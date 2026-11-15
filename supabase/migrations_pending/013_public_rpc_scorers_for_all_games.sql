-- Migration 013: return goalEvents and goalScorers for every game of the
-- season in get_public_team_data, not only games from the last 3 days, so
-- the Parents Page can show who scored when a past result is tapped open
-- (owner decision, 2026-11-15). Same change migration 012 made for cards.
-- Note: these two lists are sent regardless of the "show player stats"
-- setting, so with stats hidden the season's scorers are still visible in
-- the expanded results. The owner was told and accepted this.
-- APPLIED TO PRODUCTION on 2026-11-15. Verified at apply time: output
-- identical except goalEvents/goalScorers. Idempotent.
-- Rollback: restore the "(games.payload->>'date')::date < (current_date -
-- interval '3 days')::date" condition in both case expressions.
do $$
declare v_def text;
  v_pat text := $p$('(goalEvents|goalScorers)', \(\s*)case when games\.payload->>'date' is null or \(games\.payload->>'date'\)::date < \(current_date - interval '3 days'\)::date then '\[\]'::jsonb else \($p$;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='get_public_team_data';
  if (select count(*) from regexp_matches(v_def, v_pat, 'g')) = 0 then raise notice 'window already removed'; return; end if;
  execute regexp_replace(v_def, v_pat, $r$\1case when games.payload->>'date' is null then '[]'::jsonb else ($r$, 'g');
end $$;
