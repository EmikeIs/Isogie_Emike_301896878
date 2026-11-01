#!/usr/bin/env bash
# Portfolio 2: runs the three queries with their plans, loads the 20,000-row
# performance table and runs the scan-versus-index benchmark.
# Needs the Portfolio 1 database (run ../portfolio-1-database-design/run.sh first)
# and `npm install` at the repository root.
set -euo pipefail
cd "$(dirname "$0")"
export PGDATABASE="${PGDATABASE:-ridehailing}"
export PGTZ="${PGTZ:-Africa/Lagos}"

mkdir -p results plans
psql -X -q -v ON_ERROR_STOP=1 -f sql/01_queries.sql    > results/01_queries_and_plans.txt
psql -X -q -v ON_ERROR_STOP=1 -f sql/02_perf_setup.sql > results/02_perf_setup.txt 2>/dev/null
node src/benchmark.js > /dev/null
echo "Portfolio 2 done."
cat results/benchmark.md
