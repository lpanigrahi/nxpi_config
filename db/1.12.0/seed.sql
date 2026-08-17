-- NXPi reference seed data. Apply as a SUPERUSER, AFTER schema.sql + grants.sql.
--   psql -v admin_email="admin@you.example" -v admin_password_hash="<hash>" -f seed.sql
-- The hash is produced per-deploy by the nxpi-hash helper (Better Auth scrypt).
-- FK checks are deferred during the bulk load (superuser-only).
SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

\restrict ncf41RhGwXGca8dLOysKjefiTiopriHNDGSocO4zgEewDhPs0Psugxe0D9gd8kd

-- Dumped from database version 17.10 (Debian 17.10-1.pgdg12+1)
-- Dumped by pg_dump version 17.10 (Debian 17.10-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: __drizzle_migrations; Type: TABLE DATA; Schema: drizzle; Owner: -
--

INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (1, '632365f4b31ff0e1e9b2fb99efc5bc55e57e1539aabe1fee22bdb773838a70ca', 1746202772129);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (2, '9c6a9bd7227c59ff04491ee65df9162f70ea92bb4c43294506bfc5b4c4b2a121', 1780078341863);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (3, 'bd3c8b6b1eaf49fcd2bd4febfd758763bed3ea4d9fa102374c2cfa9004b01737', 1780108166476);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (4, '05003fb83be0cc79bef8ba98f2e62e0c2752bde316e44cc2046cf0bdc47f49f8', 1780113415343);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (5, '7c8ba33bf16e64b2001f7ba41875347725af707f2e8e3c92736c063243cabbec', 1780123973341);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (6, 'd59f0140d4ac22eff20ca2a3f2383e8872f46a0c87b7f8c903271b97121db074', 1780141813699);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (7, '2e5bf44238acd75fa9060ccb5305d0646df299f42d5a312387414fa0153043bc', 1780152823699);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (8, '2c17665fa6fa399824ab4208413a81826f29a2207e19763d5b2de8b029b1b9d5', 1780159227374);
INSERT INTO drizzle.__drizzle_migrations (id, hash, created_at) VALUES (9, '40b85f8d1df8f13874d42619a032653f28c89eb100700d52a4c6681fc8bbe465', 1780321112228);


--
-- Data for Name: organization; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'Super Admin''s Workspace', 'personal-862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'free', 'active', '2026-08-10 16:53:30.81729', '2026-08-10 16:53:30.81729');
INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'Default Organization', 'default', NULL, 'free', 'active', '2026-08-10 16:53:30.892791', '2026-08-10 16:53:30.892791');


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (id, name, email, email_verified, password, image, preferences, created_at, updated_at, banned, ban_reason, ban_expires, role, two_factor_enabled, two_factor_secret, two_factor_backup_codes) VALUES ('862152ec-20d6-4bc9-84b8-47d695c142bd', 'Super Admin', :'admin_email', false, NULL, NULL, '{}', '2026-08-10 16:53:29', '2026-08-10 16:53:29', false, NULL, NULL, 'admin', false, NULL, NULL);


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: a2a_capability_card; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: chat_thread; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('f77c78e7-767d-4180-9731-56aff36e7420', '0.1.0', 'baby-research', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/1f468-1f3fb-200d-1f52c.png","style":{"backgroundColor":"oklch(78.5% 0.115 274.713)"}}', 'Comprehensive web research workflow that performs multi-layered search and content analysis to generate detailed research reports based on user instructions and research objectives.', true, 'private', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 0, NULL, '2026-08-10 16:53:30.74363', '2026-08-10 16:53:30.74363', NULL);
INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', '0.1.0', 'Get Weather', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/26c8-fe0f.png","style":{"backgroundColor":"oklch(20.5% 0 0)"}}', 'Get weather data from the API', true, 'private', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 0, NULL, '2026-08-10 16:53:30.798399', '2026-08-10 16:53:30.798399', NULL);


--
-- Data for Name: orchestration_run; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: a2a_task; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.account (id, account_id, provider_id, user_id, access_token, refresh_token, id_token, access_token_expires_at, refresh_token_expires_at, scope, password, created_at, updated_at) VALUES ('530cbfec-fa1d-4a1a-abf6-64626a16646a', '862152ec-20d6-4bc9-84b8-47d695c142bd', 'credential', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, NULL, NULL, NULL, NULL, NULL, :'admin_password_hash', '2026-08-10 16:53:30.87', '2026-08-10 16:53:30.87');


--
-- Data for Name: agent_deployment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent_memory; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent_rating; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: apikey; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_response_enabled', 'false', NULL, '2026-08-10 16:53:30.933045');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_provider_prompt_enabled', 'false', NULL, '2026-08-10 16:53:30.935242');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_semantic_enabled', 'false', NULL, '2026-08-10 16:53:30.936719');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_retrieval_enabled', 'false', NULL, '2026-08-10 16:53:30.938326');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('bash_execution_enabled', 'false', NULL, '2026-08-10 16:53:30.939958');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('signup_enabled', 'true', NULL, '2026-08-10 16:53:30.941361');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('temporary_chat_enabled', 'true', NULL, '2026-08-10 16:53:30.942772');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('platform_mfa_required', 'false', NULL, '2026-08-10 16:53:30.944516');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_core_v2', 'true', NULL, '2026-08-10 16:53:30.9456');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_runtime_v2', 'false', NULL, '2026-08-10 16:53:30.946668');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('agent_marketplace_enabled', 'true', NULL, '2026-08-10 16:53:30.947941');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('memory_context_v2', 'false', NULL, '2026-08-10 16:53:30.948871');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('context_engine_v1', 'false', NULL, '2026-08-10 16:53:30.949697');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_routing_v2', 'true', NULL, '2026-08-10 16:53:30.95152');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('commands_v1', 'false', NULL, '2026-08-10 16:53:30.952698');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skill_package_v1', 'true', NULL, '2026-08-10 16:53:30.95404');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skill_import_v1', 'true', NULL, '2026-08-10 16:53:30.955315');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skill_governance_v1', 'true', NULL, '2026-08-10 16:53:30.956424');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('github_connector_v1', 'false', NULL, '2026-08-10 16:53:30.957373');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skill_generator_v1', 'true', NULL, '2026-08-10 16:53:30.958243');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skill_qa_v1', 'true', NULL, '2026-08-10 16:53:30.959627');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('planner_v1', 'false', NULL, '2026-08-10 16:53:30.960966');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('personal_workspace_enabled', 'false', NULL, '2026-08-10 16:53:30.962211');


--
-- Data for Name: archive; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: archive_item; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_base; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: prompt_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: assistant; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: assistant_team; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: audit_chain_head; Type: TABLE DATA; Schema: public; Owner: -
--

-- HAND-PATCHED (2026-08-11): the ref DB's head_signature pointed at
-- admin_audit_log rows that are EXCLUDED from this seed — a dangling head
-- makes verifyAuditChain fail on every fresh install (its walk starts at the
-- genesis '' and the first real row would chain off the phantom signature).
-- The chain must begin at genesis on a fresh database.
INSERT INTO public.audit_chain_head (id, head_signature, updated_at) VALUES (1, '', '2026-08-10 16:53:30.86');


--
-- Data for Name: bookmark; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: chat_export; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: chat_export_comment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: chat_message; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: chat_message_embedding; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: conditional_access_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: cron_job; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: cron_run_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_acl; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: document_chunk; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: email_otp; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: embedding_config; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: error_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: event_outbox; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-08-10 16:53:30.821712', '2026-08-10 16:53:30.821712');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-08-10 16:53:30.829758', '2026-08-10 16:53:30.829758');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, assistants, and models.', true, '8581dd37-12f9-4a6b-9a1e-5ce2bac85397', NULL, '2026-08-10 16:53:30.823126', '2026-08-10 16:53:30.834');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('b9354e24-7fcf-4c7a-9f98-dc05401889c8', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, '8581dd37-12f9-4a6b-9a1e-5ce2bac85397', NULL, '2026-08-10 16:53:30.824334', '2026-08-10 16:53:30.838');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, '8581dd37-12f9-4a6b-9a1e-5ce2bac85397', NULL, '2026-08-10 16:53:30.825757', '2026-08-10 16:53:30.84');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('ed4da86e-36e8-4a4a-b1e3-471d5af26a43', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, '8581dd37-12f9-4a6b-9a1e-5ce2bac85397', NULL, '2026-08-10 16:53:30.827426', '2026-08-10 16:53:30.842');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('89650666-ac51-4c64-a12c-bb523c16f065', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, '8581dd37-12f9-4a6b-9a1e-5ce2bac85397', NULL, '2026-08-10 16:53:30.828321', '2026-08-10 16:53:30.844');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, '388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', NULL, '2026-08-10 16:53:30.829056', '2026-08-10 16:53:30.845');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-08-10 16:53:30.896346', '2026-08-10 16:53:30.896346');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-08-10 16:53:30.903378', '2026-08-10 16:53:30.903378');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, assistants, and models.', true, '58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', NULL, '2026-08-10 16:53:30.897669', '2026-08-10 16:53:30.907');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('e336e10c-763d-4570-b9d7-ed7c24617ef9', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, '58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', NULL, '2026-08-10 16:53:30.898697', '2026-08-10 16:53:30.91');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, '58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', NULL, '2026-08-10 16:53:30.899638', '2026-08-10 16:53:30.913');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('4ed0d8de-4bbe-49bb-9d77-b325da745ee4', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, '58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', NULL, '2026-08-10 16:53:30.900617', '2026-08-10 16:53:30.915');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('c78a6ddc-0676-479f-8809-7bab5427dbb6', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, '58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', NULL, '2026-08-10 16:53:30.901768', '2026-08-10 16:53:30.916');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, '5613029d-2885-4039-addc-720f17ed46d3', NULL, '2026-08-10 16:53:30.902636', '2026-08-10 16:53:30.918');


