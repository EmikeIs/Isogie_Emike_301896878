-- Portfolio 2: three queries on the Portfolio 1 sample data, each followed
-- by its execution plan. Run after portfolio-1-database-design/run.sh.

-- Refresh planner statistics first; on a newly loaded table the planner
-- otherwise guesses row counts (it assumed 240 trips before this was added).
ANALYZE rider; ANALYZE driver; ANALYZE trip; ANALYZE payment;

\echo '== Q1. Paid trips: who rode, who drove, what was charged =='
-- Four-way join. Inner joins drop trips with no driver or no payment.
SELECT t.trip_id,
       r.full_name  AS rider,
       d.full_name  AS driver,
       t.pickup_zone || ' -> ' || t.dropoff_zone AS route,
       t.fare_amount,
       p.method,
       p.paid_at
FROM trip t
JOIN rider   r ON r.rider_id  = t.rider_id
JOIN driver  d ON d.driver_id = t.driver_id
JOIN payment p ON p.trip_id   = t.trip_id
WHERE t.status = 'completed'
  AND p.status = 'succeeded'
ORDER BY p.paid_at;

\echo '== Q1 plan =='
EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING OFF, SUMMARY OFF)
SELECT t.trip_id, r.full_name, d.full_name, t.fare_amount, p.method, p.paid_at
FROM trip t
JOIN rider   r ON r.rider_id  = t.rider_id
JOIN driver  d ON d.driver_id = t.driver_id
JOIN payment p ON p.trip_id   = t.trip_id
WHERE t.status = 'completed' AND p.status = 'succeeded'
ORDER BY p.paid_at;

\echo '== Q2. Trip counts and fares by pickup zone =='
-- LEFT JOIN keeps unpaid trips in the count. FILTER splits the counts by
-- status in one pass instead of one query per status.
SELECT t.pickup_zone,
       count(*)                                        AS trips,
       count(*) FILTER (WHERE t.status = 'completed')  AS completed,
       count(*) FILTER (WHERE t.status = 'cancelled')  AS cancelled,
       COALESCE(sum(t.fare_amount), 0)                 AS total_fares,
       round(avg(t.fare_amount), 2)                    AS avg_fare,
       COALESCE(sum(p.amount) FILTER (WHERE p.status = 'succeeded'), 0) AS collected
FROM trip t
LEFT JOIN payment p ON p.trip_id = t.trip_id
GROUP BY t.pickup_zone
ORDER BY trips DESC, t.pickup_zone;

\echo '== Q2 plan =='
EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING OFF, SUMMARY OFF)
SELECT t.pickup_zone, count(*),
       count(*) FILTER (WHERE t.status = 'completed'),
       sum(t.fare_amount), sum(p.amount) FILTER (WHERE p.status = 'succeeded')
FROM trip t
LEFT JOIN payment p ON p.trip_id = t.trip_id
GROUP BY t.pickup_zone;

\echo '== Q3. Active trips requested between 08:00 and 09:00 on 5 October =='
-- The dispatcher view: filter on status and a time range, show the rider.
SELECT t.trip_id, t.status, r.full_name AS rider, t.pickup_zone,
       t.requested_at
FROM trip t
JOIN rider r ON r.rider_id = t.rider_id
WHERE t.status IN ('assigned', 'in_progress')
  AND t.requested_at >= '2026-10-05 08:00+01'
  AND t.requested_at <  '2026-10-05 09:00+01'
ORDER BY t.requested_at;

\echo '== Q3 plan =='
EXPLAIN (ANALYZE, BUFFERS, COSTS, TIMING OFF, SUMMARY OFF)
SELECT t.trip_id, t.status, r.full_name, t.pickup_zone, t.requested_at
FROM trip t
JOIN rider r ON r.rider_id = t.rider_id
WHERE t.status IN ('assigned', 'in_progress')
  AND t.requested_at >= '2026-10-05 08:00+01'
  AND t.requested_at <  '2026-10-05 09:00+01'
ORDER BY t.requested_at;
