# trip_events run

Server reports MongoDB 7.0.42 (FerretDB v1.24.0 on PostgreSQL).

## Setup

- createCollection with $jsonSchema validator: NOT SUPPORTED by this server (create)
- createCollection without validator: ok
- unique index uq_event_id on event_id: ok
- index ix_trip_time on (trip_id, occurred_at): ok

Inserted: **2** events.

## Q1. Timeline for trip 1

```js
db.trip_events.find({trip_id: 1}).sort({occurred_at: 1})
```

```json
[
  {
    "event_id": "EVT-0001",
    "event_type": "trip_requested",
    "occurred_at": "2026-10-05T06:40:00.000Z"
  },
  {
    "event_id": "EVT-0002",
    "event_type": "trip_completed",
    "occurred_at": "2026-10-05T07:21:00.000Z"
  }
]
```

## Q2. Completed trips with a fare above 4000

```js
db.trip_events.find({event_type: 'trip_completed', 'details.fare_amount': {$gt: 4000}})
```

```json
[
  {
    "trip_id": 1,
    "driver": {
      "name": "Morgan Lee"
    },
    "details": {
      "fare_amount": 4850
    }
  }
]
```

## Q3. Event count by type

```js
db.trip_events.aggregate([{$group: {_id: '$event_type', events: {$sum: 1}}}, {$sort: {_id: 1}}])
```

```json
[
  {
    "_id": "trip_completed",
    "events": 1
  },
  {
    "_id": "trip_requested",
    "events": 1
  }
]
```

## Q4. Events handled by driver 1 (embedded snapshot)

```js
db.trip_events.find({'driver.driver_id': 1})
```

```json
[
  {
    "event_id": "EVT-0002",
    "rider": {
      "name": "Avery Quinn"
    },
    "driver": {
      "vehicle_plate": "LND-482-KJ"
    }
  }
]
```

## Validation tests

| Test | Expected | Outcome | Code |
|---|---|---|---|
| V1. occurred_at stored as a string | rejected by $jsonSchema (code 121 DocumentValidationFailure) | ACCEPTED (validator not active on this server; not verified here) |   |
| V2. duplicate event_id EVT-0001 | rejected by unique index (code 11000 DuplicateKey) | rejected | 11000  |

Documents left in collection: 2.

## Notes

The server did not accept the $jsonSchema validator, so test V1 above is not evidence of validation. Run mongodb/trip_events.mongosh.js on MongoDB 6 or 7 to verify it.
