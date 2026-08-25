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

# Set true by apply_migrations when it applies a REQUIRES-REVIEW (destructive)
# migration in the current run. Top-level init: consumers run `set -u`, and the
# flag must be safely readable even when apply_migrations never ran.
APPLIED_DESTRUCTIVE=false

compose() {
  if [ -f "$ROLLBACK_PIN" ]; then
    # Explicit -f lists disable Compose's default file discovery — include the
    # user's override file (a standard Compose idiom; first-found of the two
    # spellings, mirroring Compose's own discovery order) so pin mode deploys
    # the same config as non-pin mode, plus the pin (last wins).
    local ovr="" f
    for f in docker-compose.override.yml docker-compose.override.yaml; do
      if [ -f "$f" ]; then ovr="$f"; break; fi
    done
    if [ -n "$ovr" ]; then
      $DOCKER compose -f docker-compose.yml -f "$ovr" -f "$ROLLBACK_PIN" "$@"
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
# KNOWN DEVIATION from Compose dotenv: an EXPLICITLY-EMPTY assignment (`KEY=`)
# returns the caller's DEFAULT here, while Compose keeps the empty string.
# Deliberate: these scripts treat "blanked" and "absent" alike. Keep values
# non-empty, or delete the line entirely to mean "use the default".
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
NXPI_HASH_DEFAULT="ghcr.io/negentrophi/nxpi-hash:latest"

# ── Health helpers ───────────────────────────────────────────────────────────
# wait_healthy SERVICE TIMEOUT_SECONDS — polls the container health status.
wait_healthy() {
  local svc="$1" timeout="${2:-180}" start now cid status restarts base_restarts=""
  start=$(date +%s)
  while :; do
    # Reset each iteration so the timeout message never shows a STALE status
    # from a prior loop (e.g. a container that vanished mid-wait).
    status="no container"
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
      # Crash-loop fast-fail: every service runs restart:unless-stopped, so a
      # crashing container cycles restarting/running and NEVER reports
      # `exited` — without this check the full timeout burns before a caller
      # (e.g. update.sh's auto-rollback) can react. Two restarts observed
      # during THIS wait = a loop, not a slow boot.
      restarts=$($DOCKER inspect --format '{{.RestartCount}}' "$cid" 2>/dev/null || echo "")
      case "$restarts" in
        ''|*[!0-9]*) : ;;   # inspect failed — leave it to the timeout
        *)
          [ -n "$base_restarts" ] || base_restarts=$restarts
          if [ $((restarts - base_restarts)) -ge 2 ]; then
            warn "$svc is crash-looping (+$((restarts - base_restarts)) restarts during this wait)"
            compose logs --tail 30 "$svc" || true
            return 1
          fi ;;
      esac
    fi
    now=$(date +%s)
    if [ $((now - start)) -ge "$timeout" ]; then
      warn "$svc did not become healthy within ${timeout}s (status: ${status})"
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

# deep_probe_body — print /api/health/deep's response body (empty on failure).
# Unlike ingress_probe this does NOT use -f: a 503 body is exactly what we want
# to read. Same --resolve treatment so the real vhost is exercised.
deep_probe_body() {
  local site http_port https_port
  site=$(env_get .env SITE_ADDRESS "")
  if [ -n "$site" ]; then
    https_port=$(env_get .env CADDY_HTTPS_PORT 443)
    curl -sS --max-time 5 \
      --resolve "${site}:${https_port}:127.0.0.1" \
      "https://${site}:${https_port}/api/health/deep" 2>/dev/null || true
  else
    http_port=$(env_get .env CADDY_HTTP_PORT 80)
    curl -sS --max-time 5 \
      "http://127.0.0.1:${http_port}/api/health/deep" 2>/dev/null || true
  fi
}

