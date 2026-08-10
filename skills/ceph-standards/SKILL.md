---
name: ceph-standards
description: Ceph as distributed storage — the RADOS cluster, its daemons and the decisions that decide whether it survives. Use when running ceph -s / ceph health detail / ceph df / ceph osd tree / ceph osd dump / ceph pg / ceph balancer / ceph orch / ceph telemetry, bootstrapping or operating a cluster with cephadm (cephadm bootstrap, ceph orch apply, ceph orch upgrade start, service specs) or with Rook (CephCluster, CephBlockPool, CephFilesystem, CephObjectStore CRDs), sizing MON quorum and MGR/MDS standbys, editing a CRUSH map or crush rule and choosing the failure domain (osd/host/rack), deciding replicated size=3 min_size=2 versus an erasure-coded profile (k+m, allow_ec_overwrites, allow_ec_optimizations), pool creation and pg_num with the PG autoscaler (pg_autoscale_mode, mon_target_pg_per_osd, noautoscale, bulk), BlueStore OSDs and block.db/block.wal offload sizing with ceph-volume or ceph-bluestore-tool, RBD images and rbd create --data-pool, CephFS with max_mds and standby-replay, RGW daemon placement, mon_osd_nearfull_ratio / backfillfull / full_ratio and a cluster that stopped accepting writes, scrub and deep-scrub tuning, msgr2 crc versus secure mode and cephx keyrings, per-OSD latency and slow ops, stretch clusters and tiebreaker monitors, upgrading between named releases (Squid, Tentacle), or deciding whether Ceph is the right answer at all instead of ZFS or NFS.
---

# Ceph standards — RADOS distributed storage

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: Ceph is not "a NAS that scales". It is a **distributed system with consensus**
> (Paxos in the monitors) on which everything else rests. Two consequences govern the rest of this
> document: **if the monitor quorum falls, the entire cluster stops serving even though all the
> data is intact**, and **a full cluster cannot be emptied**, because recovering and rebalancing
> require writing. Most Ceph disasters are not disk losses: they are quorum and capacity.

## 1. Scope and triggers

Applies to the **RADOS cluster and its operation**: daemon architecture and its sizing, monitor
quorum, CRUSH map and failure domains, protection scheme (replication versus *erasure
coding*), pools and *placement groups*, BlueStore and metadata offload, the three interfaces
(RBD, CephFS, RGW) and when each one fits, network, deployment method, upgrading between named
releases, *scrubbing*, capacity management, latency observability, and the criteria for
**when not to deploy Ceph**.

Triggers: `ceph -s`, `ceph health detail`, `ceph df`, `ceph osd tree`/`dump`/`df`,
`ceph osd crush`, `ceph osd pool create`/`set`, `ceph pg`, `ceph balancer`, `ceph orch`,
`cephadm bootstrap`, `ceph-volume`, `ceph-bluestore-tool`, `rbd`, `ceph fs`, `radosgw-admin`
(as a daemon, not as an S3 API), `ceph.conf`, `keyring`, `mon_osd_full_ratio`, `pg_autoscale_mode`,
`allow_ec_overwrites`, `min_size`, `HEALTH_WARN`/`HEALTH_ERR`, `nearfull`, `slow ops`,
`CephCluster`/`CephBlockPool`/`CephFilesystem` (Rook CRDs), `pveceph`.

