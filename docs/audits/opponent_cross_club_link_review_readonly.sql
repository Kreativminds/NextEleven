-- Read-only inspection of possible cross-club federation links.
-- A shared federation_club_id is not proof that distinct names identify the same club.
SELECT o.payload->>'opponentName' AS opponent_name,
       f.official_name AS linked_federation_club,
       count(*) AS active_records,
       count(distinct o.user_id) AS distinct_accounts
FROM public.opponents o
JOIN public.federation_clubs f ON f.id=o.federation_club_id
WHERE o.deleted_at IS NULL
  AND (o.payload->>'opponentName' ILIKE '%Olivais%' OR f.official_name ILIKE '%Olivais%')
GROUP BY 1,2 ORDER BY 1,2;

SELECT official_name FROM public.federation_clubs
WHERE official_name ILIKE '%Olivais%' ORDER BY official_name;
-- Never UPDATE federation_club_id based only on text similarity.
