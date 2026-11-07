-- Prevent approved historical alias mappings from silently becoming invalid.
-- Additive pre-production guard. No existing opponent or game rows are changed.
CREATE OR REPLACE FUNCTION public.protect_reviewed_opponent_alias_identity()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.opponent_historical_aliases a
    WHERE a.canonical_opponent_id = OLD.id
  ) THEN
    IF NEW.deleted_at IS DISTINCT FROM OLD.deleted_at AND NEW.deleted_at IS NOT NULL THEN
      RAISE EXCEPTION 'Cannot soft-delete canonical opponent referenced by reviewed historical aliases';
    END IF;
    IF NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.federation_club_id IS DISTINCT FROM OLD.federation_club_id
    THEN
      RAISE EXCEPTION 'Cannot change canonical opponent identity referenced by reviewed historical aliases';
    END IF;
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.opponent_historical_aliases a
    WHERE a.source_opponent_id = OLD.id
  ) THEN
    IF NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.federation_club_id IS DISTINCT FROM OLD.federation_club_id
       OR NEW.payload->>'opponentName' IS DISTINCT FROM OLD.payload->>'opponentName'
    THEN
      RAISE EXCEPTION 'Cannot change historical source identity referenced by reviewed aliases';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS protect_reviewed_opponent_alias_identity_trg ON public.opponents;
CREATE TRIGGER protect_reviewed_opponent_alias_identity_trg
BEFORE UPDATE ON public.opponents
FOR EACH ROW EXECUTE FUNCTION public.protect_reviewed_opponent_alias_identity();
REVOKE ALL ON FUNCTION public.protect_reviewed_opponent_alias_identity() FROM PUBLIC, anon, authenticated;
COMMENT ON FUNCTION public.protect_reviewed_opponent_alias_identity() IS
'Blocks canonical soft-delete and identity drift for reviewed historical aliases, while permitting reviewed source soft-delete and preserving fixture history.';
