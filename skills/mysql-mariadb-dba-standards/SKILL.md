---
name: mysql-mariadb-dba-standards
description: Use when operating MySQL, MariaDB or Percona Server — my.cnf/mariadb.cnf and mysqld/mariadbd flags, innodb_buffer_pool_size, innodb_flush_log_at_trx_commit, innodb_redo_log_capacity, utf8mb4 charsets and collations, EXPLAIN/EXPLAIN ANALYZE plans, performance_schema and the sys schema, slow query log, mysqldump, mydumper, xtrabackup, mariabackup, binlog and GTID replication, semisync, InnoDB Cluster, Group Replication, Galera wsrep, ALGORITHM=INSTANT online DDL, gh-ost and pt-online-schema-change, Percona Toolkit, mysql_upgrade/mariadb-upgrade, or choosing between Oracle MySQL and MariaDB.
---

# MySQL / MariaDB / Percona standards (DBA)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when choosing, designing, operating, tuning or migrating servers of the MySQL family:
**Oracle MySQL**, **MariaDB Server**, **Percona Server for MySQL** and **Percona XtraDB
Cluster**. Covers the InnoDB engine and its sizing, schema and index design, plan reading,
online DDL, replication and clusters, logical/physical backup, performance
diagnostics, major upgrades and the server's security surface.

Triggers: `my.cnf`, `mariadb.cnf`, `/etc/mysql/conf.d/*`, `mysqld`, `mariadbd`, `mysql`,
`mariadb`, `mysqladmin`, `mysqlbinlog`, `mysqldump`, `mydumper`/`myloader`, `xtrabackup`,
`mariabackup`, `pt-online-schema-change`, `pt-query-digest`, `pt-archiver`, `gh-ost`,
`mysql_upgrade`/`mariadb-upgrade`, `mysqlsh`/MySQL Shell, `innodb_buffer_pool_size`,
`innodb_flush_log_at_trx_commit`, `innodb_redo_log_capacity`, `sql_mode`, `utf8mb4`,
`performance_schema`, `sys.*`, `SHOW ENGINE INNODB STATUS`, `EXPLAIN`/`EXPLAIN ANALYZE`,
`binlog`, `GTID`, `gtid_mode`, `rpl_semi_sync`, `wsrep_*`, Galera, InnoDB Cluster,
Group Replication, `ALGORITHM=INSTANT`, `ROW_FORMAT`, `ibd`, `ib_logfile`.

**Thesis of the skill**: *MySQL and MariaDB have been diverging for more than a decade and are no
longer interchangeable*. "It is the same thing, MariaDB is a drop-in" is a false belief that keeps
causing migration, replication and backup incidents. **Choosing one is an architecture decision with
an ADR**, not a packaging detail (§2, §3.1).

