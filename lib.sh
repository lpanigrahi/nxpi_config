#!/usr/bin/env bash
# =============================================================================
# lib.sh — shared helpers for the standalone Azure deployment scripts.
# Sourced by install.sh / update.sh / backup.sh / restore.sh — not executable
# on its own. Every consumer runs `set -euo pipefail` and cd's here first.
# =============================================================================

# ── Logging ──────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'; C_BLU=$'\033[34m'; C_BLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YLW=""; C_BLU=""; C_BLD=""; C_RST=""
fi
log()  { printf '%s\n' "${C_BLU}▸${C_RST} $*"; }
ok()   { printf '%s\n' "${C_GRN}✔${C_RST} $*"; }
warn() { printf '%s\n' "${C_YLW}⚠ $*${C_RST}" >&2; }
die()  { printf '%s\n' "${C_RED}✖ $*${C_RST}" >&2; exit 1; }
hdr()  { printf '\n%s\n' "${C_BLD}── $* ${C_RST}"; }

# ── Docker access ────────────────────────────────────────────────────────────
# Sets $DOCKER to "docker" or "sudo docker" (fresh installs: the docker group
# is not active in the current shell until re-login).
DOCKER="docker"
init_docker() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed (run ./install.sh first)"
  if docker info >/dev/null 2>&1; then
    DOCKER="docker"
  elif sudo -n true 2>/dev/null && sudo docker info >/dev/null 2>&1; then
    DOCKER="sudo docker"
    warn "docker requires sudo in this shell (docker group not active yet — re-login to fix); using 'sudo docker'"
  else
    die "cannot talk to the Docker daemon (try: sudo usermod -aG docker \$USER && re-login)"
  fi
  $DOCKER compose version >/dev/null 2>&1 || die "the Docker Compose v2 plugin is missing (docker compose version failed)"
}

# All compose invocations honor the rollback pin written by update.sh's
# automatic rollback (.rollback-image.yml). Without this, ANY other entry
# point (restore.sh's `up -d`, install.sh's converge) would silently recreate
# the app on the known-broken .env image and undo the rollback. update.sh
# removes the pin when a later update succeeds.
ROLLBACK_PIN=".rollback-image.yml"
compose() {
  if [ -f "$ROLLBACK_PIN" ]; then
    # Explicit -f lists disable Compose's default file discovery — include a
    # user's docker-compose.override.yml (a standard Compose idiom) so pin
    # mode deploys the same config as non-pin mode, plus the pin (last wins).
    if [ -f docker-compose.override.yml ]; then
      $DOCKER compose -f docker-compose.yml -f docker-compose.override.yml -f "$ROLLBACK_PIN" "$@"
    else
      $DOCKER compose -f docker-compose.yml -f "$ROLLBACK_PIN" "$@"
    fi
  else
    $DOCKER compose "$@"
  fi
}
# compose_raw — IGNORES the rollback pin. Used only by update.sh's pull/roll
# steps, which must target the new .env image while the pin (the last-good
# safety net) stays on disk untouched until the update actually succeeds.
compose_raw() { $DOCKER compose "$@"; }

# ── Mutual exclusion ─────────────────────────────────────────────────────────
# The mutating scripts (install/update/migrate/backup/restore) must not
# interleave — e.g. a cron backup firing mid-restore would snapshot a
# half-restored database as the newest "good" dump. Non-blocking: a collision
# fails fast instead of queueing. Nested invocations (update.sh → backup.sh)
# share the parent's lock via DEPLOY_LOCK_HELD.
acquire_lock() {
  [ -n "${DEPLOY_LOCK_HELD:-}" ] && return 0
  if ! command -v flock >/dev/null 2>&1; then
    warn "flock not available — proceeding without the inter-script lock"
    return 0
  fi
  exec 9> .deploy.lock
  flock -n 9 || die "another deployment operation holds the lock (.deploy.lock) — wait for it to finish and retry"
  export DEPLOY_LOCK_HELD=1
}

