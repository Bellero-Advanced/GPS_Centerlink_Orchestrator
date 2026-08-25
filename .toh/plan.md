# Plan: แก้การ์ดรถขัดแย้งกันเอง — สถานะ/ความเร็ว/เวลา

Status: completed 2026-08-25
Created: 2026-08-25 by /toh-plan
Supersedes: plan-2026-08-25-DLT-partition-DONE.md (เสร็จครบ 19/19 แล้ว)

## Goal

พี่โตเห็นการ์ดรถที่**ขัดแย้งกันเองในใบเดียว**: แถบแดง `จอดดับเครื่อง` แต่โชว์ `44 km/h`
และเวลา `23/08/2569` ทั้งที่วันนี้ 25 ส.ค. — สามอาการนี้ **ไม่ใช่ 3 บั๊ก** แต่เป็นโซ่เดียวกัน
ที่เริ่มจากจุดเดียว: **รถที่ไม่มีข้อมูลสดเลย ถูกตัดสินว่า "ยังสด"**

### พิสูจน์แล้วด้วยการ replay logic จริง (ไม่ใช่เดา)

รัน `useDevices.ts` ทั้งบล็อกกับ device ที่ Traccar cache ไม่คืน (`livePos = undefined`)
แต่แถวใน DB บอก `status='online'` — ได้ผลตรงกับภาพที่พี่โตเห็นเป๊ะ:

```
livePos present : false
isGpsStale      : false   ← ไม่มีข้อมูลสดเลย แต่ตัดสินว่า "สด"
isOnline        : true
hook speedKmh   : 0
displayStatus   : stopped  (แถบแดง จอดดับเครื่อง)
panel prints    : 44 km/h  ← จาก DB fallback ข้าม speedKmh ไปเลย
panel time      : 2026-08-23  = 2.4 วันก่อน
```

### โซ่ต้นตอ — 3 ข้อต่อ

**ข้อต่อ 1 — `isGpsStale` ตกเป็น `false` เมื่อไม่มีข้อมูล** (`useDevices.ts:216-218`)

```ts
const isGpsStale = liveEffectiveTime
  ? Date.now() - liveEffectiveTime.getTime() > GPS_STALE_MS
  : false;   // ← ไม่มี livePos → แปลว่า "ไม่เก่า"
```

ตรรกะกลับหัว: **ไม่มีข้อมูลสด = หลักฐานว่า offline ที่หนักที่สุด** แต่โค้ดอ่านเป็น "ผ่าน"
พอ `isGpsStale=false` และ `device.status='online'` (ค่าใน DB ที่ค้างจากก่อน Traccar restart)
→ `isOnline=true` → เข้าสาย `stopped` ได้ ทั้งที่ควรเป็น `offline`

นี่คือรากของ **อาการ "จอดดับเครื่องสีแดงหลายคัน"** — รถ 2 วันก่อนไปกองอยู่ในถังแดง
ทั้งที่ควรเป็นสีเทาออฟไลน์ ทำให้ตัวเลข `88/206` และ `14 กำลังวิ่ง` ที่ footer เชื่อถือไม่ได้

**ข้อต่อ 2 — การ์ดคำนวณความเร็วเองจากแหล่งผิด** (`FloatingVehiclePanel.tsx:122`)

```ts
const kmh = Math.round((vehicle.position?.speed ?? 0) * 1.852);
```

`vehicle.position` = ตำแหน่งที่**กู้จาก PostgreSQL** (`positionMap`) ส่วน `vehicle.speedKmh`
ที่ hook คำนวณไว้ = จาก **cache สดเท่านั้น** (`livePos`) — commit `b6db3fb` แยกสองตัวนี้ไว้
โดยเจตนา (บันทึกใน memory: fallback ต้องเป็น display-only ห้ามป้อนเข้า logic)
แต่การ์ด**ข้าม `speedKmh` ทิ้ง** แล้วคูณ 1.852 เองจาก `position` → ได้ความเร็ว 2 วันก่อน
มาแปะบนการ์ดที่บอกว่าจอด นี่คือ **อาการ "จอดดับเครื่องแต่มีความเร็ว"**

ทำผิดแบบเดียวกันอีก 5 จุด — `TelematicsPage:179` · `VehicleDetailPage:242,355` ·
`FleetPage:92,121,450` · `DashboardPage:404` ทุกจุดอ่าน `position.speed` ตรง ๆ

**ข้อต่อ 3 — เวลา 23/08 ไม่ใช่บั๊ก แต่ไม่มีบริบท**

`23/08/2569 08:14` คือ**เวลาจริงของ fix ล่าสุด** ที่ `effectiveTime()` คำนวณถูกแล้ว —
รถคันนั้น GPS หยุดส่งไป 2 วันจริง (SIM หมด/ถอดเครื่อง — แก้ด้วยโค้ดไม่ได้ ต้องแก้หน้างาน)
ปัญหาคือการ์ด**แสดงวันที่เปล่า ๆ** โดยไม่บอกว่านี่เก่า 2 วัน พอวางข้าง `44 km/h`
พี่โตจึงอ่านว่า "เวลาเพี้ยน" ทั้งที่มันคือ "ข้อมูลเก่าที่ถูกนำเสนอเหมือนของสด"

