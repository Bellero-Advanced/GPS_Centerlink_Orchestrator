# 📋 แผนงาน: เพิ่มฟังก์ชันลบ User

**Status:** completed ✅  
**Created:** 2026-09-24  
**Goal:** เพิ่มปุ่ม "ลบ" ในหน้า Team Management ให้ admin ลบ user ออกจากระบบได้ (hard delete)

---

## 🎯 Goal
Admin สามารถลบ user ที่ไม่ต้องการออกจากระบบได้ โดยต้องมี confirm dialog ป้องกันการลบผิดพลาด

---

## 🛠️ Stack (ใช้ที่มีอยู่)
- React + TypeScript
- React Query (useMutation + invalidateQueries)
- traccarService.deleteUser() — มีอยู่แล้ว ✅
- Lucide icons (Trash2)
- Toast notification

---

## 📄 Pages & Components
```
src/pages/TeamPage.tsx
├─ UserRow component          ← เพิ่มปุ่ม "ลบ" + state confirm
└─ DeleteConfirmDialog (new)  ← modal ยืนยันก่อนลบ
```

---

## ✅ Done When
- [x] ปุ่ม "ลบ" ปรากฏในแต่ละแถว user (ข้างปุ่ม "แก้ไข")
- [x] กดปุ่ม "ลบ" → เปิด confirm dialog (ชื่อ user + ยืนยัน/ยกเลิก)
- [x] กดยืนยัน → เรียก `traccarService.deleteUser(id)` → invalidate query → user หายจากรายการ
- [x] แสดง toast "ลบผู้ใช้สำเร็จ"
- [x] กดยกเลิก → ปิด dialog โดยไม่ทำอะไร
- [x] ห้ามลบตัวเอง (isSelf = true → ไม่แสดงปุ่ม "ลบ")
- [x] `npm run build` ผ่าน zero errors

---

## 📦 Phases

### Phase 1: UI — เพิ่มปุ่มลบ + confirm dialog

**T001** `ui-builder` — เพิ่มปุ่ม "ลบ" ใน UserRow + DeleteConfirmDialog component  
Files: `src/pages/TeamPage.tsx`  
- เพิ่ม `Trash2` icon จาก lucide-react
- เพิ่มปุ่ม "ลบ" ข้างปุ่ม "แก้ไข" (สีแดง: `#ef4444`)
- สร้าง `DeleteConfirmDialog` component (modal style เดียวกับ CreateUserModal)
- เพิ่ม state `deleteUser: TraccarUser | null` ใน TeamPage
- เงื่อนไข: `!isSelf` ถึงจะแสดงปุ่มลบ

**Checkpoint:** ✅  
✓ ปุ่ม "ลบ" ปรากฏในทุกแถว (ยกเว้นตัวเอง)  
✓ กดแล้วเปิด DeleteConfirmDialog  
✓ Dialog แสดงชื่อ user + ข้อความเตือน + ปุ่มยืนยัน/ยกเลิก

---

### Phase 2: Logic — เชื่อม API deleteUser

**T002** `dev-builder` — เชื่อม useMutation กับ traccarService.deleteUser()  
Files: `src/pages/TeamPage.tsx`  
- สร้าง `useMutation` ที่เรียก `traccarService.deleteUser(userId)`
- `onSuccess`: invalidate `['managed-users']` + toast.success + ปิด dialog
- `onError`: toast.error('ลบไม่สำเร็จ')
- ปุ่มยืนยันใน dialog: disabled ขณะกำลังลบ + แสดง Loader2 spinner

**Checkpoint:** ✅  
✓ กดยืนยันใน dialog → เรียก API → user หายจากรายการ  
✓ แสดง toast "ลบผู้ใช้สำเร็จ"  
✓ ถ้า API error → แสดง toast "ลบไม่สำเร็จ กรุณาลองใหม่"

---

### Phase 3: QC — ทดสอบ + build

**T003** `test-runner` — ทดสอบฟังก์ชันลบ + npm run build  
- ทดสอบลบ user ธรรมดา → สำเร็จ
- ทดสอบลบตัวเอง → ไม่มีปุ่มลบ
- ทดสอบกดยกเลิก → dialog ปิด ไม่ลบ
- `npm run build` → zero errors

**Checkpoint:** ✅  
✓ Delete user ใช้งานได้จริง  
✓ ห้ามลบตัวเอง (no button)  
✓ TypeScript + build pass

**Evidence:**
```bash
$ npm run build
✓ built in 27.78s
Exit code: 0
```

---

## ⏱️ Estimated Time
**10-15 minutes** (งานเล็ก แค่เพิ่มปุ่ม + dialog + เชื่อม API ที่มีอยู่)

---

## 📊 Summary
| Phase | Tasks | Agent | Est. Time |
|-------|-------|-------|-----------|
| 1. UI | T001 | ui-builder | 5 min |
| 2. Logic | T002 | dev-builder | 5 min |
| 3. QC | T003 | test-runner | 5 min |
| **Total** | **3 tasks** | **3 agents** | **15 min** |
