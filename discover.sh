#!/usr/bin/env bash
# =============================================================================
# discover.sh — READ-ONLY report of a deployment before a release upgrade.
#
#   ./discover.sh                       # report → backups/discover-<ts>.txt (+ stdout)
#   ./discover.sh --out FILE            # write the report elsewhere
#   ./discover.sh --target 1.41.0       # pending set / pre-checks against this release
#                                       # (default: the newest db/<version> shipped here)
#   ./discover.sh --no-uploads          # skip the uploads-volume walk (large volumes)
#
# Touches nothing: no deploy lock (it may run beside a cron backup), no marker
# table creation, no container restarts, no secret contents. Every probe is
# guarded, so a half-broken deployment still yields a report. The last block
# is the verdict: READY, BLOCKERS (must be fixed before the window), DECISIONS
# (the operator must choose) and NOTES (the upgrade will converge these).
#
# What it reports, in order: package · env keys · containers/images ·
# migration bookkeeping (marker vs drizzle journal, pending set) · schema
# sentinels · row counts (to a file) · volumes and placement · secrets present ·
# disk/memory · uploads inventory (cataloged / uncataloged / missing-on-disk,
# to files) · data pre-checks (lib-checks.sh, report mode) · runtime probes.
# =============================================================================
set -uo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=lib-checks.sh
. ./lib-checks.sh

OUT=""; TARGET=""; DO_UPLOADS=true
while [ $# -gt 0 ]; do
  case "$1" in
    --out)        shift; OUT="${1:-}" ;;
    --out=*)      OUT="${1#*=}" ;;
    --target)     shift; TARGET="${1:-}" ;;
    --target=*)   TARGET="${1#*=}" ;;
    --no-uploads) DO_UPLOADS=false ;;
    -h|--help)    sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done

TS=$(date +%Y%m%d-%H%M%S)
umask 077
mkdir -p backups
[ -n "$OUT" ] || OUT="backups/discover-${TS}.txt"
ROWS="${OUT%.txt}-rowcounts.txt"
UNCAT="${OUT%.txt}-uploads-uncataloged.txt"
MISSING_DISK="${OUT%.txt}-uploads-missing-on-disk.txt"
: > "$OUT" || die "cannot write $OUT"

report() {   # everything below runs inside this function; the tail pipes it to tee
BLOCKERS=""; DECISIONS=""; NOTES=""
blocker()  { BLOCKERS="${BLOCKERS}  ✖ $*"$'\n'; }
decision() { DECISIONS="${DECISIONS}  ? $*"$'\n'; }
note()     { NOTES="${NOTES}  · $*"$'\n'; }
kv() { printf '  %-28s %s\n' "$1" "$2"; }

init_docker

NEWEST=$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -V | tail -n1)
[ -n "$TARGET" ] || TARGET="$NEWEST"
is_exact_semver "$TARGET" || die "--target must be a bare X.Y.Z release (got: $TARGET)"
[ -d "db/$TARGET" ] || die "db/$TARGET is not shipped in this package"

# ── 1. Package ───────────────────────────────────────────────────────────────
hdr "Package"
kv "directory"        "$SCRIPT_DIR"
kv "git revision"     "$(git rev-parse --short HEAD 2>/dev/null || echo '<not a git checkout>')"
kv "git dirty files"  "$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
kv "shipped db/"      "$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tr '\n' ' ')"
kv "newest shipped"   "$NEWEST"
kv "report target"    "$TARGET"
kv "rollback pin"     "$([ -f .rollback-image.yml ] && sed -n 's/^ *image: "\(.*\)"$/\1/p' .rollback-image.yml | head -n1 || echo none)"
[ -f .rollback-image.yml ] && note "a rollback pin (.rollback-image.yml) is installed from an earlier failed update — every compose call honours it; clear it deliberately before the window"
kv "compose override" "$([ -f docker-compose.override.yml ] && echo present || echo none)"
[ -f docker-compose.override.yml ] && note "docker-compose.override.yml is present — review it; it applies to every compose call"
kv ".env.bak-* files" "$(ls -1 .env.bak-* 2>/dev/null | wc -l | tr -d ' ')"
kv "deploy lock held" "$([ -f .deploy.lock ] && echo 'file present (may be idle)' || echo no)"

