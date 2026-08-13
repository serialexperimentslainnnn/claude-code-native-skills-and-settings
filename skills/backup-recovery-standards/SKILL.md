---
name: backup-recovery-standards
description: Backup and restore mechanics — how the copy is made, where it lands and how the restore is proven. Use when choosing or operating a backup tool (restic init/backup/forget --keep-*/prune/check --read-data-subset/repository format v2, Kopia snapshot/policy set/maintenance run, BorgBackup borg create/compact/check with --append-only, borgmatic.yaml, Duplicati, rsync/rsnapshot hardlink rotation, Bacula/Bareos bconsole and Director pools, tape/LTO, Veeam in a mixed estate), designing full/incremental/differential, forever-incremental and synthetic-full chains, deduplication and compression, file-level versus block-level versus whole-image versus application-consistent snapshots, quiesce with fsfreeze and pre/post hooks around a snapshot, 3-2-1 and 3-2-1-1-0 repository topology, append-only or WORM repositories, client-side repository encryption whose passphrase never lives on the copied host, write-but-not-delete agent credentials, GFS retention with prune and garbage collection, repository check/verify, automated timed test restores, backup catalog and coverage gaps, bare-metal and granular restore procedures, and backing up endpoints, SaaS tenants, container volumes and very large filesystems where restore time dominates.
---

# Backup and recovery standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: **a green job is not a backup. The backup is the restore.** Everything that
> follows exists so that a proven, timed restore exists, repeatable by someone who did not write it.

## 1. Scope and triggers

Applies to the **mechanics** of backup and restore: copy model and chain, consistency of the starting
point, tool choice, repository design and its immutability, encryption and credential separation,
retention and pruning, verification and integrity, catalog and coverage, and the concrete restore
procedure.

Triggers: `restic`, `kopia`, `borg`, `borgmatic`, `borgmatic.yaml`, `duplicati`, `rsnapshot`,
`bconsole`, `bareos-dir.conf`, `vzdump`, `pg_dump` **as a destination** (not as a dump), `--append-only`,
`forget --keep-daily`, `prune`, `check --read-data`, `RESTIC_PASSWORD_FILE`, `KOPIA_PASSWORD`,
`BORG_REPO`, `repokey`/`keyfile`, GFS, WORM, *bare metal restore*, "test restore", "restore drill",
"backup coverage", "backup catalog", "tape/LTO".

### Arbitration rule with `bcdr-standards` (critical boundary, mirrored word for word)

`bcdr-standards` §1 already declared it and **this document reproduces it unmodified**:

> **"how is the copy made?" belongs to `backup-recovery`** (tool, repository, 3-2-1, GFS, dedup,
> repo encryption, integrity, catalog, restore procedure); **"how much can we afford to lose, in what
> order do we bring things back and who decides?" belongs to `bcdr`**.

Operational corollaries, so the boundary does not erode:

- **Not written here**: BIA, deriving RTO/RPO from business impact, service *tiers*, disaster
  activation criteria, who declares, crisis communication, alternate site, DR exercises and their
  cadence, the choice between *backup-restore* / *pilot light* / *warm standby* /
  active-active, multi-region or multi-cloud posture. All of that belongs to `bcdr-standards`.
- **Written here**: the **test restore** as an engineering control over the repository — timed,
  automated and with content verification. It is distinct from the **DR exercise**, which is
  multi-service, with recovery order and roles, and belongs to `bcdr-standards`. If the drill
  involves more than one service and people with an assigned role, it is no longer this skill's.
- **This skill receives the number, it does not invent it**: the committed RPO arrives given and here
  it is translated into copy frequency; the committed RTO arrives given and here it is contrasted
  against the **measured restore time**. If the measured one does not fit, the finding goes back to
  `bcdr-standards` — **the commitment is not adjusted here**.
- **Recovery order between services belongs to `bcdr-standards`.** Here, only the **internal** order
  of a restore (catalog → metadata → data → validation).

**Not applicable**: see
- `bcdr-standards` (**the critical boundary, above**).
- `zfs-standards`: `zfs snapshot`, `zfs send/recv`, `syncoid`/`zrepl`, native encryption and *raw send*
  are its **low-level mechanisms**. Here, their use as a **coherent starting point** (§3.2) and the
  hard rule already declared in its §1: **a snapshot is not a backup** — it lives in the same pool,
  dies with it, and a `zpool destroy` or ransomware with `root` takes it away. `zfs send` to another
  pool is a valid copy mechanism, but without a catalog, verified retention or immutability **it is
  not a backup system**: that is what this skill adds on top.
- `linux-storage-standards`: LVM and its *thin snapshots*, dm-snapshot, LUKS, filesystem freezing,
  multipath, NVMe. `fsfreeze` or the LVM snapshot as a primitive is theirs; **when and why it is used
  as the basis of a consistent copy belongs here**.
- `data-platform-standards` (**cross-reference declared on both sides**): **the correct dump for each
  engine is theirs** — `pg_dump`/`pg_basebackup`, WAL archiving and PostgreSQL PITR, `redis-cli --rdb`
  and AOF, Kafka topic retention and compaction, `mysqldump`/`xtrabackup`. **The repository where that
  dump ends up, its retention, its encryption, its immutability and its proven restore belong here.**
  Rule: if the question is "how do I get a consistent file out of this engine?", it is theirs; if it
  is "where does that file live, for how long and how do I prove it restores?", it belongs here.
