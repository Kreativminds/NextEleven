-- Migration 011: expose secondHalfStartedAt per game in get_public_team_data,
-- for the Parents Page live match minute (team.html liveMatchMinute).
-- APPLIED TO PRODUCTION on 2026-11-14 ~18:17 UTC at the owner's request during
-- a live game. Requires migration 010 (its field is the anchor). Verified at
-- apply time: output identical except for the new field. Idempotent.
-- Rollback: remove the 'secondHalfStartedAt' pair from the games object.
do $$
declare v_def text; v_anchor text := '''actualKickoffAt'', payload->>''actualKickoffAt'',';
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='get_public_team_data';
  if v_def like '%''secondHalfStartedAt''%' then raise notice 'already present'; return; end if;
  if (length(v_def) - length(replace(v_def, v_anchor, ''))) / length(v_anchor) <> 1 then
    raise exception 'anchor not found exactly once (apply migration 010 first) — nothing changed';
  end if;
  execute replace(v_def, v_anchor, v_anchor || ' ''secondHalfStartedAt'', payload->>''secondHalfStartedAt'',');
end $$;
