-- This helper counter exists only in the temporary transaction exercise.
-- Original case columns and constraints are preserved. It is not part of the P1 design.
ALTER TABLE portfolio."trip" ADD COLUMN "p3_processed_count" integer NOT NULL DEFAULT 0;
ALTER TABLE portfolio."trip" ADD CONSTRAINT "p3_count_nonnegative" CHECK ("p3_processed_count" >= 0);

BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE portfolio."trip" SET "p3_processed_count" = "p3_processed_count" + 1 WHERE "trip_id" IS NOT DISTINCT FROM 4 RETURNING json_build_object('processed_count',"p3_processed_count");
COMMIT;
SELECT "trip_id", "p3_processed_count" FROM portfolio."trip" WHERE "trip_id" IS NOT DISTINCT FROM 4;

BEGIN ISOLATION LEVEL READ COMMITTED;
UPDATE portfolio."trip" SET "p3_processed_count" = "p3_processed_count" + 10 WHERE "trip_id" IS NOT DISTINCT FROM 4 RETURNING json_build_object('processed_count',"p3_processed_count");
-- A negative counter deliberately fails its CHECK. Keep psql open so ROLLBACK can run.
\set ON_ERROR_STOP off
\set VERBOSITY verbose
UPDATE portfolio."trip" SET "p3_processed_count" = -1 WHERE "trip_id" IS NOT DISTINCT FROM 4 RETURNING json_build_object('processed_count',"p3_processed_count");
-- A failed transaction rejects another statement until it is rolled back.
SELECT 1;
ROLLBACK;
\set ON_ERROR_STOP on
SELECT "trip_id", "p3_processed_count" FROM portfolio."trip" WHERE "trip_id" IS NOT DISTINCT FROM 4;