# ── .env readers ─────────────────────────────────────────────────────────────
# env_get FILE KEY [DEFAULT] — last uncommented assignment wins, following
# Compose's dotenv rules:
#   • a QUOTED value ("…" or '…') keeps everything up to the matching quote —
#     including a literal ` #` (so a password quoted as "p @ss #1" survives);
#   • an UNQUOTED value has a trailing inline comment (` # …`) and trailing
#     whitespace stripped (so `SITE_ADDRESS=x.com  # prod` yields `x.com`).
# Values with spaces / `#` MUST be quoted in ./.env (see .env.example).
env_get() {
  local file="$1" key="$2" def="${3:-}" raw val s ch nx
  raw=$(grep -E "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2- || true)
  raw="${raw#"${raw%%[![:space:]]*}"}"   # trim leading whitespace
  case "$raw" in
    \"*)
      # Double-quoted: content is LITERAL except that \" embeds a double-quote
      # and \\ embeds a backslash; every OTHER backslash is kept verbatim (so a
      # password like "a\b\c" stays a\b\c, and a stray \n does NOT become a
      # newline that could corrupt an image ref / URL). Stop at the first
      # UNESCAPED " (so `"p\"ss"` → p"ss, not a truncation).
      s="${raw#\"}"; val=""
      while [ -n "$s" ]; do
        ch=${s:0:1}; s=${s:1}
        if [ "$ch" = "\\" ]; then
          nx=${s:0:1}
          case "$nx" in
            '"') val+='"';  s=${s:1} ;;   # \" → "
            '\') val+='\';  s=${s:1} ;;   # \\ → backslash
            *)   val+='\' ;;              # lone backslash — keep it literal
          esac
        elif [ "$ch" = '"' ]; then break
        else val+="$ch"; fi
      done ;;
    \'*) val="${raw#\'}"; val="${val%%\'*}" ;;   # single-quoted: literal, up to next '
    *)   val=$(printf '%s' "$raw" | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//') ;;
  esac
  printf '%s' "${val:-$def}"
}

# The compose project name — matches `name:` in ./docker-compose.yml unless
# overridden by COMPOSE_PROJECT_NAME, which Compose reads from the OS env OR
# from ./.env (OS env wins — same precedence Compose itself applies). Volume
# names derive from it (e.g. ${PROJECT}_uploads-data); getting this wrong
# would point the adoption guard and backup/restore at the WRONG volumes.
PROJECT="${COMPOSE_PROJECT_NAME:-$(env_get .env COMPOSE_PROJECT_NAME neogen)}"

# Default public admin-password hash helper image (override via NXPI_HASH_IMAGE
# in ./.env). Single source of truth — used by admin_hash and install.sh.
NXPI_HASH_DEFAULT="ghcr.io/lpanigrahi/nxpi-hash:latest"

