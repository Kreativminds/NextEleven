'use strict';
// Federation fixture resolver: never guess club/squad identities from names.
// Registrations are scoped to the configured competition and season.
function resolveFixtures(rawFixtures, registrations, competitionKey) {
  if (!competitionKey || !Array.isArray(rawFixtures) || !Array.isArray(registrations)) throw Error('Invalid mapping input');
  const byExternal = new Map();
  for (const reg of registrations) {
    if (reg.competitionKey !== competitionKey) continue;
    if (!reg.externalTeamId || !reg.teamId || !reg.clubId || !reg.squadLabel) throw Error('Incomplete federation registration');
    if (byExternal.has(reg.externalTeamId)) throw Error('Ambiguous external team registration');
    byExternal.set(reg.externalTeamId,reg);
  }
  const resolved=[],unresolved=[];
  for (const fixture of rawFixtures) {
    if (fixture.competitionKey !== competitionKey) {unresolved.push({fixture,reason:'competition-mismatch'});continue;}
    const home=byExternal.get(fixture.homeExternalTeamId);
    const away=byExternal.get(fixture.awayExternalTeamId);
    if (!home || !away) {unresolved.push({fixture,reason:'unmapped-registration'});continue;}
    if (home.teamId===away.teamId) {unresolved.push({fixture,reason:'same-team'});continue;}
    resolved.push({...fixture,homeTeamId:home.teamId,awayTeamId:away.teamId,
      homeName:home.displayName,awayName:away.displayName,
      homeSquadLabel:home.squadLabel,awaySquadLabel:away.squadLabel});
  }
  return {resolved,unresolved};
}
module.exports={resolveFixtures};
if(require.main===module){
  const assert=require('node:assert/strict');
  const key='afl-2026-27-u14-s3';
  const registrations=[
    {competitionKey:key,externalTeamId:'z-olivais-b',teamId:'olivais-b',clubId:'sl-olivais',squadLabel:'B',displayName:'SL Olivais B'},
    {competitionKey:key,externalTeamId:'z-olivais-a',teamId:'olivais-a',clubId:'sl-olivais',squadLabel:'A',displayName:'SL Olivais A'},
    {competitionKey:key,externalTeamId:'z-olivais-sul',teamId:'olivais-sul',clubId:'olivais-sul',squadLabel:'Principal',displayName:'Olivais Sul'},
    {competitionKey:key,externalTeamId:'z-santa-maria-b',teamId:'santa-maria-b',clubId:'santa-maria',squadLabel:'B',displayName:'Santa Maria B'}
  ];
  const match={fixtureId:'f1',competitionKey:key,homeExternalTeamId:'z-olivais-b',awayExternalTeamId:'z-santa-maria-b',status:'final',homeGoals:2,awayGoals:1};
  const out=resolveFixtures([match,{...match,fixtureId:'f2',homeExternalTeamId:'unknown'}],registrations,key);
  assert.equal(out.resolved.length,1);
  assert.equal(out.unresolved.length,1);
  assert.equal(out.resolved[0].homeTeamId,'olivais-b');
  assert.notEqual(registrations[0].teamId,registrations[1].teamId);
  assert.notEqual(registrations[0].clubId,registrations[2].clubId);
  assert.throws(()=>resolveFixtures([match],[...registrations,registrations[0]],key),/Ambiguous/);
  console.log('PASS: explicit federation registration, A/B squads, Olivais Sul, unknown quarantine');
}
