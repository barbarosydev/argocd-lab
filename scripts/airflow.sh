#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
export LOG_PREFIX="airflow"

# Configuration from environment
AIRFLOW_VERSION="${LAB_AIRFLOW_VERSION:-3.0.2}"
AIRFLOW_HELM_VERSION="${LAB_AIRFLOW_HELM_VERSION:-1.18.0}"
AIRFLOW_NAMESPACE="${LAB_AIRFLOW_NAMESPACE:-airflow}"
PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"

ACTION="${1:-}"

get_chart_version_from_app() {
  # Extract the 'targetRevision' for the Helm chart source (repoURL=https://airflow.apache.org).
  # This avoids picking up the second source (the git repo) which uses targetRevision=HEAD.
  if [ ! -f "argocd/apps/airflow.yaml" ]; then
    echo ""
    return 0
  fi

  awk '
    $1 == "repoURL:" && $2 == "https://airflow.apache.org" { in_airflow_repo = 1; next }
    $1 == "-" && $2 == "repoURL:" && $3 == "https://airflow.apache.org" { in_airflow_repo = 1; next }

    in_airflow_repo && $1 == "targetRevision:" { print $2; exit }
    in_airflow_repo && $1 == "-" && $2 == "targetRevision:" { print $3; exit }

    # Stop scanning this source block when the next source begins
    in_airflow_repo && $1 == "-" && $2 == "repoURL:" { in_airflow_repo = 0 }
    in_airflow_repo && $1 == "repoURL:" { in_airflow_repo = 0 }
  ' argocd/apps/airflow.yaml 2>/dev/null || true
}

usage() {
  cat <<EOF
Usage: $0 <action>

Actions:
  preflight   Check prerequisites for Airflow deployment
  deploy      Deploy Airflow via ArgoCD
  undeploy    Remove Airflow deployment
  status      Check Airflow deployment status
  ui          Port-forward Airflow webserver (localhost:8080)
  logs        View Airflow scheduler logs
  shell       Open shell in scheduler pod
  sync        Force sync Airflow application in ArgoCD

Environment:
  LAB_AIRFLOW_VERSION      Airflow version (default: ${AIRFLOW_VERSION})
  LAB_AIRFLOW_HELM_VERSION Helm chart version (default: ${AIRFLOW_HELM_VERSION})
  LAB_AIRFLOW_NAMESPACE    Kubernetes namespace (default: ${AIRFLOW_NAMESPACE})
EOF
  exit 1
}

preflight() {
  echo "[airflow] Preflight Check"
  echo ""

  local errors=0

  echo "[check] Required commands..."
  if require_cmd kubectl minikube; then
    echo "  ✓ Found kubectl and minikube"
  else
    echo "  ✗ Missing required commands"
    echo "    Run: task utils:install"
    errors=$((errors + 1))
  fi
  echo ""

  echo "[check] Minikube cluster..."
  if minikube status -p "${PROFILE}" >/dev/null 2>&1; then
    echo "  ✓ Minikube is running (profile: ${PROFILE})"
  else
    echo "  ✗ Minikube is not running (profile: ${PROFILE})"
    echo "    Run: task lab:up"
    errors=$((errors + 1))
  fi
  echo ""

  echo "[check] Argo CD namespace..."
  if kubectl get namespace argocd >/dev/null 2>&1; then
    echo "  ✓ Namespace argocd exists"
  else
    echo "  ✗ Namespace argocd not found"
    echo "    Run: task lab:up"
    errors=$((errors + 1))
  fi
  echo ""

  echo "[check] Required files..."
  if [ -f "argocd/apps/airflow.yaml" ]; then
    echo "  ✓ argocd/apps/airflow.yaml"
  else
    echo "  ✗ Missing argocd/apps/airflow.yaml"
    errors=$((errors + 1))
  fi

  if [ -f "argocd/apps/airflow-postgresql.yaml" ]; then
    echo "  ✓ argocd/apps/airflow-postgresql.yaml"
  else
    echo "  ✗ Missing argocd/apps/airflow-postgresql.yaml"
    errors=$((errors + 1))
  fi

  if [ -f "k8s/airflow/postgresql.yaml" ] && [ -f "k8s/airflow/postgresql-pvc.yaml" ] && [ -f "k8s/airflow/postgresql-service.yaml" ]; then
    echo "  ✓ k8s/airflow/postgresql*.yaml"
  else
    echo "  ✗ Missing one or more k8s/airflow/postgresql*.yaml manifests"
    errors=$((errors + 1))
  fi

  if [ -f "scripts/airflow-secrets.sh" ]; then
    echo "  ✓ scripts/airflow-secrets.sh"
  else
    echo "  ✗ Missing scripts/airflow-secrets.sh"
    errors=$((errors + 1))
  fi
  echo ""

  echo "[check] Airflow Helm chart version..."
  local app_chart_version
  app_chart_version=$(get_chart_version_from_app)
  if [ -z "${app_chart_version}" ]; then
    echo "  ℹ Could not read chart version from argocd/apps/airflow.yaml"
  elif [ "${app_chart_version}" != "${AIRFLOW_HELM_VERSION}" ]; then
    echo "  ✗ Chart version mismatch"
    echo "    argocd/apps/airflow.yaml: ${app_chart_version}"
    echo "    LAB_AIRFLOW_HELM_VERSION: ${AIRFLOW_HELM_VERSION}"
    echo "    Tip: align .env and the manifest for reproducible deploys"
    errors=$((errors + 1))
  else
    echo "  ✓ Chart version matches (${AIRFLOW_HELM_VERSION})"
  fi
  echo ""

  echo "[airflow] Configuration:"
  echo "  Airflow Version: ${AIRFLOW_VERSION}"
  echo "  Helm Chart Version: ${AIRFLOW_HELM_VERSION}"
  echo "  Namespace: ${AIRFLOW_NAMESPACE}"
  echo ""

  if [ "${errors}" -eq 0 ]; then
    echo "[airflow] ✓ Preflight passed"
    echo "[airflow] Run 'task airflow:deploy' to deploy"
  else
    echo "[airflow] ✗ Preflight failed (${errors} issue(s))"
    exit 1
  fi
}

