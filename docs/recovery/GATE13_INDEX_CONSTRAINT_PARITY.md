# Gate 13: index and constraint definition parity

Read-only comparison 2026-11-06.

- All 143 index names and definitions match production after normalizing schema names.
- All 88 constraints match by table, name, type and full constraint definition after normalizing schema names.
- All 30 application function bodies and selected execution metadata matched in the previous audit, after the isolated restore correction.

These checks do not verify row content, Auth identities, Storage bytes or a complete recovery rehearsal. Gate 13 remains OPEN. Production unchanged.