**Not applicable**: see `object-storage-standards` (**sibling boundary and the thinnest one**: the
**S3 object as an interface** —bucket policy, versioning, Object Lock, lifecycle, classes, presigned
URLs, multipart, checksums, cost per request— is **theirs**, including RGW seen from the
client. **Here, RGW as a daemon**: how many, where they are placed, on top of which pools —replicated
index on flash, data on EC—, its `block.db` consumption through *omap*, and its place in the
upgrade order. Arbitration rule: **if the question is answered with an S3 call, it is theirs; if it is
answered with `ceph osd pool` or `ceph orch`, it belongs here**), `linux-storage-standards` (the local
disk and its block stack: LVM, multipath, NVMe, ext4/XFS, LUKS, `fio`, `iostat`. **The boundary
is the OSD**: the raw device and its latency are theirs; what BlueStore does on top belongs
here — and **Ceph wants the raw disk behind an HBA in IT mode**, not an LV on top of a hardware
RAID), `zfs-standards` (**the honest alternative**: for a single host, or two with asynchronous
replication, ZFS is simpler, faster and cheaper to operate. §2.1 sets out when Ceph loses that
comparison), `proxmox-ve-standards` (**Ceph packaged by Proxmox**: `pveceph`, its integration
with `storage.cfg`, the PVE↔Ceph upgrade order and the 3-node minimum it documents. Here the
criteria for Ceph *as Ceph*, which do not change just because it comes packaged; §3.7 declares what is lost by
that route), `ha-clustering-standards` (**Pacemaker/Corosync, fencing and the quorum of a service**.
Boundary: **Ceph's monitor quorum is not the Corosync quorum and they are not solved with the
same tools** — Ceph does not use STONITH; its equivalent is marking an OSD `down`/`out` and the
`nearfull`. If the question is "how do I stop two nodes writing at the same time to the same LUN?",
it is theirs), `kubernetes-standards` (the K8s cluster, its admission and its workloads; **Rook is the
operator that runs Ceph inside K8s** and its deployment belongs here, but the StorageClass, the
PVC and the CSI as seen by the pod are theirs), `backup-recovery-standards` (**replication is not a copy**:
`size=3` does not protect against a `rados rm`, against ransomware with the admin keyring nor against a
`ceph osd pool delete`. The copy and its tested restore are theirs), `bcdr-standards` (RTO/RPO,
recovery order, drills; the *stretch cluster* of §3.6 is a mechanism, not a plan),
`onprem-standards` (platform umbrella and routing), `server-hardware-standards` (BOM, HBA in
IT mode, SSD endurance, BMC), `networking-standards` (VLAN, MTU, bonding, switches; here
only the network **requirement** Ceph imposes), `observability-standards` (Prometheus, rules and
dashboards; here **what** to watch), `cryptography-pki-standards` (algorithms and key custody;
here only the use of cephx and of msgr2's `secure` mode), `secrets-management-standards` (where
the `client.admin` keyring lives), `linux-hardening-standards` (CIS baseline of the host that hosts
the daemons), `vulnerability-management-standards` (triage and SLA for Ceph CVEs),
`finops-standards` (cost per usable TB versus alternatives), `air-gapped-standards`
(the internal container registry from which `cephadm` pulls the images in an environment with no
Internet egress, and the signature that is verified on the isolated side).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

### 2.1 The prior decision: Ceph or not?

| Situation | Answer | Reason |
|---|---|---|
| A single host, or two with an RPO of minutes | **ZFS + replication** | Ceph with fewer than 3 nodes has no real fault tolerance and does have all of its complexity |
| You need shared POSIX between a few clients | **NFS over ZFS** | CephFS solves the same problem with an MDS, a metadata pool and an entire operational learning curve |
| 3-4 nodes, with no part-time assigned owner | **No Ceph** | The dominant cost is not the hardware, it is **who maintains it**. With no owner, the cluster reaches `nearfull` without anyone looking |
| You need the **three** interfaces (block, file and object) on the same hardware | **Ceph** | This is its real structural advantage, and no free alternative has it |
| Incremental growth by nodes, with no array and no migration window | **Ceph** | Adding capacity without stopping and without re-platforming is its other real advantage |
| Kubernetes that needs RWX and dynamic block storage on premises | **Ceph via Rook** | The standard answer; simpler alternatives only if the RWX requirement does not exist |

**Honest criteria**: Ceph is over-engineering below ~5 nodes and ~100 TB usable, unless
the reason is *learning* or operational experience already exists in-house. Above ~1 PB or
with continuous growth, the alternative ceases to exist.

### 2.2 Versions and lifecycle

