# Active Work — GPS Thailand Application

## 🎯 Current Focus

✅ เสร็จแล้ว (2026-08-13):
- **DLT GPS Model ID validation fix**: แก้ bug `startsWith('52')` → ลบออก (field เป็น select แล้ว) + `padStart(2)` → `padStart(3)` ใน calculateLicense()
  - commit `f2a3af5` · CI ✅ success · deploy to Cloudflare Pages ✅

✅ เสร็จแล้ว (2026-08-13) — ก่อนหน้า:
- **Dashboard Enhancement — Filter + Search + Sort**: เพิ่ม 3 controls ให้ vehicle table
  1. Status filter dropdown (ทุกสถานะ/เคลื่อนที่/จอดติดเครื่อง/จอดดับเครื่อง/ออฟไลน์)
  2. Search box (ค้นหาตามชื่อยานพาหนะหรือ uniqueId)
  3. Sort controls (เรียงตาม name/speed/status + toggle asc/desc)
  4. Sortable table headers (คลิกหัวคอลัมน์เพื่อเรียง)
- **Build verified**: `npm run build` ผ่าน 13.46s, 0 TypeScript errors
- **Result count** อัพเดทตามการกรอง
- **Auto-reset pagination** เมื่อ filter/search/sort เปลี่ยน

**Previous session (2026-08-13):**
- **Dashboard Redesign**: Simplified layout — 4 KPI stats in header + paginated vehicle table only
- ลบ: Donut chart, health score, recent alerts, operational KPIs (8 กล่อง), quick actions, stats row, summary footer
- เพิ่ม: Pagination (10 รายการ/หน้า) ให้ vehicle table
- เก็บ: Idle warning + offline list
- DESIGN.md: เพิ่ม KPI pattern documentation (2-line dashboard, 3-line other pages)

📋 งานต่อไป:
- ทดสอบ multi-tenant login ที่ subdomain ต่างๆ (gps.centerlink.co.th vs GPS Thailand)
- เพิ่ม "Reset to defaults" ใน TenantDetailPage Branding section
- E2E test (Playwright) สำหรับ create tenant → branding auto-apply
- Bulk actions สำหรับ vehicle table (select multiple)
- Export filtered results to CSV

## 📌 Just Completed

**Dashboard Filter + Search + Sort (2026-08-13):**
- Added status filter, search box, sort dropdown + order toggle
- Sortable table headers (click to sort by name/speed/status)
- Dynamic result count
- Pagination resets on filter change
- File: `bellerox-gps-web/src/pages/DashboardPage.tsx`

**Dashboard Redesign (2026-08-13):**
- Simplified to 4 KPI stats + vehicle table only
- 2-line KPI design (title + value)
- Pagination (10 items/page)
- Files: `DashboardPage.tsx`, `DESIGN.md`

**White-label Branding Fix (root causes):**
1. `src/context/TenantContext.tsx` (OLD) — ลบทิ้งทั้งโฟลเดอร์
2. `src/contexts/TenantContext.tsx` (NEW) — รวมเป็น single source + ใช้ `applyBrandColors()` จาก `brandTheme.ts`
3. `src/hooks/useCompanyInfo.ts` — merge logic user attrs → tenant theme fallback

**Color-fill Polish:**
- ลบ ~50 จุดที่ hard-coded borders/slate colors
- ใช้ `fill-block-elevated`, `fill-block-subtle`, `.data-table`, `.chip` class ที่มีอยู่แล้ว

**Sidebar Cleanup:**
- เอา "พื้นที่กำหนด" ออก → เหลือ "จุดสนใจ"

**Files Changed:**
- `bellerox-gps-web/src/contexts/TenantContext.tsx` (rewritten)
- `bellerox-gps-web/src/hooks/useCompanyInfo.ts` (tenant fallback)
- `bellerox-gps-web/src/components/Logo.tsx` + `CenterlinkLoader.tsx` (import paths)
- `bellerox-gps-web/src/components/layout/LayoutV2.tsx` (sidebar cleanup)
- `bellerox-gps-web/src/pages/admin/{TenantDetailPage,TenantsPage,AdminSettingsPage,AdminUsersPage,AdminDLTPage,AdminServerConfigPage}.tsx`
- `bellerox-gps-web/src/pages/{LoginPage,AccountSettingsPage,SearchPage}.tsx`
- `bellerox-gps-web/src/pages/auth/ForgotPasswordPage.tsx`
- `bellerox-gps-web/src/App.tsx` (TenantProvider alias)

**Build Status:** ✅ Passed (13.46s, 0 errors)

## 🗂️ Next Steps

1. ทดสอบ multi-tenant login แยก subdomain
2. เพิ่ม Reset to defaults ใน TenantDetailPage
3. Playwright E2E test สำหรับ create tenant → branding auto-apply
4. Bulk vehicle actions (optional enhancement)
5. CSV export (optional enhancement)

## 📚 References

- Plan file: `.toh/plan.md` (dashboard-simplify + enhancements)
- Color-fill design tokens: `bellerox-gps-web/src/index.css`
- Brand colors utility: `bellerox-gps-web/src/lib/brandTheme.ts`
- Longdo API key: stored in `.env.local` (e4e9be1dbdc29a63c81f834251b14de1)
