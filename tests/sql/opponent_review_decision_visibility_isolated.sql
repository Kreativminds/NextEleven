-- Isolated Supabase regression. All writes roll back.
-- A is verified admin, B is a normal user. The fixtures must exist.
BEGIN;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.opponent_deletion_admins WHERE user_id='00000000-0000-0000-0000-00000000a001') THEN
  RAISE EXCEPTION 'Missing isolated administrator fixture';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.opponents WHERE user_id='00000000-0000-0000-0000-00000000a002' AND payload->>'opponentId'='9002' AND deleted_at IS NULL) THEN
  RAISE EXCEPTION 'Missing isolated non-admin opponent fixture';
 END IF;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
INSERT INTO public.opponent_deletion_requests(requester_id,opponent_local_id,opponent_name,request_reason)
VALUES ('00000000-0000-0000-0000-00000000a002','9002','User B Private Opponent','Duplicate entry');
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.opponent_deletion_requests WHERE requester_id=auth.uid() AND status='pending' AND opponent_local_id='9002') THEN
  RAISE EXCEPTION 'Requester cannot see pending review';
 END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
UPDATE public.opponent_deletion_requests SET status='rejected', reviewed_by=auth.uid(),reviewed_at=now(),decision_reason='Keep because linked to a fixture' WHERE requester_id='00000000-0000-0000-0000-00000000a002' AND opponent_local_id='9002' AND status='pending';
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.opponent_deletion_requests WHERE requester_id=auth.uid() AND opponent_local_id='9002' AND status='rejected' AND decision_reason='Keep because linked to a fixture') THEN
  RAISE EXCEPTION 'Requester cannot see decision and explanation';
 END IF;
END $$;
ROLLBACK;
