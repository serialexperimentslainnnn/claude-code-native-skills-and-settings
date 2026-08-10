---
name: oracle-dba-standards
description: Use when operating Oracle Database — sqlplus, RMAN, dgmgrl and Data Guard, srvctl/crsctl/asmcmd and ASM disk groups, lsnrctl with listener.ora/tnsnames.ora/sqlnet.ora, CDB/PDB multitenant and MAX_PDBS, Real Application Clusters, AWR/ASH/ADDM and awrrpt.sql, v$session/v$active_session_history wait events, SQL plan baselines and DBMS_SPM, DBMS_STATS, Flashback Database, unified auditing, TDE wallets and Advanced Security, DBA_FEATURE_USAGE_STATISTICS and CONTROL_MANAGEMENT_PACK_ACCESS as audit exposure, processor core factor and Named User Plus metrics, Standard Edition 2 socket and thread caps, Oracle AI Database 26ai / 23ai / 19c upgrades and Release Updates, quarterly Critical Patch Updates, or ora2pg / orafce / oracle_fdw migration off Oracle to PostgreSQL.
---

# Oracle Database administration standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Thesis of the document**: in Oracle, **the licence is the first architecture decision, not a
> footnote**. Almost no other platform has the property that *running a query*
> —a `SELECT` over a performance view— creates a retroactive financial debt. Here it does.
> Everything that follows is ordered by that asymmetry: first what you can afford to use, then
> how to use it well.
>
> **Second thesis, an uncomfortable one**: most of the Oracle installations found in production are
> **oversized and over-licensed** — Enterprise Edition with expensive options bought and
> unused, or worse, used without being bought. Honest work starts by measuring what is really used.

## 1. Scope and triggers

Applies to designing, licensing, operating, diagnosing and **exiting** Oracle Database: the licensing
model and its impact on design, multitenant architecture and instance/storage,
RAC, Data Guard, backup with RMAN and Flashback, performance diagnosis by the wait model,
PL/SQL with judgement, upgrades and quarterly patching, engine and *listener* security,
and the migration-to-PostgreSQL conversation.

Triggers: `sqlplus`, `rman`, `dgmgrl`, `srvctl`, `crsctl`, `asmcmd`, `lsnrctl`, `adrci`,
`expdp`/`impdp`, `sqlldr`, `orapwd`, `dbca`, `AutoUpgrade`/`autoupgrade.jar`, `opatch`/`opatchauto`,
`listener.ora`, `tnsnames.ora`, `sqlnet.ora`, `init.ora`/`spfile`, `ORACLE_HOME`, `ORACLE_SID`,
`CDB`/`PDB`, `PDB$SEED`, `MAX_PDBS`, `ALTER PLUGGABLE DATABASE`, `ASM`, `+DATA`/`+FRA`,
`TABLESPACE`, `AWR`, `ASH`, `ADDM`, `awrrpt.sql`, `v$session`, `v$session_wait`,
`v$active_session_history`, `v$sql`, `DBMS_XPLAN`, `DBMS_SPM`, `DBMS_STATS`,
`CONTROL_MANAGEMENT_PACK_ACCESS`, `DBA_FEATURE_USAGE_STATISTICS`, `FLASHBACK DATABASE`,
`ORA-01555`, `ORA-00060`, `ORA-04031`, "core factor", "Named User Plus", "Standard Edition 2",
"Critical Patch Update", "Release Update", `ora2pg`, `orafce`, `oracle_fdw`.

**Not applicable**: see
- `data-platform-standards` (**the parent skill**: PostgreSQL as the default, relational modelling,
  expand/contract migrations, data classification and retention, backup principles. Its
  guiding principle —*one store per need, not per fashion*— still rules: **this skill does not
  justify choosing Oracle**, it covers operating it well when it is already there by historical
  decision, by a third-party product requirement or by a live contract).
- `sqlserver-dba-standards` (the catalogue's other proprietary engine; different engines and
  vendors, the same pattern: **licensing decides the architecture**. They do not compete).
- `backup-recovery-standards` and `bcdr-standards` — **a critical boundary, an arbitration rule
  mirrored word for word from `backup-recovery-standards` §1**:
  > **"how is the copy made?" belongs to `backup-recovery`** (tool, repository, 3-2-1, GFS,
  > dedup, repo encryption, integrity, catalogue, restore procedure); **"how much can we
  > lose, in what order do we bring things up and who decides?" belongs to `bcdr`**.
- `plsql-oracle-forms-standards`: **PL/SQL as a program language** —packages,
  `BULK COLLECT`/`FORALL`, exception handling, dynamic SQL and its *binds*, `AUTHID`, utPLSQL— and
  **Oracle Forms/Reports as an application layer** are theirs; **here the engine**: parameters,
  optimiser and statistics, RMAN and Data Guard, licensing and the exit path towards
  PostgreSQL. Two warnings both skills uphold: **Oracle Forms is NOT unsupported** —what presses
  is the calendar of the 12.2.x branch—, and **Reports IS deprecated** even though it is still packaged.
- `sql-standards` (**the SQL language**; an arbitration rule mirrored from its §1: *if the question
  changes how the query or the DDL is written, it belongs to `sql-standards`; if it changes which
  engine is chosen, how it is sized, backed up, replicated or restored, it belongs here*). Theirs are
  the dialect peculiarities that **change the code** —`MERGE`, `CONNECT BY` versus `WITH
  RECURSIVE`, the historical `DUAL`, the equivalence between an empty string and `NULL`, `ROWNUM`
  versus `FETCH FIRST`— and the criteria for PL/SQL as a **language**. Ours is everything that decides
  execution: optimiser, statistics, *hints*, pinned plans, AWR/ASH, partitioning and
  the licensing of the options a SQL construct may activate unintentionally
  (**always check whether the clause you write bills**).

  This document's own extension: **what is engine-specific belongs here** — RMAN (incremental
  strategy, `VALIDATE`, recovery catalogue, FRA), Flashback, PITR with `SCN`/`RESETLOGS`
  and Data Guard as a mechanism. **The repository where those pieces land, its immutability and
  the cadence of the test restore belong to `backup-recovery`**; **the RPO/RTO that justifies the
  Data Guard protection mode and the switchover exercise as part of the plan belong to `bcdr`**.
