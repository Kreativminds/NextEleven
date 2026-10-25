# NextEleven — Nightly QA Run Log

Persistent record for next11-nightly-qa — lets each run scope its work to
"what changed since last time" instead of re-reading the whole app, and
avoids re-flagging something already triaged and left open on purpose.

Newest entry on top.

---

## 2026-10-25 — Scheduled nightly run

- lastInspectedCommit: 428ddef
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt again stated BUGS.md had exactly one
  Open entry (`integ_fix_review`, i18n, P3) to process — this is now the
  11th night running (2026-10-15 through tonight) the scheduled prompt
  has hardcoded this same stale claim. Confirmed again: BUGS.md's "Open"
  section is empty; the real fix landed 2026-10-12 via PR #1. Went with
  actual repo state, per every prior run since 10-15.
- Scope: diff since 040650b (last run's lastInspectedCommit) was only 3
  commits, all `.claude/qa/` bookkeeping (lock + run-log housekeeping
  from the 2026-10-24 run plus tonight's own in-flight lock commit) —
  zero touches to `index.html`, `css/nexteleven.css`, `team.html`, or
  `public-stats-core.js`.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1949/1949 keys, no gaps).
- Zero-AI early exit fired: no app-code diff, both checks green, BUGS.md
  Open section empty, nothing in Known Unresolved changed or worth
  reconsidering. No subagent spawned, no AI reasoning spent beyond this
  scoping/reporting pass.
- Found / Fixed / Needs approval / Pending: none — nothing to report.

## 2026-10-24 — Scheduled nightly run

- lastInspectedCommit: 040650b
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process. This is now
  the 10th night running (2026-10-15 through tonight) that the scheduled
  prompt has hardcoded this same stale claim — the real fix landed
  2026-10-12 via PR #1. Confirmed again tonight: BUGS.md's "Open" section
  is empty, and the `integ_fix_review` EN string is present in index.html,
  matching the PT string (i18n-parity check below also confirms 1949/1949
  keys, no gaps). Went with the real repo state, per every prior run
  since 10-15. Re-flagging once more: whoever generates the scheduled
  prompt should stop hardcoding this.
- Scope: diff since 3ab1f40 (last run's lastInspectedCommit) touched
  `index.html`, `public-stats-core.js` and `team.html` via 4 commits —
  fc6eb46 (add post-match summary card to Parents Page + admin Goals
  tab), 277ac3a (make Parents Page scorer names independent of the
  "Show player stats" toggle), 470892f (fix scorer names + reduce text
  prominence), 84aecb5 (side-by-side scorer columns, drop 24h cap on
  admin tab) — plus 3 version-bump commits. All 4 were made directly to
  `main` by an interactive session the same day (2026-10-24, all
  commits timestamped between 16:26 and 21:02), each commit message
  citing explicit "per Victor"/"Victor confirmed" direction, not found
  by this agent. Zero-AI early exit did not fire (app code changed), so
  triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1949/1949 keys, no gaps).
- Triage (haiku): given only the 4 commits' messages + diffstat (not the
  full diffs) plus the check results and the empty BUGS.md Open section,
  returned: P1 scorer names fixed twice then the layout changed again —
  may be incomplete/regressed; P1 277ac3a's toggle-independence change
  may leak data the toggle is meant to hide; P2 dropping the 24h cap on
  the admin tab is a behavior change worth confirming was intended; P2
  summary logic duplicated across index.html/team.html/public-stats-core.js
  risks the two views drifting apart; P2 fc6eb46 adds 283 lines with no
  tests — edge cases worth checking (zero-goal games, own goals, unnamed
  scorers, ties); P3 the deterministic checks don't cover this behavior.
  Orchestrator read the actual diffs and current code (not just the
  summary) to verify each:
  - Both P1s: not real concerns, already addressed in the commit
    messages themselves. 470892f's own text explains and fixes the
    first bug (team.html passed `data.guestPlayers`, a field that
    doesn't exist in the public payload — guest players are per-game
    `g.guestPlayers` — so every guest scorer fell back to "Unknown";
    fixed to pass `g.guestPlayers`). 277ac3a's toggle-independence is an
    explicit, confirmed Victor decision, not a silent leak: the commit
    message states the backend's `get_public_team_data` RPC was changed
    to return per-game `goalScorers`/`goalEvents` ungated but restricted
    server-side to games finished within the last 3 days — i.e. the
    scope was deliberately narrowed to "this match only," not opened up
    to full season history regardless of the privacy toggle.
  - 24h-cap drop: explicit, confirmed Victor decision per 84aecb5's
    message (admin tab only; the Parents Page card keeps its own 24h
    window), with the admin tab's EN/PT hint text updated to match in
    the same commit. Not a defect.
  - Duplicated summary logic: real, pre-existing, already-documented
    tech debt (see the "DUPLICATED TECHNICAL DEBT" header comment at
    the top of `public-stats-core.js`, predating tonight) — not a new
    issue from tonight's commits, and not something to restructure
    unattended.
  - fc6eb46 edge cases: checked `buildMatchGoalSummary` directly — own
    goals (`isOwnGoal`), zero-goal games (empty `ourGoals`/
    `opponentGoals`, template already guards on `(ourLines ||
    theirLines)` before rendering the section at all), and unresolved
    scorer names (falls back to "Unknown") are all explicitly handled.
    No defect found.
  - One residual item this agent could not fully close out from static
    code alone: `buildMatchGoalSummary` (shared by both pages) only
    counts a gpRecords entry as a scorer when `r.calledUp` is truthy.
    team.html's `renderMatchSummaryCard` (277ac3a) now builds its
    `gps` straight from the backend's new `goalScorers` field
    (`.map(r => ({ ...r, gameId: g.gameId }))`, no explicit
    `calledUp` set) rather than the old gated `gamePlayers` rows, which
    always had `calledUp: true`. Whether the backend's `goalScorers`
    rows include a `calledUp` (or equivalent truthy) field is defined
    server-side in the Supabase RPC, which isn't tracked in this repo,
    so it can't be confirmed from code alone, and this agent didn't
    have and didn't attempt to obtain a real team share token to probe
    the live RPC response. Leaning toward "this is fine": 84aecb5's own
    commit message describes Victor giving layout feedback against
    "today's home win" — i.e. he was looking at this card rendering
    live, same day, after 277ac3a had already landed. Noted below for a
    quick human double-check rather than guessed at blind.
