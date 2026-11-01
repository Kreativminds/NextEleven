// Focused regression tests for the Season Calendar feature:
//   1. Folga detection (index.html's detectFolgaCandidates) against the
//      REAL production season-6 League fixture list — three genuine rest
//      weekends, one 3-week Christmas gap correctly excluded, an
//      incomplete/still-growing schedule never flagged past its last
//      known fixture, and a genuinely irregular schedule never
//      hallucinating a weekly pattern.
//   2. Easter Sunday computation (index.html's easterSundayISO) against
//      well-known historical dates.
//   3. The parents-page chronological calendar merge (team.html's
//      renderSeasonCalendar/calBuildTimeline) — multi-day breaks and
//      tournaments appear once as a range (never duplicated per day),
//      same-day events (Folga + friendly) both appear, and the renderer
//      degrades gracefully when calendarEvents is empty/undefined.
//
// Drives index.html and team.html directly via Playwright and calls their
// pure functions in-page — same technique as regression_caio_and_cards.js.
//
// Run: node tests/regression_season_calendar.js
const { chromium } = require('playwright');
const path = require('path');

let pass = 0, fail = 0;
function check(label, cond) {
  if (cond) { pass++; console.log('PASS —', label); }
  else { fail++; console.log('FAIL —', label); }
}

(async () => {
  const browser = await chromium.launch();

  // ── index.html: Folga detection + Easter computation (pure functions) ──
  {
    const page = await browser.newPage();
    await page.goto('file://' + path.resolve(__dirname, '../index.html'));
    const result = await page.evaluate(() => {
      const out = {};

      // Real production season-6 League fixture dates (2026-10-03 through
      // 2027-04-17), confirmed against the live database.
      const season6Dates = [
        '2026-10-03','2026-10-10','2026-10-17','2026-10-24','2026-10-31',
        '2026-11-07','2026-11-14','2026-11-21','2026-12-05','2026-12-12',
        '2026-12-19','2027-01-09','2027-01-16','2027-01-23','2027-01-30',
        '2027-02-06','2027-02-13','2027-02-20','2027-02-27','2027-03-06',
        '2027-03-20','2027-04-03','2027-04-10','2027-04-17',
      ];
      out.oddLeagueCandidates = detectFolgaCandidates(season6Dates);

      // "Incomplete league schedule with no false Folga" — a short,
      // still-growing fixture list must never produce a Folga candidate
      // past the last known fixture.
      out.incompleteSchedule = detectFolgaCandidates(['2026-10-03','2026-10-10','2026-10-17','2026-10-24']);

      // A genuinely irregular schedule with no repeated gap at all must
      // never hallucinate a weekly cadence, and therefore never a Folga.
      out.irregularSchedule = detectFolgaCandidates(['2026-09-01','2026-09-08','2026-09-21','2026-09-30','2026-10-15','2026-10-26']);

      out.easter2026 = easterSundayISO(2026); // known: 2026-04-05
      out.easter2027 = easterSundayISO(2027); // known: 2027-03-28
      out.easter2024 = easterSundayISO(2024); // known: 2024-03-31

      return out;
    });
    // Three genuine rest weekends break an otherwise strict weekly
    // cadence — 2026-11-28, 2027-03-13 AND 2027-03-27 (two separate bye
    // rounds back to back around March). The one 3-week Christmas gap
    // (2026-12-19 -> 2027-01-09) is correctly NOT included — a larger
    // multiple of the cadence is a break, never a single Folga.
    check('Odd-numbered league: exactly the three known rest rounds detected, Christmas gap excluded',
      JSON.stringify(result.oddLeagueCandidates) === JSON.stringify(['2026-11-28','2027-03-13','2027-03-27']));
    check('Incomplete schedule: no Folga suggested past the last known fixture', result.incompleteSchedule.length === 0);
    check('Irregular schedule with no established weekly pattern: no false Folga', result.irregularSchedule.length === 0);
    check('Easter Sunday 2026 computed correctly (2026-04-05)', result.easter2026 === '2026-04-05');
    check('Easter Sunday 2027 computed correctly (2027-03-28)', result.easter2027 === '2027-03-28');
    check('Easter Sunday 2024 computed correctly (2024-03-31)', result.easter2024 === '2024-03-31');
    await page.close();
  }

  // ── team.html: chronological merge + rendering ──────────────────────
  {
    const page = await browser.newPage();
    await page.goto('file://' + path.resolve(__dirname, '../team.html'));
    const html = await page.evaluate(() => {
      const games = [
        { date: '2026-10-31', opponent: 'CF Estrela', competitionType: 'League', tournamentId: null },
        { date: '2026-09-12', opponent: 'Santa Maria', competitionType: 'Friendly', tournamentId: null },
      ];
      const tournaments = [
        { name: 'Winter Cup', startDate: '2026-12-27', endDate: '2026-12-29' },
      ];
      const calendarEvents = [
        // Folga with a friendly on the same date — both must appear.
        { type: 'folga', title: 'Folga', startDate: '2026-09-12', endDate: '2026-09-12' },
        // A multi-week Christmas break spanning the turn of the year.
        { type: 'break', subtype: 'christmas', title: 'Pausa de Natal', startDate: '2026-12-19', endDate: '2027-01-04' },
        // A single-date milestone.
        { type: 'milestone', title: 'Fim do Campeonato', startDate: '2027-04-17', endDate: '2027-04-17' },
      ];
      return renderSeasonCalendar(games, tournaments, calendarEvents);
    });

    check('Calendar renders the Christmas break as ONE row with its range, not one per day',
      (html.match(/Pausa de Natal/g) || []).length === 1);
    check('Calendar shows the tournament as a single range entry (27 → 29 Dec), not duplicated',
      (html.match(/Winter Cup/g) || []).length === 1);
    check('Folga and the same-day friendly BOTH appear (neither hides the other)', /Folga/.test(html) && /Santa Maria/.test(html));
    check('The milestone (Fim do Campeonato) appears', /Fim do Campeonato/.test(html));
    check('The League fixture still appears alongside everything else', /CF Estrela/.test(html));

    // Empty calendarEvents (e.g. production before migration 006 is
    // applied, or simply no events yet) must render gracefully.
    const htmlNoEvents = await page.evaluate(() => {
      const games = [{ date: '2026-10-31', opponent: 'CF Estrela', competitionType: 'League', tournamentId: null }];
      return renderSeasonCalendar(games, [], undefined);
    });
    check('Renders fine with no calendarEvents at all (undefined)', /CF Estrela/.test(htmlNoEvents));

    await page.close();
  }

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail ? 1 : 0);
})();
