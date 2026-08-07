# Settings System — Developer Checklist
# รายการตรวจสอบสำหรับนักพัฒนา

## 📋 Phase 1: User Management & Core Settings

### 1.1 Database Setup
- [ ] Create migration file for 8 new tables
- [ ] Run migration on dev database
- [ ] Verify all tables created with correct schema
- [ ] Create indexes for performance (device_id, user_id, date columns)
- [ ] Seed sample data for testing

**SQL Files:**
```bash
infrastructure/docker/postgres/migrations/
├── 001_create_drivers.sql
├── 002_create_trailers.sql
├── 003_create_speed_groups.sql
├── 004_create_maintenance_records.sql
├── 005_create_email_report_configs.sql
├── 006_create_alert_configs.sql
├── 007_create_rfid_cards.sql
└── 008_create_indexes.sql
```

---

### 1.2 Backend API — User Profile

**File:** `bellerox-gps-web/src/services/userService.ts`

- [ ] `getUserProfile()` — GET /api/users/me
- [ ] `updateUserProfile(data)` — PATCH /api/users/{id}
- [ ] `changePassword(oldPassword, newPassword)` — POST /api/users/{id}/change-password
- [ ] `uploadAvatar(file)` — POST /api/users/{id}/upload-avatar

**Validation:**
- [ ] Name: 2-100 chars
- [ ] Phone: Thai format regex
- [ ] Avatar: max 2MB, jpg/png only
- [ ] Password: min 8 chars, strength check

**Testing:**
```bash
# Unit tests
npm test -- userService.test.ts

# API tests
curl -X GET http://localhost:5173/api/users/me -H "Cookie: JSESSIONID=..."
curl -X PATCH http://localhost:5173/api/users/1 -d '{"name":"Test User"}'
```

---

### 1.3 Frontend — User Profile Pages

**Files to Create:**
```
src/pages/
├── AccountSettingsPage.tsx      # View profile
├── EditProfilePage.tsx          # Edit form
└── ChangePasswordPage.tsx       # Change password

src/components/settings/
├── ProfileCard.tsx              # Profile display
├── EditProfileForm.tsx          # Edit form
├── ChangePasswordForm.tsx       # Password form
└── PasswordStrengthMeter.tsx    # Strength indicator
```

**Checklist:**
- [ ] Create AccountSettingsPage.tsx
- [ ] Add route in App.tsx: `/app/account`
- [ ] Add nav item in LayoutV2.tsx
- [ ] Create ProfileCard component
- [ ] Create EditProfileForm component
- [ ] Create ChangePasswordForm component
- [ ] Create PasswordStrengthMeter component
- [ ] Add avatar upload (Cloudflare R2 or AWS S3)
- [ ] Add React Query hooks: `useUserProfile`, `useUpdateProfile`
- [ ] Add form validation with Zod
- [ ] Add loading states
- [ ] Add error states (toast)
- [ ] Add success toast after save
- [ ] Test on mobile (375px)
- [ ] Test dark mode

**React Query Hook:**
```typescript
// src/hooks/useUserProfile.ts
export function useUserProfile() {
  return useQuery({
    queryKey: ['user', 'profile'],
    queryFn: userService.getUserProfile,
  });
}

export function useUpdateProfile() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: userService.updateUserProfile,
    onSuccess: () => {
      queryClient.invalidateQueries(['user', 'profile']);
      toast.success('บันทึกสำเร็จ ✓');
    },
  });
}
```

---

### 1.4 Backend API — Email Report Config

**File:** `bellerox-gps-web/src/services/emailReportService.ts`

- [ ] `getEmailReports()` — GET /api/settings/email-reports
- [ ] `createEmailReport(data)` — POST /api/settings/email-reports
- [ ] `updateEmailReport(id, data)` — PUT /api/settings/email-reports/{id}
- [ ] `deleteEmailReport(id)` — DELETE /api/settings/email-reports/{id}

**Validation:**
- [ ] reportType: enum check
- [ ] frequency: enum check
- [ ] sendTime: HH:MM format
- [ ] recipients: array of valid emails, max 10

---

### 1.5 Frontend — Email Report Config

**Files to Create:**
```
src/pages/
└── EmailReportsPage.tsx

src/components/settings/
├── EmailReportList.tsx
├── EmailReportCard.tsx
├── AddEmailReportModal.tsx
└── EditEmailReportModal.tsx
```

