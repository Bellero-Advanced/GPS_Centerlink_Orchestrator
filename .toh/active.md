# Active Work — Dashboard Enhancement

**Current Focus:** Implementing Phase 3-5 of Dashboard Enhancement Plan

**Status:** T001-T002 complete ✅ | Moving to T003 Export Formats

---

## Just Completed (T002)

✅ **Quick Actions in Bulk Selection Bar**
- Added "ติดตาม" (Track) button → navigates to `/app/map`
- Added "ดูประวัติ" (History) button → navigates to `/app/fleet` 
- Both buttons disabled when no vehicles selected
- Positioned left of Export button in floating action bar
- Build passed with 0 errors

---

## Next Steps

**T003-T005: Export Format Options**
1. Replace single "Export CSV" button with dropdown menu
2. Implement Excel export (xlsx library already in project)
3. Implement PDF export (jspdf + jspdf-autotable)

**T006-T008: Advanced Preset Filters**
1. Create advanced preset modal UI
2. Implement logic (offline hours + speed threshold filters)
3. Update preset chips to show advanced info

**T009: Apply All Features to FleetPage**
1. Copy bulk selection + export + presets + quick actions from Dashboard to Fleet

---

## Files Modified

- `src/pages/DashboardPage.tsx` — Added quick action buttons (ติดตาม + ดูประวัติ)
- `.toh/plan.md` — Marked T001 ✅ T002 ✅

---

**Plan Location:** `.toh/plan.md` (10 tasks total, 2 done, 8 remaining)
