-- Club proposals: review only, never auto-create federation records.
CREATE TABLE IF NOT EXISTS public.opponent_addition_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 requester_id uuid NOT NULL REFERENCES auth.users(id),
 proposed_name text NOT NULL CHECK (length(trim(proposed_name)) BETWEEN 2 AND 200),
 proposed_type text NOT NULL CHECK (proposed_type IN ('local','federation')),
 notes text NOT NULL DEFAULT '',
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','verified','local','rejected')),
 federation_club_id uuid REFERENCES public.federation_clubs(id),
 decision_reason text,
 reviewed_by uuid REFERENCES auth.users(id),
 reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT addition_review_consistency CHECK (
 (status='pending' AND reviewed_by IS NULL AND reviewed_at IS NULL AND decision_reason IS NULL AND federation_club_id IS NULL)
 OR (status<>'pending' AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL
 AND length(trim(decision_reason))>0 AND (status='verified')=(federation_club_id IS NOT NULL)))
);
ALTER TABLE public.opponent_addition_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.opponent_addition_requests FROM anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.opponent_addition_requests TO authenticated;
DROP POLICY IF EXISTS addition_request_read ON public.opponent_addition_requests;
CREATE POLICY addition_request_read ON public.opponent_addition_requests FOR SELECT TO authenticated
 USING (requester_id=(SELECT auth.uid()) OR EXISTS
 (SELECT 1 FROM public.opponent_deletion_admins a WHERE a.user_id=(SELECT auth.uid())));
DROP POLICY IF EXISTS addition_request_insert ON public.opponent_addition_requests;
CREATE POLICY addition_request_insert ON public.opponent_addition_requests FOR INSERT TO authenticated
 WITH CHECK (requester_id=(SELECT auth.uid()) AND status='pending'
 AND federation_club_id IS NULL AND reviewed_by IS NULL AND reviewed_at IS NULL AND decision_reason IS NULL);
DROP POLICY IF EXISTS addition_request_review ON public.opponent_addition_requests;
CREATE POLICY addition_request_review ON public.opponent_addition_requests FOR UPDATE TO authenticated
 USING (status='pending' AND EXISTS
 (SELECT 1 FROM public.opponent_deletion_admins a WHERE a.user_id=(SELECT auth.uid())))
 WITH CHECK (status IN ('verified','local','rejected') AND reviewed_by=(SELECT auth.uid())
 AND reviewed_at IS NOT NULL AND length(trim(decision_reason))>0
 AND ((status='verified')=(federation_club_id IS NOT NULL)));
CREATE OR REPLACE FUNCTION public.lock_opponent_addition_request_identity()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
BEGIN
 IF NEW.id IS DISTINCT FROM OLD.id OR NEW.requester_id IS DISTINCT FROM OLD.requester_id
 OR NEW.proposed_name IS DISTINCT FROM OLD.proposed_name
 OR NEW.proposed_type IS DISTINCT FROM OLD.proposed_type
 OR NEW.notes IS DISTINCT FROM OLD.notes OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
 RAISE EXCEPTION 'Club proposal identity is immutable'; END IF;
 RETURN NEW;
END; $$;
DROP TRIGGER IF EXISTS lock_opponent_addition_request_identity ON public.opponent_addition_requests;
CREATE TRIGGER lock_opponent_addition_request_identity BEFORE UPDATE ON public.opponent_addition_requests
 FOR EACH ROW EXECUTE FUNCTION public.lock_opponent_addition_request_identity();
-- A verified outcome records the existing federation club ID only.
-- Actual club insertion and notification delivery require separate admin-controlled steps.
