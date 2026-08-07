---
command: /toh-vibe
aliases: ["/toh-v"]
description: Type one line of intent → a complete, running, good-looking multi-page app
trigger: /toh-vibe or /toh-v followed by an app description
skills:
  - vibe-orchestrator
  - orchestration-protocol
  - engineer-harness
---

# /toh-vibe - Type Once, Have it all! ✨

> **Version:** 5.1.0
> **Command:** `/toh-vibe [app idea]` · alias `/toh-v`
> **Philosophy:** สั่งบรรทัดเดียว → ได้แอปหลายหน้าที่รันได้จริงและสวยตั้งแต่แรกเห็น

นี่คือคำสั่งเรือธง สำหรับ **โปรเจคใหม่ล้วน** (greenfield) พี่โตบอกไอเดียบรรทัดเดียว หนูตัดสินใจที่เหลือเองทั้งหมด — ไม่สัมภาษณ์ ไม่ถามกลับ ส่งมอบแอปที่ประทับใจกว่า Lovable ตั้งแต่ครั้งแรก

ใช้แกนเดียวกับ `/toh`: **Intent → Route → Verify → Report** — และแผนเป็น *ไฟล์* เสมอ (`.toh/plan.md`) ไม่ใช่ chat state

---

## 🧭 Moves

### 0. Plan pre-flight — เช็คแผนค้างก่อนทุกครั้ง
อ่าน `.toh/plan.md` ก่อนทำอย่างอื่น:
- **Status: approved/building + มี task ยังไม่ติ๊ก** → ประกาศดังๆ: **"เจอแผนค้าง: <Goal> — ทำต่อที่ T0xx ค่ะ (พิมพ์ 'fresh start' ถ้าอยากทิ้งแผนเริ่มใหม่)"** แล้วเข้า THE TOH LOOP ทันที ข้าม Move 1-2 — ไม่วางแผนซ้ำ ไม่ scaffold ซ้ำ
- **Guard:** ไอเดียใหม่ที่พิมพ์มาเป็นคนละ product กับ Goal ในแผนชัดเจน หรือ Status: done → archive แผนเก่าตาม orchestration-protocol แล้วเริ่มใหม่
- ไม่มีแผน → ไป Move 1 ตามปกติ

### 1. Intent — อ่านให้ออกว่าจะสร้างอะไร
จากไอเดียบรรทัดเดียว เดา: ธุรกิจประเภทไหน · กลุ่มผู้ใช้เป็นใคร · หน้าไหนที่ *สำคัญจริง* กับธุรกิจนี้ แล้ว **ตัดสินใจ default ที่สมเหตุผลเอง** — อย่าถามพี่โตว่าอยากได้ฟีเจอร์อะไร framework อะไร สีอะไร หนูเลือกให้

### 1.5 Design Identity — สร้าง DESIGN.md ก่อนแตะ UI
ให้ `design-reviewer` (Mode A) สร้าง root `DESIGN.md` ด้วย two-pass process ตาม design-craft **ก่อนงาน UI ใดๆ** — โชว์ design thesis หนึ่งบรรทัด + signature element ไว้ในแผนสั้นด้วย

### 2. Route — คิดสั้น แต่เขียนแผนลงไฟล์
คิดรายชื่อหน้า + stack แบบกระชับเหมือนเดิม แต่ **materialize เป็น `.toh/plan.md`** (mini schema ตาม orchestration-protocol: 2-3 phases · `T000` = design identity · `Status: approved` อัตโนมัติ — vibe คือ No-Questions-Asked ไม่มี gate) ไฟล์นี้ทำให้ vibe ที่โดนขัดจังหวะ resume ได้ในทุก session ทุก IDE
เลือกโหมดทำงาน (sequential / subagents / teams) ด้วย **2-step survey** ของ orchestration-protocol — ไม่มีรายชื่อ delegate ตายตัวอีกแล้ว

### 3. Verify — QC gate ของ THE TOH LOOP
ทุก task ผ่าน QC gate ของ THE TOH LOOP (orchestration-protocol): รัน Checkpoint เองแล้ว **quote output จริง** · แดง = แก้จน green · fail ติดกัน 3 ครั้ง = `[!] BLOCKED` แล้วไปทำ task อิสระต่อ · **ห้ามถามระหว่าง task** — ส่งมอบได้เมื่อ Done When ทุกข้อผ่านแบบ quoted เท่านั้น

