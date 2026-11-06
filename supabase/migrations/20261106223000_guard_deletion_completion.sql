-- Prevent an administrator from marking a request completed without actually deleting the opponent.
-- A status transition to completed is valid only after the exact approved opponent
-- was soft-deleted in the same transaction, or previously by the approved admin flow.
CREATE OR REPLACE FUNCTION public.enforce_opponent_deletion_completion()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog,public,pg_temp AS $fn$
DECLARE matched integer;
BEGIN
 IF NEW.status='completed' AND OLD.status IS DISTINCT FROM NEW.status THEN
  IF OLD.status<>'approved' OR NEW.reviewed_by IS DISTINCT FROM auth.uid() THEN
   RAISE EXCEPTION 'Only the reviewing administrator can complete an approved request';
  END IF;
  SELECT count(*) INTO matched FROM public.opponents o
   WHERE o.user_id=NEW.requester_id
     AND o.payload->>'opponentId'=NEW.opponent_local_id
     AND o.payload->>'opponentName'=NEW.opponent_name
     AND o.deleted_at IS NOT NULL;
  IF matched<>1 THEN
   RAISE EXCEPTION 'Completion requires exactly one matching soft-deleted opponent';
  END IF;
 END IF;
 RETURN NEW;
END $fn$;
DROP TRIGGER IF EXISTS enforce_opponent_deletion_completion ON public.opponent_deletion_requests;
CREATE TRIGGER enforce_opponent_deletion_completion BEFORE UPDATE OF status
 ON public.opponent_deletion_requests FOR EACH ROW EXECUTE FUNCTION public.enforce_opponent_deletion_completion();
