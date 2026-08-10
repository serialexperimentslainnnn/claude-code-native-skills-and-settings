---
name: zfs-standards
description: OpenZFS pool design and operation on Linux and FreeBSD. Use when running zpool or zfs subcommands (zpool create/status/scrub/replace/attach/detach/import/trim, zfs send/recv, zfs rewrite, zfs allow, zdb), choosing vdev topology (mirror, raidz1/raidz2/raidz3, draid, special vdev, SLOG/log, L2ARC/cache, spares), setting ashift, recordsize, volblocksize, compression=lz4/zstd, atime, xattr=sa, sync, logbias, primarycache, dedup or fast dedup (dedup_table_quota, feature@fast_dedup), zvols, ZFS native encryption and raw send (zfs send -w, keylocation, keyformat), ARC tuning (zfs_arc_max, zarcstat, zarcsummary, arcstats), snapshot replication with sanoid/syncoid, zrepl or zfs-autobackup, zfs-dkms versus kmod module builds, RAIDZ expansion, resilver and scrub scheduling, or ZFS-on-root.
---

# ZFS (OpenZFS) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: in ZFS **the pool design is a one-way door decision**.
> `ashift`, the vdev type, its width and the presence of a `special` vdev do not change: you
> destroy the pool and restore it. Everything else (properties, snapshots, cache) is reversible.
> Spend the design effort on the irreversible and stop arguing about what a `zfs set` changes.

## 1. Scope and triggers

Applies to any task on a ZFS pool: topology and creation, dataset and zvol properties,
integrity (scrub, resilver, disk replacement), snapshots and replication as a **mechanism**,
native encryption, ARC and memory, module packaging on Linux, and capacity planning.

Triggers: `zpool`, `zfs`, `zdb`, `zed`/ZED, `arcstats`, `/etc/zfs/`, `zfs.conf` in
`modprobe.d`, `zpool.cache`, `feature@…`, `sanoid.conf`, `zrepl.yml`.

**Internal arbitration rule**: if the question is answered with `zpool` or `zfs`, it belongs to this
skill. If it is answered with `lvs`, `mdadm`, `mkfs` or `mount`, it belongs to
`linux-storage-standards`.

