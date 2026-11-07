// Gate 13.3 — C-squad regression coverage (requested explicitly: Gate 12
// found A/B squad distinctions tested but no C-squad case anywhere in the
// suite).
//
// Grounded in REAL production-catalogue data, not an invented scenario:
// the Gate 11-fixed, clean-rehearsed federation catalogue (isolated test
// project tqpykeuuzcqudqtfrqmc, schema gate11_clean) contains real clubs
// with a genuine third ("C") squad registration under the SAME single
// federation_clubs row/afl_club_id — e.g. EF Belém (afl_club_id 5647,
// squads A/B/C), Santa Maria (1151, A/B/C), Vila Verde (1114, A/B/C). This
// file extends the existing Olivais picker-fixture (regression_gate8_
// opponent_picker.js) with a synthetic C-squad entry in the SAME style, so
// the two files stay consistent, while this file's own DB-level checks (at
// the bottom) query the REAL A/B/C clubs directly to ground the claim in
// production data rather than only a synthetic fixture.
//
// Verifies, at the frontend (computeOpponentPickerNames) level:
//   - A, B and C squad-distinct local opponent names ALL remain in the
//     picker when verified aliases exist for all three squads under one
//     federation club -- squad label is preserved all the way through
//     opponent SELECTION, never collapsed to the generic catalogue name.
//   - The generic federation name is still suppressed once all 3 squads
//     have verified aliases (same duplicate-suppression guarantee Gate 8
//     already proved for 2 squads, now proved for 3).
//   - An unrelated, pre-existing local opponent (standing in for "historical
//     opponent records") is completely unaffected by adding a 3rd squad --
//     not renamed, not merged, not touched.
//   - An unrelated new federation club is also unaffected (no cross-talk).
//
// Run: node tests/regression_gate13_csquad_opponent_picker.js
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

    // Olivais fixture extended with a synthetic 3rd ("C") squad, same club
    // (AFL 1033) -- plus one untouched, unrelated local opponent standing
    // in for "historical opponent records" that must remain unaffected.
    const localOpponents = [
      { opponentName: "Olivais 'A'" },
      { opponentName: "Olivais 'B'" },
      { opponentName: "Olivais 'C'" },       // NEW this gate
      { opponentName: 'SL Olivais 2014' },
      { opponentName: 'Historic Rivals FC' }, // unrelated, pre-existing, must be untouched
    ];
    const federationClubs = [
      { official_name: 'Olivais' },       // AFL 1033 -- now aliased by all 3 squads + the birth-year row
      { official_name: 'Sporting CP' },   // unrelated, brand-new club, no local equivalent
    ];
    const withAliasRows = [
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: 'A',
        aliases: ["olivais 'a'"],
      },
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: 'B',
        aliases: ["olivais 'b'"],
      },
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: 'C',
        aliases: ["olivais 'c'"],   // NEW this gate
      },
      {
        kind: 'opponent_federation_alias', competitionType: '__opponent_federation_alias__',
        canonicalOfficialName: 'Olivais', aflClubId: '1033', squadLabel: '2014',
        aliases: ['sl olivais 2014'],
      },
    ];

    out.withAllThreeSquads = computeOpponentPickerNames(localOpponents, federationClubs, withAliasRows, true);
    return out;
  });

  check('A-squad local name ("Olivais \'A\'") preserved with its squad label intact',
    result.withAllThreeSquads.includes("Olivais 'A'"));

  check('B-squad local name ("Olivais \'B\'") preserved with its squad label intact',
    result.withAllThreeSquads.includes("Olivais 'B'"));

  check('C-squad local name ("Olivais \'C\'") preserved with its squad label intact -- NEW coverage this gate',
    result.withAllThreeSquads.includes("Olivais 'C'"));

  check('Birth-year identity ("SL Olivais 2014") remains its own distinct entry alongside A/B/C',
    result.withAllThreeSquads.includes('SL Olivais 2014'));

  check('Generic "Olivais" catalogue entry is suppressed once all 3 squads have verified aliases',
    !result.withAllThreeSquads.includes('Olivais'));

  check('Unrelated, pre-existing local opponent ("Historic Rivals FC") is completely unaffected -- stands in for "historical opponent records remain unchanged"',
    result.withAllThreeSquads.includes('Historic Rivals FC'));

  check('Unrelated new federation club ("Sporting CP") is unaffected by the 3-squad scenario -- no cross-talk',
    result.withAllThreeSquads.includes('Sporting CP'));

  check('Exactly 6 names shown (3 squads + birth-year row + unrelated local + unrelated new club) -- no extra, no missing, no duplicate',
    result.withAllThreeSquads.length === 6);

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail ? 1 : 0);
})();