- `ha-clustering-standards` (**Pacemaker/Corosync, quorum and generic fencing are theirs**; here
  Oracle Clusterware/Grid Infrastructure and RAC, which bring their own quorum and their own fencing
  —*node eviction* by voting disk and network heartbeat— and **are not mixed with Pacemaker**).
- `linux-storage-standards` and `zfs-standards` (multipath, LUNs, alignment, the filesystem beneath
  ASM), `onprem-standards` (the iron, power, capacity), `linux-hardening-standards`
  (hardening the OS that hosts `ORACLE_HOME`), `selinux-standards`.
- `proxmox-ve-standards` and `libvirt-kvm-standards` (**relevant here because of licensing**: Oracle's
  partitioning policy turns a hypervisor decision into a cost decision — §2.4).
- `vulnerability-management-standards` (**the CVE cycle, triage and patching window are theirs**;
  here only Oracle's calendar and mechanics: RU/CPU/CSPU, `opatch`).
- `cryptography-pki-standards` (algorithms, TLS and the key lifecycle that TDE and the *wallet*
  rely on), `secrets-management-standards` (where the wallet's and the service users'
  passwords live), `identity-access-management-standards` (corporate identity),
  `grc-compliance-standards` and `privacy-engineering-standards` (regulatory framework and personal data).
- `aws-standards`/`azure-standards`/`gcp-standards` (RDS for Oracle, OCI, *Authorized Cloud
  Environments*: the managed services and their billing; **the BYOL licensing criteria belong
  here**).
- `streaming-cdc-standards` (**the capture is theirs**: LogMiner, GoldenGate, Debezium; **the impact
  on the engine belongs here**: `supplemental logging`, redo retention, cost in the LGWR).
- `jvm-spring-standards`/`python-standards`/`dotnet-standards` (driver, pool and ORM from the code),
  `observability-standards` (the metrics and alerting platform where these SLIs land).
- `mysql-mariadb-dba-standards` (the catalogue's third relational engine; open source, without the
  licensing variable that dominates here), `timeseries-db-standards`, `message-brokers-standards`,
  `nosql-standards`, `search-engines-standards`, `caching-cdn-standards` (other specialised
  stores).

## 2. Licensing: the dominant decision

> **Scope warning, non-negotiable**: this document sets **technical criteria**, not contractual
> advice. Any decision with financial impact is validated against the **Licensing Information
> User Manual of the specific version**, the signed *ordering document* and the organisation's
> **licence manager** (or an independent adviser). The data below is verified as of
> August 2026 and **expires without notice**: Oracle republishes its tables without notification (§8).

### 2.1 Current editions

| Edition | Status August 2026 | Hard limit |
|---|---|---|
| **Enterprise Edition (EE)** | The only edition with on-prem GA of **Oracle AI Database 26ai** (Linux x86-64, announced 27 Jan 2026) | No socket limit; all options **charged separately** |
| **Standard Edition 2 (SE2)** | Current in 19c; for 26ai **only available on Oracle Database Appliance** at the time of this verification (§8, gap) | **Max. 2 occupied sockets** per server and an **internal cap of 16 CPU threads**; no EE options |
| **Free** (successor to Express Edition/XE) | Current (`Oracle AI Database 26ai Free`) | **2 CPUs, 2 GB of RAM, 12 GB of user data**; **no support and no patches, not even security ones** |
| **21c** | *Innovation Release*: not LTS and **not eligible for Extended Support** | Do not use as the target of a migration |

Design consequences, not procurement ones:
- **SE2 is not "cheap Oracle": it is a different product.** No partitioning, no advanced compression, no
  TDE, no Active Data Guard, no diagnostic packs. A design that assumes any of those
  pieces and lands on SE2 does not work; one that uses them on EE without licensing them is audit debt.
- **SE2's 16-thread cap is the engine's, not the contract's**: adding hardware does not give capacity to
  a single SE2 database. Size accordingly, do not discover it in production.
- **Free does not go to production.** Zero security patches is incompatible with
  `vulnerability-management-standards`. It serves for development, CI and migration testing.

### 2.2 Licence metrics

- **Processor**: `physical cores × core factor`, rounding **up**. The x86 (Intel/AMD) *core factor*
  is **0.5** (verify in the current *Processor Core Factor Table*: Oracle republishes it
  without notice, and **the one that applies is the one of the day the ordering document was signed** —
  archive the dated PDF alongside the contract). *Hyperthreading* does not count: **physical
  cores** are counted.
- **Named User Plus (NUP)**: it counts **people and devices**, with minimums per processor —
  **25 NUP per processor in EE**, **10 per server in SE2**. The core factor **does not reduce NUP**:
  it only sets the number of processors on which the minimum is calculated. NUP only pays off
  with a small, closed and **demonstrable** user population; a public web application is
  Processor by definition.
- **In *Authorized Cloud Environments* the core factor table does not apply**: counting is by vCPU
  under Oracle's cloud policy. **Do not carry the 0.5 into a cloud business case.**
- The licence of an **option** must use the **same metric and the same count** as the database
  that runs it. There is no such thing as "licensing the pack only on the instance that uses it on a Tuesday".

### 2.3 What is licensed separately (and the audit trap)

Verified against the *Licensing Information User Manual* of **Oracle AI Database 26ai**
(docs.oracle.com, availability-by-edition tables). In EE, the notes column says
literally **"Extra cost option"** for:

| Component | Manual note (26ai) | Real risk |
|---|---|---|
| **Partitioning** | EE: *extra cost option* | It is activated by creating **one** partitioned table. A developer can bill it without knowing |
| **Advanced Compression** | EE: *extra cost option* | `COMPRESS FOR OLTP`, advanced RMAN compression, compressed Data Pump |
| **Advanced Security** (column and tablespace TDE) | EE: *requires the Oracle Advanced Security option* | Encrypting at rest with TDE in EE **is a purchase**. Plan it before promising it in a design |
| **Diagnostics Pack** (AWR, ASH, ADDM) | EE: *extra cost option* | **The classic trap** — see below |
| **Tuning Pack** (SQL Tuning Advisor, SQL Access Advisor, Real-Time SQL Monitoring) | EE: *extra cost option, also requires Oracle Diagnostics Pack* | It is never bought alone: it drags in Diagnostics |
| **Real Application Clusters** | EE: *extra cost option* | See §4 |
| **Active Data Guard** | EE: *extra cost option; license included with Oracle GoldenGate* | **Basic** Data Guard is in EE; opening the standby for reading is not |
| **Database In-Memory** | EE: *extra cost option* | `INMEMORY` on a table is the activation |
| **Multitenant** | 3 user PDBs with no licence; up to **252 PDBs** in EE with the option | See §3.1 |

**The classic trap, spelled out**: in Enterprise Edition the parameter
`CONTROL_MANAGEMENT_PACK_ACCESS` comes **by default as `DIAGNOSTIC+TUNING`**. Querying a
`DBA_HIST_*` view, running `awrrpt.sql`, looking at `v$active_session_history` or opening Enterprise
Manager's performance tab **uses the Diagnostics Pack** and generates retroactive audit
exposure, even if nobody signed anything. Operating rule:

- If there is **no** pack licence: `CONTROL_MANAGEMENT_PACK_ACCESS=NONE` **set in the spfile and
  verified in CI/inventory**, and diagnosis with Statspack or with the `V$` views that do not
  belong to the pack. Forbidden "just this once to debug".
- If there **is** one: documented, with the same metric and count as the database.
- **Mandatory periodic review** of `DBA_FEATURE_USAGE_STATISTICS` (and of the historical
  `DBA_FEATURE_USAGE_STATISTICS` per instance) as a preventive control, **not** as a reaction to
  an audit letter. It is the same inventory Oracle will use.

**Mandatory scepticism**: the usage review cuts both ways. If the inventory
shows that Partitioning, In-Memory or Active Data Guard are being paid for and **nobody uses them**, that is a
FinOps finding that gets reported just like a non-compliance — with the warning that
*uninstalling* an option does not always reduce the bill until support renewal.

### 2.4 Virtualisation and soft partitioning

Oracle classifies technologies into *hard partitioning*, *soft partitioning* and *Oracle Trusted
Partitions*. The sentence that decides the cost, as it appears consistently reproduced in the
licensing literature derived from the document **"Oracle Partitioning Policy"**
(`oracle.com/us/corporate/pricing/partitioning-070609.pdf`):

> "Unless explicitly stated elsewhere in this document, soft partitioning (including features/
> functionality of any technologies listed as examples above) is not permitted as a means to
> determine or limit the number of software licenses required for any given server"

