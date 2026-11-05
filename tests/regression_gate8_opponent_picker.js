// Gate 8.4 — opponent-picker duplicate prevention.
//
// Verifies computeOpponentPickerNames() (index.html), the pure function
// behind populateOpponentDatalist():
//   - with the feature flag OFF (today's deployed default, and the state
//     Phase A+B must ship in if Phase C's aliases are delayed): the
//     picker shows ONLY the user's own local opponents, so the federation
//     catalogue can never introduce a duplicate-looking option.
//   - with the flag ON and NO alias mappings yet: a brand-new federation
//     club (nothing like it in the user's own list) is still offered —
//     Phase A/B's own value isn't lost, only genuinely NEW clubs appear.
//   - with the flag ON and a verified alias mapping in place: the
//     generic catalogue name is suppressed, the user's own differently
//     spelled, squad-distinct local names remain the only way to pick
//     that club — squad distinctions preserved, no duplicate option.
//   - confirms populateOpponentDatalist() itself (the real DOM-touching
//     function, under today's real default flag value) renders only
//     local names into the actual <datalist> element.
//
// Run: node tests/regression_gate8_opponent_picker.js
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
    await DB.open();

    const localOpponents = [
      { opponentName: "Olivais 'A'" },
      { opponentName: "Olivais 'B'" },
      { opponentName: 'SL Olivais' },
      { opponentName: 'SL Olivais 2014' },
    ];
    const federationClubs = [
      { official_name: 'Olivais' },       // AFL 1033 — aliased by all 4 local names above
      { official_name: 'Sporting CP' },   // brand-new club, no local equivalent at all
    ];
    const noAliasRows = [];
    const withAliasRows = [
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: 'A',
        aliases: ["olivais 'a'", 'sl olivais', 'sl olivais 2014'],
      },
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: 'B',
        aliases: ["olivais 'b'"],
      },
    ];

    out.flagOff = computeOpponentPickerNames(localOpponents, federationClubs, noAliasRows, false);
    out.flagOnNoAlias = computeOpponentPickerNames(localOpponents, federationClubs, noAliasRows, true);
    out.flagOnWithAlias = computeOpponentPickerNames(localOpponents, federationClubs, withAliasRows, true);

    // Real DOM path, under today's shipped default (FEDERATION_CATALOGUE_PICKER_ENABLED = false).
    document.body.insertAdjacentHTML('beforeend', '<datalist id="gf-opp-list"></datalist>');
    await DB.put('opponents', { opponentName: 'Already Known FC', ageGroup: null, level: null, logoUrl: null, notes: null });
    await DB.put('appMeta', { metaKey: 'federationClubsCache', value: { clubs: [{ official_name: 'Should Never Appear FC' }], fetchedAt: Date.now() } });
    await populateOpponentDatalist();
    out.realDatalistOptionCount = document.getElementById('gf-opp-list').children.length;
    out.realDatalistNames = Array.from(document.getElementById('gf-opp-list').children).map(o => o.value);
    out.defaultFlagValue = FEDERATION_CATALOGUE_PICKER_ENABLED;

    return out;
  });

  check('Flag OFF: picker shows only the 4 local names, federation catalogue entirely absent',
    result.flagOff.length === 4 && !result.flagOff.includes('Olivais') && !result.flagOff.includes('Sporting CP'));

  check('Flag ON, no aliases yet: the brand-new "Sporting CP" club is still offered',
    result.flagOnNoAlias.includes('Sporting CP'));

  check('Flag ON, no aliases yet: "Olivais" still shows too (nothing yet tells the system it duplicates the 4 local names)',
    result.flagOnNoAlias.includes('Olivais'));

  check('Flag ON, WITH verified aliases: the generic "Olivais" catalogue entry is suppressed',
    !result.flagOnWithAlias.includes('Olivais'));

  check('Flag ON, WITH verified aliases: all 4 local, squad-distinct names are still present (squad distinctions preserved)',
    ["Olivais 'A'", "Olivais 'B'", 'SL Olivais', 'SL Olivais 2014'].every(n => result.flagOnWithAlias.includes(n)));

  check('Flag ON, WITH verified aliases: the unrelated, brand-new "Sporting CP" club is unaffected and still shows',
    result.flagOnWithAlias.includes('Sporting CP'));

  check('Today\'s shipped default is the flag OFF (false) — Phase B can deploy before Phase C with zero behaviour change',
    result.defaultFlagValue === false);

  check('Real populateOpponentDatalist(), run under the real default flag: only the local opponent appears, the federation-only club never does',
    result.realDatalistOptionCount === 1 && result.realDatalistNames[0] === 'Already Known FC');

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail ? 1 : 0);
})();
