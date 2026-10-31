# Ride-Hailing Trip and Payment Records — database design

My case study records rider, driver, trip, payment.

## Users

- Dispatchers reviewing trip assignments
- Analysts summarizing trip activity
- Payment operators recording trip charges

## Main operations

- Create trips and assign available drivers
- Review trips by status, time range, and rider
- Summarize trip counts and fares by pickup zone
- Record a payment for a trip
- Benchmark trip time-range filtering on 20000 synthetic rows by comparing a table scan with a B-tree index using the same predicate and reporting the query plan and elapsed time

## Entities

| Entity | Information stored |
| --- | --- |
| rider | Stores rider attributes independently of trips. |
| driver | Stores driver attributes independently of trips. |
| trip | Stores each trip and references its rider and optional assigned driver. |
| payment | Stores a trip's payment details without duplicating trip attributes. |

## rider

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| rider_id | BIGINT | PK | Yes |
| display_name | TEXT |  | Yes |
| joined_on | DATE |  | Yes |


## driver

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| driver_id | BIGINT | PK | Yes |
| display_name | TEXT |  | Yes |
| vehicle_class | TEXT |  | Yes |
| enabled | BOOLEAN |  | Yes |


## trip

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| trip_id | BIGINT | PK | Yes |
| rider_id | BIGINT | FK | Yes |
| driver_id | BIGINT | FK | No |
| requested_at | TIMESTAMPTZ |  | Yes |
| pickup_zone | TEXT |  | Yes |
| dropoff_zone | TEXT |  | Yes |
| fare | NUMERIC(18,2) |  | Yes |
| status | TEXT |  | Yes |
- rider_id → rider.rider_id
- driver_id → driver.driver_id

## payment

| Field | Type | Key | Required |
| --- | --- | --- | --- |
| payment_id | BIGINT | PK | Yes |
| trip_id | BIGINT | FK, Unique | Yes |
| amount | NUMERIC(18,2) |  | Yes |
| paid_at | TIMESTAMPTZ |  | Yes |
| method | TEXT |  | Yes |
| payment_status | TEXT |  | Yes |
- trip_id → trip.trip_id
- Unique key: (trip_id).

## Relationships and business rules

- Every trip must reference an existing rider.
- A non-null assigned driver must reference an existing driver.
- A row CHECK requires fare to be greater than or equal to zero.
- A partial UNIQUE constraint on driver_id applies only when status is assigned or in_progress, preventing a driver from having two active trips.
- Each trip can have at most one payment record.
- Every rider record must have a display name.

## Assumptions

- All records and values used in exercises are synthetic; zones and names are fictional.
- Identifiers are allocated from one global identifier space, so each table has a single-column primary key whose values are globally unique.
- A trip has one rider and may have no driver until assigned; an assigned or in-progress trip has a driver.
- A driver may have at most one trip in assigned or in-progress status at a time.
- Fare and payment amounts use one currency and must be nonnegative.
- A trip has at most one payment record in this exercise.
- The normalization example keeps each rider and driver role in its own table and does not repeat ancestor attributes in Trip.