# ── Health helpers ───────────────────────────────────────────────────────────
# wait_healthy SERVICE TIMEOUT_SECONDS — polls the container health status.
wait_healthy() {
  local svc="$1" timeout="${2:-180}" start now cid status
  start=$(date +%s)
  while :; do
    cid=$(compose ps -q "$svc" 2>/dev/null | head -n1 || true)
    if [ -n "$cid" ]; then
      status=$($DOCKER inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cid" 2>/dev/null || echo "unknown")
      if [ "$status" = "healthy" ]; then
        ok "$svc is healthy"
        return 0
      fi
      if [ "$status" = "exited" ] || [ "$status" = "dead" ]; then
        warn "$svc container is $status"
        compose logs --tail 30 "$svc" || true
        return 1
      fi
    fi
    now=$(date +%s)
    if [ $((now - start)) -ge "$timeout" ]; then
      warn "$svc did not become healthy within ${timeout}s (status: ${status:-no container})"
      compose logs --tail 30 "$svc" || true
      return 1
    fi
    sleep 3
  done
}

# ingress_probe — hit the readiness endpoint THROUGH Caddy (proves the full
# public path, not just the container).
#   IP-only mode:  the Caddy site is `:80` (matches any Host) → plain
#                  http://127.0.0.1:<port> works.
#   Domain mode:   the site block binds ONLY the domain — a Host:127.0.0.1
#                  request would get Caddy's blank unmatched-host response
#                  (a vacuous 200). Probe https://<domain> pinned to loopback
#                  via --resolve instead: this exercises the real vhost AND
#                  the real certificate, so a failed ACME issuance correctly
#                  fails the gate.
ingress_probe() {
  local site http_port https_port
  site=$(env_get .env SITE_ADDRESS "")
  if [ -n "$site" ]; then
    https_port=$(env_get .env CADDY_HTTPS_PORT 443)
    curl -fsS --max-time 5 \
      --resolve "${site}:${https_port}:127.0.0.1" \
      "https://${site}:${https_port}/api/health/ready" >/dev/null 2>&1
  else
    http_port=$(env_get .env CADDY_HTTP_PORT 80)
    curl -fsS --max-time 5 \
      "http://127.0.0.1:${http_port}/api/health/ready" >/dev/null 2>&1
  fi
}

ingress_desc() {
  local site
  site=$(env_get .env SITE_ADDRESS "")
  if [ -n "$site" ]; then
    printf 'https://%s (via 127.0.0.1)' "$site"
  else
    printf 'http://127.0.0.1:%s' "$(env_get .env CADDY_HTTP_PORT 80)"
  fi
}

# health_gate TIMEOUT — app container healthy AND readiness 200 via Caddy.
# TIMEOUT is the OVERALL budget, shared by both phases: the ingress loop runs
# until the deadline rather than a fixed try count (a domain-mode first
# install may legitimately spend minutes on Let's Encrypt issuance).
health_gate() {
  local timeout="${1:-300}" start
  start=$(date +%s)
  wait_healthy app "$timeout" || return 1
  log "probing ingress: $(ingress_desc)/api/health/ready"
  while :; do
    if ingress_probe; then
      ok "readiness OK through Caddy"
      return 0
    fi
    if [ $(($(date +%s) - start)) -ge "$timeout" ]; then
      break
    fi
    sleep 3
  done
  warn "readiness endpoint not answering through Caddy at $(ingress_desc)"
  return 1
}

# ── Database helpers ─────────────────────────────────────────────────────────
# table_count — number of tables in schema `public`. Prints NOTHING on query
# failure (deliberate: callers must FAIL CLOSED on an empty result rather than
# mistake a transient exec/psql failure for a fresh database).
table_count() {
  compose exec -T postgres psql -U neogen_admin -d neogen -tAc \
    "select count(*) from information_schema.tables where table_schema='public'" \
    2>/dev/null | tr -d '[:space:]' || true
}

# user_count — rows in the auth "user" table; the bootstrap-completion
# sentinel (schema pushed but zero users ⇒ bootstrap died before seeding).
# Prints "-1" when the table does not exist (a schema push interrupted before
# the "user" table was created — also an incomplete bootstrap, NOT a transient
# failure). Prints NOTHING on query failure — fail-closed like table_count.
# NOTE: this MUST be two separate queries — a single CASE expression that
# references public."user" in its else-branch fails Postgres parse analysis
# when the relation is missing, even though that branch would never execute.
user_count() {
  local missing
  missing=$(compose exec -T postgres psql -U neogen_admin -d neogen -tAc \
    "select to_regclass('public.user') is null" \
    2>/dev/null | tr -d '[:space:]' || true)
  case "$missing" in
    t) printf -- '-1' ;;
    f) compose exec -T postgres psql -U neogen_admin -d neogen -tAc \
         'select count(*) from public."user"' \
         2>/dev/null | tr -d '[:space:]' || true ;;
    *) : ;;   # query failed → print nothing (caller fails closed)
  esac
}

# assert_numeric VALUE WHAT — die unless VALUE is a plain non-negative integer.
assert_numeric() {
  case "$1" in
    ''|*[!0-9]*) die "could not read $2 from the database (transient failure or postgres not ready) — refusing to guess; re-run when the stack is stable" ;;
  esac
}

# current app image digest (immutable, pullable rollback ref); empty if none.
app_image_digest() {
  local cid img
  cid=$(compose ps -q app 2>/dev/null | head -n1 || true)
  [ -n "$cid" ] || return 0
  img=$($DOCKER inspect --format '{{.Image}}' "$cid" 2>/dev/null || true)
  [ -n "$img" ] || return 0
  $DOCKER image inspect --format '{{if .RepoDigests}}{{index .RepoDigests 0}}{{end}}' "$img" 2>/dev/null || true
}

# ── Sourceless provisioning (static SQL applied by psql) ─────────────────────
# psql_admin [psql-args...] — run psql inside the postgres container as the
# LOCAL neogen_admin superuser (peer/trust over the container socket — no
# password, no TCP). SQL is read from the CALLER's stdin, so pipe a file:
#   psql_admin < db/1.2.0/schema.sql
#   psql_admin -v admin_email=... -v admin_password_hash=... < seed.sql
psql_admin() {
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U neogen_admin -d neogen "$@"
}

