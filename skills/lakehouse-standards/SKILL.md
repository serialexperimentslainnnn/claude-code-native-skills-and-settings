---
name: lakehouse-standards
description: Use when analytical data lives as an open table format on object storage — deciding whether a lakehouse is warranted at all versus PostgreSQL or a managed columnar warehouse, choosing between Apache Iceberg, Delta Lake, Apache Hudi and Apache Paimon, Iceberg spec v2 versus v3 (deletion vectors, row lineage, VARIANT type), reading the metadata tree of metadata.json, manifest lists, manifest files and snapshots, picking the catalog as the real architecture decision (Iceberg REST Catalog API, Apache Polaris, Unity Catalog, AWS Glue Data Catalog, Project Nessie, Apache Gravitino, Lakekeeper, legacy Hive Metastore/Thrift) and its credential vending, hidden partitioning and partition-spec evolution, expire_snapshots, remove_orphan_files, rewrite_data_files and rewrite_manifests as scheduled maintenance, copy-on-write versus merge-on-read and the real cost of MERGE and DELETE, optimistic concurrency and commit conflicts between two writers, reading one table from Spark, Trino, DuckDB, ClickHouse or Flink, pyiceberg or delta-rs, time travel and snapshot retention, table registration and catalog migration, or table/row/column access control and legally mandated deletion inside an immutable format.
---

# Lakehouse standards (open table format)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: a lakehouse **is not a Parquet directory with a marketing name**. It is a
> **table format** —a versioned metadata tree on top of a bucket— that buys you ACID, schema
> evolution, *time travel* and concurrent read/write, and **is paid for in catalog, compaction and
> permanent maintenance**. If you are not going to run that maintenance, you do not have a lakehouse:
> you have a swamp with snapshots.

## 1. Scope and triggers

Applies to the **table format** and to everything decided from it: format choice, catalog,
metadata anatomy, partitioning and its evolution, table maintenance, write concurrency,
query engines over the same data, update and delete strategy, and table-level governance/security.

Triggers: `metadata.json`, `snap-*.avro`, `manifest-list`, `.metadata/`, `_delta_log/`,
`.hoodie/`, `format-version`, `iceberg.catalog.type`, `catalog-impl`, `warehouse=`,
`spark.sql.catalog.*`, `USING iceberg` / `USING delta`, `CALL ... system.rewrite_data_files`,
`expire_snapshots`, `remove_orphan_files`, `rewrite_manifests`, `VACUUM`, `OPTIMIZE`, `ZORDER`,
`MERGE INTO`, `FOR SYSTEM_TIME AS OF` / `VERSION AS OF`, `pyiceberg`, `delta-rs`/`deltalake`,
`iceberg-rest`, `polaris`, `nessie`, `gravitino`, `lakekeeper`, `unitycatalog`, `glue_catalog`,
`hive metastore`, `thrift://`, `s3tables`, and the phrases that give the domain away: "the query
reads 50,000 files", "the bucket keeps growing", "two jobs collide when writing the table",
"I need to see the table as it was on Tuesday", "we changed the partitioning and now everything has
to be rewritten", "deleting a user does not apply to the history".

**Not applicable**: see
- `data-engineering-standards` (**sister; cut rule already written there and mirrored here without
  changes**): the **file format** —Parquet, file size, compression, file typing— is
  **theirs**; the **table format** —Iceberg/Delta/Hudi, catalog, snapshots,
  compaction, hidden partitioning— **belongs here**. **If the decision is made by the table format,
  it belongs here; if it is made by the process that writes, it is theirs.** Corollary: ingestion, orchestration,
  job idempotency, the *backfill* and the small-files problem **at source** are
  theirs; **compaction as a table operation** belongs here.
- `data-warehouse-modeling-standards` (**thin boundary, declared on both sides**): the *time
  travel* of a table format gives you back **the table as it was**; an **SCD type 2** tells you
  **how the business entity was**. They are different things: the former is an infrastructure
  capability for recovery and technical audit, with retention of days or weeks; the
  latter is a modelling decision the business queries indefinitely. **Replacing an SCD2
  with *time travel* is forbidden there and it is forbidden here** (§7). Grain, facts, dimensions and
  metrics are theirs; this skill models nothing.
- `data-platform-standards` (**mother**): **PostgreSQL, Redis/Valkey, Kafka as an engine** (topic
  partitions, retention, *schema registry*), engine backups and PITR, encryption at rest. Its
  guiding principle —**one store per need, not per fashion**— is inherited here without exception and is
  precisely the filter of §2.1: **this skill does not authorise a lakehouse, it decides how to do
  a already-justified one well.**
- `object-storage-standards`: **the substrate is theirs** — buckets, bucket policy, storage
  classes and their retrieval latency, Object Lock and *legal hold*, object versioning, lifecycle,
  multipart, `AbortIncompleteMultipartUpload`, checksums, **cost per request and per
  egress**, and the antipattern of mounting S3 as a disk. Here, what **key structure and what request
  pattern** a table format produces on top, and what it demands from the bucket. Arbitration rule:
  if the question is about the **bucket**, it is theirs; if it is about the **table**, it belongs here. Cross
  warning: **Object Lock in *compliance* mode and a table with `expire_snapshots` are incompatible
  in practice** — maintenance will not be able to delete anything (§5).
