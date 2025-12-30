#!/usr/bin/env bash
#
# Undeploy applications from Kubernetes/ArgoCD
#
# shellcheck disable=SC2034  # PROFILE is kept for consistency and future use

set -euo pipefail

# Default values
VERBOSE=false
PROFILE="argocd-lab"
APP_NAME=""
NAMESPACE="default"
DEPLOY_METHOD="gitops"  # Options: gitops, helm

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

show_help() {
  cat << EOF
Undeploy applications from Kubernetes

Usage: $(basename "$0") --app-name NAME [OPTIONS]

Options:
  --app-name NAME         Application name (required)
  --method METHOD         Deployment method: gitops, helm (default: gitops)
  --profile PROFILE       Minikube profile name (default: argocd-lab)
  --namespace NAMESPACE   Kubernetes namespace (default: default)
  --verbose               Enable verbose output
  --help                  Show this help message

Deployment Methods:
  gitops                  Remove from ArgoCD (GitOps workflow)
  helm                    Remove directly via Helm (bypasses ArgoCD)

Examples:
  $(basename "$0") --app-name demo-api
  $(basename "$0") --app-name demo-api --method gitops
  $(basename "$0") --app-name demo-api --method helm
  $(basename "$0") --app-name demo-api --namespace production

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --app-name)
      APP_NAME="$2"
      shift 2
      ;;
    --method)
      DEPLOY_METHOD="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "${APP_NAME}" ]]; then
  log_error "Application name is required"
  show_help
  exit 1
fi

# Validate deployment method
if [[ "${DEPLOY_METHOD}" != "gitops" && "${DEPLOY_METHOD}" != "helm" ]]; then
  log_error "Invalid deployment method: ${DEPLOY_METHOD}"
  log_error "Valid methods: gitops, helm"
  exit 1
fi

# Enable verbose output if requested
if [[ "${VERBOSE}" == "true" ]]; then
  set -x
fi

# Auto-detect deployment method if using default
if [[ "${DEPLOY_METHOD}" == "gitops" ]]; then
  # Check if app exists in ArgoCD
  ARGOCD_EXISTS=false
  if kubectl -n argocd get application "${APP_NAME}" >/dev/null 2>&1; then
    ARGOCD_EXISTS=true
  fi

  # Check if app exists as Helm release
  HELM_EXISTS=false
  if helm list -A 2>/dev/null | tail -n +2 | grep -q "^${APP_NAME}[[:space:]]"; then
    HELM_EXISTS=true
  fi

  # If not in ArgoCD but exists in Helm, suggest the correct method
  if [[ "${ARGOCD_EXISTS}" == "false" && "${HELM_EXISTS}" == "true" ]]; then
    log_error "${APP_NAME} is not managed by ArgoCD"
    log_error "However, a Helm release named '${APP_NAME}' was found"
    log_error ""
    log_error "This application was deployed using --method helm"
    log_error "To undeploy it, use:"
    log_error "  $(basename "$0") --app-name ${APP_NAME} --method helm"
    log_error "Or:"
    log_error "  task argocd:undeploy-app APP_NAME=${APP_NAME} -- --method helm"
    exit 1
  fi
fi

if [[ "${DEPLOY_METHOD}" == "gitops" ]]; then
  log_info "Removing ${APP_NAME} from ArgoCD (GitOps method)..."

  # Check if ArgoCD application exists
  if kubectl -n argocd get application "${APP_NAME}" >/dev/null 2>&1; then
    # Delete the ArgoCD Application (this will also delete the deployed resources)
    kubectl -n argocd delete application "${APP_NAME}"
    log_info "${APP_NAME} application removed from ArgoCD"
    log_info "ArgoCD will clean up the deployed resources automatically"
  else
    log_error "ArgoCD application ${APP_NAME} not found"
    log_error "Available ArgoCD applications:"
    kubectl -n argocd get applications -o name 2>/dev/null | sed 's|application.argoproj.io/||' || echo "  (none)"
    exit 1
  fi

  # Optionally remove the manifest file reference
  if [[ -f "argocd/apps/${APP_NAME}.yaml" ]]; then
    log_info "ArgoCD manifest still exists at: argocd/apps/${APP_NAME}.yaml"
    log_info "You can reapply it later with: kubectl apply -f argocd/apps/${APP_NAME}.yaml"
  fi
else
  log_info "Undeploying ${APP_NAME} directly via Helm..."

  # Check if Helm release exists
  if helm list -A 2>/dev/null | tail -n +2 | grep -q "^${APP_NAME}[[:space:]]"; then
    # Get the namespace
    HELM_NAMESPACE=$(helm list -A 2>/dev/null | tail -n +2 | grep "^${APP_NAME}[[:space:]]" | awk '{print $2}')
    helm uninstall "${APP_NAME}" --namespace "${HELM_NAMESPACE}"
    log_info "${APP_NAME} uninstalled successfully via Helm from namespace ${HELM_NAMESPACE}"
  else
    log_error "Helm release ${APP_NAME} not found"
    log_error "Available Helm releases:"
    helm list -A 2>/dev/null | tail -n +2 || echo "  (none)"
    exit 1
  fi

  # Check if namespace is now empty (excluding system resources)
  if [[ -n "${HELM_NAMESPACE:-}" ]]; then
    RESOURCES=$(kubectl get all -n "${HELM_NAMESPACE}" 2>/dev/null | grep -vc "^NAME" || echo "0")
    if [[ "${RESOURCES}" -eq 0 ]]; then
      log_info "Namespace ${HELM_NAMESPACE} is now empty"
      log_info "You can delete it with: kubectl delete namespace ${HELM_NAMESPACE}"
    fi
  fi
fi

log_info "Undeploy complete"
