-- Original #17: recipient-isolation and immutable notification audit, isolated only.
-- Uses seeded administrator A and requester B. Every inserted row is rolled back.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid;
BEGIN
 INSERT INTO public.opponent_deletion_requests(requester_id,opponent_local_id,opponent_name,request_reason)
 VALUES(auth.uid(),9002,'User B Private Opponent','Cross-recipient notification test') RETURNING id INTO rid;
 PERFORM set_config('next11.recipient_matrix',rid::text,true);
 IF EXISTS (SELECT 1 FROM public.opponent_review_notifications WHERE request_id=rid)
 THEN RAISE EXCEPTION 'Requester B read administrator A submission event'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid:=current_setting('next11.recipient_matrix')::uuid; nid uuid;
BEGIN
 SELECT id INTO nid FROM public.opponent_review_notifications
 WHERE request_id=rid AND event_type='submitted';
 IF nid IS NULL THEN RAISE EXCEPTION 'Administrator submission event missing'; END IF;
 UPDATE public.opponent_deletion_requests
 SET status='rejected',decision_reason='Historical fixtures require identity review',
 reviewed_by=auth.uid(),reviewed_at=now()
 WHERE id=rid AND status='pending';
 IF NOT FOUND THEN RAISE EXCEPTION 'Admin rejection failed'; END IF;
 IF EXISTS(SELECT 1 FROM public.opponent_review_notifications
           WHERE request_id=rid AND event_type='decided')
 THEN RAISE EXCEPTION 'Admin A can read requester B decision event'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid:=current_setting('next11.recipient_matrix')::uuid; nid uuid; before_count integer;
BEGIN
 SELECT id INTO nid FROM public.opponent_review_notifications
 WHERE request_id=rid AND event_type='decided';
 IF nid IS NULL THEN RAISE EXCEPTION 'Requester B decision event missing'; END IF;
 SELECT count(*) INTO before_count FROM public.opponent_review_notifications WHERE request_id=rid;
 BEGIN
   DELETE FROM public.opponent_review_notifications WHERE id=nid;
 EXCEPTION WHEN insufficient_privilege THEN NULL;
 END;
 IF NOT EXISTS(SELECT 1 FROM public.opponent_review_notifications WHERE id=nid)
 THEN RAISE EXCEPTION 'Requester B could delete decision audit'; END IF;
 IF (SELECT count(*) FROM public.opponent_review_notifications WHERE request_id=rid)<>before_count
 THEN RAISE EXCEPTION 'Notification audit row count changed'; END IF;
 UPDATE public.opponent_review_notifications SET read_at=now() WHERE id=nid;
 IF NOT FOUND THEN RAISE EXCEPTION 'Requester B cannot acknowledge own decision'; END IF;
END $$;
ROLLBACK;
