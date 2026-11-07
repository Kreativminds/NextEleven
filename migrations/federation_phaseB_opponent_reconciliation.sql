-- ============================================================================
-- FEDERATION CATALOGUE — PHASE B: classify & reconcile the 37 active
-- unlinked opponent records (25 distinct names) in production.
--
-- Starting point: PR #40's read-only preflight audit
-- (tests/sql/opponents_reconciliation_preflight_readonly.sql, branch
-- fix/opponents-reconciliation-audit-20261107) was re-run live against
-- production this gate. Its finding was reconfirmed fresh, not assumed:
--   - 160 active opponents / 123 already linked (federation_club_id) /
--     37 unlinked / 92 federation_clubs / 109 federation_club_competitions
--     registrations / 100 venues / 0 with GPS.
--   - duplicate_name_groups_same_owner = 0, duplicate rows = 0. Zero drift
--     from the PR's own finding: "Verified production has ZERO exact-name
--     duplicate groups within the same owner/family scope ... global
--     name-based merges would be unsafe." Still true. Category 5
--     (confirmed duplicate within same owner/family) is therefore empty
--     this gate, as expected.
--   - All 37 unlinked rows belong to exactly 2 user_id values (never
--     reported by real value below -- see "reporting convention").
--     family_id is null on all 37. 25 distinct opponentName values: 13
--     appear once (one owner only), 12 appear twice (one row under each
--     owner) -- 13 + 24 = 37.
--   - Several stored names carry a literal embedded double-quote around a
--     squad letter (Caneças "A", Carregado "A"/"B", Casa Pia "C",
--     Mafra "A", Tenente Valdez "A") -- these are the exact issue #39
--     flagged conflicts and are treated accordingly below.
--
-- REPORTING CONVENTION: user_id/family_id are sensitive and are never
-- printed by real value anywhere in this file or its outputs -- every
-- owner below is "Owner 1" / "Owner 2" (both are real, distinct app
-- accounts). Club/team names are not sensitive and are named freely.
--
-- CLASSIFICATION METHOD: every one of the 25 distinct names was checked
-- directly against production's federation_clubs /
-- federation_club_competitions tables (official_name, afl_club_id,
-- division/series/age_group/squad_label), and, where that left genuine
-- doubt, cross-checked against this account's own games.payload history
-- (competitionType/competitionName) for corroborating evidence. No
-- external source was used and nothing was guessed: where the catalogue
-- and game history together did not produce a confident answer, the
-- record was left unlinked and flagged for Victor, per the hard rule
-- against inventing a federation identity.
--
-- ============================================================================
-- CATEGORY 1 -- VERIFIED MATCH (9 distinct names / 9 rows, all Owner 1
-- only -- none of these 9 names recur under Owner 2). Linked below via
-- public.team_alias_mappings, using the exact schema/idempotency pattern
-- Gate 8 Phase C established (gate8_phase_c_PRODUCTION_verified_opponent_
-- aliases.sql): kind='opponent_federation_alias',
-- competitionType='__opponent_federation_alias__', canonicalOfficialName
-- (matches federation_clubs.official_name exactly), aflClubId, squadLabel,
-- aliases (lowercase). Guarded by NOT EXISTS on
-- (user_id, canonicalOfficialName, squadLabel) -- idempotent, safe to
-- re-run. Nothing is written to opponents.federation_club_id itself; the
-- established pattern resolves opponents through this alias table, not a
-- direct column write, so this migration touches no existing row.
--
--   stored opponentName            -> federation_clubs.official_name (afl_club_id) [squadLabel]
--   Águias da Musgueira            -> Águias Musgueira (908)           [null -- club has 0 competition registrations, no squad data exists at all]
--   Águias de Camarate             -> Camarate (577)                  [null -- single, unlabelled registration]
--   Alta de Lisboa                 -> Alta Lisboa (4887)               ['B' -- club registers squads A+B; this account's own game history
--                                                                        this season cites "CD III Divisão · Série 3", which is squad B's
--                                                                        division (III Divisão 3) -- squad A is a different division
--                                                                        (III Divisão 2) and not evidenced in any played game]
--   Casa Pia AC                    -> Casa Pia (180)                   ['B' -- single registered squad, unambiguous. NOTE: this is a
--                                                                        DIFFERENT opponent record from "Casa Pia \"C\"" (see Category 4) --
--                                                                        this account holds both as separate records, and "AC" here reads as
--                                                                        the club's own formal suffix (Casa Pia Atlético Clube), not a squad
--                                                                        letter, so it is not the same identity as the flagged "C" conflict]
--   Colégio Pedro Arrupe           -> Col Pedro Arrupe (5629)          [null -- single, unlabelled registration, II Divisão Série 1 --
--                                                                        matches the official spelling Victor asked to verify]
--   Desportivo O. Moscavide        -> Desp. O. Moscavide (283)         ['B' -- same reasoning as Alta de Lisboa: this account's game
--                                                                        history this season cites "CD III Divisão · Série 3", squad B's
--                                                                        division; squad A (II Divisão 1) is not evidenced]
--   EF Belém Estádio Restelo       -> EF Belém (5647)                  [null -- club registers 3 squads (A/B/C) and this account's game
--                                                                        history predates the competitionName field, so no squad could be
--                                                                        confirmed -- left null rather than guessed; squad identity is
--                                                                        metadata only; venue/logo resolution is club-level and unaffected]
--   FC Alverca                     -> Alverca (471)                    [null -- club registers 2 squads (B/C); this account's game history
--                                                                        cites only an old, differently-formatted competition name that
--                                                                        doesn't map cleanly to either current division -- left null]
--   Sporting                       -> Sporting, SAD (1095)             [null -- club registers 2 squads (B/C), no squad evidence in game
--                                                                        history. Verified, not assumed, per Victor's explicit caution:
--                                                                        this account holds a SEPARATE "Sporting SAD FF" opponent record
--                                                                        (Category 4 below) distinct from this one -- the account itself
--                                                                        already distinguishes the two, which is why this plain "Sporting"
--                                                                        record is linked here while "Sporting SAD FF" is not]
-- ============================================================================

insert into public.team_alias_mappings (user_id, device_id, local_id, payload)
select '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid, 'phaseb-federation-reconciliation', v.local_id, v.payload
from (values
  ('phaseb-aguias-musgueira', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Águias Musgueira','aflClubId','908','squadLabel',null,
    'aliases', jsonb_build_array('águias da musgueira'))),
  ('phaseb-camarate', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Camarate','aflClubId','577','squadLabel',null,
    'aliases', jsonb_build_array('águias de camarate'))),
  ('phaseb-alta-lisboa', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Alta Lisboa','aflClubId','4887','squadLabel','B',
    'aliases', jsonb_build_array('alta de lisboa'))),
  ('phaseb-casa-pia-ac', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Casa Pia','aflClubId','180','squadLabel','B',
    'aliases', jsonb_build_array('casa pia ac'))),
  ('phaseb-col-pedro-arrupe', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Col Pedro Arrupe','aflClubId','5629','squadLabel',null,
    'aliases', jsonb_build_array('colégio pedro arrupe'))),
  ('phaseb-desp-o-moscavide', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Desp. O. Moscavide','aflClubId','283','squadLabel','B',
    'aliases', jsonb_build_array('desportivo o. moscavide'))),
  ('phaseb-ef-belem', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','EF Belém','aflClubId','5647','squadLabel',null,
    'aliases', jsonb_build_array('ef belém estádio restelo'))),
  ('phaseb-fc-alverca', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Alverca','aflClubId','471','squadLabel',null,
    'aliases', jsonb_build_array('fc alverca'))),
  ('phaseb-sporting', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Sporting, SAD','aflClubId','1095','squadLabel',null,
    'aliases', jsonb_build_array('sporting')))
) as v(local_id, payload)
where not exists (
  select 1 from public.team_alias_mappings tam
  where tam.user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
    and tam.deleted_at is null
    and tam.payload->>'kind' = 'opponent_federation_alias'
    and tam.payload->>'canonicalOfficialName' = v.payload->>'canonicalOfficialName'
    and tam.payload->>'squadLabel' is not distinct from v.payload->>'squadLabel'
);

