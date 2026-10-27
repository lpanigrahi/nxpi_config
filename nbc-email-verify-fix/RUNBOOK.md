# Runbook: fix "Unable to sign in — account_not_linked" for bulk-imported users

| | |
|---|---|
| **Site** | `https://momentumai.nbcbearings.in` |
| **Affected** | ~1200 users created by **bulk import** at `@nbcbearings.in` |
| **Symptom** | "Sign in with Microsoft/Google" lands on `/api/auth/error?error=account_not_linked` — *"An account with this email already exists…"* |
| **Script** | `fix-bulk-import-email-verified.sh` (this folder) |
| **Run on** | The production VM that serves the site (Docker host with `neogen-postgres-1`) |
| **Duration** | ~10 minutes including checks; the update itself takes under a second |
| **Downtime** | None. The app stays up. |

---

## 1. Why users cannot sign in

1. The bulk import created every user with `email_verified = false`. Import only sets it to
   `true` when the org has a **DNS-verified domain claim** for the email's domain, and
   `nbcbearings.in` was imported with the domain check skipped.
2. When a user then signs in with Microsoft/Google, Better Auth finds the existing account with
   the same email and tries to link the new provider to it. Its rule is: **never link a social
   login onto a local account whose email is not verified** (`requireLocalEmailVerified`,
   default `true`). This protects against account takeover.
3. The link is refused, no session is created, and the user sees the error page.

The fix marks those users' emails as verified. They are corporate addresses the organization
owns, and the import would have done exactly this had the domain been verified at the time.
On the next Microsoft/Google sign-in, Better Auth links the provider to the existing account.
Password sign-in keeps working alongside it.

> **Do not** "fix" this by setting `requireLocalEmailVerified: false` in the app. That
> re-opens the account-takeover hole for every user on the platform.

---

## 2. What the script changes, and what it does not

**Changes:** one column, `user.email_verified` (`false` → `true`), plus `updated_at`, and only
for users who meet **all** of these conditions:

- are a member of the organization you pass with `--org-id`
- have an email ending in exactly `@nbcbearings.in` (any capitalisation)
- have role `user` or `editor`
- are not banned
- are currently unverified

**Never touches:** passwords, sessions, roles, organization or team memberships, admins,
`platform-*` role accounts, banned users, other domains, other organizations, or any other
table.

**Built-in safety:**

| Guard | Behaviour |
|---|---|
| Dry run by default | Nothing is written unless you pass `--apply` |
| Wrong-server hint | Warns (does not exit) if the domain is not found in Caddy/app config |
| Org check | Exits if the org id does not exist |
| Foreign domain claim | Exits if **another** org has verified `nbcbearings.in`. Verified users would otherwise be auto-joined into that org at their next sign-in. |
| Backup first | Writes `before.csv` and `rollback.sql` before any change |
| Typed confirmation | You must type `VERIFY <exact count>`; anything else exits with no change |
| Count match | The update is one transaction and commits only if rows changed = rows backed up; otherwise it rolls back |
| Live traffic | `lock_timeout 5s`, `statement_timeout 60s`: gives up rather than blocking the app |
| Re-runnable | Already-verified users are skipped; a second run prints `Nothing to do.` |
| Injection-safe | Org id must be a UUID; every value is passed to psql as a variable, never pasted into SQL |

---

## 3. Before you start

- [ ] SSH access to the production VM (`ssh neogen-vm` or equivalent) with permission to run `docker`
- [ ] The email of **one affected user** who can test sign-in with you
- [ ] A maintenance note to whoever else administers the platform (optional; there is no downtime)

You do **not** need the database password. The script runs `psql` inside the Postgres
container as the container's own superuser.

---

## 4. Step by step

### Step 1: Copy the script to the VM

From the machine that has this folder:

```bash
scp fix-bulk-import-email-verified.sh neogen-vm:~/
ssh neogen-vm
chmod +x ~/fix-bulk-import-email-verified.sh
cd ~
```

### Step 2: Confirm you are on the right server

