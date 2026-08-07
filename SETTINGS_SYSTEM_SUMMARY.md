# Settings System — Quick Reference
# สรุประบบตั้งค่าฉบับเต็ม v2.0.0

## 📖 เอกสารทั้งหมด (4 ไฟล์)

1. **SETTINGS_DESIGN.md** — ออกแบบรายละเอียด Part 1
   - ข้อมูลผู้ใช้ (User Profile)
   - ตั้งค่า (Settings)

2. **SETTINGS_DESIGN_PART2.md** — ออกแบบรายละเอียด Part 2
   - จัดการทรัพย์สิน (Asset Management)

3. **SETTINGS_DESIGN_PART3.md** — ออกแบบรายละเอียด Part 3
   - จัดการหางลาก (Trailer Management)
   - จัดการคนขับรถ (Driver Management)
   - จัดการบัตร RFID (RFID Management)
   - จัดการ User (User Management)

4. **SETTINGS_IMPLEMENTATION_PLAN.md** — แผนการพัฒนา
   - Phase 1-3 roadmap
   - Database schema (SQL)
   - API endpoints
   - Component list

5. **SETTINGS_UX_UI_GUIDELINES.md** — แนวทาง UX/UI
   - Design principles
   - Component styles (CSS)
   - Accessibility (A11Y)
   - Responsive design

---

## 🗂️ เมนูทั้งหมด (23 sub-menus)

### 1. ข้อมูลผู้ใช้ (3 menus)
- ข้อมูลผู้ใช้ — View Profile
- แก้ไขข้อมูลผู้ใช้ — Edit Profile
- เปลี่ยนรหัสผ่าน — Change Password

### 2. ตั้งค่า (2 menus)
- ตั้งค่ารายงานผ่านอีเมล — Email Report Config
- ตั้งค่าการแจ้งเตือน Notify — Alert Config

### 3. จัดการทรัพย์สิน (5 menus)
- จัดการทรัพย์สิน — Vehicle CRUD
- จัดการกลุ่มสินทรัพย์ — Vehicle Groups
- จัดการกลุ่มสินทรัพย์ย่อย — Sub-groups
- จัดการกลุ่มความเร็วสินทรัพย์ — Speed Groups
- จัดการบำรุงรักษา — Maintenance Records

### 4. จัดการหางลาก (3 menus)
- จัดการหางลาก — Trailer CRUD
- จัดการกลุ่มหางลาก — Trailer Groups
- จัดการกลุ่มหางลากย่อย — Trailer Sub-groups

### 5. จัดการคนขับรถ (1 menu)
- จัดการคนขับรถ — Driver CRUD

### 6. จัดการบัตร RFID (1 menu)
- จัดการบัตร RFID — RFID Card CRUD

### 7. จัดการ User (1 menu)
- จัดการ User — System User CRUD (admin only)

**Total:** 16 main features across 7 categories

---

## 🗄️ ฐานข้อมูล (8 ตารางใหม่)

1. `drivers` — พนักงานขับรถ
2. `trailers` — หางลาก
3. `trailer_groups` — กลุ่มหางลาก
4. `speed_groups` — กลุ่มความเร็ว
5. `rfid_cards` — บัตร RFID
6. `maintenance_records` — บันทึกการซ่อมบำรุง
7. `email_report_configs` — ตั้งค่ารายงานอีเมล
8. `alert_configs` — ตั้งค่าการแจ้งเตือน

**Note:** Traccar tables (`tc_users`, `tc_devices`, `tc_groups`) ใช้ต่อจากเดิม

---

## 🚀 ลำดับการพัฒนา

### Phase 1 (Week 1-2) — User & Core Settings
✅ Priority: HIGH
- User Profile (view, edit, change password)
- Email Report Config
- Alert Notification Config
- System User Management (admin)

**Routes:**
- `/app/account`
- `/app/account/change-password`
- `/app/settings/email-reports`
- `/app/settings/notifications`
- `/app/admin/users`

