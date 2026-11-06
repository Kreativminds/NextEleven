# Next Eleven, consolidated migration completion tracker

Updated 2026-11-06 UTC. **Not a release approval.** This is the single prioritized tracker for the full application migration. Production Supabase `wicydcvdakqopodbxtrl` is read-only for this work; isolated restore project `tqpykeuuzcqudqtfrqmc` may be used for safe tests. Do not merge, deploy, change production, delete records, spend money, or approve release without explicit authorization.

## Evidence inventory
- GitHub default branch `main`, active recovery branch `docs/gate13-recovery-runbook`, federation branch `feature/federation-picker-release-20261106`, catalogue branch `feature/opponent-federation-catalogue`, away-weather branch `fix/away-weather-coordinates-20261106`, and several calendar, parent UX, dark mode and sync branches. Branch presence does not prove readiness.
- Known open PRs: #37 recovery, #38 federation picker/settings, #36 home-ground coordinates on all season creation paths. Discover and reconcile all remaining PRs before integration.
- Pending SQL catalogue: `supabase/migrations_pending/README.md` has stale wording about two unapplied migrations; `BUGS.md` also contained an obsolete away-weather RPC diagnosis, corrected on this branch. Reconcile every migration with live production catalog and data before proposing execution.
- Gate 13 evidence to date: 30/30 function source and metadata parity, 143 indexes, 88 constraints, 106 RLS policies, 30 triggers; 36/38 table row counts and 28/38 fingerprints match. Auth, Storage and snapshot-consistent recovery remain incomplete.

## Priority queue and acceptance gates

| Priority | Workstream | State | Acceptance evidence / next safe action |
|---|---|---|---|
| P0 | Migration inventory and dependency graph | IN PROGRESS | Enumerate all gates, branches, PRs, pending migrations, environment targets and release criteria. Classify deployed, draft, obsolete, conflicting and unverified changes. |
| P0 | Production data integrity, opponent catalogue | OPEN | Verify account-scoped duplicates, stable club/squad identities, historical game references, venue/logo retention, import prevention and rollback. PR #38 only groups some duplicates visually; no actual record merge authorized. |
| P0 | Auth, RLS, security and public RPC | OPEN | Anonymous, parent, coach and admin permission tests, SECURITY INVOKER validation, cross-account isolation, no leaked private data, reproducible negative tests. |
| P0 | Sync and deletion consistency | OPEN | Verify offline create/edit/delete, soft-delete propagation, retry/idempotency, stable game UUID and local/cloud identity mapping; cover existing sync-fix branches. |
| P0 | Gate 13 disaster recovery | BLOCKED FOR COMPLETION | Restore reproducibly from a snapshot-consistent source, verify all 38 tables/fingerprints, Auth, Storage and recovery time/objectives on isolated test project; no production mutation. PR #37. |
| P1 | Opponent Settings and federation picker | IN REVIEW | PR #38, code-level regression checks; no age/series badges, alias-aware duplicate detection, squad distinctions, complete real browser flows and feature-flag rollback. |
| P1 | Weather and venues | DATA BLOCKER | Read-only production audit found 50 away fixtures with no opponent coordinates and 160 opponent records without coordinates; RPC already returns opponentLat/Lng. Prepare verified venue dataset, staged remediation, then weather E2E. PR #36 covers home creation forms. |
| P1 | Calendar, fixtures, competition breaks, results and cards | OPEN | Reconcile feature/fix branches, validate official vs friendly/tournament, folgas, Christmas/Easter, home/away, scores, cards, parent sharing, i18n and dark mode. |
| P1 | CI, UX and release smoke tests | OPEN | Automated syntax, i18n, browser, mobile, accessibility and real permission-boundary tests, plus cross-browser upload and parent page regression. |
| P1 | Deployment readiness | NOT AUTHORIZED | Document DNS/GitHub Pages target, Supabase environment configuration, migration order, backups, monitoring, rollback, staged launch and sign-off evidence. Explicit approval required for merge/deploy. |

