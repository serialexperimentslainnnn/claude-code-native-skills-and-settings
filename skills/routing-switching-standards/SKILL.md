---
name: routing-switching-standards
description: Campus and edge switching/routing design decisions that outlive the hardware. Use when choosing between RSTP/MSTP and a routed access layer, sizing a broadcast domain, configuring BPDU guard, root guard, storm control, portfast/edge, LACP bundles, MLAG/vPC/MC-LAG or a switch stack, first-hop redundancy with VRRPv3 (RFC 9568), HSRP or GLBP and its interaction with MLAG, picking OSPF versus IS-IS versus BGP as the campus IGP, writing eBGP import/export policy, route-maps, prefix-lists, as-path filters, maximum-prefix, BGP communities and large communities (RFC 8092), aggregation and no-export, RFC 8212 default-deny eBGP, RPKI route origin validation with Routinator/rpki-client/StayRTR and invalid=reject, ROAs (RFC 9582), RPKI-RTR (RFC 8210), IRR objects and as-set expansion, MANRS conformance, prefix hijacks and route leaks (RFC 9234 OTC), BCP 38/84 and uRPF (RFC 8704), BFD (RFC 5880/5881/5883), GTSM (RFC 5082), dual-stack IPv6 rollout planning, DSCP trust boundaries and queueing policy, CoPP/control-plane policing, 802.1X port-based access control, MACsec, SNMPv3 versus SNMP v1/v2c, TACACS+/RADIUS AAA on network devices, or an out-of-band management plane.
---

# Switching and routing standards — campus and edge

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **designing and operating the switched and routed campus, site and edge network**: sizing the
broadcast domain, STP and its real role today, loop protection, aggregation and multi-chassis
systems, the layer 2/layer 3 boundary, first-hop redundancy, IGP choice, **BGP policy in
depth**, global routing hygiene (RPKI, IRR, MANRS), IPv6 rollout, QoS with judgement, and
hardening of the management and control planes.

Triggers: `spanning-tree`, `rstp`/`mstp`, `bpduguard`, `root guard`, `storm-control`,
`port-channel`/`lacp`, `mlag`/`vpc`/`stack`, `vrrp`/`hsrp`/`glbp`, `route-map`, `prefix-list`,
`as-path access-list`, `maximum-prefix`, `community`/`large-community`, `aggregate-address`,
`rpki`/`origin-validation`, `routinator`, `rpki-client`, `stayrtr`, `as-set`, `MANRS`, `bfd`,
`ttl-security`, `copp`, `dot1x`, `macsec`, `snmpv3`, `tacacs+`, "hijack", "route leak", "DSCP".

**Not applicable** — each skill **decides** a different thing:
`networking-standards` (**trunk, the mother skill**: it decides **addressing and IPAM, which VLAN exists,
BGP/OSPF fundamentals, proxies and load balancing, host overlays, MTU/MSS and NetBox as SoT**; none of that
is reopened here, here we decide **how the switched network converges and what exactly the BGP policy
says**); `network-troubleshooting-standards` (**decides the reactive method** when something is already broken —
here the design and the proactive operation, and every structural finding of theirs comes back here);
`datacenter-fabric-standards` (**decides the DC fabric**: Clos, VXLAN/EVPN, lossless networking);
`network-automation-standards` (**decides how a change is generated, tested and applied** — here, **what
the configuration must say**); `firewall-policy-standards` (**decides which flow is permitted between zones
and under what governance**); `iac-standards` (**decides Terraform and Ansible as tools**);
`ot-ics-security-standards` (**decides the plant network, and that is not a campus**: its access
defaults —`storm-control`, `bpduguard`, 802.1X on every port, L3 to the access layer— break a
PROFINET/MRP ring and leave a PLC or an HMI with no supplicant off the network. **Here the criteria for campus and
for the control centre; the industrial segment is designed with theirs, and there *Safety* rules over
availability**); `observability-standards` (**decides what is measured and at what threshold it alerts**);
`identity-access-management-standards` (**decides corporate identity**; here only its consumption in device
AAA); `finops-standards` (transit and ports). Also boundary: `dns-standards`,
`vpn-standards`, `onprem-standards` (umbrella), `kubernetes-standards`, `secrets-management-standards`,
`sre-practice-standards`, `linux-hardening-standards`, `vulnerability-management-standards`,
`offensive-security-standards` (**this skill is defensive**), and `network-vendors-standards`,
`wan-legacy-standards`, `telco-5g-standards`, `high-speed-interconnect-standards` and
`datacenter-facilities-standards`.

