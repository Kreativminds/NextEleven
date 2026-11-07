-- Rollback for 011_roadmap_federation_status_20261107.sql
-- Restores FED-001..FED-004 from the backup captured by the migration, removes FED-005
-- only if the migration inserted it, then drops the backup table.
-- NOT YET RUN. Run only with Victor's approval, and only if 011 has been applied.

BEGIN;

UPDATE public.roadmap_items r SET
  status = b.status,
  description = b.description,
  internal_notes = b.internal_notes,
  updated_at = b.updated_at,
  title = b.title,
  is_visible_to_users = b.is_visible_to_users
FROM public.roadmap_items_backup_20261107 b
WHERE r.id = b.id;

DELETE FROM public.roadmap_items
WHERE roadmap_key = 'FED-005'
  AND internal_notes LIKE 'Blocked by: authenticated real-session test%';

DROP TABLE IF EXISTS public.roadmap_items_backup_20261107;

COMMIT;
