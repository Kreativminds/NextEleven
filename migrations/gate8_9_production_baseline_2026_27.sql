-- ============================================================================
-- GATE 8.9 — read-only production baseline, active 2026/27 season
-- (season_id=6), Victor's account (563dea01-03a6-4e74-8cac-131cb39ccd97).
-- Captured 2026-11-05, read-only, nothing modified. This is the exact
-- query to re-run immediately after Phase A/B/C deploy (before real
-- user traffic has a chance to add organic new games/events) --
-- row_count AND content_checksum must match EVERY LINE below exactly.
-- Any mismatch on games/game_players/goal_events/card_events/players/
-- team_share_links blocks release per Victor's explicit instruction
-- ("Any unexplained changes to existing records must block release").
-- A changed count on opponents_referenced_by_season6_games with an
-- unchanged games checksum is impossible (the opponent name lives
-- inside games.payload) -- so that line moves only if games also moved,
-- and is reported purely as a cross-check, not an independent trigger.
-- ============================================================================

-- BASELINE VALUES (2026-11-05, before any Gate 8 deployment phase):
--   games                                   : 27 rows, checksum 864518e6a00b890109ffd7e0375b7eb2
--   game_players                            : 143 rows, checksum 140dda0ea0da7403ae8abd15c688d63f
--   goal_events                             : 10 rows, checksum 19fda4fe174f98fb512b2a8d3ae66c5d
--   card_events                             : 4 rows, checksum ec2bff38b38834ac5849caa49367d1fb
--   players                                 : 20 rows, checksum 2b1ebcbd945b3b2b20588ad812dfa190
--   opponents_referenced_by_season6_games   : 14 rows, checksum 12d24442cb7968c6d8bdf024ec133172
--   team_share_links                        : 3 rows, checksum c2b3cb5dfa67fe419d9462c7556f0fed

select 'games' as entity,
  count(*) as row_count,
  md5(string_agg(payload::text, '|' order by (payload->>'gameId')::int)) as content_checksum
from public.games where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (payload->>'seasonId')::int=6 and deleted_at is null
union all
select 'game_players',
  count(*),
  md5(string_agg(payload::text, '|' order by (payload->>'gameId')::int, (payload->>'playerId')::int nulls last, payload->>'tempPlayerId'))
from public.game_players gp where gp.user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and gp.deleted_at is null
  and (gp.payload->>'gameId')::int in (select (payload->>'gameId')::int from public.games where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (payload->>'seasonId')::int=6 and deleted_at is null)
union all
select 'goal_events',
  count(*),
  md5(string_agg(payload::text, '|' order by (payload->>'gameId')::int, payload->>'scoredAt'))
from public.goal_events ge where ge.user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and ge.deleted_at is null
  and (ge.payload->>'gameId')::int in (select (payload->>'gameId')::int from public.games where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (payload->>'seasonId')::int=6 and deleted_at is null)
union all
select 'card_events',
  count(*),
  md5(string_agg(payload::text, '|' order by (payload->>'gameId')::int, (payload->>'minute')::int))
from public.card_events ce where ce.user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and ce.deleted_at is null
  and (ce.payload->>'gameId')::int in (select (payload->>'gameId')::int from public.games where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (payload->>'seasonId')::int=6 and deleted_at is null)
union all
select 'players',
  count(*),
  md5(string_agg(payload::text, '|' order by (payload->>'playerId')::int))
from public.players where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (payload->>'seasonId')::int=6 and deleted_at is null
union all
select 'opponents_referenced_by_season6_games',
  count(distinct lower(g.payload->>'opponent')),
  md5(string_agg(distinct lower(g.payload->>'opponent'), '|' order by lower(g.payload->>'opponent')))
from public.games g where g.user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and (g.payload->>'seasonId')::int=6 and g.deleted_at is null
union all
select 'team_share_links',
  count(*),
  md5(string_agg(share_token || ':' || enabled::text || ':' || season_id::text, '|' order by share_token))
from public.team_share_links where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97'
order by entity;

-- Additional whole-app baseline (not season-scoped), also captured
-- 2026-11-05, for the broader "nothing else moved" check:
--   seasons=7, games_total=182, opponents_total=249
--   (opponents_active=160), players_total=110, goal_events_total=11,
--   card_events_total=4.
--
-- NOTE on a discrepancy with the earlier Gate 7 report, run down and
-- explained rather than left standing: Gate 7 reported "season6_games=108".
-- Verified directly (2026-11-05): season_id=6 INCLUDING soft-deleted
-- games is 108 for Victor's account, and this is not a mixup with
-- another user -- querying season_id=6 across ALL users also returns
-- exactly 108, confirming Victor's account is the only one with
-- season_id=6 games. The 108 figure was simply counting including
-- soft-deleted rows; this file's query above filters deleted_at is null
-- (27 ACTIVE games), which is the correct basis for an "unexplained
-- change to an existing record" check. The gap (108 - 27 = 81
-- soft-deleted games under season_id=6) is not itself investigated
-- here -- it reflects ordinary delete activity on Victor's real account
-- over time (this engagement has only ever read production, never
-- written to it, so none of these deletions originate from this work).
-- Flagged only so the 108-vs-27 numbers are not mistaken for each other
-- in a future comparison -- 27 (active, filtered) is the figure this
-- baseline tracks.
select
  (select count(*) from public.seasons where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as seasons,
  (select count(*) from public.games where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as games_total,
  (select count(*) from public.opponents where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97') as opponents_total,
  (select count(*) from public.opponents where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as opponents_active,
  (select count(*) from public.players where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as players_total,
  (select count(*) from public.goal_events where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as goal_events_total,
  (select count(*) from public.card_events where user_id='563dea01-03a6-4e74-8cac-131cb39ccd97' and deleted_at is null) as card_events_total;
