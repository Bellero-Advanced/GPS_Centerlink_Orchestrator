# แผนแก้ Timezone — Per-Device Precision Fix

**สถานะ:** approved  
**สร้างเมื่อ:** 2026-08-29T16:30:00+07:00  
**เวอร์ชัน:** 1.0

---

## 🎯 เป้าหมาย

แก้เวลาผิด +7 ชม. ใน reports โดยตั้ง `decoder.timezone` แบบ **per-device**

**หลักการ:** แก้เฉพาะ device ที่เวลาผิด ไม่แตะ device ที่ถูกอยู่แล้ว

---

## 🔬 วิเคราะห์ต้นเหตุ (จาก memory)

### ข้อมูลจาก timezone-7h-offset-root-cause.md:

**Device แยกตาม protocol:**
| Protocol | Offset | Devices | แก้ได้ไหม |
|----------|--------|---------|-----------|
| gps103 | 0.00 ✅ | 11 | ถูกแล้ว |
| startek | 0.00 ✅ | 2 | ถูกแล้ว |
| **gt06** | **+7.00 ❌** | 61 | ✅ `decoder.timezone` |
| **meitrack** | **+7.00 ❌** | 2 | ❌ decoder ไม่รองรับ |
| **meiligao** | **-7.97~0** | 3 | ❌ decoder ไม่รองรับ · ค่ากระจาย |

**ข้อมูลเก่าที่ยังเพี้ยน:**
- `tc_positions`: 74,816 rows
- `tc_events`: 2,701 rows
- ID range: 3260680 ถึง 3335495
- Offset: +7.00 ชม.เป๊ะ

---

## 📋 Done When

- [ ] ดึงรายชื่อ devices แยกตาม protocol และ offset
- [ ] ตั้ง `decoder.timezone: -07:00` ให้ GT06 devices (61 คัน)
- [ ] ไม่แตะ gps103/startek (13 คัน) เพราะถูกอยู่แล้ว
- [ ] Verify ด้วยข้อมูลใหม่ — เวลาถูกต้อง
- [ ] Backfill ข้อมูลเก่า 74k rows (optional — ถามพี่โตอีกรอบ)

---

## 📐 Stack & Tools

- **Traccar Admin API:** `/api/devices` + `/api/devices/{id}`
- **Database:** PostgreSQL `tc_positions`, `tc_events`
- **Script:** Node.js หรือ bash + curl
- **Test:** curl + manual verification

---

## 🏗️ Phases

### Phase 1: Survey (สำรวจ devices จริง)

- **T001** `test-runner` — List all devices with protocol
  - Action: `curl /api/devices` → แยกตาม protocol
  - Success: ได้ CSV: deviceId, name, protocol, current_offset

- **T002** `test-runner` — Measure current offset per device
  - Action: ดึง position ล่าสุดของแต่ละคัน → คำนวณ offset
  - Success: รู้ว่าคันไหนผิด คันไหนถูก

**Checkpoint:** มี list ชัดเจนว่าต้องแก้กี่คัน

---

### Phase 2: Fix GT06 Devices (61 คัน)

- **T003** `dev-builder` — Create fix script
  - File: `scripts/fix-gt06-timezone.js`
  - Action: Loop GT06 devices → PUT `/api/devices/{id}` with `attributes.decoder.timezone: -07:00`
  - Success: Script พร้อมรัน

- **T004** `test-runner` — Dry-run (test 1 device)
  - Action: รันกับ 1 คันทดสอบ → ตรวจว่า attribute ติด
  - Success: Attribute ติดใน Traccar admin

**Checkpoint:** Script ทำงาน attribute ติดแล้ว

---

### Phase 3: Apply to All GT06 (Production)

- **T005** `test-runner` — Apply to all 61 GT06 devices
  - Action: รัน script ทั้ง 61 คัน
  - Success: ทุกคันมี `decoder.timezone: -07:00`

- **T006** `test-runner` — Restart Traccar container (optional)
  - Action: `docker restart bellerox-traccar` (ถ้า attribute ไม่มีผลทันที)
  - Success: Traccar รับ config ใหม่

**Checkpoint:** GT06 devices ทั้งหมดมี attribute แล้ว

---

### Phase 4: Verification (ทดสอบข้อมูลใหม่)

- **T007** `test-runner` — Wait for new GPS data (5-10 min)
  - Action: รอ device ส่ง position ใหม่เข้ามา
  - Success: มี position ใหม่หลัง apply attribute

- **T008** `test-runner` — Verify new position time
  - Action: ดึง position ล่าสุด → เช็คเวลาว่าเป็น UTC แล้ว
  - Success: เวลาถูก (ไม่มี +7 offset)

- **T009** `test-runner` — Check reports display
  - Action: เปิด ReportsPage → เลือก GT06 device → ดูเวลา
  - Success: เวลาแสดงถูกต้อง

**Checkpoint:** ข้อมูลใหม่ถูกต้อง 100%

---

### Phase 5: Backfill Old Data (Optional)

⚠️ **รอ approval จากพี่โต** — แก้ 74k rows ใช้เวลา 5-10 นาที

- **T010** `dev-builder` — Create backfill SQL
  - File: `scripts/backfill-timezone.sql`
  - Action: `UPDATE tc_positions SET fixtime = fixtime - INTERVAL '7 hours' WHERE id BETWEEN 3260680 AND 3335495`
  - Success: SQL พร้อมรัน

- **T011** `test-runner` — Backup before backfill
  - Action: `pg_dump tc_positions > backup-before-backfill.sql`
  - Success: Backup เสร็จ

- **T012** `test-runner` — Run backfill (production database)
  - Action: รัน SQL → update 74k rows
  - Success: Query complete, rows updated

**Checkpoint:** ข้อมูลเก่าถูกต้องแล้ว

---

## 📊 Execution Strategy

- **Total tasks:** 12 (Phase 5 optional)
- **Parallel:** T001 + T002 (survey)
- **Sequential:** Phase 2-4
- **Phase 5:** รอ approval
- **Estimated time:** 
  - Without backfill: ~30 นาที
  - With backfill: ~40 นาที

---

## 🚨 Risks

1. **Meitrack/Meiligao ยังแก้ไม่ได้** — decoder ไม่รองรับ `decoder.timezone`
   - Workaround: Backfill เฉพาะข้อมูลเก่า (one-time fix)
   
2. **Backfill อาจใช้เวลานาน** — 74k rows
   - Mitigation: รันใน off-peak hours (02:00-04:00)
   
3. **Attribute อาจไม่มีผลทันที** — ต้อง restart Traccar
   - Mitigation: Restart container หรือรอ GPS ส่งข้อมูลใหม่

---

## 📌 Next After Done

1. Monitor GT06 devices — ดูว่าเวลาถูกต้อง
2. แก้ Meitrack/Meiligao (ต้องใช้ global config หรือ firmware update)
3. ตั้ง alert เมื่อเจอเวลาอนาคต (>1 hour ahead)
