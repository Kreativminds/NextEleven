-- Original #10: read-only duplicate-group canonical selection safety audit.
-- Does NOT select or apply a canonical row; reports blockers for human review.
-- All grouping is scoped by user_id and verified federation_club_id.
-- Opponent names and account IDs are deliberately omitted from output.
WITH active AS (
 SELECT id,user_id,local_id,federation_club_id,
        nullif(btrim(payload->>'opponentName'),'') AS opponent_name,
        created_at
 FROM public.opponents
 WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
),
groups AS (
 SELECT user_id,federation_club_id,count(*) AS n
 FROM active GROUP BY user_id,federation_club_id HAVING count(*)>1
),
members AS (
 SELECT a.*, g.n FROM active a JOIN groups g USING(user_id,federation_club_id)
),
game_names AS (
 SELECT user_id,nullif(btrim(payload->>'opponent'),'') AS opponent_name,
        count(*) AS fixtures
 FROM public.games WHERE deleted_at IS NULL
 GROUP BY user_id,nullif(btrim(payload->>'opponent'),'')
),
member_evidence AS (
 SELECT m.*,coalesce(gn.fixtures,0) AS fixture_count,
        count(*) OVER (PARTITION BY m.user_id,m.federation_club_id,m.opponent_name) AS same_name_members
 FROM members m LEFT JOIN game_names gn
  ON gn.user_id=m.user_id AND gn.opponent_name=m.opponent_name
),
group_evidence AS (
 SELECT user_id,federation_club_id,max(n) AS members,
        sum(fixture_count) AS matched_fixtures,
        count(*) FILTER (WHERE fixture_count>0) AS fixture_referenced_members,
        count(*) FILTER (WHERE opponent_name IS NULL) AS unnamed_members,
        count(*) FILTER (WHERE same_name_members>1 AND fixture_count>0) AS ambiguous_name_members,
        count(*) FILTER (WHERE local_id IS NULL) AS missing_local_ids
 FROM member_evidence GROUP BY user_id,federation_club_id
)
SELECT count(*) AS duplicate_groups,
       coalesce(sum(members),0) AS duplicate_members,
       coalesce(sum(members-1),0) AS redundant_rows,
       coalesce(sum(matched_fixtures),0) AS matched_fixture_references,
       count(*) FILTER (WHERE fixture_referenced_members>1) AS groups_with_multiple_historical_names_in_use,
       count(*) FILTER (WHERE fixture_referenced_members=0) AS groups_with_no_active_fixture_name_match,
       count(*) FILTER (WHERE unnamed_members>0) AS groups_with_unnamed_members,
       count(*) FILTER (WHERE ambiguous_name_members>0) AS groups_with_ambiguous_fixture_names,
       count(*) FILTER (WHERE missing_local_ids>0) AS groups_with_missing_local_ids
FROM group_evidence;
-- Do not infer canonical identity from fixture counts or created_at.
-- A historical name match is not an opponent foreign key or deletion authority.
-- Olivais Sul and SL Olivais must never be collapsed across federation IDs.
