#!/usr/bin/env bash
# =============================================================================
# provision-privileged-role.sh — mint (or converge) the BYPASSRLS database role
# behind secrets/postgres_privileged_url, idempotently.
#
#   ./provision-privileged-role.sh            # create/converge neogen_priv, set its password, verify a login
#   ./provision-privileged-role.sh --check    # report only (exit 1 when anything is missing)
#
# WHY. db 1.29.0 ENABLEs and FORCEs row-level security on the tenant tables.
# The app's background CROSS-TENANT sweeps (expired role assignments and
# resource grants, knowledge-document and vector-store GC) run on a privileged
# pool that must be able to see every organization; when POSTGRES_PRIVILEGED_URL
# is unset the app falls back to POSTGRES_URL — the least-privilege neo_gen
# role — and those sweeps match ZERO rows, silently. This script is the other
# half of the .env opt-in (POSTGRES_PRIVILEGED_URL_FILE, see .env.example):
#
#   CREATE ROLE neogen_priv LOGIN BYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE
#     IN ROLE neo_gen;          -- inherits every grant / default privilege /
#                               -- REVOKE aimed at the app role (1.33.0's
#                               -- quarantine table stays SELECT-only)
#   ALTER ROLE neogen_priv PASSWORD '<from secrets/postgres_privileged_url>';
#
# The role has BYPASSRLS and nothing else: not SUPERUSER, so the app's
# DB_ROLE_PREFLIGHT (which refuses a SUPERUSER/BYPASSRLS MAIN pool) is
# untouched — neo_gen stays the main pool. Run BEFORE the 1.29.0 delta (the
# role is harmless on an un-forced schema and ready when the new image boots);
# ./install.sh calls it when the .env flag is set, so does upgrade-release.sh.
# =============================================================================
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"
# shellcheck source=lib.sh
. ./lib.sh

CHECK=false
for arg in "$@"; do
  case "$arg" in
    --check)   CHECK=true ;;
    -h|--help) sed -n '2,/^# ===/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown flag: $arg (see --help)" ;;
  esac
done

init_docker
$CHECK || acquire_lock

ROLE=neogen_priv
FLAG=$(env_get .env POSTGRES_PRIVILEGED_URL_FILE "")
role_exists()   { [ "$(psql_scalar "select 1 from pg_roles where rolname='$ROLE'")" = "1" ]; }
role_bypass()   { [ "$(psql_scalar "select 1 from pg_roles where rolname='$ROLE' and rolbypassrls and not rolsuper and rolcanlogin")" = "1" ]; }
role_member()   { [ "$(psql_scalar "select 1 from pg_auth_members m join pg_roles r on r.oid=m.roleid join pg_roles u on u.oid=m.member where r.rolname='neo_gen' and u.rolname='$ROLE'")" = "1" ]; }
login_works()   { # authenticate over TCP inside the postgres container, exactly as the app would
  local pw; pw=$(privileged_role_password)
  [ -n "$pw" ] || return 1
  [ "$(compose exec -T -e PGPASSWORD="$pw" postgres psql -h localhost -U "$ROLE" -d neogen -tAc 'select current_user' 2>/dev/null | tr -d '[:space:]')" = "$ROLE" ]
}

hdr "Privileged pool ($ROLE)"
PG_CID=$(compose ps -q postgres 2>/dev/null | head -n1 || true)
[ -n "$PG_CID" ] || die "postgres is not running"
wait_healthy postgres 60 >/dev/null || die "postgres is not healthy"

if $CHECK; then
  RC=0
  [ -s secrets/postgres_privileged_url ] && ok "secrets/postgres_privileged_url present" || { warn "secrets/postgres_privileged_url missing — run ./install.sh"; RC=1; }
  [ -n "$FLAG" ] && ok ".env wires it into the app (POSTGRES_PRIVILEGED_URL_FILE=$FLAG)" || { warn "POSTGRES_PRIVILEGED_URL_FILE is unset in ./.env — the app will not use the role"; RC=1; }
  role_exists && ok "role exists" || { warn "role $ROLE does not exist"; RC=1; }
  role_bypass && ok "role is LOGIN + BYPASSRLS and not SUPERUSER" || { warn "role $ROLE lacks BYPASSRLS/LOGIN or is SUPERUSER"; RC=1; }
  role_member && ok "role is a member of neo_gen (inherits its grants)" || { warn "role $ROLE is not IN ROLE neo_gen"; RC=1; }
  if role_exists; then login_works && ok "TCP login with the secret's password works" || { warn "login as $ROLE with secrets/postgres_privileged_url FAILED (password drift?) — re-run without --check"; RC=1; }; fi
  exit $RC
fi

[ -s secrets/postgres_privileged_url ] || die "secrets/postgres_privileged_url is missing — run ./install.sh first (it generates it, create-if-missing)"
PW=$(privileged_role_password)
[ -n "$PW" ] || die "could not read the password from secrets/postgres_privileged_url (sudo needed? the file is uid 1001 / mode 400)"
[ -n "$FLAG" ] || warn "POSTGRES_PRIVILEGED_URL_FILE is unset in ./.env — the role will exist but the app will not use it until you set it (see .env.example) and recreate the app container"

log "creating or converging $ROLE (LOGIN BYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE, IN ROLE neo_gen)…"
psql_admin -c "DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '$ROLE') THEN
    CREATE ROLE $ROLE LOGIN BYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE IN ROLE neo_gen;
  END IF;
END \$\$;" </dev/null >/dev/null || die "CREATE ROLE failed"
psql_admin -c "ALTER ROLE $ROLE WITH LOGIN BYPASSRLS NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;" </dev/null >/dev/null || die "ALTER ROLE failed"
psql_admin -c "GRANT neo_gen TO $ROLE;" </dev/null >/dev/null || die "GRANT neo_gen TO $ROLE failed"
# The password travels as a psql VARIABLE on stdin (psql interpolates :'pw'
# in scripts read from stdin, quoting it as a literal), never as SQL text.
printf "ALTER ROLE %s PASSWORD :'pw';\n" "$ROLE" | psql_admin -v pw="$PW" >/dev/null || die "setting the password failed"

role_bypass || die "$ROLE exists but is not LOGIN+BYPASSRLS (or is SUPERUSER) after convergence — inspect pg_roles"
role_member || die "$ROLE is not a member of neo_gen after convergence"
login_works || die "login as $ROLE with the secret's password does not work — the secret and the role disagree"
ok "$ROLE ready: BYPASSRLS, member of neo_gen, password matches secrets/postgres_privileged_url"
if [ -n "$FLAG" ]; then
  log "the app reads it via POSTGRES_PRIVILEGED_URL_FILE — recreate the app container to pick it up:  ./compose.sh up -d app"
fi
