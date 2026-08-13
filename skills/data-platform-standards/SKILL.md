---
name: data-platform-standards
description: Standards for data platform design and operations. Use when working with PostgreSQL (data modeling, indexes, migrations, tuning, replication, HA, PITR), Redis or Valkey caching (TTL, cache patterns), Kafka streaming (partitioning, retention, schema registry), database backups, encryption at rest, data classification, retention policies, or GDPR compliance for stored data.
---

# Data platform standards

## 1. Scope and triggers

Applies when designing, reviewing or operating: relational databases, caches, data streaming, backups, encryption and the data lifecycle. Triggers: "PostgreSQL", "schema migration", "index", "replica", "PITR", "Redis", "Valkey", "cache", "TTL", "Kafka", "partition", "schema registry", "backup", "retention", "GDPR", "encryption at rest".

**Not applicable**: see `microservices-architecture-standards` (data ownership per service, outbox, sagas and event choreography; here, the engine that supports them), `api-design-standards` (the outward-facing contract; a table is not an API), `onprem-standards` and `homelab-standards` (the host, the storage and the hypervisor underneath the engine), `aws-standards`/`azure-standards`/`gcp-standards` (RDS/Aurora, Azure Database, Cloud SQL/AlloyDB/BigQuery as managed services: here, the modelling and operating criteria that apply just the same), `cryptography-pki-standards` (choice of algorithms and the lifecycle of the keys that encrypt data at rest; here, only the requirement to encrypt and classify it), `grc-compliance-standards` (the regulatory framework, the record of processing and the GDPR audit evidence), `privacy-engineering-standards` (the **engineering** of privacy: what data may be collected and for how long, DPIA, pseudonymisation versus anonymisation, crypto-shredding, data subject rights end to end — here, only their execution in the engine: partitioning by retention, deletion, encryption at rest, replicas), `bcdr-standards` (RTO/RPO derived from the business and the recovery order; here, PITR and the mechanics of the engine's backup), `identity-access-management-standards` (identity and authorisation of whoever accesses the data), `vulnerability-management-standards` (CVEs and EOL of the engines), `observability-standards` (engine metrics and alerts), `iac-standards` (the code that provisions the instance), `lua-standards` (**the `EVAL`/`EVALSHA` or `FUNCTION` script that runs inside Redis/Valkey**: atomicity, determinism and the ban on depending on the clock or on randomness are theirs; memory, persistence, the eviction policy and the engine's clustering belong here), `sql-standards` (**the SQL language**: how the query and the DDL are written —joins, CTEs and window functions, `NULL` and three-valued logic, SARGable predicates, quoting of dynamic identifiers, the writing mechanics of expand/contract—; **arbitration rule mirrored from its §1**: *if the question changes how the query or the DDL is written, it belongs to `sql-standards`; if it changes which engine is chosen, how it is sized, backed up, replicated or restored, it belongs here; if it changes the shape of the model, it belongs to the modelling skill*. Corollary: *"why doesn't this query use the index?"* is theirs —you rewrite the predicate—; *"which index do I create and how much does it cost to maintain?"* belongs here), the language skills (ORM, driver and migrations from the code), `gis-geospatial-standards` (**spatial data and its criteria**: PostGIS and its types and GiST/SP-GiST indexes, reference systems and projections, tolerance and geometric validity — **here, the PostgreSQL engine that hosts it**: sizing, backup, replica and the cost of those indexes). Engines other than PostgreSQL/Redis/Valkey/Kafka —Oracle, SQL Server, MySQL, NoSQL, graph, vector, time-series, search engines and lakehouse— have **their own skill and theirs wins**: `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`, `nosql-standards`, `graph-db-standards`, `vector-db-standards`, `timeseries-db-standards`, `search-engines-standards`, `lakehouse-standards`. What is kept here is cross-cutting (3-2-1, tested restore, versioned migrations, one store per need).

Guiding principle: **one store per need, not per fashion** — PostgreSQL covers by default the relational side, JSONB, basic full-text and simple queues (`SKIP LOCKED`); add a new piece (cache, broker, search engine) only when a measured need demands it and with its operational cost accepted in an ADR.

