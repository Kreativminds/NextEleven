-- Original #10: read-only audit of reviewed historical alias graph integrity.
-- Detect chains, cycles, owner/federation mismatches and canonical retirement.
-- No name-based guesses and no changes to historical fixtures.
WITH RECURSIVE walks AS (
 SELECT a.id AS alias_id,a.owner_id,a.source_opponent_id,a.canonical_opponent_id,
        ARRAY[a.source_opponent_id,a.canonical_opponent_id] AS visited,
        (a.source_opponent_id=a.canonical_opponent_id) AS cycle,1 AS depth
 FROM public.opponent_historical_aliases a
 UNION ALL
 SELECT w.alias_id,w.owner_id,w.source_opponent_id,n.canonical_opponent_id,
        w.visited||n.canonical_opponent_id,
        n.canonical_opponent_id=ANY(w.visited),w.depth+1
 FROM walks w JOIN public.opponent_historical_aliases n
   ON n.owner_id=w.owner_id AND n.source_opponent_id=w.canonical_opponent_id
 WHERE NOT w.cycle AND w.depth<50
), findings AS (
 SELECT a.id AS alias_id,'source_owner_mismatch' AS finding
 FROM public.opponent_historical_aliases a LEFT JOIN public.opponents s ON s.id=a.source_opponent_id
 WHERE s.id IS NULL OR s.user_id IS DISTINCT FROM a.owner_id
 UNION ALL
 SELECT a.id,'canonical_owner_mismatch'
 FROM public.opponent_historical_aliases a LEFT JOIN public.opponents c ON c.id=a.canonical_opponent_id
 WHERE c.id IS NULL OR c.user_id IS DISTINCT FROM a.owner_id
 UNION ALL
 SELECT a.id,'canonical_retired'
 FROM public.opponent_historical_aliases a JOIN public.opponents c ON c.id=a.canonical_opponent_id
 WHERE c.deleted_at IS NOT NULL
 UNION ALL
 SELECT a.id,'federation_identity_mismatch'
 FROM public.opponent_historical_aliases a
 JOIN public.opponents s ON s.id=a.source_opponent_id
 JOIN public.opponents c ON c.id=a.canonical_opponent_id
 WHERE a.federation_club_id IS DISTINCT FROM s.federation_club_id
    OR a.federation_club_id IS DISTINCT FROM c.federation_club_id
 UNION ALL
 SELECT DISTINCT alias_id,'alias_cycle' FROM walks WHERE cycle
 UNION ALL
 SELECT DISTINCT alias_id,'alias_chain_requires_direct_canonical' FROM walks WHERE depth>1
 UNION ALL
 SELECT DISTINCT alias_id,'alias_chain_exceeds_50_hops' FROM walks WHERE depth=50 AND NOT cycle
)
SELECT alias_id,finding FROM findings ORDER BY alias_id,finding;
