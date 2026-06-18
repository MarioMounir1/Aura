/**
 * ============================================================
 * ELMENUS MACRO CALCULATOR — Clean Rewrite Content Script
 * ============================================================
 * 
 * Architecture:
 *   Module 1 — Configurations & Global State
 *   Module 2 — Resilient DOM Scrapers (elmenus-specific)
 *   Module 3 — State Tracker & Polling Engine
 *   Module 4 — Messaging Bridge (background.js API connector)
 *   Module 5 — Premium Glassmorphic UI Renderer
 *   Module 6 — Lifecycle Initializer
 * ============================================================
 */

// ================================================================
// MODULE 1 — CONFIGURATIONS & GLOBAL STATE
// ================================================================

/** How often to poll the modal for state changes */
const POLLING_INTERVAL_MS = 400;

/** CSS class identifying our injected badge container */
const BADGE_CONTAINER_CLASS = 'macro-badge-container';

/** Active interval pointer */
let pollingInterval = null;

/** Lock key to prevent duplicate calculation calls */
let currentStateKey = null;

// ================================================================
// MODULE 2 — RESILIENT DOM SCRAPERS (UNIVERSAL)
// ================================================================

/**
 * Detects any open food-delivery item modal/dialog/sheet.
 * Uses ARIA semantics first (reliable across all React apps),
 * then falls back to common class patterns.
 */
function findModal() {
  const MODAL_SELECTORS = [
    // ── Semantic / ARIA — most reliable cross-platform ──
    'dialog[open]',
    '[role="dialog"]',
    '[aria-modal="true"]',
    // ── Elmenus ──
    '.modal-body',
    '.item-header',
    '.modal-content',
    // ── Class-name patterns common in food-delivery React apps ──
    '[class*="ItemModal"]',
    '[class*="itemModal"]',
    '[class*="ProductModal"]',
    '[class*="productModal"]',
    '[class*="BottomSheet"]',
    '[class*="bottomSheet"]',
    '[class*="SidePanel"]',
    '[class*="SlideIn"]',
    '[class*="ModalContent"]',
    '[class*="modalContent"]',
  ];

  for (const sel of MODAL_SELECTORS) {
    try {
      const candidates = document.querySelectorAll(sel);
      for (const el of candidates) {
        if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
        // Must be visible and large enough to be a real item modal
        const rect = el.getBoundingClientRect();
        if (rect.width > 200 && rect.height > 200) return el;
      }
    } catch (_) {}
  }
  return null;
}

/**
 * Clean option text by removing price decimals, EGP suffix, and trailing chars.
 */
function cleanText(text) {
  if (!text) return '';
  // Split on price pattern like "323.00 EGP" or "25 EGP" or "ج.م"
  let cleaned = text.split(/\d+(?:\.\d+)?\s*(?:EGP|LE|ج\.م)/i)[0];
  cleaned = cleaned.replace(/\d+(?:\.\d+)?\s*(?:EGP|LE|ج\.م)/gi, '');
  cleaned = cleaned.replace(/^[\s\-_|.,/()]+|[\s\-_|.,/()]+$/g, '').trim();
  return cleaned;
}

/**
 * Filter size words from typical toppings and foods.
 */