- `streaming-cdc-standards` (**sister; boundary declared on both sides**): **how changes are captured
  and how they are processed in motion** is theirs —transaction log, Debezium, initial *snapshot*,
  replication slots, delivery semantics, per-partition ordering, windows and watermarks—.
  Here, **what happens to the table when those changes land**: *copy-on-write* versus
  *merge-on-read*, cost of `MERGE`/`DELETE`, delete files and deletion vectors,
  flow-induced compaction. **CDC is a typical lakehouse source, not the only one**: the
  lakehouse is fed just as well in batch; and CDC feeds other destinations just as well (a replica, a
  cache, a search index). Neither skill presupposes the other.
- `microservices-architecture-standards`: **outbox, sagas, domain events and per-service data
  ownership are theirs**. A domain event is not a row of an analytical table.
- `privacy-engineering-standards`: **retention, minimisation, pseudonymisation, *crypto-shredding* and
  data subject rights are theirs**. Here only the **technical constraint** imposed by an
  immutable format with history and how deletion is executed inside it (§5.3).
- `data-governance-quality-standards` (**already on disk**): **business and metadata** catalog
  (DataHub, OpenMetadata, Collibra, Atlan…), ownership and *stewardship*, glossary, data contracts,
  lineage as a programme and quality as a discipline. **Mandatory boundary because of the "catalog" homonym**:
  the catalog in this document (Polaris, Glue, Unity, Nessie, Gravitino) is a **runtime
  component** that resolves the table pointer, sequences the *commits* and issues
  credentials; theirs is a **documentary and governance inventory**. Cut rule: **if the
  component is on the path of a query, it belongs here; if it is on the path of a person who
  searches for or governs a dataset, it is theirs.** Unity Catalog appears in both lists precisely because
  it tries to be both things — its Iceberg catalog facet belongs here.
- `analytics-bi-standards`: the BI tool and consumption.
- `message-brokers-standards`: the broker as a component.
- `nosql-standards`, `graph-db-standards`, `vector-db-standards`, `search-engines-standards`,
  `timeseries-db-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`: other stores, with their own criteria.
- `aws-standards`/`azure-standards`/`gcp-standards`: **Glue, S3 Tables, Databricks, BigQuery,
  Fabric/OneLake as managed services** —provisioning, IAM, network, billing—; here the
  format and catalog criteria that apply equally in all three.
- `backup-recovery-standards` and `bcdr-standards`: **time travel is not a backup**
  (§7). What is copied, with what chain and how the restore is proven is theirs.
- `identity-access-management-standards` (the identity the catalog authenticates),
  `secrets-management-standards` (the credentials the catalog *vends*),
  `observability-standards`, `sre-practice-standards`, `iac-standards`, `cicd-standards`,
  `kubernetes-standards`, `grc-compliance-standards`, `mlops-standards`, `rag-standards`,
  `python-standards` (`pyiceberg`, `delta-rs`), `jvm-spring-standards` (the JVM and its tuning under the
  engines), `scala-standards` (**the Scala written inside a Spark or Flink job**:
  here the table format, the catalog and maintenance; there the code).
- `sql-standards` (**the SQL language**). Boundary named because **`MERGE` appears in both**:
  here it is an **operation on the table** —copy-on-write versus merge-on-read cost, delete
  files, compaction, snapshots it leaves behind—; there it is a **clause that is written**
  —match conditions, non-determinism when the source duplicates rows, per-dialect alternatives
  when the engine does not have it—. Neither duplicates the other.

## 2. Default decisions

> Verify version, licence, governance and real adoption status on the web before committing to anything in
> a real project (§8). This subsector moved a lot in 2025-2026 and a stale snapshot here costs a
> migration.

### 2.1 The starting decision: do you really need a lakehouse?

**"Lakehouse" is one of the two most over-sold labels in the sector** (the other is handled by
`streaming-cdc-standards`). Before adopting it, exhaust this ladder. Every rung avoided is
infrastructure you do not operate:

| Real situation | Simplest solution | When it stops working |
|---|---|---|
| The analytical data fits comfortably in the operational engine | **PostgreSQL** with range partitioning and a read replica (see `data-platform-standards`) | When the analytical scan competes with the transactional load and the replica no longer absorbs it |
| Medium volume, a small team, ad hoc queries | **Parquet files + DuckDB** or an embedded columnar engine, with no catalog and no transactions | When there are several writers, frequent deletes/updates or a need for an evolving schema |
| Serious analytics without a platform team | **Managed columnar warehouse** (BigQuery, Snowflake, ClickHouse Cloud, Redshift) | When cost, *lock-in* or the need for several engines to read the same data make it unviable |
| Several engines must read and write **the same** data, with ACID, deletes and an evolving schema | **Lakehouse** with a table format and catalog | — |

**What a Parquet directory really does not give you** —and it is the only list that justifies the jump—:

1. **Atomicity and isolation**: a reader never sees a half-finished write; a failed
   `INSERT OVERWRITE` does not leave the table in an intermediate state.
2. **Row-level deletes and updates** without rewriting the whole partition by hand.
3. **Safe schema evolution** (add, rename, reorder, change type within rules) by
   **column ID**, not by position nor by file name.
4. **Time travel and *rollback*** to an earlier snapshot after a bad write.
5. **Concurrent writing** with optimistic control, instead of "last writer wins".
6. **Planning without listing the bucket**: the metadata knows which files exist and what ranges
   they contain; listing S3 stops being the critical operation.
7. **Partitioning decoupled from the path**: it can be changed without rewriting the history.

**What it costs, and this has to be signed off up front**: a **catalog** that has to be deployed, authenticated,
backed up and made HA; a **periodic maintenance job** (compaction, expiration,
orphans) with its compute and its bill; a **new failure mode** (the table corrupts if you delete
files underneath the catalog); and **one more piece to update and explain to whoever replaces you**.

