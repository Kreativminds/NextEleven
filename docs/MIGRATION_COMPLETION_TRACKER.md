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
