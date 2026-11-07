-- Gate 3 — shared federation catalogue + backward-compatible alias resolution
-- Status: DEV-BRANCH ONLY. Not applied to the production project. Every
-- change below is additive — nothing existing is altered, renamed, or
-- dropped. Written for Victor Mabere's review per the Gate 3 approval
-- matrix (decision categories 2 and 4).

-- ── 1. Shared, user-independent federation club catalogue ──────────────────
create table if not exists public.federation_clubs (
  id uuid primary key default gen_random_uuid(),
  official_name text not null,
  afl_club_id text,
  afl_venue_id text,
  map_url text,
  venue_lat text,
  venue_lng text,
  logo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
comment on table public.federation_clubs is
  'Read-only, user-independent catalogue of real federation clubs. Never '
  'written to by the client app directly — populated by an approved seed '
  'migration only. No user_id, no family_id, no soft-delete: a club'' s '
  'existence does not depend on any one user''s data.';

-- Deliberately NOT unique on official_name alone: two clubs at different
-- federations could legitimately share a name. Uniqueness is scoped to
-- the AFL club ID, which IS the real identity, when one is known.
create unique index if not exists federation_clubs_afl_id_uniq
  on public.federation_clubs (afl_club_id) where afl_club_id is not null;

alter table public.federation_clubs enable row level security;
create policy federation_clubs_public_read on public.federation_clubs
  for select using (true);
-- No insert/update/delete policy is created — the table is read-only to
-- every client role; writes happen only via an approved migration/seed.

-- ── 2. Season/age-group/division as a relationship, never a club property ──
create table if not exists public.federation_club_competitions (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.federation_clubs(id) on delete cascade,
  season text,
  age_group text,
  division text,
  series text,
  created_at timestamptz not null default now()
);
comment on table public.federation_club_competitions is
  'Which competition(s) a federation club is registered in, per season. '
  'A club keeps one identity across seasons/divisions; this table is what '
  'changes, never a column on federation_clubs itself.';

alter table public.federation_club_competitions enable row level security;
create policy federation_club_competitions_public_read on public.federation_club_competitions
  for select using (true);

-- ── 3. Additive, nullable bridge from existing opponents to the catalogue ──
-- Preserves every existing opponents.id / opponentId exactly. A NULL value
-- here (the default, and the only value for every existing row until an
-- explicit, approved backfill) means "not yet linked" — nothing changes
-- for a row until this column is deliberately populated.
alter table public.opponents
  add column if not exists federation_club_id uuid references public.federation_clubs(id);

-- ── 4. Alias resolution — written as ROWS into the EXISTING             ──
-- ── team_alias_mappings table (same universal payload-jsonb shape as    ──
-- ── every other table in this schema — no ALTER TABLE needed here).     ──
-- Row shape (inside payload), by convention, matching the app's existing
-- sync model:
--   { "aliasName": "<normalized historical opponent text>",
--     "canonicalOpponentId": <local opponents.opponentId, nullable>,
--     "canonicalFederationClubId": "<federation_clubs.id, nullable>",
--     "source": "legacy-rename" | "federation-merge" | "manual" }
-- No DDL needed for this part — documented here for the migration record.

-- ── 5. New RPC: two-step opponent-name resolution (used in place of the  ──
-- ── inline `lower(o.payload->>'opponentName') = lower(games.payload->>  ──
-- ── 'opponent')` joins currently repeated 3x inside get_public_team_data)──
create or replace function public.resolve_opponent_lookup(p_user_id uuid, p_opponent_name text)
returns table(map_url text, venue_lat text, venue_lng text, logo_url text)
language sql
security definer
set search_path to 'public'
as $$
  with step1 as (
    -- Step 1: direct match against the user's live opponents catalogue —
    -- today's behaviour, completely unchanged, covers the ordinary case.
    select o.payload->>'mapUrl' as map_url, o.payload->>'venueLat' as venue_lat,
           o.payload->>'venueLng' as venue_lng, o.payload->>'logoUrl' as logo_url
    from public.opponents o
    where o.user_id = p_user_id and o.deleted_at is null
      and lower(o.payload->>'opponentName') = lower(p_opponent_name)
    limit 1
  ),
  step2 as (
    -- Step 2: only reached if step 1 found nothing. Look up the historical
    -- name in team_alias_mappings and resolve through whichever canonical
    -- target it points to (a live opponents row, or a federation_clubs row).
    -- The game's own opponent text is never touched by this — only the
    -- backing map/venue lookup changes.
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
comment on function public.resolve_opponent_lookup is
  'Gate 3 — backward-compatible opponent map/venue resolution. Step 1 '
  'preserves today''s exact behaviour; step 2 is the new alias fallback '
  'for a historical name that has since been renamed/consolidated. Never '
  'rewrites games.payload->>''opponent'' — read-only resolution helper.';
