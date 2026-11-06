# Gate 13: function recovery resolution

2026-11-06. Production read-only, isolated restore test changes only.

Eleven functions were initially flagged by raw hashes. After removing comments, whitespace and explicit schema qualifiers, ten had identical normalized source text: claim_account_code, portal_row_payload, portal_bootstrap, portal_pull, portal_bootstrap_v2, portal_save_training_session, portal_bootstrap_sequence, log_portal_change, validate_series_write and fmt_public_name.

The eleventh, generate_team_share_token, had a genuine semantic difference: production reads existing privacy settings, deletes the old link, and inserts a new link preserving privacy; the restore updated the existing link or inserted defaults. The isolated restore was corrected through migration `gate13_align_generate_team_share_token`. A fresh normalized source comparison now matches production. SECURITY DEFINER, volatility and schema-adjusted search_path also match.

This establishes source-text equivalence for the eleven previously flagged functions, not a complete execution test or full recovery validation. A full function signature and metadata audit remains required before declaring all 30 functions recovered.

No production writes, merges or deployments.
