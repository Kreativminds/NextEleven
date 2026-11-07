-- ============================================================================
-- GATE 13.6-13.8 — Phase B/C/D readiness, reconfirmed. Concise by design --
-- full detail is in gate12_4/12_5/12_6; this file states only what's new
-- or re-verified this gate, per Victor's instruction not to repeat.
-- ============================================================================

-- PHASE B -- reconfirmed, nothing changed since Gate 12.4:
--   - FEDERATION_CATALOGUE_PICKER_ENABLED = false, confirmed still the
--     literal value in index.html this gate (line 5915).
--   - Existing opponent selection, public-sharing, historical data
--     preservation, and catalogue-unavailable fallback: all re-proven by
--     this gate's full regression run (107/8/0, see gate13_3) -- the same
--     22+ checks from Gate 12.4 that covered these claims are included in
--     that 107 and still pass byte-identical.
--   - Not deployed, not merged.

-- PHASE C -- reconfirmed, nothing changed since Gate 12.5:
--   - The 5 verified alias rows (migrations/gate8_phase_c_PRODUCTION_
--     verified_opponent_aliases.sql) remain prepared, NOT inserted into
--     production. Re-confirmed by inspection this gate: still a single
--     INSERT statement, still guarded by its NOT EXISTS idempotency check,
--     still excludes "Olivais Sul" and the ambiguous historical "Benfica"
--     row, still preserves Olivais A/B squad distinction and SL Olivais
--     2014's birth-year identity, still keeps Benfica SAD (afl_club_id
--     1023) and Futebol Benfica (afl_club_id 328) as two distinct
--     canonicalOfficialName/aflClubId pairs.
--   - Not executed. No existing opponent row renamed, merged, or deleted.

-- PHASE D -- reconfirmed, nothing changed since Gate 12.6, except the gap
-- Gate 12 surfaced is now CLOSED:
--   - Picker remains disabled (same flag check as Phase B above).
--   - The C-squad manual-test gap Gate 12.6 flagged is now resolved by
--     real automated coverage (gate13_3/regression_gate13_csquad_opponent_
--     picker.js) -- A/B/C squad selection no longer needs a manual-only
--     check; it has the same automated-regression status as A/B did
--     before this gate.
--   - Final manual acceptance checklist (8 items, unchanged from Gate
--     12.6's structure, restated here per Victor's explicit ask this gate):
--     [ ] Match creation and editing          -- NOT TESTED (no dedicated regression; unchanged gap)
--     [ ] A/B/C squad selection                -- now has automated coverage (gate13_3); manual spot-check still recommended before activation
--     [ ] Venue selection                      -- NOT TESTED (no live UI path yet reads federation_club_venues)
--     [ ] Parent and coach pages                -- Parents Page has automated/mocked-RPC coverage (regression_marcadores_guests.js); no dedicated coach-view test exists
--     [ ] Public sharing                        -- code-level PASSED; live HTTP/RLS path remains BLOCKED (sandbox network policy, pre-existing)
--     [ ] Offline synchronization                -- code-level degradation PASSED (regression_gate8_rollback_safety.js); full offline-write-then-sync round trip remains BLOCKED (same reason)
--     [ ] Multi-device synchronization            -- BLOCKED (same reason, needs two real devices)
--   - Activation requires its own separate approval, per standing
--     authorization boundary -- not requested or granted by this gate.

select 'Gate 13.6-13.8 complete. Phase B: reconfirmed unchanged, picker OFF, regression evidence refreshed (107/8/0). Phase C: reconfirmed unchanged, 5 alias rows still prepared not inserted, all distinctions/exclusions intact. Phase D: picker still disabled, final 8-item manual acceptance checklist restated with the C-squad gap now closed by automated coverage; 4 items remain BLOCKED by the same pre-existing sandbox network-policy limitation, 2 remain NOT TESTED (no dedicated coverage, no live UI path). Nothing deployed, merged, inserted, or activated.' as status;
