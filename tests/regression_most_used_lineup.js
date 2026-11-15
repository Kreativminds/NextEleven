// Regression test for the Most Used Lineup (index.html buildMostUsedLineup).
// Fixture mirrors the 2026/27 season shape on 2026-11-15 (7 official games):
// positions recorded in only some games, a substitute with zero starts who
// used to be placed in the XI, and regular starters who used to be left out.
// Run: node tests/regression_most_used_lineup.js
const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 360, height: 800 } });
  await page.route(/^https?:\/\//, r => r.abort());
  await page.goto('file://' + path.resolve(__dirname, '../index.html'));
  await page.waitForTimeout(1200);
  const failures = [];
  const check = (label, cond, detail) => { if (!cond) failures.push(label); console.log((cond ? 'PASS' : 'FAIL') + ' — ' + label + (cond ? '' : '  [' + JSON.stringify(detail) + ']')); };

  const r = await page.evaluate(() => {
    I18n.set('EN');
    // name, primary position, per-game "position/role" over 7 official games ('' = not called up)
    const squad = [
      ['Caio', 'Attacking Midfielder', ['Attacking Midfielder/Starter', 'Left Back/Starter', 'Central Midfielder/Starter', 'Central Midfielder/Starter', '-/Starter', '-/Starter', '-/Starter']],
      ['Miguel', 'Goalkeeper', ['Goalkeeper/Starter', 'Goalkeeper/Starter', '-/Starter', 'Goalkeeper/Starter', '-/Starter', '-/Starter', '-/Starter']],
      ['David', 'Striker', ['Striker/Starter', 'Striker/Starter', '-/Starter', 'Striker/Starter', '-/Starter', '-/Starter', '-/Starter']],
      ['Vicente', 'Left Winger', ['Left Winger/Starter', '-/Starter', '-/Starter', 'Left Winger/Starter', '-/Starter', '-/Starter', '-/Starter']],
      ['Lorenzo', 'Right Back', ['Right Back/Starter', 'Right Back/Starter', '-/Starter', 'Left Back/Starter', 'Left Back/Starter', 'Right Back/Starter', '-/Starter']],
      ['Diogo', 'Right Winger', ['Right Winger/Starter', '-/Starter', '-/Starter', 'Right Winger/Starter', '-/Starter', '-/Sub', '-/Starter']],
      ['Alexandre', 'Centre Back', ['', '-/Starter', '-/Starter', 'Centre Back/Starter', '-/Starter', '-/Starter', '-/Starter']],
      ['Eduardo', 'Centre Back', ['Centre Back/Starter', 'Centre Back/Starter', '-/Starter', 'Centre Back/Starter', '-/Starter', '', '']],
      ['Carlos', 'Defensive Midfielder', ['Centre Back/Starter', 'Centre Back/Sub', 'Centre Back/Starter', 'Centre Back/Starter', '-/Sub', '-/Starter', '']],
      ['William', 'Defensive Midfielder', ['-/Starter', 'Central Midfielder/Starter', '-/Sub', '-/Starter', '-/Starter', '', '']],
      ['Guilherme', 'Right Back', ['Right Back/Starter', '-/Starter', '-/Starter', '-/Starter', '', '', '']],
      ['Gustavo', 'Central Midfielder', ['-/Sub', '-/-', 'Central Midfielder/Sub', '-/Starter', '-/Starter', '-/-', '']],
      ['Rodrigo', 'Goalkeeper', ['Goalkeeper/Sub', '-/-', 'Goalkeeper/Sub', '-/Sub', '', '', '']],
      ['Octave', 'Left Winger', ['Left Back/Sub', '-/Sub', '-/Sub', '-/Sub', '', '', '']],
      ['Lucas', 'Striker', ['Striker/Sub', 'Striker/Sub', 'Striker/Sub', '-/-', '', '', '']],
    ];
    const players = squad.map((x, i) => ({ playerId: i + 1, fullName: x[0], primaryPosition: x[1], shirtNumber: i + 1, isActive: true }));
    const games = [1, 2, 3, 4, 5, 6, 7].map(gameId => ({ gameId, date: '2026-10-0' + gameId, gameTime: '15:00' }));
    // listed out of date order on purpose: the builder must sort by date itself
    games.reverse(); games.push(games.shift());
    const gp = [];
    squad.forEach((x, i) => x[2].forEach((cell, gi) => {
      if (!cell) return;
      const [pos, role] = cell.split('/');
      gp.push({ gameId: gi + 1, playerId: i + 1, calledUp: true, positionPlayed: pos === '-' ? null : pos, role: role === '-' ? null : role });
    }));
    // a friendly (not in the official list) must not count
    gp.push({ gameId: 99, playerId: 14, calledUp: true, positionPlayed: 'Left Back', role: 'Starter' });
    const names = l => ({ GK: l.GK.map(e => e.player.fullName), DEF: l.DEF.map(e => e.player.fullName + ':' + POSITION_ABBR[e.position]), MID: l.MID.map(e => e.player.fullName + ':' + POSITION_ABBR[e.position]), FWD: l.FWD.map(e => e.player.fullName + ':' + POSITION_ABBR[e.position]) });
    const lineup = buildMostUsedLineup(players, [], games, gp);
    const out = { main: names(lineup) };
    out.seasonWide = (function(){ const prev = LINEUP_RECENT_GAMES; return prev; })();
    // Lorenzo (profile Right Back) starting 2 of his 3 recent games at Left Back -> shown at Left Back
    const gpMaj = gp.map(x => (x.playerId === 5 && x.gameId === 7) ? Object.assign({}, x, { positionPlayed: 'Left Back' }) : (x.playerId === 5 && x.gameId === 6) ? Object.assign({}, x, { positionPlayed: 'Left Back' }) : x);
    const lm = buildMostUsedLineup(players, [], games, gpMaj);
    out.majority = (lm.DEF.find(e => e.player.fullName === 'Lorenzo') || {}).position;
    // rendering at phone width: 11 shirts, no horizontal overflow, translated title
    const host = document.createElement('div'); host.style.width = '320px'; host.innerHTML = renderLineupPitch(lineup, '#a33'); document.body.prepend(host);
    const pitch = host.querySelector('#mostUsedPitch');
    out.shirts = host.querySelectorAll('.pitch-player').length;
    // two-line names: first name, last name, then position; nothing cut off at 320px
    out.names = (function(){ const e = (n, pos) => ({ player: { fullName: n, shirtNumber: 1 }, position: pos });
      const d = document.createElement('div'); d.style.width = '320px';
      d.innerHTML = renderLineupPitch({ GK: [e('Miguel Cavaleiro', 'Goalkeeper')], DEF: [e('Lorenzo Morenda Ambrosio Mabere', 'Left Back'), e('Alexandre Dos Santos Cardoso', 'Centre Back'), e('Eduardo Monteiro', 'Centre Back'), e('Guilherme Jesus', 'Right Back')], MID: [e('Caio', 'Attacking Midfielder')], FWD: [] }, '#a33');
      document.body.prepend(d);
      const cells = Array.from(d.querySelectorAll('.pitch-player')).map(c => ({ lines: Array.from(c.children).slice(1).map(x => x.textContent), cut: Array.from(c.querySelectorAll('.pitch-name')).some(x => x.scrollWidth > x.clientWidth + 1) }));
      d.remove(); return cells; })();
    out.wide = (function(){ const row = host.querySelector('.pitch-row-wide'); if (!row) return null; const R = pitch.getBoundingClientRect(); const ps = Array.from(row.querySelectorAll('.pitch-player')).map(el => { const b = el.getBoundingClientRect(); return { pos: el.querySelector('.pitch-pos').textContent, c: (b.left + b.width / 2 - R.left) / R.width, top: b.top }; });
      const g = k => ps.find(x => x.pos === k); return { sameLine: Math.max(...ps.map(x => x.top)) - Math.min(...ps.map(x => x.top)) < 2, lwLeft: g('LW').c, amCentre: g('AM').c, rwRight: g('RW').c }; })();
    // midfield depth: one pitch row per midfield role, attacking first
    out.rowOrder = Array.from(host.querySelectorAll('.pitch-row')).map(row => Array.from(row.querySelectorAll('.pitch-pos')).map(x => x.textContent).join('+'));
    out.overflow = pitch.scrollWidth > pitch.clientWidth + 1;
    out.rowsOneLine = Array.from(host.querySelectorAll('.pitch-row')).every(row => { const tops = Array.from(row.children).map(c => c.getBoundingClientRect().top); return Math.max(...tops) - Math.min(...tops) < 2; });
    out.titleEN = host.querySelector('.card-title').textContent;
    I18n.set('PT'); out.titlePT = (() => { const d = document.createElement('div'); d.innerHTML = renderLineupPitch(lineup, '#a33'); return d.querySelector('.card-title').textContent; })(); I18n.set('EN');
    // no Starter roles recorded at all -> falls back to appearances
    const gpNoRole = gp.map(x => Object.assign({}, x, { role: null }));
    const l2 = buildMostUsedLineup(players, [], games, gpNoRole);
    out.noRoleCount = l2.GK.length + l2.DEF.length + l2.MID.length + l2.FWD.length;
    // inactive player never placed; empty data -> empty lineup
    const l3 = buildMostUsedLineup(players.map(p => p.fullName === 'David' ? Object.assign({}, p, { isActive: false }) : p), [], games, gp);
    out.inactivePlaced = JSON.stringify(names(l3)).includes('David');
    const l4 = buildMostUsedLineup(players, [], [], []);
    out.emptyCount = l4.GK.length + l4.DEF.length + l4.MID.length + l4.FWD.length;
    // guest starter is eligible on equal terms
    const l5 = buildMostUsedLineup(players, [{ tempPlayerId: 7, name: 'Guest ST', preferredPosition: 'Striker', shirtNumber: 77 }], games,
      gp.concat(games.map(g => ({ gameId: g.gameId, playerId: null, tempPlayerId: 7, calledUp: true, positionPlayed: 'Striker', role: 'Starter' }))));
    out.guestPlaced = l5.FWD.some(e => e.player.isGuest && e.player.fullName === 'Guest ST');
    return out;
  }).catch(e => ({ error: String(e && e.stack || e) }));

  if (r.error) check('ran without error', false, r.error);
  else {
    const m = r.main, all = [].concat(m.GK, m.DEF, m.MID, m.FWD).join(',');
    check('XI has 11 players', m.GK.length + m.DEF.length + m.MID.length + m.FWD.length === 11, m);
    check('goalkeeper is the one with most starts (Miguel)', JSON.stringify(m.GK) === '["Miguel"]', m.GK);
    check('uses the last 3 official games (window = 3)', r.seasonWide === 3, r.seasonWide);
    check('recent starters are in: Alexandre, William, Gustavo', /Alexandre/.test(all) && /William/.test(all) && /Gustavo/.test(all), all);
    check('a player who only started in older games is out (Guilherme: 4 starts, none in the last 3)', !/Guilherme/.test(all), all);
    check('zero-start substitute is out (Octave), even with a friendly start', !/Octave/.test(all), all);
    check('substitutes are out (Lucas, Rodrigo)', !/Lucas|Rodrigo/.test(all), all);
    check('defence: Lorenzo, Alexandre, Eduardo — Carlos is NOT a defender', JSON.stringify(m.DEF) === '["Alexandre:CB","Eduardo:CB","Lorenzo:RB"]', m.DEF);
    check('majority rule: a player who started most recent games in another position is shown there', r.majority === 'Left Back', r.majority);
    check('midfield uses profile positions: Carlos DM, William DM, Gustavo CM, Caio AM', JSON.stringify(m.MID) === '["Carlos:DM","William:DM","Gustavo:CM","Caio:AM"]', m.MID);
    check('attack: Vicente LW, David ST, Diogo RW', JSON.stringify(m.FWD) === '["Vicente:LW","David:ST","Diogo:RW"]', m.FWD);
    check('pitch renders 11 shirts', r.shirts === 11, r.shirts);
    check('name on two lines then position (first name, last name, position)', JSON.stringify(r.names.map(c => c.lines)) === '[["Caio","AM"],["Lorenzo","Mabere","LB"],["Alexandre","Cardoso","CB"],["Eduardo","Monteiro","CB"],["Guilherme","Jesus","RB"],["Miguel","Cavaleiro","GK"]]', r.names.map(c => c.lines));
    check('no name is cut off at 320px', r.names.every(c => !c.cut), r.names.filter(c => c.cut));
    check('midfield drawn by depth: AM row, then CM row, then DM row, between attack and defence', JSON.stringify(r.rowOrder) === '["ST","LW+AM+RW","CM","DM+DM","CB+CB+RB","GK"]', r.rowOrder);
    check('wingers are on the touchlines, level with the attacking midfielder, who is centred', r.wide && r.wide.sameLine && r.wide.lwLeft < 0.25 && r.wide.rwRight > 0.75 && Math.abs(r.wide.amCentre - 0.5) < 0.06, r.wide);
    check('no horizontal overflow and every row on one line at 320px', !r.overflow && r.rowsOneLine, [r.overflow, r.rowsOneLine]);
    check('title translated (EN / PT)', r.titleEN === 'Most Used Lineup' && r.titlePT === 'Onze Mais Utilizado', [r.titleEN, r.titlePT]);
    check('no roles recorded: falls back to appearances and still fills 11', r.noRoleCount === 11, r.noRoleCount);
    check('inactive player is never placed', r.inactivePlaced === false);
    check('no data: empty lineup', r.emptyCount === 0, r.emptyCount);
    check('guest starter is eligible', r.guestPlaced === true);
  }
  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S)' : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
