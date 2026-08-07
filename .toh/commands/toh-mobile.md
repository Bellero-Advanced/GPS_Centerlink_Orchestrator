---
command: /toh-mobile
aliases: ["/toh-m"]
description: Turn the current web app into a mobile app — PWA (default) or native store build (Capacitor)
trigger: /toh-mobile or /toh-m
skills:
  - platform-specialist
  - engineer-harness
---

# /toh-mobile — Web → Mobile (one codebase) 📱

```
/toh-mobile          → แปลงแอปปัจจุบันเป็น PWA (default): ผู้ใช้ Add to Home Screen เห็นแอปบนมือถือใน ~1 นาที
/toh-mobile store    → เพิ่ม Capacitor: ทำ iOS/Android project จริง ขึ้น App Store / Play Store
```

## 🧭 IRON RULE

> **codebase เดียว** — web ที่มีอยู่คือตัวแอป เราแค่ห่อมันให้กลายเป็น mobile (pattern เดียวกับ `/toh-line`)
> อย่ารีบไปทาง store ถ้า PWA พอ — PWA คือ "เฮ้ย ง่าย" ที่เห็นผลใน session เดียว

---

## เลือกทางไหน? (อธิบายภาษาคน)

| | **PWA** (default) | **Capacitor** (`store`) |
|---|---|---|
| ผู้ใช้ติดตั้งยังไง | เปิดเว็บ → Add to Home Screen (ไม่ลงอะไร) | โหลดจาก App Store / Play Store |
| เห็นผลเร็วแค่ไหน | ~1 นาที | เป็นวัน–สัปดาห์ (ต้องรีวิว) |
| ต้องมีบัญชีอะไร | ไม่ต้อง | Apple Developer ($99/ปี) + Google Play ($25 ครั้งเดียว) |
| native จริงไหม | เข้าถึง API เว็บ (offline, notification บนบางเครื่อง) | camera, push, native plugins เต็มตัว |
| **เมื่อไหร่ควรใช้** | MVP, ทดสอบไอเดีย, แจกลิงก์ให้ลูกค้าลองเลย | ต้องขึ้น store จริง / ต้องใช้ native API ที่ PWA ทำไม่ได้ |

> เริ่มที่ **PWA เสมอ** → พอจำเป็นต้องขึ้น store ค่อยสั่ง `/toh-mobile store` (ต่อยอดจากของเดิม ไม่ต้องเขียนใหม่)

---

## Track A — PWA (default)

**เป้าหมาย:** ผู้ใช้เปิดเว็บบนมือถือ → กด Add to Home Screen → มี icon แอปบน home จริง เปิดเต็มจอ

1. **Web app manifest** — `app/manifest.ts` (Next.js) : name, short_name, `display: "standalone"`, theme/background color, start_url
2. **Icons** — generate ครบชุด (192, 512, maskable, apple-touch-icon) จาก logo เดียว
3. **Service worker** — cache แอปให้เปิดได้ตอนออฟไลน์พื้นฐาน (แนะนำ **Serwist** สำหรับ Next.js; หรือ SW เขียนเองถ้าง่ายพอ)
4. **Install prompt** — ดัก `beforeinstallprompt` แสดงปุ่ม "เพิ่มลงหน้าจอหลัก" เอง (Android/desktop) · iOS ต้องบอกวิธีด้วยมือ
5. **สอน Add to Home Screen ภาษาคน:**
   - **iPhone (Safari):** กดปุ่ม Share (สี่เหลี่ยมลูกศรขึ้น) → เลื่อนหา **"Add to Home Screen"** → Add
   - **Android (Chrome):** กดเมนู ⋮ มุมขวาบน → **"Add to Home screen" / "Install app"** → ติดตั้ง
6. **Verify:** เปิดบนมือถือจริง → เพิ่มลง home → เปิดจาก icon แล้วเต็มจอ (ไม่มี browser bar) + ลองปิดเน็ตดูว่ายังเปิดได้

---

## Track B — Capacitor (`/toh-mobile store`)

**เป้าหมาย:** ห่อ Next.js เดิมทั้งก้อนเป็น native app ขึ้น store

1. `npm i @capacitor/core && npm i -D @capacitor/cli` → `npx cap init`
2. เตรียม build ที่ Capacitor ใช้ได้ (static export หรือ host เว็บแล้วชี้ `server.url`) → `npx cap add ios` / `npx cap add android`
3. **Native plugins** ตามต้องการ: `@capacitor/camera`, `@capacitor/push-notifications`, `@capacitor/geolocation` ฯลฯ
4. `npx cap sync` ทุกครั้งหลัง build → เปิดใน Xcode / Android Studio
5. **เส้นทางขึ้น store (ภาษาคน):**
   - **iOS:** ต้องมี **Apple Developer account** ($99/ปี) → set bundle id + signing ใน Xcode → Archive → อัปโหลดผ่าน App Store Connect → รอ Apple review
   - **Android:** สมัคร **Google Play Console** ($25 ครั้งเดียว) → build signed AAB → อัปโหลด → รอ review
6. **Verify:** รันบน simulator/เครื่องจริง → plugin (เช่น camera) เรียกได้ → build ผ่านไม่ error ก่อนพูดว่าเสร็จ

---

## 🗒 Legacy note — Expo / React Native
Expo/bare React Native = **คนละ codebase** (ต้อง generate ใหม่ ขัดหลัก "Type Once") — PWA/Capacitor เก็บ codebase เดียว ใช้เฉพาะกรณีที่ **จำเป็นต้องเป็น bare React Native จริงๆ** เท่านั้น ไม่ใช่ทางหลักอีกต่อไป

---

## Output Format (ภาษาคน)
```
Track       — PWA หรือ Capacitor
Added       — ไฟล์ที่เพิ่ม (manifest, icons, service worker / cap config, native plugins)
Try it now  — วิธี Add to Home Screen บนมือถือตัวเอง (iOS + Android) ทีละสเต็ป
Verify      — เปิดจาก icon เต็มจอ ✓ · offline พื้นฐาน ✓ (store: build ผ่าน + plugin ทำงาน)
Next        — PWA พอไหม? ถ้าต้องขึ้น store → /toh-mobile store
```

## Example
```bash
/toh-mobile                     # แปลงเป็น PWA + สอน Add to Home Screen
/toh-m                          # เหมือนกัน (alias)
/toh-mobile store               # เพิ่ม Capacitor เตรียมขึ้น App Store / Play Store
```

## 🧠 Memory (สั้นๆ)
- **เริ่มงาน:** อ่าน `.toh/memory/active.md` + `.toh/memory/architecture.md`
- **จบงาน:** log mobile setup ลง `.toh/memory/changelog.md` + `decisions.md` (PWA vs store)

## Rules
1. **ALWAYS** เริ่มที่ PWA — เสนอ Capacitor เฉพาะตอนต้องขึ้น store จริง
2. **ALWAYS** สอน Add to Home Screen ทั้ง iOS และ Android (ขั้นตอนต่างกัน)
3. **ALWAYS** ทดสอบบนมือถือจริงก่อนบอกว่าเสร็จ (เต็มจอ + offline)
4. **NEVER** พา Expo เป็นทางหลัก — มันคนละ codebase
5. **NEVER** สัญญาว่าขึ้น store ได้เลย — ต้องมี Apple/Google account + ผ่าน review ก่อน