> ⚠️ ตัวแก้ timezone เดิม (`fixMs - srvMs > 1 ชม.` → ใช้ `serverTime`) **ถูกแล้ว ห้ามแตะ**
> memory ยืนยันด้วย raw payload ว่า gt06/meitrack ยังส่งเวลา +7 มาเองจริง

### ตัดสินใจแล้ว (พี่โตเลือกข้อ 1)

รถไม่มีข้อมูลสด → **`offline` สีเทา `#9AA0A6`** ตามกฎในเอกสาร (`offline = ไม่มีข้อมูล > 5 นาที`)
ไม่เพิ่มสถานะใหม่ ไม่แตะชุดสี 4 สีเดิม — `CLAUDE.md` ห้ามเปลี่ยนสีสถานะ
ผลข้างเคียงที่ยอมรับ: การ์ดแดงจะลดลง การ์ดเทาจะเพิ่มขึ้น (~20-80 คัน) = ความจริงที่ถูกซ่อนอยู่

ยังเห็น **พิกัด + ที่อยู่ + เวลา fix ล่าสุด** ครบเหมือนเดิม (นั่นคือคุณค่าของ fallback
ที่ commit `b6db3fb` สร้างไว้ — เก็บไว้ทั้งหมด) แต่ซ่อนความเร็วเก่าทิ้ง

## Stack

ไม่มีของใหม่ — React 18 + React Query + TypeScript strict ตาม `CLAUDE.md` เดิมทุกข้อ
(hook → component · ไม่มี `any` · ไม่แตะสีสถานะ · speed เก็บเป็น knots แปลงที่ display)
เพิ่ม Vitest test ไฟล์แรกของ repo (มี `vitest.config.ts` + `npm run test` อยู่แล้ว ยังไม่มีเทสต์เลย)

## Pages / Files ที่แตะ

| ไฟล์ | ทำอะไร |
|---|---|
| `src/hooks/useDevices.ts` | แก้ `isGpsStale` · export `hasLiveData` ให้ UI ใช้ |
| `src/hooks/__tests__/vehicleStatus.test.ts` | **ใหม่** — ล็อกพฤติกรรมด้วยเทสต์ |
| `src/components/map/FloatingVehiclePanel.tsx` | ใช้ `speedKmh` จาก hook · ป้าย "ข้อมูลเก่า" |
| `src/pages/TelematicsPage.tsx` | เลิกคำนวณ speed เอง |
| `src/pages/VehicleDetailPage.tsx` | เลิกคำนวณ speed เอง (2 จุด) |
| `src/pages/FleetPage.tsx` | เลิกคำนวณ speed เอง (3 จุด — รวม export CSV) |
| `src/pages/DashboardPage.tsx` | เลิกคำนวณ speed เอง |

## Done When

1. ไม่มีการ์ดใดแสดง `จอดดับเครื่อง`/`จอดติดเครื่อง`/`ออฟไลน์` พร้อมความเร็ว > 0 พร้อมกัน
2. รถที่จอดดับเครื่อง / ออฟไลน์ → ความเร็วแสดง **`0 km/h`** (ไม่ใช่ `—` ไม่ใช่เลขเก่า)
   — พี่โตสั่งชัด: จอดอยู่ = ความเร็วศูนย์จริง ต้องอ่านได้ทันทีว่าศูนย์
3. **เวลาต้องเป็น fix ล่าสุดของคันนั้นเสมอ** — ห้ามอ่านย้อนหลัง ห้ามหยิบ position เก่ากว่า
   ที่ `positionId` ชี้อยู่ · fix เก่ากว่า 5 นาที → มีป้ายบอกอายุ ("2 วันก่อน") กำกับ
4. ยังเห็นพิกัด + ที่อยู่ + เวลา fix ล่าสุดครบ (ไม่ถอย `b6db3fb`)
5. `npm run test` ผ่าน — เทสต์ครอบ 5 เคส: cache hit moving/idle/stopped · cache miss → offline · fixTime +7
6. `npm run build` 0 error · `npm run lint` 0 warning
7. ตัวเลข footer สอดคล้องกัน: `moving + idle + stopped + offline == total`

## Phase 1 — แก้รากที่ hook (ต้นน้ำ)

- [x] **T001** `dev-builder` — `src/hooks/useDevices.ts`: แก้ `isGpsStale` ให้ไม่มี `livePos` = stale
      (`const isGpsStale = liveEffectiveTime ? ... : true`) + เพิ่ม `hasLiveData: !!livePos`
      และ `lastFixAgeMs` ใน return object · อัปเดต `VehicleWithPosition` ใน `traccar.types.ts`
