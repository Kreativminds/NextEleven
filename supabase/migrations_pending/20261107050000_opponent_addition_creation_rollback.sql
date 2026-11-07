-- Rollback for supabase/migrations/20261107050000_opponent_addition_creation.sql
-- Removes the creation function and the two columns that migration added.
-- Refuses if any opponent was created by an approved addition, because those are user
-- records and must not be removed silently. Resolve them first with the owner.
-- NOT YET RUN. Run only with Victor's approval, and only if 20261107050000 has been applied.

BEGIN;

DO $guard$
DECLARE
  n integer;
BEGIN
  SELECT count(*) INTO n FROM public.opponents WHERE device_id = 'admin-approved-addition';
  IF n > 0 THEN
    RAISE EXCEPTION 'Rollback refused: % opponent(s) were created by approved additions. Review with owner first.', n;
  END IF;
END
$guard$;

DROP FUNCTION IF EXISTS public.complete_approved_opponent_addition(uuid);

ALTER TABLE public.opponent_addition_requests
  DROP COLUMN IF EXISTS created_opponent_id,
  DROP COLUMN IF EXISTS completed_at;

COMMIT;