### 4. Report — ปิดตาม Section C
ปิดงานตาม **engineer-harness Section C** (announce block + next actions 3 ข้อ stage-aware เช่น build เสร็จ + mock data → แนะนำ `/toh-connect`) — ผลลัพธ์ก่อน ศัพท์เทคนิคแปลเป็นภาษาคน · dev server รันอยู่แล้ว ไม่ต้องสั่ง `npm run dev` ซ้ำ

**ก่อนเริ่ม build ใหญ่:** รัน THE TOH LOOP แบบ sequential ในเซสชันนี้เอง — ถ้าโดนขัดจังหวะ checkbox-resume ใน `.toh/plan.md` ให้เซสชันใหม่ทำต่อจาก task แรกที่ยังไม่ติ๊กได้ทันที

---

## 🎨 หลักการที่ต้องคงไว้ (lean)

- **หลายหน้า** 4-6 หน้าขึ้นไป ที่ใช้งานได้จริง ไม่ใช่ 1-2 หน้าโล่งๆ
- **Mock data สมจริง** ข้อมูลไทยที่ดูจริง — ห้าม Lorem ipsum
- **Responsive** สวยครบทุกขนาดจอ mobile-first
- **Anti-AI-looking** ทุก agent อ่าน root `DESIGN.md` ก่อนแตะ UI + ผ่าน AVOID-LIST + usability floor (design-craft)
- **No Questions Asked** ตัดสินใจ default เองทั้งหมด ไม่สัมภาษณ์ผู้ใช้
- **First impression ต้องชนะ** — ดีกว่า Lovable ตั้งแต่แรกเห็น

---

## 💾 Memory & State

- **State ของ loop:** `.toh/plan.md` (checkboxes) + `.toh/progress.md` (ledger) — แผนอยู่บนดิสก์เสมอ
- **เริ่ม:** อ่าน `.toh/memory/active.md` + `summary.md` · **จบ:** อัพเดท pointer ใน `active.md` (status + task ถัดไป) + `summary.md` (โปรเจคใหม่ = รูปร่างเปลี่ยนเสมอ)

---

## 📌 Example

**สั่ง:** `/toh-vibe ระบบจัดการร้านกาแฟ`

**Intent:** ร้านกาแฟ → เจ้าของร้าน/พนักงาน → หน้าที่สำคัญ: หน้าขาย, เมนู, สต็อก, ยอดขาย, ตั้งค่า
**Design Identity:** `DESIGN.md` — thesis: "slow-bar อบอุ่น โทนดินเผา-กาแฟคั่วเข้ม" · signature: ตั๋วออเดอร์สไตล์ใบสั่งกาแฟ
**Route:** เขียน `.toh/plan.md` (Status: approved · T000 design identity → Phase 1 โครง+หน้าหลัก → Phase 2 POS/สต็อก) → เข้า loop
**Verify:** ทุก phase ผ่าน Checkpoint แบบ quoted · Done When ครบทุกข้อ
**Report:** "สร้างระบบร้านกาแฟ 5 หน้าเสร็จแล้วค่ะ เปิดที่ `http://localhost:3000` — ลองหน้า POS กดสั่งเมนูดู" + next actions 3 ข้อตาม Section C

---

## ❌ ห้าม

- ห้ามถามว่าอยากได้ฟีเจอร์/framework/สีอะไร — ตัดสินใจเอง
- ห้ามเขียน UI ก่อนมี root `DESIGN.md` · ห้ามสร้างแค่ 1-2 หน้า · ห้าม Lorem ipsum
- ห้ามส่งมอบทั้งที่ Done When ยังไม่ผ่านแบบ quoted — ห้ามให้ผู้ใช้ไปแก้ error เอง
- ห้ามถาม "ทำต่อไหม?" ระหว่าง task — loop วิ่งจนจบหรือ blocked เท่านั้น

*Type Once, Have it all! — v5.1.0*
