#!/usr/bin/env bash
# Runs portfolios 1 to 4 in order and regenerates every results/ folder.
# Portfolio 5 is a design exercise with nothing to execute.
#
# Needs: PostgreSQL 14+ (PG* variables set), Node 18+, `npm install` done,
# and a MongoDB server for Portfolio 4 (MONGODB_URI, default 127.0.0.1:27017).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
export PGDATABASE="${PGDATABASE:-ridehailing}"
export PGTZ="${PGTZ:-Africa/Lagos}"

"$root/portfolio-1-database-design/run.sh"
"$root/portfolio-2-query-optimisation/run.sh"
"$root/portfolio-3-transactions-concurrency/run.sh" > /dev/null
"$root/portfolio-4-nosql/run.sh" > /dev/null
echo "All portfolios run. See each results/ folder."
