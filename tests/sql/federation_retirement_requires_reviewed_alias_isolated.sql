-- Isolated only. No permanent data changes.
-- Verify that a historical opponent cannot be retired without a reviewed alias.
BEGIN;
DO $$
DECLARE source_id uuid; before_games integer;
BEGIN
 SELECT id INTO source_id FROM public.opponents WHERE local_id='-910002' AND deleted_at IS NULL;
 IF source_id IS NULL THEN RAISE EXCEPTION 'Missing isolated duplicate source fixture'; END IF;
 SELECT count(*) INTO before_games FROM public.games g
 JOIN public.opponents o ON o.user_id=g.user_id
 WHERE o.id=source_id AND g.deleted_at IS NULL
 AND g.payload->>'opponent'=o.payload->>'opponentName';
 IF before_games=0 THEN RAISE EXCEPTION 'Historical game fixture missing; guard test would be meaningless'; END IF;
 IF EXISTS(SELECT 1 FROM public.opponent_historical_aliases WHERE source_opponent_id=source_id)
 THEN RAISE EXCEPTION 'Source already has reviewed alias; negative case cannot be tested'; END IF;
 BEGIN
   UPDATE public.opponents SET deleted_at=now() WHERE id=source_id;
   RAISE EXCEPTION 'UNEXPECTED_RETIREMENT_ALLOWED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM='UNEXPECTED_RETIREMENT_ALLOWED' THEN RAISE; END IF;
   IF position('Historical fixture references require a reviewed alias' in SQLERRM)=0
   THEN RAISE EXCEPTION 'Unexpected retirement failure: %',SQLERRM; END IF;
 END;
 IF EXISTS(SELECT 1 FROM public.opponents WHERE id=source_id AND deleted_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Rejected retirement mutated opponent'; END IF;
END $$;
ROLLBACK;
