# PR #35 and #36 ancestry verification (2026-11-06)

GitHub compare against `main`:

- PR #35 head (`refs/pull/35/head`) is **behind main by 8 commits and ahead by 0**. Its head commit is already an ancestor of main. This verifies Git history inclusion, not necessarily current deployment or runtime behavior.
- PR #36 head (`refs/pull/36/head`) is **diverged, ahead 1 and behind 7**, with one changed file: `index.html` (+24, -0). The extra commit is not included in main and must be reviewed/rebased before any merge. The connector returned an empty content body when fetching large `index.html`, so source-level verification of that change is still outstanding.
- Production public RPC already includes opponent coordinate keys, but all 160 active opponents have no `venueLat` / `venueLng` keys. This does not establish whether UI coordinates can be saved now, and does not justify reapplying a redundant RPC migration.

Next: inspect PR #36's 24-line diff through a reliable source, validate its current test coverage, and independently test coordinate save/sync. Do not merge or deploy without explicit approval.
