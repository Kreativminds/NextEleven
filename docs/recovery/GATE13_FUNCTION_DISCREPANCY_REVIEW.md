# Gate 13: function implementation discrepancy

Read-only comparison completed 2026-11-06.

After normalizing schema qualifiers and whitespace, 19 of 30 application function bodies match between production and the isolated restore. Eleven do not: claim_account_code, generate_team_share_token, portal_row_payload, portal_bootstrap, portal_pull, portal_bootstrap_v2, portal_save_training_session, portal_bootstrap_sequence, log_portal_change, validate_series_write and fmt_public_name.

The differences are material enough to prevent declaring a successful restore. In particular, portal_bootstrap and portal_pull have substantially shorter bodies in the isolated restore. They require recreation from authoritative source and retesting in isolation, not changes to production.

The isolated test project has a different migration history from production, including Gate 4 and Gate 5 experiments. Do not treat it as an exact production clone.

The isolated project's security advisor also reports warnings for publicly executable SECURITY DEFINER functions and mutable function search paths. These are review findings, not evidence of exploitation. Review the intended public token-based access model before changing permissions.

Gate 13 remains OPEN. No production modifications or merge.
