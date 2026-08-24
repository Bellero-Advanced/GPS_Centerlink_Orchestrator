# 🔧 Fix 401 Login Error

## Root Cause
localStorage มี old Basic Auth token (`_basic`) ที่ไม่ match กับ password ปัจจุบัน

## Solution

### Option 1: Clear Browser Storage (แนะนำ)
```
1. เปิด https://gps.centerlink.co.th
2. กด F12 (Developer Tools)
3. ไปที่ Application > Storage > Local Storage
4. หา key "centerlink-gps-auth" → คลิกขวา Delete
5. ทำเช่นเดียวกันใน Session Storage
6. กด Cmd+Shift+R (hard reload)
7. Login ใหม่ด้วย:
   - Email: admin_gpsthailand
   - Password: admin_123
```

### Option 2: Run Console Command
```javascript
// กด F12 > Console > paste คำสั่งนี้
localStorage.removeItem('centerlink-gps-auth');
sessionStorage.removeItem('centerlink-gps-auth');
location.reload();
```

### Option 3: Code Fix (ป้องกันอนาคต)
เพิ่ม version check ใน authStore.ts:

```typescript
// Line 17
const STORE_KEY = 'centerlink-gps-auth-v2'; // เพิ่ม version → old token expired
```

---

## Verify
หลัง clear storage แล้ว:
- ✅ Console ไม่มี 401 errors
- ✅ Network tab: POST /api/session → 200 OK
- ✅ Map โหลดรถขึ้นมา
