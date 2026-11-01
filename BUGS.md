# NextEleven — Bug Queue

How this works:
- Add a new entry under "Open" whenever something is broken, with as much detail as you have (screen, what you tapped, what you expected, what happened).
- The scheduled bug-fix task processes every `Status: Open` entry, fixes what it safely can, and moves each one to "Resolved" with the commit hash — or leaves it Open with a `Needs clarification:` note if it genuinely can't tell what's wrong.
- You can also hand any entry here straight to Claude in a chat to get it fixed immediately instead of waiting for the scheduled run.

---

## Open

### "Caio Andrade" appears twice in Marcadores/Assistências on the Parents Page — once as roster player, once as unconverted guest
- Reported: 2026-11-01 (found by the nightly QA run, not by Victor)
- Status: Open — flagged, not fixed (data/migration issue, not a code bug; this agent never touches production Supabase data)
- What's happening: tonight's new "include guest/temp players in Marcadores" feature (commit 5f8f6ec) correctly folds every guest's stats into the public leaderboards. But `temporaryPlayers.tempPlayerId=1` ("Caio Andrade") was only ever partially converted to permanent player 134 back in migration 001 — 4 historical `game_players` rows (games 250/251/252/253, 10 goals total), 5 `goal_events` and 1 `card_events` row are still sitting under the old guest identity, and the temp player record itself was never retired. That gap was invisible before tonight because guests were excluded from the public leaderboards; now that they're included, both identities show up side by side: "Caio Andrade" the guest (10 goals) and "Caio Andrade" the roster player (1 goal, 2026-10-31) — same name, two separate entries.
- Fix already prepared and dry-run tested, awaiting your approval: `supabase/migrations_pending/004_merge_caio_unconverted_guest_goals.sql` re-points all 10 rows to playerId 134 and retires the temp player. Backup of every affected row: `supabase/migrations_pending/caio_unconverted_temp_rows_backup_2026-11-01.json`. Applying it resolves the duplicate and brings Caio's season total to the correct 11 goals.
- Note: `supabase/migrations_pending/README.md` only documents migrations 001/002 — it's now 7 migrations behind (003-009 undocumented there). Worth a tidy-up pass when convenient; not urgent.

## Resolved

### Admin season disciplinary stats (yellow/red cards) no longer update once a card is logged via the new Cards tab
- Reported: 2026-10-26 (found by the nightly QA run, not by Victor)
- Status: Fixed (commit 4822bf5, PR https://github.com/Kreativminds/NextEleven/pull/6 — interactive session, not this agent)
- Fix: `Calc.lorenzoStats`/`Calc.playerSeasonStats` now take a season's `cardEvents` and derive yellow/red totals from it via a new `getSeasonCardEvents()` helper, replacing the stale `gp.yellowCards`/`gp.redCards` reads, exactly option (a) suggested below. Same commit also fixed a separate latent `direct_red` vs `'red'` string mismatch in `team.html`'s card icon (the matching Supabase RPC fix is staged in `supabase/migrations_pending/002`, not yet applied — see tonight's run-log).
- Verified 2026-10-30 (this agent, as part of the nightly sweep): every call site where `playerSeasonStats`/`lorenzoStats`'s `yellow`/`red` fields are actually rendered (`trackedPlayer`'s Overview tab and `renderPlayerPortalStats`'s Quick Stats) now passes `allCardEvents`. ~9 other call sites (Squad List/Team Summary leaderboards, Tournament Summary top scorers, Dashboard tracked-player cards, Player Card popup Quick Stats, Player Portal Team Summary) still call these functions without `allCardEvents`, but none of those call sites ever display `.yellow`/`.red` — they only use `.calledUp`/`.goals`/`.assists`/`.mom` — so the gap is inert, not a visible defect. `tests/regression_caio_and_cards.js` (added in the same commit) passes.

### "Game Starting Now" kickoff time saved on the wrong calendar day in some timezones
- Reported: 2026-10-17 (found by the nightly QA run, not by Victor)
- Status: Fixed (commit 68c56c3, PR https://github.com/Kreativminds/NextEleven/pull/4)
- Fix: the new editable-kickoff dialog (`openKickoffTimeDialog`/
  `confirmKickoffTime`, added earlier the same day) took its calendar
  date from `toISOString().slice(0,10)` (UTC date) while the hour/minute
  shown and applied were local. In a timezone where local and UTC fall
  on different calendar days at the moment of the tap (Brazil evenings,
  UTC-3; Portugal just after midnight in summer, UTC+1), the saved
  kickoff time got the right hour/minute but the wrong day. Now builds
  the date from local getFullYear/getMonth/getDate via the existing
  `dISO()` helper, in both the dialog-open path and the confirm-time
  fallback.

### Kick-off time could be clipped on the Home carousel card
- Reported: 2026-10-15 (found by the nightly QA run, not by Victor)
- Status: Fixed (commit fe43e0b, PR https://github.com/Kreativminds/NextEleven/pull/3)
- Fix: the carousel-height fix from the night before (226b5d3) made the
  round/date/kick-off line single-line + ellipsis along with the
  opponent/venue lines. That line's trailing text is the match kick-off
  time, which could get silently clipped on a narrow screen with a round
  label set and the Arrive By box shown. Removed the truncation from
  that line only — it can wrap to a 2nd line in the rare case it's too
  long, rather than hiding the kick-off time. Opponent/venue lines keep
  their single-line truncation (that's what actually fixed the original
  height-variance bug).

### Truncated opponent/venue text unreadable on the Home carousel card
- Reported: 2026-10-15 (found by the nightly QA run, not by Victor)
- Status: Fixed (commit 80c54bc, PR https://github.com/Kreativminds/NextEleven/pull/3)
- Fix: added a `title=` attribute with the full text to the opponent
  name and venue line (both single-line/ellipsis-truncated since
  226b5d3), matching the app's existing pattern of pairing
  truncated/abbreviated text with a full-text `title=`.

### Blue accent strip not visible on most cards/tables (only showed on plain `.card`)
- Reported: 2026-10-14 (found by the nightly QA run, not by Victor)
- Status: Fixed (commit ba4037e, PR https://github.com/Kreativminds/NextEleven/pull/2)
- Fix: the blue left-accent rule added the same night (commit 1745e3f) was
  defined before 7 of its 8 target selectors' own base rules, which reset
  `border-left` back to gray at the same specificity later in the file.
  Moved the accent rule to the end of the stylesheet so it wins the
  cascade for all 8 selectors (`.card`, `.stat-card`, `.table-wrap`,
  `.timeline-item`, `.form-panel`, `.goal-row`, `.game-header`,
  `.game-detail-table-wrap`). No selectors or colors changed.

### Missing English translation for "possible duplicate game" review note
- Reported: 2026-10-12 (found by the nightly QA dry run, not by Victor)
- Status: Fixed (commit 2752e9c, PR https://github.com/Kreativminds/NextEleven/pull/1)
- Fix: added the missing `integ_fix_review` EN string, matching the
  existing PT text: "{n} similar games — NOT merged. Check whether
  they are really the same game."

<!-- Example format once entries start moving here:
### Captain button does nothing when tapped
- Reported: 2026-10-11
- Status: Fixed (commit b0b4c15)
- Fix: added Toast confirmation + debug logging; enlarged/redesigned the button.
-->