**Declared gap (§8)**: oracle.com returned **HTTP 403** to the automated download of that PDF in
this verification. The quote above comes from concurring secondary sources and **must
be confirmed by opening the PDF by hand** before using it to decide anything. In addition, the document itself
is published with an informational-purposes label and **is not part of the licence contract**: what
binds is the signed *ordering document*, not the policy. That distinction is exactly the one
licensing advisers argue about — **a DBA does not resolve it, and this document does not resolve it**.

The technical criteria that are set here:
- **VMware, Hyper-V, KVM/Proxmox and containers are treated by default as soft partitioning**:
  budget for licensing **all the cores of the physical host** —and, in clusters with
  live migration, of all the hosts the VM can move to— until the licence manager says
  otherwise **in writing**.
- If Oracle must coexist with a general virtualised cluster, **isolate the iron**: a dedicated
  cluster, with no DRS and no migration to unlicensed hosts, and **evidence preserved** (logs,
  configuration, dated captures) of where the instance has run. That evidence is the audit
  defence; it is collected continuously, not when the letter arrives.
- Prefer **dedicated, small iron** to a large shared cluster: in Oracle, the
  consolidation that saves money everywhere else in the catalogue **multiplies** the bill.
- The "core factor does not apply in the cloud" clause (§2.2) turns a *lift-and-shift* to IaaS into an
  exercise in recalculation, not relocation.

### 2.5 Cloud

- **BYOL to third-party IaaS (AWS/Azure/GCP)**: it is still self-managed Oracle. The **options and
  packs are licensed the same**; the only thing that changes is the counting (vCPU, *Authorized Cloud
  Environments* policy).
- **Oracle managed services (OCI Base Database, Exadata Database Service, Autonomous)**:
  they include options according to the tier contracted — the licensing manual tabulates it by columns
  (`BaseDB EE-HP`, `BaseDB EE-EP`, `ExaDB`). There part of the audit risk does disappear, in
  exchange for coupling to the provider: **an ADR decision**.
- No price figure is set in this document. **Forbidden to quote prices from memory**: only
  Oracle's current price list at the time of the decision counts.

## 3. Architecture

### 3.1 Multitenant (CDB/PDB) is the model, not a design option

- **The non-CDB architecture is unsupported**: 19c was the last version that allowed it; 21c
  onwards —and therefore 23ai and 26ai— **exist only as CDB**. An upgrade plan from 19c
  non-CDB **includes the conversion to a PDB**, and the conversion **is irreversible** (not even Flashback
  Database undoes it): the rollback is "restore the previous copy", and the window has to be sized
  accordingly.
- **3 user PDBs per CDB without a Multitenant licence** (`PDB$SEED` does not count). The fourth is a
  purchase. Nothing technically prevents creating it in EE, so **`MAX_PDBS` is set as a safeguard**
  in every CDB without the option: it is a licence control implemented as a parameter.
- Grouping criterion: one CDB per **environment and shared patching cycle**, not for naming
  convenience. Everything that shares a CDB shares the maintenance window, the version and instance
  failure — the isolation a PDB gives is logical, not availability.
- Local *undo*, a clean `PDB$SEED` and cloning via *refreshable clone* to provision environments:
  it is the best piece of the model and the most underused.

### 3.2 Instance versus database

An operational distinction, not an academic one: the **instance** is memory (SGA/PGA) and processes; the
**database** is the files. RAC is *N* instances over **one** database; Data Guard is *N* different
databases. Almost every HA misunderstanding in Oracle comes from confusing the two:
**RAC protects against a node going down; it does not protect against a file being deleted or the site
being lost.** That is Data Guard and RMAN.

