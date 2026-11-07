-- READ ONLY: federation identity reconciliation and season safety checks.
-- Returns each account-scoped federation club, the existing opponent aliases,
-- and fixture references. No deletes, renames, or updates.
WITH linked AS (
 SELECT o.user_id,o.federation_club_id,o.id AS opponent_row_id,
        o.payload->>'opponentName' AS name,
        o.payload->>'opponentId' AS local_opponent_id,
        o.payload->>'ageGroup' AS legacy_age_group,
        o.payload->>'level' AS legacy_series
 FROM public.opponents o WHERE o.deleted_at IS NULL AND o.federation_club_id IS NOT NULL
), active_games AS (
 SELECT g.user_id,g.payload->>'opponent' AS opponent_name,
        g.payload->>'seasonId' AS season_id,g.id AS game_row_id
 FROM public.games g WHERE g.deleted_at IS NULL
), active_seasons AS (
 SELECT user_id,payload->>'seasonId' AS season_id
 FROM public.seasons WHERE deleted_at IS NULL
 AND (payload->>'seasonName' ILIKE '%2026%2027%'
   OR payload->>'seasonName' IN ('2026/27','2026-2027'))
), per_club AS (
 SELECT l.user_id,l.federation_club_id,
        count(*) AS existing_rows,
        array_agg(l.name ORDER BY l.name) AS existing_aliases,
        array_agg(l.local_opponent_id ORDER BY l.name) AS local_ids,
        count(DISTINCT l.local_opponent_id) AS distinct_local_ids,
        count(*) FILTER (WHERE l.legacy_age_group IS NOT NULL OR l.legacy_series IS NOT NULL) AS rows_with_legacy_squad_context
 FROM linked l GROUP BY l.user_id,l.federation_club_id
)
SELECT c.user_id,c.federation_club_id,f.official_name,
 c.existing_rows,c.existing_rows-1 AS excess_rows,c.existing_aliases,c.local_ids,
 c.rows_with_legacy_squad_context,
 (SELECT count(*) FROM active_games g WHERE g.user_id=c.user_id
  AND g.opponent_name=ANY(c.existing_aliases)) AS all_season_game_references,
 (SELECT count(*) FROM active_games g JOIN active_seasons s
  ON s.user_id=g.user_id AND s.season_id=g.season_id
  WHERE g.user_id=c.user_id AND g.opponent_name=ANY(c.existing_aliases)) AS active_2026_27_game_references,
 CASE WHEN c.existing_rows>1 THEN 'PRESERVE_ALIAS_ROWS_UNTIL_REFERENCE_MIGRATION'
 ELSE 'ALREADY_SINGLE_ROW' END AS safe_action
FROM per_club c JOIN public.federation_clubs f ON f.id=c.federation_club_id
ORDER BY c.existing_rows DESC,f.official_name,c.user_id;

-- Separate validation: a single local opponent ID must never map to multiple
-- federation clubs within the same account. If any rows return, halt grouping.
SELECT user_id,payload->>'opponentId' AS local_opponent_id,
 count(DISTINCT federation_club_id) AS conflicting_clubs,
 array_agg(DISTINCT federation_club_id) AS federation_ids
FROM public.opponents WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
GROUP BY user_id,payload->>'opponentId'
HAVING count(DISTINCT federation_club_id)>1;
