-- Non-destructive canonical identity preparation for opponent cleanup.
-- This migration does not alter games.payload, historical names, or opponents.
-- A separate reference table avoids touching the legacy sync payload.
CREATE TABLE IF NOT EXISTS public.game_opponent_federation_links (
  game_id uuid PRIMARY KEY REFERENCES public.games(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  opponent_id uuid NOT NULL REFERENCES public.opponents(id),
  federation_club_id uuid NOT NULL REFERENCES public.federation_clubs(id),
  original_opponent_name text NOT NULL,
  linked_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.game_opponent_federation_links ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.game_opponent_federation_links FROM anon,authenticated;
GRANT SELECT ON public.game_opponent_federation_links TO authenticated;
DROP POLICY IF EXISTS game_federation_links_owner_read ON public.game_opponent_federation_links;
CREATE POLICY game_federation_links_owner_read ON public.game_opponent_federation_links
 FOR SELECT TO authenticated USING (user_id=(SELECT auth.uid()));
-- Intentionally no authenticated INSERT/UPDATE/DELETE policy.
-- Only a reviewed, privileged migration may populate the table.

-- Enforce the relationship across the three independently referenced tables.
-- Foreign keys alone do not guarantee that game, opponent and link belong to
-- the same account, or that the club ID matches the opponent's verified ID.
CREATE OR REPLACE FUNCTION public.validate_game_opponent_federation_link()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $
BEGIN
 IF NOT EXISTS (
   SELECT 1 FROM public.games g
   JOIN public.opponents o ON o.id=NEW.opponent_id
     AND o.user_id=g.user_id AND o.deleted_at IS NULL
   WHERE g.id=NEW.game_id AND g.deleted_at IS NULL
     AND g.user_id=NEW.user_id
     AND g.payload->>'opponent'=NEW.original_opponent_name
     AND o.payload->>'opponentName'=NEW.original_opponent_name
     AND o.federation_club_id=NEW.federation_club_id
 ) THEN
   RAISE EXCEPTION 'Federation link must match active game, owner, opponent and verified club';
 END IF;
 RETURN NEW;
END;
$;
DROP TRIGGER IF EXISTS validate_game_opponent_federation_link ON public.game_opponent_federation_links;
CREATE TRIGGER validate_game_opponent_federation_link
 BEFORE INSERT OR UPDATE ON public.game_opponent_federation_links
 FOR EACH ROW EXECUTE FUNCTION public.validate_game_opponent_federation_link();

-- Preview the rows eligible for an exact, account-scoped backfill.
-- Execute this SELECT before any separate backfill is approved.
WITH matches AS (
 SELECT g.id game_id,g.user_id,g.payload->>'opponent' original_opponent_name,
        count(o.id) matching_rows,max(o.id::text)::uuid opponent_id,
        max(o.federation_club_id::text)::uuid federation_club_id
 FROM public.games g LEFT JOIN public.opponents o
 ON o.user_id=g.user_id AND o.deleted_at IS NULL
 AND o.payload->>'opponentName'=g.payload->>'opponent'
 WHERE g.deleted_at IS NULL
 GROUP BY g.id,g.user_id,g.payload->>'opponent'
)
SELECT count(*) total_games,
 count(*) FILTER (WHERE matching_rows=1 AND federation_club_id IS NOT NULL) eligible,
 count(*) FILTER (WHERE matching_rows<>1) ambiguous_or_missing,
 count(*) FILTER (WHERE federation_club_id IS NULL) unlinked
FROM matches;

-- Deliberately no INSERT backfill and no destructive operations here.
