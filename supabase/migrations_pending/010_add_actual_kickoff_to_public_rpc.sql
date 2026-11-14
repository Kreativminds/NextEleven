-- Migration 010: expose actualKickoffAt and matchDurationMins per game in
-- get_public_team_data, so the Parents Page shows the real kick-off time and
-- counts goal minutes from it (team.html already reads both fields).
--
-- APPLIED TO PRODUCTION on 2026-11-14 ~18:13 Lisbon, at the owner's request
-- during a live game (game 256, scheduled 17:00, real kick-off 17:25).
-- Before the change the page showed "Início 17:00" and goal minutes 25 min off.
-- Verified at apply time: the function's output was identical except for the
-- two new fields on each game.
--
-- Written as a patch on the live definition (not a full redefinition) so it
-- cannot drift from whatever version is deployed. Idempotent: does nothing if
-- the field is already present.
--
-- Rollback: run the same block with the replace reversed, i.e. remove the line
--   'actualKickoffAt', payload->>'actualKickoffAt', 'matchDurationMins', payload->>'matchDurationMins',
-- from the function's games object. team.html falls back to gameTime.

do $$
declare
  v_def text;
  v_anchor text := '''round'', payload->>''round'',';
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'get_public_team_data';

  if v_def like '%''actualKickoffAt''%' then
    raise notice 'actualKickoffAt already exposed — nothing to do';
    return;
  end if;
  if (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor) <> 1 then
    raise exception 'anchor not found exactly once — nothing changed';
  end if;

  execute replace(v_def, v_anchor, v_anchor ||
    E'\n              ''actualKickoffAt'', payload->>''actualKickoffAt'', ''matchDurationMins'', payload->>''matchDurationMins'',');
end $$;