## Execution rules
1. Complete safe read-only audits and isolated tests, commit findings and tests to dedicated branches/draft PRs.
2. Reconcile conflicting branch changes and production state before preparing migrations. Never infer production state from stale documentation.
3. Require backups, row-level before/after verification, per-account scope and rollback for data changes.
4. Record evidence and acceptance status here on each substantive run. Passing unit tests is not equivalent to deployed end-to-end validation.
5. Keep gates open until independent acceptance evidence exists; report only substantive progress or real blockers.

## Run log
- 2026-11-06: Confirmed branch inventory, identified PR #36 home-coordinate path, stale pending-migrations README, and corrected BUGS.md's away-weather root-cause narrative using the earlier read-only production audit. Created this consolidated tracker. No production changes.

## 2026-11-06 follow-up: live catalogue and PR scope reconciliation
- Read-only production information_schema inventory returned **42 public base tables**, including federation_clubs, federation_club_competitions, federation_club_venues, team_alias_mappings, opponents_merge_plan_tmp and _gate5_staging. These are present in production; presence alone does not establish row contents, RLS correctness, or feature deployment. The earlier Gate 13 inventory of 38 tables is a different baseline and must be reconciled explicitly before treating restore parity as complete.
- PR #38 changed exactly six files: index.html, three federation regression JS tests, a read-only acceptance SQL script and a GitHub Actions workflow. This is picker/settings and test coverage, **not** proof of underlying data deduplication.
- PR #36 changed index.html only, covering season creation UI; it does not remediate opponent venue coordinates.
- Pending migrations README describes only 001/002 while BUGS.md references 003-009 and reports Caio already resolved. **Do not run 001 or 004 based on stale descriptions**; inventory each pending file and compare production behavior first. The README's historical claim of production transactional testing is not authorization to repeat writes.
- Next safe execution: enumerate all 42 tables with RLS flags and compare the 38-table restore baseline; inspect federation catalogue and opponent foreign keys with SELECT-only SQL; run PR #38 regression scripts on isolated checkout; assess 003-009 one by one. Release gate remains OPEN.

## 2026-11-06 follow-up: live restore and RLS inventory
- Read-only pg_class inspection: production has **42** public ordinary tables, isolated restore has **25**. The restore contains test-only `_gate5_probe_old` and two `federation_club_venues_pre_dedup*` backup tables. The earlier 38-table restore baseline cannot be equated to either live inventory without timestamped manifest comparison.
- All **42/42 production public tables have RLS enabled** (none FORCE RLS). This is structural coverage only, not proof of safe grants, policies, roles or cross-account isolation. All **25/25 restore public tables have RLS enabled**.
- Live foreign keys: `opponents.federation_club_id -> federation_clubs`, `opponents.user_id -> auth.users`, `federation_club_competitions.club_id -> federation_clubs`, `federation_club_venues.club_id -> federation_clubs`. This confirms relational constraints, not semantic duplicate resolution.
- Gate 13 status remains BLOCKED: reconcile missing production tables and restore-only tables, then snapshot-consistent row/fingerprint, Auth and Storage validation. Never overwrite the isolated restore before preserving its current evidence.

