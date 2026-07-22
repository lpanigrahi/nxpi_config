#!/usr/bin/env bash
# =============================================================================
# restore.sh — restore a ./backup.sh dump into the running stack.
#
#   ./restore.sh --yes                          # newest ./backups/neogen-*.dump
#   ./restore.sh --yes backups/neogen-<ts>.dump
#   ./restore.sh --yes <dump> --uploads backups/uploads-<ts>.tar.gz
#   ./restore.sh --yes --no-backup <dump>       # skip the pre-restore backup
#
# DESTRUCTIVE: pg_restore --clean drops and recreates the application's
# objects from the dump — data written after the dump is LOST. A safety
# backup of the CURRENT state is taken first (so restoring the wrong dump is
# recoverable), the app is stopped for the duration, and restarted (with a
# health gate) afterwards.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

CONFIRMED=false
DO_BACKUP=true
DUMP=""
UPLOADS_TAR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --yes)       CONFIRMED=true ;;
    --no-backup) DO_BACKUP=false ;;
    --uploads)   shift; UPLOADS_TAR="${1:-}"; [ -n "$UPLOADS_TAR" ] || die "--uploads needs a file argument" ;;
    -h|--help)   grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,15p'; exit 0 ;;
    -*)          die "unknown flag: $1 (see --help)" ;;
    *)           DUMP="$1" ;;
  esac
  shift
done

init_docker
acquire_lock                    # e.g. a cron backup mid-restore would snapshot a half-restored DB
umask 077                       # the restore log may contain data fragments
mkdir -p backups
chmod 700 backups 2>/dev/null || true

# ── Resolve + confirm ────────────────────────────────────────────────────────
if [ -z "$DUMP" ]; then
  DUMP=$(ls -t backups/neogen-*.dump 2>/dev/null | head -n1 || true)
  [ -n "$DUMP" ] || die "no dump given and none found under ./backups"
fi
[ -s "$DUMP" ] || die "dump not found or empty: $DUMP"
[ -z "$UPLOADS_TAR" ] || [ -s "$UPLOADS_TAR" ] || die "uploads archive not found or empty: $UPLOADS_TAR"

hdr "Restore plan"
log "database dump : $DUMP ($(du -h "$DUMP" | cut -f1))"
[ -n "$UPLOADS_TAR" ] && log "uploads archive: $UPLOADS_TAR ($(du -h "$UPLOADS_TAR" | cut -f1))"
warn "this DROPS current data and replaces it with the dump contents"
if ! $CONFIRMED; then
  if [ -t 0 ]; then
    printf 'Type RESTORE to proceed: '
    read -r answer
    [ "$answer" = "RESTORE" ] || die "aborted"
  else
    die "non-interactive run requires --yes"
  fi
fi

PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running — start the stack first (./install.sh)"
# Validate BOTH archives before touching anything — the uploads volume is
# wiped before extraction, so a corrupt tar discovered mid-restore would mean
# data already destroyed.
compose exec -T postgres pg_restore --list < "$DUMP" >/dev/null \
  || die "$DUMP is not a valid pg_dump custom-format archive — nothing was touched"
