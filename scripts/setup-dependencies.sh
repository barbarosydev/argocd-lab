#!/usr/bin/env bash
set -euo pipefail

# Shared helpers
# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

export LOG_PREFIX="setup"

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
