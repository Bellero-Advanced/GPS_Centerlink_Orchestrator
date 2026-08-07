# Settings System Design — Bellerox GPS v2.0.0
# ระบบตั้งค่าครบถ้วน — 7 หมวดหลัก

> **วิเคราะห์จากภาพ 2 ภาพ** — ออกแบบ UX/UI, Data Schema, Validation, CRUD Operations

---

## 📋 Overview — 7 Main Categories

จากภาพที่วิเคราะห์ พบเมนูตั้งค่า 7 หมวดหลัก:

1. **ข้อมูลผู้ใช้** (User Profile) — 3 sub-menus
2. **ตั้งค่า** (Settings) — 2 sub-menus  
3. **จัดการทรัพย์สิน** (Asset/Vehicle Management) — 5 sub-menus
4. **จัดการหางลาก** (Trailer Management) — 3 sub-menus
5. **จัดการคนขับรถ** (Driver Management) — 1 menu
6. **จัดการบัตร RFID** (RFID Card Management) — 1 menu
7. **จัดการ User** (User Management - admin only)

---

## 1️⃣ ข้อมูลผู้ใช้ (User Profile)

### 1.1 ข้อมูลผู้ใช้ (View Profile)

**Purpose:** แสดงข้อมูลโปรไฟล์ผู้ใช้ปัจจุบัน (read-only)

**Fields to Display:**
```typescript
interface UserProfile {
  id: number;
  email: string;              // อีเมล (ใช้ login)
  name: string;               // ชื่อ-นามสกุล
  phone?: string;             // เบอร์โทร
  company?: string;           // บริษัท/องค์กร
  role: 'admin' | 'manager' | 'operator' | 'viewer';
  createdAt: Date;            // วันที่สร้างบัญชี
  lastLogin?: Date;           // เข้าใช้งานล่าสุด
  avatar?: string;            // รูปโปรไฟล์ (URL)
  timezone: string;           // เขตเวลา (default: Asia/Bangkok)
  language: 'th' | 'en';      // ภาษา
}
```

**UI Layout:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: ข้อมูลผู้ใช้                            │
│   [แก้ไขข้อมูล] button (navigate to 1.2)           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Profile Card (fill-block-elevated)                  │
│                                                      │
│   [Avatar (96x96)]  ชื่อ-นามสกุล                   │
│                     อีเมล                            │
│                     บทบาท (badge)                    │
│                                                      │
│   ─────────────────────────────────────────────────│
│   ข้อมูลติดต่อ                                      │
│   📱 เบอร์โทร: 0xx-xxx-xxxx                         │
│   🏢 บริษัท: Bellerox Co., Ltd.                    │
│                                                      │
│   ─────────────────────────────────────────────────│
│   การตั้งค่า                                        │
│   🌐 ภาษา: ไทย                                      │
│   ⏰ เขตเวลา: Asia/Bangkok (GMT+7)                 │
│                                                      │
│   ─────────────────────────────────────────────────│
│   สถิติการใช้งาน                                    │
│   📅 สร้างบัญชีเมื่อ: 15 ม.ค. 2569                │
│   🕒 เข้าใช้งานล่าสุด: 3 ก.ค. 2569 14:35          │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Action Buttons:**
- **แก้ไขข้อมูล** → navigate to 1.2
- **เปลี่ยนรหัสผ่าน** → navigate to 1.3

---

### 1.2 แก้ไขข้อมูลผู้ใช้ (Edit Profile)

**Purpose:** แก้ไขข้อมูลโปรไฟล์ (ยกเว้น email, role — เปลี่ยนได้เฉพาะ admin)

**Editable Fields:**
- ชื่อ-นามสกุล (required, 2-100 chars)
- เบอร์โทร (optional, Thai format: 0xx-xxx-xxxx)
- บริษัท/องค์กร (optional, 0-200 chars)
- รูปโปรไฟล์ (upload image, max 2MB, jpg/png)
- ภาษา (radio: ไทย / English)
- เขตเวลา (select dropdown)

