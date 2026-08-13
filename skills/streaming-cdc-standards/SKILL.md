---
name: streaming-cdc-standards
description: Use when changes must be captured from a database or processed in motion — deciding whether streaming is warranted at all versus an incremental batch every 15 minutes, capturing from the transaction log (PostgreSQL pgoutput/wal2json logical decoding and replication slots, MySQL/MariaDB binlog and GTID, Oracle LogMiner, SQL Server CDC, MongoDB change streams) versus triggers or timestamp polling, running Debezium (Debezium Server, Debezium Engine, Kafka Connect connectors, signals, tombstone records, snapshot.mode and incremental snapshots) or Flink CDC, initial snapshot cost and resume after a crash, an inactive slot retaining WAL until pg_wal fills the disk (max_slot_wal_keep_size, idle_replication_slot_timeout, safe_wal_size, wal_status), why table-change events are not domain events and must not become a public contract, at-least-once versus at-most-once versus exactly-once and consumer idempotency, ordering guaranteed only per partition and choosing the partition key, schema evolution when the source adds or drops a column, event time versus processing time, windows, watermarks, late data and keyed state in Apache Flink, Kafka Streams or Spark Structured Streaming, consumer lag as the primary SLI, replay from the beginning of the log, dead-letter queues, or how long the log is retained.
---

# Streaming and change data capture (CDC) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: "real time" is, alongside "lakehouse", the most oversold and worst justified
> label in the industry. **An incremental batch every 15 minutes solves the vast majority of
> "real-time requirements"**, and streaming is not an execution mode: it is a **permanent
> operation** that somebody has to watch every night of the year. Start by proving it is needed.

## 1. Scope and triggers

Applies to **capturing changes from a source system** and to **processing them in motion**: the
decision of whether streaming is needed at all, the capture mechanism, operating the capturer and
its impact on the source, delivery semantics, ordering, schema evolution of the stream, stateful and
time-based processing, and the operation and cost of all of it.

Triggers: `debezium`, `debezium-server`, `DebeziumEngine`, `io.debezium.connector.*`,
`snapshot.mode`, `signal.data.collection`, `tombstone`, `transforms=unwrap`,
`ExtractNewRecordState`, `pgoutput`, `wal2json`, `CREATE PUBLICATION`,
`pg_create_logical_replication_slot`, `pg_replication_slots`, `slot_name`, `restart_lsn`,
`wal_status`, `safe_wal_size`, `max_slot_wal_keep_size`, `idle_replication_slot_timeout`,
`REPLICA IDENTITY FULL`, `binlog`, `gtid`, `server-id`, `LogMiner`, `change streams`,
`kafka-connect`, `connect-distributed.properties`, `consumer lag`, `auto.offset.reset`,
`enable.idempotence`, `isolation.level=read_committed`, `transactional.id`, `StreamsBuilder`,
`KTable`/`KStream`, `readStream`/`writeStream`, `withWatermark`, `checkpointLocation`,
`StreamExecutionEnvironment`, `KeyedProcessFunction`, `WatermarkStrategy`, `savepoint`,
`checkpoint`, `DLQ`/`dead letter`, and the phrases of the domain: "we want it in real time", "the
primary's disk filled up", "the connector has been down since Friday", "the deletes are missing",
"duplicate events are arriving", "events arrive out of order", "we have to reprocess the whole
history", "the source added a column and the consumer broke".

**Not applicable**: see
- `data-platform-standards` (**mother**): **Kafka as an engine is hers** —topic partitions,
  retention, replicas, `min.insync.replicas`, KRaft— and so is the **schema registry** (Karapace,
  Apicurio, Confluent Schema Registry) and **PostgreSQL as an engine** with its replication, HA and
  PITR. Here, **what gets published on those topics, with what guarantees and what is done with the
  stream**. Her principle —**one store because it is needed, not because it is fashionable**— is
  inherited as **"one stream because it is needed, not because it is fashionable"** (§2.1).
- `message-brokers-standards` — **this is the most likely collision of the pair and
  the line is written here with precision**: **the broker as a component is hers** (Kafka, Pulsar,
  RabbitMQ, NATS: choice, topology, sizing, replication, retention, cluster operation, queues versus
  logs). **Processing the stream and capturing what goes into it belong here.** Mechanical cut-off
  rule: **if the broker makes the decision, it is hers; if the producer, the consumer or the
  processor makes it, it is ours.** "How many partitions can the cluster take?" is hers; "which
  partition key do I choose and what ordering does it guarantee me?" is ours.
- `microservices-architecture-standards` (**critical boundary; see §3.3, it is the most expensive
  design mistake in the domain**): **the outbox pattern, sagas, domain events and per-service data
  ownership are hers**. A **domain event** is designed and published by the application that owns
  the data; a **row change captured by CDC is not a domain event**. Here, the capture and transport
  mechanism — including CDC **over the outbox table**, which is its correct use.
- `lakehouse-standards` (**sister; boundary declared on both sides**): **what happens to the table
  when the changes land** is hers —*copy-on-write* versus *merge-on-read*, cost of
  `MERGE`/`DELETE`, files and deletion vectors, compaction, snapshots, catalog—. Here, **how the
  changes are captured and how they are processed on the way there**. **CDC is a typical lakehouse
  source, not the only one** (the lakehouse is fed by batch just the same) and **the lakehouse is
  not the only CDC destination** (a replica, a cache, a search index, another service). Neither
  presupposes the other.
