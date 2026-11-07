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

## Production read-only integrity gate rerun (2026-11-06)

- 101 active games, 0 missing or ambiguous owner-scoped opponent references.
- 56 federation-linked games, 45 pending federation links; no automatic guess for pending identities.
- 160 active opponents: 123 linked, 37 unlinked.
- Federation catalogue: one Olivais, one Olivais Sul, distinct club IDs.
- Structural preflight gate passed (zero ambiguous game matches; separate Olivais identities). **Not** a production-data migration rehearsal, deployment or signoff. Full release remains blocked on 45 pending links, duplicate reconciliation and integrated regression.

## Additional scope AS-06: isolated security advisor triage (2026-11-06)

Status: **In progress**, outside original 33 tasks. Supabase isolated-project security advisors identified 9 RLS-without-policy informational findings (several test/restore tables), 10 mutable function search paths, 2 extensions in public, 2 token-based public-team SECURITY DEFINER RPCs executable by anon/authenticated, and disabled leaked-password protection. These are findings requiring intent/impact assessment, **not confirmed exploits**. In particular, public-team RPCs may intentionally support public token access: do not revoke them without checking the app contract. The private `app_private.can_admin_delete_opponent` helper is not executable by anon and is executable by authenticated, as designed for RLS evaluation. No production settings changed. Relevant references: https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable and https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection.

## AS-06 follow-up: public token RPC audit (2026-11-06)

- Reviewed both SECURITY DEFINER public RPC definitions. Both require an enabled matching `team_share_links.share_token` before reading data; the full-team RPC scopes records by the link owner and applies privacy options; the opponent-slice RPC resolves the owner from the link and delegates to `_opponent_lookup_for_user`.
- Rollback-only tests as Postgres `anon`: invalid token returned SQL NULL for `get_public_team_data` and zero rows for `get_public_team_data_opponent_slice`.
- **Do not revoke anon EXECUTE** without replacing the intentional public parent-page access contract. These linter warnings alone do not prove an exploit.
- Remaining AS-06: assess token entropy/revocation, valid-token privacy and cross-owner isolation, function search-path findings, extension placement and password protection. Status stays In progress.

## Additional scope audit disposition (2026-11-06)

- **AS-06 Security advisor findings review: Passed (triage only).** Findings inventoried, public token RPC intent checked, invalid-token anon negative tests passed, functions use fixed `search_path=public`, private deletion helper anon EXECUTE denied, disabled-link slice returned no rows. No confirmed exploit from these checks. This does **not** mean the warnings are remediated or the full security regression passed.
- **AS-07 Security advisor remediation and verification: To do.** Assess and, where appropriate, remediate mutable search paths, public extensions, no-policy staging tables, Auth leaked-password setting, and public-token threat model (including revocation, entropy and cross-account privacy). Do not disable public RPCs without preserving parent sharing. All production changes require explicit approval.

## Original task #27 automated regression suite (2026-11-06)

**Status changed: To do -> In progress.** Verified PR #38 commit `814a9a6` has GitHub Actions federation picker regression run 42302971736 with conclusion **success**. Inspected workflow and found its PR path filter excluded federation SQL migrations and SQL test fixtures, so regression could be skipped on security/database-only changes. Fixed workflow filter to include `supabase/migrations/20261106*.sql` and `tests/sql/federation_*.sql`, plus explicit fixture-existence assertions, commit `36e17511`. The SQL fixtures are **not executed by this Node workflow**; they still require isolated PostgreSQL runs. Full automated regression remains open until database role-matrix and browser workflows are automated and CI verified on new commit. No production deployment.

## Original task #17 complete security regression (2026-11-06)

Status: **In progress**, not passed. Tested isolated non-admin B: no admin membership visibility, no cross-account deletion requests, no cross-account addition requests (all true). Added reproducible `tests/sql/opponent_review_nonadmin_rls_isolated.sql` in commit `beb519c0`. Still required: seeded positive/negative admin matrix, browser workflows, authenticated/anonymous RPC and approval state transitions. No production changes.

## Original application regression verification (2026-11-06)

PR #38 commit `0602d2d` GitHub Actions run **42303343163**, job **128186413995**, succeeded. All three Node checks and SQL fixture-presence assertion passed. This supports the implementation of original task #18 (federation picker) and #20 (match save/edit protection), but the picker remains feature-flagged off and no browser end-to-end test has been completed. Neither task can be marked Passed yet. No production change.

