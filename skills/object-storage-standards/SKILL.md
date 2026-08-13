---
name: object-storage-standards
description: Object storage as a model distinct from block and file — the S3 API, its self-hosted implementations and its failure modes. Use when working with aws s3 / aws s3api, mc, or rclone remotes and rclone mount, s3fs, goofys or mountpoint-s3, designing bucket names and key prefixes for listing and throughput, bucket policies versus IAM versus ACLs, BucketOwnerEnforced object ownership, Block Public Access, presigned URLs and their TTL, SSE-S3 / SSE-KMS / SSE-C and TLS enforcement via aws:SecureTransport, Object Lock in governance or compliance mode, legal hold, bucket versioning with noncurrent-version expiration, lifecycle transitions to Glacier Instant Retrieval, Flexible Retrieval or Deep Archive and their restore latency, egress and per-request cost, multipart uploads and AbortIncompleteMultipartUpload, ETag pitfalls and CRC32C or CRC64-NVME checksums, cross-region or cross-provider replication, Storage Lens and request-level metrics, or running MinIO, Ceph RGW, Garage or SeaweedFS on-premise with erasure coding and failure domains.
---

# Object storage standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: object storage **is not a slow disk nor a cheap NAS**. It is a
> different model —immutable object, no real hierarchy, with a cost per request and per egress— and
> almost every serious problem in the domain is born of treating it as if it were a filesystem.

## 1. Scope and triggers

Applies to the design and operation of object storage: the model and its consequences, the S3 API
as the de facto standard and its actual compatibility, bucket and key design, security and public
exposure, immutability and versioning, life cycle and storage classes with their cost and their
**retrieval time**, integrity and multipart, replication, request and cost observability,
and the criteria for running your own object storage.

Triggers: `aws s3`, `aws s3api`, `mc` (MinIO Client), `s3cmd`, `rclone` and its *remotes*,
`s3fs`, `goofys`, `mount-s3`/`mountpoint-s3`, `boto3`/`aws-sdk` against S3, `radosgw-admin`,
`garage`, `weed`, `bucket policy`, `BucketOwnerEnforced`, `BlockPublicAcls`, `PutObjectLockConfiguration`,
`ObjectLockLegalHold`, `NoncurrentVersionExpiration`, `AbortIncompleteMultipartUpload`,
`CreateMultipartUpload`, `x-amz-checksum-*`, `presigned URL`, `STANDARD_IA`, `GLACIER`,
`DEEP_ARCHIVE`, Azure Blob `Cool`/`Archive`, GCS `Nearline`/`Coldline`/`Archive`.

**Not applicable**: see
- `backup-recovery-standards` (**sister skill; crossover declared on both sides**): object storage
  is today the most common backup **destination** and the one that provides immutability, but it is
  a domain of its own with a life beyond backup (data lake, artifacts, media, static assets, logs).
  **Here Object Lock, versioning, life cycle, classes and cost are explained; there they are
  required** as a requirement of the backup repository, together with GFS retention, `check`, the
  tested restore and the catalog.
  Arbitration rule: if the question is about the **bucket** (policy, lock, class, cost, replication,
  object key), it is ours; if it is about the **copy** (what is copied, with what chain, how long it
  is kept and how the restore is proven), it is theirs.
- `bcdr-standards`: RTO/RPO, recovery order and exercises. **Crossover that matters**: the
  retrieval time of an archive class (§5.2) is an engineering figure from this skill that
  **constrains** an RTO set there; the number is handed back to them, the commitment is not adjusted
  here.
- `aws-standards` / `azure-standards` / `gcp-standards`: S3, Azure Blob Storage and Cloud Storage as
  **managed provider services** — integration with the rest of the catalogue, accounts and
  organisations, platform controls (SCP, Azure Policy, VPC Service Controls), provider billing and
  FinOps. Here, the cross-cutting **object storage model** and the criteria that apply
  equally in all three and in self-hosted implementations.
- `identity-access-management-standards`: identity design, roles, OIDC federation and the
  least-privilege principle as a practice. Here, its concrete application: bucket policy
  versus IAM versus ACL, and a write credential without delete.
- `cryptography-pki-standards`: algorithm choice, key management and rotation in KMS/HSM. Here,
  only the operational decision: provider-managed key versus your own key, and what each one
  protects.
- `secrets-management-standards`: where access keys live and how they rotate; replacing a static
  credential with a short-lived federated identity.
- `privacy-engineering-standards`: personal data in objects — classification, minimisation, erasure.
  **Crossover**: erasure of an object locked by Object Lock in *compliance* mode is
  impossible by design; the resolution (*crypto-shredding*, bounded window) is decided in that skill
  and in `backup-recovery-standards` §3.6. Here only the technical constraint is declared.
- `grc-compliance-standards`: retention as a regulatory obligation and audit evidence; here, the
  mechanism (Object Lock, *legal hold*) that implements it.
