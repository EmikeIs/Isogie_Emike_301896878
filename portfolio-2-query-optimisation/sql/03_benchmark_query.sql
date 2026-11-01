-- Portfolio 2: the benchmark query, for running by hand in psql.
-- src/benchmark.js runs the same statement many times and times it.
--
-- Phase 1 (no index on requested_at): expect a Seq Scan over all 20,000 rows.
-- Phase 2 (after the CREATE INDEX below): expect the B-tree index to be used.

\echo '== Phase 1: no index =='
DROP INDEX IF EXISTS ix_perf_trip_requested_at;
ANALYZE perf_trip;

EXPLAIN (ANALYZE, BUFFERS)
SELECT trip_id, rider_id, pickup_zone, status, fare_amount
FROM perf_trip
WHERE requested_at >= '2026-10-01 00:00+01'
  AND requested_at <  '2026-10-03 00:00+01';

\echo '== Phase 2: B-tree index on requested_at =='
CREATE INDEX ix_perf_trip_requested_at ON perf_trip (requested_at);
ANALYZE perf_trip;

EXPLAIN (ANALYZE, BUFFERS)
SELECT trip_id, rider_id, pickup_zone, status, fare_amount
FROM perf_trip
WHERE requested_at >= '2026-10-01 00:00+01'
  AND requested_at <  '2026-10-03 00:00+01';
