#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
DEPLOY_METHOD="${LAB_DEPLOY_METHOD:-helm}"
NAMESPACE="${LAB_POSTGRES_NAMESPACE:-default}"

show_help() {
  cat <<EOF
Manage PostgreSQL deployment.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  deploy      Deploy PostgreSQL
  undeploy    Remove PostgreSQL deployment
  status      Check PostgreSQL deployment status
  password    Display PostgreSQL credentials
  shell       Open psql shell to PostgreSQL

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output
  --method METHOD  Deployment method: helm or gitops (default: helm)
  --namespace NS   Target namespace (default: default)

Examples:
  $(basename "$0") deploy
  $(basename "$0") deploy --method gitops
  $(basename "$0") undeploy
  $(basename "$0") password

EOF
}

create_secrets() {
  require_cmd kubectl openssl

  if ! kubectl get secret postgres-secret -n "${NAMESPACE}" &>/dev/null; then
    log_info "Generating PostgreSQL secrets"

    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
    AIRFLOW_DB_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
    CONNECTION_STRING="postgresql+psycopg2://airflow:${AIRFLOW_DB_PASSWORD}@postgres-postgresql.${NAMESPACE}.svc.cluster.local:5432/airflow"

    kubectl create secret generic postgres-secret \
      -n "${NAMESPACE}" \
      --from-literal=postgres-password="${POSTGRES_PASSWORD}" \
      --from-literal=airflow-password="${AIRFLOW_DB_PASSWORD}" \
      --from-literal=connection-string="${CONNECTION_STRING}"

    log_info "PostgreSQL secrets created"
  else
    log_info "PostgreSQL secrets already exist"
  fi
}

deploy_postgres_helm() {
  require_cmd kubectl helm

  log_info "Deploying PostgreSQL via Helm"

  # Add Bitnami repo if not present
  if ! helm repo list 2>/dev/null | grep -q bitnami; then
    log_info "Adding Bitnami Helm repository"
    helm repo add bitnami https://charts.bitnami.com/bitnami
  fi

  log_info "Updating Helm repositories"
  helm repo update

  # Create secrets first
  create_secrets

  # Get chart directory
  local chart_dir
  chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../k8s/postgres"

  # Update helm dependencies
  log_info "Updating Helm dependencies"
  helm dependency update "${chart_dir}"

  # Deploy via Helm
  log_info "Installing PostgreSQL"
  helm upgrade --install postgres "${chart_dir}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --wait \
    --timeout 10m

  # Wait for PostgreSQL to be ready
  log_info "Waiting for PostgreSQL to be ready"
  if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n "${NAMESPACE}" --timeout=300s 2>/dev/null; then
    log_info "PostgreSQL is ready"
  else
    log_warn "PostgreSQL pod not ready yet, but installation is in progress"
  fi

  echo ""
  log_info "✅ PostgreSQL deployment complete!"
  log_info "Run 'task postgres:password' to view credentials"
}

deploy_postgres_gitops() {
  require_cmd kubectl helm

  log_info "Deploying PostgreSQL via ArgoCD (GitOps)"

  # First, pre-pull the chart dependencies locally to avoid ArgoCD timeout
  local chart_dir
  chart_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../k8s/postgres"

  # Add Bitnami repo if not present
  if ! helm repo list 2>/dev/null | grep -q bitnami; then
    log_info "Adding Bitnami Helm repository"
    helm repo add bitnami https://charts.bitnami.com/bitnami
  fi

  log_info "Updating Helm repositories"
  helm repo update

  log_info "Pulling chart dependencies"
  helm dependency update "${chart_dir}"

  # Create secrets first
  create_secrets

  # Deploy via ArgoCD
  log_info "Creating ArgoCD Application"
  kubectl apply -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../argocd/apps/postgres.yaml"

  # Wait for PostgreSQL to be ready
  log_info "Waiting for PostgreSQL to be ready (this may take a few minutes)"
  sleep 10

  if kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n "${NAMESPACE}" --timeout=300s 2>/dev/null; then
    log_info "PostgreSQL is ready"
  else
    log_warn "PostgreSQL pod not ready yet, but deployment is in progress"
    log_info "Check status with: task postgres:status"
  fi

  echo ""
  log_info "✅ PostgreSQL GitOps deployment initiated!"
  log_info "Run 'task postgres:password' to view credentials"
}

deploy_postgres() {
  if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
    deploy_postgres_gitops
  else
    deploy_postgres_helm
  fi
}

