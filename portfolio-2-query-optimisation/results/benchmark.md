# Benchmark result

PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1). Table `perf_trip`: 20000 rows, 3656 kB. Index: 456 kB.
Each phase: 5 warm-up runs, then 31 timed runs. Times are client-measured round trips in milliseconds.

| Phase | Plan | Uses index | Rows | Median ms | Min ms | Max ms |
|---|---|---|---|---|---|---|
| no index (table scan) | Seq Scan on perf_trip | no | 151 | 3.668 | 2.743 | 9.243 |
| B-tree index | Bitmap Heap Scan on perf_trip | yes | 151 | 0.67 | 0.518 | 1.431 |

Same trip IDs returned in both phases: **yes** (md5 c88c7f439df611aebf725c4a63e442f7).
Median speed-up: **5.47x**.
