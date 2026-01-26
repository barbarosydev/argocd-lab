#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
K8S_VERSION="${LAB_K8S_VERSION:-v1.35.0}"
DRIVER="${LAB_MINIKUBE_DRIVER:-docker}"
CPUS="${LAB_MINIKUBE_CPUS:-8}"
MEMORY="${LAB_MINIKUBE_MEMORY:-16384}"
DISK_SIZE="${LAB_MINIKUBE_DISK_SIZE:-40g}"

show_help() {
  cat <<EOF
Manage Minikube cluster for ArgoCD lab.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  start       Start Minikube cluster
  stop        Stop Minikube cluster (preserves data)
  delete      Delete Minikube cluster completely
  status      Show cluster status

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  --profile NAME          Minikube profile name (default: argocd-lab)
  --k8s-version VERSION   Kubernetes version (default: v1.35.0)
  --driver DRIVER         Minikube driver (default: docker)
  --cpus NUM              Number of CPUs (default: 8)
  --memory MB             Memory in MB (default: 16384)
  --disk-size SIZE        Disk size (default: 40g)

Examples:
  $(basename "$0") start
  $(basename "$0") start --cpus 4 --memory 8192
  $(basename "$0") stop
  $(basename "$0") delete

EOF
}

start_minikube() {
  require_cmd minikube kubectl jq

  log_info "Starting Minikube '${PROFILE}' (k8s ${K8S_VERSION}, driver=${DRIVER})"

  if ! minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
    minikube start -p "$PROFILE" \
      --kubernetes-version="$K8S_VERSION" \
      --driver="$DRIVER" \
      --cpus="${CPUS}" \
      --memory="${MEMORY}" \
      --disk-size="${DISK_SIZE}"
  else
    minikube -p "$PROFILE" status >/dev/null 2>&1 || minikube start -p "$PROFILE" \
      --kubernetes-version="$K8S_VERSION" \
      --driver="$DRIVER" \
      --cpus="${CPUS}" \
      --memory="${MEMORY}" \
      --disk-size="${DISK_SIZE}"
  fi

  minikube -p "$PROFILE" update-context >/dev/null 2>&1
  log_info "Minikube ready"
}

stop_minikube() {
  require_cmd minikube jq

  if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
    log_info "Stopping Minikube profile '${PROFILE}' (preserving data)"
    minikube stop -p "$PROFILE"
  else
    log_info "Profile '${PROFILE}' not found"
  fi

  pkill -f "kubectl port-forward" 2>/dev/null && log_info "Port-forwards stopped" || true
  log_info "Minikube stopped"
}

delete_minikube() {
  require_cmd minikube jq

  if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
    log_info "Deleting Minikube profile '${PROFILE}'"
    minikube delete -p "$PROFILE"
  else
    log_info "Profile '${PROFILE}' not found"
  fi

  pkill -f "kubectl port-forward" 2>/dev/null && log_info "Port-forwards stopped" || true
  log_info "Minikube deleted"
}

status_minikube() {
  require_cmd minikube

  log_info "Minikube cluster status for profile '${PROFILE}'"
  minikube -p "$PROFILE" status || log_warn "Profile '${PROFILE}' not running"
}

main() {
  # Parse command first
  if [[ $# -eq 0 ]]; then
    show_help
    exit 1
  fi

  COMMAND="$1"
  shift

  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) show_help; exit 0 ;;
      -v|--verbose) export LAB_VERBOSE=1; shift ;;
      --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
      --k8s-version) K8S_VERSION="${2:?--k8s-version requires a value}"; shift 2 ;;
      --driver) DRIVER="${2:?--driver requires a value}"; shift 2 ;;
      --cpus) CPUS="${2:?--cpus requires a value}"; shift 2 ;;
      --memory) MEMORY="${2:?--memory requires a value}"; shift 2 ;;
      --disk-size) DISK_SIZE="${2:?--disk-size requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Execute command
  case "$COMMAND" in
    start) start_minikube ;;
    stop) stop_minikube ;;
    delete) delete_minikube ;;
    status) status_minikube ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
