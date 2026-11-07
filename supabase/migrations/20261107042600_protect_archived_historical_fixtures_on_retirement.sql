-- Original #10: historical names remain recoverable even for soft-deleted games.
-- The earlier retirement guard excluded deleted_at games. Those fixtures can later
-- be restored, so they must also retain a reviewed canonical identity.
-- This migration only changes a guard in the isolated release candidate.
CREATE OR REPLACE FUNCTION public.require_historical_alias_before_opponent_retirement()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
 IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.games g
      WHERE g.user_id=OLD.user_id
        AND g.payload->>'opponent'=OLD.payload->>'opponentName'
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.opponent_historical_aliases a
      JOIN public.opponents canonical ON canonical.id=a.canonical_opponent_id
      WHERE a.owner_id=OLD.user_id AND a.source_opponent_id=OLD.id
        AND a.historical_name=OLD.payload->>'opponentName'
        AND a.federation_club_id=OLD.federation_club_id
        AND canonical.deleted_at IS NULL
        AND canonical.user_id=OLD.user_id
        AND canonical.federation_club_id=OLD.federation_club_id
    )
 THEN
   RAISE EXCEPTION 'Historical fixture references require a reviewed alias before opponent retirement';
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.require_historical_alias_before_opponent_retirement() FROM PUBLIC, anon, authenticated;
