-- Read-only production reconciliation preview. No updates or deletes.
-- Every duplicate group is scoped to its owner and linked federation club.
-- Games use opponent names; therefore a linked duplicate may be referenced
-- by an active season fixture even if the club appears under another alias.
WITH opponents AS (
 SELECT o.user_id,o.federation_club_id,o.id AS row_id,
        o.payload->>'opponentName' AS opponent_name
 FROM public.opponents o WHERE o.deleted_at IS NULL
 AND o.federation_club_id IS NOT NULL
), duplicate_groups AS (
 SELECT user_id,federation_club_id,count(*) AS rows_per_club,
        array_agg(opponent_name ORDER BY opponent_name) AS aliases
 FROM opponents GROUP BY user_id,federation_club_id HAVING count(*)>1
), season_games AS (
 SELECT g.user_id,g.payload->>'opponent' AS opponent_name
 FROM public.games g JOIN public.seasons s
 ON s.user_id=g.user_id AND s.deleted_at IS NULL
 AND s.payload->>'seasonName'='2026/27'
 AND s.payload->>'seasonId'=g.payload->>'seasonId'
 WHERE g.deleted_at IS NULL
)
SELECT f.official_name AS federation_club, d.rows_per_club,
       d.rows_per_club-1 AS excess_rows,
       d.aliases,
       (SELECT count(*) FROM season_games sg WHERE sg.user_id=d.user_id
         AND sg.opponent_name=ANY(d.aliases)) AS live_season_game_references,
       'REVIEW_ONLY_NO_DELETE' AS action
FROM duplicate_groups d JOIN public.federation_clubs f
 ON f.id=d.federation_club_id
ORDER BY d.rows_per_club DESC,f.official_name,d.aliases::text;
