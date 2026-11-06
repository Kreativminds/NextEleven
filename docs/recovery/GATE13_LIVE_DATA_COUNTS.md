# Gate 13 live data reconciliation, 2026-11-06

Read-only counts on production and isolated restore:

| Table | Production | Restore |
|---|---:|---:|
| games | 182 | 182 |
| players | 110 | 110 |
| game_players | 321 | 321 |
| opponents | 249 | 249 |
| roadmap_items | 130 | 130 |
| seasons | 7 | 7 |
| club_teams | 6 | 6 |
| profiles | 3 | 3 |
| season_calendar_events | 10 | 10 |
| portal_change_log | 3510 | 3468 |

Production audit log maximum sequence is 3784. The isolated restore has a synthetic test sequence 999999999. A count difference against live production is not a valid backup-integrity test without a fixed snapshot boundary.

Critical recovery finding: 11 of 30 application function bodies differ after schema and whitespace normalization. They must be reconciled before declaring restore success.

Gate 13 remains OPEN. No production modifications were made.
