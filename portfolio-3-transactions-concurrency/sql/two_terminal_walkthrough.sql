-- Portfolio 3: the same experiments, typed by hand in two psql windows.
-- Open two terminals, connect both to the ridehailing database, and run the
-- lines marked A in the first window and B in the second, in order.
-- src/two_sessions.js automates exactly this sequence and records the output.

-- ---------------------------------------------------------------- setup (either window)
ALTER TABLE trip ADD COLUMN demo_counter integer NOT NULL DEFAULT 0;
SHOW transaction_isolation;                       -- read committed

-- ---------------------------------------------------------------- 1. COMMIT
-- A: BEGIN;
-- A: UPDATE trip SET demo_counter = 1 WHERE trip_id = 1;
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 0, A has not committed
-- A: COMMIT;
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1

-- ---------------------------------------------------------------- 2. ROLLBACK
-- A: BEGIN;
-- A: UPDATE trip SET demo_counter = 99 WHERE trip_id = 1;
-- A: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 99 inside A
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1, no dirty read
-- A: ROLLBACK;
-- A: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1

-- ---------------------------------------------------------------- 3. lost update
-- either: UPDATE trip SET demo_counter = 1 WHERE trip_id = 1;
-- A: BEGIN;
-- B: BEGIN;
-- A: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1
-- A: UPDATE trip SET demo_counter = 2 WHERE trip_id = 1;  -- A's read + 1
-- A: COMMIT;
-- B: UPDATE trip SET demo_counter = 2 WHERE trip_id = 1;  -- B's stale read + 1
-- B: COMMIT;
-- either: SELECT demo_counter FROM trip WHERE trip_id = 1; -- 2, one increment lost

-- ---------------------------------------------------------------- 4. FOR UPDATE
-- either: UPDATE trip SET demo_counter = 1 WHERE trip_id = 1;
-- A: BEGIN;
-- B: BEGIN;
-- A: SELECT demo_counter FROM trip WHERE trip_id = 1 FOR UPDATE;   -- 1
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1 FOR UPDATE;   -- hangs
--    (a third window can confirm the wait:
--     SELECT application_name, wait_event_type, wait_event FROM pg_stat_activity WHERE datname = current_database();)
-- A: UPDATE trip SET demo_counter = 2 WHERE trip_id = 1;
-- A: COMMIT;                                                       -- B now returns 2
-- B: UPDATE trip SET demo_counter = 3 WHERE trip_id = 1;
-- B: COMMIT;
-- either: SELECT demo_counter FROM trip WHERE trip_id = 1;         -- 3

-- The read-then-write pattern above is written out so the race is visible.
-- In application code the simplest safe form is a single statement, which
-- PostgreSQL locks and re-reads for you:
--     UPDATE trip SET demo_counter = demo_counter + 1 WHERE trip_id = 1;

-- ---------------------------------------------------------------- 5. REPEATABLE READ
-- either: UPDATE trip SET demo_counter = 1 WHERE trip_id = 1;
-- A: BEGIN ISOLATION LEVEL REPEATABLE READ;
-- B: BEGIN ISOLATION LEVEL REPEATABLE READ;
-- A: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1
-- B: SELECT demo_counter FROM trip WHERE trip_id = 1;     -- 1
-- A: UPDATE trip SET demo_counter = 2 WHERE trip_id = 1;
-- A: COMMIT;
-- B: UPDATE trip SET demo_counter = 2 WHERE trip_id = 1;
--    ERROR:  could not serialize access due to concurrent update
-- B: ROLLBACK;

-- ---------------------------------------------------------------- clean up
ALTER TABLE trip DROP COLUMN demo_counter;
