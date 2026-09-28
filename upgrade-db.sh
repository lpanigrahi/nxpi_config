#!/usr/bin/env bash
# =============================================================================
# upgrade-db.sh — guided, LOSSLESS upgrade of an EXISTING database to a shipped
# db/<version>. Defaults to the newest version this package carries.
#
#   ./upgrade-db.sh                          # newest shipped db/<version>
#   ./upgrade-db.sh 1.9.0                    # stop at a specific release
#   ./upgrade-db.sh --dry-run                # report only, change nothing
#   ./upgrade-db.sh --yes                    # non-interactive (acks still explicit)
#   ./upgrade-db.sh --ack DROP-AGENT-MEMORY  # pre-supply a typed acknowledgement
#   ./upgrade-db.sh --no-backup              # the caller already took the backup
#   ./upgrade-db.sh --run-dir DIR            # snapshots/expect files go here
#   ./upgrade-db.sh --skip-parity            # do not run ./schema-parity.sh afterwards
#   ./upgrade-db.sh --adopt-schema-version 1.4.0   # adopted/restored DB
#
# This script adds NO migration logic of its own — it drives ./migrate.sh (and
# through it apply_migrations in lib.sh) with the pre-checks and post-checks a
# multi-release jump needs but that no single-release upgrade did:
#
#   • PRE:  refuses to guess ADOPT_SCHEMA_VERSION. Getting it too LOW re-runs
#           db/1.3.0/migrate-1.3.0.sql, which DELETEs org_role_permission and
#           org_permission_group_item rows. That is the single largest risk in
#           any upgrade and it lives in a release you already have. The
#           sentinel table (SCHEMA_PROBES in lib.sh) says which release the
#           schema really matches.
#   • PRE:  runs every data pre-check in lib-checks.sh that the PENDING set
#           gates: the 1.9.0 cron NOTICE landmine, the 1.11.0 UNIQUE-index
#           duplicates, 1.25.0's fail-closed predicates (privilege-request
#           duplicates, team members outside their org, malformed role keys,
#           grants with a bad type / non-UUID / dangling resource, unknown
#           permission slugs, junction orphans), 1.29.0's app-role posture,
#           1.35.0's cron duplicates and agent_memory rows. Each delta would
#           abort INSIDE the window otherwise — after the backup and the .env
#           edit. A non-zero ack-class count (agent_memory rows) needs a typed
#           word, also with --yes (pass --ack WORD to pre-supply it).
#   • PRE:  snapshots row counts and the CUSTOM RBAC rows, so "no data was
#           lost" is verified, not assumed — against an explicit, printed list
#           of the changes the pending deltas are allowed to make
#           (expect_rows_for in lib-checks.sh: 1.22.0/1.25.0 delete the
#           materialised SYSTEM-role defaults, 1.25.0 rebuilds
#           org_resource_grant checksummed, 1.35.0 drops agent_memory,
#           1.25.0/1.27.0/1.40.1 seed reference rows).
#   • POST: asserts every sentinel object each release in scope introduces,
#           the load-bearing objects (catalog rows, chain head, partitions, RLS
#           posture, cron index, dropped orphans), that grants reached EVERY
#           table, that the custom RBAC rows are byte-identical, and that no
#           table shrank outside the expected list. Then ./schema-parity.sh
#           (when present) diffs the live catalog against db/<target>/schema.sql.
#
# Every REQUIRES-REVIEW delta in scope (1.9.0, 1.26.0, 1.29.0, 1.35.0) is
# surfaced with its own header and rationale before ONE confirmation; the
# rolling ./update.sh path refuses those by design. 1.29.0 additionally needs
# the privileged-pool decision to be explicit: POSTGRES_PRIVILEGED_URL_FILE set
# in ./.env and the neogen_priv role provisioned, or the KNOWN-LIMIT ack.
#
# optional-*.sql files (1.15.0, 1.16.0, 1.22.0) are NOT matched by the
# migrate-*.sql glob, so nothing here ever applies them (1.35.0 converges what
# two of them offered).
#
# Afterwards, roll the matching app image with ./update.sh — or let
# ./upgrade-release.sh drive this script, the image switch and the roll as one
# rehearsed, resumable, rollback-able window.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=lib-checks.sh
. ./lib-checks.sh

