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

# A backup is a dump AND its uploads archive. backup.sh's keep-list once held
# only neogen-*.dump, so retention kept a database it could restore and deleted
# the uploads-*.tar.gz that belonged with it — restore.sh --uploads then had
# nothing to pair with the dump it was handed. The keep-list must carry both
# kinds; this asserts prune_keeping honours a mixed one.
PAIRED_CANDIDATES=$'backups/neogen-2.dump\nbackups/uploads-2.tar.gz\nbackups/neogen-1.dump\nbackups/uploads-1.tar.gz'
PAIRED_KEEP=$'backups/neogen-2.dump\nbackups/uploads-2.tar.gz'
t "a kept dump keeps its uploads archive too" \
  "$(printf 'backups/neogen-1.dump\nbackups/uploads-1.tar.gz')" \
  "$(prune_keeping "$PAIRED_CANDIDATES" "$PAIRED_KEEP")"

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

# ── bundle_missing_files(): a db/<ver> folder is complete or it is not ───────
# tools/sync-from-app-copy.sh refuses to copy a folder that lacks any of the
# four artifacts; tests/db-bundle-lint.sh asserts every shipped one is whole.
# The oldest folder (1.2.0) legitimately has no migrate-*.sql — third arg "no".
t "bundle_missing_files is defined" "function" "$(type -t bundle_missing_files 2>/dev/null || echo MISSING)"
mkdir -p bundles/9.9.0 bundles/9.9.1 bundles/9.9.2 bundles/1.2.0
for f in schema.sql grants.sql seed.sql migrate-9.9.0.sql; do printf 'x\n' > bundles/9.9.0/$f; done
for f in schema.sql grants.sql migrate-9.9.1.sql; do printf 'x\n' > bundles/9.9.1/$f; done   # no seed
for f in schema.sql seed.sql migrate-9.9.2.sql; do printf 'x\n' > bundles/9.9.2/$f; done
: > bundles/9.9.2/grants.sql                                                                # EMPTY grants
for f in schema.sql grants.sql seed.sql; do printf 'x\n' > bundles/1.2.0/$f; done            # base: no migrate
t "complete bundle → nothing missing"      ""           "$(bundle_missing_files bundles/9.9.0 9.9.0)"
t "missing seed is reported"               "seed.sql"   "$(bundle_missing_files bundles/9.9.1 9.9.1)"
t "an EMPTY grants.sql counts as missing"  "grants.sql" "$(bundle_missing_files bundles/9.9.2 9.9.2)"
t "base folder without migrate is whole"   ""           "$(bundle_missing_files bundles/1.2.0 1.2.0 no)"
t "base folder still wants the migrate by default" "migrate-1.2.0.sql" "$(bundle_missing_files bundles/1.2.0 1.2.0)"
t "absent folder reports every artifact"   $'schema.sql\ngrants.sql\nseed.sql\nmigrate-0.0.1.sql' \
  "$(bundle_missing_files bundles/0.0.1 0.0.1)"

# ── review_marker_line(): where apply_migrations can SEE the marker ──────────
# lib.sh greps `head -n 6` for REQUIRES-REVIEW. A marker written lower is
# invisible and the delta silently rides the rolling path; prose that merely
# MENTIONS the token ("not REQUIRES-REVIEW") must not be mistaken for one.
t "review_marker_line is defined" "function" "$(type -t review_marker_line 2>/dev/null || echo MISSING)"
printf -- '-- migrate-x.sql — delta\n-- REQUIRES-REVIEW: drops a thing\n-- body\n' > m-flagged.sql
printf -- '-- migrate-y.sql — delta\n-- additive\n-- (deliberately not marked REQUIRES-REVIEW: nothing is dropped)\n' > m-mention.sql
{ printf -- '-- migrate-z.sql\n'; for i in 2 3 4 5 6 7; do printf -- '-- line %s\n' $i; done; printf -- '-- REQUIRES-REVIEW: too low\n'; } > m-late.sql
printf -- '-- plain\n' > m-none.sql
t "anchored marker on line 2 → 2"        "2" "$(review_marker_line m-flagged.sql)"
t "a mention in prose is not a marker"   ""  "$(review_marker_line m-mention.sql)"
t "marker below line 6 is still reported (lint fails it)" "8" "$(review_marker_line m-late.sql)"
t "no marker → empty"                    ""  "$(review_marker_line m-none.sql)"

