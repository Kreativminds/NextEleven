-- Original task #17: reproducible, read-only audit of review-related RPC security.
-- Run on isolated project only. No data modifications.
-- SECURITY DEFINER functions should have a fixed search_path and public RPC
-- execution grants must be reviewed against their intended caller contract.
WITH funcs AS (
 SELECT n.nspname AS schema_name,p.proname,p.oid,
        p.prosecdef AS security_definer,
        COALESCE(p.proconfig,ARRAY[]::text[]) AS settings,
        has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute,
        has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname IN ('public','app_private')
 AND (p.proname ILIKE '%opponent%' OR p.proname ILIKE '%review%'
      OR p.proname ILIKE '%notification%')
)
SELECT schema_name,proname,oid::regprocedure::text AS signature,
       security_definer,anon_execute,authenticated_execute,
       CASE WHEN security_definer AND NOT EXISTS
          (SELECT 1 FROM unnest(settings) x WHERE x LIKE 'search_path=%')
         THEN 'SECURITY_DEFINER_WITHOUT_FIXED_SEARCH_PATH'
       WHEN schema_name='app_private' AND anon_execute
         THEN 'PRIVATE_RPC_ANON_EXECUTE'
       WHEN security_definer AND anon_execute
         THEN 'REVIEW_ANON_EXECUTE_CONTRACT'
       ELSE 'OK' END AS audit_result
FROM funcs ORDER BY audit_result,schema_name,proname,signature;
