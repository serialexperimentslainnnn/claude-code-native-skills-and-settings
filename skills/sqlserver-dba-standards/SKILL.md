---
name: sqlserver-dba-standards
description: Use when operating Microsoft SQL Server — sqlcmd, SSMS, T-SQL, DBCC CHECKDB, tempdb file configuration, recovery models and transaction log growth, BACKUP DATABASE/DIFFERENTIAL/LOG and a broken log chain, RESTORE WITH NORECOVERY or WITH STANDBY, backup to URL, Always On availability groups, basic availability groups, failover cluster instances on WSFC, CLUSTER_TYPE EXTERNAL with Pacemaker on Linux, Query Store, sys.dm_os_wait_stats and wait statistics, plan regression and forced plans, clustered versus nonclustered and covering indexes, index fragmentation, RCSI and snapshot isolation, deadlock graphs and blocking, SQL Server Agent jobs, Ola Hallengren MaintenanceSolution, First Responder Kit sp_Blitz, dbatools, TDE, mssql-conf and mssql-server containers, edition core and memory limits, core versus Server+CAL licensing and Software Assurance failover rights, or SQL Server 2016/2017/2019/2022/2025 support dates and cumulative updates.
---

# Microsoft SQL Server administration standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Thesis of this document**: in SQL Server **the edition is an architecture decision**, not a
> purchase-order line. Moving from Standard to Enterprise to obtain full availability groups
> or online index rebuilds is a six-figure purchase in medium-sized installations;
> designing a solution that only works on Enterprise and landing it on Standard is a
> failed project. **The edition is fixed before the design, and the design respects it.**
>
> **Second thesis**: most of the instances found in production are
> **oversized** (Enterprise for a workload that fits comfortably in Standard) and at the same time
> **misconfigured** in what is actually free: `tempdb`, `MAXDOP`, the recovery model, RCSI and
> maintenance. There is almost always more performance in fixing that than in moving up an edition.

## 1. Scope and triggers

Applies to designing, licensing, operating, backing up, making highly available, diagnosing and maintaining
SQL Server on-prem, on Linux and in containers: editions and limits, instance architecture and
system databases, `tempdb`, recovery models and the log chain, native backup and restore,
Always On (AG and FCI), performance through wait statistics and Query Store, indexes,
blocking and isolation, T-SQL with judgement, maintenance jobs, engine security and
versions/support.

Triggers: `sqlcmd`, `SSMS`, `bcp`, `mssql-conf`, `mssql-cli`, `dbatools`, `T-SQL`,
`DBCC CHECKDB`, `DBCC SHOW_STATISTICS`, `tempdb`, `master`/`model`/`msdb`,
`RECOVERY FULL|SIMPLE|BULK_LOGGED`, `log_reuse_wait_desc`, `BACKUP DATABASE`, `BACKUP LOG`,
`RESTORE ... WITH NORECOVERY|STANDBY`, `RESTORE VERIFYONLY`, `BACKUP TO URL`, `msdb.dbo.backupset`,
`Always On`, `availability group`, `AG listener`, `WSFC`, `CLUSTER_TYPE = EXTERNAL|NONE`,
`FAILOVER_MODE`, `FCI`, `Query Store`, `sys.query_store_*`, `sys.dm_os_wait_stats`,
`sys.dm_exec_requests`, `sys.dm_db_index_usage_stats`, `sys.dm_db_index_physical_stats`,
`sp_WhoIsActive`, `sp_Blitz`, `sp_BlitzIndex`, `sp_QuickieStore`, `MaintenanceSolution.sql`,
`READ_COMMITTED_SNAPSHOT`, `ALLOW_SNAPSHOT_ISOLATION`, `deadlock graph`, `MAXDOP`,
`cost threshold for parallelism`, `max server memory`, `SQL Server Agent`, `TDE`, `sysadmin`,
`mssql/server` (container), "cumulative update", "Standard edition", "Software Assurance".

**Not applicable**: see
- `data-platform-standards` (**parent skill**: PostgreSQL as the default, relational modelling,
  expand/contract migrations, data classification and retention. Its principle —*a store by
  need, not by fashion*— still rules: **this skill does not justify choosing SQL Server**, it covers
  operating it well when it is already there by historical decision, because a third-party product requires it or
  because of a consolidated .NET/Windows ecosystem).
- `windows-server-ad-standards` (**critical boundary, total delegation**: forest/domain/OU, GPO,
  **Kerberos and NTLM**, SPN, delegation, **gMSA/dMSA**, Tier 0 model, PAW, forest recovery
  and Windows Server hardening are **theirs**. SQL Server's integrated authentication
  *rests* on all of that: **here it is only stated what the engine requires** —service account, correct
  SPN for Kerberos, server roles— and **the how is delegated**. **Forbidden to duplicate AD
  criteria here.**).
- `ha-clustering-standards` (**Pacemaker/Corosync, quorum, fencing/STONITH and their discipline are
  theirs**). Boundary declared explicitly: **WSFC is the Windows cluster and it belongs to this
  skill** (it is inseparable from FCI and from AGs on Windows); **when SQL Server runs on Linux, the
  cluster manager is Pacemaker and `ha-clustering-standards` rules** —including fencing, without
  which there is no HA— and here only what belongs to the engine lives: `CLUSTER_TYPE = EXTERNAL`,
  `FAILOVER_MODE = EXTERNAL`, the AG resource and the `mssql-server-ha` package.
- `backup-recovery-standards` and `bcdr-standards` — **arbitration rule mirrored word for
  word from `backup-recovery-standards` §1**:
  > **"how is the copy made?" belongs to `backup-recovery`** (tool, repository, 3-2-1, GFS,
  > dedup, repo encryption, integrity, catalogue, restore procedure); **"how much can we
  > lose, in what order do we bring it back and who decides?" belongs to `bcdr`**.
