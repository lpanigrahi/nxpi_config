#!/usr/bin/env bash
# =============================================================================
# checks-harness.sh — assertions for lib-checks.sh with the database STUBBED.
#
#   bash tests/checks-harness.sh
#
# lib-checks.sh reaches the database only through check_count / check_sample /
# rel_ready (lib.sh); this harness overrides those three, so the runner's
# verdicts, the pending-file gating, the expected-row-change generator and the
# catalog-slug extraction are exercised without docker or psql.
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
: > .env
# shellcheck disable=SC1091
. "$PKG/lib.sh"
t_exists() { [ -f "$PKG/lib-checks.sh" ]; }
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

t "lib-checks.sh exists" "yes" "$(t_exists && echo yes || echo no)"
t_exists || { printf '\n%d passed, %d failed\n' "$PASS" "$((FAIL))"; exit 1; }
# shellcheck disable=SC1091
. "$PKG/lib-checks.sh"
# The scripts cd to the package root, where db/1.25.0/… resolves; this harness
# runs in a sandbox, so point the vocabulary reader at the real delta.
CHECKS_P25_DELTA="$PKG/db/1.25.0/migrate-1.25.0.sql"

# ── the table itself ─────────────────────────────────────────────────────────
t "CHECKS is set" "yes" "$([ -n "${CHECKS:-}" ] && echo yes || echo no)"
missing_sql=""
while IFS=$'\t' read -r name gate sev req title; do
  [ -n "$name" ] || continue
  [ -n "$(check_sql "$name")" ] || missing_sql="$missing_sql $name"
done <<<"$CHECKS"
t "every check renders SQL" "" "$missing_sql"
# Capture, then grep a here-string: `fn | grep -q` under pipefail can SIGPIPE fn.
SEL=$(checks_for_pending "migrate-1.25.0.sql")
t "checks_for_pending selects the 1.25.0 set" "yes" "$(grep -qx 'p25_team_member_not_org_member' <<<"$SEL" && echo yes || echo no)"
t "checks_for_pending excludes other gates"   "no"  "$(grep -q '^p22_' <<<"$SEL" && echo yes || echo no)"
SEL=$(checks_for_pending "")
t "checks_for_pending includes always-on state checks" "yes" "$(grep -qx 'rls_posture' <<<"$SEL" && echo yes || echo no)"
SEL=$(checks_for_pending "migrate-1.35.0.sql")
t "a check gated on two files fires for either" "yes" "$(grep -qx 'cron_dup_running' <<<"$SEL" && echo yes || echo no)"

# ── the runner, with stubs ───────────────────────────────────────────────────
# STUB is "name=count name=count …" (bash 3.2 on macOS has no associative arrays).
STUB=""
check_count()  { local kv; for kv in $STUB; do [ "${kv%%=*}" = "$1" ] && { printf '%s' "${kv#*=}"; return 0; }; done; printf '0'; }
check_sample() { :; }
rel_ready()    { [ "${NOT_READY:-}" != "$1" ]; }
check_skip()   { return 1; }

STUB="p25_team_member_not_org_member=2 p35_agent_memory_rows=5 p22_viewer_audit_view_rows=1"
OUT=$(run_checks report $'migrate-1.22.0.sql\nmigrate-1.25.0.sql\nmigrate-1.35.0.sql')
t "a non-zero blocking count prints BLOCK" "yes" "$(grep -qE '^BLOCK +p25_team_member_not_org_member' <<<"$OUT" && echo yes || echo no)"
t "a zero blocking count prints ok"        "yes" "$(grep -qE '^ok +p25_grant_bad_type' <<<"$OUT" && echo yes || echo no)"
t "an ack-class count prints ACK with the word" "yes" "$(grep -qE '^ACK +p35_agent_memory_rows.*DROP-AGENT-MEMORY' <<<"$OUT" && echo yes || echo no)"
t "an info check prints its count"         "yes" "$(grep -qE '^info +p22_viewer_audit_view_rows.*\b1\b' <<<"$OUT" && echo yes || echo no)"
run_checks report $'migrate-1.22.0.sql\nmigrate-1.25.0.sql\nmigrate-1.35.0.sql' >/dev/null
t "CHECK_BLOCKERS names the blocker"       "p25_team_member_not_org_member" "$(printf '%s' "$CHECK_BLOCKERS" | tr -s ' \n' ' ' | sed 's/^ //;s/ $//')"
t "CHECK_ACKS names the ack, its word and count" "p35_agent_memory_rows DROP-AGENT-MEMORY 5" "$CHECK_ACKS"
t "checks_verdict fails on a blocker"      "1" "$(checks_verdict; echo $?)"

STUB=""
run_checks report $'migrate-1.25.0.sql' >/dev/null
t "clean run has no blockers"              "" "$CHECK_BLOCKERS"
t "checks_verdict passes when clean"       "0" "$(checks_verdict; echo $?)"

