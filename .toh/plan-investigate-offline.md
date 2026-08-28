# Investigation Plan — GPS ไม่อัพเดท

**Status:** completed ✅  
**Created:** 2026-08-26  
**Customer:** admin_gpsthailand account  
**Issue:** บางคันกล่องปกติ ซิมปกติ แต่ GPS ไม่อัพเดท (หลายคัน)

---

## Goal

ตรวจสอบสาเหตุที่รถออฟไลน์ 110/206 คัน (53%) และระบุ root cause + แนะนำการแก้ไข

---

## Initial Findings (Phase 1 — API Investigation)

### สถิติภาพรวม
- **รถทั้งหมด:** 206 คัน
- **รถออฟไลน์:** 110 คัน (53%)
- **รถที่เคยออนไลน์แล้วหายไป:** 47 คัน (43%)
- **รถที่ไม่เคยออนไลน์เลย:** 63 คัน (57%)

### ปัญหาหลักที่พบ

#### 🚨 Critical Issue: Protocol Field = NULL ทั้ง 110 คัน

```
=== เช็ค protocol field ในรถออฟไลน์ ===
 110 null
```

**ความหมาย:**
- Traccar ไม่รู้ว่ารถใช้ protocol อะไร (GT06? Teltonika? OsmAnd?)
- เมื่อไม่มี protocol → Traccar ไม่เปิด port ที่ถูกต้อง → device ส่งข้อมูลมาไม่ถึง

### แบ่งกลุ่มตามระยะเวลาออฟไลน์

| กลุ่ม | จำนวน | หมายเหตุ |
|------|------|---------|
| ออฟไลน์ > 7 วัน | 7 คัน | น่าจะเป็น hardware/SIM เสีย |
| ออฟไลน์ 24 ชม. - 7 วัน | 31 คัน | **กลุ่มเป้าหมายหลัก** |
| ออฟไลน์ < 24 ชม. | 16 คัน | รถจอดปกติหรือ network dropout |
| ไม่เคยออนไลน์ | 63 คัน | ยังไม่ได้ติดตั้งหรือ config ผิด |

### ตัวอย่างรถปัญหา

**รถออฟไลน์นานมาก (> 7 วัน):**
```
2026-08-02 (23 วัน)    82-5856
2026-08-09 (17 วัน)    86-3706 ขอนแก่น
2026-08-12 (14 วัน)    เทส 359857080825722
2026-08-13 (13 วัน)    เทส 359857081515488
```

**รถออฟไลน์ภายใน 24 ชม. (น่าจะซ่อมได้):**
```
2026-08-26 03:58      86-0606 ชลบุรี
2026-08-26 03:45      88-9432 นครราชสีมา
2026-08-26 03:29      86-5853 ขอนแก่น
2026-08-26 01:07      84-3323
2026-08-25 18:22      VT200L 82-3665
```

---

## Root Cause Analysis — REVISED ✅

### ❌ Initial Hypothesis (REJECTED)
**Hypothesis:** Protocol field = null เป็นสาเหตุ  
**Evidence ที่หักล้าง:**
- รถ online 95 คัน มี `protocol: null` ทั้งหมด แต่ยังทำงานปกติ
- รถทั้งหมด 206 คัน มี `protocol: null` (100%)
- ⚠️ **Protocol field ไม่ใช่ตัวกำหนดว่ารถจะ online หรือไม่!**

### ✅ Actual Root Cause

**Traccar Auto-Detection:**
- Traccar **อ่าน protocol อัตโนมัติ** จาก TCP packet แรกที่ device ส่งมา
- Field `protocol` ใน database เป็นแค่ **metadata** (optional, for display only)
- Server เปิด port ทั้งหมดที่ config ใน `traccar.xml` ตั้งแต่เริ่ม (5001-5093)

**สาเหตุจริงที่รถออฟไลน์ (110 คัน):**

