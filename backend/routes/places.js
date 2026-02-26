'use strict';
const express = require('express');
const axios = require('axios');

const router = express.Router();

/**
 * GET /api/v1/places/nearby
 *
 * Query params:
 *   query  {string}  – product/category to search for (e.g. "blue denim jacket")
 *   lat    {number}  – device latitude
 *   lng    {number}  – device longitude
 *   radius {number}  – search radius in metres (default 5000, max 50000)
 *
 * Uses Google Places Text Search API (no billing surprise: 1 request = 1 free QPS).
 *
 * Response 200:
 *   { places: [{ placeId, name, address, lat, lng, rating, types }] }
 */
router.get('/nearby', async (req, res, next) => {
  try {
    const { query, lat, lng, radius = 5000 } = req.query;

    if (!query) {
      return res.status(400).json({ error: 'query param is required' });
    }

    const apiKey = process.env.GOOGLE_MAPS_SERVER_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'GOOGLE_MAPS_SERVER_KEY not configured' });
    }

    // Build the location bias if coords supplied
    // Pass the query directly — the Flutter layer already builds a
    // purpose-specific store query (e.g. "electronics store", "toy store").
    const params = {
      query,
      key: apiKey,
    };
    if (lat && lng) {
      params.location = `${lat},${lng}`;
      params.radius = Math.min(Number(radius), 50000);
    }

    const { data } = await axios.get(
      'https://maps.googleapis.com/maps/api/place/textsearch/json',
      { params, timeout: 10_000 }
    );

    if (data.status !== 'OK' && data.status !== 'ZERO_RESULTS') {
      console.warn(`[Places] API error: ${data.status} – ${data.error_message ?? ''}`);
      return res.status(502).json({
        error: `Places API returned status: ${data.status}`,
        detail: data.error_message ?? null,
      });
    }

    const places = (data.results ?? []).slice(0, 15).map((p) => ({
      placeId: p.place_id,
      name: p.name,
      address: p.formatted_address,
      lat: p.geometry?.location?.lat ?? null,
      lng: p.geometry?.location?.lng ?? null,
      rating: p.rating ?? null,
      types: p.types ?? [],
    }));

    console.log(`[Places] "${query}" → ${places.length} place(s)`);
    return res.json({ places });

  } catch (err) {
    next(err);
  }
});

module.exports = router;
