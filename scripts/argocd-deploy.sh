#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
LOG_PREFIX="argocd-deploy"

ARGOCD_NAMESPACE="${LAB_ARGOCD_NAMESPACE:-argocd}"
ARGO_VALUES="${LAB_ARGO_VALUES:-k8s/argocd/values.yaml}"
ARGOCD_PORT="${LAB_ARGOCD_PORT:-8081}"
ARGOCD_HELM_VERSION="${LAB_ARGOCD_HELM_VERSION:-9.3.4}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --argocd-namespace) ARGOCD_NAMESPACE="${2:?requires value}"; shift 2 ;;
    --argo-values) ARGO_VALUES="${2:?requires value}"; shift 2 ;;
    --port) ARGOCD_PORT="${2:?requires value}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--argocd-namespace NAME] [--argo-values PATH] [--port PORT]"; exit 0 ;;
    *) log_error "Unknown arg: $1"; exit 1 ;;
  esac
done

require_cmd kubectl helm

log_info "Deploying Argo CD (ns=${ARGOCD_NAMESPACE}, chart=${ARGOCD_HELM_VERSION})"

kubectl get ns "$ARGOCD_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$ARGOCD_NAMESPACE"

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

HELM_ARGS=(--namespace "$ARGOCD_NAMESPACE" --create-namespace -f "$ARGO_VALUES" --version "$ARGOCD_HELM_VERSION")
[[ -n "${GITHUB_PAT:-}" ]] && HELM_ARGS+=(--set "configs.repositories.argocd-lab-repo.password=${GITHUB_PAT}")

helm upgrade --install argocd argo/argo-cd "${HELM_ARGS[@]}" >/dev/null 2>&1

log_info "Waiting for Argo CD to be ready..."
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=180s >/dev/null 2>&1 || true

# Port-forward
pkill -f "kubectl port-forward svc/argocd-server" 2>/dev/null || true
sleep 1
nohup kubectl -n "${ARGOCD_NAMESPACE}" port-forward svc/argocd-server "${ARGOCD_PORT}":443 >/tmp/argocd-port-forward.log 2>&1 &
sleep 2

log_info "Argo CD ready at http://localhost:${ARGOCD_PORT}"
log_info "Get password: task argocd:password"
[[ -z "${GITHUB_PAT:-}" ]] && log_warn "GITHUB_PAT not set - private repos won't work"