### 3.3 Tablespaces and organisation

- Separate by **lifecycle and policy**, not by whim: data, large indexes, temp, undo,
  and one tablespace per set with its own retention or encryption. `SYSTEM`/`SYSAUX` **never** host
  application objects.
- **Bigfile tablespaces** by default over ASM for application data (fewer files to
  manage); *smallfile* when restore granularity is needed.
- Local extent management and **ASSM**; no manual segment management in new designs.
- **Autoextend with an explicit `MAXSIZE`**: a datafile with no ceiling turns an application bug into a
  filled array.
- Table partitioning is a **design decision with a bill** (§2.3): if there is no licence, you
  design without it —views, range tables managed by the application, batch purging— and
  you document the limitation. **Forbidden** to partition "because it is the right thing" without verifying the licence.

### 3.4 ASM versus filesystem

- **ASM by default** in on-prem installations with shared or multiple block storage:
  *striping*, hot rebalancing, `ASMLib`/`AFD` or `udev` for name persistence, and it is the
  only reasonable path for RAC.
- **Redundancy**: `EXTERNAL` when the array already replicates and its reliability is proven;
  `NORMAL`/`HIGH` when ASM is the one protecting. Decide with `linux-storage-standards`, not by
  habit.
- Minimal, purposeful disk groups (`+DATA`, `+RECO`, `+GRID`); disks of the same size and
  performance within a group — the imbalance is paid in latency.
- **A filesystem (xfs/ext4 over LVM) is acceptable** on single instances, without RAC, over
  reliable storage: fewer pieces, less operation (KISS). ASM is not adopted "because it is Oracle".
- ZFS or *copy-on-write* storage under datafiles: see `zfs-standards`; mind
  `recordsize`/alignment with the `db_block_size` or performance collapses.

## 4. RAC: what it really solves

- **RAC solves availability against an instance or node going down, and it scales reads
  with effort. It does not give linear performance**: the global cache (*Cache Fusion*) has a cost, and a
  workload with shared hot blocks can be **slower** on RAC than on a single node. Any
  promise of "twice the nodes, twice the TPS" is false by default.
- **Cost**: a paid option (§2.3) **on every node**, Grid Infrastructure, shared
  storage, a dedicated and redundant interconnect, and a large jump in operational complexity —
  precisely what `ha-clustering-standards` warns about: *a badly operated cluster has worse
  availability than a well-monitored simple service*.
- **Simpler alternatives, in this order**, before proposing RAC:
  1. A well-sized single instance + **Data Guard with fast failover** (it covers node, site and
     corruption; RTO in minutes).
  2. A single instance on virtualisation with automatic restart on another host (RTO in minutes,
     cost close to zero).
  3. **Oracle Restart** (Grid Infrastructure on one node) to restart the instance and the listener.
  4. RAC **only** when the required RTO —derived by `bcdr-standards`, not invented— is in
     seconds and is budgeted.