# ── 2. Environment (keys; values only for non-secret keys) ───────────────────
hdr "Environment"
[ -f .env ]     || blocker "no ./.env — this is not an installed deployment directory"
[ -f .env.app ] || blocker "no ./.env.app"
kv ".env keys"     "$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' .env 2>/dev/null | cut -d= -f1 | tr '\n' ' ')"
kv ".env.app keys" "$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' .env.app 2>/dev/null | cut -d= -f1 | tr '\n' ' ')"
for k in APP_IMAGE DB_VERSION POSTGRES_IMAGE NXPI_HASH_IMAGE SITE_ADDRESS BETTER_AUTH_URL COMPOSE_PROJECT_NAME \
         CADDY_HTTP_PORT CADDY_HTTPS_PORT POSTGRES_PRIVILEGED_URL_FILE BACKUP_RETENTION_DAYS BACKUP_MIN_KEEP BACKUP_BLOB_ACCOUNT; do
  kv ".env $k" "$(env_get .env "$k" '<unset>')"
done
for k in FILE_STORAGE_TYPE TRUSTED_PROXY_MODE TRUSTED_PROXY_HOPS BETTER_AUTH_COOKIE_SECURE DB_ROLE_PREFLIGHT_MODE DB_PRIVILEGED_PREFLIGHT_MODE; do
  kv ".env.app $k" "$(env_get .env.app "$k" '<unset>')"
done
for k in METRICS_TOKEN AUDIT_SIGNING_KEY SECRETS_ENCRYPTION_KEY OPENAI_API_KEY ANTHROPIC_API_KEY; do
  kv ".env.app $k" "$([ -n "$(env_get .env.app "$k" '')" ] && echo set || echo '<unset>')"
done
APP_IMAGE_ENV=$(env_get .env APP_IMAGE "")
case "$APP_IMAGE_ENV" in
  ghcr.io/negentrophi/nxpi_dev:*|ghcr.io/negentrophi/nxpi_dev@*)
    note "APP_IMAGE names the FROZEN registry ghcr.io/negentrophi/nxpi_dev — CI now publishes ghcr.io/negentrophi/nxpi; the upgrade rewrites it ($(image_ref_rename "$APP_IMAGE_ENV"))" ;;
esac
[ -n "$(env_get .env.app TRUSTED_PROXY_MODE '')" ] || note "TRUSTED_PROXY_MODE is absent from ./.env.app — the current image REFUSES to boot without it; install.sh appends xff"
[ -n "$(env_get .env.app METRICS_TOKEN '')" ]      || note "METRICS_TOKEN is absent from ./.env.app — the deep health probe stays anonymous (advisory only); install.sh generates one"
[ -n "$(env_get .env POSTGRES_PRIVILEGED_URL_FILE '')" ] \
  || decision "privileged pool: POSTGRES_PRIVILEGED_URL_FILE is unset in ./.env — after db 1.29.0 the background cross-tenant sweeps match zero rows unless it is set and ./provision-privileged-role.sh has run (see .env.example)"
CUR_DB_VERSION=$(env_get .env DB_VERSION "")

# ── 3. Containers and images ─────────────────────────────────────────────────
hdr "Containers"
compose ps -a --format 'table {{.Service}}\t{{.Image}}\t{{.Status}}' 2>/dev/null | sed 's/^/  /' || echo "  (compose ps failed)"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
if [ -z "$PG_CID" ]; then
  blocker "postgres is not running — every database section below is empty"
