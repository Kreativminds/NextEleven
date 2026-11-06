# Away weather: additional frontend gap

Read-only GitHub inspection on 2026-11-06 shows `team.html` on the default branch reads `next.opponentLat` / `next.opponentLng`, while `index.html` on that same branch contains **zero references** to `venueLat` or `venueLng`. This is consistent with production having zero active opponents with those fields. The QA log references a separate PR #35 for adding coordinate-entry UI, but its merge/deployment status has not yet been independently verified. Do not assume that functionality is present on the default branch or in production.

Follow-up release dependency: reconcile PR #35 and #36, validate opponent coordinate entry and persistence, then test the already-updated production RPC in an isolated environment. Do not reapply the redundant RPC migration.
