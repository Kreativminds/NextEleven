#!/usr/bin/env node
// Targeted regression tests for the 2026-10-18 three-fix ticket:
//   1. Kickoff date/timezone bug (PR #4, cherry-picked)
//   2. goalEvents not cleared on resetGameGoals
//   3. Captain button disappearing when captain becomes unavailable
//
// Extracts the REAL function source out of index.html (same technique as
// check-syntax.js's `new Function`) and executes it against a minimal fake
// DB / DOM, so these exercise the actual shipped code, not a reimplementation.
//
// Usage: node regression.js /path/to/index.html
// Exits 1 on any failure, prints a JSON summary either way.

const fs = require('fs');
const path = process.argv[2] || require('path').join(__dirname, '..', '..', 'index.html');
const html = fs.readFileSync(path, 'utf8');

function extractFunction(src, name) {
  const marker = `function ${name}(`;
  let start = src.indexOf(marker);
  if (start === -1) throw new Error(`function ${name} not found`);
  if (src.slice(Math.max(0, start - 6), start) === 'async ') start -= 6;
  let i = src.indexOf('{', start);
  if (i === -1) throw new Error(`no body found for ${name}`);
  let depth = 0, end = -1;
  for (let j = i; j < src.length; j++) {
    if (src[j] === '{') depth++;
    else if (src[j] === '}') { depth--; if (depth === 0) { end = j; break; } }
  }
  if (end === -1) throw new Error(`unbalanced braces for ${name}`);
  return src.slice(start, end + 1);
}

const results = [];
function check(name, cond, detail) {
  results.push({ name, pass: !!cond, detail: detail || null });
}

// ── Fake DB — in-memory, mirrors the real DB module's observable contract:
// getAll() filters out isDeleted rows (DB.getAll does this centrally in the
// real app), softDelete() sets isDeleted/deletedAt/syncStatus without ever
// removing the row (so push() can still see it — same reason the real app
// doesn't use a hard delete for user-facing deletions).
function makeFakeDB() {
  const stores = { games: [], gamePlayers: [], goalEvents: [], players: [], temporaryPlayers: [] };
  const keyField = { games: 'gameId', gamePlayers: 'gamePlayerId', goalEvents: 'goalEventId', players: 'playerId', temporaryPlayers: 'tempPlayerId' };
  const nextId = { games: 1, gamePlayers: 1, goalEvents: 1, players: 1, temporaryPlayers: 1 };
  return {
    _stores: stores,
    async get(store, key) { return stores[store].find(r => r[keyField[store]] === key) || null; },
    async put(store, obj) {
      const kf = keyField[store];
      if (obj[kf] == null) obj[kf] = nextId[store]++;
      const idx = stores[store].findIndex(r => r[kf] === obj[kf]);
      if (idx >= 0) stores[store][idx] = obj; else stores[store].push(obj);
      return obj[kf];
    },
    async getAll(store, indexName, key) {
      let rows = stores[store];
      if (indexName) rows = rows.filter(r => r[indexName] === key);
      return rows.filter(r => !r.isDeleted);
    },
    async softDelete(store, key) {
      const kf = keyField[store];
      const row = stores[store].find(r => r[kf] === key);
      if (!row) return;
      row.isDeleted = true;
      row.deletedAt = new Date().toISOString();
      if (!row.syncStatus) row.syncStatus = 'local';
      else if (row.syncStatus === 'synced') row.syncStatus = 'modified';
    },
  };
}

function makeFakeConfirm() {
  const c = { _pending: null };
  c.show = (title, msg, cb) => { c._pending = Promise.resolve().then(cb); };
  c.flush = async () => { const p = c._pending; c._pending = null; if (p) await p; };
  return c;
}

function makeFakeElement() {
  return { value: '', textContent: '', dataset: {}, classList: { add() {}, remove() {} } };
}
function makeFakeDocument() {
  const els = {};
  return { getElementById(id) { if (!els[id]) els[id] = makeFakeElement(); return els[id]; }, _els: els };
}

