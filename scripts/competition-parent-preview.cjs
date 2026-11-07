'use strict';
// Read-only orchestration from permitted source adapter to parent display model.
// No production database access, scheduling, browser scraping or parent submissions.
const {planCompetitionRefresh}=require('./competition-refresh.cjs');
const {buildCompetitionView}=require('./competition-view.cjs');
async function previewParentCompetition({source,round,fetchPage,parsePage,existingResults=[],approvedTeamIds,now}) {
  const preview=await planCompetitionRefresh({source,round,fetchPage,parsePage,existingResults,approvedTeamIds,now});
  const byId=new Map(existingResults.map(f=>[f.fixtureId,f]));
  for(const change of preview.changes) byId.set(change.fixtureId,change.next);
  // Only show approved teams, including preexisting results; conflicts remain untouched.
  const approved=[...byId.values()].filter(f=>approvedTeamIds.has(f.homeTeamId)&&approvedTeamIds.has(f.awayTeamId));
  const roundFixtures=approved.filter(f=>f.round===round);
  const view=buildCompetitionView({round,sourceUrl:preview.sourceUrl,retrievedAt:preview.retrievedAt,
    fixtures:roundFixtures,standings:preview.standings,unresolved:preview.unresolved});
  return {...view,pendingReviewCount:preview.reviews.length,changesPlanned:preview.changes.length,previewOnly:true};
}
module.exports={previewParentCompetition};
if(require.main===module){
  const assert=require('node:assert/strict');
  const {DEFAULT_SOURCE}=require('./competition-source-config.cjs');
  const fixture={fixtureId:'f6',round:6,homeTeamId:'sl-olivais-b',homeName:'SL Olivais B',
    awayTeamId:'santa-maria-b',awayName:'Santa Maria B',status:'final',homeGoals:2,awayGoals:1};
  const args={source:DEFAULT_SOURCE,round:6,fetchPage:async()=>({ok:true,body:'mock'}),
    parsePage:async()=>({round:6,fixtures:[fixture]}),
    approvedTeamIds:new Set(['sl-olivais-b','santa-maria-b']),
    now:()=>new Date('2026-11-07T19:00:00Z')};
  (async()=>{
    const v=await previewParentCompetition(args);
    assert.equal(v.matches[0].score,'2–1');
    assert.equal(v.standings[0].points,3);
    assert.equal(v.changesPlanned,1);
    assert.equal(v.readOnly,true);
    const repeated=await previewParentCompetition({...args,existingResults:[fixture]});
    assert.equal(repeated.changesPlanned,0);
    console.log('PASS: source to parent preview, standings, idempotent repeat');
  })().catch(e=>{console.error(e);process.exitCode=1});
}
