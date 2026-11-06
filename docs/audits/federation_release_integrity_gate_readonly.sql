-- Read-only federation migration acceptance gate. Run against production before any release.
-- A returned failed_checks > 0 blocks the migration.
WITH game_matches AS (
 SELECT g.id,g.user_id,g.payload->>'opponent' original_name,
        count(o.id) matched,
        count(o.id) FILTER (WHERE o.federation_club_id IS NOT NULL) federation_linked
 FROM public.games g LEFT JOIN public.opponents o
 ON o.user_id=g.user_id AND o.deleted_at IS NULL
 AND o.payload->>'opponentName'=g.payload->>'opponent'
 WHERE g.deleted_at IS NULL GROUP BY g.id,g.user_id,g.payload->>'opponent'
), identity AS (
 SELECT count(*) FILTER (WHERE lower(official_name)='olivais') olivais,
        count(*) FILTER (WHERE lower(official_name)='olivais sul') olivais_sul,
        count(DISTINCT id) FILTER (WHERE lower(official_name) IN ('olivais','olivais sul')) distinct_clubs
 FROM public.federation_clubs
)
SELECT (SELECT count(*) FROM game_matches) active_games,
       (SELECT count(*) FROM game_matches WHERE matched<>1) ambiguous_or_missing_games,
       (SELECT count(*) FROM game_matches WHERE federation_linked=1) linked_games,
       (SELECT count(*) FROM game_matches WHERE federation_linked=0) pending_games,
       (SELECT olivais FROM identity) olivais_catalogue_rows,
       (SELECT olivais_sul FROM identity) olivais_sul_catalogue_rows,
       (SELECT distinct_clubs FROM identity) distinct_olivais_identities,
       (SELECT count(*) FROM game_matches WHERE matched<>1)
       + (SELECT CASE WHEN olivais=1 AND olivais_sul=1 AND distinct_clubs=2 THEN 0 ELSE 1 END FROM identity)
       AS failed_checks;
