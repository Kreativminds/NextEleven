# Gate 13 recovery procedure (draft, not production-approved)

## Preconditions
- Use a fresh, isolated Supabase recovery target. Do not overwrite production.
- Confirm PostgreSQL and Supabase component compatibility, extensions, roles, schema dependencies and secrets.
- Verify the backup manifest, file sizes, SHA-256 digests and table row counts.
- The November 2026 JSON export is **not** an atomic database snapshot. Do not treat it as a complete disaster recovery backup.

## Database restore rehearsal
1. Capture a consistent backup using a supported Supabase export strategy and retain the associated migration, configuration and roles inventory. Do not assume raw pg_dump of managed auth/storage schemas is directly portable to a hosted Supabase project.
2. Rebuild schema in the isolated target; check extensions, 38 tables, 5 views, 88 constraints, 143 indexes, 30 non-internal triggers, 106 RLS policies and 30 application routine signatures.
3. Restore data and compare each table's row count and contents to the same consistent snapshot.
4. After explicit-ID loads, inspect all sequences, including `portal_change_log_sequence_seq` and `profiles_account_number_seq`. For the **clean target only**, with no artificial audit records, a sequence repair example is:

```sql
SELECT setval(
  'gate13_restore.portal_change_log_sequence_seq',
  COALESCE((SELECT MAX(sequence) FROM gate13_restore.portal_change_log), 1),
  EXISTS (SELECT 1 FROM gate13_restore.portal_change_log)
);
```

   Substitute the real target schema. Never apply this blindly to the existing test environment, which contains a synthetic sequence value 999999999.
5. Exercise representative RPCs and trigger-backed writes with approved disposable test data, and verify rollback/cleanup strategy.

## Separate recovery tracks
- Auth: inventory users, identities, MFA requirements, providers, redirects and credentials; rehearse on a compatible isolated target.
- Storage: export physical object bytes separately from database metadata, verify checksums and restore permissions.
- Config: document Edge Functions, environment variable names, Auth provider setup, SMTP, DNS, policies and JWT/key rotation process. Never commit secrets.
- Backup retention: keep an encrypted copy in durable owner-controlled storage with an independently held passphrase. A passphrase shared in chat must be rotated.
- Acceptance: sign off only after a full application login, team access, data and image recovery rehearsal.

## Change control
No production changes, data deletion, deployment or merge is authorised by this document.
