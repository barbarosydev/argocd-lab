#!/usr/bin/env bash
set -euo pipefail

log() { echo "[install] $1"; }

# Ensure Homebrew is available
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required on macOS. Install from https://brew.sh" >&2
  exit 1
fi

# Update brew
log "Updating Homebrew"
brew update

# Install CLI tools via Homebrew (macOS only)
# Docs are managed via uv (see docs/pyproject.toml), so mkdocs packages are not installed via Homebrew.
for pkg in jq minikube kubectl helm uv pre-commit; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    log "'$pkg' already installed"
  else
    log "Installing '$pkg'"
    brew install "$pkg"
  fi
done

# Install pre-commit hooks if in a git repository
if [ -d .git ]; then
  log "Installing pre-commit hooks"
  pre-commit install
fi

log "Install complete (macOS only)"
