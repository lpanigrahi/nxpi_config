#!/usr/bin/env bash
# =============================================================================
# upgrade-to-1.9.sh — guided, LOSSLESS upgrade of an EXISTING database to 1.9.0.
#
#   ./upgrade-to-1.9.sh                              # interactive
#   ./upgrade-to-1.9.sh --dry-run                    # report only, change nothing
#   ./upgrade-to-1.9.sh --yes                        # non-interactive
#   ./upgrade-to-1.9.sh --adopt-schema-version 1.4.0 # adopted/restored DB
#
# This script adds NO migration logic of its own — it drives ./migrate.sh (and
# through it apply_migrations in lib.sh) with the pre-checks and post-checks
# that a 1.4.0 → 1.9.0 jump needs but that no single-release upgrade did:
#
#   • PRE:  refuses to guess ADOPT_SCHEMA_VERSION. Getting it too LOW re-runs
#           db/1.3.0/migrate-1.3.0.sql, which DELETEs org_role_permission and
#           org_permission_group_item rows. That is the single largest risk in
#           this upgrade and it lives in a release you already have.
#   • PRE:  checks cron_run_log for duplicate 'running' rows. migrate-1.9.0.sql
#           downgrades that collision to a NOTICE, so psql exits 0, the file is
#           stamped applied, and its unique index is SILENTLY never created —
#           the app then fails at runtime on ON CONFLICT with no trace in the
#           marker table.
#   • PRE:  snapshots row counts, so "no data was lost" is verified, not assumed.
#   • POST: asserts every object 1.5.0–1.9.0 should have created, that grants
#           reached the new tables, and that no table shrank.
#
# The 1.9.0 delta is flagged REQUIRES-REVIEW because migration 0073 re-creates
# the document_chunk → organization FK as ON DELETE CASCADE (was SET NULL):
# deleting an organization will thereafter DELETE its RAG corpus instead of
# re-homing it. No rows are destroyed by the migration itself.
#
# Afterwards, roll the matching app image with ./update.sh.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

TARGET_VER="1.9.0"
SNAPSHOT="backups/pre-${TARGET_VER}-rowcounts.txt"
ASSUME_YES=false
DRY_RUN=false
ADOPT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y)                ASSUME_YES=true ;;
    --dry-run)               DRY_RUN=true ;;
    --adopt-schema-version)  shift; [ $# -gt 0 ] || die "--adopt-schema-version needs a value (e.g. 1.4.0)"; ADOPT="${1#v}" ;;
    --adopt-schema-version=*) ADOPT="${1#*=}"; ADOPT="${ADOPT#v}" ;;
    -h|--help)               grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,34p'; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done

# An operator-supplied version reaches SQL string context and picks a db/ folder.
[ -z "$ADOPT" ] || is_exact_semver "$ADOPT" \
  || die "--adopt-schema-version must be a bare X.Y.Z release (got: $ADOPT)"

# confirm PROMPT WORD — require WORD to be typed. --yes bypasses; a dry run
# never reaches a mutation, and a non-tty without --yes must not hang.
confirm() {
  local prompt="$1" word="$2" reply
  $ASSUME_YES && { log "$prompt — auto-confirmed (--yes)"; return 0; }
  [ -t 0 ] || die "$prompt
  Not a terminal and --yes was not given — refusing to proceed unattended."
  printf '%s\n  type %s to continue: ' "$prompt" "$word"
  read -r reply
  [ "$reply" = "$word" ] || die "aborted (got '$reply', expected '$word') — nothing was changed"
}

# q SQL — a single scalar, or nothing on failure (callers fail closed).
# stdin is /dev/null on purpose: `compose exec -T` attaches stdin and would
# otherwise DRAIN this script's own stdin — both the fd-3 loops below and the
# interactive `read` in confirm() depend on it staying intact.
q() { psql_admin -tAc "$1" </dev/null 2>/dev/null | tr -d '[:space:]' || true; }

init_docker
acquire_lock

