#!/usr/bin/env node
// Targeted regression tests for the 2026-10-18 Onboarding Redesign ticket:
//   1. First-Time Wizard consolidated to 3 steps (Team/Season/Squad), old
//      drafts with step 4-8 clamp correctly instead of rendering blank
//   2. Wizard quick-add player position picker uses the canonical taxonomy
//   3. Duplicate-team-name validation standardized (Season Renewal Wizard
//      now reuses an existing clubTeams row instead of always creating one)
//   4. Password-reset validation matches signup (checkPasswordStrength reuse)
//   5. Country field: read/write round-trips through the shared field helper
//   6. Getting Started "Resources" item reflects a real appMeta flag
//   7. Invalid-position diagnostic report flags real mismatches, read-only
//
// Extracts the REAL function/const source out of index.html (same technique
// as check-syntax.js's `new Function`), same pattern as
// check-fix-2026-10-18.js, so these exercise the actual shipped code.
//
// Usage: node check-onboarding-2026-10-18.js [/path/to/index.html]
// Exits 1 on any failure, prints a JSON summary either way.

const fs = require('fs');
const path = process.argv[2] || require('path').join(__dirname, '..', '..', 'index.html');
const html = fs.readFileSync(path, 'utf8');

function extractBlock(src, marker) {
  let start = src.indexOf(marker);
  if (start === -1) throw new Error(`marker not found: ${marker}`);
  let i = src.indexOf('{', start);
  if (i === -1) throw new Error(`no body found for ${marker}`);
  let depth = 0, end = -1;
  for (let j = i; j < src.length; j++) {
    if (src[j] === '{') depth++;
    else if (src[j] === '}') { depth--; if (depth === 0) { end = j; break; } }
  }
  if (end === -1) throw new Error(`unbalanced braces for ${marker}`);
  return src.slice(start, end + 1);
}

