# Portfolio 4 — NoSQL and Advanced Data Models

I used MongoDB collection trip_events for trip_requested and driver_assigned events. These are fictional event examples based on trip, rider, driver, payment.

## Document model

| Field | Meaning |
| --- | --- |
| _id | Unique string event ID |
| eventType | One of the two selected case event labels |
| occurredAt | Native BSON Date; sample timestamps are in 2030 |
| source | Original entity, primary key and saved JSON snapshot |
| embedded | Linked record snapshots read with the event |
| references | Keys for linked sources kept outside the embedded snapshots |
| details | Event metadata whose fields vary |

Related trip, rider details are stored as snapshots with the event. This makes an event readable in one document. It duplicates some information, and later SQL changes do not automatically update the snapshots. PostgreSQL continues to enforce the relational rules.

## Example document

```javascript
{
    "_id": "event_000001",
    "schemaVersion": 1,
    "simulation": true,
    "eventType": "trip_requested",
    "occurredAt": ISODate("2030-01-01T10:00:00Z"),
    "source": {
        "entity": "payment",
        "key": {
            "payment_id": 6
        },
        "snapshot": {
            "payment_id": 6,
            "trip_id": 4,
            "amount": 18.5,
            "paid_at": "2026-02-01T09:45:00Z",
            "method": "card",
            "payment_status": "paid"
        }
    },
    "embedded": {
        "trip": [
            {
                "key": {
                    "trip_id": 4
                },
                "snapshot": {
                    "trip_id": 4,
                    "rider_id": 1,
                    "driver_id": 2,
                    "requested_at": "2026-02-01T09:00:00Z",
                    "pickup_zone": "Cedar Square",
                    "dropoff_zone": "Maple Station",
                    "fare": 18.5,
                    "status": "assigned"
                },
                "via": [
                    "payment.trip_id → trip"
                ]
            }
        ],
        "rider": [
            {
                "key": {
                    "rider_id": 1
                },
                "snapshot": {
                    "rider_id": 1,
                    "display_name": "Avery Quinn",
                    "joined_on": "2026-01-10"
                },
                "via": [
                    "payment.trip_id → trip.rider_id → rider"
                ]
            }
        ]
    },
    "references": {
        "driver": [
            {
                "key": {
                    "driver_id": 2
                },
                "via": [
                    "payment.trip_id → trip.driver_id → driver"
                ]
            }
        ]
    },
    "details": {
        "channel": "web"
    }
}
```

## Queries and results

| Query | Returned documents |
| --- | --- |
| Find the first sample event type (up to five documents). | 1 |
| Find events for the first source record using nested key fields (up to five). | 2 |
| Find events in the sample time range using a MongoDB Date filter (up to five). | 2 |
| Count documents for each event type. | 2 |

## 1. Find the first sample event type (up to five documents).

```javascript
db.getCollection("trip_events").find({"eventType":"trip_requested"}).sort({_id:1}).limit(5).toArray();
```

Selected fields from the returned documents:

```json
[
  {
    "_id": "event_000001",
    "eventType": "trip_requested",
    "occurredAt": {
      "$date": "2030-01-01T10:00:00Z"
    },
    "source": {
      "payment_id": 6
    }
  }
]
```

## 2. Find events for the first source record using nested key fields (up to five).

```javascript
db.getCollection("trip_events").find({"source.key.payment_id":6}).sort({_id:1}).limit(5).toArray();
```

Selected fields from the returned documents:

```json
[
  {
    "_id": "event_000001",
    "eventType": "trip_requested",
    "occurredAt": {
      "$date": "2030-01-01T10:00:00Z"
    },
    "source": {
      "payment_id": 6
    }
  },
  {
    "_id": "event_000002",
    "eventType": "driver_assigned",
    "occurredAt": {
      "$date": "2030-01-01T10:01:00Z"
    },
    "source": {
      "payment_id": 6
    }
  }
]
```

## 3. Find events in the sample time range using a MongoDB Date filter (up to five).

```javascript
db.getCollection("trip_events").find({"occurredAt":{"$gte":ISODate("2030-01-01T10:00:00Z"), "$lt":ISODate("2030-01-01T11:00:00Z")}}).sort({_id:1}).limit(5).toArray();
```

Selected fields from the returned documents:

```json
[
  {
    "_id": "event_000001",
    "eventType": "trip_requested",
    "occurredAt": {
      "$date": "2030-01-01T10:00:00Z"
    },
    "source": {
      "payment_id": 6
    }
  },
  {
    "_id": "event_000002",
    "eventType": "driver_assigned",
    "occurredAt": {
      "$date": "2030-01-01T10:01:00Z"
    },
    "source": {
      "payment_id": 6
    }
  }
]
```

## 4. Count documents for each event type.

```javascript
db.getCollection("trip_events").aggregate([{"$group":{"_id":"$eventType", "documentCount":{"$sum":1}}}, {"$sort":{"_id":1}}]).toArray();
```

| _id | documentCount |
| --- | --- |
| driver_assigned | 1 |
| trip_requested | 1 |

## Validation and suitability

MongoDB inserted 2 documents. An invalid date type was rejected with code 121 and a repeated event ID with 11000. The collection still contained 2 valid documents. The compound eventType/occurredAt index supports those access fields; this exercise does not measure its speed.

The details field can vary across event types, while the common fields have a validator. Events can be added as separate documents rather than growing one large history record.

## Run the script

Connect mongosh to a fresh exercise database and run Isogie_Emike_301896878_P4_MongoDB.js. It selects portfolio_nosql, creates the collection, inserts the sample documents and displays the query results. [Implementation evidence](screenshots/Isogie_Emike_301896878_P4_DocumentsAndQueries.png).

## References

- [MongoDB — data modelling](https://www.mongodb.com/docs/manual/data-modeling/)

