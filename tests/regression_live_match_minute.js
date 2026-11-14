// Regression test for the Parents Page live match minute (team.html) and
// second-half-aware goal minutes (public-stats-core.js).
// Run: node tests/regression_live_match_minute.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.addInitScript(() => { try { localStorage.setItem('nexteleven_team_lang', 'en'); } catch (e) {} });
  await page.route('**/rpc/get_public_team_data', r => r.fulfill({ status: 200, contentType: 'application/json', body: 'null' }));
  await page.goto('file://' + path.resolve(__dirname, '../team.html') + '?token=test');
  await page.waitForTimeout(600);
  const failures = [];
  const check = (label, cond, detail) => { if (!cond) failures.push(label); console.log((cond ? 'PASS' : 'FAIL') + ' — ' + label + (cond ? '' : '  [' + JSON.stringify(detail) + ']')); };

  const r = await page.evaluate(() => {
    const K = '2026-11-14T17:25:00.000Z';
    const at = hhmm => new Date('2026-11-14T' + hhmm + ':00.000Z');
    const g = { date: '2026-11-14', gameTime: '17:00', actualKickoffAt: K, matchDurationMins: '80' };
    const g2 = Object.assign({}, g, { secondHalfStartedAt: '2026-11-14T18:20:00.000Z' });
    const lab = (game, t) => { const x = liveMatchMinute(game, {}, at(t)); return x ? x.label : null; };
    const sum = (game) => buildMatchGoalSummary(game, [{ playerId: 1, calledUp: true, goals: 3 }], [{ playerId: 1, fullName: 'A B' }], [],
      [{ scorerId: 1, scorerType: 'player', scoredAt: '2026-11-14T17:38:47.000Z' }, { scorerId: 1, scorerType: 'player', scoredAt: '2026-11-14T17:56:59.000Z' }, { scorerId: 1, scorerType: 'player', scoredAt: '2026-11-14T18:30:00.000Z' }]).ourGoals.map(x => x.minute);
    return {
      first1: lab(g, '17:25'), first14: lab(g, '17:38'), first40: lab(g, '18:04'),
      stoppage: lab(g, '18:06'), ht: lab(g, '18:15'), longBreak: lab(g, '18:45'),
      beforeKick: lab(g, '17:20'),
      second41: lab(g2, '18:20'), second51: lab(g2, '18:30'), second80: lab(g2, '18:59'), secondOver: lab(g2, '19:03'),
      noKickoff: liveMatchMinute({ date: '2026-11-14', gameTime: '17:00' }, {}, at('17:30')),
      default90: lab({ actualKickoffAt: K }, '18:09'), default90ht: lab({ actualKickoffAt: K }, '18:20'),
      goalsNoSecond: sum(g), goalsSecond: sum(g2),
      cardsHtml: renderLiveCard({ opponent: 'X', homeAway: 'Away', ourScore: '2', opponentScore: '1', goalEvents: [], goalScorers: [], guestPlayers: [], date: '2026-11-14', actualKickoffAt: new Date(Date.now() - 10 * 60000).toISOString(), matchDurationMins: '80',
        cardEvents: [ { team: 'us', scorerType: 'player', scorerId: '121', cardType: 'yellow', minute: '12', stoppageMinute: null },
                      { team: 'opponent', scorerType: null, scorerId: null, opponentShirtNumber: '7', cardType: 'direct_red', minute: '30', stoppageMinute: null },
                      { team: 'us', scorerType: 'staff', scorerId: null, cardType: 'direct_red', minute: '35', stoppageMinute: null } ] }, { clubName: 'Us' }, [{ playerId: '121', fullName: 'Test Player' }], []),
      cardHtml: (function(){ const real = Date; return renderLiveCard(Object.assign({ opponent: 'X', homeAway: 'Away', ourScore: '2', opponentScore: '1', goalEvents: [], goalScorers: [], guestPlayers: [] }, g, { actualKickoffAt: new Date(Date.now() - 10 * 60000).toISOString() }), { clubName: 'Us' }, [], []); })(),
    };
  }).catch(e => ({ error: String(e && e.stack || e) }));

  if (r.error) check('ran without error', false, r.error);
  else {
    check("first half: kick-off minute is 1'", r.first1 === "1'", r.first1);
    check("first half: 13 min after kick-off is 14'", r.first14 === "14'", r.first14);
    check("first half: last minute is 40'", r.first40 === "40'", r.first40);
    check("first-half stoppage shows 40+'", r.stoppage === "40+'", r.stoppage);
    check('break shows Half-time', r.ht === 'Half-time', r.ht);
    check('no second-half time after a long break: nothing shown (no wrong minute)', r.longBreak === null, r.longBreak);
    check('before kick-off: nothing shown', r.beforeKick === null, r.beforeKick);
    check("second half starts at 41'", r.second41 === "41'", r.second41);
    check("second half: 10 min in is 51'", r.second51 === "51'", r.second51);
    check("second half: last minute is 80'", r.second80 === "80'", r.second80);
    check("after full time shows 80+'", r.secondOver === "80+'", r.secondOver);
    check('no recorded kick-off: nothing shown', r.noKickoff === null, r.noKickoff);
    check("default 90 min game: 45' then Half-time", r.default90 === "45'" && r.default90ht === 'Half-time', [r.default90, r.default90ht]);
    check('goal minutes without second-half time: elapsed from kick-off (14, 32, 65)', JSON.stringify(r.goalsNoSecond) === '[14,32,65]', r.goalsNoSecond);
    check('goal minutes with second-half time: break removed (14, 32, 50)', JSON.stringify(r.goalsSecond) === '[14,32,50]', r.goalsSecond);
    check("live card shows the minute next to LIVE (11')", /class="live-minute"[^>]*>· 11'</.test(r.cardHtml), r.cardHtml && r.cardHtml.slice(0, 300));
  }
  if (!r.error) {
    check('live card lists a player yellow with name and minute', /id="liveCards"[\s\S]*🟨<\/span> [^<]*Player[^<]* 12&#39;/.test(r.cardsHtml), r.cardsHtml);
    check('live card lists an opponent red (Opponent #7 30\')', /🟥<\/span> Opponent #7 30&#39;/.test(r.cardsHtml), r.cardsHtml);
    check('live card lists a coach red as Coach/Staff', /🟥<\/span> Coach\/Staff 35&#39;/.test(r.cardsHtml), r.cardsHtml);
    check('live card has no cards block when no cards are recorded', !/id="liveCards"/.test(r.cardHtml));
  }
  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S)' : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
