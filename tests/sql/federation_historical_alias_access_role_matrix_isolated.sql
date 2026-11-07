-- Original task #17: reviewed historical alias access boundary.
-- Run only on isolated Supabase; all role/session changes are transaction-local.
-- Assertions are independent of the number of existing alias rows.
BEGIN;
SET LOCAL ROLE anon;
DO $$
BEGIN
 IF has_table_privilege('anon','public.opponent_historical_aliases','SELECT')
 OR has_table_privilege('anon','public.opponent_historical_aliases','INSERT')
 OR has_table_privilege('anon','public.opponent_historical_aliases','UPDATE')
 OR has_table_privilege('anon','public.opponent_historical_aliases','DELETE')
 THEN RAISE EXCEPTION 'Anonymous role has private historical alias table privileges'; END IF;
 IF has_function_privilege('anon','public.require_historical_alias_before_opponent_retirement()','EXECUTE')
 THEN RAISE EXCEPTION 'Anonymous role can invoke retirement trigger function'; END IF;
END $$;
ROLLBACK;

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-00000000a002';
DO $$
BEGIN
 IF has_table_privilege('authenticated','public.opponent_historical_aliases','INSERT')
 OR has_table_privilege('authenticated','public.opponent_historical_aliases','UPDATE')
 OR has_table_privilege('authenticated','public.opponent_historical_aliases','DELETE')
 THEN RAISE EXCEPTION 'Authenticated role can mutate reviewed historical aliases'; END IF;
 IF NOT has_table_privilege('authenticated','public.opponent_historical_aliases','SELECT')
 THEN RAISE EXCEPTION 'Authenticated role cannot read owner-scoped historical aliases'; END IF;
 IF EXISTS (SELECT 1 FROM public.opponent_historical_aliases WHERE owner_id <> auth.uid())
 THEN RAISE EXCEPTION 'Cross-owner historical alias leak'; END IF;
 IF has_function_privilege('authenticated','public.require_historical_alias_before_opponent_retirement()','EXECUTE')
 THEN RAISE EXCEPTION 'Authenticated role can invoke retirement trigger function'; END IF;
END $$;
ROLLBACK;