// ── TEST GROUP 1 — captain button visibility (fix #3) ───────────────────────
(function testCaptainButton() {
  const src = extractFunction(html, 'shouldShowCaptainButton');
  const shouldShowCaptainButton = new Function(src + '; return shouldShowCaptainButton;')();

  const cases = [
    // [avail, isCaptain, anyCaptainSet, expected, label]
    [false, false, false, true,  'no captain set, available player -> eligible'],
    [false, false, true,  false, 'captain set elsewhere, not captain -> hidden'],
    [false, true,  true,  true,  'is captain, available -> shown'],
    [true,  false, false, false, 'unavailable, no captain set -> cannot be newly assigned'],
    [true,  false, true,  false, 'unavailable, not captain, captain set -> hidden'],
    [true,  true,  true,  true,  'CAPTAIN BECOMES UNAVAILABLE -> button must stay (the bug fix)'],
  ];
  for (const [avail, isCaptain, anyCaptainSet, expected, label] of cases) {
    const actual = shouldShowCaptainButton(avail, isCaptain, anyCaptainSet);
    check(`captain-button: ${label}`, actual === expected, `avail=${avail} isCaptain=${isCaptain} anyCaptainSet=${anyCaptainSet} -> got ${actual}, want ${expected}`);
  }
})();

