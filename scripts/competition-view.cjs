'use strict';
// Produces safe, read-only presentation data. Does not fetch, persist or alter team games.
function buildCompetitionView({round,sourceUrl,retrievedAt,fixtures,standings,unresolved=[]}) {
  if (!Number.isSafeInteger(round)||round<1) throw Error('Invalid round');
  if (!Array.isArray(fixtures)||!Array.isArray(standings)) throw Error('Missing fixtures or standings');
  const url=new URL(sourceUrl);
  if(url.protocol!=='https:'||url.hostname!=='www.zerozero.pt') throw Error('Unapproved source URL');
  const matches=fixtures.map(f=>{
    if(!f.fixtureId||!f.homeName||!f.awayName)throw Error('Invalid fixture');
    const finished=f.status==='final';
    if(finished && ![f.homeGoals,f.awayGoals].every(n=>Number.isSafeInteger(n)&&n>=0))throw Error('Invalid score');
    return {fixtureId:f.fixtureId,home:f.homeName,away:f.awayName,
      score:finished?String(f.homeGoals)+'–'+String(f.awayGoals):null,
      status:f.status,provisional:finished};
  });
  return {round,sourceUrl,retrievedAt,matches,
    standings:standings.map(t=>({position:t.position,teamId:t.teamId,name:t.name,
      played:t.played,wins:t.wins,draws:t.draws,losses:t.losses,
      goalsFor:t.goalsFor,goalsAgainst:t.goalsAgainst,goalDifference:t.goalDifference,points:t.points,
      provisional:true})),
    unresolvedCount:unresolved.length,readOnly:true};
}
module.exports={buildCompetitionView};
if(require.main===module){
  const assert=require('node:assert/strict');
  const view=buildCompetitionView({round:6,sourceUrl:'https://www.zerozero.pt/edicao/test/225119?jornada_in=6&fase=249719',
    retrievedAt:'2026-11-07T19:00:00Z',fixtures:[
      {fixtureId:'m1',homeName:'SL Olivais B',awayName:'Santa Maria B',status:'final',homeGoals:2,awayGoals:1},
      {fixtureId:'m2',homeName:'Oriental',awayName:'Estrela Amadora B',status:'scheduled'}],
    standings:[{position:1,teamId:'sl-olivais-b',name:'SL Olivais B',played:1,wins:1,draws:0,losses:0,goalsFor:2,goalsAgainst:1,goalDifference:1,points:3}]});
  assert.equal(view.matches[0].score,'2–1');
  assert.equal(view.matches[1].score,null);
  assert.equal(view.standings[0].points,3);
  assert.equal(view.readOnly,true);
  assert.throws(()=>buildCompetitionView({round:6,sourceUrl:'https://evil.example/',fixtures:[],standings:[]}),/Unapproved/);
  console.log('PASS: read-only parent data, scheduled match, standings, source validation');
}
