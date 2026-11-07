-- Isolated rollback-only regression. Canonical references must not be broken.
BEGIN;
INSERT INTO public.opponent_historical_aliases
 (owner_id,historical_name,source_opponent_id,canonical_opponent_id,federation_club_id,reviewed_by,review_reason)
SELECT src.user_id,src.payload->>'opponentName',src.id,dst.id,src.federation_club_id,
 '00000000-0000-0000-0000-00000000a001'::uuid,'Reviewed duplicate with historical fixture references'
FROM public.opponents src JOIN public.opponents dst
 ON src.user_id=dst.user_id AND src.federation_club_id=dst.federation_club_id
WHERE src.local_id='-910002' AND dst.local_id='-910001';
DO $$
DECLARE blocked boolean;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.opponent_historical_aliases WHERE source_opponent_id=(SELECT id FROM public.opponents WHERE local_id='-910002'))
 THEN RAISE EXCEPTION 'Fixture alias missing'; END IF;
 blocked:=false;
 BEGIN
  UPDATE public.opponents SET deleted_at=now() WHERE local_id='-910001';
 EXCEPTION WHEN raise_exception THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'Canonical soft-delete was not blocked'; END IF;
 blocked:=false;
 BEGIN
  UPDATE public.opponents SET payload=jsonb_set(payload,'{opponentName}','"Changed historical name"')
  WHERE local_id='-910002';
 EXCEPTION WHEN raise_exception THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'Historical source rename was not blocked'; END IF;
 blocked:=false;
 BEGIN
  UPDATE public.opponents SET federation_club_id='461ac75e-a34c-46f9-8b45-8e4d982ca559'::uuid
  WHERE local_id='-910001';
 EXCEPTION WHEN raise_exception THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'Canonical federation identity drift was not blocked'; END IF;
 IF EXISTS (SELECT 1 FROM public.opponents WHERE local_id IN ('-910001','-910002') AND deleted_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Protected opponent was modified'; END IF;
END $$;
ROLLBACK;
