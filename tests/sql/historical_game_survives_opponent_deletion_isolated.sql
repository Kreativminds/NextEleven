-- Original task #20: historical game remains byte-for-byte unchanged after approved opponent deletion.
-- Run only in isolated Supabase. Every inserted record and soft-delete is rolled back.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
INSERT INTO public.opponents(id,user_id,device_id,local_id,payload)
VALUES ('d91e0000-0000-4000-8000-000000000020',auth.uid(),'fixture-task20','920020',
        '{"opponentName":"Fixture Historic Rival","opponentId":920020}'::jsonb);
INSERT INTO public.games(id,user_id,device_id,local_id,payload)
VALUES ('d91e0000-0000-4000-8000-000000000021',auth.uid(),'fixture-task20','920021',
        '{"opponent":"Fixture Historic Rival","opponentId":920020,"gameId":920021,"homeScore":3,"opponentScore":2,"events":[{"type":"goal","minute":19}],"season":"2026/27"}'::jsonb);
DO $$
DECLARE rid uuid;
BEGIN
 INSERT INTO public.opponent_deletion_requests(requester_id,opponent_local_id,opponent_name,request_reason)
 VALUES (auth.uid(),920020,'Fixture Historic Rival','Duplicate in federation') RETURNING id INTO rid;
 PERFORM set_config('next11.task20_rid',rid::text,true);
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
UPDATE public.opponent_deletion_requests SET status='approved',decision_reason='Confirmed duplicate',reviewed_by=auth.uid(),reviewed_at=now()
WHERE id=current_setting('next11.task20_rid')::uuid AND status='pending';
SELECT public.complete_approved_opponent_deletion(current_setting('next11.task20_rid')::uuid);
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE expected jsonb := '{"opponent":"Fixture Historic Rival","opponentId":920020,"gameId":920021,"homeScore":3,"opponentScore":2,"events":[{"type":"goal","minute":19}],"season":"2026/27"}'::jsonb;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.opponents WHERE local_id='920020' AND deleted_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Approved deletion did not soft-delete opponent'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.games WHERE local_id='920021' AND deleted_at IS NULL AND payload=expected)
 THEN RAISE EXCEPTION 'Historical fixture mutated or disappeared'; END IF;
END $$;
ROLLBACK;