**Form Layout:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: แก้ไขข้อมูลผู้ใช้                       │
│   [บันทึก] [ยกเลิก] buttons                        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Form Card                                            │
│                                                      │
│   รูปโปรไฟล์                                         │
│   [Avatar preview (96x96)]  [อัพโหลดรูป] button    │
│   <small>ขนาดไฟล์สูงสุด 2 MB (JPG, PNG)</small>    │
│                                                      │
│   ชื่อ-นามสกุล *                                    │
│   [___________________________________]             │
│                                                      │
│   เบอร์โทร                                           │
│   [___________________________________]             │
│   <small>รูปแบบ: 0xx-xxx-xxxx</small>              │
│                                                      │
│   บริษัท/องค์กร                                     │
│   [___________________________________]             │
│                                                      │
│   ภาษา *                                             │
│   ( ) ไทย  ( ) English                             │
│                                                      │
│   เขตเวลา *                                          │
│   [Asia/Bangkok (GMT+7)         ▼]                 │
│                                                      │
│   [บันทึกการเปลี่ยนแปลง] [ยกเลิก]                 │
└─────────────────────────────────────────────────────┘
```

**Validation Rules:**
- ชื่อ-นามสกุล: required, 2-100 chars, Thai/English/spaces only
- เบอร์โทร: optional, regex: `^0\d{1,2}-\d{3}-\d{4}$`
- บริษัท: 0-200 chars
- Avatar: max 2MB, mime: image/jpeg or image/png

**API:**
```typescript
PATCH /api/users/{userId}
Body: {
  name: string;
  phone?: string;
  company?: string;
  avatar?: string; // base64 or upload URL
  language: 'th' | 'en';
  timezone: string;
}
```

---

### 1.3 เปลี่ยนรหัสผ่าน (Change Password)

**Purpose:** เปลี่ยนรหัสผ่านผู้ใช้ปัจจุบัน

**Form Fields:**
- รหัสผ่านเดิม (required)
- รหัสผ่านใหม่ (required, min 8 chars)
- ยืนยันรหัสผ่านใหม่ (required, must match)

**UI Layout:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: เปลี่ยนรหัสผ่าน                         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Form Card (max-width: 480px, centered)              │
│                                                      │
│   รหัสผ่านเดิม *                                    │
│   [___________________________________] [👁 show]   │
│                                                      │
│   รหัสผ่านใหม่ *                                    │
│   [___________________________________] [👁 show]   │
│   <small>ความยาวอย่างน้อย 8 ตัวอักษร</small>      │
│                                                      │
│   ยืนยันรหัสผ่านใหม่ *                              │
│   [___________________________________] [👁 show]   │
│                                                      │
│   Password Strength Indicator:                      │
│   [████████░░] 80% (Strong)                         │
│   ✓ ความยาวอย่างน้อย 8 ตัว                         │
│   ✓ มีตัวอักษรพิมพ์ใหญ่และพิมพ์เล็ก               │
│   ✓ มีตัวเลข                                        │
│   ✗ มีอักขระพิเศษ (!@#$%...)                       │
│                                                      │
│   [เปลี่ยนรหัสผ่าน] [ยกเลิก]                       │
└─────────────────────────────────────────────────────┘
```

**Validation Rules:**
- รหัสผ่านเดิม: required, must match current password
- รหัสผ่านใหม่: min 8 chars, recommend: uppercase + lowercase + number + special
- ยืนยันรหัสผ่าน: must match รหัสผ่านใหม่
- รหัสผ่านใหม่ ≠ รหัสผ่านเดิม

**Password Strength:**
```typescript
function calculatePasswordStrength(pw: string): {
  score: number; // 0-100
  level: 'weak' | 'fair' | 'good' | 'strong';
  feedback: string[];
} {
  let score = 0;
  const feedback: string[] = [];
  
  if (pw.length >= 8) { score += 25; feedback.push('✓ ความยาวอย่างน้อย 8 ตัว'); }
  if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) { score += 25; feedback.push('✓ มีตัวพิมพ์ใหญ่และเล็ก'); }
  if (/\d/.test(pw)) { score += 25; feedback.push('✓ มีตัวเลข'); }
  if (/[^a-zA-Z0-9]/.test(pw)) { score += 25; feedback.push('✓ มีอักขระพิเศษ'); }
  
  const level = score >= 75 ? 'strong' : score >= 50 ? 'good' : score >= 25 ? 'fair' : 'weak';
  return { score, level, feedback };
}
```

**API:**
```typescript
POST /api/users/{userId}/change-password
Body: {
  oldPassword: string;
  newPassword: string;
}
Response: { success: boolean; message: string }
```

---

## 2️⃣ ตั้งค่า (Settings)

### 2.1 ตั้งค่ารายงานผ่านอีเมล (Email Report Settings)

**Purpose:** ตั้งค่าการส่งรายงานอัตโนมัติทางอีเมล (scheduled reports)

**Features:**
- เลือกประเภทรายงาน (trips, summary, fuel, alerts)
- เลือกความถี่ (daily, weekly, monthly)
- เลือกเวลาส่ง
- เลือกรายชื่อผู้รับ
- เลือกยานพาหนะ/กลุ่ม

**Data Schema:**
```typescript
interface EmailReportConfig {
  id: number;
  enabled: boolean;
  reportType: 'trips' | 'summary' | 'fuel' | 'alerts' | 'driver-score';
  frequency: 'daily' | 'weekly' | 'monthly';
  sendTime: string;           // HH:MM (24-hour format)
  dayOfWeek?: number;         // 0-6 (for weekly)
  dayOfMonth?: number;        // 1-31 (for monthly)
  recipients: string[];       // email addresses
  deviceIds?: number[];       // specific vehicles
  groupIds?: number[];        // or vehicle groups
  format: 'pdf' | 'csv' | 'excel';
  language: 'th' | 'en';
}
```

