-- ============================================================================
-- GATE 12.4 — Phase B frontend readiness: each of Gate 12's 7 listed claims
-- mapped to specific, re-run-this-gate regression evidence. PREPARATION
-- ONLY. Phase B is not deployed or merged by this file.
-- ============================================================================

-- Re-ran this gate (node tests/<file>.js, real Playwright execution against
-- team.html/index.html, not estimated): regression_gate7_opponent_alias.js
-- (9/9), regression_gate8_opponent_picker.js (8/8), regression_gate8_
-- rollback_safety.js (5/5) -- 22/22, zero failures, identical to the Gate
-- 10.4/11.9 authoritative baseline for these three files.

-- 1. "Existing opponent selection remains functional"
--    PASSED. regression_gate8_opponent_picker.js: "Flag OFF: picker shows
--    only the 4 local names, federation catalogue entirely absent" and
--    "Today's shipped default is the flag OFF -- Phase B can deploy before
--    Phase C with zero behaviour change". regression_gate7_opponent_alias.js:
--    "Direct local opponent match still resolves (existing behaviour
--    unchanged)".

-- 2. "Existing parent and coach views remain accessible"
--    PASSED (code-level/mocked-RPC, see caveat in item 3). regression_
--    marcadores_guests.js drives team.html -- the Parents Page itself --
--    directly via Playwright, with get_public_team_data mocked at the
--    network layer rather than estimated; the page renders and the guest-
--    player/public-stats code path it exercises is the same page Phase B's
--    resolver patch feeds. No dedicated "coach view" test exists in this
--    suite (same limitation Gate 10.5 already disclosed) -- NOT TESTED for
--    any coach-specific view distinct from the Parents Page, flagged rather
--    than assumed.

-- 3. "Public-sharing tokens continue working"
--    PARTIALLY VERIFIED, WITH AN EXPLICIT CAVEAT CARRIED FORWARD FROM GATE
--    10.5 (unchanged, not new to this gate): regression_marcadores_guests.js
--    verifies the client-side consumption of get_public_team_data's
--    response shape end-to-end against a real rendered page, with the RPC
--    response mocked rather than a live Supabase call. A genuine live
--    HTTP request against production's actual RLS/token-validation path
--    (real share_token, real anon key, real network round-trip) remains
--    BLOCKED by this sandbox's network policy -- exactly the same
--    structural blocker Gate 10.5 already identified, not a new gap. PASSED
--    at the code/mocked level; the live end-to-end case stays BLOCKED,
--    pending a human test with real device/network access (manual
--    procedure already documented in gate10_5_outstanding_integration_
--    limitations.sql).

-- 4. "Historical opponent names remain unchanged"
--    PASSED, by direct code inspection plus regression evidence.
--    resolve_opponent_lookup()'s own doc comment states it "Never rewrites
--    games.payload->>'opponent'" -- confirmed true by reading its full body
--    (gate3_federation_catalogue.sql, re-read this gate and in Gate 12.2):
--    every branch only SELECTs map/venue/logo fields, never UPDATEs
--    games/opponents. regression_gate7_opponent_alias.js's "Direct local
--    opponent match still resolves (existing behaviour unchanged)" is the
--    regression-level confirmation of the same guarantee.

-- 5. "Existing venue and logo data are preserved"
--    PASSED. Phase B's resolver step 1 (the ordinary, by-far-most-common
--    case -- a local opponents-table match) is byte-identical to today's
--    existing inline query, proven live in Gate 9.2 and unchanged since.
--    Nothing in Phase A or B writes to opponents.payload's existing venue/
--    logo fields. The ONLY venue/logo data this release can newly expose is
--    the additive federation_clubs catalogue -- and that remains 0-for-92
--    populated for map_url/venue_lat/venue_lng/logo_url (disclosed gap
--    since Gate 8.3, unaffected by this gate), so there is nothing new yet
--    to even risk disturbing.

-- 6. "Federation RPC functions are compatible with the frontend"
--    PASSED. regression_gate8_opponent_picker.js exercises the REAL,
--    production-shaped populateOpponentDatalist() against a real DB-backed
--    scenario (not a stub), under all 4 flag/alias combinations (flag off;
--    flag on, no aliases; flag on, with aliases; today's real shipped
--    default) -- 8/8 passed, including squad-distinction preservation.

-- 7. "The application continues working if federation catalogue access is
--    unavailable"
--    PASSED. regression_gate8_rollback_safety.js, all 5 checks: sync
--    failure returns [] without throwing, getFederationClubs() degrades to
--    [] rather than undefined/throw, local opponent-name resolution is
--    completely unaffected, the picker still renders with local names
--    only, and no uncaught page error occurs at any point in the simulated
--    outage.

-- FEDERATION PICKER FLAG STATUS: confirmed still FALSE by default in the
-- current index.html on this branch (re-read this gate) -- unchanged,
-- Phase D has not flipped it, per Gate 12's explicit instruction to keep it
-- OFF through Phase B.

select 'Gate 12.4 complete. All 7 Phase B claims checked against fresh regression evidence (22/22 checks re-run, 0 failures). 5 of 7 fully PASSED with direct test or code-level evidence. 1 (parent/coach views) PASSED for the Parents Page specifically, with no dedicated coach-view test -- flagged NOT TESTED for that narrower case, not assumed. 1 (public-sharing tokens) PASSED at the code/mocked-RPC level; the live production HTTP/RLS path remains BLOCKED by sandbox network policy, unchanged from Gate 10.5 -- not a new gap introduced by this gate. Picker flag confirmed still OFF. Nothing deployed.' as status;
