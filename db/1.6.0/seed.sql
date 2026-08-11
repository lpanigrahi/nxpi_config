-- NXPi reference seed data. Apply as a SUPERUSER, AFTER schema.sql + grants.sql.
--   psql -v admin_email="admin@you.example" -v admin_password_hash="<hash>" -f seed.sql
-- The hash is produced per-deploy by the nxpi-hash helper (Better Auth scrypt).
-- FK checks are deferred during the bulk load (superuser-only).
SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

\restrict gAVnAFMcNsChRKsaH3nJ4IGh9Y95gsuyAXVlDbeJV1ALtyyjfOuv15B4jlTqWw0

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

INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'Super Admin''s Workspace', 'personal-8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'free', 'active', '2026-07-27 12:50:28.884684', '2026-07-27 12:50:28.884684');
INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('d9c54dbe-b06d-46b6-a499-757a86c3abcc', 'Default Organization', 'default', NULL, 'free', 'active', '2026-07-27 12:50:28.964342', '2026-07-27 12:50:28.964342');


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (id, name, email, email_verified, password, image, preferences, created_at, updated_at, banned, ban_reason, ban_expires, role, two_factor_enabled, two_factor_secret, two_factor_backup_codes) VALUES ('8d14138b-3c50-41a7-a5ac-5714b8a37daf', 'Super Admin', :'admin_email', false, NULL, NULL, '{}', '2026-07-27 12:50:26.569', '2026-07-27 12:50:26.569', false, NULL, NULL, 'admin', false, NULL, NULL);


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

INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('4e83579e-67ab-49c0-a6f9-15af86cf927d', '0.1.0', 'baby-research', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/1f468-1f3fb-200d-1f52c.png","style":{"backgroundColor":"oklch(78.5% 0.115 274.713)"}}', 'Comprehensive web research workflow that performs multi-layered search and content analysis to generate detailed research reports based on user instructions and research objectives.', true, 'private', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 0, NULL, '2026-07-27 12:50:28.844416', '2026-07-27 12:50:28.844416', NULL);
INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('589071dc-4ea0-4116-b467-ad527c91d27e', '0.1.0', 'Get Weather', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/26c8-fe0f.png","style":{"backgroundColor":"oklch(20.5% 0 0)"}}', 'Get weather data from the API', true, 'private', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 0, NULL, '2026-07-27 12:50:28.867181', '2026-07-27 12:50:28.867181', NULL);


--
-- Data for Name: orchestration_run; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: a2a_task; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.account (id, account_id, provider_id, user_id, access_token, refresh_token, id_token, access_token_expires_at, refresh_token_expires_at, scope, password, created_at, updated_at) VALUES ('52d7f0a7-2230-4f48-8a19-738a1ee1b783', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', 'credential', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, NULL, NULL, NULL, NULL, NULL, :'admin_password_hash', '2026-07-27 12:50:28.953', '2026-07-27 12:50:28.953');


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

INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_response_enabled', 'false', NULL, '2026-07-27 12:50:29.006967');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_provider_prompt_enabled', 'false', NULL, '2026-07-27 12:50:29.008771');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_semantic_enabled', 'false', NULL, '2026-07-27 12:50:29.009999');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('cache_retrieval_enabled', 'false', NULL, '2026-07-27 12:50:29.010945');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('bash_execution_enabled', 'false', NULL, '2026-07-27 12:50:29.011848');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('signup_enabled', 'true', NULL, '2026-07-27 12:50:29.012788');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('temporary_chat_enabled', 'true', NULL, '2026-07-27 12:50:29.015083');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('platform_mfa_required', 'false', NULL, '2026-07-27 12:50:29.017249');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_core_v2', 'false', NULL, '2026-07-27 12:50:29.018547');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_runtime_v2', 'false', NULL, '2026-07-27 12:50:29.019737');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('agent_marketplace_enabled', 'true', NULL, '2026-07-27 12:50:29.020769');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('memory_context_v2', 'false', NULL, '2026-07-27 12:50:29.022084');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('skills_routing_v2', 'false', NULL, '2026-07-27 12:50:29.023438');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('commands_v1', 'false', NULL, '2026-07-27 12:50:29.02455');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('github_connector_v1', 'false', NULL, '2026-07-27 12:50:29.025562');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('personal_workspace_enabled', 'false', NULL, '2026-07-27 12:50:29.027058');


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
-- Data for Name: org_role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-07-27 12:50:28.889407', '2026-07-27 12:50:28.889407');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-07-27 12:50:28.898815', '2026-07-27 12:50:28.898815');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, assistants, and models.', true, 'caf3463b-1f5e-46fd-9f12-8d980a7e8113', NULL, '2026-07-27 12:50:28.891168', '2026-07-27 12:50:28.904');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('a8aca324-6bbe-45d3-99cb-14958efb7e27', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, 'caf3463b-1f5e-46fd-9f12-8d980a7e8113', NULL, '2026-07-27 12:50:28.892102', '2026-07-27 12:50:28.908');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, 'caf3463b-1f5e-46fd-9f12-8d980a7e8113', NULL, '2026-07-27 12:50:28.893166', '2026-07-27 12:50:28.91');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('431fc38a-90fc-4bb7-821f-a7dfae983dcb', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, 'caf3463b-1f5e-46fd-9f12-8d980a7e8113', NULL, '2026-07-27 12:50:28.894538', '2026-07-27 12:50:28.912');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('72437031-e4e9-4821-8792-520586c164e2', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, 'caf3463b-1f5e-46fd-9f12-8d980a7e8113', NULL, '2026-07-27 12:50:28.896223', '2026-07-27 12:50:28.914');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, '9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', NULL, '2026-07-27 12:50:28.897593', '2026-07-27 12:50:28.916');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-07-27 12:50:28.969055', '2026-07-27 12:50:28.969055');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-07-27 12:50:28.9771', '2026-07-27 12:50:28.9771');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, assistants, and models.', true, 'f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', NULL, '2026-07-27 12:50:28.970502', '2026-07-27 12:50:28.981');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('5bddab42-b33f-4130-905c-039cfa466c17', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, 'f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', NULL, '2026-07-27 12:50:28.971412', '2026-07-27 12:50:28.984');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, 'f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', NULL, '2026-07-27 12:50:28.972556', '2026-07-27 12:50:28.987');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('be2f674c-8001-4050-97c5-ed656eae7ea0', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, 'f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', NULL, '2026-07-27 12:50:28.973589', '2026-07-27 12:50:28.989');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('6da2602d-add2-448f-b25c-8370fe84dc08', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, 'f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', NULL, '2026-07-27 12:50:28.974968', '2026-07-27 12:50:28.991');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, '990ce9dc-779c-44b9-bdb5-9bad765ef45b', NULL, '2026-07-27 12:50:28.976182', '2026-07-27 12:50:28.993');


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

INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('4ba94ecf-3411-4373-a9fb-93d4df3ea13c', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'tool', 'INITIAL_SEARCH', 'Perform initial web search based on user query and parameters', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Based on the following research instruction, perform a comprehensive web search:"},{"type":"hardBreak"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Research Instruction**: "},{"type":"mention","attrs":{"id":"20075100-6d14-42ea-ac7a-a2732d54cacf","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Topic Area**: "},{"type":"mention","attrs":{"id":"e279fc2c-43c3-441d-bb5d-2d084a74bd63","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- Search Strategy:"}]}]}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Extract key concepts and themes from the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Identify multiple search angles and perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Use diverse keywords and search terms"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Focus on finding authoritative and comprehensive sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Include recent developments and established knowledge"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. Cast a wide net to ensure comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  Important: Don''t limit yourself to obvious keywords. Consider:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Technical terminology and industry jargon"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Alternative names and concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Related fields and cross-industry applications"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Recent trends and developments"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Expert opinions and case studies"}]},{"type":"paragraph","content":[{"type":"text","text":"  Return maximum 15 diverse, high-quality results."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('0d6f147c-4e3e-427e-8b0c-7ce4c301d747', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'condition', 'URL_CONDITION', '', '{"position":{"x":1092.720830684793,"y":-109.56839983927273},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488","path":["answer","important_url"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_not_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('580e94e3-5d5a-41f0-a5cc-b717cb584c7e', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'tool', 'CONTENT_EXTRACTION', 'Extract detailed content from important URL', '{"position":{"x":1426.344044454295,"y":-203.77120780533727},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"url : "},{"type":"mention","attrs":{"id":"9bd55c87-9eac-4af2-968f-c83b93577639","label":"{\"nodeId\":\"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488\",\"path\":[\"answer\",\"important_url\"]}"}}]}]},"tool":{"type":"app-tool","id":"webContent","description":"A detailed web content extraction tool that analyzes and summarizes specific web pages from provided URLs. Extracts full content, processes it intelligently, and provides comprehensive summaries. Perfect for in-depth analysis of specific articles, documents, or web pages.","parameterSchema":{"type":"object","properties":{"urls":{"type":"array","items":{"type":"string"},"description":"List of URLs to extract content from"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each URL","default":3000,"minimum":100,"maximum":10000},"livecrawl":{"type":"string","enum":["always","fallback","preferred"],"description":"Live crawling preference - always forces live crawl, fallback uses cache first, preferred tries live first","default":"preferred"}},"required":["urls"]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('39d3e42d-b612-4d39-a68b-9ace86463ddb', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'llm', 'SUMMARY', 'Synthesize all information into comprehensive research report', '{"position":{"x":1912.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"title":{"type":"string","description":"Clear, descriptive title for the research report"},"summary":{"type":"string","description":"Executive summary in 4-6 sentences"},"content":{"type":"string","description":"Comprehensive analysis in markdown format with source citations"},"diagram":{"type":"string","description":"Mermaid diagram code if beneficial (empty string if not needed)"},"key_insights":{"type":"array","items":{"type":"string"},"description":"3-5 most important insights from the research"},"confidence_level":{"type":"number","description":"Confidence score 1-10 based on source quality and coverage"},"sources_used":{"type":"array","items":{"type":"object","properties":{"title":{"type":"string"},"url":{"type":"string"},"type":{"type":"string"}}},"description":"List of all sources referenced in the content"},"images":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string"},"description":{"type":"string"},"context":{"type":"string"}}},"description":"List of relevant images extracted from search results"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report based on all collected information."}]},{"type":"paragraph","content":[{"type":"text","text":"  Research Instruction: "},{"type":"mention","attrs":{"id":"32c8abfa-f993-4c29-906a-d1c26f36711e","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"research_instruction\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c20376fa-66ec-45ce-bbef-a4f8d793e110","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"topic\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Output Language: "},{"type":"mention","attrs":{"id":"87a8619d-b077-48de-8351-1cb5bdf6cc59","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"language\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Information Sources:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Initial Search: "},{"type":"mention","attrs":{"id":"53de2392-4c38-4d56-a8bf-d1b64892a348","label":"{\"nodeId\":\"4ba94ecf-3411-4373-a9fb-93d4df3ea13c\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Analysis: "},{"type":"mention","attrs":{"id":"7447143a-9154-49e8-b3bb-bff946398903","label":"{\"nodeId\":\"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488\",\"path\":[\"answer\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"  - Detailed Content: "},{"type":"mention","attrs":{"id":"2769be0e-9631-4562-9ccc-2026d7aca616","label":"{\"nodeId\":\"580e94e3-5d5a-41f0-a5cc-b717cb584c7e\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Additional Search: "},{"type":"mention","attrs":{"id":"9ebfa7ad-341d-4db5-a88b-1d772fa97edd","label":"{\"nodeId\":\"a3172be5-7943-4cb7-b682-ef2af54e8c28\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Generate a structured report that directly addresses the research instruction:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. "},{"type":"text","marks":[{"type":"bold"}],"text":"title"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Clear, descriptive title that reflects the research focus"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should align with the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Executive summary in 4-6 sentences"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Directly answer the key questions in the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Highlight major findings and implications"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"content"},{"type":"text","text":" (string - markdown format):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Comprehensive analysis organized logically"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Structure based on the research instruction requirements"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Include: key findings, evidence, analysis, implications, recommendations"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Use proper markdown formatting with headers, lists, emphasis"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Important Content Guidelines:"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Images"},{"type":"text","text":": If images are available in the search results, include relevant ones using markdown image syntax: `![Image description](image_url)`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Sources"},{"type":"text","text":": Always cite sources when referencing specific information using format: `[Source Title](URL)` or `According to [Source Title](URL), ...`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Data and Statistics"},{"type":"text","text":": When presenting data, always include the source"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Quotes"},{"type":"text","text":": Use blockquotes for important quotes with attribution"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Evidence"},{"type":"text","text":": Support claims with specific evidence from the sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Structure Example:"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```markdown"}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Introduction"}]},{"type":"paragraph","content":[{"type":"text","text":"     Brief overview with context"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Key Findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 1 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 2 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Visual Evidence"}]},{"type":"paragraph","content":[{"type":"text","text":"     ![Chart showing trend](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"italic"}],"text":"Source: [Report Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Detailed Analysis"}]},{"type":"paragraph","content":[{"type":"text","text":"     In-depth analysis with multiple source citations"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Implications"}]},{"type":"paragraph","content":[{"type":"text","text":"     What this means for the research question"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"diagram"},{"type":"text","text":" (string - Mermaid code):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Create visualization if it helps explain findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Examples: process flows, relationships, timelines, comparisons"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Only include if it adds significant value"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. "},{"type":"text","marks":[{"type":"bold"}],"text":"key_insights"},{"type":"text","text":" (array of strings):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - 3-5 most important insights from the research"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should directly relate to the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. "},{"type":"text","marks":[{"type":"bold"}],"text":"confidence_level"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate confidence in findings based on source quality and coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  7. "},{"type":"text","marks":[{"type":"bold"}],"text":"sources_used"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - List all sources referenced in the content"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Format: {\"title\": \"Source Title\", \"url\": \"URL\", \"type\": \"article/report/study\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"  Write in [INITIAL_SEARCH.output_language]. Ensure the report:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Fully addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Includes relevant images where they add value"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Properly cites all sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Provides actionable insights"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Maintains professional formatting"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"8. "},{"type":"text","marks":[{"type":"bold"}],"text":"images"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Extract at least 3 relevant images"},{"type":"text","text":" from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Format: {\"url\": \"image_url\", \"description\": \"descriptive caption\", \"context\": \"how this image relates to the research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Select images that support key findings or illustrate important concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse image types: charts, diagrams, photos, infographics"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize images that enhance understanding of the research topic"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('3f24c2d5-c299-42a8-8aec-2b7703117604', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'condition', 'SEARCH_CONDITION', '', '{"position":{"x":1096.3175798437799,"y":108.80530614989887},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488","path":["answer","additional_search_instruction"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('a3172be5-7943-4cb7-b682-ef2af54e8c28', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'tool', 'ADDITIONAL_SEARCH', 'Perform supplementary search based on specific instruction', '{"position":{"x":1439.3610744098883,"y":257.6457427362809},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Perform targeted search based on this specific instruction: "},{"type":"mention","attrs":{"id":"dc2caf22-632d-4388-bf9c-7c8626a24c65","label":"{\"nodeId\":\"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488\",\"path\":[\"answer\",\"additional_search_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"Research Context: "},{"type":"mention","attrs":{"id":"6ab2e17b-1e04-4065-97d4-627de934b88d","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c8de8dcf-0218-4b31-8552-b1f5d0ab8ad3","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"text","text":"  Search Strategy:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Follow the specific search instruction precisely"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Focus on filling the identified information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Look for recent developments and expert perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Include diverse viewpoints and comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Prioritize sources that add new insights to the research"}]},{"type":"paragraph","content":[{"type":"text","text":"  Target 8-10 high-quality results that provide unique value."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('048fd5b4-fdb2-4a38-a975-1fabecc72aeb', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'output', 'OUTPUT', '', '{"position":{"x":2632.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"research_findings","source":{"nodeId":"39d3e42d-b612-4d39-a68b-9ace86463ddb","path":["answer"]}},{"key":"organized_data","source":{"nodeId":"2c086c8f-e7e8-43d6-afc2-736cbcf795c3","path":["answer"]}},{"key":"message_response_guide","source":{"nodeId":"971cbea9-159b-454d-bda8-1ea5c59910cb","path":["template"]}},{"key":"images","source":{"nodeId":"39d3e42d-b612-4d39-a68b-9ace86463ddb","path":["answer","images"]}}]}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('2c086c8f-e7e8-43d6-afc2-736cbcf795c3', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'llm', 'ORGANIZATION', 'Organize and summarize all collected information for report generation', '{"position":{"x":2272.4044439691656,"y":91.44758151102624},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"string"},"totalTokens":{"type":"number"}}},"messages":[{"role":"system","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"You are a research information organizer. Your task is to systematically organize and summarize all collected research information into a comprehensive, well-structured format that will be used for report generation."}]},{"type":"paragraph","content":[{"type":"text","text":"Your response should include:"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH OVERVIEW"}]},{"type":"paragraph","content":[{"type":"text","text":"[Summarize the research instruction and approach]"}]},{"type":"paragraph","content":[{"type":"text","text":"## KEY SOURCES IDENTIFIED"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all important sources with titles and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 1](URL1) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 2](URL2) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 3](URL3) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"## AVAILABLE IMAGES"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all images found with descriptions and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 1](image_url1) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 2](image_url2) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 3](image_url3) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"## MAIN FINDINGS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Organized key findings with source attributions]"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 1 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 2 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 3 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"## DETAILED CONTENT SUMMARY"}]},{"type":"paragraph","content":[{"type":"text","text":"[Comprehensive summary of all extracted content]"}]},{"type":"paragraph","content":[{"type":"text","text":"## STATISTICAL DATA"}]},{"type":"paragraph","content":[{"type":"text","text":"[Any numbers, statistics, or quantitative data found]"}]},{"type":"paragraph","content":[{"type":"text","text":"## EXPERT OPINIONS/QUOTES"}]},{"type":"paragraph","content":[{"type":"text","text":"[Important quotes or expert perspectives]"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH GAPS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Areas where information might be incomplete]"}]},{"type":"paragraph","content":[{"type":"text","text":"Make this comprehensive and well-organized for easy reference in report generation."}]}]}},{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"4a3380c5-0b39-43a8-906e-f0a38ca41539","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"1de3a234-9029-4914-8086-ba9789e2a017","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Initial Search Results: "},{"type":"mention","attrs":{"id":"2ea9f224-5806-408a-a538-c61313a6f0af","label":"{\"nodeId\":\"4ba94ecf-3411-4373-a9fb-93d4df3ea13c\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Analysis Summary: "},{"type":"mention","attrs":{"id":"a0c436b7-6300-4d1f-a0e6-1316c1c8cdc7","label":"{\"nodeId\":\"fcc24d1c-8a39-4fe8-82f1-4e363c1f0488\",\"path\":[\"answer\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Detailed Content: "},{"type":"mention","attrs":{"id":"10bf3fbf-2421-4d94-bc64-30e96ef28168","label":"{\"nodeId\":\"580e94e3-5d5a-41f0-a5cc-b717cb584c7e\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Additional Search:  "},{"type":"mention","attrs":{"id":"2e50dd84-1d6a-4680-92ae-b3d78045b713","label":"{\"nodeId\":\"a3172be5-7943-4cb7-b682-ef2af54e8c28\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Please organize all this information according to the format specified in the system prompt."}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('971cbea9-159b-454d-bda8-1ea5c59910cb', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'template', 'REPORT_GUIDE', '', '{"position":{"x":2270.033917728336,"y":-27.217682321506935},"type":"default"}', '{"kind":"template","outputSchema":{"type":"object","properties":{"template":{"type":"string"}}},"template":{"type":"tiptap","tiptap":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report using the research findings. Guidelines:"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present the complete content directly without code blocks or formatting wrapper"}]},{"type":"paragraph","content":[{"type":"text","text":"- Do not add introductory remarks like \"Here''s the report\" or \"Report completed\""}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the title, summary, and complete content from findings"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MANDATORY REQUIREMENTS:"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include at least 3 relevant images"},{"type":"text","text":" using ![Description](image_url) format throughout the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include the mermaid diagram"},{"type":"text","text":" from research_findings using \\`\\`\\`mermaid format within the content flow"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST cite every source with URLs"},{"type":"text","text":" - format: [Source Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include source URLs"},{"type":"text","text":" for all data, statistics, and factual information"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"IMAGE USAGE:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Extract images from organized_data or research_findings content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place images strategically to support key points"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use format: ![Descriptive caption](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include image source attribution when possible"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MERMAID DIAGRAM:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the diagram from research_findings.diagram"}]},{"type":"paragraph","content":[{"type":"text","text":"- Format: \\`\\`\\`mermaid [diagram_code] \\`\\`\\`"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place within relevant content section, not as separate section"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure diagram enhances understanding of the topic"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"CONTENT STRUCTURE:"}]},{"type":"paragraph","content":[{"type":"text","text":"# [research_findings.title]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"[Include executive summary, key insights, detailed analysis with images and diagrams integrated naturally]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"Confidence Level:"},{"type":"text","text":" [research_findings.confidence_level]/10"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include confidence level and key insights naturally within the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure all sources are properly cited throughout"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present as a professional research report ready for the user"}]}]}}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('fcc24d1c-8a39-4fe8-82f1-4e363c1f0488', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'llm', 'ANALYSIS', 'Analyze search results and determine research strategy', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"reference_sources":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string","description":"Source URL"},"summary":{"type":"string","description":"Brief summary of the source content and relevance"}}},"description":"List of key reference sources from search results"},"important_url":{"type":"string","description":"Single most important URL for detailed content extraction"},"additional_search_instruction":{"type":"string","description":"Specific instruction for additional search to fill information gaps (empty string if none needed)"},"analysis_summary":{"type":"string","description":"Assessment of current research state and strategy"},"research_completeness":{"type":"number","description":"Score 1-10 rating how well initial search addresses research instruction"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Analyze the search results in the context of the research instruction and determine the next steps."},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"23b93374-40fe-4397-8375-3ee3eacee22a","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"fa4b502f-3b13-4717-b4ae-675961527f20","label":"{\"nodeId\":\"40226534-a12a-4309-8c6b-f315f9236357\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Search Results: "},{"type":"mention","attrs":{"id":"88493890-21ba-476a-a7c0-b6dd70a1d480","label":"{\"nodeId\":\"4ba94ecf-3411-4373-a9fb-93d4df3ea13c\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"1. "},{"type":"text","marks":[{"type":"bold"}],"text":"important_url"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"YOU MUST SELECT AT LEAST ONE URL"},{"type":"text","text":" unless search results are completely irrelevant"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Choose the URL with the most comprehensive, authoritative information"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize: research papers, detailed reports, expert analyses, case studies, official websites"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Even if quality is moderate, select the BEST available option for detailed extraction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Only return empty string \"\" if absolutely no URLs provide any additional value"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Default behavior: ALWAYS select the most valuable URL from available results"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"additional_search_instruction"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Specific instruction for additional search to fill information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should be a clear directive like \"Find recent statistics on AI adoption in hospitals\" or \"Search for regulatory challenges in healthcare AI implementation\""}]},{"type":"paragraph","content":[{"type":"text","text":"     - Based on what''s missing from initial search relative to research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Return empty string \"\" if initial search provides sufficient coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"analysis_summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Assessment of how well current results address the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Identification of information gaps and missing perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Quality and credibility evaluation of found sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Strategy for completing the research objective"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"research_completeness"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate how well the initial search addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Consider coverage, depth, and relevance to stated objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  Be strategic and selective. Focus on what''s truly needed to address the research instruction."},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"5. "},{"type":"text","marks":[{"type":"bold"}],"text":"reference_sources"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Extract 5-8 key reference sources from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - For each source provide: {\"url\": \"full_url\", \"summary\": \"brief description of content and relevance to research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse source types: official reports, news articles, academic papers, expert analyses"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Focus on sources that directly support the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize credible, authoritative sources"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('40226534-a12a-4309-8c6b-f315f9236357', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'input', 'INPUT', '', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"topic":{"type":"string","description":"Subject area or domain (e.g., ''technology'', ''healthcare'', ''finance'', ''education'')"},"language":{"type":"string","description":"Preferred language for sources. eg. en (English), ko (Korean)"},"research_instruction":{"type":"string","default":"Comprehensive research instruction including what to research, why, and how to approach it. Example: ''Research the current state of AI in healthcare, focusing on diagnostic applications, regulatory challenges, and market adoption rates. I need this for a business proposal targeting hospital administrators.''"}},"required":["research_instruction"]}}', '2026-07-27 12:50:28.859946', '2026-07-27 12:50:28.859946');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('7d9dd438-8584-405f-8a00-ce794619bdbd', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'input', 'INPUT', 'Collect story requirements and preferences from user', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"region":{"type":"string"}},"required":["region"]}}', '2026-07-27 12:50:28.869307', '2026-07-27 12:50:28.869307');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('ef11ef4a-4932-44a4-9083-b3701734542f', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'http', 'WEATHER API', 'Get weather data from the API', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"http","outputSchema":{"type":"object","properties":{"response":{"type":"object","properties":{"status":{"type":"number"},"statusText":{"type":"string"},"ok":{"type":"boolean"},"headers":{"type":"object"},"body":{"type":"string"},"duration":{"type":"number"},"size":{"type":"number"}}}}},"method":"GET","headers":[],"query":[{"key":"current","value":"temperature_2m"},{"key":"hourly","value":"temperature_2m"},{"key":"timezone","value":"auto"},{"key":"daily","value":"sunrise,sunset"},{"key":"latitude","value":{"nodeId":"4a812129-6e21-4b99-aced-e9c5cdc02be6","path":["answer","latitude"]}},{"key":"longitude","value":{"nodeId":"4a812129-6e21-4b99-aced-e9c5cdc02be6","path":["answer","longitude"]}}],"timeout":30000,"url":"https://api.open-meteo.com/v1/forecast"}', '2026-07-27 12:50:28.869307', '2026-07-27 12:50:28.869307');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('4a812129-6e21-4b99-aced-e9c5cdc02be6', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'llm', 'LLM', 'Get latitude and longitude from the LLM', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"latitude":{"type":"number","description":"Geographical latitude of the location"},"longitude":{"type":"number","description":"Geographical longitude of the location"}}}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"What are the latitude and longitude of "},{"type":"mention","attrs":{"id":"e8d2314a-f81b-41e3-91ff-f235486a62f3","label":"{\"nodeId\":\"7d9dd438-8584-405f-8a00-ce794619bdbd\",\"path\":[\"region\"]}"}}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-27 12:50:28.869307', '2026-07-27 12:50:28.869307');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('e067a262-cc2e-4c60-9595-929f2fc74770', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'note', 'NOTE', '# 🌦️ Regional Weather Lookup Workflow

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
', '{"position":{"x":-569.8790292584229,"y":-731.5434457770423},"type":"default"}', '{"kind":"note","outputSchema":{"type":"object","properties":{}}}', '2026-07-27 12:50:28.869307', '2026-07-27 12:50:28.869307');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('3a95964c-7c6c-47bb-b7fe-7d8f8072c41f', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'output', 'OUTPUT', 'Output the weather data', '{"position":{"x":1080,"y":0},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"result","source":{"nodeId":"ef11ef4a-4932-44a4-9083-b3701734542f","path":["response","body"]}}]}', '2026-07-27 12:50:28.869307', '2026-07-27 12:50:28.869307');


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

INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('254e6ba8-3fe9-4f40-ae10-57eb2fb7eee9', 'global', NULL, 'team-manager', 'admin.auditLog', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.033249');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('21942cdb-4ce9-450d-960b-7f542a71e2d8', 'global', NULL, 'team-manager', 'admin.featureFlags', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.034638');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b1541942-6ac8-4744-bfde-10e95c02545a', 'global', NULL, 'team-manager', 'admin.identity', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.035589');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('eb3d22e1-6e24-4c7b-86e7-924f4a35ffce', 'global', NULL, 'team-manager', 'admin.models', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.036618');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d50a156a-a26d-4e4d-a35d-e8ab6b516866', 'global', NULL, 'team-manager', 'admin.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.037417');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('aa140ad4-1a3c-4277-b65b-bde0754efb1f', 'global', NULL, 'team-manager', 'admin.organizations', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.038155');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('79d068e2-75ef-4ea5-9ba9-8e140152147e', 'global', NULL, 'team-manager', 'admin.platformSettings', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.039456');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('800654d7-8452-438f-b22b-f0fc68005c36', 'global', NULL, 'team-manager', 'admin.security', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.040999');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('4cec0964-2bc9-4c93-a7ff-332fba2a4e88', 'global', NULL, 'team-manager', 'admin.subscriptions', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.042312');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('dc447741-eba6-4355-b3ff-2395f0b38a8f', 'global', NULL, 'team-manager', 'admin.users', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.043491');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('38b4d29d-b062-4039-989d-287a6ca9c6be', 'global', NULL, 'team-manager', 'nav.rag', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.04466');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('f2e40c6f-a5f4-4c02-a2fb-f6192d3411ab', 'global', NULL, 'team-manager', 'org.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.045567');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('bcc20d1f-087c-4b6c-8049-35d1972e4b8f', 'global', NULL, 'team-manager', 'org.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.046525');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b1baa00c-4688-48b9-8cfb-f43b5c8023b1', 'global', NULL, 'team-manager', 'team.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.047667');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('5c8be5f7-1ba1-44f7-b22c-d011e2c6ce6d', 'global', NULL, 'team-manager', 'workspace.mcp', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.048599');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1b9c62b7-f89b-425f-862d-ba76ce1ed6cc', 'global', NULL, 'team-manager', 'workspace.promptTemplates', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.049519');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('356babc1-6f45-47fb-af7b-649ba56d9960', 'global', NULL, 'user', 'admin.auditLog', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.050218');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('6f592c2a-d422-491c-800d-263adc9d294e', 'global', NULL, 'user', 'admin.featureFlags', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.050951');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('4d1dc65a-0e1b-4173-b0ce-541ba718cd4f', 'global', NULL, 'user', 'admin.identity', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.051743');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('7a42e36b-6900-449d-886b-b9d160d6424c', 'global', NULL, 'user', 'admin.models', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.052482');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('93093bfa-4c07-4f57-af0f-fe6099a2847c', 'global', NULL, 'user', 'admin.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.053583');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('a6609e7d-8041-44dd-8604-4005dd6c7a20', 'global', NULL, 'user', 'admin.organizations', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.054791');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('f11ecd6b-b578-4fa2-9c24-4ff8ea2a8f4a', 'global', NULL, 'user', 'admin.platformSettings', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.055856');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('73961e3d-a031-47bf-93f0-23c9320d987a', 'global', NULL, 'user', 'admin.security', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.056739');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('9468001e-ba42-42a6-86a6-afe376872d7d', 'global', NULL, 'user', 'admin.subscriptions', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.057449');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('cbb9039a-9529-4c8e-9eb5-ece1bf4e6995', 'global', NULL, 'user', 'admin.users', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.058148');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('2229c9d8-625d-4028-9976-1b8f0a30546d', 'global', NULL, 'user', 'nav.rag', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.058782');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('e1da80ce-9520-4201-931a-62ccd027e619', 'global', NULL, 'user', 'org.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.059491');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('5bf3cd94-8f31-4bc8-ae2a-8f727bb174d7', 'global', NULL, 'user', 'org.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.060752');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('970aca6b-be08-40b2-a473-bcf4cf91db4a', 'global', NULL, 'user', 'team.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.061983');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('5a837b9e-20c5-442c-8338-a2c4c17932fb', 'global', NULL, 'user', 'workspace.mcp', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.063073');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('a5e311fd-4348-4870-9bfa-caa6e554025b', 'global', NULL, 'user', 'workspace.promptTemplates', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.064024');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8ffe2080-2aa8-47f0-962c-e5b4514f8024', 'global', NULL, 'viewer', 'admin.auditLog', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.06509');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('eabee01f-dddc-433c-a0a8-5b1d478783ad', 'global', NULL, 'viewer', 'admin.featureFlags', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.066231');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('aea84fb5-58da-4667-afa4-3ce6e18d3147', 'global', NULL, 'viewer', 'admin.identity', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.067332');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c75ac4cb-a7b0-457a-9779-3b55e626dd68', 'global', NULL, 'viewer', 'admin.models', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.068534');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('2d7a33bc-3377-4bf9-9f3f-298459c9b0dd', 'global', NULL, 'viewer', 'admin.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.069612');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('333000d0-0f40-4f24-999b-aeee2c92826d', 'global', NULL, 'viewer', 'admin.organizations', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.070639');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('35707296-87c8-402b-bd74-ff81440a6fa7', 'global', NULL, 'viewer', 'admin.platformSettings', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.071388');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('0bbaef14-732c-4e9d-a035-ac5dbad6a9ef', 'global', NULL, 'viewer', 'admin.security', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.072472');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8673681b-a82c-403c-bd60-2d76ec214aec', 'global', NULL, 'viewer', 'admin.subscriptions', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.073603');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d09f500f-8ec5-44a1-bf29-ffd14b09ba61', 'global', NULL, 'viewer', 'admin.users', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.074665');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1f3f27bb-cfdf-4a3a-8453-70f10486434f', 'global', NULL, 'viewer', 'nav.rag', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.075528');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1239e63c-28cd-44ad-9ca1-c4143db7b9e0', 'global', NULL, 'viewer', 'org.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.076317');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('9d11d7f9-b233-41e9-9d73-e2bbef81ca4a', 'global', NULL, 'viewer', 'org.monitor', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.077023');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('39b298dd-e040-4451-80d7-f61dbe566fa2', 'global', NULL, 'viewer', 'team.analytics', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.077679');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('02d4a668-8e85-4be5-9734-3935d7e7c93b', 'global', NULL, 'viewer', 'workspace.mcp', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.07831');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('ff0f3dee-a88f-4e5d-aa7b-3c17d4c28fcf', 'global', NULL, 'viewer', 'workspace.promptTemplates', false, '8d14138b-3c50-41a7-a5ac-5714b8a37daf', '2026-07-27 12:50:29.07898');


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

INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-07-27 12:50:28.920408', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, assistants, workflows, MCP servers and knowledge bases.', true, NULL, '2026-07-27 12:50:28.92486', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-07-27 12:50:28.927994', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-07-27 12:50:28.995623', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, assistants, workflows, MCP servers and knowledge bases.', true, NULL, '2026-07-27 12:50:28.998396', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-07-27 12:50:29.001335', '2026-07-27 12:50:29.001335');


