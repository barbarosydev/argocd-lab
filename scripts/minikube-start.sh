#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env
LOG_PREFIX="minikube-start"

PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
K8S_VERSION="${LAB_K8S_VERSION:-v1.35.0}"
DRIVER="${LAB_MINIKUBE_DRIVER:-docker}"
CPUS="${LAB_MINIKUBE_CPUS:-4}"
MEMORY="${LAB_MINIKUBE_MEMORY:-8192}"
DISK_SIZE="${LAB_MINIKUBE_DISK_SIZE:-20g}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
    --k8s-version) K8S_VERSION="${2:?--k8s-version requires a value}"; shift 2 ;;
    --driver) DRIVER="${2:?--driver requires a value}"; shift 2 ;;
    --cpus) CPUS="${2:?--cpus requires a value}"; shift 2 ;;
    --memory) MEMORY="${2:?--memory requires a value}"; shift 2 ;;
    --disk-size) DISK_SIZE="${2:?--disk-size requires a value}"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--profile NAME] [--k8s-version VERSION] [--driver DRIVER] [--cpus NUM] [--memory MB] [--disk-size SIZE]"; exit 0 ;;
    *) log_error "Unknown arg: $1"; exit 1 ;;
  esac
done

require_cmd minikube kubectl jq

log_info "Starting Minikube '${PROFILE}' (k8s ${K8S_VERSION}, driver=${DRIVER}, cpus=${CPUS}, memory=${MEMORY}MB, disk=${DISK_SIZE})"

if ! minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
  minikube start -p "$PROFILE" --kubernetes-version="${K8S_VERSION}" --driver="${DRIVER}" --cpus="${CPUS}" --memory="${MEMORY}" --disk-size="${DISK_SIZE}"
else
  minikube -p "$PROFILE" status >/dev/null 2>&1 || minikube start -p "$PROFILE" --kubernetes-version="${K8S_VERSION}" --driver="${DRIVER}" --cpus="${CPUS}" --memory="${MEMORY}" --disk-size="${DISK_SIZE}"
fi

minikube -p "$PROFILE" update-context >/dev/null 2>&1
log_info "Minikube ready"
