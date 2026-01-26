#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""

show_help() {
  cat <<EOF
Quality checks and formatting for ArgoCD Lab.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  validate    Run all validation checks
  hooks       Install pre-commit hooks
  run         Run pre-commit hooks

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output

Examples:
  $(basename "$0") validate
  $(basename "$0") hooks

EOF
}

validate_all() {
  require_cmd pre-commit uv

  log_info "Running pre-commit hooks..."

  if [[ "${LAB_VERBOSE:-0}" -eq 1 ]]; then
    pre-commit run --all-files
  else
    pre-commit run --all-files || {
      log_error "Pre-commit checks failed. Fix errors and run again."
      exit 1
    }
  fi

  log_info "Building documentation..."
  if [[ "${LAB_VERBOSE:-0}" -eq 1 ]]; then
    uv run --project docs mkdocs build
  else
    uv run --project docs mkdocs build >/dev/null 2>&1 || {
      log_error "Documentation build failed. Run with --verbose for details."
      exit 1
    }
  fi

  log_info "All validation checks passed"
}

install_hooks() {
  require_cmd pre-commit

  log_info "Installing pre-commit hooks"
  pre-commit install
  log_info "Pre-commit hooks installed"
}

run_hooks() {
  require_cmd pre-commit

  log_info "Running pre-commit hooks..."
  pre-commit run --all-files
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
    validate) validate_all ;;
    hooks) install_hooks ;;
    run) run_hooks ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