# ── Patch releases order between their minor and the next (1.40.0 < 1.40.1 < 1.41.0)
t "ver_le 1.40.0 <= 1.40.1"  "y" "$(ver_le 1.40.0 1.40.1 && echo y || echo n)"
t "ver_le 1.40.1 <= 1.41.0"  "y" "$(ver_le 1.40.1 1.41.0 && echo y || echo n)"
t "ver_le 1.41.0 <= 1.40.1"  "n" "$(ver_le 1.41.0 1.40.1 && echo y || echo n)"
t "is_exact_semver 1.40.1"   "y" "$(is_exact_semver 1.40.1 && echo y || echo n)"
mkdir -p patch/db/1.40.0 patch/db/1.40.1 patch/db/1.41.0
for v in 1.40.0 1.40.1 1.41.0; do printf -- '-- d\n' > patch/db/$v/migrate-$v.sql; done
( cd patch && migration_files_through 1.41.0 | xargs -n1 basename | tr '\n' ' ' ) > patch/order.txt
t "migration_files_through orders 1.40.0 1.40.1 1.41.0" "migrate-1.40.0.sql migrate-1.40.1.sql migrate-1.41.0.sql " "$(cat patch/order.txt)"
( cd patch && migration_files_through 1.40.1 | xargs -n1 basename | tr '\n' ' ' ) > patch/order2.txt
t "migration_files_through 1.40.1 stops before 1.41.0" "migrate-1.40.0.sql migrate-1.40.1.sql " "$(cat patch/order2.txt)"

# ── image_ref_rename(): the registry moved nxpi_dev → nxpi; exact repo only ───
t "image_ref_rename is defined" "function" "$(type -t image_ref_rename 2>/dev/null || echo MISSING)"
t "tag ref is renamed"         "ghcr.io/negentrophi/nxpi:latest"      "$(image_ref_rename ghcr.io/negentrophi/nxpi_dev:latest)"
t "digest ref is renamed"      "ghcr.io/negentrophi/nxpi@sha256:abc"  "$(image_ref_rename ghcr.io/negentrophi/nxpi_dev@sha256:abc)"
t "new name is left alone"     "ghcr.io/negentrophi/nxpi:sha-cb44bba" "$(image_ref_rename ghcr.io/negentrophi/nxpi:sha-cb44bba)"
t "helper image is left alone" "ghcr.io/negentrophi/nxpi-hash:latest" "$(image_ref_rename ghcr.io/negentrophi/nxpi-hash:latest)"
t "db artifact is left alone"  "ghcr.io/negentrophi/nxpi_dev/db:1.41.0" "$(image_ref_rename ghcr.io/negentrophi/nxpi_dev/db:1.41.0)"
t "other owner is left alone"  "ghcr.io/lpanigrahi/nxpi_dev:latest"   "$(image_ref_rename ghcr.io/lpanigrahi/nxpi_dev:latest)"
t "custom old/new repos"       "r.io/b:1"                              "$(image_ref_rename r.io/a:1 r.io/a r.io/b)"

# ── env_set(): replace-or-append a dotenv key so env_get reads it back ────────
t "env_set is defined" "function" "$(type -t env_set 2>/dev/null || echo MISSING)"
printf 'A=1\nDB_VERSION=1.15.0\n# comment\nB=2\n' > es.env
env_set es.env DB_VERSION 1.41.0
t "env_set replaces in place"        "1.41.0" "$(env_get es.env DB_VERSION)"
t "env_set keeps the other keys"     "1 2"    "$(env_get es.env A) $(env_get es.env B)"
t "env_set keeps line count"         "4"      "$(wc -l < es.env | tr -d ' ')"
env_set es.env TRUSTED_PROXY_MODE xff
t "env_set appends when absent"      "xff"    "$(env_get es.env TRUSTED_PROXY_MODE)"
env_set es.env PW 'p @ss #1'
t "env_set quotes a value with spaces/#" "p @ss #1" "$(env_get es.env PW)"
env_set es.env IMG 'ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b98'
t "env_set writes an image ref verbatim" "ghcr.io/negentrophi/nxpi:sha-cb44bba@sha256:1a615b98" "$(env_get es.env IMG)"
printf 'K=1\n' > es2.env; printf 'K=2' >> es2.env   # no trailing newline before append
env_set es2.env NEWKEY v
t "env_set appends on its own line even without a trailing newline" "v" "$(env_get es2.env NEWKEY)"
env_set es2.env K 3
t "env_set collapses a last-wins duplicate to one line" "1" "$(grep -c '^K=' es2.env | tr -d ' ')"
t "env_set value survives the collapse"                 "3" "$(env_get es2.env K)"

