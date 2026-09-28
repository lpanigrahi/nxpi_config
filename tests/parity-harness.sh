#!/usr/bin/env bash
# =============================================================================
# parity-harness.sh — assertions for the PURE halves of schema-parity.sh
# (lib-parity.sh): inventory filtering and diff classification. No docker, no
# database; fixture inventories only.
#
#   bash tests/parity-harness.sh
# =============================================================================
set -uo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PKG=$(cd -- "$HERE/.." && pwd)
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
: > .env
# shellcheck disable=SC1091
. "$PKG/lib.sh"
PASS=0; FAIL=0
t() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); printf 'FAIL %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"; fi; }

t "lib-parity.sh exists" "yes" "$([ -f "$PKG/lib-parity.sh" ] && echo yes || echo no)"
[ -f "$PKG/lib-parity.sh" ] || { printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"; exit 1; }
# shellcheck disable=SC1091
. "$PKG/lib-parity.sh"

# ── parity_filter(): what is never compared, what is only advisory ───────────
cat > inv.raw <<'EOF'
schema|drizzle
schema|public
table|drizzle.__drizzle_migrations|r|rls=f|force=f
column|drizzle.__drizzle_migrations.id|integer|notnull=t
table|public.deploy_schema_migrations|r|rls=f|force=f
column|public.deploy_schema_migrations.filename|text|notnull=t
table|public.authz_decision_log_y2026m10|r|rls=t|force=t
index|public.authz_decision_log_y2026m10|authz_decision_log_y2026m10_pkey|CREATE UNIQUE INDEX ON public.authz_decision_log_y2026m10 USING btree (id)
partition|public.authz_decision_log|public.authz_decision_log_y2026m10|FOR VALUES FROM ('2026-10-01') TO ('2026-11-01')
table|public.authz_decision_log_default|r|rls=t|force=t
table|public."user"|r|rls=f|force=f
EOF
parity_filter inv.raw > inv.compare 2> inv.advisory
t "drizzle objects are dropped (schema kept)"   "1" "$(grep -c 'drizzle' inv.compare | tr -d ' ')"
t "schema|drizzle survives"                     "yes" "$(grep -qx 'schema|drizzle' inv.compare && echo yes || echo no)"
t "deploy_schema_migrations is dropped"         "0" "$(grep -c 'deploy_schema_migrations' inv.compare | tr -d ' ')"
t "runtime month partitions leave the compare set" "0" "$(grep -c 'y2026m10' inv.compare | tr -d ' ')"
t "…and land in the advisory stream"            "3" "$(grep -c 'y2026m10' inv.advisory | tr -d ' ')"
t "the default partition is compared"           "yes" "$(grep -q 'authz_decision_log_default' inv.compare && echo yes || echo no)"
t "ordinary tables are compared"                "yes" "$(grep -q 'public."user"' inv.compare && echo yes || echo no)"

# ── parity_classify(): only-scratch / only-live / advisory name-only ─────────
cat > scratch.inv <<'EOF'
table|public.a|r|rls=f|force=f
column|public.a.id|uuid|notnull=t
index|public.a|a_pkey|CREATE UNIQUE INDEX ON public.a USING btree (id)
constraint|public.b|b_org_fk|f|FOREIGN KEY (org) REFERENCES public.organization(id) ON DELETE CASCADE|del=c
table|public.c|r|rls=f|force=f
EOF
cat > live.inv <<'EOF'
table|public.a|r|rls=f|force=f
column|public.a.id|uuid|notnull=t
index|public.a|a_id_key|CREATE UNIQUE INDEX ON public.a USING btree (id)
constraint|public.b|b_org_fk|f|FOREIGN KEY (org) REFERENCES public.organization(id) ON DELETE SET NULL|del=n
table|public.agent_memory|r|rls=f|force=f
EOF
mkdir out
parity_classify scratch.inv live.inv out
t "only-scratch lists what the live DB is MISSING" "yes" "$(grep -qx 'table|public.c|r|rls=f|force=f' out/only-scratch.txt && echo yes || echo no)"
t "only-live lists what the live DB has EXTRA"     "yes" "$(grep -qx 'table|public.agent_memory|r|rls=f|force=f' out/only-live.txt && echo yes || echo no)"
t "matching lines are not findings"                "0"   "$(grep -c 'public.a|' out/only-scratch.txt out/only-live.txt | awk -F: '{s+=$2} END{print s}')"
t "an index that differs only by NAME is advisory" "yes" "$(grep -q 'a_pkey' out/advisory.txt && grep -q 'a_id_key' out/advisory.txt && echo yes || echo no)"
t "the renamed index is not a hard finding"        "0" "$(grep -c 'index|' out/only-scratch.txt out/only-live.txt | awk -F: '{s+=$2} END{print s}')"
t "a constraint whose DEFINITION differs stays hard" "yes" "$(grep -q 'b_org_fk' out/only-scratch.txt && grep -q 'b_org_fk' out/only-live.txt && echo yes || echo no)"
t "summary counts hard findings"                   "yes" "$(grep -qE 'only-scratch=2' out/summary.txt && grep -qE 'only-live=2' out/summary.txt && echo yes || echo no)"
t "parity_verdict is 3 with hard findings"         "3" "$(parity_verdict out; echo $?)"
cp scratch.inv live2.inv; mkdir out2; parity_classify scratch.inv live2.inv out2
t "identical inventories → verdict 0"              "0" "$(parity_verdict out2; echo $?)"
t "identical inventories → empty findings"         "0" "$(cat out2/only-scratch.txt out2/only-live.txt | wc -l | tr -d ' ')"

# ── accept file: operator-accepted regexes drop hard lines to advisory ───────
printf 'agent_memory\n' > accept.txt
mkdir out3; parity_classify scratch.inv live.inv out3 accept.txt
t "an accepted pattern moves a hard line to advisory" "0" "$(grep -c 'agent_memory' out3/only-live.txt | tr -d ' ')"
t "…and records it as accepted"                       "yes" "$(grep -q 'accepted.*agent_memory' out3/advisory.txt && echo yes || echo no)"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
exit $((FAIL > 0))
