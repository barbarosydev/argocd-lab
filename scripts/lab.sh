#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

PROFILE="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
ARGOCD_NAMESPACE="${LAB_ARGOCD_NAMESPACE:-argocd}"
ARGOCD_PORT="${LAB_ARGOCD_PORT:-8081}"

show_help() {
  cat <<EOF
Show ArgoCD Lab status and information.

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help              Show this help message
  -v, --verbose           Enable verbose output
  --profile NAME          Minikube profile name (default: argocd-lab)
  --namespace NAME        ArgoCD namespace (default: argocd)
  --port PORT             ArgoCD port (default: 8081)

Examples:
  $(basename "$0")
  $(basename "$0") --profile my-lab

EOF
}

show_status() {
  require_cmd kubectl minikube jq

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ArgoCD Lab Status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Minikube Status
  echo "🔬 Minikube Cluster (${PROFILE}):"
  if minikube profile list -o json 2>/dev/null | jq -e --arg p "$PROFILE" '.valid[]?.Name == $p' >/dev/null; then
    minikube -p "$PROFILE" status 2>/dev/null || log_warn "Profile exists but not running"
  else
    echo "   Status: Not found"
    echo ""
    log_warn "Minikube cluster not running. Run 'task lab:up' to start."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    return
  fi
  echo ""

  # ArgoCD Status
  echo "🔄 ArgoCD Status (${ARGOCD_NAMESPACE}):"
  if kubectl get ns "$ARGOCD_NAMESPACE" >/dev/null 2>&1; then
    local server_status
    server_status=$(kubectl -n "$ARGOCD_NAMESPACE" get deployment argocd-server -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null || echo "Unknown")

    if [[ "$server_status" == "True" ]]; then
      echo "   Server:      ✅ Ready"
    else
      echo "   Server:      ⏳ Not Ready"
    fi
    echo "   UI:          http://localhost:${ARGOCD_PORT}"
    echo "   Username:    admin"
    echo "   Password:    Run 'task argocd:password'"
  else
    echo "   Status:      Not deployed"
    echo ""
    log_warn "ArgoCD not deployed. Run 'task lab:up' to deploy."
  fi
  echo ""

  # Applications
  echo "📦 Deployed Applications:"
  if kubectl get ns "$ARGOCD_NAMESPACE" >/dev/null 2>&1; then
    local app_count
    app_count=$(kubectl -n "$ARGOCD_NAMESPACE" get applications --no-headers 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$app_count" -gt 0 ]]; then
      kubectl -n "$ARGOCD_NAMESPACE" get applications 2>/dev/null | head -n 10 || echo "   None"
    else
      echo "   None deployed"
    fi
  else
    echo "   ArgoCD not available"
  fi
  echo ""

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

main() {
  # Parse options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) show_help; exit 0 ;;
      -v|--verbose) export LAB_VERBOSE=1; shift ;;
      --profile) PROFILE="${2:?--profile requires a value}"; shift 2 ;;
      --namespace) ARGOCD_NAMESPACE="${2:?--namespace requires a value}"; shift 2 ;;
      --port) ARGOCD_PORT="${2:?--port requires a value}"; shift 2 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  show_status
}

main "$@"