| Item | Verified status (Aug 2026) | Criteria |
|---|---|---|
| **Tentacle (v20.2.z)** | Initial release **2025-11-18**; latest point release **20.2.3** (2026-08-05); **estimated EOL 2027-06-01** | **Default for new deployments.** Brings `allow_ec_optimizations` (§3.3) |
| **Squid (v19.2.z)** | Initial **2024-09-26**; latest **19.2.5** (2026-07-14); **estimated EOL 2026-10-31** | Supported, but **less than three months from EOL**: if you are here, the upgrade to Tentacle is already in the plan, not in the backlog |
| Reef (18.2.z), Quincy (17.2.z) and earlier | **Archived**: Reef EOL 2025-03-20, Quincy EOL 2025-01-13 | No backports and no security patches. Running Reef in production today is security debt, not feature debt |
| Licence | **LGPL-2.1 or LGPL-3** (verified in the `COPYING` file of `ceph/ceph`, `main` branch) | No source-available clause and no relicensing; the licence risk here is nil |
| Rook | **Apache-2.0** (`LICENSE` file, `master` branch) | |

**On "the annual cycle"**: the documentation states a stable cycle that is **annual, targeting March**, with
support of ~24 months (two cycles) and **rolling upgrade supported from the last two stable
releases**. The reality of the dates does not meet that target: Squid came out in September 2024 and
Tentacle in November 2025. **Plan against the EOL date published in the release index,
not against "March"**, and do not skip more than two releases: doing so forces a staged upgrade
and a reinstall.

### 2.3 Data protection

| Use | Default | Justifiable alternative |
|---|---|---|
| RBD (VMs, containers) | **Replication `size=3`, `min_size=2`** | EC only if it has been measured; see §3.3 |
| CephFS metadata | **Replication 3, on flash** | Never EC. Never HDD |
| CephFS / RGW cold and large data | **EC 4+2** (or 6+3 with enough failure domains) | Replication 3 if latency rules |
| RGW index and `.log`/`.meta` pools | **Replication 3, on flash** | Never EC |

`min_size=1` **is forbidden** (§7): it allows writes to be served with a single live copy and turns
the next failure into data loss. On EC pools, the documented recommendation is
**`min_size` ≥ k+1**.

## 3. Structure and conventions

### 3.1 Daemons and quorum — the point that decides survival

- **MON** (`ceph-mon`): the source of truth for the maps, with Paxos-style consensus. **The cluster
  lives if and only if a strict majority of monitors is active and sees each other.** 3 monitors
  tolerate 1 failure; **4 also tolerate only 1** (which is why an even number buys nothing and does add
  surface); 5 tolerate 2. Documented: at least 3 in production, **always an odd number**.
- **Design consequence, non-negotiable**: monitors are spread across different failure domains
  (rack, chassis, UPS, switch). Three monitors in the same rack are a single-rack
  cluster, no matter how many OSDs are spread around. Verified requirements: ≥2 cores, **≥5 GiB RAM per
  daemon**, **100 GB per daemon on SSD** (the MON's rocksdb base grows during rebalancing, and
  a MON that runs out of disk takes down the quorum).
- **MGR** (`ceph-mgr`): modules, dashboard, metrics and orchestrator. **Always ≥2** (active +
  standby); the upgrade is blocked (`UPGRADE_NO_STANDBY_MGR`) if there is no standby.
- **OSD** (`ceph-osd`): one per device. Verified: **≥4 GB RAM per daemon** (more is better;
  less than 2 GB is not recommended), 1 thread minimum / 3 recommended per HDD OSD, 4 / 6 per NVMe.
  Devices below **1 TiB** are discouraged; PCIe Gen4+ NVMe **above 30 TB**
  may be split into two or more OSDs.
- **MDS** (`ceph-mds`): only if there is CephFS. ≥2 cores (frequency over count), **≥8 GiB
  RAM**. `max_mds` is the number of active *ranks*; **the practical maximum on an HA system is one
  less than the number of MDS daemons**, because you need at least one standby for every rank you
  want to be able to lose.