### Phase 2 (Week 3-4) — Asset Management
✅ Priority: HIGH
- Vehicle CRUD (enhance existing)
- Vehicle Groups (tree view)
- Speed Groups
- Maintenance Records

**Routes:**
- `/app/fleet` (enhanced)
- `/app/settings/groups`
- `/app/settings/speed-groups`
- `/app/maintenance`

### Phase 3 (Week 5) — Driver & Trailer
✅ Priority: MEDIUM
- Driver CRUD
- Trailer CRUD
- RFID Card Management

**Routes:**
- `/app/drivers` (enhanced)
- `/app/settings/trailers`
- `/app/settings/trailer-groups`
- `/app/settings/rfid-cards`

---

## 🎨 UI Components (ต้องสร้าง)

### Shared Components
- `SettingsLayout.tsx` — layout wrapper
- `SettingsPageHeader.tsx` — consistent header
- `FormModal.tsx` — reusable modal
- `DataTable.tsx` — sortable table
- `ConfirmDeleteModal.tsx` — delete confirmation
- `ImageUpload.tsx` — drag-drop uploader
- `SearchSelect.tsx` — searchable dropdown
- `TreeView.tsx` — collapsible tree
- `PasswordStrengthMeter.tsx` — password indicator

### Page-Specific
- `ProfileCard.tsx` — user profile display
- `EmailReportCard.tsx` — scheduled report item
- `AlertConfigCard.tsx` — alert rule item
- `VehicleFormTabs.tsx` — multi-tab vehicle form
- `DriverFormTabs.tsx` — multi-tab driver form
- `MaintenanceRecordCard.tsx` — maintenance history
- `RFIDScanner.tsx` — RFID integration
- `PermissionMatrix.tsx` — role permission editor

---

## 📊 Key Data Models

### User Profile
```typescript
interface UserProfile {
  id: number;
  email: string;
  name: string;
  phone?: string;
  company?: string;
  role: 'admin' | 'manager' | 'operator' | 'viewer';
  avatar?: string;
  timezone: string;
  language: 'th' | 'en';
}
```

### Vehicle (extended)
```typescript
interface Vehicle {
  // Basic (from Traccar)
  id: number;
  name: string;
  uniqueId: string; // IMEI
  
  // Extended
  licensePlate?: string;
  vehicleType?: string;
  brand?: string;
  model?: string;
  year?: number;
  
  // Groups
  groupId?: number;
  speedGroupId?: number;
  
  // Maintenance
  lastService?: Date;
  nextService?: Date;
  odometer?: number;
  
  // Status
  status: 'active' | 'inactive' | 'maintenance';
}
```

### Driver
```typescript
interface Driver {
  id: number;
  employeeId?: string;
  name: string;
  phone: string;
  email?: string;
  idCard?: string;
  
  licenseNumber?: string;
  licenseType?: string;
  licenseExpiry?: Date;
  
  rfidCard?: string;
  assignedVehicleId?: number;
  safetyScore?: number;
  
  status: 'active' | 'inactive' | 'suspended';
}
```

### Trailer
```typescript
interface Trailer {
  id: number;
  name: string;
  licensePlate?: string;
  type?: string;
  capacity?: number;
  
  groupId?: number;
  currentVehicleId?: number;
  rfidTag?: string;
  
  status: 'available' | 'in-use' | 'maintenance';
}
```

### RFID Card
```typescript
interface RFIDCard {
  id: number;
  cardNumber: string;
  cardType: 'driver' | 'trailer' | 'asset';
  assignedTo?: {
    type: 'driver' | 'vehicle' | 'trailer';
    id: number;
    name: string;
  };
  issueDate: Date;
  expiryDate?: Date;
  status: 'active' | 'inactive' | 'lost';
}
```

---

## 🔗 API Endpoints (ต้องสร้าง)

### User Profile
```
GET    /api/users/me
PATCH  /api/users/{id}
POST   /api/users/{id}/change-password
POST   /api/users/{id}/upload-avatar
```

