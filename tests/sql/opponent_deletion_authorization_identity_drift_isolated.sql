-- Task #17 negative authorization matrix for approved opponent deletion.
-- Isolated project only. Every mutation is rolled back.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid;
BEGIN
 INSERT INTO public.opponent_deletion_requests
 (requester_id,opponent_local_id,opponent_name,request_reason)
 VALUES(auth.uid(),9002,'User B Private Opponent','Authorization regression')
 RETURNING id INTO rid;
 PERFORM set_config('next11.auth_matrix_request',rid::text,true);
END $$;
-- The requester must never be able to complete an unapproved deletion.
DO $$
DECLARE rid uuid:=current_setting('next11.auth_matrix_request')::uuid;
 denied boolean:=false;
BEGIN
 BEGIN PERFORM public.complete_approved_opponent_deletion(rid);
 EXCEPTION WHEN raise_exception OR insufficient_privilege THEN denied:=true;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'Non-admin could execute completion RPC'; END IF;
 IF (SELECT status FROM public.opponent_deletion_requests WHERE id=rid)<>'pending'
 THEN RAISE EXCEPTION 'Non-admin altered request state'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.opponents
   WHERE user_id=auth.uid() AND payload->>'opponentId'='9002'
   AND payload->>'opponentName'='User B Private Opponent' AND deleted_at IS NULL)
 THEN RAISE EXCEPTION 'Non-admin RPC mutated opponent'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid:=current_setting('next11.auth_matrix_request')::uuid;
 denied boolean:=false;
BEGIN
 -- Even an administrator cannot complete a request before approval.
 BEGIN PERFORM public.complete_approved_opponent_deletion(rid);
 EXCEPTION WHEN raise_exception OR insufficient_privilege THEN denied:=true;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'Admin completed pending request'; END IF;
 UPDATE public.opponent_deletion_requests
 SET status='approved',decision_reason='Verified duplicate',reviewed_by=auth.uid(),reviewed_at=now()
 WHERE id=rid AND status='pending';
 IF NOT FOUND THEN RAISE EXCEPTION 'Admin approval failed'; END IF;
 -- Identity drift after approval must fail closed.
 UPDATE public.opponents SET payload=jsonb_set(payload,'{opponentName}',
 to_jsonb('Renamed After Approval'::text))
 WHERE user_id='00000000-0000-0000-0000-00000000a002'
 AND payload->>'opponentId'='9002' AND payload->>'opponentName'='User B Private Opponent';
 IF NOT FOUND THEN RAISE EXCEPTION 'Identity-drift fixture could not be seeded'; END IF;
 denied:=false;
 BEGIN PERFORM public.complete_approved_opponent_deletion(rid);
 EXCEPTION WHEN raise_exception OR insufficient_privilege THEN denied:=true;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'Admin completed deletion despite identity drift'; END IF;
 IF (SELECT status FROM public.opponent_deletion_requests WHERE id=rid)<>'approved'
 THEN RAISE EXCEPTION 'Identity drift incorrectly completed request'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.opponents
 WHERE user_id='00000000-0000-0000-0000-00000000a002'
 AND payload->>'opponentId'='9002' AND payload->>'opponentName'='Renamed After Approval'
 AND deleted_at IS NULL)
 THEN RAISE EXCEPTION 'Identity drift incorrectly deleted opponent'; END IF;
END $$;
ROLLBACK;
