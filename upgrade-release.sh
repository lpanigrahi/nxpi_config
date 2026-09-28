#!/usr/bin/env bash
# =============================================================================
# upgrade-release.sh — ONE rehearsed, resumable, rollback-able maintenance
# window: this deployment → a newer db/<version> AND a newer app image, with
# zero data loss verified rather than assumed.
#
#   ./upgrade-release.sh --image ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:… --dry-run
#   ./upgrade-release.sh --image <ref> [--target 1.41.0] [--yes] [--ack WORD…]
#   ./upgrade-release.sh --resume <run-id>          # continue a run that stopped
#   ./upgrade-release.sh --rollback [<run-id>]      # back to the pre-upgrade state
#
# Flags: --target X.Y.Z (default: newest db/ shipped here) · --image REF
# (required forward; tag@sha256 recommended — a bare tag is pinned to the digest
# it resolves to) · --dry-run (preflight only; nothing changes) · --yes (skip
# the one typed UPGRADE; acks stay explicit) · --ack WORD (pre-supply a typed
# acknowledgement: DROP-AGENT-MEMORY, KNOWN-LIMIT) · --accept-uncataloged-uploads
# · --no-rehearse · --skip-parity · --smoke-login (real sign-in with
# SMOKE_LOGIN_EMAIL from ./.env and secrets/smoke_login_password) · --ship-config
# (also upload the config tar to Blob) · --clear-stale-pin · --allow-override-file
# · --accept-data-loss-since (rollback after go-live) · --adopt-schema-version V.
#
# Sequence (each step is recorded in backups/release-<id>/state.env; --resume
# skips what is done):
#   1 preflight   discover.sh, image pull + digest, disk need, env plan,
#                 upgrade-db.sh --dry-run (every pre-check and review header),
#                 privileged-pool decision, UPLOADS GATE — read-only, then ONE
#                 typed UPGRADE
#   2 stop app    Caddy keeps answering (502); the dump below is then exact and
#                 the deltas' lock_timeout cannot trip over a live query
#   3 bundle      backup.sh (dump + uploads tar, no pruning) + secrets/.env/
#                 .env.app/certs/compose tar + caddy volumes + row counts +
#                 uploads inventory, all sha256-manifested; optional Blob upload
#   4 parity      schema-parity.sh <current>: the VM must really be at the
#                 release it claims (only-scratch ⇒ stop, app restarted)
#   5 rehearsal   schema-parity.sh --rehearse <dump> --target: the pending set
#                 must take THIS data to the target catalog on a scratch copy
#   6 privileged  provision-privileged-role.sh when ./.env opts in
#   7 migrate     upgrade-db.sh <target> --yes --no-backup (bumps DB_VERSION,
#                 arms ALLOW_DESTRUCTIVE_MIGRATION after its own review)
#   8 switch      APP_IMAGE := the digest-pinned new image; TRUSTED_PROXY_MODE /
#                 METRICS_TOKEN converged — the LAST moment .env changes, so an
#                 abort before here leaves a bootable configuration
#   9 roll        update.sh --no-backup (pull no-op, no pending, up -d app,
#                 300 s health gate). After a stop update.sh has no automatic
#                 rollback reference — expected; this script owns rollback
#  10 verify      row counts vs the allow-list, custom RBAC rows, uploads bytes,
#                 users, credentialed deep probe, schema parity vs the target,
#                 privileged pool wired, login smoke test — fail ⇒ exit 4, app up
#
# Exit codes: 0 upgraded and verified · 1 preflight/usage (nothing changed) ·
# 2 refused at a gate before any database mutation (app restarted) · 3 the
# database was migrated but the roll failed or aborted — app DOWN, run
# --rollback · 4 serving on the new image but post-verification differs ·
# 5 rollback completed healthy · 6 rollback failed (manual recovery printed).
#
# --rollback: verifies the bundle's manifest, refuses after go-live without
# --accept-data-loss-since, stops the app, restores ./.env and ./.env.app from
# the bundle FIRST (DB_VERSION and APP_IMAGE back), installs the old image's
# digest pin (.rollback-image.yml — every compose call honours it), then
# restore.sh --yes <dump> --uploads <tar> --skip-resync (drops the schema,
# restores exactly the dump, grants, flushes both redis tiers, re-extracts the
# uploads, starts the pinned old image, health-gates), and re-checks row counts,
# users and uploads against the bundle.
# =============================================================================
set -uo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=lib-checks.sh
. ./lib-checks.sh

