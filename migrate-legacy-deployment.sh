#!/usr/bin/env bash
# =============================================================================
# migrate-legacy-deployment.sh — orchestrates a fresh install of THIS checkout,
# with the data from an OLD, already-running deployment (a different host
# directory, e.g. a legacy nxpi_config checkout) migrated onto it.
#
#   ./migrate-legacy-deployment.sh --old-dir /path/to/nxpi_config --yes
#   ./migrate-legacy-deployment.sh --old-dir /path/to/nxpi_config --yes \
#       --adopt-schema-version 1.4.0
#
# DESTRUCTIVE, ONE-WAY for the OLD deployment: after taking a backup, this
# STOPS AND REMOVES the old deployment's entire docker stack (compose down -v
# in --old-dir) — both checkouts' compose files use the same project name, so
# they cannot run side by side. From that point on, recovery means restoring
# the staged dump through this checkout's own install/restore/migrate flow,
# not undoing the teardown.
#
# What it does, using this package's OWN scripts as building blocks (no new
# pg_dump/pg_restore/secret-generation logic is added here):
#   1. back up the OLD deployment (--old-dir/backup.sh; app stays up for this)
#   2. stage that dump under ./backups
#   3. carry over --old-dir/secrets/better_auth_secret ONLY — regenerating it
#      would permanently break decryption of stored integration credentials
#      and invalidate every session. Postgres/Redis secrets are left to
#      regenerate fresh (safe: no data loss, and this is what actually
#      sidesteps a stale/mismatched-credentials problem on the old side).
#   4. stop + remove the OLD stack (docker compose down -v in --old-dir)
#   5. fresh install of THIS checkout (./install.sh)
#   6. restore the staged dump on top (./restore.sh --yes)
#   7. bring the schema forward to this checkout's target DB_VERSION
#      (ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh — auto-detects whether
#      ADOPT_SCHEMA_VERSION is needed; override with --adopt-schema-version)
#   8. roll the app image (./update.sh) and verify /api/health/ready
#
# Zero data loss, NOT zero downtime: the app is offline from step 4 until
# step 8's health gate passes. Uploads on LOCAL disk storage are NOT handled
# by this script (only the database) — if --old-dir's FILE_STORAGE_TYPE is
# local, back up/restore that volume yourself via backup.sh/restore.sh's own
# --uploads flag; this script only warns, it does not do it for you.
#
# Prerequisites (deliberately manual, not done by this script):
#   - this checkout already cloned onto the VM as a NEW directory (separate
#     from --old-dir) with ./.env / ./.env.app created and DB_VERSION /
#     APP_IMAGE / SUPER_ADMIN_EMAIL / storage credentials set as intended.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

as_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

OLD_DIR=""
CONFIRMED=false
ADOPT_VER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --old-dir)               shift; OLD_DIR="${1:-}"; [ -n "$OLD_DIR" ] || die "--old-dir needs a path argument" ;;
    --yes)                   CONFIRMED=true ;;
    --adopt-schema-version)  shift; ADOPT_VER="${1:-}"; [ -n "$ADOPT_VER" ] || die "--adopt-schema-version needs a version argument" ;;
    -h|--help)                sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    -*)                       die "unknown flag: $1 (see --help)" ;;
    *)                        die "unexpected argument: $1 (see --help)" ;;
  esac
  shift
done
[ -n "$OLD_DIR" ] || die "--old-dir <path-to-old-deployment> is required (see --help)"

# ── Validate both directories ────────────────────────────────────────────────
[ -d "$OLD_DIR" ] || die "--old-dir does not exist: $OLD_DIR"
OLD_DIR=$(cd -- "$OLD_DIR" && pwd)
for f in lib.sh docker-compose.yml backup.sh secrets; do
  [ -e "$OLD_DIR/$f" ] || die "--old-dir ($OLD_DIR) doesn't look like a deployment directory (missing $f)"
done
[ "$OLD_DIR" != "$SCRIPT_DIR" ] || die "--old-dir is this script's own directory — pass the OLD (currently-running) checkout, not this one"

[ -f .env ] || die "no ./.env here — set this checkout up first (cp .env.example .env, edit it) before running this script"

init_docker
acquire_lock

