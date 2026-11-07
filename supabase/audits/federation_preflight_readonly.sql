-- Read-only production preflight before ANY federation reconciliation migration.
-- Abort deployment if any result is unexpected. No rows modified.
WITH game_matches AS (
 SELECT g.id,g.user_id,g.payload->>'opponent' historical_name,
        count(o.id) match_count,
        count(o.federation_club_id) federation_match_count
 FROM public.games g LEFT JOIN public.opponents o
   ON o.user_id=g.user_id AND o.deleted_at IS NULL
  AND o.payload->>'opponentName'=g.payload->>'opponent'
 WHERE g.deleted_at IS NULL GROUP BY g.id,g.user_id,g.payload->>'opponent'
), duplicate_clubs AS (
 SELECT user_id,federation_club_id,count(*) records
 FROM public.opponents WHERE deleted_at IS NULL AND federation_club_id IS NOT NULL
 GROUP BY user_id,federation_club_id HAVING count(*)>1
)
SELECT 'active_games' metric,count(*)::bigint value FROM game_matches
UNION ALL SELECT 'unmatched_or_ambiguous_games',count(*) FROM game_matches WHERE match_count<>1
UNION ALL SELECT 'games_with_federation_id',count(*) FROM game_matches WHERE match_count=1 AND federation_match_count=1
UNION ALL SELECT 'games_without_federation_id',count(*) FROM game_matches WHERE match_count=1 AND federation_match_count=0
UNION ALL SELECT 'duplicate_federation_groups',count(*) FROM duplicate_clubs
UNION ALL SELECT 'redundant_opponent_records',coalesce(sum(records-1),0) FROM duplicate_clubs
ORDER BY metric;

-- Confirm separate club identities: these UUIDs must remain distinct.
SELECT id,official_name FROM public.federation_clubs
WHERE id IN ('2048d15c-37b2-4d9b-8be6-c063dc57378d','461ac75e-a34c-46f9-8b45-8e4d982ca559');

-- Baseline current-season row counts, by user, without revealing account details.
SELECT 'seasons' entity,count(*) n FROM public.seasons WHERE deleted_at IS NULL
UNION ALL SELECT 'games',count(*) FROM public.games WHERE deleted_at IS NULL
UNION ALL SELECT 'game_players',count(*) FROM public.game_players WHERE deleted_at IS NULL
UNION ALL SELECT 'player_game_stats',count(*) FROM public.player_game_stats WHERE deleted_at IS NULL
UNION ALL SELECT 'season_calendar_events',count(*) FROM public.season_calendar_events WHERE deleted_at IS NULL;