ASSUME_YES=false
DRY_RUN=false
ADOPT=""
TARGET_VER=""
NO_BACKUP=false
RUN_DIR="backups"
SKIP_PARITY=false
REUSE_BASELINE=false
ACKS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y)                ASSUME_YES=true ;;
    --dry-run)               DRY_RUN=true ;;
    --no-backup)             NO_BACKUP=true ;;
    --skip-parity)           SKIP_PARITY=true ;;
    # upgrade-release.sh --resume: the baseline in --run-dir was taken BEFORE
    # the first (partial) migration run; a fresh one would describe the
    # intermediate state and make the final comparison lie.
    --reuse-baseline)        REUSE_BASELINE=true ;;
    --ack)                   shift; [ $# -gt 0 ] || die "--ack needs a word"; ACKS="$ACKS $1" ;;
    --ack=*)                 ACKS="$ACKS ${1#*=}" ;;
    --run-dir)               shift; [ $# -gt 0 ] || die "--run-dir needs a directory"; RUN_DIR="$1" ;;
    --run-dir=*)             RUN_DIR="${1#*=}" ;;
    --adopt-schema-version)  shift; [ $# -gt 0 ] || die "--adopt-schema-version needs a value (e.g. 1.4.0)"; ADOPT="${1#v}" ;;
    --adopt-schema-version=*) ADOPT="${1#*=}"; ADOPT="${ADOPT#v}" ;;
    -h|--help)               sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    -*)                      die "unknown flag: $1 (see --help)" ;;
    *)                       [ -z "$TARGET_VER" ] || die "give at most one target version (got '$TARGET_VER' and '$1')"
                             TARGET_VER="${1#v}" ;;
  esac
  shift
done
mkdir -p "$RUN_DIR" 2>/dev/null || die "cannot create --run-dir $RUN_DIR"

# Default target: the newest db/<version> this package ships. `sort -V` is the
# same ordering apply_migrations uses, so 1.10.0 correctly follows 1.9.0.
if [ -z "$TARGET_VER" ]; then
  TARGET_VER=$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -V | tail -n1)
  [ -n "$TARGET_VER" ] || die "no db/<version> directories found in this package"
fi
is_exact_semver "$TARGET_VER" || die "target must be a bare X.Y.Z release (got: $TARGET_VER)"
[ -d "db/$TARGET_VER" ] || die "db/$TARGET_VER is not shipped in this package.
  Available: $(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tr '\n' ' ')"

SNAPSHOT="$RUN_DIR/pre-${TARGET_VER}-rowcounts.txt"
EXPECT="$RUN_DIR/pre-${TARGET_VER}-expected-changes.tsv"
CUSTOM_RBAC="$RUN_DIR/pre-${TARGET_VER}-custom-rbac.txt"

# An operator-supplied version reaches SQL string context and picks a db/ folder.
[ -z "$ADOPT" ] || is_exact_semver "$ADOPT" \
  || die "--adopt-schema-version must be a bare X.Y.Z release (got: $ADOPT)"

# at_least VER — true when VER is within the upgrade's scope, i.e. the target is
# at or beyond it. Gates the per-release verification blocks below.
at_least() { ver_le "$1" "$TARGET_VER"; }

