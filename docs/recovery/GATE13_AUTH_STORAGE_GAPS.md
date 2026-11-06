# Gate 13: Auth and Storage recovery gap

Read-only inventory 2026-11-06:

| Component | Production | Isolated test project |
|---|---:|---:|
| auth.users | 3 | 5 |
| auth.identities | 5 | 0 |
| storage.buckets | 1 | 0 |
| storage.objects metadata rows | 16 | 0 |

The five test users are not proof that production accounts or identities were recovered. The isolated project has no restored Storage bucket metadata or object records, and no object-byte recovery has been verified. Do not copy production identities, credentials or private files into an unrelated test environment without an approved secure recovery design. Verify user login and file-byte integrity in a controlled rehearsal.

Schema parity is strong (30 application functions, 143 indexes, 88 constraints, 106 RLS policies, 30 triggers), but complete disaster recovery remains NO-GO.

No production writes or deployments.
