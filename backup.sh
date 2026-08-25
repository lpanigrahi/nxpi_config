#!/usr/bin/env bash
# =============================================================================
# backup.sh — database (and uploads) backup for the standalone Azure deploy.
#
#   ./backup.sh                 # pg_dump -Fc → ./backups/neogen-<ts>.dump
#                               # + uploads volume tar (when on local storage)
#   ./backup.sh --no-prune      # skip retention pruning (used by restore.sh)
#
# • Runs pg_dump INSIDE the postgres container — no PostgreSQL client or
#   Node.js needed on the VM host.
# • The dump is custom-format (-Fc): restore with ./restore.sh (pg_restore).
# • Local retention: BACKUP_RETENTION_DAYS in ./.env (default 7 days).
# • A single VM has no secondary durability — ship dumps OFF the VM, e.g.:
#     az storage blob upload --account-name <acct> -c backups \
#       -f backups/neogen-<ts>.dump -n neogen-<ts>.dump
#   Suggested cron (daily 03:00; dated log files are pruned by retention):
#     0 3 * * *  cd /path/to/azure-deployment && ./backup.sh >> "backups/cron-$(date +\%F).log" 2>&1
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

PRUNE=true
REQUIRE_UPLOADS=false
BACKUP_DEGRADED=false   # uploads archive failed (best-effort path) → exit 1 at the end
for arg in "$@"; do
  case "$arg" in
    # Used by restore.sh's pre-restore safety backup: retention pruning here
    # could otherwise DELETE the very dump the caller is about to restore.
    --no-prune) PRUNE=false ;;
    # Used by restore.sh when it is about to WIPE the uploads volume: the
    # uploads safety archive must then be a hard requirement, not best-effort.
    --require-uploads) REQUIRE_UPLOADS=true ;;
    -h|--help)  grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,19p'; exit 0 ;;
    *) die "unknown flag: $arg (see --help)" ;;
  esac
done

init_docker
acquire_lock
# Dumps contain the ENTIRE database (password hashes, encrypted credentials) —
# they must never be world-readable, even between two lines of this script.
umask 077
mkdir -p backups
chmod 700 backups 2>/dev/null || true
STAMP=$(date +%Y%m%d-%H%M%S)
DUMP="backups/neogen-${STAMP}.dump"

# ── Database dump ────────────────────────────────────────────────────────────
hdr "Database backup"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running — nothing to back up"

log "pg_dump -Fc → $DUMP"
compose exec -T postgres pg_dump -U neogen_admin -d neogen -Fc > "$DUMP" \
  || { rm -f "$DUMP"; die "pg_dump failed"; }
[ -s "$DUMP" ] || { rm -f "$DUMP"; die "pg_dump produced an empty file"; }
# Integrity check: a valid custom-format archive lists its TOC.
compose exec -T postgres pg_restore --list < "$DUMP" >/dev/null \
  || { rm -f "$DUMP"; die "dump failed the pg_restore --list integrity check"; }
ok "database dump: $DUMP ($(du -h "$DUMP" | cut -f1))"

# ── Uploads volume (only meaningful on local file storage) ───────────────────
# --require-uploads OVERRIDES the storage-type skip: it is restore.sh's
# pre-wipe safety contract ("I am about to destroy the uploads volume — a
# safety archive is mandatory"), which must hold even after an operator
# switched FILE_STORAGE_TYPE away from local while the volume still has data.
STORAGE_TYPE=$(env_get .env.app FILE_STORAGE_TYPE "local")
if [ "$STORAGE_TYPE" = "local" ] || $REQUIRE_UPLOADS; then
  # Guard BEFORE `docker run`: a `-v name:/data` mount silently AUTO-CREATES a
  # missing volume, which would make this step archive a fresh empty volume
  # and report it as a good backup.
  if ! $DOCKER volume inspect "${PROJECT}_uploads-data" >/dev/null 2>&1; then
    if $REQUIRE_UPLOADS; then
      die "uploads volume ${PROJECT}_uploads-data does not exist but --require-uploads was given"
    fi
    log "uploads volume ${PROJECT}_uploads-data does not exist yet — skipping volume archive"
  else
    UPLOADS_TAR="backups/uploads-${STAMP}.tar.gz"
    log "archiving uploads volume (${PROJECT}_uploads-data) → $UPLOADS_TAR"
    # The container runs as root (it must read the uid-1001 uploads), so it
    # also chmods the archive to 600 and chowns it to the invoking user —
    # otherwise the tar would land 0644 root:root (world-readable).
    if $DOCKER run --rm \
        -e TARBALL="uploads-${STAMP}.tar.gz" \
        -e HOST_UID="$(id -u)" \
        -v "${PROJECT}_uploads-data":/data:ro \
        -v "$SCRIPT_DIR/backups":/out \
        alpine sh -c 'umask 077; tar czf "/out/$TARBALL" -C /data . && chmod 600 "/out/$TARBALL" && chown "$HOST_UID" "/out/$TARBALL"'; then
      ok "uploads archive: $UPLOADS_TAR ($(du -h "$UPLOADS_TAR" | cut -f1))"
    elif $REQUIRE_UPLOADS; then
      die "uploads archive FAILED and --require-uploads was given (disk space?) — aborting"
    else
      warn "uploads archive failed — database dump is still good"
      BACKUP_DEGRADED=true   # cron must see this (a silent exit 0 here means zero uploads backups accumulate unnoticed)
    fi
  fi
