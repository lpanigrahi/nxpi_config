#!/usr/bin/env bash
# Mark bulk-imported users at a domain as email-verified, so Better Auth will
# link their Microsoft/Google sign-in instead of refusing `account_not_linked`.
# Touches ONE column (user.email_verified) on rows that are: members of ONE org,
# at ONE email domain, role 'user'/'editor', not banned, currently unverified.
# Dry-run by default. --apply writes a backup + rollback file first.
#
#   ./fix-bulk-import-email-verified.sh --list-orgs
#   ./fix-bulk-import-email-verified.sh --org-id <uuid>                 # dry run
#   ./fix-bulk-import-email-verified.sh --org-id <uuid> --email a@x --apply
#   ./fix-bulk-import-email-verified.sh --org-id <uuid> --apply
set -euo pipefail

DOMAIN="nbcbearings.in"
PG_CONTAINER="${PG_CONTAINER:-neogen-postgres-1}"
CADDY_CONTAINER="${CADDY_CONTAINER:-neogen-caddy-1}"
SITE_HOST="${SITE_HOST:-momentumai.nbcbearings.in}"
ORG_ID="" ONLY_EMAIL="" APPLY=0 LIST_ORGS=0 SKIP_HOST_CHECK=0

die() { echo "ERROR: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org-id) ORG_ID="${2:-}"; shift 2 ;;
    --domain) DOMAIN="${2:-}"; shift 2 ;;
    --email) ONLY_EMAIL="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --list-orgs) LIST_ORGS=1; shift ;;
    --skip-host-check) SKIP_HOST_CHECK=1; shift ;;
    -h|--help) sed -n 2,12p "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

DOMAIN="$(tr '[:upper:]' '[:lower:]' <<<"$DOMAIN")"
ONLY_EMAIL="$(tr '[:upper:]' '[:lower:]' <<<"$ONLY_EMAIL")"
[[ "$DOMAIN" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]] || die "bad --domain: $DOMAIN"
if [[ -n "$ONLY_EMAIL" && "$ONLY_EMAIL" != *"@$DOMAIN" ]]; then
  die "--email must be at @$DOMAIN"
fi

# psql inside the container, as the image's own superuser and database.
# Variables go in with -v and are quoted by psql (:'name'), never by bash.
psql_c() {
  docker exec -i ${PG_DB:+-e PG_DB="$PG_DB"} "$PG_CONTAINER" sh -c \
    'psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "${PG_DB:-$POSTGRES_DB}" "$@"' \
    psql -v domain="$DOMAIN" -v org="$ORG_ID" -v only_email="$ONLY_EMAIL" "$@"
}

docker inspect "$PG_CONTAINER" >/dev/null 2>&1 || die "container $PG_CONTAINER not found"

# Wrong-server guard: this VM must actually serve the affected site.
if [[ $SKIP_HOST_CHECK -eq 0 ]]; then
  docker exec "$CADDY_CONTAINER" sh -c "grep -rqs '$SITE_HOST' /etc/caddy/" \
    || die "$CADDY_CONTAINER does not serve $SITE_HOST — wrong VM? (--skip-host-check to override)"
fi

if [[ $LIST_ORGS -eq 1 ]]; then
  psql_c <<'SQL'
\echo 'Organizations with unverified users at the domain:'
SELECT o.id, o.name, count(*) AS unverified_users
FROM "user" u
JOIN organization_member m ON m.user_id = u.id
JOIN organization o ON o.id = m.organization_id
WHERE u.email_verified = false
  AND lower(u.email) LIKE '%@' || :'domain'
GROUP BY o.id, o.name
ORDER BY unverified_users DESC;
SQL
  exit 0
fi

[[ "$ORG_ID" =~ ^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$ ]] \
  || die "--org-id <uuid> is required (find it with --list-orgs)"

# The ONE predicate, used for the backup, the update and the re-check.
TARGETS_SQL=$(cat <<'SQL'
SELECT u.id, u.email, u.role, u.created_at
FROM "user" u
WHERE u.email_verified = false
  AND u.banned = false
  AND u.role IN ('user', 'editor')
  AND lower(u.email) LIKE '%@' || :'domain'
  AND (:'only_email' = '' OR lower(u.email) = :'only_email')
  AND EXISTS (SELECT 1 FROM organization_member m
              WHERE m.user_id = u.id AND m.organization_id = :'org')
SQL
)

