# Settings System — Implementation Roadmap
# แผนการพัฒนาระบบตั้งค่า v2.0.0

## 📊 Summary

**Total Features:** 23 sub-menus across 7 main categories
**Estimated Development Time:** 4-6 weeks (1 developer)
**Priority:** HIGH → MEDIUM → LOW

---

## ✅ Implementation Priority

### Phase 1: User Management & Core Settings (Week 1-2) — HIGH

**1.1 ข้อมูลผู้ใช้ (User Profile)**
- [ ] View Profile Page
- [ ] Edit Profile Form
- [ ] Change Password Form
- [ ] Avatar Upload

**1.2 ตั้งค่า (Settings)**
- [ ] Email Report Config (CRUD)
- [ ] Alert Notification Config (CRUD)
- [ ] LINE Notify Integration

**7.1 จัดการ User (Admin)**
- [ ] User CRUD
- [ ] Role & Permission System
- [ ] Password Reset Flow
- [ ] User Invitation Email

**Deliverables:**
- `/app/account` — View/Edit Profile
- `/app/account/change-password`
- `/app/settings/email-reports`
- `/app/settings/notifications`
- `/app/admin/users` (admin only)

**API Endpoints:**
```
GET    /api/users/me
PATCH  /api/users/{id}
POST   /api/users/{id}/change-password
POST   /api/users/{id}/upload-avatar

GET    /api/settings/email-reports
POST   /api/settings/email-reports
PUT    /api/settings/email-reports/{id}
DELETE /api/settings/email-reports/{id}

GET    /api/settings/alert-configs
POST   /api/settings/alert-configs
PUT    /api/settings/alert-configs/{id}
DELETE /api/settings/alert-configs/{id}

GET    /api/admin/users (admin only)
POST   /api/admin/users (admin only)
PUT    /api/admin/users/{id} (admin only)
DELETE /api/admin/users/{id} (admin only)
POST   /api/admin/users/{id}/reset-password (admin only)
```

---

### Phase 2: Asset Management (Week 3-4) — HIGH

**3.1 จัดการทรัพย์สิน (Vehicle)**
- [ ] Vehicle CRUD (enhance existing FleetPage)
- [ ] Multi-tab Form (Basic Info / GPS Device / Documents / Maintenance)
- [ ] Vehicle Import CSV
- [ ] Vehicle Export CSV

**3.2 จัดการกลุ่มสินทรัพย์ (Vehicle Groups)**
- [ ] Group CRUD
- [ ] Tree View UI
- [ ] Drag-and-drop reorder

**3.3 จัดการกลุ่มสินทรัพย์ย่อย (Sub-groups)**
- [ ] Sub-group CRUD (nested under groups)

**3.4 จัดการกลุ่มความเร็ว (Speed Groups)**
- [ ] Speed Group CRUD
- [ ] Assign to vehicles
- [ ] Speed violation alerts per group

**3.5 จัดการบำรุงรักษา (Maintenance)**
- [ ] Maintenance Record CRUD
- [ ] Maintenance Schedule (due alerts)
- [ ] Maintenance Cost Reports
- [ ] Upload receipts/photos

**Deliverables:**
- `/app/fleet` (enhanced with full CRUD)
- `/app/settings/groups`
- `/app/settings/speed-groups`
- `/app/maintenance`

**API Endpoints:**
```
# Already exists in Traccar:
GET    /api/devices
POST   /api/devices
PUT    /api/devices/{id}
DELETE /api/devices/{id}

# New endpoints (custom):
GET    /api/groups (enhance existing)
POST   /api/groups
PUT    /api/groups/{id}
DELETE /api/groups/{id}

GET    /api/speed-groups
POST   /api/speed-groups
PUT    /api/speed-groups/{id}
DELETE /api/speed-groups/{id}

GET    /api/maintenance-records
POST   /api/maintenance-records
PUT    /api/maintenance-records/{id}
DELETE /api/maintenance-records/{id}
```

---

### Phase 3: Driver & Trailer Management (Week 5) — MEDIUM

**5.1 จัดการคนขับรถ (Driver)**
- [ ] Driver CRUD
- [ ] Multi-tab Form (Basic / License / Employment)
- [ ] Driver Safety Score (link to DriverScorePage)
- [ ] Driver Assignment to Vehicle
- [ ] Driver Import CSV

**4.1 จัดการหางลาก (Trailer)**
- [ ] Trailer CRUD
- [ ] Trailer Groups
- [ ] Trailer-Vehicle Assignment
- [ ] RFID Integration (detect trailer attachment)

