#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
AIRFLOW_PORT="${LAB_AIRFLOW_PORT:-8080}"

show_help() {
  cat <<EOF
Manage Airflow deployment with external PostgreSQL.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  deploy      Deploy Airflow (requires PostgreSQL to be deployed first)
  undeploy    Remove Airflow deployment (leaves PostgreSQL intact)
  ui          Open Airflow web UI via port-forward
  passwords   Display Airflow and PostgreSQL credentials
  status      Check Airflow deployment status

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output
  --port PORT      Port for UI port-forward (default: 8080)

Prerequisites:
  PostgreSQL must be deployed first: task postgres:deploy

Examples:
  $(basename "$0") deploy
  $(basename "$0") ui --port 8081
  $(basename "$0") undeploy
  $(basename "$0") passwords

EOF
}

deploy_airflow() {
  require_cmd kubectl openssl

  log_info "Deploying Airflow"

  # Check if PostgreSQL is running
  if ! kubectl get pod -l app.kubernetes.io/name=postgresql &>/dev/null; then
    log_error "PostgreSQL is not deployed. Deploy it first with 'task postgres:deploy'"
    exit 1
  fi

  # Check if PostgreSQL is ready
  if ! kubectl get pod -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].status.phase}' 2>/dev/null | grep -q "Running"; then
    log_error "PostgreSQL is not ready. Wait for it to be running or check 'task postgres:status'"
    exit 1
  fi

  # Check if postgres-secret exists (required for connection string)
  if ! kubectl get secret postgres-secret &>/dev/null; then
    log_error "PostgreSQL secrets not found. Redeploy PostgreSQL with 'task postgres:deploy'"
    exit 1
  fi

  # Generate Airflow webserver secret if it doesn't exist
  if ! kubectl get secret airflow-webserver-secret &>/dev/null; then
    log_info "Generating Airflow webserver secret"

    WEBSERVER_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 16)

    kubectl create secret generic airflow-webserver-secret \
      --from-literal=webserver-secret-key="$(openssl rand -hex 32)" \
      --from-literal=webserver-password="${WEBSERVER_PASSWORD}"

    log_info "Airflow webserver secret created"
  else
    log_info "Airflow webserver secret already exists"
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

  log_info "Undeploying Airflow"

  # Undeploy Airflow via ArgoCD (with cascade delete)
  if kubectl get application airflow -n argocd &>/dev/null; then
    log_info "Removing Airflow application (cascade delete)"
    kubectl delete application airflow -n argocd --cascade=foreground --wait=true
    log_info "Airflow application removed"
  else
    log_info "Airflow ArgoCD application not found"
  fi

  # Clean up any orphaned Airflow resources (in case ArgoCD apps were deleted without cascade)
  log_info "Cleaning up orphaned Airflow resources"
  kubectl delete statefulset,deployment,service,configmap,serviceaccount,secret,job,pvc -l release=airflow --ignore-not-found 2>/dev/null || true
  kubectl delete statefulset,deployment,service,configmap,serviceaccount,secret,job,pvc -l app.kubernetes.io/instance=airflow --ignore-not-found 2>/dev/null || true

  # Delete Airflow secrets
  if kubectl get secret airflow-webserver-secret &>/dev/null; then
    log_info "Deleting Airflow webserver secret"
    kubectl delete secret airflow-webserver-secret
  fi

  echo ""
  log_info "✅ Airflow undeploy complete!"
  log_info "PostgreSQL was NOT removed. To remove it, run 'task postgres:undeploy'"
}

ui_airflow() {
  require_cmd kubectl

  log_info "Starting Airflow UI port-forward on port ${AIRFLOW_PORT}"

  # Check if Airflow webserver is running
  if ! kubectl get pod -l component=webserver &>/dev/null; then
    log_error "Airflow webserver pod not found. Deploy Airflow first with 'task airflow:deploy'"
    exit 1
  fi

  # Get webserver password from secret
  local webserver_pass="(run 'task airflow:passwords' to view)"
  if kubectl get secret airflow-webserver-secret &>/dev/null; then
    webserver_pass=$(kubectl get secret airflow-webserver-secret -o jsonpath='{.data.webserver-password}' 2>/dev/null | base64 -d)
  fi

  log_info "Airflow UI will be available at http://localhost:${AIRFLOW_PORT}"
  log_info "Username: admin"
  log_info "Password: ${webserver_pass}"
  log_info "Press Ctrl+C to stop port forwarding"
  echo ""

  kubectl port-forward svc/airflow-webserver "${AIRFLOW_PORT}:8080"
}

passwords_airflow() {
  require_cmd kubectl

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Airflow & PostgreSQL Credentials"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Airflow Web UI credentials
  if kubectl get secret airflow-webserver-secret &>/dev/null; then
    WEBSERVER_PASS=$(kubectl get secret airflow-webserver-secret -o jsonpath='{.data.webserver-password}' 2>/dev/null | base64 -d)

    echo "📊 Airflow Web UI:"
    echo "   URL:      http://localhost:${AIRFLOW_PORT} (when port-forwarded)"
    echo "   Username: admin"
    echo "   Password: ${WEBSERVER_PASS}"
    echo ""
  else
    log_warn "Airflow webserver secret not found"
    echo ""
  fi

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
    log_warn "PostgreSQL secrets not found"
    echo ""
  fi

  if ! kubectl get secret airflow-webserver-secret &>/dev/null && ! kubectl get secret postgres-secret &>/dev/null; then
    log_error "No secrets found. Deploy Airflow first with 'task airflow:deploy'"
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
      --port) AIRFLOW_PORT="${2:?--port requires a value}"; shift 2 ;;
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