NEW_TARGET_VER=$(db_target_version)
[ -n "$NEW_TARGET_VER" ] || die "cannot determine the target DB version from ./.env — set DB_VERSION explicitly, or pin APP_IMAGE to an exact X.Y.Z tag (see .env.example)"
[ -d "db/$NEW_TARGET_VER" ] || die "db/$NEW_TARGET_VER (derived from ./.env) does not exist in this checkout"
NEW_APP_IMAGE=$(env_get .env APP_IMAGE "(unset)")
OLD_DB_VERSION=$(env_get "$OLD_DIR/.env" DB_VERSION "(unset)")
OLD_APP_IMAGE=$(env_get "$OLD_DIR/.env" APP_IMAGE "(unset)")
FST=$(env_get .env.app FILE_STORAGE_TYPE "local")

# ── Print the plan, require confirmation ─────────────────────────────────────
hdr "Migration plan"
log "old deployment  : $OLD_DIR"
log "  DB_VERSION    : $OLD_DB_VERSION"
log "  APP_IMAGE     : $OLD_APP_IMAGE"
log "new deployment  : $SCRIPT_DIR (this checkout)"
log "  target version: $NEW_TARGET_VER"
log "  APP_IMAGE     : $NEW_APP_IMAGE"
log "  FILE_STORAGE_TYPE (new): $FST"
if [ "$FST" != "azure" ]; then
  warn "FILE_STORAGE_TYPE is not 'azure' — this script does NOT back up/restore"
  warn "the uploads-data volume. If --old-dir stores files locally, handle that"
  warn "yourself with backup.sh/restore.sh's own --uploads flag."
fi
warn "This STOPS AND REMOVES the old deployment's stack (docker compose down -v"
warn "in $OLD_DIR) after taking a backup. The app will be OFFLINE from that"
warn "point until this checkout's install/restore/migrate/update flow completes."
if ! $CONFIRMED; then
  if [ -t 0 ]; then
    printf 'Type MIGRATE to proceed: '
    read -r answer
    [ "$answer" = "MIGRATE" ] || die "aborted"
  else
    die "non-interactive run requires --yes"
  fi
fi

# ── 1. Back up the old deployment ────────────────────────────────────────────
hdr "1/8 Backing up the old deployment"
"$OLD_DIR/backup.sh" \
  || die "backup of the old deployment failed — nothing has been touched yet; investigate and re-run"
DUMP=$(ls -t "$OLD_DIR"/backups/neogen-*.dump 2>/dev/null | head -n1 || true)
[ -n "$DUMP" ] && [ -s "$DUMP" ] \
  || die "backup.sh reported success but no dump was found under $OLD_DIR/backups — aborting before anything else is touched"
ok "backed up: $DUMP ($(du -h "$DUMP" | cut -f1))"

# ── 2. Stage the dump here ───────────────────────────────────────────────────
hdr "2/8 Staging the dump"
mkdir -p backups; chmod 700 backups 2>/dev/null || true
NEW_DUMP="backups/$(basename "$DUMP")"
cp "$DUMP" "$NEW_DUMP"
chmod 600 "$NEW_DUMP" 2>/dev/null || true
ok "staged: $NEW_DUMP"

# ── 3. Carry over ONLY better_auth_secret; confirm the rest are unset ───────
hdr "3/8 Carrying over the auth secret"
[ -s "$OLD_DIR/secrets/better_auth_secret" ] \
  || die "$OLD_DIR/secrets/better_auth_secret is missing or empty — refusing to proceed. Regenerating it fresh would permanently break decryption of stored integration credentials and invalidate every session; investigate before continuing."
mkdir -p secrets
chmod 700 secrets 2>/dev/null || as_root chmod 700 secrets
as_root cp "$OLD_DIR/secrets/better_auth_secret" secrets/better_auth_secret
as_root chown 1001 secrets/better_auth_secret
as_root chmod 400 secrets/better_auth_secret
ok "carried over secrets/better_auth_secret from the old deployment"

for s in postgres_password postgres_url redis_password redis_url redis_cache_url; do
  if [ -s "secrets/$s" ]; then
    die "secrets/$s already exists in this checkout — refusing to proceed. This script expects a checkout that has never been installed, so install.sh generates fresh Postgres/Redis credentials. Remove it yourself first only if you're sure why it's there."
  fi
