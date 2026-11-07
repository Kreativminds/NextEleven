-- Migration: add_i_divisao_federation_catalogue_2026_27
-- Source: AFL "CD I DIVISÃO | SUB 14 - 2026/27" clubs and programme (Série 1).
-- Scope: 2 federation clubs (only if absent), 16 competition rows, 5 home venues.
--
-- NOT YET APPLIED. Requires Victor's explicit approval before running against
-- production. Tested in the isolated project (tqpykeuuzcqudqtfrqmc) first.
--
-- Properties:
--   * Additive only. No opponent, game, fixture, alias or existing federation row is changed.
--   * Idempotent: every insert is guarded by NOT EXISTS, so a re-run adds nothing.
--   * Clubs are matched by afl_club_id only. No club is created by name.
--   * Preflight aborts before any write if a same-named unlinked club exists
--     or an AFL id resolves to more than one club.
--   * Postflight verifies the expected 16 competition rows and 5 venues exist.
--   * Rollback: supabase/migrations_pending/010_add_i_divisao_federation_catalogue_2026_27_rollback.sql
--
-- Venue note: Oriental (391) already has venue 1945 in the isolated project but not
-- in production. The guard skips it where present, so it is inserted only where missing.

-- ---------------------------------------------------------------------------
-- 1. Preflight (read-only; raises before any write)
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  n integer;
BEGIN
  SELECT count(*) INTO n
  FROM public.federation_clubs
  WHERE afl_club_id IS NULL
    AND lower(official_name) IN ('algés', 'sintrense');
  IF n > 0 THEN
    RAISE EXCEPTION 'Preflight: % unlinked federation club(s) named Algés/Sintrense exist. Resolve before applying.', n;
  END IF;

  SELECT count(*) INTO n FROM (
    SELECT afl_club_id
    FROM public.federation_clubs
    WHERE afl_club_id IN ('1147','1041','471','327','1023','948','180','5156',
                          '5925','641','2727','391','703','1125','1017','1095')
    GROUP BY afl_club_id
    HAVING count(*) > 1
  ) d;
  IF n > 0 THEN
    RAISE EXCEPTION 'Preflight: % AFL id(s) map to more than one federation club.', n;
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 2. Clubs missing from the catalogue (Algés 1147, Sintrense 1041)
-- ---------------------------------------------------------------------------
INSERT INTO public.federation_clubs (official_name, afl_club_id, locality)
SELECT v.official_name, v.afl_club_id, v.locality
FROM (VALUES
  ('Algés',    '1147', 'Algés'),
  ('Sintrense', '1041', 'Sintra')
) AS v(official_name, afl_club_id, locality)
WHERE NOT EXISTS (
  SELECT 1 FROM public.federation_clubs c WHERE c.afl_club_id = v.afl_club_id
);

-- ---------------------------------------------------------------------------
-- 3. I Divisão Série 1 registrations (16 rows, squad as printed in the PDF)
-- ---------------------------------------------------------------------------
INSERT INTO public.federation_club_competitions
  (club_id, season, age_group, division, series, squad_label)
SELECT c.id, '2026/27', 'Sub-14', 'I Divisão', '1', r.squad
FROM (VALUES
  ('1147', NULL::text), ('471', 'A'), ('327', 'A'), ('1023', 'A'),
  ('948', 'A'), ('180', 'A'), ('5156', 'A'), ('5925', 'A'),
  ('641', 'A'), ('2727', 'A'), ('391', 'A'), ('703', 'A'),
  ('1125', 'A'), ('1017', 'A'), ('1041', NULL::text), ('1095', 'A')
) AS r(afl_id, squad)
JOIN public.federation_clubs c ON c.afl_club_id = r.afl_id
WHERE NOT EXISTS (
  SELECT 1 FROM public.federation_club_competitions x
  WHERE x.club_id = c.id
    AND x.season = '2026/27'
    AND x.division = 'I Divisão'
    AND x.series = '1'
    AND x.squad_label IS NOT DISTINCT FROM r.squad
);

-- ---------------------------------------------------------------------------
-- 4. Home venues from the I Divisão programme (5 rows)
-- ---------------------------------------------------------------------------
INSERT INTO public.federation_club_venues
  (club_id, venue_name, afl_venue_code, pitch_length_m, pitch_width_m, surface, notes)
SELECT c.id, v.venue_name, v.venue_code, v.length_m, v.width_m, 'Relvado Sintético',
  'Locality: ' || v.locality || '. Source venue number (unconfirmed as an official ID): '
  || v.venue_code || '. Added from I Divisão Série 1 Sub-14 2026/27 document. Migration 010.'
FROM (VALUES
  ('1147', '1891', 'Campo Dr Simões Alves',                          100.0::numeric, 54.0::numeric, 'Algés'),
  ('1041', '151',  'Campo do Sintrense, Nº 2',                        90.0::numeric, 55.0::numeric, 'Sintra'),
  ('5925', '1875', 'Complexo Desportivo da Abóboda',                 100.0::numeric, 64.0::numeric, 'Abóboda - São Domingos de Rana'),
  ('180',  '364',  'Est. Pina Manique 3 (C. Prof José Cruz Filipe)', 100.0::numeric, 64.0::numeric, 'Lisboa'),
  ('391',  '1945', 'Campo Ferroviário-Marvila',                      100.0::numeric, 64.0::numeric, 'Marvila - Lisboa')
) AS v(afl_id, venue_code, venue_name, length_m, width_m, locality)
JOIN public.federation_clubs c ON c.afl_club_id = v.afl_id
WHERE NOT EXISTS (
  SELECT 1 FROM public.federation_club_venues x
  WHERE x.club_id = c.id
    AND (x.afl_venue_code = v.venue_code OR x.venue_name = v.venue_name)
);

-- ---------------------------------------------------------------------------
-- 5. Postflight: fail the transaction if the expected end state is not present
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  n_comp integer;
  n_venue integer;
BEGIN
  SELECT count(*) INTO n_comp
  FROM public.federation_club_competitions
  WHERE season = '2026/27' AND division = 'I Divisão' AND series = '1';
  IF n_comp <> 16 THEN
    RAISE EXCEPTION 'Postflight: expected 16 I Divisão competition rows, found %', n_comp;
  END IF;

  SELECT count(*) INTO n_venue
  FROM public.federation_club_venues v
  JOIN public.federation_clubs c ON c.id = v.club_id
  WHERE (c.afl_club_id, v.afl_venue_code) IN (
    ('1147','1891'), ('1041','151'), ('5925','1875'), ('180','364'), ('391','1945')
  );
  IF n_venue <> 5 THEN
    RAISE EXCEPTION 'Postflight: expected 5 required venue rows, found %', n_venue;
  END IF;
END
$postflight$;
