-- Original tasks #2 and #10: read-only duplicate federation identity preflight.
-- No writes, no automatic canonical selection and no historical fixture changes.
-- Execute with SELECT-only access. Aggregate output deliberately omits account IDs.
WITH active_opponents AS (
 SELECT id,user_id,local_id,payload->>'opponentName' AS historical_name,
        federation_club_id,created_at
 FROM public.opponents
 WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
),
duplicate_groups AS (
 SELECT user_id,federation_club_id,count(*) AS member_count
 FROM active_opponents GROUP BY user_id,federation_club_id HAVING count(*)>1
),
members AS (
 SELECT a.*,d.member_count
 FROM active_opponents a
 JOIN duplicate_groups d USING(user_id,federation_club_id)
),
fixture_refs AS (
 SELECT m.id AS opponent_id,count(g.id) AS fixture_name_matches
 FROM members m
 LEFT JOIN public.games g ON g.user_id=m.user_id
  AND g.deleted_at IS NULL
  AND g.payload->>'opponent'=m.historical_name
 GROUP BY m.id
),
summary AS (
 SELECT (SELECT count(*) FROM duplicate_groups) AS duplicate_identity_groups,
        (SELECT coalesce(sum(member_count-1),0) FROM duplicate_groups) AS redundant_opponent_rows,
        (SELECT count(*) FROM members) AS member_rows,
        (SELECT coalesce(sum(fixture_name_matches),0) FROM fixture_refs) AS historical_fixture_name_matches,
        (SELECT count(*) FROM members m WHERE m.historical_name IS NULL OR btrim(m.historical_name)='') AS unnamed_members
)
SELECT * FROM summary;
-- IMPORTANT: fixture_name_matches is a name-based impact inventory, NOT a safe
-- deletion/migration list. Confirm account ownership, registration and historic
-- references individually. Olivais Sul must remain separate from SL Olivais.
