-- migrate-1.53.0.sql — schema delta 1.52.0 → 1.53.0: background runs keep a capped record of each tool call, with chat's retention (F-14-1). Source migration 0054 (journaled migration 0054_background_tool_call_records.sql), carried whole below.
-- Route: ./update.sh   (the ordinary rolling path — see FORWARD-ONLY below)
--
-- WHAT IT IS FOR, IN ONE PARAGRAPH.
--
-- Agent, A2A and scheduled runs now keep a capped record of every tool call
-- (input, output or error): agent and A2A runs in the existing
-- `orchestration_run.steps` json, scheduled runs in the new
-- `cron_run_log.tool_calls`. So that those records go exactly when chat's
-- tool parts would, `orchestration_run` gains `user_id` (FK → user, ON DELETE
-- CASCADE) and its `thread_id` FK becomes ON DELETE CASCADE (was SET NULL).
-- No existing row is rewritten.
--
-- THIS FILE MUST SHIP WITH THE IMAGE THAT DECLARES THE COLUMNS (or before
-- it). An image ahead of this delta fails every agent run (`insertRun` names
-- `user_id`) and the scheduler's run reads with 42703; the boot sentinels name
-- it first.
--
-- FORWARD-ONLY and re-runnable (ADD COLUMN / CREATE INDEX IF NOT EXISTS,
-- guarded ADD CONSTRAINT, the thread key found by its columns and replaced
-- only when it is not already the CASCADE key). Rolling back the IMAGE is
-- safe: pre-1.53.0 code never reads the new columns, and the CASCADE only
-- removes rows that code could no longer reach. `SET lock_timeout` bounds
-- every lock wait.
--
-- RLS in this bundle: none — neither table carries a policy. schema.sql is
-- 1.52.0's plus exactly these objects; grants.sql is 1.52.0's, unchanged;
-- seed.sql re-renders the journal stamp through 0054.
--
-- ROLLBACK.
--
--     Forward-only. To remove the schema objects:
--     ALTER TABLE cron_run_log DROP COLUMN IF EXISTS tool_calls;
--     ALTER TABLE orchestration_run DROP COLUMN IF EXISTS user_id;
--     ALTER TABLE orchestration_run DROP CONSTRAINT orchestration_run_thread_id_chat_thread_id_fk;
--     ALTER TABLE orchestration_run ADD CONSTRAINT orchestration_run_thread_id_chat_thread_id_fk
--       FOREIGN KEY (thread_id) REFERENCES chat_thread(id) ON DELETE SET NULL;

SET lock_timeout = '5s';
ALTER TABLE "cron_run_log" ADD COLUMN IF NOT EXISTS "tool_calls" json;
ALTER TABLE "orchestration_run" ADD COLUMN IF NOT EXISTS "user_id" uuid;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orchestration_run_user_id_user_id_fk'
      AND conrelid = to_regclass('orchestration_run')
  ) THEN
    ALTER TABLE "orchestration_run"
      ADD CONSTRAINT "orchestration_run_user_id_user_id_fk"
      FOREIGN KEY ("user_id") REFERENCES "user"("id")
      ON DELETE CASCADE ON UPDATE NO ACTION;
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS "orchestration_run_user_id_idx" ON "orchestration_run" USING btree ("user_id");
DO $$
DECLARE
  fk record;
BEGIN
  FOR fk IN
    SELECT c.conname, c.confdeltype
    FROM pg_constraint c
    JOIN pg_attribute a
      ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
    WHERE c.contype = 'f'
      AND c.conrelid = to_regclass('orchestration_run')
      AND c.confrelid = to_regclass('chat_thread')
      AND array_length(c.conkey, 1) = 1
      AND a.attname = 'thread_id'
  LOOP
    IF fk.confdeltype <> 'c'
       OR fk.conname <> 'orchestration_run_thread_id_chat_thread_id_fk' THEN
      EXECUTE format('ALTER TABLE "orchestration_run" DROP CONSTRAINT %I', fk.conname);
    END IF;
  END LOOP;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orchestration_run_thread_id_chat_thread_id_fk'
      AND conrelid = to_regclass('orchestration_run')
  ) THEN
    ALTER TABLE "orchestration_run"
      ADD CONSTRAINT "orchestration_run_thread_id_chat_thread_id_fk"
      FOREIGN KEY ("thread_id") REFERENCES "chat_thread"("id")
      ON DELETE CASCADE ON UPDATE NO ACTION NOT VALID;
  END IF;
END $$;
ALTER TABLE "orchestration_run" VALIDATE CONSTRAINT "orchestration_run_thread_id_chat_thread_id_fk";
