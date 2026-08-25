#!/usr/bin/env bash
# =============================================================================
# migrate.sh — schema-only, DATA-PRESERVING database migration.
#
#   ./migrate.sh                # safety backup → additive schema sync
#   ./migrate.sh --no-backup    # skip the safety backup (not recommended)
#
# Use this when a new release ships schema changes and you want to migrate the
# EXISTING database in place without rolling the app image (for the combined
# app + db upgrade, use ./update.sh — it applies the same migration set).
#
# Guarantees (enforced by this script + apply_migrations in lib.sh, applying
# static SQL via psql inside the postgres container):
#   • NEVER initializes: refuses to run against an empty database and never
#     seeds or overwrites rows — your data is not touched.
#   • ADDITIVE-ONLY by default: applies db/<version>/migrate-*.sql; a
#     DESTRUCTIVE change is flagged REQUIRES-REVIEW and refused unless
#     ALLOW_DESTRUCTIVE_MIGRATION=1 (after that, roll the matching image
#     with ./update.sh — the old image is expected to fail the health gate).
#   • Adopted/restored DBs: if the migration marker is empty, set
#     ADOPT_SCHEMA_VERSION=<the schema's actual release> so already-present
#     migrations are stamped instead of re-applied.
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
    -h|--help)   sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
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
# a schema with no admin/org/seeds — that is install.sh territory.
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

# Initialize the marker for an ADOPTED database (honors ADOPT_SCHEMA_VERSION);
# no-op for a this-flow deployment. Deliberately BEFORE the safety backup:
# marker rows are trivially-removable metadata, and dying below (pre-backup,
# pre-mutation) is the cheapest possible failure.
reconcile_marker "$(basename "$DB_DIR")"
if [ -z "${ADOPT_SCHEMA_VERSION:-}" ]; then
  # Guard: an EMPTY marker with pending migrate files means an adopted or
  # pre-marker-restored schema — blindly applying every migrate-*.sql would
  # re-run DDL it may already contain (destructive files included when
  # ALLOW_DESTRUCTIVE_MIGRATION=1). Fail closed on the marker read.
  # (ADOPT_SCHEMA_VERSION set to a release OLDER than every migrate file
  # legitimately stamps nothing — that case must fall through, hence the
  # unset-check above rather than re-testing emptiness after reconcile.)
  MARKER_N=$(marker_row_count)
  [ -n "$MARKER_N" ] || die "could not read the migration marker (postgres busy?) — re-run when stable"
  if [ "$MARKER_N" = "0" ] && [ -n "$(migration_files_through "$(basename "$DB_DIR")")" ]; then
    die "the migration marker is EMPTY but migrations exist for $(basename "$DB_DIR").
  Applying them blindly would re-run DDL an adopted/restored schema may already
  contain. Confirm the schema's ACTUAL release and re-run:
    ADOPT_SCHEMA_VERSION=<its release> ./migrate.sh
  (already-present migrations are then stamped; only newer ones are applied)."
  fi
fi

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
  if ! health_gate 120; then
    if [ "$APPLIED_DESTRUCTIVE" = "true" ]; then
      # EXPECTED, not an error: a REQUIRES-REVIEW migration is by definition
      # incompatible with the still-running old image (that is why update.sh
      # routed it here). The migration itself SUCCEEDED — exit 0 so the
      # documented recovery chain (./migrate.sh && ./update.sh) proceeds.
      warn "the running app failed the health gate — EXPECTED after a destructive"
      warn "migration: the current image predates the schema change. Roll the app"
      warn "onto the matching release now:  ./update.sh"
      warn "(If ./update.sh's gate ALSO fails, the outage predates this migration.)"
    else
      die "the app is unhealthy after the migration — inspect: $DOCKER compose logs app"
    fi
  fi
fi

hdr "Migration complete"
ok "database schema is in sync ($(table_count) tables); data preserved"
log "to also roll the app onto a new image:  ./update.sh"