- [x] **T002** `dev-builder` — `src/hooks/__tests__/vehicleStatus.test.ts` (**ใหม่**):
      แยก logic คำนวณสถานะออกเป็น pure function `computeVehicleStatus()` ใน `src/lib/vehicleStatus.ts`
      แล้วเทสต์ 5 เคสใน Done When #5 — hook เรียกใช้ฟังก์ชันนี้แทนโค้ด inline
- [x] **Checkpoint 1** — `npm run test` ต้องผ่านและ quote ผลจริง · `npm run build` 0 error
      · ยืนยันว่าเคส "cache miss → offline" fail ก่อนแก้ T001 และ pass หลังแก้

## Phase 2 — ให้ทุกหน้าใช้ค่าจาก hook (ปลายน้ำ)

- [x] **T003** `dev-builder` — `FloatingVehiclePanel.tsx`: เปลี่ยน `kmh` มาจาก `vehicle.speedKmh`
      · **แสดง `0` เมื่อไม่มีข้อมูลสด** (ไม่ใช่ `—` — พี่โตสั่ง: จอด/ออฟไลน์ = ศูนย์จริง)
      · แสดงบล็อกความเร็วทุกสถานะรวม `offline` (เดิม `:239` ซ่อนของ offline ทิ้ง)
      · เพิ่มป้ายอายุข้อมูลใต้เวลาเมื่อ fix เก่ากว่า 5 นาที ใช้ `formatDistanceToNow`
      + locale `th` (`date-fns` มีใน deps แล้ว)
- [x] **T004** `dev-builder` [P] — `TelematicsPage.tsx:179` + `VehicleDetailPage.tsx:242,355`:
      ใช้ `v.speedKmh` แทน `knotsToKmh(v.position?.speed)` · `stale` ใช้ `hasLiveData` จาก hook
- [x] **T005** `dev-builder` [P] — `FleetPage.tsx:92,121,450` + `DashboardPage.tsx:404`:
      ใช้ `v.speedKmh` — รวม CSV export (ห้ามส่งความเร็วเก่าออกไฟล์รายงาน)
      และ preset filter บรรทัด 450 (กรองด้วยความเร็วเก่า = ผลกรองผิด)
- [x] **Checkpoint 2** — `grep -rn "position?\.speed\|position\.speed" src/` เหลือเฉพาะจุดที่
      ต้องใช้ค่าดิบจริง (TripReplay history) · `npm run build` + `npm run lint` 0

## Phase 3 — ยืนยันกับข้อมูลจริง

- [x] **T006** `test-runner` — รัน `npm run dev` เปิด `/app/map` ด้วย Playwright:
      นับการ์ดที่มี badge `จอดดับเครื่อง` พร้อมความเร็ว > 0 → ต้องเป็น **0**
      · ยืนยัน `moving+idle+stopped+offline == total` ที่ footer
- [x] **T007** `dev-builder` — เทียบจำนวนก่อน/หลังแก้ (stopped ลดเท่าไร offline เพิ่มเท่าไร)
      รายงานตัวเลขจริงให้พี่โตเห็นว่ากระทบกี่คัน
- [x] **Checkpoint 3** — Done When ครบ 7 ข้อ · commit + push + CI เขียว (ตาม memory
      `toh-plan-commit-rule`) · อัปเดต memory ไฟล์ `traccar-positions-cache-gap`

## ที่ตรวจแล้วว่า *ไม่ใช่* ต้นตอ — อย่าเสียเวลาซ้ำ

- ❌ **timezone / `effectiveTime()`** — คำนวณถูกแล้ว `23/08` คือเวลา fix จริง ไม่ใช่ค่าเพี้ยน
- ❌ **Traccar server TZ** — แก้แล้ว commit `0ffe76c` (`TZ=UTC`) ยืนยันด้วย raw payload
- ❌ **`b6db3fb` fallback** — ไม่ใช่บั๊ก มันกู้พิกัดได้ 121/121 · ปัญหาคือ *ปลายทาง* ใช้ผิด
- ❌ **`/api/positions` cache gap** — รู้อยู่แล้วและมี fallback ครอบแล้ว ไม่ต้องแก้ซ้ำ
- ❌ **สีสถานะ** — `#EA4335` แดง / `#9AA0A6` เทา ถูกตามสเปค ไม่แตะ

## ข้อจำกัดของ session นี้

credential Traccar ใน `.env.local` / `server/.env` / `docker/.env` **401 ทั้ง 3 ชุด**
และ SSH เข้า VM `34.142.244.40:22` timeout จาก IP นี้ → **ยืนยันตัวเลข production สดไม่ได้**
จึงพิสูจน์ด้วยการ replay logic จากโค้ดจริงแทน (ผลตรงกับภาพเป๊ะ) และ Phase 3 จะรัน
`npm run dev` ในเครื่องเพื่อยืนยัน — ถ้าพี่โตมี credential ที่ใช้ได้ บอกได้ หนูจะวัด production ให้ด้วย
