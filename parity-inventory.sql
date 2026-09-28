-- parity-inventory.sql — one line per catalog object, in a form that is the
-- SAME whether the object was created by db/<ver>/schema.sql on a scratch
-- database or by twenty migrate-*.sql deltas on the live one. Run identically
-- on both sides by ./schema-parity.sh with `psql -tA`, then sorted and diffed.
--
-- Deliberately NOT included: attnum (ordinal positions legitimately differ
-- between ADD COLUMN and a fresh CREATE TABLE), owners, tablespaces, stats,
-- extension versions, row data. Whitespace inside policy predicates and
-- function bodies is collapsed, and SQL comments inside function bodies are
-- dropped before hashing: a migrate-*.sql delta keeps its `--` commentary in
-- pg_proc.prosrc while the pg_dump'd schema.sql renders the same function
-- without it, and the code is what parity judges. search_path is emptied so
-- every regclass / regtype renders schema-qualified the same way on both
-- sides.
\set QUIET on
SET search_path = '';

-- schemas we care about
SELECT 'schema|' || nspname FROM pg_catalog.pg_namespace WHERE nspname IN ('public', 'drizzle') ORDER BY 1;

-- extensions (names only)
SELECT 'ext|' || extname FROM pg_catalog.pg_extension ORDER BY 1;

-- tables and partitioned tables, with their RLS posture
SELECT 'table|' || c.oid::regclass::text || '|' || c.relkind::text || '|rls=' || c.relrowsecurity || '|force=' || c.relforcerowsecurity
  FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('public', 'drizzle') AND c.relkind IN ('r', 'p')
 ORDER BY 1;

-- columns: type, nullability, default, identity, generated (no ordinal)
SELECT 'column|' || a.attrelid::regclass::text || '.' || a.attname
       || '|' || pg_catalog.format_type(a.atttypid, a.atttypmod)
       || '|notnull=' || a.attnotnull
       || '|default=' || COALESCE(pg_catalog.pg_get_expr(d.adbin, d.adrelid), '')
       || '|identity=' || a.attidentity::text || '|gen=' || a.attgenerated::text
  FROM pg_catalog.pg_attribute a
  JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_catalog.pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
 WHERE n.nspname IN ('public', 'drizzle') AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
 ORDER BY 1;

-- indexes: name in field 3, definition WITHOUT the name after it (a rename with
-- an identical definition is then a name-only advisory, not a finding)
SELECT 'index|' || schemaname || '.' || tablename || '|' || indexname || '|'
       || regexp_replace(indexdef, '^CREATE (UNIQUE )?INDEX \S+ ON ', 'CREATE \1INDEX ON ')
  FROM pg_catalog.pg_indexes
 WHERE schemaname IN ('public', 'drizzle')
 ORDER BY 1;

-- constraints: name in field 3, then type, definition, FK actions, validity.
-- CHECK bodies are compared in a cast-and-paren-stripped form: a CHECK created
-- by a migration deparses as ARRAY[('a'::character varying)::text, …] while the
-- same CHECK created by pg_dump's schema.sql deparses as (ARRAY['a'::character
-- varying, …])::text[] — identical semantics, different rendering.
SELECT 'constraint|' || c.conrelid::regclass::text || '|' || c.conname || '|' || c.contype::text
       || '|' || CASE WHEN c.contype = 'c'
                      THEN regexp_replace(regexp_replace(regexp_replace(pg_catalog.pg_get_constraintdef(c.oid),
                             '::(character varying|text\[\]|text|integer|bigint|numeric)', '', 'g'), '[()]', '', 'g'), '\s+', ' ', 'g')
                      ELSE pg_catalog.pg_get_constraintdef(c.oid) END
       || '|del=' || c.confdeltype::text || '|upd=' || c.confupdtype::text
       || '|deferrable=' || c.condeferrable || '|valid=' || c.convalidated
  FROM pg_catalog.pg_constraint c JOIN pg_catalog.pg_namespace n ON n.oid = c.connamespace
 WHERE n.nspname IN ('public', 'drizzle') AND c.conrelid <> 0
 ORDER BY 1;

