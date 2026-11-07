-- Isolated Supabase only. Run after opponent review and completion migrations.
-- Covers the approved-deletion state machine with a real authenticated role.
-- All writes are rolled back, including notifications and opponent soft-deletion.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid;
BEGIN
  INSERT INTO public.opponent_deletion_requests
    (requester_id, opponent_local_id, opponent_name, request_reason)
  VALUES (auth.uid(), 9002, 'User B Private Opponent', 'Verified duplicate review requested')
  RETURNING id INTO rid;
  PERFORM set_config('next11.review_request_id', rid::text, true);
  IF NOT EXISTS (
    SELECT 1 FROM public.opponent_review_notifications
    WHERE request_id=rid AND event_type='submitted'
  ) THEN
    -- The submission event is for the administrator, and should not be
    -- visible to the requester under row-level security.
    NULL;
  END IF;
END $$;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid := current_setting('next11.review_request_id')::uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.opponent_review_notifications
    WHERE request_id=rid AND event_type='submitted'
  ) THEN RAISE EXCEPTION 'Administrator did not receive submission notification'; END IF;
  UPDATE public.opponent_deletion_requests
  SET status='approved', decision_reason='Verified duplicate and historical dependencies',
      reviewed_by=auth.uid(), reviewed_at=now()
  WHERE id=rid AND status='pending';
  IF NOT FOUND THEN RAISE EXCEPTION 'Admin approval failed'; END IF;
  -- Direct completion must be blocked until the actual opponent is soft-deleted.
  BEGIN
    UPDATE public.opponent_deletion_requests SET status='completed' WHERE id=rid;
    RAISE EXCEPTION 'Direct completion unexpectedly succeeded';
  EXCEPTION WHEN check_violation OR raise_exception THEN
    -- Catch only the guard error; the explicit unexpected-success exception
    -- is rethrown below by checking the state after the nested block.
    NULL;
  END;
  IF (SELECT status FROM public.opponent_deletion_requests WHERE id=rid) <> 'approved'
  THEN RAISE EXCEPTION 'Invalid direct completion changed status'; END IF;
  PERFORM public.complete_approved_opponent_deletion(rid);
  IF (SELECT status FROM public.opponent_deletion_requests WHERE id=rid) <> 'completed'
  THEN RAISE EXCEPTION 'Approved deletion RPC failed to complete request'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.opponent_review_notifications
                 WHERE request_id=rid AND event_type='submitted')
  THEN RAISE EXCEPTION 'Submission notification missing after completion'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid := current_setting('next11.review_request_id')::uuid;
BEGIN
  IF (SELECT count(*) FROM public.opponent_review_notifications
      WHERE request_id=rid AND event_type IN ('decided','completed')) <> 2
  THEN RAISE EXCEPTION 'Requester must receive both decision and completion notifications'; END IF;
  IF EXISTS (SELECT 1 FROM public.opponent_review_notifications
             WHERE request_id=rid AND event_type='submitted')
  THEN RAISE EXCEPTION 'Requester can see administrator submission notification'; END IF;
END $$;
ROLLBACK;
