# Plan: พิกัดต้องไม่หาย — แก้ position id ซ้ำข้าม partition

Status: completed 2026-08-25
Created: 2026-08-25 by /toh
Supersedes: plan-2026-08-25-vehicle-card-status-DONE.md (เสร็จ 7/7 · commit b50c6e8)

## Goal

พี่โตชี้ว่าการ์ดบอก **"ไม่มีพิกัดล่าสุด"** ทั้งที่เวลาอัปเดตคือ 25/08 วันนี้ และตั้งกฎชัด:

> "fix time ที่ส่งมาล่าสุดทุกครั้ง มันก็คู่กับพิกัด ดังนั้นมันต้องโชว์พิกัดตลอด ไม่มีหาย
> ต่อให้ออฟไลน์ หรือจอดดับเครื่องก็ต้องโชว์พิกัดล่าสุด"

ถูกต้องทุกคำ — GPS ส่ง fix time มาพร้อมพิกัดเสมอ ถ้าเวลามีแต่พิกัดหาย นั่นคือบั๊กฝั่งเรา

### ต้นตอ — `position id` ซ้ำข้าม partition (พิสูจน์แล้ว ไม่ใช่ทฤษฎี)

```
GET /api/positions?id=92932   → deviceId=36  fix 5 ส.ค.  lat 12.955   ← Traccar หยิบอันนี้
history ของ device 122         → deviceId=122 fix 25 ส.ค. lat 14.132   ← อันที่ถูกจริง
```

`id=92932` มี **สองแถว คนละ device คนละ partition** · `device.positionId` ชี้ค่าที่ถูก
แต่ `?id=` คืนแถวจาก partition ที่ id ชนกัน → `getPositionsByIds()` ได้ของรถคันอื่น

โค้ดปัจจุบันกรอง `p.deviceId !== d.id` ทิ้ง **ซึ่งถูกแล้ว** (ถ้าไม่ทิ้ง รถอยุธยาจะไปโผล่ชลบุรี
ห่างกัน 300 กม.) แต่ผลลัพธ์คือ **พิกัดหายเงียบ ๆ** ทั้งที่ GPS ส่งมาจริงเมื่อ 3 นาทีก่อน

นี่คือผลพวงจาก partition ที่ทำ PK uniqueness หาย — ตระกูลเดียวกับ [[tc-positions-missing-id-index]]

### วัดจริงทั้งฝูง 206 คัน (user `admin_gpsthailand`)

| ค่า | ผล |
|---|---|
| `GET /api/positions` (cache) | **29** |
| cache ไม่มี | **177** |
| `positionId` ชี้แถวของ**ตัวเอง** | 44 |
| `positionId` ชี้แถวของ**รถคันอื่น** | **72** (ในนั้น 66 คันส่งข้อมูลมา < 5 นาที) |

ไม่ใช่แค่ 4 คันที่พี่โตแคปมา — **72 คัน = 35% ของฝูง**

### ทางแก้ที่ทดสอบต้นทุนแล้ว

`?deviceId=<id>` คืน**พิกัดของตัวเองถูกต้องเสมอ** (ไม่ชนกับ partition อื่น เพราะกรองด้วย deviceId)

| วิธี | ต้นทุนจริงที่วัดได้ | ครอบคลุม |
|---|---|---|
| `?deviceId=` ยิงขนาน chunk 25 | **2.4 s** / 177 คัน | +48 คัน |
| history 7 วัน + กรอง deviceId | ~22 s / 65 คัน | +65 คัน |
| ~~batch `?deviceId=a&deviceId=b`~~ | 144 ms แต่คืน **0 แถว** | ❌ ใช้ไม่ได้ |

### 206 คัน แยก 3 กลุ่ม

| กลุ่ม | จำนวน | ต้องทำ |
|---|---|---|
| มีพิกัดแล้ว (cache) | 29 | ปกติ |
| กู้ได้ (`positionId > 0`) | **113** | ทำให้พิกัดกลับมา |
| `positionId=0` + `lastUpdate=null` | **64** | **"ยังไม่เชื่อม GPS"** (พี่โตสั่ง) |

64 คันนี้ไม่มีพิกัดในระบบจริง — device สร้างไว้แต่ยังไม่เคยติดตั้ง เรียก "ออฟไลน์" ผิดความหมาย

### 🔴 ผลพลอยได้ที่ต้องแก้ด้วย — DLT

`getPositionsForDevices()` (ใช้โดย `useDltAutoSend`) push `fallback` เข้า `merged` โดยเช็คแค่
`!cachedDeviceIds.has(p.deviceId)` → **แถวของรถคันอื่นหลุดเข้าไปได้** แล้ว DLT key ด้วย `p.deviceId`
= ตำแหน่งไปผูกกับรถผิดคัน

**ยังไม่เกิดความเสียหาย** เพราะด่าน `FRESH_WINDOW_MS = 15 นาที` ใน `classifyFreshness()`
ตัดแถวเก่า 20 วันทิ้งทั้งหมด → ไม่มีข้อมูลผิดส่งถึงกรมขนส่ง (ตรวจแล้ว)
แต่เป็นระเบิดเวลา: ถ้าแถวที่ id ชนกันบังเอิญสดพอ จะส่งพิกัดผิดคันไปให้ราชการ **ต้องปิดช่องนี้**

