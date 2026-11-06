-- Deploy only after assigning the owner's auth.users UUID to opponent_deletion_admins.
-- This migration does not delete or rename opponents or fixtures.
CREATE TABLE IF NOT EXISTS public.opponent_deletion_admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);
ALTER TABLE public.opponent_deletion_admins ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.opponent_deletion_admins FROM anon, authenticated;
GRANT SELECT ON public.opponent_deletion_admins TO authenticated;
DROP POLICY IF EXISTS opponent_deletion_admin_self_read ON public.opponent_deletion_admins;
CREATE POLICY opponent_deletion_admin_self_read ON public.opponent_deletion_admins
 FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.opponent_deletion_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 requester_id uuid NOT NULL REFERENCES auth.users(id),
 opponent_local_id text NOT NULL,
 opponent_name text NOT NULL,
 request_reason text NOT NULL CHECK (length(trim(request_reason)) BETWEEN 1 AND 2000),
 status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','completed')),
 decision_reason text,
 reviewed_by uuid REFERENCES auth.users(id),
 reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT decision_required CHECK (
   (status='pending' AND reviewed_by IS NULL AND reviewed_at IS NULL AND decision_reason IS NULL)
   OR (status<>'pending' AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL AND length(trim(decision_reason))>0)
 )
);
CREATE UNIQUE INDEX IF NOT EXISTS opponent_deletion_one_pending_per_user_team
 ON public.opponent_deletion_requests(requester_id,opponent_local_id) WHERE status='pending';
CREATE INDEX IF NOT EXISTS opponent_deletion_admin_inbox
 ON public.opponent_deletion_requests(status,created_at DESC);
ALTER TABLE public.opponent_deletion_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.opponent_deletion_requests FROM anon, authenticated;
GRANT SELECT,INSERT,UPDATE ON public.opponent_deletion_requests TO authenticated;
DROP POLICY IF EXISTS opponent_deletion_request_read ON public.opponent_deletion_requests;
CREATE POLICY opponent_deletion_request_read ON public.opponent_deletion_requests
 FOR SELECT TO authenticated USING (
 requester_id=(SELECT auth.uid()) OR EXISTS (
 SELECT 1 FROM public.opponent_deletion_admins a WHERE a.user_id=(SELECT auth.uid())));
DROP POLICY IF EXISTS opponent_deletion_request_create ON public.opponent_deletion_requests;
CREATE POLICY opponent_deletion_request_create ON public.opponent_deletion_requests
 FOR INSERT TO authenticated WITH CHECK (
 requester_id=(SELECT auth.uid()) AND status='pending'
 AND reviewed_by IS NULL AND reviewed_at IS NULL AND decision_reason IS NULL
 AND EXISTS (SELECT 1 FROM public.opponents o WHERE o.user_id=(SELECT auth.uid())
 AND o.deleted_at IS NULL AND o.payload->>'opponentId'=opponent_local_id
 AND o.payload->>'opponentName'=opponent_name));
DROP POLICY IF EXISTS opponent_deletion_admin_review ON public.opponent_deletion_requests;
CREATE POLICY opponent_deletion_admin_review ON public.opponent_deletion_requests
 FOR UPDATE TO authenticated USING (
 status='pending' AND EXISTS (SELECT 1 FROM public.opponent_deletion_admins a
 WHERE a.user_id=(SELECT auth.uid())))
 WITH CHECK (status IN ('approved','rejected') AND reviewed_by=(SELECT auth.uid())
 AND reviewed_at IS NOT NULL AND length(trim(decision_reason))>0);

-- An administrator can only set review fields; original request identity is immutable.
CREATE OR REPLACE FUNCTION public.lock_opponent_deletion_request_identity()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $
BEGIN
 IF NEW.id IS DISTINCT FROM OLD.id OR NEW.requester_id IS DISTINCT FROM OLD.requester_id
 OR NEW.opponent_local_id IS DISTINCT FROM OLD.opponent_local_id
 OR NEW.opponent_name IS DISTINCT FROM OLD.opponent_name
 OR NEW.request_reason IS DISTINCT FROM OLD.request_reason
 OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
   RAISE EXCEPTION 'Deletion request identity is immutable';
 END IF;
 RETURN NEW;
END;
$;
DROP TRIGGER IF EXISTS lock_opponent_deletion_request_identity ON public.opponent_deletion_requests;
CREATE TRIGGER lock_opponent_deletion_request_identity BEFORE UPDATE ON public.opponent_deletion_requests
 FOR EACH ROW EXECUTE FUNCTION public.lock_opponent_deletion_request_identity();

-- Critical: revoke hard DELETE from regular users and remove the legacy DELETE policy.\n-- RLS alone is insufficient while the own_rows_delete policy remains active.\nREVOKE DELETE ON public.opponents FROM anon, authenticated;\nDROP POLICY IF EXISTS own_rows_delete ON public.opponents;\n\n-- Critical: stop direct soft-deletion by regular users even via REST/sync.
-- Explicitly permit the authenticated owner to maintain other fields.
CREATE OR REPLACE FUNCTION public.prevent_unreviewed_opponent_deletion()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
BEGIN
 IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM public.opponent_deletion_admins a
      WHERE a.user_id=(SELECT auth.uid())) THEN
   RAISE EXCEPTION 'Only the application administrator may delete teams after review';
 END IF;
 RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS prevent_unreviewed_opponent_deletion ON public.opponents;
CREATE TRIGGER prevent_unreviewed_opponent_deletion BEFORE UPDATE ON public.opponents
 FOR EACH ROW EXECUTE FUNCTION public.prevent_unreviewed_opponent_deletion();

-- ADMIN CONFIGURATION REQUIRED, using the actual verified auth.users UUID:
-- INSERT INTO public.opponent_deletion_admins(user_id) VALUES ('<verified-owner-uuid>');
-- No privileged identity is inferred from user-controlled metadata or email.
