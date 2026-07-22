--
-- PostgreSQL database dump
--

\restrict GVShlZ7r7B4dEMdPpZVN38Le0vVTdeKUByREJr4mKdCogwxwM1QOmIQKI4GJPWA

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
-- Name: drizzle; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA drizzle;


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: __drizzle_migrations; Type: TABLE; Schema: drizzle; Owner: -
--

CREATE TABLE drizzle.__drizzle_migrations (
    id integer NOT NULL,
    hash text NOT NULL,
    created_at bigint
);


--
-- Name: __drizzle_migrations_id_seq; Type: SEQUENCE; Schema: drizzle; Owner: -
--

CREATE SEQUENCE drizzle.__drizzle_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: __drizzle_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: drizzle; Owner: -
--

ALTER SEQUENCE drizzle.__drizzle_migrations_id_seq OWNED BY drizzle.__drizzle_migrations.id;


--
-- Name: a2a_capability_card; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.a2a_capability_card (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    organization_id uuid,
    user_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    version text DEFAULT '1.0'::text NOT NULL,
    skills json,
    tools json,
    model text,
    reasoning_mode text,
    allowed_agent_ids json,
    visibility character varying,
    governance_status character varying,
    invocable boolean DEFAULT true NOT NULL,
    card json NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: a2a_task; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.a2a_task (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    user_id uuid NOT NULL,
    agent_id uuid,
    parent_task_id uuid,
    orchestration_run_id uuid,
    job_id text,
    state character varying DEFAULT 'submitted'::character varying NOT NULL,
    objective text DEFAULT ''::text NOT NULL,
    input json,
    result json,
    error text,
    usage json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id text NOT NULL,
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    access_token text,
    refresh_token text,
    id_token text,
    access_token_expires_at timestamp without time zone,
    refresh_token_expires_at timestamp without time zone,
    scope text,
    password text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: admin_audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_audit_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor_id uuid,
    target_user_id uuid,
    organization_id uuid,
    action character varying NOT NULL,
    metadata jsonb,
    event_signature text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agent; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    icon json,
    user_id uuid NOT NULL,
    organization_id uuid,
    instructions json,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    install_count integer DEFAULT 0 NOT NULL,
    governance_status character varying DEFAULT 'approved'::character varying NOT NULL,
    reviewed_by uuid,
    reviewed_at timestamp without time zone,
    governance_note text,
    allowed_models json,
    allowed_kb_ids json,
    team_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    CONSTRAINT agent_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['public'::character varying, 'private'::character varying, 'readonly'::character varying, 'team'::character varying, 'organization'::character varying, 'official'::character varying])::text[])))
);


