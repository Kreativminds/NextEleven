-- Gate 4 remediation (Victor's instruction #2): complete the federation
-- catalogue roster.
--
-- A fresh, independent research pass re-fetched the same official AFL
-- document (CD II DIV SUB-14 ATUALIZACAO, afl.pt) TWICE, with two
-- differently-worded extraction prompts, specifically to cross-check
-- against extraction error. Both passes agreed exactly on every one of
-- the 44 club/ID pairs, including quirky details unlikely to survive a
-- hallucination (two squads sharing one numeric ID). All 23 previously
-- seeded clubs reconcile cleanly against this same document.
--
-- SCOPE RECONCILIATION: the source lists 44 roster entries (Series I-IV),
-- but Sacavenense fields two squads ("B" and "C") under the SAME AFL club
-- ID (1017) -- confirmed in both extraction passes, not an extraction
-- artifact. federation_clubs is keyed by unique afl_club_id (one row per
-- real federation identity, not per squad/division entry, matching
-- Victor's instruction to keep the catalogue "independent of age groups,
-- divisions, series and seasons"), so 44 roster entries -> 43 unique club
-- rows. This migration brings the catalogue from 23 to 43.
--
-- CORRECTION: the existing row for AFL ID 53 was seeded as 'Carregado "B"'
-- in Gate 4. Both fresh extraction passes of the same source show this ID
-- labeled only 'CARREGADO', with no 'B' qualifier anywhere in the text.
-- Corrected here to the better-verified reading. Flagged, not silently
-- changed.
--
-- NOT seeded, left unresolved, because they are not verified (per Victor's
-- explicit "do not invent federation IDs, addresses or GPS coordinates" /
-- "if a record cannot be verified, leave it unresolved"):
--   - afl_venue_id for any club: the source has no column or header
--     labeled "ID" or "venue ID" at all. There IS an unlabeled parenthetical
--     number before each venue name in the fixture listing, in the same
--     style AFL uses for club IDs -- but the source itself never calls
--     this a venue ID, so treating it as one would be inventing structure
--     the source doesn't state. Left null pending a source that actually
--     labels it as such.
--   - locality / municipality / pitch dimensions: this data DOES appear in
--     the source, attached to each fixture, but was extracted in a single
--     pass (not cross-checked the way the club ID/name pairs were via two
--     independent extractions). Medium confidence, not the same bar as
--     the IDs above. Schema columns added below so this can be filled in
--     once verified, but deliberately left NULL in this migration rather
--     than promoting medium-confidence text to seeded data.
--
-- SCHEMA ADDITIONS (additive, nullable, no existing row affected):
alter table public.federation_clubs add column if not exists locality text;
alter table public.federation_clubs add column if not exists municipality text;

-- Supports "preserve multiple venues where applicable" at the design level.
-- Left empty here -- no venue is verified enough yet to populate it; see
-- the note above on why afl_venue_id and locality/pitch data are withheld.
create table if not exists public.federation_club_venues (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.federation_clubs(id) on delete cascade,
  venue_name text,
  afl_venue_code text, -- the unlabeled parenthetical number, kept as a
                        -- candidate field name only; never populated until
                        -- a source actually confirms what it denotes
  pitch_length_m numeric,
  pitch_width_m numeric,
  surface text,
  notes text,
  created_at timestamptz not null default now()
);
alter table public.federation_club_venues enable row level security;
create policy federation_club_venues_public_read on public.federation_club_venues for select using (true);

-- Correction: AFL ID 53 has no "B" qualifier in the source.
update public.federation_clubs set official_name = 'Carregado' where afl_club_id = '53';

insert into public.federation_clubs (official_name, afl_club_id)
values
  ('Igreja Nova', '2159'),
  ('Lourinhanense', '1081'),
  ('Mafra "A"', '277'),
  ('Malveira "A"', '137'),
  ('Montelavarenses', '353'),
  ('Vila Verde "B"', '1114'),
  ('Alverca "B"', '471'),
  ('Azambuja', '590'),
  ('Catujalense', '2712'),
  ('Águias Musgueira "A"', '908'),
  ('Sacavenense', '1017'), -- fields squads "B" and "C" under this one AFL ID, per source
  ('Col. São João Brito "B"', '2595'),
  ('Olivais "B"', '1033'),
  ('Ponte Frielas "B"', '703'),
  ('Col. Pedro Arrupe', '5629'),
  ('Sporting, SAD "C"', '1095'),
  ('EF Belém "C"', '5647'),
  ('Casa Pia "B"', '180'),
  ('Salesianos Lisboa', '5560'),
  ('Santa Maria "C"', '1151')
on conflict (afl_club_id) where afl_club_id is not null do nothing;
