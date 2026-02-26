'use strict';
const axios = require('axios');

const SERPER_ENDPOINT = 'https://google.serper.dev/shopping';

/**
 * Query Google Shopping via Serper.dev.
 *
 * @param {string} searchQuery - Product search query from Gemini.
 * @param {object} opts
 * @param {string} [opts.gl='us']  Country code. 'lk' (Sri Lanka) returns near-zero
 *                                 Google Shopping listings, so 'us' is the practical
 *                                 default until a local catalogue is available.
 * @param {string} [opts.hl='en']  Language.
 * @param {number} [opts.num=10]   Max results to return.
 * @returns {Promise<Array<{title,price,link,thumbnail,source,rating,ratingCount}>>}
 */
async function searchShopping(searchQuery, { gl = 'us', hl = 'en', num = 20 } = {}) {
  const response = await axios.post(
    SERPER_ENDPOINT,
    { q: searchQuery, gl, hl, num },
    {
      headers: {
        'X-API-KEY': process.env.SERPER_API_KEY,
        'Content-Type': 'application/json',
      },
      timeout: 12_000,
    }
  );

  const shopping = response.data?.shopping ?? [];

  // Serper returns imageUrl, not thumbnail — normalize to internal field name
  return shopping.map((item) => ({
    title: item.title ?? 'Untitled',
    price: item.price ?? null,
    link: item.link ?? null,
    thumbnail: item.imageUrl ?? item.thumbnail ?? null,
    source: item.source ?? null,
    rating: typeof item.rating === 'number' ? item.rating : null,
    ratingCount: typeof item.ratingCount === 'number' ? item.ratingCount : null,
  }));
}

module.exports = { searchShopping };