## 2. Default decisions

> **Mandatory web verification before pinning versions**: values verified in August 2026; re-verify with WebSearch on every real use (see §8).

| Area | Default | Note |
|---|---|---|
| Relational | **PostgreSQL 18.x** (18.4 stable; 19 in beta, GA expected autumn 2026 — not in prod until 19.1+) | Default unless a requirement rules it out, with an ADR |
| IDs | Native `uuidv7()` (PG 18) or `bigint identity` | UUIDv4 as a PK fragments B-tree indexes |
| In-memory cache | **Valkey** (BSD-3, Linux Foundation, 9.x) | Redis 8+ is tri-licensed (AGPLv3/RSALv2/SSPL): use it only if the organisation's licence policy accepts AGPL or if you need its integrated modules (JSON, query engine, vector) |
| Streaming | **Kafka 4.x** (4.2.1 current; KRaft, no ZooKeeper since 4.0) | Managed (MSK/Confluent Cloud/Aiven) unless there is real operational capacity to run it |
| Schema registry | **Karapace or Apicurio** (Apache 2.0) | Confluent Schema Registry is under the Confluent Community License, not OSS: a conscious decision |
| Event format | **Avro or protobuf** with a registry | JSON Schema only with validation in CI |
| Migrations | Versioned tool from the ecosystem (Flyway/Liquibase/Alembic/dbmate...) in the repo and in CI | Never manual DDL in prod |
| Backups | **3-2-1** + PITR with WAL archiving (pgBackRest/barman) | A backup without a tested restore does not exist |

## 3. Design and limits

### PostgreSQL — modelling
- Normalise by default (3NF); denormalise only with measurement that justifies it and documenting the invariant that is broken. JSONB for genuinely semi-structured data, not as an excuse for not modelling.
- Correct types: `timestamptz` (never `timestamp` without a zone), `numeric` for money, `text` + `CHECK`/domains instead of arbitrary `varchar(n)`. Constraints in the DB (`NOT NULL`, FK, `UNIQUE`, `CHECK`): the application validates, the database guarantees.
- Declarative partitioning (by date range, typically) when there is time-based retention or tables > tens of GB with a recent-access pattern; decide it at design time, not when the pain arrives.
- Schema conventions: `snake_case`, names in a single consistent language, audit columns (`created_at`/`updated_at` in `timestamptz`) by default; *soft delete* only if the business needs the history — and then with a partial index and a purge policy that respects retention (§5), not an eternal `deleted_at`.
- Multi-tenancy decided by ADR: schema/DB per tenant (strong isolation, more operation) vs a `tenant_id` column + **Row-Level Security enabled** as a mandatory safety net (never just filters in the app).

### PostgreSQL — indexes
- Every FK with an index. Composite indexes ordered by selectivity and query pattern; partial ones for hot subsets (`WHERE deleted_at IS NULL`); *covering* (`INCLUDE`) for measured index-only scans.
- Every index is justified with a plan (`EXPLAIN (ANALYZE, BUFFERS)`): unused indexes cost writes and space — review `pg_stat_user_indexes` periodically and drop the dead ones.
- Creation in prod always with `CREATE INDEX CONCURRENTLY` (outside a transaction, with a retry if it is left `INVALID`).

### PostgreSQL — migrations (expand/contract)
- Versioned, immutable once merged, with a total order and applied only by CI/CD. Every change backward compatible with the running code (N and N-1 coexist during the deployment):
  1. **Expand**: add the new column/table (nullable or with a default), dual write where appropriate.
  2. **Migrate**: backfill in small batches (avoids long locks and massive bloat).
  3. **Contract**: remove the old thing in a later migration, once telemetry confirms nothing uses it.
- Know the locks before every hot DDL (cheat sheet; verify against the docs for your version):

| Operation | Cost while hot | Safe alternative |
|---|---|---|
| `ADD COLUMN` (nullable or constant default) | Cheap (PG 11+) | — |
| Direct `SET NOT NULL` | Scan with a lock | `CHECK ... NOT VALID` + `VALIDATE CONSTRAINT` (PG 12+ takes advantage of it) |
| Column `ALTER TYPE` | Table rewrite | New column + backfill + swap (expand/contract) |
| Direct `ADD FOREIGN KEY` | Lock + validation | `NOT VALID` + `VALIDATE` afterwards |
| `CREATE INDEX` | Write lock | `CONCURRENTLY` |

