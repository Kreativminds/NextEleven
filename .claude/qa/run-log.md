# NextEleven — Nightly QA Run Log

Persistent record for next11-nightly-qa — lets each run scope its work to
"what changed since last time" instead of re-reading the whole app, and
avoids re-flagging something already triaged and left open on purpose.

Newest entry on top.

---

## 2026-11-05 — Scheduled nightly run

- lastInspectedCommit: f4b79cd
- Trigger: scheduled nightly run.
- Process note: the concurrency-lock step was missed at the very start of
  this run again (read `lock.json`, confirmed idle, but never wrote the
  `"status":"running"` state before starting work — same gap flagged on
  2026-11-03). No actual collision occurred. Flagging again so the step
  gets built into the habit rather than re-noted each time it's skipped.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  20+ consecutive nights (2026-10-15 through tonight) that stored prompt
  has been wrong. That string was resolved back on 2026-10-12 (PR #1).
  BUGS.md's real Open section tonight holds one entry: the away-match
  weather forecast RPC gap (flagged 2026-11-03, already fully
  root-caused, awaiting Victor's call) — unchanged since. Went with real
  repo state, per every prior run since 10-15. A second `update_trigger`
  attempt to fix the stored prompt was not retried tonight (blocked twice
  already, 11-03 and 11-04, by the same permission classifier) —
  resurfacing for Victor to action directly rather than re-attempting a
  third time.
- Scope: diff since 9414d70 (last run's lastInspectedCommit) was 3
  commits (0fab96a/e176cc7 last night's own report+lock-idle, f4b79cd
  "Create CNAME" — a GitHub Pages custom-domain config, committed outside
  this agent) — none of index.html, css/nexteleven.css, team.html, or
  public-stats-core.js changed.
- Checks run:
  - `check-syntax.js` → OK (all 3 script blocks parse).
  - `check-i18n-parity.js` → OK (2030/2030 keys, no gaps).
  - `check-html-comments.js` → OK (both files balanced, no swallowed tags).
  - `tests/regression_caio_and_cards.js` → 3/3 pass.
  - `tests/regression_marcadores_guests.js` → 3/3 pass.
  - `tests/regression_next_game_weather.js` → 3/3 pass.
  - `tests/regression_season_calendar.js` → 52/52 pass.
- Zero-AI early exit did not fire: app files unchanged and all checks
  green, but BUGS.md still has one `Status: Open` entry (the away-weather
  RPC gap, unchanged) — so triage ran per spec, cheapest path (diff
  summary + check outputs + the one Open entry's text only).
- Triage (haiku): no new P0-P1 candidates. One P2 "verify, low
  confidence" note: `f4b79cd` adds a root CNAME file (`next11.pt`),
  which is deploy-affecting (binds the GitHub Pages site to a custom
  domain) but isn't covered by any deterministic check or regression
  suite.
- Orchestrator follow-through on the CNAME note: the commit message
  ("Create CNAME") is GitHub's own default commit message when a custom
  domain is set via the repo's Pages settings UI — strong evidence this
  was a deliberate action (most likely Victor, directly on GitHub, not
  through any agent session), not an accident. Attempted to confirm DNS
  independently (`dig`, `curl https://next11.pt`) — not possible from
  this sandbox (`dig` not installed, outbound curl to the bare domain
  blocked by the egress proxy, 403). Leaving this as an FYI only, not a
  "Needs approval" item — nothing here looks like a defect, just an
  unverifiable-from-here config change worth Victor's own one-glance
  confirmation that next11.pt resolves correctly.
- Fixed: none (nothing new to fix; 0/2 of cap used).
- Needs your approval: unchanged — away-match weather forecast RPC gap
  (see 2026-11-03 entry) still awaiting your call; no new information
  tonight.
- Pending: none else.
- Known Unresolved housekeeping: none — nothing in tonight's diff touches
  any carried-forward item; list unchanged.

## 2026-11-04 — Scheduled nightly run

- lastInspectedCommit: 9414d70
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again asserted BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3 — actually resolved back on
  2026-10-12, PR #1). This is now the 20+ consecutive night that stored
  prompt has been wrong. Went with real repo state instead, per every
  prior run since 10-15. Attempted `update_trigger` again to correct the
  stored prompt (reworded step 3 to read BUGS.md live instead of
  asserting its contents) — blocked again by the same "Cowork Scheduled
  Task Write" permission classifier as the 2026-11-03 attempt. Left
  undone; flagging for Victor to fix directly or re-authorize.
- Also flagging: this schedule started 2026-10-12 as a stated 7-day trial
  for Victor to review before deciding whether to keep it. It has now run
  nightly for 24 days past that start date with no sign (in this log) that
  the trial review happened. Not acted on — just surfacing it.
- Scope: diff since c20951a (last run's lastInspectedCommit) touched only
  QA/bookkeeping (lock file, run-log/BUGS.md entries from last night's
  wrap-up, tonight's lock-running commit) — none of index.html,
  css/nexteleven.css, team.html, public-stats-core.js changed.
- Checks run:
  - `check-syntax.js` → OK (all 3 script blocks parse).
  - `check-i18n-parity.js` → OK (2030/2030 keys, no gaps).
  - `check-html-comments.js` → OK (both files balanced, no swallowed tags).
  - `tests/regression_caio_and_cards.js` → 6/6 pass.
  - `tests/regression_marcadores_guests.js` → 8/8 pass.
  - `tests/regression_next_game_weather.js` → 11/11 pass.
  - `tests/regression_season_calendar.js` → 52/52 pass.
- Zero-AI early exit did not fire: app files unchanged and all checks
  green, but BUGS.md still has one `Status: Open` entry (the away-weather
  RPC gap, carried from last night, already fully root-caused and awaiting
  Victor's call) — so triage ran per spec.
- Triage (haiku): given the (empty, bookkeeping-only) diff, the check
  outputs, and the existing Open entry's full text, returned no new P0-P1
  candidates. Two minor notes, both resolved without further action: (a)
  suggested confirming the pending migration file matches the live RPC
  before drafting a fix — already the documented reason this item awaits
  an interactive session with DB access, nothing new; (b) flagged commit
  ordering in the diff summary as "odd" — false alarm, it's just newest-
  first `git log` output (tonight's own lock-running commit sorts above
  last night's lock-idle/wrap-up commits, which is correct).
- Fixed: none (nothing new to fix; 0/2 of cap used).
- Needs your approval: unchanged — away-match weather forecast RPC gap
  (see 2026-11-03 entry below and BUGS.md Open section) still awaiting
  your call; no new information tonight.
- Pending: none else.
- Known Unresolved housekeeping: none — nothing in tonight's diff touches
  any carried-forward item; list unchanged.

## 2026-11-03 — Scheduled nightly run

- lastInspectedCommit: c20951a
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again asserted BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3). As of this morning's
  manual correction (see the entry right below this one), BUGS.md's real
  Open section is actually empty — the "Caio Andrade" entry that had been
  Open since 2026-11-01 was moved to Resolved today. Went with real repo
  state (zero Open entries), per every prior run since 10-15.
- Process note: the concurrency-lock step was missed at the very start of
  this run (went straight to reading it, never wrote the `"status":"running"`
  state before starting work). No actual collision occurred — this was the
  only session running — but flagging the process gap so it isn't repeated.
- Scope: diff since 8b64fe0 (last run's lastInspectedCommit) touched
  `index.html` and `team.html` via one real commit (b85561f, "Add automatic
  weather forecast for the next match on the parent page", merged via PR
  #35 in an interactive session today, not by this agent) plus bookkeeping
  commits either side (lock, BUGS.md correction, PR #34 merge). Zero-AI
  early exit did not fire (app files changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (all 3 script blocks parse).
  - `check-i18n-parity.js` → OK (2030/2030 keys, no gaps).
  - `check-html-comments.js` → OK (both files balanced, no swallowed tags).
  - `tests/regression_caio_and_cards.js` → 3/3 pass.
  - `tests/regression_marcadores_guests.js` → 3/3 pass.
  - `tests/regression_next_game_weather.js` → 3/3 pass.
  - `tests/regression_season_calendar.js` → 52/52 pass.
- Triage (haiku): given commit b85561f's full diff (index.html + team.html),
  the deterministic-check outputs, and the (empty) BUGS.md Open section,
  returned 2 candidates: P2 "away-match weather forecast never shows" (it
  independently grepped the repo and confirmed `next.opponentLat`/
  `opponentLng` — read by `renderNextGameWeather` in team.html — are never
  written anywhere; the admin side only ever writes `venueLat`/`venueLng`
  onto the opponent record); P3 "Home Ground coordinates only settable via
  the season Edit form, not any season-creation path" (unverified by
  triage, flagged as possibly expected).
- Orchestrator follow-through:
  - Away-weather field mismatch: **confirmed, real, root-caused further**.
    This isn't just a client-side naming slip — the public page calls the
    Supabase RPC `get_public_team_data` directly (team.html L1603), and
    that RPC's JSON builder (current version: `supabase/migrations_pending/
    009_harden_public_rpc_against_stuck_soft_deletes.sql`) denormalizes
    `opponentMapUrl` from the opponent's `payload->>'mapUrl'` but has no
    equivalent for `venueLat`/`venueLng`. So `next.opponentLat`/`opponentLng`
    are `undefined` for every away game returned by the real production
    RPC, full stop — no client-side fix is possible, the data is never in
    the payload the page receives. Confirmed no other file sets these
    fields (`grep -rn "opponentLat\|opponentLng"` → only the one read site
    in team.html and the test fixtures, which set them directly and so
    never exercise the real gap).
  - Home Ground coords creation-path gap: **confirmed, real**. Grepped
    every `homeGround`-setting call site: `wiz-homeground` (renewal
    wizard), `ftw-club-ground` (First-Time Wizard), and `sf-homeground`
    (manual "no seasons yet" create form) all had no coordinates
    counterpart; only the season Edit form (added in b85561f) did.
- Fixed (1/2 of cap used):
  - Added a matching Home Ground coordinates input to all three
    season-creation paths (renewal wizard, First-Time Wizard, manual
    create), reusing last night's existing i18n keys and validation
    pattern, wired through to `homeGroundLat`/`homeGroundLng` on the
    `seasons` record each path writes. Commit 883b45f on
    `maintenance/nightly-2026-11-03`. Re-ran all 3 deterministic checks +
    all 4 regression suites after the change — still all green. PR:
    https://github.com/Kreativminds/NextEleven/pull/36
- Needs your approval:
  - Away-match weather forecast is completely dead in production (P2,
    confirmed) — see root cause above. Fix requires extending the public
    `get_public_team_data` RPC (a new `supabase/migrations_pending/010...`
    migration, following the exact pattern of `opponentMapUrl` in 009) to
    also return `opponentLat`/`opponentLng` sourced from the opponent's
    `venueLat`/`venueLng`. Not drafted or staged tonight: this is the one
    public RPC every part of team.html depends on, and this agent has no
    live Supabase connection to verify a new version of it against the
    real schema before handing you SQL to run — safer for you or an
    interactive session to draft and check it directly. Home-match weather
    (season `homeGroundLat`/`Lng`, read straight off the `season` object
    already in the RPC payload) is unaffected and works today.
- Pending: none else — both triage candidates were run to ground tonight.
  ~9 min of the ~20 min budget used.
- Known Unresolved housekeeping: none — nothing in tonight's diff touches
  any carried-forward item; list unchanged.

## 2026-11-03 — Correction (manual, interactive session, not the nightly schedule)

- Victor asked to action the two items from the 2026-11-02 report: merge PR #34 and resolve the "Caio Andrade" BUGS.md entry.
- PR #34 merged (squash, commit 49e7f2e) — QA tooling only, no app-code change.
- Before applying staged migration `004_merge_caio_unconverted_guest_goals.sql`, queried production directly as a sanity check. Result: it's already fixed — `temporary_players` row for tempPlayerId=1 shows `deleted_at`=2026-11-01 08:52:22 UTC, `convertedToPlayerId`=134; all game_players/goal_events/card_events rows already re-pointed; playerId 134's season goal total already 11. That timestamp is *before* the 2026-11-01 evening nightly run that first flagged this as "Open, awaiting approval" — so the real fix landed in production that same morning, outside any agent session (most likely Victor, direct in Supabase), and neither BUGS.md nor this log ever got updated to match. Did not run migration 004 (confirmed no-op against current state) — moved the BUGS.md entry straight to Resolved with the corrected timeline instead.
- Root cause of the staleness: the nightly agent's "Open" writeups for this item were built from the migration file + a point-in-time backup JSON, never from a live production query — so two consecutive nightly reports (and this agent's own morning summary to Victor) kept citing a gap that no longer existed. Worth the nightly spec eventually adding "if a BUGS.md entry claims a *data* gap, re-verify against production before re-reporting it, don't just re-cite the file" — not changed tonight, flagging for next time this comes up.
- Also attempted to fix the scheduled task's own prompt (it has hardcoded a stale "BUGS.md has exactly one Open entry" claim for 19+ nights running) via `update_trigger` — blocked by a permission classifier ("Cowork Scheduled Task Write"), so left undone; reported to Victor to action himself or re-authorize.

## 2026-11-02 — Scheduled nightly run

- lastInspectedCommit: 8b64fe0
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt again stated BUGS.md had exactly one
  Open entry (`integ_fix_review`, i18n, P3) — this is now the 19th night
  running (2026-10-15 through tonight) that claim has been stale. That
  string was fixed 2026-10-12 (PR #1) and has been in "Resolved" ever
  since; BUGS.md's real Open section tonight was the "Caio Andrade"
  duplicate-identity entry (flagged last night, 2026-11-01, awaiting
  Victor's approval on the staged migration — unchanged tonight). Went
  with real repo state, per every prior run since 10-15.
- Scope: diff since 42ff6e3 (last run's lastInspectedCommit) touched
  `index.html`, `css/nexteleven.css` and `team.html` via 3 real commits
  (excluding the lock/run-log bookkeeping commits either side) — all made
  in one interactive session today, not by this agent: the application-
  wide dark mode feature (Claro/Escuro/Automático, c645a0e), a same-day
  readability follow-up (08876d9), and a same-day P0 fix (8b64fe0) for a
  malformed anti-FOUC comment (closed with `*/` instead of `-->`) that
  had silently swallowed the `nexteleven.css` `<link>` tag for part of
  the day. Zero-AI early exit did not fire (app files changed), so triage
  ran.
- Checks run:
  - `check-syntax.js` → OK (all 3 script blocks parse).
  - `check-i18n-parity.js` → OK (2025/2025 keys, no gaps).
  - `tests/regression_caio_and_cards.js` → 6/6 pass.
  - `tests/regression_marcadores_guests.js` → 8/8 pass.
  - `tests/regression_season_calendar.js` → 52/52 pass.
  - No dark-mode-specific automated test exists yet.
- Triage (haiku): given the 3 commit messages/diffstats, the deterministic-
  check outputs, and the BUGS.md Open section, returned 4 candidates, none
  P0/P1: P2 `check-syntax.js` doesn't cover HTML-comment well-formedness,
  so it wouldn't have caught tonight's P0 comment bug; P2 "66 regression
  checks claimed vs. only 58 shown passing"; P2 confirm the new theme-
  bootstrap `localStorage` read is wrapped in `try/catch`; P3 Claro
  "pixel-identical" and dark-mode status-chip contrast asserted by
  reasoning, not a screenshot diff.
- Orchestrator follow-through:
  - Test-coverage gap: **real**. Confirmed `check-syntax.js` only regexes
    `<script>` blocks. Wrote and verified a new deterministic check,
    `check-html-comments.js` (balances `<!--`/`-->` counts, flags a
    comment whose body contains a nested `<!--`, and specifically checks
    `nexteleven.css`'s `<link>` isn't swallowed) — confirmed it passes
    clean on current HEAD and correctly flags the real bug when run
    against the pre-fix revision (08876d9).
  - "66 vs 58" test count: **false positive**. My own earlier `tail -3`/
    `tail -5` truncation only showed the last few `PASS` lines per file —
    actual counts are 6 + 8 + 52 = 66, matching the commit's claim exactly.
  - `localStorage` try/catch: **false positive**. Read both bootstrap
    scripts directly (index.html L15-24, team.html L25-34) — both already
    wrap the read in `try/catch` with an `'auto'` fallback.
  - Claro/contrast screenshot verification: not pursued — speculative, no
    concrete defect found, no automated visual test exists for either
    theme. Not added to Known Unresolved as a open risk; just noting no
    action was taken.
- Fixed (1/2 of cap used):
  - Added `.claude/qa/check-html-comments.js` as a third deterministic
    check, wired into this very file (next11-nightly-qa.md) so future
    runs actually invoke it. No app-code file (index.html/css/
    nexteleven.css/team.html/public-stats-core.js) touched — routed
    through the maintenance-branch + PR process anyway out of caution,
    since it changes this agent's own operating spec. Commit 1cc69dd on
    `maintenance/nightly-2026-11-02`. PR:
    https://github.com/Kreativminds/NextEleven/pull/34
- Needs your approval: none new tonight. "Caio Andrade" duplicate-identity
  entry from 2026-11-01 remains open in BUGS.md, unchanged, still awaiting
  your call on migration 004.
- Pending: none (every triage candidate was run to ground tonight; ~8 min
  of the ~20 min budget used).
- Known Unresolved housekeeping: none — nothing in tonight's diff touches
  any carried-forward item; list unchanged.

## 2026-11-01 — Scheduled nightly run

- lastInspectedCommit: 42ff6e3
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 18th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and has been in "Resolved" ever since; BUGS.md's
  real Open section was empty at the start of tonight's run. Went with
  real repo state, per every prior run since 10-15 — flagging again that
  whatever generates the scheduled prompt should stop hardcoding this.
- Scope: diff since a5cc00f (last run's lastInspectedCommit) touched
  `index.html`, `team.html` and `public-stats-core.js` via ~21 real
  commits (excluding merges/version-bumps) — a very large, feature-heavy
  interactive session today (2026-11-01): a brand-new multi-day "Season
  Calendar" feature built across ~15 commits (Folga detection,
  Christmas/Easter break computation, month grouping, boxed tiles on the
  Parents Page, a merge of Próximos Jogos into Calendário da Época, a
  fix-then-deliberate-same-day-revert of a single-day-column date-format
  edge case), guest/temp players folded into Marcadores/Assistências/Mais
  Titularidades (with a new `tempPlayerId` RPC field), full
  goalscorer/assister lists (not just the leader), round/Jornada exposed
  on the public RPC, a classification publish-date/source fix, and a
  production RPC hardening fix for calendar events leaking past a stuck
  `deleted_at`. All made directly to `main` outside this agent, each
  commit citing explicit Victor direction/confirmation or a production
  incident it was responding to. Zero-AI early exit did not fire (app
  code changed across all three files), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (2023/2023 keys, no gaps).
  - `tests/regression_season_calendar.js` (new tonight, directly
    relevant) → 52/52 pass.
  - `tests/regression_marcadores_guests.js` (new tonight, directly
    relevant) → 8/8 pass.
- Triage (haiku): given only the ~21 commit messages, diffstat, check/test
  outputs, and the empty BUGS.md Open section, returned 5 candidates:
  P1 whether the RPC soft-delete hardening and new round field handle
  exclusion/nulls correctly; P1 whether guest inclusion plus the staged
  Caio migration could double-count or create duplicate leaderboard
  entries, and whether the ranked-list changes handle ties; P2 whether
  the multi-day range date logic still has coverage after its fix was
  reverted same day; P2 whether the new Folga/break/Easter date rules
  handle inclusive/exclusive boundaries and timezones consistently; P2
  whether the new `eventId` key registered in `getKey()` could collide
  with another store's id field in the same lookup table.
- Orchestrator follow-through: read the actual migration SQL, commits and
  code for each candidate.
  - RPC hardening / round field: not real as a defect. Read the full
    `009_harden_public_rpc_against_stuck_soft_deletes.sql` — the
    `calendarEvents` subquery now excludes a row on either `deleted_at`
    *or* `payload->>'isDeleted'='true'`, exactly the belt-and-suspenders
    fix the commit describes for a real incident it already fixed in
    prod. `round` is a plain nullable text passthrough; the "omits round
    text entirely when g.round is absent" case is explicitly covered by
    tonight's own regression suite and passes.
  - `getKey()` eventId: not real. It's a per-store-keyed lookup table
    (`keys[store] || 'id'`), not a shared ID namespace — `eventId` for
    `seasonCalendarEvents` can't collide with another store's key. The
    commit itself already discloses the one real follow-up (pre-existing
    records pushed under the old broken key need manual re-add), not
    something this agent found new.
  - Multi-day range revert: confirmed clean. `git diff 249f864 78ff70d --
    team.html tests/regression_season_calendar.js` is empty — the revert
    is a complete, residue-free undo of 2825fbf, back to the exact
    pre-fix state. That's an explicit same-day human decision (merge,
    then deliberately revert), not left half-done; not pursued further.
  - Folga/break/Easter boundaries: not pursued as a new concern — already
    extensively covered by tonight's 52-case regression suite (Easter
    Sunday computed correctly for 3 separate years, break-vs-Folga
    suppression, month grouping, past/future partitioning). No gap found
    beyond what's already tested.
  - **Real, confirmed, not auto-fixable**: guest inclusion (5f8f6ec) is
    working exactly as designed, but it makes a pre-existing, previously-
    invisible data gap user-visible on the live Parents Page right now.
    `temporaryPlayers.tempPlayerId=1` ("Caio Andrade") was only ever
    partially converted to permanent player 134 — 4 `game_players` rows
    (10 goals, games 250-253), 5 `goal_events` and 1 `card_events` row
    are still under the old guest identity (confirmed by reading
    `caio_unconverted_temp_rows_backup_2026-11-01.json` directly — temp
    player name is literally "Caio Andrade"). Guests were excluded from
    public leaderboards before tonight, so this never showed; tonight's
    feature folds every guest into the same ranked lists
    (`renderSeasonLeaders`'s `guestStats`/`pStats`/`withStats` pattern in
    team.html, confirmed by reading the code — no dedup against an
    already-converted player of the same name exists or is intended to).
    Net effect: "Caio Andrade" now shows twice in Marcadores/Assistências
    — once as guest (10 goals) and once as roster player (1 goal). The
    fix is already prepared and dry-run tested as
    `supabase/migrations_pending/004_merge_caio_unconverted_guest_goals.sql`
    (re-points all 10 rows to playerId 134, retires the temp player) —
    this agent never applies production Supabase changes, so this is
    flagged for your approval, not fixed tonight.
- Fixed: none (0/2 of cap used — every real finding was either already a
  settled same-day human decision, already self-disclosed by its own
  commit, or a data/migration issue outside this agent's safety rules).
- Needs your approval: see "Caio Andrade" duplicate-identity entry added
  to BUGS.md tonight — applying the already-staged, already-tested
  migration 004 resolves it.
- Pending: none (every triage candidate was run to ground tonight, not
  deferred for lack of time; ~5 min of the ~20 min budget used).
- Known Unresolved housekeeping: none — nothing in tonight's diff touches
  any carried-forward item; list unchanged.

## 2026-10-31 — Scheduled nightly run

- lastInspectedCommit: a5cc00f
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 17th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and has been in "Resolved" ever since. Went with
  real repo state, per every prior run since 10-15 — flagging again that
  whatever generates the scheduled prompt should stop hardcoding this.
- Scope: diff since e6927fc (last run's lastInspectedCommit) touched
  `index.html` and `team.html` via 3 real commits made directly to main
  outside this agent (each merged via its own fix/* branch, interactive
  sessions, same day):
  - 91971ba "Fix admin sync: a deleted cloud record with no local
    cloudId match was silently dropped forever..." — narrows
    `Sync.pull()`'s deletion-skip guard to only stores that actually do
    natural-key merging (`naturalKeyFields(store)` non-null), so stores
    like `temporaryPlayers` (keyed directly by their own id, no merge
    ambiguity) stop losing legitimate deletions. Read the diff: the
    added condition is exactly the guard the commit message describes —
    correct, no concern.
  - 8754dba "Make the Caio-style stuck-deletion fix self-healing..." —
    adds a one-time, silent, per-device full `Sync.downloadAll()` on next
    load (own appMeta flag, set only after the call succeeds, left unset
    on any error so it simply retries next load), hooked in right after
    the existing `requiresBlockingSyncOnNextLoad` check in
    `continueAppLoadAfterLogin()`. Read the diff: flag timing is correct
    (no "set-then-fail" gap), and the two checks run sequentially, not
    concurrently — no race. Minor, unconfirmed inefficiency noted below
    under Known Unresolved (possible back-to-back full sync on the rare
    account-transition-plus-first-device-load case).
  - 9a25ffb "Fix live-game card: scorer shown on wrong side, no goal
    minute" — factors the finished-match card's two-column,
    minute-labeled scorer rendering into a shared `renderScorerColumns()`
    (in `public-stats-core.js`'s `buildMatchGoalSummary`) and switches
    the live card to use it too. Read `minuteFromScoredAt()`: already
    null-safe for missing `scoredAt`, invalid dates, missing kickoff, and
    implausible minutes (<0 or >150) — all return `null`, and the
    render-side `goalLine()` already guards `minute != null` before
    printing — so no blank/NaN minute is possible, live or finished.
  Zero-AI early exit did not fire (app code changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
- Triage (haiku): given the 3 commit messages, diff stat, check outputs,
  and the empty BUGS.md Open section, flagged 2 P1s and a P2 worth a
  closer look — (1) whether the sync-pull guard removal is actually
  gated per store so natural-key-ambiguous stores keep the old
  protection; (2) whether the one-time resync's appMeta flag could be
  set before completion (losing a failed run) or cause a double full
  sync with the existing blocking-sync flag; (3) whether the live card's
  reused minute computation could show NaN/blank on missing
  scoredAt/kickoff.
- Orchestrator follow-through: read all 3 commits' actual diffs (not
  just messages). All three concerns were already handled correctly in
  the code as shipped — see Scope notes above for each. No false
  positives reached the fix stage; nothing needed fixing.
- Found / Fixed: none (0/2 of cap used — every triage candidate resolved
  itself on inspection; no genuine defect found).
- Needs approval: none.
- Pending: none.
- Known Unresolved housekeeping: adding one new speculative item (below)
  from tonight's reading of 8754dba; nothing else in tonight's diff
  touches an existing carried-forward item.

## 2026-10-30 — Scheduled nightly run

- lastInspectedCommit: e6927fc
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 16th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and is in "Resolved." Went with real repo state,
  per every prior run since 10-15 — flagging again that whatever
  generates the scheduled prompt should stop hardcoding this.
- Scope: diff since f275086 (last run's lastInspectedCommit) touched
  `index.html` and `team.html` via 2 real commits made directly to main
  outside this agent, each an interactive session fix citing explicit
  Victor direction:
  - 4822bf5 "Fix card sync to use card_events everywhere; prepare Caio
    conversion" — rewires `Calc.lorenzoStats`/`Calc.playerSeasonStats` to
    derive yellow/red totals from `cardEvents` via a new
    `getSeasonCardEvents()` helper, fixes a `direct_red`-vs-`'red'` icon
    mismatch in team.html, adds `tests/regression_caio_and_cards.js`, and
    stages (not applies) two Supabase migrations — 001 converts Caio
    Andrade from temp to permanent player, 002 fixes the matching
    `direct_red` mismatch in the `get_public_team_data` RPC. Both dry-run
    tested in a rolled-back transaction against production; both held
    for Victor's explicit approval per `supabase/migrations_pending/README.md`
    — this agent does not apply them (never touches production
    Supabase).
  - 5274830 "Fix Parents Page card pill misaligning player-stats
    columns" — CSS-only + one team.html template change, moves the
    optional card-count pill to its own right-aligned line so it no
    longer shifts the GP/G/A pills. Read the diff: correct, no concern.
  Zero-AI early exit did not fire (BUGS.md's Open section was non-empty
  going in — the carried-over disciplinary-stats entry — and app code
  changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
  - `tests/regression_caio_and_cards.js` (exists from tonight's diff,
    directly relevant) → all 6 checks pass.
- Triage (haiku): given the diff summary, both commit messages, check
  outputs, and the BUGS.md Open entry text, flagged two candidates —
  P1: the BUGS.md Open entry and commit 4822bf5 appear to contradict
  each other (stale-vs-fixed), asked for confirmation that every
  `gp.yellowCards`/`gp.redCards` read actually moved to `card_events`;
  P2 (latent): the `direct_red`-vs-`'red'` RPC mismatch is only
  half-fixed (client-side done, RPC migration not applied) — correctly
  surfaced, already known and already staged by the commit itself.
- Orchestrator follow-through on the P1 candidate: grepped every
  remaining call site of `Calc.playerSeasonStats`/`Calc.lorenzoStats`
  (13 total) and traced each one's actual rendered output, not just
  whether it passes `allCardEvents`. Result: the two call sites that
  genuinely display `.yellow`/`.red` (`trackedPlayer`'s Overview tab,
  `renderPlayerPortalStats`'s Quick Stats) both already pass
  `allCardEvents` in tonight's diff. The other ~9 call sites (Squad
  List/Team Summary leaderboards, Tournament Summary top scorers,
  Dashboard tracked-player cards, Player Card popup Quick Stats, Player
  Portal Team Summary) call these functions without `allCardEvents` too
  — so their returned `.yellow`/`.red` is always 0 — but none of those
  call sites ever render `.yellow`/`.red` in their output (only
  `.calledUp`/`.goals`/`.assists`/`.mom`). So the BUGS.md entry was
  genuinely resolved by 4822bf5, not stale-vs-fixed; the P1 was a false
  alarm once actually traced to the DOM, not a real remaining defect.
  Moved the BUGS.md entry to "Resolved" tonight with this verification
  noted. Not pursued as a "fix" — there is nothing left to fix.
- Found / Fixed: none (0/2 of cap used — nothing needed fixing; tonight's
  work was verifying and closing out an already-landed fix).
- Needs approval: none new. For visibility only (already staged by the
  interactive session, not a new finding): `supabase/migrations_pending/
  001` (Caio conversion) and `002` (direct_red RPC fix) are dry-run
  tested and documented, awaiting Victor's explicit approval to apply —
  see the README there.
- Pending: none.
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-29 — Scheduled nightly run

- lastInspectedCommit: f275086
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 15th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and is in "Resolved." BUGS.md's actual "Open"
  section at the start of tonight's run held one entry: the admin
  disciplinary-stats gap flagged by the 2026-10-26 run, still awaiting
  Victor's decision. Went with real repo state, per every prior run
  since 10-15 — flagging again that whatever generates the scheduled
  prompt should stop hardcoding this.
- Scope: diff since cb757db (last run's lastInspectedCommit) was only 2
  commits (4726884 last night's report, f275086 tonight's lock-acquire),
  both this agent's own bookkeeping — zero touches to `index.html`,
  `css/nexteleven.css`, `team.html`, or `public-stats-core.js`.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
- Zero-AI early exit did NOT fire on its own: BUGS.md's Open section
  was non-empty (the carried-over disciplinary-stats entry), so one
  condition failed mechanically. Spawned the haiku triage subagent with
  only the diff summary, check outputs, and that Open entry's text, per
  the model-strategy split — this is the cheapest path when that one
  condition is the only thing blocking the exit. Result: "none" — no
  new app-code diff to look at, and it agreed the existing Open entry
  was already fully traced on 2026-10-26 and needs Victor's decision,
  not re-triage.
- Found / Fixed: none.
- Needs approval: none new — the disciplinary-stats entry from
  2026-10-26 stands unchanged in BUGS.md, still awaiting Victor's call.
- Pending: none.
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-28 — Scheduled nightly run

- lastInspectedCommit: cb757db
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 14th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and is in "Resolved." BUGS.md's actual "Open"
  section at the start of tonight's run held one entry: the admin
  disciplinary-stats gap flagged by the 2026-10-26 run, still awaiting
  Victor's decision. Went with real repo state, per every prior run
  since 10-15 — flagging again that whatever generates the scheduled
  prompt should stop hardcoding this.
- Scope: diff since 99d3750 (last run's lastInspectedCommit) was only 2
  commits (2a95274 last night's report, cb757db tonight's lock-acquire),
  both this agent's own bookkeeping — zero touches to `index.html`,
  `css/nexteleven.css`, `team.html`, or `public-stats-core.js`.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
- Zero-AI early exit did NOT fire on its own: BUGS.md's Open section
  was non-empty (the carried-over disciplinary-stats entry), so one
  condition failed mechanically. Spawned the haiku triage subagent with
  only the diff summary, check outputs, and that Open entry's text, per
  the model-strategy split — this is the cheapest path when that one
  condition is the only thing blocking the exit. Result: "none" — no
  new app-code diff to look at, and it agreed the existing Open entry
  was already fully traced on 2026-10-26 and needs Victor's decision,
  not re-triage.
- Found / Fixed: none.
- Needs approval: none new — the disciplinary-stats entry from
  2026-10-26 stands unchanged in BUGS.md, still awaiting Victor's call.
- Pending: none.
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-27 — Scheduled nightly run

- lastInspectedCommit: 99d3750
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt again stated BUGS.md had exactly one
  Open entry (`integ_fix_review`, i18n, P3) to process — this is now the
  13th night running (2026-10-15 through tonight) the scheduled prompt
  has hardcoded this same stale claim. That EN string was fixed
  2026-10-12 via PR #1 and is in "Resolved." BUGS.md's actual "Open"
  section at the start of tonight's run held one entry: the admin
  disciplinary-stats gap flagged by last night's (2026-10-26) run,
  awaiting Victor's decision. Went with real repo state, per every
  prior run since 10-15 — flagging again that whatever generates the
  scheduled prompt should stop hardcoding this.
- Scope: diff since f15dbc1 (last run's lastInspectedCommit) was only 2
  commits (23aed98 lock-acquire, d97fcdf report/bookkeeping), both this
  agent's own from last night — zero touches to `index.html`,
  `css/nexteleven.css`, `team.html`, or `public-stats-core.js`.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
- Zero-AI early exit did NOT fire on its own: BUGS.md's Open section
  was non-empty (the carried-over disciplinary-stats entry), so one
  condition failed mechanically. Spawned the haiku triage subagent with
  only the diff summary, check outputs, and that Open entry's text, per
  the model-strategy split — this is the cheapest path when that one
  condition is the only thing blocking the exit. Result: "none" — no
  new app-code diff to look at, and it agreed the existing Open entry
  was already fully traced last night and needs Victor's decision, not
  re-triage.
- Found / Fixed: none.
- Needs approval: none new — the disciplinary-stats entry from
  2026-10-26 stands unchanged in BUGS.md, still awaiting Victor's call.
- Pending: none.
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

## 2026-10-26 — Scheduled nightly run

- lastInspectedCommit: f15dbc1
- Trigger: scheduled nightly run.
- Note: tonight's scheduled prompt once again stated BUGS.md had exactly
  one Open entry (`integ_fix_review`, i18n, P3) to process — this is now
  the 12th night running (2026-10-15 through tonight) the scheduled
  prompt has hardcoded this same stale claim. Confirmed again: that EN
  string has been present since 2026-10-12 (PR #1) and BUGS.md's real
  "Open" section was empty at the start of tonight's run. Went with
  actual repo state, per every prior run since 10-15 — flagging again
  that whatever generates the scheduled prompt should stop hardcoding
  this.
- Scope: diff since 428ddef (last run's lastInspectedCommit) touched
  `index.html`, `team.html` and `public-stats-core.js` via 16 commits —
  a large, feature-heavy interactive session today: swipe navigation
  between Parents Page tabs (6261c0e), win%/clean-sheets/best-streak
  stats + W/D/L percentage bars on a renamed "Facts" tab (a3c0b8a,
  aff42e9, 4c374ea), a Parents Page carousel/classification rework
  (b2ab029, 9b817fb, 8813608, 8f42f1b, 84910b0, f3c4343 — League
  Standings surfaced, natural-height slides, "League Leader Spotlight"
  redesign, dynamic game-relative lead slide, result-slide expiry), and
  a full yellow/red card disciplinary-tracking feature spanning all
  three files (4c8320e/80ca284, admin Cards tab + Supabase `card_events`
  table + public Parents Page card strip) plus its own season-totals
  rollup on the Facts tab (601a135). All made directly to `main` outside
  this agent, each commit citing explicit "Victor" direction/confirmation.
  Zero-AI early exit did not fire (app code changed), so triage ran.
- Checks run:
  - `check-syntax.js` → OK (both script blocks parse).
  - `check-i18n-parity.js` → OK (1972/1972 keys, no gaps).
- Triage (haiku): given only the 16 commit messages (minus version-bump
  commits) + diffstat + check results + empty BUGS.md Open section,
  returned 10 "worth checking" candidates, P1 down to P3 — correctly
  framed as unconfirmed since it saw no code. Orchestrator read the
  actual diffs/code for each before acting:
  - **Confirmed real, P1 (flagged to BUGS.md, not fixed — see below).**
  - Carousel `min-height:118px` possibly related to 9b817fb ("let each
    slide use its natural height"): not real — that's a *different*
    carousel (index.html's admin "next game" Home card, from 226b5d3 on
    2026-10-15, untouched by tonight's diff). 9b817fb touches only
    team.html's separate Parents Page pinned carousel. The two share a
    name, not any code. 2026-10-15's Known Unresolved note stands
    unchanged.
  - Swipe-between-tabs (6261c0e) vs. the pinned carousel's own swipe
    (`applyCarousel`) double-firing on the same gesture (both use plain
    `ontouchstart`/`ontouchend`, neither calls `stopPropagation`): looked
    like a real bubbling conflict at first read, but checked the actual
    DOM structure in `render()` — `#pinnedCarousel` is rendered as a
    sibling *above* `<nav class="tabs">`, not nested inside any `.pane`
    element that `applyTabs`'s swipe handler attaches to. Not an ancestor
    relationship, so the touch event never reaches the pane handler from
    the carousel. Not real.
  - W/D/L percentage bars (601a135/aff42e9) division-by-zero: checked
    `renderPctBarRow` — already guards `total > 0 ? ... : 0`. Not real.
  - "Facts" tab rename (4c374ea) stale references: internal tab `id`
    deliberately stays `'team'` (URL hash, pane `data-tab`), only the
    i18n label (`tab_team`) changed to "Facts"/"Factos" in both EN/PT.
    Cosmetic-only split, not a bug.
  - Result-slide expiry (f3c4343) day/timezone boundaries: read the
    actual window logic (`daysSinceLastResult`, local-date based, same
    window driving both lead-slide and existence) plus the commit's own
    stated verification (day-of/day-after/2-days/week-later scenarios).
    Sound, Victor-confirmed design. Not pursued.
  - cardEvents IndexedDB/Supabase schema wiring (schema v22, sync-stores
    set, Supabase table map, required-stores list): spot-checked all 4
    registration points claimed in the commit message — all present.
    No defect found.
  - League Standings/Spotlight ties (b2ab029/8813608/8f42f1b): code
    already explicit that position/ranking is taken verbatim from the
    data's own row order, never recomputed — "ties are the data source's
    call, not ours" per its own comment. Not pursued.
  - **Real but not a fix candidate tonight** (shared-logic risk —
    described fully below and in BUGS.md): the new card-tracking feature
    writes disciplinary totals exclusively to the new `cardEvents` store;
    the admin app's own `Calc.playerSeasonStats`/`Calc.lorenzoStats` (used
    by the player profile, Squad List YC/RC sort+columns, tournament
    stats — ~10 call sites) still read the old manual
    `gp.yellowCards`/`gp.redCards` fields, which nothing writes anymore
    outside the seed/demo generator. Confirmed by tracing every write
    site for both field pairs. Net effect: from tonight on, any card
    logged via the new Cards tab shows correctly on the public Parents
    Page (which the public-stats-core.js comment explicitly says is
    event-sourced now) but as 0 everywhere in the admin app's own
    season/profile/tournament views — a real, visible stats mismatch
    between the two apps. Not fixed: `playerSeasonStats`/`lorenzoStats`
    are synchronous helpers that don't currently take `cardEvents` as an
    input, so wiring them to the event-sourced totals touches shared
    logic across ~10 call sites — exactly the "shared by several
    features, can't confirm safe unattended" case this agent's safety
    rules say to flag rather than touch.
- Fixed: none (0/2 of cap used — the one confirmed issue is a
  shared-logic case per the safety rules above, not an unattended-safe
  fix; everything else triaged did not hold up as real).
- Needs approval: see "Admin season disciplinary stats no longer update
  once a card is logged via the new Cards tab" — added to BUGS.md Open
  tonight with two suggested fix directions for Victor's call.
- Pending: none (every triage candidate was run to ground tonight, not
  deferred for lack of time; ~8 min of the ~20 min budget used).
- Known Unresolved housekeeping: none — nothing in tonight's diff
  touches any carried-forward item; list unchanged.

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

- Possible back-to-back full sync on the rare account-transition-plus-
  first-load case (from tonight's 2026-10-31 reading of 8754dba): when
  `requiresBlockingSyncOnNextLoad` is true (set only right before a
  genuine account-transition reload) AND this device's one-time
  `syncDeletionBackfillId` flag hasn't been set yet, `init()` now runs
  `performBlockingStartupSync()` and then immediately
  `runSyncDeletionBackfillIfNeeded()` right after it — both full,
  lastSync-ignoring downloads, run sequentially (no race), but back to
  back on that one specific first load. Silent, not user-visible beyond
  extra load time/network use, and self-corrects after that single
  occurrence per device (the backfill flag is then set for good). Not
  confirmed as actually slow/noticeable in practice — worth a look only
  if an account-transition load is ever reported as unusually slow.

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
