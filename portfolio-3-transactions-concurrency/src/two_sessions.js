// Portfolio 3: transactions and concurrency with two real database sessions.
//
// Session A and Session B are two separate connections to PostgreSQL, the
// same as two dispatchers working at once. They share one helper column,
// trip.demo_counter, on trip 1. The column is added at the start and dropped
// at the end, and the script checks that the trip's real fields are the same
// afterwards.
//
// Experiments
//   1. COMMIT makes a change permanent and visible to the other session.
//   2. ROLLBACK discards a change; under READ COMMITTED the other session
//      never sees the uncommitted value.
//   3. Lost update: both sessions read, then both write. One increment is lost.
//   4. SELECT ... FOR UPDATE: Session B waits for Session A's lock and both
//      increments survive.
//   5. REPEATABLE READ: the same race as 3, but PostgreSQL refuses the second
//      write with a serialization error instead of losing it.
//
// Connection settings come from the PG* environment variables.

const fs = require('node:fs');
const path = require('node:path');
const { Client } = require('pg');

const TRIP_ID = 1;
const log = [];
let stepNo = 0;

function record(session, action, result) {
  stepNo += 1;
  log.push({ step: stepNo, session, action, result: result ?? '' });
  console.log(`${String(stepNo).padStart(3)}  ${session.padEnd(2)}  ${action.padEnd(62)}  ${result ?? ''}`);
}

function section(title) {
  log.push({ section: title });
  console.log(`\n== ${title} ==`);
}

async function counter(client) {
  const r = await client.query('SELECT demo_counter FROM trip WHERE trip_id = $1', [TRIP_ID]);
  return r.rows[0].demo_counter;
}

async function sessionWaitEvent(observer, pid) {
  const r = await observer.query(
    'SELECT wait_event_type, wait_event, state FROM pg_stat_activity WHERE pid = $1', [pid]);
  const row = r.rows[0] || {};
  return `${row.wait_event_type ?? '-'} / ${row.wait_event ?? '-'} (${row.state})`;
}

