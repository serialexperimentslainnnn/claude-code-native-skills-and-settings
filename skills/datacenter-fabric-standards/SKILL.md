---
name: datacenter-fabric-standards
description: The data centre network as a routed Clos fabric, not one big switched network. Use when designing or reviewing a leaf-spine (Clos) topology, oversubscription ratio and spine count, eBGP-per-leaf with private ASNs or IS-IS as the underlay, BGP unnumbered with IPv6 link-local next hops (RFC 8950), RFC 7938 large-scale DC routing, VXLAN encapsulation (RFC 7348) or Geneve (RFC 8926), EVPN control plane (RFC 7432, RFC 8365) replacing flood-and-learn, EVPN route types 1-5, IMET, ESI and RFC 9136 type-5 IP prefix routes, symmetric versus asymmetric IRB (RFC 9135), anycast distributed gateway, L3VNI/L2VNI and VRF multi-tenancy, EVPN multihoming with ESI-LAG and RFC 9746 split-horizon versus proprietary MLAG/vPC, jumbo frames and encapsulation MTU overhead, ARP/ND suppression and proxy-ARP (RFC 9161), BUM traffic handling (RFC 9572), configuring lossless Ethernet on the switch with PFC (802.1Qbb), ETS (802.1Qaz), DCBX, ECN (RFC 3168) and DCQCN, DCI and the danger of stretching layer 2, or deciding that two switches and plain routing are enough and EVPN is not needed.
---

# Data centre fabric standards — Clos, EVPN and when to do none of this

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **designing, sizing and operating a data centre's internal network**: leaf-spine Clos
topology, oversubscription and scaling, the fabric protocol (*underlay*), the
VXLAN/EVPN overlay, integrated routing and the distributed gateway, VRF multi-tenancy, encapsulation
MTU, server multihoming, lossless networking for storage and RDMA, data centre
interconnect, and **the criteria for not building an EVPN fabric**.

Triggers: "leaf-spine", "Clos", "spine", "leaf", "border leaf", "superspine", "oversubscription",
`vxlan`/`vni`/`vtep`/`nve`, `evpn`, `l2vpn evpn`, `route-type 2`/`type-5`, `esi`, `anycast-gateway`,
`irb`, `l3vni`/`l2vni`, `vrf`, "BGP unnumbered", "underlay/overlay", `mtu 9216`/"jumbo", `pfc`,
`802.1Qbb`, `dcbx`, `ets`, `ecn`, `wred`, `dcqcn`, "lossless", "RoCE", "DCI", "VXLAN stretch",
"MLAG", "vPC", "ESI-LAG".

