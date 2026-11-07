-- Isolated project ONLY. Transactional public-share revocation regression.
-- No share token is emitted; no permanent changes. The test uses one existing
-- enabled link and checks that disabling it immediately closes opponent lookup.
BEGIN;
DO $$
DECLARE
  v_user uuid;
  v_season integer;
  v_token text;
  v_before bigint;
  v_after bigint;
  v_restored bigint;
BEGIN
  SELECT user_id, season_id, share_token INTO v_user, v_season, v_token
  FROM public.team_share_links WHERE enabled IS TRUE
  ORDER BY created_at LIMIT 1 FOR UPDATE;
  IF NOT FOUND THEN
    RAISE NOTICE 'SKIP: no enabled isolated share link; no revocation assertion performed';
    RETURN;
  END IF;
  -- Do not log or return v_token. Count is for the same name and same token.
  SELECT count(*) INTO v_before
  FROM public.get_public_team_data_opponent_slice(v_token, 'Olivais Sul');
  UPDATE public.team_share_links SET enabled = false
  WHERE user_id=v_user AND season_id=v_season AND share_token=v_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'Share link disable did not update any row'; END IF;
  SELECT count(*) INTO v_after
  FROM public.get_public_team_data_opponent_slice(v_token, 'Olivais Sul');
  IF v_after <> 0 THEN
    RAISE EXCEPTION 'REVOKED_TOKEN_LEAK: disabled share token returned % opponent rows', v_after;
  END IF;
  UPDATE public.team_share_links SET enabled = true
  WHERE user_id=v_user AND season_id=v_season AND share_token=v_token;
  SELECT count(*) INTO v_restored
  FROM public.get_public_team_data_opponent_slice(v_token, 'Olivais Sul');
  IF v_restored <> v_before THEN
    RAISE EXCEPTION 'RESTORE_MISMATCH: same enabled link changed results from % to %', v_before, v_restored;
  END IF;
  RAISE NOTICE 'PASS: disabled token returned zero rows; enabled baseline restored (baseline rows %)', v_before;
END $$;
ROLLBACK;
