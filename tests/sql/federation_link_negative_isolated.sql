-- Run on isolated fixture DB only, after link schema and positive backfill.
-- Transaction always rolls back. Tests cross-account, wrong club and name.
BEGIN;
DO $test$
DECLARE l record; bad uuid; other_user uuid; rejected boolean;
BEGIN
 SELECT * INTO STRICT l FROM public.game_opponent_federation_links LIMIT 1;
 SELECT id INTO STRICT bad FROM public.federation_clubs
 WHERE id <> l.federation_club_id LIMIT 1;
 SELECT id INTO STRICT other_user FROM auth.users WHERE id <> l.user_id LIMIT 1;
 rejected:=false;
 BEGIN
   UPDATE public.game_opponent_federation_links SET user_id=other_user
   WHERE game_id=l.game_id;
 EXCEPTION WHEN OTHERS THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'FAIL: cross-account link accepted'; END IF;
 rejected:=false;
 BEGIN
   UPDATE public.game_opponent_federation_links SET federation_club_id=bad
   WHERE game_id=l.game_id;
 EXCEPTION WHEN OTHERS THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'FAIL: wrong federation club accepted'; END IF;
 rejected:=false;
 BEGIN
   UPDATE public.game_opponent_federation_links
   SET original_opponent_name='Wrong historical name' WHERE game_id=l.game_id;
 EXCEPTION WHEN OTHERS THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'FAIL: wrong historical name accepted'; END IF;
END $test$;
SELECT count(*) AS valid_links
FROM public.game_opponent_federation_links l
JOIN public.games g ON g.id=l.game_id
JOIN public.opponents o ON o.id=l.opponent_id
WHERE l.user_id=g.user_id AND o.user_id=g.user_id
 AND l.federation_club_id=o.federation_club_id
 AND l.original_opponent_name=g.payload->>'opponent';
ROLLBACK;
