-- Pre-production only until reviewed canonical mappings and release approval.
-- Historical aliases are additive; never rewrite games.payload.opponent.
CREATE TABLE IF NOT EXISTS public.opponent_historical_aliases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  historical_name text NOT NULL CHECK (length(btrim(historical_name)) > 0),
  source_opponent_id uuid NOT NULL REFERENCES public.opponents(id) ON DELETE RESTRICT,
  canonical_opponent_id uuid NOT NULL REFERENCES public.opponents(id) ON DELETE RESTRICT,
  federation_club_id uuid NOT NULL REFERENCES public.federation_clubs(id) ON DELETE RESTRICT,
  reviewed_by uuid NOT NULL,
  review_reason text NOT NULL CHECK (length(btrim(review_reason)) >= 10),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT opponent_historical_aliases_unique_owner_name UNIQUE (owner_id, historical_name),
  CONSTRAINT opponent_historical_aliases_no_self CHECK (source_opponent_id <> canonical_opponent_id)
);
CREATE INDEX IF NOT EXISTS opponent_historical_aliases_canonical_idx
  ON public.opponent_historical_aliases (owner_id, canonical_opponent_id);
CREATE OR REPLACE FUNCTION public.validate_opponent_historical_alias()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE src record; dst record;
BEGIN
  SELECT user_id, federation_club_id, payload->>'opponentName' AS name, deleted_at
    INTO src FROM public.opponents WHERE id=NEW.source_opponent_id;
  SELECT user_id, federation_club_id, deleted_at
    INTO dst FROM public.opponents WHERE id=NEW.canonical_opponent_id;
  IF src.user_id IS DISTINCT FROM NEW.owner_id
     OR dst.user_id IS DISTINCT FROM NEW.owner_id
     OR src.federation_club_id IS DISTINCT FROM NEW.federation_club_id
     OR dst.federation_club_id IS DISTINCT FROM NEW.federation_club_id
     OR src.name IS DISTINCT FROM NEW.historical_name
     OR src.deleted_at IS NOT NULL OR dst.deleted_at IS NOT NULL
  THEN
    RAISE EXCEPTION 'Alias source/canonical identity mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.opponent_deletion_admins
                 WHERE user_id=NEW.reviewed_by)
  THEN RAISE EXCEPTION 'Alias requires registered administrator review'; END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS validate_opponent_historical_alias_trg ON public.opponent_historical_aliases;
CREATE TRIGGER validate_opponent_historical_alias_trg
BEFORE INSERT OR UPDATE ON public.opponent_historical_aliases
FOR EACH ROW EXECUTE FUNCTION public.validate_opponent_historical_alias();
ALTER TABLE public.opponent_historical_aliases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.opponent_historical_aliases FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.opponent_historical_aliases TO authenticated;
CREATE POLICY opponent_historical_aliases_owner_read
ON public.opponent_historical_aliases FOR SELECT TO authenticated
USING (owner_id = (SELECT auth.uid()));
-- No authenticated INSERT/UPDATE/DELETE grants: mappings require reviewed
-- privileged migration, never an unreviewed user or application action.
REVOKE ALL ON FUNCTION public.validate_opponent_historical_alias() FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.opponent_historical_aliases IS
'Reviewed historical-name-to-canonical-opponent mapping. Does not alter historical fixtures. Privileged migration writes only.';