- `data-engineering-standards` (**sister**): batch ingestion, orchestration, the watermark of an
  incremental, job idempotency, *backfill* and file format. She sets **when change capture is the
  answer**; here **how it is done well**. Her mirrored rule: the **file format** is hers, the
  **table format** belongs to `lakehouse-standards`.
- `data-governance-quality-standards` (**already on disk**): **data contracts, ownership, catalog,
  lineage and quality as a programme are hers**. Here, their execution in the stream: which schema
  gets published, who the responsible producer is and which assertions divert an event to the failed
  queue. Cut-off rule: if the question is "who is the owner and what does the contract promise?", it
  is hers; if it is "what does the consumer do when an event arrives that breaks it?", it is ours.
- `data-warehouse-modeling-standards`: the destination model. **A change stream is not an SCD2**:
  dimensional historisation is a modelling decision of hers; here the change is merely delivered.
- `privacy-engineering-standards`: **personal data, minimisation, retention and erasure are hers**.
  Here their technical constraint: a change published on a log with long retention **is one more
  copy of the personal data**, and a `DELETE` at the source **does not erase the previous events in
  the log** (§5).
- `observability-standards`: instrumentation, OTel, cardinality and the metrics backend. Here,
  **what to measure** in a stream (§6).
- `sre-practice-standards` (SLO, error budget, on-call), `incident-management-standards`,
  `backup-recovery-standards` (**the event log is not a backup**),
  `bcdr-standards`, `kubernetes-standards`, `iac-standards`, `cicd-standards`,
  `secrets-management-standards`, `identity-access-management-standards`,
  `grc-compliance-standards`, `mlops-standards`, `nosql-standards`, `search-engines-standards`,
  `vector-db-standards`, `graph-db-standards`, `timeseries-db-standards`,
  `oracle-dba-standards`/`sqlserver-dba-standards`/`mysql-mariadb-dba-standards` (**tuning and
  operating the source engine** are theirs; here only what CDC demands of it. Arbitration rule
  mirrored with `mysql-mariadb-dba-standards`: **capture is ours, impact on the engine is theirs**
  — the GTID format, the `binlog` as an engine mechanism and its purging are theirs; reading it as
  a change stream is ours), `ibm-i-rpg-standards` (**the Db2 for i equivalent, with the same
  mirrored rule**: the **journal and its receivers** —`CRTJRN`, `STRJRNPF`, `IMAGES(*BOTH)`,
  receiver management and purging— are hers, along with the platform's data traps (packed decimal,
  numeric dates, multi-member files, CCSID 65535); **reading that journal as a change stream is
  ours**. It is declared explicitly because **the mechanism catalogue in §2.2 did not include it**,
  and it must not be inferred from that that the platform has no log-based capture: it has one, and
  it is among the oldest), `aws-standards`/`azure-standards`/`gcp-standards` (MSK, DMS, Kinesis, Event Hubs,
  Pub/Sub, Datastream as managed services), `python-standards`, `jvm-spring-standards`
  (**Java/Kotlin code quality**: Flink and Kafka Streams are JVM and their *build*, tests and
  packaging are hers; stream design is ours), `scala-standards` (same boundary for
  the Scala API of Flink and Kafka Streams), `sql-standards` (Flink SQL and ksqlDB have
  streaming semantics of their own —windows, watermarks, dynamic tables— **which are ours**; the
  relational SQL written against a sink is hers).

**Governing principle**: **streaming is not paid for in compute, it is paid for in continuous
operation.** A batch that fails is retried tomorrow; a stream that fails accumulates lag, holds
resources at the source and degrades while nobody is looking. Before adopting it, the question is
not "can I?", it is **"who watches it at 3 a.m. on a Sunday in August?"**.

## 2. Default decisions

> Verify version, licence and ownership on the web before committing to it in a real project (§8).
> In 2026 this subsector changed hands: **IBM completed the acquisition of Confluent on
> 17 Mar 2026**.

### 2.1 The starting decision: do you really need streaming?

Exhaust this ladder **before** introducing a stream. Every rung avoided is a permanent operation you
do not take on:

| Stated need | Simplest solution | When it genuinely stops working |
|---|---|---|
| "We want it in real time" (for a report that is looked at in the morning) | **Incremental batch by watermark** (see `data-engineering-standards`) | Never stops working. This case **is not streaming** |
| Latency of minutes, moderate volume | **Incremental batch every 5-15 minutes** | When the source has no reliable watermark, or deletes must be captured |
| Query operational data with minimal delay | **Read replica** of the engine itself (see `data-platform-standards`) | When the destination is another engine, or another data model |
| You need **deletes**, ordering and the complete history of changes | **CDC** from the transaction log | — |
| Somebody or something **acts within seconds** on the event (fraud, stock, alerts, prices) | **Streaming** with stateful processing | — |

Two questions that settle most arguments:

1. **Which decision changes if the data arrives in 5 seconds instead of 15 minutes, and who makes
   it?** If the answer is "none" or "nobody", the real-time requirement does not exist.
2. **What is the cost of the stream being down for 4 hours on a Sunday?** If it is "none", you do
   not need streaming either. If it is "severe", you need **on-call**, not just technology.

**Honest rule**: CDC is **the right answer to a problem other than real time**. Its real value is
usually **capturing deletes and rapid changes faithfully**, not latency. Many projects that "need
streaming" actually needed CDC dumping into a destination in micro-batches.

### 2.2 How changes are captured: the mechanism matters more than the tool

