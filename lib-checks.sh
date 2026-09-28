#!/usr/bin/env bash
# =============================================================================
# lib-checks.sh — the data pre-checks a release upgrade runs BEFORE it touches
# the database, and the expected row-count changes it must tolerate afterwards.
# Sourced by discover.sh (report mode, read-only) and upgrade-db.sh (die mode).
# Requires lib.sh to be sourced first (psql_scalar, psql_admin, rel_ready).
#
# Every packaged delta that can FAIL CLOSED on live data (1.9.0, 1.11.0,
# 1.25.0, 1.35.0) does so from inside a single-transaction psql apply — AFTER
# a full backup has been taken and ./.env has been edited. Mirroring each of
# those predicates here as a read-only SELECT is what lets --dry-run and
# discover.sh say "this window will stop at 1.25.0 on 3 grants" a week early.
#
# The table: name<TAB>gate<TAB>severity<TAB>requires<TAB>title
#   gate      comma list of migrate-*.sql files; the check runs when ANY is
#             pending, or `always` for a state report that needs no pending delta
#   severity  block        a non-zero count stops the upgrade
#             ack:<WORD>   a non-zero count needs the operator to type WORD
#             info         a count worth printing (feeds expect_rows_for)
#   requires  comma list of tables that must exist in schema public, else the
#             check is "not applicable yet" (an adopted schema may predate them)
# check_sql NAME renders the COUNT query; check_sample_sql NAME an optional
# detail listing; check_skip NAME returns 0 when the check is moot on this
# database (e.g. the index it guards already exists). The database is reached
# ONLY through check_count / check_sample / rel_ready / check_skip, so
# tests/checks-harness.sh can stub all four.
# =============================================================================

CHECKS=$(printf '%s\n' \
  $'cron_dup_running\tmigrate-1.9.0.sql,migrate-1.35.0.sql\tblock\tcron_run_log\tcron jobs with MORE THAN ONE running row (the one-running-per-job index would be silently skipped)' \
  $'invoice_dups\tmigrate-1.11.0.sql\tblock\tinvoice\t(organization_id, external_invoice_id) groups holding duplicate invoices' \
  $'org_invite_pending_dups\tmigrate-1.11.0.sql\tblock\torg_invite\t(organization_id, invited_email) groups with more than one PENDING invite' \
  $'p20_apikeys_become_unscoped\tmigrate-1.20.0.sql\tinfo\tapikey\tAPI keys that will hold no org authority until re-bound (1.20.0 binds keys to one organization)' \
  $'p22_viewer_audit_view_rows\tmigrate-1.22.0.sql\tinfo\torg_role_permission,org_role\torg_role_permission rows 1.22.0 DELETES (system viewer role, audit:view, not denied)' \
  $'p22_readonly_audit_view_items\tmigrate-1.22.0.sql\tinfo\torg_permission_group_item,org_permission_group\torg_permission_group_item rows 1.22.0 DELETES (system read-only pack, audit:view)' \
  $'p25_privilege_request_dups\tmigrate-1.25.0.sql\tblock\torg_privilege_request\tduplicate PENDING privilege requests per (membership, role, team) — 0010 refuses them' \
  $'p25_team_member_no_team\tmigrate-1.25.0.sql\tblock\tteam_member,team\tteam_member rows whose team no longer exists — 0011 cannot resolve their organization' \
  $'p25_team_member_not_org_member\tmigrate-1.25.0.sql\tblock\tteam_member,team,organization_member\tteam_member rows whose user is NOT a member of the team\'s organization — 0011 refuses them (enrol the user; deleting the row can orphan a team)' \
  $'p25_org_role_bad_key\tmigrate-1.25.0.sql\tblock\torg_role\torg_role keys that violate ^[a-z0-9][a-z0-9-]{1,63}$ — 0009 adds that CHECK' \
  $'p25_org_role_key_collision\tmigrate-1.25.0.sql\tblock\torg_role\t(organization, key) collisions once NULL keys are backfilled to custom-<id8> — 0009 makes the index FULL unique' \
  $'p25_grant_bad_type\tmigrate-1.25.0.sql\tblock\torg_resource_grant\torg_resource_grant rows whose resource_type is outside the six partitions — 0015 refuses them' \
  $'p25_grant_non_uuid\tmigrate-1.25.0.sql\tblock\torg_resource_grant\torg_resource_grant rows whose resource_id is not a UUID — 0015 casts the column' \
  $'p25_grant_dangling\tmigrate-1.25.0.sql\tblock\torg_resource_grant,agent,assistant,knowledge_base,mcp_server,team,workflow\torg_resource_grant rows pointing at a resource that no longer exists — 0015\'s per-partition FKs refuse them (revoke in the product)' \
  $'p25_grant_extra_cols\tmigrate-1.25.0.sql\tblock\torg_resource_grant\tcolumns on org_resource_grant the 0015 rebuild would NOT copy' \
  $'p25_unknown_permissions\tmigrate-1.25.0.sql\tblock\torg_role_permission,org_permission_group_item,org_resource_grant\tpermission slugs in use that 0012\'s catalog does not know' \
  $'p25_junction_orphans\tmigrate-1.25.0.sql\tblock\torg_role_permission,org_role,org_permission_group_item,org_permission_group,org_role_permission_group\tRBAC junction rows with no parent role/group — 0017 cannot take an organization from nothing' \
  $'p25_role_group_org_mismatch\tmigrate-1.25.0.sql\tblock\torg_role_permission_group,org_role,org_permission_group\trole↔pack attachments across two organizations — 0017 refuses them' \
  $'p26_audit_chain_head_rows\tmigrate-1.26.0.sql\tinfo\taudit_chain_head\taudit_chain_head rows (1.26.0 keys the chain per organization; expects the single platform head)' \
  $'p29_app_role_can_bypass_rls\tmigrate-1.29.0.sql\tblock\t-\tthe neo_gen app role is SUPERUSER or BYPASSRLS — 1.29.0\'s FORCE ROW LEVEL SECURITY would be inert' \
  $'p35_agent_memory_rows\tmigrate-1.35.0.sql\tack:DROP-AGENT-MEMORY\tagent_memory\trows in agent_memory, which 1.35.0 DROPS (an orphan store with no readers — expected 0)' \
  $'rls_posture\talways\tinfo\t-\ttables with row-level security FORCED (0 before 1.29.0, ≥26 after)' \
  $'privileged_role_present\talways\tinfo\t-\tthe neogen_priv BYPASSRLS role exists (1 = provisioned)')