Rule: **if nobody on the team can name who runs compaction and at what cadence, you are not yet
ready for a lakehouse.**

### 2.2 The three (four) formats — status verified as of August 2026

| Format | Verified version | Real status | Verdict |
|---|---|---|---|
| **Apache Iceberg** | **1.11.0** (Java implementation, May 2026); **spec v3** in production | **It is the *lingua franca***: the three big cloud providers offer it managed, Snowflake and Databricks read and write it natively, DuckDB has write support, Trino/Flink/Spark/ClickHouse support it. Spec v3 is GA in Snowflake (7 May 2026) and in Databricks Runtime 18.0+ | **Default for any new lakehouse that must be multi-engine** |
| **Delta Lake** | **4.3.1** (Jul 2026) | Alive and with the largest single-vendor ecosystem. It is still the native and most optimised format **inside Databricks**. UniForm allows exposing a Delta table as Iceberg | **Default only if the centre of gravity is Databricks**; outside that, Iceberg |
| **Apache Hudi** | **1.2.0** (Jun 2026); 0.14.x branch still with releases | Mature, with its design centred on *upserts*, deletes and incremental *pull*. **Its historical differentiation has eroded**: Iceberg v3 and Delta incorporated deletion vectors and row lineage | **Do not choose it for a new project unless there is a concrete requirement** of its index/upsert model that you have tested |
| **Apache Paimon** | 1.x | **Streaming-native** niche (LSM, high-throughput *upsert*, originating in Alibaba's Flink ecosystem). Legitimate if your workload is continuous, very high-throughput CDC | Justified exception, not a default |
| **DuckLake** | — | Metadata in a relational database instead of files. **Experimental**: interesting, with no demonstrated production adoption | **Pilot, never production** |

**What has to be understood about the convergence (it is the fact that decides the choice, and where it is
easiest to stay with a 2024 snapshot)**: **the format war ended in a draw, not by extermination**.
Iceberg won as the interoperability standard; Delta survives as Databricks' native optimised
format; and **Iceberg's spec v3** absorbed exactly the capabilities that differentiated
Delta —**deletion vectors, row lineage (`_row_id`, `_last_updated_sequence_number`), `VARIANT`
type, column default values, geospatial types, nanosecond timestamps and multi-argument partition
transforms**—, so the "performance or compatibility" dilemma stopped existing. Databricks has also proposed
converging the **metadata tree** of Iceberg v4 and Delta 5.0 into a single structure: **it is a proposal, not a fact** — watch it, do not
take it as settled (§8).

Practical consequence: **the format choice is today a reversible (*two-way door*) decision and
cheap compared with the catalog one.** What is lost when changing format is the history:
the migration moves metadata and sometimes rewrites files, but **the old snapshots and the earlier *time
travel* do not travel**. Plan the migration with a coexistence period and do not promise
queryable history across the cut.

**On Iceberg's `format-version`**: v3 is not backwards compatible — **a v2 reader cannot
read a v3 table**, although a v3 reader reads v2 tables. Raising `format-version` is a change
that **breaks old consumers**: inventory the engines that read the table **before** raising it, not
after. In v3, positional delete files stop being written in favour of **deletion
vectors** (at most one per data file and snapshot).

### 2.3 The catalog: **this one really is the architecture decision**

The format says how the metadata is stored; **the catalog says which is the table's current
pointer, who can read it and with what credential**. It is the serialisation point of the *commits*, the
API boundary between all the engines and your data, and **the place where vendor lock-in actually
happens**. An open format with a closed catalog is not an open lakehouse: it is a
product with a public file format.

| Catalog | Verified status (Aug 2026) | Real openness | When |
|---|---|---|---|
| **Apache Polaris** | **1.7.0** (Aug 2026); **ASF TLP since 18 Feb 2026**. Stateless REST server on PostgreSQL/others | **Genuinely open**: Apache 2.0, foundation governance, *credential vending* with a zero-trust model. **Iceberg only** | **Default when you want vendor neutrality** and the team can operate a service with its database |
| **Vendor-managed REST catalog** (AWS Glue / S3 Tables, BigLake REST, etc.) | Alive and with v3 support in AWS since Nov 2025 | They speak the **Iceberg REST API**, which is what matters; the implementation is the vendor's | **Pragmatic default if you already live in that cloud** and you accept the dependency |
| **Unity Catalog** | **OSS 0.5.1** (Jul 2026), Apache 2.0, under LF AI & Data; exposes the Iceberg REST API and the Hive Metastore one | **Partial openness and that is the small print**: the OSS version lags far behind the managed one — **lineage, federation and fine-grained access control (RLS, column masking, ABAC) belong to the Databricks version**, not to the OSS. Databricks has declared an intention to close the gap; **parity has no date** | If your platform **is** Databricks, it is the natural and almost obligatory choice. **Do not adopt it "because it is open source" expecting the product's functionality** |
| **Project Nessie** | **0.108.4** (Jul 2026), active | Open. Its own value is **Git-like branches and tags** on top of the catalog (isolated development environments, atomic multi-table publication) | When you need data branching. **Watch out**: a convergence with Polaris is being discussed — verify it before betting on five years (§8) |
| **Apache Gravitino** | **1.3.0** (Jun 2026); ASF TLP since Jun 2025 | Open. It positions itself as a **"catalog of catalogs"**: federation of heterogeneous metadata in place | When the problem is to **federate** several existing catalogs, not to replace them |
| **Lakekeeper** | REST implementation in Rust, single binary | Open | Lightweight alternative to Polaris. **Verify version, licence and maturity before production** |
| **Hive Metastore (Thrift)** | No formal deprecation by the Iceberg project, but **pushed out commercially and architecturally** (e.g. Starburst retires its packaged HMS image in its Aug 2026 LTS) | Open but obsolete by design: **no *credential vending*, no branches, SPOF unless carefully made HA, Thrift protocol** | **Only to coexist with what already exists. FORBIDDEN in new deployments** (§7) |

**Catalog rules, in order of importance**:

1. **Choose an implementation that speaks the Iceberg REST API.** It is what lets you change
   backend without touching each engine's configuration. Starting with Thrift/HMS is signing up for a future
   migration.
2. **Migrating catalog is a metadata operation**: the data files do not move, the table is
   re-registered. That makes the decision less irreversible than it looks — **but the real risk
   is *split-brain***: two catalogs pointing at the same table during the transition, with
   two divergent snapshot pointers. Cut writes at the source before registering at the
   destination, without exception.
3. **The catalog is critical stateful infrastructure**: its database needs HA, backup and
   a proven restore (see `backup-recovery-standards`). **If you lose the catalog, the files in the
   bucket are still there but there is no table.** Have the reconstruction procedure from the
   most recent `metadata.json` written down.
4. **Planned coexistence, not perpetual**: it is legitimate to have Glue for the legacy and Polaris for
   the multi-engine part. Put an end date on the coexistence or it becomes permanent.
5. **Mandatory ADR** with the exit plan written down: which engines depend on it, how the tables are
   re-registered and how long it takes.

### 2.4 Query engines over the same data

| Engine | Verified version (Aug 2026) | Use |
|---|---|---|
| **Trino** | 483 (Jul 2026) | Federated interactive querying over the lakehouse. Good query default |
| **DuckDB** | 1.5.5 (Jul 2026) | Local querying and jobs that fit on one big machine. **Consider this before Spark** |
| **Apache Spark** | 4.2.0 (Jul 2026); 4.0.4 and 3.5.9 in maintenance | Heavy writing, table maintenance, processes that do not fit on one machine |
| **Apache Flink** | **2.3.0** (Jun 2026); 1.20.x still patched | Continuous writing from a stream (see `streaming-cdc-standards`) |
| **ClickHouse** | — (**not verified in this review**) | Reading Iceberg/Delta; its strength is its own storage, not the lakehouse |
| Managed (Snowflake, Databricks, BigQuery, Athena, EMR, Dremio, StarRocks) | — | Fine; the criterion is which **catalog** they require |

**What "open" really means**: data in Parquet + an open table format is a **necessary and not
sufficient** condition. Check all three, and if one fails do not say it is open:
(a) can **another** engine **read** the table without exporting it?; (b) can another engine **write** to
it?; (c) does the **catalog** speak a protocol that someone else implements? The most common scenario of
false openness in 2026 is not the format: it is a proprietary catalog that vends credentials only to
its own engine, or a managed table where only the vendor can write.

## 3. Anatomy, partitioning and maintenance

### 3.1 The metadata tree — **understanding it explains 90 % of the performance and cost problems**

A table format is a **stack of immutable pointers**. In Iceberg, top down:

```
catalog   →  metadata.json            (schema, partitioning, properties, snapshot list)
             └─ snapshot              (a complete state of the table at an instant)
                └─ manifest list      (that snapshot's manifests, with partition ranges)
                   └─ manifest file   (the data files, with per-column metrics: min/max/nulls)
                      └─ data files   (.parquet) + delete files / deletion vectors
```

Delta uses a **transaction log** (`_delta_log/` with incremental JSON and periodic *checkpoints*)
and Hudi a **timeline** (`.hoodie/`), but the three consequences are the same:

- **A write modifies nothing: it adds.** A `commit` is publishing a new pointer. That is why there is
  ACID, and that is why **the bucket grows by design** until somebody cleans up.
- **Query planning is done by reading metadata, not by listing the bucket.** *Pruning*
  happens at two levels: by partition range (in the manifest list) and by **per-column
  min/max statistics** (in the manifest). A slow engine is usually reading too many
  manifests, not too much data.
- **The symptoms of "it is slow" and "it costs a lot" are almost always metadata**, not compute:
  too many live snapshots, too many manifests, too many small files, or delete
  files not merged. Diagnose by **counting files and manifests per partition** before touching
  the cluster.
- **Per-column metrics cost metadata space**: on very wide tables, writing statistics
  for all 500 columns inflates the manifest and slows down planning. Limit the columns with
  statistics to the ones that get filtered.

### 3.2 Partitioning

- **Hidden partitioning (Iceberg)**: the partition is declared as a **transformation over a
  column** (`days(event_ts)`, `bucket(16, user_id)`) and the engine applies it when filtering by the original
  column. Compared with directory partitioning (Hive style), it eliminates the most frequent
  class of error in the domain: **the query that filters by `event_ts` but not by the synthetic column
  `dt`, and scans the whole table without anyone noticing until the bill arrives**. With hidden partitioning
  that query prunes properly; without it, it does not.
- **Partitioning evolution**: the specification can be changed **without rewriting the history**;
  old data keeps its spec and new data uses the new one. It is one of the best reasons to
  adopt the format. Two warnings: (a) the engine has to plan over **two specs at once**,
  with its cost; (b) **it is not an excuse for not thinking about the initial partitioning**, it is an
  emergency exit.
- **Classic and vetoed error: partitioning by a high-cardinality column** (`user_id`, `order_id`,
  `uuid`). It generates millions of tiny partitions, sinks planning and multiplies the
  requests to the bucket. If you need to group by that column, use **`bucket(N, col)`** (bounded number
  of partitions) or **ordering/clustering within the partition**, not direct partitioning.
- **Sizing rule**: aim for partitions of **hundreds of MB to a few GB**. A
  daily partition producing 3 MB means the right partition was the month.
- **Partition by the column you filter by** —almost always the **event** date, not the ingestion
  one— and verify the pruning by reading the plan, not by assuming it.

### 3.3 Maintenance — **the section nobody plans and the one that decides whether the project survives**

The formats **bring the primitives; none of them runs by itself**. Scheduling them, sizing them and
watching them is platform work with real compute cost, and it goes into the budget from day
one.

| Operation | What it fixes | If it is not done |
|---|---|---|
| **Compaction** (`rewrite_data_files` / `OPTIMIZE`) | Merges small files; optionally sorts or clusters (Z-order) | Thousands of files per partition: slow planning, expensive requests, queries that degrade every week |
| **Snapshot expiration** (`expire_snapshots` / `VACUUM`) | Removes old snapshots **and the files only they referenced** | **The bucket grows forever**, the `metadata.json` accumulates snapshots, listing and planning degrade and the bill goes up without anyone connecting the cause. **This is the most common economic failure in the domain** |
| **Orphan cleanup** (`remove_orphan_files`) | Deletes files that are in the bucket but **no** snapshot references (leftovers from jobs that died halfway) | Expiration does **not** touch them: they accumulate indefinitely and you pay storage for invisible rubbish |
| **Manifest rewriting** (`rewrite_manifests`) | Consolidates fragmented manifests | Slow planning despite having few data files |
| **Delete merging** (compaction of *delete files* / vectors) | Reduces the work of applying deletes on read | *Merge-on-read* tables that become slower and slower to read |

Hard rules:

- **Order**: compact first, **then** expire snapshots (so expiration can free the
  files that compaction made obsolete), then clean orphans and consolidate manifests.
  Skipping a step weakens the others.
- **`remove_orphan_files` with a wide safety window** (3 days by default; **never smaller than
  the maximum duration of an in-flight write**). A short window deletes files from an in-flight
  job and **corrupts the table**. This is the most dangerous command in the domain: treat it as such.
- **Snapshot expiration sets your real *time travel* and *rollback* window**. Decide it
  explicitly (typical: 7 days), publish it and do not discover it the day you need to revert.
- **Cadence**: stream-fed tables, every 1-3 hours; batch tables, daily; orphans and
  manifests, weekly. Adjust with the metric, not with habit.
- **Compaction costs compute and requests**: it rewrites data. On large tables it is a budget
  line of its own and it competes with the queries. Schedule it outside the critical window and
  **limit its concurrency**, or it becomes the process that takes the platform down.
- **At scale, maintenance is triggered by signal, not by blind cron**: number of files, average
  size, delete-file ratio, number of manifests and snapshot depth per table,
  with cron as a safety net.
- **Never delete files from the bucket "to clean up"** nor set an S3 lifecycle rule that
  expires objects inside the path of a live table. **It is the fastest and most definitive way
  to destroy a table**: the catalog will keep pointing at files that no longer exist. Cleanup is
  done **always** with the format's primitives (§7). See `object-storage-standards` for the
  lifecycle rule, which here is **vetoed over active table paths**.

### 3.4 Concurrent writes and optimistic control

- The model is **optimistic concurrency**: each writer reads the current snapshot, prepares its
  files and **tries to publish** the new pointer. If someone else published in the meantime, the *commit*
  fails and the writer **retries, re-basing its change** on the new snapshot, if the conflict
  allows it.
- **What actually happens when two jobs write the same table**: two `INSERT`s to different
  partitions almost always coexist (it retries and goes through). **Two operations that rewrite the same
  files —two `MERGE`s, or a `MERGE` and a compaction over the same partition— genuinely
  conflict**, and one of the two loses its entire work after having spent the compute.
  At high throughput, the retry turns into *livelock*: it never manages to publish.
- Rules: **one logical writer per table and partition**; maintenance does **not** overlap with the
  heavy writes on the same partitions; configure retries with *backoff* and **a cap**;
  and if the conflict is chronic, the problem is the partitioning design or the pipeline
  concurrency, not the number of retries.
- **Isolation is at table level.** A change that must be atomic **across several tables** is
  not, unless the catalog offers it explicitly (it is Nessie's own branching
  argument). Do not assume multi-table atomicity.
- **Branches and tags** (Iceberg branches/tags, Nessie): atomic publication, isolated development
  environments and audit by tag. Useful and correct; **each live branch retains snapshots and therefore
  files**: it goes into the maintenance budget.

### 3.5 Updates and deletes: *copy-on-write* versus *merge-on-read*

The change capture mechanism belongs to `streaming-cdc-standards`; **what it does to the table belongs
here**. It is a per-table decision, written down, not a default inherited from the example you copied.

| Strategy | How it works | Write cost | Read cost | When |
|---|---|---|---|---|
| **Copy-on-write (CoW)** | Rewrites the affected data files in the *commit* | **High**: changing one row rewrites its whole file | **Minimal**: readers read clean data | Tables with infrequent updates and many reads. **Default for the consumption layer** |
| **Merge-on-read (MoR)** | Writes delete files / deletion vectors and merges on read | **Low**: the *commit* is fast | **Growing**: each read applies the pending deletes | Continuous ingestion or high-throughput CDC. **Forces aggressive compaction** |

- **MoR without scheduled compaction is a time bomb**: the table is fast to write and
  slower to read every day, with a degradation nobody attributes to the decision that caused it.
- **The real cost of `DELETE` and `UPDATE`**: in CoW, deleting 10 rows spread across 10 files
  rewrites all 10 files completely. **A compliance-mandated deletion affecting one row
  per partition can rewrite the whole table.** Group the deletes into **periodic batches** instead
  of applying them row by row.
- **Iceberg v3 replaces positional delete files with deletion vectors** (bitmap,
  at most one per data file and snapshot): fewer files, more efficient reading and
  simpler comparison of deletes between commits. It is a solid reason to move to v3 on MoR
  tables, **once the readers have been inventoried** (§2.2).
- **Continuous ingestion produces small files by construction.** Do not treat it as a defect
  of the stream: it is the price of latency, and it is paid with compaction. If nobody wants to pay it, the
  latency you wanted was not necessary.

## 4. Quality and testing — gates

In increasing order of cost. **Those marked as a gate break the build or block publication.**

1. **Table definition and properties as code**, versioned and reviewed: schema,
   `format-version`, partition specification, CoW/MoR strategy, compaction and
   expiration properties. A table created by hand from a console is a table with no owner. *CI gate.*
2. **Every table is registered in the catalog and accessed through the catalog.** Path access
   (`s3://.../table/`) bypassing the catalog is forbidden: it is the direct route to corruption and to bypassing
   access control. *Review gate.*
3. **Schema evolution test**: the proposed change is applied to a copy and **read with the
   version of every engine that consumes the table**. Renaming, reordering and changing type are legal by
   spec; **removing or changing type incompatibly breaks consumers**. A `format-version` change
   is an incompatible change as long as an old reader exists. *CI gate.*
4. **Published table contract**: removing or renaming a consumed column, changing the grain
   or changing the partition spec **breaks the build** unless there is registered approval. The published table
   is an API (consistent with `data-warehouse-modeling-standards` §4). *Gate.*
5. **Assertions on the data** (key uniqueness, non-nulls, referential, ranges): they belong to
   `data-engineering-standards` §4 and `data-warehouse-modeling-standards` §4. Here it is only required
   that they **block snapshot publication**, taking advantage of the fact that the format allows writing to a
   branch and merging only if they pass.
6. **Write idempotency test**: running the same load twice produces the same
   table state (same count, same checksum). *CI gate on pipelines that write.*
7. **Concurrency test**: two simultaneous writers on the same table in the test
   environment; it is verified that one retries and **neither loses data silently**. This test is never
   done and it is where production failures appear.
8. **Table health as a scheduled test, with thresholds** (not just a dashboard): number of files per
   partition, average file size, number of snapshots, number of manifests, delete-file
   ratio. Exceeding the threshold **opens an actionable alert**, not an entry in a dashboard
   nobody looks at.
9. ***Rollback* drill** documented and executed on a schedule: reverting a table to an earlier
   snapshot, measuring how long it takes and checking that the consumers tolerate it. A *rollback* that
   has never been tested does not exist.
10. **Catalog loss drill**: rebuilding a table's registration from its `metadata.json`
    in a test environment. It is this domain's specific disaster scenario.
11. **Dependencies pinned by hash/digest** in every process with *warehouse* credentials
    (`pyiceberg`, `delta-rs`, connectors, Spark/Trino images). *CI gate* (§5).

## 5. Stack security

### 5.1 Access control: who actually enforces it

The split, verified and with its blind spot:

| Control | Who enforces it |
|---|---|
| Namespace, table and column permissions; credential scope | **The catalog** (REST catalog RBAC) |
| Storage path restriction | **The catalog**, through *credential vending* of temporary, scoped credentials |
| **Row filtering and column masking** | **The engine**, unless your catalog implements fine-grained control — Polaris, for example, does **not** do it natively |
| Engine-independent audit | **The catalog** |

**Derived design rule, and it is the domain's trap**: **never rely on fine-grained control
applied only in the engine if several engines can obtain storage credentials**. A
Trino row policy is unknown to Spark; and a scoped credential granting read access to
the files will hand over the unmasked rows to any client that does not go through the engine with the
policy. If you need real RLS/masking: either the catalog enforces it, or **you restrict
the set of engines that can obtain credentials**, or you publish a derived, already-filtered table.

- ***Credential vending* mandatory**: users and engines must **not** have direct
  bucket credentials. The catalog authenticates and issues temporary least-privilege credentials.
  A user with S3 keys for the *warehouse* invalidates the whole catalog's access control.
- The catalog is a **high-value target**: strong authentication, TLS, no long-lived static
  credentials, federated identities (see `identity-access-management-standards` and
  `secrets-management-standards`), and retained audit.
- **Separation of writing and maintenance**: the pipeline identity writes; the maintenance
  identity deletes. A single role being able to delete data files is the surface with which
  a table gets destroyed, by mistake or by attack.

### 5.2 Substrate and supply chain

- **Encryption at rest** for the bucket and **mandatory TLS** on access; the detail belongs to
  `object-storage-standards` and `cryptography-pki-standards`.
- **Object Lock in *compliance* mode over live table paths is incompatible with
  maintenance**: `expire_snapshots` and `remove_orphan_files` will not be able to delete anything and
  storage will grow without limit. If there is a regulatory immutability obligation, it is solved with
  **a derived copy** in a locked bucket, not by locking the operational table.
- **Supply chain — this is not hypothetical**: the data ecosystem has been under a sustained
  campaign since 2025. Verified precedents: **Trivy** (Mar 2026), **LiteLLM** on PyPI (1.82.7 and
  1.82.8, 24 Mar 2026), **Telnyx** (Mar 2026), **Microsoft's `durabletask`** (1.4.1-1.4.3,
  May 2026) and **`elementary-data` 0.23.3** (Apr 2026, `.pth` pattern that runs when the
  interpreter starts). The current generation, **"Mini Shai-Hulud" (CVE-2026-45321)**, active since the end of
  Apr 2026, is a worm that propagates between npm and PyPI, **extracts OIDC tokens from the memory of the
  GitHub Actions runner** and has managed to **forge SLSA level 3 provenance attestations**.
  Mandatory derivations here:
  - **Pin by hash/digest** everything installed in a process that has *warehouse* or catalog
    credentials; no open ranges.
  - **Quarantine window** of days before adopting a freshly published version in environments with
    production credentials.
  - **Provenance attestation is no longer sufficient proof** on its own: combine it with
    quarantine and with *runner* least privilege.
  - A table maintenance *runner* **must not have credentials for more than one environment**.
