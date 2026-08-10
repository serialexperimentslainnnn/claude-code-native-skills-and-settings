---
name: proxmox-ve-standards
description: Proxmox VE and Proxmox Backup Server as a production virtualization platform. Use when running pvecm, ha-manager, pvesh, pveum, pvesm, pvesr, pveceph, pveperf, qm, pct or vzdump, editing /etc/pve files (corosync.conf, storage.cfg, datacenter.cfg, qemu-server/*.conf, lxc/*.conf, user.cfg, sdn/), sizing cluster quorum and QDevice (corosync-qdevice), HA groups, affinity rules and watchdog fencing, PVE SDN zones/vnets/fabrics or EVPN controllers, Linux bridge versus OVS on a PVE node, choosing among LVM-thin, ZFS, Ceph, NFS or iSCSI PVE storage types and their snapshot support, replication jobs between nodes, privileged versus unprivileged LXC containers, cloud-init VM templates, PVE roles and API tokens instead of root@pam, enterprise versus no-subscription repositories, the ESXi import wizard and VMware exit, or Proxmox Backup Server datastores, namespaces, verify/prune/garbage-collect and sync jobs, proxmox-backup-client and S3-backed datastores.
---

# Proxmox VE and Proxmox Backup Server standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: in Proxmox VE the irreversible decisions are not in the VM, they are in the
> **cluster**. The Corosync network, the number of nodes, the storage type and the CPU model are
> chosen once and condition everything else; a VM is reconfigured in a minute. Spend the design
> effort on what cannot be changed without emptying the cluster.

## 1. Scope and triggers

Applies to Proxmox VE and Proxmox Backup Server **as a production platform**: design and quorum of the
cluster, HA and fencing, choice and operation of PVE storage, hypervisor networking and SDN, life
cycle of VMs and LXC containers, PBS as a backup product, RBAC and API automation,
cluster update cadence, and migration from VMware.

Triggers: `pvecm`, `ha-manager`, `pvesh`, `pveum`, `pvesm`, `pvesr`, `pveceph`, `pveperf`,
`pveversion`, `qm`, `pct`, `vzdump`, `proxmox-backup-client`, `proxmox-backup-manager`,
`/etc/pve/` (`corosync.conf`, `storage.cfg`, `datacenter.cfg`, `qemu-server/<vmid>.conf`,
`lxc/<ctid>.conf`, `user.cfg`, `sdn/`), `/etc/apt/sources.list.d/pve-enterprise.*`,
`corosync-qdevice`, `pve-esxi-import-tools`, "node without quorum", "the cluster has split",
"the VM does not migrate", "PBS datastore", "verify job", "garbage collect".

**Internal arbitration rule**: if the answer is written with a `pve*`/`qm`/`pct` command or by
touching a file under `/etc/pve/`, it belongs to this skill. If it is written with `virsh` or by editing domain
XML, it belongs to `libvirt-kvm-standards`.

### 1.1 Boundary with `libvirt-kvm-standards` (the finest of the pair)

PVE uses KVM/QEMU, but **does not use libvirt**: it manages QEMU directly from `qemu-server`. As a
consequence:

| Decided here | Decided in `libvirt-kvm-standards` |
|---|---|
| Whether there is a cluster, quorum, HA and fencing | Whether the host is standalone and there is no platform |
| Storage as a **PVE type** (`storage.cfg`) and what supports snapshots | libvirt pool/volume, `qemu-img`, low-level disk format |
| The **VM profile** that PVE sets (virtio, agent, cluster CPU type) | The full **domain XML**: `machine type`, `iothreads`, `numatune`, `<cpu>` |
| Integrated backup (PBS/vzdump) and its retention | That there **is no** integrated backup: it is a reason not to use plain libvirt in production |
| RBAC, API tokens, resource pools | `libvirtd`/modular daemons, sVirt, socket and local permissions |
| Live migration as a **cluster operation** | The compatibility **requirements** that make it possible |

**The domain XML is not documented here.** If you are editing XML on a PVE host, you are almost always
doing something wrong (`args:` in the `.conf` is outside the supported model and breaks migration,
snapshots and support).

**Not applicable**: see `libvirt-kvm-standards` (**the sibling boundary**, §1.1 above: the
KVM/QEMU substrate without a platform; standalone hosts, lab, CI), `onprem-standards` (**umbrella**: its §2
sets the choice of hypervisor and VM backup and this skill develops it without contradicting it; its
§1.3 sets the invariants, in particular *HA without tested fencing is deferred corruption* and *a
backup without a tested restore does not exist*), `ha-clustering-standards`
(**surgical boundary**: there **generic** Pacemaker/Corosync to give HA to Linux **services**
(resources, constraints, OCF agents, device STONITH); here the PVE cluster, which brings its
own stack —`pve-cluster`/`pmxcfs`, `pve-ha-manager`, watchdog— and **is not operated with `pcs` or
`crm`**. Rule: **if the resource that fails over is a PVE VM or container, it belongs here; if it is a
service inside an OS, it belongs there.** Corosync is common to both: the principles of quorum,
latency and link redundancy hold the same), `zfs-standards` (**the pool underneath**: vdev
topology, `ashift`, the zvol's `recordsize`/`volblocksize`, ARC, scrub, `zfs send` as a mechanism — **the
pool design is theirs, its use as PVE storage is ours**), `bcdr-standards` (RTO/RPO
derived from the business, recovery order, DR exercises, disaster declaration — **PBS is
the tool, not the strategy**), `backup-recovery-standards` (**generic backup mechanics**:
restic/Kopia/Borg/Bareos, full/incremental chains, 3-2-1-1-0 topology, append-only repositories,
GFS, automated test restores — **PBS as a product and its jobs belong here**; the
cross-cutting criteria for retention, immutability and verification are theirs and this document does not contradict them),
`linux-storage-standards` (LVM and LVM-thin, multipath, iSCSI initiator, NVMe, filesystems and LUKS
**underneath** PVE storage: `storage.cfg` is ours, `lvs`/`multipath -ll`/`iscsiadm` are
theirs), `object-storage-standards` (the S3 bucket backing a
PBS datastore), `ceph-standards` (**everything about Ceph that `pveceph` does not expose**: CRUSH map and
failure domains, daemon sizing, PGs, BlueStore, *scrubbing* and upgrades between
named releases — here only the hyperconverged Ceph exactly as PVE integrates it),
`linux-administration-standards` (the node's Debian OS: systemd, journald,
diagnostics), `linux-hardening-standards` (the node's CIS baseline, `sshd_config`, auditd),
`selinux-standards` (MAC; PVE uses **AppArmor** for LXC — the profiles are theirs),
`networking-standards` (network **design**: VLAN, routing, BGP; here only the node's configuration and
PVE's SDN), `firewall-policy-standards` (**the filtering policy as a governed artifact**:
flow matrix, rule ownership and expiry, nftables; here only that the PVE firewall is
enabled with *default-deny* and expressed per VM/security group), `dns-standards`, `iac-standards`
(Terraform/OpenTofu and Ansible that **define** the VMs; here what the definition must contain),
`observability-standards` (metrics and alerting design; here **what** must be watched in PVE/PBS),
`kubernetes-standards` (containerised workloads on a K8s cluster, even if its nodes are PVE
VMs), `container-runtime-security-standards` (security of the running OCI container; PVE's LXC
**is not an OCI container** and its criteria are in §3.5),
`vulnerability-management-standards` (triage of a specific CVE), `identity-access-management-standards`
(the IdP PVE federates to), `secrets-management-standards` (custody of tokens and backup
encryption keys), `windows-server-ad-standards` (Windows VMs: virtio-win drivers, AD),
`incident-response-forensics-standards` (memory acquisition of a compromised VM),
`homelab-standards` (**the boundary is the rigour demanded, not the size**: there a lab PVE node
where the criteria are cost, noise and power draw; here production with a committed RTO/RPO),
`vmware-standards` (**boundary of origin, not of destination**: **the decision to stay or
leave VMware, its licensing model and what breaks when migrating are theirs**; **here the
destination platform** and its operation. PVE's import wizard is ours; the inventory
of what must be pulled out and its cost, theirs), `xen-standards` and `hyper-v-standards` (the
other two hypervisors in the catalogue, each with its own skill — the comparison is written from the
skill of the hypervisor in question, not here).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real system (§8).

| Area | Default | Justifiable alternative / Forbidden |
|---|---|---|
| PVE version | **PVE 9.2** (21 May 2026): Debian 13.5, kernel 7.0, QEMU 11.0, LXC 7.0, ZFS 2.4 | ❌ **PVE 8.x in production from Sep 2026: EOL on 31 Aug 2026** (the whole OS stops receiving patches, not just PVE). The 8.4 → 9.x jump by the official procedure, never by a hand-rolled dist-upgrade |
| PBS version | **PBS 4.2** (29 Apr 2026): Debian 13.4, kernel 7.0, ZFS 2.4 | PBS and PVE are updated **in coordination**; check compatibility before decoupling them |
| Cluster size | **3 nodes minimum** for HA (real quorum) | 2 nodes **only** with a QDevice (`corosync-qdevice`) at a third site; ❌ 2 nodes "with HA" without a QDevice; ❌ a standalone node acting as arbiter on a shared network |
| Corosync network | **Dedicated physical NIC**, latency **< 5 ms** between all nodes, and **at least 2 links** (`link0`/`link1` on different networks) | ❌ Corosync sharing the network with storage or replication (except as a **low-priority fallback** link); ❌ a single link over a bond as the whole redundancy story; >10 ms is unstable with more than 3 nodes |
| Fencing | **Watchdog** (hardware if the BMC offers it, `softdog` otherwise) configured and **exercised** before enabling HA | ❌ Enabling `ha-manager` without having powered off a node and timed the failover |
| Default storage | **Local ZFS + `pvesr` replication** for small clusters (2-5 nodes, RPO in minutes) | **Ceph** from **3 identical nodes** and with its own network; **NFS/iSCSI** if there is already an array and the SPOF it introduces is accepted |
| Ceph | Minimum **3 preferably identical servers**; `size=3`, `min_size=2`; **exclusive ≥ 10 Gbps** network | ❌ `min_size=1` (allows I/O with a single replica: data loss); ❌ Ceph with 3 nodes "because the minimum is 3" if there is neither a dedicated network nor a maintenance budget; realistic from **5 nodes** |
| Ceph release | **Tentacle 20.2.1** for new deployments on PVE 9.2; **Squid 19.2.3** is still packaged | The Ceph upgrade and the PVE upgrade are done **in separate steps** and in the documented order, never at the same time |
| VM network | **Linux bridge** with `VLAN aware`, over a **LACP bond (802.3ad)** to MLAG/stacked switches | **OVS** only if you need something the Linux bridge does not give (and you will know what it is); ❌ OVS "because it sounds better" |
| VM profile | **virtio-scsi single** + `qemu-guest-agent` + `discard` + `iothread`; UEFI/OVMF unless there is a reason | ❌ Emulated IDE/SATA or `e1000` outside a rescue boot; ❌ a production VM without the agent (breaks consistent snapshots, ordered shutdown and IPs in the GUI) |
| CPU type | **A named model common to the whole cluster** (the highest all nodes support), defined as a custom CPU model in the datacenter | ❌ `host` in a heterogeneous cluster: **it breaks live migration** and, on vulnerable kernels, exposes nested virtualisation paths (§5) |
| Containers | **Unprivileged LXC** (the default since PVE 4.4) for internal services that do not need their own kernel | **VM** whenever there is multi-tenancy, untrusted code, a different kernel or an isolation requirement; ❌ privileged LXC treated as a security boundary (§3.5) |
| Backup | **PBS** with **client-side** encryption, `verify` + `prune` + `garbage-collect` scheduled and **sync to a second repository** | `vzdump` to NFS only as a one-off secondary copy; ❌ standalone vzdump without verification or retention as the only copy; ❌ "backup" = hypervisor snapshot |
| Automation | **API token with a least-privilege role** and `privsep`, per service | ❌ `root@pam` (or its token) in Terraform, Ansible, CI or an exporter |
| Repos | **`pve-enterprise` with a subscription** in production | `pve-no-subscription` is technically valid but **it is not the tested package queue**; ❌ `pvetest` in production; ❌ mixing third-party Debian repos on the node |

## 3. Design and conventions

### 3.1 Cluster and quorum

- The PVE cluster is **pmxcfs over Corosync**: `/etc/pve` is a replicated filesystem that **becomes
  read-only when quorum is lost**. A node without quorum does not start VMs nor accept changes: that is the
  design working, not a fault.
- **Odd number of nodes** or a QDevice. With an even number and no arbiter, a 50/50 partition leaves the
  whole cluster read-only.
- **Corosync tolerates little latency and no jitter, but needs almost no bandwidth.** That is why
  the rule is a **dedicated** network, not a fast network: a clean 1 Gbps link is better than sharing a
  25 Gbps one with Ceph. Corosync supports up to 8 links; use **at least 2, on different physical paths**.
- A bond **is not a substitute for a second link**: it protects against a cable failure, not against a badly
  configured switch, a loop or a broadcast storm that hits the whole bond.
- A new node: it joins **empty**; joining a node with defined VMs destroys its `/etc/pve`. Removing a
  node is `pvecm delnode` and **the hostname/VMID is not reused without reinstalling**.
- Corosync links are changed with the cluster **healthy** and following the procedure
  (`corosync.conf` with an incremented `config_version`, distributed by pmxcfs); editing by hand on a
  node without quorum splits the cluster.

### 3.2 HA and fencing

- `ha-manager` only acts on declared resources; a critical VM that nobody added to HA **does not
  fail over**. Inventory which resources are HA and which are not, explicitly.
- **Fencing in PVE is by watchdog + quorum loss**: the node left without quorum
  self-reboots. This implies that **the cluster network is the fencing mechanism**: if it is fragile,
  fencing fires on its own. Another reason for a dedicated, redundant network.
- **HA groups / affinity rules** (PVE 9: affinity and anti-affinity rules): use them to separate
  the nodes of an application cluster (etcd, replicated database) and to co-locate VMs that
  talk to each other a lot. Without anti-affinity, HA can gather the three replicas on one node.
- **Failover is rehearsed by powering off a node** (physical `poweroff` or cutting the PSU, not an
  ordered `shutdown`), in an agreed window, timing how long until the service responds. Without that
  rehearsal, HA is a ticked box, not a capability. Invariant of `onprem-standards` §1.3.
- The PVE 9.2 dynamic load balancer relocates load; **it does not replace anti-affinity nor
  sizing**: a cluster that only holds up with N live nodes does not tolerate losing one.

### 3.3 Storage

Criteria, in order of preference by **the simplest thing that meets the RPO**:

1. **Local ZFS + scheduled replication (`pvesr`)** — 2 to 5 nodes. RPO = replication interval
   (minutes), not zero. No storage network, no array, no data quorum. It is the default
   option for most small clusters. The pool design belongs to `zfs-standards`.
2. **Ceph** — from **3 identical nodes** per the documentation, but **realistic from 5**: with 3
   nodes, losing one during maintenance leaves you with no rebuild headroom. It requires its own network
   ≥10 Gbps (25+ for internal traffic in serious deployments) and **an owner who maintains it**. Badly
   sized Ceph is worse than NFS.
3. **NFS / iSCSI / FC against an array** — valid if the array already exists and its HA is real. It introduces a
   SPOF external to the cluster and its latency. With LVM over iSCSI/FC, PVE 9 brings snapshots over shared
   *thick* LVM by means of volume chains; verify the exact support for your storage
   type before promising snapshots.

Cross-cutting rules:

- **Snapshots depend on the storage type.** Do not promise snapshots or a consistent backup without
  checking what that storage supports in the installed version — it is the usual cause of "I cannot
  take a snapshot before updating".
- **Thin provisioning is watched or it corrupts**: on LVM-thin and ZFS, overcommitting without an alert on
  real usage ends in a full pool and VMs read-only or corrupted. Alert with a threshold and headroom
  (ZFS: do not go past 80%).
- **A snapshot is not a backup** (it lives in the same pool and dies with it) and **a snapshot with memory
  is not one either**: it is a local restore point.
- The VM's disk on ZFS is a **zvol**: its `volblocksize` is a `zfs-standards` decision and is
  set **at creation**; changing it requires recreating the volume.

### 3.4 Networking and SDN

- **Plane separation, mandatory**: management/PVE-UI, Corosync, storage/replication,
  VM traffic and backup. Minimum: Corosync apart from everything else; storage apart from
  VM traffic.
- The PVE management interface **never exposed to a user network or to the Internet**: bastion or VPN. Port
  8006 on the Internet is an incident waiting for a date.
- **A VLAN-aware Linux bridge** over a LACP bond is the default case and the best supported. OVS adds
  surface and failure modes; it is justified by a concrete function, not by preference.
- **PVE SDN**: integrated into the product and actively developed. Simple/VLAN/QinQ/VXLAN zones
  and **EVPN** for L3 between nodes; **Fabrics** (PVE 9.0: OpenFabric and OSPF; 9.1: OSPF route
  redistribution and multiple EVPN controllers; 9.2: **WireGuard** protocol, BGP route-maps and prefix-lists,
  IPv6 underlay for EVPN) build spine-leaf topologies from the interface instead of editing
  FRR by hand. **Check in the release notes which part is marked experimental in your exact
  version before putting it into production**: the SDN has matured in parts, not as a block.
- PVE firewall: enable it at the datacenter level with a **default-deny** inbound policy and
  rules per VM/security group. A host firewall enabled without a management rule locks you
  out: change it with an OOB console open.

### 3.5 VMs and containers

- **The LXC vs VM decision is about isolation, not performance.** LXC shares the kernel with the host.
  A **privileged LXC is not a security boundary**: root inside is root on the host (without
  UID remapping), and the LXC project itself declares that configuration insecure and **does not treat
  escapes from a privileged container as CVEs**. What is left is namespaces, capabilities and
  AppArmor: defence in depth, not a trust boundary.
- **Unprivileged** LXC (the default) remaps UID 0 to an unprivileged host UID, and it is the only
  mode that can be reasoned about as a boundary. Cases that still push towards privileged (kernel NFS/CIFS
  client, some GPU passthrough): if they show up, **the correct answer is usually a VM**.
- No multi-tenancy and no untrusted code in LXC: **that is a VM**.
- **Templates + cloud-init** for everything created more than once; VMID and naming by convention;
  the definition lives in the IaC repo (`iac-standards`), not in clicks.
- **Coherent CPU across the cluster**: a common named model (or a datacenter custom CPU model,
  editable from the GUI in 9.2). `host` maximises performance and **minimises portability**.
- Ballooning: useful for overcommitting memory in environments with decoupled peaks; **disable it**
  on VMs with memory pinned by the application (databases, a sized JVM, hugepages). NUMA
  enabled on large VMs and `cores`/`sockets` coherent with the hardware.
- `args:` in the VM's `.conf` (passing arguments straight to QEMU) is a **last resort**: it is not
  supported, it can break migration and snapshots, and it drops out of the model on every upgrade.

### 3.6 PBS

- **Model**: a datastore with chunk-based deduplication + **client-side encryption** (the client holds the
  key; PBS stores ciphertext and **cannot restore without it**). Hard corollary:
  **the key is kept outside the backed-up system** or the backup is confetti
  (`secrets-management-standards`, `bcdr-standards`).
- **The three jobs are mandatory and distinct**: `verify` (re-reads and checks the integrity of the
  chunks — a backup never verified is not tested), `prune` (applies the retention policy by
  marking snapshots) and `garbage-collect` (actually frees the space of unreferenced chunks).
  Prune without GC frees nothing; GC without prune deletes nothing. Schedule all three and **alert if they fail**.
- **Namespaces** to separate sources/tenants within a datastore, and **sync jobs** (pull or push)
  towards a second PBS, ideally at another site and **outside the production trust domain**
  (ransomware attacks the reachable backup first). PBS 4.2 adds server-side encryption for push sync
  and `worker-threads` to parallelise groups over high-latency links.
- **S3 backend**: introduced as a *technology preview* in PBS 4.0 and **officially supported since
  PBS 4.2** (29 Apr 2026), with a request and traffic counter per datastore. Limits that change the
  design: each S3 datastore is managed by **a single PBS instance**, there is a local cache of metadata
  and chunks, and **PBS does not support Object Lock or versioning** — enabling Object Lock on the bucket can
  damage the datastore's structure. Conclusion: **S3 is an additional / cheap offsite copy, it does not
  replace the local PBS nor does it by itself provide the immutability** the ransomware scenario demands.
  Verify this point in the official documentation before designing on top of it (§8).
- **The hard rule**: *a green job is not a backup*. What counts is a **real, timed
  restore**: a single file, a whole VM and —at least once— **PBS itself** from scratch. It is
  scheduled, measured against the RTO and the result goes into monitoring.
- The **strategy** (what is protected, with which RTO/RPO, in what order it is recovered, who declares the
  disaster) belongs to `bcdr-standards`. Here only the mechanics of the product.

### 3.7 Operation

- **Real RBAC**: roles by function over paths (`/vms/<id>`, `/storage/<id>`, `/pool/<pool>`), resource
  pools to group by service/customer, and **API tokens with `privsep`** and minimum
  permissions per integration. `root@pam` is for emergencies, with the password in a secrets manager and
  MFA (TOTP/WebAuthn) mandatory on every human account. Authentication against the corporate IdP
  (LDAP/AD/OIDC) for people; local tokens for machines.
- **Rolling update across the cluster**, one node at a time: `migrate` out → `apt full-upgrade` →
  `reboot` → check quorum, HA and the state of Ceph/ZFS → **rebalance** → next node. Never two
  nodes at once; never with the cluster degraded or Ceph in `HEALTH_WARN` because of a rebuild.
- **Kernel and microcode**: a reboot is required; plan it in the same window. Verify the kernel
  actually booted (`uname -r`) against the installed one, not the package.
- **Life cycle**: a PVE major is supported while its base Debian is *oldstable*, ~3 years
  from its release. Have the jump dated **before** the EOL, with a staging node or cluster that walks
  the path first.

### 3.8 Migration from VMware

- Context (verify it, it changes every quarter): post-Broadcom licensing —the end of perpetual
  licences, withdrawal of free ESXi, minimums of 16 cores per CPU and 72 cores per order in
  VCF/VVF, cost increases of several multiples— has driven a mass exit; Proxmox VE is the
  main recipient and XCP-ng/Vates a smaller but living alternative. **The platform decision belongs
  to `onprem-standards` §2**; here, how the migration is executed.
- **Integrated import wizard** (ESXi-type storage, `pve-esxi-import-tools`): it imports the
  whole VM mapping most of the configuration, with a live-import option to
  reduce downtime. Verified limits: tested with **ESXi 6.5 to 8.0**; **disks on vSAN do not
  work**; an overloaded ESXi **rate-limits requests and blocks imports in flight** (the
  `esxi-folder-fuse` service limits to 4 parallel connections); free ESXi **does not expose the API** the
  wizard needs. In the field, connecting **straight to the ESXi host** usually works where vCenter fails,
  and live import requires a very stable network. These limits come from documentation and reports
  from 2024-2025: **re-verify the current state in the wiki and Bugzilla before planning** (§8).
- **Before moving anything**: install **virtio and qemu-guest-agent in the guest while it is still on
  ESXi** (on Windows, the virtio-win drivers). Migrating first and then fighting a Windows that does not
  boot because the disk controller changed is the classic mistake.
- What frequently breaks: BIOS/UEFI boot and boot order, disk controller, network interface
  names (and with them static IPs and firewall rules), leftover VMware Tools, licences
  tied to UUID/MAC, independent disks or RDMs, and everything depending on vSphere features with no
  equivalent (DRS affinities, storage policies). **Migrate in batches, with a window and a rollback
  plan**; the original VM is kept powered off until validation.

## 4. Quality gates

Before signing off a PVE/PBS platform:

1. **Quorum verified**: `pvecm status` with all the expected votes, and `corosync-cfgtool -s` with
   **all links up**. A link down for weeks with nobody aware is the state right before
   every split cluster.
2. **Corosync latency measured** (< 5 ms, without spikes) and a **demonstrably separate cluster network**
   from storage and from VM traffic.
3. **Fencing tested**: abrupt power-off of a node with HA active; the time until the
   service comes back is recorded and compared with the committed RTO. Half-yearly at minimum.
4. **Restore tested and timed**: a file + a whole VM from PBS, with the result in
   monitoring. A green `verify` does **not** count as a restore.
5. **`verify`, `prune` and `garbage-collect` scheduled** and with a failure alert on all three.
6. **No `root@pam` in automation**: audit `/etc/pve/user.cfg` and the tokens; every integration
   with its own token and its minimum role.
7. **VM profile audited**: all production VMs with virtio, `qemu-guest-agent` active and
   the cluster's CPU model. The exception list justified in writing.
8. **No privileged LXC** except for a documented exception, with an owner and a review date.
9. **Storage usage below the threshold** (ZFS < 80%, thin pools with headroom) and alerting by prediction,
   not by "full".
10. **Versions up to date and coherent**: `pveversion -v` the same on all nodes; no EOL branch in
    production; PVE and PBS compatible with each other.

## 5. Security

- **CVE-2026-53359 ("Januscape", disclosed 06 Jul 2026)**: **guest → host** escape in the x86 shadow
  MMU of KVM (Intel VMX/EPT and AMD SVM/NPT), affecting VMs with **nested virtualisation**
  enabled. **Patching 53359 is not enough**: full remediation also requires **`CVE-2026-46113`**
  (fixed in May 2026; it covers the *leaf shadow page* case, 53359 the *non-leaf* one).
  Proxmox published fixed kernels (**`proxmox-kernel-6.8.12-33-pve`
  and `proxmox-kernel-7.0.14-4-pve`** or later; Debian, DSA-6381-1). Action: **patch and
  reboot**, audit which VMs have nested virt or `host` CPU, and **disable nested unless there is a demonstrated
  need**. Nested is not exposed by default: it requires the explicit flag or the `host` CPU
  model — another reason not to use `host` indiscriminately. **Verify the minimum version
  pinned today before quoting it** (§8).
- **Interface surface**: PVE-UI/API (8006), SPICE/VNC proxy, SSH between nodes and PBS (8007) go
  on the management plane, **with no route from user networks**. TLS with a certificate from the internal PKI
  (ACME/step-ca), not the default self-signed one.
- **Multi-tenancy**: the boundary between tenants is **the VM**, never the LXC. Add network
  separation (VLAN/SDN + per-VM firewall) and pools + RBAC; without all three, "multi-tenant" is a label.
- **Backup isolation**: the destination PBS does **not** authenticate with production-domain
  credentials, and the remote sync is preferably **pull from the destination**. A PBS that production
  can delete does not protect against ransomware.
- **AppArmor** confines the LXCs; disabling it "so it works" turns any container into a
  de facto privileged one. The correct diagnosis goes through `selinux-standards` (MAC profiles).
- Encryption at rest: client-side encryption in PBS **always**; the node's disk with LUKS or ZFS
  native encryption where the data demands it; keys outside the host.
- Subscription and repos: `pve-enterprise` is also a security decision (a tested package queue
  and support). No third-party repo on the hypervisor node: the node is not an application
  server.

## 6. Performance and observability

- **What to watch as a minimum** (the stack design belongs to `observability-standards`): cluster state and
  votes, Corosync links, HA state per resource, Ceph/ZFS health (scrub, resilver,
  degradation), real usage of each storage with prediction, memory pressure and ballooning,
  `steal time` in guests, state and age of the last backup **and of the last tested restore**,
  `verify` failures, PBS GC, certificate expiry, NTP drift and temperature/SMART.
- Every alert links a runbook. An alert nobody can act on is removed (`onprem-standards` §6).
- **Overcommit**: vCPUs are overcommitted with judgement (watch `steal`); **memory is not
  overcommitted in production** except with ballooning understood and measured — the host's OOM takes
  VMs down with it.
- Live migration: real cost in memory and network. With large VMs and a slow migration network, the
  maintenance window is calculated, not improvised; a dedicated migration network if the cluster is
  large.
- Capacity with **N-1 as a requirement**: the cluster must absorb the loss of a node (two, if
  maintenance coincides with a failure) without overcommit. Otherwise there is no HA, there is hope.

## 7. Sustainability and prohibitions

**Cadence**
- PVE/PBS minor: monthly, rolling across the cluster. Kernel/microcode: monthly or on an exploitable CVE.
- Major: after reading the full release notes and testing in staging, **with a date before the EOL of the
  current branch** (PVE 8 → 9 before 31 Aug 2026).
- Ceph: its upgrade is a project of its own, in steps and in the documented order (check the minimum
  versions of `pve-manager` and of the Ceph packages before starting). Never at the same time as PVE's.
- BMC/NIC/HBA/disk firmware: quarterly review.

**FORBIDDEN**
- ❌ Enabling HA without fencing/watchdog **tested by powering off a node**. Platform invariant.
- ❌ A 2-node cluster with HA and no QDevice; an even number without an arbiter.
- ❌ Corosync sharing the network with storage, replication or backup; a single link.
- ❌ Editing `corosync.conf` by hand on a node without quorum, or joining a node with VMs to the cluster.
- ❌ Running PVE 8.x in production after its EOL (31 Aug 2026) without a dated exit plan.
- ❌ `root@pam` (or its token) in Terraform, Ansible, CI, exporters or any automation.
- ❌ Exposing 8006/8007 or the BMC to a user network or to the Internet.
- ❌ Privileged LXC as isolation for untrusted code or for another tenant.
- ❌ A production VM without `qemu-guest-agent`, or with emulated IDE/SATA/`e1000`.
- ❌ `host` CPU in a heterogeneous cluster (it breaks live migration) and nested virt without need.
- ❌ `args:` in the VM's `.conf` as permanent configuration.
- ❌ Treating a snapshot (with or without memory) as a backup; a single copy; PBS in the same chassis or
  pool as production; the backup encryption key stored only inside the backed-up system.
- ❌ `prune` without `garbage-collect`, or any of the three jobs without a failure alert.
- ❌ Signing off a backup on the basis of a green job, without a timed restore.
- ❌ `min_size=1` in Ceph; Ceph without a dedicated network; Ceph without an owner who maintains it.
- ❌ Thin provisioning without a real-usage alert; ZFS pools > 80% without a plan.
- ❌ Updating two nodes at once, or updating with the cluster/Ceph degraded.
- ❌ Installing third-party repos or application services on the hypervisor node.
- ❌ Migrating from ESXi without installing virtio/guest-agent first, and without keeping the source VM powered off
  until validation.

## 8. Mandatory web verification

Before pinning any version, date or feature name, **look it up — do not remember it**. The
verification of this document (Aug 2026) and what remains open:

1. **Versions and EOL**: `pve.proxmox.com/wiki/Roadmap`, `pbs.proxmox.com/wiki/Roadmap` and the official
   life-cycle table. Verified: **PVE 9.2 (21 May 2026)** on Debian 13.5, kernel 7.0,
   QEMU 11.0, LXC 7.0, ZFS 2.4, Ceph Squid 19.2.3 and **Tentacle 20.2.1** (default on new
   deployments); **PBS 4.2 (29 Apr 2026)** on Debian 13.4, kernel 7.0, ZFS 2.4; **PVE 8 EOL
   31 Aug 2026**. It expires fast: re-verify.
2. **PBS S3 backend**: verified that it moved from *technology preview* (4.0) to **officially
   supported in 4.2**. **Declared gap**: the absence of **Object Lock/versioning** support and
   the risk of corrupting the datastore by enabling it on the bucket comes from third-party analysis,
   **not confirmed against official documentation** — confirm it before designing immutability over
   S3.
3. **Maturity of PVE's SDN**: features verified per version (Fabrics with OpenFabric/OSPF in
   9.0; OSPF route redistribution and multiple EVPN controllers in 9.1; WireGuard fabric, BGP route-maps
   and prefix-lists and IPv6 underlay in 9.2). **Declared gap**: **it has not been confirmed which
   subcomponents are still marked experimental** in the 9.2 documentation — check it in
   the release notes and in the SDN docs before taking them to production.
4. **VMware import wizard**: limits verified (ESXi 6.5-8.0, vSAN not
   supported, ESXi rate limiting, 4 parallel connections, API not exposed on free ESXi).
   **Declared gap**: the main source is documentation and reports from **2024-2025**; the state as of
   2026 has not been confirmed, nor which bugs have been closed. Consult the *Migrate to Proxmox VE* wiki and
   Bugzilla before planning a large migration.
5. **CVEs**: verified **CVE-2026-53359 "Januscape"** (guest→host escape via nested KVM) and the
   fixed kernels cited in §5. Re-verify the **currently valid minimum version** and look for later
   CVEs in QEMU, the KVM kernel and the `pve-*` packages before pinning a minimum.
6. **Ceph**: verified the documented minimum of **3 preferably identical servers**, `size=3`/
   `min_size=2`, an exclusive **≥10 Gbps** network and the recommendation of three networks (25+/10+/1 Gbps). Verify
   the requirements of the Ceph version you are going to deploy and the life cycle of that release.
7. **Corosync**: verified the **<5 ms** latency required, instability above ~10 ms with
   more than 3 nodes, dedicated NIC recommended, **up to 8 links**, and the explicit prohibition on
   sharing a network between corosync and storage.
8. **LXC**: verified that **unprivileged is the default since PVE 4.4** and that upstream declares
   privileged mode insecure and does not treat its escapes as CVEs.
9. **Market context** (changes every quarter): Broadcom/VMware licensing, core minimums,
   and the maturity of alternatives (XCP-ng/Vates, Nutanix). Verified as of Aug 2026 the general direction of the
   migration; the percentages cited in §3.8 come from third-party analysis and **not from a primary
   source**.
10. **Official upgrade procedure** (`Upgrade_from_8_to_9`, `pve8to9`, `Ceph_Squid_to_Tentacle`)
    and its minimum package versions: they are read in full before starting, never from memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
