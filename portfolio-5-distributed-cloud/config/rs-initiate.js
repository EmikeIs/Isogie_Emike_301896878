// Initiates the proposed replica set. Not run for this portfolio.
// Three voting members, one per failure zone. Any two can elect a primary,
// so losing one zone keeps the set writable.
rs.initiate({
  _id: 'rh-events',
  members: [
    { _id: 0, host: 'mongo-a:27017', priority: 2, tags: { zone: 'zone-a' } },
    { _id: 1, host: 'mongo-b:27017', priority: 1, tags: { zone: 'zone-b' } },
    { _id: 2, host: 'mongo-c:27017', priority: 1, tags: { zone: 'zone-c' } },
  ],
  settings: {
    // A secondary calls an election if it cannot reach the primary for 10 s.
    electionTimeoutMillis: 10000,
  },
});

// Writes are acknowledged only once a majority (2 of 3) hold them, so an
// acknowledged trip event survives the loss of any single member.
db.adminCommand({
  setDefaultRWConcern: 1,
  defaultWriteConcern: { w: 'majority', wtimeout: 5000 },
  defaultReadConcern: { level: 'majority' },
});