- **As of Aug 2026 there is no record of a compromise of `pyiceberg` or `deltalake`/`delta-rs`** — verify it
  again before committing to it (§8).

### 5.3 Personal data and deletion in an immutable format

**The technical constraint, which is the only thing this skill decides** (the policy belongs to
`privacy-engineering-standards`):

- A `DELETE` on the table **does not delete the data**: it creates a new snapshot in which the row does not
  appear. **The data is still in the previous files and is still recoverable by *time travel*
  until the snapshots expire and the orphans are cleaned up.**
- Therefore, a legally mandated deletion is only **complete** when: (1) the
  `DELETE` is executed; (2) the affected files are **compacted or rewritten**; (3) all the
  snapshots that referenced them **expire**; (4) **the orphans are cleaned up**; and (5) it is checked that no
  **branch, tag, replica, backup or derived table** keeps the row.
- **Mandatory design consequence**: the **snapshot expiration window becomes a
  compliance parameter**, not just an operational one. If the deletion commitment is 30 days, snapshot
  retention **must** be shorter, and that has to be stated in writing.
- When the above is not viable (huge history, frequent deletes, a simultaneous
  immutability obligation), the way out is **crypto-shredding** or pseudonymisation by design:
  the decision belongs to `privacy-engineering-standards`; **the structure that makes it possible is decided
  here and now, because afterwards it is a complete rewrite of the table**.
