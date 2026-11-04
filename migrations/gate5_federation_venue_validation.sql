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
--     anywhere in the source. Per the existing federation_club_venues
--     schema comment ("never populated until a source actually confirms
--     what it denotes"), afl_venue_code is deliberately left NULL here --
--     the number is recorded only in `notes`, explicitly caveated, not
--     promoted to a confirmed identifier column.
--
-- NOT SEEDED / LEFT UNRESOLVED (per "do not invent... leave unresolved and
-- report exactly what is missing"):
--   - Carregado's venue_number reads "23" in both extraction passes --
--     anomalously low versus every other value in the dataset (next-lowest
--     is 131; most are in the 1000s-5000s). Flagged as a likely transcription
--     artifact in the source or extraction rather than silently trusted;
--     recorded in `notes` as unverified pending a direct re-check of the PDF.
--   - A venue numbered 3449 ("Alto Lumiar Campo 2," ~100.0x60.0) is
--     referenced in Série III fixtures but attached to no club in the club
--     table in either extraction pass -- which club uses it was "not
--     captured." No federation_club_venues row is created for it (the
--     table requires a club_id); reported here as a genuine gap, not
--     guessed.
--   - GPS coordinates and street addresses: not present in this source at
--     all, for any club. Not invented.
--
-- MULTI-VENUE / SHARED-VENUE CASES CAPTURED (lower-confidence items kept
-- in `notes` as text rather than structured numeric columns, since they
-- come from a single fixture mention, not the double-extracted main table):
--   - Sacavenense ("B" and "C", same afl_club_id 1017) share their primary
--     venue 1518, AND a separate fixture elsewhere references a second
--     venue for this club: "Complexo Desportivo Elias Pereira - Campo Nº 3"
--     (venue_number 2061, ~90.0x45.0 per that one mention only).
--   - Salesianos Lisboa's club-table venue is 2009 ("Campo Fernando
--     Perfeito"), but a separate fixture lists this club at a different
--     venue: "Complexo Desportivo Bairro Boavista" (venue_number 3048,
--     ~92.0x47.0, locality Monsanto) -- a second, lower-confidence venue
--     for the same club.
--   - Águias Musgueira "A" and Alta Lisboa share venue 3348.
--   - AD Pastéis and Oriental share venue 1945 -- this pairing was not on
--     Victor's original flagged-case list, but is directly supported by
--     both extraction passes, so included for completeness rather than
--     dropped for not having been asked for by name.

alter table public.federation_club_venues add column if not exists afl_venue_code_unconfirmed_note text;

-- ── Primary venues (one row per club, from the double-extracted club table) ──
insert into public.federation_club_venues (club_id, venue_name, pitch_length_m, pitch_width_m, surface, notes)
select fc.id, v.venue_name, v.pitch_length_m, v.pitch_width_m, v.surface, v.notes
from (values
  ('762','Campo Henrique Tomás Frade',101.0,56.0,'Relvado Sintético','Locality: Ericeira. Source venue number (unconfirmed as an official ID): 195.'),
  ('2159','Campo Domingos Pinto Jorge - Igreja Nova',90.0,45.0,'Relvado Sintético','Locality: Igreja Nova - Mafra. Source venue number (unconfirmed): 1896.'),
  ('4421','Campo da Tapadinha / Fonte Grada / TVD',96.0,55.0,'Relvado Sintético','Locality: Fonte Grada - Torres Vedras. Source venue number (unconfirmed): 1782.'),
  ('1081','Estádio Municipal Lourinhã Nº 2',100.0,64.0,'Relvado Sintético','Locality: Lourinhã. Source venue number (unconfirmed): 1942.'),
  ('277','Campo João Simões - Alcainça',100.0,55.0,'Relvado Sintético','Locality: Alcainça. Source venue number (unconfirmed): 2968.'),
  ('137','Campo José Alegre (Nº2 Malveira)',90.0,54.0,'Relvado Sintético','Locality: Malveira. Source venue number (unconfirmed): 1912.'),
  ('353','Campo do Vimal - Montelavar',92.0,58.0,'Relvado Sintético','Locality: Montelavar. Source venue number (unconfirmed): 1955.'),
  ('1004','Academia Torreense 2 / Complexo Desportivo de Arenes',102.0,66.0,'Piso Sintético','Locality: Torres Vedras. Source venue number (unconfirmed): 5912.'),
  ('315','Estádio Municipal Venda do Pinheiro',100.0,64.0,'Relvado Sintético','Locality: Venda do Pinheiro. Source venue number (unconfirmed): 1958.'),
  ('1114','Campo Afonso Araújo Sommer',96.0,60.0,'Relvado Sintético','Locality: Vila Verde. Source venue number (unconfirmed): 1956.'),
  ('955','Campo Fernando Manuel Pereira (Alenquer)',99.0,60.0,'Relvado Sintético','Locality: Alenquer. Source venue number (unconfirmed): 2162.'),
  ('471','Centro Formação FC Alverca / Century 21 / Imoteam / Campo 1',105.0,68.0,'Relvado Sintético','Locality: Alverca. Source venue number (unconfirmed): 5117.'),
  ('590','Estádio Municipal Azambuja',null,null,'Relvado Sintético','Locality: Azambuja. Source venue number (unconfirmed): 4148. Pitch dimensions NOT given in the club table (fixtures show "(x)" placeholder) -- left unresolved rather than invented.'),
  ('53','Campo José Lacerda Pinto Barreiros',100.0,64.0,'Relvado Sintético','Locality: Carregado. Source venue number (unconfirmed): 23 -- FLAGGED: anomalously low vs. every other venue number in this dataset (next-lowest is 131); likely transcription artifact. Recommend direct re-check against the source PDF before treating as reliable.'),
  ('813','Campo São João',100.0,61.0,'Relvado Sintético','Locality: Castanheira do Ribatejo. Source venue number (unconfirmed): 1323.'),
  ('2712','Campo 1º Maio Catujal',100.0,54.0,'Relvado Sintético','Locality: Catujal / Sacavém. Source venue number (unconfirmed): 2229.'),
  ('1125','Comp. Desp. Qta Piedade Campo Nº 1',104.0,64.0,'Relvado Sintético','Locality: Póvoa Santa Iria. Source venue number (unconfirmed): 2716.'),
  ('1002','Campo do SC Sanjoanense',90.0,49.0,'Relvado Sintético','Locality: São João da Talha. Source venue number (unconfirmed): 1886.'),
  ('365','Campo Atlético Reynolds',100.0,56.0,'Relvado Sintético','Locality: Santa Iria da Azóia. Source venue number (unconfirmed): 2212.'),
  ('147','Campo Meia Laranja',91.0,56.0,'Relvado Sintético','Locality: Santo Antão do Tojal. Source venue number (unconfirmed): 1849.'),
  ('1216','Campo Conde Mendia - Zambujalense',100.0,64.0,'Relvado Sintético','Locality: Zambujal. Source venue number (unconfirmed): 2221.'),
  ('908','Complexo Desportivo Alto Lumiar Campo 1',105.0,65.0,'Relvado Sintético','Locality: Alto do Lumiar. Source venue number (unconfirmed): 3348. SHARED venue -- also used by Alta Lisboa (afl_club_id 4887).'),
  ('4887','Complexo Desportivo Alto Lumiar Campo 1',105.0,65.0,'Relvado Sintético','Locality: Alto do Lumiar. Source venue number (unconfirmed): 3348. SHARED venue -- also used by Águias Musgueira "A" (afl_club_id 908).'),
  ('50','Parque Desp. Munic. Bobadela',100.0,57.0,'Relvado Sintético','Locality: Bobadela - Sacavém. Source venue number (unconfirmed): 2214.'),
  ('577','Campo Quinta Barros',90.0,52.0,'Relvado Sintético','Locality: Camarate. Source venue number (unconfirmed): 1482.'),
  ('5629','Campo Colégio Pedro Arrupe',100.0,50.0,'Relvado Sintético','Locality: Parque das Nações - Lisboa. Source venue number (unconfirmed): 4753.'),
  ('2595','Campo Colégio São João Brito - Sintético',95.0,45.0,'Relvado Sintético','Locality: Lumiar / Lisboa. Source venue number (unconfirmed): 1862.'),
  ('283','Estádio Alfredo Marques Augusto',102.0,68.0,'Relvado Sintético','Locality: Olivais. Source venue number (unconfirmed): 222.'),
  ('1033','Campo Branca Lucas',100.0,65.0,'Relvado Sintético','Locality: Olivais - Lisboa. Source venue number (unconfirmed): 1511.'),
  ('190','Campo do Olivais Sul',101.0,68.0,'Relvado Sintético','Locality: Olivais Sul - Lisboa. Source venue number (unconfirmed): 1853.'),
  ('703','Campo Bonjardim',100.0,63.0,'Relvado Sintético','Locality: Ponte Frielas. Source venue number (unconfirmed): 131.'),
  ('1017','Complexo Desportivo Elias Pereira - Campo Nº 1',100.0,64.0,'Relvado Sintético','Locality: Sacavém. Source venue number (unconfirmed): 1518. SHARED between this club''s own "B" and "C" squads (same afl_club_id). Also, per a separate single fixture mention (not cross-checked to the same bar as this row): this club also uses "Complexo Desportivo Elias Pereira - Campo Nº 3" (venue number 2061, ~90.0x45.0) -- recorded here as a note only, not as a second structured row, pending stronger confirmation.'),
  ('5919','Campo Ferroviário-Marvila',102.0,64.0,'Relvado Sintético','Locality: Marvila - Lisboa. Source venue number (unconfirmed): 1945. SHARED venue -- also used by Oriental (afl_club_id 391). Not on Victor''s original flagged-case list; included because both extraction passes agree on it.'),
  ('145','Campo Manuel Candeias - Estádio Tapadinha',93.0,53.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 1373.'),
  ('180','Estádio Pina Manique Nº 2',90.0,60.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 204.'),
  ('5647','Campo Nº 3 Restelo',90.0,45.0,'Relvado Sintético','Locality: Restelo - Lisboa. Source venue number (unconfirmed): 1641.'),
  ('328','Campo Nº2 Estádio Francisco Lázaro',90.0,45.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 1335.'),
  ('391','Campo Ferroviário-Marvila',102.0,64.0,'Relvado Sintético','Locality: Marvila - Lisboa. Source venue number (unconfirmed): 1945. SHARED venue -- also used by AD Pastéis (afl_club_id 5919).'),
  ('5560','Campo Fernando Perfeito',90.0,45.0,'Relvado Sintético','Locality: Bº Encarnação / Lisboa. Source venue number (unconfirmed): 2009. Per a separate single fixture mention (lower confidence than this row): this club is also listed at "Complexo Desportivo Bairro Boavista" (venue number 3048, ~92.0x47.0, locality Monsanto) -- recorded as a note only, not as a second structured row.'),
  ('1151','Complexo Lúdico União D. R. Santa Maria',94.0,60.0,'Relvado Sintético','Locality: Odivelas. Source venue number (unconfirmed): 1829.'),
  ('1095','Estádio Universitário (Campo Nr.5)',100.0,65.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 2182.'),
  ('376','Campo Bº Padre Cruz (Unidos)',94.0,56.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 1753.'),
  ('1209','Campo do Vitória',100.0,60.0,'Relvado Sintético','Locality: Lisboa. Source venue number (unconfirmed): 1894.')
) as v(afl_club_id, venue_name, pitch_length_m, pitch_width_m, surface, notes)
join public.federation_clubs fc on fc.afl_club_id = v.afl_club_id
where not exists (
  select 1 from public.federation_club_venues ev where ev.club_id = fc.id and ev.venue_name = v.venue_name
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
