-- Rollback for 010_add_i_divisao_federation_catalogue_2026_27.sql
-- Removes only rows that migration 010 can identify. Does not touch II/III rows,
-- opponents, games or aliases.
-- NOT YET RUN. Run only with Victor's approval, and only if 010 has been applied.

BEGIN;

-- 1. Refuse if any opponent links to a club this migration may have created.
DO $guard$
DECLARE
  n integer;
BEGIN
  SELECT count(*) INTO n
  FROM public.opponents o
  JOIN public.federation_clubs c ON c.id = o.federation_club_id
  WHERE c.afl_club_id IN ('1147', '1041');
  IF n > 0 THEN
    RAISE EXCEPTION 'Rollback refused: % opponent(s) link to Algés (1147) or Sintrense (1041).', n;
  END IF;
END
$guard$;

-- 2. Venues inserted by 010 (identified by the migration marker in notes).
DELETE FROM public.federation_club_venues v
USING public.federation_clubs c
WHERE c.id = v.club_id
  AND v.notes LIKE '%Migration 010.%';

-- 3. I Divisão Série 1 competition rows for 2026/27 (no other rows use this division).
DELETE FROM public.federation_club_competitions
WHERE season = '2026/27'
  AND division = 'I Divisão'
  AND series = '1';

-- 4. Clubs created by 010: only if created today and nothing else references them.
DELETE FROM public.federation_clubs c
WHERE c.afl_club_id IN ('1147', '1041')
  AND c.created_at >= date_trunc('day', now())
  AND NOT EXISTS (SELECT 1 FROM public.federation_club_competitions x WHERE x.club_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.federation_club_venues x WHERE x.club_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.opponents o WHERE o.federation_club_id = c.id);

COMMIT;