- Fixed: none (0/2 of cap used — nothing held up as a genuine,
  actionable defect).
- Needs approval: none — see the one residual item above, filed as a
  double-check rather than a confirmed issue (no branch/PR opened for
  it, since there is nothing to fix yet and no reproduction).
- Pending / worth a quick look next time you're on the Parents Page
  after a game with goals: confirm scorer names (not just "Unknown"/
  the opponent placeholder) actually render on the pinned match-summary
  card. If they don't, the likely cause is the `goalScorers`→`gps`
  mapping in `renderMatchSummaryCard` missing a `calledUp` flag that
  `buildMatchGoalSummary` expects — a one-line fix (set
  `calledUp: true` in that `.map()`), flag it in BUGS.md and a future
  run (or an interactive session) can land it immediately.
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-23 — Scheduled nightly run

- lastInspectedCommit: 3ab1f40
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process. This is now
  the 9th night running (2026-10-15 through tonight) that the scheduled
  prompt has hardcoded this same stale claim — the real fix landed
  2026-10-12 via PR #1. Confirmed again tonight: BUGS.md's "Open" section
  is empty, and the `integ_fix_review` EN string is present in index.html,
  matching the PT string (i18n-parity check below also confirms 1943/1943
  keys, no gaps). Went with the real repo state, per every prior run
  since 10-15. Re-flagging once more: whoever generates the scheduled
  prompt should stop hardcoding this.
- Scope: diff since 32f6ef6 (last run's lastInspectedCommit) touched only
  this agent's own bookkeeping (`.claude/qa/lock.json`,
  `.claude/qa/run-log.md` from last night's run) — no commits to
  `index.html`, `css/nexteleven.css`, `team.html`, or
  `public-stats-core.js`. No interactive bug-fixer session landed
  anything on `main` either.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1943/1943 keys, no gaps).