**Not applicable** — each skill **decides** a different thing:
`networking-standards` (**the backbone, the parent**: it decides **addressing and IPAM, which VLAN exists,
BGP/OSPF fundamentals, design MTU/MSS, proxies and host overlays, NetBox as the SoT**; none of that is
reopened here, here we decide **the fabric's topology and control plane**);
`routing-switching-standards` (**it decides campus and edge**: STP, campus MLAG, VRRP, the site IGP,
**BGP policy towards the outside**, RPKI, QoS, CoPP and the management plane — here only BGP as the internal
fabric protocol, not Internet policy); `network-troubleshooting-standards` (**it decides the reactive
method** when the fabric is already failing); `network-automation-standards` (**it decides how this
configuration is generated, tested and applied**, and its telemetry); `high-speed-interconnect-standards`
(**already written**: **InfiniBand and RoCE as a compute interconnect are theirs**; here only the
Ethernet that carries them); `datacenter-facilities-standards` (**the physical
plant is theirs** — power, cooling, racks, cabling); `kubernetes-standards` (**it decides what runs
on top**: CNI, Service, Ingress, NetworkPolicy, service mesh); `firewall-policy-standards`
(**it decides which flow is permitted between tenants and zones**); `finops-standards` (cost per port,
optics and transceivers). Also boundaries: `onprem-standards` (the umbrella), `iac-standards`,
`observability-standards`, `sre-practice-standards`, `secrets-management-standards`,
`linux-hardening-standards`, `vulnerability-management-standards`,
`identity-access-management-standards`, `offensive-security-standards` (**this skill is defensive**),
`vpn-standards`, `dns-standards`, `network-vendors-standards`, `telco-5g-standards` and
`wan-legacy-standards`.

**Governing principle**: **the modern data centre is designed as a routed fabric, not as one big
switched network.** Layer 2 is reduced to a minimum and carried encapsulated over routing; the
throughput scales horizontally; and **predictable latency is worth more than peak bandwidth**.

## 2. Default decisions

> Verify status, version and RFC on the web before committing to anything (§8). The RFCs in this table are
> verified one by one against the `rfc-editor.org` JSON API.

| Decision | Default | Justifiable alternative / vetoed |
|---|---|---|
| Topology | **A two-tier leaf-spine Clos**; three tiers only when the leaves exceed the spines' radix | ❌ Core-distribution-access with stretched VLANs in a new DC; ❌ a ring or a tree with STP |
| Connectivity | **Every leaf to every spine; no leaf to another leaf, no spine to another spine.** More throughput = one more spine | Leaf-leaf links: they break the uniform path and the predictability |
| Oversubscription | **Declare it explicitly** per rack role (1:1 or 2:1 on storage/AI, 3:1–4:1 on general compute) | ❌ Not calculating it and discovering it in production; ❌ the same ratio for every rack |
| Underlay | **eBGP, a private ASN per leaf**, spines with a common ASN, ECMP to all of them. **RFC 7938** (Informational) as the reference | **IS-IS** if a pure IGP is preferred and the team knows it well; OSPF is the worst of the three here |
| Underlay addressing | **BGP unnumbered**: an IPv6 link-local next hop over unnumbered links — **RFC 8950** (Nov-2020, **obsoletes RFC 5549**) | Numbering each `/31`: it works, but it is inventory that automates badly |
| Failure detection | **BFD** on every underlay session, with ECMP recalculating | Aggressive BGP timers: they punish the CPU and converge worse |
| Encapsulation | **VXLAN — RFC 7348** (Informational, Aug-2014) for universal hardware support | **Geneve — RFC 8926** (Proposed Standard) is technically superior but its ASIC support is uneven: **verify per platform** |
| Overlay control plane | **EVPN — RFC 7432** with **RFC 8365** (EVPN over NVO/VXLAN) | ❌ **Flood-and-learn with multicast VXLAN**: it learns by flooding, depends on multicast in the underlay and does not scale |
| IRB | **Symmetric — RFC 9135** (Oct-2021). The modern default: each VTEP only needs its local VLANs and transit goes over a common **L3VNI** | **Asymmetric** requires **every** VNI to exist on **every** VTEP: simpler to understand, does not scale |
| Gateway | **Distributed anycast**: the same IP and MAC on every leaf; the first hop never crosses the fabric | ❌ A centralised gateway: it turns a fabric into a hub-and-spoke topology and adds *tromboning* |
| Multi-tenancy | **A VRF per tenant mapped to an L3VNI**; IP prefixes with **RFC 9136** (type-5); leaks between VRFs only by written policy | ❌ A single routing space "because they're all ours" |
| MTU | **Jumbo across the whole fabric (≥ 9000 payload)**, uniform and verified end to end. **Non-negotiable** | ❌ MTU 1500 with VXLAN on top; ❌ a different MTU on a single link |
| Server multihoming | **EVPN multihoming (ESI-LAG)**: standard, no peer link, active-active, N leaves. Split-horizon updated by **RFC 9746** (Mar-2025) | **Proprietary MLAG/vPC** only if the hardware does not support EVPN-MH: it ties you to a vendor and adds shared state |
| DF election | An **explicit** *designated forwarder* algorithm — **RFC 8584** (Apr-2019) made the framework extensible | Leaving it at the default and discovering it through duplicated BUM traffic |
| Lossless networking | **Only where the protocol demands it** (RDMA/RoCE, some storage). **ECN (RFC 3168) first, PFC as a last resort**, in a single class | ❌ PFC enabled "just in case" across the whole fabric |
| DCI | **Routed (L3) interconnect by default** | An L2 stretch between DCs **only** with a written requirement, a bounded failure domain and a retirement date |

## 3. Design decisions

**EVPN: what it actually solves**
VXLAN without a control plane **floods and learns**, like a switch. EVPN replaces that with **BGP
advertising what each VTEP knows**, and with it the dependency on multicast in the
underlay, the flooding of unknown unicast and much of the ARP/ND on the wire all disappear.

- **Type 1 — Ethernet Auto-Discovery**: discovery by ESI; it underpins multihoming (fast convergence
  when a link drops, *aliasing* to balance towards a multihomed server).
- **Type 2 — MAC/IP Advertisement**: the host's MAC and, optionally, its IP. It is what makes
  **ARP/ND suppression** possible (proxy ARP/ND operational aspects in **RFC 9161**).
- **Type 3 — IMET**: it builds the replication tree for BUM traffic. Procedures updated by
  **RFC 9572** (May-2024).
- **Type 4 — Ethernet Segment**: it discovers who shares a segment and **elects the designated forwarder**
  that forwards BUM towards it (avoiding duplicates and loops).
- **Type 5 — IP Prefix (RFC 9136)**: IP prefixes with no MAC; external connectivity, summarisation, VRFs.
- **Reading rule**: an L2 reachability problem within a VNI → types 2 and 3; multihoming or duplicated
  traffic → types 1 and 4; connectivity between VRFs or towards the outside → type 5.

**MTU: the non-negotiable requirement**
- The encapsulation **adds a header** (VXLAN over UDP/IP adds tens of bytes; Geneve more, and
  **variable** by options). If the fabric does not carry the tenant's frame **plus** that header,
  it breaks.
- **What breaks if it is missing**: ping works, the TCP handshake works and the transfer hangs.
  Large packets with DF disappear and, without ICMP *fragmentation needed* / *packet too big* coming
  back, PMTUD dies silently. **The canonical symptom: "it connects but hangs on transfer"** — the
  demonstration belongs to `network-troubleshooting-standards`; **the fix belongs here and is a design one**.
- **Uniform means uniform**: a single link with a lower MTU makes the problem intermittent and
  dependent on the ECMP path. It is verified as a gate (§4), not by visual inspection.

**Server multihoming**
- **EVPN-MH (ESI-LAG)** is the default: standard, with no peer link between leaves, supporting more than two
  leaves, with no proprietary shared state. The **ESI**'s value and uniqueness, the
  **DF election** algorithm (RFC 8584) and the behaviour when a leaf loses its only uplink are decided
  explicitly.
- **MLAG/vPC** remains valid where the hardware dictates, but it **drags the campus's failure modes into
  the fabric** (*split brain*, keepalive, peer upgrades) which do not exist in EVPN-MH. If
  you choose it, those three cases are tested in a lab (criteria in `routing-switching-standards`).

**Storage and RDMA: badly done lossless networking propagates congestion**
- **PFC (IEEE 802.1Qbb, today incorporated into 802.1Q)** pauses per priority on the link, and its effect is
  **to push congestion backwards**: if the receiver does not drain, the pause propagates hop by hop and
  stops traffic that had nothing to do with it (*congestion spreading*). With buffer dependency
  cycles it can produce **PFC deadlock**, from which the network does not recover on its own.
- **That is why the order is ECN first**: ECN marking (**RFC 3168**) with per-queue thresholds and end-to-end
  rate control (**DCQCN** in RoCEv2, which combines ECN and feedback to the sender). PFC remains
  as a last-resort safety net, not as the primary mechanism.
- Requirements if it is deployed: **a single lossless class**, ETS (**IEEE 802.1Qaz**) sharing out the
  rest, priority mapping **consistent across every hop** (one mismatch breaks the guarantee),
  sized buffer *headroom*, and **monitoring of pause frames and ECN marking**: if
  nobody looks at the PFC counters, you do not know you are pausing.
- **InfiniBand versus RoCE** belongs to `high-speed-interconnect-standards` (**already written**).

**DCI: the danger of stretching layer 2**
- **By default, DCs are interconnected at layer 3.** Stretching layer 2 creates **a single
  failure domain with latency in the middle**: a storm, a loop or a control plane failure propagates to both
  sites at once, and the high availability that motivated the stretch disappears precisely in the scenario
  that justified it.
- If the requirement is real, it is bounded: only the necessary VNIs, with BUM and MAC control, separate
  failure domains on both sides and **a written retirement date**. A "temporary" stretch with no date is
  permanent. The correct alternative is almost always to **fix the application** that assumes L2
  adjacency and treats the IP as an identity.

**When an EVPN fabric is NOT needed — the section that adds the most value**
- **One rack, two ToRs and plain routing are enough.** With two switches, a couple of VLANs, LACP towards the
  servers and a redundant gateway, EVPN contributes nothing and adds a whole control plane that has to be
  known how to operate, diagnose and upgrade.
- **Honest thresholds for considering it**: more than a handful of racks; a real need to move a subnet
  between racks; multi-tenancy with overlapping addresses; standard multihoming to more than two
  leaves. **None of them is "we want VXLAN because it's modern".**
- **The cost that must be accepted first**: staff capable of diagnosing BGP with L2VPN families, a NOS with
  mature support, a lab to test changes, and automation (it is not operated by hand). If any of the four is
  missing, **an EVPN fabric is a source of incidents, not an improvement**.
- **Legitimate alternatives**: pure routing with ECMP and no overlay when each rack is a subnet;
  an overlay **on the host** (Kubernetes or the hypervisor already do it, `kubernetes-standards`) leaving the
  physical network as dumb, fast transport.
- **Rule**: **the complexity of the control plane is justified by a written requirement, not by the
  vendor's catalogue.**

## 4. Quality gates

- **End-to-end MTU verification** as an automatic gate after every change: a test with a large packet
  and the DF bit between VTEPs and between hosts on different VNIs, not configuration inspection.
- **Failure testing with real traffic and measurement** before production: the loss of a spine (must be
  transparent), of a leaf uplink, of a leaf on a multihomed server, and **the recovery from each of them**
  (coming back fails more often than going).
- **A negative tenant isolation test**: verify that the VRFs **cannot** reach each
  other. Multi-tenancy tested only along the happy path is not tested.
- **Consistency between peers of the same role**: the fabric is regular by design, so **a leaf that differs
  from the rest is a finding**. Automatic diff.
- **A virtual lab with the same NOS versions** before any change to EVPN, the underlay or
  VRF policy (tooling in `network-automation-standards`).
- With lossless networking: validate that the class is mapped identically on **every** hop and run a
  load test watching the PFC and ECN counters.

## 5. Operations and security

- **An OOB management plane for the whole fabric**, separate from the data traffic, with centralised AAA and
  SSH/SNMPv3 (the full criteria in `routing-switching-standards`). It is what lets you fix the
  underlay change that isolated a leaf.
- **The fabric is not a trust zone.** Sharing a fabric does not authorise traffic: east-west
  policy belongs to `firewall-policy-standards`. **A VRF segregates routing, it does not apply policy.**
- **VXLAN encrypts and authenticates nothing**: whoever can inject into the underlay can inject into a VNI.
  The underlay must be physically bounded and sensitive traffic protected above it (mTLS, IPsec,
  MACsec on links that leave the premises).
- **Signals that are always watched**: underlay and overlay BGP sessions, EVPN routes by type, MAC
  and ARP/ND entries per VTEP **against the ASIC's table limit** (exhausting it is a silent and
  brutal failure), per-interface discards and errors, **the real ECMP balance** (an unbalanced hash saturates
  one link with the fabric at 40%), PFC/ECN counters, and optics.