- `data-platform-standards`: table and data lake formats (Parquet, Iceberg, Delta), **logical**
  partitioning of the data and query engines. Here, the **key layout** that partitioning
  produces and its effect on listings and requests.
- `kubernetes-standards`: CSI, `PersistentVolume` and object storage consumed from a *pod*
  (including the S3 CSI, which drags along the same problems as §2.2).
- `linux-storage-standards` (**already on disk**): real POSIX blocks and filesystems — LVM,
  ext4/XFS/btrfs, NFS, iSCSI. **The boundary is exactly the antipattern in §2.2**: if you need
  POSIX semantics (atomic rename, random in-place write, `flock`, *hardlinks*), the
  problem belongs to that skill, not this one — do not mount S3.
- `zfs-standards`: pools, datasets and `zfs send`. An object backend does not replace a local pool
  nor the other way round.
- `ceph-standards`: **the RADOS cluster topology, `ceph osd`, the CRUSH map, the pools and the
  protection scheme (replica versus *erasure coding*) are hers**; here S3 as an interface —
  bucket policy, versioning, Object Lock, classes and life cycle— in front of RGW.
- `proxmox-ve-standards` (**already on disk**): Proxmox Backup Server *datastores* over S3 —
  the product and its configuration are hers; the properties required of the bucket (Object Lock,
  versioning, credential, class, cost), ours.
- `networking-standards` and `firewall-policy-standards`: private endpoints, egress and resolution;
  `dns-standards`: bucket names, *virtual-hosted style* and CNAME to the endpoint, and the risk of a
  **dangling subdomain** when a bucket is deleted and its record survives.
- `observability-standards`: metrics, alerts and dashboard design. Here, **what** must be measured.
- `iac-standards`: buckets and policies as code. `cicd-standards`: artifacts and cache in objects.
- `homelab-standards`: object storage in a lab, where the criteria are cost and simplicity and what
  is vetoed here is accepted.

## 2. The model, and the antipattern that dominates the domain

### 2.1 Object versus file

| | File (POSIX) | Object (S3) |
|---|---|---|
| Unit | Mutable file, random in-place write | **Immutable object**: replaced whole, not modified |
| Hierarchy | Real directories | **Flat key**; the `/` is a prefix convention, **not a folder** |
| Rename | Metadata operation, atomic | **Does not exist**: it is copy + delete, with cost, time and a non-atomic window |
| Metadata | `stat`, permissions, owner, xattrs | Headers and *tags*; no uid/gid nor mode unless you emulate them |
| List | Cheap, ordered by directory | **Paginated and billed request**; a prefix with millions of keys is an operational problem |
| Locking | `flock`, `fcntl` | Inter-client locking **does not exist**; the last write wins |
| Cost | Space | **Space + requests + egress**, and all three matter |
| Consistency | The filesystem's | **Strong** read-after-write in S3 since 2020; **versioning and listing have their own nuances** — verify your implementation's model (§8) |

Design consequences that follow directly from the table: do not design flows that depend on
renaming, do not use listing as an index (use a database), do not expect coordinated concurrent
writes, and **pack very small files** into larger objects: a million 4 KB objects
is a request and cost problem, not a space one.

### 2.2 "Mounting S3 as if it were a disk": antipattern

`s3fs`, `goofys`, `rclone mount` and `mountpoint-s3` **translate** POSIX calls to an API that has no
POSIX semantics. What breaks, and why it is not a tool quality problem but one of
impedance:

- **Non-atomic rename** (copy + delete): any "write to `.tmp` and rename" pattern —the
  most common safe-write pattern there is— stops being safe.
- **Random in-place write**: either it does not exist, or it is emulated by rewriting the whole
  object (brutal amplification of I/O and cost).
- **No inter-client locking**: two concurrent writers corrupt without warning.
- **Expensive metadata**: every `stat` is a request. An `ls -l`, a `find` or an `rsync` over a
  mount is a bill and a latency, not a local operation.
- **Failures POSIX does not contemplate**: network cuts, 429/503 and retries show up as I/O errors
  or as mounts that disappear without a record.
- **Misaligned namespace**: S3 keys admit things POSIX does not; there are keys that
  simply **are not visible** from the mount (for example, those containing null bytes), and the
  translation splits on `/`.

**Criteria**:
- **VETOED** for: databases of any kind, backend of a stateful application, user
  home, build destination, workloads with many small files or with concurrent writes.
- **Admissible, bounded and documented**: sequential reading of large objects by processes that
  cannot speak S3 (media ingest, training, read-only ETL), or temporary read-only
  exposure. For that case, **`mountpoint-s3`** (1.23.0, 21 Jul 2026) is the option with the
  most honest contract: **AWS explicitly states that it is not a general-purpose filesystem**,
  optimised for high-throughput reading and sequential writing of new objects from **a single
  client**, and refers you to EFS/FSx if you need real semantics.
