const crypto = require('crypto');

// Known working credentials from database
const knownHash = 'b0aa00a1049188fa83363939f993766bb4e5951d56ea0e88';
const knownSalt = '2e0e185cc499012d92816b15c2675b5958677c677fe5fce2';

console.log('=== Analyzing existing admin hash ===');
console.log('Hash length:', knownHash.length);
console.log('Salt length:', knownSalt.length);
console.log('');

// Test different password combinations with this salt
const passwords = ['admin', 'Admin123', 'cl_changeme_2026!', 'password', 'centerlink'];

passwords.forEach(pwd => {
  // Method 1: password + salt
  const hash1 = crypto.createHash('sha256').update(pwd + knownSalt).digest('hex').substring(0, 48);
  
  // Method 2: salt + password
  const hash2 = crypto.createHash('sha256').update(knownSalt + pwd).digest('hex').substring(0, 48);
  
  console.log(`Password: ${pwd}`);
  console.log(`  pwd+salt: ${hash1.substring(0, 20)}... ${hash1 === knownHash ? '✅ MATCH!' : ''}`);
  console.log(`  salt+pwd: ${hash2.substring(0, 20)}... ${hash2 === knownHash ? '✅ MATCH!' : ''}`);
  console.log('');
});

// Also check what the admin password might have been set to via Traccar web UI
console.log('=== Trying default Traccar admin password ===');
const defaultPwd = 'admin';
const hash = crypto.createHash('sha256').update(defaultPwd + knownSalt).digest('hex').substring(0, 48);
console.log('Hash matches:', hash === knownHash ? '✅ YES' : '❌ NO');