--
-- Data for Name: group_mapping; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: hitl_assignment_cursor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_execution; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_node; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('1f9deeb3-0313-42b4-a088-27c7915c353d', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'tool', 'INITIAL_SEARCH', 'Perform initial web search based on user query and parameters', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Based on the following research instruction, perform a comprehensive web search:"},{"type":"hardBreak"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Research Instruction**: "},{"type":"mention","attrs":{"id":"20075100-6d14-42ea-ac7a-a2732d54cacf","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Topic Area**: "},{"type":"mention","attrs":{"id":"e279fc2c-43c3-441d-bb5d-2d084a74bd63","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- Search Strategy:"}]}]}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Extract key concepts and themes from the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Identify multiple search angles and perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Use diverse keywords and search terms"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Focus on finding authoritative and comprehensive sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Include recent developments and established knowledge"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. Cast a wide net to ensure comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  Important: Don''t limit yourself to obvious keywords. Consider:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Technical terminology and industry jargon"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Alternative names and concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Related fields and cross-industry applications"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Recent trends and developments"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Expert opinions and case studies"}]},{"type":"paragraph","content":[{"type":"text","text":"  Return maximum 15 diverse, high-quality results."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('e218530f-2628-4e85-91b6-50b7e8276ac3', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'condition', 'URL_CONDITION', '', '{"position":{"x":1092.720830684793,"y":-109.56839983927273},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"f9bf6172-a399-4669-b794-24b76a2be91e","path":["answer","important_url"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_not_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('2de4a287-b264-40a4-8f26-cf93ef706212', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'tool', 'CONTENT_EXTRACTION', 'Extract detailed content from important URL', '{"position":{"x":1426.344044454295,"y":-203.77120780533727},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"url : "},{"type":"mention","attrs":{"id":"9bd55c87-9eac-4af2-968f-c83b93577639","label":"{\"nodeId\":\"f9bf6172-a399-4669-b794-24b76a2be91e\",\"path\":[\"answer\",\"important_url\"]}"}}]}]},"tool":{"type":"app-tool","id":"webContent","description":"A detailed web content extraction tool that analyzes and summarizes specific web pages from provided URLs. Extracts full content, processes it intelligently, and provides comprehensive summaries. Perfect for in-depth analysis of specific articles, documents, or web pages.","parameterSchema":{"type":"object","properties":{"urls":{"type":"array","items":{"type":"string"},"description":"List of URLs to extract content from"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each URL","default":3000,"minimum":100,"maximum":10000},"livecrawl":{"type":"string","enum":["always","fallback","preferred"],"description":"Live crawling preference - always forces live crawl, fallback uses cache first, preferred tries live first","default":"preferred"}},"required":["urls"]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('d23e2812-8149-4241-bcf3-18fb99e8c98c', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'llm', 'SUMMARY', 'Synthesize all information into comprehensive research report', '{"position":{"x":1912.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"title":{"type":"string","description":"Clear, descriptive title for the research report"},"summary":{"type":"string","description":"Executive summary in 4-6 sentences"},"content":{"type":"string","description":"Comprehensive analysis in markdown format with source citations"},"diagram":{"type":"string","description":"Mermaid diagram code if beneficial (empty string if not needed)"},"key_insights":{"type":"array","items":{"type":"string"},"description":"3-5 most important insights from the research"},"confidence_level":{"type":"number","description":"Confidence score 1-10 based on source quality and coverage"},"sources_used":{"type":"array","items":{"type":"object","properties":{"title":{"type":"string"},"url":{"type":"string"},"type":{"type":"string"}}},"description":"List of all sources referenced in the content"},"images":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string"},"description":{"type":"string"},"context":{"type":"string"}}},"description":"List of relevant images extracted from search results"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report based on all collected information."}]},{"type":"paragraph","content":[{"type":"text","text":"  Research Instruction: "},{"type":"mention","attrs":{"id":"32c8abfa-f993-4c29-906a-d1c26f36711e","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"research_instruction\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c20376fa-66ec-45ce-bbef-a4f8d793e110","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"topic\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Output Language: "},{"type":"mention","attrs":{"id":"87a8619d-b077-48de-8351-1cb5bdf6cc59","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"language\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Information Sources:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Initial Search: "},{"type":"mention","attrs":{"id":"53de2392-4c38-4d56-a8bf-d1b64892a348","label":"{\"nodeId\":\"1f9deeb3-0313-42b4-a088-27c7915c353d\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Analysis: "},{"type":"mention","attrs":{"id":"7447143a-9154-49e8-b3bb-bff946398903","label":"{\"nodeId\":\"f9bf6172-a399-4669-b794-24b76a2be91e\",\"path\":[\"answer\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"  - Detailed Content: "},{"type":"mention","attrs":{"id":"2769be0e-9631-4562-9ccc-2026d7aca616","label":"{\"nodeId\":\"2de4a287-b264-40a4-8f26-cf93ef706212\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Additional Search: "},{"type":"mention","attrs":{"id":"9ebfa7ad-341d-4db5-a88b-1d772fa97edd","label":"{\"nodeId\":\"1c2dfa94-348b-4707-a4f2-afd133842cd5\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Generate a structured report that directly addresses the research instruction:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. "},{"type":"text","marks":[{"type":"bold"}],"text":"title"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Clear, descriptive title that reflects the research focus"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should align with the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Executive summary in 4-6 sentences"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Directly answer the key questions in the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Highlight major findings and implications"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"content"},{"type":"text","text":" (string - markdown format):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Comprehensive analysis organized logically"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Structure based on the research instruction requirements"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Include: key findings, evidence, analysis, implications, recommendations"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Use proper markdown formatting with headers, lists, emphasis"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Important Content Guidelines:"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Images"},{"type":"text","text":": If images are available in the search results, include relevant ones using markdown image syntax: `![Image description](image_url)`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Sources"},{"type":"text","text":": Always cite sources when referencing specific information using format: `[Source Title](URL)` or `According to [Source Title](URL), ...`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Data and Statistics"},{"type":"text","text":": When presenting data, always include the source"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Quotes"},{"type":"text","text":": Use blockquotes for important quotes with attribution"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Evidence"},{"type":"text","text":": Support claims with specific evidence from the sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Structure Example:"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```markdown"}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Introduction"}]},{"type":"paragraph","content":[{"type":"text","text":"     Brief overview with context"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Key Findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 1 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 2 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Visual Evidence"}]},{"type":"paragraph","content":[{"type":"text","text":"     ![Chart showing trend](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"italic"}],"text":"Source: [Report Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Detailed Analysis"}]},{"type":"paragraph","content":[{"type":"text","text":"     In-depth analysis with multiple source citations"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Implications"}]},{"type":"paragraph","content":[{"type":"text","text":"     What this means for the research question"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"diagram"},{"type":"text","text":" (string - Mermaid code):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Create visualization if it helps explain findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Examples: process flows, relationships, timelines, comparisons"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Only include if it adds significant value"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. "},{"type":"text","marks":[{"type":"bold"}],"text":"key_insights"},{"type":"text","text":" (array of strings):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - 3-5 most important insights from the research"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should directly relate to the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. "},{"type":"text","marks":[{"type":"bold"}],"text":"confidence_level"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate confidence in findings based on source quality and coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  7. "},{"type":"text","marks":[{"type":"bold"}],"text":"sources_used"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - List all sources referenced in the content"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Format: {\"title\": \"Source Title\", \"url\": \"URL\", \"type\": \"article/report/study\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"  Write in [INITIAL_SEARCH.output_language]. Ensure the report:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Fully addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Includes relevant images where they add value"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Properly cites all sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Provides actionable insights"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Maintains professional formatting"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"8. "},{"type":"text","marks":[{"type":"bold"}],"text":"images"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Extract at least 3 relevant images"},{"type":"text","text":" from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Format: {\"url\": \"image_url\", \"description\": \"descriptive caption\", \"context\": \"how this image relates to the research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Select images that support key findings or illustrate important concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse image types: charts, diagrams, photos, infographics"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize images that enhance understanding of the research topic"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('61a7db5f-e578-4877-8e24-bc0f811c764e', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'condition', 'SEARCH_CONDITION', '', '{"position":{"x":1096.3175798437799,"y":108.80530614989887},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"f9bf6172-a399-4669-b794-24b76a2be91e","path":["answer","additional_search_instruction"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('1c2dfa94-348b-4707-a4f2-afd133842cd5', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'tool', 'ADDITIONAL_SEARCH', 'Perform supplementary search based on specific instruction', '{"position":{"x":1439.3610744098883,"y":257.6457427362809},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Perform targeted search based on this specific instruction: "},{"type":"mention","attrs":{"id":"dc2caf22-632d-4388-bf9c-7c8626a24c65","label":"{\"nodeId\":\"f9bf6172-a399-4669-b794-24b76a2be91e\",\"path\":[\"answer\",\"additional_search_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"Research Context: "},{"type":"mention","attrs":{"id":"6ab2e17b-1e04-4065-97d4-627de934b88d","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c8de8dcf-0218-4b31-8552-b1f5d0ab8ad3","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"text","text":"  Search Strategy:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Follow the specific search instruction precisely"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Focus on filling the identified information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Look for recent developments and expert perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Include diverse viewpoints and comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Prioritize sources that add new insights to the research"}]},{"type":"paragraph","content":[{"type":"text","text":"  Target 8-10 high-quality results that provide unique value."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('e70fd679-8809-4d94-bbe6-7e8a0f615aa1', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'output', 'OUTPUT', '', '{"position":{"x":2632.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"research_findings","source":{"nodeId":"d23e2812-8149-4241-bcf3-18fb99e8c98c","path":["answer"]}},{"key":"organized_data","source":{"nodeId":"9b3978cb-9369-4c1f-9cc4-f8d5c9f7f184","path":["answer"]}},{"key":"message_response_guide","source":{"nodeId":"845b5e8c-8987-4777-a3d2-a3fcee2af853","path":["template"]}},{"key":"images","source":{"nodeId":"d23e2812-8149-4241-bcf3-18fb99e8c98c","path":["answer","images"]}}]}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('9b3978cb-9369-4c1f-9cc4-f8d5c9f7f184', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'llm', 'ORGANIZATION', 'Organize and summarize all collected information for report generation', '{"position":{"x":2272.4044439691656,"y":91.44758151102624},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"string"},"totalTokens":{"type":"number"}}},"messages":[{"role":"system","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"You are a research information organizer. Your task is to systematically organize and summarize all collected research information into a comprehensive, well-structured format that will be used for report generation."}]},{"type":"paragraph","content":[{"type":"text","text":"Your response should include:"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH OVERVIEW"}]},{"type":"paragraph","content":[{"type":"text","text":"[Summarize the research instruction and approach]"}]},{"type":"paragraph","content":[{"type":"text","text":"## KEY SOURCES IDENTIFIED"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all important sources with titles and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 1](URL1) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 2](URL2) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 3](URL3) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"## AVAILABLE IMAGES"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all images found with descriptions and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 1](image_url1) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 2](image_url2) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 3](image_url3) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"## MAIN FINDINGS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Organized key findings with source attributions]"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 1 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 2 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 3 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"## DETAILED CONTENT SUMMARY"}]},{"type":"paragraph","content":[{"type":"text","text":"[Comprehensive summary of all extracted content]"}]},{"type":"paragraph","content":[{"type":"text","text":"## STATISTICAL DATA"}]},{"type":"paragraph","content":[{"type":"text","text":"[Any numbers, statistics, or quantitative data found]"}]},{"type":"paragraph","content":[{"type":"text","text":"## EXPERT OPINIONS/QUOTES"}]},{"type":"paragraph","content":[{"type":"text","text":"[Important quotes or expert perspectives]"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH GAPS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Areas where information might be incomplete]"}]},{"type":"paragraph","content":[{"type":"text","text":"Make this comprehensive and well-organized for easy reference in report generation."}]}]}},{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"4a3380c5-0b39-43a8-906e-f0a38ca41539","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"1de3a234-9029-4914-8086-ba9789e2a017","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Initial Search Results: "},{"type":"mention","attrs":{"id":"2ea9f224-5806-408a-a538-c61313a6f0af","label":"{\"nodeId\":\"1f9deeb3-0313-42b4-a088-27c7915c353d\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Analysis Summary: "},{"type":"mention","attrs":{"id":"a0c436b7-6300-4d1f-a0e6-1316c1c8cdc7","label":"{\"nodeId\":\"f9bf6172-a399-4669-b794-24b76a2be91e\",\"path\":[\"answer\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Detailed Content: "},{"type":"mention","attrs":{"id":"10bf3fbf-2421-4d94-bc64-30e96ef28168","label":"{\"nodeId\":\"2de4a287-b264-40a4-8f26-cf93ef706212\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Additional Search:  "},{"type":"mention","attrs":{"id":"2e50dd84-1d6a-4680-92ae-b3d78045b713","label":"{\"nodeId\":\"1c2dfa94-348b-4707-a4f2-afd133842cd5\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Please organize all this information according to the format specified in the system prompt."}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('845b5e8c-8987-4777-a3d2-a3fcee2af853', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'template', 'REPORT_GUIDE', '', '{"position":{"x":2270.033917728336,"y":-27.217682321506935},"type":"default"}', '{"kind":"template","outputSchema":{"type":"object","properties":{"template":{"type":"string"}}},"template":{"type":"tiptap","tiptap":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report using the research findings. Guidelines:"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present the complete content directly without code blocks or formatting wrapper"}]},{"type":"paragraph","content":[{"type":"text","text":"- Do not add introductory remarks like \"Here''s the report\" or \"Report completed\""}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the title, summary, and complete content from findings"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MANDATORY REQUIREMENTS:"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include at least 3 relevant images"},{"type":"text","text":" using ![Description](image_url) format throughout the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include the mermaid diagram"},{"type":"text","text":" from research_findings using \\`\\`\\`mermaid format within the content flow"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST cite every source with URLs"},{"type":"text","text":" - format: [Source Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include source URLs"},{"type":"text","text":" for all data, statistics, and factual information"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"IMAGE USAGE:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Extract images from organized_data or research_findings content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place images strategically to support key points"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use format: ![Descriptive caption](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include image source attribution when possible"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MERMAID DIAGRAM:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the diagram from research_findings.diagram"}]},{"type":"paragraph","content":[{"type":"text","text":"- Format: \\`\\`\\`mermaid [diagram_code] \\`\\`\\`"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place within relevant content section, not as separate section"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure diagram enhances understanding of the topic"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"CONTENT STRUCTURE:"}]},{"type":"paragraph","content":[{"type":"text","text":"# [research_findings.title]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"[Include executive summary, key insights, detailed analysis with images and diagrams integrated naturally]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"Confidence Level:"},{"type":"text","text":" [research_findings.confidence_level]/10"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include confidence level and key insights naturally within the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure all sources are properly cited throughout"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present as a professional research report ready for the user"}]}]}}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('f9bf6172-a399-4669-b794-24b76a2be91e', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'llm', 'ANALYSIS', 'Analyze search results and determine research strategy', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"reference_sources":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string","description":"Source URL"},"summary":{"type":"string","description":"Brief summary of the source content and relevance"}}},"description":"List of key reference sources from search results"},"important_url":{"type":"string","description":"Single most important URL for detailed content extraction"},"additional_search_instruction":{"type":"string","description":"Specific instruction for additional search to fill information gaps (empty string if none needed)"},"analysis_summary":{"type":"string","description":"Assessment of current research state and strategy"},"research_completeness":{"type":"number","description":"Score 1-10 rating how well initial search addresses research instruction"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Analyze the search results in the context of the research instruction and determine the next steps."},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"23b93374-40fe-4397-8375-3ee3eacee22a","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"fa4b502f-3b13-4717-b4ae-675961527f20","label":"{\"nodeId\":\"afd7ebfc-ceec-4d1f-a774-60f126402e4d\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Search Results: "},{"type":"mention","attrs":{"id":"88493890-21ba-476a-a7c0-b6dd70a1d480","label":"{\"nodeId\":\"1f9deeb3-0313-42b4-a088-27c7915c353d\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"1. "},{"type":"text","marks":[{"type":"bold"}],"text":"important_url"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"YOU MUST SELECT AT LEAST ONE URL"},{"type":"text","text":" unless search results are completely irrelevant"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Choose the URL with the most comprehensive, authoritative information"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize: research papers, detailed reports, expert analyses, case studies, official websites"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Even if quality is moderate, select the BEST available option for detailed extraction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Only return empty string \"\" if absolutely no URLs provide any additional value"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Default behavior: ALWAYS select the most valuable URL from available results"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"additional_search_instruction"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Specific instruction for additional search to fill information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should be a clear directive like \"Find recent statistics on AI adoption in hospitals\" or \"Search for regulatory challenges in healthcare AI implementation\""}]},{"type":"paragraph","content":[{"type":"text","text":"     - Based on what''s missing from initial search relative to research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Return empty string \"\" if initial search provides sufficient coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"analysis_summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Assessment of how well current results address the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Identification of information gaps and missing perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Quality and credibility evaluation of found sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Strategy for completing the research objective"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"research_completeness"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate how well the initial search addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Consider coverage, depth, and relevance to stated objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  Be strategic and selective. Focus on what''s truly needed to address the research instruction."},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"5. "},{"type":"text","marks":[{"type":"bold"}],"text":"reference_sources"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Extract 5-8 key reference sources from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - For each source provide: {\"url\": \"full_url\", \"summary\": \"brief description of content and relevance to research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse source types: official reports, news articles, academic papers, expert analyses"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Focus on sources that directly support the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize credible, authoritative sources"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('afd7ebfc-ceec-4d1f-a774-60f126402e4d', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'input', 'INPUT', '', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"topic":{"type":"string","description":"Subject area or domain (e.g., ''technology'', ''healthcare'', ''finance'', ''education'')"},"language":{"type":"string","description":"Preferred language for sources. eg. en (English), ko (Korean)"},"research_instruction":{"type":"string","default":"Comprehensive research instruction including what to research, why, and how to approach it. Example: ''Research the current state of AI in healthcare, focusing on diagnostic applications, regulatory challenges, and market adoption rates. I need this for a business proposal targeting hospital administrators.''"}},"required":["research_instruction"]}}', '2026-08-10 16:53:30.760478', '2026-08-10 16:53:30.760478');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('dae073e9-c5d1-4647-b967-4e0d2fd8c55f', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'input', 'INPUT', 'Collect story requirements and preferences from user', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"region":{"type":"string"}},"required":["region"]}}', '2026-08-10 16:53:30.806296', '2026-08-10 16:53:30.806296');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('d7a672ab-9879-4a39-830b-9a872390e8d9', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'http', 'WEATHER API', 'Get weather data from the API', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"http","outputSchema":{"type":"object","properties":{"response":{"type":"object","properties":{"status":{"type":"number"},"statusText":{"type":"string"},"ok":{"type":"boolean"},"headers":{"type":"object"},"body":{"type":"string"},"duration":{"type":"number"},"size":{"type":"number"}}}}},"method":"GET","headers":[],"query":[{"key":"current","value":"temperature_2m"},{"key":"hourly","value":"temperature_2m"},{"key":"timezone","value":"auto"},{"key":"daily","value":"sunrise,sunset"},{"key":"latitude","value":{"nodeId":"8d9de973-2988-44ab-a41c-bef94e240cce","path":["answer","latitude"]}},{"key":"longitude","value":{"nodeId":"8d9de973-2988-44ab-a41c-bef94e240cce","path":["answer","longitude"]}}],"timeout":30000,"url":"https://api.open-meteo.com/v1/forecast"}', '2026-08-10 16:53:30.806296', '2026-08-10 16:53:30.806296');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('8d9de973-2988-44ab-a41c-bef94e240cce', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'llm', 'LLM', 'Get latitude and longitude from the LLM', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"latitude":{"type":"number","description":"Geographical latitude of the location"},"longitude":{"type":"number","description":"Geographical longitude of the location"}}}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"What are the latitude and longitude of "},{"type":"mention","attrs":{"id":"e8d2314a-f81b-41e3-91ff-f235486a62f3","label":"{\"nodeId\":\"dae073e9-c5d1-4647-b967-4e0d2fd8c55f\",\"path\":[\"region\"]}"}}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-08-10 16:53:30.806296', '2026-08-10 16:53:30.806296');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('dabd0356-d0d7-4ac1-abc5-e9dd8a071276', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'note', 'NOTE', '# 🌦️ Regional Weather Lookup Workflow

This workflow retrieves weather information for a specified region by chaining together an LLM for geocoding and an HTTP request to a public weather API.

### ➡️ Execution Pipeline

1.  **Input Region**: A user provides a region name (e.g., "Seoul" or "Tokyo").
2.  **Find Coordinates (LLM)**: The LLM converts the text-based region name into geographical latitude and longitude coordinates.
3.  **Fetch Weather API (HTTP)**: The workflow uses these coordinates to call the Open-Meteo weather API and request the current forecast.
4.  **Return Weather Data (Output)**: The raw JSON response from the weather API is passed on as the final result of the workflow.

---

### 🔬 Node Output Examples

Here are examples of the output structure for the key nodes in this workflow.

#### 📍 **Find Coordinates (LLM) Output**
This node outputs the latitude and longitude in a structured object.

```json
{
"answer": {
  "latitude": 37.5665,
  "longitude": 126.9780
}
}
```

#### ☁️ **Fetch Weather API (HTTP) Output**
This node returns the full HTTP response. The actual weather data is located inside the `body` field as a JSON string.

```json
{
"response": {
  "status": 200,
  "ok": true,
  "body": "{"latitude":37.56,"longitude":126.97,"current":{"time":"2023-10-27T12:00","temperature_2m":15.4},"daily":{"sunrise":["2023-10-27T06:45"],"sunset":["2023-10-27T17:40"]}}",
  "duration": 150
}
}
```
', '{"position":{"x":-569.8790292584229,"y":-731.5434457770423},"type":"default"}', '{"kind":"note","outputSchema":{"type":"object","properties":{}}}', '2026-08-10 16:53:30.806296', '2026-08-10 16:53:30.806296');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('24d332fd-d750-4adb-a961-4880088ce0fa', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'output', 'OUTPUT', 'Output the weather data', '{"position":{"x":1080,"y":0},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"result","source":{"nodeId":"d7a672ab-9879-4a39-830b-9a872390e8d9","path":["response","body"]}}]}', '2026-08-10 16:53:30.806296', '2026-08-10 16:53:30.806296');


--
-- Data for Name: hitl_sla_event; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inference_request_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_documents; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ingestion_jobs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mcp_server; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: integration_connector; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: integration_event; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: integration_sync_config; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: subscription; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: job_execution; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_base_document; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_embedding_migration_state; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_embeddings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_entity; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_entity_mention; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_metadata; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_versions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_access_label; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: label_access_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ldap_directory; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: marketplace_category; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: marketplace_listing; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: marketplace_fork; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: marketplace_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: marketplace_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mcp_oauth_session; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mcp_server_custom_instructions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mcp_server_tool_custom_instructions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: mcp_tool_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: memory_entry; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: model_catalog_custom_model; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: model_catalog_metadata; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: model_pricing; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: nav_visibility_override; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('ff9c2daa-58c9-4bf8-a856-0140e3e27cd2', 'global', NULL, 'team-manager', 'admin.auditLog', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.973055');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('72947798-a976-4001-9072-6eee495efc57', 'global', NULL, 'team-manager', 'admin.featureFlags', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.974458');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d14f1440-a4d2-4c05-997d-96d01c614dc2', 'global', NULL, 'team-manager', 'admin.identity', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.975395');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('4c612ab5-b184-4be9-a114-9d0ae646149d', 'global', NULL, 'team-manager', 'admin.models', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.976428');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('6fafedf6-df82-4895-ab39-f0fc182faae4', 'global', NULL, 'team-manager', 'admin.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.977458');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d4221607-9de9-41ef-8b02-fcf9d9447224', 'global', NULL, 'team-manager', 'admin.organizations', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.978783');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('38c6f9cc-8146-4f3b-a4d6-3a0940198de4', 'global', NULL, 'team-manager', 'admin.platformSettings', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.979665');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('f8cdcb28-6233-4341-9da9-7114255e0140', 'global', NULL, 'team-manager', 'admin.security', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.98041');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('831e8697-fed8-4a6e-941e-5b7816eb99a6', 'global', NULL, 'team-manager', 'admin.subscriptions', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.981244');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('3fccde56-769b-4503-b495-4c032334b168', 'global', NULL, 'team-manager', 'admin.users', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.981847');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b3fc55f4-af83-4113-941c-6d95ef5e138e', 'global', NULL, 'team-manager', 'nav.rag', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.982364');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('2dedce29-e31c-4698-9520-80eee44b14ed', 'global', NULL, 'team-manager', 'org.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.982874');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('abe33493-9c32-4d2b-b83c-82c9bd2806a7', 'global', NULL, 'team-manager', 'org.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.983382');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('9401fefd-9a57-43a5-8597-14f5bcd441ee', 'global', NULL, 'team-manager', 'team.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.984002');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('dca795cd-8bfb-4773-94a7-6ff934d935a4', 'global', NULL, 'team-manager', 'workspace.mcp', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.984799');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('a1ee4de8-4d58-45ce-81b9-92c95c918631', 'global', NULL, 'team-manager', 'workspace.promptTemplates', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.985537');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d41ec15f-fc17-4fc0-863e-3e10537480a6', 'global', NULL, 'user', 'admin.auditLog', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.986085');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1f6d28ae-fe67-4ac2-b692-3b428f0fcb3d', 'global', NULL, 'user', 'admin.featureFlags', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.986626');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('15a8614c-c9ed-46b5-96c8-6352377f06b3', 'global', NULL, 'user', 'admin.identity', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.987129');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('987e2b6d-0658-48ef-974d-54991f953e07', 'global', NULL, 'user', 'admin.models', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.987999');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8715b27d-566b-4350-add9-ff50c617a748', 'global', NULL, 'user', 'admin.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.988554');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('06ec071b-879a-45fe-b55b-b7fc167db19d', 'global', NULL, 'user', 'admin.organizations', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.989077');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('db83f5bb-316e-459d-beb6-aae247f2c53b', 'global', NULL, 'user', 'admin.platformSettings', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.989599');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('ee3005fe-2fc3-4e80-aac6-be6c8fd62cd0', 'global', NULL, 'user', 'admin.security', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.990183');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('3334e628-3fce-481d-b4e5-b43ed3005cef', 'global', NULL, 'user', 'admin.subscriptions', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.990708');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b3480813-6e8e-4110-97e6-a3e4578365de', 'global', NULL, 'user', 'admin.users', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.991224');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8c07ab83-8027-44c5-a1bf-1802cafefae9', 'global', NULL, 'user', 'nav.rag', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.991754');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('3a4f4714-f8c4-436c-9a55-fc0668d1afae', 'global', NULL, 'user', 'org.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.992751');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c35b7f1a-c975-4901-9417-3d5afe11c2a7', 'global', NULL, 'user', 'org.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.994019');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('3c96c9a2-c127-4ce9-840a-39693d262fc6', 'global', NULL, 'user', 'team.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.994673');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('615fa348-9fb3-43cf-9e6e-3e81873485e2', 'global', NULL, 'user', 'workspace.mcp', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.995214');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('7de112f7-e968-436b-b127-b8dddaaa4237', 'global', NULL, 'user', 'workspace.promptTemplates', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.995768');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('6744666c-87c1-4d3e-bb44-621ece8df6ce', 'global', NULL, 'viewer', 'admin.auditLog', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.99647');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('a023b36e-8984-4484-8f8d-91e31cb61239', 'global', NULL, 'viewer', 'admin.featureFlags', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.997204');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('4b24e52f-d141-4e9c-b9e1-a4376b180d87', 'global', NULL, 'viewer', 'admin.identity', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.997855');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('eb302507-4f0b-4e05-a1fd-bcd5a70d3318', 'global', NULL, 'viewer', 'admin.models', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.998425');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b03f6e4d-561a-4b96-8928-604ee4bc245f', 'global', NULL, 'viewer', 'admin.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.998951');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('3e4f7120-0749-4add-b6b2-515212c6f1d4', 'global', NULL, 'viewer', 'admin.organizations', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:30.999556');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1d2602e7-442d-4c72-a6c4-de9191f53830', 'global', NULL, 'viewer', 'admin.platformSettings', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.000354');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('903e4905-0bba-44f3-aac7-d0b3517c1d72', 'global', NULL, 'viewer', 'admin.security', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.001316');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('773ed795-385d-44d5-9de5-986ed3e0980c', 'global', NULL, 'viewer', 'admin.subscriptions', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.002037');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('757f69a1-86b1-428e-8a3d-9ac1f3c47548', 'global', NULL, 'viewer', 'admin.users', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.002896');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('5dfb1b52-ddd4-4ec3-845b-b146e67c4131', 'global', NULL, 'viewer', 'nav.rag', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.003472');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8c058736-c818-441b-9f0e-a75117f4021b', 'global', NULL, 'viewer', 'org.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.004113');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('fb7a6cdd-a819-48dc-8078-3776a8efdb13', 'global', NULL, 'viewer', 'org.monitor', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.005026');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('699cf266-f3de-47c3-b65c-3d2ce14fb85a', 'global', NULL, 'viewer', 'team.analytics', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.005822');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('dcc5bab1-421b-4a30-aade-df1dfa530193', 'global', NULL, 'viewer', 'workspace.mcp', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.006618');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('9ae0a4a8-857c-46c3-b698-b20e49eace35', 'global', NULL, 'viewer', 'workspace.promptTemplates', false, '862152ec-20d6-4bc9-84b8-47d695c142bd', '2026-08-10 16:53:31.007273');


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: oidc_provider; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_budget; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_compliance_rule; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_custom_model; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_domain_claim; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_invite; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_model_allocation; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_permission_group; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-08-10 16:53:30.849405', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, assistants, workflows, MCP servers and knowledge bases.', true, NULL, '2026-08-10 16:53:30.853326', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-08-10 16:53:30.856043', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-08-10 16:53:30.922258', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, assistants, workflows, MCP servers and knowledge bases.', true, NULL, '2026-08-10 16:53:30.925492', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-08-10 16:53:30.928456', '2026-08-10 16:53:30.928456');


