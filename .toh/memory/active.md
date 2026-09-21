# 🎯 Active Work

**Status:** ✅ DLT Manual Override — DEPLOYED TO PRODUCTION

**Last Completed:** 2026-09-21 15:30 ICT

**What Was Done (full deployment):**
- ✅ Migrations applied to Supabase prod (zenfuxlykduaxrsnhmlq):
  - `dlt_manual_overrides` + `dlt_transmission_log` tables created
  - Fixed: dropped invalid FK to `tc_devices` (Traccar is a separate DB)
  - Fixed: added `updated_at` column + trigger, `created_by` default, RLS write policies
  - Fixed: `pg_net` extension added (was missing — cron's net.http_post needs it)
- ✅ Cron job `send-dlt-batch-60s` active, fires every 60s → HTTP 200 confirmed
- ✅ Edge Functions deployed (all ACTIVE):
  - `send-dlt-batch` (--no-verify-jwt, called by cron)
  - `overdue-checker`
  - `payment-reconcile`
- ✅ Frontend aligned with real schema (commit 4076dfb):
  - useCreateOverride: removed non-existent `speed` col + GENERATED `is_active` write, added `created_by`
  - useStopOverride: only sets `stopped_at` (is_active is generated)
  - useTransmissionHistory: fixed col names `batch`/`response`
- ✅ CI green: tsc + lint + build pass, deployed to Cloudflare Pages

**Migration tracking note:** billing/payment migrations were applied out-of-band
(no tracking table). Backfilled `supabase_migrations.schema_migrations` with those
4 versions so `db push` only applies new ones.

**Verified live:**
- `curl POST send-dlt-batch` → `{"message":"No active overrides"}` HTTP 200
- `cron.job_run_details` → succeeded every minute
- `net._http_response` → status 200

**Next Work:** (ไม่มีงานค้าง — ระบบ DLT Manual พร้อมใช้งานแล้ว รอคำสั่งใหม่)
