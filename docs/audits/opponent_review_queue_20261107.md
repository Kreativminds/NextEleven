# Opponent identity review queue (2026-11-07, final)

Scope: the open opponent names from Phase B, and the federation clubs without a 2026/27 Sub-14
registration in the three AFL PDFs (I, II and III Divisão, Sub-14, 2026/27).

Production status of this file: nothing here has been applied. Writes listed under section H
are prepared as pending migrations and need Victor's approval.

Evidence sources:
- AFL 2026/27 PDFs: I Divisão (Série 1), II Divisão (Séries 1 and 2), III Divisão (Séries 1 to 6).
- AFL 2024/25 documents (historical, used for identity only): `CD II DIV SUB 14 ATUALIZACAO`
  (afl.pt/wp-content/uploads/2024/10/CD-II-DIV-SUB-14-ATUALIZACAO.pdf) and
  `CD I DIV SUB 14 ATUALIZACAO` (afl.pt/wp-content/uploads/2024/10/CD-I-DIV-SUB-14-ATUALIZACAO.pdf).
- Production fixtures and opponents (read-only, 2026-11-07). Games store the opponent as a name
  string (`payload.opponent`), so fixture context uses exact name matches.

Confidence: High = official record and venue both match; Medium-high = name plus one corroborating
signal; Medium = name match only; Low = name match with a conflicting signal; None = no record.

## A. Confirmed by Victor, verified against records

| Stored name | Mapping | Evidence | Fixture context (production) | Confidence | Status |
|---|---|---|---|---|---|
| CAC (opp 20) | Cultural (220), club level | III Div. S3 "CULTURAL A" (220) and S4 "CULTURAL B" (220); venue Academia Jogador, Odivelas | 2 League games, season 2 (2024). Not linked; no 2026/27 fixture | Medium-high | Mapping prepared in 012. Not applied |
| Atlético CP (opp 610) | Atlético (145), club level | II Div. S2 "ATLÉTICO A" (145) and III Div. S4 "ATLÉTICO B" (145); both at CP Manuel Candeias Nº 2 / Estádio Tapadinha, Lisboa | 2 League games, season 2 (2024). Already linked to 145 in production. Two 2026/27 fixtures exist but are soft-deleted (status `to_confirm`) | Medium-high | Already in effect at opponent level. No change. The two soft-deleted 2026/27 fixtures are flagged for owner review, not restored |
| Sporting SAD FF (opp 43) | Sporting, SAD (1095), club level. Squad FF kept only as the original designation | 1095 is "SPORTING, SAD" in all three 2026/27 PDFs (squads A, B and C). No FF registration in any PDF. "FF" appears only for Benfica (III Div.) | 0 games under this exact name. Fixtures sit under the base name "Sporting" (opp 12, unlinked, 4 games in seasons 1 and 2) | Medium (club). No squad-level evidence | Mapping prepared in 012 with squad label FF in the alias payload. No competition row created |
| Musgueira (opp 39) | No link | No "Musgueira" record in any PDF or 2024/25 document. "ÁGUIAS MUSGUEIRA A (908)" was a separate club in the 2024/25 III Divisão | 0 games under this exact name | None | Kept unlinked. Victor's rule applies: not Águias |

## B. Resolved by the AFL documents (depends on migration 010 where noted)

| Stored name | Mapping | Evidence | Fixture context | Confidence | Status |
|---|---|---|---|---|---|
| Algés (opp 608) | Algés (1147), club level | I Div. 2026/27 "ALGÉS (1147)", Série 1, no squad; home venue 1891 Campo Dr Simões Alves | 1 active 2026/27 **Friendly** on 27 Sep 2026 (away, 0–11, Campo do Algés). I Div. programme also schedules Algés in a league match on 24/10/2026 (Sporting SAD A v Algés) | High (club) | Needs 010 first (club 1147 is not yet in production). Mapping prepared in 012, conditional on 1147 existing |
| Caneças "A" (opp 60) | Caneças (948), squad A | I Div. 2026/27 "CANEÇAS A (948)", Série 1. Previously recorded as "squad B only" | 0 games under this exact name. The 19 matches a naive substring search returned were false positives | High for squad A | Squad-letter conflict cleared. Mapping prepared in 012. Not applied |

Correction: the earlier queue said Algés was "different competition, friendly only". The I Divisão
PDF registers Algés in Sub-14 Série 1, so it is a catalogue club. Its one game is a friendly, which
does not change club identity.

## C. Stored squad letters: preserved

| Stored name | Federation record | Finding | Status |
|---|---|---|---|
| Carregado "A" / "B" | Carregado (53): one unlabelled registration (II Div. S1) | No squad A or B entries | Keep as-is |
| Casa Pia "C" (opp 48) | Casa Pia (180): squads A (I Div.) and B (II Div.) | No squad C. 29 games under the stored name | Keep as-is |

## D. Club-level matches (fixture context checked; squad letter preserved separately)

