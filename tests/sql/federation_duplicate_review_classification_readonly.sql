-- Original #10: classify federation duplicate groups by historical-name risk.
-- Read-only; never selects canonical opponent or authorizes deletion.
WITH active AS (
 SELECT user_id,federation_club_id,local_id,
        nullif(btrim(payload->>'opponentName'),'') AS name
 FROM public.opponents
 WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
), duplicate_groups AS (
 SELECT user_id,federation_club_id,count(*) AS member_count
 FROM active GROUP BY 1,2 HAVING count(*)>1
), members AS (
 SELECT a.*,g.member_count
 FROM active a JOIN duplicate_groups g USING(user_id,federation_club_id)
), game_names AS (
 SELECT user_id,nullif(btrim(payload->>'opponent'),'') AS name,count(*) AS fixtures
 FROM public.games WHERE deleted_at IS NULL
 GROUP BY 1,2
), annotated AS (
 SELECT m.*,coalesce(gn.fixtures,0) AS fixture_count,
        count(*) OVER (PARTITION BY m.user_id,m.federation_club_id,m.name) AS same_name_count
 FROM members m LEFT JOIN game_names gn ON gn.user_id=m.user_id AND gn.name=m.name
), group_risk AS (
 SELECT user_id,federation_club_id,max(member_count) AS members,
        count(*) FILTER (WHERE fixture_count>0) AS historical_name_members,
        count(*) FILTER (WHERE name IS NULL) AS unnamed_members,
        count(*) FILTER (WHERE local_id IS NULL) AS missing_local_ids,
        count(*) FILTER (WHERE fixture_count>0 AND same_name_count>1) AS ambiguous_fixture_name_members,
        sum(fixture_count) AS historical_fixture_name_matches
 FROM annotated GROUP BY 1,2
), classified AS (
 SELECT *,
 CASE WHEN unnamed_members>0 OR missing_local_ids>0 OR ambiguous_fixture_name_members>0
      THEN 'blocked_identity_integrity'
      WHEN historical_name_members>1 THEN 'requires_historical_alias_preservation'
      WHEN historical_name_members=1 THEN 'requires_single_historical_name_preservation'
      ELSE 'requires_manual_canonical_review'
 END AS review_class
 FROM group_risk
)
SELECT review_class,count(*) AS groups,sum(members) AS member_rows,
       sum(members-1) AS redundant_rows,
       sum(historical_fixture_name_matches) AS historical_fixture_name_matches
FROM classified GROUP BY review_class ORDER BY review_class;