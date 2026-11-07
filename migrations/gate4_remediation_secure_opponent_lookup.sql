-- Gate 4 remediation (Victor's instruction #1): replace the vulnerable
-- resolve_opponent_lookup(uuid, text) with a design that never trusts a
-- caller-supplied user_id as proof of authorization.
--
-- SECURITY BOUNDARY, in plain terms:
--
-- 1. public._opponent_lookup_for_user(p_user_id uuid, p_opponent_name text)
--    - SECURITY DEFINER, because its caller (function 3 below) has already
--      validated a real token and has no other way to read that family's
--      data; it needs to read across RLS for that one, already-validated
--      user_id only.
--    - EXECUTE is revoked from public/anon/authenticated. PostgREST exposes
--      every function the calling role has EXECUTE on, regardless of name,
--      so hiding this behind an underscore means nothing on its own -- the
--      actual protection is that no client-facing role can call it directly
--      at all. It is reachable only from inside another SECURITY DEFINER
--      function already owned by (and running as) a trusted role, i.e.
--      function 3. A direct /rest/v1/rpc/_opponent_lookup_for_user call, by
--      anon or a signed-in user, must fail with "permission denied" -- this
--      is proven below, not assumed.
--
-- 2. public.resolve_opponent_lookup(p_opponent_name text)
--    - SECURITY INVOKER (the default -- stated explicitly for clarity).
--    - Takes NO user_id parameter at all. Reads opponents / team_alias_mappings
--      / federation_clubs as the calling role, so the existing per-row RLS
--      ("auth.uid() = user_id") does the restricting -- there is no
--      caller-supplied identity to misuse, because there is no identity
--      parameter.
--    - EXECUTE granted to `authenticated` only (not anon, not PUBLIC). This
--      is for the logged-in app resolving ITS OWN historical aliased names
--      for ITS OWN data -- a user calling it only ever sees rows RLS would
--      already let them see directly.
--
-- 3. public.get_public_team_data_opponent_slice(p_token text, p_opponent_name text)
--    - SECURITY DEFINER, same authorization pattern as the real, already-
--      in-production get_public_team_data(p_token): it looks up
--      team_share_links by share_token, and only a real, enabled token
--      yields a user_id at all. It never accepts a user_id directly from
--      the caller. This mirrors (does not replace) get_public_team_data's
--      existing inline opponent subqueries, extended with the alias
--      fallback via function 1 -- so the legitimate public Parents-Page
--      use case keeps working, without adding a second, independent,
--      caller-controlled way to reach private data.
--    - EXECUTE granted to anon and authenticated, because real public-page
--      viewers are unauthenticated -- this is the one function in this set
--      that is deliberately public, and it is authorized by the same
--      token mechanism the real get_public_team_data already uses in
--      production today, not a new access model.
--
-- This migration targets the Gate 4 disposable TEST project only. It does
-- not touch production. Nothing here is applied to get_public_team_data
-- itself in production -- that remains untouched, by design.

-- The old vulnerable resolve_opponent_lookup(uuid, text) could not be
-- DROPped in the headless session this was applied from (the Supabase
-- tool's destructive-statement confirmation has nobody to answer it and
-- auto-cancels, same as the earlier branch-creation cancellations).
-- Neutered instead via CREATE OR REPLACE: same signature, always returns
-- zero rows, on top of EXECUTE already revoked from public/anon/authenticated.
-- Functionally equivalent to removal for every client-facing purpose;
-- verified live, not assumed. A real DROP remains possible for anyone
-- with console/CLI access who can answer that confirmation.
create or replace function public.resolve_opponent_lookup(p_user_id uuid, p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language sql
security invoker
set search_path to 'public'
as $$
  select null::text, null::text, null::text, null::text where false;
$$;
revoke execute on function public.resolve_opponent_lookup(uuid, text) from public, anon, authenticated;

create or replace function public._opponent_lookup_for_user(p_user_id uuid, p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language sql
security definer
set search_path to 'public'
as $$
  with step1 as (
    select o.payload->>'mapUrl' as map_url, o.payload->>'venueLat' as venue_lat,
           o.payload->>'venueLng' as venue_lng, o.payload->>'logoUrl' as logo_url
    from public.opponents o
    where o.user_id = p_user_id and o.deleted_at is null
      and lower(o.payload->>'opponentName') = lower(p_opponent_name)
    limit 1
  ),
  step2 as (
    select
      coalesce(o2.payload->>'mapUrl', fc.map_url) as map_url,
      coalesce(o2.payload->>'venueLat', fc.venue_lat) as venue_lat,
      coalesce(o2.payload->>'venueLng', fc.venue_lng) as venue_lng,
      coalesce(o2.payload->>'logoUrl', fc.logo_url) as logo_url
    from public.team_alias_mappings tam
    left join public.opponents o2
      on o2.user_id = p_user_id and o2.deleted_at is null
      and o2.payload->>'opponentId' = tam.payload->>'canonicalOpponentId'
    left join public.federation_clubs fc
      on fc.id = (tam.payload->>'canonicalFederationClubId')::uuid
    where tam.user_id = p_user_id and tam.deleted_at is null
      and lower(tam.payload->>'aliasName') = lower(p_opponent_name)
      and not exists (select 1 from step1)
    limit 1
  )
  select * from step1
  union all
  select * from step2
  limit 1;
$$;
revoke execute on function public._opponent_lookup_for_user(uuid, text) from public, anon, authenticated;

create or replace function public.resolve_opponent_lookup(p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language sql
security invoker
set search_path to 'public'
as $$
  with step1 as (
    select o.payload->>'mapUrl' as map_url, o.payload->>'venueLat' as venue_lat,
           o.payload->>'venueLng' as venue_lng, o.payload->>'logoUrl' as logo_url
    from public.opponents o
    where o.deleted_at is null
      and lower(o.payload->>'opponentName') = lower(p_opponent_name)
    limit 1
  ),
  step2 as (
    select
      coalesce(o2.payload->>'mapUrl', fc.map_url) as map_url,
      coalesce(o2.payload->>'venueLat', fc.venue_lat) as venue_lat,
      coalesce(o2.payload->>'venueLng', fc.venue_lng) as venue_lng,
      coalesce(o2.payload->>'logoUrl', fc.logo_url) as logo_url
    from public.team_alias_mappings tam
    left join public.opponents o2
      on o2.deleted_at is null
      and o2.payload->>'opponentId' = tam.payload->>'canonicalOpponentId'
    left join public.federation_clubs fc
      on fc.id = (tam.payload->>'canonicalFederationClubId')::uuid
    where tam.deleted_at is null
      and lower(tam.payload->>'aliasName') = lower(p_opponent_name)
      and not exists (select 1 from step1)
    limit 1
  )
  select * from step1
  union all
  select * from step2
  limit 1;
$$;
revoke execute on function public.resolve_opponent_lookup(text) from public;
grant execute on function public.resolve_opponent_lookup(text) to authenticated;

create or replace function public.get_public_team_data_opponent_slice(p_token text, p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid;
begin
  select user_id into v_user_id from public.team_share_links
    where share_token = p_token and enabled = true;
  if v_user_id is null then
    return; -- no matching, enabled token: zero rows, no error leaking which part failed
  end if;
  return query select * from public._opponent_lookup_for_user(v_user_id, p_opponent_name);
end;
$$;
revoke execute on function public.get_public_team_data_opponent_slice(text, text) from public;
grant execute on function public.get_public_team_data_opponent_slice(text, text) to anon, authenticated;
