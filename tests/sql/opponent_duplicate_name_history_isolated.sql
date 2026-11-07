-- Original #17/#20: same-owner duplicate-name insertion must fail without
-- changing historical games. Isolated Supabase only; all writes rolled back.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
INSERT INTO public.opponents(id,user_id,device_id,local_id,payload)
VALUES ('d91e0000-0000-4000-8000-000000000031',auth.uid(),'fixture-unique','930031',
 '{"opponentName":"Fixture Unique Rival","opponentId":930031}'::jsonb);
INSERT INTO public.games(id,user_id,device_id,local_id,payload)
VALUES ('d91e0000-0000-4000-8000-000000000033',auth.uid(),'fixture-unique','930033',
 '{"opponent":"Fixture Unique Rival","opponentId":930031,"homeScore":1,"opponentScore":1,"season":"2026/27"}'::jsonb);
DO $$
DECLARE blocked boolean:=false;
BEGIN
 BEGIN
  INSERT INTO public.opponents(id,user_id,device_id,local_id,payload)
  VALUES ('d91e0000-0000-4000-8000-000000000032',auth.uid(),'fixture-unique','930032',
   '{"opponentName":"Fixture Unique Rival","opponentId":930032}'::jsonb);
 EXCEPTION WHEN unique_violation THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'Duplicate same-owner opponent name unexpectedly accepted'; END IF;
 IF (SELECT count(*) FROM public.opponents WHERE device_id='fixture-unique' AND deleted_at IS NULL)<>1
 THEN RAISE EXCEPTION 'Duplicate-name failure changed opponent records'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.games WHERE local_id='930033' AND deleted_at IS NULL
  AND payload='{"opponent":"Fixture Unique Rival","opponentId":930031,"homeScore":1,"opponentScore":1,"season":"2026/27"}'::jsonb)
 THEN RAISE EXCEPTION 'Duplicate-name failure changed historical fixture'; END IF;
END $$;
ROLLBACK;