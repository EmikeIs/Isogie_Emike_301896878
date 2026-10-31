# Portfolio 3 — Transactions and Concurrency

I used a temporary counter (p3_processed_count) on trip, record {"trip_id":4}, to compare transaction behaviour without changing the original business fields. The helper is used only for this exercise.

## Commit and rollback

| Stage | Counter |
| --- | --- |
| Before COMMIT | 0 |
| Uncommitted change | 1 |
| Other session before COMMIT | 0 |
| After COMMIT | 1 |
| After ROLLBACK | 1 |

The CHECK error (23514) aborted the second transaction. ROLLBACK restored the earlier committed value. READ COMMITTED kept the uncommitted change hidden from the other session.

## Two-session comparison

| Method | Result | Expected |
| --- | --- | --- |
| Read, calculate and write | 2 | 3 |
| SELECT FOR UPDATE | 3 | 3 |

Both sessions first read 1. Without locking, both wrote 2 and one increment was lost. With SELECT FOR UPDATE, Session B waited for Session A, read the updated value 2, and committed 3. The observed wait type was Lock. This checks row locking; the case's separate business constraints still apply.

## Files and order

Run the Portfolio 1 schema and sample data in a fresh database, then Isogie_Emike_301896878_P3_Transactions.sql. Open two psql terminals connected to that same database. Follow steps 1–9 across SessionA.sql and SessionB.sql; run step 5 in Session A outside a transaction.

- [Transactions](Isogie_Emike_301896878_P3_Transactions.sql)
- [Session A](Isogie_Emike_301896878_P3_SessionA.sql)
- [Session B](Isogie_Emike_301896878_P3_SessionB.sql)
- [Commit and rollback](screenshots/Isogie_Emike_301896878_P3_CommitRollback.png)
- [Concurrency](screenshots/Isogie_Emike_301896878_P3_ConcurrencyResult.png)

## References

- [PostgreSQL — transaction isolation](https://www.postgresql.org/docs/17/transaction-iso.html)
- [PostgreSQL — row locks](https://www.postgresql.org/docs/17/explicit-locking.html)

