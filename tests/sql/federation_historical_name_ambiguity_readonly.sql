-- Original #20: detect ambiguous owner-scoped historical fixture names.
-- A name shared by multiple opponent rows cannot be safely retired or remapped
-- by string matching alone, even if one candidate has a reviewed alias.
-- Read-only, covers active and archived fixtures.
WITH name_candidates AS (
 SELECT o.user_id AS owner_id, o.payload->>'opponentName' AS historical_name,
        count(*) AS opponent_rows,
        count(DISTINCT o.federation_club_id) FILTER (WHERE o.federation_club_id IS NOT NULL) AS federation_identities,
        array_agg(o.id ORDER BY o.id) AS candidate_ids
 FROM public.opponents o
 WHERE nullif(btrim(o.payload->>'opponentName'),'') IS NOT NULL
 GROUP BY o.user_id,o.payload->>'opponentName'
 HAVING count(*)>1
), referenced AS (
 SELECT n.*,g.id AS game_id,g.deleted_at AS game_deleted_at
 FROM name_candidates n JOIN public.games g
 ON g.user_id=n.owner_id AND g.payload->>'opponent'=n.historical_name
)
SELECT owner_id,game_id,historical_name,
 CASE WHEN game_deleted_at IS NULL THEN 'active' ELSE 'archived' END AS fixture_state,
 opponent_rows,federation_identities,candidate_ids,
 'ambiguous_historical_opponent_name_requires_manual_review' AS finding
FROM referenced ORDER BY owner_id,game_id;
