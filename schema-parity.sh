#!/usr/bin/env bash
# =============================================================================
# schema-parity.sh — does the LIVE database's catalog equal what db/<ver>/
# schema.sql builds? And, in rehearsal mode, does the pending migration set
# take a copy of the live data to exactly that catalog?
#
#   ./schema-parity.sh [VER] [--out DIR] [--accept FILE] [--with-seed] [--keep]
#   ./schema-parity.sh --rehearse DUMP --target VER [--out DIR] [--ack WORD…]
#
# Parity mode (default VER = DB_VERSION in ./.env): starts a throwaway postgres
# from the LIVE postgres image (no network, tmpfs — SCRATCH_DATA_DIR=/path for
# a disk-backed one), loads db/<VER>/schema.sql + grants.sql into it, renders
# ./parity-inventory.sql on both databases, and classifies the difference:
#   only-scratch  objects the live database is MISSING       → hard finding
#   only-live     objects the live database has EXTRA        → hard finding
#   advisory      name-only index/constraint renames, runtime month partitions
#                 of authz_decision_log, operator-accepted patterns (--accept)
# Never compared: the drizzle journal rows, deploy_schema_migrations.
# Run it BEFORE a release upgrade against the current version (proves the VM
# really is at the release it claims; the only-live lines are what the upgrade
# must reconcile) and AFTER against the target (must be clean).
#
# Rehearsal mode: pg_restores DUMP (a fresh ./backup.sh dump) into the scratch,
# applies grants.sql for the dump's release, runs every pending migrate-*.sql
# there through the SAME apply_migrations the live path uses, compares row
# counts against expect_rows_for's allow-list, and then runs the parity check
# against db/<target>. It proves, on the real data, that 1.25.0's fail-closed
# predicates pass, that the checksummed rebuild matches, and that the final
# catalog equals the target — before the live database is touched.
#
# Exit: 0 parity/rehearsal clean · 3 differences or rehearsal findings ·
#       1 error. Output under --out (default backups/parity-<ver>-<ts>/).
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh
# shellcheck source=lib-checks.sh
. ./lib-checks.sh
# shellcheck source=lib-parity.sh
. ./lib-parity.sh

VER=""; OUT=""; ACCEPT=""; WITH_SEED=false; KEEP=false; REHEARSE=""; TARGET=""; ACKS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out)       shift; OUT="${1:-}" ;;
    --out=*)     OUT="${1#*=}" ;;
    --accept)    shift; ACCEPT="${1:-}" ;;
    --accept=*)  ACCEPT="${1#*=}" ;;
    --with-seed) WITH_SEED=true ;;
    --keep)      KEEP=true ;;
    --rehearse)  shift; REHEARSE="${1:-}" ;;
    --rehearse=*) REHEARSE="${1#*=}" ;;
    --target)    shift; TARGET="${1:-}" ;;
    --target=*)  TARGET="${1#*=}" ;;
    --ack)       shift; ACKS="$ACKS ${1:-}" ;;
    --ack=*)     ACKS="$ACKS ${1#*=}" ;;
    -h|--help)   sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    -*)          die "unknown flag: $1 (see --help)" ;;
    *)           [ -z "$VER" ] || die "give at most one version"; VER="${1#v}" ;;
  esac
  shift
done

init_docker
[ -f .env ] || die "no ./.env here — run from an installed deployment directory"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running — the live side of the comparison needs it"
PG_IMAGE=$($DOCKER inspect --format '{{.Config.Image}}' "$PG_CID")
TS=$(date +%Y%m%d-%H%M%S)
umask 077

