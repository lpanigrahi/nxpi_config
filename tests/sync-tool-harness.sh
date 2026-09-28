#!/usr/bin/env bash
# =============================================================================
# sync-tool-harness.sh — contract tests for tools/sync-from-app-copy.sh.
#
#   bash tests/sync-tool-harness.sh
#
# Runs the tool against throwaway fixture trees (a fake "ours" package and a
# fake app-copy), never against the real db/ folders. Exit codes under test:
#   0  in sync (nothing missing, nothing drifted)
#   2  a SOURCE folder is incomplete (never copied, even with --apply)
#   3  a folder BOTH sides ship differs (a shipped release's SQL changed — human decides)
#   4  report-only found missing folders (re-run with --apply)
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)
TOOL="$PKG/tools/sync-from-app-copy.sh"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

mkb() { # mkb ROOT VER [skip-file]  — a complete bundle, optionally minus one file
  local root="$1" ver="$2" skip="${3:-}" f
  mkdir -p "$root/db/$ver"
  for f in schema.sql grants.sql seed.sql "migrate-$ver.sql"; do
    [ "$f" = "$skip" ] && continue
    printf -- '-- %s %s\n' "$ver" "$f" > "$root/db/$ver/$f"
  done
}

# A fake "ours": lib.sh is the real one (the tool sources it), plus one bundle.
OURS="$WORK/ours"; SRC="$WORK/app"
mkdir -p "$OURS/tools" "$SRC"
cp "$PKG/lib.sh" "$OURS/lib.sh"; cp "$PKG/lib.sh" "$SRC/lib.sh"
printf 'ours\n' > "$OURS/README.md"; printf 'theirs\n' > "$SRC/README.md"
mkb "$OURS" 1.0.0; mkb "$SRC" 1.0.0
mkb "$SRC" 1.1.0
touch "$SRC/db/1.1.0/.DS_Store"

t "tool exists and is executable" "yes" "$([ -x "$TOOL" ] && echo yes || echo no)"

# 1. report-only: 1.1.0 is missing → exit 4, named in the report, nothing copied
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" 2>&1); RC=$?
t "report-only with a missing folder exits 4" "4" "$RC"
t "missing folder is named"                   "yes" "$(grep -q 'MISSING.*1\.1\.0' <<<"$OUT" && echo yes || echo no)"
t "report-only copies nothing"                "no"  "$([ -d "$OURS/db/1.1.0" ] && echo yes || echo no)"
t "script diff report names README"           "yes" "$(grep -q -- '--- ours/README.md' <<<"$OUT" && echo yes || echo no)"

# 2. --apply copies the missing folder verbatim (minus .DS_Store); second run is in sync
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" --apply 2>&1); RC=$?
t "--apply exits 0"                    "0"   "$RC"
t "--apply copied the folder"          "yes" "$(diff -rq --exclude=.DS_Store "$OURS/db/1.1.0" "$SRC/db/1.1.0" >/dev/null && echo yes || echo no)"
t "--apply drops .DS_Store"            "no"  "$([ -e "$OURS/db/1.1.0/.DS_Store" ] && echo yes || echo no)"
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" 2>&1); RC=$?
t "second run is in sync (exit 0)"     "0"   "$RC"

# 3. an INCOMPLETE source folder is refused (exit 2) and never copied
mkb "$SRC" 1.2.0 seed.sql
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" --apply 2>&1); RC=$?
t "incomplete source folder exits 2"   "2"   "$RC"
t "incomplete folder names the gap"    "yes" "$(grep -q 'INCOMPLETE.*1\.2\.0.*seed\.sql' <<<"$OUT" && echo yes || echo no)"
t "incomplete folder is not copied"    "no"  "$([ -d "$OURS/db/1.2.0" ] && echo yes || echo no)"
rm -rf "$SRC/db/1.2.0"

# 4. a folder both sides ship that DIFFERS is refused (exit 3) with a diff, even with --apply
printf -- '-- changed upstream\n' >> "$SRC/db/1.0.0/migrate-1.0.0.sql"
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" --apply 2>&1); RC=$?
t "drifted shipped folder exits 3"     "3"   "$RC"
t "drift names the folder"             "yes" "$(grep -q 'DRIFTED.*1\.0\.0' <<<"$OUT" && echo yes || echo no)"
t "drift shows the diff"               "yes" "$(grep -q 'changed upstream' <<<"$OUT" && echo yes || echo no)"
t "drift leaves ours untouched"        "no"  "$(grep -q 'changed upstream' "$OURS/db/1.0.0/migrate-1.0.0.sql" && echo yes || echo no)"

# 5. the report can go to a file; a non-semver folder name is a hard error
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" --report "$WORK/report.txt" 2>&1); RC=$?
t "--report writes the diff report"    "yes" "$(grep -q -- '--- ours/README.md' "$WORK/report.txt" 2>/dev/null && echo yes || echo no)"
mkdir -p "$SRC/db/1.3.0-rc1"
OUT=$(bash "$TOOL" "$SRC" --package "$OURS" 2>&1); RC=$?
t "non-semver folder name exits 1"     "1"   "$RC"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