- `object-storage-standards` (**sister skill; cross-reference declared on both sides**): object storage
  is today the most common backup destination and the one that provides immutability, but it is a
  domain of its own. **Object Lock, versioning, bucket policies, storage classes and their retrieval
  time, lifecycle, multipart and cost are explained there**; here they are **required** as a repository
  requirement (§3.4) and linked, without duplicating the detail.
- `privacy-engineering-standards` (**real cross-reference, declared on both sides**): the right to
  erasure against immutable copies. **The erasure obligation, its implementation and the reapplication
  of erasures after a restore are theirs; the repository's retention window and its immutability
  belong here.** The conflict is not resolved by deleting inside the backup (§3.6): it is resolved
  with per-subject *crypto-shredding* and with a bounded, documented retention window.
- `cryptography-pki-standards`: algorithm choice, key derivation and **custody** of the repository's
  encryption material. Here, only the operational requirement: **client-side** encryption and the key
  **outside** the backed-up system.
- `secrets-management-standards`: where the repository credentials live and how they rotate, the
  `RESTIC_PASSWORD_FILE` or the systemd unit's `LoadCredential=`.
- `incident-response-forensics-standards` (**cross-reference declared on both sides**): **restoring
  without eradicating is one of their antipatterns**, and the clean restore point is determined by the
  investigation. Additional cross-reference from this skill: **verifying that the copy is not
  compromised before restoring** — the repository is a plausible source of reinfection (trojanised
  binaries, persistence tasks, attacker keys). What this skill contributes is what makes that
  verification possible: retention deeper than the plausible *dwell time*, a catalog queryable by
  date, the ability to restore into an isolated environment for analysis, and mounting the copy
  read-only. **The decision about the clean point is theirs.**
- `kubernetes-standards` (**line decided and declared**): the **Kubernetes object** is theirs — Velero
  and its installation, `Backup`/`Restore`/`Schedule`/`BackupStorageLocation`, CSI `VolumeSnapshotClass`,
  Velero *hooks*, `etcd` backup. **The doctrine belongs here**: immutable destination, credential
  without delete, GFS, repository `check`, timed test restore and coverage. Rule: if the answer is a
  manifest or a `velero` CLI invocation, it is theirs; if it is "how often, where, with what retention
  and how is it tested", it belongs here. (Velero uses **Kopia** as its data backend: whatever is said
  about Kopia here applies to it.)
- `proxmox-ve-standards` (**already exists on disk; line decided**): **Proxmox Backup Server as a
  product is theirs** — installation, *datastores* and *namespaces*, `proxmox-backup-client`,
  `verify`/`prune`/`garbage-collect` and sync jobs, *datastores* over S3, RBAC, integration with
  `vzdump`. **The doctrine of verification, retention, immutability and isolation belongs here**, and
  PBS either meets it or does not, like any other tool.
- `libvirt-kvm-standards` (**already exists on disk**): internal and external domain *snapshots*
  (`snapshot-create-as`, `blockcommit`, `blockpull`), `virsh blockcopy`, *quiesce* via
  `qemu-guest-agent`. The primitive is theirs; its use as the basis of a consistent copy belongs
  here.
- `podman-systemd-containers-standards`: volumes, `podman volume export`,
  Quadlet. What of a container is backed up and what is not (§3.8) belongs here.
- `ha-clustering-standards`: **replication is not backup** — HA propagates deletion
  and malicious encryption at network speed.
- `onprem-standards`: platform umbrella. Its §1.3 sets the invariant **"a backup without a proven
  restore does not exist"**, which this document develops without contradicting; its §6 marked its
  backup block as **provisional criteria pending this skill** — from here on, it cedes the detail and
  keeps the invariant.
- `homelab-standards`: restic/Kopia/borgmatic **in a lab**, where the dominant criterion is cost and
  effort, not a contractual commitment. There, what is vetoed here as expensive is admissible.
- `aws-standards` / `azure-standards` / `gcp-standards`: AWS Backup, Azure Backup and Backup Vault,
  Google's Backup and DR Service, and their billing and quotas. Here, the criteria they must meet.
- `windows-server-ad-standards`: system state backup and AD forest recovery.
- `vulnerability-management-standards`: triage and patching SLA for the backup software's CVEs
  (§5). `observability-standards`: metric and alert design; here, **what** must be watched.
- `grc-compliance-standards`: retention **by regulatory obligation** and audit evidence. Here, the
  mechanism that implements it. `iac-standards`: backup configuration as code.
- `identity-access-management-standards` and `linux-hardening-standards`: separate identity and
  hardening of the backup host. `networking-standards` and `firewall-policy-standards`: segmentation
  of the backup plane.

## 2. Default decisions