- `sql-standards` (**the SQL language**; arbitration rule mirrored from its §1: *if the question
  changes how the query or the DDL is written, it belongs to `sql-standards`; if it changes which engine is
  chosen, how it is sized, backed up, replicated or restored, it belongs here*). Theirs are the
  T-SQL peculiarities that **change the code** —`MERGE` and its conditions for safe use,
  `OUTPUT`, `TOP`, `APPLY`, `OFFSET/FETCH`, the effect of collation on string
  comparison—; from here, everything that decides execution: Query Store, forced plans, compatibility
  levels, `READ_COMMITTED_SNAPSHOT`, statistics, DBCC and the per-core licensing of
  the features a construct may require.

  Its own extension: **what is engine-specific belongs here** — recovery models, the log
  chain and how it breaks, full/differential/log backups, `RESTORE ... WITH STANDBY`,
  `RESTORE VERIFYONLY`/`CHECKSUM`, backup to URL and the role of AGs in the RPO. **The repository,
  its immutability and the cadence of the test restore belong to `backup-recovery`**; **the RPO/RTO
  that justifies synchronous mode and the failover exercise belong to `bcdr`**.
- `oracle-dba-standards` (the catalogue's other proprietary engine; a different vendor, the same
  pattern: **licensing decides the architecture**. They do not compete).
- `dotnet-standards` (**the C#/EF Core code that consumes this database is theirs**: driver,
  pool, `Microsoft.Data.SqlClient`, migrations from the application).
- `streaming-cdc-standards` (**capture is theirs**: CDC, change tracking, change event streaming,
  Debezium; **the cost in the engine belongs here**: log retention, capture jobs, impact
  on the recovery model).
- `azure-standards` (Azure SQL Database, Managed Instance, Arc, Azure Hybrid Benefit),
  `aws-standards`/`gcp-standards` (RDS for SQL Server, Cloud SQL for SQL Server).
- `vulnerability-management-standards` (**the CVE cycle and the patching window are theirs**; here
  only the mechanics of CUs and their cadence), `identity-access-management-standards`,
  `cryptography-pki-standards` (TLS and the keys TDE rests on), `secrets-management-standards`,
  `linux-hardening-standards` and `podman-systemd-containers-standards`/`kubernetes-standards`
  (the OS and the runtime when SQL Server runs outside Windows),
  `observability-standards`, `grc-compliance-standards`, `privacy-engineering-standards`,
  `iac-standards`, `firewall-policy-standards` (exposure of port 1433).
- `mysql-mariadb-dba-standards` (the catalogue's third relational engine; open source, without the
  edition variable that dominates here), `timeseries-db-standards`, `message-brokers-standards`,
  `nosql-standards`, `search-engines-standards`, `caching-cdn-standards` (other specialised
  stores).

## 2. Editions and licensing: the dominant decision

> **Scope warning, non-negotiable**: what is set here is **technical criteria**, not contractual
> advice. Every decision with an economic impact is validated against the **SQL Server licensing
> guide**, the current **Product Terms** and the organisation's **licence manager**.
> No price appears in this document (§8).

### 2.1 Standard's real limits — verified on SQL Server 2025 (17.x)

Primary source: *Editions and supported features of SQL Server 2025*, learn.microsoft.com
(also checked against the markdown of the `MicrosoftDocs/sql-docs` repository).

| Limit | Enterprise | **Standard** | Express |
|---|---|---|---|
| Maximum compute per instance (engine) | OS maximum | **Lesser of 4 sockets or 32 cores** | Lesser of 1 socket or 4 cores |
| Maximum *buffer pool* memory per instance | OS maximum | **256 GB** | 1,410 MB |
| Columnstore segment cache | Unlimited | 32 GB | 352 MB |
| *Memory-optimized* data per database | Unlimited | 32 GB | 352 MB |

**A change that does move a design** — footnote 2 of the document itself: *"In SQL Server 2022 (16.x)
and earlier versions, the limit is the lesser of 4 sockets or 24 cores."* That is: **Standard went
from 24 to 32 cores and its buffer pool rose to 256 GB in the 2025 version**. A sizing exercise done
on "Standard is 24 cores and 128 GB" is out of date and may be justifying an unnecessary
Enterprise. **Always verify against the page for the specific version**: the limits are per
version.

### 2.2 What separates Enterprise from Standard (what decides the architecture)

Enterprise only (verified in the 2025 table):
- Full **Always On availability groups**, **contained AG**, **distributed AG**, automatic
  read/write connection redirection. **Standard only has *basic availability groups***:
  *"A basic availability group supports two replicas, with one database."* — two replicas, **a
  single database**, with no readable replica.
- **FCI**: Enterprise up to **16 nodes**; Standard **2 nodes**.
- **Online index rebuild and create** (and its *resumable* version), **online schema
  change**, **online page and file restore**, *fast recovery*, mirrored backups.
- Almost all advanced *Intelligent Query Processing* (batch mode on rowstore, adaptive joins,
  memory grant feedback, cardinality feedback, DOP feedback, *automatic tuning*), **Query Store on
  secondary replicas**, parallel index maintenance, parallel `CHECKDB`, distributed partitioned
  views.

**In Standard, and this is what usually surprises people** (and dismantles many "we need Enterprise"):
**TDE**, **backup encryption**, **backup compression**, **table and index partitioning**,
**data compression**, **columnstore**, **In-Memory OLTP**, **Query Store**, **Always Encrypted**
(also with *secure enclaves*), **row-level security**, **dynamic data masking**, **auditing**,
**Change Data Capture**, **Accelerated Database Recovery**, **optimized locking**, **backup and
restore to S3-compatible object storage**, **clusterless AG** and
—**new in 2025**— **Resource Governor**, which used to be Enterprise-only.

Decision rule: **Enterprise is justified by real HA (a multi-database or multi-replica AG),
24×7 online maintenance or a compute ceiling**; not by features that are already in Standard.
Every Enterprise proposal is accompanied by which of those three reasons applies.

Other edition facts verified in 2025: **Express** goes up to 1 socket/4 cores and now
includes what used to be *Express with Advanced Services*; **Enterprise Developer** and
**Standard Developer** exist as separate editions (Developer = the full functionality of its edition,
**licensed only for development and testing — never in production**); the **Web** edition is withdrawn
from 2025 onwards (2022 is the last one that includes it); on-prem *Reporting Services* is consolidated under
**Power BI Report Server**.

### 2.3 Licensing model