- **Minimisation**: the PII column that never lands in the table is the one you do not have to delete
  across an entire history afterwards.

## 6. Performance and operability

- **Diagnose by metadata, not by cluster.** Faced with "it is slow", measure in this order: number of
  data files read, average size, number of manifests, live snapshots, delete-file
  ratio, and only then CPU and memory. Adding *workers* to a fragmented table is paying more
  for the same problem.
- **Minimum per-table metrics**, with a threshold and an alert: files per partition, average file
  size, number of snapshots, number of manifests, age of the last compaction,
  age of the last expiration, total table bytes versus live bytes, and **cost of
  bucket requests** (see `object-storage-standards`).
- **Cost**: in this model you pay for **storage + requests + query compute +
  maintenance compute**. The two line items people forget are the last two. Budget
  maintenance explicitly; if it does not fit, the table is badly sized or the lakehouse was
  unnecessary (§2.1).
- **Divergence between stored bytes and live bytes**: it is the early and direct indicator that
  expiration or orphan cleanup is not running. Watch it from day one.
- **Ordering and clustering** within the partition (order by the filter column, Z-order for
  multidimensional filters) are worth more than adding partitions. They are applied during compaction.
- **Bounded column statistics** on wide tables: writing them all inflates the manifests.
- **Owner per table**, published, with its freshness SLA (from
  `data-engineering-standards` §6.2) **and its maintenance plan**. A table with no owner has
  nobody to run compaction, which is how they all end up degraded.
