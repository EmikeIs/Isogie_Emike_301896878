# Ride-Hailing Trip and Payment Records

**MIT 8103 Advanced Database Systems** · Emike Isogie · Student ID 301896878

This repository is my practical portfolio for MIT 8103. All five activities use one case study, and every script in it has been run. The saved outputs sit next to the code that produced them.

## Case study

The case study is a fictional ride-hailing service operating in Lagos. Riders request trips, the service matches each request to an available driver, and each completed trip is paid for once.

Three groups use the database. **Dispatchers** create trips and assign available drivers. **Analysts** review trips by status, time range and rider, and summarise trip counts and fares by pickup zone. **Payment operators** record the charge for each completed trip.

The main data is riders, drivers (with their licence and vehicle), trips (pickup and drop-off zone, status, times, distance and fare) and payments, held in PostgreSQL. A history of trip events is held in MongoDB. All names, phone numbers, plates and references are made up.

## The five portfolios

| | Activity | What is in it | Key result |
|---|---|---|---|
| [Portfolio 1](portfolio-1-database-design/) | Database design and modelling | ER diagram, schema, keys, constraints, normalisation to 3NF, 30 constraint tests | 30 of 30 invalid inserts rejected; sample rows unchanged |
| [Portfolio 2](portfolio-2-query-optimisation/) | Query processing and optimisation | Three queries with plans; scan versus B-tree benchmark on 20,000 rows | Median 3.668 ms → 0.670 ms, same 151 rows, index used |
| [Portfolio 3](portfolio-3-transactions-concurrency/) | Transactions and concurrency | COMMIT, ROLLBACK, READ COMMITTED, lost update, FOR UPDATE, REPEATABLE READ | Unlocked race ends at 2; locked race ends at 3 |
| [Portfolio 4](portfolio-4-nosql/) | NoSQL and advanced data models | `trip_events` document collection with embedded snapshots | 2 events, 4 queries, duplicate ID rejected |
| [Portfolio 5](portfolio-5-distributed-cloud/) | Distributed and cloud database | Three-zone replica set, write concern, lag, sharding, backups | Design and configuration; not deployed |

The two-to-three page summary submitted to the LMS is [Isogie_Emike_301896878_FinalSummary.md](Isogie_Emike_301896878_FinalSummary.md), with a [PDF](Isogie_Emike_301896878_FinalSummary.pdf) copy.

## Repository layout

```
.
├── README.md                           this file
├── Isogie_Emike_301896878_FinalSummary.md / .pdf
├── images/                             figures used in the summary
├── scripts/
│   ├── run_all.sh                      runs portfolios 1 to 4 in order
│   ├── render_evidence.py              turns saved text output into PNG images
│   └── build_summary_pdf.sh            builds the summary PDF
├── portfolio-1-database-design/        sql/, er/, results/, screenshots/
├── portfolio-2-query-optimisation/     sql/, src/, plans/, results/, screenshots/
├── portfolio-3-transactions-concurrency/ sql/, src/, results/, screenshots/
├── portfolio-4-nosql/                  mongodb/, src/, results/, screenshots/
├── portfolio-5-distributed-cloud/      config/, diagrams/
└── package.json                        Node.js dependencies (pg, mongodb)
```

Each portfolio has its own README. It explains what was built, how it was tested and what the results mean.

## Running it

You need PostgreSQL 14 or later, Node.js 18 or later, and for Portfolio 4 a MongoDB server (or a MongoDB-compatible one). The outputs in this repository were produced on PostgreSQL 16.15, Node.js 22 and FerretDB 1.24.

```bash
npm install
export PGHOST=localhost PGUSER=postgres          # your connection details
export MONGODB_URI=mongodb://localhost:27017     # for Portfolio 4
scripts/run_all.sh
```

`run_all.sh` drops and recreates a database called `ridehailing`, so use a test server. Each portfolio can also be run on its own with its `run.sh`, after Portfolio 1 has built the database.

The images in each `screenshots/` folder are the saved terminal output drawn as pictures by `scripts/render_evidence.py`. The text they show is in the matching `results/` file.

## Known limitation

Portfolio 4's evidence was produced on FerretDB rather than MongoDB itself. FerretDB does not support `$jsonSchema` validators, so the test that an invalid date is rejected is written but not yet verified. The Portfolio 4 README explains how to run it on MongoDB.

## AI use

AI tools were used to help prepare this work. The declaration is in the [final summary](Isogie_Emike_301896878_FinalSummary.md#ai-use-declaration).
