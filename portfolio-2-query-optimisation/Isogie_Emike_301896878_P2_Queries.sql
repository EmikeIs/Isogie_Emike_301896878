-- Show related trip, rider, driver records (up to 20).
SELECT t0."trip_id" AS "trip_trip_id",
       t0."requested_at" AS "trip_requested_at",
       t1."rider_id" AS "rider_rider_id",
       t1."display_name" AS "rider_display_name",
       t2."driver_id" AS "driver_driver_id",
       t2."display_name" AS "driver_display_name"
FROM portfolio."trip" t0
JOIN portfolio."rider" t1 ON t0."rider_id" = t1."rider_id"
JOIN portfolio."driver" t2 ON t0."driver_id" = t2."driver_id"
ORDER BY t0."trip_id", t1."rider_id", t2."driver_id"
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT t0."trip_id" AS "trip_trip_id",
       t0."requested_at" AS "trip_requested_at",
       t1."rider_id" AS "rider_rider_id",
       t1."display_name" AS "rider_display_name",
       t2."driver_id" AS "driver_driver_id",
       t2."display_name" AS "driver_display_name"
FROM portfolio."trip" t0
JOIN portfolio."rider" t1 ON t0."rider_id" = t1."rider_id"
JOIN portfolio."driver" t2 ON t0."driver_id" = t2."driver_id"
ORDER BY t0."trip_id", t1."rider_id", t2."driver_id"
LIMIT 20;

-- Find trip records where requested_at matches "2026-02-01T09:00:00Z" (up to 20).
SELECT * FROM portfolio."trip"
WHERE "requested_at" IS NOT DISTINCT FROM '2026-02-01T09:00:00Z'
ORDER BY "trip_id"
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM portfolio."trip"
WHERE "requested_at" IS NOT DISTINCT FROM '2026-02-01T09:00:00Z'
ORDER BY "trip_id"
LIMIT 20;

-- Count payment records for each trip_id (up to 20 groups).
SELECT "trip_id", count(*) AS record_count
FROM portfolio."payment"
GROUP BY "trip_id"
ORDER BY record_count DESC, "trip_id" NULLS LAST
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT "trip_id", count(*) AS record_count
FROM portfolio."payment"
GROUP BY "trip_id"
ORDER BY record_count DESC, "trip_id" NULLS LAST
LIMIT 20;
