#!/usr/bin/env bash
# =============================================================================
# lib-harness.sh — runtime assertions for the PURE helpers in ../lib.sh.
#
#   bash tests/lib-harness.sh          # run locally (any bash ≥ 3.2)
#
# Target-fidelity run (Ubuntu = the VM's platform, GNU coreutils, bash 5):
#   docker run --rm -v "$PWD":/pkg:ro ubuntu:24.04 \
#     bash /pkg/tests/lib-harness.sh /pkg/lib.sh
#
# No docker/psql helper is exercised — only env_get / ver_le / version
# resolution / migration-file selection / neo_gen_password decoding / the
# compose() override+pin file selection (via a stubbed $DOCKER). Everything
# runs inside a throwaway mktemp sandbox; the package tree is never touched.
# Exit 0 = all assertions pass; nonzero = at least one failure (printed).
# =============================================================================
set -uo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
LIB="${1:-$HERE/../lib.sh}"
[ -r "$LIB" ] || { echo "cannot read lib.sh at $LIB" >&2; exit 1; }
LIB=$(cd -- "$(dirname -- "$LIB")" && pwd)/$(basename -- "$LIB")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
: > .env   # PROJECT computation at source time reads ./.env
# shellcheck disable=SC1090
source "$LIB"

PASS=0; FAIL=0
t() { # t NAME EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then PASS=$((PASS+1));
  else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi
}

# ── env_get (Compose-dotenv semantics + documented deviations) ───────────────
cat > t1.env <<'EOF'
PLAIN=hello
TRAILWS=value
INLINE=x.com  # prod comment
HASH_UNQUOTED=abc#notcomment
QUOTED_HASH="p @ss #1"
SQUOTED='keep #this'
ESCQUOTE="p\"ss"
BACKSLASHES="a\b\c"
DOUBLEBS="a\\b"
LITNL="line\nend"
EMPTY=
DUPE=first
DUPE=second
EQCHAIN=postgres://u:p@h:5432/db?a=b
  LEADWS=indented
EOF
t "env_get plain"            "hello"          "$(env_get t1.env PLAIN)"
t "env_get trailing ws"      "value"          "$(env_get t1.env TRAILWS)"
t "env_get inline comment"   "x.com"          "$(env_get t1.env INLINE)"
t "env_get unquoted # glued" "abc#notcomment" "$(env_get t1.env HASH_UNQUOTED)"
t "env_get quoted keeps #"   "p @ss #1"       "$(env_get t1.env QUOTED_HASH)"
t "env_get single-quoted"    "keep #this"     "$(env_get t1.env SQUOTED)"
t "env_get escaped quote"    'p"ss'           "$(env_get t1.env ESCQUOTE)"
t "env_get lone backslashes" 'a\b\c'          "$(env_get t1.env BACKSLASHES)"
t "env_get double backslash" 'a\b'            "$(env_get t1.env DOUBLEBS)"
t "env_get \\n stays literal" 'line\nend'     "$(env_get t1.env LITNL)"
# DOCUMENTED deviation from Compose dotenv: explicit-empty returns the default.
t "env_get explicit-empty -> default (documented)" "defval" "$(env_get t1.env EMPTY defval)"
t "env_get missing -> default" "defval"       "$(env_get t1.env NOPE defval)"
t "env_get last wins"        "second"         "$(env_get t1.env DUPE)"
t "env_get value with ="     "postgres://u:p@h:5432/db?a=b" "$(env_get t1.env EQCHAIN)"
t "env_get leading-ws key missed(grep ^)" "defval" "$(env_get t1.env LEADWS defval)"

# ── ver_le ───────────────────────────────────────────────────────────────────
ver_le 1.2.0 1.3.0  && r=y || r=n; t "ver_le 1.2.0<=1.3.0" y "$r"
ver_le 1.3.0 1.3.0  && r=y || r=n; t "ver_le equal" y "$r"
ver_le 1.10.0 1.9.0 && r=y || r=n; t "ver_le 1.10.0<=1.9.0 is false" n "$r"
ver_le 1.9.0 1.10.0 && r=y || r=n; t "ver_le 1.9.0<=1.10.0" y "$r"

