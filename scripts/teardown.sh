#!/usr/bin/env zsh
log "Teardown complete"

pgrep -f "kubectl port-forward svc/argocd-server" >/dev/null && pkill -f "kubectl port-forward svc/argocd-server" || true
log "Stopping Argo CD port-forward if running"
# Kill any port-forward processes

fi
  log "Cluster '${CLUSTER_NAME}' not found. Nothing to delete."
else
  kind delete cluster --name "$CLUSTER_NAME"
  log "Deleting kind cluster '${CLUSTER_NAME}'"
if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then

log() { echo "[teardown] $1"; }

CLUSTER_NAME="argocd-lab"

set -euo pipefail
