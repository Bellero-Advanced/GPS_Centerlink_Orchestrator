# Production Polish Sprint — Beta to Stable v1.0
> **Strategy:** ยกระดับหน้า Beta → Production-grade + Dynamic Branding System
> **Created:** 2026-08-07
> **Status:** approved

---

## 🎯 Goal
1. **Upgrade 7 pages** จาก Beta/mock → Production-ready ตาม DESIGN.md
2. **Dynamic Branding System** — sidebar/header สีตาม company brand
3. **Logo rebrand** — headbar แสดง logo+ชื่อ · sidebar แสดง Clock+Contact
4. **User account visibility** — tenant users เห็น company info เหมือน admin

---

## ✅ Done When
- [ ] Build passes zero TS errors
- [ ] All 7 pages load without Beta labels
- [ ] No bento-card class used
- [ ] Inspection + Compliance full-screen
- [ ] Sidebar + header apply companyBrandColor
- [ ] Logo + company name in headbar
- [ ] Clock + contact in sidebar
- [ ] Dark mode works

---

## Phase 1: Dynamic Branding Foundation

- [ ] T001 — Add companyBrandColor to CompanyInfo (src/hooks/useCompanyInfo.ts)
- [ ] T002 — Create brand color utility (src/lib/brandTheme.ts)
- [ ] T003 — Apply brand colors in Layout.tsx

**Checkpoint:** Build passes, sidebar/header branded

---

## Phase 2: Logo & Identity Upgrade

- [ ] T004 — Headbar logo + company name (Layout.tsx)
- [ ] T005 — Sidebar Clock + Contact (Layout.tsx)
- [ ] T006 — User account dropdown upgrade (Layout.tsx)

**Checkpoint:** Visual match images

---

## Phase 3: Fix Beta Pages

- [ ] T007 — Fix SpeedPage (remove Beta)
- [ ] T008 — Fix ScoringPage (remove Beta)
- [ ] T009 — Fix FuelPage (bento → fill-block)

**Checkpoint:** Beta pages production-grade

---

## Phase 4: Full-Screen Pages

- [ ] T010 — InspectionPage full-screen
- [ ] T011 — CompliancePage full-screen

**Checkpoint:** Both full viewport

---

## Phase 5: Polish Remaining

- [ ] T012 — AuditLogPage UI
- [ ] T013 — AlertSettingsPage fixes

**Checkpoint:** All pages clean

---

## Phase 6: Admin Settings

- [ ] T014 — Brand Color in SettingsPage
- [ ] T015 — Brand Color in AdminSettingsPage

**Checkpoint:** Admin can set colors

---

## Phase 7: Final QC

- [ ] T016 — Build verification
- [ ] T017 — Dark mode check
- [ ] T018 — Mobile responsive

**Checkpoint:** Production-ready