- Zero-AI early exit: fired. No app-code diff, both checks pass, BUGS.md
  Open section empty (confirmed directly, not from the scheduled
  prompt's claim), nothing in Known Unresolved changed or worth
  reconsidering (no code moved since it was last written). No haiku
  triage spawned, no AI reasoning spent on triage/fix.
- Fixed: none (0/2 of cap used — nothing to look at).
- Needs approval: none.
- Pending: none.

## 2026-10-22 — Scheduled nightly run

- lastInspectedCommit: 32f6ef6
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process. This is now
  the 8th night running (2026-10-15 through tonight) that the scheduled
  prompt has hardcoded this same stale claim — the real fix landed
  2026-10-12 via PR #1. Confirmed again tonight: BUGS.md's "Open" section
  is empty, and the `integ_fix_review` EN string is present in index.html,
  matching the PT string (i18n-parity check below also confirms 1943/1943
  keys, no gaps). Went with the real repo state, per every prior run since
  10-15. Re-flagging once more: whoever generates the scheduled prompt
  should stop hardcoding this.
- Scope: diff since 92e2e95 (last run's lastInspectedCommit) touched
  `index.html` via one commit, 8396fa8 ("Fix three League Classification
  import UX issues"), made directly to main outside this agent (no
  `nightly-qa:` prefix, no maintenance branch — same pattern as other
  interactive sessions on prior nights). No other app-code files changed.
  Zero-AI early exit did not fire (app code changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1943/1943 keys, no gaps).
- Triage (haiku): given only the commit message for 8396fa8 (not the
  diff) plus the check results and the empty BUGS.md Open section,
  returned 3 candidates: P1 possible silent truncation in
  `firstTableRows()` if position were ever compared as a string (e.g.
  "10" < "9") or left blank; P1 possible wrong team auto-marked "our
  team" via `matchAlias()` if an alias matched ambiguously or scope were
  wrong; P3 dark-mode contrast risk on the new amber "our team" row
  styling. Orchestrator verified each against the actual code; none held
  up:
  - `firstTableRows` concern: not real. `buildRow()` runs every position
    through `toIntOrNull()` before it ever reaches `firstTableRows` —
    position is always a proper integer or `null`, never a string, so no
    "10" vs "9" lexicographic comparison is possible. A blank/null
    position is explicitly skipped by the `pos != null` guard rather than
    breaking the ordering check — intentional, not a defect.
  - `matchAlias` concern: not real. The alias record for a given
    season/competition/phase/series scope is only ever appended to with a
    normalized name the admin explicitly confirmed by marking a row "our
    team" on a previous publish (`clsPublish`'s `cleanRows.find(r =>
    r.isOurTeam)` path) — there is exactly one alias record per scope,
    built solely from admin-confirmed names. A wrong auto-mark would
    require the admin to have mis-marked a row previously (a data/human
    issue, not a code defect this agent can detect or fix).
  - Dark-mode concern: not applicable. Grepped the whole codebase —
    `prefers-color-scheme`, `data-theme`, and a `.dark` class don't exist
    anywhere in `css/nexteleven.css` or `index.html`. The app has no dark
    mode, so there's no dark-mode contrast to regress.
- Fixed: none (0/2 of cap used — nothing found held up as a genuine,
  fixable issue after verification).
- Needs approval: none.
- Pending: none (every triage candidate was run to ground tonight, not
  deferred for lack of time).
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-21 — Scheduled nightly run

- lastInspectedCommit: 92e2e95
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process. This is now
  the 7th night running (2026-10-15 through tonight) that the scheduled
  prompt has hardcoded this same stale claim — the real fix landed
  2026-10-12 via PR #1. Confirmed again tonight: BUGS.md's "Open" section
  is empty, and the `integ_fix_review` EN string is present in index.html,
  matching the PT string. Went with the real repo state, per every prior
  run since 10-15. Re-flagging once more: whoever generates the scheduled
  prompt should stop hardcoding this — it's a recurring false signal, not
  a one-off.
- Scope: diff since 3f7894a (last run's lastInspectedCommit) touched only
  this agent's own bookkeeping (`.claude/qa/lock.json`,
  `.claude/qa/run-log.md` from last night's run) — no commits to
  `index.html`, `css/nexteleven.css`, `team.html`, or
  `public-stats-core.js`. No interactive bug-fixer session landed
  anything on `main` either.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1942/1942 keys, no gaps).
- Zero-AI early exit: fired. No app-code diff, both checks pass, BUGS.md
  Open section empty (confirmed directly, not from the scheduled
  prompt's claim), nothing in Known Unresolved changed or worth
  reconsidering (no code moved since it was last written). No haiku
  triage spawned, no AI reasoning spent on triage/fix.
- Fixed: none (0/2 of cap used — nothing to look at).
- Needs approval: none.
- Pending: none.

## 2026-10-20 — Scheduled nightly run

- lastInspectedCommit: 3f7894a
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process. This is now
  the 6th night running (2026-10-15 through tonight) that the scheduled
  prompt has hardcoded this same stale claim — the real fix landed
  2026-10-12 via PR #1. Confirmed again tonight: BUGS.md's "Open"
  section is empty, and the `integ_fix_review` EN string is present at
  index.html:7041 (`'{n} similar games — NOT merged. Check whether they
  are really the same game.'`), matching the PT string. Went with the
  real repo state, per every prior run since 10-15. Re-flagging: whoever
  generates the scheduled prompt should stop hardcoding this — it's a
  recurring false signal, not a one-off.
- Scope: diff since 924d7b1 (last run's lastInspectedCommit) touched
  only this agent's own bookkeeping (`.claude/qa/lock.json`,
  `.claude/qa/run-log.md` from last night's run) — no commits to
  `index.html`, `css/nexteleven.css`, `team.html`, or
  `public-stats-core.js`. No interactive bug-fixer session landed
  anything on `main` either.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1942/1942 keys, no gaps).
- Zero-AI early exit: fired. No app-code diff, both checks pass, BUGS.md
  Open section empty (confirmed directly, not from the scheduled
  prompt's claim), nothing in Known Unresolved changed or worth
  reconsidering (no code moved since it was last written). No haiku
  triage spawned, no AI reasoning spent on triage/fix.
- Fixed: none (0/2 of cap used — nothing to look at).
- Needs approval: none.
- Pending: none.

## 2026-10-19 — Scheduled nightly run

- lastInspectedCommit: 924d7b1
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt again claimed BUGS.md had exactly one
  Open entry (`integ_fix_review`, i18n) — same stale claim as every prior
  night going back to 2026-10-15 (it was resolved 2026-10-12, PR #1).
  Confirmed BUGS.md's real "Open" section is empty and the
  `integ_fix_review` EN string is present in index.html. Went with the
  real repo state, as every prior run has. Flagging again (per every
  run-log entry since 10-15) that whatever generates the scheduled
  prompt should stop hardcoding this.
- Scope: diff since 841dc50 (last run's lastInspectedCommit) touched only
  this agent's own bookkeeping (`.claude/qa/lock.json`,
  `.claude/qa/run-log.md` from last night's run) — no commits to
  `index.html`, `css/nexteleven.css`, `team.html`, or
  `public-stats-core.js`. No interactive bug-fixer session landed
  anything on `main` since last night either.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1942/1942 keys, no gaps).
- Zero-AI early exit: fired. No app-code diff, both checks pass, BUGS.md
  Open section empty, nothing in Known Unresolved changed or worth
  reconsidering (no code moved since it was last written). No haiku
  triage spawned, no AI reasoning spent on triage/fix.
- Fixed: none (0/2 of cap used — nothing to look at).
- Needs approval: none.
- Pending: none.

## 2026-10-18 — Scheduled nightly run

- lastInspectedCommit: 841dc50
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt again claimed BUGS.md had exactly one
  Open entry (`integ_fix_review`, i18n) — same stale claim as the last
  several nights (it was resolved 2026-10-12). Confirmed BUGS.md's real
  "Open" section is empty and the `integ_fix_review` EN string is
  present in index.html. Went with the real repo state, as every prior
  run has. Flagging again that whatever generates the scheduled prompt
  should stop hardcoding this.
- Scope: diff since fcc36cd (last run's lastInspectedCommit) touched
  index.html via 4 merged PRs, all made directly to main outside this
  agent (no `nightly-qa:` prefix, no maintenance branch — same pattern
  as every other night): PR #5 (kickoff-timezone fix, goalEvents-reset
  cleanup, captain-button-lockout fix — all three were open items from
  this agent's own earlier nights, now closed by an interactive
  session), PR #6 (onboarding wizard simplified from 8 steps to 3, plus
  several related fixes), PR #7 (country field extended to two more
  team-creation paths). Zero-AI early exit did not fire (app code
  changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1942/1942 keys, no gaps).
- Triage (haiku): given commit-message summaries of all 4 PRs (not the
  full diff) plus the check results and empty BUGS.md Open section,
  returned 8 "verify" candidates, P1 down to P3 — none a slam-dunk,
  all explicitly framed as "worth a closer look," which is the right
  call given it only saw summaries, not code. Orchestrator verified
  each against the actual code before acting; none held up as a fixable
  defect:
  - Not real / already handled correctly: kickoff-read-side concern
    (team.html already derives local display time from the full ISO
    timestamp — the bug was only in how the date was constructed before
    saving, already fixed); public-stats soft-deleted-goalEvents concern
    (public-stats-core.js reads `gamePlayers.goals`/`.assists` directly,
    never touches `goalEvents` at all — confirmed by grep, no code path
    exists to check); legacy-position-taxonomy concern (the new invalid-
    position report is explicitly a report-only diagnostic per its own
    code comment and the PR's stated scope — "no historical player
    records are modified" — and `getPositionGroup` already falls back
    to an `'other'` bucket for unrecognized values rather than hiding
    players); country-required-on-edit concern (PR #6's own commit
    message states the design explicitly: "required-on-create" only,
    optional on existing records — confirmed Edit Season's save handler
    deliberately has no required-check, matching that stated intent);
    i18n-remapping-correctness concern (checked all 4 remapped squad-
    form keys in both EN and PT — correct, sensible labels).
  - Real but not worth a fix tonight (moved to Known Unresolved below):
    dead wizard-step code left over from the 8-to-3 consolidation
    (confirmed genuinely unreachable, zero functional impact — cleanup,
    not a bug); possible wrong-calendar-day `actualKickoffAt` on games
    saved before today's timezone fix (unconfirmed against real data,
    and backfilling match data automatically is out of scope anyway).
  - Not pursued: Getting Started checklist flag backfill (new
    `gettingStartedSettingsVisited` flag starts `false` for existing
    clubs who already opened Settings many times before this shipped) —
    true but cosmetic, self-corrects the moment Settings is opened
    again, not worth a slot.
