-- Migration 020: Create Audit Log Table
-- RBAC Phase 2: Compliance and security audit trail
-- Date: 2026-08-25

-- ========================================
-- AUDIT_LOG TABLE (Partitioned by month)
-- ========================================
-- Logs all write operations for compliance and security

CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES tc_users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(50) NOT NULL,
    resource_id INTEGER,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Indexes for common queries
CREATE INDEX idx_audit_tenant_time ON audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_user_time ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_resource ON audit_log(resource, resource_id) WHERE resource_id IS NOT NULL;
CREATE INDEX idx_audit_details ON audit_log USING GIN(details);

-- Comments
COMMENT ON TABLE audit_log IS 'Audit trail for all write operations (partitioned by month)';
COMMENT ON COLUMN audit_log.action IS 'Format: resource:action (e.g., vehicles:write, vehicles:delete)';
COMMENT ON COLUMN audit_log.details IS 'Full request body + response status';

-- ========================================
-- CREATE PARTITIONS (Current + Next 3 months)
-- ========================================

-- August 2026
CREATE TABLE IF NOT EXISTS audit_log_2026_08 PARTITION OF audit_log
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

-- September 2026
CREATE TABLE IF NOT EXISTS audit_log_2026_09 PARTITION OF audit_log
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

-- October 2026
CREATE TABLE IF NOT EXISTS audit_log_2026_10 PARTITION OF audit_log
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