TARGET=""; IMAGE=""; DRY_RUN=false; ASSUME_YES=false; RESUME=""; ROLLBACK=false; ROLLBACK_ID=""
REHEARSE=true; SKIP_PARITY=false; SMOKE_LOGIN=false; SHIP_CONFIG=false; ACCEPT_UNCAT=false
CLEAR_PIN=false; ALLOW_OVERRIDE=false; ACCEPT_LOSS=false; ADOPT=""; ACK_ARGS=""; ACKS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target)    shift; TARGET="${1:-}" ;;         --target=*)  TARGET="${1#*=}" ;;
    --image)     shift; IMAGE="${1:-}" ;;          --image=*)   IMAGE="${1#*=}" ;;
    --dry-run)   DRY_RUN=true ;;
    --yes|-y)    ASSUME_YES=true ;;
    --resume)    shift; RESUME="${1:-}" ;;         --resume=*)  RESUME="${1#*=}" ;;
    --rollback)  ROLLBACK=true; if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then shift; ROLLBACK_ID="$1"; fi ;;
    --ack)       shift; ACK_ARGS="$ACK_ARGS --ack ${1:-}"; ACKS="$ACKS ${1:-}" ;;
    --ack=*)     ACK_ARGS="$ACK_ARGS --ack ${1#*=}"; ACKS="$ACKS ${1#*=}" ;;
    --accept-uncataloged-uploads) ACCEPT_UNCAT=true ;;
    --no-rehearse) REHEARSE=false ;;
    --skip-parity) SKIP_PARITY=true ;;
    --smoke-login) SMOKE_LOGIN=true ;;
    --ship-config) SHIP_CONFIG=true ;;
    --clear-stale-pin) CLEAR_PIN=true ;;
    --allow-override-file) ALLOW_OVERRIDE=true ;;
    --accept-data-loss-since) ACCEPT_LOSS=true ;;
    --adopt-schema-version) shift; ADOPT="${1:-}" ;;
    -h|--help)   sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done

init_docker
acquire_lock
umask 077
mkdir -p backups; chmod 700 backups 2>/dev/null || true

# ── run state ────────────────────────────────────────────────────────────────
if [ -n "$RESUME" ]; then RUN_ID="$RESUME"
elif $ROLLBACK; then RUN_ID="${ROLLBACK_ID:-$(readlink backups/release-current 2>/dev/null | sed 's|.*release-||')}"; [ -n "$RUN_ID" ] || die "no run to roll back — pass --rollback <run-id>"
else RUN_ID=$(date +%Y%m%d-%H%M%S); fi
RUN="backups/release-$RUN_ID"
STATE="$RUN/state.env"
if [ -n "$RESUME" ] || $ROLLBACK; then [ -f "$STATE" ] || die "no run state at $STATE"; fi
mkdir -p "$RUN"; chmod 700 "$RUN"
[ -f "$STATE" ] || : > "$STATE"
ln -sfn "release-$RUN_ID" backups/release-current
sv()   { local k="$1" v="$2"; grep -v "^${k}=" "$STATE" > "$STATE.tmp" 2>/dev/null || true; printf '%s=%s\n' "$k" "$v" >> "$STATE.tmp"; mv "$STATE.tmp" "$STATE"; }
gv()   { sed -n "s/^$1=//p" "$STATE" | tail -n1; }
done_() { [ "$(gv "STEP_$1")" = "done" ]; }
begin() { done_ "$1" && { log "step $1: already done (resume) — skipping"; return 1; }; sv "STEP_$1" "start $(date +%FT%T)"; hdr "$2"; return 0; }
finish() { sv "STEP_$1" "done"; }
LOG="$RUN/run.log"
exec > >(tee -a "$LOG") 2>&1
log "run $RUN_ID — state: $STATE — log: $LOG"

sha256() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
site_url() { local site; site=$(env_get .env SITE_ADDRESS ""); if [ -n "$site" ]; then printf 'https://%s:%s' "$site" "$(env_get .env CADDY_HTTPS_PORT 443)"; else printf 'http://127.0.0.1:%s' "$(env_get .env CADDY_HTTP_PORT 80)"; fi; }
curl_site() { # curl_site METHOD PATH [curl-args…] — through the ingress, resolving a domain to loopback
  local m="$1" p="$2"; shift 2; local site url; site=$(env_get .env SITE_ADDRESS ""); url="$(site_url)$p"
  if [ -n "$site" ]; then curl -sS --max-time 15 -X "$m" --resolve "${site}:$(env_get .env CADDY_HTTPS_PORT 443):127.0.0.1" "$@" "$url"
  else curl -sS --max-time 15 -X "$m" "$@" "$url"; fi
}
volume_tar() { # volume_tar VOLUME OUTFILE
  $DOCKER volume inspect "$1" >/dev/null 2>&1 || return 0
  $DOCKER run --rm -e HOST_UID="$(id -u)" -v "$1":/data:ro -v "$SCRIPT_DIR/$RUN":/out alpine \
    sh -c "umask 077; tar czf /out/$(basename "$2") -C /data . && chmod 600 /out/$(basename "$2") && chown \$HOST_UID /out/$(basename "$2")"
}

