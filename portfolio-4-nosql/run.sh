#!/usr/bin/env bash
# Portfolio 4: trip_events on MongoDB (or a MongoDB-compatible server).
# Set MONGODB_URI if the server is not on 127.0.0.1:27017.
# With mongosh installed, the same steps can be run directly:
#   mongosh "$MONGODB_URI/ridehailing" --file mongodb/trip_events.mongosh.js
set -euo pipefail
cd "$(dirname "$0")"
node src/run_trip_events.js > /dev/null
cat results/run_output.md
