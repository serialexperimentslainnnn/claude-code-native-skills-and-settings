---
name: ha-clustering-standards
description: High availability for services running inside an OS, with Pacemaker/Corosync as reference. Use when running pcs, crm/crmsh, crm_mon, crm_resource, crm_simulate, cibadmin, pcs stonith, pcs constraint or the ha_cluster system role, editing cib.xml, votequorum settings (two_node, wait_for_all, last_man_standing, auto_tie_breaker), corosync-qnetd/qdevice arbitration, STONITH agents (fence_ipmilan, fence_idrac, fence_ilo, fence_apc, fence_sbd, fence_vmware, fence_aws/fence_gce), sbd.conf and hardware watchdog fencing, stonith-enabled and no-quorum-policy, OCF resource agents, IPaddr2 virtual IPs, colocation and ordering constraints, resource-stickiness, clone and promotable resources, cluster maintenance-mode and standby, DRBD with drbdadm and drbd.conf, dlm with GFS2 or OCFS2 shared filesystems, Patroni patroni.yml versus a Pacemaker-managed PostgreSQL, keepalived.conf VRRP as a lighter alternative, split-brain and fence racing incidents, or answering whether a service needs a cluster at all.
---

# Service high availability standards (Pacemaker/Corosync)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Thesis of this document**: **HA without tested fencing is not HA, it is deferred data
> corruption.** A cluster that cannot kill a suspect node with certainty is not protecting the
> service: it is waiting for the day two nodes write the same data at the same time.
>
> **The corollary most often forgotten**: **a badly operated cluster has worse availability than a
> simple, well-monitored service.** Every node, every agent, every constraint and every
> fencing device is a new part that can fail — and it does fail. Complexity is the
> enemy of *uptime*. Apply KISS before applying Pacemaker.

## 1. Scope and triggers

Applies to providing high availability to **services running inside an operating system**:
the decision of whether a cluster is needed at all, quorum and arbitration, fencing/STONITH, resource
management with Pacemaker, shared or replicated storage, patterns by service type,
cluster operation and failover exercises.

Triggers: `pacemaker`, `pacemakerd`, `corosync`, `corosync-qnetd`, `corosync-qdevice`,
`votequorum`, `two_node`, `wait_for_all`, `last_man_standing`, `auto_tie_breaker`, `pcs`,
`pcsd`, `crm`, `crmsh`, `crm_mon`, `crm_resource`, `crm_simulate`, `crm_verify`, `cibadmin`,
`cib.xml`, `stonith-enabled`, `no-quorum-policy`, `resource-stickiness`, `migration-threshold`,
`failure-timeout`, `ocf:heartbeat:*`, `IPaddr2`, `Filesystem`, `systemd:` as a resource class,
`pcs constraint colocation|order`, `clone`, `promotable`/`master`, `fence_ipmilan`,
`fence_idrac`, `fence_ilo4`, `fence_apc_snmp`, `fence_sbd`, `fence_vmware_rest`,
`fence_aws`/`fence_gce`, `sbd`, `/etc/sysconfig/sbd`, `SBD_WATCHDOG_DEV`, `softdog`,
`drbdadm`, `drbd.conf`, `drbdsetup`, `dlm_controld`, `gfs2`, `mkfs.gfs2`, `ocfs2`,
`patroni.yml`, `patronictl`, `keepalived.conf`, `vrrp_instance`, `ha_cluster` (system role),
`cockpit-ha-cluster`, "split-brain", "the cluster failed over on its own", "both nodes think
they are primary", "the resource does not start and I do not know why".

**Internal arbitration rule**: if the answer is written with `pcs`/`crm`/`cibadmin` over a
Pacemaker CIB, or in `sbd.conf`/`drbd.conf`, it belongs to this skill.

### 1.1 Boundary with `proxmox-ve-standards` (mirror of the rule already written there)

`proxmox-ve-standards` already set the arbitration rule for this pair, and **this document mirrors it
verbatim**:

> **If the resource that fails over is a PVE VM or container, it belongs to `proxmox-ve-standards`;
> if it is a service inside an OS, it belongs here.**

With two clarifications that must be clear:

- **PVE ships its own HA stack** —`pve-cluster`/`pmxcfs`, `pve-ha-manager`, its HA groups and
  its watchdog— and **it is not operated with `pcs` or with `crm`**. Running `pcs` on a PVE node is a
  category error: there is no CIB to touch.
- **Corosync is common to both.** The principles of quorum, ring latency, link redundancy
  and node arithmetic hold equally on both sides; what changes is the resource
  manager on top.

### 1.2 HA is not DR (the domain's most common confusion)

