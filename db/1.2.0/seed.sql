-- NXPi reference seed data. Apply as a SUPERUSER, AFTER schema.sql + grants.sql.
--   psql -v admin_email="admin@you.example" -v admin_password_hash="<hash>" -f seed.sql
-- The hash is produced per-deploy by the nxpi-hash helper (Better Auth scrypt).
-- FK checks are deferred during the bulk load (superuser-only).
SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

\restrict V3hyJVmQbxun8RgLC0xo0DV0sRVQCSRaLbvjQTWCT2uyTiQ2xCp5xkyK0hhx6uw

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

INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'Super Admin''s Workspace', 'personal-5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'free', 'active', '2026-07-14 19:07:53.761406', '2026-07-14 19:07:53.761406');
INSERT INTO public.organization (id, name, slug, description, plan, status, created_at, updated_at) VALUES ('7f8c231d-5128-4059-b9eb-2daef779d1e9', 'Default Organization', 'default', NULL, 'free', 'active', '2026-07-14 19:07:54.05733', '2026-07-14 19:07:54.05733');


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (id, name, email, email_verified, password, image, preferences, created_at, updated_at, banned, ban_reason, ban_expires, role, two_factor_enabled, two_factor_secret, two_factor_backup_codes) VALUES ('5b31c819-89b7-4d30-8e1d-747c5b736710', 'Super Admin', :'admin_email', false, NULL, NULL, '{}', '2026-07-14 19:07:47.642', '2026-07-14 19:07:47.642', false, NULL, NULL, 'admin', false, NULL, NULL);


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

INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('d7984ddd-9ebc-4421-bcde-b202ae792d5a', '0.1.0', 'baby-research', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/1f468-1f3fb-200d-1f52c.png","style":{"backgroundColor":"oklch(78.5% 0.115 274.713)"}}', 'Comprehensive web research workflow that performs multi-layered search and content analysis to generate detailed research reports based on user instructions and research objectives.', true, 'private', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 0, NULL, '2026-07-14 19:07:53.591978', '2026-07-14 19:07:53.591978', NULL);
INSERT INTO public.workflow (id, version, name, icon, description, is_published, visibility, user_id, organization_id, install_count, tags, created_at, updated_at, deleted_at) VALUES ('61c31733-e2f0-45da-8aa5-fd6736967c66', '0.1.0', 'Get Weather', '{"type":"emoji","value":"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/26c8-fe0f.png","style":{"backgroundColor":"oklch(20.5% 0 0)"}}', 'Get weather data from the API', true, 'private', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 0, NULL, '2026-07-14 19:07:53.648549', '2026-07-14 19:07:53.648549', NULL);


--
-- Data for Name: orchestration_run; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: a2a_task; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: account; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.account (id, account_id, provider_id, user_id, access_token, refresh_token, id_token, access_token_expires_at, refresh_token_expires_at, scope, password, created_at, updated_at) VALUES ('628858fd-5b71-40b8-94a3-8fcc0152e2e6', '5b31c819-89b7-4d30-8e1d-747c5b736710', 'credential', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, NULL, NULL, NULL, NULL, NULL, :'admin_password_hash', '2026-07-14 19:07:54.008', '2026-07-14 19:07:54.008');


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

INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('bash_execution_enabled', 'false', NULL, '2026-07-14 19:07:54.331563');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('signup_enabled', 'true', NULL, '2026-07-14 19:07:54.338653');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('temporary_chat_enabled', 'true', NULL, '2026-07-14 19:07:54.347368');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('platform_mfa_required', 'false', NULL, '2026-07-14 19:07:54.351822');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('agent_marketplace_enabled', 'true', NULL, '2026-07-14 19:07:54.368819');
INSERT INTO public.app_settings (key, value, updated_by, updated_at) VALUES ('personal_workspace_enabled', 'false', NULL, '2026-07-14 19:07:54.375804');


--
-- Data for Name: archive; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: archive_item; Type: TABLE DATA; Schema: public; Owner: -
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

INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-07-14 19:07:53.774352', '2026-07-14 19:07:53.774352');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-07-14 19:07:53.814733', '2026-07-14 19:07:53.814733');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, skills, and models.', true, '3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', NULL, '2026-07-14 19:07:53.782043', '2026-07-14 19:07:53.825');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('95c02282-76e7-492c-a1cf-288206830eab', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, '3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', NULL, '2026-07-14 19:07:53.786419', '2026-07-14 19:07:53.84');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, '3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', NULL, '2026-07-14 19:07:53.79066', '2026-07-14 19:07:53.854');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('9e59748e-4a47-43c0-bc76-31c0f97fe4ef', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, '3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', NULL, '2026-07-14 19:07:53.798066', '2026-07-14 19:07:53.864');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('f424f818-f9b8-4b64-be88-8b35cf6e1d0b', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, '3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', NULL, '2026-07-14 19:07:53.801058', '2026-07-14 19:07:53.87');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, 'ef48cd4a-64d5-49f2-aa76-00155dc41abe', NULL, '2026-07-14 19:07:53.807807', '2026-07-14 19:07:53.874');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'org-admin', 'Org Admin', 'Full control over the organization. Maps to org owner/admin.', true, NULL, NULL, '2026-07-14 19:07:54.109442', '2026-07-14 19:07:54.109442');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'viewer', 'Viewer', 'Read-only access across the organization.', true, NULL, NULL, '2026-07-14 19:07:54.201932', '2026-07-14 19:07:54.201932');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'ai-admin', 'AI Admin', 'Manage agents, workflows, MCP servers, skills, and models.', true, 'd0c9b7be-0023-4e50-87bf-79d9bc9f2231', NULL, '2026-07-14 19:07:54.157151', '2026-07-14 19:07:54.222');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('2438f0d2-e301-4406-8cdc-ea97dd88b6cf', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'security-admin', 'Security Admin', 'Manage security settings, policies, audit log, suspend members.', true, 'd0c9b7be-0023-4e50-87bf-79d9bc9f2231', NULL, '2026-07-14 19:07:54.175447', '2026-07-14 19:07:54.231');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'knowledge-admin', 'Knowledge Admin', 'Create, edit, delete, transfer, review/approve, and publish knowledge bases.', true, 'd0c9b7be-0023-4e50-87bf-79d9bc9f2231', NULL, '2026-07-14 19:07:54.18575', '2026-07-14 19:07:54.238');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('ee2f673f-b3a8-4cdd-9ba0-49eea73f84c6', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'billing-admin', 'Billing Admin', 'Manage billing and view organization settings.', true, 'd0c9b7be-0023-4e50-87bf-79d9bc9f2231', NULL, '2026-07-14 19:07:54.190808', '2026-07-14 19:07:54.246');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('fb56fc01-2d0f-40db-aaf0-9e2a29f617c9', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'team-manager', 'Team Manager', 'Create and manage teams and their members.', true, 'd0c9b7be-0023-4e50-87bf-79d9bc9f2231', NULL, '2026-07-14 19:07:54.194351', '2026-07-14 19:07:54.253');
INSERT INTO public.org_role (id, organization_id, key, name, description, is_system, parent_role_id, created_by, created_at, updated_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'user', 'User', 'Basic contributor — create and edit own agents and workflows.', true, '7bfed3b6-8c60-4a27-95f3-08baf1c1850a', NULL, '2026-07-14 19:07:54.199496', '2026-07-14 19:07:54.263');


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

INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('8f48f974-e7ab-417e-a987-393060416bbd', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'tool', 'INITIAL_SEARCH', 'Perform initial web search based on user query and parameters', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Based on the following research instruction, perform a comprehensive web search:"},{"type":"hardBreak"}]},{"type":"bulletList","content":[{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Research Instruction**: "},{"type":"mention","attrs":{"id":"20075100-6d14-42ea-ac7a-a2732d54cacf","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- **Topic Area**: "},{"type":"mention","attrs":{"id":"e279fc2c-43c3-441d-bb5d-2d084a74bd63","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]}]},{"type":"listItem","content":[{"type":"paragraph","content":[{"type":"text","text":"- Search Strategy:"}]}]}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Extract key concepts and themes from the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Identify multiple search angles and perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Use diverse keywords and search terms"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Focus on finding authoritative and comprehensive sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Include recent developments and established knowledge"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. Cast a wide net to ensure comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  Important: Don''t limit yourself to obvious keywords. Consider:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Technical terminology and industry jargon"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Alternative names and concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Related fields and cross-industry applications"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Recent trends and developments"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Expert opinions and case studies"}]},{"type":"paragraph","content":[{"type":"text","text":"  Return maximum 15 diverse, high-quality results."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('450f9ad7-663c-4516-a4fb-b1a52fa8a287', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'condition', 'URL_CONDITION', '', '{"position":{"x":1092.720830684793,"y":-109.56839983927273},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4","path":["answer","important_url"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_not_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('ddbaa938-d366-4312-bedb-ba211a2b99b8', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'tool', 'CONTENT_EXTRACTION', 'Extract detailed content from important URL', '{"position":{"x":1426.344044454295,"y":-203.77120780533727},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"url : "},{"type":"mention","attrs":{"id":"9bd55c87-9eac-4af2-968f-c83b93577639","label":"{\"nodeId\":\"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4\",\"path\":[\"answer\",\"important_url\"]}"}}]}]},"tool":{"type":"app-tool","id":"webContent","description":"A detailed web content extraction tool that analyzes and summarizes specific web pages from provided URLs. Extracts full content, processes it intelligently, and provides comprehensive summaries. Perfect for in-depth analysis of specific articles, documents, or web pages.","parameterSchema":{"type":"object","properties":{"urls":{"type":"array","items":{"type":"string"},"description":"List of URLs to extract content from"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each URL","default":3000,"minimum":100,"maximum":10000},"livecrawl":{"type":"string","enum":["always","fallback","preferred"],"description":"Live crawling preference - always forces live crawl, fallback uses cache first, preferred tries live first","default":"preferred"}},"required":["urls"]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('8ec7aa2a-1890-40a6-833e-828d623c5a27', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'llm', 'SUMMARY', 'Synthesize all information into comprehensive research report', '{"position":{"x":1912.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"title":{"type":"string","description":"Clear, descriptive title for the research report"},"summary":{"type":"string","description":"Executive summary in 4-6 sentences"},"content":{"type":"string","description":"Comprehensive analysis in markdown format with source citations"},"diagram":{"type":"string","description":"Mermaid diagram code if beneficial (empty string if not needed)"},"key_insights":{"type":"array","items":{"type":"string"},"description":"3-5 most important insights from the research"},"confidence_level":{"type":"number","description":"Confidence score 1-10 based on source quality and coverage"},"sources_used":{"type":"array","items":{"type":"object","properties":{"title":{"type":"string"},"url":{"type":"string"},"type":{"type":"string"}}},"description":"List of all sources referenced in the content"},"images":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string"},"description":{"type":"string"},"context":{"type":"string"}}},"description":"List of relevant images extracted from search results"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report based on all collected information."}]},{"type":"paragraph","content":[{"type":"text","text":"  Research Instruction: "},{"type":"mention","attrs":{"id":"32c8abfa-f993-4c29-906a-d1c26f36711e","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"research_instruction\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c20376fa-66ec-45ce-bbef-a4f8d793e110","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"topic\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Output Language: "},{"type":"mention","attrs":{"id":"87a8619d-b077-48de-8351-1cb5bdf6cc59","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"language\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Information Sources:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Initial Search: "},{"type":"mention","attrs":{"id":"53de2392-4c38-4d56-a8bf-d1b64892a348","label":"{\"nodeId\":\"8f48f974-e7ab-417e-a987-393060416bbd\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Analysis: "},{"type":"mention","attrs":{"id":"7447143a-9154-49e8-b3bb-bff946398903","label":"{\"nodeId\":\"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4\",\"path\":[\"answer\"]}","mentionSuggestionChar":"@"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"  - Detailed Content: "},{"type":"mention","attrs":{"id":"2769be0e-9631-4562-9ccc-2026d7aca616","label":"{\"nodeId\":\"ddbaa938-d366-4312-bedb-ba211a2b99b8\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Additional Search: "},{"type":"mention","attrs":{"id":"9ebfa7ad-341d-4db5-a88b-1d772fa97edd","label":"{\"nodeId\":\"4cd73d2e-cb7e-4dfb-b259-28c149256bc1\",\"path\":[\"tool_result\"]}","mentionSuggestionChar":"@"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Generate a structured report that directly addresses the research instruction:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. "},{"type":"text","marks":[{"type":"bold"}],"text":"title"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Clear, descriptive title that reflects the research focus"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should align with the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Executive summary in 4-6 sentences"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Directly answer the key questions in the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Highlight major findings and implications"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"content"},{"type":"text","text":" (string - markdown format):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Comprehensive analysis organized logically"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Structure based on the research instruction requirements"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Include: key findings, evidence, analysis, implications, recommendations"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Use proper markdown formatting with headers, lists, emphasis"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Important Content Guidelines:"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Images"},{"type":"text","text":": If images are available in the search results, include relevant ones using markdown image syntax: `![Image description](image_url)`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Sources"},{"type":"text","text":": Always cite sources when referencing specific information using format: `[Source Title](URL)` or `According to [Source Title](URL), ...`"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Data and Statistics"},{"type":"text","text":": When presenting data, always include the source"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Quotes"},{"type":"text","text":": Use blockquotes for important quotes with attribution"}]},{"type":"paragraph","content":[{"type":"text","text":"     - "},{"type":"text","marks":[{"type":"bold"}],"text":"Evidence"},{"type":"text","text":": Support claims with specific evidence from the sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"bold"}],"text":"Structure Example:"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```markdown"}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Introduction"}]},{"type":"paragraph","content":[{"type":"text","text":"     Brief overview with context"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Key Findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 1 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Finding 2 with source citation"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Visual Evidence"}]},{"type":"paragraph","content":[{"type":"text","text":"     ![Chart showing trend](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "},{"type":"text","marks":[{"type":"italic"}],"text":"Source: [Report Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Detailed Analysis"}]},{"type":"paragraph","content":[{"type":"text","text":"     In-depth analysis with multiple source citations"}]},{"type":"paragraph","content":[{"type":"text","text":"     "}]},{"type":"paragraph","content":[{"type":"text","text":"     ## Implications"}]},{"type":"paragraph","content":[{"type":"text","text":"     What this means for the research question"}]},{"type":"paragraph","content":[{"type":"text","text":"     ```"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"diagram"},{"type":"text","text":" (string - Mermaid code):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Create visualization if it helps explain findings"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Examples: process flows, relationships, timelines, comparisons"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Only include if it adds significant value"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. "},{"type":"text","marks":[{"type":"bold"}],"text":"key_insights"},{"type":"text","text":" (array of strings):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - 3-5 most important insights from the research"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should directly relate to the research instruction objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  6. "},{"type":"text","marks":[{"type":"bold"}],"text":"confidence_level"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate confidence in findings based on source quality and coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  7. "},{"type":"text","marks":[{"type":"bold"}],"text":"sources_used"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - List all sources referenced in the content"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Format: {\"title\": \"Source Title\", \"url\": \"URL\", \"type\": \"article/report/study\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"  Write in [INITIAL_SEARCH.output_language]. Ensure the report:"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Fully addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Includes relevant images where they add value"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Properly cites all sources"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Provides actionable insights"}]},{"type":"paragraph","content":[{"type":"text","text":"  - Maintains professional formatting"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"8. "},{"type":"text","marks":[{"type":"bold"}],"text":"images"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Extract at least 3 relevant images"},{"type":"text","text":" from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Format: {\"url\": \"image_url\", \"description\": \"descriptive caption\", \"context\": \"how this image relates to the research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Select images that support key findings or illustrate important concepts"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse image types: charts, diagrams, photos, infographics"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize images that enhance understanding of the research topic"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('568679b6-707e-4774-8d85-062154445213', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'condition', 'SEARCH_CONDITION', '', '{"position":{"x":1096.3175798437799,"y":108.80530614989887},"type":"default"}', '{"kind":"condition","outputSchema":{"type":"object","properties":{}},"branches":{"if":{"id":"if","logicalOperator":"AND","type":"if","conditions":[{"source":{"nodeId":"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4","path":["answer","additional_search_instruction"],"nodeName":"ANALYSIS","type":"object"},"operator":"is_empty"}]},"else":{"id":"else","logicalOperator":"AND","type":"else","conditions":[]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('4cd73d2e-cb7e-4dfb-b259-28c149256bc1', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'tool', 'ADDITIONAL_SEARCH', 'Perform supplementary search based on specific instruction', '{"position":{"x":1439.3610744098883,"y":257.6457427362809},"type":"default"}', '{"kind":"tool","outputSchema":{"type":"object","properties":{"tool_result":{"type":"object"}}},"model":{"provider":"openai","model":"gpt-4.1"},"message":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Perform targeted search based on this specific instruction: "},{"type":"mention","attrs":{"id":"dc2caf22-632d-4388-bf9c-7c8626a24c65","label":"{\"nodeId\":\"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4\",\"path\":[\"answer\",\"additional_search_instruction\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"Research Context: "},{"type":"mention","attrs":{"id":"6ab2e17b-1e04-4065-97d4-627de934b88d","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  Topic Area: "},{"type":"mention","attrs":{"id":"c8de8dcf-0218-4b31-8552-b1f5d0ab8ad3","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"text","text":"  Search Strategy:"}]},{"type":"paragraph","content":[{"type":"text","text":"  1. Follow the specific search instruction precisely"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. Focus on filling the identified information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. Look for recent developments and expert perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. Include diverse viewpoints and comprehensive coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  5. Prioritize sources that add new insights to the research"}]},{"type":"paragraph","content":[{"type":"text","text":"  Target 8-10 high-quality results that provide unique value."}]}]},"tool":{"type":"app-tool","id":"webSearch","description":"A web search tool for quick research and information gathering. Provides basic search results with titles, summaries, and URLs from across the web. Perfect for finding relevant sources and getting an overview of topics.","parameterSchema":{"type":"object","properties":{"query":{"type":"string","description":"Search query"},"numResults":{"type":"number","description":"Number of search results to return","default":5,"minimum":1,"maximum":20},"type":{"type":"string","enum":["auto","keyword","neural"],"description":"Search type - auto lets Exa decide, keyword for exact matches, neural for semantic search","default":"auto"},"category":{"type":"string","enum":["company","research paper","news","linkedin profile","github","tweet","movie","song","personal site","pdf"],"description":"Category to focus the search on"},"includeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically include in search results","default":[]},"excludeDomains":{"type":"array","items":{"type":"string"},"description":"List of domains to specifically exclude from search results","default":[]},"startPublishedDate":{"type":"string","description":"Start date for published content (YYYY-MM-DD format)"},"endPublishedDate":{"type":"string","description":"End date for published content (YYYY-MM-DD format)"},"maxCharacters":{"type":"number","description":"Maximum characters to extract from each result","default":3000,"minimum":100,"maximum":10000}},"required":["query"]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('34fb5219-d9b9-4cd2-a64c-c18c81bb881a', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'output', 'OUTPUT', '', '{"position":{"x":2632.4044439691656,"y":29.67494745840466},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"research_findings","source":{"nodeId":"8ec7aa2a-1890-40a6-833e-828d623c5a27","path":["answer"]}},{"key":"organized_data","source":{"nodeId":"598b5a99-e184-4bb1-9b79-8ff54b6f070e","path":["answer"]}},{"key":"message_response_guide","source":{"nodeId":"b6df0c2f-cf59-4cd3-b9da-3be772ceb48c","path":["template"]}},{"key":"images","source":{"nodeId":"8ec7aa2a-1890-40a6-833e-828d623c5a27","path":["answer","images"]}}]}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('598b5a99-e184-4bb1-9b79-8ff54b6f070e', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'llm', 'ORGANIZATION', 'Organize and summarize all collected information for report generation', '{"position":{"x":2272.4044439691656,"y":91.44758151102624},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"string"},"totalTokens":{"type":"number"}}},"messages":[{"role":"system","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"You are a research information organizer. Your task is to systematically organize and summarize all collected research information into a comprehensive, well-structured format that will be used for report generation."}]},{"type":"paragraph","content":[{"type":"text","text":"Your response should include:"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH OVERVIEW"}]},{"type":"paragraph","content":[{"type":"text","text":"[Summarize the research instruction and approach]"}]},{"type":"paragraph","content":[{"type":"text","text":"## KEY SOURCES IDENTIFIED"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all important sources with titles and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 1](URL1) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 2](URL2) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"- [Source Title 3](URL3) - Brief description"}]},{"type":"paragraph","content":[{"type":"text","text":"## AVAILABLE IMAGES"}]},{"type":"paragraph","content":[{"type":"text","text":"[List all images found with descriptions and URLs]"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 1](image_url1) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 2](image_url2) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"- ![Description 3](image_url3) - Context/relevance"}]},{"type":"paragraph","content":[{"type":"text","text":"## MAIN FINDINGS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Organized key findings with source attributions]"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 1 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 2 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"- Finding 3 (Source: [Title](URL))"}]},{"type":"paragraph","content":[{"type":"text","text":"## DETAILED CONTENT SUMMARY"}]},{"type":"paragraph","content":[{"type":"text","text":"[Comprehensive summary of all extracted content]"}]},{"type":"paragraph","content":[{"type":"text","text":"## STATISTICAL DATA"}]},{"type":"paragraph","content":[{"type":"text","text":"[Any numbers, statistics, or quantitative data found]"}]},{"type":"paragraph","content":[{"type":"text","text":"## EXPERT OPINIONS/QUOTES"}]},{"type":"paragraph","content":[{"type":"text","text":"[Important quotes or expert perspectives]"}]},{"type":"paragraph","content":[{"type":"text","text":"## RESEARCH GAPS"}]},{"type":"paragraph","content":[{"type":"text","text":"[Areas where information might be incomplete]"}]},{"type":"paragraph","content":[{"type":"text","text":"Make this comprehensive and well-organized for easy reference in report generation."}]}]}},{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"4a3380c5-0b39-43a8-906e-f0a38ca41539","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"1de3a234-9029-4914-8086-ba9789e2a017","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"topic\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Initial Search Results: "},{"type":"mention","attrs":{"id":"2ea9f224-5806-408a-a538-c61313a6f0af","label":"{\"nodeId\":\"8f48f974-e7ab-417e-a987-393060416bbd\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Analysis Summary: "},{"type":"mention","attrs":{"id":"a0c436b7-6300-4d1f-a0e6-1316c1c8cdc7","label":"{\"nodeId\":\"f60a8e5d-bc96-4b7c-b4f7-27adb99058a4\",\"path\":[\"answer\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Detailed Content: "},{"type":"mention","attrs":{"id":"10bf3fbf-2421-4d94-bc64-30e96ef28168","label":"{\"nodeId\":\"ddbaa938-d366-4312-bedb-ba211a2b99b8\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Additional Search:  "},{"type":"mention","attrs":{"id":"2e50dd84-1d6a-4680-92ae-b3d78045b713","label":"{\"nodeId\":\"4cd73d2e-cb7e-4dfb-b259-28c149256bc1\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"Please organize all this information according to the format specified in the system prompt."}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('b6df0c2f-cf59-4cd3-b9da-3be772ceb48c', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'template', 'REPORT_GUIDE', '', '{"position":{"x":2270.033917728336,"y":-27.217682321506935},"type":"default"}', '{"kind":"template","outputSchema":{"type":"object","properties":{"template":{"type":"string"}}},"template":{"type":"tiptap","tiptap":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Create a comprehensive research report using the research findings. Guidelines:"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present the complete content directly without code blocks or formatting wrapper"}]},{"type":"paragraph","content":[{"type":"text","text":"- Do not add introductory remarks like \"Here''s the report\" or \"Report completed\""}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the title, summary, and complete content from findings"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MANDATORY REQUIREMENTS:"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include at least 3 relevant images"},{"type":"text","text":" using ![Description](image_url) format throughout the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include the mermaid diagram"},{"type":"text","text":" from research_findings using \\`\\`\\`mermaid format within the content flow"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST cite every source with URLs"},{"type":"text","text":" - format: [Source Title](URL)"}]},{"type":"paragraph","content":[{"type":"text","text":"- "},{"type":"text","marks":[{"type":"bold"}],"text":"MUST include source URLs"},{"type":"text","text":" for all data, statistics, and factual information"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"IMAGE USAGE:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Extract images from organized_data or research_findings content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place images strategically to support key points"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use format: ![Descriptive caption](image_url)"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include image source attribution when possible"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"MERMAID DIAGRAM:"}]},{"type":"paragraph","content":[{"type":"text","text":"- Use the diagram from research_findings.diagram"}]},{"type":"paragraph","content":[{"type":"text","text":"- Format: \\`\\`\\`mermaid [diagram_code] \\`\\`\\`"}]},{"type":"paragraph","content":[{"type":"text","text":"- Place within relevant content section, not as separate section"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure diagram enhances understanding of the topic"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"CONTENT STRUCTURE:"}]},{"type":"paragraph","content":[{"type":"text","text":"# [research_findings.title]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"[Include executive summary, key insights, detailed analysis with images and diagrams integrated naturally]"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","marks":[{"type":"bold"}],"text":"Confidence Level:"},{"type":"text","text":" [research_findings.confidence_level]/10"}]},{"type":"paragraph","content":[{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"- Include confidence level and key insights naturally within the content"}]},{"type":"paragraph","content":[{"type":"text","text":"- Ensure all sources are properly cited throughout"}]},{"type":"paragraph","content":[{"type":"text","text":"- Present as a professional research report ready for the user"}]}]}}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('f60a8e5d-bc96-4b7c-b4f7-27adb99058a4', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'llm', 'ANALYSIS', 'Analyze search results and determine research strategy', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"reference_sources":{"type":"array","items":{"type":"object","properties":{"url":{"type":"string","description":"Source URL"},"summary":{"type":"string","description":"Brief summary of the source content and relevance"}}},"description":"List of key reference sources from search results"},"important_url":{"type":"string","description":"Single most important URL for detailed content extraction"},"additional_search_instruction":{"type":"string","description":"Specific instruction for additional search to fill information gaps (empty string if none needed)"},"analysis_summary":{"type":"string","description":"Assessment of current research state and strategy"},"research_completeness":{"type":"number","description":"Score 1-10 rating how well initial search addresses research instruction"}}},"totalTokens":{"type":"number"}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"Analyze the search results in the context of the research instruction and determine the next steps."},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"Research Instruction: "},{"type":"mention","attrs":{"id":"23b93374-40fe-4397-8375-3ee3eacee22a","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"research_instruction\"]}"}},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Topic Area: "},{"type":"mention","attrs":{"id":"fa4b502f-3b13-4717-b4ae-675961527f20","label":"{\"nodeId\":\"62b79b46-b750-4998-a398-17268b448424\",\"path\":[\"topic\"]}"}}]},{"type":"paragraph","content":[{"type":"hardBreak"},{"type":"text","text":"---"},{"type":"hardBreak"},{"type":"text","text":"Search Results: "},{"type":"mention","attrs":{"id":"88493890-21ba-476a-a7c0-b6dd70a1d480","label":"{\"nodeId\":\"8f48f974-e7ab-417e-a987-393060416bbd\",\"path\":[\"tool_result\"]}"}},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"---"}]},{"type":"paragraph","content":[{"type":"text","text":"1. "},{"type":"text","marks":[{"type":"bold"}],"text":"important_url"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"YOU MUST SELECT AT LEAST ONE URL"},{"type":"text","text":" unless search results are completely irrelevant"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Choose the URL with the most comprehensive, authoritative information"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize: research papers, detailed reports, expert analyses, case studies, official websites"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Even if quality is moderate, select the BEST available option for detailed extraction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Only return empty string \"\" if absolutely no URLs provide any additional value"}]},{"type":"paragraph","content":[{"type":"text","text":"   - "},{"type":"text","marks":[{"type":"bold"}],"text":"Default behavior: ALWAYS select the most valuable URL from available results"},{"type":"hardBreak"}]},{"type":"paragraph","content":[{"type":"text","text":"  2. "},{"type":"text","marks":[{"type":"bold"}],"text":"additional_search_instruction"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Specific instruction for additional search to fill information gaps"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Should be a clear directive like \"Find recent statistics on AI adoption in hospitals\" or \"Search for regulatory challenges in healthcare AI implementation\""}]},{"type":"paragraph","content":[{"type":"text","text":"     - Based on what''s missing from initial search relative to research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Return empty string \"\" if initial search provides sufficient coverage"}]},{"type":"paragraph","content":[{"type":"text","text":"  3. "},{"type":"text","marks":[{"type":"bold"}],"text":"analysis_summary"},{"type":"text","text":" (string):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Assessment of how well current results address the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Identification of information gaps and missing perspectives"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Quality and credibility evaluation of found sources"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Strategy for completing the research objective"}]},{"type":"paragraph","content":[{"type":"text","text":"  4. "},{"type":"text","marks":[{"type":"bold"}],"text":"research_completeness"},{"type":"text","text":" (number 1-10):"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Rate how well the initial search addresses the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"     - Consider coverage, depth, and relevance to stated objectives"}]},{"type":"paragraph","content":[{"type":"text","text":"  Be strategic and selective. Focus on what''s truly needed to address the research instruction."},{"type":"hardBreak"},{"type":"hardBreak"},{"type":"text","text":"5. "},{"type":"text","marks":[{"type":"bold"}],"text":"reference_sources"},{"type":"text","text":" (array of objects):"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Extract 5-8 key reference sources from the search results"}]},{"type":"paragraph","content":[{"type":"text","text":"   - For each source provide: {\"url\": \"full_url\", \"summary\": \"brief description of content and relevance to research\"}"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Include diverse source types: official reports, news articles, academic papers, expert analyses"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Focus on sources that directly support the research instruction"}]},{"type":"paragraph","content":[{"type":"text","text":"   - Prioritize credible, authoritative sources"}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('62b79b46-b750-4998-a398-17268b448424', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'input', 'INPUT', '', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"topic":{"type":"string","description":"Subject area or domain (e.g., ''technology'', ''healthcare'', ''finance'', ''education'')"},"language":{"type":"string","description":"Preferred language for sources. eg. en (English), ko (Korean)"},"research_instruction":{"type":"string","default":"Comprehensive research instruction including what to research, why, and how to approach it. Example: ''Research the current state of AI in healthcare, focusing on diagnostic applications, regulatory challenges, and market adoption rates. I need this for a business proposal targeting hospital administrators.''"}},"required":["research_instruction"]}}', '2026-07-14 19:07:53.618384', '2026-07-14 19:07:53.618384');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('6af3b88b-e9de-48a7-bfa6-3cdf835fdd96', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'input', 'INPUT', 'Collect story requirements and preferences from user', '{"position":{"x":0,"y":0},"type":"default"}', '{"kind":"input","outputSchema":{"type":"object","properties":{"region":{"type":"string"}},"required":["region"]}}', '2026-07-14 19:07:53.653744', '2026-07-14 19:07:53.653744');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('e516eaff-a356-4f89-ba35-3f4ee5954721', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'http', 'WEATHER API', 'Get weather data from the API', '{"position":{"x":720,"y":0},"type":"default"}', '{"kind":"http","outputSchema":{"type":"object","properties":{"response":{"type":"object","properties":{"status":{"type":"number"},"statusText":{"type":"string"},"ok":{"type":"boolean"},"headers":{"type":"object"},"body":{"type":"string"},"duration":{"type":"number"},"size":{"type":"number"}}}}},"method":"GET","headers":[],"query":[{"key":"current","value":"temperature_2m"},{"key":"hourly","value":"temperature_2m"},{"key":"timezone","value":"auto"},{"key":"daily","value":"sunrise,sunset"},{"key":"latitude","value":{"nodeId":"fb22af2f-5cbc-49b4-8758-a269a08e5429","path":["answer","latitude"]}},{"key":"longitude","value":{"nodeId":"fb22af2f-5cbc-49b4-8758-a269a08e5429","path":["answer","longitude"]}}],"timeout":30000,"url":"https://api.open-meteo.com/v1/forecast"}', '2026-07-14 19:07:53.653744', '2026-07-14 19:07:53.653744');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('fb22af2f-5cbc-49b4-8758-a269a08e5429', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'llm', 'LLM', 'Get latitude and longitude from the LLM', '{"position":{"x":360,"y":0},"type":"default"}', '{"kind":"llm","outputSchema":{"type":"object","properties":{"answer":{"type":"object","properties":{"latitude":{"type":"number","description":"Geographical latitude of the location"},"longitude":{"type":"number","description":"Geographical longitude of the location"}}}}},"messages":[{"role":"user","content":{"type":"doc","content":[{"type":"paragraph","content":[{"type":"text","text":"What are the latitude and longitude of "},{"type":"mention","attrs":{"id":"e8d2314a-f81b-41e3-91ff-f235486a62f3","label":"{\"nodeId\":\"6af3b88b-e9de-48a7-bfa6-3cdf835fdd96\",\"path\":[\"region\"]}"}}]}]}}],"model":{"provider":"openai","model":"gpt-4.1"}}', '2026-07-14 19:07:53.653744', '2026-07-14 19:07:53.653744');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('fb177d47-6814-4c8f-a341-9da35243c860', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'note', 'NOTE', '# 🌦️ Regional Weather Lookup Workflow

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
', '{"position":{"x":-569.8790292584229,"y":-731.5434457770423},"type":"default"}', '{"kind":"note","outputSchema":{"type":"object","properties":{}}}', '2026-07-14 19:07:53.653744', '2026-07-14 19:07:53.653744');
INSERT INTO public.workflow_node (id, version, workflow_id, kind, name, description, ui_config, node_config, created_at, updated_at) VALUES ('cebe4669-ab44-4106-81c9-fafc808de599', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'output', 'OUTPUT', 'Output the weather data', '{"position":{"x":1080,"y":0},"type":"default"}', '{"kind":"output","outputSchema":{"type":"object","properties":{}},"outputData":[{"key":"result","source":{"nodeId":"e516eaff-a356-4f89-ba35-3f4ee5954721","path":["response","body"]}}]}', '2026-07-14 19:07:53.653744', '2026-07-14 19:07:53.653744');


--
-- Data for Name: hitl_sla_event; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: knowledge_base; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: prompt_version; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill; Type: TABLE DATA; Schema: public; Owner: -
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

INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c72d00af-c81e-44a3-8e6a-b02afad43553', 'global', NULL, 'team-manager', 'admin.auditLog', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.418295');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('80ecf12c-10a3-4264-a7fe-05bdb4d59440', 'global', NULL, 'team-manager', 'admin.featureFlags', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.423079');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('f78ecbfb-714a-415a-9dee-4ff5fdd148cf', 'global', NULL, 'team-manager', 'admin.identity', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.431009');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('bb557c8a-e9b9-425a-b14a-4e3d766bddb2', 'global', NULL, 'team-manager', 'admin.models', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.438445');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('f0c7f0e9-d265-4f57-a5c0-da637859b803', 'global', NULL, 'team-manager', 'admin.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.443851');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('2c609435-8415-41c7-8ed4-a3f2f2443fff', 'global', NULL, 'team-manager', 'admin.organizations', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.447826');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('54bdc01b-e162-4fbf-b664-a53387cbe8f1', 'global', NULL, 'team-manager', 'admin.platformSettings', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.455485');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('649a02b7-e02d-4d79-b0fd-fe8e9225310b', 'global', NULL, 'team-manager', 'admin.security', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.458363');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('81dc3ee8-4663-4ab9-b0ae-b8359e5041c0', 'global', NULL, 'team-manager', 'admin.subscriptions', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.463138');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('846319cc-08a6-487a-83c1-73e0c49e0c44', 'global', NULL, 'team-manager', 'admin.users', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.466957');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('fe7e3017-24c1-471c-b9d0-b1ef5b580dd1', 'global', NULL, 'team-manager', 'nav.rag', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.474581');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('ebcbe560-76e4-4000-a407-68a853211d22', 'global', NULL, 'team-manager', 'org.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.477436');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b96fdd3d-c643-43be-b806-ada1f76a5f58', 'global', NULL, 'team-manager', 'org.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.482743');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('8bad781e-a818-4b9e-94c3-54b90fe74d8f', 'global', NULL, 'team-manager', 'team.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.490143');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('25c493f7-63ba-45db-861a-08d349092d11', 'global', NULL, 'team-manager', 'workspace.mcp', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.496116');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('9654793d-1bc3-4872-a941-ce365ce7f63f', 'global', NULL, 'team-manager', 'workspace.promptTemplates', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.507471');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('26229f91-c70e-4556-a986-edc167a97550', 'global', NULL, 'user', 'admin.auditLog', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.513074');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('18dd4b2b-7053-4aad-9c8d-139b5b712722', 'global', NULL, 'user', 'admin.featureFlags', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.516112');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('dd7c2554-6b96-4653-8242-f44342dd9cec', 'global', NULL, 'user', 'admin.identity', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.521349');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('e92726d1-38c1-45ed-8e0b-873cbce008eb', 'global', NULL, 'user', 'admin.models', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.526502');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('e7d42a64-f532-41da-b19a-410d1303b3c7', 'global', NULL, 'user', 'admin.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.530338');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d6020d76-c2fe-4d6f-b707-d21235fe2956', 'global', NULL, 'user', 'admin.organizations', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.533233');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('7983d835-a2ff-4c20-8fa5-b7d5e66e8104', 'global', NULL, 'user', 'admin.platformSettings', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.537125');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b740c280-4622-4fa7-91da-63b5811afcd5', 'global', NULL, 'user', 'admin.security', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.542568');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('afc7ce24-89fc-453e-b1d5-f846a3c6e060', 'global', NULL, 'user', 'admin.subscriptions', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.550654');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c418e313-b5e1-4f93-88af-83a3c599a57a', 'global', NULL, 'user', 'admin.users', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.557781');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b046023e-fd29-4799-9858-dead83c1a68a', 'global', NULL, 'user', 'nav.rag', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.564693');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('7c38697e-38b3-4fa3-b263-c14c29135d96', 'global', NULL, 'user', 'org.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.567014');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('a987bb5d-fae0-48cd-8820-75c518d37107', 'global', NULL, 'user', 'org.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.571436');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('6ca6f37a-921e-49cb-bc6a-c2db8d2a419e', 'global', NULL, 'user', 'team.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.574014');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c60a580e-6c22-4b8a-9d13-9011512e1822', 'global', NULL, 'user', 'workspace.mcp', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.581549');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c4f5d491-e305-4547-80e2-d430a346cc09', 'global', NULL, 'user', 'workspace.promptTemplates', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.584528');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('fd3940b0-1ee5-4349-a7ca-4a9a82577e02', 'global', NULL, 'viewer', 'admin.auditLog', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.588103');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('d14cd616-9ad2-4308-bb04-a614dc361ba2', 'global', NULL, 'viewer', 'admin.featureFlags', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.591414');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('4be947c1-8bbe-490e-b6ea-991cc3168960', 'global', NULL, 'viewer', 'admin.identity', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.601175');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('392285b7-ef56-43a7-b11f-4249c21c45fc', 'global', NULL, 'viewer', 'admin.models', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.607311');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('6708a45e-af50-4629-9f9a-50c06ef86c68', 'global', NULL, 'viewer', 'admin.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.614151');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('b86bdd15-6b2b-4eb0-bb88-c4214db8ce37', 'global', NULL, 'viewer', 'admin.organizations', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.618541');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('41b59361-a661-483c-a30c-c91612d2f820', 'global', NULL, 'viewer', 'admin.platformSettings', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.62287');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('aebc25f8-df18-4916-a81e-08dde05f58aa', 'global', NULL, 'viewer', 'admin.security', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.625596');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('326c7e0a-024c-45c7-910c-82d8081d0414', 'global', NULL, 'viewer', 'admin.subscriptions', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.632789');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('361ffb6b-2ea8-4155-aba2-905326e21125', 'global', NULL, 'viewer', 'admin.users', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.636346');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('cd7c31bd-582a-4643-a43e-710fcf4fd77d', 'global', NULL, 'viewer', 'nav.rag', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.639621');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('df7ed082-30cc-4de0-83be-e6df5512f29f', 'global', NULL, 'viewer', 'org.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.642945');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('30aac965-37a4-48d3-ade6-c288b72caff1', 'global', NULL, 'viewer', 'org.monitor', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.647706');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('c581c5ef-0f6f-4fe0-abcf-eb6c59d02b9a', 'global', NULL, 'viewer', 'team.analytics', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.65337');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('1f4d5e10-c4ef-4597-818c-74e2d4a36609', 'global', NULL, 'viewer', 'workspace.mcp', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.657653');
INSERT INTO public.nav_visibility_override (id, scope, organization_id, role_key, nav_item_id, visible, updated_by, updated_at) VALUES ('25e72250-45e6-4e23-9fd4-9e981548c0d9', 'global', NULL, 'viewer', 'workspace.promptTemplates', false, '5b31c819-89b7-4d30-8e1d-747c5b736710', '2026-07-14 19:07:54.660923');


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

INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-07-14 19:07:53.889521', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, skills, workflows, MCP servers and knowledge bases.', true, NULL, '2026-07-14 19:07:53.905388', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-07-14 19:07:53.916748', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'read-only', 'Read-Only Pack', 'View access across every resource — pair with a custom role that may see but not change anything.', true, NULL, '2026-07-14 19:07:54.283049', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'ai-builder', 'AI Builder Pack', 'Build and manage agents, skills, workflows, MCP servers and knowledge bases.', true, NULL, '2026-07-14 19:07:54.296303', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group (id, organization_id, key, name, description, is_system, created_by, created_at, updated_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', '7f8c231d-5128-4059-b9eb-2daef779d1e9', 'people-manager', 'People Manager Pack', 'Invite, edit, suspend and remove members, and manage teams — without full org-manager authority.', true, NULL, '2026-07-14 19:07:54.30613', '2026-07-14 19:07:54.30613');


--
-- Data for Name: org_permission_group_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'members:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'teams:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'roles:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'settings:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'billing:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'audit:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'analytics:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'security:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'storage:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'knowledge:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'skills:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'agents:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'workflows:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'mcp:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'memory:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'models:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('5e2cf46e-251a-411b-bcbe-0d67e68d2fc5', 'policies:view', '2026-07-14 19:07:53.889521');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:create', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:edit', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:delete', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:approve', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:disable', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:transfer', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'agents:publish', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:create', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:edit', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:delete', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:deploy', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:approve', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:disable', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:transfer', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'skills:publish', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'workflows:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'workflows:create', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'workflows:edit', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'workflows:delete', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'mcp:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'mcp:create', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'mcp:edit', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'mcp:delete', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'knowledge:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'knowledge:create', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'knowledge:edit', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'knowledge:search', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('7d5db1ba-96eb-45da-b8cb-afea66f32de3', 'models:view', '2026-07-14 19:07:53.905388');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'members:view', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'members:invite', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'members:edit', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'members:remove', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'members:suspend', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'teams:view', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'teams:create', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'teams:edit', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'teams:delete', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('404b0c40-db9a-45d3-b80a-65795c3276f6', 'teams:manage_members', '2026-07-14 19:07:53.916748');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'members:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'teams:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'roles:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'settings:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'billing:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'audit:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'analytics:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'security:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'storage:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'knowledge:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'skills:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'agents:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'workflows:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'mcp:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'memory:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'models:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('359bebe6-f334-4465-bf20-b726d4480f93', 'policies:view', '2026-07-14 19:07:54.283049');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:create', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:edit', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:delete', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:approve', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:disable', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:transfer', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'agents:publish', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:create', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:edit', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:delete', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:deploy', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:approve', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:disable', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:transfer', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'skills:publish', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'workflows:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'workflows:create', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'workflows:edit', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'workflows:delete', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'mcp:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'mcp:create', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'mcp:edit', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'mcp:delete', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'knowledge:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'knowledge:create', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'knowledge:edit', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'knowledge:search', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('243e36e1-83de-463d-88a9-a1929d894e88', 'models:view', '2026-07-14 19:07:54.296303');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'members:view', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'members:invite', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'members:edit', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'members:remove', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'members:suspend', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'teams:view', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'teams:create', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'teams:edit', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'teams:delete', '2026-07-14 19:07:54.30613');
INSERT INTO public.org_permission_group_item (group_id, permission, created_at) VALUES ('c724710f-7f9f-4088-82c3-42a053f5bdb2', 'teams:manage_members', '2026-07-14 19:07:54.30613');


--
-- Data for Name: org_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_provider_credential; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: organization_member; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('5ee0996b-5fc5-44c6-85c3-8cdb2fdf5ec5', '26f1b0ef-60c0-49c8-9fb7-d6baac020351', '5b31c819-89b7-4d30-8e1d-747c5b736710', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-07-14 19:07:53.766542');
INSERT INTO public.organization_member (id, organization_id, user_id, role, status, source, external_id, suspended_at, suspended_by, joined_at) VALUES ('f6334d9f-761f-41b5-ab14-239065ae333e', '7f8c231d-5128-4059-b9eb-2daef779d1e9', '5b31c819-89b7-4d30-8e1d-747c5b736710', 'owner', 'active', 'direct', NULL, NULL, NULL, '2026-07-14 19:07:54.06676');


--
-- Data for Name: org_resource_grant; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_assignment; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: org_role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'members:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'members:invite', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'members:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'members:remove', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'members:suspend', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'teams:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'teams:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'teams:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'teams:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'teams:manage_members', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'roles:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'roles:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'roles:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'roles:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'roles:assign', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'settings:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'settings:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'billing:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'billing:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'audit:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'analytics:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'security:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'security:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'storage:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'storage:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:transfer', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:search', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:publish', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'knowledge:admin', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:deploy', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:approve', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:disable', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:transfer', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'skills:publish', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:approve', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:disable', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:transfer', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'agents:publish', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'workflows:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'workflows:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'workflows:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'workflows:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'mcp:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'mcp:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'mcp:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'mcp:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'memory:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'memory:create', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'memory:edit', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'memory:delete', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'memory:share', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'models:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'models:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'policies:view', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95fcde52-f214-4801-ab6a-f5658c3469d9', 'policies:manage', '2026-07-14 19:07:53.818194');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'agents:delete', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'agents:approve', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'agents:disable', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'agents:transfer', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'agents:publish', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'workflows:delete', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'mcp:edit', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'mcp:delete', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:create', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:edit', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:delete', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:deploy', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:approve', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:disable', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:transfer', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'skills:publish', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'models:manage', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'memory:create', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'memory:edit', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'memory:delete', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('4845e4f2-9c28-49ec-8322-a2e5067ea627', 'memory:share', '2026-07-14 19:07:53.83329');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95c02282-76e7-492c-a1cf-288206830eab', 'security:manage', '2026-07-14 19:07:53.84687');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95c02282-76e7-492c-a1cf-288206830eab', 'policies:manage', '2026-07-14 19:07:53.84687');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95c02282-76e7-492c-a1cf-288206830eab', 'members:edit', '2026-07-14 19:07:53.84687');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('95c02282-76e7-492c-a1cf-288206830eab', 'members:suspend', '2026-07-14 19:07:53.84687');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:create', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:edit', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:delete', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:transfer', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:admin', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('a43c5327-9947-4b85-abfa-6bf2c422d539', 'knowledge:publish', '2026-07-14 19:07:53.859994');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9e59748e-4a47-43c0-bc76-31c0f97fe4ef', 'billing:manage', '2026-07-14 19:07:53.865213');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f424f818-f9b8-4b64-be88-8b35cf6e1d0b', 'teams:create', '2026-07-14 19:07:53.870101');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f424f818-f9b8-4b64-be88-8b35cf6e1d0b', 'teams:edit', '2026-07-14 19:07:53.870101');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f424f818-f9b8-4b64-be88-8b35cf6e1d0b', 'teams:manage_members', '2026-07-14 19:07:53.870101');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('f424f818-f9b8-4b64-be88-8b35cf6e1d0b', 'members:invite', '2026-07-14 19:07:53.870101');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'agents:create', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'agents:edit', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'workflows:create', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'workflows:edit', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'mcp:create', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'memory:create', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('3a5e43c5-09a8-4bc3-97fc-32c0dacfed9e', 'memory:edit', '2026-07-14 19:07:53.875145');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'members:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'teams:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'roles:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'settings:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'billing:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'audit:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'analytics:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'security:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'storage:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'knowledge:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'skills:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'agents:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'workflows:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'mcp:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'memory:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'models:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'policies:view', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ef48cd4a-64d5-49f2-aa76-00155dc41abe', 'knowledge:search', '2026-07-14 19:07:53.880343');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'members:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'members:invite', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'members:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'members:remove', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'members:suspend', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'teams:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'teams:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'teams:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'teams:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'teams:manage_members', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'roles:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'roles:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'roles:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'roles:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'roles:assign', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'settings:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'settings:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'billing:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'billing:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'audit:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'analytics:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'security:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'security:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'storage:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'storage:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:transfer', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:search', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:publish', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'knowledge:admin', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:deploy', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:approve', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:disable', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:transfer', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'skills:publish', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:approve', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:disable', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:transfer', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'agents:publish', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'workflows:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'workflows:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'workflows:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'workflows:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'mcp:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'mcp:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'mcp:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'mcp:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'memory:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'memory:create', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'memory:edit', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'memory:delete', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'memory:share', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'models:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'models:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'policies:view', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('18e0fad4-609e-4d55-ac68-0fb88f162ff9', 'policies:manage', '2026-07-14 19:07:54.213031');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'agents:delete', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'agents:approve', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'agents:disable', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'agents:transfer', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'agents:publish', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'workflows:delete', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'mcp:edit', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'mcp:delete', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:create', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:edit', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:delete', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:deploy', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:approve', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:disable', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:transfer', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'skills:publish', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'models:manage', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'memory:create', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'memory:edit', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'memory:delete', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('5d84bf0b-968b-4a8f-a3f1-633de70300af', 'memory:share', '2026-07-14 19:07:54.225774');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2438f0d2-e301-4406-8cdc-ea97dd88b6cf', 'security:manage', '2026-07-14 19:07:54.232029');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2438f0d2-e301-4406-8cdc-ea97dd88b6cf', 'policies:manage', '2026-07-14 19:07:54.232029');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2438f0d2-e301-4406-8cdc-ea97dd88b6cf', 'members:edit', '2026-07-14 19:07:54.232029');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('2438f0d2-e301-4406-8cdc-ea97dd88b6cf', 'members:suspend', '2026-07-14 19:07:54.232029');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:create', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:edit', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:delete', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:transfer', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:admin', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('9025aa0f-5404-4e2c-9c83-667320777989', 'knowledge:publish', '2026-07-14 19:07:54.240862');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('ee2f673f-b3a8-4cdd-9ba0-49eea73f84c6', 'billing:manage', '2026-07-14 19:07:54.248032');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('fb56fc01-2d0f-40db-aaf0-9e2a29f617c9', 'teams:create', '2026-07-14 19:07:54.256037');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('fb56fc01-2d0f-40db-aaf0-9e2a29f617c9', 'teams:edit', '2026-07-14 19:07:54.256037');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('fb56fc01-2d0f-40db-aaf0-9e2a29f617c9', 'teams:manage_members', '2026-07-14 19:07:54.256037');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('fb56fc01-2d0f-40db-aaf0-9e2a29f617c9', 'members:invite', '2026-07-14 19:07:54.256037');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'agents:create', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'agents:edit', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'workflows:create', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'workflows:edit', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'mcp:create', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'memory:create', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('d0c9b7be-0023-4e50-87bf-79d9bc9f2231', 'memory:edit', '2026-07-14 19:07:54.26728');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'members:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'teams:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'roles:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'settings:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'billing:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'audit:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'analytics:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'security:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'storage:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'knowledge:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'skills:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'agents:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'workflows:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'mcp:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'memory:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'models:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'policies:view', '2026-07-14 19:07:54.272472');
INSERT INTO public.org_role_permission (role_id, permission, created_at) VALUES ('7bfed3b6-8c60-4a27-95f3-08baf1c1850a', 'knowledge:search', '2026-07-14 19:07:54.272472');


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
-- Data for Name: session_policy; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: skill_team; Type: TABLE DATA; Schema: public; Owner: -
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
-- Data for Name: tool; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('cf9b4224-6663-430a-b926-39b4123c26f3', 'Python Code Runner', 'Execute Python scripts in the browser via Pyodide. Supports numpy, pandas, matplotlib, scipy. Guides correct usage of the sandboxed environment.', '# Python Code Runner

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

## When to Use This Tool

Invoke when the user asks to:
- Run, execute, or test Python code
- Perform calculations or data processing
- Prototype algorithms or functions
- Verify Python syntax or logic', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{python,execution,scripting,pyodide}', '{"type":"emoji","value":"🐍"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);
INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('c1ac651a-6bc5-439a-8a8b-fb4a0dd8153f', 'Data Analysis — Pandas & NumPy', 'Analyze datasets with pandas and numpy in the browser. CSV loading via StringIO or URL fetch, descriptive stats, groupby, correlation, and more.', '# Data Analysis — Pandas & NumPy

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

## When to Use This Tool

Invoke when the user asks to:
- Analyze CSV or tabular data
- Compute summary statistics or aggregations
- Filter, sort, or transform datasets
- Find correlations or patterns in data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{pandas,numpy,data-analysis,statistics,csv}', '{"type":"emoji","value":"📊"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);
INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('c2259301-4677-4c25-87e2-11f7c1ecf67a', 'Data Visualization — Matplotlib', 'Create charts and plots with matplotlib in the Pyodide sandbox. Includes agg backend setup and all common chart types.', '# Data Visualization — Matplotlib

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

## When to Use This Tool

Invoke when the user asks to:
- Plot, chart, or visualize data
- Create graphs (line, bar, scatter, histogram, pie, heatmap)
- Generate figures or diagrams from data', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{matplotlib,visualization,charts,plots}', '{"type":"emoji","value":"📈"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);
INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('48086daf-cb9b-4494-ae85-611ef526adcb', 'Math & Statistics Calculator', 'Perform advanced math, statistics, and scientific computing with numpy and scipy. Covers hypothesis tests, linear algebra, integration, optimization, and distributions.', '# Math & Statistics Calculator

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

## When to Use This Tool

Invoke when the user asks to:
- Compute statistics, probabilities, or p-values
- Solve equations or linear algebra problems
- Perform numerical integration or optimization
- Work with probability distributions', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'analysis', '{math,statistics,numpy,scipy,computation}', '{"type":"emoji","value":"🧮"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);
INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('925dd801-9924-493f-937d-4db613a9f058', 'Text & File Processing', 'Parse and transform text, JSON, CSV, and structured data in Python. Covers regex extraction, word frequency, string transforms, and URL text fetching.', '# Text & File Processing

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

## When to Use This Tool

Invoke when the user asks to:
- Parse or extract data from JSON, CSV, or plain text
- Apply regex patterns for search or extraction
- Count word frequencies or analyze text
- Transform or reformat strings
- Fetch and process text from a URL', '{"allowed-tools":["python-execution"],"user-invocable":true}', 'development', '{text,parsing,csv,json,regex}', '{"type":"emoji","value":"📝"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);
INSERT INTO public.tool (id, name, description, content, frontmatter, category, tags, icon, user_id, organization_id, visibility, version, install_count, is_published, submission_status, created_at, updated_at, deleted_at) VALUES ('818b89b3-19f0-490c-bdba-46b0fc896bb9', 'Server-Side Python Executor', 'Run real Python (or shell) commands on the server backend using the bash-execution tool. Unlike Pyodide, this uses the actual system Python with full stdlib, file I/O, pip-installed packages, and no CORS restrictions.', '# Server-Side Python Executor

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
', '{"allowed-tools":["bash-execution"],"user-invocable":true}', 'development', '{python,bash,server,execution,code}', '{"type":"emoji","value":"🖥️"}', '5b31c819-89b7-4d30-8e1d-747c5b736710', NULL, 'public', '1.0.0', 0, true, 'none', '2026-07-14 19:07:57.464888', '2026-07-14 19:07:57.464888', NULL);


--
-- Data for Name: tool_install; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tool_rating; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: tool_submission; Type: TABLE DATA; Schema: public; Owner: -
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

INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('0798917c-d7fd-401c-8065-84a02046e483', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'ddbaa938-d366-4312-bedb-ba211a2b99b8', '8ec7aa2a-1890-40a6-833e-828d623c5a27', '{"sourceHandle":"right","targetHandle":"left"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('3ad14de8-80f9-4ced-8c5d-09cb3633af9a', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '598b5a99-e184-4bb1-9b79-8ff54b6f070e', '34fb5219-d9b9-4cd2-a64c-c18c81bb881a', '{"sourceHandle":"right","targetHandle":"left"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('2619a8cf-4eb4-4d8c-b6d1-5a887c5d978a', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '8ec7aa2a-1890-40a6-833e-828d623c5a27', 'b6df0c2f-cf59-4cd3-b9da-3be772ceb48c', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('84b3c305-59e2-4440-93e0-a9c71c8dffbc', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'f60a8e5d-bc96-4b7c-b4f7-27adb99058a4', '450f9ad7-663c-4516-a4fb-b1a52fa8a287', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('ac546733-6cc6-48d1-a736-d73563327454', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '8f48f974-e7ab-417e-a987-393060416bbd', 'f60a8e5d-bc96-4b7c-b4f7-27adb99058a4', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('42961e02-4b4b-485f-af71-3181ed8b1d9c', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '568679b6-707e-4774-8d85-062154445213', '8ec7aa2a-1890-40a6-833e-828d623c5a27', '{"sourceHandle":"if","targetHandle":"left"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('248cc305-0f4b-4ce1-9cbc-042d888047f6', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '450f9ad7-663c-4516-a4fb-b1a52fa8a287', 'ddbaa938-d366-4312-bedb-ba211a2b99b8', '{"sourceHandle":"if"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('be79997b-a748-4509-ba74-bc6d4fb521e2', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '568679b6-707e-4774-8d85-062154445213', '4cd73d2e-cb7e-4dfb-b259-28c149256bc1', '{"sourceHandle":"else","targetHandle":"left"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('c27b6412-4768-44ca-ad22-0cf1ffdcd780', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'b6df0c2f-cf59-4cd3-b9da-3be772ceb48c', '34fb5219-d9b9-4cd2-a64c-c18c81bb881a', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('5b30e12d-448e-4cb7-9793-f747139c9f13', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '62b79b46-b750-4998-a398-17268b448424', '8f48f974-e7ab-417e-a987-393060416bbd', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('c7bc3817-90dd-43b1-b89d-ecb92bf34e47', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '4cd73d2e-cb7e-4dfb-b259-28c149256bc1', '8ec7aa2a-1890-40a6-833e-828d623c5a27', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('4ecabfed-49ec-4252-b57a-70361677cc17', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '450f9ad7-663c-4516-a4fb-b1a52fa8a287', '8ec7aa2a-1890-40a6-833e-828d623c5a27', '{"sourceHandle":"else","targetHandle":"left"}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('8c7281c4-4567-48fe-b329-6809aff687db', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', 'f60a8e5d-bc96-4b7c-b4f7-27adb99058a4', '568679b6-707e-4774-8d85-062154445213', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('bddf381c-a6d5-44f9-864c-c4181e4a595a', '0.1.0', 'd7984ddd-9ebc-4421-bcde-b202ae792d5a', '8ec7aa2a-1890-40a6-833e-828d623c5a27', '598b5a99-e184-4bb1-9b79-8ff54b6f070e', '{}', '2026-07-14 19:07:53.635461');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('16482deb-7cb9-4e30-b6fa-0e1920b980de', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', '6af3b88b-e9de-48a7-bfa6-3cdf835fdd96', 'fb22af2f-5cbc-49b4-8758-a269a08e5429', '{}', '2026-07-14 19:07:53.658392');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('ba93e617-5313-4214-a623-4feca8b64610', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'fb22af2f-5cbc-49b4-8758-a269a08e5429', 'e516eaff-a356-4f89-ba35-3f4ee5954721', '{}', '2026-07-14 19:07:53.658392');
INSERT INTO public.workflow_edge (id, version, workflow_id, source, target, ui_config, created_at) VALUES ('0447aa55-b4ed-4905-ada3-8995fa703011', '0.1.0', '61c31733-e2f0-45da-8aa5-fd6736967c66', 'e516eaff-a356-4f89-ba35-3f4ee5954721', 'cebe4669-ab44-4106-81c9-fafc808de599', '{}', '2026-07-14 19:07:53.658392');


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

\unrestrict V3hyJVmQbxun8RgLC0xo0DV0sRVQCSRaLbvjQTWCT2uyTiQ2xCp5xkyK0hhx6uw


SET session_replication_role = DEFAULT;
