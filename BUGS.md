# NextEleven — Bug Queue

How this works:
- Add a new entry under "Open" whenever something is broken, with as much detail as you have (screen, what you tapped, what you expected, what happened).
- The scheduled bug-fix task processes every `Status: Open` entry, fixes what it safely can, and moves each one to "Resolved" with the commit hash — or leaves it Open with a `Needs clarification:` note if it genuinely can't tell what's wrong.
- You can also hand any entry here straight to Claude in a chat to get it fixed immediately instead of waiting for the scheduled run.

---

## Open

(none)

## Resolved

### "Caio Andrade" appears twice in Marcadores/Assistências on the Parents Page — once as roster player, once as unconverted guest
- Reported: 2026-11-01 (found by the nightly QA run, not by Victor)
- Status: Fixed in production — but not by the staged migration below, and not by this agent. Verified 2026-11-03 by querying production directly: `temporary_players` row for `tempPlayerId=1` ("Caio Andrade") already shows `deleted_at`/`isDeleted`/`convertedToPlayerId=134` set, timestamped **2026-11-01 08:52:22 UTC** — hours before that evening's nightly run even flagged this as "Open, awaiting approval." All 4 `game_players` rows, 5 `goal_events` and 1 `card_events` row are already re-pointed to playerId 134; `playerId=134`'s season goal total is already the correct 11. Someone (most likely Victor, outside any agent session) applied the real fix directly to Supabase the same morning the gap was found — this file and two consecutive nightly reports (2026-11-01, 2026-11-02) just never got updated to reflect that, and kept re-describing an already-closed issue as open.
- The staged migration, `supabase/migrations_pending/004_merge_caio_unconverted_guest_goals.sql`, was never actually run — it's now a no-op (its WHERE clauses match 0 rows against current production state) and is left in place only as documentation of what was done. Backup of the pre-fix rows: `supabase/migrations_pending/caio_unconverted_temp_rows_backup_2026-11-01.json`.
- Lesson for future runs: this agent's "Open" write-up was based on reading the migration file and the backup JSON (both static, point-in-time), never on re-querying live production — so it couldn't detect that the underlying data had already changed. Worth remembering that a BUGS.md entry describing a *data* gap (as opposed to a code gap) can go stale the moment someone fixes the data directly, with no commit to signal it.
- Note: `supabase/migrations_pending/README.md` only documents migrations 001/002 — it's now 7 migrations behind (003-009 undocumented there). Worth a tidy-up pass when convenient; not urgent.

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