# permission_catalog_slugs DELTA_FILE — the 0012 vocabulary, read from the
# packaged delta itself (its INSERT INTO permission_catalog VALUES rows), so
# the pre-check and the migration can never disagree. One slug per line.
permission_catalog_slugs() {
  sed -nE "s/^[[:space:]]*\('([a-z_-]+:[a-z_-]+)',.*/\1/p" "$1"
}

# sql_in_list "a b c" → 'a','b','c'
sql_in_list() {
  local out="" s
  for s in $1; do out="${out:+$out,}'${s//\'/\'\'}'"; done
  printf '%s' "$out"
}

check_sql() {
  case "$1" in
    cron_dup_running)
      printf '%s' "select count(*) from (select cron_job_id from cron_run_log where status='running' group by cron_job_id having count(*) > 1) d" ;;
    invoice_dups)
      printf '%s' "select count(*) from (select 1 from invoice where external_invoice_id is not null group by organization_id, external_invoice_id having count(*) > 1) d" ;;
    org_invite_pending_dups)
      printf '%s' "select count(*) from (select 1 from org_invite where accepted_at is null group by organization_id, invited_email having count(*) > 1) d" ;;
    p20_apikeys_become_unscoped)
      printf '%s' "select count(*) from apikey" ;;
    p22_viewer_audit_view_rows)
      printf '%s' "select count(*) from org_role_permission orp join org_role r on orp.role_id = r.id where r.is_system and r.key = 'viewer' and orp.permission = 'audit:view' and orp.denied = false" ;;
    p22_readonly_audit_view_items)
      printf '%s' "select count(*) from org_permission_group_item gi join org_permission_group g on gi.group_id = g.id where g.is_system and g.key = 'read-only' and gi.permission = 'audit:view'" ;;
    p25_privilege_request_dups)
      printf '%s' "select count(*) from (select 1 from org_privilege_request where status = 'pending' group by membership_id, role_id, coalesce(team_id, '00000000-0000-0000-0000-000000000000'::uuid) having count(*) > 1) d" ;;
    p25_team_member_no_team)
      printf '%s' "select count(*) from team_member tm left join team t on t.id = tm.team_id where t.id is null" ;;
    p25_team_member_not_org_member)
      printf '%s' "select count(*) from team_member tm join team t on t.id = tm.team_id left join organization_member om on om.organization_id = t.organization_id and om.user_id = tm.user_id where om.id is null" ;;
    p25_org_role_bad_key)
      printf '%s' "select count(*) from org_role where key is not null and key !~ '^[a-z0-9][a-z0-9-]{1,63}\$'" ;;
    p25_org_role_key_collision)
      printf '%s' "select count(*) from (select organization_id, coalesce(key, 'custom-' || left(replace(id::text, '-', ''), 8)) k from org_role group by 1, 2 having count(*) > 1) d" ;;
    p25_grant_bad_type)
      printf '%s' "select count(*) from org_resource_grant where resource_type not in ('agents','assistants','knowledge','mcp','teams','workflows')" ;;
    p25_grant_non_uuid)
      printf '%s' "select count(*) from org_resource_grant where resource_id::text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$'" ;;
    p25_grant_dangling)
      # Only well-formed ids are cast; malformed ones are p25_grant_non_uuid's.
      printf '%s' "select count(*) from org_resource_grant g where resource_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$' and (
        (g.resource_type = 'agents'     and not exists (select 1 from agent          t where t.id = g.resource_id::uuid)) or
        (g.resource_type = 'assistants' and not exists (select 1 from assistant      t where t.id = g.resource_id::uuid)) or
        (g.resource_type = 'knowledge'  and not exists (select 1 from knowledge_base t where t.id = g.resource_id::uuid)) or
        (g.resource_type = 'mcp'        and not exists (select 1 from mcp_server     t where t.id = g.resource_id::uuid)) or
        (g.resource_type = 'teams'      and not exists (select 1 from team           t where t.id = g.resource_id::uuid)) or
        (g.resource_type = 'workflows'  and not exists (select 1 from workflow       t where t.id = g.resource_id::uuid)))" ;;
    p25_grant_extra_cols)
      printf '%s' "select count(*) from (select attname from pg_attribute where attrelid = 'public.org_resource_grant'::regclass and attnum > 0 and not attisdropped except select unnest(array['id','organization_id','membership_id','resource_type','resource_id','permission','granted_by','granted_at','expires_at'])) x" ;;
    p25_unknown_permissions)
      local slugs; slugs=$(sql_in_list "$(permission_catalog_slugs "${CHECKS_P25_DELTA:-db/1.25.0/migrate-1.25.0.sql}" | tr '\n' ' ')")
      [ -n "$slugs" ] || slugs="''"
      printf '%s' "select count(*) from (select permission from org_role_permission union select permission from org_permission_group_item union select permission from org_resource_grant) p where p.permission not in ($slugs)" ;;
    p25_junction_orphans)
      printf '%s' "select (select count(*) from org_role_permission rp left join org_role r on r.id = rp.role_id where r.id is null) + (select count(*) from org_permission_group_item gi left join org_permission_group g on g.id = gi.group_id where g.id is null) + (select count(*) from org_role_permission_group rg left join org_role r on r.id = rg.role_id where r.id is null)" ;;
    p25_role_group_org_mismatch)
      printf '%s' "select count(*) from org_role_permission_group rg join org_role r on r.id = rg.role_id join org_permission_group g on g.id = rg.group_id where r.organization_id <> g.organization_id" ;;
    p26_audit_chain_head_rows)
      printf '%s' "select count(*) from audit_chain_head" ;;
    p29_app_role_can_bypass_rls)
      printf '%s' "select count(*) from pg_roles where rolname = 'neo_gen' and (rolsuper or rolbypassrls)" ;;
    p35_agent_memory_rows)
      printf '%s' "select count(*) from agent_memory" ;;
    rls_posture)
      printf '%s' "select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relforcerowsecurity" ;;
    privileged_role_present)
      printf '%s' "select count(*) from pg_roles where rolname = 'neogen_priv' and rolbypassrls" ;;
    *) return 1 ;;
  esac
}