| Mechanism | How it works | Verdict |
|---|---|---|
| **Reading the transaction log** (PostgreSQL WAL, MySQL/MariaDB binlog, Oracle LogMiner, SQL Server CDC, MongoDB *change streams*, **Db2 for i journals and receivers** — see `ibm-i-rpg-standards`) | Reads the engine's write log: it sees **every** operation, in *commit* order, with before and after | **The correct way.** No schema impact, captures deletes, respects transactional ordering. **Absolute default** |
| **Triggers** writing to an audit table | The engine runs code on every write | **Vetoed unless the log is impossible.** Penalises **every** transaction of the operational system, is bypassed by badly written bulk operations, pollutes the schema and is forgotten when a new table is created |
| **Timestamp query** (`WHERE updated_at > :x`) | Periodic polling | **This is not CDC.** **It loses physical deletes** (for ever and silently) and **loses multiple changes between polls** (you only see the last state). Besides, `updated_at` is almost never reliable: skewed clocks, bulk updates that do not touch it, writes that commit out of order. Legitimate only as an **incremental batch**, knowing what is being lost |
| **Dual write** from the application (DB and then broker) | The app writes to both places | **FORBIDDEN** (§7): it is not atomic. See outbox in `microservices-architecture-standards` |

**A warning about watermarks and commit ordering**: even with a perfect `updated_at`, a long
transaction may commit **after** your window has already passed its timestamp. Without window
overlap, that row is never ingested. It is the classic silent loss and it is one of the strongest
arguments in favour of the log.

### 2.3 Toolchain

| Area | Default | Verified status (Aug 2026) | Justifiable alternative |
|---|---|---|---|
| CDC capturer | **Debezium 3.6.x** | 3.6.0.Final (1 Jul 2026); 3.7.0.Alpha1 in progress. **Apache 2.0** (verified in the repository). De facto standard, backed by Red Hat | **Flink CDC** (Apache 2.0) if processing is already Flink and you want a single system |
| Running the capturer | **Debezium Server** (standalone) if you do not need Kafka Connect | Exists and is maintained; in the 3.6 series it is **migrating from the old embedded engine to the Quarkus extension** (`debezium-quarkus-engine`), with lifecycle control for *hot standby* with external locking. **Careful: it is an architectural migration in progress, not a consolidated mode** | **Distributed Kafka Connect** when you already operate Connect: it remains the most proven route and the one that has had the most eyes on it |
| Broker | **Kafka** (the component and its operation belong to `data-platform-standards` / `message-brokers-standards`) | Kafka 4.3.1 (Jun 2026), Apache 2.0, ASF. **IBM's acquisition of Confluent does not change Kafka's licence**: the project belongs to the ASF and its PMC is independent | — |
| Demanding stateful processing | **Apache Flink 2.3.0** | 2.3.0 stable according to the official downloads page (Jun 2026); 2.2.1, 2.1.3 and 1.20.5 also published. **It does not lose the technical crown, but it does lose new teams** because of its operational complexity: it demands dedicated people | **Managed Flink service** if you have no platform |
| Processing embedded in a JVM service | **Kafka Streams** | Alive. No cluster of its own; **bounded by the number of partitions** and with less sophisticated time/late-data handling than Flink | — |
| Processing where Spark already exists | **Spark Structured Streaming** | Alive (Spark 4.2.0, Jul 2026). Micro-batches: latency of seconds, not milliseconds. Wins by inertia if the team is already Spark | — |
| Managed SQL-first engines (RisingWave, Materialize, Decodable, ksqlDB…) | — | They greatly reduce the operational load in exchange for flexibility and for lock-in | Valid with an ADR and an exit plan |
| Event format | **Avro or Protobuf with a schema registry** | The registry belongs to `data-platform-standards` | JSON only with validation in CI |

**Criterion for choosing the processor, one line each**:
- **Flink** if there is **large state, serious event-time semantics and late data that matters**,
  and you have somebody to operate it.
- **Kafka Streams** if it is a **JVM application that already lives inside Kafka** and you do not
  want another cluster.
- **Spark Structured Streaming** if **you already operate Spark** and second-level latency is
  enough.
- **None of them** if what you needed was an incremental batch (§2.1). It is the right answer more
  often than is admitted.

**Retired or declining engines — do not choose them for anything new**: classic Spark Streaming
(DStreams) is obsolete compared with Structured Streaming; Apache Apex has had no development since
2019; Samza has not released since 2023; Storm is maintained but is rarely the right choice today.

**Ownership and licence risk**: **IBM completed the purchase of Confluent on 17 Mar 2026** (around
$11bn; WarpStream included). Kafka as a project is unaffected, but **the Confluent Community
License** —which covers Schema Registry, REST Proxy, ksqlDB and several connectors— **is not OSI
open source** and forbids offering them as a competing service. With the new owner, the pricing and
support model is a risk to watch, not a settled fact (§8). Practical consequence: **prefer Karapace
or Apicurio** for the registry (criterion already set in `data-platform-standards`) and record in
the ADR which non-OSI-licensed components you depend on.

## 3. Structure and conventions

### 3.1 CDC in practice: the initial snapshot and resuming

- **The initial snapshot is the most expensive and most dangerous moment of the whole project**:
  reading an entire table on a production system. Rules:
  - **Read from a replica** whenever the mechanism allows it; if not, plan it in a low-load window,
    with bounded reads and `statement_timeout`.
  - **Prefer the incremental snapshot** (chunked, resumable, in parallel with the stream) over the
    blocking one. A snapshot that cannot be resumed turns into five twelve-hour retries.
  - **Measure and budget how long it takes before running it in production.** It is the figure that
    decides whether the project is viable.
  - **Re-snapshotting has to be a planned and rehearsed operation** (signals / *ad hoc snapshot*),
    not an accident: you will need it when a slot is invalidated or a position is lost.
