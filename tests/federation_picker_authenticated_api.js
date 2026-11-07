// AUTHENTICATED real-session API check for the federation catalogue (no browser UI).
// Requires a real test user session; run only against a non-production test project,
// or read-only against production with Victor's approval.
//
// Environment:
//   SUPABASE_URL            e.g. https://<project>.supabase.co
//   SUPABASE_ANON_KEY       publishable/anon key of that project
//   TEST_USER_JWT           access token of a signed-in test user (never commit it)
//
// Exit codes: 0 pass, 1 fail, 2 skipped (required configuration missing).
// Read-only: issues GET requests only.
const assert = require('node:assert/strict');

const { SUPABASE_URL, SUPABASE_ANON_KEY, TEST_USER_JWT } = process.env;
if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !TEST_USER_JWT) {
  console.log('SKIPPED: set SUPABASE_URL, SUPABASE_ANON_KEY and TEST_USER_JWT to run the authenticated API check.');
  process.exit(2);
}

const headers = {
  apikey: SUPABASE_ANON_KEY,
  Authorization: `Bearer ${TEST_USER_JWT}`,
  Accept: 'application/json',
};

async function get(pathAndQuery) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${pathAndQuery}`, { headers });
  const body = await res.json().catch(() => null);
  return { status: res.status, body };
}

(async () => {
  // 1. Catalogue is readable by an authenticated user.
  const clubs = await get('federation_clubs?select=id,official_name,afl_club_id&limit=500');
  assert.equal(clubs.status, 200, `federation_clubs status ${clubs.status}`);
  assert(Array.isArray(clubs.body) && clubs.body.length > 0, 'federation_clubs returned no rows');

  // 2. Season 2026/27 registrations are readable and well-formed.
  const comps = await get('federation_club_competitions?select=club_id,season,division,series,squad_label&season=eq.2026%2F27&limit=1000');
  assert.equal(comps.status, 200, `competitions status ${comps.status}`);
  assert(comps.body.every(r => r.season === '2026/27'), 'season filter returned other seasons');

  // 3. No duplicate AFL club ids in the catalogue.
  const ids = clubs.body.map(c => c.afl_club_id).filter(Boolean);
  assert.equal(new Set(ids).size, ids.length, 'duplicate afl_club_id in federation_clubs');

  // 4. Every 2026/27 registration points to a catalogue club.
  const clubIds = new Set(clubs.body.map(c => c.id));
  const orphan = comps.body.filter(r => !clubIds.has(r.club_id));
  assert.equal(orphan.length, 0, `${orphan.length} registrations point to unknown clubs`);

  console.log(`PASS (authenticated API): ${clubs.body.length} clubs, ${comps.body.length} registrations for 2026/27, no duplicate AFL ids, no orphan registrations`);
})().catch(e => { console.error('FAIL:', e.message || e); process.exitCode = 1; });