- **`s3fs-fuse`** (v1.97, 8 Dec 2025; active repository) is the only one of the three that gives a
  broad POSIX subset and the one that works against non-AWS endpoints, at the cost of being the
  slowest in metadata and with a history of cache problems and mounts that fall over. Use it only
  within the bounded case.
- **`goofys` is dead**: last release **v0.24.0 (April 2020)** and last *push* to the repository
  in July 2024. **VETOED** in new deployments.
- **`rclone mount`** (rclone 1.75.0, 31 Jul 2026, very active project) is acceptable for
  synchronisation and occasional access; **not** as an application's storage.
- The correct alternative is almost always to **speak S3 directly from the application**, or to use
  a real network filesystem (`linux-storage-standards`).

## 3. Default decisions

> Verify version, licence, maintenance status and **real S3 compatibility** on the web before
> committing to them (§8). Data as of **August 2026**, with versions and dates taken from
> `api.github.com` and from the official notes, **never from the HTML render of GitHub Releases**.

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| API | **S3 as the de facto standard**. Everything you write, against the S3 SDK | Proprietary APIs only if they give something S3 does not; portability is worth more than it seems on the day you change provider |
| Managed service versus your own | **Managed by default** (S3, Blob, GCS). You pay for durability, availability and for not operating disks | Self-hosted only with the criteria of §7 |
| Self-hosted, large scale and multi-service | **Ceph RGW** — Tentacle **v20.2.3** (05 Aug 2026); v20.2.0 Nov 2025, v20.2.1 Apr 2026, v20.2.2 Jun 2026. **Squid 19.2.x has an estimated EOL of 31-10-2026**: do not start anything new there. Topology, `ceph osd`, pools and EC in `ceph-standards`. Object Lock in *governance* and *compliance*; in Tentacle, `PutObjectLockConfiguration` **now allows enabling Object Lock on an existing versioned bucket** (previously only at creation) | Real cost: operating Ceph is a job, not a task |
| Self-hosted, small and geo-distributed | **Garage** v2.3.0 (16 Apr 2026), AGPL-3.0, lightweight and honest about its limits | **NO USE AS AN IMMUTABILITY ANCHOR**: it does not implement bucket versioning (`GetBucketVersioning` is a *stub* that answers "not enabled") and therefore **there is no Object Lock**; it does not implement S3 ACLs or policies either (it uses its own per-bucket key model) nor *erasure coding* |
| Self-hosted with a permissive licence | **SeaweedFS** 4.40 (20 Jul 2026), **Apache-2.0** core | **Open-core**: automatic *erasure coding* repair, PITR and OIDC admin are in the per-TB paid Enterprise edition. And there is an **open issue that Object Lock's *compliance* mode does not prevent deletion** (issue #8350, v4.12): **validate WORM in your version before trusting it** |
| **MinIO** | **It is not the default option for a new deployment.** AGPLv3; the administration UI was removed from the Community Edition (Feb 2025 commit, controversy in Jun 2025) and stayed in the commercial **AIStor**; the GitHub project went into **maintenance mode** and **its last release was RELEASE.2025-10-15**, that is, ~9.5 months without publishing as of Aug 2026 | Justifiable only if it is already deployed and operated, or if AIStor is bought with eyes open (starting rate publicly quoted in the order of **$96,000/year up to 400 TB usable** — verify it). There is a *fork* of the browser (OpenMaxIO), which **does not solve** server maintenance. **This is the figure most often quoted from memory and the worst aged: verify it (§8)** |
| CLI | **`aws s3`/`aws s3api`** against AWS; **`rclone`** for synchronisation, migration and multi-provider; **`mc`** only in the MinIO ecosystem | `s3cmd`: legacy, no reason to choose it today |
| Public access | **Blocked by default and at account level**, not only per bucket | Exception: deliberate public distribution, served by a CDN, with the bucket **private** behind it (OAC/OAI or signing), not open |
| Permission model | **Bucket policy + IAM**. **ACLs disabled** (`BucketOwnerEnforced`) | ACLs are de facto being retired: since **April 2023** new S3 buckets are created with BPA enabled and ACLs disabled **by any route** (console, CLI, SDK, CloudFormation). Do not re-enable them |
| Encryption at rest | **Provider-managed by default**; **your own key (KMS/CMEK) when access control over the key is a real control** (separation of duties, revocation, audit) | **SSE-C** only with a strong reason: per-request key management is yours, and losing it is losing the data |
| Encryption in transit | **Mandatory and enforced by policy** (`aws:SecureTransport = false` → `Deny`) | Trusting the client to use HTTPS |
| Immutability | **Object Lock with versioning** (§5.1); *compliance* for the anchor copy, *governance* for the operational one | Without Object Lock there is no real defence against a compromise with valid credentials |
| Versioning | **Enabled on buckets with non-reproducible data**, **always with `NoncurrentVersionExpiration`** | **FORBIDDEN** versioning without an expiration policy: it is a growing bill nobody looks at |
| Multipart | **`AbortIncompleteMultipartUpload` lifecycle rule on every bucket** | Without it, orphan parts are billed indefinitely and **are not visible** in `aws s3 ls` nor in the objects tab |
| Credential | **Short-lived federated identity** (role, OIDC); static only if there is no alternative, with rotation | A permanent access key in the application |
| Backup repository credential | **Write without delete** (`PutObject` yes, `DeleteObject`/`DeleteObjectVersion` no; no `s3:BypassGovernanceRetention`) | See `backup-recovery-standards` §3.4 |

