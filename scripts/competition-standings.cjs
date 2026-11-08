'use strict';
// Provisional standings engine. Only accepts validated, completed results.
// Ranking rules are supplied by competition configuration; no guessed federation rules.
function standings(results, options = {}) {
  const points = options.points || {win:3,draw:1,loss:0};
  const ranking = options.ranking || ['points','goalDifference','goalsFor'];
  const allowed = new Set(['points','goalDifference','goalsFor','wins']);
  if (!ranking.length || ranking.some(k=>!allowed.has(k))) throw Error('Unsupported ranking criteria');
  const teams = new Map();
  function team(id, name) {
    if (!id || !name) throw Error('Verified team ID and name required');
    if (!teams.has(id)) teams.set(id,{teamId:id,name,played:0,wins:0,draws:0,losses:0,goalsFor:0,goalsAgainst:0,goalDifference:0,points:0});
    return teams.get(id);
  }
  const seen = new Set();
  for (const game of results) {
    if (game.status !== 'final') continue;
    if (!game.fixtureId || seen.has(game.fixtureId)) throw Error('Duplicate or missing fixture ID');
    seen.add(game.fixtureId);
    if (game.homeTeamId === game.awayTeamId) throw Error('Same team on both sides');
    const h=game.homeGoals,a=game.awayGoals;
    if (![h,a].every(v=>Number.isSafeInteger(v)&&v>=0)) throw Error('Invalid final score');
    const home=team(game.homeTeamId,game.homeName), away=team(game.awayTeamId,game.awayName);
    home.played++;away.played++;
    home.goalsFor+=h;home.goalsAgainst+=a;away.goalsFor+=a;away.goalsAgainst+=h;
    if(h>a){home.wins++;away.losses++;home.points+=points.win;away.points+=points.loss;}
    else if(h<a){away.wins++;home.losses++;away.points+=points.win;home.points+=points.loss;}
    else {home.draws++;away.draws++;home.points+=points.draw;away.points+=points.draw;}
  }
  const rows=[...teams.values()];
  for(const t of rows)t.goalDifference=t.goalsFor-t.goalsAgainst;
  rows.sort((a,b)=>{
    for(const key of ranking)if(a[key]!==b[key])return b[key]-a[key];
    return a.name.localeCompare(b.name,'pt');
  });
  return rows.map((t,i)=>({...t,position:i+1,provisional:true}));
}
module.exports={standings};
if(require.main===module){
  const assert=require('node:assert/strict');
  const match=(fixtureId,homeTeamId,homeName,awayTeamId,awayName,homeGoals,awayGoals,status='final')=>({fixtureId,homeTeamId,homeName,awayTeamId,awayName,homeGoals,awayGoals,status});
  const rows=standings([
    match('m1','sl-olivais-b','SL Olivais B','santa-maria-b','Santa Maria B',2,1),
    match('m2','sacavenense-b','Sacavenense B','moscavide','Moscavide',10,1),
    match('m3','sl-olivais-b','SL Olivais B','sacavenense-b','Sacavenense B',0,0),
    match('m4','other','Other','moscavide','Moscavide',null,null,'scheduled')
  ]);
  assert.equal(rows.length,4);
  assert.equal(rows.find(t=>t.teamId==='sl-olivais-b').points,4);
  assert.equal(rows.find(t=>t.teamId==='sacavenense-b').goalDifference,9);
  assert.equal(rows.find(t=>t.teamId==='moscavide').played,1);
  assert.throws(()=>standings([match('x','a','A','b','B',2,-1)]),/Invalid final score/);
  assert.throws(()=>standings([match('x','a','A','b','B',1,0),match('x','a','A','b','B',1,0)]),/Duplicate/);
  console.log('PASS: standings, scheduled exclusion, squad IDs, invalid scores, duplicate fixture');
}
