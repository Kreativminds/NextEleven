# Gate 13: sequence state and safe recovery policy

Read-only inspection on 2026-11-06:

| Sequence | Production last_value | Isolated restore last_value | Related maximum row value |
|---|---:|---:|---|
| portal_change_log_sequence_seq | 3784 | 3741 | Isolated restore includes synthetic sequence 999999999 |
| profiles_account_number_seq | 3 | NULL (never called) | Account number maximum 3 in both environments |

Both sequences are ascending, non-cycling, increment 1, cache 1. The audit-log synthetic high key means blindly setting sequence to MAX(sequence) would jump to 1,000,000,000 and obscure recovery tests. Conversely, leaving it at 3741 is not sufficient evidence of correct next-value behavior. Account-number sequence needs a controlled next-value rehearsal, because its `last_value` is NULL even though existing profiles reach 3.

Recommended fresh isolated rehearsal: load a clean snapshot, identify synthetic rows separately, validate sequence ownership and next-value collision-free behavior inside a rollback-only test transaction where possible. Do not call nextval on production. Do not remove test rows without explicit approval.

Gate 13 OPEN; no production modifications.
