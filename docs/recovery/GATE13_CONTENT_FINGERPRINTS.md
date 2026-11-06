# Gate 13: full table content fingerprint comparison

Read-only live comparison 2026-11-06, all 38 application tables. Each fingerprint is an order-independent MD5 of JSONB row representations, aggregated per table. No row contents or personal data were exported.

- 28/38 tables have matching content fingerprints.
- 10 differ: app_meta, card_events, club_history, game_players, opponents, portal_change_log, portal_sessions, profiles, roadmap_items, tournaments.
- Previous count check: 36/38 tables have matching row counts. Equal counts are not equal content.

These hashes compare a live production database against an older isolated restore and therefore do not by themselves prove restore corruption. A snapshot-bound manifest and exact point-in-time comparison are required. MD5 here is a comparison aid, not a tamper-resistant backup integrity mechanism.

Gate 13 remains OPEN. Production unchanged.
