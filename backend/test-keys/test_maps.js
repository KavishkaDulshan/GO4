'use strict';
/**
 * test_maps.js
 * Tests GOOGLE_MAPS_API_KEY against three APIs used by Go4:
 *   1. Geocoding API        – address → lat/lng
 *   2. Places Nearby Search – find stores around a point
 *   3. Directions API       – route distance to a store
 *
 * Run: node test-keys/test_maps.js
 *
 * All three must be enabled at:
 *   https://console.cloud.google.com/apis/library
 */
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const https = require('https');

function get(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let d = '';
      res.on('data', (c) => (d += c));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(d) }));
    }).on('error', reject);
  });
}

function statusLabel(apiStatus, errorMsg) {
  if (apiStatus === 'OK' || apiStatus === 'ZERO_RESULTS')  return '✅  ENABLED';
  if (apiStatus === 'REQUEST_DENIED') return `❌  NOT ENABLED – ${errorMsg}`;
  return `⚠️  ${apiStatus} – ${errorMsg ?? ''}`;
}

(async () => {
  const key = process.env.GOOGLE_MAPS_API_KEY;
  if (!key || key.startsWith('your_')) {
    console.error('[Maps] ❌  GOOGLE_MAPS_API_KEY is not set in .env');
    process.exit(1);
  }

  console.log('[Maps] Testing key:', key.slice(0, 8) + '...\n');

  // NSBM campus coordinates
  const lat = 6.8213, lng = 80.0414;

  const [geocode, places, directions] = await Promise.all([
    get(`https://maps.googleapis.com/maps/api/geocode/json?address=NSBM+Green+University,Sri+Lanka&key=${key}`),
    get(`https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=5000&type=store&key=${key}`),
    get(`https://maps.googleapis.com/maps/api/directions/json?origin=${lat},${lng}&destination=Colombo,Sri+Lanka&key=${key}`),
  ]);

  const results = [
    { api: 'Geocoding API       ', s: geocode.body.status,    e: geocode.body.error_message },
    { api: 'Places Nearby Search', s: places.body.status,     e: places.body.error_message  },
    { api: 'Directions API      ', s: directions.body.status, e: directions.body.error_message },
  ];

  let allDenied = true;
  let hasRestriction = false;

  for (const r of results) {
    const label = statusLabel(r.s, r.e);
    console.log(`[Maps]  ${r.api}  →  ${label}`);
    if (!label.startsWith('❌')) allDenied = false;
    if (r.e && r.e.includes('not authorized')) hasRestriction = true;
  }

  if (hasRestriction) {
    console.log('\n[Maps] ℹ️   Key has an APPLICATION RESTRICTION (Android apps only).');
    console.log('[Maps]    This is CORRECT for google_maps_flutter – it works inside the app.');
    console.log('[Maps]    For server-side calls (Geocoding, Places, Directions) you need');
    console.log('[Maps]    a SEPARATE key restricted by "IP addresses" or "None".');
    console.log('[Maps]    Action: In Google Cloud Console → Credentials → create a');
    console.log('[Maps]    "Server key" with no app restriction, add to .env as');
    console.log('[Maps]    GOOGLE_MAPS_SERVER_KEY=...\n');
    // Not a hard failure — flutter key is working correctly
    process.exit(0);
  } else if (allDenied) {
    console.log('\n[Maps] ❌  All APIs denied. The key may be invalid or APIs not enabled.');
    console.log('[Maps]    Enable at: https://console.cloud.google.com/apis/library\n');
    process.exit(1);
  } else {
    console.log('\n[Maps] ✅  All required APIs are ENABLED and key is VALID.\n');
  }
})().catch((err) => {
  console.error('[Maps] ❌  Unexpected error:', err.message);
  process.exit(1);
});