# ── Parity mode ──────────────────────────────────────────────────────────────
if [ -z "$REHEARSE" ]; then
  [ -n "$VER" ] || VER=$(resolved_db_version) || die "cannot resolve a version — pass one (e.g. 1.41.0) or set DB_VERSION in ./.env"
  is_exact_semver "$VER" || die "version must be bare X.Y.Z (got: $VER)"
  [ -f "db/$VER/schema.sql" ] || die "db/$VER/schema.sql is not shipped here"
  [ -n "$OUT" ] || OUT="backups/parity-${VER}-${TS}"
  mkdir -p "$OUT"
  hdr "Schema parity: live database vs db/$VER/schema.sql"
  log "scratch image: $PG_IMAGE   output: $OUT"

  scratch_pg_start "$PG_IMAGE"
  trap '$KEEP || scratch_pg_stop' EXIT
  log "loading db/$VER/schema.sql + grants.sql into the scratch…"
  scratch_load_sql "db/$VER/schema.sql" >/dev/null || die "schema.sql failed to load into the scratch (see above)"
  scratch_load_sql "db/$VER/grants.sql" >/dev/null || die "grants.sql failed to load into the scratch"
  if $WITH_SEED; then
    scratch_load_sql "db/$VER/seed.sql" -v admin_email=parity@example.invalid -v admin_password_hash=x >/dev/null \
      || warn "seed.sql did not load into the scratch — reference-row comparison skipped"
  fi

  log "rendering the inventory on both sides…"
  PSQL_TARGET=scratch psql_admin -tA < parity-inventory.sql | parity_filter /dev/stdin > "$OUT/scratch.inv" 2> "$OUT/.adv.scratch"
  psql_admin -tA < parity-inventory.sql | parity_filter /dev/stdin > "$OUT/live.inv" 2> "$OUT/.adv.live"
  [ -s "$OUT/scratch.inv" ] || die "the scratch inventory is empty — parity-inventory.sql did not run"
  [ -s "$OUT/live.inv" ]    || die "the live inventory is empty"
  parity_classify "$OUT/scratch.inv" "$OUT/live.inv" "$OUT" "$ACCEPT"
  sed 's/^/live: /' "$OUT/.adv.live" >> "$OUT/advisory.txt"; rm -f "$OUT/.adv.scratch" "$OUT/.adv.live"

  if $WITH_SEED; then
    hdr "Reference rows (seed.sql vs live)"
    for q in "select slug from permission_catalog order by 1" "select coalesce(name, id::text) from sod_rule where organization_id is null order by 1"; do
      PSQL_TARGET=scratch psql_admin -tAc "$q" </dev/null 2>/dev/null | sort > "$OUT/.ref.scratch" || true
      psql_admin -tAc "$q" </dev/null 2>/dev/null | sort > "$OUT/.ref.live" || true
      if [ -s "$OUT/.ref.scratch" ]; then
        MISSING_REF=$(comm -23 "$OUT/.ref.scratch" "$OUT/.ref.live" | wc -l | tr -d ' ')
        [ "$MISSING_REF" = "0" ] && ok "live has every reference row of: $q" || { warn "$MISSING_REF reference row(s) missing live for: $q"; comm -23 "$OUT/.ref.scratch" "$OUT/.ref.live" >> "$OUT/only-scratch.txt"; }
      fi
    done
    rm -f "$OUT/.ref.scratch" "$OUT/.ref.live"
    parity_classify "$OUT/scratch.inv" "$OUT/live.inv" "$OUT/.reclass" "$ACCEPT" >/dev/null 2>&1 || true   # keep summary consistent
    rm -rf "$OUT/.reclass"
  fi

  hdr "Result"
  cat "$OUT/summary.txt"
  if [ -s "$OUT/only-scratch.txt" ]; then warn "objects the LIVE database is MISSING (only-scratch):"; sed 's/^/    /' "$OUT/only-scratch.txt" | head -n 60; fi
  if [ -s "$OUT/only-live.txt" ];    then warn "objects the LIVE database has EXTRA (only-live):";     sed 's/^/    /' "$OUT/only-live.txt"    | head -n 60; fi
  if [ -s "$OUT/advisory.txt" ];     then log  "advisory ($(grep -c . "$OUT/advisory.txt" | tr -d ' ') lines, see $OUT/advisory.txt):"; sed 's/^/    /' "$OUT/advisory.txt" | head -n 20; fi
  if parity_verdict "$OUT"; then ok "live catalog matches db/$VER/schema.sql"; exit 0
  else warn "differences found — full lists under $OUT"; exit 3; fi
fi

# ── Rehearsal mode ───────────────────────────────────────────────────────────
[ -s "$REHEARSE" ] || die "--rehearse needs an existing dump file (from ./backup.sh)"
[ -n "$TARGET" ] || TARGET=$(find db -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V | tail -n1)
is_exact_semver "$TARGET" || die "--target must be bare X.Y.Z (got: $TARGET)"
[ -f "db/$TARGET/schema.sql" ] || die "db/$TARGET is not shipped here"
CUR=$(resolved_db_version) || die "cannot resolve the CURRENT version from ./.env (set DB_VERSION)"
[ -n "$OUT" ] || OUT="backups/rehearsal-${TARGET}-${TS}"
mkdir -p "$OUT"
hdr "Rehearsal: $REHEARSE ($CUR) → $TARGET on a scratch copy"
log "scratch image: $PG_IMAGE   output: $OUT   (the live database is not touched)"

