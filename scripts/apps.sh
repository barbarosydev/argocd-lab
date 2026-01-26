#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
ARGOCD_NAMESPACE="${LAB_ARGOCD_NAMESPACE:-argocd}"
APP_NAME="${LAB_APP_NAME:-demo-api}"
APP_NAMESPACE="${LAB_APP_NAMESPACE:-default}"
DEPLOY_METHOD="${LAB_DEPLOY_METHOD:-gitops}"
PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"

show_help() {
  cat <<EOF
Manage ArgoCD applications.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  list        List deployed applications
  sync        Sync all ArgoCD applications
  deploy      Deploy an application
  undeploy    Remove an application

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  --namespace NAME        ArgoCD namespace (default: argocd)
  --app-name NAME         Application name (default: demo-api)
  --app-namespace NS      App target namespace (default: default)
  --method METHOD         Deployment method gitops or helm (default: gitops)
  --profile NAME          Minikube profile (default: argocd-lab)

Examples:
  $(basename "$0") list
  $(basename "$0") sync
  $(basename "$0") deploy --app-name demo-api
  $(basename "$0") deploy --app-name demo-api --method helm
  $(basename "$0") undeploy --app-name demo-api

EOF
}

sync_apps() {
  require_cmd kubectl

  log_info "Syncing all ArgoCD applications"

  # Get all applications
  local apps
  apps=$(kubectl -n "$ARGOCD_NAMESPACE" get applications -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

  if [[ -z "$apps" ]]; then
    log_info "No applications found to sync"
    return
  fi

  # Sync each application
  for app in $apps; do
    log_info "Syncing application: $app"
    kubectl -n "$ARGOCD_NAMESPACE" patch application "$app" \
      --type merge \
      -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}' \
      2>/dev/null || log_warn "Failed to trigger sync for $app"
  done

  log_info "Sync triggered for all applications"
  log_info "Check status with: kubectl -n ${ARGOCD_NAMESPACE} get applications"
}

list_apps() {
  require_cmd kubectl

  log_info "ArgoCD Applications in namespace '${ARGOCD_NAMESPACE}'"
  echo ""

  if kubectl get ns "$ARGOCD_NAMESPACE" >/dev/null 2>&1; then
    local app_count
    app_count=$(kubectl -n "$ARGOCD_NAMESPACE" get applications --no-headers 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$app_count" -gt 0 ]]; then
      kubectl -n "$ARGOCD_NAMESPACE" get applications
    else
      echo "No applications deployed"
    fi
  else
    log_error "ArgoCD namespace '${ARGOCD_NAMESPACE}' not found"
    exit 1
  fi
  echo ""
}

deploy_app() {
  require_cmd kubectl docker minikube

  local app_dir="k8s/${APP_NAME}/app"
  local chart_dir="k8s/${APP_NAME}"

  [[ ! -d "$app_dir" ]] && { log_error "App dir not found: $app_dir"; exit 1; }
  [[ ! -f "$chart_dir/Chart.yaml" ]] && { log_error "Chart not found: $chart_dir/Chart.yaml"; exit 1; }

  log_info "Building ${APP_NAME} image"
  eval "$(minikube -p "${PROFILE}" docker-env)"
  docker build -t "${APP_NAME}:latest" "${app_dir}"

  if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
    [[ ! -f "argocd/apps/${APP_NAME}.yaml" ]] && { log_error "ArgoCD manifest not found"; exit 1; }
    kubectl apply -f "argocd/apps/${APP_NAME}.yaml"
    log_info "${APP_NAME} registered with ArgoCD"
  else
    require_cmd helm
    kubectl get ns "$APP_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$APP_NAMESPACE"
    helm upgrade --install "$APP_NAME" "$chart_dir" -n "$APP_NAMESPACE" --create-namespace
    log_info "${APP_NAME} deployed via Helm to ${APP_NAMESPACE}"
  fi
}

undeploy_app() {
  require_cmd kubectl

  if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
    if kubectl -n "$ARGOCD_NAMESPACE" get application "$APP_NAME" >/dev/null 2>&1; then
      kubectl -n "$ARGOCD_NAMESPACE" delete application "$APP_NAME"
      log_info "${APP_NAME} removed from ArgoCD"
    else
      log_error "ArgoCD application ${APP_NAME} not found"
      exit 1
    fi
  else
    require_cmd helm
    if helm list -A 2>/dev/null | grep -q "^${APP_NAME}[[:space:]]"; then
      local ns
      ns=$(helm list -A | grep "^${APP_NAME}[[:space:]]" | awk '{print $2}')
      helm uninstall "$APP_NAME" -n "$ns"
      log_info "${APP_NAME} uninstalled from ${ns}"
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
      -v|--verbose) export LAB_VERBOSE=1; shift ;;
      --namespace) ARGOCD_NAMESPACE="${2:?--namespace requires a value}"; shift 2 ;;
      --app-name) APP_NAME="${2:?--app-name requires a value}"; shift 2 ;;
      --app-namespace) APP_NAMESPACE="${2:?--app-namespace requires a value}"; shift 2 ;;
      --method) DEPLOY_METHOD="${2:?--method requires a value}"; shift 2 ;;
      --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Validate deployment method for deploy/undeploy commands
  if [[ "$COMMAND" == "deploy" || "$COMMAND" == "undeploy" ]]; then
    [[ "$DEPLOY_METHOD" != "gitops" && "$DEPLOY_METHOD" != "helm" ]] && {
      log_error "Invalid method: $DEPLOY_METHOD (must be gitops or helm)"
      exit 1
    }
  fi

  # Execute command
  case "$COMMAND" in
    list) list_apps ;;
    sync) sync_apps ;;
    deploy) deploy_app ;;
    undeploy) undeploy_app ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
