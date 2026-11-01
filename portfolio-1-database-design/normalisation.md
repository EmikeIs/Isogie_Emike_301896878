# Normalisation walk-through

This note follows the sample data from a rough spreadsheet to the final schema. The SQL that builds each stage is [`sql/04_normalisation.sql`](sql/04_normalisation.sql). Its printed output, which matches the tables below, is in [`results/02_normalisation.txt`](results/02_normalisation.txt).

## Starting point: unnormalised

Imagine a dispatcher keeping one spreadsheet line per rider, with every trip typed into a single cell.

| rider_phone | rider_name | trips |
|---|---|---|
| +2348030000101 | Avery Quinn | 1: Lekki>Victoria Island, Morgan Lee (+2348090000201, LND-482-KJ), 4850, PAY-2026-10-05-0001 card \| 2: Victoria Island>Lekki, cancelled |
| +2348030000102 | Tobi Adeyemi | 1: Yaba>Ikeja, Ifeanyi Bello (+2348090000202, EKY-115-AA), in progress |

The `trips` cell is a repeating group. You cannot filter by pickup zone, total the fares or check that a driver has only one active trip without pulling the text apart first.

## First normal form

Each trip gets its own row and every cell holds one value. The sheet numbered trips per rider, so the natural key is the pair (`rider_phone`, `trip_seq`).

| rider_phone | trip_seq | rider_name | pickup | dropoff | status | driver_phone | driver_name | plate | fare | payment_ref | method |
|---|---|---|---|---|---|---|---|---|---|---|---|
| …0101 | 1 | Avery Quinn | Lekki | Victoria Island | completed | …0201 | Morgan Lee | LND-482-KJ | 4850.00 | PAY-2026-10-05-0001 | card |
| …0101 | 2 | Avery Quinn | Victoria Island | Lekki | cancelled | | | | | | |
| …0102 | 1 | Tobi Adeyemi | Yaba | Ikeja | in_progress | …0202 | Ifeanyi Bello | EKY-115-AA | | | |

The values are now atomic, but Avery's name is stored twice. If she changed it, both rows would need updating, and missing one leaves the data contradicting itself.

## Second normal form

`rider_name` depends only on `rider_phone`, which is just part of the key. That is a partial dependency, so the rider moves to a table of its own.

**rider**

| rider_phone (PK) | rider_name |
|---|---|
| +2348030000101 | Avery Quinn |
| +2348030000102 | Tobi Adeyemi |

**trip** keeps (`rider_phone`, `trip_seq`) as its key along with every column that needs the whole key: zones, status, driver details, fare and payment details.

## Third normal form

Two indirect dependencies are left in the trip table.

The first runs key → `driver_phone` → `driver_name`, `vehicle_plate`. The driver's name and plate describe the driver, not the trip. If Morgan Lee drove fifty trips, the plate would be copied fifty times.

The second runs key → `payment_ref` → `payment_method`. The method describes the payment, not the trip.

Each moves out into its own table. The trip keeps a reference to its driver, and the payment points back to its trip.

**driver**

| driver_phone (PK) | driver_name | vehicle_plate (UK) |
|---|---|---|
| +2348090000201 | Morgan Lee | LND-482-KJ |
| +2348090000202 | Ifeanyi Bello | EKY-115-AA |

**trip**

| rider_phone (PK, FK) | trip_seq (PK) | driver_phone (FK) | pickup | dropoff | status | fare |
|---|---|---|---|---|---|---|
| …0101 | 1 | …0201 | Lekki | Victoria Island | completed | 4850.00 |
| …0101 | 2 | | Victoria Island | Lekki | cancelled | |
| …0102 | 1 | …0202 | Yaba | Ikeja | in_progress | |

**payment**

| payment_ref (PK) | rider_phone, trip_seq (FK, UK) | method |
|---|---|---|
| PAY-2026-10-05-0001 | …0101, 1 | card |

Every non-key column now depends on the key, the whole key, and nothing else.

## From 3NF to the final schema

The final schema in [`sql/01_schema.sql`](sql/01_schema.sql) keeps this 3NF shape with two changes.

First, the natural keys are replaced by integer identity keys (`rider_id`, `driver_id`, `trip_id`, `payment_id`). Phone numbers and plates change in real life, and a composite key such as (`rider_phone`, `trip_seq`) would have to be copied into every payment. The natural identifiers stay as `UNIQUE` columns, so duplicates are still blocked.

Second, rules that the spreadsheet relied on people to remember are now written into the database. These cover the status checks, the one-active-trip rule for drivers, and the rule that only completed trips can be paid.

One field is kept on purpose even though it looks like it could be derived. `payment.amount` repeats `trip.fare_amount`. The payment is a financial record of what was actually charged, so it should not change if someone edits the fare later. The trigger checks that the two match at the moment the payment is recorded.
