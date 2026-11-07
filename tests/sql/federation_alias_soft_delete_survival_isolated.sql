-- Rollback-only regression: a reviewed historical alias survives source soft-delete.
-- The source row remains for historical provenance; no game payload is rewritten.
BEGIN;
INSERT INTO public.opponent_historical_aliases
 (owner_id,historical_name,source_opponent_id,canonical_opponent_id,federation_club_id,reviewed_by,review_reason)
SELECT src.user_id,src.payload->>'opponentName',src.id,dst.id,src.federation_club_id,
 '00000000-0000-0000-0000-00000000a001'::uuid,'Reviewed isolated duplicate with historical fixtures'
FROM public.opponents src JOIN public.opponents dst
 ON src.user_id=dst.user_id AND src.federation_club_id=dst.federation_club_id
WHERE src.local_id='-910002' AND dst.local_id='-910001';
DO $$ BEGIN
 IF NOT FOUND THEN NULL; END IF;
 IF (SELECT count(*) FROM public.opponent_historical_aliases
     WHERE historical_name='Olivais "A"')<>1
 THEN RAISE EXCEPTION 'Historical alias was not inserted exactly once'; END IF;
END $$;
CREATE TEMP TABLE alias_game_snapshot ON COMMIT DROP AS
SELECT id,payload FROM public.games WHERE payload->>'opponent'='Olivais "A"';
UPDATE public.opponents SET deleted_at=now() WHERE local_id='-910002' AND deleted_at IS NULL;
DO $$ BEGIN
 IF (SELECT count(*) FROM public.opponents WHERE local_id='-910002' AND deleted_at IS NOT NULL)<>1
 THEN RAISE EXCEPTION 'Historical source was not soft-deleted'; END IF;
 IF EXISTS (
   SELECT 1 FROM alias_game_snapshot snap
   LEFT JOIN public.games g ON g.id=snap.id
   WHERE g.id IS NULL OR g.payload IS DISTINCT FROM snap.payload
 ) THEN RAISE EXCEPTION 'Historical game payload changed'; END IF;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$ DECLARE expected uuid; resolved uuid; fid uuid; BEGIN
 SELECT dst.id, dst.federation_club_id INTO expected,fid
 FROM public.opponents dst WHERE dst.local_id='-910001';
 SELECT public.resolve_historical_opponent_alias('Olivais "A"',fid) INTO resolved;
 IF resolved IS DISTINCT FROM expected THEN
  RAISE EXCEPTION 'Soft-deleted source must resolve to active canonical'; END IF;
 IF public.resolve_historical_opponent_alias('Olivais "A"',
    '461ac75e-a34c-46f9-8b45-8e4d982ca559'::uuid) IS NOT NULL
 THEN RAISE EXCEPTION 'Olivais Sul must remain distinct'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$ DECLARE fid uuid; BEGIN
 SELECT federation_club_id INTO fid FROM public.opponents WHERE local_id='-910001';
 IF public.resolve_historical_opponent_alias('Olivais "A"',fid) IS NOT NULL
 THEN RAISE EXCEPTION 'Cross-owner alias leak'; END IF;
END $$;
ROLLBACK;