- If there is RAC: services (`srvctl add service`) as the application's unit of connection, with
  preferences and *TAF*/*Application Continuity* configured; connection via **SCAN**, never via a node
  VIP in connection strings. Nodes identical in hardware and patching.
- **RAC's quorum and fencing belong to Oracle Clusterware** (voting disks, network heartbeat,
  *node eviction*): **it is not combined with Pacemaker/Corosync**. `ha-clustering-standards` describes the
  general discipline of fencing; its implementation here is Oracle's and only Oracle's.
- **Forbidden to justify RAC as a substitute for backup or DR.** A `DROP TABLE` replicates
  instantly to every node.

## 5. Data Guard and continuity

- **Physical (redo apply) by default**: a block-by-block copy, simple, covering all the content.
  **Logical (SQL apply)** only for specific cases (different versions, a subset of schemas, a rolling
  upgrade) and accepting its data type limitations.
- **Protection modes** — choose from the RPO derived by `bcdr-standards`:

| Mode | RPO | Cost |
|---|---|---|
| `MAX PERFORMANCE` (asynchronous) | > 0, varying with the lag | None on the primary |
| `MAX AVAILABILITY` (synchronous with degradation) | 0 while the standby responds | Commit latency; degrades to asynchronous on failure |
| `MAX PROTECTION` | Strictly 0 | **It stops the primary** if it cannot confirm. Only with ≥2 standbys and with that consequence accepted in writing |

- **Switchover ≠ failover**: a *switchover* is planned, reversible and lossless — it is the operation
  you rehearse. A *failover* is the reaction to losing the primary, potentially with data
  loss, and it **leaves the old primary out of the role** until it is reinstantiated (`FLASHBACK DATABASE`
  recovers it without a full copy if it was enabled: the main reason to have it active).
- **The Broker (`dgmgrl`) is mandatory** over manual parameter management: less human error
  surface, `VALIDATE DATABASE` as a prior check, and observability of the *apply lag* and
  *transport lag* — both are **first-class SLIs** with alerting.
- **The rehearsal is mandatory and scheduled**: a full *switchover* with the application
  reconnecting (not just the engine) at least at the cadence set by `bcdr-standards`. A Data Guard
  that has never switched over is an assumption, not a control.
- **Active Data Guard is a paid option** (§2.3). Without it, the standby **is not opened for reading**.
  A design that plans to "offload the reports to the replica" is buying, even if it does not know it.
  Snapshot Standby (opening the standby read-write for testing and then reverting it) is
  in EE, and it is the cheap way to test on real data — with the data classification
  respected (`privacy-engineering-standards`).

## 6. Backup: RMAN and Flashback

> **An invariant shared with `backup-recovery-standards` and `bcdr-standards`, with no nuance:**
> **a backup without a tested restore does not exist.** An `RMAN> backup` that finished green is not proof
> of anything.

- **RMAN is the mechanism**, not an option: block-consistent backups, corruption
  detection, and `RESTORE`/`RECOVER` guided by the catalogue. `expdp` dumps **are not a
  backup**: they are logical data movement, with no PITR and no instance recovery.
- **Default strategy**: a weekly level 0 + daily level 1 incrementals with **block change
  tracking** enabled (it drastically reduces the scan), continuous redo archiving, and an `FRA`
  sized with an explicit retention policy (`CONFIGURE RETENTION POLICY`). *Merge* incrementals
  (an updated image) when the RTO demands a fast restore and there is space.
- **A recovery catalogue** in a separate database when there is more than a handful of instances:
  the `controlfile` only retains limited metadata and **is lost with the site**. The catalogue is
  backed up too.
- **Verification as an engineering control**, not as trust:
  - `RESTORE ... VALIDATE` and `BACKUP VALIDATE CHECK LOGICAL` on a scheduled cadence.
  - **A real periodic restore to a different host**, timed, with `RECOVER` to an SCN and
    data validation by the application. The cadence and the record of the exercise are set by
    `backup-recovery-standards`; **the Oracle procedure belongs here**.
  - `V$DATABASE_BLOCK_CORRUPTION` watched; `DB_BLOCK_CHECKSUM`/`DB_BLOCK_CHECKING` active unless
    a measured cost advises otherwise.
- **Flashback is a different safety net, not a backup**: `FLASHBACK QUERY`/`FLASHBACK TABLE`
  (they depend on *undo* and its retention) and `FLASHBACK DATABASE` (it depends on the *flashback logs*) only
  cover recent logical errors within their window and **disappear with the primary
  storage**. They are enabled because they shorten the RTO of human error and because they are a practical
  requirement for reinstantiating after a failover — never as a substitute for the copy.
- **Recycle bin**: on by default, it is not a recovery control (a `PURGE` or space
  pressure empties it). Do not include it in a runbook as a safety net.
- The destination of the copies, their encryption, immutability and the 3-2-1 rule belong to `backup-recovery-standards`.
  A specific note: **encrypting RMAN backups by key/wallet depends on Advanced Security**
  in some modes — verify the licence before promising "backups encrypted by the engine";
  encrypting in the repository is the alternative with no bill.

## 7. Performance: the wait model

- **A method, not guesswork**: in Oracle you diagnose by **wait events** — where the session's
  time goes, not which counter looks high. The sequence is always: *session → time →
  dominant wait event → responsible SQL → plan → cause*. Any proposal to change a
  parameter that does not come from that chain is forbidden.
- **Tools and their bill** (§2.3): AWR, ASH and ADDM **are the Diagnostics Pack**. Without a licence:
  `V$SESSION` (with `event`, `blocking_session`, `sql_id`), `V$SESSION_WAIT`, `V$SYSTEM_EVENT`,
  `V$SQL`, `DBMS_XPLAN`, SQL trace (`10046`) + `tkprof`, and **Statspack** as the supported historical
  alternative. With a licence: ASH is the most cost-effective tool in the product — per-second
  sampling that answers "what was happening at 03:14" without reproducing the problem.
- **Wait classes and how to read them** (a triage guide, not a recipe): **user I/O** waits
  (`db file sequential read`) are usually the plan or an index, not a slow disk; **concurrency**
  (`buffer busy waits`, `enq: TX - row lock contention`) is data design or long transactions;
  **configuration** (`log file sync`) points at commits per operation or redo latency;
  high **CPU** with `library cache: mutex X` or huge *hard parse* figures points at the literals
  antipattern; in RAC, `gc *` waits are the cost of Cache Fusion.
- **Plans and their stability**:
  - Read the **real** plan (`DBMS_XPLAN.DISPLAY_CURSOR` with `ALLSTATS LAST`), not the estimated one.
  - **SQL Plan Baselines (`DBMS_SPM`)** as the default stability mechanism for critical
    SQL: a known good plan is accepted and the evolution of new plans goes through
    verification. *SQL Profiles* are a Tuning Pack product (**a bill**); baselines are not.
  - **Hints in application code: a last resort**, with a comment explaining why and a
    review date. A hint is debt that survives version and data changes.
- **Optimiser statistics**:
  - `DBMS_STATS` with the automatic task **active**; you intervene by hand when there is a bulk load,
    a volatile table or a misleading histogram, not as routine.
  - **Gather right after large loads** and before the application queries; for very volatile
    intermediate tables, consider locked statistics or deliberate *dynamic sampling*.
  - **Forbidden to delete statistics or disable gathering** as a "solution" to a bad plan: that
    does not fix the plan, it removes the information.
- **Classic antipatterns, vetoed**:
  - **SQL without bind variables** (concatenated literals): massive *hard parse*, library cache
    contention and, incidentally, SQL injection. It is the no. 1 performance failure in Oracle and the no. 1
    security one at the same time. `CURSOR_SHARING=FORCE` is an emergency **sticking plaster**, not a solution.
  - **Indexes nobody uses**: they cost on every DML. Periodic review with usage monitoring and
    withdrawal (invisible first, `DROP` afterwards) — the same hygiene the parent skill demands.
  - Functions over the column in the `WHERE` (they invalidate the index unless there is a function-based index),
    implicitly converted types (`VARCHAR2` vs `NUMBER`), and `SELECT *` in interfaces.
  - Row-by-row loops from the application (*row-by-row*, "slow-by-slow") where a set operation
    would have fitted.
  - Long transactions and insufficient `undo` → `ORA-01555`. It is fixed by shortening transactions,
    not by blindly raising `UNDO_RETENTION`.
- **Parameters**: changes one at a time, with before/after measurement, in a versioned `spfile` and with
  written justification. Hidden parameters (`_`) **only** with an Oracle Service Request backing
  them. `MEMORY_TARGET`/`SGA_TARGET` managed, `hugepages` configured on Linux for large
  SGAs (and `MEMORY_TARGET` is incompatible with hugepages: choose consciously).

## 8. PL/SQL with judgement

- **Yes**: logic that must sit next to the data for performance (bulk processing with `BULK
  COLLECT`/`FORALL`), integrity that cannot be entrusted to a client, package APIs that
  encapsulate table access, and scheduled jobs of the engine itself.
- **No**: complete business rules buried in packages — **it is business logic with no tests,
  no code review and no portability**, and it is the main anchor that turns "migrating off
  Oracle" into a multi-year project (§11). If it is written, it is written **as code**: in the
  repository, versioned, with versioned migrations (the same criteria as
  `data-platform-standards`), with `utPLSQL` or equivalent in CI, and compiled with
  `PLSQL_WARNINGS` treated as errors in the build.
- **Forbidden**: dynamic DDL and `EXECUTE IMMEDIATE` with concatenated input (use
  `DBMS_ASSERT` and bind variables); `AUTHID DEFINER` without thinking in packages that receive
  external input; triggers with non-obvious side effects (cascading triggers are the
  hardest-to-diagnose cause of incidents in the engine); `COMMIT` inside triggers
  (`PRAGMA AUTONOMOUS_TRANSACTION` only for auditing, with the loss of atomicity accepted).

## 9. Versions, patching and upgrades

State verified as of August 2026 (**re-verify in MOS Doc ID 742060.1**, which is the
authoritative source and **requires a support account** — this document has not been able to read it, §12):

| Version | Status | Dates (verify) |
|---|---|---|
| **Oracle AI Database 26ai** | The current release. On-prem GA for Linux x86-64 announced on **27 Jan 2026** (EE). RU numbering: **23.26.1** (Jan 2026), **23.26.2** (Apr 2026), **23.26.3** (Jul 2026) — confirmed on docs.oracle.com | Premier Support until **31 Dec 2031** (secondary source); Extended **TBD** |
| **23ai** | The same code line; for whoever was already on 23ai in OCI or on *engineered systems*, moving to 26ai is an RU | See 26ai |
| **19c** | The reference LTS of the installed estate | Premier until **31 Dec 2029**; Extended until **31 Dec 2032** |
| **21c** | *Innovation Release*, **no Extended Support** | Premier until **31 Jul 2027** (verify) |

**The 19c small print that changes decisions**: from **1 May 2027** onwards 19c support
**excludes** —according to the support policy and its *statement of changes*— BSAFE libraries, Java and
related products, **TLS**, **Native Network Encryption**, **Transparent Data Encryption**,
`DBMS_CRYPTO`, C and Java utilities, and **FIPS** compliance. Direct operational consequence:
**if the system depends on TDE, TCPS/TLS, native network encryption or FIPS validation, the real horizon
for 19c is May 2027, not 2029 or 2032.** Verify the exact scope in the primary source before
building a plan on it (§12).

**Patching** — the calendar changed in 2026 and it is the datum most often misstated from memory:
- **Critical Patch Update (CPU)**: quarterly, the **third Tuesday of January, April, July and October**.
  Last published: **21 Jul 2026**. Announced next ones: **20 Oct 2026**, **19 Jan 2027**,
  **20 Apr 2027**.
- **Critical Security Patch Update (CSPU)**: **new in 2026** — an interleaved **monthly** track, the
  third Tuesday of **February, March, May, June, August, September, November and December**
  (the first was published on **28 May 2026**). **It does not replace the CPU: it complements it.**
- **Release Update (RU)**, quarterly for functionality and cumulative fixes: **always go by
  RU, not by loose patches**; a *one-off* only with an open SR and with a plan for reabsorption in the
  next RU.
- The triage, the window and the application SLA are set by `vulnerability-management-standards`. Here
  the minimum rule: **patching delay is measured and justified in writing**, it does not accumulate in
  silence. Apply with `opatchauto` over a cloned `ORACLE_HOME` and with a **tested rollback**.

**Upgrade path**:
1. A mandatory prior inventory: edition, options **actually in use**
   (`DBA_FEATURE_USAGE_STATISTICS`), size, non-CDB vs CDB, application dependencies and drivers.
2. **AutoUpgrade** (`autoupgrade.jar`) is the supported tool; `analyze` and `fixups` before
   `deploy`. No inherited manual recipes.
3. From 19c non-CDB: **conversion to a PDB is mandatory** and irreversible (§3.1) — a full rehearsal on
   a copy with representative data and a rollback window = restore.
4. Statistics and plans: capture baselines **before** upgrading; a plan regression after the
   upgrade is the most common failure and the most recoverable one if there are baselines.
5. Never in production without having rehearsed the same path in preproduction with real volume.

## 10. Security

- **Users and roles**: application accounts **without** `DBA`, without `SELECT ANY TABLE`, without
  `CREATE ANY *`. Especially dangerous system privileges, forbidden outside justified and
  audited administration: `SYSDBA`/`SYSOPER`, `ALTER SYSTEM`, `CREATE ANY
  PROCEDURE`/`EXECUTE ANY PROCEDURE`, `GRANT ANY *`, `BECOME USER`, `CREATE DATABASE LINK`
  (a *database link* is a permanent trust bridge between systems: inventoried and reviewed).
- **Default accounts**: locked and with an expired password except for the strictly necessary ones.
  Passwords from `secrets-management-standards`, never in `tnsnames.ora`, scripts or jobs.
  `SEC_CASE_SENSITIVE_LOGON` and password profiles active.
- **Unified auditing** (`unified auditing`) by default in current versions: policies
  aimed at what matters (use of administrative privileges, structural changes, access to
  classified tables), **not** "audit everything" — that fills SYSAUX and nobody reads it. The records leave
  the host towards the SIEM (see `detection-engineering-standards` for their exploitation). The
  traditional `AUDIT_TRAIL` is considered legacy.
- **Encryption**: TLS/TCPS on the listener with managed certificates (`cryptography-pki-standards`).
  **TDE requires Advanced Security in EE** (§2.3): if it is not licensed, encryption at rest is
  solved **underneath** (volume/array encryption) and the difference in threat model is documented.
  The *wallet*/keystore **never** in the same backup as the data, and its password under the
  secrets manager — the same key custody criteria `bcdr-standards` demands.
