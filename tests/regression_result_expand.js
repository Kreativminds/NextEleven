// Regression test for the Parents Page tap-to-expand result rows (team.html).
// Run: node tests/regression_result_expand.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 360, height: 800 }, hasTouch: true });
  await page.addInitScript(() => { try { localStorage.setItem('nexteleven_team_lang', 'en'); } catch (e) {} });
  await page.route('**/rpc/get_public_team_data', r => r.fulfill({ status: 200, contentType: 'application/json', body: 'null' }));
  await page.goto('file://' + path.resolve(__dirname, '../team.html') + '?token=test');
  await page.waitForTimeout(600);
  const failures = [];
  const check = (label, cond, detail) => { if (!cond) failures.push(label); console.log((cond ? 'PASS' : 'FAIL') + ' — ' + label + (cond ? '' : '  [' + JSON.stringify(detail) + ']')); };

  const r = await page.evaluate(async () => {
    const players = [{ playerId: '134', fullName: 'Caio Andrade' }, { playerId: '130', fullName: 'David Oliveira' }];
    const base = { opponent: 'Alta de Lisboa', homeAway: 'Away', opponentScore: '1', guestPlayers: [], cardEvents: [] };
    // full timing: real kick-off + second-half start
    const gFull = Object.assign({}, base, { gameId: '256', date: '2026-11-14', gameTime: '17:00', ourScore: '3', actualKickoffAt: '2026-11-14T17:25:00.000Z', secondHalfStartedAt: '2026-11-14T18:31:00.000Z', matchDurationMins: '80',
      goalScorers: [{ playerId: '130', calledUp: 'true', goals: '1' }, { playerId: '134', calledUp: 'true', goals: '2' }],
      goalEvents: [{ scorerId: '130', scorerType: 'player', scoredAt: '2026-11-14T17:38:47.000Z' }, { scorerId: '134', scorerType: 'player', scoredAt: '2026-11-14T17:56:59.000Z' }, { scorerId: '134', scorerType: 'player', scoredAt: '2026-11-14T19:01:15.000Z' }],
      cardEvents: [{ team: 'us', scorerType: 'player', scorerId: '134', cardType: 'yellow', minute: '33', stoppageMinute: null }] });
    // scheduled time only: minutes cannot be trusted
    const gOld = Object.assign({}, base, { gameId: '253', date: '2026-10-24', gameTime: '14:00', ourScore: '3',
      goalScorers: [{ playerId: '134', calledUp: 'true', goals: '2' }, { playerId: '130', calledUp: 'true', goals: '1' }],
      goalEvents: [{ scorerId: '134', scorerType: 'player', scoredAt: '2026-10-24T15:10:00.000Z' }, { scorerId: '134', scorerType: 'player', scoredAt: '2026-10-24T15:19:00.000Z' }, { scorerId: '130', scorerType: 'player', scoredAt: '2026-10-24T15:23:00.000Z' }] });
    // real kick-off, no second-half start: first-half minute trusted, second-half not
    const gHalf = Object.assign({}, base, { gameId: '255', date: '2026-11-07', gameTime: '14:00', ourScore: '2', actualKickoffAt: '2026-11-07T14:05:00.000Z',
      goalScorers: [{ playerId: '130', calledUp: 'true', goals: '1' }, { playerId: '134', calledUp: 'true', goals: '1' }],
      goalEvents: [{ scorerId: '130', scorerType: 'player', scoredAt: '2026-11-07T14:33:00.000Z' }, { scorerId: '134', scorerType: 'player', scoredAt: '2026-11-07T15:25:00.000Z' }] });
    const gNone = Object.assign({}, base, { gameId: '249', date: '2026-09-12', gameTime: '10:00', ourScore: '0', opponentScore: '4', goalScorers: [], goalEvents: [] });
    const host = document.createElement('div'); host.className = 'card'; host.style.width = '328px'; document.body.prepend(host);
    const draw = () => { host.innerHTML = [gFull, gOld, gHalf, gNone].map(g => renderResultRow(g, players)).join(''); };
    draw();
    const txt = el => el.textContent.replace(/\s+/g, ' ').trim();
    const d = host.querySelectorAll('details.res');
    const out = { expandable: d.length, plainRows: host.querySelectorAll(':scope > .row').length };
    out.closedByDefault = Array.from(d).every(x => !x.open);
    out.detailHiddenWhenClosed = d[0].querySelector('.res-detail').getBoundingClientRect().height === 0 || (d[0].querySelector('.res-detail').checkVisibility ? !d[0].querySelector('.res-detail').checkVisibility({ contentVisibilityAuto: true, checkVisibilityCSS: true }) : false);
    out.dbg = [Array.from(d).map(x => x.open), d[0].querySelector('.res-detail').getBoundingClientRect().height, d[0].getBoundingClientRect().height, d[0].querySelector('summary').getBoundingClientRect().height];
    out.rowTextUnchanged = /Alta de Lisboa/.test(txt(d[0].querySelector('summary'))) && /1-3/.test(txt(d[0].querySelector('summary')));
    d[0].querySelector('summary').click();
    await new Promise(r => setTimeout(r, 50));
    out.opensInline = d[0].open && d[0].querySelector('.res-detail').getBoundingClientRect().height > 0 && location.href.indexOf('team.html') > -1;
    out.full = txt(d[0].querySelector('.res-detail'));
    out.old = txt(d[1].querySelector('.res-detail'));
    out.half = txt(d[2].querySelector('.res-detail'));
    out.cardsStillVisible = /🟨/.test(txt(host.querySelector('.card-events-line') || { textContent: '' }));
    draw(); // periodic re-render
    out.staysOpenAfterRerender = host.querySelector('details.res[data-gid="256"]').open && !host.querySelector('details.res[data-gid="253"]').open;
    host.querySelector('details.res[data-gid="256"] summary').click();
    await new Promise(r => setTimeout(r, 50)); draw();
    out.closesAgain = !host.querySelector('details.res[data-gid="256"]').open;
    out.overflow = host.scrollWidth > host.clientWidth + 1;
    return out;
  }).catch(e => ({ error: String(e && e.stack || e) }));

  if (r.error) check('ran without error', false, r.error);
  else {
    check('results with scorers are expandable (3); a result without scorers stays a plain row (1)', r.expandable === 3 && r.plainRows === 1, [r.expandable, r.plainRows]);
    check('rows are closed by default and the detail takes no space', r.closedByDefault && r.detailHiddenWhenClosed && Math.abs(r.dbg[2] - r.dbg[3]) < 1, r.dbg);
    check('the row itself still shows opponent and score', r.rowTextUnchanged);
    check('tap opens the scorers inline, on the same page', r.opensInline);
    check("full timing: scorers grouped with minutes (David 14' · Caio 32', 70')", r.full === "⚽ David Oliveira 14' · Caio Andrade 32', 70'", r.full);
    check('no real kick-off: names only, with a count (Caio ×2 · David)', r.old === '⚽ Caio Andrade ×2 · David Oliveira', r.old);
    check("real kick-off, no second-half start: first-half minute shown, second-half minute hidden", r.half === "⚽ David Oliveira 28' · Caio Andrade", r.half);
    check('card line is still visible without tapping', r.cardsStillVisible);
    check('an opened row stays open after the page re-renders; others stay closed', r.staysOpenAfterRerender);
    check('tapping again closes it', r.closesAgain);
    check('no horizontal overflow at phone width', !r.overflow);
  }
  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S)' : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
