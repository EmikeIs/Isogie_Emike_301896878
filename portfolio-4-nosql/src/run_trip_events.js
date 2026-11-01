// Portfolio 4: Node.js runner for the trip_events collection.
//
// Does the same work as mongodb/trip_events.mongosh.js, but records every
// step to results/ so the evidence can be committed. It connects to
// MONGODB_URI (default mongodb://127.0.0.1:27017).
//
// If the server does not support $jsonSchema validators (some MongoDB-
// compatible servers, such as FerretDB, do not), the run says so in the
// results instead of hiding it, and the date-type test is marked as not
// verified on that server.

const fs = require('node:fs');
const path = require('node:path');
const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
const out = { server: {}, setup: [], inserted: 0, queries: [], validation: [], notes: [] };

const schema = {
  bsonType: 'object',
  required: ['event_id', 'trip_id', 'event_type', 'occurred_at', 'rider'],
  properties: {
    event_id: { bsonType: 'string', pattern: '^EVT-[0-9]{4,}$' },
    trip_id: { bsonType: 'int', minimum: 1 },
    event_type: { enum: ['trip_requested', 'driver_assigned', 'trip_started', 'trip_completed', 'trip_cancelled'] },
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
        driver_id: { bsonType: 'int' }, name: { bsonType: 'string' }, vehicle_plate: { bsonType: 'string' },
      },
    },
    details: { bsonType: 'object' },
  },
};

const events = [
  {
    event_id: 'EVT-0001',
    trip_id: 1,
    event_type: 'trip_requested',
    occurred_at: new Date('2026-10-05T06:40:00Z'),
    rider: { rider_id: 1, name: 'Avery Quinn' },
    details: {
      pickup: { zone: 'Lekki', location: { type: 'Point', coordinates: [3.4746, 6.4474] } },
      dropoff: { zone: 'Victoria Island' },
      vehicle_type: 'sedan',
      estimated_fare: 4500,
    },
  },
  {
    event_id: 'EVT-0002',
    trip_id: 1,
    event_type: 'trip_completed',
    occurred_at: new Date('2026-10-05T07:21:00Z'),
    rider: { rider_id: 1, name: 'Avery Quinn' },
    driver: { driver_id: 1, name: 'Morgan Lee', vehicle_plate: 'LND-482-KJ', rating_at_time: 4.8 },
    details: {
      distance_km: 12.4,
      duration_min: 29,
      fare_amount: 4850,
      payment: { method: 'card', reference: 'PAY-2026-10-05-0001' },
    },
  },
];

async function tryInsert(coll, label, doc, expect) {
  try {
    await coll.insertOne(doc);
    out.validation.push({ test: label, expected: expect, outcome: 'ACCEPTED' });
  } catch (e) {
    out.validation.push({ test: label, expected: expect, outcome: 'rejected', code: e.code, codeName: e.codeName || null });
  }
}