# ── rowcount_compare(): losslessness with an explicit, printed allow-list ────
t "rowcount_compare is defined" "function" "$(type -t rowcount_compare 2>/dev/null || echo MISSING)"
printf 'user\t10\nchat\t5\norg_role_permission\t20\nagent_memory\t0\npermission_catalog\t0\norg_resource_grant\t7\ngroup\t4\n' > rc.before
printf 'user\t10\nchat\t5\norg_role_permission\t17\npermission_catalog\t78\norg_resource_grant\t7\ngroup\t4\norg_resource_grant_agents\t3\n' > rc.after
printf 'org_role_permission\tshrink=3\t0005 viewer loses audit:view\nagent_memory\tgone\t0094 orphan table dropped\npermission_catalog\tgrow\t0012 seeds the vocabulary\norg_resource_grant\tsame\t0015 checksummed rebuild\n' > rc.expect
OUT=$(rowcount_compare rc.before rc.after rc.expect); RC=$?
t "all-expected run exits 0"                "0"   "$RC"
t "expected exact shrink is reported ok"    "yes" "$(grep -qE '^ok shrink.org_role_permission.20.17' <<<"$OUT" && echo yes || echo no)"
t "expected gone is reported ok"            "yes" "$(grep -qE '^ok gone.agent_memory' <<<"$OUT" && echo yes || echo no)"
t "a new partition child is reported new"   "yes" "$(grep -qE '^new.org_resource_grant_agents.3' <<<"$OUT" && echo yes || echo no)"
t "unchanged tables are counted, not listed" "yes" "$(grep -qE '^unchanged.4$' <<<"$OUT" && echo yes || echo no)"
t "no violation lines"                      "0"   "$(grep -c '^!!' <<<"$OUT" | tr -d ' ')"
# violations: an unlisted shrink, an unlisted disappearance, a broken exact, a broken same
printf 'user\t9\nchat\t5\norg_role_permission\t18\npermission_catalog\t78\norg_resource_grant\t6\n' > rc.bad
OUT=$(rowcount_compare rc.before rc.after.missing rc.expect 2>/dev/null); RC=$?
t "missing after-file fails closed"         "2"   "$RC"
OUT=$(rowcount_compare rc.before rc.bad rc.expect); RC=$?
t "violations exit 1"                       "1"   "$RC"
t "unlisted shrink is a violation"          "yes" "$(grep -qE '^!! shrank.user.10.9' <<<"$OUT" && echo yes || echo no)"
t "unlisted disappearance is a violation"   "yes" "$(grep -qE '^!! gone.group.4' <<<"$OUT" && echo yes || echo no)"
t "exact shrink mismatch is a violation"    "yes" "$(grep -qE '^!! exact.org_role_permission.20.18.*expected 3' <<<"$OUT" && echo yes || echo no)"
t "broken same is a violation"              "yes" "$(grep -qE '^!! same.org_resource_grant.7.6' <<<"$OUT" && echo yes || echo no)"
# a plain shrink line for the same table relaxes an exact one (1.22.0 exact + 1.25.0 open)
printf 'org_role_permission\tshrink=3\tfirst\norg_role_permission\tshrink\tsecond delta also deletes\n' > rc.expect2
printf 'org_role_permission\t20\n' > rc.b2; printf 'org_role_permission\t11\n' > rc.a2
OUT=$(rowcount_compare rc.b2 rc.a2 rc.expect2); RC=$?
t "open shrink relaxes exact for the same table" "0" "$RC"
# no expect file at all: any shrink is a violation, growth is fine
printf 'a\t1\nb\t1\n' > rc.b3; printf 'a\t2\nb\t1\n' > rc.a3
OUT=$(rowcount_compare rc.b3 rc.a3); RC=$?
t "growth without an expect file is fine"   "0"   "$RC"
# a gone that is NOT gone is a violation (the drop did not happen)
printf 'x\t1\n' > rc.b4; printf 'x\t1\n' > rc.a4; printf 'x\tgone\tshould drop\n' > rc.e4
OUT=$(rowcount_compare rc.b4 rc.a4 rc.e4); RC=$?
t "expected-gone table still present is a violation" "1" "$RC"

