-- Next Eleven: read-only opponent reconciliation diagnostics
-- Run using SELECT privileges only. No mutations or identity inference.
-- 1. Coverage by account (do not export user identifiers publicly).
SELECT count(*) AS active_opponents,
       count(*) FILTER (WHERE federation_club_id IS NULL) AS unlinked,
       count(*) FILTER (WHERE federation_club_id IS NOT NULL) AS linked,
       count(DISTINCT federation_club_id) AS linked_catalogue_clubs
FROM public.opponents WHERE deleted_at IS NULL;

-- 2. Catalogue venue completeness; no inferred geocoding.
SELECT count(*) AS clubs,
       count(*) FILTER (WHERE nullif(btrim(venue_lat),'') IS NOT NULL) AS latitude_present,
       count(*) FILTER (WHERE nullif(btrim(venue_lng),'') IS NOT NULL) AS longitude_present,
       count(*) FILTER (WHERE nullif(btrim(map_url),'') IS NOT NULL) AS map_url_present
FROM public.federation_clubs;

-- 3. Merge-plan grouping diagnostics. A group_size=1 is not a merge instruction.
SELECT group_size, count(*) AS rows_in_plan, sum(game_count) AS referenced_games
FROM public.opponents_merge_plan_tmp GROUP BY group_size ORDER BY group_size;

-- 4. RLS policy inventory for user-owned and public catalogue entities.
SELECT tablename, policyname, cmd, roles, qual, with_check
FROM pg_policies WHERE schemaname='public'
AND tablename IN ('opponents','team_alias_mappings','federation_clubs','federation_club_competitions','federation_club_venues','opponents_merge_plan_tmp')
ORDER BY tablename, policyname;
