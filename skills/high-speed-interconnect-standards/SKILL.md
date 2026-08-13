---
name: high-speed-interconnect-standards
description: RDMA interconnects for HPC, AI and storage — InfiniBand, RoCE v2 and iWARP as a separate network from the data network. Use when designing or debugging an InfiniBand fabric with opensm or a vendor subnet manager, LIDs, GUIDs, P_Key partitions, SHARP in-network reduction, ibstat, ibstatus, ibnetdiscover, ibdiagnet, perfquery, ibping, iblinkinfo and port error counters, RoCE v2 on Ethernet with rdma-core, ibv_devinfo, rdma link, mlx5 or irdma drivers, RoCE priority and DSCP mapping and end-to-end validation, out-of-sequence and CNP counters, iWARP (RFC 5040, RFC 5044), Ultra Ethernet UEC 1.0 as an emerging alternative, choosing between InfiniBand and Ethernet for a GPU or HPC cluster, fat-tree and dragonfly topologies for compute clusters, libibverbs and verbs programming, UCX, MPI over RDMA (Open MPI, MPICH, UCX transports), NCCL or RCCL collectives and their network backend, GPUDirect RDMA, NVMe over Fabrics with RoCE, TCP or Fibre Channel, nvme connect and nvme discover, SMB Direct, NFS over RDMA (RFC 8166), deciding that NVMe/TCP is good enough and no RDMA is needed, or diagnosing an RDMA fabric where the symptom is collapsed throughput rather than packet loss.
---

# High-speed interconnect standards — RDMA, InfiniBand and RoCE

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **designing, deploying, validating and diagnosing the high-performance compute and
storage network**: RDMA as a model, the choice of transport (InfiniBand, RoCE v2, iWARP), subnet
management and partitions, compute topologies and their oversubscription, the software stack (verbs,
UCX, MPI, GPU collectives), storage over RDMA, and **the criterion for not using RDMA at all**.

Triggers: `ibstat`, `ibnetdiscover`, `ibdiagnet`, `perfquery`, `iblinkinfo`, `opensm`, "subnet
manager", "LID", "P_Key", "SHARP", `rdma-core`, `ibv_devinfo`, `rdma link`, `mlx5`, `irdma`, "RoCE
v2", "iWARP", "GPUDirect", "verbs", "UCX", "NCCL"/"RCCL", "MPI", "fat-tree", "dragonfly", "NVMe-oF",
`nvme connect`, "SMB Direct", "NFS over RDMA", "Ultra Ethernet"/"UEC".

**Not applicable**: the catalogue already splits this up: `networking-standards` is the **trunk**
(VLANs, addressing, MTU, management plane) and **already delegates the depth**, while
`datacenter-fabric-standards` **owns the Ethernet that carries RoCE** — Clos, VXLAN/EVPN and **all
the mechanics of the lossless network: PFC, ETS, DCBX, ECN and DCQCN, with their thresholds and
their monitoring** (here only **what the interconnect requires and how it is validated end to
end**), `routing-switching-standards` owns the campus, BGP policy and control plane security, and
`network-automation-standards` configuration as code. Outwards: **the GPU and its compute belong to
`gpu-computing-standards`**, **the job scheduler and cluster sizing, to `hpc-standards`**, the
filesystem and local block to `linux-storage-standards`, objects to `object-storage-standards`, the
measurement methodology and the load model to `performance-engineering-standards`, metrics and
alerts to `observability-standards`, the SLO to `sre-practice-standards`, the reactive method to
`network-troubleshooting-standards`, filtering to `firewall-policy-standards`, identity to
`identity-access-management-standards`, the mesh to `microservices-architecture-standards`, caching
to `caching-cdn-standards`, containers to `kubernetes-standards`, and the umbrella to
`onprem-standards` (with `datacenter-facilities-standards`, owner of the physical plant).
Among the three sisters of this batch: `wireless-standards` is the **access network**,
`load-balancing-standards` the **service network** and this one the **compute network**; **the
domain's error is applying the same criteria to all three**.

