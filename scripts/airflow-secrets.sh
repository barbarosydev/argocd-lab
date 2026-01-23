#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
export LOG_PREFIX="airflow-secrets"

ACTION="${1:-}"
NAMESPACE="${LAB_AIRFLOW_NAMESPACE:-airflow}"

DB_SECRET_NAME="airflow-postgresql-secret"
ADMIN_SECRET_NAME="airflow-admin-secret"

usage() {
  cat <<EOF
Usage: $0 <action>

Actions:
  init         Create required secrets if missing (db + admin)
  db           Print DB SQLAlchemy connection string
  admin        Print Airflow admin password

Notes:
  - Secrets are created in-cluster only (no secrets in git).
  - Re-running init is safe.
EOF
  exit 1
}

require_cluster() {
  require_cmd kubectl

  # Namespace may not exist yet; caller can create it.
}

random_password() {
  # 24 chars, URL-safe. Good enough for a local lab.
  if require_cmd openssl; then
    openssl rand -base64 24 | tr -d '=+/\n' | cut -c1-24
  else
    date +%s | shasum | cut -c1-24
  fi
}

ensure_db_secret() {
  if kubectl -n "${NAMESPACE}" get secret "${DB_SECRET_NAME}" >/dev/null 2>&1; then
    log_debug "DB secret exists"
    return 0
  fi

  local password
  password=$(random_password)

  local conn
  conn="postgresql+psycopg2://airflow:${password}@airflow-postgresql:5432/airflow"

  log_info "Creating DB secret '${DB_SECRET_NAME}' in namespace '${NAMESPACE}'"
  kubectl -n "${NAMESPACE}" create secret generic "${DB_SECRET_NAME}" \
    --from-literal=password="${password}" \
    --from-literal=sql_alchemy_conn="${conn}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

ensure_admin_secret() {
  if kubectl -n "${NAMESPACE}" get secret "${ADMIN_SECRET_NAME}" >/dev/null 2>&1; then
    log_debug "Admin secret exists"
    return 0
  fi

  local password
  password=$(random_password)

  log_info "Creating admin secret '${ADMIN_SECRET_NAME}' in namespace '${NAMESPACE}'"
  kubectl -n "${NAMESPACE}" create secret generic "${ADMIN_SECRET_NAME}" \
    --from-literal=password="${password}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

init_secrets() {
  require_cluster

  if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
    log_error "Namespace '${NAMESPACE}' not found. Deploy Airflow first (task airflow:deploy)."
    exit 1
  fi

  ensure_db_secret
  ensure_admin_secret

  echo "[airflow] Secrets ready in namespace '${NAMESPACE}'"
}

show_db() {
  require_cluster
  kubectl -n "${NAMESPACE}" get secret "${DB_SECRET_NAME}" -o jsonpath='{.data.sql_alchemy_conn}' | base64 -d
  echo
}

show_admin() {
  require_cluster
  kubectl -n "${NAMESPACE}" get secret "${ADMIN_SECRET_NAME}" -o jsonpath='{.data.password}' | base64 -d
  echo
}

case "${ACTION}" in
  init) init_secrets ;;
  db) show_db ;;
  admin) show_admin ;;
  -h|--help|"") usage ;;
  *) log_error "Unknown action: ${ACTION}"; usage ;;
esac
