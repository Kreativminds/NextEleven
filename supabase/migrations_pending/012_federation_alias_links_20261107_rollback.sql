-- Rollback for 012_federation_alias_links_20261107.sql
-- Migration 012 only sets federation_club_id where it was NULL, so clearing the same
-- opponent rows restores the prior state exactly. Alias rows are identified by the
-- migration's device_id and local_id prefix.
-- NOT YET RUN. Run only with Victor's approval, and only if 012 has been applied.

BEGIN;

-- The prevent_unreviewed_opponent_deletion trigger requires the owner session for
-- federation_club_id changes (see the note in 012).
SET LOCAL request.jwt.claim.sub = '563dea01-03a6-4e74-8cac-131cb39ccd97';

UPDATE public.opponents o
SET federation_club_id = NULL,
    updated_at = now()
FROM public.federation_clubs c
JOIN (VALUES
  ('20',  '220'),
  ('43',  '1095'),
  ('765', '277'),
  ('67',  '1669'),
  ('60',  '948'),
  ('608', '1147')
) AS m(opponent_id, afl_club_id) ON c.afl_club_id = m.afl_club_id
WHERE o.user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
  AND o.federation_club_id = c.id
  AND o.payload->>'opponentId' = m.opponent_id;

DELETE FROM public.team_alias_mappings
WHERE user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
  AND device_id = 'federation-release-20261107'
  AND local_id LIKE 'release-%';

COMMIT;