# ── uploads_classify(): disk set vs catalog set, with the served-uncataloged layout ─
t "uploads_classify is defined" "function" "$(type -t uploads_classify 2>/dev/null || echo MISSING)"
printf 'uploads/31-report.txt\nuploads/32-orphan.txt\nuploads/shared/33-logo.png\nuploads/threads/9f/34-x.pdf\nlogos/old.png\n' > up.disk
printf 'uploads/31-report.txt\nuploads/gone-from-disk.txt\n' > up.db
OUT=$(uploads_classify up.disk up.db)
t "cataloged file"                 "yes" "$(grep -qE '^cataloged.uploads/31-report.txt$' <<<"$OUT" && echo yes || echo no)"
t "flat uncataloged file"          "yes" "$(grep -qE '^uncataloged.flat.uploads/32-orphan.txt$' <<<"$OUT" && echo yes || echo no)"
t "shared layout is tagged shared" "yes" "$(grep -qE '^uncataloged.shared.uploads/shared/33-logo.png$' <<<"$OUT" && echo yes || echo no)"
t "threads layout is tagged"       "yes" "$(grep -qE '^uncataloged.threads.uploads/threads/9f/34-x.pdf$' <<<"$OUT" && echo yes || echo no)"
t "outside the prefix is other"    "yes" "$(grep -qE '^uncataloged.other.logos/old.png$' <<<"$OUT" && echo yes || echo no)"
t "catalog row without a file"     "yes" "$(grep -qE '^missing-on-disk.uploads/gone-from-disk.txt$' <<<"$OUT" && echo yes || echo no)"
t "classification is exhaustive"   "6"   "$(wc -l <<<"$OUT" | tr -d ' ')"

# ── disk_need_kb(): the free-space demand of a window ──────────────────────────
t "disk_need_kb is defined" "function" "$(type -t disk_need_kb 2>/dev/null || echo MISSING)"
# 3×DB (dump, migration headroom, a disk-backed scratch or the rollback's own
# safety dump) + 2×uploads (bundle tar + rollback safety tar) + 1.5 GiB image
# + 2 GiB slack, in KiB: 3·1 GiB + 0 + 3.5 GiB = 6.5 GiB = 6815744 KiB
t "disk_need_kb 1GiB db, no uploads" "6815744" "$(disk_need_kb 1073741824 0)"
t "disk_need_kb counts uploads twice" "6817792" "$(disk_need_kb 1073741824 1048576)"

# ── list_pending_destructive(): EVERY unapplied flagged delta, not just the first ─
t "list_pending_destructive is defined" "function" "$(type -t list_pending_destructive 2>/dev/null || echo MISSING)"
t "is_migration_applied is defined"     "function" "$(type -t is_migration_applied 2>/dev/null || echo MISSING)"
mkdir -p pend/db/1.1.0 pend/db/1.2.0 pend/db/1.3.0 pend/db/1.4.0
printf -- '-- d\n-- REQUIRES-REVIEW: a\n' > pend/db/1.1.0/migrate-1.1.0.sql
printf -- '-- d\n' > pend/db/1.2.0/migrate-1.2.0.sql
printf -- '-- d\n-- REQUIRES-REVIEW: b\n' > pend/db/1.3.0/migrate-1.3.0.sql
printf -- '-- d\n-- REQUIRES-REVIEW: c\n' > pend/db/1.4.0/migrate-1.4.0.sql
printf 'DB_VERSION=1.4.0\n' > pend/.env
ensure_migration_marker() { :; }                                   # stub: no DB
is_migration_applied() { [ "$1" = "migrate-1.1.0.sql" ]; }         # stub: 1.1.0 already applied
cd pend
t "lists every pending flagged delta in order" "db/1.3.0/migrate-1.3.0.sql db/1.4.0/migrate-1.4.0.sql " "$(list_pending_destructive | tr '\n' ' ')"
t "has_pending_destructive still prints only the first" "db/1.3.0/migrate-1.3.0.sql" "$(has_pending_destructive)"
printf 'DB_VERSION=1.2.0\n' > .env
t "nothing flagged within a lower target" "" "$(list_pending_destructive)"
cd ..
unset -f ensure_migration_marker is_migration_applied

