#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""

show_help() {
  cat <<EOF
Utility commands for ArgoCD Lab.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  clean       Clean local artifacts
  install     Install dependencies (macOS)
  update      Update dependencies
  info        Show environment info

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output

Examples:
  $(basename "$0") clean
  $(basename "$0") install
  $(basename "$0") info

EOF
}

clean_artifacts() {
  log_info "Removing temporary files..."
  rm -rf site docs/site .venv docs/.venv 2>/dev/null || true
  find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
  rm -f /tmp/argocd-port-forward*.log 2>/dev/null || true
  log_info "Done"
}

install_dependencies() {
  # Ensure Homebrew is available
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew is required on macOS. Install from https://brew.sh"
    exit 1
  fi

  log_info "Updating Homebrew"
  brew update

  PACKAGES=(jq minikube kubectl helm uv pre-commit)
  for pkg in "${PACKAGES[@]}"; do
    if brew list --formula "$pkg" >/dev/null 2>&1; then
      log_debug "'$pkg' already installed"
    else
      log_info "Installing '$pkg'"
      brew install "$pkg"
    fi
  done

  # Install pre-commit hooks if in a git repository
  if [ -d .git ]; then
    log_info "Installing pre-commit hooks"
    pre-commit install
  fi

  log_info "Setup complete"
}

update_dependencies() {
  log_info "Updating dependencies"

  # Update pre-commit hooks
  if command -v pre-commit >/dev/null 2>&1; then
    log_info "Updating pre-commit hooks"
    pre-commit autoupdate
  fi

  # Update brew packages
  if command -v brew >/dev/null 2>&1; then
    log_info "Updating Homebrew packages"
    brew upgrade kubectl helm minikube 2>/dev/null || log_warn "Some packages may not need updating"
  else
    log_warn "Homebrew not available"
  fi

  log_info "Update complete"
}

show_info() {
  local profile="${LAB_MINIKUBE_PROFILE:-argocd-lab}"
  local k8s_version="${LAB_K8S_VERSION:-v1.35.0}"
  local argocd_namespace="${LAB_ARGOCD_NAMESPACE:-argocd}"
  local argocd_port="${LAB_ARGOCD_PORT:-8081}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ArgoCD Lab Environment Info"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Tools
  echo "🛠️  Installed Tools:"
  local k h m j u
  k=$(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'Not installed')
  h=$(helm version --short 2>/dev/null | cut -d'+' -f1 || echo 'Not installed')
  m=$(minikube version --short 2>/dev/null || echo 'Not installed')
  j=$(jq --version 2>/dev/null || echo 'Not installed')
  u=$(uv --version 2>/dev/null || echo 'Not installed')
  echo "   kubectl:     $k"
  echo "   helm:        $h"
  echo "   minikube:    $m"
  echo "   jq:          $j"
  echo "   uv:          $u"
  echo ""

  # Configuration
  echo "⚙️  Configuration:"
  echo "   Profile:     $profile"
  echo "   K8s Version: $k8s_version"
  echo "   Namespace:   $argocd_namespace"
  echo "   ArgoCD Port: $argocd_port"
  echo ""

  # Current context
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null || echo 'None')
  echo "📍 Current Context: $ctx"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
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
      --verbose) export LAB_VERBOSE=1; shift ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  # Execute command
  case "$COMMAND" in
    clean) clean_artifacts ;;
    install) install_dependencies ;;
    update) update_dependencies ;;
    info) show_info ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
