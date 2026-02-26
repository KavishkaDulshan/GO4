'use strict';
/**
 * test_gemini.js
 * Tests GEMINI_API_KEY by sending a simple text prompt.
 * Run: node test-keys/test_gemini.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const { GoogleGenerativeAI } = require('@google/generative-ai');

(async () => {
  const key = process.env.GEMINI_API_KEY;
  if (!key || key.startsWith('your_')) {
    console.error('[Gemini] ❌  GEMINI_API_KEY is not set in .env');
    process.exit(1);
  }

  console.log('[Gemini] Testing key:', key.slice(0, 8) + '...');

  try {
    const genAI = new GoogleGenerativeAI(key);
    // gemini-1.5-flash/2.0-flash deprecated; 2.5-flash is the current stable model
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
    const result = await model.generateContent(
      'Reply with exactly: "Go4 Gemini connection successful."'
    );
    const text = result.response.text().trim();
    console.log('[Gemini] ✅  Response:', text);
    console.log('[Gemini] ✅  Key is VALID and quota is available.');
  } catch (err) {
    console.error('[Gemini] ❌  Error:', err.message);
    if (err.message.includes('API_KEY_INVALID')) {
      console.error('[Gemini]    → Key is invalid or revoked. Check Google AI Studio.');
    } else if (err.message.includes('quota')) {
      console.error('[Gemini]    → Quota exceeded. Check your usage limits.');
    }
    process.exit(1);
  }
})();
