#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
ARGOCD_NAMESPACE="${LAB_ARGOCD_NAMESPACE:-argocd}"
ARGO_VALUES="${LAB_ARGO_VALUES:-k8s/argocd/values.yaml}"
ARGOCD_PORT="${LAB_ARGOCD_PORT:-8081}"
ARGOCD_HELM_VERSION="${LAB_ARGOCD_HELM_VERSION:-9.3.4}"

show_help() {
  cat <<EOF
Manage Argo CD deployment and operations.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  bootstrap   Deploy/upgrade Argo CD
  password    Get admin password
  ui          Open UI in browser

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  --namespace NAME        ArgoCD namespace (default: argocd)
  --values PATH           Values file path (default: k8s/argocd/values.yaml)
  --port PORT             Port for UI (default: 8081)
  --version VERSION       Helm chart version (default: 9.3.4)

Examples:
  $(basename "$0") bootstrap
  $(basename "$0") password
  $(basename "$0") ui --port 8082

EOF
}

bootstrap_argocd() {
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
  if [[ -z "${GITHUB_PAT:-}" ]]; then
    log_warn "GITHUB_PAT not set - private repos won't work"
  fi
}

get_password() {
  require_cmd kubectl

  log_info "ArgoCD Admin Password:"
  kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d && echo
}

open_ui() {
  require_cmd kubectl

  log_info "Opening ArgoCD UI at http://localhost:${ARGOCD_PORT}"
  open "http://localhost:${ARGOCD_PORT}"
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
      --namespace) ARGOCD_NAMESPACE="${2:?--namespace requires a value}"; shift 2 ;;
      --values) ARGO_VALUES="${2:?--values requires a value}"; shift 2 ;;
      --port) ARGOCD_PORT="${2:?--port requires a value}"; shift 2 ;;
      --version) ARGOCD_HELM_VERSION="${2:?--version requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Execute command
  case "$COMMAND" in
    bootstrap) bootstrap_argocd ;;
    password) get_password ;;
    ui) open_ui ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
