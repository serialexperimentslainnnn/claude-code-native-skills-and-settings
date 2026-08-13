---
name: timeseries-db-standards
description: Use when business, industrial or scientific measurements are stored and queried over time — deciding whether PostgreSQL with range partitioning, BRIN indexes and materialized rollups already suffices before adopting a dedicated engine, TimescaleDB and TigerData (create_hypertable, hypertable, chunk_time_interval, time_bucket, continuous aggregate, add_retention_policy, add_compression_policy, hypercore/columnstore, the tsl/ directory and the Tiger Data License), InfluxDB 3 Core versus Enterprise and the 1.x/2.x/3.x incompatibility mess, InfluxQL and Flux migration, line protocol and InfluxDB Line Protocol/ILP ingestion, QuestDB, VictoriaMetrics as a business data store, TDengine and its AGPL licence, ClickHouse MergeTree/AggregatingMergeTree with TTL as a columnar time-series store, tag versus field modelling and unbounded series explosion from a per-device or per-order identifier, wide versus narrow schema, downsampling and rollup tiers, retention as a business decision, columnar compression ratios and their effect on query speed, batched writes, out-of-order and late-arriving sensor readings from intermittent IoT links, backfills, updates and deletes as the expensive operation, SQL versus proprietary query languages, time-bucket aggregation, gap filling and interpolation, or historians, OT/SCADA archives and sensor telemetry retention.
---

# Time-series database standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: almost everyone who installs a TSDB does so for volumes **PostgreSQL would not
> even notice**. A range-partitioned table with a BRIN index and a few materialised views absorbs
> billions of rows on ordinary hardware. A TSDB is not a free *upgrade*: it is **one more engine to
> operate, back up, patch and know how to query**. Start by proving the default is not enough.

## 1. Scope and triggers

Applies to **storing and querying timestamped business, industrial and scientific measurements**:
OT/IoT sensors and telemetry, energy meters, financial series, laboratory readings, usage events
aggregated over time. It covers engine choice, series modelling, retention and resolution,
compression, ingestion, the query pattern and operations.

Triggers: `create_hypertable`, `chunk_time_interval`, `time_bucket`, `time_bucket_gapfill`,
`add_continuous_aggregate_policy`, `add_retention_policy`, `add_compression_policy`, `hypercore`,
`columnstore`, `_timescaledb_internal`, `USING BRIN`, `PARTITION BY RANGE (ts)`, `influxd`,
`influxdb3`, `line protocol`, `ILP`, `InfluxQL`, `Flux`, `questdb`, `SAMPLE BY`, `LATEST ON`,
`vmagent`/`vminsert`/`vmselect` as a business store, `taosd`, `MergeTree ORDER BY (id, ts)`,
`AggregatingMergeTree`, `TTL ... DELETE`/`TTL ... GROUP BY`, and the domain phrases: "we store sensor
readings", "the history takes up terabytes", "the last-year query takes minutes",
"we want to see the hourly average", "the data arrives hours late because the equipment had no
coverage", "we have to fill the gaps", "how long do we keep the detail?".

**Not applicable**: see
- `observability-standards` (**this skill's critical boundary, and it is declared here without
  ambiguity**): **the whole monitoring stack is theirs** — Prometheus, PromQL, Mimir, Thanos,
  exporters, *scraping*, *recording rules*, Alertmanager, exemplars, sampling, the OpenTelemetry
  Collector, and **cardinality control for system metrics**. Cut-off rule: **if the series measures
  the behaviour of your software or your infrastructure and exists to diagnose an incident, it is
  theirs; if the series is business or physical-process data — what the plant produced, what the
  sensor measured, what the asset traded at — and someone is going to query, bill or audit it months
  later, it belongs here.** Practical consequences of the line: the retention of a CPU metric is
  decided by the observability budget (there); the retention of a meter reading is decided by
  contractual or regulatory obligation (here). The same engine can serve both uses —
  **VictoriaMetrics is the obvious case** — and that does **not** move the boundary: it is decided by
  the purpose of the data, not by the binary. **And if it is the same cluster for both, that is an
  isolation error** (§6).
- `data-platform-standards` (**parent**): **PostgreSQL as an engine is theirs** — modelling, indexes,
  migrations, *tuning*, replicas, HA, PITR, encryption at rest, GDPR classification and retention.
  Here, **the temporal pattern on top of that engine** (range partitioning with retention in mind,
  BRIN, materialised aggregates) and **when it stops being enough**. Its principle — **one store per
  need, not per fashion** — is the premise of §2.1.
- `message-brokers-standards` (**the line is declared on both sides**): **a
  broker transports the measurements, a TSDB stores them to be queried.** The broker — MQTT, Kafka,
  NATS — its topology, retention, security and operation are theirs. **The write into the store and
  everything that happens afterwards belongs here.** They meet exactly at IoT ingestion: the broker
  receives from the device, a consumer writes in batches to the TSDB. **The broker is not the store**
  (§7).