else
  log "FILE_STORAGE_TYPE=$STORAGE_TYPE — uploads live off-VM, skipping volume archive (--require-uploads would force it)"
fi

# ── Retention ────────────────────────────────────────────────────────────────
if $PRUNE; then
  RETENTION=$(env_get .env BACKUP_RETENTION_DAYS 7)
  case "$RETENTION" in *[!0-9]*|"") RETENTION=7 ;; esac
  # Keep at least N dumps regardless of age. `find -mtime` alone will happily
  # delete your LAST dump after a quiet month — age is not a retention policy.
  MIN_KEEP=$(env_get .env BACKUP_MIN_KEEP 3)
  case "$MIN_KEEP" in *[!0-9]*|"") MIN_KEEP=3 ;; esac
  KEEP_LIST=$(ls -1t backups/neogen-*.dump 2>/dev/null | head -n "$MIN_KEEP" || true)
  CANDIDATES=$(find backups -maxdepth 1 \( -name 'neogen-*.dump' -o -name 'uploads-*.tar.gz' -o -name 'restore-*.log' -o -name 'cron-*.log' \) -mtime +"$RETENTION" 2>/dev/null)
  PRUNED=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rm -f "$f" && PRUNED=$((PRUNED + 1))
  done <<EOF
$(prune_keeping "$CANDIDATES" "$KEEP_LIST")
EOF
  [ "$PRUNED" != "0" ] && log "pruned $PRUNED backup file(s) older than ${RETENTION} days"
else
  log "retention pruning skipped (--no-prune)"
fi

hdr "Backup complete"
ok "latest: $DUMP"
# ── Off-VM shipping ──────────────────────────────────────────────────────────
# A single VM's disk is not a durability story: losing the machine loses the
# database AND every dump sitting beside it. Automated when BACKUP_BLOB_CONTAINER
# is set; a shipping failure is DEGRADED (nonzero exit) so cron notices, and it
# does not change any caller's exit-code contract.
BLOB_CONTAINER=$(env_get .env BACKUP_BLOB_CONTAINER "")
BLOB_ACCOUNT=$(env_get .env BACKUP_BLOB_ACCOUNT "")
if [ -n "$BLOB_CONTAINER" ] && [ -n "$BLOB_ACCOUNT" ]; then
  if ! command -v az >/dev/null 2>&1; then
    warn "BACKUP_BLOB_CONTAINER is set but the az CLI is not installed — dump NOT shipped off-VM"
    BACKUP_DEGRADED=true
  else
    log "shipping $(basename "$DUMP") to blob container ${BLOB_CONTAINER}…"
    # --auth-mode login uses the VM's managed identity: no account key on disk.
    if az storage blob upload --auth-mode login --account-name "$BLOB_ACCOUNT" \
         -c "$BLOB_CONTAINER" -f "$DUMP" -n "$(basename "$DUMP")" --overwrite false >/dev/null 2>&1; then
      ok "shipped off-VM"
    else
      warn "could not ship $(basename "$DUMP") to ${BLOB_ACCOUNT}/${BLOB_CONTAINER} — the dump exists ONLY on this VM"
      BACKUP_DEGRADED=true
    fi
  fi
else
  log "ship it OFF the VM (single-VM disk is not a durability story):"
  log "  set BACKUP_BLOB_ACCOUNT + BACKUP_BLOB_CONTAINER in ./.env to automate this, or run:"
  log "  az storage blob upload --account-name <acct> -c backups -f $DUMP -n $(basename "$DUMP")"
fi
if $BACKUP_DEGRADED; then
  warn "backup completed WITHOUT the uploads archive (database dump is good) — exiting nonzero for cron/automation."
  exit 1
fi
