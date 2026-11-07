-- Post-migration read-only verification. Run only where the link table exists.
-- Zero invalid links and an enabled validation trigger are required.
SELECT count(*) AS invalid_links
FROM public.game_opponent_federation_links l
LEFT JOIN public.games g ON g.id=l.game_id
LEFT JOIN public.opponents o ON o.id=l.opponent_id
WHERE g.id IS NULL OR o.id IS NULL OR g.deleted_at IS NOT NULL
 OR o.deleted_at IS NOT NULL OR l.user_id IS DISTINCT FROM g.user_id
 OR o.user_id IS DISTINCT FROM g.user_id
 OR l.original_opponent_name IS DISTINCT FROM g.payload->>'opponent'
 OR l.original_opponent_name IS DISTINCT FROM o.payload->>'opponentName'
 OR l.federation_club_id IS DISTINCT FROM o.federation_club_id;

SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid='public.game_opponent_federation_links'::regclass
 AND tgname='validate_game_opponent_federation_link' AND NOT tgisinternal;
