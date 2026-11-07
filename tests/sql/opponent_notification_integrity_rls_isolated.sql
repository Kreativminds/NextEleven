-- Isolated rollback-only task #17 notification security regression.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid; denied boolean:=false;
BEGIN
 INSERT INTO public.opponent_deletion_requests(requester_id,opponent_local_id,opponent_name,request_reason)
 VALUES(auth.uid(),9002,'User B Private Opponent','Notification security test') RETURNING id INTO rid;
 PERFORM set_config('next11.notify_req',rid::text,true);
 BEGIN
  INSERT INTO public.opponent_review_notifications(recipient_id,request_id,request_kind,event_type,message)
  VALUES(auth.uid(),rid,'deletion','completed','Fake approval');
 EXCEPTION WHEN insufficient_privilege OR check_violation THEN denied:=true;
 END;
 IF NOT denied THEN RAISE EXCEPTION 'Forged notification insert permitted'; END IF;
 IF EXISTS(SELECT 1 FROM public.opponent_review_notifications WHERE request_id=rid)
 THEN RAISE EXCEPTION 'Requester can read admin submission notification'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid:=current_setting('next11.notify_req')::uuid;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.opponent_review_notifications WHERE request_id=rid AND event_type='submitted')
 THEN RAISE EXCEPTION 'Admin notification absent'; END IF;
 UPDATE public.opponent_deletion_requests SET status='rejected',
 decision_reason='Linked fixtures must be preserved',reviewed_by=auth.uid(),reviewed_at=now()
 WHERE id=rid AND status='pending';
 IF NOT FOUND THEN RAISE EXCEPTION 'Admin decision failed'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid:=current_setting('next11.notify_req')::uuid; nid uuid; denied boolean;
BEGIN
 SELECT id INTO nid FROM public.opponent_review_notifications WHERE request_id=rid AND event_type='decided';
 IF nid IS NULL THEN RAISE EXCEPTION 'Requester decision notification absent'; END IF;
 denied:=false;
 BEGIN UPDATE public.opponent_review_notifications SET message='Fake decision' WHERE id=nid;
 EXCEPTION WHEN raise_exception THEN denied:=true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Message tampering permitted'; END IF;
 denied:=false;
 BEGIN UPDATE public.opponent_review_notifications SET recipient_id='00000000-0000-0000-0000-00000000a001' WHERE id=nid;
 EXCEPTION WHEN raise_exception OR check_violation OR insufficient_privilege THEN denied:=true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Recipient reassignment permitted'; END IF;
 UPDATE public.opponent_review_notifications SET read_at=now() WHERE id=nid;
 IF NOT FOUND THEN RAISE EXCEPTION 'Owner read acknowledgement failed'; END IF;
 denied:=false;
 BEGIN UPDATE public.opponent_review_notifications SET read_at=NULL WHERE id=nid;
 EXCEPTION WHEN raise_exception THEN denied:=true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Read acknowledgement reversal permitted'; END IF;
END $$;
ROLLBACK;