- **RGW** (`radosgw`): stateless, scaled by number of instances behind a load balancer.

**Placement**: MON, MGR and MDS can coexist with OSDs on modest clusters, but **a MON
competing for IOPS with an OSD on the same disk is a classic root cause of spurious
elections**. Separate disk for the MON, always.

### 3.2 CRUSH and the failure domain that is not the one you think

- CRUSH determines placement with no central table: that is what allows growth. The parameter that
  decides real resilience is the **failure domain of the rule**: `host` spreads each replica
  onto a different host; `rack`, onto a different rack.
- **The most common design flaw**: leaving the domain at `host` on a cluster that is already spread
  over several racks or several chassis. With `size=3` and domain `host`, **the three replicas can end up
  in the same rack**: you lose the rack and you lose the pool. And the other way round: setting domain `rack` with fewer
  than 3 racks leaves PGs permanently `undersized`, because CRUSH cannot satisfy the rule.
- Operational rule: **the failure domain must be the level of which you can lose one whole
  unit**, and the number of *buckets* at that level must be ≥ `size` (or ≥ `k+m` on EC;
  **k+m+1 is the correct planning figure**, so you can rebalance with a domain down).
- The CRUSH hierarchy is declared explicitly (`ceph osd crush move`, or `location` in the cephadm
  spec). **A CRUSH map that does not reflect the real cabling is a lie in tree format**:
  check it against the physical inventory, not against the diagram.
- Device classes (`hdd`, `ssd`, `nvme`) to steer pools to different media; the balancer
  (`ceph balancer`) in `upmap` mode to spread PGs. An unbalanced cluster reaches `nearfull`
  because of the fullest OSD, not because of the average — **usable capacity is set by the fullest OSD**.

### 3.3 Replication versus erasure coding

- **EC is not "cheap RAID"**: every write touches `k+m` OSDs and every degraded read requires
  reconstruction. Below the stripe size, **a small write becomes a distributed
  read-modify-write**: that is where EC ruins performance.
- **By default, EC does not accept partial writes.** For RBD, CephFS and librados you have to enable
  `allow_ec_overwrites true` on the pool, **only possible on BlueStore OSDs** (BlueStore's
  checksum is what detects bitrot during the *deep scrub*).
- **RBD and CephFS are not fully supported on EC**: metadata goes on a replicated
  pool and only the data on the EC one (`rbd create --data-pool ec_pool replicated_pool/img`;
  on CephFS, default data pool or *file layouts*).
- **From Tentacle onwards**: `allow_ec_optimizations true` improves small I/O and eliminates *padding*,
  reducing space amplification. It requires **all MONs and OSDs already on Tentacle**, it can be
  enabled on existing pools and **it cannot be disabled** once active. Only with the Jerasure
  and ISA-L plugins.
- Profiles: the documentation recommends **not going beyond `k>4` or `m>2`** without understanding the impact;
  **`m=1` is strongly discouraged in production** (unavailability during maintenance and
  data loss on overlapping failures). If you do not know which to choose: **4+2 or 6+3**. `k>8`
  discouraged in most cases.
- Since Octopus an EC pool recovers with **k** shards available (below k there is already loss),
  but `min_size = k+1` is recommended so as not to lose writes.

**Criteria**: EC for RGW and for CephFS with large sequential objects. **For RBD, replication 3
unless you have measured your own I/O pattern** — the space saving is paid for in write
latency and, above all, in recovery time.

### 3.4 Pools and PGs

- **Autoscaling enabled** (`pg_autoscale_mode on`) is the sensible default; `warn` if you prefer
  to decide the jumps yourself. `off` only with judgement and with the calculation done.
- Target per OSD: `mon_target_pg_per_osd`, **default 100**; the documentation itself recommends
  **200 for everything except the smallest deployments**, and warns that **above 500 there is excessive
  peering traffic and RAM consumption**. With more than 50 OSDs, 100-250 PG replicas per
  OSD.
