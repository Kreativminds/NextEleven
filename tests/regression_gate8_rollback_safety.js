// Gate 8.7 — rollback safety (frontend side).
//
// The DB-level rollback drill (soft-deleting/restoring opponent_federation_alias
// rows, proven reversible via the real get_public_team_data_opponent_slice
// RPC) is documented in migrations/gate8_phase_c_PRODUCTION_verified_opponent_aliases.sql
// and was run directly against the isolated Supabase test project.
//
// This test covers the OTHER half of a safe rollback: if Phase A's
// federation_clubs table were ever renamed away or made unreachable
// (the non-destructive way this engagement rolls back a table, per the
// standing "never DROP" constraint), does the app degrade safely, or
// does it throw/break? Verifies syncFederationClubsIfStale() and
// getFederationClubs() by making the simulated fetch throw, exactly as
// a missing/renamed table would surface through Sync.fetchFederationClubs().
//
// Run: node tests/regression_gate8_rollback_safety.js
const { chromium } = require('playwright');
const path = require('path');

let pass = 0, fail = 0;
function check(label, cond) {
  if (cond) { pass++; console.log('PASS —', label); }
  else { fail++; console.log('FAIL —', label); }
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const pageErrors = [];
  page.on('pageerror', err => pageErrors.push(String(err)));
  await page.goto('file://' + path.resolve(__dirname, '../index.html'));

  const result = await page.evaluate(async () => {
    const out = {};
    await DB.open();

    // Simulate a rolled-back/unreachable federation_clubs table: force
    // Sync.fetchFederationClubs to throw (the same shape of failure a
    // renamed-away or dropped table would produce through PostgREST),
    // and force the stale/offline branch too.
    const originalIsConfigured = Sync.isConfigured;
    const originalFetch = Sync.fetchFederationClubs;
    Sync.isConfigured = () => true;
    Sync.fetchFederationClubs = async () => { throw new Error('relation "federation_clubs" does not exist (simulated rollback)'); };

    // No pre-existing cache -- the worst case (first load right after rollback).
    out.noCacheResult = await syncFederationClubsIfStale();
    out.getFederationClubsAfterFailedSync = await getFederationClubs();

    // Local opponent lookups must keep working regardless.
    await DB.put('opponents', { opponentName: 'Still Works FC', ageGroup: null, level: null, logoUrl: null, notes: null });
    out.localLookupStillWorks = await findOpponentByName('Still Works FC');

    document.body.insertAdjacentHTML('beforeend', '<datalist id="gf-opp-list"></datalist>');
    await populateOpponentDatalist();
    out.datalistStillRenders = document.getElementById('gf-opp-list').children.length >= 1;

    Sync.isConfigured = originalIsConfigured;
    Sync.fetchFederationClubs = originalFetch;
    return out;
  });

  check('syncFederationClubsIfStale() does not throw when the catalogue table is unreachable, returns [] with no cache',
    Array.isArray(result.noCacheResult) && result.noCacheResult.length === 0);

  check('getFederationClubs() returns [] (not undefined/throw) after a failed sync',
    Array.isArray(result.getFederationClubsAfterFailedSync) && result.getFederationClubsAfterFailedSync.length === 0);

  check('Local opponent name resolution is completely unaffected by the catalogue being unreachable',
    result.localLookupStillWorks && result.localLookupStillWorks.opponentName === 'Still Works FC');

  check('The opponent picker still renders (local names only) with the catalogue unreachable',
    result.datalistStillRenders);

  check('No uncaught page error was thrown at any point during the simulated rollback',
    pageErrors.length === 0);

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  if (pageErrors.length) console.log('Page errors:', pageErrors);
  process.exit(fail ? 1 : 0);
})();