## 4. Buckets and keys

- **A bucket is not a folder**: it is a **boundary of policy, of encryption, of life cycle, of
  versioning, of replication, of logging and often of billing**. A bucket is created when any
  of those properties differs, not to "organise".
- **Naming**: the name is **global** in S3 and appears in DNS. A stable and
  predictable convention (`<org>-<environment>-<domain>-<purpose>-<region>`), in lower case and
  without dots —**dots break TLS with *virtual-hosted style* access***. No guessable names that
  invite *bucket squatting*, and no names that reveal sensitive internal structure.
- **Administrative failure domain**: strong isolation is the **account**, not the bucket. The anchor
  copy of a backup lives in another account (`backup-recovery-standards` §3.4).
- **Keys and prefixes**:
  - The prefix is the only thing the service understands about hierarchy. **Design the prefix for
    the read pattern**, not so that it looks nice in the console.
  - **Time prefix first** (`year/month/day/`) when queries and life cycle are by
    date: it makes lifecycle filtering and range deletion cheap.
  - **High cardinality first** (short hash, tenant id) when the pattern is heavy writing and it
    has to be spread out. In S3 per-prefix scaling is automatic today, but spreading still
    helps and in self-hosted implementations it can be decisive. **Verify your provider's current
    limits (§8) instead of dragging along advice from 2015.**
  - **Listing is the enemy**: `ListObjectsV2` is paginated, billed and slow over huge
    prefixes. If your application lists in order to find something, **you are missing an index** in
    a database. Listing is for inventory and reconciliation, not for serving requests.
  - **No secrets or personal data in the key**: the key appears in access logs, in metrics, in
    URLs and in referrers.
  - **Consistent delimiters**; avoid keys that begin with `/`, that contain `//`, control
    characters or sequences that break translation to a file during a restore.
- **Object and bucket tagging**: bucket *tags* for cost and ownership (owner, environment,
  classification); object *tags* only if you are going to use them in policies or in lifecycle rules
  — they are billed and forgotten.

## 5. Security, immutability and life cycle

### 5.1 Exposure: where the leaks happen

- **Block public access enabled at account level**, in addition to per bucket, and applied by
  organisation policy so that it cannot be disabled without going through governance. Check
  current as of Aug 2026: new S3 buckets are created with **BPA enabled and ACLs disabled**
  since April 2023, by any route; *directory buckets* have BPA fixed and **not modifiable**.
  **This does not save you from old buckets**: the change did not touch existing ones. Auditing the
  old ones is separate work, and it is where the leaks are.
- **Hierarchy of controls**, and why ACLs are superfluous: an ACL is a per-object model, invisible
  in audit, that survives the bucket policy and that produces exactly the classic failure
  ("private bucket, public object"). With `BucketOwnerEnforced` **the problem disappears**: the
  bucket owner owns all the objects and access is governed only with policies. It is the
  default configuration and **it is not reverted**.
- **Bucket policy versus IAM**: IAM says what an identity can do; the bucket policy
  says who can touch the resource and is the right place for the **negative** controls that must
  hold for everybody: deny without TLS, deny without encryption, deny outside the organisation or
  the private endpoint, deny `s3:BypassGovernanceRetention` except to a named role. **An explicit
  `Deny` always wins**: use it for the invariants.
- **Presigned URLs**: **short TTL** (minutes, not days), the smallest possible verb, not reused and
  not recorded in logs — the URL **is** the credential. Watch out for the hard limit: a URL signed
  with temporary credentials **does not survive the expiry of those credentials** even if its own
  TTL is longer. For sustained public download, a CDN with signing, not hand-rolled presigning.
- **Access logging enabled** (access logs or data events), with the destination in **another bucket
  and preferably another account**. Without logging, a per-object exfiltration is invisible.
- **Controlled egress**: on sensitive workloads, a private endpoint and a policy restricting the
  origin — a bucket reachable from anywhere with a leaked key is exfiltration in one `aws s3 sync`.
- **Dangling subdomain**: a CNAME to a bucket that gets deleted lets somebody else claim it. When
  retiring a bucket, retire the DNS record **first** (`dns-standards`).

### 5.2 Immutability and retention

**Object Lock** (WORM), with the detail verified as of Aug 2026:

- **It requires versioning**, and the lock applies to **object versions**, not to keys. Enabling
  Object Lock on a bucket **cannot be undone**.
