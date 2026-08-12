# Active Work — GPS Thailand Application

## 🎯 Current Focus

✅ เสร็จแล้ว (2026-08-12):
- **White-label branding fix**: รวม 2 TenantContext เป็นอันเดียว (single source of truth) + `useCompanyInfo` fallback → tenant theme
- **Color-fill polish**: ลบ hard-coded `borderColor:'#DADCE0'` / `border:'1px solid #E8EAED'` ใน 7 admin files + AccountSettingsPage (เปลี่ยนเป็น `var(--surface-2)` fill)
- **Sidebar cleanup**: เอา "พื้นที่กำหนด" ออก เหลือแค่ "จุดสนใจ" (label เปลี่ยนจาก "จุดสนใจ (POI)" → "จุดสนใจ")
- **Build verified**: `npm run build` ผ่าน 20.37s, 0 TypeScript errors

📋 งานต่อไป:
- ทดสอบ multi-tenant login ที่ subdomain ต่างๆ (gps.centerlink.co.th vs GPS Thailand)
- เพิ่ม "Reset to defaults" ใน TenantDetailPage Branding section
- E2E test (Playwright) สำหรับ create tenant → branding auto-apply

## 📌 Just Completed

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

**Build Status:** ✅ Passed (20.37s, 0 errors)

## 🗂️ Next Steps

1. ทดสอบ multi-tenant login แยก subdomain
2. เพิ่ม Reset to defaults ใน TenantDetailPage
3. Playwright E2E test สำหรับ create tenant → branding auto-apply

## 📚 References

- Plan file: `.toh/plan.md` (white-label-branding-fix)
- Color-fill design tokens: `bellerox-gps-web/src/index.css`
- Brand colors utility: `bellerox-gps-web/src/lib/brandTheme.ts`
- Longdo API key: stored in `.env.local` (e4e9be1dbdc29a63c81f834251b14de1)