> Verify the latest version, licence and maintenance status on the web before committing them to a
> real project (§8). Data as of **August 2026**, with dates and versions taken from
> `api.github.com` and the official notes, **never from the HTML render of GitHub Releases**.

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| General tool (Linux/Unix, S3 destination) | **restic** — 0.19.1 (5-Jul-2026), BSD-2-Clause, active repository. Block-level dedup, client-side encryption, S3/SFTP/local, `check --read-data-subset` | **Kopia** 0.23.1 (16-Jun-2026, Apache-2.0) if you need per-directory policies, a GUI or Velero compatibility |
| When format maturity rules | **BorgBackup 1.4.x** — 1.4.5 (18-Jul-2026), stable and maintained; **server-side `--append-only`** is its best argument | **FORBIDDEN: Borg 2.0 in production**: still in beta (2.0.0b22, 22-Jul-2026) after years of development. Verify its status before planning the migration |
| Borg orchestration | **borgmatic** 2.1.6 (1-Jun-2026): retention, hooks, `check` and monitoring declared in `borgmatic.yaml` | Home-grown scripts around `borg`: they reinvent `prune`, the hooks and the reporting, and they are always missing the `check` |
| Enterprise, multi-platform, tape | **Bareos 25.x** (AGPLv3 for **all the code**; the **binary packages in the release repo require a subscription contract** — the code is free, the convenient binary is not) | **Bacula**: dual licence, **Enterprise is proprietary** and with components that only reach Community after an exclusivity period. Choose by licence model, not by popularity |
| Mixed estate with VMware/Hyper-V and Windows agents | **Veeam**, and only if its cost and its surface are accepted with eyes open (§5) | **Mandatory if used**: server **outside the production domain**, patching with exposed-service urgency |
| Graphical interface for workstations | **Kopia** (official GUI) | **Duplicati** 2.3.0.4 (9-Jul-2026): useful on the desktop, a history of repository reliability problems; **FORBIDDEN as the only backup of a server** |
| Simple "mirror" copy | **`rsync` with `--link-dest` or `rsnapshot`** only for non-critical data with no immutability or encryption requirement | **FORBIDDEN as a production backup system**: no real dedup, no encryption, no catalog, no `check`, and an `rsync --delete` propagates deletion |
| Containers and Kubernetes | **Velero** 1.18.2 (26-Jun-2026), repo **`velero-io/velero`** (the old `vmware-tanzu/velero` redirects), CNCF, Kopia backend | See the boundary with `kubernetes-standards`. Backing up only PVs without the cluster objects leaves half the job done |
| Chain model | **Forever incremental with dedup** (restic, Kopia, Borg): a single chain, pruning by retention | **Full + incrementals with a long chain**: a broken chain invalidates everything after it. If the tool uses it, demand a periodic **synthetic full** |
| Compression | **zstd** (restic ≥0.14 with **repository format v2**; Borg `zstd`; Kopia by default) | No compression only if the data is already compressed or encrypted (video, encrypted VM images) |
| Encryption | **Client-side, always**, with the key **outside** the backed-up system | **FORBIDDEN** to rely only on the provider's encryption: it protects neither from deletion nor from compromise of the source |
| Primary destination | **Object storage with Object Lock** (see `object-storage-standards`) | Borg repository in `--append-only` mode over SSH with a dedicated user and a restricted `command=` |
| Source credential | **Write without delete**: the backed-up system cannot prune its own copies. Pruning is executed by a different identity, from another plane | **FORBIDDEN** for the same secret that writes to be able to run `forget --prune` or `DeleteObject` |
| Retention | **GFS** by criticality, with a window deeper than the plausible *dwell time* (months) | 7-day retention: it discovers the ransomware on day 30 and has nothing to go back to |
| Verification | **Scheduled repository `check` + automated and timed test restore** (§3.7) | **FORBIDDEN** to consider a repository verified because of the copy job's exit code |
| Catalog | **Coverage inventory as code**, contrasted against the service inventory (§3.9) | The implicit list of "whatever somebody configured at some point" |

**Tool selection rule**: choose by **real maintenance** (release cadence and number of effective
maintainers), **licence model** (what they charge you, when and along which axis — capacity,
endpoints, binaries) and **attack surface**, in that order. Popularity is not a criterion: it is the
reason you end up choosing the product that gets attacked the most.

**Bus factor risk, verified**: in **Kopia**, the founder accumulates ~5x the contributions of the
second contributor (2041 versus 426 as of Aug-2026). It is not a veto — Apache-2.0, continuous
activity and institutional use as Velero's backend mitigate it — but **it is a datum for the ADR**,
and it is exactly the kind of thing that is not decided from memory.

## 3. Mechanics

### 3.1 Copy models

| Model | What it does | Dominant risk |
|---|---|---|
| **Full** | Everything, every time | Cost and window; simplest RTO |
| **Incremental** | Only what changed since the previous copy (of any type) | **The chain**: one corrupt link invalidates everything after it |
| **Differential** | Everything changed since the last full | Grows until the next full; two-piece restore |
| **Forever incremental** | An initial full and only incrementals afterwards, with retention resolving the pruning | The repository **is** the chain: its integrity is everything (hence the `check`) |
| **Synthetic full** | The repository synthesises a full out of incrementals, without re-reading the source | Consumes I/O and space at the destination; indispensable if the tool uses classic chains |

