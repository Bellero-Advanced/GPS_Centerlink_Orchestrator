# Plan: White-label Branding (Tenant Theme) — Fix Regression + Color-fill Polish + Sidebar Cleanup

**Status:** draft
**Created:** 2026-08-12
**Goal:** แก้ปัญหา white-label tenant branding ไม่ apply (logo / primary color / background fallback ไป Centerlink) + ปรับ component UI ให้เป็น color-fill แบบสม่ำเสมอ + เอา tab "พื้นที่กำหนด" ออกจาก sidebar เหลือแค่ "จุดสนใจ (POI)"

---

## 🎯 Root Cause (จากการสำรวจโค้ดจริง)

มี **2 TenantContext ทับซ้อน** และ **2 ระบบ branding** ตีกันเอง:

| Layer | ไฟล์ | แหล่งข้อมูล branding | ใช้ที่ไหน |
|-------|------|--------------------|----------|
| **OLD** | `src/context/TenantContext.tsx` (TenantThemeProvider) | tenant.theme (Supabase / localStorage) | App.tsx, LoginPage, Logo, ForgotPassword, CenterlinkLoader |
| **NEW** | `src/contexts/TenantContext.tsx` (TenantProvider) | tenant.theme (Supabase / localStorage) | LayoutV2, SettingsPage, BillingPage, PlanBillingSection |
| **LEGACY** | `src/hooks/useCompanyInfo.ts` | `user.attributes.*` (Traccar user attributes) | Layout, LayoutV2 (header user dropdown), AccountSettingsPage |

**ปัญหา:**
1. LayoutV2 ดึง `useTenant()` (NEW) → applyBrandColors จาก `tenantTheme.primaryColor` ✅ (ดูเหมือนถูก)
2. **แต่ `applyBrandColors` ถูกเรียกซ้อน** — ทั้ง `TenantContext.tsx` (OLD) และ `LayoutV2` เรียก `setProperty('--brand', ...)` และ OLD ใช้ `adjustColor(brandColor, -15)` (linear RGB shift) ที่**ทำลาย hue** ของสีจริง
3. `useCompanyInfo` (LEGACY) ยังถูกใช้ใน **header user dropdown** ของ LayoutV2 (รูปบริษัทบน avatar + ข้อมูลบริษัท dropdown) — ถ้า tenant admin ไม่ได้แก้ company attributes ใน Traccar จะ fallback ไป Centerlink (`#EC4899` default ใน `brandColors.ts`)
4. ทุก input ในหน้า Admin (`TenantDetailPage`, `TenantsPage`, `AdminSettingsPage`) hard-code `borderColor: '#DADCE0'` + `border: '1px solid #DADCE0'` — ขัดกับ color-fill design system
5. Sidebar มี 2 entry ที่ทับซ้อน: "พื้นที่กำหนด" (NAV ops) + มี "จุดสนใจ (POI)" ใน NAV ops → ผู้ใช้ขอเอาพื้นที่กำหนดออก

## Stack
- React 18 + TypeScript + Vite 5
- Tailwind CSS (design tokens ใน `src/index.css`)
- Supabase (`cl_tenants` table) + localStorage cache
- Traccar user attributes (สำหรับ CompanyInfo ฝั่ง user)

---

## Phases

### Phase 1 — Consolidate TenantContext (single source of truth)
**Goal:** รวม 2 context เป็นอันเดียว ให้ทุกหน้าใช้ tenant.theme จาก Supabase จริงๆ

- **T001 [dev-builder]** `src/contexts/TenantContext.tsx`
  - เพิ่ม useEffect ที่ 2: หลัง tenant โหลด → call `applyBrandColors(theme.primaryColor)` จาก `brandTheme.ts` (ไม่ใช้ adjustColor แบบเก่า)
  - Export hook ใหม่ `useTenantTheme()` (alias ของ `useTenant()`) เพื่อให้ LoginPage / Logo / ForgotPassword / CenterlinkLoader ใช้ได้ทันทีโดยไม่ต้องเปลี่ยน import path
  - ลบ `src/context/TenantContext.tsx` (เก่า)
  - เปลี่ยน `App.tsx`: `import { TenantThemeProvider as TenantProvider }` + ใช้อันเดียว

- **T002 [dev-builder]** แทนที่จุดที่ใช้ OLD context ให้ใช้ NEW (จะรวม import path ใน T003)
  - Logo.tsx, CenterlinkLoader.tsx, LoginPage.tsx, ForgotPasswordPage.tsx, App.tsx

- **T003 [dev-builder]** `src/hooks/useCompanyInfo.ts`
  - **เพิ่ม** resolver layer: ถ้า `user.attributes.companyBrandColor/Logo/...` ว่าง → fallback ไป `useTenant().theme.primaryColor / .logoUrl / .appName`
  - เพื่อให้ header dropdown ของ LayoutV2 แสดง logo + ชื่อบริษัท **จาก tenant config จริง** (ไม่ใช่ user attrs)
  - ทำ CompanyInfo = merge(user.attrs, tenant.theme) ส่งกลับ

✅ **Checkpoint P1:** `npm run build` ผ่าน + ลอง Login ใน localhost:
- Header brand color เปลี่ยนตาม primaryColor ใน Supabase tenant
- Logo ใน header dropdown = `tenant.theme.logoUrl`
- ไม่มี "flash of pink Centerlink" ตอนโหลด

---