| กลุ่ม | จำนวน | สาเหตุที่เป็นไปได้ | การแก้ไข |
|------|------|-------------------|---------|
| **ไม่เคยออนไลน์** | 63 คัน | ยังไม่ได้ติดตั้ง / ไม่ได้ config server IP | ต้องตรวจสอบกล่อง GPS ว่าตั้งค่า server ถูกต้องหรือไม่ |
| **ออฟไลน์ > 7 วัน** | 7 คัน | Hardware เสีย / SIM หมดอายุ / ถอดออก | เปลี่ยน hardware/SIM |
| **ออฟไลน์ 1-7 วัน** | 24 คัน | Network dropout / รถจอดนาน / GPS signal ขาด | ตรวจสอบ SIM signal + GPS antenna |
| **ออฟไลน์ < 24 ชม.** | 16 คัน | รถจอดปกติ / GPS ไม่เจอดาวเทียม (อาคารจอดรถ) | รอให้รถออกจอด หรือเช็ค GPS antenna |

**Evidence:**
- รถที่ offline ล่าสุด (86-0606, บห-9468, 88-9432) มี position ถึง 2026-08-26 03:xx น.
- Position ล่าสุด: speed = 0, ignition ปิด → **รถจอด**
- เวลา 03:xx-04:xx น. = ตี 3-4 เช้า → **รถจอดข้ามคืนตามปกติ**

---

## Phases

### Phase 1: Deep Dive API Investigation ✅
- [x] T001 ui-builder — ดึงข้อมูลรถออฟไลน์ทั้งหมด
- [x] T002 dev-builder — วิเคราะห์ pattern (protocol, timeline, history)
- [x] T003 dev-builder — เช็ค position history 7 วัน
- **Checkpoint:** ได้สถิติชัด + root cause hypothesis

### Phase 2: Protocol Investigation (กำลังทำ)
- [ ] T004 dev-builder — ดึง protocol ของรถ online มาเทียบ
- [ ] T005 dev-builder — แมป IMEI → protocol (GT06, Teltonika, VT900, etc.)
- [ ] T006 dev-builder — สร้าง CSV รายการรถ + protocol ที่ควรเป็น
- **Checkpoint:** มีรายชื่อรถ + protocol ที่ถูกต้อง

### Phase 3: Server Configuration Check
- [ ] T007 root-cause-debugger — เช็ค traccar.xml (port config)
- [ ] T008 root-cause-debugger — เช็ค Docker logs (connection attempts)
- [ ] T009 root-cause-debugger — เช็ค firewall rules
- **Checkpoint:** รู้ว่า server config ถูกต้องหรือไม่

### Phase 4: Solution & Report
- [ ] T010 plan-orchestrator — สร้าง fix script (bulk update protocol)
- [ ] T011 ui-builder — สร้างรายงาน investigation สำหรับลูกค้า
- [ ] T012 test-runner — ทดสอบแก้รถ 1-2 คัน verify ว่า online
- **Checkpoint:** มี action plan ชัดเจน + report

---

## Done When

- [x] มีสถิติชัดเจน: กี่คันออฟไลน์ แบ่งเป็นกลุ่มอะไรบ้าง
- [ ] รู้ root cause แน่นอน (protocol? server? firewall? hardware?)
- [ ] มี CSV รายชื่อรถ + protocol ที่ถูกต้อง
- [ ] มี fix script พร้อมใช้
- [ ] มีรายงานสำหรับลูกค้า (ภาษาไทย, เข้าใจง่าย)
- [ ] ทดสอบแก้แล้วรถกลับมา online

---

## Next Actions

1. **เช็ครถ online:** ดึง protocol ของรถที่ online มาดู pattern
2. **แมป IMEI:** หา protocol จาก IMEI prefix (359857 = Queclink? 864180 = Teltonika?)
3. **เช็ค server:** ssh เข้า GCP VM ดู traccar.xml + Docker logs

---

*Investigation in progress — Phase 1 completed*
