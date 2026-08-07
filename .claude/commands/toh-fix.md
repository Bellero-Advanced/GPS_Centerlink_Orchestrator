---
command: /toh-fix
aliases: ["/toh-f"]
description: Evidence-first debugging — find the root cause with proof before touching code
trigger: /toh-fix or /toh-f followed by an error or problem
skills:
  - debug-protocol
  - error-handling
  - engineer-harness
---

# /toh-fix — Evidence-First Bug Fixing 🔧

```
/toh-fix [error or problem]
/toh-f  [error or problem]
```

## 🧭 IRON RULE

> **อย่าแตะโค้ดจนกว่าจะบอก root cause ได้พร้อมหลักฐาน.**
> ห้ามเดา ห้ามกดอาการ (`undefined` → ใส่ `?.`) แล้วเรียกว่าแก้แล้ว
> ถ้ายังบอกไม่ได้ว่า "พังเพราะอะไร" = ยังไม่ถึงเวลาแก้ ให้ไปหาหลักฐานต่อ

**เมื่อร่องรอยตัน / ยังไม่รู้สาเหตุ** → delegate การสืบสวนให้ agent `root-cause-debugger`
(agent สาย investigate อย่างเดียว: อ่าน log / git / data flow แล้วรายงานสาเหตุกลับมา — ไม่แก้โค้ดเอง)

---

## Protocol: REPRODUCE → EVIDENCE → DIAGNOSE → FIX → PROVE

### 1. REPRODUCE — ทำให้พังซ้ำก่อน
ทำให้ bug เกิดขึ้นบนเจตนา ก่อนคิดแก้เสมอ. รู้ path/URL/action ที่ทำให้พัง แล้วเห็นมันพังกับตา
**ถ้าทำซ้ำไม่ได้ = ยังแก้ไม่ได้** — บอกตรงๆ แล้วขอข้อมูลเพิ่ม (steps, env, ข้อมูลที่ใช้, screenshot)

### 2. EVIDENCE — เก็บหลักฐาน (ห้ามเดา)
- **อ่าน error + stack trace เต็มๆ** — ไฟล์ไหน บรรทัดไหน เรียกมาจากไหน
- **`git log` / `git diff`** — อะไรเพิ่งเปลี่ยน (bug ใหม่ = โค้ดใหม่ ~80%)
- **ตาม data flow ด้วย log/debugger จริง** — ค่ามาจากไหน, ตอนถึงจุดพังค่าเป็นอะไรจริงๆ, มันหายที่ step ไหน

### 3. DIAGNOSE — differential diagnosis
เขียนสมมุติฐาน 2–3 ข้อ แต่ละข้อมี **หลักฐานสนับสนุน + หักล้าง**
→ เลือกข้อที่ **หลักฐานชี้** ไม่ใช่ข้อที่แก้ง่ายสุด
→ ถาม "ทำไม" ต่อจนถึงต้นตอ (ทำไม undefined? → API ตอบช้า → ทำไมไม่มี loading state?)

### 4. FIX — แก้ที่ต้นตอ
แก้ root cause ที่จุดเดียว. จะเสริม defensive guard ตรงจุดที่อาการโผล่ก็ได้ **แต่ guard ไม่ใช่การแก้** — ต้นตอต้องหาย

### 5. PROVE — พิสูจน์ว่าหาย
รันเส้นทางเดิมที่พังซ้ำ + เส้นทางข้างเคียงที่อาจโดนกระทบ **แล้วค่อยรายงาน** (ไม่ใช่ "น่าจะได้แล้ว")

---

## 🔁 Rewrite Rule

เสนอเขียนใหม่เมื่อ **พิสูจน์ได้ว่า design ผิด** เท่านั้น — ไม่ใช่นับจำนวนรอบที่ลอง
"ลองมาหลายรอบแล้วเลยลบทิ้ง" = ยอมแพ้ ไม่ใช่วิศวกรรม. ถ้าหา evidence เป็นระบบ ส่วนใหญ่จบใน 1–2 attempt

---

## 🔍 Common Root Causes

หาสาเหตุจริง แล้ว **พิสูจน์** — ไม่ใช่แปะ fix สำเร็จรูป

| Symptom | สาเหตุจริงที่พบบ่อย | วิธี PROVE |
|---------|--------------------|-----------|
| `Cannot read property X of undefined` | ไม่มี loading state / API response shape เปลี่ยน / race condition | ตอน render มีข้อมูลจริงไหม? log ค่า + shape ของ API response จริง; พังเฉพาะ network ช้า (หรือเร็ว) ไหม? |
| `Type X is not assignable to Y` | type ที่ประกาศไว้ **โกหก** runtime shape จริง | log/inspect ค่า runtime จริง เทียบกับ type ที่ประกาศ — อันไหนตรงความจริง |
| Hydration mismatch | server กับ client render ต่างกัน (`Date.now`/`Math.random`/`window`/locale) | หาให้เจอว่า **อะไร** ที่ต่างระหว่าง server render กับ client render |
| `Module not found` | path ผิด / ยังไม่ได้ install / case-sensitivity | เช็ค path ไฟล์จริงกับ `package.json` — ชื่อ/ตัวพิมพ์ตรงกันไหม |
| ทำงานบนเครื่อง แต่ build พัง | type-check เข้มกว่า / env var หาย / dynamic import | อ่าน error ตอน build จริง **อย่าเดา** ว่าเป็นอะไร |

---

## 📋 Report Format (ภาษาคน)

```
Problem     — อาการที่เจอ (ผู้ใช้เห็นอะไร)
Root cause  — สาเหตุจริง + หลักฐานที่ยืนยัน
Fix         — แก้อะไร ที่ไฟล์ไหน ทำไม
Proof       — รันอะไรซ้ำแล้วผ่าน (เส้นทางเดิม + ข้างเคียง)
Prevention  — กันไม่ให้กลับมาอีกยังไง
```

---

## 🧠 Memory (สั้นๆ)

- **เริ่มงาน:** อ่าน `.toh/memory/active.md` + `.toh/memory/changelog.md` (debugging อยากรู้ว่าอะไรเพิ่งเปลี่ยน)
- **จบงาน:** log การแก้ลง `.toh/memory/changelog.md`

---

## Example

```bash
/toh-fix TypeError: Cannot read property 'map' of undefined
/toh-f  dashboard ไม่โหลด หน้าเปล่า
/toh-fix ทำงานบนเครื่อง แต่ npm run build พัง
```