function isSizeText(text) {
  if (!text) return false;
  const lower = text.toLowerCase().replace(/_/g, ' ');
  const foodKeywords = /\b(?:cheese|sauce|bacon|patty|patties|beef|chicken|fries|drink|coke|cola|sprite|fanta|water|extra|add|topping|onion|mushroom|jalapeno|pickles|mayo|ketchup|mustard|garlic|peppers|tomato|lettuce|bread|bun|egg|ham|turkey|pepperoni|olives|ranch|barbecue|bbq|cheddar|mozzarella|swiss|blue\s+cheese|gravy|jalapenos)\b/i;

  if (foodKeywords.test(lower)) {
    return false;
  }

  const sizeKeywords = [
    /\b\d+\s*(?:gm|g|gram|kg|kilo|pcs|pieces|piece|oz|lbs?)\b/i,
    /\b(?:regular|medium|large|small|mega|giant|double|triple|single|quad|half|quarter|whole)\b/i,
    /\b(?:size|combo|solo|meal|sandwich\s+only|plain)\b/i,
    /\b\d+\s*["'\u201c]\b/i,
  ];

  return sizeKeywords.some(regex => regex.test(lower));
}

/**
 * Extracts base menu item name from title.
 */
function extractItemName() {
  const modal = findModal();
  const root = modal || document;

  // Known platform-specific selectors first
  const specificSelectors = [
    '.item-header h5.title',
    '[class*="itemName"]',
    '[class*="ItemName"]',
    '[class*="item-name"]',
    '[class*="productName"]',
    '[class*="ProductName"]',
    '[class*="product-name"]',
    '[class*="itemTitle"]',
    '[class*="ItemTitle"]',
  ];
  for (const sel of specificSelectors) {
    const el = root.querySelector(sel);
    if (el) {
      const text = el.textContent?.trim();
      if (text && text.length > 1 && text.length < 120) return text;
    }
  }

  // Generic: first meaningful heading that doesn't look like a section label
  const sectionKeywords = /^(select|choose|extras?|add-?ons?|drink|combo|topping|sauce|size)\b/i;
  const headings = root.querySelectorAll('h1, h2, h3, h4, h5, h6');
  for (const h of headings) {
    if (h.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
    const text = h.textContent?.trim();
    if (text && text.length > 1 && text.length < 120 && !sectionKeywords.test(text)) {
      return text;
    }
  }

  return null;
}

/**
 * Extracts menu item description.
 */
function extractItemDescription() {
  const modal = findModal();
  const root = modal || document;
  const baseName = extractItemName();

  const descriptionSelectors = [
    '.item-header p',
    '.item-header span',
    '[class*="itemDescription"]',
    '[class*="ItemDescription"]',
    '[class*="item-description"]',
    '[class*="productDescription"]',
    '[class*="ProductDescription"]',
    '[class*="product-description"]',
    'p[class*="desc" i]',
    'span[class*="desc" i]',
    'div[class*="desc" i]'
  ];

  for (const sel of descriptionSelectors) {
    try {
      const el = root.querySelector(sel);
      if (el) {
        const text = el.textContent?.trim();
        if (text && text.length > 5 && text.length < 500) {
          if (text.includes("Add to basket") || text.includes("سلة")) continue;
          if (baseName && text.toLowerCase() === baseName.toLowerCase()) continue;
          return text;
        }
      }
    } catch (_) {}
  }

  // Fallback: search for first p or span with substantial text under the modal
  const elements = root.querySelectorAll('p, span');
  for (const el of elements) {
    if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
    const text = el.textContent?.trim() || '';
    if (text.length > 15 && text.length < 300) {
      if (el.closest('button, label, input, [role="button"], [role="checkbox"], [role="radio"]')) continue;
      if (/^(select|choose|extras?|add-?ons?|drink|combo|topping|sauce|size)/i.test(text)) continue;
      if (baseName && text.toLowerCase() === baseName.toLowerCase()) continue;
      return text;
    }
  }

  return null;
}

/**
 * Extracts restaurant name from navigation breadcrumbs or headers.
 */
function extractRestaurantName() {
  const RESTAURANT_SELECTORS = [
    'h1.restaurant-name',
    '[class*="restaurant-name"]',
    '[class*="restaurantName"]',
    'nav [class*="breadcrumb"] a:last-of-type',
    '.breadcrumb-item:last-child a',
    '.restaurant-header h1',
    '.restaurant-info h1',
  ];

  for (const selector of RESTAURANT_SELECTORS) {
    const el = document.querySelector(selector);
    if (el) {
      const text = el.textContent.trim();
      if (text && text.length > 0 && text.length < 80) return text;
    }
  }

  // Fallback to title
  const parts = document.title.split(/[|\-–]/);
  if (parts.length > 0) {
    const candidate = parts[0].trim();
    if (candidate.toLowerCase() !== 'elmenus') return candidate;
  }

  return 'Elmenus';
}

/**
 * Scrapes selected menu item size.
 */
function extractActiveSize() {
  const modal = findModal();
  const root = modal || document;

  // Strategy 1: Standard HTML radio inputs (Elmenus & similar)
  const checkedInputs = root.querySelectorAll('input[type="radio"]:checked');
  for (const input of checkedInputs) {
    const wrapper = input.closest('label') || input.closest('li') || input.parentElement;
    if (wrapper) {
      const text = cleanText(wrapper.textContent);
      if (text && isSizeText(text)) return text;
    }
  }

  // Strategy 2: ANY element with role="radio" and aria-checked="true"
  // (covers div/span/li radio replacements used in React apps like Talabat)
  const ariaRadios = root.querySelectorAll('[role="radio"][aria-checked="true"]');
  for (const el of ariaRadios) {
    if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
    const text = cleanText(el.textContent);
    if (text && isSizeText(text)) return text;
  }

  // Strategy 3: ARIA listbox selected option
  const ariaSelected = root.querySelectorAll('[aria-selected="true"]');
  for (const el of ariaSelected) {
    if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
    const text = cleanText(el.textContent);
    if (text && text.length < 60 && isSizeText(text)) return text;
  }

  // Strategy 4: CSS active/selected class patterns (Mrsool & others)
  const activePatterns = [
    '.size-option.active',
    'label.active[for^="size"]',
    '[class*="--active"]',
    '[class*="--selected"]',
    '[class*="isSelected"]',
    '[class*="isChecked"]',
    '[class*="is-active"]',
    '[class*="Selected"][class*="option" i]',
    '[class*="Selected"][class*="size" i]',
  ];
  for (const pattern of activePatterns) {
    try {
      const els = root.querySelectorAll(pattern);
      for (const el of els) {
        if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
        if (el.querySelectorAll('*').length > 15) continue; // skip large containers
        const text = cleanText(el.textContent);
        if (text && text.length < 60 && isSizeText(text)) return text;
      }
    } catch (_) {}
  }

  return 'Regular';
}

/**
 * Scrapes selected add-ons.
 */
function extractAddOns() {
  const modal = findModal();
  const root = modal || document;
  const activeAddOns = [];

  // Strategy 1: Standard HTML checkboxes
  const checkedBoxes = root.querySelectorAll('input[type="checkbox"]:checked');
  checkedBoxes.forEach(box => {
    if (box.closest(`.${BADGE_CONTAINER_CLASS}`)) return;
    let wrapper = box.closest('label') || box.closest('li');
    if (!wrapper) {
      let curr = box.parentElement;
      while (curr && curr !== document.body) {
        const text = curr.textContent?.trim() || '';
        if (text && text.length > 0) { wrapper = curr; break; }
        curr = curr.parentElement;
      }
    }
    if (wrapper && wrapper.textContent) {
      const text = cleanText(wrapper.textContent);
      if (text && !isSizeText(text) && !activeAddOns.includes(text)) {
        activeAddOns.push(text);
      }
    }
  });

  // Strategy 2: ARIA checkboxes (React custom components — Talabat, Mrsool)
  const ariaChecked = root.querySelectorAll(
    '[role="checkbox"][aria-checked="true"], [role="switch"][aria-checked="true"]'
  );
  ariaChecked.forEach(el => {
    if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) return;
    const text = cleanText(el.textContent);
    if (text && !isSizeText(text) && !activeAddOns.includes(text)) {
      activeAddOns.push(text);
    }
  });

  return activeAddOns;
}

/**
 * Scrapes the total basket price from the Add to Cart button (Reactivity Trick).
 */
function extractTotalPrice() {
  const candidates = document.querySelectorAll('button, a, [role="button"], div, span');

  for (const el of candidates) {
    if (el.closest(`.${BADGE_CONTAINER_CLASS}`)) continue;
    // Skip header and nav elements
    if (el.closest('header, nav, [class*="header" i], [class*="nav" i]')) continue;

    const text = el.textContent?.trim() || '';
    if (text.length === 0 || text.length > 200) continue;

    // Focus specifically on checkout/basket/add button text that has prices
    if (/(?:add|basket|cart|order|checkout|أضف|سلة)/i.test(text)) {
      const match = text.match(/(\d+(?:\.\d+)?)\s*(?:EGP|LE|ج\.م)/i);
      if (match) {
        return match[1];
      }
    }
  }
  return null;
}

// ================================================================
// MODULE 3 — STATE TRACKER & POLLING ENGINE
// ================================================================

/**
 * Start the continuous polling loop checking for modal presence.
 */
function initTracker() {
  if (pollingInterval) clearInterval(pollingInterval);

  pollingInterval = setInterval(() => {
    // Use universal modal detection — works on any platform
    const modal = findModal();
    if (modal) {
      syncMacroTracker();
    } else {
      currentStateKey = null;
      if (document.querySelector('.macro-floating-widget')) {
        removeExistingBadges();
      }
    }
  }, 400);
}

function syncMacroTracker() {
  // Use universal item name extraction — works on any platform
  const baseName = extractItemName();
  if (!baseName) return;

  const activeSize = extractActiveSize();
  const addOns = extractAddOns();
  const itemDescription = extractItemDescription();

  const itemKey = `${baseName} | Size: ${activeSize} | AddOns: ${addOns.join(',')}`;

  if (itemKey === currentStateKey) return;
  currentStateKey = itemKey;

  showLoadingBadge();

  const restaurantName = extractRestaurantName();

  try {
    chrome.runtime.sendMessage({
      action: "fetchMacros",
      itemKey: itemKey,
      stateKey: itemKey,
      baseName: baseName,
      itemName: baseName,
      itemDescription: itemDescription || "",
      restaurantName: restaurantName,
      activeSize: activeSize,
      size: activeSize,
      addOns: addOns
    }, (response) => {
      if (chrome.runtime.lastError) return;
      if (itemKey !== currentStateKey) return;

      if (response && response.success && response.data) {
        injectMacroBadge(response.data, response.source);
      } else {
        showErrorBadge(response?.error || 'Calculation failed');
      }
    });
  } catch (err) {
    console.warn('[MACRO] Message sending failed:', err.message || err);
    if (err.message && err.message.includes('context invalidated')) {
      showErrorBadge('Extension reloaded. Please refresh the page.');
    } else {
      showErrorBadge('Connection to extension lost. Please refresh.');
    }
  }
}

// ================================================================
// MODULE 4 — MESSAGING BRIDGE
// ================================================================

/**
 * Sends calculation payload to background.js
 */
function requestMacros(payload) {
  chrome.runtime.sendMessage(
    {
      action: 'fetchMacros',
      ...payload
    },
    (response) => {
      // Guard: runtime connection lost
      if (chrome.runtime.lastError) {
        console.warn('[MACRO] Runtime connection error:', chrome.runtime.lastError.message);
        showErrorBadge('Extension connection lost. Reload the page.');
        return;
      }

      // Guard: check if modal closed or state has already advanced
      if (!document.querySelector('.modal-body, .item-header')) {
        return;
      }
      if (payload.stateKey !== currentStateKey) {
        console.log('[MACRO] ↩️ Stale calculation response discarded');
        return;
      }

      if (response && response.success && response.data) {
        console.log(`[MACRO] ✅ Calculation success (source: ${response.source})`);
        injectMacroBadge(response.data, response.source);
      } else {
        const errMsg = response?.error || 'Unable to calculate nutritional macros';
        console.warn('[MACRO] Calculation error:', errMsg);
        showErrorBadge(errMsg);
      }
    }
  );
}

// ================================================================
// MODULE 5 — PREMIUM GLASSMORPHIC UI RENDERER
// ================================================================

/**
 * Remove all existing badge container elements
 */
function removeExistingBadges() {
  document.querySelectorAll('.macro-floating-widget').forEach(el => el.remove());
}

/**
 * Helper function to clear state and hide the widget.
 */
function clearAndHideWidget() {
  currentStateKey = null;
  const widgetEl = document.querySelector('.macro-floating-widget') || document.getElementById('macro-nutrition-widget');
  if (widgetEl) {
    widgetEl.classList.remove('macro-visible');
  }
}

/**
 * Show a clean, premium loading indicator
 */
function showLoadingBadge() {
  removeExistingBadges();

  const loadingHTML = `
    <div class="macro-floating-widget" style="
      position: fixed !important;
      bottom: 30px !important;
      right: 30px !important;
      z-index: 2147483647 !important;
      flex-direction: column !important;
      gap: 8px !important;
      padding: 16px 20px !important;
      background: rgba(20, 20, 20, 0.85) !important;
      backdrop-filter: blur(16px) !important;
      -webkit-backdrop-filter: blur(16px) !important;
      border: 1px solid rgba(255, 255, 255, 0.15) !important;
      border-radius: 16px !important;
      color: white !important;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5) !important;
      font-family: sans-serif !important;
      min-width: 250px !important;
      transition: all 0.3s ease !important;
    ">
      <div style="display: flex; justify-content: space-between; align-items: center; font-size: 11px; font-weight: 600; text-transform: uppercase; color: rgba(255,255,255,0.6);">
        <span>Nutrition Facts</span>
        <span style="font-size: 10px; color: rgba(255,255,255,0.4);">Calculating…</span>
      </div>
      <div style="height: 4px; background: rgba(255,255,255,0.1); border-radius: 2px; overflow: hidden; position: relative; margin-top: 4px;">
        <div style="position: absolute; top: 0; left: 0; bottom: 0; width: 30%; background: #ffa133; animation: macro-loader-pulse 1.2s infinite ease-in-out;"></div>
      </div>
      <style>
        @keyframes macro-loader-pulse {
          0% { left: -30%; }
          100% { left: 100%; }
        }
      </style>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', loadingHTML);

  // Reveal via class — global stylesheet owns display value
  const widgetEl = document.querySelector('.macro-floating-widget') || document.getElementById('macro-nutrition-widget');
  if (widgetEl) {
    widgetEl.classList.add('macro-visible');
  }
}

/**
 * Show a clean, premium error notification
 */
function showErrorBadge(message) {
  removeExistingBadges();

  const errorHTML = `
    <div class="macro-floating-widget" style="
      position: fixed !important;
      bottom: 30px !important;
      right: 30px !important;
      z-index: 2147483647 !important;
      padding: 16px 20px !important;
      background: rgba(20, 20, 20, 0.85) !important;
      backdrop-filter: blur(16px) !important;
      -webkit-backdrop-filter: blur(16px) !important;
      border: 1px solid rgba(255, 255, 255, 0.15) !important;
      border-radius: 16px !important;
      color: white !important;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5) !important;
      font-family: sans-serif !important;
      min-width: 250px !important;
      transition: all 0.3s ease !important;
    ">
      <div style="font-size: 11px; font-weight: 600; text-transform: uppercase; color: #ff7675; margin-bottom: 4px;">⚠️ Calculation Error</div>
      <div style="font-size: 11px; color: rgba(255,255,255,0.7); line-height: 1.4;">${sanitizeText(message)}</div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', errorHTML);

  // Reveal via class — global stylesheet owns display value
  const widgetEl = document.querySelector('.macro-floating-widget') || document.getElementById('macro-nutrition-widget');
  if (widgetEl) {
    widgetEl.classList.add('macro-visible');
  }
}

