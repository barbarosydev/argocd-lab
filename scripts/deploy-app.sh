#!/usr/bin/env bash
#
# Build and deploy applications to Kubernetes/ArgoCD
#

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
Build and deploy applications to Kubernetes

Usage: $(basename "$0") --app-name NAME [OPTIONS]

Options:
  --app-name NAME         Application name (required)
  --method METHOD         Deployment method: gitops, helm (default: gitops)
  --profile PROFILE       Minikube profile name (default: argocd-lab)
  --namespace NAMESPACE   Kubernetes namespace (default: default)
  --verbose               Enable verbose output
  --help                  Show this help message

Deployment Methods:
  gitops                  Deploy via ArgoCD (GitOps workflow, automated sync)
  helm                    Deploy directly via Helm (quick testing, no ArgoCD)

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

# Derive paths from app name
APP_DIR="k8s/${APP_NAME}/app"
CHART_DIR="k8s/${APP_NAME}"

# Validate paths exist
if [[ ! -d "${APP_DIR}" ]]; then
  log_error "Application directory not found: ${APP_DIR}"
  exit 1
fi

if [[ ! -f "${CHART_DIR}/Chart.yaml" ]]; then
  log_error "Helm chart not found: ${CHART_DIR}/Chart.yaml"
  exit 1
fi

# Enable verbose output if requested
if [[ "${VERBOSE}" == "true" ]]; then
  set -x
fi

log_info "Building ${APP_NAME} Docker image..."

# Set docker environment to use Minikube's Docker daemon
eval "$(minikube -p "${PROFILE}" docker-env)"

# Build the Docker image
docker build -t "${APP_NAME}:latest" "${APP_DIR}"

log_info "Docker image ${APP_NAME}:latest built successfully"

if [[ "${DEPLOY_METHOD}" == "gitops" ]]; then
  log_info "Deploying ${APP_NAME} via ArgoCD (GitOps method)..."

  # Check if ArgoCD manifest exists
  if [[ ! -f "argocd/apps/${APP_NAME}.yaml" ]]; then
    log_error "ArgoCD application manifest not found: argocd/apps/${APP_NAME}.yaml"
    exit 1
  fi

  # Apply the ArgoCD Application manifest
  kubectl apply -f "argocd/apps/${APP_NAME}.yaml"

  log_info "${APP_NAME} application registered with ArgoCD"
  log_info "Check status with: kubectl -n argocd get app ${APP_NAME}"
  log_info "Or view in ArgoCD UI: task argocd:ui"
else
  log_info "Deploying ${APP_NAME} directly via Helm..."

  # Create namespace if it doesn't exist
  kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

  # Deploy via Helm
  helm upgrade --install "${APP_NAME}" "${CHART_DIR}" \
    --namespace "${NAMESPACE}" \
    --create-namespace

  log_info "${APP_NAME} deployed successfully via Helm"
  log_info "Check status with: kubectl -n ${NAMESPACE} get pods -l app=${APP_NAME}"
  log_info ""
  log_info "Test the application:"
  log_info "  kubectl -n ${NAMESPACE} port-forward svc/${APP_NAME} 8000:8000"
  log_info "  curl http://localhost:8000/health"
fi