## 2026-11-06 follow-up: opponent linkage, venue coordinates and RLS policies
- Production read-only counts: **92** federation clubs, **100** federation venue rows, **0/92** clubs with both nonblank `venue_lat` and `venue_lng`, **160** active opponents, **123/160** with `federation_club_id`, **37/160** unlinked, and **35** rows in `opponents_merge_plan_tmp`. Merge-plan rows are candidates, not verified safe merges; 100 venue records do not imply usable lat/lng.
- Federation clubs, competitions and venues have explicit `SELECT USING (true)` public policies. Opponents and team_alias_mappings have per-user `auth.uid() = user_id` policies for select/insert/update/delete. This is policy-expression evidence only; actual anonymous and cross-account tests remain outstanding.
- `opponents_merge_plan_tmp` has **zero RLS policies**, but table-level SELECT privileges are granted to anon and authenticated. Because RLS is enabled, these roles should be denied rows in normal access; verify through real API negative tests before declaring safe. `_gate5_staging` has zero policies and no SELECT grant to these roles. No production grants or policies changed.
- P0 next: verify public API cannot reveal merge-plan records, inspect opponent linking candidates and historical game references, prepare a deterministic no-write reconciliation report. P1 next: source verified venue coordinates, then stage updates on isolated environment only.

## 2026-11-06 opponent reconciliation diagnostics
- Production SELECT results: **123** linked active opponents reference **52 distinct** federation clubs; **37** active opponents remain unlinked. This is linkage coverage, not a deduplication result.
- The 35 `opponents_merge_plan_tmp` rows all report `group_size=1`, and their summed `game_count` is **103**. This temporary table therefore does **not** presently demonstrate duplicate groups suitable for merging. Treat any earlier claims of 35 confirmed duplicates as unverified.
- All **92** federation clubs have blank `venue_lat`, `venue_lng`, and `map_url` (each present count zero). Venue rows need separate verification before any weather remediation.
- Reproducible SELECT-only queries committed in `docs/audits/opponent_reconciliation_readonly.sql`. Next: inspect payload identities and game references with safe aggregate queries, then prepare account-scoped mapping candidates for human review, no automatic merges.

## 2026-11-06 follow-up: identity and game payload audit
- Read-only `opponents.payload` inspection: all 160 active records have `opponentName` and `opponentId`; 136 contain `ageGroup`, 10 contain `mapUrl`. These are per-opponent values; federation club catalogue has zero map URLs. Do not conflate the two sources.
- Exact case/whitespace-normalized opponent-name duplicates **within the same user_id**: **0 groups** among active records. This does not rule out aliases, age/series suffixes, different punctuation, or duplicate real-world clubs. The 35-row merge-plan is not evidence of duplicate groups.
- All **101 active games** contain an `opponent` payload key; only **2** contain `opponentMapUrl`. The game opponent field's value type and linkage semantics still require validation before any merge/repointing.
- Reproducible SELECT-only diagnostics committed at `docs/audits/opponent_identity_and_game_references_readonly.sql`. Next: inspect opponent reference value types and scoped linkage with aggregate queries, then create a non-destructive candidate alias review; never remove squad/competition distinctions or historical references.

## 2026-11-06 game-reference integrity acceptance
- Read-only live inspection: all **101** active games store `payload.opponent` as a JSON **string**; all **160** active opponents store `payload.opponentId` as a JSON **number**. These are not directly compatible stable foreign keys.
- Scoped join on `games.user_id = opponents.user_id` and exact `games.payload.opponent = opponents.payload.opponentName`: **101/101 uniquely resolved**, **0 unmatched**, **0 ambiguous**. Games currently refer to **32** distinct opponent names. This is a measured baseline, not proof future rename is safe.
- Added `docs/audits/opponent_game_reference_acceptance.sql` to verify that all game names remain uniquely resolvable before and after a proposed change. Any merge or rename must first specify game payload updates, backup, per-account mapping and rollback, and must be approved before production execution.
- A separate query using `homeAway='away'` returned zero; this is **not** a reliable away-fixture count until actual enum values are inspected. Do not supersede the earlier 50-away-fixture finding with this invalid assumption.

