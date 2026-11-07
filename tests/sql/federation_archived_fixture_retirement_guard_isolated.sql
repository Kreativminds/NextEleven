-- Original #10: archived games still require reviewed alias before retirement.
-- Uses isolated -910002 Olivais A fixture. No persistent changes.
BEGIN;
UPDATE public.games SET deleted_at=now()
 WHERE user_id='00000000-0000-0000-0000-00000000a001'::uuid
   AND payload->>'opponent'='Olivais "A"' AND deleted_at IS NULL;
DO $$
DECLARE n integer;
BEGIN
 SELECT count(*) INTO n FROM public.games
 WHERE user_id='00000000-0000-0000-0000-00000000a001'::uuid
 AND payload->>'opponent'='Olivais "A"' AND deleted_at IS NOT NULL;
 IF n<1 THEN RAISE EXCEPTION 'Missing archived-only fixture test data'; END IF;
 IF EXISTS (SELECT 1 FROM public.games WHERE user_id='00000000-0000-0000-0000-00000000a001'::uuid
 AND payload->>'opponent'='Olivais "A"' AND deleted_at IS NULL)
 THEN RAISE EXCEPTION 'Fixture must be archived-only'; END IF;
 IF EXISTS (SELECT 1 FROM public.opponent_historical_aliases
 WHERE source_opponent_id=(SELECT id FROM public.opponents WHERE local_id='-910002'))
 THEN RAISE EXCEPTION 'Fixture already has alias; negative test invalid'; END IF;
 BEGIN
   UPDATE public.opponents SET deleted_at=now()
    WHERE local_id='-910002' AND deleted_at IS NULL;
   RAISE EXCEPTION 'UNEXPECTED_RETIREMENT_SUCCESS';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM='UNEXPECTED_RETIREMENT_SUCCESS' THEN RAISE; END IF;
   IF position('Historical fixture references require a reviewed alias' IN SQLERRM)=0
   THEN RAISE EXCEPTION 'Wrong retirement rejection: %',SQLERRM; END IF;
 END;
 IF EXISTS (SELECT 1 FROM public.opponents WHERE local_id='-910002' AND deleted_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Archived fixture source was retired'; END IF;
END $$;
ROLLBACK;
