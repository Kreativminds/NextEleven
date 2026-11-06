# Weather feature release review, 2026-11-06

## Source-verified findings

Read the full GitHub patch of PR #35 and PR #36, not the large `index.html` content response (which was empty in this connector).

PR #35's head is an ancestor of `main` (ahead 0, behind 8). Its patch implements the opponent edit form field `opp-coords`, populates it with `formatCoordsPair(o.venueLat,o.venueLng)`, validates with `parseCoordsInput`, and saves `venueLat`/`venueLng` into the opponent data object via `saveOpponentFromForm`. The parser accepts optional blank coordinates and bounds latitude [-90,90], longitude [-180,180]. It also adds home-ground editing and the Parents Page weather widget with regression tests.

PR #36 is not included in main (ahead 1, behind 7, only `index.html` +24 lines). Its patch extends **three season creation paths** with home-ground coordinate entry and validation: renewal wizard (`wiz-homeground-coords`), first-time wizard (`ftw-club-ground-coords`), and manual create (`sf-homeground-coords`). It uses the existing `formatCoordsPair`/`parseCoordsInput` helpers and persists `homeGroundLat`/`homeGroundLng` to the draft or new season payload. This is a consistency enhancement, not the missing opponent coordinates fix.

Production RPC contains both opponent coordinate keys, but none of the 160 active opponent records currently has `venueLat`/`venueLng`. The empty production values are consistent with the field being newly introduced and optional. **Do not treat zero populated records as evidence that save/sync is broken**. Need an isolated end-to-end create/edit/sync/reload test before declaring persistence proven.

## Release actions

1. Verify PR #36 patch against current main after rebase or conflict check, run syntax/i18n and season creation regression tests on the exact combined code.
2. Test an opponent with sample coordinates in isolated Supabase: save, sync, reload, public RPC JSON, away weather display. Test clearing coordinates, invalid input and missing opponent.
3. Confirm public page link privacy and weather API failure behavior.
4. Ask for explicit merge/deploy approval once tests are green. Do not make a redundant production RPC change.

No production write or deployment performed.
