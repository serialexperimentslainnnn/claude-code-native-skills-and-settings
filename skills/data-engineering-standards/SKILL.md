---
name: data-engineering-standards
description: Use when moving or transforming data on a schedule — deciding whether a pipeline is needed at all versus a read replica, a federated query or a nightly COPY, ELT versus ETL, batch/incremental/streaming ingestion, managed connectors versus custom code (Airbyte, Fivetran, Meltano, dlt, Singer taps), SQL transformation with dbt (dbt_project.yml, models/, dbt build, dbt test, dbt Fusion) or SQLMesh (audits, virtual data environments), data-pipeline orchestration with Airflow (DAGs, @task, assets), Dagster, Prefect, Kestra or Mage, watermarks, partitions, idempotent backfill and reprocessing, Parquet layout, compression and the small-file problem, partition pruning as a cost decision, freshness SLA versus availability SLA, pipeline retries, silent pipeline failure, data lineage or the data on-call rotation.
---

# Data engineering standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when data **is moved or transformed repeatedly**: the decision of whether a pipeline is
needed at all, ingestion, transformation, orchestration, reprocessing, file formats,
scan cost, data observability and the operation of all of it.

Triggers: `dbt_project.yml`, `profiles.yml`, `models/`, `dbt run|build|test|source freshness`,
`dbt deps`, `sqlmesh plan`, `audits/`, `dag.py`, `@dag`/`@task`, `airflow dags`, `@asset`,
`dg`/`dagster dev`, `prefect deploy`, Kestra `flows/*.yml`, `meltano.yml`, `tap-`/`target-`,
`dlt.pipeline(...)`, `airbyte`, `fivetran`, `COPY`/`UNLOAD`, `MERGE`, `INSERT OVERWRITE`,
`.parquet`, `_SUCCESS`, `part-00000-*`, `watermark`, `backfill`, `reprocess`, "the pipeline
failed", "yesterday's data is missing", "the data is stale", "the report ran before the
ETL", "duplicates after the retry", "the query costs €40 every time".

**Not applicable**: see
- `data-warehouse-modeling-standards` (**sister; boundary declared on both sides**): it
  decides **the shape of the destination** —grain, facts and dimensions, SCD, layers, metrics—; this one
  decides **how the data gets there and is recomputed without breaking**. A pipeline without a model
  produces a swamp; a model without a pipeline is a diagram. If the question is "which columns and
  at what grain?", it is theirs; if it is "how do I reload March without duplicating?", it is from here.
- `data-platform-standards` (**mother**): PostgreSQL as the operational engine, Redis/Valkey, Kafka
  as an engine (partitions, retention, registry), backups and PITR, encryption at rest. Its guiding
  principle —**one store per need, not per fashion**— is inherited here without exception: this skill does not
  authorise new stores, only movement between the ones already justified.
- `lakehouse-standards`: the **table format** —Iceberg, Delta Lake,
  Hudi—, REST catalog, snapshots, *time travel*, compaction and table maintenance,
  hidden partitioning and partition evolution. Here only the **file format** (Parquet), the
  file size and idempotent writing. Cut-off rule: **if the decision is made by the
  table format, it belongs to `lakehouse-standards`; if it is made by the writing process, it is from here**.
- `streaming-cdc-standards`: Debezium, log connectors, initial *snapshot*,
  handling of `DELETE` and *tombstones*, ordering and *exactly-once* in streaming. Here only
  the **criteria for when change capture is the answer** and what it forces downstream.
- `data-governance-quality-standards`: data contracts as a programme,
  catalogue, ownership, *stewardship*, quality policy. Here their **execution in the pipeline**:
  the assertions that break the run and the freshness gate.
- `analytics-bi-standards`: the BI tool and consumption. The
  **metric definition** falls to `data-warehouse-modeling-standards`, not here.
- `microservices-architecture-standards`: **outbox, domain events and data ownership per
  service are theirs**; here only the analytical consumption of those events.
- `privacy-engineering-standards`: **retention, deletion, minimisation and personal data are theirs**;
  here they are **executed** (columns that are not copied, partitions that are dropped, environments without PII).
- `object-storage-standards`: **S3 as the substrate** —buckets, keys, storage classes,
  Object Lock, lifecycle, multipart—; here which files are written inside.
