# Certificate Tenant Data Integration

**Status:** `completed`  
**Created:** 2026-08-19  
**Completed:** 2026-08-19  
**Model:** claude-opus-5

## Objective

ใบรับรองทะเบียนรถ ดึงข้อมูลบริษัทจาก tenant ใน `/admin` + เพิ่ม field ลายเซ็น + ตราประทับ

## Requirements

1. ข้อมูลบริษัท (ชื่อ, ที่อยู่, เบอร์) → ดึงจาก tenant database (หน้า `/admin` มีอยู่แล้ว)
2. เพิ่ม 3 fields ใหม่ใน tenant settings (`/admin`):
   - `directorName` — ชื่อกรรมการผู้มีอำนาจ
   - `directorSignature` — รูปลายเซ็น (image upload, preserve aspect ratio)
   - `companySeal` — รูปตราประทับบริษัท (image upload, preserve aspect ratio)
3. Certificate PDF ใช้ข้อมูลจาก tenant + ประทับลายเซ็น + ตราลงใน PDF

## Tasks

- [ ] `T1` [dev-builder] เช็คหน้า `/admin` — มี tenant settings form อยู่ที่ไหน (AdminPage? SettingsPage?)
- [ ] `T2` [dev-builder] เพิ่ม 3 fields ใน tenant model/type: `directorName`, `directorSignature`, `companySeal`
- [ ] `T3` [ui-builder] เพิ่ม 3 inputs ในหน้า admin:
  - Text input: ชื่อกรรมการ
  - Image upload: ลายเซ็น (with preview, preserve ratio)
  - Image upload: ตราประทับ (with preview, preserve ratio)
- [ ] `T4` [dev-builder] แก้ `certificateService.ts` — ดึง tenant data แทนค่า hardcode
- [ ] `T5` [dev-builder] แก้ certificate template — แสดงลายเซ็น + ตราประทับ (preserve ratio, no squeeze)
- [ ] `T6` [test-runner] Build + ทดสอบ E2E (upload signature → generate cert → ตรวจรูปไม่บีบ)

## Done When

- [ ] ✅ Admin page มี 3 fields ใหม่ (ชื่อ, ลายเซ็น, ตรา)
- [ ] ✅ Upload รูปได้ + preview ไม่บีบ
- [ ] ✅ Certificate PDF ดึงข้อมูลจาก tenant
- [ ] ✅ ลายเซ็น + ตรา แสดงใน PDF (preserve aspect ratio)
- [ ] ✅ Build ผ่าน + ทดสอบ E2E
