---
name: wan-legacy-standards
description: The inherited wide-area network that is still carrying production traffic, and the replace-or-keep decision. Use when working with an MPLS L3VPN or L2VPN/VPLS service, VRF-lite and route distinguishers, route targets and import/export policy, a CE-PE handover and the contractual class-of-service and SLA that justifies the price, pseudowires, martini circuits, Carrier Ethernet EVPL/EPL and MEF service definitions, DIA versus a leased line versus broadband with a tunnel, a hybrid WAN or an SD-WAN migration and its cloud control plane dependency, Cisco Catalyst SD-WAN / Viptela vManage, Versa, Silver Peak, VeloCloud, Frame Relay DLCI and LMI, ATM PVC and AAL5, X.25, ISDN BRI/PRI and backup dial, leased serial lines, E1/T1, G.703, V.35, RS-232 and RS-485 telemetry circuits, a PSTN/POTS or copper switch-off notice, WLR withdrawal and stop sell, analogue modems and dial-up for out-of-band access, point-to-point circuits feeding SCADA and telecontrol, LLQ/CBWFQ and shaping on a slow link, compression and fragmentation-and-interleave, or a circuit whose only job is to serve equipment nobody is allowed to touch.
---

# Legacy WAN standards — MPLS, old circuits and the replace decision

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the wide-area network that already exists and was not designed yesterday**: carrier MPLS
services (L3VPN, L2VPN/VPLS) and their contract; leased circuits, Carrier Ethernet and dedicated
Internet access; the replacement by **SD-WAN** and its real cost; the **legacy circuit
technology** that is still alive (Frame Relay, ATM, ISDN, X.25, serial lines, modems); the
**regulatory switch-off calendars** for copper and PSTN, which are the forced trigger for
most of these migrations; QoS on slow links; and the criterion of **replacing versus
keeping** when the circuit serves something that cannot be touched.

Triggers: `VRF`, `route-target`, `route-distinguisher`, `mpls`, `xconnect`, `pseudowire`, VPLS,
`DLCI`, `LMI`, `PVC`, `AAL5`, `BRI`/`PRI`, `X.25`, `V.35`, `G.703`, E1/T1, RS-232/RS-485;
vManage/Catalyst SD-WAN, Versa, VeloCloud, Silver Peak; "WLR withdrawal", "stop sell", "copper
switch-off", "PSTN switch-off", "all-IP"; `service-policy`, `shape average`, `priority`, LLQ,
CBWFQ, LFI; "ISDN backup", "telecontrol line", "point-to-point circuit".

**Not applicable**: the catalogue already divides this up — `networking-standards` is the **trunk**
(addressing, VLAN, MTU/MSS, proxies, overlays, OOB plane) and **already delegates the depth**;
`routing-switching-standards` decides the **BGP policy** towards the outside, the site IGP, RPKI and
campus QoS (**here only the QoS of the slow WAN link and the CE-PE**);
`datacenter-fabric-standards` decides the internal fabric and **the danger of stretching layer 2** over DCI
(**here, VPLS as a contracted service, not as a DC design**); `vpn-standards` decides the **tunnel
and the concentrator** (WireGuard, IPsec/IKEv2, OpenVPN) — here only **when a tunnel over the Internet
replaces a contracted circuit and what is lost**; `firewall-policy-standards` (what crosses it);
`network-automation-standards` (how the change is applied); `network-troubleshooting-standards`
(the reactive method); `load-balancing-standards`, `dns-standards`;
`network-vendors-standards` (**operating model, licences, EoS and CPE vendor risk —
including the dependency on the SD-WAN control plane as vendor lock-in**);
`telco-5g-standards` (the carrier network seen from inside: 5G SA/NSA, slicing, APN, NB-IoT/LTE-M and
**5G FWA as an access**). Outwards: **`ot-ics-security-standards` owns the security of the industrial
system** —ISA/IEC 62443 zones and conduits, field protocols, the SIS— and here only
**which circuit transports it and how it is replaced without stopping the process** is decided;
`bcdr-standards` (RTO/RPO that justify the backup link), `finops-standards` (recurring
circuit cost), `observability-standards` (link telemetry),
`edge-computing-standards`, `offensive-security-standards` (**this skill
is defensive**).

## 2. Default decisions

> Verify on the web the real status of the service, its end of sale and **the regulatory
> calendar of the specific country** before committing to anything (§8). Switch-off dates **change and get
> delayed**, and they differ by country and by carrier.

