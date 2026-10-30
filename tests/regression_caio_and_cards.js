// Focused regression tests for this PR:
//   1. Caio Andrade shows up as ONE permanent player with his historical
//      totals correctly attributed, and is never listed as a guest.
//   2. A direct red card renders as a red card icon on the Parents Page
//      (regression for the 'red' vs 'direct_red' cardType mismatch fixed
//      in team.html's cardEventIcon() and the get_public_team_data RPC).
//
// Drives team.html directly via Playwright, mocking the
// get_public_team_data RPC response with the shape the fixed RPC returns
// AFTER the pending Supabase migrations in supabase/migrations_pending/
// are applied (playerId 134 for Caio, no tempPlayerId references, a
// cardType:'direct_red' event). This is the same mocking technique used
// for the card-tracking feature's own tests.
//
// Run: node tests/regression_caio_and_cards.js
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
      { playerId: 101, fullName: 'Existing Player', shirtNumber: 10, primaryPosition: 'Striker' },
      // Caio: converted to permanent — isActive, no tempPlayerId anywhere.
      { playerId: 134, fullName: 'Caio Andrade', shirtNumber: null, primaryPosition: null },
    ],
    games: [
      { gameId: 250, date: '2026-09-10', gameTime: '15:00', opponent: 'Opp A', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 0, ourScore: 1, guestPlayers: [], goalEvents: [], goalScorers: [{ playerId: 134, goals: 1 }], cardEvents: [] },
      { gameId: 251, date: '2026-09-17', gameTime: '15:00', opponent: 'Opp B', homeAway: 'Away', competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 2, ourScore: 2, guestPlayers: [], goalEvents: [], goalScorers: [], cardEvents: [] },
      { gameId: 252, date: '2026-10-01', gameTime: '15:00', opponent: 'Opp C', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 1, ourScore: 5, guestPlayers: [], goalEvents: [], goalScorers: [{ playerId: 134, goals: 4 }], cardEvents: [] },
      // game 253: Caio's yellow card + a direct red card for the OTHER
      // player, to test the icon fix independently of the conversion.
      { gameId: 253, date: '2026-10-22', gameTime: '15:00', opponent: 'Opp D', homeAway: 'Home', competitionType: 'League', competitionName: 'Liga Distrital', opponentScore: 1, ourScore: 2, guestPlayers: [], goalEvents: [], goalScorers: [{ playerId: 134, goals: 2 }],
        cardEvents: [
          { team: 'us', scorerId: 134, scorerType: 'player', cardType: 'yellow', minute: 72, stoppageMinute: null },
          { team: 'us', scorerId: 101, scorerType: 'player', cardType: 'direct_red', minute: 80, stoppageMinute: null },
        ] },
    ],
    gamePlayers: [
      { gameId: 250, playerId: 134, calledUp: true, role: 'Starter', goals: 1, assists: 0, playedFullGame: true, positionPlayed: 'Attacking Midfielder', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 251, playerId: 134, calledUp: true, role: 'Starter', goals: 0, assists: 0, playedFullGame: true, positionPlayed: 'Left Back', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 252, playerId: 134, calledUp: true, role: 'Starter', goals: 4, assists: 1, playedFullGame: true, positionPlayed: 'Central Midfielder', cardYellowCount: 0, cardRedCount: 0 },
      { gameId: 253, playerId: 134, calledUp: true, role: 'Starter', goals: 2, assists: 0, playedFullGame: true, positionPlayed: 'Central Midfielder', cardYellowCount: 1, cardRedCount: 0 },
      { gameId: 253, playerId: 101, calledUp: true, role: 'Starter', goals: 0, assists: 0, playedFullGame: true, positionPlayed: 'Striker', cardYellowCount: 0, cardRedCount: 1 },
    ],
    availability: { available: 2, unavailable: 0, unavailablePlayers: [] },
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

  // ── Test 1: Caio appears exactly once in the roster and once in the
  // Player Statistics card — two DIFFERENT sections, each a single row,
  // never a "guest" label and never a second/duplicate row in either.
  await page.goto(PAGE_URL + '#squad');
  await page.waitForTimeout(600);
  const squadPaneText = await page.evaluate(() => document.querySelector('.pane[data-tab="squad"]').innerText);
  const rosterMentions = (squadPaneText.split('PLAYER STATISTICS')[0].match(/Caio Andrade/g) || []).length;
  const statsSectionText = squadPaneText.split('PLAYER STATISTICS')[1] || '';
  const statsMentions = (statsSectionText.match(/Caio Andrade/g) || []).length;
  check('Caio appears exactly once in the squad roster', rosterMentions === 1);
  check('Caio appears exactly once in Player Statistics (no duplicate row)', statsMentions === 1);
  check('No "guest" / temporary-player label appears for Caio', !/guest|temp(or[aá]rio)?/i.test(squadPaneText));

  // ── Test 2: season goal total for Caio = 1 + 0 + 4 + 2 = 7 — proves the
  // four historical game_players rows (including the two post-consolidation
  // ones for games 252/253) are summed once each, not double-counted.
  const caioStatsLine = statsSectionText.split('Caio Andrade')[1] || '';
  check('Season goal total is 7 (1+0+4+2, not double-counted)', /\b7\s*G\b/.test(caioStatsLine));

  // ── Test 3: direct_red card renders the red icon, not the yellow one ──
  await page.goto(PAGE_URL + '&x=2#matches');
  await page.waitForTimeout(600);
  const cardLineHtml = await page.evaluate(() => {
    const lines = [...document.querySelectorAll('.card-events-line')];
    return lines.map(l => l.innerHTML).join(' | ');
  });
  check('Direct red card renders 🟥 (not 🟨) on the match strip', cardLineHtml.includes('🟥'));
  check('Caio\'s yellow card still renders 🟨 on the match strip', cardLineHtml.includes('🟨'));

  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S):\n' + failures.join('\n') : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
