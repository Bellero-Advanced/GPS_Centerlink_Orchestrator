# 🚀 วิธีใช้งาน Claude Code + /toh- Commands

> คู่มือใช้งาน Claude Code แบบ Lovable-style  
> "สั่งปุ๊บ ได้ปั๊บ ไม่ต้องถาม ไม่ต้องรอ"

---

## 📋 สารบัญ

1. [การติดตั้ง](#1-การติดตั้ง)
2. [เริ่มต้นใช้งาน](#2-เริ่มต้นใช้งาน)
3. [สร้าง Project ใหม่](#3-สร้าง-project-ใหม่)
4. [พัฒนาต่อยอด](#4-พัฒนาต่อยอด)
5. [ตัวอย่างการใช้งานจริง](#5-ตัวอย่างการใช้งานจริง)
6. [Tips & Tricks](#6-tips--tricks)

---

## 1. การติดตั้ง

### ติดตั้ง Claude Code CLI

```bash
# ติดตั้ง Claude Code
npm install -g @anthropic-ai/claude-code

# หรือใช้ npx
npx @anthropic-ai/claude-code
```

### ตรวจสอบว่า Skills และ Commands พร้อมใช้

```bash
# ดู skills ที่มี
ls ~/.claude/skills/

# ดู commands ที่มี  
ls ~/.claude/commands/

# ดู agents ที่มี
ls ~/.claude/agents/
```

ต้องเห็น:
```
skills/
├── vibe-orchestrator/
├── ui-first-builder/
├── dev-engineer/
├── design-craft/
├── backend-engineer/
└── platform-specialist/

commands/
├── toh-vibe.md
├── toh-ui.md
├── toh-dev.md
├── toh-design.md
├── toh-connect.md
├── toh-line.md
├── toh-mobile.md
├── toh-fix.md
└── toh-ship.md

agents/
├── ui-builder.md
├── dev-builder.md
├── design-reviewer.md
├── backend-connector.md
└── platform-adapter.md
```

---

## 2. เริ่มต้นใช้งาน

### เปิด Claude Code

```bash
# เข้าไปใน folder ที่ต้องการทำงาน
cd ~/projects

# เปิด Claude Code
claude
```

### ทำความเข้าใจ Commands

| Command | Shortcut | ทำอะไร |
|---------|----------|--------|
| `/toh-vibe` | `/toh-v` | สร้าง project ใหม่ตั้งแต่ต้น |
| `/toh-ui` | `/toh-u` | สร้าง/แก้ไข UI components |
| `/toh-dev` | `/toh-d` | เพิ่ม logic, state, validation |
| `/toh-design` | `/toh-ds` | Polish design ให้ดู pro |
| `/toh-connect` | `/toh-c` | เชื่อม Supabase backend |
| `/toh-line` | `/toh-l` | แปลงเป็น LINE MINI App |
| `/toh-mobile` | `/toh-m` | สร้าง mobile app (PWA / Capacitor) |
| `/toh-fix` | `/toh-f` | แก้ bug อัตโนมัติ |
| `/toh-ship` | `/toh-s` | Deploy to production |

---

## 3. สร้าง Project ใหม่

### Step 1: สั่งสร้าง

```
/toh-vibe ระบบจัดการสินค้า สำหรับร้านกาแฟ
```

**เท่านี้จบ!** Claude จะ:
1. ✅ สร้าง Next.js project
2. ✅ ติดตั้ง dependencies
3. ✅ สร้าง UI พร้อม mock data ภาษาไทย
4. ✅ รัน dev server

### Step 2: ดูผลลัพธ์

```
✅ Project พร้อมแล้วค่ะ!

📁 สร้างไฟล์:
- app/page.tsx (Dashboard)
- app/products/page.tsx (รายการสินค้า)
- components/features/product-card.tsx
- types/index.ts
- lib/mock-data.ts

🌐 Preview: http://localhost:3000

🎯 ต้องการอะไรเพิ่มสั่งได้เลยค่ะ!
```

---

## 4. พัฒนาต่อยอด

### เพิ่มหน้าใหม่

```
/toh-ui หน้า orders พร้อม table แสดงออเดอร์ และ filter by status
```

### เพิ่ม Form

```
/toh-ui form เพิ่มสินค้า ในหน้า products
```

### เพิ่ม Logic

```
/toh-dev เพิ่ม CRUD และ search สำหรับ products
```

### ปรับ Design

```
/toh-design ปรับให้ดู professional ขึ้น
```

### เชื่อม Backend

```
/toh-connect เชื่อม Supabase พร้อม auth
```

### Deploy

```
/toh-ship deploy ไป Vercel
```

---

## 5. ตัวอย่างการใช้งานจริง

### 🛒 สร้าง E-commerce

```bash
# Step 1: สร้าง project
/toh-vibe ร้านขายเสื้อผ้าออนไลน์

# Step 2: เพิ่มหน้า products
/toh-ui หน้าสินค้า grid view พร้อม filter by category และ price range

# Step 3: เพิ่มหน้า cart
/toh-ui หน้าตะกร้าสินค้า พร้อม summary และ checkout button

# Step 4: เพิ่ม logic
/toh-dev cart functionality ด้วย Zustand

# Step 5: เชื่อม backend
/toh-connect products, orders, users tables

# Step 6: Deploy
/toh-ship
```

### 📊 สร้าง Dashboard

```bash
# Step 1: สร้าง project
/toh-vibe admin dashboard สำหรับดู analytics

# Step 2: เพิ่ม charts
/toh-ui หน้า reports พร้อม line chart รายได้ และ bar chart ยอดขาย

# Step 3: เพิ่ม tables
/toh-ui table แสดง recent orders พร้อม pagination

# Step 4: เพิ่ม filters
/toh-dev filter by date range และ export to CSV
```

### 📱 สร้าง LINE MINI App

```bash
# Step 1: สร้าง web app ก่อน
/toh-vibe ระบบจองคิว ร้านอาหาร

# Step 2: แปลงเป็น LINE MINI App (ยังใช้ LIFF SDK)
/toh-line เพิ่ม LINE login และ share

# Step 3: เพิ่ม LINE features
/toh-ui ปุ่มแชร์ให้เพื่อน และ ส่งข้อความยืนยัน
```

### 💼 สร้าง SaaS

```bash
# Step 1: สร้าง core app
/toh-vibe project management tool

# Step 2: เพิ่ม auth
/toh-connect auth ด้วย email/password และ Google

# Step 3: เพิ่ม team features
/toh-ui หน้า team management และ invite members

# Step 4: เพิ่ม subscription
/toh-dev pricing plans และ Stripe integration
```

---

## 6. Tips & Tricks

### 💡 Tip 1: ยิ่งให้ context ยิ่งดี

```bash
# ❌ ไม่ดี (กว้างเกินไป)
/toh-ui หน้า settings

# ✅ ดี (ชัดเจน)
/toh-ui หน้า settings แบ่งเป็น tabs: Profile, Notifications, Security
```

### 💡 Tip 2: ทำทีละ step

```bash
# แทนที่จะสั่งทุกอย่างทีเดียว
# ให้สั่งทีละ step แล้วตรวจสอบ

/toh-ui หน้า products      # ตรวจสอบ UI
/toh-dev CRUD products     # ตรวจสอบ logic
/toh-design polish         # ตรวจสอบ design
```

### 💡 Tip 3: ใช้ /toh-fix เมื่อมี error

```bash
# เมื่อเจอ error ไม่ต้อง debug เอง
/toh-fix
```

### 💡 Tip 4: ดู mock data ก่อน connect

```bash
# ตรวจสอบว่า UI ทำงานถูกต้องกับ mock data ก่อน
# แล้วค่อย connect backend

/toh-vibe expense tracker
# ทดสอบ UI...
/toh-connect
```

### 💡 Tip 5: ใช้ภาษาไทยได้เลย

```bash
# Commands รองรับภาษาไทยเต็มที่
/toh-vibe ระบบบันทึกรายรับรายจ่าย สำหรับคนทำธุรกิจ SME
/toh-ui เพิ่มหน้ารายงานประจำเดือน พร้อม chart
```

---

## 🎯 Quick Reference

```bash
# สร้าง Project ใหม่
/toh-v [description]

# เพิ่ม/แก้ UI
/toh-u [what to create/modify]

# เพิ่ม Logic
/toh-d [what logic to add]

# Polish Design
/toh-ds

# Connect Backend
/toh-c

# LINE MINI App
/toh-l

# Mobile App
/toh-m

# Fix Errors
/toh-f

# Deploy
/toh-s
```

---

## 🆘 แก้ปัญหาเบื้องต้น

### "Command not found"

```bash
# ตรวจสอบว่า commands อยู่ถูกที่
ls ~/.claude/commands/
# ถ้าไม่มี ให้ copy จาก template
```

### "Skills not loading"

```bash
# ตรวจสอบว่า skills อยู่ถูกที่
ls ~/.claude/skills/
# ถ้าไม่มี ให้ copy จาก template
```

### "Error แต่ไม่รู้ว่าอะไร"

```bash
# ใช้ /toh-fix
/toh-fix

# หรืออธิบาย error ที่เห็น
/toh-fix error: Cannot read property 'map' of undefined
```

---

## 📚 Resources

- **Skills:** `~/.claude/skills/`
- **Commands:** `~/.claude/commands/`
- **Agents:** `~/.claude/agents/`
- **Templates:** `~/.claude/templates/`

---

> 💡 **Remember:** Claude Code + /toh- commands ออกแบบมาให้ใช้งานง่ายเหมือน Lovable
> 
> **สั่ง → ได้ → ใช้งาน**
> 
> ไม่ต้องคิดเยอะ ลุยเลย! 🚀