# ── is_exact_semver ──────────────────────────────────────────────────────────
is_exact_semver 1.9.0 && r=y || r=n;               t "semver 1.9.0" y "$r"
is_exact_semver 10.22.333 && r=y || r=n;           t "semver 10.22.333" y "$r"
is_exact_semver 1.2.0-main.80c736af && r=y || r=n; t "semver rejects -main.<sha>" n "$r"
is_exact_semver main && r=y || r=n;                t "semver rejects main" n "$r"
is_exact_semver sha-80c736a && r=y || r=n;         t "semver rejects sha-<short>" n "$r"
is_exact_semver latest && r=y || r=n;              t "semver rejects latest" n "$r"
is_exact_semver 1.2 && r=y || r=n;                 t "semver rejects 1.2" n "$r"
is_exact_semver 1.2.0.1 && r=y || r=n;             t "semver rejects 1.2.0.1" n "$r"
is_exact_semver "1..0" && r=y || r=n;              t "semver rejects 1..0" n "$r"
is_exact_semver "" && r=y || r=n;                  t "semver rejects empty" n "$r"

# ── version resolution ───────────────────────────────────────────────────────
mkdir -p db/1.2.0 db/1.3.0
echo 'DB_VERSION=1.3.0' > .env
t "db_target_version DB_VERSION" "1.3.0" "$(db_target_version)"
t "db_dir explicit"              "db/1.3.0" "$(db_dir)"
printf 'APP_IMAGE=ghcr.io/x/y:v1.2.0\n' > .env
t "db_target_version v-tag"      "1.2.0" "$(db_target_version)"
printf 'APP_IMAGE=ghcr.io/x/y:latest\n' > .env
t "db_target_version latest -> empty" "" "$(db_target_version)"
db_dir >/dev/null 2>&1 && r=y || r=n; t "db_dir latest + 2 folders fails" n "$r"
printf 'APP_IMAGE=ghcr.io/x/y@sha256:abc\n' > .env
t "db_target_version digest -> empty" "" "$(db_target_version)"
printf 'APP_IMAGE=reg.example:5000/x/y\n' > .env
t "db_target_version registry-port untagged -> empty" "" "$(db_target_version)"
# CI moving tags (main branch publishes <pkgver>-main.<sha>, main, sha-<short>):
# none identify a db/ package, so derivation must yield empty, and DB_VERSION
# must still resolve the folder when set alongside them.
printf 'APP_IMAGE=ghcr.io/x/y:1.2.0-main.80c736af\n' > .env
t "db_target_version <ver>-main.<sha> -> empty" "" "$(db_target_version)"
printf 'APP_IMAGE=ghcr.io/x/y:main\n' > .env
t "db_target_version main -> empty" "" "$(db_target_version)"
printf 'APP_IMAGE=ghcr.io/x/y:sha-80c736a\n' > .env
t "db_target_version sha-<short> -> empty" "" "$(db_target_version)"
printf 'APP_IMAGE=ghcr.io/x/y:main\n' > .env
db_dir >/dev/null 2>&1 && r=y || r=n; t "db_dir main-tag + 2 folders fails" n "$r"
printf 'APP_IMAGE=ghcr.io/x/y:1.2.0-main.80c736af\nDB_VERSION=1.3.0\n' > .env
t "db_dir suffixed tag + DB_VERSION resolves" "db/1.3.0" "$(db_dir)"
printf 'DB_VERSION=9.9.9\n' > .env
db_dir >/dev/null 2>&1 && r=y || r=n; t "db_dir explicit-missing-folder fails" n "$r"
rm -rf db/1.2.0
printf 'APP_IMAGE=ghcr.io/x/y:latest\n' > .env
t "db_dir lone-folder fallback" "db/1.3.0" "$(db_dir)"
t "resolved_db_version lone-folder" "1.3.0" "$(resolved_db_version)"
mkdir -p db/1.2.0

