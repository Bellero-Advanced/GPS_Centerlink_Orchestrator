# DLT Diagnosis — 3 คันที่ส่งไม่ติด

**Created:** 2026-08-12 19:30
**Vehicles:** 70-4440 หนองคาย, 70-7170 ราชบุรี, 70-7ุภ/ ราชบุรี

---

## 🔍 Root Cause พบแล้ว

### ปัญหา: ทะเบียนรถเป็นตัวเลขล้วน + สั้นเกินไป

```javascript
Vehicle: "70-4440 หนองคาย"
  Sanitized: "704440" (6 chars)
  Has alphabet: ✗
  Length: 6 (ต้องการ >= 15)
  → DLT reject: license ต้องมี A-Z อย่างน้อย 1 ตัว

Vehicle: "70-7170 ราชบุรี"
  Sanitized: "707170" (6 chars)
  Has alphabet: ✗
  Length: 6
  → DLT reject: license ต้องมี A-Z อย่างน้อย 1 ตัว

Vehicle: "70-7ุภ/ ราชบุรี"
  Sanitized: "707" (3 chars)
  Has alphabet: ✗
  Length: 3
  → DLT reject: license ต้องมี A-Z อย่างน้อย 1 ตัว
```

---

## 🧪 Code Analysis

### buildDltPreview Priority (dltService.ts:444-449)

```typescript
if      (s((device.contact ?? '').trim())) licenseSource = `contact: "${device.contact}"`;
else if (s(device.name))                   licenseSource = `name: "${device.name}"`;
else if (s(chassisNo))                     licenseSource = `chassisNo: "${chassisNo}"`;
else if (s(device.uniqueId))               licenseSource = `uniqueId: "${device.uniqueId}"`;
else                                       licenseSource = `device.id: ${device.id} (fallback)`;
```

**Priority 1:** `device.contact` (ทะเบียนรถ)
- 3 คันนี้ contact = ทะเบียนที่เป็นตัวเลขล้วน
- Sanitize แล้ว = ไม่มี A-Z → **ไม่ผ่าน DLT validation** ❌

---

## 💡 Solution Strategy

### Option A: เพิ่ม prefix "V" หน้า contact เสมอ ✅ (Recommended)

```typescript
// Before:
const license = unitId.padEnd(80, '0');  // ตัวเลขล้วน

// After:
let licenseBase: string;
if (device.contact && sanitize(device.contact)) {
  // เพิ่ม "V" prefix เพื่อให้มี alphabet
  licenseBase = 'V' + sanitize(device.contact);
} else if (device.name && sanitize(device.name)) {
  licenseBase = sanitize(device.name);
} else {
  // fallback: unit_id with prefix
  licenseBase = 'V' + buildDltUnitId(device, venderId);
}

const license = licenseBase.padEnd(80, '0');
```

**Result:**
```
70-4440 → "V704440" (มี V แล้ว) ✓
70-7170 → "V707170" (มี V แล้ว) ✓
70-7ุภ/ → "V707" (มี V แล้ว) ✓
```

**Pros:**
- ง่ายที่สุด
- ใช้ได้กับทุกกรณี (ไม่ว่าทะเบียนจะเป็นอะไร)
- Backward compatible (รถที่ติดอยู่ยังติดอยู่)

**Cons:**
- Masterfile ต้องซิงค์ใหม่ทั้งหมด

---

### Option B: ตรวจว่า contact มี A-Z หรือไม่ → ถ้าไม่มีใช้ unit_id

```typescript
const contactSanitized = sanitize(device.contact);
const hasAlpha = /[a-zA-Z]/.test(contactSanitized);

let licenseBase: string;
if (hasAlpha && contactSanitized.length >= 6) {
  licenseBase = contactSanitized;
} else {
  // fallback: unit_id (มีตัวเลขอยู่แล้ว → เพิ่ม V prefix)
  licenseBase = 'V' + buildDltUnitId(device, venderId);
}

const license = licenseBase.padEnd(80, '0');
```

**Pros:**
- รถที่มีทะเบียนตัวอักษร (ส่วนใหญ่) ไม่ต้องซิงค์ Masterfile
- แค่ 3 คันนี้ซิงค์ใหม่

**Cons:**
- Logic ซับซ้อนกว่า

---

## 🎯 Recommendation

**ใช้ Option A** — เพิ่ม "V" prefix หน้าทุก contact/unit_id

**เหตุผล:**
1. ง่าย ชัดเจน ไม่มี edge cases
2. ทำงานได้กับทุกกรณี (ตัวเลขล้วน, มีตัวอักษร, สั้น, ยาว)
3. "V" = "Vehicle" → มีความหมาย
4. Masterfile sync ครั้งเดียว → แก้ปัญหาถาวร

---

## 📋 Next Steps

### 1. แก้ Code (10 min)

**File:** `src/services/dltService.ts`

แก้ function `mapToLocation` (line 365-369):

```typescript
// BEFORE:
const unitId = buildDltUnitId(device, venderId);
const license = unitId.padEnd(80, '0');  // ตัวเลขล้วน ❌

// AFTER:
const unitId = buildDltUnitId(device, venderId);
// เพิ่ม "V" prefix เพื่อให้มี alphabet (DLT requirement)
const licenseBase = 'V' + unitId;
const license = licenseBase.padEnd(80, '0');  // "V052000..." (28 + 52 zeros) ✓
```

### 2. Sync Masterfile (5 min)

**ทุกคันที่ dltEnabled=true ต้องซิงค์:**
- เปิด DLT Page
- กดปุ่ม "ซิงค์ Masterfile ทั้งหมด"
- รอจนเสร็จ (15-16 คัน ~ 2-3 นาที)

### 3. ทดสอบ (5 min)

- ส่ง DLT ใหม่ (auto-send หรือกด "ส่งทันที")
- รอ 2-3 นาที
- เช็ค DLT Portal → ควรเห็น 3 คันนี้ขึ้นสีเขียว ✓

---

## ✅ Expected Result

**หลังแก้:**

```javascript
// Console log
[DLT DEBUG sendDltBatch] {
  vender_id: 52,
  locations_count: 16,  // ครบ 16 คันแล้ว
  locations: [
    {
      unit_id: "052000300000359857082980301",
      license: "V052000300000359857082980301000...",  // มี "V" ✓
      license_length: 80,
      // ... 70-4440 หนองคาย
    },
    {
      unit_id: "052000300000359857082980302",
      license: "V052000300000359857082980302000...",  // มี "V" ✓
      // ... 70-7170 ราชบุรี
    },
    {
      unit_id: "052000300000359857082980303",
      license: "V052000300000359857082980303000...",  // มี "V" ✓
      // ... 70-7ุภ/ ราชบุรี
    }
    // ... 13 คันอื่น ✓
  ]
}

// Response:
{ code: 1, received_records: 16, message: "success" }
```

**DLT Portal:** รถทั้ง 16 คันขึ้นสีเขียว ✓

---

**Status:** Diagnosis complete — Ready to fix
**Estimated fix time:** 20 minutes total
