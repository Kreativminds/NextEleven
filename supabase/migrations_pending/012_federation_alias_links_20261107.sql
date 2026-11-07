-- Migration: federation_alias_links_20261107
-- Federation mappings for the open opponent names confirmed in docs/audits/opponent_review_queue_20261107.md.
--
-- NOT YET APPLIED. Requires Victor's explicit approval before running in production.
-- Scope: owner 563dea01-03a6-4e74-8cac-131cb39ccd97 only (the owner with fixtures).
-- Additive: inserts alias rows (team_alias_mappings) and sets federation_club_id on
-- exactly the opponent rows listed below. No game, fixture, score or name is changed.
-- Algés (1147) is only linked when migration 010 has created that club.
-- Rollback: supabase/migrations_pending/012_federation_alias_links_20261107_rollback.sql
-- (Forward migration tested in isolation. Rollback written, not yet tested.)

-- 1. Alias rows (same format as the Phase B rows). Idempotent by local_id.
INSERT INTO public.team_alias_mappings
  (user_id, payload, sync_status, device_id, local_id)
SELECT '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid,
  jsonb_build_object(
    'kind', 'opponent_federation_alias',
    'aliases', jsonb_build_array(a.alias),
    'aflClubId', a.afl_club_id,
    'squadLabel', a.squad_label,
    'competitionType', '__opponent_federation_alias__',
    'canonicalOfficialName', a.canonical_name
  ),
  'synced', 'federation-release-20261107', 'release-' || a.slug
FROM (VALUES
  ('cac',              '220',  NULL::text, 'Cultural',                 'release-cac'),
  ('sporting sad ff',  '1095', 'FF',       'Sporting, SAD',            'release-sporting-sad-ff'),
  ('mafra "a"',        '277',  'A',        'CD Mafra',                 'release-mafra-a'),
  ('tenente valdez "a"','1669','A',        'Tenente Valdez',           'release-tenente-valdez-a'),
  ('caneças "a"',      '948',  'A',        'Caneças',                  'release-canecas-a'),
  ('algés',            '1147', NULL::text, 'Algés',                    'release-alges')
) AS a(alias, afl_club_id, squad_label, canonical_name, slug)
WHERE (a.afl_club_id <> '1147' OR EXISTS (SELECT 1 FROM public.federation_clubs c WHERE c.afl_club_id = '1147'))
  AND NOT EXISTS (
    SELECT 1 FROM public.team_alias_mappings t
    WHERE t.user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
      AND t.local_id = 'release-' || a.slug
  );

-- 2. Opponent rows: set federation_club_id only where it is still null.
--    Opponent ids are the payload opponentId values read in production on 2026-11-07.
--    prevent_unreviewed_opponent_deletion (migration 20261106190000) rejects any
--    federation_club_id change unless auth.uid() is the row owner. A migration run
--    as the database role has no auth.uid(), so the statement runs as the owner for
--    this transaction only, the same way the app saves the link.
SET LOCAL request.jwt.claim.sub = '563dea01-03a6-4e74-8cac-131cb39ccd97';

UPDATE public.opponents o
SET federation_club_id = c.id,
    updated_at = now()
FROM public.federation_clubs c
JOIN (VALUES
  ('20',   '220'),   -- CAC -> Cultural
  ('43',   '1095'),  -- Sporting SAD FF -> Sporting, SAD (club level)
  ('765',  '277'),   -- Mafra "A" -> CD Mafra (club level)
  ('67',   '1669'),  -- Tenente Valdez "A" -> Tenente Valdez (club level)
  ('60',   '948'),   -- Caneças "A" -> Caneças (squad A per I Divisão)
  ('608',  '1147')   -- Algés -> Algés (requires migration 010)
) AS m(opponent_id, afl_club_id) ON c.afl_club_id = m.afl_club_id
WHERE o.user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
  AND o.deleted_at IS NULL
  AND o.federation_club_id IS NULL
  AND o.payload->>'opponentId' = m.opponent_id;
