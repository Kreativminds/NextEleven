-- Original task #20: read-only fixture opponent reference completeness gate.
-- Covers active and archived fixtures. Exact historical names are intentional:
-- never silently fold Olivais Sul into Olivais or normalize federation identity.
-- A missing opponent name or absent owner-scoped opponent row requires review.
WITH fixture_refs AS (
 SELECT g.id AS game_id,g.user_id AS owner_id,g.deleted_at,
        g.payload->>'opponent' AS historical_name
 FROM public.games g
), matches AS (
 SELECT f.game_id,f.owner_id,f.deleted_at,f.historical_name,
        count(o.id) AS matching_rows
 FROM fixture_refs f LEFT JOIN public.opponents o
   ON o.user_id=f.owner_id
  AND o.payload->>'opponentName'=f.historical_name
 GROUP BY f.game_id,f.owner_id,f.deleted_at,f.historical_name
)
SELECT owner_id,game_id,historical_name,
 CASE WHEN deleted_at IS NULL THEN 'active' ELSE 'archived' END AS fixture_state,
 matching_rows,
 CASE WHEN nullif(btrim(historical_name),'') IS NULL
      THEN 'missing_fixture_opponent_name'
      WHEN matching_rows=0 THEN 'no_owner_scoped_opponent_row'
 END AS finding
FROM matches
WHERE nullif(btrim(historical_name),'') IS NULL OR matching_rows=0
ORDER BY owner_id,game_id;