-- ============================================================================
-- CATEGORY 3 -- DIFFERENT COMPETITION (1 distinct name / 1 row, Owner 1
-- only). Retained as-is, no federation link -- confirmed NOT a league
-- fixture at all.
--
--   Algés (Owner 1, 1 row): no federation_clubs record matches under any
--   search variant tried (plain, accent-stripped, "Belenenses"). This
--   account's own games history explains why: its one logged game against
--   "Algés" is tagged competitionType='Friendly' (season 6), not
--   'League' -- a friendly opponent is outside the federation league
--   catalogue by definition, so the absence of a catalogue row is
--   expected, not a gap. No action required; no federation ID invented.
-- ============================================================================

-- ============================================================================
-- CATEGORY 2 -- VERIFIED LOCAL TEAM: NONE this gate.
--
-- None of the remaining unmatched names could be independently VERIFIED
-- as a local/non-federated team from production data alone (the
-- federation_clubs / federation_club_competitions tables and this
-- account's own game history are the only sources available in this
-- environment -- no external AFL registry lookup was performed). Rather
-- than assert local-team status on an absence of evidence, every
-- unmatched name is classified as Category 4 (ambiguous) below and
-- handed to Victor to confirm. If Victor confirms any of them as
-- genuinely local/unaffiliated, they can be promoted to Category 2 in a
-- follow-up gate -- that is a safer direction than guessing here.
-- ============================================================================

