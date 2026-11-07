// Run: node tests/regression_federation_match_save_contract.js
// Read-only source contract checks for the real match create/edit path.
// This is not a substitute for a browser end-to-end test.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const html=fs.readFileSync(path.join(__dirname,'..','index.html'),'utf8');
const start=html.indexOf('async function saveGame() {');
const end=html.indexOf('\nasync function ',start+1);
assert(start>=0,'saveGame must exist');
const body=html.slice(start,end<0?start+9000:end);
const checks=[
  ['opponent taken from the existing free-text form', /const opp = document\.getElementById\('gf-opp'\)\.value\.trim\(\)/],
  ['opponent stored as a string', /opponent: opp/],
  ['edit preserves the existing game id', /game\.gameId = parseInt\(existingId\)/],
  ['edit preserves the opponent score', /game\.opponentScore = existingGame/],
  ['edit preserves creation timestamp', /game\.createdAt = \(existingGame/],
  ['edit preserves game UUID', /game\.gameUuid = \(existingGame/],
  ['edit preserves actual kickoff timestamp', /game\.actualKickoffAt = \(existingGame/],
  ['save creates a local backup first', /await Backup\.create\('before-save'\)/],
  ['save writes the games store', /await DB\.put\('games', game\)/],
  ['save schedules cloud sync', /Sync\.scheduleAutoSync\(\)/],
];
for(const [description,regex] of checks) assert(regex.test(body),description);
assert(/<input id="gf-opp"[^>]*list="gf-opp-list"/.test(html),'picker must remain an editable text field');
assert(/const FEDERATION_CATALOGUE_PICKER_ENABLED = false;/.test(html),'federation picker must remain disabled');
console.log('PASS: '+checks.length+' create/edit invariants plus editable opponent and disabled flag');
