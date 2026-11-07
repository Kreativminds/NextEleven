-- Synthetic read-only regression of fixture reference completeness gate.
-- Includes archived fixtures, cross-owner lookalikes and distinct Olivais Sul.
WITH opponents(id,user_id,historical_name) AS (
 VALUES (1,10,'Olivais A'),(2,10,'Olivais Sul'),
        (3,20,'CAC'),(4,30,'Cacém')
), games(id,user_id,historical_name,deleted_at) AS (
 VALUES (101,10,'Olivais A',NULL::timestamptz),
 (102,10,'Olivais Sul',now()),
 (103,10,'CAC',NULL::timestamptz),
 (104,20,'Olivais A',now()),
 (105,20,'CAC',NULL::timestamptz),
 (106,30,'Cacém',NULL::timestamptz),
 (107,10,NULL::text,now()),
 (108,10,' ',NULL::timestamptz)
), matches AS (
 SELECT g.id game_id,g.user_id owner_id,g.historical_name,g.deleted_at,
        count(o.id) matching_rows
 FROM games g LEFT JOIN opponents o
 ON o.user_id=g.user_id AND o.historical_name=g.historical_name
 GROUP BY g.id,g.user_id,g.historical_name,g.deleted_at
), findings AS (
 SELECT game_id, CASE WHEN nullif(btrim(historical_name),'') IS NULL
 THEN 'missing_fixture_opponent_name' ELSE 'no_owner_scoped_opponent_row'
 END AS finding
 FROM matches
 WHERE nullif(btrim(historical_name),'') IS NULL OR matching_rows=0
), expected(game_id,finding) AS (
 VALUES (103,'no_owner_scoped_opponent_row'),(104,'no_owner_scoped_opponent_row'),
 (107,'missing_fixture_opponent_name'),(108,'missing_fixture_opponent_name')
), differences AS (
 (SELECT * FROM findings EXCEPT ALL SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM findings)
)
SELECT CASE WHEN EXISTS(SELECT 1 FROM differences) THEN 'FAIL' ELSE 'PASS' END result,
 (SELECT count(*) FROM findings) findings_count,
 (SELECT count(*) FROM games) fixtures_checked;