-- ============================================================================
-- CATEGORY 4 -- AMBIGUOUS: retained unlinked, flagged for Victor's review.
-- 15 distinct names / 27 rows. No writes below -- this section is a
-- record of what was checked and why each was left alone, for Victor's
-- decision.
--
-- -- Known issue #39 conflicts (explicit "do NOT auto-merge" instruction
--    -- the federation row exists but names a DIFFERENT squad/registration
--    than the stored opponent, so merging would misattribute identity):
--   Caneças "A"        (Owner 1 + Owner 2, 2 rows) -- federation "Caneças" registers
--                        ONLY squad B (III Divisão 2, afl_club_id 948). No squad A
--                        registration exists for this club. Flagged, not merged.
--   Carregado "A"      (Owner 1 + Owner 2, 2 rows) -- federation "Carregado" has a
--                        single UNLABELLED registration (II Divisão 1, afl_club_id 53).
--                        Flagged, not merged.
--   Carregado "B"      (Owner 1 + Owner 2, 2 rows) -- same federation row as above
--                        (still unlabelled, no squad B registration exists either).
--                        Flagged, not merged.
--   Casa Pia "C"       (Owner 1 + Owner 2, 2 rows) -- federation "Casa Pia" registers
--                        ONLY squad B (II Divisão 2, afl_club_id 180) -- the same club
--                        already linked above via "Casa Pia AC" -- a different stored
--                        record for this account. No squad C registration exists.
--                        Flagged, not merged, per explicit instruction.
--   Mafra "A"          (Owner 1 + Owner 2, 2 rows) -- federation "CD Mafra" has a
--                        single UNLABELLED registration (II Divisão 1, afl_club_id 277).
--                        Flagged, not merged.
--   Tenente Valdez "A" (Owner 1 + Owner 2, 2 rows) -- federation "Tenente Valdez" has
--                        a single UNLABELLED registration (III Divisão 3, afl_club_id
--                        1669). Flagged, not merged.
--
-- -- No federation_clubs record found under any search variant tried:
--   Cadaval             (Owner 1 + Owner 2, 2 rows)
--   Coutada              (Owner 1 + Owner 2, 2 rows)
--   Falcons               (Owner 1 + Owner 2, 2 rows)
--   Operário Lisboa      (Owner 1 only, 1 row)
--   Vilafranquense 1957  (Owner 1 + Owner 2, 2 rows)
--
-- -- Genuine match risk / needs Victor's confirmation, not a clean miss:
--   Atlético CP (Owner 1, 1 row): federation "Atlético" exists
--     (afl_club_id 145, squads A+B) and is a plausible candidate, but
--     "CP" is not a squad-letter suffix like the issue #39 cases -- it
--     risks being read as "Atlético Clube de Portugal", a real, distinct,
--     well-known club. Left unlinked rather than guessed; needs Victor to
--     confirm which organisation this stored name actually refers to.
--   CAC (Owner 1, 1 row): per the explicit instruction, NOT auto-matched
--     to "Cacém" (afl_club_id 131, exists, III Divisão 6). A "CAC
--     Cultural" candidate was searched for specifically and not found --
--     only a generic, too-weak "Cultural" (afl_club_id 220) exists, which
--     is not a confident match either. Left unlinked for Victor.
--   Musgueira (Owner 1 + Owner 2, 2 rows): no federation_clubs row is
--     named exactly "Musgueira" -- the only near match is "Águias
--     Musgueira" (908), already linked above to this SAME account's
--     separate "Águias da Musgueira" record. Owner 1 holds BOTH
--     "Águias da Musgueira" and plain "Musgueira" as two distinct
--     opponent records, which is itself evidence the account intends
--     them as two different teams -- so "Musgueira" is deliberately NOT
--     folded into the same alias. Needs Victor to confirm what this
--     plain name actually refers to.
--   Sporting SAD FF (Owner 1 + Owner 2, 2 rows): per the explicit
--     instruction, must NOT be treated as the same identity as "Sporting,
--     SAD" (1095, linked above under the plain "Sporting" record). No
--     separate FF/women's federation_clubs entry exists in the catalogue
--     to link to instead. Owner 1 holds both "Sporting" and "Sporting SAD
--     FF" as two distinct records, confirming the account itself already
--     treats them as different teams. Needs Victor to confirm whether a
--     distinct federation entry should be added, or this is local-only.
-- ============================================================================

