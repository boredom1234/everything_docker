#!/usr/bin/env bash
# Thin wrapper so users without 'make' can still use the same targets.
# Usage: ./make.sh <target> <tool> [WORKSPACE=...]
# Example: ./make.sh build coderabbit

set -e

if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ -z "$1" ]; then
  echo "Usage: ./make.sh <target> <tool> [WORKSPACE=/path/to/project]"
  echo ""
  echo "Targets: build | up | down | shell | rebuild | ps | clean"
  echo "Tools:   coderabbit | codex"
  echo ""
  echo "Current env: WORKSPACE=${WORKSPACE:-<not set>}"
  exit 0
fi

if command -v make >/dev/null 2>&1; then
  exec make "$@"
fi

# Pure-bash fallback if 'make' is missing.
TARGET="$1"
TOOL="${2:-coderabbit}"

if [ -z "${WORKSPACE:-}" ]; then
  echo "ERROR: WORKSPACE not set."
  echo "       Set it like:  export WORKSPACE=/path/to/project"
  exit 1
fi

COMPOSE="docker compose -f ${TOOL}/docker-compose.yml"

case "$TARGET" in
  build)   $COMPOSE build ;;
  up)      WORKSPACE="$WORKSPACE" $COMPOSE up -d ;;
  down)    $COMPOSE down ;;
  shell)   $COMPOSE exec "$TOOL" bash ;;
  rebuild) $COMPOSE build --no-cache ;;
  ps)      $COMPOSE ps ;;
  clean)   $COMPOSE down --rmi local -v ;;
  *)
    echo "Unknown target: $TARGET"
    echo "Targets: build | up | down | shell | rebuild | ps | clean"
    exit 1
    ;;
esac
