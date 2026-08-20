---
updated: 2026-08-18
---

# Active Work

## ✅ Completed: Multi-Tenant Architecture

**Plan:** `.toh/certificate-tenant-data.md` (approved + executed)

**Status:** All tasks completed and deployed

### What was done:

**Tenant System Features:**
- **Multi-tenant isolation** — แต่ละลูกค้ามี database row, custom domain, admin account แยกกัน
- **White-label branding** — logo, colors, app name ตั้งค่าได้ต่อ tenant
- **GPS server config** — port range allocation per tenant
- **Admin pages** — TenantListPage (ดูรายชื่อ) + TenantDetailPage (จัดการ tenant)
- **Mobile app builder** — ปุ่ม trigger EAS build iOS/Android ได้จากหน้า admin
- **Sub-companies view** — แสดงบริษัทย่อยภายใต้แต่ละ tenant

**Architecture:**
- Supabase table `tenants` with JSON schema
- Service layer: `tenantService.ts` (CRUD + asset upload)
- Admin Traccar integration: suspend/resume + password reset
- Route guard: `/admin/*` routes

### Deployment:
- Commit: `2d84c0f`
- CI/CD: ✅ Passed (build 32137607372)
- Live: https://gpsthailand.centerlink.co.th/admin/tenants

### Files added:
- `src/pages/admin/TenantListPage.tsx`
- `src/pages/admin/TenantDetailPage.tsx`
- `src/services/tenantService.ts`
- `src/lib/tenantConfig.ts`

## ✅ Completed: Certificate Signature & Seal to TenantTheme

**Date:** 2026-08-20

### What was done:
- เพิ่มฟิลด์ลายเซ็น/ตราประทับใน `TenantTheme` interface:
  - `authorizedSignatoryName` — ชื่อกรรมการผู้มีอำนาจ
  - `signatureUrl` — URL ลายเซ็นกรรมการ
  - `companySealUrl` — URL ตราประทับบริษัท
- แก้ `useCompanyInfo` ให้ดึงข้อมูลจาก theme (fallback)
- แก้ `certificateService.ts`:
  - ขยายขนาดรูปลายเซ็น 200x80px, ตราประทับ 100x100px
  - เพิ่ม `object-fit: contain` รักษาสัดส่วนรูป
  - เพิ่ม `crossOrigin='anonymous'` สำหรับ CORS
  - เพิ่ม image preload wait ก่อน generate PDF
- Certificate PDF ดึงข้อมูลอัตโนมัติจาก tenant theme แล้ว

### Deployment:
- Commit: `fbf1cbc`
- CI/CD: ✅ Passed (build 32296351808)
- Live: https://gpsthailand.centerlink.co.th/

### Testing:
- [ ] Upload ลายเซ็นที่ `/admin/tenants/[id]`
- [ ] Upload ตราประทับที่ `/admin/tenants/[id]`
- [ ] ออกใบรับรอง → ดูว่าลายเซ็น/ตราประทับโชว์ถูกต้อง รักษาสัดส่วน

## 🔧 Current: Certificate HTML2Canvas Fix

**Issue:** Certificate generation failing with "Node cannot be found in the current page" error from html2canvas library.

**Root Cause:** Off-screen positioning (`left: -9999px`) broke html2canvas's internal DOM tree traversal. The library clones the DOM tree and needs elements to be in normal layout flow.

**Solution:**
- Changed from `position: absolute; left: -9999px` to `position: fixed; visibility: hidden`
- Keeps element at (0,0) in layout flow but invisible to user
- Simplified html2canvas options (removed onclone callback, set allowTaint:false)
- Added layout reflow trigger before capture

**Files Changed:**
- `bellerox-gps-web/src/services/certificateService.ts` — positioning strategy

**Status:**
- ✅ Committed: `85bc6b2`
- ✅ Pushed to GitHub
- 🔄 CI/CD running: https://github.com/Bellero-Advanced/bellerox-gps-web/actions
- 🧪 **Needs testing:** Generate certificate from DLT Compliance page to verify fix

## Next: (awaiting user)
Test certificate generation to verify html2canvas fix works.