- **Resuming after a crash**: the capturer stores its **offset** (LSN, GTID, *resume token*)
  durably and outside its own process. Rules: the offset store goes into the backup; **if it is
  lost, the price is a full new snapshot**; and **the offset is committed after delivering, never
  before** — the other way round loses changes silently, this way they merely duplicate (and that
  is what idempotency is for, §3.4).
- **Heartbeats**: in databases with many tables where you only capture a few, and in databases with
  little activity, the capturer may not advance its offset for hours while the WAL piles up.
  **Enable heartbeats**; it is the specific mitigation and almost nobody knows about it.
- **Filter at the source, not at the destination**: include only the necessary tables and columns
  (bounded publications, include lists). Less load, less personal-data surface (§5), less schema
  noise.

### 3.2 The impact on the source: **the production failure par excellence**

**A logical replication slot retains WAL for as long as its consumer does not confirm. If the
consumer stops and nobody notices, `pg_wal` grows until the disk fills and the primary goes down.**
This is not a rare case: it is *the* incident of this domain. Verified against PostgreSQL 18:

- **`max_slot_wal_keep_size`** (since PG 13; reloadable via SIGHUP, in MB if no unit is given)
  limits the WAL that slots may retain. With the default value **`-1` retention is unlimited**,
  which is exactly the configuration that fills the disk. **Always set it to a value consistent with
  the real free space.**
- **The trade-off has to be accepted explicitly**: when the limit is exceeded, PostgreSQL
  **invalidates the slot** and recycles the WAL. The consumer can no longer continue and **a new
  slot and, typically, a full initial snapshot will be needed**. It is a conscious decision: **you
  sacrifice CDC to save the database**. It is the right choice, and it has to be written in the
  runbook before it happens.
- **`idle_replication_slot_timeout`** (**new in PostgreSQL 18**; unitless value in seconds, `0`
  disables it) automatically invalidates inactive slots. **Invalidation happens at the
  *checkpoint***, so there is a delay between crossing the threshold and the actual invalidation. It
  does not apply to slots that do not reserve WAL nor to slots synchronised from the primary
  (`synced = true`). Reasonable values are of the order of 48-72 h.
- **Mandatory monitoring of `pg_replication_slots`**: `active`, `wal_status`, `safe_wal_size`
  (with a positive `max_slot_wal_keep_size` it indicates how much WAL is left before invalidation;
  **negative means it has already been passed**) and `invalidation_reason`. **Alert with a threshold
  on slot WAL retention and on inactive slots, without exception.** And **delete orphan slots**: a
  slot from a test that nobody removed is a time bomb.
- **Long transactions at the source** make everything worse: they retain WAL and can fill the
  storage on their own. Complement with `wal_sender_timeout` (60 s by default) to detect dead
  consumers.
- **`REPLICA IDENTITY`**: by default PostgreSQL only publishes the primary key in the "before" of an
  `UPDATE`/`DELETE`. `REPLICA IDENTITY FULL` gives the full row **at the cost of more WAL and more
  load**: enable it per table and only if the consumer needs it, never globally.
- **Other engines, same principle**: in MySQL/MariaDB, binlog retention (`binlog_expire_logs_seconds`)
  sets your resume window — if the consumer is down for longer than that retention, **the position
  is lost and a re-snapshot is required**. In Oracle, log mining has a cost in the engine itself.
  **Coordinate the parameter with the engine's DBA, it is a shared decision.**
- **Cross-cutting rule**: CDC **couples the health of your analytics platform to the health of the
  operational database**. It is the hidden cost of the technique and it has to be told in writing to
  the team that owns the source before anything is switched on.

### 3.3 CDC versus outbox — **the boundary and the most expensive design mistake in the domain**

**Say it plainly and without lukewarm qualifiers: table changes captured by CDC are NOT domain
events.** An `UPDATE` on `orders` tells you that some columns changed value; it does **not** tell you
that the order was cancelled, nor why, nor by whom. Publishing raw CDC as a contract between
services means:

- **You couple every consumer to the internal physical schema** of the source service. From that
  moment on, that service can no longer refactor its database: any `ALTER TABLE` is a breaking change
  in a public API that nobody declared as such. It is exactly the same mistake as letting another
  service query your database, with an intermediate hop that disguises it.
- **You lose intent.** The row diff does not contain the "why". Each consumer reconstructs the
  semantics its own way, and all the reconstructions are different and plausible.
- **You expose everything that is in the table**, including columns that should never have left the
  service (§5).
- **No contract and no versioning**: a refactor breaks consumers in production without prior
  warning.

**The correct division, and the boundary with `microservices-architecture-standards`**:

| Case | Correct pattern | Owner of the decision |
|---|---|---|
| Publish that **something of business significance happened** so other services react | **Outbox**: the application writes the domain event, with its schema and its version, in the same transaction as the state change | `microservices-architecture-standards` |
| **Transport** that event reliably from the outbox table to the broker | **CDC over the outbox table** — this is the correct and virtuous use of CDC in service architecture | Here |
| Feed an **analytical store, a lakehouse, a cache or a search index** from existing tables | **Direct CDC over the tables**, with the destination treated as an **internal** consumer | Here |
| Integrate a **legacy system** that cannot be modified | **Direct CDC**, with a **mandatory anti-corruption layer** translating to a contract of your own before exposing it to anybody else | Here |