**Checklist:**
- [ ] Create EmailReportsPage.tsx
- [ ] Add route: `/app/settings/email-reports`
- [ ] Add nav item in LayoutV2.tsx
- [ ] Create EmailReportList component
- [ ] Create EmailReportCard component
- [ ] Create AddEmailReportModal component
- [ ] Add React Query hooks
- [ ] Add CRUD operations
- [ ] Add validation
- [ ] Test email sending (cron job)

---

### 1.6 Backend API — Alert Config

**File:** `bellerox-gps-web/src/services/alertConfigService.ts`

- [ ] `getAlertConfigs()` — GET /api/settings/alert-configs
- [ ] `createAlertConfig(data)` — POST /api/settings/alert-configs
- [ ] `updateAlertConfig(id, data)` — PUT /api/settings/alert-configs/{id}
- [ ] `deleteAlertConfig(id)` — DELETE /api/settings/alert-configs/{id}

**Integration:**
- [ ] LINE Notify integration
- [ ] Email alert integration
- [ ] SMS alert integration (optional)

---

### 1.7 Frontend — Alert Config

**Files to Create:**
```
src/pages/
└── AlertConfigPage.tsx

src/components/settings/
├── AlertConfigList.tsx
├── AlertConfigCard.tsx
├── AddAlertConfigModal.tsx
└── EditAlertConfigModal.tsx
```

**Checklist:**
- [ ] Create AlertConfigPage.tsx
- [ ] Add route: `/app/settings/notifications`
- [ ] Add nav item in LayoutV2.tsx
- [ ] Create AlertConfigList component (grouped by type)
- [ ] Create AlertConfigCard component
- [ ] Create AddAlertConfigModal component
- [ ] Add React Query hooks
- [ ] Add CRUD operations
- [ ] Test LINE Notify sending
- [ ] Test email sending

---

### 1.8 Backend API — System User Management (Admin)

**File:** `bellerox-gps-web/src/services/adminUserService.ts`

- [ ] `getSystemUsers()` — GET /api/admin/users (admin only)
- [ ] `createSystemUser(data)` — POST /api/admin/users (admin only)
- [ ] `updateSystemUser(id, data)` — PUT /api/admin/users/{id} (admin only)
- [ ] `deleteSystemUser(id)` — DELETE /api/admin/users/{id} (admin only)
- [ ] `resetUserPassword(id)` — POST /api/admin/users/{id}/reset-password (admin only)

**Authorization:**
- [ ] Check user role in middleware
- [ ] Only `admin` role can access these endpoints
- [ ] Return 403 for non-admin users

---

### 1.9 Frontend — System User Management

**Files to Create:**
```
src/pages/
└── AdminUsersPage.tsx

src/components/admin/
├── UserList.tsx
├── UserCard.tsx
├── AddUserModal.tsx
├── EditUserModal.tsx
├── PermissionMatrix.tsx
└── ResetPasswordModal.tsx
```

**Checklist:**
- [ ] Create AdminUsersPage.tsx
- [ ] Add route: `/app/admin/users` (admin only)
- [ ] Add nav item in LayoutV2.tsx (show only for admin)
- [ ] Create UserList component
- [ ] Create AddUserModal component
- [ ] Create PermissionMatrix component (role selection)
- [ ] Add React Query hooks
- [ ] Add role-based access control (RBAC)
- [ ] Test user creation flow
- [ ] Test password reset flow
- [ ] Test permission restrictions

---

## 📋 Phase 2: Asset Management

### 2.1 Backend API — Vehicle Groups

**File:** `bellerox-gps-web/src/services/vehicleGroupService.ts`

- [ ] Enhance existing `useGroups` hook from Traccar
- [ ] Add tree structure support
- [ ] Add drag-and-drop reorder API

---

### 2.2 Frontend — Vehicle Groups

**Files to Create:**
```
src/pages/
└── VehicleGroupsPage.tsx

src/components/settings/
├── GroupTree.tsx
├── AddGroupModal.tsx
└── EditGroupModal.tsx
```

**Checklist:**
- [ ] Create VehicleGroupsPage.tsx
- [ ] Add route: `/app/settings/groups`
- [ ] Create GroupTree component (collapsible tree)
- [ ] Add drag-and-drop reorder
- [ ] Add CRUD operations
- [ ] Test nested groups (2-3 levels)

---

### 2.3 Backend API — Speed Groups

