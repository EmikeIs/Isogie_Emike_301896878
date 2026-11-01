// Portfolio 2: table scan versus B-tree index on perf_trip.requested_at.
//
// Runs the same time-range query in two phases (without, then with, the
// index). Each phase does a few warm-up runs, then times RUNS executions and
// reports the median, so one slow run cannot skew the figure. It also saves
// each phase's EXPLAIN ANALYZE plan and checks that both phases return
// exactly the same trip IDs.
//
// Connection settings come from the standard PG* environment variables.
// Usage: node portfolio-2-query-optimisation/src/benchmark.js

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { Client } = require('pg');

const WARMUP = 5;
const RUNS = 31;
const INDEX = 'ix_perf_trip_requested_at';
const QUERY = `
SELECT trip_id, rider_id, pickup_zone, status, fare_amount
FROM perf_trip
WHERE requested_at >= '2026-10-01 00:00+01'
  AND requested_at <  '2026-10-03 00:00+01'`;

const here = path.join(__dirname, '..');
const resultsDir = path.join(here, 'results');
const plansDir = path.join(here, 'plans');

function median(values) {
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

async function timeQuery(client) {
  const start = process.hrtime.bigint();
  const res = await client.query(QUERY);
  const ms = Number(process.hrtime.bigint() - start) / 1e6;
  return { ms, rows: res.rows };
}

async function runPhase(client, label) {
  for (let i = 0; i < WARMUP; i++) await client.query(QUERY);

  const times = [];
  let rows = [];
  for (let i = 0; i < RUNS; i++) {
    const r = await timeQuery(client);
    times.push(r.ms);
    rows = r.rows;
  }

  const plan = await client.query(`EXPLAIN (ANALYZE, BUFFERS) ${QUERY}`);
  const planText = plan.rows.map((r) => r['QUERY PLAN']).join('\n');
  const topNode = planText.split('\n')[0].replace(/\s+\(cost.*$/, '').trim();

  const ids = rows.map((r) => r.trip_id).sort((a, b) => a - b);
  const digest = crypto.createHash('md5').update(ids.join(',')).digest('hex');

  return {
    phase: label,
    plan_node: topNode,
    uses_index: planText.includes(INDEX),
    rows_returned: rows.length,
    result_md5: digest,
    median_ms: Number(median(times).toFixed(3)),
    min_ms: Number(Math.min(...times).toFixed(3)),
    max_ms: Number(Math.max(...times).toFixed(3)),
    runs: RUNS,
    planText,
  };
}

async function main() {
  const client = new Client();
  await client.connect();
  await client.query("SET TIME ZONE 'Africa/Lagos'");

  const { rows: [info] } = await client.query(
    "SELECT current_setting('server_version') AS version, count(*)::int AS n FROM perf_trip");
  if (info.n !== 20000) throw new Error(`expected 20000 rows in perf_trip, found ${info.n}`);

  await client.query(`DROP INDEX IF EXISTS ${INDEX}`);
  await client.query('ANALYZE perf_trip');
  const scan = await runPhase(client, 'no index (table scan)');

  await client.query(`CREATE INDEX ${INDEX} ON perf_trip (requested_at)`);
  await client.query('ANALYZE perf_trip');
  const { rows: [size] } = await client.query(
    `SELECT pg_size_pretty(pg_relation_size('${INDEX}')) AS index_size,
            pg_size_pretty(pg_relation_size('perf_trip')) AS table_size`);
  const indexed = await runPhase(client, 'B-tree index');

  await client.end();

  fs.mkdirSync(resultsDir, { recursive: true });
  fs.mkdirSync(plansDir, { recursive: true });
  fs.writeFileSync(path.join(plansDir, 'benchmark_1_table_scan.txt'), scan.planText + '\n');
  fs.writeFileSync(path.join(plansDir, 'benchmark_2_btree_index.txt'), indexed.planText + '\n');

  const sameResult = scan.result_md5 === indexed.result_md5 && scan.rows_returned === indexed.rows_returned;
  const speedup = scan.median_ms / indexed.median_ms;

  const summary = {
    postgres_version: info.version,
    table_rows: info.n,
    table_size: size.table_size,
    index_size: size.index_size,
    query: QUERY.trim(),
    warmup_runs: WARMUP,
    timed_runs: RUNS,
    phases: [scan, indexed].map(({ planText, ...rest }) => rest),
    same_result: sameResult,
    median_speedup: Number(speedup.toFixed(2)),
  };
  fs.writeFileSync(path.join(resultsDir, 'benchmark.json'), JSON.stringify(summary, null, 2) + '\n');

  const md = [
    '# Benchmark result',
    '',
    `PostgreSQL ${info.version}. Table \`perf_trip\`: ${info.n} rows, ${size.table_size}. Index: ${size.index_size}.`,
    `Each phase: ${WARMUP} warm-up runs, then ${RUNS} timed runs. Times are client-measured round trips in milliseconds.`,
    '',
    '| Phase | Plan | Uses index | Rows | Median ms | Min ms | Max ms |',
    '|---|---|---|---|---|---|---|',
    ...summary.phases.map((p) =>
      `| ${p.phase} | ${p.plan_node} | ${p.uses_index ? 'yes' : 'no'} | ${p.rows_returned} | ${p.median_ms} | ${p.min_ms} | ${p.max_ms} |`),
    '',
    `Same trip IDs returned in both phases: **${sameResult ? 'yes' : 'NO'}** (md5 ${scan.result_md5}).`,
    `Median speed-up: **${summary.median_speedup}x**.`,
    '',
  ].join('\n');
  fs.writeFileSync(path.join(resultsDir, 'benchmark.md'), md);

  console.log(md);
  if (!sameResult) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
