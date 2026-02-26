'use strict';
const express = require('express');
const SearchHistory = require('../models/SearchHistory');

const router = express.Router();

/**
 * GET /api/v1/history
 * Optional query param: ?sessionId=<string>
 *
 * Authentication (via soft middleware in server.js):
 *   - Signed-in user  → filter by userId
 *   - Anonymous       → filter by sessionId (if provided)
 *   - Neither         → return []
 *
 * Response 200: Array of up to 50 history items, newest first.
 * Each item: { searchId, tags, results, imagePath, createdAt }
 */
router.get('/', async (req, res, next) => {
  try {
    let filter;

    if (req.user?.sub) {
      filter = { userId: req.user.sub };
    } else if (req.query.sessionId) {
      filter = { sessionId: req.query.sessionId };
    } else {
      return res.json([]);
    }

    const docs = await SearchHistory.find(filter)
      .sort({ createdAt: -1 })
      .limit(50)
      .select('_id tags results imagePath createdAt')
      .lean();

    const items = docs.map((d) => ({
      searchId: d._id.toString(),
      tags: d.tags,
      results: d.results,
      imagePath: d.imagePath,
      createdAt: d.createdAt,
    }));

    console.log(`[History] ✅  ${items.length} item(s) for ${req.user?.sub ? `user ${req.user.sub}` : `session ${req.query.sessionId}`}`);
    return res.json(items);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