- ***Governance* mode**: nobody deletes or alters the lock **except** whoever has
  `s3:BypassGovernanceRetention` and sends the `x-amz-bypass-governance-retention` header. It is the
  correct mode for operational data and for **testing** a policy before committing to it.
- ***Compliance* mode**: **nobody** —including the root account— can delete, overwrite, shorten the
  retention or change the mode until it expires. It is the real protection against an attacker with
  administrator credentials, and **it is also an operational and cost risk**: a badly set retention
  (6 years instead of 6 days) is irreversible and is paid for in full. **Mandatory practice: test in
  *governance*, promote to *compliance*.**
- **Minimum retention 1 day, no maximum.** Set the bucket's default retention and do not leave it
  to the client.
- ***Legal hold***: independent of retention, with no date, removed explicitly, and **the life
  cycle does not override it**. Retention and *hold* coexist: if either is active, nothing is
  deleted. It is the mechanism for an investigation or litigation (`grc-compliance-standards`,
  `incident-response-forensics-standards`).
- **On existing objects**: it is applied or extended with **S3 Batch Operations**. In **Ceph RGW ≥
  Tentacle**, `PutObjectLockConfiguration` now allows enabling Object Lock on a versioned bucket
  that was not created with it — previously it forced you to create a new bucket and migrate.
- **Object Lock has been assessed by third parties against SEC 17a-4(f), FINRA 4511 and CFTC 1.31**:
  if that assessment is your compliance justification, verify its currency and its scope
  (`grc-compliance-standards`), do not cite it from memory.
- **Compatibility is not presumed**: there are S3 implementations that expose the Object Lock API
  and **do not enforce it** (a documented and open case in SeaweedFS, §3). If your immutability
  depends on this, **test it**: write, lock, try to delete with an administrator credential and
  check that it fails. That is the §6.4 gate.
- **A constraint to be declared, not dodged**: erasure under the right to erasure **is not
  possible** within an object in *compliance* mode. See `privacy-engineering-standards` and
  `backup-recovery-standards` §3.6: it is resolved with *crypto-shredding* and a bounded window, not
  by editing the copy.

**Versioning**: it is the defence against accidental deletion and overwriting, and **the mechanism
that turns a `DELETE` into a reversible marker**. Two uncomfortable truths:
1. **Versioning without an expiration policy is a growing bill** — all noncurrent
   versions keep occupying space and being billed, indefinitely, and they do not appear in a normal
   listing. Rule: versioning and `NoncurrentVersionExpiration` **are configured in the same change**,
   always.
2. **Versioning is not immutability**: whoever can delete versions (`DeleteObjectVersion`) or
   suspend versioning takes everything. Immutability is given by Object Lock.

### 5.3 Life cycle and storage classes

- **The classic mistake of the domain**: designing with the archive class because it is cheap to
  store and discovering the **retrieval time** during an incident. Current AWS data as of Aug 2026:
  **Deep Archive** typically restores in **~12 h** with *Standard* (9-12 h via S3 Batch Operations,
  with throughput of the order of 1-2 PB/day) and in **~48 h** with *Bulk*. Retrieval prices quoted
  publicly: ~**$0.02/GB** *Standard* and ~**$0.0025/GB** *Bulk* (verify them, §8).
  **Hard rule: if the RTO is shorter than the class's retrieval time, that class is not your
  recovery tier.** That number is handed back to `bcdr-standards`.
- **Hidden costs of retrieval**, all real and all forgotten: the restored object is **temporarily
  copied to a hot class** and that copy is billed for as long as it lasts; the original stays in
  archive; the **minimum storage duration** (180 days in Deep Archive) is paid in full even if you
  delete on day 30; and there is a **per-request cost** for each restored object, which dominates if
  they are millions of small objects.
- **Transition design**: transition by age based on a **measured** access pattern, not an assumed
  one (Storage Lens / class analytics). Small objects do not pay off for a transition (there is an
  effective minimum size and a per-object transition cost): **pack them**.
- **Egress and request cost as a design constraint**: egress between providers
  or to the Internet is the axis that decides entire architectures (and the one that makes leaving
  expensive). A backup repository is designed assuming that **one day it will be read in full**, and
  that day it is billed.
- **Equivalents**: Azure Blob (*Cool*, *Cold*, *Archive*, with rehydration measured in hours and its
  own minimum storage duration) and GCS (*Nearline*, *Coldline*, *Archive*, with no rehydration wait
  but with a retrieval cost and minimum storage durations) **are not interchangeable** with S3 nor
  with each other. **Verify times, minimums and cost of each before designing (§8): they are
  explicitly flagged as a gap in this revision except for what is indicated for AWS.**
- **Lifecycle rules are deployed as code and reviewed**: `put-bucket-lifecycle-
  configuration` **replaces the whole configuration, it does not merge it** — a careless deployment
  deletes existing rules (including the one that aborts multipart). It is a classic silent failure.

## 6. Gates

They break the delivery:

1. **Bucket and policy as code**, with an explicit `Deny` of non-TLS traffic and of writing without
   encryption. Created by hand in the console = finding.
2. **Public exposure scan** in CI and continuously: account-level BPA, ACLs disabled,
   absence of `Principal: "*"` without a condition. Real-time alert on a policy change that
   opens a bucket.
3. **`AbortIncompleteMultipartUpload` present on every bucket**, with a `DaysAfterInitiation`
   greater than the longest legitimate session (7 days is a reasonable default). Verified by
   inventory, not by trust.
4. **Immutability test executed**, not assumed: write an object under Object Lock, try to
   delete it with the most privileged credential available and **check that it fails**. Mandatory on
   any non-AWS implementation.
5. **Versioning and `NoncurrentVersionExpiration` together**, always. Versioning without expiration
   is a gate failure.
6. **Inventory reconciliation**: periodic comparison between what is believed to be there and what
   is there (provider inventory or listing), with detection of incomplete parts and orphan
   versions.
7. **Cost alert per axis**, not only on the total: space, **requests**, egress and archive
   retrieval separately. A spike in requests is an application anomaly or an exfiltration.
8. **Access logging active**, in another bucket and if possible in another account, with defined
   retention.
9. **Recovery test from the cold class**, timed, at least once: the real time is the
   figure, and it usually contradicts the spreadsheet.
10. **Integrity verified end to end** (§7.2): checksum checked on upload and on download,
    not entrusted to the ETag.

## 7. Operation

### 7.1 Replication, migration and tools

- **Cross-region replication**: protects against a regional failure; **it does not protect against
  deletion**, which is replicated too unless configured otherwise, nor against a compromise of the
  account. For backup, what counts is **another administrative failure domain** (another account or
  another provider) plus Object Lock at the destination.
- **Cross-provider replication**: defensible as insurance against whole-provider risk
  (`bcdr-standards`), and expensive in egress. A decision with an ADR and quantified cost, not a
  reflex.
- **Replication is not retroactive** by default: objects predating the rule are not copied without
  an explicit *batch* operation. A very frequent silent failure.
- **`rclone`** (1.75.0, 31 Jul 2026) is the right tool to synchronise and migrate between
  providers. Rules: `--checksum` rather than `--size-only`; **`--dry-run` before any
  `sync`** (which deletes at the destination); `copy` by default and `sync` only when deletion is
  the intent; parallelism and *chunk* size tuned, knowing that parallelism is paid for in
  requests.
- **`aws s3 sync`** for day-to-day work on AWS; **`aws s3api`** when you need fine control (lock,
  versions, checksums). **`mc`** only in the MinIO ecosystem.
- **Large migrations**: count the **requests**, not just the TB; consider the provider's physical
  transfer if the volume justifies it; and validate with **inventory and checksum**, not with "the
  command finished".

### 7.2 Multipart and integrity

- **Multipart is mandatory above the SDK's threshold** and desirable for large objects: it allows
  parallelism and per-part retry. Its residue is the problem.
- **Incomplete parts: rubbish that is billed and not visible.** They are stored and charged at the
  rate of the class indicated when uploading them, indefinitely, and **they do not appear in
  `aws s3 ls` nor in the console's object list**. In archive they are billed as *staging* at the hot
  rate. The control is the lifecycle rule (§6.3) and the Storage Lens metric
  (`IncompleteMultipartUploadStorageBytes`, daily update).
- **ETag: classic trap.** The ETag **is not necessarily the object's MD5**; in multipart it is a
  composite (hash of hashes with an `-N` suffix) that depends on the **part size used**, so two
  identical copies uploaded with different part sizes have different ETags. **VETOED to use the
  ETag as proof of integrity or as a comparison criterion between sources.**
- **Checksums, which is what does work**: use additional checksums (`x-amz-checksum-*`). Status
  verified as of Aug 2026: if none is specified, S3 applies **CRC-64/NVME** by default and computes
  the full-object checksum when the upload finishes. In multipart, **`COMPOSITE` or
  `FULL_OBJECT`** is declared in `CreateMultipartUpload` (`FULL_OBJECT` only with CRC algorithms, and
  in that case no per-part algorithm is sent); a mismatch returns **`BadDigest`**. With an additional
  per-part checksum, part numbers must **start at 1 and be consecutive** or you get
  **`InvalidPartOrder`**.
- **End-to-end verification**: the producer computes and stores the content's checksum; the
  consumer checks it after downloading. The provider's check covers transport and
  storage, it does not cover you having uploaded the wrong file.

### 7.3 Observability and cost

- **Measure requests, not just space.** It is the most expensive operational lesson of the domain:
  the bill of a bucket with many small objects is dominated by `GET`/`PUT`/`LIST`, not by the GB.
- Minimum series: bytes per class, number of objects, **requests by type**, 4xx/5xx error rate,
  **429/503 and retries** (they indicate poor spreading or a rate limit), p50/p99 latency, **egress
  bytes**, bytes in incomplete parts, bytes in noncurrent versions, and **archive retrieval cost**.
