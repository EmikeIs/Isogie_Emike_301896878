// Sharding option for trip_events, for when one replica set is no longer
// enough. Not run for this portfolio; it needs a sharded cluster (config
// servers plus mongos), which the three-member design above does not include.

sh.enableSharding('ridehailing');

// Chosen key: hashed trip_id.
//  + writes for new trips spread evenly across shards (no single hot shard)
//  + "all events for trip X" goes to exactly one shard
//  - a time-range query across many trips goes to every shard
db.getSiblingDB('ridehailing').trip_events.createIndex({ trip_id: 'hashed' });
sh.shardCollection('ridehailing.trip_events', { trip_id: 'hashed' });

// Rejected alternative: { occurred_at: 1 }.
// Every new event has the latest timestamp, so all inserts would land on the
// shard holding the top range: a single hot shard.
//
// Considered alternative: { pickup_zone: 1, occurred_at: 1 }.
// Good for zone reports, but zones are few and uneven (Lekki is much busier
// than Apapa), so chunks would grow lopsided.
