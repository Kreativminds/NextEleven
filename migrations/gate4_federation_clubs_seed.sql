-- Gate 4 — federation_clubs seed migration (task #148)
--
-- Provenance: these 23 rows are the subset of the official AF Lisboa
-- "CD II DIV SUB-14 ATUALIZAÇÃO" roster (afl.pt, 2024/25 season, Sub-14 II
-- Divisão, Séries I–IV, 44 clubs total) that Gate 2's cross-check matched
-- against an existing row in this account's production `opponents`
-- catalogue, with a real AFL club ID confirmed for each
-- (NextEleven_Opponent_Reconciliation_v2.xlsx / opponent_reconciliation_v2.csv,
-- "AFL club ID" column, numeric values only).
--
-- HONEST SCOPE NOTE: this is 23 of the 44 clubs in the official roster —
-- the ones this account's own existing opponents happened to match in
-- Gate 2. The other ~21 roster clubs that never matched any existing
-- opponent were not re-captured with their AFL IDs in a saved artifact
-- from Gate 2's web research, so they are deliberately NOT fabricated
-- here. Completing the full 44-club roster is flagged as outstanding
-- work in the Gate 4 report, not silently assumed done.
--
-- afl_venue_id, map_url, venue_lat, venue_lng, logo_url are left NULL —
-- Gate 2 confirmed AFL does not publish a structured venue-ID registry
-- alongside this competition roster, so there is no verified source for
-- those fields yet. Enrichment is future work, not guessed data.
--
-- GATE 10.2 UPDATE: this file's INSERT already carried
-- "on conflict (afl_club_id) ... do nothing" since its very first
-- commit (8fc09ca, Gate 4) -- Gate 9.8's claim that it had "no explicit
-- idempotency guard" was incorrect; re-verified this gate by reading the
-- file's own git history. The INSERT was, and remains, safely re-runnable.
--
-- What WAS missing, and is added below: a conflict-REPORT step, run
-- before the insert, so a name mismatch between this seed and an
-- existing row sharing the same afl_club_id is surfaced explicitly
-- rather than silently resolved by "do nothing". Running this report
-- against the isolated test project (Gate 10.2) found exactly 2 of the
-- 23 rows below do not match the existing record by name:
--   afl_club_id 53  : seed 'Carregado "B"' vs existing 'Carregado'
--     (existing row's own federation_club_competitions registration has
--     squad_label = null -- no separate "B" squad registration exists
--     for this club today. FLAGGED, not resolved here: this may mean
--     Gate 2's original research identified a genuine B-squad entry
--     that the later AFL-official reconciliation (Gate 5) folded into
--     a single unlabelled registration, or it may mean Gate 2's naming
--     was simply imprecise. Either way, this seed statement does NOT
--     overwrite the existing row (per its own ON CONFLICT DO NOTHING),
--     so no data is at risk -- but the question itself is unresolved
--     and should not be silently closed by this migration.)
--   afl_club_id 283 : seed 'Desportivo O. Moscavide' vs existing
--     'Desp. O. Moscavide' -- a cosmetic abbreviation difference only.
--     Confirmed (Gate 10.2) that this club's A/B squad distinction IS
--     correctly preserved at the competition-registration level
--     (federation_club_competitions holds separate squad_label='A' and
--     squad_label='B' rows for this club's id) -- unaffected by the
--     name-string difference.
-- All other 21 rows match the existing record's official_name exactly.

-- CONFLICT REPORT — run this SELECT first. Any row it returns is a name
-- mismatch between this seed and the federation_clubs row already on
-- file for that afl_club_id; the INSERT below will NOT touch that row
-- (ON CONFLICT DO NOTHING), so review any reported row before relying on
-- either name.
with seed(official_name, afl_club_id) as (
  values
  ('Bobadelense','50'),('Carregado "B"','53'),('Atlético','145'),('Tojal','147'),
  ('Olivais Sul','190'),('Desportivo O. Moscavide','283'),('Venda Pinheiro','315'),
  ('Futebol Benfica','328'),('Santa Iria','365'),('Unidos','376'),('Oriental','391'),
  ('Camarate','577'),('Ericeirense','762'),('Castanheira','813'),('Alenquer','955'),
  ('Sanjoanense','1002'),('Torreense','1004'),('Povoense','1125'),('Vitória','1209'),
  ('Zambujalense','1216'),('Janitas','4421'),('Alta Lisboa','4887'),('AD Pastéis','5919')
)
select s.afl_club_id, s.official_name as seed_name, f.official_name as existing_name
from seed s
join public.federation_clubs f on f.afl_club_id = s.afl_club_id
where f.official_name is distinct from s.official_name;

insert into public.federation_clubs (official_name, afl_club_id, afl_venue_id, map_url, venue_lat, venue_lng, logo_url)
values
  ('Bobadelense', '50', null, null, null, null, null),
  ('Carregado "B"', '53', null, null, null, null, null),
  ('Atlético', '145', null, null, null, null, null),
  ('Tojal', '147', null, null, null, null, null),
  ('Olivais Sul', '190', null, null, null, null, null),
  ('Desportivo O. Moscavide', '283', null, null, null, null, null),
  ('Venda Pinheiro', '315', null, null, null, null, null),
  ('Futebol Benfica', '328', null, null, null, null, null),
  ('Santa Iria', '365', null, null, null, null, null),
  ('Unidos', '376', null, null, null, null, null),
  ('Oriental', '391', null, null, null, null, null),
  ('Camarate', '577', null, null, null, null, null),
  ('Ericeirense', '762', null, null, null, null, null),
  ('Castanheira', '813', null, null, null, null, null),
  ('Alenquer', '955', null, null, null, null, null),
  ('Sanjoanense', '1002', null, null, null, null, null),
  ('Torreense', '1004', null, null, null, null, null),
  ('Povoense', '1125', null, null, null, null, null),
  ('Vitória', '1209', null, null, null, null, null),
  ('Zambujalense', '1216', null, null, null, null, null),
  ('Janitas', '4421', null, null, null, null, null),
  ('Alta Lisboa', '4887', null, null, null, null, null),
  ('AD Pastéis', '5919', null, null, null, null, null)
on conflict (afl_club_id) where afl_club_id is not null do nothing;
