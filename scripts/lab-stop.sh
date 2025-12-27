#!/usr/bin/env bash
set -euo pipefail

# lab-stop.sh: stop local lab (delete Minikube and stop port-forward)
PROFILE=${MINIKUBE_PROFILE:-${CLUSTER_NAME:-argocd-lab}}

log() { echo "[lab-stop] $1"; }
err() { echo "[lab-stop] ERROR: $1" >&2; }

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

if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  log "Deleting Minikube profile '${PROFILE}'"
  minikube delete -p "$PROFILE"
else
  log "Profile '${PROFILE}' not found. Nothing to delete."
fi

log "Stopping Argo CD port-forward if running"
if pgrep -f "kubectl port-forward svc/argocd-server" >/dev/null; then
  pkill -f "kubectl port-forward svc/argocd-server"
fi

log "Lab stopped"
