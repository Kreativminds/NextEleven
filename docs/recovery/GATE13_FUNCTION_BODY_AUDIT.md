# Gate 13 function body audit

Read-only comparison on 2026-11-06.

The 30 application function signatures match between production and the isolated restore. After removing schema qualifiers and whitespace, 19 function source hashes match and 11 differ.

Differing functions: claim_account_code, generate_team_share_token, portal_row_payload, portal_bootstrap, portal_pull, portal_bootstrap_v2, portal_save_training_session, portal_bootstrap_sequence, log_portal_change, validate_series_write, fmt_public_name.

Some source lengths differ substantially. Therefore function restoration is NOT verified. Do not approve the restore as equivalent until all 11 are reconciled from a supported consistent backup and retested. No database changes were made.
