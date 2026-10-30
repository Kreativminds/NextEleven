# Pending production migrations — NOT yet applied

These two migrations are prepared and tested but **not applied to production**.
Per the standing rule for this project, no production data or schema change
runs without Victor's explicit approval.

Testing performed: both migrations were run against the live `wicydcvdakqopodbxtrl`
project inside an explicit `BEGIN; ... ROLLBACK;` transaction, so every statement
executed for real (including the unique-index checks) and was then fully reverted —
no production data was changed. Row counts, the `game_players_identity_uniq`
constraint, and the full set of affected rows were verified before rolling back.

## 001_convert_caio_to_permanent_player.sql
Converts Caio Andrade (temporary player id 1, season 6) into a permanent squad
player. Backup of every row this touches is in `caio_pre_migration_backup.json`.

Order matters and is the fix for the constraint failure in the previous attempt:
duplicate `game_players` rows are soft-deleted **before** any row is re-pointed
to the new `playerId` — re-pointing two active rows for the same game onto the
same `playerId` at once is exactly what violates `game_players_identity_uniq`.

Verified by dry run:
- `active_gp` 128 → 127 (one stale duplicate for game 253 soft-deleted; the
  other 3 games had no active duplicate, only this one did)
- `active_ge` / `active_ce` unchanged (3 / 3) — no goal or card event lost
- `active_players` 98 → 99 (Caio added)
- Zero rows violate `game_players_identity_uniq` after the update
- Caio no longer appears as an active guest anywhere (`tempPlayerId=1` with
  `calledUp=true` count is 0)
- His one yellow card (card 253, minute 72) is re-pointed to the new playerId

## 002_fix_card_red_count_direct_red.sql
Redefines `get_public_team_data` with one change: `cardRedCount` and the
match-level card display were matching the literal string `'red'`, but the
admin app has always recorded a direct red card as `'direct_red'` (see
`cardTypeIcon()` / `selectCardType()` in `index.html`). A direct red card was
therefore never counted in a player's season `cardRedCount` and rendered as a
🟨 instead of a 🟥 on the Parents Page match strip — the second half of
`team.html`'s matching `cardEventIcon()` fix is already in this PR. No red
cards exist in production yet, so this hasn't visibly manifested, but it
would break the first one recorded.

## Apply order
Run `002` first (pure function redefinition, independent of the data), then
`001`. Either is safe to run alone; running `001` fixes Caio regardless of
`002`, and `002` fixes red-card counting for every player regardless of `001`.
