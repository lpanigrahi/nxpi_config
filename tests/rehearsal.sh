#!/usr/bin/env bash
# =============================================================================
# rehearsal.sh — the end-to-end proof, on local Docker, that upgrade-release.sh
# takes a 1.15.0-shaped deployment with REAL-LOOKING data to 1.41.0 + the new
# image with zero data loss, and that --rollback brings it back byte-for-byte.
#
#   tests/rehearsal.sh [--old-image REF] [--new-image REF] [--from 1.15.0] [--to 1.41.0]
#                      [--http-port 18080] [--https-port 18443] [--project neogen-rehearsal]
#                      [--dir DIR] [--skip-rollback] [--keep] [--force-clean]
#
# Isolation: a throwaway copy of the TRACKED package files (git ls-files) in a
# temp dir, its own compose project (volumes neogen-rehearsal_*), remapped
# Caddy ports. The real ./secrets, ./.env, ./backups and neogen_* volumes are
# never read or touched (their count is asserted unchanged at the end).
#
# Steps: install 1.15.0 on the OLD image → seed data (tests/rehearsal-seed.sql
# + files in the uploads volume, one of them uncataloged) → snapshots →
# upgrade-release.sh --yes → assertions (counts, RBAC, grant, catalog, schema,
# uploads bytes, sign-in, the 404/200 catalog behaviour) → --rollback →
# assertions (everything byte-identical to the snapshots) → teardown.
#
# Needs: docker + compose v2, curl, sudo (install.sh chowns secrets to uid
# 1001), pull access to both images. On an arm64 host (Apple Silicon) the
# images are linux/amd64-only and run under emulation — slow but faithful;
# DOCKER_DEFAULT_PLATFORM is exported automatically.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)

OLD_IMAGE="ghcr.io/negentrophi/nxpi_dev:latest"
NEW_IMAGE="ghcr.io/negentrophi/nxpi:sha-cb44bba"
FROM=1.15.0; TO=1.41.0; HTTP=18080; HTTPS=18443; PROJECT=neogen-rehearsal; DIR=""
SKIP_ROLLBACK=false; KEEP=false; FORCE_CLEAN=false
while [ $# -gt 0 ]; do
  case "$1" in
    --old-image) shift; OLD_IMAGE="$1" ;;   --new-image) shift; NEW_IMAGE="$1" ;;
    --from) shift; FROM="$1" ;;             --to) shift; TO="$1" ;;
    --http-port) shift; HTTP="$1" ;;        --https-port) shift; HTTPS="$1" ;;
    --project) shift; PROJECT="$1" ;;       --dir) shift; DIR="$1" ;;
    --skip-rollback) SKIP_ROLLBACK=true ;;  --keep) KEEP=true ;;  --force-clean) FORCE_CLEAN=true ;;
    -h|--help) sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

PASS=0; FAIL=0; T0=$(date +%s)
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf 'ok    %s\n' "$1"; else FAIL=$((FAIL+1)); printf 'FAIL  %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }
phase() { printf '\n══ %s  (t+%ss) ══\n' "$1" "$(( $(date +%s) - T0 ))"; }
die() { printf '✖ %s\n' "$*" >&2; exit 1; }

# ── pre-checks ───────────────────────────────────────────────────────────────
phase "pre-checks"
for c in docker curl tar; do command -v $c >/dev/null || die "$c is required"; done
docker compose version >/dev/null 2>&1 || die "docker compose v2 is required"
command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || die "sha256sum/shasum required"
case "$(uname -m)" in x86_64|amd64) ;; *) export DOCKER_DEFAULT_PLATFORM=linux/amd64; echo "  arm64 host: DOCKER_DEFAULT_PLATFORM=linux/amd64 (emulated)";; esac
for img in "$OLD_IMAGE" "$NEW_IMAGE"; do
  docker image inspect "$img" >/dev/null 2>&1 || docker pull "$img" >/dev/null 2>&1 || die "cannot pull $img — docker login ghcr.io with a read:packages PAT (never 'gh auth token')"
done
NEW_DIGEST=$(docker image inspect "$NEW_IMAGE" --format '{{join .RepoDigests "\n"}}' | grep -F @sha256: | head -n1)
OLD_DIGEST=$(docker image inspect "$OLD_IMAGE" --format '{{join .RepoDigests "\n"}}' | grep -F @sha256: | head -n1)
echo "  old: $OLD_DIGEST"; echo "  new: $NEW_DIGEST"
NEW_PINNED="${NEW_IMAGE}@${NEW_DIGEST#*@}"
if docker volume ls -q | grep -q "^${PROJECT}_"; then
  $FORCE_CLEAN && docker compose -p "$PROJECT" down -v --remove-orphans >/dev/null 2>&1 || die "volumes ${PROJECT}_* exist from an earlier run — re-run with --force-clean"