- **Upgrades**: one at a time, by role, **draining the node first** (removing it from the ECMP) and verifying
  between steps. Upgrading spines and leaves at the same time is how a data centre is lost.
- **Fabric-specific performance**: the value of a Clos is that every leaf-leaf pair is at the
  same distance and the high percentile of latency is stable — a design that improves the peak at the cost of
  unequal paths is worse for distributed applications, which wait for the slowest one. **ECMP with a
  per-flow hash, never per packet**; watch the real entropy (a few large flows unbalance ECMP
  even with spare capacity). The ASIC buffer is finite and shared: most of the
  unexplainable discards are *incast*, which is not fixed with more bandwidth.
- **Capacity**: the oversubscription ratio is reviewed with real per-rack data, not with the one from the
  original design. Cost per port and optics in `finops-standards`.

## 6. Performance

**Section deliberately omitted**: telemetry, its thresholds and its alerts belong to
`observability-standards`; reactive diagnosis, to `network-troubleshooting-standards`; and what is
specific to fabric performance is integrated into §5, where it is operated. Duplicating it here would be
filler.

## 7. Sustainability and prohibitions

- **Cadence**: the NOS reviewed quarterly and in the face of an exploitable CVE; **a stable branch with mature
  EVPN support** over the latest feature. An EVPN bug is an incident for the whole DC.
