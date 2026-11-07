-- Original task #17: verify public share-token RPC privilege boundary.
-- Execute on isolated Supabase only. Read-only; never uses a valid share token.
-- A public token endpoint must remain callable by anon, while its internal
-- owner-scoped helper must not become a directly callable anon RPC.
DO $$
DECLARE
  public_rpc regprocedure := to_regprocedure('public.get_public_team_data_opponent_slice(text,text)');
  private_helper regprocedure := to_regprocedure('public._opponent_lookup_for_user(uuid,text)');
BEGIN
  IF public_rpc IS NULL THEN
    RAISE EXCEPTION 'Public opponent slice RPC missing or signature changed';
  END IF;
  IF NOT has_function_privilege('anon', public_rpc, 'EXECUTE') THEN
    RAISE EXCEPTION 'Public parent share token RPC unexpectedly unavailable to anon';
  END IF;
  IF private_helper IS NOT NULL AND has_function_privilege('anon', private_helper, 'EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can directly call private opponent lookup';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p WHERE p.oid = public_rpc
    AND (NOT p.prosecdef OR NOT EXISTS (
      SELECT 1 FROM unnest(coalesce(p.proconfig,ARRAY[]::text[])) cfg
      WHERE cfg LIKE 'search_path=%'
    ))
  ) THEN
    RAISE EXCEPTION 'Public token RPC must use security definer and pinned search path';
  END IF;
END $$;
