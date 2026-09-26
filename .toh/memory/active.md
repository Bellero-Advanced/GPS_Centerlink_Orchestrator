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

**Just Completed:** 2026-09-21 16:45 ICT — DLT Manual page design polish ✅
- Full-screen layout (เอา container padding ออก)
- Color-fill UI (ใช้ fill-block pattern + surface tokens แทน border cards)
- rounded-sm ทุก component (tabs, inputs, buttons, tables)
- SearchSelect สำหรับ dropdown รถ (ค้นหาได้ + แสดง IMEI)
- Commit: `08fcbcd` · CI: green ✅ · Deploy: Cloudflare Pages success

**Just Completed:** 2026-09-25 — Timezone +7h fix ✅ (Traccar per-device tz + 3.9M-row backfill + web d43004a)

**Just Completed:** 2026-09-25 — Reports on TimescaleDB ✅ (plan completed)
- geocoder.onRequest=false (trips 7d 96s→0.2s) · nginx rate limit per real IP · Redis removed · tc_positions_ts archive (3.5GB→314MB, forever) · fleet.segments 213/213 · /api/fleet (fleet 7d 0.6s) · mobile nav 4 items · log rotation
- web 31a7b80 (CI green, deployed) · infra fff40fa · VM live

**Next Work:** monitor `tz-audit.sql` weekly · 10 pre-existing failing web tests (vehicleStatus/FloatingVehiclePanel/positionOwnership)

**Plan Status:** completed ✅ (`.toh/plan.md`) · แผนเก่า → `archive/plan-2026-09-24-delete-user.md`