--
-- Data for Name: org_permission_group_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'members:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'teams:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'roles:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'settings:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'billing:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'audit:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'analytics:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'security:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'storage:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'knowledge:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'assistants:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'agents:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'skills:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'workflows:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'mcp:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'memory:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'marketplace:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'models:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('8c21d1c7-8fea-4332-8948-aac73fc3b7ff', 'policies:view', '2026-08-10 16:53:30.849405');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:create', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:edit', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:delete', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:approve', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:disable', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:transfer', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'agents:publish', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:create', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:edit', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:delete', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:deploy', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:approve', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:disable', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:transfer', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'assistants:publish', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'workflows:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'workflows:create', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'workflows:edit', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'workflows:delete', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'mcp:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'mcp:create', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'mcp:edit', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'mcp:delete', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'knowledge:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'knowledge:create', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'knowledge:edit', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'knowledge:search', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c2c165b6-e019-4e51-b6aa-a3a55c33d695', 'models:view', '2026-08-10 16:53:30.853326');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'members:view', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'members:invite', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'members:edit', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'members:remove', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'members:suspend', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'teams:view', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'teams:create', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'teams:edit', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'teams:delete', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('2d4897fb-849d-4441-833e-62b7f275e4e6', 'teams:manage_members', '2026-08-10 16:53:30.856043');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'members:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'teams:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'roles:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'settings:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'billing:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'audit:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'analytics:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'security:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'storage:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'knowledge:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'assistants:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'agents:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'skills:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'workflows:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'mcp:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'memory:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'marketplace:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'models:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('98a924a9-44a7-4522-8f4f-0c6aa9256fcf', 'policies:view', '2026-08-10 16:53:30.922258');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:create', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:edit', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:delete', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:approve', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:disable', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:transfer', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'agents:publish', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:create', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:edit', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:delete', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:deploy', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:approve', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:disable', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:transfer', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'assistants:publish', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'workflows:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'workflows:create', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'workflows:edit', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'workflows:delete', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'mcp:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'mcp:create', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'mcp:edit', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'mcp:delete', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'knowledge:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'knowledge:create', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'knowledge:edit', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'knowledge:search', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('061fce6e-d051-4228-9216-80ff8a2b77e1', 'models:view', '2026-08-10 16:53:30.925492');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'members:view', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'members:invite', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'members:edit', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'members:remove', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'members:suspend', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'teams:view', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'teams:create', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'teams:edit', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'teams:delete', '2026-08-10 16:53:30.928456');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('489af1ee-9764-4931-9aed-0dab694370ff', 'teams:manage_members', '2026-08-10 16:53:30.928456');


