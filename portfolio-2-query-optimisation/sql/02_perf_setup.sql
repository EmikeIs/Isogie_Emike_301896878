-- Portfolio 2: performance data set.
-- 20,000 synthetic trips in their own table, perf_trip, so the benchmark
-- never touches the sample records. setseed() makes the "random" values the
-- same on every run, so anyone re-running this gets identical rows.

DROP TABLE IF EXISTS perf_trip;

CREATE TABLE perf_trip (
    trip_id      integer PRIMARY KEY,
    rider_id     integer      NOT NULL,
    driver_id    integer,
    pickup_zone  varchar(40)  NOT NULL,
    dropoff_zone varchar(40)  NOT NULL,
    status       varchar(12)  NOT NULL,
    requested_at timestamptz  NOT NULL,
    distance_km  numeric(6,2),
    fare_amount  numeric(10,2)
);

SELECT setseed(0.301896878);

INSERT INTO perf_trip
SELECT g,
       1 + (random() * 4999)::int,                                   -- 5,000 riders
       1 + (random() *  799)::int,                                   -- 800 drivers
       (ARRAY['Lekki','Yaba','Ikeja','Surulere','Victoria Island',
              'Ajah','Ikoyi','Maryland','Gbagada','Apapa'])[1 + (random() * 9)::int],
       (ARRAY['Lekki','Yaba','Ikeja','Surulere','Victoria Island',
              'Ajah','Ikoyi','Maryland','Gbagada','Apapa'])[1 + (random() * 9)::int],
       CASE WHEN random() < 0.88 THEN 'completed' ELSE 'cancelled' END,
       -- spread evenly over 1 January to 31 October 2026 (304 days)
       timestamptz '2026-01-01 00:00+01' + random() * interval '304 days',
       round((2 + random() * 28)::numeric, 2),
       NULL
FROM generate_series(1, 20000) AS g;

-- Fare follows distance: a base charge plus a per-km rate. Cancelled trips
-- carry no fare.
UPDATE perf_trip
SET fare_amount = CASE WHEN status = 'completed' THEN round(800 + distance_km * 320, 2) END,
    distance_km = CASE WHEN status = 'completed' THEN distance_km END;

ANALYZE perf_trip;

SELECT count(*) AS rows_loaded,
       min(requested_at) AS earliest,
       max(requested_at) AS latest,
       pg_size_pretty(pg_relation_size('perf_trip')) AS table_size
FROM perf_trip;