# schema_notice — surface a schema-behind-image condition to the OPERATOR at the
# one moment they are watching: the end of install/update/migrate.
#
# Readiness deliberately does not gate on schema currency (a drifted schema is
# degraded, not unservable), so without this the 2026-07-28 VM incident repeats:
# every skill route 500s with 42703 while every deploy signal stays green. Deep
# DOES gate, so a 503 there with a healthy readiness means schema skew.
#
# NEVER fails: this is advisory output, not a gate. Prints the deep body rather
# than extracting from it — no jq dependency, and the operator gets the missing
# columns AND the pending migration names verbatim.
#
# The match relies on `schema` being the LAST key of `checks` (probes.ts builds
# `{ database, redis, queues, schema }`), so a queue-level "status":"error"
# earlier in the body cannot be mistaken for schema drift — verified against
# that exact shape. Worst case if that order ever changes is a spurious advisory
# line, never a failed deploy.
schema_notice() {
  local body
  body=$(deep_probe_body)
  case "$body" in
    *'"schema"'*'"status":"error"'*) ;;
    *) return 0 ;;
  esac
  warn "DATABASE SCHEMA IS BEHIND THIS IMAGE — skill/plugin requests will fail
  with 42703/42P01 until the pending delta is applied:
      set DB_VERSION in ./.env and run ./migrate.sh
  /api/health/deep reports:
$body"
  return 0
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
      # Advisory, never gating — see schema_notice.
      schema_notice
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
# ── Data placement ───────────────────────────────────────────────────────────
# The compose file CAN bind-pin postgres-data, postgres-wal and redis-data to
# dedicated managed disks (opt-in — the driver_opts blocks ship commented out).
# Nothing here validated a mount, a filesystem or a volume's device before, and
# the failure that matters is silent: an unmounted disk used to mean Postgres
# initdb'ing an empty cluster that passes every health check while serving zero
# rows. Binding a SUBDIRECTORY of each mountpoint makes Docker refuse instead —
# these deciders are the preflight that explains WHY before the container start
# fails.
#
# Each is pure (text in, verdict out) so tests/lib-harness.sh can assert it; the
# impure one-line wrappers that shell out live below them.

# fstab_has_mount FSTAB_TEXT MOUNTPOINT — is the mount persisted across reboot?
# A commented line must NOT count: a VM that boots without the disk looks
# correctly configured right up until it reboots.
fstab_has_mount() {
  printf '%s\n' "$1" | grep -vE '^[[:space:]]*#' | awk -v mp="$2" '$2 == mp { found = 1 } END { exit !found }'
}

# mount_ok FINDMNT_LINE — "<target> <source> <fstype> <options>". Empty input
# means the path is not a mount at all; a read-only mount fails too, because
# Postgres cannot start on one.
mount_ok() {
  [ -n "${1:-}" ] || return 1
  case " $(printf '%s' "$1" | awk '{print $4}' | tr ',' ' ') " in
    *" ro "*) return 1 ;;
  esac
  return 0
}

# has_free_kb HAVE NEED — fails CLOSED on empty or non-numeric input, mirroring
# assert_numeric: an unreadable df must never read as "plenty of room".
has_free_kb() {
  case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac
  case "${2:-}" in ''|*[!0-9]*) return 1 ;; esac
  [ "$1" -ge "$2" ]
}

# parse_kb_avail DF_OUTPUT — the Available column of `df -Pk`. Lifted out of
# update.sh's inline awk so the arithmetic is assertable.
parse_kb_avail() {
  printf '%s\n' "$1" | awk 'NR==2 {print $4}'
}

# ── pgBackRest (point-in-time recovery) ──────────────────────────────────────

# pgbackrest_ready IMAGE ARCHIVE_MODE — is this deployment actually archiving?
# Both halves are required and they fail differently:
#   • the STOCK pgvector image has no pgbackrest binary, so archive_command
#     fails on every segment and Postgres retains WAL until the disk fills and
#     writes stop — worse than not archiving at all;
#   • archive_mode=off means backups exist but nothing bridges the gaps between
#     them, so "we have PITR" is false while every command still exits 0.
# Fails CLOSED on empty input, like assert_numeric.
pgbackrest_ready() {
  image="${1:-}" mode="${2:-}"
  [ -n "$image" ] || return 1
  [ "$mode" = "on" ] || return 1
  case "$image" in
    *nxpi-postgres*) return 0 ;;
    *) return 1 ;;
  esac
}

