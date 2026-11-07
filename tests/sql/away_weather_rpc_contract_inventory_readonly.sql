-- INT-01: read-only RPC contract inventory, isolated project only.
-- An empty weather RPC set is a blocker, not proof that the UI is broken.
-- Do not create a guessed RPC or modify production.
WITH functions AS (
 SELECT n.nspname AS schema_name, p.proname AS function_name,
        pg_get_function_identity_arguments(p.oid) AS arguments,
        pg_get_function_result(p.oid) AS result_type,
        p.prosecdef AS security_definer
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public'
   AND (p.proname ILIKE '%weather%' OR p.proname ILIKE '%venue%'
        OR p.proname ILIKE '%ground%')
)
SELECT * FROM functions ORDER BY function_name, arguments;
