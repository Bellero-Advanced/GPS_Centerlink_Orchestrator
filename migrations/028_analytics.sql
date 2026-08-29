-- Migration 028: Analytics and Driver Scoring
-- Phase 9: Advanced Analytics
-- Date: 2026-08-25

-- ========================================
-- ANALYTICS AGGREGATION TABLES
-- ========================================

-- Daily vehicle summary (pre-aggregated for fast queries)
CREATE TABLE IF NOT EXISTS analytics_daily_vehicle (
    date DATE NOT NULL,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES tc_devices(id) ON DELETE CASCADE,
    total_distance_km NUMERIC(10, 2),
    total_trip_time_minutes INTEGER,
    total_idle_time_minutes INTEGER,
    max_speed_kmh NUMERIC(6, 2),
    avg_speed_kmh NUMERIC(6, 2),
    harsh_braking_count INTEGER DEFAULT 0,
    harsh_acceleration_count INTEGER DEFAULT 0,
    speeding_violations_count INTEGER DEFAULT 0,
    geofence_violations_count INTEGER DEFAULT 0,
    driver_score INTEGER, -- 0-100
    created_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (date, device_id)
);

CREATE INDEX idx_analytics_daily_vehicle_tenant_date ON analytics_daily_vehicle(tenant_id, date DESC);
CREATE INDEX idx_analytics_daily_vehicle_device ON analytics_daily_vehicle(device_id, date DESC);
CREATE INDEX idx_analytics_daily_vehicle_score ON analytics_daily_vehicle(driver_score) WHERE driver_score IS NOT NULL;

COMMENT ON TABLE analytics_daily_vehicle IS 'Daily aggregated vehicle analytics';
COMMENT ON COLUMN analytics_daily_vehicle.driver_score IS 'Driver behavior score (0-100, higher is better)';

-- Monthly tenant summary
CREATE TABLE IF NOT EXISTS analytics_monthly_tenant (
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    total_devices INTEGER,
    active_devices INTEGER,
    total_distance_km NUMERIC(12, 2),
    total_trip_hours NUMERIC(10, 2),
    avg_driver_score NUMERIC(5, 2),
    total_violations INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (year, month, tenant_id)
);

CREATE INDEX idx_analytics_monthly_tenant ON analytics_monthly_tenant(tenant_id, year DESC, month DESC);

-- ========================================
-- DRIVER BEHAVIOR SCORING
-- ========================================

-- Function: Calculate driver score based on behavior metrics
CREATE OR REPLACE FUNCTION calculate_driver_score(
    p_harsh_braking INTEGER,
    p_harsh_acceleration INTEGER,
    p_speeding_violations INTEGER,
    p_geofence_violations INTEGER,
    p_total_distance_km NUMERIC
) RETURNS INTEGER AS $$
DECLARE
    base_score INTEGER := 100;
    penalty INTEGER := 0;
BEGIN
    -- Normalize violations by distance (per 100 km)
    IF p_total_distance_km > 0 THEN
        -- Harsh braking: -2 points per occurrence per 100km
        penalty := penalty + (p_harsh_braking * 100.0 / p_total_distance_km * 2)::INTEGER;

        -- Harsh acceleration: -2 points per occurrence per 100km
        penalty := penalty + (p_harsh_acceleration * 100.0 / p_total_distance_km * 2)::INTEGER;

        -- Speeding: -5 points per violation per 100km
        penalty := penalty + (p_speeding_violations * 100.0 / p_total_distance_km * 5)::INTEGER;

        -- Geofence violations: -3 points per violation per 100km
        penalty := penalty + (p_geofence_violations * 100.0 / p_total_distance_km * 3)::INTEGER;
    END IF;

    -- Apply penalty
    base_score := base_score - penalty;

    -- Clamp to 0-100
    IF base_score < 0 THEN
        base_score := 0;
    END IF;

    RETURN base_score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ========================================
-- ANALYTICS AGGREGATION FUNCTION
-- ========================================

-- Function: Aggregate daily analytics for a specific date
CREATE OR REPLACE FUNCTION aggregate_daily_analytics(p_date DATE)
RETURNS INTEGER AS $$
DECLARE
    records_inserted INTEGER := 0;
