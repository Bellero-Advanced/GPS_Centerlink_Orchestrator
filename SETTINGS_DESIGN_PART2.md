# Settings System Design — Part 2
# จัดการทรัพย์สิน (Asset/Vehicle Management)

## 3️⃣ จัดการทรัพย์สิน (Asset Management)

### 3.1 จัดการทรัพย์สิน (Vehicle CRUD)

**Purpose:** เพิ่ม/แก้ไข/ลบ ยานพาหนะในระบบ

**Data Schema:**
```typescript
interface Vehicle {
  id: number;
  name: string;              // ชื่อรถ (required)
  uniqueId: string;          // IMEI (required, unique)
  licensePlate?: string;     // ป้ายทะเบียน
  vehicleType?: string;      // ประเภท: รถบรรทุก, รถตู้, รถเก๋ง, มอเตอร์ไซค์
  brand?: string;            // ยี่ห้อ: Isuzu, Toyota, Honda
  model?: string;            // รุ่น
  year?: number;             // ปี พ.ศ.
  color?: string;            // สี
  
  groupId?: number;          // กลุ่มหลัก
  subGroupId?: number;       // กลุ่มย่อย
  speedGroupId?: number;     // กลุ่มความเร็ว
  
  // GPS Device Info
  deviceModel?: string;      // รุ่นอุปกรณ์ GPS
  simNumber?: string;        // เลขซิม
  installDate?: Date;        // วันติดตั้ง
  
  // Vehicle Details
  vin?: string;              // เลขตัวถัง
  engineNumber?: string;     // เลขเครื่องยนต์
  fuelType?: 'gasoline' | 'diesel' | 'lpg' | 'ev';
  fuelCapacity?: number;     // ความจุถัง (ลิตร)
  
  // Maintenance
  lastService?: Date;        // ซ่อมบำรุงล่าสุด
  nextService?: Date;        // ครั้งถัดไป
  odometer?: number;         // เลขไมล์ปัจจุบัน (km)
  
  // Insurance & Tax
  insuranceExpiry?: Date;    // ประกันหมดอายุ
  taxExpiry?: Date;          // ภาษีหมดอายุ
  
  status: 'active' | 'inactive' | 'maintenance';
  notes?: string;            // หมายเหตุ
}
```

**UI - Vehicle List Page:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: จัดการทรัพย์สิน (ยานพาหนะ)             │
│   [+ เพิ่มยานพาหนะ] [Import CSV] [Export]          │
└─────────────────────────────────────────────────────┘

[Search: ค้นหาชื่อ, ป้ายทะเบียน, IMEI]
[Filter: กลุ่ม ▼] [สถานะ ▼]

┌─────────────────────────────────────────────────────┐
│ Vehicle Table (sticky header)                       │
│                                                      │
│ ชื่อ         ป้ายทะเบียน  IMEI        กลุ่ม  สถานะ│
│ ────────────────────────────────────────────────────│
│ รถ-001       กข 1234     123456...   A     [●]     │
│ [แก้ไข] [ลบ]                                       │
│                                                      │
│ รถบรรทุก 10ล้อ  นข 5678  789012...   B     [●]     │
│ [แก้ไข] [ลบ]                                       │
│                                                      │
└─────────────────────────────────────────────────────┘

