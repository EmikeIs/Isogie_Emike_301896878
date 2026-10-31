# Ride-Hailing Trip and Payment Records — normalisation

The example uses the saved sample records. The full set of fields is in the design and schema.

## Starting grouped records

| rider_id | trip records (list) |
| --- | --- |
| 1 | [4,5] |


The record IDs are grouped in a list. In 1NF, each record has its own row and each cell holds one value.

## 1NF: one value per cell

| trip.trip_id | trip.rider_id | trip.driver_id | trip.pickup_zone | rider.rider_id | rider.display_name | driver.driver_id | driver.display_name |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4 | 1 | 2 | Cedar Square | 1 | Avery Quinn | 2 | Morgan Lee |
| 5 | 1 | NULL | Willow Park | 1 | Avery Quinn | NULL | NULL |

Key: trip_id.

## 2NF: depend on the whole key

The declared candidate keys do not introduce a partial dependency here, so the 1NF rows stay unchanged at this step.

## trip_example

| trip.trip_id | trip.rider_id | trip.driver_id | trip.pickup_zone | rider.rider_id | rider.display_name | driver.driver_id | driver.display_name |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4 | 1 | 2 | Cedar Square | 1 | Avery Quinn | 2 | Morgan Lee |
| 5 | 1 | NULL | Willow Park | 1 | Avery Quinn | NULL | NULL |

## 3NF: store each entity’s details once

The entity keys determine their own descriptions. Related records keep foreign keys rather than repeating those descriptions.

## rider

| rider_id | display_name | joined_on |
| --- | --- | --- |
| 1 | Avery Quinn | 2026-01-10 |

## driver

| driver_id | display_name | vehicle_class | enabled |
| --- | --- | --- | --- |
| 2 | Morgan Lee | compact | true |
| 3 | Riley Park | standard | true |

## trip

| trip_id | rider_id | driver_id | requested_at | pickup_zone | dropoff_zone | fare | status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4 | 1 | 2 | 2026-02-01T09:00:00+00:00 | Cedar Square | Maple Station | 18.5 | assigned |
| 5 | 1 | NULL | 2026-02-02T14:30:00+00:00 | Willow Park | Cedar Square | 0 | requested |

## payment

| payment_id | trip_id | amount | paid_at | method | payment_status |
| --- | --- | --- | --- | --- | --- |
| 6 | 4 | 18.5 | 2026-02-01T09:45:00+00:00 | card | paid |

## Dependencies

- rider: (rider_id) → display_name, joined_on
- driver: (driver_id) → display_name, vehicle_class, enabled
- trip: (trip_id) → rider_id, driver_id, requested_at, pickup_zone, dropoff_zone, fare, status
- payment: (payment_id) → trip_id, amount, paid_at, method, payment_status

Joining the decomposed sample tables reproduces the original 2 example rows. The design assumes the declared keys describe the relevant business dependencies.
