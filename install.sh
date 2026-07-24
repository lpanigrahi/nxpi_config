#!/usr/bin/env bash
# =============================================================================
# install.sh — single-command, idempotent installer for the NXPi standalone
# Azure VM deployment package.
#
#   ./install.sh            # fresh install OR converge an existing deployment
#   ./install.sh --force    # skip the Ubuntu distro check
#   ./install.sh --no-migrate  # re-run without the day-2 schema sync
#
# What it does (each step skips itself when already done):
#   1. verifies the environment (Ubuntu, sudo, curl/openssl)
#   2. installs Docker Engine + Compose v2 if missing
#   3. generates ./secrets/* with correct ownership (app secrets → uid 1001)
#   4. creates ./.env + ./.env.app from the examples (never overwrites),
#      auto-filling BETTER_AUTH_URL with the VM's public IP in IP-only mode
#   5. pulls the application image from the registry (never builds)
#   6. starts Postgres + Redis and waits until healthy
#   7. fresh database  → apply static SQL (schema + grants + seed) via psql
#      existing schema → nothing (use ./update.sh to move to a new release)
#   8. starts the app + Caddy and gates on health THROUGH the public ingress
#   9. prints the deployment summary
#
# The application is NEVER built here — the image is an immutable release
# artifact pulled from the registry (APP_IMAGE in ./.env).
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

FORCE=false
RUN_MIGRATE=true
for arg in "$@"; do
  case "$arg" in
    --force)      FORCE=true ;;
    --no-migrate) RUN_MIGRATE=false ;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,25p'; exit 0 ;;
    *) die "unknown flag: $arg (see --help)" ;;
  esac
done

# run a command as root (sudo only when not already root)
as_root() { if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi; }

# GNU/BSD-portable in-place sed (Ubuntu = GNU; BSD only during local testing)
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

# ── 1. Preflight ─────────────────────────────────────────────────────────────
hdr "Preflight"
if [ -r /etc/os-release ] && grep -q '^ID=ubuntu' /etc/os-release; then
  ok "Ubuntu detected"
elif $FORCE; then
  warn "not Ubuntu — continuing because of --force"
else
  die "this installer targets Ubuntu (re-run with --force to override)"
fi
command -v curl >/dev/null 2>&1 || die "curl is required"
command -v openssl >/dev/null 2>&1 || die "openssl is required"
if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  log "sudo access is needed for Docker install + secret ownership; you may be prompted"
  sudo true || die "sudo access is required"
fi
# Sudo-copy gotcha: if this folder arrived via `sudo scp`/`sudo cp` it is
# root-owned and every write below fails with a cryptic 'Permission denied'.
if [ ! -w . ]; then
  die "this directory is not writable by $(id -un) — fix ownership first:
    sudo chown -R \"\$USER\" \"$SCRIPT_DIR\""
fi
ok "preflight passed"

# ── 2. Docker Engine + Compose v2 ────────────────────────────────────────────
hdr "Docker"
if command -v docker >/dev/null 2>&1; then
  ok "docker already installed: $(docker --version 2>/dev/null || true)"
else
  [ "$(uname -s)" = "Linux" ] || die "automatic Docker install is Linux-only — install Docker manually and re-run"
  log "installing Docker Engine (get.docker.com)…"
  curl -fsSL https://get.docker.com | as_root sh
  as_root systemctl enable --now docker
  if [ "$(id -u)" -ne 0 ]; then
    as_root usermod -aG docker "$USER"
    warn "added $USER to the docker group — takes effect on your NEXT login (this run continues via sudo)"
  fi
fi
init_docker   # sets $DOCKER (docker | sudo docker), verifies compose v2
acquire_lock  # no concurrent install/update/backup/restore
ok "compose: $($DOCKER compose version --short 2>/dev/null || echo v2)"

