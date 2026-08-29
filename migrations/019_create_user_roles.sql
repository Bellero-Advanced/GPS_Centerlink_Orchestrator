-- Migration 019: Create User-Roles Mapping
-- RBAC Phase 2: Assign roles to users with scoping
-- Date: 2026-08-25

-- ========================================
-- USER_ROLES TABLE
-- ========================================
-- Many-to-many relationship between users and roles
-- Includes scope for group-based access control (for Supervisor role)

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL REFERENCES tc_users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    scope JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by INTEGER REFERENCES tc_users(id),

    PRIMARY KEY (user_id, role_id, tenant_id)
);

-- Indexes
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
CREATE INDEX idx_user_roles_tenant ON user_roles(tenant_id);
CREATE INDEX idx_user_roles_scope ON user_roles USING GIN(scope) WHERE scope IS NOT NULL;

-- Comments
COMMENT ON TABLE user_roles IS 'Maps users to roles within tenants';
COMMENT ON COLUMN user_roles.scope IS 'Group-based access control: {"groupIds": [1,2,3]} for Supervisor';
COMMENT ON COLUMN user_roles.created_by IS 'User ID who assigned this role';

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Function: Assign role to user
CREATE OR REPLACE FUNCTION assign_role_to_user(
    p_user_id INTEGER,
    p_role_id INTEGER,
    p_tenant_id INTEGER,
    p_scope JSONB DEFAULT NULL,
    p_created_by INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
    -- Verify user exists and belongs to tenant
    IF NOT EXISTS (
        SELECT 1 FROM tc_users
        WHERE id = p_user_id AND tenant_id = p_tenant_id
    ) THEN
        RAISE EXCEPTION 'User % does not exist or does not belong to tenant %', p_user_id, p_tenant_id;
    END IF;

    -- Verify role exists
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_role_id) THEN
        RAISE EXCEPTION 'Role % does not exist', p_role_id;
    END IF;

    -- Insert or update
    INSERT INTO user_roles (user_id, role_id, tenant_id, scope, created_by)
    VALUES (p_user_id, p_role_id, p_tenant_id, p_scope, p_created_by)
    ON CONFLICT (user_id, role_id, tenant_id)
    DO UPDATE SET scope = EXCLUDED.scope;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Remove role from user
CREATE OR REPLACE FUNCTION remove_role_from_user(
    p_user_id INTEGER,
    p_role_id INTEGER,
    p_tenant_id INTEGER
) RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM user_roles
    WHERE user_id = p_user_id
      AND role_id = p_role_id
      AND tenant_id = p_tenant_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function: Get user permissions (optimized for JWT caching)
CREATE OR REPLACE FUNCTION get_user_permissions(
    p_user_id INTEGER,
    p_tenant_id INTEGER
) RETURNS TABLE(
    permission_name VARCHAR(100),
    scope JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT p.name, ur.scope
    FROM user_roles ur
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = p_user_id
      AND ur.tenant_id = p_tenant_id;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function: Check if user has permission
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id INTEGER,
    p_tenant_id INTEGER,
    p_permission VARCHAR(100)
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON ur.role_id = rp.role_id
        JOIN permissions p ON rp.permission_id = p.id
        WHERE ur.user_id = p_user_id
          AND ur.tenant_id = p_tenant_id
          AND p.name = p_permission
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- ========================================
-- VIEW: User Roles Summary
-- ========================================
CREATE OR REPLACE VIEW v_user_roles_summary AS
SELECT
    u.id AS user_id,
    u.name AS user_name,
    u.email,
    u.tenant_id,
    t.name AS tenant_name,
    r.id AS role_id,
    r.name AS role_name,
    r.description AS role_description,
    ur.scope,
    ur.created_at AS role_assigned_at,
    COUNT(DISTINCT rp.permission_id) AS permission_count
FROM tc_users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN roles r ON ur.role_id = r.id
LEFT JOIN tenants t ON ur.tenant_id = t.id
LEFT JOIN role_permissions rp ON r.id = rp.role_id
GROUP BY u.id, u.name, u.email, u.tenant_id, t.name, r.id, r.name, r.description, ur.scope, ur.created_at;

COMMENT ON VIEW v_user_roles_summary IS 'Quick view of user roles with permission counts';

-- ========================================
-- SEED: Assign roles to existing users
-- ========================================
-- Assign tenant_admin role to all existing admin users

DO $$
DECLARE
    admin_user RECORD;
    role_tenant_admin INTEGER;
BEGIN
    -- Get tenant_admin role ID
    SELECT id INTO role_tenant_admin FROM roles WHERE name = 'tenant_admin';

    -- Assign to all existing administrators
    FOR admin_user IN
        SELECT id, tenant_id FROM tc_users WHERE administrator = true AND tenant_id IS NOT NULL
    LOOP
        INSERT INTO user_roles (user_id, role_id, tenant_id)
        VALUES (admin_user.id, role_tenant_admin, admin_user.tenant_id)
        ON CONFLICT DO NOTHING;
    END LOOP;

    RAISE NOTICE 'Migration 019: ✅ Assigned tenant_admin role to existing admin users';
END $$;

-- ========================================
-- VERIFICATION
-- ========================================
DO $$
DECLARE
    assigned_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO assigned_count FROM user_roles;

    IF assigned_count = 0 THEN
        RAISE WARNING 'No roles assigned yet (this is OK if no users exist)';
    ELSE
        RAISE NOTICE 'Migration 019: ✅ % role assignments created', assigned_count;
    END IF;
END $$;
