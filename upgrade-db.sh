#!/usr/bin/env bash
# =============================================================================
# upgrade-db.sh — guided, LOSSLESS upgrade of an EXISTING database to a shipped
# db/<version>. Defaults to the newest version this package carries.
#
#   ./upgrade-db.sh                          # newest shipped db/<version>
#   ./upgrade-db.sh 1.9.0                    # stop at a specific release
#   ./upgrade-db.sh --dry-run                # report only, change nothing
#   ./upgrade-db.sh --yes                    # non-interactive
#   ./upgrade-db.sh --adopt-schema-version 1.4.0   # adopted/restored DB
#
# This script adds NO migration logic of its own — it drives ./migrate.sh (and
# through it apply_migrations in lib.sh) with the pre-checks and post-checks a
# multi-release jump needs but that no single-release upgrade did:
#
#   • PRE:  refuses to guess ADOPT_SCHEMA_VERSION. Getting it too LOW re-runs
#           db/1.3.0/migrate-1.3.0.sql, which DELETEs org_role_permission and
#           org_permission_group_item rows. That is the single largest risk in
#           any upgrade and it lives in a release you already have.
#   • PRE:  when 1.9.0 is pending, checks cron_run_log for duplicate 'running'
#           rows. migrate-1.9.0.sql downgrades that collision to a NOTICE, so
#           psql exits 0, the file is stamped applied, and its unique index is
#           SILENTLY never created — the app then fails at runtime on
#           ON CONFLICT with no trace in the marker table.
#   • PRE:  when 1.11.0 is pending, checks invoice and org_invite for the
#           duplicates its two new UNIQUE indexes cannot span. That delta fails
#           CLOSED on them by design (it will not delete rows to make an index
#           fit), and duplicate PENDING invites are documented-normal on a VM
#           with invite churn — so this is the check that lets --dry-run tell
#           you, instead of a full backup and an aborted migration telling you.
#   • PRE:  snapshots row counts, so "no data was lost" is verified, not assumed.
#   • POST: asserts every object each release in scope should have created,
#           that grants reached the new tables, and that no table shrank.
#
# A REQUIRES-REVIEW delta in scope (currently 1.9.0's document_chunk FK cascade)
# is surfaced with its own header text and needs an explicit confirmation; the
# rolling ./update.sh path refuses those by design. Purely additive targets
# (e.g. 1.10.0, 1.11.0, 1.12.0) need no such gate.
#
# Afterwards, roll the matching app image with ./update.sh.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

ASSUME_YES=false
DRY_RUN=false
ADOPT=""
TARGET_VER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y)                ASSUME_YES=true ;;
    --dry-run)               DRY_RUN=true ;;
    --adopt-schema-version)  shift; [ $# -gt 0 ] || die "--adopt-schema-version needs a value (e.g. 1.4.0)"; ADOPT="${1#v}" ;;
    --adopt-schema-version=*) ADOPT="${1#*=}"; ADOPT="${ADOPT#v}" ;;
    -h|--help)               grep '^#' "$0" | sed 's/^# \{0,1\}//' | sed -n '2,40p'; exit 0 ;;
    -*)                      die "unknown flag: $1 (see --help)" ;;
    *)                       [ -z "$TARGET_VER" ] || die "give at most one target version (got '$TARGET_VER' and '$1')"
                             TARGET_VER="${1#v}" ;;
  esac
  shift
done

# Default target: the newest db/<version> this package ships. `sort -V` is the
# same ordering apply_migrations uses, so 1.10.0 correctly follows 1.9.0.
if [ -z "$TARGET_VER" ]; then
  TARGET_VER=$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -V | tail -n1)
  [ -n "$TARGET_VER" ] || die "no db/<version> directories found in this package"
fi
is_exact_semver "$TARGET_VER" || die "target must be a bare X.Y.Z release (got: $TARGET_VER)"
[ -d "db/$TARGET_VER" ] || die "db/$TARGET_VER is not shipped in this package.
  Available: $(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tr '\n' ' ')"

SNAPSHOT="backups/pre-${TARGET_VER}-rowcounts.txt"

# An operator-supplied version reaches SQL string context and picks a db/ folder.
[ -z "$ADOPT" ] || is_exact_semver "$ADOPT" \
  || die "--adopt-schema-version must be a bare X.Y.Z release (got: $ADOPT)"