- **Deprecation**: retired VNIs, VRFs and ESIs are removed from the configuration, the SoT and the documentation.
- **End of support for the inventoried hardware**: the fabric is replaced by generations, and the plan
  starts before the vendor announces it.

**FORBIDDEN**
- ❌ Designing a new DC as one big switched network with stretched VLANs and STP as the convergence mechanism.
- ❌ Leaf-leaf or spine-spine links in a Clos.
- ❌ VXLAN **flood-and-learn** (without EVPN) in a new deployment.
- ❌ A fabric with MTU 1500, or with a different MTU on some link.
- ❌ A centralised gateway instead of a distributed anycast one, with no written requirement.
- ❌ Asymmetric IRB by default in a fabric that will grow.
- ❌ Stretching layer 2 between data centres with no written requirement, without bounding the failure domain and without
  a retirement date.
- ❌ PFC across the whole fabric "just in case"; or lossless networking without ECN, without consistent mapping on every
  hop and without monitoring pause counters.
- ❌ Treating the fabric as a trust zone and skipping east-west policy.
- ❌ Building an EVPN fabric for one rack, or without the staff, lab and automation to operate it.
- ❌ Upgrading several leaves or spines at once, or without draining the node first.
- ❌ Divergent configuration between devices of the same role, or made by hand outside the SoT.
- ❌ Not declaring the oversubscription ratio per rack role.
- ❌ ECMP with a per-packet hash.
- ❌ Putting a fabric into production without having tested and **measured** the loss of a spine, an uplink and a leaf with
  real traffic.

