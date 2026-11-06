# Gate 13: complete application routine parity

2026-11-06, verified read-only against production and isolated restore after the test-only migration `gate13_align_generate_team_share_token`.

All 30 production application function signatures have matching normalized source text in `gate13_restore`. Normalization removes comments, whitespace and the environment-specific `public.` / `gate13_restore.` qualifiers. All 30 also match on SECURITY DEFINER flag, volatility, parallel safety, strictness, set-returning flag, return type and schema-normalized function settings. Five additional test-only functions are excluded from this parity assertion.

This is source and metadata parity, not functional test coverage. No production modifications were made.

Gate 13 remains OPEN until consistent backup, snapshot data parity, Auth and Storage recovery and complete rehearsal are verified.