**Governing principle**: **the compute and storage network is not the data network.** A different
failure model (the symptom is not loss, it is performance collapse), a different oversubscription
criterion, a different management plane and different staff. Treating it as "just another VLAN" is
the expensive error in the domain.

## 2. Default decisions

> Verify the state of the ecosystems, current rates, versions and **the raw licence** before fixing
> anything (§8).

| Decision | Default | Justifiable alternative / vetoed |
|---|---|---|
| RDMA or not? | **No, by default.** It is justified by a measured requirement TCP cannot meet | ❌ RDMA "because it is faster" with no target number and no team able to operate it |
| Compute transport | **InfiniBand** when the cluster is for training or classic HPC and there is budget and staff | **Ethernet with RoCE v2** when the open ecosystem, multi-use or cost rules; **iWARP**, de facto in retreat |
| Storage transport | **NVMe/TCP** unless there is a measured requirement | NVMe-oF/RoCE with a validated lossless network; FC-NVMe if a fibre SAN already exists |
| Lossless network for RoCE | **Mandatory and validated end to end**, in **a single class**, with ECN first and PFC as a last resort (mechanics in `datacenter-fabric-standards`) | ❌ Deploying RoCE with no congestion control validated end to end |
| Compute oversubscription | **1:1 (non-blocking)** on the training/HPC network | 2:1 only with a measured traffic profile; ❌ importing the 3:1-4:1 of a general-purpose compute fabric |
| Topology | **Non-blocking fat-tree (Clos)** as the default | **Dragonfly** at large scale for cabling cost, assuming adaptive routing and more complexity |
| Subnet management (IB) | **One primary SM and at least one standby**, with versioned configuration | ❌ A single SM; ❌ two "master" SMs competing through accidental discovery |
| Isolation (IB) | **Partitions (P_Key)** declared per tenant/service | ❌ Everything in the default partition and calling it segmentation |
| User stack | **rdma-core / libibverbs** as the base and **UCX** as the transport for MPI and collectives; **NCCL/RCCL** with GPUDirect RDMA verified | ❌ Reimplementing a transport on top of verbs; ❌ assuming GPUDirect is active because the card supports it |
| Management plane | **Out of band and separate from the fabric**, like any network device | ❌ Managing the fabric switches through the fabric itself |

## 3. Design criteria

**RDMA: what it is and what it demands**
- **Direct remote memory access**: the card reads and writes the other end's memory **with no
  intermediate copies and without going through the kernel** on the data path. Hence the three real
  gains: low and **predictable** latency, zero copy and a freed CPU.
- **What it demands of the application**: registering and pinning memory (a non-trivial cost and
  `memlock` limits), managing queues and completions, and **assuming a different failure model** —
  the reliable connection aborts the *queue pair* on error and recovery belongs to the application.
  **An application that does not speak verbs gains nothing from installing RDMA cards**: it is an
  architecture decision, not a network tweak, and if the software is not ported the project is a
  development project.

**InfiniBand versus RoCE v2 versus iWARP — an honest criterion**
- **InfiniBand**: a coherent end-to-end stack, credit-based flow control **in the protocol itself**,
  centralised management by the SM and in-network aggregation. Lower technical risk in training and
  HPC. **The price**: a very concentrated ecosystem — the specification belongs to the IBTA, but the
  adapter and switch market has been dominated by one manufacturer since NVIDIA's purchase of
  Mellanox —, high cost and staff you have to train or hire.
- **RoCE v2**: RDMA over UDP/IP, therefore **routable** and over anybody's switches; an open
  ecosystem and staff you already have. **The price**: **the network becomes your responsibility**,
  and that is where it breaks (§ next).
- **iWARP**: RDMA over TCP (**RFC 5040** and **RFC 5044**), with no lossless network requirement. It
  sounds ideal and **in practice it has lost the market**: scarce card support and declining
  adoption. Do not choose it for something new without verifying that hardware you want to buy
  exists.
- **Ultra Ethernet (UEC)** is the move to watch: specification **1.0 published in Jun 2025**, with a
  modern RDMA transport, multi-path spraying and reordering on the card, precisely to fix what RoCE
  v2 does badly. **It is not yet the safe default**: verify real hardware first.
