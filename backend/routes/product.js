'use strict';
const express = require('express');
const router = express.Router();
const { enrichProduct } = require('../services/geminiEnrichService');

/**
 * POST /api/v1/product/enrich
 * Body: { title, category?, source?, price? }
 * Returns: { description, specifications, features, compatibility, bestFor }
 */
router.post('/enrich', async (req, res, next) => {
  try {
    const { title, category, source, price } = req.body;
    if (!title || typeof title !== 'string') {
      return res.status(400).json({ error: '"title" is required' });
    }

    console.log(`[Enrich] Enriching: "${title.slice(0, 60)}"`);
    const enriched = await enrichProduct({ title, category, source, price });
    console.log(`[Enrich] ✅ OK — ${enriched.specifications?.length ?? 0} specs, ${enriched.features?.length ?? 0} features`);

    res.json(enriched);
  } catch (err) {
    console.error('[Enrich] ❌', err.message);
    next(err);
  }
});

module.exports = router;
