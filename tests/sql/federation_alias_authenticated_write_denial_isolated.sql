-- Rollback-only authenticated historical-alias authorization regression.
-- Run against isolated Next Eleven Supabase only, never production.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE owner_a uuid := '00000000-0000-0000-0000-00000000a001';
DECLARE owner_b uuid := '00000000-0000-0000-0000-00000000a002';
DECLARE src uuid := '11087a52-a995-4b93-a4d3-784387879cb8';
DECLARE dst uuid := '11087a52-a995-4b93-a4d3-784387879cb9';
DECLARE fed uuid := '3b9dbcd6-a8e6-4057-ae97-68ae879d92f9';
DECLARE before_games integer;
BEGIN
  IF has_table_privilege('authenticated', 'public.opponent_historical_aliases', 'INSERT')
     OR has_table_privilege('authenticated', 'public.opponent_historical_aliases', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.opponent_historical_aliases', 'DELETE')
  THEN RAISE EXCEPTION 'Authenticated role unexpectedly can mutate reviewed aliases'; END IF;
  IF NOT has_table_privilege('authenticated', 'public.opponent_historical_aliases', 'SELECT')
  THEN RAISE EXCEPTION 'Owner-scoped alias SELECT grant missing'; END IF;
  IF EXISTS (SELECT 1 FROM public.opponent_historical_aliases WHERE owner_id <> auth.uid())
  THEN RAISE EXCEPTION 'User B can read another owner historical aliases'; END IF;
  IF public.resolve_historical_opponent_alias('Olivais "A"', '3b9dbcd6-a8e6-4057-ae97-68ae879d92f9') IS NOT NULL
  THEN RAISE EXCEPTION 'User B can resolve owner A reviewed alias'; END IF;
  SELECT count(*) INTO before_games FROM public.games;
  -- Even an owner-scoped client cannot create a purportedly reviewed mapping.
  BEGIN
    INSERT INTO public.opponent_historical_aliases
      (owner_id,historical_name,source_opponent_id,canonical_opponent_id,
       federation_club_id,reviewed_by,review_reason)
    VALUES (owner_a,'Olivais "A"',src,dst,fed,owner_a,
            'Forged administrator review attempt by user B');
    RAISE EXCEPTION 'UNEXPECTED_ALIAS_INSERT_ALLOWED';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF (SELECT count(*) FROM public.games) <> before_games
  THEN RAISE EXCEPTION 'Historical fixtures changed during authorization test'; END IF;
END $$;
ROLLBACK;
