#!/usr/bin/env bash
# =============================================================================
# migrate.sh — schema-only, DATA-PRESERVING database migration.
#
#   ./migrate.sh                # safety backup → additive schema sync
#   ./migrate.sh --no-backup    # skip the safety backup (not recommended)
#
# Use this when a new release ships schema changes and you want to migrate the
# EXISTING database in place without rolling the app image (for the combined
# app + db upgrade, use ./update.sh — it calls this same migration one-shot).
#
# Guarantees (all enforced by the `migrate` one-shot in docker-compose.yml):
#   • NEVER initializes: refuses to run against an empty database, never
#     creates a database (DB_INIT_CREATE_DB=false), never seeds or overwrites
#     rows (DB_INIT_SEED=false) — your data is not touched.
#   • ADDITIVE-ONLY: applies db/<version>/migrate-*.sql; a DESTRUCTIVE change is
#     flagged REQUIRES-REVIEW and refused unless ALLOW_DESTRUCTIVE_MIGRATION=1.
#   • The migration SQL is the shipped db/<version>/ set — no source, no clone.
#     Keep DB_VERSION (./.env) aligned with the APP_IMAGE version.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

DO_BACKUP=true
for arg in "$@"; do
  case "$arg" in
    --no-backup) DO_BACKUP=false ;;
    -h|--help)   grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,20p'; exit 0 ;;
    *) die "unknown flag: $arg (see --help)" ;;
  esac
done

init_docker
acquire_lock

# ── Preflight ────────────────────────────────────────────────────────────────
hdr "Preflight"
[ -f .env ] || die "no ./.env here — run ./install.sh first"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running — start the stack first (./install.sh)"
wait_healthy postgres 60 >/dev/null || die "postgres is not healthy"

# Fresh-database guard: migrating an EMPTY database would de-facto initialize
# a schema with no admin/org/seeds — that is install.sh/bootstrap territory.
# A FAILED count query (empty/non-numeric) is fatal too: never guess.
TABLES=$(table_count)
assert_numeric "$TABLES" "the table count"
if [ "$TABLES" = "0" ]; then
  die "the database is EMPTY — there is nothing to migrate.
  This script never initializes a database (by design, so it can never
  clobber a mis-targeted one). For first-time provisioning run: ./install.sh"
fi
DB_DIR=$(db_dir) || die "no SQL artifacts under ./db — set DB_VERSION in ./.env to the release you are migrating to."
log "existing database: $TABLES tables — migrating in place using ./$DB_DIR"

# ── Safety backup ────────────────────────────────────────────────────────────
if $DO_BACKUP; then
  hdr "Safety backup"
  ./backup.sh || die "backup failed — refusing to migrate without one (override with --no-backup)"
else
  warn "skipping the safety backup (--no-backup)"
fi

# ── Additive-only schema sync (static migrate-*.sql applied by psql) ─────────
hdr "Schema migration"
if apply_migrations; then
  ok "schema migrated (additive-only; no data rows were modified)"
else
  ok "no pending migrations for ./$DB_DIR — schema already matches this release"
fi

# ── Verify the running app (if any) still passes its health gate ─────────────
APP_CID=$(compose ps -q app 2>/dev/null | head -n1 || true)
if [ -n "$APP_CID" ]; then
  hdr "Health check"
  health_gate 120 || die "the app is unhealthy after the migration — inspect: $DOCKER compose logs app"
fi

hdr "Migration complete"
ok "database schema is in sync ($(table_count) tables); data preserved"
log "to also roll the app onto a new image:  ./update.sh"
