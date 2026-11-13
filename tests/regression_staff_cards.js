// Regression tests for coach/staff cards (scorerType 'staff').
//   A. Admin app (index.html): the Add Card dialog saves a staff card with the
//      right payload, staff cards stay out of player totals and dismissals,
//      the Cards tab labels them, and an existing player card still saves as before.
//   B. Parents Page (team.html): a staff card is labelled "Coach/Staff"
//      (never "Unknown"), and player cards render as before.
// No network and no real data: the admin DB layer is replaced by an
// in-memory stub, and team.html's RPC is mocked.
// Run: node tests/regression_staff_cards.js
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch();
  const failures = [];
  const check = (label, cond, detail) => { if (!cond) failures.push(label); console.log((cond ? 'PASS' : 'FAIL') + ' — ' + label + (cond || detail === undefined ? '' : '  [' + detail + ']')); };

  // ── A. Admin app ─────────────────────────────────────────────────────
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  await page.route(/^https?:\/\//, r => r.abort());
  await page.addInitScript(() => { try { localStorage.setItem('nexteleven_lang', 'en'); } catch (e) {} });
  await page.goto('file://' + path.resolve(__dirname, '../index.html'));
  await page.waitForTimeout(1200);

  const admin = await page.evaluate(async () => {
    const out = {};
    I18n.set('EN');
    // In-memory stand-ins for the pieces the dialog touches.
    const store = [];
    let nextId = 1;
    DB.get = async (s, id) => s === 'games' ? { gameId: 256, seasonId: 6, date: '2026-11-14', gameTime: '17:00' } : store.find(c => c.cardEventId === id) || null;
    DB.getAll = async (s) => s === 'cardEvents' ? store.slice() : s === 'gamePlayers' ? [{ gameId: 256, playerId: 121, calledUp: true }] : [];
    DB.put = async (s, row) => { if (row.cardEventId == null) { row.cardEventId = nextId++; store.push(row); } return row.cardEventId; };
    window.checkGameEditableOrWarn = () => true;
    window._gdPlayers = [{ playerId: 121, fullName: 'Test Player', shirtNumber: 9 }];
    window._gdTempPlayers = [];
    if (!document.getElementById('gdPanel-cards')) { const d = document.createElement('div'); d.id = 'gdPanel-cards'; document.body.appendChild(d); }
    const $ = id => document.getElementById(id);
    const vis = id => getComputedStyle($(id)).display !== 'none';

    // 1. Default dialog state is unchanged: player recipient.
    await openCardDialog(256);
    out.defaultRecipient = $('cardDialog').dataset.recipient;
    out.defaultPlayerFieldVisible = vis('cardPlayerField');
    out.defaultStaffHidden = !vis('cardStaffFields');

    // 2. Our head coach, direct red, minute 30.
    selectCardRecipient('staff');
    out.staffFieldsVisible = vis('cardStaffFields');
    out.playerFieldHiddenForStaff = !vis('cardPlayerField') && !vis('cardOpponentFields');
    selectCardType('direct_red');
    $('cardStaffRole').value = 'head_coach';
    $('cardStaffName').value = 'Mister Test';
    $('cardMinuteInput').value = '30';
    await saveCardDialog();
    out.staffRed = JSON.parse(JSON.stringify(store[0] || null));

    // 3. Opponent assistant coach, yellow then second yellow (links to the yellow).
    await openCardDialog(256);
    selectCardTeam('opponent'); selectCardRecipient('staff'); selectCardType('yellow');
    $('cardStaffRole').value = 'assistant_coach'; $('cardMinuteInput').value = '40';
    await saveCardDialog();
    await openCardDialog(256);
    selectCardTeam('opponent'); selectCardRecipient('staff');
    $('cardStaffRole').value = 'assistant_coach';
    selectCardType('second_yellow');
    await updateSecondYellowCheck();
    $('cardMinuteInput').value = '55';
    await saveCardDialog();
    out.oppSecondYellow = JSON.parse(JSON.stringify(store[2] || null));
    out.oppYellowId = store[1] && store[1].cardEventId;

    // 4. A normal player yellow still saves exactly as before.
    await openCardDialog(256);
    $('cardMinuteInput').value = '60';
    await saveCardDialog();
    out.playerCard = JSON.parse(JSON.stringify(store[3] || null));

    // 5. Totals: staff counted apart; player totals and dismissals untouched.
    out.totals = computeCardTotals(store);

    // 6. Player stats ignore staff cards.
    const s = Calc.playerSeasonStats(121, [{ gameId: 256, seasonId: 6 }], [{ gameId: 256, playerId: 121, calledUp: true }], null, store);
    out.playerStatsYellow = s.yellowCards !== undefined ? s.yellowCards : s.yellow;
    out.playerStatsRed = s.redCards !== undefined ? s.redCards : s.red;

    // 7. Cards tab rendering.
    await renderCardsTab(256);
    out.tabText = $('gdPanel-cards').innerText;
    out.staffTotalsRow = !!$('cardStaffTotals');

    // 8. Editing a staff card reopens it as staff with its values.
    await openCardDialog(256, store[0].cardEventId);
    out.editRecipient = $('cardDialog').dataset.recipient;
    out.editRole = $('cardStaffRole').value;
    out.editName = $('cardStaffName').value;
    out.editStaffVisible = vis('cardStaffFields');
    cancelCardDialog();
    return out;
  }).catch(e => ({ error: String(e && e.stack || e) }));

  if (admin.error) { check('admin test ran without error', false, admin.error); }
  else {
    check('default recipient is Player, player field visible, staff fields hidden', admin.defaultRecipient === 'player' && admin.defaultPlayerFieldVisible && admin.defaultStaffHidden);
    check('staff selection shows role/name and hides player and shirt fields', admin.staffFieldsVisible && admin.playerFieldHiddenForStaff);
    const r = admin.staffRed || {};
    check('our coach red saved: staff, head_coach, name, direct_red, minute 30, no player id', r.scorerType === 'staff' && r.team === 'us' && r.staffRole === 'head_coach' && r.staffName === 'Mister Test' && r.cardType === 'direct_red' && r.minute === 30 && r.scorerId === null && r.seasonId === 6, JSON.stringify(r));
    const o = admin.oppSecondYellow || {};
    check('opponent staff 2nd yellow links to that staff member\'s earlier yellow', o.scorerType === 'staff' && o.team === 'opponent' && o.cardType === 'second_yellow' && o.linkedEventId === admin.oppYellowId, JSON.stringify(o));
    const p = admin.playerCard || {};
    check('player card unchanged: player:121, yellow, no staff fields', p.scorerType === 'player' && p.scorerId === 121 && p.cardType === 'yellow' && p.staffRole === null && p.staffName === null, JSON.stringify(p));
    const t = admin.totals;
    check('player totals exclude staff cards (us: 1 yellow, 0 red, 0 dismissals)', t.us.yellow === 1 && t.us.red === 0 && t.us.dismissals === 0, JSON.stringify(t));
    check('opponent player totals exclude staff cards (0/0/0)', t.opponent.yellow === 0 && t.opponent.red === 0 && t.opponent.dismissals === 0, JSON.stringify(t));
    check('staff totals: us 0 yellow 1 red; opponent 2 yellow 1 red', t.us.staffYellow === 0 && t.us.staffRed === 1 && t.opponent.staffYellow === 2 && t.opponent.staffRed === 1, JSON.stringify(t));
    check('player season stats ignore staff cards (1 yellow, 0 red)', admin.playerStatsYellow === 1 && admin.playerStatsRed === 0, admin.playerStatsYellow + '/' + admin.playerStatsRed);
    check('Cards tab labels the coach with role and name', /Head coach · Mister Test/.test(admin.tabText), admin.tabText);
    check('Cards tab shows a separate Coach / Staff totals row', admin.staffTotalsRow && /Coach \/ Staff/.test(admin.tabText));
    check('editing a staff card reopens as staff with role and name', admin.editRecipient === 'staff' && admin.editRole === 'head_coach' && admin.editName === 'Mister Test' && admin.editStaffVisible);
  }
  await ctx.close();

  // ── B. Parents Page ──────────────────────────────────────────────────
  const page2 = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page2.addInitScript(() => { try { localStorage.setItem('nexteleven_team_lang', 'en'); } catch (e) {} });
  await page2.route('**/rpc/get_public_team_data', r => r.fulfill({ status: 200, contentType: 'application/json', body: 'null' }));
  await page2.goto('file://' + path.resolve(__dirname, '../team.html') + '?token=test');
  await page2.waitForTimeout(600);
  const strip = await page2.evaluate(() => renderCardEventsStrip({
    guestPlayers: [],
    cardEvents: [
      { team: 'us', scorerType: 'staff', scorerId: null, cardType: 'direct_red', minute: '30', stoppageMinute: null },
      { team: 'opponent', scorerType: 'staff', scorerId: null, cardType: 'yellow', minute: '40', stoppageMinute: null },
      { team: 'us', scorerType: 'player', scorerId: '121', cardType: 'yellow', minute: '60', stoppageMinute: null },
      { team: 'opponent', scorerType: null, scorerId: null, opponentShirtNumber: '7', cardType: 'yellow', minute: '70', stoppageMinute: null },
    ],
  }, [{ playerId: '121', fullName: 'Test Player' }])).catch(e => 'ERROR ' + e);
  check('parents page: our staff red shows 🟥 Coach/Staff 30\'', /🟥<\/span> Coach\/Staff 30/.test(strip), strip);
  check('parents page: opponent staff card labelled Opponent · Coach/Staff', /Opponent (&middot;|·) Coach\/Staff 40/.test(strip), strip);
  check('parents page: no "Unknown" for staff cards', (strip.match(/Unknown/g) || []).length === 0, strip);
  check('parents page: opponent player card unchanged (Opponent #7)', /Opponent #7 70/.test(strip), strip);

  console.log('\n' + (failures.length ? failures.length + ' FAILURE(S):\n' + failures.join('\n') : 'All checks passed.'));
  await browser.close();
  process.exit(failures.length ? 1 : 0);
})();
