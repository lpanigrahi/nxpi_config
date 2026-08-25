#!/usr/bin/env bash
# =============================================================================
# pgbackrest.sh — point-in-time recovery: repository, WAL archive, restore.
#
# ADDED ALONGSIDE backup.sh, deliberately not replacing it. They cover different
# failures and backup.sh is a hard dependency of three other scripts:
#   • backup.sh  — one self-contained pg_dump per run, the PRE-MUTATION safety
#     snapshot that update.sh, migrate.sh and restore.sh each take before they
#     touch anything. Protects against logical damage (a bad migration) and
#     travels off-box as a single file. restore.sh is 300 lines of tested
#     failure handling built on it.
#   • pgbackrest — full/differential/incremental plus a continuous WAL archive,
#     so you can recover to a POINT IN TIME rather than to the last dump.
#     Protects against losing the disk or the VM.
# Replacing backup.sh would mean rewriting the highest-consequence script at the
# same time as moving disks and rebuilding the VM. Don't stack those.
#
#   ./pgbackrest.sh stanza-create        once, before anything else
#   ./pgbackrest.sh check                proves the repo is reachable — run this
#                                        BEFORE enabling POSTGRES_ARCHIVE_MODE
#   ./pgbackrest.sh backup [full|diff|incr]
#   ./pgbackrest.sh info                 what the repository actually holds
#   ./pgbackrest.sh drill                restore-rehearsal reminder + guidance
#
# Restores are deliberately NOT automated here. A PITR restore stops the
# database, replaces PGDATA and replays WAL to a target; doing that from a
# convenience wrapper is how a "recovery" becomes an outage. `drill` prints the
# exact command and the verification steps.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"
# shellcheck source=lib.sh
. ./lib.sh

STANZA="$(env_get .env PGBACKREST_STANZA neogen)"
IMAGE="$(env_get .env POSTGRES_IMAGE '')"
ARCHIVE_MODE="$(env_get .env POSTGRES_ARCHIVE_MODE off)"

usage() { sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit "${1:-0}"; }
[ $# -ge 1 ] || usage 1
# Help before init_docker: asking what a script does must not require a working
# Docker daemon.
case "$1" in -h|--help|help) usage 0 ;; esac

init_docker

# Every pgbackrest invocation runs INSIDE the postgres container: that is where
# the binary, PGDATA and the mounted config are. Running it on the host would
# need a second copy of all three.
pgb() {
  # shellcheck disable=SC2046  # word splitting of the argv string is intended
  compose exec -T -u postgres postgres pgbackrest $(pgbackrest_argv "$STANZA" "$@")
}

require_pitr_image() {
  case "$IMAGE" in
    *nxpi-postgres*) return 0 ;;
  esac
  die "POSTGRES_IMAGE is '${IMAGE:-<unset, using the stock pgvector image>}', which carries no pgbackrest binary.
  archive_command runs INSIDE the postgres container, so the binary must be in
  the image. Set POSTGRES_IMAGE in ./.env to the nxpi-postgres build published
  by CI, then recreate the data tier:
    ./compose.sh up -d postgres"
}

case "$1" in
  stanza-create)
    require_pitr_image
    hdr "Creating stanza ${STANZA}"
    pgb stanza-create
    ok "stanza created — now run: ./pgbackrest.sh check"
    ;;

  check)
    require_pitr_image
    hdr "Checking stanza ${STANZA}"
    # `check` verifies the repository is writable AND that archiving works
    # end-to-end. This is the gate before turning archive_mode on: with
    # archiving enabled and the repo unreachable, Postgres retains every WAL
    # segment until the disk fills and the database stops accepting writes.
    if pgb check; then
      ok "repository reachable and archiving verified"
      if [ "$ARCHIVE_MODE" != "on" ]; then
        warn "POSTGRES_ARCHIVE_MODE is '${ARCHIVE_MODE}' — backups will work but there is NO
  point-in-time recovery between them. Set POSTGRES_ARCHIVE_MODE=on in ./.env
  and RESTART postgres (archive_mode needs a restart, not a reload):
    ./compose.sh up -d --force-recreate postgres"
      fi
    else
      die "pgbackrest check FAILED — do NOT enable POSTGRES_ARCHIVE_MODE.
  With archiving on and the repository unreachable, WAL accumulates until the
  disk fills and the database stops. Fix the repository first (credentials,
  container name, network egress), then re-run this check."
    fi
    ;;

  backup)
    require_pitr_image
    TYPE="${2:-incr}"
    case "$TYPE" in full|diff|incr) ;; *) die "backup type must be full, diff or incr (got '$TYPE')" ;; esac
    # Serialised against update/migrate/restore: a backup overlapping a schema
    # change captures a half-migrated cluster as the newest "good" state.
    acquire_lock
    if ! pgbackrest_ready "$IMAGE" "$ARCHIVE_MODE"; then
      warn "archiving is not fully enabled — this ${TYPE} backup is a point-in-TIME snapshot only,
  with no WAL to replay past it. ./pgbackrest.sh check explains what is missing."
    fi
    hdr "pgbackrest ${TYPE} backup (${STANZA})"
    pgb backup --type="$TYPE"
    ok "${TYPE} backup complete — verify with: ./pgbackrest.sh info"
    ;;

  info)
    require_pitr_image
    pgb info
    ;;

  drill)
    hdr "Restore drill"
    cat <<'DRILL'
PITR is not "done" when a backup succeeds. It is done when you have restored to
a chosen target on a SCRATCH machine and passed a health gate. Until then you
have an untested assumption.

Rehearse quarterly, on a throwaway VM — never in place:

  1. provision a scratch VM + disks   (./prepare-disks.sh)
  2. copy ./secrets and ./.env across  (an adopted cluster needs its ORIGINALS)
  3. restore to a target time:
       ./compose.sh stop postgres
       ./compose.sh run --rm -u postgres postgres \
         pgbackrest --stanza=<stanza> --delta \
                    --type=time --target="2026-08-20 14:00:00+00" restore
       ./compose.sh up -d postgres
  4. verify — and be specific:
       - exact per-table row counts vs the source (never n_live_tup, it is an estimate)
       - select filename from public.deploy_schema_migrations order by 1
       - select extversion from pg_extension where extname='vector'
       - the app: /api/health/ready, a real sign-in, one upload + download
  5. write down the wall-clock time it took. That number IS your RTO; without
     it, the recovery plan has no schedule.

Record the result in this package's README.md, Backup section.
DRILL
    ;;

  -h|--help|help) usage 0 ;;
  *) die "unknown command '$1' — try: ./pgbackrest.sh --help" ;;
esac
