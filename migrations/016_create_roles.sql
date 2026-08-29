-- Migration 016: Create Roles Table
-- RBAC Phase 2: Role-Based Access Control
-- Date: 2026-08-25

-- ========================================
-- ROLES TABLE
-- ========================================
-- Stores system and custom roles for RBAC
-- System roles (is_system=true) cannot be deleted
-- Tenant admins can create custom roles for their organization

CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false,
    tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT roles_name_tenant_unique UNIQUE (name, tenant_id),
    CONSTRAINT roles_system_no_tenant CHECK (
        (is_system = true AND tenant_id IS NULL) OR
        (is_system = false AND tenant_id IS NOT NULL) OR
        (is_system = false AND tenant_id IS NULL)
    )
);

-- Indexes
CREATE INDEX idx_roles_tenant ON roles(tenant_id) WHERE tenant_id IS NOT NULL;
CREATE INDEX idx_roles_system ON roles(is_system) WHERE is_system = true;

-- Comments
COMMENT ON TABLE roles IS 'User roles for RBAC system';
COMMENT ON COLUMN roles.is_system IS 'System roles cannot be deleted or modified';
COMMENT ON COLUMN roles.tenant_id IS 'NULL for system roles, set for custom tenant roles';

-- ========================================
-- SEED SYSTEM ROLES
-- ========================================
-- 7 predefined system roles

INSERT INTO roles (id, name, description, is_system, tenant_id) VALUES
    (1, 'super_admin', 'Platform owner (Bellerox team) - god mode, can do everything', true, NULL),
    (2, 'tenant_admin', 'Company owner - manage users, devices, billing within tenant', true, NULL),
    (3, 'fleet_manager', 'Operations manager - view all vehicles, create geofences, run reports', true, NULL),
    (4, 'supervisor', 'Field manager - limited to assigned groups only', true, NULL),
    (5, 'driver', 'End user (mobile app) - view own vehicle only', true, NULL),
    (6, 'api_client', 'Read-only API access for integrations', true, NULL),
    (7, 'auditor', 'Compliance/security - read-only access to everything including audit logs', true, NULL)
ON CONFLICT (id) DO NOTHING;

-- Reset sequence to avoid conflicts with system roles
SELECT setval('roles_id_seq', 100, false);

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    role_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO role_count FROM roles WHERE is_system = true;
    IF role_count != 7 THEN
        RAISE EXCEPTION 'Expected 7 system roles, found %', role_count;
    END IF;
    RAISE NOTICE 'Migration 016: ✅ 7 system roles created';
END $$;
