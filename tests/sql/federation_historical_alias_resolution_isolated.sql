-- Rollback-only authenticated alias resolution matrix, isolated project only.
-- Fixture uses isolated SLO Benfica and Olivais "A", never production.
BEGIN;
INSERT INTO public.opponent_historical_aliases
 (owner_id,historical_name,source_opponent_id,canonical_opponent_id,federation_club_id,reviewed_by,review_reason)
SELECT src.user_id,src.payload->>'opponentName',src.id,dst.id,src.federation_club_id,
 '00000000-0000-0000-0000-00000000a001'::uuid,'Isolated approved canonical alias rehearsal'
FROM public.opponents src JOIN public.opponents dst
 ON src.user_id=dst.user_id AND src.federation_club_id=dst.federation_club_id
WHERE src.local_id='-910002' AND dst.local_id='-910001';
DO $$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.opponent_historical_aliases WHERE historical_name='Olivais "A"')
 THEN RAISE EXCEPTION 'Alias fixture not created'; END IF;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$ DECLARE got uuid; BEGIN
 SELECT public.resolve_historical_opponent_alias('Olivais "A"','3b9dbcd6-a8e6-4057-ae97-68ae879d92f9') INTO got;
 IF got IS DISTINCT FROM '11087a52-a995-4b93-a4d3-784387879cb8'::uuid
 THEN RAISE EXCEPTION 'Valid alias failed'; END IF;
 IF public.resolve_historical_opponent_alias('Olivais "A"','461ac75e-a34c-46f9-8b45-8e4d982ca559') IS NOT NULL
 THEN RAISE EXCEPTION 'Distinct federation identity was crossed'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$ BEGIN
 IF public.resolve_historical_opponent_alias('Olivais "A"','3b9dbcd6-a8e6-4057-ae97-68ae879d92f9') IS NOT NULL
 THEN RAISE EXCEPTION 'Cross-owner alias leak'; END IF;
END $$;
ROLLBACK;