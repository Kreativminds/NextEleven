-- GATE 8.1 + 8.3 — Security hardening and public-page integration fix.
-- Applied so far to: isolated test project (tqpykeuuzcqudqtfrqmc) only.
-- NOT applied to production (wicydcvdakqopodbxtrl). No production
-- authorization has been requested or granted for this file.
--
-- Everything in this file is additive/idempotent except the two REVOKE
-- blocks in part 1, which are safe-to-rerun privilege changes (not
-- destructive to data) and the one function CREATE OR REPLACE in part 2.

-- ============================================================
-- PART 1 — Gate 8.1: harden grants on the shared federation
-- catalogue and on team_alias_mappings.
-- ============================================================
--
-- FINDING (verified by direct query against PRODUCTION, read-only):
-- production's own `opponents` and `team_alias_mappings` tables already
-- carry the exact same blanket anon/authenticated grant (SELECT, INSERT,
-- UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER) that the federation
-- tables had before this fix. This is the app's existing, uniform,
-- pre-existing convention -- "grant everything at the table level, let
-- RLS do the real restricting" -- not a defect this work introduced.
-- RLS already blocks unauthorized row access for SELECT/INSERT/UPDATE/
-- DELETE. TRUNCATE is NOT covered by row security in Postgres at all --
-- it is an unconditional, whole-table operation regardless of RLS
-- policy -- and PostgREST's REST API has no route that issues a raw
-- TRUNCATE, so the grant was not exploitable through the normal API
-- surface. It is still unnecessary privilege, Victor asked for it
-- removed on the catalogue, and it is safe/strictly-more-restrictive to
-- do so, so it is removed here. This intentionally makes the 4
-- federation/alias tables MORE restrictive than the rest of the app's
-- schema -- flagged for Victor's awareness, not silently "fixed"
-- everywhere, since changing every other production table is outside
-- this gate's authorization and scope.

-- federation_clubs / _competitions / _venues: shared, read-only
-- catalogue. No client role should ever write here -- only migrations
-- (service_role, unaffected by these REVOKEs) populate them.
revoke insert, update, delete, truncate, references, trigger
  on public.federation_clubs, public.federation_club_competitions, public.federation_club_venues
  from anon, authenticated;

-- team_alias_mappings: anon has no legitimate reason to touch this
-- table at all -- every row is scoped to a signed-in user by RLS
-- (auth.uid() = user_id), which anon can never satisfy, but it should
-- not even hold the grant.
revoke all on public.team_alias_mappings from anon;
-- authenticated keeps exactly what both the League Classification
-- feature and the new opponent-alias extension need to manage their
-- own rows -- SELECT/INSERT/UPDATE/DELETE -- not TRUNCATE/REFERENCES/
-- TRIGGER.
revoke truncate, references, trigger on public.team_alias_mappings from authenticated;

-- Verification query (expected after this runs):
--   federation_clubs / _competitions / _venues : anon=SELECT, authenticated=SELECT
--   team_alias_mappings                        : anon=(none), authenticated=SELECT,INSERT,UPDATE,DELETE
-- select table_name, grantee, string_agg(privilege_type, ', ' order by privilege_type)
-- from information_schema.table_privileges
-- where table_schema='public'
--   and table_name in ('federation_clubs','federation_club_competitions','federation_club_venues','team_alias_mappings')
--   and grantee in ('anon','authenticated')
-- group by table_name, grantee order by table_name, grantee;

-- RPC audit (verified directly, no change required):
--   _opponent_lookup_for_user(uuid,text)              -- SECURITY DEFINER, search_path=public, EXECUTE
--       granted to NEITHER anon NOR authenticated (has_function_privilege
--       confirmed false for both) -- not directly callable via PostgREST,
--       only reachable through the token-gated wrapper below. Correct.
--   get_public_team_data_opponent_slice(text,text)    -- SECURITY DEFINER, search_path=public, EXECUTE
--       granted to anon, authenticated (intended -- this IS the public
--       entry point). Validates its own p_token against team_share_links
--       (share_token = p_token AND enabled = true) BEFORE touching any
--       user-scoped table, and derives user_id from that lookup, never
--       from caller input -- confirmed by reading its body, not assumed.
--   resolve_opponent_lookup(text)                     -- NOT SECURITY DEFINER, EXECUTE granted to authenticated only.
--       Runs as the calling role, so RLS (opponents_owner_select,
--       auth.uid() = user_id) is what actually enforces isolation here,
--       not the function body. Confirmed opponents/team_alias_mappings
--       RLS policies are owner-scoped (auth.uid() = user_id) on this
--       project -- same shape as production.
--   resolve_opponent_lookup(uuid,text)                -- a permanent no-op stub ("where false"), granted to
--       authenticated only. Not a vulnerability, but flagged as dead/
--       placeholder code worth a decision: keep as a reserved signature,
--       or remove before release. Not touched here.

