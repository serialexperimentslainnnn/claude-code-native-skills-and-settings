---
name: nosql-standards
description: Use when a non-relational store is proposed, modelled or operated — justifying it against PostgreSQL JSONB and GIN first, MongoDB (mongod, mongosh, replica set, sharded cluster, SSPL, Atlas-only rapid releases), DynamoDB single-table design (partition key and sort key, GSI, LSI, hot partition, on-demand versus provisioned capacity, TransactWriteItems, DynamoDB Streams, adaptive capacity), Cassandra or ScyllaDB (CQL, cqlsh, keyspace RF, NetworkTopologyStrategy, LOCAL_QUORUM, tombstones, compaction strategy, nodetool repair), Couchbase, FerretDB or the Linux Foundation DocumentDB Postgres extension, modelling by access pattern instead of by entity, deliberate denormalization and duplicated writes, eventual versus strong reads, CAP and PACELC trade-offs, LSM write amplification and compaction cost, rebalancing and major-version upgrades, source-available licence review (SSPL, BUSL, free-tier node or vCPU caps) before a commercial or managed deployment, or migrating back to a relational store.
---

# NoSQL data store standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **deciding, modelling and operating** a non-relational store: document (MongoDB and
compatibles, Couchbase), key-value and wide-column (DynamoDB, Cassandra, ScyllaDB).
It covers the prior justification against PostgreSQL, modelling by access pattern, key
design, consistency as a product decision, operation (partitions, compaction, rebalancing,
backup, upgrades), cost and **licence review** — which in this domain is an architecture
criterion, not a legal formality — and the exit back to relational when the decision was
wrong.

Triggers: "MongoDB", "mongosh", "replica set", "sharding", "DynamoDB", "single-table
design", "partition key", "GSI", "hot partition", "Cassandra", "ScyllaDB", "CQL",
"keyspace", "quorum", "tombstone", "compaction", "Couchbase", "FerretDB", "DocumentDB",
"eventual consistency", "denormalise", "flexible schema", "NoSQL".