- Mark `bulk` on pools that are going to be large: without it the autoscaler starts with few PGs
  and the pool suffers as it grows.
- **During an upgrade, the autoscaler is paused** (cephadm does it by itself unless you enable
  `mgr/cephadm/pg_autoscale_during_upgrade`). A PG *split* halfway through an upgrade can add
  days on a large cluster.
- One pool per purpose, with a name that says what it serves. **Never** `rados bench` against a production
  pool without deleting the `bench*` objects afterwards: they are a documented cause of `OSD_FULL`.

### 3.5 BlueStore and metadata sizing

- BlueStore talks directly to the block device; **Filestore is obsolete** and any OSD left
  on Filestore is migrated.
- With hybrid HDD+SSD OSDs, `block.db` (which absorbs the `wal`) goes on the fast device.
  **Verified sizing (current documentation)**: **≥2.5 %** of the slow `block` size —the
  figure dropped because since Squid RocksDB compresses—, **≥4 % for RGW** (because of the volume of
  *omap* keys), and **1-2 % is enough for RBD**. The folkloric "always 4 %" rule over-provisions the
  NVMe on RBD workloads and under-provisions it on none.
- Ratio of OSDs per offload device: **4-5 HDD OSDs per SATA SSD**, **≤15 per NVMe**. That
  device is a **failure domain**: if it dies, every OSD that depends on it dies. Count it
  in the CRUSH design.
- With no mix of fast and slow media **no separate LVs are created**: BlueStore colocates by itself.

### 3.6 Network

- **Against the folklore**: the current documentation **does not recommend separating public and
  cluster networks by default**. It says Ceph works well with a single public network, especially at **25 GE or
  more**, and that the second network "complicates configuration, cost and management and often has no
  significant impact on performance". The firm recommendation is a different one: **active/active bonding against
  redundant switches** (or L3 multipath with FRR), with the right *hash policy* (usually
  L2+3 or L3+4 — a badly chosen one leaves a fraction of the bandwidth unused).
- Minimum: **10 Gb/s** between hosts and towards clients; **25 Gb/s** with substantial load; 100 Gb/s on
  dense nodes. Reference for why: replicating 10 TiB takes **30 hours at 1 Gb/s and 3 hours at
  10 Gb/s**; that time is the window in which a second failure costs you the data.
- Dedicated cluster network **only** if the link is slow by modern standards (1 GE, or 10 GE on
  dense/SSD nodes) and you cannot extend the bonding. If you do add it: each node needs an extra interface or VLAN
  and **you double the network failure surface** — a cluster network down with the public one
  up produces a cluster that sees itself but cannot replicate.
- Daemons bind by default in the range **6800:7568**; filtering must allow it between
  all nodes (`firewall-policy-standards` for the policy).

### 3.7 Deployment: cephadm, Rook or Proxmox's Ceph

| Route | When | What is lost |
|---|---|---|
| **cephadm** | **Default on bare metal.** The only method with full integration of the orchestration API, CLI and dashboard; supports Octopus and later | Requires containers (Podman or Docker) and **SSH to all nodes with a privileged key** — that is its trust model, treat it as Tier 0 |
| **Rook** | **The only recommended method for Ceph inside Kubernetes**, and also for connecting K8s to an external Ceph cluster | The storage lifecycle ends up coupled to that of the K8s cluster. A K8s cluster that is rebuilt "because it is ephemeral" cannot be the one that hosts the persistent storage |
| **Proxmox's Ceph (`pveceph`)** | When there is already a PVE cluster and the storage is for its VMs | It is real Ceph, but **the calendar is set by Proxmox**: the packaged version, not the one you want. The PVE upgrade and the Ceph one **are two separate projects and in a documented order**. Outside the PVE ecosystem it is useless |
| Ansible, Salt, Juju, Puppet, manual | Legacy or very specific requirements | No integrated orchestrator: `ceph orch` does not work, the dashboard loses capabilities and every operation becomes manual again |

### 3.8 Stretch and multi-site

