-- Synthetic read-only regression for historical opponent name ambiguity.
-- Two Olivais A rows belonging to one owner are ambiguous; Olivais Sul
-- is distinct. Same-name rows in a different owner must not contaminate.
WITH opponents(id,user_id,historical_name,federation_club_id) AS (
 VALUES (1,10,'Olivais A',100),(2,10,'Olivais A',100),
 (3,10,'Olivais Sul',200),(4,20,'Olivais A',100),
 (5,20,'Olivais A',100),(6,30,'Olivais A',100)
), games(id,user_id,opponent,deleted_at) AS (
 VALUES (101,10,'Olivais A',NULL::timestamptz),
 (102,10,'Olivais A',now()),(103,10,'Olivais Sul',NULL::timestamptz),
 (104,20,'Olivais A',NULL::timestamptz),(105,30,'Olivais A',NULL::timestamptz)
), name_candidates AS (
 SELECT user_id,historical_name,count(*) AS opponent_rows
 FROM opponents GROUP BY user_id,historical_name HAVING count(*)>1
), findings AS (
 SELECT g.id AS game_id, n.opponent_rows
 FROM games g JOIN name_candidates n
 ON g.user_id=n.user_id AND g.opponent=n.historical_name
), expected(game_id,opponent_rows) AS (
 VALUES (101,2::bigint),(102,2::bigint),(104,2::bigint)
), discrepancies AS (
 (SELECT * FROM findings EXCEPT ALL SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT ALL SELECT * FROM findings)
)
SELECT CASE WHEN EXISTS(SELECT 1 FROM discrepancies) THEN 'FAIL' ELSE 'PASS' END AS result,
 (SELECT count(*) FROM findings) AS ambiguous_fixture_count,
 (SELECT count(*) FROM games) AS fixtures_checked;
