-- Original #10: isolated, rollback-only alias coverage rehearsal.
-- Fixture-specific canonical is a simulation, NOT a production decision.
BEGIN;
CREATE TEMP TABLE next11_alias_rehearsal (
 owner_id uuid, federation_club_id uuid, historical_local_id text,
 historical_name text, canonical_local_id text,
 PRIMARY KEY(owner_id,historical_local_id),
 UNIQUE(owner_id,federation_club_id,historical_name)
) ON COMMIT DROP;
DO $$
DECLARE own uuid := '00000000-0000-0000-0000-00000000a001';
 fed uuid := '3b9dbcd6-a8e6-4057-ae97-68ae879d92f9';
 before_games jsonb; after_games jsonb; covered integer;
BEGIN
 IF (SELECT count(*) FROM public.opponents WHERE user_id=own AND federation_club_id=fed
 AND deleted_at IS NULL AND local_id IN ('-910001','-910002'))<>2
 THEN RAISE EXCEPTION 'Isolated duplicate fixture changed'; END IF;
 SELECT jsonb_agg(jsonb_build_object('id',id,'payload',payload) ORDER BY id)
 INTO before_games FROM public.games WHERE user_id=own AND deleted_at IS NULL
 AND payload->>'opponent' IN
 (SELECT payload->>'opponentName' FROM public.opponents WHERE user_id=own
 AND federation_club_id=fed AND local_id IN ('-910001','-910002') AND deleted_at IS NULL);
 INSERT INTO next11_alias_rehearsal
 SELECT user_id,federation_club_id,local_id,payload->>'opponentName','-910001'
 FROM public.opponents WHERE user_id=own AND federation_club_id=fed
 AND deleted_at IS NULL AND local_id IN ('-910001','-910002');
 IF (SELECT count(*) FROM next11_alias_rehearsal)<>2
 OR (SELECT count(DISTINCT historical_name) FROM next11_alias_rehearsal)<>2
 OR (SELECT count(DISTINCT canonical_local_id) FROM next11_alias_rehearsal)<>1
 THEN RAISE EXCEPTION 'Alias coverage or canonical cardinality failed'; END IF;
 IF EXISTS (SELECT 1 FROM next11_alias_rehearsal a LEFT JOIN public.opponents o
 ON o.user_id=a.owner_id AND o.local_id=a.canonical_local_id
 AND o.federation_club_id=a.federation_club_id AND o.deleted_at IS NULL
 WHERE o.local_id IS NULL) THEN RAISE EXCEPTION 'Canonical owner or identity mismatch'; END IF;
 SELECT count(*) INTO covered FROM public.games g JOIN next11_alias_rehearsal a
 ON a.owner_id=g.user_id AND a.historical_name=g.payload->>'opponent'
 WHERE g.user_id=own AND g.deleted_at IS NULL;
 IF covered<>2 THEN RAISE EXCEPTION 'Expected two historical fixtures, got %',covered; END IF;
 SELECT jsonb_agg(jsonb_build_object('id',id,'payload',payload) ORDER BY id)
 INTO after_games FROM public.games WHERE user_id=own AND deleted_at IS NULL
 AND payload->>'opponent' IN (SELECT historical_name FROM next11_alias_rehearsal);
 IF before_games IS DISTINCT FROM after_games THEN RAISE EXCEPTION 'Fixture changed'; END IF;
 RAISE NOTICE 'PASS: 2 historical aliases resolve to 1 simulated canonical, 2 fixtures unchanged';
END $$;
ROLLBACK;