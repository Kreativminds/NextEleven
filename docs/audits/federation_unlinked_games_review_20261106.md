# Federation reconciliation: unresolved game-linked opponents

Read-only production inspection, 6 November 2026. No fixture or opponent records modified.

## Verified totals
- 101 active games, all with exactly one account-scoped opponent-name match.
- 56 game references have a federation_club_id.
- 45 game references lack federation_club_id, covering 14 names.
- 16 account-scoped federation duplicate groups, 22 redundant opponent rows.

## Names requiring identity review
| Historical name | Games | Possible federation catalogue match | Action |
|---|---:|---|---|
| Alta de Lisboa | 6 | Alta Lisboa | Confirm official club ID |
| Águias da Musgueira | 4 | Águias Musgueira | Confirm official club ID |
| Águias de Camarate | 4 | No confident match | Federation check, may be distinct club |
| Casa Pia AC | 4 | Casa Pia | Confirm official club ID |
| Desportivo O. Moscavide | 4 | No confident match | Federation check |
| EF Belém Estádio Restelo | 4 | EF Belém | Confirm club identity versus venue label |
| FC Alverca | 4 | No confident match | Federation check |
| Sporting | 4 | Sporting, SAD | Confirm legal/competition identity |
| Atlético CP | 2 | Atlético | Confirm official club ID |
| CAC | 2 | Ambiguous, NOT Cacém by assumption | Manual verification required |
| Colégio Pedro Arrupe | 2 | No confident match | Local-team classification if applicable |
| Falcons | 2 | No confident match | Local-team classification if applicable |
| Operário Lisboa | 2 | No confident match | Federation check |
| Algés | 1 | No confident match | Federation check |

**Important:** Similar names are candidates only. Do not automatically merge, rename, delete or link any of these records. In particular, CAC must not be equated with Cacém. A local-team classification is not a federation club ID.

## Safe completion gates
1. Verify the federation club ID for each proposed match against authoritative federation registrations. Record evidence and flag genuinely local teams separately.
2. Recheck per-account name uniqueness and 2026/27 season fingerprints immediately before writes.
3. Populate persistent game links only for verified exact opponent rows; use an idempotent reviewed migration and verify game counts and original names.
4. Consolidate account-specific duplicate opponent records only after verifying all game, player and calendar references and having a complete recovery backup.
5. Update Admin > Roadmap with unresolved identity checks, club addition and deletion review, requester notification and decision feedback.

Status: reconciliation research, **not production cleanup completion**.
