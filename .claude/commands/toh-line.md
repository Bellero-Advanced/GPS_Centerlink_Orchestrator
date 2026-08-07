---
command: /toh-line
aliases: ["/toh-l"]
description: Convert web app to LINE Mini App or create new LIFF integration
trigger: /toh-line or /toh-l
skills:
  - platform-specialist
  - engineer-harness
---

# /toh-line — Convert to LINE MINI App 💚

```
/toh-line            → แปลงแอปปัจจุบันเป็น LINE MINI App (default — ไม่ต้องพิมพ์อะไรต่อ)
/toh-line [feature]  → convert + เพิ่ม feature LINE (share, message, rich menu ฯลฯ)
```

## 🧭 IRON RULE

> แอปเป็น **web อยู่แล้ว** — งาน convert จริงๆ มีนิดเดียว: หุ้มด้วย LIFF แล้วปรับ UX
> **ห้าม hardcode เวอร์ชัน SDK / ห้ามลอก snippet เก่า** — ดึง docs จริงก่อนเขียนโค้ดทุกครั้ง
> LIFF = ตัว SDK (`@line/liff`) ที่ยังใช้อยู่ · **LINE MINI App** = channel type ใหม่ที่เราสร้าง (แทน LINE Login + LIFF-app แบบเก่า)

---

## Flow: DOC CHECK → WRAP → ADAPT UX → CHANNEL → VERIFY

### 1. DOC CHECK ก่อนเสมอ (สำคัญสุด)
ดึง docs ปัจจุบันจาก `developers.line.biz` ผ่าน **Context7** (`/websites/developers_line_biz_en_reference_liff`) หรือ web fetch:
- **SDK version ล่าสุด** + วิธีติดตั้ง — `npm i @line/liff` (ตรึง version ตาม docs) หรือ CDN edge `https://static.line-scdn.net/liff/edge/2/sdk.js` (ได้ v2 ล่าสุดเสมอ)
- **API ที่จะใช้** (`liff.init`, `isInClient`, `isLoggedIn`, `getProfile`, `shareTargetPicker`, `sendMessages`) — เช็ค signature จาก reference จริง ไม่เดาจากความจำ
- เช็ค **release notes** ว่ามี method ใหม่/deprecated อะไร แล้วค่อยเขียนโค้ด

### 2. WRAP — หุ้มแอปเดิมด้วย LIFF
- `lib/liff.ts` — `initializeLiff()` + helper (`isInLiff`, `getProfile`, `shareMessage`, `closeLiff`) ตาม API ที่เพิ่งเช็ค
- `providers/liff-provider.tsx` — init ครั้งเดียวตอน mount, เก็บ state (`isReady`, `isInLiff`, `isLoggedIn`, `profile`, `error`)
- ใส่ `<LiffProvider>` ครอบใน root layout · `liffId` อ่านจาก env ที่ผูกกับ channel ของผู้ใช้ (ค่าตัวอย่างไม่ใช่ของจริง — เอามาจาก channel ที่สร้างในขั้น 4)

### 3. ADAPT UX — ตาม LINE MINI App guideline
- **ไม่มีหน้า login แยก** — พอเปิดใน LINE มี profile ให้เลยผ่าน `getProfile()` (ทักชื่อ/รูปได้ทันที)
- **Safe area** — เผื่อ header ของ LINE ด้านบน (`env(safe-area-inset-top/bottom)`) ปุ่มสำคัญอย่าชนขอบ
- **ปุ่ม action เต็มความกว้าง** แตะง่าย (min 44px) · สี brand/ปุ่ม **ยึดตาม LINE design guideline ใน docs** ไม่ใช่ hardcode ค่าตายตัวในไฟล์นี้
- ถ้าเปิดนอก LINE (external browser) → แสดง fallback ที่ยังใช้งานได้ ไม่ใช่จอเปล่า

