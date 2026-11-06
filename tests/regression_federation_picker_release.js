// Run: node tests/regression_federation_picker_release.js
// Exercises the exact functions extracted from index.html, without production writes.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync(require('node:path').join(__dirname, '..', 'index.html'), 'utf8');
const start = html.indexOf('const FEDERATION_CATALOGUE_PICKER_ENABLED = false;');
const end = html.indexOf('// As the user types, show a small inline hint', start);
assert(start >= 0 && end > start, 'Federation picker implementation must be present and disabled by default');
const source = html.slice(start, end);
assert.equal((html.match(/async function populateOpponentDatalist\(\)/g) || []).length, 1);
const local = [{opponentName:'Olivais "A"'},{opponentName:'Olivais "B"'},{opponentName:'Existing Club'}];
const list = {innerHTML:''};
let calls = [];
let fail = false;
const context = {
  console:{warn(){}}, Map, Set, Promise,
  DB:{async getAll(){return local}},
  Auth:{isLoggedIn(){return true}},
  Sync:{isConfigured(){return true},async supabaseRequest(method, table){
    calls.push(table);
    if(fail) throw new Error('network unavailable');
    return table === 'federation_clubs'
      ? [{id:'o',official_name:'Olivais'},{id:'c',official_name:'Casa Pia'},{id:'n',official_name:'New Club'}]
      : [{club_id:'o',squad_label:'A'},{club_id:'o',squad_label:'B'},{club_id:'c',squad_label:'C'}];
  }},
  document:{getElementById(){return list}},
  window:{},
  esc(s){return s.replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;')},
};
vm.createContext(context);
vm.runInContext(source.replace('const FEDERATION_CATALOGUE_PICKER_ENABLED = false;', 'var FEDERATION_CATALOGUE_PICKER_ENABLED = false;'),context);
(async()=>{
  await vm.runInContext('populateOpponentDatalist()',context);
  assert.equal(calls.length,0,'Disabled flag must not access federation API');
  assert.equal(context.window._opponentCatalogueNames.length,3);
  vm.runInContext('FEDERATION_CATALOGUE_PICKER_ENABLED = true',context);
  await vm.runInContext('populateOpponentDatalist()',context);
  const names=context.window._opponentCatalogueNames;
  for(const name of ['Olivais "A"','Olivais "B"','Casa Pia "C"','New Club','Existing Club']) assert(names.includes(name),name);
  assert.equal(names.filter(n=>n==='Olivais "A"').length,1,'No duplicate');
  assert(list.innerHTML.includes('&quot;C&quot;'),'HTML escaped');
  fail=true;
  await vm.runInContext('populateOpponentDatalist()',context);
  assert.equal(context.window._opponentCatalogueNames.length,3,'API failure must retain local names');
  console.log('PASS: flag off, federation A/B/C, deduplication, escaping, API outage fallback');
})().catch(e=>{console.error(e);process.exitCode=1});
