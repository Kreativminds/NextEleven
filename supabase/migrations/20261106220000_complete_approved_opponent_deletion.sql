-- Complete approved opponent deletions only through the verified admin role.
-- Soft-delete only; never modify fixture history. Transactional and fail-closed.
DROP POLICY IF EXISTS opponent_deletion_admin_complete ON public.opponent_deletion_requests;
CREATE POLICY opponent_deletion_admin_complete ON public.opponent_deletion_requests
 FOR UPDATE TO authenticated USING (
 status='approved' AND reviewed_by=(SELECT auth.uid())
 AND EXISTS(SELECT 1 FROM public.opponent_deletion_admins a WHERE a.user_id=(SELECT auth.uid())))
 WITH CHECK(status='completed' AND reviewed_by=(SELECT auth.uid())
 AND decision_reason IS NOT NULL AND length(trim(decision_reason))>0);
CREATE OR REPLACE FUNCTION public.complete_approved_opponent_deletion(p_request_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,public,pg_temp AS $fn$
DECLARE r public.opponent_deletion_requests%ROWTYPE; changed integer;
BEGIN
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.opponent_deletion_admins WHERE user_id=auth.uid()) THEN
  RAISE EXCEPTION 'Administrator authorization required';
 END IF;
 SELECT * INTO r FROM public.opponent_deletion_requests WHERE id=p_request_id AND status='approved' AND reviewed_by=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Approved request not found for this administrator'; END IF;
 -- Fail closed on ambiguity, changed names, or stale identity.
 SELECT count(*) INTO changed FROM public.opponents o WHERE o.user_id=r.requester_id
  AND o.deleted_at IS NULL AND o.payload->>'opponentId'=r.opponent_local_id
  AND o.payload->>'opponentName'=r.opponent_name;
 IF changed<>1 THEN RAISE EXCEPTION 'Opponent identity no longer uniquely matches the approved request'; END IF;
 -- Retain fixtures and their historical opponent strings.
 UPDATE public.opponents SET deleted_at=now() WHERE user_id=r.requester_id
  AND deleted_at IS NULL AND payload->>'opponentId'=r.opponent_local_id
  AND payload->>'opponentName'=r.opponent_name;
 GET DIAGNOSTICS changed=ROW_COUNT;
 IF changed<>1 THEN RAISE EXCEPTION 'Deletion was not uniquely applied'; END IF;
 UPDATE public.opponent_deletion_requests SET status='completed'
 WHERE id=r.id AND status='approved' AND reviewed_by=auth.uid();
 GET DIAGNOSTICS changed=ROW_COUNT;
 IF changed<>1 THEN RAISE EXCEPTION 'Deletion completion could not be recorded'; END IF;
 RETURN true;
END $fn$;
REVOKE ALL ON FUNCTION public.complete_approved_opponent_deletion(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.complete_approved_opponent_deletion(uuid) TO authenticated;