# pgbackrest_argv STANZA SUBCOMMAND… — always carries --stanza. Without it
# pgbackrest silently operates on whichever stanza the config names first,
# which on a multi-stanza repository is someone else's database.
pgbackrest_argv() {
  stanza="$1"; shift
  printf '%s' "--stanza=$stanza"
  for a in "$@"; do printf ' %s' "$a"; done
}

# prune_keeping CANDIDATES KEEP_LIST — newline-separated paths in, the subset
# that may be DELETED out. Age alone is not a retention policy: `find -mtime`
# will happily remove the last dump after a quiet month, and a backup set you
# can lose to inactivity is not a backup set. Matching is EXACT per line, so
# `neogen-11.dump` never protects `neogen-1.dump`.
# Passed through the ENVIRONMENT, not `awk -v`: -v runs escape processing and
# chokes on a literal newline ("awk: newline in string"), which silently emptied
# the result — i.e. it pruned nothing rather than pruning wrongly, but a
# retention policy that quietly stops working is still a broken one.
prune_keeping() {
  printf '%s\n' "$1" | KEEP_LIST="$2" awk '
    BEGIN {
      n = split(ENVIRON["KEEP_LIST"], k, "\n")
      for (i = 1; i <= n; i++) if (k[i] != "") protected[k[i]] = 1
    }
    $0 != "" && !($0 in protected) { print }
  '
}

# compose_volume_device FILE VOLNAME — the `device:` a named volume is pinned
# to in the compose FILE, or empty. Scoped to that volume's own block: reading
# the next volume's device instead would make the adoption guard compare the
# wrong pair and report a mismatch that is not there.
compose_volume_device() {
  awk -v want="$2" '
    /^volumes:[[:space:]]*$/ { in_vols = 1; next }
    in_vols && /^[^[:space:]#]/ { in_vols = 0 }          # next top-level key ends it
    !in_vols { next }
    /^[[:space:]]{2}[^[:space:]#][^:]*:[[:space:]]*$/ {  # a volume key
      name = $0; sub(/^[[:space:]]+/, "", name); sub(/:.*$/, "", name)
      here = (name == want)
      next
    }
    here && /^[[:space:]]*device:[[:space:]]*/ {
      sub(/^[[:space:]]*device:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, "")
      print; exit
    }
  ' "$1" 2>/dev/null
}

# placement_verdict VOLUME_EXISTS DECLARED_DEVICE ACTUAL_DEVICE [DISK_HAS_PGDATA]
#   → fresh | adopt | mismatch
#
# The whole adoption decision, with no docker in it. Replaces install.sh's
# name-only check, which could not tell these apart:
#   • rebuilt VM: no volume yet, but the attached disk already holds PGDATA.
#     Name-only says "fresh" → new secrets generated against live data →
#     stored integration credentials permanently undecryptable.
#   • re-pointed volume: the file declares a device the existing volume does not
#     have (or vice versa). Docker refuses to change a volume's options, so
#     converging silently fails to do what the operator believes it did.
placement_verdict() {
  vol_exists="$1" declared="${2:-}" actual="${3:-}" disk_has_pgdata="${4:-}"

  if [ "$vol_exists" = "yes" ]; then
    # Disagreement in EITHER direction is a mismatch — including "the volume has
    # no device but the file pins one", which is the case where an operator
    # believes they are on the new disk and are in fact on the OS disk.
    [ "$declared" = "$actual" ] && { printf 'adopt'; return 0; }
    printf 'mismatch'; return 0
  fi

  # No volume yet. If the declared device already carries a cluster, this is a
  # rebuilt/re-attached machine and its ORIGINAL secrets are required.
  [ -n "$disk_has_pgdata" ] && { printf 'adopt'; return 0; }
  printf 'fresh'
}

# Impure wrappers — the halves that touch the machine.
disk_avail_kb()  { parse_kb_avail "$(df -Pk "$1" 2>/dev/null)"; }
mount_info()     { findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS "$1" 2>/dev/null | head -n1; }
# volume_device NAME — the host path an existing volume is bind-pinned to, or
# empty when it is an ordinary Docker-managed volume.
#
# `--format '{{.Options.device}}'` is WRONG here and the way it is wrong is
# quiet: Docker renders an empty or absent Options map as the literal string
# "<no value>". That is not a path and it is not empty either, so
# placement_verdict compares "" against "<no value>", calls it a `mismatch`,
# and install.sh refuses to converge — on EVERY unpinned deployment, which is
# every deployment that has not opted into the dedicated-disk layout. Guard on
# .Options (an empty map is falsy in Go templates) and `index` it, then
# normalize defensively in case another docker version renders it differently.
volume_device() {
  local d
  d=$($DOCKER volume inspect "$1" --format '{{if .Options}}{{index .Options "device"}}{{end}}' 2>/dev/null) || d=""
  case "$d" in "<no value>"|"<nil>") d="" ;; esac
  printf '%s' "$d"
}
is_pgdata_dir()  { [ -s "$1/PG_VERSION" ]; }