- A cluster stretched between two data centres **needs a tiebreaker monitor at a third
  site**: with monitors at only two sites, a network partition leaves both without a majority. The
  third site can be much smaller, but **it has to exist and be independent**.
- Inter-site latency enters the synchronous write path. Stretching a cluster is not DR:
  it is a single, larger logical failure domain. For real DR, see `bcdr-standards`; for
  asynchronous object replication, RGW *multisite* is decided in `object-storage-standards`.

## 4. Verification before production

In order of increasing cost; none is optional for a cluster that is going to carry real data.

1. `ceph -s` at `HEALTH_OK` **with no muted warnings**, and `ceph health detail` read in full.
2. `ceph osd tree` checked against the **physical inventory**: every host in its real rack.
3. **Failure domain test**: power off a whole host (and then a rack, if the design declares it)
   and check that the cluster keeps serving I/O and that it recovers to `active+clean` on its own.
4. **Quorum test**: stop one monitor, check service; for two out of three, check that the
   cluster **stops** — and that you know how to recover it. An operator who has not seen a cluster without
   quorum will see one for the first time in production.
5. **Capacity test**: fill a test pool up to `nearfull` in a disposable environment and
   run the procedure from §6.2. Time it.
6. Benchmark with **your** pattern (`fio` from the client, not `rados bench` from the node). Vendor
   IOPS figures and those in Ceph *whitepapers* **are not a commitment**: they depend on the
   medium, on the EC profile, on the block size and on the number of clients. **If you have not measured it yourself, it
   is not a number, it is an expectation.**
7. `ceph telemetry` is opt-in: decide consciously whether you enable it (it helps the project, it sends data
   out). In an isolated environment, it cannot be enabled.

## 5. Security

- **cephx is active by default** and provides mutual authentication. The `client.admin` keyring is
  **equivalent to root over all the cluster's data**: off the client nodes, in a
  secrets manager, and with keyrings scoped by capability (`mon 'profile rbd'`,
  `osd 'profile rbd pool=...'`) for each consumer.
- **Data traffic is not encrypted by default.** msgr2 has two modes: `crc` (strong
  authentication + integrity, **no secrecy**) and `secure` (full encryption with AES-GCM). The verified
  defaults are `ms_cluster_mode = crc secure`, `ms_service_mode = crc secure`,
  `ms_client_mode = crc secure` — and since **the first in the list is preferred**, in practice the
  traffic between daemons and with clients goes in **crc, that is, in the clear**. Only the monitors
  reverse the order (`ms_mon_cluster_mode = secure crc`). If the Ceph network is not trusted,
  **set `secure` explicitly** and measure the cost; if you leave it at `crc`, let that be a written
  decision, not an oversight.
- **MGR dashboard and API never exposed** outside the management network; TLS mandatory; no
  default credentials. RGW is exposed, and its surface (S3, policies, presigned URLs)
  is hardened with `object-storage-standards`.
- `cephadm` keeps an SSH key with privileged access to all nodes: it is Tier 0 material.
  Rotate and audit its use.
- CVEs: Ceph publishes its own advisories; subscribe to `ceph-announce` and handle them in the
  `vulnerability-management-standards` flow. **Running an archived release means not receiving the
  patch** (§2.2).

## 6. Operability

### 6.1 Scrub and deep scrub

Verified default values: `osd_max_scrubs` **3**, `osd_scrub_min_interval` **1 day**,
`osd_scrub_max_interval` **7 days**, `osd_deep_scrub_interval` **7 days**,
`osd_scrub_load_threshold` **10.0**, `osd_scrub_during_recovery` **false**.

- The light *scrub* compares size and attributes; the **deep scrub reads all the data and verifies
  checksums**: it is what detects bitrot, and it is the reason EC with *overwrites* requires
  BlueStore.
- Bound the window with `osd_scrub_begin_hour`/`end_hour` if the scrub interferes with the load. **What
  is forbidden is disabling it** (permanent `nodeep-scrub`): a cluster with no deep scrub does not
  know whether its data is sound, and it finds out when recovery fails.
