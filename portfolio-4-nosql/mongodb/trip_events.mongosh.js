// Portfolio 4: trip_events collection for MongoDB.
// Run with:  mongosh "mongodb://localhost:27017/ridehailing" --file trip_events.mongosh.js
//
// Each document is one thing that happened to a trip. Rider and driver
// details are copied in as they were at that moment (a snapshot), and the
// `details` field changes shape with the event type.

const dbName = 'ridehailing';
const rh = db.getSiblingDB(dbName);

rh.trip_events.drop();

// ---------------------------------------------------------------- schema validation
rh.createCollection('trip_events', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['event_id', 'trip_id', 'event_type', 'occurred_at', 'rider'],
      properties: {
        event_id:    { bsonType: 'string', pattern: '^EVT-[0-9]{4,}$' },
        trip_id:     { bsonType: 'int', minimum: 1 },
        event_type:  { enum: ['trip_requested', 'driver_assigned', 'trip_started', 'trip_completed', 'trip_cancelled'] },
        occurred_at: { bsonType: 'date' },
        rider: {
          bsonType: 'object',
          required: ['rider_id', 'name'],
          properties: { rider_id: { bsonType: 'int' }, name: { bsonType: 'string' } },
        },
        driver: {
          bsonType: 'object',
          required: ['driver_id', 'name', 'vehicle_plate'],
          properties: {
            driver_id: { bsonType: 'int' },
            name: { bsonType: 'string' },
            vehicle_plate: { bsonType: 'string' },
          },
        },
        details: { bsonType: 'object' },
      },
    },
  },
  validationLevel: 'strict',
  validationAction: 'error',
});

rh.trip_events.createIndex({ event_id: 1 }, { unique: true, name: 'uq_event_id' });
rh.trip_events.createIndex({ trip_id: 1, occurred_at: 1 }, { name: 'ix_trip_time' });

// ---------------------------------------------------------------- sample events
// Both events describe trip 1 from the PostgreSQL sample data.
const inserted = rh.trip_events.insertMany([
  {
    event_id: 'EVT-0001',
    trip_id: NumberInt(1),
    event_type: 'trip_requested',
    occurred_at: ISODate('2026-10-05T06:40:00Z'),
    rider: { rider_id: NumberInt(1), name: 'Avery Quinn' },
    details: {
      pickup:  { zone: 'Lekki', location: { type: 'Point', coordinates: [3.4746, 6.4474] } },
      dropoff: { zone: 'Victoria Island' },
      vehicle_type: 'sedan',
      estimated_fare: 4500,
    },
  },
  {
    event_id: 'EVT-0002',
    trip_id: NumberInt(1),
    event_type: 'trip_completed',
    occurred_at: ISODate('2026-10-05T07:21:00Z'),
    rider:  { rider_id: NumberInt(1), name: 'Avery Quinn' },
    driver: { driver_id: NumberInt(1), name: 'Morgan Lee', vehicle_plate: 'LND-482-KJ', rating_at_time: 4.8 },
    details: {
      distance_km: 12.4,
      duration_min: 29,
      fare_amount: 4850,
      payment: { method: 'card', reference: 'PAY-2026-10-05-0001' },
    },
  },
]);
print(`Inserted: ${Object.keys(inserted.insertedIds).length}`);

// ---------------------------------------------------------------- queries
print('\nQ1. Timeline for trip 1');
printjson(rh.trip_events.find({ trip_id: 1 }, { _id: 0, event_id: 1, event_type: 1, occurred_at: 1 })
  .sort({ occurred_at: 1 }).toArray());

print('\nQ2. Completed trips with a fare above 4000 (field inside details)');
printjson(rh.trip_events.find(
  { event_type: 'trip_completed', 'details.fare_amount': { $gt: 4000 } },
  { _id: 0, trip_id: 1, 'driver.name': 1, 'details.fare_amount': 1 }).toArray());

print('\nQ3. Event count by type');
printjson(rh.trip_events.aggregate([
  { $group: { _id: '$event_type', events: { $sum: 1 } } },
  { $sort: { _id: 1 } },
]).toArray());

print('\nQ4. Events handled by driver 1, read from the embedded snapshot');
printjson(rh.trip_events.find(
  { 'driver.driver_id': 1 },
  { _id: 0, event_id: 1, 'rider.name': 1, 'driver.vehicle_plate': 1 }).toArray());

// ---------------------------------------------------------------- validation tests
print('\nV1. occurred_at stored as a string instead of a date');
try {
  rh.trip_events.insertOne({
    event_id: 'EVT-0003', trip_id: NumberInt(2), event_type: 'trip_started',
    occurred_at: '2026-10-05 08:14', rider: { rider_id: NumberInt(2), name: 'Tobi Adeyemi' },
  });
  print('ACCEPTED (unexpected)');
} catch (e) {
  print(`rejected: code ${e.code} ${e.codeName || ''}`);
}

print('\nV2. duplicate event_id');
try {
  rh.trip_events.insertOne({
    event_id: 'EVT-0001', trip_id: NumberInt(1), event_type: 'trip_requested',
    occurred_at: new Date(), rider: { rider_id: NumberInt(1), name: 'Avery Quinn' },
  });
  print('ACCEPTED (unexpected)');
} catch (e) {
  print(`rejected: code ${e.code} ${e.codeName || ''}`);
}

print(`\nDocuments in collection: ${rh.trip_events.countDocuments()}`);
