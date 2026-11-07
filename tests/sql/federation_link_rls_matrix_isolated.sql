-- Isolated-only RLS matrix for the fixture owner and another user.
-- Execute each transaction separately if the SQL client returns only the final result.
-- Expected: owner=2, other user=0, unauthenticated=0.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a001';
SELECT count(*) AS owner_visible_links FROM public.game_opponent_federation_links;
ROLLBACK;

BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='00000000-0000-0000-0000-00000000a002';
SELECT count(*) AS other_user_visible_links FROM public.game_opponent_federation_links;
ROLLBACK;

BEGIN;
SET LOCAL ROLE authenticated;
SELECT count(*) AS no_jwt_visible_links FROM public.game_opponent_federation_links;
ROLLBACK;

-- Also assert that authenticated has no mutation privileges.
SELECT has_table_privilege('authenticated','public.game_opponent_federation_links','INSERT') AS can_insert,
 has_table_privilege('authenticated','public.game_opponent_federation_links','UPDATE') AS can_update,
 has_table_privilege('authenticated','public.game_opponent_federation_links','DELETE') AS can_delete;
