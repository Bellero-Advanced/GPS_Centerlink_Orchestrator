-- Migration 027: API Keys for Programmatic Access
-- Phase 8: White-Label Platform
-- Date: 2026-08-25

-- ========================================
-- API KEYS TABLE
-- ========================================
-- Allow users/tenants to create API keys for integrations

CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES tc_users(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    key_hash VARCHAR(128) UNIQUE NOT NULL,
    key_prefix VARCHAR(16) NOT NULL,  -- First 8 chars for identification
    permissions JSONB DEFAULT '[]'::jsonb,
    rate_limit_per_minute INTEGER DEFAULT 100,
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES tc_users(id),

    -- Constraints
    CONSTRAINT api_keys_name_tenant_unique UNIQUE (tenant_id, name)
);

-- Indexes
CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id) WHERE is_active = true;
CREATE INDEX idx_api_keys_user ON api_keys(user_id) WHERE is_active = true;
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at) WHERE expires_at IS NOT NULL;

-- Comments
COMMENT ON TABLE api_keys IS 'API keys for programmatic access (integrations, webhooks)';
COMMENT ON COLUMN api_keys.key_hash IS 'SHA-256 hash of actual API key (never store plaintext)';
COMMENT ON COLUMN api_keys.key_prefix IS 'First 8 chars for UI display (e.g., "blx_1234...")';
COMMENT ON COLUMN api_keys.permissions IS 'Scoped permissions (subset of user permissions)';

