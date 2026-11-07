-- ============================================================================
-- GATE 9.1 — full-schema staging environment: precise limitation, and the
-- fallback actually used. Applied ONLY to the isolated test project
-- (tqpykeuuzcqudqtfrqmc). NEVER applied to production
-- (wicydcvdakqopodbxtrl) — no production schema change is authorized by
-- Gate 9, and none was made.
--
-- PRECISE LIMITATION (Victor's own instruction: "If full-schema staging
-- cannot be established, explain the precise limitation"), established by
-- direct, first-hand tool calls, not assumption:
--   1. Supabase database branching (Preview Branches) requires the Pro
--      plan or higher. Org "vmabere" (xfyrmvfdphumqmxnjbhh) is confirmed
--      Free tier (get_organization -> {"plan":"free","tier":"tier_free"}),
--      cross-confirmed against Supabase's own published pricing. A
--      create_branch call against production returned the standard
--      headless-confirmation auto-cancel, which is moot here regardless —
--      the plan itself blocks branching before confirmation is relevant.
--   2. A third, disposable project cannot be created either: the Free
--      tier caps an organization at 2 ACTIVE projects, and this org
--      already has exactly 2 (production wicydcvdakqopodbxtrl + the
--      existing isolated test project tqpykeuuzcqudqtfrqmc). A direct
--      create_project attempt failed with Supabase's own
--      BadRequestException naming the 2-project limit explicitly — this
--      is a first-hand confirmation, not an inference from a secondary
--      source.
--   FALLBACK ADOPTED (within Gate 9.1's own wording: "If full-schema
--   staging cannot be established... identify which tests remain
--   blocked" — nothing here is a substitute for full branch isolation,
--   it is the nearest available approximation): extend the EXISTING
--   isolated test project with the 11 tables get_public_team_data and
--   its dependents need that it did not yet carry (players, game_players,
--   achievements, app_branding, injuries, tournaments,
--   classification_snapshots, season_calendar_events, temporary_players,
--   goal_events, card_events), reproducing production's real schema for
--   each — columns, defaults, constraints, indexes, RLS policies — via
--   direct, read-only introspection of production (information_schema,
--   pg_constraint, pg_indexes, pg_policies, pg_proc), then seeding
--   synthetic data only. This project already carried opponents, games,
--   team_alias_mappings, seasons, club_teams, team_share_links,
--   federation_clubs, federation_club_competitions and
--   federation_club_venues from Gates 4–8, plus the two fixture
--   auth.users already present (00000000-0000-0000-0000-00000000a001 /
--   ...a002) — no new auth user is created here, only new data tables.
--
--   WHAT THIS DOES NOT REPRODUCE, so it is not mistaken for a real
--   branch (tests this leaves BLOCKED, carried into the final report):
--     - True production-equivalent infra: separate compute, separate
--       Postgres version drift, separate extension set, separate
--       connection pooling behaviour. This is the SAME physical Supabase
--       project used since Gate 4, just with more tables.
--     - Auth: no Supabase Auth flows (signup/login/JWT issuance) are
--       exercised — only two pre-existing fixture auth.users rows are
--       reused, as in every earlier gate. Real end-user authentication
--       behaviour is therefore NOT validated anywhere in this engagement.
--     - Storage, Edge Functions, or any non-Postgres Supabase product.
--     - Triggers: production's advisors have never flagged a trigger on
--       any of these 11 tables (verified: no rows in pg_trigger for them
--       on production beyond the standard updated_at pattern, which this
--       migration does not need to reproduce since synthetic seed rows
--       set updated_at explicitly via their defaults).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PART 1 — the 11 missing tables, reproducing production's real schema.
-- ----------------------------------------------------------------------------

create table if not exists public.players (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_players_user on public.players(user_id);
create index if not exists players_family_id_updated_at_idx on public.players(family_id, updated_at);
create unique index if not exists players_identity_uniq on public.players(user_id, ((payload->>'seasonId')), ((payload->>'careerPlayerId'))) where (deleted_at is null);
create unique index if not exists players_sync_identity_unique on public.players(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.game_players (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_game_players_user on public.game_players(user_id);
create index if not exists game_players_family_id_updated_at_idx on public.game_players(family_id, updated_at);
create unique index if not exists game_players_identity_uniq on public.game_players(user_id, ((payload->>'gameId')), ((payload->>'playerId'))) where (deleted_at is null);
create unique index if not exists game_players_sync_identity_unique on public.game_players(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.achievements (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_achievements_user on public.achievements(user_id);
create index if not exists idx_achievements_family on public.achievements(family_id, updated_at);
create unique index if not exists achievements_sync_identity_unique on public.achievements(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.app_branding (
  id uuid not null default extensions.gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id),
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  sync_status text default 'synced'::text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  constraint app_branding_user_id_unique unique (user_id)
);

create table if not exists public.injuries (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_injuries_user on public.injuries(user_id);
create unique index if not exists injuries_sync_identity_unique on public.injuries(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.tournaments (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  user_id uuid references auth.users(id),
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text
);
create index if not exists idx_tournaments_user on public.tournaments(user_id);
create unique index if not exists tournaments_sync_identity_unique on public.tournaments(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.classification_snapshots (
  id uuid not null default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id),
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text
);
create index if not exists idx_classification_snapshots_user on public.classification_snapshots(user_id);
create unique index if not exists classification_snapshots_sync_identity_unique on public.classification_snapshots(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.season_calendar_events (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  user_id uuid references auth.users(id),
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text
);
create index if not exists idx_season_calendar_events_user on public.season_calendar_events(user_id);
create unique index if not exists season_calendar_events_autokey_uniq on public.season_calendar_events(user_id, ((payload->>'seasonId')), ((payload->>'autoKey'))) where ((deleted_at is null) and ((payload->>'autoKey') is not null));
create unique index if not exists season_calendar_events_sync_identity_unique on public.season_calendar_events(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.temporary_players (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  user_id uuid references auth.users(id),
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text
);
create index if not exists idx_temporary_players_user on public.temporary_players(user_id);
create unique index if not exists temporary_players_sync_identity_unique on public.temporary_players(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.goal_events (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_goal_events_user on public.goal_events(user_id);
create unique index if not exists goal_events_sync_identity_unique on public.goal_events(user_id, device_id, local_id) where (deleted_at is null);

create table if not exists public.card_events (
  id uuid not null default uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text,
  user_id uuid references auth.users(id)
);
create index if not exists idx_card_events_user on public.card_events(user_id);
create unique index if not exists card_events_sync_identity_unique on public.card_events(user_id, device_id, local_id) where (deleted_at is null);

-- ----------------------------------------------------------------------------
-- PART 2 — RLS: enable + reproduce production's real policies exactly
-- (verified via pg_policies on production, not assumed). Ten of the
-- eleven tables are owner-scoped on all four operations
-- (auth.uid() = user_id); app_branding is the one exception, matching
-- production exactly: SELECT is public (true) because branding/logo data
-- is meant to be readable by anyone with a share link, while
-- INSERT/UPDATE/DELETE stay owner-scoped.
-- ----------------------------------------------------------------------------
do $$
declare
  t text;
  owner_scoped_tables text[] := array['players','game_players','achievements','injuries','tournaments',
                                       'classification_snapshots','season_calendar_events','temporary_players',
                                       'goal_events','card_events'];
begin
  foreach t in array owner_scoped_tables loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists own_rows_select on public.%I;', t);
    execute format('create policy own_rows_select on public.%I for select using (auth.uid() = user_id);', t);
    execute format('drop policy if exists own_rows_insert on public.%I;', t);
    execute format('create policy own_rows_insert on public.%I for insert with check (auth.uid() = user_id);', t);
    execute format('drop policy if exists own_rows_update on public.%I;', t);
    execute format('create policy own_rows_update on public.%I for update using (auth.uid() = user_id) with check (auth.uid() = user_id);', t);
    execute format('drop policy if exists own_rows_delete on public.%I;', t);
    execute format('create policy own_rows_delete on public.%I for delete using (auth.uid() = user_id);', t);
    execute format('grant select, insert, update, delete on public.%I to anon, authenticated;', t);
  end loop;
end $$;

alter table public.app_branding enable row level security;
drop policy if exists app_branding_select_public on public.app_branding;
create policy app_branding_select_public on public.app_branding for select using (true);
drop policy if exists app_branding_insert_own on public.app_branding;
create policy app_branding_insert_own on public.app_branding for insert with check (auth.uid() = user_id);
drop policy if exists app_branding_update_own on public.app_branding;
create policy app_branding_update_own on public.app_branding for update using (auth.uid() = user_id);
drop policy if exists app_branding_delete_own on public.app_branding;
create policy app_branding_delete_own on public.app_branding for delete using (auth.uid() = user_id);
grant select, insert, update, delete on public.app_branding to anon, authenticated;

-- ----------------------------------------------------------------------------
-- PART 3 — fmt_public_name, byte-for-byte copy of production's definition
-- (read directly from production, read-only, 2026-11-05). get_public_team_data
-- depends on this for every player-name field.
-- ----------------------------------------------------------------------------
create or replace function public.fmt_public_name(p_name text, p_mode text)
 returns text
 language sql
 immutable
as $function$
  select case
      when p_name is null or btrim(p_name) = '' then null
      when p_mode = 'hidden' then null
      when p_mode = 'initials' then regexp_replace(p_name, '^(\S+).*\s(\S)\S*$', '\1 \2.')
      when p_mode = 'initial_surname' then regexp_replace(p_name, '^(\S)\S*.*\s(\S+)$', '\1. \2')
      else p_name
      end;
$function$;

-- ----------------------------------------------------------------------------
-- PART 4 — synthetic seed data, fixture user
-- 00000000-0000-0000-0000-00000000a001 only (the same fixture user used
-- throughout Gates 4-8; never Victor's real user_id, never real player
-- names). Two games already exist in this project for this user under
-- seasonId=5 is NOT true -- only gameId=5001 (2025-03-10) existed before
-- this migration. A second, recent game (gameId=5002, dated today) is
-- added here so get_public_team_data's 3-day-recency gates on
-- goalEvents/goalScorers/cardEvents (per-game) can be exercised too, not
-- just the always-on gamePlayers aggregate counters.
-- A seasons row for seasonId=5 is required -- without it
-- get_public_team_data returns null at its very first lookup
-- (v_season_payload), per its own definition -- and none existed yet
-- (seasons had 0 rows in this project before this migration).
-- ----------------------------------------------------------------------------

insert into public.seasons (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'season-5',
  jsonb_build_object('seasonId', 5, 'seasonName', '2025 Test Season', 'clubName', 'SL Olivais Test Club',
    'ageGroup', 'U12', 'status', 'active', 'clubTeamId', 1, 'homeGroundLat', '38.76', 'homeGroundLng', '-9.15')
where not exists (
  select 1 from public.seasons where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and (payload->>'seasonId')::int = 5 and deleted_at is null
);

insert into public.club_teams (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'club-1',
  jsonb_build_object('clubTeamId', 1, 'logoUrl', 'https://example.com/test-club-logo.png')
where not exists (
  select 1 from public.club_teams where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and (payload->>'clubTeamId')::int = 1 and deleted_at is null
);

insert into public.app_branding (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'branding-1',
  jsonb_build_object('mainLogo', 'https://example.com/test-main-logo.png')
where not exists (select 1 from public.app_branding where user_id = '00000000-0000-0000-0000-00000000a001'::uuid);

insert into public.players (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', v.local_id, v.payload
from (values
  ('player-1', jsonb_build_object('playerId',1,'seasonId',5,'fullName','Test Player One','shirtNumber','7','primaryPosition','Forward','isActive',true,'dateOfBirth','2013-11-07')),
  ('player-2', jsonb_build_object('playerId',2,'seasonId',5,'fullName','Test Player Two','shirtNumber','4','primaryPosition','Midfielder','isActive',true,'dateOfBirth','2013-06-15')),
  ('player-3', jsonb_build_object('playerId',3,'seasonId',5,'fullName','Test Player Three','shirtNumber','1','primaryPosition','Goalkeeper','isActive',true,'dateOfBirth','2013-01-20'))
) as v(local_id, payload)
where not exists (
  select 1 from public.players p where p.user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and p.deleted_at is null and (p.payload->>'playerId') = v.payload->>'playerId' and (p.payload->>'seasonId')::int = 5
);

insert into public.temporary_players (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'temp-player-1',
  jsonb_build_object('tempPlayerId', 'temp-1', 'name', 'Guest Player Test', 'shirtNumber', '99', 'preferredPosition', 'Defender')
where not exists (
  select 1 from public.temporary_players where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and payload->>'tempPlayerId' = 'temp-1' and deleted_at is null
);

-- gameId=5002: a second, RECENT game (dated today) under the same
-- season, so the RPC's 3-day-recency-gated fields are exercisable.
insert into public.games (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', '5002',
  jsonb_build_object('gameId', 5002, 'seasonId', 5, 'date', to_char(current_date, 'YYYY-MM-DD'), 'gameTime', '15:00',
    'opponent', 'Direct Match FC', 'homeAway', 'home', 'competitionType', 'League', 'venue', 'Test Venue')
where not exists (
  select 1 from public.games where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and (payload->>'gameId')::int = 5002 and deleted_at is null
);

insert into public.game_players (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', v.local_id, v.payload
from (values
  ('gp-5001-1', jsonb_build_object('gameId',5001,'playerId',1,'seasonId',5,'calledUp','true','goals','1','assists','0','playedFullGame','true','positionPlayed','Forward')),
  ('gp-5001-2', jsonb_build_object('gameId',5001,'playerId',2,'seasonId',5,'calledUp','true','goals','0','assists','1','playedFullGame','true','positionPlayed','Midfielder')),
  ('gp-5002-1', jsonb_build_object('gameId',5002,'playerId',1,'seasonId',5,'calledUp','true','goals','1','assists','0','playedFullGame','true','positionPlayed','Forward')),
  ('gp-5002-temp', jsonb_build_object('gameId',5002,'tempPlayerId','temp-1','seasonId',5,'calledUp','true','goals','0','assists','0','playedFullGame','false','positionPlayed','Defender'))
) as v(local_id, payload)
where not exists (
  select 1 from public.game_players gp where gp.user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and gp.deleted_at is null and gp.local_id = v.local_id
);

insert into public.goal_events (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', v.local_id, v.payload
from (values
  ('ge-5001-1', jsonb_build_object('gameId',5001,'scorerId','1','scorerType','player','scoredAt','2025-03-10T15:23:00')),
  ('ge-5002-1', jsonb_build_object('gameId',5002,'scorerId','1','scorerType','player','scoredAt', to_char(current_date,'YYYY-MM-DD') || 'T15:23:00'))
) as v(local_id, payload)
where not exists (
  select 1 from public.goal_events where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and deleted_at is null and local_id = v.local_id
);

insert into public.card_events (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', v.local_id, v.payload
from (values
  ('ce-5001-1', jsonb_build_object('gameId',5001,'team','us','scorerId','2','scorerType','player','cardType','yellow','minute','30')),
  ('ce-5002-1', jsonb_build_object('gameId',5002,'team','us','scorerId','2','scorerType','player','cardType','yellow','minute','55'))
) as v(local_id, payload)
where not exists (
  select 1 from public.card_events where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and deleted_at is null and local_id = v.local_id
);

insert into public.achievements (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'ach-1',
  jsonb_build_object('seasonId', 5, 'category', 'Trophy', 'title', 'Test League Winners 2025', 'date', '2025-06-01', 'dismissed', 'false')
where not exists (
  select 1 from public.achievements where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and local_id = 'ach-1' and deleted_at is null
);

insert into public.injuries (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'inj-1',
  jsonb_build_object('injuryId', 'inj-1', 'playerId', 3, 'status', 'Injured', 'reportedDate', to_char(current_date,'YYYY-MM-DD'))
where not exists (
  select 1 from public.injuries where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and local_id = 'inj-1' and deleted_at is null
);

insert into public.tournaments (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'tourn-1',
  jsonb_build_object('tournamentId', 1, 'seasonId', 5, 'name', 'Test Cup 2025', 'location', 'Test Grounds', 'startDate', '2025-07-01', 'endDate', '2025-07-03')
where not exists (
  select 1 from public.tournaments where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and local_id = 'tourn-1' and deleted_at is null
);

insert into public.classification_snapshots (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'class-1',
  jsonb_build_object('seasonId', 5, 'competitionType', 'League', 'competitionName', 'Test League', 'phase', 'Regular',
    'publicationStatus', 'published', 'publishedAt', to_char(current_date,'YYYY-MM-DD'),
    'sourceName', 'Test Federation', 'rows', jsonb_build_array(
      jsonb_build_object('position',1,'team','SL Olivais Test Club','points',30)))
where not exists (
  select 1 from public.classification_snapshots where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and local_id = 'class-1' and deleted_at is null
);

insert into public.season_calendar_events (user_id, device_id, local_id, payload)
select '00000000-0000-0000-0000-00000000a001'::uuid, 'dev-test', 'cal-1',
  jsonb_build_object('seasonId', 5, 'type', 'training', 'subtype', null, 'title', 'Test Training Session',
    'startDate', to_char(current_date + 2,'YYYY-MM-DD'), 'endDate', to_char(current_date + 2,'YYYY-MM-DD'), 'status', 'confirmed')
where not exists (
  select 1 from public.season_calendar_events where user_id = '00000000-0000-0000-0000-00000000a001'::uuid
    and local_id = 'cal-1' and deleted_at is null
);

select 'Gate 9.1 complete: 11 tables + fmt_public_name created on the isolated test project (tqpykeuuzcqudqtfrqmc) only, schema/constraints/indexes/RLS reproduced from production via read-only introspection, synthetic data seeded for fixture user a001 only. Production untouched.' as status;