if [ -n "$UPLOADS_TAR" ]; then
  case "$UPLOADS_TAR" in
    /*) UPLOADS_ABS="$UPLOADS_TAR" ;;
    *)  UPLOADS_ABS="$SCRIPT_DIR/$UPLOADS_TAR" ;;
  esac
  $DOCKER run --rm -v "$(dirname "$UPLOADS_ABS")":/in:ro \
    alpine tar tzf "/in/$(basename "$UPLOADS_ABS")" >/dev/null \
    || die "$UPLOADS_TAR failed the tar integrity check — nothing was touched"
  ok "uploads archive passed integrity check"
fi

# ── Safety backup of the CURRENT state (restoring the wrong dump must be
# recoverable — same backup-first contract as update.sh / migrate.sh).
# --no-prune: backup.sh's retention pruning could otherwise DELETE the very
# dump we are about to restore (any dump older than BACKUP_RETENTION_DAYS). ──
if $DO_BACKUP; then
  hdr "Safety backup (current state, before the restore)"
  # --require-uploads (only when we will wipe the uploads volume): backup.sh
  # normally treats an uploads-archive failure as best-effort, but here a
  # missing uploads safety copy would make a wrong --uploads restore
  # unrecoverable.
  BK_FLAGS="--no-prune"
  [ -n "$UPLOADS_TAR" ] && BK_FLAGS="$BK_FLAGS --require-uploads"
  # shellcheck disable=SC2086
  ./backup.sh $BK_FLAGS || die "safety backup failed — refusing to restore without one (override with --no-backup)"
else
  warn "skipping the pre-restore safety backup (--no-backup)"
fi
# Re-verify the dump is still there and intact before any mutation.
[ -s "$DUMP" ] || die "$DUMP disappeared before the restore could start — nothing was touched"

# ── Stop the app (frees connections so --clean can drop objects) ─────────────
# STRUCTURAL SAFETY NET: once the app is stopped AND the restore is verified
# good, ANY later exit (a delegated `die` in apply_migrations, an uploads
# failure, a transient DB hiccup) must still bring the app back — otherwise a
# successful restore could leave the site down. An EXIT trap guarantees it,
# independent of every intermediate command being die-free.
NEEDS_APP_RESTART=false
RESTORE_DEGRADED=false   # set true if a non-fatal step (uploads) failed → exit nonzero
restore_restart_trap() {
  if [ "$NEEDS_APP_RESTART" = "true" ]; then
    warn "a post-restore step did not complete — restarting the app so the site is not left down…"
    compose up -d >/dev/null 2>&1 || true
  fi
}
trap restore_restart_trap EXIT

hdr "Restore"
log "stopping app…"
compose stop app >/dev/null

# Same flags as the app repo's own restore path (scripts/db-backup.ts). No
# --exit-on-error: with --clean, per-object errors can be benign — better to
# let pg_restore finish, then VERIFY the result below than to abort midway.
# stderr is captured so a nonzero exit can be classified: pg_restore prints
# "errors ignored on restore: N" ONLY when it ran to completion — its absence
# on failure means a hard abort (connection lost, unreadable dump, …) where
# the table count of the UNTOUCHED old database would falsely read as success.
RESTORE_LOG="backups/restore-$(date +%Y%m%d-%H%M%S).log"
log "pg_restore --clean --if-exists --no-owner (this can take a while; log: $RESTORE_LOG)…"
set +e
compose exec -T postgres pg_restore -U neogen_admin -d neogen \
  --clean --if-exists --no-owner < "$DUMP" 2> "$RESTORE_LOG"
RC=$?
set -e
if [ $RC -ne 0 ]; then
  if grep -q 'errors ignored on restore' "$RESTORE_LOG"; then
    warn "pg_restore completed with ignored per-object errors (exit $RC) — verifying what landed… (details: $RESTORE_LOG)"
  else
    tail -n 15 "$RESTORE_LOG" >&2 || true
    die "pg_restore FAILED before completing (exit $RC) — see $RESTORE_LOG.
  The database may be UNCHANGED or PARTIALLY restored — do NOT trust it until
  verified. The app is still stopped; the pre-restore safety backup is in
  ./backups if needed."
  fi
fi
TABLES=$(table_count)
case "$TABLES" in
  ''|*[!0-9]*)
    # Transient verification failure ≠ incomplete restore — say so precisely.
    die "restore finished but the verification query failed (postgres busy?).
  Verify manually before starting the app:
    ./compose.sh exec postgres psql -U neogen_admin -d neogen -c '\\dt'
  then: ./compose.sh up -d" ;;
esac
if [ "$TABLES" -lt 50 ]; then
  die "restore looks INCOMPLETE ($TABLES tables in schema public).
  The database may be in a mixed state — do NOT start the app.
  Re-try with another dump, or re-provision + restore on a fresh volume."
fi
ok "restore landed: $TABLES tables in schema public"
# The DB is verified good from here on — any later failure MUST still restart
# the app (the EXIT trap handles it). Dies BEFORE this point correctly leave the
# app stopped, since the database state is unknown/untrusted.
NEEDS_APP_RESTART=true

# ── Re-sync the schema to the CURRENT app image ──────────────────────────────
# A dump older than the running release restores the OLD schema; applying the
# target version's additive migrate-*.sql brings it forward so the app image
# never boots against a schema behind its code.
# IMPORTANT: the app is currently STOPPED (compose stop app above). Nothing in
# this block may `die` — that would leave the site down. Anything that cannot
# be auto-applied is downgraded to a warning; the app is always restarted below.
hdr "Schema re-sync (additive, matches the current release)"
if RS_DIR=$(db_dir); then
  RS_MARK=$(marker_row_count)
  # No `|| true`: has_pending_destructive fails closed. A die here is past the
  # verified restore, so the EXIT trap still restarts the app.
  RS_DESTRUCTIVE=$(has_pending_destructive)
  if [ -z "$RS_MARK" ] || [ "$RS_MARK" = "0" ]; then
    # The restored dump has no migration-marker rows (a pre-marker or external
    # dump). We cannot tell which migrations its schema already contains, so
    # auto-applying every migrate-*.sql would re-run DDL already present and
    # fail. Do NOT guess — leave it to the operator.
    warn "the restored dump has no migration-marker rows — NOT auto-migrating."
    warn "Verify the restored schema version; if it predates the running image, run"
    warn "  ./migrate.sh   (additive) then restart with ./compose.sh up -d."
  elif [ -n "$RS_DESTRUCTIVE" ]; then
    # A destructive migration is pending — apply_migrations would die and leave
    # the app stopped. Skip it here; the operator applies it deliberately.
    warn "a pending migration ($RS_DESTRUCTIVE) is destructive (REQUIRES-REVIEW) — NOT auto-migrating."
    warn "Apply it deliberately after this restore: ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh"
  elif apply_migrations; then
    ok "schema re-synced to ./$RS_DIR"
  else
    ok "no pending migrations — restored schema already matches this release"
  fi
else
  warn "no SQL artifacts under ./db — skipping schema re-sync (set DB_VERSION if the dump predates the running image)"
fi

# ── Flush Redis ──────────────────────────────────────────────────────────────
# Queue/cache state (BullMQ jobs, rate limits) written AFTER the dump refers
# to rows that no longer exist in the restored database — ghost jobs would
# fire against missing data on the first boot. (Shared helper: never dies, so
# the stop→up no-die invariant of this section holds.)
flush_redis

# ── Uploads volume (optional) ────────────────────────────────────────────────
if [ -n "$UPLOADS_TAR" ]; then
  # ($UPLOADS_ABS was resolved and integrity-checked in the preflight above.)
  # The archive name is passed as a POSITIONAL PARAMETER ($1) — interpolating
  # it into the sh -c string would word-split / shell-inject on filenames
  # with spaces or metacharacters, after the wipe already ran.
  log "restoring uploads volume (${PROJECT}_uploads-data)…"
  # WARN (not die): the DB restore already succeeded; a failed uploads
  # extraction must not leave the app stopped (the volume was wiped, so warn
  # loudly — but still restart the app below).
  if $DOCKER run --rm \
      -v "${PROJECT}_uploads-data":/data \
      -v "$(dirname "$UPLOADS_ABS")":/in:ro \
      alpine sh -c 'rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null; tar xzf "/in/$1" -C /data' sh "$(basename "$UPLOADS_ABS")"; then
    ok "uploads volume restored"
  else
    warn "uploads restore FAILED — the uploads volume may be EMPTY (the database restore is intact). Re-run with a good --uploads archive."
    RESTORE_DEGRADED=true   # surface a nonzero exit at the end (cron/callers)
  fi
fi

# ── Restart + verify ─────────────────────────────────────────────────────────
hdr "Restart"
compose up -d
NEEDS_APP_RESTART=false   # app is up — the safety-net trap is no longer needed
health_gate 300 || die "the app did not pass the health gate after restore — inspect: $DOCKER compose logs app"

hdr "Restore complete"
ok "restored from $DUMP"
# The database restore + app are healthy, but a non-fatal step degraded the
# result (e.g. uploads not restored) — exit nonzero so automation/cron notices.
if [ "$RESTORE_DEGRADED" = "true" ]; then
  warn "restore completed with WARNINGS (see above) — exiting nonzero."
  exit 1
fi
