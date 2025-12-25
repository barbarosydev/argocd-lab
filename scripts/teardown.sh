#!/usr/bin/env bash
set -euo pipefail

PROFILE=${MINIKUBE_PROFILE:-${CLUSTER_NAME:-argocd-lab}}

log() { echo "[teardown] $1"; }
err() { echo "[teardown] ERROR: $1" >&2; }

# Parse optional --profile/--cluster-name
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|--cluster-name)
      PROFILE=${2:-}
      [[ -z "$PROFILE" ]] && { err "--profile requires a value"; exit 1; }
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--profile NAME]"; exit 0;
      ;;
    *)
      err "Unknown arg: $1"; exit 1;
      ;;
  esac
done

# Delete minikube profile if exists
if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  log "Deleting Minikube profile '${PROFILE}'"
  minikube delete -p "$PROFILE"
else
  log "Profile '${PROFILE}' not found. Nothing to delete."
fi

log "Stopping Argo CD port-forward if running"
pgrep -f "kubectl port-forward svc/argocd-server" >/dev/null && pkill -f "kubectl port-forward svc/argocd-server" || true

log "Teardown complete"