async function main() {
  const a = new Client({ application_name: 'session_A' });
  const b = new Client({ application_name: 'session_B' });
  const observer = new Client({ application_name: 'observer' });
  await Promise.all([a.connect(), b.connect(), observer.connect()]);
  const pidB = (await b.query('SELECT pg_backend_pid() AS pid')).rows[0].pid;

  const fingerprintSql = `SELECT md5(string_agg(row_to_json(x)::text, '|' ORDER BY trip_id)) AS h
     FROM (SELECT trip_id, rider_id, driver_id, pickup_zone, dropoff_zone, status,
                  requested_at, started_at, completed_at, distance_km, fare_amount FROM trip) x`;
  const before = (await observer.query(fingerprintSql)).rows[0].h;

  const { rows: [iso] } = await a.query('SHOW transaction_isolation');

  section('Setup');
  await observer.query('ALTER TABLE trip DROP COLUMN IF EXISTS demo_counter');
  await observer.query('ALTER TABLE trip ADD COLUMN demo_counter integer NOT NULL DEFAULT 0');
  record('--', 'ALTER TABLE trip ADD COLUMN demo_counter integer DEFAULT 0', 'helper column added');
  record('--', 'SHOW transaction_isolation', iso.transaction_isolation);

  // 1. COMMIT
  section('1. COMMIT');
  await a.query('BEGIN');
  record('A', 'BEGIN');
  await a.query('UPDATE trip SET demo_counter = 1 WHERE trip_id = $1', [TRIP_ID]);
  record('A', 'UPDATE trip SET demo_counter = 1 WHERE trip_id = 1', 'UPDATE 1');
  record('B', 'SELECT demo_counter  (A not yet committed)', `sees ${await counter(b)}`);
  await a.query('COMMIT');
  record('A', 'COMMIT');
  record('B', 'SELECT demo_counter  (after A commits)', `sees ${await counter(b)}`);

  // 2. ROLLBACK and READ COMMITTED visibility
  section('2. ROLLBACK and READ COMMITTED');
  await a.query('BEGIN');
  record('A', 'BEGIN');
  await a.query('UPDATE trip SET demo_counter = 99 WHERE trip_id = $1', [TRIP_ID]);
  record('A', 'UPDATE trip SET demo_counter = 99 WHERE trip_id = 1', 'UPDATE 1');
  record('A', 'SELECT demo_counter  (inside its own transaction)', `sees ${await counter(a)}`);
  record('B', 'SELECT demo_counter  (A still open)', `sees ${await counter(b)}  <- uncommitted 99 hidden`);
  await a.query('ROLLBACK');
  record('A', 'ROLLBACK');
  record('A', 'SELECT demo_counter', `sees ${await counter(a)}`);
  record('B', 'SELECT demo_counter', `sees ${await counter(b)}`);
  const afterRollback = await counter(observer);

  // 3. Lost update
  section('3. Lost update without locking');
  await observer.query('UPDATE trip SET demo_counter = 1 WHERE trip_id = $1', [TRIP_ID]);
  record('--', 'reset demo_counter to 1');
  await a.query('BEGIN');
  await b.query('BEGIN');
  record('A', 'BEGIN');
  record('B', 'BEGIN');
  const readA = await counter(a);
  record('A', 'SELECT demo_counter', `reads ${readA}`);
  const readB = await counter(b);
  record('B', 'SELECT demo_counter', `reads ${readB}`);
  await a.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [readA + 1, TRIP_ID]);
  record('A', `UPDATE ... SET demo_counter = ${readA + 1}  (its read + 1)`, 'UPDATE 1');
  await a.query('COMMIT');
  record('A', 'COMMIT');
  await b.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [readB + 1, TRIP_ID]);
  record('B', `UPDATE ... SET demo_counter = ${readB + 1}  (its stale read + 1)`, 'UPDATE 1');
  await b.query('COMMIT');
  record('B', 'COMMIT');
  const lost = await counter(observer);
  record('--', 'final demo_counter', `${lost}  (two increments from 1 should give 3)`);

  // 4. SELECT ... FOR UPDATE
  section('4. SELECT ... FOR UPDATE');
  await observer.query('UPDATE trip SET demo_counter = 1 WHERE trip_id = $1', [TRIP_ID]);
  record('--', 'reset demo_counter to 1');
  await a.query('BEGIN');
  await b.query('BEGIN');
  record('A', 'BEGIN');
  record('B', 'BEGIN');
  const lockedA = (await a.query(
    'SELECT demo_counter FROM trip WHERE trip_id = $1 FOR UPDATE', [TRIP_ID])).rows[0].demo_counter;
  record('A', 'SELECT demo_counter ... FOR UPDATE', `reads ${lockedA}, holds row lock`);

  const t0 = Date.now();
  const bRead = b.query('SELECT demo_counter FROM trip WHERE trip_id = $1 FOR UPDATE', [TRIP_ID]);
  record('B', 'SELECT demo_counter ... FOR UPDATE', 'sent');
  await new Promise((r) => setTimeout(r, 300));
  record('--', 'pg_stat_activity for session B', await sessionWaitEvent(observer, pidB));

  await a.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [lockedA + 1, TRIP_ID]);
  record('A', `UPDATE ... SET demo_counter = ${lockedA + 1}`, 'UPDATE 1');
  await a.query('COMMIT');
  record('A', 'COMMIT  (releases the lock)');

  const lockedB = (await bRead).rows[0].demo_counter;
  const waited = Date.now() - t0;
  record('B', 'SELECT ... FOR UPDATE returns', `reads ${lockedB} after waiting ~${waited} ms`);
  await b.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [lockedB + 1, TRIP_ID]);
  record('B', `UPDATE ... SET demo_counter = ${lockedB + 1}`, 'UPDATE 1');
  await b.query('COMMIT');
  record('B', 'COMMIT');
  const locked = await counter(observer);
  record('--', 'final demo_counter', `${locked}  (both increments kept)`);

  // 5. REPEATABLE READ
  section('5. Same race under REPEATABLE READ');
  await observer.query('UPDATE trip SET demo_counter = 1 WHERE trip_id = $1', [TRIP_ID]);
  record('--', 'reset demo_counter to 1');
  await a.query('BEGIN ISOLATION LEVEL REPEATABLE READ');
  await b.query('BEGIN ISOLATION LEVEL REPEATABLE READ');
  record('A', 'BEGIN ISOLATION LEVEL REPEATABLE READ');
  record('B', 'BEGIN ISOLATION LEVEL REPEATABLE READ');
  const rrA = await counter(a);
  record('A', 'SELECT demo_counter', `reads ${rrA}`);
  const rrB = await counter(b);
  record('B', 'SELECT demo_counter', `reads ${rrB}`);
  await a.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [rrA + 1, TRIP_ID]);
  record('A', `UPDATE ... SET demo_counter = ${rrA + 1}`, 'UPDATE 1');
  await a.query('COMMIT');
  record('A', 'COMMIT');
  let rrOutcome;
  try {
    await b.query('UPDATE trip SET demo_counter = $1 WHERE trip_id = $2', [rrB + 1, TRIP_ID]);
    rrOutcome = 'accepted';
    record('B', `UPDATE ... SET demo_counter = ${rrB + 1}`, 'UPDATE 1 (unexpected)');
    await b.query('COMMIT');
  } catch (err) {
    rrOutcome = `${err.code} ${err.message}`;
    record('B', `UPDATE ... SET demo_counter = ${rrB + 1}`, `ERROR ${err.code}: ${err.message}`);
    await b.query('ROLLBACK');
    record('B', 'ROLLBACK  (the application would retry the whole transaction)');
  }
  const rr = await counter(observer);
  record('--', 'final demo_counter', `${rr}  (B's stale write refused, not lost silently)`);

  // Clean up
  section('Clean up');
  await observer.query('ALTER TABLE trip DROP COLUMN demo_counter');
  record('--', 'ALTER TABLE trip DROP COLUMN demo_counter', 'helper column removed');
  const after = (await observer.query(fingerprintSql)).rows[0].h;
  record('--', 'compare trip business fields before and after', before === after ? `identical (md5 ${after})` : 'CHANGED');

  await Promise.all([a.end(), b.end(), observer.end()]);

  const summary = {
    default_isolation: iso.transaction_isolation,
    after_rollback: afterRollback,
    lost_update_final: lost,
    for_update_final: locked,
    for_update_wait_ms: waited,
    repeatable_read_second_writer: rrOutcome,
    repeatable_read_final: rr,
    business_fields_unchanged: before === after,
  };
  writeOutputs(summary);
  const ok = afterRollback === 1 && lost === 2 && locked === 3 && rr === 2 && before === after;
  if (!ok) process.exitCode = 1;
}

function writeOutputs(summary) {
  const dir = path.join(__dirname, '..', 'results');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'summary.json'), JSON.stringify(summary, null, 2) + '\n');

  const lines = ['# Two-session timeline', '', 'Generated by `src/two_sessions.js`. A and B are separate connections; `--` is the setup/observer connection.', ''];
  let open = false;
  for (const e of log) {
    if (e.section) {
      lines.push('', `## ${e.section}`, '', '| Step | Session | Action | Result |', '|---|---|---|---|');
      open = true;
      continue;
    }
    const esc = (s) => String(s).replace(/\|/g, '\\|');
    lines.push(`| ${e.step} | ${e.session} | \`${esc(e.action)}\` | ${esc(e.result)} |`);
  }
  lines.push('', '## Summary', '', '```json', JSON.stringify(summary, null, 2), '```', '');
  fs.writeFileSync(path.join(dir, 'timeline.md'), lines.join('\n'));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
