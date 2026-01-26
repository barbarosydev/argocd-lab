#!/usr/bin/env bash
# check-lab-status.sh: Check the status of the lab environment

set -euo pipefail

# Shared helpers
# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
export LOG_PREFIX="lab-status"

PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
NS="${LAB_ARGOCD_NAMESPACE:-argocd}"
PORT="${LAB_ARGOCD_PORT:-8081}"

log_info "=== Lab Status ==="

# Minikube
if minikube status -p "$PROFILE" >/dev/null 2>&1; then
  log_info "Minikube: Running"
else
  log_warn "Minikube: Not running (task up)"
fi

# Kubectl context
log_info "Context: $(kubectl config current-context 2>/dev/null || echo 'None')"

# ArgoCD
if kubectl get ns "$NS" >/dev/null 2>&1; then
  log_info "ArgoCD namespace: OK"
  kubectl get pods -n "$NS" --no-headers 2>/dev/null | awk '{print "  " $1 ": " $3}' || true
else
  log_warn "ArgoCD namespace: Not found"
fi

# Port-forward
if pgrep -f "kubectl port-forward svc/argocd-server" >/dev/null; then
  log_info "Port-forward: Running (port $PORT)"
else
  log_warn "Port-forward: Not running"
fi

log_info "=== Done ==="