# The redis tiers, queue first. Two servers with OPPOSITE eviction policies:
# `redis` is BullMQ's (noeviction, AOF) and `redis-cache` is the app cache's
# (allkeys-lru, no persistence). Both must be flushed on a generation change.
REDIS_SERVICES="redis redis-cache"

# redis_flush_one SVC — FLUSHALL one redis service. Never fatal; the warning
# names the SERVICE so an operator cannot paste a command that flushes the
# other tier. A service that is not running is skipped silently: `redis-cache`
# is optional, and warning about it on every install would be noise.
redis_flush_one() {
  svc="$1"
  [ -n "$(compose ps -q "$svc" 2>/dev/null)" ] || return 0
  compose exec -T "$svc" sh -c 'REDISCLI_AUTH=$(cat /run/secrets/redis_password) redis-cli FLUSHALL' >/dev/null \
    && ok "$svc flushed" \
    || warn "could not flush $svc — flush manually: ./compose.sh exec $svc sh -c 'REDISCLI_AUTH=\$(cat /run/secrets/redis_password) redis-cli FLUSHALL'"
  return 0
}

flush_redis() {
  log "flushing Redis (cache/queues from the previous database generation)…"
  for svc in $REDIS_SERVICES; do
    redis_flush_one "$svc"
  done
  return 0
}

# ver_le A B — true if release semver A <= B. NOTE: uses `sort -V`, which orders
# a final release AFTER its pre-release (so 1.3.0-rc1 is treated as > 1.3.0),
# not strict semver precedence. This pipeline only ships plain release versions
# (release-please bare semver) as db/<ver> folders, so pre-release-tagged
# migrations do not occur — do not create pre-release-named db folders.
ver_le() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; }

