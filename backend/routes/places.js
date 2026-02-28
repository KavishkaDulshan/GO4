'use strict';
const express = require('express');
const axios   = require('axios');

const router = express.Router();

const NEARBY_URL  = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
const TEXT_URL    = 'https://maps.googleapis.com/maps/api/place/textsearch/json';

// ── Category → Search strategies ──────────────────────────────────────────────
//
// Each strategy: { type, keyword }
//   type    – a valid Google Places type used in Nearby Search for precise
//             server-side filtering (far more reliable than free-text queries)
//   keyword – additional hint sent alongside the type
//
// Multiple strategies are tried in order; unique results are merged.
// Using type=electronics_store+keyword="phone accessories" is orders of
// magnitude more reliable than text-searching "phone accessories store near me".
//
// Full Google Places type reference:
// https://developers.google.com/maps/documentation/places/web-service/supported_types

function resolveStrategies(category, productName) {
  const cat  = (category    || '').toLowerCase().replace(/[_\-]/g, ' ').trim();
  const name = (productName || '').toLowerCase().trim();
  const all  = `${cat} ${name}`;
  const hit  = (...terms) => terms.some((t) => all.includes(t));

  // ── Mobile phones & accessories ───────────────────────────────────────────
  if (hit('iphone', 'samsung', 'pixel', 'oneplus', 'xiaomi', 'redmi', 'oppo', 'vivo',
          'huawei', 'realme', 'motorola', 'nokia', 'smartphone', 'mobile phone',
          'phone case', 'phone cover', 'back cover', 'screen protector', 'phone charger',
          'charging cable', 'mobile charger', 'phone stand', 'sim card', 'tempered glass',
          'phone holder', 'phone accessory', 'mobile accessory')) {
    return [
      { type: 'electronics_store', keyword: 'mobile phone accessories store'    },
      { type: 'electronics_store', keyword: 'mobile phone shop'                 },
      { type: 'shopping_mall',     keyword: 'mobile phone accessories'          },
    ];
  }

  // ── Laptops & computers ───────────────────────────────────────────────────
  if (hit('laptop', 'notebook', 'macbook', 'chromebook', 'desktop computer',
          'hard disk', 'ssd', 'ram', 'graphics card', 'gpu', 'cpu', 'processor',
          'motherboard', 'computer mouse', 'keyboard', 'monitor', 'usb hub')) {
    return [
      { type: 'electronics_store', keyword: 'laptop computer store'             },
      { type: 'electronics_store', keyword: 'computer hardware shop'            },
      { type: 'shopping_mall',     keyword: 'computer laptop accessories'       },
    ];
  }

  // ── Audio & headphones ────────────────────────────────────────────────────
  if (hit('headphone', 'earphone', 'earbuds', 'airpods', 'speaker', 'soundbar',
          'bluetooth speaker', 'neckband', 'wireless headset', 'wired headphone')) {
    return [
      { type: 'electronics_store', keyword: 'headphones audio electronics store' },
      { type: 'electronics_store', keyword: 'sound audio equipment shop'          },
    ];
  }

  // ── Cameras & photography ─────────────────────────────────────────────────
  if (hit('camera', 'dslr', 'mirrorless', 'camera lens', 'tripod', 'photography',
          'action camera', 'gopro', 'webcam', 'memory card')) {
    return [
      { type: 'electronics_store', keyword: 'camera photography store'          },
      { type: 'electronics_store', keyword: 'camera accessories shop'            },
    ];
  }

  // ── Televisions & displays ────────────────────────────────────────────────
  if (hit('television', ' tv ', 'smart tv', 'oled', 'qled', 'projector', 'tv stand')) {
    return [
      { type: 'electronics_store', keyword: 'television display store'          },
      { type: 'electronics_store', keyword: 'home appliance electronics shop'   },
    ];
  }

  // ── Smartwatches & wearables ─────────────────────────────────────────────
  if (hit('smartwatch', 'fitness tracker', 'apple watch', 'galaxy watch',
          'fitbit', 'garmin', 'mi band', 'wearable')) {
    return [
      { type: 'electronics_store', keyword: 'smartwatch wearable store'         },
      { type: 'jewelry_store',     keyword: 'smartwatch accessories shop'        },
    ];
  }

  // ── Wristwatches (non-smart) ──────────────────────────────────────────────
  if (hit('wristwatch', 'analog watch', 'quartz watch', 'luxury watch',
          'watch strap', 'watch band') && !hit('smartwatch', 'fitness tracker')) {
    return [
      { type: 'jewelry_store',     keyword: 'wristwatch store'                  },
      { type: 'store',             keyword: 'watch shop'                         },
    ];
  }

  // ── Gaming & consoles ────────────────────────────────────────────────────
  if (hit('gaming', 'playstation', 'xbox', 'nintendo', 'switch',
          'game controller', 'gaming headset', 'gaming chair', 'video game')) {
    return [
      { type: 'electronics_store', keyword: 'video game console store'          },
      { type: 'store',             keyword: 'gaming accessories shop'            },
      { type: 'shopping_mall',     keyword: 'game store'                         },
    ];
  }

  // ── General electronics (catch-all) ──────────────────────────────────────
  if (hit('electronic', 'gadget', 'tech', 'device', 'appliance')) {
    return [
      { type: 'electronics_store', keyword: `${name || category} store`         },
      { type: 'shopping_mall',     keyword: 'electronics shop'                   },
    ];
  }

  // ── Shoes & footwear ─────────────────────────────────────────────────────
  if (hit('shoes', 'sneakers', 'boots', 'slippers', 'sandals', 'loafers',
          'running shoe', 'sports shoe', 'footwear')) {
    return [
      { type: 'shoe_store',     keyword: productName || 'shoe footwear store'   },
      { type: 'clothing_store', keyword: 'shoes footwear accessories'            },
    ];
  }

  // ── Clothing & fashion ────────────────────────────────────────────────────
  if (hit('t-shirt', ' shirt', 'dress', 'jacket', 'coat', 'hoodie', 'sweater',
          'blouse', 'trouser', 'jeans', 'skirt', 'clothing', 'apparel',
          'fashion', 'outfit', 'kurta', 'saree', 'lehenga')) {
    return [
      { type: 'clothing_store',   keyword: productName || 'clothing apparel'    },
      { type: 'department_store', keyword: 'fashion store clothing'              },
    ];
  }

  // ── Jewelry ──────────────────────────────────────────────────────────────
  if (hit('ring', 'necklace', 'bracelet', 'earring', 'pendant',
          'jewel', 'gold ', 'silver ', 'diamond', 'gemstone')) {
    return [
      { type: 'jewelry_store', keyword: productName || 'jewelry gold shop'      },
      { type: 'store',         keyword: 'gold silver jewelry store'              },
    ];
  }

  // ── Bags & luggage ────────────────────────────────────────────────────────
  if (hit('bag', 'handbag', 'backpack', 'purse', 'wallet', 'luggage', 'suitcase', 'travel bag')) {
    return [
      { type: 'clothing_store',   keyword: 'bags accessories leather goods'     },
      { type: 'department_store', keyword: 'bags luggage travel accessories'    },
    ];
  }

  // ── Eyewear ──────────────────────────────────────────────────────────────
  if (hit('glasses', 'sunglasses', 'eyewear', 'optical', 'spectacle', 'contact lens', 'reading glass')) {
    return [
      { type: 'store', keyword: 'optical eyewear glasses store'                 },
    ];
  }

  // ── Furniture ─────────────────────────────────────────────────────────────
  if (hit('sofa', 'couch', 'furniture', 'dining table', 'chair', 'wardrobe',
          'bookshelf', 'cabinet', 'desk', 'bed frame', 'closet')) {
    return [
      { type: 'furniture_store',  keyword: productName || 'furniture shop'      },
      { type: 'home_goods_store', keyword: 'furniture interior store'            },
    ];
  }

  // ── Kitchen & home appliances ─────────────────────────────────────────────
  if (hit('frying pan', 'cookware', 'knife set', 'blender', 'toaster', 'kettle',
          'coffee maker', 'air fryer', 'rice cooker', 'oven', 'microwave',
          'refrigerator', 'washing machine', 'kitchen appliance', 'dishwasher')) {
    return [
      { type: 'home_goods_store', keyword: 'kitchen appliances store'           },
      { type: 'hardware_store',   keyword: 'home appliance shop'                 },
      { type: 'department_store', keyword: 'kitchen accessories store'           },
    ];
  }

  // ── Home décor & textiles ─────────────────────────────────────────────────
  if (hit('mattress', 'pillow', 'bedding', 'duvet', 'bed sheet', 'curtain',
          'rug', 'carpet', 'lamp', 'home decor', 'decoration', 'wallpaper', 'cushion')) {
    return [
      { type: 'home_goods_store', keyword: productName || 'home decor store'    },
      { type: 'department_store', keyword: 'home furnishing interior shop'       },
    ];
  }

  // ── Toys & games ──────────────────────────────────────────────────────────
  if (hit('toy', 'lego', 'puzzle', 'rubik', 'action figure', 'doll',
          'stuffed animal', 'board game', 'jigsaw', 'remote control car')) {
    return [
      { type: 'store',            keyword: 'toy children game shop'             },
      { type: 'department_store', keyword: 'toys games store'                    },
    ];
  }

  // ── Sports & fitness ──────────────────────────────────────────────────────
  if (hit('sport', 'fitness', 'yoga mat', 'dumbbell', 'gym equipment',
          'cycling', 'bicycle', 'cricket', 'football', 'basketball',
          'badminton', 'tennis', 'swimming', 'hiking', 'camping', 'trekking')) {
    return [
      { type: 'store',            keyword: 'sporting goods fitness equipment shop' },
      { type: 'department_store', keyword: 'sports accessories store'               },
    ];
  }

  // ── Beauty & cosmetics ───────────────────────────────────────────────────
  if (hit('lipstick', 'foundation', 'mascara', 'blush', 'eyeshadow', 'concealer',
          'skincare', 'moisturizer', 'serum', 'face wash', 'toner', 'sunscreen',
          'perfume', 'fragrance', 'cologne', 'cosmetic', 'makeup', 'beauty')) {
    return [
      { type: 'beauty_salon',     keyword: 'cosmetics beauty store'             },
      { type: 'store',            keyword: 'beauty products makeup shop'         },
      { type: 'department_store', keyword: 'beauty cosmetics counter'            },
    ];
  }

  // ── Pharmacy & health ────────────────────────────────────────────────────
  if (hit('medicine', 'supplement', 'vitamin', 'protein powder', 'whey protein',
          'pharmacy', 'painkiller', 'antibiotic', 'first aid', 'health product')) {
    return [
      { type: 'pharmacy', keyword: productName || 'pharmacy chemist medical store' },
      { type: 'store',    keyword: 'health supplement nutrition shop'               },
    ];
  }

  // ── Books & stationery ───────────────────────────────────────────────────
  if (hit('book', 'novel', 'textbook', 'stationery', 'pen ', 'pencil',
          'office supply', 'notebook paper', 'printer cartridge')) {
    return [
      { type: 'book_store', keyword: productName || 'books stationery shop'    },
      { type: 'store',      keyword: 'books office supplies stationery'         },
    ];
  }

  // ── Pet supplies ──────────────────────────────────────────────────────────
  if (hit('pet food', 'dog collar', 'cat litter', 'fish tank', 'aquarium',
          'bird cage', 'pet toy', 'pet bed', 'pet grooming', 'pet supply')) {
    return [
      { type: 'pet_store', keyword: productName || 'pet shop supplies'          },
    ];
  }

  // ── Musical instruments ──────────────────────────────────────────────────
  if (hit('guitar', 'piano', 'keyboard instrument', 'drum', 'violin',
          'flute', 'ukulele', 'musical instrument')) {
    return [
      { type: 'store', keyword: 'musical instrument shop'                       },
    ];
  }

  // ── Automotive accessories ────────────────────────────────────────────────
  if (hit('tyre', 'tire ', 'car seat cover', 'car accessory', 'motor oil',
          'car part', 'car battery', 'wiper blade', 'dash cam', 'car charger',
          'automotive', 'vehicle part')) {
    return [
      { type: 'car_repair',  keyword: 'auto parts car accessories shop'        },
      { type: 'car_dealer',  keyword: 'automotive accessories store'            },
    ];
  }

  // ── Food & grocery ────────────────────────────────────────────────────────
  if (hit('grocery', 'snack', 'food item', 'beverage', 'soft drink',
          'coffee bean', 'loose tea', 'chocolate bar', 'sauce', 'spice', 'cereal')) {
    return [
      { type: 'supermarket',        keyword: productName || 'grocery supermarket' },
      { type: 'convenience_store',  keyword: 'grocery food shop'                    },
    ];
  }

  // ── Generic fallback ─────────────────────────────────────────────────────
  // Use the raw product name as keyword and fan out across shopping destinations.
  const kw = productName || category || 'retail';
  return [
    { type: 'store',            keyword: `${kw} shop near me`                  },
    { type: 'department_store', keyword: kw                                     },
    { type: 'shopping_mall',    keyword: `${kw} store`                          },
  ];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function mergeUnique(existing, incoming) {
  const seen = new Set(existing.map((p) => p.placeId).filter(Boolean));
  for (const p of incoming) {
    if (p.placeId && !seen.has(p.placeId)) {
      seen.add(p.placeId);
      existing.push(p);
    }
  }
  return existing;
}

function toPlace(p) {
  return {
    placeId:          p.place_id             ?? null,
    name:             p.name                 ?? 'Store',
    // nearbysearch returns `vicinity`, textsearch returns `formatted_address`
    address:          p.formatted_address    ?? p.vicinity ?? '',
    lat:              p.geometry?.location?.lat ?? null,
    lng:              p.geometry?.location?.lng ?? null,
    rating:           p.rating               ?? null,
    userRatingsTotal: p.user_ratings_total   ?? null,
    openNow:          p.opening_hours?.open_now ?? null,
    types:            p.types                ?? [],
  };
}

// ── GET /nearby ───────────────────────────────────────────────────────────────
/**
 * GET /api/v1/places/nearby
 *
 * Query params:
 *   category    {string}  – product category from Gemini (e.g. "Electronics")
 *   productName {string}  – product name from Gemini (e.g. "iPhone SE 2 back cover")
 *   lat         {number}  – device latitude
 *   lng         {number}  – device longitude
 *
 * Strategy:
 *   1. Resolve 2-3 search strategies from category+productName using the comprehensive
 *      category map above (each strategy: Google Places type + keyword).
 *   2. When location is available: use Nearby Search API with type+keyword+rankby=distance.
 *      This guarantees only actual stores of that type are returned, ranked closest-first.
 *   3. When no location: fall back to Text Search (still better-keyworded than before).
 *   4. Merge unique results by placeId; return up to 20.
 *
 * Response 200: { places: [...] }
 */
router.get('/nearby', async (req, res, next) => {
  try {
    const { category = '', productName = '', lat, lng } = req.query;

    if (!category && !productName) {
      return res.status(400).json({ error: 'Provide at least one of: category, productName' });
    }

    const apiKey = process.env.GOOGLE_MAPS_SERVER_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'GOOGLE_MAPS_SERVER_KEY not configured' });
    }

    const strategies  = resolveStrategies(category, productName);
    const hasLocation = Boolean(lat && lng);
    let   allPlaces   = [];

    for (const { type, keyword } of strategies) {
      if (allPlaces.length >= 20) break;

      try {
        if (hasLocation) {
          // ── Nearby Search with type + rankby=distance ────────────────────
          // Returns only genuine stores of the given Place type, sorted by
          // proximity.  No radius cap means we cast a wider net automatically.
          const { data } = await axios.get(NEARBY_URL, {
            params: {
              location: `${lat},${lng}`,
              rankby:   'distance',       // closest-first, no fixed radius cap
              type,                        // strict Google Places type filter
              keyword,                     // additional keyword refinement
              key:      apiKey,
            },
            timeout: 9_000,
          });

          if (data.status === 'OK' || data.status === 'ZERO_RESULTS') {
            const batch = (data.results ?? []).slice(0, 20).map(toPlace);
            mergeUnique(allPlaces, batch);
            console.log(
              `[Places/Nearby] type="${type}" keyword="${keyword}" → ` +
              `${batch.length} result(s) (running total ${allPlaces.length})`
            );
          } else {
            console.warn(`[Places/Nearby] status=${data.status} ` +
              `type="${type}" keyword="${keyword}" – ${data.error_message ?? ''}`);
          }

        } else {
          // ── Text Search fallback when GPS unavailable ─────────────────────
          const { data } = await axios.get(TEXT_URL, {
            params: { query: `${keyword}`, key: apiKey },
            timeout: 9_000,
          });

          if (data.status === 'OK' || data.status === 'ZERO_RESULTS') {
            const batch = (data.results ?? []).slice(0, 20).map(toPlace);
            mergeUnique(allPlaces, batch);
            console.log(`[Places/Text] keyword="${keyword}" → ${batch.length} result(s)`);
          } else {
            console.warn(`[Places/Text] status=${data.status} for "${keyword}"`);
          }
        }

      } catch (stratErr) {
        // A strategy failing shouldn't abort the whole request – log and continue
        console.warn(
          `[Places] strategy {type=${type}, keyword="${keyword}"} ` +
          `error: ${stratErr.message}`
        );
      }
    }

    console.log(
      `[Places] Final: ${allPlaces.length} place(s) ` +
      `for category="${category}" product="${productName}"`
    );
    return res.json({ places: allPlaces.slice(0, 20) });

  } catch (err) {
    next(err);
  }
});

