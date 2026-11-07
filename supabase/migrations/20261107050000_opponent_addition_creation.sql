-- Approved club proposals create the real opponent record for the requester.
-- Additive only: new columns on opponent_addition_requests and one admin-gated
-- SECURITY DEFINER function. No existing opponent, game or fixture is changed.
-- Creation is idempotent per request (created_opponent_id guards re-runs) and
-- fails closed on a duplicate active name for the same requester.

ALTER TABLE public.opponent_addition_requests
  ADD COLUMN IF NOT EXISTS created_opponent_id uuid REFERENCES public.opponents(id),
  ADD COLUMN IF NOT EXISTS completed_at timestamptz;

CREATE OR REPLACE FUNCTION public.complete_approved_opponent_addition(p_request_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $fn$
DECLARE
  r public.opponent_addition_requests%ROWTYPE;
  new_id uuid;
  new_local_id text;
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.opponent_deletion_admins a WHERE a.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Administrator authorization required';
  END IF;

  SELECT * INTO r
  FROM public.opponent_addition_requests
  WHERE id = p_request_id
    AND status IN ('verified', 'local')
    AND reviewed_by = auth.uid()
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approved club proposal not found for this administrator';
  END IF;

  IF r.created_opponent_id IS NOT NULL THEN
    RETURN r.created_opponent_id;  -- already created: idempotent
  END IF;

  IF r.status = 'verified' AND r.federation_club_id IS NULL THEN
    RAISE EXCEPTION 'Verified proposal requires a federation club';
  END IF;

  new_local_id := gen_random_uuid()::text;

  INSERT INTO public.opponents (user_id, device_id, local_id, payload, federation_club_id)
  VALUES (
    r.requester_id,
    'admin-approved-addition',
    new_local_id,
    jsonb_build_object(
      'opponentId', new_local_id,
      'opponentName', r.proposed_name,
      'ageGroup', NULL,
      'level', NULL,
      'source', 'admin_approved_addition',
      'additionRequestId', r.id::text
    ),
    CASE WHEN r.status = 'verified' THEN r.federation_club_id ELSE NULL END
  )
  RETURNING id INTO new_id;

  UPDATE public.opponent_addition_requests
  SET created_opponent_id = new_id, completed_at = now()
  WHERE id = r.id AND created_opponent_id IS NULL;

  RETURN new_id;
END
$fn$;

REVOKE ALL ON FUNCTION public.complete_approved_opponent_addition(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_approved_opponent_addition(uuid) TO authenticated;