else
  kv "postgres healthy"  "$(wait_healthy postgres 5 >/dev/null 2>&1 && echo yes || echo NO)"
  kv "postgres server"   "$(compose exec -T postgres postgres --version 2>/dev/null | tr -d '\n' || echo '?')"
  PSQL_VER=$(compose exec -T postgres psql --version 2>/dev/null | sed -E 's/.* ([0-9]+\.[0-9]+).*/\1/' | tr -d '\n' || true)
  kv "psql client"       "${PSQL_VER:-?}"
  if [ -n "$PSQL_VER" ] && ! ver_le 17.6 "$PSQL_VER"; then
    note "psql $PSQL_VER < 17.6 — the shipped schema.sql files start with \\restrict; only fresh installs and schema-parity scratch loads need it (the migrate path does not)"
  fi
fi
APP_DIGEST=$(app_image_digest 2>/dev/null || true)
kv "app running image"  "$(compose ps --format '{{.Image}}' app 2>/dev/null | head -n1 || echo none)"
kv "app image digest"   "${APP_DIGEST:-<no running app container>}"
[ -n "$APP_DIGEST" ] || note "no running app container — update.sh will have no automatic rollback reference; upgrade-release.sh records the digest itself"
kv "docker / compose"   "$($DOCKER version --format '{{.Server.Version}}' 2>/dev/null || echo ?) / $($DOCKER compose version --short 2>/dev/null || echo ?)"

# ── 4. Migration bookkeeping ─────────────────────────────────────────────────
hdr "Migration bookkeeping"
PENDING=""
if [ -n "$PG_CID" ]; then
  TABLES=$(table_count); kv "tables in public" "${TABLES:-?}"
  [ "${TABLES:-0}" != "0" ] || blocker "the database is EMPTY — nothing to upgrade (this is install.sh's job)"
  USERS=$(user_count); kv "users" "${USERS:-?}"
  if marker_table_exists; then
    MARKER_N=$(marker_row_count); kv "marker rows" "${MARKER_N:-?}"
    kv "marker newest" "$(psql_admin -tAc 'select filename from public.deploy_schema_migrations' </dev/null 2>/dev/null | sort -V | tail -n1)"
    [ "${MARKER_N:-0}" != "0" ] || note "the migration marker is EMPTY — upgrade-db.sh will need --adopt-schema-version <the release the schema really matches>; use the sentinel probe below and schema-parity.sh to establish it"
  else
    kv "marker table" "ABSENT (never provisioned by this package's scripts)"
    note "no deploy_schema_migrations table — everything <= $TARGET reads as pending; establish the real release first (--adopt-schema-version)"
  fi
  DRZ=$(psql_scalar "select case when to_regclass('drizzle.__drizzle_migrations') is null then -1 else (select count(*) from drizzle.__drizzle_migrations) end")
  kv "drizzle journal rows" "$([ "${DRZ:-x}" = "-1" ] && echo none || echo "${DRZ:-?}")  (informational — this package never runs the journal)"
  PENDING=$(pending_migrations "$TARGET" 2>/dev/null || true)
  kv "pending → $TARGET" "$(printf '%s\n' "$PENDING" | grep -c . | tr -d ' ') file(s)"
  printf '%s\n' "$PENDING" | sed '/^$/d;s/^/    /'
  DESTR=""
  while IFS= read -r base; do
    [ -n "$base" ] || continue
    f=$(find db -mindepth 2 -maxdepth 2 -name "$base" | head -n1)
    [ -n "$f" ] && [ -n "$(review_marker_line "$f")" ] && DESTR="${DESTR}${base} "
  done <<<"$PENDING"
  kv "REQUIRES-REVIEW pending" "${DESTR:-none}"
  [ -z "$DESTR" ] || note "roll-forward-only deltas in scope ($DESTR) — the window needs the maintenance path; the previously-running image cannot serve the migrated schema"
  if [ -n "$CUR_DB_VERSION" ] && ! ver_le "$CUR_DB_VERSION" "$TARGET"; then
    blocker "./.env DB_VERSION=$CUR_DB_VERSION is NEWER than the report target $TARGET"
  fi