- **Listener surface**: on an internal interface, **never** exposed to the Internet or to the user
  network; `ADMIN_RESTRICTIONS_<listener>=ON`; no `EXTPROC` if it is not used; *valid node checking*
  (`TCP.VALIDNODE_CHECKING` in `sqlnet.ora`) or, better, filtering per `firewall-policy-standards`; and
  **never** port 1521 open "temporarily" for a test. A listener with no password is not
  a configuration defect: it is the modern design — the protection is network and OS.
- **OS surface**: `ORACLE_HOME` and files owned by the `oracle` user, restrictive
  permissions, `orapwd` protected, `linux-hardening-standards` and `selinux-standards` for the rest.
- **Personal data**: classification, retention and masking in non-production environments belong to
  `privacy-engineering-standards` and `data-platform-standards`. Licensing note: **Data Masking and
  Subsetting** and **Database Vault** are separate products — copying production to preproduction "and
  then we anonymise" is not acceptable with or without them.

## 11. Leaving Oracle: the real conversation

It is not a default recommendation nor a free migration. It is an ADR decision with a big cost
and a big benefit, raised **when the licensing cost and the audit exposure
exceed the cost of rewriting** — not out of technological preference.

**What really breaks** (in order of real pain, not of code volume):
1. **Business PL/SQL**: large packages, autonomous transactions, `COMMIT` inside routines
   (PostgreSQL cannot commit inside a function, and a `PROCEDURE` does not control the transaction
   if it is called inside a block). It is 80 % of the effort.
