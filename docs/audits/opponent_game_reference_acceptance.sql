-- Non-mutating acceptance checks before and after any proposed opponent cleanup.
-- Existing games reference opponent names, not federation UUIDs.
WITH names AS (
 SELECT user_id, payload->>'opponentName' AS name, count(*) AS n
 FROM public.opponents WHERE deleted_at IS NULL GROUP BY 1,2
), references AS (
 SELECT g.user_id,g.payload->>'opponent' AS opponent_name,coalesce(n.n,0) AS matching_opponents
 FROM public.games g LEFT JOIN names n ON n.user_id=g.user_id AND n.name=g.payload->>'opponent'
 WHERE g.deleted_at IS NULL
)
SELECT count(*) AS active_games,
 count(*) FILTER(WHERE matching_opponents=1) AS uniquely_resolved,
 count(*) FILTER(WHERE matching_opponents=0) AS orphaned,
 count(*) FILTER(WHERE matching_opponents>1) AS ambiguous
FROM references;
-- Note: deliberately no UPDATE/DELETE. Any migration must preserve 100% uniquely_resolved.
