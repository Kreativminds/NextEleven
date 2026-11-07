-- Read-only queue of game-linked opponent identities requiring federation verification.
-- Never treat a similar club name as an approved identity match.
WITH pending AS (
 SELECT g.user_id, g.payload->>'opponent' historical_name, count(*) game_count
 FROM public.games g
 JOIN public.opponents o ON o.user_id=g.user_id AND o.deleted_at IS NULL
  AND o.payload->>'opponentName'=g.payload->>'opponent'
 WHERE g.deleted_at IS NULL AND o.federation_club_id IS NULL
 GROUP BY g.user_id,g.payload->>'opponent'
), candidates AS (
 SELECT p.user_id,p.historical_name,p.game_count,
  count(f.id) AS exact_normalized_catalogue_matches,
  string_agg(f.id::text, ', ' ORDER BY f.id::text) AS candidate_ids
 FROM pending p LEFT JOIN public.federation_clubs f
 ON lower(regexp_replace(f.official_name,'[^[:alnum:]]','','g')) =
    lower(regexp_replace(p.historical_name,'[^[:alnum:]]','','g'))
 GROUP BY p.user_id,p.historical_name,p.game_count
)
SELECT historical_name, sum(game_count) affected_games,
       sum(exact_normalized_catalogue_matches) exact_normalized_matches,
       CASE WHEN historical_name='CAC' THEN 'AMBIGUOUS: never infer Cacém'
            WHEN sum(exact_normalized_catalogue_matches)=0 THEN 'REQUIRES OFFICIAL IDENTITY EVIDENCE'
            ELSE 'CANDIDATE ONLY: verify registration and squad' END decision
FROM candidates
GROUP BY historical_name ORDER BY affected_games DESC,historical_name;
