#!/usr/bin/env bash
# =============================================================================
# update.sh — safe rolling update to the latest published application image.
#
#   ./update.sh                # backup → pull → schema sync → roll → health gate
#   ./update.sh --no-backup    # skip the safety backup (not recommended)
#
# Order of operations (each stage aborts BEFORE the app is touched):
#   1. preflight (stack running, disk space)
#   2. safety backup (./backup.sh — pg_dump before anything mutates)
#   3. capture the current image digest = immutable rollback ref
#   4. docker compose pull app        (ONLY the app image — postgres/redis/
#      caddy are never restarted by an update; infra image updates apply on
#      ./install.sh re-runs instead)
#   5. additive-only schema sync      (one-shot `migrate`; a DESTRUCTIVE diff
#      fails loudly here and the running app keeps serving untouched)
#   6. docker compose up -d app       (single-container rolling restart)
#   7. health gate through the public ingress
#      → on FAILURE: automatic rollback to the captured digest + re-gate
#
# Never rebuilds anything, never runs `down`, never touches volumes.
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

# ── 1. Preflight ─────────────────────────────────────────────────────────────
hdr "Preflight"
[ -f .env ] || die "no ./.env here — run ./install.sh first"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "the stack is not running (no postgres container) — run ./install.sh"
wait_healthy postgres 60 >/dev/null || die "postgres is not healthy — fix the data tier before updating"
# The roll uses `up -d --no-deps app` (skips compose's depends_on healthy
# checks by design) — so verify redis here, BEFORE the old app is replaced.
wait_healthy redis 30 >/dev/null || die "redis is not healthy — fix the data tier before updating"
# Fresh-database guard: updating implies an EXISTING deployment. An empty DB
# means this is really a first install — refuse rather than half-provision
# (the migrate one-shot never seeds admin/org data). A FAILED count query
# (empty/non-numeric) is also fatal: never guess about provisioning state.
TABLES=$(table_count)
assert_numeric "$TABLES" "the table count"
[ "$TABLES" != "0" ] || die "the database is EMPTY — this is an update script, not an installer.
  For first-time provisioning run: ./install.sh"
AVAIL_KB=$(df -Pk . | awk 'NR==2 {print $4}')
if [ "${AVAIL_KB:-0}" -lt 2097152 ]; then
  warn "less than 2 GB free on this filesystem — image pull + backup may fail"
fi
APP_IMAGE=$(env_get .env APP_IMAGE "")
DB_VERSION_VAL=$(env_get .env DB_VERSION "")
log "target image: ${APP_IMAGE}  (SQL artifacts: ${DB_VERSION_VAL:-auto})"
# APP_IMAGE tag ↔ DB_VERSION alignment — FATAL, not a warning: db_target_version
# gives DB_VERSION precedence, so a stale DB_VERSION would cap the migration
# target BELOW the rolled image and silently skip the target release's schema.
assert_version_alignment

# ── 2. Safety backup ─────────────────────────────────────────────────────────
if $DO_BACKUP; then
  hdr "Safety backup"
  ./backup.sh || die "backup failed — refusing to update without one (override with --no-backup)"
else
  warn "skipping the safety backup (--no-backup)"
fi

# ── 3. Rollback reference ────────────────────────────────────────────────────
# The pin file (if present from a previous failed update) is deliberately NOT
# deleted here: it must survive a failure in any step below (pull, schema
# sync) so that install.sh/restore.sh keep honoring the last-good image. The
# pull/roll steps bypass it via compose_raw instead, and only a SUCCESSFUL
# update removes it.
hdr "Rollback reference"
PREV_DIGEST=$(app_image_digest)
if [ -z "$PREV_DIGEST" ] && [ -f "$ROLLBACK_PIN" ]; then
  # No running app container — recover the last-good digest from the pin.
  PREV_DIGEST=$(sed -n 's/^ *image: "\(.*\)"$/\1/p' "$ROLLBACK_PIN" | head -n1)
  [ -n "$PREV_DIGEST" ] && log "recovered rollback ref from $ROLLBACK_PIN"
fi
if [ -n "$PREV_DIGEST" ]; then
  ok "rollback image digest: $PREV_DIGEST"
else
  warn "no running app container, no pin — automatic rollback will not be available"
fi

# ── 4. Pull the latest APP image only ────────────────────────────────────────
# Deliberately scoped to `app`: an unscoped pull would also fetch new
# postgres/redis/caddy patch tags and the later `up -d` would then restart the
# DATA TIER mid-update — breaking this script's single-container-roll contract.
# Infrastructure image updates apply on ./install.sh re-runs instead, where a
# data-tier restart is an expected part of converging.
hdr "Pull"
# compose_raw: fetch the NEW .env image even while a rollback pin exists (the
# pin would otherwise redirect the pull to the old digest).
compose_raw pull app || die "image pull failed — the running stack is untouched"

