-- ============================================================================
-- GATE 12.6 — Phase D activation checklist. PREPARED, NOT ACTIVATED. The
-- federation picker flag (FEDERATION_CATALOGUE_PICKER_ENABLED) stays false
-- until Phases A/B/C are live/verified AND every item below passes.
-- ============================================================================

-- Prerequisite gate (per Gate 12 section 6, unchanged): Phase A deployed +
-- verified, Phase B deployed + stable, Phase C aliases applied + validated,
-- THEN this checklist, THEN explicit approval to flip the flag.

-- 1. OPPONENT SELECTION
--    Automated coverage: regression_gate8_opponent_picker.js (8/8, re-run
--    this gate) -- duplicate suppression with verified aliases, squad
--    distinctions preserved, unrelated new clubs unaffected.
--    Manual acceptance: pick an opponent from a REAL device, flag on, real
--    production data -- confirm the datalist shows local + federation
--    entries with no visible duplicates for Olivais/Benfica.

-- 2. MATCH CREATION AND EDITING
--    Automated coverage: NONE in this suite (same gap disclosed since Gate
--    10.5/11.9 -- not new to this gate). NOT TESTED.
--    Manual acceptance REQUIRED: create a new match against a federation-
--    only opponent (no local row, no alias yet); edit an existing match's
--    opponent field; confirm no error, no data loss, no change to any
--    other match.

-- 3. A/B/C SQUAD SELECTION
--    Automated coverage: PARTIAL. regression_gate8_opponent_picker.js
--    covers squad A and squad B (Olivais "A" / Olivais "B") only -- no "C"
--    squad case exists anywhere in the current regression fixtures.
--    Manual acceptance REQUIRED, specifically: a club with an actual C-
--    squad registration (if one exists in the real 2026/27 data) must be
--    checked by hand -- this is a genuine gap, not assumed covered by
--    analogy to A/B.

-- 4. VENUE SELECTION
--    Automated coverage: NONE (no live UI path reads federation_club_venues
--    yet -- disclosed since Gate 10/11, unaffected by the venue-dedup fix
--    itself, which only touched migration SQL). NOT TESTED.
--    Manual acceptance REQUIRED once any venue-selection UI exists; until
--    then this item has no user-visible behaviour to break, since nothing
--    in the live app reads federation_club_venues today.

-- 5. PARENT SHARING
--    Automated coverage: regression_marcadores_guests.js (Parents Page,
--    get_public_team_data response shape, mocked RPC).
--    Manual acceptance REQUIRED: a real parent-facing share link, opened by
--    an actual unauthenticated browser session, confirming opponent name/
--    venue/logo render correctly for a federation-resolved opponent --
--    this is the live-HTTP case Gate 10.5 flagged as BLOCKED by sandbox
--    network policy, still BLOCKED, still needs a human with real device/
--    network access.

-- 6. PUBLIC MATCH INFORMATION
--    Same BLOCKED status and same manual procedure as item 5 -- these are
--    the same underlying RPC path (get_public_team_data_opponent_slice).

-- 7. OFFLINE-TO-ONLINE SYNCHRONIZATION
--    Automated coverage: regression_gate8_rollback_safety.js (5/5) covers
--    the catalogue-unavailable case (offline-like degradation), not a full
--    offline-write-then-sync round trip.
--    Manual acceptance REQUIRED: same BLOCKED item carried from Gate 10.5
--    (needs real device/network access) -- not newly introduced by Phase D.

-- 8. MULTI-DEVICE SYNCHRONIZATION
--    Same BLOCKED status, same carried-forward manual procedure from Gate
--    10.5 -- requires two real devices, out of reach of this sandbox.

-- SUMMARY: 3 of 8 items (opponent selection, parent sharing's code-level
-- path, offline degradation's code-level path) have real automated
-- regression coverage re-confirmed this gate. 5 of 8 require a human with
-- real device/network access before Phase D can be considered fully
-- verified -- 4 of those 5 are the SAME pre-existing structural blocker
-- (sandbox network policy) already disclosed since Gate 10.5, not new
-- gaps this gate introduced. The C-squad case (item 3) is a genuinely new,
-- previously-undisclosed gap, worth Victor's attention specifically.

select 'Gate 12.6 complete. Phase D activation checklist prepared across all 8 required areas, each marked with its real automated-test status and exactly what manual acceptance remains. Federation picker flag confirmed still OFF. Not activated.' as status;
