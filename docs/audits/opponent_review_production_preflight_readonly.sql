-- Read-only production preflight for addition/deletion review migrations.
-- Run before deployment. No schema or data changes.
SELECT count(*) AS verified_super_admins
FROM public.profiles WHERE role='super_admin';

SELECT
 has_table_privilege('authenticated','public.opponents','DELETE') AS authenticated_can_hard_delete,
 EXISTS(SELECT 1 FROM pg_policies
  WHERE schemaname='public' AND tablename='opponents'
  AND cmd='DELETE') AS has_delete_policy;

SELECT
 to_regclass('public.opponent_deletion_admins') IS NOT NULL AS deletion_admin_table_exists,
 to_regclass('public.opponent_deletion_requests') IS NOT NULL AS deletion_requests_exist,
 to_regclass('public.opponent_addition_requests') IS NOT NULL AS addition_requests_exist;

SELECT count(*) AS active_opponents,
 count(*) FILTER (WHERE federation_club_id IS NOT NULL) AS federation_linked,
 count(*) FILTER (WHERE federation_club_id IS NULL) AS not_federation_linked
FROM public.opponents WHERE deleted_at IS NULL;
