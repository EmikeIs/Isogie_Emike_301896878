-- Portfolio 1: fictional sample records.
-- Names, phone numbers, plates and references are made up.
-- Rows are inserted in order, so identity values run 1, 2, 3 ...

BEGIN;

INSERT INTO rider (full_name, phone, email, created_at) VALUES
    ('Avery Quinn',    '+2348030000101', 'avery.quinn@example.com',  '2026-09-01 08:00+01'),
    ('Tobi Adeyemi',   '+2348030000102', 'tobi.adeyemi@example.com', '2026-09-02 09:30+01'),
    ('Chiamaka Obi',   '+2348030000103', NULL,                       '2026-09-03 11:15+01'),
    ('Daniel Okoro',   '+2348030000104', 'd.okoro@example.com',      '2026-09-04 14:45+01');

INSERT INTO driver (full_name, phone, licence_no, vehicle_plate, vehicle_type, rating, is_available, created_at) VALUES
    ('Morgan Lee',     '+2348090000201', 'LAG-DL-20411', 'LND-482-KJ', 'sedan',   4.8, true,  '2026-08-20 10:00+01'),
    ('Ifeanyi Bello',  '+2348090000202', 'LAG-DL-20412', 'EKY-115-AA', 'suv',     4.6, false, '2026-08-21 10:00+01'),
    ('Sade Martins',   '+2348090000203', 'LAG-DL-20413', 'KJA-903-BC', 'minivan', 4.9, false, '2026-08-22 10:00+01');

-- One trip for each stage of the life cycle.
INSERT INTO trip (rider_id, driver_id, pickup_zone, dropoff_zone, status,
                  requested_at, started_at, completed_at, distance_km, fare_amount) VALUES
    -- 1: finished and paid
    (1, 1, 'Lekki',  'Victoria Island', 'completed',
     '2026-10-05 07:40+01', '2026-10-05 07:52+01', '2026-10-05 08:21+01', 12.40, 4850.00),
    -- 2: driver on the way with the rider in the car
    (2, 2, 'Yaba',   'Ikeja',           'in_progress',
     '2026-10-05 08:05+01', '2026-10-05 08:14+01', NULL, NULL, NULL),
    -- 3: driver matched, not yet picked up
    (3, 3, 'Ikeja',  'Surulere',        'assigned',
     '2026-10-05 08:20+01', NULL, NULL, NULL, NULL),
    -- 4: still waiting for a driver
    (4, NULL, 'Surulere', 'Yaba',       'requested',
     '2026-10-05 08:25+01', NULL, NULL, NULL, NULL),
    -- 5: rider cancelled before a match
    (1, NULL, 'Victoria Island', 'Lekki', 'cancelled',
     '2026-10-04 18:10+01', NULL, NULL, NULL, NULL);

INSERT INTO payment (trip_id, amount, currency, method, status, reference, paid_at) VALUES
    (1, 4850.00, 'NGN', 'card', 'succeeded', 'PAY-2026-10-05-0001', '2026-10-05 08:22+01');

COMMIT;