BEGIN
    INSERT INTO analytics_daily_vehicle (
        date,
        tenant_id,
        device_id,
        total_distance_km,
        total_trip_time_minutes,
        total_idle_time_minutes,
        max_speed_kmh,
        avg_speed_kmh,
        harsh_braking_count,
        harsh_acceleration_count,
        speeding_violations_count,
        geofence_violations_count,
        driver_score
    )
    SELECT
        p_date,
        d.tenant_id,
        p.deviceid,
        -- Distance calculation (using positions)
        SUM(
            CASE
                WHEN LAG(p.latitude) OVER w IS NOT NULL THEN
                    ST_Distance(
                        ST_MakePoint(LAG(p.longitude) OVER w, LAG(p.latitude) OVER w)::geography,
                        ST_MakePoint(p.longitude, p.latitude)::geography
                    ) / 1000.0
                ELSE 0
            END
        ) AS total_distance_km,
        -- Trip time (speed > 0)
        (COUNT(*) FILTER (WHERE p.speed > 0) * 10 / 60)::INTEGER AS total_trip_time_minutes,
        -- Idle time (speed = 0, ignition on)
        (COUNT(*) FILTER (WHERE p.speed = 0 AND p.attributes->>'ignition' = 'true') * 10 / 60)::INTEGER AS idle_time_minutes,
        -- Speed stats
        MAX(p.speed * 1.852)::NUMERIC(6,2) AS max_speed_kmh,
        AVG(p.speed * 1.852)::NUMERIC(6,2) AS avg_speed_kmh,
        -- Behavior metrics (placeholder - need actual event detection)
        0 AS harsh_braking_count,
        0 AS harsh_acceleration_count,
        COUNT(e.id) FILTER (WHERE e.type = 'deviceOverspeed') AS speeding_violations,
        COUNT(e.id) FILTER (WHERE e.type IN ('geofenceEnter', 'geofenceExit')) AS geofence_violations,
        -- Calculate driver score
        calculate_driver_score(
            0, -- harsh_braking
            0, -- harsh_acceleration
            COUNT(e.id) FILTER (WHERE e.type = 'deviceOverspeed')::INTEGER,
            COUNT(e.id) FILTER (WHERE e.type IN ('geofenceEnter', 'geofenceExit'))::INTEGER,
            SUM(
                CASE
                    WHEN LAG(p.latitude) OVER w IS NOT NULL THEN
                        ST_Distance(
                            ST_MakePoint(LAG(p.longitude) OVER w, LAG(p.latitude) OVER w)::geography,
                            ST_MakePoint(p.longitude, p.latitude)::geography
                        ) / 1000.0
                    ELSE 0
                END
            )
        ) AS driver_score
    FROM tc_positions p
    JOIN tc_devices d ON p.deviceid = d.id
    LEFT JOIN tc_events e ON e.deviceid = p.deviceid
        AND DATE(e.eventtime) = p_date
    WHERE DATE(p.fixtime) = p_date
      AND p.valid = true
      AND d.tenant_id IS NOT NULL
    GROUP BY d.tenant_id, p.deviceid
    WINDOW w AS (PARTITION BY p.deviceid ORDER BY p.fixtime)
    ON CONFLICT (date, device_id)
    DO UPDATE SET
        total_distance_km = EXCLUDED.total_distance_km,
        total_trip_time_minutes = EXCLUDED.total_trip_time_minutes,
        total_idle_time_minutes = EXCLUDED.total_idle_time_minutes,
        max_speed_kmh = EXCLUDED.max_speed_kmh,
        avg_speed_kmh = EXCLUDED.avg_speed_kmh,
        speeding_violations_count = EXCLUDED.speeding_violations_count,
        geofence_violations_count = EXCLUDED.geofence_violations_count,
        driver_score = EXCLUDED.driver_score;

    GET DIAGNOSTICS records_inserted = ROW_COUNT;
    RETURN records_inserted;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- VIEWS FOR ANALYTICS DASHBOARD
-- ========================================

-- View: Top performing vehicles (by driver score)
CREATE OR REPLACE VIEW v_analytics_top_drivers AS
SELECT
    a.device_id,
    d.name AS device_name,
    a.tenant_id,
    AVG(a.driver_score)::NUMERIC(5,2) AS avg_driver_score,
    SUM(a.total_distance_km)::NUMERIC(10,2) AS total_distance_km,
    SUM(a.speeding_violations_count) AS total_violations,
    COUNT(*) AS days_tracked
FROM analytics_daily_vehicle a
JOIN tc_devices d ON a.device_id = d.id
WHERE a.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY a.device_id, d.name, a.tenant_id
HAVING AVG(a.driver_score) IS NOT NULL
ORDER BY avg_driver_score DESC;

-- View: Tenant analytics summary
CREATE OR REPLACE VIEW v_analytics_tenant_summary AS
SELECT
    t.id AS tenant_id,
    t.name AS tenant_name,
    COUNT(DISTINCT a.device_id) AS active_vehicles,
    SUM(a.total_distance_km)::NUMERIC(12,2) AS total_distance_km,
    AVG(a.driver_score)::NUMERIC(5,2) AS avg_driver_score,
    SUM(a.speeding_violations_count + a.geofence_violations_count) AS total_violations
FROM tenants t
LEFT JOIN analytics_daily_vehicle a ON t.id = a.tenant_id
    AND a.date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY t.id, t.name;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename IN ('analytics_daily_vehicle', 'analytics_monthly_tenant')
    ) THEN
        RAISE NOTICE 'Migration 028: ✅ Analytics tables created';

        -- Aggregate today's data (initial run)
        PERFORM aggregate_daily_analytics(CURRENT_DATE - INTERVAL '1 day');
        RAISE NOTICE 'Migration 028: ✅ Initial analytics aggregation complete';
    ELSE
        RAISE EXCEPTION 'Analytics tables creation failed';
    END IF;
END $$;

-- ========================================
-- CRON SETUP (Manual)
-- ========================================
-- Run daily at 1 AM to aggregate previous day:
-- 0 1 * * * psql -U traccar -d traccar -c "SELECT aggregate_daily_analytics(CURRENT_DATE - INTERVAL '1 day')"
