# DLT Log Checker — Task Brief

**Goal:** เช็ค browser console logs การส่ง DLT ล่าสุด (15-16 คัน) เพื่อหาสาเหตุที่ Portal ไม่แสดง

## วิธีเช็ค

1. **เปิด DLT Page ใน browser**
   - `http://localhost:5173` → login → DLT Page
   - เปิด DevTools Console (F12)

2. **หา Debug Logs**
   ```
   [DLT DEBUG sendDltBatch] Sending: { ... }
   ```
   
   เช็คค่าต่อไปนี้:
   - `vender_id`: ต้องตรงกับที่ลงทะเบียนกับ DLT
   - `locations_count`: 15-16 (จำนวนรถที่ส่ง)
   - `first_location.unit_id`: 27 digits (7 model + 5 zeros + 15 IMEI)
   - `first_location.license`: 80 digits (15 IMEI + 65 zeros)
   - `first_location.license_length`: ต้องเป็น 80
   - `first_location.engine_status`: 0 หรือ 1
   - `first_location.speed`: km/h (integer)

3. **เช็ค Response**
   ```
   received_records: 15-16 (ควรเท่ากับ locations_count)
   code: 1 (success)
   ```

## สาเหตุที่เป็นไปได้

### 1. license ไม่มีตัวอักษร (ตัวเลขล้วน)
- DLT ต้องการ license มี **อย่างน้อย 1 ตัวอักษร (A-Z)**
- IMEI เป็นตัวเลขล้วน → DLT reject
- **วิธีแก้:** เพิ่มตัวอักษรข้างหน้า IMEI

### 2. unit_id ไม่ตรงกับ Masterfile
- ส่ง unit_id ไปแต่ Masterfile ไม่รู้จัก
- **วิธีแก้:** เช็ค Masterfile ว่ามี unit_id นี้หรือยัง

### 3. license ไม่ตรงกับ Masterfile
- Masterfile ลงทะเบียนด้วย license เก่า (unit_id format)
- ส่งด้วย license ใหม่ (IMEI format)
- **วิธีแก้:** ซิงค์ Masterfile (ทำไปแล้วใน commit 0f260e9)

### 4. vender_id ไม่ตรงกับ unit_id
- unit_id ขึ้นต้นด้วย vendor_id (3 หลักแรกของ 7 model digits)
- ถ้า vendor_id = 52 → unit_id ควรขึ้นต้นด้วย 052xxxx...
- **วิธีแก้:** เช็คว่า gpsModelId ถูกต้องหรือไม่

## Expected Output

จาก logs ผมควรเห็น:
```javascript
{
  vender_id: 52,
  locations_count: 15,
  first_location: {
    unit_id: "0520001000008XXXXXXXXXXXXXXX", // 27 digits
    license: "8XXXXXXXXXXXXXXX0000...000",   // 80 digits (15 IMEI + 65 zeros)
    license_length: 80,
    utc_ts: "2026-08-11T10:30:45.000Z",
    lat: 13.756,
    lon: 100.501,
    speed: 45,
    engine_status: 1
  }
}

// Response:
{ code: 1, received_records: 15, message: "success" }
```

## Root Cause Hypothesis

จาก code ที่อ่าน license ตอนนี้คือ:
```typescript
const imei = device.uniqueId.replace(/\D/g, '').slice(0, 15).padStart(15, '0');
const license = imei.padEnd(80, '0');  // 15 IMEI + 65 zeros = 80 digits
```

**ปัญหา:** IMEI เป็นตัวเลขล้วน → DLT reject เพราะต้องการอย่างน้อย 1 ตัวอักษร!

**DLT Spec (line 422-425):**
```typescript
if (!/[a-zA-Z]/.test(loc.license)) {
  errs.push(`license เป็นตัวเลขล้วน — DLT ต้องการอย่างน้อย 1 ตัวอักษร (A-Z)`);
}
```

---

**Next Step:** เปิด browser console → copy logs มาวิเคราะห์
