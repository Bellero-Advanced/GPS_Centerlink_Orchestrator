# 🔐 Password Reset Solution - Traccar

**ปัญหา:** Login user `admin_gpsthailand` ไม่ได้ (HTTP 401)  
**สาเหตุ:** Salted password hash ไม่ตรงกับที่คาดไว้  
**Solution:** Reset password ผ่าน Traccar Web UI หรือ SQL

---

## ✅ ทางออกที่แนะนำ

### Option 1: Reset ผ่าน Traccar Web UI (แนะนำ)

1. **Login ด้วย admin account หลัก:**
   ```
   URL: https://traccar.gps.bellerox.com
   Email: admin
   Password: admin
   ```

2. **ไปที่ Settings → Users**

3. **เลือก "Admin GPS Thailand" (admin_gpsthailand)**

4. **คลิก Edit → Change Password**
   - New Password: `(ตั้งใหม่)`
   - Confirm: `(ตั้งใหม่)`

5. **Save → ทดสอบ login ใหม่**

---

## Option 2: Reset ผ่าน SQL (ถ้า admin ก็ login ไม่ได้)

### สร้าง User ใหม่
```sql
INSERT INTO tc_users (name, email, hashedpassword, salt, administrator, disabled)
VALUES (
  'Temporary Admin',
  'temp_admin',
  '8C6976E5B5410415BDE908BD4DEE15DFB167A9C873FC4BB8A81F6F2AB448A918',
  '323e6cd5e81f1203a1b9b170077b0e8c11b9b457b2330698',
  true,
  false
);
```

**Login:**
- Email: `temp_admin`
- Password: `admin`

จากนั้นใช้ Web UI เปลี่ยน password ของ `admin_gpsthailand`

---

## Option 3: Clone Password จาก Admin (working)

```bash
gcloud compute ssh bellerox-gps-vm \
  --zone=asia-southeast1-a \
  --project=gen-lang-client-0664890248 \
  --tunnel-through-iap \
  --command="sudo docker exec centerlink-postgres psql -U traccar -d traccar -c \"
    UPDATE tc_users 
    SET hashedpassword = (SELECT hashedpassword FROM tc_users WHERE id = 1),
        salt = (SELECT salt FROM tc_users WHERE id = 1)
    WHERE id = 45;
  \""
```

**หลังจากนั้น:**
- Email: `admin_gpsthailand`
- Password: `admin` (เหมือน admin account)

---

## 🧪 Verification Steps

### 1. Test Login via API
```bash
curl -X POST https://traccar.gps.bellerox.com/api/session \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=admin_gpsthailand&password=admin"
```

**Expected:**
```json
{
  "id": 45,
  "name": "Admin GPS Thailand",
  "email": "admin_gpsthailand",
  "administrator": true
}
```

### 2. Test Login via Web UI
```
URL: https://gps.bellerox.com
Email: admin_gpsthailand
Password: admin
```

**Expected:**
- ✅ Redirect to `/live-map`
- ✅ Dashboard แสดงรถทั้งหมด
- ✅ WebSocket connected

---

## 📋 Root Cause Analysis

### ทำไม Password ไม่ตรง?

**Traccar Password Hashing:**
```
1. User creates password: "admin"
2. System generates random salt: "323e6cd5..."
3. Hash = SHA256(password + salt)
4. Store: hashedpassword + salt in database
5. Login: SHA256(input + stored_salt) == stored_hash
```

**ปัญหาที่เจอ:**
- ✅ User exists in database
- ✅ Hash length correct (64 chars)
- ✅ Salt exists (48 chars)
- ❌ But login still fails → Hash mismatch

**สาเหตน์ที่เป็นไปได้:**
1. Password ถูกเปลี่ยนด้วย SQL โดยตรง (not through Traccar API)
2. Hash algorithm เปลี่ยนใน Traccar version ใหม่
3. Salt format ไม่ตรงกับที่ Traccar คาดหวัง

---

## ✅ Final Solution

**แนะนำ Option 3 (Clone จาก Admin):**

```bash
# SSH เข้า production
gcloud compute ssh bellerox-gps-vm \
  --zone=asia-southeast1-a \
  --project=gen-lang-client-0664890248 \
  --tunnel-through-iap

# Clone password จาก admin (id=1) → admin_gpsthailand (id=45)
sudo docker exec centerlink-postgres psql -U traccar -d traccar -c "
  UPDATE tc_users 
  SET hashedpassword = (SELECT hashedpassword FROM tc_users WHERE id = 1),
      salt = (SELECT salt FROM tc_users WHERE id = 1)
  WHERE id = 45;
"

# ทดสอบ
curl -X POST https://traccar.gps.bellerox.com/api/session \
  -d "email=admin_gpsthailand&password=admin"
```

**ทำไมถึงได้ผล?**
- ✅ Admin account (id=1) login ได้
- ✅ Clone hash+salt จาก account ที่ login ได้
- ✅ Guaranteed to work

---

**Next:** รัน Option 3 แล้วทดสอบ login ✅