- `observability-standards`: telemetry **of the system** (OTel, Prometheus, cardinality). The
  **observability of the data** —freshness, volume, schema, distribution, lineage— is from here; the
  line is: if the signal describes the process (CPU, latency, HTTP errors), it is theirs; if it describes the
  data (it arrived late, 0 rows arrived, the schema changed), it is from here.
- `sre-practice-standards` (SLO, error budget, on-call as a practice), `incident-management-standards`
  (the incident process), `cicd-standards` (the CI pipeline that deploys the data
  pipeline), `iac-standards`, `kubernetes-standards`, `python-standards` (quality of the Python code
  of the job), `secrets-management-standards` (the store credentials),
  `identity-access-management-standards`, `backup-recovery-standards`, `bcdr-standards`,
  `grc-compliance-standards`, `aws-standards`/`azure-standards`/`gcp-standards` (Glue, Data
  Factory, Dataflow, MWAA, BigQuery/Redshift/Synapse **as managed services**),
  `mlops-standards` (**feature store, train/serve skew and the training pipeline are theirs**),
  `rag-standards` and `llm-app-engineering-standards`, `ai-governance-standards`.
- Specific engines: `nosql-standards`, `timeseries-db-standards`, `search-engines-standards`,
  `message-brokers-standards`, `graph-db-standards`, `vector-db-standards`, `oracle-dba-standards`,
  `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`.
- `r-standards` and `julia-standards`: the **platform** —ingestion, orchestration,
  idempotence, *backfill*, Parquet, freshness— is from here; the **analysis code** that runs in a
  pipeline step is theirs. If an R or Julia script has de facto become the
  orchestrator, the problem belongs to this skill.
- `scala-standards` and `python-standards` (**Spark is the most likely confusion**: the platform
  —cluster sizing, partitions, *shuffle*, output format, job orchestration and its
  idempotence— **is from here**; the **Scala or the Python written inside the job** —style,
  effects, tests, build with sbt or with `uv`— belongs to the language skill).
- `sql-standards` (**the SQL language**). **dbt/SQLMesh as a tool and the structure of the
  project are from here** —materialisations, orchestration, data tests, *backfill*,
  idempotence—; the **SQL that model contains** is subject to `sql-standards`: joins, CTEs and
  window functions, `NULL`, SARGable predicates, style and linting with `sqlfluff`. Generating the
  SQL with a template **does not exempt it** from that criterion.

**Guiding principle**: **every pipeline will run twice.** Because of a retry, a *backfill*, a
duplicated deployment or a nervous human at 3 a.m. A process that cannot be repeated
without changing the result is not a pipeline: it is a script with luck. Idempotence is not an
optimisation, it is the entry condition.

**Scepticism corollary**: this sector sells tooling at a rate no organisation
can operate. Every new piece of the *stack* is one more component to update, monitor,
secure and explain to whoever replaces you. Before adding it, demand the measured need.

## 2. Default decisions

> Verify the latest version, licence and **owner** on the web before pinning it in a real
> project (§8). This sector consolidated heavily in 2025-2026: several tools changed owner or
> licence without changing name.

### 2.1 The starting decision: is a pipeline needed?

Before choosing a tool, exhaust this order. Every rung you avoid is infrastructure you
do not operate:

| Real need | Simplest solution | When it stops working |
|---|---|---|
| Query operational data without punishing the DB | **Read replica** of the engine (see `data-platform-standards`) | Analytical queries that sweep whole tables and compete with replication |
| Occasionally cross two sources | **Federated query** (PostgreSQL FDW, DuckDB `read_parquet`/`ATTACH`, external tables) | Volume that makes federation slow or expensive; need for history |
| A daily report on yesterday's data | **Nightly `COPY`/`UNLOAD`/export** to files + queries over them | More than a handful of sources, or transformations with dependencies between them |
| A dashboard over one table | **Materialised view** in the engine itself | Crossing between different systems |
| All of the above insufficient | **Pipeline** with an orchestrator | — |

A federated query, a read replica or a nightly `COPY` solve **more cases than
the industry admits**. The cost of a pipeline is not writing it: it is keeping it alive for
five years while the sources change without warning.

### 2.2 ELT versus ETL

**ELT by default**: extract, load raw, transform **inside** the warehouse with SQL. The modern
warehouse inverted the order for three concrete reasons, not out of fashion:

1. Warehouse compute is elastic and scales better than your own ETL server.
2. The **immutable raw layer** allows reprocessing without going back to the source — and the source almost never
   lets you go back (APIs with short retention, systems that overwrite).
3. Transformation in SQL is reviewable, testable and understandable by more people than a graph in
   a graphical tool.

**ETL is still correct** when: the law forbids raw data landing (PII that must be
pseudonymised **before** loading — coordinate with `privacy-engineering-standards`), the raw
volume is absurd compared to the useful one, the source requires transformation in the same read process, or
the destination has no compute (a file, an SFTP). Decision by ADR, not by inverting the default.

### 2.3 Toolchain

| Area | Default | Verified state (Aug 2026) | Justifiable alternative |
|---|---|---|---|
| SQL transformation | **dbt Core** | dbt Labs **completed the merger with Fivetran on 1-Jun-2026**. dbt Core is still **Apache 2.0**; dbt Core v2.0 (based on the Fusion engine) published in the `dbt-core` repo under Apache 2.0, in alpha. The **dbt Fusion binary is proprietary**, under the *dbt Product Licensing Agreement* | **SQLMesh**: donated by Fivetran to the **Linux Foundation (Mar-2026)**, open governance. It is today the alternative with the best governance position, not an experiment |
| Orchestration (heavy, market standard) | **Airflow 3.3.x** | 3.3.0 (Jul-2026). **Airflow 2 reached EOL on 22-Apr-2026**: any 2.x in production is unpatched software | Astronomer/MWAA/Composer if you do not want to operate it |
| Orchestration (declarative, asset-oriented) | **Dagster 1.13.x** | **Prefect announced the acquisition of Dagster Labs on 13-Jul-2026**; the combined company operates under the Prefect name from Aug-2026. Dagster and Dagster+ remain maintained and the OSS continues under its current licence | Prefect 3.x if you already use it |
| Lightweight / declarative YAML orchestration | **Kestra 1.x** | Active releases (1.3.x branch and LTS 1.0.x) | — |
| Ingestion with code, in your process | **dlt** (1.29.x) | Python library, no server to operate. **Default when the connector does not exist** | Singer taps if there is already a good one |
| Ingestion with managed connectors | **Fivetran** (SaaS) if the budget covers it | Airbyte: platform and strategic connectors under **Elastic License 2.0** — *source-available*, **not OSI open source**; restricts offering it as a managed service | **Meltano** (4.x) to orchestrate Singer taps with versioned configuration |
| Columnar file format | **Parquet** | Still the undisputed default of the ecosystem. New formats (Vortex —incubating at LF AI & Data—, Lance, Nimble) address AI/random-access workloads: **pilot, not production** for general analytics | ORC only if the existing ecosystem imposes it; **never CSV/JSON as a destination format** |
| Local query engine / small pipelines | **DuckDB 1.5.x** | Legitimately replaces Spark in the "fits in a big machine" range, which is most of them | — |
| Compression | **zstd** by default; snappy if the engine prefers it and CPU is the bottleneck | — | gzip only for legacy compatibility |
| Distributed engine | **None by default** | Spark/Flink only when the volume does not fit in a big machine, **measured** | — |

**On orchestrators, honestly**: most organisations that install Airflow
did not need it. A `systemd` timer, a cron with locking (`flock`) and a decent log cover a
linear three-step pipeline. The orchestrator earns its cost when there are **real dependencies
between tasks, per-task retries, parameterised backfill and shared visibility** — not when
there are three jobs that run in order. Installing Airflow for that is paying for a cluster to
replace `&&`.

**On continuity risk after the consolidation**: dbt, SQLMesh, Census and Fivetran are
today under the same roof; Dagster and Prefect too. That does not invalidate any tool, but it does
force you to: (a) prefer the project with foundation governance when everything else ties —SQLMesh
is in the Linux Foundation, dbt Core is not—, (b) record in the ADR **what the exit plan is** for
the proprietary piece, and (c) not build on functionality exclusive to the commercial layer without
deciding it.

## 3. Structure and conventions

### 3.1 Pipeline layers

Three zones, with different rules. (**The shape of the consumption layer is decided by
`data-warehouse-modeling-standards`; here only the movement contract between zones.**)