| Situation | Default | Justifiable alternative |
|---|---|---|
| New site, traffic mostly to SaaS/cloud | **Dedicated Internet access (DIA) + encrypted tunnel**, dual carrier | MPLS if there is a contractual requirement for an end-to-end SLA |
| Site with critical interactive traffic between own sites | MPLS L3VPN **or** SD-WAN over two accesses with an access SLA | A dedicated point-to-point link if latency is the hard requirement |
| Site backup | **A second access on a different medium** (fibre + mobile), not a second circuit from the same carrier through the same duct | A single access, if the RTO allows it in writing |
| Legacy circuit serving an untouchable system | **Keep and isolate** until there is a process shutdown window | Replace only with a tested rollback plan and a window agreed with operations |
| Migration forced by a regulatory switch-off | Start **24 months before** the firm date | — |
| Stretching layer 2 between sites (VPLS/EPL) | **Avoid**. Route | Only if an application demands it and the failure domain is documented |
| Analogue modem / ISDN as rescue access | **Replace with a cellular modem on the OOB management network** | — |

## 3. Structure and conventions

### MPLS: what you are actually buying

What a carrier sells as "MPLS" is **almost always L3VPN (RFC 4364)**: the CE hands routes to the
PE over a routing protocol (eBGP, OSPF or static), the PE puts them in a **VRF** identified
by a *route distinguisher*, and VPN membership is controlled with import and export **route targets**.
The customer never sees the MPLS label: it sees a cloud that routes.

- **The RD disambiguates, the RT decides membership.** Confusing them produces malformed VPN
  topologies (a hub-and-spoke that turns out to be a full mesh, extranets that leak). On the customer
  side this matters when non-trivial topologies are requested: **demand the RT design from the carrier in writing**.
- **L2VPN / VPLS** delivers Ethernet: point-to-point pseudowires (EPL/EVPL in MEF language) or a
  multipoint broadcast domain. It is bought "because it is transparent", and that transparency is the
  problem: **a loop or a storm at one site propagates to all of them**. If it is contracted, it goes with
  storm control, a MAC limit and a written reason.
- **MTU**: the carrier's encapsulation reduces the usable MTU. Negotiate **an MTU of 1600+ on the access** or
  accept MSS clamping and fragmentation. It is the classic root cause of "everything works except the
  large transfers".

**What justifies the price and the Internet does not give you** — it is the only honest argument in favour of MPLS:

1. **A contractual end-to-end SLA with penalties**: availability, latency, *jitter* and
   loss **between sites**, measured by the carrier and with credits for breach. On the Internet
   only the **access** is contracted; nobody guarantees the path between carriers.
2. **Classes of service honoured in the carrier's core**, not just on the CPE. Marking DSCP on
   the Internet is marking for nobody.
3. **A single responsible party** when it fails: there is no blame-sharing between two ISPs.
4. **Private delivery** without Internet exposure (although **the traffic is not encrypted by default**:
   MPLS isolates, it does not encrypt — see §5).

**Criteria**: if the requirement cannot be written as a clause with a penalty, **there is no business
case for MPLS**. If it can be, the price buys something real.

### SD-WAN: what it solves and what it buys in exchange

What it **really** solves, and it is quite a lot:

- Using **several heterogeneous accesses simultaneously** with path selection per application and by
  active measurement (loss/latency/jitter), not by a static metric.
- **Direct Internet/SaaS breakout** from the site instead of backhauling to the datacenter, with the policy
  applied at the edge.
- **Site provisioning** in hours instead of in the lead time of a circuit installation.
- Centralised policy and templates instead of per-device configuration.

What it adds, and is usually omitted from the decision:

- **Dependency on the control plane**, usually in the vendor's cloud (orchestrator and
  controllers). Ask in writing: what happens at the site if the orchestrator is unreachable
  for hours? And for days? Does the tunnel survive? Can it be recovered without it? The correct
  answer is "the data plane carries on with the last policy"; **it must be verified in a lab,
  not believed**.
- **Strong vendor lock-in**: CPE, per-site licences, orchestrator and policy model are
  proprietary and not interchangeable. It is a lock-in decision (`network-vendors-standards`), not
  a purchase of boxes.
- **A new surface**: the orchestrator is a high-value target. SD-WAN controllers have
  accumulated critical authentication vulnerabilities (see `vpn-standards` §history). It goes behind
  MFA, isolated and patched with the same urgency as an IdP.
- **Migration of SLA responsibility to the customer**: with two Internet accesses, the one who
  answers for end-to-end quality is you.

**When NOT to migrate** — the honest criteria:

- When the real requirement is a **contractual SLA between sites** with penalties (see above).
- When there are **few sites** (fewer than ~10–15): the cost of licences, orchestrator and rollout is not
  amortised against the circuit savings.