- **Useful alerts**: a spike in `GET` or in egress outside the pattern (exfiltration or a client
  loop), growth in noncurrent versions (the expiration is missing), growth in incomplete parts (the
  abort rule is missing), the appearance of `Principal: "*"`, and replication failure with growing
  lag.
- **Cost per bucket and per owner**, via tagging, or the FinOps conversation is impossible.
- **Reconciliation with the provider's inventory** (daily inventory report) instead of massive
  listings: listing millions of objects to know what is there is expensive and slow.

### 7.4 On-premise: when to run your own

Running your own object storage is a **permanent operational commitment**, not a deployment. It is
only justified with at least one of these reasons, written in an ADR:

- **Sovereignty or a legal requirement** that rules out the provider.
- **Volume and pattern** where egress and request cost dominate and there are people to operate it.
- **Latency or adjacency** to local compute.
- **Already amortised hardware** and already existing operational capability.

And what it really implies:

- **Erasure coding versus replica**: EC gives space efficiency (typically 1.3-1.5x versus 3x
  for triple replication) in exchange for CPU, latency and **expensive rebuilds**. Replication is
  simple and fast to rebuild. The decision depends on object size and access profile, and it is one
  of the hard ones to change afterwards.
- **Explicit failure domains**: the distribution scheme must spread across node, rack and
  power feed, not only across disks. An EC that survives two disks but not a rack **does not protect
  against what actually fails**.
- **Durability is continuous work**: *scrub*, silent corruption detection, disk
  replacement and control of rebuild time, which grows with disk capacity and is when
  the cluster is vulnerable.
- **Upgrades and compatibility**: a self-hosted S3 API is **never 100 % compatible**. Test
  with **your** client and **your** features —Object Lock, versioning, policies, lifecycle, multipart,
  checksums— before committing. It is exactly where Garage falls short and where SeaweedFS has an
  open issue (§3).
- **Honest comparison**: the hardware cost is the easy part. Add energy, space,
  replacement, **staff with on-call**, upgrades, and the fact that the durability and
  availability you achieve will not be the provider's. If the result comes out similar, **pay for
  the service**: the "it is cheaper" argument almost never survives counting the staff.
- **And even with your own object storage, the anchor copy still needs another administrative
  failure domain** (`backup-recovery-standards` §3.4). Your MinIO/Ceph in the same data centre is
  not the offsite copy.

## 8. Sustainability and prohibitions

**Cadence**: half-yearly review of versions, licences and maintenance status of the
self-hosted implementation (§9); quarterly review of bucket policies and public exposure;
annual review of lifecycle rules against the real access pattern and against the bill;
checking the immutability test after every major backend upgrade.

**FORBIDDEN**
- ❌ Mounting S3 as a filesystem for a database, a stateful backend, a home directory or a build.
- ❌ Using `goofys` in anything new (dead since 2020/2024).
- ❌ Depending on atomic rename, random in-place write or inter-client locking over objects.
- ❌ Using listing as the application's index.
- ❌ Disabling block public access, or re-enabling ACLs, without a documented and reviewed decision.
- ❌ `Principal: "*"` without a restrictive condition in a bucket policy.
- ❌ A bucket without a `Deny` of non-TLS traffic.
- ❌ Versioning without `NoncurrentVersionExpiration`.
- ❌ A bucket without an `AbortIncompleteMultipartUpload` rule.
- ❌ Using the **ETag** as proof of integrity or to compare objects across sources.
- ❌ Trusting the immutability of an S3 implementation **without having tested** that deletion fails.
- ❌ Anchoring the immutability of a backup on **Garage** (it has no versioning, therefore no Object
  Lock) or on **SeaweedFS** without validating *compliance* mode in your version.
- ❌ Deploying **MinIO** on a new system without having verified its maintenance status and its
  current commercial model (§9).
- ❌ Applying Object Lock in *compliance* mode without having first tested the policy in
  *governance*.
- ❌ Designing with an archive class without knowing and measuring its **retrieval time**, its
  minimum storage duration and its retrieval cost.
- ❌ Presuming that replication protects against deletion, or that it is retroactive.
- ❌ Presigned URLs with a long TTL, reused or recorded in logs.
- ❌ Secrets or personal data in the bucket name or in the object key.
- ❌ Deleting a bucket without first retiring its DNS record (dangling subdomain).
- ❌ Deploying `put-bucket-lifecycle-configuration` without knowing that it **replaces** the whole
  configuration.
- ❌ Watching only space and not **requests** or egress.
- ❌ Running your own object storage without an ADR, without on-call staff and without an S3
  compatibility test with your real client.
- ❌ Stating versions, licences, prices, retrieval times or service behaviour **from memory**
  (§9).

## 9. Mandatory web verification