scratch_pg_start "$PG_IMAGE"
trap '$KEEP || scratch_pg_stop' EXIT
log "restoring the dump into the scratch…"
$DOCKER cp "$REHEARSE" "$SCRATCH_CID:/tmp/rehearse.dump"
$DOCKER exec "$SCRATCH_CID" pg_restore -U neogen_admin -d neogen --no-owner --no-privileges -j 2 /tmp/rehearse.dump >"$OUT/restore.log" 2>&1 \
  || warn "pg_restore reported errors (see $OUT/restore.log) — usually harmless ownership notices; continuing"
scratch_load_sql "db/$CUR/grants.sql" >/dev/null || die "grants.sql ($CUR) failed on the scratch"

export PSQL_TARGET=scratch NXPI_TARGET_VERSION="$TARGET"
TABLES=$(table_count); [ "${TABLES:-0}" != "0" ] || die "the restored scratch has no tables — is $REHEARSE a valid dump?"
ok "scratch restored: $TABLES tables, $(user_count) users"

PENDING=$(pending_migrations "$TARGET")
log "pending on the scratch: $(printf '%s\n' "$PENDING" | grep -c . | tr -d ' ') delta(s)"
hdr "Pre-checks on the scratch"
run_checks report "$PENDING"
checks_verdict || { warn "pre-checks BLOCK on this data — the live window would abort at the same point"; exit 3; }
if [ -n "$CHECK_ACKS" ]; then
  while read -r an aw ac; do
    [ -n "$an" ] || continue
    case " $ACKS " in *" $aw "*) log "$an: $ac row(s) acknowledged (--ack $aw)" ;; *) warn "$an: $ac row(s) — the live run will require --ack $aw (rehearsal continues)" ;; esac
  done <<<"$CHECK_ACKS"
fi

hdr "Migrating the scratch copy"
rowcount_snapshot > "$OUT/rowcounts.before"
expect_rows_for "$PENDING" > "$OUT/expected-changes.tsv"
export ALLOW_DESTRUCTIVE_MIGRATION=1
if apply_migrations; then ok "every pending delta applied on the scratch"; else ok "nothing was pending on the scratch"; fi
rowcount_snapshot > "$OUT/rowcounts.after"
set +e
CMP=$(rowcount_compare "$OUT/rowcounts.before" "$OUT/rowcounts.after" "$OUT/expected-changes.tsv"); CMP_RC=$?
set -e
printf '%s\n' "$CMP" | grep -E '^(ok|!!|new|grew|unchanged)' | sed 's/^/    /' || true
[ "$CMP_RC" = "0" ] && ok "row counts changed only as expected" || warn "UNEXPECTED row-count change on the scratch (see '!!' lines)"

hdr "Parity of the migrated scratch vs db/$TARGET/schema.sql"
# The migrated scratch is now the "live" side; a second scratch holds the target schema.
psql_admin -tA < parity-inventory.sql | parity_filter /dev/stdin > "$OUT/migrated.inv" 2>/dev/null
MIGRATED_CID="$SCRATCH_CID"
unset PSQL_TARGET NXPI_TARGET_VERSION
SCRATCH_CID=""
scratch_pg_start "$PG_IMAGE"
TARGET_CID="$SCRATCH_CID"
trap '$KEEP || { $DOCKER rm -f "$MIGRATED_CID" "$TARGET_CID" >/dev/null 2>&1; }' EXIT
scratch_load_sql "db/$TARGET/schema.sql" >/dev/null || die "db/$TARGET/schema.sql failed to load"
scratch_load_sql "db/$TARGET/grants.sql" >/dev/null || die "db/$TARGET/grants.sql failed to load"
PSQL_TARGET=scratch psql_admin -tA < parity-inventory.sql | parity_filter /dev/stdin > "$OUT/target.inv" 2>/dev/null
parity_classify "$OUT/target.inv" "$OUT/migrated.inv" "$OUT" "$ACCEPT"
cat "$OUT/summary.txt"
if [ -s "$OUT/only-scratch.txt" ]; then warn "the MIGRATED copy is MISSING (only-scratch):"; sed 's/^/    /' "$OUT/only-scratch.txt" | head -n 60; fi
if [ -s "$OUT/only-live.txt" ];    then warn "the MIGRATED copy has EXTRA (only-live):";     sed 's/^/    /' "$OUT/only-live.txt"    | head -n 60; fi

hdr "Rehearsal result"
RC=0
[ "$CMP_RC" = "0" ] || RC=3
parity_verdict "$OUT" || RC=3
if [ "$RC" = "0" ]; then ok "the pending set takes this data to db/$TARGET cleanly — the live window can proceed"
else warn "rehearsal found differences — fix them before the live window (details under $OUT)"; fi
exit $RC
