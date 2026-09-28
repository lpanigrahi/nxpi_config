-- migrate-1.37.0.sql — schema delta 1.36.0 → 1.37.0 (R14 QA campaign, plane P10, finding F11): the three columns better-auth 1.6.22's twoFactor plugin maps and `two_factor` never grew. Source migration 0038 (journaled migration 0038_two_factor_plugin_fields.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- The better-auth drizzle adapter inserts EVERY field the plugin's model
-- declares and resolves each as a property of the mapped table. 1.4's twoFactor
-- model was `secret`/`backup_codes`/`user_id`; 1.6.22's is those three plus
-- `verified`, `failed_verification_count` and `locked_until`. The 1.4 → 1.6
-- upgrade reconciled the `apikey` table and left this one alone, so on every
-- database carrying this lineage `POST /api/auth/two-factor/enable` answers
-- **500 with an empty body** on `BetterAuthError: The field "verified" does not
-- exist in the "twoFactor" Drizzle schema`. NO `two_factor` ROW CAN BE CREATED
-- ON A 1.6 DEPLOYMENT — the adapter emits `verified` on every insert, so both
-- the vendor door and the app's credential-less one fail the same way — and an
-- organization that switches on "Require MFA" gates every member behind an
-- enrolment door that cannot open, with no in-product way back. Rows written
-- BEFORE the 1.6 upgrade survive it and keep working; the count is 0 SINCE the
-- upgrade, not 0 outright, and the `verified DEFAULT true` below exists for
-- exactly those surviving rows. This delta adds the three columns; the app
-- image ships the matching table definition and a boot sentinel per column, so
-- an image rolled ahead of this file now fails its boot probe by name instead
-- of 500ing at request time.
--
-- ONE THING HEALS ITSELF RATHER THAN BEING MIGRATED HERE. Backup codes written
-- before the upgrade are plain JSON, and 1.6.22 reads them encrypted
-- (`storeBackupCodes: "encrypted"` by default), so the vendor's own
-- `/two-factor/verify-backup-code` throws on them — a 500 at the one moment a
-- saved recovery code is needed. The app image re-encodes such a row, in the
-- vendor's own encoding, the FIRST time that row is read
-- (`ensureBackupCodesEncrypted`); it is idempotent, bounded to the one row the
-- request is about, and needs neither a backfill nor a column here. Nothing in
-- this file touches `backup_codes`.
--
-- WHAT MOVES. Nothing. Three ADD COLUMN IF NOT EXISTS with constant defaults,
-- no CHECK, no index, no FK, no data rewritten and nothing dropped — the legacy
-- `enabled` column (which better-auth maps nothing onto) is left exactly where
-- it is. `verified` defaults TRUE, which is the vendor's own default and the
-- only safe backfill: a row written before the column existed belongs to an
-- account that completed enrolment under 1.4, and defaulting it FALSE would
-- make `/two-factor/verify-totp` answer TOTP_NOT_ENABLED at that account's next
-- sign-in — MFA holders locked out by the delta that exists to unbreak MFA.
-- Fresh enrolments are written `verified = false` explicitly by the plugin and
-- flipped by verify-totp, so the default never decides a new row.
--
-- The other two columns are the plugin's TOTP brute-force limiter (NIST SP
-- 800-63B §5.2.2): a per-account budget of consecutive failed verifications and
-- a timed lock. Without them a six-digit second factor has no attempt limit of
-- its own at sign-in.
--
-- RE-RUNNABLE. Every statement is `IF NOT EXISTS`; applying this file twice
-- lands the same shape. A database already carrying the columns executes
-- nothing.
--
-- ROLLBACK: `ALTER TABLE two_factor DROP COLUMN IF EXISTS verified, DROP COLUMN
-- IF EXISTS failed_verification_count, DROP COLUMN IF EXISTS locked_until;`.
-- What that costs is stated above rather than discovered: it restores the shape
-- on which MFA enrolment is impossible.
--
-- Apply with psql -1 (ON_ERROR_STOP) so the three statements land or do not.

SET lock_timeout = '5s';

ALTER TABLE two_factor ADD COLUMN IF NOT EXISTS verified boolean DEFAULT true NOT NULL;

ALTER TABLE two_factor ADD COLUMN IF NOT EXISTS failed_verification_count integer DEFAULT 0 NOT NULL;

ALTER TABLE two_factor ADD COLUMN IF NOT EXISTS locked_until timestamp;