# ── 1. Preflight and state report ───────────────────────────────────────────
hdr "Preflight"
[ -f .env ] || die "no ./.env here — run ./install.sh first"
[ -d "db/$TARGET_VER" ] || die "db/$TARGET_VER is missing from this package — you are on an older release of the deployment package; update it before upgrading."
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running — start the stack first (./install.sh)"
wait_healthy postgres 60 >/dev/null || die "postgres is not healthy"

TABLES=$(table_count)
assert_numeric "$TABLES" "the table count"
if [ "$TABLES" = "0" ]; then
  die "the database is EMPTY — there is nothing to upgrade.
  This script never initializes a database. For first-time provisioning run:
      DB_VERSION=$TARGET_VER ./install.sh"
fi

CUR_DB_VERSION=$(env_get .env DB_VERSION "")
CUR_APP_IMAGE=$(env_get .env APP_IMAGE "")
log "current .env DB_VERSION : ${CUR_DB_VERSION:-<unset>}"
log "current .env APP_IMAGE  : ${CUR_APP_IMAGE:-<unset>}"
log "database                : $TABLES tables in schema public"

ensure_migration_marker
MARKER_N=$(marker_row_count)
[ -n "$MARKER_N" ] || die "could not read the migration marker (postgres busy?) — re-run when stable"
log "migration marker        : $MARKER_N recorded"

# What apply_migrations WOULD run, computed the same way it computes it.
PENDING=""
while IFS= read -r f <&3; do
  [ -n "$f" ] || continue
  base=$(basename "$f")
  [ "$(q "select 1 from public.deploy_schema_migrations where filename = '${base//\'/\'\'}'")" = "1" ] \
    || PENDING="${PENDING}${base}"$'\n'
done 3< <(migration_files_through "$TARGET_VER")
PENDING=${PENDING%$'\n'}

hdr "Plan"
if [ -z "$PENDING" ]; then
  ok "no pending migrations — this database is already at $TARGET_VER"
  log "nothing to do. To roll the app image:  ./update.sh"
  exit 0
fi
log "migrations to apply (in order):"
printf '%s\n' "$PENDING" | sed 's/^/    /'