2. **Semantics that change silently**: Oracle treats the **empty string as `NULL`**; PostgreSQL
   does not. It is the no. 1 source of post-migration bugs and **no converter detects it**: it requires auditing
   every comparison with `NULL` and every concatenation.
3. **Oracle's `DATE` includes a time** → map to `timestamp`, never to `date`.
4. `ROWID` (`ctid` is **not** a substitute: it changes with `VACUUM` — a real primary key is added),
   `ROWNUM`, `CONNECT BY`, hierarchical queries, `MERGE`, sequences with `NEXTVAL` outside replicated state.
5. Proprietary types and functions, *hints*, `DBMS_*`, *scheduler* jobs, database links.

**Current tools** (verify version and maintenance before adopting them, §12):
- **ora2pg** (GPLv3, 25.x branch): conversion of schema, data and PL/SQL, and —most valuable— its
  **migration complexity report**, which is run **first**, before committing to anything.
  Its output **does not go to production without review**: it leaves `TODO`/`FIXME` markers by design.
- **orafce**: an extension that reimplements Oracle functions and packages in PostgreSQL. It reduces
  work; **it does not give full compatibility** and its own authors say so.
- **oracle_fdw**: a bridge for an incremental cutover — keeping both engines while
  services are moved, instead of a *big bang*.
- **IvorySQL** (an Oracle compatibility mode on PostgreSQL) as an alternative; **do not mix Oracle
  mode and PostgreSQL mode in the same database**.
- **AWS DMS Schema Conversion** (AWS now recommends the managed route over the downloadable
  **AWS SCT** client), **pgloader**, **credativ-pg-migrator**.
- **Explicit correction**: **Babelfish is NO use for Oracle** — it is the compatibility layer for
  **SQL Server**. Confusing it is a mistake that appears frequently in migration material.

Criteria: migrate **by domains**, starting with the peripheral (reporting, low-risk internal
applications), with `data-platform-standards` setting the destination and the migration discipline, and
`streaming-cdc-standards` if coexistence with change capture is needed. Migrating the data
without migrating the logic is a trap: you deliver a PostgreSQL with half the rules.

## 12. Quality and gates

Gates that **break the build or block going to production**, in increasing order of cost:

1. **The licensing gate (the first, always)**: no design, deployment script or migration is
   approved without declaring which options and packs it uses. Automatable check:
   `CONTROL_MANAGEMENT_PACK_ACCESS` conforming to what is contracted, `MAX_PDBS` set if there is no
   Multitenant, and a **scheduled review of `DBA_FEATURE_USAGE_STATISTICS`** whose result is
   archived with a date. Use of an uncontracted option is a **build failure**, not an observation.
2. **SQL/PL/SQL lint and review**: no concatenated literals (bind variables mandatory),
   no `SELECT *` in interfaces, `PLSQL_WARNINGS` as a compilation error.
3. **Versioned migrations** in the repository and applied only by pipeline (the same criteria as
   `data-platform-standards`); manual DDL in production **forbidden**.
4. **PL/SQL tests** (`utPLSQL` or equivalent) over the happy path, edges and errors, against a
   real Oracle database of the same major version — never against a "compatible" engine.
5. **Plan testing with representative volume**: a plan over 1,000 rows does not predict 100 M.
   Capture baselines of the critical SQL before any upgrade or statistics change.
6. **A passed test restore** (§6) as a periodic platform gate: if the last validated
   restore is older than the agreed cadence, the platform is in breach.
7. **A rehearsed Data Guard switchover** at the cadence of `bcdr-standards`, with the application
   inside the exercise.
8. **Patching**: RU/CPU/CSPU applied within the `vulnerability-management-standards` window;
   the delay is recorded with a reason and a target date.

## 13. Operability and SLIs

- **Minimum SLIs with an actionable alert and a runbook** (the platform where they live belongs to
  `observability-standards`):
  - Availability of the instance and of the **service** (not just "the process is alive"): a real connection and
    a test query.
  - Space: tablespaces and the **FRA** (a full FRA **stops the database** — it is the most frequent
    self-inflicted Oracle outage), ASM per disk group, `ORACLE_BASE`/diag.
  - Redo: log switch frequency, `log file sync`, archiving **with the lag watched** (an archiving
    failure = an imminent halt).
  - Data Guard: *transport lag* and *apply lag*, broker status.
  - Sessions: blocking (`blocking_session`), `ORA-00060` (deadlocks), idle sessions with
    an open transaction.
  - Errors: `ORA-01555`, `ORA-04031`, block corruption, `alert.log` and `adrci` alerts
    filtered by severity (do not dump the whole log into the SIEM).
  - Backups: success and duration of the backup **and of the test restore**, and the **age of the last
    validated restore** as a first-class SLI.
  - Licensing: the date of the last `DBA_FEATURE_USAGE_STATISTICS` review.
- **Capacity**: project datafile growth, redo per second, IOPS and CPU with data, and
  review it quarterly. In Oracle, capacity is **also** a projection of licensing cost:
  adding cores is a purchase.