# ═════════════════════════════════════════════════════════════════════════════
# ROLLBACK
# ═════════════════════════════════════════════════════════════════════════════
if $ROLLBACK; then
  hdr "ROLLBACK of run $RUN_ID"
  DUMP=$(gv DUMP); UPL=$(gv UPLOADS_TAR); OLD_DIGEST=$(gv OLD_DIGEST); OLD_APP_IMAGE=$(gv OLD_APP_IMAGE); OPENED=$(gv OPENED_AT)
  [ -s "$DUMP" ] || die "the run's dump is missing ($DUMP) — cannot roll back from this bundle"
  [ -s "$RUN/env.before" ] || die "$RUN/env.before is missing"
  if [ -s "$RUN/manifest.sha256" ]; then
    (cd "$SCRIPT_DIR" && sha256 -c "$RUN/manifest.sha256" --quiet 2>/dev/null) || die "bundle manifest check FAILED — a file changed since the backup; inspect $RUN before restoring"
    ok "bundle manifest verified"
  fi
  if [ -n "$OPENED" ] && ! $ACCEPT_LOSS; then
    die "the upgraded stack was OPENED to users at $OPENED — rolling back discards everything written since.
  Re-run with --accept-data-loss-since to confirm that is intended."
  fi
  if [ -n "$OLD_DIGEST" ] && ! $DOCKER image inspect "$OLD_DIGEST" >/dev/null 2>&1; then
    log "pulling the previous image $OLD_DIGEST…"; $DOCKER pull "$OLD_DIGEST" >/dev/null || die "cannot pull $OLD_DIGEST — the previous image is gone from the registry"
  fi
  log "this restores: $DUMP${UPL:+ + $UPL}, ./.env and ./.env.app from the bundle, and pins the app to ${OLD_DIGEST:-<no digest recorded>}"
  confirm "Roll back to the pre-upgrade state (the current database and uploads are REPLACED)." "ROLLBACK"
  sv STEP_rollback "start $(date +%FT%T)"
  compose stop app >/dev/null 2>&1 || true
  # 1. configuration FIRST — restore.sh reads DB_VERSION/APP_IMAGE from ./.env
  cp .env "$RUN/env.upgraded" 2>/dev/null || true; cp .env.app "$RUN/env.app.upgraded" 2>/dev/null || true
  cp "$RUN/env.before" .env; chmod 600 .env
  [ -s "$RUN/env.app.before" ] && { cp "$RUN/env.app.before" .env.app; chmod 600 .env.app; }
  ok "./.env and ./.env.app restored from the bundle (upgraded copies kept as $RUN/env*.upgraded)"
  # 2. the digest pin — the moving tag in the restored .env must never resolve
  if [ -n "$OLD_DIGEST" ]; then printf 'services:\n  app:\n    image: "%s"\n' "$OLD_DIGEST" > .rollback-image.yml; ok "app pinned to $OLD_DIGEST via .rollback-image.yml"; fi
  # 3. the data
  RS_ARGS="--yes $DUMP --skip-resync"; [ -n "$UPL" ] && [ -s "$UPL" ] && RS_ARGS="$RS_ARGS --uploads $UPL"
  # shellcheck disable=SC2086
  if ./restore.sh $RS_ARGS; then RS=0; else RS=$?; fi
  # 4. verify against the bundle
  hdr "Rollback verification"
  V=0
  rowcount_snapshot > "$RUN/rowcounts.rollback" 2>/dev/null || true
  if [ -s "$RUN/rowcounts.before" ] && [ -s "$RUN/rowcounts.rollback" ]; then
    if cmp -s <(sort "$RUN/rowcounts.before") <(sort "$RUN/rowcounts.rollback"); then ok "row counts identical to the pre-upgrade snapshot"
    else warn "row counts differ from the pre-upgrade snapshot:"; diff <(sort "$RUN/rowcounts.before") <(sort "$RUN/rowcounts.rollback") | head -n 20 | sed 's/^/    /'; V=1; fi
  fi
  if [ -s "$RUN/uploads-stats.before" ]; then
    NOW=$(uploads_volume_stats 2>/dev/null || true)
    [ "$NOW" = "$(cat "$RUN/uploads-stats.before")" ] && ok "uploads volume: $NOW (files, KiB) as before" || { warn "uploads volume differs: now '$NOW', before '$(cat "$RUN/uploads-stats.before")'"; V=1; }
  fi
  ingress_probe && ok "ingress /api/health/ready answers" || { warn "ingress not ready"; V=1; }
  if [ "$RS" = "0" ] && [ "$V" = "0" ]; then sv STEP_rollback done; ok "ROLLED BACK to the pre-upgrade state (the pin stays until the next successful ./update.sh clears it)"; exit 5
  else warn "rollback finished with problems (restore.sh exit $RS, verification $V) — inspect: ./compose.sh ps; ./compose.sh logs app; restore log under backups/"; exit 6; fi
fi

# ═════════════════════════════════════════════════════════════════════════════
# FORWARD
# ═════════════════════════════════════════════════════════════════════════════
NEWEST=$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tail -n1)
[ -n "$TARGET" ] || TARGET=$(gv TARGET); [ -n "$TARGET" ] || TARGET="$NEWEST"
is_exact_semver "$TARGET" || die "--target must be bare X.Y.Z"
[ -d "db/$TARGET" ] || die "db/$TARGET is not shipped here"
[ -n "$IMAGE" ] || IMAGE=$(gv NEW_IMAGE); [ -n "$IMAGE" ] || die "--image <ref> is required (the new app image, tag@sha256 recommended)"
sv TARGET "$TARGET"