- **Choice rule**: do you have a team capable of operating and **diagnosing** a lossless Ethernet?
  If not, either InfiniBand or NVMe/TCP and no RDMA at all. The worst combination is **RoCE operated
  by people who do not know they are operating it**.

**RoCE needs a lossless network: what the interconnect demands**
- **The mechanics belong to `datacenter-fabric-standards`** (PFC 802.1Qbb, ETS 802.1Qaz, DCBX, ECN
  and DCQCN). Here only what the interconnect imposes:
  1. **A single lossless class**, with RoCE's priority mapped **identically on every hop and on both
     cards**: a mismatch on a single hop voids the guarantee.
  2. **Coherence between DSCP and L2 priority** (RoCE v2 is UDP/IP: the marking that survives
     routing is DSCP), and **coherent MTU and jumbo frames** along the whole path.
  3. **Congestion control configured on the card too** (DCQCN or equivalent), not only in the
     network: it is **end to end**, and half a configuration is none.
- **Why a badly configured lossless network makes things worse**: PFC does not drop, it **pauses**,
  and the pause **pushes congestion backwards** until it stops unrelated traffic (*congestion
  spreading*); with buffer dependency cycles you get **PFC deadlock**, from which the network **does
  not recover on its own** and which looks like part of the cluster stopped with no obvious errors.
  You have swapped "losing packets" for "stopping everybody": if end-to-end congestion control does
  not work, you have made the failure worse, not removed it.
- **End-to-end validation, mandatory**: a real load between distant peers watching **PFC pause
  counters, ECN marks and CNPs on cards and switches**. If nobody looks at the counters, you do not
  know whether you are pausing. It is a gate (§4).

**Management: the subnet manager and why Ethernet has no equivalent**
- In InfiniBand, the **Subnet Manager** discovers the topology, **assigns the LIDs**, programs each
  switch's **forwarding tables** and maintains the state. **Without an SM the fabric does not get
  past "link up": it forwards nothing.** Consequences: **a primary and a standby SM**, versioned
  configuration, and awareness that somebody else's SM on the subnet can reprogram it.
  **Rerouting is an observable operation** that is worth provoking in a lab. **Partitions (P_Key)**
  are the native isolation: per tenant or service, not everything in the default partition.
- **In Ethernet there is none of this**: there is no central entity programming the forwarding. Its
  functional equivalent is **distributed protocols** (BGP/EVPN, ECMP) plus your automation — that
  is, **what in InfiniBand is a component, in Ethernet is a project**. That is the real hidden cost
  of choosing RoCE.

**Topologies and oversubscription in compute**
- **A non-blocking fat-tree** is the default: equal paths between any pair and predictable latency.
  **Dragonfly** reduces cabling and cost at large scale in exchange for unequal paths and dependence
  on **adaptive routing**; only with a team that knows how to operate it.
- **Oversubscription is decided with different criteria from a data centre fabric**: there the
  traffic is many independent flows and 3:1 is reasonable; here a synchronous collective makes
  **the whole job advance at the pace of the slowest link**, so it does not degrade a bit: it
  degrades the entire job. Default **1:1**; anything else is a written and measured decision. And
  the **collectives' *incast*** (many senders to one receiver) breaks buffers: it is not fixed with
  more bandwidth, but with congestion control and in-network aggregation.

**Software**
- **verbs / rdma-core** is the base; almost nobody should be programming there directly. **UCX** is
  the transport layer used by MPI and other libraries: if something goes wrong in MPI, the diagnosis
  is usually in UCX — the selected transport, the chosen device, the registered memory — not in the
  switch. **MPI** (Open MPI, MPICH) and the scheduler belong to `hpc-standards`.
- **GPU collectives (NCCL/RCCL)**: distributed training depends on them choosing the right transport
  and on **GPUDirect RDMA** actually being active (card and GPU in a reasonable PCIe/NUMA domain).
  **Verify it, do not assume it**: the usual silent degradation is falling back to a path that
  copies via the CPU. The GPU itself belongs to `gpu-computing-standards`.

