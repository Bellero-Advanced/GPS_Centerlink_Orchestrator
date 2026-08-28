const crypto = require('crypto');

// Generate random salt (24 bytes = 48 hex chars)
const salt = crypto.randomBytes(24).toString('hex');

// Password to hash
const password = 'password';

// Traccar 6.x uses: SHA-256(password + salt) - password FIRST, then salt
const combined = password + salt;
const hash = crypto.createHash('sha256').update(combined).digest('hex');

console.log('Password:', password);
console.log('Salt (48 chars):', salt);
console.log('Hash (48 chars):', hash.substring(0, 48));
console.log('');
console.log('SQL UPDATE:');
console.log(`UPDATE tc_users SET`);
console.log(`  hashedpassword = '${hash.substring(0, 48)}',`);
console.log(`  salt = '${salt}'`);
console.log(`WHERE email = 'testadmin';`);
