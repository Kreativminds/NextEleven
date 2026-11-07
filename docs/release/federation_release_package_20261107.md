# Federation release package (2026-11-07)

Status: **prepared, not approved, not deployed.**
Candidate: draft PR #42, branch `feature/federation-release-consolidated-20261107`, HEAD recorded in the PR.
Picker flag: `FEDERATION_CATALOGUE_PICKER_ENABLED = false`. Stays false in this package.

## 1. Verdict

| Decision | Verdict | Reason |
|---|---|---|
| Merge PR #42 to main | **NO-GO** | Needs approval. Authenticated real-session tests not run. CI on PR #42 not yet confirmed |
| Apply migrations to production | **NO-GO** until backup is confirmed and each step is approved | No production write made in this pass. Owner backup not verified in this pass |
| Enable the picker flag | **NO-GO** | Authenticated browser and API tests not run; sandbox cannot reach `*.supabase.co` |
| Accept the package for review | **GO** | Local suites pass on the candidate; isolated tests pass; every production step has a tested rollback (except 20261107050000, see section 6) |

## 2. Contents

| Item | Type | Production status | Tested in isolation |
|---|---|---|---|
| `supabase/migrations/20261107050000_opponent_addition_creation.sql` | Additive function and 2 columns | **Not applied** | Yes (role matrix). Rollback test not completed (see section 6) |
| `supabase/migrations_pending/010_add_i_divisao_federation_catalogue_2026_27.sql` | Additive: 2 clubs, 16 competition rows, 5 venues | Not applied | Yes: apply +2/+16/+4 venues (Oriental 1945 already in isolated), re-run no-op, rollback to baseline |
| `supabase/migrations_pending/011_roadmap_federation_status_20261107.sql` | Update 4 roadmap rows, insert FED-005 (internal) | Not applied | Yes: apply, assertions, idempotency, rollback restore |
| `supabase/migrations_pending/012_federation_alias_links_20261107.sql` | 6 alias rows, 6 opponent links (owner 563dea01) | Not applied | Yes, with Algés skipped (no 1147). Found and fixed a trigger blocker (owner session needed) |
| Rollback files for 010, 011, 012 and 20261107050000 | Reverse steps | n/a | 010 and 011 tested. 012 and 20261107050000 **not tested** |
| Code: picker, addition creation UI, inbox | Client code | Shipped to branch only | Browser and regression suites pass (section 3) |

## 3. Test evidence (this candidate)

Run directly in this session:

- `tests/regression_*.js` (12 files) and `tests/browser_*.js` (4 files): 16 files, **0 failures**.
  Includes `regression_federation_picker_release`, `regression_federation_match_save_contract`,
  `regression_opponent_review_inbox`, `regression_opponents_settings`, `regression_season_calendar` (52 passed), and the gate suites.
- `tests/browser_*.js` (Chromium, synthetic): `browser_federation_picker`, `browser_federation_picker_mobile_synthetic`
  (390x844 touch, synthetic), `browser_opponent_approval`, `browser_opponent_review_inbox`. All pass.
- Inline scripts in `index.html` parse (3 of 3).
- `tests/federation_picker_authenticated_api.js`: **skipped** (exit 2). Needs `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `TEST_USER_JWT`.

Isolated project (`tqpykeuuzcqudqtfrqmc`), rollback-only, all pass:

- Link RLS matrix: no mutation grants for `authenticated`. Owner sees 2 links; other user sees 0.
- Non-admin review RLS: no admin membership or cross-account request leak.
- Anonymous boundary: no reads or mutations on private review tables; public share contract intact.
- Invalid share token: null, empty and invalid tokens return 0 rows.
- Addition local role matrix: requester impersonation and forged approval blocked; admin local classification works; requester sees result; no false federation link.
- Alias write denial: authenticated cannot write reviewed aliases; cross-owner alias read and resolve blocked.

Not run: authenticated real-session HTTP and browser tests (network). Of the 46 SQL fixtures in `tests/sql/`,
only the six isolated security fixtures listed above were re-run in this pass. The other read-only and isolated fixtures were not.

## 4. Production baseline (read-only, 2026-11-07, before any write in this pass)

Expected values for the preflight. Any difference stops the release.

| Measure | Expected |
|---|---|
| Active games | 101 |
| Active games, season 6 (2026/27) | 27 |
| Soft-deleted games, season 6 | 81 (pre-existing; do not touch) |
| Active game_players | 250 |
| Active opponents | 160 |
| Soft-deleted opponents | 89 |
| Active opponents linked to a federation club | 131 |
| game_opponent_federation_links | 56 |
| Active team_alias_mappings | 10 |
| federation_clubs | 92 |
| federation_club_competitions | 109 (I Divisão: 0) |
| federation_club_venues | 100 |
| opponent_addition_requests | 0 |
| opponent_deletion_requests | 0 |
| roadmap_items | 134 |
| `complete_approved_opponent_addition` defined | 0 |
| Dangling `federation_club_id` references | 0 |

Preflight SQL (read-only, run before each step):

```sql
select
 (select count(*) from public.games where deleted_at is null) games_active,
 (select count(*) from public.games where deleted_at is null and payload->>'seasonId'='6') games_s6_active,
 (select count(*) from public.games where deleted_at is not null and payload->>'seasonId'='6') games_s6_deleted,
 (select count(*) from public.game_players where deleted_at is null) gp_active,
 (select count(*) from public.opponents where deleted_at is null) opp_active,
 (select count(*) from public.opponents where deleted_at is not null) opp_deleted,
 (select count(*) from public.opponents where deleted_at is null and federation_club_id is not null) opp_linked,
 (select count(*) from public.game_opponent_federation_links) game_links,
 (select count(*) from public.team_alias_mappings where deleted_at is null) aliases,
 (select count(*) from public.federation_clubs) fed_clubs,
 (select count(*) from public.federation_club_competitions) fed_comps,
 (select count(*) from public.federation_club_venues) fed_venues,
 (select count(*) from public.opponent_addition_requests) add_req,
 (select count(*) from public.opponent_deletion_requests) del_req,
 (select count(*) from public.roadmap_items) roadmap_rows,
 (select count(*) from pg_proc where proname='complete_approved_opponent_addition') addition_fn,
 (select count(*) from public.opponents o where o.federation_club_id is not null
   and not exists (select 1 from public.federation_clubs c where c.id=o.federation_club_id)) dangling;
