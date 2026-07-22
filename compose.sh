#!/usr/bin/env bash
# =============================================================================
# compose.sh — pin-honoring `docker compose` wrapper for manual operations.
#
#   ./compose.sh ps
#   ./compose.sh logs -f app
#   ./compose.sh up -d app
#
# Use this instead of raw `docker compose` in this directory: after a failed
# update auto-rolls back, a digest pin (.rollback-image.yml) keeps the app on
# the last-good image — raw `docker compose up` would bypass it and redeploy
# the known-broken .env image. This wrapper (like every script here) applies
# the pin automatically while it exists.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh
init_docker
compose "$@"