**6.1 จัดการบัตร RFID**
- [ ] RFID Card CRUD
- [ ] RFID Scanner Integration
- [ ] Assign RFID to Driver/Trailer
- [ ] RFID Usage Log

**Deliverables:**
- `/app/drivers` (enhanced)
- `/app/settings/trailers`
- `/app/settings/trailer-groups`
- `/app/settings/rfid-cards`

**Data Storage:**
- **Drivers:** Custom table `drivers` (not in Traccar core)
- **Trailers:** Custom table `trailers`
- **RFID:** Custom table `rfid_cards`

**API Endpoints:**
```
GET    /api/drivers
POST   /api/drivers
PUT    /api/drivers/{id}
DELETE /api/drivers/{id}

GET    /api/trailers
POST   /api/trailers
PUT    /api/trailers/{id}
DELETE /api/trailers/{id}

GET    /api/trailer-groups
POST   /api/trailer-groups
PUT    /api/trailer-groups/{id}
DELETE /api/trailer-groups/{id}

GET    /api/rfid-cards
POST   /api/rfid-cards
PUT    /api/rfid-cards/{id}
DELETE /api/rfid-cards/{id}
```

---

## 🗄️ Database Schema (Custom Tables)

```sql
-- ─── Drivers ──────────────────────────────────────────────────
CREATE TABLE drivers (
  id SERIAL PRIMARY KEY,
  employee_id VARCHAR(50),
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(100),
  id_card VARCHAR(13),
  
  license_number VARCHAR(50),
  license_type VARCHAR(50),
  license_expiry DATE,
  
  address TEXT,
  province VARCHAR(100),
  
  hire_date DATE,
  department VARCHAR(100),
  shift VARCHAR(20),
  
  rfid_card VARCHAR(50),
  assigned_vehicle_id INT REFERENCES tc_devices(id) ON DELETE SET NULL,
  
  status VARCHAR(20) DEFAULT 'active',
  photo_url TEXT,
  notes TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ─── Trailers ─────────────────────────────────────────────────
CREATE TABLE trailers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  license_plate VARCHAR(50),
  type VARCHAR(50),
  brand VARCHAR(50),
  model VARCHAR(50),
  year INT,
  capacity DECIMAL(10,2),
  length DECIMAL(10,2),
  width DECIMAL(10,2),
  height DECIMAL(10,2),
  
  group_id INT REFERENCES trailer_groups(id) ON DELETE SET NULL,
  sub_group_id INT REFERENCES trailer_groups(id) ON DELETE SET NULL,
  
  current_vehicle_id INT REFERENCES tc_devices(id) ON DELETE SET NULL,
  rfid_tag VARCHAR(50),
  
  insurance_expiry DATE,
  registration_expiry DATE,
  
  status VARCHAR(20) DEFAULT 'available',
  notes TEXT,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ─── Trailer Groups ───────────────────────────────────────────
CREATE TABLE trailer_groups (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT REFERENCES trailer_groups(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── Speed Groups ─────────────────────────────────────────────
CREATE TABLE speed_groups (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  max_speed INT NOT NULL,
  description TEXT,
  color VARCHAR(7),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── RFID Cards ───────────────────────────────────────────────
CREATE TABLE rfid_cards (
  id SERIAL PRIMARY KEY,
  card_number VARCHAR(50) NOT NULL UNIQUE,
  card_type VARCHAR(20) NOT NULL,
  assigned_to_type VARCHAR(20),  -- 'driver', 'vehicle', 'trailer'
  assigned_to_id INT,
  issue_date DATE NOT NULL,
  expiry_date DATE,
  status VARCHAR(20) DEFAULT 'active',
  last_used TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── Maintenance Records ──────────────────────────────────────
CREATE TABLE maintenance_records (
  id SERIAL PRIMARY KEY,
  vehicle_id INT NOT NULL REFERENCES tc_devices(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  odometer INT,
  description TEXT NOT NULL,
  cost DECIMAL(10,2),
  garage VARCHAR(200),
  technician VARCHAR(100),
  next_due_odometer INT,
  next_due_date DATE,
  attachments JSONB,  -- array of URLs
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ─── Email Report Configs ─────────────────────────────────────
CREATE TABLE email_report_configs (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES tc_users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT true,
  report_type VARCHAR(50) NOT NULL,
  frequency VARCHAR(20) NOT NULL,
  send_time TIME NOT NULL,
  day_of_week INT,
  day_of_month INT,
  recipients JSONB NOT NULL,  -- array of emails
  device_ids JSONB,
  group_ids JSONB,
  format VARCHAR(10) DEFAULT 'pdf',
  language VARCHAR(5) DEFAULT 'th',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ─── Alert Configs ────────────────────────────────────────────
CREATE TABLE alert_configs (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES tc_users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT true,
  alert_type VARCHAR(50) NOT NULL,
  threshold INT,
  device_ids JSONB,
  group_ids JSONB,
  geofence_ids JSONB,
  
  notify_email BOOLEAN DEFAULT false,
  email_recipients JSONB,
  
  notify_line BOOLEAN DEFAULT false,
  line_token VARCHAR(200),
  
  notify_sms BOOLEAN DEFAULT false,
  sms_recipients JSONB,
  
  cooldown INT DEFAULT 300,
  schedule JSONB,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🎨 UI Components to Build

### 1. Shared Components (in `/src/components/settings/`)
- `SettingsLayout.tsx` — sidebar + content area
- `SettingsPageHeader.tsx` — consistent header with breadcrumb
- `FormModal.tsx` — reusable modal for CRUD forms
- `DataTable.tsx` — sortable, filterable, paginated table
- `ConfirmDeleteModal.tsx` — delete confirmation
- `ImageUpload.tsx` — drag-and-drop image uploader
- `SearchSelect.tsx` — searchable dropdown (for vehicle/driver/group selection)
- `TreeView.tsx` — collapsible tree for groups
- `DateRangePicker.tsx` — date range selector (already exists)
- `CopyButton.tsx` — copy to clipboard (already exists)

### 2. Page-Specific Components
- `ProfileCard.tsx` — user profile display
- `PasswordStrengthMeter.tsx` — visual password strength
- `EmailReportCard.tsx` — scheduled report item
- `AlertConfigCard.tsx` — alert rule item
- `VehicleFormTabs.tsx` — multi-tab vehicle form
- `DriverFormTabs.tsx` — multi-tab driver form
- `MaintenanceRecordCard.tsx` — maintenance history item
- `RFIDScanner.tsx` — RFID card reader integration
- `PermissionMatrix.tsx` — role permission editor (admin)

---

## 🚀 Development Workflow

### Step 1: Create Database Migrations
```bash
# Create migration files (example using Prisma or raw SQL)
npx prisma migrate dev --name add-settings-tables
```

### Step 2: Build Backend API
```bash
# Add new endpoints in Express.js/Node.js backend
# OR extend Traccar API with custom endpoints
```

### Step 3: Build Frontend Pages
```bash
# 1. Create page skeleton
touch src/pages/settings/AccountSettingsPage.tsx

