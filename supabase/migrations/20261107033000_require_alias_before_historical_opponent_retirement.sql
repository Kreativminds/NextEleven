-- Fail closed when a soft-deleted opponent is still named in historical fixtures.
-- Reviewed alias mapping must exist BEFORE the source can be retired.
-- This is additive and does not rewrite fixtures or authorize deletions.
CREATE OR REPLACE FUNCTION public.require_historical_alias_before_opponent_retirement()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
 IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.games g
      WHERE g.user_id=OLD.user_id AND g.deleted_at IS NULL
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
DROP TRIGGER IF EXISTS require_historical_alias_before_opponent_retirement_trg ON public.opponents;
CREATE TRIGGER require_historical_alias_before_opponent_retirement_trg
BEFORE UPDATE OF deleted_at ON public.opponents
FOR EACH ROW EXECUTE FUNCTION public.require_historical_alias_before_opponent_retirement();
REVOKE ALL ON FUNCTION public.require_historical_alias_before_opponent_retirement() FROM PUBLIC, anon, authenticated;