## 2026-11-06 alias and fixture direction validation
- Actual production `games.payload.homeAway` enum values are **'Home' (51)** and **'Away' (50)**, case sensitive. Earlier query using lowercase `'away'` returned a false zero. Any regression test must use the actual values.
- Production `team_alias_mappings` is a generic JSON payload sync table, with **1** active record. Its payload fields are `phase`, `competitionName`, `createdAt`, `seasonId`, `series`, `aliases`, `updatedAt`, `aliasId`, `competitionType`. There is **no** typed `federation_club_id` column in this table; do not mistake competition-scoped aliases for verified federation club identity mappings.
- **37** active opponents are still unlinked to the federation catalogue. Identity review must distinguish official club, squad label, age group, series, and actual separate clubs. Never infer a merge from punctuation, stripped age suffixes, or shared venue alone.
- Committed `docs/audits/opponent_alias_fixture_readonly.sql` for reproducible SELECT-only validation. Production unchanged.

## 2026-11-06 PR #38 code review and naming candidates
- PR #38 `index.html` patch implements Settings grouping with `opponentCatalogueDisplayKey`, but its explicit aliases cover only `Alta Lisboa/Alta de Lisboa` and `Atlético/Atlético CP`. It removes visible age/division badges, not arbitrary age/series substrings in `opponentName`. Its federation picker is **feature-flagged OFF** (`FEDERATION_CATALOGUE_PICKER_ENABLED = false`). Do not describe the picker as enabled or opponent cleanup as finished.
- Production aggregate: **0/160** active opponent names and **0/101** game opponent names match common age/series patterns tested; **56/160** opponent names match a possible squad-letter marker pattern. Regex candidate counts are not verified duplicate identities; preserve distinct A/B squads and distinct clubs.
- Added `docs/audits/opponent_name_suffix_candidates_readonly.sql`. Release blocker: expand alias coverage only with authoritative verified mappings and test both Settings and match history in browser before any deployment.

## 2026-11-06 concrete federation-link defect candidates
- Production `opponents` to `federation_clubs` read-only join shows `SL Olivais` (**1** row) and `SL Olivais 2014` (**1** row) both linked to the shared federation club `Olivais`. `Olivais "A"` and `Olivais "B"` each have **2** rows linked to `Olivais`, while `Olivais Sul` has **2** rows linked to its distinct `Olivais Sul` club. Cross-account repetition is not necessarily duplication.
- Federation catalogue contains exactly `Olivais` and `Olivais Sul` for name pattern `%Olivais%`; no exact `SL Olivais` or `SL Olivais 2014` federation record. The two SL links are **suspected identity errors**, not yet authorized or independently verified corrections. Do not merge or remap these by name alone.
- Committed `docs/audits/opponent_cross_club_link_review_readonly.sql` to reproduce candidate mapping evidence. Required remediation: confirm distinct official identities, create or match authoritative federation records as appropriate, repoint only affected account records with rollback, and verify all 101 game references still uniquely resolve.

## User-confirmed Olivais identity rule (2026-11-06)
- **Olivais Sul** is a distinct club and must NEVER be merged with or grouped under SL Olivais.
- **SL Olivais** is the parent club/group for **Olivais A** and **Olivais B**; preserve A and B as separate squads within that group, rather than independent clubs or collapsed squads.
- **SL Olivais 2014** identity relative to SL Olivais has not been explicitly confirmed; do not infer its mapping.
- Current production links SL Olivais and SL Olivais 2014 to the generic federation record Olivais. Remediation must respect the above rule and verify club identity before writing data. No production mutation authorized by this note.

## User-confirmed final SL Olivais identity mapping (2026-11-06)
- **SL Olivais**, **SL Olivais 2014**, **Olivais "A"**, and **Olivais "B"** belong to ONE SL Olivais club identity. A and B remain separate squad labels within that club, not separate clubs. The '2014' alias must not create an extra club.
- **Olivais Sul** is a completely separate club, never group or merge with SL Olivais.
- Settings > Opponents Database desired presentation: two club groups, SL Olivais and Olivais Sul, with underlying opponent records and game history retained. Do not assume federation club ID 'Olivais' represents the correct SL Olivais identity without validating the catalogue source.
