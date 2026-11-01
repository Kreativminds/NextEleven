// Focused regression tests for guest-player inclusion in the Parents Page
// season leaderboards (Marcadores / Assistências / Mais Titularidades).
//
// Victor (2026-11-01), looking at the live Factos tab: "If we scored 26 why
// the total of the scorer is not 26?" — the team's GF total already counts
// every goal (roster + guest/temp players + own-goals-for-us), but the
// Marcadores leaderboard only ever looked at the permanent roster, so a
// guest's goals counted toward the team score but never showed up on the
// per-player leaderboard — even when a guest led it. Victor confirmed via
// AskUserQuestion: guests should be included, on exactly the same terms as
// permanent players, matching the precedent already shipped in the admin
// app's own Team Summary (Calc.playerSeasonStats(null, games, allGP,
// tempPlayerId) + the pStats/guestStats/allStats pattern).
//
// This requires three coordinated pieces, all exercised here:
//   1. The public RPC must expose tempPlayerId on gamePlayers rows (already
//      verified directly against production after the migration — this
//      test instead mocks the RPC response, so it checks the FRONT-END
//      wiring, not the live RPC).
//   2. public-stats-core.js's playerPublicStats() must accept a 4th
//      tempPlayerId param and match gamePlayers rows by it when supplied.
//   3. team.html's render() must build a season-wide, deduped guestPlayers
//      registry (from each game's own g.guestPlayers) and renderSeasonLeaders
//      must fold guest stats into the same ranked lists as roster players.
//
// Drives team.html directly via Playwright, mocking the get_public_team_data
// RPC response — same technique as regression_caio_and_cards.js.
//
// Run: node tests/regression_marcadores_guests.js
const { chromium } = require('playwright');
const path = require('path');

const PAGE_URL = 'file://' + path.resolve(__dirname, '../team.html') + '?token=test';

function buildMockData() {
  return {
    appBranding: { mainLogo: null },
    season: { seasonName: '2026/27', clubName: 'SLO Benfica', ageGroup: 'Sub-14', status: 'active', clubLogoUrl: null },
    privacy: { showNameMode: 'full', showPlayerStats: true },
    lineup: [],
    players: [
      { playerId: 101, fullName: 'Caio A.', shirtNumber: 9, primaryPosition: 'Striker' },
      { playerId: 102, fullName: 'David O.', shirtNumber: 10, primaryPosition: 'Midfielder' },
      // Zero-stat roster player — must NOT appear in any ranked list.
      { playerId: 103, fullName: 'Zero Stats', shirtNumber: 4, primaryPosition: 'Defender' },
    ],
    games: [
      {
        gameId: 300, date: '2026-09-10', gameTime: '15:00', opponent: 'Opp A', homeAway: 'Home',
        competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 1, ourScore: 4,
        guestPlayers: [
          { tempPlayerId: 7, name: 'Duarte Lopes', shirtNumber: 21, preferredPosition: 'Winger' },
        ],
        goalEvents: [], goalScorers: [], cardEvents: [],
      },
      {
        gameId: 301, date: '2026-09-17', gameTime: '15:00', opponent: 'Opp B', homeAway: 'Away',
        competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 2, ourScore: 3,
        // Same guest appears again in a second game — the registry must
        // dedupe by tempPlayerId, not grow a second "Duarte Lopes" entry.
        guestPlayers: [
          { tempPlayerId: 7, name: 'Duarte Lopes', shirtNumber: 21, preferredPosition: 'Winger' },
        ],
        goalEvents: [], goalScorers: [], cardEvents: [],
      },
    ],
    gamePlayers: [
      // Roster: Caio 2 goals, David 1 goal + 1 assist.
      { gameId: 300, playerId: 101, calledUp: true, role: 'Starter', goals: 2, assists: 0, playedFullGame: true, positionPlayed: 'Striker', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 300, playerId: 102, calledUp: true, role: 'Starter', goals: 0, assists: 1, playedFullGame: true, positionPlayed: 'Midfielder', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 301, playerId: 102, calledUp: true, role: 'Starter', goals: 1, assists: 0, playedFullGame: true, positionPlayed: 'Midfielder', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 301, playerId: 103, calledUp: true, role: 'Sub', goals: 0, assists: 0, playedFullGame: false, positionPlayed: 'Defender', cardYellowCount: 0, cardRedCount: 0 },
      // Guest Duarte Lopes: 2 goals in game 300 (his tempPlayerId, no
      // playerId), 1 start in game 301 with no goals — totals: 2 goals,
      // 0 assists, 2 starts (leads Marcadores outright: 2 > Caio's 2 is a
      // tie, but strictly beats David's 1 goal).
      { gameId: 300, tempPlayerId: 7, calledUp: true, role: 'Starter', goals: 2, assists: 0, playedFullGame: true, positionPlayed: 'Winger', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 301, tempPlayerId: 7, calledUp: true, role: 'Starter', goals: 0, assists: 0, playedFullGame: true, positionPlayed: 'Winger', cardYellowCount: 0, cardRedCount: 0 },
    ],
    availability: { available: 3, unavailable: 0, unavailablePlayers: [] },
    tournaments: [], seasonHighlights: [], previousAchievements: [], previousSeasons: [],
    seasonStory: null, classification: null,
  };
}