- A sustained `PG_NOT_DEEP_SCRUBBED` means that **there is not enough time**: either there is too much data for
  the hardware, or the window is too narrow. It is a capacity signal, not noise to be
  muted.

### 6.2 Capacity — the classic operational failure

Verified default thresholds: `mon_osd_nearfull_ratio` **0.85**, `mon_osd_backfillfull_ratio`
**0.90**, `mon_osd_full_ratio` **0.95**.

- **Documented trap**: those three parameters **are only applied at cluster creation** and
  afterwards live in the OSDMap. Changing them in `ceph.conf` or in the central config **does nothing**;
  you have to use `ceph osd set-nearfull-ratio` / `set-backfillfull-ratio` / `set-full-ratio`.
- The disaster sequence: an OSD crosses `full` → **the cluster stops accepting writes** →
  to recover you need to write → you are blocked. And before that, at `backfillfull`, **rebalancing
  can no longer complete**, which is the warning that recovery does not fit.
- **Sizing rule, not a monitoring one**: the design usable capacity is the one that leaves
  room for **the loss of the largest host to be recovered without crossing `nearfull`**. On a cluster
  of 10 nodes, one node is 10 % and it fits; **on one of 3 nodes with domain `host`, the loss of a
  node cannot be recovered anywhere** — you can only wait for it to come back. That is the
  real difference between 3 and 10 nodes, and no capacity spreadsheet writes it down.
- Emergency exit (and only that): raise `full_ratio` **a little** with
  `ceph osd set-full-ratio` to regain writes, delete data or **add OSDs**, and
  put it back. Look for forgotten `bench*` objects with `rados ls` before anything else.
- Actionable alert: `nearfull` projected, not reached. If your first warning is `OSD_NEARFULL`, you are
  already late.

### 6.3 What to watch

- **Status**: `HEALTH_*` and each check separately — `OSD_NEARFULL`, `OSD_BACKFILLFULL`,
  `OSD_FULL`, `PG_DEGRADED`, `PG_AVAILABILITY`, `OSDMAP_FLAGS`, `MON_DOWN`,
  `UPGRADE_NO_STANDBY_MGR`, `POOL_FULL`, `TOO_MANY_PGS`, `OBJECT_UNFOUND`.
- **Per-OSD latency** (`ceph osd perf`, `commit_latency`/`apply_latency`, and the exporter's
  metrics): the metric that matters is not the average, it is **the worst OSD**. In a distributed system,
  a single sick disk drags down the latency of every PG that touches it, and the symptom the
  user sees is `slow ops` on clients that are not on that host. Alert on **outlier**, not on average.
- `slow ops` / `SLOW_OPS` with its OSD and its operation type: it is the shortest path to the bad disk.
- Occupancy per OSD (deviation between the fullest and the emptiest) and balancer status.
- PGs in states other than `active+clean` and **how long they have been that way**.
- Quorum status and **clock drift between monitors**: `MON_CLOCK_SKEW` degrades Paxos. Reliable NTP
  on the monitors is not optional.

### 6.4 Upgrade

- Order automated by cephadm: **managers → monitors → the rest of the daemons**, restarting each one
  only when Ceph confirms that the cluster is still available. `HEALTH_WARNING` during the process is
  expected.
- Requirements: **an MGR on standby** (otherwise the upgrade is blocked), cluster **with no prior
  degradation**, autoscaler paused (cephadm does it), and **do not change the topology during the
  OSD phase**.
- Staged upgrade (`--daemon-types`, `--limit`, scope by CRUSH *bucket*) for large
  clusters; on a large CephFS, the docs describe using `mgr/orchestrator/fail_fs` so you do not have to
  lower `max_mds`.
- **Never** upgrade Ceph and the underlying platform (PVE, K8s, kernel) in the same window.

## 7. Sustainability and prohibitions

- Cadence: follow the current stable release and plan the jump **before** the published EOL, not
  after. At most two releases of jump per rolling upgrade.
