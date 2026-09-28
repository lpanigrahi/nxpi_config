#!/usr/bin/env bash
# =============================================================================
# sync-from-app-copy.sh — carry new db/<version>/ bundles over from the app
# repo's embedded copy of this package, and REPORT (never apply) script drift.
#
#   tools/sync-from-app-copy.sh <path/to/nxpi/azure-deployment>            # report only
#   tools/sync-from-app-copy.sh <path/to/nxpi/azure-deployment> --apply    # copy MISSING bundles
#   tools/sync-from-app-copy.sh <src> --report FILE                        # diff report to FILE
#
# The README says new db/<version>/ folders and tooling fixes land in the app
# repo's embedded copy first and are carried over here by hand. This tool makes
# the bundle half mechanical and the script half deliberate:
#
#   • MISSING    a db/<v> the source ships and we do not → copied verbatim by
#                --apply (minus .DS_Store), then re-verified with diff -rq.
#   • INCOMPLETE a source folder lacking one of schema/grants/seed/migrate-<v>
#                (bundle_missing_files) → never copied. Exit 2.
#   • DRIFTED    a folder BOTH sides ship whose contents differ. A shipped
#                release's SQL is frozen; if upstream changed it, a human decides.
#                Never overwritten. Exit 3, unified diff printed.
#   • scripts/templates (lib.sh, install.sh, docker-compose.yml, .env*.example,
#                README …) → a unified diff REPORT only. This package carries
#                fixes the app copy lacks (see git log), so nothing is auto-applied.
#
# Exit codes: 0 in sync · 1 usage/error · 2 incomplete source folder(s) ·
#             3 drifted shipped folder(s) · 4 report-only found missing folders.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

SRC=""; APPLY=false; REPORT=""; PKG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply)     APPLY=true ;;
    --report)    shift; [ $# -gt 0 ] || { echo "--report needs a file" >&2; exit 1; }; REPORT="$1" ;;
    --report=*)  REPORT="${1#*=}" ;;
    --package)   shift; [ $# -gt 0 ] || { echo "--package needs a dir" >&2; exit 1; }; PKG="$1" ;;   # tests
    --package=*) PKG="${1#*=}" ;;
    -h|--help)   sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    -*)          echo "unknown flag: $1 (see --help)" >&2; exit 1 ;;
    *)           [ -z "$SRC" ] || { echo "give exactly one source path" >&2; exit 1; }; SRC="$1" ;;
  esac
  shift
done
[ -n "$SRC" ] || { echo "usage: $0 <app-copy-path> [--apply] [--report FILE]" >&2; exit 1; }

PKG=${PKG:-$(cd -- "$SCRIPT_DIR/.." && pwd)}
cd "$PKG"
# shellcheck source=../lib.sh
. ./lib.sh

