'use strict';
// Pure reconciliation planner. Does not access the database or modify existing match records.
// Fixture IDs must already be verified against the federation competition registration.
function reconcileResults(previous, incoming) {
  if (!Array.isArray(previous) || !Array.isArray(incoming)) throw Error('Result arrays required');
  const byId = new Map();
  for (const old of previous) {
    if (!old.fixtureId || byId.has(old.fixtureId)) throw Error('Invalid stored fixture identities');
    byId.set(old.fixtureId, old);
  }
  const seen = new Set(), changes = [];
  for (const next of incoming) {
    if (!next.fixtureId || seen.has(next.fixtureId)) throw Error('Duplicate incoming fixture');
    seen.add(next.fixtureId);
    if (!next.homeTeamId || !next.awayTeamId || next.homeTeamId === next.awayTeamId) throw Error('Invalid team identities');
    if (!['final','scheduled','postponed'].includes(next.status)) throw Error('Invalid result status');
    if (next.status === 'final' && ![next.homeGoals,next.awayGoals].every(x=>Number.isSafeInteger(x)&&x>=0)) throw Error('Invalid score');
    const old = byId.get(next.fixtureId);
    if (!old) { changes.push({kind:'insert',fixtureId:next.fixtureId,next});continue; }
    if (old.homeTeamId !== next.homeTeamId || old.awayTeamId !== next.awayTeamId) {
      changes.push({kind:'review',reason:'team-identity-conflict',fixtureId:next.fixtureId,previous:old,next});continue;
    }
    if (old.status === 'official' || old.status === 'verified') {
      if (old.homeGoals !== next.homeGoals || old.awayGoals !== next.awayGoals) changes.push({kind:'review',reason:'protected-result-conflict',fixtureId:next.fixtureId,previous:old,next});
      continue;
    }
    if (old.status === 'final' && next.status !== 'final') continue; // Never regress a final result to an empty fixture.
    const scoreChanged = old.homeGoals !== next.homeGoals || old.awayGoals !== next.awayGoals;
    if (old.status !== next.status || scoreChanged) changes.push({kind:'update',fixtureId:next.fixtureId,previous:old,next,reason:scoreChanged?'score-correction':'status-change'});
  }
  return changes;
}
module.exports={reconcileResults};
if(require.main===module){
  const assert=require('node:assert/strict');
  const a={fixtureId:'f1',homeTeamId:'sl-olivais-b',awayTeamId:'santa-maria-b',status:'final',homeGoals:2,awayGoals:1};
  const updated={...a,homeGoals:3};
  assert.deepEqual(reconcileResults([a],[a]),[]);
  assert.equal(reconcileResults([a],[updated])[0].kind,'update');
  assert.equal(reconcileResults([{...a,status:'official'}],[updated])[0].kind,'review');
  assert.equal(reconcileResults([a],[{...a,status:'scheduled',homeGoals:null,awayGoals:null}]).length,0);
  assert.equal(reconcileResults([],[a])[0].kind,'insert');
  assert.equal(reconcileResults([a],[{...a,awayTeamId:'other'}])[0].kind,'review');
  assert.throws(()=>reconcileResults([],[a,a]),/Duplicate/);
  console.log('PASS: insert, no-op, correction, protected results, no regression, identity conflicts');
}
