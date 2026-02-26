'use strict';
/**
 * test_openai.js
 * Tests OPENAI_API_KEY by listing available models (cheapest possible call).
 * Run: node test-keys/test_openai.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const https = require('https');

(async () => {
  const key = process.env.OPENAI_API_KEY;
  if (!key || key.startsWith('your_')) {
    console.warn('[OpenAI] ⚠️   OPENAI_API_KEY is not set in .env – skipping.');
    console.warn('[OpenAI]     Add your key to .env then re-run: node test-keys/test_openai.js');
    process.exit(0);
  }

  console.log('[OpenAI] Testing key:', key.slice(0, 7) + '...');

  const options = {
    hostname: 'api.openai.com',
    path: '/v1/models',
    method: 'GET',
    headers: { Authorization: `Bearer ${key}` },
  };

  await new Promise((resolve, reject) => {
    https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode === 200) {
          const parsed = JSON.parse(data);
          const whisper = parsed.data.find((m) => m.id.includes('whisper'));
          console.log('[OpenAI] ✅  Key is VALID.');
          if (whisper) console.log('[OpenAI]    Whisper model available:', whisper.id);
          else console.log('[OpenAI]    ⚠️  No Whisper model found – check org access.');
          resolve();
        } else if (res.statusCode === 401) {
          console.error('[OpenAI] ❌  401 – Key is invalid or expired.');
          reject(new Error('Invalid key'));
        } else {
          console.error(`[OpenAI] ❌  HTTP ${res.statusCode}:`, data);
          reject(new Error(`HTTP ${res.statusCode}`));
        }
      });
    }).on('error', reject).end();
  });
})().catch((err) => {
  console.error('[OpenAI] ❌ ', err.message);
  process.exit(1);
});