-- ========================================
-- API KEY USAGE LOG (for monitoring)
-- ========================================
CREATE TABLE IF NOT EXISTS api_key_usage (
    id BIGSERIAL PRIMARY KEY,
    api_key_id INTEGER NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
    endpoint VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    response_time_ms INTEGER,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create partitions for current + next 3 months
CREATE TABLE IF NOT EXISTS api_key_usage_2026_08 PARTITION OF api_key_usage
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE IF NOT EXISTS api_key_usage_2026_09 PARTITION OF api_key_usage
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE IF NOT EXISTS api_key_usage_2026_10 PARTITION OF api_key_usage
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE IF NOT EXISTS api_key_usage_2026_11 PARTITION OF api_key_usage
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

-- Indexes on partitions
CREATE INDEX idx_api_key_usage_key_time ON api_key_usage(api_key_id, created_at DESC);
CREATE INDEX idx_api_key_usage_endpoint ON api_key_usage(endpoint);

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function: Generate API key
CREATE OR REPLACE FUNCTION generate_api_key()
RETURNS TEXT AS $$
DECLARE
    key TEXT;
BEGIN
    -- Format: blx_<32 random chars>
    key := 'blx_' || encode(gen_random_bytes(24), 'base64');
    -- Remove URL-unsafe characters
    key := replace(replace(replace(key, '/', '_'), '+', '-'), '=', '');
    RETURN substring(key, 1, 40);
END;
$$ LANGUAGE plpgsql;

-- Function: Hash API key
CREATE OR REPLACE FUNCTION hash_api_key(p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN encode(digest(p_key, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Create API key
CREATE OR REPLACE FUNCTION create_api_key(
    p_tenant_id INTEGER,
    p_user_id INTEGER,
    p_name VARCHAR(128),
    p_permissions JSONB DEFAULT '[]'::jsonb,
    p_expires_days INTEGER DEFAULT NULL,
    p_created_by INTEGER DEFAULT NULL
) RETURNS TABLE(
    id INTEGER,
    api_key TEXT,  -- Only returned once!
    key_prefix VARCHAR(16)
) AS $$
DECLARE
    v_key TEXT;
    v_key_hash TEXT;
    v_key_prefix VARCHAR(16);
    v_expires_at TIMESTAMPTZ;
    v_id INTEGER;
BEGIN
    -- Generate key
    v_key := generate_api_key();
    v_key_hash := hash_api_key(v_key);
    v_key_prefix := substring(v_key, 1, 12);

    -- Calculate expiry
    IF p_expires_days IS NOT NULL THEN
        v_expires_at := NOW() + (p_expires_days || ' days')::INTERVAL;
    END IF;

    -- Insert
    INSERT INTO api_keys (
        tenant_id, user_id, name, key_hash, key_prefix,
        permissions, expires_at, created_by
    ) VALUES (
        p_tenant_id, p_user_id, p_name, v_key_hash, v_key_prefix,
        p_permissions, v_expires_at, p_created_by
    ) RETURNING api_keys.id INTO v_id;

    -- Return key (ONLY TIME IT'S EVER SHOWN)
    RETURN QUERY SELECT v_id, v_key, v_key_prefix;
END;
$$ LANGUAGE plpgsql;

-- Function: Validate API key
CREATE OR REPLACE FUNCTION validate_api_key(p_key TEXT)
RETURNS TABLE(
    id INTEGER,
    tenant_id INTEGER,
    user_id INTEGER,
    permissions JSONB,
    rate_limit_per_minute INTEGER
) AS $$
DECLARE
    v_key_hash TEXT;
BEGIN
    v_key_hash := hash_api_key(p_key);

    RETURN QUERY
    SELECT
        ak.id,
        ak.tenant_id,
        ak.user_id,
        ak.permissions,
        ak.rate_limit_per_minute
    FROM api_keys ak
    WHERE ak.key_hash = v_key_hash
      AND ak.is_active = true
      AND (ak.expires_at IS NULL OR ak.expires_at > NOW());

    -- Update last_used_at
    UPDATE api_keys
    SET last_used_at = NOW()
    WHERE key_hash = v_key_hash;
END;
$$ LANGUAGE plpgsql;

-- Function: Revoke API key
CREATE OR REPLACE FUNCTION revoke_api_key(p_key_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE api_keys
    SET is_active = false
    WHERE id = p_key_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- VIEW: API Keys Summary
-- ========================================
CREATE OR REPLACE VIEW v_api_keys_summary AS
SELECT
    ak.id,
    ak.tenant_id,
    t.name AS tenant_name,
    ak.user_id,
    u.name AS user_name,
    ak.name,
    ak.key_prefix,
    ak.is_active,
    ak.rate_limit_per_minute,
    ak.last_used_at,
    ak.expires_at,
    ak.created_at,
    COUNT(aku.id) FILTER (WHERE aku.created_at >= NOW() - INTERVAL '24 hours') AS requests_today
FROM api_keys ak
LEFT JOIN tenants t ON ak.tenant_id = t.id
LEFT JOIN tc_users u ON ak.user_id = u.id
LEFT JOIN api_key_usage aku ON ak.id = aku.api_key_id
GROUP BY ak.id, t.name, u.name;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    partition_count INTEGER;
BEGIN
    -- Check if tables created
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'api_keys') THEN
        RAISE EXCEPTION 'api_keys table not created';
    END IF;

    -- Check partitions
    SELECT COUNT(*) INTO partition_count
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename LIKE 'api_key_usage_2026%';

    IF partition_count < 4 THEN
        RAISE EXCEPTION 'Expected 4 partitions, found %', partition_count;
    END IF;

    RAISE NOTICE 'Migration 027: ✅ API keys table created with % partitions', partition_count;
END $$;

-- ========================================
-- USAGE EXAMPLES
-- ========================================

-- Create API key:
-- SELECT * FROM create_api_key(1, 1, 'Production API', '["vehicles:read", "positions:read"]'::jsonb, 365);
-- → Returns: id, api_key (blx_xxx...), key_prefix

-- Validate key:
-- SELECT * FROM validate_api_key('blx_abc123...');
-- → Returns tenant_id, user_id, permissions if valid

-- Revoke key:
-- SELECT revoke_api_key(123);

-- List keys:
-- SELECT * FROM v_api_keys_summary WHERE tenant_id = 1;