# ── 2. Adopted-marker guard ─────────────────────────────────────────────────
# An EMPTY marker means the schema was provisioned outside this harness (or
# restored from a dump taken before the marker existed). We must NOT guess its
# release: stamping too HIGH skips migrations the schema still needs; too LOW
# re-runs migrate-1.3.0.sql, which deletes RBAC rows.
if [ "$MARKER_N" = "0" ]; then
  hdr "Adopted database"
  warn "the migration marker is EMPTY — this schema was not provisioned by this harness."
  [ -n "$ADOPT" ] || die "refusing to guess the schema's actual release.
  Confirm which release this database's schema ALREADY matches and re-run:
      ./upgrade-to-1.9.sh --adopt-schema-version <X.Y.Z>
  Too HIGH silently skips migrations the schema still needs.
  Too LOW re-runs db/1.3.0/migrate-1.3.0.sql, which DELETEs rows from
  org_role_permission and org_permission_group_item — real data loss.
  If unsure, check for a table added by a known release, e.g.:
      skill_scan     exists ⇒ schema is at least 1.5.0
      skill_qa_run   exists ⇒ at least 1.6.0
      skill.deployed exists ⇒ at least 1.8.0"

  STAMPED=""; EXECUTED=""
  while IFS= read -r f <&3; do
    [ -n "$f" ] || continue
    base=$(basename "$f"); ver=${base#migrate-}; ver=${ver%.sql}
    if ver_le "$ver" "$ADOPT"; then STAMPED="${STAMPED}    $base"$'\n'
    else EXECUTED="${EXECUTED}    $base"$'\n'; fi
  done 3< <(migration_files_through "$TARGET_VER")

  log "with --adopt-schema-version $ADOPT:"
  printf '%s\n' "  STAMPED as already-present (NOT executed):"
  [ -n "$STAMPED" ] && printf '%s' "$STAMPED" || printf '    (none)\n'
  printf '%s\n' "  EXECUTED against your data:"
  [ -n "$EXECUTED" ] && printf '%s' "$EXECUTED" || printf '    (none)\n'
  confirm "Confirm this split is correct for your schema." "ADOPT"
  export ADOPT_SCHEMA_VERSION="$ADOPT"
fi

# ── 3. cron_run_log pre-check (the silent-skip landmine) ────────────────────
# migrate-1.9.0.sql creates a partial UNIQUE index on cron_run_log(cron_job_id)
# WHERE status='running', wrapped in `EXCEPTION WHEN unique_violation THEN
# RAISE NOTICE`. A NOTICE is not an error: psql exits 0, lib.sh stamps the file
# applied, and the index is never created and never retried. Catch it BEFORE.
hdr "Pre-check: cron_run_log"
if [ "$(q "select to_regclass('public.cron_run_log') is null")" = "t" ]; then
  log "cron_run_log does not exist yet — nothing to check"
else
  DUPES=$(q "select count(*) from (select cron_job_id from cron_run_log where status='running' group by cron_job_id having count(*) > 1) d")
  assert_numeric "$DUPES" "the cron_run_log duplicate count"
  if [ "$DUPES" != "0" ]; then
    warn "$DUPES cron job(s) have MORE THAN ONE 'running' row:"
    psql_admin -c "select cron_job_id, count(*) from cron_run_log where status='running' group by cron_job_id having count(*) > 1;" || true
    die "migrate-1.9.0.sql would SILENTLY skip creating
  cron_run_log_one_running_per_job (it downgrades the collision to a NOTICE, so
  the migration still reports success). The app would then fail at runtime with
  'no unique or exclusion constraint matching the ON CONFLICT specification'.
  Let the app's cleanupStaleLogs sweep finish, or resolve the duplicates by hand
  (keep the newest per job), then re-run this script."
  fi
  ok "no duplicate 'running' rows — the 1.9.0 claim index can be created"
fi

# ── 4. Losslessness snapshot ────────────────────────────────────────────────
# Exact counts for the tables 1.5.0–1.9.0 touch, plus every user table, so the
# post-check can prove nothing shrank. Written BEFORE any mutation.
hdr "Row-count snapshot"
snapshot_to() {
  psql_admin -tAF$'\t' -c "
    select table_name,
           (xpath('/row/c/text()',
                  query_to_xml(format('select count(*) as c from public.%I', table_name),
                               false, true, '')))[1]::text::bigint
    from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
    order by table_name;" 2>/dev/null
}
if $DRY_RUN; then
  log "(dry run) would write $SNAPSHOT"
else
  mkdir -p backups
  snapshot_to > "$SNAPSHOT" || die "could not snapshot row counts — refusing to migrate without a baseline"
  [ -s "$SNAPSHOT" ] || die "the row-count snapshot came back empty — refusing to migrate without a baseline"
  ok "baseline written: $SNAPSHOT ($(wc -l < "$SNAPSHOT" | tr -d ' ') tables)"
fi

if $DRY_RUN; then
  hdr "Dry run complete"
  log "no changes were made. Re-run without --dry-run to apply."
  exit 0
fi

# ── 5. Align DB_VERSION ─────────────────────────────────────────────────────
hdr "Target version"
if [ "$CUR_DB_VERSION" != "$TARGET_VER" ]; then
  log "./.env needs:  DB_VERSION=$TARGET_VER   (currently ${CUR_DB_VERSION:-<unset>})"
  confirm "This edits your ./.env." "EDIT"
  # Same content as ./.env, so same secrecy — do not inherit a loose umask.
  ENV_BAK=".env.bak-$(date +%Y%m%d-%H%M%S)"
  cp .env "$ENV_BAK" && chmod 600 "$ENV_BAK"
  if grep -qE '^[[:space:]]*DB_VERSION=' .env; then
    # BSD/GNU-portable in-place edit via a temp file (no sed -i flag juggling).
    awk -v v="$TARGET_VER" '/^[[:space:]]*DB_VERSION=/{print "DB_VERSION=" v; next} {print}' .env > .env.tmp \
      && mv .env.tmp .env
  else
    printf '\nDB_VERSION=%s\n' "$TARGET_VER" >> .env
  fi
  [ "$(env_get .env DB_VERSION "")" = "$TARGET_VER" ] || die "failed to set DB_VERSION in ./.env — set it by hand and re-run"
  ok "DB_VERSION=$TARGET_VER (previous ./.env saved alongside)"
else
  ok "DB_VERSION is already $TARGET_VER"
fi

# assert_version_alignment only enforces for an EXACT X.Y.Z image tag; moving
# tags (latest/main/sha-…) legitimately skip it and rely on DB_VERSION.
assert_version_alignment

# ── 6. Explain the semantic change, then migrate ────────────────────────────
hdr "Review: what 1.9.0 changes beyond adding objects"
cat <<'EOF'
  db/1.9.0/migrate-1.9.0.sql is flagged REQUIRES-REVIEW. Reviewed:

    • It DELETES NO ROWS. There is no DROP TABLE, DROP COLUMN, TRUNCATE, or
      unguarded DELETE anywhere in 1.5.0 → 1.9.0. Both NOT NULL columns added
      carry defaults, so existing rows are grandfathered without a rewrite.

    • It DOES change future behaviour: migration 0073 re-creates the
      document_chunk → organization foreign key as ON DELETE CASCADE
      (previously ON DELETE SET NULL). From then on, DELETING AN ORGANIZATION
      DELETES ITS ENTIRE RAG CORPUS instead of re-homing those chunks as
      personal/global. This is the reason for the flag.

    • It installs the admin_audit_log immutability trigger for the first time.
      Set AUDIT_SIGNING_KEY in ./.env.app BEFORE the first post-1.9.0 audit row
      is written — the hash chain starts from whatever key is active.

  ./migrate.sh will take its own mandatory backup before touching anything.
EOF
confirm "Proceed with the upgrade to $TARGET_VER." "UPGRADE"

hdr "Migration"
# migrate.sh takes the safety backup, re-checks the marker, applies every
# pending delta in semver order inside a single transaction per file, and
# re-applies db/1.9.0/grants.sql afterwards.
# Its post-migration health gate is EXPECTED to fail here: the running app
# image predates the schema. migrate.sh exits 0 in that case by design.
ALLOW_DESTRUCTIVE_MIGRATION=1 ./migrate.sh \
  || die "migration failed — the database was rolled back to its pre-migration state.
  Your backup is in ./backups. Inspect the error above, then re-run."

# ── 7. Post-migration verification ──────────────────────────────────────────
hdr "Verification"
FAILED=0
chk() { # chk DESCRIPTION EXPECTED ACTUAL REMEDY
  if [ "$3" = "$2" ]; then ok "$1"
  else warn "FAILED: $1 (expected '$2', got '$3')
  $4"; FAILED=$((FAILED + 1)); fi
}

# The landmine from step 3 — verify the index actually exists.
chk "cron claim index present" "1" \
  "$(q "select 1 from pg_class where relname='cron_run_log_one_running_per_job'")" \
  "migrate-1.9.0.sql skipped it via its NOTICE handler. Resolve duplicate
  'running' rows in cron_run_log, then create it by hand:
    CREATE UNIQUE INDEX CONCURRENTLY cron_run_log_one_running_per_job
      ON cron_run_log (cron_job_id) WHERE status = 'running';"

chk "audit immutability trigger active" "1" \
  "$(q "select 1 from pg_trigger where tgname='admin_audit_log_immutable_trg' and not tgisinternal")" \
  "re-apply the 0071 section of db/1.9.0/migrate-1.9.0.sql."

for t in org_policy_version job_execution event_outbox audit_chain_head \
         skill_scan skill_attestation skill_qa_run skill_qa_check_result \
         skill_qa_certification skill_qa_recording; do
  chk "table $t exists" "1" \
    "$(q "select 1 from information_schema.tables where table_schema='public' and table_name='$t'")" \
    "a migration between 1.5.0 and 1.9.0 did not fully apply — check the marker table."
done

check_col() {
  chk "column $1.$2 exists" "1" \
    "$(q "select 1 from information_schema.columns where table_schema='public' and table_name='$1' and column_name='$2'")" \
    "the migration that adds it did not apply — check the marker table."
}
check_col skill deployed
check_col skill lifecycle_status
check_col skill qa_baseline_hash
check_col skill_qa_run fingerprint
check_col agent_deployment owner_user_id
check_col admin_audit_log prev_signature

chk "document_chunk org FK is ON DELETE CASCADE" "c" \
  "$(q "select confdeltype from pg_constraint where conname='document_chunk_organization_id_organization_id_fk' and conrelid='public.document_chunk'::regclass")" \
  "the 0073 section did not apply."

chk "audit chain head seeded" "1" \
  "$(q "select 1 from audit_chain_head where id=1")" \
  "insert it: INSERT INTO audit_chain_head (id, head_signature) VALUES (1,'') ON CONFLICT DO NOTHING;"

# Grants: the reason apply_migrations re-runs grants.sql. A VM provisioned at an
# older release would otherwise have no privileges on tables created since.
chk "neo_gen can write job_execution" "t" \
  "$(q "select has_table_privilege('neo_gen','public.job_execution','INSERT')")" \
  "re-apply grants:  ./compose.sh exec -T postgres psql -U neogen_admin -d neogen < db/$TARGET_VER/grants.sql"
chk "neo_gen can read the drizzle schema" "t" \
  "$(q "select has_schema_privilege('neo_gen','drizzle','USAGE')")" \
  "re-apply grants (see above) — the ADR-0038 block lives in db/$TARGET_VER/grants.sql."

for v in 1.5.0 1.6.0 1.7.0 1.8.0 1.9.0; do
  chk "migrate-$v.sql recorded" "1" \
    "$(q "select 1 from public.deploy_schema_migrations where filename='migrate-$v.sql'")" \
    "re-run ./migrate.sh."
done

# ── The losslessness assertion ──────────────────────────────────────────────
hdr "Data preservation"
snapshot_to > "${SNAPSHOT}.after" || die "could not read post-migration row counts"
[ -s "${SNAPSHOT}.after" ] || die "post-migration row counts came back empty — verify by hand before rolling the app"
# awk exits 1 if ANY table shrank, printing one line per loss. `set +e` around
# it so a non-zero exit is data, not a script abort.
set +e
SHRANK=$(awk -F'\t' '
  NR==FNR { before[$1] = $2; next }
  ($1 in before) && ($2 + 0) < (before[$1] + 0) {
    printf "    %s: %s -> %s\n", $1, before[$1], $2; found = 1
  }
  END { exit(found ? 1 : 0) }
' "$SNAPSHOT" "${SNAPSHOT}.after")
SHRANK_RC=$?
set -e

if [ "$SHRANK_RC" != "0" ]; then
  warn "TABLES LOST ROWS during the upgrade:"
  printf '%s\n' "$SHRANK"
  warn "restore from the backup ./migrate.sh took:  ./restore.sh --yes backups/neogen-<newest>.dump"
  FAILED=$((FAILED + 1))
else
  ok "no table lost rows ($(wc -l < "$SNAPSHOT" | tr -d ' ') tables compared against the pre-upgrade baseline)"
fi

# ── 8. Hand off ─────────────────────────────────────────────────────────────
if [ "$FAILED" != "0" ]; then
  hdr "Upgrade INCOMPLETE"
  die "$FAILED verification check(s) failed — see the remedies above.
  The schema was migrated but is not fully consistent; do NOT roll the app image
  until these are resolved. Backups are in ./backups."
fi

hdr "Upgrade complete"
ok "database schema is at $TARGET_VER ($(table_count) tables); all data preserved"
log "baseline kept for reference: $SNAPSHOT (and ${SNAPSHOT}.after)"
log ""
log "NEXT:"
log "  1. set AUDIT_SIGNING_KEY in ./.env.app (before the first audit row is written)"
log "  2. roll the app onto the matching image:  ./update.sh"
