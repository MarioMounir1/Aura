/**
 * ============================================================
 * ELMENUS MACRO CALCULATOR - Popup Script
 * ============================================================
 * Handles UI interactions, tab verification, and cache purges.
 */

document.addEventListener('DOMContentLoaded', () => {
  initPopup();
});

/**
 * Initializes the popup listeners and status verification
 */
function initPopup() {
  setupActionListeners();
  verifyActiveTabState();
}

/**
 * Binds event handlers to the popup buttons
 */
function setupActionListeners() {
  // Open elmenus.com button
  const openSiteBtn = document.getElementById('openSiteBtn');
  openSiteBtn.addEventListener('click', () => {
    chrome.tabs.create({ url: 'https://www.elmenus.com' });
  });

  // Clear Cache button with premium feedback transition
  const clearCacheBtn = document.getElementById('clearCacheBtn');
  clearCacheBtn.addEventListener('click', () => {
    // Disable temporarily to prevent multiple quick clicks
    clearCacheBtn.disabled = true;
    const originalText = clearCacheBtn.innerHTML;
    clearCacheBtn.innerHTML = 'Clearing... ⏳';

    chrome.runtime.sendMessage({ action: 'clearCache' }, (response) => {
      clearCacheBtn.disabled = false;
      
      if (chrome.runtime.lastError) {
        console.error('[POPUP] Message failed:', chrome.runtime.lastError);
        clearCacheBtn.innerHTML = 'Error ❌';
        setTimeout(() => {
          clearCacheBtn.innerHTML = originalText;
        }, 2000);
        return;
      }

      if (response && response.success) {
        clearCacheBtn.innerHTML = 'Cache Cleared! ✓';
        clearCacheBtn.style.borderColor = 'rgba(76, 175, 80, 0.4)';
        clearCacheBtn.style.backgroundColor = 'rgba(76, 175, 80, 0.05)';
        
        setTimeout(() => {
          clearCacheBtn.innerHTML = originalText;
          clearCacheBtn.style.borderColor = '';
          clearCacheBtn.style.backgroundColor = '';
        }, 2500);
      } else {
        clearCacheBtn.innerHTML = 'Failed ❌';
        setTimeout(() => {
          clearCacheBtn.innerHTML = originalText;
        }, 2000);
      }
    });
  });
}

/**
 * Checks if the user is currently on an elmenus.com page and updates the status badge styles accordingly
 */
function verifyActiveTabState() {
  const statusCard = document.getElementById('statusCard');
  const statusText = document.getElementById('statusText');

  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (chrome.runtime.lastError || !tabs || tabs.length === 0) {
      statusText.innerHTML = 'Unable to read active tab';
      return;
    }

    const activeTab = tabs[0];
    const url = activeTab.url || '';
    
    // Check if URL belongs to elmenus.com
    const isOnElmenus = url.includes('elmenus.com');

    if (isOnElmenus) {
      statusText.innerHTML = 'Active on elmenus.com ✓';
      statusCard.style.borderColor = 'rgba(76, 175, 80, 0.3)';
      statusCard.style.background = 'rgba(76, 175, 80, 0.03)';
      
      // Inject CSS variables to override the status accent color to green
      statusCard.style.setProperty('--brand-color', '#4caf50');
      statusCard.style.setProperty('--brand-glow', 'rgba(76, 175, 80, 0.3)');
    } else {
      statusText.innerHTML = 'Visit elmenus.com to use';
      statusCard.style.borderColor = 'rgba(255, 161, 51, 0.15)';
      statusCard.style.background = 'var(--glass-bg)';
      
      // Reset variables to the theme orange
      statusCard.style.setProperty('--brand-color', 'var(--brand-color)');
      statusCard.style.setProperty('--brand-glow', 'var(--brand-glow)');
    }
  });
}