**Guiding principle**: **a layer 2 decision is paid for over ten years.** Design so that **convergence
does not depend on STP** and so that **no prefix leaves without explicit authorisation**.

## 2. Default decisions

> Verify status and version on the web before pinning anything (§8). The RFCs in this table are
> verified one by one against the `rfc-editor.org` JSON API.

| Decision | Default | Justifiable alternative / vetoed |
|---|---|---|
| L2/L3 boundary | **Routed to the access layer**: the broadcast domain dies in the closet and the IGP converges, not STP | Centralised gateway **only** with a real L2 mobility requirement; never "because it was always done that way" |
| STP | **RSTP/MSTP enabled as a safety net**, with primary and secondary root pinned | ❌ STP as the design's **convergence mechanism**; ❌ root elected by MAC; ❌ disabling it "to go faster" |
| Loop protection | `bpduguard` + `rootguard` + `portfast/edge` + `storm-control` on **every** access port | Without BPDU guard, a consumer switch under a desk reconfigures your topology |
| Aggregation | **LACP active** (IEEE 802.1AX-2020) | ❌ `static`/`on`: it detects neither crossed cabling nor a half-dead member |
| Multi-chassis | **MLAG/vPC** with a peer link and a **dual** keepalive over a different path | Stack: **one control plane ⇒ one upgrade ⇒ one failure**; acceptable at the access layer, not in the core |
| First hop | **VRRPv3 — RFC 9568** (May 2024, **obsoletes RFC 5798**), IPv4+IPv6, explicit priorities and preempt | HSRP/GLBP only in a single-vendor estate. With MLAG, **the MLAG's own active-active gateway**; VRRP on top duplicates state |
| Campus IGP | **OSPF** for ubiquity and for the people who operate it | **IS-IS** (ISO 10589, RFC 1195; IPv6 in RFC 5308) for address-family independence and scaling; **BGP** if the topology is a routed fabric. ❌ Everything in `area 0` |
| Failure detection | **BFD — RFC 5880**, single-hop **5881**, multihop **5883**, tied to the IGP and to BGP | Relying on IGP hellos: seconds versus milliseconds |
| eBGP | **RFC 8212**: with no policy, nothing is advertised and nothing is accepted. Inbound **and** outbound filter on every session | ❌ A session with no `prefix-list`/`route-map` in both directions, no `maximum-prefix` with an action, no `as-path` filter |
| Global hygiene | **ROV with your own validator** (Routinator / rpki-client / StayRTR), **invalid = reject**; your own ROAs (**RFC 9582** profile, obsoletes 6482); RPKI-RTR **RFC 8210** | ROV in "mark only" indefinitely. A wide `maxLength`: **RFC 9319 (BCP)** advises against it |
| Antispoofing | **BCP 38 (RFC 2827)** and **BCP 84 (RFC 3704)**; strict uRPF where the path is symmetric, **RFC 8704** where it is not | ❌ An edge with no source filtering |
| Anti-leak | **RFC 9234** (BGP roles and the Only-to-Customer attribute) | ASPA **is still an Internet-Draft** (§8): useful, not the sole control |
| Session protection | **GTSM (RFC 5082)** on direct eBGP, plus BGP and IGP session authentication | A session exposed to the Internet with neither GTSM nor authentication |
| IPv6 | **Dual stack from day one**, with **parity** in filtering, logging and monitoring | ❌ "We'll do it later": the retrofit costs more, and the lack of parity is where the hole appears |
| QoS | **Trust only at the edge**: mark/remark on ingress, trust towards the core. DSCP **RFC 2474**, AF **2597**, EF **3246** | ❌ QoS as a substitute for capacity; ❌ trusting the user's DSCP |
| Management plane | **Physical OOB**, centralised AAA (**TACACS+** for per-command authorisation; RADIUS where it does not reach), SSH with keys, **SNMPv3 authPriv** | ❌ Telnet, management HTTP, SNMP v1/v2c, the `public` community, shared accounts |

## 3. Design conventions

**Layer 2 and its limits**
- **The broadcast domain is the blast radius**: a loop, a storm or a duplicate MAC
  affect everything sharing the VLAN. Size by impact, not by convenience.