### Phase 2 — Color-fill UI Polish (Admin & Account pages)
**Goal:** เปลี่ยน hard-coded borders เป็น color-fill / surface-2 fill ให้หมด

- **T004 [ui-builder]** `src/pages/admin/TenantDetailPage.tsx`
  - `inputCls` ที่ใช้ `surface-2` already — แต่**ยังมี inline `style={{ borderColor: '#DADCE0' }}`** ทับอยู่ 35+ จุด
  - เปลี่ยนเป็น `style={{ border: 'none' }}` (ยกเลิก hard-coded borderColor)
  - ลบ border `1px solid #DADCE0` ออกจาก image preview frames (61, 66, 75, 210) → ใช้ `surface-2` fill แทน

- **T005 [ui-builder]** `src/pages/admin/TenantsPage.tsx` (NewTenantModal)
  - ลบ `style={{ borderColor: '#DADCE0' }}` ทุก input (8 จุด)
  - เปลี่ยน `border: '1px solid #E8EAED'` ใน tenant list row → ใช้ `surface-2` fill background แทน (card-style)

- **T006 [ui-builder]** `src/pages/admin/AdminSettingsPage.tsx`
  - ลบ `borderColor: '#DADCE0'` ทุก input (10 จุด, รวม `onFocus` / `onBlur` ด้วย)
  - ลบ `border: '1px solid #E8EAED'` ใน tenant expandable row

- **T007 [ui-builder]** `src/pages/admin/AdminUsersPage.tsx`, `AdminDLTPage.tsx`, `AdminServerConfigPage.tsx`
  - เปลี่ยน `borderBottom: '1px solid #E8EAED'` ของ table headers → ใช้ `.data-table` class ที่มีอยู่แล้ว
  - ลบ inline borders อื่นๆ ที่เหลือ

- **T008 [ui-builder]** `src/pages/AccountSettingsPage.tsx`
  - `inputBase` style มี `border: '1px solid var(--border)'` → ลบออก (ให้ class `input` ใน index.css จัดการ)
  - ToggleRow bg `#BDC1C6` → ใช้ `var(--ink-4)`
  - Company form inputs ที่ใช้ inline hard-coded border → ลบออก

✅ **Checkpoint P2:** `npm run build` ผ่าน + visual check: ไม่มี input/panel ไหนมีขอบแข็งอีก ทุกอย่างเป็น color-fill (ตาม DESIGN.md §5.4)

---

### Phase 3 — Sidebar Cleanup
**Goal:** เอา "พื้นที่กำหนด" ออกจาก sidebar ตามที่พี่โตขอ

- **T009 [ui-builder]** `src/components/layout/LayoutV2.tsx`
  - ลบ object `{ to: '/app/geofences', icon: Shield, label: 'พื้นที่กำหนด' }` ออกจาก `NAV[1].items` (ปฏิบัติการ section)
  - **เปลี่ยน** label "จุดสนใจ (POI)" → "จุดสนใจ" (ตัด "(POI)" ออก) — ตามที่พี่โตระบุเหลือแค่จุดสนใจ

- **T010 [ui-builder]** `src/pages/SearchPage.tsx` (ถ้ามี) — ลบ quick-link "พื้นที่กำหนด" ด้วย (เปลี่ยน redirect ไป `/app/poi-areas`)

- **T011 [dev-builder]** `App.tsx` — ตรวจว่า `/app/geofences` route ใช้ `Navigate to="/app/poi-areas"` อยู่แล้ว (จากที่อ่าน line 189-190 ✅) — **ไม่ต้องแก้**

✅ **Checkpoint P3:** Sidebar ฝั่งซ้ายเหลือ "จุดสนใจ" อย่างเดียว — กดแล้วไป `/app/poi-areas`

---

### Phase 4 — Verification
- **T012 [test-runner]**
  - `cd bellerox-gps-web && npm run build` → ต้อง exit 0
  - `npm run lint` → ต้อง 0 warnings
  - ทดสอบ flow ใน browser (manual):
    - Login → header สีตาม tenant primaryColor ✅
    - กด `/app/poi-areas` → "จุดสนใจ" เหลืออย่างเดียว ✅
    - ทุก input ใน Admin pages เป็น color-fill ✅ (ไม่มีขอบ)
  - อัปเดต memory: `.toh/memory/active.md` + `summary.md` + `changelog.md`

---

## Definition of Done
- ✅ branding ของ tenant (primaryColor / logo / background) apply จริง ไม่ fallback ไป Centerlink
- ✅ ไม่มี hard-coded `borderColor` / `border: '1px solid #...'` ใน Admin / Account pages
- ✅ Sidebar: เอา "พื้นที่กำหนด" ออก เหลือ "จุดสนใจ"
- ✅ `npm run build` ผ่าน, `npm run lint` ผ่าน, ไม่ regression
- ✅ Memory อัปเดต

## 3 Next Actions หลังเสร็จ
1. ทดสอบ multi-tenant login (gps.centerlink.co.th vs GPS Thailand subdomain) — ยืนยัน brand color แยกชัดเจน
2. เพิ่ม "Reset to defaults" ใน TenantDetailPage Branding section เพื่อ revert กลับ Centerlink theme
3. ทำ E2E test (Playwright) สำหรับ create tenant → branding auto-apply

---

*เป้าหมาย: ขจัด 2 root causes (2 TenantContext + useCompanyInfo legacy) + color-fill polish + sidebar cleanup · 4 phases · 12 tasks · ~25 นาที*