```bash
docker ps --format '{{.Names}}' | grep -E 'neogen-(postgres|caddy|app)-1'
```

**Expect:** the three container names. If any is missing, stop.

Where the domain is configured differs per VM (Caddyfile, `SITE_ADDRESS`, or TLS
terminated upstream on older hosts), so the script only **warns** if it cannot find
`momentumai.nbcbearings.in` in config. The real proof that you are on the right server
comes in Steps 3–4: the organization and ~1200 `@nbcbearings.in` users must be in
**this** database.

### Step 3: Find the organization id (read-only)

```bash
./fix-bulk-import-email-verified.sh --list-orgs
```

**Expect** something like:

```
                  id                  |      name       | unverified_users
--------------------------------------+-----------------+------------------
 6f1c…-…-…-…-…                         | NBC Bearings    |             1203
```

Copy the `id` of the organization the users were imported into. Every later command uses it as
`<ORG_ID>`.

### Step 4: Dry run (read-only)

```bash
./fix-bulk-import-email-verified.sh --org-id <ORG_ID>
```

**Expect:**

```
== Pre-flight: nbcbearings.in, org <ORG_ID> ==
Organization: <org name>
Domain claims for this org (fine if empty):
…
Users to verify: 1203
Sample:
 (10 emails, all @nbcbearings.in)
DRY RUN — nothing changed. Re-run with --apply.
```

Check that:

- [ ] the organization name is the right one
- [ ] the count is about what you expect (~1200)
- [ ] every sample email is `@nbcbearings.in`

### Step 5: Fix ONE user and test

```bash
./fix-bulk-import-email-verified.sh --org-id <ORG_ID> --email <test-user@nbcbearings.in> --apply
```

At the prompt type **`VERIFY 1`** and press Enter.

**Expect:**

```
Backup:   /home/azureuser/email-verify-<timestamp>-XXXX/before.csv (1 rows)
Rollback: /home/azureuser/email-verify-<timestamp>-XXXX/rollback.sql
Type VERIFY 1 to apply: VERIFY 1
Committed: 1 users verified.
Still unverified after run: 0 (expect 0)
```

Now ask the test user to:

1. open a **private/incognito** window
2. go to `https://momentumai.nbcbearings.in`
3. click **Sign in with Microsoft** (or Google)

**Expect:** they land inside the app, not on "Unable to sign in".
**If it still fails:** stop and roll back this user (section 6). The cause is something else,
so send the new error URL to engineering.

### Step 6: Fix everyone else

```bash
./fix-bulk-import-email-verified.sh --org-id <ORG_ID> --apply
```

At the prompt type **`VERIFY <count>`**, using exactly the number the script printed
(e.g. `VERIFY 1202`).

**Expect:**

```
Users to verify: 1202
…
Type VERIFY 1202 to apply: VERIFY 1202
Committed: 1202 users verified.
Still unverified after run: 0 (expect 0)
```

### Step 7: Confirm

```bash
./fix-bulk-import-email-verified.sh --org-id <ORG_ID>
```

**Expect:** `Users to verify: 0` / `Nothing to do.`
Then ask two or three more users to sign in with Microsoft/Google.

### Step 8: Keep the evidence

Each `--apply` run leaves a folder `~/email-verify-<timestamp>-XXXX/` holding:

- `before.csv`: every user id/email that was changed (the change record)
- `rollback.sql`: the exact undo for that run

Copy these folders somewhere safe (ticket attachment, ops share). Changes made by this script
are **not** written to the in-app Audit log, so these files are the record.

---

## 5. Stop conditions: when the script refuses

