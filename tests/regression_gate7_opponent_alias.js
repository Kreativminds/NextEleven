// Gate 7 — opponent/federation-club alias resolution.
//
// Verifies the fix to index.html's findOpponentByName(): a name that
// matches neither the user's own opponents list nor the federation
// catalogue's official_name directly can still resolve via a verified
// team_alias_mappings row (kind:'opponent_federation_alias'), WITHOUT
// colliding with the League Classification feature's own, pre-existing
// use of the same table/store (Classification.scopeKey/matchAlias).
//
// Drives index.html directly via Playwright and calls the real,
// in-page functions — same technique as regression_season_calendar.js.
// No network calls: the federation-club "catalogue" and alias rows are
// seeded straight into IndexedDB via DB.put, exactly as the real sync
// layer would leave them after a pull.
//
// Run: node tests/regression_gate7_opponent_alias.js
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
  await page.goto('file://' + path.resolve(__dirname, '../index.html'));

  const result = await page.evaluate(async () => {
    const out = {};

    // Open IndexedDB directly (what init() does as its first step) — the
    // rest of init() is not needed for this test and would try things
    // (auth/session, network) that don't apply to a bare file:// load.
    await DB.open();

    // ── Seed the federation-club catalogue cache (what syncFederationClubsIfStale
    // would have stored after a real pull) — base names only, no squad letters,
    // matching the Gate 5 Resolution fix. ──────────────────────────────────────
    const clubs = [
      { official_name: 'Olivais', map_url: 'https://maps.example/olivais', venue_lat: '38.77', venue_lng: '-9.11', logo_url: null },
      { official_name: 'Olivais Sul', map_url: 'https://maps.example/olivais-sul', venue_lat: '38.78', venue_lng: '-9.12', logo_url: null },
    ];
    await DB.put('appMeta', { metaKey: 'federationClubsCache', value: { clubs, fetchedAt: Date.now() } });

    // ── Seed one real local opponent (to prove direct local match still wins,
    // unchanged) and one opponent-federation-alias mapping covering the known
    // real-world name variants for Olivais (afl_club_id 1033). ────────────────
    await DB.put('opponents', { opponentName: 'Already Known FC', ageGroup: null, level: null, logoUrl: null, notes: null });
    await DB.put('teamAliasMappings', {
      kind: 'opponent_federation_alias',
      competitionType: '__opponent_federation_alias__',
      canonicalOfficialName: 'Olivais',
      aflClubId: '1033',
      squadLabel: 'A',
      aliases: ['olivais "a"', 'sl olivais', 'sl olivais 2014'],
    });

    // ── A League Classification alias row (the feature that already owns
    // this table) — no `kind` field, a real League scope. Must stay invisible
    // to findOpponentByName, and the opponent-alias row above must stay
    // invisible to Classification.matchAlias. ─────────────────────────────────
    const clsScope = { seasonId: 6, competitionType: 'League', competitionName: 'AF Lisboa II Divisão · Série 2', phase: '', series: '2' };
    await DB.put('teamAliasMappings', {
      seasonId: clsScope.seasonId, competitionType: clsScope.competitionType,
      competitionName: clsScope.competitionName, phase: clsScope.phase, series: clsScope.series,
      aliases: ['some other classification variant'],
    });

    out.directLocalMatch = await findOpponentByName('Already Known FC');
    out.directFederationMatch = await findOpponentByName('Olivais Sul'); // no alias needed
    out.aliasMatchQuoted = await findOpponentByName('Olivais "A"');
    out.aliasMatchSLOlivais = await findOpponentByName('SL Olivais');
    out.aliasMatchBirthYear = await findOpponentByName('SL Olivais 2014');
    out.noMatch = await findOpponentByName('Totally Unknown FC');

    // Cross-contamination checks, both directions.
    const allAliasRows = await DB.getAll('teamAliasMappings');
    out.classificationMatchAlias = Classification.matchAlias('some other classification variant', allAliasRows, clsScope);
    out.classificationScopeKeyOfOppAliasRow = Classification.scopeKey(allAliasRows.find(a => a.kind === 'opponent_federation_alias'));
    out.classificationScopeKeyOfRealScope = Classification.scopeKey(clsScope);

    return out;
  });

  check('Direct local opponent match still resolves (existing behaviour unchanged)',
    result.directLocalMatch && result.directLocalMatch.opponentName === 'Already Known FC');

  check('Direct federation-catalogue match (no alias needed) still resolves',
    result.directFederationMatch && result.directFederationMatch.opponentName === 'Olivais Sul' && result.directFederationMatch._fromFederationCatalogue === true);

  check('"Olivais \\"A\\"" resolves via alias to canonical "Olivais"',
    result.aliasMatchQuoted && result.aliasMatchQuoted.opponentName === 'Olivais' && result.aliasMatchQuoted._fromFederationCatalogue === true);

  check('"SL Olivais" resolves via alias to canonical "Olivais"',
    result.aliasMatchSLOlivais && result.aliasMatchSLOlivais.opponentName === 'Olivais');

  check('"SL Olivais 2014" (birth-year variant) resolves via alias to canonical "Olivais"',
    result.aliasMatchBirthYear && result.aliasMatchBirthYear.opponentName === 'Olivais');

  check('A name with no local, federation or alias match resolves to null',
    result.noMatch === null);

  check('"Olivais Sul" is NOT pulled in by the Olivais alias (distinct club preserved)',
    result.directFederationMatch.opponentName !== 'Olivais');

  check('Classification.matchAlias still finds its own (non-opponent-alias) row',
    !!result.classificationMatchAlias);

  check('The opponent-federation-alias row\'s scopeKey never equals a real classification scope\'s key (no cross-contamination)',
    result.classificationScopeKeyOfOppAliasRow !== result.classificationScopeKeyOfRealScope);

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail ? 1 : 0);
})();
