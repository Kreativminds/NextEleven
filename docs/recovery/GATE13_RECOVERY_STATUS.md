# Gate 13 | Recovery validation and remaining work

Status: **OPEN**. Isolated database restore evidence is strong, but end-to-end disaster recovery is not yet demonstrated.

## Verified against isolated Supabase test project
- Project: `tqpykeuuzcqudqtfrqmc`, schema: `gate13_restore`.
- 38 tables, 5 views, 88 constraints, 143 indexes, 30 non-internal triggers and 106 RLS policies.
- 35 function signatures, including five test-only routines: `test_probe2`, `test_probe3`, `test_probe5`, `test_probe6`, `test_secdef_probe`.
- Audit table has 3,468 records versus 3,465 in exported snapshot. Extra sequence values: 3740, 3741, 999999999. These must not be deleted without approval.
- `portal_change_log_sequence_seq` currently reports last_value 3741, while a test record has sequence 999999999. This is an isolated test-environment anomaly, not evidence of a production issue.
- `profiles_account_number_seq` also exists and requires restore validation.

## Restore procedure precautions
1. Restore only into a new isolated target, never overwrite production.
2. Verify schema and manifest checksums before restoring data.
3. Load table data and validate counts, keys, foreign keys, views, triggers, policies and RPCs.
4. After explicit-ID imports, inspect every owned or application-managed sequence and resynchronise as appropriate. For a **clean** target without synthetic test rows, an example for the audit sequence is:
   ```sql
   SELECT setval(
     'gate13_restore.portal_change_log_sequence_seq',
     COALESCE((SELECT MAX(sequence) FROM gate13_restore.portal_change_log), 1),
     EXISTS (SELECT 1 FROM gate13_restore.portal_change_log)
   );
   ```
   Adapt schema and sequence names to the actual restore target. Do not blindly use this on the existing test schema with sequence 999999999.
5. Test representative read and write paths using disposable test records in an approved environment.

## Blocking recovery gaps
- Consistent database snapshot with supported export and restore procedure.
- Auth account, identity and MFA recovery test.
- Physical Storage objects backup and restore test.
- Secret and application configuration recovery plan.
- Durable encrypted off-session backup with independently held passphrase.
- End-to-end application recovery rehearsal.

## Change control
This file is documentation only. No production changes, cleanup, branch merge or deployment are authorised by this record.
