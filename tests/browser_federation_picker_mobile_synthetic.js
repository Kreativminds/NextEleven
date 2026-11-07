// SYNTHETIC phone-viewport test for the federation opponent picker.
// Chromium emulating 390x844 with touch. This is NOT an Android device and NOT an
// authenticated production session. It runs the picker source from index.html on a
// synthetic page, never connects to Supabase, and never touches production.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const html = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
const start = html.indexOf('const FEDERATION_CATALOGUE_PICKER_ENABLED = false;');
const end = html.indexOf('// As the user types, show a small inline hint', start);
assert(start >= 0 && end > start, 'Picker source must exist in index.html');

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const context = await browser.newContext({
      viewport: { width: 390, height: 844 },
      deviceScaleFactor: 2,
      isMobile: true,
      hasTouch: true,
    });
    const page = await context.newPage();
    await page.setContent('<meta name="viewport" content="width=device-width, initial-scale=1"><datalist id="gf-opp-list"></datalist>');
    await page.evaluate(() => {
      window.esc = s => String(s).replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');
      window.DB = { getAll: async () => [{ opponentName: 'SL Olivais' }, { opponentName: 'Olivais Sul' }] };
      window.Auth = { isLoggedIn: () => true };
      window.Sync = {
        isConfigured: () => true,
        supabaseRequest: async (_m, table) => table === 'federation_clubs'
          ? [{ id: 'ol', official_name: 'Olivais' }, { id: 'ca', official_name: 'Casa Pia' }]
          : [],
      };
    });
    await page.evaluate(source => {
      const s = document.createElement('script');
      s.textContent = source;
      document.body.appendChild(s);
    }, html.slice(start, end).replace('const FEDERATION_CATALOGUE_PICKER_ENABLED = false;', 'let FEDERATION_CATALOGUE_PICKER_ENABLED = false;'));
    await page.evaluate(async () => { await populateOpponentDatalist(); });

    const options = () => page.locator('#gf-opp-list option').evaluateAll(n => n.map(o => o.value || o.textContent || ''));
    let opts = await options();
    assert(opts.some(x => x.includes('SL Olivais')), 'Local club present while flag off');
    assert(!opts.some(x => x.includes('Casa Pia')), 'Remote club absent while flag off');

    await page.evaluate(async () => { FEDERATION_CATALOGUE_PICKER_ENABLED = true; await populateOpponentDatalist(); });
    opts = await options();
    assert(opts.some(x => x.includes('Casa Pia')), 'Remote club appears when enabled');
    assert(opts.some(x => x.includes('Olivais Sul')), 'Olivais Sul stays distinct from Olivais');

    // Layout: the page must not scroll horizontally at phone width.
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
    assert(overflow <= 0, `No horizontal overflow at 390px (found ${overflow}px)`);

    await page.evaluate(async () => { Sync.supabaseRequest = async () => { throw new Error('outage'); }; await populateOpponentDatalist(); });
    opts = await options();
    assert(opts.some(x => x.includes('SL Olivais')), 'Local club survives outage on mobile');
    assert(!opts.some(x => x.includes('Casa Pia')), 'Stale remote club cleared after outage');

    console.log('PASS (synthetic, 390x844 touch Chromium): flag gating, distinct Olivais clubs, no horizontal overflow, offline fallback');
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