--
-- Data for Name: org_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_policy_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_provider_credential; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: organization_member; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('0f08e7ae-51df-42f2-b990-9a8019691fd4', '8f9c1d6a-cf27-4b6c-9903-e1856592baeb', '862152ec-20d6-4bc9-84b8-47d695c142bd', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-08-10 16:53:30.819124');
INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('e63eeb47-9be2-41b9-8854-4dabe10c657e', 'f0cea0d1-b637-4e5c-9f91-2dbd0a7b9d2e', '862152ec-20d6-4bc9-84b8-47d695c142bd', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-08-10 16:53:30.894471');


--
-- Data for Name: org_resource_grant; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_assignment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'members:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'members:invite', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'members:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'members:remove', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'members:suspend', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'teams:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'teams:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'teams:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'teams:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'teams:manage_members', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'roles:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'roles:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'roles:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'roles:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'roles:assign', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'settings:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'settings:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'billing:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'billing:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'audit:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'analytics:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'security:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'security:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'storage:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'storage:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:transfer', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:search', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:publish', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'knowledge:admin', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:deploy', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:approve', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:disable', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:transfer', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'assistants:publish', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:approve', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:disable', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:transfer', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'agents:publish', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:approve', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:certify', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:disable', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'skills:execute', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'workflows:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'workflows:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'workflows:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'workflows:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'mcp:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'mcp:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'mcp:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'mcp:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'memory:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'memory:create', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'memory:edit', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'memory:delete', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'memory:share', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'marketplace:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'marketplace:moderate', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'models:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'models:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'policies:view', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4d99b11f-2c3b-4f9d-be78-ad5f6e042cb7', 'policies:manage', '2026-08-10 16:53:30.831419');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'agents:delete', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'agents:approve', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'agents:disable', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'agents:transfer', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'agents:publish', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'workflows:delete', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'mcp:edit', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'mcp:delete', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:create', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:edit', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:delete', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:deploy', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:approve', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:disable', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:transfer', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'assistants:publish', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'skills:approve', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'skills:disable', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'skills:manage', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'models:manage', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'memory:create', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'memory:edit', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'memory:delete', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('49a60c20-166f-4ccd-ada3-6819959f53cd', 'memory:share', '2026-08-10 16:53:30.836473');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('b9354e24-7fcf-4c7a-9f98-dc05401889c8', 'security:manage', '2026-08-10 16:53:30.838999');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('b9354e24-7fcf-4c7a-9f98-dc05401889c8', 'policies:manage', '2026-08-10 16:53:30.838999');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('b9354e24-7fcf-4c7a-9f98-dc05401889c8', 'members:edit', '2026-08-10 16:53:30.838999');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('b9354e24-7fcf-4c7a-9f98-dc05401889c8', 'members:suspend', '2026-08-10 16:53:30.838999');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:create', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:edit', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:delete', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:transfer', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:admin', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2cafc797-4797-4fd7-9d75-f2428b4147b9', 'knowledge:publish', '2026-08-10 16:53:30.841031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ed4da86e-36e8-4a4a-b1e3-471d5af26a43', 'billing:manage', '2026-08-10 16:53:30.843093');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('89650666-ac51-4c64-a12c-bb523c16f065', 'teams:create', '2026-08-10 16:53:30.844553');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('89650666-ac51-4c64-a12c-bb523c16f065', 'teams:edit', '2026-08-10 16:53:30.844553');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('89650666-ac51-4c64-a12c-bb523c16f065', 'teams:manage_members', '2026-08-10 16:53:30.844553');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('89650666-ac51-4c64-a12c-bb523c16f065', 'members:invite', '2026-08-10 16:53:30.844553');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'agents:create', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'agents:edit', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'workflows:create', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'workflows:edit', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'mcp:create', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'memory:create', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('8581dd37-12f9-4a6b-9a1e-5ce2bac85397', 'memory:edit', '2026-08-10 16:53:30.846333');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'members:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'teams:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'roles:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'settings:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'billing:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'audit:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'analytics:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'security:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'storage:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'knowledge:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'assistants:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'agents:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'skills:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'workflows:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'mcp:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'memory:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'marketplace:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'models:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'policies:view', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('388d91ab-81c5-4a62-ae0c-f0e59c23c2e3', 'knowledge:search', '2026-08-10 16:53:30.847453');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'members:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'members:invite', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'members:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'members:remove', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'members:suspend', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'teams:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'teams:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'teams:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'teams:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'teams:manage_members', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'roles:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'roles:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'roles:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'roles:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'roles:assign', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'settings:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'settings:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'billing:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'billing:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'audit:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'analytics:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'security:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'security:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'storage:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'storage:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:transfer', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:search', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:publish', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'knowledge:admin', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:deploy', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:approve', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:disable', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:transfer', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'assistants:publish', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:approve', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:disable', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:transfer', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'agents:publish', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:approve', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:certify', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:disable', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'skills:execute', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'workflows:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'workflows:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'workflows:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'workflows:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'mcp:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'mcp:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'mcp:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'mcp:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'memory:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'memory:create', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'memory:edit', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'memory:delete', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'memory:share', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'marketplace:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'marketplace:moderate', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'models:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'models:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'policies:view', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ad8026dd-884c-4a32-9944-afc04224d92b', 'policies:manage', '2026-08-10 16:53:30.904961');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'agents:delete', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'agents:approve', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'agents:disable', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'agents:transfer', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'agents:publish', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'workflows:delete', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'mcp:edit', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'mcp:delete', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:create', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:edit', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:delete', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:deploy', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:approve', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:disable', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:transfer', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'assistants:publish', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'skills:approve', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'skills:disable', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'skills:manage', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'models:manage', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'memory:create', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'memory:edit', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'memory:delete', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f2bd4e55-ad3f-4984-9684-402180ba67ea', 'memory:share', '2026-08-10 16:53:30.908866');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('e336e10c-763d-4570-b9d7-ed7c24617ef9', 'security:manage', '2026-08-10 16:53:30.911517');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('e336e10c-763d-4570-b9d7-ed7c24617ef9', 'policies:manage', '2026-08-10 16:53:30.911517');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('e336e10c-763d-4570-b9d7-ed7c24617ef9', 'members:edit', '2026-08-10 16:53:30.911517');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('e336e10c-763d-4570-b9d7-ed7c24617ef9', 'members:suspend', '2026-08-10 16:53:30.911517');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:create', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:edit', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:delete', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:transfer', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:admin', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('cc907b14-7442-4eab-8d50-2cb6fd79ffc0', 'knowledge:publish', '2026-08-10 16:53:30.913556');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4ed0d8de-4bbe-49bb-9d77-b325da745ee4', 'billing:manage', '2026-08-10 16:53:30.915497');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('c78a6ddc-0676-479f-8809-7bab5427dbb6', 'teams:create', '2026-08-10 16:53:30.917466');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('c78a6ddc-0676-479f-8809-7bab5427dbb6', 'teams:edit', '2026-08-10 16:53:30.917466');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('c78a6ddc-0676-479f-8809-7bab5427dbb6', 'teams:manage_members', '2026-08-10 16:53:30.917466');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('c78a6ddc-0676-479f-8809-7bab5427dbb6', 'members:invite', '2026-08-10 16:53:30.917466');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'agents:create', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'agents:edit', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'workflows:create', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'workflows:edit', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'mcp:create', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'memory:create', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('58758fe7-94de-4bc6-9a94-7c7e5fb7a6bd', 'memory:edit', '2026-08-10 16:53:30.919432');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'members:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'teams:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'roles:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'settings:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'billing:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'audit:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'analytics:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'security:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'storage:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'knowledge:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'assistants:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'agents:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'skills:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'workflows:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'mcp:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'memory:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'marketplace:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'models:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'policies:view', '2026-08-10 16:53:30.920528');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5613029d-2885-4039-addc-720f17ed46d3', 'knowledge:search', '2026-08-10 16:53:30.920528');


