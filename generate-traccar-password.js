const crypto = require('crypto');

// Generate random salt (24 bytes = 48 hex chars)
const salt = crypto.randomBytes(24).toString('hex');

// Password to hash
const password = 'password';

// Traccar uses: hex(salt + SHA-256(salt + password))
const combined = salt + password;
const hash = crypto.createHash('sha256').update(combined).digest('hex');
const traccarHash = (salt + hash).substring(0, 48);  // Traccar takes first 48 chars

console.log('Password:', password);
console.log('Salt (48 chars):', salt);
console.log('Hash (48 chars):', traccarHash);
console.log('');
console.log('SQL UPDATE:');
console.log(`hashedpassword = '${traccarHash}'`);
console.log(`salt = '${salt}'`);