- `streaming-cdc-standards` (**cut-off rule mirrored word for word**): *if the decision is taken by
  the broker, it is theirs; if it is taken by the producer, the consumer or the processor, it belongs
  here* — applied to this pair, **what the consumer does when the data arrives (delivery semantics,
  idempotency, ordering, windows, watermarks, consumer lag, reprocessing, dead-letter queue) is
  theirs**; **how that data ends up written, compressed, aggregated and expired in the store belongs
  here**. Their "late data" is a windowing decision; mine is an out-of-order write against an already
  compressed *chunk*.
- `data-warehouse-modeling-standards`: the analytical model (star, grain, SCD, calendar dimension). A
  time series **is not a periodic fact table** by default; if the data ends up in a mart, the
  modelling is theirs.
- `lakehouse-standards`: cold history in an open table format over object storage. **The next step
  when the TSDB stops being the right place for 5 years of detail** (§3.5).
- `data-engineering-standards` (batch ingestion, orchestration, *backfill*),
  `data-governance-quality-standards` (ownership, catalog, contracts and data quality),
  `analytics-bi-standards` (the dashboard that draws it), `nosql-standards` (Cassandra/Mongo
  as a generic engine; here only if used **as** a time series), `search-engines-standards`,
  `vector-db-standards`, `graph-db-standards`, `object-storage-standards` (the underlying storage and
  its cost per tier), `backup-recovery-standards` (backup mechanics and proven restore),
  `bcdr-standards` (RTO/RPO), `sre-practice-standards`, `privacy-engineering-standards`
  (**a series per device or per person can be personal data**: minimisation, retention and the right
  to erasure are theirs), `grc-compliance-standards` (legal retention obligation),
  `kubernetes-standards`, `linux-storage-standards`/`zfs-standards` (the disk underneath),
  `aws-standards`/`azure-standards`/`gcp-standards` (Timestream, Managed Prometheus, Monarch and other
  managed offerings), `python-standards`, `mlops-standards` (forecasting and anomaly detection over
  the series: the model is theirs, the store belongs here),
  `oracle-dba-standards` and `mysql-mariadb-dba-standards` (the *tuning* and
  operation of those engines are theirs), `sqlserver-dba-standards` and `caching-cdn-standards`.

**Governing principle**: **resolution and retention are business decisions, not infrastructure
decisions.** Everything else — engine, compression, partitioning — derives from answering *how much
detail is needed and for how long*. A team that has not answered that is not ready to choose an
engine.

## 2. Default decisions

> Verify version, licence and **ownership** on the web before committing to it in a real project (§8).
> **This domain has changed licence and owner repeatedly**: Timescale renamed itself to
> **TigerData** (17-Jun-2025) and InfluxDB has broken compatibility **twice**.

### 2.1 The prior question: why not PostgreSQL?

**PostgreSQL, used well, is a perfectly decent time-series database.** Before introducing a new
engine, exhaust this ladder and **write in the ADR which rung you stop at**:

| Rung | What you do | How far it really goes |
|---|---|---|
| **1. Ordinary table** | `timestamptz` + series key, composite index `(series, ts DESC)` | Millions of rows. Most projects that "need a TSDB" live here and do not know it |
| **2. Declarative range partitioning by time** | Partition by day/week/month; **retention becomes a `DROP TABLE`, which is instantaneous**, instead of a mass `DELETE` that generates *bloat* | Hundreds of millions to billions of rows. **This is the rung almost nobody tries** |
| **3. BRIN index** on the time column | A tiny index that exploits the physical correlation between insertion order and time | Ideal in *append-only* tables ordered by time: it costs a fraction of a B-tree in space and write cost |
| **4. Materialised aggregates** (refreshed materialised views, or *rollup* tables maintained by a *job*) | You precompute hourly and daily averages/maxima/sums | The dashboard query stops touching the detail. **It is 80% of the benefit of a TSDB, with the engine you already have** |
| **5. TimescaleDB** (extension) | Automates 2, 3 and 4 and adds **columnar compression** and incremental continuous aggregates | **It is still PostgreSQL**: same SQL, same *drivers*, same backup, same team. **It is the first legitimate step outside the default** |
| **6. Dedicated engine** | InfluxDB, QuestDB, ClickHouse, VictoriaMetrics, TDengine | Only with a measurement that proves 1-5 do not get there |

The three questions that settle the discussion:

1. **How many points per second are really ingested, measured, at peak?** If the answer is
   "we don't know" or "a few thousand", rungs 2-4 are more than enough.