**Hard rules that follow**:
- **A raw CDC topic is never a public contract.** If somebody outside the owning team consumes it,
  either it becomes a domain event with an outbox, or an anti-corruption layer with its own versioned
  schema is placed in between. No exceptions.
- The cost of the outbox is real and must be stated: **it touches every write path, the table grows
  and has to be purged, and you maintain two schemas** (the table's and the event's). It is paid
  because the contract is worth it.
- **Tombstones**: on a compacted topic, a delete is represented by a message with a null value. If
  your consumer does not handle them, **deletes are not propagated** and your copy accumulates
  ghosts. It is a silent failure, which is the worst kind.

### 3.4 Delivery semantics: what they really mean

| Semantics | What it guarantees | How it is achieved | Verdict |
|---|---|---|---|
| **At-most-once** | Never duplicates; **may lose** | Commit the offset **before** processing | **It is almost always an accident, not a design.** And it happens through carelessness |
| **At-least-once** | Never loses; **may duplicate** | Commit the offset **after** processing | **The correct default.** Everything else is built on top |
| **Exactly-once** | Each effect is applied once | Transactions and state coordinated **inside the system** | **Real, but far narrower than it is sold as** (see below) |

**What "exactly once" really means**: it is **exactly-once *of effect***, not of delivery, and
**only within the boundary of the system that implements it** — reading from Kafka, updating state
and writing to Kafka in one transaction (Kafka Streams / transactional producer with
`read_committed`), or Flink's *checkpoint* mechanism with two-phase transactional sinks. **As soon
as an effect leaves that boundary** —calling an API, sending an email, writing to a database that
does not take part in the transaction— **the guarantee is over**. It also costs latency and
operational complexity.

**Therefore: consumer idempotency is the only real defence, and it is mandatory.** It is not an
alternative to *exactly-once*, it is its prerequisite and its substitute in 90 % of cases. It is
implemented with:
- **Business key + upsert** (`INSERT ... ON CONFLICT`, `MERGE`) instead of a plain `INSERT`.
- **Deduplication by event identifier** with a bounded window, when the upsert does not apply.
- **Version / sequence number comparison**: discard the event whose `lsn`/`sequence` is lower than
  or equal to the one already applied. This also protects against reordering.
- **Non-idempotent external effects** (charging, sending, notifying) **protected with an idempotency
  key and an execution log**. A reprocess must not bill twice.

### 3.5 Ordering and partitioning

- **Ordering is only guaranteed within a partition.** There is no global ordering in a partitioned
  log, and whoever assumes there is builds a system that fails intermittently and randomly.
- **Choosing the partition key is choosing what is ordered.** Rule: **the key is the entity whose
  sequence of changes matters** — typically the primary key of the source row. That way all the
  changes of the same order go to the same partition and arrive in order.
- **Consequences that have to be accepted**:
  - **Partition skew**: a very active entity saturates its partition and limits parallelism. It is
    detected by measuring lag **per partition**, not the aggregate.
  - **Changing the number of partitions breaks key affinity** and therefore historical ordering.
    It is a design decision with consequences, not a capacity adjustment (topic operation belongs to
    `data-platform-standards`).
  - **Consumer parallelism is bounded by the number of partitions.**
- **If ordering between different entities matters** (a transfer between two accounts), partitioning
  by entity does **not** give it to you. Either you put both in the same partition via a composite
  business key, or you solve it with state and event time in the processor, or you redesign the
  operation as a single event. Choose explicitly: do not leave it to chance.
- **Reordering across topics**: two different streams have no relative ordering. If a consumer needs
  "customer first, then order", that is a **dependency** to be resolved in the consumer (wait, look
  up, retry), not a transport guarantee.

### 3.6 Schema and evolution

The schema registry and its compatibility configuration belong to `data-platform-standards`. What is
specific to the stream:

- **Backward compatibility** (a new consumer reads old data) as the mandatory minimum;
  **forward** (an old consumer reads new data) when you do not control the consumers, which is the
  usual case. Verified in CI, not in somebody's head.
- **What to do when the source adds a column**: it is **additive and compatible** if the field has a
  default value. Decide explicitly whether it is propagated (**not everything that appears at the
  source should leave the source**, §5). If your connector has a column include list, the new column
  does not get in by itself: that is the safe option.
- **What to do when the source drops or renames a column**: it is **incompatible** and breaks
  consumers. It is handled as an *expand/contract* migration, coordinated with the team that owns
  the source: publish both fields, migrate consumers, retire the old one. **That the capturer
  tolerates the change does not mean your consumers do.**
- **Type change**: almost always incompatible. New field + coexistence + retirement.
- **Events already published cannot be rewritten.** A consumer reprocessing from the beginning of
  the log will see **every** historical schema: your consuming code must be able to read them all
  for as long as the log retains them. This is not theoretical, it is what happens on the day you
  reprocess.
- **The owner of the event schema is the producer**, with a published and versioned contract. A
  schema change without notice is an incident, not a deployment.

### 3.7 Processing in motion: time, windows and state

- **Event time versus processing time**: **event time** (when it happened) is the correct one for
  anything the business is going to read; **processing time** (when the engine saw it) produces
  **non-reproducible** results: reprocessing gives a different result from the original. Rule:
  **always aggregate by event time**; use processing time only for telemetry of the system itself.