[Pagination: 1 2 3 ... 10]  Total: 247 vehicles
```

**Add/Edit Modal (Multi-tab form):**
```
┌─────────────────────────────────────────────────────┐
│ Modal: เพิ่มยานพาหนะใหม่                            │
│                                                      │
│ [ข้อมูลพื้นฐาน] [อุปกรณ์ GPS] [เอกสาร] [บำรุงรักษา]│
│                                                      │
│ Tab 1: ข้อมูลพื้นฐาน                                │
│                                                      │
│   ชื่อยานพาหนะ *                                    │
│   [___________________________________]             │
│                                                      │
│   ป้ายทะเบียน                                        │
│   [__________] จังหวัด [___________]               │
│                                                      │
│   ประเภท                                             │
│   [รถบรรทุก            ▼]                          │
│                                                      │
│   ยี่ห้อ / รุ่น                                     │
│   [Isuzu     ▼]  [FTR 240           ▼]            │
│                                                      │
│   ปีที่ผลิต (พ.ศ.)                                 │
│   [2565      ▼]                                     │
│                                                      │
│   สี                                                 │
│   [ขาว        ▼]                                    │
│                                                      │
│   กลุ่ม / กลุ่มย่อย                                 │
│   [กลุ่ม A    ▼]  [ย่อย A1          ▼]            │
│                                                      │
│   กลุ่มความเร็ว                                     │
│   [รถบรรทุก - 90 km/h  ▼]                          │
│                                                      │
│   สถานะ                                              │
│   (•) ใช้งาน  ( ) ปิดใช้งาน  ( ) ซ่อมบำรุง       │
│                                                      │
│   [บันทึก] [ยกเลิก]                                │
└─────────────────────────────────────────────────────┘
```

**Validation:**
- name: required, 1-100 chars
- uniqueId (IMEI): required, 15 digits, unique
- licensePlate: optional, Thai format
- year: 2500-2600 (Buddhist Era)
- odometer: >= 0

---

### 3.2 จัดการกลุ่มสินทรัพย์ (Vehicle Groups)

**Purpose:** สร้างกลุ่มยานพาหนะเพื่อจัดระเบียบและ filter

**Data Schema:**
```typescript
interface VehicleGroup {
  id: number;
  name: string;              // ชื่อกลุ่ม (required, unique)
  description?: string;
  color?: string;            // สีแสดงบนแผนที่
  icon?: string;             // icon name
  parentId?: number;         // null = top-level group
  vehicleCount?: number;     // จำนวนรถในกลุ่ม (computed)
}
```

**UI - Tree Structure:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: จัดการกลุ่มยานพาหนะ                    │
│   [+ เพิ่มกลุ่มหลัก]                                │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Tree View                                            │
│                                                      │
│ ▼ กลุ่ม A (45 คัน)              [แก้ไข] [ลบ]      │
│   ├─ A1 - ขนส่งในเมือง (20)     [แก้ไข] [ลบ]      │
│   ├─ A2 - ขนส่งต่างจังหวัด (15) [แก้ไข] [ลบ]      │
│   └─ A3 - สำรอง (10)             [แก้ไข] [ลบ]      │
│                                                      │
│ ▼ กลุ่ม B (30 คัน)              [แก้ไข] [ลบ]      │
│   └─ B1 - VIP (30)               [แก้ไข] [ลบ]      │
│                                                      │
│ ▶ กลุ่ม C (12 คัน)              [แก้ไข] [ลบ]      │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

### 3.3 จัดการกลุ่มสินทรัพย์ย่อย (Sub-groups)

**Purpose:** กลุ่มย่อยภายใต้กลุ่มหลัก (เหมือน 3.2 แต่ level 2)

**Implementation:** Same as 3.2 but filtered by parentId

---

### 3.4 จัดการกลุ่มความเร็วสินทรัพย์ (Speed Groups)

**Purpose:** กำหนดความเร็วสูงสุดตามประเภทรถ

**Data Schema:**
```typescript
interface SpeedGroup {
  id: number;
  name: string;              // รถบรรทุก, รถตู้, มอเตอร์ไซค์
  maxSpeed: number;          // km/h
  description?: string;
  color?: string;            // สีแจ้งเตือนบนแผนที่
}
```

**UI:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: จัดการกลุ่มความเร็ว                    │
│   [+ เพิ่มกลุ่มความเร็ว]                            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Speed Group Cards                                    │
│                                                      │
│ ┌────────────────────────────────────────────┐     │
│ │ รถบรรทุก 10 ล้อ                            │     │
│ │ ความเร็วสูงสุด: 90 km/h                   │     │
│ │ จำนวนรถ: 45 คัน                            │     │
│ │ [แก้ไข] [ลบ]                               │     │
│ └────────────────────────────────────────────┘     │
│                                                      │
│ ┌────────────────────────────────────────────┐     │
│ │ รถตู้ผู้โดยสาร                             │     │
│ │ ความเร็วสูงสุด: 100 km/h                  │     │
│ │ จำนวนรถ: 12 คัน                            │     │
│ │ [แก้ไข] [ลบ]                               │     │
│ └────────────────────────────────────────────┘     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

### 3.5 จัดการบำรุงรักษา (Maintenance Management)

**Purpose:** บันทึกและติดตามการซ่อมบำรุง

**Data Schema:**
```typescript
interface MaintenanceRecord {
  id: number;
  vehicleId: number;
  type: 'routine' | 'repair' | 'inspection' | 'tire' | 'oil' | 'battery' | 'other';
  date: Date;                // วันที่ทำ
  odometer: number;          // เลขไมล์
  description: string;
  cost: number;              // ค่าใช้จ่าย (THB)
  garage?: string;           // ชื่ออู่
  technician?: string;       // ช่างผู้ทำ
  nextDueOdometer?: number;  // ไมล์ครั้งถัดไป
  nextDueDate?: Date;        // วันครั้งถัดไป
  attachments?: string[];    // URLs ของใบเสร็จ/รูปภาพ
  notes?: string;
}
```

**UI:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: จัดการบำรุงรักษา                       │
│   [+ บันทึกการซ่อมบำรุง]                            │
└─────────────────────────────────────────────────────┘

[Filter: ยานพาหนะ ▼] [ประเภท ▼] [ช่วงเวลา: __/__]

┌─────────────────────────────────────────────────────┐
│ Maintenance Records Table                            │
│                                                      │
│ วันที่    รถ     ประเภท      ค่าใช้จ่าย  ครั้งถัดไป│
│ ─────────────────────────────────────────────────── │
│ 1/7/69   รถ-001  เปลี่ยนถ่ายน้ำมัน  ฿1,200  1/10/69│
│ [ดูรายละเอียด] [แก้ไข] [ลบ]                        │
│                                                      │
│ 25/6/69  รถ-002  ตรวจสภาพประจำปี   ฿3,500  25/6/70 │
│ [ดูรายละเอียด] [แก้ไข] [ลบ]                        │
│                                                      │
└─────────────────────────────────────────────────────┘
```

