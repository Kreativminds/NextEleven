-- Read-only preflight for original task #10. Run against isolated project first.
-- No identity inference, no historical fixture rewrites and no DML.
-- Any returned row is an integrity exception requiring manual review.
WITH alias_audit AS (
 SELECT a.id AS alias_id, a.owner_id, a.historical_name,
        a.source_opponent_id, a.canonical_opponent_id,
        CASE
          WHEN src.id IS NULL THEN 'missing_source'
          WHEN dst.id IS NULL THEN 'missing_canonical'
          WHEN src.user_id IS DISTINCT FROM a.owner_id
            OR dst.user_id IS DISTINCT FROM a.owner_id THEN 'owner_mismatch'
          WHEN src.federation_club_id IS DISTINCT FROM a.federation_club_id
            OR dst.federation_club_id IS DISTINCT FROM a.federation_club_id THEN 'federation_mismatch'
          WHEN src.payload->>'opponentName' IS DISTINCT FROM a.historical_name THEN 'source_name_drift'
          WHEN dst.deleted_at IS NOT NULL THEN 'retired_canonical'
          WHEN src.id=dst.id THEN 'self_alias'
          ELSE NULL
        END AS exception
 FROM public.opponent_historical_aliases a
 LEFT JOIN public.opponents src ON src.id=a.source_opponent_id
 LEFT JOIN public.opponents dst ON dst.id=a.canonical_opponent_id
)
SELECT * FROM alias_audit WHERE exception IS NOT NULL
ORDER BY owner_id, alias_id;
