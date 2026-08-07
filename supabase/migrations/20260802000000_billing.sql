-- ═══════════════════════════════════════════════════════
-- Billing Schema — Centerlink GPS
-- Run via: supabase db push  OR  psql -f this file
-- Tables: billing_subscriptions, billing_invoices, billing_payment_events
-- ═══════════════════════════════════════════════════════

-- ── Enums ────────────────────────────────────────────────────────────

CREATE TYPE subscription_plan AS ENUM ('basic', 'pro');
CREATE TYPE subscription_status AS ENUM ('active', 'pending', 'overdue', 'locked', 'trial', 'cancelled');
CREATE TYPE payment_method AS ENUM ('qr30_webhook', 'slip_upload', 'manual');

-- ── billing_subscriptions ────────────────────────────────────────────

CREATE TABLE billing_subscriptions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        TEXT        NOT NULL,           -- Traccar user id or domain
  device_id        INTEGER     NOT NULL,           -- Traccar device id
  vehicle_imei     TEXT        NOT NULL,
  plan             subscription_plan NOT NULL DEFAULT 'basic',
  status           subscription_status NOT NULL DEFAULT 'active',
  start_date       TIMESTAMPTZ NOT NULL DEFAULT now(),
  end_date         TIMESTAMPTZ NOT NULL,           -- next billing date
  monthly_amount   NUMERIC(10,2) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (tenant_id, device_id)
);

CREATE INDEX idx_billing_subs_tenant   ON billing_subscriptions (tenant_id);
CREATE INDEX idx_billing_subs_status   ON billing_subscriptions (status);
CREATE INDEX idx_billing_subs_end_date ON billing_subscriptions (end_date);

-- ── billing_invoices ─────────────────────────────────────────────────

CREATE TABLE billing_invoices (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id  UUID NOT NULL REFERENCES billing_subscriptions(id) ON DELETE CASCADE,
  amount           NUMERIC(10,2) NOT NULL,
  due_date         DATE NOT NULL,
  paid_at          TIMESTAMPTZ,
  invoice_ref      VARCHAR(24) NOT NULL UNIQUE,    -- shown on QR e.g. BLX-0012-A3F9
  qr_payload       TEXT,                           -- raw PromptPay QR payload string
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_billing_invoices_sub    ON billing_invoices (subscription_id);
CREATE INDEX idx_billing_invoices_due    ON billing_invoices (due_date);
CREATE INDEX idx_billing_invoices_unpaid ON billing_invoices (due_date) WHERE paid_at IS NULL;

-- ── billing_payment_events ───────────────────────────────────────────

CREATE TABLE billing_payment_events (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id     UUID NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
  method         payment_method NOT NULL,
  amount         NUMERIC(10,2) NOT NULL,
  verified_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  provider_ref   TEXT,                             -- EasySlip txRef or SCB ref
  raw_response   JSONB
);

CREATE INDEX idx_billing_events_invoice ON billing_payment_events (invoice_id);

-- ── Row Level Security ───────────────────────────────────────────────
-- Tenants can read their own rows; only service_role can write.

ALTER TABLE billing_subscriptions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_invoices       ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_payment_events ENABLE ROW LEVEL SECURITY;

-- Tenants read own subscriptions (tenant_id matches JWT sub or custom claim)
CREATE POLICY "tenant_read_own_subs"
  ON billing_subscriptions FOR SELECT
  USING (tenant_id = auth.uid()::text);

-- Service role bypasses RLS — used by Edge Functions + admin
-- (service_role key never exposed to frontend)