2. **Which query hurts?** If it is "hourly average of the last month for 50 sensors", a materialised
   aggregate resolves it in milliseconds. If it is "ad-hoc scan of 3 years of raw detail with
   arbitrary groupings", then there is a case for a columnar engine.
3. **Who operates the new engine at 3 in the morning?** If the answer is "the same person who already
   operates PostgreSQL and has no time", the correct answer is rung 5, not 6.

**Uncomfortable corollary**: the argument "but it's time-series data" **is not a justification**. Time
series is the shape of the data, not an engine requirement.

### 2.2 What makes a time series special (and why that allows tricks)

These four properties are what a specialised engine exploits; **if your workload does not meet them,
the specialised engine will not give you its advantage** and you will be paying for the operations
without the benefit:

| Property | Technical consequence it enables |
|---|---|
| **Writes almost always append-only and in time order** | Sequential write structures; no in-place update; an almost free time index (BRIN) |
| **Queries almost always bounded by a time range** | Partitioning/*chunking* by time → **partition pruning**: the query does not even look at 99% of the data |
| **Data ages and loses value** | Retention by expiry and ***downsampling***: three-year-old detail is almost never needed to the second |
| **Contiguous values of the same series look very much alike** | **Columnar compression with delta and delta-of-delta encoding**: order-of-magnitude ratios, impossible in a generic row-based engine |

**The most important practical consequence**: in a specialised engine, **compressing usually speeds up
analytical queries** (less I/O, better cache use) at the cost of making point modifications over
already compressed data more expensive. In a generic engine, compressing only saves disk.

### 2.3 Toolchain

| Area | Default | Verified status (Aug 2026) | Justifiable alternative |
|---|---|---|---|
| **Starting point** | **Partitioned PostgreSQL + BRIN + materialised aggregates** | Engine and version are set by `data-platform-standards` | None: it is rung 0 |
| **First specialised step** | **TimescaleDB 2.29.0** (28-Jul-2026) on top of PostgreSQL | **Dual licence, verbatim from the `LICENSE` file**: outside the `tsl/` directory, **Apache 2.0**; inside `tsl/`, **Timescale License (TSL)**. Separate objects are compiled and **the binaries with `-tsl` in the name are TSL**. The company renamed itself **Timescale → TigerData (17-Jun-2025)** and the TSL appears today as the *Tiger Data License* | None if you already use PostgreSQL: it is the option with the lowest organisational cost |
| **Generalist columnar** (wins more cases than is admitted) | **ClickHouse 26.7.x** (26.7.2.59-stable, 3-Aug-2026) | **Apache 2.0** (verbatim from the `LICENSE`, © 2016-2026 ClickHouse, Inc.) | It is the right answer when there is also heavy ad-hoc analytics over the history |
| **Dedicated engine with SQL and low ingestion latency** | **QuestDB 9.4.3** (15-Jun-2026) | **Apache 2.0** (verbatim from the `LICENSE.txt`). There is a commercial Enterprise edition: **verify its terms before counting on HA or advanced security** (§8) | Niche: high frequency (finance, tick data) with SQL |
| **Dedicated metrics engine used as a store** | **VictoriaMetrics v1.148.0** (20-Jul-2026); LTS lines **v1.136.x** and **v1.122.x** | **Apache 2.0** repository. ***Open core* model: there are Enterprise builds with the `enterprise` suffix that require `-license`/`-licenseFile`**, with their own features (per-*tenant* retention, disaster recovery, anomaly detection). The licence check happens **only at startup** | Valid, but **watch the boundary**: if your case is monitoring, the skill is `observability-standards` |
| **Dedicated IoT/OT-oriented engine** | **TDengine 3.4.1.6** (`ver-3.4.1.6`, 30-Apr-2026) | **AGPL v3** (verbatim from the `LICENSE`). **The AGPL is an organisational licence-policy decision, not a detail**: consult it before adopting, and all the more if the product is offered to third parties | Only with a clear industrial case and the AGPL accepted |
| **InfluxDB** | **It is not the default. Adopt it with your eyes open** (§2.4) | **3.10.0** (17-Jun-2026). The current repository (the v3 engine, in Rust) carries **`LICENSE-APACHE` + `LICENSE-MIT`** (permissive dual licence) and corresponds to **InfluxDB 3 Core**. **Enterprise is commercial** | Only if you already have an Influx ecosystem, or if the managed provider is the route |
| **Cold history of years** | **Open table format over object storage** | See `lakehouse-standards` | The engine's own tiered storage if it offers it and you have tested it |
| **Managed** | Valid and often correct | The specific services belong to the cloud skills | ADR with exit cost and a **tested** export format |

### 2.4 InfluxDB: the warning that must be given in writing

**InfluxDB has broken compatibility twice and that is an architectural datum, not an anecdote.**
What was verified as of August 2026:

- **1.x** (InfluxQL, TSM) and **2.x** (Flux, organisations/*buckets*) are **distinct lines with
  distinct query languages**. **3.x** is a **new engine rewritten in Rust** (Arrow/Parquet)
  with SQL and InfluxQL — and **Flux is not supported in line 3**: anyone who built their platform
  on Flux is facing a **query rewrite**, not an upgrade.
- **1.x and 2.x are in maintenance**: no new features. There is no published forced EOL date,
  but **building something new there is knowingly purchased debt**.
- **Line 3 splits into two products**: **Core** (free, permissive, **single node**) and
  **Enterprise** (commercial: high availability, multi-node, compaction for long-range queries,
  certifications and support). Translation without decoration: **the free edition of InfluxDB 3 does
  not cover high availability**, and performance on long historical queries is tied to commercial
  edition functionality.
- **Verified operational warning**: the `latest` tag of the InfluxDB Docker images will point to
  **InfluxDB 3 Core from 15-Sep-2026**. **Pin the tag by version**; otherwise a
  `docker pull` switches your major engine without warning.

**Criterion**: for a new deployment, InfluxDB is only the right choice if you explicitly accept the
commercial edition or the managed service, **or** if your case is single-node and without an
availability commitment. In any other scenario, TimescaleDB or ClickHouse give you more certainty for
less product risk.

## 3. Modelling, retention and ingestion

### 3.1 Tags versus fields, and **cardinality explosion**

In engines with a tag model (Influx, VictoriaMetrics, TDengine, Prometheus), each distinct
combination of tag values **creates a series**, and series are the unit of cost in memory, in the
index and in query time.

- **Tag** = what you group or filter by. **It must have a bounded value set known in advance**:
  `plant`, `line`, `sensor_type`, `unit`.
- **Field** = the measured value. Not indexed as a dimension: `temperature`, `pressure`, `kwh`.

**Cardinality explosion is THE structural failure of this domain, and it is stated here for business
data, not for system metrics** (that belongs to `observability-standards`): **putting a unique
identifier in as a tag — `order_id`, `transaction_id`, the `serial_number` of a fleet of millions of
devices, a session `uuid` — kills any time-series engine.** It does not degrade it: it kills it. The
symptom arrives late and always the same way: ingestion goes fine for weeks, then memory consumption
grows without a ceiling, queries become unpredictable and the engine ends up restarting. **And it is
not fixed by removing the tag: the series already created persist in the index.**

Hard rules:
- **No high-cardinality identifier as a tag.** If it has to be kept, it goes as a
  **field** (not indexed) or in a separate **dimension table**, joined at query time.
- **A series budget declared up front**: multiply the cardinalities of your tags
  before writing the first line. If the product exceeds what your engine can take, the design is
  wrong, not the engine.
- **Alert on the number of active series**, not just on disk and CPU. It is the leading
  indicator that avoids the incident.
- **If your data is intrinsically high-cardinality** — one measurement per order, per transaction,
  per user — **the tag model is the wrong model**. Use a **columnar engine without a series
  index** (ClickHouse, TimescaleDB with a normal column): there, cardinality is just another column,
  not a combinatorial explosion. **This is the most useful family-selection criterion in the whole
  section.**

### 3.2 Wide versus narrow schema

| Model | Shape | When |
|---|---|---|
| **Narrow** (`ts, series, metric, value`) | One row per measurement | Heterogeneous and changing metrics; adding a magnitude does not touch the schema. **Cost: more rows, and comparing two magnitudes requires a self-join or a pivot** |
| **Wide** (`ts, series, temperature, pressure, flow, …`) | One row per sampling instant, one column per magnitude | **Default when the set of magnitudes is stable** and they are sampled together. Fewer rows, better columnar compression, trivial queries |

Rule: **if the equipment emits the same N magnitudes at the same instant, the schema is wide.** The
narrow one is chosen when the catalogue of magnitudes is open or changes outside your control. Decide
it in writing: **changing it later means rewriting the history.**

In addition:
- **`timestamptz` always, and storage in UTC, without exception.** The time zone is a
  presentation decision. Daylight-saving changes destroy series stored in local time, and the
  bug appears twice a year for years.
- **Declared time resolution** (second, millisecond, microsecond) and consistent with what the
  equipment can really measure. Storing nanoseconds from a sensor that samples every 5 s is cost
  without information.
- **Measurement quality is part of the data**: in OT, the point's `quality`/status and the
  engineering unit are stored; a reading with no quality flag cannot be audited afterwards.

### 3.3 Retention, resolution and *downsampling*

**This is a business decision and it has to be extracted from the business in writing.** A tiered
pattern, which is the one that works:

| Tier | Resolution | Typical retention | What for |
|---|---|---|---|
| **Raw** | The sampling one | Weeks or a few months | Fine diagnosis, incident investigation, evidence |
| **Fine aggregate** | 1 min / 5 min | Months or 1-2 years | Operational dashboards |
| **Coarse aggregate** | 1 h / 1 day | Years | Trend, reports, legal obligation |

Rules:
- **The aggregate is computed incrementally and continuously** (TimescaleDB continuous aggregates,
  `AggregatingMergeTree` + TTL with `GROUP BY` in ClickHouse, the engine's *rollup* rules), **not with
  a home-made job that recomputes the whole month every night**.
- **Decide which function aggregates each magnitude**: average for temperatures, **sum for counters**,
  **last value for accumulators**, min/max when the peak is the datum that matters. **Aggregating a
  counter by average is a silent business error** nobody detects until the audit.
- **Store `count` and `sum`, not just the average**: with the average you cannot re-aggregate to a
  larger window without bias. With `sum` and `count`, you can. And **percentiles cannot be
  averaged**: if you are going to be asked for them, store a *sketch* or the raw data.
- **Retention applies itself and gets verified**: engine policy or a scheduled partition `DROP`,
  with an alert if it did not run. A retention policy nobody checks is an intention.
- **Before deleting the raw data, ask whether there is an obligation to keep it** (sector regulation,
  contract, equipment warranty, litigation). See `grc-compliance-standards` and
  `privacy-engineering-standards`.
- **Alternative to deletion: move to cold.** Old detail in Parquet over object storage costs a
  fraction and remains queryable (`lakehouse-standards`). **The right decision is often not "delete
  or keep", it is "keep where".**

### 3.4 Ingestion

- **In batches, always.** Point-by-point writing is the number one performance mistake of the
  domain: it collapses the engine through per-request overhead long before it does so through data
  volume. Batch by size **and** by maximum wait time, so as not to sacrifice freshness.
- **Protocol**: prefer **SQL** or the engine's native protocol when the producer is yours;
  **line protocol (InfluxDB Line Protocol / ILP)** when the producer is an agent or a piece of field
  equipment that already speaks it; Prometheus *remote write* **only** if the source is an exporter
  (and then check whether the case really belongs to `observability-standards`). **Choose the
  protocol by the producer, not by taste.**
- **Out-of-order and late data**: in IoT with intermittent connectivity **this is normal, not the
  exception** — a piece of equipment with no coverage dumps 8 hours at once. Before choosing an
  engine, **check explicitly what it does with a write far earlier than the last one**: some accept
  it at a cost, others discard it silently, and in engines with block compression a write into an
  already compressed block **forces decompression and rewriting**, which is very expensive.
  **Silent discard = loss of industrial data. It is an engine-elimination criterion.**
- **Device timestamp versus reception timestamp**: store **the event's** as the series time,
  and consider also storing the ingestion one. Field clocks drift:
  **validate at the edge** for a reasonable range and divert the impossible (dates in 1970 or in 2049)
  to quarantine, instead of putting it into the series.
- **Idempotency**: resends happen. A natural key `(series, ts)` with an
  *upsert*/last-write-wins write, and **decided on purpose** — many series engines **do not
  deduplicate** and you end up with the duplicate point, which throws off the sums.
