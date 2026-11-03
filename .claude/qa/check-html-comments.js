#!/usr/bin/env node
// Deterministic check #3 — no AI tokens needed.
// Confirms HTML comments in index.html/team.html are well-formed, and that
// the app's own stylesheet <link> isn't accidentally swallowed by one.
//
// Added 2026-11-02 after a same-day production incident (commit 8b64fe0):
// an anti-FOUC comment was opened with <!-- but closed with the CSS
// comment marker */ instead of -->. Browsers don't treat */ as an HTML
// comment terminator, so the open comment silently swallowed everything up
// to the next literal --> later in <head> — including the
// <link rel="stylesheet" href="css/nexteleven.css"> tag itself, which broke
// the whole app's styling. check-syntax.js only parses <script> blocks, so
// it never saw this; this check closes that gap.
//
// Usage: node .claude/qa/check-html-comments.js [file...]
// Defaults to index.html and team.html if no args given.

const fs = require('fs');
const files = process.argv.slice(2);
const targets = files.length ? files : ['index.html', 'team.html'];

let allOk = true;
const results = targets.map(file => {
  const html = fs.readFileSync(file, 'utf8');
  const openCount = (html.match(/<!--/g) || []).length;
  const closeCount = (html.match(/-->/g) || []).length;
  const issues = [];

  if (openCount !== closeCount) {
    issues.push(`unbalanced comment markers: ${openCount} '<!--' vs ${closeCount} '-->'`);
  }

  // Walk comments left-to-right. HTML comments don't nest, so a correctly
  // closed comment's captured body should never contain another '<!--' —
  // if it does, the real closing '-->' was missing or malformed and this
  // "comment" actually swallowed a later comment's opener (and everything
  // in between).
  const comments = [...html.matchAll(/<!--([\s\S]*?)-->/g)];
  comments.forEach((m, i) => {
    if (m[1].includes('<!--')) {
      issues.push(`comment #${i} (byte offset ${m.index}) contains a nested '<!--' — its closing '-->' is probably missing or was replaced with something else (e.g. '*/')`);
    }
  });

  // The admin app's stylesheet link must not be swallowed inside a comment.
  if (file === 'index.html') {
    const needle = 'href="css/nexteleven.css';
    const idx = html.indexOf(needle);
    if (idx === -1) {
      issues.push(`'${needle}' not found at all`);
    } else {
      const swallowed = comments.some(m => idx > m.index && idx < m.index + m[0].length);
      if (swallowed) issues.push(`'${needle}' is inside an HTML comment — the stylesheet will not load`);
    }
  }

  if (issues.length) allOk = false;
  return { file, ok: issues.length === 0, openCount, closeCount, commentCount: comments.length, issues };
});

console.log(JSON.stringify({ ok: allOk, results }, null, 2));
process.exit(allOk ? 0 : 1);
