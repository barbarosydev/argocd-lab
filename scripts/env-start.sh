#!/usr/bin/env bash
set -euo pipefail

# env-start.sh: start local Kubernetes (Minikube) environment
# Usage:
#   scripts/env-start.sh --profile argocd-lab --k8s-version v1.35.0

PROFILE=${MINIKUBE_PROFILE:-${CLUSTER_NAME:-argocd-lab}}
K8S_VERSION=${K8S_VERSION:-v1.35.0}
VERBOSE=${LAB_VERBOSE:-0}

log() { echo "[env-start] $1"; }
err() { echo "[env-start] ERROR: $1" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|--cluster-name)
      PROFILE=${2:-}
      [[ -z "$PROFILE" ]] && { err "--profile requires a value"; exit 1; }
      shift 2;
      ;;
    --k8s-version)
      K8S_VERSION=${2:-}
      [[ -z "$K8S_VERSION" ]] && { err "--k8s-version requires a value"; exit 1; }
      shift 2;
      ;;
    --verbose)
      VERBOSE=1; shift 1;
      ;;
    -h|--help)
      echo "Usage: $0 [--profile NAME] [--k8s-version VERSION] [--verbose]"; exit 0;
      ;;
    *)
      err "Unknown arg: $1"; exit 1;
      ;;
  esac
done

if [[ ${VERBOSE} -eq 1 ]]; then
  set -x
  exec 3>&1 4>&2
else
  exec 3>/dev/null 4>/dev/null
fi

log "Checking required commands: minikube, kubectl, jq"
for cmd in minikube kubectl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { err "'$cmd' is not installed"; exit 1; }
done

log "Creating/starting Minikube profile '${PROFILE}' (k8s ${K8S_VERSION})"
if ! minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  minikube start -p "$PROFILE" --kubernetes-version="$K8S_VERSION" >&3 2>&4
else
  minikube -p "$PROFILE" status >&3 2>&4 || minikube start -p "$PROFILE" --kubernetes-version="$K8S_VERSION" >&3 2>&4
fi

log "Setting kubectl context"
minikube -p "$PROFILE" update-context >&3 2>&4
kubectl cluster-info >&3 2>&4

log "Environment ready"
