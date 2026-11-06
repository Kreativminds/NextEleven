# Gate 13: read-only reconciliation

Date: 2026-11-06

Read-only catalog checks compared production public schema with the isolated gate13_restore schema.

- Tables: 38 in each.
- Views: 5 in each.
- Non-internal triggers: 30 in each.
- RLS policies: 106 in each.
- Application function signatures: all 30 matched by name and argument types, excluding five diagnostic functions present only in the test schema.
- The documentation branch was three commits ahead and zero behind main at comparison time. No commit status checks were reported.

These checks establish inventory and signature parity, not function-body, row-content, or disaster-recovery equivalence.

Gate 13 remains OPEN due to consistent backup, Auth, Storage, durable retention, and full recovery rehearsal requirements.

No production changes were made.
