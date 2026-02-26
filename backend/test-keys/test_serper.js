'use strict';
/**
 * test_serper.js
 * Tests SERPER_API_KEY by firing a minimal Google Shopping search.
 * Run: node test-keys/test_serper.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const https = require('https');

(async () => {
  const key = process.env.SERPER_API_KEY;
  if (!key || key.startsWith('your_')) {
    console.error('[Serper] ❌  SERPER_API_KEY is not set in .env');
    process.exit(1);
  }

  console.log('[Serper] Testing key:', key.slice(0, 8) + '...');

  // No region filter (gl) so results aren't sparse; real searches will use gl:'lk'
  const payload = JSON.stringify({ q: 'red linen shirt', hl: 'en', num: 5 });

  const options = {
    hostname: 'google.serper.dev',
    path: '/shopping',
    method: 'POST',
    headers: {
      'X-API-KEY': key,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  await new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode === 200) {
          const parsed = JSON.parse(data);
          const count = parsed.shopping?.length ?? 0;
          console.log(`[Serper] ✅  Key is VALID. Received ${count} shopping results.`);
          if (count > 0) console.log('[Serper]    First result:', parsed.shopping[0].title);
          resolve();
        } else if (res.statusCode === 401) {
          console.error('[Serper] ❌  401 Unauthorized – key is invalid or exhausted.');
          reject(new Error('Invalid key'));
        } else {
          console.error(`[Serper] ❌  Unexpected status ${res.statusCode}:`, data);
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
})().catch((err) => {
  console.error('[Serper] ❌ ', err.message);
  process.exit(1);
});