- When the traffic is still **mostly between your own sites and jitter-sensitive** (internal
  voice, terminal applications, industrial protocols) and not towards SaaS.
- When the alternative access carrier **is the same one and through the same duct**: then there is
  no diversity, just two invoices.
- When the team does not have the capacity to operate the new model. A badly operated SD-WAN is worse than
  a boring MPLS that has been working for eight years.

> **Savings figures: vendor folklore.** The published figures for SD-WAN savings against
> MPLS range from **20 % to 90 %** depending on the source, and **no independent study with
> transparent methodology was located**. The defects are structural and repeated: (a) they attribute to SD-WAN
> savings that come from **consolidating vendors at the same time**; (b) they compare an "all
> inclusive" MPLS invoice against **only the bandwidth line** of the new design, omitting licences, CPE,
> rollout and management; (c) they omit one-off costs (rollout and per-site installation); (d)
> they extrapolate from estates of hundreds of sites; (e) they present **illustrative models** as
> measured results. As a useful counterpoint, an independent industry consultancy documented a
> real case where the bandwidth saving was **10 %** and it still recommended the migration for
> resilience and throughput. **Rule: do not quote a savings percentage that does not come from your own
> invoice.** The business case is built with the prices quoted to your company, for your number
> of sites, with the one-off costs included.

### What is still alive, and why

