#!/usr/bin/env bash
# Rebuilds the ridehailing database and saves the Portfolio 1 outputs.
# Connection settings come from the usual PG* variables (PGHOST, PGUSER ...).
set -euo pipefail
cd "$(dirname "$0")"

DB="${PGDATABASE:-ridehailing}"
export PGTZ="${PGTZ:-Africa/Lagos}"
PSQL=(psql -X -q -d "$DB" -v ON_ERROR_STOP=1)

dropdb --if-exists "$DB"
createdb "$DB"

"${PSQL[@]}" -f sql/01_schema.sql      2>/dev/null
"${PSQL[@]}" -f sql/02_sample_data.sql

mkdir -p results
psql -X -q -d "$DB" -f sql/03_constraint_tests.sql 2>&1 | sed -n '/== Constraint test results ==/,$p' > results/01_constraint_tests.txt
psql -X -d "$DB" -f sql/04_normalisation.sql    2>/dev/null | grep -v -E '^(CREATE|INSERT|SET|RESET|DROP)' > results/02_normalisation.txt
psql -X -d "$DB" -f sql/05_operations.sql       > results/03_operations.txt 2>&1

# Sample data as loaded, for reference.
{
  for t in rider driver trip payment; do
    echo "== $t =="
    psql -X -d "$DB" -c "SELECT * FROM $t ORDER BY 1"
  done
} > results/00_sample_data.txt

echo "Portfolio 1 done. Outputs in $(pwd)/results"
