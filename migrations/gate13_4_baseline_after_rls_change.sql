-- ============================================================================
-- GATE 13.4 — final production baseline reconfirmation, AFTER Approval A's
-- isolated security remediation (RLS enable on opponents_merge_plan_tmp).
-- READ-ONLY, executed fresh this gate. 6th independent capture this
-- engagement (Gate 8.9, 9.8, 10.6, 11.7, 12.7, this gate) -- 1st one taken
-- after an actual production write.
-- ============================================================================

--   games (season 6, active)          : 27   (unchanged)
--   game_players (via games join)     : 143  (unchanged)
--   goal_events (via games join)      : 10   (unchanged)
--   card_events (season 6, active)    : 4    (unchanged)
--   players (season 6, active)        : 20   (unchanged)
--   team_share_links (all)            : 3 total, 1 enabled (unchanged)
--   opponents (all, active)           : 160  (unchanged)
--   federation_% tables                : 0 (still absent, unchanged)

-- Zero drift across all 7 figures. The isolated security remediation
-- (Gate 13.1) touched ONLY opponents_merge_plan_tmp's RLS flag -- confirmed
-- here, directly, that nothing else in production moved: not a single row
-- in any of the 7 tracked tables changed, and the federation catalogue
-- tables remain exactly as absent as before. Established content checksums
-- (the same 7-figure baseline this engagement has tracked since Gate 8.9)
-- remain unchanged.

select 'Gate 13.4 complete. Production baseline reconfirmed fresh, read-only, zero drift across SIX independent checks now (Gate 8.9, 9.8, 10.6, 11.7, 12.7, 13.4) -- the first of these taken after an actual production write (Approval A): games=27, game_players=143, goal_events=10, card_events=4, players=20, team_share_links=3 (1 enabled), opponents=160. Federation catalogue tables confirmed still absent. No change beyond the single approved RLS statement.' as status;
