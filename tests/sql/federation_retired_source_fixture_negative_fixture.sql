-- Original #20: synthetic negative regression for retired historical opponent references.
-- Read-only. Exercises active AND archived fixtures, owner isolation, alias validity,
-- distinct Olivais Sul, and canonical retirement. No production fixture is modified.
WITH opponents(id,user_id,federation_club_id,historical_name,deleted_at) AS (
 VALUES
 (1,10,100,'Olivais A',now()),
 (2,10,100,'Olivais',NULL::timestamptz),
 (3,20,200,'Olivais Sul',now()),
 (4,20,200,'Olivais Sul',NULL::timestamptz),
 (5,10,300,'CAC',now()),
 (6,10,300,'CAC canonical',now()),
 (7,10,400,'Another club',now())
), games(id,user_id,opponent,deleted_at) AS (
 VALUES
 (101,10,'Olivais A',NULL::timestamptz),
 (102,10,'Olivais A',now()),
 (103,20,'Olivais Sul',NULL::timestamptz),
 (104,20,'Olivais Sul',now()),
 (105,10,'CAC',now()),
 (106,10,'Another club',NULL::timestamptz)
), aliases(id,owner_id,source_opponent_id,canonical_opponent_id,historical_name,federation_club_id) AS (
 VALUES
 (201,10,1,2,'Olivais A',100),
 (202,20,3,4,'Olivais Sul',200),
 (203,10,5,6,'CAC',300),
 (204,20,7,4,'Another club',400)
), retired_sources AS (
 SELECT id source_id,user_id owner_id,historical_name,federation_club_id
 FROM opponents WHERE deleted_at IS NOT NULL
), referenced AS (
 SELECT r.*,g.id game_id,g.deleted_at game_deleted_at
 FROM retired_sources r JOIN games g ON g.user_id=r.owner_id AND g.opponent=r.historical_name
), valid_alias AS (
 SELECT r.game_id,r.source_id
 FROM referenced r
 JOIN aliases a ON a.owner_id=r.owner_id AND a.source_opponent_id=r.source_id
   AND a.historical_name=r.historical_name
   AND a.federation_club_id IS NOT DISTINCT FROM r.federation_club_id
 JOIN opponents canonical ON canonical.id=a.canonical_opponent_id
   AND canonical.user_id=r.owner_id AND canonical.deleted_at IS NULL
   AND canonical.federation_club_id IS NOT DISTINCT FROM r.federation_club_id
), findings AS (
 SELECT r.game_id,r.source_id,
 CASE WHEN r.game_deleted_at IS NULL THEN 'active' ELSE 'archived' END fixture_state
 FROM referenced r
 WHERE NOT EXISTS (SELECT 1 FROM valid_alias a WHERE a.game_id=r.game_id AND a.source_id=r.source_id)
), expected(game_id,source_id,fixture_state) AS (
 VALUES (105,5,'archived'),(106,7,'active')
), discrepancies AS (
 (SELECT * FROM findings EXCEPT ALL SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM findings)
)
SELECT CASE WHEN EXISTS(SELECT 1 FROM discrepancies) THEN 'FAIL' ELSE 'PASS' END AS retired_fixture_negative_regression,
 (SELECT count(*) FROM findings) AS expected_findings,
 (SELECT count(*) FROM referenced) AS fixture_references_checked;