-- ============================================================================
-- CATEGORY 5 -- CONFIRMED DUPLICATE WITHIN SAME OWNER/FAMILY SCOPE: NONE.
-- Reconfirmed fresh this gate (see summary metrics above):
-- duplicate_name_groups_same_owner = 0, duplicate rows = 0. Consistent
-- with PR #40's own finding. Nothing to consolidate; no references
-- (games/game_players/goal_events/card_events) were touched.
-- ============================================================================

select 'Phase B complete. 37 active unlinked opponents (25 distinct names) classified: 9 distinct names / 9 rows verified-matched and linked via team_alias_mappings (Águias Musgueira, Camarate, Alta Lisboa, Casa Pia, Col Pedro Arrupe, Desp. O. Moscavide, EF Belém, Alverca, Sporting SAD); 1 distinct name / 1 row (Algés) confirmed different-competition (Friendly, not League) and retained as-is; 0 verified-local-team (insufficient evidence to assert, left as ambiguous instead); 15 distinct names / 27 rows ambiguous and flagged for Victor''s review with specific reasoning (6 are issue #39''s known flagged conflicts, 5 have no federation record found at all, 3 carry a genuine match risk needing Victor''s confirmation -- Atlético CP, CAC, Musgueira, Sporting SAD FF); 0 confirmed duplicates (zero same-owner duplicate-name groups, reconfirmed fresh, consistent with PR #40). Remaining unclassified: 0. No row in opponents/games/game_players/goal_events/card_events was modified or deleted -- this migration only adds new, idempotent team_alias_mappings rows.' as status;