# ── 5. Additive-only schema sync (runs BEFORE the app is rolled) ─────────────
# Applies the target version's static migrate-*.sql via psql (sourceless). A
# migration failure is fatal here — BEFORE the app is rolled — leaving the
# running app and any rollback pin untouched.
hdr "Schema sync"
DB_DIR=$(db_dir) || die "no SQL artifacts under ./db for the target version — set DB_VERSION in ./.env to match the new APP_IMAGE, then re-run."
# Initialize the marker for an adopted DB (honors ADOPT_SCHEMA_VERSION); no-op
# for a this-flow deployment. Without this, apply_migrations on an empty marker
# would re-apply migrations an adopted schema already contains.
reconcile_marker "$(basename "$DB_DIR")"
# Keep the rolling path additive-only: a destructive (REQUIRES-REVIEW) migration
# would break the auto-rollback's assumption that the OLD image stays schema-
# compatible. Route those through ./migrate.sh (backup-first, no auto-rollback).
# No `|| true`: has_pending_destructive fails closed (dies on a marker-read
# error). Here that is a clean pre-mutation abort — nothing has changed yet.
DESTRUCTIVE=$(has_pending_destructive)
[ -z "$DESTRUCTIVE" ] || die "a pending migration ($DESTRUCTIVE) is flagged REQUIRES-REVIEW
  (destructive). The rolling update path is additive-only. Apply it deliberately
  in a maintenance window: ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh   then re-run ./update.sh."
if apply_migrations; then
  ok "schema migrated to ./$DB_DIR"
else
  ok "no pending migrations — schema already matches the target release"
fi

# ── 6. Roll the app onto the new image ───────────────────────────────────────
# A failure of `up -d app` ITSELF (not just the health gate) must also land in
# the rollback path below — set -e would otherwise abort with the old
# container possibly already removed and no recovery attempted.
hdr "Rolling update"
ROLL_OK=true
# compose_raw: roll onto the NEW image, bypassing (but not deleting) the pin.
compose_raw up -d --no-deps app || ROLL_OK=false   # scoped: only the app container
NEW_DIGEST=$(app_image_digest)

# ── 7. Health gate → auto-rollback on failure ────────────────────────────────
hdr "Health gate"
if $ROLL_OK && health_gate 300; then
  ok "update complete"
  rm -f "$ROLLBACK_PIN"   # the update succeeded — retire the old safety pin
  [ -n "$PREV_DIGEST" ] && log "previous image (manual rollback ref): $PREV_DIGEST"
  [ -n "$NEW_DIGEST" ]  && log "now running:                          $NEW_DIGEST"
  exit 0
fi

if $ROLL_OK; then
  warn "health gate FAILED on the new image"
else
  warn "'compose up' FAILED while rolling the app onto the new image"
fi
if [ -z "$PREV_DIGEST" ]; then
  die "no rollback reference available — inspect: $DOCKER compose logs app caddy"
fi
if $ROLL_OK && [ "$PREV_DIGEST" = "${NEW_DIGEST:-}" ]; then
  die "the image did not actually change — this is not an image regression.
  Inspect: $DOCKER compose logs app caddy   (config/schema/secrets issue?)"
fi

hdr "Automatic rollback"
# The digest pin is written to an override FILE (not an env var): with
# DOCKER="sudo docker" an `APP_IMAGE=… sudo docker …` env prefix would be
# silently stripped by sudoers env_reset and the "rollback" would re-apply
# the broken .env image. Every compose invocation in this package honors the
# pin (see compose() in lib.sh), so restore.sh / install.sh re-runs keep the
# rolled-back image too, until a later successful update clears the file.
printf 'services:\n  app:\n    image: "%s"\n' "$PREV_DIGEST" > "$ROLLBACK_PIN"
log "re-pinning app to $PREV_DIGEST (via $ROLLBACK_PIN)…"
compose up -d --no-deps app || warn "rollback 'compose up' reported an error — checking health anyway…"
if health_gate 300; then
  warn "ROLLED BACK to $PREV_DIGEST — the update was NOT applied."
  warn "The schema sync already ran and is additive-only, so the old image is compatible."
  warn "The pin lives in $ROLLBACK_PIN and is honored by every script in this package"
  warn "(install/update/restore) until a later successful ./update.sh clears it."
  warn "Diagnose the new image before retrying:  $DOCKER compose logs app"
  warn "If data damage is suspected, restore the pre-update backup: ./restore.sh --yes"
  exit 1
fi
die "rollback did not become healthy either — inspect immediately:
  $DOCKER compose ps
  $DOCKER compose logs app caddy
  Pre-update backup is in ./backups (restore with ./restore.sh --yes)"