check_count() { printf ''; }   # database unreachable
OUT=$(run_checks report $'migrate-1.25.0.sql')
t "an unreadable count prints ??"          "yes" "$(grep -qE '^\?\? +p25_' <<<"$OUT" && echo yes || echo no)"
run_checks report $'migrate-1.25.0.sql' >/dev/null
t "unavailable checks fail closed"         "1" "$(checks_verdict; echo $?)"
check_count()  { local kv; for kv in $STUB; do [ "${kv%%=*}" = "$1" ] && { printf '%s' "${kv#*=}"; return 0; }; done; printf '0'; }

NOT_READY=org_privilege_request
OUT=$(run_checks report $'migrate-1.25.0.sql')
t "a table not in shape yet prints n/a"    "yes" "$(grep -qE '^n/a +p25_privilege_request_dups' <<<"$OUT" && echo yes || echo no)"
unset NOT_READY

check_skip() { [ "$1" = "cron_dup_running" ]; }   # the index already exists
OUT=$(run_checks report $'migrate-1.35.0.sql')
t "a moot check prints n/a with its skip reason" "yes" "$(grep -qE '^n/a +cron_dup_running' <<<"$OUT" && echo yes || echo no)"
check_skip() { return 1; }

# die mode: blockers abort with exit 1 (in a subshell), clean passes
STUB="p25_grant_non_uuid=3"
t "die mode exits 1 on a blocker" "1" "$( (run_checks die $'migrate-1.25.0.sql' >/dev/null 2>&1); echo $?)"
STUB=""
t "die mode passes when clean"    "0" "$( (run_checks die $'migrate-1.25.0.sql' >/dev/null 2>&1); echo $?)"

# ── permission_catalog_slugs(): the 0012 vocabulary, read from the delta ─────
t "permission_catalog_slugs counts 78" "78" "$(permission_catalog_slugs "$PKG/db/1.25.0/migrate-1.25.0.sql" | wc -l | tr -d ' ')"
t "permission_catalog_slugs has members:view" "yes" "$(permission_catalog_slugs "$PKG/db/1.25.0/migrate-1.25.0.sql" | grep -qx 'members:view' && echo yes || echo no)"
t "p25_unknown_permissions SQL embeds the vocabulary" "yes" "$(check_sql p25_unknown_permissions | grep -q "'members:view'" && echo yes || echo no)"

# ── expect_rows_for(): the printed allow-list for rowcount_compare ───────────
# 1.22.0/0005 DELETEs the viewer/read-only audit:view rows AND INSERTs audit:view
# for every system security-admin lacking it — the net on org_role_permission can
# be zero or even growth, so the allow-list is an OPEN shrink that names both.
STUB="p22_viewer_audit_view_rows=1 p22_readonly_audit_view_items=1 p22_secadmin_missing_audit_view=1"
OUT=$(expect_rows_for $'migrate-1.22.0.sql')
t "1.22.0 alone → open shrink on org_role_permission naming the insert" "yes" "$(grep -qE $'^org_role_permission\tshrink\t.*security-admin' <<<"$OUT" && echo yes || echo no)"
t "1.22.0 alone → exact shrink on the pack items"  "yes" "$(grep -qE $'^org_permission_group_item\tshrink=1\t' <<<"$OUT" && echo yes || echo no)"
t "1.22.0 alone → nothing else"       "2"   "$(wc -l <<<"$OUT" | tr -d ' ')"
t "p22_secadmin_missing_audit_view is a check" "yes" "$(grep -q '^p22_secadmin_missing_audit_view' <<<"$CHECKS" && echo yes || echo no)"
STUB="p26_audit_chain_head_rows=2"
run_checks report $'migrate-1.26.0.sql' >/dev/null
t "more than one audit_chain_head row BLOCKS 1.26.0" "yes" "$(grep -q '^p26_audit_chain_head_rows' <<<"$CHECK_BLOCKERS" && echo yes || echo no)"
STUB="p26_audit_chain_head_rows=0"
run_checks report $'migrate-1.26.0.sql' >/dev/null
t "only the platform head (no other rows) is fine" "" "$CHECK_BLOCKERS"
OUT=$(expect_rows_for $'migrate-1.22.0.sql\nmigrate-1.25.0.sql\nmigrate-1.27.0.sql\nmigrate-1.35.0.sql\nmigrate-1.40.1.sql')
t "1.25.0 adds open shrinks"          "yes" "$(grep -qE $'^org_permission_group\tshrink\t' <<<"$OUT" && grep -qE $'^org_role_permission\tshrink\t' <<<"$OUT" && echo yes || echo no)"
t "1.25.0 pins org_resource_grant same" "yes" "$(grep -qE $'^org_resource_grant\tsame\t' <<<"$OUT" && echo yes || echo no)"
t "1.25.0 lets permission_catalog grow" "yes" "$(grep -qE $'^permission_catalog\tgrow\t' <<<"$OUT" && echo yes || echo no)"
t "1.27.0 lets sod_rule grow"         "yes" "$(grep -qE $'^sod_rule\tgrow\t' <<<"$OUT" && echo yes || echo no)"
t "1.35.0 expects agent_memory gone"  "yes" "$(grep -qE $'^agent_memory\tgone\t' <<<"$OUT" && echo yes || echo no)"
OUT=$(expect_rows_for $'migrate-1.16.0.sql')
t "an additive-only set expects nothing" "" "$OUT"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
