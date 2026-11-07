-- Isolated project only. Valid-token cross-owner metadata isolation.
-- All fixture rows are rolled back; tokens and private values are never printed.
BEGIN;
CREATE TEMP TABLE next11_share_isolation_fixture(token text, opponent_name text) ON COMMIT DROP;
DO $$
DECLARE v_owner uuid; v_other uuid;
v_token text; v_name text := '__next11_cross_owner_isolation_20261107__';
BEGIN
 SELECT user_id,share_token INTO v_owner,v_token FROM public.team_share_links
 WHERE enabled IS TRUE AND share_token IS NOT NULL AND length(share_token)>0
 ORDER BY created_at LIMIT 1;
 IF v_token IS NULL THEN RAISE EXCEPTION 'No enabled isolated share link'; END IF;
 SELECT user_id INTO v_other FROM public.opponents
 WHERE user_id <> v_owner ORDER BY user_id LIMIT 1;
 IF v_other IS NULL THEN RAISE EXCEPTION 'No second existing isolated owner'; END IF;
 IF EXISTS(SELECT 1 FROM public.federation_clubs
 WHERE lower(official_name)=lower(v_name))
 THEN RAISE EXCEPTION 'Synthetic name collision'; END IF;
 INSERT INTO public.opponents(id,user_id,device_id,local_id,payload)
 VALUES
 (gen_random_uuid(),v_owner,'isolation-test','isolation-owner',jsonb_build_object('opponentName',v_name,'mapUrl','owner-only-marker')),
 (gen_random_uuid(),v_other,'isolation-test','isolation-other',jsonb_build_object('opponentName',v_name,'mapUrl','foreign-only-marker'));
 INSERT INTO next11_share_isolation_fixture VALUES(v_token,v_name);
END $$;
GRANT SELECT ON next11_share_isolation_fixture TO anon;
SET LOCAL ROLE anon;
DO $$
DECLARE v_count integer; v_marker text;
BEGIN
 SELECT count(*),min(map_url) INTO v_count,v_marker
 FROM next11_share_isolation_fixture f
 CROSS JOIN LATERAL public.get_public_team_data_opponent_slice(f.token,f.opponent_name);
 IF v_count <> 1 OR v_marker IS DISTINCT FROM 'owner-only-marker'
 THEN RAISE EXCEPTION 'Valid share token did not isolate owner metadata'; END IF;
END $$;
ROLLBACK;