- **Runbooks written and rehearsed**: reverting a table to a snapshot; recovering from an
  over-aggressive expiration; rebuilding the registration after losing the catalog; stopping and draining writers
  before a catalog migration.
- **A *rollback* is visible to consumers**: it changes what they already read. Communicate it; the
  silence destroys trust faster than the error.

## 7. Sustainability and prohibitions

- **Cadence**: review format, catalog and engine versions quarterly; and **the
  Iceberg v4 / Delta 5.0 convergence**, which is the proposal with the most capacity to shift the ground of this domain
  in the medium term. `format-version` jumps are planned with a reader inventory.
- **Active retirement**: a table with no measured consumption for a quarter is flagged and retired, with its
  files. A lakehouse accumulates by design; pruning is part of the work.
- **Mandatory ADR** for: adopting a lakehouse (versus the alternatives in §2.1), choosing a format,
  **choosing a catalog with a written exit plan**, CoW/MoR strategy per table, partitioning
  policy, snapshot retention window (**which is also a compliance parameter**)
  and maintenance plan with its budget.
- **Count on coexistence**: for years you will have tables in two formats or two catalogs.
  Put a date, an owner and a finishing criterion on it, or it becomes the permanent state.

**FORBIDDEN**
- ❌ Adopting a lakehouse without first ruling out PostgreSQL, Parquet+DuckDB or a managed columnar
  warehouse (§2.1).
