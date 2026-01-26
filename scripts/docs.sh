#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

load_env

COMMAND=""
DOCS_DIR="docs"
SITE_DIR="site"

show_help() {
  cat <<EOF
Manage MkDocs documentation.

Usage: $(basename "$0") COMMAND [OPTIONS]

Commands:
  serve       Serve documentation with live reload
  build       Build static documentation
  clean       Clean documentation artifacts

Options:
  -h, --help       Show this help message
  --verbose        Enable verbose output

Examples:
  $(basename "$0") serve
  $(basename "$0") build
  $(basename "$0") clean

EOF
}

serve_docs() {
  require_cmd uv

  log_info "Starting documentation server with live reload"
  log_info "Documentation will be available at http://127.0.0.1:8000"
  log_info "Press Ctrl+C to stop"
  echo ""

  uv run --project "$DOCS_DIR" mkdocs serve
}

build_docs() {
  require_cmd uv

  log_info "Building static documentation"

  uv run --project "$DOCS_DIR" mkdocs build

  log_info "Documentation built in ${SITE_DIR}/"
}

clean_docs() {
  log_info "Cleaning documentation artifacts"

  rm -rf "$SITE_DIR" "${DOCS_DIR}/site" 2>/dev/null || true
  find "$DOCS_DIR" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

  log_info "Documentation artifacts cleaned"
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
    serve) serve_docs ;;
    build) build_docs ;;
    clean) clean_docs ;;
    *) log_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
  esac
}

main "$@"