/**
 * Injects the beautifully formatted Macro results card
 */
function injectMacroBadge(macros) {
  // 1. Remove old badges
  document.querySelectorAll('.macro-floating-widget').forEach(el => el.remove());

  /**
   * Display the macro value exactly as received from the backend.
   * The backend already applies margin and returns {min, max} ranges.
   * No second margin should be applied here.
   */
  const formatMacro = (macroValue) => {
    if (macroValue === null || macroValue === undefined) return '0';

    // Backend returns {min, max} range objects
    if (typeof macroValue === 'object' && macroValue !== null) {
      const min = Number(macroValue.min ?? 0);
      const max = Number(macroValue.max ?? 0);
      if (isNaN(min) || isNaN(max) || (min === 0 && max === 0)) return '0';
      if (min === max) return min.toString();
      return `${min} - ${max}`;
    }

    // Backend returns a plain number (no range)
    const num = Number(macroValue);
    if (isNaN(num) || num === 0) return '0';
    return num.toString();
  };

  // 2. Build the HTML for a fixed, floating panel
  const badgeHTML = `
        <div class="macro-floating-widget" style="
            position: fixed !important;
            bottom: 30px !important;
            right: 30px !important;
            z-index: 2147483647 !important;
            flex-direction: row !important;
            gap: 20px !important;
            padding: 20px !important;
            background: rgba(20, 20, 20, 0.85) !important;
            backdrop-filter: blur(16px) !important;
            -webkit-backdrop-filter: blur(16px) !important;
            border: 1px solid rgba(255, 255, 255, 0.15) !important;
            border-radius: 16px !important;
            color: white !important;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.5) !important;
            transition: all 0.3s ease !important;
        ">
            <div style="text-align: center; font-family: sans-serif;">
                <div style="font-size: 12px; color: #aaa; margin-bottom: 5px;">CALORIES</div>
                <div style="font-size: 18px; font-weight: bold; color: #ff9800;">
                    ${formatMacro(macros.calories)}
                </div>
            </div>
            <div style="text-align: center; font-family: sans-serif;">
                <div style="font-size: 12px; color: #aaa; margin-bottom: 5px;">PROTEIN</div>
                <div style="font-size: 18px; font-weight: bold; color: #2196f3;">
                    ${formatMacro(macros.protein)}g
                </div>
            </div>
            <div style="text-align: center; font-family: sans-serif;">
                <div style="font-size: 12px; color: #aaa; margin-bottom: 5px;">CARBS</div>
                <div style="font-size: 18px; font-weight: bold; color: #4caf50;">
                    ${formatMacro(macros.carbs)}g
                </div>
            </div>
            <div style="text-align: center; font-family: sans-serif;">
                <div style="font-size: 12px; color: #aaa; margin-bottom: 5px;">FAT</div>
                <div style="font-size: 18px; font-weight: bold; color: #f44336;">
                    ${formatMacro(macros.fats)}g
                </div>
            </div>
        </div>
    `;

  // 3. Append safely to the body, completely outside React's reach
  document.body.insertAdjacentHTML('beforeend', badgeHTML);

  // 4. Reveal widget via CSS class — global stylesheet exclusively controls display value
  const widgetEl = document.querySelector('.macro-floating-widget') || document.getElementById('macro-nutrition-widget');
  if (widgetEl) {
    widgetEl.classList.add('macro-visible');
  }
}