| Technology | Status | Where it survives and why |
|---|---|---|
| **Frame Relay** (DLCI, LMI) | Withdrawn by the large carriers years ago; residual/*grandfathered* listings in wholesale tariffs | Legacy islands with FR↔ATM interworking. **Nothing new is contracted** |
| **ATM** (PVC, AAL5) | The same: residual | Legacy backhaul and the odd old enterprise access |
| **X.25** | Practically extinct on the public network | Very old financial and telecontrol terminals, almost always **emulated over IP (XOT)**, not native |
| **ISDN** (BRI/PRI) | Switched off with the PSTN: **ISDN depends on the same infrastructure** | Old telephony head-ends, dial backup and lifts. **PRI is replaced by a SIP trunk** |
| **Serial lines / E1-T1, V.35, G.703** | Still contracted as a leased circuit, increasingly badly | Telecontrol, substation protection, synchronisation |
| **RS-232 / RS-485 point-to-point** | Alive and well on the plant floor | Telecontrol and field. It is extended with serial-to-Ethernet converters, **which is exactly where the risk creeps in** (§5) |
| **Analogue modem / dial-up** | Dies with the PSTN | OOB rescue access. **Replace with cellular**, not with "another modem" |

### The copper and PSTN switch-off — hard data, and it varies by country

**It is the forced trigger**: it is not an optional modernisation, it is a date on which you lose the
service. **Always** verify the country's and the carrier's calendar (§8).

- **Spain — completed.** The CNMC publishes it unambiguously: *"27 de mayo de 2025. Hoy se completa
  en España el proceso de cierre de las centrales de cobre"*, switching off *"las últimas (661
  centrales, distribuidas por toda la geografía)"* (CNMC blog, 27-05-2025). The total estate
  was 8,532 exchanges; the first two were closed in 2014. The closure was supervised by the CNMC through
  the wholesale market analysis procedure, **with a firm date per exchange communicated in
  advance**. Practical consequence: in Spain **there is no ADSL over Telefónica's copper pair
  left, no PSTN, no ISDN over that network**. If a Spanish project plan still assumes an analogue
  line or a copper PRI, it is wrong.
- **United Kingdom — in progress, with a shifted date.** The WLR *stop sell* is from September 2023 and
  the PSTN/WLR switch-off was delayed from 31-12-2025 to **January 2027**. **Data taken from
  secondary industry sources, not from Openreach as a primary source: verify (§8)**; there is
  simultaneous circulation of "December 2027", which appears to be incorrect. ISDN2/ISDN30 fall with it, and
  the ADSL associated with a WLR dies with the line even if nobody uses the phone.
- **Germany — all-IP migration completed** around 2020 (the wholesale migration of data
  lines was declared complete in May 2020; pure voice lines and multi-terminal ISDN
  dragged on afterwards). **Sources disagree on the exact final date: verify in
  Deutsche Telekom's press releases if the fact decides anything (§8).**
- **United States — accelerated by regulation in 2026.** In March 2026 the FCC adopted an order
  that facilitates copper retirement: it allows *grandfathering* of legacy services (they are kept
  for existing customers but **are not sold to new ones** and can be discontinued sooner), removes
  network change notification requirements and simplifies discontinuance through technology
  transition, although **FCC authorisation is still required** when the retirement implies
  discontinuing the service. **A verbatim quote from the official document could not be obtained (§8).**
  Consequence: in the US the immediate risk is not the switch-off, it is **no longer being able to move
  or order** a legacy TDM circuit.

**Operational criteria**: for every country with sites, maintain a **table with the firm date, the
*stop sell* date and the end-of-moves date**. The *stop sell* arrives long before the
switch-off and it is the one that breaks projects: it prevents ordering or moving a circuit that the plan assumed
was available.

### QoS on slow links

It still exists, and most of the modern QoS doctrine **does not apply** to a 2 Mbps link:

- ***Shape* to the contracted throughput**, not to that of the physical interface. If the carrier delivers
  10 Mbps over a Gigabit port, without *shaping* the queue is at the carrier and the CPE's QoS does
  nothing. **This is the most frequent WAN mistake.**
- **A single, bounded strict priority queue (LLQ)**, for voice/control. If everything is priority,
  nothing is.
- **Fragmentation and interleaving (LFI)** stops being necessary above ~768 kbps; below that,
  without it a large packet introduces a serialisation delay that ruins voice.
- Marking is only worth something **within a domain that honours it**. Marking towards the Internet does nothing;
  towards an MPLS PE it does whatever the class-of-service contract says (which must be read: the
  carrier's DSCP→class mapping rarely matches the internal one).

## 4. Quality and verification

- **Circuit acceptance test before putting it into production**: throughput in both directions,
  latency and jitter under load, sustained loss, and **behaviour on failure of the primary link**
  (the real switchover time, not the brochure's). It is documented and archived: it is the baseline against
  which the SLA will be claimed.
- **Test the backup for real, with an actual cut of the primary and in an agreed window.** A backup
  link never tested does not exist, exactly like a backup never restored
  (`bcdr-standards`).
- **Verify physical diversity**, not logical diversity. Ask the carrier for written confirmation that
  the two accesses do not share duct, chamber or exchange. It is common to discover that they do.
- **Before touching a telecontrol circuit**: an inventory of what depends on it, a window agreed
  with operations/the plant, and a **tested rollback plan**. Acceptance is signed by whoever operates the
  process, not by the network team.

## 5. Security

- ❌ **MPLS does not encrypt.** It is isolation by labelling and trust in the carrier, not
  confidentiality. **All sensitive traffic goes encrypted over MPLS too** (IPsec or MACsec depending on
  the case). The carrier saying "it is a private network" is not a cryptographic control.
- **A CE is an exposed device**: the carrier's PE is outside your trust domain.
  Filtering on the CE, authentication of the routing session (BGP with TCP-AO or MD5 depending on support),
  a limit on received prefixes, and no management listening towards the WAN side.
- **Serial and telecontrol circuits**: they have no authentication and no integrity. **The compensating
  control is physical and segmentation-based** —the zone and the conduit are decided by `ot-ics-security-standards`—; what
  is decided here is that **putting a serial-to-Ethernet converter on a routable network turns a physical
  risk into a remote one**. If it is done: a dedicated network, with no Internet egress, with no exposure of the
  converter's management, and with the change approved by the process owner.
- **ISDN and rescue modems**: a modem that answers is an access without strong authentication and without
  logging. If one exists in the estate, it is a finding, not a feature. Replace it with cellular OOB
  access with MFA and logging (`vpn-standards`, `identity-access-management-standards`).
- **The migration is the moment of greatest exposure**: two coexisting paths, duplicated rules and
  temporary ones that stay, and policy that gets relaxed "until it stabilises". Every migration
  exception carries a **written expiry date** (`firewall-policy-standards`).
- **When retiring a circuit**: formal cancellation with the carrier, removal of the associated rules,
  inventory update and **secure wipe of the returned CPE** (it contains keys, certificates and the
  full configuration of your network).

## 6. Operability

- **Measure the link independently of the carrier**: active end-to-end probes
  (latency, jitter, loss) and availability measured by you. Without your own measurement, an
  SLA claim is an argument of opinions. What is instrumented and with which threshold belongs to
  `observability-standards`; **what this skill decides is that it is measured, and that the metric agreed in
  the contract is the one instrumented**.
- **Read the SLA as an engineer**: what is measured, where it is measured, how monthly availability
  is computed, what is excluded (planned maintenance, force majeure, failure of the radio
  access), what the committed MTTR is and **how the credit is claimed**. An SLA with a credit
  of 5 % of the fee is not an incentive: it is decorative.
- **Circuit inventory as first-class data**: carrier identifier, location,
  throughput, provisioning date, renewal date, early-termination penalty, incident contact
  and **which systems it serves**. Half of the spend on legacy WAN is on circuits that
  nobody knows the purpose of and nobody dares to cut.
- **Method for cutting what nobody knows the purpose of**: instrument the traffic, check utilisation
  over a full business cycle (including monthly and annual closes), give notice, **switch it off
  reversibly** (administrative block, not contractual cancellation) and wait. Only afterwards, the cancellation.

## 7. Sustainability and prohibitions

- Review the WAN estate **annually** against the switch-off calendars and against the contractual
  renewal dates. The automatic three-year renewal of an obsolete circuit is how you end up
  paying for copper in 2029.
- Every legacy circuit kept by decision carries a **review date and a written reason**
  ("it serves the PLC on line 3, no shutdown window until the annual August shutdown"). Conscious
  debt, not oversight.
- Document in an ADR the MPLS/SD-WAN/Internet decision with the condition that would reopen it (end
  of contract, opening of sites, change of the traffic profile towards SaaS).

Prohibitions:

- ❌ **FORBIDDEN** to quote an SD-WAN savings percentage that does not come from the project's real
  quotes and invoices. The published figures (20–90 %) are marketing material with no methodology.
- ❌ **FORBIDDEN** to plan a migration forced by a regulatory switch-off with less than 24 months, or
  ignoring the ***stop sell*** date, which arrives much earlier and is the one that blocks orders and moves.
- ❌ **FORBIDDEN** to write from memory a switch-off date for copper, PSTN or ISDN. **It varies by country,
  by carrier and it gets delayed** (§8).
- ❌ **FORBIDDEN** to treat MPLS as encrypted transport.
- ❌ **FORBIDDEN** to contract two "redundant" accesses without written confirmation of physical diversity.
- ❌ **FORBIDDEN** to accept as good a backup link that has never been switched over with a real cut.
- ❌ **FORBIDDEN** to expose to a routable network a serial-to-Ethernet converter or a telecontrol gateway
  without the process owner's approval and without dedicated segmentation.
- ❌ **FORBIDDEN** to leave an analogue or ISDN rescue modem in the estate as emergency access.
- ❌ **FORBIDDEN** to apply QoS on the CPE without *shaping* to the contracted throughput: the queue stays at the
  carrier and the policy does nothing.
- ❌ **FORBIDDEN** to stretch layer 2 between sites (VPLS/EPL) without a written reason and without a MAC limit and
  storm control.
- ❌ **FORBIDDEN** to return a CPE to the carrier without a secure wipe of its configuration and its keys.
- ❌ **FORBIDDEN** to cancel a circuit serving an industrial system without a window agreed with
  operations and a tested rollback plan.

## 8. Mandatory web verification

**Always** check, in a primary source (national regulator, incumbent carrier, contract):

1. **The copper and PSTN switch-off calendar for the specific country** and for the incumbent
   carrier, plus the ***stop sell* date** and the end-of-moves date. It is the fact most
   often asserted wrongly and **it changes by country**. Spain: CNMC (completed 27-05-2025). United Kingdom:
   Openreach (**the January 2027 figure taken from trade press, not from Openreach — verify**).
   Germany: Deutsche Telekom (sources disagree on the final date). US: FCC orders
   on copper retirement and §214 discontinuance.
2. **End of sale and end of support** of the specific service in the carrier's catalogue
   (Frame Relay, ATM, PRI, serial lines): ask for it in writing, do not infer it.
3. **The text of the current SLA**: metrics, measurement points, exclusions, MTTR and the credit
   procedure. And the carrier's **DSCP → class-of-service mapping**.
4. **Early-termination penalty** and automatic renewal date of each circuit.
5. **Control-plane failure model of the SD-WAN** of the candidate vendor: what survives at the
   site without the orchestrator and for how long. And its **open security advisories** for the
   orchestrator and the controllers (`network-vendors-standards`).
6. **Status of the European regulatory proposal** affecting high-risk vendors if the CPE
   or the access equipment is from a restricted vendor (`network-vendors-standards` §5).

**Declared gaps**: (a) the UK PSTN switch-off date and the exact final date of the
ISDN switch-off in Germany come from search summaries and trade press, not from the primary
source — **do not use without verifying**. (b) No verbatim quote was obtained from the March 2026 FCC
order: the official PDF (`docs.fcc.gov`) could not be converted to readable text; the content described
comes from summaries. (c) **No** independent and methodologically
transparent study on SD-WAN savings versus MPLS was located; that is why this skill forbids quoting percentages.
(d) The sales status of Frame Relay/ATM was not verified carrier by carrier: it is only
established that the withdrawals are mostly historical and that residual listings remain.

If the web contradicts this document, **the web wins** — flag the discrepancy.
