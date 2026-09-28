#!/usr/bin/env bash
# =============================================================================
# bundle-lint-harness.sh — contract tests for tests/db-bundle-lint.sh.
#
#   bash tests/bundle-lint-harness.sh
#
# Builds throwaway db/ trees and asserts the lint accepts a sound one and
# rejects each defect class it exists to catch. The real db/ is never used.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)
LINT="$PKG/tests/db-bundle-lint.sh"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

# mk ROOT VER PREV [flag]  — a whole bundle whose delta header chains PREV → VER
mk() {
  local root="$1" ver="$2" prev="$3" flag="${4:-}" d="$1/db/$2"
  mkdir -p "$d"
  printf -- "-- schema\n" > "$d/schema.sql"
  printf -- "-- grants: neo_gen\nGRANT SELECT ON ALL TABLES IN SCHEMA public TO neo_gen;\n" > "$d/grants.sql"
  printf -- "-- seed :'admin_email' :'admin_password_hash'\n" > "$d/seed.sql"
  if [ -n "$prev" ]; then
    {
      printf -- '-- migrate-%s.sql — schema delta %s → %s (fixture).\n' "$ver" "$prev" "$ver"
      [ "$flag" = "flagged" ] && printf -- '-- REQUIRES-REVIEW: drops a thing\n'
      printf -- '-- body\nSELECT 1;\n'
    } > "$d/migrate-$ver.sql"
  fi
}
good() { # a sound 4-release tree: 1.2.0 (base) → 1.3.0 (flagged) → 1.4.0 → 1.4.1 → 1.5.0
  local r="$1"; rm -rf "$r"
  mk "$r" 1.2.0 ""; mk "$r" 1.3.0 1.2.0 flagged; mk "$r" 1.4.0 1.3.0; mk "$r" 1.4.1 1.4.0; mk "$r" 1.5.0 1.4.1
}
run() { bash "$LINT" --db "$1/db" --expect-flagged "1.3.0" >"$WORK/out" 2>&1; echo $?; }

t "lint exists" "yes" "$([ -f "$LINT" ] && echo yes || echo no)"

good "$WORK/g";  t "sound tree passes"                         "0" "$(run "$WORK/g")"
t "sound tree names the flagged set"       "yes" "$(grep -q 'flagged.*1\.3\.0' "$WORK/out" && echo yes || echo no)"
t "patch release 1.4.1 orders between 1.4.0 and 1.5.0" "yes" "$(grep -q '1\.4\.0 1\.4\.1 1\.5\.0' "$WORK/out" && echo yes || echo no)"

good "$WORK/a"; rm "$WORK/a/db/1.4.0/seed.sql"
t "incomplete folder fails"                "1" "$(run "$WORK/a")"
t "incomplete folder is named"             "yes" "$(grep -q '1\.4\.0.*seed\.sql' "$WORK/out" && echo yes || echo no)"

good "$WORK/b"; { printf -- '-- migrate-1.5.0.sql — schema delta 1.4.1 → 1.5.0\n'; for i in 2 3 4 5 6 7; do printf -- '-- l%s\n' $i; done; printf -- '-- REQUIRES-REVIEW: too low\nSELECT 1;\n'; } > "$WORK/b/db/1.5.0/migrate-1.5.0.sql"
t "marker below line 6 fails"              "1" "$(run "$WORK/b")"
t "low marker names the line"              "yes" "$(grep -qE '1\.5\.0.*line 8' "$WORK/out" && echo yes || echo no)"

good "$WORK/c"; printf -- '-- migrate-1.5.0.sql — schema delta 1.4.0 → 1.5.0 (skips 1.4.1)\nSELECT 1;\n' > "$WORK/c/db/1.5.0/migrate-1.5.0.sql"
t "header chain gap fails"                 "1" "$(run "$WORK/c")"
t "gap names both versions"                "yes" "$(grep -q '1\.4\.1' "$WORK/out" && grep -q '1\.4\.0' "$WORK/out" && echo yes || echo no)"

# Deltas ≤ 1.14.0 are allowed their historical BEGIN/COMMIT; a NEWER one is not.
good "$WORK/d"; mk "$WORK/d" 1.15.0 1.5.0; printf -- '-- migrate-1.15.0.sql — schema delta 1.5.0 → 1.15.0\nBEGIN;\nSELECT 1;\nCOMMIT;\n' > "$WORK/d/db/1.15.0/migrate-1.15.0.sql"
t "inner BEGIN/COMMIT in a modern delta fails" "1" "$(run "$WORK/d")"
good "$WORK/d2"; printf -- '-- migrate-1.5.0.sql — schema delta 1.4.1 → 1.5.0\nBEGIN;\nSELECT 1;\nCOMMIT;\n' > "$WORK/d2/db/1.5.0/migrate-1.5.0.sql"
t "inner BEGIN/COMMIT in a legacy delta is tolerated" "0" "$(run "$WORK/d2")"

good "$WORK/e"; printf -- '-- migrate-1.5.0.sql — schema delta 1.4.1 → 1.5.0\n\\connect other\nSELECT 1;\n' > "$WORK/e/db/1.5.0/migrate-1.5.0.sql"
t "psql meta-command fails"                "1" "$(run "$WORK/e")"

good "$WORK/f"; mk "$WORK/f" 1.6.0 1.5.0 flagged
t "an unexpected flagged release fails"    "1" "$(run "$WORK/f")"
t "unexpected flagged release is named"    "yes" "$(grep -q '1\.6\.0' "$WORK/out" && echo yes || echo no)"

good "$WORK/h"; mkdir -p "$WORK/h/db/1.7.0-rc1"
t "non-semver folder fails"                "1" "$(run "$WORK/h")"

good "$WORK/i"; printf -- '-- migrate-1.5.0.sql — schema delta 1.4.1 → 1.5.0\nSELECT 1;' > "$WORK/i/db/1.5.0/migrate-1.5.0.sql"
t "missing trailing newline fails"         "1" "$(run "$WORK/i")"

good "$WORK/j"; : > "$WORK/j/db/1.4.0/seed.sql"; printf -- '-- no admin vars\n' > "$WORK/j/db/1.4.0/seed.sql"
t "seed without the admin variables fails" "1" "$(run "$WORK/j")"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
