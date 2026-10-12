#!/usr/bin/env node
// Deterministic check #2 — no AI tokens needed.
// Every key in TR.EN must also exist in TR.PT and vice versa. Catches the
// "added an English string, forgot the Portuguese one" mistake before it
// ships — exactly the kind of gap bug-fixer.md warns about.
//
// A naive "match anything followed by a colon" regex produces heavy false
// positives here: several TR values are long help/example strings that
// themselves contain "word: text" (e.g. a mini format example shown to the
// user), and those get mistaken for real keys. So this scans char-by-char
// and only ever treats `identifier:` as a real key when it's immediately
// followed by a string literal AND we are not currently inside one — then
// skips the whole string body (respecting \" / \' escapes) before looking
// for the next key, so nothing inside a value is ever re-scanned.
//
// Usage: node .claude/qa/check-i18n-parity.js [path-to-index.html]

const fs = require('fs');
const path = process.argv[2] || 'index.html';
const html = fs.readFileSync(path, 'utf8');

function findBlockRange(src, label, fromIndex) {
  const re = new RegExp(label + '\\s*:\\s*\\{');
  const m = src.slice(fromIndex).match(re);
  if (!m) throw new Error(`could not find ${label}:{ block`);
  const openBraceIdx = fromIndex + m.index + m[0].length - 1; // index of the '{'
  let depth = 1, i = openBraceIdx + 1;
  while (depth > 0 && i < src.length) {
    if (src[i] === '"' || src[i] === "'" || src[i] === '`') {
      i = skipString(src, i);
      continue;
    }
    if (src[i] === '{') depth++;
    else if (src[i] === '}') depth--;
    i++;
  }
  if (depth !== 0) throw new Error(`unbalanced braces scanning ${label} block`);
  return { start: openBraceIdx + 1, end: i - 1 }; // content between { and matching }
}

// i points at the opening quote char; returns index just past the closing one.
function skipString(src, i) {
  const quote = src[i];
  i++;
  while (i < src.length) {
    if (src[i] === '\\') { i += 2; continue; }
    if (src[i] === quote) return i + 1;
    i++;
  }
  return i; // unterminated — stop at EOF, caller treats as done
}

function extractKeys(blockText) {
  const keys = new Set();
  let i = 0;
  const n = blockText.length;
  while (i < n) {
    const ch = blockText[i];
    if (ch === '"' || ch === "'" || ch === '`') { i = skipString(blockText, i); continue; }
    if (/[A-Za-z0-9_]/.test(ch)) {
      const start = i;
      while (i < n && /[A-Za-z0-9_]/.test(blockText[i])) i++;
      const word = blockText.slice(start, i);
      // must be followed by optional whitespace, a colon, optional
      // whitespace, then a quote — i.e. this identifier is a property name
      // whose value is a string literal (every real TR entry is).
      let j = i;
      while (j < n && /\s/.test(blockText[j])) j++;
      if (blockText[j] === ':') {
        let k = j + 1;
        while (k < n && /\s/.test(blockText[k])) k++;
        if (blockText[k] === '"' || blockText[k] === "'" || blockText[k] === '`') {
          keys.add(word);
        }
      }
      continue;
    }
    i++;
  }
  return keys;
}

const trIdx = html.indexOf('const TR');
if (trIdx === -1) {
  console.log(JSON.stringify({ ok: false, error: 'const TR not found — i18n block shape may have changed' }));
  process.exit(1);
}

let enRange, ptRange;
try {
  enRange = findBlockRange(html, 'EN', trIdx);
  ptRange = findBlockRange(html, 'PT', enRange.end);
} catch (e) {
  console.log(JSON.stringify({ ok: false, error: e.message }));
  process.exit(1);
}

const enKeys = extractKeys(html.slice(enRange.start, enRange.end));
const ptKeys = extractKeys(html.slice(ptRange.start, ptRange.end));

const missingInPT = [...enKeys].filter(k => !ptKeys.has(k)).sort();
const missingInEN = [...ptKeys].filter(k => !enKeys.has(k)).sort();

const ok = missingInPT.length === 0 && missingInEN.length === 0;
console.log(JSON.stringify({
  ok,
  enKeyCount: enKeys.size,
  ptKeyCount: ptKeys.size,
  missingInPT,
  missingInEN,
}, null, 2));
process.exit(ok ? 0 : 1);
