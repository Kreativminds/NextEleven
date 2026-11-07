-- Read-only, isolated project only. Do not print or export bearer share tokens.
-- This checks structural hygiene, NOT cryptographic unpredictability.
DO $$
DECLARE total_count integer; unique_count integer; weak_count integer;
BEGIN
 SELECT count(*), count(DISTINCT share_token),
        count(*) FILTER (WHERE share_token IS NULL OR length(btrim(share_token)) < 24)
 INTO total_count, unique_count, weak_count
 FROM public.team_share_links;
 IF total_count = 0 THEN
   RAISE EXCEPTION 'No share links: token inventory not exercised';
 END IF;
 IF unique_count <> total_count THEN
   RAISE EXCEPTION 'Share-token collision or missing token detected';
 END IF;
 IF weak_count <> 0 THEN
   RAISE EXCEPTION 'Missing or shorter-than-24-character share token detected';
 END IF;
END $$;
-- Aggregate-only evidence, never expose token values.
SELECT count(*) AS total_links,
 count(*) FILTER (WHERE enabled) AS enabled_links,
 count(DISTINCT share_token) AS unique_tokens,
 min(length(share_token)) AS minimum_length,
 max(length(share_token)) AS maximum_length
FROM public.team_share_links;
