# Away-weather frontend status: verification pending

Correction 2026-11-06: the GitHub connector returned `index.html` with an empty content body, despite a valid blob SHA. The prior claim that the default branch contains zero `venueLat` / `venueLng` references was therefore unsupported and is withdrawn. Do not infer that coordinate-entry UI is absent or that PR #35 is unmerged based on this response.

Verified facts: production `get_public_team_data` includes `opponentLat` and `opponentLng`; all 160 active opponent records lack `venueLat` / `venueLng` keys. Next steps: fetch `index.html` via a reliable source or smaller retrieval mechanism, inspect PR #35/#36 merge status, and test the opponent coordinate save/sync flow. No production changes.
