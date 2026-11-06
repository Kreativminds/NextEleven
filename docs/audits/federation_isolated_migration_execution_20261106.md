# Isolated federation link migration test, 2026-11-06

Environment: isolated Supabase project `tqpykeuuzcqudqtfrqmc`, **not production**. Its project root is a partial fixture database, not a full copy of production.

## Executed

1. Applied `20261106200000_game_opponent_federation_links.sql` successfully after correcting a malformed PostgreSQL dollar-quote delimiter in the development branch (commit `77702e9`).
2. Verified `game_opponent_federation_links`: zero rows, RLS enabled, one active identity validation trigger, one owner-read policy.
3. Attempted `20261106203000_backfill_verified_game_federation_links.sql`. **Expected fail-closed result:** `Federation link backfill blocked: 2 unmatched or ambiguous games`. The migration was not applied.
4. Read-only diagnosis: isolated fixtures `SLO Benfica` and `Olivais \"A\"` have no exact account-scoped opponent rows; `Direct Match FC` has exactly one. No production fixture was changed.

## Conclusion

Schema creation passes on the isolated project. The backfill correctly blocks incomplete fixture data, which is a successful negative test, **not a successful backfill test**. Production read-only audit separately showed 101/101 unique matches, 56 federation-linked, 45 pending. Re-run the full backfill and postmigration integrity audit on a faithful isolated copy of production before approval to deploy. Do not fabricate opponent matches in production or infer federation identities from names.

## Remaining verification

- Positive backfill and idempotent rerun on representative linked fixtures.
- Negative cross-account and mismatched federation-ID INSERT tests.
- RLS anonymous, owner and other-user permission matrix.
- Browser and sync tests.