### Email Reports
```
GET    /api/settings/email-reports
POST   /api/settings/email-reports
PUT    /api/settings/email-reports/{id}
DELETE /api/settings/email-reports/{id}
```

### Alert Configs
```
GET    /api/settings/alert-configs
POST   /api/settings/alert-configs
PUT    /api/settings/alert-configs/{id}
DELETE /api/settings/alert-configs/{id}
```

### Speed Groups
```
GET    /api/speed-groups
POST   /api/speed-groups
PUT    /api/speed-groups/{id}
DELETE /api/speed-groups/{id}
```

### Maintenance
```
GET    /api/maintenance-records
POST   /api/maintenance-records
PUT    /api/maintenance-records/{id}
DELETE /api/maintenance-records/{id}
```

### Drivers
```
GET    /api/drivers
POST   /api/drivers
PUT    /api/drivers/{id}
DELETE /api/drivers/{id}
```

### Trailers
```
GET    /api/trailers
POST   /api/trailers
PUT    /api/trailers/{id}
DELETE /api/trailers/{id}
```

### RFID Cards
```
GET    /api/rfid-cards
POST   /api/rfid-cards
PUT    /api/rfid-cards/{id}
DELETE /api/rfid-cards/{id}
```

### System Users (admin)
```
GET    /api/admin/users
POST   /api/admin/users
PUT    /api/admin/users/{id}
DELETE /api/admin/users/{id}
POST   /api/admin/users/{id}/reset-password
```

---

## ✅ Validation Rules (สำคัญ)

### User Profile
- name: 2-100 chars
- phone: Thai format (0xx-xxx-xxxx)
- avatar: max 2MB, jpg/png only

### Vehicle
- name: required, 1-100 chars
- uniqueId (IMEI): required, 15 digits, unique
- licensePlate: Thai format
- year: 2500-2600 (Buddhist Era)

### Driver
- name: required, 2-100 chars
- phone: required, Thai format
- idCard: 13 digits (optional)
- licenseExpiry: must be future date

### RFID Card
- cardNumber: required, unique, alphanumeric
- expiryDate: must be future (if set)

---

## 🎯 UX Principles

1. **Progressive Disclosure** — แสดงข้อมูลทีละขั้น (multi-tab form)
2. **Immediate Feedback** — toast notification ทันที
3. **Prevent Errors** — validation real-time + ConfirmModal
4. **User Control** — ปุ่ม "ยกเลิก" ทุก modal, soft delete
5. **Consistency** — ใช้ design pattern เดียวกันทุกหน้า

---

## 📱 Responsive Breakpoints

- **Mobile:** < 640px (full-screen modal, stack fields)
- **Tablet:** 640px - 1023px (modal 540px width)
- **Desktop:** >= 1024px (modal 600px width)

---

## 🎨 Color System

```css
--status-active:   #22c55e;  /* เขียว */
--status-inactive: #94a3b8;  /* เทา */
--status-pending:  #f59e0b;  /* ส้ม */
--status-error:    #ef4444;  /* แดง */

--brand:           #1d7aed;  /* น้ำเงิน */
--critical:        #ef4444;  /* แดง */
```

---

## 📝 Next Steps

### Immediate (Week 1)
1. Create database migrations (8 new tables)
2. Build backend API (Phase 1 endpoints)
3. Create shared UI components
4. Implement User Profile pages

### Short-term (Week 2-3)
5. Implement Email Report Config
6. Implement Alert Config
7. Enhance FleetPage with full CRUD
8. Add Vehicle Groups management

### Mid-term (Week 4-5)
9. Implement Driver Management
10. Implement Trailer Management
11. Implement RFID Management
12. Testing + Bug fixes

### Long-term (Week 6+)
13. Documentation (user manual)
14. Admin training
15. Rollout to production
16. Monitor usage + feedback

---

## 📞 Support

**Design Lead:** Claude AI
**Documents:** 5 files (SETTINGS_*.md)
**Total Scope:** 23 sub-menus, 16 main features, 8 database tables
**Estimated Time:** 4-6 weeks (1 developer)

