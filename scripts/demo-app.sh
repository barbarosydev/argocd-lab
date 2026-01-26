#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
export LOG_PREFIX="demo-app"

COMMAND=""
APP_NAME="${LAB_APP_NAME:-demo-api}"
NAMESPACE="${LAB_APP_NAMESPACE:-default}"
DEPLOY_METHOD="${LAB_DEPLOY_METHOD:-gitops}"
PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"

show_help() {
  cat <<EOF
Manage demo application deployment.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  deploy      Deploy application
  undeploy    Remove application deployment

Options:
  -h, --help           Show this help message
  --app-name NAME      Application name (default: demo-api)
  --method METHOD      Deployment method: gitops|helm (default: gitops)
  --profile NAME       Minikube profile (default: argocd-lab)
  --namespace NS       Kubernetes namespace (default: default)

Examples:
  $(basename "$0") deploy
  $(basename "$0") deploy --method helm
  $(basename "$0") undeploy --app-name demo-api

EOF
}

deploy_app() {
  require_cmd kubectl docker minikube

  APP_DIR="k8s/${APP_NAME}/app"
  CHART_DIR="k8s/${APP_NAME}"

  [[ ! -d "$APP_DIR" ]] && { log_error "App dir not found: $APP_DIR"; exit 1; }
  [[ ! -f "$CHART_DIR/Chart.yaml" ]] && { log_error "Chart not found: $CHART_DIR/Chart.yaml"; exit 1; }

  log_info "Building ${APP_NAME} image"
  eval "$(minikube -p "${PROFILE}" docker-env)"
  docker build -t "${APP_NAME}:latest" "${APP_DIR}"

  if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
    [[ ! -f "argocd/apps/${APP_NAME}.yaml" ]] && { log_error "ArgoCD manifest not found"; exit 1; }
    kubectl apply -f "argocd/apps/${APP_NAME}.yaml"
    log_info "${APP_NAME} registered with ArgoCD"
  else
    require_cmd helm
    kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"
    helm upgrade --install "$APP_NAME" "$CHART_DIR" -n "$NAMESPACE" --create-namespace
    log_info "${APP_NAME} deployed via Helm to ${NAMESPACE}"
  fi
}

undeploy_app() {
  require_cmd kubectl

  if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
    if kubectl -n argocd get application "$APP_NAME" >/dev/null 2>&1; then
      kubectl -n argocd delete application "$APP_NAME"
      log_info "${APP_NAME} removed from ArgoCD"
    else
      log_error "ArgoCD application ${APP_NAME} not found"
      exit 1
    fi
  else
    require_cmd helm
    if helm list -A 2>/dev/null | grep -q "^${APP_NAME}[[:space:]]"; then
      NS=$(helm list -A | grep "^${APP_NAME}[[:space:]]" | awk '{print $2}')
      helm uninstall "$APP_NAME" -n "$NS"
      log_info "${APP_NAME} uninstalled from ${NS}"
    else
      log_error "Helm release ${APP_NAME} not found"
      exit 1
    fi
  fi
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
      --app-name) APP_NAME="${2:?--app-name requires a value}"; shift 2 ;;
      --method) DEPLOY_METHOD="${2:?--method requires a value}"; shift 2 ;;
      --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
      --namespace) NAMESPACE="${2:?--namespace requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Validate deployment method
  [[ "$DEPLOY_METHOD" != "gitops" && "$DEPLOY_METHOD" != "helm" ]] && {
    log_error "Invalid method: $DEPLOY_METHOD (must be gitops or helm)"
    exit 1
  }

  # Execute command
  case "$COMMAND" in
    deploy) deploy_app ;;
    undeploy) undeploy_app ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
