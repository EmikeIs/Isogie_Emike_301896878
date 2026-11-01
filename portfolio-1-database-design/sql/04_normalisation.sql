-- Portfolio 1: normalisation walk-through on the sample data.
-- Builds each stage in a separate schema (norm_demo) so the main tables are
-- untouched, then prints every stage. The explanation is in ../normalisation.md.

DROP SCHEMA IF EXISTS norm_demo CASCADE;
CREATE SCHEMA norm_demo;
SET search_path = norm_demo, public;

-- Unnormalised: how a dispatcher's spreadsheet might look, one line per
-- rider with every trip squeezed into one text cell.
CREATE TABLE unf_rider_sheet (
    rider_phone text,
    rider_name  text,
    trips       text   -- repeating group
);
INSERT INTO unf_rider_sheet VALUES
('+2348030000101', 'Avery Quinn',
 '1: Lekki>Victoria Island, Morgan Lee (+2348090000201, LND-482-KJ), 4850, PAY-2026-10-05-0001 card | 2: Victoria Island>Lekki, cancelled'),
('+2348030000102', 'Tobi Adeyemi',
 '1: Yaba>Ikeja, Ifeanyi Bello (+2348090000202, EKY-115-AA), in progress');

-- 1NF: one row per trip, one value per cell. The sheet numbered trips per
-- rider, so the key is (rider_phone, trip_seq).
CREATE TABLE nf1_trip_line (
    rider_phone   text,
    trip_seq      integer,
    rider_name    text,
    pickup_zone   text,
    dropoff_zone  text,
    status        text,
    driver_phone  text,
    driver_name   text,
    vehicle_plate text,
    fare_amount   numeric(10,2),
    payment_ref   text,
    payment_method text,
    PRIMARY KEY (rider_phone, trip_seq)
);
INSERT INTO nf1_trip_line VALUES
('+2348030000101', 1, 'Avery Quinn',  'Lekki', 'Victoria Island', 'completed',   '+2348090000201', 'Morgan Lee',    'LND-482-KJ', 4850, 'PAY-2026-10-05-0001', 'card'),
('+2348030000101', 2, 'Avery Quinn',  'Victoria Island', 'Lekki', 'cancelled',   NULL, NULL, NULL, NULL, NULL, NULL),
('+2348030000102', 1, 'Tobi Adeyemi', 'Yaba', 'Ikeja',            'in_progress', '+2348090000202', 'Ifeanyi Bello', 'EKY-115-AA', NULL, NULL, NULL);

-- 2NF: rider_name depends on rider_phone alone (part of the key), so it
-- moves to its own table. Every remaining column needs the whole key.
CREATE TABLE nf2_rider (
    rider_phone text PRIMARY KEY,
    rider_name  text NOT NULL
);
CREATE TABLE nf2_trip (
    rider_phone   text REFERENCES nf2_rider,
    trip_seq      integer,
    pickup_zone   text,
    dropoff_zone  text,
    status        text,
    driver_phone  text,
    driver_name   text,
    vehicle_plate text,
    fare_amount   numeric(10,2),
    payment_ref   text,
    payment_method text,
    PRIMARY KEY (rider_phone, trip_seq)
);
INSERT INTO nf2_rider SELECT DISTINCT rider_phone, rider_name FROM nf1_trip_line;
INSERT INTO nf2_trip
SELECT rider_phone, trip_seq, pickup_zone, dropoff_zone, status, driver_phone,
       driver_name, vehicle_plate, fare_amount, payment_ref, payment_method
FROM nf1_trip_line;

-- 3NF: two transitive dependencies remain in nf2_trip.
--   key -> driver_phone -> driver_name, vehicle_plate
--   key -> payment_ref  -> payment_method
-- Each moves to its own table, leaving only a reference behind.
CREATE TABLE nf3_rider  (rider_phone  text PRIMARY KEY, rider_name text NOT NULL);
CREATE TABLE nf3_driver (driver_phone text PRIMARY KEY, driver_name text NOT NULL, vehicle_plate text NOT NULL UNIQUE);
CREATE TABLE nf3_trip (
    rider_phone  text REFERENCES nf3_rider,
    trip_seq     integer,
    driver_phone text REFERENCES nf3_driver,
    pickup_zone  text,
    dropoff_zone text,
    status       text,
    fare_amount  numeric(10,2),
    PRIMARY KEY (rider_phone, trip_seq)
);
CREATE TABLE nf3_payment (
    payment_ref    text PRIMARY KEY,
    rider_phone    text,
    trip_seq       integer,
    payment_method text NOT NULL,
    UNIQUE (rider_phone, trip_seq),
    FOREIGN KEY (rider_phone, trip_seq) REFERENCES nf3_trip
);
INSERT INTO nf3_rider  SELECT * FROM nf2_rider;
INSERT INTO nf3_driver SELECT DISTINCT driver_phone, driver_name, vehicle_plate FROM nf2_trip WHERE driver_phone IS NOT NULL;
INSERT INTO nf3_trip   SELECT rider_phone, trip_seq, driver_phone, pickup_zone, dropoff_zone, status, fare_amount FROM nf2_trip;
INSERT INTO nf3_payment SELECT payment_ref, rider_phone, trip_seq, payment_method FROM nf2_trip WHERE payment_ref IS NOT NULL;

\echo '== UNF: one row per rider, trips packed into one cell =='
SELECT * FROM unf_rider_sheet;
\echo '== 1NF: atomic values, key (rider_phone, trip_seq) =='
SELECT * FROM nf1_trip_line ORDER BY 1, 2;
\echo '== 2NF: rider details split out =='
SELECT * FROM nf2_rider ORDER BY 1;
SELECT * FROM nf2_trip ORDER BY 1, 2;
\echo '== 3NF: driver and payment details split out =='
SELECT * FROM nf3_rider ORDER BY 1;
SELECT * FROM nf3_driver ORDER BY 1;
SELECT * FROM nf3_trip ORDER BY 1, 2;
SELECT * FROM nf3_payment ORDER BY 1;

-- The final schema (01_schema.sql) keeps this 3NF shape and replaces the
-- natural keys with integer identity keys. Phone, licence, plate and
-- payment reference stay as UNIQUE columns.
RESET search_path;
DROP SCHEMA norm_demo CASCADE;
