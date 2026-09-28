#!/usr/bin/env bash
# =============================================================================
# db-bundle-lint.sh — static checks over every db/<version>/ bundle. No docker,
# no database: the things that can be known from the files alone.
#
#   bash tests/db-bundle-lint.sh                       # lint ./db
#   bash tests/db-bundle-lint.sh --db DIR              # lint another tree (tests)
#   bash tests/db-bundle-lint.sh --expect-flagged "1.3.0 1.9.0 …"
#
# What it asserts, and why each one matters to apply_migrations (lib.sh):
#   • folder names are bare X.Y.Z (ver_le / sort -V cannot order anything else)
#   • every folder is WHOLE: schema.sql, grants.sql, seed.sql, migrate-<v>.sql
#     (the lowest folder is the lineage base and legitimately has no delta)
#   • the REQUIRES-REVIEW marker, where present, sits in the first SIX lines —
#     apply_migrations greps `head -n 6`; a lower marker is invisible and the
#     delta rides update.sh's rolling path unreviewed
#   • the flagged set equals the EXPECTED set below — a new flagged release is
#     a deliberate change to this file, never a surprise
#   • the header chain is contiguous: `-- migrate-Y.sql — … X → Y` where X is
#     the previous folder in sort -V order (this is what catches a skipped
#     patch release such as 1.40.1)
#   • psql hygiene: no \connect / \c / \! / \i / \ir meta-commands (they run
#     inside `compose exec … psql -1`); no inner BEGIN/COMMIT in any delta
#     newer than 1.14.0 (an inner COMMIT splits the single-transaction apply —
#     the frozen 1.3.0–1.14.0 files carry them historically); trailing newline
#   • seed.sql takes :'admin_email' and :'admin_password_hash'; grants.sql
#     names the neo_gen role
#   • optional-*.sql files are listed (never applied by any script)
# Exit 0 when every check passes, 1 otherwise.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)

# Releases whose delta is REQUIRES-REVIEW. Adding one here is the deliberate act.
EXPECT_FLAGGED="1.3.0 1.9.0 1.26.0 1.29.0 1.35.0"
# Deltas at or below this version predate the single-transaction contract and
# carry their own BEGIN/COMMIT; anything newer must not.
LEGACY_INNER_TX_CEILING="1.14.0"

DB="$PKG/db"
while [ $# -gt 0 ]; do
  case "$1" in
    --db)               shift; DB="$1" ;;
    --db=*)             DB="${1#*=}" ;;
    --expect-flagged)   shift; EXPECT_FLAGGED="$1" ;;
    --expect-flagged=*) EXPECT_FLAGGED="${1#*=}" ;;
    -h|--help)          sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $1 (see --help)" >&2; exit 1 ;;
  esac
  shift
done
[ -d "$DB" ] || { echo "no such db directory: $DB" >&2; exit 1; }

# Pure helpers only; lib.sh reads ./.env at source time and tolerates its absence.
# shellcheck disable=SC1091
. "$PKG/lib.sh"

