-- Read-only, owner-scoped historical opponent alias resolution.
-- Returns NULL for missing, unreviewed, stale or cross-owner mappings.
-- No fallback guesses and no historical fixture mutation.
CREATE OR REPLACE FUNCTION public.resolve_historical_opponent_alias(
  p_historical_name text,
  p_federation_club_id uuid
) RETURNS uuid
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = ''
AS $$
 SELECT a.canonical_opponent_id
 FROM public.opponent_historical_aliases a
 JOIN public.opponents src ON src.id=a.source_opponent_id
 JOIN public.opponents dst ON dst.id=a.canonical_opponent_id
 WHERE a.owner_id=(SELECT auth.uid())
   AND a.historical_name=p_historical_name
   AND a.federation_club_id=p_federation_club_id
   AND src.user_id=a.owner_id
   AND dst.user_id=a.owner_id
   AND src.federation_club_id=a.federation_club_id
   AND dst.federation_club_id=a.federation_club_id
   AND src.payload->>'opponentName'=a.historical_name
   AND dst.deleted_at IS NULL
   AND src.deleted_at IS NULL
 LIMIT 1;
$$;
REVOKE ALL ON FUNCTION public.resolve_historical_opponent_alias(text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_historical_opponent_alias(text,uuid) TO authenticated;
COMMENT ON FUNCTION public.resolve_historical_opponent_alias(text,uuid) IS
'Owner-scoped, read-only verified alias lookup; NULL if absent or invalid. Does not rewrite fixtures or authorize deletion.';