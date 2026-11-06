# Gate 13: full live table-count comparison

Read-only check on 2026-11-06 across all 38 application tables:

- 36 tables have equal live row counts between production and the isolated restore.
- `portal_change_log`: production 3,510, isolated restore 3,468.
- `portal_sessions`: production 1, isolated restore 0.
- Production total: 4,640; isolated restore total: 4,597.

These are live counts, not a transactionally consistent backup snapshot. The restore includes known synthetic test audit-log records. Equal counts do not establish row-content equivalence. The missing session in the test environment is not necessarily a defect because sessions may be ephemeral, but it requires a documented recovery policy.

No production writes. Gate 13 remains OPEN.
