#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
LOG_PREFIX="deploy-app"

PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
APP_NAME=""
NAMESPACE="${LAB_APP_NAMESPACE:-default}"
DEPLOY_METHOD="${LAB_DEPLOY_METHOD:-gitops}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="${2:?requires value}"; shift 2 ;;
    --method) DEPLOY_METHOD="${2:?requires value}"; shift 2 ;;
    --profile) PROFILE="${2:?requires value}"; shift 2 ;;
    --namespace) NAMESPACE="${2:?requires value}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --app-name NAME [--method gitops|helm] [--profile NAME] [--namespace NS]"; exit 0 ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$APP_NAME" ]] && { log_error "Application name required (--app-name)"; exit 1; }
[[ "$DEPLOY_METHOD" != "gitops" && "$DEPLOY_METHOD" != "helm" ]] && { log_error "Invalid method: $DEPLOY_METHOD"; exit 1; }

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
  kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"
  helm upgrade --install "$APP_NAME" "$CHART_DIR" -n "$NAMESPACE" --create-namespace
  log_info "${APP_NAME} deployed via Helm to ${NAMESPACE}"
fi
