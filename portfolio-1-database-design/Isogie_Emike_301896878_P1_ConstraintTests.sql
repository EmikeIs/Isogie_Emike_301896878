-- Run these deliberately invalid statements one at a time, outside a transaction.
-- Each should fail at the named constraint; the sample rows should remain unchanged.

-- 1. rider pk duplicate. Expected: pk_rider, SQLSTATE 23505.
INSERT INTO portfolio."rider" ("rider_id", "display_name", "joined_on")
VALUES (1, 'Casey Reed', '2026-03-01');

-- 2. driver pk duplicate. Expected: pk_driver, SQLSTATE 23505.
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled")
VALUES (2, 'Casey Reed', 'compact', TRUE);

-- 3. trip pk duplicate. Expected: pk_trip, SQLSTATE 23505.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (4, 1, NULL, '2026-03-01T10:00:00Z', 'Cedar Square', 'Willow Park', 10, 'requested');

-- 4. payment pk duplicate. Expected: pk_payment, SQLSTATE 23505.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (6, 5, 9, '2026-03-01T10:30:00Z', 'cash', 'paid');

-- 5. trip fk rider. Expected: fk_trip_0, SQLSTATE 23503.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (20, 90001, NULL, '2026-03-02T10:00:00Z', 'Cedar Square', 'Maple Station', 12, 'requested');

-- 6. trip fk driver. Expected: fk_trip_1, SQLSTATE 23503.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (21, 1, 90002, '2026-03-02T11:00:00Z', 'Cedar Square', 'Maple Station', 12, 'assigned');

-- 7. payment fk trip. Expected: fk_payment_0, SQLSTATE 23503.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (22, 90003, 12, '2026-03-02T12:00:00Z', 'card', 'paid');

-- 8. rider not null id. Expected: rider_id, SQLSTATE 23502.
INSERT INTO portfolio."rider" ("rider_id", "display_name", "joined_on")
VALUES (NULL, 'Casey Reed', '2026-03-03');

-- 9. rider not null name. Expected: display_name, SQLSTATE 23502.
INSERT INTO portfolio."rider" ("rider_id", "display_name", "joined_on")
VALUES (23, NULL, '2026-03-03');

-- 10. rider not null joined. Expected: joined_on, SQLSTATE 23502.
INSERT INTO portfolio."rider" ("rider_id", "display_name", "joined_on")
VALUES (24, 'Casey Reed', NULL);

-- 11. driver not null id. Expected: driver_id, SQLSTATE 23502.
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled")
VALUES (NULL, 'Casey Reed', 'compact', TRUE);

-- 12. driver not null name. Expected: display_name, SQLSTATE 23502.
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled")
VALUES (26, NULL, 'compact', TRUE);

-- 13. driver not null vehicle. Expected: vehicle_class, SQLSTATE 23502.
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled")
VALUES (27, 'Casey Reed', NULL, TRUE);

-- 14. driver not null enabled. Expected: enabled, SQLSTATE 23502.
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled")
VALUES (28, 'Casey Reed', 'compact', NULL);

-- 15. trip not null id. Expected: trip_id, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (NULL, 1, NULL, '2026-03-04T10:00:00Z', 'Cedar Square', 'Maple Station', 10, 'requested');

-- 16. trip not null rider. Expected: rider_id, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (30, NULL, NULL, '2026-03-04T10:00:00Z', 'Cedar Square', 'Maple Station', 10, 'requested');

-- 17. trip not null requested. Expected: requested_at, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (31, 1, NULL, NULL, 'Cedar Square', 'Maple Station', 10, 'requested');

-- 18. trip not null pickup. Expected: pickup_zone, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (32, 1, NULL, '2026-03-04T10:00:00Z', NULL, 'Maple Station', 10, 'requested');

-- 19. trip not null dropoff. Expected: dropoff_zone, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (33, 1, NULL, '2026-03-04T10:00:00Z', 'Cedar Square', NULL, 10, 'requested');

-- 20. trip not null fare. Expected: fare, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (34, 1, NULL, '2026-03-04T10:00:00Z', 'Cedar Square', 'Maple Station', NULL, 'requested');

-- 21. trip not null status. Expected: status, SQLSTATE 23502.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (35, 1, NULL, '2026-03-04T10:00:00Z', 'Cedar Square', 'Maple Station', 10, NULL);

-- 22. payment not null id. Expected: payment_id, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (NULL, 5, 10, '2026-03-05T10:00:00Z', 'card', 'paid');

-- 23. payment not null trip. Expected: trip_id, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (37, NULL, 10, '2026-03-05T10:00:00Z', 'card', 'paid');

-- 24. payment not null amount. Expected: amount, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (38, 5, NULL, '2026-03-05T10:00:00Z', 'card', 'paid');

-- 25. payment not null paid at. Expected: paid_at, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (39, 5, 10, NULL, 'card', 'paid');

-- 26. payment not null method. Expected: method, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (40, 5, 10, '2026-03-05T10:00:00Z', NULL, 'paid');

-- 27. payment not null status. Expected: payment_status, SQLSTATE 23502.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (41, 5, 10, '2026-03-05T10:00:00Z', 'card', NULL);

-- 28. payment trip unique. Expected: uq_payment_0, SQLSTATE 23505.
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status")
VALUES (42, 4, 18.5, '2026-03-06T10:00:00Z', 'card', 'paid');

-- 29. trip fare check. Expected: trip_fare_nonnegative, SQLSTATE 23514.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (43, 1, NULL, '2026-03-06T11:00:00Z', 'Cedar Square', 'Maple Station', -1, 'requested');

-- 30. trip active driver unique. Expected: active_driver_assignment, SQLSTATE 23505.
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status")
VALUES (44, 1, 2, '2026-03-06T12:00:00Z', 'Willow Park', 'Maple Station', 10, 'in_progress');