// ── GET /details ──────────────────────────────────────────────────────────────
/**
 * GET /api/v1/places/details
 *
 * Query params:
 *   placeId {string} – Google Places placeId
 *
 * Response 200: { openNow, weekdayText, phone, website, mapsUrl }
 */
router.get('/details', async (req, res, next) => {
  try {
    const { placeId } = req.query;

    if (!placeId) {
      return res.status(400).json({ error: 'placeId param is required' });
    }

    const apiKey = process.env.GOOGLE_MAPS_SERVER_KEY;
    if (!apiKey) {
      return res.status(500).json({ error: 'GOOGLE_MAPS_SERVER_KEY not configured' });
    }

    const { data } = await axios.get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      {
        params: {
          place_id: placeId,
          fields:   'opening_hours,formatted_phone_number,website,url',
          key:      apiKey,
        },
        timeout: 8_000,
      }
    );

    if (data.status !== 'OK') {
      console.warn(`[Places/Details] ${data.status} for ${placeId}`);
      return res.status(502).json({ error: `Places Details API: ${data.status}` });
    }

    const r = data.result ?? {};
    return res.json({
      openNow:     r.opening_hours?.open_now     ?? null,
      weekdayText: r.opening_hours?.weekday_text ?? [],
      phone:       r.formatted_phone_number       ?? null,
      website:     r.website                      ?? null,
      mapsUrl:     r.url                          ?? null,
    });

  } catch (err) {
    next(err);
  }
});

module.exports = router;