- **Updates and deletes are THE expensive operation.** These engines are designed not to do
  them. Consequences to accept in advance: correcting a badly ingested history is a project, not an
  `UPDATE`; **deleting the data of a single device or a single person can be
  disproportionately costly**, so if there is a right to erasure, **partition by something that
  allows block deletion** or encrypt per subject (see `privacy-engineering-standards`).
- **Massive backfill**: done with compression and aggregates **disabled or paused** when
  the engine allows it, and re-enabled at the end. And measured in a mirror environment first.

### 3.5 Querying

- **SQL is the default, and the reason is about staffing, not elegance**: anyone who knows SQL can
  query your store, and **every BI tool speaks SQL**. A proprietary language
  — Flux is the expensive example — ties you to an ecosystem, has no labour market and **can
  disappear with a major version change of the product** (§2.4). **Adopting an engine with a
  proprietary language requires an ADR with an exit cost.**
- **Every query carries a bounded time-range filter**, and the filter must allow partition/*chunk*
  pruning: no wrapping the time column in a function that prevents the partitioning from being used.
  A query without a time bound over a TSDB is a full scan in disguise.
- **Aggregation by time *bucket*** (`time_bucket`, `SAMPLE BY`, `toStartOfInterval`,
  `GROUP BY` over truncated time) is the domain's primitive; **set the *bucket*'s time zone
  explicitly** when the report is a business one: "per day" means local day for the user and
  UTC day for the engine, and that is where reports fail to reconcile.
- **Gaps and interpolation are business decisions, and they must be declared**: is a sensor that did
  not report a zero, a null, or the last known value? **Zero and last-known-value give radically
  different results** in a consumption calculation. Use the engine's primitive
  (gap filling, `LOCF`, linear interpolation) **and document which one was applied in the report**.
- **Query the aggregate, not the raw data**, for anything that is a dashboard. If the user needs to
  drill down to the raw data, let that be an explicit and time-bounded path.
- **Window functions** for deltas, rates, moving averages and last value per series: they are part of
  the engine's contract. **A series engine without decent window functions forces you to pull the
  data out and compute outside**, which is exactly what you were trying to avoid.

## 4. Quality and testing — gates

In order of increasing cost. **Those marked as a gate break the build or the deployment.**

1. **An ADR for the §2.1 rung**: why PostgreSQL is not enough, with the measured number of points per
   second and the query that hurts. **Without this document the introduction of a new engine is not
   approved.** *Design gate.*
2. **Schema, retention policies, compression policies and aggregate definitions as code**,
   versioned and applied by the pipeline. Nothing created by hand in production. *CI gate.*
3. **Cardinality budget computed and verified in CI**: the product of tag cardinalities
   against the declared limit. A change that puts a unique identifier in as a tag **breaks
   the build**. *Gate.*
4. **Out-of-order and late write test** with a point from days ago against already
   compressed data: verify that it **goes in**, and measure what it costs. *Gate.*
5. **Duplicate test**: resending the same batch does not alter sums or counts. *Gate.*
6. **Aggregate correctness test**: the *rollup* of a known window matches the
   computation over the raw data, including the correct function per magnitude (sum versus average).
   *Gate.*
7. **Retention policy test**: that what must expire expires **and only that**, verified over
   synthetic data with dates on the boundary.
8. **Performance test with realistic volume**: the critical queries against a dataset of the
   expected size **a year out**, not against a week of test data. A plan over 10 M rows
   does not predict 10,000 M.
9. **Full restore test** of the store with the engine ingesting (§6). Done before
   production.
10. **Major version upgrade rehearsal** on a mirror with representative data, verifying
    storage format and query compatibility.
11. **Dependencies and images pinned by digest**, with an SBOM (§5). *CI gate.*

## 5. Stack security

- **Mandatory TLS in transit** for ingestion and querying, including inside the network. Industrial
  telemetry travelling in the clear over a flat network is the classic finding of an OT audit.
- **Authentication and authorisation separated by role**: a **write-without-read** role for the
  field agents (a compromised device must not be able to read the plant's history), a
  read role for BI, an administration role for nobody except operations. **A device's
  token is a field secret: rotatable, minimum scope and individually revocable.**
- **Encryption at rest** (volume or engine mechanism) and data classification: a series per
  household meter, per vehicle or per wearable device **is personal data**; a plant
  production series is an industrial secret. See `privacy-engineering-standards` and
  `data-platform-standards`.
- **No series engines exposed to the Internet without authentication.** It is a real and
  recurring pattern in IoT installations: an ingestion interface left open "because the equipment is
  outside". Ingestion from the field comes in through an authenticated endpoint, or through the
  broker (see `message-brokers-standards`), not through the engine's port.
- **The exploration/query interface is also surface**: embedded panels and consoles without
  authentication expose the whole history. Behind identity, always.
- **Parameterised queries** in anything that builds SQL from user input: being a series
  engine does not make it immune to injection (there are 2026 injection CVEs in integrations that
  concatenate SQL against ClickHouse).
- **Supply chain**: pin images and clients **by digest**; generate and keep SBOMs;
  quarantine for days before adopting newly published versions. **Verified precedents in the
  catalogue**: Trivy (Mar-2026), LiteLLM (Mar-2026), `elementary-data` (Apr-2026) and **Mini
  Shai-Hulud / CVE-2026-45321**, which **forges SLSA level 3 attestations**: **provenance is no
  longer sufficient proof on its own**.
- **Watch the CVEs of the specific engine and its images** (see `vulnerability-management-standards`).
  ClickHouse publishes its own security changelog and *distroless* images since Apr-2026, which
  greatly reduce scanner noise in exchange for having no shell inside the container.

## 6. Performance and operability

- **Compression: measure it, do not assume it.** The ratios vendors publish are obtained with regular,
  low-entropy series. The real effect depends on your data. What is general:
  **ordering by `(series, time)` before compressing is what makes compression work** —
  a storage order that interleaves series destroys the ratio. Measure **space and query
  time before and after**, on your data.
- **Store SLIs**: points ingested per second and their rejection rate, **lag between the data's
  timestamp and its availability for querying** (freshness, which is the metric the business cares
  about), **number of active series** (§3.1), p95/p99 latency of dashboard
  queries, continuous aggregate lag, compression ratio and **projected disk
  growth**. Instrumentation and backend: `observability-standards`.
- **Isolate the uses.** If the same engine serves platform monitoring **and** business data,
  separate them into different instances or clusters: a cardinality spike on the metrics side
  cannot take down the plant's production history, nor the other way round. **And their retentions
  answer to different owners.**
- **Replicas**: replicate to tolerate a node failure **and** to separate continuous ingestion from
  heavy analytical queries. **Check first which replication model the free edition of your engine
  offers**: in several of the options in §2.3, high availability lives in the commercial
  edition (InfluxDB 3, and VictoriaMetrics Enterprise features). **Discovering it after
  choosing is the expensive mistake.**
- **Backing up an engine that ingests non-stop**: a hot file copy **is not a consistent
  backup**. Use the engine's snapshot/backup mechanism (or a volume snapshot with the engine in a
  consistent state), verify the copy and **rehearse the full restore on a scheduled
  cadence**: the gate is "we restored and validated", not "the job finished"
  (`backup-recovery-standards`). **Budget the restore time**: restoring compressed terabytes
  is slow, and that number is your real RTO, not the one you put in the document.
- **Beware the argument "retention is already my backup"**: retention deletes, it does not protect.
  An accidental deletion or a corruption propagates to the replicas. **Retention is not a backup**
  (§7).
- **Upgrades**: major version changes with the release notes read, a rehearsal on a mirror and a
  **defined rollback plan**, knowing whether the storage format changes (if it does, the rollback
  requires restoring, not just deploying the previous version). Never a `.0` in
  production.
- **Capacity**: project with data — points/s × bytes/point after compression × retention per
  tier — and review quarterly. **Disk, retention and resolution are the same decision**: if the
  disk does not stretch, the right answer is usually to lower the resolution of the history, not to
  buy disk.
  **Mandatory prior check**: if that series feeds a model's training, the *rollup*
  **destroys the dataset** and with it the reproducibility `mlops-standards` demands. The
  resolution of the history stops being a storage decision the moment there is a model
  behind it: it is agreed with whoever trains it, or the raw series of the signals it uses is kept.

### 6.1 Industrial cases (OT/IoT) and their boundary

- **The modern TSDB does not by itself replace an industrial historian.** A historian also provides
  asset context, point quality, event and alarm management, and integration with
  the control system. If that is the requirement, **the TSDB is a piece, not the solution**.
- **The boundary with the OT world is declared and respected**: the control system, the plant
  protocols (OPC UA, Modbus and the rest), industrial network segmentation and the level model of the
  plant architecture **do not belong to this skill** — the network and its segmentation belong to
  `networking-standards` and `firewall-policy-standards`, and the security policy to
  `grc-compliance-standards`. **Here the work starts at the point where the measurement leaves the
  plant towards the store, and never the other way round: the flow is from OT to IT,
  unidirectional.**
- **Design for disconnection**: store-and-forward at the edge, ingestion that tolerates the later
  mass dump (§3.4) and a control that this dump does not take down normal ingestion
  (rate limiting on the consumer).
- **The timestamp is set by the equipment, and its clock lies.** Time synchronisation at the edge
  as a design requirement, and validation at ingestion.

## 7. Sustainability and prohibitions

- **Cadence**: review the engine's version, licence **and ownership** **every quarter**. This domain
  has seen a company rename (Timescale→TigerData), an engine change with the loss of a query language
  (InfluxDB) and several *open core* models moving features into the paid edition.
- **Active retirement**: a series, table or policy with no measured queries for two quarters is
  flagged and retired. **A series store grows by silent accumulation**: nobody deletes anything
  because nobody knows who uses it.
- **Mandatory ADR** for: introducing an engine other than PostgreSQL, choosing a wide or narrow
  schema, setting the resolution and retention tiers, adopting an engine with a proprietary query
  language, and depending on a commercial edition feature.

**FORBIDDEN**
- ❌ Adopting a TSDB without having measured the real workload or ruled out, in writing, partitioned
  PostgreSQL with BRIN and materialised aggregates.
- ❌ Using "it's time-series data" as an engine justification.
- ❌ **A high-cardinality identifier as a tag.** It is the structural failure of the domain.
- ❌ Deploying without a computed series budget or an alert on active series.
- ❌ Point-by-point writing on the hot ingestion path.
- ❌ Choosing an engine without checking what it does with out-of-order and late writes; accepting an
  engine that **discards them silently** for an IoT case.
- ❌ Storing the timestamp in local time, or without a time zone.
- ❌ Storing only the average in an aggregate (it prevents unbiased re-aggregation); averaging
  percentiles; **aggregating a counter by average**.
- ❌ A store without a retention policy applied automatically and **verified**.
- ❌ Deleting the raw detail without having checked whether there is a retention obligation.
- ❌ A dashboard query against the raw data when the aggregate exists; a query without a bounded time
  range.
- ❌ Filling gaps with an implicit criterion not documented in the report.
- ❌ Trusting the correction of a history to mass `UPDATE`/`DELETE` as if it were an ordinary
  table.
- ❌ Ingestion or exploration console exposed without authentication; optional TLS "because it's the
  internal network".
- ❌ The same cluster for platform monitoring and business data.
- ❌ Copying the engine's files hot and calling it a backup; **using retention as a backup**; not
  rehearsing the full restore or measuring how long it takes.
- ❌ Adopting an engine whose high availability lives in the commercial edition **without having
  decided so on purpose**.
- ❌ Using the broker as a series store (see `message-brokers-standards`).
- ❌ Starting something new on InfluxDB 1.x/2.x or on Flux; depending on the `latest` tag of an
  InfluxDB image.
- ❌ Adopting an AGPL engine without explicit approval from the organisation's licence policy.
- ❌ Fixing an engine's versions, licences or ownership from memory (§8).

## 8. Mandatory web verification

The §2 data is from **August 2026**, taken from `api.github.com` (versions and dates) and from the raw
`LICENSE` files (licences). Before committing to anything in a deliverable, verify:

1. **TimescaleDB / TigerData**: version (**2.29.0**, 28-Jul-2026) and, above all, **the current
   licence and its scope**. Verified *verbatim* in `LICENSE`: **Apache 2.0 outside `tsl/`,
   Timescale License inside `tsl/`, with separate `-tsl` binaries**. The company renamed itself to
   **TigerData on 17-Jun-2025** and the TSL appears as the *Tiger Data License*. **Check in the
   official documentation which specific features fall on each side before counting on any of them**
   (compression, continuous aggregates and policies have historically lived on the TSL side: do not
   assert it without checking it in your version).
2. **InfluxDB**: the current line (**3.10.0**, 17-Jun-2026), the licence of the v3 engine repository
   (**Apache-2.0 + MIT**, corresponding to **Core**), the maintenance status of 1.x and 2.x, the
   absence of Flux in line 3, and **which exact features require Enterprise** (high availability,
   multi-node, compaction for long ranges). Also verify the change to the Docker `latest` tag planned
   for **15-Sep-2026**.
3. **ClickHouse** (26.7.2.59-stable, 3-Aug-2026, Apache 2.0), **QuestDB** (9.4.3, 15-Jun-2026,
   Apache 2.0), **VictoriaMetrics** (v1.148.0, 20-Jul-2026; LTS v1.136.x and v1.122.x; Apache 2.0 with
   *open core* Enterprise under `-license`) and **TDengine** (`ver-3.4.1.6`, 30-Apr-2026, **AGPL v3**).
   Re-verify version **and** licence: the last three have a commercial edition and the feature split
   changes between versions.
4. **CVEs and security advisories** for the specific engine and its images; and the evolution of **Mini
   Shai-Hulud (CVE-2026-45321)** in the supply chain.
5. **Managed services**: availability, limits and pricing model of your cloud's managed offering,
   and **the format and cost of exporting the data out** before going in.

**Declared gaps in this review** (not to be filled from memory):
- **The exact split of TimescaleDB features between Apache and TSL**: the dual licence mechanism was
  verified *verbatim*; **the list of features per edition in 2.29 was not verified**. Do not
  assert that a specific feature is Apache without checking it.
- **InfluxDB 3 Core's query range limit**: the claim circulates that Core is bounded
  to short-range queries. The official documentation consulted **only** says that Enterprise adds
  *"long-range historical queries with compaction"* and multi-node; **no numeric limit in hours has
  been verified**. Do not quote a figure.
- **QuestDB Enterprise and TDengine Enterprise**: terms, price and feature split **not
  verified**.
- **ClickHouse as a time series**: the status of the time-series-specific table engine and its
  maturity were not verified. Use `MergeTree` with an ordering key and TTL, which is what was checked.
- **Real compression ratios**: **there is no independently verified figure** in
  this review. All the published ones come from vendors. Measure it on your data.
- **Performance comparisons between engines**: the available ones are published by the
  vendors themselves (including those comparing Influx with TDengine). Treat them as marketing.
- **Managed services** (Amazon Timestream and equivalents): status, limits and prices **not
  verified** in this review.
- **Recent CVEs for TimescaleDB, InfluxDB, QuestDB, VictoriaMetrics and TDengine**: **not reviewed
  one by one**. It was only confirmed that ClickHouse maintains its own security changelog and
  publishes *distroless* images since Apr-2026.

If the web contradicts this document, **the web wins** — flag the discrepancy.
