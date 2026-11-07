-- Anonymous privilege regression, isolated Supabase only. No persistent changes.
BEGIN;
SET LOCAL ROLE anon;
DO $$
DECLARE rel text;
BEGIN
  FOREACH rel IN ARRAY ARRAY[
    'public.opponent_review_notifications',
    'public.opponent_deletion_requests',
    'public.opponent_addition_requests',
    'public.opponent_deletion_admins'
  ] LOOP
    IF has_table_privilege('anon',rel,'SELECT')
       OR has_table_privilege('anon',rel,'INSERT')
       OR has_table_privilege('anon',rel,'UPDATE')
       OR has_table_privilege('anon',rel,'DELETE') THEN
      RAISE EXCEPTION 'Anonymous table privilege unexpectedly granted: %', rel;
    END IF;
  END LOOP;
  IF has_function_privilege('anon','public.complete_approved_opponent_deletion(uuid)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can execute deletion completion RPC';
  END IF;
END $$;
ROLLBACK;
