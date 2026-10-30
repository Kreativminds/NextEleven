-- Migration: convert_caio_to_permanent_player
-- Project: wicydcvdakqopodbxtrl
-- Scope: user_id 563dea01-03a6-4e74-8cac-131cb39ccd97, season 6,
--        temporary_players.tempPlayerId = 1 ("Caio Andrade")
--
-- NOT YET APPLIED. Tested via BEGIN/ROLLBACK dry run against production —
-- see supabase/migrations_pending/README.md for the verified results and
-- supabase/migrations_pending/caio_pre_migration_backup.json for a backup
-- of every row this touches.
--
-- Idempotent: safe to run twice. The second run is a no-op — step 2's
-- INSERT is guarded by temporary_players.convertedToPlayerId, and by then
-- no row still carries tempPlayerId=1 for steps 1/3/4/5/6 to match.
--
-- Allocated identity: playerId 134 (one past the current max playerId, 133,
-- confirmed free across every season for this user) and a fresh
-- careerPlayerId. dateOfBirth, shirtNumber and primaryPosition are left
-- unset per instruction — only the shirt number PLAYED in each historical
-- match (payload.shirtNumberPlayed, already recorded per game_players row)
-- is preserved.

-- Step 1: resolve the one known duplicate — game 253 has two ACTIVE
-- game_players rows for Caio (local_id 401 and 408); keep the
-- most-recently-updated row per game, soft-delete any other active
-- duplicate. This MUST run before step 3: converting two active rows for
-- the same game onto the same playerId at once is exactly what violates
-- game_players_identity_uniq (user_id, gameId, playerId) and is why the
-- previous conversion attempt failed.
with dups as (
  select id, row_number() over (
    partition by (payload->>'gameId')::int order by updated_at desc
  ) as rn
  from game_players
  where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
    and deleted_at is null
    and (payload->>'tempPlayerId')::int = 1
)
update game_players gp
set deleted_at = now(),
    payload = payload || jsonb_build_object('isDeleted', true, 'deletedAt', now(), 'updatedAt', now())
from dups
where gp.id = dups.id and dups.rn > 1;

-- Step 2: create the permanent player row for season 6. No-op if Caio was
-- already converted (idempotency guard).
insert into players (id, user_id, device_id, local_id, payload, created_at, updated_at, deleted_at, sync_status)
select
  gen_random_uuid(), '563dea01-03a6-4e74-8cac-131cb39ccd97', 'dev-caio-migration', 'caio-player',
  jsonb_build_object(
    'playerId', 134, 'seasonId', 6, 'fullName', 'Caio Andrade', 'isActive', true,
    'careerPlayerId', gen_random_uuid()::text,
    'shirtNumber', null, 'dateOfBirth', null, 'primaryPosition', null, 'secondaryPosition', null,
    'nationality', null, 'dominantFoot', null, 'height', null, 'weight', null,
    'relationship', null, 'trackingLabel', null, 'trackingStatus', null, 'developmentNotes', null,
    'createdAt', now(), 'updatedAt', now()
  ),
  now(), now(), null, 'synced'
where not exists (
  select 1 from temporary_players
  where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
    and (payload->>'tempPlayerId')::int = 1
    and payload->>'convertedToPlayerId' is not null
);

-- Step 3: re-point every game_players row this guest ever had — active
-- AND already-deleted, for a consistent historical identity — onto the
-- new permanent playerId. goals, assists, shirtNumberPlayed and
-- positionPlayed are untouched, so nothing is recomputed or summed.
update game_players
set payload = (payload - 'tempPlayerId') || jsonb_build_object('playerId', 134, 'updatedAt', now())
where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  and (payload->>'tempPlayerId')::int = 1;

-- Step 4: re-point goal_events (by scorerType/scorerId — goal_events never
-- references a specific game_players row, so this cannot orphan anything).
update goal_events
set payload = payload || jsonb_build_object('scorerType', 'player', 'scorerId', 134, 'updatedAt', now())
where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  and payload->>'scorerType' = 'temp' and (payload->>'scorerId')::int = 1;

-- Step 5: re-point card_events the same way (currently just his one
-- yellow card, game 253 minute 72).
update card_events
set payload = payload || jsonb_build_object('scorerType', 'player', 'scorerId', 134, 'updatedAt', now())
where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  and payload->>'scorerType' = 'temp' and (payload->>'scorerId')::int = 1;

-- Step 6: retire the temporary player — soft-deleted, never hard-deleted,
-- and marked with exactly which player it became (also guards against
-- converting it a second time). This is what stops him being offered as a
-- separate selectable guest anywhere.
update temporary_players
set deleted_at = now(),
    payload = payload || jsonb_build_object('isDeleted', true, 'deletedAt', now(), 'convertedToPlayerId', 134, 'updatedAt', now())
where user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'
  and (payload->>'tempPlayerId')::int = 1
  and payload->>'convertedToPlayerId' is null;

-- Post-migration validation (run manually after applying, or re-run the
-- dry run in README.md):
--   select count(*) from game_players where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97'
--     and deleted_at is null and (payload->>'tempPlayerId')::int = 1;         -- expect 0
--   select (payload->>'gameId')::int, (payload->>'playerId')::int, count(*)
--     from game_players where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97'
--     and deleted_at is null and (payload->>'playerId')::int = 134
--     group by 1,2 having count(*) > 1;                                      -- expect 0 rows
