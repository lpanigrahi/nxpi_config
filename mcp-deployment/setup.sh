#!/usr/bin/env bash
# =============================================================================
# setup.sh — single-command, idempotent setup for the standalone SharePoint
# MCP stack (fully isolated from the NXPi app stack next door).
#
#   ./setup.sh              # env file + IP detection + pull + up + prints URL
#   MCP_IP=10.0.0.4 ./setup.sh   # override the auto-detected private IP
#
# NEW DESIGN: ONE container serves all eleven sites (docker-compose.single.yml
# + envs/mcp-all.env). The old eleven-container stack (docker-compose.yml) is
# retired — this script brings it DOWN if it is still running, so the VM
# converges to exactly one mcp-sharepoint container on port 8000.
#
# What it does (each step skips itself when already done):
#   1. creates ./.env from .env.example (never overwrites), chmod 600
#   2. detects the VM's PRIVATE IP and writes MCP_ALLOWED_HOSTS into ./.env
#      (the app's requests get HTTP 421 without it)
#   3. retires the legacy eleven-container stack if it is running
#   4. pulls ghcr.io/negentrophi/ms-sharepoint-mcp and starts the container
#      (never builds — pin a tag via MCP_IMAGE_TAG in ./.env)
#   5. prints the ONE URL to paste into the app's MCP Configuration UI
#
# The app stack (azure-deployment/) is NEVER touched by this script.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

# The consolidated stack. Every compose call names the file explicitly so the
# legacy docker-compose.yml (kept for rollback) is never picked up by default.
COMPOSE_FILE="docker-compose.single.yml"

# ── Logging (same conventions as azure-deployment/lib.sh) ────────────────────
if [ -t 1 ]; then
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YLW=$'\033[33m'; C_BLU=$'\033[34m'; C_RST=$'\033[0m'
else
  C_RED=""; C_GRN=""; C_YLW=""; C_BLU=""; C_RST=""
fi
log()  { printf '%s\n' "${C_BLU}▸${C_RST} $*"; }
ok()   { printf '%s\n' "${C_GRN}✔${C_RST} $*"; }
warn() { printf '%s\n' "${C_YLW}⚠ $*${C_RST}" >&2; }
die()  { printf '%s\n' "${C_RED}✖ $*${C_RST}" >&2; exit 1; }

# GNU/BSD-portable in-place sed (Ubuntu = GNU; BSD only during local testing)
sed_i() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

# ── 1. Env file ──────────────────────────────────────────────────────────────
[ -f .env ] || { cp .env.example .env; ok "created ./.env (from .env.example)"; }
chmod 600 .env
ok "./.env permissions set (600)"

# ── 2. Private IP → MCP_ALLOWED_HOSTS ────────────────────────────────────────
# The app container reaches host-published ports via the VM's PRIVATE IP (the
# Azure public IP is fabric NAT and does not reliably hairpin from inside the
# VM). `hostname -I` is Ubuntu; the ipconfig fallback covers macOS smoke tests.
IP="${MCP_IP:-}"
if [ -z "$IP" ]; then
  IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
fi
if [ -z "$IP" ] && command -v ipconfig >/dev/null 2>&1; then
  IP=$(ipconfig getifaddr en0 2>/dev/null || true)
fi
printf '%s' "$IP" | grep -Eq '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' \
  || die "could not detect a valid private IPv4 address (got: '${IP:-}') —
  re-run with an explicit override:  MCP_IP=<vm-private-ip> ./setup.sh"

ALLOWED="${IP}:*,localhost:*,127.0.0.1:*"
if grep -q '^MCP_ALLOWED_HOSTS=' .env; then
  sed_i "s|^MCP_ALLOWED_HOSTS=.*|MCP_ALLOWED_HOSTS=${ALLOWED}|" .env
else
  printf 'MCP_ALLOWED_HOSTS=%s\n' "$ALLOWED" >> .env
fi
ok "MCP_ALLOWED_HOSTS=${ALLOWED}"

# ── 2b. Site registry ────────────────────────────────────────────────────────
# compose refuses to start the service if a listed env_file is missing.
[ -f envs/mcp-all.env ] || die "envs/mcp-all.env is missing — restore it (it is tracked in git) before starting the stack"
ok "envs/mcp-all.env present (all eleven sites, one container)"

# ── 3. Docker + retire the legacy eleven-container stack ─────────────────────
# docker | sudo docker (fresh installs: the docker group needs a re-login)
if docker info >/dev/null 2>&1; then DOCKER="docker"
elif sudo -n true 2>/dev/null && sudo docker info >/dev/null 2>&1; then
  DOCKER="sudo docker"
  warn "docker requires sudo in this shell (docker group not active yet — re-login to fix)"
else
  die "cannot talk to the Docker daemon (is Docker installed and running?)"
fi

# The old stack ran eleven mcp-* containers under project `sharepoint-mcp`.
# One process now carries the whole load, and the concurrency gates assume it
# is alone (see docker-compose.single.yml) — so the two must not run together.
LEGACY=$($DOCKER ps -aq --filter "label=com.docker.compose.project=sharepoint-mcp" | wc -l | tr -d ' ')
if [ "$LEGACY" -gt 0 ]; then
  log "retiring the legacy eleven-container stack (${LEGACY} containers)…"
  if [ -f docker-compose.yml ]; then
    $DOCKER compose -f docker-compose.yml down
  else
    $DOCKER ps -aq --filter "label=com.docker.compose.project=sharepoint-mcp" | xargs -r $DOCKER rm -f
  fi
  ok "legacy stack retired"
fi

# ── 4. Pull + start ──────────────────────────────────────────────────────────
log "pulling ghcr.io/negentrophi/ms-sharepoint-mcp…"
$DOCKER compose -f "$COMPOSE_FILE" pull || die "image pull failed. If the GHCR package is private, log in first:
    echo \$GHCR_TOKEN | $DOCKER login ghcr.io -u <github-user> --password-stdin
  (PAT with read:packages), then re-run ./setup.sh"
log "starting the container…"
$DOCKER compose -f "$COMPOSE_FILE" up -d
ok "stack is up (one container: mcp-sharepoint)"

# ── 5. Summary ───────────────────────────────────────────────────────────────
printf '\n'
MISSING=""
for key in TENANT_ID CLIENT_ID CLIENT_SECRET; do
  grep -Eq "^${key}=.+" .env || MISSING="${MISSING} ${key}"
done
if [ -n "$MISSING" ]; then
  warn "Graph credentials are NOT fully set (missing:${MISSING}) — the server"
  warn "is up but every tool call will fail. Edit ./.env, then"
  warn "restart:  $DOCKER compose -f $COMPOSE_FILE up -d"
  printf '\n'
fi
ok "MCP Configuration UI → register ONE server (it serves all eleven sites;"
ok "the model picks a department via the site_name argument):"
ok "    SharePoint"
ok "        { \"url\": \"http://${IP}:8000/mcp\" }"
printf '\n'
log "Verify:"
log "  $DOCKER compose -f $COMPOSE_FILE ps                          # healthy?"
log "  $DOCKER compose -f $COMPOSE_FILE logs mcp-sharepoint | grep -i auth"
log "  # list_available_sites should return all eleven site names"
printf '\n'
warn "Azure NSG: keep port 8000 CLOSED inbound (default-deny). In app mode the"
warn "endpoint is unauthenticated — the NSG and MCP_ALLOWED_HOSTS are the only"
warn "guards. (Delegated mode adds bearer-token auth; see .env.delegated.)"