--
-- Data for Name: org_permission_group_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'members:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'teams:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'roles:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'settings:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'billing:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'audit:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'analytics:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'security:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'storage:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'knowledge:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'assistants:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'agents:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'workflows:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'mcp:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'memory:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'models:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('47f33cb1-0614-4db9-8bff-84405b6baa21', 'policies:view', '2026-07-27 12:50:28.920408');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:create', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:edit', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:delete', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:approve', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:disable', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:transfer', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'agents:publish', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:create', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:edit', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:delete', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:deploy', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:approve', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:disable', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:transfer', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'assistants:publish', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'workflows:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'workflows:create', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'workflows:edit', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'workflows:delete', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'mcp:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'mcp:create', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'mcp:edit', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'mcp:delete', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'knowledge:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'knowledge:create', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'knowledge:edit', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'knowledge:search', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('91442342-e205-438e-a693-ab949cba6ac3', 'models:view', '2026-07-27 12:50:28.92486');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'members:view', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'members:invite', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'members:edit', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'members:remove', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'members:suspend', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'teams:view', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'teams:create', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'teams:edit', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'teams:delete', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('87d4d68d-5c33-4fc1-9089-e49fac684439', 'teams:manage_members', '2026-07-27 12:50:28.927994');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'members:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'teams:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'roles:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'settings:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'billing:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'audit:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'analytics:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'security:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'storage:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'knowledge:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'assistants:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'agents:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'workflows:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'mcp:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'memory:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'models:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('f2eaac09-b41e-43a8-b90d-270d30b9a51f', 'policies:view', '2026-07-27 12:50:28.995623');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:create', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:edit', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:delete', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:approve', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:disable', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:transfer', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'agents:publish', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:create', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:edit', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:delete', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:deploy', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:approve', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:disable', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:transfer', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'assistants:publish', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'workflows:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'workflows:create', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'workflows:edit', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'workflows:delete', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'mcp:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'mcp:create', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'mcp:edit', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'mcp:delete', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'knowledge:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'knowledge:create', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'knowledge:edit', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'knowledge:search', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('920a9a40-51f3-46a4-99fa-04c97b19f56b', 'models:view', '2026-07-27 12:50:28.998396');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'members:view', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'members:invite', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'members:edit', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'members:remove', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'members:suspend', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'teams:view', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'teams:create', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'teams:edit', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'teams:delete', '2026-07-27 12:50:29.001335');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('78539d17-f694-4cda-816e-3f1d61261b3a', 'teams:manage_members', '2026-07-27 12:50:29.001335');