**Not applicable**: see `data-platform-standards` (**parent skill**: PostgreSQL as the default —
modelling, JSONB, indexes, partitioning, replicas, PITR —, Valkey/Redis, Kafka, backups,
data classification; and the "one store per need" principle this skill inherits),
`graph-db-standards` (graph databases: **the graph is a different data model, not one more
NoSQL family** even if marketing groups them together — variable-depth traversals,
Cypher/GQL, supernodes; nothing about graphs is decided here),
`microservices-architecture-standards` (data ownership per service, outbox, sagas and
eventual consistency **between services**; here the engine's),
`privacy-engineering-standards` (what personal data may exist, DPIA, real erasure and
end-to-end crypto-shredding; here only its execution on an engine with no JOIN and no FK),
`object-storage-standards` (S3 and compatibles as a blob store: a large document almost
never goes in the database), `backup-recovery-standards` (the mechanics and repository of
the copy), `bcdr-standards` (RTO/RPO derived from the business), `observability-standards`,
`sre-practice-standards`, `kubernetes-standards` (operators and StatefulSets),
`linux-storage-standards` and `zfs-standards` (the disk underneath), `iac-standards`,
`cicd-standards`, `secrets-management-standards`,
`identity-access-management-standards`, `cryptography-pki-standards`,
`grc-compliance-standards`, `vulnerability-management-standards`,
`aws-standards`/`azure-standards`/`gcp-standards` (DynamoDB, Cosmos DB, Firestore and
managed DocumentDB as provider services: quotas, IAM and the bill are theirs; **the
modelling and consistency criteria are ours**), the language skills (drivers,
ODM/ORM and their lifecycle), `data-engineering-standards` (pipelines loading from or
extracting to these stores), `rag-standards` (retrieval for AI), `vector-db-standards`
(**vector search and ANN index operation: theirs**, even if these engines have
added vector types), `data-warehouse-modeling-standards` (analytical modelling).
`search-engines-standards` (**Elasticsearch/OpenSearch and text
search are theirs — a very close boundary**: if the requirement is *relevance*
— ranking, analysers, facets, suggestions — it is not a document store, it is a search engine;
here only the real store that feeds it and that it is reindexed from),
`vector-db-standards` (**vector search and ANN: theirs**, even if these engines have
added vector types), `timeseries-db-standards` (**time series: theirs**),
`caching-cdn-standards` (**Redis/Valkey as a cache: theirs** — a cache is not a store and
is not decided here), `data-warehouse-modeling-standards` and `lakehouse-standards` (analytics
and dimensional modelling), `streaming-cdc-standards` (CDC from these engines),
`message-brokers-standards`, `data-governance-quality-standards`, `oracle-dba-standards`,
`sqlserver-dba-standards`, `mysql-mariadb-dba-standards`.

### Governing principle: the prior question is **why not PostgreSQL?**

A NoSQL store enters the architecture **only** when a **measured** need demands it
and the ADR documents which one. The list of needs that justify it is short:

1. **Real horizontal write scale** that a properly sized PostgreSQL (with
   partitioning and replicas) does not absorb, demonstrated with figures and a projection, not with
   fear.
2. **A known, fixed, high-cardinality access pattern**, with a strict p99 latency
   budget at scale (single-digit milliseconds under sustained load).
3. **Multi-region active-active geographic distribution** with local writes and accepted
   conflict resolution.
4. **Series or log volume** that an LSM engine absorbs cheaply and the relational one does not.

What does **not** justify a NoSQL: the *shape* of the data. "It is hierarchical", "it is nested", "the
fields vary per customer" and "the schema evolves fast" are all solved by PostgreSQL with
`jsonb` + **GIN** indexes (`jsonb_path_ops`), generated columns for what is queried
often, `CHECK` with `jsonb_matches_schema`/validation at the edge, declarative partitioning
and read replicas. And it solves them **while keeping** multi-document transactions,
referential integrity, ad-hoc JOINs and a mature operational ecosystem.

A signal from the industry itself: **DocumentDB** — the MongoDB-compatible document engine
donated to the Linux Foundation (MIT, August 2025) — is literally a couple of PostgreSQL
extensions (`pg_documentdb_core`, `pg_documentdb`) plus a protocol gateway
(`pg_documentdb_gw`). When the industry wanted an open document store, it built it
**on top of PostgreSQL**. Mind the name: it is **not** Amazon DocumentDB, which is a
different managed AWS service.

**Cost of the decision**: adopting a NoSQL adds an engine to operate, a licence to
review, a consistency model to explain to the business and a model that **freezes
with the access pattern** (§3). It is a *one-way* door in practice: you go in fast and
you come out with a migration (§7).

## 2. Default decisions

> Verify on the web the version, the EOL, the CVEs and **above all the current licence** before
> pinning anything in a real project (§8). The data in this table is from August 2026 and
> expires; the licences in this domain have changed several times in two years.

| Need | Default | Justifiable alternative |
|---|---|---|
| Any case with no measured need from §1 | **PostgreSQL** (`jsonb` + GIN) | — (the burden of proof lies with whoever proposes the NoSQL) |
| Managed document store on AWS/Azure/GCP | The provider's service, with the modelling from §3 | Self-managed only with real operational capacity |
| Key-value at scale on AWS | **DynamoDB** | Cassandra/ScyllaDB if there is multi-cloud or required portability |
| Self-managed wide-column | **Apache Cassandra 5.0.x** (Apache-2.0) | ScyllaDB if the latency/density profile justifies it **and** its licence is accepted (§2.1) |
| "Mongo-compatible" document store without SSPL | **DocumentDB** (Linux Foundation, MIT) or **FerretDB** on top of it | MongoDB with a commercial licence |
| Cache | **Not this skill** — see `caching-cdn-standards` | — |
| Relevance search | **Not this skill** — see `search-engines-standards` | — |

Verified versions (August 2026):

| Engine | Verified status | Note that changes decisions |
|---|---|---|
| MongoDB | 8.3.x branch (8.3.7, Jul 2026); 9.0 in alpha. 8.0 and 7.0 with EOL 31 Oct 2029 (policy extended to 4-5 years) | **The *rapid releases* (8.1, 8.2, 8.3) are only supported on Atlas, not on-prem**: self-managed ⇒ **8.0 LTS**. 8.2 end of support 31 Jul 2026 |
| Apache Cassandra | 5.0.8 (Apr 2026) stable; 6.0-alpha1 in development (Accord protocol) | 5.0 brought SAI (CEP-7) and a vector type with ANN (CEP-30) and the Unified Compaction Strategy. Do not take 6.0 to production |
| ScyllaDB | 2026.2.x stable; 2026.3.0 in rc. Versioned by year | **There is no longer an open source edition** (§2.1) |
| DocumentDB (LF) | Linux Foundation project, MIT, extensions on top of PostgreSQL (supports up to PG 18) | A real option for escaping SSPL while keeping the Mongo drivers |
| FerretDB | Latest verified public tag: v2.7.0 (Nov 2025) | A cadence to watch before relying on it in production |

### 2.1 Licences — the fact that decides

**Rule**: no engine enters a commercial deployment, and even less one **offered as a
service to third parties**, without reading its current licence and recording it in the ADR. Status
verified in August 2026:

| Engine | Code licence | What it implies |
|---|---|---|
| **MongoDB Community Server** | **SSPL v1** since October 2018 (withdrawn from the OSI in 2019; the OSI declared in 2021 that it does **not** meet the Open Source Definition). The *drivers* are Apache-2.0 | Offering it **as a service** requires publishing all the software of that service under SSPL: in practice, your own managed service ⇒ commercial licence (Enterprise Advanced). **MongoDB has not returned to an OSI licence**, unlike Elastic and Redis. Internal application use: no publication obligation. Debian, RHEL and Fedora dropped it over this |
| **ScyllaDB** | **Source-available** (ScyllaDB Software License Agreement) since December 2024. **6.2 was the last AGPL release**; earlier ones remain AGPL in perpetuity but without fixes | Free tier with a **hard limit**, verbatim from the official FAQ: *"The full-featured ScyllaDB Enterprise will be available for free with a 10TB limitation (total hard drive space of all ScyllaDB servers per organization). The maximum total amount of virtual CPUs (vCPUs, hyperthreads) of all servers across all clusters is 50."* Any serious deployment ⇒ commercial contract. Budget for it **before** choosing it |
| **Apache Cassandra** | **Apache-2.0** | No deployment or service restriction. It is the default when the licence is a criterion |
| **Couchbase Server** | Code under **BSL 1.1** (reverts to Apache-2.0 after 4 years). The Community Edition binaries go under their own *Community Edition License Agreement* | CE limited to **5 nodes per cluster**, **4 cores per node** and **no XDCR** (CE 7.0+): departmental scale. Derivatives of the BSL code inherit BSL |
| **ArangoDB** | **BUSL-1.1** since 3.12 (previously Apache-2.0). CE binaries under the *ArangoDB Community License* with a cap of **100 GiB** in production and internal use only | Forbidden to use it for a DBaaS/SaaS or to redistribute it with your product without a commercial agreement |
| **DocumentDB (Linux Foundation)** | **MIT** | No restrictions; vendor-neutral governance with a TSC |
| **DynamoDB / Cosmos DB / Firestore** | Proprietary managed service | The "licence" is the provider's contract and the *lock-in*: record it as an exit cost (§7) |
| Valkey / Redis | *Out of scope* (see `caching-cdn-standards`): Valkey BSD-3; Redis 8+ tri-licensed AGPLv3/RSALv2/SSPL | Cited only so the licence criteria are not confused across families |

**FORBIDDEN** to assert the licence of any of these engines from memory: you read the
current official page (§8). A licence error is the most expensive one in this domain.

## 3. Modelling: it is the opposite of relational

### 3.1 You model by access pattern, not by entity

- The starting point is **not** the entity-relationship diagram: it is the **list of queries**
  of the application, each with its cardinality, its frequency and its latency
  budget. Without that list written down, no design is possible — there is guesswork.
- **Deliberate denormalisation and controlled duplication**: the data is copied to where it is read.
  Every duplicate is an invariant that the application — not the engine — must maintain: document
  which copy is the source of truth, who propagates it and what happens if propagation
  fails halfway (there is no FK and no JOIN to save you).
- **Aggregate = transaction and read boundary**: if two things are read and written together
  and their size is bounded, they go in the same document/partition; if they grow unbounded
  (comments, events, history), they are **not** nested: the unbounded document is the
  classic antipattern (in DynamoDB it is also impossible: maximum **400 KB per item**).
- **Changing the access pattern later usually means remodelling and migrating all the
  data**, not adding an index. It is the structural difference from the relational world and the
  reason a domain still under exploration — where nobody yet knows how it will be queried — is
  the worst possible candidate for a NoSQL.
- "Flexible schema" does **not** mean "no contract": the schema exists, and if it is not in the
  engine it is — implicit and unvalidated — in the code. An explicit, versioned contract
  always: JSON Schema validated at the edge, `$jsonSchema` on the collection, types
  declared in CQL. A new field ⇒ additive and with a default; a shape migration ⇒ the same
  expand/contract discipline as in SQL, with double reads during the transition.

### 3.2 Key design (what decides performance and the bill)

- **Partition key**: it determines the distribution. It is chosen for **high cardinality and
  uniform traffic**, not because "it is the main entity's id". Low-cardinality
  keys (status, country, a large tenant, `true/false`, today's date) produce
  ***hot partitions***: the cluster is at 10% and the user sees throttling.
- **Sort key** (sort key / clustering key): it defines the cheaply queryable range.
  It is designed as a **hierarchy of prefixes** (`ORG#123#PROJ#7#TASK#9`) so that a single
  `begins_with` serves several queries.
- Limits that condition the design in DynamoDB (verified; re-verify in §8): item
  **400 KB**; **3,000 RCU / 1,000 WCU per partition** (with automatic *adaptive capacity*,
  which mitigates but does not eliminate the hot-key problem); **5 LSIs** and **20 GSIs** per
  table by default; 40,000 RU/WU per table by default; 2,500 tables per region (raisable
  to 10,000).
- Hot-key mitigation: *write sharding* with a bounded suffix (`#1..#N`) and
  scatter on read, or a key change — never "trusting the engine to spread it".
- **Cassandra/ScyllaDB**: the *partition key* bounds the work of a query; huge partitions
  (hundreds of MB, millions of cells) kill latencies and compaction. Always query
  by partition key; `ALLOW FILTERING` is **forbidden** in production. Native
  secondary indexes are a trap at scale: model a table per query, or SAI
  (Cassandra 5.0) with measurement.
- **Single-table design in DynamoDB**: it is the right technique to
  resolve several entities and accesses with fewer requests and cheap transactions, and it is
  **expensive in cognition**: generic attribute names (`PK`/`SK`/`GSI1PK`), unreadable
  outside the code that interprets it, hard to explore ad-hoc and very rigid against a new
  access pattern. Adopt it when the access pattern is stable and written down;
  with two or three entities and simple accesses, several tables are more honest. In both
  cases, the access→key map is documented alongside the code: without it, the table is
  unreadable in 6 months.

### 3.3 Consistency: it is a product decision

- **CAP without mysticism**: faced with a network partition, the system chooses to answer with
  possibly stale data (AP) or to reject the request (CP). **PACELC** adds what is
  really paid for daily: *else*, with no partition, you choose between **latency** and
  **consistency**. Most of these engines are configurable per operation: the
  decision is not the engine's, it is **yours and per query**.
- **"Eventual" in practice** means: you can read your own write and not see it;
  two readers can see different states; a counter can go backwards; and a
  late reconciliation can erase what the user had just written. All of that must be
  **decided with the product owner**, not hidden in a YAML. What does not tolerate
  staleness (balance, stock, permissions, credit limits, uniqueness) is not solved by an
  eventual read — and often not by this kind of store either.
- Concrete levers: DynamoDB with strongly consistent reads (`ConsistentRead=true`,
  twice the cost, only in the table's region, not on GSIs) versus the eventual default;
  global tables with **MREC** (eventual) or **MRSC** (strong multi-region, with its own
  quotas); Cassandra/ScyllaDB with `LOCAL_QUORUM` at RF=3 per DC as a healthy baseline (R+W>RF), and
  `ONE` only where staleness is acceptable and explicit; MongoDB with `writeConcern`
  `majority` + `readConcern` `majority` and reads on the primary by default (`readPreference
  secondary` only with accepted lag).
- **Transactions where they exist and their limits**: MongoDB has multi-document and
  distributed transactions (with a cost, a bounded time window and contention of their own); DynamoDB has
  transactions bounded per request and at double cost; Cassandra has LWT (Paxos, expensive) and
  Accord in development for 6.0. **None** replaces a relational store for dense
  transactional logic: if the domain needs transactions often, the engine is badly
  chosen.
- Without FKs and JOINs, integrity is held up by the application: uniqueness with a sentinel
  item/document and a conditional insert (`attribute_not_exists`, unique index), idempotence
  by natural key on every retryable write, and a **reconciler** that detects
  divergences between duplicated copies. That reconciler is part of the deliverable, not an
  extra.

## 4. Quality and gates

CI gates, in increasing cost order. They break the build:

1. **A versioned schema contract in the repo** (JSON Schema / `$jsonSchema` / CQL DDL) and
   backward-compatibility validation on every PR. Without a contract, no merge.
2. **An access-pattern map** kept up to date as a file in the repo: every application query
   mapped to a key/index. A new query with no entry in the map is a review failure,
   not a detail.
3. **Integration tests against the real engine** (Testcontainers, DynamoDB Local): never
   against a driver mock or an in-memory stub — the dialects and the limits lie.
   Cover the happy path **and edges**: an item at the size limit, a non-existent key, a conditional
   write that fails, a duplicate retry, pagination with `LastEvaluatedKey`/cursor.
4. **An explicit consistency test**: at least one test documenting the behaviour
   under eventual reads (reading right after writing) so that the §3.3 decision is
   verifiable and not folklore.
5. **Scan detection**: `Scan` without a key filter, `ALLOW FILTERING` and
   `find()` without an index on the hot path are forbidden. A linter or a mechanical review over the
   queries; in MongoDB, `notablescan` in test environments so it fails in CI.
6. **A load test with representative data and a realistic distribution** (including the
   hot keys): a plan with 1,000 documents predicts nothing at 100 M. Measure p99, not
   the mean.
7. **A tested restore** of the backup (§6) on a scheduled cadence: it is a delivery gate,
   not an operations task.

## 5. Security

- **Authentication and authorisation always enabled**: these engines have starred in massive
  leaks precisely because of unauthenticated instances exposed to the Internet. `bindIp`
  restricted, never `0.0.0.0` reachable from outside; private network + egress and
  ingress firewall; **never** a database port published on the Internet, not even "just for
  a moment to test".
- **TLS in transit** between clients and nodes **and between nodes** (Cassandra/Scylla:
  `internode_encryption`); **encryption at rest** with keys in a KMS and rotation (see
  `cryptography-pki-standards`).
- **Least privilege with per-application roles**, separate from the administration ones and from
  the analytics ones. Beware query-level RBAC bypasses: CVE-2026-13059 in
  MongoDB (CVSS 8.6) allowed a low-privilege user to bypass controls on
  `find`/`update`/`delete`/`aggregate` — the engine's RBAC gets patched, not assumed.
- **Injection**: yes, it exists outside SQL. Never build filters from user
  input without typing (operators `$where`, `$ne`, `$gt` injected from client JSON);
  `$where` and server-side JavaScript execution, **disabled**. In CQL, always prepared
  statements with parameters.
- **CVEs and patching** (verified in August 2026, re-verify in §8): MongoDB accumulated
  high-severity vulnerabilities in 2026 — CVE-2026-13072 (CVSS 9.2, memory corruption
  with *compute mode* enabled), CVE-2026-9740 (8.7, reachable unauthenticated), CVE-2026-8053
  (time-series collections) — with fixes in **7.0.39 / 8.0.28 / 8.2.12 / 8.3.7**; and
  **MongoBleed (CVE-2025-14847)**, an unauthenticated memory leak via compressed messages,
  **entered CISA's KEV catalogue** (active exploitation confirmed). Cassandra: review
  CVE-2025-23015 (escalation to superuser with `MODIFY ON ALL KEYSPACES`), whose patch was
  applied wrongly in 4.0.16 — fixed in 4.0.17. Subscribing to the engine's advisories is
  mandatory, not optional.
- **Driver supply chain**: there is no known incident specific to these
  engines, but npm and PyPI live under recurring worm campaigns (Shai-Hulud/TeamPCP,
  TrapDoor in 2026, including malicious packages **with valid SLSA provenance**).
  Pin drivers by version and hash in the lockfile, SCA in CI and review of any major
  version jump.
- **Personal data**: without JOINs and FKs, erasure is a **search across all the copies**
  (§3.1) — the right to erasure is designed with the model, not afterwards. Duplicated documents and
  partitions, secondary indexes, streams, backups and cross-region replicas
  all count. Where physical erasure is not viable within the window, crypto-shredding per subject
  (see `privacy-engineering-standards`).

## 6. Operation, performance and cost

- **Replicas and partitions**: RF=3 as a baseline with zone/rack awareness
  (`NetworkTopologyStrategy`, rack awareness); MongoDB with a 3-member replica set and
  arbiters **avoided**. Adding or removing nodes is **rebalancing**: expensive in network and I/O,
  planned within a window and measured, never improvised during an incident.
- **Compaction and write amplification (LSM)**: in Cassandra/ScyllaDB (and in the
  storage engine of many document stores) every write is rewritten several times
  during compaction. Consequences that must be budgeted: enough free space to
  compact (rule of thumb: do not fill the disk beyond 50-70% depending on the strategy),
  reserved I/O and CPU, and a conscious choice of strategy (UCS in Cassandra 5.0,
  size-tiered vs levelled depending on read/write mix). **Tombstones**: deletes are
  writes; a mass-delete workload generates slow reads and timeouts until
  `gc_grace_seconds` — deletion is designed (TTL, time partitioning and drop), not
  improvised.
- **Repair/anti-entropy** as a scheduled and monitored task (`nodetool repair`
  incremental or an ecosystem tool; Cassandra 5.0.x includes automated repair
  backported from 6.0). An unrepaired replica is silently divergent data.
- **Backup and restore**: snapshot + a copy outside the cluster, encrypted, with an
  immutable or offline copy (3-2-1). **The gate is the restore**, and in these engines the restore
  usually involves rebuilding the topology and token ranges: rehearse it fully, timed, and
  record the real time as an SLI. In DynamoDB, PITR is a checkbox that **has to be
  enabled** and has its own window; copying to another account/region is a separate decision.
- **Major version upgrades**: read the full release notes, rehearse in
  staging with representative data, rolling upgrade node by node with verified protocol
  compatibility, and a **defined and tested rollback** (which in many engines is not
  reversible once the sstable/file format has been migrated: if there is no way back, the
  strategy is a parallel cluster and double writes). Never a `.0` in production. And mind the
  real support: in self-managed MongoDB, the *rapid releases* are not supported (§2).
- **Minimum observability**: p99 latency per operation, throttling/timeout rate, replica
  lag, traffic distribution per partition (to see the hot keys **before**
  the incident), maximum partition size, pending compactions, tombstones per
  read, and consumption against capacity. Symptom-based alerts with a runbook.
- **Cost — the access pattern is the bill**:
  - The **per-request (on-demand)** model versus **provisioned capacity**: in
    DynamoDB, after the November 2024 price cut (−50% on-demand, up to −67% on
    global tables), **on-demand is the reasonable default** for most workloads; provisioned
    wins with very predictable and stable traffic. There are *Database Savings
    Plans* (since December 2025, ~12-18%) and reserved capacity, each with its own scope.
    Re-verify prices and discounts before modelling (§8).
  - Bad modelling **multiplies** the bill without changing a line of business: `Scan` instead
    of `Query`, a GSI projecting `ALL` when `KEYS_ONLY` would have done, large items read
    whole to use one field, writes replicated to regions nobody reads, or a
    document that grows until it consumes several units per read.
  - A cost budget **per query** on the hot paths, measured in production and
    reviewed quarterly alongside the latency one. In NoSQL, cost and model are the same thing.
- **Capacity**: project data and traffic growth with real data; the moment to
  add nodes is before compaction cannot keep up, not when the disk is at 85%.

## 7. Sustainability, exit and prohibitions

- **A mandatory ADR** for: the choice of engine (with the "why not PostgreSQL" answered),
  the partition and sort keys, single vs multiple tables, the consistency level per
  operation, the retention policy and **the licence in force at the time of deciding**.
- **Re-evaluate the licence at every major upgrade**: this domain has changed licence
  three times in two years (ScyllaDB 2024, ArangoDB 3.12, Redis 2024-2025). An upgrade can
  change your legal obligations without changing a line of your code.
- **Exit and migration back to relational** when the decision was wrong (symptoms:
  every new feature requires remodelling; the application reimplements JOINs in memory;
  reconcilers proliferate; the bill grows faster than the traffic; nobody can
  answer an ad-hoc business query). Procedure:
  1. Pin the real access pattern observed in production (not the imagined one) and model the
     target relational schema, **normalising** what was duplicated.
  2. Bulk initial load + **CDC/stream** from the source engine (Change Streams, DynamoDB
     Streams, Cassandra CDC) into the target, until a stable lag is reached.
  3. Double writes or *shadow reads* with automatic result comparison during a
     period with real traffic; the cutover happens when divergence is zero and measured.
  4. Switchover by *feature flag*, with a way back available, and retirement of the old
     engine **as part of the project** (otherwise you keep two stores forever).
  - A partial migration is valid and often the best: leave in the NoSQL only the workload that
    justified §1 and take the rest to PostgreSQL.

**FORBIDDEN**
- ❌ Choosing NoSQL **for the shape of the data** (hierarchical, nested, "variable fields"): that
  is `jsonb` + GIN in PostgreSQL.
- ❌ Adopting it without an ADR with the **measured** need from §1 and without the "why not
  PostgreSQL".
- ❌ Modelling **by entity** (copying the relational model into the document store) or starting to
  model without the written list of access patterns.
- ❌ "Flexible schema" as an excuse for having no contract and no validation.
- ❌ Documents, arrays or partitions that grow **unbounded**.
- ❌ Low-cardinality or skewed-traffic partition keys, with no mitigation.
- ❌ `Scan` without a key filter, `ALLOW FILTERING`, or queries without an index on a hot path.
- ❌ Cassandra's native secondary indexes at scale without measurement; GSIs with `ALL`
  projection "just in case".
- ❌ Promising strong consistency the engine does not provide, or hiding the eventual one from the
  business.
- ❌ Using the NoSQL as the transactional store for money/stock without idempotence and without
  uniqueness guaranteed in the engine.
- ❌ An instance without authentication, with `0.0.0.0` reachable or without TLS between nodes.
- ❌ `$where`/server-side JavaScript, or filters built from untyped user input.
- ❌ Self-managing MongoDB on a *rapid release* (not supported outside Atlas).
- ❌ Mass deletion without a tombstone/compaction plan, or disabling repair.
- ❌ A backup without a rehearsed and timed restore; PITR left off in the belief that it comes
  enabled.
- ❌ A major upgrade without a rehearsal, without release notes and without a defined rollback path.
- ❌ Deploying a **source-available** engine (SSPL, BUSL, the ScyllaDB licence) in a commercial
  product or as a service without legal review and without recording the obligation in the ADR.
- ❌ Asserting versions, EOLs or **licences** from memory, without the verification in §8.

## 8. Mandatory web verification

Before pinning any fact from this document into a deliverable:

1. **The current licence of each engine** on its official page (`mongodb.com/legal/licensing`,
   the ScyllaDB licensing FAQ, the Couchbase CE licence, the ArangoDB licence): it is the fact
   that changes most and the one that costs most to get wrong. Verify the free-tier numeric limits
   too (10 TB / 50 vCPU on ScyllaDB, 5 nodes / 4 cores on Couchbase CE, 100 GiB
   on ArangoDB CE) **verbatim**, not from a summary.
2. **Stable version, release policy and EOL**: MongoDB (is 8.0 still the on-prem LTS?
   has 9.0 gone GA?), Cassandra (is 6.0 GA?), ScyllaDB (is 2026.3 stable?), DocumentDB and
   FerretDB (real release cadence).
3. **Open CVEs and patch versions** of the engines to be recommended, and presence in
   **CISA's KEV catalogue** (MongoBleed was in it in August 2026).
4. **Prices and billing models** of DynamoDB/Cosmos DB/Firestore and their commitment
   discounts: they change and they determine the design.
5. **Quotas and hard limits** of the managed service (item size, throughput per
   partition, number of indexes): a limit is a design constraint, not a detail.
6. **Supply-chain incidents** in the drivers and ODMs that are going to be used.

**Declared gaps** (not verified in the August 2026 session; **do not fill from
memory**, verify before using):
- **The current stable version of Couchbase Server** and the state of its Community Edition in 2026
  (only the licensing model and its limits were verified, not the version nor recent changes).
- **The state of MongoDB 9.0** beyond the existence of alpha tags.
- **ScyllaDB's real compatibility with the current CQL/Cassandra 5.0 version** (SAI,
  vector type): not verified.
- **FerretDB's activity status** after v2.7.0 (Nov 2025): not verified whether the cadence
  has resumed or the project has changed model.
- **Cosmos DB and Firestore**: no specific fact was verified (quotas, consistency
  models, prices) — treat everything relating to them as a **Declared gap** here.
- **CVEs for Couchbase, DynamoDB and DocumentDB**: not reviewed.

If the web contradicts this document, **the web wins** — flag the discrepancy.
