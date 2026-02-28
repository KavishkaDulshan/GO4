'use strict';
const axios = require('axios');

const SERPER_ENDPOINT = 'https://google.serper.dev/shopping';

/**
 * Query Google Shopping via Serper.dev.
 *
 * @param {string} searchQuery - Product search query.
 * @param {object} opts
 * @param {string} [opts.gl='us']       Country code (e.g. 'lk', 'in', 'gb').
 * @param {string} [opts.hl='en']       Language.
 * @param {number} [opts.num=40]        Max results to request.
 * @param {string} [opts.location]      City/region string for localised results.
 * @returns {Promise<Array>} Normalised product list
 */
async function searchShopping(searchQuery, { gl = 'us', hl = 'en', num = 40, location } = {}) {
  const body = { q: searchQuery, gl, hl, num };
  if (location) body.location = location;

  const response = await axios.post(
    SERPER_ENDPOINT,
    body,
    {
      headers: {
        'X-API-KEY': process.env.SERPER_API_KEY,
        'Content-Type': 'application/json',
      },
      timeout: 12_000,
    }
  );

  const shopping = response.data?.shopping ?? [];

  // Helper: detect base64 data URIs (unusable as HTTP image URLs)
  const isBase64 = (url) => typeof url === 'string' && url.startsWith('data:');
  const safeUrl  = (url) => (isBase64(url) ? null : url ?? null);
  const logUrl   = (url) => isBase64(url) ? `[base64-img ~${Math.round(url.length / 1024)}KB]` : (url ?? '(none)');

  // Log a compact summary of the first raw item for diagnostics
  if (shopping.length > 0) {
    const sample = shopping[0];
    console.log('[Serper] Fields from first result:', Object.keys(sample).join(', '));
    console.log('[Serper] imageUrl:', logUrl(sample.imageUrl));
    console.log('[Serper] thumbnail:', logUrl(sample.thumbnail));
  }

  const mapped = shopping.map((item) => {
    const imageUrl =
      safeUrl(item.imageUrl)
      ?? safeUrl(item.image)
      ?? safeUrl(item.thumbnailUrl)
      ?? null;

    const thumbnail = safeUrl(item.thumbnail) ?? imageUrl;

    const extensions = Array.isArray(item.extensions)
      ? item.extensions.filter((e) => typeof e === 'string')
      : [];

    return {
      title:         item.title         ?? 'Untitled',
      price:         item.price         ?? null,
      originalPrice: item.originalPrice ?? null,
      link:          item.link          ?? null,
      imageUrl,
      thumbnail,
      source:        item.source        ?? null,
      rating:        typeof item.rating     === 'number' ? item.rating     : null,
      ratingCount:   typeof item.ratingCount === 'number' ? item.ratingCount : null,
      delivery:      item.delivery      ?? item.shippingPrice ?? null,
      offers:        typeof item.offers === 'number' ? item.offers : null,
      extensions,
    };
  });

  // Sort: items with a valid image first
  const sorted = [...mapped].sort((a, b) => {
    if (a.thumbnail && !b.thumbnail) return -1;
    if (!a.thumbnail && b.thumbnail) return 1;
    return 0;
  });

  const withImg = sorted.filter((i) => i.thumbnail).length;
  console.log(`[Serper] ${sorted.length} results, ${withImg} with image`);
  return sorted;
}

module.exports = { searchShopping };