Before committing to any version, licence, price, timing or behaviour, **search for it — do not
remember it**. **Methodological warning**: every GitHub date or version must come from
**`api.github.com` or the Atom feeds**, never from the HTML render of the Releases page.

1. **MinIO** — the most volatile and worst-remembered figure of the domain. Verified as of Aug 2026:
   AGPLv3; administration UI removed from the Community Edition (Feb 2025 commit, public
   controversy in Jun 2025) and available only in the commercial **AIStor** (rate publicly quoted in
   the order of $96,000/year up to 400 TB usable); GitHub project declared in **maintenance mode**;
   **last release `RELEASE.2025-10-15T17-29-55Z`**, confirmed via `api.github.com` — ~9.5 months
   without publishing. There is the OpenMaxIO browser *fork*. **Check whether there have been new
   releases, whether maintenance mode still holds, and which additional features have been moved to
   AIStor** before recommending or discarding it.
2. **Ceph RGW**: current stable version (as of Aug 2026, **Tentacle v20.2.3**, 05 Aug 2026, with an
   estimated EOL of 01-06-2027; Squid 19.2.x dies on 31-10-2026), and the status of
   Object Lock —including the Tentacle novelty of being able to enable it on an existing versioned
   bucket— and of the fix for `RetainUntilDate` beyond 2106 (**it does not repair locks already
   written**).
3. **Garage** (v2.3.0, 16 Apr 2026, AGPL-3.0): confirm in its **official S3 compatibility table**
   whether it still lacks bucket versioning, Object Lock, S3 ACLs/policies and *erasure coding*.
   These limits change between versions and they are what decides whether it works for your case.
4. **SeaweedFS** (4.40, 20 Jul 2026, Apache-2.0 core): status of the issue about Object Lock's
   *compliance* mode (issue #8350 on v4.12, deletion still succeeding) and what remains
   exclusive to the per-TB paid Enterprise edition (automatic EC repair, PITR, OIDC admin).
5. **S3 Object Lock**: current modes, real limits, `s3:BypassGovernanceRetention`, minimum and
   maximum retention, application to existing objects via Batch Operations, and the scope and
   currency of the assessment against SEC 17a-4(f) / FINRA 4511 / CFTC 1.31.
6. **Providers' default behaviour**: verified as of Aug 2026 that S3 still creates new
   buckets with **Block Public Access enabled and ACLs disabled** (`BucketOwnerEnforced`)
   since April 2023, by any route, and that *directory buckets* have it fixed. **Check whether
   it has changed, and check the Azure and GCP equivalents — not verified in this revision.**
7. **Cold and archive classes**: verified as of Aug 2026 for AWS **Deep Archive**: *Standard* ~12 h
   (9-12 h with S3 Batch Operations, of the order of 1-2 PB/day), *Bulk* ~48 h, minimum storage
   duration 180 days, retrieval cost quoted in secondary sources at ~$0.02/GB (*Standard*) and
   ~$0.0025/GB (*Bulk*). **Cross-check the prices against the official S3 pricing page before using
   them**. **Declared gap**: not verified in this revision are the times, minimums and costs of
   **Azure Blob Archive** (rehydration) or of **GCS Coldline/Archive**, nor the current egress cost
   of any provider.
8. **Mounting**: status and contract of **`mountpoint-s3`** (1.23.0, 21 Jul 2026; AWS states that it
   is not a general-purpose filesystem), **`s3fs-fuse`** (v1.97, Dec 2025, active repo) and
   **`rclone`** (1.75.0, 31 Jul 2026). Confirmed as of Aug 2026 that **`goofys` is abandoned** (last
   release v0.24.0 from April 2020, last *push* in July 2024).
9. **Per-prefix performance and rate limits** of your provider: the advice to randomise the
   prefix comes from an old model. Check the current limits in the official documentation instead
   of dragging along recipes.
10. **Integrity**: current behaviour of default checksums (as of Aug 2026, **CRC-64/NVME**
    when none is specified), the `COMPOSITE`/`FULL_OBJECT` distinction in multipart and the
    `BadDigest` and `InvalidPartOrder` errors.
11. **Supply chain incidents** of any tool or image you recommend (`rclone`,
    `mc`, S3 clients, MinIO/Ceph/Garage/SeaweedFS images), in their advisory channels. Precedents
    from the catalogue that justify checking: the compromise of **Trivy** (March 2026), the 2026
    wave against repositories and GitHub Actions (Nx / CVE-2026-48027 in CISA's KEV, the
    "Megalodon" campaign, *Miasma*). **Declared gap**: the CVE history of Ceph RGW,
    Garage and SeaweedFS has not been reviewed in this pass.
12. **Consistency model** of your specific implementation (listing, versioning, replication): S3
    gives strong read-after-write since 2020, but **self-hosted implementations and listing nuances
    vary**. Do not take it for granted.

If you cannot verify, **say so explicitly instead of assuming**.
If the web contradicts this document, **the web wins** — flag the discrepancy.