fi

# ── 5. Schema sentinels ──────────────────────────────────────────────────────
hdr "Schema sentinels (which release does the schema really match?)"
if [ -n "$PG_CID" ]; then
  schema_probe_report | awk -F'\t' '$1=="highest-present"{print "  highest release whose sentinel exists: " $2; next} {printf "  %-8s %-8s %s\n", $1, $2, $3}'
fi

# ── 6. Row counts ────────────────────────────────────────────────────────────
hdr "Row counts"
if [ -n "$PG_CID" ]; then
  rowcount_snapshot > "$ROWS" 2>/dev/null || true
  if [ -s "$ROWS" ]; then
    kv "snapshot" "$ROWS ($(wc -l < "$ROWS" | tr -d ' ') tables)"
    for tname in user organization organization_member chat_thread chat_message thread_attachment knowledge_base knowledge_documents \
                 document_chunk knowledge_embeddings agent skill apikey admin_audit_log org_resource_grant org_role org_role_permission \
                 org_permission_group org_permission_group_item permission_catalog sod_rule agent_memory cron_run_log session; do
      c=$(awk -F'\t' -v t="$tname" '$1==t{print $2}' "$ROWS"); kv "  $tname" "${c:-<absent>}"
    done
  else
    blocker "could not snapshot row counts (postgres busy?)"
  fi
  kv "database size" "$(psql_scalar "select pg_size_pretty(pg_database_size(current_database()))")"
  echo "  largest relations:"
  psql_admin -tAF' ' -c "select '    ' || c.relname, pg_size_pretty(pg_total_relation_size(c.oid)) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind in ('r','p') order by pg_total_relation_size(c.oid) desc limit 10" </dev/null 2>/dev/null || true
  DB_BYTES=$(psql_scalar "select pg_database_size(current_database())")
fi

# ── 7. Volumes and placement ─────────────────────────────────────────────────
hdr "Volumes"
for v in postgres-data postgres-wal redis-data uploads-data backups-data caddy-data caddy-config npm-cache-data; do
  name="${PROJECT}_$v"
  if $DOCKER volume inspect "$name" >/dev/null 2>&1; then
    dev=$(volume_device "$name"); mp=$($DOCKER volume inspect "$name" --format '{{.Mountpoint}}' 2>/dev/null)
    kv "$name" "exists; device=${dev:-<docker-managed>}; mountpoint=$mp"
  else
    kv "$name" "absent"
  fi
done
VOL_EXISTS=no; $DOCKER volume inspect "${PROJECT}_postgres-data" >/dev/null 2>&1 && VOL_EXISTS=yes
DECLARED=$(compose_volume_device docker-compose.yml postgres-data); ACTUAL=""
[ "$VOL_EXISTS" = "yes" ] && ACTUAL=$(volume_device "${PROJECT}_postgres-data")
HAS_PG=""; [ "$VOL_EXISTS" = "no" ] && [ -n "$DECLARED" ] && is_pgdata_dir "$DECLARED" && HAS_PG=has-pgdata
VERDICT=$(placement_verdict "$VOL_EXISTS" "$DECLARED" "$ACTUAL" "$HAS_PG")
kv "placement verdict" "$VERDICT (declared=${DECLARED:-none} actual=${ACTUAL:-none})"
[ "$VERDICT" != "mismatch" ] || blocker "postgres-data placement MISMATCH — install.sh will refuse to converge (docs/CUTOVER-RUNBOOK.md)"
if [ -n "$PG_CID" ]; then
  kv "PG_VERSION"    "$(compose exec -T postgres cat /var/lib/postgresql/data/PG_VERSION 2>/dev/null | tr -d '\n' || echo ?)"
  kv "pg_wal path"   "$(compose exec -T postgres readlink -f /var/lib/postgresql/data/pg_wal 2>/dev/null | tr -d '\n' || echo ?)"
