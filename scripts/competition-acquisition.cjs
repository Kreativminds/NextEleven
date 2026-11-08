'use strict';
// Read-only, dependency-injected acquisition adapter. It never scrapes, schedules or writes.
// The caller must supply a permitted fetch implementation and a parser for the source format.
const { buildRoundUrl } = require('./competition-source-config.cjs');
function isValidScore(score) {
  return Number.isSafeInteger(score) && score >= 0;
}
async function acquireRound({ source, round, fetchPage, parsePage, now = () => new Date() }) {
  if (typeof fetchPage !== 'function' || typeof parsePage !== 'function') throw Error('Fetch and parser adapters required');
  const url = buildRoundUrl(source, round);
  const response = await fetchPage(url);
  if (!response || response.ok !== true || typeof response.body !== 'string') throw Error('Source unavailable');
  const parsed = await parsePage(response.body, {round,url});
  if (!parsed || parsed.round !== round || !Array.isArray(parsed.fixtures)) throw Error('Source round mismatch');
  const ids = new Set();
  const fixtures = parsed.fixtures.map(f => {
    if (typeof f.fixtureId !== 'string' || !f.fixtureId || ids.has(f.fixtureId)) throw Error('Duplicate or missing fixture identity');
    ids.add(f.fixtureId);
    if (!f.homeTeamId || !f.awayTeamId || f.homeTeamId === f.awayTeamId) throw Error('Unresolved fixture teams');
    if (f.status === 'final' && (!isValidScore(f.homeGoals) || !isValidScore(f.awayGoals))) throw Error('Final result missing valid scores');
    if (!['final','scheduled','postponed'].includes(f.status)) throw Error('Unknown fixture status');
    return Object.freeze({...f,sourceUrl:url,round});
  });
  return Object.freeze({round,sourceUrl:url,retrievedAt:now().toISOString(),fixtures});
}
module.exports={acquireRound};
if(require.main===module){
  const assert=require('node:assert/strict');
  const {DEFAULT_SOURCE}=require('./competition-source-config.cjs');
  const fixture={fixtureId:'f1',homeTeamId:'sl-olivais-b',awayTeamId:'santa-maria-b',homeGoals:2,awayGoals:1,status:'final'};
  const fetchPage=async url=>({ok:true,body:'fixture sample'});
  const parsePage=async (_body,{round})=>({round,fixtures:[fixture]});
  (async()=>{
    const r=await acquireRound({source:DEFAULT_SOURCE,round:6,fetchPage,parsePage,now:()=>new Date('2026-11-07T19:00:00Z')});
    assert.equal(r.fixtures[0].awayTeamId,'santa-maria-b');
    assert.match(r.sourceUrl,/jornada_in=6/);
    assert.equal(r.retrievedAt,'2026-11-07T19:00:00.000Z');
    await assert.rejects(acquireRound({source:DEFAULT_SOURCE,round:6,fetchPage,parsePage:async()=>({round:5,fixtures:[]})}),/round mismatch/);
    await assert.rejects(acquireRound({source:DEFAULT_SOURCE,round:6,fetchPage,parsePage:async()=>({round:6,fixtures:[fixture,fixture]})}),/Duplicate/);
    await assert.rejects(acquireRound({source:DEFAULT_SOURCE,round:6,fetchPage:async()=>({ok:false}),parsePage}),/unavailable/);
    console.log('PASS: injected acquisition, provenance, mismatched rounds, duplicates, unavailable source');
  })().catch(e=>{console.error(e);process.exitCode=1;});
}