# at_least VER — true when VER is within the upgrade's scope, i.e. the target is
# at or beyond it. Gates the per-release verification blocks below.
at_least() { ver_le "$1" "$TARGET_VER"; }

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
log "target db version       : $TARGET_VER"
log "current .env DB_VERSION : ${CUR_DB_VERSION:-<unset>}"
log "current .env APP_IMAGE  : ${CUR_APP_IMAGE:-<unset>}"
log "database                : $TABLES tables in schema public"

# Refuse to move DB_VERSION BACKWARDS. Without this, running the script with an
# older explicit target after ./.env has advanced would cap the migration below
# the image's schema — the silent-downgrade footgun.
if [ -n "$CUR_DB_VERSION" ] && ! ver_le "$CUR_DB_VERSION" "$TARGET_VER"; then
  die "./.env already targets DB_VERSION=$CUR_DB_VERSION, which is NEWER than $TARGET_VER.
  Refusing to lower it — that would cap migrations below the running image's
  schema. Re-run without a version argument to target the newest shipped
  release, or pass a target at or above $CUR_DB_VERSION."
fi

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

# pending_has FILE — true when FILE is in the pending set.
pending_has() { printf '%s\n' "$PENDING" | grep -qx "$1"; }

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
      ./upgrade-db.sh --adopt-schema-version <X.Y.Z>
  Too HIGH silently skips migrations the schema still needs.
  Too LOW re-runs db/1.3.0/migrate-1.3.0.sql, which DELETEs rows from
  org_role_permission and org_permission_group_item — real data loss.
  If unsure, check for a column/table added by a known release, e.g.:
      skill_scan          exists ⇒ schema is at least 1.5.0
      skill_qa_run        exists ⇒ at least 1.6.0
      skill.deployed      exists ⇒ at least 1.8.0
      job_execution       exists ⇒ at least 1.9.0
      session.mfa_verified_at    ⇒ at least 1.10.0
      organization_entitlement   ⇒ at least 1.11.0
      user.locked_until          ⇒ at least 1.12.0"

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

# ── 3. cron_run_log pre-check (only when 1.9.0 is actually pending) ─────────
# migrate-1.9.0.sql creates a partial UNIQUE index on cron_run_log(cron_job_id)
# WHERE status='running', wrapped in `EXCEPTION WHEN unique_violation THEN
# RAISE NOTICE`. A NOTICE is not an error: psql exits 0, lib.sh stamps the file
# applied, and the index is never created and never retried. Catch it BEFORE.
if pending_has "migrate-1.9.0.sql"; then
  hdr "Pre-check: cron_run_log (migrate-1.9.0.sql is pending)"
  if [ "$(q "select to_regclass('public.cron_run_log') is null")" = "t" ]; then
    log "cron_run_log does not exist yet — nothing to check"
  else
    DUPES=$(q "select count(*) from (select cron_job_id from cron_run_log where status='running' group by cron_job_id having count(*) > 1) d")
    assert_numeric "$DUPES" "the cron_run_log duplicate count"
    if [ "$DUPES" != "0" ]; then
      warn "$DUPES cron job(s) have MORE THAN ONE 'running' row:"
      psql_admin -c "select cron_job_id, count(*) from cron_run_log where status='running' group by cron_job_id having count(*) > 1;" </dev/null || true
      die "migrate-1.9.0.sql would SILENTLY skip creating
  cron_run_log_one_running_per_job (it downgrades the collision to a NOTICE, so
  the migration still reports success). The app would then fail at runtime with
  'no unique or exclusion constraint matching the ON CONFLICT specification'.
  Let the app's cleanupStaleLogs sweep finish, or resolve the duplicates by hand
  (keep the newest per job), then re-run this script."
    fi
    ok "no duplicate 'running' rows — the 1.9.0 claim index can be created"
  fi
fi

