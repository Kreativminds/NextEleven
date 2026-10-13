# NextEleven — Nightly QA Run Log

Persistent record for next11-nightly-qa — lets each run scope its work to
"what changed since last time" instead of re-reading the whole app, and
avoids re-flagging something already triaged and left open on purpose.

Newest entry on top.

---

## 2026-10-13 — Scheduled nightly run

- lastInspectedCommit: 4a8c3c2
- Trigger: scheduled nightly run.
- Scope: diff since 3b06d40 (last run's recorded lastInspectedCommit)
  only touches index.html via 2752e9c — which is the EN translation fix
  already reviewed, fixed and merged by last night's run (PR #1). No
  other app-code commits since then. Because index.html appears in the
  diff window, the zero-AI early exit condition wasn't literally met, so
  triage ran (cheap, confirmed nothing new).
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1919/1919 keys, no gaps either way).
- Triage (haiku): "none" — the only app-code change in window is the
  already-merged i18n fix; no new P0/P1/P2/P3 candidates.
- Fixed: none (nothing to fix).
- Needs approval: none.
- Pending: none.

## 2026-10-12 — Scheduled nightly run

- lastInspectedCommit: 3b06d40
- Trigger: scheduled nightly run (first real run; trial started today).
- Scope: commits since 37052b9 touched team.html (PWA/Parents Page, venue
  layout) — zero-AI early exit did not fire, so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → 1 finding (before fix): `integ_fix_review`
    missing in EN. OK (after fix).
- Triage (haiku): only concrete candidate was the known `integ_fix_review`
  i18n gap. No P0/P1/P2 found; team.html/PWA/icons/sw.js/manifest commits
  are new features with no visible defect, not flagged.
- Fixed (1/2 of cap used):
  - `integ_fix_review` missing EN translation — added EN string matching
    existing PT text. Commit 2752e9c on `maintenance/nightly-2026-10-12`
    (version bump 3ae384e). PR: https://github.com/Kreativminds/NextEleven/pull/1
- Needs approval: none.
- Pending (not reached, cap not binding — only 1 candidate existed): none.

## 2026-10-12 — Setup / dry run (manual, not a scheduled run)

- lastInspectedCommit: 37052b9
- Trigger: manual setup dry run, not the nightly schedule (not yet enabled).
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → 1 finding: `integ_fix_review` key exists in
    the PT translation block but is missing from EN. Used at the
    "possible duplicate game" row in the data-integrity checker
    (`I18n.t('integ_fix_review', {n: g.length})`); an English-language
    user would see a missing/raw key there instead of the message.
- Fixed: none (setup run — no fixes made per instruction not to do
  unrelated work while configuring the system).
- Logged to BUGS.md as an Open entry for the first real run to pick up.

## Known Unresolved
(carried forward between runs so they aren't re-analyzed from scratch)

(none — `integ_fix_review` resolved in the 2026-10-12 scheduled run above)
