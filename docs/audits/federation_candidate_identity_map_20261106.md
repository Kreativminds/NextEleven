# Federation club candidate reconciliation, 2026-11-06

Read-only catalogue cross-reference. These are **candidates**, not confirmed official identity links. Do not update opponent rows or game references until federation registration evidence is verified.

| Historical game name | Catalogue name | Federation club UUID | Decision |
|---|---|---|---|
| Alta de Lisboa | Alta Lisboa | 52eb7785-faa9-4812-be9e-e596edbd1f69 | Verify |
| Águias da Musgueira | Águias Musgueira | e37bcc5c-5b02-46b4-b8cb-691a388bcea8 | Verify |
| Atlético CP | Atlético | dcaa7afc-2ed6-4e68-87e7-5bc4ca7df871 | Verify |
| Casa Pia AC | Casa Pia | 27acec85-66fd-4fa6-9efd-6b670b939ab2 | Verify |
| Desportivo O. Moscavide | Desp. O. Moscavide | dc0c6d10-f449-48a3-9592-1aff825db3b6 | Verify |
| EF Belém Estádio Restelo | EF Belém | 4bca633e-6cdc-406d-8483-08854da541a8 | Verify club identity vs venue |
| FC Alverca | Alverca | d34d7791-a873-4bd6-a266-514cfe2471bb | Verify |
| Sporting | Sporting, SAD | ddbe33b5-6215-45ff-962a-31529229b755 | Verify |
| Águias de Camarate | Camarate | 33d78f92-582c-4a2c-8cc4-1947e7313713 | Distinct name, manual verification only |
| CAC | Cultural / Cacém | none | Ambiguous, do not link by abbreviation |
| Algés | none found | none | Check federation |
| Colégio Pedro Arrupe | none found | none | Check local team |
| Falcons | none found | none | Check local team |
| Operário Lisboa | none found | none | Check federation |

Olivais = 2048d15c-37b2-4d9b-8be6-c063dc57378d. Olivais Sul = 461ac75e-a34c-46f9-8b45-8e4d982ca559. These **must never merge**.

Next: validate each candidate against official federation team registration and competition, then perform a transactionally guarded backfill with complete backup and active-season regression checks. No production data changed by this audit.

## Competition cross-check, 2026/27 Sub-14 III Divisão Série 3

13 registered club squads: 3F, AD Pastéis, Alta Lisboa (B), CF Estrela (B), Cultural (A), Damaiense (B), Desp. O. Moscavide (B), Olivais (B), Oriental (B), Palmense, Sacavenense (B), Santa Maria (B), Tenente Valdez.

This competition evidence supports Alta Lisboa B and Desp. O. Moscavide B as registered entries, but does **not** alone establish that every historical alias is that same registered squad. The club catalogue must display a single Olivais entry, with squad B retained only in the competition registration. Olivais Sul is a separate federation club and is not in this series list.