## Original task #18 acceptance closure (2026-11-06)

**Passed for pre-production implementation:** federation opponent picker. GitHub Actions run **42304525350** (run #85), commit `2b23bbc73731bb88de5d12f0d9f45c62ef77922c`, completed successfully. Chromium browser acceptance, picker Node regression, match-save source contract, opponents Settings regression, and SQL fixture presence all green. Browser test uses a synthetic page and mocked federation service, exercising flag-off behavior, federation suggestions, distinct Olivais Sul and outage fallback. This does **not** validate authenticated production Supabase browser flows, match create/edit E2E, parent share links, offline/multi-device, or deployment. Feature flag remains OFF. Task #18 is accepted as implemented and browser-smoke-tested in pre-production, with integration/release tests remaining under original tasks #27 and #29. Fixed original scope becomes **14 Passed, 0 Failed, 8 In progress, 11 To do (14/33, 42%)**. Application and integration becomes 1 Passed, 3 In progress, 4 To do. No production change.

## Original task #19 browser verification (2026-11-06)

GitHub Actions run **42304845242** (#88), commit `51c736cc817fbc8e0715b51527a9232793b118f9`, completed **success**. Both Chromium browser checks and three Node regression suites passed. The new `tests/browser_opponent_approval.js` exercises user federation/local proposals, deletion requests, administrator rejection reasons, and confirms no direct opponent mutation from the tested handlers. The browser test uses mocked transport and does not verify live database role policies, delivered administrator notifications, user notification delivery, or complete approved-deletion execution. **Task #19 remains In progress**, not Passed, until those acceptance gaps close. Original scope remains **14/33 (42%)**. No production changes.

## Original task #20 match save/edit protection (2026-11-06)

Production read-only integrity check: **101 active games, 101 unique owner-scoped opponent matches, 0 missing, 0 ambiguous**. Existing `tests/regression_federation_match_save_contract.js` checks preservation of game ID, UUID, creation/kickoff timestamps, opponent score, local backup and sync scheduling, and is green in GitHub Actions run #88. This is baseline evidence, not browser save/edit execution or a production migration rehearsal. **Task #20 remains In progress** until real create/edit browser flows and rollback/history protection are verified. No production changes.

## Task #19 approved deletion and notification execution (2026-11-06)

Implemented `20261106220000_complete_approved_opponent_deletion.sql`: authenticated verified administrator only, approved request required, exact single opponent identity, transactional soft-delete and status completion, preserving historical fixtures. Isolated Supabase role A (admin)/B (requester) transaction passed and rolled back; non-admin RPC call rejected. Implemented `20261106213000_opponent_review_notifications.sql`: durable admin submission inbox events, requester decision events and distinct final completion events. Isolated approval -> completion produced both user events; rolled back. Notification identity trigger prevents recipient/message forgery. **Still pending for #19:** wire inbox and approved-deletion RPC into actual application interface, then verify end-to-end browser + authenticated Data API. Original tally stays 14/33, no production mutation.

## Final manual Go: deletion completion notification role matrix (2026-11-06)

- Added `tests/sql/opponent_deletion_completion_notifications_isolated.sql`, commit `6a8ed8185c4704422384a9d8c29c603a16e79f15`.
- Executed on isolated project `tqpykeuuzcqudqtfrqmc` with rollback-only authenticated user B and admin A: submission inbox, admin approval, rejected premature completion, completion RPC, requester decision and completion events, and admin-only notification visibility all passed (SQL returned no errors).
- This is genuine isolated database role-matrix evidence, not app browser/API integration. Task #19 remains In progress pending application UI integration and end-to-end acceptance; task #17 remains In progress pending complete security regression. Original tally unchanged at 14/33 Passed (42%). Production untouched.

## Overnight task #19: review inbox UI adapter (2026-11-06)

- Added `js/opponent-review-inbox.js` commit `a5c793aa66494fcb2f5442ae0e6ac98497e8d2fc`, a framework-independent authenticated UI adapter for loading the user's review notifications, escaping notification HTML, marking own messages read, and administrator-gated completion of approved deletion through `rpc/complete_approved_opponent_deletion` (never direct opponent mutation).
- Added `tests/regression_opponent_review_inbox.js` commit `cef4be28da6fe86a58aaabba1bc3cfaa3e546afd` covering owner-filtered inbox, HTML escaping, admin gate, cancelled confirmation, RPC call and no direct opponent mutation. Test file committed but its execution/CI success is **not yet verified**.
- **Remaining:** integrate adapter into the real `index.html` Settings opponent panel, wire notification controls, run browser tests and authenticated Data API end-to-end. Do not mark #19 Passed. Fixed 33-task KPI unchanged: 14 Passed, 0 Failed, 8 In progress, 11 To do. Additional scope unchanged: 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Task #17: notification integrity and owner isolation (2026-11-06)

- Added `tests/sql/opponent_notification_integrity_rls_isolated.sql`, commit `745b10244cd2e87c1bf5ff98b6ed8c52749dab23`.
- Executed committed fixture successfully in isolated Supabase `tqpykeuuzcqudqtfrqmc` as authenticated requester B and reviewer A, with all writes rolled back. Verified: forged notification INSERT rejected; requester cannot read admin submission; admin receives submission; requester receives rejection; message and recipient immutability enforced; own read acknowledgement succeeds and cannot be reversed.
- This advances original #17 security regression, which remains In progress pending complete role matrix and application/API tests. Task #19 UI integration is separately being developed by another agent. Fixed KPI remains 14 Passed, 0 Failed, 8 In progress, 11 To do; additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Original #20 historical match preservation after approved deletion (2026-11-07)

- Committed `tests/sql/historical_game_survives_opponent_deletion_isolated.sql` in `78163e2a9cc9aaafbba8087a0cc8e1c0b36f0df7`.
- Ran rollback-only authenticated requester B/admin A integration test on isolated Supabase `tqpykeuuzcqudqtfrqmc`. Seeded a 2026/27 fixture with final score 3-2, goal event and historical opponent name; approved and completed soft-deletion of the related opponent through the actual RPC; asserted the opponent was soft-deleted while the complete game JSON payload, scores, events, season and game row remained unchanged. RPC returned true; all assertions passed; transaction rolled back.
- This establishes database-level history preservation for #20, but not the browser create/edit workflow or synchronization safety. #20 remains In progress, #19 remains In progress. Fixed KPI stays 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production untouched.

## Overnight task #27: review inbox regression coverage (2026-11-07)

- Added `tests/browser_opponent_review_inbox.js` in commit `3bd3a6b234266f528cd64c546cb1c244587446ee`, covering actual Chromium DOM escaping of notification messages, unread button visibility, owner-scoped read acknowledgement, non-admin denial, cancelled completion and admin-only completion RPC with mocked transport.
- Extended `.github/workflows/federation-picker-regression.yml` in commit `0c0c4e0c8bf99ad74aa1b9af6d2422d1eddcfd56` to run both `tests/regression_opponent_review_inbox.js` and the new Chromium browser test, and require new rollback-only SQL fixtures. This is substantive CI integration, but **the new workflow execution has not yet been verified**. The SQL fixtures are checked for presence, not executed by GitHub Actions.
- Original #27 remains In progress until CI evidence and full integration regression; #19 remains In progress until the adapter is actually wired into the application and authenticated Data API verified. No production changes. Fixed original KPI unchanged 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do.

## Overnight task #17: approved deletion negative authorization and identity drift (2026-11-07)

- Added `tests/sql/opponent_deletion_authorization_identity_drift_isolated.sql` (final commit `af506a38c785cc9a2eb8f8d44ab1515f31dbb1a4`). Executed successfully on isolated Supabase `tqpykeuuzcqudqtfrqmc` with a full transaction rollback.
- Authenticated requester B was denied completion RPC on an unapproved request, with opponent and request unchanged. Administrator A was also denied completion before approval. After legitimate admin approval, requester B renamed the opponent, simulating stale identity; administrator completion RPC failed closed, request remained approved, and owner B confirmed renamed opponent still active.
- Important RLS finding during test development: administrator cannot read the renamed foreign opponent once the approved identity no longer matches, which is expected and is why the final survival assertion uses the owner role. No application changes or production mutation. Original #17 remains In progress; original #19 remains In progress pending real UI/Data API integration. KPI remains 14/33 passed (42%), additional scope 6/7 passed.

## Overnight #27 CI confirmation and #17 anonymous role gate (2026-11-07)

- Verified GitHub Actions run [42316950882](https://github.com/Kreativminds/NextEleven/actions/runs/42316950882), job `128231792949`, for workflow commit `0c0c4e0c8bf99ad74aa1b9af6d2422d1eddcfd56`: **success**. Node federation/match/settings/inbox tests, Chromium federation picker/approval/inbox adapter tests and SQL fixture presence checks all succeeded. SQL fixtures were **not** executed in GitHub Actions. Original #27 remains In progress because full candidate integration and database tests in CI remain outstanding.
- Executed an isolated `anon` privilege matrix successfully. Anonymous role lacks SELECT/INSERT/UPDATE/DELETE on opponent review notifications, deletion requests, addition requests and administrator membership; it also lacks EXECUTE on approved-deletion completion RPC. The initial attempt to query notification rows as anon produced expected permission-denied; the final regression uses `has_table_privilege` to assert denied grants without relying on RLS row visibility. Committed reusable fixture `tests/sql/opponent_review_anon_privilege_isolated.sql` in `045df092f496a70f0909da4c5cd697ff24f3f772`.
- This is verified security evidence for original #17, which remains In progress pending full role and browser/API regression. Original KPI unchanged: 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope: 6 Passed, 0 Failed, 0 In progress, 1 To do. No production changes.

## Overnight #17/#20 duplicate-name and historical fixture protection (2026-11-07)

- Isolated Supabase revealed `opponents_name_uniq` rejects a same-owner duplicate name with SQLSTATE 23505, so an attempted two-row ambiguous-name fixture could not be constructed. This is a database uniqueness protection, not proof all federation identity duplicates are eliminated.
- Added `tests/sql/opponent_duplicate_name_history_isolated.sql` in commit `a9fa35cbc21680090ae0a0b3bcd9256feb99ae8f`; rollback-only authenticated role B execution passed. It asserts a second same-owner opponent with the same name is rejected, the original active opponent remains, and its 2026/27 historical fixture JSON (1-1 result) remains intact.
- Original #17 and #20 remain In progress; no UI/API end-to-end completion or production migration. Fixed original KPI 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production untouched.

## Overnight original #10 duplicate federation identity impact preflight (2026-11-07)

- Added reusable, strictly read-only `tests/sql/federation_duplicate_identity_readonly_preflight.sql`, commit `02e0bc3564c9ec1ab65ddfedd1990c3e0de32b02`.
- Executed against production with SELECT-only SQL (no DDL/DML). Confirmed 16 same-owner/same-federation duplicate identity groups, 38 active opponent members, 22 redundant rows, 30 name-matched historical fixtures and zero unnamed members. This independently reconciles the prior inventory, but name matches are **not** deletion authorization and do not prove safe canonical selection. Distinct Olivais Sul remains a separate federation identity.
- Original #10 remains In progress pending verified owner-scoped canonical mapping, historical link preservation and isolated migration rehearsal. Original 33-task KPI unchanged at 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope unchanged 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: canonical selection safety blocker audit (2026-11-07)

- Committed read-only `tests/sql/federation_duplicate_canonical_safety_readonly.sql` (`eae893d771c6010512a567f7420e3b5ca7ebd31c`). This reports duplicate-group fixture-reference risk, ambiguous names, missing IDs and multiple historically used names without selecting or modifying a canonical row.
- Executed against isolated Supabase `tqpykeuuzcqudqtfrqmc` with SELECT-only access. Result: 1 duplicate federation identity group, 2 member rows, 1 redundant row, 2 historical fixture name matches, **1 group with multiple distinct historical opponent names referenced by fixtures**, no unnamed members, no ambiguous fixture-name rows and no missing local IDs. This is a real blocker to naive duplicate deletion even when the federation identity is shared.
- Isolated counts do not represent the production inventory of 16 duplicate groups. No production query or mutation in this run. Original #10 remains In progress until a safe canonical mapping and migration rehearsal preserve both historical names and game references. Original 33 KPI remains 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do.

## Overnight original #10: historical-name risk classification (2026-11-07)

- Added reusable read-only `tests/sql/federation_duplicate_review_classification_readonly.sql`, commit `4fd46cc59157cf3c428c1d01c327513eb30f41a2`. It groups duplicates by owner and verified federation identity, classifies identity-integrity blockers and one/multiple historical opponent-name preservation requirements, and deliberately does not choose a canonical row or modify data.
- Executed successfully against isolated Supabase `tqpykeuuzcqudqtfrqmc`: 1 duplicate group, 2 member rows, 1 redundant row and 2 matched historical fixture names. Classified as `requires_historical_alias_preservation`; naive consolidation is unsafe. These are isolated fixture counts, not production counts.
- Original #10 remains In progress pending reviewed canonical mapping, explicit alias retention and rollback-only consolidation rehearsal. Original KPI 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: historical fixture reference strength audit (2026-11-07)

- Added reusable, read-only `tests/sql/federation_duplicate_game_reference_strength_readonly.sql`, commit `35c4f701b60e4b2902487391d691476f6ddddc00`. The audit distinguishes name-only historical game matches from explicit local opponent ID matches and flags ambiguous or conflicting evidence, scoped by owner and verified federation identity.
- Executed on isolated Supabase `tqpykeuuzcqudqtfrqmc`: 2 affected games, **0 explicit opponent IDs**, **2 name-only references**, 0 ambiguous matches and 0 conflicting name/ID evidence. This means the test fixture's historical games cannot be safely remapped by an assumed opponent foreign key. Preserve both original fixture names and require reviewed canonical/alias mapping.
- Original #10 remains In progress; no duplicate consolidation or production data modification was performed. Fixed original KPI remains 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do.

## Overnight original #10: isolated historical alias mapping rehearsal (2026-11-07)

- Added `tests/sql/federation_duplicate_alias_coverage_rehearsal_isolated.sql`, commit `3e1ff0ed3b669f3eb6042848ba15fdebb4f61b7b`.
- Executed the equivalent rollback-only SQL on isolated Supabase `tqpykeuuzcqudqtfrqmc`, **passed** after correcting the fixture `local_id` type to text. A temporary owner/federation-scoped mapping preserves both historical opponent names, resolves them to one simulated canonical ID, checks that the canonical is an active opponent of the same owner/federation, covers both historical fixture references, and confirms fixture JSON payloads unchanged. Transaction rolled back; no opponent deleted.
- The canonical ID is an isolated test choice, not production authorization. This proves an alias-preserving rehearsal pattern but does not implement persistent aliases, resolve production's 16 duplicate groups, or approve any consolidation. Original #10 remains In progress; KPI 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #17: inbox acknowledgement and cross-owner isolation (2026-11-07)

- Added `tests/sql/opponent_review_inbox_acknowledgement_isolated.sql`, commit `c348e25c5dff87e0a2dd7937b9b26e91f854df6a`.
- Executed the rollback-only test in isolated Supabase `tqpykeuuzcqudqtfrqmc` as authenticated requester B and administrator A. PASS: admin received a submission event, could mark their own event read, could not revert read acknowledgement to unread, and requester B could neither see nor update the administrator's event. All fixture writes rolled back.
- Original #17 security regression remains In progress pending full authenticated API/browser matrix; original #19 inbox UI integration remains In progress. No task promoted to Passed. Original KPI 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: persistent guarded historical alias schema (2026-11-07)

- Implemented additive migration `supabase/migrations/20261107021000_opponent_historical_aliases.sql`, commit `c2f7d91c40632691cf18e1465dd67fc1ec63aa4e`. Creates owner-scoped historical name to canonical opponent mapping, verified same-owner/same-federation identity trigger, reviewed-by admin requirement, restrictive RLS and no authenticated write privileges. Historical game payloads and opponent records are untouched.
- Applied migration successfully **only** to isolated Supabase `tqpykeuuzcqudqtfrqmc`. Rollback-only positive alias insertion for SLO Benfica / Olivais A, wrong-name rejection, owner read, cross-owner read denial, and authenticated write grant denial passed. Fixture alias insertion rolled back. Migration schema itself persists in isolated project only.
- Original #10 remains In progress: no production canonical selection, bulk mapping, consolidation, historical migration or app integration yet. Fixed original KPI remains 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope remains 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: owner-scoped historical alias resolver (2026-11-07)

- Added `supabase/migrations/20261107023000_resolve_historical_opponent_alias.sql`, commit `b8fc27bfc638cf26f7f70065d18a37dc60895efe`. SECURITY INVOKER, authenticated-only, read-only resolver returns a canonical UUID only for a reviewed owner/federation-scoped historical alias whose source and canonical opponents remain active and identity-consistent. No fuzzy fallback, no fixture rewriting, no deletion.
- Applied only to isolated Supabase `tqpykeuuzcqudqtfrqmc`. Executed rollback-only authenticated role test PASS: valid Olivais A alias resolves to isolated SLO Benfica canonical; distinct Olivais Sul federation ID returns NULL; another user cannot read the mapping. Test fixture was rolled back. Reproducible `tests/sql/federation_historical_alias_resolution_isolated.sql`, commit `6c4e203085b5c7b042440cf9b3d60d65c42f6183`.
- Original #10 remains In progress until reviewed canonical decisions, persistent approved mappings, complete migration rehearsal and application integration. Fixed original 33-task KPI unchanged: 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: reviewed alias survives approved source soft-delete (2026-11-07)

- Found and fixed a concrete consolidation blocker: the original historical alias resolver required `src.deleted_at IS NULL`, making reviewed aliases stop resolving as soon as an approved redundant source opponent was soft-deleted. The canonical target must remain active, but the historical source may be soft-deleted while its owner, name and federation identity remain immutable.
- Committed additive resolver migration `supabase/migrations/20261107024500_preserve_soft_deleted_historical_alias.sql` (`ec71a68af1092b20dc7d037ce3cbbd14e24ba516`) and applied it only to isolated Supabase `tqpykeuuzcqudqtfrqmc`.
- Added rollback-only `tests/sql/federation_alias_soft_delete_survival_isolated.sql` (final corrected commit `5f47260a52455c6120866836372554443bebefc9`). **PASS** on isolated Supabase: reviewed deletion request, admin approval, source soft-delete under existing guard, alias resolution to active canonical, unchanged historical game payloads, distinct Olivais Sul and cross-owner denial. Test transaction rolled back, no lasting opponent deletion. Earlier test attempts identified and corrected admin approval and temporary table permission prerequisites.
- Original #10 remains **In progress** pending production-reviewed canonical mapping, all duplicate groups, app integration and full migration rehearsal. Fixed original 33-task KPI unchanged: 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.

## Overnight original #10: protect reviewed alias identity from drift (2026-11-07)

- Found an alias-integrity gap: after a reviewed alias was created, the canonical opponent could be soft-deleted or its federation identity changed, and the historical source name could be renamed, invalidating the reviewed resolution.
- Added additive `supabase/migrations/20261107030000_guard_reviewed_alias_identity.sql` (commit `3b2535cb17ee61d0b649deb9fe0d0cf9dd4051e3`). BEFORE UPDATE guard prevents soft-deletion of a canonical referenced by reviewed aliases and prevents source name/owner/federation drift and canonical owner/federation drift. It does not block an approved historical source soft-delete.
- Applied **only** to isolated Supabase `tqpykeuuzcqudqtfrqmc`, migration succeeded. Added `tests/sql/federation_reviewed_alias_identity_guard_isolated.sql` (commit `1741d96bd8f7f3df66f939af283b5819c28c485f`), executed rollback-only, **PASS**: canonical soft-delete, source rename and canonical federation drift rejected, both fixture opponents remained active after failed changes. No production mutation.
- Original #10 remains In progress pending reviewed canonical decisions, all 16 duplicate groups, app integration and full rehearsal. Original fixed 33-task KPI remains 14 Passed, 0 Failed, 8 In progress, 11 To do (42%). Additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do.

## Overnight original #27: CI path coverage for alias migration work (2026-11-07)

- Fixed a concrete release-regression gap in `.github/workflows/federation-picker-regression.yml`, commit `a592366dee5de75fc44f2cf2e2b641cc7769b55f`: the workflow previously triggered on `20261106*.sql` migrations but **not** on the new `20261107*.sql` historical alias and identity-guard migrations, so database-only overnight changes could bypass the PR regression workflow.
- Added PR triggers for 20261107 migrations, deletion and notification SQL test fixtures; expanded tracked-fixture assertions to include the alias schema, resolver, soft-delete survival and identity-guard migrations and their isolated SQL tests. Independently fetched and verified all seven newly asserted files exist on the feature branch.
- **Important limit:** this workflow checks fixture presence and runs Node/Chromium checks, **not** the PostgreSQL SQL fixtures. A successful workflow cannot be represented as an executed database role matrix. Await a workflow run on this new SHA; no CI success claimed yet. Original task #27 remains In progress. Fixed original KPI 14 Passed, 0 Failed, 8 In progress, 11 To do (42%); additional scope 6 Passed, 0 Failed, 0 In progress, 1 To do. Production unchanged.