| | HA (this skill) | DR (`bcdr-standards`) |
|---|---|---|
| Responds to | Failure of **one component** inside a failure domain | Loss of the **entire failure domain**: room, data centre, region, provider |
| Horizon | Seconds to minutes, **automatic** | Minutes to days, **with a human decision** to declare the disaster |
| Mechanism | Active redundancy and failover | Recovery from a copy or an alternate site |
| What it does **not** protect against | Logical deletion, corruption, ransomware, human error — **it replicates them instantly** | (that is exactly what it exists for) |
| Metric | Availability, MTTR | **RTO/RPO** derived from business impact |

**An HA cluster is not a backup and does not replace a continuity plan.** Synchronous
replication is a `DELETE` propagated in milliseconds. And conversely: an impeccable DR plan does not
avoid Tuesday's minute of downtime. **You need both, and they are different projects.**
`bcdr-standards` sets RTO/RPO and the recovery order; this skill sets the mechanism that
supports the availability objective set by `sre-practice-standards`.

**Not applicable**: see `proxmox-ve-standards` (**sister boundary, §1.1**: HA of PVE VMs and containers
with `ha-manager`, HA groups, affinity rules and its watchdog),
`kubernetes-standards` (**the orchestrator is the right answer to "make this service survive
its host going down"**: rescheduling, replicas, probes and PDBs. Pacemaker does not compete with that),
`podman-systemd-containers-standards` (**cross-reference, no overlap**: containers as systemd
services on a host. If the question is how they survive the host going down, the
honest answer is **almost never with Pacemaker**: an orchestrator, a load balancer in front of two
instances with the state outside, or downtime accepted in writing. Pacemaker managing
a host's containers is cluster complexity with none of its guarantees),
`bcdr-standards` (**§1.2**: RTO/RPO, BIA, DR exercises, alternate site, disaster
declaration), `backup-recovery-standards` (the copy and its tested restore — **replication is not
a copy**), `sre-practice-standards` (**availability as an objective is theirs**: SLI/SLO, error
budget, on-call, capacity; **the mechanism to reach it belongs here**. If the SLO is met without a
cluster, no cluster is built), `incident-management-standards` (declaration, roles and communication
of the incident; here the technical diagnosis of the cluster), `data-platform-standards` (**the data
engine and its replication are theirs**: PostgreSQL, its streaming replication, tuning, PITR, Redis,
Kafka; **here the cluster mechanism that promotes or fails over** — see §5.2, where the criterion is
that for PostgreSQL the default answer is **not** Pacemaker), `linux-storage-standards`
(LVM, multipath, iSCSI, local filesystems and LUKS **underneath** the cluster resource),
`zfs-standards` (the pool; ZFS **is not** a cluster filesystem and is not mounted on two nodes),
`ceph-standards` (**frequent confusion: Ceph's monitor quorum is not Corosync's quorum,
and Ceph does not use STONITH** — its high availability comes from RADOS through replication and the CRUSH map,
not from a resource manager; MON/OSD sizing and their failure domains are theirs),
`linux-administration-standards` (**systemd**: a cluster-managed resource **is not
touched with `systemctl`** — it is already forbidden there and confirmed here), `networking-standards`
(network design, VLANs, VRRP at the network level, MTU; here the cluster's use of the network and its
latency requirements), `firewall-policy-standards` (the filtering policy that must allow
Corosync traffic and the fencing devices),
`observability-standards` (design of the metrics and alerting stack; here **what** to watch on the
cluster and **from where**), `identity-access-management-standards` (BMC credentials and their
custody; here the fact that fencing needs those credentials and that they are highly privileged),
`secrets-management-standards` (where those credentials live), `onprem-standards` (**umbrella**:
its §1.3 sets the invariant *HA without tested fencing is deferred corruption*, which is this
document's thesis, and its §6 ceded the detail of the HA block to this skill),
`microservices-architecture-standards` (**distributed resilience in the application** —circuit
breakers, retries with backoff, bulkheads, sagas— versus infrastructure HA: **a
well-designed application needs less cluster**, and that is the right order of investment),
`windows-server-ad-standards` (WSFC and Windows clustering).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8). In clusters,
> **the version that rules is the one your distribution packages and supports**, not upstream's:
> nothing is compiled by hand here.

| Component | Status (Aug 2026) | Criteria |
|---|---|---|
| Pacemaker | **3.0.3** (2026-07-28) and **2.1.11** (2026-06-29): **both lines alive** | 3.0 (GA 2025-01-08) exists to **remove deprecated legacy syntax**. Greenfield → 3.0.x if the distro ships it; otherwise 2.1.x, no drama |
| Corosync | **3.1.10** (2025-11-15) | Annual cadence (releases in November). Stable and boring, which is what you want in the membership layer |
| `pcs` | **0.12.3** (2026-07-10) / **0.11.12.1** (2026-07-14) — two maintained lines | **The tool on RHEL/Fedora/Ubuntu.** On RHEL 10, the **standalone `pcsd` web UI no longer exists**: it moves to `cockpit-ha-cluster` |
| `crmsh` | **5.0.0** (2025-08-15); **5.1.0-rc2** (2026-06-29) | **The tool on SUSE/SLES.** SLE HA 16 is built around `crm cluster init`. **Neither `pcs` nor `crmsh` is obsolete**: you choose by vendor support, not by taste |
| `resource-agents` | **4.18.0** (2026-04-08) | Active |
| `fence-agents` | **4.17.0** (2026-01-05) | Active |
| `sbd` | **1.5.2** (2023-01-09) — last *release*; repository with activity (commits in Jan 2026) | **Slow cadence**: use it with the version your distro packages and do not assume recent upstream fixes. It is still the reference mechanism when there is no PDU/BMC |
| DRBD (module) | **9.3.3** (2026-07-01) out-of-tree from LINBIT; **10.0.0 in alpha** — do not touch | **The DRBD in the mainline kernel is 8.4.11, from ~8 years ago.** LINBIT is upstreaming 9.3 (it could land in Linux 7.2, Sep/Oct 2026). Today: **out-of-tree module via DKMS**, with everything that implies for kernel patching |
| `drbd-utils` | **9.34.0** | **Do not mix `drbd-utils` 9.x with the in-tree 8.4 module**: the config syntax does not match and it produces confusing failures |
| Patroni | **4.1.4** (2026-07-07); lines 4.0.10 and 3.3.11 patched the same day | **Default answer for PostgreSQL HA** (§5.2) |
| keepalived | **2.4.3** | VRRP: a **lightweight** alternative for a virtual IP without a full cluster (§5.5) |
| Automation | The **`ha_cluster`** system role (RHEL) or `crm cluster init` (SUSE) | A declarative, versioned cluster > an irreproducible interactive `pcs` session |

**Status of cluster filesystems — an important, verified change**:

- **GFS2 is leaving Red Hat.** The *Resilient Storage Add-On* **is discontinued from RHEL
  10 onwards**: the `gfs2-utils`, `dlm` and `ctdb` packages are discontinued and **the `gfs2` and `dlm`
  modules have been removed from the RHEL 10 kernel**. It remains supported on RHEL 7/8/9 until the end of their
  maintenance cycle — that is your migration window, not an open-ended extension.
- **OCFS2 is leaving SUSE.** Deprecated in SLE HA 15 SP7 and **it will not be in SLE HA 16**; SUSE
  documents migration **to GFS2** (warning: GFS2 **does not support reflink**, unlike OCFS2).
- **The two distributions have swapped their preferred cluster filesystem.** Any
  multi-vendor design has to take that on board.
- **Consequence for criteria**: on RHEL 10+ **there is no supported shared-block filesystem
  in the kernel**. Active/active design over shared disk stops being a default
  option; what remains is active/passive with XFS over shared storage, distributed
  storage (CephFS and similar) or exporting over NFS/SMB from an active/passive pair. **Choosing GFS2
  today for something new requires justifying the lifecycle.**

## 3. The prior question: do you really need HA?

**It is the most important section in the document.** Before installing anything, answer in writing:

1. **Which SPOF does the cluster remove, and which ones does it leave?** A two-node cluster in the same rack,
   with the same PDU, the same switch and the same storage array removes almost nothing: it moves the single
   point of failure from the server to the switch. **Draw the failure domains before buying
   licences.**
2. **What is the availability objective, and where does it come from?** If it comes from an SLO with business
   impact behind it (`sre-practice-standards`), go ahead. If it comes from "we want it not to
   go down", there is no requirement, there is anxiety.
3. **How much does a minute of downtime really cost?** Compare it with the cost of operating a cluster:
   a second node, fencing devices, a dedicated network, training, double patching windows and
   a new failure mode nobody on the team has seen before.
4. **Who operates this at 3 in the morning?** A cluster only one person understands **reduces**
   real availability. If the on-call team cannot read a `crm_mon` or know when to put the
   cluster into maintenance, the cluster is a risk, not a control.
5. **Is the service's state compatible with failover?** A service that takes 8 minutes
   to recover its database after a dirty shutdown gains nothing from a 20-second failover.

### 3.1 Simpler alternatives that almost always suffice

They are ruled out **in writing** before building Pacemaker:

| Alternative | When it suffices |
|---|---|
| **A service with `Restart=on-failure` and monitoring** | When the typical failure is the process dying, not the hardware burning. It covers most real incidents |
| **A load balancer in front of N stateless backends** | The most robust pattern there is: no quorum, no fencing, no split-brain. **If you can move the state out of the service, do it and save yourself the whole cluster** |
| **A replica with a documented manual promotion** | An RTO of minutes is acceptable. A tested runbook + a daily replica is worth more than a cluster nobody has exercised |
| **VRRP (`keepalived`) for the IP** | All you need is an IP moving between two nodes. No CIB, no fencing, no agents |
| **An orchestrator** | The service is already in containers and what you want is automatic rescheduling |
| **A managed service / the provider's cluster** | In the cloud: somebody else operates the HA and it comes out cheaper than yours |

**Decision rule**: build Pacemaker when you need **automatic failover of a stateful
resource with guaranteed mutual exclusion** — and you are willing to maintain tested fencing.
In any other case, there is a simpler answer, and the simpler answer is the correct one.

## 4. Quorum, split-brain and fencing

### 4.1 Quorum

- **Three nodes as the minimum sane number.** Quorum is arithmetic, not opinion: with 3 nodes
  you survive the loss of 1 with a real majority.
- **Two nodes with no arbiter is a data-corruption machine.** Faced with a partition, both nodes
  see "the other is not there" and both conclude the same thing. The only thing that stops both mounting
  the data is fencing — and if fencing also depends on the partitioned network, it stops nothing.
- `votequorum` parameters (verbatim text from the manual, so they are not quoted from memory):
  - **`two_node`**: *"Enables two node cluster operations (default: 0)"*; it artificially sets
    quorum to 1 in two-node clusters. Note from the manual: *"enabling `two_node: 1` automatically
    enables `wait_for_all`"*.
  - **`wait_for_all`**: *"Enables Wait For All (WFA) feature (default: 0)"* — the cluster
    *"will be quorate for the first time only after all nodes have been visible at least once at
    the same time"*. Operational translation: **it prevents a single node booting alone after a general
    outage and declaring itself owner of everything**. It is a real and cheap protection.
  - **`last_man_standing`**: dynamically recalculates `expected_votes` and quorum under certain
    conditions, with a configurable window (10 s by default). **Dangerous without impeccable
    fencing**: it lowers the quorum bar precisely when the cluster is degraded.
  - **`auto_tie_breaker`**: allows surviving the simultaneous loss of 50 % of the nodes
    deterministically; by default the lowest `nodeid` wins, adjustable with
    `auto_tie_breaker_node`.
- **`corosync-qnetd` + `corosync-qdevice` is the right answer for two nodes.** A third
  arbiter that **does not have to be a cluster node** (a small host in another failure
  domain). A ridiculous cost compared with what it avoids. **A two-node cluster with no qdevice and no
  reliable fencing does not go into production.**
- **The arbiter has to be in another failure domain.** A qnetd in the same rack, the same
  switch or the same VM as a node arbitrates nothing.
- **Corosync network**: dedicated or at least isolated, with **link redundancy** (several
  `ring`s), low and stable latency. Corosync is sensitive to latency and jitter: **a network
  shared with backups or replication produces spurious fencings at 3 in the morning**. The
  design of that network belongs to `networking-standards`; the requirement comes from here.
- **`no-quorum-policy`**: the sensible default is `stop` (stop resources on losing quorum).
  `ignore` is the express route to split-brain and only makes sense in very specific configurations
  with perfect fencing. **`no-quorum-policy=ignore` copied from a blog is a common cause of
  data loss.**

### 4.2 Fencing / STONITH: the thesis

**Without tested fencing there is no HA.** The cluster cannot distinguish "the node is dead" from "the
node is not answering me but is still writing to disk". The only way to turn that
uncertainty into certainty is **to kill the node** and confirm it has died.

- **`stonith-enabled=false` is this domain's cardinal sin.** It is the line that appears in
  every "build your first cluster" tutorial and in every corruption postmortem.
  It is **forbidden** outside a disposable lab, and in a lab it is documented as such.
  A cluster with STONITH disabled is not a degraded cluster: it is two servers with a
  system giving them permission to trample each other.
- **Agents by platform** (choose by what is underneath, not by what is easy):

| Substrate | Agent | Warning |
|---|---|---|
| Physical server with a BMC | `fence_ipmilan`, `fence_idrac`, `fence_ilo4`/`fence_ilo5` | **The BMC has to be on a network that survives the partition**, and its credentials are extremely privileged (`identity-access-management-standards`). A BMC powered by the same PSU as the node is not always any use |
| Managed PDU | `fence_apc_snmp` and equivalents | Reliable and brutal. Careful with dual-power servers: **you have to cut both feeds** or nothing switches off |
| No BMC and no PDU | **SBD** (`fence_sbd`) | Disk mode (1–3 devices; 2–3 recommended for critical workloads) or **diskless** with a watchdog only |
| Hypervisor | `fence_vmware_rest`, libvirt agents | The hypervisor becomes the fencing SPOF: bear it in mind |
| Cloud | `fence_aws`, `fence_gce`, `fence_azure_arm` | They depend on the provider's API and on credentials: an outage of the provider's API is a fencing outage |

- **SBD**, verified and non-negotiable clarifications:
  - **Hardware watchdog, always.** ClusterLabs is explicit: a **software** watchdog
    depends on the OS working correctly, and is therefore **not reliable for fencing**.
    `softdog` is fine for a lab and **for nothing else**.
  - The `sbd` daemon **must be started before the cluster services**, and **the cluster
    cannot manage it as a resource**. It is infrastructure, not a resource.
  - Disk mode: the shared device is a SPOF; with 2–3 devices in different arrays
    it stops being one.
- **`fencing loop`**: node A kills B, B boots, they do not agree, it kills A, and so on until
  somebody stops it. It is mitigated with a delay on starting the cluster services after
  boot and with `wait_for_all`.
- **`fence racing`**: both nodes of a pair fire simultaneously and the cluster is left with
  nobody. It is mitigated with an **asymmetric delay** on the fencing devices (`pcmk_delay_base` /
  `pcmk_delay_max`, different per node) so one always wins.
- **Fencing topology**: when there are several mechanisms (BMC + PDU), the **order and the
  fallback** are defined (`pcs stonith level`), not two loose agents left competing.

### 4.3 THE MANDATORY TEST

**Before a cluster takes production traffic, a node is powered off dirty.** Not
`pcs cluster stop`, not `reboot`: **cut the power, `echo c > /proc/sysrq-trigger`, or
unplug the active node's network.** And you check:

1. The surviving node **fences** the other and confirms it (it does not "believe" it has switched it off).
2. The resources start on the survivor within the expected time, and it is **timed**.
3. The data is **intact**: consistent filesystem, database with no corruption, no double
   writes.
4. The fenced node, on returning, **does not take out** the one that is serving.
5. And it is repeated **causing a network partition** instead of the power-off: it is a different failure and
   reveals whether fencing depends on the network that has just partitioned.

**A cluster that has not passed this test is not in production, it is in testing** — however
it behaves the rest of the time.

## 5. Pacemaker in practice and patterns by service

### 5.1 Resources, agents and constraints

- **Agent class**: `ocf:` when an OCF agent exists (it has a real `monitor` and state
  semantics), `systemd:` when what you manage is an existing, well-built unit. **`lsb:`
  only in legacy**: init scripts lie about state.
- **Every resource carries a `monitor` operation with an explicit `interval`.** A resource with no monitor is
  a resource the cluster believes alive forever. And with a **realistic** `timeout`: a short
  timeout on a slow service produces phantom failovers; a long one lengthens the real outage.
- **`resource-stickiness` > 0 by default.** Without *stickiness*, the resource goes back to the
  "preferred" node as soon as it reappears, causing **a second free outage** right after the
  first. Failback is a decision, not a reflex.
- **`migration-threshold` + `failure-timeout`**: they limit how many failures a resource tolerates on a
  node before moving, and when the failure is forgotten. Without them, a resource bounces between nodes.
- **Badly placed constraints are the number 1 cause of surprise failovers.** Criteria:
  - **Colocation** (`colocation`) and **ordering** (`order`) are different things and are confused
    daily: "together" does not imply "in this order". **Both** are declared when applicable.
  - Intermediate `score`s (neither `INFINITY` nor 0) produce behaviours nobody predicts.
    **Use `INFINITY` or do not add the constraint.**
  - A **group** (`group`) is syntactic sugar for implicit colocation + ordering. Convenient and
    readable; but it implies that **a member's failure drags the following ones with it**. If that is not
    what you want, do not use a group.
  - **`clone`** for stateless active/active services; **`promotable`** for the
    primary/replica pattern.
  - **`crm_simulate` before applying** any constraint change in production: it tells you
    what the cluster is going to move **before** it moves it. It is the most underused tool in the
    stack.
- **The CIB is configuration, and it is versioned.** It is exported (`pcs cluster cib` / `cibadmin -Q`) to the
  repository, and deployed with the `ha_cluster` role or equivalent (`iac-standards`). **Editing
  `cib.xml` by hand on disk is forbidden** — use `pcs`/`crm`/`cibadmin`.

### 5.2 PostgreSQL: **Patroni, not Pacemaker** (a clear criterion)

**For PostgreSQL, the default answer today is Patroni + a distributed DCS (etcd or Consul)
+ HAProxy in front. Pacemaker is the exception.**

Reasons, not tastes:
- Patroni **understands PostgreSQL**: replication roles, promotion, *rewind*, lag. Pacemaker is
  a generic resource manager and everything it knows about Postgres comes from an agent.
- Patroni explicitly covers the ugly case: **it demotes the primary when it is isolated from the
  majority**, and `maximum_lag_on_failover` prevents promoting a replica that lags too far behind — which is
  exactly the decision that ruins a badly executed failover.

**Pacemaker is still the answer when**:
- the database's HA is **through shared storage**, not through replication;
- PostgreSQL is **one more resource** inside a cluster that already manages other services and
  OS dependencies;
- there is a vendor-supported stack built around Pacemaker (typical with SAP), and
  stepping outside it leaves you without support.

**Patroni traps to note in the design**:
- **The DCS is the new quorum.** A single-node etcd, or —the classic— running on the same
  machines as the database, turns a primary failure into a total outage. **A distributed, quorate
  etcd in different failure domains**, or there is no HA.
- With **only two PostgreSQL nodes** quorum becomes awkward again; consider a third
  node (even a witness) before accepting the design.
- Client routing (HAProxy against Patroni's REST API) is **part of the design**, not a
  detail: without it, the failover happens and nobody notices.

**The engine, its replication, its tuning and its PITR belong to `data-platform-standards`.** Here only
**which cluster mechanism is used and why** is set.

### 5.3 Virtual IP

- `ocf:heartbeat:IPaddr2` is the most common resource and the easiest to break: **the virtual IP is
  colocated and ordered with the service that uses it** (group or colocation+order), or you will end up with the
  IP on one node and the service on another.
- Check that the gratuitous ARP arrives and that the switches update their table: a failover
  that is technically correct with the network unaware of it is still an outage.
- If **all** you need is to move an IP, **do not build Pacemaker**: `keepalived` (§5.5).

### 5.4 NFS / Samba in active-passive

- Pattern: shared storage + `Filesystem` + virtual IP + the service, all in a
  **group**, with strict ordering. Only one node mounts.
- **What breaks people**: the **lock state**. An NFS failover without migrating the lock
  state leaves clients hanging or, worse, writing over locks that are no longer valid. The
  state directory goes on the shared storage, and **it is tested with real clients
  writing during the failover**, not with a `showmount`.
- With Samba and CTDB in play: check the package's lifecycle in your distro before
  designing (on RHEL 10, `ctdb` is in the discontinued batch of the Resilient Storage Add-On).

### 5.5 VRRP with `keepalived` (the lightweight option, and often the right one)

- For **HAProxy/nginx or another stateless frontend** with a floating IP, `keepalived` (2.4.x) does
  the job with no CIB, no agents and no fencing.
- **Its limits, stated plainly**: VRRP **has no quorum and no fencing**. Faced with a partition,
  both nodes can claim the IP (two MACs announcing the same address). It is acceptable
  precisely because **in front of stateless services a split-brain corrupts nothing**:
  it duplicates traffic, not data.
- **Hard rule**: `keepalived` **never** in front of a stateful resource that cannot tolerate double
  writing. There you need quorum and fencing, that is, Pacemaker (or the engine's own
  mechanism, §5.2).

## 6. Shared and replicated storage

**The rule that governs this whole section**: **a non-cluster filesystem, mounted on two
nodes at once, destroys the data.** Not "may cause problems": it destroys it, and often in
silence, because each node has its own cache and its own journal. XFS, ext4, btrfs and ZFS
**are not cluster filesystems**. The only mechanism that prevents that double mount in the real
world is fencing (§4.2), and hence this document's thesis is what it is.

- **Active/passive with XFS over shared storage** is the default pattern and the one to
  prefer: a single mount, a `Filesystem` resource managed by the cluster, tested fencing.
  Simple and sufficient in most cases.
- **Active/active with GFS2 or OCFS2** requires a distributed lock manager (`dlm`) and **impeccable
  fencing**: without it, `dlm` cannot recover and the cluster hangs or corrupts. Besides,
  **their future is compromised in both big families** (§2): GFS2 out of RHEL 10,
  OCFS2 out of SLE HA 16. **A new design on a cluster filesystem: justify the
  lifecycle in writing, and plan the exit.**
- **DRBD** when there is no shared array and you want block replication between nodes:
  - Replication modes: **A** (asynchronous, RPO > 0), **B** (semi-synchronous) and **C** (synchronous,
    RPO 0 and the one used in real HA). **Choose C unless the link's latency makes it
    impossible** — and if it does, admit your RPO is not zero and note it in `bcdr-standards`.
  - **Dual-primary is the classic trap.** It only makes sense for the short, controlled case
    (live VM migration) and **requires a cluster filesystem on top**. Historical LINBIT
    guidance: in DRBD 9 there is "two-primary", not "multi-primary"; appearing to work is not
    working. **Permanent dual-primary for a normal filesystem = guaranteed corruption.**
  - **Real operational debt**: the module is **out-of-tree** (DKMS) and lags behind the kernel. Every
    kernel update is a risk of booting with no `/dev/drbdX`. Plan the patching
    accounting for that. The effort to upstream DRBD 9.3 into mainline is under way but **has not
    landed yet**; until then, DKMS.
  - **Do not mix `drbd-utils` 9.x with the mainline kernel's 8.4 module**: the configuration
    syntax does not match.
- **DRBD is not a backup.** It replicates deletion and corruption at link speed.

## 7. Operation, gates and prohibitions

### 7.1 Operation

- **Maintenance mode BEFORE touching anything.** `pcs property set maintenance-mode=true` (or
  `pcs node standby` / `crm node standby` for one node) before patching, restarting a service,
  testing something or looking with too much curiosity. **The most common cause of a cluster incident
  is an administrator operating the service by hand while the cluster watches.**
- **A cluster-managed resource is not touched with `systemctl`.** It is already forbidden in
  `linux-administration-standards`; it is confirmed here: `systemctl restart` on a managed
  resource makes the cluster see it as a failure and, depending on the configuration, a fencing.
- **Leaving maintenance is part of the procedure**, and you verify that the cluster sees the
  real state (`crm_mon -1`, no pending failures, a clean `pcs status`). A cluster that has spent
  weeks in `maintenance-mode` **is not providing HA** and nobody has noticed.
- **Rolling upgrades**, node by node, with the cluster running:
  - Pacemaker supports rolling upgrade **from 2.0.0 onwards**; from versions earlier than
    2.0.0 it is **not supported** — you have to go through a 2.x release first.
  - A node with Pacemaker 3.0+ **does not connect to Pacemaker Remote nodes of 1.1.14 or earlier**,
    and Pacemaker 1 does not talk to Remote/bundles of 3.0+. Take inventory before starting.
  - Pacemaker 3.0 **validates the CIB strictly**: `validate-with` is mandatory, case-sensitive, and
    does not accept old schemas (`pacemaker-1.1`, `pacemaker-next`, etc.). **A CIB
    that was working may fail to load after the upgrade.** Test it with `crm_verify`
    against the new schema before touching the first node.
- **Monitoring of the cluster FROM OUTSIDE the cluster.** A cluster that watches itself
  reports perfectly right up until the moment it can no longer report. The "cluster without
  quorum" or "node fenced" alert has to come out of a system that is not in the cluster
  (`observability-standards`). What to watch as a minimum:
  - quorum present and the expected number of nodes;
  - **`stonith-enabled` is `true`** (alert if somebody disables it — it happens);
  - resources stopped, failed or on an unexpected node;
  - **fencing failures** (a fencing that fails is a high-severity incident, even if the
    service stays up);
  - `maintenance-mode` active for more than X hours;
  - Corosync retransmissions and token loss (an early symptom of the network that will cause the
    next spurious fencing);
  - the state of the fencing devices: **the BMC/PDU is tested periodically, not when it is
    needed**;
  - the health of SBD and the watchdog.
- **The logs that matter**: `pacemaker.log` / the `pacemaker` and `corosync` journals, and above all
  **`crm_mon --show-detail` and the resource's failure history**. In an incident, the question
  is not "what happened" but **"why did the cluster decide this"**, and that answer is in the
  PE transition (`crm_simulate` over the transition file). Retention of those logs
  sufficient for a postmortem (`incident-management-standards`).
- **Fencing credentials**: they are "switch this server off" credentials. They go in the secrets
  manager (`secrets-management-standards`), with rotation, and their management network segmented.

### 7.2 Exercises (recurring gates)

1. **Before production**: the test of §4.3 — dirty power-off **and** network partition — with a
   report: what was switched off, how long the failover took, data integrity, what failed.
2. **A scheduled failover at least every six months**, in an agreed window, on the production
   cluster. A failover only tested on installation day is not tested: the kernel, the agents,
   the BMC firmware and the network rules have changed since then.
3. **Tested failback.** The way back is one more failover and is usually less rehearsed than the
   way out. It is exercised explicitly, and it is decided whether it is automatic (with low
   `stickiness`) or manual (recommended by default).
4. **A report per exercise**: date, scenario, measured failover time, deviation from
   the objective, findings and actions with an owner. Without a report, the exercise does not count.
5. **Testing the fencing devices separately** (`pcs stonith fence <node>` in a window):
   it confirms that the BMC answers, that the credentials are still valid and that the management
   network reaches it. It is the component that degrades most silently.
6. **`crm_simulate` in CI** over the versioned CIB on any constraint change.

### 7.3 FORBIDDEN

- ❌ **`stonith-enabled=false`** in anything other than a disposable lab
  documented as such. It is this document's number one prohibition.
- ❌ A cluster in production **without the dirty power-off test** of §4.3.
- ❌ **A two-node cluster with no qdevice/qnetd** (or without fencing that demonstrably resolves the
  partition).
- ❌ An arbiter (qnetd) in the same failure domain as a cluster node.
- ❌ **`no-quorum-policy=ignore`** copied without understanding what it enables.
- ❌ **A software watchdog (`softdog`) as fencing in production**: it is unreliable by design.
- ❌ Mounting a **non-cluster** filesystem (XFS, ext4, btrfs, ZFS) on two nodes at once.
- ❌ **Permanent DRBD dual-primary** under a filesystem that is not a cluster one.
- ❌ Confusing **replication with backup**, or **HA with DR** (§1.2).
- ❌ Operating a managed resource with `systemctl`, or touching the service without `maintenance-mode`.
- ❌ Editing `cib.xml` by hand on disk; configuring the cluster only through an interactive session without
  leaving the CIB versioned in the repository.
- ❌ Constraints with intermediate `score`s "to see what happens"; constraints without `crm_simulate`.
- ❌ A resource with no `monitor` operation, or with a `timeout` copied from the example.
- ❌ `resource-stickiness=0` (immediate automatic failback = a second free outage).
- ❌ **Exposing the `pcsd` daemon / its web interface to an untrusted network.** The bulk of the recent
  `pcs` CVEs comes from its **dependencies packaged in `pcsd`** (tornado, rack, lodash:
  RHSA-2026:2452 / 2462 / 2469 / 2818 / 2819, Feb 2026), not from the cluster logic. Management
  network, and patching at the pace of the distro's errata.
- ❌ Corosync over a network shared with backup or massive replication.
- ❌ **Pacemaker managing a host's containers** to "give them HA": see
  `podman-systemd-containers-standards`. The answer is an orchestrator, a load balancer with the
  state outside, or downtime accepted in writing.
- ❌ `keepalived`/VRRP in front of a stateful resource that cannot tolerate double writing.
- ❌ Building a cluster because "we want it not to go down", with no SLO, no failure domains
  drawn and nobody on call who knows how to operate it.
- ❌ Compiling Pacemaker/Corosync by hand on a system with vendor support.
- ❌ A new design on GFS2/OCFS2 without justifying its lifecycle in writing (§2).

## 8. Mandatory web verification

Before pinning anything in a real project:

1. **The versions packaged by your distribution** of `pacemaker`, `corosync`, `pcs`/`crmsh`,
   `resource-agents`, `fence-agents` and `sbd` — **not upstream's**. In clusters, vendor
   support rules.
2. **The cluster filesystem's lifecycle** in your distro: GFS2 **discontinued from
   RHEL 10 onwards** (Resilient Storage Add-On; the `gfs2` and `dlm` modules out of the kernel), OCFS2
   deprecated in SLE HA 15 SP7 and **out of SLE HA 16**. Confirm the exact end-of-support dates
   for RHEL 9 before committing to a migration.
3. **Pacemaker 3.0 migration notes**: strict CIB validation, `validate-with`,
   withdrawn schemas, Pacemaker Remote compatibility. Read ClusterLabs's 3.0 changes page
   **before** the first rolling upgrade.
4. **The status of the specific fencing agent for your hardware/hypervisor/cloud** and its parameters
   (`pcmk_delay_base`, `pcmk_host_map`, `pcmk_reboot_action`): they change between versions of
   `fence-agents`.
5. **Security errata for `pcs`/`pcsd`** in your stream (the recent ones come from packaged
   dependencies) and CVEs for `corosync`, `pacemaker` and `sbd`.
6. **Patroni**: latest version and its compatibility matrix with the PostgreSQL version and with
   the chosen DCS; and whether it is still the default recommendation over Pacemaker.
7. **DRBD**: whether the 9.3 module has landed in the mainline kernel yet (LINBIT's estimate:
   possibly Linux 7.2, Sep/Oct 2026) — it completely changes the maintenance equation
   compared with DKMS.
8. **Corosync latency requirements and tuning** (`token`, `consensus`) for your topology, in
   particular if there are links between rooms.

**Declared gaps — do NOT fill from memory, verify before using:**
- **Date and content of the last `sbd` release**: the last verified tag is **1.5.2
  (2023-01-09)** with repository activity in January 2026, but **it has not been confirmed whether
  a later release exists nor which version RHEL 10 and SLE HA 16 package**. Check it before
  depending on a specific fix.
- **The exact release date of `keepalived` 2.4.3** (tag verified, date not obtained because of an
  API rate limit) and its maintenance status.
- **The date of `drbd-utils` 9.34.0** (tag verified, date not obtained). And **the exact relationship
  between DRBD 9.3.3 and the 10.0.0 alpha branch**: LINBIT's support plan has not been verified.
- **The reason for the Patroni patch batch of 2026-07-07** (4.1.4, 4.0.10 and 3.3.11 on the same day,
  the typical pattern of a security fix): **not verified**. Consult the advisory before
  pinning a minimum version.
- **The status and support of `pg_auto_failover`** as an alternative to Patroni in two-node
  scenarios: mentioned in the sources but **not verified as to current maintenance**.
- **Supported alternatives to GFS2 on RHEL 10** for active/active over shared block:
  **not verified** beyond the observation that the add-on disappears. Confirm with Red
  Hat before designing.
- **The Corosync tuning parameters recommended today** (`token`, `token_retransmits_before_loss_const`,
  `consensus`): **not verified in this revision**. Do not copy values from blogs.
- **The exact compatibility of `crmsh` 5.1 with Pacemaker 3.0.x** (5.1.0 was at rc2 as of Jun 2026):
  not verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
