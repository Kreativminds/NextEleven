# Gate 13 security and trigger reconciliation

Read-only production versus isolated restore checks, 2026-11-06:

- 106 RLS policies matched by table, policy name, command, permissiveness, USING expression and WITH CHECK expression, after normalizing the isolated schema qualifier.
- 30 non-internal triggers matched by table, trigger name and full `pg_get_triggerdef` definition, after normalizing schema qualifiers.
- No RLS or trigger discrepancies remain in these comparisons.

These checks do not establish application function-body equivalence, data-content integrity, Auth or Storage recovery. Gate 13 remains OPEN. No production modifications were made.