# EXIT trap: a stop before any database mutation is undone by restarting the
# OLD app; after the migration started nothing is auto-started — the message
# names the rollback.
FINISHED=false
on_exit() {
  $FINISHED && return 0
  if done_ stop_app && ! done_ migrate_started; then
    warn "exiting before any database mutation — restarting the app on its previous image"; compose up -d --no-deps app >/dev/null 2>&1 || true
  elif done_ migrate_started && ! done_ roll; then
    warn "the database was migrated but the app was NOT rolled — it is DOWN. Either fix and:  ./upgrade-release.sh --resume $RUN_ID   or:  ./upgrade-release.sh --rollback $RUN_ID"
  fi
}
trap on_exit EXIT

# ── 1. Preflight (read-only) ─────────────────────────────────────────────────
if begin preflight "1. Preflight → db $TARGET, image $IMAGE"; then
  [ -f .rollback-image.yml ] && { $CLEAR_PIN && { rm -f .rollback-image.yml; warn "cleared the stale .rollback-image.yml (--clear-stale-pin)"; } || die "a rollback pin (.rollback-image.yml) from an earlier failed update is installed — inspect it; re-run with --clear-stale-pin to remove it"; }
  [ -f docker-compose.override.yml ] && ! $ALLOW_OVERRIDE && die "docker-compose.override.yml is present and would apply to every step — review it; re-run with --allow-override-file"
  $DRY_RUN || sudo -v 2>/dev/null || warn "sudo is not available non-interactively — the secrets tar (uid-1001 files) may fail; run 'sudo -v' first"

  log "read-only discovery…"
  ./discover.sh --out "$RUN/discover.before.txt" --target "$TARGET" >/dev/null 2>&1; DRC=$?
  grep -A200 '── Verdict' "$RUN/discover.before.txt" | sed 's/^/  /'
  [ "$DRC" = "0" ] || die "discover.sh reports BLOCKERS (above; full report: $RUN/discover.before.txt) — nothing was changed"

  bash tests/lib-harness.sh >/dev/null 2>&1 && ok "lib.sh self-test passes" || die "tests/lib-harness.sh fails on this host — do not upgrade with a broken helper library"
  PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true); [ -n "$PG_CID" ] || die "postgres is not running"
  wait_healthy postgres 60 >/dev/null || die "postgres is not healthy"
  USERS=$(user_count); [ "${USERS:-0}" -gt 0 ] 2>/dev/null || die "no users in the database — this is not a populated deployment"
  marker_table_exists || [ -n "$ADOPT" ] || die "no migration marker table — pass --adopt-schema-version <the release the schema really matches> (see discover's sentinel report)"
  [ -n "$(env_get .env POSTGRES_PRIVILEGED_URL_FILE '')" ] && [ ! -s secrets/postgres_privileged_url ] && die "POSTGRES_PRIVILEGED_URL_FILE is set but secrets/postgres_privileged_url is missing — run ./install.sh first"
  for s in postgres_privileged_url redis_cache_url; do [ -s "secrets/$s" ] || die "secrets/$s is missing — run ./install.sh BEFORE the window (it converges secrets and ./.env.app without touching the database)"; done

  OLD_APP_IMAGE=$(env_get .env APP_IMAGE ""); OLD_DB_VERSION=$(env_get .env DB_VERSION "")
  OLD_DIGEST=$(app_image_digest 2>/dev/null || true)
  [ -n "$OLD_DIGEST" ] || OLD_DIGEST=$(image_digest_of "$OLD_APP_IMAGE" 2>/dev/null || true)
  sv OLD_APP_IMAGE "$OLD_APP_IMAGE"; sv OLD_DB_VERSION "$OLD_DB_VERSION"; sv OLD_DIGEST "$OLD_DIGEST"
  kvp() { printf '  %-26s %s\n' "$1" "$2"; }
  kvp "current DB_VERSION" "${OLD_DB_VERSION:-<unset>}"; kvp "current APP_IMAGE" "$OLD_APP_IMAGE"; kvp "running digest" "${OLD_DIGEST:-<none — no rollback image recorded!>}"
  [ -n "$OLD_DIGEST" ] || warn "no previous image digest could be recorded: a rollback would have to pull $OLD_APP_IMAGE by tag"
  [ -n "$OLD_DB_VERSION" ] || die "DB_VERSION is unset in ./.env — set it to the release this database is at"
  ver_le "$OLD_DB_VERSION" "$TARGET" || die "DB_VERSION=$OLD_DB_VERSION is newer than the target $TARGET"

  log "pulling $IMAGE…"
  $DOCKER pull "$IMAGE" >/dev/null 2>&1 || die "cannot pull $IMAGE — is the package public / are you logged in to ghcr.io?"
  NEW_DIGEST=$(image_digest_of "$IMAGE") || die "the local image for $IMAGE does not carry the digest the reference names — the tag moved; re-pull and pin explicitly"
  [ -n "$NEW_DIGEST" ] || die "could not read a repository digest for $IMAGE"
  case "$IMAGE" in *@sha256:*) NEW_PINNED="$IMAGE" ;; *) NEW_PINNED="${IMAGE}@${NEW_DIGEST#*@}" ;; esac
  sv NEW_IMAGE "$IMAGE"; sv NEW_PINNED "$NEW_PINNED"; sv NEW_DIGEST "$NEW_DIGEST"
  kvp "new image (pinned)" "$NEW_PINNED"
  [ "$NEW_DIGEST" != "$OLD_DIGEST" ] || warn "the new image digest equals the running one — this window changes the schema only"

  DB_BYTES=$(psql_scalar "select pg_database_size(current_database())"); UPS=$(uploads_volume_stats 2>/dev/null || printf '0\t0'); UP_KB=${UPS#*$'\t'}
  NEED=$(disk_need_kb "${DB_BYTES:-0}" "$(( ${UP_KB:-0} * 1024 ))"); AVAIL=$(df -Pk . | awk 'NR==2{print $4}')
  kvp "disk need / free (KiB)" "$NEED / $AVAIL"; [ "$AVAIL" -ge "$NEED" ] || die "not enough free space for the window (need $NEED KiB, have $AVAIL) — prune backups/ or grow the disk"

  kvp "TRUSTED_PROXY_MODE" "$(env_get .env.app TRUSTED_PROXY_MODE '<absent → will append xff>')"
  kvp "METRICS_TOKEN" "$([ -n "$(env_get .env.app METRICS_TOKEN '')" ] && echo set || echo '<absent → will generate>')"
  kvp "privileged pool" "$([ -n "$(env_get .env POSTGRES_PRIVILEGED_URL_FILE '')" ] && echo 'opted in (role provisioned in step 6)' || echo 'NOT opted in (KNOWN-LIMIT ack required)')"

  log "guided upgrade dry run (pre-checks, allow-list, review headers)…"
  UD_ARGS="--dry-run --run-dir $RUN --skip-parity $ACK_ARGS"; [ -n "$ADOPT" ] && UD_ARGS="$UD_ARGS --adopt-schema-version $ADOPT"; $ASSUME_YES && UD_ARGS="$UD_ARGS --yes"
  # shellcheck disable=SC2086
  ./upgrade-db.sh "$TARGET" $UD_ARGS || die "upgrade-db.sh --dry-run failed (above) — nothing was changed"

  # The uploads gate: the current image answers 404 for any uploads/<uuid>-<name>
  # object with no thread_attachment row (uploads/shared/… excepted). Bytes stay
  # on disk. This tooling never fabricates catalog rows; the operator decides.
  if $DOCKER volume inspect "${PROJECT}_uploads-data" >/dev/null 2>&1; then
    DL=$(mktemp); DBL=$(mktemp); uploads_list_volume > "$DL" 2>/dev/null || true; uploads_list_catalog > "$DBL" 2>/dev/null || true
    uploads_classify "$DL" "$DBL" > "$RUN/uploads-inventory.before"; rm -f "$DL" "$DBL"
    NUNCAT=$(grep -c $'^uncataloged\t\(flat\|threads\|other\)' "$RUN/uploads-inventory.before" || true)
    kvp "uploads uncataloged" "${NUNCAT:-0} (list: $RUN/uploads-inventory.before)"
    if [ "${NUNCAT:-0}" != "0" ] && ! $ACCEPT_UNCAT; then
      warn "$NUNCAT upload file(s) outside uploads/shared/ have no catalog row: the new image will answer 404 for them."
      warn "Decide first (catalog them in the product, move them under uploads/shared/, or accept), then re-run with --accept-uncataloged-uploads."
      FINISHED=true; exit 2
    fi
  fi

  if $DRY_RUN; then hdr "Dry run complete"; log "nothing was changed. Re-run without --dry-run (same flags) to open the window."; FINISHED=true; exit 0; fi
  confirm "OPEN THE MAINTENANCE WINDOW: stop the app, back up, migrate the database to $TARGET and roll to $NEW_PINNED." "UPGRADE"
  finish preflight
fi
OLD_DB_VERSION=$(gv OLD_DB_VERSION); OLD_DIGEST=$(gv OLD_DIGEST); NEW_PINNED=$(gv NEW_PINNED)

# ── 2. Stop the app ──────────────────────────────────────────────────────────
if begin stop_app "2. Stop the app (Caddy keeps answering 502)"; then
  compose stop app >/dev/null 2>&1 || warn "compose stop app reported an error (already stopped?)"
  ok "app stopped at $(date +%FT%T)"; finish stop_app
fi

# ── 3. Safety bundle ─────────────────────────────────────────────────────────
if begin bundle "3. Safety bundle → $RUN"; then
  BK_ARGS="--no-prune --stamp $RUN_ID"; $DOCKER volume inspect "${PROJECT}_uploads-data" >/dev/null 2>&1 && BK_ARGS="$BK_ARGS --require-uploads"
  # shellcheck disable=SC2086
  BK_OUT=$(./backup.sh $BK_ARGS 2>&1 | tee /dev/stderr) || die "backup.sh failed — refusing to continue without a verified dump"
  DUMP=$(printf '%s\n' "$BK_OUT" | sed -n 's/^BACKUP_DUMP=//p' | tail -n1); UPL=$(printf '%s\n' "$BK_OUT" | sed -n 's/^BACKUP_UPLOADS=//p' | tail -n1)
  [ -s "$DUMP" ] || die "backup.sh did not report a dump"
  sv DUMP "$DUMP"; sv UPLOADS_TAR "$UPL"
  cp .env "$RUN/env.before"; cp .env.app "$RUN/env.app.before"; cp docker-compose.yml "$RUN/compose.before.yml"; chmod 600 "$RUN"/env*.before
  [ -n "$OLD_DIGEST" ] && printf 'services:\n  app:\n    image: "%s"\n' "$OLD_DIGEST" > "$RUN/rollback-image.yml"
  CONF="$RUN/config-$RUN_ID.tar.gz"
  if sudo -n true 2>/dev/null; then sudo tar czf "$CONF" secrets .env .env.app Caddyfile docker-compose.yml certs 2>/dev/null && sudo chown "$(id -u)" "$CONF" && chmod 600 "$CONF" && ok "config tar: $CONF (secrets, env, Caddyfile, compose, certs)" || warn "config tar failed — copy secrets/ off the VM by hand before continuing"
  else tar czf "$CONF" .env .env.app Caddyfile docker-compose.yml certs 2>/dev/null && chmod 600 "$CONF" && warn "config tar WITHOUT secrets/ (no sudo) — copy secrets/ off the VM by hand" || true; fi
  volume_tar "${PROJECT}_caddy-data" "$RUN/caddy-data-$RUN_ID.tar.gz" && volume_tar "${PROJECT}_caddy-config" "$RUN/caddy-config-$RUN_ID.tar.gz" && ok "caddy volumes archived"
  rowcount_snapshot > "$RUN/rowcounts.before" || die "could not snapshot row counts"
  uploads_volume_stats > "$RUN/uploads-stats.before" 2>/dev/null || printf '0\t0\n' > "$RUN/uploads-stats.before"
  user_count > "$RUN/users.before"; psql_scalar "select count(*) from organization" > "$RUN/orgs.before"
  ( cd "$SCRIPT_DIR" && sha256 "$DUMP" ${UPL:+"$UPL"} "$CONF" "$RUN"/caddy-*.tar.gz "$RUN/rowcounts.before" 2>/dev/null ) > "$RUN/manifest.sha256"
  ok "manifest: $RUN/manifest.sha256 ($(grep -c . "$RUN/manifest.sha256") files)"
  if $SHIP_CONFIG && [ -n "$(env_get .env BACKUP_BLOB_CONTAINER '')" ] && command -v az >/dev/null 2>&1; then
    az storage blob upload --auth-mode login --account-name "$(env_get .env BACKUP_BLOB_ACCOUNT '')" -c "$(env_get .env BACKUP_BLOB_CONTAINER '')" -f "$CONF" -n "$(basename "$CONF")" --overwrite false >/dev/null 2>&1 && ok "config tar shipped to Blob" || warn "config tar NOT shipped to Blob"
  fi
  finish bundle
fi
DUMP=$(gv DUMP); UPL=$(gv UPLOADS_TAR)

# ── 4. Parity of the current release ─────────────────────────────────────────
if begin parity_before "4. Schema parity: is this database really at $OLD_DB_VERSION?"; then
  if $SKIP_PARITY; then log "skipped (--skip-parity)"
  else
    ./schema-parity.sh "$OLD_DB_VERSION" --out "$RUN/parity-before"; PRC=$?
    if [ "$PRC" = "3" ] && [ -s "$RUN/parity-before/only-scratch.txt" ]; then
      warn "the live database is MISSING objects db/$OLD_DB_VERSION/schema.sql has — it is not at the release ./.env claims. Establish the real release first (see $RUN/parity-before)."; FINISHED=false; exit 2
    elif [ "$PRC" = "3" ]; then log "only-live differences (objects the upgrade will reconcile) — continuing"
    elif [ "$PRC" != "0" ]; then die "schema-parity.sh errored"; fi
  fi
  finish parity_before
fi

# ── 5. Rehearsal on the fresh dump ───────────────────────────────────────────
if begin rehearsal "5. Rehearsal: apply the pending set to a scratch copy of $DUMP"; then
  if $REHEARSE; then
    # shellcheck disable=SC2086
    ./schema-parity.sh --rehearse "$DUMP" --target "$TARGET" --out "$RUN/rehearsal" $ACK_ARGS || { warn "the rehearsal did not come out clean — the live database is untouched (details: $RUN/rehearsal)"; exit 2; }
  else log "skipped (--no-rehearse)"; fi
  finish rehearsal
fi

# ── 6. Privileged pool ───────────────────────────────────────────────────────
if begin privileged "6. Privileged pool"; then
  if [ -n "$(env_get .env POSTGRES_PRIVILEGED_URL_FILE '')" ]; then ./provision-privileged-role.sh || die "privileged-role provisioning failed"
  else log "not opted in (POSTGRES_PRIVILEGED_URL_FILE unset) — the KNOWN-LIMIT ack was given to upgrade-db.sh"; fi
  finish privileged
fi

# ── 7. Migrate ───────────────────────────────────────────────────────────────
if begin migrate "7. Migrate the database to $TARGET"; then
  sv STEP_migrate_started done
  UD_ARGS="--yes --no-backup --run-dir $RUN --skip-parity $ACK_ARGS"; [ -n "$ADOPT" ] && UD_ARGS="$UD_ARGS --adopt-schema-version $ADOPT"
  # shellcheck disable=SC2086
  if ! ./upgrade-db.sh "$TARGET" $UD_ARGS; then
    warn "upgrade-db.sh FAILED — every delta is one transaction and the marker is exact: the database is at an intermediate release, the app is DOWN."
    warn "Fix the cause and:  ./upgrade-release.sh --resume $RUN_ID     or roll back:  ./upgrade-release.sh --rollback $RUN_ID"
    exit 3
  fi
  finish migrate
fi

# ── 8. Switch the configuration ──────────────────────────────────────────────
if begin switch "8. Point ./.env at $NEW_PINNED and converge ./.env.app"; then
  env_set .env APP_IMAGE "$NEW_PINNED"; ok "APP_IMAGE=$NEW_PINNED"
  [ -n "$(env_get .env.app TRUSTED_PROXY_MODE '')" ] || { env_set .env.app TRUSTED_PROXY_MODE xff; ok "TRUSTED_PROXY_MODE=xff appended to ./.env.app"; }
  [ -n "$(env_get .env.app METRICS_TOKEN '')" ] || { env_set .env.app METRICS_TOKEN "$(openssl rand -hex 32 | tr -d '\n')"; ok "METRICS_TOKEN generated in ./.env.app"; }
  finish switch
fi

# ── 9. Roll ──────────────────────────────────────────────────────────────────
if begin roll "9. Roll the app onto $NEW_PINNED"; then
  if ./update.sh --no-backup; then ok "app rolled and health-gated"
  else
    URC=$?; warn "update.sh exited $URC — the app did not become healthy on the new image:"; compose logs --tail 60 app 2>/dev/null | sed 's/^/    /' || true
    warn "Roll back:  ./upgrade-release.sh --rollback $RUN_ID   (the schema is roll-forward-only past 1.26.0, so the old image cannot serve it)"
    exit 3
  fi
  finish roll
fi

# ── 10. Post-verification ────────────────────────────────────────────────────
if begin verify "10. Post-verification"; then
  V=0; vfail() { warn "$*"; V=$((V+1)); }
  rowcount_snapshot > "$RUN/rowcounts.after" || vfail "could not snapshot row counts"
  EXP="$RUN/pre-$TARGET-expected-changes.tsv"; [ -f "$EXP" ] || EXP=""
  CMP=$(rowcount_compare "$RUN/rowcounts.before" "$RUN/rowcounts.after" ${EXP:+"$EXP"}); CRC=$?   # no errexit in this script
  printf '%s\n' "$CMP" | grep -E '^(ok|!!|new|grew|unchanged)' | sed 's/^/    /' || true
  [ "$CRC" = "0" ] && ok "row counts changed only as the pending deltas allow" || vfail "UNEXPECTED row-count change (the '!!' lines)"
  U_NOW=$(user_count); [ "$U_NOW" = "$(cat "$RUN/users.before")" ] && ok "users: $U_NOW (unchanged)" || vfail "users changed: $(cat "$RUN/users.before") → $U_NOW"
  O_NOW=$(psql_scalar "select count(*) from organization"); [ "$O_NOW" = "$(cat "$RUN/orgs.before")" ] && ok "organizations: $O_NOW (unchanged)" || vfail "organizations changed"
  UPS_NOW=$(uploads_volume_stats 2>/dev/null || printf '0\t0'); [ "$UPS_NOW" = "$(cat "$RUN/uploads-stats.before")" ] && ok "uploads volume: $UPS_NOW (files, KiB) unchanged" || vfail "uploads volume changed: $(cat "$RUN/uploads-stats.before") → $UPS_NOW"
  RUNNING=$(app_image_digest 2>/dev/null || true); [ "${RUNNING#*@}" = "${NEW_PINNED#*@}" ] && ok "running image digest matches the pin" || vfail "running digest ${RUNNING:-<none>} ≠ ${NEW_PINNED#*@}"
  DEEP=$(deep_probe_body); if printf '%s' "$DEEP" | grep -q '"schema"[^}]*"status":"error"'; then vfail "deep probe reports schema drift: $(printf '%s' "$DEEP" | cut -c1-200)"; elif [ -n "$DEEP" ]; then ok "deep probe answered ($(printf '%s' "$DEEP" | cut -c1-80)…)"; else warn "deep probe returned nothing (METRICS_TOKEN not honoured yet?) — advisory"; fi
  if [ -n "$(env_get .env POSTGRES_PRIVILEGED_URL_FILE '')" ]; then
    [ "$(compose exec -T app sh -c 'tr "\0" "\n" < /proc/1/environ | grep -c "^POSTGRES_PRIVILEGED_URL="' 2>/dev/null | tr -d '[:space:]')" = "1" ] && ok "privileged pool is wired into the app process" || vfail "POSTGRES_PRIVILEGED_URL did not reach the app process"
    ./provision-privileged-role.sh --check >/dev/null 2>&1 && ok "neogen_priv verified (BYPASSRLS, member of neo_gen, login works)" || vfail "provision-privileged-role.sh --check fails"
  fi
  UNSCOPED=$(psql_scalar "select count(*) from apikey where organization_id is null"); [ -n "$UNSCOPED" ] && log "API keys without an organization (hold no org authority until re-bound): $UNSCOPED"
  # login smoke: the auth stack must answer through the ingress; a non-existent
  # account gets a 4xx JSON (touches user/account/session tables, no lockout row)
  HC=$(curl_site GET /api/auth/get-session -o /dev/null -w '%{http_code}' 2>/dev/null || echo 000); [ "$HC" = "200" ] && ok "GET /api/auth/get-session → 200" || vfail "GET /api/auth/get-session → $HC"
  HC=$(curl_site POST /api/auth/sign-in/email -o "$RUN/.signin.json" -w '%{http_code}' -H 'Content-Type: application/json' -H "Origin: $(env_get .env BETTER_AUTH_URL '')" \
        -d "{\"email\":\"smoke-$RUN_ID@invalid.example\",\"password\":\"not-a-password\"}" 2>/dev/null || echo 000)
  case "$HC" in 400|401|403|422) ok "POST /api/auth/sign-in/email (unknown account) → $HC (auth stack answers)" ;; *) vfail "sign-in probe → $HC ($(cut -c1-120 "$RUN/.signin.json" 2>/dev/null))" ;; esac
  if $SMOKE_LOGIN; then
    SE=$(env_get .env SMOKE_LOGIN_EMAIL ''); SP=$(cat secrets/smoke_login_password 2>/dev/null || sudo -n cat secrets/smoke_login_password 2>/dev/null || true)
    if [ -n "$SE" ] && [ -n "$SP" ]; then
      HC=$(curl_site POST /api/auth/sign-in/email -c "$RUN/.cookies" -o "$RUN/.signin2.json" -w '%{http_code}' -H 'Content-Type: application/json' -H "Origin: $(env_get .env BETTER_AUTH_URL '')" -d "{\"email\":\"$SE\",\"password\":$(printf '%s' "$SP" | sed 's/\\/\\\\/g;s/"/\\"/g;s/^/"/;s/$/"/')}" 2>/dev/null || echo 000)
      [ "$HC" = "200" ] && ok "smoke user signed in" || vfail "smoke user sign-in → $HC"
      curl_site POST /api/auth/sign-out -b "$RUN/.cookies" -o /dev/null -H "Origin: $(env_get .env BETTER_AUTH_URL '')" >/dev/null 2>&1 || true; rm -f "$RUN/.cookies" "$RUN/.signin2.json"
    else warn "--smoke-login: SMOKE_LOGIN_EMAIL (./.env) or secrets/smoke_login_password missing — skipped"; fi
  fi
  rm -f "$RUN/.signin.json"
  if ! $SKIP_PARITY; then
    ./schema-parity.sh "$TARGET" --out "$RUN/parity-after" && ok "live catalog matches db/$TARGET/schema.sql" || vfail "schema parity vs db/$TARGET differs (see $RUN/parity-after)"
  fi
  sv VERIFY_FAILURES "$V"
  finish verify
  if [ "$V" != "0" ]; then
    hdr "Upgraded, but $V verification(s) failed"
    warn "the app is SERVING on the new image. Investigate before opening to users; rollback is still valid:  ./upgrade-release.sh --rollback $RUN_ID"
    FINISHED=true; exit 4
  fi
fi

hdr "Upgrade complete"
sv OPENED_AT "$(date +%FT%T)"
{ echo "run:        $RUN_ID"; echo "from:       db $OLD_DB_VERSION, image ${OLD_DIGEST:-?}"; echo "to:         db $TARGET, image $NEW_PINNED"; echo "bundle:     $DUMP ${UPL:++ $UPL} (+ config/caddy tars, manifest)"; echo "opened at:  $(gv OPENED_AT)"; echo "rollback:   ./upgrade-release.sh --rollback $RUN_ID --accept-data-loss-since   (discards writes after opened-at)"; } | tee "$RUN/summary.txt"
ok "db $TARGET on $NEW_PINNED, all verifications passed. The window can close."
FINISHED=true
exit 0
