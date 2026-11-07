'use strict';
// Read-only orchestration. Source adapter is injected; no live network calls or database writes.
// Only approved federation mappings are allowed into the provisional standings.
const {acquireRound}=require('./competition-acquisition.cjs');
const {reconcileResults}=require('./competition-reconcile.cjs');
const {standings}=require('./competition-standings.cjs');
async function planCompetitionRefresh({source,round,fetchPage,parsePage,existingResults=[],approvedTeamIds,now}) {
  if (!(approvedTeamIds instanceof Set)) throw Error('Approved federation team ID set required');
  const acquired=await acquireRound({source,round,fetchPage,parsePage,now});
  const unresolved=acquired.fixtures.filter(f=>!approvedTeamIds.has(f.homeTeamId)||!approvedTeamIds.has(f.awayTeamId));
  const valid=acquired.fixtures.filter(f=>approvedTeamIds.has(f.homeTeamId)&&approvedTeamIds.has(f.awayTeamId));
  const changes=reconcileResults(existingResults,valid);
  const reviews=changes.filter(c=>c.kind==='review');
  const applied=changes.filter(c=>c.kind==='insert'||c.kind==='update');
  const combined=new Map(existingResults.map(f=>[f.fixtureId,f]));
  for(const c of applied) combined.set(c.fixtureId,c.next);
  // This is a preview only, not a database write. Approved, final fixtures only.
  const table=standings([...combined.values()].filter(f=>f.status==='final'));
  return {round,sourceUrl:acquired.sourceUrl,retrievedAt:acquired.retrievedAt,
    changes:applied,reviews,unresolved,standings:table,previewOnly:true};
}
module.exports={planCompetitionRefresh};
if(require.main===module){
  const assert=require('node:assert/strict');
  const {DEFAULT_SOURCE}=require('./competition-source-config.cjs');
  const match=(fixtureId,homeTeamId,homeName,awayTeamId,awayName,homeGoals,awayGoals)=>({fixtureId,homeTeamId,homeName,awayTeamId,awayName,homeGoals,awayGoals,status:'final'});
  const fixture=match('m1','sl-olivais-b','SL Olivais B','santa-maria-b','Santa Maria B',2,1);
  const unknown=match('m2','unknown','Unknown','sl-olivais-b','SL Olivais B',3,0);
  const args={source:DEFAULT_SOURCE,round:6,fetchPage:async()=>({ok:true,body:'fixture'}),parsePage:async()=>({round:6,fixtures:[fixture,unknown]}),approvedTeamIds:new Set(['sl-olivais-b','santa-maria-b']),now:()=>new Date('2026-11-07T19:00:00Z')};
  (async()=>{
    const first=await planCompetitionRefresh(args);
    assert.equal(first.changes.length,1);
    assert.equal(first.unresolved.length,1);
    assert.equal(first.standings[0].name,'SL Olivais B');
    assert.equal(first.previewOnly,true);
    const repeat=await planCompetitionRefresh({...args,existingResults:[fixture]});
    assert.equal(repeat.changes.length,0);
    const corrected=await planCompetitionRefresh({...args,existingResults:[{...fixture,homeGoals:1}]});
    assert.equal(corrected.changes[0].reason,'score-correction');
    console.log('PASS: pipeline preview, unresolved team quarantine, idempotency, score correction');
  })().catch(e=>{console.error(e);process.exitCode=1});
}