- **STP is the safety net, not the plan.** It must be enabled and correctly parameterised, but a design
  whose convergence depends on STP recalculating accepts a failure of tens of seconds and a
  topology nobody can draw from memory. Convergence comes from routing to the access layer, LACP and MLAG.
- **MSTP** when there are many VLANs and they are spread across instances; then the **region (name, revision and
  VLAN→instance mapping) must be identical on every switch**: a mismatch splits the region
  silently.
- **MLAG failure modes to be decided before buying it**: peer-link partition (*split
  brain*), keepalive loss with a live peer, peer software upgrade, and state
  synchronisation (MAC, ARP/ND, IGMP). They are verified in the lab, not in the brochure.

**IGP choice — real criteria, not preference**
- **OSPF** with real areas (stub/totally stubby where applicable) and boundary summarisation, which is
  what bounds the reach of a *flap*.
- **IS-IS** if you want an IGP indifferent to the address family and with less surface (it does not
  run over IP). Cost: fewer people know how to operate it — a legitimate design criterion.
- **BGP** in a campus with a routed fabric or multi-tenant with VRFs; its strength is **policy**, not
  convergence (which is compensated with BFD).
- **One IGP for topology, BGP for policy.** Redistributing between them with no filters, no tags and no
  metric control is the classic way to create a permanent loop.

