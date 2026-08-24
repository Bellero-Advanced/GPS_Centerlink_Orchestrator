-- สร้างหรืออัพเดท account admin_gpsthailand
-- Password: admin (SHA1: D033E22AE348AEB5660FC2140AEC35850C4DA997)

INSERT INTO tc_users (
  name, 
  email, 
  hashedpassword, 
  administrator, 
  readonly, 
  devicelimit, 
  userlimit, 
  devicereadonly, 
  limitcommands, 
  disablereports, 
  fixedtime, 
  expirationtime, 
  token, 
  attributes
)
VALUES (
  'Admin GPS Thailand',
  'admin_gpsthailand',
  'D033E22AE348AEB5660FC2140AEC35850C4DA997',
  true,
  false,
  -1,
  0,
  false,
  false,
  false,
  false,
  NULL,
  NULL,
  ''
)
ON CONFLICT (email) DO UPDATE SET
  hashedpassword = 'D033E22AE348AEB5660FC2140AEC35850C4DA997',
  administrator = true,
  name = 'Admin GPS Thailand'
RETURNING id, name, email, administrator;

-- แสดง admin users ทั้งหมด
SELECT id, name, email, administrator, readonly 
FROM tc_users 
WHERE administrator = true 
ORDER BY id;