- **Per core**: **physical cores** are counted (*hyperthreading* does not count), with a per-processor
  minimum and sale in packs of 2. It is the only model available for Enterprise in new
  agreements.
- **Server + CAL**: Standard only. It stops paying off beyond a certain number of users; the
  threshold depends on the agreement — **calculate it, do not estimate it**.
- **Enterprise with Server+CAL** (legacy, not available for new agreements) is **limited to
  20 cores per instance** (footnote 1 of the editions document): an old contract may
  be imposing a performance ceiling nobody remembers.
- **Virtualisation**: with **Software Assurance**, Enterprise offers unlimited virtualisation on
  a fully licensed host; without SA, you license per VM. Counting VMs on a shared
  host without SA is the fast route to an audit finding.

### 2.4 Software Assurance and its role in high availability — **the expensive trap**

**Failover rights are a Software Assurance (or subscription licence) benefit.
Without SA, a passive replica is fully licensed, even if it never serves a
query.** With SA, for each licensed OSE you can run passive replicas in anticipation of
a failover (typically one for HA, one for DR and one in Azure), **provided they neither serve data nor
run active work** and do not exceed the primary's licence.

Direct design consequences, not procurement ones:
- A **readable secondary** in an AG **stops being passive**: it is licensed. "Offloading the reports to
  the replica" is a purchase. The same goes for running backups or `CHECKDB` on the secondary
  under the current terms: **verify it before designing it**.
- The cost of HA in SQL Server is not the cluster: **it is the second node's licence if there is no SA**.
- **Verify the current Product Terms**: failover rights have been redefined more than
  once. Their wording is not fixed here; what is fixed is the obligation to check it.

## 3. Instance architecture

- **One instance per host as the default.** Multiple named instances split memory and CPU
  between competing engines and complicate patching; separating by container or by VM is cleaner
  and easier to license. Consolidate into **databases within one instance**, not into
  instances within a host.
- **System databases**: `master` (configuration and logins) and `msdb` (Agent, backup
  history, plans) **are part of the backup strategy** — losing them costs a rebuild of the
  environment; `model` is the template for every new database (setting the recovery model and default
  file sizes there avoids surprises); `tempdb` is recreated at startup and **is not
  backed up**.
- **Memory**: `max server memory` **always set**, leaving headroom for the OS (and for other consumers
  on the host); never left at the default. `min server memory` only if there is real competition. On Linux, limits
  via `mssql-conf` and **cgroup v2** (honoured from SQL Server 2025 and from 2022 CU 20 —
  before that, a container with a memory limit could die of OOM because the engine ignored it).
- **Parallelism**: `MAXDOP` and `cost threshold for parallelism` **explicit** from day one. The
  default value of `cost threshold` (5) is from the nineties and parallelises trivial queries:
  raising it is one of the product's best benefit/risk changes. `MAXDOP` according to
  core count and NUMA, with the exception documented per workload.
- **Storage**: data, log and `tempdb` on volumes with different I/O profiles; the transaction
  log is **sequential write and latency-sensitive** — it is the first place to put
  fast storage. NTFS formatted with a 64 KB allocation unit on Windows unless the array vendor's
  criteria say otherwise (`linux-storage-standards`/`onprem-standards` for the rest).
- **Autogrowth**: in **fixed and large** increments, never as a percentage, and with
  *Instant File Initialization* enabled (the *Perform Volume Maintenance Tasks* privilege) so that
  data growth does not freeze the instance. Autogrowth is a **safety net**,
  not a capacity strategy: files are pre-sized.

### 3.1 `tempdb` — the setting with the most real impact

- **Multiple data files, all of the same size and with the same autogrowth**: allocation
  page contention in `tempdb` is the classic bottleneck of busy instances, and it only
  disappears if the files are symmetric (the allocator is *round-robin* proportional to free
  space: an unequal file takes all the work). The modern installer proposes a reasonable
  number based on cores; **review it, do not accept it blindly**, and **never**
  leave a single file on a server with several cores.
- **Pre-size** so that it does not grow while hot; a dedicated and fast volume; *memory-optimized
  tempdb metadata* only on Enterprise and with a workload that justifies it.
- `tempdb` is **shared by the whole instance**: a query with a monstrous `sort` or a badly used
  `snapshot isolation` affects every database. Watch it as a global resource.
- On Linux, `tempdb` on **tmpfs** is supported: a real performance option, with the consequent
  RAM consumption accepted.

### 3.2 Recovery models and their direct consequence

| Model | What it implies | Recovery point |
|---|---|---|
| **SIMPLE** | The log is truncated automatically at each *checkpoint*. **There is no log backup** | Only the last full/differential. **RPO = hours**, like it or not |
| **FULL** | The log is retained **until it is backed up**. Mandatory for AGs and *log shipping* | PITR to the minute/second, if and only if there are periodic log backups |
| **BULK_LOGGED** | Minimal logging of certain bulk operations | **It breaks PITR within the interval** containing the bulk operation: you recover to the end of the log backup, not to an instant |

**The consequence that gets forgotten**: putting a database in **FULL without scheduling log backups** does not give
better recovery — it makes **the log grow until it fills the disk** and takes the instance down. It is the
product's most frequent self-inflicted incident. Operational rule:

- The model is determined by the **RPO derived by `bcdr-standards`**, and **FULL implies scheduled log
  backups on the same day it is enabled**. There are no half measures.
- Mandatory diagnosis when the log grows: `sys.databases.log_reuse_wait_desc` says **why**
  it cannot be reused (`LOG_BACKUP`, `ACTIVE_TRANSACTION`, `AVAILABILITY_REPLICA`,
  `REPLICATION`…). It is read **before** touching anything.
- **Forbidden**: `DBCC SHRINKFILE` on the log as a routine, and forbidden any Internet
  recipe that goes through putting the database into SIMPLE to "clean the log": **it breaks the log chain**
  (§4) and with it the recovery point.
- **VLF**: grow the log in large and few increments; thousands of VLFs slow down startup and
  recovery.

## 4. Native backup and restore

- **Three pieces**: **full** (the base of the chain), **differential** (everything changed since the
  last full — not since the previous differential) and **log** (the changes since the previous log
  backup, and **only** in FULL/BULK_LOGGED).
