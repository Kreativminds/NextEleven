-- Gate 5, Section 1: federation venue validation.
--
-- Source: the same official AFL document already used to build the 43-club
-- catalogue -- https://afl.pt/wp-content/uploads/2024/10/CD-II-DIV-SUB-14-ATUALIZACAO.pdf
-- ("CD II DIVISÃO | SUB 14 - 2024/25"). Re-extracted TWICE independently
-- (two differently-worded prompts) specifically for this migration; both
-- passes agreed exactly on every club/venue/locality/dimension value below.
--
-- GATE 5 PREMISE CHECK -- escalated to Victor separately, not silently
-- resolved here: Victor's Gate 5 instruction states "the original source
-- inventory covered both II and III Divisão." A targeted search of afl.pt
-- (four query phrasings + a direct URL-pattern attempt) found NO "III
-- Divisão Sub-14 Futebol de Onze" roster document anywhere. III Divisão
-- documents DO exist on afl.pt, but only for Sub-15/Sub-17 and futsal --
-- never Sub-14 11-a-side. The cited II Divisão PDF itself, re-verified
-- twice, contains ONLY II Divisão data (header: "CD II DIVISÃO | SUB 14").
-- So: either Victor has a different, not-yet-identified document in mind
-- (possibly from Gate 2's original research, which is not available in
-- this repo to re-check), or the "covers both II and III" premise does not
-- match this source. NOT assumed resolved either way -- flagged for Victor
-- in the Gate 5 report. The 43-club catalogue is, as far as this migration
-- can verify, the complete extraction of the ONE document that exists.
--
-- CONFIDENCE CAVEATS (apply to every row below):
--   - The source gives pitch dimensions as two numbers joined by "x"
--     (e.g. "101.0x56.0") with NO label for which is length and which is
--     width. Populated here as length-then-width per standard football
--     convention -- this ordering is an interpretation of the source's
--     format, not a label the document itself prints.
--   - The "venue_number" (bare number, parenthetical in fixtures /
--     hyphenated before the venue name in club lists) is NOT labeled "ID"
--     anywhere in THIS (2024/25) source alone. See the GATE 11 FIX note
--     below for how this was subsequently resolved.
--
-- ============================================================================
-- GATE 11 FIX (root-cause fix for the Gate 10.3 clean-rehearsal defect):
-- ============================================================================
-- Gate 10.3 found that applying this file followed by
-- gate5_resolution_afl_official_2026_27.sql from a genuinely clean start
-- produces 135 federation_club_venues rows instead of 92-102, because this
-- file left afl_venue_code NULL for every row, and the later migration's
-- own dedup guard keys on afl_venue_code -- NULL never equals anything in
-- SQL, so every club covered by both sources got a second, duplicate row.
--
-- ROOT-CAUSE FIX APPLIED HERE: this file's venue_number values are now
-- cross-checked against the independent, later, OFFICIAL 2026/27 AFL
-- documents (the _gate5_staging dataset transcribed in
-- gate5_resolution_afl_official_2026_27.sql) -- a second, independent,
-- officially-labelled source. Where the SAME afl_club_id reports the SAME
-- venue_number in both the 2024/25 extraction (this file) AND the official
-- 2026/27 documents, that number is confirmed as a genuine, stable AFL
-- venue identifier (not merely "unconfirmed as an official ID" as this
-- file originally read it) and is now populated directly into
-- afl_venue_code. This is NOT inventing an identifier and NOT deriving one
-- from the venue name -- it is the exact number already captured by this
-- file's own double-extraction, now independently corroborated by a
-- second, later, authoritative document using AFL's own venue-numbering
-- scheme. Per-row confirmation status is recorded in each row's `notes`.
--
-- Of this file's 43 rows, cross-checking against the 2026/27 staging
-- dataset gives three outcomes:
--   (a) MATCHED (33 rows) -- same afl_club_id, same venue_number in both
--       sources -- afl_venue_code populated with that confirmed number.
--   (b) NO SECOND SOURCE (8 rows: afl_club_id 2159, 1081, 353, 590, 1216,
--       908, 1002, 5560) -- this club does not appear in the 2026/27
--       official documents at all (not currently registered in Sub-14
--       II/III Divisão, or renamed/withdrawn) -- no independent
--       confirmation is possible, so afl_venue_code stays NULL, exactly as
--       Victor's "do not invent" instruction requires. A deterministic
--       fallback match (normalized venue name, see function below) is
--       used by later migrations so these rows are still correctly
--       recognized rather than silently duplicated if a future source
--       ever does cover them.
--   (c) SUPERSEDED / KNOWN STALE (2 rows: afl_club_id 4421 "Janitas",
--       venue_name/locality both differ from the 2026/27 source, and 391
--       "Oriental", whose 1945 claim gate5_resolution_afl_official_2026_27
--       .sql's own header already documents as disproven by the current
--       official document, which shows Oriental at 2009 instead) --
--       afl_venue_code stays NULL here too, and is NOT populated with the
--       old number, so this file never re-asserts a value a later,
--       authoritative source has already shown to be wrong. The later
--       migration's own supersede step (see that file) replaces these
--       specific rows in place with the current, confirmed venue instead
--       of inserting a second, duplicate row.
--
-- A normalized-name matching function is added below as the deterministic
-- fallback strategy Victor's Gate 11 instruction asks for, used only when
-- an official code is genuinely unavailable on one or both sides of a
-- comparison -- it never overrides a confirmed afl_venue_code match, and it
-- compares within the SAME club_id only, so it can never merge two
-- different clubs' venues into one, and never collapses a club's genuinely
-- distinct multiple pitches (those differ in venue_name, not just
-- formatting, so normalization does not make them equal).
create or replace function public.gate11_normalize_venue_name(p text)
returns text
language sql
immutable
as $$
  select trim(both ' ' from
    regexp_replace(
      regexp_replace(
        translate(
          lower(coalesce(p, '')),
          'áàâãäéèêëíìîïóòôõöúùûüçñºª°',
          'aaaaaeeeeiiiiooooouuuucnoo '
        ),
        '[^a-z0-9 ]+', ' ', 'g'
      ),
      '\s+', ' ', 'g'
    )
  )
