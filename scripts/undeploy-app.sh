#!/usr/bin/env bash
#
# Undeploy applications from Kubernetes/ArgoCD
#

set -euo pipefail

# Shared helpers
# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
LOG_PREFIX="undeploy-app"

APP_NAME=""
DEPLOY_METHOD="${LAB_DEPLOY_METHOD:-gitops}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name) APP_NAME="${2:?requires value}"; shift 2 ;;
    --method) DEPLOY_METHOD="${2:?requires value}"; shift 2 ;;
    -h|--help) echo "Usage: $0 --app-name NAME [--method gitops|helm]"; exit 0 ;;
    *) log_error "Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$APP_NAME" ]] && { log_error "Application name required (--app-name)"; exit 1; }
[[ "$DEPLOY_METHOD" != "gitops" && "$DEPLOY_METHOD" != "helm" ]] && { log_error "Invalid method: $DEPLOY_METHOD"; exit 1; }

if [[ "$DEPLOY_METHOD" == "gitops" ]]; then
  if kubectl -n argocd get application "$APP_NAME" >/dev/null 2>&1; then
    kubectl -n argocd delete application "$APP_NAME"
    log_info "${APP_NAME} removed from ArgoCD"
  else
    log_error "ArgoCD application ${APP_NAME} not found"
    exit 1
  fi
else
  if helm list -A 2>/dev/null | grep -q "^${APP_NAME}[[:space:]]"; then
    NS=$(helm list -A | grep "^${APP_NAME}[[:space:]]" | awk '{print $2}')
    helm uninstall "$APP_NAME" -n "$NS"
    log_info "${APP_NAME} uninstalled from ${NS}"
  else
    log_error "Helm release ${APP_NAME} not found"
    exit 1
  fi
fi