- **Deduplication**: variable-length block dedup (restic, Borg, Kopia) is what gives real ratios over
  similar data; fixed-length dedup breaks with a one-byte insertion. **Dedup creates coupling**: one
  corrupt block affects every snapshot referencing it — an additional reason for the periodic
  `check --read-data`. Dedup **across clients** in a shared repository is a side channel and an
  isolation risk: **one repository per system or per trust domain**, not one global one.
- **Compress before encrypting**, never the other way round (encrypted data is incompressible). All the
  recommended tools already do this; if one lets you invert it, that is a smell.
- **Copy levels**, and when each applies:
  - **File**: portable, trivial granular restore, loses attributes if the *backend* does not support
    them and is extremely slow with millions of small files.
  - **Block / image**: fast and faithful, allows *bare metal restore*, but **it restores garbage if
    the source was not coherent** and granular restore requires mounting the image.
  - **Application-consistent**: the only valid one for databases and directories; it is obtained with
    the engine's own mechanism (`data-platform-standards`) or with *hooks* that invoke it.

### 3.2 Consistency: where most home-made backups fail

**Copying a database's files hot without its own mechanism produces an unusable backup.** Not
"degraded": unusable, and silently so — the job finishes green, the file exists, it is the expected
size, and the engine refuses to start on restore day because the pages belong to different instants
and the WAL/redo is not there.

Correct order, best to worst:

1. **The engine's mechanism** (`pg_basebackup` + WAL archiving, `xtrabackup`, `mongodump`, logical
   dump...). Which mechanism and with which parameters is set by `data-platform-standards`; **here we
   only require that it exists and that its output lands in the repository under the rules of §3.4**.
2. **Snapshot with quiesce**: freeze the filesystem (`fsfreeze`, VSS on Windows, `qemu-guest-agent`
   with `fsfreeze-hook`) or the engine (`pg_backup_start`), take the snapshot (ZFS, LVM, CSI, hypervisor),
   thaw and **copy from the snapshot, not from the live system**. This makes the copy at least
   *crash consistent*, and *application consistent* if the hook involves the engine.
3. **Hot copy with nothing**: valid only for data with no transactional state (static content, logs).
   For everything else, **vetoed**.

*Hook* rules:
- **Failure of the `pre` hook aborts the copy.** A hook that fails and a copy that carries on is the
  exact recipe for the green unusable backup. Verify that your tool does this: in `borgmatic` the
  hooks are declarative and their failure is a job failure; in home-grown scripts you have to code it.
- **The `post` hook always runs**, even if the copy fails (`trap`/`defer`): a frozen filesystem or a
  database left in backup mode that nobody thawed is a production incident.
- **Bounded and monitored freeze window**: `fsfreeze` blocks writes. Set a maximum time and an
  emergency exit.
- **The snapshot is the starting point, not the destination**. A ZFS or LVM snapshot lives on the same
  storage as the source; it is a coherence and fast-recovery-from-human-error mechanism,
  **not a backup** (`zfs-standards` §1, `linux-storage-standards`).

### 3.3 What gets backed up (and what almost nobody backs up)

Beyond the obvious data: system and service configuration, **network, firewall and load balancer
configuration**, VM definitions and their inventory, certificates and their private material, secrets
and their vault, **the backup system's own configuration and its catalog**, telemetry and dashboards,
licence keys, the inventory and the operational documentation. Practical rule: **if rebuilding it by
hand costs more than copying it, it goes into the backup**.

And **what does not go in**: caches, artifacts rebuildable from the code, regenerable derived data,
and anything whose retention is vetoed by personal data minimisation
(`privacy-engineering-standards`). Backing up junk inflates the cost and lengthens the restore, which
is the time that matters.

### 3.4 The repository

**3-2-1** as the floor: **3** copies of the data, on **2** different media or technologies, with **1**
off site. **3-2-1-1-0** is the real target today: it adds **1 immutable or offline copy** and **0
verification errors** — that is, the variant that makes explicit what 3-2-1 left implicit.

- **Local**: fast for the everyday restore (95% of restores are "I deleted a file"). It does not count
  as an off-site copy and **it does not protect against a domain compromise**.
- **Remote (object storage)**: default destination. It must meet the following, and this is a
  requirement of this skill with the detail in `object-storage-standards`:
  - **Real immutability: Object Lock**, in *compliance* mode for the anchor copy and *governance* for
    the operational one. **Verify that the implementation really enforces it** — there are S3
    implementations that expose the API and do not apply it (§5, and the detail in
    `object-storage-standards` §2).
  - **A write-without-delete credential**, different from the pruning one and from the restore one.
  - **Versioning enabled with an expiration policy for non-current versions**: without expiration, the
    bill grows on its own.
- **Tape / LTO**: still the only trivially *air-gapped* copy and the lowest cost per TB at scale.
  Price: **retrieval time and logistics**. It is justified by long retention and physical isolation,
  not by cost alone.
- ***Append-only* repository**: Borg over SSH with a dedicated user, key restricted by
  `command="borg serve --append-only --restrict-to-path ..."`. It is the honest on-prem alternative to
  Object Lock. **Careful**: `--append-only` protects from remote deletion, but **compaction is executed
  by the server side**; the recovery procedure after a deletion attempt must be known **before**
  needing it.

**Isolation — what makes the repository still exist after the compromise**:
- **Its own identity, not federated with production**; independent MFA; **backup server outside the
  domain** (§5).
