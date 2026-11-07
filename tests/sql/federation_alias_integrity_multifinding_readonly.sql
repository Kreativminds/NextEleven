-- Original #10: read-only multi-finding historical alias integrity audit.
-- Unlike CASE-based checks, report ALL applicable violations per alias.
-- No DML; zero rows means no violations in the inspected snapshot.
WITH findings AS (
 SELECT a.id AS alias_id, a.owner_id, a.historical_name,
        a.source_opponent_id, a.canonical_opponent_id,
        v.reason
 FROM public.opponent_historical_aliases a
 LEFT JOIN public.opponents src ON src.id=a.source_opponent_id
 LEFT JOIN public.opponents dst ON dst.id=a.canonical_opponent_id
 CROSS JOIN LATERAL (
   VALUES
    ('missing_source', src.id IS NULL),
    ('missing_canonical', dst.id IS NULL),
    ('source_owner_mismatch', src.id IS NOT NULL AND src.user_id IS DISTINCT FROM a.owner_id),
    ('canonical_owner_mismatch', dst.id IS NOT NULL AND dst.user_id IS DISTINCT FROM a.owner_id),
    ('source_federation_mismatch', src.id IS NOT NULL AND src.federation_club_id IS DISTINCT FROM a.federation_club_id),
    ('canonical_federation_mismatch', dst.id IS NOT NULL AND dst.federation_club_id IS DISTINCT FROM a.federation_club_id),
    ('source_name_drift', src.id IS NOT NULL AND src.payload->>'opponentName' IS DISTINCT FROM a.historical_name),
    ('retired_canonical', dst.id IS NOT NULL AND dst.deleted_at IS NOT NULL),
    ('self_alias', a.source_opponent_id = a.canonical_opponent_id)
 ) AS v(reason, violated)
 WHERE v.violated
), duplicate_sources AS (
 SELECT a.id AS alias_id, a.owner_id, a.historical_name,
        a.source_opponent_id, a.canonical_opponent_id,
        'multiple_canonical_destinations'::text AS reason
 FROM public.opponent_historical_aliases a
 WHERE EXISTS (
  SELECT 1 FROM public.opponent_historical_aliases b
  WHERE b.owner_id=a.owner_id AND b.source_opponent_id=a.source_opponent_id
    AND b.canonical_opponent_id IS DISTINCT FROM a.canonical_opponent_id
 )
)
SELECT * FROM findings
UNION ALL
SELECT * FROM duplicate_sources
ORDER BY owner_id, alias_id, reason;
