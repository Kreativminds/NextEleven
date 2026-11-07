-- ============================================================================
-- GATE 13.5 — Phase A exact production migration execution plan.
-- PREPARED, NOT EXECUTED. Consolidates Gate 12.2/12.3 into one ready-to-run
-- plan; does not repeat their full reasoning (see those files for why).
-- ============================================================================

-- ORDERED MIGRATION FILES (run each file's full, unmodified, committed SQL
-- content, in this exact order -- file paths are the source of truth, not
-- pasted here in full, since they are already committed and unchanged):
--   1. migrations/gate3_federation_catalogue.sql
--   2. migrations/gate4_federation_clubs_seed.sql   (run its own conflict-
--      report SELECT first, review output, then its INSERT)
--   3. migrations/gate4_remediation_federation_clubs_full_roster.sql
--   4. migrations/gate5_federation_venue_validation.sql     (Gate 11 fixed)
--   5. migrations/gate5_resolution_afl_official_2026_27.sql (Gate 11 fixed)
--   6. migrations/gate8_security_hardening_and_public_page_fix.sql,
--      PART 1 ONLY -- the REVOKE block, inlined below for at-a-glance review:

--      revoke insert, update, delete, truncate, references, trigger
--        on public.federation_clubs, public.federation_club_competitions, public.federation_club_venues
--        from anon, authenticated;
--      revoke all on public.team_alias_mappings from anon;
--      revoke truncate, references, trigger on public.team_alias_mappings from authenticated;

-- The two statements with the ONLY real historical failure risk (these are
-- exactly what threw a real 23505 in Gate 10.3's unfixed rehearsal, and
-- what Gate 11's clean rehearsal proved run clean, twice) -- inlined for
-- at-a-glance review, inside file 5 above:
--   create unique index ... on public.federation_club_venues (club_id, afl_venue_code) where afl_venue_code is not null;
--   create unique index ... on public.federation_club_venues (club_id, venue_name);
-- (exact index names/options are in the file itself -- not retyped here to
-- avoid a transcription error; the file is the executable source.)

-- DEPENDENCIES: reconfirmed unchanged since Gate 12.2 -- production schema
-- still matches every tested assumption (opponents/team_alias_mappings
-- payload-jsonb shape, gen_random_uuid() resolvable, pgcrypto/uuid-ossp/
-- btree_gist present, federation_% tables still absent -- reconfirmed
-- fresh in Gate 13.4). No new dependency introduced since Gate 12.

-- EXPECTED COUNTS AFTER DEPLOYMENT:
--   federation_clubs              : 0 -> 92
--   federation_club_competitions  : 0 -> 109
--   federation_club_venues        : 0 -> 100 (92 coded + 8 explained null-coded legacy)
--   opponents.federation_club_id  : new nullable column, 100% NULL (no backfill)
--   games/game_players/goal_events/card_events/players/team_share_links/opponents : byte-identical to Gate 13.4's fresh snapshot (27/143/10/4/20/3-1/160)

-- PRE-DEPLOYMENT CHECKS (run immediately before step 1, in this order):
--   [ ] select count(*) from information_schema.tables where table_schema='public' and table_name like 'federation_%'; -- expect 0
--   [ ] re-run Gate 13.4's 7-figure baseline query -- expect byte-identical to this report's "EXPECTED COUNTS" unchanged-tables list
--   [ ] select table_name, grantee, string_agg(privilege_type,',' order by privilege_type) from information_schema.table_privileges where table_schema='public' and table_name='team_alias_mappings' and grantee in ('anon','authenticated') group by table_name, grantee; -- capture today's grant baseline, to diff against after step 6

-- POST-DEPLOYMENT CHECKS (run after step 6, in this order):
--   [ ] federation_clubs = 92
--   [ ] federation_club_competitions = 109
--   [ ] federation_club_venues = 100, with null-afl_venue_code count = 8
--   [ ] no duplicate (club_id, afl_venue_code) pairs where afl_venue_code is not null
--   [ ] opponents.federation_club_id column exists, 100% NULL
--   [ ] the 7-figure unchanged-tables baseline is still byte-identical
--   [ ] team_alias_mappings anon grant fully revoked; authenticated narrowed to SELECT/INSERT/UPDATE/DELETE
--   [ ] federation_% tables' anon/authenticated grants are SELECT-only
--   [ ] get_advisors (security) shows no new finding beyond today's baseline

-- STOP CONDITIONS (any one halts immediately, state preserved, nothing
-- auto-rolled-back):
--   - any pre-deployment check fails to match its expectation
--   - any statement errors (constraint violation, type mismatch)
--   - any post-deployment count differs from its expected value
--   - any of the 7 unchanged-tables figures differs from its pre-deployment value

-- NON-DESTRUCTIVE RECOVERY (unchanged from Gate 12.3 -- restated for
-- completeness, not re-derived): on partial failure, record exact error +
-- step, query actual current state of any new objects (don't assume from
-- step number alone), fix root cause, re-run the SAME file from the start
-- (every file 1-5 is independently proven idempotent, run twice from a
-- clean schema with zero errors in Gate 11.1 -- safe to repeat). Full
-- rollback (after a successful deploy, if ever wanted): revoke SELECT on
-- the 3 federation_% tables from anon/authenticated (instant, zero data
-- loss, reversible) -- never DROP.

select 'Gate 13.5 complete. Phase A execution plan is ready to run: 6 ordered files, dependencies reconfirmed unchanged, expected counts stated, pre/post-deployment checks and stop conditions listed, non-destructive recovery confirmed. NOT executed -- awaiting Approval B.' as status;