## Stack

ไม่มีของใหม่ — React Query + TypeScript strict ตาม `CLAUDE.md`
(service → hook → component · ไม่มี `any` · **ไม่เพิ่ม/เปลี่ยนสี 4 สถานะเดิม**)

## Done When

1. รถทุกคันที่มี `positionId > 0` **แสดงพิกัด** — ไม่มี "ไม่มีพิกัดล่าสุด" ในกลุ่มนี้
2. พิกัดที่แสดง **เป็นของรถคันนั้นจริง** (`p.deviceId === device.id` ทุกแถว ไม่มีข้อยกเว้น)
3. เวลาที่แสดงคู่กับพิกัดเสมอ — fix time กับพิกัดมาจาก**แถวเดียวกัน** ห้ามคนละแถว
4. 64 คันที่ไม่เคยส่งข้อมูล → ป้าย **"ยังไม่เชื่อม GPS"** ไม่ใช่ "ออฟไลน์"
5. DLT: แถวที่ `deviceId` ไม่ตรง **ไม่หลุด**เข้า `merged` เลย
6. โหลดหน้าแผนที่ไม่ช้าลงจนสังเกตได้ — fallback ชั้นแพงทำเบื้องหลัง ไม่บล็อก first paint
7. `npm run test` · `npm run build` 0 error · `npm run lint` ไม่เพิ่ม warning · CI เขียว

## Phase 1 — ปิดรูรั่วที่ service (ต้นน้ำ)

- [x] **T001** `src/services/traccarService.ts`: `getPositionsByIds()` รับ `Map<positionId, deviceId>`
      แล้ว **กรอง `p.deviceId` ต้องตรงกับที่ขอ** คืนเฉพาะแถวที่เจ้าของถูก · เพิ่ม
      `getPositionsByDeviceIds(ids)` ยิง `?deviceId=` ขนาน chunk 25 + กรอง `deviceId` (2.4 s/177 คัน)
- [x] **T002** `getPositionsForDevices()`: ใช้ตัวใหม่ทั้งสองชั้น · ยืนยันว่า `merged` มีแต่แถว
      ที่ `deviceId` ตรง (ปิดช่อง DLT ตาม Done When #5)
- [x] **Checkpoint 1** — unit test ยืนยันแถวเจ้าของผิดถูกกรองทิ้ง 100% · quote ผลจริง

## Phase 2 — hook ต่อ fallback 3 ชั้น + สถานะใหม่

- [x] **T003** `src/hooks/useDevices.ts`: fallback เป็นชั้น — (1) cache (2) `?deviceId=`
      (3) history 7 วัน สำหรับคันที่ยังไม่ได้ · ชั้น 3 แยก query แยก `enabled` ไม่บล็อก first paint
- [x] **T004** `src/lib/vehicleStatus.ts`: เพิ่ม `hasEverReported` (จาก `positionId > 0`)
      → `displayStatus: 'unlinked'` สำหรับคันที่ไม่เคยส่ง · **สีเทาอ่อนกว่า offline** ไม่แตะ 4 สีเดิม
      · อัปเดต `STATUS_TH`/`STATUS_COLOR` ทั้ง 13 ไฟล์ที่ใช้ `displayStatus` (grep ให้ครบ)
- [x] **Checkpoint 2** — เทสต์: partition sweep ต้องยังผ่านด้วย 5 สถานะ · build 0 error

## Phase 3 — ยืนยันกับ production จริง

- [x] **T005** วัดซ้ำด้วย `admin_gpsthailand` — รถที่มี `positionId > 0` ต้องมีพิกัด **113/113**
      · ทุกแถว `deviceId` ตรง · เทียบก่อน/หลังให้พี่โตเห็นตัวเลข
- [x] **T006** render test: การ์ดของ `2ฒฌ-3550` (คันในภาพ) ต้องโชว์พิกัด + เวลาจากแถวเดียวกัน
- [x] **Checkpoint 3** — Done When ครบ 7 ข้อ · commit + push + **รอ CI เขียว** · อัปเดต memory

## ที่ตรวจแล้วว่า *ไม่ใช่* ต้นตอ — อย่าเสียเวลาซ้ำ

- ❌ **`?id=` คืนหลายแถว** — คืนแถวเดียวเสมอ (ตรวจ 3 id) ปัญหาคือคืน**ผิดคัน** ไม่ใช่คืนเกิน
- ❌ **chunk 40 ยาวเกิน** — ขอ 116 ได้คืน 116 ครบ ไม่ได้หายจาก URL length
- ❌ **สิทธิ์ผู้ใช้** — `admin_gpsthailand` เห็น 206 คันครบ
- ❌ **timezone / `effectiveTime()`** — ถูกแล้ว ห้ามแตะ ดู [[timezone-7h-offset-root-cause]]
- ❌ **batch `?deviceId=a&deviceId=b`** — HTTP 200 แต่คืน 0 แถว ต้องยิงทีละคันขนานกัน
- ❌ **DLT ส่งข้อมูลผิดไปแล้ว** — ด่าน 15 นาทีกันไว้ทัน ยังไม่มีความเสียหาย แต่ต้องปิดช่อง