```

## 5. Ordered production sequence (each step needs its own approval)

0. **Backup.** Owner confirms a fresh logical backup of `wicydcvdakqopodbxtrl` exists and records its timestamp. Not verified in this pass.
1. **Preflight.** Run the query in section 4. Stop on any difference.
2. **20261107050000** (addition creation). Apply the migration as written. Verify `addition_fn = 1`.
3. **010** (I Divisão catalogue). Apply. Expected after: `fed_clubs` 94, `fed_comps` 125, `fed_venues` 105. Postflight inside the file enforces 16 I Divisão rows and 5 venues.
4. **011** (roadmap status). Apply. Expected: `roadmap_rows` 135 (FED-005 added). `is_visible_to_users` unchanged.
5. **012** (alias links). Apply after step 3, because Algés needs club 1147. Expected after: `aliases` 16, `opp_linked` 137, `game_links` 56 (unchanged). Runs in the owner session for the trigger.
6. **Postflight.** Re-run section 4. Expected changes only: `fed_clubs` +2, `fed_comps` +16, `fed_venues` +5, `aliases` +6, `opp_linked` +6, `roadmap_rows` +1, `addition_fn` 1. All game, game_players, game_links and season-6 counts must equal the baseline.
7. **Flag.** Stays `false`. Enabling it is a separate approval, after the authenticated tests in section 7 pass.

Schema changes from step 2 to 5 run in one maintenance window in this order. Do not run step 5 without step 3.

## 6. Rollback (reverse order)

| Step | Rollback file | Refuses when | Expected after rollback |
|---|---|---|---|
| 5 | `012_..._rollback.sql` | never (clears only the six links it set) | `aliases` 10, `opp_linked` 131 |
| 4 | `011_..._rollback.sql` | never (restores from backup table) | `roadmap_rows` 134 |
| 3 | `010_..._rollback.sql` | any opponent links to 1147 or 1041 | `fed_clubs` 92, `fed_comps` 109, `fed_venues` 100 |
| 2 | `20261107050000_opponent_addition_creation_rollback.sql` | any opponent created by an approved addition | `addition_fn` 0 |

Rollbacks for **012** and **20261107050000** are **not tested**. The 20261107050000 test call timed out (section 9).
Both must be tested in isolation before they are relied on. Rollbacks for 010 and 011 were tested in isolation.

Notes:
- Rollbacks 010, 011 and 012 use only identifying markers (`Migration 010.` in venue notes, `release-%` alias ids,
  the 011 backup table). Pre-existing rows are not touched.
- Rollback 012 uses the owner session for the same trigger reason as the forward migration.

## 7. Authenticated tests required before the picker flag is enabled

1. Create or use a signed-in test user on a non-production project, or use read-only production with approval.
2. `SUPABASE_URL=… SUPABASE_ANON_KEY=… TEST_USER_JWT=… node tests/federation_picker_authenticated_api.js` → expect PASS.
3. Authenticated browser pass of the picker in Chromium and on a real Android device (not synthetic). Steps:
   open the add-game form → type a federation name → confirm suggestions show distinct clubs (Olivais and Olivais Sul separate) → save → reload → confirm the link persists.
4. Flag enablement is then a separate approval.

## 8. Open items and risks (not blockers for accepting the package)

- 81 soft-deleted season-6 game rows and 2 soft-deleted Atlético CP 2026/27 fixtures (`to_confirm`) predate this pass. Owner review before any cleanup. Not restored.
- Opponent `Vilafranquense 1957`: candidate AFL 1165 (2024/25) not confirmed. Unlinked.
- Operário Lisboa, Cadaval, Coutada and Falcons: no AFL record found in the 2026/27 PDFs or 2024/25 I and II Divisão documents. Unlinked.
- Musgueira: no record. Stays unlinked. `Águias da Musgueira` → 908 remains low-confidence.
- Sporting SAD FF: club-level only. No FF registration exists in any PDF.
- Linked-count figures: 131 is current. The earlier 123 is superseded (see review queue, section I).
- Victor's approval applies to package inclusion of migration 20261107050000, not to deployment.

## 9. Status update (second pass, 2026-11-07 13:30 Lisbon)

Verified in this pass:
- **CI on PR #42 HEAD `1fe3e7f`:** workflow "Federation picker regression", run `42368287691`, **success**. It runs the four node regression scripts and three browser suites in Chromium, and checks that the SQL fixtures and migrations exist (`test -s`). It does **not** execute the SQL fixtures against a database.
- **PR containment:** PR #38 head `6a09c6b` and PR #41 head `8383cc7` are both ancestors of `1fe3e7f`. Remote heads confirmed with `git ls-remote`.
- **Flag:** `FEDERATION_CATALOGUE_PICKER_ENABLED = false` on the head. With the flag off, the picker returns no catalogue suggestions (`federationOpponentSuggestions`).
- **Local suites on the head:** 16 regression and browser files, 0 failures.
- **Authenticated API check:** exits 2 (skipped). Missing `TEST_USER_JWT` only. `SUPABASE_URL` and the anon key are public client config in `index.html` (`https://wicydcvdakqopodbxtrl.supabase.co`), so they can be used as-is.

