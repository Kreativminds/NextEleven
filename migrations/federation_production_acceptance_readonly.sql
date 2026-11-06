-- Next Eleven federation catalogue production acceptance checks.
-- Read-only. Run after each frontend release and before enabling the picker.
select
  (select count(*) from public.federation_clubs) as federation_clubs,
  (select count(*) from public.federation_club_competitions where season = '2026/27') as registrations_2026_27,
  (select count(*) from public.federation_club_venues) as federation_venues,
  (select count(*) from public.opponents where deleted_at is null) as active_opponents,
  (select count(*) from public.opponents where deleted_at is null and federation_club_id is not null) as linked_opponents,
  (select count(*) from public.opponents where deleted_at is null and federation_club_id is null) as unresolved_opponents,
  (select count(*) from public.games where deleted_at is null) as active_games,
  (select count(*) from (select afl_club_id from public.federation_clubs where afl_club_id is not null group by 1 having count(*) > 1) x) as duplicate_federation_ids,
  (select count(*) from (select club_id, afl_venue_code from public.federation_club_venues where afl_venue_code is not null group by 1,2 having count(*) > 1) x) as duplicate_club_venue_codes;

-- Acceptance baseline on 2026-11-06: 92 clubs, 109 registrations, 100 venues,
-- 160 active opponents, 123 linked, 37 unresolved, 101 active games.
-- Do not use this script to delete, merge, or rename historical records.
