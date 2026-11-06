-- Read-only acceptance checks for aliases, home/away fixtures and federation linkage.
SELECT payload->>'homeAway' AS home_away,count(*) AS games
FROM public.games WHERE deleted_at IS NULL GROUP BY 1 ORDER BY 1;

SELECT count(*) AS active_alias_mapping_records
FROM public.team_alias_mappings WHERE deleted_at IS NULL;

SELECT count(*) AS active_opponents,
 count(*) FILTER(WHERE federation_club_id IS NULL) AS unlinked,
 count(*) FILTER(WHERE federation_club_id IS NOT NULL) AS linked
FROM public.opponents WHERE deleted_at IS NULL;

SELECT jsonb_object_keys(payload) AS alias_payload_field,count(*) AS records
FROM public.team_alias_mappings WHERE deleted_at IS NULL GROUP BY 1 ORDER BY 1;
-- Alias records are season/competition scoped. Do not treat them as club ID remapping.