- **The log chain** is the asset: an uninterrupted sequence of log backups since a
  full. **It is broken by**: putting the database into SIMPLE (even if it goes back to FULL, a new
  full is needed), a log backup with `TRUNCATE_ONLY` from old versions, or an **out-of-band
  backup** taken by another tool that does not use `COPY_ONLY`. Hence the rule:
  **every ad-hoc backup is taken with `COPY_ONLY`** — a normal full from an external tool
  resets the differential base and leaves the scheduled differentials meaningless.
- **Verification**: `WITH CHECKSUM` on the backup and `RESTORE VERIFYONLY WITH CHECKSUM` as the automatic
  minimum. That is **not** a restore: it only says the file is readable.
- **`RESTORE ... WITH NORECOVERY`** to chain the differential and the logs; **`WITH STANDBY`** leaves the
  database **readable between log applications** (an undo file) — it is the right tool
  for *log shipping* with a queryable secondary, and the cheap way to have a readable delayed
  copy without licensing readable replicas.
- **Restore to a point in time**: `RESTORE ... WITH STOPAT` (or `STOPATMARK`) over the log chain.
  Rehearse it before needing it: human error is recovered with this, not with an AG.
- **Backup to URL** (object storage): supported to *block blobs* with SAS; in 2025 also
  **to S3-compatible storage via REST**, on Enterprise **and Standard**. It is a destination, not
  a policy — **the repository, immutability and the 3-2-1 rule belong to
  `backup-recovery-standards`**. On Linux, *backup to URL* with a *page blob* is not supported.
- **Encryption**: `BACKUP ... WITH ENCRYPTION` available in Standard and Enterprise; the **certificate or
  asymmetric key is backed up and held outside the system being backed up** (key custody,
  `bcdr-standards`). An encrypted backup whose certificate was lost with the server is a useless
  copy: **it is the most common way of discovering there was no DR**.
- **Catalogue**: `msdb.dbo.backupset`/`backupmediafamily` is the record of what exists. It is queried
  to detect **coverage gaps** and it is backed up with `msdb`.

> **Shared invariant, with no nuance**: **a backup without a tested restore does not exist.** The gate is not
> "the job finished green", it is "we restored, timed it and validated it". The cadence and the record
> of the exercise are set by `backup-recovery-standards`; the engine's procedure belongs here.

## 5. High availability

- **Availability Groups (AG)**: replication at the **database** level via log shipping.
  - **Synchronous** = RPO 0 and automatic failover possible, **at the cost of latency on every commit**
    (the primary waits for the hardening on the secondary). **Asynchronous** = no latency impact,
    with potential loss and **only forced manual failover, with data loss**. The choice is
    dictated by `bcdr-standards`'s RPO, not by convenience.
  - **Listener**: the application connects to the *listener*, never to a node's name, and the
    connection string declares `MultiSubnetFailover=True` when there are different subnets. Without that, the failover
    "works" and the application does not come back.
  - **Readable replica**: it is not free in two senses. **Licensing** (§2.4: it stops being passive) and
    **performance** — read-only queries implicitly take *snapshot isolation*,
    which generates **row versioning on the primary** (14 bytes per modified row) and increases
    `tempdb` usage on the secondary; besides, the `REDO` can block against long queries and
    trigger *redo lag*, which is real RPO lost. It is monitored.
  - On Enterprise, per the 2025 documentation: up to **8 secondary replicas**. **Standard only
    has *basic AG***: 2 replicas, **1 database**, with no readable secondary (§2.2).
- **FCI (failover cluster instance)**: it shares **storage**; it protects against node
  failure, **not against data failure** (a corrupt LUN is corrupt for everyone). It requires a cluster
  (WSFC/Pacemaker) and shared storage. Enterprise 16 nodes, Standard 2.
- **AG vs FCI, in one line**: FCI protects the server with a single copy of the data; AG protects the
  data with several copies and allows geographic separation. **They are combined** (an FCI as a replica of an
  AG) only with a written reason: the complexity multiplies.
- **Cluster boundary, declared**:
  - **Windows** → **WSFC** is the substrate of FCI and of AGs (except *clusterless*). Its quorum
    (disk, file share or cloud witness), its vote model and its operation belong **to this
    skill**. The domain, the accounts and the DNS it rests on belong to
    `windows-server-ad-standards`.
  - **Linux** → the manager is **Pacemaker/Corosync** and **`ha-clustering-standards`** rules,
    including its invariant: **without tested fencing there is no HA, there is deferred corruption**. What belongs to the engine
    is: `CLUSTER_TYPE = EXTERNAL` with `FAILOVER_MODE = EXTERNAL` (the only combination with automatic
    failover), the **`mssql-server-ha`** package —with HA agent v2 from **SQL Server 2025
    CU 3**— and the AG and IP resources.
  - **`CLUSTER_TYPE = NONE`** (clusterless AG): **manual failover only**, intended for *read-scale*
    and rolling upgrades. **It is not high availability**: do not sell it as such.
  - **An AG or FCI cannot span WSFC and Pacemaker.** For mixed scenarios there are only two routes,
    both AG-based: `CLUSTER_TYPE = NONE` or a **distributed AG**.
- **Mandatory rehearsal**: failover is tested with the application inside the exercise (reconnection,
  pool, DNS, `MultiSubnetFailover`), at `bcdr-standards`'s cadence. An AG that has never
  failed over is an assumption.
- **Forbidden**: *database mirroring* in new designs (**deprecated**), and presenting an AG as
  a substitute for backup — a `DELETE` replicates in milliseconds.

## 6. SQL Server on Linux and in containers