**File:** `bellerox-gps-web/src/services/speedGroupService.ts`

- [ ] `getSpeedGroups()` — GET /api/speed-groups
- [ ] `createSpeedGroup(data)` — POST /api/speed-groups
- [ ] `updateSpeedGroup(id, data)` — PUT /api/speed-groups/{id}
- [ ] `deleteSpeedGroup(id)` — DELETE /api/speed-groups/{id}

---

### 2.4 Frontend — Speed Groups

**Files to Create:**
```
src/pages/
└── SpeedGroupsPage.tsx

src/components/settings/
├── SpeedGroupCard.tsx
├── AddSpeedGroupModal.tsx
└── EditSpeedGroupModal.tsx
```

**Checklist:**
- [ ] Create SpeedGroupsPage.tsx
- [ ] Add route: `/app/settings/speed-groups`
- [ ] Create SpeedGroupCard component
- [ ] Add CRUD operations
- [ ] Link to vehicles (assign speed group)
- [ ] Test speed violation alerts

---

### 2.5 Backend API — Maintenance Records

**File:** `bellerox-gps-web/src/services/maintenanceService.ts`

- [ ] `getMaintenanceRecords(vehicleId?)` — GET /api/maintenance-records
- [ ] `createMaintenanceRecord(data)` — POST /api/maintenance-records
- [ ] `updateMaintenanceRecord(id, data)` — PUT /api/maintenance-records/{id}
- [ ] `deleteMaintenanceRecord(id)` — DELETE /api/maintenance-records/{id}
- [ ] `uploadReceipt(file)` — POST /api/maintenance-records/{id}/upload

---

### 2.6 Frontend — Maintenance Records

**Files to Create:**
```
src/pages/
└── MaintenancePage.tsx

src/components/maintenance/
├── MaintenanceList.tsx
├── MaintenanceCard.tsx
├── AddMaintenanceModal.tsx
└── MaintenanceSchedule.tsx
```

**Checklist:**
- [ ] Create MaintenancePage.tsx
- [ ] Add route: `/app/maintenance`
- [ ] Create MaintenanceList component
- [ ] Create AddMaintenanceModal component
- [ ] Add receipt upload (images/PDFs)
- [ ] Add due date alerts (email/LINE)
- [ ] Add filter by vehicle
- [ ] Add cost summary

---

### 2.7 Enhance FleetPage with Full CRUD

**Existing File:** `src/pages/FleetPage.tsx`

**Enhancements:**
- [ ] Add multi-tab form (4 tabs: Basic / GPS Device / Documents / Maintenance)
- [ ] Add CSV import (bulk upload)
- [ ] Add CSV export (enhanced with more fields)
- [ ] Add speed group assignment
- [ ] Add maintenance history link
- [ ] Test with 100+ vehicles

---

## 📋 Phase 3: Driver & Trailer Management

### 3.1 Backend API — Drivers

**File:** `bellerox-gps-web/src/services/driverService.ts`

- [ ] `getDrivers()` — GET /api/drivers
- [ ] `createDriver(data)` — POST /api/drivers
- [ ] `updateDriver(id, data)` — PUT /api/drivers/{id}
- [ ] `deleteDriver(id)` — DELETE /api/drivers/{id}
- [ ] `assignDriverToVehicle(driverId, vehicleId)` — POST /api/drivers/{id}/assign

---

### 3.2 Frontend — Driver Management

**Files to Create:**
```
src/pages/
└── DriversPage.tsx (enhance existing)

src/components/drivers/
├── DriverList.tsx
├── DriverCard.tsx
├── AddDriverModal.tsx
├── EditDriverModal.tsx
└── DriverFormTabs.tsx
```

**Checklist:**
- [ ] Enhance DriversPage.tsx
- [ ] Create multi-tab form (4 tabs)
- [ ] Add photo upload
- [ ] Add license expiry alert
- [ ] Add CSV import
- [ ] Link to safety score (from DriverScorePage)
- [ ] Test vehicle assignment

---

### 3.3 Backend API — Trailers

**File:** `bellerox-gps-web/src/services/trailerService.ts`

- [ ] `getTrailers()` — GET /api/trailers
- [ ] `createTrailer(data)` — POST /api/trailers
- [ ] `updateTrailer(id, data)` — PUT /api/trailers/{id}
- [ ] `deleteTrailer(id)` — DELETE /api/trailers/{id}
- [ ] `assignTrailerToVehicle(trailerId, vehicleId)` — POST /api/trailers/{id}/assign