## 8. Mandatory web verification

**Methodology**: the RFCs were verified **one by one** against the `rfc-editor.org` JSON API (title,
status, date, `obsoletes`/`obsoleted_by`/`updated_by`), not against HTML summaries.

**RFCs verified Aug-2026**. **VXLAN = RFC 7348** (Aug-2014, **Informational** — it is not Standards
Track; citing it as "a standard" is incorrect); **Geneve = RFC 8926** (Nov-2020, Proposed Standard).
**EVPN = RFC 7432** (Feb-2015), updated by **8584, 9161, 9572, 9573 and 9746**; **EVPN over
NVO/VXLAN = RFC 8365** (Mar-2018), updated by **9746**. **Symmetric/asymmetric IRB = RFC 9135** and
**IP prefixes / type-5 = RFC 9136** (both Oct-2021). **DF election framework = RFC 8584** (Apr-2019,
updated by 9722 and 9785). **Split-horizon in EVPN multihoming = RFC 9746** (Mar-2025), which
**updates 7432 and 8365**. **Proxy ARP/ND = RFC 9161** (Jan-2022); **BUM = RFC 9572** (May-2024).
**BGP in large-scale DCs = RFC 7938** (Aug-2016, **Informational**). **IPv6 next hop for IPv4
NLRI ("BGP unnumbered") = RFC 8950** (Nov-2020), which **obsoletes RFC 5549** — citing 5549 today is a factual
error. **ECN = RFC 3168**, updated by 4301, 6040, 8311 and 9768. **IEEE**: PFC = **802.1Qbb** and
QCN = **802.1Qau**, both **incorporated into the 802.1Q base** (the current revision is 802.1Q-2022); ETS =
**802.1Qaz**; DCBX is an extension of LLDP (802.1AB).

**Declared discrepancy**: **RFC 7432 has a successor in progress.** `draft-ietf-bess-rfc7432bis` is
at revision **-14** with activity on **2-Mar-2026** and **is not yet an RFC** (`rfc: null` in the datatracker,
with no *intended std level* declared in the register consulted). The current normative reference is still
**RFC 7432**, but it is being replaced: verify whether it has been published before citing it in an
architecture document.

**Declared gaps — do NOT fill from memory**:
1. **The exact overhead bytes of VXLAN and Geneve** and the resulting concrete minimum MTU: **not
   verified byte by byte**. Geneve is **variable** because of its options. Calculate it and **test it**.
2. **Geneve support in ASICs** by platform and generation: **not verified**, and it is the criterion that
   decides VXLAN versus Geneve.
3. **ASIC table limits** (MAC, ARP/ND, routes, VTEPs, VNIs): **not verified**. They are the fabric's real
   ceiling and they vary by model and forwarding profile.
4. **EVPN versions and support status per NOS** (including open NOSes such as SONiC and FRR-based
   ones): **not verified**. Check the version, maintenance and **raw licence** before setting
   any of them as the default.
5. **ECN thresholds, PFC *headroom* and DCQCN parameters**: **not verified** and highly dependent
   on the hardware and the traffic profile. They start from the vendor's guidance and are validated under load.
6. **PFC deadlock in specific Clos topologies** and its current mitigations: general criteria here,
   **not cross-checked** against recent literature.
7. **Typical oversubscription ratios by workload** (AI versus general compute): they are engineering
   criteria, **not verified measurements**.
8. **`high-speed-interconnect-standards` already exists**: InfiniBand, RoCE v2, iWARP, the subnet
   manager, PFC deadlock as seen from the interconnect and NVMe over Fabrics **are theirs**.
   `datacenter-facilities-standards` **also exists**: the physical plant — power, cooling,
   cabling — is theirs. Do not improvise it here.

If the web contradicts this document, **the web wins** — flag the discrepancy.
