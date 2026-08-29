-- Migration 026: Tenant Branding Configuration
-- Phase 8: White-Label Platform
-- Date: 2026-08-25

-- ========================================
-- TENANT BRANDING
-- ========================================
-- Allow tenants to customize their platform appearance

-- Add branding column to tenants table (already has name, email)
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS branding JSONB DEFAULT '{
  "logo": null,
  "primaryColor": "#1E40AF",
  "secondaryColor": "#3B82F6",
  "accentColor": "#10B981",
  "companyName": null,
  "tagline": null,
  "supportEmail": null,
  "supportPhone": null,
  "websiteUrl": null,
  "customDomain": null
}'::jsonb;

-- Index for faster branding lookups
CREATE INDEX IF NOT EXISTS idx_tenants_branding ON tenants USING GIN(branding);

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function: Update tenant branding
CREATE OR REPLACE FUNCTION update_tenant_branding(
    p_tenant_id INTEGER,
    p_branding JSONB
) RETURNS JSONB AS $$
DECLARE
    new_branding JSONB;
BEGIN
    -- Merge with existing branding (keeps defaults for missing fields)
    UPDATE tenants
    SET branding = branding || p_branding,
        updated_at = NOW()
    WHERE id = p_tenant_id
    RETURNING branding INTO new_branding;

    RETURN new_branding;
END;
$$ LANGUAGE plpgsql;

-- Function: Get tenant branding by domain
CREATE OR REPLACE FUNCTION get_tenant_by_domain(
    p_domain TEXT
) RETURNS TABLE(
    id INTEGER,
    name VARCHAR(128),
    branding JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id, t.name, t.branding
    FROM tenants t
    WHERE t.branding->>'customDomain' = p_domain
       OR t.name = p_domain  -- Fallback to name match
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- SEED DEFAULT BRANDING
-- ========================================
-- Update existing tenant 1 with Bellerox default branding

UPDATE tenants
SET branding = jsonb_build_object(
    'logo', '/logo.png',
    'primaryColor', '#1E40AF',
    'secondaryColor', '#3B82F6',
    'accentColor', '#10B981',
    'companyName', 'Bellerox GPS',
    'tagline', 'Real-time Fleet Management',
    'supportEmail', 'support@bellerox.com',
    'supportPhone', '+66-2-123-4567',
    'websiteUrl', 'https://bellerox.com',
    'customDomain', null
)
WHERE id = 1;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    branding_count INTEGER;
BEGIN
    -- Check if branding column exists and has data
    SELECT COUNT(*) INTO branding_count
    FROM tenants
    WHERE branding IS NOT NULL;

    IF branding_count > 0 THEN
        RAISE NOTICE 'Migration 026: ✅ Tenant branding configured for % tenants', branding_count;
    ELSE
        RAISE EXCEPTION 'Tenant branding configuration failed';
    END IF;
END $$;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Update tenant branding (API call):
-- SELECT update_tenant_branding(1, '{"primaryColor": "#FF0000", "companyName": "My Company"}'::jsonb);

-- Get tenant by custom domain:
-- SELECT * FROM get_tenant_by_domain('gps.mycompany.com');

-- Get branding for display:
-- SELECT branding FROM tenants WHERE id = 1;
