-- rehearsal-seed.sql — realistic USER data on a fresh db/1.15.0 install, with
-- fixed UUIDs so every rehearsal run is byte-comparable. Applied by
-- tests/rehearsal.sh with `psql_admin -1` right after ./install.sh. Every
-- column below exists in db/1.15.0/schema.sql (the shape the live VM has).
--
-- Anchors from db/1.15.0/seed.sql:
--   admin user            a95df531-0ef4-4d3e-9c5c-ce373b5c0178
--   Default Organization  17c3b09a-27d7-46cc-8756-604c9f033d93
--   system role 'user'    37530b12-d995-4c76-86b8-e08e7501c0b2 (Default Org)
--   system role 'viewer'  461ba26f-e34e-4f88-99b7-214709dfa57b (carries audit:view → 1.22.0 deletes it)
--
-- What each row exercises on the way to 1.41.0:
--   custom role with key IS NULL          → 0009 backfills custom-22222222, NOT NULL
--   a denied=true permission on it        → must SURVIVE 0016 (deletes system defaults only)
--   team_member whose user IS an org member → 0011 backfills org/membership instead of failing
--   org_resource_grant (knowledge → existing KB, UUID text, catalog slug) → 0015 rebuild + checksum
--   thread_attachment + files on disk     → uploads catalog behaviour on the new image
--   knowledge base / documents / chunks   → the RAG corpus survives 0073's CASCADE change
--   expired org_invite + expired session  → the expiry rows that exist at 1.15.0
--   cron_job + ONE finished cron_run_log  → no duplicate 'running' rows (1.35.0 pre-check)

\set org    '17c3b09a-27d7-46cc-8756-604c9f033d93'
\set admin  'a95df531-0ef4-4d3e-9c5c-ce373b5c0178'
\set owner  '10000000-0000-4000-8000-000000000001'
\set member '10000000-0000-4000-8000-000000000002'

INSERT INTO "user" (id, name, email, email_verified, role) VALUES
  (:'owner',  'Rehearsal Owner',  'owner@rehearsal.example',  true, 'user'),
  (:'member', 'Rehearsal Member', 'member@rehearsal.example', true, 'user');
-- credential accounts reusing the admin's scrypt hash → sign-in works with the same password
INSERT INTO account (id, account_id, provider_id, user_id, password)
  SELECT '10000000-0000-4000-8000-00000000000a', :'owner',  'credential', :'owner',  password FROM account WHERE user_id = :'admin' AND provider_id = 'credential';
INSERT INTO account (id, account_id, provider_id, user_id, password)
  SELECT '10000000-0000-4000-8000-00000000000b', :'member', 'credential', :'member', password FROM account WHERE user_id = :'admin' AND provider_id = 'credential';

INSERT INTO organization (id, name, slug) VALUES ('11111111-0000-4000-8000-000000000001', 'Rehearsal Org', 'rehearsal');
INSERT INTO organization_member (id, organization_id, user_id, role) VALUES
  ('12000000-0000-4000-8000-000000000001', :'org', :'owner',  'admin'),
  ('12000000-0000-4000-8000-000000000002', :'org', :'member', 'member'),
  ('12000000-0000-4000-8000-000000000003', '11111111-0000-4000-8000-000000000001', :'owner', 'owner');

-- custom role, key deliberately NULL (1.25.0/0009 backfills it to custom-22222222)
INSERT INTO org_role (id, organization_id, key, name, description, is_system, created_by) VALUES
  ('22222222-0000-4000-8000-000000000001', :'org', NULL, 'Rehearsal Custom Role', 'a custom role the upgrade must keep', false, :'admin');
INSERT INTO org_role_permission (role_id, permission, denied) VALUES
  ('22222222-0000-4000-8000-000000000001', 'members:view',   false),
  ('22222222-0000-4000-8000-000000000001', 'members:invite', true);    -- a DENY row: must survive 0016
