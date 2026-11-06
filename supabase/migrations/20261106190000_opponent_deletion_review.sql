-- Administrator identity is derived from the existing verified profiles.super_admin role.
-- Abort if the role assignment is absent or ambiguous.
-- This migration does not delete or rename opponents or fixtures.
CREATE TABLE IF NOT EXISTS public.opponent_deletion_admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);
ALTER TABLE public.opponent_deletion_admins ENABLE ROW LEVEL SECURITY;
DO $$
DECLARE admin_count integer;
BEGIN
 SELECT count(*) INTO admin_count FROM public.profiles WHERE role='super_admin';
 IF admin_count<>1 THEN RAISE EXCEPTION 'Expected exactly one verified super_admin, found %',admin_count; END IF;
 INSERT INTO public.opponent_deletion_admins(user_id)
 SELECT id FROM public.profiles WHERE role='super_admin'
 ON CONFLICT (user_id) DO NOTHING;
END $$;
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
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
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
$$;
DROP TRIGGER IF EXISTS lock_opponent_deletion_request_identity ON public.opponent_deletion_requests;
CREATE TRIGGER lock_opponent_deletion_request_identity BEFORE UPDATE ON public.opponent_deletion_requests
 FOR EACH ROW EXECUTE FUNCTION public.lock_opponent_deletion_request_identity();

-- Critical: revoke hard DELETE from regular users and remove the legacy DELETE policy.
-- RLS alone is insufficient while the own_rows_delete policy remains active.
REVOKE DELETE ON public.opponents FROM anon, authenticated;
DROP POLICY IF EXISTS own_rows_delete ON public.opponents;

-- Critical: stop direct soft-deletion by regular users even via REST/sync.
-- Explicitly permit the authenticated owner to maintain other fields.
CREATE OR REPLACE FUNCTION public.prevent_unreviewed_opponent_deletion()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
BEGIN
 IF (SELECT auth.uid()) IS DISTINCT FROM OLD.user_id THEN
   IF NEW.id IS DISTINCT FROM OLD.id OR NEW.user_id IS DISTINCT FROM OLD.user_id
      OR NEW.payload IS DISTINCT FROM OLD.payload
      OR NEW.device_id IS DISTINCT FROM OLD.device_id
      OR NEW.local_id IS DISTINCT FROM OLD.local_id
      OR NEW.federation_club_id IS DISTINCT FROM OLD.federation_club_id
      OR NEW.created_at IS DISTINCT FROM OLD.created_at
      OR NEW.updated_at IS DISTINCT FROM OLD.updated_at THEN
     RAISE EXCEPTION 'Administrator may change only deletion timestamp';
   END IF;
 END IF;
 IF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS DISTINCT FROM OLD.deleted_at THEN
   RAISE EXCEPTION 'Deleted opponent timestamp is immutable';
 END IF;
 IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
   IF NOT EXISTS (SELECT 1 FROM public.opponent_deletion_admins a
     WHERE a.user_id=(SELECT auth.uid())) THEN
     RAISE EXCEPTION 'Only the application administrator may delete teams after review';
   END IF;
   IF NOT EXISTS (
     SELECT 1 FROM public.opponent_deletion_requests r
     WHERE r.requester_id=OLD.user_id
       AND r.opponent_local_id=OLD.payload->>'opponentId'
       AND r.opponent_name=OLD.payload->>'opponentName'
       AND r.status='approved'
       AND r.reviewed_by=(SELECT auth.uid())
       AND r.reviewed_at IS NOT NULL
   ) THEN
     RAISE EXCEPTION 'Approved deletion request required';
   END IF;
 END IF;
 RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS prevent_unreviewed_opponent_deletion ON public.opponents;
CREATE TRIGGER prevent_unreviewed_opponent_deletion BEFORE UPDATE ON public.opponents
 FOR EACH ROW EXECUTE FUNCTION public.prevent_unreviewed_opponent_deletion();


-- Private authorization helper avoids recursive RLS checks:
-- deletion request INSERT checks opponents; opponent admin SELECT checks requests.
CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA app_private FROM PUBLIC;
GRANT USAGE ON SCHEMA app_private TO authenticated;
CREATE OR REPLACE FUNCTION app_private.can_admin_delete_opponent(
 p_owner uuid,p_local_id text,p_name text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path=pg_catalog,public,pg_temp AS $admincheck$
 SELECT auth.uid() IS NOT NULL
 AND EXISTS(SELECT 1 FROM public.opponent_deletion_admins a
   WHERE a.user_id=auth.uid())
 AND EXISTS(SELECT 1 FROM public.opponent_deletion_requests r
   WHERE r.requester_id=p_owner AND r.opponent_local_id=p_local_id
   AND r.opponent_name=p_name AND r.status='approved'
   AND r.reviewed_by=auth.uid() AND r.reviewed_at IS NOT NULL)
$admincheck$;
REVOKE ALL ON FUNCTION app_private.can_admin_delete_opponent(uuid,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.can_admin_delete_opponent(uuid,text,text)
 TO authenticated;
DROP POLICY IF EXISTS opponent_admin_approved_deletion_read ON public.opponents;
CREATE POLICY opponent_admin_approved_deletion_read ON public.opponents
 FOR SELECT TO authenticated USING
 (app_private.can_admin_delete_opponent(user_id,payload->>'opponentId',payload->>'opponentName'));
DROP POLICY IF EXISTS opponent_admin_approved_deletion ON public.opponents;
CREATE POLICY opponent_admin_approved_deletion ON public.opponents
 FOR UPDATE TO authenticated USING
 (app_private.can_admin_delete_opponent(user_id,payload->>'opponentId',payload->>'opponentName'))
 WITH CHECK (EXISTS(SELECT 1 FROM public.opponent_deletion_admins a
 WHERE a.user_id=auth.uid()));

-- Admin allowlist is populated from the single verified super_admin profile.
-- Never infer admin privilege from user-controlled metadata or email.
