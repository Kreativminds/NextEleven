-- ============================================================================
-- GATE 12.7 — final production baseline reconfirmation, immediately before
-- any approved deployment, per Gate 12 section 7. READ-ONLY, executed fresh
-- this gate directly against production (wicydcvdakqopodbxtrl). Fifth
-- independent capture this engagement (Gate 8.9, 9.8, 10.6, 11.7, this gate).
-- ============================================================================

-- Active season reconfirmed: exactly one row has payload->>'status'='active'
-- -- id e2ac10e1-981a-4e12-9018-bf9a85384541, local_id '6', seasonName
-- '2026/27' (unchanged).

-- NOTE ON METHODOLOGY -- a real pitfall hit and resolved THIS gate, worth
-- recording: querying game_players/goal_events by their OWN denormalized
-- payload->>'seasonId' field undercounts (141 and 7 respectively) because a
-- small number of rows carry a missing/stale seasonId on themselves even
-- though their parent game correctly belongs to season 6 -- this is the
-- same root cause as the already-documented 188-vs-143 discrepancy (Gate
-- 9.4). The CORRECT, established method is to join through games.gameId
-- instead of trusting the row's own seasonId -- doing so returns the
-- expected 143/10 exactly. Recorded here so this pitfall doesn't have to be
-- rediscovered in a future gate.

--   games (season 6, active)          : 27   (unchanged)
--   game_players (via games join)     : 143  (unchanged)
--   goal_events (via games join)      : 10   (unchanged)
--   card_events (season 6, active)    : 4    (unchanged)
--   players (season 6, active)        : 20   (unchanged)
--   team_share_links (all)            : 3 total, 1 enabled (unchanged)
--   opponents (all, active)           : 160  (unchanged)

-- Zero drift across all 7 figures, fifth independent check.

-- Federation tables reconfirmed ABSENT from production (gate12_2, same
-- gate). opponents_merge_plan_tmp reconfirmed (gate12_1, same gate): 35
-- rows, RLS still disabled, 0 policies, still awaiting separate approval.

-- Per Gate 12's own instruction: "Any unexplained difference must stop the
-- deployment." There is no unexplained difference -- the only discrepancy
-- encountered (the seasonId-filter undercounting) was a query-methodology
-- artifact on THIS gate's own first-attempt query, fully explained and
-- resolved by switching to the established join method, not a real data
-- change. All 7 figures match Victor's stated expectations exactly.

select 'Gate 12.7 complete. Production baseline reconfirmed fresh, read-only, zero drift across FIVE independent checks now (Gate 8.9, 9.8, 10.6, 11.7, 12.7): games=27, game_players=143, goal_events=10, card_events=4, players=20, team_share_links=3 (1 enabled), opponents=160. No unexplained difference. No production modification made this gate.' as status;
