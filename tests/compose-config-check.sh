#!/usr/bin/env bash
# =============================================================================
# compose-config-check.sh — does docker-compose.yml still render from the
# SHIPPED templates? Copies the compose file and its bind-mounted companions
# into a throwaway directory, materialises .env / .env.app from the examples
# and empty secret files, and runs `docker compose config`. Then asserts the
# privileged-pool wiring: POSTGRES_PRIVILEGED_URL_FILE renders EMPTY unless
# ./.env sets it (an empty *_FILE is skipped by secrets-entrypoint.sh).
#
#   bash tests/compose-config-check.sh
#
# Needs docker compose v2; no containers are started, nothing is pulled.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)
command -v docker >/dev/null || { echo "docker not found — skipping"; exit 0; }
docker compose version >/dev/null 2>&1 || { echo "docker compose v2 not found — skipping"; exit 0; }

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

cd "$WORK" || exit 1
for f in docker-compose.yml Caddyfile secrets-entrypoint.sh init.sql pgbackrest.conf; do cp "$PKG/$f" .; done
mkdir -p secrets certs
for s in postgres_password redis_password postgres_url postgres_privileged_url redis_url redis_cache_url better_auth_secret; do printf 'x\n' > "secrets/$s"; done
sed -e 's|^APP_IMAGE=.*|APP_IMAGE=ghcr.io/negentrophi/nxpi:sha-cb44bba|' \
    -e 's|^BETTER_AUTH_URL=.*|BETTER_AUTH_URL=http://127.0.0.1|' "$PKG/.env.example" > .env
cp "$PKG/.env.app.example" .env.app

OUT=$(docker compose config 2>&1); RC=$?
t "compose renders from the shipped templates" "0" "$RC"
[ "$RC" = "0" ] || printf '%s\n' "$OUT" | head -20

t "TRUSTED_PROXY_MODE reaches the app from .env.app" "yes" \
  "$(docker compose config 2>/dev/null | grep -qE '^\s+TRUSTED_PROXY_MODE: xff$' && echo yes || echo no)"
t "privileged *_FILE is EMPTY when .env does not set it" "yes" \
  "$(docker compose config 2>/dev/null | grep -qE '^\s+POSTGRES_PRIVILEGED_URL_FILE: ""$' && echo yes || echo no)"
t "privileged secret is mounted on app regardless" "yes" \
  "$(docker compose config 2>/dev/null | grep -qE 'source: postgres_privileged_url' && echo yes || echo no)"

printf 'POSTGRES_PRIVILEGED_URL_FILE=/run/secrets/postgres_privileged_url\n' >> .env
t "privileged *_FILE is set when .env opts in" "yes" \
  "$(docker compose config 2>/dev/null | grep -qE '^\s+POSTGRES_PRIVILEGED_URL_FILE: /run/secrets/postgres_privileged_url$' && echo yes || echo no)"

# Documented footgun (README, "Upgrading THIS PACKAGE"): `compose config` does
# NOT check that a file-secret exists — the failure lands at container CREATE,
# which is why install.sh must generate every secret before any `up`. If this
# ever flips, the README paragraph is stale — update both together.
rm secrets/postgres_privileged_url
OUT=$(docker compose config 2>&1); RC=$?
t "compose config still passes with a missing secret file (surfaces at create, per README)" "0" "$RC"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
