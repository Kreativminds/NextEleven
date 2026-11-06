-- 2026/27 non-destructive integrity fingerprint across dependent tables.
-- Snapshot each result before any migration and compare after, rejecting any mismatch.
-- The 'players' dataset is account-wide because player season membership is not
-- established by this query; retaining it protects profiles from collateral writes.
WITH live AS (
 SELECT user_id,payload->>'seasonId' AS sid
 FROM public.seasons WHERE deleted_at IS NULL AND payload->>'seasonName'='2026/27'
), protected_rows AS (
 SELECT 'seasons' AS dataset,t.id,t.payload FROM public.seasons t
 JOIN live s ON t.user_id=s.user_id AND t.payload->>'seasonId'=s.sid
 WHERE t.deleted_at IS NULL
 UNION ALL SELECT 'games',t.id,t.payload FROM public.games t
 JOIN live s ON t.user_id=s.user_id AND t.payload->>'seasonId'=s.sid
 WHERE t.deleted_at IS NULL
 UNION ALL SELECT 'season_calendar_events',t.id,t.payload FROM public.season_calendar_events t
 JOIN live s ON t.user_id=s.user_id AND t.payload->>'seasonId'=s.sid
 WHERE t.deleted_at IS NULL
 UNION ALL SELECT 'game_players',t.id,t.payload FROM public.game_players t
 JOIN live s ON t.user_id=s.user_id AND t.payload->>'seasonId'=s.sid
 WHERE t.deleted_at IS NULL
 UNION ALL SELECT 'player_game_stats',t.id,t.payload FROM public.player_game_stats t
 JOIN live s ON t.user_id=s.user_id AND t.payload->>'seasonId'=s.sid
 WHERE t.deleted_at IS NULL
 UNION ALL SELECT 'players_account_wide',t.id,t.payload FROM public.players t
 JOIN (SELECT DISTINCT user_id FROM live) s ON t.user_id=s.user_id
 WHERE t.deleted_at IS NULL
)
SELECT dataset,count(*) AS records,
       md5(coalesce(string_agg(id::text||':'||payload::text,'|' ORDER BY id::text),'')) AS payload_fingerprint
FROM protected_rows GROUP BY dataset ORDER BY dataset;