- Segmented management plane and **one-way network flow** wherever possible: the repository does not
  mount or reach the source; if the source pushes, it pushes with a credential without delete.
- **At least one copy in another administrative failure domain** (another account, another provider,
  another medium). Production, backup and anchor copy in the same account cover a disk failure, not an
  account failure.
- **The encryption key, outside**: client-side encryption with the key held in a system that is not
  lost along with the backed-up one (`cryptography-pki-standards`, `secrets-management-standards`).
  Encrypted backup without the key = total loss with extra steps.

### 3.5 Retention

- **GFS by criticality**, not a single scheme. A reasonable starting point to adjust per dataset:
  dailies 14-30, weeklies 8-12, monthlies 12, yearlies according to obligation. **The number is closed
  by the intersection of three constraints**: the RPO received from `bcdr-standards`, regulatory
  obligation (`grc-compliance-standards`), and personal data minimisation
  (`privacy-engineering-standards`). The three pull in different directions: that is a decision, not
  an oversight.
- **Minimum depth against silent corruption and ransomware**: retention must cover the attacker's
  plausible *dwell time* and the time to detect slow corruption. Months, not days. Short retention
  turns "up to what date do I have good copies?" into "I don't have any".
- **Prune and garbage collection**: in dedup repositories, `forget` marks and **`prune`/`compact`/
  `maintenance` frees**. Consequences that must be planned for: it is the most expensive and most
  dangerous repository operation, **it needs free space**, and on destinations with Object Lock **it
  cannot delete what is locked** — align the retention window with the lock's, or the `prune` will
  fail forever in silence.
- **Cost is a design constraint, not a surprise**: long retention in a hot class is expensive and in an
  archive class it is **slow to retrieve**. Design retention together with the storage class and its
  retrieval time (`object-storage-standards`), not afterwards.

### 3.6 Erasure and retention: the privacy cross-reference

A real and frequent conflict: the obligation to erase a piece of personal data versus an immutable
repository where by design **nothing can be deleted**.

- **It is not resolved by deleting inside the backup.** Editing immutable copies breaks the property
  that justifies their existence, and with Object Lock in *compliance* mode it is outright impossible.
- **It is resolved by design**: per-subject encryption from day 1 (*crypto-shredding* — the subject's
  key is destroyed and their data becomes unreadable across every copy), plus a **bounded, documented
  and defensible retention window**, plus the **reapplication of erasures after any restore** as a
  mandatory step of the procedure.
- **Split**: the obligation, the design of the *crypto-shredding* and the reapplication belong to
  `privacy-engineering-standards`; **the retention window, the immutability and the reapplication step
  inside the restore runbook belong here**.

### 3.7 Verification: the heart of the skill

Three distinct controls, and **none replaces another**:

1. **Job success**: absolute minimum. A job that has not run for three weeks and nobody noticed is the
   most common failure and the cheapest to detect. **Alert on absence**, not only on error.
2. **Repository `check`**: structural consistency (`restic check`, `borg check`, `kopia
   snapshot verify`) and, periodically, **real re-reading of data** (`restic check --read-data-subset`,
   `borg check --verify-data`). It is the only defence against silent corruption at the destination.
   Reasonable cadence: structural weekly, re-reading of a rotating subset that covers the whole
   repository within a quarter.
3. **Automated and timed test restore** — **the only control that counts**:
   - **Automated and periodic**, not annual and manual.
   - **Into an isolated environment**, never over the source. **What that environment is, how it is
     isolated and who pre-provisions it is specified by `bcdr-standards` §3.6 (IRE / *clean room*)**:
     here, only the requirement that the restore does not touch the source. After a compromise, the
     IRE stops being a recommendation and is the only admissible destination.
   - **With content verification**: the database starts and answers a known query; the restored file
     matches by hash; the service passes its *smoke test*. Restoring bytes proves nothing.
   - **Timed and with the time published as a metric**, at realistic volume. Restore time is an
     engineering datum, not an estimate.
   - **Rotating what gets restored**, so coverage is real and not always the same easy service.
   - **The age of the last validated restore per system is an SLI**, with an alert as it ages —
     exactly like a certificate approaching expiry.

**Partial versus full restore**: the partial one is the one used daily and the one that must be fast
and self-service; the full one is the one that decides whether the system exists. **Both get tested**,
and the full one at least once at real volume: that is where the bandwidth limit, the archive-class
retrieval cost and the fact that the destination had no room to unpack all show up.

### 3.8 Restore

- **Written and rehearsed procedure**, with the acid test inherited from `bcdr-standards`: **can it be
  executed by someone who did not write it, at 03:00, without calling anyone?**
- **Internal order**: catalog and keys → metadata → data → integrity validation → functional
  validation → reconnection. (The order **between services** belongs to `bcdr-standards`.)
- **Bare metal restore**: it demands boot media, drivers, partitioning and a bootloader. It is tested
  on equivalent hardware or a VM **before** needing it; it is the scenario where most plans discover
  the image does not boot. A modern and often better alternative: **rebuild from IaC and restore only
  the data** (`iac-standards`) — faster, cleaner and without dragging along the attacker's
  persistence. Choose one of the two **explicitly** and test the one you choose.
