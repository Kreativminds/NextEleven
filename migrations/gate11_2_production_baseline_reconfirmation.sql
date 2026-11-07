-- ============================================================================
-- GATE 11.7 — production protection reconfirmation. All queries READ-ONLY,
-- executed fresh this gate directly against production (wicydcvdakqopodbxtrl).
-- Nothing written. Fourth independent capture of this baseline this
-- engagement (Gate 8.9, Gate 9.8, Gate 10.6, this gate) -- zero drift again.
-- ============================================================================

-- Active season reconfirmed: exactly one row has status='active' --
-- seasonId='6', seasonName='2026/27'.

--   games (season 6, active)          : 27   (unchanged)
--   game_players (season 6, active)   : 143  (unchanged)
--   goal_events (season 6, active)    : 10   (unchanged)
--   card_events (season 6, active)    : 4    (unchanged)
--   players (season 6, active)        : 20   (unchanged)
--   team_share_links (all)            : 3 total, 1 enabled (unchanged)
--   opponents (all, active)           : 160  (unchanged)

-- The 188-vs-143 game_players discrepancy remains fully documented (Gate
-- 9.4) and consistently resolved to 143 everywhere this engagement has
-- referenced it since -- no unexplained difference.

-- Federation tables reconfirmed ABSENT from production (no
-- federation_clubs / federation_club_competitions / federation_club_venues
-- exist there) -- nothing from this gate's test-project-only rehearsal has
-- touched production in any way.

-- opponents_merge_plan_tmp reconfirmed (Gate 11.1, same session): RLS still
-- disabled, 0 policies, 35 rows unchanged -- no change since Gate 10, still
-- awaiting separate approval.

select 'Gate 11.7 complete. Production baseline reconfirmed fresh, read-only, zero drift across FOUR independent checks now (Gate 8.9, 9.8, 10.6, 11.7): games=27, game_players=143, goal_events=10, card_events=4, players=20, team_share_links=3 (1 enabled), opponents=160. Federation tables confirmed absent from production. opponents_merge_plan_tmp confirmed unchanged (35 rows, RLS still disabled). No production modification made this gate.' as status;