# ── assert_version_alignment (die in subshell) ───────────────────────────────
printf 'APP_IMAGE=ghcr.io/x/y:1.3.0\nDB_VERSION=1.2.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment mismatch dies" die "$r"
printf 'APP_IMAGE=ghcr.io/x/y:v1.3.0\nDB_VERSION=1.3.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment v-prefix matches" pass "$r"
printf 'APP_IMAGE=ghcr.io/x/y@sha256:abc\nDB_VERSION=1.2.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment digest skipped" pass "$r"
printf 'APP_IMAGE=ghcr.io/x/y:latest\nDB_VERSION=1.2.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment latest skipped" pass "$r"
printf 'APP_IMAGE=ghcr.io/x/y:1.2.0-main.80c736af\nDB_VERSION=1.9.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment <ver>-main.<sha> skipped" pass "$r"
printf 'APP_IMAGE=ghcr.io/x/y:main\nDB_VERSION=1.9.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment main skipped" pass "$r"
printf 'APP_IMAGE=ghcr.io/x/y:sha-80c736a\nDB_VERSION=1.9.0\n' > .env
( assert_version_alignment ) 2>/dev/null && r=pass || r=die; t "alignment sha-<short> skipped" pass "$r"

# ── migration_files_through (multi-version ordering + cap) ───────────────────
mkdir -p db/1.4.0 db/1.10.0
touch db/1.3.0/migrate-1.3.0.sql db/1.4.0/migrate-1.4.0.sql db/1.10.0/migrate-1.10.0.sql
t "migrations through 1.4.0 (capped, ordered)" \
  "db/1.3.0/migrate-1.3.0.sql
db/1.4.0/migrate-1.4.0.sql" \
  "$(migration_files_through 1.4.0)"
t "migrations through 1.10.0 semver order" \
  "db/1.3.0/migrate-1.3.0.sql
db/1.4.0/migrate-1.4.0.sql
db/1.10.0/migrate-1.10.0.sql" \
  "$(migration_files_through 1.10.0)"
# Hotfix layout: the ordering key is the FILENAME version, not the folder —
# db/1.3.0/migrate-1.2.5.sql must apply BEFORE db/1.2.9/migrate-1.2.9.sql.
mkdir -p db/1.2.9
touch db/1.3.0/migrate-1.2.5.sql db/1.2.9/migrate-1.2.9.sql
t "migrations hotfix folder!=file ordered by filename version" \
  "db/1.3.0/migrate-1.2.5.sql
db/1.2.9/migrate-1.2.9.sql
db/1.3.0/migrate-1.3.0.sql" \
  "$(migration_files_through 1.3.0)"
rm -rf db/1.2.9 db/1.3.0/migrate-1.2.5.sql

# ── neo_gen_password (extraction + percent-decode) ───────────────────────────
mkdir -p secrets
printf 'postgres://neo_gen:s3cretHEX@postgres:5432/neogen' > secrets/postgres_url
t "neo_gen_password plain" "s3cretHEX" "$(neo_gen_password)"
printf 'postgres://neo_gen:p%%40ss%%23w@postgres:5432/neogen' > secrets/postgres_url
t "neo_gen_password percent-decode" 'p@ss#w' "$(neo_gen_password)"

# ── APPLIED_DESTRUCTIVE contract ─────────────────────────────────────────────
# Top-level init: readable under set -u before apply_migrations ever runs.
t "APPLIED_DESTRUCTIVE initialized false" "false" "${APPLIED_DESTRUCTIVE}"

# ── compose(): rollback pin + override-file selection (stubbed \$DOCKER) ──────
DOCKER="echo"
t "compose() no pin = plain compose" "compose ps" "$(compose ps)"
touch .rollback-image.yml
t "compose() pin only" \
  "compose -f docker-compose.yml -f .rollback-image.yml ps" "$(compose ps)"
touch docker-compose.override.yaml
t "compose() pin + .yaml override honored" \
  "compose -f docker-compose.yml -f docker-compose.override.yaml -f .rollback-image.yml ps" "$(compose ps)"
touch docker-compose.override.yml
t "compose() .yml wins over .yaml (Compose discovery order)" \
  "compose -f docker-compose.yml -f docker-compose.override.yml -f .rollback-image.yml ps" "$(compose ps)"
rm -f .rollback-image.yml docker-compose.override.yml docker-compose.override.yaml

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