- **Granular restore**: mounting the repository read-only (`restic mount`, `borg mount`,
  `kopia mount`) is the fast route to recover a file, and also the safe route to **inspect** a copy
  without deploying it — useful in the cross-reference with
  `incident-response-forensics-standards`.
- **Before restoring after a compromise**: the copy is treated as potentially contaminated. It is
  mounted read-only, analysed, and restored from the point the investigation determines, not from the
  most recent one. **The clean point decision does not belong to this skill.**
- **Every real restore generates a record**: what, from when, how long it took, what failed. It is the
  source of truth for restore time, far better than the synthetic drill.

### 3.9 Catalog and coverage

**The discovery that a service never entered the backup happens on the worst day.** The control is an
inventory, not an intention:

- **Coverage inventory as code**, generated and contrasted **against the service inventory** (the same
  one `onprem-standards` talks about): what is backed up, under which policy, to which repository,
  with what retention, when its last `check` was and its last validated restore.
- **The headline metric is coverage**: % of production services with a copy configured, verified
  **and** test-restored within the deadline. All three at once, or it does not count.
- **What is not backed up is declared explicitly**, with an owner and with risk acceptance. A service
  without a copy by decision is governance; without a copy by oversight it is a time bomb.
- **Active discovery**: periodically compare existing hosts, volumes, buckets, databases and SaaS
  *tenants* against the coverage inventory. Everything new starts with no copy.
- **The backup system's catalog backs itself up**, outside the backup system. Without a catalog, a
  dedup repository is a pile of blocks.

### 3.10 Cases

- **Endpoints and laptops**: intermittent connectivity, encrypted disk, user with local `root`.
  Continuous or opportunistic copy, with **retention on the server and a credential without delete**
  (the stolen or compromised laptop must not be able to prune). Client-side encryption mandatory.
  Assume the user will switch the agent off: measure the **age of the last copy per device**, not job
  success.
- **SaaS**: **the provider does not back up your data for you.** The shared responsibility model leaves
  data protection on the customer's side; the provider's replication is not backup (the deletion is
  replicated) and the native recycle bin has limited retention and can be emptied by an attacker with
  permissions. Demand your own copy, exportable and restorable, and **test the restore**, not the
  export. The vendor-dependency framing and the exit plan belong to `bcdr-standards`.
- **Objects and buckets**: a bucket is not backed up by "copying it to another bucket in the same
  account". See `object-storage-standards` for replication, versioning, Object Lock and cost; here, the
  requirement: **another account or another provider, a credential without delete, and a proven
  restore** (which with objects is usually the problem: restoring millions of objects is slow and is
  billed per request).
- **Containers and volumes**: the image is rebuilt, **the volume is not**. What is backed up is the
  **state** (volumes, databases, secrets) and the **definition** (manifests, Quadlet, compose), not the
  container. Copying a database volume hot without a *hook* is the §3.2 case in its most frequent form.
- **Enormous filesystems (millions of files, hundreds of TB)**: here **the problem is not the copy
  time, it is the restore time**. Incremental copying is cheap; restoring 200 TB or 300 million
  inodes is not. Design consequences: segment by dataset with different policies, prefer block-level
  copying or snapshot replication for the bulk and file-level copying for what requires granularity,
  **measure restore time per dataset** and hand the number back to `bcdr-standards` if it does not fit.
  Metadata traversal usually dominates over volume: a tree with tens of millions of small files takes
  longer to enumerate than to transfer.

## 4. Gates

They break the delivery. In order of increasing cost:

1. **Backup configuration as code and reviewed** — policy, retention, destination and hooks in the IaC
   repository, not configured by hand in a console.
2. **Alert on the absence of a copy**, not only on a failed copy. A job that stopped running does not
   generate an error: it generates silence.
3. **Scheduled structural repository `check`** with its result in monitoring.
4. **`check` with data re-reading** covering the whole repository within a defined cycle.
5. **Automated, timed test restore with functional verification**, with the **age of the last
   validated restore** published per system and alerted as it ages. *This is the gate: the previous
   four without this one prove nothing.*
6. **Immutability test**: demonstrate, by running it, that the source's credential **cannot** delete or
   alter the copies, and that the anchor copy resists a deliberate deletion attempt.
7. **Key custody test**: restore using **only** the material held outside the backed-up system, by the
   designated people.
8. **Coverage**: 100% of production services with a copy configured **and** verified **and** with a
   test restore within the deadline; whatever is missing, declared with an owner and accepted risk.
9. **No plaintext secrets**: no repository password in the unit file, in the `crontab`, in the image or
   in the log. `LoadCredential=`/`systemd-creds`, a file with restricted permissions or a secrets
   manager (`secrets-management-standards`).
10. **Patching the backup software with an exposed-service SLA** (§5), verified in the vulnerability
    inventory.

## 5. Backup system security

**The backup system is a maximum-value target and a critical surface.** By design it has read access
to everything and credentials across the whole fleet: whoever controls it controls the data and can
destroy the ability to recover.

