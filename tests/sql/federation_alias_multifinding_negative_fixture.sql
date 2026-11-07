-- Original #10: independent negative-fixture regression for multi-finding audit.
-- Synthetic CTE data, no database writes. This proves simultaneous violations
-- are emitted separately and valid owner-scoped aliases are not flagged.
WITH opponents(id,user_id,federation_club_id,opponent_name,deleted_at) AS (
 VALUES
 (1,10,100,'Olivais A',NULL::timestamptz),
 (2,10,100,'Olivais',NULL::timestamptz),
 (3,20,200,'Olivais Sul',NULL::timestamptz),
 (4,10,100,'Retired',now())
), aliases(id,owner_id,historical_name,source_opponent_id,canonical_opponent_id,federation_club_id) AS (
 VALUES
 (101,10,'Olivais A',1,2,100), -- valid
 (102,10,'Wrong name',1,3,100), -- name + owner + federation mismatch
 (103,10,'Olivais A',1,4,100), -- retired canonical
 (104,10,'Olivais A',1,1,100), -- self alias
 (105,10,'Missing',999,2,100) -- missing source
), findings AS (
 SELECT a.id AS alias_id, v.reason
 FROM aliases a
 LEFT JOIN opponents src ON src.id=a.source_opponent_id
 LEFT JOIN opponents dst ON dst.id=a.canonical_opponent_id
 CROSS JOIN LATERAL (VALUES
 ('missing_source',src.id IS NULL),
 ('missing_canonical',dst.id IS NULL),
 ('source_owner_mismatch',src.id IS NOT NULL AND src.user_id IS DISTINCT FROM a.owner_id),
 ('canonical_owner_mismatch',dst.id IS NOT NULL AND dst.user_id IS DISTINCT FROM a.owner_id),
 ('source_federation_mismatch',src.id IS NOT NULL AND src.federation_club_id IS DISTINCT FROM a.federation_club_id),
 ('canonical_federation_mismatch',dst.id IS NOT NULL AND dst.federation_club_id IS DISTINCT FROM a.federation_club_id),
 ('source_name_drift',src.id IS NOT NULL AND src.opponent_name IS DISTINCT FROM a.historical_name),
 ('retired_canonical',dst.id IS NOT NULL AND dst.deleted_at IS NOT NULL),
 ('self_alias',a.source_opponent_id=a.canonical_opponent_id)
 ) v(reason,violated) WHERE v.violated
 UNION ALL
 SELECT a.id,'multiple_canonical_destinations'
 FROM aliases a WHERE EXISTS (
 SELECT 1 FROM aliases b WHERE b.owner_id=a.owner_id
 AND b.source_opponent_id=a.source_opponent_id
 AND b.canonical_opponent_id IS DISTINCT FROM a.canonical_opponent_id)
), expected(alias_id,reason) AS (
 VALUES
 (102,'source_name_drift'),(102,'canonical_owner_mismatch'),(102,'canonical_federation_mismatch'),
 (103,'retired_canonical'),(104,'self_alias'),(105,'missing_source'),
 (101,'multiple_canonical_destinations'),(102,'multiple_canonical_destinations'),
 (103,'multiple_canonical_destinations'),(104,'multiple_canonical_destinations')
), discrepancies AS (
 (SELECT * FROM findings EXCEPT ALL SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM findings)
)
SELECT CASE WHEN EXISTS(SELECT 1 FROM discrepancies)
 THEN (SELECT 1/0 FROM discrepancies LIMIT 1)
 ELSE 1 END AS audit_negative_fixture_pass;