### 4. CHANNEL — เดินเรื่องภาษาคน (non-dev ทำตามได้)
**เตรียมก่อน:** LINE Developers account · endpoint URL (URL ที่ deploy แล้ว เช่นบน Vercel) · provider (ไทย: เดือน มี.ค. 2026 สร้าง LINE MINI App channel ได้แล้ว แต่ต้องอยู่ใต้ certified provider)

เดินให้ทีละสเต็ปแบบ "เปิดหน้านี้ → กดตรงนี้ → copy ค่านี้มาวาง":
1. เปิด `developers.line.biz/console` → เลือก/สร้าง provider
2. กด **Create a new channel** → เลือกชนิด **LINE MINI App**
3. กรอกชื่อแอป + region (Thailand) → สร้าง
4. เข้า tab **LIFF / MINI App** → ตั้ง **Endpoint URL** = URL ที่ deploy · เลือก scope (`profile`, `openid`)
5. copy **LIFF ID** → เอามาใส่ใน env (`NEXT_PUBLIC_LIFF_ID`) แล้ว redeploy
> ชี้ปุ่ม/เมนูตาม docs ล่าสุดจริง (UI console เปลี่ยนได้) — อย่าอธิบายจากภาพจำ

### 5. VERIFY — พิสูจน์ว่าใช้ได้จริง
- เปิดใน **LINE app** → `liff.init()` สำเร็จ (ไม่มี error code), `getProfile()` คืนชื่อ/รูปจริง
- เปิดใน **browser ปกติ** → fallback ทำงาน ไม่ crash (`isInClient() === false` แล้ว UI ยังใช้ได้)
- ถ้ามี feature (share/message) → ยิงจริงแล้วเห็นผลใน chat · แล้วค่อยรายงานว่า "ผ่าน"

---

## + [feature] — convert แล้วเพิ่มของ LINE
| พิมพ์ | ได้อะไร | เช็คก่อนใช้ |
|-------|---------|-----------|
| `/toh-line add share` | ปุ่มแชร์ผ่าน `shareTargetPicker` | `isApiAvailable('shareTargetPicker')` |
| `/toh-line add message` | ส่งข้อความเข้า chat ผ่าน `sendMessages` | `isInClient()` ก่อนเรียก |
| `/toh-line add rich menu` | rich menu ผูกกับ OA | ทำฝั่ง Messaging API / console |

---

## Output Format (ภาษาคน)
```
Converted   — ไฟล์ที่เพิ่ม/แก้ (lib/liff.ts, providers/liff-provider.tsx, layout)
SDK         — @line/liff เวอร์ชันไหน (ดึงจาก docs วันนี้) + วิธีติดตั้ง
Channel     — checklist ตั้งค่า LINE MINI App channel ทีละขั้น + ต้องเตรียมอะไร
Verify      — init สำเร็จใน LINE ✓ · fallback นอก LINE ✓
Next        — deploy → ใส่ Endpoint URL + LIFF ID → เปิดผ่าน LINE
```

## Example
```bash
/toh-line                          # convert แอปเดิม → LINE MINI App
/toh-l add LINE share button       # convert + ปุ่มแชร์
/toh-line convert + get profile    # convert + ทักผู้ใช้ด้วยชื่อจาก LINE
```

## 🧠 Memory (สั้นๆ)
- **เริ่มงาน:** อ่าน `.toh/memory/active.md` + `.toh/memory/architecture.md`
- **จบงาน:** log LIFF integration ลง `.toh/memory/changelog.md` + `decisions.md` (channel config)

## Rules
1. **ALWAYS** ดึง docs จริงก่อนเขียนโค้ด — ห้าม hardcode SDK version / API signature
2. **ALWAYS** `liff.init()` สำเร็จก่อน แล้วค่อยเรียก API อื่น
3. **ALWAYS** เช็ค `isInClient()` / `isApiAvailable()` ก่อนเรียกฟีเจอร์เฉพาะ LINE
4. **ALWAYS** มี fallback ตอนเปิดนอก LINE — ห้ามจอเปล่า
5. **NEVER** สมมติว่าค่าตัวอย่าง (LIFF ID, สี brand) คือของจริง — เอามาจาก channel/docs ของผู้ใช้
