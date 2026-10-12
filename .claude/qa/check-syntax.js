#!/usr/bin/env node
// Deterministic check #1 — no AI tokens needed.
// Confirms both <script> blocks in index.html still parse as valid JS.
// Exit 0 + "OK" per block = safe. Exit 1 on any parse error.
//
// Usage: node .claude/qa/check-syntax.js [path-to-index.html]

const fs = require('fs');
const path = process.argv[2] || 'index.html';

const html = fs.readFileSync(path, 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)];

if (scripts.length === 0) {
  console.log(JSON.stringify({ ok: false, error: 'no <script> blocks found — unexpected file shape' }));
  process.exit(1);
}

let allOk = true;
const results = scripts.map((m, i) => {
  try {
    new Function(m[1]);
    return { block: i, ok: true, length: m[1].length };
  } catch (e) {
    allOk = false;
    return { block: i, ok: false, length: m[1].length, error: e.message };
  }
});

console.log(JSON.stringify({ ok: allOk, blocks: results }, null, 2));
process.exit(allOk ? 0 : 1);
