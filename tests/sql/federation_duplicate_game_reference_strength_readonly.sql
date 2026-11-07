-- Original #10: read-only audit of actual historical game reference strength.
-- Does not assume a game name match is a safe foreign key or deletion approval.
-- Scoped to the same owner and verified federation club; output is aggregate only.
WITH duplicate_groups AS (
 SELECT user_id,federation_club_id
 FROM public.opponents WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
 GROUP BY 1,2 HAVING count(*)>1
), members AS (
 SELECT o.user_id,o.federation_club_id,o.local_id,
        nullif(btrim(o.payload->>'opponentName'),'') AS name
 FROM public.opponents o JOIN duplicate_groups d USING(user_id,federation_club_id)
 WHERE o.deleted_at IS NULL
), games_with_members AS (
 SELECT g.id AS game_id,g.user_id,m.federation_club_id,m.local_id,m.name,
        nullif(btrim(g.payload->>'opponent'),'') AS game_name,
        nullif(btrim(g.payload->>'opponentId'),'') AS game_local_id,
        (g.payload->>'opponent'=m.name) AS name_match,
        (g.payload->>'opponentId'=m.local_id::text) AS id_match
 FROM public.games g JOIN members m ON m.user_id=g.user_id
  AND (g.payload->>'opponent'=m.name OR g.payload->>'opponentId'=m.local_id::text)
 WHERE g.deleted_at IS NULL
), per_game AS (
 SELECT game_id,user_id,federation_club_id,
        count(*) AS candidate_members,
        bool_or(name_match) AS any_name_match,
        bool_or(id_match) AS any_id_match,
        bool_or(game_local_id IS NOT NULL) AS any_explicit_id,
        bool_or(game_local_id IS NOT NULL AND name_match AND NOT id_match)
          AS conflicting_name_and_id,
        bool_or(game_name IS NOT NULL AND id_match AND NOT name_match)
          AS conflicting_id_and_name
 FROM games_with_members GROUP BY game_id,user_id,federation_club_id
)
SELECT count(*) AS affected_games,
       count(*) FILTER(WHERE any_explicit_id) AS games_with_explicit_id,
       count(*) FILTER(WHERE NOT any_explicit_id) AS games_name_only,
       count(*) FILTER(WHERE candidate_members>1) AS ambiguous_member_matches,
       count(*) FILTER(WHERE conflicting_name_and_id OR conflicting_id_and_name)
          AS conflicting_name_id_evidence
FROM per_game;
-- If games_name_only > 0, preserve historical names and obtain reviewed mapping.
-- Never rewrite fixtures, select canonical IDs or delete opponents from this audit.