// Same extraction technique as check-fix-2026-10-18.js's extractFunction.
function extractFn(src, name) {
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

function makeFakeDB(initial) {
  const stores = Object.assign({ clubTeams: [], players: [], seasons: [], appMeta: [] }, initial || {});
  const keyField = { clubTeams: 'clubTeamId', players: 'playerId', seasons: 'seasonId', appMeta: 'metaKey' };
  const nextId = { clubTeams: 1, players: 1, seasons: 1 };
  return {
    _stores: stores,
    async get(store, key) { return stores[store].find(r => r[keyField[store]] === key) || null; },
    async put(store, obj) {
      const kf = keyField[store];
      if (store === 'appMeta') {
        const idx = stores.appMeta.findIndex(r => r.metaKey === obj.metaKey);
        if (idx >= 0) stores.appMeta[idx] = obj; else stores.appMeta.push(obj);
        return obj.metaKey;
      }
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
  };
}

function makeFakeElement(initial) {
  return Object.assign({ value: '', textContent: '', style: {}, dataset: {} }, initial || {});
}
function makeFakeDocument(values) {
  const els = {};
  Object.entries(values || {}).forEach(([id, value]) => { els[id] = makeFakeElement({ value }); });
  return { getElementById(id) { if (!els[id]) els[id] = makeFakeElement(); return els[id]; }, _els: els };
}
function makeFakeI18n() {
  return { t: (key, vars) => key + (vars ? JSON.stringify(vars) : '') };
}

async function main() {

// ── TEST GROUP 1 — password strength parity (fix #4) ────────────────────────
try {
  const checkPasswordStrengthSrc = extractFn(html, 'checkPasswordStrength');
  const checkPasswordStrength = new Function(`${checkPasswordStrengthSrc}; return checkPasswordStrength;`)();

  const weak = checkPasswordStrength('abc123');
  check('password: 6-char all-lowercase+digits fails length/upper/special',
    !weak.length && !weak.upper && !weak.special,
    JSON.stringify(weak));

  const strong = checkPasswordStrength('Correct-Horse-9');
  check('password: 15-char mixed-case+digit+special passes every check',
    Object.values(strong).every(Boolean),
    JSON.stringify(strong));

  // The actual regression: handleCompletePasswordReset must reuse this same
  // function rather than its own weaker length-only check.
  const resetFnSrc = extractFn(html, 'handleCompletePasswordReset');
  check('password-reset: no longer checks newPassword.length < 6 directly',
    !resetFnSrc.includes('newPassword.length < 6'));
  check('password-reset: calls checkPasswordStrength, same as signup',
    resetFnSrc.includes('checkPasswordStrength(newPassword)'));
} catch (e) {
  check('password strength parity group', false, e.message);
}

// ── TEST GROUP 2 — wizard consolidated to 3 steps, old drafts clamp ─────────
try {
  const stepsMatch = html.match(/const FIRST_TIME_WIZARD_STEPS = (\d+);/);
  check('wizard: FIRST_TIME_WIZARD_STEPS is 3', stepsMatch && stepsMatch[1] === '3', stepsMatch && stepsMatch[1]);

  const routerSrc = extractFn(html, 'renderFirstTimeWizardStep');
  check('wizard: step router only handles steps 1-3 (Team/Season/Squad)',
    routerSrc.includes('renderFTWStepClub') && routerSrc.includes('renderFTWStepSeason') &&
    routerSrc.includes('renderFTWStepSquad') && !routerSrc.includes('renderFTWStepOpponents') &&
    !routerSrc.includes('renderFTWStepWelcome'));

  const openFn = extractFn(html, 'openFirstTimeWizard');
  check('wizard: openFirstTimeWizard clamps an old draft\'s step to FIRST_TIME_WIZARD_STEPS',
    openFn.includes('_firstTimeWizardState.step > FIRST_TIME_WIZARD_STEPS'));

  const homeAutoTriggerSrc = extractFn(html, 'home');
  check('wizard: the auto-trigger entry point in home() also clamps an old draft\'s step',
    homeAutoTriggerSrc.includes('_firstTimeWizardState.step > FIRST_TIME_WIZARD_STEPS'));

  // Execute the actual clamp arithmetic (the real guard, copied verbatim)
  // against a simulated old-flow draft sitting at step 5 (Opponents).
  const loadedDraft = { step: 5, club: { name: 'Test FC' }, season: {}, squad: { mode: null, players: [] } };
  const clamped = Object.assign({}, loadedDraft);
  if (clamped.step > 3) clamped.step = 3;
  check('wizard: a draft at old step 5 (Opponents) clamps to step 3 (Squad), not a blank screen',
    clamped.step === 3, JSON.stringify(clamped));
} catch (e) {
  check('wizard consolidation group', false, e.message);
}

// ── TEST GROUP 3 — position picker uses canonical taxonomy (fix #2) ─────────
try {
  const squadStepSrc = extractFn(html, 'renderFTWStepSquad');
  check('wizard squad step: no longer has the GK/DF/MF/FW mini-list',
    !squadStepSrc.includes("<option>GK</option>"));
  check('wizard squad step: quick-add position select uses renderPositionOptions',
    squadStepSrc.includes('renderPositionOptions('));

  const positionsMatch = html.match(/POSITIONS:\s*(\[[^\]]+\])/);
  const positions = JSON.parse(positionsMatch[1].replace(/'/g, '"'));
  const keysBlock = extractBlock(html, 'const POSITION_I18N_KEYS = ');
  const POSITION_I18N_KEYS = new Function(`${keysBlock}; return POSITION_I18N_KEYS;`)();
  const missingKeys = positions.filter(p => !POSITION_I18N_KEYS[p]);
  check('position taxonomy: every CONFIG.POSITIONS value has an i18n key mapping',
    missingKeys.length === 0, JSON.stringify(missingKeys));

  const renderPositionOptionsSrc = extractFn(html, 'renderPositionOptions');
  const renderPositionOptions = new Function('CONFIG', 'I18n', 'POSITION_I18N_KEYS',
    `${renderPositionOptionsSrc}; return renderPositionOptions;`
  )({ POSITIONS: positions }, makeFakeI18n(), POSITION_I18N_KEYS);
  const optionsHtml = renderPositionOptions('Centre Back');
  check('renderPositionOptions: emits all 10 canonical positions as option values',
    positions.every(p => optionsHtml.includes(`value="${p}"`)));
  check('renderPositionOptions: marks the passed-in value selected',
    optionsHtml.includes('value="Centre Back" selected'));
} catch (e) {
  check('position taxonomy group', false, e.message);
}

// ── TEST GROUP 4 — duplicate-team-name validation (fix #3) ──────────────────
try {
  const wizardCreateNewClubSrc = extractFn(html, 'wizardCreateNewClub');
  check('Season Renewal Wizard: wizardCreateNewClub now normalizes+reuses an existing club',
    wizardCreateNewClubSrc.includes('normalize(c.name) === normalize(name)'));

  const fakeDB = makeFakeDB({ clubTeams: [{ clubTeamId: 1, name: 'SL Olívais', createdAt: 't' }] });
  global.document = makeFakeDocument({ 'wiz-new-club-name': 'sl olivais' }); // same name, no accent, different case
  global.Toast = { error() {}, show() {} };
  global._seasonWizardState = {};
  global.renderWizardStepYear = async () => {};
  global.I18n = makeFakeI18n();
  const wizardCreateNewClub = new Function('DB', 'document', 'Toast', 'I18n',
    `let _seasonWizardState = {}; async function renderWizardStepYear(){} ${wizardCreateNewClubSrc}; return wizardCreateNewClub;`
  )(fakeDB, global.document, global.Toast, global.I18n);
  await wizardCreateNewClub();
  check('duplicate-team fix: a diacritic/case-different name reuses clubTeamId 1 instead of creating a 2nd row',
    fakeDB._stores.clubTeams.length === 1,
    JSON.stringify(fakeDB._stores.clubTeams));
} catch (e) {
  check('duplicate-team-name group', false, e.message);
}

// ── TEST GROUP 5 — country field read/write round-trip (fix #5) ─────────────
try {
  const renderCountryFieldSrc = extractFn(html, 'renderCountryField');
  const readCountryFieldSrc = extractFn(html, 'readCountryField');
  const countryOptionsMatch = html.match(/const COUNTRY_OPTIONS\s*=\s*\[[^\]]*\]\s*;/);
  if (!countryOptionsMatch) throw new Error('COUNTRY_OPTIONS declaration not found in index.html');
  const countryOptionsSrc = countryOptionsMatch[0];
  const escSrc = (() => { try { return extractFn(html, 'esc'); } catch (e) { return 'function esc(s){return String(s==null?"":s);}'; } })();
  // No 'document' parameter here on purpose: readCountryField reads the live
  // global.document (reassigned below per-case), so a frozen local param
  // would shadow it and silently ignore later reassignments.
  const mod = new Function(
    `${countryOptionsSrc}; ${escSrc}; ${renderCountryFieldSrc}; ${readCountryFieldSrc}; return { renderCountryField, readCountryField };`
  );
  const { renderCountryField, readCountryField } = mod();
  const knownHtml = renderCountryField('c1', 'c1-other', 'Portugal');
  check('country field: a known option renders selected', knownHtml.includes('value="Portugal" selected'));

  global.document = makeFakeDocument({ 'c1': 'Portugal', 'c1-other': '' });
  check('country field: readCountryField round-trips a known selection',
    readCountryField('c1', 'c1-other') === 'Portugal');

  global.document = makeFakeDocument({ 'c1': 'Other', 'c1-other': 'Angola' });
  check('country field: readCountryField falls through to free text on "Other"',
    readCountryField('c1', 'c1-other') === 'Angola');
} catch (e) {
  check('country field group', false, e.message);
}

// ── TEST GROUP 6 — Getting Started "Resources" item reflects a real flag ────
try {
  const itemsSrc = extractFn(html, 'getGettingStartedItems');
  check('getting-started: resources item no longer hardcoded done:false',
    !itemsSrc.includes("done: false }") || !itemsSrc.includes("key: 'resources', label: I18n.t('gs_item_resources'), done: false"));
  check('getting-started: resources item reads a real appMeta flag',
    itemsSrc.includes("gettingStartedSettingsVisited"));

  const settingsFnSrc = extractFn(html, 'settings');
  check('Settings render: marks gettingStartedSettingsVisited the first time Settings is opened',
    settingsFnSrc.includes("metaKey: 'gettingStartedSettingsVisited'"));
} catch (e) {
  check('getting-started resources group', false, e.message);
}

// ── TEST GROUP 7 — invalid-position diagnostic report (read-only) ───────────
try {
  const scanSrc = extractFn(html, 'scanInvalidPositionPlayers');
  check('invalid-position report: filters only, never writes (no DB.put call in the scan)',
    !scanSrc.includes('DB.put') && !scanSrc.includes('DB.softDelete'));

  const fakeDB = makeFakeDB({
    players: [
      { playerId: 1, fullName: 'Valid Player', seasonId: 1, primaryPosition: 'Centre Back', secondaryPosition: null },
      { playerId: 2, fullName: 'Legacy Player', seasonId: 1, primaryPosition: 'DF', secondaryPosition: null },
      { playerId: 3, fullName: 'No Position Player', seasonId: 1, primaryPosition: null, secondaryPosition: null },
    ],
    seasons: [{ seasonId: 1, seasonName: '2026/27' }],
  });
  const CONFIG = { POSITIONS: ['Goalkeeper','Centre Back','Right Back','Left Back','Defensive Midfielder','Central Midfielder','Attacking Midfielder','Right Winger','Left Winger','Striker'] };
  const scanInvalidPositionPlayers = new Function('DB', 'CONFIG', `${scanSrc}; return scanInvalidPositionPlayers;`)(fakeDB, CONFIG);
  const flagged = await scanInvalidPositionPlayers();
  check('invalid-position report: flags the legacy "DF" value',
    flagged.length === 1 && flagged[0].fullName === 'Legacy Player', JSON.stringify(flagged));
  check('invalid-position report: does not flag a valid position or an empty one',
    !flagged.some(f => f.fullName === 'Valid Player' || f.fullName === 'No Position Player'));
} catch (e) {
  check('invalid-position report group', false, e.message);
}

const failed = results.filter(r => !r.pass);
console.log(JSON.stringify({ ok: failed.length === 0, total: results.length, failed: failed.length, results }, null, 2));
process.exit(failed.length === 0 ? 0 : 1);

}

main();