It is a first-class deployment, **with known cutbacks**. Not supported on Linux (verified in
the 2025 documentation): **merge replication**, **FILESTREAM and FileTable**, **extended
system procedures (`xp_cmdshell`)**, **linked servers to non-SQL Server sources**
(use PolyBase), **`EXTERNAL_ACCESS`/`UNSAFE` CLR assemblies**, **Buffer Pool Extension**,
**database mirroring**, **Always Encrypted with secure enclaves**, **EKM** (except with Azure Key
Vault from 2022 CU 12), **integrated Windows authentication for linked servers and for
AG endpoints** (the endpoints use certificate authentication), **Analysis Services**,
**Reporting Services**, several Agent subsystems (CmdExec, PowerShell, SSIS, SSAS, SSRS),
**Agent alerts** and *Managed Backup*. In addition: **a single instance per host** (there is no SQL
Browser and no named instances) and **Linux deployments are not FIPS compliant**. From
SQL Server 2025, **SLES is no longer supported**.

Containers: the official `mssql/server` image. Criteria:
- Pin the image **by digest**, explicit `MSSQL_PID`, the `sa` password from the secrets
  manager (never in the `Dockerfile`, the `compose` file or the command line), and **persistent
  volumes** for data, log and backups — a database container with no volume is
  scheduled data loss.
- **cgroup v2** honoured from 2025 (and 2022 CU 20). With a cgroup v2 CPU limit, the engine keeps
  reporting the host's CPUs: align it with `ALTER SERVER CONFIGURATION SET PROCESS AFFINITY` and
  *trace flag* 8002 so that parallelism decisions are not taken on a false count.
- Features that depend on the **Azure Arc** agent (Entra ID, Purview, pay-as-you-go,
  Defender) **are not supported in containers**.
- On Kubernetes, `kubernetes-standards` rules for the rest; container HA via a *statefulset*
  and restart **is not an AG**: it is a restart, with its own RTO.

## 7. Performance

### 7.1 Method: wait statistics and Query Store

- **Diagnose by waits**, not by hunches: `sys.dm_os_wait_stats` (cumulative since
  startup — **measure by delta between two instants**, never the raw cumulative),
  `sys.dm_exec_requests`/`sys.dm_exec_session_wait_stats` for what is happening now, and
  `sp_WhoIsActive` as the first-line tool. Ignore the benign background waits before
  drawing conclusions.
- **Query Store is the tool that changed diagnosis** and it is in **every edition**
  (enabled by default on new databases from 2022): it stores queries, plans and execution
  statistics **with history**, so that "yesterday it was fine and today it is not" goes from anecdote to evidence.
  Criteria: **enabled on every production database**, with the capture mode and retention sized
  (`AUTO` in general), and **watching that it does not fill up** —if the store goes `READ_ONLY` it stops
  capturing silently—. `sp_QuickieStore` to query it without writing SQL by hand.
- **Plan regression**: identify with Query Store the query with several plans and force the good one
  (`sys.sp_query_store_force_plan`) as a **temporary containment measure**, with a review date and the
  cause investigated afterwards. A forced plan nobody reviews is debt: the engine may stop
  being able to apply it and nobody finds out. On Enterprise there is *automatic tuning* to fix
  regressions automatically — **with supervision**, not as an autopilot.
- **Statistics**: `AUTO_CREATE_STATISTICS` and `AUTO_UPDATE_STATISTICS` enabled; manual
  updates after bulk loads and on large tables where the automatic threshold arrives late.
  `AUTO_UPDATE_STATISTICS_ASYNC` with judgement. The number 1 cause of a bad plan is an old
  statistic, not the optimiser.
- **Parameter sniffing**: a classic symptom (the same procedure, erratic performance). It is attacked
  in this order: statistics → rewriting the query → targeted `OPTIMIZE FOR`/`RECOMPILE` →
  *Query Store hints* (preferable to touching the code) → separating code paths.
  A global `WITH RECOMPILE` is an expensive sticking plaster.

### 7.2 Indexes

- **One *clustered* index per table, almost always**: the table *is* the clustered index.
  A **narrow, increasing, unique and immutable** key (an `int/bigint identity` or a `sequence`);
  **a random GUID as the clustered key** fragments and widens every nonclustered index
  (which includes it as a pointer) — vetoed unless justified by measurement. A *heap* (a table without a clustered
  index) is the exception, not the default.
- **Nonclustered**: by real query pattern, with `INCLUDE` to achieve measured **coverage**, and
  **filtered** for hot subsets. Every index is justified with a plan; every index
  costs on every `INSERT`/`UPDATE`/`DELETE` and on every backup.
- **Retirement**: `sys.dm_db_index_usage_stats` to detect indexes with no reads and with writes.
  Before dropping, **disable** and observe. Careful: usage statistics reset with the
  instance — do not decide on a short window.
- **Missing indexes**: the *missing indexes* DMVs are a **hint**, not an order. Applying their
  suggestions wholesale is one of the worst frequent practices: they overlap, duplicate and fatten
  the table. Consolidate by hand (`sp_BlitzIndex` helps).
- **Fragmentation and the myth of routine maintenance**: reorganising or rebuilding indexes every
  night **out of habit** is, on modern storage (SSD/NVMe/array with cache), almost always
  useless work that generates **tonnes of log** (and therefore huge log backups, AG traffic
  and I/O pressure) for a marginal improvement. Criteria:
  - What almost always matters is **updating the statistics**, not defragmentation.
  - Rebuild with high thresholds and only on large and genuinely fragmented indexes;
    **`ONLINE = ON` is Enterprise** — on Standard, a rebuild **blocks**: schedule it in a
    window or do not do it.
  - Watch the global `FILLFACTOR`: lowering it "to reduce fragmentation" wastes memory and I/O
    on every read.

### 7.3 Blocking, isolation and **why RCSI is usually the answer**

- SQL Server's default is `READ COMMITTED` **with locks**: readers block writers
  and vice versa. That is where most of the blocking attributed to "the database is slow" comes from, and where
  the `WITH (NOLOCK)` antipattern comes from, which **is not an optimisation: it is reading dirty data**, with
  duplicated or missing reads and, in real cases, error 601. **Forbidden as a general practice.**
- **`READ_COMMITTED_SNAPSHOT ON` (RCSI)** changes the database's default level to row
  versioning: **readers stop blocking writers** without changing a line of application
  code. It is, in practice, the right answer for the vast majority of OLTP workloads —
  the behaviour anyone coming from PostgreSQL or Oracle is already used to. **Its cost,
  declared**: row versioning in `tempdb` (size it), 14 extra bytes per versioned row,
  and a real semantic change —certain locks that today serialise accidentally disappear,
  so there is application logic that relied on them without knowing. Hence: **it is enabled with
  testing**, not hot on a Friday, and it requires momentary exclusive access to the database.