| Message | Meaning | What to do |
|---|---|---|
| `WARNING: could not confirm from config that this VM serves …` | Advisory only; the domain is configured somewhere the script does not look | Continue, but check the org name, count and sample emails in the dry run |
| `container neogen-postgres-1 not found` | Different container name on this VM | `docker ps`, then run with `PG_CONTAINER=<name> ./fix-…sh …` |
| `ERROR: organization not found` | Wrong org id | Re-run Step 3 |
| `ERROR: domain verified by another organization` | Another org owns `nbcbearings.in` | **Do not proceed.** Escalate to engineering; verifying users would move them into that org |
| `--email must be at @nbcbearings.in` | Typo in `--email` | Fix the address |
| `not confirmed; nothing changed` | Confirmation text did not match | Re-run and type `VERIFY <exact count>` |
| `backup has N rows, expected M` | Users changed between count and backup | Re-run; nothing was changed |
| `ROLLED BACK: updated N but expected M` / `row count mismatch` | Data changed mid-run | Nothing was committed. Re-run |
| `canceling statement due to lock timeout` | The `user` table was busy | Nothing was committed. Re-run in a quieter minute |

Every refusal exits **before** or **without** committing a change.

---

## 6. Rollback

Use the `rollback.sql` from the run you want to undo:

```bash
ls -d ~/email-verify-*        # pick the run's folder
RUN=~/email-verify-<timestamp>-XXXX

docker exec -i neogen-postgres-1 sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < "$RUN/rollback.sql"
```

This prints `UPDATE <n>` and then **rolls back automatically**, because the file deliberately
ends without `COMMIT`. When `<n>` matches the row count in `before.csv`, commit it for real:

```bash
( cat "$RUN/rollback.sql"; echo "COMMIT;" ) | \
  docker exec -i neogen-postgres-1 sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

Rollback sets exactly those user ids back to unverified. Any Microsoft/Google accounts users
linked in the meantime stay linked. That is harmless: those users simply keep their working
sign-in.

---

## 7. Prevent it happening again (do this after the fix)

The org needs a **verified domain** so future imports create verified users:

1. Sign in as platform admin → **Admin → Identity → Domains**
2. Select the organization → enter `nbcbearings.in` → **Add domain**
3. Publish the TXT record shown:
   - Name: `_nxpi-domain-verification.nbcbearings.in`
   - Value: the token shown on the row
4. After DNS propagates (`nslookup -type=TXT _nxpi-domain-verification.nbcbearings.in`),
   click **Verify**. The row shows **Verified**.
5. Leave **Auto-assign** off unless you want every new `@nbcbearings.in` account auto-joined.

Future bulk imports at that domain then need no "skip domain check" and no script.

---

## 8. Reference

**Options**

| Option | Purpose |
|---|---|
| `--list-orgs` | Read-only: orgs that have unverified users at the domain |
| `--org-id <uuid>` | Organization to fix (required except with `--list-orgs`) |
| `--email <addr>` | Limit to one user |
| `--apply` | Actually write (otherwise dry run) |
| `--domain <d>` | Default `nbcbearings.in` |
| `--skip-host-check` | Skip the advisory wrong-server hint |

**Environment overrides:** `PG_CONTAINER` (default `neogen-postgres-1`), `CADDY_CONTAINER`
(default `neogen-caddy-1`), `APP_CONTAINER` (default `neogen-app-1`), `SITE_HOST` (default `momentumai.nbcbearings.in`), `PG_DB`
(default: the container's `POSTGRES_DB`).

**Manual check of one user** (read-only):

```bash
docker exec -it neogen-postgres-1 sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' <<'SQL'
SELECT u.email, u.email_verified, u.role, array_agg(a.provider_id) AS providers
FROM "user" u LEFT JOIN account a ON a.user_id = u.id
WHERE lower(u.email) = lower('<user@nbcbearings.in>')
GROUP BY u.id;
SQL
```

Before the fix: `email_verified = f`, providers `{credential}`. After a successful Microsoft
sign-in: `email_verified = t`, providers `{credential,microsoft}`.

**Tested** against a scratch database: single-user apply, full apply, re-run (no-op), rollback,
and every refusal in section 5 (wrong org, wrong server, foreign verified claim, wrong
confirmation, wrong email domain, malformed org id). Admin, `platform-*`, banned, other-domain
and other-org users were confirmed untouched.