# flush_redis — FLUSHALL the redis container (queues + cache). Call whenever
# the DATABASE generation changes under a possibly-surviving redis volume
# (fresh provision, seed resume, restore): cached entities and BullMQ jobs
# keyed on the previous database's rows would otherwise leak into the new one
# — and the seed's DETERMINISTIC UUIDs (e.g. the super-admin id) make stale
# `user-<id>` cache entries COLLIDE with, not just miss, the new rows.
# Never fatal: a failed flush degrades to a manual-command warning.
flush_redis() {
  log "flushing Redis (cache/queues from the previous database generation)…"
  compose exec -T redis sh -c 'REDISCLI_AUTH=$(cat /run/secrets/redis_password) redis-cli FLUSHALL' >/dev/null \
    && ok "redis flushed" \
    || warn "could not flush redis — flush manually: ./compose.sh exec redis sh -c 'REDISCLI_AUTH=\$(cat /run/secrets/redis_password) redis-cli FLUSHALL'"
  return 0
}

# ver_le A B — true if release semver A <= B. NOTE: uses `sort -V`, which orders
# a final release AFTER its pre-release (so 1.3.0-rc1 is treated as > 1.3.0),
# not strict semver precedence. This pipeline only ships plain release versions
# (release-please bare semver) as db/<ver> folders, so pre-release-tagged
# migrations do not occur — do not create pre-release-named db folders.
ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; }

# assert_version_alignment — die if DB_VERSION (./.env) is set but disagrees
# with a semver APP_IMAGE tag. Keeps the provisioning/migration target aligned
# with the image being deployed (db_target_version gives DB_VERSION precedence).
assert_version_alignment() {
  local img tag dbv
  img=$(env_get .env APP_IMAGE "")
  dbv=$(env_get .env DB_VERSION "")
  case "$img" in *@sha256:*) return 0 ;; esac   # digest pin — no tag to compare
  tag=${img##*:}
  case "$tag" in */*) return 0 ;; esac          # registry :port, no tag
  tag=${tag#v}                                   # strip leading v so :v1.2.0 matches
  case "$tag" in
    [0-9]*.[0-9]*.[0-9]*)
      [ -z "$dbv" ] || [ "${dbv#v}" = "$tag" ] \
        || die "APP_IMAGE tag is $tag but DB_VERSION=$dbv in ./.env — align them
  (set DB_VERSION=$tag, or unset it to derive from the image tag) and re-run." ;;
  esac
}

# db_target_version — the bare semver this deployment targets, from DB_VERSION
# or the APP_IMAGE tag. Prints the version, or NOTHING if it cannot be derived
# (a digest pin `…@sha256:…`, `:latest`, or an untagged image — including one
# whose registry has a `:port`).
db_target_version() {
  local ver img
  ver=$(env_get .env DB_VERSION "")
  if [ -z "$ver" ]; then
    img=$(env_get .env APP_IMAGE "")
    case "$img" in *@sha256:*) return 0 ;; esac   # digest pin — no version
    ver=${img##*:}
    # A '/' in the extracted segment means the last ':' was a registry PORT,
    # not a tag → the image is untagged (no derivable version).
    case "$ver" in ""|latest|"$img"|*/*) ver="" ;; esac
  fi
  printf '%s' "${ver#v}"   # db/ folders are named by bare semver
}

# db_dir — the versioned SQL artifact directory. Prints the path or nothing.
# When a version is EXPLICITLY resolvable (DB_VERSION or a semver image tag) its
# folder MUST exist — no silent fallback to a different version. The lone-folder
# fallback applies ONLY when no version is derivable (e.g. :latest, one folder).
db_dir() {
  local ver
  ver=$(db_target_version)
  if [ -n "$ver" ]; then
    [ -d "db/$ver" ] && { printf 'db/%s' "$ver"; return 0; }
    return 1   # explicit version but no matching folder → fail, do NOT substitute
  fi
  # No derivable version: use a lone db/<x> folder if exactly one exists.
  if [ "$(find db -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')" = "1" ]; then
    find db -mindepth 1 -maxdepth 1 -type d | head -n1; return 0
  fi
  return 1
}

# resolved_db_version — the concrete target version, resolving the lone-folder
# fallback so migration bookkeeping has a version even for a :latest deploy.
resolved_db_version() {
  local v
  v=$(db_target_version)
  [ -n "$v" ] && { printf '%s' "$v"; return 0; }
  local d; d=$(db_dir) || return 1
  basename "$d"
}

