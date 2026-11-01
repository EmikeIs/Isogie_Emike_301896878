-- Portfolio 1: the case-study operations run end to end.
-- Creates a trip, assigns an available driver, starts and completes the trip,
-- then records the payment. Everything runs in one transaction that is rolled
-- back at the end, so the sample data used by the later portfolios is unchanged.

\set ON_ERROR_STOP on
BEGIN;

\echo '== 1. Avery (rider 1) requests a trip; no driver yet =='
INSERT INTO trip (rider_id, pickup_zone, dropoff_zone, requested_at)
VALUES (1, 'Lekki', 'Ikeja', '2026-10-05 09:00+01')
RETURNING trip_id, rider_id, status, driver_id;

\echo '== 2. Assign the first available driver =='
-- FOR UPDATE SKIP LOCKED lets two dispatchers run this at the same time
-- without both picking the same driver.
WITH picked AS (
    SELECT driver_id FROM driver
    WHERE is_available
    ORDER BY rating DESC, driver_id
    LIMIT 1
    FOR UPDATE SKIP LOCKED
), mark_busy AS (
    UPDATE driver d SET is_available = false
    FROM picked WHERE d.driver_id = picked.driver_id
    RETURNING d.driver_id
)
UPDATE trip t SET driver_id = mark_busy.driver_id, status = 'assigned'
FROM mark_busy
WHERE t.trip_id = currval(pg_get_serial_sequence('trip', 'trip_id'))
RETURNING t.trip_id, t.status, t.driver_id;

\echo '== 3. Driver picks up the rider =='
UPDATE trip SET status = 'in_progress', started_at = '2026-10-05 09:12+01'
WHERE trip_id = currval(pg_get_serial_sequence('trip', 'trip_id'))
RETURNING trip_id, status, started_at;

\echo '== 4. Trip ends; fare is set =='
UPDATE trip SET status = 'completed', completed_at = '2026-10-05 09:47+01',
                distance_km = 18.30, fare_amount = 6200.00
WHERE trip_id = currval(pg_get_serial_sequence('trip', 'trip_id'))
RETURNING trip_id, status, distance_km, fare_amount;

UPDATE driver SET is_available = true
WHERE driver_id = (SELECT driver_id FROM trip WHERE trip_id = currval(pg_get_serial_sequence('trip', 'trip_id')));

\echo '== 5. A payment for the wrong amount is refused =='
\set ON_ERROR_STOP off
SAVEPOINT before_bad_payment;
INSERT INTO payment (trip_id, amount, method, status, reference, paid_at)
VALUES (currval(pg_get_serial_sequence('trip', 'trip_id')), 5000.00, 'wallet', 'succeeded', 'PAY-DEMO-BAD', '2026-10-05 09:48+01');
ROLLBACK TO SAVEPOINT before_bad_payment;
\set ON_ERROR_STOP on

\echo '== 6. The correct payment is recorded =='
INSERT INTO payment (trip_id, amount, method, status, reference, paid_at)
VALUES (currval(pg_get_serial_sequence('trip', 'trip_id')), 6200.00, 'wallet', 'succeeded', 'PAY-DEMO-0001', '2026-10-05 09:48+01')
RETURNING payment_id, trip_id, amount, method, status;

\echo '== 7. The finished record =='
SELECT t.trip_id, r.full_name AS rider, d.full_name AS driver, t.pickup_zone,
       t.dropoff_zone, t.status, t.fare_amount, p.method, p.status AS payment_status
FROM trip t
JOIN rider r   ON r.rider_id  = t.rider_id
JOIN driver d  ON d.driver_id = t.driver_id
JOIN payment p ON p.trip_id   = t.trip_id
WHERE t.trip_id = currval(pg_get_serial_sequence('trip', 'trip_id'));

ROLLBACK;
\echo '== Rolled back: sample data restored =='
SELECT count(*) AS trips, (SELECT count(*) FROM payment) AS payments FROM trip;