# 2. Add route in App.tsx
<Route path="/app/settings/account" element={<AccountSettingsPage />} />

# 3. Add nav item in LayoutV2.tsx
{ to: '/app/settings/account', icon: UserCog, label: 'บัญชีของฉัน' }

# 4. Build CRUD components
touch src/components/settings/ProfileForm.tsx

# 5. Create hooks
touch src/hooks/useProfile.ts

# 6. Create service functions
# Add to src/services/settingsService.ts
```

### Step 4: Testing Checklist
- [ ] All CRUD operations work (Create, Read, Update, Delete)
- [ ] Form validation works
- [ ] Loading states show correctly
- [ ] Error states show toast + retry
- [ ] Empty states show EmptyState component
- [ ] Mobile responsive (375px width)
- [ ] Dark mode doesn't break layout
- [ ] Thai text displays correctly

### Step 5: Deploy
```bash
npm run build
git add -A
git commit -m "feat: Complete Settings System (Phase X)"
git push origin main
```

---

## 📝 Notes

1. **Data Isolation:** Each user sees only their assigned vehicles/groups based on `allowedDeviceIds` or `allowedGroupIds` in `tc_users` table.

2. **LINE Notify Integration:** Store LINE token per user, not globally. Use LINE Notify API to send alerts: `POST https://notify-api.line.me/api/notify`

3. **Email Reports:** Use cron job or scheduled task (e.g., node-cron) to generate and email reports at specified times.

4. **RFID Integration:** Depends on GPS device model. Some devices (e.g., Teltonika FMB) support iButton/RFID input via `attributes.driverUniqueId`.

5. **Maintenance Due Alerts:** Check daily via cron: `nextDueDate <= NOW() + 7 days` → send alert.

6. **Password Security:** Use bcrypt for hashing, min 8 chars, enforce complexity in production.

7. **File Uploads:** Use Cloudflare R2 or AWS S3 for avatar/receipt storage, not local filesystem.

8. **Soft Delete:** Set `status = 'deleted'` instead of hard DELETE, keep audit trail.