- **Watermarks**: the engine's assertion that "I no longer expect events earlier than T". It is
  **a heuristic, not a fact**, and it embodies the central trade-off of the domain: **aggressive
  watermark = fast results and more data discarded; permissive watermark = late results and more
  state retained**. It is chosen with real lateness data from the stream, documented and reviewed.
- **Data arriving late**: decide and write down what happens to it. Three legitimate options —
  discard it (counting it, always), accept it with an allowed lateness and **re-emit** the corrected
  result, or divert it to a side stream for separate handling. **The illegal option is not
  deciding**, because the silent default is to discard it without counting it, and then the figures
  do not add up and nobody knows why.
- **Windows**: *tumbling* by default; *sliding* multiply state and compute by the overlap; session
  windows when the business talks about sessions. **Every open window is retained state**: a 30-day
  window over a high-cardinality key is a memory problem, not a requirement.
- **State**: it is the most expensive and most fragile asset of a stream. Rules:
  - **TTL on all keyed state**, without exception. Keyed state with no expiry grows until it brings
    the job down, and it does so months after nobody remembers the design.
  - **Checkpoints/savepoints on durable storage**, backed up and **with a tested restore**. A job
    whose state cannot be restored is not recoverable: only reprocessable.
  - **State compatibility limits deployment**: changing the logic or the state schema may prevent
    restoring from the previous *savepoint*. Decide in advance whether a deployment keeps state or
    starts from scratch — and if it starts from scratch, how long it takes to catch up.
  - **Stateful *joins* over streams** require retaining both sides: define the window or state
    explodes.

## 4. Quality and testing — gates

In increasing order of cost. **Those marked as gates break the build or the deployment.**

1. **Capturer and job configuration as code**, versioned and reviewed: connectors, table and column
   include lists, snapshot mode, partition keys, retention, window parameters. Nothing created by
   hand against a production API. *CI gate.*
2. **No secrets in the connector configuration**: credentials come from the secrets manager
   (see `secrets-management-standards`). A connector file with the production database password is a
   finding, not an oversight. *CI gate.*
3. **Schema compatibility verified in CI** against the registry, with the declared policy
   (minimum `BACKWARD`). An incompatible change **breaks the build**. *Gate.*
4. **Unit tests of the processing logic** with fixed events and an expected result, covering the
   happy path **and the mandatory edges**: **duplicate event**, **out-of-order event**,
   **delete / tombstone**, **null field**, **late event beyond the watermark**,
   **empty window**, **brand-new key never seen before**, **restart mid-window**. *CI gate.*
5. **End-to-end idempotency test**: delivering the same batch of events twice produces the same
   state at the destination (same count, same checksum). **Without this test, idempotency is an
   intention.** *CI gate.*
6. **Delete propagation test**: delete at the source and check that the destination reflects the
   delete. It is the most expensive silent failure and the least tested. *Gate.*
7. **Resume test**: kill the capturer or the job, start it and check that it **neither loses nor
   duplicates in a non-idempotent way**. With containers of the real engine (not with doubles),
   because the log's behaviour is what is being tested.
