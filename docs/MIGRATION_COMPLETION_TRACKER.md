# Next Eleven: unified migration completion tracker

Updated 2026-11-06. **No production deployment, data changes, merges or release approval authorized.** This tracker is the single cross-workstream queue; evidence must be attached before closing any gate.

## Priority 0: production data integrity and federation identity

| ID | Status | Acceptance evidence | Next action |
|---|---|---|---|
| FED-01 | In progress | 101 active games all matched to exactly one opponent; 56 federation-linked; 45 unlinked across 14 names | Verify each candidate against federation competition registration, not name similarity |
| FED-02 | In progress | 16 duplicate federation identity groups, 22 redundant opponent rows, 30 game references | Link historical games to canonical federation IDs; verify 2026/27 fixtures and account isolation; no physical deletion before verified backup |
| FED-03 | Isolated schema and backfill tested, not deployed | Link schema applied on isolated project, RLS and trigger active; SLO Benfica and Olivais A linked to the same Olivais federation ID; backfill rerun idempotent; wrong owner, club and historical name rejected | Validate positive backfill against faithful production fixture snapshot before release |
| FED-04 | Partially deployed, isolated review tests passed | Production deletion review protection active, addition review absent; isolated addition schema applied; requester insert passed; forged requester rejected; non-admin review updated zero rows; admin review passed; deletion request, admin approval and approved soft-delete passed in rollback-only isolated test; recursive RLS policy corrected with private approval helper | Test browser workflow, notifications and local classification; approve addition deployment separately |

## Priority 1: integration and release security

| ID | Status | Acceptance evidence | Next action |
|---|---|---|---|
| SEC-01 | In progress | Federation link table denies authenticated INSERT/UPDATE/DELETE; negative cross-account, wrong club and wrong historical name mutations rejected in isolated tests | Run anonymous, user A, user B and admin matrix for addition/deletion review tables and RPCs |
| SYNC-01 | Open | Offline and multi-device sync behavior, collision recovery, no data loss | Reproduce and regression-test multi-account cases; review existing SYNC-008 |
| INT-01 | Open | PR #36 reports away-match weather RPC/field mismatch | Compare actual RPC signature with admin form, prepare isolated fix and tests |
| UX-01 | Open | Federation picker, Settings catalogue, parent fixtures and admin workflows | Browser regression with duplicated aliases, Olivais Sul separation, season 2026/27 and missing clubs |

## Deferred improvement, not a release prerequisite: Gate 13 disaster recovery

| ID | Status | Acceptance evidence | Next action |
|---|---|---|---|
| DR-01 | Partial | 30/30 function source+metadata, 143 indexes, 88 constraints, 106 RLS policies, 30 triggers parity | Re-run parity on isolated restore with timestamped reproducible evidence |
| DR-02 | Partial | 36/38 table counts, 28/38 content fingerprints match | Identify 2 count and 10 fingerprint mismatches; distinguish snapshot drift from missing rows |
| DR-03 | Blocked on evidence | Auth users, identities, Storage objects/buckets, snapshot consistency | Establish export and restore procedure with isolated test, no production mutation |
| DR-04 | Open | PR #37 docs/gate13-recovery-runbook | Validate full restore drill, recovery time and rollback criteria before signoff |

## Priority 3: integrated QA and release readiness

| ID | Status | Acceptance evidence | Next action |
|---|---|---|---|
| QA-01 | Open | Syntax, i18n, HTML, opponent regressions, season calendar, auth, RLS, smoke tests all green | Run all workflows on exact candidate SHA and capture links |
| QA-02 | In progress | Reviewed open PRs #2, #4, #36, #37, #38. PR #36 and #38 both change index.html; #36 adds home-ground coordinates in three season-creation paths, while #38 changes opponent catalogue and settings. Integration order: preserve #36 coordinates while incorporating #38 federation picker, then rerun tests. PR #37 is documentation-only and not a federation release blocker | All five open PRs inspected; integration review complete. Verify candidate SHA and test combined changes in QA-01 before merge |
| REL-01 | Not approved | Deployment checklist, rollback, backup, release notes and explicit owner approval | Produce approval-ready release bundle; no deployment without authorization |

## Decision and identity invariants

- Olivais A, Olivais B, Olivais 2014 and SL Olivais are one club identity when federation-confirmed; Olivais Sul is distinct. Squad labels belong to competition registrations, not club names.
- Never equate CAC and Cacém merely because of a similar abbreviation.
- Only the owner/admin can delete clubs after dependency checks. Users submit proposals; local teams must be visibly flagged, not falsely federation-verified.
- No renaming or deleting historical fixture opponent names during migration; preserve 2026/27 season, scores, events and standings.
- Gate 13 test project tqpykeuuzcqudqtfrqmc is isolated; production project wicydcvdakqopodbxtrl remains read-only for migration work.

## Fresh isolated-environment discovery (2026-11-06)

A read-only `information_schema.tables` comparison of production and isolated project revealed that the **project root** of tqpykeuuzcqudqtfrqmc contains only 26 public base tables, while production contains 44 public base tables (including operational staging tables). Production-only application tables include `roadmap_items`, `profiles`, `player_game_stats`, `training_sessions`, `training_packs`, `events`, `backups` and others. The isolated project also has test-only tables. This is **not evidence that the named `gate13_restore` branch is incomplete**: branch-level inspection is required. Do not run full DR parity against the project root and mislabel it a restore test. Verify the actual branch identifier and compare the same schema/snapshot before re-running DR gates.

## Evidence register

- PR #37: https://github.com/Kreativminds/NextEleven/pull/37
- PR #38: https://github.com/Kreativminds/NextEleven/pull/38
- PR #36: https://github.com/Kreativminds/NextEleven/pull/36
- Federation name inventory: docs/audits/federation_unlinked_games_review_20261106.md
- Candidate identity map: docs/audits/federation_candidate_identity_map_20261106.md
- Existing regression workflow #27 passed for commit 02deb111d0a710e32b3ed797776133e17a76ab89.

## Completion policy

A task is complete only after implementation, isolated tests, negative tests, evidence, dependency resolution and (where required) explicitly approved release. A commit or green unit test alone is not deployment or migration completion.

## PR #36 dependency review (2026-11-06)

- PR #36 changes only `index.html`, adding home-ground coordinates to season wizard, first-time wizard, and Settings season creation.
- PR #38 also changes `index.html`, including opponent Settings, federation catalogue and picker. Both PRs therefore touch the same large HTML file and require integration/rebase before merge. Their shown diff hunks do not directly overlap, but mergeability has not been confirmed.
- Preserve the `homeGroundLat` and `homeGroundLng` fields and invalid-coordinate validation from #36 in the eventual combined candidate.
- PR #37 is recovery documentation and should not block federation deployment. PRs #2 and #4 are older, separate UI/timezone changes requiring disposition before full branch inventory is closed.
- No merge or production deployment performed.

## Older open PR dependency inspection (2026-11-06)

- PR #2: `css/nexteleven.css` UI accent corrections; `index.html` only updates the CSS cache-busting query; `version.json` changes. No direct overlap with PR #38's shown `index.html` federation hunks, but CSS visuals require regression.
- PR #4: `index.html` fixes kickoff-dialog timezone date conversion (`toISOString().slice(0,10)` replaced with local `dISO`), plus `version.json`. No direct overlap with PR #38's shown federation hunks; retain timezone behavior in eventual candidate.
- All five currently open PRs (#2, #4, #36, #37, #38) now have file inventory and patch-level dependency inspection. No merges performed. Integration smoke testing and exact candidate SHA verification remain under QA-01.
