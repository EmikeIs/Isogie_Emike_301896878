// Run once in mongosh against a fresh exercise database.
// These records are fictional events for the case study.
(async function () {
  db = db.getSiblingDB('portfolio_nosql');
  if ((await db.getCollectionNames()).includes("trip_events")) {
    throw new Error('The exercise collection already exists. Use a fresh database.');
  }

  // The validator checks the stable event fields while details can vary.
  await db.createCollection("trip_events", {
    validator: {
    "$jsonSchema": {
        "bsonType": "object",
        "required": [
            "_id",
            "schemaVersion",
            "simulation",
            "eventType",
            "occurredAt",
            "source",
            "embedded",
            "references",
            "details"
        ],
        "properties": {
            "_id": {
                "bsonType": "string",
                "minLength": 1
            },
            "schemaVersion": {
                "enum": [
                    1
                ]
            },
            "simulation": {
                "enum": [
                    true
                ]
            },
            "eventType": {
                "bsonType": "string",
                "enum": [
                    "trip_requested",
                    "driver_assigned"
                ]
            },
            "occurredAt": {
                "bsonType": "date"
            },
            "source": {
                "bsonType": "object",
                "required": [
                    "entity",
                    "key",
                    "snapshot"
                ],
                "properties": {
                    "entity": {
                        "enum": [
                            "payment"
                        ]
                    },
                    "key": {
                        "bsonType": "object",
                        "required": [
                            "payment_id"
                        ]
                    },
                    "snapshot": {
                        "bsonType": "object"
                    }
                }
            },
            "embedded": {
                "bsonType": "object"
            },
            "references": {
                "bsonType": "object"
            },
            "details": {
                "bsonType": "object"
            }
        }
    }
},
    validationLevel: 'strict', validationAction: 'error'
  });

  // Insert the four example events and show their IDs.
  printjson(await db.getCollection("trip_events").insertMany([
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
    },
    {
        "_id": "event_000002",
        "schemaVersion": 1,
        "simulation": true,
        "eventType": "driver_assigned",
        "occurredAt": ISODate("2030-01-01T10:01:00Z"),
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
            "channel": "mobile",
            "note": "Illustrative event-specific metadata",
            "examples": {
                "location": "illustrative location",
                "route_summary": "illustrative route_summary",
                "surge_details": "illustrative surge_details",
                "fare_breakdown": "illustrative fare_breakdown"
            }
        }
    }
]));
  await db.getCollection("trip_events").createIndex({eventType: 1, occurredAt: -1}, {name: 'event_type_time'});

  // 1. Find the first sample event type (up to five documents).
  printjson(await db.getCollection("trip_events").find({"eventType":"trip_requested"}).sort({_id:1}).limit(5).toArray());

  // 2. Find events for the first source record using nested key fields (up to five).
  printjson(await db.getCollection("trip_events").find({"source.key.payment_id":6}).sort({_id:1}).limit(5).toArray());

  // 3. Find events in the sample time range using a MongoDB Date filter (up to five).
  printjson(await db.getCollection("trip_events").find({"occurredAt":{"$gte":ISODate("2030-01-01T10:00:00Z"), "$lt":ISODate("2030-01-01T11:00:00Z")}}).sort({_id:1}).limit(5).toArray());

  // 4. Count documents for each event type.
  printjson(await db.getCollection("trip_events").aggregate([{"$group":{"_id":"$eventType", "documentCount":{"$sum":1}}}, {"$sort":{"_id":1}}]).toArray());

  // A date stored as text should be rejected by the validator.
  try {
    await db.getCollection("trip_events").insertOne({...{
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
}, _id: 'invalid_date_example', occurredAt: 'not-a-date'});
  } catch (error) { print('Invalid date error: ' + error.code); }

  // Reusing an event ID should be rejected by the unique _id index.
  try { await db.getCollection("trip_events").insertOne({
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
}); }
  catch (error) { print('Duplicate ID error: ' + error.code); }

  print('Document count: ' + await db.getCollection("trip_events").countDocuments());
})().catch(error => { print(error.stack || String(error)); quit(1); });