// ── TEST GROUP 2 — resetGameGoals + goalEvents cleanup (fix #2) ─────────────
async function testResetGameGoals() {
  const fnsSrc = [
    'clearAllGoalEventsForGame', 'logGoalEventsForDelta', 'resetGameGoals',
    'getOrCreateGP', 'getOrCreateGPForTemp', 'simpleToggleCaptain', 'simpleToggleCaptainTemp',
  ].map(n => extractFunction(html, n)).join('\n\n');

  const factory = new Function(
    'DB', 'I18n', 'Confirm', 'Toast', 'gdDebugLog', 'checkGameEditableOrWarn',
    'refreshGameHeaderScore', 'renderSimpleGoalsTab', 'renderStartingXITab', 'State',
    fnsSrc + `
    return { clearAllGoalEventsForGame, logGoalEventsForDelta, resetGameGoals, getOrCreateGP, getOrCreateGPForTemp, simpleToggleCaptain, simpleToggleCaptainTemp };`
  );

  const DB = makeFakeDB();
  const I18n = { t: (k) => k };
  const Confirm = makeFakeConfirm();
  const Toast = { show() {}, error() {} };
  const State = { currentSeasonId: 1 };
  const fns = factory(DB, I18n, Confirm, Toast, () => {}, () => true, async () => {}, async () => {}, async () => {}, State);

  // Seed: one game, one season player who scored, one guest who scored.
  await DB.put('games', { gameId: 500, opponentScore: 2, ownGoalsForUs: 0, ourScore: null });
  await DB.put('gamePlayers', { gameId: 500, playerId: 10, seasonId: 1, calledUp: true, role: 'Starter', goals: 2, assists: 1 });
  await DB.put('gamePlayers', { gameId: 500, tempPlayerId: 20, seasonId: 1, calledUp: true, role: 'Sub', goals: 1, assists: 0 });
  // Another match's goalEvents — must survive untouched.
  await DB.put('gamePlayers', { gameId: 999, playerId: 10, seasonId: 1, calledUp: true, role: 'Starter', goals: 3, assists: 0 });
  await fns.logGoalEventsForDelta(999, 1, 10, 'player', 0, 3);

  // Build up game 500's goal events the same way simpleSetField would:
  // player 10 went 0 -> 2 goals, guest 20 went 0 -> 1 goal.
  await fns.logGoalEventsForDelta(500, 1, 10, 'player', 0, 2);
  await fns.logGoalEventsForDelta(500, 1, 20, 'temp', 0, 1);

  const activeBefore = (await DB.getAll('goalEvents', 'gameId', 500));
  check('goalEvents: creation logs one row per goal (player)', activeBefore.filter(e => e.scorerType === 'player').length === 2);
  check('goalEvents: creation logs one row per goal (guest)', activeBefore.filter(e => e.scorerType === 'temp').length === 1);

  // Goal correction: player 10 corrected down from 2 to 1 (typo fix).
  await fns.logGoalEventsForDelta(500, 1, 10, 'player', 2, 1);
  const afterCorrection = await DB.getAll('goalEvents', 'gameId', 500);
  check('goalEvents: correction (delta<0) soft-deletes the right count', afterCorrection.filter(e => e.scorerType === 'player').length === 1,
    `expected 1 active player-goal row after correcting 2->1, got ${afterCorrection.filter(e => e.scorerType === 'player').length}`);

  // --- Now the actual fix under test: resetGameGoals must clear everything
  // for game 500 (both scorer types), leave game 999 untouched, and the
  // deletion must be a tombstone (soft), not a hard delete.
  fns.resetGameGoals(500);
  await Confirm.flush();

  const gp500 = await DB.getAll('gamePlayers', 'gameId', 500);
  check('resetGameGoals: zeroes goals/assists for season player', gp500.find(r => r.playerId === 10).goals === 0 && gp500.find(r => r.playerId === 10).assists === 0);
  check('resetGameGoals: zeroes goals/assists for guest', gp500.find(r => r.tempPlayerId === 20).goals === 0 && gp500.find(r => r.tempPlayerId === 20).assists === 0);

  const activeGame500 = await DB.getAll('goalEvents', 'gameId', 500);
  check('resetGameGoals: no active goalEvents left for the reset game', activeGame500.length === 0, `still active: ${activeGame500.length}`);

  const allGame500Raw = DB._stores.goalEvents.filter(e => e.gameId === 500);
  check('resetGameGoals: rows are soft-deleted (tombstoned), not hard-deleted', allGame500Raw.length === 3 && allGame500Raw.every(e => e.isDeleted === true && e.deletedAt),
    `raw rows remaining: ${allGame500Raw.length}, all tombstoned: ${allGame500Raw.every(e => e.isDeleted === true)}`);
  check('resetGameGoals: tombstoned rows get syncStatus so push() can propagate the deletion', allGame500Raw.every(e => e.syncStatus === 'local' || e.syncStatus === 'modified'));

  const activeGame999 = await DB.getAll('goalEvents', 'gameId', 999);
  check('resetGameGoals: another match\'s goalEvents are untouched', activeGame999.length === 3, `expected 3 untouched rows for game 999, got ${activeGame999.length}`);

  // Repeated reset must be a safe no-op — no error, no re-deletion attempt
  // blowing up, no duplicate tombstone fields.
  let threw = false;
  try {
    fns.resetGameGoals(500);
    await Confirm.flush();
  } catch (e) { threw = true; }
  check('resetGameGoals: repeated reset does not throw', !threw);
  const afterSecondReset = DB._stores.goalEvents.filter(e => e.gameId === 500);
  check('resetGameGoals: repeated reset does not create extra rows or duplicate deletions', afterSecondReset.length === 3);

  // --- Captain toggle / one-captain-per-match, untouched by today's fix,
  // exercised here because the ticket explicitly asks for it.
  await DB.put('gamePlayers', { gameId: 500, playerId: 10, seasonId: 1, calledUp: true, role: 'Starter', goals: 0, assists: 0, captain: false });
  await fns.simpleToggleCaptain(500, 10);
  let gp = await DB.getAll('gamePlayers', 'gameId', 500);
  check('captain: assigning sets captain=true on that player', gp.find(r => r.playerId === 10).captain === true);

  await fns.simpleToggleCaptainTemp(500, 20);
  gp = await DB.getAll('gamePlayers', 'gameId', 500);
  check('captain: reassigning to a guest clears the previous captain (exactly one captain)',
    gp.find(r => r.playerId === 10).captain === false && gp.find(r => r.tempPlayerId === 20).captain === true);

  await fns.simpleToggleCaptainTemp(500, 20);
  gp = await DB.getAll('gamePlayers', 'gameId', 500);
  check('captain: tapping the current captain again clears captaincy', gp.find(r => r.tempPlayerId === 20).captain === false);
}

