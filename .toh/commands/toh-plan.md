---
command: /toh-plan
aliases: ["/toh-p"]
description: See the plan first, approve once, then the whole plan gets built autonomously
trigger: /toh-plan or /toh-p followed by a feature request or PRD
skills:
  - plan-orchestrator
  - orchestration-protocol
  - engineer-harness
---

# /toh-plan - The Brain v3.0 🧠

> **Version:** 3.0.0
> **Command:** `/toh-plan [request หรือ PRD]` · alias `/toh-p`
> **Philosophy:** เห็นแผนก่อน อนุมัติครั้งเดียว แล้วหนูสร้างเองจนจบ

คำสั่งนี้สำหรับพี่โตที่ **อยากเห็นแผนก่อนลงมือ** — หนูวิเคราะห์ เขียนแผนเป็นไฟล์ `.toh/plan.md` คุยปรับกันได้เต็มที่ ขอไฟเขียวแค่ *ครั้งเดียว* จากนั้นสร้างทั้งแผนอัตโนมัติ (โปรเจคใหม่ที่ไม่ต้องดูแผน → `/toh-vibe`)

ใช้แกน 4 Moves: **Intent → Draft → Confirm → Execute**

---

## 🧭 4 Moves

### 1. Intent — เข้าใจก่อน
อ่าน memory ก่อนเสมอ (block ด้านล่าง) แล้ววิเคราะห์ request/PRD: ธุรกิจอะไร ผู้ใช้เป็นใคร ฟีเจอร์ไหนสำคัญจริง แตะ UI / logic / backend อะไรบ้าง — ช่วงนี้คุยกับพี่โตได้อิสระ ถาม-ตอบ-ปรับได้เต็มที่ ยังไม่ต้องรีบเขียนแผน

### 2. Draft — แผนคือไฟล์ ไม่ใช่ข้อความแชท
เขียน `.toh/plan.md` ตาม schema ใน **orchestration-protocol Section D** (Goal · Stack · Pages · Done When · Phases ที่แต่ละ task มี T-ID + agent + file path จริง + `[P]` เมื่อขนานได้ + **Checkpoint** ปิดท้ายทุก phase · Status: draft):
- โปรเจคที่มี UI → `T000 design-reviewer — generate root DESIGN.md` เป็น task แรกเสมอ (design identity ก่อน UI ทุกชิ้น)
- Phase 1 = งาน UI shell ให้พี่โตเห็นหน้าจอเร็วที่สุด

แล้วเล่าให้พี่โตฟังแบบ **ย่อ**: เป้าหมาย · กี่ phase · กี่ task · ประมาณกี่นาที — ห้าม dump ตารางยักษ์หรือทั้งไฟล์ใส่แชท

### 3. Confirm — ด่านอนุมัติด่านเดียว
ปิดท้ายด้วย 3 ทางเลือกนี้เสมอ:

1. **Go** — สร้างทั้งแผนอัตโนมัติ ตรวจเองทุกขั้น เสร็จแล้วค่อยรายงาน (recommended)
2. **ปรับแผน** — บอกได้เลยว่าแก้ตรงไหน
3. **เก็บไว้ก่อน** — แผนอยู่ที่ `.toh/plan.md` สั่ง `/toh-vibe` เมื่อไหร่ก็ได้

พร้อมบอกให้ชัด: **หลัง "Go" หนูจะไม่หยุดถามระหว่าง phase** — ทำยาวจนเสร็จหรือจนเจอ blocker จริงๆ เท่านั้น

### 4. Execute — Go แล้วไปยาว
พี่โตพิมพ์ "Go" → ตั้ง `Status: approved` ใน plan.md แล้วรัน **THE TOH LOOP** (orchestration-protocol Section E) ทั้งลูป: survey → pick task → implement → QC gate ที่รันจริงและ **quote ผลจริง** → tick checkbox → task ถัดไปโดยไม่ถาม จนทุก Done When ผ่าน

จบงานปิดด้วย **engineer-harness Section C** (announce block + 3 next actions) — ตามสัญญานั้นเป๊ะ ไม่ improvise


---

## 💾 Memory (Tiered)

- **Tier 1 — อ่านเสมอ:** `.toh/memory/active.md` (งานค้าง + pointer ไป plan.md) · `summary.md` (ภาพรวมโปรเจค)
- **Tier 2 — งาน build/code:** `architecture.md` + `components.md` · งาน debug: `changelog.md`
- **Tier 3 — เมื่อถูกอ้างถึงเท่านั้น:** `decisions.md` · `agents-log.md`
- **ระหว่าง loop:** checkbox ใน `plan.md` + ledger `.toh/progress.md` คือ state จริง — `active.md` เก็บแค่ pointer (status + task ถัดไป) ห้าม dump แผนลงไป

---

## 🎯 Trigger สั้นๆ

- เริ่มวางแผน: `/toh-plan ...` · `/toh-p ...` · "วางแผน..."
- อนุมัติ: "Go" / "ลุย" / "เริ่มเลย" → Execute ทั้งแผน
- ปรับ: "เพิ่ม xxx" / "ตัด xxx" → แก้ plan.md แล้วสรุปย่อใหม่

---

## ❌ ห้าม

- ห้ามลงมือสร้างก่อนพี่โตเห็นแผนและกด Go (ด่านเดียว แต่ต้องมี)
- ห้ามหยุดถามระหว่าง phase หลัง Go — checkpoint เป็นตัวคุมความคืบหน้า ไม่ใช่พี่โต
- ห้าม tick checkbox โดยไม่มี quoted passing run (Evidence Rule ใน engineer-harness)
- ห้ามโชว์ตาราง status ระหว่างทำงาน — หนึ่ง status line ต่อ task พอ

*The Brain — plan once, approve once, built to the end · v3.0.0*
