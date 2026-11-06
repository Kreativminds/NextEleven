# Next Eleven full migration execution tracker

Updated 2026-11-06. This is the cross-workstream tracker for the entire application migration, not just disaster recovery. Source of truth: live GitHub, Supabase and verified test evidence. Do not infer deployment status from a pending SQL file or an unmerged PR.

## Workstreams

| Workstream | Current evidence | Next safe action | Release gate |
|---|---|---|---|
| Disaster recovery, Gate 13 | 30/30 function parity; 143/143 indexes; 88/88 constraints; 106 RLS policies; 30 triggers; 28/38 table content fingerprints match live restore | Snapshot-bound data audit, sequence rehearsal, Auth/Storage recovery design and test | NO-GO until complete recovery rehearsal |
| Pending database migrations | `supabase/migrations_pending/README.md` documents 001/002 but the directory contains at least 003-009; the README is stale | Inventory each pending SQL against current production read-only, identify already-applied/no-op changes, dependency and rollback plans | Explicit production approval |
| Parents Page away-weather | `BUGS.md` has an open issue: away fixture lacks opponent latitude/longitude in public RPC | Inspect live `get_public_team_data`, draft migration 010 and isolated regression tests | RPC integration and authorization checks |
| Open feature branches and PRs | PR #36 is described as unmerged; PR #35 adds weather; PR #37 holds recovery evidence; federation catalogue branch exists | Reconcile current PR statuses, conflicts, tests, dependencies and deployment order | Reviewed merge/deployment approvals |
| Automated QA | Nightly run log records syntax, i18n and regression tests, but its historical results are not fresh proof | Run or independently verify current tests and coverage on target commits | Current commit acceptance suite |
| Public domain and app hosting | `CNAME` reportedly points to next11.pt; previous nightly run could not independently verify live DNS | Check HTTPS, DNS, redirects and GitHub Pages deployment configuration | Verified public access |
| Security and access | Public RPCs, RLS and SECURITY DEFINER usage require environment-specific review | Authenticated/anonymous access matrix, leak checks and policy regression tests | Security sign-off |
| Migration acceptance | No verified all-gates completion record yet | Define end-to-end smoke tests for administrator, parent and coach flows, import, games, results and data synchronization | Explicit final release approval |

## Execution policy

Proceed autonomously with read-only production discovery, branch changes, isolated testing, draft PRs and evidence gathering. Do not merge, deploy, modify production, delete data or spend money without explicit user authorization. Each execution should pick the highest-value safe unfinished item, perform implementation or validation, and update this tracker. Do not call a gate complete based solely on matching counts or a green unit test.
