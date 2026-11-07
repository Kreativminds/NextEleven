-- ============================================================================
-- GATE 8.5 / PHASE C — verified opponent/federation-club alias mappings.
-- STATUS: PREPARED and TESTED on the isolated test project. NOT APPLIED
-- to production. Requires Victor's explicit approval before this runs
-- anywhere near wicydcvdakqopodbxtrl, and requires Phase A (catalogue +
-- the corrected _opponent_lookup_for_user) and Phase B (frontend) to be
-- live first.
--
-- CLARIFYING THE ROW COUNT (Victor's own question): the four identities
-- described in prose become FIVE alias rows, not four, because "Olivais
-- A and B, plus SL Olivais" names two different squad registrations
-- (squad A and squad B are separate federation_club_competitions rows
-- for the same club) and squad distinctions must be preserved as
-- different canonical identities, not merged into one row. "SL Olivais
-- 2014" is also kept as its own row (not folded into squad A) per
-- Victor's explicit instruction to preserve its birth-year identity,
-- even though it resolves to the same AFL club.
--
-- Verified against production (read-only, 2026-11-05) for Victor's own
-- account (user_id 563dea01-03a6-4e74-8cac-131cb39ccd97): every real
-- opponents row (active AND soft-deleted) whose name contains "olivais"
-- or "benfica", so the alias coverage below is checked against the
-- actual data, not assumed:
--
--   id       opponentId  opponentName          deleted?  -> covered by
--   7f2db349 613         Benfica               yes       -> EXCLUDED (ambiguous, per Victor's explicit instruction -- NOT aliased)
--   24291b4c 666         Benfica SAD "B"       yes       -> Row 4 (alias 'benfica sad "b"')
--   8ec238e7 806         Benfica SAD "B"       no        -> Row 4 (same alias text, same row)
--   6f54a579 1           Fut. Benfica          no        -> Row 5 (alias 'fut. benfica')
--   e1836cc5 671         Futebol Benfica       yes       -> Row 5 (alias 'futebol benfica', same row)
--   3e3886a3 811         Futebol Benfica       no        -> Row 5 (same alias text, same row)
--   2fd2c500 648         Olivais "A"           yes       -> Row 1 (alias 'olivais "a"')
--   eb1fc8b6 788         Olivais "A"           no        -> Row 1 (same alias text, same row)
--   0ef55d7a 672         Olivais "B"           yes       -> Row 2 (alias 'olivais "b"')
--   e1c6765a 812         Olivais "B"           no        -> Row 2 (same alias text, same row)
--   0b611e22 799         Olivais Sul           no        -> NOT ALIASED (a genuinely different club -- see note below)
--   947ae575 6           SL Olivais            no        -> Row 1 (alias 'sl olivais', same row as Olivais "A")
--   100b0d5e 607         SL Olivais 2014       no        -> Row 3 (alias 'sl olivais 2014', its own row)
--
-- "Olivais Sul" (opponent_id 799) is NOT one of Victor's four verified
-- identities and is deliberately left unaliased here -- it is a
-- different club (proven, not assumed: Gate 7's regression test
-- confirmed the Olivais alias does not pull in "Olivais Sul", and
-- nothing in Victor's instructions names it). If it later needs its
-- own federation link, that is a fifth, separate decision, not part of
-- this gate.
--
-- Net effect once applied: 11 of these 13 real opponents rows gain a
-- federation-club resolution (venue/logo once the catalogue itself is
-- enriched with that data -- see the Gate 8.3 limitation note); the
-- ambiguous "Benfica" row and "Olivais Sul" are correctly left alone.
--
-- Each row uses the exact schema Gate 7 shipped and this gate's
-- corrected resolver (gate8_security_hardening_and_public_page_fix.sql)
-- actually reads: kind='opponent_federation_alias',
-- competitionType='__opponent_federation_alias__', canonicalOfficialName
-- (must match federation_clubs.official_name exactly), aflClubId,
-- squadLabel, aliases (lowercase text array). device_id/local_id are
-- required NOT NULL columns on team_alias_mappings -- 'gate8-phase-c'
-- is a placeholder; the real deployment should use whatever device/sync
-- identifiers the app's own sync layer assigns when a user saves an
-- alias, not a hardcoded literal (this file is a reviewed template, not
-- a verbatim production script, for exactly this reason -- replace
-- these two columns at apply time, or drive this insert from the app's
-- own DB.put() path during Phase C instead of raw SQL).
--
-- Idempotent: safe to re-run -- guarded by NOT EXISTS on
-- (user_id, canonicalOfficialName, squadLabel), which is the real
-- identity for this user's federation opponent aliases (a user has at
-- most one alias row per club+squad).
-- ============================================================================

-- VERIFIED LIVE on the isolated test project, 2026-11-05 (using the
-- fixture user 00000000-0000-0000-0000-00000000a001, never Victor's
-- real user_id -- this template was not run against his data):
--   - Inserted these 5 rows, re-ran the identical statement a second
--     time: row count unchanged both times. Idempotent.
--   - Called get_public_team_data_opponent_slice for every one of the
--     13 real opponentName strings found on Victor's production
--     account (the table above), through the actual token-gated public
--     RPC path, with each catalogue club's map_url temporarily set to
--     a unique marker string so the result could be checked by WHICH
--     club it reached, not just whether it returned something:
--       Olivais "A", Olivais "B", SL Olivais 2014  -> all -> club 1033 (correct, same club, squads preserved only as alias metadata)
--       Benfica SAD "B"                             -> club 1023 (correct, distinct from Futebol Benfica)
--       Fut. Benfica, Futebol Benfica                -> both -> club 328 (correct)
--       Olivais Sul                                  -> club 190, its OWN distinct club -- confirmed NOT pulled into the Olivais-1033 alias
--       Benfica (the ambiguous historical record)     -> zero rows -- confirmed correctly left unaliased
--       SL Olivais                                    -> resolved via this fixture user's own local opponents row (step 1), proving local-opponent priority still wins over the alias even though 'sl olivais' is also in Row 1's aliases array
--     The four marker values were reverted to null immediately after.
insert into public.team_alias_mappings (user_id, device_id, local_id, payload)
select '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid, 'gate8-phase-c', v.local_id, v.payload
from (values
  ('row-1-olivais-a', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Olivais','aflClubId','1033','squadLabel','A',
    'aliases', jsonb_build_array('olivais "a"','sl olivais'))),
  ('row-2-olivais-b', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Olivais','aflClubId','1033','squadLabel','B',
    'aliases', jsonb_build_array('olivais "b"'))),
  ('row-3-sl-olivais-2014', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Olivais','aflClubId','1033','squadLabel','2014',
    'aliases', jsonb_build_array('sl olivais 2014'))),
  ('row-4-benfica-sad-b', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Benfica, SAD','aflClubId','1023','squadLabel','B',
    'aliases', jsonb_build_array('benfica sad "b"'))),
  ('row-5-futebol-benfica', jsonb_build_object(
    'kind','opponent_federation_alias','competitionType','__opponent_federation_alias__',
    'canonicalOfficialName','Futebol Benfica','aflClubId','328','squadLabel',null,
    'aliases', jsonb_build_array('fut. benfica','futebol benfica')))
) as v(local_id, payload)
where not exists (
  select 1 from public.team_alias_mappings tam
  where tam.user_id = '563dea01-03a6-4e74-8cac-131cb39ccd97'::uuid
    and tam.deleted_at is null
    and tam.payload->>'kind' = 'opponent_federation_alias'
    and tam.payload->>'canonicalOfficialName' = v.payload->>'canonicalOfficialName'
    -- NULL-safe equality: Row 5's squadLabel is a real JSON null, so
    -- ->> on it already yields SQL NULL on both sides when it repeats.
    and tam.payload->>'squadLabel' is not distinct from v.payload->>'squadLabel'
);
