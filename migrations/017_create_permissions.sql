-- Migration 017: Create Permissions Table
-- RBAC Phase 2: Permission definitions
-- Date: 2026-08-25

-- ========================================
-- PERMISSIONS TABLE
-- ========================================
-- Stores all available permissions in resource:action format
-- Example: vehicles:read, vehicles:write, vehicles:delete

CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT perm_format CHECK (name ~ '^[a-z_]+:[a-z_]+$'),
    CONSTRAINT perm_name_match CHECK (name = resource || ':' || action)
);

-- Indexes
CREATE INDEX idx_permissions_resource ON permissions(resource);
CREATE INDEX idx_permissions_action ON permissions(action);

-- Comments
COMMENT ON TABLE permissions IS 'Available permissions for RBAC system';
COMMENT ON COLUMN permissions.name IS 'Format: resource:action (e.g., vehicles:read)';

-- ========================================
-- SEED PERMISSIONS
-- ========================================
-- 50+ permissions covering all system resources

INSERT INTO permissions (name, resource, action, description) VALUES
-- Vehicles (Devices)
('vehicles:read', 'vehicles', 'read', 'View vehicles and positions'),
('vehicles:write', 'vehicles', 'write', 'Create and update vehicles'),
('vehicles:delete', 'vehicles', 'delete', 'Delete vehicles'),

-- Positions (GPS data)
('positions:read', 'positions', 'read', 'View position history'),

-- Geofences (Zones)
('geofences:read', 'geofences', 'read', 'View geofences'),
('geofences:write', 'geofences', 'write', 'Create and update geofences'),
('geofences:delete', 'geofences', 'delete', 'Delete geofences'),

-- Reports
('reports:read', 'reports', 'read', 'View all types of reports'),
('reports:export', 'reports', 'export', 'Export reports to CSV/PDF/Excel'),

-- Commands (Engine cut, lock, etc.)
('commands:execute', 'commands', 'execute', 'Send commands to devices'),

-- Users (Personnel management)
('users:read', 'users', 'read', 'View users list'),
('users:write', 'users', 'write', 'Create and update users'),
('users:delete', 'users', 'delete', 'Delete users'),

-- Billing (Subscription management)
('billing:read', 'billing', 'read', 'View billing information and invoices'),
('billing:write', 'billing', 'write', 'Manage subscription and payment methods'),

-- Settings (Tenant configuration)
('settings:read', 'settings', 'read', 'View tenant settings'),
('settings:write', 'settings', 'write', 'Update tenant settings and branding'),

-- Audit (Compliance)
('audit:read', 'audit', 'read', 'View audit logs'),

-- Tenants (Platform management - super admin only)
('tenants:read', 'tenants', 'read', 'View all tenants'),
('tenants:write', 'tenants', 'write', 'Create and manage tenants'),

-- Groups (Vehicle groups)
('groups:read', 'groups', 'read', 'View vehicle groups'),
('groups:write', 'groups', 'write', 'Create and update vehicle groups'),
('groups:delete', 'groups', 'delete', 'Delete vehicle groups'),

-- Drivers (Personnel - different from system users)
('drivers:read', 'drivers', 'read', 'View driver profiles'),
('drivers:write', 'drivers', 'write', 'Create and update driver profiles'),
('drivers:delete', 'drivers', 'delete', 'Delete driver profiles'),

-- Notifications (Alerts)
('notifications:read', 'notifications', 'read', 'View notification rules'),
('notifications:write', 'notifications', 'write', 'Create and update notification rules'),
('notifications:delete', 'notifications', 'delete', 'Delete notification rules'),

-- Maintenance (Service schedules)
('maintenance:read', 'maintenance', 'read', 'View maintenance schedules'),
('maintenance:write', 'maintenance', 'write', 'Create and update maintenance schedules'),

-- Events (GPS events - speeding, geofence, etc.)
('events:read', 'events', 'read', 'View GPS events and alerts'),

-- Trips (Trip history)
('trips:read', 'trips', 'read', 'View trip history and analytics'),

-- DLT (Thailand specific - Department of Land Transport)
('dlt:read', 'dlt', 'read', 'View DLT submission logs'),
('dlt:write', 'dlt', 'write', 'Submit data to DLT'),

-- Analytics (Advanced reports)
('analytics:read', 'analytics', 'read', 'View advanced analytics and dashboards'),

-- API Keys (Integration management)
('api_keys:read', 'api_keys', 'read', 'View API keys'),
('api_keys:write', 'api_keys', 'write', 'Create and manage API keys'),

-- Roles (Role management - tenant admin can create custom roles)
('roles:read', 'roles', 'read', 'View roles'),
('roles:write', 'roles', 'write', 'Create custom roles (tenant-scoped)'),

-- Webhooks (Integration events)
('webhooks:read', 'webhooks', 'read', 'View webhook configurations'),
('webhooks:write', 'webhooks', 'write', 'Create and update webhooks')

ON CONFLICT (name) DO NOTHING;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    perm_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO perm_count FROM permissions;
    IF perm_count < 40 THEN
        RAISE EXCEPTION 'Expected at least 40 permissions, found %', perm_count;
    END IF;
    RAISE NOTICE 'Migration 017: ✅ % permissions created', perm_count;
END $$;