SRC=$(cd -- "$SRC" 2>/dev/null && pwd) || die "source path does not exist: $SRC"
[ -d "$SRC/db" ] || die "$SRC has no db/ directory — is it the app repo's azure-deployment/ folder?"
[ "$SRC" != "$PKG" ] || die "source and package are the same directory"
case "$SRC/" in "$PKG"/*) die "source lies inside this package ($PKG) — refusing" ;; esac

# ── 1. Classify every source bundle ──────────────────────────────────────────
hdr "Bundles: $SRC/db → $PKG/db"
SRC_VERS=$(find "$SRC/db" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -V)
[ -n "$SRC_VERS" ] || die "no db/<version> folders under $SRC/db"
LOWEST=$(printf '%s\n' "$SRC_VERS" | head -n1)

MISSING=""; INCOMPLETE=""; DRIFTED=""; PRESENT=0
while IFS= read -r v; do
  [ -n "$v" ] || continue
  is_exact_semver "$v" || die "source folder db/$v is not a bare X.Y.Z release — ver_le/sort -V cannot order it; fix upstream first"
  want_migrate=yes; [ "$v" = "$LOWEST" ] && want_migrate=no
  if [ -d "db/$v" ]; then
    if diff -rq --exclude=.DS_Store "db/$v" "$SRC/db/$v" >/dev/null 2>&1; then
      PRESENT=$((PRESENT + 1))
    else
      DRIFTED="${DRIFTED}${v}"$'\n'
    fi
  else
    gaps=$(bundle_missing_files "$SRC/db/$v" "$v" "$want_migrate" | tr '\n' ' ')
    if [ -n "$gaps" ]; then INCOMPLETE="${INCOMPLETE}${v}: ${gaps}"$'\n'
    else MISSING="${MISSING}${v}"$'\n'; fi
  fi
done <<<"$SRC_VERS"
MISSING=${MISSING%$'\n'}; INCOMPLETE=${INCOMPLETE%$'\n'}; DRIFTED=${DRIFTED%$'\n'}

log "identical on both sides : $PRESENT folder(s)"
if [ -n "$MISSING" ];    then log "MISSING here (source ships them):"; printf '%s\n' "$MISSING" | sed 's/^/    MISSING    /'; fi
if [ -n "$INCOMPLETE" ]; then warn "INCOMPLETE in source (never copied):"; printf '%s\n' "$INCOMPLETE" | sed 's/^/    INCOMPLETE /' >&2; fi
if [ -n "$DRIFTED" ]; then
  warn "DRIFTED — shipped on both sides but the contents differ (a frozen release's SQL changed upstream):"
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    printf '    DRIFTED    %s\n' "$v" >&2
    diff -ru --exclude=.DS_Store --label "ours/db/$v" --label "app/db/$v" "db/$v" "$SRC/db/$v" >&2 || true
  done <<<"$DRIFTED"
fi

# ── 2. Apply (missing only) ──────────────────────────────────────────────────
if $APPLY && [ -n "$MISSING" ] && [ -z "$DRIFTED" ] && [ -z "$INCOMPLETE" ]; then
  hdr "Copying missing bundles"
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    cp -R "$SRC/db/$v" "db/$v"
    find "db/$v" -name .DS_Store -delete
    diff -rq --exclude=.DS_Store "db/$v" "$SRC/db/$v" >/dev/null \
      || die "db/$v does not match the source after copying — inspect and re-run"
    ok "added db/$v"
  done <<<"$MISSING"
  log "next: bash tests/db-bundle-lint.sh && git add db/ && git commit"
  MISSING=""
elif $APPLY && [ -n "$MISSING" ]; then
  warn "--apply refused: resolve the DRIFTED/INCOMPLETE folders above first (nothing was copied)"
fi

# ── 3. Script / template drift report (never applied) ────────────────────────
hdr "Script and template drift (report only — apply by hand)"
TRACKED="lib.sh install.sh update.sh migrate.sh restore.sh backup.sh compose.sh secrets-entrypoint.sh
prepare-disks.sh generate-certs.sh pgbackrest.sh pgbackrest.conf init.sql docker-compose.yml Caddyfile
.env.example .env.app.example .gitignore README.md docs/CUTOVER-RUNBOOK.md docs/SOURCELESS-DEPLOYMENT-PLAN.md
tests/lib-harness.sh"
emit_report() {
  local f
  for f in $TRACKED; do
    if [ -e "$f" ] && [ -e "$SRC/$f" ]; then
      diff -u --label "ours/$f" --label "app/$f" "$f" "$SRC/$f" || true
    elif [ -e "$SRC/$f" ]; then printf 'Only in app copy: %s\n' "$f"
    elif [ -e "$f" ];       then printf 'Only in ours:     %s\n' "$f"
    fi
  done
  # Anything the app copy ships at top level that we have no name for.
  for f in "$SRC"/*.sh "$SRC"/*.yml "$SRC"/*.conf; do
    [ -e "$f" ] || continue
    b=$(basename "$f"); [ -e "$b" ] || printf 'Only in app copy: %s\n' "$b"
  done
}
if [ -n "$REPORT" ]; then
  emit_report > "$REPORT"
  ok "diff report written to $REPORT ($(grep -c '^--- ours/' "$REPORT" 2>/dev/null || echo 0) differing file(s))"
else
  emit_report
fi

# ── 4. Verdict ───────────────────────────────────────────────────────────────
hdr "Verdict"
if [ -n "$INCOMPLETE" ]; then
  printf '%s\n' "✖ incomplete source folder(s) — nothing copied for them (exit 2)" >&2
  exit 2
fi
if [ -n "$DRIFTED" ]; then
  printf '%s\n' "✖ shipped folder(s) differ from the source — a human decides; nothing was overwritten (exit 3)" >&2
  exit 3
fi
if [ -n "$MISSING" ]; then
  log "missing folder(s) found — re-run with --apply to copy them (exit 4)"
  exit 4
fi
ok "bundles in sync with $SRC"
exit 0
