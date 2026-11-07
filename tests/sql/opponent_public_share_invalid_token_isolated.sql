-- Original task #17: anonymous share-token negative boundary.
-- Read-only, isolated project only. Never logs or retrieves a valid token.
-- Invalid, blank and NULL tokens must not disclose opponent metadata.
BEGIN;
SET LOCAL ROLE anon;
DO $$
DECLARE
  n integer;
  token text;
BEGIN
  FOREACH token IN ARRAY ARRAY[
    NULL::text,
    '',
    'invalid-token-not-issued-20261107',
    '00000000-0000-0000-0000-000000000000'
  ] LOOP
    SELECT count(*) INTO n
    FROM public.get_public_team_data_opponent_slice(token, 'SL Olivais');
    IF n <> 0 THEN
      RAISE EXCEPTION 'Invalid share token returned % opponent rows', n;
    END IF;
  END LOOP;
  -- Even a plausible club name must not bypass token authorization.
  SELECT count(*) INTO n
  FROM public.get_public_team_data_opponent_slice('invalid-token-not-issued-20261107', 'Olivais Sul');
  IF n <> 0 THEN
    RAISE EXCEPTION 'Olivais Sul metadata exposed without valid share token';
  END IF;
END $$;
ROLLBACK;
