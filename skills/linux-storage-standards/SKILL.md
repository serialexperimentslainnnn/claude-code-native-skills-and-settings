---
name: linux-storage-standards
description: Linux block storage and traditional filesystems, everything except ZFS. Use when working with LVM (pvcreate, vgcreate, lvcreate, lvextend, lvresize, pvmove, lvmthin thin pools, thin_pool_autoextend_threshold, lvm.conf, dmeventd), mdadm software RAID (--consistency-policy ppl/journal, write-intent bitmap, /proc/mdstat, mdadm.conf), ext4/XFS/btrfs (mkfs.ext4, mkfs.xfs, xfs_growfs, xfs_repair, xfs_info, resize2fs, tune2fs, e2fsck, dumpe2fs, btrfs subvolume/scrub/balance), mount options (noatime, discard, nofail, x-systemd.device-timeout), fstrim.timer, blkid, lsblk, partitioning with parted/sgdisk, NVMe and SSD wear (nvme-cli, smartctl, over-provisioning, /sys/block/*/queue/scheduler none vs mq-deadline vs bfq, nr_requests), device-mapper multipath (multipath -ll, multipath.conf, /dev/mapper aliases), iSCSI initiator (iscsiadm, open-iscsi, node.session.timeo), NFS client mounts (hard vs soft, timeo, retrans, nconnect), LUKS/dm-crypt (cryptsetup, crypttab, luksFormat, argon2id), disk quotas, inode exhaustion, df versus du discrepancies, and I/O diagnosis or benchmarking with iostat, iotop, blktrace, biolatency or fio.
---

# Linux storage standards (block layer and filesystems)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: storage in Linux is **a stack of layers**, and almost every wrong diagnosis
> comes from treating it as one. "The disk is slow" is rarely the disk. Before
> touching anything, **place the problem in its layer**.

## 1. Scope and triggers

Applies to all local and block storage of a Linux host **that is not ZFS**: the stack from
device to application, LVM, software RAID, traditional filesystems (ext4, XFS, btrfs),
NVMe/SSD, multipath, iSCSI and NFS **from the client side**, encryption at rest with LUKS, quotas,
capacity, and I/O diagnosis and measurement.

Triggers: `lsblk`, `blkid`, `pvs`/`vgs`/`lvs`, `lvm.conf`, `mdadm`, `/proc/mdstat`, `mkfs.*`,
`xfs_*`, `resize2fs`, `tune2fs`, `btrfs`, `/etc/fstab` (a filesystem's line),
`fstrim.timer`, `nvme`, `smartctl`, `multipath.conf`, `iscsiadm`, `cryptsetup`, `/etc/crypttab`,
`iostat`, `fio`, `blktrace`, "no space left", "inodes exhausted", "df and du don't match".

**Internal arbitration rule**: if the question is answered with `lvs`, `mdadm`, `mkfs` or `mount`, it belongs
to this skill. If it is answered with `zpool` or `zfs`, it belongs to `zfs-standards`.

**Not applicable**: see `zfs-standards` (**the sister boundary**: pools, vdevs, `ashift`, `recordsize`,
`volblocksize`, snapshots, `zfs send`, ARC, scrub, native encryption. **A system with ZFS does not carry
LVM or mdadm underneath**: ZFS is both volume manager and filesystem and it demands the raw disks
behind an HBA in IT mode — stacking it on `md` or on an LV takes away the information it repairs
with. If a diagram shows `zpool` and `vgcreate` over the same disks, the design is
wrong. The only legitimate coexistence is having both worlds on **different disks** of the same host,
e.g. root on LVM+ext4 and data on ZFS), `linux-administration-standards` (**the closest one; the
boundary is what is being asked, not which file is touched**: the **systemd model** —`fstab` versus
`.mount` units, generators, `x-systemd.*`, boot ordering, `autofs`, `emergency.target` and the
recovery of a host that will not boot, `systemd-cgtop`, `IOWeight=`, journald retention— is
**theirs**; **the content of the line**: which filesystem, with which creation parameters, on which
block layer, with which options for performance and how it is sized and grown, is
**ours**. In one line: **"why doesn't it mount at boot?" is theirs; "why is it slow and
how do I grow it?" is ours.** And `iostat` appears in both: there as part of the general triage of
a slow host, here as an attribution tool inside the block stack),
`onprem-standards` (platform umbrella; its §2 fixes the filesystem criteria and its §1.3 the
invariants), `homelab-standards` (btrfs with snapshots and its tooling in a **personal lab**,
where the criteria are cost, noise and power draw; here btrfs is judged by feature stability in
production, §3.4), `bcdr-standards` (RTO/RPO, recovery order, DR exercises),
`backup-recovery-standards` (backup tool, repository, retention,
immutability and restore procedure; **an LVM or btrfs snapshot is not a backup**, §3.2 and
§3.4: here they are given as a consistency-point mechanism, never as a backup strategy),
`data-platform-standards` (**the data engine on top**: the filesystem, its alignment and the LV layout
where PostgreSQL lives are **ours**; `shared_buffers`, `wal_*`, indexes, PITR and replication are
**theirs**), `linux-hardening-standards` (**`noexec`/`nosuid`/`nodev` and partition separation
as a CIS control are theirs**; here the same mount options **on performance and layout
criteria** — if the question is "what does the benchmark require?", it is there; if it is "does `noatime` cost me
anything?", it is here), `cryptography-pki-standards` (choice of algorithm, KDF and **key custody** for
LUKS; here only the operational use of the encrypted volume), `secrets-management-standards` (where the
unattended unlock key lives), `kubernetes-standards` (CSI, PV/PVC, StorageClass and access
modes — the boundary is the node: the node's disk and filesystem are ours, the volume the
CSI presents to the pod is theirs), `observability-standards` (metric and alert design; here **what**
has to be watched), `incident-response-forensics-standards` (forensic image acquisition and chain
of custody: if the goal is to preserve evidence, that skill wins — here diagnosis and
repair, which **destroy evidence**), `proxmox-ve-standards` and `libvirt-kvm-standards`
(VM storage — the LV or the image file and its alignment are
ours, the virtual disk's cache model and its definition are theirs), `ha-clustering-standards`
(**shared** storage — cluster LVM, GFS2/OCFS2, fencing and quorum;
here the storage **of one host**), `object-storage-standards` (S3 and its
consistency and durability model, radically different from block's — you do not design an object
system with filesystem criteria), `file-servers-standards` (**the file sharing protocol
and its exposure**: `smb.conf` and `/etc/exports`, dialect, identity mapping, ACLs of the
published share and its auditing — **if the answer is written in `/etc/exports`, it is theirs**; here
the **client side** of the NFS mount and everything block, including the `targetcli` iSCSI `target`,
which is not file sharing but a raw disk with a single owner),
`networking-standards` (the network underpinning iSCSI/NFS:
VLANs, MTU/jumbo frames, routes; here the client side and its timeouts).

## 2. Default decisions

> Verify the latest version and the status of each feature on the web before pinning it (§8).

| Area | Default | Justifiable alternative / Forbidden |
|---|---|---|
| General filesystem | **XFS** (the RHEL family's default since RHEL 7 and through RHEL 10) | **ext4** if you need to **shrink** the filesystem, or on workloads with many small files. ❌ Choosing "because I always use ext4" without looking at §3.4 |
| Filesystem if you have to shrink | **ext4** — **XFS cannot be reduced, full stop** (`xfs_growfs` only grows; there is no online shrink and none on the upstream roadmap as of kernel 7.0) | ❌ Planning an XFS "we'll shrink it later": the only path is dump + `mkfs` + restore |
| btrfs | Only with the **single/DUP/RAID1/RAID1C3/RAID1C4** profiles; useful if you want snapshots and checksums without ZFS | ❌ **btrfs RAID5/RAID6**: the project's documentation marks it **unstable** and the on-disk format is still not finalised (status as of kernel 7.1). See §3.4 |
| Volume manager | **LVM** when you have to grow, move online or share out a pool of disks; **no LVM** if it is one disk and one filesystem that never change | ❌ LVM "out of habit" on a single-disk VM: an extra layer, more pieces, zero benefit (§3.2) |
| LVM thin | Only with `thin_pool_autoextend_threshold` **< 100** (typically 80) and `lvm2-monitor`/`dmeventd` active and **monitored** | ❌ Overprovisioning with no alert on pool occupancy: **filling a thin pool corrupts it and it may be unrepairable** (§3.2) |
| Software RAID | **mdadm RAID10** for data that matters; **RAID1** for root/boot | **RAID6** if capacity wins. ❌ **RAID5 with large disks** (consistent with `onprem-standards` §7). ❌ RAID0 in production |
| RAID5/6 write hole | `--consistency-policy=ppl` (RAID5) or a journal on mirrored SSDs (RAID4/5/6) | ❌ Believing that the **write-intent bitmap closes the write hole**: it only speeds up the resync. See §3.3 |
| I/O scheduler | **`none`** on NVMe (and it is the kernel's default for NVMe) | **`mq-deadline`** on SATA SSD/HDD with mixed load, and on NVMe **only** if you measure that tail latency (p99/p999) improves. `bfq` on desktop/interactive. ❌ Changing it without measuring before and after |
| TRIM | **`fstrim.timer`** weekly (`systemctl enable --now fstrim.timer`) | ❌ The **`discard`** mount option on XFS (`xfs(5)` itself advises against it: impact "quite severe") and on ext4. On **btrfs**, `discard=async` is a valid alternative. ❌ Continuous TRIM on a thin SAN LUN |
| `atime` | **`noatime`** (or `relatime`, which is already the kernel default) | ❌ `atime` by default on filesystems with many files or on remote storage |
| Mounting non-critical volumes | `nofail` + `x-systemd.device-timeout=` | ❌ An `fstab` entry without `nofail` for an optional data disk: **an absent disk leaves the host in `emergency.target`** (boot and its recovery belong to `linux-administration-standards`) |
| Device identification | **`UUID=`** in `fstab`/`crypttab`, or `/dev/disk/by-id`; the mapper alias with multipath | ❌ `/dev/sdX` in any persistent file: it gets reordered between boots |
| NFS client | **`hard`** always, with `timeo=600,retrans=2` | ❌ **`soft`** on write workloads: it causes documented **silent corruption**. `softerr`/`softreval` only with the application aware of EIO. `nconnect=4–8` **after measuring** and never with `sec=krb5*` |
| Encryption at rest | **LUKS2 with `argon2id`** (cryptsetup's upstream default) | `pbkdf2` **only** on the partition GRUB has to unlock. KDF policy and key custody belong to `cryptography-pki-standards` |
| Multipath | Active whenever the LUN arrives over more than one path; **access only through `/dev/mapper/<alias>`** | ❌ Mounting `/dev/sdX` when a multipath map exists: the classic failure, §3.6 |

## 3. The stack and its layers

### 3.1 The block stack

```
aplicación
  └─ filesystem            (ext4 / XFS / btrfs)   ← inodos, journal, fragmentación, lleno
      └─ LUKS / dm-crypt   (opcional)             ← CPU, TRIM, desbloqueo
          └─ LVM  (PV/VG/LV, thin)                ← espacio del VG, thin pool lleno
              └─ mdadm  (RAID por software)       ← degradado, resync, write hole
                  └─ multipath (SAN)              ← rutas caídas, failover
                      └─ dispositivo (SATA/SAS/NVMe/LUN)  ← SMART, desgaste, cola
```

- **The order matters and is not negotiable**: `multipath` goes below LVM, **LUKS goes above
  LVM or below, but it is decided once** (LUKS-on-LV lets you encrypt only some volumes;
  LVM-on-LUKS encrypts everything with a single key and is usually the right thing for a laptop or a whole
  host). Reordering the stack afterwards means migrating data.
- **Diagnosis: identify the layer before acting.** `lsblk -o NAME,KNAME,TYPE,SIZE,FSTYPE,MOUNTPOINT`
  shows the real stack. High latency in `iostat` on `dm-3` with the physical disks idle
  points to the dm layer (encryption, thin, RAID), not to the disk.
- **Every layer adds a failure mode and a place where things lie**: the one with the fewest layers that meets
  the requirement is the correct one (KISS). Every layer present must justify its existence.

### 3.2 LVM

- **When it pays off**: you have to grow online, move data between disks without stopping (`pvmove`),
  aggregate several devices, or separate volumes with different life cycles.
- **When it is free complexity**: a VM with one virtual disk and one filesystem, where the
  hypervisor already knows how to grow the disk. There LVM only adds a step to every operation.
- **Growing**: `lvextend -r -L +100G /dev/vg/lv` — the `-r` (`--resizefs`) grows the filesystem
  in the same step, and it is **the correct form**: doing it in two steps is where people forget the
  second one and then "the disk didn't grow". Growing XFS and ext4 is **online**.
- **Shrinking**: **only ext4 and only with the filesystem unmounted** (`e2fsck -f`, `resize2fs` to the
  target size, **then** `lvreduce` to a size **equal or larger**). Reversing the order destroys
  data. **XFS is never shrunk** (§2, §3.4). Before shrinking: a verified backup, not a snapshot.
- **Thin provisioning — the real risk**: the sum of the thin LVs can exceed the pool; while
  there is free space nothing happens, and the day it fills up **the thin pool can end up damaged and be
  hard or impossible to repair**. Non-negotiable requirements:
  - `thin_pool_autoextend_threshold` **< 100** (100 disables it; the minimum accepted is 50; 80 is
    the practical value) and `thin_pool_autoextend_percent` (e.g. 20) in `lvm.conf`; **with real free
    extents in the VG**, because without them `lvextend --use-policies` can do nothing.
  - `lvm2-monitor` active and **monitoring enabled on the pool** (`lvchange --monitor y`): without
    dmeventd the policy is not applied.
  - **An alert on the pool's `Data%` and `Meta%`** (`lvs -o +data_percent,metadata_percent`) — the
    **metadata runs out separately** and its exhaustion returns I/O errors just like the
    data does. It is the classic oversight.
  - Behaviour on a full pool configured deliberately: `--errorwhenfull y|n` (the default `n`
    queues writes for ~60 s waiting for an extension, and then returns an error).
  - A documented emergency exit: `fstrim`/`discard` in the guests, destroying snapshots,
    deleting data, or extending the VG. Reads keep working even with the pool out of space.
- **LVM snapshots ≠ ZFS/btrfs snapshots**: the classic ones are **copy-on-write with a fixed exception
  volume** that, if it fills up, **invalidates the snapshot**; they penalise every write to the origin;
  they are neither cheap nor infinite. Thin snapshots are much better but they share the fate of the
  thin pool. In both cases: **a consistency point for taking the copy, never the copy itself**
  (`backup-recovery-standards`).
- **LVM on RAID**: `md` underneath and LVM on top is the classic and predictable combination. `lvcreate
  --type raid1/raid5` (dm-raid) exists and uses the same kernel engine, but it leaves diagnosis
  split between `lvs` and `/proc/mdstat`: pick one and be consistent. ❌ Stacking LVM on LVM.
- **Alignment**: on SAN LUNs and on SSDs, `pvcreate --dataalignment` consistent with the array's
  stripe; misalignment multiplies read-modify-write writes. Check with `pvs -o +pe_start`.
- **Copy of the VG metadata**: `/etc/lvm/backup` and `/etc/lvm/archive` are backed up with the host.
  `vgcfgrestore` has saved more systems than any recovery tool.

### 3.3 Software RAID (mdadm)

- **Levels and criteria**: RAID1 (root, boot), **RAID10 (data with IOPS)**, RAID6 (capacity with
  large disks). **RAID5 with large disks is forbidden** for the same reason as RAIDZ1: the
  rebuild window is so long that a second failure or a URE stops being improbable.
  RAID0 is not RAID.
- **Write hole**: after an unclean shutdown a stripe's parity can be left inconsistent with the
  data, and if the array is also degraded there is no way to recompute it → **silent
  corruption** when rebuilding. That is why `md` does not start a degraded and dirty array by default.
  - **`--consistency-policy=ppl`** (Partial Parity Log, **RAID5 only**, metadata 1.x or IMSM):
    it closes the write hole **without a dedicated disk**, at a cost of up to 30–40 % of write
    performance. **It is weaker than a journal**: it does not protect data in flight, only silent
    corruption; if a dirty disk of the stripe is lost, there is no PPL recovery for that stripe.
  - **`--write-journal`** (RAID4/5/6): a strong guarantee, it requires a **dedicated and mirrored SSD** — if not,
    you have just created a SPOF that takes the array with it.
  - **The write-intent bitmap does NOT close the write hole**: it only limits the region to be resynced.
    Use it anyway (`--bitmap=internal`) because it turns a full resync into one of minutes.
  - **RAID6 has no PPL**: a journal, or accept the risk.
  - **If the filesystem on top already solves it** (ZFS raidz), protection at the `md` level is redundant —
    but then you should not have `md` underneath ZFS at all (§1).
- **Operation**: `mdadm --detail --scan >> /etc/mdadm/mdadm.conf` after creating (otherwise the array can
  be assembled under a different name); `mdadm --monitor` with a real mail/alert destination; periodic and
  **watched** `checkarray` (scrub) — an array that is never verified does not know it has a bad disk
  until the resync.
- **Rebuild**: `/proc/mdstat` gives progress and speed; `/sys/block/mdX/md/sync_speed_max`
  bounds it. **Time a real resync in preproduction**: if it takes longer than your acceptable risk
  window, the RAID level is wrongly chosen.
- **mdadm+LVM+XFS versus ZFS/btrfs — the criteria, not the tribe**: `md`+LVM+XFS is predictable,
  universal, supported by every distribution, with rescue tools on any live CD, and
  **it does not detect silent corruption** (no data checksums: parity detects a disk that
  fails, not a bit that lies). ZFS/btrfs give end-to-end checksums, cheap snapshots and
  repair from the redundant copy, in exchange for RAM, a mental model of their own and —in ZFS— an
  out-of-tree module. **Decide on the requirement**: if you need demonstrable integrity and
  snapshots, ZFS (`zfs-standards`); if you need simplicity, portability and shrinkable volumes,
  `md`+LVM+ext4/XFS. **What is forbidden is mixing them in the same stack.**

### 3.4 Filesystems

- **XFS** — RHEL's default since 7 (and in RHEL 10). It scales better from several TB up and in
  parallelism: the allocation groups have independent metadata and allow allocation from
  several threads without contention. **It only grows** (`xfs_growfs`, online). On a metadata error it
  **shuts the filesystem down** and returns `EFSCORRUPTED` (unlike ext4, which by default continues) —
  fail-fast, which for a server is usually the right thing.
- **ext4** — the choice when you need to **shrink** (`resize2fs` offline), on workloads with many
  small files, and where the familiarity of the rescue tools matters.
- **Creation parameters that are NOT changed afterwards** — they are decided at `mkfs` or you live
  with them for life:
  - **Block size** (`-b` in ext4, `-b size=` in XFS): fixed forever.
  - **Number of inodes / bytes-per-inode ratio in ext4** (`-i`, `-N`): **running out of inodes with plenty
    of free space** is a classic failure on mail, cache or build filesystems (§3.8). XFS allocates
    inodes dynamically and does not suffer from this.
  - **Sector size/`sunit`/`swidth` in XFS** to align with the RAID stripe.
  - `-m` (percentage reserved for root in ext4): **lower it to 0–1 % on large data volumes**;
    the default 5 % is tens of GB thrown away. **Do not lower it on `/` or `/var`**: that reserve
    is what lets you fix a full system.
  - ext4 features (`metadata_csum`, `64bit`) — check your `mke2fs.conf` default.
- **btrfs — status as of kernel 7.1** (the project's official documentation, Aug 2026):
  - **OK**: subvolumes and snapshots, compression, `send`, `receive`, `scrub`, free space tree,
    fsverity, the **RAID1, RAID1C3, RAID1C4** profiles.
  - **"mostly OK"**: quotas/qgroups (performance degrades a lot with many snapshots),
    `device replace`, zoned mode.
  - **`RAID56`: unstable.** The RAID5/6 block group is still not fully implemented and **the
    on-disk format is not finalised**. **Forbidden in production**, with no nuance and no "but it works
    for me".
  - Criteria: btrfs is right for root with snapshots and rollback, and for data with RAID1/1C3.
    For parity, it is either `md`+RAID6 or ZFS RAIDZ2.
  - Its qgroups on a system with frequent automatic snapshots are a known source of
    latency: measure it before enabling them.
- **Mount options that matter (for performance and operability)**: `noatime`; `nofail` +
  `x-systemd.device-timeout=` on non-critical volumes; implicit `nodiscard` (use `fstrim.timer`,
  §3.5); `defaults` without thinking is a decision, and usually the wrong one. **`noexec`, `nosuid` and
  `nodev` are security controls and their criteria are fixed by `linux-hardening-standards`.**
- **`fstab` versus `.mount` units**: **the model, the precedence and the generator belong to
  `linux-administration-standards`**; here only the content rule: **always identify by
  `UUID=`**, never by `/dev/sdX`, and on a volume that may not be present, `nofail`.
- **`fsck` and repair**: `xfs_repair` requires the filesystem **unmounted** and `xfs_repair -L`
  (discarding the log) is **destructive, a last resort**. On ext4, `e2fsck -f` outside the production
  window. Before repairing a filesystem with data that matters and where compromise is suspected:
  **image first** (`incident-response-forensics-standards`) — repairing destroys evidence.

### 3.5 NVMe, SSD and wear

- **Over-provisioning**: leaving 7–20 % of an SSD unpartitioned (or
  using `nvme format`/HPA depending on the manufacturer) extends its life and stabilises sustained write
  latency. On datacentre SSDs it usually comes from the factory; on consumer models used as a cache or
  SLOG, doing it by hand is the difference between stable performance and collapse.
- **TRIM**: **weekly `fstrim.timer`**, not `discard` on the mount. `xfs(5)` explicitly
  advises against `discard` because of its "quite severe" impact (there are documented cases of deletions going from ~31 s
  to ~2 min). On **btrfs**, `discard=async` (kernel 5.6+) is a reasonable alternative.
  On LUKS it has to be **explicitly allowed** (`discard` in `crypttab`), with the known
  trade-off of **information leakage** about which blocks are in use: it is a threat-model
  decision, not a performance one. On thin SAN LUNs or thin virtual disks, **periodic fstrim**, not
  continuous.
- **Monitor wear, not death**: `smartctl -a` / `nvme smart-log` →
  `percentage_used`, `available_spare` against `available_spare_threshold`, `media_errors`,
  `unsafe_shutdowns`, `data_units_written`. **A metric exported and alerted on by trend**: an
  SSD is replaced when the projection says it will hit the limit within the
  provisioning window, not when it fails. Watch the **batches**: identical disks bought together
  wear out together.
- **I/O schedulers**: the classic ones (`cfq`, single-queue `deadline`) no longer exist; the
  kernel is blk-mq. For **NVMe the default and the recommendation is `none`**: the device's queue depth and
  parallelism make scheduling pure CPU overhead. **`mq-deadline`**
  is justified on SATA SSD/HDD with mixed load and, on NVMe, **only** if the metric you care about is
  **tail latency** (p99/p999) and you have measured it: `mq-deadline` imposes deadlines (500 ms
  read / 5 s write) and prevents a request from being left behind. `bfq` for desktop interactivity.
  On many NVMe devices **only `none` is available** unless you load the modules.
  It is changed through sysfs without a reboot (persistent via a udev rule), but **never without measuring before and
  after**.
- **Queues**: `nr_requests`, `queue_depth` and the number of hardware queues determine perceived
  performance more than the scheduler does. "The disk is slow" with `%util` at 100 % and a high `aqu-sz`
  is **queue saturation**, not a bad disk.

### 3.6 Multipath, iSCSI and NFS (client side)

- **Multipath when the LUN arrives over more than one path** (two HBAs, two controllers, two
  FC/iSCSI switches). Without it, losing a path is losing the LUN.
- **The classic failure: mounting `/dev/sdX` instead of the mapper.** With multipath, each path
  appears as a different `sdX` and **it works** — until that path goes down, or until two paths get
  mounted at the same time and corrupt. **Hard rule: if `multipath -ll` lists the WWID, the only legitimate
  access is `/dev/mapper/<alias>`.** Add the underlying `sdX` devices to LVM's `blacklist`/filter
  (`global_filter` in `lvm.conf`) so that LVM does not see the same PV four times.
- **Persistent aliases** in `multipath.conf` (by WWID, with a name that says what it is), `find_multipaths`
  and a path policy matching the array (`path_grouping_policy`, ALUA). The array's parameters are
  taken **from the vendor's guide**, not from the generic default.
- **iSCSI**: `iscsiadm` with `node.startup=automatic` for LUNs needed at boot and **the network
  unit up first** (`_netdev` in `fstab`); mutual CHAP; **a dedicated storage VLAN**, with a consistent MTU
  end to end (`networking-standards`). Timeouts (`node.session.timeo.replacement_timeout`)
  tuned to the array's failover time: too short turns a normal failover into I/O
  errors; too long hangs the application.
- **NFS client — `hard` versus `soft`**: **`hard` always**. `soft` returns EIO after `retrans`
  retries and **can cause silent data corruption**: the application does not know which writes
  were committed. The documented real pattern is exactly that (corrupt artifacts, checksums
  that do not match, tools that ignore `write()`'s EIO). Conservative values:
  **`hard,timeo=600,retrans=2`** (plus `_netdev`/`nofail` and systemd ordering).
  - `softerr`/`softreval` are nuances for specific cases (being able to unmount a dead server),
    not the solution to the blocking.
  - `nconnect=4–8` improves throughput with several TCP connections (kernel 5.3+), **after measuring** and
    with the vendor guide's value; the **first mount to an IP fixes the `nconnect` for that
    IP** on that client. **Do not combine it with `sec=krb5*`.**
  - **The impact of remote storage going down**: with `hard`, processes touching the mount
    end up in `D` (uninterruptible) and cannot be killed; the host looks hung. That is
    **correct**: the alternative is corruption. Real mitigation: monitor the NFS server,
    mounts with `autofs` or `.mount` for the non-critical
    (`linux-administration-standards`), and do not hang critical services off an NFS with no HA.

### 3.7 Encryption at rest (LUKS)

- **LUKS2 with `argon2id`** (cryptsetup's upstream default; minimum benchmark memory 64 MiB).
  **`pbkdf2` only** on the partition GRUB has to unlock, because its LUKS2 support is
  limited. An old keyslot is migrated with `cryptsetup luksConvertKey --pbkdf argon2id`.
  **Do not pin KDF parameters from memory: the defaults change between versions** — the choice of
  algorithm and its parameters belong to `cryptography-pki-standards`.
- **A LUKS header backup is mandatory** (`cryptsetup luksHeaderBackup`), stored **off the encrypted
  disk** and with access control: a corrupt header is total loss even if the data
  is intact. It is the first question in any review.
- **Unattended unlock**: TPM2 (`systemd-cryptenroll --tpm2-device=auto` with thought-out PCRs and
  a **recovery policy**), Clevis/Tang for network unlock, or `LoadCredential`/an agent. **The
  policy, the custody of the recovery key and its rotation belong to
  `cryptography-pki-standards` and `secrets-management-standards`**; here it is fixed that
  (a) there is **always** a recovery passphrase held off the host, and (b) a firmware or kernel
  change can invalidate the TPM sealing: **test the boot after every update that touches
  PCRs, with an OOB console available**.
- **Cost and TRIM**: the CPU impact with AES-NI is marginal; TRIM through LUKS has to be
  explicitly enabled and it leaks metadata (§3.5). The baseline of mandatory encryption by
  data classification belongs to `linux-hardening-standards`.

### 3.8 The failures that look like something else

- **`df` says full and `du` cannot find it** → almost always a **deleted file still held open**
  by a process: `lsof +L1` or `lsof | grep deleted`; the space comes back when the process restarts, not
  when you delete it again. Other causes: a mount **on top** of a directory with data underneath
  (check with a bind mount of the root), or the percentage reserved for root (`tune2fs -m`).
- **"No space left" with `df` showing free space** → **inodes exhausted** (`df -i`). It happens on
  cache, mail or build filesystems with millions of small files. **It cannot be fixed
  online on ext4**: you have to recreate the filesystem with more inodes (or migrate to XFS, which allocates them
  dynamically). It is a **design failure at `mkfs` time**, and that is why `df -i` goes into monitoring.
- **A filesystem 100 % full that prevents booting or repairing**: with no space no logs are written,
  journald does not start, some services fail inexplicably, and on ext4 with no root reserve
  not even an administrator can manoeuvre. **Alert at 80 %, not at 95 %**, and with
  a prediction of the time until it fills up.
- **Quotas**: `quota`/`xfs_quota` (XFS includes project quotas, very useful for bounding a
  directory without giving it its own LV) when several consumers share a filesystem. Without
  quotas, the first one to run away takes everyone down.
- **A degraded `dm` that nobody sees**: `dmsetup status`, `lvs -o +lv_health_status`, `/proc/mdstat`.
  A degraded array that raises no alert is scheduled data loss.

### 3.9 Performance and measurement

- **Latency versus throughput**: they are different goals and almost always opposed. Define which one
  matters to you **before** measuring. A MB/s number with no latency percentiles says nothing about a
  database.
- **`iostat -xz 1`**: `r_await`/`w_await` (real per-operation latency), `aqu-sz` (queue
  depth), `%util` (**misleading on NVMe**: it reaches 100 % without saturation because the device processes
  in parallel). `iotop`/`pidstat -d` to attribute to a process; `blktrace`/`biolatency` (bcc/bpftrace)
  when you need to see the real distribution and where the time is lost inside the stack.
- **Measuring with `fio` without fooling yourself** — the three errors that invalidate any benchmark:
  1. **Measuring the cache**: a dataset larger than RAM, or `direct=1` (O_DIRECT) to bypass the page
     cache. A `dd` giving 3 GB/s on a machine with 64 GB of RAM is measuring memory.
  2. **Measuring the wrong pattern**: use the `bs`, the read/write mix, the `iodepth` and the `numjobs`
     of your real workload, not sequential `bs=1M` for a DB that does 8K random.
  3. **Not letting the SSD reach steady state**: the first minutes of an empty SSD
     lie. `ramp_time` and long runs.
  Also: `fsync`/`end_fsync` if durability matters to you, and **never run `fio` in write mode
  against a device with data** (`filename=/dev/sdX` destroys the contents).
- **"The disk is slow" — the real order of suspicion**: (1) filesystem above 80–90 % full or
  fragmented; (2) queue depth / saturation through concurrency; (3) an intermediate dm layer
  (thin pool nearly full, encryption without AES-NI, RAID resyncing); (4) synchronous writes the
  application requests and nobody had counted; (5) the disk. **The disk is the last hypothesis, not the
  first.**
- **Growing online**: virtual disk enlarged → `echo 1 > /sys/class/block/sdX/device/rescan`
  (or `iscsiadm --rescan`, or `multipathd resize map`) → `growpart`/`parted` → `pvresize` →
  `lvextend -r`. Each step is verified before the next; skipping one produces the classic
  "I enlarged the disk and it doesn't show".

## 4. Gates: what has to be demonstrated

A storage system is not in production until these points are demonstrated with
evidence and a date:

1. **A capacity alert with prediction, on space AND on inodes.** `df` and `df -i` exported, a warning
   at 80 % with an estimate of the time until it fills up. A warning at 95 % is late by definition.
   On LVM thin, an additional alert on the pool's `Data%` **and** `Meta%`.
2. **A degradation alert that has been tested.** `mdadm --monitor` (or the dm equivalent) and SMART/NVMe with
   a destination that reaches a human on call; **it is verified by triggering it** (unplugging a disk in
   preproduction), not by reading the configuration.
3. **Scrub/`checkarray` scheduled and watched** on any array with redundancy; **the alert is
   on the result**, not on the timer having run.
4. **A timed rebuild.** A real resync measured in preproduction with the load applied. If
   it exceeds the acceptable risk window, **the RAID level is wrongly chosen** and it is revisited (§3.3).
5. **Online growth rehearsed.** The complete procedure (§3.9) executed at least once
   by someone other than the runbook's author, with the application running.
6. **LUKS header and LVM metadata backups verified**, kept off the system, and with the
   restore tested (`cryptsetup luksHeaderRestore` / `vgcfgrestore`) in a test environment.
7. **No reference to `/dev/sdX`** in `fstab`, `crypttab`, scripts, units or documentation.
   Mechanical gate: `grep -rn '/dev/sd' /etc/fstab /etc/crypttab /etc/systemd/system/` empty.
8. **Multipath: check that the mount point is the mapper** and that path failover has been
   tested (bring a path down and see that I/O continues).

## 5. Security

- **Encryption at rest according to the data's classification** (§3.7). The baseline of what must be encrypted
  and partition separation as a CIS control belong to `linux-hardening-standards`; **the
  `noexec`/`nosuid`/`nodev` options are theirs**, not ours.
- **Disk retirement**: a disk that leaves the datacentre without cryptographic erasure or physical
  destruction is a data breach. `nvme format --ses=1`/`blkdiscard`/`cryptsetup luksErase` depending on the
  medium — and on SSDs, **deleting files deletes nothing** because of internal remapping: encryption from
  day one is what makes retirement trivial (destroy the key and the disk is noise).
- **LVM filter (`global_filter`)**: on a host with multipath, iSCSI or VMs, LVM can activate
  volumes that are not its own — including LVs **inside** guest disks. It is escape and
  corruption surface: filter explicitly what LVM should look at.
- **Network mounts and trust**: NFSv3 with `sec=sys` trusts the UID the client claims. On
  untrusted networks, NFSv4 with Kerberos or nothing; segmentation design belongs to
  `networking-standards`.
- **TRIM over encryption leaks metadata** (which blocks are in use): a conscious decision (§3.5).
- **CVEs of the storage stack**: kernel ones (`md`, `dm`, NVMe/SCSI drivers, filesystems)
  are triaged like any other (`vulnerability-management-standards`); their remediation **implies
  a reboot**, and that policy belongs to `linux-administration-standards`. **Declared gap (§8)**: no
  specific LVM/mdadm/XFS/ext4/btrfs CVE from 2025-2026 has been verified in this session.

## 6. Observability and operability

- **Minimum metrics per host**: space and inodes per filesystem (`node_filesystem_*`), latency and
  queue per device (`node_disk_*`: `io_time`, `read/write_time`, `io_now`), array state
  (`node_md_*`), SMART/NVMe (`smartctl_exporter`: `percentage_used`, `available_spare`,
  `media_errors`, reallocated and pending sectors), data **and metadata** occupancy of thin pools,
  multipath path state, network mount state. The design of the alerts and their thresholds belongs
  to `observability-standards`; **what** to expose belongs here.
- **Actionable alerts**: filesystem > 80 % (with prediction), inodes > 80 %, array degraded or
  resyncing, thin pool > 80 % on data or metadata, multipath path down, SMART with reallocated or
  pending sectors growing, NVMe `percentage_used` above the provisioning threshold,
  p99 latency above target, NFS/iSCSI mount unavailable. With no runbook linked, the
  alert is superfluous.
- **Capacity as planning, not as an alarm**: quarterly review of the trend per volume,
  age and wear per disk batch, and the VG's real free space (thin pools lie
  about available space by design).
- **Tested runbooks**: replacing a disk in an array, extending a volume online, a thin pool
  at 95 %, a filesystem at 100 %, a SAN path down, an NFS server down. Tested, versioned, with an
  owner.

## 7. Sustainability and prohibitions

**Cadence**
- Quarterly review: firmware of disks, HBAs and controllers (SSD firmware bugs that
  cause data loss after N power-on hours are a genre of their own); wear per batch;
  capacity trend; validity of the topology against the current load.
- Before any kernel upgrade: check changes in the block subsystem or in the
  filesystem you use if the jump is a major version (`linux-administration-standards` governs
  the reboot policy).
- **Document in the runbook the irreversible `mkfs` decisions** (block size, inodes,
  alignment) alongside the host: in three years nobody will remember why that filesystem has those
  parameters, and they are the ones that prevent growth.

**FORBIDDEN**
- ❌ **LVM or mdadm underneath ZFS.** If the system is ZFS, the disks go raw behind an HBA in
  IT mode (`zfs-standards`).
- ❌ **btrfs RAID5/RAID6** in production: **unstable** and with an unfinalised on-disk format.
- ❌ **mdadm RAID5 with large disks**; ❌ RAID0 with data that matters; ❌ an array without `--bitmap`.
- ❌ Believing that the write-intent bitmap closes the write hole (it does not: it only speeds up the resync).
- ❌ **An overprovisioned thin pool without `thin_pool_autoextend_threshold < 100`, without dmeventd active
  and without an alert on data AND metadata.** Filling the pool can be unrepairable.
- ❌ LVM or btrfs snapshots presented as a backup.
- ❌ Planning to shrink an XFS: **you cannot**. Choosing XFS where the requirement is to shrink.
- ❌ `lvreduce` before `resize2fs`, or `lvreduce` without a verified backup.
- ❌ `/dev/sdX` in `fstab`, `crypttab`, scripts, units or documentation.
- ❌ Mounting the underlying `sdX` when a multipath map exists.
- ❌ **NFS with `soft` on write workloads**: documented silent corruption.
- ❌ `nconnect` combined with `sec=krb5*`; `nconnect` copied from a blog without measuring.
- ❌ The **`discard`** mount option on ext4/XFS by default (use `fstrim.timer`); continuous TRIM
  on a thin SAN LUN.
- ❌ An `fstab` entry for an optional volume **without `nofail`**: an absent disk takes the boot down.
- ❌ Changing the I/O scheduler, `nr_requests` or any tunable **without measuring before and
  after**.
- ❌ Benchmarks with `dd`, without `direct=1`, with a dataset smaller than RAM, or without `ramp_time` on an SSD.
- ❌ Running `fio` in write mode against a device with data.
- ❌ LUKS without a **header backup** kept off the encrypted disk, or TPM unlock without
  a recovery passphrase held in custody.
- ❌ `xfs_repair -L` or any destructive repair as a first attempt, or before having an
  image if compromise is suspected.
- ❌ A production filesystem without an alert on space **and on inodes**.
- ❌ A degraded array, a thin pool at its limit or a multipath path down with no alert reaching a human.
- ❌ Lowering the root reserve (`tune2fs -m 0`) on `/` or `/var`.
- ❌ Retiring a disk without cryptographic erasure or physical destruction.

## 8. Mandatory web verification

Verified as of **August 2026** (and what has to be re-verified before pinning anything):
1. **XFS does not support shrinking**, neither online nor offline, and it is not on the upstream roadmap as of kernel 7.0;
   there is only work under review to shrink **empty AGs**. `xfs_growfs` only grows. **XFS is still
   the RHEL family's default in RHEL 10**, with ext4 fully supported. Re-verify
   in Red Hat's documentation and on `xfs.org` — it is the most frequent memory error in the domain.
   (Note: XFS gained metadata self-healing in kernel 7.0; **gap**: its scope not verified.)
2. **btrfs — the official stability matrix** (`btrfs.readthedocs.io/en/latest/Status.html`, status as of
   kernel 7.1): `RAID56` = **unstable** with an unfinalised on-disk format; `qgroups` and
   `device replace` = "mostly OK"; snapshots, compression, send/receive, scrub, free space tree and
   RAID1/1C3/1C4 = OK. **Re-verify on that page, never by hearsay**: it is the canonical source and it
   changes per kernel version.
3. **I/O schedulers**: `none` is the default and the recommendation for NVMe; `mq-deadline`
   justified by measured tail latency or on SATA. The single-queue schedulers (`cfq`,
   `deadline`) no longer exist. Confirm what `/sys/block/<dev>/queue/scheduler` offers on the
   specific kernel.
4. **LVM thin**: `thin_pool_autoextend_threshold` minimum 50, 100 disables it; dmeventd/`lvm2-monitor`
   required; **metadata** exhaustion is an independent failure mode; filling the pool
   can damage it in a way that is hard or impossible to repair. Source: `lvmthin(7)`. Re-verify your
   distribution's defaults in `lvm.conf`.
5. **`fstrim.timer` versus `discard`**: `xfs(5)` still advises against `discard` because of its severe
   impact; ext4 does not recommend it by default either; `discard=async` belongs to **btrfs** (kernel 5.6+) and
   does not exist in ext4/XFS. Re-verify in the `man` page of the installed version.
6. **NFS `hard` versus `soft`**: `nfs(5)` documents that a `soft` timeout **can cause
   silent data corruption**. `hard,timeo=600,retrans=2` as the baseline. `nconnect` requires
   kernel 5.3+, the optimal value depends on the vendor (4 on some, 8-16 on others) and **it is not combined
   with Kerberos**. Check the specific storage vendor's guide.
7. **mdadm write hole**: `--consistency-policy` accepts `resync|bitmap|journal|ppl`; **PPL is RAID5
   only**, max. 64 disks, a write cost of up to 30–40 %, and **it does not protect data in flight**;
   `journal` works for RAID4/5/6 and requires a dedicated SSD (mirrored, or it is a SPOF). The **bitmap does not
   close the write hole**. Source: `mdadm(8)` and `docs.kernel.org/driver-api/md/raid5-ppl.html`.
8. **cryptsetup/LUKS2**: the upstream default is **argon2id** (it was argon2i), with a minimum benchmark
   memory of 64 MiB; the parameters self-tune to the hardware and **change between versions** —
   the ArchWiki itself warns against trusting the defaults. GRUB needs `pbkdf2`.
   **Declared gap**: the exact cryptsetup version current in Aug 2026 has not been verified, nor
   its current default parameters. Consult the upstream GitLab before pinning them.
9. **CVEs**: **declared gap** — no specific CVE for
   LVM2, mdadm, cryptsetup, open-iscsi, multipath-tools or the filesystems (ext4/XFS/btrfs) in
   2025-2026 has been verified in this session. Consult the distribution's advisories (DSA/USN/RHSA) and NVD before asserting anything about
   the security of these components.
10. **Declared gap — not verified in this session**: (a) the current status of `f2fs` and other
    niche filesystems (bcachefs included: its upstream situation has been changeable and **it is not
    recommended here by default** precisely because it has not been verified); (b) the current values
    of `nr_requests` and blk-mq defaults per device type; (c) the current supported volume and file
    size limits **of the distribution** (not of the filesystem) for ext4 and XFS —
    Red Hat and SUSE publish *supported* limits lower than the theoretical ones, and that is the number that
    counts in a support contract.
11. Before any `mkfs` in production: the irreversible parameters (§3.4) against the
    documentation of the installed `e2fsprogs`/`xfsprogs` version, not against memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
