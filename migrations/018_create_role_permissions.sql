-- Migration 018: Create Role-Permissions Mapping
-- RBAC Phase 2: Map permissions to roles
-- Date: 2026-08-25

-- ========================================
-- ROLE_PERMISSIONS TABLE
-- ========================================
-- Many-to-many relationship between roles and permissions

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    PRIMARY KEY (role_id, permission_id)
);

-- Indexes
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions(permission_id);

-- Comments
COMMENT ON TABLE role_permissions IS 'Maps permissions to roles (many-to-many)';

-- ========================================
-- MAP SYSTEM ROLES TO PERMISSIONS
-- ========================================

-- 1. SUPER ADMIN: ALL permissions (god mode)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions
ON CONFLICT DO NOTHING;

-- 2. TENANT ADMIN: Everything except tenants:write
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions WHERE name != 'tenants:write' AND name != 'tenants:read'
ON CONFLICT DO NOTHING;

-- 3. FLEET MANAGER: Read + operational permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions WHERE name IN (
    -- View everything
    'vehicles:read',
    'positions:read',
    'geofences:read',
    'geofences:write',  -- Can create zones
    'reports:read',
    'reports:export',
    'commands:execute',  -- Can send commands
    'groups:read',
    'drivers:read',
    'notifications:read',
    'events:read',
    'trips:read',
    'maintenance:read',
    'analytics:read',
    'dlt:read'
)
ON CONFLICT DO NOTHING;

-- 4. SUPERVISOR: Limited read + commands (group-scoped)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 4, id FROM permissions WHERE name IN (
    'vehicles:read',      -- Only assigned groups
    'positions:read',
    'geofences:read',
    'reports:read',       -- Group-scoped
    'reports:export',
    'commands:execute',   -- Group-scoped
    'events:read',
    'trips:read'
)
ON CONFLICT DO NOTHING;

-- 5. DRIVER: Self-only read (mobile app)
INSERT INTO role_permissions (role_id, permission_id)
SELECT 5, id FROM permissions WHERE name IN (
    'vehicles:read',      -- Own vehicle only
    'positions:read',     -- Own history only
    'trips:read'          -- Own trips only
)
ON CONFLICT DO NOTHING;

-- 6. API CLIENT: Read-only data access
INSERT INTO role_permissions (role_id, permission_id)
SELECT 6, id FROM permissions WHERE name IN (
    'vehicles:read',
    'positions:read',
    'geofences:read',
    'reports:read',
    'reports:export',
    'drivers:read',
    'events:read',
    'trips:read',
    'groups:read'
)
ON CONFLICT DO NOTHING;

-- 7. AUDITOR: Read-only everything + audit logs
INSERT INTO role_permissions (role_id, permission_id)
SELECT 7, id FROM permissions WHERE action = 'read'
ON CONFLICT DO NOTHING;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    super_admin_perms INTEGER;
    tenant_admin_perms INTEGER;
    fleet_mgr_perms INTEGER;
    supervisor_perms INTEGER;
    driver_perms INTEGER;
    api_client_perms INTEGER;
    auditor_perms INTEGER;
    total_perms INTEGER;
BEGIN
    -- Count permissions per role
    SELECT COUNT(*) INTO super_admin_perms FROM role_permissions WHERE role_id = 1;
    SELECT COUNT(*) INTO tenant_admin_perms FROM role_permissions WHERE role_id = 2;
    SELECT COUNT(*) INTO fleet_mgr_perms FROM role_permissions WHERE role_id = 3;
    SELECT COUNT(*) INTO supervisor_perms FROM role_permissions WHERE role_id = 4;
    SELECT COUNT(*) INTO driver_perms FROM role_permissions WHERE role_id = 5;
    SELECT COUNT(*) INTO api_client_perms FROM role_permissions WHERE role_id = 6;
    SELECT COUNT(*) INTO auditor_perms FROM role_permissions WHERE role_id = 7;
    SELECT COUNT(*) INTO total_perms FROM permissions;

    -- Verify super admin has ALL permissions
    IF super_admin_perms != total_perms THEN
        RAISE EXCEPTION 'Super admin should have all % permissions, has %', total_perms, super_admin_perms;
    END IF;

    -- Verify tenant admin has most permissions (all except tenants:*)
    IF tenant_admin_perms < (total_perms - 2) THEN
        RAISE EXCEPTION 'Tenant admin should have at least % permissions, has %', (total_perms - 2), tenant_admin_perms;
    END IF;

    -- Verify other roles have reasonable permissions
    IF fleet_mgr_perms < 10 THEN
        RAISE EXCEPTION 'Fleet manager should have at least 10 permissions, has %', fleet_mgr_perms;
    END IF;

    IF supervisor_perms < 5 THEN
        RAISE EXCEPTION 'Supervisor should have at least 5 permissions, has %', supervisor_perms;
    END IF;

    IF driver_perms < 3 THEN
        RAISE EXCEPTION 'Driver should have at least 3 permissions, has %', driver_perms;
    END IF;

    RAISE NOTICE 'Migration 018: ✅ Role permissions mapped';
    RAISE NOTICE '  - super_admin: % permissions', super_admin_perms;
    RAISE NOTICE '  - tenant_admin: % permissions', tenant_admin_perms;
    RAISE NOTICE '  - fleet_manager: % permissions', fleet_mgr_perms;
    RAISE NOTICE '  - supervisor: % permissions', supervisor_perms;
    RAISE NOTICE '  - driver: % permissions', driver_perms;
    RAISE NOTICE '  - api_client: % permissions', api_client_perms;
    RAISE NOTICE '  - auditor: % permissions', auditor_perms;
END $$;