# is_exact_semver — true only for a bare X.Y.Z release version (digits and dots,
# exactly three components). CI also publishes suffixed moving tags
# (`latest`, `main`, `sha-<short>`, `<pkgver>-main.<shortsha>`) — none of those
# identify a db/ package, so version alignment/derivation must ignore them.
# NOTE: a single glob like [0-9]*.[0-9]*.[0-9]* is NOT enough — each `*`
# matches anything, so `1.2.0-main.80c736af` would pass. Hence the two stages.
is_exact_semver() {
  case "$1" in
    *[!0-9.]*) return 1 ;;            # only digits and dots allowed
    *.*.*.*|.*|*.|*..*) return 1 ;;   # >3 components or an empty component
  esac
  case "$1" in
    [0-9]*.[0-9]*.[0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

# assert_version_alignment — die if DB_VERSION (./.env) is set but disagrees
# with an EXACT-semver APP_IMAGE tag. Keeps the provisioning/migration target
# aligned with the image being deployed (db_target_version gives DB_VERSION
# precedence). Suffixed/moving tags (`latest`, `main`, `sha-<short>`,
# `<pkgver>-main.<shortsha>`) skip enforcement — they don't name a db/ package,
# so DB_VERSION alone is authoritative for them.
assert_version_alignment() {
  local img tag dbv
  img=$(env_get .env APP_IMAGE "")
  dbv=$(env_get .env DB_VERSION "")
  case "$img" in *@sha256:*) return 0 ;; esac   # digest pin — no tag to compare
  tag=${img##*:}
  case "$tag" in */*) return 0 ;; esac          # registry :port, no tag
  tag=${tag#v}                                   # strip leading v so :v1.2.0 matches
  if is_exact_semver "$tag"; then
    [ -z "$dbv" ] || [ "${dbv#v}" = "$tag" ] \
      || die "APP_IMAGE tag is $tag but DB_VERSION=$dbv in ./.env — align them
  (set DB_VERSION=$tag, or unset it to derive from the image tag) and re-run."
  fi
}

# db_target_version — the bare semver this deployment targets, from DB_VERSION
# or the APP_IMAGE tag. Prints the version, or NOTHING if it cannot be derived
# (a digest pin `…@sha256:…`, an untagged image — including one whose registry
# has a `:port` — or ANY non-exact-semver tag: `latest`, `main`, `sha-<short>`,
# `<pkgver>-main.<shortsha>`; those are moving tags and never name a db/
# package, so only DB_VERSION can resolve them).
db_target_version() {
  local ver img
  ver=$(env_get .env DB_VERSION "")
  if [ -z "$ver" ]; then
    img=$(env_get .env APP_IMAGE "")
    case "$img" in *@sha256:*) return 0 ;; esac   # digest pin — no version
    ver=${img##*:}
    # A '/' in the extracted segment means the last ':' was a registry PORT,
    # not a tag → the image is untagged (no derivable version).
    case "$ver" in ""|"$img"|*/*) ver="" ;; esac
    ver=${ver#v}
    # Only an exact X.Y.Z tag identifies a db/ package.
    if [ -n "$ver" ] && ! is_exact_semver "$ver"; then ver=""; fi
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
    # `-n` first: an EXPIRED sudo cache in a non-interactive run (plausible
    # after a long image pull) must fail fast, not hang on a hidden password
    # prompt with stderr discarded. Retry interactively only when a tty can
    # actually take the prompt.
    url=$(sudo -n cat secrets/postgres_url 2>/dev/null || true)
    if [ -z "$url" ] && [ -t 0 ]; then
      url=$(sudo cat secrets/postgres_url 2>/dev/null || true)
    fi
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
# Ordering key is the FILENAME's embedded version (the same key the <= filter
# uses) — path order would let a hotfix file whose version differs from its
# folder (db/1.3.0/migrate-1.2.5.sql) apply out of numeric order.
migration_files_through() {
  local target="$1" f base ver
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base=$(basename "$f" .sql); ver=${base#migrate-}
    ver_le "$ver" "$target" && printf '%s\t%s\n' "$ver" "$f"
  done < <(find db -mindepth 2 -maxdepth 2 -name 'migrate-*.sql' 2>/dev/null) \
    | sort -V -k1,1 | cut -f2-
}

# stamp_migrations_through VERSION — record all migrations <= VERSION as applied
# WITHOUT running them. Used after a FRESH install, whose schema.sql already
# embeds every change up to VERSION (so a later update never re-applies them).
stamp_migrations_through() {
  local target="$1" f base base_sql
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    base_sql=${base//\'/\'\'}   # SQL-escape: filenames come from CI, but cheap
    psql_admin -c "insert into public.deploy_schema_migrations (filename) values ('$base_sql') on conflict do nothing;" >/dev/null \
      || die "could not record migration $base in the marker table — re-run when the DB is stable"
  done 3< <(migration_files_through "$target")
}

# apply_migrations — apply every db/*/migrate-*.sql with version <= the target
# version that is not yet recorded, in ascending order (a multi-release jump
# applies each intermediate delta). Returns 0 if ≥1 applied, 10 if none pending.
# A migration failure — or a REQUIRES-REVIEW file without an explicit override —
# is FATAL (caller must not roll the app onto it).
apply_migrations() {
  local target f base base_sql applied any=false
  APPLIED_DESTRUCTIVE=false   # per-invocation reset (global — callers inspect it)
  target=$(resolved_db_version) || die "cannot resolve the target DB version — set DB_VERSION in ./.env"
  ensure_migration_marker
  # Read the list on fd 3, NOT fd 0: the `compose exec -T` calls in the loop
  # body read stdin and would otherwise DRAIN the pipe (only the first
  # migration would be seen).
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    base_sql=${base//\'/\'\'}
    # FAIL CLOSED: a transient psql error must not be read as "not applied"
    # (which would re-run a non-idempotent ADD COLUMN and die "already exists").
    local rc
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base_sql'" 2>/dev/null); rc=$?; set -e
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
      APPLIED_DESTRUCTIVE=true
    fi
    log "applying migration: $base"
    # -1 (--single-transaction): a mid-file failure rolls the WHOLE file back —
    # without it, a delta that drops+recreates constraints could die halfway
    # and leave the schema mangled with NO marker row. NOTE: the frozen
    # 1.3.0–1.8.0 files carry internal BEGIN/COMMIT blocks; under -1 psql
    # warns "there is already a transaction in progress" and the inner COMMITs
    # win — harmless noise, never "fix" the frozen files to silence it.
    psql_admin -1 < "$f" || die "migration $base FAILED — the transaction was rolled back; inspect $f and retry"
    psql_admin -c "insert into public.deploy_schema_migrations (filename) values ('$base_sql') on conflict do nothing;" >/dev/null \
      || die "could not record migration $base in the marker table — re-run when the DB is stable"
    any=true
  done 3< <(migration_files_through "$target")
  if $any; then
    # Re-apply the target release's grants (idempotent): migrations can add
    # schemas/objects whose grants only exist in the NEWEST grants.sql (e.g.
    # the ADR-0038 drizzle-schema block, added in 1.9.0) — a VM provisioned at
    # an older release would otherwise never receive them.
    # set -e is DISABLED in here when the caller runs `if apply_migrations`,
    # so every mutating command must carry an explicit || die.
    local dbd
    dbd=$(db_dir) || die "cannot resolve db/<version> for the grants re-apply — set DB_VERSION in ./.env"
    log "re-applying ${dbd}/grants.sql (idempotent — grants for new objects)…"
    psql_admin < "$dbd/grants.sql" \
      || die "grants.sql failed after migrations — the app role may lack grants on new tables; re-run"
    return 0
  fi
  return 10
}

# has_pending_destructive — prints the first UNAPPLIED REQUIRES-REVIEW migration
# (<= target) that apply_migrations would run, or nothing. update.sh uses this
# to keep the rolling-update path strictly additive: a destructive change must
# go through ./migrate.sh (its own backup, no auto-rollback "additive-compatible"
# assumption), never the rolling path whose rollback trusts additivity.
has_pending_destructive() {
  local target f base base_sql applied rc
  target=$(resolved_db_version) || return 0
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    base_sql=${base//\'/\'\'}
    # FAIL CLOSED (like apply_migrations): a transient psql error must not read
    # as "not applied" and falsely flag an already-applied migration as pending.
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base_sql'" 2>/dev/null); rc=$?; set -e
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
  local target f base base_sql applied rc
  target=$(resolved_db_version) || return 1
  ensure_migration_marker
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f")
    base_sql=${base//\'/\'\'}
    set +e; applied=$(psql_admin -tAc "select 1 from public.deploy_schema_migrations where filename = '$base_sql'" 2>/dev/null); rc=$?; set -e
    [ $rc -eq 0 ] || die "could not read the migration marker for $base (postgres busy?) — re-run when stable"
    [ "$(printf '%s' "$applied" | tr -d '[:space:]')" = "1" ] || return 0
  done 3< <(migration_files_through "$target")
  return 1
}