---

### 3.4 Frontend — Trailer Management

**Files to Create:**
```
src/pages/
└── TrailersPage.tsx

src/components/settings/
├── TrailerList.tsx
├── TrailerCard.tsx
├── AddTrailerModal.tsx
└── EditTrailerModal.tsx
```

**Checklist:**
- [ ] Create TrailersPage.tsx
- [ ] Add route: `/app/settings/trailers`
- [ ] Create TrailerCard component (grid layout)
- [ ] Add vehicle assignment
- [ ] Add RFID integration
- [ ] Show current status (available/in-use)

---

### 3.5 Backend API — RFID Cards

**File:** `bellerox-gps-web/src/services/rfidService.ts`

- [ ] `getRFIDCards()` — GET /api/rfid-cards
- [ ] `createRFIDCard(data)` — POST /api/rfid-cards
- [ ] `updateRFIDCard(id, data)` — PUT /api/rfid-cards/{id}
- [ ] `deleteRFIDCard(id)` — DELETE /api/rfid-cards/{id}
- [ ] `scanRFIDCard()` — WebSocket listener for RFID scan events

---

### 3.6 Frontend — RFID Management

**Files to Create:**
```
src/pages/
└── RFIDCardsPage.tsx

src/components/settings/
├── RFIDCardList.tsx
├── RFIDCardCard.tsx
├── AddRFIDCardModal.tsx
└── RFIDScanner.tsx
```

**Checklist:**
- [ ] Create RFIDCardsPage.tsx
- [ ] Add route: `/app/settings/rfid-cards`
- [ ] Create RFIDScanner component (WebSocket)
- [ ] Add card assignment (driver/trailer/asset)
- [ ] Add expiry alert
- [ ] Test scan-to-assign flow

---

## ✅ Final Testing Checklist

### Functional Testing
- [ ] All CRUD operations work
- [ ] Form validation works (required fields, format)
- [ ] File uploads work (avatar, receipts)
- [ ] Search filters work
- [ ] Sorting works (table columns)
- [ ] Pagination works (> 100 items)
- [ ] Delete confirmation works
- [ ] Toast notifications show

### UI/UX Testing
- [ ] Loading states show correctly
- [ ] Error states show toast + retry
- [ ] Empty states show EmptyState component
- [ ] Modal can close (X, ESC, overlay click)
- [ ] Forms reset after close
- [ ] Keyboard navigation works (Tab, Enter, ESC)

### Responsive Testing
- [ ] Mobile 375px width works
- [ ] Tablet 768px width works
- [ ] Desktop 1920px width works
- [ ] Touch targets >= 44px (mobile)

### Dark Mode Testing
- [ ] All colors use CSS vars
- [ ] No hardcoded colors
- [ ] Readable in both light/dark

### Accessibility Testing
- [ ] All images have alt text
- [ ] Buttons have aria-label (icon-only)
- [ ] Forms have proper labels
- [ ] Focus visible (keyboard)
- [ ] Color contrast >= 4.5:1 (WCAG AA)

### Performance Testing
- [ ] Page load < 2s
- [ ] Table renders < 500ms (100 rows)
- [ ] No memory leaks (React DevTools Profiler)
- [ ] Images optimized (< 100KB)

### Security Testing
- [ ] CSRF protection
- [ ] XSS protection (sanitize inputs)
- [ ] SQL injection protection (parameterized queries)
- [ ] Role-based access control (admin routes)
- [ ] Password hashing (bcrypt)

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] All tests pass (`npm test`)
- [ ] Build passes (`npm run build`)
- [ ] Lint passes (`npm run lint`)
- [ ] No console errors in browser
- [ ] Database migrations ready

### Deployment
- [ ] Run database migrations on production
- [ ] Deploy backend API
- [ ] Deploy frontend (Cloudflare Pages)
- [ ] Update environment variables
- [ ] Restart services

### Post-Deployment
- [ ] Smoke test (login, view profile, create vehicle)
- [ ] Check error logs (no exceptions)
- [ ] Monitor performance (page load times)
- [ ] User acceptance testing (UAT)

---

## 📞 Support

**Developer:** Review this checklist at each phase
**Total Items:** ~150 checkboxes
**Estimated Time:** 4-6 weeks (1 developer)