-- policies: predicates with whitespace collapsed
SELECT 'policy|' || schemaname || '.' || tablename || '|' || policyname || '|' || permissive || '|' || COALESCE(roles::text, '')
       || '|' || cmd
       || '|' || regexp_replace(COALESCE(qual, ''), '\s+', ' ', 'g')
       || '|' || regexp_replace(COALESCE(with_check, ''), '\s+', ' ', 'g')
  FROM pg_catalog.pg_policies
 WHERE schemaname IN ('public', 'drizzle')
 ORDER BY 1;

-- triggers (non-internal)
SELECT 'trigger|' || t.tgrelid::regclass::text || '|' || t.tgname || '|' || pg_catalog.pg_get_triggerdef(t.oid)
  FROM pg_catalog.pg_trigger t JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('public', 'drizzle') AND NOT t.tgisinternal
 ORDER BY 1;

-- functions: signature, result, security/volatility, body hash (comments dropped, whitespace collapsed).
-- Comment stripping is textual: a `--` or `/*` inside a string literal is also
-- dropped, identically on both sides, so parity stays consistent — it only
-- stops noticing a literal that differs after such a token.
SELECT 'function|' || n.nspname || '.' || p.proname || '(' || pg_catalog.pg_get_function_identity_arguments(p.oid) || ')'
       || '|' || pg_catalog.pg_get_function_result(p.oid)
       || '|secdef=' || p.prosecdef || '|vol=' || p.provolatile::text
       || '|config=' || COALESCE(array_to_string(p.proconfig, ','), '')
       || '|' || md5(regexp_replace(
                       regexp_replace(
                         regexp_replace(p.prosrc, '/\*.*?\*/', '', 'g'),   -- /* block */ comments
                         '--[^\n]*', '', 'g'),                            -- -- line comments
                       '\s+', ' ', 'g'))
  FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
 WHERE n.nspname IN ('public', 'drizzle')
 ORDER BY 1;

-- enum types and their labels
SELECT 'enum|' || n.nspname || '.' || t.typname || '|' || string_agg(e.enumlabel, ',' ORDER BY e.enumsortorder)
  FROM pg_catalog.pg_type t JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace JOIN pg_catalog.pg_enum e ON e.enumtypid = t.oid
 WHERE n.nspname IN ('public', 'drizzle')
 GROUP BY n.nspname, t.typname
 ORDER BY 1;

-- partitions and their bounds
SELECT 'partition|' || i.inhparent::regclass::text || '|' || i.inhrelid::regclass::text || '|' || pg_catalog.pg_get_expr(c.relpartbound, c.oid)
  FROM pg_catalog.pg_inherits i JOIN pg_catalog.pg_class c ON c.oid = i.inhrelid JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname IN ('public', 'drizzle') AND c.relpartbound IS NOT NULL
 ORDER BY 1;

-- sequences (names)
SELECT 'sequence|' || schemaname || '.' || sequencename FROM pg_catalog.pg_sequences WHERE schemaname IN ('public', 'drizzle') ORDER BY 1;

-- what the app role can do, per table, and the default privileges it inherits
SELECT 'grant|' || table_schema || '.' || table_name || '|' || string_agg(privilege_type, ',' ORDER BY privilege_type)
  FROM information_schema.role_table_grants
 WHERE grantee = 'neo_gen' AND table_schema IN ('public', 'drizzle')
 GROUP BY table_schema, table_name
 ORDER BY 1;
SELECT 'grant-schema|' || n.nspname || '|usage=' || pg_catalog.has_schema_privilege('neo_gen', n.oid, 'USAGE')
  FROM pg_catalog.pg_namespace n WHERE n.nspname IN ('public', 'drizzle') ORDER BY 1;
SELECT 'defacl|' || n.nspname || '|' || d.defaclobjtype::text || '|' || d.defaclacl::text
  FROM pg_catalog.pg_default_acl d JOIN pg_catalog.pg_namespace n ON n.oid = d.defaclnamespace
 WHERE n.nspname IN ('public', 'drizzle')
 ORDER BY 1;