# ── 4. invoice / org_invite pre-check (only when 1.11.0 is actually pending) ─
# migrate-1.11.0.sql builds two partial UNIQUE indexes. Unlike 1.9.0's NOTICE
# handler it fails CLOSED on pre-existing duplicates — it will not delete rows
# to make an index fit, because ./migrate.sh is additive-only by contract. That
# is the right call, but on its own it surfaces as an aborted migration AFTER
# migrate.sh has taken a full backup and this script has already edited ./.env.
# Checking here is what lets --dry-run report it instead.
if pending_has "migrate-1.11.0.sql"; then
  hdr "Pre-check: invoice / org_invite (migrate-1.11.0.sql is pending)"

  # rel_ready TABLE COL… — true only when the table AND every named column are
  # present. An adopted schema may predate any of them; that must read as
  # "nothing to check yet", never as a check that silently passed.
  rel_ready() {
    local t="$1" c; shift
    [ "$(q "select to_regclass('public.$t') is not null")" = "t" ] || return 1
    for c in "$@"; do
      [ "$(q "select 1 from information_schema.columns where table_schema='public' and table_name='$t' and column_name='$c'")" = "1" ] || return 1
    done
    return 0
  }

  # (a) invoice_org_external_id_uq. A duplicate here is a real anomaly: it is a
  # replayed billing webhook, minted before the index existed to block it.
  if rel_ready invoice organization_id external_invoice_id issued_at; then
    INV_DUPES=$(q "select count(*) from (select 1 from invoice where external_invoice_id is not null group by organization_id, external_invoice_id having count(*) > 1) d")
    assert_numeric "$INV_DUPES" "the invoice duplicate count"
    if [ "$INV_DUPES" != "0" ]; then
      warn "$INV_DUPES (organization_id, external_invoice_id) group(s) hold duplicate invoices:"
      # Order by issued_at, not min(id): invoice.id is gen_random_uuid(), so the
      # smallest uuid is not the earliest row.
      psql_admin -c "select organization_id, external_invoice_id, count(*) as copies, min(issued_at) as earliest from invoice where external_invoice_id is not null group by 1,2 having count(*) > 1 order by 3 desc;" </dev/null || true
      die "migrate-1.11.0.sql will REFUSE to build invoice_org_external_id_uq over these.
  They are duplicate open invoices from replayed billing webhooks. Keep ONE row
  per group (normally the 'earliest' shown above), void or delete the rest, then
  re-run this script. The delta will not modify invoice rows for you —
  ./migrate.sh is additive-only by contract."
    fi
    ok "no duplicate (organization_id, external_invoice_id) invoices"
  else
    log "invoice is not present in its 1.11.0 shape yet — nothing to check"
  fi

  # (b) org_invite_pending_email_uq. A duplicate here is EXPECTED, not damage:
  # invite-service.create re-invites when a pending invite has EXPIRED, leaving
  # two rows with accepted_at IS NULL. Any VM with invite churn can hit this, so
  # say so plainly rather than implying corruption.
  if rel_ready org_invite organization_id invited_email accepted_at expires_at; then
    INVITE_DUPES=$(q "select count(*) from (select 1 from org_invite where accepted_at is null group by organization_id, invited_email having count(*) > 1) d")
    assert_numeric "$INVITE_DUPES" "the org_invite duplicate count"
    if [ "$INVITE_DUPES" != "0" ]; then
      warn "$INVITE_DUPES (organization_id, invited_email) group(s) hold more than one PENDING invite:"
      psql_admin -c "select organization_id, invited_email, count(*) as pending, max(expires_at) as keep_this_one from org_invite where accepted_at is null group by 1,2 having count(*) > 1 order by 3 desc;" </dev/null || true
      die "migrate-1.11.0.sql will REFUSE to build org_invite_pending_email_uq over these.
  This is NOT corruption — re-inviting after a pending invite EXPIRED leaves both
  rows pending, which is normal. Keep the newest per group (the 'keep_this_one'
  expires_at above) and delete the superseded rows, then re-run this script. The
  delta will not delete invite rows for you — ./migrate.sh is additive-only."
    fi
    ok "no duplicate pending invites — the 1.11.0 invite index can be created"
  else
    log "org_invite is not present in its 1.11.0 shape yet — nothing to check"
  fi
fi

