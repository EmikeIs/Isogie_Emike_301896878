-- Fictional sample records for Ride-Hailing Trip and Payment Records.
BEGIN;
SET LOCAL standard_conforming_strings = on;
INSERT INTO portfolio."rider" ("rider_id", "display_name", "joined_on") VALUES (1, 'Avery Quinn', '2026-01-10');
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled") VALUES (2, 'Morgan Lee', 'compact', TRUE);
INSERT INTO portfolio."driver" ("driver_id", "display_name", "vehicle_class", "enabled") VALUES (3, 'Riley Park', 'standard', TRUE);
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status") VALUES (4, 1, 2, '2026-02-01T09:00:00Z', 'Cedar Square', 'Maple Station', 18.5, 'assigned');
INSERT INTO portfolio."trip" ("trip_id", "rider_id", "driver_id", "requested_at", "pickup_zone", "dropoff_zone", "fare", "status") VALUES (5, 1, NULL, '2026-02-02T14:30:00+00:00', 'Willow Park', 'Cedar Square', 0, 'requested');
INSERT INTO portfolio."payment" ("payment_id", "trip_id", "amount", "paid_at", "method", "payment_status") VALUES (6, 4, 18.5, '2026-02-01T09:45:00Z', 'card', 'paid');
COMMIT;
