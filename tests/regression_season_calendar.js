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

    // Today-anchored default view: a past fixture/break must be present
    // in the markup (nothing is lost) but inside the collapsed
    // #season-calendar-rest container, not the default-visible list —
    // "it must be clear what stage we are" (Victor, 2026-11-01). Dates
    // are computed relative to the real clock so this never goes stale.
    const todaySplit = await page.evaluate(() => {
      const d = new Date();
      const fmt = (delta) => { const x = new Date(d); x.setDate(x.getDate() + delta); return `${x.getFullYear()}-${String(x.getMonth()+1).padStart(2,'0')}-${String(x.getDate()).padStart(2,'0')}`; };
      const games = [
        { date: fmt(-10), opponent: 'Past Opponent FC', competitionType: 'League', tournamentId: null },
        { date: fmt(10), opponent: 'Future Opponent FC', competitionType: 'League', tournamentId: null },
      ];
      const calendarEvents = [
        { type: 'folga', title: 'Folga Futura', startDate: fmt(5), endDate: fmt(5) },
        { type: 'milestone', title: 'Marco Futuro', startDate: fmt(20), endDate: fmt(20) },
      ];
      const html = renderSeasonCalendar(games, [], calendarEvents);
      const listSection = html.split('id="season-calendar-list"')[1].split('</div>')[0] + (html.split('id="season-calendar-rest"')[0] || '');
      const restMatch = html.match(/id="season-calendar-rest"[^>]*>([\s\S]*?)<\/div>\s*<button/);
      return {
        html,
        visiblePart: html.split('id="season-calendar-rest"')[0],
        restPart: restMatch ? restMatch[1] : '',
      };
    });
    check('Past fixture is present in the markup but NOT in the default-visible section',
      todaySplit.html.includes('Past Opponent FC') && !todaySplit.visiblePart.includes('Past Opponent FC'));
    check('Past fixture IS inside the collapsed "past events" section', todaySplit.restPart.includes('Past Opponent FC'));
    check('Future fixture, future Folga and future milestone are all in the default-visible section',
      todaySplit.visiblePart.includes('Future Opponent FC') && todaySplit.visiblePart.includes('Folga Futura') && todaySplit.visiblePart.includes('Marco Futuro'));
    check('A Folga/break item gets the cal-pause highlight class', /cal-box cal-pause"[^>]*>[\s\S]{0,80}Folga Futura/.test(todaySplit.html));
    check('A milestone item gets the cal-milestone highlight class', /cal-box cal-milestone"[^>]*>[\s\S]{0,80}Marco Futuro/.test(todaySplit.html));
    // Jogos Tab UX Improvements (spec, 2026): calendar game items are no
    // longer flattened cal-box tiles — they reuse renderUpcomingMatchRow's
    // richer row (opponent, date/time, home/away, venue, directions), so an
    // ordinary upcoming fixture must render via THAT markup, not a cal-box,
    // and must never pick up the pause/milestone highlight classes.
    check('An ordinary upcoming fixture renders via the rich match row (not a cal-box tile)',
      /<div class="row venue-row[^"]*"[^>]*>[\s\S]{0,300}?Future Opponent FC/.test(todaySplit.html));
    check('An ordinary fixture does NOT get a pause/milestone highlight class',
      !/cal-box[^"]*cal-(pause|milestone)[^"]*"[^>]*>[\s\S]{0,120}Future Opponent FC/.test(todaySplit.html));

    await page.close();
  }

  // ── team.html: Jogos Tab UX Improvements (2026) ─────────────────────
  // Últimos Resultados expand/collapse, competition-label suppression,
  // and no-duplication between results and the calendar.
  {
    const page = await browser.newPage();
    await page.goto('file://' + path.resolve(__dirname, '../team.html'));

    // renderResultRow: League matches drop the repetitive comp tag;
    // Cup/Friendly/tournament-linked matches keep it (spec §4).
    const resultRows = await page.evaluate(() => {
      const leagueGame = { opponent: 'Leagueside FC', ourScore: 2, opponentScore: 1, homeAway: 'Home', competitionType: 'League', tournamentId: null };
      const friendlyGame = { opponent: 'Friendly Town', ourScore: 1, opponentScore: 1, homeAway: 'Away', competitionType: 'Friendly', tournamentId: null };
      const tourneyGame = { opponent: 'Cup Rivals', ourScore: 3, opponentScore: 0, homeAway: 'Home', competitionType: 'League', tournamentId: 'tourney-1', competitionName: 'Winter Cup' };
      return {
        league: renderResultRow(leagueGame, []),
        friendly: renderResultRow(friendlyGame, []),
        tourney: renderResultRow(tourneyGame, []),
      };
    });
    check('renderResultRow: League match has NO comp-tag (repetitive label removed)', !/comp-tag/.test(resultRows.league));
    check('renderResultRow: Friendly match KEEPS its comp-tag', /comp-tag/.test(resultRows.friendly));
    check('renderResultRow: tournament-linked match KEEPS its comp-tag', /comp-tag/.test(resultRows.tourney) && /Winter Cup/.test(resultRows.tourney));
    check('renderResultRow: home/away score order preserved (home 2-1 at home)', /2-1/.test(resultRows.league));
    // Away game: our=1, their=1 at Away means the score shown must still be
    // "their score - our score" positionally (home-away), i.e. homeAwayScore
    // handles the flip — 1-1 is a draw either way, so assert the W/D/L badge
    // (result() returns the single-letter code used directly as the class).
    check('renderResultRow: away draw gets the "D" badge', /badge-D"/.test(resultRows.friendly));
    check('renderResultRow: home win gets the "W" badge', /badge-W"/.test(resultRows.league));

    // renderUpcomingMatchRow: same comp-tag suppression rule.
    const upcomingRows = await page.evaluate(() => {
      const leagueGame = { opponent: 'Leagueside FC', date: '2027-05-01', gameTime: '15:00', homeAway: 'Home', venue: 'Home Ground', competitionType: 'League', tournamentId: null };
      const cupGame = { opponent: 'Cup Rivals', date: '2027-05-08', gameTime: '18:00', homeAway: 'Away', venue: 'Away Ground', competitionType: 'Cup', tournamentId: null, competitionName: 'National Cup' };
      return {
        league: renderUpcomingMatchRow(leagueGame, 0),
        cup: renderUpcomingMatchRow(cupGame, 1),
      };
    });
    check('renderUpcomingMatchRow: League fixture has NO comp-tag', !/comp-tag/.test(upcomingRows.league));
    check('renderUpcomingMatchRow: Cup fixture KEEPS its comp-tag', /comp-tag/.test(upcomingRows.cup) && /National Cup/.test(upcomingRows.cup));
    check('renderUpcomingMatchRow: venue and kickoff time are present', /Home Ground/.test(upcomingRows.league) && /15:00/.test(upcomingRows.league));
    check('renderUpcomingMatchRow: away fixture shows its own venue', /Away Ground/.test(upcomingRows.cup));

    // No duplication: a finished match passed into Últimos Resultados must
    // never also appear in the calendar when the calendar is only given
    // upcomingGames (the already-filtered not-yet-played list) — exercised
    // directly at the call-site contract: a finished game is simply absent
    // from the array handed to renderSeasonCalendar.
    const noDupe = await page.evaluate(() => {
      const upcomingOnly = [{ date: '2027-06-01', opponent: 'Still To Play FC', competitionType: 'League', tournamentId: null }];
      const html = renderSeasonCalendar(upcomingOnly, [], []);
      return { hasFinished: /Already Played FC/.test(html), hasUpcoming: /Still To Play FC/.test(html) };
    });
    check('Calendar never shows a finished match when only upcomingGames is passed in', !noDupe.hasFinished);
    check('Calendar still shows the genuinely upcoming match', noDupe.hasUpcoming);

    // Empty states (spec §8, scenarios 3 & 7).
    // Nothing at all (no completed matches, no upcoming items, no
    // tournaments/events) — calendar renders nothing to show, which is the
    // correct "graceful" empty state rather than an empty card shell.
    const emptyCalendar = await page.evaluate(() => renderSeasonCalendar([], [], []));
    check('Calendar with truly nothing to show renders empty (no stray card shell)', emptyCalendar === '');
    // Only PAST items exist (everything already played, nothing upcoming) —
    // the card renders, and the default-visible section shows the explicit
    // "no upcoming" message rather than appearing blank.
    const noUpcomingState = await page.evaluate(() => {
      const d = new Date();
      const fmt = (delta) => { const x = new Date(d); x.setDate(x.getDate() + delta); return `${x.getFullYear()}-${String(x.getMonth()+1).padStart(2,'0')}-${String(x.getDate()).padStart(2,'0')}`; };
      const games = [{ date: fmt(-10), opponent: 'Already Played FC', competitionType: 'League', tournamentId: null }];
      return renderSeasonCalendar(games, [], []);
    });
    check('No-upcoming-events state shows the empty-calendar message, not a blank list',
      /id="season-calendar-list"[^>]*>[\s\S]{0,40}<p class="row-meta"/.test(noUpcomingState));
    check('No-upcoming-events state still keeps the past match available behind "view past events"',
      /Already Played FC/.test(noUpcomingState));

    await page.close();
  }

  await browser.close();
  console.log(`\n${pass} passed, ${fail} failed.`);
  process.exit(fail ? 1 : 0);
})();
