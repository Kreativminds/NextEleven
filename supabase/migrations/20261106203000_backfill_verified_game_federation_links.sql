-- Backfill only verified, exact, account-scoped game/opponent matches.
-- Requires 20261106200000_game_opponent_federation_links.sql.
-- No games, opponents, season, player or calendar records are changed.
DO $$
DECLARE eligible_count bigint; inserted_count bigint; mismatch_count bigint;
BEGIN
  -- Do not proceed if a game has no matching opponent or multiple matches.
  WITH matches AS (
    SELECT g.id, count(o.id) n
    FROM public.games g LEFT JOIN public.opponents o
      ON o.user_id=g.user_id AND o.deleted_at IS NULL
      AND o.payload->>'opponentName'=g.payload->>'opponent'
    WHERE g.deleted_at IS NULL GROUP BY g.id
  ) SELECT count(*) INTO mismatch_count FROM matches WHERE n<>1;
  IF mismatch_count<>0 THEN
    RAISE EXCEPTION 'Federation link backfill blocked: % unmatched or ambiguous games', mismatch_count;
  END IF;

  SELECT count(*) INTO eligible_count
  FROM public.games g JOIN public.opponents o
    ON o.user_id=g.user_id AND o.deleted_at IS NULL
    AND o.payload->>'opponentName'=g.payload->>'opponent'
  WHERE g.deleted_at IS NULL AND o.federation_club_id IS NOT NULL;

  -- Existing links are immutable. A changed source identity requires review.
  SELECT count(*) INTO mismatch_count
  FROM public.game_opponent_federation_links l
  JOIN public.games g ON g.id=l.game_id
  JOIN public.opponents o ON o.user_id=g.user_id AND o.deleted_at IS NULL
    AND o.payload->>'opponentName'=g.payload->>'opponent'
  WHERE l.user_id IS DISTINCT FROM g.user_id
    OR l.opponent_id IS DISTINCT FROM o.id
    OR l.federation_club_id IS DISTINCT FROM o.federation_club_id
    OR l.original_opponent_name IS DISTINCT FROM g.payload->>'opponent';
  IF mismatch_count<>0 THEN
    RAISE EXCEPTION 'Federation link backfill blocked: % existing links conflict with source', mismatch_count;
  END IF;

  INSERT INTO public.game_opponent_federation_links
    (game_id,user_id,opponent_id,federation_club_id,original_opponent_name)
  SELECT g.id,g.user_id,o.id,o.federation_club_id,g.payload->>'opponent'
  FROM public.games g JOIN public.opponents o
    ON o.user_id=g.user_id AND o.deleted_at IS NULL
    AND o.payload->>'opponentName'=g.payload->>'opponent'
  WHERE g.deleted_at IS NULL AND o.federation_club_id IS NOT NULL
  ON CONFLICT (game_id) DO NOTHING;
  GET DIAGNOSTICS inserted_count = ROW_COUNT;

  SELECT count(*) INTO mismatch_count
  FROM public.games g JOIN public.opponents o
    ON o.user_id=g.user_id AND o.deleted_at IS NULL
    AND o.payload->>'opponentName'=g.payload->>'opponent'
  LEFT JOIN public.game_opponent_federation_links l ON l.game_id=g.id
  WHERE g.deleted_at IS NULL AND o.federation_club_id IS NOT NULL
    AND (l.game_id IS NULL OR l.federation_club_id<>o.federation_club_id
      OR l.opponent_id<>o.id OR l.original_opponent_name<>g.payload->>'opponent');
  IF mismatch_count<>0 THEN
    RAISE EXCEPTION 'Federation link backfill verification failed for % games', mismatch_count;
  END IF;
  RAISE NOTICE 'Federation links verified: % eligible, % newly inserted', eligible_count, inserted_count;
END $$;
