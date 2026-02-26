'use strict';
/**
 * test_all.js  –  Run all API key tests sequentially.
 * Usage: npm run test:keys   OR   node test-keys/test_all.js
 */
const { execSync } = require('child_process');
const path = require('path');

const tests = [
  { name: 'Gemini', file: 'test_gemini.js' },
  { name: 'Serper', file: 'test_serper.js' },
  { name: 'Maps', file: 'test_maps.js' },
  { name: 'OpenAI', file: 'test_openai.js' },
];

let passed = 0;
let failed = 0;

console.log('\n══════════════════════════════════════════');
console.log('  Go4 API Key Test Suite');
console.log('══════════════════════════════════════════\n');

for (const t of tests) {
  console.log(`\n── ${t.name} ${'─'.repeat(40 - t.name.length)}`);
  try {
    execSync(`node ${path.join(__dirname, t.file)}`, { stdio: 'inherit' });
    passed++;
  } catch {
    failed++;
  }
}

console.log('\n══════════════════════════════════════════');
console.log(`  Results: ${passed} passed  /  ${failed} failed`);
console.log('══════════════════════════════════════════\n');
process.exit(failed > 0 ? 1 : 0);