1. **Raw / landing**: faithful copy of the source, **immutable**, partitioned by ingestion
   date, with provenance metadata (`_ingested_at`, `_source`, `_batch_id`, `_source_file`).
   It is not cleaned, not renamed, not corrected. Its entire value is that you can rebuild
   everything else from it.
2. **Intermediate / prepared**: typing, deduplication, name normalisation, application of
   quality rules. It is the layer where the ugly logic lives.
3. **Consumption**: the one people and BI tools see. **It must be boring**: stable
   names, stable types, no surprising logic.

### 3.2 Ingestion: choose the cheapest mode that works

| Mode | When | Trap |
|---|---|---|
| **Full (*full refresh*)** | Small tables, dimensions, sources without a change marker | Scales terribly and erases history if the source overwrites |
| **Incremental by watermark** | Table with a reliable `updated_at` and an index | **`updated_at` is almost never reliable**: misaligned clocks, bulk updates that do not touch it, deletes that leave no trace |
| **Change data capture (CDC)** | You need deletes, ordering and low latency over a DB | Coupling to the engine log; real operational load (see `streaming-cdc-standards`) |
| **Streaming** | Business latency is measured in seconds **and someone acts within those seconds** | Almost nobody needs seconds; almost everybody asks for them |

Hard ingestion rules:
- **Overlap the window**: read from `max(watermark) - Δ`, with Δ ≥ the clock skew and the write
  latency of the source. Then deduplicate by key. A window without overlap loses rows
  silently, which is the worst possible failure.
- **Deletes do not propagate by themselves.** If the source deletes physically and you ingest by
  watermark, your copy accumulates ghosts forever. Decide explicitly: CDC, periodic
  reconciliation *full refresh*, or logical deletion agreed with the source.
- **Write the watermark after confirming the write**, never before. The other way round loses
  data; this way you only reprocess.
- Store the raw file/batch before parsing it. When the parsing fails six months later, it will be
  the only thing that saves you.

### 3.3 Idempotence and reprocessing — the section that separates a pipeline from a script

- **Unit of work = partition**, not "today's run". A task receives an explicit
  interval and produces **exactly** the partition of that interval.
- **Write by partition replacement**, not by accumulation: `INSERT OVERWRITE` / `DELETE`
  of the range + `INSERT` in the same transaction / `MERGE` by key. Never a plain `INSERT` in a
  task that can be retried.
- **No `now()`, `CURRENT_DATE` or "the last file" inside the logic.** Time enters
  as a **parameter** of the run. A pipeline that queries the clock cannot reprocess the
  past, and therefore cannot be corrected.
- **Backfill = the same task, a different parameter.** If a different script is needed to reload
  March, the design is wrong. The backfill runs bounded (range by range, with a concurrency
  limit) so as not to take down the source or the warehouse.
- **Explicit business key and deduplication**: every table has a declared key and a
  criterion for "which one wins" when there are duplicates (typically the most recent by `_ingested_at`).
- **Non-idempotent side effects** (sending an email, calling an API that charges, publishing an
  event) outside the data pipeline, or protected by an idempotency key and a run
  log. A retry must not bill twice.
- **Files: write to a temporary location and rename/publish at the end** (or use the atomic commit of the table
  format, see `lakehouse-standards`). A consumer must never see a half-written partition.

### 3.4 Formats and files

- **Parquet as the columnar default** for all persisted analytical data. CSV only as an exchange
  format with third parties; JSON only as the raw landing of an API.
- **Target file size: ~128 MB - 1 GB** per file (adjust to the engine). The **small-file
  problem** is real and expensive: thousands of 2 MB files multiply the requests to
  S3, bloat the metadata and sink the planner. Compact as a scheduled task.
- Partition by the column you **filter** on, normally the event date (not the ingestion one) —
  and with **low cardinality**. Partitioning by `user_id` generates a million directories and is an
  incident, not a design.
- Correct types in the file: dates as date, decimals as decimal (**money never in
  float**), *timestamps* with zone. A Parquet with everything as `string` wastes the whole format.
- Write the schema, do not infer it on every read. Schema inference is the number one
  cause of "the pipeline worked yesterday".

### 3.5 Cost: partitioning is a money decision

In BigQuery, Athena, Snowflake, Redshift Spectrum and any engine over object storage **you pay
per data scanned**. Therefore:

- **Partition pruning verified, not assumed**: review the plan (`EXPLAIN`, estimated bytes) of
  the expensive queries. A function over the partition column in the `WHERE` cancels the whole
  pruning and multiplies the bill without warning.
- `SELECT *` on a wide columnar table is a cost error, not a style one.
- **Materialise what is queried many times**; leave as a view what is queried rarely. The
  intermediate table nobody queries is paid for on every run and nobody reads it.
- Budget per query and per project, with an alert. Cost is an SLI (§6), not a surprise at the
  end of the month.
- The nightly *full refresh* of a table with billions of rows is correct exactly
  until you see what it costs per year. Then it becomes incremental, with periodic full
  reconciliation.

## 4. Quality and testing — gates

In order of increasing cost. **The ones marked as a gate break the build or the run.**

1. **SQL and Python lint and formatting** (`sqlfluff`/the ecosystem's formatter, `ruff` — see
   `python-standards`). *CI gate.*
2. **The project compiles without running anything**: `dbt parse`/`dbt compile`, `sqlmesh plan` in a virtual
   environment, `airflow dags list`/import of all DAGs without error. A DAG that does not import breaks the
   whole *scheduler*. *CI gate.*
3. **No credentials or references to production in the repo**: profiles and
   connections come from a secrets manager (see `secrets-management-standards`). *CI gate.*
4. **Unit tests of the transformation logic** with fixed input data and expected output
   (`dbt` unit tests, `sqlmesh` unit tests, or SQL over fixtures). Cover the happy path **and the
   edges**: nulls, duplicates, a row arriving twice, empty string versus null, value outside
   the catalogue, date in the future. *CI gate.*
5. **Data assertions at run time** (not in CI): key uniqueness, no nulls in the
   critical columns, referential integrity against the dimension, accepted range/values, and
   **volume within the expected band**. The detail of the quality programme belongs to
   `data-governance-quality-standards`; here the rule is about execution:
   - A **blocking** assertion stops the publication of the consumption layer. Publishing bad
     data is worse than not publishing.
   - A **warning** assertion stops nothing but is counted and reviewed; if nobody looks at it,
     delete it — quality noise trains the team to ignore quality alerts.
6. **Source freshness** (`dbt source freshness` or equivalent) **before** transforming: if the
   source has not arrived, you do not silently transform over stale data.
7. **Idempotence tested explicitly**: a test that runs the same partition **twice** and
   checks that the result is identical (same count, same checksum). Without this test,
   idempotence is an intention. *CI gate in pipelines that write.*
8. **Isolated development environment** per branch/user (own schema, SQLMesh virtual environment,
   dbt `target`): nobody develops against production tables.
9. **Differential run on PR**: build only what changed and what is downstream, over a
   bounded sample, and compare against production when the engine allows it. A PR that has never been
   run is not reviewed.
10. **No real PII in non-production environments** (see `privacy-engineering-standards`). *Gate.*

## 5. Stack security

