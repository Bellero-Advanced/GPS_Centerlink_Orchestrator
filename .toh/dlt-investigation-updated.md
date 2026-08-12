# DLT Investigation — 3 คันที่ส่งไม่ติด vs คันที่ติด

**Created:** 2026-08-12 20:00
**Goal:** เปรียบเทียบรถที่ส่งไม่ติด (70-4440, 70-7170, 70-7ุภ/) กับรถที่ติด

---

## ✅ ข้อสรุปจาก DLT Official Spec

**จาก PDF (Page 18-19):**

### unit_id Field
- **Type:** Text (27)
- **Format:** หลัก 1-7 = gps_model_id, หลัก 8-27 = หมายเลขเครื่อง
- **ตัวอย่าง:**
  ```
  "000000LP-GPS-X2-0001"           (มีขีด + ตัวอักษร)
  "0010001000000LP-GPS-X2-0001"    (มีขีด + ตัวอักษร)
  "0230034000000000000000000131"   (ตัวเลขล้วน) ✓
  ```

**ข้อสรุป:** unit_id สามารถเป็นตัวเลขล้วนได้! ไม่มีข้อกำหนดว่าต้องมี A-Z

---

## 🔍 Root Cause ที่เป็นไปได้ (ใหม่)

### ❌ ~~License ต้องมีตัวอักษร~~ (ยกเลิก)
Spec ไม่ได้บอกแบบนั้น — unit_id ตัวเลขล้วนใช้ได้

### ✅ สาเหตุที่เป็นไปได้:

#### 1. Masterfile ไม่ sync (น่าจะเป็นนี่!)
- รถที่ติด: Masterfile มี unit_id + license ตรงกับที่ส่งไป
- รถที่ไม่ติด: Masterfile อาจเป็น format เก่า หรือยังไม่ลงทะเบียน

#### 2. GPS Model ID ผิดหรือขาด
- รถที่ติด: `device.attributes.gpsModelId` = "052xxxx" (7 digits)
- รถที่ไม่ติด: gpsModelId = undefined → fallback = "0520000" → unit_id ผิด

#### 3. Device ไม่ได้เปิด dltEnabled
- รถที่ติด: `device.attributes.dltEnabled = true`
- รถที่ไม่ติด: dltEnabled = false → ไม่ส่ง DLT เลย

#### 4. Position data stale (เก่าเกิน 10 นาที)
- DLT reject position ที่เก่าเกิน 10 นาที
- รถที่ไม่ติด: position.fixTime อาจเก่ามาก → isLocationFresh = false → skip

---

## 📋 Investigation Checklist

### สิ่งที่ต้องเช็คสำหรับ 3 คัน:

```typescript
// 70-4440 หนองคาย
{
  device: {
    id: ???,
    name: "70-4440 หนองคาย",
    uniqueId: ??? (IMEI),
    contact: "70-4440 หนองคาย",
    attributes: {
      dltEnabled: ???,           // ต้อง = true
      gpsModelId: ???,           // ต้องมีค่า 7 digits
      driverLicenseNo: ???,      // อาจไม่มีก็ได้
    }
  },
  position: {
    fixTime: ???,                // ต้องไม่เก่าเกิน 10 นาที
    latitude: ???,
    longitude: ???,
    speed: ???,
    attributes: {
      ignition: ???,
    }
  },
  dlt: {
    unitId: buildDltUnitId(device, venderId),  // ต้องมี 27 chars
    license: buildDltLicense(device, venderId), // ต้องมี 80 chars
    warnings: validateDltLocation(loc),         // ต้อง = []
  }
}
```

### เปรียบเทียบกับรถที่ติด 1 คัน:

```typescript
// เช่น รถที่ติด (ทะเบียนมีตัวอักษร)
{
  device: {
    name: "กข 1234 กรุงเทพ",
    contact: "กข 1234",
    attributes: {
      dltEnabled: true ✓,
      gpsModelId: "0520003" ✓,
    }
  },
  dlt: {
    unitId: "052000300000359857082980301" (27) ✓,
    license: "052000300000359857082980301..." (80) ✓,
    warnings: [] ✓,
  }
}
```

---

## 🎯 Action Plan

### Phase 1: Query Real Data (5 min)

ต้องเข้า Traccar API จริงหรือเปิด DLT Page แล้วดู console logs:

```bash
# Option A: API Query (ถ้า API accessible)
curl -u "username:password" https://api.gps.bellerox.com/api/devices \
  | jq '.[] | select(.contact | contains("70-4440"))'

# Option B: Browser Console (ใน DLT Page)
# เปิด DevTools → Console → หา device object
# filter: vehicle.name.includes("70-4440")
```

### Phase 2: Compare & Diagnose (5 min)

เทียบ 3 fields:
1. `dltEnabled` — true/false?
2. `gpsModelId` — มี 7 digits หรือไม่?
3. `position.fixTime` — fresh (< 10 min) หรือไม่?

### Phase 3: Fix (10 min)

**ถ้า dltEnabled = false:**
- เปิดใน Fleet Page → Edit device → เปิด DLT toggle

**ถ้า gpsModelId ขาด:**
- เปิด DLT Page → GPS Models section → เพิ่ม/แก้ gpsModelId

**ถ้า Masterfile ไม่ sync:**
- DLT Page → กดปุ่ม "ซิงค์ Masterfile" ทั้ง 3 คัน

---

## 🤔 คำถามถัดไป

**พี่โต:** รถอื่นที่ติดอยู่ — ทะเบียนเป็นอะไร?
- ถ้าเป็น "กข 1234" (มีตัวอักษรไทย) → sanitize เป็น Latin
- ถ้าเป็น "80-1234" (ตัวเลขล้วนเหมือนกัน) → แต่ทำไมติด? 🤔

**สมมติฐาน:**
- รถที่ติด = Masterfile ซิงค์แล้ว ✓
- รถที่ไม่ติด = Masterfile ยังไม่ซิงค์ ❌

---

**Status:** Waiting for real device data to confirm
**Next:** ขอ device data ของ 3 คัน + 1 คันที่ติด