- ❌ Putting a lakehouse in production **without scheduled and budgeted maintenance work**:
  compaction, snapshot expiration and orphan cleanup.
- ❌ **Deleting files from the bucket by hand**, or applying an S3 lifecycle rule that expires
  objects inside the path of a live table. It destroys the table.
- ❌ `remove_orphan_files` with a window smaller than the maximum duration of an in-flight write.
- ❌ Accessing the table by path bypassing the catalog, or registering the same table in two catalogs
  with active writing in both (*split-brain*).
- ❌ **Hive Metastore/Thrift in a new deployment.**
- ❌ Adopting a catalog without an ADR with an **exit plan** — that is where vendor lock-in lives, not
  in the format.
- ❌ Calling a stack "open" when its catalog only talks to its own vendor's engine, or
  whose managed table only the vendor can write to.
- ❌ Adopting Unity Catalog OSS expecting the functionality of the managed Databricks version
  (lineage, federation, RLS and masking are **not** in the OSS).
- ❌ Partitioning by a high-cardinality column (use `bucket(N, col)` or clustering).
- ❌ Relying on partitioning evolution to avoid thinking about the initial partitioning.
- ❌ Raising `format-version` (e.g. to Iceberg v3) without inventorying the reading engines: **v2 does not read
  v3**.