# ack_given WORD — true when the operator pre-supplied WORD via --ack.
ack_given() { case " $ACKS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# q SQL — a single scalar, or nothing on failure (callers fail closed).
# (psql_scalar in lib.sh; stdin is /dev/null there on purpose — `compose exec
# -T` would otherwise DRAIN this script's own stdin, which the fd-3 loops below
# and the interactive `read` in confirm() depend on.)
q() { psql_scalar "$1"; }

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

# A dry run changes NOTHING — not even the marker table: read it if it exists.
if $DRY_RUN && ! marker_table_exists; then
  MARKER_N=0
  log "migration marker        : table absent (dry run leaves it absent)"
else
  ensure_migration_marker
  MARKER_N=$(marker_row_count)
  [ -n "$MARKER_N" ] || die "could not read the migration marker (postgres busy?) — re-run when stable"
  log "migration marker        : $MARKER_N recorded"
fi

# What apply_migrations WOULD run, computed the same way it computes it.
PENDING=$(pending_migrations "$TARGET_VER")

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
  The sentinel objects each release introduces, probed against THIS database
  (present ⇒ the schema is at least that release):
$(schema_probe_report | awk -F'\t' '$1=="highest-present"{print "      highest release whose sentinel exists: " $2; next} {printf "      %-8s %-8s %s\n", $1, $2, $3}')
  Releases without a unique sentinel (1.7.0, 1.21.0, 1.28.0, 1.34.0, 1.40.1)
  are safe to re-apply — choose the LOWER neighbour. ./schema-parity.sh <X.Y.Z>
  is the decisive test: it must report nothing in only-scratch."

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

# ── 3. Data pre-checks for the pending set (lib-checks.sh) ──────────────────
# Every delta that fails CLOSED on live data — 1.9.0's cron NOTICE landmine,
# 1.11.0's UNIQUE-index duplicates, 1.25.0's sixteen RAISE EXCEPTION sites,
# 1.29.0's app-role posture, 1.35.0's cron duplicates and agent_memory drop —
# does so from INSIDE its single-transaction apply, after the backup and the
# ./.env edit. lib-checks.sh mirrors each predicate as a read-only SELECT keyed
# on the pending file, so a --dry-run reports it a week early. A BLOCK or an
# unreadable check dies; an ACK-class count needs the operator's typed word.
hdr "Data pre-checks ($(printf '%s\n' "$PENDING" | grep -c . | tr -d ' ') pending delta(s))"
run_checks die "$PENDING"
if [ -n "$CHECK_ACKS" ]; then
  while read -r ack_name ack_word ack_count; do
    [ -n "$ack_name" ] || continue
    if ack_given "$ack_word"; then log "$ack_name: $ack_count row(s) — acknowledged via --ack $ack_word"; continue; fi
    warn "$ack_name reports $ack_count row(s) that the pending delta will DROP with the table."
    if $DRY_RUN; then log "(dry run) the real run will ask you to type $ack_word (or pass --ack $ack_word)"; continue; fi
    ASSUME_YES_SAVED=$ASSUME_YES; ASSUME_YES=false   # an ack is never auto-confirmed
    confirm "Accept losing these rows." "$ack_word"
    ASSUME_YES=$ASSUME_YES_SAVED
  done <<<"$CHECK_ACKS"
fi

# ── 4. The privileged-pool decision (only when 1.29.0 is pending) ───────────
# 1.29.0 FORCEs row-level security. The app's background cross-tenant sweeps
# run on a privileged pool that falls back to POSTGRES_URL when nothing else
# is configured — and then matches ZERO rows, silently. The bundle does not
# choose for you; this script refuses to let the choice stay implicit.
if pending_has "migrate-1.29.0.sql"; then
  hdr "Privileged pool (migrate-1.29.0.sql is pending)"
  PRIV_FILE=$(env_get .env POSTGRES_PRIVILEGED_URL_FILE "")
  if [ -n "$PRIV_FILE" ]; then
    [ -s secrets/postgres_privileged_url ] || die "POSTGRES_PRIVILEGED_URL_FILE is set in ./.env but secrets/postgres_privileged_url is missing — run ./install.sh (it generates it), then ./provision-privileged-role.sh"
    if [ "$(q "select 1 from pg_roles where rolname='neogen_priv' and rolbypassrls")" = "1" ]; then
      ok "neogen_priv (BYPASSRLS) exists and ./.env wires secrets/postgres_privileged_url into the app"
    elif $DRY_RUN; then
      warn "neogen_priv does not exist yet — run ./provision-privileged-role.sh before the real run"
    else
      die "POSTGRES_PRIVILEGED_URL_FILE is set but the neogen_priv role does not exist — run ./provision-privileged-role.sh first (idempotent), then re-run"
    fi
  else
    warn "POSTGRES_PRIVILEGED_URL_FILE is unset in ./.env: after this delta the expired-grant sweep and the
  knowledge/vector GC match zero rows until it is set (see .env.example, 'Privileged database pool').
  Reads still filter expiry at query time, so nothing is granted that should not be — this is
  housekeeping and observability, not privilege persistence."
    if ack_given KNOWN-LIMIT; then log "accepted as a known limit (--ack KNOWN-LIMIT)"
    elif $DRY_RUN; then log "(dry run) the real run will ask you to type KNOWN-LIMIT, or set the flag and provision the role"
    else
      ASSUME_YES_SAVED=$ASSUME_YES; ASSUME_YES=false
      confirm "Proceed WITHOUT a privileged pool (record this decision)." "KNOWN-LIMIT"
      ASSUME_YES=$ASSUME_YES_SAVED
    fi
  fi
fi

# ── 5. Losslessness snapshot ────────────────────────────────────────────────
# Exact counts for every user table, so the post-check can prove nothing shrank.
# Written BEFORE any mutation.
hdr "Row-count snapshot"
# custom_rbac_rows — the NON-system role permissions and pack items: the rows
# no delta may touch (1.22.0 and 1.25.0 delete materialised SYSTEM defaults
# only). Captured before, compared byte-for-byte after.
custom_rbac_rows() {
  psql_admin -tAF$'\t' -c "
    select 'role', r.id::text, rp.permission, rp.denied::text
      from org_role_permission rp join org_role r on r.id = rp.role_id where not r.is_system
    union all
    select 'pack', g.id::text, gi.permission, ''
      from org_permission_group_item gi join org_permission_group g on g.id = gi.group_id where not g.is_system
    order by 1, 2, 3;" </dev/null 2>/dev/null
}
# The allow-list the post-check will judge by — printed now so a dry run shows
# exactly which tables may change and why.
EXPECT_TEXT=$(expect_rows_for "$PENDING")
if [ -n "$EXPECT_TEXT" ]; then
  log "row-count changes the pending deltas are ALLOWED to make (everything else must be unchanged):"
  printf '%s\n' "$EXPECT_TEXT" | awk -F'\t' '{printf "    %-28s %-10s %s\n", $1, $2, $3}'
else
  log "the pending set is additive-only: no table may lose rows"
fi
if $DRY_RUN; then
  log "(dry run) would write $SNAPSHOT, $EXPECT and $CUSTOM_RBAC"
elif $REUSE_BASELINE && [ -s "$SNAPSHOT" ] && [ -s "$EXPECT" ]; then
  ok "reusing the baseline already in $RUN_DIR (--reuse-baseline): $SNAPSHOT, $EXPECT, $CUSTOM_RBAC"
else
  rowcount_snapshot > "$SNAPSHOT" || die "could not snapshot row counts — refusing to migrate without a baseline"
  [ -s "$SNAPSHOT" ] || die "the row-count snapshot came back empty — refusing to migrate without a baseline"
  printf '%s\n' "$EXPECT_TEXT" | sed '/^$/d' > "$EXPECT"
  if rel_ready org_role_permission && rel_ready org_permission_group_item; then
    custom_rbac_rows > "$CUSTOM_RBAC" || die "could not snapshot the custom RBAC rows"
  else
    : > "$CUSTOM_RBAC"
  fi
  ok "baseline written: $SNAPSHOT ($(wc -l < "$SNAPSHOT" | tr -d ' ') tables), $CUSTOM_RBAC ($(wc -l < "$CUSTOM_RBAC" | tr -d ' ') custom RBAC rows)"
fi

# ── 6. Align DB_VERSION ─────────────────────────────────────────────────────
hdr "Target version"
if $DRY_RUN; then
  log "(dry run) ./.env would get DB_VERSION=$TARGET_VER (currently ${CUR_DB_VERSION:-<unset>}); the review follows"
elif [ "$CUR_DB_VERSION" != "$TARGET_VER" ]; then
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
# tags (latest/main/sha-…) legitimately skip it and rely on DB_VERSION. A dry
# run evaluates it against the TARGET (the .env edit has not happened yet), so
# an exact-tag pin that would stop the real run is reported now, not after the
# edit. upgrade-release.sh switches APP_IMAGE only AFTER this script (so an
# abort restarts a still-bootable old image) and says so with
# NXPI_IMAGE_SWITCH_PENDING=1.
if [ -n "${NXPI_IMAGE_SWITCH_PENDING:-}" ]; then
  log "version alignment: skipped — the caller switches APP_IMAGE after the migration"
elif $DRY_RUN; then
  ALIGN_IMG=$(env_get .env APP_IMAGE ""); ALIGN_TAG=${ALIGN_IMG##*:}; ALIGN_TAG=${ALIGN_TAG#v}
  case "$ALIGN_IMG" in *@sha256:*) ALIGN_TAG="" ;; esac; case "$ALIGN_TAG" in */*) ALIGN_TAG="" ;; esac
  if [ -n "$ALIGN_TAG" ] && is_exact_semver "$ALIGN_TAG" && [ "$ALIGN_TAG" != "$TARGET_VER" ]; then
    warn "APP_IMAGE pins the exact tag $ALIGN_TAG: the real run will REFUSE at version alignment once DB_VERSION=$TARGET_VER — repin APP_IMAGE (or let upgrade-release.sh switch it) first"
  fi
else
  assert_version_alignment
fi

# ── 7. Surface EVERY REQUIRES-REVIEW delta, then migrate ────────────────────
# lib.sh's list_pending_destructive prints every flagged file apply_migrations
# would run — a 1.15.0 → 1.41.0 jump carries three. Only then do we arm the
# override — a purely additive upgrade (e.g. 1.9.0 → 1.10.0) never asks for it.
# review_notes FILE — what each flagged delta does to DATA, in one paragraph.
review_notes() {
  case "$(basename "$1")" in
    migrate-1.9.0.sql) cat <<'EOF'
  Reviewed for data loss across 1.5.0 → 1.15.0: no DROP TABLE, DROP COLUMN,
  TRUNCATE or unguarded DELETE; every NOT NULL column added carries a default.
  The flag is about CHANGED BEHAVIOUR: document_chunk's organization FK becomes
  ON DELETE CASCADE, so deleting an organization deletes its RAG corpus instead
  of re-homing it. Row-count preserving.
EOF
    ;;
    migrate-1.26.0.sql) cat <<'EOF'
  No row is deleted. audit_chain_head.chain_key becomes NOT NULL (the chain is
  keyed per organization from here) — the PREVIOUSLY RUNNING image sends none,
  so it cannot write ANY audit row afterwards: this is ROLL-FORWARD-ONLY. The
  matching image must be rolled right after the migration; the pre-upgrade dump
  is the only way back. Row-count preserving (one UPDATE keys the platform head).
EOF
    ;;
    migrate-1.29.0.sql) cat <<'EOF'
  No table, column, index or constraint changes; nothing is deleted. ENFORCEMENT
  changes: row-level security is ENABLED and FORCED on 26 tenant tables. The
  previously running image does not set app.current_org_id and would read EMPTY
  tables — roll-forward-only, same as 1.26.0. The privileged-pool decision above
  is what keeps the background sweeps working. Fully reversible in SQL, but the
  supported way back is the pre-upgrade dump.
EOF
    ;;
    migrate-1.35.0.sql) cat <<'EOF'
  47 legacy constraint names are RENAMED to their fresh-lineage equivalents;
  document_chunk's organization FK becomes ON DELETE CASCADE where it was SET
  NULL (deleting an organization then deletes its RAG corpus); RLS parity on
  assistant / organization_entitlement / knowledge_embedding_migration_state;
  the redundant IVFFlat index is dropped; and the ORPHAN table agent_memory is
  DROPPED (zero readers and writers in the app — its row count was acknowledged
  in the pre-checks above). The delta aborts, whole, on duplicate 'running'
  cron rows (pre-checked). Row counts: agent_memory disappears; nothing else.
EOF
    ;;
    *) printf '  (no packaged review note for %s — read its header above)\n' "$(basename "$1")" ;;
  esac
}
# Against the TARGET, not ./.env's current DB_VERSION: in a dry run the .env
# edit has not happened yet, and the review headers must show regardless.
DESTRUCTIVE_LIST=$(NXPI_TARGET_VERSION="$TARGET_VER" list_pending_destructive || true)
if [ -n "$DESTRUCTIVE_LIST" ]; then
  hdr "Review required: $(printf '%s\n' "$DESTRUCTIVE_LIST" | xargs -n1 basename | tr '\n' ' ')"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    warn "$(basename "$f") is flagged REQUIRES-REVIEW — its own rationale follows:"
    sed -n '1,12p' "$f" | sed 's/^/  /'
    echo; review_notes "$f"; echo
  done <<<"$DESTRUCTIVE_LIST"
  $NO_BACKUP || log "./migrate.sh will take its own mandatory backup before touching anything."
  if $DRY_RUN; then log "(dry run) the real run asks for ONE typed UPGRADE covering every delta above"
  else
    confirm "Proceed, accepting the reviewed change(s) above." "UPGRADE"
    export ALLOW_DESTRUCTIVE_MIGRATION=1
  fi
else
  hdr "Review"
  ok "no REQUIRES-REVIEW delta in scope — this upgrade is additive-only"
  log "(the same set is what ./update.sh's rolling path would apply)"
  $DRY_RUN || confirm "Proceed with the upgrade to $TARGET_VER." "UPGRADE"
fi

if $DRY_RUN; then
  hdr "Dry run complete"
  log "no changes were made. Re-run without --dry-run to apply."
  exit 0
fi

hdr "Migration"
# migrate.sh takes the safety backup (unless --no-backup: the caller already
# did), re-checks the marker, applies every pending delta in semver order
# inside a single transaction per file, and re-applies db/<target>/grants.sql.
# Its post-migration health gate may fail here when a running app image
# predates the schema; migrate.sh exits 0 in that case by design.
MIGRATE_ARGS=""; $NO_BACKUP && MIGRATE_ARGS="--no-backup"
# Sentinel for upgrade-release.sh: every gate above passed and the database is
# about to be written — a failure BEFORE this file exists changed nothing.
: > "$RUN_DIR/.migrate-invoked"
# shellcheck disable=SC2086
./migrate.sh $MIGRATE_ARGS \
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
if at_least 1.13.0; then
  # Org RBAC denials (0081). Read on every load of Organizations → Roles &
  # Permissions, so an image carrying ADR-0083 without it 42703s on that screen.
  chk_col org_role_permission denied

  # PARTIAL index — invisible to information_schema, so probe pg_indexes, the
  # same way the 1.11.0 checks above do.
  chk "org_role_permission denied index present" "1" \
    "$(q "select 1 from pg_indexes where schemaname='public' and indexname='org_role_permission_denied_idx'")" \
    "re-run ./migrate.sh."
fi
if at_least 1.14.0; then
  # Plugin acquisition (0090-0092). plugin_bundle.origin is selected on EVERY
  # render of the Plugins tab, list and detail alike, so an image ahead of this
  # delta 42703s there.
  chk_table plugin_source; chk_table plugin_source_entry
  chk_col plugin_bundle source_id
  chk_col plugin_bundle origin
  chk_col plugin_source last_sync_notes

  # New TABLES need new privileges — unlike 1.12.0's columns, which inherited
  # their table's. The delta GRANTs them itself and grants.sql re-asserts it;
  # this is the check that proves one of the two actually reached the role.
  chk "neo_gen can write plugin_source" "t" \
    "$(q "select has_table_privilege('neo_gen','public.plugin_source','INSERT')")" \
    "re-apply grants:  ./compose.sh exec -T postgres psql -U neogen_admin -d neogen < db/$TARGET_VER/grants.sql"
  chk "neo_gen can write plugin_source_entry" "t" \
    "$(q "select has_table_privilege('neo_gen','public.plugin_source_entry','INSERT')")" \
    "re-apply grants (see above)."
fi
if at_least 1.15.0; then
  # 0083-0089, the releases 1.13.0 and 1.14.0 both skipped. deleted_at is the
  # soft-delete filter on EVERY Plugins query, which is why a VM at 1.14.0
  # running the matching image fails that tab.
  chk_col plugin_bundle deleted_at
  chk_col skill_install enabled
  chk_col plugin_bundle_install enabled
  chk_col plugin_bundle_install reconciled_items
  chk_col model_pricing cached_input_cost_per_1m
  chk_col model_pricing cache_write_cost_per_1m

  # 0084 and 0088 add CHECK constraints keyed on pg_constraint BY NAME, so a
  # database that already had one takes a no-op — meaning absence here means
  # the delta did not run, not that it was skipped as redundant.
  chk "nav_visibility_override scope/org check present" "1" \
    "$(q "select 1 from pg_constraint where conname='nav_visibility_override_scope_org_check'")" \
    "re-run ./migrate.sh."
  chk "plugin_bundle status check present" "1" \
    "$(q "select 1 from pg_constraint where conname='plugin_bundle_status_check'")" \
    "re-run ./migrate.sh (0088 skips cleanly when plugin_bundle is absent — check that it exists)."
fi

# ── Version-agnostic checks for everything 1.16.0 and later ─────────────────
# One sentinel per release (SCHEMA_PROBES) instead of a hand-written block per
# release, plus the LOAD-BEARING objects whose absence takes a screen or the
# login down, and a grants sweep over EVERY table (a delta GRANTs its own new
# tables and grants.sql re-asserts; this proves one of the two reached the role).
hdr "Sentinels ($TARGET_VER)"
while IFS=$'\t' read -r pv pk po; do
  [ -n "$pv" ] || continue
  at_least "$pv" || continue
  ver_le 1.16.0 "$pv" || continue    # ≤ 1.15.0 is covered by the blocks above
  chk "$pv sentinel: $pk $po" "1" "$(q "$(schema_probe_sql "$pk" "$po")")" \
    "the delta that introduces it did not fully apply — check the marker table and re-run ./migrate.sh."
done <<<"$SCHEMA_PROBES"

if at_least 1.25.0; then
  chk "permission_catalog is populated (≥ 78 slugs)" "t" \
    "$(q "select (select count(*) from permission_catalog) >= 78")" \
    "0012's seed did not land (or 1.40.1's repair is pending) — the RBAC matrix renders empty and every grant edit fails 23503."
  chk "org_resource_grant is partitioned" "p" \
    "$(q "select relkind from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='org_resource_grant'")" \
    "0015's rebuild did not complete."
  chk "org_resource_grant has its six partitions" "6" \
    "$(q "select count(*) from pg_inherits where inhparent='public.org_resource_grant'::regclass")" \
    "0015's partitions are missing."
  chk "org_role.key is NOT NULL" "NO" \
    "$(q "select is_nullable from information_schema.columns where table_schema='public' and table_name='org_role' and column_name='key'")" \
    "0009 did not apply."
fi
if at_least 1.26.0; then
  chk "audit chain head is keyed" "1" \
    "$(q "select 1 from information_schema.columns where table_schema='public' and table_name='audit_chain_head' and column_name='chain_key' and is_nullable='NO'")" \
    "0020 did not apply."
fi
if at_least 1.29.0; then
  chk "≥ 26 tables FORCE row-level security" "t" \
    "$(q "select (select count(*) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relforcerowsecurity) >= 26")" \
    "1.29.0's ENABLE/FORCE statements did not land — tenant data is readable across organizations by the app role."
  chk "≥ 26 tenant_isolation policies" "t" \
    "$(q "select (select count(*) from pg_policies where schemaname='public' and policyname='tenant_isolation') >= 26")" \
    "1.29.0's CREATE POLICY statements did not land."
fi
if at_least 1.35.0; then
  chk "cron claim index present (1.35.0 converges legacy 0072)" "1" \
    "$(q "select 1 from pg_indexes where schemaname='public' and indexname='cron_run_log_one_running_per_job'")" \
    "resolve duplicate 'running' cron rows and re-run ./migrate.sh."
  chk "redundant IVFFlat index is gone" "" \
    "$(q "select 1 from pg_indexes where schemaname='public' and indexname='knowledge_embeddings_embedding_ivfflat_idx'")" \
    "0036's DROP INDEX did not run."
  chk "orphan agent_memory table is gone" "" \
    "$(q "select 1 from information_schema.tables where table_schema='public' and table_name='agent_memory'")" \
    "0036's DROP TABLE did not run."
  chk "document_chunk org FK is ON DELETE CASCADE" "c" \
    "$(q "select confdeltype from pg_constraint where conname='document_chunk_organization_id_organization_id_fk' and conrelid='public.document_chunk'::regclass")" \
    "0036's convergence of legacy 0073 did not apply."
fi

hdr "Grants (every table)"
# admin_audit_log_quarantine is SELECT-only for the app role by design (1.33.0
# grants.sql REVOKEs writes); deploy_schema_migrations is the scripts' own.
NO_INSERT=$(q "select string_agg(c.relname, ' ') from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind in ('r','p')
    and c.relname not in ('admin_audit_log_quarantine','deploy_schema_migrations')
    and not has_table_privilege('neo_gen', c.oid, 'INSERT')")
NO_SELECT=$(q "select string_agg(c.relname, ' ') from pg_class c join pg_namespace n on n.oid=c.relnamespace
  where n.nspname='public' and c.relkind in ('r','p') and c.relname <> 'deploy_schema_migrations'
    and not has_table_privilege('neo_gen', c.oid, 'SELECT')")
chk "neo_gen can INSERT into every app table" "" "$NO_INSERT" \
  "re-apply grants:  ./compose.sh exec -T postgres psql -U neogen_admin -d neogen < db/$TARGET_VER/grants.sql"
chk "neo_gen can SELECT from every table" "" "$NO_SELECT" "re-apply grants (see above)."
chk "neo_gen can use the drizzle schema" "t" "$(q "select has_schema_privilege('neo_gen','drizzle','USAGE')")" "re-apply grants (see above)."

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
rowcount_snapshot > "${SNAPSHOT}.after" || die "could not read post-migration row counts"
[ -s "${SNAPSHOT}.after" ] || die "post-migration row counts came back empty — verify by hand before rolling the app"
# rowcount_compare judges every table against the printed allow-list: `!!`
# lines are violations (exit 1), `ok <kind>` lines are the expected changes
# with their reason, `new`/`grew` are informational. `set +e` around it so a
# non-zero exit is data, not a script abort.
set +e
COMPARE=$(rowcount_compare "$SNAPSHOT" "${SNAPSHOT}.after" "$EXPECT")
COMPARE_RC=$?
set -e
printf '%s\n' "$COMPARE" | grep -E '^(ok|!!|new|grew)' | sed 's/^/    /' || true
printf '%s\n' "$COMPARE" | grep -E '^unchanged' | sed 's/^/    /' || true
if [ "$COMPARE_RC" = "2" ]; then
  warn "could not compare row counts (a snapshot is missing) — verify by hand"; FAILED=$((FAILED + 1))
elif [ "$COMPARE_RC" != "0" ]; then
  warn "TABLES LOST ROWS OUTSIDE THE EXPECTED LIST (the '!!' lines above)"
  warn "restore from the pre-upgrade backup:  ./restore.sh --yes backups/neogen-<newest>.dump"
  FAILED=$((FAILED + 1))
else
  ok "no unexpected row loss ($(wc -l < "$SNAPSHOT" | tr -d ' ') tables compared; expected changes printed above)"
fi
if [ -s "$CUSTOM_RBAC" ]; then
  custom_rbac_rows > "${CUSTOM_RBAC}.after" || die "could not re-read the custom RBAC rows"
  if cmp -s "$CUSTOM_RBAC" "${CUSTOM_RBAC}.after"; then
    ok "custom (non-system) role permissions and pack items are byte-identical ($(wc -l < "$CUSTOM_RBAC" | tr -d ' ') rows)"
  else
    warn "CUSTOM RBAC ROWS CHANGED — the deltas may only touch is_system rows:"
    diff "$CUSTOM_RBAC" "${CUSTOM_RBAC}.after" | head -n 40 | sed 's/^/    /' || true
    FAILED=$((FAILED + 1))
  fi
fi

# ── Catalog parity against the shipped schema ───────────────────────────────
if [ -x ./schema-parity.sh ] && ! $SKIP_PARITY; then
  hdr "Schema parity vs db/$TARGET_VER/schema.sql"
  if ./schema-parity.sh "$TARGET_VER" --out "$RUN_DIR/parity-$TARGET_VER"; then
    ok "live catalog matches db/$TARGET_VER/schema.sql"
  else
    warn "schema-parity.sh reported differences (see $RUN_DIR/parity-$TARGET_VER/summary.txt)"
    FAILED=$((FAILED + 1))
  fi
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
