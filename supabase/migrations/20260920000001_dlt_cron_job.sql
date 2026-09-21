-- Migration: DLT Cron Job
-- Created: 2026-09-20
-- Purpose: Schedule send-dlt-batch Edge Function to run every 60 seconds

-- ============================================================================
-- IMPORTANT: Manual Configuration Required
-- ============================================================================
-- After applying this migration, you MUST manually set the service role key:
--
--   ALTER DATABASE postgres
--   SET app.settings.service_role_key = '<YOUR_SUPABASE_SERVICE_ROLE_KEY>';
--
-- The key is found in Supabase Dashboard → Settings → API → service_role key
-- ============================================================================

-- Enable pg_cron + pg_net extensions
-- (pg_net provides net.http_post used by the scheduled job)
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Schedule send-dlt-batch to run every 1 minute
-- Idempotent: drop any prior job with the same name first
SELECT cron.unschedule(jobid)
  FROM cron.job
  WHERE jobname = 'send-dlt-batch-60s';

SELECT cron.schedule(
  'send-dlt-batch-60s',
  '*/1 * * * *',  -- Every 1 minute (cron format)
  $$
  SELECT net.http_post(
    url := 'https://zenfuxlykduaxrsnhmlq.supabase.co/functions/v1/send-dlt-batch',
    headers := jsonb_build_object(
      'Authorization',
      'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    timeout_milliseconds := 30000
  ) AS request_id;
  $$
);

-- Verify the job was created
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'send-dlt-batch-60s'
  ) THEN
    RAISE NOTICE 'Cron job created successfully: send-dlt-batch-60s';
  ELSE
    RAISE EXCEPTION 'Failed to create cron job';
  END IF;
END $$;
