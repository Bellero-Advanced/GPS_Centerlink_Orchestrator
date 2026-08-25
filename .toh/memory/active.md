---
updated: 2026-08-25
---

# Active Work

## ✅ Just Completed: DLT ส่งครบทุกคัน + Auto-index Partition (2026-08-25)

**อาการ:** DLT แต่ละรอบส่งไม่เท่ากัน (5→10 คัน) และบางคันไม่ส่งพร้อมคันอื่น

**ต้นตอ (วัดจาก production):** `useDltAutoSend` ดึงตำแหน่งด้วย `GET /api/positions` เปล่า
ซึ่งอ่านจาก **in-memory cache ของ Traccar** เท่านั้น — รถเปิด DLT ไว้ 42 คัน แต่ติดใน cache
แค่ 8 คัน และเปลี่ยนไปตามจังหวะที่ GPS ยิงเข้ามา → จำนวนต่อรอบจึงสุ่ม
**DLT ไม่ได้ปฏิเสธเลย** ทุก batch HTTP 200 · received == sent
(บั๊กเดียวกับ Vehicle Card ว่างที่แก้ใน `b6db3fb` แต่ path DLT ยังใช้ของเดิม)

**แก้:**
- `services/traccarService.ts` — `getPositionsForDevices()` รวม cache + DB fallback ที่เดียว
  คืนทั้งสองชุด เพื่อให้ status/speed คิดจาก live เท่านั้น (กันการ์ดเปลี่ยนสี)
- `hooks/useDltAutoSend.ts` — ใช้ชุด merged · คง rate-limit guard ข้าม tab ไว้
- `services/dltService.ts` — วน devices แทน positions (คันที่ไม่มี position จะไม่หายเงียบ)
  + แยกเหตุผลข้ามเป็น stale / future / badTimestamp / noPosition
- `pages/DLTPage.tsx` — คอลัมน์ "ข้าม" + tooltip + แผงรถที่ส่งไม่ได้เรียงตามอายุ
- `infrastructure/postgres/create-next-month-partition.sh` — เข้า git + สร้าง index `id`
  ให้ partition ใหม่ + backfill ย้อนหลังแบบ idempotent (CONCURRENTLY ถ้ามีข้อมูล)

**ผล:** ดึงได้ 42/42 คัน ใน 0.197s · ผ่านด่านสด 15 นาที **15 คัน** (จาก 8)
พิสูจน์บั๊ก partition: สร้าง `tc_positions_2026_10` มือ ได้ index แค่ 3 ตัว ไม่มี `_id_idx`
→ รัน script แล้วเป็น 4 ตัว all_valid=t ทั้ง 6 partition · GPS ไม่หยุดระหว่างรัน (load 0.10)

**Commit:** web `cd6b21c` · infra `b655891`

⚠️ **25 จาก 42 คัน ตำแหน่งเก่ากว่า 24 ชม.** — เป็นปัญหา SIM/ฮาร์ดแวร์หน้างาน แก้ด้วยโค้ดไม่ได้
ตอนนี้เห็นรายชื่อในแผง "ยานพาหนะที่ส่งไม่ได้" แล้ว ต้องไปตามที่หน้างาน
⚠️ อีก 9 ไฟล์ untracked ใน `bellerox-gps-web` ยังมีรหัสผ่านเปลือย — **ตั้งใจไม่ commit**

---

## 🎯 Next Steps
1. เปิด DLTPage รอ 1 รอบส่ง (60 วิ) ดูว่าคอลัมน์ "ข้าม" ขึ้นเลข และจำนวนส่งเพิ่มจาก 8
2. ไปตาม SIM/อุปกรณ์ 25 คันที่ GPS ไม่ส่งเข้ามาเกิน 24 ชม.
3. ลบ/gitignore ไฟล์ที่มีรหัสผ่าน 9 ไฟล์
4. Longdo API key ยังรั่วใน public repo 3 ไฟล์ + git history (พี่โตสั่งใช้ key เดิมไปก่อน)

---

## 📌 ค้างจากรอบก่อน

`.toh/memory/archive/plan-2026-08-22-cost-pipeline-reports-PARKED.md` — 30 done / 63 pending
(แผน cost/pipeline/reports) กู้กลับมาทำต่อได้ทุกเมื่อ
