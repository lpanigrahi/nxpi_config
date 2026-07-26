#!/usr/bin/env bash
# =============================================================================
# setup.sh — single-command, idempotent setup for the standalone SharePoint
# MCP stack (fully isolated from the NXPi app stack next door).
#
#   ./setup.sh              # env file + IP detection + pull + up + prints URLs
#   MCP_IP=10.0.0.4 ./setup.sh   # override the auto-detected private IP
#
# What it does (each step skips itself when already done):
#   1. creates ./.env from .env.example (never overwrites), chmod 600
#   2. detects the VM's PRIVATE IP and writes MCP_ALLOWED_HOSTS into ./.env
#      (the app's requests get HTTP 421 without it)
#   3. pulls ghcr.io/lpanigrahi/ms-sharepoint-mcp and starts the stack
#      (never builds — pin a tag via MCP_IMAGE_TAG in ./.env)
#   4. prints the per-site URLs to paste into the app's MCP Configuration UI
#
# The app stack (azure-deployment/) is NEVER touched by this script.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

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

# ── 2b. Per-site env files ───────────────────────────────────────────────────
# compose refuses to start ANY service if one listed env_file is missing.
for site in rd manufacturing qa sales hr finance logistics gm ir scm nei; do
  [ -f "envs/mcp-${site}.env" ] || die "envs/mcp-${site}.env is missing — restore it (it is tracked in git) before starting the stack"
done
ok "all 11 envs/mcp-*.env files present"

# ── 3. Pull + start ──────────────────────────────────────────────────────────
# docker | sudo docker (fresh installs: the docker group needs a re-login)
if docker info >/dev/null 2>&1; then DOCKER="docker"
elif sudo -n true 2>/dev/null && sudo docker info >/dev/null 2>&1; then
  DOCKER="sudo docker"
  warn "docker requires sudo in this shell (docker group not active yet — re-login to fix)"
else
  die "cannot talk to the Docker daemon (is Docker installed and running?)"
fi

log "pulling ghcr.io/lpanigrahi/ms-sharepoint-mcp…"
$DOCKER compose pull || die "image pull failed. If the GHCR package is private, log in first:
    echo \$GHCR_TOKEN | $DOCKER login ghcr.io -u <github-user> --password-stdin
  (PAT with read:packages), then re-run ./setup.sh"
log "starting the stack…"
$DOCKER compose up -d
ok "stack is up"

# ── 4. Summary ───────────────────────────────────────────────────────────────
printf '\n'
MISSING=""
for key in TENANT_ID CLIENT_ID CLIENT_SECRET; do
  grep -Eq "^${key}=.+" .env || MISSING="${MISSING} ${key}"
done
if [ -n "$MISSING" ]; then
  warn "Graph credentials are NOT fully set (missing:${MISSING}) — the servers"
  warn "are up but every tool call will fail. Edit ./.env, then"
  warn "restart:  $DOCKER compose up -d"
  printf '\n'
fi
ok "MCP Configuration UI → add ONE server PER SITE:"
while IFS='|' read -r port site; do
  ok "    ${site}"
  ok "        { \"url\": \"http://${IP}:${port}/mcp\" }"
done <<EOF
8001|SharePoint R&D
8002|SharePoint Manufacturing
8003|SharePoint QA
8004|SharePoint Sales
8005|SharePoint HR
8006|SharePoint Finance
8007|SharePoint Logistics
8008|SharePoint GM
8009|SharePoint IR
8010|SharePoint SCM
8011|SharePoint NEI
EOF
printf '\n'
log "Verify:"
log "  $DOCKER compose ps                            # all 11 healthy?"
log "  $DOCKER compose logs mcp-hr | grep -i auth    # 'Authentication successful' (per site)"
printf '\n'
warn "Azure NSG: keep ports 8001-8011 CLOSED inbound (default-deny). The"
warn "endpoints are unauthenticated — the NSG and MCP_ALLOWED_HOSTS are the"
warn "only guards."