| Stored name | Mapping | Evidence | Fixture context | Confidence | Status |
|---|---|---|---|---|---|
| Mafra "A" (opp 765, 419) | CD Mafra (277), club level, squad A kept in the name | II Div. 2026/27 "CD MAFRA (277)", unlabelled. The 2024/25 II Div. lists "MAFRA A (277)", so squad A is a historical label on this club | 0 games under this exact name (both owners) | Medium-high | Mapping prepared in 012 for owner 563dea01. Owner 7f4a91b0 has no fixtures and is left unlinked |
| Tenente Valdez "A" (opp 67, 201) | Tenente Valdez (1669), club level, squad A kept in the name | III Div. 2026/27 "TENENTE VALDEZ (1669)", unlabelled. Parque Jogos CER Tenente Valdez, Paiã | 0 games under this exact name. Opp 748 "Tenente Valdez" is already linked to 1669 with 2 games in 2026/27 | Medium-high | Mapping prepared in 012 for owner 563dea01 |

## E. Not in the 2026/27 PDFs: open

| Stored name | Finding | Fixture context | Action | Status |
|---|---|---|---|---|
| Operário Lisboa (opp 16) | Not in 2026/27 PDFs, nor the 2024/25 I or II Divisão documents | 2 games in season 2 (2023 and 2024), unlinked | Keep unlinked. Find the AFL 2026/27 competition and ID from an official source | Open |
| Cadaval (opp 760) | Not in 2026/27 PDFs, nor 2024/25 I or II Divisão | 0 games under this exact name | Keep unlinked. Confirm competition from an official source | Open |
| Coutada (opp 2) | Not in 2026/27 PDFs, nor 2024/25 I or II Divisão | 0 games under this exact name | Keep unlinked | Open |
| Falcons (opp 27) | Not in 2026/27 PDFs, nor 2024/25 I or II Divisão | 2 games in season 1 (2022 and 2023), unlinked | Keep unlinked | Open |
| Vilafranquense 1957 (opp 780) | 2024/25 I Divisão lists "VILAFRANQUENSE (1165)", no squad. The stored name's "1957" suffix does not match that entry, and identity is not confirmed | 0 games under this exact name | Keep unlinked. Victor to confirm whether it is AFL 1165 | Open, candidate only |

## F. Eight federation clubs without a 2026/27 Sub-14 registration in the three PDFs

Not deleted. These are valid clubs and remain in the shared catalogue.

Águias Musgueira (908), Azambuja (590), Igreja Nova (2159), Lourinhanense (1081),
Montelavarenses (353), Salesianos Lisboa (5560), Sanjoanense (1002), Zambujalense (1216).

Several of these appear in the 2024/25 documents (for example, Azambuja, Igreja Nova,
Lourinhanense, Montelavarenses, Sanjoanense and Zambujalense in the II Divisão; Salesianos Lisboa
in the II Divisão Série IV; Águias Musgueira in the III Divisão). They may have moved division or
stopped fielding a Sub-14 team. Confirm with the 2026/27 AFL documents for those divisions.

**Correction to Phase B:** the "Águias da Musgueira" alias to club 908 was made on a candidate basis.
Club 908 has no 2026/27 Sub-14 registration in the supplied PDFs, and its venue claim is unconfirmed.
Treat it as low-confidence. It must not be used for "Musgueira".

## G. Counts

- Open names reviewed: 15 (27 rows).
- Confirmed by Victor and verified: CAC, Atlético CP (already in effect), Sporting SAD FF (club level), Musgueira (no link).
- Resolved by AFL documents: Algés (after 010), Caneças "A" (after 010).
- Club-level, squad preserved: Mafra "A", Tenente Valdez "A".
- Preserved squad letters: Carregado, Casa Pia "C".
- Open, not in any PDF checked: Operário Lisboa, Cadaval, Coutada, Falcons, Vilafranquense 1957 (candidate 1165).

## H. Production writes, prepared and not applied

1. Migration 010: 2 clubs (Algés 1147, Sintrense 1041), 16 I Divisão competition rows, 5 venues. Rollback alongside. Tested in isolation.
2. Migration 012: 6 alias rows and 6 opponent links (CAC→220, Sporting SAD FF→1095, Mafra "A"→277, Tenente Valdez "A"→1669, Caneças "A"→948, Algés→1147 after 010). Rollback alongside. Tested in isolation. Note: the link update must run in the owner session because of `prevent_unreviewed_opponent_deletion`; the migration sets this for the transaction only.
3. Migration 011: roadmap status for FED-001..FED-004 and blocked FED-005. Rollback alongside. Tested in isolation.
4. Migration 20261107050000 (addition creation): tested in isolation. Not applied to production.

## I. Linked-count reconciliation (2026-11-07)

Measures, read in production today:
- Opponents linked to a federation club, active: 131 (`opponents.federation_club_id`).
- Game-level links: 56 (`game_opponent_federation_links`), matching FED-01 in the tracker.
- Dangling references: 0.

The 131 are all from writes on or before 2026-11-06 19:23 UTC (38 rows share that timestamp). No
opponent row was written today. The nine alias rows created today at 10:31 UTC do not change
`federation_club_id`. The earlier figure of 123 cannot be reproduced from any state change. The most
likely cause is that it was counted with a different filter or from an earlier snapshot. Because no
data changed, the figure in earlier notes should be treated as superseded by 131.