**Storage over RDMA — the most useful section, because most people do not need RDMA**
- **NVMe over Fabrics** has three live transports: **RoCE** (lowest latency, requires a lossless
  network), **TCP** (any NIC, any switch, any routed topology) and **Fibre Channel** (natural if you
  already have a SAN).
- **NVMe/TCP is enough for the vast majority** and avoids all of the above: no lossless network, no
  PFC, no priority mapping, no specialised staff. The cost is latency and CPU, and a good part of it
  is recovered with offload on the card.
- **Criterion**: start at NVMe/TCP; move to NVMe-oF/RoCE **only** with a **measured** latency
  requirement TCP does not meet **and** a team able to maintain the lossless Ethernet. If you
  already have InfiniBand for the compute, NVMe-oF over it is natural. **SMB Direct** and **NFS over
  RDMA** (RPC over RDMA, **RFC 8166**) drag in the same requirement: without the network underneath
  there are incidents, not gains.

## 4. Quality gates

- **Validate the network before the application**: latency and throughput with card-level tools
  **between all the relevant pairs**, not between two neighbours. A fabric tested in only one rack
  is not tested.
- **RoCE gate**: load with simultaneous observation of **PFC, ECN/CNP, reorderings and retries** on
  card and switch. **Zero sustained pauses** or the design does not pass. And **coherence of the
  lossless class on every hop** by an automatic diff: a switch differing from its peers is a
  finding.
- **Real failure test**: a link drop, a switch drop and (in IB) **the primary SM going down**,
  measuring reconfiguration and impact on a running job. The return path too.
- **Real collective test** at the target scale, not just point to point: that is where
  oversubscription and incast show up. With **GPUDirect RDMA verified active** and the path chosen
  by the collectives library checked, and with **homogeneous firmware, driver and NOS** across the
  whole fleet (mixed versions in RDMA produce failures that look like network ones).

## 5. Security

- **RDMA neither authenticates nor encrypts by default** and the data path **bypasses the kernel**:
  host controls (local firewall, inspection) **do not see that traffic**, and whoever can inject
  into the fabric can read and write registered remote memory. Consequence: **the fabric is a
  physical and bounded trust domain**, protected by **isolation** (P_Key in IB, VLAN/VRF and
  filtering at the edge of the RoCE Ethernet), not by rules on the data path (the zone policy
  belongs to `firewall-policy-standards`).
- **Do not route RoCE outside its domain** or carry it over links shared with general traffic
  without deciding to: it breaks the lossless guarantee and widens the surface.
- **An OOB management plane** for the fabric switches and for the SM, with AAA and no factory
  credentials: a compromised SM reprograms the forwarding of the whole cluster. If the data requires
  confidentiality and the facility is not trusted, **link or application** encryption
  (`cryptography-pki-standards`), not assuming that "it goes over another network".

## 6. Performance and diagnosis

- **Here the symptom is not packet loss: it is performance collapse.** The job takes three times as
  long, the collective slows down, and `ping` responds perfectly. Looking for "lost packets" is the
  classic dead end of the domain.
- **Counters always watched**, on card and switch: symbol and link errors, dropped and renegotiated
  links, bit error rate and optics status, **PFC pause frames**, **ECN-marked packets and CNPs**,
  out-of-sequence packets, retries and `retry exceeded`, and completions with errors. The **counter
  that rises where it should not** is the diagnosis, not the capture.
- **A single degraded link poisons the cluster**: with collectives, a port with symbol errors drops
  overall performance without ever going down; the periodic sweep of counters and link quality is
  routine, not a reaction to an incident.
- **Placement matters**: NUMA and PCIe affinity between card, GPU and process changes the result
  more than any switch tuning. And it is measured with the real workload — the target collective —
  not with point-to-point synthetics (methodology in `performance-engineering-standards`).

## 7. Long-term sustainability and prohibitions

- **Cadence**: firmware, driver and NOS quarterly and on an exploitable CVE, **as a tested set**
  (card + driver + NOS + library), not piece by piece. In RDMA, unsupported combinations give odd
  performance, not a clear error.
- **Generations**: the fabric is replaced by complete generations and the rates double every few
  years, changing optics, connector and power budget; mixing them works by negotiating down, so
  **plan for it, do not discover it**. Retired partitions, nodes and classes disappear from
  configuration and documentation.