echo "== Pre-flight: $DOMAIN, org $ORG_ID =="
psql_c <<'SQL'
SELECT count(*) > 0 AS org_found, max(name) AS org_name
FROM organization WHERE id = :'org' \gset
\if :org_found
  \echo 'Organization:' :org_name
\else
  DO $$BEGIN RAISE EXCEPTION 'organization not found'; END$$;
\endif

-- A VERIFIED claim on this domain by ANOTHER org would auto-join these users
-- into that org once they are verified. Refuse rather than move people.
SELECT count(*) > 0 AS foreign_claims FROM org_domain_claim
WHERE lower(domain) = :'domain' AND verified AND organization_id <> :'org' \gset
\if :foreign_claims
  \echo 'ERROR: another organization has verified this domain:'
  SELECT organization_id, domain, auto_assign FROM org_domain_claim
  WHERE lower(domain) = :'domain' AND verified AND organization_id <> :'org';
  DO $$BEGIN RAISE EXCEPTION 'domain verified by another organization'; END$$;
\endif
\echo 'Domain claims for this org (fine if empty):'
SELECT domain, verified, auto_assign FROM org_domain_claim
WHERE lower(domain) = :'domain' AND organization_id = :'org';
SQL

count=$(psql_c -t -A <<SQL
SELECT count(*) FROM ($TARGETS_SQL) t;
SQL
)
count="${count//[[:space:]]/}"
echo "Users to verify: $count"
[[ "$count" -gt 0 ]] || { echo "Nothing to do."; exit 0; }

echo "Sample:"
psql_c <<SQL
SELECT email, role, created_at FROM ($TARGETS_SQL) t ORDER BY email LIMIT 10;
SQL

if [[ $APPLY -eq 0 ]]; then
  echo "DRY RUN — nothing changed. Re-run with --apply."
  exit 0
fi

OUT="$(mktemp -d "$HOME/email-verify-$(date +%Y%m%d-%H%M%S)-XXXX")"
psql_c <<SQL >"$OUT/before.csv"
COPY ($TARGETS_SQL ORDER BY email) TO STDOUT WITH CSV HEADER;
SQL
backup_rows=$(($(wc -l <"$OUT/before.csv") - 1))
[[ "$backup_rows" -eq "$count" ]] || die "backup has $backup_rows rows, expected $count"

# Rollback = set the flag back on exactly these ids.
{
  echo "BEGIN;"
  echo "UPDATE \"user\" SET email_verified = false WHERE id IN ("
  tail -n +2 "$OUT/before.csv" | cut -d, -f1 | sed "s/.*/  '&'/" | paste -sd, -
  echo ");"
  echo "-- expect UPDATE $count, then: COMMIT;"
} >"$OUT/rollback.sql"
echo "Backup:   $OUT/before.csv ($backup_rows rows)"
echo "Rollback: $OUT/rollback.sql"

read -r -p "Type VERIFY $count to apply: " answer
[[ "$answer" == "VERIFY $count" ]] || die "not confirmed; nothing changed"

# One short transaction. Give up rather than queue behind live traffic, and
# commit only if the rows updated match the backup exactly.
psql_c -v expected="$count" <<SQL
SET lock_timeout = '5s';
SET statement_timeout = '60s';
BEGIN;
WITH targets AS ($TARGETS_SQL),
updated AS (
  UPDATE "user" u SET email_verified = true, updated_at = now()
  FROM targets t WHERE u.id = t.id
  RETURNING u.id
)
SELECT count(*) AS updated FROM updated \gset
SELECT (:updated = :expected) AS matches \gset
\if :matches
  COMMIT;
  \echo 'Committed:' :updated 'users verified.'
\else
  ROLLBACK;
  \echo 'ROLLED BACK: updated' :updated 'but expected' :expected
  DO \$\$BEGIN RAISE EXCEPTION 'row count mismatch, rolled back'; END\$\$;
\endif
SQL

remaining=$(psql_c -t -A <<SQL
SELECT count(*) FROM ($TARGETS_SQL) t;
SQL
)
echo "Still unverified after run: ${remaining//[[:space:]]/} (expect 0)"
