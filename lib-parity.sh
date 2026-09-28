#!/usr/bin/env bash
# =============================================================================
# lib-parity.sh — the PURE halves of ./schema-parity.sh: which inventory lines
# are compared at all, and how two inventories are classified into findings.
# Sourced by schema-parity.sh; tests/parity-harness.sh drives it on fixtures.
#
# An inventory line is `kind|schema.object|…` as parity-inventory.sql renders
# it (one line per table, column, index, constraint, policy, trigger, function,
# enum, partition, sequence, extension, grant). Index and constraint lines put
# the NAME in field 3 and the definition after it, so a rename with an
# identical definition can be told apart from a real difference.
# =============================================================================

# parity_filter INV — stdout: the lines to compare; stderr: advisory lines.
#   • schema `drizzle` is compared only as "the schema exists": its journal
#     rows differ by design between a packaged and a journaled lineage
#   • public.deploy_schema_migrations is this package's own bookkeeping
#   • authz_decision_log_y<YYYY>m<MM> children are created by the APP at
#     runtime (ensureDecisionLogPartitions) — whether one exists depends on the
#     calendar, not on the release, so they are reported, never judged;
#     authz_decision_log_default is a real, shipped partition and IS compared
parity_filter() {
  awk '
    /deploy_schema_migrations/ { next }
    /drizzle\./                { next }
    /authz_decision_log_y[0-9][0-9][0-9][0-9]m[0-9][0-9]/ { print "runtime-partition: " $0 > "/dev/stderr"; next }
    { print }' "$1"
}

# parity_classify SCRATCH LIVE OUTDIR [ACCEPT] — writes OUTDIR/only-scratch.txt
# (objects the live database is MISSING — always a hard finding),
# OUTDIR/only-live.txt (objects the live database has EXTRA — hard),
# OUTDIR/advisory.txt (name-only index/constraint renames, operator-accepted
# patterns) and OUTDIR/summary.txt. ACCEPT is an optional file of regexes;
# a hard line matching one is moved to advisory as "accepted".
parity_classify() {
  local scratch="$1" live="$2" out="$3" accept="${4:-}"
  mkdir -p "$out"
  sort -u "$scratch" > "$out/.scratch.sorted"
  sort -u "$live"    > "$out/.live.sorted"
  comm -23 "$out/.scratch.sorted" "$out/.live.sorted" > "$out/.only-scratch.raw"
  comm -13 "$out/.scratch.sorted" "$out/.live.sorted" > "$out/.only-live.raw"
  : > "$out/advisory.txt"

  # Name-only detection: an index/constraint line whose definition (every
  # field but the name) exists on the OTHER side under a different name is a
  # rename, not a drift — 1.35.0 renames 47 of them on the legacy lineage.
  awk -F'|' -v OFS='|' -v ADV="$out/advisory.txt" -v OS="$out/only-scratch.txt" -v OL="$out/only-live.txt" '
    function keyof(line,   n, i, k, f) { n = split(line, f, "|"); k = ""; for (i = 1; i <= n; i++) if (i != 3) k = k "|" f[i]; return k }
    function nameable(line) { return (line ~ /^index\|/ || line ~ /^constraint\|/) }
    FNR == NR { s[FNR] = $0; if (nameable($0)) { sk[keyof($0)] = $3 }; ns = FNR; next }
    { l[FNR] = $0; if (nameable($0)) { lk[keyof($0)] = $3 }; nl = FNR }
    END {
      for (i = 1; i <= ns; i++) { line = s[i]; if (nameable(line) && (keyof(line) in lk)) print "name-only: scratch=" line " ↔ live-name=" lk[keyof(line)] > ADV; else print line > OS }
      for (i = 1; i <= nl; i++) { line = l[i]; if (nameable(line) && (keyof(line) in sk)) print "name-only: live=" line " ↔ scratch-name=" sk[keyof(line)] > ADV; else print line > OL }
    }' "$out/.only-scratch.raw" "$out/.only-live.raw"
  [ -f "$out/only-scratch.txt" ] || : > "$out/only-scratch.txt"
  [ -f "$out/only-live.txt" ]    || : > "$out/only-live.txt"

  # Operator-accepted patterns.
  if [ -n "$accept" ] && [ -s "$accept" ]; then
    local f
    for f in only-scratch only-live; do
      grep -E -f "$accept" "$out/$f.txt" 2>/dev/null | sed "s/^/accepted ($f): /" >> "$out/advisory.txt" || true
      grep -E -v -f "$accept" "$out/$f.txt" > "$out/.$f.kept" 2>/dev/null || true
      mv "$out/.$f.kept" "$out/$f.txt"
    done
  fi

  printf 'only-scratch=%s only-live=%s advisory=%s\n' \
    "$(grep -c . "$out/only-scratch.txt" | tr -d ' ')" \
    "$(grep -c . "$out/only-live.txt" | tr -d ' ')" \
    "$(grep -c . "$out/advisory.txt" | tr -d ' ')" > "$out/summary.txt"
  rm -f "$out"/.scratch.sorted "$out"/.live.sorted "$out"/.only-scratch.raw "$out"/.only-live.raw
}

# parity_verdict OUTDIR — 0 when nothing hard remains, 3 otherwise.
parity_verdict() {
  if [ -s "$1/only-scratch.txt" ] || [ -s "$1/only-live.txt" ]; then return 3; fi
  return 0
}