# neo_gen_password — the app-role password, extracted (and percent-decoded)
# from the postgres_url secret. Used to ALTER ROLE neo_gen so the app (which
# connects over TCP as neo_gen) can authenticate.
# NOTE: postgres_url is chowned to uid 1001 (the app) mode 400 so the app
# container can read it — a non-root HOST user (the operator running install.sh)
# therefore cannot `cat` it directly. Fall back to sudo (install.sh requires
# sudo and has already used it to set the secret's ownership).
neo_gen_password() {
  local url pw
  url=$(cat secrets/postgres_url 2>/dev/null || true)
  if [ -z "$url" ] && [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    url=$(sudo cat secrets/postgres_url 2>/dev/null || true)
  fi
  pw=${url#*://}     # neo_gen:<pw>@postgres:5432/neogen
  pw=${pw#*:}        # <pw>@postgres:5432/neogen
  pw=${pw%%@*}       # <pw>
  # percent-decode (installer passwords are plain hex → no-op; user-supplied
  # passwords in the URL are percent-encoded per secrets/README.md).
  case "$pw" in
    *%*) printf '%b' "${pw//%/\\x}" ;;
    *)   printf '%s' "$pw" ;;
  esac
}

# admin_hash PASSWORD — Better Auth scrypt hash via the public nxpi-hash image
# (no application source). The password is piped on STDIN (never argv/env) so
# it does not appear in `docker run` argv (host ps) or `docker inspect`.
admin_hash() {
  local img
  img=$(env_get .env NXPI_HASH_IMAGE "")
  [ -n "$img" ] || img="$NXPI_HASH_DEFAULT"
  printf '%s' "$1" | $DOCKER run --rm -i "$img"
}

# ── Migration bookkeeping ────────────────────────────────────────────────────
ensure_migration_marker() {
  psql_admin -c "create table if not exists public.deploy_schema_migrations (filename text primary key, applied_at timestamptz not null default now());" >/dev/null \
    || die "could not create the migration marker table"
}

# marker_row_count — rows in deploy_schema_migrations, or nothing on failure.
marker_row_count() {
  psql_admin -tAc "select count(*) from public.deploy_schema_migrations" 2>/dev/null | tr -d '[:space:]' || true
}

# reconcile_marker DEPLOY_VERSION — initialize the migration marker on an
# already-provisioned DB that has an EMPTY marker (adopted from an external or
# older flow). We do NOT guess the schema's version: stamping DEPLOY_VERSION on
# an OLDER adopted schema would mark (and forever skip) migrations it still
# needs. The operator must confirm the schema's ACTUAL release via
# ADOPT_SCHEMA_VERSION; otherwise we only warn and leave the marker empty.
reconcile_marker() {
  local deploy_version="$1" n adopt
  ensure_migration_marker
  n=$(marker_row_count)
  [ -n "$n" ] || die "could not read the migration marker (postgres busy?) — re-run when stable"
  [ "$n" = "0" ] || return 0   # already initialized — nothing to do
  # An empty marker is LEGITIMATE and needs no action when there are no
  # migration files to stamp anyway — e.g. the FIRST release (which ships no
  # migrate-*.sql). Only an empty marker WITH pending migrate files is the
  # ambiguous adopted-external-DB case that needs an operator-confirmed version.
  [ -n "$(migration_files_through "$deploy_version")" ] || return 0
  adopt=${ADOPT_SCHEMA_VERSION:-}
  if [ -z "$adopt" ]; then
    # WARN (not die): the caller decides what to do next. For an EXTERNALLY
    # provisioned (adopted) DB, set ADOPT_SCHEMA_VERSION so update.sh does not
    # re-apply migrations the schema already has. For a THIS-flow deployment
    # this state is a pending upgrade — the caller's own pending-migration check
    # routes it to ./update.sh.
    warn "no migration marker but migrations exist for $deploy_version."
    warn "If ADOPTING an externally-provisioned DB, set ADOPT_SCHEMA_VERSION=<its release> and re-run."
    return 0
  fi
  warn "stamping the migration marker at ADOPT_SCHEMA_VERSION=$adopt (operator-confirmed)."
  stamp_migrations_through "${adopt#v}"
}

# migration_files_through VERSION — every db/*/migrate-*.sql whose embedded
# version is <= VERSION, one path per line, ascending semver order. This spans
# ALL version folders, so a multi-release jump applies each intermediate delta.
migration_files_through() {
  local target="$1" f base ver
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base=$(basename "$f" .sql); ver=${base#migrate-}
    ver_le "$ver" "$target" && printf '%s\n' "$f"
  done < <(find db -mindepth 2 -maxdepth 2 -name 'migrate-*.sql' 2>/dev/null | sort -V)
}

# stamp_migrations_through VERSION — record all migrations <= VERSION as applied
# WITHOUT running them. Used after a FRESH install, whose schema.sql already
# embeds every change up to VERSION (so a later update never re-applies them).
stamp_migrations_through() {
  local target="$1" f base
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    psql_admin -c "insert into public.deploy_schema_migrations (filename) values ('$base') on conflict do nothing;" >/dev/null \
      || die "could not record migration $base in the marker table — re-run when the DB is stable"
  done 3< <(migration_files_through "$target")
}

# apply_migrations — apply every db/*/migrate-*.sql with version <= the target
# version that is not yet recorded, in ascending order (a multi-release jump
# applies each intermediate delta). Returns 0 if ≥1 applied, 10 if none pending.
# A migration failure — or a REQUIRES-REVIEW file without an explicit override —
# is FATAL (caller must not roll the app onto it).
apply_migrations() {
  local target f base applied any=false
  target=$(resolved_db_version) || die "cannot resolve the target DB version — set DB_VERSION in ./.env"
  ensure_migration_marker
  # Read the list on fd 3, NOT fd 0: the `compose exec -T` calls in the loop
  # body read stdin and would otherwise DRAIN the pipe (only the first
  # migration would be seen).
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    # FAIL CLOSED: a transient psql error must not be read as "not applied"
    # (which would re-run a non-idempotent ADD COLUMN and die "already exists").
    local rc
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base'" 2>/dev/null); rc=$?; set -e
    [ $rc -eq 0 ] || die "could not read the migration marker for $base (postgres busy?) — re-run when stable"
    applied=$(printf '%s' "$applied" | tr -d '[:space:]')
    [ "$applied" = "1" ] && { log "migration already applied: $base"; continue; }
    # A CI-flagged destructive migration is refused unless explicitly allowed —
    # mirrors the old "destructive drizzle-kit push fails loudly" safety.
    if head -n 6 "$f" | grep -q 'REQUIRES-REVIEW'; then
      if [ "${ALLOW_DESTRUCTIVE_MIGRATION:-}" != "1" ]; then
        die "migration $base is flagged REQUIRES-REVIEW (potentially destructive —
  DROP / type narrowing). Review $f and take a backup, then re-run with
  ALLOW_DESTRUCTIVE_MIGRATION=1 to apply it."
      fi
      warn "applying DESTRUCTIVE migration $base (ALLOW_DESTRUCTIVE_MIGRATION=1)"
    fi
    log "applying migration: $base"
    psql_admin < "$f" || die "migration $base FAILED — the app was NOT changed; inspect $f and retry"
    psql_admin -c "insert into public.deploy_schema_migrations (filename) values ('$base') on conflict do nothing;" >/dev/null \
      || die "could not record migration $base in the marker table — re-run when the DB is stable"
    any=true
  done 3< <(migration_files_through "$target")
  $any && return 0 || return 10
}

# has_pending_destructive — prints the first UNAPPLIED REQUIRES-REVIEW migration
# (<= target) that apply_migrations would run, or nothing. update.sh uses this
# to keep the rolling-update path strictly additive: a destructive change must
# go through ./migrate.sh (its own backup, no auto-rollback "additive-compatible"
# assumption), never the rolling path whose rollback trusts additivity.
has_pending_destructive() {
  local target f base applied rc
  target=$(resolved_db_version) || return 0
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    # FAIL CLOSED (like apply_migrations): a transient psql error must not read
    # as "not applied" and falsely flag an already-applied migration as pending.
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base'" 2>/dev/null); rc=$?; set -e
    [ $rc -eq 0 ] || die "could not read the migration marker for $base (postgres busy?) — re-run when stable"
    applied=$(printf '%s' "$applied" | tr -d '[:space:]')
    [ "$applied" = "1" ] && continue
    if head -n 6 "$f" | grep -q 'REQUIRES-REVIEW'; then printf '%s\n' "$f"; return 0; fi
  done 3< <(migration_files_through "$target")
}

# has_pending_migration — returns 0 if ANY migration <= the target version is
# not yet recorded (the DB is behind the target image). Fails closed on a
# marker-read error, like apply_migrations.
has_pending_migration() {
  local target f base applied rc
  target=$(resolved_db_version) || return 1
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base'" 2>/dev/null); rc=$?; set -e
    [ $rc -eq 0 ] || die "could not read the migration marker for $base (postgres busy?) — re-run when stable"
    [ "$(printf '%s' "$applied" | tr -d '[:space:]')" = "1" ] || return 0
  done 3< <(migration_files_through "$target")
  return 1
}