- **Every configuration change is code**: the `spfile` exported and versioned, `listener.ora`,
  `sqlnet.ora`, `tnsnames.ora` and jobs under version control with *drift* detection
  (`iac-standards`). Zero manual changes in production.

## 14. Sustainability and prohibitions

- A **half-yearly** review of: edition and options used vs. contracted, version and support dates,
  patching applied, dead indexes and objects, live database links, and total cost per instance.
- **A mandatory ADR** for: the edition and licence metric, the virtualisation platform that hosts
  Oracle, adoption of any paid option, adoption of RAC, the Data Guard protection mode,
  the destination of an exit migration.
- Decommissioning is part of the job: instances nobody uses keep billing support.

### List of prohibitions

- ❌ **Using AWR/ASH/ADDM, SQL Tuning Advisor, Real-Time SQL Monitoring or any
  `DBA_HIST_*` view without the corresponding pack licence** — not "just to debug", not once.
  Without a licence: `CONTROL_MANAGEMENT_PACK_ACCESS=NONE` and end of discussion.
- ❌ Creating partitioned tables, marking tables `INMEMORY`, enabling advanced compression, opening a
  standby for reading or creating the fourth PDB **without verifying the licence first**.
- ❌ Setting **prices, metrics or edition limits from memory**. If it is not verified against the
  vendor's documentation or the contract: the gap is declared and the matter is referred to the licence
  manager (§2, §15).
- ❌ Deploying Oracle on a shared virtualisation cluster assuming that "only the hosts where it runs
  get licensed" (§2.4).
- ❌ Production on **Free** (no security patches) or on an out-of-support version without
  documented and risk-accepted compensation.
- ❌ A **non-CDB** architecture in a new design (unsupported) and conversion to a PDB without a prior rehearsal.
- ❌ Justifying **RAC** by performance, or as a substitute for backup or DR.
- ❌ `MAX PROTECTION` without ≥2 standbys and without written acceptance that the primary stops.
- ❌ Treating `expdp` as a backup, or the *recycle bin* as a recovery control.
- ❌ Accepting a backup as good because of a green `RMAN>`: **without a tested restore it does not exist**.
- ❌ SQL with concatenated literals (performance **and** injection) and `EXECUTE IMMEDIATE` over
  unvalidated input.
- ❌ Changing hidden parameters (`_*`) without a Service Request backing them; touching more than one
  parameter at a time without measurement.
- ❌ Deleting or locking statistics as a remedy for a bad plan.
- ❌ Hints sprayed through the code as a stability strategy (use *baselines*).
- ❌ A listener exposed outside the service network, `EXTPROC` active without use, or passwords in
  `tnsnames.ora`/scripts.
- ❌ An application account with `DBA`, `SELECT ANY TABLE` or `GRANT ANY *`.
- ❌ A TDE wallet backed up alongside the data it encrypts.
- ❌ Copying production with personal data to non-production environments without masking.
- ❌ Mixing Pacemaker/Corosync with Oracle Clusterware for the same resource.
- ❌ Presenting the migration to PostgreSQL as an automatic conversion: business PL/SQL and the
  semantics of `NULL`/empty string are not solved by any tool.
- ❌ Proposing Babelfish to migrate Oracle (it is for SQL Server).

## 15. Mandatory web verification

Every datum in this skill with a financial or support impact **expires**. Before pinning anything:

1. **Version and support**: MOS **Doc ID 742060.1** ("Release Schedule of Current Database Releases")
   and the *Oracle Lifetime Support Policy: Technology Products* (PDF) — Premier/Extended for 19c, 21c,
   23ai and **26ai**, and **the exact scope of the 19c exclusions from 1 May 2027**
   (BSAFE, Java, TLS, Native Network Encryption, TDE, `DBMS_CRYPTO`, FIPS).
2. **Licensing by edition**: the *Licensing Information User Manual* of the exact version
   deployed (tables "Consolidation", "High Availability", "Manageability", "Performance",
   "Scalability", "Security", "VLDB") — what is an *extra cost option* **today** and whether anything changed
   edition.
3. **Availability of Standard Edition 2 for 26ai** outside Oracle Database Appliance: it was an
   **open gap** in this verification.
4. The current *Processor Core Factor Table* and the *Authorized Cloud Environments* policy.
5. **Oracle Partitioning Policy** (PDF): confirm the verbatim quote in §2.4 by opening the document
   —oracle.com blocked the automated download— and its contractual status.
6. The limits of **Oracle AI Database Free** and its patching policy.
7. The current **CPU and CSPU** calendar and the CVEs of the last quarter affecting the version
   deployed; triage per `vulnerability-management-standards`.
8. The status and maintenance of **ora2pg**, **orafce**, **oracle_fdw**, **IvorySQL**,
   **credativ-pg-migrator** and of the AWS conversion route before recommending them.

### Declared gaps in this verification (August 2026)

- **MOS Doc ID 742060.1**: it requires a My Oracle Support account. **Not read**. The support dates
  of §9 come from concurring secondary sources (Oracle announcements picked up by
  third parties) except the Release Updates table, which was read on docs.oracle.com. **Confirm in MOS
  before planning an upgrade.**
- **Oracle Partitioning Policy (PDF)**: oracle.com returned **HTTP 403** to the automated download.
  The quote in §2.4 is not verified against the primary source.
- **Processor Core Factor Table (PDF)**: the same block. The 0.5 value for x86 comes from secondary
  sources; **verify the current PDF and archive a dated copy**.
- **Prices**: **none** in this document, deliberately. There is no verified list figure and
  **none is approximated**.
- **Standard Edition 2 on 26ai outside ODA**: no confirmation of general availability
  found. Treat as "not available" until confirmed with Oracle.
- **RAC under SE2**: secondary sources **contradict each other** (some give it as removed since 19c,
  others as included within the 2-socket cap). **No criterion is set here**: verify in the
  Licensing Information User Manual of the specific version before designing on it.
- **Premier Support dates for 21c and 26ai**: secondary source only.

If the web contradicts this document, **the web wins** — flag the discrepancy.