- Set `lock_timeout` and `statement_timeout` in the migration session so as not to hang production; retry with backoff if it cannot get the lock.

### PostgreSQL — transactions and concurrency
- Short transactions: no transactions left open during external calls or while waiting for a user (they block vacuum, hold snapshots, worsen bloat). Alert on `idle in transaction`.
- Deliberate isolation level: `READ COMMITTED` by default; `REPEATABLE READ`/`SERIALIZABLE` with handling of serialisation errors (retry). Explicit locks (`SELECT ... FOR UPDATE SKIP LOCKED` for work queues) before table locks.
- Idempotent concurrent writes: `INSERT ... ON CONFLICT` for upserts; natural keys with `UNIQUE` as a safety net against duplicates from retries.

### Valkey/Redis — cache patterns
- **Cache-aside** by default: read cache → miss → read DB → write cache with a TTL. The DB is the source of truth; the cache is always disposable and rebuildable.
- **TTL mandatory on every key** (§7). TTL with jitter to avoid stampedes from synchronised expiry; for very hot keys, anti-stampede protection (a light lock or *soft-TTL* with background refresh).
- Explicit invalidation on write (delete, not a cache update — fewer races). Keys with a namespace and a version (`app:v2:user:{id}`) to invalidate per deployment.
- `maxmemory` + an explicit policy (`allkeys-lru`/`volatile-ttl` depending on use); never unlimited. If it is only a cache, persistence disabled; if some data requires durability, it does not belong in the cache.
- Design for the cache failing: the application must work (degraded) with the cache down; protect the DB from the *thundering herd* after it comes back (rate limit/progressive load). Other legitimate uses (rate limiting, distributed locks with expiry, light queues) are declared as such, with their own durability and HA assessed — not "taking advantage of" the cache instance.
- Using the cache as the only copy of business data is forbidden, and `KEYS` in prod is forbidden (use `SCAN`).

### Kafka — streaming
- **Partition key = the entity whose sequence matters** (order is only guaranteed within a partition). Size partitions by target throughput and consumer parallelism with headroom (growing partitions breaks key affinity: a design decision, not a patch).
- **Explicit retention per topic** according to data classification and GDPR (§5): `delete` with a bounded time by default; `compact` only for changelogs/state by key. No infinite retention "just in case".
- **Registry mandatory** with at least `BACKWARD` compatibility verified in CI; schema evolution additive only and with defaults. Idempotent producers (`enable.idempotence=true`, the modern default) and `acks=all` with `min.insync.replicas=2` (RF=3) for data that matters.
- Idempotent consumers (delivery is at-least-once), monitored lag, DLQ with a runbook. Commit offsets after processing (at-least-once), never before (silent at-most-once); *exactly-once* only within Kafka Streams/Kafka transactions, do not promise it end to end.
- Kafka is neither a database nor an eternal store: queryable state lives in a store of truth (PostgreSQL, object), fed from the stream. For long history, tiered storage or export to cheap storage, with an explicit decision.

## 4. Quality and testing

- **Migration tests in CI**: every PR applies `up` against a real DB (a container of the same major version as prod, e.g. Testcontainers), and validates N-1 compatibility: the current code works on the new schema and the new code on the previous schema during the rollout.
- Destructive migrations (drops from the contract phase) with double control: explicit review + confirmation from telemetry that they are unused; the pipeline flags them and requires separate approval.
- Test data: synthetic or anonymised fixtures — **forbidden** to copy production data with PII into test environments without verified anonymisation/masking.
- Integration tests of repositories/queries against real PostgreSQL, not against H2/SQLite or driver mocks: dialects lie.
- **Contract testing of event schemas**: the registry's compatibility check is a CI gate; a producer does not merge an incompatible schema.
- Performance with realistic data: validate the plans of critical queries with representative volumes (a plan over 100 rows does not predict 100M); latency budgets per query in the hot flows.
- Gates: SQL lint (sqlfluff or equivalent) + migrations applied + integration tests in CI. Merging DDL that has not gone through the pipeline is forbidden.

