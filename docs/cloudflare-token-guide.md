# Cloudflare API Token — Full Permissions Guide

## วิธีสร้าง Token ที่ให้ Claude ทำได้ทุกอย่าง

Token ที่ใช้อยู่ (`cfut_...`) มี scope เฉพาะ Zone:DNS:Edit เท่านั้น  
สร้าง Token ใหม่แบบ Full Access ได้ตามขั้นตอนนี้:

---

## วิธีที่ 1 — Custom Token (แนะนำ, ปลอดภัยกว่า)

1. ไปที่ https://dash.cloudflare.com/profile/api-tokens
2. คลิก **"Create Token"**
3. เลือก **"Create Custom Token"** (ด้านล่างสุด)
4. ตั้งชื่อ: `Bellerox GPS Admin`
5. เพิ่ม Permissions ทั้งหมดนี้:

| Resource | Permission |
|----------|-----------|
| Zone → DNS | Edit |
| Zone → Zone | Edit |
| Zone → Zone Settings | Edit |
| Zone → Cache Purge | Purge |
| Account → Cloudflare Pages | Edit |
| Account → Workers Scripts | Edit |
| Account → Workers Routes | Edit |
| Account → Account Settings | Read |

6. Zone Resources: **All zones from account**
7. Account Resources: **All accounts**
8. TTL: ไม่ตั้ง (หรือตั้ง 1 ปี)
9. คลิก **"Continue to summary"** → **"Create Token"**
10. **Copy token ทันที** (แสดงครั้งเดียวเท่านั้น!)

---

## วิธีที่ 2 — Global API Key (Full access ทุกอย่าง)

> ⚠️ ใช้เฉพาะกรณีจำเป็น — ให้ access ทุกอย่างในบัญชี Cloudflare

1. ไปที่ https://dash.cloudflare.com/profile/api-tokens
2. เลื่อนลงไปที่ **"Global API Key"**
3. คลิก **"View"** → ยืนยัน password
4. Copy key

ใช้ร่วมกับ header:
```
X-Auth-Email: admin@jkt.co.th
X-Auth-Key: <global-api-key>
```

แทน `Authorization: Bearer <token>`

---

## Quick Reference — Permissions ที่แต่ละงานต้องการ

| งาน | Permission ที่ต้องการ |
|-----|---------------------|
| สร้าง DNS records | Zone:DNS:Edit |
| Deploy Cloudflare Pages | Account:Cloudflare Pages:Edit |
| Deploy Workers | Account:Workers Scripts:Edit |
| ตั้ง custom domain บน Pages | Account:Cloudflare Pages:Edit + Zone:Zone:Edit |
| Purge cache | Zone:Cache Purge:Purge |
| ดู analytics | Zone:Analytics:Read |

---

## ใช้งานกับ Claude

เมื่อได้ Token แล้ว วาง token เป็น argument ใน goal:

```
/goal CF_API_TOKEN=<your-full-token> จัดการ DNS และ Pages custom domain
```

หรือตั้งเป็น environment variable:
```bash
export CF_API_TOKEN="<your-full-token>"
```

---

## ตรวจสอบ Token ปัจจุบัน

```bash
curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer <your-token>" | python3 -m json.tool
```

ผลลัพธ์ควรแสดง `"status": "active"` และ permissions ที่มี