--
-- Name: agent_deployment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_deployment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    environment character varying DEFAULT 'production'::character varying NOT NULL,
    model_override text,
    tool_overrides jsonb,
    system_prompt_override text,
    organization_id uuid,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agent_install; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_install (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    user_id uuid NOT NULL,
    installed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agent_memory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_memory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    content text NOT NULL,
    category text DEFAULT 'context'::text,
    embedding public.vector(1536),
    importance real DEFAULT 1 NOT NULL,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agent_rating; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_rating (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    user_id uuid NOT NULL,
    rating integer NOT NULL,
    review text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: agent_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    agent_id uuid NOT NULL,
    version_number integer NOT NULL,
    label text,
    snapshot json NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: apikey; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.apikey (
    id text NOT NULL,
    name text,
    start text,
    prefix text,
    key text NOT NULL,
    user_id uuid NOT NULL,
    refill_interval integer,
    refill_amount integer,
    last_refill_at timestamp without time zone,
    enabled boolean DEFAULT true NOT NULL,
    rate_limit_enabled boolean DEFAULT false NOT NULL,
    rate_limit_time_window integer,
    rate_limit_max integer,
    request_count integer DEFAULT 0 NOT NULL,
    remaining integer,
    last_request timestamp without time zone,
    expires_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    permissions text,
    metadata text
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value text NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: archive; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archive (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    user_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: archive_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archive_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    archive_id uuid NOT NULL,
    item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: bookmark; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmark (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    item_id uuid NOT NULL,
    item_type character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_export (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    exporter_id uuid NOT NULL,
    original_thread_id uuid,
    messages json NOT NULL,
    exported_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: chat_export_comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_export_comment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    export_id uuid NOT NULL,
    author_id uuid NOT NULL,
    parent_id uuid,
    content json NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_message; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message (
    id text NOT NULL,
    thread_id uuid NOT NULL,
    role text NOT NULL,
    parts json[],
    metadata json,
    is_compaction_summary boolean DEFAULT false NOT NULL,
    moderation_flagged boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_message_embedding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_embedding (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_id text NOT NULL,
    thread_id uuid NOT NULL,
    user_id uuid NOT NULL,
    embedding public.vector(1536),
    text_content text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_thread; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_thread (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    pinned boolean DEFAULT false NOT NULL,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: conditional_access_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conditional_access_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    name text NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    effect character varying DEFAULT 'require_mfa'::character varying NOT NULL,
    definition jsonb NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: cron_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cron_job (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    schedule text NOT NULL,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    target_type text NOT NULL,
    target_id uuid,
    payload json DEFAULT '{}'::json,
    trigger_type text DEFAULT 'cron'::text NOT NULL,
    interval_seconds integer,
    event_type text,
    webhook_token text,
    trigger_config json,
    max_retries integer DEFAULT 0 NOT NULL,
    retry_backoff_ms integer DEFAULT 1000 NOT NULL,
    retry_strategy text DEFAULT 'fixed'::text NOT NULL,
    sla_seconds integer,
    sla_action text,
    notify_on json,
    notify_channels json,
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    CONSTRAINT cron_job_trigger_type_check CHECK ((trigger_type = ANY (ARRAY['cron'::text, 'interval'::text, 'event'::text, 'webhook'::text, 'a2a'::text])))
);


--
-- Name: cron_run_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cron_run_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cron_job_id uuid NOT NULL,
    status text NOT NULL,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finished_at timestamp without time zone,
    duration_ms integer,
    output text,
    output_truncated boolean DEFAULT false NOT NULL,
    error text,
    token_usage json,
    attempt integer DEFAULT 1 NOT NULL,
    trigger_type text,
    triggered_by text,
    sla_breached boolean DEFAULT false NOT NULL
);


--
-- Name: document_acl; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_acl (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source_key text NOT NULL,
    grantee_type text NOT NULL,
    grantee_id uuid NOT NULL,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: document_chunk; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_chunk (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content text NOT NULL,
    embedding public.vector(1536),
    source_filename text NOT NULL,
    source_mime_type text,
    source_key text,
    chunk_index integer DEFAULT 0 NOT NULL,
    metadata json DEFAULT '{}'::json,
    language character varying(8),
    user_id uuid,
    organization_id uuid,
    thread_id uuid,
    content_tsv tsvector,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: email_otp; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_otp (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    code_hash text NOT NULL,
    purpose text DEFAULT 'step_up'::text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    consumed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: embedding_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.embedding_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    user_id uuid,
    provider text NOT NULL,
    model text NOT NULL,
    dims integer NOT NULL,
    connection_kind character varying,
    endpoint text,
    deployment text,
    api_version text,
    region character varying,
    secret_encrypted text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: error_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message text NOT NULL,
    stack text,
    route text,
    user_id uuid,
    severity character varying DEFAULT 'error'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: group_mapping; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_mapping (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    provider text,
    external_group text NOT NULL,
    team_id uuid,
    team_role character varying DEFAULT 'member'::character varying NOT NULL,
    role_id uuid,
    role_team_scoped boolean DEFAULT false NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: hitl_assignment_cursor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hitl_assignment_cursor (
    workflow_id uuid NOT NULL,
    node_id uuid NOT NULL,
    cursor integer DEFAULT 0 NOT NULL,
    organization_id uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: hitl_sla_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hitl_sla_event (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    execution_id uuid NOT NULL,
    task_id uuid NOT NULL,
    workflow_id uuid NOT NULL,
    node_id uuid NOT NULL,
    rule_action character varying(16) NOT NULL,
    fired_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    sla_minutes integer,
    breached boolean DEFAULT false NOT NULL,
    organization_id uuid,
    user_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: inference_request_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inference_request_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid NOT NULL,
    trace_id uuid NOT NULL,
    user_id uuid,
    source character varying DEFAULT 'unknown'::character varying NOT NULL,
    provider text NOT NULL,
    model_id text NOT NULL,
    input_tokens integer DEFAULT 0 NOT NULL,
    output_tokens integer DEFAULT 0 NOT NULL,
    total_tokens integer DEFAULT 0 NOT NULL,
    estimated_cost_usd real,
    latency_ms integer,
    finish_reason text,
    fallback_used boolean DEFAULT false NOT NULL,
    primary_provider text,
    error_code text,
    flagged boolean DEFAULT false NOT NULL,
    agent_id uuid,
    organization_id uuid,
    team_id uuid,
    skill_id uuid,
    run_id uuid,
    run_kind character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ingestion_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingestion_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    user_id uuid,
    document_id uuid,
    knowledge_base_id uuid,
    source_type text NOT NULL,
    source_ref text,
    operation text NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    progress integer DEFAULT 0 NOT NULL,
    error text,
    mime_type text,
    filename text,
    stats jsonb DEFAULT '{}'::jsonb NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone
);


--
-- Name: integration_connector; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_connector (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    connector_type character varying NOT NULL,
    name character varying NOT NULL,
    display_name character varying,
    credentials jsonb DEFAULT '{}'::jsonb NOT NULL,
    config jsonb DEFAULT '{}'::jsonb NOT NULL,
    mcp_server_id uuid,
    enabled boolean DEFAULT true NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    last_error text,
    last_tested_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: integration_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_event (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    connector_id uuid NOT NULL,
    direction character varying NOT NULL,
    event_type character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    error text,
    processed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: integration_sync_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.integration_sync_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    connector_id uuid NOT NULL,
    knowledge_base_id uuid,
    sync_schedule character varying DEFAULT '0 * * * *'::character varying NOT NULL,
    sync_filter jsonb DEFAULT '{}'::jsonb,
    enabled boolean DEFAULT true NOT NULL,
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: invoice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    subscription_id uuid,
    amount_due integer DEFAULT 0 NOT NULL,
    currency character varying(3) DEFAULT 'usd'::character varying NOT NULL,
    status character varying DEFAULT 'open'::character varying NOT NULL,
    issued_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    paid_at timestamp without time zone,
    external_invoice_id text,
    hosted_url text
);


--
-- Name: knowledge_audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    user_id uuid,
    resource_type text NOT NULL,
    resource_id uuid NOT NULL,
    action text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_base; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_base (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    organization_id uuid,
    user_id uuid,
    team_id uuid,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    governance_status character varying DEFAULT 'approved'::character varying NOT NULL,
    reviewed_by uuid,
    reviewed_at timestamp without time zone,
    governance_note text,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT knowledge_base_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['private'::character varying, 'team'::character varying, 'org'::character varying, 'public'::character varying])::text[])))
);


--
-- Name: knowledge_base_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_base_document (
    knowledge_base_id uuid NOT NULL,
    source_key text NOT NULL,
    added_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    knowledge_base_id uuid,
    source_key text NOT NULL,
    source_filename text NOT NULL,
    source_mime_type text,
    title text,
    organization_id uuid,
    user_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    chunk_count integer DEFAULT 0 NOT NULL,
    file_size bigint,
    version integer DEFAULT 1 NOT NULL,
    content_hash text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: knowledge_embedding_migration_state; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_embedding_migration_state (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    user_id uuid,
    backfilled_at timestamp without time zone,
    verified_at timestamp without time zone,
    read_from_new boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_embeddings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_embeddings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    chunk_id uuid,
    document_id uuid,
    organization_id uuid,
    user_id uuid,
    embedding public.vector(1536),
    embedding_768 public.vector(768),
    embedding_1024 public.vector(1024),
    embedding_3072 public.halfvec(3072),
    embedding_model text DEFAULT 'text-embedding-3-small'::text NOT NULL,
    dims integer DEFAULT 1536 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_entity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_entity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name text NOT NULL,
    normalized_name text NOT NULL,
    type text DEFAULT 'OTHER'::text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_entity_mention; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_entity_mention (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entity_id uuid NOT NULL,
    chunk_id uuid NOT NULL,
    source_key text,
    organization_id uuid,
    user_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_metadata (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_type text NOT NULL,
    resource_id uuid NOT NULL,
    organization_id uuid,
    user_id uuid,
    key text NOT NULL,
    value text,
    data_type text DEFAULT 'string'::text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: knowledge_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.knowledge_versions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    knowledge_base_id uuid,
    document_id uuid,
    organization_id uuid,
    user_id uuid,
    version_number integer NOT NULL,
    label text,
    snapshot jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: label_access_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.label_access_policy (
    label_id uuid NOT NULL,
    model_ids jsonb,
    mcp_server_ids jsonb,
    tool_permissions jsonb,
    auth_limit integer,
    chat_limit integer,
    api_limit integer,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ldap_directory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ldap_directory (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name text NOT NULL,
    server_url text NOT NULL,
    bind_dn text NOT NULL,
    base_dn text NOT NULL,
    user_search_filter text DEFAULT '(sAMAccountName={0})'::text NOT NULL,
    group_attribute text DEFAULT 'memberOf'::text NOT NULL,
    use_ad_matching_rule boolean DEFAULT false NOT NULL,
    claim_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: marketplace_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_category (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: marketplace_fork; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_fork (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fork_resource_type character varying NOT NULL,
    fork_resource_id uuid NOT NULL,
    source_listing_id uuid,
    source_resource_type character varying NOT NULL,
    source_resource_id uuid NOT NULL,
    forked_by uuid,
    organization_id uuid,
    forked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: marketplace_install; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_install (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    listing_id uuid NOT NULL,
    resource_type character varying NOT NULL,
    resource_id uuid NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    installed_version text,
    installed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: marketplace_listing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_listing (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_type character varying NOT NULL,
    resource_id uuid NOT NULL,
    organization_id uuid,
    scope character varying DEFAULT 'organization'::character varying NOT NULL,
    team_id uuid,
    name text NOT NULL,
    description text,
    icon json,
    tags text[],
    version text,
    status character varying DEFAULT 'pending_review'::character varying NOT NULL,
    category_id uuid,
    featured boolean DEFAULT false NOT NULL,
    install_count integer DEFAULT 0 NOT NULL,
    submitted_by uuid,
    submitted_at timestamp without time zone,
    reviewed_by uuid,
    reviewed_at timestamp without time zone,
    rejection_reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT marketplace_listing_resource_type_check CHECK (((resource_type)::text = ANY ((ARRAY['agent'::character varying, 'tool'::character varying, 'workflow'::character varying, 'skill'::character varying, 'prompt'::character varying, 'knowledge_pack'::character varying])::text[]))),
    CONSTRAINT marketplace_listing_scope_check CHECK (((scope)::text = ANY ((ARRAY['personal'::character varying, 'team'::character varying, 'organization'::character varying, 'enterprise'::character varying, 'public'::character varying])::text[])))
);


--
-- Name: marketplace_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketplace_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    listing_id uuid NOT NULL,
    resource_type character varying NOT NULL,
    resource_id uuid NOT NULL,
    version_number integer NOT NULL,
    label text,
    snapshot jsonb NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: mcp_oauth_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_oauth_session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mcp_server_id uuid NOT NULL,
    server_url text NOT NULL,
    client_info json,
    tokens json,
    code_verifier text,
    state text,
    user_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: mcp_server; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_server (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    config json NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: mcp_server_custom_instructions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_server_custom_instructions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    mcp_server_id uuid NOT NULL,
    prompt text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: mcp_server_tool_custom_instructions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_server_tool_custom_instructions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    tool_name text NOT NULL,
    mcp_server_id uuid NOT NULL,
    prompt text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: mcp_tool_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mcp_tool_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    server_id uuid,
    primitive_kind character varying DEFAULT 'tool'::character varying NOT NULL,
    tool_name text,
    effect character varying NOT NULL,
    roles text[] DEFAULT '{}'::text[] NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: memory_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.memory_entry (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    scope character varying NOT NULL,
    memory_type character varying DEFAULT 'semantic'::character varying NOT NULL,
    owner_user_id uuid,
    agent_id uuid,
    team_id uuid,
    session_key text,
    key text,
    content text NOT NULL,
    metadata jsonb,
    embedding public.vector(1536),
    importance real DEFAULT 1 NOT NULL,
    expires_at timestamp without time zone,
    last_accessed_at timestamp without time zone,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT memory_entry_scope_check CHECK (((scope)::text = ANY ((ARRAY['working'::character varying, 'session'::character varying, 'long_term'::character varying, 'team'::character varying, 'organization'::character varying])::text[])))
);


--
-- Name: model_catalog_custom_model; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_catalog_custom_model (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider text NOT NULL,
    model text NOT NULL,
    version text,
    context_window integer DEFAULT 0 NOT NULL,
    vision boolean DEFAULT false NOT NULL,
    reasoning boolean DEFAULT false NOT NULL,
    function_calling boolean DEFAULT false NOT NULL,
    streaming boolean DEFAULT true NOT NULL,
    embeddings boolean DEFAULT false NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: model_catalog_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_catalog_metadata (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider text NOT NULL,
    model text NOT NULL,
    model_version text,
    embeddings boolean DEFAULT false NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    deprecation_status character varying DEFAULT 'active'::character varying NOT NULL,
    deprecated_at timestamp without time zone,
    sunset_at timestamp without time zone,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: model_pricing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.model_pricing (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    model text NOT NULL,
    provider text NOT NULL,
    input_cost_per_1m real DEFAULT 0 NOT NULL,
    output_cost_per_1m real DEFAULT 0 NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: nav_visibility_override; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nav_visibility_override (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope character varying NOT NULL,
    organization_id uuid,
    role_key character varying NOT NULL,
    nav_item_id character varying NOT NULL,
    visible boolean NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT nav_visibility_override_scope_check CHECK (((scope)::text = ANY ((ARRAY['global'::character varying, 'org'::character varying])::text[])))
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    type text NOT NULL,
    title text NOT NULL,
    body text,
    severity text DEFAULT 'info'::text NOT NULL,
    resource_type text,
    resource_id text,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: oidc_provider; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oidc_provider (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_id text NOT NULL,
    name text NOT NULL,
    provider_type character varying DEFAULT 'generic'::character varying NOT NULL,
    issuer text NOT NULL,
    claim_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    discovery_metadata jsonb,
    discovered_at timestamp without time zone,
    enabled boolean DEFAULT true NOT NULL,
    organization_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: orchestration_run; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orchestration_run (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    parent_run_id uuid,
    thread_id uuid,
    workflow_id uuid,
    orchestrator_agent_id uuid,
    deleted_agent_name text,
    mode character varying DEFAULT 'tool'::character varying NOT NULL,
    status character varying DEFAULT 'running'::character varying NOT NULL,
    steps json DEFAULT '[]'::json NOT NULL,
    total_usage json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at timestamp without time zone,
    CONSTRAINT orchestration_run_status_check CHECK (((status)::text = ANY ((ARRAY['running'::character varying, 'completed'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: org_budget; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_budget (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    scope character varying NOT NULL,
    team_id uuid,
    user_id uuid,
    monthly_spend_limit_usd real,
    monthly_token_limit integer,
    alert_threshold_pct integer DEFAULT 80 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_by uuid,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_compliance_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_compliance_rule (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    pattern text NOT NULL,
    match_type character varying DEFAULT 'keyword'::character varying NOT NULL,
    action character varying DEFAULT 'flag'::character varying NOT NULL,
    target character varying DEFAULT 'both'::character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_custom_model; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_custom_model (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    provider character varying NOT NULL,
    model text NOT NULL,
    label text,
    supports_tools boolean DEFAULT false NOT NULL,
    supports_image_input boolean DEFAULT false NOT NULL,
    context_window integer DEFAULT 0 NOT NULL,
    connection_kind character varying,
    endpoint text,
    deployment text,
    api_version text,
    secret_encrypted text,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_domain_claim; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_domain_claim (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    domain text NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    auto_assign boolean DEFAULT false NOT NULL,
    verification_token text NOT NULL,
    verification_expires_at timestamp without time zone,
    default_system_role text DEFAULT 'user'::text NOT NULL,
    verified_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_invite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_invite (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    invited_email text NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    token text NOT NULL,
    invited_by uuid,
    expires_at timestamp without time zone NOT NULL,
    accepted_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_model_allocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_model_allocation (
    organization_id uuid NOT NULL,
    backup_models text[],
    monthly_token_allocation integer,
    daily_token_allocation integer,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_permission_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_permission_group (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    key character varying(64),
    name text NOT NULL,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_permission_group_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_permission_group_item (
    group_id uuid NOT NULL,
    permission text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    type character varying DEFAULT 'governance'::character varying NOT NULL,
    name text NOT NULL,
    description text,
    effect character varying DEFAULT 'deny'::character varying NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    definition jsonb NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT org_policy_effect_check CHECK (((effect)::text = ANY ((ARRAY['allow'::character varying, 'deny'::character varying])::text[]))),
    CONSTRAINT org_policy_type_check CHECK (((type)::text = ANY ((ARRAY['governance'::character varying, 'security'::character varying, 'compliance'::character varying, 'ownership'::character varying])::text[])))
);


--
-- Name: org_provider_credential; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_provider_credential (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    provider character varying NOT NULL,
    label text,
    config_encrypted text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_resource_grant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_resource_grant (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    resource_type text NOT NULL,
    resource_id text NOT NULL,
    permission text NOT NULL,
    granted_by uuid,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_role (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    key character varying,
    name text NOT NULL,
    description text,
    is_system boolean DEFAULT false NOT NULL,
    parent_role_id uuid,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_role_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_role_assignment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    role_id uuid NOT NULL,
    team_id uuid,
    assigned_by uuid,
    assigned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_role_permission (
    role_id uuid NOT NULL,
    permission text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_role_permission_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_role_permission_group (
    role_id uuid NOT NULL,
    group_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_routing_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_routing_policy (
    organization_id uuid NOT NULL,
    default_routing_policy character varying,
    mode_config jsonb,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_security_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_security_settings (
    organization_id uuid NOT NULL,
    pii_masking_enabled boolean DEFAULT false NOT NULL,
    dlp_enabled boolean DEFAULT false NOT NULL,
    block_on_injection boolean DEFAULT true NOT NULL,
    injection_block_threshold real DEFAULT 0.85 NOT NULL,
    block_on_jailbreak boolean DEFAULT true NOT NULL,
    jailbreak_block_threshold real DEFAULT 0.9 NOT NULL,
    output_moderation_enabled boolean DEFAULT false NOT NULL,
    block_on_flagged_output boolean DEFAULT false NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_storage_governance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_storage_governance (
    organization_id uuid NOT NULL,
    max_file_size_mb integer,
    max_folder_size_mb integer,
    max_files_per_thread integer,
    max_storage_per_user_mb integer,
    max_storage_per_org_mb integer,
    allowed_file_types text[],
    blocked_file_types text[],
    retention_days integer,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_label; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    label_id uuid NOT NULL,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_mcp_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_mcp_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    allowed_mcp_server_ids text[],
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_model_allocation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_model_allocation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    allowed_models text[],
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_preference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_preference (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    display_name text,
    profession text,
    bot_name text,
    system_prompt text,
    response_style_example text,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_rate_limit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_rate_limit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    auth_limit integer,
    chat_limit integer,
    api_limit integer,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_token_quota; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_token_quota (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    monthly_token_limit integer,
    daily_premium_token_limit integer,
    alert_threshold_pct integer DEFAULT 80 NOT NULL,
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: org_user_tool_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.org_user_tool_permission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    allowed_tools text[],
    denied_tools text[],
    updated_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    plan character varying DEFAULT 'free'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: organization_member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_member (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    source character varying DEFAULT 'direct'::character varying NOT NULL,
    external_id text,
    suspended_at timestamp without time zone,
    suspended_by uuid,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: organization_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_settings (
    organization_id uuid NOT NULL,
    max_monthly_tokens integer,
    allowed_models text[],
    denied_models text[],
    default_model_id text,
    premium_restriction_enabled boolean DEFAULT false NOT NULL,
    premium_cost_threshold_usd real,
    hidden_models text[],
    features jsonb,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: plan_entitlement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_entitlement (
    plan character varying NOT NULL,
    max_members integer,
    max_agents integer,
    monthly_token_quota integer,
    features text[],
    price_amount integer DEFAULT 0 NOT NULL,
    currency character varying(3) DEFAULT 'usd'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: prompt_experiment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prompt_experiment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    prompt_name text NOT NULL,
    variant_a_id uuid,
    variant_b_id uuid,
    rollout_percent integer DEFAULT 50 NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ended_at timestamp without time zone
);


--
-- Name: prompt_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prompt_template (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    template text NOT NULL,
    variables jsonb,
    category text DEFAULT 'system'::text,
    tags text[],
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT prompt_template_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['private'::character varying, 'org'::character varying, 'public'::character varying])::text[])))
);


--
-- Name: prompt_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prompt_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    version text DEFAULT '1.0.0'::text NOT NULL,
    content text NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: rag_search_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rag_search_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    query text NOT NULL,
    expanded_queries jsonb,
    result_count integer DEFAULT 0 NOT NULL,
    reranked boolean DEFAULT false NOT NULL,
    top_result_score real,
    latency_ms integer,
    hallucination_risk text,
    organization_id uuid,
    mode character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: rag_user_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rag_user_config (
    user_id uuid NOT NULL,
    organization_id uuid,
    chunk_size integer DEFAULT 2000 NOT NULL,
    chunk_overlap integer DEFAULT 200 NOT NULL,
    chunking_strategy text DEFAULT 'recursive'::text NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: retrieval_feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retrieval_feedback (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    search_log_id uuid,
    source_key text,
    chunk_index integer,
    relevant boolean NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: saml_provider; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.saml_provider (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid,
    name text NOT NULL,
    entity_id text NOT NULL,
    metadata_url text,
    metadata_xml text,
    certificate text,
    enabled boolean DEFAULT false NOT NULL,
    claim_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: scim_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scim_config (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    bearer_token_hash text,
    enabled boolean DEFAULT false NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: scim_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scim_group (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    external_id text,
    display_name text NOT NULL,
    team_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: security_event_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.security_event_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid,
    trace_id uuid,
    user_id uuid,
    organization_id uuid,
    event_type character varying NOT NULL,
    detector_score real,
    safety_score real,
    blocked boolean DEFAULT false NOT NULL,
    details jsonb,
    source character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    token text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address text,
    user_agent text,
    user_id uuid NOT NULL,
    impersonated_by text,
    impersonation_expires_at timestamp without time zone
);


--
-- Name: session_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    max_lifetime_minutes integer,
    idle_timeout_minutes integer,
    reauth_after_minutes integer,
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: skill; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    agent_id uuid,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    persona text,
    avatar_url text,
    system_prompt_template text,
    prompt_version_id uuid,
    default_model_id text,
    allowed_model_ids text[],
    tool_config jsonb,
    knowledge_base_id uuid,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    governance_status character varying DEFAULT 'approved'::character varying NOT NULL,
    reviewed_by uuid,
    reviewed_at timestamp without time zone,
    governance_note text,
    team_id uuid,
    deleted_at timestamp without time zone,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT skill_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['private'::character varying, 'team'::character varying, 'org'::character varying, 'official'::character varying])::text[])))
);


--
-- Name: skill_team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.skill_team (
    skill_id uuid NOT NULL,
    team_id uuid NOT NULL,
    deployed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: subscription; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    plan character varying DEFAULT 'free'::character varying NOT NULL,
    status character varying DEFAULT 'active'::character varying NOT NULL,
    seats integer DEFAULT 1 NOT NULL,
    current_period_start timestamp without time zone,
    current_period_end timestamp without time zone,
    cancel_at_period_end boolean DEFAULT false NOT NULL,
    external_customer_id text,
    external_subscription_id text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: team; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organization_id uuid NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    description text,
    visibility character varying DEFAULT 'organization'::character varying NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: team_invite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_invite (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    invited_email text NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    token text NOT NULL,
    invited_by uuid,
    expires_at timestamp without time zone NOT NULL,
    accepted_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: team_member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_member (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying DEFAULT 'member'::character varying NOT NULL,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: team_model_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_model_policy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    allowed_models text[],
    denied_models text[],
    default_model_id text,
    premium_restriction_enabled boolean DEFAULT false NOT NULL,
    premium_cost_threshold_usd real,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: thread_attachment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.thread_attachment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    thread_id uuid NOT NULL,
    user_id uuid NOT NULL,
    storage_key text NOT NULL,
    filename text NOT NULL,
    mime_type text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    rag_status text DEFAULT 'pending'::text NOT NULL,
    lifecycle_status character varying DEFAULT 'uploaded'::character varying NOT NULL,
    scan_status character varying DEFAULT 'pending'::character varying NOT NULL,
    language character varying(8),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: token_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    thread_id uuid,
    model text NOT NULL,
    provider text NOT NULL,
    input_tokens integer DEFAULT 0 NOT NULL,
    output_tokens integer DEFAULT 0 NOT NULL,
    total_tokens integer DEFAULT 0 NOT NULL,
    source character varying DEFAULT 'chat'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tool; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    content text NOT NULL,
    frontmatter json,
    category character varying DEFAULT 'other'::character varying NOT NULL,
    tags text[],
    icon json,
    user_id uuid NOT NULL,
    organization_id uuid,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    version text DEFAULT '1.0.0'::text NOT NULL,
    install_count integer DEFAULT 0 NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    submission_status character varying DEFAULT 'none'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone,
    CONSTRAINT tool_visibility_check CHECK (((visibility)::text = ANY ((ARRAY['public'::character varying, 'private'::character varying, 'readonly'::character varying])::text[])))
);


--
-- Name: tool_install; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_install (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tool_id uuid NOT NULL,
    user_id uuid NOT NULL,
    installed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tool_rating; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_rating (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tool_id uuid NOT NULL,
    user_id uuid NOT NULL,
    rating integer NOT NULL,
    review text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tool_submission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_submission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tool_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    rejection_reason text,
    reviewed_by uuid,
    reviewed_at timestamp without time zone,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tool_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tool_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    thread_id uuid,
    tool_name text NOT NULL,
    source character varying DEFAULT 'chat'::character varying NOT NULL,
    duration_ms integer DEFAULT 0 NOT NULL,
    success boolean DEFAULT true NOT NULL,
    error_message text,
    run_id uuid,
    run_kind character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: trusted_device; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trusted_device (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    device_id text NOT NULL,
    label text,
    last_seen_ip text,
    user_agent text,
    expires_at timestamp without time zone,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: two_factor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.two_factor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    secret text,
    backup_codes text,
    enabled boolean DEFAULT false NOT NULL
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    email_verified boolean DEFAULT false NOT NULL,
    password text,
    image text,
    preferences json DEFAULT '{}'::json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    ban_reason text,
    ban_expires timestamp without time zone,
    role text DEFAULT 'user'::text NOT NULL,
    two_factor_enabled boolean DEFAULT false NOT NULL,
    two_factor_secret text,
    two_factor_backup_codes text
);


--
-- Name: user_access_label; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_access_label (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    color character varying(20) DEFAULT 'gray'::character varying,
    description text,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_label_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_label_assignment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    label_id uuid NOT NULL,
    assigned_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_mcp_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_mcp_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    mcp_server_id uuid NOT NULL,
    granted_by uuid,
    source_label_id uuid,
    granted_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_model_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_model_access (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    model_id text NOT NULL,
    granted_by uuid,
    source_label_id uuid,
    granted_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: user_rate_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_rate_limits (
    user_id uuid NOT NULL,
    auth_limit integer,
    chat_limit integer,
    api_limit integer,
    source_label_id uuid,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_token_quota; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_token_quota (
    user_id uuid NOT NULL,
    monthly_token_limit integer,
    daily_premium_token_limit integer,
    alert_threshold_pct integer DEFAULT 80 NOT NULL,
    updated_by uuid,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_tool_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tool_permission (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    tool_name text NOT NULL,
    permission text NOT NULL,
    granted_by uuid,
    source_label_id uuid,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: verification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    identifier text NOT NULL,
    value text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: web_vitals_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_vitals_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(10) NOT NULL,
    value real NOT NULL,
    rating character varying(32) NOT NULL,
    delta real NOT NULL,
    navigation_type character varying(20),
    url text,
    user_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: webhook; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    url text NOT NULL,
    secret text NOT NULL,
    events text[] DEFAULT '{}'::text[] NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: webhook_delivery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_delivery (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    webhook_id uuid NOT NULL,
    user_id uuid NOT NULL,
    event text NOT NULL,
    payload json NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 5 NOT NULL,
    next_attempt_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_attempt_at timestamp without time zone,
    last_status_code integer,
    last_error text,
    delivered_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: workflow; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version text DEFAULT '0.1.0'::text NOT NULL,
    name text NOT NULL,
    icon json,
    description text,
    is_published boolean DEFAULT false NOT NULL,
    visibility character varying DEFAULT 'private'::character varying NOT NULL,
    user_id uuid NOT NULL,
    organization_id uuid,
    install_count integer DEFAULT 0 NOT NULL,
    tags text[],
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: workflow_comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_comment (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id uuid NOT NULL,
    node_id uuid,
    anchor json,
    body text DEFAULT ''::text NOT NULL,
    author_id uuid,
    resolved boolean DEFAULT false NOT NULL,
    color text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: workflow_edge; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_edge (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version text DEFAULT '0.1.0'::text NOT NULL,
    workflow_id uuid NOT NULL,
    source uuid NOT NULL,
    target uuid NOT NULL,
    ui_config json DEFAULT '{}'::json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: workflow_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_execution (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status character varying DEFAULT 'running'::character varying NOT NULL,
    query json,
    result json,
    node_history json DEFAULT '[]'::json NOT NULL,
    duration_ms integer,
    snapshot json,
    paused_node_id uuid,
    pending_task_id uuid,
    compensation_log json,
    mode character varying DEFAULT 'sync'::character varying NOT NULL,
    last_completed_node_id uuid,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    completed_at timestamp without time zone,
    CONSTRAINT workflow_execution_status_check CHECK (((status)::text = ANY ((ARRAY['running'::character varying, 'success'::character varying, 'fail'::character varying, 'paused'::character varying, 'cancelled'::character varying])::text[])))
);


--
-- Name: workflow_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_group (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id uuid NOT NULL,
    parent_group_id uuid,
    label text DEFAULT ''::text NOT NULL,
    color text,
    collapsed boolean DEFAULT false NOT NULL,
    bounds json NOT NULL,
    node_ids json DEFAULT '[]'::json NOT NULL,
    z_index integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: workflow_install; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_install (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id uuid NOT NULL,
    user_id uuid NOT NULL,
    installed_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: workflow_node; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_node (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version text DEFAULT '0.1.0'::text NOT NULL,
    workflow_id uuid NOT NULL,
    kind text NOT NULL,
    name text NOT NULL,
    description text,
    ui_config json DEFAULT '{}'::json,
    node_config json DEFAULT '{}'::json,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: workflow_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_version (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    workflow_id uuid NOT NULL,
    version_number integer NOT NULL,
    label text,
    snapshot_nodes json NOT NULL,
    snapshot_edges json NOT NULL,
    snapshot_workflow json NOT NULL,
    snapshot_groups json,
    snapshot_comments json,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: __drizzle_migrations id; Type: DEFAULT; Schema: drizzle; Owner: -
--

ALTER TABLE ONLY drizzle.__drizzle_migrations ALTER COLUMN id SET DEFAULT nextval('drizzle.__drizzle_migrations_id_seq'::regclass);


--
-- Name: __drizzle_migrations __drizzle_migrations_pkey; Type: CONSTRAINT; Schema: drizzle; Owner: -
--

ALTER TABLE ONLY drizzle.__drizzle_migrations
    ADD CONSTRAINT __drizzle_migrations_pkey PRIMARY KEY (id);


--
-- Name: a2a_capability_card a2a_capability_card_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_capability_card
    ADD CONSTRAINT a2a_capability_card_pkey PRIMARY KEY (id);


--
-- Name: a2a_task a2a_task_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_pkey PRIMARY KEY (id);


--
-- Name: account account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_pkey PRIMARY KEY (id);


--
-- Name: admin_audit_log admin_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_pkey PRIMARY KEY (id);


--
-- Name: agent_deployment agent_deployment_agent_env_org_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_deployment
    ADD CONSTRAINT agent_deployment_agent_env_org_unique UNIQUE (agent_id, environment, organization_id);


--
-- Name: agent_deployment agent_deployment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_deployment
    ADD CONSTRAINT agent_deployment_pkey PRIMARY KEY (id);


--
-- Name: agent_install agent_install_agent_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_install
    ADD CONSTRAINT agent_install_agent_id_user_id_unique UNIQUE (agent_id, user_id);


--
-- Name: agent_install agent_install_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_install
    ADD CONSTRAINT agent_install_pkey PRIMARY KEY (id);


--
-- Name: agent_memory agent_memory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memory
    ADD CONSTRAINT agent_memory_pkey PRIMARY KEY (id);


--
-- Name: agent agent_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_pkey PRIMARY KEY (id);


--
-- Name: agent_rating agent_rating_agent_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rating
    ADD CONSTRAINT agent_rating_agent_id_user_id_unique UNIQUE (agent_id, user_id);


--
-- Name: agent_rating agent_rating_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rating
    ADD CONSTRAINT agent_rating_pkey PRIMARY KEY (id);


--
-- Name: agent_version agent_version_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_version
    ADD CONSTRAINT agent_version_number_unique UNIQUE (agent_id, version_number);


--
-- Name: agent_version agent_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_version
    ADD CONSTRAINT agent_version_pkey PRIMARY KEY (id);


--
-- Name: apikey apikey_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apikey
    ADD CONSTRAINT apikey_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: archive_item archive_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive_item
    ADD CONSTRAINT archive_item_pkey PRIMARY KEY (id);


--
-- Name: archive archive_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive
    ADD CONSTRAINT archive_pkey PRIMARY KEY (id);


--
-- Name: bookmark bookmark_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmark
    ADD CONSTRAINT bookmark_pkey PRIMARY KEY (id);


--
-- Name: bookmark bookmark_user_id_item_id_item_type_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmark
    ADD CONSTRAINT bookmark_user_id_item_id_item_type_unique UNIQUE (user_id, item_id, item_type);


--
-- Name: chat_export_comment chat_export_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export_comment
    ADD CONSTRAINT chat_export_comment_pkey PRIMARY KEY (id);


--
-- Name: chat_export chat_export_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export
    ADD CONSTRAINT chat_export_pkey PRIMARY KEY (id);


--
-- Name: chat_message_embedding chat_message_embedding_message_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_embedding
    ADD CONSTRAINT chat_message_embedding_message_id_unique UNIQUE (message_id);


--
-- Name: chat_message_embedding chat_message_embedding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_embedding
    ADD CONSTRAINT chat_message_embedding_pkey PRIMARY KEY (id);


--
-- Name: chat_message chat_message_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_pkey PRIMARY KEY (id);


--
-- Name: chat_thread chat_thread_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_thread
    ADD CONSTRAINT chat_thread_pkey PRIMARY KEY (id);


--
-- Name: conditional_access_policy conditional_access_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_access_policy
    ADD CONSTRAINT conditional_access_policy_pkey PRIMARY KEY (id);


--
-- Name: cron_job cron_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_job
    ADD CONSTRAINT cron_job_pkey PRIMARY KEY (id);


--
-- Name: cron_run_log cron_run_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_run_log
    ADD CONSTRAINT cron_run_log_pkey PRIMARY KEY (id);


--
-- Name: document_acl document_acl_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_acl
    ADD CONSTRAINT document_acl_pkey PRIMARY KEY (id);


--
-- Name: document_chunk document_chunk_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_chunk
    ADD CONSTRAINT document_chunk_pkey PRIMARY KEY (id);


--
-- Name: email_otp email_otp_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_otp
    ADD CONSTRAINT email_otp_pkey PRIMARY KEY (id);


--
-- Name: embedding_config embedding_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.embedding_config
    ADD CONSTRAINT embedding_config_pkey PRIMARY KEY (id);


--
-- Name: error_log error_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_log
    ADD CONSTRAINT error_log_pkey PRIMARY KEY (id);


--
-- Name: group_mapping group_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mapping
    ADD CONSTRAINT group_mapping_pkey PRIMARY KEY (id);


--
-- Name: hitl_assignment_cursor hitl_assignment_cursor_workflow_id_node_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_assignment_cursor
    ADD CONSTRAINT hitl_assignment_cursor_workflow_id_node_id_pk PRIMARY KEY (workflow_id, node_id);


--
-- Name: hitl_sla_event hitl_sla_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_pkey PRIMARY KEY (id);


--
-- Name: inference_request_log inference_request_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_pkey PRIMARY KEY (id);


--
-- Name: ingestion_jobs ingestion_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestion_jobs
    ADD CONSTRAINT ingestion_jobs_pkey PRIMARY KEY (id);


--
-- Name: integration_connector integration_connector_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connector
    ADD CONSTRAINT integration_connector_pkey PRIMARY KEY (id);


--
-- Name: integration_event integration_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_event
    ADD CONSTRAINT integration_event_pkey PRIMARY KEY (id);


--
-- Name: integration_sync_config integration_sync_config_connector_kb_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_sync_config
    ADD CONSTRAINT integration_sync_config_connector_kb_unique UNIQUE (connector_id, knowledge_base_id);


--
-- Name: integration_sync_config integration_sync_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_sync_config
    ADD CONSTRAINT integration_sync_config_pkey PRIMARY KEY (id);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: knowledge_audit_logs knowledge_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_audit_logs
    ADD CONSTRAINT knowledge_audit_logs_pkey PRIMARY KEY (id);


--
-- Name: knowledge_base_document knowledge_base_document_knowledge_base_id_source_key_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base_document
    ADD CONSTRAINT knowledge_base_document_knowledge_base_id_source_key_pk PRIMARY KEY (knowledge_base_id, source_key);


--
-- Name: knowledge_base knowledge_base_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_pkey PRIMARY KEY (id);


--
-- Name: knowledge_documents knowledge_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_documents
    ADD CONSTRAINT knowledge_documents_pkey PRIMARY KEY (id);


--
-- Name: knowledge_embedding_migration_state knowledge_embedding_migration_state_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embedding_migration_state
    ADD CONSTRAINT knowledge_embedding_migration_state_pkey PRIMARY KEY (id);


--
-- Name: knowledge_embeddings knowledge_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embeddings
    ADD CONSTRAINT knowledge_embeddings_pkey PRIMARY KEY (id);


--
-- Name: knowledge_entity_mention knowledge_entity_mention_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity_mention
    ADD CONSTRAINT knowledge_entity_mention_pkey PRIMARY KEY (id);


--
-- Name: knowledge_entity knowledge_entity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity
    ADD CONSTRAINT knowledge_entity_pkey PRIMARY KEY (id);


--
-- Name: knowledge_metadata knowledge_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_metadata
    ADD CONSTRAINT knowledge_metadata_pkey PRIMARY KEY (id);


--
-- Name: knowledge_versions knowledge_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_versions
    ADD CONSTRAINT knowledge_versions_pkey PRIMARY KEY (id);


--
-- Name: label_access_policy label_access_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_access_policy
    ADD CONSTRAINT label_access_policy_pkey PRIMARY KEY (label_id);


--
-- Name: ldap_directory ldap_directory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ldap_directory
    ADD CONSTRAINT ldap_directory_pkey PRIMARY KEY (id);


--
-- Name: marketplace_category marketplace_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_category
    ADD CONSTRAINT marketplace_category_pkey PRIMARY KEY (id);


--
-- Name: marketplace_category marketplace_category_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_category
    ADD CONSTRAINT marketplace_category_slug_unique UNIQUE (slug);


--
-- Name: marketplace_fork marketplace_fork_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_fork
    ADD CONSTRAINT marketplace_fork_pkey PRIMARY KEY (id);


--
-- Name: marketplace_install marketplace_install_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_install
    ADD CONSTRAINT marketplace_install_pkey PRIMARY KEY (id);


--
-- Name: marketplace_install marketplace_install_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_install
    ADD CONSTRAINT marketplace_install_unique UNIQUE (listing_id, user_id);


--
-- Name: marketplace_listing marketplace_listing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_pkey PRIMARY KEY (id);


--
-- Name: marketplace_version marketplace_version_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_version
    ADD CONSTRAINT marketplace_version_number_unique UNIQUE (listing_id, version_number);


--
-- Name: marketplace_version marketplace_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_version
    ADD CONSTRAINT marketplace_version_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_session mcp_oauth_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_session
    ADD CONSTRAINT mcp_oauth_session_pkey PRIMARY KEY (id);


--
-- Name: mcp_oauth_session mcp_oauth_session_state_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_session
    ADD CONSTRAINT mcp_oauth_session_state_unique UNIQUE (state);


--
-- Name: mcp_server_custom_instructions mcp_server_custom_instructions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_custom_instructions
    ADD CONSTRAINT mcp_server_custom_instructions_pkey PRIMARY KEY (id);


--
-- Name: mcp_server_custom_instructions mcp_server_custom_instructions_user_id_mcp_server_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_custom_instructions
    ADD CONSTRAINT mcp_server_custom_instructions_user_id_mcp_server_id_unique UNIQUE (user_id, mcp_server_id);


--
-- Name: mcp_server mcp_server_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server
    ADD CONSTRAINT mcp_server_pkey PRIMARY KEY (id);


--
-- Name: mcp_server_tool_custom_instructions mcp_server_tool_custom_instructions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_tool_custom_instructions
    ADD CONSTRAINT mcp_server_tool_custom_instructions_pkey PRIMARY KEY (id);


--
-- Name: mcp_server_tool_custom_instructions mcp_server_tool_custom_instructions_user_id_tool_name_mcp_serve; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_tool_custom_instructions
    ADD CONSTRAINT mcp_server_tool_custom_instructions_user_id_tool_name_mcp_serve UNIQUE (user_id, tool_name, mcp_server_id);


--
-- Name: mcp_tool_policy mcp_tool_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_tool_policy
    ADD CONSTRAINT mcp_tool_policy_pkey PRIMARY KEY (id);


--
-- Name: memory_entry memory_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_pkey PRIMARY KEY (id);


--
-- Name: model_catalog_custom_model model_catalog_custom_model_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_custom_model
    ADD CONSTRAINT model_catalog_custom_model_pkey PRIMARY KEY (id);


--
-- Name: model_catalog_custom_model model_catalog_custom_model_provider_model_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_custom_model
    ADD CONSTRAINT model_catalog_custom_model_provider_model_unique UNIQUE (provider, model);


--
-- Name: model_catalog_metadata model_catalog_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_metadata
    ADD CONSTRAINT model_catalog_metadata_pkey PRIMARY KEY (id);


--
-- Name: model_catalog_metadata model_catalog_metadata_provider_model_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_metadata
    ADD CONSTRAINT model_catalog_metadata_provider_model_unique UNIQUE (provider, model);


--
-- Name: model_pricing model_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_pricing
    ADD CONSTRAINT model_pricing_pkey PRIMARY KEY (id);


--
-- Name: model_pricing model_pricing_provider_model_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_pricing
    ADD CONSTRAINT model_pricing_provider_model_unique UNIQUE (provider, model);


--
-- Name: nav_visibility_override nav_visibility_override_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_visibility_override
    ADD CONSTRAINT nav_visibility_override_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: oidc_provider oidc_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oidc_provider
    ADD CONSTRAINT oidc_provider_pkey PRIMARY KEY (id);


--
-- Name: oidc_provider oidc_provider_provider_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oidc_provider
    ADD CONSTRAINT oidc_provider_provider_id_unique UNIQUE (provider_id);


--
-- Name: orchestration_run orchestration_run_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orchestration_run
    ADD CONSTRAINT orchestration_run_pkey PRIMARY KEY (id);


--
-- Name: org_budget org_budget_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_pkey PRIMARY KEY (id);


--
-- Name: org_compliance_rule org_compliance_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_compliance_rule
    ADD CONSTRAINT org_compliance_rule_pkey PRIMARY KEY (id);


--
-- Name: org_custom_model org_custom_model_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_custom_model
    ADD CONSTRAINT org_custom_model_pkey PRIMARY KEY (id);


--
-- Name: org_custom_model org_custom_model_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_custom_model
    ADD CONSTRAINT org_custom_model_unique UNIQUE (organization_id, provider, model);


--
-- Name: org_domain_claim org_domain_claim_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_domain_claim
    ADD CONSTRAINT org_domain_claim_pkey PRIMARY KEY (id);


--
-- Name: org_invite org_invite_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite
    ADD CONSTRAINT org_invite_pkey PRIMARY KEY (id);


--
-- Name: org_invite org_invite_token_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite
    ADD CONSTRAINT org_invite_token_unique UNIQUE (token);


--
-- Name: org_model_allocation org_model_allocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_model_allocation
    ADD CONSTRAINT org_model_allocation_pkey PRIMARY KEY (organization_id);


--
-- Name: org_permission_group_item org_permission_group_item_group_id_permission_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group_item
    ADD CONSTRAINT org_permission_group_item_group_id_permission_pk PRIMARY KEY (group_id, permission);


--
-- Name: org_permission_group org_permission_group_org_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group
    ADD CONSTRAINT org_permission_group_org_name_unique UNIQUE (organization_id, name);


--
-- Name: org_permission_group org_permission_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group
    ADD CONSTRAINT org_permission_group_pkey PRIMARY KEY (id);


--
-- Name: org_policy org_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_policy
    ADD CONSTRAINT org_policy_pkey PRIMARY KEY (id);


--
-- Name: org_provider_credential org_provider_credential_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_provider_credential
    ADD CONSTRAINT org_provider_credential_pkey PRIMARY KEY (id);


--
-- Name: org_provider_credential org_provider_credential_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_provider_credential
    ADD CONSTRAINT org_provider_credential_unique UNIQUE (organization_id, provider);


--
-- Name: org_resource_grant org_resource_grant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_resource_grant
    ADD CONSTRAINT org_resource_grant_pkey PRIMARY KEY (id);


--
-- Name: org_resource_grant org_resource_grant_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_resource_grant
    ADD CONSTRAINT org_resource_grant_unique UNIQUE (membership_id, resource_type, resource_id, permission);


--
-- Name: org_role_assignment org_role_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_pkey PRIMARY KEY (id);


--
-- Name: org_role org_role_org_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role
    ADD CONSTRAINT org_role_org_name_unique UNIQUE (organization_id, name);


--
-- Name: org_role_permission_group org_role_permission_group_role_id_group_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_permission_group
    ADD CONSTRAINT org_role_permission_group_role_id_group_id_pk PRIMARY KEY (role_id, group_id);


--
-- Name: org_role_permission org_role_permission_role_id_permission_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_permission
    ADD CONSTRAINT org_role_permission_role_id_permission_pk PRIMARY KEY (role_id, permission);


--
-- Name: org_role org_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role
    ADD CONSTRAINT org_role_pkey PRIMARY KEY (id);


--
-- Name: org_routing_policy org_routing_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_routing_policy
    ADD CONSTRAINT org_routing_policy_pkey PRIMARY KEY (organization_id);


--
-- Name: org_security_settings org_security_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_security_settings
    ADD CONSTRAINT org_security_settings_pkey PRIMARY KEY (organization_id);


--
-- Name: org_storage_governance org_storage_governance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_storage_governance
    ADD CONSTRAINT org_storage_governance_pkey PRIMARY KEY (organization_id);


--
-- Name: org_user_label org_user_label_org_user_label_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_label
    ADD CONSTRAINT org_user_label_org_user_label_unique UNIQUE (organization_id, user_id, label_id);


--
-- Name: org_user_label org_user_label_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_label
    ADD CONSTRAINT org_user_label_pkey PRIMARY KEY (id);


--
-- Name: org_user_mcp_access org_user_mcp_access_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_mcp_access
    ADD CONSTRAINT org_user_mcp_access_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_mcp_access org_user_mcp_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_mcp_access
    ADD CONSTRAINT org_user_mcp_access_pkey PRIMARY KEY (id);


--
-- Name: org_user_model_allocation org_user_model_allocation_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_model_allocation
    ADD CONSTRAINT org_user_model_allocation_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_model_allocation org_user_model_allocation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_model_allocation
    ADD CONSTRAINT org_user_model_allocation_pkey PRIMARY KEY (id);


--
-- Name: org_user_preference org_user_preference_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_preference
    ADD CONSTRAINT org_user_preference_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_preference org_user_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_preference
    ADD CONSTRAINT org_user_preference_pkey PRIMARY KEY (id);


--
-- Name: org_user_rate_limit org_user_rate_limit_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_rate_limit
    ADD CONSTRAINT org_user_rate_limit_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_rate_limit org_user_rate_limit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_rate_limit
    ADD CONSTRAINT org_user_rate_limit_pkey PRIMARY KEY (id);


--
-- Name: org_user_token_quota org_user_token_quota_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_token_quota
    ADD CONSTRAINT org_user_token_quota_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_token_quota org_user_token_quota_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_token_quota
    ADD CONSTRAINT org_user_token_quota_pkey PRIMARY KEY (id);


--
-- Name: org_user_tool_permission org_user_tool_permission_org_user_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_tool_permission
    ADD CONSTRAINT org_user_tool_permission_org_user_unique UNIQUE (organization_id, user_id);


--
-- Name: org_user_tool_permission org_user_tool_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_tool_permission
    ADD CONSTRAINT org_user_tool_permission_pkey PRIMARY KEY (id);


--
-- Name: organization_member organization_member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member
    ADD CONSTRAINT organization_member_pkey PRIMARY KEY (id);


--
-- Name: organization_member organization_member_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member
    ADD CONSTRAINT organization_member_unique UNIQUE (organization_id, user_id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization_settings organization_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_pkey PRIMARY KEY (organization_id);


--
-- Name: organization organization_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_slug_unique UNIQUE (slug);


--
-- Name: plan_entitlement plan_entitlement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_entitlement
    ADD CONSTRAINT plan_entitlement_pkey PRIMARY KEY (plan);


--
-- Name: prompt_experiment prompt_experiment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_experiment
    ADD CONSTRAINT prompt_experiment_pkey PRIMARY KEY (id);


--
-- Name: prompt_template prompt_template_org_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_org_slug_unique UNIQUE (organization_id, slug);


--
-- Name: prompt_template prompt_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_pkey PRIMARY KEY (id);


--
-- Name: prompt_version prompt_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_version
    ADD CONSTRAINT prompt_version_pkey PRIMARY KEY (id);


--
-- Name: rag_search_log rag_search_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_search_log
    ADD CONSTRAINT rag_search_log_pkey PRIMARY KEY (id);


--
-- Name: rag_user_config rag_user_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_user_config
    ADD CONSTRAINT rag_user_config_pkey PRIMARY KEY (user_id);


--
-- Name: retrieval_feedback retrieval_feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retrieval_feedback
    ADD CONSTRAINT retrieval_feedback_pkey PRIMARY KEY (id);


--
-- Name: saml_provider saml_provider_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saml_provider
    ADD CONSTRAINT saml_provider_pkey PRIMARY KEY (id);


--
-- Name: scim_config scim_config_organization_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_config
    ADD CONSTRAINT scim_config_organization_id_unique UNIQUE (organization_id);


--
-- Name: scim_config scim_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_config
    ADD CONSTRAINT scim_config_pkey PRIMARY KEY (id);


--
-- Name: scim_group scim_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_group
    ADD CONSTRAINT scim_group_pkey PRIMARY KEY (id);


--
-- Name: security_event_log security_event_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_event_log
    ADD CONSTRAINT security_event_log_pkey PRIMARY KEY (id);


--
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);


--
-- Name: session_policy session_policy_organization_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_policy
    ADD CONSTRAINT session_policy_organization_id_unique UNIQUE (organization_id);


--
-- Name: session_policy session_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_policy
    ADD CONSTRAINT session_policy_pkey PRIMARY KEY (id);


--
-- Name: session session_token_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_token_unique UNIQUE (token);


--
-- Name: skill skill_org_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_org_slug_unique UNIQUE (organization_id, slug);


--
-- Name: skill skill_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_pkey PRIMARY KEY (id);


--
-- Name: skill_team skill_team_skill_id_team_id_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_team
    ADD CONSTRAINT skill_team_skill_id_team_id_pk PRIMARY KEY (skill_id, team_id);


--
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (id);


--
-- Name: team_invite team_invite_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_pkey PRIMARY KEY (id);


--
-- Name: team_invite team_invite_token_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_token_unique UNIQUE (token);


--
-- Name: team_member team_member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_pkey PRIMARY KEY (id);


--
-- Name: team_member team_member_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_unique UNIQUE (team_id, user_id);


--
-- Name: team_model_policy team_model_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_model_policy
    ADD CONSTRAINT team_model_policy_pkey PRIMARY KEY (id);


--
-- Name: team_model_policy team_model_policy_team_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_model_policy
    ADD CONSTRAINT team_model_policy_team_unique UNIQUE (team_id);


--
-- Name: team team_org_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_org_slug_unique UNIQUE (organization_id, slug);


--
-- Name: team team_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (id);


--
-- Name: thread_attachment thread_attachment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_attachment
    ADD CONSTRAINT thread_attachment_pkey PRIMARY KEY (id);


--
-- Name: token_usage token_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_usage
    ADD CONSTRAINT token_usage_pkey PRIMARY KEY (id);


--
-- Name: tool_install tool_install_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_install
    ADD CONSTRAINT tool_install_pkey PRIMARY KEY (id);


--
-- Name: tool_install tool_install_tool_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_install
    ADD CONSTRAINT tool_install_tool_id_user_id_unique UNIQUE (tool_id, user_id);


--
-- Name: tool tool_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool
    ADD CONSTRAINT tool_pkey PRIMARY KEY (id);


--
-- Name: tool_rating tool_rating_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_rating
    ADD CONSTRAINT tool_rating_pkey PRIMARY KEY (id);


--
-- Name: tool_rating tool_rating_tool_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_rating
    ADD CONSTRAINT tool_rating_tool_id_user_id_unique UNIQUE (tool_id, user_id);


--
-- Name: tool_submission tool_submission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_submission
    ADD CONSTRAINT tool_submission_pkey PRIMARY KEY (id);


--
-- Name: tool_usage tool_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_usage
    ADD CONSTRAINT tool_usage_pkey PRIMARY KEY (id);


--
-- Name: trusted_device trusted_device_device_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_device
    ADD CONSTRAINT trusted_device_device_id_unique UNIQUE (device_id);


--
-- Name: trusted_device trusted_device_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_device
    ADD CONSTRAINT trusted_device_pkey PRIMARY KEY (id);


--
-- Name: two_factor two_factor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT two_factor_pkey PRIMARY KEY (id);


--
-- Name: two_factor two_factor_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT two_factor_user_id_unique UNIQUE (user_id);


--
-- Name: user_access_label user_access_label_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_label
    ADD CONSTRAINT user_access_label_name_unique UNIQUE (name);


--
-- Name: user_access_label user_access_label_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_label
    ADD CONSTRAINT user_access_label_pkey PRIMARY KEY (id);


--
-- Name: user user_email_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_email_unique UNIQUE (email);


--
-- Name: user_label_assignment user_label_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_label_assignment
    ADD CONSTRAINT user_label_assignment_pkey PRIMARY KEY (id);


--
-- Name: user_label_assignment user_label_assignment_user_id_label_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_label_assignment
    ADD CONSTRAINT user_label_assignment_user_id_label_id_unique UNIQUE (user_id, label_id);


--
-- Name: user_mcp_access user_mcp_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_pkey PRIMARY KEY (id);


--
-- Name: user_mcp_access user_mcp_access_user_id_mcp_server_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_user_id_mcp_server_id_unique UNIQUE (user_id, mcp_server_id);


--
-- Name: user_model_access user_model_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_model_access
    ADD CONSTRAINT user_model_access_pkey PRIMARY KEY (id);


--
-- Name: user_model_access user_model_access_user_id_model_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_model_access
    ADD CONSTRAINT user_model_access_user_id_model_id_unique UNIQUE (user_id, model_id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_rate_limits user_rate_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rate_limits
    ADD CONSTRAINT user_rate_limits_pkey PRIMARY KEY (user_id);


--
-- Name: user_token_quota user_token_quota_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_token_quota
    ADD CONSTRAINT user_token_quota_pkey PRIMARY KEY (user_id);


--
-- Name: user_tool_permission user_tool_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tool_permission
    ADD CONSTRAINT user_tool_permission_pkey PRIMARY KEY (id);


--
-- Name: user_tool_permission user_tool_permission_unique_idx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tool_permission
    ADD CONSTRAINT user_tool_permission_unique_idx UNIQUE (user_id, tool_name);


--
-- Name: verification verification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification
    ADD CONSTRAINT verification_pkey PRIMARY KEY (id);


--
-- Name: web_vitals_log web_vitals_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_vitals_log
    ADD CONSTRAINT web_vitals_log_pkey PRIMARY KEY (id);


--
-- Name: webhook_delivery webhook_delivery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery
    ADD CONSTRAINT webhook_delivery_pkey PRIMARY KEY (id);


--
-- Name: webhook webhook_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT webhook_pkey PRIMARY KEY (id);


--
-- Name: workflow_comment workflow_comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflow_comment_pkey PRIMARY KEY (id);


--
-- Name: workflow_edge workflow_edge_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_edge
    ADD CONSTRAINT workflow_edge_pkey PRIMARY KEY (id);


--
-- Name: workflow_execution workflow_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_execution
    ADD CONSTRAINT workflow_execution_pkey PRIMARY KEY (id);


--
-- Name: workflow_group workflow_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_group
    ADD CONSTRAINT workflow_group_pkey PRIMARY KEY (id);


--
-- Name: workflow_install workflow_install_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_install
    ADD CONSTRAINT workflow_install_pkey PRIMARY KEY (id);


--
-- Name: workflow_install workflow_install_workflow_id_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_install
    ADD CONSTRAINT workflow_install_workflow_id_user_id_unique UNIQUE (workflow_id, user_id);


--
-- Name: workflow_node workflow_node_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_node
    ADD CONSTRAINT workflow_node_pkey PRIMARY KEY (id);


--
-- Name: workflow workflow_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow
    ADD CONSTRAINT workflow_pkey PRIMARY KEY (id);


--
-- Name: workflow_version workflow_version_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_version
    ADD CONSTRAINT workflow_version_number_unique UNIQUE (workflow_id, version_number);


--
-- Name: workflow_version workflow_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_version
    ADD CONSTRAINT workflow_version_pkey PRIMARY KEY (id);


--
-- Name: a2a_capability_card_agent_id_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX a2a_capability_card_agent_id_unique ON public.a2a_capability_card USING btree (agent_id);


--
-- Name: a2a_capability_card_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_capability_card_org_idx ON public.a2a_capability_card USING btree (organization_id);


--
-- Name: a2a_capability_card_org_model_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_capability_card_org_model_idx ON public.a2a_capability_card USING btree (organization_id, model);


--
-- Name: a2a_capability_card_org_reasoning_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_capability_card_org_reasoning_idx ON public.a2a_capability_card USING btree (organization_id, reasoning_mode);


--
-- Name: a2a_task_orchestration_run_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_task_orchestration_run_id_idx ON public.a2a_task USING btree (orchestration_run_id);


--
-- Name: a2a_task_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_task_org_idx ON public.a2a_task USING btree (organization_id);


--
-- Name: a2a_task_parent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_task_parent_idx ON public.a2a_task USING btree (parent_task_id);


--
-- Name: a2a_task_state_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_task_state_idx ON public.a2a_task USING btree (state);


--
-- Name: a2a_task_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX a2a_task_user_idx ON public.a2a_task USING btree (user_id);


--
-- Name: admin_audit_log_action_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_audit_log_action_idx ON public.admin_audit_log USING btree (action);


--
-- Name: admin_audit_log_actor_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_audit_log_actor_id_idx ON public.admin_audit_log USING btree (actor_id);


--
-- Name: admin_audit_log_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_audit_log_created_at_idx ON public.admin_audit_log USING btree (created_at);


--
-- Name: admin_audit_log_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_audit_log_org_id_idx ON public.admin_audit_log USING btree (organization_id);


--
-- Name: admin_audit_log_target_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_audit_log_target_user_id_idx ON public.admin_audit_log USING btree (target_user_id);


--
-- Name: agent_deployment_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_deployment_agent_id_idx ON public.agent_deployment USING btree (agent_id);


--
-- Name: agent_deployment_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_deployment_org_id_idx ON public.agent_deployment USING btree (organization_id);


--
-- Name: agent_install_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_install_user_id_idx ON public.agent_install USING btree (user_id);


--
-- Name: agent_is_published_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_is_published_idx ON public.agent USING btree (is_published);


--
-- Name: agent_memory_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_agent_id_idx ON public.agent_memory USING btree (agent_id);


--
-- Name: agent_memory_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_category_idx ON public.agent_memory USING btree (category);


--
-- Name: agent_memory_embedding_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_embedding_hnsw_idx ON public.agent_memory USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: agent_memory_expires_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_expires_at_idx ON public.agent_memory USING btree (expires_at);


--
-- Name: agent_memory_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_org_idx ON public.agent_memory USING btree (organization_id);


--
-- Name: agent_memory_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_memory_user_id_idx ON public.agent_memory USING btree (user_id);


--
-- Name: agent_org_governance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_org_governance_idx ON public.agent USING btree (organization_id, governance_status);


--
-- Name: agent_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_org_idx ON public.agent USING btree (organization_id);


--
-- Name: agent_rating_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_rating_agent_id_idx ON public.agent_rating USING btree (agent_id);


--
-- Name: agent_team_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_team_id_idx ON public.agent USING btree (team_id);


--
-- Name: agent_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_user_id_idx ON public.agent USING btree (user_id);


--
-- Name: agent_user_id_is_published_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_user_id_is_published_idx ON public.agent USING btree (user_id, is_published);


--
-- Name: agent_version_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX agent_version_agent_id_idx ON public.agent_version USING btree (agent_id);


--
-- Name: apikey_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX apikey_key_idx ON public.apikey USING btree (key);


--
-- Name: apikey_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX apikey_user_id_idx ON public.apikey USING btree (user_id);


--
-- Name: archive_item_item_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX archive_item_item_id_idx ON public.archive_item USING btree (item_id);


--
-- Name: bookmark_item_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bookmark_item_idx ON public.bookmark USING btree (item_id, item_type);


--
-- Name: bookmark_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bookmark_user_id_idx ON public.bookmark USING btree (user_id);


--
-- Name: chat_export_comment_authorId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_export_comment_authorId_idx" ON public.chat_export_comment USING btree (author_id);


--
-- Name: chat_export_comment_exportId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "chat_export_comment_exportId_idx" ON public.chat_export_comment USING btree (export_id);


--
-- Name: chat_export_expires_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_export_expires_at_idx ON public.chat_export USING btree (expires_at);


--
-- Name: chat_export_exporter_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_export_exporter_id_idx ON public.chat_export USING btree (exporter_id);


--
-- Name: chat_message_embedding_embedding_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_embedding_embedding_hnsw_idx ON public.chat_message_embedding USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: chat_message_thread_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_thread_created_idx ON public.chat_message USING btree (thread_id, created_at);


--
-- Name: chat_message_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_message_thread_id_idx ON public.chat_message USING btree (thread_id);


--
-- Name: chat_thread_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_thread_org_idx ON public.chat_thread USING btree (organization_id);


--
-- Name: chat_thread_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_thread_user_id_idx ON public.chat_thread USING btree (user_id);


--
-- Name: chat_thread_user_id_pinned_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX chat_thread_user_id_pinned_created_at_idx ON public.chat_thread USING btree (user_id, pinned, created_at);


--
-- Name: cme_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cme_thread_id_idx ON public.chat_message_embedding USING btree (thread_id);


--
-- Name: cme_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cme_user_id_idx ON public.chat_message_embedding USING btree (user_id);


--
-- Name: conditional_access_policy_org_enabled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX conditional_access_policy_org_enabled_idx ON public.conditional_access_policy USING btree (organization_id, enabled);


--
-- Name: cron_job_next_run_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_job_next_run_at_idx ON public.cron_job USING btree (next_run_at);


--
-- Name: cron_job_organization_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_job_organization_id_idx ON public.cron_job USING btree (organization_id);


--
-- Name: cron_job_trigger_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_job_trigger_type_idx ON public.cron_job USING btree (trigger_type);


--
-- Name: cron_job_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_job_user_id_idx ON public.cron_job USING btree (user_id);


--
-- Name: cron_job_webhook_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cron_job_webhook_token_idx ON public.cron_job USING btree (webhook_token);


--
-- Name: doc_acl_grantee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX doc_acl_grantee_idx ON public.document_acl USING btree (grantee_id);


--
-- Name: doc_acl_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX doc_acl_key_idx ON public.document_acl USING btree (source_key);


--
-- Name: document_chunk_content_tsv_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_content_tsv_idx ON public.document_chunk USING gin (content_tsv);


--
-- Name: document_chunk_embedding_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_embedding_hnsw_idx ON public.document_chunk USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: document_chunk_organization_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_organization_id_idx ON public.document_chunk USING btree (organization_id);


--
-- Name: document_chunk_sourceKey_sourceFilename_userId_chunk_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "document_chunk_sourceKey_sourceFilename_userId_chunk_idx" ON public.document_chunk USING btree (source_key, source_filename, user_id, chunk_index);


--
-- Name: document_chunk_source_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_source_key_idx ON public.document_chunk USING btree (source_key);


--
-- Name: document_chunk_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_thread_id_idx ON public.document_chunk USING btree (thread_id);


--
-- Name: document_chunk_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX document_chunk_user_id_idx ON public.document_chunk USING btree (user_id);


--
-- Name: email_otp_user_purpose_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX email_otp_user_purpose_idx ON public.email_otp USING btree (user_id, purpose);


--
-- Name: embedding_config_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX embedding_config_org_idx ON public.embedding_config USING btree (organization_id);


--
-- Name: embedding_config_org_scope_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX embedding_config_org_scope_uq ON public.embedding_config USING btree (organization_id) WHERE (user_id IS NULL);


--
-- Name: embedding_config_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX embedding_config_user_idx ON public.embedding_config USING btree (user_id);


--
-- Name: embedding_config_user_scope_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX embedding_config_user_scope_uq ON public.embedding_config USING btree (user_id) WHERE (organization_id IS NULL);


--
-- Name: error_log_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_log_created_at_idx ON public.error_log USING btree (created_at);


--
-- Name: error_log_severity_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_log_severity_idx ON public.error_log USING btree (severity);


--
-- Name: error_log_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_log_user_id_idx ON public.error_log USING btree (user_id);


--
-- Name: group_mapping_org_group_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX group_mapping_org_group_idx ON public.group_mapping USING btree (organization_id, external_group);


--
-- Name: group_mapping_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX group_mapping_org_idx ON public.group_mapping USING btree (organization_id);


--
-- Name: hitl_sla_event_execution_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX hitl_sla_event_execution_idx ON public.hitl_sla_event USING btree (execution_id);


--
-- Name: hitl_sla_event_idem_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hitl_sla_event_idem_idx ON public.hitl_sla_event USING btree (task_id, rule_action, fired_at);


--
-- Name: hitl_sla_event_workflow_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX hitl_sla_event_workflow_idx ON public.hitl_sla_event USING btree (workflow_id);


--
-- Name: inference_request_log_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_agent_id_idx ON public.inference_request_log USING btree (agent_id);


--
-- Name: inference_request_log_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_created_at_idx ON public.inference_request_log USING btree (created_at);


--
-- Name: inference_request_log_model_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_model_id_created_at_idx ON public.inference_request_log USING btree (model_id, created_at);


--
-- Name: inference_request_log_org_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_org_id_created_at_idx ON public.inference_request_log USING btree (organization_id, created_at);


--
-- Name: inference_request_log_provider_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_provider_created_at_idx ON public.inference_request_log USING btree (provider, created_at);


--
-- Name: inference_request_log_run_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_run_id_idx ON public.inference_request_log USING btree (run_id);


--
-- Name: inference_request_log_skill_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_skill_id_created_at_idx ON public.inference_request_log USING btree (skill_id, created_at);


--
-- Name: inference_request_log_source_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_source_created_at_idx ON public.inference_request_log USING btree (source, created_at);


--
-- Name: inference_request_log_team_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_team_id_created_at_idx ON public.inference_request_log USING btree (team_id, created_at);


--
-- Name: inference_request_log_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inference_request_log_user_id_created_at_idx ON public.inference_request_log USING btree (user_id, created_at);


--
-- Name: ingestion_jobs_document_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ingestion_jobs_document_idx ON public.ingestion_jobs USING btree (document_id);


--
-- Name: ingestion_jobs_org_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ingestion_jobs_org_created_idx ON public.ingestion_jobs USING btree (organization_id, created_at);


--
-- Name: ingestion_jobs_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ingestion_jobs_status_idx ON public.ingestion_jobs USING btree (status);


--
-- Name: ingestion_jobs_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ingestion_jobs_user_idx ON public.ingestion_jobs USING btree (user_id);


--
-- Name: integration_connector_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX integration_connector_org_idx ON public.integration_connector USING btree (organization_id, connector_type);


--
-- Name: integration_connector_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX integration_connector_status_idx ON public.integration_connector USING btree (status);


--
-- Name: integration_event_connector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX integration_event_connector_idx ON public.integration_event USING btree (connector_id, created_at);


--
-- Name: integration_event_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX integration_event_status_idx ON public.integration_event USING btree (status, created_at);


--
-- Name: invoice_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invoice_org_idx ON public.invoice USING btree (organization_id);


--
-- Name: kb_governance_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kb_governance_status_idx ON public.knowledge_base USING btree (organization_id, governance_status);


--
-- Name: kb_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kb_org_id_idx ON public.knowledge_base USING btree (organization_id);


--
-- Name: kb_team_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kb_team_id_idx ON public.knowledge_base USING btree (team_id);


--
-- Name: kb_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX kb_user_id_idx ON public.knowledge_base USING btree (user_id);


--
-- Name: knowledge_audit_logs_org_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_audit_logs_org_created_idx ON public.knowledge_audit_logs USING btree (organization_id, created_at);


--
-- Name: knowledge_audit_logs_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_audit_logs_resource_idx ON public.knowledge_audit_logs USING btree (resource_type, resource_id);


--
-- Name: knowledge_audit_logs_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_audit_logs_user_idx ON public.knowledge_audit_logs USING btree (user_id);


--
-- Name: knowledge_documents_kb_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_documents_kb_idx ON public.knowledge_documents USING btree (knowledge_base_id);


--
-- Name: knowledge_documents_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_documents_org_idx ON public.knowledge_documents USING btree (organization_id);


--
-- Name: knowledge_documents_source_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_documents_source_key_idx ON public.knowledge_documents USING btree (source_key);


--
-- Name: knowledge_documents_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_documents_user_idx ON public.knowledge_documents USING btree (user_id);


--
-- Name: knowledge_embedding_migration_state_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embedding_migration_state_org_idx ON public.knowledge_embedding_migration_state USING btree (organization_id);


--
-- Name: knowledge_embedding_migration_state_org_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_embedding_migration_state_org_scope_idx ON public.knowledge_embedding_migration_state USING btree (organization_id) WHERE (user_id IS NULL);


--
-- Name: knowledge_embedding_migration_state_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embedding_migration_state_user_idx ON public.knowledge_embedding_migration_state USING btree (user_id);


--
-- Name: knowledge_embedding_migration_state_user_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_embedding_migration_state_user_scope_idx ON public.knowledge_embedding_migration_state USING btree (user_id) WHERE (organization_id IS NULL);


--
-- Name: knowledge_embeddings_chunk_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_chunk_idx ON public.knowledge_embeddings USING btree (chunk_id);


--
-- Name: knowledge_embeddings_chunk_model_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_embeddings_chunk_model_idx ON public.knowledge_embeddings USING btree (chunk_id, embedding_model);


--
-- Name: knowledge_embeddings_document_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_document_idx ON public.knowledge_embeddings USING btree (document_id);


--
-- Name: knowledge_embeddings_e1024_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_e1024_hnsw_idx ON public.knowledge_embeddings USING hnsw (embedding_1024 public.vector_cosine_ops);


--
-- Name: knowledge_embeddings_e3072_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_e3072_hnsw_idx ON public.knowledge_embeddings USING hnsw (embedding_3072 public.halfvec_cosine_ops);


--
-- Name: knowledge_embeddings_e768_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_e768_hnsw_idx ON public.knowledge_embeddings USING hnsw (embedding_768 public.vector_cosine_ops);


--
-- Name: knowledge_embeddings_embedding_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_embedding_hnsw_idx ON public.knowledge_embeddings USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: knowledge_embeddings_embedding_ivfflat_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_embedding_ivfflat_idx ON public.knowledge_embeddings USING ivfflat (embedding public.vector_cosine_ops);


--
-- Name: knowledge_embeddings_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_embeddings_org_idx ON public.knowledge_embeddings USING btree (organization_id);


--
-- Name: knowledge_entity_mention_chunk_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_entity_mention_chunk_idx ON public.knowledge_entity_mention USING btree (chunk_id);


--
-- Name: knowledge_entity_mention_entity_chunk_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_entity_mention_entity_chunk_idx ON public.knowledge_entity_mention USING btree (entity_id, chunk_id);


--
-- Name: knowledge_entity_mention_entity_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_entity_mention_entity_idx ON public.knowledge_entity_mention USING btree (entity_id);


--
-- Name: knowledge_entity_mention_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_entity_mention_org_idx ON public.knowledge_entity_mention USING btree (organization_id);


--
-- Name: knowledge_entity_mention_source_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_entity_mention_source_key_idx ON public.knowledge_entity_mention USING btree (source_key);


--
-- Name: knowledge_entity_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_entity_org_idx ON public.knowledge_entity USING btree (organization_id);


--
-- Name: knowledge_entity_org_name_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_entity_org_name_type_idx ON public.knowledge_entity USING btree (organization_id, normalized_name, type);


--
-- Name: knowledge_metadata_key_value_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_metadata_key_value_idx ON public.knowledge_metadata USING btree (key, value);


--
-- Name: knowledge_metadata_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_metadata_org_idx ON public.knowledge_metadata USING btree (organization_id);


--
-- Name: knowledge_metadata_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_metadata_resource_idx ON public.knowledge_metadata USING btree (resource_type, resource_id);


--
-- Name: knowledge_metadata_unique_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX knowledge_metadata_unique_idx ON public.knowledge_metadata USING btree (resource_type, resource_id, key);


--
-- Name: knowledge_versions_document_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_versions_document_idx ON public.knowledge_versions USING btree (document_id);


--
-- Name: knowledge_versions_kb_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_versions_kb_idx ON public.knowledge_versions USING btree (knowledge_base_id);


--
-- Name: knowledge_versions_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX knowledge_versions_org_idx ON public.knowledge_versions USING btree (organization_id);


--
-- Name: ldap_directory_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ldap_directory_org_idx ON public.ldap_directory USING btree (organization_id);


--
-- Name: marketplace_fork_fork_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_fork_fork_idx ON public.marketplace_fork USING btree (fork_resource_type, fork_resource_id);


--
-- Name: marketplace_fork_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_fork_source_idx ON public.marketplace_fork USING btree (source_listing_id);


--
-- Name: marketplace_install_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_install_user_idx ON public.marketplace_install USING btree (user_id);


--
-- Name: marketplace_listing_category_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_listing_category_id_idx ON public.marketplace_listing USING btree (category_id);


--
-- Name: marketplace_listing_organization_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_listing_organization_id_idx ON public.marketplace_listing USING btree (organization_id);


--
-- Name: marketplace_listing_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX marketplace_listing_resource_idx ON public.marketplace_listing USING btree (resource_type, resource_id);


--
-- Name: marketplace_listing_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_listing_scope_idx ON public.marketplace_listing USING btree (scope);


--
-- Name: marketplace_listing_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_listing_status_idx ON public.marketplace_listing USING btree (status);


--
-- Name: marketplace_listing_team_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_listing_team_id_idx ON public.marketplace_listing USING btree (team_id);


--
-- Name: marketplace_version_listing_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketplace_version_listing_idx ON public.marketplace_version USING btree (listing_id);


--
-- Name: mcp_oauth_session_server_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_oauth_session_server_id_idx ON public.mcp_oauth_session USING btree (mcp_server_id);


--
-- Name: mcp_oauth_session_tokens_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_oauth_session_tokens_idx ON public.mcp_oauth_session USING btree (mcp_server_id) WHERE (tokens IS NOT NULL);


--
-- Name: mcp_server_custom_mcpServerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "mcp_server_custom_mcpServerId_idx" ON public.mcp_server_custom_instructions USING btree (mcp_server_id);


--
-- Name: mcp_server_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_server_org_idx ON public.mcp_server USING btree (organization_id);


--
-- Name: mcp_server_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_server_user_id_idx ON public.mcp_server USING btree (user_id);


--
-- Name: mcp_server_visibility_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_server_visibility_idx ON public.mcp_server USING btree (visibility);


--
-- Name: mcp_tool_policy_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_tool_policy_org_idx ON public.mcp_tool_policy USING btree (organization_id);


--
-- Name: mcp_tool_policy_org_server_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_tool_policy_org_server_idx ON public.mcp_tool_policy USING btree (organization_id, server_id);


--
-- Name: mcp_tool_policy_server_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mcp_tool_policy_server_id_idx ON public.mcp_tool_policy USING btree (server_id);


--
-- Name: memory_entry_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_agent_id_idx ON public.memory_entry USING btree (agent_id);


--
-- Name: memory_entry_embedding_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_embedding_hnsw_idx ON public.memory_entry USING hnsw (embedding public.vector_cosine_ops);


--
-- Name: memory_entry_expires_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_expires_idx ON public.memory_entry USING btree (expires_at);


--
-- Name: memory_entry_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_key_idx ON public.memory_entry USING btree (key);


--
-- Name: memory_entry_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_org_idx ON public.memory_entry USING btree (organization_id);


--
-- Name: memory_entry_org_scope_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_org_scope_idx ON public.memory_entry USING btree (organization_id, scope);


--
-- Name: memory_entry_owner_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_owner_idx ON public.memory_entry USING btree (owner_user_id);


--
-- Name: memory_entry_team_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX memory_entry_team_idx ON public.memory_entry USING btree (team_id);


--
-- Name: nav_vis_override_global_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX nav_vis_override_global_unique ON public.nav_visibility_override USING btree (role_key, nav_item_id) WHERE ((scope)::text = 'global'::text);


--
-- Name: nav_vis_override_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nav_vis_override_org_idx ON public.nav_visibility_override USING btree (organization_id);


--
-- Name: nav_vis_override_org_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX nav_vis_override_org_unique ON public.nav_visibility_override USING btree (organization_id, role_key, nav_item_id) WHERE (organization_id IS NOT NULL);


--
-- Name: notification_user_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_user_created_idx ON public.notification USING btree (user_id, created_at);


--
-- Name: notification_user_read_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_user_read_idx ON public.notification USING btree (user_id, read_at);


--
-- Name: oidc_provider_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oidc_provider_org_idx ON public.oidc_provider USING btree (organization_id);


--
-- Name: orchestration_run_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orchestration_run_agent_id_idx ON public.orchestration_run USING btree (orchestrator_agent_id);


--
-- Name: orchestration_run_parent_run_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orchestration_run_parent_run_id_idx ON public.orchestration_run USING btree (parent_run_id);


--
-- Name: orchestration_run_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orchestration_run_status_idx ON public.orchestration_run USING btree (status);


--
-- Name: orchestration_run_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orchestration_run_thread_id_idx ON public.orchestration_run USING btree (thread_id);


--
-- Name: orchestration_run_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX orchestration_run_workflow_id_idx ON public.orchestration_run USING btree (workflow_id);


--
-- Name: org_budget_member_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_budget_member_unique ON public.org_budget USING btree (organization_id, user_id) WHERE ((scope)::text = 'member'::text);


--
-- Name: org_budget_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_budget_org_id_idx ON public.org_budget USING btree (organization_id);


--
-- Name: org_budget_org_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_budget_org_unique ON public.org_budget USING btree (organization_id) WHERE ((scope)::text = 'org'::text);


--
-- Name: org_budget_team_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_budget_team_unique ON public.org_budget USING btree (organization_id, team_id) WHERE ((scope)::text = 'team'::text);


--
-- Name: org_compliance_rule_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_compliance_rule_org_idx ON public.org_compliance_rule USING btree (organization_id, enabled);


--
-- Name: org_custom_model_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_custom_model_org_idx ON public.org_custom_model USING btree (organization_id);


--
-- Name: org_domain_claim_domain_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_domain_claim_domain_idx ON public.org_domain_claim USING btree (domain);


--
-- Name: org_domain_claim_org_domain_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_domain_claim_org_domain_idx ON public.org_domain_claim USING btree (organization_id, domain);


--
-- Name: org_invite_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_invite_email_idx ON public.org_invite USING btree (invited_email);


--
-- Name: org_invite_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_invite_org_idx ON public.org_invite USING btree (organization_id);


--
-- Name: org_invite_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_invite_token_idx ON public.org_invite USING btree (token);


--
-- Name: org_permission_group_item_perm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_permission_group_item_perm_idx ON public.org_permission_group_item USING btree (permission);


--
-- Name: org_permission_group_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_permission_group_org_idx ON public.org_permission_group USING btree (organization_id);


--
-- Name: org_permission_group_org_key_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_permission_group_org_key_unique ON public.org_permission_group USING btree (organization_id, key) WHERE (key IS NOT NULL);


--
-- Name: org_policy_org_type_enabled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_policy_org_type_enabled_idx ON public.org_policy USING btree (organization_id, type, enabled);


--
-- Name: org_provider_credential_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_provider_credential_org_idx ON public.org_provider_credential USING btree (organization_id);


--
-- Name: org_resource_grant_membership_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_resource_grant_membership_idx ON public.org_resource_grant USING btree (membership_id);


--
-- Name: org_resource_grant_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_resource_grant_org_idx ON public.org_resource_grant USING btree (organization_id);


--
-- Name: org_resource_grant_resource_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_resource_grant_resource_idx ON public.org_resource_grant USING btree (resource_type, resource_id);


--
-- Name: org_role_assignment_membership_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_assignment_membership_idx ON public.org_role_assignment USING btree (membership_id);


--
-- Name: org_role_assignment_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_assignment_org_idx ON public.org_role_assignment USING btree (organization_id);


--
-- Name: org_role_assignment_orgwide_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_role_assignment_orgwide_unique ON public.org_role_assignment USING btree (membership_id, role_id) WHERE (team_id IS NULL);


--
-- Name: org_role_assignment_role_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_assignment_role_idx ON public.org_role_assignment USING btree (role_id);


--
-- Name: org_role_assignment_team_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_role_assignment_team_unique ON public.org_role_assignment USING btree (membership_id, role_id, team_id) WHERE (team_id IS NOT NULL);


--
-- Name: org_role_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_org_idx ON public.org_role USING btree (organization_id);


--
-- Name: org_role_org_key_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX org_role_org_key_unique ON public.org_role USING btree (organization_id, key) WHERE (key IS NOT NULL);


--
-- Name: org_role_permission_group_group_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_permission_group_group_idx ON public.org_role_permission_group USING btree (group_id);


--
-- Name: org_role_permission_perm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_role_permission_perm_idx ON public.org_role_permission USING btree (permission);


--
-- Name: org_user_label_org_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_label_org_user_idx ON public.org_user_label USING btree (organization_id, user_id);


--
-- Name: org_user_mcp_access_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_mcp_access_org_id_idx ON public.org_user_mcp_access USING btree (organization_id);


--
-- Name: org_user_model_allocation_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_model_allocation_org_id_idx ON public.org_user_model_allocation USING btree (organization_id);


--
-- Name: org_user_preference_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_preference_org_id_idx ON public.org_user_preference USING btree (organization_id);


--
-- Name: org_user_rate_limit_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_rate_limit_org_id_idx ON public.org_user_rate_limit USING btree (organization_id);


--
-- Name: org_user_token_quota_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_token_quota_org_id_idx ON public.org_user_token_quota USING btree (organization_id);


--
-- Name: org_user_tool_permission_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX org_user_tool_permission_org_id_idx ON public.org_user_tool_permission USING btree (organization_id);


--
-- Name: organization_member_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_member_org_idx ON public.organization_member USING btree (organization_id);


--
-- Name: organization_member_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_member_user_idx ON public.organization_member USING btree (user_id);


--
-- Name: organization_slug_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organization_slug_idx ON public.organization USING btree (slug);


--
-- Name: prompt_experiment_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_experiment_active_idx ON public.prompt_experiment USING btree (is_active);


--
-- Name: prompt_experiment_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_experiment_name_idx ON public.prompt_experiment USING btree (prompt_name);


--
-- Name: prompt_template_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_template_org_id_idx ON public.prompt_template USING btree (organization_id);


--
-- Name: prompt_template_visibility_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_template_visibility_idx ON public.prompt_template USING btree (visibility);


--
-- Name: prompt_version_is_active_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_version_is_active_idx ON public.prompt_version USING btree (name, is_active);


--
-- Name: prompt_version_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX prompt_version_name_idx ON public.prompt_version USING btree (name);


--
-- Name: rag_search_log_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rag_search_log_created_at_idx ON public.rag_search_log USING btree (created_at);


--
-- Name: rag_search_log_org_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rag_search_log_org_created_idx ON public.rag_search_log USING btree (organization_id, created_at);


--
-- Name: rag_search_log_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rag_search_log_user_id_idx ON public.rag_search_log USING btree (user_id);


--
-- Name: saml_provider_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX saml_provider_org_idx ON public.saml_provider USING btree (organization_id);


--
-- Name: scim_group_org_external_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scim_group_org_external_idx ON public.scim_group USING btree (organization_id, external_id);


--
-- Name: scim_group_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX scim_group_org_idx ON public.scim_group USING btree (organization_id);


--
-- Name: scim_group_team_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX scim_group_team_unique ON public.scim_group USING btree (team_id);


--
-- Name: security_event_blocked_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX security_event_blocked_idx ON public.security_event_log USING btree (blocked, created_at);


--
-- Name: security_event_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX security_event_org_idx ON public.security_event_log USING btree (organization_id, created_at);


--
-- Name: security_event_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX security_event_type_idx ON public.security_event_log USING btree (event_type, created_at);


--
-- Name: security_event_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX security_event_user_idx ON public.security_event_log USING btree (user_id, created_at);


--
-- Name: skill_agent_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_agent_id_idx ON public.skill USING btree (agent_id);


--
-- Name: skill_org_governance_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_org_governance_idx ON public.skill USING btree (organization_id, governance_status);


--
-- Name: skill_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_org_id_idx ON public.skill USING btree (organization_id);


--
-- Name: skill_team_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX skill_team_id_idx ON public.skill USING btree (team_id);


--
-- Name: subscription_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscription_org_idx ON public.subscription USING btree (organization_id);


--
-- Name: subscription_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscription_status_idx ON public.subscription USING btree (status);


--
-- Name: team_invite_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_invite_email_idx ON public.team_invite USING btree (invited_email);


--
-- Name: team_invite_team_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_invite_team_idx ON public.team_invite USING btree (team_id);


--
-- Name: team_invite_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX team_invite_token_idx ON public.team_invite USING btree (token);


--
-- Name: team_member_team_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_member_team_id_idx ON public.team_member USING btree (team_id);


--
-- Name: team_member_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_member_user_id_idx ON public.team_member USING btree (user_id);


--
-- Name: team_model_policy_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_model_policy_org_id_idx ON public.team_model_policy USING btree (organization_id);


--
-- Name: team_org_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_org_id_idx ON public.team USING btree (organization_id);


--
-- Name: thread_attachment_storage_key_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX thread_attachment_storage_key_idx ON public.thread_attachment USING btree (storage_key);


--
-- Name: thread_attachment_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX thread_attachment_thread_id_idx ON public.thread_attachment USING btree (thread_id);


--
-- Name: thread_attachment_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX thread_attachment_user_id_idx ON public.thread_attachment USING btree (user_id);


--
-- Name: token_usage_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_usage_created_at_idx ON public.token_usage USING btree (created_at);


--
-- Name: token_usage_thread_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_usage_thread_id_idx ON public.token_usage USING btree (thread_id);


--
-- Name: token_usage_user_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_usage_user_id_created_at_idx ON public.token_usage USING btree (user_id, created_at);


--
-- Name: token_usage_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX token_usage_user_id_idx ON public.token_usage USING btree (user_id);


--
-- Name: tool_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_category_idx ON public.tool USING btree (category);


--
-- Name: tool_install_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_install_user_id_idx ON public.tool_install USING btree (user_id);


--
-- Name: tool_is_published_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_is_published_idx ON public.tool USING btree (is_published);


--
-- Name: tool_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_org_idx ON public.tool USING btree (organization_id);


--
-- Name: tool_rating_tool_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_rating_tool_id_idx ON public.tool_rating USING btree (tool_id);


--
-- Name: tool_submission_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_submission_status_idx ON public.tool_submission USING btree (status);


--
-- Name: tool_submission_tool_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_submission_tool_id_idx ON public.tool_submission USING btree (tool_id);


--
-- Name: tool_submission_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_submission_user_id_idx ON public.tool_submission USING btree (user_id);


--
-- Name: tool_usage_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_usage_created_at_idx ON public.tool_usage USING btree (created_at);


--
-- Name: tool_usage_run_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_usage_run_id_idx ON public.tool_usage USING btree (run_id);


--
-- Name: tool_usage_tool_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_usage_tool_name_idx ON public.tool_usage USING btree (tool_name);


--
-- Name: tool_usage_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_usage_user_id_idx ON public.tool_usage USING btree (user_id);


--
-- Name: tool_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_user_id_idx ON public.tool USING btree (user_id);


--
-- Name: tool_user_id_visibility_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tool_user_id_visibility_idx ON public.tool USING btree (user_id, visibility);


--
-- Name: trusted_device_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX trusted_device_user_idx ON public.trusted_device USING btree (user_id);


--
-- Name: two_factor_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX two_factor_user_id_idx ON public.two_factor USING btree (user_id);


--
-- Name: user_access_label_createdBy_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_access_label_createdBy_idx" ON public.user_access_label USING btree (created_by);


--
-- Name: user_label_assignment_labelId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_label_assignment_labelId_idx" ON public.user_label_assignment USING btree (label_id);


--
-- Name: user_mcp_access_mcpServerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_mcp_access_mcpServerId_idx" ON public.user_mcp_access USING btree (mcp_server_id);


--
-- Name: user_mcp_access_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "user_mcp_access_userId_idx" ON public.user_mcp_access USING btree (user_id);


--
-- Name: user_tool_permission_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_tool_permission_user_id_idx ON public.user_tool_permission USING btree (user_id);


--
-- Name: web_vitals_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX web_vitals_created_at_idx ON public.web_vitals_log USING btree (created_at);


--
-- Name: web_vitals_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX web_vitals_name_idx ON public.web_vitals_log USING btree (name);


--
-- Name: webhook_delivery_status_next_attempt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX webhook_delivery_status_next_attempt_idx ON public.webhook_delivery USING btree (status, next_attempt_at);


--
-- Name: webhook_delivery_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX webhook_delivery_user_id_idx ON public.webhook_delivery USING btree (user_id);


--
-- Name: webhook_delivery_webhook_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX webhook_delivery_webhook_id_idx ON public.webhook_delivery USING btree (webhook_id);


--
-- Name: webhook_enabled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX webhook_enabled_idx ON public.webhook USING btree (enabled);


--
-- Name: webhook_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX webhook_user_id_idx ON public.webhook USING btree (user_id);


--
-- Name: workflow_comment_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_comment_workflow_id_idx ON public.workflow_comment USING btree (workflow_id);


--
-- Name: workflow_edge_source_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_edge_source_idx ON public.workflow_edge USING btree (source);


--
-- Name: workflow_edge_target_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_edge_target_idx ON public.workflow_edge USING btree (target);


--
-- Name: workflow_edge_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_edge_workflow_id_idx ON public.workflow_edge USING btree (workflow_id);


--
-- Name: workflow_execution_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_execution_status_idx ON public.workflow_execution USING btree (status);


--
-- Name: workflow_execution_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_execution_user_id_idx ON public.workflow_execution USING btree (user_id);


--
-- Name: workflow_execution_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_execution_workflow_id_idx ON public.workflow_execution USING btree (workflow_id);


--
-- Name: workflow_group_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_group_workflow_id_idx ON public.workflow_group USING btree (workflow_id);


--
-- Name: workflow_install_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_install_user_id_idx ON public.workflow_install USING btree (user_id);


--
-- Name: workflow_is_published_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_is_published_idx ON public.workflow USING btree (is_published);


--
-- Name: workflow_node_kind_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_node_kind_idx ON public.workflow_node USING btree (kind);


--
-- Name: workflow_node_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_node_workflow_id_idx ON public.workflow_node USING btree (workflow_id);


--
-- Name: workflow_org_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_org_idx ON public.workflow USING btree (organization_id);


--
-- Name: workflow_user_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_user_id_idx ON public.workflow USING btree (user_id);


--
-- Name: workflow_version_workflow_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX workflow_version_workflow_id_idx ON public.workflow_version USING btree (workflow_id);


--
-- Name: a2a_capability_card a2a_capability_card_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_capability_card
    ADD CONSTRAINT a2a_capability_card_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: a2a_capability_card a2a_capability_card_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_capability_card
    ADD CONSTRAINT a2a_capability_card_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: a2a_capability_card a2a_capability_card_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_capability_card
    ADD CONSTRAINT a2a_capability_card_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: a2a_task a2a_task_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: a2a_task a2a_task_orchestration_run_id_orchestration_run_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_orchestration_run_id_orchestration_run_id_fk FOREIGN KEY (orchestration_run_id) REFERENCES public.orchestration_run(id) ON DELETE SET NULL;


--
-- Name: a2a_task a2a_task_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: a2a_task a2a_task_parent_task_id_a2a_task_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_parent_task_id_a2a_task_id_fk FOREIGN KEY (parent_task_id) REFERENCES public.a2a_task(id) ON DELETE SET NULL;


--
-- Name: a2a_task a2a_task_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.a2a_task
    ADD CONSTRAINT a2a_task_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: account account_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account
    ADD CONSTRAINT account_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: admin_audit_log admin_audit_log_actor_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_actor_id_user_id_fk FOREIGN KEY (actor_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: admin_audit_log admin_audit_log_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: admin_audit_log admin_audit_log_target_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_target_user_id_user_id_fk FOREIGN KEY (target_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agent_deployment agent_deployment_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_deployment
    ADD CONSTRAINT agent_deployment_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: agent_deployment agent_deployment_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_deployment
    ADD CONSTRAINT agent_deployment_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agent_deployment agent_deployment_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_deployment
    ADD CONSTRAINT agent_deployment_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: agent_install agent_install_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_install
    ADD CONSTRAINT agent_install_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: agent_install agent_install_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_install
    ADD CONSTRAINT agent_install_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_memory agent_memory_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memory
    ADD CONSTRAINT agent_memory_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: agent_memory agent_memory_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memory
    ADD CONSTRAINT agent_memory_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: agent_memory agent_memory_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_memory
    ADD CONSTRAINT agent_memory_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent agent_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: agent_rating agent_rating_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rating
    ADD CONSTRAINT agent_rating_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: agent_rating agent_rating_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_rating
    ADD CONSTRAINT agent_rating_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent agent_reviewed_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: agent agent_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: agent agent_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent
    ADD CONSTRAINT agent_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: agent_version agent_version_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_version
    ADD CONSTRAINT agent_version_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: agent_version agent_version_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_version
    ADD CONSTRAINT agent_version_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: apikey apikey_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.apikey
    ADD CONSTRAINT apikey_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: app_settings app_settings_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: archive_item archive_item_archive_id_archive_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive_item
    ADD CONSTRAINT archive_item_archive_id_archive_id_fk FOREIGN KEY (archive_id) REFERENCES public.archive(id) ON DELETE CASCADE;


--
-- Name: archive_item archive_item_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive_item
    ADD CONSTRAINT archive_item_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: archive archive_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive
    ADD CONSTRAINT archive_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: bookmark bookmark_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmark
    ADD CONSTRAINT bookmark_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_export_comment chat_export_comment_author_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export_comment
    ADD CONSTRAINT chat_export_comment_author_id_user_id_fk FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_export_comment chat_export_comment_export_id_chat_export_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export_comment
    ADD CONSTRAINT chat_export_comment_export_id_chat_export_id_fk FOREIGN KEY (export_id) REFERENCES public.chat_export(id) ON DELETE CASCADE;


--
-- Name: chat_export_comment chat_export_comment_parent_id_chat_export_comment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export_comment
    ADD CONSTRAINT chat_export_comment_parent_id_chat_export_comment_id_fk FOREIGN KEY (parent_id) REFERENCES public.chat_export_comment(id) ON DELETE CASCADE;


--
-- Name: chat_export chat_export_exporter_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_export
    ADD CONSTRAINT chat_export_exporter_id_user_id_fk FOREIGN KEY (exporter_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_message_embedding chat_message_embedding_message_id_chat_message_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_embedding
    ADD CONSTRAINT chat_message_embedding_message_id_chat_message_id_fk FOREIGN KEY (message_id) REFERENCES public.chat_message(id) ON DELETE CASCADE;


--
-- Name: chat_message_embedding chat_message_embedding_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_embedding
    ADD CONSTRAINT chat_message_embedding_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE CASCADE;


--
-- Name: chat_message_embedding chat_message_embedding_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_embedding
    ADD CONSTRAINT chat_message_embedding_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: chat_message chat_message_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message
    ADD CONSTRAINT chat_message_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE CASCADE;


--
-- Name: chat_thread chat_thread_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_thread
    ADD CONSTRAINT chat_thread_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: chat_thread chat_thread_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_thread
    ADD CONSTRAINT chat_thread_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: conditional_access_policy conditional_access_policy_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_access_policy
    ADD CONSTRAINT conditional_access_policy_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: conditional_access_policy conditional_access_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conditional_access_policy
    ADD CONSTRAINT conditional_access_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: cron_job cron_job_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_job
    ADD CONSTRAINT cron_job_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: cron_job cron_job_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_job
    ADD CONSTRAINT cron_job_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: cron_run_log cron_run_log_cron_job_id_cron_job_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cron_run_log
    ADD CONSTRAINT cron_run_log_cron_job_id_cron_job_id_fk FOREIGN KEY (cron_job_id) REFERENCES public.cron_job(id) ON DELETE CASCADE;


--
-- Name: document_chunk document_chunk_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_chunk
    ADD CONSTRAINT document_chunk_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: document_chunk document_chunk_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_chunk
    ADD CONSTRAINT document_chunk_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE CASCADE;


--
-- Name: document_chunk document_chunk_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_chunk
    ADD CONSTRAINT document_chunk_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: email_otp email_otp_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_otp
    ADD CONSTRAINT email_otp_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: embedding_config embedding_config_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.embedding_config
    ADD CONSTRAINT embedding_config_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: embedding_config embedding_config_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.embedding_config
    ADD CONSTRAINT embedding_config_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: error_log error_log_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_log
    ADD CONSTRAINT error_log_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: group_mapping group_mapping_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mapping
    ADD CONSTRAINT group_mapping_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: group_mapping group_mapping_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mapping
    ADD CONSTRAINT group_mapping_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: group_mapping group_mapping_role_id_org_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mapping
    ADD CONSTRAINT group_mapping_role_id_org_role_id_fk FOREIGN KEY (role_id) REFERENCES public.org_role(id) ON DELETE SET NULL;


--
-- Name: group_mapping group_mapping_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mapping
    ADD CONSTRAINT group_mapping_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: hitl_assignment_cursor hitl_assignment_cursor_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_assignment_cursor
    ADD CONSTRAINT hitl_assignment_cursor_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: hitl_sla_event hitl_sla_event_execution_id_workflow_execution_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_execution_id_workflow_execution_id_fk FOREIGN KEY (execution_id) REFERENCES public.workflow_execution(id) ON DELETE CASCADE;


--
-- Name: hitl_sla_event hitl_sla_event_node_id_workflow_node_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_node_id_workflow_node_id_fk FOREIGN KEY (node_id) REFERENCES public.workflow_node(id) ON DELETE CASCADE;


--
-- Name: hitl_sla_event hitl_sla_event_task_id_a2a_task_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_task_id_a2a_task_id_fk FOREIGN KEY (task_id) REFERENCES public.a2a_task(id) ON DELETE CASCADE;


--
-- Name: hitl_sla_event hitl_sla_event_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: hitl_sla_event hitl_sla_event_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hitl_sla_event
    ADD CONSTRAINT hitl_sla_event_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: inference_request_log inference_request_log_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: inference_request_log inference_request_log_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: inference_request_log inference_request_log_skill_id_skill_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_skill_id_skill_id_fk FOREIGN KEY (skill_id) REFERENCES public.skill(id) ON DELETE SET NULL;


--
-- Name: inference_request_log inference_request_log_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: inference_request_log inference_request_log_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inference_request_log
    ADD CONSTRAINT inference_request_log_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: ingestion_jobs ingestion_jobs_document_id_knowledge_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestion_jobs
    ADD CONSTRAINT ingestion_jobs_document_id_knowledge_documents_id_fk FOREIGN KEY (document_id) REFERENCES public.knowledge_documents(id) ON DELETE CASCADE;


--
-- Name: ingestion_jobs ingestion_jobs_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestion_jobs
    ADD CONSTRAINT ingestion_jobs_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE SET NULL;


--
-- Name: ingestion_jobs ingestion_jobs_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestion_jobs
    ADD CONSTRAINT ingestion_jobs_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: ingestion_jobs ingestion_jobs_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingestion_jobs
    ADD CONSTRAINT ingestion_jobs_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: integration_connector integration_connector_mcp_server_id_mcp_server_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connector
    ADD CONSTRAINT integration_connector_mcp_server_id_mcp_server_id_fk FOREIGN KEY (mcp_server_id) REFERENCES public.mcp_server(id) ON DELETE SET NULL;


--
-- Name: integration_connector integration_connector_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_connector
    ADD CONSTRAINT integration_connector_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: integration_event integration_event_connector_id_integration_connector_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_event
    ADD CONSTRAINT integration_event_connector_id_integration_connector_id_fk FOREIGN KEY (connector_id) REFERENCES public.integration_connector(id) ON DELETE CASCADE;


--
-- Name: integration_sync_config integration_sync_config_connector_id_integration_connector_id_f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_sync_config
    ADD CONSTRAINT integration_sync_config_connector_id_integration_connector_id_f FOREIGN KEY (connector_id) REFERENCES public.integration_connector(id) ON DELETE CASCADE;


--
-- Name: integration_sync_config integration_sync_config_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.integration_sync_config
    ADD CONSTRAINT integration_sync_config_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE CASCADE;


--
-- Name: invoice invoice_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: invoice invoice_subscription_id_subscription_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_subscription_id_subscription_id_fk FOREIGN KEY (subscription_id) REFERENCES public.subscription(id) ON DELETE SET NULL;


--
-- Name: knowledge_audit_logs knowledge_audit_logs_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_audit_logs
    ADD CONSTRAINT knowledge_audit_logs_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_audit_logs knowledge_audit_logs_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_audit_logs
    ADD CONSTRAINT knowledge_audit_logs_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: knowledge_base_document knowledge_base_document_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base_document
    ADD CONSTRAINT knowledge_base_document_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE CASCADE;


--
-- Name: knowledge_base knowledge_base_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_base knowledge_base_reviewed_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: knowledge_base knowledge_base_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: knowledge_base knowledge_base_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_base
    ADD CONSTRAINT knowledge_base_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: knowledge_documents knowledge_documents_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_documents
    ADD CONSTRAINT knowledge_documents_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE SET NULL;


--
-- Name: knowledge_documents knowledge_documents_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_documents
    ADD CONSTRAINT knowledge_documents_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_documents knowledge_documents_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_documents
    ADD CONSTRAINT knowledge_documents_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: knowledge_embedding_migration_state knowledge_embedding_migration_state_organization_id_organizatio; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embedding_migration_state
    ADD CONSTRAINT knowledge_embedding_migration_state_organization_id_organizatio FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_embedding_migration_state knowledge_embedding_migration_state_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embedding_migration_state
    ADD CONSTRAINT knowledge_embedding_migration_state_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: knowledge_embeddings knowledge_embeddings_chunk_id_document_chunk_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embeddings
    ADD CONSTRAINT knowledge_embeddings_chunk_id_document_chunk_id_fk FOREIGN KEY (chunk_id) REFERENCES public.document_chunk(id) ON DELETE CASCADE;


--
-- Name: knowledge_embeddings knowledge_embeddings_document_id_knowledge_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embeddings
    ADD CONSTRAINT knowledge_embeddings_document_id_knowledge_documents_id_fk FOREIGN KEY (document_id) REFERENCES public.knowledge_documents(id) ON DELETE CASCADE;


--
-- Name: knowledge_embeddings knowledge_embeddings_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embeddings
    ADD CONSTRAINT knowledge_embeddings_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_embeddings knowledge_embeddings_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_embeddings
    ADD CONSTRAINT knowledge_embeddings_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: knowledge_entity_mention knowledge_entity_mention_chunk_id_document_chunk_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity_mention
    ADD CONSTRAINT knowledge_entity_mention_chunk_id_document_chunk_id_fk FOREIGN KEY (chunk_id) REFERENCES public.document_chunk(id) ON DELETE CASCADE;


--
-- Name: knowledge_entity_mention knowledge_entity_mention_entity_id_knowledge_entity_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity_mention
    ADD CONSTRAINT knowledge_entity_mention_entity_id_knowledge_entity_id_fk FOREIGN KEY (entity_id) REFERENCES public.knowledge_entity(id) ON DELETE CASCADE;


--
-- Name: knowledge_entity_mention knowledge_entity_mention_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity_mention
    ADD CONSTRAINT knowledge_entity_mention_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_entity_mention knowledge_entity_mention_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity_mention
    ADD CONSTRAINT knowledge_entity_mention_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: knowledge_entity knowledge_entity_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_entity
    ADD CONSTRAINT knowledge_entity_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_metadata knowledge_metadata_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_metadata
    ADD CONSTRAINT knowledge_metadata_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_metadata knowledge_metadata_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_metadata
    ADD CONSTRAINT knowledge_metadata_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: knowledge_versions knowledge_versions_document_id_knowledge_documents_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_versions
    ADD CONSTRAINT knowledge_versions_document_id_knowledge_documents_id_fk FOREIGN KEY (document_id) REFERENCES public.knowledge_documents(id) ON DELETE CASCADE;


--
-- Name: knowledge_versions knowledge_versions_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_versions
    ADD CONSTRAINT knowledge_versions_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE CASCADE;


--
-- Name: knowledge_versions knowledge_versions_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_versions
    ADD CONSTRAINT knowledge_versions_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: knowledge_versions knowledge_versions_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.knowledge_versions
    ADD CONSTRAINT knowledge_versions_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: label_access_policy label_access_policy_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_access_policy
    ADD CONSTRAINT label_access_policy_label_id_user_access_label_id_fk FOREIGN KEY (label_id) REFERENCES public.user_access_label(id) ON DELETE CASCADE;


--
-- Name: label_access_policy label_access_policy_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.label_access_policy
    ADD CONSTRAINT label_access_policy_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: ldap_directory ldap_directory_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ldap_directory
    ADD CONSTRAINT ldap_directory_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: marketplace_fork marketplace_fork_forked_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_fork
    ADD CONSTRAINT marketplace_fork_forked_by_user_id_fk FOREIGN KEY (forked_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: marketplace_fork marketplace_fork_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_fork
    ADD CONSTRAINT marketplace_fork_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: marketplace_fork marketplace_fork_source_listing_id_marketplace_listing_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_fork
    ADD CONSTRAINT marketplace_fork_source_listing_id_marketplace_listing_id_fk FOREIGN KEY (source_listing_id) REFERENCES public.marketplace_listing(id) ON DELETE SET NULL;


--
-- Name: marketplace_install marketplace_install_listing_id_marketplace_listing_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_install
    ADD CONSTRAINT marketplace_install_listing_id_marketplace_listing_id_fk FOREIGN KEY (listing_id) REFERENCES public.marketplace_listing(id) ON DELETE CASCADE;


--
-- Name: marketplace_install marketplace_install_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_install
    ADD CONSTRAINT marketplace_install_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: marketplace_install marketplace_install_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_install
    ADD CONSTRAINT marketplace_install_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: marketplace_listing marketplace_listing_category_id_marketplace_category_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_category_id_marketplace_category_id_fk FOREIGN KEY (category_id) REFERENCES public.marketplace_category(id) ON DELETE SET NULL;


--
-- Name: marketplace_listing marketplace_listing_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: marketplace_listing marketplace_listing_reviewed_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: marketplace_listing marketplace_listing_submitted_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_submitted_by_user_id_fk FOREIGN KEY (submitted_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: marketplace_listing marketplace_listing_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_listing
    ADD CONSTRAINT marketplace_listing_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: marketplace_version marketplace_version_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_version
    ADD CONSTRAINT marketplace_version_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: marketplace_version marketplace_version_listing_id_marketplace_listing_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketplace_version
    ADD CONSTRAINT marketplace_version_listing_id_marketplace_listing_id_fk FOREIGN KEY (listing_id) REFERENCES public.marketplace_listing(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_session mcp_oauth_session_mcp_server_id_mcp_server_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_session
    ADD CONSTRAINT mcp_oauth_session_mcp_server_id_mcp_server_id_fk FOREIGN KEY (mcp_server_id) REFERENCES public.mcp_server(id) ON DELETE CASCADE;


--
-- Name: mcp_oauth_session mcp_oauth_session_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_oauth_session
    ADD CONSTRAINT mcp_oauth_session_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: mcp_server_custom_instructions mcp_server_custom_instructions_mcp_server_id_mcp_server_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_custom_instructions
    ADD CONSTRAINT mcp_server_custom_instructions_mcp_server_id_mcp_server_id_fk FOREIGN KEY (mcp_server_id) REFERENCES public.mcp_server(id) ON DELETE CASCADE;


--
-- Name: mcp_server_custom_instructions mcp_server_custom_instructions_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_custom_instructions
    ADD CONSTRAINT mcp_server_custom_instructions_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: mcp_server mcp_server_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server
    ADD CONSTRAINT mcp_server_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: mcp_server_tool_custom_instructions mcp_server_tool_custom_instructions_mcp_server_id_mcp_server_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_tool_custom_instructions
    ADD CONSTRAINT mcp_server_tool_custom_instructions_mcp_server_id_mcp_server_id FOREIGN KEY (mcp_server_id) REFERENCES public.mcp_server(id) ON DELETE CASCADE;


--
-- Name: mcp_server_tool_custom_instructions mcp_server_tool_custom_instructions_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server_tool_custom_instructions
    ADD CONSTRAINT mcp_server_tool_custom_instructions_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: mcp_server mcp_server_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_server
    ADD CONSTRAINT mcp_server_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: mcp_tool_policy mcp_tool_policy_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_tool_policy
    ADD CONSTRAINT mcp_tool_policy_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: mcp_tool_policy mcp_tool_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_tool_policy
    ADD CONSTRAINT mcp_tool_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: mcp_tool_policy mcp_tool_policy_server_id_mcp_server_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mcp_tool_policy
    ADD CONSTRAINT mcp_tool_policy_server_id_mcp_server_id_fk FOREIGN KEY (server_id) REFERENCES public.mcp_server(id) ON DELETE CASCADE;


--
-- Name: memory_entry memory_entry_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE CASCADE;


--
-- Name: memory_entry memory_entry_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: memory_entry memory_entry_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: memory_entry memory_entry_owner_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_owner_user_id_user_id_fk FOREIGN KEY (owner_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: memory_entry memory_entry_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.memory_entry
    ADD CONSTRAINT memory_entry_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: model_catalog_custom_model model_catalog_custom_model_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_custom_model
    ADD CONSTRAINT model_catalog_custom_model_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: model_catalog_custom_model model_catalog_custom_model_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_custom_model
    ADD CONSTRAINT model_catalog_custom_model_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: model_catalog_metadata model_catalog_metadata_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_catalog_metadata
    ADD CONSTRAINT model_catalog_metadata_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: model_pricing model_pricing_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.model_pricing
    ADD CONSTRAINT model_pricing_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: nav_visibility_override nav_visibility_override_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_visibility_override
    ADD CONSTRAINT nav_visibility_override_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: nav_visibility_override nav_visibility_override_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_visibility_override
    ADD CONSTRAINT nav_visibility_override_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: notification notification_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: notification notification_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: oidc_provider oidc_provider_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oidc_provider
    ADD CONSTRAINT oidc_provider_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: orchestration_run orchestration_run_orchestrator_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orchestration_run
    ADD CONSTRAINT orchestration_run_orchestrator_agent_id_agent_id_fk FOREIGN KEY (orchestrator_agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: orchestration_run orchestration_run_parent_run_id_orchestration_run_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orchestration_run
    ADD CONSTRAINT orchestration_run_parent_run_id_orchestration_run_id_fk FOREIGN KEY (parent_run_id) REFERENCES public.orchestration_run(id) ON DELETE SET NULL;


--
-- Name: orchestration_run orchestration_run_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orchestration_run
    ADD CONSTRAINT orchestration_run_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE SET NULL;


--
-- Name: orchestration_run orchestration_run_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orchestration_run
    ADD CONSTRAINT orchestration_run_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE SET NULL;


--
-- Name: org_budget org_budget_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_budget org_budget_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_budget org_budget_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: org_budget org_budget_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_budget org_budget_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_budget
    ADD CONSTRAINT org_budget_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_compliance_rule org_compliance_rule_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_compliance_rule
    ADD CONSTRAINT org_compliance_rule_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_compliance_rule org_compliance_rule_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_compliance_rule
    ADD CONSTRAINT org_compliance_rule_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_custom_model org_custom_model_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_custom_model
    ADD CONSTRAINT org_custom_model_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_custom_model org_custom_model_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_custom_model
    ADD CONSTRAINT org_custom_model_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_domain_claim org_domain_claim_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_domain_claim
    ADD CONSTRAINT org_domain_claim_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_invite org_invite_invited_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite
    ADD CONSTRAINT org_invite_invited_by_user_id_fk FOREIGN KEY (invited_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_invite org_invite_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_invite
    ADD CONSTRAINT org_invite_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_model_allocation org_model_allocation_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_model_allocation
    ADD CONSTRAINT org_model_allocation_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_model_allocation org_model_allocation_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_model_allocation
    ADD CONSTRAINT org_model_allocation_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_permission_group org_permission_group_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group
    ADD CONSTRAINT org_permission_group_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_permission_group_item org_permission_group_item_group_id_org_permission_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group_item
    ADD CONSTRAINT org_permission_group_item_group_id_org_permission_group_id_fk FOREIGN KEY (group_id) REFERENCES public.org_permission_group(id) ON DELETE CASCADE;


--
-- Name: org_permission_group org_permission_group_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_permission_group
    ADD CONSTRAINT org_permission_group_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_policy org_policy_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_policy
    ADD CONSTRAINT org_policy_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_policy org_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_policy
    ADD CONSTRAINT org_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_provider_credential org_provider_credential_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_provider_credential
    ADD CONSTRAINT org_provider_credential_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_provider_credential org_provider_credential_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_provider_credential
    ADD CONSTRAINT org_provider_credential_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_resource_grant org_resource_grant_granted_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_resource_grant
    ADD CONSTRAINT org_resource_grant_granted_by_user_id_fk FOREIGN KEY (granted_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_resource_grant org_resource_grant_membership_id_organization_member_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_resource_grant
    ADD CONSTRAINT org_resource_grant_membership_id_organization_member_id_fk FOREIGN KEY (membership_id) REFERENCES public.organization_member(id) ON DELETE CASCADE;


--
-- Name: org_resource_grant org_resource_grant_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_resource_grant
    ADD CONSTRAINT org_resource_grant_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_role_assignment org_role_assignment_assigned_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_assigned_by_user_id_fk FOREIGN KEY (assigned_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_role_assignment org_role_assignment_membership_id_organization_member_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_membership_id_organization_member_id_fk FOREIGN KEY (membership_id) REFERENCES public.organization_member(id) ON DELETE CASCADE;


--
-- Name: org_role_assignment org_role_assignment_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_role_assignment org_role_assignment_role_id_org_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_role_id_org_role_id_fk FOREIGN KEY (role_id) REFERENCES public.org_role(id) ON DELETE CASCADE;


--
-- Name: org_role_assignment org_role_assignment_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_assignment
    ADD CONSTRAINT org_role_assignment_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: org_role org_role_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role
    ADD CONSTRAINT org_role_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_role org_role_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role
    ADD CONSTRAINT org_role_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_role org_role_parent_role_id_org_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role
    ADD CONSTRAINT org_role_parent_role_id_org_role_id_fk FOREIGN KEY (parent_role_id) REFERENCES public.org_role(id) ON DELETE SET NULL;


--
-- Name: org_role_permission_group org_role_permission_group_group_id_org_permission_group_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_permission_group
    ADD CONSTRAINT org_role_permission_group_group_id_org_permission_group_id_fk FOREIGN KEY (group_id) REFERENCES public.org_permission_group(id) ON DELETE CASCADE;


--
-- Name: org_role_permission_group org_role_permission_group_role_id_org_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_permission_group
    ADD CONSTRAINT org_role_permission_group_role_id_org_role_id_fk FOREIGN KEY (role_id) REFERENCES public.org_role(id) ON DELETE CASCADE;


--
-- Name: org_role_permission org_role_permission_role_id_org_role_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_role_permission
    ADD CONSTRAINT org_role_permission_role_id_org_role_id_fk FOREIGN KEY (role_id) REFERENCES public.org_role(id) ON DELETE CASCADE;


--
-- Name: org_routing_policy org_routing_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_routing_policy
    ADD CONSTRAINT org_routing_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_routing_policy org_routing_policy_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_routing_policy
    ADD CONSTRAINT org_routing_policy_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_security_settings org_security_settings_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_security_settings
    ADD CONSTRAINT org_security_settings_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_storage_governance org_storage_governance_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_storage_governance
    ADD CONSTRAINT org_storage_governance_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_label org_user_label_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_label
    ADD CONSTRAINT org_user_label_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_label org_user_label_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_label
    ADD CONSTRAINT org_user_label_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_label org_user_label_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_label
    ADD CONSTRAINT org_user_label_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_mcp_access org_user_mcp_access_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_mcp_access
    ADD CONSTRAINT org_user_mcp_access_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_mcp_access org_user_mcp_access_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_mcp_access
    ADD CONSTRAINT org_user_mcp_access_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_mcp_access org_user_mcp_access_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_mcp_access
    ADD CONSTRAINT org_user_mcp_access_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_model_allocation org_user_model_allocation_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_model_allocation
    ADD CONSTRAINT org_user_model_allocation_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_model_allocation org_user_model_allocation_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_model_allocation
    ADD CONSTRAINT org_user_model_allocation_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_model_allocation org_user_model_allocation_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_model_allocation
    ADD CONSTRAINT org_user_model_allocation_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_preference org_user_preference_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_preference
    ADD CONSTRAINT org_user_preference_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_preference org_user_preference_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_preference
    ADD CONSTRAINT org_user_preference_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_preference org_user_preference_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_preference
    ADD CONSTRAINT org_user_preference_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_rate_limit org_user_rate_limit_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_rate_limit
    ADD CONSTRAINT org_user_rate_limit_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_rate_limit org_user_rate_limit_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_rate_limit
    ADD CONSTRAINT org_user_rate_limit_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_rate_limit org_user_rate_limit_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_rate_limit
    ADD CONSTRAINT org_user_rate_limit_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_token_quota org_user_token_quota_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_token_quota
    ADD CONSTRAINT org_user_token_quota_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_token_quota org_user_token_quota_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_token_quota
    ADD CONSTRAINT org_user_token_quota_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_token_quota org_user_token_quota_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_token_quota
    ADD CONSTRAINT org_user_token_quota_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: org_user_tool_permission org_user_tool_permission_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_tool_permission
    ADD CONSTRAINT org_user_tool_permission_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: org_user_tool_permission org_user_tool_permission_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_tool_permission
    ADD CONSTRAINT org_user_tool_permission_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: org_user_tool_permission org_user_tool_permission_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.org_user_tool_permission
    ADD CONSTRAINT org_user_tool_permission_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: organization_member organization_member_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member
    ADD CONSTRAINT organization_member_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: organization_member organization_member_suspended_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member
    ADD CONSTRAINT organization_member_suspended_by_user_id_fk FOREIGN KEY (suspended_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: organization_member organization_member_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_member
    ADD CONSTRAINT organization_member_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: organization_settings organization_settings_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_settings
    ADD CONSTRAINT organization_settings_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: prompt_experiment prompt_experiment_variant_a_id_prompt_version_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_experiment
    ADD CONSTRAINT prompt_experiment_variant_a_id_prompt_version_id_fk FOREIGN KEY (variant_a_id) REFERENCES public.prompt_version(id) ON DELETE CASCADE;


--
-- Name: prompt_experiment prompt_experiment_variant_b_id_prompt_version_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_experiment
    ADD CONSTRAINT prompt_experiment_variant_b_id_prompt_version_id_fk FOREIGN KEY (variant_b_id) REFERENCES public.prompt_version(id) ON DELETE CASCADE;


--
-- Name: prompt_template prompt_template_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: prompt_template prompt_template_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_template
    ADD CONSTRAINT prompt_template_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: prompt_version prompt_version_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prompt_version
    ADD CONSTRAINT prompt_version_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: rag_search_log rag_search_log_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_search_log
    ADD CONSTRAINT rag_search_log_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: rag_search_log rag_search_log_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_search_log
    ADD CONSTRAINT rag_search_log_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: rag_user_config rag_user_config_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_user_config
    ADD CONSTRAINT rag_user_config_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: rag_user_config rag_user_config_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rag_user_config
    ADD CONSTRAINT rag_user_config_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: retrieval_feedback retrieval_feedback_search_log_id_rag_search_log_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retrieval_feedback
    ADD CONSTRAINT retrieval_feedback_search_log_id_rag_search_log_id_fk FOREIGN KEY (search_log_id) REFERENCES public.rag_search_log(id) ON DELETE SET NULL;


--
-- Name: retrieval_feedback retrieval_feedback_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retrieval_feedback
    ADD CONSTRAINT retrieval_feedback_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: saml_provider saml_provider_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.saml_provider
    ADD CONSTRAINT saml_provider_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: scim_config scim_config_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_config
    ADD CONSTRAINT scim_config_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: scim_config scim_config_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_config
    ADD CONSTRAINT scim_config_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: scim_group scim_group_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_group
    ADD CONSTRAINT scim_group_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: scim_group scim_group_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scim_group
    ADD CONSTRAINT scim_group_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: security_event_log security_event_log_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_event_log
    ADD CONSTRAINT security_event_log_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: security_event_log security_event_log_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.security_event_log
    ADD CONSTRAINT security_event_log_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: session_policy session_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_policy
    ADD CONSTRAINT session_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: session session_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: skill skill_agent_id_agent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_agent_id_agent_id_fk FOREIGN KEY (agent_id) REFERENCES public.agent(id) ON DELETE SET NULL;


--
-- Name: skill skill_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: skill skill_knowledge_base_id_knowledge_base_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_knowledge_base_id_knowledge_base_id_fk FOREIGN KEY (knowledge_base_id) REFERENCES public.knowledge_base(id) ON DELETE SET NULL;


--
-- Name: skill skill_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: skill skill_prompt_version_id_prompt_version_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_prompt_version_id_prompt_version_id_fk FOREIGN KEY (prompt_version_id) REFERENCES public.prompt_version(id) ON DELETE SET NULL;


--
-- Name: skill skill_reviewed_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: skill skill_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill
    ADD CONSTRAINT skill_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE SET NULL;


--
-- Name: skill_team skill_team_skill_id_skill_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_team
    ADD CONSTRAINT skill_team_skill_id_skill_id_fk FOREIGN KEY (skill_id) REFERENCES public.skill(id) ON DELETE CASCADE;


--
-- Name: skill_team skill_team_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.skill_team
    ADD CONSTRAINT skill_team_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: subscription subscription_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: team team_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: team_invite team_invite_invited_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_invited_by_user_id_fk FOREIGN KEY (invited_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: team_invite team_invite_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: team_invite team_invite_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invite
    ADD CONSTRAINT team_invite_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: team_member team_member_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: team_member team_member_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_member
    ADD CONSTRAINT team_member_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: team_model_policy team_model_policy_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_model_policy
    ADD CONSTRAINT team_model_policy_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: team_model_policy team_model_policy_team_id_team_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_model_policy
    ADD CONSTRAINT team_model_policy_team_id_team_id_fk FOREIGN KEY (team_id) REFERENCES public.team(id) ON DELETE CASCADE;


--
-- Name: team team_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE CASCADE;


--
-- Name: thread_attachment thread_attachment_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_attachment
    ADD CONSTRAINT thread_attachment_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE CASCADE;


--
-- Name: thread_attachment thread_attachment_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.thread_attachment
    ADD CONSTRAINT thread_attachment_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: token_usage token_usage_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_usage
    ADD CONSTRAINT token_usage_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE SET NULL;


--
-- Name: token_usage token_usage_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_usage
    ADD CONSTRAINT token_usage_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tool_install tool_install_tool_id_tool_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_install
    ADD CONSTRAINT tool_install_tool_id_tool_id_fk FOREIGN KEY (tool_id) REFERENCES public.tool(id) ON DELETE CASCADE;


--
-- Name: tool_install tool_install_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_install
    ADD CONSTRAINT tool_install_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tool tool_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool
    ADD CONSTRAINT tool_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: tool_rating tool_rating_tool_id_tool_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_rating
    ADD CONSTRAINT tool_rating_tool_id_tool_id_fk FOREIGN KEY (tool_id) REFERENCES public.tool(id) ON DELETE CASCADE;


--
-- Name: tool_rating tool_rating_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_rating
    ADD CONSTRAINT tool_rating_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tool_submission tool_submission_reviewed_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_submission
    ADD CONSTRAINT tool_submission_reviewed_by_user_id_fk FOREIGN KEY (reviewed_by) REFERENCES public."user"(id);


--
-- Name: tool_submission tool_submission_tool_id_tool_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_submission
    ADD CONSTRAINT tool_submission_tool_id_tool_id_fk FOREIGN KEY (tool_id) REFERENCES public.tool(id) ON DELETE CASCADE;


--
-- Name: tool_submission tool_submission_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_submission
    ADD CONSTRAINT tool_submission_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tool_usage tool_usage_thread_id_chat_thread_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_usage
    ADD CONSTRAINT tool_usage_thread_id_chat_thread_id_fk FOREIGN KEY (thread_id) REFERENCES public.chat_thread(id) ON DELETE SET NULL;


--
-- Name: tool_usage tool_usage_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool_usage
    ADD CONSTRAINT tool_usage_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: tool tool_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tool
    ADD CONSTRAINT tool_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: trusted_device trusted_device_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trusted_device
    ADD CONSTRAINT trusted_device_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: two_factor two_factor_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT two_factor_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_access_label user_access_label_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_access_label
    ADD CONSTRAINT user_access_label_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_label_assignment user_label_assignment_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_label_assignment
    ADD CONSTRAINT user_label_assignment_label_id_user_access_label_id_fk FOREIGN KEY (label_id) REFERENCES public.user_access_label(id) ON DELETE CASCADE;


--
-- Name: user_label_assignment user_label_assignment_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_label_assignment
    ADD CONSTRAINT user_label_assignment_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_mcp_access user_mcp_access_granted_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_granted_by_user_id_fk FOREIGN KEY (granted_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_mcp_access user_mcp_access_mcp_server_id_mcp_server_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_mcp_server_id_mcp_server_id_fk FOREIGN KEY (mcp_server_id) REFERENCES public.mcp_server(id) ON DELETE CASCADE;


--
-- Name: user_mcp_access user_mcp_access_source_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_source_label_id_user_access_label_id_fk FOREIGN KEY (source_label_id) REFERENCES public.user_access_label(id) ON DELETE SET NULL;


--
-- Name: user_mcp_access user_mcp_access_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mcp_access
    ADD CONSTRAINT user_mcp_access_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_model_access user_model_access_granted_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_model_access
    ADD CONSTRAINT user_model_access_granted_by_user_id_fk FOREIGN KEY (granted_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_model_access user_model_access_source_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_model_access
    ADD CONSTRAINT user_model_access_source_label_id_user_access_label_id_fk FOREIGN KEY (source_label_id) REFERENCES public.user_access_label(id) ON DELETE SET NULL;


--
-- Name: user_model_access user_model_access_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_model_access
    ADD CONSTRAINT user_model_access_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_rate_limits user_rate_limits_source_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rate_limits
    ADD CONSTRAINT user_rate_limits_source_label_id_user_access_label_id_fk FOREIGN KEY (source_label_id) REFERENCES public.user_access_label(id) ON DELETE SET NULL;


--
-- Name: user_rate_limits user_rate_limits_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rate_limits
    ADD CONSTRAINT user_rate_limits_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_rate_limits user_rate_limits_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rate_limits
    ADD CONSTRAINT user_rate_limits_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_token_quota user_token_quota_updated_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_token_quota
    ADD CONSTRAINT user_token_quota_updated_by_user_id_fk FOREIGN KEY (updated_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_token_quota user_token_quota_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_token_quota
    ADD CONSTRAINT user_token_quota_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user_tool_permission user_tool_permission_granted_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tool_permission
    ADD CONSTRAINT user_tool_permission_granted_by_user_id_fk FOREIGN KEY (granted_by) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: user_tool_permission user_tool_permission_source_label_id_user_access_label_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tool_permission
    ADD CONSTRAINT user_tool_permission_source_label_id_user_access_label_id_fk FOREIGN KEY (source_label_id) REFERENCES public.user_access_label(id) ON DELETE SET NULL;


--
-- Name: user_tool_permission user_tool_permission_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tool_permission
    ADD CONSTRAINT user_tool_permission_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: web_vitals_log web_vitals_log_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_vitals_log
    ADD CONSTRAINT web_vitals_log_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: webhook_delivery webhook_delivery_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery
    ADD CONSTRAINT webhook_delivery_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: webhook_delivery webhook_delivery_webhook_id_webhook_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_delivery
    ADD CONSTRAINT webhook_delivery_webhook_id_webhook_id_fk FOREIGN KEY (webhook_id) REFERENCES public.webhook(id) ON DELETE CASCADE;


--
-- Name: webhook webhook_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT webhook_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: webhook webhook_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT webhook_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_comment workflow_comment_author_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflow_comment_author_id_user_id_fk FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: workflow_comment workflow_comment_node_id_workflow_node_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflow_comment_node_id_workflow_node_id_fk FOREIGN KEY (node_id) REFERENCES public.workflow_node(id) ON DELETE CASCADE;


--
-- Name: workflow_comment workflow_comment_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_comment
    ADD CONSTRAINT workflow_comment_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_edge workflow_edge_source_workflow_node_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_edge
    ADD CONSTRAINT workflow_edge_source_workflow_node_id_fk FOREIGN KEY (source) REFERENCES public.workflow_node(id) ON DELETE CASCADE;


--
-- Name: workflow_edge workflow_edge_target_workflow_node_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_edge
    ADD CONSTRAINT workflow_edge_target_workflow_node_id_fk FOREIGN KEY (target) REFERENCES public.workflow_node(id) ON DELETE CASCADE;


--
-- Name: workflow_edge workflow_edge_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_edge
    ADD CONSTRAINT workflow_edge_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_execution workflow_execution_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_execution
    ADD CONSTRAINT workflow_execution_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_execution workflow_execution_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_execution
    ADD CONSTRAINT workflow_execution_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_group workflow_group_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_group
    ADD CONSTRAINT workflow_group_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_install workflow_install_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_install
    ADD CONSTRAINT workflow_install_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_install workflow_install_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_install
    ADD CONSTRAINT workflow_install_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow_node workflow_node_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_node
    ADD CONSTRAINT workflow_node_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- Name: workflow workflow_organization_id_organization_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow
    ADD CONSTRAINT workflow_organization_id_organization_id_fk FOREIGN KEY (organization_id) REFERENCES public.organization(id) ON DELETE SET NULL;


--
-- Name: workflow workflow_user_id_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow
    ADD CONSTRAINT workflow_user_id_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_version workflow_version_created_by_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_version
    ADD CONSTRAINT workflow_version_created_by_user_id_fk FOREIGN KEY (created_by) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: workflow_version workflow_version_workflow_id_workflow_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_version
    ADD CONSTRAINT workflow_version_workflow_id_workflow_id_fk FOREIGN KEY (workflow_id) REFERENCES public.workflow(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict GVShlZ7r7B4dEMdPpZVN38Le0vVTdeKUByREJr4mKdCogwxwM1QOmIQKI4GJPWA