# ── 3. Secrets ───────────────────────────────────────────────────────────────
hdr "Secrets (./secrets)"
# Nothing under secrets/ or backups/ may ever exist world-readable — not even
# between two lines of this script (an interrupted run must not leave 0644
# credentials or a listable secret inventory behind). umask BEFORE mkdir so
# the directories themselves are born 0700; chmod covers pre-existing ones.
umask 077
mkdir -p secrets backups
chmod 700 secrets backups 2>/dev/null || true
# Data-adoption guard: this package uses the same project/volume names as the
# repo-checkout deployment, so an existing postgres volume will be ADOPTED.
# Postgres only applies POSTGRES_PASSWORD_FILE at initdb — generating ANY
# fresh secret against old data breaks it: new DB passwords cannot log in,
# and a new better_auth_secret invalidates sessions AND makes stored
# integration credentials (encrypted under the old secret) permanently
# undecryptable. Require the COMPLETE original set when adopting.
if $DOCKER volume inspect "${PROJECT}_postgres-data" >/dev/null 2>&1; then
  MISSING=""
  for s in postgres_password redis_password postgres_url redis_url better_auth_secret; do
    [ -s "secrets/$s" ] || MISSING="$MISSING $s"
  done
  if [ -n "$MISSING" ]; then
    die "found an existing data volume (${PROJECT}_postgres-data) but incomplete secrets in ./secrets (missing:$MISSING).
  An adopted database only works with its ORIGINAL secrets — newly generated
  ones cannot open it (and a new better_auth_secret would permanently break
  stored integration credentials). Copy the COMPLETE secrets/ directory from
  the previous deployment into ./secrets, or start truly fresh by removing
  the old data first (DESTROYS ALL DATA):
    $DOCKER compose down -v"
  fi
fi
gen_secret() { # FILE GENERATOR… — create only if missing (idempotent)
  local f="secrets/$1"; shift
  if [ -s "$f" ]; then log "keep existing $f"; return 0; fi
  "$@" > "$f"
  ok "generated $f"
}
rand_hex() { openssl rand -hex "$1" | tr -d '\n'; }
gen_secret better_auth_secret        rand_hex 32
gen_secret postgres_password         rand_hex 24
gen_secret redis_password            rand_hex 24
# The APP connects as the least-privilege neo_gen role over TCP. Its password
# is free-standing (grants.sql creates the role LOGIN; install.sh sets this
# password on it during provisioning). DDL is applied by install.sh as the
# LOCAL neogen_admin superuser inside the postgres container — no privileged
# TCP URL / git token is needed anymore (sourceless provisioning).
gen_secret postgres_url            sh -c "printf 'postgres://neo_gen:%s@postgres:5432/neogen' \"\$(openssl rand -hex 24)\""
gen_secret redis_url               sh -c "printf 'redis://:%s@redis:6379' \"\$(cat secrets/redis_password)\""
# Compose file-secrets are bind mounts that keep HOST permissions. The app
# container runs as uid 1001 (nextjs) and must be able to read its three
# secrets; the root-read files stay owned by the invoking user, mode 600.
as_root chown 1001 secrets/postgres_url secrets/redis_url secrets/better_auth_secret
as_root chmod 400  secrets/postgres_url secrets/redis_url secrets/better_auth_secret
chmod 600 secrets/postgres_password secrets/redis_password 2>/dev/null \
  || as_root chmod 600 secrets/postgres_password secrets/redis_password
ok "secret permissions set (app secrets → uid 1001 / 400, rest → 600)"

# ── 4. Environment files ─────────────────────────────────────────────────────
hdr "Environment files"
[ -f .env ]     || { cp .env.example .env;         ok "created ./.env (from .env.example)"; }
[ -f .env.app ] || { cp .env.app.example .env.app; ok "created ./.env.app (from .env.app.example)"; }

