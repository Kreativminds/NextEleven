-- Migration 012: return cardEvents for every game of the season in
-- get_public_team_data, not only games from the last 3 days, so the Parents
-- Page can show cards under past results (owner request, 2026-11-15).
-- Goal events/scorers keep their 3-day window. Names stay privacy-filtered:
-- the page resolves scorer ids against the already-filtered players list.
-- APPLIED TO PRODUCTION on 2026-11-15. Verified at apply time: output
-- identical except cardEvents (1 -> 8 cards across 4 games). Idempotent.
-- Rollback: restore the "(games.payload->>'date')::date < (current_date -
-- interval '3 days')::date" condition in the cardEvents case expression.
do $$
declare v_def text;
  v_pat text := $p$('cardEvents', \(\s*)case when games\.payload->>'date' is null or \(games\.payload->>'date'\)::date < \(current_date - interval '3 days'\)::date then '\[\]'::jsonb else \($p$;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='get_public_team_data';
  if (select count(*) from regexp_matches(v_def, v_pat, 'g')) = 0 then raise notice 'window already removed'; return; end if;
  execute regexp_replace(v_def, v_pat, $r$\1case when games.payload->>'date' is null then '[]'::jsonb else ($r$);
end $$;