- **Outside the production domain.** This is not a preference: **CVE-2026-44963** in Veeam Backup &
  Replication (insecure deserialization, CWE-502, **CVSS v4 9.4** / v3 8.8) allows **remote code
  execution on the backup server by any authenticated domain user, without elevated privileges**, and
  **only affects domain-joined installations**. It affects 12.3.2.4465 and earlier of the 12 branch;
  fixed in **12.3.2.4854** (advisory KB4869, **9-Jun-2026**); branch 13 is not affected due to
  architectural changes. As of the verification date there was no confirmed exploitation or validated
  public PoC — but ransomware groups have repeatedly attacked Veeam infrastructure and CISA has
  catalogued previous flaws in the product as exploited. **The mitigation the vendor itself
  recommends: unjoin the server from the domain.** That is the argument, and it holds for any product:
  backup infrastructure with a separate identity turns a domain RCE into a contained incident.
  **Verify versions and exploitation status before acting (§8).**
- **Patch with exposed-service urgency**, even if it is "only on the internal network". It goes to
  `vulnerability-management-standards` with a critical SLA.
- **Least privilege in both directions**: the agent's credential writes and does not delete; the
  pruning one lives on another plane and the source does not know it; the restore one is used on
  demand and audited. None of them is a domain administrator.
- **Minimum surface**: no exposed web console, no plugin that is not used, no agent on systems that do
  not require it. The management plane, segmented.
- **Auditing the backup itself**: `forget`, `prune`, repository deletion, retention policy change and
  restore are first-class security events. **They are logged outside the backup system** and alerted
  on (a pruning spike outside the window is a sign of compromise, not of tidying up).