detect_public_ip() {
  # Azure IMDS first (definitive on Azure), then a generic external probe.
  # NOTE: IMDS answers 200 with an EMPTY body when the NIC has no public IP
  # (e.g. behind a load balancer) — treat that as a miss, not a result.
  local ip
  ip=$(curl -fsS --max-time 2 -H Metadata:true \
    "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipAddress/0/publicIpAddress?api-version=2021-02-01&format=text" \
    2>/dev/null || true)
  if [ -n "$ip" ]; then printf '%s' "$ip"; return 0; fi
  ip=$(curl -fsS --max-time 5 -4 https://ifconfig.me 2>/dev/null || true)
  [ -n "$ip" ] && printf '%s' "$ip"
}

if grep -q '<VM_PUBLIC_IP>' .env; then
  log "BETTER_AUTH_URL not set — detecting the VM's public IP…"
  PUB_IP=$(detect_public_ip || true)
  # Format-check before writing: a captive portal / proxy error page from the
  # fallback probe must not end up inside BETTER_AUTH_URL.
  if printf '%s' "${PUB_IP:-}" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    sed_i "s|<VM_PUBLIC_IP>|${PUB_IP}|" .env
    ok "BETTER_AUTH_URL=http://${PUB_IP} (IP-only mode)"
  else
    die "could not detect a valid public IPv4 address — edit ./.env and set BETTER_AUTH_URL, then re-run"
  fi
fi

BAU=$(env_get .env BETTER_AUTH_URL "")
# Domain-mode consistency: with SITE_ADDRESS set, Caddy serves ONLY that vhost
# over TLS — BETTER_AUTH_URL must be exactly https://<SITE_ADDRESS>. This is
# fatal (not a warning): proceeding would deploy a green-looking stack whose
# sign-in is broken on the real domain, and the http:// branch below would
# additionally disable Secure cookies for what is actually an HTTPS site.
SITE=$(env_get .env SITE_ADDRESS "")
if [ -n "$SITE" ] && [ "$BAU" != "https://$SITE" ]; then
  die "SITE_ADDRESS=$SITE but BETTER_AUTH_URL=$BAU — domain mode requires BETTER_AUTH_URL=https://$SITE.
  Fix ./.env (either set BETTER_AUTH_URL=https://$SITE, or unset SITE_ADDRESS
  for IP-only mode) and re-run."
fi
# Custom-cert consistency: the mode is enabled by certs/tls.caddy (written by
# ./generate-certs.sh and imported by the Caddyfile). When enabled it requires
# domain mode (the cert names a hostname) and the cert/key files — resolved
# with the same defaults as docker-compose.yml — must exist under ./certs, the
# only host path mounted into the caddy container (at /certs, read-only).
# Fatal here: a bad combo would otherwise only surface as a caddy crash-loop
# after the stack is up.
TLS_CERT=$(env_get .env TLS_CERT_PATH "")
TLS_KEY=$(env_get .env TLS_KEY_PATH "")
if { [ -n "$TLS_CERT" ] || [ -n "$TLS_KEY" ]; } && [ ! -f certs/tls.caddy ]; then
  die "TLS_CERT_PATH/TLS_KEY_PATH are set in ./.env but ./certs/tls.caddy does not
  exist — custom-cert mode is enabled by that snippet. Run ./generate-certs.sh
  (see certs/README.md), or unset the vars, and re-run."
fi
if [ -f certs/tls.caddy ]; then
  [ -n "$SITE" ] || die "./certs/tls.caddy exists but SITE_ADDRESS is not set — custom-cert mode
  needs SITE_ADDRESS set to the certificate's hostname (and
  BETTER_AUTH_URL=https://<SITE_ADDRESS>). Fix ./.env, or delete
  ./certs/tls.caddy for IP-only mode, and re-run."
  # Same defaults as the caddy service environment in docker-compose.yml.
  TLS_CERT=${TLS_CERT:-/certs/fullchain.crt}
  TLS_KEY=${TLS_KEY:-/certs/server.key}
  for tls_path in "$TLS_CERT" "$TLS_KEY"; do
    case "$tls_path" in
      /certs/*) ;;
      *) die "$tls_path — TLS_CERT_PATH/TLS_KEY_PATH must be container paths under
  /certs/ (the ./certs bind mount), e.g. /certs/fullchain.crt." ;;
    esac
    tls_host_file="certs/${tls_path#/certs/}"
    [ -f "$tls_host_file" ] || die "custom-cert mode needs $tls_path but ./$tls_host_file does not exist —
  run ./generate-certs.sh (see certs/README.md) and re-run."
  done
  ok "custom-cert mode: $TLS_CERT + $TLS_KEY (files present in ./certs)"
fi
case "$BAU" in
  http://*)
    # IP-only / plain-HTTP mode: browsers refuse Secure cookies over http://,
    # so sign-in silently loops unless the Secure force is disabled.
    if grep -Eq '^BETTER_AUTH_COOKIE_SECURE=false' .env.app; then
      ok "BETTER_AUTH_COOKIE_SECURE=false already set (required for http:// mode)"
    elif grep -Eq '^# *BETTER_AUTH_COOKIE_SECURE=false' .env.app; then
      sed_i 's|^# *BETTER_AUTH_COOKIE_SECURE=false|BETTER_AUTH_COOKIE_SECURE=false|' .env.app
      ok "enabled BETTER_AUTH_COOKIE_SECURE=false in ./.env.app (required for http:// mode)"
    else
      printf '\nBETTER_AUTH_COOKIE_SECURE=false\n' >> .env.app
      ok "appended BETTER_AUTH_COOKIE_SECURE=false to ./.env.app (required for http:// mode)"
    fi
    ;;
  https://*)
    # Bidirectional convergence: a BETTER_AUTH_COOKIE_SECURE=false left over
    # from an earlier IP-only phase would ship session cookies WITHOUT the
    # Secure attribute on the production HTTPS site — re-comment it.
    if grep -Eq '^BETTER_AUTH_COOKIE_SECURE=false' .env.app; then
      sed_i 's|^BETTER_AUTH_COOKIE_SECURE=false|# BETTER_AUTH_COOKIE_SECURE=false|' .env.app
      ok "re-enabled Secure cookies: commented out BETTER_AUTH_COOKIE_SECURE=false in ./.env.app (https mode)"
    else
      ok "https mode — Secure cookies stay on"
    fi
    ;;
  *) die "BETTER_AUTH_URL in ./.env must start with http:// or https:// (got: '$BAU')" ;;
esac

has_llm_key=false
for k in OPENAI_API_KEY ANTHROPIC_API_KEY GOOGLE_GENERATIVE_AI_API_KEY OPENROUTER_API_KEY GROQ_API_KEY XAI_API_KEY AZURE_OPENAI_API_KEY; do
  [ -n "$(env_get .env.app "$k" "")" ] && { has_llm_key=true; break; }
done
if $has_llm_key; then
  ok "LLM provider key present in ./.env.app"
else
  warn "NO LLM provider key set in ./.env.app — the app will start but chat is unusable."
  warn "Edit ./.env.app (e.g. ANTHROPIC_API_KEY=…) then: ./compose.sh up -d app"
fi

# ── 4b. Locate the versioned SQL artifacts (sourceless provisioning) ─────────
# The database is provisioned from pre-generated static SQL — no source, no
# drizzle-kit, no git access. Resolve and validate the artifact set up front.
hdr "Database artifacts"
assert_version_alignment   # DB_VERSION must match a semver APP_IMAGE tag if both set
DB_DIR=$(db_dir) || die "no SQL artifacts found under ./db.
  Expected ./db/<version>/{schema.sql,grants.sql,seed.sql} matching your
  APP_IMAGE tag. Set DB_VERSION in ./.env, or ensure the db/<version> folder
  ships in this package (published per release by the app repo's CI)."
for f in schema.sql grants.sql seed.sql; do
  [ -s "$DB_DIR/$f" ] || die "missing or empty: $DB_DIR/$f"
done
ok "using SQL artifacts in ./$DB_DIR"

# ── 5. Pull the application + helper images ──────────────────────────────────
hdr "Pull images"
APP_IMAGE=$(env_get .env APP_IMAGE "")
NXPI_HASH_IMAGE=$(env_get .env NXPI_HASH_IMAGE "$NXPI_HASH_DEFAULT")
log "pulling ${APP_IMAGE:-<unset>} + infrastructure images…"
if ! compose pull; then
  die "image pull failed. If the registry package is private, log in first:
    echo \$GHCR_TOKEN | $DOCKER login ghcr.io -u <github-user> --password-stdin
  (PAT with read:packages), then re-run ./install.sh"
fi
# The public admin-password hash helper (no app source). Non-fatal if the pull
# fails now — it is only needed at the seed step, with a clear message there.
$DOCKER pull "$NXPI_HASH_IMAGE" >/dev/null 2>&1 && ok "pulled $NXPI_HASH_IMAGE" \
  || warn "could not pre-pull $NXPI_HASH_IMAGE (will retry at the seed step)"
ok "images pulled"

# ── 6. Data tier ─────────────────────────────────────────────────────────────
hdr "Data tier"
compose up -d postgres redis
wait_healthy postgres 120 || die "Postgres did not become healthy"
wait_healthy redis 60     || die "Redis did not become healthy"

# ── 7. Database provisioning (sourceless, idempotency fork) ──────────────────
hdr "Database provisioning"
GEN_ADMIN_PW=""   # set when we generate the admin password (printed once below)

DB_VER=$(basename "$DB_DIR")

# apply_seed — (re)create the app role + grants, set its password, compute the
# admin hash, and apply seed.sql ATOMICALLY. Shared by the fresh path and the
# "finish an interrupted provision" path, so both are idempotent:
#   • grants.sql is idempotent (CREATE ROLE guarded, grants re-appliable) and
#     is applied here so the neo_gen role exists even if a prior run died
#     between schema.sql and grants.sql.
#   • seed.sql is applied in a SINGLE TRANSACTION (-1): any failure rolls back
#     ALL inserts, so the DB returns to schema-only and a re-run seeds cleanly
#     (no primary-key collisions from a half-applied seed).
apply_seed() {
  local app_pw app_pw_esc admin_email admin_pw hash
  log "applying grants.sql (least-privilege role; idempotent)…"
  psql_admin < "$DB_DIR/grants.sql" || die "grants.sql failed to apply"

  # The app connects as neo_gen over TCP — set its password from the secret.
  # SQL-escape it (double single-quotes) and pipe the whole statement on STDIN —
  # never via `psql -v`/argv, which `docker compose exec` exposes to host `ps`.
  app_pw=$(neo_gen_password)
  [ -n "$app_pw" ] || die "could not read the app-role password from secrets/postgres_url"
  app_pw_esc=${app_pw//\'/\'\'}
  printf "ALTER ROLE neo_gen PASSWORD '%s';\n" "$app_pw_esc" | psql_admin >/dev/null \
    || die "failed to set the neo_gen role password"

  admin_email=$(env_get .env SUPER_ADMIN_EMAIL "admin@example.com")
  admin_pw=$(env_get .env SUPER_ADMIN_PASSWORD "")
  if [ -z "$admin_pw" ]; then
    admin_pw=$(rand_hex 16)   # strong, no special chars; printed immediately below
    GEN_ADMIN_PW="$admin_pw"
  fi
  log "computing the admin password hash (nxpi-hash helper)…"
  hash=$(admin_hash "$admin_pw") \
    || die "could not compute the admin hash. Ensure NXPI_HASH_IMAGE is pullable:
    $DOCKER pull $(env_get .env NXPI_HASH_IMAGE "$NXPI_HASH_DEFAULT")"
  [ -n "$hash" ] || die "the nxpi-hash helper returned an empty hash"

  log "applying seed.sql (org + RBAC + settings + nav + tools + admin)…"
  psql_admin -1 -v admin_email="$admin_email" -v admin_password_hash="$hash" < "$DB_DIR/seed.sql" \
    || die "seed.sql failed to apply — it was rolled back (atomic); fix the issue and re-run ./install.sh"

  # Print the generated password NOW — before the health gate, which can abort.
  # Losing it would strand the admin account (a re-run seeds nothing).
  if [ -n "$GEN_ADMIN_PW" ]; then
    printf '\n'
    warn "SUPER-ADMIN PASSWORD (generated, shown ONCE — SAVE IT NOW):"
    warn "    ${admin_email} / ${GEN_ADMIN_PW}"
    printf '\n'
  fi
}

# FAIL CLOSED: an empty/non-numeric count (transient exec/psql failure) aborts
# rather than mis-classifying a populated production DB as "fresh".
TABLES=$(table_count)
assert_numeric "$TABLES" "the table count"

if [ "$TABLES" = "0" ]; then
  log "fresh database — provisioning from static SQL (no source, no git)…"
  log "applying schema.sql (DDL)…"
  psql_admin < "$DB_DIR/schema.sql" || die "schema.sql failed to apply — start fresh with: $DOCKER compose down -v"
  apply_seed   # grants + role password + atomic seed
  # schema.sql already embeds every change up to $DB_VER — stamp those migrations
  # as applied so a later ./update.sh does not re-apply an already-present diff.
  stamp_migrations_through "$DB_VER"
  # A surviving redis volume (secrets are keep-if-present, so it stays readable)
  # holds cache/queue state from the PREVIOUS database generation — and the
  # seed's deterministic UUIDs make stale entries collide with the new rows.
  flush_redis
  ok "database provisioned from ./$DB_DIR"
else
  # Completion sentinel: schema present but ZERO users ⇒ a prior seed step did
  # not finish. user_count prints "-1" when the "user" TABLE itself is missing
  # (schema apply interrupted even earlier — an unrecoverable partial state).
  USERS=$(user_count)
  if [ "$USERS" = "-1" ]; then
    die "the schema is PARTIAL ($TABLES tables but no \"user\" table) — a prior
  provisioning was interrupted mid-apply and cannot be safely resumed.
  Start fresh (DESTROYS DATA): $DOCKER compose down -v && ./install.sh"
  fi
  assert_numeric "$USERS" "the user count"
  if [ "$USERS" = "0" ]; then
    warn "schema present ($TABLES tables) but no users — finishing the interrupted seed…"
    apply_seed   # re-applies grants (idempotent) + atomic seed
    stamp_migrations_through "$DB_VER"
    flush_redis  # same surviving-redis hazard as the fresh path
    ok "database seed completed"
  else
    # Initialize the marker for an adopted DB (or no-op for a this-flow one).
    reconcile_marker "$DB_VER"
    # If migrations remain pending, the database is BEHIND the target image —
    # install.sh provisions/converges but does NOT upgrade schemas. Refuse to
    # roll a newer image over an un-migrated schema; send the operator to
    # ./update.sh (which applies the migrations and rolls with auto-rollback).
    if has_pending_migration; then
      die "the database is at an OLDER release than APP_IMAGE ($DB_VER) — install.sh
  does not upgrade schemas. Run ./update.sh to apply the pending migration(s) and
  roll the app safely. (Adopting an external DB? First set ADOPT_SCHEMA_VERSION
  to its current release so already-present migrations are not re-applied.)"
    fi
    log "database already provisioned ($TABLES tables, $USERS users) — nothing to do."
    log "(to move to a newer release, use ./update.sh)"
  fi
fi

# ── 8. Application + ingress ─────────────────────────────────────────────────
hdr "Application"
# Soft port check: if the ingress port is already bound and it is not our own
# Caddy (fresh install), the `up` below will fail — say why up front.
HTTP_PORT=$(env_get .env CADDY_HTTP_PORT 80)
if [ -z "$(compose ps -q caddy 2>/dev/null)" ] && command -v ss >/dev/null 2>&1; then
  # Capture then match (no `grep -q` piped from ss/awk): grep -q exits early and
  # would SIGPIPE the upstream on a busy host, and pipefail would then suppress
  # the warning exactly when the port IS bound.
  LISTENERS=$(ss -ltn 2>/dev/null | awk '{print $4}' || true)
  if grep -qE "[:.]${HTTP_PORT}\$" <<<"$LISTENERS"; then   # here-string: no SIGPIPE
    warn "port ${HTTP_PORT} is already in use by another process — Caddy will fail to bind."
    warn "Stop the other service, or set CADDY_HTTP_PORT/CADDY_HTTPS_PORT in ./.env."
  fi
fi
compose up -d
health_gate 300 || die "the app did not pass the health gate — inspect: $DOCKER compose logs app caddy"

# ── 9. Summary ───────────────────────────────────────────────────────────────
hdr "Deployment complete"
ADMIN_EMAIL=$(env_get .env SUPER_ADMIN_EMAIL "admin@example.com")
ADMIN_PW=$(env_get .env SUPER_ADMIN_PASSWORD "")
printf '\n'
ok  "URL:          ${BAU}"
ok  "Image:        ${APP_IMAGE}"
ok  "Super admin:  ${ADMIN_EMAIL}"
if [ -n "$GEN_ADMIN_PW" ]; then
  warn "Password:     ${GEN_ADMIN_PW}"
  warn "              ^ GENERATED this run — SAVE IT NOW (shown only here), then"
  warn "                change it after first login. (Set SUPER_ADMIN_PASSWORD in"
  warn "                ./.env to choose your own before a fresh install.)"
elif [ -n "$ADMIN_PW" ]; then
  log "Password:     (as configured in ./.env)"
else
  log "Password:     (unchanged — database was already provisioned)"
fi
printf '\n'
log "Useful commands (run from this directory — ./compose.sh honors the"
log "rollback pin after a failed update; raw 'docker compose' does not):"
log "  ./compose.sh ps                         # stack status"
log "  ./compose.sh logs -f app                # app logs"
log "  ./update.sh                             # pull latest image + schema sync"
log "  ./migrate.sh                            # schema-only migration (data preserved)"
log "  ./backup.sh                             # database (+uploads) backup"
log "  ./restore.sh --yes <dump>               # restore a backup"