- Fixed: none (0/2 of cap used — nothing found held up as a genuine,
  fixable issue after verification).
- Needs approval: none.
- Pending: none (every triage candidate was run to ground tonight, not
  deferred for lack of time).
- Known Unresolved housekeeping: removed the captain-button and
  `resetGameGoals`/`goalEvents` entries — both fixed in today's PR #5.
  Added the two new "real but not worth fixing tonight" items above.

## 2026-10-17 — Scheduled nightly run

- lastInspectedCommit: fcc36cd
- Trigger: scheduled nightly run.
- Scope: diff since f760e82 (last run's recorded lastInspectedCommit)
  touched index.html and team.html via 6 commits (35c398d, affd8/affb9d8,
  b12da41, 1ef1b08, 2fcd004, 59cee92 — 11-starter-cap guest fix, "hide C
  button on other rows once captain set," manual kickoff override +
  editable kickoff-time dialog, Parents Page live-card kickoff display,
  per-goal timestamp log), made directly to main outside this agent today
  (no `nightly-qa:` prefix, no maintenance branch — interactive bug-fixer
  session, same pattern as previous nights). Zero-AI early exit did not
  fire (app code changed), so triage ran.
  - Note: today's scheduled prompt again claimed BUGS.md had an Open
    entry (`integ_fix_review`, i18n). Same stale claim as the last two
    nights — it was resolved on 2026-10-12 and the real Open section is
    empty. Went with the real repo state. Third night running the prompt
    text hasn't been refreshed — flagging again that this should be
    fixed at the source (whatever generates the scheduled prompt).
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse), before and after
    the fix.
  - `check-i18n-parity.js` → OK (1932/1932 keys, no gaps), before and
    after the fix (no new keys added by tonight's fix).
- Triage (haiku): reviewed the 6-commit diff to index.html/team.html.
  Returned several candidates; orchestrator verified each against the
  actual (non-diff) code before acting — most didn't hold up:
  - False positives, confirmed not real: team.html getLang()/roundLabel
    concern (transcription artifact in the triage prompt, not an actual
    diff — both already exist and work); getLang() lowercase vs
    I18n.get() uppercase casing "mismatch" (each file consistently uses
    its own established convention); goalEvents gameId index "may not
    exist" (it was created with the store, pre-existing, unrelated to
    tonight's diff); soft-delete/tombstone re-deletion in
    logGoalEventsForDelta's decrease path (DB.getAll already filters
    isDeleted rows by design, confirmed in DB.softDelete's own comment);
    Supabase goal_events payload-shape risk (uses the same generic
    JSONB-payload cloudRow as every other store, no per-field columns,
    and push() already has per-record try/catch + duplicate-key recovery
    so one bad row can't stall the queue); Parents Page not receiving
    actualKickoffAt (games already sync their whole record as one JSONB
    payload, same as every other field added to games historically — no
    evidence of an explicit column allowlist anywhere in the pull path).
  - Real but not pursued as a fix tonight (see "Needs approval" and
    "Pending" below): captain-button stuck-hidden edge case; goalEvents
    not cleaned up by resetGameGoals.
  - Real and fixed: see below.
- Fixed (1/2 of cap used):
  - P2 — `openKickoffTimeDialog`/`confirmKickoffTime` (index.html, new
    tonight in 59cee92) took the dialog's calendar date from
    `toISOString().slice(0,10)` (UTC date) while hour/minute were local —
    in a timezone where local/UTC fall on different calendar days at tap
    time (Brazil evenings, UTC-3; Portugal just after midnight in summer,
    UTC+1), `actualKickoffAt` got the right time but the wrong day.
    Fixed by building the date from local getFullYear/getMonth/getDate
    via the existing `dISO({y,m,d})` helper, in both the dialog-open path
    and the confirm-time fallback. Scoped to exactly those two spots.
    Commit `68c56c3` (version bump `7359c07`) on
    `maintenance/nightly-2026-10-17`.
  - PR: https://github.com/Kreativminds/NextEleven/pull/4
- Needs approval:
  - Captain ("C") button (`renderStartingXITab`, from today's affb9d8)
    can end up hidden on every row with no UI path to clear/reassign
    captaincy, if the current captain's own row ever becomes `avail`
    (unavailable) while still called up. The adjacent existing comment
    says a called-up player "should never actually be unavailable here"
    under today's rules, so not reachable in normal use right now — but
    this is core Starting XI/captain logic shared by multiple features,
    so left for Victor's call rather than touched unattended. Proposal if
    wanted: always show the captain's own C button regardless of `avail`.
- Pending (not reached — cap not binding, only 1 fix cleared the bar):
  - `resetGameGoals` zeroes `gamePlayers.goals`/`.assists` directly,
    bypassing `logGoalEventsForDelta` (added tonight) — a reset leaves
    orphaned `goalEvents` rows. Zero current observable impact (nothing
    reads `goalEvents` back into any UI yet). Worth a look once something
    actually consumes `goalEvents`.

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

- ~~Captain button stuck-hidden edge case~~ — fixed 2026-10-18 in
  `shouldShowCaptainButton` (commit 2d3afdd, PR #5, interactive session
  outside this agent). Removed from this list.

- ~~`resetGameGoals` leaving orphaned `goalEvents` rows~~ — fixed
  2026-10-18 via `clearAllGoalEventsForGame` (commit 2d3afdd, PR #5,
  same session as above). Removed from this list.

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

- Historical `actualKickoffAt` values possibly on the wrong calendar day
  for games where "Game Starting Now" / the kickoff-time dialog was used
  before today's UTC-crossing-timezone fix (commit ecf0b2d, PR #5)
  landed. The fix only corrects new saves going forward; nothing
  backfills records already written with the old UTC-derived date. Not
  confirmed against real data (would need to check actual game records
  for a BR/PT-timezone edge case), and correcting past records
  automatically is out of scope for this agent either way (touches
  user-facing match data) — flagging for Victor to spot-check if a
  wrong kickoff day turns up on an older game.

- Dead code from the 8-to-3 First-Time Wizard consolidation (660e650):
  `renderFTWStepWelcome`, `renderFTWStepOpponents`, `renderFTWStepResources`,
  `renderFTWStepReview` and their supporting functions are no longer
  reachable — `renderFirstTimeWizardStep()`'s dispatcher only handles
  steps 1-3 and `FIRST_TIME_WIZARD_STEPS = 3` clamps any in-flight draft
  down to that range. Confirmed no live code path still calls into them.
  Zero functional impact (truly dead, not a latent bug) — pure cleanup
  opportunity, not urgent.