- `ALLOW_SNAPSHOT_ISOLATION` (explicit *snapshot* isolation) is different: a transaction with a fully
  consistent view and **update conflicts** the application must retry. It is used
  where it is needed, not by default.
- ***Deadlocks***: they are **captured**, not guessed — the `system_health` extended events
  session records them by default; read the **deadlock graph** to know which
  resources and in what order. Solution in order of preference: **consistent access order** →
  indexes that reduce the scope of the lock → shorter transactions → isolation level →
  **retry with backoff in the application** (always, as a net: a deadlock is a recoverable
  error, not a failure of the user's request).
- **Short transactions with no external interaction inside**: no HTTP calls and no waiting for
  a user with an open transaction. Set `LOCK_TIMEOUT` and command timeouts in the application.
- **`Optimized locking`** (2022+, and in Standard in 2025) reduces escalation and the number of locks:
  evaluate it, with the same before/after measurement discipline.

### 7.4 T-SQL: antipatterns that kill plans

- **Non-*SARGable* predicates**: a function on the column (`WHERE YEAR(date)=2026`,
  `WHERE UPPER(col)=…`), a computation on the column, `LIKE '%something'`. Rewrite to ranges.
- **Implicit type conversion** (`nvarchar` against `varchar`, text against number): it invalidates the
  index silently. It is the most expensive and easiest-to-fix performance bug.
- **User-defined scalar functions** in `SELECT`/`WHERE`: historically row-by-row
  execution. *Scalar UDF inlining* exists (all editions), but it does not cover every case:
  prefer inline table-valued functions (`iTVF`) or expressions.
- **Cursors and `WHILE` loops** where a set-based operation would fit.
- **`SELECT *`** in interfaces and views; **views nested on views** (the optimiser ends up
  with plans impossible to reason about).
- **`sp_executesql` with concatenated literals**: massive recompilation **and SQL injection**.
  Parameters always. It is a security veto as well as a performance one.
- `MERGE`: use with caution (a long history of bugs and blocking). Explicit `INSERT`/`UPDATE`
  with logical `ON CONFLICT` handling is usually more predictable.
- **Triggers** with non-obvious side effects and without set handling (`inserted`/`deleted`
  have **several rows**): a chronic source of logical corruption.
- Treat `NULL`, `ANSI_NULLS` and `SET` options consciously: they change plans and affect filtered
  and indexed indexes.

## 8. Maintenance: what every instance needs

Four jobs, not one fewer, all with an **alert when they fail** (a maintenance job that
fails silently is worse than not having it):

1. **Integrity**: `DBCC CHECKDB` with `DATA_PURITY`, at a weekly cadence at minimum on databases that
   matter. **It is the only control that detects corruption**; without it, corruption is discovered the
   day you restore. On Enterprise there is parallel checking; on large databases, split by
   tables/filegroups or run it on a restored copy —which, incidentally, **tests the
   restore**: two controls for the price of one.
2. **Statistics** (priority) and **indexes** (with high thresholds, §7.2).
3. **Backups** full/differential/log according to the recovery model (§4).
4. **History purge**: `msdb` (backup and job history), Query Store, extended event
   sessions, old backup files. An unpurged `msdb` degrades the Agent itself.

**Reference community solutions — status verified in August 2026**:
- **Ola Hallengren, *SQL Server Maintenance Solution*** (`MaintenanceSolution.sql`,
  `DatabaseBackup`, `DatabaseIntegrityCheck`, `IndexOptimize`): **alive and updated**, with declared support
  for SQL Server 2017, 2019, 2022 and **2025** plus Azure SQL MI. **It is the default**: you do not
  write your own backup and maintenance scripts unless there is a documented reason. It is distributed by
  dated versions, not by semver: download the latest from `ola.hallengren.com`.
- **dbatools** (PowerShell, >500 commands): **alive** — 2.8.2 published on the PowerShell Gallery in
  May 2026, with continuous activity in `dataplat/dbatools`. It is the right way to automate
  (`Install-DbaMaintenanceSolution`, migrations, inventory) rather than GUIs and hand-written scripts.
- **First Responder Kit** (`sp_Blitz`, `sp_BlitzIndex`, `sp_BlitzCache`, `sp_BlitzFirst`): **alive**,
  with the *"The First Responder Kit 2026"* release (2026-07-08) and an annual versioning model. Real warnings
  from the author himself: since April 2026 **it only supports SQL Server 2016 SP2 and later**,
  `sp_Blitz` **requires `sp_ineachdb`**, several scripts were deprecated (`sp_BlitzQueryStore` →
  `sp_QuickieStore`), and there was a release marked by the author as unreliable for containing a lot of
  AI-edited code. **Test before deploying**, especially with case-sensitive collation.
- **`sp_WhoIsActive`** (Adam Machanic) for live diagnosis.
- Cross-cutting rule: **any third-party script installed on a production instance is
  reviewed line by line** — it runs with high privileges inside the engine.

## 9. Security

- **Authentication**: **integrated mode (Windows/Kerberos) by default**; SQL authentication only
  when there is no alternative (Linux, containers, third parties), with passwords from the secrets
  manager. **Everything relating to Kerberos, SPN, delegation, managed service accounts
  (gMSA/dMSA), GPO and Tier 0 is delegated entirely to `windows-server-ad-standards`** — here only
  what the engine requires is declared: a dedicated service account with no domain privileges, a **correct
  SPN** (without it the connection silently falls back to NTLM and Kerberos and delegation are lost),
  and no domain administrative account running the service.
- **`sa`**: disabled and renamed; **never** as an application account. No application login
  in `sysadmin` or in `db_owner`: minimum permissions per schema, ideally via
  procedures or defined database roles.
- **Roles**: use server and database roles (including user-defined server roles) instead of granting to
  individual principals. Periodically review `sysadmin`,
  `securityadmin`, `CONTROL SERVER` and `db_owner` membership — it is the access review that
  nobody does until the audit.
- **Surface**: `xp_cmdshell` **disabled** (and absent on Linux); *CLR* disabled unless
  needed and never `UNSAFE`; *Ad Hoc Distributed Queries* disabled; **SQL Browser** off
  where it is not needed; **port 1433 never exposed to the Internet or to the user network**
  (`firewall-policy-standards`), and **encryption in transit mandatory** (`Encrypt=True` with
  certificate validation in the connection string — a `TrustServerCertificate=True` in
  production voids the protection).
- **Linked servers**: permanent trust bridges. Inventoried, with the least-privileged
  account and reviewed; never mapping to an administrative account.
- **Encryption at rest**: **TDE is available in Standard and Enterprise** (not in Express) — the myth
  that "TDE is Enterprise only" is out of date and has justified unnecessary purchases. TDE protects
  files and backups **at rest**, not from a user with permissions. **The certificate/DEK is backed up
  and held outside the server**: losing it is losing the data (§4). For column-level sensitive
  data, **Always Encrypted** (also in Standard, even with secure enclaves on Windows),
  with the key outside the engine — it is the only protection against the DBA themselves. Keys and their
  lifecycle, in `cryptography-pki-standards`/`secrets-management-standards`.
- **Auditing**: *SQL Server Audit* (server and database auditing, available in all
  editions in 2025) over what matters —permission changes, access to classified data,
  use of privileged accounts—, with output to the SIEM. Do not audit everything: nobody reads it and it costs.
- **Patching**: SQL Server is served through **Cumulative Updates** (since 2017 there are no Service Packs).
  Apply CUs on a cadence, in a window, with a planned rollback; security bulletins arrive
  through Patch Tuesday. In 2026 significant engine vulnerabilities have been published —among them
  critical deserialisation RCEs reaching from SQL Server 2016 SP3 through 2025, and elevation
  of privilege to `sysadmin`— which reinforces two things: **patch** and **do not grant privileges that
  turn an elevation into a disaster**. Triage and the window are set by
  `vulnerability-management-standards`.

## 10. Versions and support — verified in a primary source

Data taken from the lifecycle pages on learn.microsoft.com (August 2026). **It is the data
that ages fastest: always re-verify.**

| Version | Start | End of *mainstream* support | End of extended support |
|---|---|---|---|
| SQL Server 2016 | 2016-06-01 | 2021-07-13 | **2026-07-14 — already expired** |
| SQL Server 2017 | 2017-09-29 | 2022-10-11 | **2027-10-12** |
| SQL Server 2019 | 2019-11-04 | 2025-02-28 | **2030-01-08** |
| SQL Server 2022 | 2022-11-16 | **2028-01-11** | 2033-01-11 |
| **SQL Server 2025** (17.x) | **2025-11-18** | **2031-01-06** | **2036-01-06** |

Mandatory readings of that table:
- **SQL Server 2016 has been out of support since 14 July 2026.** There are paid **Extended
  Security Updates**: Year 1 (2026-07-15 → 2027-07-13), Year 2 (2027-07-14 → 2028-07-18),
  Year 3 (2028-07-19 → 2029-07-17). A 2016 without ESU in production is an explicitly accepted
  risk or a breach — there is no third option. A coincidence that illustrates the point:
  the same month as its end of support, a critical RCE affecting it was published.
- **2017 has little more than a year of life left** (October 2027): any plan reaching 2027 must include it.
- **2019 has been out of mainstream support since February 2025**: it receives security fixes until 2030, but
  **no functional fixes**. It is not the destination of a new migration.
- Recommended destination today: **2022 or 2025**, depending on CU maturity and application compatibility.

**Upgrading**: `compatibility level` is a lever **independent** of the version — it is raised
**after** the upgrade, with Query Store enabled to capture the baseline and be able to revert a regressed
plan. It is the safety net that turns a risky upgrade into a reversible one.

## 11. Quality and gates

Gates that block go-live, in increasing order of cost:

1. **Edition and licence gate (the first one)**: every design declares the target edition and which
   exclusive feature it uses. A design that uses full AGs, online indexing or *automatic
   tuning* on Standard **does not pass**. Every non-passive replica and every additional VM is declared to
   the licence manager (§2.4).
2. **Base configuration verified** as code: `max server memory`, `MAXDOP`,
   `cost threshold for parallelism`, symmetric `tempdb` files, fixed autogrowth, a recovery
   model consistent with the scheduled backups, RCSI consciously decided,
   Query Store enabled. Checkable with `dbatools` in CI/inventory.
3. **Schema migrations versioned** in a repository and applied only by pipeline (a
   `data-platform-standards` criterion); manual DDL in production **forbidden**.
4. **T-SQL review** against the antipatterns of §7.4; parameterised queries mandatory.
5. **Testing with a representative volume** and comparing plans before/after; validate
   N-1 compatibility during rolling deployments.
6. **`DBCC CHECKDB` green** as a health condition of the instance; its failure is an incident.
7. **Test restore passed** within the agreed cadence (§4).
8. **Failover rehearsed** (AG or FCI) with the application inside (§5).
9. **CU applied** within `vulnerability-management-standards`'s window.

## 12. Operability and SLIs

- **Minimum SLIs with an actionable alert and a runbook** (the platform belongs to `observability-standards`):
  - Availability of the instance **and of the database** (a `SUSPECT` or `RECOVERY_PENDING` database with the
    service up is not detected by a port check).
  - Space: data, the **transaction log** with `log_reuse_wait_desc`, `tempdb`, and the backup
    disk.
  - Backups: success and duration of the full/differential/log, **the age of the last log backup**
    (it is the real RPO), and **the age of the last validated restore** as a first-class SLI.
  - AG: synchronisation state, **send/redo queue** and *redo lag* per replica, listener state,
    WSFC health (or that of the Pacemaker resource on Linux).
  - Performance: dominant waits by delta, blocking (blocked sessions and duration), deadlocks
    per hour, page life expectancy, CPU and `tempdb` usage.
  - Maintenance: last successful run of `CHECKDB`, of statistics and of the purge.
  - Errors: the engine error log filtered by severity (≥16, and I/O **823/824/825** — the
    825 is the early warning of a disk starting to fail and almost nobody watches it).
- **Capacity**: data and log growth, IOPS and log write latency, connections,
  projected with data and reviewed quarterly. Adding cores is **a purchase** (§2.3):
  sizing is also FinOps.
- **Configuration as code**: instance parameters, Agent jobs, alerts, extended
  event sessions and logins, versioned and with *drift* detection (`iac-standards`,
  `dbatools`). Zero manual changes in production.

## 13. Sustainability and prohibitions

- **Half-yearly review**: version and support dates, CUs applied, edition vs functionality
  actually used, replicas and VMs against licences, dead indexes, jobs failing silently,
  databases with no owner.
- **Mandatory ADR** for: edition and licensing model, HA topology (AG vs FCI vs none),
  recovery model per database, enabling RCSI, contracting Software Assurance as
  a requirement of the HA architecture, and adoption of managed cloud services.
- Retiring is part of the job: instances and databases nobody uses still cost licence, backup and
  attack surface.

### List of prohibitions

- ❌ **Designing on Enterprise functionality without confirming the edition** (full AGs, readable
  replica, online indexing, page restore, advanced IQP).
- ❌ **Assuming the passive replica is free**: without Software Assurance, it is licensed (§2.4). And a
  readable secondary **is not passive**.
- ❌ Pinning **prices, edition limits or memory licensing rights**. If it is not verified
  against Microsoft's documentation or the contract: a declared gap and a query to the licence
  manager.
- ❌ **Developer or Evaluation edition in production.**
- ❌ Production on **SQL Server 2016 without ESU** (out of support since 2026-07-14) or on
  any expired version without a risk accepted in writing.
- ❌ A database in **FULL with no scheduled log backups**; `DBCC SHRINKFILE` of the log as a routine; switching to
  SIMPLE to "clean" the log.
- ❌ An ad-hoc backup **without `COPY_ONLY`** (it breaks the differential chain) or with another tool that
  interferes with the log chain.
- ❌ Accepting a backup as good on the basis of `RESTORE VERIFYONLY`: **without a tested restore it does not exist**.
- ❌ A TDE or backup encryption certificate held on the same server or in the same
  repository it backs up.
- ❌ **`WITH (NOLOCK)` as a general practice** (dirty, duplicated or missing reads). If the
  problem is blocking, the answer is **RCSI**, indexes and short transactions.
- ❌ **A single `tempdb` file** on a multi-core server, or files of unequal sizes.
- ❌ `max server memory` at the default, `MAXDOP` unset, `cost threshold for parallelism` at 5.
- ❌ Autogrowth as a percentage, or files growing while hot as a capacity strategy.
- ❌ Applying the missing-index suggestions from the DMVs wholesale.
- ❌ Rebuilding every index every night out of routine (log, I/O and AG traffic in exchange for nothing),
  and rebuilding without `ONLINE` on Standard outside a window.
- ❌ An instance without periodic `DBCC CHECKDB`.
- ❌ Concatenated dynamic SQL (`EXEC`/`sp_executesql` with literals): performance **and** injection.
- ❌ `xp_cmdshell` enabled, `UNSAFE` CLR, `sa` active or an application account in `sysadmin`.
- ❌ Port 1433 reachable from the Internet or from the user network; `TrustServerCertificate=True`
  in production.
- ❌ *Database mirroring* in a new design (deprecated).
- ❌ Presenting `CLUSTER_TYPE = NONE` as high availability (manual failover only).
- ❌ Attempting an AG or FCI spanning WSFC and Pacemaker.
- ❌ Duplicating Active Directory criteria here: **that belongs to `windows-server-ad-standards`**.
- ❌ Installing third-party scripts in production without reviewing them line by line.
- ❌ A SQL Server container with no persistent volume, or with the `sa` password in the manifest.

## 14. Mandatory web verification

Before committing any fact from this document to a deliverable:

1. **Support dates**: `learn.microsoft.com/lifecycle/products/sql-server-<year>` for each
   live version, and the status of the **SQL Server 2016 ESUs**.
2. **Limits and features by edition**: *Editions and supported features* **of the exact
   version** (the limits changed in 2025: 32 cores and 256 GB in Standard). Check whether anything else
   has moved from Enterprise to Standard since then.
3. **Licensing**: the SQL Server licensing guide and the current **Product Terms** —
   per-core model vs Server+CAL, virtualisation and **failover rights with
   Software Assurance**. Any decision with a cost goes to the licence manager.
4. **Current version and CU** (`Latest updates and version history for SQL Server`) and **CVEs from the last
   quarter**; triage according to `vulnerability-management-standards`.
5. **SQL Server on Linux and in containers**: the list of unsupported features and the supported
   distributions (**SLES stopped being one in 2025**); the status of the Pacemaker HA agent
   (`mssql-server-ha`).
6. **Community tools**: latest version and activity of **Ola Hallengren's
   `MaintenanceSolution.sql`**, **dbatools** and the **First Responder Kit** —including its minimum
   supported SQL Server version— before installing them.

### Declared gaps and discrepancies (August 2026)

- **Prices**: **none** in this document, deliberately. There is no verified figure and **none is
  approximated**.
- **The exact wording of the failover rights with Software Assurance**: described here in general
  terms from licensing sources; **not verified against the original Product
  Terms**. Before deciding on passive replicas, read them.
- **The break-even threshold for Server+CAL vs per core**: it depends on the agreement. **No number is fixed.**
- **A discrepancy in Microsoft's own documentation**, detected in this verification and **not
  resolved**:
  - *Maximum relational database size in Express*: the **Windows** editions page says
    **50 GB**; the **Linux** one for the same version says **10 GB**. Verify against the page for the
    specific platform before sizing anything on Express.
  - *Synchronous secondary replicas in Enterprise*: the **Windows** page indicates up to 8
    secondaries **including 5 synchronous**; the **Linux** one, up to 8 **including 2 synchronous**.
    Confirm for the target platform.
- **Cadence and content of the SQL Server 2025 CUs** after CU 3: not verified in
  detail.

If the web contradicts this document, **the web wins** — flag the discrepancy.
