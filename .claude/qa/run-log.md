# NextEleven — Nightly QA Run Log

Persistent record for next11-nightly-qa — lets each run scope its work to
"what changed since last time" instead of re-reading the whole app, and
avoids re-flagging something already triaged and left open on purpose.

Newest entry on top.

---

## 2026-10-16 — Scheduled nightly run

- lastInspectedCommit: f760e82
- Trigger: scheduled nightly run.
- Scope: diff since c9f4798 (last run's recorded lastInspectedCommit)
  touched team.html via two commits (d744cc1 "Fix Waze opening without
  a route on the parent page", c71708e "Fix Google Maps opening a
  garbled search instead of the venue"), both made directly to main
  outside this agent today (no `nightly-qa:` prefix, no maintenance
  branch — an interactive bug-fixer session, same pattern as 2026-10-15).
  Zero-AI early exit did not fire (app code changed), so triage ran.
  - Note: today's scheduled prompt again claimed BUGS.md had an Open
    entry (`integ_fix_review`, i18n). That's stale — same as last
    night — it was resolved on 2026-10-12 and the real Open section is
    empty. Went with the real repo state. Second night running the
    prompt text hasn't been refreshed; worth updating at the source if
    this keeps recurring.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1919/1919 keys, no gaps).
- Triage (haiku): reviewed the two-commit diff to the directions/Waze
  chooser in team.html (new `opponentMapAddress` param threaded through
  `directionsLinkHtml`/`registerDirectionsTarget`, lat/lng extraction
  from full Google Maps URLs, priority order in `openDirectionsChooser`).
  No P0/P1. Two hedged P2/P3 candidates returned, both investigated
  further and not pursued as fixes tonight (see Known Unresolved) —
  treated as equivalent to "nothing concrete to fix."
- Fixed: none (0/2 of cap used — nothing cleared the bar for an
  unattended fix).
- Needs approval: none.
- Pending: none (nothing reached but cut by the cap — the cap wasn't
  binding).

## 2026-10-15 — Scheduled nightly run

- lastInspectedCommit: c9f4798
- Trigger: scheduled nightly run.
- Scope: diff since 0d5fe9d (last run's recorded lastInspectedCommit)
  touched index.html via one commit, 226b5d3 ("Lock the Home carousel
  card to one consistent layout and height"), made directly to main
  outside this agent (no `nightly-qa:` prefix, no maintenance branch —
  looks like an interactive bug-fixer session). Zero-AI early exit did
  not fire (app code changed), so triage ran.
  - Note: today's scheduled prompt claimed BUGS.md had one Open entry
    (`integ_fix_review`, i18n). That was stale — it was already
    resolved on 2026-10-12 (see below) and the actual Open section is
    empty. Went with the real repo state, not the stale prompt text.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse), before and after
    each fix.
  - `check-i18n-parity.js` → OK (1919/1919 keys, no gaps), before and
    after each fix.
- Triage (haiku): one concrete candidate (P2, kick-off time clippable)
  plus two P3s, one speculative/unconfirmed (see "Known Unresolved").
- Fixed (2/2 of cap used):
  - P2 — the round/date/kick-off line on the Home carousel card became
    `nowrap`+ellipsis in 226b5d3 along with the opponent/venue lines;
    unlike those, its trailing content is the match kick-off time, which
    could get silently clipped on a narrow viewport with a round label
    set and the Arrive By box shown. Removed nowrap/ellipsis from that
    line only (it can wrap to a 2nd line in the rare case it's too long);
    opponent/venue lines keep their truncation since that's what actually
    fixed last night's height-variance bug. Commit fe43e0b (version bump
    31790cc) on `maintenance/nightly-2026-10-15`.
  - P3 — truncated opponent/venue text had no way to be read in full.
    Added `title=` with the full text to both, matching the existing
    app convention (e.g. position-pill `title=` elsewhere). Commit
    80c54bc (version bump 06bf8b4) on `maintenance/nightly-2026-10-15`.
  - PR: https://github.com/Kreativminds/NextEleven/pull/3
- Needs approval: none.
- Pending (not reached, cap was binding): the third candidate below is
  carried to "Known Unresolved" rather than counted as "pending",
  since it's unconfirmed, not a cap-cut concrete fix.

## 2026-10-14 — Scheduled nightly run

- lastInspectedCommit: 0d5fe9d
- Trigger: scheduled nightly run.
- Scope: diff since 4a8c3c2 (last run's recorded lastInspectedCommit)
  touched index.html, css/nexteleven.css and team.html (7 commits: blue
  accent color added to admin UI, CSS cache-bust bump, round number shown
  across all game references in team.html, Home carousel height/arrival-box
  fixes, PWA icon replacement). Zero-AI early exit did not fire (app code
  changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse), before and after fix.
  - `check-i18n-parity.js` → OK (1919/1919 keys, no gaps), before and after fix.
- Triage (haiku, 2 passes — first pass sent an empty diff by mistake and was
  re-run with the actual diff included): identified the blue-accent CSS
  rule as the one concrete candidate; a second, speculative concern about
  sticky-column width was raised but self-flagged as unconfirmed/pre-existing
  and not pursued (verified: inline `min-width:60px` on `.col-sticky-num`
  predates tonight's diff — only the cell's text content changed).
- Fixed (1/2 of cap used):
  - Blue left-accent strip (added by commit 1745e3f tonight) only rendered
    on `.card` — the other 7 target selectors (`.stat-card`, `.table-wrap`,
    `.timeline-item`, `.form-panel`, `.goal-row`, `.game-header`,
    `.game-detail-table-wrap`) each have their own later `border:1px solid
    var(--border)` base rule that reset `border-left` back to gray after
    the accent rule, same specificity, later source order wins. Moved the
    accent rule to the end of the stylesheet, after all 8 target base
    rules, so it reliably wins for all of them. CSS-only, no selectors/colors
    changed. Commit ba4037e (version bump 659cfa1) on
    `maintenance/nightly-2026-10-14`. PR: https://github.com/Kreativminds/NextEleven/pull/2
- Needs approval: none.
- Pending (not reached, cap not binding — only 1 candidate existed): none.

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

- Home carousel card `min-height:118px` (set in 226b5d3) is a floor, not
  a guarantee — if real content ever exceeds it (e.g. the fixture-status
  badge wrapping on a long label, or a larger user text scale), slides
  could still differ in height. Speculative, not confirmed against real
  content as of 2026-10-15 — don't re-triage from scratch, but worth a
  quick look if Victor or a future run sees carousel height jitter again.

- Directions chooser (team.html, `openDirectionsChooser`/
  `extractLatLngFromMapUrl`), from tonight's 2026-10-16 triage of
  d744cc1/c71708e:
  - P2: when a resolved address or extracted lat/lng is known, the
    Google Maps button now always drops the stored `mapUrl` in favor of
    a plain coordinate/address search — including for a full (non-short)
    Google Maps "place" link, which would lose the named place card in
    favor of a bare pin. No admin UI writes `opponentMapAddress` or
    `opponentMapUrl` anywhere in index.html (grepped, confirmed) — the
    only populated instance right now is the one hardcoded tonight for
    the Tenente Valdez game, paired with a short `maps.app.goo.gl` link,
    which is exactly the case this change was meant to fix. So no actual
    regression is live today; only becomes one if a future game is given
    both a full/working Google Maps place link *and* a resolved address.
  - P3: `extractLatLngFromMapUrl`'s `@lat,lng` pattern is the map's
    camera-center coordinate in a Google Maps URL, not guaranteed to be
    the exact pin — only the `!3d/!4d` and `destination=` patterns are
    place-specific. For a saved URL that's a plain viewport link (not a
    place share), Waze could get a slightly off coordinate. No evidence
    this is actually happening with current data.
  - Not pursued as a fix tonight — both are unconfirmed against real
    data (no admin UI path populates these fields yet) and the "garbled
    token" fix they're part of is this morning's own deliberate, already
    reasoned design choice, not a defect introduced carelessly. Worth a
    look if/when `opponentMapAddress` gets a real admin-UI input and
    sees broader use.