PASS=0; FAIL=0
ok_()   { PASS=$((PASS+1)); printf 'ok    %s\n' "$*"; }
fail_() { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$*"; }
info_() { printf 'info  %s\n' "$*"; }

VERS=$(find "$DB" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V)
[ -n "$VERS" ] || { echo "no db/<version> folders under $DB" >&2; exit 1; }
LOWEST=$(printf '%s\n' "$VERS" | head -n1)
info_ "order: $(printf '%s\n' "$VERS" | tr '\n' ' ' | sed 's/ $//')"

FLAGGED=""; PREV=""
while IFS= read -r v; do
  [ -n "$v" ] || continue
  d="$DB/$v"

  # 1. name
  if is_exact_semver "$v"; then ok_ "$v: bare semver name"
  else fail_ "$v: folder name is not a bare X.Y.Z release"; PREV="$v"; continue; fi

  # 2. completeness
  want=yes; [ "$v" = "$LOWEST" ] && want=no
  gaps=$(bundle_missing_files "$d" "$v" "$want" | tr '\n' ' ')
  if [ -z "$gaps" ]; then ok_ "$v: whole (schema/grants/seed$([ $want = yes ] && printf '/migrate'))"
  else fail_ "$v: missing or empty: $gaps"; fi

  # 3. seed / grants contract
  if [ -s "$d/seed.sql" ]; then
    if grep -q ":'admin_email'" "$d/seed.sql" && grep -q ":'admin_password_hash'" "$d/seed.sql"; then
      ok_ "$v: seed.sql takes :'admin_email' and :'admin_password_hash'"
    else fail_ "$v: seed.sql does not take :'admin_email' / :'admin_password_hash'"; fi
  fi
  if [ -s "$d/grants.sql" ]; then
    if grep -q 'neo_gen' "$d/grants.sql"; then ok_ "$v: grants.sql names neo_gen"
    else fail_ "$v: grants.sql never mentions the neo_gen app role"; fi
  fi

  # 4. the delta itself
  m="$d/migrate-$v.sql"
  if [ -s "$m" ]; then
    line=$(review_marker_line "$m")
    if [ -n "$line" ]; then
      FLAGGED="${FLAGGED}${v} "
      if [ "$line" -le 6 ]; then ok_ "$v: REQUIRES-REVIEW marker on line $line (visible to apply_migrations)"
      else fail_ "$v: REQUIRES-REVIEW marker on line $line — apply_migrations reads only head -n 6, so this delta would ride the rolling path UNREVIEWED"; fi
    elif grep -q 'REQUIRES-REVIEW' "$m"; then
      info_ "$v: mentions REQUIRES-REVIEW in prose only (not flagged) — expected for 1.10.0/1.36.0/1.39.0/1.40.x"
    fi

    # header chain: `-- migrate-V.sql — (schema delta|data PATCH) X → Y`
    hdr=$(head -n1 "$m")
    if printf '%s' "$hdr" | grep -qE '(schema delta|data PATCH) [0-9.]+ → [0-9.]+'; then
      from=$(printf '%s' "$hdr" | sed -E 's/.*(schema delta|data PATCH) ([0-9.]+) → ([0-9.]+).*/\2/')
      to=$(printf '%s'   "$hdr" | sed -E 's/.*(schema delta|data PATCH) ([0-9.]+) → ([0-9.]+).*/\3/')
      if [ "$to" != "$v" ]; then fail_ "$v: header says it lands on $to, folder is $v"
      elif [ -n "$PREV" ] && [ "$from" != "$PREV" ]; then fail_ "$v: header chains from $from but the previous shipped folder is $PREV — a release is missing or misordered"
      else ok_ "$v: header chains $from → $to"; fi
    else
      info_ "$v: no 'X → Y' header on line 1 — chain not checked"
    fi

    # psql hygiene
    if grep -qE '^\\(connect|c |!|i |ir )' "$m"; then fail_ "$v: psql meta-command (\\connect/\\c/\\!/\\i) inside a delta applied via compose exec psql"
    else ok_ "$v: no psql meta-commands"; fi
    if grep -qE '^(BEGIN|COMMIT);' "$m"; then
      if ver_le "$v" "$LEGACY_INNER_TX_CEILING"; then info_ "$v: carries its own BEGIN/COMMIT (frozen legacy delta ≤ $LEGACY_INNER_TX_CEILING)"
      else fail_ "$v: inner BEGIN/COMMIT — splits the single-transaction apply (psql -1); deltas newer than $LEGACY_INNER_TX_CEILING must not"; fi
    else ok_ "$v: single-transaction safe (no inner BEGIN/COMMIT)"; fi
    if [ -n "$(tail -c1 "$m")" ]; then fail_ "$v: migrate-$v.sql lacks a trailing newline"
    else ok_ "$v: trailing newline"; fi
  fi

  # 5. optional files
  for o in "$d"/optional-*.sql; do
    [ -e "$o" ] && info_ "$v: ships $(basename "$o") — operator-run only, never applied by any script"
  done
  PREV="$v"
done <<<"$VERS"

# 6. the flagged set is the expected set, exactly
FLAGGED=${FLAGGED% }
norm() { printf '%s\n' $1 | sort -V | tr '\n' ' ' | sed 's/ $//'; }
if [ "$(norm "$FLAGGED")" = "$(norm "$EXPECT_FLAGGED")" ]; then ok_ "flagged set: ${FLAGGED:-(none)} — matches the expected set"
else fail_ "flagged set is [${FLAGGED:-none}] but this file expects [${EXPECT_FLAGGED:-none}] — a new REQUIRES-REVIEW release must be added here deliberately (and documented in README)"; fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
