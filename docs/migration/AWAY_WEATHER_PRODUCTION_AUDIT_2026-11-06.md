# Away-match weather: production read-only verification (2026-11-06)

## Findings

The open issue in `BUGS.md` claims the public RPC does not return opponent coordinates. **That diagnosis is now stale.** Direct read-only inspection of the live production `public.get_public_team_data(p_token text)` definition shows both `opponentLat` and `opponentLng` in the `games` JSON, sourced from `public.opponents.payload.venueLat` and `venueLng`, respectively. The function also emits `opponentMapUrl`.

The missing weather forecast is still unresolved, but the observed blocker is **missing coordinate data**, not missing JSON fields:

| Production read-only check | Result |
|---|---:|
| Active games with `homeAway = 'Away'` | 50 |
| Away games with matching active opponent name | 50 |
| Away games with matched opponent latitude AND longitude | 0 |
| Active opponents | 160 |
| Active opponents with `venueLat` | 0 |
| Active opponents with `venueLng` | 0 |
| Active opponents with `mapUrl` | 10 |

Queries used exact case `Away`, not `away`; the latter incorrectly returns zero. Opponent matching used the same case-insensitive name and user ID predicate as the RPC. These are counts, not exposure of private row data.

## Implications

- **Do not create or deploy a migration 010 merely to add the two fields.** They already exist in the live RPC. Replacing the full SECURITY DEFINER function from a stale SQL file could silently revert later fixes.
- Investigate why the admin opponent venue coordinate fields are empty (including the feature branch and PR #35), then implement a safe admin UX for capture and validation of opponent venue coordinates.
- Populate existing opponent coordinates only from verified venue locations, with user approval for production data updates; do not guess coordinates from club names.
- After approved data remediation, test an away fixture through the real public token RPC and the browser forecast, including missing-coordinates graceful fallback.
- Update the open BUGS.md entry only after fixing and verifying the full feature, or amend its root cause on a separate reviewable PR.

No production writes were performed. This is a **verified diagnosis**, not a claim that away weather is fixed.
