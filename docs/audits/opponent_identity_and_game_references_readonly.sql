-- Read-only opponent identity and historical reference diagnostics.
-- Never automatically merge by normalized name or discard age-group distinctions.
WITH names AS (
 SELECT user_id,lower(regexp_replace(btrim(payload->>'opponentName'),'\\s+',' ','g')) AS normalized_name,
        count(*) AS records
 FROM public.opponents WHERE deleted_at IS NULL GROUP BY user_id,2
)
SELECT count(*) FILTER(WHERE records>1) AS duplicate_exact_name_groups,
       coalesce(sum(records) FILTER(WHERE records>1),0) AS rows_in_exact_name_groups
FROM names;

SELECT count(*) AS active_games,
       count(*) FILTER(WHERE payload ? 'opponent') AS with_opponent_reference,
       count(*) FILTER(WHERE nullif(btrim(payload->>'opponentMapUrl'),'') IS NOT NULL) AS with_opponent_map_url
FROM public.games WHERE deleted_at IS NULL;

SELECT count(*) AS active_opponents,
       count(*) FILTER(WHERE nullif(btrim(payload->>'ageGroup'),'') IS NOT NULL) AS with_age_group,
       count(*) FILTER(WHERE nullif(btrim(payload->>'mapUrl'),'') IS NOT NULL) AS with_map_url,
       count(*) FILTER(WHERE federation_club_id IS NULL) AS unlinked_to_federation
FROM public.opponents WHERE deleted_at IS NULL;