INSERT INTO org_role_assignment (id, organization_id, membership_id, role_id, assigned_by) VALUES
  ('23000000-0000-4000-8000-000000000001', :'org', '12000000-0000-4000-8000-000000000002', '22222222-0000-4000-8000-000000000001', :'admin'),
  ('23000000-0000-4000-8000-000000000002', :'org', '12000000-0000-4000-8000-000000000001', '37530b12-d995-4c76-86b8-e08e7501c0b2', :'admin');

INSERT INTO team (id, organization_id, name, slug, created_by) VALUES
  ('24000000-0000-4000-8000-000000000001', :'org', 'Rehearsal Team', 'rehearsal-team', :'admin');
INSERT INTO team_member (id, team_id, user_id, role) VALUES
  ('24000000-0000-4000-8000-000000000002', '24000000-0000-4000-8000-000000000001', :'member', 'member');

INSERT INTO chat_thread (id, title, user_id, organization_id) VALUES
  ('30000000-0000-4000-8000-000000000001', 'Rehearsal thread', :'owner', :'org');
INSERT INTO chat_message (id, thread_id, role, parts) VALUES
  ('msg-rehearsal-1', '30000000-0000-4000-8000-000000000001', 'user',      ARRAY['{"type":"text","text":"hello"}'::json]),
  ('msg-rehearsal-2', '30000000-0000-4000-8000-000000000001', 'assistant', ARRAY['{"type":"text","text":"hi"}'::json]);
INSERT INTO thread_attachment (id, thread_id, user_id, storage_key, filename, mime_type, size) VALUES
  ('31000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', :'owner',
   'uploads/31000000-0000-4000-8000-000000000001-report.txt', 'report.txt', 'text/plain', 22);

INSERT INTO knowledge_base (id, name, organization_id, user_id, visibility) VALUES
  ('40000000-0000-4000-8000-000000000001', 'Rehearsal KB', :'org', :'owner', 'org');
INSERT INTO knowledge_documents (id, knowledge_base_id, source_key, source_filename, organization_id, user_id, chunk_count) VALUES
  ('41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 'uploads/kb/handbook.txt', 'handbook.txt', :'org', :'owner', 2);
INSERT INTO knowledge_base_document (knowledge_base_id, source_key) VALUES
  ('40000000-0000-4000-8000-000000000001', 'uploads/kb/handbook.txt');
INSERT INTO document_chunk (id, content, source_filename, source_key, chunk_index, user_id, organization_id) VALUES
  ('42000000-0000-4000-8000-000000000001', 'chunk one', 'handbook.txt', 'uploads/kb/handbook.txt', 0, :'owner', :'org'),
  ('42000000-0000-4000-8000-000000000002', 'chunk two', 'handbook.txt', 'uploads/kb/handbook.txt', 1, :'owner', :'org');

-- a resource grant: type in 0015's list, resource_id a UUID string that EXISTS, slug in 0012's catalog
INSERT INTO org_resource_grant (id, organization_id, membership_id, resource_type, resource_id, permission, granted_by) VALUES
  ('50000000-0000-4000-8000-000000000001', :'org', '12000000-0000-4000-8000-000000000002', 'knowledge',
   '40000000-0000-4000-8000-000000000001', 'knowledge:view', :'admin');

-- expiry rows that exist at 1.15.0 (org_role_assignment.expires_at only arrives with 1.16.0)
INSERT INTO org_invite (id, organization_id, invited_email, role, token, invited_by, expires_at) VALUES
  ('60000000-0000-4000-8000-000000000001', :'org', 'expired@rehearsal.example', 'member', 'rehearsal-expired-invite', :'admin', now() - interval '1 day');
INSERT INTO session (id, expires_at, token, user_id) VALUES
  ('61000000-0000-4000-8000-000000000001', now() - interval '1 day', 'rehearsal-expired-session', :'owner');

INSERT INTO cron_job (id, name, schedule, user_id, organization_id, target_type, target_id) VALUES
  ('70000000-0000-4000-8000-000000000001', 'Rehearsal nightly', '0 3 * * *', :'owner', :'org', 'workflow', NULL);
INSERT INTO cron_run_log (id, cron_job_id, status, finished_at, duration_ms) VALUES
  ('71000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001', 'success', now(), 1200);
