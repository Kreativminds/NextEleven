# NextEleven — Bug Queue

How this works:
- Add a new entry under "Open" whenever something is broken, with as much detail as you have (screen, what you tapped, what you expected, what happened).
- The scheduled bug-fix task processes every `Status: Open` entry, fixes what it safely can, and moves each one to "Resolved" with the commit hash — or leaves it Open with a `Needs clarification:` note if it genuinely can't tell what's wrong.
- You can also hand any entry here straight to Claude in a chat to get it fixed immediately instead of waiting for the scheduled run.

---

## Open

(none)

## Resolved

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