// ── TEST GROUP 3 — kickoff date/timezone (fix #1, PR #4) ────────────────────
// Run via a child process per timezone so Date's local getters really
// resolve in that zone, exercising the real extracted code against the
// actual bug scenario (UTC-date vs local-date mismatch at day boundaries).
async function testKickoffTimezone() {
  const { spawnSync } = require('child_process');
  const fnsSrc = ['dISO', 'openKickoffTimeDialog', 'confirmKickoffTime'].map(n => extractFunction(html, n)).join('\n\n');

  const childScript = `
    const html = require('fs').readFileSync(${JSON.stringify(path)}, 'utf8');
    ${extractFunction.toString()}
    const fnsSrc = ${JSON.stringify(['dISO', 'openKickoffTimeDialog', 'confirmKickoffTime'])}.map(n => extractFunction(html, n)).join('\\n\\n');
    const els = {};
    function makeEl() { return { value: '', textContent: '', dataset: {}, classList: { add(){}, remove(){} } }; }
    const document = { getElementById(id) { if (!els[id]) els[id] = makeEl(); return els[id]; } };
    const I18n = { t: (k) => k };
    const checkGameEditableOrWarn = () => true;
    const DB = { _game: { gameId: 1, actualKickoffAt: null }, async get() { return this._game; }, async put(store, obj) { this._game = obj; } };
    const Toast = { show(){}, error(){} };
    const Render = { gameDetail: async () => {} };
    const factory = new Function('document','I18n','checkGameEditableOrWarn','DB','Toast','Render',
      fnsSrc + '; return { openKickoffTimeDialog, confirmKickoffTime };');
    const fns = factory(document, I18n, checkGameEditableOrWarn, DB, Toast, Render);

    async function run() {
      const scenario = process.env.QA_LABEL;
      const localIso = process.env.QA_LOCAL_ISO; // e.g. "2026-07-15T00:30:00" interpreted as LOCAL time
      const d = new Date(localIso);
      // Simulate "now" being this instant for a fresh tap.
      const RealDate = Date;
      global.Date = class extends RealDate {
        constructor(...args) { if (args.length === 0) { super(d.getTime()); } else { super(...args); } }
        static now() { return d.getTime(); }
      };
      fns.openKickoffTimeDialog(1);
      await fns.confirmKickoffTime();
      const saved = DB._game.actualKickoffAt;
      const savedLocal = new RealDate(saved);
      const expectedY = d.getFullYear(), expectedM = d.getMonth(), expectedDate = d.getDate();
      const ok = savedLocal.getFullYear() === expectedY && savedLocal.getMonth() === expectedM && savedLocal.getDate() === expectedDate
        && savedLocal.getHours() === d.getHours() && savedLocal.getMinutes() === d.getMinutes();
      console.log(JSON.stringify({ scenario, tz: process.env.TZ, localIso, saved, ok }));
      process.exit(ok ? 0 : 1);
    }
    run();
  `;

  const scenarios = [
    { tz: 'Europe/Lisbon', local: '2026-07-15T00:30:00', label: 'Lisbon DST (UTC+1) just after local midnight — UTC date is the previous day' },
    { tz: 'America/Sao_Paulo', local: '2026-07-15T21:45:00', label: 'Sao Paulo (UTC-3) evening kickoff — UTC date is the next day' },
    { tz: 'Europe/Lisbon', local: '2026-03-29T01:30:00', label: 'Lisbon spring-forward DST transition night' },
    { tz: 'Europe/Lisbon', local: '2026-10-25T01:30:00', label: 'Lisbon fall-back DST transition night' },
    { tz: 'America/Sao_Paulo', local: '2026-01-15T12:00:00', label: 'Sao Paulo midday — no boundary crossing, sanity check' },
  ];

  for (const s of scenarios) {
    const r = spawnSync(process.execPath, ['-e', childScript], {
      env: { ...process.env, TZ: s.tz, QA_LABEL: s.label, QA_LOCAL_ISO: s.local },
      encoding: 'utf8',
    });
    let parsed = null;
    try { parsed = JSON.parse((r.stdout || '').trim().split('\n').pop()); } catch (e) {}
    check(`kickoff-tz: ${s.label} [TZ=${s.tz}, local=${s.local}]`, r.status === 0 && parsed && parsed.ok,
      parsed ? JSON.stringify(parsed) : `no parseable output; stderr: ${r.stderr}`);
  }

  // Existing-kickoff-date preservation: reopen the dialog on an already-set
  // kickoff from a DIFFERENT calendar day than "today" and adjust only the
  // time — the saved date must stay the original day, not jump to today.
  const preserveScript = `
    const html = require('fs').readFileSync(${JSON.stringify(path)}, 'utf8');
    ${extractFunction.toString()}
    const fnsSrc = ${JSON.stringify(['dISO', 'openKickoffTimeDialog', 'confirmKickoffTime'])}.map(n => extractFunction(html, n)).join('\\n\\n');
    const els = {};
    function makeEl() { return { value: '', textContent: '', dataset: {}, classList: { add(){}, remove(){} } }; }
    const document = { getElementById(id) { if (!els[id]) els[id] = makeEl(); return els[id]; } };
    const I18n = { t: (k) => k };
    const checkGameEditableOrWarn = () => true;
    const existingIso = '2026-10-10T19:05:00.000Z';
    const DB = { _game: { gameId: 1, actualKickoffAt: existingIso }, async get() { return this._game; }, async put(store, obj) { this._game = obj; } };
    const Toast = { show(){}, error(){} };
    const Render = { gameDetail: async () => {} };
    const factory = new Function('document','I18n','checkGameEditableOrWarn','DB','Toast','Render',
      fnsSrc + '; return { openKickoffTimeDialog, confirmKickoffTime };');
    const fns = factory(document, I18n, checkGameEditableOrWarn, DB, Toast, Render);
    async function run() {
      // Re-opening "today" (a later date than the existing kickoff) to nudge the minute.
      fns.openKickoffTimeDialog(1, DB._game.actualKickoffAt);
      await fns.confirmKickoffTime();
      const saved = DB._game.actualKickoffAt;
      const savedLocalDate = new Date(saved);
      const originalLocalDate = new Date(existingIso);
      const ok = savedLocalDate.getFullYear() === originalLocalDate.getFullYear()
        && savedLocalDate.getMonth() === originalLocalDate.getMonth()
        && savedLocalDate.getDate() === originalLocalDate.getDate();
      console.log(JSON.stringify({ saved, existingIso, ok }));
      process.exit(ok ? 0 : 1);
    }
    run();
  `;
  const r2 = spawnSync(process.execPath, ['-e', preserveScript], { env: { ...process.env, TZ: 'Europe/Lisbon' }, encoding: 'utf8' });
  let parsed2 = null;
  try { parsed2 = JSON.parse((r2.stdout || '').trim().split('\n').pop()); } catch (e) {}
  check('kickoff-tz: adjusting an existing kickoff preserves its original calendar date', r2.status === 0 && parsed2 && parsed2.ok,
    parsed2 ? JSON.stringify(parsed2) : `no parseable output; stderr: ${r2.stderr}`);
}

(async () => {
  await testResetGameGoals();
  await testKickoffTimezone();

  const failed = results.filter(r => !r.pass);
  console.log(JSON.stringify({ ok: failed.length === 0, total: results.length, passed: results.length - failed.length, failed: failed.length, results }, null, 2));
  process.exit(failed.length === 0 ? 0 : 1);
})();
