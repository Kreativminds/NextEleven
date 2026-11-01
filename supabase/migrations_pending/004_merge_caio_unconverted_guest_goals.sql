-- Migration: merge_caio_unconverted_guest_goals
-- Project: wicydcvdakqopodbxtrl
-- Scope: user_id 563dea01-03a6-4e74-8cac-131cb39ccd97, season 6
--
-- Background: 001_convert_caio_to_permanent_player.sql converted Caio
-- Andrade (temporary_players.tempPlayerId=1) to a permanent player
-- (players.playerId=134). That migration's steps 3-6 (re-point
-- game_players/goal_events/card_events, retire the temp player) were
-- never actually applied to production -- four historical game_players
-- rows (games 250, 251, 252, 253), five goal_events rows and one
-- card_events row were still sitting under the old guest identity, and
-- temporary_players.tempPlayerId=1 was never marked converted/deleted.
--
-- Effect of the gap: the Parents Page's Top Scorer / season-leaders
-- computation only ever considers permanent players (players.isActive),
-- never guests -- so these 10 goals (1+3+4+2) were invisible there, even
-- though Caio's own permanent-player record (134) correctly showed his
-- 1 goal from the 2026-10-31 match. Reported by Victor as "Caio is the
-- top scorer with at least 11 goals" -- 10 (unconverted) + 1 (already
-- converted) = 11, matching exactly.
--
-- NOT YET APPLIED -- tested via BEGIN/ROLLBACK dry run against
-- production (remaining_temp_rows: 0, duplicate_active_134_rows: 0,
-- caio_season_total_goals: 11). Backup of every row this touches:
-- caio_unconverted_temp_rows_backup_2026-11-01.json.
--
-- Idempotent: safe to run twice -- the WHERE clauses select on
-- tempPlayerId=1 / scorerType='temp', so a second run matches 0 rows.
-- No active-row conflicts: confirmed 0 existing active (non-deleted)
-- playerId=134 rows for games 250/251/252/253 before this runs.

UPDATE game_players
SET payload = (payload - 'tempPlayerId') || jsonb_build_object('playerId', 134, 'updatedAt', now())
WHERE user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  AND (payload->>'tempPlayerId')::int = 1;

UPDATE goal_events
SET payload = payload || jsonb_build_object('scorerType', 'player', 'scorerId', 134, 'updatedAt', now())
WHERE user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  AND payload->>'scorerType' = 'temp' AND (payload->>'scorerId')::int = 1;

UPDATE card_events
SET payload = payload || jsonb_build_object('scorerType', 'player', 'scorerId', 134, 'updatedAt', now())
WHERE user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  AND payload->>'scorerType' = 'temp' AND (payload->>'scorerId')::int = 1;

UPDATE temporary_players
SET deleted_at = now(),
    payload = payload || jsonb_build_object('isDeleted', true, 'deletedAt', now(), 'convertedToPlayerId', 134, 'updatedAt', now())
WHERE user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  AND (payload->>'tempPlayerId')::int = 1
  AND payload->>'convertedToPlayerId' IS NULL;

-- Post-migration validation (expect 0, 0, 11):
--   select count(*) from game_players where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97'
--     and (payload->>'tempPlayerId')::int = 1;
--   select (payload->>'gameId')::int, count(*) from game_players
--     where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null
--     and (payload->>'playerId')::int = 134 group by 1 having count(*) > 1;
--   select sum((payload->>'goals')::int) from game_players
--     where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null
--     and (payload->>'playerId')::int = 134;