**FORBIDDEN**
- ❌ Deploying **RoCE with no end-to-end congestion control configured and validated** (card **and**
  network), with a load test and observed counters. Without that, it does not go into production.
- ❌ Choosing RDMA with no **measured** performance requirement TCP fails to meet, or RoCE with no
  team able to operate and diagnose a lossless Ethernet.
- ❌ Enabling PFC on more than one class, or with a different priority/DSCP mapping on some hop.
- ❌ Operating without monitoring pause, ECN/CNP and link error counters.
- ❌ InfiniBand with a single subnet manager, or with its configuration outside version control.
- ❌ Leaving the whole InfiniBand fabric in the default partition and calling it segmentation.
- ❌ Treating the fabric as an extensible trust zone, or routing RoCE outside its domain.
- ❌ Managing the fabric's switches through the fabric itself.
- ❌ Importing into the compute network the oversubscription of a general-purpose compute fabric.
- ❌ Assuming GPUDirect RDMA is active without having verified it.
- ❌ Heterogeneous firmware, driver and NOS across the fabric's fleet.
- ❌ Diagnosing by looking for packet loss when the symptom is performance collapse.
- ❌ Putting NVMe-oF/RoCE where NVMe/TCP does the job, or designing on Ultra Ethernet without
  verifying real hardware availability.

## 8. Mandatory web verification

**Methodology**: the RFCs, **one by one** against `rfc-editor.org`'s JSON; the state of the
ecosystems, against primary sources (IBTA, UEC, NVM Express).

**RFCs verified Aug 2026**: **iWARP — RDMAP = RFC 5040** (Oct 2007, Proposed Standard, updated by
7146) and **MPA = RFC 5044** (Oct 2007, updated by 6581 and 7146); **NFS/RPC over RDMA v1 =
RFC 8166** (Jun 2017, **obsoletes RFC 5666** — citing 5666 today is a factual error). The lossless
network and its IEEE/ECN references are verified in `datacenter-fabric-standards`: **do not
duplicate them or recall them from here**.

**Status verified Aug 2026**: **IBTA** published the initial **XDR** specifications in Oct 2023
(Vol. 1 rel. 1.7), with **XDR = 800 Gb/s per port** over 200 Gb/s per lane, and a roadmap towards
**GDR (1600G)** and **LDR (3200G)**; the current ladder is EDR 100G → HDR 200G → NDR 400G →
XDR 800G. **The Ultra Ethernet Consortium published specification 1.0 on 11 Jun 2025**, with its own
RDMA transport, multi-path spraying and reordering at the endpoint. **NVM Express published the 2.4
set on 4 Aug 2026**, with **NVMe over RDMA Transport 1.3** and **NVMe over TCP Transport 1.3**.
**iWARP is in adoption decline** according to the sources consulted.

**Declared discrepancy**: on InfiniBand's market position versus Ethernet the sources do not agree —
some hold that the specialised Ethernet of InfiniBand's own manufacturer already ships more volume
than its InfiniBand, and others present InfiniBand as the de facto standard of training. **It is
market analysis, not a technical datum**: do not use it as a design argument.

**Declared gaps — do NOT fill from memory**:
1. **Effective rates and latencies per generation** (beyond the nominal per port) and **real
   availability of XDR/GDR hardware**: not verified.
2. **iWARP support by manufacturer and model** and **availability and interoperability of UEC 1.0
   compliant hardware**: **not verified**, and they are what decides whether each is an option
   today.
3. **Versions, maintenance and raw licence** of `rdma-core`, **UCX** (only its copyright header was
   read, not the terms), Open MPI, MPICH, NCCL/RCCL and `opensm`: **not verified**.
4. **DCQCN parameters, ECN thresholds and PFC *headroom***, and **oversubscription numbers per
   workload type**: vendor and engineering criteria, not measurements (in
   `datacenter-fabric-standards` they are also recorded as not verified).
5. **NVMe/TCP versus NVMe/RoCE latency figures**: the sources give ranges, not reproducible
   measurements. Measure on your hardware before justifying RDMA with them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
