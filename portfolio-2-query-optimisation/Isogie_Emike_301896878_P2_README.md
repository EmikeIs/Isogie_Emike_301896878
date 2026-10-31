# Ride-Hailing Trip and Payment Records — SQL queries

## 1. Show related trip, rider, driver records (up to 20).

```sql
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
```

| trip_trip_id | trip_requested_at | rider_rider_id | rider_display_name | driver_driver_id | driver_display_name |
| --- | --- | --- | --- | --- | --- |
| 4 | 2026-02-01T09:00:00+00:00 | 1 | Avery Quinn | 2 | Morgan Lee |

## 2. Find trip records where requested_at matches "2026-02-01T09:00:00Z" (up to 20).

```sql
SELECT * FROM portfolio."trip"
WHERE "requested_at" IS NOT DISTINCT FROM '2026-02-01T09:00:00Z'
ORDER BY "trip_id"
LIMIT 20;
```

| trip_id | rider_id | driver_id | requested_at | pickup_zone | dropoff_zone | fare | status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4 | 1 | 2 | 2026-02-01T09:00:00+00:00 | Cedar Square | Maple Station | 18.5 | assigned |

## 3. Count payment records for each trip_id (up to 20 groups).

```sql
SELECT "trip_id", count(*) AS record_count
FROM portfolio."payment"
GROUP BY "trip_id"
ORDER BY record_count DESC, "trip_id" NULLS LAST
LIMIT 20;
```

| trip_id | record_count |
| --- | --- |
| 4 | 1 |


## Index comparison

| Phase | Median (ms) | Three runs (ms) | Plan nodes | Buffer hits |
| --- | --- | --- | --- | --- |
| Before index | 0.991 | 1.009, 0.991, 0.991 | Sort → Seq Scan | 112 |
| After index | 0.178 | 0.183, 0.174, 0.178 | Sort → Bitmap Heap Scan → Bitmap Index Scan | 25 |

The median execution time changed from 0.991 ms to 0.178 ms. The measured plan used p2_filter_idx. The results matched in both phases. An index adds storage and write-maintenance costs; timings depend on the selected lookup and environment.

## Execution plans

### Before index, run 1

```text
Sort (actual time=0.977..0.978 rows=20 loops=1)
  Seq Scan on trip (actual time=0.014..0.942 rows=20 loops=1)
Planning Time: 0.34 ms
Execution Time: 1.009 ms
```

### Before index, run 2

```text
Sort (actual time=0.961..0.963 rows=20 loops=1)
  Seq Scan on trip (actual time=0.015..0.928 rows=20 loops=1)
Planning Time: 0.327 ms
Execution Time: 0.991 ms
```

### Before index, run 3

```text
Sort (actual time=0.962..0.963 rows=20 loops=1)
  Seq Scan on trip (actual time=0.014..0.926 rows=20 loops=1)
Planning Time: 0.328 ms
Execution Time: 0.991 ms
```

### After index, run 1

```text
Sort (actual time=0.123..0.125 rows=20 loops=1)
  Bitmap Heap Scan on trip (actual time=0.03..0.087 rows=20 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.018..0.018 rows=20 loops=1)
Planning Time: 0.543 ms
Execution Time: 0.183 ms
```

### After index, run 2

```text
Sort (actual time=0.12..0.121 rows=20 loops=1)
  Bitmap Heap Scan on trip (actual time=0.029..0.085 rows=20 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.017..0.017 rows=20 loops=1)
Planning Time: 0.55 ms
Execution Time: 0.174 ms
```

### After index, run 3

```text
Sort (actual time=0.122..0.124 rows=20 loops=1)
  Bitmap Heap Scan on trip (actual time=0.031..0.087 rows=20 loops=1)
    Bitmap Index Scan using p2_filter_idx (actual time=0.018..0.018 rows=20 loops=1)
Planning Time: 0.523 ms
Execution Time: 0.178 ms
```

## Reproduce

Use a fresh database with the Portfolio 1 schema and sample data. Run Isogie_Emike_301896878_P2_Queries.sql, then Isogie_Emike_301896878_P2_Optimisation.sql. The optimisation script creates a separate performance table and runs EXPLAIN (ANALYZE, BUFFERS).

[Query screenshot](screenshots/Isogie_Emike_301896878_P2_QueryResults.png) · [Index comparison](screenshots/Isogie_Emike_301896878_P2_IndexComparison.png)

## References

- [PostgreSQL — EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html)

