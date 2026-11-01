-- Portfolio 1: constraint tests.
-- Each statement below breaks one rule on purpose. The block runs every
-- statement inside its own sub-transaction, records whether the database
-- rejected it and which error it raised, then compares row counts before
-- and after. Expected result: 30 rejected, 0 accepted, counts unchanged.
--
-- Run after 01_schema.sql and 02_sample_data.sql.
-- SQLSTATE codes: 23502 not-null, 23503 foreign key, 23505 unique, 23514 check.

DROP TABLE IF EXISTS constraint_test_case;
CREATE TEMP TABLE constraint_test_case (
    test_no        integer PRIMARY KEY,
    target_table   text NOT NULL,
    rule_tested    text NOT NULL,
    expected_state text NOT NULL,
    stmt           text NOT NULL,
    outcome        text,
    sqlstate       text,
    constraint_hit text
);

INSERT INTO constraint_test_case (test_no, target_table, rule_tested, expected_state, stmt) VALUES
-- rider
( 1, 'rider',   'name is required',                    '23502', $$INSERT INTO rider (full_name, phone) VALUES (NULL, '+2348030000999')$$),
( 2, 'rider',   'name cannot be blank',                '23514', $$INSERT INTO rider (full_name, phone) VALUES ('   ', '+2348030000999')$$),
( 3, 'rider',   'phone must be unique',                '23505', $$INSERT INTO rider (full_name, phone) VALUES ('Copy Rider', '+2348030000101')$$),
( 4, 'rider',   'phone must be digits',                '23514', $$INSERT INTO rider (full_name, phone) VALUES ('Bad Phone', '0803-ABC')$$),
( 5, 'rider',   'email must look like an email',       '23514', $$INSERT INTO rider (full_name, phone, email) VALUES ('Bad Email', '+2348030000998', 'not-an-email')$$),
( 6, 'rider',   'email must be unique',                '23505', $$INSERT INTO rider (full_name, phone, email) VALUES ('Copy Email', '+2348030000997', 'avery.quinn@example.com')$$),
-- driver
( 7, 'driver',  'licence must be unique',              '23505', $$INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type) VALUES ('Copy Licence', '+2348090000999', 'LAG-DL-20411', 'NEW-001-AA', 'sedan')$$),
( 8, 'driver',  'plate must be unique',                '23505', $$INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type) VALUES ('Copy Plate', '+2348090000998', 'LAG-DL-99998', 'LND-482-KJ', 'sedan')$$),
( 9, 'driver',  'vehicle type from fixed list',        '23514', $$INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type) VALUES ('Bad Type', '+2348090000997', 'LAG-DL-99997', 'NEW-002-AA', 'helicopter')$$),
(10, 'driver',  'rating between 1 and 5',              '23514', $$INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type, rating) VALUES ('Bad Rating', '+2348090000996', 'LAG-DL-99996', 'NEW-003-AA', 'suv', 6.0)$$),
(11, 'driver',  'licence is required',                 '23502', $$INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type) VALUES ('No Licence', '+2348090000995', NULL, 'NEW-004-AA', 'sedan')$$),
-- trip
(12, 'trip',    'rider must exist',                    '23503', $$INSERT INTO trip (rider_id, pickup_zone, dropoff_zone) VALUES (999, 'Lekki', 'Yaba')$$),
(13, 'trip',    'driver must exist',                   '23503', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status) VALUES (2, 999, 'Lekki', 'Yaba', 'assigned')$$),
(14, 'trip',    'status from fixed list',              '23514', $$INSERT INTO trip (rider_id, pickup_zone, dropoff_zone, status) VALUES (2, 'Lekki', 'Yaba', 'flying')$$),
(15, 'trip',    'requested trip has no driver',        '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status) VALUES (2, 1, 'Lekki', 'Yaba', 'requested')$$),
(16, 'trip',    'assigned trip needs a driver',        '23514', $$INSERT INTO trip (rider_id, pickup_zone, dropoff_zone, status) VALUES (2, 'Lekki', 'Yaba', 'assigned')$$),
(17, 'trip',    'in-progress trip needs start time',   '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status) VALUES (2, 1, 'Lekki', 'Yaba', 'in_progress')$$),
(18, 'trip',    'completed trip needs end time',       '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, started_at, distance_km, fare_amount) VALUES (2, 1, 'Lekki', 'Yaba', 'completed', now(), 5, 2000)$$),
(19, 'trip',    'completed trip needs a fare',         '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, started_at, completed_at, distance_km) VALUES (2, 1, 'Lekki', 'Yaba', 'completed', now(), now(), 5)$$),
(20, 'trip',    'start cannot be before request',      '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, requested_at, started_at) VALUES (2, 1, 'Lekki', 'Yaba', 'in_progress', '2026-10-05 09:00+01', '2026-10-05 08:00+01')$$),
(21, 'trip',    'end cannot be before start',          '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, requested_at, started_at, completed_at, distance_km, fare_amount) VALUES (2, 1, 'Lekki', 'Yaba', 'completed', '2026-10-05 08:00+01', '2026-10-05 08:10+01', '2026-10-05 08:05+01', 5, 2000)$$),
(22, 'trip',    'fare cannot be negative',             '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, started_at, completed_at, distance_km, fare_amount) VALUES (2, 1, 'Lekki', 'Yaba', 'completed', now(), now(), 5, -100)$$),
(23, 'trip',    'distance must be positive',           '23514', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status, started_at, completed_at, distance_km, fare_amount) VALUES (2, 1, 'Lekki', 'Yaba', 'completed', now(), now(), 0, 2000)$$),
(24, 'trip',    'pickup zone is required',             '23502', $$INSERT INTO trip (rider_id, pickup_zone, dropoff_zone) VALUES (2, NULL, 'Yaba')$$),
(25, 'trip',    'driver has one active trip only',     '23505', $$INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status) VALUES (4, 2, 'Surulere', 'Lekki', 'assigned')$$),
-- payment
(26, 'payment', 'trip must exist',                     '23503', $$INSERT INTO payment (trip_id, amount, method, reference) VALUES (999, 1000, 'cash', 'PAY-TEST-0026')$$),
(27, 'payment', 'one payment per trip',                '23505', $$INSERT INTO payment (trip_id, amount, method, reference) VALUES (1, 4850, 'cash', 'PAY-TEST-0027')$$),
(28, 'payment', 'amount must be positive',             '23514', $$INSERT INTO payment (trip_id, amount, method, reference) VALUES (2, 0, 'cash', 'PAY-TEST-0028')$$),
(29, 'payment', 'method from fixed list',              '23514', $$INSERT INTO payment (trip_id, amount, method, reference) VALUES (2, 1000, 'cheque', 'PAY-TEST-0029')$$),
(30, 'payment', 'only completed trips can be paid',    '23514', $$INSERT INTO payment (trip_id, amount, method, status, reference, paid_at) VALUES (3, 1500, 'wallet', 'succeeded', 'PAY-TEST-0030', now())$$);

CREATE TEMP TABLE row_counts_before AS
SELECT 'rider' AS t, count(*) AS n FROM rider UNION ALL
SELECT 'driver', count(*) FROM driver UNION ALL
SELECT 'trip',   count(*) FROM trip   UNION ALL
SELECT 'payment',count(*) FROM payment;

DO $$
DECLARE
    tc   record;
    v_state text;
    v_con   text;
BEGIN
    FOR tc IN SELECT * FROM constraint_test_case ORDER BY test_no LOOP
        BEGIN
            EXECUTE tc.stmt;
            -- reaching this line means the bad row was accepted
            UPDATE constraint_test_case SET outcome = 'ACCEPTED' WHERE test_no = tc.test_no;
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_con = CONSTRAINT_NAME;
            UPDATE constraint_test_case
               SET outcome = 'rejected', sqlstate = v_state,
                   constraint_hit = COALESCE(NULLIF(v_con, ''), 'NOT NULL')
             WHERE test_no = tc.test_no;
        END;
    END LOOP;
END;
$$;

\echo
\echo '== Constraint test results =='
SELECT test_no AS "#", target_table AS "table", rule_tested AS "rule",
       outcome, sqlstate,
       CASE WHEN sqlstate = expected_state THEN 'yes' ELSE 'NO' END AS "expected error",
       constraint_hit AS "caught by"
FROM constraint_test_case ORDER BY test_no;

\echo '== Summary =='
SELECT count(*) FILTER (WHERE outcome = 'rejected')         AS rejected,
       count(*) FILTER (WHERE outcome = 'ACCEPTED')         AS accepted,
       count(*) FILTER (WHERE sqlstate = expected_state)    AS matched_expected_error,
       count(*)                                             AS total
FROM constraint_test_case;

\echo '== Row counts before and after (valid sample rows must be unchanged) =='
SELECT b.t AS "table", b.n AS before,
       a.n AS after,
       CASE WHEN a.n = b.n THEN 'unchanged' ELSE 'CHANGED' END AS check_result
FROM row_counts_before b
JOIN (SELECT 'rider' AS t, count(*) AS n FROM rider UNION ALL
      SELECT 'driver', count(*) FROM driver UNION ALL
      SELECT 'trip',   count(*) FROM trip   UNION ALL
      SELECT 'payment',count(*) FROM payment) a USING (t)
ORDER BY array_position(ARRAY['rider','driver','trip','payment'], b.t);