$$;
--
-- NOT SEEDED / LEFT UNRESOLVED (per "do not invent... leave unresolved and
-- report exactly what is missing"):
--   - A venue numbered 3449 ("Alto Lumiar Campo 2," ~100.0x60.0) is
--     referenced in Série III fixtures but attached to no club in the club
--     table in either 2024/25 extraction pass -- which club uses it was
--     "not captured" at the time. RESOLVED since: the 2026/27 official
--     documents identify it as belonging to "3F" (afl_club_id 6051, a club
--     not previously in this catalogue) and to Alta Lisboa's "B" squad --
--     see gate5_resolution_afl_official_2026_27.sql, which seeds this
--     venue fresh; no row for it is created in this file.
--   - GPS coordinates and street addresses: not present in this source at
--     all, for any club. Not invented.
--
-- MULTI-VENUE / SHARED-VENUE CASES CAPTURED (lower-confidence items kept
-- in `notes` as text rather than structured numeric columns, since they
-- come from a single fixture mention, not the double-extracted main table):
--   - Sacavenense ("B" and "C", same afl_club_id 1017) share their primary
--     venue 1518, AND a separate fixture elsewhere references a second
--     venue for this club: "Complexo Desportivo Elias Pereira - Campo Nº 3"
--     (venue_number 2061, ~90.0x45.0 per that one mention only). CONFIRMED
--     since: the 2026/27 official document independently lists Sacavenense
--     at both 1518 and 2061 -- a genuine second pitch, not a duplicate.
--   - Salesianos Lisboa's club-table venue is 2009 ("Campo Fernando
--     Perfeito"), but a separate fixture lists this club at a different
--     venue: "Complexo Desportivo Bairro Boavista" (venue_number 3048,
--     ~92.0x47.0, locality Monsanto) -- a second, lower-confidence venue
--     for the same club. NOTE: the 2026/27 official document separately,
--     independently lists a DIFFERENT club (Oriental, afl_club_id 391) at
--     the same venue_number 2009 / venue_name "Campo Fernando Perfeito" --
--     corroborating that 2009 is a real, stable venue, but NOT evidence
--     that Salesianos Lisboa (5560) and Oriental (391) are the same club:
--     they are recorded in this catalogue as two distinct afl_club_id
--     values and are kept that way here (no merge), consistent with "do
--     not incorrectly merge unrelated venues/clubs."
--   - Águias Musgueira "A" and Alta Lisboa share venue 3348. CONFIRMED
--     since: the 2026/27 document independently lists Alta Lisboa at 3348
--     (as well as 3449); Águias Musgueira does not appear in either 2026/27
--     document at all (per gate5_resolution_afl_official_2026_27.sql's own
--     note), so its half of this "shared venue" claim stays unconfirmed
--     (afl_venue_code NULL on that row), while Alta Lisboa's is confirmed.
--   - AD Pastéis and Oriental share venue 1945 -- this pairing was not on
--     Victor's original flagged-case list, but is directly supported by
--     both extraction passes, so included for completeness rather than
--     dropped for not having been asked for by name. SUPERSEDED since: the
--     2026/27 official document shows AD Pastéis still at 1945, but
--     Oriental has moved to 2009 -- this pairing no longer holds for the
--     current season (see the SUPERSEDED note above and the resolution
--     file's own supersede step).

alter table public.federation_club_venues add column if not exists afl_venue_code_unconfirmed_note text;

-- ── Primary venues (one row per club, from the double-extracted club table) ──
insert into public.federation_club_venues (club_id, venue_name, afl_venue_code, pitch_length_m, pitch_width_m, surface, notes)
select fc.id, v.venue_name, v.afl_venue_code, v.pitch_length_m, v.pitch_width_m, v.surface, v.notes
from (values
  ('762','Campo Henrique Tomás Frade','195',101.0,56.0,'Relvado Sintético','Locality: Ericeira. Venue number 195 -- CONFIRMED: matches the official AFL 2026/27 Sub-14 II Divisão document for the same club (afl_club_id 762).'),
  ('2159','Campo Domingos Pinto Jorge - Igreja Nova',null,90.0,45.0,'Relvado Sintético','Locality: Igreja Nova - Mafra. Source venue number (unconfirmed): 1896 -- club does not appear in either 2026/27 official document; no independent confirmation available. Left NULL per "do not invent."'),
  ('4421','Campo da Tapadinha / Fonte Grada / TVD',null,96.0,55.0,'Relvado Sintético','Locality: Fonte Grada - Torres Vedras. Source venue number (unconfirmed): 1782 -- SUPERSEDED: the 2026/27 official document shows this club (Janitas, afl_club_id 4421) at a DIFFERENT venue (2193, Campo Parque Desp. Ramalhal, locality Ramalhal - T.Vedras) this season. 1782 is not reasserted here; see gate5_resolution_afl_official_2026_27.sql''s supersede step, which updates this row in place with the current, confirmed venue rather than inserting a duplicate.'),
  ('1081','Estádio Municipal Lourinhã Nº 2',null,100.0,64.0,'Relvado Sintético','Locality: Lourinhã. Source venue number (unconfirmed): 1942 -- club does not appear in either 2026/27 official document; no independent confirmation available.'),
  ('277','Campo João Simões - Alcainça','2968',100.0,55.0,'Relvado Sintético','Locality: Alcainça. Venue number 2968 -- CONFIRMED: matches the official AFL 2026/27 document for CD Mafra (afl_club_id 277), which also lists two further confirmed pitches (1830, 3049) for this same club, added fresh by the later migration.'),
  ('137','Campo José Alegre (Nº2 Malveira)','1912',90.0,54.0,'Relvado Sintético','Locality: Malveira. Venue number 1912 -- CONFIRMED: matches the official AFL 2026/27 document for Malveira (afl_club_id 137).'),
  ('353','Campo do Vimal - Montelavar',null,92.0,58.0,'Relvado Sintético','Locality: Montelavar. Source venue number (unconfirmed): 1955 -- club does not appear in either 2026/27 official document; no independent confirmation available.'),
  ('1004','Academia Torreense 2 / Complexo Desportivo de Arenes','5912',102.0,66.0,'Piso Sintético','Locality: Torres Vedras. Venue number 5912 -- CONFIRMED: matches the official AFL 2026/27 document for Torreense (afl_club_id 1004).'),
  ('315','Estádio Municipal Venda do Pinheiro','1958',100.0,64.0,'Relvado Sintético','Locality: Venda do Pinheiro. Venue number 1958 -- CONFIRMED: matches the official AFL 2026/27 document for Venda Pinheiro (afl_club_id 315).'),
  ('1114','Campo Afonso Araújo Sommer','1956',96.0,60.0,'Relvado Sintético','Locality: Vila Verde. Venue number 1956 -- CONFIRMED: matches the official AFL 2026/27 document for Vila Verde (afl_club_id 1114), registered across three séries this season, all at this same confirmed venue.'),
  ('955','Campo Fernando Manuel Pereira (Alenquer)','2162',99.0,60.0,'Relvado Sintético','Locality: Alenquer. Venue number 2162 -- CONFIRMED: matches the official AFL 2026/27 document for Alenquer (afl_club_id 955).'),
  ('471','Centro Formação FC Alverca / Century 21 / Imoteam / Campo 1','5117',105.0,68.0,'Relvado Sintético','Locality: Alverca. Venue number 5117 -- CONFIRMED: matches the official AFL 2026/27 document for Alverca (afl_club_id 471), which also lists a second confirmed pitch (5494) for this same club, added fresh by the later migration.'),
  ('590','Estádio Municipal Azambuja',null,null,null,'Relvado Sintético','Locality: Azambuja. Source venue number (unconfirmed): 4148 -- club does not appear in either 2026/27 official document; no independent confirmation available. Pitch dimensions NOT given in the club table (fixtures show "(x)" placeholder) -- left unresolved rather than invented.'),
  ('53','Campo José Lacerda Pinto Barreiros','23',100.0,64.0,'Relvado Sintético','Locality: Carregado. Venue number 23 -- CONFIRMED: independently verified by the official AFL 2026/27 document (Carregado, afl_club_id 53 -> venue 23), which resolves this file''s original "anomalously low, possible transcription artifact" flag -- it is correct, not an error.'),
  ('813','Campo São João','1323',100.0,61.0,'Relvado Sintético','Locality: Castanheira do Ribatejo. Venue number 1323 -- CONFIRMED: matches the official AFL 2026/27 document for Castanheira (afl_club_id 813).'),
  ('2712','Campo 1º Maio Catujal','2229',100.0,54.0,'Relvado Sintético','Locality: Catujal / Sacavém. Venue number 2229 -- CONFIRMED: matches the official AFL 2026/27 document for Catujalense (afl_club_id 2712).'),
  ('1125','Comp. Desp. Qta Piedade Campo Nº 1','2716',104.0,64.0,'Relvado Sintético','Locality: Póvoa Santa Iria. Venue number 2716 -- CONFIRMED: matches the official AFL 2026/27 document for Povoense (afl_club_id 1125), registered across two séries this season, both at this same confirmed venue.'),
  ('1002','Campo do SC Sanjoanense',null,90.0,49.0,'Relvado Sintético','Locality: São João da Talha. Source venue number (unconfirmed): 1886 -- club does not appear in either 2026/27 official document; no independent confirmation available.'),
  ('365','Campo Atlético Reynolds','2212',100.0,56.0,'Relvado Sintético','Locality: Santa Iria da Azóia. Venue number 2212 -- CONFIRMED: matches the official AFL 2026/27 document for Santa Iria (afl_club_id 365).'),
  ('147','Campo Meia Laranja','1849',91.0,56.0,'Relvado Sintético','Locality: Santo Antão do Tojal. Venue number 1849 -- CONFIRMED: matches the official AFL 2026/27 document for Tojal (afl_club_id 147).'),
  ('1216','Campo Conde Mendia - Zambujalense',null,100.0,64.0,'Relvado Sintético','Locality: Zambujal. Source venue number (unconfirmed): 2221 -- club does not appear in either 2026/27 official document; no independent confirmation available.'),
  ('908','Complexo Desportivo Alto Lumiar Campo 1',null,105.0,65.0,'Relvado Sintético','Locality: Alto do Lumiar. Source venue number (unconfirmed): 3348 -- SHARED venue claim (also used by Alta Lisboa, afl_club_id 4887), but this club (Águias Musgueira "A") does not appear in either 2026/27 official document at all, per gate5_resolution_afl_official_2026_27.sql''s own note -- no independent confirmation available for this club''s half of the pairing.'),
  ('4887','Complexo Desportivo Alto Lumiar Campo 1','3348',105.0,65.0,'Relvado Sintético','Locality: Alto do Lumiar. Venue number 3348 -- CONFIRMED: matches the official AFL 2026/27 document for Alta Lisboa (afl_club_id 4887), which also lists a second confirmed pitch (3449, same complex) for this same club, added fresh by the later migration. SHARED venue claim with Águias Musgueira (afl_club_id 908) stays unconfirmed on that club''s own row (908 is not in the 2026/27 documents).'),
  ('50','Parque Desp. Munic. Bobadela','2214',100.0,57.0,'Relvado Sintético','Locality: Bobadela - Sacavém. Venue number 2214 -- CONFIRMED: matches the official AFL 2026/27 document for Bobadelense (afl_club_id 50).'),
  ('577','Campo Quinta Barros','1482',90.0,52.0,'Relvado Sintético','Locality: Camarate. Venue number 1482 -- CONFIRMED: matches the official AFL 2026/27 document for Camarate (afl_club_id 577).'),
  ('5629','Campo Colégio Pedro Arrupe','4753',100.0,50.0,'Relvado Sintético','Locality: Parque das Nações - Lisboa. Venue number 4753 -- CONFIRMED: matches the official AFL 2026/27 document for Col Pedro Arrupe (afl_club_id 5629).'),
  ('2595','Campo Colégio São João Brito - Sintético','1862',95.0,45.0,'Relvado Sintético','Locality: Lumiar / Lisboa. Venue number 1862 -- CONFIRMED: matches the official AFL 2026/27 document for Col S J Brito (afl_club_id 2595).'),
  ('283','Estádio Alfredo Marques Augusto','222',102.0,68.0,'Relvado Sintético','Locality: Olivais. Venue number 222 -- CONFIRMED: matches the official AFL 2026/27 document for Desp. O. Moscavide (afl_club_id 283), registered across two séries this season, both at this same confirmed venue.'),
  ('1033','Campo Branca Lucas','1511',100.0,65.0,'Relvado Sintético','Locality: Olivais - Lisboa. Venue number 1511 -- CONFIRMED: matches the official AFL 2026/27 document for Olivais (afl_club_id 1033), registered across two séries (squads A and B) this season, both at this same confirmed venue.'),
  ('190','Campo do Olivais Sul','1853',101.0,68.0,'Relvado Sintético','Locality: Olivais Sul - Lisboa. Venue number 1853 -- CONFIRMED: matches the official AFL 2026/27 document for Olivais Sul (afl_club_id 190).'),
  ('703','Campo Bonjardim','131',100.0,63.0,'Relvado Sintético','Locality: Ponte Frielas. Venue number 131 -- CONFIRMED: matches the official AFL 2026/27 document for Ponte Frielas (afl_club_id 703).'),
  ('1017','Complexo Desportivo Elias Pereira - Campo Nº 1','1518',100.0,64.0,'Relvado Sintético','Locality: Sacavém. Venue number 1518 -- CONFIRMED: matches the official AFL 2026/27 document for Sacavenense (afl_club_id 1017), shared between this club''s own "B" and "C" squads (same afl_club_id). The 2026/27 document also independently confirms this club''s second pitch (2061, Campo Nº 3), previously recorded here only as a lower-confidence fixture-mention note -- now added fresh, with full confidence, by the later migration.'),
  ('5919','Campo Ferroviário-Marvila','1945',102.0,64.0,'Relvado Sintético','Locality: Marvila - Lisboa. Venue number 1945 -- CONFIRMED: matches the official AFL 2026/27 document for AD Pastéis (afl_club_id 5919). NOTE: the earlier claim that this venue is shared with Oriental (afl_club_id 391) does NOT hold for the current season -- the 2026/27 document shows Oriental at a different venue (2009) -- see that club''s own row and gate5_resolution_afl_official_2026_27.sql.'),
  ('145','Campo Manuel Candeias - Estádio Tapadinha','1373',93.0,53.0,'Relvado Sintético','Locality: Lisboa. Venue number 1373 -- CONFIRMED: matches the official AFL 2026/27 document for Atlético (afl_club_id 145), registered across two séries this season, both at this same confirmed venue.'),
  ('180','Estádio Pina Manique Nº 2','204',90.0,60.0,'Relvado Sintético','Locality: Lisboa. Venue number 204 -- CONFIRMED: matches the official AFL 2026/27 document for Casa Pia (afl_club_id 180).'),
  ('5647','Campo Nº 3 Restelo','1641',90.0,45.0,'Relvado Sintético','Locality: Restelo - Lisboa. Venue number 1641 -- CONFIRMED: matches the official AFL 2026/27 document for EF Belém (afl_club_id 5647), which also lists a second confirmed pitch (4963) for this same club, added fresh by the later migration. This venue (1641) is also independently confirmed as used by Belenenses (afl_club_id 327) -- a genuine shared venue between two different clubs, not a duplicate.'),
  ('328','Campo Nº2 Estádio Francisco Lázaro','1335',90.0,45.0,'Relvado Sintético','Locality: Lisboa. Venue number 1335 -- CONFIRMED: matches the official AFL 2026/27 document for Futebol Benfica (afl_club_id 328).'),
  ('391','Campo Ferroviário-Marvila',null,102.0,64.0,'Relvado Sintético','Locality: Marvila - Lisboa. Source venue number (unconfirmed): 1945 -- SUPERSEDED: the 2026/27 official document shows this club (Oriental, afl_club_id 391) at a DIFFERENT venue this season (2009, Campo Fernando Perfeito). 1945 is not reasserted here; see gate5_resolution_afl_official_2026_27.sql''s supersede step, which updates this row in place with the current, confirmed venue rather than inserting a duplicate.'),
  ('5560','Campo Fernando Perfeito',null,90.0,45.0,'Relvado Sintético','Locality: Bº Encarnação / Lisboa. Source venue number (unconfirmed): 2009 -- club (Salesianos Lisboa) does not appear in either 2026/27 official document; no independent confirmation available for THIS club. NOTE (observation, not a confirmation): the 2026/27 document independently lists a DIFFERENT club, Oriental (afl_club_id 391), at this same venue_number/venue_name -- corroborating that 2009 is a real, stable venue, but not evidence these are the same club; kept as two distinct afl_club_id rows, no merge.'),
  ('1151','Complexo Lúdico União D. R. Santa Maria','1829',94.0,60.0,'Relvado Sintético','Locality: Odivelas. Venue number 1829 -- CONFIRMED: matches the official AFL 2026/27 document for Santa Maria (afl_club_id 1151), registered across three séries (squads A, B and C) this season, all at this same confirmed venue.'),
  ('1095','Estádio Universitário (Campo Nr.5)','2182',100.0,65.0,'Relvado Sintético','Locality: Lisboa. Venue number 2182 -- CONFIRMED: matches the official AFL 2026/27 document for Sporting, SAD (afl_club_id 1095), registered across two séries this season, both at this same confirmed venue.'),
  ('376','Campo Bº Padre Cruz (Unidos)','1753',94.0,56.0,'Relvado Sintético','Locality: Lisboa. Venue number 1753 -- CONFIRMED: matches the official AFL 2026/27 document for Unidos (afl_club_id 376).'),
  ('1209','Campo do Vitória','1894',100.0,60.0,'Relvado Sintético','Locality: Lisboa. Venue number 1894 -- CONFIRMED: matches the official AFL 2026/27 document for Vitória (afl_club_id 1209).')
) as v(afl_club_id, venue_name, afl_venue_code, pitch_length_m, pitch_width_m, surface, notes)
join public.federation_clubs fc on fc.afl_club_id = v.afl_club_id
where not exists (
  select 1 from public.federation_club_venues ev
  where ev.club_id = fc.id
    and (
      (ev.afl_venue_code is not null and v.afl_venue_code is not null and ev.afl_venue_code = v.afl_venue_code)
      or ev.venue_name = v.venue_name
      or (
        (ev.afl_venue_code is null or v.afl_venue_code is null)
        and public.gate11_normalize_venue_name(ev.venue_name) = public.gate11_normalize_venue_name(v.venue_name)
      )
    )
);

-- ── Locality (federation_clubs.locality). municipality left NULL -- the   ──
-- ── source gives one locality string per club/venue and never separately ──
-- ── labels a distinct "municipality" field; inventing that split would   ──
-- ── add structure the source doesn't state.                              ──
update public.federation_clubs fc set locality = loc.locality
from (values
  ('762','Ericeira'), ('2159','Igreja Nova - Mafra'), ('4421','Fonte Grada - Torres Vedras'),
  ('1081','Lourinhã'), ('277','Alcainça'), ('137','Malveira'), ('353','Montelavar'),
  ('1004','Torres Vedras'), ('315','Venda do Pinheiro'), ('1114','Vila Verde'),
  ('955','Alenquer'), ('471','Alverca'), ('590','Azambuja'), ('53','Carregado'),
  ('813','Castanheira do Ribatejo'), ('2712','Catujal / Sacavém'), ('1125','Póvoa Santa Iria'),
  ('1002','São João da Talha'), ('365','Santa Iria da Azóia'), ('147','Santo Antão do Tojal'),
  ('1216','Zambujal'), ('908','Alto do Lumiar'), ('4887','Alto do Lumiar'), ('50','Bobadela - Sacavém'),
  ('577','Camarate'), ('5629','Parque das Nações - Lisboa'), ('2595','Lumiar / Lisboa'),
  ('283','Olivais'), ('1033','Olivais - Lisboa'), ('190','Olivais Sul - Lisboa'), ('703','Ponte Frielas'),
  ('1017','Sacavém'), ('5919','Marvila - Lisboa'), ('145','Lisboa'), ('180','Lisboa'),
  ('5647','Restelo - Lisboa'), ('328','Lisboa'), ('391','Marvila - Lisboa'),
  ('5560','Bº Encarnação / Lisboa'), ('1151','Odivelas'), ('1095','Lisboa'), ('376','Lisboa'), ('1209','Lisboa')
) as loc(afl_club_id, locality)
where fc.afl_club_id = loc.afl_club_id and fc.locality is null;