fi

# ── 8. Secrets present (never their contents) ────────────────────────────────
hdr "Secrets"
for s in postgres_password redis_password postgres_url redis_url redis_cache_url better_auth_secret postgres_privileged_url; do
  if [ -s "secrets/$s" ]; then kv "secrets/$s" "present ($(ls -l "secrets/$s" 2>/dev/null | awk '{print $1" "$3}'))"
  elif [ -e "secrets/$s" ]; then kv "secrets/$s" "EMPTY"; blocker "secrets/$s is empty"
  else kv "secrets/$s" "absent$([ "$s" = postgres_privileged_url ] || [ "$s" = redis_cache_url ] && echo ' (install.sh generates it)' || echo ' — REQUIRED')"
       case "$s" in postgres_privileged_url|redis_cache_url) note "secrets/$s is absent — run ./install.sh (it is create-if-missing) BEFORE the window" ;; *) blocker "secrets/$s is missing — an adopted database needs its ORIGINAL secrets" ;; esac
  fi
done
kv "sudo -n available" "$(sudo -n true 2>/dev/null && echo yes || echo 'no (the secrets tar and uid-1001 files need it)')"

# ── 9. Disk and memory ───────────────────────────────────────────────────────
hdr "Disk and memory"
AVAIL_KB=$(df -Pk . 2>/dev/null | awk 'NR==2{print $4}')
kv "free here (KiB)"      "${AVAIL_KB:-?}"
[ -d /var/lib/docker ] && kv "free /var/lib/docker (KiB)" "$(df -Pk /var/lib/docker 2>/dev/null | awk 'NR==2{print $4}')"
command -v free >/dev/null && kv "memory" "$(free -m 2>/dev/null | awk 'NR==2{print $2" MiB total, "$7" MiB available"}')"
UP_FILES=""; UP_KB=""
if $DOCKER volume inspect "${PROJECT}_uploads-data" >/dev/null 2>&1; then
  st=$(uploads_volume_stats 2>/dev/null || true); UP_FILES=${st%%$'\t'*}; UP_KB=${st#*$'\t'}
  kv "uploads volume" "${UP_FILES:-?} files, ${UP_KB:-?} KiB"
fi
if [ -n "${DB_BYTES:-}" ] && [ -n "$AVAIL_KB" ]; then
  NEED_KB=$(disk_need_kb "$DB_BYTES" "$(( ${UP_KB:-0} * 1024 ))")
  kv "window needs (KiB)" "$NEED_KB  (2×DB + uploads + 1.5 GiB image + 2 GiB slack)"
  if [ "$AVAIL_KB" -lt "$NEED_KB" ]; then blocker "free space $AVAIL_KB KiB < needed $NEED_KB KiB — prune backups/ or grow the disk first"; else kv "disk verdict" "ok"; fi
fi

# ── 10. Uploads inventory ────────────────────────────────────────────────────
hdr "Uploads inventory"
if ! $DO_UPLOADS; then
  echo "  skipped (--no-uploads)"
elif ! $DOCKER volume inspect "${PROJECT}_uploads-data" >/dev/null 2>&1; then
  echo "  no uploads volume"
elif [ -z "$PG_CID" ]; then
  echo "  postgres down — cannot read the catalog"
else
  DISKL=$(mktemp); DBL=$(mktemp)
  uploads_list_volume > "$DISKL" 2>/dev/null || true
  uploads_list_catalog > "$DBL" 2>/dev/null || true
  CLS=$(uploads_classify "$DISKL" "$DBL")
  kv "cataloged"       "$(grep -c '^cataloged' <<<"$CLS")"
  kv "uncataloged"     "$(grep -c '^uncataloged' <<<"$CLS")  (flat=$(grep -c $'^uncataloged\tflat' <<<"$CLS") shared=$(grep -c $'^uncataloged\tshared' <<<"$CLS") threads=$(grep -c $'^uncataloged\tthreads' <<<"$CLS") other=$(grep -c $'^uncataloged\tother' <<<"$CLS"))"
  kv "missing-on-disk" "$(grep -c '^missing-on-disk' <<<"$CLS")"
  grep '^uncataloged' <<<"$CLS" | cut -f2- > "$UNCAT" || true
  grep '^missing-on-disk' <<<"$CLS" | cut -f2 > "$MISSING_DISK" || true
  kv "lists" "$UNCAT, $MISSING_DISK"
  NUNCAT=$(grep -c $'^uncataloged\t\(flat\|threads\|other\)' <<<"$CLS" || true)
  [ "${NUNCAT:-0}" = "0" ] || decision "$NUNCAT uncataloged upload file(s) outside uploads/shared/ — the current image answers 404 for them (bytes stay on disk). Decide before the window: catalog them in the product, move them under uploads/shared/, or accept. List: $UNCAT"
  NMISS=$(grep -c '^missing-on-disk' <<<"$CLS" || true)
  [ "${NMISS:-0}" = "0" ] || note "$NMISS catalog row(s) whose file is already missing on disk — pre-existing loss, not caused by the upgrade: $MISSING_DISK"
  rm -f "$DISKL" "$DBL"
fi

# ── 11. Data pre-checks (report mode) ────────────────────────────────────────
hdr "Data pre-checks for the pending set → $TARGET"
if [ -n "$PG_CID" ]; then
  run_checks report "$PENDING"
  [ -z "$CHECK_BLOCKERS" ]    || blocker "data pre-checks BLOCK: $(printf '%s' "$CHECK_BLOCKERS" | tr '\n' ' ') — the corresponding delta would abort inside the window"
  [ -z "$CHECK_UNAVAILABLE" ] || blocker "pre-check(s) could not be evaluated: $(printf '%s' "$CHECK_UNAVAILABLE" | tr '\n' ' ')"
  [ -z "$CHECK_ACKS" ]        || decision "typed acknowledgement(s) will be required: $(printf '%s' "$CHECK_ACKS" | tr '\n' ';')"
fi

# ── 12. Runtime ──────────────────────────────────────────────────────────────
hdr "Runtime"
kv "ingress /api/health/ready" "$(ingress_probe && echo ok || echo 'NOT ok')"
DEEP=$(deep_probe_body); kv "deep probe" "$( [ -n "$DEEP" ] && printf '%s' "$DEEP" | cut -c1-160 || echo '<empty>')"
for r in redis redis-cache; do
  n=$(compose exec -T "$r" sh -c 'REDISCLI_AUTH=$(cat /run/secrets/redis_password 2>/dev/null) redis-cli DBSIZE 2>/dev/null' 2>/dev/null | tr -d '\n' || true)
  kv "$r DBSIZE" "${n:-?}"
done
echo "  recent app log lines matching error|warn:"
compose logs --tail 200 app 2>/dev/null | grep -iE 'error|warn' | tail -n 10 | cut -c1-200 | sed 's/^/    /' || true

# ── 13. Verdict ──────────────────────────────────────────────────────────────
hdr "Verdict"
if [ -z "$BLOCKERS" ]; then echo "READY: no blockers for an upgrade to $TARGET"; else printf 'BLOCKERS (fix before the window):\n%s' "$BLOCKERS"; fi
[ -z "$DECISIONS" ] || printf 'DECISIONS (the operator chooses):\n%s' "$DECISIONS"
[ -z "$NOTES" ]     || printf 'NOTES (the upgrade converges these):\n%s' "$NOTES"
echo
log "report saved: $OUT"
[ -z "$BLOCKERS" ]
}

# A plain pipe (not `exec > >(tee …)`): the shell waits for tee, so the last
# lines always land in the file; the report's own status is what we exit with.
report 2>&1 | tee -a "$OUT"
exit "${PIPESTATUS[0]}"
