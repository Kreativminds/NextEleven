-- Read-only, account-scoped season integrity baseline.
-- seasonId is NOT globally unique: always join on user_id and seasonId.
WITH active_seasons AS (
 SELECT user_id, payload->>'seasonId' AS season_id,
        payload->>'seasonName' AS season_name
 FROM public.seasons WHERE deleted_at IS NULL
), active_games AS (
 SELECT id,user_id,payload FROM public.games WHERE deleted_at IS NULL
)
SELECT s.season_name,
       count(DISTINCT s.user_id) AS accounts,
       count(DISTINCT g.id) AS games,
       count(DISTINCT g.id) FILTER (WHERE g.payload->>'homeAway'='Home') AS home_games,
       count(DISTINCT g.id) FILTER (WHERE g.payload->>'homeAway'='Away') AS away_games
FROM active_seasons s
LEFT JOIN active_games g ON g.user_id=s.user_id
 AND g.payload->>'seasonId'=s.season_id
GROUP BY s.season_name ORDER BY s.season_name;

-- Immutable before/after fingerprint for 2026/27 game payloads, per account.
-- Do not print account IDs in public reporting.
WITH live_season AS (
 SELECT user_id,payload->>'seasonId' AS season_id
 FROM public.seasons WHERE deleted_at IS NULL AND payload->>'seasonName'='2026/27'
)
SELECT count(*) AS games,
       md5(coalesce(string_agg(g.id::text||':'||g.payload::text, '|' ORDER BY g.id::text),'')) AS games_fingerprint
FROM public.games g JOIN live_season s ON s.user_id=g.user_id
 AND s.season_id=g.payload->>'seasonId'
WHERE g.deleted_at IS NULL;
