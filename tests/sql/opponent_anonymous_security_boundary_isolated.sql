-- Isolated project only: public anonymous boundary for opponent review and federation aliases.
-- Rollback-only, no permanent records or permission changes.
BEGIN;
SET LOCAL ROLE anon;
DO $$
DECLARE
  table_name text;
  n bigint;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'opponent_deletion_requests',
    'opponent_addition_requests',
    'opponent_deletion_admins',
    'opponent_review_notifications',
    'opponent_historical_aliases'
  ] LOOP
    -- A public client must never see private moderation or alias data.
    IF has_table_privilege('anon', 'public.' || table_name, 'SELECT') THEN
      EXECUTE format('SELECT count(*) FROM public.%I', table_name) INTO n;
      IF n <> 0 THEN
        RAISE EXCEPTION 'Anonymous user can read % rows in %', n, table_name;
      END IF;
    END IF;
    IF has_table_privilege('anon', 'public.' || table_name, 'INSERT')
      OR has_table_privilege('anon', 'public.' || table_name, 'UPDATE')
      OR has_table_privilege('anon', 'public.' || table_name, 'DELETE') THEN
      RAISE EXCEPTION 'Anonymous user has mutation grant on %', table_name;
    END IF;
  END LOOP;
  IF has_function_privilege('anon',
    'public.complete_approved_opponent_deletion(uuid)', 'EXECUTE')
  THEN RAISE EXCEPTION 'Anonymous user can execute approved deletion'; END IF;
  IF has_function_privilege('anon',
    'public.resolve_historical_opponent_alias(text,uuid)', 'EXECUTE')
  THEN RAISE EXCEPTION 'Anonymous user can resolve private historical aliases'; END IF;
  IF has_function_privilege('anon',
    'public.resolve_opponent_lookup(text)', 'EXECUTE')
  THEN RAISE EXCEPTION 'Anonymous user can execute private opponent lookup'; END IF;
  IF NOT has_function_privilege('anon',
    'public.get_public_team_data_opponent_slice(text,text)', 'EXECUTE')
  THEN RAISE EXCEPTION 'Public token-sharing contract unexpectedly revoked'; END IF;
END $$;
ROLLBACK;
