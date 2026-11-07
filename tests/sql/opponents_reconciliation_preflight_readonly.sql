-- Opponent reconciliation preflight. READ ONLY. No merge or mutation.
-- Run against production before planning canonical links.
WITH active AS (
 SELECT id, user_id, family_id, federation_club_id,
        nullif(trim(payload->>'opponentName'),'') AS name
 FROM public.opponents WHERE deleted_at IS NULL
), duplicate_names AS (
 SELECT user_id, family_id, lower(name) AS name_key,
        count(*) AS rows_in_group, array_agg(id ORDER BY id) AS opponent_ids
 FROM active WHERE name IS NOT NULL
 GROUP BY user_id, family_id, lower(name)
 HAVING count(*) > 1
)
SELECT 'active_opponents' AS metric, count(*)::text AS value FROM active
UNION ALL SELECT 'linked', count(*)::text FROM active WHERE federation_club_id IS NOT NULL
UNION ALL SELECT 'unlinked', count(*)::text FROM active WHERE federation_club_id IS NULL
UNION ALL SELECT 'duplicate_name_groups_same_owner', count(*)::text FROM duplicate_names
UNION ALL SELECT 'duplicate_name_rows_same_owner', coalesce(sum(rows_in_group),0)::text FROM duplicate_names
UNION ALL SELECT 'federation_clubs', count(*)::text FROM public.federation_clubs
UNION ALL SELECT 'federation_registrations', count(*)::text FROM public.federation_club_competitions
UNION ALL SELECT 'venues', count(*)::text FROM public.federation_club_venues
UNION ALL SELECT 'clubs_with_gps', count(*)::text FROM public.federation_clubs WHERE nullif(trim(venue_lat),'') IS NOT NULL AND nullif(trim(venue_lng),'') IS NOT NULL
ORDER BY metric;

-- Review unlinked records. Do not auto-link on name similarity.
SELECT o.id, o.user_id, o.family_id,
       o.payload->>'opponentName' AS opponent_name,
       c.id AS exact_federation_id, c.official_name AS exact_federation_name
FROM public.opponents o
LEFT JOIN public.federation_clubs c
 ON lower(trim(o.payload->>'opponentName')) = lower(trim(c.official_name))
WHERE o.deleted_at IS NULL AND o.federation_club_id IS NULL
ORDER BY opponent_name, o.user_id, o.id;

-- Duplicate names are scoped by owner and family. This is only a candidate list.
WITH active AS (
 SELECT id,user_id,family_id,nullif(trim(payload->>'opponentName'),'') AS name
 FROM public.opponents WHERE deleted_at IS NULL
)
SELECT user_id,family_id,lower(name) AS name_key,count(*) AS copies,
       array_agg(id ORDER BY id) AS candidate_ids
FROM active WHERE name IS NOT NULL
GROUP BY user_id,family_id,lower(name)
HAVING count(*) > 1
ORDER BY copies DESC,name_key;
