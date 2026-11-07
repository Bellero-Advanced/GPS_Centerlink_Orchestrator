# Supabase Migrations — policy model

> Read this before adding a table or writing a policy. Getting the `TO` clause
> wrong here causes either a silent 401 on every request or a data leak.

## The constraint that drives every decision

**The app does not authenticate against Supabase.**

Login, session restore and every permission check go through Traccar
(`POST /api/session`, Basic auth on each request). Supabase is used purely as a
Postgres-with-an-HTTP-API. There is therefore **no Supabase JWT** on the normal
request path, so `auth.uid()` is always `null` and any policy written
`TO authenticated` matches nobody.

This is recorded in `~/.claude/.../memory/supabase-rls-anon-no-session.md` from a
production incident where every request returned 401.

## Access matrix

| Table group | `anon` | `authenticated` | `service_role` |
|---|---|---|---|
| `cl_tenants` | read | — | full |
| `cl_fuel_logs`, `cl_maintenance_records`, `cl_inspections`, `cl_dispatch_*`, `cl_predictive_maintenance`, `cl_alert_rules` | full | — | full |
| `dlt_manual_overrides`, `dlt_transmission_logs` | full | — | full |
| `cl_payment_slots`, `cl_payment_queue` | — | read | full |
| `billing_*` | — | read own (`tenant_id = auth.uid()`) | full |
| `cl_audit_logs`, `cl_roles`, `cl_role_permissions`, `cl_user_roles` | — | — | full *(Postgres only, via api-gateway)* |

`service_role` always gets `FOR ALL USING (true) WITH CHECK (true)` — it bypasses
RLS by design and is **never** shipped to the frontend.

## Why `cl_audit_logs` and the role tables are service-only

Those live in the Traccar PostgreSQL instance, not Supabase. They are reached
exclusively through `api-gateway/routes/admin.ts`, which verifies the caller
against Traccar and requires `superadmin`. No Supabase policy is involved.

## Adding a new table — checklist

1. `CREATE TABLE IF NOT EXISTS` (migrations are re-runnable).
2. `ALTER TABLE … ENABLE ROW LEVEL SECURITY;` — **required, not optional**.
   A table without RLS in `public` is fully readable with the publishable key.
3. Add a policy for `service_role` and, if the browser reads it, for `anon`.
4. Prefer `DROP POLICY IF EXISTS … ; CREATE POLICY …` so re-running is safe.
5. For tables driven by a `DO $$ … $$` loop (see
   `20261106000000_operational_records.sql`), add the table name to the array.

## Migrations in this folder

| File | Adds | RLS |
|---|---|---|
| `20260802000000_billing.sql` | billing subscriptions/invoices/events | enabled, `authenticated` read own |
| `20260830000000_payment_slots.sql` | `cl_payment_slots` + utilization fn | enabled, `authenticated` read |
| `20260830000001_payment_queue.sql` | `cl_payment_queue` | enabled, `authenticated` read |
| `20260830000002_slot_cleanup.sql` | cleanup fn + `cl_slot_cleanup_log` | **added by 20261107** |
| `20260920000000_dlt_manual_override.sql` | DLT override + transmission logs | **added by 20261107** (was missing) |
| `20260920000001_dlt_cron_job.sql` | pg_cron schedule | n/a |
| `20260921000000_add_license_plate.sql` | `tc_devices.license_plate` | n/a (Traccar table) |
| `20261106000000_operational_records.sql` | 7 operational tables | enabled, `anon` full |
| `20261107000000_rls_hardening.sql` | RLS for the 3 gaps above | enabled |

## Applying

`supabase db push` where the CLI is linked, otherwise paste the file into the
Supabase SQL editor. Every file is idempotent, so re-applying is safe.

Verify after applying:

```sql
SELECT tablename, rowsecurity
  FROM pg_tables
 WHERE schemaname = 'public'
 ORDER BY rowsecurity, tablename;
```

Any row with `rowsecurity = false` in `public` is a finding.