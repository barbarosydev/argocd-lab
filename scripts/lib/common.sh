#!/usr/bin/env bash
# Shared helpers for ArgoCD Lab scripts.
#
# This file is meant to be sourced (not executed).

set -euo pipefail

# Colors (can be disabled with LAB_NO_COLOR=1)
if [[ "${LAB_NO_COLOR:-0}" -eq 1 ]]; then
  COLOR_INFO=""
  COLOR_WARN=""
  COLOR_ERROR=""
  COLOR_DEBUG=""
  COLOR_RESET=""
else
  COLOR_INFO="\033[0;36m"   # cyan
  COLOR_WARN="\033[1;33m"   # yellow
  COLOR_ERROR="\033[0;31m"  # red
  COLOR_DEBUG="\033[0;35m"  # magenta
  COLOR_RESET="\033[0m"
fi

# Load env vars from .env without overriding already-set environment vars.
# Priority:
#   1) existing environment variables
#   2) .env file values
load_env() {
  local env_file="${ENV_FILE:-.env}"

  [[ -f "${env_file}" ]] || return 0

  # Read key=value lines, ignore comments/blank lines. Do not override existing env vars.
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue

    if [[ "${line}" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local val="${BASH_REMATCH[2]}"

      # Don't override already-set env vars.
      if [[ -z "${!key+x}" ]]; then
        export "${key}=${val}"
      fi
    fi
  done < "${env_file}"
}

log_info() {
  echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $*"
}

log_warn() {
  echo -e "${COLOR_WARN}[WARN]${COLOR_RESET} $*"
}

log_error() {
  echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $*" >&2
}

log_debug() {
  if [[ "${LAB_VERBOSE:-0}" -eq 1 ]]; then
    echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} $*"
  fi
}

require_cmd() {
  local cmd
  for cmd in "$@"; do
    command -v "${cmd}" >/dev/null 2>&1 || {
      log_error "'${cmd}' is not installed"
      return 1
    }
  done
}

# Simple arg parser helper
has_flag() {
  local flag="$1"; shift
  local arg
  for arg in "$@"; do
    if [[ "${arg}" == "${flag}" ]]; then
      return 0
    fi
  done
  return 1
}