--
-- Data for Name: org_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_provider_credential; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: organization_member; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('110f5615-7560-4b0d-9381-d11086cbfc15', 'da17d7a9-7b4e-4749-8567-db7ec579fb8d', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-07-27 12:50:28.886397');
INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('2acdf4d7-531e-4489-a7fe-2ae751b5fe2e', 'd9c54dbe-b06d-46b6-a499-757a86c3abcc', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-07-27 12:50:28.966452');


--
-- Data for Name: org_resource_grant; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_assignment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'members:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'members:invite', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'members:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'members:remove', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'members:suspend', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'teams:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'teams:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'teams:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'teams:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'teams:manage_members', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'roles:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'roles:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'roles:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'roles:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'roles:assign', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'settings:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'settings:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'billing:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'billing:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'audit:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'analytics:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'security:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'security:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'storage:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'storage:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:transfer', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:search', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:publish', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'knowledge:admin', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:deploy', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:approve', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:disable', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:transfer', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'assistants:publish', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:approve', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:disable', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:transfer', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'agents:publish', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'workflows:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'workflows:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'workflows:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'workflows:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'mcp:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'mcp:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'mcp:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'mcp:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'memory:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'memory:create', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'memory:edit', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'memory:delete', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'memory:share', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'models:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'models:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'policies:view', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5925b1cf-b891-4453-ba27-523ba190e2c6', 'policies:manage', '2026-07-27 12:50:28.900943');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'agents:delete', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'agents:approve', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'agents:disable', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'agents:transfer', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'agents:publish', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'workflows:delete', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'mcp:edit', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'mcp:delete', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:create', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:edit', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:delete', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:deploy', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:approve', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:disable', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:transfer', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'assistants:publish', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'models:manage', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'memory:create', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'memory:edit', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'memory:delete', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4b0d41bd-04e1-40ec-8f39-389b243767a7', 'memory:share', '2026-07-27 12:50:28.90577');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a8aca324-6bbe-45d3-99cb-14958efb7e27', 'security:manage', '2026-07-27 12:50:28.908729');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a8aca324-6bbe-45d3-99cb-14958efb7e27', 'policies:manage', '2026-07-27 12:50:28.908729');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a8aca324-6bbe-45d3-99cb-14958efb7e27', 'members:edit', '2026-07-27 12:50:28.908729');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a8aca324-6bbe-45d3-99cb-14958efb7e27', 'members:suspend', '2026-07-27 12:50:28.908729');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:create', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:edit', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:delete', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:transfer', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:admin', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('79aa6a59-a9c7-4279-867f-90b2a2d3ebae', 'knowledge:publish', '2026-07-27 12:50:28.910461');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('431fc38a-90fc-4bb7-821f-a7dfae983dcb', 'billing:manage', '2026-07-27 12:50:28.912105');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('72437031-e4e9-4821-8792-520586c164e2', 'teams:create', '2026-07-27 12:50:28.914521');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('72437031-e4e9-4821-8792-520586c164e2', 'teams:edit', '2026-07-27 12:50:28.914521');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('72437031-e4e9-4821-8792-520586c164e2', 'teams:manage_members', '2026-07-27 12:50:28.914521');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('72437031-e4e9-4821-8792-520586c164e2', 'members:invite', '2026-07-27 12:50:28.914521');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'agents:create', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'agents:edit', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'workflows:create', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'workflows:edit', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'mcp:create', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'memory:create', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('caf3463b-1f5e-46fd-9f12-8d980a7e8113', 'memory:edit', '2026-07-27 12:50:28.916629');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'members:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'teams:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'roles:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'settings:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'billing:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'audit:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'analytics:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'security:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'storage:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'knowledge:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'assistants:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'agents:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'workflows:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'mcp:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'memory:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'models:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'policies:view', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9c2d7b33-93b0-4ff8-b5ad-ea997fe4805a', 'knowledge:search', '2026-07-27 12:50:28.917788');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'members:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'members:invite', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'members:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'members:remove', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'members:suspend', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'teams:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'teams:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'teams:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'teams:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'teams:manage_members', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'roles:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'roles:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'roles:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'roles:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'roles:assign', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'settings:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'settings:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'billing:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'billing:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'audit:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'analytics:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'security:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'security:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'storage:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'storage:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:transfer', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:search', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:publish', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'knowledge:admin', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:deploy', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:approve', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:disable', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:transfer', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'assistants:publish', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:approve', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:disable', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:transfer', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'agents:publish', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'workflows:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'workflows:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'workflows:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'workflows:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'mcp:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'mcp:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'mcp:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'mcp:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'memory:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'memory:create', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'memory:edit', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'memory:delete', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'memory:share', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'models:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'models:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'policies:view', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5a050b2f-e246-4f88-9239-2055ac01b4bb', 'policies:manage', '2026-07-27 12:50:28.978675');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'agents:delete', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'agents:approve', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'agents:disable', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'agents:transfer', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'agents:publish', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'workflows:delete', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'mcp:edit', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'mcp:delete', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:create', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:edit', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:delete', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:deploy', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:approve', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:disable', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:transfer', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'assistants:publish', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'models:manage', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'memory:create', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'memory:edit', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'memory:delete', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('029cbaba-83cb-4385-b391-8c7588ac89e0', 'memory:share', '2026-07-27 12:50:28.982296');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5bddab42-b33f-4130-905c-039cfa466c17', 'security:manage', '2026-07-27 12:50:28.984671');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5bddab42-b33f-4130-905c-039cfa466c17', 'policies:manage', '2026-07-27 12:50:28.984671');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5bddab42-b33f-4130-905c-039cfa466c17', 'members:edit', '2026-07-27 12:50:28.984671');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5bddab42-b33f-4130-905c-039cfa466c17', 'members:suspend', '2026-07-27 12:50:28.984671');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:create', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:edit', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:delete', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:transfer', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:admin', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d85ca1d0-2e87-47af-a4d2-73a552e5882c', 'knowledge:publish', '2026-07-27 12:50:28.987425');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('be2f674c-8001-4050-97c5-ed656eae7ea0', 'billing:manage', '2026-07-27 12:50:28.989589');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('6da2602d-add2-448f-b25c-8370fe84dc08', 'teams:create', '2026-07-27 12:50:28.991447');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('6da2602d-add2-448f-b25c-8370fe84dc08', 'teams:edit', '2026-07-27 12:50:28.991447');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('6da2602d-add2-448f-b25c-8370fe84dc08', 'teams:manage_members', '2026-07-27 12:50:28.991447');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('6da2602d-add2-448f-b25c-8370fe84dc08', 'members:invite', '2026-07-27 12:50:28.991447');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'agents:create', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'agents:edit', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'workflows:create', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'workflows:edit', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'mcp:create', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'memory:create', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f02ed4a9-7cf8-4cce-b2d7-0d6ee7562b7c', 'memory:edit', '2026-07-27 12:50:28.992971');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'members:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'teams:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'roles:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'settings:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'billing:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'audit:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'analytics:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'security:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'storage:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'knowledge:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'assistants:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'agents:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'workflows:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'mcp:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'memory:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'models:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'policies:view', '2026-07-27 12:50:28.993929');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('990ce9dc-779c-44b9-bdb5-9bad765ef45b', 'knowledge:search', '2026-07-27 12:50:28.993929');


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

INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('4f1d2d77-ab78-4826-b79f-a77dd3189d49', 'Python Code Runner', 'Execute Python scripts in the browser via Pyodide. Supports numpy, pandas, matplotlib, scipy. Guides correct usage of the sandboxed environment.', '# Python Code Runner

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
- Verify Python syntax or logic', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{python,execution,scripting,pyodide}', '{"type":"emoji","value":"🐍"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('d48b2359-7ec4-4ad1-b6ac-8082c9abbacd', 'Data Analysis — Pandas & NumPy', 'Analyze datasets with pandas and numpy in the browser. CSV loading via StringIO or URL fetch, descriptive stats, groupby, correlation, and more.', '# Data Analysis — Pandas & NumPy

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
- Find correlations or patterns in data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{pandas,numpy,data-analysis,statistics,csv}', '{"type":"emoji","value":"📊"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('376b57e6-1953-4860-a445-44eaa9cf4f03', 'Data Visualization — Matplotlib', 'Create charts and plots with matplotlib in the Pyodide sandbox. Includes agg backend setup and all common chart types.', '# Data Visualization — Matplotlib

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
- Generate figures or diagrams from data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{matplotlib,visualization,charts,plots}', '{"type":"emoji","value":"📈"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('85e05537-df9b-46fa-907d-8add275c36b8', 'Math & Statistics Calculator', 'Perform advanced math, statistics, and scientific computing with numpy and scipy. Covers hypothesis tests, linear algebra, integration, optimization, and distributions.', '# Math & Statistics Calculator

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
- Work with probability distributions', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{math,statistics,numpy,scipy,computation}', '{"type":"emoji","value":"🧮"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('c60bb653-0a0c-41c4-88ca-42f9f2db58ad', 'Text & File Processing', 'Parse and transform text, JSON, CSV, and structured data in Python. Covers regex extraction, word frequency, string transforms, and URL text fetching.', '# Text & File Processing

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
- Fetch and process text from a URL', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{text,parsing,csv,json,regex}', '{"type":"emoji","value":"📝"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('04f3e735-9c30-479c-b584-0e978fcbed74', 'Server-Side Python Executor', 'Run real Python (or shell) commands on the server backend using the bash-execution tool. Unlike Pyodide, this uses the actual system Python with full stdlib, file I/O, pip-installed packages, and no CORS restrictions.', '# Server-Side Python Executor

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
', '{"allowed-tools":["bash-execution"],"user-invocable":true}', 'development', '{python,bash,server,execution,code}', '{"type":"emoji","value":"🖥️"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'none', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('9052f437-2eb4-4cd7-a028-7766ce38accb', 'Presentation Builder', 'Create real PowerPoint (.pptx) decks in the browser with the PptxGenJS global — slides, styled text, bullets, tables, images — delivered as a downloadable file via Files.save.', '# Presentation Builder

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
different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'creative', '{pptx,powerpoint,presentation,slides,pptxgenjs}', '{"type":"emoji","value":"📽️"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'approved', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('42f7b772-f226-42d5-b58f-a28cd80bca65', 'Word Document Builder', 'Create real Word (.docx) documents in the browser with the docx global — headings, styled runs, lists, tables, page breaks — delivered as a downloadable file via Files.save.', '# Word Document Builder

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
different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'writing', '{docx,word,report,letter}', '{"type":"emoji","value":"📄"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'approved', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('05e2eb2d-af01-4c6b-96ef-7778df1acae1', 'Spreadsheet Builder', 'Create real Excel (.xlsx) workbooks in the browser with the XLSX (SheetJS) global — multiple sheets, column widths, formulas — delivered as a downloadable file via Files.save.', '# Spreadsheet Builder

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
then stop and wait instead of generating a different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'analysis', '{xlsx,excel,spreadsheet,sheetjs}', '{"type":"emoji","value":"📊"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'approved', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('dc1dc9f5-a16d-4185-ac5b-d9d8f52bf838', 'PDF Builder', 'Create real PDF files in the browser with the PDFLib global (pdf-lib) — text, shapes, multi-page layouts — delivered as a downloadable file via Files.save.', '# PDF Builder

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
wait instead of generating a different format.', '{"allowed-tools":["mini-javascript-execution"],"user-invocable":true}', 'productivity', '{pdf,pdf-lib,invoice,printable}', '{"type":"emoji","value":"📑"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'approved', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);
INSERT INTO public.skill (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, scope, team_id, active_version_number, last_auto_rollback_at, created_at, updated_at, deleted_at) VALUES ('bc5dbe34-6fd3-4330-bf39-04627c5ba7df', 'Competitor Comparison', 'Compare 2–20 companies, products, APIs, LLMs, frameworks or platforms and generate an executive comparison report with a feature/pricing matrix, strengths, weaknesses, rankings and sources. Use for: compare A vs B, X versus Y, competitive analysis, battle card, vendor comparison, feature comparison, pricing comparison, technical comparison, market comparison, top competitors, best alternative / alternative to X.', '# Competitor Comparison

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

$ARGUMENTS', '{"allowed-tools":["webSearch","webContent","http","createTable","browser-automation"],"user-invocable":true,"argument-hint":"<competitor A> vs <competitor B> [vs ...] [focus: pricing|features|security|...]"}', 'analysis', '{comparison,competitive-analysis,battle-card,vendor,research,web-search}', '{"type":"emoji","value":"⚖️"}', '8d14138b-3c50-41a7-a5ac-5714b8a37daf', NULL, 'public', '1.0.0', 0, true, 'approved', 'personal', NULL, NULL, NULL, '2026-07-27 12:50:30.12965', '2026-07-27 12:50:30.12965', NULL);


--
-- Data for Name: skill_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_rating; Type: TABLE DATA; Schema: public; Owner: -
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

INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('36c5c609-e8ec-48ec-aaf0-595cda966adb', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '580e94e3-5d5a-41f0-a5cc-b717cb584c7e', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '{"sourceHandle":"right","targetHandle":"left"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('ceaa518e-13ae-41c1-97df-a53862a2e611', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '2c086c8f-e7e8-43d6-afc2-736cbcf795c3', '048fd5b4-fdb2-4a38-a975-1fabecc72aeb', '{"sourceHandle":"right","targetHandle":"left"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('7061d146-3a65-4161-8487-0a94e27de8c5', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '971cbea9-159b-454d-bda8-1ea5c59910cb', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('650f21cb-9205-4ec1-aade-aca2ec8cffd3', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'fcc24d1c-8a39-4fe8-82f1-4e363c1f0488', '0d6f147c-4e3e-427e-8b0c-7ce4c301d747', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('912f2ffc-95ee-4694-a62b-d87a495e586b', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '4ba94ecf-3411-4373-a9fb-93d4df3ea13c', 'fcc24d1c-8a39-4fe8-82f1-4e363c1f0488', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('427e9147-0d05-4969-8183-48896909af81', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '3f24c2d5-c299-42a8-8aec-2b7703117604', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '{"sourceHandle":"if","targetHandle":"left"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('3350148e-dc6d-42fc-8c36-9b746d839746', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '0d6f147c-4e3e-427e-8b0c-7ce4c301d747', '580e94e3-5d5a-41f0-a5cc-b717cb584c7e', '{"sourceHandle":"if"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('df33fb5f-5f21-49dd-8bfa-333e13d73003', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '3f24c2d5-c299-42a8-8aec-2b7703117604', 'a3172be5-7943-4cb7-b682-ef2af54e8c28', '{"sourceHandle":"else","targetHandle":"left"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('a9af8dc5-2478-44f6-9a23-271003c04f6a', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '971cbea9-159b-454d-bda8-1ea5c59910cb', '048fd5b4-fdb2-4a38-a975-1fabecc72aeb', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('14654295-759c-4860-bdf2-fb807ff74138', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '40226534-a12a-4309-8c6b-f315f9236357', '4ba94ecf-3411-4373-a9fb-93d4df3ea13c', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('a5362ac6-4ce9-462d-a964-5680b7ebda4a', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'a3172be5-7943-4cb7-b682-ef2af54e8c28', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('e20d55e2-cce1-4986-9f05-dcdb4fc84c67', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '0d6f147c-4e3e-427e-8b0c-7ce4c301d747', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '{"sourceHandle":"else","targetHandle":"left"}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('5da452e0-8bf8-4601-b841-af003f223956', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', 'fcc24d1c-8a39-4fe8-82f1-4e363c1f0488', '3f24c2d5-c299-42a8-8aec-2b7703117604', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('54882086-a4fa-4bcb-802c-6b94b7a89e78', '0.1.0', '4e83579e-67ab-49c0-a6f9-15af86cf927d', '39d3e42d-b612-4d39-a68b-9ace86463ddb', '2c086c8f-e7e8-43d6-afc2-736cbcf795c3', '{}', '2026-07-27 12:50:28.864013');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('41faa3ef-6c95-40f6-980e-ae3fcab98a65', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', '7d9dd438-8584-405f-8a00-ce794619bdbd', '4a812129-6e21-4b99-aced-e9c5cdc02be6', '{}', '2026-07-27 12:50:28.87065');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('e80ffa53-856f-4b3c-9a62-b98be54e2b2b', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', '4a812129-6e21-4b99-aced-e9c5cdc02be6', 'ef11ef4a-4932-44a4-9083-b3701734542f', '{}', '2026-07-27 12:50:28.87065');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('b7ffd8c7-ac12-4726-8bb1-80b7fae89111', '0.1.0', '589071dc-4ea0-4116-b467-ad527c91d27e', 'ef11ef4a-4932-44a4-9083-b3701734542f', '3a95964c-7c6c-47bb-b7fe-7d8f8072c41f', '{}', '2026-07-27 12:50:28.87065');


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

\unrestrict gAVnAFMcNsChRKsaH3nJ4IGh9Y95gsuyAXVlDbeJV1ALtyyjfOuv15B4jlTqWw0


SET session_replication_role = DEFAULT;