fi
(lsof -iTCP:"$HTTP" -sTCP:LISTEN >/dev/null 2>&1) && die "port $HTTP is in use"
if sudo -n true 2>/dev/null; then echo "  sudo: available (secrets get uid 1001 / 400, as on the VM)"
else export NXPI_NO_SUDO=1; echo "  sudo: not available non-interactively — NXPI_NO_SUDO=1 (secrets 444 in the throwaway copy)"; fi
REAL_VOLS=$(docker volume ls -q | grep -c '^neogen_' || true)

# ── throwaway package copy ───────────────────────────────────────────────────
[ -n "$DIR" ] || DIR=$(mktemp -d "${TMPDIR:-/tmp}/nxpi-rehearsal.XXXXXX")
mkdir -p "$DIR"
( cd "$PKG" && git ls-files -z | tar --null -T - -cf - ) | tar -C "$DIR" -xf - || die "could not copy the tracked package files"
echo "  package copy: $DIR"
cleanup() {
  $KEEP && { echo "  --keep: leaving $DIR and project $PROJECT running"; return 0; }
  ( cd "$DIR" 2>/dev/null && docker compose -p "$PROJECT" down -v --remove-orphans >/dev/null 2>&1 ) || true
  docker volume ls -q | grep "^${PROJECT}_" | xargs docker volume rm >/dev/null 2>&1 || true
  rm -rf "$DIR" 2>/dev/null || sudo -n rm -rf "$DIR" 2>/dev/null || echo "  could not remove $DIR (root-owned files?) — remove it by hand"
}
trap cleanup EXIT
cd "$DIR" || exit 1
export COMPOSE_PROJECT_NAME="$PROJECT"

ADMIN_PW=$(openssl rand -hex 12)
cat > .env <<EOF
APP_IMAGE=$OLD_IMAGE
DB_VERSION=$FROM
NXPI_HASH_IMAGE=ghcr.io/negentrophi/nxpi-hash:latest
BETTER_AUTH_URL=http://127.0.0.1:$HTTP
SUPER_ADMIN_EMAIL=rehearsal-admin@example.com
SUPER_ADMIN_PASSWORD=$ADMIN_PW
CADDY_HTTP_PORT=$HTTP
CADDY_HTTPS_PORT=$HTTPS
COMPOSE_PROJECT_NAME=$PROJECT
BACKUP_RETENTION_DAYS=1
POSTGRES_PRIVILEGED_URL_FILE=/run/secrets/postgres_privileged_url
EOF
chmod 600 .env
cp .env.app.example .env.app; chmod 600 .env.app
# shellcheck disable=SC1091
. ./lib.sh

