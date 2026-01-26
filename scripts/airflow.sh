#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
export LOG_PREFIX="airflow"

COMMAND=""
PORT="${LAB_AIRFLOW_PORT:-8080}"
KEEP_SECRETS=0

show_help() {
  cat <<EOF
Manage Airflow deployment with external PostgreSQL.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  deploy      Deploy Airflow with PostgreSQL via ArgoCD
  undeploy    Remove Airflow and PostgreSQL deployment
  ui          Open Airflow web UI via port-forward
  passwords   Display Airflow and PostgreSQL credentials
  status      Check Airflow deployment status

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output
  --port PORT      Port for UI port-forward (default: 8080)
  --keep-secrets   Keep secrets when undeploying (undeploy only)

Examples:
  $(basename "$0") deploy
  $(basename "$0") ui --port 8081
  $(basename "$0") undeploy --keep-secrets
  $(basename "$0") passwords

EOF
}

deploy_airflow() {
  require_cmd kubectl openssl

  log_info "Deploying Airflow with external PostgreSQL"

  # Generate secrets if they don't exist
  if ! kubectl get secret postgres-secret &>/dev/null; then
    log_info "Generating PostgreSQL secrets"

    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    AIRFLOW_PASSWORD=$(openssl rand -base64 32)
    CONNECTION_STRING="postgresql+psycopg2://airflow:${AIRFLOW_PASSWORD}@postgres-postgresql.default.svc.cluster.local:5432/airflow"

    kubectl create secret generic postgres-secret \
      --from-literal=postgres-password="${POSTGRES_PASSWORD}" \
      --from-literal=airflow-password="${AIRFLOW_PASSWORD}" \
      --from-literal=connection-string="${CONNECTION_STRING}"

    log_info "PostgreSQL secrets created"
  else
    log_info "PostgreSQL secrets already exist"
  fi

  # Deploy PostgreSQL
  log_info "Deploying PostgreSQL via ArgoCD"
  kubectl apply -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../argocd/apps/postgres.yaml"

  # Wait for PostgreSQL to be ready
  log_info "Waiting for PostgreSQL to be ready (this may take a few minutes)"
  sleep 5

  if ! kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=300s 2>/dev/null; then
    log_warn "PostgreSQL pod not ready yet, continuing anyway"
  else
    log_info "PostgreSQL is ready"
  fi

  # Deploy Airflow
  log_info "Deploying Airflow via ArgoCD"
  kubectl apply -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../argocd/apps/airflow.yaml"

  # Wait for Airflow webserver to be ready
  log_info "Waiting for Airflow webserver to be ready (this may take a few minutes)"
  sleep 5

  if ! kubectl wait --for=condition=ready pod -l component=webserver --timeout=600s 2>/dev/null; then
    log_warn "Airflow webserver not ready yet, but deployment is in progress"
  else
    log_info "Airflow webserver is ready"
  fi

  echo ""
  log_info "✅ Airflow deployment complete!"
  log_info "Run 'task airflow:ui' to access the Airflow web UI"
  log_info "Run 'task airflow:passwords' to view credentials"
}

undeploy_airflow() {
  require_cmd kubectl

  log_info "Undeploying Airflow and PostgreSQL"

  # Undeploy Airflow
  if kubectl get application airflow -n argocd &>/dev/null; then
    log_info "Removing Airflow application"
    kubectl delete -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../argocd/apps/airflow.yaml"
    log_info "Airflow application removed"
  else
    log_info "Airflow application not found, skipping"
  fi

  # Undeploy PostgreSQL
  if kubectl get application postgres -n argocd &>/dev/null; then
    log_info "Removing PostgreSQL application"
    kubectl delete -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../argocd/apps/postgres.yaml"
    log_info "PostgreSQL application removed"
  else
    log_info "PostgreSQL application not found, skipping"
  fi

  # Delete secrets unless --keep-secrets is specified
  if [[ ${KEEP_SECRETS} -eq 0 ]]; then
    if kubectl get secret postgres-secret &>/dev/null; then
      log_info "Deleting PostgreSQL secrets"
      kubectl delete secret postgres-secret
      log_info "Secrets deleted"
    fi
  else
    log_info "Keeping secrets as requested"
  fi

  echo ""
  log_info "✅ Airflow undeploy complete!"
}

ui_airflow() {
  require_cmd kubectl

  log_info "Starting Airflow UI port-forward on port ${PORT}"

  # Check if Airflow webserver is running
  if ! kubectl get pod -l component=webserver &>/dev/null; then
    log_error "Airflow webserver pod not found. Deploy Airflow first with 'task airflow:deploy'"
    exit 1
  fi

  log_info "Airflow UI will be available at http://localhost:${PORT}"
  log_info "Username: admin"
  log_info "Password: admin (default - run 'task airflow:passwords' for all credentials)"
  log_info "Press Ctrl+C to stop port forwarding"
  echo ""

  kubectl port-forward svc/airflow-webserver "${PORT}:8080"
}

passwords_airflow() {
  require_cmd kubectl

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Airflow & PostgreSQL Credentials"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Airflow Web UI credentials
  echo "📊 Airflow Web UI:"
  echo "   URL:      http://localhost:${PORT} (when port-forwarded)"
  echo "   Username: admin"
  echo "   Password: admin"
  echo ""

  # PostgreSQL credentials
  if kubectl get secret postgres-secret &>/dev/null; then
    POSTGRES_PASS=$(kubectl get secret postgres-secret -o jsonpath='{.data.postgres-password}' 2>/dev/null | base64 -d)
    AIRFLOW_DB_PASS=$(kubectl get secret postgres-secret -o jsonpath='{.data.airflow-password}' 2>/dev/null | base64 -d)

    echo "🐘 PostgreSQL Admin:"
    echo "   Host:     postgres-postgresql.default.svc.cluster.local"
    echo "   Port:     5432"
    echo "   Username: postgres"
    echo "   Password: ${POSTGRES_PASS}"
    echo ""

    echo "🐘 PostgreSQL Airflow User:"
    echo "   Host:     postgres-postgresql.default.svc.cluster.local"
    echo "   Port:     5432"
    echo "   Database: airflow"
    echo "   Username: airflow"
    echo "   Password: ${AIRFLOW_DB_PASS}"
    echo ""
  else
    log_error "PostgreSQL secrets not found. Deploy Airflow first with 'task airflow:deploy'"
    exit 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

status_airflow() {
  require_cmd kubectl

  echo "Checking Airflow deployment status..."
  echo ""
  echo "ArgoCD Applications:"
  kubectl get application -n argocd 2>/dev/null | grep -E "(NAME|postgres|airflow)" || echo "No Airflow applications found"
  echo ""
  echo "Pods:"
  kubectl get pods -l 'app.kubernetes.io/name in (postgresql,airflow)' 2>/dev/null || echo "No Airflow pods found"
  echo ""
  echo "Services:"
  kubectl get svc 2>/dev/null | grep -E "(NAME|postgres|airflow)" || echo "No Airflow services found"
}

main() {
  # Parse command first
  if [[ $# -eq 0 ]]; then
    show_help
    exit 1
  fi

  COMMAND="$1"
  shift

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) show_help; exit 0 ;;
      --verbose) export LAB_VERBOSE=1; shift ;;
      --port) PORT="${2:?--port requires a value}"; shift 2 ;;
      --keep-secrets) KEEP_SECRETS=1; shift ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Execute command
  case "$COMMAND" in
    deploy) deploy_airflow ;;
    undeploy) undeploy_airflow ;;
    ui) ui_airflow ;;
    passwords) passwords_airflow ;;
    status) status_airflow ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