- **The tool's own supply chain**: verify the signature and checksum of the binaries (restic and rclone
  publish signed checksums), pin versions by *digest* in containers and watch the project's advisories.
  Precedents from the catalogue that justify the paranoia: the compromise of
  **Trivy** (March 2026) and the 2026 wave of attacks on repositories and GitHub Actions
  (Nx/**CVE-2026-48027** in CISA's KEV catalog, the "Megalodon" campaign against workflows, *Miasma*).
  **As of Aug-2026 no evidence of compromise was found in restic, rclone, Kopia or borgmatic** — with
  the §8 caveat: the search was broad, not exhaustive over each project's advisory channels.
- **The repository is a plausible source of reinfection**: it contains what was there on the day of the
  compromise, including trojanised binaries and persistence. Mounting it read-only to analyse before
  restoring is the correct move; deciding the clean point belongs to
  `incident-response-forensics-standards`.

## 6. Operability and metrics

What is watched (the **how** it is instrumented belongs to `observability-standards`):

- **Age of the last correct copy** per system — the metric compared against the committed RPO.
- **Age of the last `check` with re-reading** and of the **last validated restore**, per repository and
  per system. Alert on ageing.
- **Measured restore time**, per system and per size, from the test restore **and** from the real
  restores.
- **Coverage** (§3.9) and its trend.
- **Copy duration and window**: a copy that no longer fits in its window is a warning that the strategy
  has outgrown itself, not a performance problem.
- **Repository growth and cost**, broken down by requests as well as space: in object storage, a
  repository with millions of small objects is billed per request
  (`object-storage-standards`).
- **`prune`/`compact` success**: its silent failure is how a repository grows uncontrolled or how
  retention stops being met. A specific alert.
- **Free space at the destination** with a threshold that accounts for what the `prune` needs to
  operate.
- **A failed test restore raises its own alert**, distinct from the failed-copy one, and with higher
  priority: a failed copy is a problem of today; a failed restore is the revelation that you have been
  without protection for months.

## 7. Sustainability and prohibitions

**Cadence**: half-yearly review of the tool's versions, licences and maintenance status (§8); annual
review of the retention scheme against regulatory obligation and minimisation; review of the coverage
policy on every new service; repository format migration planned as a project, with a window and a
subsequent `check` — **never as a side effect of a package update** (restic requires
`migrate upgrade_repo_v2` + `prune` for format v2; Borg 2 will break compatibility and **is still in
beta**).

**Honest incremental adoption**: an encrypted copy to a destination with Object Lock → GFS retention →
scheduled `check` → **one automated test restore** → coverage inventory. In that order. Half of all
organisations stop at the first step and believe they are done.

**FORBIDDEN**
- ❌ Declaring a backup "done" without a proven, timed restore with content verification.
- ❌ Taking the copy job's exit code as proof that the repository is healthy.
- ❌ Copying a database's files hot without the engine's mechanism or a quiesce.
- ❌ Continuing the copy when the `pre` hook has failed; or leaving the filesystem frozen because the
  `post` hook did not run on error.
- ❌ Considering a snapshot that lives in the same pool or on the same storage as the source a backup.
- ❌ Considering replication, RAID or an HA cluster a backup: they propagate deletion and encryption.
- ❌ A single copy; a copy in the same chassis, pool, account or provider as the source without a
  documented decision; the total absence of an immutable or offline copy.
- ❌ A credential on the backed-up system with delete or prune permission over its own repository.
- ❌ A backup server joined to the production domain, or with an identity federated with it.
- ❌ Encryption only on the provider side; the encryption key held only inside the backed-up system;
  the repository password in plaintext in a systemd unit, cron, image or log.
- ❌ Retention shorter than an attacker's plausible *dwell time*.
- ❌ An Object Lock window misaligned with retention, leaving the `prune` failing silently.
- ❌ Versioning at the destination without an expiration policy for non-current versions.
- ❌ A repository shared between different trust domains to "take advantage of the dedup".
- ❌ **Borg 2.x in production** while it remains in beta.
- ❌ `rsync`/`rsnapshot` or `Duplicati` as the only backup of a production server.
- ❌ Choosing the tool by popularity instead of by real maintenance, licence and surface.
- ❌ A production service with no entry in the coverage inventory, or an exclusion without an owner or
  accepted risk.
- ❌ Restoring after a compromise without the investigation having established the clean point.
- ❌ Assuming SaaS backs up your data, or testing the export instead of the restore.
- ❌ Designing archive-class retention without having measured its **retrieval time**
  (`object-storage-standards`).
- ❌ Fixing versions, licences, CVEs or product behaviour **from memory** (§8).
- ❌ Invading `bcdr-standards`: RTO/RPO, *tiers*, recovery order between services and disaster
  activation criteria are not set here.

## 8. Mandatory web verification

Before committing to any version, licence, CVE or behaviour, **search for it — do not remember it**.
**Methodological warning**: every GitHub date or version must come from **`api.github.com` or the Atom
feeds**, never from the HTML render of the Releases page (the HTML summary invents the year).

1. **restic**: latest stable (as of Aug-2026, **0.19.1**, 5-Jul-2026; 0.19.0 of 9-Jun-2026 added zstd
   `fastest`/`better` modes, faster index loading, a `check` restrictable by snapshot filter and
   `restore --ownership-by-name`, and requires Go ≥1.25). Status of **repository format v2** and of the
   `migrate upgrade_repo_v2` + `prune` procedure, and which legacy *features* have been withdrawn.
2. **Kopia**: latest stable (as of Aug-2026, **0.23.1**, 16-Jun-2026, Apache-2.0), repository format
   changes between major versions and **governance / bus factor status** (the founder accumulated
   ~5x the contributions of the second contributor). Check the current contributor graph.
3. **BorgBackup**: stable branch (as of Aug-2026, **1.4.5**, 18-Jul-2026) and **the status of Borg 2.0**,
   which was still in **beta** (2.0.0b22, 22-Jul-2026) after years of development. **Do not plan the
   migration without confirming it has left beta.** And **borgmatic** (2.1.6, 1-Jun-2026).
4. **Bareos and Bacula**: version, and above all **licence model and binary access model** — Bareos is
   AGPLv3 across all the code but the **packages in the release repository require a subscription**;
   Bacula is dual-licensed with **Enterprise proprietary**. Verify Bareos's 25.x branch and its
   maintenance releases.
5. **Veeam**: status of **CVE-2026-44963** (CVSS v4 9.4, RCE by an authenticated domain user, only
   **domain-joined** installations, affects 12.3.2.4465 and earlier of v12, fixed in
   **12.3.2.4854**, KB4869 of 9-Jun-2026, v13 unaffected), its active exploitation and any later CVE.
   Contrast the build number against Veeam's official KB: there are reports of inconsistencies between
   the technical press and the vendor's KBs. Also review CISA's **KEV** catalog.
6. **Velero**: the current repository (**`velero-io/velero`**; `vmware-tanzu/velero` redirects), latest
   stable (as of Aug-2026, **1.18.2**, 26-Jun-2026) and its status in the CNCF.
7. **Duplicati** (2.3.0.4 stable, 9-Jul-2026) and any tool you are going to recommend for the desktop:
   repository reliability and project activity.
8. **Supply chain incidents** for any tool you recommend, in their advisory channels (the project's
   GitHub Security Advisories, the vendor's lists), not just via a general search.
   **Declared gap**: the Aug-2026 check on restic, rclone, Kopia and borgmatic was a broad search with
   no results, **not an exhaustive review of each project's advisories**.
9. **Object Lock and the destination**: behaviour and real implementation at your provider and, if it is
   self-hosted, whether the implementation **enforces** immutability or merely exposes the API. The
   detail is in `object-storage-standards` §8; here, the requirement to check it before anchoring your
   immutability on it.
10. **Managed backup services** (AWS Backup, Azure Backup, Google Backup and DR) and **SaaS** ones
    (Microsoft 365 Backup and its coverage per workload, Google Workspace) before treating them as
    sufficient: what they cover today and what they do not.
11. **Declared gaps in this review**, not to be filled from memory:
    - **Proxmox Backup Server**: its version and its verification, *namespace* and synchronisation
      capabilities were not verified. The GitHub mirror `proxmox/proxmox-backup` does not reflect real
      development (which lives at `git.proxmox.com`) and its tags are out of date. It will go to
      `proxmox-ve-standards`; until then, **verify in the official Proxmox documentation**.
    - **Tape/LTO**: current generation, capacities and the status of the LTO consortium's roadmap were
      not verified.
    - **Cost figures** for any provider: not verified here beyond what is stated in
      `object-storage-standards`.
    - **Bareos/Bacula CVEs**: not reviewed in this pass.

If you cannot verify, **say so explicitly instead of assuming**.
If the web contradicts this document, **the web wins** — flag the discrepancy.