# check_sample_sql NAME — a short listing of the offending rows (may be empty).
check_sample_sql() {
  case "$1" in
    cron_dup_running)             printf '%s' "select cron_job_id, count(*) from cron_run_log where status='running' group by cron_job_id having count(*) > 1" ;;
    invoice_dups)                 printf '%s' "select organization_id, external_invoice_id, count(*) as copies, min(issued_at) as earliest from invoice where external_invoice_id is not null group by 1,2 having count(*) > 1 order by 3 desc limit 20" ;;
    org_invite_pending_dups)      printf '%s' "select organization_id, invited_email, count(*) as pending, max(expires_at) as keep_this_one from org_invite where accepted_at is null group by 1,2 having count(*) > 1 order by 3 desc limit 20" ;;
    p25_privilege_request_dups)   printf '%s' "select membership_id, role_id, coalesce(team_id::text,'org-wide') as team, count(*) from org_privilege_request where status='pending' group by 1,2,3 having count(*) > 1 limit 20" ;;
    p25_team_member_no_team)      printf '%s' "select tm.id, tm.team_id, tm.user_id from team_member tm left join team t on t.id = tm.team_id where t.id is null limit 20" ;;
    p25_team_member_not_org_member) printf '%s' "select tm.id as team_member, t.id as team, t.organization_id as org, tm.user_id from team_member tm join team t on t.id = tm.team_id left join organization_member om on om.organization_id = t.organization_id and om.user_id = tm.user_id where om.id is null limit 20" ;;
    p25_org_role_bad_key)         printf '%s' "select id, organization_id, key from org_role where key is not null and key !~ '^[a-z0-9][a-z0-9-]{1,63}\$' limit 20" ;;
    p25_org_role_key_collision)   printf '%s' "select organization_id, coalesce(key, 'custom-' || left(replace(id::text,'-',''), 8)) as key, count(*) from org_role group by 1,2 having count(*) > 1 limit 20" ;;
    p25_grant_bad_type)           printf '%s' "select resource_type, count(*) from org_resource_grant where resource_type not in ('agents','assistants','knowledge','mcp','teams','workflows') group by 1" ;;
    p25_grant_non_uuid)           printf '%s' "select organization_id, resource_type, resource_id from org_resource_grant where resource_id::text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$' limit 20" ;;
    p25_grant_dangling)           printf '%s' "select g.id, g.organization_id, g.resource_type, g.resource_id, g.permission from org_resource_grant g where resource_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$' and ((g.resource_type='agents' and not exists (select 1 from agent t where t.id=g.resource_id::uuid)) or (g.resource_type='assistants' and not exists (select 1 from assistant t where t.id=g.resource_id::uuid)) or (g.resource_type='knowledge' and not exists (select 1 from knowledge_base t where t.id=g.resource_id::uuid)) or (g.resource_type='mcp' and not exists (select 1 from mcp_server t where t.id=g.resource_id::uuid)) or (g.resource_type='teams' and not exists (select 1 from team t where t.id=g.resource_id::uuid)) or (g.resource_type='workflows' and not exists (select 1 from workflow t where t.id=g.resource_id::uuid))) limit 20" ;;
    p25_grant_extra_cols)         printf '%s' "select attname from pg_attribute where attrelid = 'public.org_resource_grant'::regclass and attnum > 0 and not attisdropped except select unnest(array['id','organization_id','membership_id','resource_type','resource_id','permission','granted_by','granted_at','expires_at'])" ;;
    p25_unknown_permissions)      local slugs; slugs=$(sql_in_list "$(permission_catalog_slugs "${CHECKS_P25_DELTA:-db/1.25.0/migrate-1.25.0.sql}" | tr '\n' ' ')"); [ -n "$slugs" ] || slugs="''"
                                  printf '%s' "select p.permission, count(*) from (select permission, 'role' as src from org_role_permission union all select permission, 'group' from org_permission_group_item union all select permission, 'grant' from org_resource_grant) p where p.permission not in ($slugs) group by 1 order by 2 desc limit 20" ;;
    p25_junction_orphans)         printf '%s' "select 'org_role_permission' as junction, rp.role_id::text as parent, rp.permission from org_role_permission rp left join org_role r on r.id = rp.role_id where r.id is null union all select 'org_permission_group_item', gi.group_id::text, gi.permission from org_permission_group_item gi left join org_permission_group g on g.id = gi.group_id where g.id is null union all select 'org_role_permission_group', rg.role_id::text, rg.group_id::text from org_role_permission_group rg left join org_role r on r.id = rg.role_id where r.id is null limit 20" ;;
    p25_role_group_org_mismatch)  printf '%s' "select rg.role_id, r.organization_id as role_org, rg.group_id, g.organization_id as group_org from org_role_permission_group rg join org_role r on r.id = rg.role_id join org_permission_group g on g.id = rg.group_id where r.organization_id <> g.organization_id limit 20" ;;
    p29_app_role_can_bypass_rls)  printf '%s' "select rolname, rolsuper, rolbypassrls from pg_roles where rolname in ('neo_gen','neogen_priv','neogen_admin')" ;;
    *) printf '' ;;
  esac
}

