'use strict';
// Pure configuration/URL builder. Network access and writes intentionally excluded.
const DEFAULT_SOURCE = Object.freeze({
  provider: 'zerozero',
  editionId: 225119,
  phaseId: 249719,
  slug: 'af-lisboa-juniores-c1-3-divisao-sub-14-1-fase-serie-3-2026-2027',
  baseUrl: 'https://www.zerozero.pt'
});
function positiveInt(value, label) {
  if (!Number.isSafeInteger(value) || value < 1) throw new RangeError(label + ' must be a positive integer');
  return value;
}
function buildRoundUrl(source, round) {
  positiveInt(round, 'round');
  positiveInt(source.editionId, 'editionId');
  positiveInt(source.phaseId, 'phaseId');
  if (!/^[a-z0-9-]+$/.test(source.slug)) throw new Error('Invalid competition slug');
  const base = new URL(source.baseUrl);
  if (base.protocol !== 'https:' || base.hostname !== 'www.zerozero.pt' || base.username || base.password || base.search || base.hash || base.pathname !== '/') {
    throw new Error('Source host is not approved');
  }
  const url = new URL('/edicao/' + source.slug + '/' + source.editionId, base);
  url.searchParams.set('jornada_in', String(round));
  url.searchParams.set('fase', String(source.phaseId));
  return url.toString();
}
function buildRoundUrls(source, rounds) {
  positiveInt(rounds, 'rounds');
  if (rounds > 100) throw new RangeError('Round limit exceeded');
  return Array.from({length:rounds}, (_,i)=>buildRoundUrl(source,i+1));
}
module.exports = {DEFAULT_SOURCE,buildRoundUrl,buildRoundUrls};
if (require.main === module) {
  const assert = require('node:assert/strict');
  const one = buildRoundUrl(DEFAULT_SOURCE,1);
  assert.match(one,/jornada_in=1/);
  assert.match(one,/fase=249719/);
  assert.equal(buildRoundUrls(DEFAULT_SOURCE,7).length,7);
  assert.match(buildRoundUrl(DEFAULT_SOURCE,6),/jornada_in=6/);
  assert.throws(()=>buildRoundUrl(DEFAULT_SOURCE,0),/positive integer/);
  assert.throws(()=>buildRoundUrl({...DEFAULT_SOURCE,baseUrl:'https://evil.example/'},1),/not approved/);
  console.log('PASS: URLs for 1..7, phase retained, round validation, host guard');
}
