#!/usr/bin/env zsh
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
for pkg in kind kubectl helm uv mkdocs mkdocs-material; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    log "'$pkg' already installed"
  else
    log "Installing '$pkg'"
    brew install "$pkg"
  fi
done

log "Install complete (macOS only)"