undeploy_postgres() {
  require_cmd kubectl

  log_info "Undeploying PostgreSQL"

  local found=0

  # Check for ArgoCD application
  if kubectl get application postgres -n argocd &>/dev/null; then
    log_info "Removing PostgreSQL ArgoCD application (cascade delete)"
    kubectl delete application postgres -n argocd --cascade=foreground --wait=true
    log_info "PostgreSQL ArgoCD application removed"
    found=1
  fi

  # Check for Helm release
  if helm list -n "${NAMESPACE}" 2>/dev/null | grep -q "^postgres[[:space:]]"; then
    log_info "Removing PostgreSQL Helm release"
    helm uninstall postgres -n "${NAMESPACE}" --wait
    log_info "PostgreSQL Helm release removed"
    found=1
  fi

  if [[ $found -eq 0 ]]; then
    log_warn "No PostgreSQL deployment found"
  fi

  # Clean up orphaned resources
  log_info "Cleaning up orphaned PostgreSQL resources"
  kubectl delete statefulset,deployment,service,configmap,serviceaccount,job,pvc \
    -l release=postgres -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true
  kubectl delete statefulset,deployment,service,configmap,serviceaccount,job,pvc \
    -l app.kubernetes.io/instance=postgres -n "${NAMESPACE}" --ignore-not-found 2>/dev/null || true

  # Delete secrets
  if kubectl get secret postgres-secret -n "${NAMESPACE}" &>/dev/null; then
    log_info "Deleting PostgreSQL secrets"
    kubectl delete secret postgres-secret -n "${NAMESPACE}"
  fi

  echo ""
  log_info "✅ PostgreSQL undeploy complete!"
}

status_postgres() {
  require_cmd kubectl

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  PostgreSQL Deployment Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  echo "📦 ArgoCD Application:"
  if kubectl get application postgres -n argocd &>/dev/null; then
    kubectl get application postgres -n argocd -o custom-columns=NAME:.metadata.name,STATUS:.status.health.status,SYNC:.status.sync.status,MESSAGE:.status.operationState.message 2>/dev/null || \
    kubectl get application postgres -n argocd
  else
    echo "   Not deployed via ArgoCD"
  fi
  echo ""

  echo "📦 Helm Release:"
  if helm list -n "${NAMESPACE}" 2>/dev/null | grep -q "^postgres[[:space:]]"; then
    helm list -n "${NAMESPACE}" | grep -E "(NAME|^postgres[[:space:]])"
  else
    echo "   Not deployed via Helm"
  fi
  echo ""

  echo "🔧 Pods:"
  kubectl get pods -l app.kubernetes.io/name=postgresql -n "${NAMESPACE}" 2>/dev/null || echo "   No PostgreSQL pods found"
  echo ""

  echo "🌐 Services:"
  kubectl get svc -n "${NAMESPACE}" 2>/dev/null | grep -E "(NAME|postgres)" || echo "   No PostgreSQL services found"
  echo ""

  echo "💾 Persistent Volume Claims:"
  kubectl get pvc -n "${NAMESPACE}" 2>/dev/null | grep -E "(NAME|postgres)" || echo "   No PostgreSQL PVCs found"
  echo ""

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

password_postgres() {
  require_cmd kubectl

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  PostgreSQL Credentials"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if kubectl get secret postgres-secret -n "${NAMESPACE}" &>/dev/null; then
    POSTGRES_PASS=$(kubectl get secret postgres-secret -n "${NAMESPACE}" -o jsonpath='{.data.postgres-password}' 2>/dev/null | base64 -d)
    AIRFLOW_DB_PASS=$(kubectl get secret postgres-secret -n "${NAMESPACE}" -o jsonpath='{.data.airflow-password}' 2>/dev/null | base64 -d)

    echo "🐘 PostgreSQL Admin:"
    echo "   Host:     postgres-postgresql.${NAMESPACE}.svc.cluster.local"
    echo "   Port:     5432"
    echo "   Username: postgres"
    echo "   Password: ${POSTGRES_PASS}"
    echo ""

    echo "🐘 PostgreSQL Airflow User:"
    echo "   Host:     postgres-postgresql.${NAMESPACE}.svc.cluster.local"
    echo "   Port:     5432"
    echo "   Database: airflow"
    echo "   Username: airflow"
    echo "   Password: ${AIRFLOW_DB_PASS}"
    echo ""
  else
    log_error "PostgreSQL secrets not found. Deploy PostgreSQL first with 'task postgres:deploy'"
    exit 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

shell_postgres() {
  require_cmd kubectl

  log_info "Opening psql shell to PostgreSQL"

  if ! kubectl get pod -l app.kubernetes.io/name=postgresql -n "${NAMESPACE}" &>/dev/null; then
    log_error "PostgreSQL pod not found. Deploy PostgreSQL first with 'task postgres:deploy'"
    exit 1
  fi

  local pod_name
  pod_name=$(kubectl get pod -l app.kubernetes.io/name=postgresql -n "${NAMESPACE}" -o jsonpath='{.items[0].metadata.name}')

  kubectl exec -it "${pod_name}" -n "${NAMESPACE}" -- psql -U postgres
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
      --method) DEPLOY_METHOD="${2:?--method requires a value}"; shift 2 ;;
      --namespace) NAMESPACE="${2:?--namespace requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Validate deployment method
  if [[ "$COMMAND" == "deploy" ]]; then
    [[ "$DEPLOY_METHOD" != "gitops" && "$DEPLOY_METHOD" != "helm" ]] && {
      log_error "Invalid method: $DEPLOY_METHOD (must be gitops or helm)"
      exit 1
    }
  fi

  # Execute command
  case "$COMMAND" in
    deploy) deploy_postgres ;;
    undeploy) undeploy_postgres ;;
    status) status_postgres ;;
    password) password_postgres ;;
    shell) shell_postgres ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
