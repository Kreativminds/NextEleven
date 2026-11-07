# Opponent identity review queue (2026-11-07)

Scope: the 27 ambiguous opponent rows (15 names) left unlinked by Phase B, and the
federation clubs without a 2026/27 Sub-14 registration in the three AFL PDFs
(I, II and III Divisão, Sub-14, 2026/27).

Status of this file: nothing here is applied to production. No opponent has been deleted,
merged or relinked. Production writes need Victor's approval.

Evidence sources:
- AFL PDFs: I Divisão (Série 1), II Divisão (Séries 1 and 2), III Divisão (Séries 1 to 6).
- Production (`wicydcvdakqopodbxtrl`), read-only: 92 clubs, 109 competitions, 100 venues, no I Divisão rows.
- Migration `010_add_i_divisao_federation_catalogue_2026_27` (in `supabase/migrations_pending/`): not applied.

Confidence scale: High = federation record and venue match; Medium = name match with one
corroborating signal; Low = name match only; None = no federation record found.

## A. Identity confirmed by Victor

| Stored name | Confirmed identity | Federation record in PDFs | Proposed mapping | Confidence | Action | Status |
|---|---|---|---|---|---|---|
| CAC | Clube Atlético e Cultural | "CULTURAL" 220: III Div. S3 (squad A) and S4 (squad B); venue Academia Jogador, Odivelas | Club 220, club level, no squad | Medium-high | Admin approves additive alias (`opponent_federation_alias`) | Ready to prepare; not applied |
| Atlético CP | Atlético Clube de Portugal | "ATLÉTICO" 145: II Div. S2 (squad A), III Div. S4 (squad B). Home venue: CP Manuel Candeias Nº 2 / Estádio Tapadinha, Lisboa (both squads) | Club 145, club level | Medium-high. Name and Tapadinha venue match. The federation record does not name the official club | Admin confirms 145 is this club's youth structure before alias | Needs confirmation |
| Musgueira | Musgueira (not Águias da Musgueira) | None. No "Musgueira" in any PDF | No link | None | Keep unlinked. Do not link to 908 | Open: no catalogue entry |
| Sporting SAD FF | Sporting SAD (FF squad) | "SPORTING, SAD" 1095 in all three PDFs, squads A (I), B (II), C (III). **No FF squad** | Club 1095 at club level only; squad FF not linkable | Medium (club). FF squad: no evidence | Admin decides: club-level link, or keep unlinked until an FF registration is confirmed | Needs decision |
| Operário Lisboa | Operário Lisboa | None | No link. AFL ID not verified. Do not invent | None | Confirm competition and AFL ID from an official source | Open |

## B. Resolved by the I Divisão PDF (depends on migration 010)

| Stored name | Resolution | Evidence | Confidence | Action | Status |
|---|---|---|---|---|---|
| Caneças "A" | Club 948, squad A | I Div. "CANEÇAS A" (948), Série 1. Previously "squad B only" | High for squad A | Squad-letter conflict cleared once 010 is applied. Keep stored name as-is | Ready after 010 |
| Algés | Club 1147, club level | I Div. "ALGÉS" (1147), Série 1, no squad. Venue 1891 Campo Dr Simões Alves | High (club). The stored name's competition was "Friendly" only, which does not change club identity | Link to 1147 after 010. Victor to confirm the stored game is a club game, not a different team | Ready after 010 + confirmation |

Correction to the earlier version of this file: Algés was previously listed as "different competition, local or friendly-only". The I Divisão PDF shows Algés registered in Sub-14 Série 1. Under the rule that clubs are not treated as local because they are absent from a PDF, Algés is a catalogue club.

## C. Stored squad letters: preserved, no change

| Stored name | Federation record | Finding | Status |
|---|---|---|---|
| Caneças "A" | See section B | Resolved by I Div. | Ready after 010 |
| Carregado "A" / "B" | Carregado (53): one unlabelled registration (II Div. S1) | No squad A or B entries | Keep as-is |
| Casa Pia "C" | Casa Pia (180): squads A (I Div.) and B (II Div.) | No squad C | Keep as-is |
| Mafra "A" | CD Mafra (277): one unlabelled registration (II Div. S1) | No separate squad A entry | Keep as-is; see D |
| Tenente Valdez "A" | Tenente Valdez (1669): one unlabelled registration (III Div.) | No separate squad A entry | Keep as-is; see D |

## D. Probable club-level matches (need confirmation)

| Stored name | Proposed | Evidence | Confidence | Action | Status |
|---|---|---|---|---|---|
| Mafra "A" | Club 277, club level | Only federation Mafra in the PDFs | Medium | Confirm the stored squad letter is not a separate team | Needs confirmation |
| Tenente Valdez "A" | Club 1669, club level | Only federation Tenente Valdez in the PDFs | Medium | Same as above | Needs confirmation |

## E. Not in the three PDFs: no catalogue entry, no link

| Stored name | Finding | Action | Status |
|---|---|---|---|
| Cadaval | No federation record in any PDF | Confirm competition and age group. Likely local or outside the catalogue | Open |
| Coutada | No federation record in any PDF | Same | Open |
| Falcons | No federation record in any PDF | Same | Open |
| Vilafranquense 1957 | No federation record in any PDF | Confirm whether a Sub-14 team exists in another competition | Open |

## F. Eight federation clubs without a 2026/27 Sub-14 registration in the three PDFs

Not deleted. These are valid clubs and remain in the shared catalogue.

Águias Musgueira (908), Azambuja (590), Igreja Nova (2159), Lourinhanense (1081),
Montelavarenses (353), Salesianos Lisboa (5560), Sanjoanense (1002), Zambujalense (1216).

Open question: they may belong to another division, age group or season not covered by the
three PDFs. Needs the relevant AFL documents.

**Correction to Phase B:** the "Águias da Musgueira" alias to club 908 was made on a candidate
basis. Club 908 has no 2026/27 Sub-14 registration in the supplied PDFs, and its venue claim is
marked unconfirmed. Treat that alias as low-confidence until confirmed. It must not be used for "Musgueira".

## G. Counts

- 27 rows / 15 names reviewed.
- Identity confirmed by Victor: 5 names (CAC, Atlético CP, Musgueira, Sporting SAD FF, Operário Lisboa).
- Resolved by the I Divisão PDF, after migration 010: 2 names (Caneças "A", Algés).
- Squad-letter conflicts preserved, no change: 4 names (Carregado, Casa Pia C, Mafra, Tenente Valdez).
- Not in the PDFs, open: 4 names (Cadaval, Coutada, Falcons, Vilafranquense 1957).
- Open decisions for Victor: Sporting SAD FF squad, Atlético CP confirmation, Musgueira (no record), Mafra and Tenente Valdez confirmation, Algés confirmation.

## H. Production items that need approval (not applied)

1. Migration 010 (additive): 2 clubs (Algés 1147, Sintrense 1041), 16 I Divisão competition rows, 5 venues (Oriental 1945 is already present in the isolated project, not in production). Rollback file alongside it.
2. Alias inserts for CAC→220 and Atlético CP→145, after Victor confirms (section A).
3. Algés→1147 alias, after section B confirmation.
4. Sporting SAD FF→1095: club level only, after decision.

## I. Linked-count discrepancy (open)

Production shows 131 opponents linked to a federation club (active and incl. deleted), against 123 in earlier notes.
Last write to a linked row: 2026-11-06 19:23 UTC. No production writes made in this pass.
The 123 query could not be reproduced from the notes. Needs reconciliation before release.
