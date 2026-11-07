-- Isolated project only: rollback-only inbox acknowledgement and cross-owner access regression.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid;
BEGIN
 INSERT INTO public.opponent_deletion_requests(requester_id,opponent_local_id,opponent_name,request_reason)
 VALUES(auth.uid(),9002,'User B Private Opponent','Inbox acknowledgement regression')
 RETURNING id INTO rid;
 PERFORM set_config('next11.inbox_test_id',rid::text,true);
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid:=current_setting('next11.inbox_test_id')::uuid; nid uuid;
BEGIN
 SELECT id INTO STRICT nid FROM public.opponent_review_notifications
 WHERE request_id=rid AND recipient_id=auth.uid() AND event_type='submitted';
 UPDATE public.opponent_review_notifications SET read_at=now() WHERE id=nid;
 IF NOT EXISTS(SELECT 1 FROM public.opponent_review_notifications WHERE id=nid AND read_at IS NOT NULL)
 THEN RAISE EXCEPTION 'Own read acknowledgement failed'; END IF;
 BEGIN
  UPDATE public.opponent_review_notifications SET read_at=NULL WHERE id=nid;
  RAISE EXCEPTION 'Unread reversal unexpectedly permitted';
 EXCEPTION WHEN raise_exception THEN
  IF (SELECT read_at FROM public.opponent_review_notifications WHERE id=nid) IS NULL
  THEN RAISE EXCEPTION 'Unread reversal changed row'; END IF;
 END;
 PERFORM set_config('next11.inbox_notification_id',nid::text,true);
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE nid uuid:=current_setting('next11.inbox_notification_id')::uuid;
BEGIN
 IF EXISTS(SELECT 1 FROM public.opponent_review_notifications WHERE id=nid)
 THEN RAISE EXCEPTION 'Cross-account notification read leak'; END IF;
 UPDATE public.opponent_review_notifications SET read_at=now() WHERE id=nid;
 IF FOUND THEN RAISE EXCEPTION 'Cross-account notification update succeeded'; END IF;
END $$;
ROLLBACK;
