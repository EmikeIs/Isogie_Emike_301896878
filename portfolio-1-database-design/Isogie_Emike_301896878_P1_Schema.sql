-- Ride-Hailing Trip and Payment Records: tables, keys and business constraints.
-- Run once in a fresh PostgreSQL database.
BEGIN;
SET LOCAL standard_conforming_strings = on;
CREATE SCHEMA portfolio;
CREATE TABLE portfolio."rider" (
  "rider_id" bigint NOT NULL,
  "display_name" text NOT NULL,
  "joined_on" date NOT NULL,
  CONSTRAINT "pk_rider" PRIMARY KEY ("rider_id")
);
CREATE TABLE portfolio."driver" (
  "driver_id" bigint NOT NULL,
  "display_name" text NOT NULL,
  "vehicle_class" text NOT NULL,
  "enabled" boolean NOT NULL,
  CONSTRAINT "pk_driver" PRIMARY KEY ("driver_id")
);
CREATE TABLE portfolio."trip" (
  "trip_id" bigint NOT NULL,
  "rider_id" bigint NOT NULL,
  "driver_id" bigint,
  "requested_at" timestamptz NOT NULL,
  "pickup_zone" text NOT NULL,
  "dropoff_zone" text NOT NULL,
  "fare" numeric(18,2) NOT NULL,
  "status" text NOT NULL,
  CONSTRAINT "pk_trip" PRIMARY KEY ("trip_id")
);
CREATE TABLE portfolio."payment" (
  "payment_id" bigint NOT NULL,
  "trip_id" bigint NOT NULL,
  "amount" numeric(18,2) NOT NULL,
  "paid_at" timestamptz NOT NULL,
  "method" text NOT NULL,
  "payment_status" text NOT NULL,
  CONSTRAINT "pk_payment" PRIMARY KEY ("payment_id"),
  CONSTRAINT "uq_payment_0" UNIQUE ("trip_id")
);
ALTER TABLE portfolio."trip" ADD CONSTRAINT "fk_trip_0" FOREIGN KEY ("rider_id") REFERENCES portfolio."rider" ("rider_id");
ALTER TABLE portfolio."trip" ADD CONSTRAINT "fk_trip_1" FOREIGN KEY ("driver_id") REFERENCES portfolio."driver" ("driver_id");
ALTER TABLE portfolio."payment" ADD CONSTRAINT "fk_payment_0" FOREIGN KEY ("trip_id") REFERENCES portfolio."trip" ("trip_id");
ALTER TABLE portfolio."trip" ADD CONSTRAINT "trip_fare_nonnegative" CHECK ("fare" >= 0);
CREATE UNIQUE INDEX "active_driver_assignment" ON portfolio."trip" ("driver_id") WHERE (("status" = 'assigned') OR ("status" = 'in_progress'));
COMMIT;