## 5. Security and personal data

- **Encryption at rest mandatory** (volume/filesystem or the managed provider's TDE) with keys in a KMS and rotation; column/application encryption for especially sensitive data. **TLS in transit** in PostgreSQL, Valkey/Redis and Kafka, intra-network too (zero-trust): `scram-sha-256` in PG (never `md5`/`trust`), AUTH+TLS in Valkey, SASL+ACLs per principal in Kafka.
- Least privilege: application roles without `SUPERUSER`/ownership, distinct users for app/migrations/read, credentials from a secrets manager with rotation; `pgaudit` or equivalent where there are audit requirements.
- **Data classification**: label every table/topic/cache key (public / internal / confidential / personal data). The classification determines encryption, retention, access and whether it may be in a cache or in a topic.
- **GDPR by design**:
  - *Minimisation*: do not store or publish "just in case" fields in events; PII out of logs, metrics and cache keys.
  - *Retention*: defined by classification and automated (date partitions + drop, `retention.ms` per topic, TTL); not "forever".
  - *Right to be forgotten*: deletion with full reach — DB (real delete, not just an eternal soft-delete), replicas, cache, topics (compaction with tombstones or **crypto-shredding**: encryption per subject and destruction of the key, the only practical route in immutable logs and backups within their documented retention window).
- Backups are personal data too: encrypted, restricted access and a retention window that the forgetting policy documents.
- Record of processing kept up to date: for every store with PII, document the purpose, legal basis, retention and who has access (GDPR art. 30); non-production environments count (§4: no real PII in test).
- Pseudonymisation where the use case allows it (analytics, metrics): surrogate keys without PII in the derived datasets; the mapping table under the strictest access control.
- Access to sensitive data audited and reviewed periodically; bulk exports (dumps, ETL to the outside) require approval and are traced (exfiltration control).

## 6. Operability

- **PostgreSQL HA**: streaming replication with at least one replica in another AZ; automated and **tested** failover (Patroni or equivalent when self-managed; multi-AZ when managed). Synchronous replicas only if RPO≈0 justifies the latency. `pg_stat_replication` and replica lag with an alert.
- Reads on a replica only for workloads that tolerate the lag (reporting, searches); never read your own write from the replica without session control. The HA replica is not the reporting one: heavy analytical workloads on a dedicated replica.
- Failover rehearsed on a schedule (game day): the exercise includes the application (reconnection, poolers, DNS/VIP), not just the engine.
- **PITR**: base backups + continuous WAL archiving (pgBackRest/barman or the provider's mechanism). RTO/RPO defined in writing and **restore rehearsed on a scheduled cadence** — the gate is "we restored and validated", not "the backup finished".
- **3-2-1 backups**: 3 copies, 2 media/systems, 1 off-site/off-account; at least one immutable or offline copy (ransomware). Automatic integrity verification.
- **Reasoned basic tuning** (a starting point, measure afterwards): `shared_buffers` ~25% RAM; `effective_cache_size` ~50-75%; `work_mem` calculated from connections×concurrent operations (no heroic global values); `random_page_cost` ≈1.1 on SSD/NVMe; `max_wal_size` and `checkpoint_completion_target` for smooth checkpoints (watch `checkpoints_req` vs `checkpoints_timed`); `wal_compression`; autovacuum **more** aggressive on hot tables (lower `autovacuum_vacuum_scale_factor`), never disabled. **PgBouncer/pooler** when there are many connections (transaction pooling; careful: it breaks session features — session prepared statements, advisory locks). Every parameter change with a reason and measurement before/after; the DB configuration is versioned code, with no manual changes (drift).
- **Cache HA**: Valkey/Redis with a replica + failover (Sentinel or cluster mode) only if the impact of losing the cache justifies it (measured: can the DB take the massive miss?); if not, a simple instance and a tolerant design (§3). Cluster for datasets that do not fit in one node, not for fashion.
- **Kafka ops**: RF=3 and `min.insync.replicas=2` on topics with important data; monitor under-replicated partitions, ISR shrink, disk usage per topic and partition skew (hot keys). Rehearsed rolling upgrades; brokers spread across AZs with `rack awareness`.
- **Observability** (`pg_stat_statements` always enabled; alert by symptom with a runbook). Minimum SLIs per piece:
  - PostgreSQL: query latency p95/p99, error rate, connections used/pool, replication lag, bloat, disk, transaction age (`wraparound`); slow query logs (`log_min_duration_statement`) and lock logs (`log_lock_waits`).
  - Valkey/Redis: hit ratio, evictions, memory used vs `maxmemory`, p99 latency, blocked clients.
  - Kafka: consumer lag per group, under-replicated partitions, throughput per topic, DLQ depth.
  - Backups: success/duration of the backup **and** of the test restore, age of the last validated restore (a first-class SLI).
- **Capacity**: project growth with data (table/topic size, IOPS, connections); review quarterly; cost (FinOps) is a design attribute — tiering/retention before "more disk".

## 7. Sustainability and evolution

- DB and event schemas evolve **only** through expand/contract (§3): the new coexists with the old, telemetry confirms the abandonment, and the contract is executed — removing is part of the task, not tacit debt.
- Major version changes (PG, Kafka, Valkey) planned: read the release notes, rehearse in staging with representative data, `pg_upgrade`/rolling upgrade with a defined rollback. Never jump to a .0 in production.
- ADR for one-way decisions: engine choice, partitioning strategy (PG and Kafka), partition keys, multi-tenancy model, retention policy.
- Avoid coupling to the provider without deciding it: proprietary features of the managed service (exclusive extensions, non-standard APIs) only with an ADR that records the exit cost.
- Continuous hygiene: review quarterly unused indexes, orphan tables, topics with no consumers and cache keys with no traffic — the schema accumulates debt too.

### List of prohibitions
- ❌ A database shared between services (each service owns its schema; integration via API/events).
- ❌ Manual DDL in production or migrations outside the versioned pipeline.
- ❌ A migration with a breaking change without an expand/contract phase (direct drop/rename of a column in use).
- ❌ Cache keys without a TTL, or the cache as the only copy of business data.
- ❌ `KEYS`, `FLUSHALL` or an instance without `maxmemory` in production.
- ❌ Topics without a schema in the registry, without a compatibility policy or with indefinite retention and no justification.
- ❌ A backup without a tested restore; unencrypted backups; no offsite/immutable copy.
- ❌ PII in logs, metrics, cache keys or events without need and without classification.
- ❌ `trust`/`md5` in `pg_hba.conf`, a superuser for the application, or DB secrets in code/repository.
- ❌ Disabling autovacuum, or fsync/synchronous_commit=off to "gain performance" on data that matters.
- ❌ Indexes not justified with an execution plan; blocking `CREATE INDEX` while hot.
- ❌ UUIDv4 as a PK in large insert-intensive tables (use uuidv7/bigint).
- ❌ Long transactions or `idle in transaction` without a timeout (`idle_in_transaction_session_timeout`).
- ❌ Copying production data with PII into non-production environments without anonymising.
- ❌ Kafka as a queryable store of truth or with implicit infinite retention.
- ❌ SQL built by concatenating input (always parameterised queries).
- ❌ Pinning versions, licences or parameters "from memory" without the verification in §8.

## 8. Mandatory web verification

Before pinning in a deliverable any version, licence or parameter recommended here, **verify with WebSearch** (the data in §2 is from August 2026 and expires):

1. Stable version and EOL of PostgreSQL (is it still 18.x? has 19 GA shipped?) — postgresql.org / endoflife.date.
2. Stable version of Kafka (is it still 4.2.x?) and of the chosen client/registry.
3. Licence status of Redis vs Valkey (Redis 8+: tri-licensed with AGPLv3 since May 2025; Valkey BSD-3 — any later change?).
4. Relevant CVEs of the versions to recommend and the state of the extensions/tools (pgBackRest, Patroni, PgBouncer, Karapace/Apicurio).
5. Applicable regulatory changes (GDPR/EDPB guidance) if the design touches personal data.

If the web contradicts this document, **the web wins** — flag the discrepancy.