- Every cluster has **a named owner** and a runbook covering: losing a disk, losing a host,
  losing quorum, reaching `nearfull`, and doing the upgrade. Without that, the cluster is a liability.

Explicit prohibitions:

- ❌ **`min_size = 1`** on any pool. Not even "temporarily to recover", without a written
  decision and an immediate rollback.
- ❌ **An even number of monitors**, or all three monitors in the same failure domain.
- ❌ A **2-node** cluster. There is no fault tolerance; there are two copies of the complexity.
- ❌ Failure domain `host` on a multi-rack cluster without having decided it explicitly.
- ❌ **EC for RBD** without having measured your write pattern; EC with `m=1` in production.
- ❌ Putting CephFS metadata or the RGW index on EC or on HDD.
- ❌ A hardware RAID controller in front of the OSDs. **HBA in IT mode**, raw disk.
- ❌ Disabling the *deep scrub* permanently, or muting `PG_NOT_DEEP_SCRUBBED`.
- ❌ Treating `nearfull` as an informational warning. It is a deadline.
- ❌ Changing the capacity ratios in `ceph.conf` believing they take effect (§6.2).
- ❌ Running an archived release (Reef or earlier) in production.
- ❌ Exposing the MGR dashboard or the orchestration API outside the management network.
- ❌ Handing out the `client.admin` keyring to clients or to scripts. Capabilities scoped per consumer.
- ❌ Using replication as if it were a backup.
- ❌ `rados bench` against a production pool without cleaning the objects afterwards.
- ❌ Upgrading Ceph with the cluster degraded, or at the same time as the underlying platform.
- ❌ Deploying Ceph "because it scales" on 3 nodes with no owner, no 10 Gb/s network and no runbook.

## 8. Mandatory web verification

Before pinning any data from this document into a real design:

1. **Current release and EOL** at `docs.ceph.com/en/latest/releases/` (*Active Releases* table): as of
   Aug 2026, **Tentacle 20.2.3** (2026-08-05, estimated EOL 2027-06-01) and **Squid 19.2.5**
   (2026-07-14, **estimated EOL 2026-10-31**). That Squid date is imminent: re-verify it.
2. **Release cycle** at `docs.ceph.com/en/latest/releases/general/`: the documented target
   (March, annual, 24 months of support) **does not match the real dates** of Squid and Tentacle.
   Check both before planning a migration.
3. **Default values** cited here (`mon_osd_*_ratio`, `osd_scrub_*`, `osd_deep_scrub_interval`,
   `mon_target_pg_per_osd`, `ms_*_mode`, `block.db` sizing): the configuration
   documentation is the source and **it changes between releases**. Check against the docs for **your** version,
   not against `latest`.
4. **Status of `allow_ec_optimizations`**: introduced in Tentacle, restricted to Jerasure and ISA-L
   and **irreversible once enabled**. Verify its status and its limitations in the docs for your
   release before touching a pool.
5. **CVEs for Ceph, cephadm and Rook**: official project advisories and `ceph-announce`.
   **Declared gap**: the Ceph CVE history has not been reviewed for this document.
6. **Performance**: any IOPS or throughput figure from a vendor or from a *whitepaper* is
   treated as unverified until you reproduce it on your hardware with your data profile.
   **Declared gap**: this document **contains no absolute performance figure** for
   that reason; only the replication-time-per-bandwidth reference, which is in the
   official documentation.
7. **Version packaged by Proxmox VE** and its documented upgrade order, if the route is
   `pveceph`: Proxmox sets it, not you (`proxmox-ve-standards` §2 keeps it up to date).
8. **Licences**: Ceph **LGPL-2.1 or LGPL-3** (`COPYING` in `ceph/ceph@main`), Rook **Apache-2.0**
   (`LICENSE` in `rook/rook@master`), both read raw. Re-verify if the project changes foundation
   or governance.

If the web contradicts this document, **the web wins** — flag the discrepancy.
