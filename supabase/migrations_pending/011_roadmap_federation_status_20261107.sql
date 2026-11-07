-- Migration: roadmap_federation_status_20261107
-- Updates internal roadmap status for the federation workstream (FED-001..FED-004)
-- and adds FED-005 (picker production enablement, blocked).
--
-- NOT YET APPLIED. Requires Victor's explicit approval before running in production.
-- Internal only: is_visible_to_users is never changed. No game, opponent, alias or
-- federation data is touched.
-- Rollback: supabase/migrations_pending/011_roadmap_federation_status_20261107_rollback.sql

-- 1. Capture current values so the rollback restores them exactly.
CREATE TABLE IF NOT EXISTS public.roadmap_items_backup_20261107 AS
SELECT * FROM public.roadmap_items WHERE roadmap_key IN ('FED-001','FED-002','FED-003','FED-004')
WITH NO DATA;
INSERT INTO public.roadmap_items_backup_20261107
SELECT r.* FROM public.roadmap_items r
WHERE r.roadmap_key IN ('FED-001','FED-002','FED-003','FED-004')
  AND NOT EXISTS (SELECT 1 FROM public.roadmap_items_backup_20261107 b WHERE b.id = r.id);

-- 2. Status and evidence for the federation workstream.
UPDATE public.roadmap_items SET
  status = 'In Progress',
  description = 'Reconcile opponent names to official AFL 2026/27 Sub-14 federation clubs (I, II and III Divisão). II and III catalogue rows match production exactly (109/109). I Divisão additions are prepared in migration 010 (not applied). Confirmed identities: CAC, Atlético CP, Algés (club level), Sporting SAD FF (club level, squad FF kept as original designation). Open: Musgueira, Operário Lisboa, Cadaval, Coutada, Falcons, Vilafranquense 1957 (not in the supplied PDFs).',
  internal_notes = 'Evidence: docs/audits/opponent_review_queue_20261107.md. Production 2026-11-07: 160 active opponents, 131 linked to a federation club, 56 game-level links, 0 dangling references.',
  updated_at = now()
WHERE roadmap_key = 'FED-001';

UPDATE public.roadmap_items SET
  status = 'In Progress',
  description = 'Safe opponent deduplication and 2026/27 regression. Production still holds 16 duplicate federation identity groups and 22 redundant opponent rows. No physical deletion before a verified backup. Season 2026/27 (seasonId 6): 27 active games, game-level links preserved.',
  updated_at = now()
WHERE roadmap_key = 'FED-002';

UPDATE public.roadmap_items SET
  status = 'In Progress',
  description = 'Users request club addition or deletion. Administrator verifies federation records, distinguishes local teams, reviews deletions and approves additions. Addition creation (migration 20261107050000) is tested in isolation and is not applied to production. Awaiting release approval.',
  updated_at = now()
WHERE roadmap_key = 'FED-003';

UPDATE public.roadmap_items SET
  internal_notes = 'Notifications: deletion completion covered in isolated role tests. Production has 0 addition requests and 0 deletion requests as of 2026-11-07.',
  updated_at = now()
WHERE roadmap_key = 'FED-004';

-- 3. Picker production enablement is tracked separately and stays blocked until
--    authenticated browser testing and Victor's approval are complete.
INSERT INTO public.roadmap_items
  (title, type, phase, priority, status, is_visible_to_users, description, group_name, epic_name, roadmap_key, governance_state, internal_notes)
SELECT
  'Federation picker production enablement', 'Feature', 2, 'P1', 'Blocked', false,
  'Enable FEDERATION_CATALOGUE_PICKER_ENABLED in production only after authenticated browser and mobile tests pass and Victor approves. Flag is false in the release candidate.',
  'Federation', 'Club identity', 'FED-005', 'canonical',
  'Blocked by: authenticated real-session test (sandbox cannot reach *.supabase.co), approval. Synthetic Chromium and regression tests pass.'
WHERE NOT EXISTS (SELECT 1 FROM public.roadmap_items WHERE roadmap_key = 'FED-005');
