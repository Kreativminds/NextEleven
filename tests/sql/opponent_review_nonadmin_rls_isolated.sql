-- Run on isolated test project only. No permanent changes.
-- Non-admin account B must not see admin membership or account A review requests.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM public.opponent_deletion_admins) THEN
   RAISE EXCEPTION 'Non-admin can see admin membership';
 END IF;
 IF EXISTS (SELECT 1 FROM public.opponent_deletion_requests WHERE requester_id <> auth.uid()) THEN
   RAISE EXCEPTION 'Cross-account deletion review leak';
 END IF;
 IF EXISTS (SELECT 1 FROM public.opponent_addition_requests WHERE requester_id <> auth.uid()) THEN
   RAISE EXCEPTION 'Cross-account addition review leak';
 END IF;
END $$;
ROLLBACK;