**UI Layout:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: ตั้งค่ารายงานผ่านอีเมล                 │
│   [+ เพิ่มรายงานอัตโนมัติ] button                  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ List of Scheduled Reports                           │
│                                                      │
│ ┌──────────────────────────────────────────────┐   │
│ │ [✓] รายงานการเดินทางรายวัน                   │   │
│ │     ส่งทุกวัน เวลา 08:00                      │   │
│ │     ถึง: admin@company.com, manager@...      │   │
│ │     [แก้ไข] [ลบ]                             │   │
│ └──────────────────────────────────────────────┘   │
│                                                      │
│ ┌──────────────────────────────────────────────┐   │
│ │ [✓] รายงานสรุปรายสัปดาห์                    │   │
│ │     ส่งทุกวันจันทร์ เวลา 09:00               │   │
│ │     ถึง: ceo@company.com                     │   │
│ │     [แก้ไข] [ลบ]                             │   │
│ └──────────────────────────────────────────────┘   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Add/Edit Modal:**
```
┌─────────────────────────────────────────────────────┐
│ Modal: เพิ่มรายงานอัตโนมัติ                         │
│                                                      │
│   ประเภทรายงาน *                                     │
│   [รายงานการเดินทาง         ▼]                     │
│                                                      │
│   ความถี่ *                                          │
│   ( ) รายวัน  (•) รายสัปดาห์  ( ) รายเดือน        │
│                                                      │
│   วันที่ส่ง (สำหรับรายสัปดาห์)                     │
│   [จันทร์                    ▼]                    │
│                                                      │
│   เวลาที่ส่ง *                                      │
│   [08] : [00]   <input type="time">                │
│                                                      │
│   ผู้รับอีเมล *                                     │
│   [admin@company.com          ] [+ เพิ่ม]          │
│   • admin@company.com [×]                           │
│   • manager@company.com [×]                         │
│                                                      │
│   ยานพาหนะ/กลุ่ม                                    │
│   [ทั้งหมด                    ▼]                    │
│                                                      │
│   รูปแบบไฟล์                                         │
│   (•) PDF  ( ) CSV  ( ) Excel                      │
│                                                      │
│   [บันทึก] [ยกเลิก]                                │
└─────────────────────────────────────────────────────┘
```

**Validation:**
- recipients: required, valid email format, max 10 recipients
- sendTime: 00:00 - 23:59
- dayOfWeek: 0-6 (0=Sunday)
- dayOfMonth: 1-31

---

### 2.2 ตั้งค่าการแจ้งเตือน Notify (Alert Notification Settings)

**Purpose:** ตั้งค่าการแจ้งเตือนผ่าน LINE Notify, Email, SMS

**Alert Types:**
- ความเร็วเกิน (overspeed)
- เข้า/ออก Geofence
- เครื่องยนต์ติด/ดับ (ignition on/off)
- จอดนานเกิน X นาที (long idle)
- ตัดสัญญาณ GPS (offline)
- แบตเตอรี่อ่อน
- การลาก (towing — เคลื่อนที่โดยเครื่องยนต์ดับ)

**Data Schema:**
```typescript
interface AlertConfig {
  id: number;
  enabled: boolean;
  alertType: 'overspeed' | 'geofence-enter' | 'geofence-exit' | 'ignition-on' | 'ignition-off' | 'long-idle' | 'offline' | 'low-battery' | 'towing';
  threshold?: number;         // speed limit (km/h) or idle time (minutes)
  deviceIds?: number[];       // specific vehicles
  groupIds?: number[];        // or vehicle groups
  geofenceIds?: number[];     // for geofence alerts
  
  // Notification channels
  notifyEmail: boolean;
  emailRecipients?: string[];
  
  notifyLine: boolean;
  lineToken?: string;         // LINE Notify token
  
  notifySms: boolean;
  smsRecipients?: string[];   // Thai phone numbers
  
  // Advanced
  cooldown: number;           // seconds before re-alerting (prevent spam)
  schedule?: {
    enabled: boolean;
    from: string;             // HH:MM
    to: string;               // HH:MM
    daysOfWeek: number[];     // 0-6
  };
}
```

**UI Layout:**
```
┌─────────────────────────────────────────────────────┐
│ PageHeader: ตั้งค่าการแจ้งเตือน                     │
│   [+ เพิ่มกฎการแจ้งเตือน] button                   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Alert Rules List (grouped by type)                  │
│                                                      │
│ ● ความเร็วเกิน (3 rules)                           │
│   ┌────────────────────────────────────────────┐   │
│   │ [✓] ความเร็วเกิน 90 km/h — ยานพาหนะทั้งหมด │   │
│   │     แจ้งผ่าน: LINE, Email                  │   │
│   │     [แก้ไข] [ลบ]                           │   │
│   └────────────────────────────────────────────┘   │
│                                                      │
│ ● Geofence (2 rules)                               │
│   ┌────────────────────────────────────────────┐   │
│   │ [✓] ออกจากโรงงาน — กลุ่มรถขนส่ง           │   │
│   │     แจ้งผ่าน: LINE                         │   │
│   │     [แก้ไข] [ลบ]                           │   │
│   └────────────────────────────────────────────┘   │
│                                                      │
│ ● เครื่องยนต์ (1 rule)                            │
│ ● การลาก (1 rule)                                 │
│                                                      │
└─────────────────────────────────────────────────────┘
```

