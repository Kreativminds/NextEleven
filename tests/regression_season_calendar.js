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

    // A Folga dated INSIDE a confirmed break is pure duplication (the break
    // already covers it) and must be suppressed; a Folga OUTSIDE any break
    // is a genuine stand-alone rest day and must still appear (Victor,
    // 2026-11-01, reporting Folga 27/03/2027 shown redundantly inside
    // Pausa da Páscoa 25/03→01/04/2027).
    const folgaVsBreak = await page.evaluate(() => {
      const calendarEvents = [
        { type: 'folga', title: 'Folga Standalone', startDate: '2027-03-13', endDate: '2027-03-13' },
        { type: 'break', subtype: 'easter', title: 'Pausa da Páscoa', startDate: '2027-03-25', endDate: '2027-04-01' },
        { type: 'folga', title: 'Folga Inside Break', startDate: '2027-03-27', endDate: '2027-03-27' },
      ];
      return renderSeasonCalendar([], [], calendarEvents);
    });
    check('A Folga dated inside a confirmed break is suppressed (not shown as a duplicate tile)',
      !/Folga Inside Break/.test(folgaVsBreak));
    check('The break itself still renders once, covering its full range',
      (folgaVsBreak.match(/Pausa da Páscoa/g) || []).length === 1);
    check('A stand-alone Folga outside any break still renders normally',
      /Folga Standalone/.test(folgaVsBreak));

    // Folga/break tiles carry a "wait for the coach" disclaimer — a
    // friendly may still be arranged on a Folga date, a tournament may
    // still be slotted into a break (Victor, 2026-11-01). Milestones and
    // match rows must NOT pick up either note.
    const notesHtml = await page.evaluate(() => {
      const games = [{ date: '2027-05-01', opponent: 'Note-Free FC', competitionType: 'League', tournamentId: null }];
      const calendarEvents = [
        { type: 'folga', title: 'Folga With Note', startDate: '2027-05-10', endDate: '2027-05-10' },
        { type: 'break', subtype: 'christmas', title: 'Break With Note', startDate: '2027-05-15', endDate: '2027-05-20' },
        { type: 'milestone', title: 'Milestone No Note', startDate: '2027-05-25', endDate: '2027-05-25' },
      ];
      return renderSeasonCalendar(games, [], calendarEvents);
    });
    // Language-agnostic (the page's default language may be PT or EN): a
    // tile with a note has TWO cal-box-meta divs (range + note), one
    // without has just the range. Bound each tile's fragment up to the
    // next tile/row so a later box's meta divs never leak into the count.
    const tileMetaCount = title => {
      // Folga/break tiles now get a 📅 icon prefix ahead of the title text
      // (mockup §3) — match it optionally so this stays agnostic to
      // whichever kind of tile is being checked (milestone tiles have no
      // icon).
      const m = notesHtml.match(new RegExp('<div class="cal-box-title">(?:\\S+ )?' + title + '</div>([\\s\\S]*?)(?=<div class="cal-box-title">|<div class="match-card|$)'));
      if (!m) return -1;
      return (m[1].match(/cal-box-meta/g) || []).length;
    };
    // Single-day items (Folga, this milestone) no longer repeat their date
    // as a separate meta line — the tile's own date column (added
    // 2026-11-01, "the folga dates are not the same as the others") already
    // shows it, so a second textual date line would just be redundant.
    // Only a genuine multi-day range (the break) still needs the explicit
    // range text, since the date column can only anchor to one day.
    check('A Folga tile shows an extra note beyond its date (single day, no separate range line)', tileMetaCount('Folga With Note') === 1);
    check('A break tile shows an extra note beyond its date range (multi-day, keeps the explicit range line)', tileMetaCount('Break With Note') === 2);
    check('A milestone tile shows NO extra note and no separate range line (single day, nothing beyond the date column)', tileMetaCount('Milestone No Note') === 0);
    check('An ordinary match row carries no cal-box note markup at all', !/Note-Free FC[\s\S]{0,300}cal-box-meta/.test(notesHtml));

    // Month grouping (Victor, 2026-11-01: "group by month ... so it's
    // easier to see by block"). Items spanning 3 distinct months must get
    // exactly 3 headers, each immediately preceding its own month's items,
    // with no repeated header for a second item in the same month.
    const monthGroupHtml = await page.evaluate(() => {
      const games = [
        { date: '2026-11-07', opponent: 'Nov Match A', competitionType: 'League', tournamentId: null },
        { date: '2026-11-21', opponent: 'Nov Match B', competitionType: 'League', tournamentId: null },
        { date: '2026-12-05', opponent: 'Dec Match', competitionType: 'League', tournamentId: null },
      ];
      const calendarEvents = [
        { type: 'milestone', title: 'Jan Milestone', startDate: '2027-01-15', endDate: '2027-01-15' },
      ];
      return renderSeasonCalendar(games, [], calendarEvents);
    });
    check('Exactly 3 month headers rendered for 3 distinct months (Nov/Dec/Jan)',
      (monthGroupHtml.match(/cal-month-header/g) || []).length === 3);
    check('Both November items sit under the SAME single November header (not duplicated)',
      (monthGroupHtml.slice(0, monthGroupHtml.indexOf('Nov Match B')).match(/cal-month-header/g) || []).length === 1);
    check('Each month header shows the correct dynamically-computed event count (2 for November, 1 each for December/January)',
      /Novembro de 2026[\s\S]{0,40}2 eventos/.test(monthGroupHtml) &&
      /Dezembro de 2026[\s\S]{0,40}1 evento(?!s)/.test(monthGroupHtml) &&
      /Janeiro de 2027[\s\S]{0,40}1 evento(?!s)/.test(monthGroupHtml));
    check('Chronological order preserved: November header before December header before January header',
      monthGroupHtml.indexOf('Nov Match A') < monthGroupHtml.indexOf('Dec Match') &&
      monthGroupHtml.indexOf('Dec Match') < monthGroupHtml.indexOf('Jan Milestone'));

    // A multi-day range (a break or tournament) must NOT get the
    // single-day date column match cards and single-day tiles (Folga,
    // a one-day milestone) use — anchoring a range's column to its start
    // date falsely implied it coincided with whatever match happens to
    // land on that same start date (Victor, 2026-11-01, seeing Pausa de
    // Natal's column show "19 DEZ", the same day a League game was
    // played: "How can I have Christmas break and a game on the same
    // date?"). A range instead keeps only its explicit "start → end"
    // text — a single-day item still gets the column.
    const rangeVsSingleDay = await page.evaluate(() => {
      const games = [{ date: '2026-12-19', opponent: 'Last Match Before Break', competitionType: 'League', tournamentId: null }];
      const calendarEvents = [
        { type: 'break', subtype: 'christmas', title: 'Range Break', startDate: '2026-12-19', endDate: '2027-01-04' },
        { type: 'folga', title: 'Single Day Folga', startDate: '2026-11-28', endDate: '2026-11-28' },
      ];
      return renderSeasonCalendar(games, [], calendarEvents);
    });
    // Bound each tile to its own fragment — from the last tile-opening tag
    // before its title text, up to the next tile-opening tag (cal-box or
    // match-card) after it — same technique as tileMetaCount above, so a
    // neighbouring tile's markup never leaks into the check.
    const tileFragment = (html, title) => {
      const titleIdx = html.indexOf(title);
      if (titleIdx === -1) return '';
      // Lookahead for a quote or space after cal-box/match-card excludes
      // hyphenated modifier classes (cal-box-title, match-card-date, etc.)
      // which would otherwise also match this prefix.
      const openTagRe = /<div class="(?:cal-box|match-card)(?=["\s])/g;
      let start = 0, m;
      while ((m = openTagRe.exec(html)) && m.index < titleIdx) start = m.index;
      openTagRe.lastIndex = titleIdx;
      const next = openTagRe.exec(html);
      const end = next ? next.index : html.length;
      return html.slice(start, end);
    };
    const rangeBreakFragment = tileFragment(rangeVsSingleDay, 'Range Break');
    const folgaFragment = tileFragment(rangeVsSingleDay, 'Single Day Folga');
    check('A multi-day range tile (Pausa de Natal) does NOT get a single-day date column',
      !rangeBreakFragment.includes('match-card-date'));
    check('A multi-day range tile still shows its explicit start → end range as text',
      /19\/12\/2026.*→.*04\/01\/2027/.test(rangeBreakFragment));
    check('A genuine single-day tile (an ordinary Folga) STILL gets the date column',
      folgaFragment.includes('match-card-date'));

    // calMonthLabel itself: capitalised, includes the year, language-aware.
    const monthLabels = await page.evaluate(() => ({
      nov2026: calMonthLabel('2026-11-07'),
      jan2027: calMonthLabel('2027-01-01'),
    }));
    check('calMonthLabel capitalises the month name and includes the year',
      /^[A-ZÀ-Ý]/.test(monthLabels.nov2026) && monthLabels.nov2026.includes('2026'));
    check('calMonthLabel produces a different label for a different month',
      monthLabels.nov2026 !== monthLabels.jan2027);

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
    // Widened lookahead (80 -> 260) to span the tile's own date column
    // markup (weekday/day/month divs, added 2026-11-01), which now sits
    // between the opening tile tag and the title text.
    check('A Folga/break item gets the cal-pause highlight class', /cal-box cal-pause"[^>]*>[\s\S]{0,350}Folga Futura/.test(todaySplit.html));
    check('A milestone item gets the cal-milestone highlight class', /cal-box cal-milestone"[^>]*>[\s\S]{0,350}Marco Futuro/.test(todaySplit.html));
    // Jogos Tab UX Improvements (spec, 2026): calendar game items are no
    // longer flattened cal-box tiles — they reuse renderUpcomingMatchRow's
    // richer match-card (opponent, date/time, home/away, venue,
    // directions), so an ordinary upcoming fixture must render via THAT
    // markup, not a cal-box, and must never pick up the pause/milestone
    // highlight classes.
    check('An ordinary upcoming fixture renders via the rich match card (not a cal-box tile)',
      /<div class="match-card[^"]*"[^>]*>[\s\S]{0,300}?Future Opponent FC/.test(todaySplit.html));
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

    // Jornada/round number (Victor, 2026-11-01): the public RPC previously
    // never selected games.round, so this was always blank on the Parents
    // Page even though roundLabel()/renderResultRow()/
    // renderUpcomingMatchRow() already supported it — the fix was an RPC
    // change (migration 007), not a front-end one. These checks lock the
    // already-existing front-end behaviour in place: round shows when
    // present, is silently omitted when absent (friendlies/tournament
    // games typically have no round), and is translated per language.
    const roundRows = await page.evaluate(() => {
      const withRound = { opponent: 'Round Match', date: '2027-05-01', gameTime: '15:00', homeAway: 'Home', venue: 'Ground', competitionType: 'League', tournamentId: null, round: '10' };
      const noRound = { opponent: 'Friendly Town FC', date: '2027-05-08', gameTime: '15:00', homeAway: 'Home', venue: 'Ground', competitionType: 'Friendly', tournamentId: null };
      const resultWithRound = { opponent: 'Round Result', ourScore: 2, opponentScore: 1, homeAway: 'Home', competitionType: 'League', tournamentId: null, round: '12' };
      setLang('en');
      const enUpcoming = renderUpcomingMatchRow(withRound, 0);
      const enResult = renderResultRow(resultWithRound, []);
      setLang('pt');
      const ptUpcoming = renderUpcomingMatchRow(withRound, 0);
      const ptResult = renderResultRow(resultWithRound, []);
      const noRoundUpcoming = renderUpcomingMatchRow(noRound, 0);
      setLang('pt'); // restore the page's default language for later checks
      return { enUpcoming, enResult, ptUpcoming, ptResult, noRoundUpcoming };
    });
    check('renderUpcomingMatchRow shows "Round 10" in English when g.round is set', /Round 10/.test(roundRows.enUpcoming));
    check('renderUpcomingMatchRow shows "Jornada 10" in Portuguese when g.round is set', /Jornada 10/.test(roundRows.ptUpcoming));
    check('renderResultRow shows "Round 12" in English when g.round is set', /Round 12/.test(roundRows.enResult));
    check('renderResultRow shows "Jornada 12" in Portuguese when g.round is set', /Jornada 12/.test(roundRows.ptResult));
    check('renderUpcomingMatchRow omits round text entirely when g.round is absent', !/Round |Jornada /.test(roundRows.noRoundUpcoming));

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
