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

# ── redis_flush_one(): the per-service flush the two tiers share ─────────────
# Since the queue/cache split there are TWO redis servers with opposite
# eviction policies. The flush must target the service it was ASKED for, and
# must skip a service that is not running (redis-cache is optional, and a
# warning on every install would be noise). `compose` is stubbed to RECORD its
# argv, because the real function sends compose output to /dev/null.
ARGV_LOG="$WORK/compose-argv.log"
: > "$ARGV_LOG"
compose() {
  printf '%s\n' "$*" >> "$ARGV_LOG"
  # `ps -q` must report a container id or the caller treats the service as down.
  case "$1 $2" in "ps -q") printf 'deadbeefc0de\n' ;; esac
  return 0
}

redis_flush_one redis-cache >/dev/null 2>&1
case "$(cat "$ARGV_LOG")" in
  *"exec -T redis-cache "*) FLUSH_TARGET=yes ;;
  *)                        FLUSH_TARGET=no ;;
esac
t "redis_flush_one targets the service it was given" "yes" "$FLUSH_TARGET"
case "$(cat "$ARGV_LOG")" in
  *FLUSHALL*) FLUSH_CMD=yes ;;
  *)          FLUSH_CMD=no ;;
esac
t "redis_flush_one still issues FLUSHALL" "yes" "$FLUSH_CMD"

# A service that is not running must be skipped, not warned about.
compose() { printf '%s\n' "$*" >> "$ARGV_LOG"; return 0; }   # ps -q → empty
: > "$ARGV_LOG"
redis_flush_one redis-cache >/dev/null 2>&1
case "$(cat "$ARGV_LOG")" in
  *FLUSHALL*) SKIPPED=no ;;
  *)          SKIPPED=yes ;;
esac
t "redis_flush_one skips a service that is not running" "yes" "$SKIPPED"

t "REDIS_SERVICES lists the queue first, then the cache" \
  "redis redis-cache" "${REDIS_SERVICES:-UNSET}"
unset -f compose

# ── Data placement: mount + fstab deciders (fixtures only, no real disks) ────
# Nothing in this package validated a mount, a filesystem or a volume's device
# before. These are the pure halves of prepare-disks.sh's preflight, so the
# checks that gate a data-tier start are themselves testable.

# EXISTENCE FIRST. Without this the negative cases below pass vacuously: an
# undefined function also exits non-zero, so `fn ... && echo yes || echo no`
# prints "no" whether the decider said false or never ran at all.
for fn in fstab_has_mount mount_ok has_free_kb parse_kb_avail; do
  t "$fn is defined" "function" "$(type -t "$fn" 2>/dev/null || echo MISSING)"
done

# fstab_has_mount: a COMMENTED line must not count as configured, or a VM that
# boots without the disk looks correctly configured right up until it reboots.
FSTAB_OK=$'UUID=abc /srv/pgdata ext4 defaults,noatime,nofail 0 2\n'
FSTAB_COMMENTED=$'# UUID=abc /srv/pgdata ext4 defaults 0 2\n'
t "fstab_has_mount finds a real entry"        "yes" "$(fstab_has_mount "$FSTAB_OK" /srv/pgdata && echo yes || echo no)"
t "fstab_has_mount ignores a commented entry" "no"  "$(fstab_has_mount "$FSTAB_COMMENTED" /srv/pgdata && echo yes || echo no)"
t "fstab_has_mount does not match a prefix"   "no"  "$(fstab_has_mount "$FSTAB_OK" /srv/pg && echo yes || echo no)"

# mount_ok: empty input means "not a mount at all"; a read-only mount must fail
# too, since Postgres cannot start on one.
t "mount_ok accepts a rw mount" "yes" \
  "$(mount_ok '/srv/pgdata /dev/sdc ext4 rw,noatime' && echo yes || echo no)"
t "mount_ok rejects a ro mount" "no" \
  "$(mount_ok '/srv/pgdata /dev/sdc ext4 ro,noatime' && echo yes || echo no)"
t "mount_ok rejects empty input (not mounted)" "no" \
  "$(mount_ok '' && echo yes || echo no)"