# ── 5. Losslessness snapshot ────────────────────────────────────────────────
# Exact counts for every user table, so the post-check can prove nothing shrank.
# Written BEFORE any mutation.
hdr "Row-count snapshot"
snapshot_to() {
  psql_admin -tAF$'\t' -c "
    select table_name,
           (xpath('/row/c/text()',
                  query_to_xml(format('select count(*) as c from public.%I', table_name),
                               false, true, '')))[1]::text::bigint
    from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
    order by table_name;" </dev/null 2>/dev/null
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

# ── 6. Align DB_VERSION ─────────────────────────────────────────────────────
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
  ok "DB_VERSION=$TARGET_VER (previous ./.env saved as $ENV_BAK)"
else
  ok "DB_VERSION is already $TARGET_VER"
fi

# assert_version_alignment only enforces for an EXACT X.Y.Z image tag; moving
# tags (latest/main/sha-…) legitimately skip it and rely on DB_VERSION.
assert_version_alignment

# ── 7. Surface any REQUIRES-REVIEW delta, then migrate ──────────────────────
# lib.sh's has_pending_destructive prints the first flagged file apply_migrations
# would run. Only then do we arm the override — a purely additive upgrade
# (e.g. 1.9.0 → 1.10.0) never asks for it.
DESTRUCTIVE_FILE=$(has_pending_destructive || true)
if [ -n "$DESTRUCTIVE_FILE" ]; then
  hdr "Review required: $(basename "$DESTRUCTIVE_FILE")"
  warn "this delta is flagged REQUIRES-REVIEW — its own rationale follows:"
  sed -n '1,12p' "$DESTRUCTIVE_FILE" | sed 's/^/  /'
  cat <<'EOF'

  Reviewed for data loss across 1.5.0 → 1.12.0: there is no DROP TABLE, DROP
  COLUMN, TRUNCATE or unguarded DELETE anywhere in that range. Every NOT NULL
  column added carries a default, so existing rows are grandfathered without a
  table rewrite. The flag is about CHANGED BEHAVIOUR, not migration-time loss.

  ./migrate.sh will take its own mandatory backup before touching anything.
EOF
  confirm "Proceed, accepting the reviewed change above." "UPGRADE"
  export ALLOW_DESTRUCTIVE_MIGRATION=1
else
  hdr "Review"
  ok "no REQUIRES-REVIEW delta in scope — this upgrade is additive-only"
  log "(the same set is what ./update.sh's rolling path would apply)"
  confirm "Proceed with the upgrade to $TARGET_VER." "UPGRADE"
fi

hdr "Migration"
# migrate.sh takes the safety backup, re-checks the marker, applies every
# pending delta in semver order inside a single transaction per file, and
# re-applies db/<target>/grants.sql afterwards.
# Its post-migration health gate may fail here when a running app image
# predates the schema; migrate.sh exits 0 in that case by design.
./migrate.sh \
  || die "migration failed — the database was rolled back to its pre-migration state.
  Your backup is in ./backups. Inspect the error above, then re-run."

# ── 8. Post-migration verification ──────────────────────────────────────────
hdr "Verification"
FAILED=0
chk() { # chk DESCRIPTION EXPECTED ACTUAL REMEDY
  if [ "$3" = "$2" ]; then ok "$1"
  else warn "FAILED: $1 (expected '$2', got '$3')
  $4"; FAILED=$((FAILED + 1)); fi
}
chk_table() {
  chk "table $1 exists" "1" \
    "$(q "select 1 from information_schema.tables where table_schema='public' and table_name='$1'")" \
    "the migration that creates it did not fully apply — check the marker table."
}
chk_col() {
  chk "column $1.$2 exists" "1" \
    "$(q "select 1 from information_schema.columns where table_schema='public' and table_name='$1' and column_name='$2'")" \
    "the migration that adds it did not apply — check the marker table."
}

if at_least 1.5.0; then
  chk_table skill_scan; chk_table skill_attestation
  chk_col skill lifecycle_status
fi
if at_least 1.6.0; then
  chk_table skill_qa_run; chk_table skill_qa_check_result; chk_table skill_qa_certification
  chk_col skill qa_baseline_hash
fi
if at_least 1.7.0; then
  chk_table skill_qa_recording
  chk_col skill_qa_run fingerprint
fi
if at_least 1.8.0; then
  chk_col skill deployed
fi
if at_least 1.9.0; then
  chk_table org_policy_version; chk_table job_execution
  chk_table event_outbox;      chk_table audit_chain_head
  chk_col agent_deployment owner_user_id
  chk_col admin_audit_log prev_signature

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

  chk "document_chunk org FK is ON DELETE CASCADE" "c" \
    "$(q "select confdeltype from pg_constraint where conname='document_chunk_organization_id_organization_id_fk' and conrelid='public.document_chunk'::regclass")" \
    "the 0073 section did not apply."

  chk "audit chain head seeded" "1" \
    "$(q "select 1 from audit_chain_head where id=1")" \
    "insert it: INSERT INTO audit_chain_head (id, head_signature) VALUES (1,'') ON CONFLICT DO NOTHING;"

  # Grants: the reason apply_migrations re-runs grants.sql. A VM provisioned at
  # an older release would otherwise have no privileges on tables created since.
  chk "neo_gen can write job_execution" "t" \
    "$(q "select has_table_privilege('neo_gen','public.job_execution','INSERT')")" \
    "re-apply grants:  ./compose.sh exec -T postgres psql -U neogen_admin -d neogen < db/$TARGET_VER/grants.sql"
  chk "neo_gen can read the drizzle schema" "t" \
    "$(q "select has_schema_privilege('neo_gen','drizzle','USAGE')")" \
    "re-apply grants (see above) — the ADR-0038 block lives in db/$TARGET_VER/grants.sql."
fi
if at_least 1.10.0; then
  # Better Auth names this column in its explicit select list, so an image
  # carrying 0077 without this column 42703s inside getSession() — a total
  # login outage, not a degraded page.
  chk_col session mfa_verified_at
fi
if at_least 1.11.0; then
  # resolveOrgEntitlement sits on the org-quota path EVERY inference request
  # walks, so an image carrying 0078 without this table 42P01s there.
  chk_table organization_entitlement

  # Both indexes are PARTIAL, so information_schema cannot see them — probe
  # pg_indexes, exactly as the app's schema sentinels do. A missing index here
  # does not raise: it silently readmits the duplicate rows 0079 exists to
  # block, so nothing would surface it at runtime.
  chk "invoice replay-guard index present" "1" \
    "$(q "select 1 from pg_indexes where schemaname='public' and indexname='invoice_org_external_id_uq'")" \
    "duplicate (organization_id, external_invoice_id) invoices blocked it. Resolve
  them (see the pre-check above), then re-run ./migrate.sh."
  chk "pending-invite uniqueness index present" "1" \
    "$(q "select 1 from pg_indexes where schemaname='public' and indexname='org_invite_pending_email_uq'")" \
    "duplicate PENDING invites blocked it. Keep the newest per
  (organization_id, invited_email), then re-run ./migrate.sh."

  chk "neo_gen can write organization_entitlement" "t" \
    "$(q "select has_table_privilege('neo_gen','public.organization_entitlement','INSERT')")" \
    "re-apply grants:  ./compose.sh exec -T postgres psql -U neogen_admin -d neogen < db/$TARGET_VER/grants.sql"
fi
if at_least 1.12.0; then
  # Account lockout (0080). Once an admin enables the policy the sign-in route
  # reads user.locked_until on EVERY attempt, so an image carrying 0080 without
  # these columns 42703s there — a total login outage, as with 1.10.0's
  # session.mfa_verified_at. No grants check: these are columns on an existing
  # table, so they inherit "user"'s privileges rather than needing new ones.
  chk_col user failed_login_attempts
  chk_col user last_failed_login_at
  chk_col user locked_until
fi

# Every migration in scope must now be recorded.
while IFS= read -r f <&3; do
  [ -n "$f" ] || continue
  base=$(basename "$f")
  chk "$base recorded" "1" \
    "$(q "select 1 from public.deploy_schema_migrations where filename='${base//\'/\'\'}'")" \
    "re-run ./migrate.sh."
done 3< <(migration_files_through "$TARGET_VER")

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

# ── 9. Hand off ─────────────────────────────────────────────────────────────
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
if at_least 1.9.0 && pending_has "migrate-1.9.0.sql"; then
  log "  1. set AUDIT_SIGNING_KEY in ./.env.app (before the first audit row is written)"
  log "  2. roll the app onto the matching image:  ./update.sh"
else
  log "  roll the app onto the matching image:  ./update.sh"
fi
