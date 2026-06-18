/**
 * ============================================================
 * ELMENUS MACRO CALCULATOR - Background Service Worker
 * ============================================================
 * Handles:
 * 1. Listening to content script requests
 * 2. Persistent 1-hour caching using chrome.storage.local
 * 3. Sending POST requests to http://localhost:3000/api/nutrition/calculate
 * 4. Summing base item macros with selected add-on macros
 * 5. Formatting response payloads or forwarding backend error messages
 * ============================================================
 */

// ================================================================
// CONFIGURATION & GLOBAL STATE
// ================================================================

const API_ENDPOINTS = [
  'http://localhost:3000/api/nutrition/calculate',
  'http://127.0.0.1:3000/api/nutrition/calculate'
];
const CACHE_EXPIRATION_MS = 1000 * 60 * 60; // 1 hour

// ================================================================
// SERVICE WORKER MESSAGE LISTENERS
// ================================================================

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'fetchMacros') {
    handleFetchMacros(request, sendResponse);
    return true; // Keeps communication channel open for asynchronous sendResponse
  }

  if (request.action === 'clearCache') {
    handleClearCache(sendResponse);
    return true;
  }
});

// ================================================================
// LOGIC CONTROLLERS
// ================================================================

/**
 * Handles the calculation fetch request from the content script
 */
async function handleFetchMacros(request, sendResponse) {
  const { stateKey, restaurantName, itemName, itemDescription, size, price, addOns } = request;

  console.log('[BG] Received fetch request for state key:', stateKey);

  try {
    // 1. Check persistent local cache first
    const cachedItem = await getCacheItem(stateKey);
    if (cachedItem) {
      console.log('[BG] Cache HIT for key:', stateKey);
      sendResponse({
        success: true,
        data: cachedItem,
        source: 'local_cache'
      });
      return;
    }

    // 2. Fetch fresh macros from API
    console.log('[BG] Cache MISS. Fetching from backend API...');
    const freshData = await fetchMacrosFromBackend(restaurantName, itemName, itemDescription, size, addOns);

    if (freshData) {
      // 3. Store in local cache
      await setCacheItem(stateKey, freshData);

      sendResponse({
        success: true,
        data: freshData,
        source: 'api_server'
      });
    } else {
      sendResponse({
        success: false,
        error: 'Unable to resolve nutritional values'
      });
    }
  } catch (err) {
    console.warn('[BG] Error during handleFetchMacros:', err.message || err);
    sendResponse({
      success: false,
      error: err.message || 'Server or network calculation failure'
    });
  }
}

/**
 * Clears the entire chrome local storage cache
 */
async function handleClearCache(sendResponse) {
  try {
    await chrome.storage.local.clear();
    console.log('[BG] Local cache successfully cleared');
    sendResponse({ success: true });
  } catch (err) {
    console.warn('[BG] Failed to clear local cache:', err.message || err);
    sendResponse({ success: false, error: err.message });
  }
}

// ================================================================
// BACKEND API INTEGRATION
// ================================================================

/**
 * Calls the local Node backend server and aggregates base and addon macros
 */
async function fetchMacrosFromBackend(restaurantName, itemName, itemDescription, size, addOns) {
  // Enhancing the item name with size if it's not a standard 'Regular' size
  // This informs the AI of size portions for better nutritional estimates
  const finalItemName = size && size !== 'Regular' ? `${itemName} (${size})` : itemName;

  const requestBody = {
    restaurantName: restaurantName || 'Elmenus',
    itemName: finalItemName,
    itemDescription: itemDescription || '',
    addOns: addOns || []
  };

  console.log('[BG] Sending POST payload to backend:', requestBody);

  let lastError = null;

  for (const endpoint of API_ENDPOINTS) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'elm_prod_secret_key_9988'
        },
        body: JSON.stringify(requestBody)
      });

      if (!response.ok) {
        // Try to parse error details from server response
        let errorDetail = '';
        try {
          const errorJson = await response.json();
          errorDetail = errorJson.error || errorJson.message || '';
        } catch (_) { }

        throw new Error(errorDetail || `API Server returned status code ${response.status}`);
      }

      const result = await response.json();

      // API returns macros directly on the result object (not nested under result.item)
      if (result && result.success !== false && result.calories != null) {
        return {
          calories: result.calories,
          protein: result.protein,
          carbs: result.carbs,
          fats: result.fats,
          source: result.source === 'cache' ? 'Cached' : 'AI Generated'
        };
      }

      // Fallback: if success flag is explicitly false, treat as error
      if (result && result.success === false) {
        throw new Error(result.error || 'Backend returned an error response');
      }

      return null;
    } catch (err) {
      console.warn(`[BG] Endpoint fetch failed for ${endpoint}:`, err.message || err);
      lastError = err;
    }
  }

  // If we reach here, all endpoints failed
  throw lastError || new Error('All backend endpoints failed to respond');
}

// ================================================================
// LOCAL STORAGE CACHE HELPERS
// ================================================================

/**
 * Retrieves a cached item and verifies it has not expired yet
 */
async function getCacheItem(key) {
  try {
    const data = await chrome.storage.local.get(key);
    if (!data || !data[key]) {
      return null;
    }

    const cached = data[key];
    const age = Date.now() - cached.timestamp;

    if (age > CACHE_EXPIRATION_MS) {
      console.log('[BG] Cached item has expired, clearing key:', key);
      await chrome.storage.local.remove(key);
      return null;
    }

    return cached.payload;
  } catch (e) {
    console.error('[BG] Error accessing cache:', e);
    return null;
  }
}

/**
 * Persists an item in local storage with a timestamp
 */
async function setCacheItem(key, payload) {
  try {
    const entry = {
      payload: payload,
      timestamp: Date.now()
    };
    await chrome.storage.local.set({ [key]: entry });
    console.log('[BG] Successfully stored item in persistent cache');
  } catch (e) {
    console.error('[BG] Error writing to cache:', e);
  }
}

console.log('[BG] Elmenus Macro Calculator background worker active');
