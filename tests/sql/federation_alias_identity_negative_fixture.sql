-- Original #10: synthetic, read-only alias identity safety regression.
-- Covers independent findings per alias, not only the first error.
-- A same-name Olivais Sul remains distinct from Olivais; CAC is not Cacem.
WITH opponents(id,owner_id,federation_id,retired) AS (
 VALUES ('olivais-a','owner-a','fed-olivais',false),
        ('olivais','owner-a','fed-olivais',false),
        ('olivais-sul','owner-a','fed-olivais-sul',false),
        ('retired','owner-a','fed-olivais',true),
        ('other-owner','owner-b','fed-olivais',false),
        ('cac','owner-a','fed-cac',false),
        ('cacem','owner-a','fed-cacem',false)
), aliases(id,owner_id,source_id,canonical_id,federation_id) AS (
 VALUES ('valid','owner-a','olivais-a','olivais','fed-olivais'),
        ('wrong_owner','owner-a','olivais-a','other-owner','fed-olivais'),
        ('wrong_federation','owner-a','olivais-sul','olivais','fed-olivais-sul'),
        ('retired_canonical','owner-a','olivais-a','retired','fed-olivais'),
        ('missing_source','owner-a','missing','olivais','fed-olivais'),
        ('cac_not_cacem','owner-a','cac','cacem','fed-cac')
), findings AS (
 SELECT a.id,'source_owner_mismatch' AS finding FROM aliases a
 LEFT JOIN opponents s ON s.id=a.source_id
 WHERE s.id IS NULL OR s.owner_id IS DISTINCT FROM a.owner_id
 UNION ALL
 SELECT a.id,'canonical_owner_mismatch' FROM aliases a
 LEFT JOIN opponents c ON c.id=a.canonical_id
 WHERE c.id IS NULL OR c.owner_id IS DISTINCT FROM a.owner_id
 UNION ALL
 SELECT a.id,'canonical_retired' FROM aliases a JOIN opponents c ON c.id=a.canonical_id
 WHERE c.retired
 UNION ALL
 SELECT a.id,'federation_identity_mismatch' FROM aliases a
 JOIN opponents s ON s.id=a.source_id JOIN opponents c ON c.id=a.canonical_id
 WHERE a.federation_id IS DISTINCT FROM s.federation_id
 OR a.federation_id IS DISTINCT FROM c.federation_id
), expected(id,finding) AS (
 VALUES ('wrong_owner','canonical_owner_mismatch'),
        ('wrong_federation','federation_identity_mismatch'),
        ('retired_canonical','canonical_retired'),
        ('missing_source','source_owner_mismatch'),
        ('cac_not_cacem','federation_identity_mismatch')
), discrepancies AS (
 (SELECT * FROM findings EXCEPT SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT SELECT * FROM findings)
)
SELECT (SELECT count(*) FROM aliases) AS tested_aliases,
       (SELECT count(*) FROM findings) AS detected_findings,
       (SELECT count(*) FROM discrepancies) AS mismatches,
       CASE WHEN (SELECT count(*) FROM discrepancies)=0
         AND (SELECT count(*) FROM findings)=5
         AND (SELECT count(*) FROM aliases)=6
       THEN 'PASS' ELSE 'FAIL' END AS result;