# has_free_kb: fail CLOSED on unparseable input, mirroring assert_numeric.
t "has_free_kb passes when there is room"   "yes" "$(has_free_kb 100000 50000 && echo yes || echo no)"
t "has_free_kb fails when there is not"     "no"  "$(has_free_kb 10000 50000 && echo yes || echo no)"
t "has_free_kb fails closed on garbage"     "no"  "$(has_free_kb "" 50000 && echo yes || echo no)"

# parse_kb_avail: lifted out of update.sh's inline awk so it can be asserted.
DF_OUT=$'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/sdc 103080888 1234 97612345 2% /srv/pgdata'
t "parse_kb_avail reads the Available column" "97612345" "$(parse_kb_avail "$DF_OUT")"

# ── compose_volume_device(): read a volume's declared device from the FILE ────
# The verdict compares what the compose file DECLARES against what the volume
# actually has, so the file side has to be readable without docker.
t "compose_volume_device is defined" "function" "$(type -t compose_volume_device 2>/dev/null || echo MISSING)"
cat > cvd.yml <<'YML'
volumes:
  postgres-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/pgdata/data
  redis-data:
  uploads-data:
    driver: local
    driver_opts:
      device: /srv/other/data
YML
t "device of a pinned volume"          "/srv/pgdata/data" "$(compose_volume_device cvd.yml postgres-data)"
t "device of an unpinned volume"       ""                 "$(compose_volume_device cvd.yml redis-data)"
t "device of a volume that is absent"  ""                 "$(compose_volume_device cvd.yml nope)"
t "does not leak the NEXT volume's device" "/srv/other/data" "$(compose_volume_device cvd.yml uploads-data)"

# ── placement_verdict(): fresh vs adopt vs mismatch ──────────────────────────
# install.sh detected an existing deployment BY VOLUME NAME only — it never
# inspected Mountpoint, Driver or Options. Two ways that bites:
#   • on a REBUILT VM the volume does not exist yet but the DISK carries PGDATA,
#     so the guard reports "fresh", regenerates better_auth_secret, and every
#     stored integration credential becomes undecryptable — permanently;
#   • if a volume's declared device changes, Docker REFUSES to re-point it, so
#     converging silently does nothing useful.
t "placement_verdict is defined" "function" "$(type -t placement_verdict 2>/dev/null || echo MISSING)"

t "no volume, no data on the disk = fresh"        "fresh"    "$(placement_verdict no  /srv/pgdata/data '')"
t "volume pinned where the file says = adopt"     "adopt"    "$(placement_verdict yes /srv/pgdata/data /srv/pgdata/data)"
t "unpinned volume but the file pins = mismatch"  "mismatch" "$(placement_verdict yes /srv/pgdata/data '')"
t "pinned volume but the file does not = mismatch" "mismatch" "$(placement_verdict yes '' /srv/pgdata/data)"
t "pinned somewhere else entirely = mismatch"     "mismatch" "$(placement_verdict yes /srv/pgdata/data /var/lib/docker/volumes/x/_data)"
t "no volume but the DISK already holds PGDATA = adopt" "adopt" "$(placement_verdict no /srv/pgdata/data '' has-pgdata)"
t "neither volume nor device declared = fresh"    "fresh"    "$(placement_verdict no '' '')"

# ── prune_keeping(): retention that cannot delete your last backup ───────────
# `find -mtime` alone will delete the LAST dump after a quiet month — age is not
# a retention policy. This decides WHICH candidates may go, given the newest N
# that must survive regardless of age.
t "prune_keeping is defined" "function" "$(type -t prune_keeping 2>/dev/null || echo MISSING)"

CANDIDATES=$'backups/neogen-3.dump\nbackups/neogen-2.dump\nbackups/neogen-1.dump'
KEEP=$'backups/neogen-3.dump\nbackups/neogen-2.dump'
t "keeps the protected newest, prunes the rest" "backups/neogen-1.dump" \
  "$(prune_keeping "$CANDIDATES" "$KEEP")"
t "prunes nothing when every candidate is protected" "" \
  "$(prune_keeping "$KEEP" "$KEEP")"
t "prunes nothing when there are no candidates" "" \
  "$(prune_keeping "" "$KEEP")"