-- November 2026
CREATE TABLE IF NOT EXISTS audit_log_2026_11 PARTITION OF audit_log
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function: Log audit event
CREATE OR REPLACE FUNCTION log_audit_event(
    p_tenant_id INTEGER,
    p_user_id INTEGER,
    p_action VARCHAR(100),
    p_resource VARCHAR(50),
    p_resource_id INTEGER DEFAULT NULL,
    p_details JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
    audit_id BIGINT;
BEGIN
    INSERT INTO audit_log (
        tenant_id, user_id, action, resource, resource_id,
        details, ip_address, user_agent
    ) VALUES (
        p_tenant_id, p_user_id, p_action, p_resource, p_resource_id,
        p_details, p_ip_address, p_user_agent
    ) RETURNING id INTO audit_id;

    RETURN audit_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get audit log for user
CREATE OR REPLACE FUNCTION get_user_audit_log(
    p_user_id INTEGER,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE(
    id BIGINT,
    action VARCHAR(100),
    resource VARCHAR(50),
    resource_id INTEGER,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id, a.action, a.resource, a.resource_id,
        a.details, a.ip_address, a.created_at
    FROM audit_log a
    WHERE a.user_id = p_user_id
    ORDER BY a.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: Get audit log for tenant
CREATE OR REPLACE FUNCTION get_tenant_audit_log(
    p_tenant_id INTEGER,
    p_from_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days',
    p_to_date TIMESTAMPTZ DEFAULT NOW(),
    p_limit INTEGER DEFAULT 1000
) RETURNS TABLE(
    id BIGINT,
    user_id INTEGER,
    user_name VARCHAR(128),
    action VARCHAR(100),
    resource VARCHAR(50),
    resource_id INTEGER,
    details JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id, a.user_id, u.name, a.action, a.resource,
        a.resource_id, a.details, a.ip_address, a.created_at
    FROM audit_log a
    LEFT JOIN tc_users u ON a.user_id = u.id
    WHERE a.tenant_id = p_tenant_id
      AND a.created_at >= p_from_date
      AND a.created_at <= p_to_date
    ORDER BY a.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- VIEW: Recent Audit Activity
-- ========================================
CREATE OR REPLACE VIEW v_audit_recent AS
SELECT
    a.id,
    t.name AS tenant_name,
    u.name AS user_name,
    u.email AS user_email,
    a.action,
    a.resource,
    a.resource_id,
    a.ip_address,
    a.created_at,
    a.details->>'method' AS http_method,
    a.details->>'url' AS request_url,
    (a.details->>'status')::INTEGER AS response_status
FROM audit_log a
LEFT JOIN tenants t ON a.tenant_id = t.id
LEFT JOIN tc_users u ON a.user_id = u.id
WHERE a.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY a.created_at DESC;

COMMENT ON VIEW v_audit_recent IS 'Last 24 hours of audit activity';

-- ========================================
-- VIEW: Audit Statistics by User
-- ========================================
CREATE OR REPLACE VIEW v_audit_stats_by_user AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.email,
    t.name AS tenant_name,
    COUNT(*) AS total_actions,
    COUNT(*) FILTER (WHERE a.created_at >= NOW() - INTERVAL '24 hours') AS actions_today,
    COUNT(*) FILTER (WHERE a.created_at >= NOW() - INTERVAL '7 days') AS actions_this_week,
    MAX(a.created_at) AS last_action_at,
    COUNT(DISTINCT a.action) AS unique_actions,
    COUNT(DISTINCT a.ip_address) AS unique_ips
FROM audit_log a
JOIN tc_users u ON a.user_id = u.id
LEFT JOIN tenants t ON a.tenant_id = t.id
GROUP BY u.id, u.name, u.email, t.name;

COMMENT ON VIEW v_audit_stats_by_user IS 'Audit activity statistics per user';

-- ========================================
-- AUTOMATIC PARTITION CREATION
-- ========================================
-- Function to create next month's partition

CREATE OR REPLACE FUNCTION create_audit_log_partition(
    p_year INTEGER,
    p_month INTEGER
) RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    -- Calculate dates
    start_date := make_date(p_year, p_month, 1);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'audit_log_' || p_year || '_' || LPAD(p_month::TEXT, 2, '0');

    -- Create partition if not exists
    EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF audit_log FOR VALUES FROM (%L) TO (%L)',
        partition_name, start_date, end_date
    );

    RETURN partition_name;
END;
$$ LANGUAGE plpgsql;

-- Schedule: Create next 3 months of partitions
-- (Run this monthly via cron or at server startup)
DO $$
DECLARE
    current_month INTEGER;
    current_year INTEGER;
    i INTEGER;
BEGIN
    current_month := EXTRACT(MONTH FROM NOW());
    current_year := EXTRACT(YEAR FROM NOW());

    -- Create next 3 months
    FOR i IN 1..3 LOOP
        PERFORM create_audit_log_partition(current_year, current_month);

        -- Increment month
        current_month := current_month + 1;
        IF current_month > 12 THEN
            current_month := 1;
            current_year := current_year + 1;
        END IF;
    END LOOP;

    RAISE NOTICE 'Created audit log partitions for next 3 months';
END $$;

-- ========================================
-- RETENTION POLICY
-- ========================================
-- Function to drop old partitions (> 12 months)

CREATE OR REPLACE FUNCTION cleanup_old_audit_partitions() RETURNS INTEGER AS $$
DECLARE
    partition_record RECORD;
    dropped_count INTEGER := 0;
    retention_date DATE;
BEGIN
    retention_date := CURRENT_DATE - INTERVAL '12 months';

    FOR partition_record IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename LIKE 'audit_log_%'
          AND tablename ~ '^audit_log_\d{4}_\d{2}$'
    LOOP
        -- Extract year and month from partition name
        DECLARE
            year INTEGER;
            month INTEGER;
            partition_date DATE;
        BEGIN
            year := SUBSTRING(partition_record.tablename FROM 11 FOR 4)::INTEGER;
            month := SUBSTRING(partition_record.tablename FROM 16 FOR 2)::INTEGER;
            partition_date := make_date(year, month, 1);

            IF partition_date < retention_date THEN
                EXECUTE format('DROP TABLE IF EXISTS %I', partition_record.tablename);
                dropped_count := dropped_count + 1;
                RAISE NOTICE 'Dropped old partition: %', partition_record.tablename;
            END IF;
        END;
    END LOOP;

    RETURN dropped_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_audit_partitions IS 'Drops audit log partitions older than 12 months (run monthly)';

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    partition_count INTEGER;
BEGIN
    -- Count audit_log partitions
    SELECT COUNT(*) INTO partition_count
    FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename LIKE 'audit_log_2026%';

    IF partition_count < 4 THEN
        RAISE EXCEPTION 'Expected at least 4 partitions, found %', partition_count;
    END IF;

    RAISE NOTICE 'Migration 020: ✅ Audit log table created with % partitions', partition_count;
    RAISE NOTICE '  - Retention: 12 months';
    RAISE NOTICE '  - Auto-partition: Next 3 months created';
END $$;