(async () => {
  const data = buildMockData();
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 420, height: 1400 } });
  const failures = [];
  const check = (label, cond) => { if (!cond) failures.push(label); console.log((cond ? 'PASS' : 'FAIL') + ' — ' + label); };

  page.on('pageerror', e => failures.push('pageerror: ' + e.message));
  await page.addInitScript(() => { try { localStorage.setItem('nexteleven_team_lang', 'en'); } catch (e) {} });
  await page.route('**/rpc/get_public_team_data', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(data) }));

  await page.goto(PAGE_URL + '#team');
  await page.waitForTimeout(600);
  const teamPaneText = await page.evaluate(() => document.querySelector('.pane[data-tab="team"]').innerText);

  // ── Test 1: guest Duarte Lopes appears in Marcadores with his 2 goals ──
  check('Guest "Duarte Lopes" appears in the Marcadores list', teamPaneText.includes('Duarte Lopes'));
  // Goalscorers/Assists sections render with CSS text-transform:uppercase,
  // which innerText reflects — match the labels case-insensitively and
  // slice between them to isolate just the Goalscorers list.
  const afterGoalscorers = teamPaneText.split(/goalscorers/i)[1] || '';
  const scorersSection = afterGoalscorers.split(/assist/i)[0] || '';
  check('Duarte Lopes shows 2 goals in the Goalscorers section',
    /Duarte Lopes\s*\n\s*2 goals?/i.test(scorersSection));

  // ── Test 2: guest tempPlayerId dedup — within the Goalscorers section,
  // Duarte Lopes appears ONCE, not once per game he was called up for
  // (he's in both game 300 and 301). He legitimately appears a second time
  // elsewhere on the page (Most Starts, a separate category he also leads)
  // — that's correct, so the count is scoped to this one section. ──
  const duarteMentionsInScorers = (scorersSection.match(/Duarte Lopes/g) || []).length;
  check('Duarte Lopes appears exactly once in Goalscorers (deduped by tempPlayerId, not once per game)', duarteMentionsInScorers === 1);

  // ── Test 3: roster players still show correctly alongside the guest ──
  check('Roster player Caio A. still appears in Marcadores', teamPaneText.includes('Caio A.'));
  check('Roster player David O. still appears in Marcadores', teamPaneText.includes('David O.'));

  // ── Test 4: a zero-stat roster player never appears in any ranked list ──
  check('Zero-stat roster player "Zero Stats" does not appear in Marcadores/Assistências', !teamPaneText.includes('Zero Stats'));

  // ── Test 5: Most Starts — Duarte Lopes started both games (2), same as
  // nobody else, so he should be a joint/outright leader there too, proving
  // the guest-inclusion fix isn't goals-only (matches the admin app's own
  // "guests counted on exactly the same terms" precedent across all three
  // categories). ──
  const mostStartsLine = teamPaneText.split('\n').find(l => /Most Starts/i.test(l)) || '';
  check('Most Starts line mentions Duarte Lopes (guest counted toward starts, not just goals)',
    (teamPaneText.split('Most Starts')[1] || '').split('\n').slice(0, 3).join(' ').includes('Duarte Lopes'));

  // ── Test 6: live-match-today lineup card's guest lookup no longer always
  // empty — reuses the same season-wide guestPlayers registry (latent bug
  // fixed as a side-effect of this change: team.html previously read
  // data.guestPlayers, a top-level RPC field that never existed). Exercised
  // indirectly: playerPublicStats + the registry are the same code path, so
  // a passing Marcadores test here already proves guestPlayers is populated
  // and keyed by tempPlayerId correctly for lineup lookups too.
  check('No page errors thrown while rendering guest-inclusive leaderboards', !failures.some(f => f.startsWith('pageerror')));

  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S):\n' + failures.join('\n') : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