- ❌ *Merge-on-read* without scheduled aggressive compaction.
- ❌ Applying compliance deletions row by row on *copy-on-write* tables.
- ❌ **Replacing an SCD type 2 with *time travel*** (mirror prohibition of
  `data-warehouse-modeling-standards`).
- ❌ **Using *time travel* as a backup.** It has days of retention, lives in the same
  bucket, shares the same blast radius and disappears with expiration. See
  `backup-recovery-standards`.
- ❌ Considering personal data deleted after a `DELETE`, without snapshot expiration or orphan
  cleanup (§5.3).
- ❌ Object Lock in *compliance* mode over the path of an active table.
- ❌ Direct bucket credentials for users or engines, instead of *credential vending*.
- ❌ Relying on RLS/masking applied only in one engine when several engines can obtain
  credentials.
- ❌ A single role with file write and delete permission for everything.
- ❌ Several concurrent writers on the same table and partition without conflict design, or
  maintenance overlapping with heavy writing.
- ❌ Assuming atomicity across several tables.
- ❌ Dependencies not pinned by hash/digest in processes with *warehouse* credentials (§5.2).
- ❌ A catalog without HA, without backup and without a restore drill.
- ❌ DuckLake or other experimental formats in production.
- ❌ Pinning versions, licences, governance or adoption status from memory (§8).

## 8. Mandatory web verification

The data in §2, §3 and §5 is from **August 2026**. Before committing to anything in a deliverable, verify:

1. **Iceberg**: implementation version (**1.11.0**, May 2026 — confirmed by the releases
   feed) and status of **spec v3** (in production; GA in Snowflake on 7 May 2026 and in
   Databricks Runtime 18.0+; AWS with deletion vectors and row lineage since Nov 2025). Verify
   which engines in **your** stack read v3 before raising `format-version`.
2. **Delta Lake** (4.3.1, Jul 2026) and **Hudi** (1.2.0, Jun 2026): real version and activity.
3. **The convergence**: status of the proposal for a **common metadata tree between Iceberg v4 and
   Delta 5.0**. As of Aug 2026 it is a **Databricks proposal, not an Iceberg community
   decision**. Do not cite it as a fact.
4. **Catalogs**: Polaris (1.7.0 Aug 2026, ASF TLP since 18 Feb 2026), Nessie (0.108.4) **and in
   particular whether the discussed Nessie→Polaris convergence has materialised**; Gravitino (1.3.0,
   TLP since Jun 2025); **Unity Catalog OSS** (0.5.1, Jul 2026) and **what concrete functionality remains
   exclusive to Databricks** — it is the fact that decides whether "open" means anything; Glue and S3
   Tables; and the real degree of **Hive Metastore** retirement in your distribution.
5. **Engines**: Trino (483), DuckDB (1.5.5), Spark (4.2.0), Flink (2.3.0) and their concrete support for
   the spec version you use.
6. **Licences**: of every engine and catalog you recommend, and of the commercial layer you lean
   on (Databricks, Snowflake, Dremio, Starburst, Confluent). In this sector they change without changing
   the product name.
7. **Supply chain**: recent advisories for `pyiceberg`, `deltalake`/`delta-rs`, Spark/Trino
   and catalog images, and the evolution of **Mini Shai-Hulud (CVE-2026-45321)**.
8. **Object Lock, storage classes and cost per request**: cross-check it with
   `object-storage-standards` §5 and with the vendor's current price list.

**Declared gaps of this review** (do not fill in from memory):
- **ClickHouse**: version, licence and status of its Iceberg/Delta support not verified.
- **Lakekeeper**: version, licence and production maturity not verified. Do not recommend it without
  checking.
- **Apache Paimon**: exact version and release cadence not verified; only its
  streaming-native positioning.
- **Hudi**: the relationship between the 1.2.x and 0.14.x branches (both with releases in
  Jun 2026) not verified, nor which one the project recommends.
- **Nessie/Polaris convergence**: picked up as an ecosystem comment, **not verified** in the
  project's own source.
- **Maintenance cost figures**: there is no verified data; measure on your platform before
  budgeting.
- **Iceberg v4**: no schedule or community agreement verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
