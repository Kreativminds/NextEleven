-- Original #20: read-only check that archived and active fixtures can resolve
-- historical opponent names after a source opponent is soft-deleted.
-- Never modify fixtures; zero rows means no detected orphaned retired source.
WITH retired_sources AS (
 SELECT o.id AS source_id, o.user_id AS owner_id,
        o.payload->>'opponentName' AS historical_name, o.federation_club_id
 FROM public.opponents o WHERE o.deleted_at IS NOT NULL
), referenced AS (
 SELECT r.*, g.id AS game_id, g.deleted_at AS game_deleted_at
 FROM retired_sources r
 JOIN public.games g ON g.user_id=r.owner_id
  AND g.payload->>'opponent'=r.historical_name
), valid_alias AS (
 SELECT r.game_id,r.source_id,a.id AS alias_id
 FROM referenced r
 JOIN public.opponent_historical_aliases a
   ON a.owner_id=r.owner_id AND a.source_opponent_id=r.source_id
   AND a.historical_name=r.historical_name
   AND a.federation_club_id IS NOT DISTINCT FROM r.federation_club_id
 JOIN public.opponents canonical
   ON canonical.id=a.canonical_opponent_id
   AND canonical.user_id=r.owner_id AND canonical.deleted_at IS NULL
   AND canonical.federation_club_id IS NOT DISTINCT FROM r.federation_club_id
)
SELECT r.owner_id,r.game_id,r.source_id,r.historical_name,
       CASE WHEN r.game_deleted_at IS NULL THEN 'active' ELSE 'archived' END AS fixture_state,
       'retired_source_without_valid_reviewed_alias' AS finding
FROM referenced r
WHERE NOT EXISTS (
 SELECT 1 FROM valid_alias a WHERE a.game_id=r.game_id AND a.source_id=r.source_id
)
ORDER BY r.owner_id,r.game_id,r.source_id;