async function main() {
  const client = new MongoClient(uri, { serverSelectionTimeoutMS: 5000 });
  await client.connect();
  const db = client.db('ridehailing');

  const info = await db.admin().command({ buildInfo: 1 });
  out.server = { reported_version: info.version, ferretdb: info.ferretdbVersion || null };

  await db.collection('trip_events').drop().catch(() => {});

  let validatorActive = true;
  try {
    await db.createCollection('trip_events', {
      validator: { $jsonSchema: schema }, validationLevel: 'strict', validationAction: 'error',
    });
    out.setup.push('createCollection with $jsonSchema validator: ok');
  } catch (e) {
    validatorActive = false;
    out.setup.push(`createCollection with $jsonSchema validator: NOT SUPPORTED by this server (${e.message.split(':')[0]})`);
    out.notes.push('The server did not accept the $jsonSchema validator, so test V1 above is not evidence of validation. Run mongodb/trip_events.mongosh.js on MongoDB 6 or 7 to verify it.');
    await db.createCollection('trip_events');
    out.setup.push('createCollection without validator: ok');
  }

  const coll = db.collection('trip_events');
  await coll.createIndex({ event_id: 1 }, { unique: true, name: 'uq_event_id' });
  await coll.createIndex({ trip_id: 1, occurred_at: 1 }, { name: 'ix_trip_time' });
  out.setup.push('unique index uq_event_id on event_id: ok', 'index ix_trip_time on (trip_id, occurred_at): ok');

  const ins = await coll.insertMany(events);
  out.inserted = ins.insertedCount;

  const q = async (label, query, run) => {
    const result = await run();
    out.queries.push({ label, query, result });
  };

  await q('Q1. Timeline for trip 1',
    'find({trip_id: 1}).sort({occurred_at: 1})',
    () => coll.find({ trip_id: 1 }, { projection: { _id: 0, event_id: 1, event_type: 1, occurred_at: 1 } })
      .sort({ occurred_at: 1 }).toArray());

  await q('Q2. Completed trips with a fare above 4000',
    "find({event_type: 'trip_completed', 'details.fare_amount': {$gt: 4000}})",
    () => coll.find({ event_type: 'trip_completed', 'details.fare_amount': { $gt: 4000 } },
      { projection: { _id: 0, trip_id: 1, 'driver.name': 1, 'details.fare_amount': 1 } }).toArray());

  await q('Q3. Event count by type',
    "aggregate([{$group: {_id: '$event_type', events: {$sum: 1}}}, {$sort: {_id: 1}}])",
    () => coll.aggregate([{ $group: { _id: '$event_type', events: { $sum: 1 } } }, { $sort: { _id: 1 } }]).toArray());

  await q('Q4. Events handled by driver 1 (embedded snapshot)',
    "find({'driver.driver_id': 1})",
    () => coll.find({ 'driver.driver_id': 1 },
      { projection: { _id: 0, event_id: 1, 'rider.name': 1, 'driver.vehicle_plate': 1 } }).toArray());

  await tryInsert(coll, 'V1. occurred_at stored as a string', {
    event_id: 'EVT-0003', trip_id: 2, event_type: 'trip_started', occurred_at: '2026-10-05 08:14',
    rider: { rider_id: 2, name: 'Tobi Adeyemi' },
  }, 'rejected by $jsonSchema (code 121 DocumentValidationFailure)');
  if (!validatorActive) out.validation[out.validation.length - 1].note = 'validator not active on this server; not verified here';

  await tryInsert(coll, 'V2. duplicate event_id EVT-0001', {
    event_id: 'EVT-0001', trip_id: 1, event_type: 'trip_requested', occurred_at: new Date(),
    rider: { rider_id: 1, name: 'Avery Quinn' },
  }, 'rejected by unique index (code 11000 DuplicateKey)');

  // Remove anything V1 let through on a server without validation, so the
  // collection ends with just the two sample events.
  await coll.deleteMany({ event_id: { $nin: ['EVT-0001', 'EVT-0002'] } });
  out.final_count = await coll.countDocuments();

  const plan = await coll.find({ trip_id: 1 }).sort({ occurred_at: 1 }).explain('queryPlanner');
  out.q1_winning_plan = JSON.stringify(plan.queryPlanner?.winningPlan ?? plan).slice(0, 400);

  await client.close();
  write();
}

function write() {
  const dir = path.join(__dirname, '..', 'results');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'run_output.json'), JSON.stringify(out, null, 2) + '\n');

  const L = ['# trip_events run', ''];
  L.push(`Server reports MongoDB ${out.server.reported_version}` +
    (out.server.ferretdb ? ` (FerretDB ${out.server.ferretdb} on PostgreSQL)` : '') + '.', '');
  L.push('## Setup', '', ...out.setup.map((s) => `- ${s}`), '', `Inserted: **${out.inserted}** events.`, '');
  for (const r of out.queries) {
    L.push(`## ${r.label}`, '', '```js', `db.trip_events.${r.query}`, '```', '', '```json', JSON.stringify(r.result, null, 2), '```', '');
  }
  L.push('## Validation tests', '', '| Test | Expected | Outcome | Code |', '|---|---|---|---|');
  for (const v of out.validation) {
    L.push(`| ${v.test} | ${v.expected} | ${v.outcome}${v.note ? ` (${v.note})` : ''} | ${v.code ?? ''} ${v.codeName ?? ''} |`);
  }
  L.push('', `Documents left in collection: ${out.final_count}.`, '');
  if (out.notes.length) L.push('## Notes', '', ...out.notes, '');
  fs.writeFileSync(path.join(dir, 'run_output.md'), L.join('\n'));
  console.log(L.join('\n'));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
