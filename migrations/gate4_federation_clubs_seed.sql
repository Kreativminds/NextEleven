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