--
-- Data for Name: org_role_permission_group; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_routing_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_security_settings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_storage_governance; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_label; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_mcp_access; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_model_allocation; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_preference; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_rate_limit; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_token_quota; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_user_tool_permission; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: organization_settings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: plan_entitlement; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: plugin_bundle; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: plugin_bundle_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: plugin_bundle_item; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: prompt_experiment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: prompt_template; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: rag_search_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: rag_user_config; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: retrieval_feedback; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: saml_provider; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: scim_config; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: scim_group; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: security_event_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: semantic_response_cache; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: session_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('3f313de9-8ea8-4643-b7e1-2bc0b4581603', 'Python Code Runner', 'Execute Python scripts in the browser via Pyodide. Supports numpy, pandas, matplotlib, scipy. Guides correct usage of the sandboxed environment.', '# Python Code Runner

Use the `python-execution` tool to run Python code directly in the browser via Pyodide.

## Environment Overview

- **Runtime**: Pyodide v0.23.4 (WebAssembly Python 3.11)
- **Auto-loaded packages**: numpy, pandas, matplotlib, scipy (imported on first use)
- **No installation needed**: These packages are available immediately

## Constraints

### Filesystem
- `open()` raises `OSError` — no local filesystem access
- Use `io.StringIO` / `io.BytesIO` for in-memory file operations

### Networking
- `requests` and standard `urllib` do **not** work
- Use Pyodide''s HTTP helper instead:
  ```python
  from pyodide.http import open_url
  content = open_url("https://example.com/data.csv").read()
  ```

## Output Patterns

Print results directly — all stdout is captured and returned:
```python
print("Result:", result)
print(df.to_string())
```

## Error Handling Template

```python
try:
    result = compute_something()
    print("Success:", result)
except Exception as e:
    print(f"Error: {type(e).__name__}: {e}")
```

## When to Use This Skill

Invoke when the user asks to:
- Run, execute, or test Python code
- Perform calculations or data processing
- Prototype algorithms or functions
- Verify Python syntax or logic', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{python,execution,scripting,pyodide}', '{"type":"emoji","value":"🐍"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('d97439ee-aacd-4208-a50f-e55c2d04e1cd', 'Data Analysis — Pandas & NumPy', 'Analyze datasets with pandas and numpy in the browser. CSV loading via StringIO or URL fetch, descriptive stats, groupby, correlation, and more.', '# Data Analysis — Pandas & NumPy

Analyze data using pandas and numpy via the `python-execution` tool.

## Loading Data

### From inline CSV string
```python
import pandas as pd
import io

csv_data = """name,age,score
Alice,30,85
Bob,25,92
Carol,35,78"""

df = pd.read_csv(io.StringIO(csv_data))
print(df.head())
```

### From a URL
```python
import pandas as pd
import io
from pyodide.http import open_url

url = "https://example.com/data.csv"
content = open_url(url).read()
df = pd.read_csv(io.StringIO(content))
```

## Descriptive Statistics

```python
print(df.describe())
print("\nShape:", df.shape)
print("\nNull counts:\n", df.isnull().sum())
print("\nDtypes:\n", df.dtypes)
```

## GroupBy & Aggregation

```python
grouped = df.groupby("category").agg(
    count=("value", "count"),
    mean=("value", "mean"),
    total=("value", "sum"),
)
print(grouped)
```

## Correlation Matrix

```python
import numpy as np

numeric_cols = df.select_dtypes(include=np.number)
print(numeric_cols.corr().round(3))
```

## Filtering & Sorting

```python
filtered = df[df["score"] > 80].sort_values("score", ascending=False)
print(filtered)
```

## When to Use This Skill

Invoke when the user asks to:
- Analyze CSV or tabular data
- Compute summary statistics or aggregations
- Filter, sort, or transform datasets
- Find correlations or patterns in data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{pandas,numpy,data-analysis,statistics,csv}', '{"type":"emoji","value":"📊"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('21762bb0-c4f8-411c-8395-76cb63eea30d', 'Data Visualization — Matplotlib', 'Create charts and plots with matplotlib in the Pyodide sandbox. Includes agg backend setup and all common chart types.', '# Data Visualization — Matplotlib

Create charts using matplotlib via the `python-execution` tool.

## Required Setup

Always set the `agg` backend **before** importing pyplot — this enables chart capture in the
browser:

```python
import matplotlib
matplotlib.use(''agg'')
import matplotlib.pyplot as plt
```

Calling `plt.show()` renders the chart inline in the response.

## Line Chart

```python
import matplotlib
matplotlib.use(''agg'')
import matplotlib.pyplot as plt

x = [1, 2, 3, 4, 5]
y = [2, 4, 1, 6, 3]

plt.figure(figsize=(8, 4))
plt.plot(x, y, marker=''o'', linewidth=2, color=''steelblue'')
plt.title("Line Chart")
plt.xlabel("X")
plt.ylabel("Y")
plt.grid(True)
plt.show()
```

## Bar Chart

```python
categories = ["A", "B", "C", "D"]
values = [23, 45, 12, 67]

plt.figure(figsize=(8, 4))
plt.bar(categories, values, color=''coral'')
plt.title("Bar Chart")
plt.xlabel("Category")
plt.ylabel("Value")
plt.show()
```

## Scatter Plot

```python
import numpy as np

x = np.random.randn(100)
y = x * 2 + np.random.randn(100)

plt.figure(figsize=(6, 6))
plt.scatter(x, y, alpha=0.6, color=''purple'')
plt.title("Scatter Plot")
plt.xlabel("X")
plt.ylabel("Y")
plt.show()
```

## Histogram

```python
data = np.random.normal(50, 10, 500)

plt.figure(figsize=(8, 4))
plt.hist(data, bins=30, color=''teal'', edgecolor=''white'')
plt.title("Histogram")
plt.xlabel("Value")
plt.ylabel("Frequency")
plt.show()
```

## When to Use This Skill

Invoke when the user asks to:
- Plot, chart, or visualize data
- Create graphs (line, bar, scatter, histogram, pie, heatmap)
- Generate figures or diagrams from data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{matplotlib,visualization,charts,plots}', '{"type":"emoji","value":"📈"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('b704df07-8ef8-4af5-b8e4-4e4edf4ef8e4', 'Math & Statistics Calculator', 'Perform advanced math, statistics, and scientific computing with numpy and scipy. Covers hypothesis tests, linear algebra, integration, optimization, and distributions.', '# Math & Statistics Calculator

Use numpy and scipy for advanced mathematical and statistical computation via the
`python-execution` tool.

## Descriptive Statistics

```python
import numpy as np
from scipy import stats

data = [12, 15, 14, 10, 18, 20, 13, 16, 11, 17]

print(f"Mean:     {np.mean(data):.4f}")
print(f"Median:   {np.median(data):.4f}")
print(f"Std Dev:  {np.std(data, ddof=1):.4f}")
print(f"Skewness: {stats.skew(data):.4f}")
print(f"Kurtosis: {stats.kurtosis(data):.4f}")
```

## Hypothesis Testing

### One-sample t-test
```python
t_stat, p_value = stats.ttest_1samp(data, popmean=14)
print(f"t-statistic: {t_stat:.4f}, p-value: {p_value:.4f}")
```

### Two-sample t-test
```python
group_a = [12, 15, 14, 10, 18]
group_b = [20, 22, 19, 21, 23]
t_stat, p_value = stats.ttest_ind(group_a, group_b)
print(f"t-statistic: {t_stat:.4f}, p-value: {p_value:.4f}")
```

## Linear Algebra

```python
A = np.array([[2, 1], [5, 3]])
b = np.array([4, 7])

x = np.linalg.solve(A, b)
print("Solution:", x)
print("Eigenvalues:", np.linalg.eigvals(A))
print("Determinant:", np.linalg.det(A))
```

## Numerical Integration

```python
from scipy import integrate

result, error = integrate.quad(lambda x: x**2 + np.sin(x), 0, np.pi)
print(f"Integral: {result:.6f} (error: {error:.2e})")
```

## Optimization

```python
from scipy.optimize import minimize

def objective(x):
    return (x[0] - 2)**2 + (x[1] + 1)**2

result = minimize(objective, x0=[0, 0])
print(f"Minimum at: {result.x}, value: {result.fun:.6f}")
```

## Probability Distributions

```python
dist = stats.norm(loc=0, scale=1)
print(f"P(X < 1.96) = {dist.cdf(1.96):.4f}")
print(f"95th percentile = {dist.ppf(0.95):.4f}")
```

## When to Use This Skill

Invoke when the user asks to:
- Compute statistics, probabilities, or p-values
- Solve equations or linear algebra problems
- Perform numerical integration or optimization
- Work with probability distributions', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{math,statistics,numpy,scipy,computation}', '{"type":"emoji","value":"🧮"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('ab69cb23-81be-4322-8f3d-e83625aa2ac6', 'Text & File Processing', 'Parse and transform text, JSON, CSV, and structured data in Python. Covers regex extraction, word frequency, string transforms, and URL text fetching.', '# Text & File Processing

Process text and structured data formats using Python via the `python-execution` tool.

## JSON Parsing & Transformation

```python
import json

raw = ''{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}''
data = json.loads(raw)

for user in data["users"]:
    print(f"{user[''name'']}: {user[''age'']} years old")

# Re-serialize with formatting
print(json.dumps(data, indent=2))
```

## CSV Parsing

```python
import csv
import io

csv_text = """id,name,score
1,Alice,95
2,Bob,87
3,Carol,92"""

reader = csv.DictReader(io.StringIO(csv_text))
rows = list(reader)
for row in rows:
    print(f"{row[''name'']}: {row[''score'']}")
```

## Regex Extraction

```python
import re

text = "Contact us at support@example.com or sales@company.org for help."

emails = re.findall(r''[\w.+-]+@[\w-]+\.[\w.]+'', text)
print("Emails found:", emails)

# Named groups
pattern = r''(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})''
match = re.search(pattern, "Date: 2024-03-15")
if match:
    print(match.groupdict())
```

## Word Frequency

```python
from collections import Counter
import re

text = "the quick brown fox jumps over the lazy dog the fox"
words = re.findall(r''\b\w+\b'', text.lower())
freq = Counter(words)
for word, count in freq.most_common(5):
    print(f"{word}: {count}")
```

## String Transforms

```python
text = "  Hello, World! This is a TEST.  "

print(text.strip())
print(text.lower())
print(text.upper())
print(text.title())
print(text.replace("TEST", "example"))
print("-".join(text.strip().split()))
```

## Fetch Text from URL

```python
from pyodide.http import open_url

content = open_url("https://example.com/data.txt").read()
lines = content.strip().split("\n")
print(f"Fetched {len(lines)} lines")
print(lines[:5])
```

## When to Use This Skill

Invoke when the user asks to:
- Parse or extract data from JSON, CSV, or plain text
- Apply regex patterns for search or extraction
- Count word frequencies or analyze text
- Transform or reformat strings
- Fetch and process text from a URL', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{text,parsing,csv,json,regex}', '{"type":"emoji","value":"📝"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('3fee077d-28ea-4a9b-b44b-10015735aa50', 'Server-Side Python Executor', 'Run real Python (or shell) commands on the server backend using the bash-execution tool. Unlike Pyodide, this uses the actual system Python with full stdlib, file I/O, pip-installed packages, and no CORS restrictions.', '# Server-Side Python Executor

Use the `bash-execution` tool to run Python (or other allowed commands) directly on the server.

---
allowed-tools: ["bash-execution"]
user-invocable: true
---

## Key Differences from Pyodide (browser Python)

| Feature | Pyodide (browser) | bash-execution (server) |
|---------|-------------------|------------------------|
| Runtime | WebAssembly Python 3.11 | Real system Python |
| Filesystem | No access | Read/write inside sandbox dir |
| Packages | numpy, pandas, scipy, matplotlib | Any pip-installed system package |
| Network | Limited (CORS) | Full network (via allowed commands) |
| Execution | In-browser | Server subprocess |

## Usage Patterns

### Run a quick calculation
```python
# command: python3 -c "import math; print(math.factorial(20))"
```

### Run a multi-line script (write to temp file first)
Write the script to the sandbox, then execute it:
```
# command: python3 /tmp/neogen-sandbox/script.py
```

### Check available Python version
```
# command: python3 --version
```

### List sandbox files
```
# command: ls /tmp/neogen-sandbox
```

## Security Notes

- Commands run inside `/tmp/neogen-sandbox` by default
- Only whitelisted commands are allowed (python3, python, node, echo, cat, ls, pwd, curl)
- Dangerous patterns (`rm -rf`, `sudo`, etc.) are blocked automatically
- No environment secrets are passed to subprocesses
- Default timeout: 10 seconds

## When to Use

- Computations requiring the full Python stdlib
- File I/O operations (reading/writing data files)
- Running scripts that use system-installed packages
- Tasks where Pyodide''s WASM environment is insufficient
', '{"allowed-tools":["bash-execution"],"user-invocable":true}', 'development', '{python,bash,server,execution,code}', '{"type":"emoji","value":"🖥️"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'none', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('66d49fce-de28-4915-8ad8-60e7348123fc', 'Presentation Builder', 'Create real PowerPoint (.pptx) decks in the browser with the PptxGenJS global — slides, styled text, bullets, tables, images — delivered as a downloadable file via Files.save.', '# Presentation Builder

Create downloadable PowerPoint files with the `mini-javascript-execution`
tool. The sandbox exposes a `PptxGenJS` global (pptxgenjs, MIT).

## Sandbox Rules (read before writing code)

- Output files ONLY via `Files.save(name, data, mimeType?)` — max 5 files,
  10MB each, per execution. There is no other download mechanism.
- Never use bracket-notation property access with a plain string key
  (`obj["key"]` is blocked). Dot access only. Keys starting with `!`
  (SheetJS metadata like `ws["!cols"]`) are the one allowed exception.
- Never build strings with literal-to-literal concatenation (`"a" + "b"` is
  blocked). Use template literals or single strings.
- Never name identifiers containing `document`, `window`, or `process`
  (blocked as substrings). Use `d`, `pdfDoc`, `proc`, etc.
- Execution times out at 30 seconds — keep generation loops bounded.

## Critical output rule

Always finish with `write({ outputType: "arraybuffer" })` handed to
`Files.save`. NEVER call `pptx.writeFile()` — it needs a DOM and throws in
this sandbox.

## Canvas and layout

Set the layout before adding slides. `LAYOUT_WIDE` is 13.33 x 7.5 inches;
all x/y/w/h coordinates are in inches from the top-left corner. Content
placed past the canvas edge is silently invisible, not clamped.

## Title + bullet slides

```js
const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_WIDE";

const title = pptx.addSlide();
title.background = { color: "20304A" };
title.addText("Quarterly Review", {
  x: 0.6, y: 2.6, w: 12, h: 1.2,
  fontSize: 40, bold: true, color: "FFFFFF",
});

const body = pptx.addSlide();
body.addText("Highlights", {
  x: 0.6, y: 0.4, w: 12, h: 0.8, fontSize: 28, bold: true, color: "20304A",
});
body.addText([
  { text: "Revenue grew 12 percent", options: { bullet: true, breakLine: true } },
  { text: "Churn fell below 2 percent", options: { bullet: true } },
], { x: 0.8, y: 1.4, w: 11, h: 3, fontSize: 18 });

const buf = await pptx.write({ outputType: "arraybuffer" });
Files.save("review.pptx", buf);
```

Bullet rules: set `bullet: true` per item — never type a literal bullet
character (it renders doubled). Set `breakLine: true` on every array item
except the last.

## Tables

```js
const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_WIDE";
const slide = pptx.addSlide();
slide.addText("Revenue by Region", {
  x: 0.6, y: 0.4, w: 12, h: 0.8, fontSize: 24, bold: true,
});
slide.addTable([
  [{ text: "Region", options: { bold: true } }, { text: "Revenue", options: { bold: true } }],
  [{ text: "EMEA" }, { text: "1.2M" }],
  [{ text: "APAC" }, { text: "0.9M" }],
], { x: 0.6, y: 1.4, w: 12, colW: [6, 6], fontSize: 16, border: { pt: 0.5, color: "C8CDD4" } });
const buf = await pptx.write({ outputType: "arraybuffer" });
Files.save("regions.pptx", buf);
```

## Slide masters (consistent branding)

Define a master once, then stamp every slide from it — background, footer
band, and logo text repeat automatically:

```js
const pptx = new PptxGenJS();
pptx.layout = "LAYOUT_WIDE";
pptx.defineSlideMaster({
  title: "BRAND",
  background: { color: "F6F4EF" },
  objects: [
    { rect: { x: 0, y: 7.0, w: "100%", h: 0.5, fill: { color: "20304A" } } },
    { text: {
      text: "Acme Corp",
      options: { x: 0.5, y: 7.02, w: 4, h: 0.4, fontSize: 12, color: "FFFFFF" },
    } },
  ],
});
const slide = pptx.addSlide({ masterName: "BRAND" });
slide.addText("On-brand slide", {
  x: 0.6, y: 0.6, w: 9, h: 1, fontSize: 28, bold: true, color: "20304A",
});
const buf = await pptx.write({ outputType: "arraybuffer" });
Files.save("branded.pptx", buf);
```

## Images and charts

- Images: `slide.addImage({ data: base64String, x, y, w, h })` with PNG or
  JPEG data only — SVG conversion needs a DOM and fails in this sandbox.
  Downscale large images first; the whole file must stay under 10MB.
- Charts: `slide.addChart` supports bar, line, pie and more; pass data as
  an array of series objects. Prefer native charts over chart images.

## Design guidance

- Hex colors take NO leading `#` (`"20304A"`, never `"#20304A"`).
- Pick one dominant color plus one accent; repeat them on every slide.
- Keep a slide to one idea and at most six bullets; move detail to more
  slides rather than shrinking the font below 16pt.
- Dark title slide + light content slides reads well with zero effort.

## When to use this skill

The user asks for a presentation, slide deck, pitch deck, or .pptx file.

## Format scope (critical)

This skill produces .pptx ONLY. If the user asked for a PDF, Word document,
or spreadsheet, do NOT substitute a .pptx for it. The matching skills are
PDF Builder, Word Document Builder, and Spreadsheet Builder — if the one the
user needs is not among your available tools, tell the user to install it
from Skills > Marketplace, then stop and wait instead of generating a
different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'creative', '{pptx,powerpoint,presentation,slides,pptxgenjs}', '{"type":"emoji","value":"📽️"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('f88f8187-9aa7-437f-96a7-3e12024f2fbb', 'Word Document Builder', 'Create real Word (.docx) documents in the browser with the docx global — headings, styled runs, lists, tables, page breaks — delivered as a downloadable file via Files.save.', '# Word Document Builder

Create downloadable Word files with the `mini-javascript-execution` tool.
The sandbox exposes a `docx` global (the docx npm package, MIT).

## Sandbox Rules (read before writing code)

- Output files ONLY via `Files.save(name, data, mimeType?)` — max 5 files,
  10MB each, per execution. There is no other download mechanism.
- Never use bracket-notation property access with a plain string key
  (`obj["key"]` is blocked). Dot access only. Keys starting with `!`
  (SheetJS metadata like `ws["!cols"]`) are the one allowed exception.
- Never build strings with literal-to-literal concatenation (`"a" + "b"` is
  blocked). Use template literals or single strings.
- Never name identifiers containing `document`, `window`, or `process`
  (blocked as substrings). Use `d`, `pdfDoc`, `proc`, etc.
- Execution times out at 30 seconds — keep generation loops bounded.

## Critical naming rule

ALWAYS destructure the classes you need from the `docx` global first, and
never name your own variables anything containing `document` — the sandbox
validator blocks that substring. Use `d` for the Document instance.

## Structured document

```js
const { Document, Packer, Paragraph, TextRun, HeadingLevel } = docx;

const d = new Document({
  sections: [{
    children: [
      new Paragraph({ text: "Project Report", heading: HeadingLevel.HEADING_1 }),
      new Paragraph({ text: "Summary", heading: HeadingLevel.HEADING_2 }),
      new Paragraph({
        children: [
          new TextRun("The rollout finished "),
          new TextRun({ text: "ahead of schedule", bold: true }),
          new TextRun(" with no open incidents."),
        ],
      }),
      new Paragraph({ text: "Next steps", heading: HeadingLevel.HEADING_2 }),
      new Paragraph({ text: "Expand to the EU region", bullet: { level: 0 } }),
      new Paragraph({ text: "Review cost dashboards weekly", bullet: { level: 0 } }),
    ],
  }],
});

const blob = await Packer.toBlob(d);
Files.save("report.docx", await blob.arrayBuffer());
```

Styling lives on `TextRun` (`bold`, `italics`, `size` in half-points,
`color` as hex without `#`). Structure lives on `Paragraph` (`heading`,
`bullet`, `spacing`, `alignment`).

## Tables

```js
const { Document, Packer, Paragraph, Table, TableRow, TableCell, WidthType } = docx;

const rows = [
  new TableRow({ children: [
    new TableCell({ children: [new Paragraph("Item")] }),
    new TableCell({ children: [new Paragraph("Qty")] }),
  ]}),
  new TableRow({ children: [
    new TableCell({ children: [new Paragraph("Laptops")] }),
    new TableCell({ children: [new Paragraph("12")] }),
  ]}),
];

const d = new Document({
  sections: [{
    children: [
      new Paragraph({ text: "Inventory" }),
      new Table({ rows, width: { size: 100, type: WidthType.PERCENTAGE } }),
    ],
  }],
});

const blob = await Packer.toBlob(d);
Files.save("inventory.docx", await blob.arrayBuffer());
```

## Page breaks and multiple sections

Insert `new Paragraph({ children: [new PageBreak()] })` (destructure
`PageBreak` too) to force a new page, or start a new entry in `sections`
for different headers/orientation.

## When to use this skill

The user asks for a Word document, report, memo, letter, or .docx file.

## Format scope (critical)

This skill produces .docx ONLY. If the user asked for a PDF, presentation,
or spreadsheet, do NOT substitute a .docx for it. The matching skills are
PDF Builder, Presentation Builder, and Spreadsheet Builder — if the one the
user needs is not among your available tools, tell the user to install it
from Skills > Marketplace, then stop and wait instead of generating a
different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'writing', '{docx,word,report,letter}', '{"type":"emoji","value":"📄"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('103412ac-dace-4ea9-aa1e-0cdd8179adce', 'Spreadsheet Builder', 'Create real Excel (.xlsx) workbooks in the browser with the XLSX (SheetJS) global — multiple sheets, column widths, formulas — delivered as a downloadable file via Files.save.', '# Spreadsheet Builder

Create downloadable Excel workbooks with the `mini-javascript-execution`
tool. The sandbox exposes an `XLSX` global (SheetJS).

## Sandbox Rules (read before writing code)

- Output files ONLY via `Files.save(name, data, mimeType?)` — max 5 files,
  10MB each, per execution. There is no other download mechanism.
- Never use bracket-notation property access with a plain string key
  (`obj["key"]` is blocked). Dot access only. Keys starting with `!`
  (SheetJS metadata like `ws["!cols"]`) are the one allowed exception.
- Never build strings with literal-to-literal concatenation (`"a" + "b"` is
  blocked). Use template literals or single strings.
- Never name identifiers containing `document`, `window`, or `process`
  (blocked as substrings). Use `d`, `pdfDoc`, `proc`, etc.
- Execution times out at 30 seconds — keep generation loops bounded.

## Critical access rule

Never address cells as `ws["A1"]` — plain-string bracket access is blocked.
Build sheets from arrays with `XLSX.utils` helpers instead. SheetJS
metadata keys starting with `!` (like `ws["!cols"]`) are allowed.

## Multi-sheet workbook with widths and a formula

```js
const summaryRows = [
  ["Metric", "Value"],
  ["Customers", 1284],
  ["Active seats", 3921],
];
const spendRows = [
  ["Team", "Amount"],
  ["Platform", 5200],
  ["Data", 3100],
  ["Total", { f: "SUM(B2:B3)" }],
];

const wb = XLSX.utils.book_new();
const summary = XLSX.utils.aoa_to_sheet(summaryRows);
const spend = XLSX.utils.aoa_to_sheet(spendRows);
summary["!cols"] = [{ wch: 18 }, { wch: 12 }];
spend["!cols"] = [{ wch: 14 }, { wch: 12 }];
XLSX.utils.book_append_sheet(wb, summary, "Summary");
XLSX.utils.book_append_sheet(wb, spend, "Spend");

const data = XLSX.write(wb, { type: "array", bookType: "xlsx" });
Files.save("dashboard.xlsx", data);
```

Formula cells are plain objects with an `f` key inside the row arrays —
Excel evaluates them on open. Number cells stay numbers (no quoting), so
downstream formulas and formatting work.

## Number formats (currency, percent, dates)

Give a cell a number format by using a cell object with `v` (value),
`t: "n"` (numeric type — REQUIRED, or the value is written as text and the
format never renders), and `z` (format code) inside the row arrays — no
bracket access needed:

```js
const rows = [
  ["Product", "Price", "Share"],
  ["Basic", { v: 19.99, t: "n", z: "$#,##0.00" }, { v: 0.42, t: "n", z: "0.0%" }],
  ["Pro", { v: 49.5, t: "n", z: "$#,##0.00" }, { v: 0.58, t: "n", z: "0.0%" }],
];
const ws = XLSX.utils.aoa_to_sheet(rows);
ws["!cols"] = [{ wch: 12 }, { wch: 12 }, { wch: 10 }];
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, "Pricing");
Files.save("pricing.xlsx", XLSX.write(wb, { type: "array", bookType: "xlsx" }));
```

Common format codes: `"$#,##0.00"` currency, `"0.0%"` percent,
`"#,##0"` thousands, `"yyyy-mm-dd"` dates (pair with a real Date value).

## From objects instead of arrays

`XLSX.utils.json_to_sheet(arrayOfObjects)` maps object keys to a header
row automatically — handy when data arrives as JSON from `fetch`.

## When to use this skill

The user asks for a spreadsheet, workbook, budget, tracker, or .xlsx file.
For plain tabular text a .csv via `Files.save("data.csv", csvString)` is
also fine — use xlsx when formulas, multiple sheets, or typing matter.

## Format scope (critical)

This skill produces .xlsx (or .csv) ONLY. If the user asked for a PDF,
presentation, or Word document, do NOT substitute a spreadsheet for it. The
matching skills are PDF Builder, Presentation Builder, and
Word Document Builder — if the one the user needs is not among your
available tools, tell the user to install it from Skills > Marketplace,
then stop and wait instead of generating a different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'analysis', '{xlsx,excel,spreadsheet,sheetjs}', '{"type":"emoji","value":"📊"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('876dccdb-8c2e-4abc-a74f-7b452a92836b', 'PDF Builder', 'Create real PDF files in the browser with the PDFLib global (pdf-lib) — text, shapes, multi-page layouts — delivered as a downloadable file via Files.save.', '# PDF Builder

Create downloadable PDFs with the `mini-javascript-execution` tool. The
sandbox exposes a `PDFLib` global (pdf-lib, MIT).

## Sandbox Rules (read before writing code)

- Output files ONLY via `Files.save(name, data, mimeType?)` — max 5 files,
  10MB each, per execution. There is no other download mechanism.
- Never use bracket-notation property access with a plain string key
  (`obj["key"]` is blocked). Dot access only. Keys starting with `!`
  (SheetJS metadata like `ws["!cols"]`) are the one allowed exception.
- Never build strings with literal-to-literal concatenation (`"a" + "b"` is
  blocked). Use template literals or single strings.
- Never name identifiers containing `document`, `window`, or `process`
  (blocked as substrings). Use `d`, `pdfDoc`, `proc`, etc.
- Execution times out at 30 seconds — keep generation loops bounded.

## Coordinates

pdf-lib measures in points (72 per inch) from the BOTTOM-left corner. An A4
page is 595 x 842 points, so "top of the page" is a large y value.

## Text encoding (critical)

The built-in StandardFonts encode WinAnsi (Latin-1) ONLY. `drawText` throws
"WinAnsi cannot encode" on arrows, em dashes, smart quotes, emoji, and
non-Latin scripts. Stick to plain ASCII: write `->` instead of an arrow
character, `-` instead of an em dash, straight quotes instead of curly ones.

## One-page document

```js
const pdfDoc = await PDFLib.PDFDocument.create();
const font = await pdfDoc.embedFont(PDFLib.StandardFonts.HelveticaBold);
const page = pdfDoc.addPage(PDFLib.PageSizes.A4);

page.drawText("Invoice #2041", { x: 50, y: 780, size: 24, font });
page.drawLine({
  start: { x: 50, y: 770 }, end: { x: 545, y: 770 },
  thickness: 1, color: PDFLib.rgb(0.2, 0.25, 0.35),
});
page.drawText("Amount due: 1,250.00", { x: 50, y: 740, size: 12 });

Files.save("invoice.pdf", await pdfDoc.save());
```

## Multi-page pagination

Track the y cursor and start a new page before running off the bottom:

```js
const pdfDoc = await PDFLib.PDFDocument.create();
const font = await pdfDoc.embedFont(PDFLib.StandardFonts.Helvetica);
const lines = ["alpha", "beta", "gamma", "delta", "epsilon"];

let page = pdfDoc.addPage(PDFLib.PageSizes.A4);
let y = 800;
for (const line of lines) {
  if (y < 60) {
    page = pdfDoc.addPage(PDFLib.PageSizes.A4);
    y = 800;
  }
  page.drawText(line, { x: 50, y, size: 12, font });
  y -= 18;
}

Files.save("list.pdf", await pdfDoc.save());
```

## Shapes and color

`drawRectangle`, `drawLine`, and `drawCircle` take
`PDFLib.rgb(r, g, b)` colors with components from 0 to 1. Use a filled
rectangle behind text for header bands.

## Merging existing PDFs

`PDFLib.PDFDocument.load(bytes)` opens an existing PDF fetched at runtime;
`copyPages` moves pages between documents. Remote fetches are subject to
CORS — prefer generating from data you already have.

## When to use this skill

The user asks for a PDF: invoice, certificate, one-pager, printable form.

## Format scope (critical)

This skill produces .pdf ONLY. If the user asked for a presentation, Word
document, or spreadsheet, do NOT substitute a PDF for it. The matching
skills are Presentation Builder, Word Document Builder, and
Spreadsheet Builder — if the one the user needs is not among your available
tools, tell the user to install it from Skills > Marketplace, then stop and
wait instead of generating a different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'productivity', '{pdf,pdf-lib,invoice,printable}', '{"type":"emoji","value":"📑"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('1e06d668-4db9-425a-9996-d266703b6a34', 'Competitor Comparison', 'Compare 2–20 companies, products, APIs, LLMs, frameworks or platforms and generate an executive comparison report with a feature/pricing matrix, strengths, weaknesses, rankings and sources. Use for: compare A vs B, X versus Y, competitive analysis, battle card, vendor comparison, feature comparison, pricing comparison, technical comparison, market comparison, top competitors, best alternative / alternative to X.', '# Competitor Comparison

Produce an executive comparison report for 2–20 companies, products, services, APIs, LLMs, frameworks or platforms, directly in chat. Work fast: parallel searches, tight page budgets, cached results.

## Step 0 — Preflight: tool availability

- This skill needs a web tool. If neither `webSearch` nor `webContent` is available in this chat, do NOT produce a comparison from memory: if `http` is available, use it as the fallback (Step 2); if no web tool is available at all, tell the user to enable **Web Search** in the composer tool picker (and re-send the request), then stop.

## Step 1 — Detect & Deduplicate Competitors

- Extract every company/product named in the request (and in the invocation arguments, when provided at the end of this document).
- If the request names a category or asks for alternatives/top competitors WITHOUT naming them ("compare the top 10 CRM platforms", "best alternatives to X"), first run ONE discovery `webSearch` (e.g. `top <category> platforms` or `"<X>" competitors alternatives`) to enumerate the competitor set; state the discovered list and its source at the top of the report. For "alternative(s) to X", include X itself as the baseline column.
- Deduplicate case-insensitively and ignore legal/qualifier suffixes (Inc, Ltd, LLC, Corp, Group, GmbH, AB, Co): "SKF", "skf" and "SKF Group" are ONE competitor. Note any merges in the final report.
- Bounds: 2–20 competitors. Fewer than 2 distinct after dedupe → ask the user for at least one more. More than 20 → compare the first 20 and say so.
- Focus filters, when the user names them, shape search and report emphasis: pricing, features, technical specifications, architecture, security, deployment, integrations, AI capabilities, compliance, performance, documentation, support, roadmap, latest releases. No filter → balanced coverage.
- Depth: "executive summary" → deliver only the Executive Summary, Competitor Overview and Recommendations (plus Sources); "detailed report" (the default) → the full Step 5 structure.

## Step 2 — Search (parallel, search-API first)

- In a SINGLE response, issue one `webSearch` call per competitor IN PARALLEL — never search competitors one at a time:
  - query: `"<competitor>" official site products pricing features`
  - `numResults: 6`, `category: "company"`, `maxCharacters: 3000`
- When focus filters were requested, add up to 3 focused searches per competitor to the same parallel batch, e.g. `"<competitor>" pricing plans tiers`, `"<competitor>" security SOC 2 ISO 27001 compliance`, `"<competitor>" release notes changelog`.
- Target only the highest-value pages: home, products, features, pricing, documentation, security, downloads, release notes, about, support, developer portal. Prefer results on the competitor''s official domain. Never crawl a complete website.
- Page budget: 10 pages per competitor by default, hard maximum 20. Never fetch the same URL twice — search and page results are cached for 24 hours, so repeated comparisons reuse them.
- Use `webContent` only to fill gaps, batching ALL missing URLs for a competitor into ONE call via `urls: [...]`.
- If `webSearch` is unavailable, fall back to the `http` tool against likely official URLs. Use `browser-automation` ONLY as a last resort when both search and direct fetch fail and the tool is available in this chat.

## Step 3 — Extract (structured, evidence-only)

For each competitor, record only what the fetched sources actually state: company overview, products, features, pricing (model and tiers), technical specifications, deployment models, security, compliance, integrations, supported platforms, AI features, target industries, documentation, support, latest version / latest release, differentiators.

- Every fact carries its source URL, retrieval date/timestamp, and a confidence score:
  - **high** — stated on the competitor''s official domain
  - **medium** — from a third-party source
  - **low** — weak or indirect evidence
  - Downgrade one level when the page is more than a year old.
- Any fact not present in the sources is the literal string UNKNOWN. Never infer, estimate or invent a value. Never hallucinate.
- A competitor that cannot be found at all (invalid or unrecognized name) gets every field marked UNKNOWN and is listed under "Not Found" in the Competitor Overview — never silently drop it.
- A competitor whose pages time out or fail to fetch does NOT fail the run: do not retry beyond the page budget, keep whatever search-snippet evidence you already have, mark the remaining fields UNKNOWN, and note the competitor as "partially unavailable" in the Competitor Overview.

## Step 4 — Normalize Terminology

Vendors describe the same capability with different words. Map synonyms to canonical terms BEFORE building the matrix, so equivalent capabilities land in the same row:

| Canonical | Synonyms |
|---|---|
| AI Assistant | AI Copilot, Copilot, Digital Assistant, Virtual Assistant |
| Cloud Deployment | SaaS, Cloud Hosted, Cloud Native, Hosted |
| SSO | Single Sign-On, Single Sign On |
| On-Premise | On-Prem, Self-Hosted, Self Hosted |
| API Access | REST API, Public API, Developer API |
| SOC 2 | SOC2, SOC 2 Type II, SOC 2 Type 2 |
| ISO 27001 | ISO27001, ISO 27001:2022 |

Extend the same principle to any other synonymous terms you encounter — the table above is a starting dictionary, not a closed list.

## Step 5 — Report (fixed structure, in this order)

1. **Executive Summary** — 2–5 paragraphs.
2. **Competitor Overview** — one paragraph per competitor; list Not Found competitors here explicitly.
3. **Comparison Matrix** — markdown table: one column per competitor, one row per normalized capability; use — for UNKNOWN cells. When focus filters were requested, put those dimensions first. When pricing data exists for 2+ competitors, add a dedicated Pricing sub-table (plans/tiers × competitors) beneath the main matrix. Use `createTable` in addition when an interactive table helps.
4. **Strengths** — grouped by competitor.
5. **Weaknesses** — grouped by competitor; include Missing Capabilities: normalized capabilities other competitors have that this one lacks or reports UNKNOWN.
6. **Unique Differentiators** — grouped by competitor.
7. **Rankings** — only where evidence supports them (e.g. feature completeness, AI capabilities, documentation quality, security, integration coverage, developer experience, enterprise readiness, innovation, support). Every ranking entry states its score, reason, evidence and confidence. Do not generate arbitrary scores — explain every ranking.
8. **Recommendations** — best fit for Enterprise, SMB, Developer, relevant industries (Manufacturing, Healthcare, Financial Services, Government) and General Purpose — ONLY where the evidence supports a recommendation; otherwise state that evidence is insufficient. End with a one-paragraph **Final Recommendation**: the overall best choice, or an explicit "depends on segment" verdict, evidence-backed like every ranking.
9. **Sources** — per competitor: URL, retrieval date, confidence.

## Invocation arguments

If the skill was invoked with arguments they appear below (otherwise this section is empty aside from the placeholder):

$ARGUMENTS', '{"allowed-tools":["webSearch","webContent","http","createTable","browser-automation"],"user-invocable":true,"argument-hint":"<competitor A> vs <competitor B> [vs ...] [focus: pricing|features|security|...]"}', 'analysis', '{comparison,competitive-analysis,battle-card,vendor,research,web-search}', '{"type":"emoji","value":"⚖️"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('2b38a5e9-a92a-4594-b1c2-023a56f0407a', 'Bearing Selection & Design', 'Select, size and validate rolling bearings for an application: bearing design, selection and recommendation with L10 life, load and speed calculations, static safety, shaft fit, housing fit and lubrication guidance. Evidence-backed from the internal RD document library and manufacturer catalogues — never from memory. Use for: design a bearing, select a bearing, recommend a bearing, calculate L10 life, check bearing life, calculate bearing load, suggest shaft fit, suggest housing fit, select lubrication, high-speed bearing, heavy-load bearing.', '# Bearing Selection & Design

Select, size and validate rolling bearings for an application, directly in chat.
Covers deep groove ball (6xxx), cylindrical roller (N and NU carry no axial
load; NJ and NUP do) and taper roller (3xxxx) bearings. Every recommendation is
traceable to a retrieved catalogue value, a calculation, or a named standard.

## Step 0 — Preflight: evidence tools

This skill may not state engineering values from memory, so it needs at least
one evidence tool. Check what is available and degrade in this order:

1. `MS-SP-RD__search_documents` — the internal RD document library. Always first.
2. `rag_search` — documents engineers uploaded to a Knowledge Base.
3. `webSearch` / `webContent` — manufacturer sites, for external cross-checks.

If the SharePoint tools are missing, say so and continue with whatever remains —
a deployment whose SharePoint server is named differently still works through
`rag_search` and `webSearch`. If NO evidence tool is available at all, tell the
user to enable **Web Search** and the SharePoint server in the
composer tool picker, then stop. Never fall back to recalled values.

## Step 1 — Collect engineering inputs

Two rules that look like they conflict, resolved by one test: *would a different
answer from the engineer change the recommendation?* If yes, ask. If no, proceed
and record the assumption.

Minimum viable inputs — ask only for these, one at a time, then compute:

| Task | Required | Estimate if absent (and say so) |
|---|---|---|
| L10 life | designation or bore diameter, radial load, speed | axial load = 0; reliability 90 percent; aISO = 1 |
| Selection | bore diameter, radial load, speed | axial load = 0; 70 degrees C; reliability 90 percent |
| Static check | designation, maximum load | — |
| Shaft / housing fit | radial load, C, which ring rotates | — |
| Lubrication | speed, bore and outside diameter | — |

An axial load changes which bearing types are even valid, so never silently
assume one is present. Assuming Fa = 0 is safe only when the engineer has said
the load is purely radial or the application obviously has no thrust — say which.

Industry, duty cycle, contamination, sealing and cost target refine the answer
but must never block it. Every estimate appears under Engineering Assumptions.

## When to stop and ask the engineer

The engineer is the authority. Asking costs no tool calls and returns in under a
second — far cheaper than a full report built on a wrong premise. Ask **one
question at a time**, and make every question **specific and answerable**
("Which clearance — CN, C3 or C4?"), never open-ended ("Tell me more").

| Situation | What to do |
|---|---|
| A required input is missing | Ask for it. Do not guess the load or the speed. |
| Evidence is not in the RD folder | Ask the engineer to share the catalogue or name the folder. Do not merely report UNKNOWN and stop. |
| The designation is ambiguous | `6205` alone is under-specified: the seal variant (-2RS, -ZZ, open), the clearance (CN, C3, C4) and the manufacturer each change the ratings. Ask which — never pick one silently. |
| Sources disagree | Two documents give different C for the same bearing: present both with citations and ask which governs. **Never average** them and never silently prefer one. |
| A safety-relevant assumption is needed | Confirm before proceeding when the assumption could change the verdict — shock load treated as steady, reliability below 90 percent, temperature outside the normal range, or an application the evidence does not cover. |

Values the engineer supplies are tagged `[user-provided]` and carried into the
report''s Engineering Assumptions section.

## Step 2 — Gather evidence (parallel, RD folder first)

In a SINGLE response, issue the RD-folder searches IN PARALLEL — never one at a
time:

- `MS-SP-RD__search_documents` for the designation or bore size, for the
  application, and for the governing standard. Results carry page numbers — keep
  them, they become the citations.
- When a hit is an Excel or CSV catalogue, use `MS-SP-RD__query_document_data`
  to query the table directly (for example bore = 25 and C > 14) instead of
  reading it as prose. This is what keeps numeric selection evidence-backed
  rather than a guess about which row you saw.
- `MS-SP-RD__get_document_content` to read a specific document. If it returns no
  text layer the catalogue is a scan — fall back to
  `MS-SP-RD__get_document_page_image` and read the page as an image.
- When the engineer names a folder, path or file instead of a topic, navigate
  directly: `MS-SP-RD__list_available_sites` then
  `MS-SP-RD__list_folder_contents` to browse,
  `MS-SP-RD__get_document_by_path` to open a known path, or
  `MS-SP-RD__search_sharepoint` to find a document by filename. Do not crawl
  folders to locate a document by topic — that is what `search_documents` is for.
- `rag_search` for anything an engineer uploaded to a Knowledge Base.
- `webSearch` / `webContent` only to fill gaps the RD folder cannot, and always
  marked as a lower-confidence external source. If `webSearch` is unavailable,
  fall back to `http` against a known manufacturer URL.

Budget: at most 10 documents, hard maximum 20. Never fetch the same one twice.

## Step 3 — Extract with provenance

Tag every engineering value with where it came from. A value with no tag is a
defect:

- `[catalogue]` — a manufacturer catalogue. Record manufacturer, designation,
  document name and **page**.
- `[calculated]` — produced by the calculation block. Show the formula and inputs.
- `[standard]` — a named standard clause, e.g. ISO 281 or ISO 76.
- `[document]` — an internal RD document. Cite document name and page.
- `[user-provided]` — the engineer supplied it in this conversation.
- `[assumption]` — you estimated it. State the rationale and the engineering
  practice that permits it.
- `UNKNOWN` — not found. Never infer, estimate or invent an engineering value.

Confidence on every retrieved fact: **high** (internal approved document or the
manufacturer''s own catalogue), **medium** (manufacturer website or third-party
distributor), **low** (indirect or undated). Internal approved documents
outrank external web sources when both are available.

### Never recall a load rating

Dynamic load rating (C), static load rating (C0), speed ratings and internal
clearance are **manufacturer-specific**. They MUST come from a source retrieved
in **this conversation**.

- You may state *boundary dimensions* (bore, outside diameter, width) from
  memory ONLY when you cite ISO 15 or ISO 355 as the source — those are
  dimensional standards, identical across manufacturers.
- You may NEVER state a C or C0 value that did not appear in a
  `MS-SP-RD__search_documents`, `rag_search`, `webSearch` or `webContent`
  result in this conversation — even when you are confident you know it.
  SKF, NBC, NSK and Timken publish different ratings for the same designation;
  a recalled or blended value is a safety defect, not a rounding error.
- With no source: output `UNKNOWN`, state plainly that the calculation
  **cannot proceed** without it, and **ask the engineer** to share the catalogue
  or confirm the rating. Never substitute a remembered value to keep the answer
  flowing. Never hallucinate.

## Step 4 — Calculate

Run the block below with `mini-javascript-execution`. **Copy it verbatim** and
change only the inputs at the end — never rewrite a formula or the factor table.

```js
// ISO 281 / ISO 76 bearing calculations.
// Factor rows are ARRAYS of objects read with dot access. The sandbox blocks
// bracket lookups that use a quoted identifier key, so no keyed map here.

// ISO 281 deep groove ball: e and Y against Fa/C0.
const dgbbFactorRows = [
  { ratio: 0.025, e: 0.22, y: 2.0 },
  { ratio: 0.04, e: 0.24, y: 1.8 },
  { ratio: 0.07, e: 0.27, y: 1.6 },
  { ratio: 0.13, e: 0.31, y: 1.4 },
  { ratio: 0.25, e: 0.37, y: 1.2 },
  { ratio: 0.5, e: 0.44, y: 1.0 },
];

// ISO 281 reliability factor a1.
const a1Rows = [
  { reliability: 90, a1: 1.0 },
  { reliability: 95, a1: 0.64 },
  { reliability: 96, a1: 0.55 },
  { reliability: 97, a1: 0.47 },
  { reliability: 98, a1: 0.37 },
  { reliability: 99, a1: 0.25 },
];

// Every input is checked. A missing value throws rather than defaulting - a
// silent default becomes a wrong life figure that an engineer acts on.
function need(v, label) {
  if (typeof v !== ''number'' || !isFinite(v) || v < 0) {
    throw new Error(`${label} is required as a non-negative number - report UNKNOWN and ask for the catalogue rather than guessing`);
  }
  return v;
}

function positive(v, label) {
  need(v, label);
  if (!(v > 0)) throw new Error(`${label} must be greater than zero`);
  return v;
}

function a1For(reliability) {
  const rows = a1Rows;
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].reliability === reliability) return rows[i].a1;
  }
  throw new Error(''reliability must be 90, 95, 96, 97, 98 or 99 percent (ISO 281 a1 table)'');
}

// e and Y interpolated against Fa/C0 (ISO 281, deep groove ball).
function dgbbFactors(fa, c0) {
  positive(c0, ''C0'');
  const rows = dgbbFactorRows;
  const first = rows[0];
  const last = rows[rows.length - 1];
  const r = fa / c0;
  if (r <= first.ratio) return { e: first.e, y: first.y };
  if (r >= last.ratio) return { e: last.e, y: last.y };
  for (let i = 1; i < rows.length; i++) {
    const hi = rows[i];
    if (r <= hi.ratio) {
      const lo = rows[i - 1];
      const t = (r - lo.ratio) / (hi.ratio - lo.ratio);
      return { e: lo.e + t * (hi.e - lo.e), y: lo.y + t * (hi.y - lo.y) };
    }
  }
  return { e: last.e, y: last.y };
}

// Equivalent dynamic load P (ISO 281).
//   dgbb     deep groove ball
//   crb      cylindrical N or NU - carries NO axial load
//   crbAxial cylindrical NJ or NUP - axial capable, needs catalogue Y and e
//   trb      taper roller - needs catalogue Y and e
// catY and catE are the bearing''s OWN factors from its catalogue. Never assume.
function equivalentDynamicLoad(kind, fr, fa, c0, catY, catE) {
  need(fr, ''Fr'');
  need(fa, ''Fa'');
  if (kind === ''crb'') {
    if (fa > 0) {
      throw new Error(''N and NU cylindrical roller bearings carry no axial load - use kind crbAxial with the catalogue Y and e for NJ or NUP, or confirm the axial load is zero'');
    }
    return fr;
  }
  if (fa === 0) return fr;
  positive(fr, ''Fr'');
  if (kind === ''trb'' || kind === ''crbAxial'') {
    positive(catY, ''catalogue Y'');
    positive(catE, ''catalogue e'');
    if (fa / fr <= catE) return fr;
    const x = kind === ''trb'' ? 0.4 : 0.92;
    return x * fr + catY * fa;
  }
  const f = dgbbFactors(fa, c0);
  if (fa / fr <= f.e) return fr;
  return 0.56 * fr + f.y * fa;
}

// Equivalent static load P0 and static safety factor s0 (ISO 76).
// catY0 is the bearing''s own static axial factor, required whenever an axial
// load acts on a taper or axial-capable cylindrical roller bearing.
function staticSafety(kind, fr, fa, c0, catY0) {
  need(fr, ''Fr'');
  need(fa, ''Fa'');
  positive(c0, ''C0'');
  let p0;
  if (kind === ''dgbb'') {
    p0 = Math.max(fr, 0.6 * fr + 0.5 * fa);
  } else if (kind === ''trb'' || kind === ''crbAxial'') {
    if (fa > 0) {
      positive(catY0, ''catalogue Y0'');
      p0 = Math.max(fr, 0.5 * fr + catY0 * fa);
    } else {
      p0 = fr;
    }
  } else {
    if (fa > 0) throw new Error(''N and NU cylindrical roller bearings carry no axial load'');
    p0 = fr;
  }
  positive(p0, ''P0'');
  return { p0: p0, s0: c0 / p0 };
}

// Basic and modified rating life (ISO 281).
// Life exponent is 3 for ball bearings and 10 / 3 for roller bearings.
// reliability is a percentage from the a1 table. aIso is the life modification
// factor for contamination and viscosity - pass 1 only when it is unknown, and
// record that as an assumption.
function ratingLife(kind, c, pLoad, n, reliability, aIso) {
  positive(c, ''C'');
  positive(pLoad, ''P'');
  positive(n, ''speed'');
  const a1 = a1For(reliability);
  const aiso = (aIso === undefined || aIso === null) ? 1 : positive(aIso, ''aISO'');
  const expo = kind === ''dgbb'' ? 3 : 10 / 3;
  const l10 = Math.pow(c / pLoad, expo);
  const l10h = (l10 * 1e6) / (60 * n);
  return {
    l10: l10,
    l10h: l10h,
    lnmh: l10h * a1 * aiso,
    a1: a1,
    aIso: aiso,
    exponent: expo,
    dynamicSafety: c / pLoad,
  };
}

// Load class for fit selection. ISO 286 practice keys the tolerance off the
// P/C ratio. This CLASSIFIES the load only - the tolerance class itself must
// come from the catalogue or an ISO 286 table, never from memory.
function loadClass(pLoad, c) {
  positive(pLoad, ''P'');
  positive(c, ''C'');
  const ratio = pLoad / c;
  const name = ratio <= 0.05 ? ''light'' : (ratio <= 0.10 ? ''normal'' : ''heavy'');
  return { ratio: ratio, loadClass: name };
}

// Speed factor n * dm for lubrication selection, dm = (d + D) / 2 in mm.
// The grease or oil choice and the relubrication interval must come from the
// catalogue - this computes only the standard decision parameter.
function speedFactor(n, boreD, outsideD) {
  positive(n, ''speed'');
  positive(boreD, ''bore diameter d'');
  positive(outsideD, ''outside diameter D'');
  const dm = (boreD + outsideD) / 2;
  return { dm: dm, ndm: n * dm };
}

// --- inputs: replace with the retrieved and user-supplied values ---
const kind = ''dgbb'';     // dgbb | crb | crbAxial | trb
const C = 14.0;          // dynamic load rating, kN  [catalogue]
const C0 = 7.8;          // static load rating, kN   [catalogue]
const Fr = 4.5;          // radial load, kN
const Fa = 0.0;          // axial load, kN
const n = 1800;          // speed, rpm
const d = 25;            // bore diameter, mm      [catalogue]
const D = 52;            // outside diameter, mm   [catalogue]
const reliability = 90;  // percent, ISO 281 a1 table
const aIso = 1;          // life modification factor (1 = unknown, say so)
const catY = 0;          // catalogue Y  - required for trb and crbAxial
const catE = 0;          // catalogue e  - required for trb and crbAxial
const catY0 = 0;         // catalogue Y0 - required for axial-loaded trb/crbAxial

const P = equivalentDynamicLoad(kind, Fr, Fa, C0, catY, catE);
const life = ratingLife(kind, C, P, n, reliability, aIso);
const stat = staticSafety(kind, Fr, Fa, C0, catY0);
const fitLoad = loadClass(P, C);
const lube = speedFactor(n, d, D);
console.log({
  P_kN: P,
  L10_million_rev: life.l10,
  L10h_hours: life.l10h,
  Lnmh_hours: life.lnmh,
  a1: life.a1,
  dynamic_safety_C_over_P: life.dynamicSafety,
  P0_kN: stat.p0,
  s0: stat.s0,
  load_class: fitLoad.loadClass,
  dm_mm: lube.dm,
  speed_factor_n_dm: lube.ndm,
});
```

The block **refuses rather than defaults**. If it throws, the message names the
missing value — report that value as UNKNOWN and ask the engineer for it. Never
edit the block to work around a refusal.

Report results to 3 significant figures and restate the inputs alongside them.

State these sanity checks explicitly: s0 below 1 is static overload; L10h far
below the required life means undersized; a speed above the catalogue limiting
speed invalidates the selection regardless of life.

### Shaft and housing fits

`loadClass(P, C)` gives the load class. That class plus **which ring rotates**
determines the fit *principle*:

- Rotating inner ring under radial load — the inner ring sees a circumferential
  load, so an **interference fit on the shaft** is required.
- Stationary outer ring under radial load — point load, so a **clearance or
  transition fit** in the housing is acceptable.
- Rotating outer-ring load — **interference fit in the housing**.

Report the load class and the fit principle from this rule. Do **NOT** state a
tolerance class (k5, m6, H7, N7 and so on) unless you retrieved it from the
bearing catalogue or an ISO 286 table in this conversation — tolerance classes
depend on bearing type, size range and manufacturer practice. With no source,
give the principle, mark the class `UNKNOWN` and ask the engineer.

### Lubrication

`speedFactor(n, d, D)` returns dm and the speed factor n·dm, the standard
parameter for grease-versus-oil selection and relubrication-interval lookup.
Report n·dm, then take the grease type, base-oil viscosity and relubrication
interval **from the catalogue** — never from memory.

## Step 5 — Report (fixed structure, in this order)

1. **Executive Summary** — the recommendation and the one number that drives it.
2. **Application Review** — what the bearing has to do, in engineering terms.
3. **Engineering Assumptions** — every `[assumption]` and `[user-provided]`
   value, with rationale. If there are none, say so.
4. **Recommended Bearing** — designation, manufacturer, dimensions, C, C0,
   limiting speed, each with its provenance tag and citation.
5. **Alternative Bearings** — economy, premium, higher-speed and heavier-duty
   options where the evidence supports them; UNKNOWN where it does not.
6. **Engineering Calculations** — formula, inputs, result, standard clause.
7. **Comparison** — a table when more than one candidate survives. Use
   `createTable` when an interactive table helps, and `createBarChart` to
   compare calculated life across candidates. Comparing life is valid *here*
   because this skill has the application''s load case; it is not valid in a bare
   bearing-versus-bearing comparison.
8. **Validation** — fit, clearance, lubrication, speed and static checks; flag
   undersized, oversized, wrong type, or excessive speed.
9. **Risks** — failure modes this selection is exposed to, and under what
   conditions.
10. **Recommendations** — mounting, lubrication interval, inspection, and what to
    re-check if the duty changes.
11. **References** — every source: document name, page, retrieval date,
    confidence. Standards cited by clause.

## Format scope (critical)

This skill produces its report **in chat**. For a downloadable file, the report
text is handed to the existing document skills — do NOT substitute a format or
reimplement generation:

- **Word Document Builder** — .docx engineering reports
- **Spreadsheet Builder** — .xlsx comparison matrices and calculation sheets

If the user asks for a file and the matching skill is not installed, tell them to
install it from **Skills > Marketplace** rather than producing a different format.

For manufacturer cross-reference, equivalents and head-to-head comparison, use
the **Bearing Comparison & Equivalents** skill instead of answering here.

## Invocation arguments

If the skill was invoked with arguments they appear below (otherwise this section
is empty aside from the placeholder):

$ARGUMENTS', '{"allowed-tools":["MS-SP-RD__search_documents","MS-SP-RD__query_document_data","MS-SP-RD__get_document_content","MS-SP-RD__get_document_by_path","MS-SP-RD__get_document_page_image","MS-SP-RD__list_folder_contents","MS-SP-RD__search_sharepoint","MS-SP-RD__list_available_sites","rag_search","webSearch","webContent","http","createTable","createBarChart","mini-javascript-execution"],"user-invocable":true,"argument-hint":"<application or designation> [bore mm] [radial load kN] [axial load kN] [speed rpm]"}', 'analysis', '{bearing,mechanical-engineering,iso-281,l10-life,bearing-selection,engineering-calculation}', '{"type":"emoji","value":"⚙️"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, deployed, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, lifecycle_status, lifecycle_reviewed_by, lifecycle_reviewed_at, lifecycle_note, lifecycle_previous_status, qa_baseline_hash, created_at, updated_at, deleted_at) VALUES ('f0347531-c4ce-4295-9339-6d7bba6d91b3', 'Bearing Comparison & Equivalents', 'Compare 2–20 bearings, series or manufacturers (NBC, SKF, Timken, NSK, NTN, FAG, INA, KOYO) and find an equivalent, alternative or cross-reference replacement. Produces a comparison matrix of load ratings, speed, clearance and sealing with per-value evidence. Use for: compare bearings, bearing comparison, NBC vs SKF, suggest an equivalent bearing, cross-reference a bearing, replace bearing 6205, alternative bearing, manufacturer cross reference.', '# Bearing Comparison & Equivalents

Compare 2–20 bearings, series or manufacturers, and find equivalents and
replacements — directly in chat. Covers NBC, SKF, Timken, NSK, NTN, FAG, INA,
KOYO, Schaeffler and JTEKT. Every compared value is a retrieved value, never a
recalled one.

## Step 0 — Preflight: evidence tools

This skill may not state engineering values from memory, so it needs at least
one evidence tool. Check what is available and degrade in this order:

1. `MS-SP-RD__search_documents` — the internal RD document library. Always first.
2. `rag_search` — documents engineers uploaded to a Knowledge Base.
3. `webSearch` / `webContent` — manufacturer sites, for external cross-checks.

If the SharePoint tools are missing, say so and continue with whatever remains —
a deployment whose SharePoint server is named differently still works through
`rag_search` and `webSearch`. If NO evidence tool is available at all, tell the
user to enable **Web Search** and the SharePoint server in the
composer tool picker, then stop. Never fall back to recalled values.

## Step 1 — Resolve what is being compared

- Extract every designation, series and manufacturer named in the request and in
  the invocation arguments.
- Deduplicate case-insensitively, ignoring legal suffixes: "SKF", "skf" and
  "SKF Group" are ONE manufacturer. Note any merges in the report.
- Bounds: 2–20 items. Fewer than 2 after dedupe → ask for at least one more.
  More than 20 → compare the first 20 and say so.
- A bare designation is ambiguous. `6205` does not identify a product: the seal
  variant (-2RS, -ZZ, open), the clearance (CN, C3, C4) and the manufacturer all
  change the ratings. Ask which — never pick one silently.

## When to stop and ask the engineer

The engineer is the authority. Asking costs no tool calls and returns in under a
second — far cheaper than a full report built on a wrong premise. Ask **one
question at a time**, and make every question **specific and answerable**
("Which clearance — CN, C3 or C4?"), never open-ended ("Tell me more").

| Situation | What to do |
|---|---|
| A required input is missing | Ask for it. Do not guess the load or the speed. |
| Evidence is not in the RD folder | Ask the engineer to share the catalogue or name the folder. Do not merely report UNKNOWN and stop. |
| The designation is ambiguous | `6205` alone is under-specified: the seal variant (-2RS, -ZZ, open), the clearance (CN, C3, C4) and the manufacturer each change the ratings. Ask which — never pick one silently. |
| Sources disagree | Two documents give different C for the same bearing: present both with citations and ask which governs. **Never average** them and never silently prefer one. |
| A safety-relevant assumption is needed | Confirm before proceeding when the assumption could change the verdict — shock load treated as steady, reliability below 90 percent, temperature outside the normal range, or an application the evidence does not cover. |

Values the engineer supplies are tagged `[user-provided]` and carried into the
report''s Engineering Assumptions section.

## Step 2 — Gather evidence (parallel, RD folder first)

In a SINGLE response, issue one `MS-SP-RD__search_documents` per item IN
PARALLEL — never one at a time. Then:

- When a hit is an Excel or CSV catalogue, use `MS-SP-RD__query_document_data`
  to pull the rows directly rather than reading the table as prose.
- `MS-SP-RD__get_document_content` for a specific document;
  `MS-SP-RD__get_document_page_image` when a catalogue is a scan with no text.
- When the engineer names a folder, path or file instead of a topic, navigate
  directly: `MS-SP-RD__list_available_sites` then
  `MS-SP-RD__list_folder_contents` to browse,
  `MS-SP-RD__get_document_by_path` to open a known path, or
  `MS-SP-RD__search_sharepoint` to find a document by filename.
- `rag_search` for engineer-uploaded documents.
- `webSearch` / `webContent` for manufacturers absent from the RD folder,
  marked as lower-confidence external sources. If `webSearch` is unavailable,
  fall back to `http` against a known manufacturer URL.

Budget: 10 documents per item, hard maximum 20. Never fetch the same document
twice.

## Step 3 — Extract with provenance

Tag every engineering value with where it came from. A value with no tag is a
defect:

- `[catalogue]` — a manufacturer catalogue. Record manufacturer, designation,
  document name and **page**.
- `[calculated]` — produced by the calculation block. Show the formula and inputs.
- `[standard]` — a named standard clause, e.g. ISO 281 or ISO 76.
- `[document]` — an internal RD document. Cite document name and page.
- `[user-provided]` — the engineer supplied it in this conversation.
- `[assumption]` — you estimated it. State the rationale and the engineering
  practice that permits it.
- `UNKNOWN` — not found. Never infer, estimate or invent an engineering value.

Confidence on every retrieved fact: **high** (internal approved document or the
manufacturer''s own catalogue), **medium** (manufacturer website or third-party
distributor), **low** (indirect or undated). Internal approved documents
outrank external web sources when both are available.

### Never recall a load rating

Dynamic load rating (C), static load rating (C0), speed ratings and internal
clearance are **manufacturer-specific**. They MUST come from a source retrieved
in **this conversation**.

- You may state *boundary dimensions* (bore, outside diameter, width) from
  memory ONLY when you cite ISO 15 or ISO 355 as the source — those are
  dimensional standards, identical across manufacturers.
- You may NEVER state a C or C0 value that did not appear in a
  `MS-SP-RD__search_documents`, `rag_search`, `webSearch` or `webContent`
  result in this conversation — even when you are confident you know it.
  SKF, NBC, NSK and Timken publish different ratings for the same designation;
  a recalled or blended value is a safety defect, not a rounding error.
- With no source: output `UNKNOWN`, state plainly that the calculation
  **cannot proceed** without it, and **ask the engineer** to share the catalogue
  or confirm the rating. Never substitute a remembered value to keep the answer
  flowing. Never hallucinate.

## Step 4 — Compare on matched dimensions

Compare only like with like. Normalise before building the matrix:

| Canonical | Variants |
|---|---|
| Dynamic load rating C | Cr, C dyn, basic dynamic load rating |
| Static load rating C0 | C0r, C stat, basic static load rating |
| Limiting speed | max speed, speed limit (grease and oil quoted separately) |
| Internal clearance | radial clearance, CN / C2 / C3 / C4 |
| Sealed | 2RS, RS, DDU, 2RSR, contact seal |
| Shielded | ZZ, 2Z, Z, metal shield |

Extend the same principle to any other synonymous terms you meet — the table is
a starting dictionary, not a closed list.

For an **equivalent or replacement**, a candidate qualifies only when boundary
dimensions match exactly and load ratings, speed, clearance and sealing are
compatible. State each dimension as matched, better, worse or UNKNOWN. **Never
recommend an incompatible replacement** — if the bore, outside diameter or width
differs, say so and reject it, however close the ratings are.

Where two sources disagree on a rating, show both with citations and ask which
governs.

### Never compute bearing life here

Compare **properties of the bearing** — load ratings, speed, clearance, sealing,
dimensions. Bearing **life is not a property of a bearing**: L10 depends on the
equivalent load P, which comes from the application''s radial load, axial load and
speed. A comparison request does not carry a load case, so there is nothing to
compute from.

If the user wants a life comparison, say that it needs the application''s loads
and speed, collect them, and use the **Bearing Selection & Design** skill — which
ships a certified ISO 281 block. Never write a life formula from memory here.

## Step 5 — Report (fixed structure, in this order)

1. **Executive Summary** — the verdict in 2–5 sentences.
2. **Items Compared** — one line each; list anything Not Found explicitly rather
   than dropping it.
3. **Comparison Matrix** — one column per item, one row per normalised property,
   em dash for UNKNOWN. Use `createTable` when an interactive table helps and
   `createBarChart` for load-rating and speed comparisons.
4. **Equivalents** — matched pairs with the compatibility verdict per dimension.
5. **Strengths** and **Weaknesses** — grouped per item, evidence-backed.
6. **Recommendation** — which to choose and under what conditions; say
   explicitly when the evidence does not support a verdict.
7. **References** — document name, page, retrieval date, confidence per item.

## Format scope (critical)

This skill produces its report **in chat**. For a downloadable file, the report
text is handed to the existing document skills — do NOT substitute a format or
reimplement generation:

- **Word Document Builder** — .docx engineering reports
- **Spreadsheet Builder** — .xlsx comparison matrices and calculation sheets

If the user asks for a file and the matching skill is not installed, tell them to
install it from **Skills > Marketplace** rather than producing a different format.

For sizing a bearing from an application''s loads and speed, use the
**Bearing Selection & Design** skill instead of answering here.

## Invocation arguments

If the skill was invoked with arguments they appear below (otherwise this section
is empty aside from the placeholder):

$ARGUMENTS', '{"allowed-tools":["MS-SP-RD__search_documents","MS-SP-RD__query_document_data","MS-SP-RD__get_document_content","MS-SP-RD__get_document_by_path","MS-SP-RD__get_document_page_image","MS-SP-RD__list_folder_contents","MS-SP-RD__search_sharepoint","MS-SP-RD__list_available_sites","rag_search","webSearch","webContent","http","createTable","createBarChart"],"user-invocable":true,"argument-hint":"<bearing A> vs <bearing B> [vs ...] | equivalent for <designation>"}', 'analysis', '{bearing,comparison,equivalent,cross-reference,mechanical-engineering,replacement}', '{"type":"emoji","value":"🔩"}', '862152ec-20d6-4bc9-84b8-47d695c142bd', NULL, 'public', '1.0.0', 0, true, true, 'approved', 'personal', NULL, NULL, NULL, 'approved', NULL, NULL, NULL, NULL, NULL, '2026-08-10 16:53:31.973172', '2026-08-10 16:53:31.973172', NULL);


--
-- Data for Name: skill_attestation; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_qa_run; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_qa_certification; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_qa_check_result; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_qa_recording; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_rating; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_scan; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_submission; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: team_invite; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: team_member; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: team_model_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: thread_attachment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: token_usage; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tool_usage; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: trusted_device; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: two_factor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_label_assignment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_mcp_access; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_model_access; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_rate_limits; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_token_quota; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_tool_permission; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: web_vitals_log; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: webhook; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: webhook_delivery; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_comment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_edge; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('5f72cc4a-73f0-408c-bdfa-f08338981ab3', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '2de4a287-b264-40a4-8f26-cf93ef706212', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '{"sourceHandle":"right","targetHandle":"left"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('47d7d107-c9e3-4aeb-be85-98876f3384a8', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '9b3978cb-9369-4c1f-9cc4-f8d5c9f7f184', 'e70fd679-8809-4d94-bbe6-7e8a0f615aa1', '{"sourceHandle":"right","targetHandle":"left"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('ca755f9a-2263-4cd7-9085-3b603b0d421c', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '845b5e8c-8987-4777-a3d2-a3fcee2af853', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('b424dc21-c05b-4ce8-bf27-1cc415e6d880', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'f9bf6172-a399-4669-b794-24b76a2be91e', 'e218530f-2628-4e85-91b6-50b7e8276ac3', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('6a05d82b-0458-4d86-804d-7c66df050dab', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '1f9deeb3-0313-42b4-a088-27c7915c353d', 'f9bf6172-a399-4669-b794-24b76a2be91e', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('8be66ee6-b83b-4bd9-8777-4737d373d5e2', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '61a7db5f-e578-4877-8e24-bc0f811c764e', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '{"sourceHandle":"if","targetHandle":"left"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('c54a22a9-da7c-4483-a1e2-62ccfea541ce', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'e218530f-2628-4e85-91b6-50b7e8276ac3', '2de4a287-b264-40a4-8f26-cf93ef706212', '{"sourceHandle":"if"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('b980b8ea-6974-4dec-ac0b-70ee02e6c0b8', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '61a7db5f-e578-4877-8e24-bc0f811c764e', '1c2dfa94-348b-4707-a4f2-afd133842cd5', '{"sourceHandle":"else","targetHandle":"left"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('6246e408-9178-4935-bd2e-6e17ea7183cb', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '845b5e8c-8987-4777-a3d2-a3fcee2af853', 'e70fd679-8809-4d94-bbe6-7e8a0f615aa1', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('74e6d59e-7dac-45eb-ad87-3e8d5c9bfeb2', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'afd7ebfc-ceec-4d1f-a774-60f126402e4d', '1f9deeb3-0313-42b4-a088-27c7915c353d', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('81d85e73-2565-45a7-9281-57990207caaa', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', '1c2dfa94-348b-4707-a4f2-afd133842cd5', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('d1402e19-31e4-4c86-bbea-2e9570ce8180', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'e218530f-2628-4e85-91b6-50b7e8276ac3', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '{"sourceHandle":"else","targetHandle":"left"}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('579521d1-5a66-423a-ad87-235d71b82b9a', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'f9bf6172-a399-4669-b794-24b76a2be91e', '61a7db5f-e578-4877-8e24-bc0f811c764e', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('63809d04-85a0-4933-b746-e868b065a53e', '0.1.0', 'f77c78e7-767d-4180-9731-56aff36e7420', 'd23e2812-8149-4241-bcf3-18fb99e8c98c', '9b3978cb-9369-4c1f-9cc4-f8d5c9f7f184', '{}', '2026-08-10 16:53:30.794742');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('a629dc02-e393-4a8c-bea2-3493ae29c43f', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'dae073e9-c5d1-4647-b967-4e0d2fd8c55f', '8d9de973-2988-44ab-a41c-bef94e240cce', '{}', '2026-08-10 16:53:30.807872');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('52aad188-92cd-426f-a519-f8ff2eae6385', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', '8d9de973-2988-44ab-a41c-bef94e240cce', 'd7a672ab-9879-4a39-830b-9a872390e8d9', '{}', '2026-08-10 16:53:30.807872');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('7779480c-fe02-4758-95f7-cbbc091e0914', '0.1.0', '5b9f0aeb-80ef-4c8f-94a2-1f9281f74d57', 'd7a672ab-9879-4a39-830b-9a872390e8d9', '24d332fd-d750-4adb-a961-4880088ce0fa', '{}', '2026-08-10 16:53:30.807872');


--
-- Data for Name: workflow_group; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: workflow_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: __drizzle_migrations_id_seq; Type: SEQUENCE SET; Schema: drizzle; Owner: -
--

SELECT pg_catalog.setval('drizzle.__drizzle_migrations_id_seq', 9, true);


--
-- PostgreSQL database dump complete
--

\unrestrict ncf41RhGwXGca8dLOysKjefiTiopriHNDGSocO4zgEewDhPs0Psugxe0D9gd8kd


SET session_replication_role = DEFAULT;