deploy() {
  log_info "Deploying Airflow ${AIRFLOW_VERSION} via ArgoCD (GitOps)..."

  # Create namespace if it doesn't exist
  kubectl create namespace "${AIRFLOW_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

  # Create secrets once (if missing). No passwords are stored in git.
  ./scripts/airflow-secrets.sh init

  # Register the Argo CD Applications. Argo CD will deploy PostgreSQL and Airflow from Git.
  log_info "Registering PostgreSQL application with ArgoCD..."
  kubectl apply -f argocd/apps/airflow-postgresql.yaml

  log_info "Registering Airflow application with ArgoCD..."
  kubectl apply -f argocd/apps/airflow.yaml

  log_info "Applications registered. ArgoCD will sync them automatically."
  log_info "Check status with 'task airflow:status'"
}

undeploy() {
  log_info "Removing Airflow..."
  kubectl delete -f argocd/apps/airflow.yaml --ignore-not-found
  kubectl delete -f argocd/apps/airflow-postgresql.yaml --ignore-not-found
  kubectl delete namespace "${AIRFLOW_NAMESPACE}" --ignore-not-found
  log_info "Airflow removed"
}

status() {
  echo "[airflow] ArgoCD Application Status:"
  kubectl get application airflow -n argocd -o wide 2>/dev/null || echo "  Application not found"
  echo ""
  echo "[airflow] Pod Status:"
  kubectl get pods -n "${AIRFLOW_NAMESPACE}" 2>/dev/null || echo "  Namespace not found"
  echo ""
  echo "[airflow] Services:"
  kubectl get svc -n "${AIRFLOW_NAMESPACE}" 2>/dev/null || echo "  No services found"
}

ui() {
  log_info "Starting port-forward to Airflow webserver..."
  echo "[airflow] Access Airflow at http://localhost:8080"
  echo "[airflow] Username: admin"
  echo "[airflow] Password: task airflow:password"
  echo "[airflow] Press Ctrl+C to stop"
  # Airflow 3.0 renamed webserver to api-server
  kubectl port-forward svc/airflow-api-server -n "${AIRFLOW_NAMESPACE}" 8080:8080 2>/dev/null \
    || kubectl port-forward svc/airflow-webserver -n "${AIRFLOW_NAMESPACE}" 8080:8080
}

logs() {
  echo "[airflow] Scheduler logs (Ctrl+C to exit):"
  kubectl logs -f -l component=scheduler -n "${AIRFLOW_NAMESPACE}" --tail=100
}

shell() {
  local pod
  pod=$(kubectl get pods -n "${AIRFLOW_NAMESPACE}" -l component=scheduler -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -z "${pod}" ]; then
    log_error "No scheduler pod found"
    exit 1
  fi
  log_info "Opening shell in ${pod}..."
  kubectl exec -it "${pod}" -n "${AIRFLOW_NAMESPACE}" -- /bin/bash
}

sync() {
  log_info "Syncing Airflow application..."
  kubectl patch application airflow -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}'
  log_info "Sync triggered. Check status with 'task airflow:status'"
}

# Main
case "${ACTION}" in
  preflight) preflight ;;
  deploy) deploy ;;
  undeploy) undeploy ;;
  status) status ;;
  ui) ui ;;
  logs) logs ;;
  shell) shell ;;
  sync) sync ;;
  -h|--help|"") usage ;;
  *) log_error "Unknown action: ${ACTION}"; usage ;;
esac
