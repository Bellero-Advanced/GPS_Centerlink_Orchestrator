# 🔧 คู่มือกู้คืน Account Admin

**ปัญหา:** Login ไม่ได้ — account `admin_gpsthailand` หายหรือถูกลบ

---

## 🚨 วิธีแก้ไข (เลือก 1 วิธี)

### วิธีที่ 1: ใช้ GCP Console (แนะนำ)

1. เปิด [GCP Console](https://console.cloud.google.com)
2. ไปที่ VM instance: `gps-thailand-vm`
3. คลิก **SSH** (เปิด browser terminal)
4. รันคำสั่งนี้:

```bash
docker exec bellerox-postgres psql -U traccar -d traccar -c "
INSERT INTO tc_users (name, email, hashedpassword, administrator, readonly, devicelimit, userlimit, devicereadonly, limitcommands, disablereports, fixedtime, expirationtime, token, attributes)
VALUES ('Admin GPS Thailand', 'admin_gpsthailand', 'D033E22AE348AEB5660FC2140AEC35850C4DA997', true, false, -1, 0, false, false, false, false, NULL, NULL, '')
ON CONFLICT (email) DO UPDATE SET hashedpassword = 'D033E22AE348AEB5660FC2140AEC35850C4DA997', administrator = true
RETURNING id, name, email;
"
```

5. ลอง login ใหม่:
   - Email: `admin_gpsthailand`
   - Password: `admin`

---

### วิธีที่ 2: ใช้ SQL File

1. SSH เข้า server:
   ```bash
   ssh nupakorn_m@34.142.244.40
   ```

2. Upload file `fix-account.sql` ไปยัง server

3. รันคำสั่ง:
   ```bash
   docker exec -i bellerox-postgres psql -U traccar -d traccar < fix-account.sql
   ```

---

### วิธีที่ 3: Login ด้วย Admin Account อื่น

ถ้า SSH ไม่ได้ ลองใช้ admin account อื่นก่อน:

**Account 1:**
- Email: `admin`
- Password: `admin` (default)

**Account 2:**
- Email: `deploy@gps.bellerox.com`
- Password: *(ถ้ารู้)*

**Account 3:**
- Email: `test@bellerox.com`
- Password: *(ถ้ารู้)*

หลัง login สำเร็จ → ไปที่ **Settings > Users** → สร้าง user ใหม่

---

## 🔍 ตรวจสอบ Users ที่มี

```bash
docker exec bellerox-postgres psql -U traccar -d traccar -c "
SELECT id, name, email, administrator, readonly 
FROM tc_users 
WHERE administrator = true 
ORDER BY id;
"
```

---

## 📝 Account Details

| Field | Value |
|-------|-------|
| **Name** | Admin GPS Thailand |
| **Email** | admin_gpsthailand |
| **Password** | admin |
| **Administrator** | Yes |
| **Device Limit** | Unlimited (-1) |

---

## ⚠️ หมายเหตุ

- Password `admin` เป็น default — **ควรเปลี่ยนทันที**
- Hash SHA1: `D033E22AE348AEB5660FC2140AEC35850C4DA997`
- Traccar ใช้ SHA1 สำหรับ hash password
- Account จะถูกสร้างหรืออัพเดท (ON CONFLICT DO UPDATE)

---

## 🔐 เปลี่ยน Password หลัง Login

1. Login สำเร็จแล้ว
2. คลิก user menu (มุมขวาบน)
3. Settings > Account
4. Change Password
5. ใส่ password ใหม่ (อย่างน้อย 8 ตัวอักษร)
6. Save

---

## 📞 ติดปัญหา?

1. **SSH timeout** → ใช้ GCP Console SSH แทน
2. **Docker not found** → `docker ps` เช็ค container
3. **Database error** → `docker logs bellerox-postgres`
4. **ยัง login ไม่ได้** → Clear browser cache + cookies

---

**สรุป:** ใช้ GCP Console SSH → รัน SQL command → Login ด้วย `admin_gpsthailand` / `admin` ✅
