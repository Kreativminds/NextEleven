// Real Chromium smoke test for the federation opponent suggestion widget.
// Runs on a synthetic page, never connects to production.
const { chromium } = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const html = fs.readFileSync(require('node:path').join(__dirname, '..', 'index.html'), 'utf8');
const start = html.indexOf('const FEDERATION_CATALOGUE_PICKER_ENABLED = false;');
const end = html.indexOf('// As the user types, show a small inline hint', start);
assert(start >= 0 && end > start, 'Picker source must exist');
(async () => {
 const browser = await chromium.launch({headless:true});
 try {
  const page = await browser.newPage();
  await page.setContent('<datalist id="gf-opp-list"></datalist>');
  await page.evaluate(() => {
   window.esc = s => String(s).replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;');
   window.DB = {getAll:async()=>[{opponentName:'SL Olivais'},{opponentName:'Olivais Sul'}]};
   window.Auth = {isLoggedIn:()=>true};
   window.Sync = {isConfigured:()=>true,supabaseRequest:async(_method,table)=>table==='federation_clubs' ? [{id:'ol',official_name:'Olivais'},{id:'ca',official_name:'Casa Pia'}] : [{club_id:'ol',squad_label:'B'},{club_id:'ca',squad_label:'A'}]};
  });
  await page.evaluate(source => { const script=document.createElement('script'); script.textContent=source; document.body.appendChild(script); },html.slice(start,end));
  await page.evaluate(async()=>{ await populateOpponentDatalist(); });
  let options=await page.locator('#gf-opp-list option').evaluateAll(nodes=>nodes.map(n=>n.value || n.textContent || ''));
  assert(options.some(x=>x.includes('SL Olivais')),'Local club present while flag off');
  assert(!options.some(x=>x.includes('Casa Pia')),'Remote club absent while flag off');
  await page.evaluate(async()=>{ FEDERATION_CATALOGUE_PICKER_ENABLED=true; await populateOpponentDatalist(); });
  options=await page.locator('#gf-opp-list option').evaluateAll(nodes=>nodes.map(n=>n.value || n.textContent || ''));
  assert(options.some(x=>x.includes('Casa Pia')),'Remote club appears when enabled');
  assert(options.some(x=>x.includes('Olivais Sul')),'Distinct Olivais Sul retained');
  await page.evaluate(async()=>{ Sync.supabaseRequest=async()=>{throw new Error('outage')}; await populateOpponentDatalist(); });
  options=await page.locator('#gf-opp-list option').evaluateAll(nodes=>nodes.map(n=>n.value || n.textContent || ''));
  assert(options.some(x=>x.includes('SL Olivais')),'Local club survives outage');
  assert(!options.some(x=>x.includes('Casa Pia')),'Stale remote club cleared after outage');
  console.log('PASS: real Chromium federation picker flag, distinct clubs and offline fallback');
 } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1});
