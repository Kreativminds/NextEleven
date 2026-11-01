-- Migration: add_season_calendar_events
-- Project: wicydcvdakqopodbxtrl
-- Feature: Season Calendar Improvements (Folga detection, Christmas/Easter
--          break suggestions, admin-defined milestones, parents-page
--          chronological calendar).
--
-- NOT YET APPLIED to production. Pure schema addition — one new table,
-- RLS policies, two indexes. No existing table, row or function is
-- touched by this file (the get_public_team_data RPC change lives in
-- 006_extend_public_rpc_with_calendar.sql instead, so the two concerns —
-- "add a table" and "change what the public API returns" — stay
-- separable and independently reviewable). Nothing destructive.
--
-- Shape matches every other sync-envelope table in this schema exactly
-- (same columns/defaults as `tournaments`, same four own_rows_* RLS
-- policies, same (user_id, device_id, local_id) sync-identity unique
-- index) so it needs no special-casing anywhere in the generic
-- IndexedDB<->Supabase sync engine (index.html's SYNC_STORES_SET /
-- storeToTable()) beyond registering the new store name.
--
-- payload shape (admin-owned, never containing player data — "Avoid
-- exposing private player information through calendar events" is
-- satisfied by construction: this table has no player fields at all):
--   eventId:    int, local primary key (IndexedDB autoIncrement)
--   seasonId:   int
--   type:       'folga' | 'break' | 'milestone'
--   subtype:    'christmas' | 'easter' | 'custom' | null
--   title:      text (display name, e.g. "Pausa de Natal", "Fim do Campeonato")
--   startDate:  'YYYY-MM-DD'
--   endDate:    'YYYY-MM-DD' (equal to startDate for single-day events)
--   status:     'suggested' | 'confirmed' | 'rejected'
--   source:     'auto' | 'manual'
--   autoKey:    stable id for auto-generated rows (e.g. 'folga-2026-11-28',
--               'christmas-2026') used to avoid re-creating a duplicate
--               suggestion when Folga detection / holiday suggestions are
--               re-run — never set for manual entries.
--   notes, createdAt, updatedAt
--
-- Suggestions (status='suggested') are never exposed on the parents page —
-- only status='confirmed' rows reach get_public_team_data (see migration
-- 006). Rejected rows are kept (soft state, not deleted) so a rejection is
-- remembered and never re-suggested.

create table public.season_calendar_events (
  id uuid not null default extensions.uuid_generate_v4() primary key,
  family_id text,
  device_id text not null,
  local_id text not null,
  user_id uuid,
  payload jsonb not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  deleted_at timestamptz,
  sync_status text default 'synced'::text
);

alter table public.season_calendar_events enable row level security;

create policy own_rows_select on public.season_calendar_events
  for select using (auth.uid() = user_id);
create policy own_rows_insert on public.season_calendar_events
  for insert with check (auth.uid() = user_id);
create policy own_rows_update on public.season_calendar_events
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy own_rows_delete on public.season_calendar_events
  for delete using (auth.uid() = user_id);

create index idx_season_calendar_events_user on public.season_calendar_events (user_id);

create unique index season_calendar_events_sync_identity_unique
  on public.season_calendar_events (user_id, device_id, local_id)
  where (deleted_at is null);

-- Prevents a duplicate auto-generated suggestion for the same season when
-- Folga detection / holiday suggestions are re-run (idempotent by design —
-- manual entries carry no autoKey and are therefore never constrained by
-- this index, so admins can always add as many custom events as they like).
create unique index season_calendar_events_autokey_uniq
  on public.season_calendar_events (user_id, (payload->>'seasonId'), (payload->>'autoKey'))
  where (deleted_at is null and payload->>'autoKey' is not null);