# check_skip NAME — 0 when the check is moot on THIS database.
check_skip() {
  case "$1" in
    cron_dup_running)
      # 1.9.0 built the one-running-per-job index and 1.35.0 re-applies it
      # guarded; once it exists the duplicate question is already answered.
      [ "$(psql_scalar "select 1 from pg_indexes where schemaname='public' and indexname='cron_run_log_one_running_per_job'")" = "1" ] ;;
    *) return 1 ;;
  esac
}
check_skip_reason() {
  case "$1" in
    cron_dup_running) printf 'cron_run_log_one_running_per_job already exists' ;;
    *) printf 'moot' ;;
  esac
}

# The only two database touches the runner makes (stubbed by the harness).
check_count()  { psql_scalar "$(check_sql "$1")"; }
check_sample() { local s; s=$(check_sample_sql "$1"); [ -n "$s" ] && psql_admin -c "$s" </dev/null 2>/dev/null | sed 's/^/        /' || true; }

# checks_for_pending PENDING — names of the checks that apply when the given
# migrate-*.sql basenames (one per line) are pending. `always` checks are
# included regardless.
checks_for_pending() {
  local pending="$1" name gate sev req title g
  while IFS=$'\t' read -r name gate sev req title; do
    [ -n "$name" ] || continue
    if [ "$gate" = "always" ]; then printf '%s\n' "$name"; continue; fi
    # Here-strings, not `printf | grep -q`: under pipefail an early grep exit
    # can SIGPIPE the producer and turn a match into a non-zero pipeline.
    for g in ${gate//,/ }; do
      if grep -qx "$g" <<<"$pending"; then printf '%s\n' "$name"; break; fi
    done
  done <<<"$CHECKS"
}

# run_checks MODE PENDING — MODE `report` prints every verdict and returns 0;
# MODE `die` prints them and exits 1 when any blocker or unreadable check
# remains (acks are the caller's to collect — upgrade-db.sh prompts for them).
# Sets CHECK_BLOCKERS, CHECK_ACKS (name<SP>WORD<SP>count per line),
# CHECK_UNAVAILABLE, CHECK_INFO (name<TAB>count per line).
CHECK_BLOCKERS=""; CHECK_ACKS=""; CHECK_UNAVAILABLE=""; CHECK_INFO=""
run_checks() {
  local mode="$1" pending="$2" name gate sev req title n t applies
  CHECK_BLOCKERS=""; CHECK_ACKS=""; CHECK_UNAVAILABLE=""; CHECK_INFO=""
  local selected; selected=$(checks_for_pending "$pending")
  while IFS=$'\t' read -r name gate sev req title; do
    [ -n "$name" ] || continue
    grep -qx "$name" <<<"$selected" || continue
    applies=yes
    if [ "$req" != "-" ]; then
      for t in ${req//,/ }; do rel_ready "$t" || { applies="$t"; break; }; done
    fi
    if [ "$applies" != "yes" ]; then printf 'n/a   %-32s %s is not in its shape yet\n' "$name" "$applies"; continue; fi
    if check_skip "$name"; then printf 'n/a   %-32s %s\n' "$name" "$(check_skip_reason "$name")"; continue; fi
    n=$(check_count "$name")
    case "$n" in
      ''|*[!0-9]*)
        printf '??    %-32s could not be evaluated (postgres busy? query error?) — %s\n' "$name" "$title"
        CHECK_UNAVAILABLE="${CHECK_UNAVAILABLE}${name}"$'\n'; continue ;;
    esac
    case "$sev" in
      info)
        printf 'info  %-32s %s — %s\n' "$name" "$n" "$title"
        CHECK_INFO="${CHECK_INFO}${name}"$'\t'"${n}"$'\n' ;;
      block)
        if [ "$n" = "0" ]; then printf 'ok    %-32s 0 — %s\n' "$name" "$title"
        else
          printf 'BLOCK %-32s %s — %s\n' "$name" "$n" "$title"; check_sample "$name"
          CHECK_BLOCKERS="${CHECK_BLOCKERS}${name}"$'\n'
        fi ;;
      ack:*)
        if [ "$n" = "0" ]; then printf 'ok    %-32s 0 — %s\n' "$name" "$title"
        else
          printf 'ACK   %-32s %s — %s (type %s to accept)\n' "$name" "$n" "$title" "${sev#ack:}"; check_sample "$name"
          CHECK_ACKS="${CHECK_ACKS}${name} ${sev#ack:} ${n}"$'\n'
        fi ;;
    esac
  done <<<"$CHECKS"
  CHECK_BLOCKERS=${CHECK_BLOCKERS%$'\n'}; CHECK_ACKS=${CHECK_ACKS%$'\n'}
  CHECK_UNAVAILABLE=${CHECK_UNAVAILABLE%$'\n'}; CHECK_INFO=${CHECK_INFO%$'\n'}
  if [ "$mode" = "die" ] && ! checks_verdict; then
    die "pre-checks found blocker(s) or could not evaluate a check — see BLOCK / ?? lines above. Nothing was changed."
  fi
  return 0
}