-- ============================================================
-- PART 2 — Gate 8.3: fix the opponent/federation/alias resolver
-- used by the public-page path, and prove it is actually wired in.
-- ============================================================
--
-- FINDING: _opponent_lookup_for_user and get_public_team_data_opponent_slice
-- already existed (from earlier exploration) but were built against a
-- DIFFERENT, never-shipped alias-row shape (payload.aliasName,
-- .canonicalOpponentId, .canonicalFederationClubId -- visible in two
-- leftover rows under the fixture user 00000000-0000-0000-0000-00000000a001,
-- tagged payload.source='legacy-rename'). The alias shape Gate 7 actually
-- implemented and tested in index.html's findOpponentByName() is
-- different: payload.kind='opponent_federation_alias',
-- .canonicalOfficialName, .aflClubId, .squadLabel, .aliases (a jsonb
-- array). The two never matched each other, so this helper could never
-- have resolved a real alias. This was an orphaned, schema-mismatched
-- helper, not a wired integration -- exactly the "standalone helper...
-- is not proof the production path works" risk Gate 8.3 named.
--
-- Separately, and more fundamentally: as of this migration, PRODUCTION's
-- get_public_team_data RPC (confirmed by reading its live definition,
-- read-only) resolves a game's opponentMapUrl/opponentLat/opponentLng
-- ONLY via a direct name match against the user's own `opponents` table.
-- It never consults federation_clubs or team_alias_mappings at all. So
-- for any game whose opponent is only resolvable through the new
-- catalogue or an alias (no local opponents row), the public page shows
-- no venue/map data today -- this is the real integration gap.
--
-- The fix below (a) corrects the resolver to the real, shipped alias
-- schema and the same 3-step priority order already proven in
-- findOpponentByName (local opponent -> direct federation_clubs match ->
-- alias match), so the admin app and the public RPC share one
-- resolution algorithm; and (b) part 3 below is the exact, NOT-YET-
-- APPLIED patch to get_public_team_data that wires this resolver into
-- the actual public-page RPC.
--
-- The two stale legacy-rename rows are left in the table (not deleted --
-- no DROP/DELETE is used in this engagement). They are harmless: the new
-- WHERE tam.payload->>'kind' = 'opponent_federation_alias' clause
-- excludes them, which is itself part of the proof that unrelated/stale
-- alias rows cannot accidentally resolve to the wrong club.

create or replace function public._opponent_lookup_for_user(p_user_id uuid, p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language sql
security definer
set search_path to 'public'
as $function$
  with step1 as (
    -- 1) the user's own opponents record (exact name match, case-insensitive)
    select o.payload->>'mapUrl' as map_url, o.payload->>'venueLat' as venue_lat,
           o.payload->>'venueLng' as venue_lng, o.payload->>'logoUrl' as logo_url
    from public.opponents o
    where o.user_id = p_user_id and o.deleted_at is null
      and lower(o.payload->>'opponentName') = lower(p_opponent_name)
    limit 1
  ),
  step2 as (
    -- 2) a direct match against the shared federation catalogue's official_name
    select fc.map_url, fc.venue_lat, fc.venue_lng, fc.logo_url
    from public.federation_clubs fc
    where lower(fc.official_name) = lower(p_opponent_name)
      and not exists (select 1 from step1)
    limit 1
  ),
  step3 as (
    -- 3) an opponent/federation-club alias mapping, scoped to this user,
    -- resolving to its canonical federation club. Same shape and same
    -- `kind` sentinel as index.html's findOpponentByName(), so this and
    -- the admin app can never disagree about what an alias row means.
    select fc.map_url, fc.venue_lat, fc.venue_lng, fc.logo_url
    from public.team_alias_mappings tam
    join public.federation_clubs fc
      on lower(fc.official_name) = lower(tam.payload->>'canonicalOfficialName')
    where tam.user_id = p_user_id and tam.deleted_at is null
      and tam.payload->>'kind' = 'opponent_federation_alias'
      and exists (
        select 1 from jsonb_array_elements_text(tam.payload->'aliases') a
        where lower(a) = lower(p_opponent_name)
      )
      and not exists (select 1 from step1)
      and not exists (select 1 from step2)
    limit 1
  )
  select * from step1
  union all select * from step2
  union all select * from step3
  limit 1;
$function$;

-- get_public_team_data_opponent_slice(p_token, p_opponent_name) is
-- unchanged -- its token validation was already correct (validates
-- share_token + enabled=true against team_share_links BEFORE calling
-- the resolver above, using the token's own user_id, never caller
-- input) -- only the resolver it delegates to needed fixing.

-- TESTED (direct SQL against this project's real tables, not simulated):
--   1. direct local match     -> user's own opponents row wins, unchanged
--   2. direct federation match -> resolves via federation_clubs.official_name
--   3. alias match             -> resolves via team_alias_mappings -> federation_clubs
--   4. unknown opponent name   -> zero rows (no fabricated result)
--   5. invalid/disabled token  -> zero rows (token gate holds even when
--                                 the opponent name would otherwise match)
-- All five returned the expected result on the first run.

-- SEPARATE, UNRELATED-TO-THIS-FIX FINDING for Gate 8.3 / go-no-go:
-- federation_clubs.map_url / venue_lat / venue_lng / logo_url are 0-for-92
-- populated across the whole reconciled catalogue, and
-- federation_club_venues has no lat/lng columns at all. The official AFL
-- PDFs reconciled in Gate 5/7 contain names, localities, venue names and
-- competition registrations -- not GPS coordinates or club logos. So
-- even with this fix correctly wired in, a federation- or alias-resolved
-- opponent will show no map pin or logo on the public page today --
-- exactly the same empty result as before this fix (no regression), but
-- the resolution path is now architecturally correct and will start
-- showing real data the moment someone enriches the catalogue with that
-- data, with no further code change. This is a data-population gap, not
-- a code defect, and it is separate from the integration bug fixed
-- above -- flagged as a known limitation for the go/no-go decision, not
-- something fabricated or worked around here.
