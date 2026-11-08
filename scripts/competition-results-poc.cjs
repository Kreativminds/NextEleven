// Zerozero result text proof-of-concept parser. No network calls, no production writes.
// Inputs must be retrieved from a permitted source and manually/automatically verified.
'use strict';
function parseRound(text, expectedRound) {
  const header = text.match(/(?:###\s*)?JORNADA\s+(\d+)/i);
  if (!header || Number(header[1]) !== expectedRound) throw Error('Round mismatch');
  const section = text.split(/##\s*Classifica[cç][aã]o/i)[0];
  const matches = [];
  for (const line of section.split(/\r?\n/)) {
    // Normalized plain-text fixture format: 03/10 | Home | 0-6 | Away
    const parts = line.split('|').map(s => s.trim());
    if (parts.length < 4) continue;
    const score = parts[2].match(/^(\d{1,2})\s*[-–]\s*(\d{1,2})$/);
    if (!score) continue; // Scheduled fixtures are not results.
    const [home, away] = [parts[1],parts[3]];
    if (!home || !away || home === away) throw Error('Invalid teams');
    matches.push({ round: expectedRound, date: parts[0], home, away,
      homeGoals:Number(score[1]), awayGoals:Number(score[2]) });
  }
  return matches;
}
module.exports = { parseRound };
if (require.main === module) {
  const assert = require('node:assert/strict');
  const fixture = '### JORNADA 1\n03/10 | Desportivo O. Moscavide | 0-6 | SL Olivais B\n03/10 | CAC | 7-1 | Damaiense B\n08/12 | Tenente Valdez | 15:00 | AD Pastéis\n## Classificação';
  const rows = parseRound(fixture,1);
  assert.equal(rows.length,2);
  assert.equal(rows[0].away,'SL Olivais B');
  assert.equal(rows[0].awayGoals,6);
  assert.throws(()=>parseRound(fixture,2),/Round mismatch/);
  assert.equal(parseRound('### JORNADA 2\n10/10 | CAC | 15:00 | 3F',2).length,0);
  console.log('PASS: score extraction, squad label, missing result, round guard');
}
