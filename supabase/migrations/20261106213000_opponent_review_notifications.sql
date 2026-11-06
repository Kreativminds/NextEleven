-- In-app opponent review notifications. No email or external delivery is implied.
-- Each request and decision creates one durable, owner-scoped inbox event.
CREATE TABLE IF NOT EXISTS public.opponent_review_notifications (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 recipient_id uuid NOT NULL REFERENCES auth.users(id),
 request_id uuid NOT NULL,
 request_kind text NOT NULL CHECK(request_kind IN ('addition','deletion')),
 event_type text NOT NULL CHECK(event_type IN ('submitted','decided')),
 message text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 read_at timestamptz,
 UNIQUE(request_kind,request_id,event_type,recipient_id)
);
CREATE INDEX IF NOT EXISTS opponent_review_notifications_inbox ON public.opponent_review_notifications(recipient_id,created_at DESC);
ALTER TABLE public.opponent_review_notifications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.opponent_review_notifications FROM anon,authenticated;
GRANT SELECT,UPDATE ON public.opponent_review_notifications TO authenticated;
CREATE POLICY opponent_review_notification_read ON public.opponent_review_notifications FOR SELECT TO authenticated USING(recipient_id=(SELECT auth.uid()));
CREATE POLICY opponent_review_notification_mark_read ON public.opponent_review_notifications FOR UPDATE TO authenticated USING(recipient_id=(SELECT auth.uid())) WITH CHECK(recipient_id=(SELECT auth.uid()));
CREATE OR REPLACE FUNCTION public.opponent_review_notify() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public,pg_temp AS $fn$
DECLARE admin_id uuid; kind text; label text; event_name text; recipient uuid; body text;
BEGIN
 kind:=CASE WHEN TG_TABLE_NAME='opponent_addition_requests' THEN 'addition' ELSE 'deletion' END;
 label:=CASE WHEN kind='addition' THEN to_jsonb(NEW)->>'proposed_name' ELSE to_jsonb(NEW)->>'opponent_name' END;
 IF TG_OP='INSERT' THEN
  event_name:='submitted'; body:='New '||kind||' request: '||label;
  FOR admin_id IN SELECT user_id FROM public.opponent_deletion_admins LOOP
   INSERT INTO public.opponent_review_notifications(recipient_id,request_id,request_kind,event_type,message)
   VALUES(admin_id,NEW.id,kind,event_name,body) ON CONFLICT DO NOTHING;
  END LOOP;
 ELSIF NEW.status IS DISTINCT FROM OLD.status AND NEW.status<>'pending' THEN
  event_name:='decided'; recipient:=NEW.requester_id;
  body:='Your '||kind||' request for '||label||' was '||NEW.status||'. '||coalesce(NEW.decision_reason,'');
  INSERT INTO public.opponent_review_notifications(recipient_id,request_id,request_kind,event_type,message)
  VALUES(recipient,NEW.id,kind,event_name,body) ON CONFLICT DO NOTHING;
 END IF;
 RETURN NEW;
END $fn$;
REVOKE ALL ON FUNCTION public.opponent_review_notify() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS opponent_addition_review_notify ON public.opponent_addition_requests;
CREATE TRIGGER opponent_addition_review_notify AFTER INSERT OR UPDATE OF status ON public.opponent_addition_requests FOR EACH ROW EXECUTE FUNCTION public.opponent_review_notify();
DROP TRIGGER IF EXISTS opponent_deletion_review_notify ON public.opponent_deletion_requests;
CREATE TRIGGER opponent_deletion_review_notify AFTER INSERT OR UPDATE OF status ON public.opponent_deletion_requests FOR EACH ROW EXECUTE FUNCTION public.opponent_review_notify();
-- Inbox consumption/UI and read_at immutability enforcement require separate acceptance checks.