# ── (a) fresh install at $FROM on the OLD image ──────────────────────────────
phase "(a) install $FROM on $OLD_IMAGE"
if ! ./install.sh --force > "$DIR/install.log" 2>&1; then
  tail -n 40 "$DIR/install.log"
  if docker compose -p "$PROJECT" logs app 2>/dev/null | grep -q 'not readable by uid 1001'; then
    echo "  Docker Desktop bind-mount uid mapping: secrets unreadable by uid 1001 — falling back to chmod 444 (throwaway dir only)"
    (chmod 444 secrets/* 2>/dev/null || sudo -n chmod 444 secrets/*) && ./compose.sh up -d app >/dev/null 2>&1 && health_gate 300 || die "app still unhealthy after the permission fallback"
  else die "install.sh failed (log: $DIR/install.log)"; fi
fi
t "install: postgres healthy"   "yes" "$(wait_healthy postgres 30 >/dev/null 2>&1 && echo yes || echo no)"
t "install: ingress ready"      "yes" "$(ingress_probe && echo yes || echo no)"
t "install: schema at $FROM"    "1"   "$(psql_scalar "select 1 from information_schema.columns where table_name='plugin_bundle' and column_name='deleted_at'")"
t "install: marker newest is $FROM" "migrate-$FROM.sql" "$(psql_admin -tAc 'select filename from public.deploy_schema_migrations' </dev/null 2>/dev/null | sort -V | tail -n1)"
t "install: privileged role provisioned" "1" "$(psql_scalar "select 1 from pg_roles where rolname='neogen_priv' and rolbypassrls")"

# ── (b) seed data + files ────────────────────────────────────────────────────
phase "(b) seed"
psql_admin -1 < "$PKG/tests/rehearsal-seed.sql" > "$DIR/seed.log" 2>&1 || { tail -n 20 "$DIR/seed.log"; die "seed failed"; }
docker compose -p "$PROJECT" exec -T app sh -c '
  mkdir -p /app/uploads/uploads/shared &&
  printf "cataloged report body\n" > /app/uploads/uploads/31000000-0000-4000-8000-000000000001-report.txt &&
  printf "orphan body\n"           > /app/uploads/uploads/32000000-0000-4000-8000-000000000002-orphan.txt &&
  printf "shared logo\n"           > /app/uploads/uploads/shared/33000000-0000-4000-8000-000000000003-logo.txt' \
  || die "could not write the upload fixtures"
t "seed: users"        "3" "$(user_count)"
t "seed: custom role key is NULL" "" "$(psql_scalar "select key from org_role where id='22222222-0000-4000-8000-000000000001'")"

# ── (c) snapshots ────────────────────────────────────────────────────────────
phase "(c) snapshots"
S="$DIR/rehearsal"; mkdir -p "$S"
snap() { # snap SUFFIX
  rowcount_snapshot > "$S/counts.$1"
  psql_admin -tAF$'\t' -c "select r.id, r.is_system, coalesce(r.key,'<null>') from org_role r order by 1" </dev/null > "$S/roles.$1"
  psql_admin -tAF$'\t' -c "select rp.role_id, rp.permission, rp.denied from org_role_permission rp order by 1,2" </dev/null > "$S/orp.$1"
  psql_admin -tAF$'\t' -c "select gi.group_id, gi.permission from org_permission_group_item gi order by 1,2" </dev/null > "$S/opgi.$1"
  psql_admin -tAF$'\t' -c "select g.id, g.is_system, g.key from org_permission_group g order by 1" </dev/null > "$S/opg.$1"
  psql_admin -tAc "select table_name from information_schema.tables where table_schema='public' and table_type='BASE TABLE' order by 1" </dev/null > "$S/tables.$1"
  psql_admin -tAc "select filename from public.deploy_schema_migrations order by 1" </dev/null | sort -V > "$S/marker.$1"
  docker compose -p "$PROJECT" exec -T app sh -c 'cd /app/uploads && find . -type f | sort | xargs sha256sum' > "$S/uploads.$1" 2>/dev/null
}
snap pre
t "snapshot: counts captured" "yes" "$([ -s "$S/counts.pre" ] && echo yes || echo no)"
t "snapshot: 3 upload files hashed" "3" "$(grep -c . "$S/uploads.pre")"
cnt() { awk -F'\t' -v t="$1" '$1==t{print $2}' "$S/counts.$2"; }

# ── (d) the upgrade ──────────────────────────────────────────────────────────
phase "(d) upgrade-release.sh → $TO on $NEW_PINNED"
TU=$(date +%s)
./upgrade-release.sh --yes --target "$TO" --image "$NEW_PINNED" --accept-uncataloged-uploads --ack DROP-AGENT-MEMORY > "$DIR/upgrade.log" 2>&1; URC=$?
echo "  upgrade-release.sh exit $URC in $(( $(date +%s) - TU ))s (log: $DIR/upgrade.log)"
[ "$URC" = "0" ] || { grep -E '✖|FAIL|!!|BLOCK|warn|⚠' "$DIR/upgrade.log" | tail -n 30; }
t "upgrade exits 0" "0" "$URC"
RUN="backups/$(readlink backups/release-current)"

# ── (e) assertions after the upgrade ─────────────────────────────────────────
phase "(e) post-upgrade assertions"
snap post
t "marker newest is $TO"                 "migrate-$TO.sql" "$(tail -n1 "$S/marker.post")"
# the marker gained exactly the files AFTER migrate-$FROM.sql in apply order, up to $TO
EXPECTED_NEW=$(migration_files_through "$TO" | xargs -n1 basename | awk -v f="migrate-$FROM.sql" 'found{print} $0==f{found=1}' | tr '\n' ' ')
t "marker gained exactly the pending set" "$EXPECTED_NEW" "$(comm -13 <(sort "$S/marker.pre") <(sort "$S/marker.post") | sort -V | tr '\n' ' ')"
# (cron_run_log and session are written by the RUNNING app — the scheduler
# logs runs, sign-ins create sessions — so only user-authored tables are exact)
for tbl in user organization organization_member chat_thread chat_message thread_attachment knowledge_base knowledge_documents document_chunk team team_member org_role org_role_assignment org_resource_grant org_invite; do
  t "count unchanged: $tbl" "$(cnt "$tbl" pre)" "$(cnt "$tbl" post)"
done
t "custom role got its key"             "custom-22222222" "$(psql_scalar "select key from org_role where id='22222222-0000-4000-8000-000000000001'")"
t "org_role.key is NOT NULL"            "NO" "$(psql_scalar "select is_nullable from information_schema.columns where table_name='org_role' and column_name='key'")"
t "custom deny row survived"            "1" "$(psql_scalar "select count(*) from org_role_permission where role_id='22222222-0000-4000-8000-000000000001' and permission='members:invite' and denied")"
t "custom allow row survived"           "1" "$(psql_scalar "select count(*) from org_role_permission where role_id='22222222-0000-4000-8000-000000000001' and permission='members:view' and not denied")"
# every deleted RBAC row belonged to a SYSTEM role/pack and was not a deny
DEL=$(comm -23 <(sort "$S/orp.pre") <(sort "$S/orp.post"))
BAD=$(printf '%s\n' "$DEL" | awk -F'\t' 'NF{print}' | while IFS=$'\t' read -r rid perm denied; do sys=$(awk -F'\t' -v r="$rid" '$1==r{print $2}' "$S/roles.pre"); [ "$sys" = "t" ] && [ "$denied" = "f" ] || echo "$rid $perm $denied sys=$sys"; done)
t "deleted role permissions were system, non-deny rows only" "" "$BAD"
t "some system default rows were deleted (by design)" "yes" "$([ -n "$DEL" ] && echo yes || echo no)"
t "viewer lost audit:view (1.22.0)"     "0" "$(psql_scalar "select count(*) from org_role_permission where role_id='461ba26f-e34e-4f88-99b7-214709dfa57b' and permission='audit:view'")"
DELG=$(comm -23 <(sort "$S/opg.pre") <(sort "$S/opg.post") | awk -F'\t' '$2!="t"{print}')
t "deleted packs were system packs only" "" "$DELG"
t "grant row intact with uuid resource_id" "40000000-0000-4000-8000-000000000001" "$(psql_scalar "select resource_id::text from org_resource_grant where id='50000000-0000-4000-8000-000000000001'")"
t "org_resource_grant is partitioned (p)" "p" "$(psql_scalar "select relkind from pg_class where relname='org_resource_grant' and relnamespace='public'::regnamespace")"
t "six grant partitions"                "6" "$(psql_scalar "select count(*) from pg_inherits where inhparent='public.org_resource_grant'::regclass")"
t "team_member org backfilled"          "17c3b09a-27d7-46cc-8756-604c9f033d93" "$(psql_scalar "select organization_id from team_member where id='24000000-0000-4000-8000-000000000002'")"
t "team_member membership backfilled"   "12000000-0000-4000-8000-000000000002" "$(psql_scalar "select membership_id from team_member where id='24000000-0000-4000-8000-000000000002'")"
t "permission_catalog ≥ 78"             "t" "$(psql_scalar "select (select count(*) from permission_catalog) >= 78")"
t "platform sod_rule seeded"            "t" "$(psql_scalar "select (select count(*) from sod_rule where organization_id is null) >= 1")"
t "agent_memory dropped"                "" "$(psql_scalar "select 1 from information_schema.tables where table_name='agent_memory'")"
t "document_chunk FK is CASCADE"        "c" "$(psql_scalar "select confdeltype from pg_constraint where conname='document_chunk_organization_id_organization_id_fk'")"
t "RLS forced on ≥ 26 tables"           "t" "$(psql_scalar "select (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relforcerowsecurity) >= 26")"
t "thread_attachment.thread_id nullable" "YES" "$(psql_scalar "select is_nullable from information_schema.columns where table_name='thread_attachment' and column_name='thread_id'")"
t "24 new tables, 1 gone"               "24 1" "$(echo "$(comm -13 "$S/tables.pre" "$S/tables.post" | grep -c .) $(comm -23 "$S/tables.pre" "$S/tables.post" | grep -c .)")"
t "uploads bytes identical"             "yes" "$(cmp -s "$S/uploads.pre" "$S/uploads.post" && echo yes || echo no)"
t "app runs the new digest"             "${NEW_DIGEST#*@}" "$(app_image_digest | sed 's/.*@//')"
t "ingress ready on the new image"      "yes" "$(ingress_probe && echo yes || echo no)"
t "orchestrator reported the orphan upload" "yes" "$(grep -q '32000000-0000-4000-8000-000000000002-orphan.txt' "$RUN/uploads-inventory.before" 2>/dev/null && echo yes || echo no)"
t "privileged pool in the app process"  "1" "$(docker compose -p "$PROJECT" exec -T app sh -c 'tr "\0" "\n" < /proc/1/environ | grep -c "^POSTGRES_PRIVILEGED_URL="' 2>/dev/null | tr -d '[:space:]')"
# sign-in + the uploads catalog behaviour
signin() { curl -s -o "$S/signin.$1.json" -w '%{http_code}' -c "$S/cookies.$1" -X POST "http://127.0.0.1:$HTTP/api/auth/sign-in/email" -H 'Content-Type: application/json' -H "Origin: http://127.0.0.1:$HTTP" -d "{\"email\":\"$1\",\"password\":\"$ADMIN_PW\"}"; }
t "admin signs in on the new image"     "200" "$(signin rehearsal-admin@example.com)"
t "seeded owner signs in"               "200" "$(signin owner@rehearsal.example)"
t "session cookie issued"               "yes" "$(grep -qi 'session_token' "$S/cookies.owner@rehearsal.example" && echo yes || echo no)"
getf() { curl -s -o /dev/null -w '%{http_code}' -b "$S/cookies.owner@rehearsal.example" "http://127.0.0.1:$HTTP/api/storage/files/$1"; }
t "cataloged upload served (200)"       "200" "$(getf uploads/31000000-0000-4000-8000-000000000001-report.txt)"
t "uncataloged upload refused (404)"    "404" "$(getf uploads/32000000-0000-4000-8000-000000000002-orphan.txt)"
t "shared upload served (200)"          "200" "$(getf uploads/shared/33000000-0000-4000-8000-000000000003-logo.txt)"

# ── (f) rollback ─────────────────────────────────────────────────────────────
if ! $SKIP_ROLLBACK; then
  phase "(f) rollback"
  TR=$(date +%s)
  ./upgrade-release.sh --rollback --yes --accept-data-loss-since > "$DIR/rollback.log" 2>&1; RRC=$?
  echo "  rollback exit $RRC in $(( $(date +%s) - TR ))s (log: $DIR/rollback.log)"
  [ "$RRC" = "5" ] || grep -E '✖|FAIL|warn|⚠' "$DIR/rollback.log" | tail -n 20
  t "rollback exits 5 (healthy)"        "5" "$RRC"
  snap rb
  t "rollback: marker identical"        "yes" "$(cmp -s "$S/marker.pre" "$S/marker.rb" && echo yes || echo no)"
  t "rollback: table set identical"     "yes" "$(cmp -s "$S/tables.pre" "$S/tables.rb" && echo yes || echo no)"
  # the bundle's dump was taken AFTER the pre snapshot, and the running app writes
  # cron_run_log / session rows in between — compare everything else exactly
  t "rollback: counts identical (app-written tables excluded)" "yes" \
    "$(cmp -s <(grep -vE '^(cron_run_log|session)\b' "$S/counts.pre") <(grep -vE '^(cron_run_log|session)\b' "$S/counts.rb") && echo yes || echo no)"
  t "rollback: role permissions identical" "yes" "$(cmp -s "$S/orp.pre" "$S/orp.rb" && echo yes || echo no)"
  t "rollback: custom key NULL again"   "" "$(psql_scalar "select key from org_role where id='22222222-0000-4000-8000-000000000001'")"
  t "rollback: agent_memory back"       "1" "$(psql_scalar "select 1 from information_schema.tables where table_name='agent_memory'")"
  t "rollback: grant table plain again" "r" "$(psql_scalar "select relkind from pg_class where relname='org_resource_grant' and relnamespace='public'::regnamespace")"
  t "rollback: uploads identical"       "yes" "$(cmp -s "$S/uploads.pre" "$S/uploads.rb" && echo yes || echo no)"
  t "rollback: old digest running"      "${OLD_DIGEST#*@}" "$(app_image_digest | sed 's/.*@//')"
  t "rollback: ingress ready"           "yes" "$(ingress_probe && echo yes || echo no)"
  t "rollback: admin signs in"          "200" "$(signin rehearsal-admin@example.com)"
fi

# ── (g) teardown + isolation check ───────────────────────────────────────────
phase "(g) teardown"
$KEEP || { docker compose -p "$PROJECT" down -v --remove-orphans >/dev/null 2>&1; t "project volumes removed" "0" "$(docker volume ls -q | grep -c "^${PROJECT}_" || true)"; }
t "real neogen_* volumes untouched" "$REAL_VOLS" "$(docker volume ls -q | grep -c '^neogen_' || true)"
printf '\n%d passed, %d failed  (total %ss)\n' "$PASS" "$FAIL" "$(( $(date +%s) - T0 ))"
exit $((FAIL > 0))