# ── SCHEMA_PROBES: one sentinel per release, sorted, with SQL renderers ───────
t "SCHEMA_PROBES is set"        "yes" "$([ -n "${SCHEMA_PROBES:-}" ] && echo yes || echo no)"
t "SCHEMA_PROBES is sorted -V"  "yes" "$([ "$(printf '%s\n' "$SCHEMA_PROBES" | cut -f1)" = "$(printf '%s\n' "$SCHEMA_PROBES" | cut -f1 | sort -V)" ] && echo yes || echo no)"
t "SCHEMA_PROBES reaches 1.42.0" "yes" "$(printf '%s\n' "$SCHEMA_PROBES" | grep -q '^1\.42\.0	' && echo yes || echo no)"
t "SCHEMA_PROBES keeps the legacy 1.5.0 probe" "yes" "$(printf '%s\n' "$SCHEMA_PROBES" | grep -q '^1\.5\.0	table	skill_scan$' && echo yes || echo no)"
t "schema_probe_sql column"     "yes" "$(schema_probe_sql column agent.governance_disabled_by | grep -q "table_name='agent'.*column_name='governance_disabled_by'" && echo yes || echo no)"
t "schema_probe_sql table"      "yes" "$(schema_probe_sql table permission_catalog | grep -q "table_name='permission_catalog'" && echo yes || echo no)"
t "schema_probe_sql policy"     "yes" "$(schema_probe_sql policy 'tenant_isolation ON org_role' | grep -q "policyname='tenant_isolation'.*tablename='org_role'" && echo yes || echo no)"
t "schema_probe_sql function"   "yes" "$(schema_probe_sql function admin_audit_log_signed_append | grep -q "proname='admin_audit_log_signed_append'" && echo yes || echo no)"
t "schema_probe_sql constraint" "yes" "$(schema_probe_sql constraint knowledge_embeddings_dims_col_ck | grep -q "conname='knowledge_embeddings_dims_col_ck'" && echo yes || echo no)"
t "schema_probe_sql index"      "yes" "$(schema_probe_sql index cron_run_log_one_running_per_job | grep -q "indexname='cron_run_log_one_running_per_job'" && echo yes || echo no)"

# ── deep_probe_auth_header(): /api/health/deep is credentialed since DT-4-i-1 ─
# The app reads METRICS_TOKEN from its process env, i.e. ./.env.app — not ./.env.
# Unset means the advisory probe stays anonymous (and prints nothing useful).
t "deep_probe_auth_header is defined" "function" "$(type -t deep_probe_auth_header 2>/dev/null || echo MISSING)"
mkdir -p dph && ( cd dph && : > .env && : > .env.app )
t "no token anywhere → placeholder header" "X-Deep-Probe: none" "$(cd dph && deep_probe_auth_header)"
printf 'METRICS_TOKEN=fromapp\n' > dph/.env.app
t "token from .env.app"                   "Authorization: Bearer fromapp" "$(cd dph && deep_probe_auth_header)"
printf 'METRICS_TOKEN=fromenv\n' > dph/.env
t ".env.app wins over .env"               "Authorization: Bearer fromapp" "$(cd dph && deep_probe_auth_header)"
: > dph/.env.app
t ".env is the fallback"                  "Authorization: Bearer fromenv" "$(cd dph && deep_probe_auth_header)"

# ── NXPI_TARGET_VERSION: a rehearsal migrates a SCRATCH copy to a target the ─
# live ./.env does not name yet (upgrade-db.sh bumps DB_VERSION later). The
# override wins over DB_VERSION and the image tag; unset, nothing changes.
mkdir -p tov && printf 'APP_IMAGE=x:latest\nDB_VERSION=1.15.0\n' > tov/.env
t "db_target_version reads .env by default"    "1.15.0" "$(cd tov && db_target_version)"
t "NXPI_TARGET_VERSION overrides it"           "1.41.0" "$(cd tov && NXPI_TARGET_VERSION=1.41.0 db_target_version)"
t "an empty override is ignored"               "1.15.0" "$(cd tov && NXPI_TARGET_VERSION= db_target_version)"

# ── pending_migrations(): what a read-only observer would apply, WITHOUT ─────
# creating the marker table (discover.sh must leave no trace).
t "pending_migrations is defined" "function" "$(type -t pending_migrations 2>/dev/null || echo MISSING)"
t "marker_table_exists is defined" "function" "$(type -t marker_table_exists 2>/dev/null || echo MISSING)"
cd pend
printf 'DB_VERSION=1.4.0\n' > .env
marker_table_exists() { return 0; }
is_migration_applied() { [ "$1" = "migrate-1.1.0.sql" ]; }
t "pending_migrations lists unapplied basenames in order" "migrate-1.2.0.sql migrate-1.3.0.sql migrate-1.4.0.sql " "$(pending_migrations 1.4.0 | tr '\n' ' ')"
marker_table_exists() { return 1; }
is_migration_applied() { die "must not query a marker table that does not exist"; }
t "no marker table → everything is pending, no query made" "migrate-1.1.0.sql migrate-1.2.0.sql migrate-1.3.0.sql migrate-1.4.0.sql " "$(pending_migrations 1.4.0 | tr '\n' ' ')"
cd ..
unset -f marker_table_exists is_migration_applied

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