8. **State restore test** from *checkpoint*/*savepoint*, and of **changing the application version**
   while keeping state. It is done before the first production deployment, not after the first
   incident.
9. **Periodic reconciliation against the source** (count and sum of a key measure, with a declared
   tolerance), scheduled. **A CDC stream diverges from the source over time; without reconciliation
   you do not find out.** This is the most important operational gate of them all.
10. **Reprocessing rehearsal**: reprocess from the beginning of the log in a mirror environment,
    measuring how long it takes and what it costs. If it does not fit in the time available, your
    recovery plan does not exist.
11. **Dependencies pinned by hash/digest** in connectors, images and job libraries (§5).
    *CI gate.*

## 5. Stack security

- **CDC copies everything that is in the table, including the columns that should never have left.**
  Filter **at the capturer** (column list, bounded publication, masking in the connector), not
  downstream: every PII column you do not capture is a retention, erasure and breach problem you
  will not have. Coordinate with `privacy-engineering-standards`.
- **An event log with long retention is one more copy of the personal data**, with its own
  classification, its declared retention and its access control. **Infinite retention "just in case"
  is forbidden** (§7).
- **The right to erasure clashes with the log**: a `DELETE` at the source generates a new event,
  **it does not erase the previous events**. A compacted topic with a *tombstone* removes the
  previous versions of that key **over time, not immediately**, and only if it is compacted. If
  there is an erasure commitment, **topic retention becomes a compliance parameter**, or it is
  designed with pseudonymisation / *crypto-shredding* from the start. The policy belongs to
  `privacy-engineering-standards`; **the technical constraint and the parameter are set here**.
- **Least privilege at the source**: the capturer's user has **only** the replication/read
  permissions it needs, on the agreed tables. **It is not a superuser**, even if the connector
  tutorial says so.
- **The capturer authenticates with rotatable, short-lived credentials**; no eternal static
  passwords in a connector file. TLS mandatory against the source and against the broker;
  authorisation per topic and per consumer group.
- **PII out of logs and error messages**: a connector that logs the row it could not serialise is a
  leak. Log key and offset, not content. The same applies to the **dead-letter queue**: it is a data
  store with real content, and it needs its own access control and its own retention.
- **Supply chain — verified precedents, not hypotheses**: **Trivy** (Mar 2026), **LiteLLM**
  on PyPI (1.82.7/1.82.8, 24 Mar 2026), **Telnyx** (Mar 2026), **Microsoft's `durabletask`**
  (1.4.1-1.4.3, May 2026) and **`elementary-data` 0.23.3** (Apr 2026, with the `.pth` pattern that
  runs when the interpreter starts). The current generation, **"Mini Shai-Hulud"
  (CVE-2026-45321)**, active since late Apr 2026, propagates between npm and PyPI, **extracts OIDC
  tokens from the memory of the GitHub Actions runner** and has gone as far as **forging SLSA
  level 3 provenance attestations**. Mandatory consequence: pin by hash/digest everything that runs
  in a process holding credentials for the source database or the broker; a quarantine window of
  days before adopting newly published versions; **provenance attestation is no longer sufficient
  proof on its own**; and a *runner* does not hold credentials for more than one environment.

## 6. Performance and operability

### 6.1 Consumer lag is the primary metric

- **Measure lag in time, not just in number of messages.** "12,000 messages behind" says nothing;
  "18 minutes behind" does. And **measure it per partition**: the aggregate hides skew,
  which is the most frequent cause.
- **Alert on trend, not on an isolated threshold**: lag that grows steadily is an incident even if
  its absolute value is still small. The fixed threshold warns when there is no margin left.
- Mandatory complementary signals: **capturer lag relative to the source** (which is different from
  consumer lag), **WAL retention / slot size** (§3.2), job restart rate, **retained state**,
  *checkpoint* duration and failures, message rate to the DLQ,
  and **data age at the destination** (freshness, which is the signal the business cares about;
  see `data-engineering-standards` §6).
- **Actionable alert with a runbook**, always: what broke, what depends on it, how it is recovered,
  how long it takes. A lag alert with no runbook at 4 a.m. is useless.
- **If there is a latency commitment, there is on-call.** An SLO of seconds with nobody to respond
  out of hours is a documented lie (criterion inherited from `data-engineering-standards` §6.3 and
  `sre-practice-standards`).

### 6.2 Reprocessing, DLQ and the question that decides the architecture

- **The dead-letter queue (DLQ) is mandatory and has an owner.** Rules: every diverted message
  carries **the cause and the original offset**; there is a written reinjection procedure; and
  **the DLQ is monitored with an alert**. A DLQ nobody looks at is a dump of lost data with the
  appearance of a solution. A poison message must **never** be retried infinitely: it blocks the
  whole partition and stops the stream.
- **Reprocessing from the beginning**: it is the capability that makes a stream operable —
  fixing a logic error, populating a new destination, recovering from corruption. Requirements:
  **idempotent consumers** (§3.4), a destination that tolerates rewriting, capacity to absorb the
  burst without bringing anything downstream down, and **a prior measurement of how long it takes**.
  Rehearse it (§4).
- **The question that decides the architecture: how long do you keep the log?** It is not an
  operational parameter, it is a structural decision:

| Retention | What it buys you | What it costs you |
|---|---|---|
| **Short** (hours/days) | Cheap storage, small personal-data surface | **You can only reprocess the recent past.** A new destination has to be seeded from the source with a snapshot |
| **Medium** (weeks) | Realistic reprocessing of incidents | Cost and data classification |
| **Long or infinite** (log as the source of truth) | Rebuild any destination at any time | Growing cost, **direct conflict with retention and erasure of personal data**, and **every historical schema alive for ever** in your consuming code |

  **Decide it in writing in the ADR, with the privacy team present**, and be clear that **the log
  is not a backup**: it has neither the recovery model, nor the verification, nor the isolation of
  one (see `backup-recovery-standards`).

### 6.3 Cost

- **Streaming is paid for in continuous operation, not in one-off compute.** A batch consumes
  resources when it runs; a stream consumes **24×7**: brokers, capturer *workers*, processor
  *task managers*, state and log storage, and **human attention**.
- **The most expensive item is usually the last one**, and it is the one that never appears in the
  comparison that justified the project.
- **Compare honestly**: annual cost of the stream (infrastructure + on-call + maintenance)
  against the annual cost of the equivalent incremental batch. If the difference is not justified by
  a business decision that happens within those seconds (§2.1), the answer is the batch.
- **Small files are a cost induced by streaming** when the destination is a lakehouse:
  compaction goes into the stream's budget, not into another team's (see
  `lakehouse-standards` §3.3 and §3.5).

## 7. Sustainability and prohibitions

- **Cadence**: review quarterly the version and licence of the capturer, the processor and the
  broker, and **the ownership of the components** — in 2026 this subsector changed hands
  (IBM/Confluent). Major versions of Flink and of the connectors are rehearsed in a mirror with a
  **state restore test** before touching production.
- **Active retirement**: a stream, topic or connector with no measured consumption for a quarter is
  flagged and retired — **including its replication slots**, which are what gets forgotten and what
  fills the disk months later.
- **Mandatory ADR** for: introducing streaming (versus the batch of §2.1), choosing a capture
  mechanism, choosing a processor, **setting log retention** (§6.2), defining each stream's
  partition key, and publishing any topic as a contract outside the team.
- **Source impact document signed by the owning team** before enabling CDC against a production
  database. It is not bureaucracy: it is that their disk is the one that fills up.

**FORBIDDEN**
- ❌ Adopting streaming without having ruled out in writing the incremental batch and the read
  replica.
- ❌ Promising second-level latency with no on-call to sustain it.
- ❌ **Dual write** from the application (database and then broker) with neither outbox nor CDC.
- ❌ **Publishing raw CDC as a contract outside the team that owns the data**, with neither outbox
  nor anti-corruption layer. It is the most expensive design mistake in the domain.
- ❌ Calling a row change a "domain event".
- ❌ Trigger-based CDC when the transaction log is available.
- ❌ Calling a poll on `updated_at` CDC: it loses deletes and intermediate changes.
- ❌ **A replication slot with `max_slot_wal_keep_size = -1` (the default value) without an alert on
  WAL retention and on inactive slots.**
- ❌ Leaving orphan slots from tests or retired connectors.
- ❌ Global `REPLICA IDENTITY FULL` without a demonstrated need per table.
- ❌ Committing the offset before processing (accidental *at-most-once*).
- ❌ A non-idempotent consumer. **Delivery is "at least once" unless proven otherwise.**
- ❌ Promising end-to-end *exactly-once* when there is an effect outside the transactional boundary.
- ❌ Assuming global ordering in a partitioned log, or changing the number of partitions without
  accepting the break in key affinity.
- ❌ A consumer that ignores *tombstones*: deletes are not propagated and nobody finds out.
- ❌ Aggregating by processing time what the business is going to read.
- ❌ Not deciding what is done with late data (the silent default is to discard it without counting
  it).
- ❌ Keyed state without TTL; a wide sliding window over a high-cardinality key.
- ❌ A stateful job without a durable *checkpoint* and **without a tested restore**.
- ❌ Putting CDC into production without having measured the initial snapshot or rehearsed the
  re-snapshot.
- ❌ An initial snapshot against the primary at peak hour without agreement from the source team.
- ❌ A stream without a DLQ, or a DLQ with no owner, no alert and no reinjection procedure.
- ❌ Infinite retrying of a poison message, which blocks the partition.
- ❌ A stream without periodic reconciliation against the source.
- ❌ Infinite topic retention "just in case", or a log with personal data and no declared retention.
- ❌ Using the event log as a backup.
- ❌ A superuser account for the capturer; eternal static credentials in the connector
  configuration.
- ❌ Capturing PII columns "because they came in the table"; PII in connector logs or in the DLQ
  without control.
- ❌ Dependencies not pinned by hash/digest in processes with source or broker credentials.
- ❌ Stating versions, licences or ownership of a tool from memory (§8).

## 8. Mandatory web verification

The data in §2, §3.2 and §5 are from **August 2026**. Before committing to anything in a
deliverable, verify:

1. **Debezium**: current version (3.6.0.Final on 1 Jul 2026; 3.7.0.Alpha1 in progress), licence
   (**Apache 2.0**, verified in the repository) and **the real state of Debezium Server**: in the
   3.6 series it is migrating from the old embedded engine to the Quarkus extension. **Check whether
   that migration has consolidated before betting on the standalone mode without Kafka Connect.**
   Verify too the state of the specific connector for your engine (the PostgreSQL, MySQL and SQL
   Server ones are the most road-tested; for the rest, do not assume it).
2. **PostgreSQL**: logical replication parameters and behaviour in **your** version —
   `max_slot_wal_keep_size` (default `-1`, unlimited), **`idle_replication_slot_timeout` (new
   in PG 18, invalidates at the *checkpoint*, does not apply to `synced` slots)**,
   `wal_sender_timeout`, and the `wal_status`, `safe_wal_size` and `invalidation_reason` columns of
   `pg_replication_slots`. **These names change between versions: do not cite them from memory.**
3. **Processors**: Flink (**2.3.0 stable according to the official downloads page, Jun 2026**;
   careful, several secondary sources still cite 2.2.1 — **the project's source wins**), Kafka
   Streams (with Kafka 4.3.1, Jun 2026) and Spark Structured Streaming (Spark 4.2.0, Jul 2026). And
   the support calendar of the branch you use.
4. **Licences and ownership**: **IBM completed the acquisition of Confluent on 17 Mar 2026**; Kafka
   remains at the ASF under Apache 2.0 and is unaffected. Verify the current state of the **Confluent
   Community License** (not OSI: Schema Registry, REST Proxy, ksqlDB and several connectors) and
   whether the pricing or support model has changed under IBM. Verify too the licence of any
   commercial CDC platform before recommending it.
5. **Supply chain**: advisories for the connectors, images and libraries you install, and the
   evolution of **Mini Shai-Hulud (CVE-2026-45321)**.
6. **Source engine**: binlog retention and its current parameter in MySQL/MariaDB, the state of
   LogMiner in the Oracle version in use, and the CDC limits of the managed service if the source is
   in the cloud.

**Declared gaps in this revision** (do not fill them in from memory):
- **Debezium Server in standalone mode**: verified that it **exists** and that in 3.6 it is in an
  architectural migration towards the Quarkus extension; **not verified** whether the standalone
  mode is already considered consolidated and recommended by the project over Kafka Connect. Do not
  assert it.
- **Flink CDC**: neither version nor release cadence of the subproject verified (only that it is
  Apache 2.0 under the Flink umbrella).
- **Licences of commercial CDC platforms** (Estuary, Artie, Sequin, Streamkap, Airbyte for
  CDC): **not verified** in this revision. The search returned no primary sources. Do not cite any
  specific licence without checking it in the repository or on the product's website.
- **Kafka Streams and Spark Structured Streaming**: no independent adoption figure verified.
  The available comparisons come from vendors with an interest in the answer
  (Confluent, Decodable, RisingWave, Tinybird, Onehouse): treat them as orientation, not as data.
- **PeerDB/ClickPipes and other destination-specific CDC**: current state not verified.
- **Cost**: there are no verified figures for streaming/batch comparative cost. Measure it on your
  platform.

If the web contradicts this document, **the web wins** — flag the discrepancy.