**Not applicable**: see `linux-storage-standards` (**the sister boundary**: LVM, mdadm,
ext4/XFS/btrfs, multipath, NVMe, LUKS, `fio`, `iostat` — the whole traditional block stack; **a system
with ZFS does not have LVM or mdadm underneath**, ZFS is both volume manager and filesystem and it
needs the raw disks), `onprem-standards` (the platform umbrella: its §2 sets the filesystem criteria
—ZFS with mirrors or RAIDZ2— and this skill develops it without contradicting it; its §1.3 sets the
invariants), `bcdr-standards` (RTO/RPO, recovery order, DR exercises: **a snapshot is not a backup**,
see §3.5), `backup-recovery-standards` (the **strategy and mechanics of the backup**: tool,
repository, GFS retention, immutability, catalogue, restore procedure; here only the snapshot and
`zfs send` as a **low-level mechanism**, not as a copy plan), `linux-administration-standards`
(day-to-day OS: `fstab`, `.mount` units, systemd, packages, general host diagnosis; the **boundary**:
the mounting of a ZFS dataset is governed by the `mountpoint` property and ZFS's systemd generator,
not by `fstab` — if an `fstab` line appears for a dataset, the error belongs to this skill; if the
problem is boot ordering, `systemd-remount-fs` or a `.mount` for a non-ZFS filesystem, it belongs to
that one), `data-platform-standards` (**the data engine on top**: the `recordsize`/`volblocksize` of
the dataset where PostgreSQL lives is **this skill's**; the `shared_buffers`, the `full_page_writes`,
the indexes and the PITR are **theirs** — see §3.2), `homelab-standards` (btrfs and snapshots in a lab,
criteria of cost, noise and power draw: there ZFS competes with btrfs for RAM and for simplicity, and
the decision is economic), `proxmox-ve-standards` and `libvirt-kvm-standards`
(VM storage — the zvol and its `volblocksize` belong here, the VM's disk definition and the
hypervisor's cache model are theirs),
`ha-clustering-standards` (shared storage and fencing — **ZFS is not a cluster filesystem**, see §7),
`object-storage-standards` (S3),
`file-servers-standards` (**the snapshot is created here and published there**: the *Previous
Versions* a Windows client sees come from a ZFS snapshot exposed over SMB with `shadow_copy2`, whose
configuration is theirs), `kubernetes-standards` (CSI, PV/PVC), `observability-standards` (design of
metrics and alerts; here only **what** has to be watched in ZFS), `cryptography-pki-standards`
(algorithm choice and custody of the `keylocation` key; here only the operational use of native
encryption), `linux-hardening-standards` (`noexec`/`nosuid`/`nodev` as a security control, even though
they are expressed as ZFS properties; the performance and layout criteria belong here).

## 2. Default decisions

> Verify the latest version on the web before pinning it on a real system (§8).

| Area | By default | Justifiable alternative / Forbidden |
|---|---|---|
| OpenZFS version | **2.4.x** (2.4.3, 12 Jun 2026; Linux kernels 4.18–7.0, FreeBSD 13.3+/14.0+) | **2.3.x** (2.3.8) is still maintained and is the conservative choice if your distro packages it. **2.2 has been EOL since 18 Dec 2025** — even though a 2.2.10 was published on 12 Jun 2026, it is not a live branch: plan the exit. ❌ EOL branches in prod without a migration date |
| Topology for data that matters | **Mirrors** (2-way vdevs, 3 for irreplaceable data) | **RAIDZ2** when usable space rules over IOPS (archive, backup, media). ❌ RAIDZ1 with disks ≥2 TB. ❌ RAID0 / a single vdev with no redundancy in prod |
| RAIDZ vdev width | RAIDZ2 of **6–10 disks**; above that, several vdevs in the same pool | ❌ RAIDZ of 16+ disks "so as not to lose space": the resilver drags on forever and the second-failure window explodes |
| `ashift` | **12** (4 KiB sectors) unless proven otherwise; **13** on NVMe/SSD with an 8 KiB page | ❌ Letting ZFS autodetect with disks that lie (512e): you are stuck at `ashift=9` **for life**. Verify with `zdb -C \| grep ashift` after creating |
| Compression | **`lz4`** across the whole pool (`compression=lz4`), negligible cost and it avoids writing zeros | **`zstd`** (level 3–7) on cold data or with spare CPU and a proven ratio. ❌ `compression=off` "to save CPU": you lose space, bandwidth, and lz4's early-abort is already free |
| `atime` | **`atime=off`** by default; `relatime=on` if something depends on access time | ❌ `atime=on` on datasets with many files: a write for every read |
| `xattr` | **`xattr=sa`** (and `acltype=posixacl` where ACLs are used) | ❌ `xattr=dir` (the historical default): an extra inode per attribute, it penalises SELinux and Samba |
| `recordsize` (dataset) | **128K** in general; **16K** for PostgreSQL/MySQL (data); **1M** for large sequential files (media, backups, images) | See §3.2. ❌ Lowering `recordsize` "just in case": it multiplies metadata and kills compression |
| `volblocksize` (zvol) | **16K** (the default since OpenZFS 2.2) on mirrors; on RAIDZ, calculate the padding first (§3.2) | ❌ Setting it after creating the zvol: **it is only applied at creation**, you have to recreate and migrate |
| `sync` | **`sync=standard`** always | ❌ **`sync=disabled`**: a bullet in the foot. The pool does not corrupt, but the application loses writes it believed were committed — unacceptable in a DB, NFS or a hypervisor |
| Deduplication | **`dedup=off`**. The *fast dedup* of 2.3+ improves the mechanism, **it does not change the recommendation** | Only with a measured ratio **>2:1** (`zdb -S`), `dedup_table_quota` set and the DDT on a dedicated `dedup` vdev. `feature@fast_dedup` is an **irreversible pool upgrade** (not importable by 2.2.x). ❌ Legacy dedup (without migration to fast dedup) |
| SLOG | **No, by default.** Only if there are measured **synchronous** writes (NFS with `sync`, VM zvols, DB) | SSD/NVMe with **PLP (power-loss protection)**, mirrored. ❌ A consumer SSD without PLP as SLOG: it loses exactly what it came to protect. ❌ SLOG to speed up asynchronous writes: it does nothing |
| L2ARC | **No, by default.** It is almost never the answer: **more RAM first** | Only with a working set >> RAM, `arcstat` showing a sustained high *miss* rate and ≥64 GB of RAM. Its headers **consume ARC**: on small machines it makes performance worse |
| `special` vdev | Only with **the same redundancy as the data pool** (a 2–3 way mirror) | **Losing it takes the whole pool with it.** Useful for metadata and `special_small_blocks` in HDD RAIDZ pools. ❌ A single-device `special` vdev. ❌ Adding it without a replacement plan |
| Module on Linux | **kmod packaged by the distro** (Proxmox VE, Ubuntu `zfs-linux`, RHEL `kmod-zfs`) | `zfs-dkms` only if there is no kmod, **with the kernel pinned** (§3.6). ❌ `zfs-dkms` on a Proxmox host (the kernel already ships ZFS) |
| Encryption at rest | **LUKS underneath** when all that is needed is full disk encryption | **Native encryption** when per-dataset encryption or `raw send` to an untrusted destination is needed — with the caveats of §5 |
| Maximum occupancy | **80 %** as the alert threshold, 85 % as the operational ceiling | ❌ Pools above 90 %: the allocator changes strategy, fragmentation explodes and performance falls off a cliff |

## 3. Design and operation

### 3.1 Topology: what does not change

- **The vdev is the unit of redundancy and of failure.** A pool dies if *any* of its vdevs dies.
  Corollary: adding a vdev with no redundancy to a redundant pool degrades **the whole** pool.
- **Mirrors vs RAIDZ — the real criterion is IOPS and resilver time, not usable space**:
  - A RAIDZ vdev gives the **IOPS of a single disk**, regardless of its width. A pool of
    N mirrors gives N times the IOPS of one disk. For VMs, databases or any random workload,
    **mirrors**.
  - A mirror's resilver copies disk to disk. A RAIDZ's **reads all the surviving disks** and
    reconstructs: with 18–24 TB disks that is days, and during those days the redundancy is spent and
    the sibling disks (same age, same batch) are running flat out.
  - **RAIDZ1 with large disks is a losing bet**: the reconstruction window is so long and the stress so
    high that a second failure (or a URE) stops being improbable. Forbidden in prod with disks ≥2 TB
    (consistent with `onprem-standards` §2 and §7).
- **Width**: RAIDZ2 of 6–10. Wider gives no IOPS, it only lengthens the resilver. Several narrow
  vdevs > one wide vdev.
- **`ashift` is set when the vdev is created and never changed.** Set it explicitly
  (`zpool create -o ashift=12`) and verify it with `zdb -C`. A pool with `ashift=9` on 4Kn disks
  or SSDs has permanent write amplification.
- **Homogeneity**: all the vdevs of a pool with the same topology and size. A pool mixing a
  mirror and a RAIDZ2 inherits the worst of both and unbalances allocation.
- **dRAID**: it only makes sense from dozens of disks upwards (distributed spare → sequential resilver
  in hours instead of days). Below ~20 disks, complexity with no return.

### 3.2 `recordsize`, `volblocksize` and padding in RAIDZ

- `recordsize` is a **maximum**, not a fixed size: small files use smaller blocks.
  It is changeable live but **it only affects new blocks**; to rewrite what already exists,
  `zfs rewrite` (§3.3) — verifying the result, because there are reports that it does not always apply
  the new `recordsize` (§8).
- **Databases**: `recordsize` aligned with the engine's page size, typically **16K** for
  PostgreSQL (8K pages; 16K compresses better than two 8K ones and avoids the read amplification of
  the 128K default). A separate dataset for the WAL with **`recordsize=128K`** and
  `logbias=throughput`, because it is sequential writing. **The `shared_buffers`, the
  `full_page_writes` and the PITR plan belong to `data-platform-standards`**; here only the dataset
  layout and the block size.
- **Large sequential files** (media, backup images, objects): `recordsize=1M`. Less metadata, better
  compression, fewer IOPS.
- **`volblocksize` on a zvol**: default **16K** since OpenZFS 2.2, applied **only at creation**.
  Changing it requires creating a new zvol and migrating the content.
- **The RAIDZ waste with small blocks is real and it is calculated beforehand, not afterwards.** ZFS
  rounds allocation to multiples of (parity+1) sectors; with a small `volblocksize` on RAIDZ the
  *padding* can cost as much as the parity. Documented example: 4-disk RAIDZ1,
  `ashift=12`, `volblocksize=8K` → 25 % to parity **and another 25 % to padding**; what ZFS reports as
  1.5 TB usable stores 1 TB of guest data. **VM zvols and databases go on mirrors**; if they have to go
  on RAIDZ, calculate the overhead with the RAIDZ stripe width table (Delphix/Ahrens) **before**
  creating the pool.
- `primarycache=metadata` only on datasets whose caching is already done by the application (e.g. the
  DB's buffer pool) and with prior measurement. By default, `all`.

### 3.3 Integrity and operation

- **Scheduled and watched scrub**: monthly on HDD, quarterly on SSD/NVMe. `zpool scrub -a` (2.4+)
  covers all imported pools. A scrub that is not watched is useless: the alert is on
  `zpool status`, not on whether the cron ran.
- **`zpool status` is read with judgement**, not by looking for the word `ONLINE`:
  - `DEGRADED` → act today, not tomorrow. `FAULTED`/`UNAVAIL` → redundancy spent.
  - `READ`/`WRITE`/`CKSUM` columns **other than zero are a finding even if the pool is `ONLINE`**:
    recurring checksum errors on a disk foreshadow its death or point to a cable,
    backplane, HBA or non-ECC RAM.
  - `zpool status -v` lists the files affected by unrepairable corruption.
  - After a resilver or expansion, `scan:`/`expand:` report the progress and whether it finished.
- **ZED (`zfs-zed`) active and with real notification** (`/etc/zfs/zed.d/zed.rc`): without ZED nobody
  finds out about a `DEGRADED` until the second disk fails.
- **SMART as an early signal**: `smartd` with a short weekly and a long monthly self-test; the disk is
  replaced on trend (reallocated sectors, pending, CRC errors), not on death.
- **Disk replacement**: `zpool replace pool <old> <new>`. With a physical slot available,
  connect the new one **before** removing the old one (resilver without degrading). Identify disks by
  `/dev/disk/by-id/` — **never by `/dev/sdX`**, which gets reordered at boot.
- **Hot spares**: useful only if `autoreplace=on` is set and ZED activates them. A spare that requires
  manual intervention adds nothing over a disk on the shelf. In small mirror pools,
  a third disk in the mirror is usually a better use of the same hardware.
- **Hardware RAID underneath ZFS breaks the integrity model**, with no nuance: ZFS stops seeing the
  individual disks, it cannot repair from the redundant copy (it only detects), the controller's cache
  lies about write barriers and the resilver stops being intelligent.
  **HBA in IT/JBOD mode or nothing.**
- **ECC RAM**: ZFS detects corruption on disk, not in memory. Without ECC, a flipped bit is written
  with a correct checksum. It is not negotiable in a production storage system.
- **`zpool import` after a disaster**: `zpool import` with no arguments enumerates what is importable;
  `-d /dev/disk/by-id` when the names changed; `-f` after a host failure; `-R /mnt` to
  import under an alternative root without stepping on mounts; `-o readonly=on` **as the first attempt,
  always** on a suspect pool. `-F`/`-X` (rewind) are destructive: they discard transactions.
  Before using them, a forensic image or a copy — and ask before improvising.
- **Expansion: what can and cannot be done**:
  - ✅ Adding a new vdev to the pool (it grows, it does **not rebalance**: the old data stays where it
    was and the new vdev takes the writes).
  - ✅ Replacing all the disks of a vdev with larger ones (with `autoexpand=on`, it grows when the last
    resilver finishes).
  - ✅ **RAIDZ expansion** (`zpool attach` on a RAIDZ vdev, since OpenZFS **2.3.0**): it adds a
    disk to an existing RAIDZ vdev, online, resumable and even resistant to a disk failure
    during the reflow. **Real limits**: it does not change the RAIDZ level (a RAIDZ1 does not become a
    RAIDZ2), and **it does not rewrite the existing data** — the old blocks keep their original
    data/parity ratio, just spread over more disks. The promised efficiency is only obtained on what is
    written afterwards, and `zfs list`/`df` report less space than expected for the new blocks
    (documented behaviour, not a bug). To recover the ratio you have to rewrite:
    **`zfs rewrite`** (arrived in **2.3.4**) or send/recv to a new dataset.
  - ❌ Removing a disk from a RAIDZ vdev, narrowing it or changing its level.
  - ❌ Removing a data vdev from a pool with RAIDZ (`zpool remove` only supports top-level
    mirror/single in pools without RAIDZ).
  - ❌ Changing `ashift`.
- **`zfs rewrite`** (2.3.4+): rewrites files in place to apply the pool's current configuration
  (rebalancing after adding a vdev or expanding RAIDZ, defragmentation, compression change).
  Operational warning: **existing snapshots pin the old blocks**, so the rewrite
  doubles the space until they are freed; pause the automatic snapshot policy during the
  operation and keep capacity headroom.

### 3.4 ARC and memory

- **The "1 GB of RAM per TB of pool" is folklore**, not a criterion. The correct ARC size is
  determined by the **working set** and the measured hit ratio, not by the pool's capacity. A cold
  200 TB archive works with 32 GB; a 2 TB DB with random access may want more.
  **The only exception where the rule is still alive —and falls short— is deduplication**: the DDT
  must reside in memory and it asks for considerably more than 1 GB/TB. It is one more reason for
  `dedup=off`.
- **Since OpenZFS 2.3 the ARC by default grows to almost all the RAM** (`max(RAM − 1 GB,
  5/8 × RAM)`), versus 50 % in earlier versions. On a host that serves **only**
  storage that is fine; on a hypervisor or on a host with applications, **you have to cap**
  `zfs_arc_max` explicitly or the ARC competes with the VMs and the memory pressure ends in the
  OOM killer.
- It is set **in bytes** in `/etc/modprobe.d/zfs.conf` (`options zfs zfs_arc_max=…`) and the initramfs
  is regenerated; live via `/sys/module/zfs/parameters/zfs_arc_max`. Verify that it was actually
  applied: that is the classic mistake.
- **Always with swap configured**, even with RAM to spare: the ARC does not shrink instantly
  under pressure and without swap the OOM killer kills the application. **A `zvol` as a swap device is
  forbidden** (known deadlock under memory pressure): swap on a partition or a file outside ZFS.
- Measure, do not guess: `zarcstat`/`zarcsummary` (renamed from `arcstat`/`arc_summary` in 2.4) and
  `/proc/spl/kstat/zfs/arcstats`. Target hit ratio >85–90 %; below that, the problem is RAM or
  the access pattern, not a lack of L2ARC.
- **ZFS on machines with little RAM** (<8 GB): it works, but with `zfs_arc_max` capped at 1–2 GB, no
  dedup, no L2ARC and accepting modest performance. Below 2 GB of ARC the system
  crawls: there ZFS is the wrong choice.

### 3.5 Snapshots and replication (mechanism, not strategy)

- **A snapshot is NOT a backup.** It lives in the same pool: a vdev failure, a `zpool destroy`,
  ransomware with root or a fire takes it away along with the original. The snapshot is cheap *undo*
  and a consistency point for the copy. **The backup strategy —what is copied, where to, with what
  retention, immutability and restore verification— belongs to `backup-recovery-standards`, and
  the RTO/RPO and recovery order to `bcdr-standards`.** This skill only sets the mechanism.
- Recursive and per-dataset atomic snapshots (`zfs snapshot -r`); naming with a sortable timestamp
  (`autosnap_2026-08-02_00:00:00_daily`).
- **Automated retention, never manual.** Tools with verified maintenance (Aug 2026):
  - **sanoid/syncoid** (jimsalterjrs/sanoid): active repo (Jun 2026), last release v2.3.0
    (Jun 2025). Declarative policy in `sanoid.conf`, `syncoid` for the send. **By default.**
  - **zrepl** (Go, a daemon with push/pull jobs, snapshots and pruning in a single binary): active,
    v0.7.0 (Feb 2026) after a long pause — valid if you want a daemon instead of cron+scripts.
  - **zfs-autobackup** (psy0rz): active (Jun 2026), but its current line is **v4.0-beta**: use the
    stable one or accept that you are on beta.
  - ❌ Home-made retention scripts without locking or idempotency: they delete the wrong snapshot on
    the day it matters.
- **Incremental replication** with `zfs send -i`/`-I` over a common base snapshot; `-R` to replicate
  the tree with properties. On the destination, **`zfs recv -F` only if you understand that it discards
  local changes**. Bookmarks (`#`) when you want to be able to purge the source snapshot while keeping
  the incremental starting point.
- **Destination in read mode**: `readonly=on` on the replicated dataset and, if the destination is not
  trusted, **`zfs allow` delegating only the minimum** instead of handing over root.
- **Encrypted replication**: `zfs send -w` (**raw send**) sends the blocks exactly as they are
  encrypted; the destination never sees the key or the plaintext. It is the correct mode for
  replicating to a third party. See §5 for the maturity status.
- **Verify the replica, do not assume it**: the alert is on "age of the last snapshot received at the
  destination" compared with the RPO, and periodically the destination is **mounted and checked**. A
  replica nobody has ever read is a hypothesis.

### 3.6 ZFS on Linux: the module and the root

- **Licence**: ZFS is CDDL and the kernel is GPLv2; the module cannot be distributed inside the
  kernel. Practical consequence: **the module is always out of tree**, it is compiled against your
  kernel and **it may fail to compile after an update**. This is not a one-off failure: it is the
  structural condition.
- **kmod (precompiled by the distro) > DKMS**, whenever it exists: the package is versioned
  against the kernel the distro ships and the package manager does not let them diverge. Proxmox VE,
  Ubuntu (`zfs-linux`) and RHEL/EL (OpenZFS's `kmod-zfs`) offer it. **On Proxmox VE you do not install
  `zfs-dkms`**: the kernel already ships ZFS and adding it breaks things.
- **If DKMS is mandatory**, the procedure is not negotiable:
  1. `apt-mark hold` (or the equivalent) on the kernel/headers metapackage until you have checked that
     the installed OpenZFS version supports that kernel — **the supported range is looked up in the
     release notes, not from memory** (2.4.3: 4.18–7.0).
  2. After the upgrade and **before rebooting**: `dkms status zfs` must say `installed` for the
     **new** kernel, not `added`.
  3. Keep the previous kernel bootable in GRUB; never `autoremove` the last good one.
  4. On ZFS-on-root, regenerate the initramfs and do not reboot without OOB console or KVM access.
- **ZFS on root**: viable and used in production (Proxmox, Ubuntu), but it raises a module failure from
  "the data pool does not mount" to "the system does not boot". It requires: an out-of-band console, a
  rescue kernel, a separate `bpool` if the bootloader does not support all the features, and **not
  enabling new pool features on the boot pool without checking that the bootloader understands them**.
- **`zpool upgrade` is irreversible**: it enables features that prevent importing the pool with earlier
  ZFS versions (and with another OS). It is not run "because `zpool status` suggests it": it is run
  when you need a specific feature and you have verified that **all** the systems that must
  import that pool (including the rescue live-USB and the replication destination) support it.

### 3.7 Capacity

- **Above ~80 % the pool degrades.** ZFS is copy-on-write: without contiguous free space there is
  nowhere to write new blocks and the allocator moves from *first-fit* to *best-fit*, which sends
  latency through the roof. Above 90 % the fall is a step, not a slope.
- **Fragmentation is not defragmented with a tool**: `zpool list` shows `FRAG` (of the
  free space, not of the data). It is corrected by freeing space, rewriting (`zfs rewrite`) or
  with send/recv to a new pool. Preventing it is cheaper than fixing it.
- **Capacity alerting with prediction**, not with a fixed threshold: warn at 75–80 % with an estimated
  time to full. A ZFS pool 100 % full may even prevent **deleting** files (deleting requires
  writing metadata); the emergency exit is destroying a snapshot or a reservation.
- **`refreservation` on VM zvols and `quota`/`reservation` per dataset**: without them, one dataset
  eats the pool and takes down all the others. A dataset with a `quota` is not an isolated dataset: it
  also reserves (`reservation`) what it cannot afford to lose.
- `zfs list -o space` to understand where the space went (`USEDSNAP`, `USEDREFRESERV`);
  `df` **lies** about ZFS.

## 4. Gates: what has to be demonstrated

A ZFS pool is not "in production" until these four points are demonstrated, with evidence
and a date, not declared:

1. **Scrub scheduled AND watched.** A timer/cron with `OnCalendar` and `RandomizedDelaySec`, and an
   alert that fires if (a) the scrub fails, (b) the last scrub is more than N days old, or (c) the
   scrub finds errors. The gate is passed by the alert, not by the timer.
2. **Degradation alerting proven.** ZED active with a notification that reaches a human on call.
   **It is verified by causing it** (offlining a disk in a test pool or `zinject`), not by reading
   the config.
3. **Disk replacement rehearsed.** The `zpool replace` runbook has been executed at least once
   by an operator other than the one who wrote it, timing the full resilver. If the estimated
   resilver exceeds the acceptable risk window, **the topology is badly chosen** and it has to be
   revised (§3.1).
4. **Restore from the replica verified.** The destination pool is imported, the replicated dataset is
   mounted and the content is checked with the real application. A replica that has only been
   written, never read, does not count. (The policy and cadence of this test belong to
   `backup-recovery-standards` / `bcdr-standards`; the technical gate belongs here.)

Additional items, enforceable in any review:
- `zdb -C | grep ashift` matches the hardware; `zpool status -v` clean and `CKSUM=0`.
- A ZFS exporter (node_exporter with the zfs collector, or `zfs_exporter`) publishing pool state,
  capacity, `FRAG`, ARC hit ratio, age of the last scrub and age of the last replicated snapshot.
- Disks referenced by `by-id` in any script or documentation; none by `/dev/sdX`.
- A boot test after a kernel update on a ZFS-on-root host, done in preproduction before
  production.

## 5. Security

- **Native encryption — real state (Aug 2026)**: the history of corruption with `send`/`recv` over
  encrypted datasets (issues #12014 and #11688, open since 2021) was closed with **PR #17340**,
  included from **2.2.8 / 2.3.3** onwards; FreeBSD shipped it as an erratum (FreeBSD-EN-25:10.zfs).
  Criteria: **usable from 2.3.3/2.4.x**, with two caveats that are not omitted —
  (a) the failures were in the **non-raw send** from encrypted datasets: **always prefer
  `zfs send -w`**; (b) the Proxmox VE documentation was still marking native encryption as
  *experimental* with known limitations in the replication of encrypted datasets. Before
  recommending it on a specific system, **verify the state in the exact version and the exact
  distro** (§8). With LUKS underneath you have a mature alternative if you do not need per-dataset
  encryption or raw send.
- **What native encryption does NOT encrypt**: dataset names, sizes, properties and the pool's
  topology itself. If the threat model includes metadata, it is LUKS.
- **Key custody**: `keylocation` never pointing to a file inside the encrypted pool itself
  (circular dependency: without the key you do not mount, and the key is inside). The key in a secrets
  manager or a TPM, **and a copy held outside the system being backed up** — an encrypted backup with
  no key is total loss. The algorithm choice and the custody policy belong to
  `cryptography-pki-standards` and `secrets-management-standards`.
- **Delegation with `zfs allow`** instead of root: the agent that replicates only needs
  `send,snapshot,hold` at the source and `receive,create,mount` at the destination. Root for a
  replication job is unnecessary privilege and ransomware surface.
- **Snapshots as ransomware mitigation — with limits**: they are read-only and they help, but an
  attacker with root on the host **can destroy them**. The real protection is the copy **off the host**
  and immutable (the domain of `backup-recovery-standards`/`bcdr-standards`). `zfs hold` on
  critical snapshots adds friction, not a security boundary.
- **Mount properties as a security control** (`exec=off`, `setuid=off`, `devices=off` on
  data datasets, `/home`, `/var/tmp`): the criteria and the baseline belong to
  `linux-hardening-standards`; here it is recorded that in ZFS they are expressed as **dataset
  properties**, not as `fstab` options, and that that is where they are applied.
- **CVEs**: no relevant OpenZFS-specific vulnerability in 2025-2026 is on record in the sources
  consulted, but the correct channel is the distro's advisories (`zfs-linux`,
  `kmod-zfs`), not the absence of news. See §8.

## 6. Performance and observability

- **Minimum metrics per pool**: state (`ONLINE`/`DEGRADED`/`FAULTED`), used capacity, `FRAG`,
  READ/WRITE/CKSUM errors per vdev, progress and age of the last scrub, age of the last
  snapshot and of the last snapshot **received** at the destination, ARC size and hit ratio, latency
  per vdev. The design of the alerts and their thresholds belongs to `observability-standards`;
  **what** has to be exposed belongs here.
- **Actionable alerts**: pool not `ONLINE`; any growing CKSUM counter; scrub with an
  age > cadence + margin; capacity > 80 %; replication lagging the RPO; SMART with
  reallocated/pending sectors growing. Without a linked runbook, the alert is surplus.
- **Diagnosis**: `zpool iostat -vl 1` (latency broken down by vdev and by queue: disk_wait,
  syncq_wait, asyncq_wait) is the first tool, not the host's `iostat` — it tells you whether the
  problem is the disk, the sync queue or trim. `zpool iostat -r` for the request size distribution.
- **Before touching a tunable**, measure. ZFS's `module parameters` (`zfs_txg_timeout`,
  `zfs_vdev_*_max_active`, `zfs_dirty_data_max`) solve specific problems and **create others** if
  copied from a blog. Change with a hypothesis, measurement before and after, and a record of why.
- **`autotrim=on`** on SSD/NVMe pools, or a periodic `zpool trim`. Without TRIM the write performance
  of a flash pool degrades with use.
- **Replication over the network**: `syncoid` with compression and `mbuffer` on WAN links; on a 10G+
  LAN compression is usually the bottleneck, not the link. Measure before assuming.

## 7. Sustainability and prohibitions

**Cadence**
- Follow the supported stable branch; **plan the exit from a branch before its EOL**, not
  afterwards (2.2 EOL 18 Dec 2025). Before every OpenZFS upgrade: read the release notes and confirm
  the supported kernel range.
- Before every kernel upgrade on a host with DKMS: check compatibility (§3.6). On a host with
  kmod, check that the module package accompanies the kernel in the same repository.
- `zpool upgrade` only when a feature is needed and **all** the pool's consumers
  (rescue, replication destination, another OS) support it.
- Quarterly review of: capacity and trend, disk age per batch, `FRAG`, and whether the
  topology is still the right one for the current workload.

**FORBIDDEN**
- ❌ **RAIDZ1 with disks ≥2 TB** in production. ❌ A vdev with no redundancy in a pool with data.
- ❌ **Hardware RAID (or any controller with non-pass-through cache) underneath ZFS.** HBA in
  IT/JBOD or nothing.
- ❌ A system with ZFS mounted **on top of LVM or mdadm**: ZFS needs the raw disks; stacking it on
  another volume manager takes away the information it uses to repair and adds a failure layer.
- ❌ Creating a pool without setting `ashift` explicitly and without verifying it afterwards.
- ❌ **`sync=disabled`** on any dataset with data that matters.
- ❌ **`dedup=on`** without a measured ratio >2:1, without `dedup_table_quota` and without RAM to
  spare. *Fast dedup* does not change this.
- ❌ SLOG without PLP, an unmirrored SLOG in critical workloads, or a SLOG "to speed up" asynchronous
  writes (it does nothing).
- ❌ A `special` vdev without redundancy: losing it destroys the entire pool.
- ❌ L2ARC before having exhausted the RAM expansion.
- ❌ Referencing disks by `/dev/sdX` in pools, scripts or documentation.
- ❌ Snapshots presented as a backup. ❌ A replica whose restore has never been tested.
- ❌ Running `zpool import -F`/`-X` as the first attempt on a suspect pool, or without a prior copy.
- ❌ `zfs-dkms` without a pinned kernel, or rebooting after a kernel upgrade without checking
  `dkms status`.
- ❌ `zfs-dkms` installed on Proxmox VE.
- ❌ Pools above 80 % without a dated growth plan; pools at 90 % operating "normally".
- ❌ ZFS in production **without ECC RAM**.
- ❌ **A zvol as a swap device** (known deadlock under memory pressure).
- ❌ Using ZFS as a shared cluster filesystem (two nodes importing the same pool):
  **ZFS is not cluster-aware**; a simultaneous import destroys the pool. See `ha-clustering-standards`.
- ❌ Copying module tunables from a blog without measurement before and after.
- ❌ Running `zpool upgrade` "because `zpool status` suggests it".

## 8. Mandatory web verification

Verified as of **August 2026** (and what has to be re-verified):
1. **OpenZFS version and branches**: 2.4.3 and 2.3.8 (both 12 Jun 2026); 2.2 EOL 18 Dec 2025.
   **Supported kernel range in 2.4.3: Linux 4.18–7.0, FreeBSD 13.3+/14.0+** — this is the datum
   that breaks systems and it expires every release. Source: `api.github.com/repos/openzfs/zfs/releases`
   or the Atom feeds. **Never from the GitHub Releases HTML render**: the summariser invents the year.
2. **RAIDZ expansion**: arrived in 2.3.0; it does not rebalance and does not change the RAIDZ level.
   Confirm whether any later version has added automatic rebalancing.
3. **Fast dedup**: in 2.3.0 (DDT log, prefetch, pruning, `dedup_table_quota`). The recommendation
   is still **not to use dedup**, upheld by the feature's own authors. Re-verify if
   that changes.
4. **`zfs rewrite`**: arrived in **2.3.4** (not in 2.4, as it is often misremembered). **Declared gap**:
   it is not conclusively verified whether `zfs rewrite` applies a new `recordsize` to existing
   files — there are reports that it does not. **Test on a test dataset before planning on
   it.**
5. **Native encryption**: #12014/#11688 closed by PR #17340, included in 2.2.8/2.3.3. **Declared
   gap**: the *current* state of the Proxmox VE documentation (which marked it as experimental) is not
   verified, nor whether there are open issues later than 2.3.3. Verify in the openzfs/zfs issue
   tracker and in the distro's doc before recommending it without caveats.
6. **Replication tools** (real maintenance, not popularity): sanoid/syncoid active
   (repo Jun 2026, release v2.3.0 of Jun 2025), zrepl v0.7.0 (Feb 2026), zfs-autobackup at
   v4.0-beta (Jun 2026). Re-verify via `api.github.com/repos/<org>/<repo>` (fields `pushed_at`,
   `archived`) before adopting.
7. **Default ARC**: since 2.3 it is `max(RAM − 1 GB, 5/8 × RAM)`. Confirm in the exact version
   before sizing a hypervisor.
8. **CVEs**: check the distro's advisories (`zfs-linux`, `kmod-zfs`) and the GitHub Security Advisories
   of `openzfs/zfs`. **Declared gap**: the Aug 2026 search found no relevant OpenZFS CVE
   in 2025-2026, but the absence of results **is not a negative verification**:
   check in NVD and in the distro's tracker before asserting it.
9. **Cross compatibility** before any upgrade: kernel ↔ OpenZFS, OpenZFS version ↔
   pool features ↔ bootloader (ZFS-on-root) ↔ version of the replication destination.
10. **Optimal `volblocksize`/`recordsize`**: the RAIDZ overhead table (stripe width,
    Ahrens/Delphix) and the current `volblocksize` default (16K since 2.2) before creating zvols
    on RAIDZ.

If the web contradicts this document, **the web wins** — flag the discrepancy.