# The case that matters: everything is old, but the keep-list still saves them.
t "an all-old set still keeps the protected ones" "backups/neogen-1.dump" \
  "$(prune_keeping "$CANDIDATES" "$KEEP")"
# A substring name must not be protected by a longer one (neogen-1 vs neogen-11).
t "protection is exact, not substring" "backups/neogen-1.dump" \
  "$(prune_keeping $'backups/neogen-1.dump' $'backups/neogen-11.dump')"

# ── pgbackrest helpers ───────────────────────────────────────────────────────
# PITR is only real once a RESTORE has been rehearsed, so the guardrails here
# are about refusing to look ready when it is not.
for fn in pgbackrest_ready pgbackrest_argv; do
  t "$fn is defined" "function" "$(type -t "$fn" 2>/dev/null || echo MISSING)"
done

# pgbackrest_ready IMAGE ARCHIVE_MODE — both must be right, and the failure
# modes differ: the stock image has no binary (archive_command fails and WAL
# piles up until the disk fills), archive_mode=off means nothing is archived at
# all (backups exist but PITR between them does not).
t "stock image + archiving on = not ready" "no" \
  "$(pgbackrest_ready 'pgvector/pgvector:pg17' on && echo yes || echo no)"
t "pitr image + archiving on = ready" "yes" \
  "$(pgbackrest_ready 'ghcr.io/x/nxpi-postgres:1.0.0' on && echo yes || echo no)"
t "pitr image + archiving off = not ready" "no" \
  "$(pgbackrest_ready 'ghcr.io/x/nxpi-postgres:1.0.0' off && echo yes || echo no)"
t "empty image = not ready (fail closed)" "no" \
  "$(pgbackrest_ready '' on && echo yes || echo no)"

# pgbackrest_argv STANZA SUBCOMMAND… — the stanza must always be passed, or
# pgbackrest operates on whatever the config happens to name first.
t "argv always carries the stanza" "--stanza=neogen backup --type=full" \
  "$(pgbackrest_argv neogen backup --type=full)"
t "argv with no extra args still names the stanza" "--stanza=neogen info" \
  "$(pgbackrest_argv neogen info)"

# ── volume_device(): Docker's "<no value>" must normalize to EMPTY ───────────
# The bug this guards: `--format '{{.Options.device}}'` renders an unpinned
# volume's absent Options map as the literal string "<no value>". Compared
# against a compose file that declares no device, placement_verdict saw
# "" != "<no value>" and returned `mismatch` — so install.sh refused to
# converge on EVERY deployment that had not opted into the pinned layout.
# $DOCKER is a plain variable, so a shell function substitutes for the binary.
t "volume_device is defined" "function" "$(type -t volume_device 2>/dev/null || echo MISSING)"

fake_docker_noopts() { printf '\n'; }                       # {{if .Options}} false → empty
fake_docker_literal() { printf '<no value>\n'; }            # a docker that renders it anyway
fake_docker_pinned() { printf '/srv/pgdata/data\n'; }
fake_docker_fails()  { return 1; }

DOCKER=fake_docker_noopts
t "unpinned volume yields empty"            "" "$(volume_device anything)"
DOCKER=fake_docker_literal
t "a literal <no value> normalizes to empty" "" "$(volume_device anything)"
DOCKER=fake_docker_pinned
t "a pinned volume still yields its device" "/srv/pgdata/data" "$(volume_device anything)"
DOCKER=fake_docker_fails
t "a failed inspect yields empty, not an error" "" "$(volume_device anything)"

# The verdict this all feeds, end to end: an unpinned volume against an
# unpinned compose file is `adopt` — an ordinary existing deployment.
DOCKER=fake_docker_noopts
t "unpinned volume + unpinned file = adopt" "adopt" \
  "$(placement_verdict yes "" "$(volume_device anything)")"
# …but an unpinned volume against a file that DOES pin must still refuse.
t "unpinned volume + pinned file = mismatch" "mismatch" \
  "$(placement_verdict yes /srv/pgdata/data "$(volume_device anything)")"
unset -f fake_docker_noopts fake_docker_literal fake_docker_pinned fake_docker_fails

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
