#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
LOG_PREFIX="minikube-stop"

PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
PAUSE_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
    --pause) PAUSE_MODE=true; shift ;;
    -h|--help) echo "Usage: $0 [--profile NAME] [--pause]"; exit 0 ;;
    *) log_error "Unknown arg: $1"; exit 1 ;;
  esac
done

require_cmd minikube jq

if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  if [[ "$PAUSE_MODE" == "true" ]]; then
    log_info "Stopping Minikube profile '${PROFILE}' (preserving data)"
    minikube stop -p "$PROFILE"
  else
    log_info "Deleting Minikube profile '${PROFILE}'"
    minikube delete -p "$PROFILE"
  fi
else
  log_info "Profile '${PROFILE}' not found"
fi

pkill -f "kubectl port-forward" 2>/dev/null && log_info "Port-forwards stopped" || true
log_info "Lab stopped"