done
ok "Postgres/Redis secrets are unset — install.sh will generate them fresh"

# ── 4. Point of no return: tear down the OLD stack ───────────────────────────
hdr "4/8 Stopping and removing the old deployment's stack"
warn "POINT OF NO RETURN: removing $OLD_DIR's stack now (docker compose down -v)."
warn "From here, recovery means restoring $NEW_DUMP through this checkout's own"
warn "install -> restore -> migrate flow — not undoing this step."
if [ -x "$OLD_DIR/compose.sh" ]; then
  ( cd "$OLD_DIR" && ./compose.sh down -v )
else
  ( cd "$OLD_DIR" && $DOCKER compose down -v )
fi
ok "old stack removed"

# ── 5. Fresh install of this checkout ────────────────────────────────────────
hdr "5/8 Fresh install (new deployment)"
./install.sh \
  || die "install.sh failed — the old stack is already gone. The staged dump is at $NEW_DUMP; fix the reported problem and re-run ./install.sh, or restore from your own off-VM backup of the old deployment."
ok "fresh install complete"

# ── 6. Restore the old data on top ───────────────────────────────────────────
hdr "6/8 Restoring the old data"
./restore.sh --yes "$NEW_DUMP" \
  || die "restore.sh failed — see its output above. The dump is still at $NEW_DUMP; investigate and re-run: ./restore.sh --yes $NEW_DUMP"
ok "data restored"

# ── 7. Bring the schema forward, deliberately ────────────────────────────────
hdr "7/8 Bringing the schema forward to $NEW_TARGET_VER"
if [ -z "$ADOPT_VER" ]; then
  MARKER_N=$(marker_row_count)
  if [ "$MARKER_N" = "0" ] && [ -n "$(migration_files_through "$NEW_TARGET_VER")" ]; then
    ADOPT_VER=$(env_get "$OLD_DIR/.env" DB_VERSION "")
    [ -n "$ADOPT_VER" ] \
      || die "the restored schema's migration marker is empty and $OLD_DIR/.env has no DB_VERSION set — re-run with --adopt-schema-version <the old schema's actual release>"
    log "restored marker table is empty — auto-detected ADOPT_SCHEMA_VERSION=$ADOPT_VER from $OLD_DIR/.env"
  fi
else
  log "using operator-supplied --adopt-schema-version=$ADOPT_VER"
fi
export ALLOW_DESTRUCTIVE_MIGRATION=1
[ -z "$ADOPT_VER" ] || export ADOPT_SCHEMA_VERSION="$ADOPT_VER"
./migrate.sh \
  || die "migrate.sh failed — see its output above. The database currently holds the restored data on the new install; investigate and re-run: ALLOW_DESTRUCTIVE_MIGRATION=1 $( [ -n "$ADOPT_VER" ] && printf 'ADOPT_SCHEMA_VERSION=%s ' "$ADOPT_VER" )./migrate.sh"
unset ALLOW_DESTRUCTIVE_MIGRATION
[ -z "$ADOPT_VER" ] || unset ADOPT_SCHEMA_VERSION
ok "schema migrated to $NEW_TARGET_VER"

# ── 8. Roll the app image ────────────────────────────────────────────────────
hdr "8/8 Rolling the app image"
./update.sh \
  || warn "update.sh reported a failure — it auto-rolls back on a failed health gate, so the app should still be serving on its previous image. Investigate before re-running."

# ── Verify ────────────────────────────────────────────────────────────────────
hdr "Verification"
READY=$(curl -s "http://localhost/api/health/ready" 2>/dev/null || true)
printf '%s\n' "$READY"
case "$READY" in
  *'"status":"ok"'*) ok "health check: ok" ;;
  *)                 warn "health check did not report status:ok — inspect: ./compose.sh logs app" ;;
esac

hdr "Migration complete"
log "old deployment ($OLD_DIR) has been torn down — its volumes are gone."
log "recovery, if ever needed, starts from: $NEW_DUMP"
log "applied migrations (deploy_schema_migrations):"
compose exec -T postgres psql -U neogen_admin -d neogen -tAc \
  "select filename from deploy_schema_migrations order by filename;" 2>/dev/null || true
