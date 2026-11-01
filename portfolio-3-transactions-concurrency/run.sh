#!/usr/bin/env bash
# Portfolio 3: two-session transaction and concurrency experiments.
# Needs the Portfolio 1 database and `npm install` at the repository root.
set -euo pipefail
cd "$(dirname "$0")"
export PGDATABASE="${PGDATABASE:-ridehailing}"
mkdir -p results
node src/two_sessions.js | tee results/console.txt