**BGP: what has to be decided explicitly**
- **Decision order** (verify the vendor's exact one): weight → `LOCAL_PREF` → locally
  originated → `AS_PATH` → `ORIGIN` → `MED` → eBGP over iBGP → IGP cost to the next hop →
  tie-break. **In practice what gets touched is**: `LOCAL_PREF` to choose the exit, `AS_PATH` prepending
  to influence the inbound (a blunt tool), `MED` only with the same neighbour.
- **Communities as a policy mechanism, not as a comment**: the edge **marks** on ingress
  (origin, neighbour type, geography, advertisement intent) and the rest of the policy **reads** those
  marks. **Large communities (RFC 8092)** with 4-byte ASNs; the standard ones (RFC 1997) fall
  short. Document the community dictionary as a contract if you do peering.
- **Aggregation**: advertise the aggregate and filter the specifics unless there is a written reason; deaggregating out of
  habit fattens everybody's global table. Watch out for the black hole of an aggregate with no discard route.
- **Outbound filtering — the lesson of the hijacks**: the incidents of traffic redirection
  and crypto-asset theft via BGP were not sophisticated attacks, but **a prefix
  advertised by someone who should not have and a neighbour who did not filter**. The defence that works is boring:
  an explicit outbound filter, an inbound filter by expected prefixes, `maximum-prefix` with an action and
  ROV with invalid=reject. **Signing ROAs protects everybody else; validating is what protects you.**
- **IRR**: still the basis for automatic filter generation in peering, but **its quality
  is uneven** (stale objects, `as-set`s with no authority that expand to thousands of prefixes, with no
  ownership validation). Use it **together with** RPKI, preferring RIR registries and with an explicit
  expansion limit.
- **MANRS**: alive; secretariat and operations moved from the Internet Society to the **Global Cyber Alliance**
  (2024), with ISOC keeping funding and training. Use it as an **auditable
  checklist** (filtering, antispoofing, coordination, validated global data), not as a badge.

**IPv6 and QoS**
- The IPv6 plan is done **once**; redoing it with firewall, DNS and monitoring already written costs a
  multiple (the concrete plan belongs to `networking-standards`). **The real risk is not having no IPv6: it is
  having it half-done** — enabled by default on the systems and with no policy equivalent to IPv4.
- **QoS distributes scarcity; it does not create capacity.** If the link is saturated in a sustained way, it only
  decides who suffers. Size first, prioritise after. It is useful for traffic sensitive to
  latency and jitter and for protecting the control plane; marking end to end with no agreement across
  every hop —and transit usually rewrites DSCP— is decorative.

## 4. Quality gates

- **A routing change is tested in the lab**: BGP policy and redistribution have
  effects that only show up with the full topology, and their failure is global and silent. A virtual
  lab with the same NOS versions (tooling in `network-automation-standards`).
- **A window with timed rollback and an OOB console open** on every remote routing or
  filtering change; abort criteria written **before** starting.
- **Negative tests**: after touching BGP policy, verify **what is advertised** from an external view
  (looking glass or collector), not just what is received. A filter tested only through the happy path is
  not tested.
- **Measured convergence**: bring down the primary link or node and measure the time until **application
  traffic** recovers, not until the protocol says "up". An unexercised failover does not
  count, and the way back fails more often than the way out.
- **Drift detection** against the SoT as a periodic gate (mechanics in `network-automation-standards`).

## 5. Management and control plane security

- **A separate, out-of-band management plane**: dedicated VLAN/network, with no route from user networks,
  reachable only via a bastion. It is **the first target after the initial compromise**, and it is also what
  saves you when the change that broke the network is yours.
- **Centralised AAA with named accounts**: **TACACS+** on network devices when you want
  **per-command** authorisation and accounting (RADIUS does not provide it); RADIUS for 802.1X. A single local
  emergency account, held in the secrets manager (`secrets-management-standards`) and rotated after
  each use.
- **Protocols, no nuance**: **SSH** with keys and **SNMPv3 authPriv**. **Telnet, management HTTP
  and SNMP v1/v2c are FORBIDDEN** (a cleartext community = a credential on the wire; with write access = control of
  the device). Unnecessary services switched off; CDP/LLDP off untrusted ports.
- **802.1X (IEEE 802.1X-2020)** on wired access and WPA3-Enterprise on wireless, with dynamic VLAN,
  quarantine and an **explicit policy for what happens if the supplicant fails**: fail-open turns the
  control into theatre; fail-closed demands a plan for printers and equipment with no supplicant (MAB, which is weak
  and must be a registered exception). `port-security` where 802.1X does not reach; **MACsec** on links between
  closets or buildings when the medium is not trusted.
- **CoPP is not an extra**: a rate policy per class towards the CPU (routing, management, ARP/ND, ICMP,
  the rest). Without it, anyone with access to the segment takes down the control plane with trivial traffic and
  the device stops converging exactly when it is most needed. Verify the limits in the lab: a
  CoPP that is too aggressive breaks routing itself.
- **Lifecycle**: the vendor's CIS baseline, firmware reviewed quarterly and on an exploitable CVE
  (`vulnerability-management-standards`), inventory with an end-of-support date. A switch out of
  support has a replacement plan or it is a hole, but it is not a deferrable decision.

## 6. Operation and capacity

- **Signals that are always watched** (platform in `observability-standards`): errors and discards per
  interface, utilisation by percentiles, **STP topology changes (TCN)**, stability of IGP adjacencies
  and BGP sessions, prefixes received per neighbour against `maximum-prefix`, ROV result, optics
  and **control plane CPU**. A rising TCN counter is a finding, not noise: behind it there is usually
  a port with no `portfast/edge` or a flapping link.
- **Capacity with data**: percentiles of sustained utilisation, action threshold around 70%, and a
  horizon longer than the purchase and installation lead time. Port and transit cost in `finops-standards`.
- **Configuration as code**: it lives in the repository and is applied from there; per-device backups
  versioned and restorable (mechanics in `network-automation-standards`).
- **Runbooks with an owner**: uplink loss, layer 2 loop, a route leak of your own or of a neighbour,
  MLAG failure, control plane saturation, management certificate expiry.

## 7. Sustainability and prohibitions

- **Cadence**: NOS and firmware reviewed quarterly; nothing without vendor support unless there is a written
  exit date; stable/LTS branches over the latest feature.
- **Real deprecation**: a retired VLAN, BGP session or rule is removed from the configuration, the SoT and the
  documentation. "Just in case" is debt with compound interest.

**FORBIDDEN**
- ❌ Relying on STP to converge; or disabling it "because there is MLAG".
- ❌ An access port without `bpduguard`, `portfast/edge` and `storm-control`.
- ❌ Extending a VLAN between buildings or sites for convenience (for DCI, see `datacenter-fabric-standards`).
- ❌ **Static** aggregation (`on`) instead of LACP.
- ❌ Deploying MLAG without lab-testing *split brain*, keepalive loss and peer upgrade.
- ❌ A chassis stack as the only redundancy in the core or distribution layer.
- ❌ Overlaying VRRP on an MLAG active-active gateway without understanding what each state gains.
- ❌ An entire IGP in `area 0`, or redistributing with no filter, no tag and no metric control.
- ❌ An eBGP session with no inbound **and** outbound filter, no `maximum-prefix` with an action, or trusting
  the vendor's default instead of RFC 8212.
- ❌ Advertising to the Internet what was learned from the Internet (transit leak) for lack of an outbound filter.
- ❌ RPKI in "mark only" indefinitely, or publishing ROAs and not validating.
- ❌ Generating filters from an IRR `as-set` with no expansion limit and no review.
- ❌ An edge with no BCP 38/84 and no uRPF.
- ❌ IPv6 without filtering, logging and monitoring parity with IPv4.
- ❌ Trusting the user's DSCP, or using QoS to paper over a badly sized link.
- ❌ Network equipment without CoPP.
- ❌ Telnet, management HTTP, SNMP v1/v2c, default communities, factory credentials, shared
  accounts.
- ❌ A management interface reachable from a user network or from the Internet.
- ❌ 802.1X in permanent fail-open, or generalised MAB with no register of exceptions.
- ❌ A routing change with no prior lab, no timed rollback and no OOB console.
- ❌ Declaring that a failover "works" without having exercised and **measured** it with real traffic.

## 8. Mandatory web verification

**Methodology**: the RFCs in this document were verified **one by one** against the `rfc-editor.org`
JSON API (title, status, date, `obsoletes`/`obsoleted_by`), not against HTML summaries.

**RFCs verified Aug 2026, with the corrections they introduced**. **VRRPv3 = RFC 9568** (May 2024),
which **obsoletes RFC 5798** — citing 5798 today is a factual error. **ROA profile = RFC 9582**
(May 2024), which **obsoletes RFC 6482**. **RPKI-RTR v1 = RFC 8210** (Sep 2017; RFC 6810 is v0,
*updated by* 8210). **Origin validation = RFC 6811**, updated by **8481** and **8893**;
**`maxLength` = RFC 9319** (BCP). **BGP roles / OTC = RFC 9234** (May 2022). **BGP-4 = RFC 4271**
(*Draft Standard*), updated by twelve RFCs among them **8212** (eBGP with no policy does not propagate) and
**7606**. **Communities = RFC 1997**; **large communities = RFC 8092**. **BFD = RFC 5880 / 5881 /
5883**. **GTSM = RFC 5082**. **BGP Ops & Security = RFC 7454** (BCP). **Antispoofing = RFC 2827
(BCP 38)** and **RFC 3704 (BCP 84)**, updated by **RFC 8704** (BCP). **IS-IS**: ISO/IEC 10589 with
**RFC 1195**, IPv6 in **RFC 5308**. **QoS**: **2474 / 2597 / 3246**.
**ASPA is NOT an RFC**: `draft-ietf-sidrops-aspa-profile` rev **-29** and `…-verification` rev **-27**, both
with activity on **3 Aug 2026**. **IEEE**: **802.1AX-2020** (aggregation; amendment 802.1AXdz-2025,
YANG) and **802.1X-2020**; **RSTP (ex-802.1w) and MSTP (ex-802.1s) are no longer independent standards**,
they are consolidated into 802.1Q (2022 edition plus amendments).

**Declared discrepancy — RPKI ROV enforcement**: the sources do not agree because **they measure different
things**. `networking-standards` records ~12.3% of **ASes** applying full ROV (Jun 2026); an
arXiv article from Mar 2026 gives "less than 30% of **user addresses** in networks that filter
invalids". Both can be true at once. Moreover, the **NIST RPKI Monitor**
(`rpki-monitor.antd.nist.gov`) **explicitly warns that it does not measure which networks actually filter**.
Do not cite a single "ROV deployment" figure without saying what it measures.

**Declared gaps — do NOT fill them from memory**:
1. **Current figures for ROA coverage and ROV enforcement**: second-hand here; verify at
   NIST RPKI Monitor, RIPE NCC and APNIC.
2. **MANRS participants and the status of its programmes**: the handover of the secretariat from ISOC to the
   **Global Cyber Alliance** (2024) is on record, and "more than 1,300 participants" cited at the community meeting
   of **17 Jun 2026** in an article by MANRS itself; **not independently verified**.
3. **Exact order of the BGP decision process per vendor**: every implementation adds steps
   (`weight`, `MED` across different ASes, multipath, deterministic bestpath). Verify in their documentation.
4. **MLAG behaviour under split brain, keepalive loss and peer upgrade**:
   **specific to each implementation**, not verified here. It is checked in the lab.
5. **Current editions of IEEE 802.1Q and its amendments**: from a search, **not cross-checked**
   against the IEEE SA catalogue.
6. **Version, maintenance and licence of Routinator, rpki-client and StayRTR**: **not verified**.
7. **Relative reliability of each IRR** and their object validation policies: **not verified**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
