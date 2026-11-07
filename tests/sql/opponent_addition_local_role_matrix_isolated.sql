-- Original #17: addition-review authorization and local-team classification.
-- Run ONLY in isolated project with seeded auth users A (admin), B (requester).
-- Transaction rolls back all test requests and notifications.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid; blocked boolean;
BEGIN
  blocked := false;
  BEGIN
    INSERT INTO public.opponent_addition_requests(requester_id,proposed_name,proposed_type)
    VALUES ('00000000-0000-0000-0000-00000000a001','Forged request','local');
  EXCEPTION WHEN insufficient_privilege OR check_violation THEN blocked := true;
  END;
  IF NOT blocked THEN RAISE EXCEPTION 'Requester impersonation accepted'; END IF;

  INSERT INTO public.opponent_addition_requests(requester_id,proposed_name,proposed_type,notes)
  VALUES (auth.uid(),'Local Community Test FC','local','Not federation verified')
  RETURNING id INTO rid;
  PERFORM set_config('next11.addition_role_test',rid::text,true);
  blocked := false;
  BEGIN
    UPDATE public.opponent_addition_requests
    SET status='local',reviewed_by=auth.uid(),reviewed_at=now(),decision_reason='Forged approval'
    WHERE id=rid;
  EXCEPTION WHEN insufficient_privilege OR check_violation THEN blocked := true;
  END;
  IF (SELECT status FROM public.opponent_addition_requests WHERE id=rid) <> 'pending'
  THEN RAISE EXCEPTION 'Nonadmin changed addition review status'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a001';
DO $$
DECLARE rid uuid := current_setting('next11.addition_role_test')::uuid;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.opponent_addition_requests WHERE id=rid)
  THEN RAISE EXCEPTION 'Admin cannot see pending addition'; END IF;
  UPDATE public.opponent_addition_requests
  SET status='local', reviewed_by=auth.uid(), reviewed_at=now(),
      decision_reason='Local team only, no federation registration confirmed'
  WHERE id=rid AND status='pending';
  IF NOT FOUND THEN RAISE EXCEPTION 'Admin local classification rejected'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
DECLARE rid uuid := current_setting('next11.addition_role_test')::uuid;
BEGIN
  IF (SELECT status FROM public.opponent_addition_requests WHERE id=rid) <> 'local'
  THEN RAISE EXCEPTION 'Requester cannot see local classification'; END IF;
  IF (SELECT federation_club_id FROM public.opponent_addition_requests WHERE id=rid) IS NOT NULL
  THEN RAISE EXCEPTION 'Local team was falsely federation-linked'; END IF;
END $$;
ROLLBACK;