# checks_verdict — 0 when the last run_checks found no blocker and evaluated
# every applicable check; 1 otherwise (fail closed).
checks_verdict() { [ -z "$CHECK_BLOCKERS" ] && [ -z "$CHECK_UNAVAILABLE" ]; }

# check_info_count NAME — the count an info check produced in the last run.
check_info_count() { printf '%s\n' "$CHECK_INFO" | awk -F'\t' -v n="$1" '$1==n{print $2; exit}'; }

# expect_rows_for PENDING — the allow-list rowcount_compare needs for this set
# of pending deltas (table<TAB>kind<TAB>reason, see lib.sh). Exact 1.22.0
# counts come from check_count; a later 1.25.0 in the same run relaxes them.
expect_rows_for() {
  local pending="$1" n
  has() { grep -qx "$1" <<<"$pending"; }
  if has migrate-1.22.0.sql; then
    n=$(check_count p22_viewer_audit_view_rows);    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf 'org_role_permission\tshrink=%s\t1.22.0/0005: the system viewer role loses audit:view (moved to security-admin)\n' "$n"
    n=$(check_count p22_readonly_audit_view_items); case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf 'org_permission_group_item\tshrink=%s\t1.22.0/0005: the system read-only pack loses audit:view\n' "$n"
  fi
  if has migrate-1.25.0.sql; then
    printf 'org_role_permission\tshrink\t1.25.0/0016: materialised catalog defaults deleted from SYSTEM roles (custom roles and deny rows untouched)\n'
    printf 'org_permission_group_item\tshrink\t1.25.0/0016: materialised catalog defaults deleted from SYSTEM packs\n'
    printf 'org_permission_group\tshrink\t1.25.0/0016: emptied, unreferenced SYSTEM packs deleted (re-created on next groups-panel load)\n'
    printf 'permission_catalog\tgrow\t1.25.0/0012: seeds the permission vocabulary\n'
    printf 'org_resource_grant\tsame\t1.25.0/0015: checksummed rebuild as a partitioned table — MUST be equal\n'
  fi
  if has migrate-1.27.0.sql; then
    printf 'sod_rule\tgrow\t1.27.0/0023: platform separation-of-duties defaults\n'
  fi
  if has migrate-1.35.0.sql; then
    printf 'agent_memory\tgone\t1.35.0/0036 (legacy 0094): the orphan agent_memory table is dropped\n'
  fi
  if has migrate-1.40.1.sql; then
    printf 'permission_catalog\tgrow\t1.40.1: upsert repair of the catalog (no-op on a migrated database)\n'
    printf 'sod_rule\tgrow\t1.40.1: upsert repair of the platform sod_rule rows (no-op on a migrated database)\n'
  fi
  unset -f has
}