Not verified in this pass:
- **Rollback for 20261107050000:** test call timed out. The server reported a pending question and got no answer. The likely reason is confirmation for `DROP` statements. The isolated state after the timeout is unknown until checked.
- **Rollback for 012:** not run. It uses only `UPDATE` and `DELETE`, so it is not expected to need confirmation.
- **Backup:** not verifiable from this environment. See section 10.
- **Authenticated tests:** no test credentials available.

## 10. Blockers

1. **Recoverable production backup not verified.** No backup artifact, timestamp or restore instructions are identified in the repo. `docs/MIGRATION_COMPLETION_TRACKER.md` refers to a Gate 13 restore test with a 38/38 match, but names no artifact or timestamp. DR-02 records earlier count and fingerprint mismatches, and DR-03 and DR-04 are open. Owner must confirm a point-in-time backup of `wicydcvdakqopodbxtrl` and provide the restore procedure. A targeted logical export of the affected tables is also prepared as a fallback (section 11).
2. **Authenticated picker tests not run.** Need a `TEST_USER_JWT` for a test account on a non-production project, or owner-approved read-only use of a production account.
3. **Rollback for 20261107050000 not tested.** Requires answering the Supabase server's pending confirmation (isolated project only).
4. **Rollback for 012 not tested.**
5. **Owner approval** for each production step in section 5.

## 12. Approvals requested

- [ ] Accept this package for review (section 1).
- [ ] Approve step 0 (backup confirmation) and step 1 (preflight).
- [ ] Approve steps 2 to 5, individually or as one window.
- [ ] Approve the rollback test for 20261107050000 in isolation.
- [ ] Decide whether PR #41 and PR #38 close once PR #42 is approved (both remain open now).

## 11. Targeted recovery export (read-only, fallback until a full backup is confirmed)

This does not replace a full point-in-time backup. It captures the rows the release can change, so a
release can be checked and reversed against known values. Run it read-only before step 2. Store the output
outside the repo, with a checksum.

```sql
-- Read-only. Writes nothing. Copy the result to a dated file and record its sha256.
select jsonb_build_object(
  'captured_at', now(),
  'games', (select jsonb_agg(to_jsonb(g) order by g.id) from public.games g),
  'game_players', (select jsonb_agg(to_jsonb(p) order by p.id) from public.game_players p),
  'opponents', (select jsonb_agg(to_jsonb(o) order by o.id) from public.opponents o),
  'game_opponent_federation_links', (select jsonb_agg(to_jsonb(l)) from public.game_opponent_federation_links l),
  'team_alias_mappings', (select jsonb_agg(to_jsonb(t) order by t.id) from public.team_alias_mappings t),
  'federation_clubs', (select jsonb_agg(to_jsonb(c) order by c.id) from public.federation_clubs c),
  'federation_club_competitions', (select jsonb_agg(to_jsonb(x) order by x.id) from public.federation_club_competitions x),
  'federation_club_venues', (select jsonb_agg(to_jsonb(v) order by v.id) from public.federation_club_venues v),
  'roadmap_items', (select jsonb_agg(to_jsonb(r) order by r.id) from public.roadmap_items r),
  'opponent_addition_requests', (select jsonb_agg(to_jsonb(a)) from public.opponent_addition_requests a),
  'opponent_deletion_requests', (select jsonb_agg(to_jsonb(d)) from public.opponent_deletion_requests d)
);
```

Restore check after any rollback: re-run the section 4 preflight and compare each row count and the
sha256 of each table's JSON, ordered by id, against this export. Rows changed by a migration are expected
only in the columns listed in its rollback file.