/**
 * Escapes minimum characters for safe innerHTML injection
 */
function sanitizeText(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ================================================================
// MODULE 6 — LIFECYCLE INITIALIZER
// ================================================================

/**
 * Initialize script and active polling loop
 */
function init() {
  initTracker();

  // ── Comprehensive modal-close interception ──────────────────────────────────

  // 1. Click: close button, backdrop, or general interactions inside modal
  document.addEventListener('click', (event) => {
    const target = event.target;
    if (!target) return;

    // Close button — covers Bootstrap, Material, custom, elmenus patterns
    const isCloseBtn = target.closest(
      '.close, [class*="close" i], [aria-label="Close" i], [aria-label="close" i], ' +
      '[data-dismiss="modal"], [data-testid*="close" i], ' +
      'button[class*="dismiss" i], button[class*="cancel" i]'
    );

    // Backdrop — clicking outside the modal content area
    const isBackdrop =
      target.classList.contains('modal') ||
      target.closest('.modal-backdrop') ||
      target.classList.contains('modal-holder') ||
      target.classList.contains('fade') ||
      target.getAttribute('data-backdrop') !== null;

    if (isCloseBtn || isBackdrop) {
      clearAndHideWidget();
      return;
    }

    // Trigger instant macro sync on interaction with items inside modal
    if (findModal()) {
      setTimeout(syncMacroTracker, 50);
    }
  }, true); // capture phase so we fire before React synthetic handlers

  // 1b. Change events: trigger instant sync on input changes inside the modal
  document.addEventListener('change', () => {
    if (findModal()) {
      setTimeout(syncMacroTracker, 50);
    }
  }, true);

  // 2. Keyboard: Escape key dismisses modal
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      clearAndHideWidget();
    }
  });

  console.log('[MACRO] 🚀 Content script successfully initialized');
}

// Cleanup on unload
window.addEventListener('beforeunload', () => {
  if (pollingInterval) {
    clearInterval(pollingInterval);
    pollingInterval = null;
  }
  console.log('[MACRO] 🧹 Polling cleaned up on unload');
});

// ================================================================
// GLOBAL CSS OVERRIDES — Widget visibility via .macro-visible class
// ================================================================

(function injectGlobalStyles() {
  if (document.getElementById('macro-global-styles')) return; // Prevent duplicate injection
  const overrideStyle = document.createElement('style');
  overrideStyle.id = 'macro-global-styles';
  overrideStyle.innerHTML = `
    .macro-floating-widget, #macro-nutrition-widget {
      display: none !important;
    }
    .macro-floating-widget.macro-visible, #macro-nutrition-widget.macro-visible {
      display: block !important;
    }
  `;
  (document.head || document.documentElement).appendChild(overrideStyle);
})();

// Run
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}