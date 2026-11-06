# Gate 13 recovery checklist

## Verified read-only evidence
- [x] Isolated Supabase project is available.
- [x] 38 restored tables, all reported with RLS enabled.
- [x] 5 views, 88 constraints, 143 indexes, 30 non-internal triggers, 106 RLS policies.
- [x] 35 routines in restore schema, including 5 diagnostic test routines, leaving 30 expected application signatures.
- [x] Backup versus restore audit-log row-count difference explained by 3 additional sequence keys: 3740, 3741, 999999999.
- [x] Identified audit and account-number sequences.
- [x] Recovery documentation committed on a dedicated branch.

## Still required for Gate 13 closure
- [ ] Compare object definitions and full row contents against a single consistent backup.
- [ ] Validate sequence repair in a fresh isolated recovery target.
- [ ] Capture a transactionally consistent backup through an approved supported process.
- [ ] Validate Auth recovery, including identities and MFA.
- [ ] Restore and verify actual Storage object bytes.
- [ ] Verify secrets/configuration recovery plan without placing secrets in GitHub.
- [ ] Store a new encrypted backup durably with a rotated private passphrase.
- [ ] Complete end-to-end app recovery rehearsal and record acceptance evidence.

## Constraints
- No production writes, cleanup or deployment without explicit approval.
- No deletion of the three additional audit records or five test functions without explicit approval.
- This checklist is a recovery evidence tracker, not an authorisation to release Phase A.

**Decision: Gate 13 OPEN, full disaster recovery NO-GO.**