**Not applicable**: see `data-platform-standards` (**parent skill**: PostgreSQL is the catalogue's
relational default and the governing principle is *a store by need, not by fashion* —
this skill activates when MySQL/MariaDB is **already there** or when a hard requirement
imposes it, not to propose it by default; it also sets Valkey/Redis and Kafka),
`caching-cdn-standards` (the cache in front of the database; **explicit boundary**: if
the problem is a query with no index or an N+1, the solution is to fix the query, **not**
to add a cache — see §6), `oracle-dba-standards` (Oracle Database: RMAN, Data Guard,
RAC, AWR/ASH, licensing and the exit towards PostgreSQL) and `sqlserver-dba-standards`
(T-SQL, DBCC CHECKDB, Always On, Query Store, per-core licensing),
`nosql-standards`/`search-engines-standards`/`vector-db-standards`/
`timeseries-db-standards` (other data models; the last one also covers the decision to
partition by range in PostgreSQL before adopting a temporal engine),
`message-brokers-standards` (queues, brokers and distributed logs),
`streaming-cdc-standards` (**capture from the binlog is theirs**: Debezium, connectors,
event schema; **the impact on the engine belongs to this skill**: `binlog_format=ROW`,
`binlog_row_image`, binlog retention, I/O and purge cost, a dedicated replica for the
connector), `backup-recovery-standards` (generic repository mechanics, GFS retention,
immutability, encryption of the copy; here only the engine-specific tool and the
consistency of the recovery point), `bcdr-standards` (**the plan**: BIA, RTO/RPO
derived from the business, recovery order, disaster declaration),
`ha-clustering-standards` (Pacemaker/Corosync, STONITH, VIP and generic OS clustering;
here the engine's native clusters), `linux-storage-standards` and `onprem-standards`
(filesystem, I/O scheduler, NVMe, RAID and the hardware under the datadir),
`observability-standards` (metrics, traces and alerting platform; here which SLIs to export),
`sre-practice-standards` and `incident-management-standards` (SLOs and the incident process),
`vulnerability-management-standards` (triage and patching cadence; here which engine CVEs
to look at), `linux-hardening-standards` and `firewall-policy-standards` (host hardening and
network exposure), `identity-access-management-standards` (corporate identity; here
accounts and privileges *inside* the server), `cryptography-pki-standards` (algorithms and
lifecycle of the certificates the engine's TLS uses), `secrets-management-standards`
(where the application's password lives), `privacy-engineering-standards` (which personal
data may be stored and its erasure; here how it is executed in the engine),
`aws-standards`/`azure-standards`/`gcp-standards` (RDS/Aurora MySQL, Azure Database for
MySQL/MariaDB, Cloud SQL for MySQL as **managed services**: the schema, index and
replication criteria here still apply; control-plane operation does not),
`kubernetes-standards` (operators and statefulsets), `iac-standards` (provisioning),
`php-standards`/`python-standards`/`typescript-standards`/`jvm-spring-standards` (**MySQL is
the classic engine of LAMP and of many frameworks**: ORM, driver, pool and migrations from the
code are theirs; the resulting schema and its cost, from here),
`data-engineering-standards`/`analytics-bi-standards`/`lakehouse-standards` (analytics over
the data once extracted; **MySQL is not an analytical store**),
`sql-standards` (**the SQL language**; arbitration rule mirrored from their §1: *if the question
changes how the query or the DDL is written, it belongs to `sql-standards`; if it changes which
engine is chosen, how it is sized, backed up, replicated or restored, it belongs here*. The
MySQL/MariaDB dialect quirks that **change the code** —`ONLY_FULL_GROUP_BY` and the rest of
`sql_mode`, `INSERT ... ON DUPLICATE KEY UPDATE` in the absence of `MERGE`, collations and string
comparison— are theirs; **the server parameter that enables them and its operational impact,
here**).

## 2. Default decisions

> Verify the latest version and the EOL dates on the web before committing to them in a real
> project (§8). The following data are from **August 2026** and go stale fast.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| The catalogue's relational engine | **PostgreSQL** (see `data-platform-standards`) | MySQL/MariaDB only because of an existing system, a product requirement (WordPress, Zabbix, Moodle…), team competence or an imposed managed service — **with an ADR** |
| If it is MySQL | **MySQL 9.7.x LTS** (GA 2026-04-21, EOL 2034-04-21; 9.7.2 of 2026-07-28) | **8.4 LTS** only if there is a compatibility blocker (premier until 2029-04-30, extended until 2032-04-30). **8.0 died on 2026-04-30**: any 8.0 in production today is open risk |
| MySQL *Innovation* releases | **FORBIDDEN in production** | From 9.7, Oracle moves to **CalVer `YY.M`** (26.7 is the July-2026 one, next 26.10). An Innovation release is only supported **until the next one comes out**: it is a preview channel, not a production branch |
| If it is MariaDB | **MariaDB 12.3 LTS** (GA 2026-05-28) or **11.8 LTS** (EOL 2028-06-04, extended 2033-10-22) | 11.4 LTS (EOL 2029-05-29) and 10.11 LTS (EOL 2028-02-16) are still alive for legacy systems. **10.6 died on 2026-07-06**. Quarterly rolling releases (12.0/12.1/12.2…): **not in production** |
| Percona | **Percona Server for MySQL 8.4.x** (8.4.10-10, 2026-06-30) | **There is no Percona Server 9.7**: if you need MySQL 9.7 LTS, it is Oracle MySQL. Percona Server 8.0 EOL Jun-2026 |
| Table engine | **InnoDB, no exceptions** | MyISAM/Aria as a business data engine is **vetoed** (§7) |
| Character set | **`utf8mb4`** + an explicit, single collation across the whole schema | `utf8`/`utf8mb3` is the historic 3-byte disaster: it is not UTF-8, it breaks emoji and a good part of the extended BMP |
| Primary key | `BIGINT UNSIGNED AUTO_INCREMENT` or **binary UUIDv7** (`BINARY(16)`) | **UUIDv4 as a PK is vetoed** in insert-heavy tables (§3.2) |
| Durability | `innodb_flush_log_at_trx_commit=1` + `sync_binlog=1` | Any other value is **consciously accepted data loss**, with an ADR (§3.1) |
| Schema change | **Explicit `ALGORITHM=INSTANT`** when the operation supports it; otherwise `INPLACE`; failing that, **gh-ost** (or `pt-online-schema-change` if there are FKs you cannot touch) | Never let the server choose the algorithm silently |
| Physical backup | **XtraBackup 8.4** on MySQL/Percona; **`mariabackup`** on MariaDB | **XtraBackup does not work for MariaDB** and can produce corrupt copies silently: it is a real divergence of InnoDB internals (§3.6) |
| Logical backup | **mydumper/myloader** for volume; `mysqldump`/`mariadb-dump` only for schemas or small tables | `mysqldump` is single-threaded and its restore does not scale |
| Tooling | **Percona Toolkit 3.7.1-3** (2026-04-17) | `pt-query-digest`, `pt-archiver`, `pt-online-schema-change`, `pt-upgrade` are still maintained |
| High availability | **Asynchronous replication with GTID + orchestrated, rehearsed failover** | Synchronous clusters (InnoDB Cluster/Group Replication, Galera/PXC) only with a measured need and the operational cost accepted (§3.5) |
| DDL migrations | A versioned tool (Flyway/Liquibase/Alembic/dbmate/Skeema) in the repo and in CI | See `data-platform-standards` §3; manual DDL in production is vetoed |

### 2.1 The real map of the family (August 2026)

| Product | What it is today | Criterion |
|---|---|---|
| **Oracle MySQL** | Oracle's proprietary upstream, Community (GPLv2) + Enterprise. Innovation/LTS model, now CalVer | The default if you are already on MySQL. Watch out: development activity and the size of the contributor base are the subject of public criticism in 2026 — a risk factor to monitor, not an automatic reason to flee |
| **MariaDB Server** | A 2009 fork (Monty Widenius). **MariaDB plc has been owned by K1 Investment Management since Sep-2024** (a ~$37M acquisition after a disastrous spell on the stock market via a SPAC); the **MariaDB Foundation** governs the open project and is independent (AWS came in as a *diamond* sponsor) | Adoptable: the code is GPLv2 and the Foundation is the governance safeguard. **But the commercial backing is in the hands of private equity**: record in the ADR the risk of a model change and verify the corporate status before committing to paid support |
| **Percona Server for MySQL** | A *real* drop-in for Oracle MySQL with extra instrumentation (better `performance_schema`, thread pool, auditing, encryption). GPLv2 | A sensible choice when you want MySQL with serious diagnostic tooling. Cost: **it lags behind Oracle** (mainline 8.4, no 9.7) |
| **Percona XtraDB Cluster (PXC)** | Percona Server + Galera | See §3.5 before adopting it |
| **Other forks** (Aurora MySQL, TiDB, Vitess, Dolt, MyRocks…) | Compatible by *wire protocol*, not by engine | Wire protocol compatibility ≠ semantic compatibility. Each is a decision of its own with its own ADR |

## 3. Technical criteria

### 3.1 The MySQL ↔ MariaDB divergence (verified, August 2026)

Up to MariaDB 5.5 it was a drop-in; since the jump to 10.0 (2014) it stopped being one, and
**MariaDB no longer guarantees drop-in compatibility**. What remains true: **wire protocol
compatibility** — almost all MySQL drivers and clients talk to MariaDB. What is not true, and
breaks migrations:

- **JSON**: MySQL uses a **native binary** `JSON` type, with multi-valued indexes over
  arrays, indexable generated columns and the `->`/`->>` operators. In MariaDB, `JSON` is an
  **alias for `LONGTEXT`** with `CHECK (json_valid(...))`: every operation re-parses the text and
  there are no arrow operators. Migrating in either direction requires touching schema and queries.
- **Replication**: the **GTID formats are incompatible**. You cannot set a MariaDB as
  a replica of a MySQL primary (or vice versa) with GTID. It is the trap that most often
  turns a "transparent migration" into an outage.
- **High availability**: **Group Replication / InnoDB Cluster** (MySQL) and **Galera** (MariaDB,
  PXC) solve the same thing with different, **unmixable** implementations.
- **Vectors**: **MariaDB 11.8 LTS** brings `VECTOR(N)` and a native **`VECTOR INDEX` (modified
  HNSW)**, with `VEC_DISTANCE_EUCLIDEAN`/`VEC_DISTANCE_COSINE` and tuning
  (`mhnsw_ef_search`, `mhnsw_default_m`). **MySQL 9.7 has the `VECTOR` type but no ANN index
  in the community edition**: the index and `DISTANCE()` live in HeatWave (Oracle's
  cloud). If you need vector search *in the MySQL-family engine*, today that is MariaDB — or,
  better, a dedicated store (see `vector-db-standards`).
- **MariaDB only**: `SEQUENCE`, system-versioned tables (`SYSTEM VERSIONING`), Oracle
  compatibility mode, **thread pool in the community edition** (in MySQL it is Enterprise),
  ColumnStore.
- **MySQL only**: binary JSON, invisible indexes, transactional data dictionary,
  MySQL Shell and its AdminAPI, Group Replication, lateral derived tables, CIDR in user accounts.
- **Authentication**: `caching_sha2_password` (MySQL) and MySQL's SHA-256 are **not
  transferable** to MariaDB; `mysql_native_password` has been disabled by default since 8.4.
  Users are recreated, not migrated.

**Criterion**: a MySQL↔MariaDB migration is a **full migration project** —
schema conversion, query rewriting, account recreation, synchronisation by
logical dump (never by GTID), and a cutover window with rollback. Budget it as such or
do not do it.

### 3.2 InnoDB: what really moves the needle

- **`innodb_buffer_pool_size` is by far the highest-impact setting.** Starting
  point on a dedicated server: **50-75% of RAM**, leaving real headroom for connections,
  per-session `sort_buffer`/`join_buffer`, the OS and the page cache. On a shared server or a
  container with a `memory.limit`, size below the limit and **verify it does not die
  by OOM**. Decision metric: the physical read rate
  (`Innodb_buffer_pool_reads` / `Innodb_buffer_pool_read_requests`) — if the *working set*
  fits, that rate tends to zero and adding RAM stops paying off.
- **Redo log**: insufficient sizing → aggressive checkpoints and write stalls.
  MySQL 8.0.30+/8.4/9.7 use `innodb_redo_log_capacity` (which replaces
  `innodb_log_file_size`×`innodb_log_files_in_group`); MariaDB keeps `innodb_log_file_size`.
  **Verify the parameter name against the exact version before writing it down** (§8).
- **Durability — the real trade-off**: `innodb_flush_log_at_trx_commit`
  - `1` (default, **mandatory for data that matters**): fsync of the redo on every commit.
    Durable against an OS/host crash.
  - `2`: writes to the OS page cache on every commit, fsync every second. Survives the
    crash of the *process*, **not that of the host**. Loss window ≈1 s.
  - `0`: loss window ≈1 s even on a process crash.
  The "performance trick" of lowering it to 2 is **accepting data loss**: only with an ADR, only
  on read replicas, test environments or rebuildable workloads. With `sync_binlog=1` and
  `=1` you get durability *and* binlog↔InnoDB consistency; any relaxation breaks the
  recovery point of §3.6. If the fsync hurts, the right answer is usually
  **to batch writes and use storage with a battery-backed cache**, not to relax
  durability.
- **`innodb_flush_method`/`innodb_flush_neighbors`**: on NVMe/SSD, `O_DIRECT` and
  `innodb_flush_neighbors=0`; the inherited default is designed for spinning disks.
- **`innodb_io_capacity`/`_max`** matched to the real storage, measured — not copied off a blog.
- **MyISAM is dead**: no transactions, no crash recovery, table-level
  locking and silent corruption. It may only remain in internal system tables where the
  engine imposes it. Any business table on MyISAM/Aria is debt to be converted, and its
  presence invalidates any consistent backup strategy.

### 3.3 Schema: the clustered index rules

- **InnoDB organises the table physically by the primary key** (clustered index). Everything
  else follows from that:
  - A **monotonically increasing** PK (`AUTO_INCREMENT`, UUIDv7, ULID, Snowflake) always inserts
    at the end: full pages, few splits, a compact index.
  - A **random PK (UUIDv4)** inserts at scattered positions: constant *page splits*,
    fragmentation, half-empty pages, wasted buffer pool and write amplification.
    It is the most expensive and most frequent antipattern of the family. **Vetoed** on large
    tables.
  - If you need opaque identifiers on the outside: **UUIDv7/ULID in `BINARY(16)`** (never
    `CHAR(36)`), or an internal `BIGINT` PK + a unique public column.
- **Every table has an explicit PK**. Without one, InnoDB invents a hidden internal one you cannot
  use, and row-based replication degrades into full scans on the replica.
- **Narrow PK**: every secondary index stores the PK as a pointer. A wide PK inflates
  *all* the indexes.
- **Types**: `DATETIME`/`TIMESTAMP` with an explicit time-zone criterion (document which one and
  why; `TIMESTAMP` converts by `time_zone`, `DATETIME` does not) — and verify the status of the
  **year 2038 problem** in your version (MariaDB 11.8 extended the `TIMESTAMP` range).
  `DECIMAL` for money, **never `FLOAT`/`DOUBLE`**. `ENUM` only for genuinely
  fixed sets (adding a value is a DDL). `TEXT`/`BLOB` out of the hot row if they are not read
  every time. `NOT NULL` by default.
- **Classic traps**: `sql_mode` without `STRICT_TRANS_TABLES` accepts silent truncation —
  **set `sql_mode` explicitly and version it**; comparing a `VARCHAR` with a number causes
  implicit conversion and cancels the index; `utf8mb4` changes the maximum index key size
  (767→3072 bytes with `DYNAMIC`), so prefixes and long indexes have to be reviewed.
- **Collation**: choose **one** for the whole schema and for the connections. Mixing collations
  in a `JOIN` forces conversion and kills the index. Bear in mind that the `utf8mb4` collation
  default **changed between major versions** (`general_ci` → `0900_ai_ci` in MySQL 8+,
  `uca1400` in recent MariaDB): declare the collation, do not inherit it.

### 3.4 Online schema changes

Verified status (August 2026):

- **`ALGORITHM=INSTANT`** is the default in MySQL 8.4+ when the operation allows it, and covers:
  adding/dropping a column (in any position), adding/dropping a virtual column or `DEFAULT`,
  extending `ENUM`/`SET`, changing index type, renaming a table. **It does not cover building
  indexes, changing the PK or most type changes.**
- Hard INSTANT limits that bite in production: **a maximum of 64 row versions** (255
  since MySQL 9.1) before requiring a rebuild; **not** on `ROW_FORMAT=COMPRESSED`, nor
  with a `FULLTEXT` index, nor on temporary tables; a cap of 1022 internal columns; only
  `LOCK=DEFAULT`. `OPTIMIZE TABLE` (a rebuild) resets the counter.
- **Rule**: **always specify `ALGORITHM=` and `LOCK=` explicitly**, even the default.
  Letting the server silently choose a `COPY` on a 400 GB table is an incident.
- When INSTANT/INPLACE do not reach: **gh-ost** by default (no triggers, reads the binlog,
  the cutover controlled by you — better under heavy write load) or **`pt-online-schema-change`**
  if there are foreign keys you cannot drop or old versions. Both are still maintained.
  Both require space for a full copy of the table and a cutover window.
- Every migration with the **expand/contract** discipline of `data-platform-standards` §3, with
  a bounded `lock_wait_timeout` and retry: a DDL waiting on a *metadata lock* **queues every
  subsequent query on that table**, including the `SELECT`s. It is the mechanism by which
  "a small ALTER" takes down an entire service.

### 3.5 Indexes, queries and replication

**Indexes and plans**
- `EXPLAIN` first, `EXPLAIN ANALYZE` (MySQL 8.0.18+ / MariaAB with `ANALYZE FORMAT=JSON`)
  to contrast the estimate with reality. What to look at: `type` (`ALL` = full scan,
  `index` = full index scan — not good either), estimated vs actual `rows`,
  the `key` used, `Extra` (`Using filesort`, `Using temporary`, `Using index` = covering).
- **Composite index: order matters** — prefix by equality, then range, then ordering.
  An index `(a,b,c)` serves `a`, `(a,b)`, `(a,b,c)`; **not** `b` or `(b,c)`. A
  range condition consumes the rest of the index for ordering.
- **Covering**: if the index contains all the columns of the query, it does not touch the table
  (`Using index`). It is the highest-return optimisation on hot reads.
- **Antipatterns that cancel the index**: a function or arithmetic on the indexed column
  (`WHERE DATE(created_at) = …`), `LIKE '%something'`, `OR` over different columns without
  suitable indexes, implicit type or collation conversion, `SELECT *` when covering existed,
  pagination with a large `OFFSET` (use key/*keyset* pagination).
- Duplicate or redundant indexes (`(a)` when `(a,b)` exists) cost writes and space:
  periodic review with `pt-duplicate-key-checker` and `sys.schema_unused_indexes`.

**Replication**
- **GTID always enabled** (`gtid_mode=ON`+`enforce_gtid_consistency` in MySQL;
  `gtid_strict_mode` in MariaDB): without GTID, failover and reattaching replicas are
  manual and error-prone.
- `binlog_format=ROW` (the modern default) and `binlog_row_image` consciously decided:
  `FULL` is what CDC needs (see `streaming-cdc-standards`), `MINIMAL` reduces volume
  but breaks consumers that expect the full row.
- **Asynchronous** (default): fast, with a failover loss window equal to the lag.
  **Semisynchronous** (a plugin in MySQL, `rpl_semi_sync_master_wait_point=AFTER_SYNC`): the
  primary waits for an acknowledgement from at least one replica → RPO≈0 at the cost of commit
  latency and a degraded mode (on timeout, **it silently falls back to asynchronous**: alert on
  that state or you will not know you lost the guarantee).
- **Replica lag — real causes**, in order of frequency: a single-threaded applier for lack of
  parallelism (`replica_parallel_workers` + `binlog_transaction_dependency_tracking=WRITESET`),
  large transactions or long DDL, missing PKs on tables (full scans per row),
  saturated I/O, and heavy read queries competing on the replica. A useful metric:
  `Seconds_Behind_Source` **lies** in several scenarios — complement it with
  a heartbeat (`pt-heartbeat`) or a timestamp of your own.
- **Never write to a replica** except with `super_read_only=ON` deliberately disabled
  during a controlled failover. `read_only` is not enough for users with `SUPER`.
- **Clusters — the honest criterion**:
  - **InnoDB Cluster / Group Replication** (MySQL) and **Galera / PXC** (MariaDB/Percona) give
    consistency and automatic failover, but their real cost is high: extreme sensitivity to
    network latency, **a write penalty on a single hot row** (certification conflicts in Galera
    are errors the application **must** retry), DDL that
    blocks the cluster (TOI) or requires a rolling procedure (RSU), multi-primary writes
    that almost never pay off, and SST (state transfer) that can take hours on a
    large dataset.
  - **Default**: primary + asynchronous replicas with GTID and **orchestrated, rehearsed
    failover** (Orchestrator, MySQL Shell/MySQL Router, MaxScale, ProxySQL as the case may be).
    Adopt a synchronous cluster only with a measured RPO≈0 requirement and a team capable of
    operating it — documented in an ADR. A badly operated cluster has *less* availability than a
    primary with a replica.
  - Remember: `wsrep_notify_cmd` and the SST surface are **the most serious vulnerability class
    of 2026 in this family** (§5).

### 3.6 Backup and recovery point

- **Logical** (`mysqldump`, `mariadb-dump`, **mydumper/myloader**): portable across versions
  and engines, allows restoring a single table, **but** its restore is slow and the time grows
  with the dataset. Consistency only with `--single-transaction` (**and only if everything is
  InnoDB**: one MyISAM table silently breaks the dump's consistency).
- **Physical** (**XtraBackup 8.4** for MySQL/Percona; **`mariabackup`** for MariaDB): a hot
  file-level copy, fast restore, it is what makes the RTO viable. Rules:
  - **The tool's major version must match the server's.** XtraBackup 8.4
    does not back up data created by versions earlier than 8.4. XtraBackup 8.0 reached EOL in
    June 2026.
  - **XtraBackup is no good for MariaDB** (InnoDB internals diverged): use
    `mariabackup`. This confusion produces copies that restore and then corrupt.
  - Record the **LSN/binlog position** of each copy: it is the anchor for PITR.
- **PITR**: base copy + **binlogs archived off the host**, with a defined retention and
  `binlog_expire_logs_seconds` consistent with that retention. Without archived binlogs, your RPO is
  the age of the last backup, whatever the slides say.
- **Non-negotiable gate**: *a backup with no tested restore does not exist*. The SLI is the **age
  of the last validated restore** on a clean host, with an integrity check
  (`mysqlcheck`/`CHECKSUM TABLE` or comparison with `pt-table-checksum`) — not "the job finished
  green".
- The plan (RTO/RPO, recovery order, who declares the disaster, the ransomware scenario)
  lives in `bcdr-standards`; the repository, immutability and encryption, in
  `backup-recovery-standards`. Here only the engine mechanics.

## 4. Quality and CI gates

In increasing order of cost. The ones marked **break the build**:

1. **SQL and schema lint** (sqlfluff, or `skeema lint`): style, strict `sql_mode`,
   mandatory `utf8mb4`, mandatory `ENGINE=InnoDB`. **Gate**.
2. **Mandatory PK on every new table** and **a veto on `FLOAT`/`DOUBLE` for amounts** and on
   `utf8`/`utf8mb3`, checked against the PR's DDL. **Gate**.
3. **Migrations applied against a real engine** of the **same major version and same
   distribution as production** (container/Testcontainers): MySQL 9.7 is tested against MySQL
   9.7, not against MariaDB nor against SQLite. Dialects lie (§3.1). **Gate**.
4. **N-1 compatibility** (expand/contract): the current code works with the new schema and
   the new code with the previous schema. **Gate**.
5. **DDL budget**: the pipeline computes whether the `ALTER` is INSTANT/INPLACE/COPY and, if it is
   COPY or touches a table above a row threshold, **requires explicit approval** and
   a route via gh-ost/pt-osc. **Gate**.
6. **Plan review on critical queries** with representative volume: a plan over
   1,000 rows predicts nothing about 100M. A p95 latency budget per hot query.
7. **`pt-upgrade`** before every major upgrade: it compares results and plans from a
   real corpus of queries between the current version and the target.
8. **Primary-replica consistency** with `pt-table-checksum` on a schedule (silent
   drift is real, especially after replication incidents).
9. **Automated test restore** on a cadence, with its result as a published metric.
10. Synthetic or anonymised test data: **forbidden** to clone production with
    personal data to non-production environments without masking.

## 5. Security

- **Network surface**: port 3306 is **never exposed to the Internet**, not even "temporarily".
  Bind to an internal interface, deny-by-default filtering (`firewall-policy-standards`),
  administrative access via a bastion. A MySQL with a reachable `root@%` is an incident waiting
  for a date.
- **Accounts**: identity in this family is **`user@host`** — the `host` is part of the
  credential and is a real access control. **`%` is forbidden** except with justification and a
  compensating network; different users for the application, migrations, reads, backup and
  monitoring, each with least privilege (`SELECT,INSERT,UPDATE,DELETE` on **its**
  schema; never `ALL PRIVILEGES ON *.*`, never `SUPER`/`GRANT OPTION` for the application).
  Remove anonymous accounts and sample databases at provisioning time.
- **TLS mandatory** intra-network too (`require_secure_transport=ON`, `REQUIRE SSL` or per-account
  mTLS). Certificates and their lifecycle: `cryptography-pki-standards`.
- **Authentication**: `caching_sha2_password` in MySQL 8.4+/9.7 (`mysql_native_password`
  disabled by default — do not re-enable it "so the old driver works": update the
  driver). Passwords from the secrets manager, never in a readable `my.cnf` nor in container
  environment variables in the clear. `local_infile=OFF` unless needed (a vector for reading
  client files). `secure_file_priv` restricted or empty to disable `INTO OUTFILE`.
- **CVEs to watch (verified as of August 2026 — re-verify, §8)**:
  - **Galera/wsrep**: `CVE-2026-49261` (**CVSS 10.0**, command execution via
    `wsrep_notify_cmd` with the name of a *joiner* node), `CVE-2026-48165`, `CVE-2026-48163`
    and `CVE-2026-44168` (arbitrary commands on the donor during SST via rsync and mariabackup).
    **If you have Galera/PXC, this is priority one**; temporary mitigation: disable
    `wsrep_notify_cmd`. It is also the operational argument against adopting a synchronous cluster
    without a team that patches it at pace.
  - **MariaDB Connector/C `CVE-2026-44172`**: `mysql_real_escape_string()` **does not escape
    correctly with the `big5` charset** in the text protocol (fixed in 3.3.19 / 3.4.9). It is the
    demonstration of why manual escaping is vetoed: **use server-side prepared statements**,
    always.
  - MySQL is part of the quarterly **Oracle Critical Patch Update** (January/April/July/October);
    `CVE-2026-46850` (MySQL Shell, 9.9) and `CVE-2026-46860` (MySQL Router, 9.8) show that
    **the ecosystem's tools are attack surface just like the server**.
- **Supply chain**: the package repositories (Oracle, MariaDB, Percona), the
  container images and the Kubernetes operators are privileged code over your data.
  Pin by *digest*, verify the repository's signature and checksum. **A mandatory
  2026 precedent**: *Mini Shai-Hulud* / **CVE-2026-45321** demonstrated that SLSA level 3
  attestations **can be forged** — provenance is **no longer** sufficient proof
  on its own; combine it with digest pinning, change review and runtime detection
  (see `vulnerability-management-standards` and `cicd-standards`).
- **Auditing**: an audit plugin (Percona/MariaDB/Enterprise) where there is a requirement;
  logging of administrative access and of bulk exports (exfiltration control).
  The **general log is forbidden in production** (it logs credentials and kills performance).
- **Personal data**: classification, minimisation and real erasure per
  `privacy-engineering-standards`. Remember that the **binlogs and the backups also contain
  the deleted data** during their retention window: document it.

## 6. Performance and operability

- **The myth of "the database needs optimising"**: in the vast majority of cases the engine is
  fine and the problem is **the application**: an ORM **N+1** issuing 3,000 queries per
  request, a missing index, `SELECT *` over wide tables, `OFFSET` pagination, or a
  transaction left open during an HTTP call. **Diagnose before touching `my.cnf`.** Raising
  the buffer pool does not fix an N+1; it only makes it faster to run 3,000 times.
  → **Boundary with `caching-cdn-standards`**: putting a cache in front of a query with no
  index is hiding the problem and duplicating state. First the index or the query; the cache
  afterwards and with judgement.
- **Instrumentation**: `performance_schema` **enabled** (with bounded consumers if memory
  is tight) and **the `sys` schema as the read interface**: `sys.statement_analysis`,
  `sys.schema_unused_indexes`, `sys.schema_tables_with_full_table_scans`,
  `sys.io_global_by_file_by_bytes`, `sys.innodb_lock_waits`.
- **Slow queries**: `slow_query_log` with a low `long_query_time` (0.1-0.5 s) and
  `log_queries_not_using_indexes` **temporarily** (it floods the disk), digested with
  `pt-query-digest`. The unit of work is the **aggregate by query fingerprint**, not the
  isolated slow query: a thousand 20 ms queries weigh more than one 2 s query.
- **Minimum SLIs** to export (see `observability-standards` for the platform):
  connections used vs `max_connections` (and rejections), QPS by type, p95/p99 latency,
  buffer pool physical read rate, **replica lag** (with a heartbeat, not just
  `Seconds_Behind_Source`), lock waits and deadlocks, history list size
  (`History list length` — its growth betrays open transactions), disk usage of the
  datadir and of the binlogs, **the age of the last validated restore**.
- **Connections**: MySQL uses one thread per connection; a high `max_connections` is a trap
  of memory and context switching. **A pool in the application** properly sized (not 200
  connections per pod), or **ProxySQL/MaxScale** as a multiplexer when the number of clients
  demands it. Thread pool: community in MariaDB and Percona, Enterprise in Oracle MySQL.
- **Short transactions**, bounded `innodb_lock_wait_timeout` and `wait_timeout`,
  `MAX_EXECUTION_TIME` on the application's read queries. No transactions left open
  waiting on an external service.
- **Deadlocks**: they are normal under concurrent load; the application **must retry** with
  backoff. If they are frequent, the cause is inconsistent lock ordering between transactions,
  not the engine. `SHOW ENGINE INNODB STATUS` for the last one; `innodb_print_all_deadlocks` to
  investigate a pattern.
- **Capacity**: project table and index size, IOPS and connections with data; review
  quarterly. Cost (FinOps) is a design attribute: archiving with `pt-archiver` and
  partitioning by date range before "more disk".
- **Configuration as code**: `my.cnf` versioned and deployed by IaC. Zero manual
  changes in production; every parameter with a written reason and a before/after measurement.

## 7. Sustainability and prohibitions

**Upgrades**
- **Major versions are not skipped**: the route from MySQL 8.0 is **8.0 → 8.4 → 9.7**, sequential;
  the data dictionary is upgraded at each jump. Budget it as two projects.
- Before each jump: read the incompatibility notes, run **`pt-upgrade`** with
  real queries, and review **new reserved words** (8.4 added `MANUAL`, `PARALLEL`,
  `QUALIFY`, `TABLESAMPLE`, among others — an unquoted column name breaks at
  application startup, not at migration time).
- A rehearsal in pre-production with representative data and a **defined rollback route** (a
  replica of the old version kept until validation; once the dictionary is upgraded, there is no
  going back on the same datadir).
- Minimum cadence: quarterly patches aligned with Oracle's CPU / the MariaDB and Percona
  releases; **an LTS jump planned 12 months ahead** of EOL, not when the date arrives.
- Review every six months the status of the series you use against §8: in this family, the EOL
  dates are enforced and leave systems without security patches (8.0 and 10.6 died in 2026).

**List of prohibitions**
- ❌ Stating or assuming that **MariaDB is a drop-in for MySQL** (or vice versa). It has not been
  since 2014.
- ❌ Cross MySQL↔MariaDB replication with GTID, or mixing Group Replication with Galera.
- ❌ **XtraBackup against MariaDB** (use `mariabackup`), or a tool of a major version different
  from the server's.
- ❌ Running a series that is **out of support** (MySQL 8.0 after 2026-04-30, MariaDB 10.6 after
  2026-07-06, Percona Server 8.0 after Jun-2026) without a dated exit plan.
- ❌ **MySQL *Innovation* releases or MariaDB rolling releases in production.**
- ❌ MyISAM/Aria for business data; tables without an explicit primary key.
- ❌ **UUIDv4 as a PK** on large insert-heavy tables; a UUID in `CHAR(36)`.
- ❌ `utf8`/`utf8mb3`; mixed collations within a schema or across a `JOIN`.
- ❌ `FLOAT`/`DOUBLE` for monetary amounts.
- ❌ `sql_mode` not set explicitly, or without strict mode.
- ❌ `ALTER TABLE` without explicit `ALGORITHM=`/`LOCK=` on large tables in production.
- ❌ `innodb_flush_log_at_trx_commit != 1` or `sync_binlog != 1` on data that matters, without an
  ADR documenting the accepted loss window.
- ❌ **Concatenating input into SQL** or trusting manual client-side escaping (see
  `CVE-2026-44172`): server-side prepared statements, always.
- ❌ `root@%`, `ALL PRIVILEGES ON *.*` for the application, accounts with no `host` restriction,
  or 3306 reachable from outside the service network.
- ❌ The general log enabled in production; passwords in `my.cnf` without restricted permissions.
- ❌ Writing to a replica; `read_only` without `super_read_only`.
- ❌ Adopting Galera/PXC/InnoDB Cluster without a measured RPO≈0 requirement, without a failover
  **and** SST rehearsal, and without the capacity to patch quickly (§5).
- ❌ A backup with no tested restore; PITR without binlogs archived off the host.
- ❌ Copying production with personal data to non-production environments without anonymising.
- ❌ Touching `my.cnf` before having diagnosed the query (§6), or **adding a cache to
  cover up a query with no index**.
- ❌ Stating versions, EOL or the behaviour of a parameter **from memory**, without §8.

## 8. Mandatory web verification

None of the above regarding versions, dates or licences is taken as good without
checking it. Before committing it to a deliverable:

1. **MySQL**: current LTS series and dates — `endoflife.date/api/mysql.json` (raw data, not
   the HTML page) and Oracle's lifecycle. Confirm the **CalVer `YY.M` model** for
   Innovation/LTS after 9.7 and which LTS is recommended today.
2. **MariaDB**: LTS series and EOL — `endoflife.date/api/mariadb.json` and
   `mariadb.org/about/maintenance-policy/`. **Declared gap**: the exact EOL date of
   **MariaDB 12.3 LTS** has not been verified (the published policy and the feed did not agree at
   the time of writing: *3 years of community binaries + 2 of source patches* versus a 5-year EOL
   in other series). **Verify it before committing to a support window.**
3. **Percona**: the current version of Percona Server, XtraBackup, Percona Toolkit and PXC on
   `docs.percona.com`; and whether a line aligned with MySQL 9.7 already exists (as of August 2026
   it did **not**).
4. **MySQL↔MariaDB divergence**: MariaDB's official compatibility matrix
   (`mariadb.com/docs/.../mysql-to-mariadb-compatibility-matrix` and "Incompatibilities and
   Feature Differences") before planning any migration. It changes with every release.
5. **Exact parameter names** in the specific version: `innodb_redo_log_capacity` vs
   `innodb_log_file_size`, `utf8mb4` collation defaults, defaults for
   `binlog_transaction_dependency_tracking`, and the status of the semisynchronous plugin.
   **Against the version's manual, not from memory.**
6. **CVEs**: the quarter's Oracle CPU (`oracle.com/security-alerts/`), MariaDB
   Community/Enterprise CVE lists, Percona advisories, and the status of the 2026 Galera/wsrep
   CVEs (`CVE-2026-49261` and family) and of Connector/C (`CVE-2026-44172`). Prioritise with
   CVSS + EPSS + KEV (`vulnerability-management-standards`).
7. **Supply chain**: current incidents in package and image repositories;
   review the status of **CVE-2026-45321 / Mini Shai-Hulud** and which provenance guarantees
   are still valid.
8. **Declared gaps** (not verified on the web in this drafting — **do not fill from memory**):
   - The exact EOL of **MariaDB 12.3 LTS** (point 2).
   - The support status of **MariaDB 12.3 in the distributions** (Debian/RHEL/Fedora) and which
     series each one packages today.
   - The **active maintenance status of gh-ost** (latest release and cadence): it was verified
     that it is still the recommended reference tool, **not** the repository's activity.
   - Comparative performance figures for MariaDB Vector vs pgvector: they appear in the vendor's
     marketing material; **neither reproduced nor independently verified**.
   - The exact EOL date of **Percona Server 8.4** and of XtraBackup 8.4.

If the web contradicts this document, **the web wins** — flag the discrepancy.