- **Supply chain — a live precedent, not a hypothesis**: the package **`elementary-data` 0.23.3`**
  (a quality tool of the dbt ecosystem, >1M downloads/month) was published with an **infostealer**
  on 24-Apr-2026, via script injection in a GitHub Actions workflow triggered by a PR
  comment; the *payload* travelled in a `.pth` file that Python executes **when the interpreter starts**, and
  it stole dbt profiles, Snowflake/BigQuery/Redshift credentials, AWS/GCP/Azure keys,
  Kubernetes secrets, API tokens, SSH keys and `.env` files. Fixed in 0.23.4. In the
  same period: **LiteLLM** (Mar-2026) and **Microsoft `durabletask`** (May-2026) on PyPI. Mandatory
  consequences:
  - **Pin dependencies by hash** (`uv.lock`/`requirements.txt` with hashes, images by
    *digest*). An open version range in a data tool = warehouse credentials
    exposed to the next malicious release.
  - **Delay the adoption** of newly published versions in the environments that hold production
    credentials (a quarantine window of days, not minutes).
  - The *runner* that executes the pipeline **must not hold credentials for more than one environment**.
  - Publish with OIDC and ephemeral tokens; never static long-lived tokens (see `cicd-standards`).
- **Warehouse credentials**: one identity per pipeline, with permissions per schema/dataset, not
  one omnipotent shared service account. Write only where it writes; read only where it
  reads. Managed rotation (see `secrets-management-standards`).
- **Least privilege at the source**: the extraction user is **read-only**, over the specific
  agreed tables or views, with a `statement_timeout` so as not to take down the operational
  system. Extract from a replica, not from the primary, unless there is a reason.
- **Minimisation at extraction**: do not copy columns you are not going to use. Every PII column you
  do not ingest is a retention, deletion and breach problem you will not have
  (see `privacy-engineering-standards`).
- **Retention in the raw layer too**: "we keep the raw data forever" is a privacy and
  cost decision that someone has to sign off. Partition by date so you can `DROP`.
- **Encryption in transit and at rest** in every hop, including the intermediate buckets and the
  landing zones (SFTP, `/tmp`, the *worker*'s disk).
- **PII out of logs and error messages**: a pipeline log that prints the failing row is
  a leak. Log the key or the offset, not the content.
- **Never SQL by concatenation** of run parameters (dates, table names) in jobs
  that receive external input: parameterise or validate against an allowlist.

## 6. Performance and operability

### 6.1 Data observability (distinct from system observability)

The process can finish green and the data be wrong. **Silent failure is worse than an
outage**: an outage is visible; a table that has been three weeks stale is
discovered in a board meeting. Instrument four signals per dataset:

| Signal | What it measures | Typical alert |
|---|---|---|
| **Freshness** | Age of the most recent data | Exceeds the agreed freshness SLA |
| **Volume** | Rows/bytes of the last partition | Outside the band relative to history (includes **0 rows**, the most common and least alerted failure) |
| **Schema** | Columns, types, nullability | Unannounced change at the source |
| **Distribution** | Nulls, cardinality, ranges of critical columns | Abrupt drift |

In addition: column-to-column **lineage** when the engine allows it, or at least table to table.
Lineage is not documentation: it is what answers the only two questions of a data
incident —**"what broke?"** and **"what depends on it?"**— and what allows warning the
affected before they decide on false data.

### 6.2 Freshness SLA versus availability SLA

They are **different** and are constantly confused. The table can be 100 % available and
contain data from the day before yesterday. Publish, per consumption dataset:

- **Committed freshness** ("orders are up to date at 07:00 on a working day").
- **Correction window** ("corrections from the last 3 days are reprocessed; further back,
  on request").
- **Owner** and contact channel.

Without that published commitment, every consumer invents their own and they are all wrong.

### 6.3 Operation

- **Retries with backoff and jitter**, with a cap. An infinite retry against a downed source is
  a denial-of-service attack against your own provider.
- **Timeouts on everything**: query, task and the whole DAG. A task without a timeout can block the
  *slot* and stop everything else from running while freshness degrades silently.
- **Bounded concurrency** per source (*pools*): the pipeline must not be able to take down the
  operational system it extracts from. This is especially true in *backfills*.
- **Actionable alerts**: alert on a **symptom with impact** (dataset X breaches its freshness
  SLA), not on "task Y failed" when the retry is going to solve it. Every alert carries a
  runbook: what broke, what depends on it, how it is reprocessed.
- **Data on-call rotation**: if there are freshness commitments, there is someone who answers. If nobody
  answers out of hours, **do not promise freshness out of hours** — an SLA with no
  on-call behind it is a documented lie. Coordinate with `sre-practice-standards`.
- **Reprocessing runbook** written and **rehearsed**: how to reload a day, how to reload a month,
  how long it takes, how much it costs and who has to be notified. It is rehearsed on a schedule; on the day of the
  incident you do not improvise a `MERGE`.
- **Communication to the consumer**: when published data was incorrect, correcting it is not enough.
  It has to be said. Trust in the data platform is lost through silence, not through errors.
- Capacity and cost reviewed on a cadence: volume growth, duration of the critical
  runs (does the nightly window still fit in the night?), cost per dataset.

## 7. Sustainability and prohibitions

- **Update cadence**: majors of the orchestrator and of the transformation engine with a
  rehearsal in a mirror environment; EOLs are planned ahead (precedent: Airflow 2 died
  on 22-Apr-2026 and dragged down whoever did not look). Review licences and ownership
  of the pieces **quarterly**: in this sector they change without the product name changing.
- **Active retirement**: every dataset and every DAG with no measured consumption for a quarter is marked
  for retirement and retired. A data warehouse grows by accumulation by default; pruning is part
  of the work, not an optional clean-up.
- **Mandatory ADR** for: adopting an orchestrator, changing the transformation engine, choosing a
  partitioning strategy, introducing streaming, and contracting a SaaS piece with data inside.
- Avoid building on functionality exclusive to the commercial layer of a tool without
  recording the exit cost.

**FORBIDDEN**
- ❌ A pipeline without having first ruled out a read replica, a federated query or a nightly export.
- ❌ A process that cannot be run twice with the same result.
- ❌ `now()`/`CURRENT_DATE`/"the last file" inside the transformation logic: time is
  a parameter.
- ❌ A *backfill* script different from the normal pipeline.
- ❌ Writing the watermark before confirming the data write.
- ❌ An incremental window without overlap, or incremental without an explicit plan for source deletes.
- ❌ Transforming the raw layer: it is immutable. Correcting the raw destroys the ability to reprocess.
- ❌ Writing to a path that consumers read while it is being written (without atomic publication).
- ❌ Publishing the consumption layer with the blocking assertions red.
- ❌ A data alert without a runbook, or an alert nobody attends to.
- ❌ Promising a freshness SLA with no on-call to sustain it.
- ❌ Tolerated silent failure: "0 rows" is not success.
- ❌ CSV or JSON as an analytical destination format; Parquet with everything typed as `string`.
- ❌ Thousands of small files without a compaction task.
- ❌ Partitioning by a high-cardinality column.
- ❌ `SELECT *` on wide columnar tables in production.
- ❌ Writing a connector for a source that already has a maintained and acceptable one — and its converse:
  adopting a whole ingestion platform for two sources that `dlt` solves in 40 lines.
- ❌ Streaming because it sounds better, with nobody acting within the latency being bought.
- ❌ Spark because the data "is big", without having measured that it does not fit in one machine.
- ❌ Dependencies not pinned by hash/digest in any process with warehouse credentials (§5).
- ❌ A shared service account with full permissions for all pipelines.
- ❌ Copying PII columns "just in case"; PII in pipeline logs.
- ❌ A raw layer with no declared retention policy.
- ❌ Pinning versions, licences or ownership of a tool from memory (§8).

## 8. Mandatory web verification

The data in §2 and §5 is from **August 2026** and this sector consolidates constantly. Before
pinning anything in a deliverable, verify:

1. **dbt**: current licence of dbt Core (Apache 2.0 as of today), state of dbt Core v2.0
   (it was in **alpha**) and of the Fusion binary (proprietary, *dbt Product Licensing Agreement*), and
   what has changed in governance after the merger with Fivetran (completed 1-Jun-2026).
2. **SQLMesh**: state in the Linux Foundation after the Mar-2026 donation and the project's real
   activity.
3. **Orchestrators**: current Airflow version (3.3.0 in Jul-2026) and its support calendar;
   **evolution of Dagster after the acquisition by Prefect (announced 13-Jul-2026)** — the
   product integration and the OSS licence are the risk to watch, not the version;
   state of Kestra and of Mage (verify whether Mage is still maintained before recommending it:
   **not verified in this revision**).
4. **Ingestion**: current Airbyte licence (ELv2, *source-available*), Fivetran's model after the
   merger, and the activity of Meltano and dlt.
5. **Formats**: whether Parquet is still the de facto default and whether any successor (Vortex, Lance,
   Nimble, F3) has moved from pilot to production; state of Iceberg's *File Format API*
   (boundary with `lakehouse-standards`).
6. **Supply chain**: CVEs and recent compromises of **any** package you are going to
   add to the environment with warehouse credentials (precedents: `elementary-data` Apr-2026,
   `durabletask` May-2026, LiteLLM Mar-2026).
7. Versions and EOL of the warehouse engine (BigQuery/Snowflake/Redshift/Databricks/DuckDB) and of the
   pipeline's Python *runtimes*.

**Declared gaps of this revision** (do not fill from memory):
- **Mage**: its maintenance state not verified. Do not recommend it without checking.
- **Prefect/Dagster**: not verified whether there is a public long-term OSS licence commitment beyond
  "the open source project continues under its existing license"; the press release does not
  detail it. Verify before betting orchestration on Dagster for five years.
- **Parquet v3**: there is discussion on the Apache mailing list, with no verified state. Do not
  claim anything about a v3.
- **Fivetran**: pricing and terms after the merger not verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
