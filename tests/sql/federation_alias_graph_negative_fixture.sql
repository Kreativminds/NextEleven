-- Read-only synthetic regression: three-node cycle, separate Olivais Sul,
-- and an unrelated valid direct canonical mapping. Expect 0 mismatches.
WITH RECURSIVE edges(owner_id,source_id,target_id) AS (
 VALUES ('owner-a','olivais-a','olivais'),
 ('owner-a','olivais','olivais-b'),
 ('owner-a','olivais-b','olivais-a'),
 ('owner-b','olivais-sul','sul-canonical'),
 ('owner-c','direct-source','direct-canonical')
), walks AS (
 SELECT owner_id,source_id,target_id,ARRAY[source_id,target_id] AS visited,
        (source_id=target_id) AS cycle,1 AS depth FROM edges
 UNION ALL
 SELECT w.owner_id,w.source_id,e.target_id,w.visited||e.target_id,
        e.target_id=ANY(w.visited),w.depth+1
 FROM walks w JOIN edges e ON e.owner_id=w.owner_id AND e.source_id=w.target_id
 WHERE NOT w.cycle AND w.depth<50
), actual AS (
 SELECT source_id,bool_or(cycle) AS cycle,bool_or(depth>1) AS chained
 FROM walks GROUP BY source_id
), expected(source_id,cycle,chained) AS (
 VALUES ('olivais-a',true,true),('olivais',true,true),
 ('olivais-b',true,true),('olivais-sul',false,false),
 ('direct-source',false,false)
), mismatches AS (
 (SELECT * FROM actual EXCEPT SELECT * FROM expected)
 UNION ALL
 (SELECT * FROM expected EXCEPT SELECT * FROM actual)
)
SELECT (SELECT count(*) FROM actual) AS tested_sources,
       (SELECT count(*) FROM mismatches) AS mismatches;
