---
name: ot-ics-security-standards
description: Securing industrial control and operational technology where availability and physical safety outrank confidentiality. Use when working with PLCs, RTUs, HMIs, DCS, SCADA masters, historians or a Safety Instrumented System (SIS), the Purdue/ISA-95 level model and an industrial DMZ at Level 3.5, ISA/IEC 62443 parts (62443-2-1, 62443-3-2 zones and conduits and its ZCR workflow, 62443-3-3 system requirements, 62443-4-1 and 62443-4-2 component requirements, SL-T/SL-C/SL-A security levels, the seven foundational requirements), NIST SP 800-82r3 and its OT overlay, IEC 62351 and NERC CIP, unauthenticated field protocols (Modbus TCP port 502, DNP3 / IEEE 1815 Secure Authentication SAv5, EtherNet/IP and CIP, PROFINET, S7comm, IEC 60870-5-104, BACnet), OPC UA SecurityPolicy selection (Aes256_Sha256_RsaPss, Aes128_Sha256_RsaOaep, Basic256Sha256, SecurityMode None) and deprecated Basic128Rsa15/Basic256, passive monitoring with a TAP or SPAN and why an active scan crashes a controller, a data diode or unidirectional gateway, vendor and OEM remote access into the plant, engineering workstations and project files, twenty-year asset lifecycles and unsupported Windows that cannot be patched, or ICS-specific malware such as Stuxnet, Industroyer, TRITON, PIPEDREAM and FrostyGoop.
---

# OT/ICS security standards — industrial, with physical safety first

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, reviewing or operating the security of a system that **acts on the
physical world**: continuous or discrete process, energy, water, transport, buildings, healthcare,
manufacturing. Covers: the inversion of priorities compared with IT, the reference model (Purdue /
ISA-95) and its real use, **zones and conduits** from IEC 62443-3-2, security levels SL-T /
SL-C / SL-A, industrial DMZ and data diode, unauthenticated field protocols,
**passive** monitoring, vendor remote access, 20-year life cycles and assets
that cannot be patched, change management with the process running, and the regulatory framework
(NIS2, CRA, NERC CIP, IEC 62443 as the normative backbone).

Triggers: PLC, RTU, IED, HMI, DCS, SCADA, historian, SIS, `Modbus/TCP` (502), DNP3 /
IEEE 1815, IEC 60870-5-104, IEC 61850 (MMS/GOOSE/SV), EtherNet/IP and CIP, PROFINET, S7comm,
BACnet, OPC UA / OPC DA, ISA-95, "level 3.5", "data diode", "shutdown window",
"engineering workstation", "controller firmware", ANSI/ISA-62443, NIST SP 800-82r3,
IEC 62351, NERC CIP, ENS for critical operators.

**Strictly defensive posture.** Any active testing on real equipment requires scope
and authorisation **in writing**, a window agreed with operations and a shutdown plan; by
default you test on a bench/digital twin, not in the plant.

**Not applicable**: see `networking-standards` (network design, VLANs, routing, DNS — **the
topology and the addressing are theirs; which zone exists and which SL it demands, from here**),
`firewall-policy-standards` (**the rule as an artifact**: default-deny, flow matrix,
life cycle and rule approval — **here it is decided which conduit exists between zones and
which industrial protocol may cross it, there the rule is written and governed**),
`vpn-standards` (tunnel and concentrator as a service — **here the governance of vendor
access and the industrial broker/jump host**), `detection-engineering-standards` (**the detection
rule**; here only what OT telemetry exists and how to obtain it without touching the process),
`soc-operations-standards` (shift, queue and triage — **an IT SOC without escalation to operations is
useless for OT**), `incident-response-forensics-standards` (response and investigation; here
only why "power off and isolate" can be the worst move), `vulnerability-management-standards`
(CVSS/EPSS/KEV triage and SLA — **here why that SLA does not apply and what compensates for the patch
that will not be applied**), `endpoint-security-standards` (**sister skill**: EDR, application
control and IT endpoint encryption — **here the industrial endpoint that takes no agent
and why**), `grc-compliance-standards` (framework, SoA, risk acceptance),
`identity-access-management-standards` (IdP, MFA, account life cycle),
`windows-server-ad-standards` and `linux-hardening-standards` (the domain and the OS baseline
in the control centre), `routing-switching-standards` (switching, MLAG, 802.1X — **reciprocal
warning: the plant network is not a campus**, and its access defaults (`storm-control`,
`bpduguard`, 802.1X on every port, L3 to the access layer) break a PROFINET/MRP ring or leave
a PLC with no supplicant off the network. They are applied only with the criteria from here),
`embedded-iot-standards` (**the device as a product**: silicon, firmware and its update.
Damage boundary: if its failure injures someone or stops production, this skill wins),
`edge-computing-standards` (**the Linux node at the edge and its fleet**; here the constraints the
plant imposes on it, which are not negotiated from the IT side),
`safety-critical-standards` (**the certified safety function**: SIL/PL, IEC 61508 life cycle,
certification evidence. Here the security **of** the SIS as a network asset —isolate it, do not
reach it, do not patch it blindly—; **there what it guarantees and who signs it**),
`physical-security-standards` (physical access control and CCTV of the industrial site; **here what
happens once somebody is already standing in front of the cabinet**),
`chaos-engineering-standards` (**expressly cedes the physical process to this skill**: no fault
injection in the plant nor on a SIS; the legitimate equivalent is the bench or the twin),
`bcdr-standards` (BIA, RTO/RPO), `backup-recovery-standards` (copy and restore),
`onprem-standards` (physical platform), `offensive-security-standards` (authorised offensive
exercise; this skill does not run it), `threat-intelligence-standards` (indicator and actor),
`air-gapped-standards` (**arbitration, reciprocal from their §1**: the isolation **of the
physical process** —Purdue, level 3.5 DMZ, zones and conduits, diode— belongs here; **the isolated
enclave as a general mode of operation —data, servers, internal mirror, time and PKI with no egress— is
theirs**), `robotics-ros-standards` (**the industrial robot**: ROS 2, QoS and middleware, and the
machine safety of the arm are theirs; here the cell as a zone within the process).

## 2. Default decisions

> Verify on the web before pinning anything in a real project (§8). The editions of IEC 62443
> and the state of NIS2 transposition change; do not write them from memory.

| Decision | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Order of priorities | **Safety → Availability → Integrity → Confidentiality** | Per-zone adjustment documented in the risk analysis | Applying IT's CIA order as is |
| Technical framework | **ISA/IEC 62443** (zones, conduits, SL) | NIST SP 800-82r3 + its SP 800-53r5 *OT overlay* as a complement | A generic IT baseline as the only framework |
| Architecture | Segmentation by **zones and conduits** over the Purdue map | Microsegmentation when the asset does not fit a level | Flat plant network; "a firewall at the edge and that's it" |
| IT/OT boundary | **Industrial DMZ (level 3.5)** with no traffic crossing it end to end | Data diode / unidirectional gateway where the flow is outbound only | Direct level 2 ↔ level 4 connection; corporate historian querying the PLC |
| Discovery and inventory | **Passive** (TAP, or SPAN accepting loss) | Active query **only** with the vendor's protocol, prior bench testing and a window | `nmap`/vulnerability scanner against levels 0-2 |
| Vendor access | **Broker with jump host, MFA, recorded session, on demand and with approval** | Dedicated VPN to a specific zone, with an expiry | Permanent OEM tunnel, TeamViewer/AnyDesk on the HMI, "temporary" 4G modem |
| Protocol with security | **OPC UA** with `SignAndEncrypt` and `Aes256_Sha256_RsaPss` | `Aes128_Sha256_RsaOaep` or `Basic256Sha256` if the far end cannot manage it | `SecurityMode None`, anonymous, `Basic128Rsa15`/`Basic256` (obsolete, SHA-1) |
| Legacy protocol | **Compensate in the network** (zone, conduit, allowed function list) | DNP3 SAv5 (IEEE 1815-2012 cl. 7) or IEC 62351 where both ends support it | Assuming Modbus/TCP "is authenticated" because there is a VPN |
| Controller patching | **Planned shutdown window**, after bench validation and with rollback | Compensation (segmentation, monitoring, write control) if there is no window | Patching a PLC in production "because the CVE is 9.8" |
| Crypto on the link | TLS 1.2+/1.3 where the equipment really supports it | External tunnel (gateway, IPsec) if the equipment cannot | Vendor-proprietary crypto with no documentation and no audit |

## 3. The inversion of priorities, and why the patch can be the bigger risk

- In IT the worst case is a data breach. In OT the worst case is **a dead person or the
  process out of control**. Everything else in this document derives from that sentence.
- **The safety instrumented system (SIS) is its own zone, isolated and with no route from
  the DCS.** TRITON/TRISIS (2017, Schneider Triconex) is the precedent: malware written to
  manipulate the last barrier before the accident.
- **Availability is not an SLA, it is physics.** A PLC restart is not "a minute of
  downtime": it is a process stop with a start-up of hours, product lost and, depending on the
  process, risk to people.
- **That is why the patch can be the bigger risk.** New firmware implies a restart,
  functional revalidation and —in pharma, nuclear or aviation— recertification. The correct
  decision is often **not to patch and to compensate**, but it is documented as a formal risk
  acceptance (`grc-compliance-standards`), never by omission.
- Triage: CVSS 9.8 on a PLC does **not** mean "patch within 15 days". Ask first whether the
  asset is reachable from a less trusted zone; if it is not, the finding is architecture work,
  not maintenance work.
- **Active scanning knocks controllers over.** They handle one thing at a time, with a minimal
  TCP/IP stack and fragile embedded HTTP servers; a scanner probing TLS conditions
  restarts them. CISA documented in AA22-103A adversary *packet of death* capabilities that
  leave the PLC inoperative until a power cycle and configuration recovery — an
  unauthorised sweep approaches the same result **by accident**. Rule: **levels
  0-2 are a no-scan zone by default**; authenticated scanning is reserved for 3.5 and above.

## 4. Purdue, zones and conduits

- **Purdue (derived from PERA/ISA-95) is still valid as vocabulary, not as a blueprint.** "Level
  1", "level 3.5" are common language between plants and vendors, and that is worth having. What no
  longer holds is the strict hierarchy: IIoT, cloud telemetry and remote operation create
  routes from level 0/1 to level 4-5 that the diagram does not show. Correct use: **Purdue as a
  high-level map, IEC 62443-3-2 (zones and conduits) as the segmentation that is implemented and
  audited**. Every route that skips levels is documented as an explicit conduit with its SL, or
  it does not exist.
- IEC 62443-3-2 workflow (**ZCR 1-7**): identify the system under consideration (SuC) →
  initial risk assessment → partition into zones and conduits → compare against the
  tolerable risk → detailed assessment → document requirements, assumptions and constraints →
  asset owner approval. **ZCR 3.2** requires separating IACS assets from
  business assets; **ZCR 3.6** recommends grouping into their own zone the devices that come in over an
  external network (remote access does **not** live inside the SuC); **ZCR 5.6** requires assigning an SL
  to each zone and conduit.
- **Industrial DMZ (3.5)**: the replica historian, the patch server, the antivirus
  repository and the remote access broker live there. No flow crosses it end to
  end: each side terminates in the DMZ and the other side initiates its own.
- **Data diode / unidirectional gateway** when the real requirement is "get data out without
  letting anything in". It is hardware, not a firewall rule — and that is its value: it admits
  no exception through a misconfiguration. Cost: any future write inbound requires
  a redesign.
- The engineering workstations (EWS) are **the most dangerous asset in the plant**: they hold the
  software that programs the controller and the project files. Their own zone, without
  browsing or email, without USB, with application control.

## 5. IEC 62443: the normative backbone (quotes)

- Reference parts: **62443-2-1** (asset owner's security programme;
  **edition 2.0 of 2024**, replacing the 2010 one, restructured into programme elements
  —SPE— with a maturity model), **62443-3-2** (risk assessment, zones and conduits),
  **62443-3-3** (technical system requirements, SR and RE), **62443-4-1** (the vendor's secure
  development process) and **62443-4-2** (component requirements, CR).
  Verify the current edition of each part before citing it (§8).
- **Seven foundational requirements (FR)**, defined in IEC 62443-1-1 and the structure of 3-3 and
  4-2: **FR 1 – Identification and authentication control**, **FR 2 – Use control**,
  **FR 3 – System integrity**, **FR 4 – Data confidentiality**, **FR 5 – Restricted data
  flow**, **FR 6 – Timely response to events**, **FR 7 – Resource availability**.
- **Security levels (verbatim, IEC 62443-3-3):**
  - **SL 1**: *"Protection against casual or coincidental violation."*
  - **SL 2**: *"Protection against intentional violation using simple means with low
    resources, generic skills and low motivation."*
  - **SL 3**: *"Protection against intentional violation using sophisticated means with
    moderate resources, IACS specific skills and moderate motivation."*
  - **SL 4**: *"Protection against intentional violation using sophisticated means with
    extended resources, IACS specific skills and high motivation."*
- The SL **is not a global number**: it is a **seven-element vector**, one per FR (Annex A
  of 62443-3-3). A zone may demand SL 3 on FR 1-3 and FR 7 and SL 1 on FR 4 (confidentiality)
  — e.g. `SL = (3,3,3,1,2,1,3)`. Anyone selling you "we are SL 2" with no vector and no scope is
  selling marketing.
- Always distinguish **SL-T** (target, comes out of the risk analysis and is a design
  requirement), **SL-C** (capability the product or system can support; declared by the
  vendor against 62443-4-2) and **SL-A** (achieved, what is really there). The audit
  compares **SL-A against SL-T**; SL-C proves nothing on its own.
- Tension to be resolved explicitly: 62443-1-1 assigns the target by likelihood and
  consequence, 3-3 describes the levels by **adversary capability**. Document the
  translation; if you do not, the SL-T ends up being set by the vendor.
- **NIST SP 800-82 Rev. 3** (Sep-2023, current; a planning note from Jul-2024 anticipates
  errata) is the complement: extension from ICS to OT, adaptation of SP 800-53r5 controls
  and an **OT overlay** with low/moderate/high impact baselines. Check for errata or a revision (§8).
- **Minimum operational framework**: the *Five ICS Cybersecurity Critical Controls* (SANS, Lee
  and Conway) — an ICS-specific incident response plan, a defensible architecture,
  network visibility and monitoring, secure remote access and risk-based vulnerability
  management. They map onto 62443 and are the short list when there is no programme.

## 6. Protocols, monitoring and remote access

- **Unauthenticated by design, not by oversight**: Modbus/TCP (502) has no TLS, no
  authentication header, and no concept of a user — the MBAP *unit identifier* is a routing
  field, not an identity. Same for base DNP3, IEC 60870-5-104, EtherNet/IP–CIP, PROFINET,
  S7comm and BACnet: the original model assumed **the network was the security boundary**, and
  that premise is dead. Consequence: **whoever reaches the port is in control**, and the
  compensating control is architectural, not protocol-level.
- Extensions that do exist: **DNP3 Secure Authentication v5** (IEEE 1815-2012, clause 7,
  based on IEC/TS 62351-5): challenge-response with a symmetric key, authenticity and integrity and
  anti-replay, **without confidentiality**; the acknowledged gap is **key management**, which
  the standard largely leaves unspecified and each vendor solves its own way —
  verify how keys are provisioned and rotated before taking it as secure. **IEC 62351** secures the
  TC57 family (part 3 = TLS over TCP/IP; part 5 = DNP3/60870-5). Verify editions (§8).
- **OPC UA is the exception**: security in the protocol itself. Demand `SignAndEncrypt`,
  policy **`Aes256_Sha256_RsaPss`** (preferred), `Aes128_Sha256_RsaOaep` or
  `Basic256Sha256` as a fallback, and a named user instead of anonymous. **Forbidden**:
  `Basic128Rsa15` and `Basic256`: obsolete since specification 1.04 because of SHA-1, they must come
  disabled by default (open62541 removed them from the code as of 1.4.6). Common trap:
  the **user token** policy is independent of the channel's — a strong channel with
  the user encrypted under `Basic256` is not a secure configuration. Certificate trust list
  **managed**, not "accept the first one that arrives".
- **Passive monitoring by default**: TAP (physical copy, independent of the switch's
  load) before SPAN (mirror: adds load and drops packets at peak). It gives you inventory,
  a process baseline and behavioural detection — a station that only used to read and suddenly
  **writes** to the PLC, a mode change, a logic download outside the window.
  Honest limit: **it does not confirm whether a patch is applied**, it does not see powered-off or
  silent assets and it generates far more volume than a scan; it is compensated with documentary
  vendor inventory and active queries **over the native protocol**, tested on a bench.
- **Vendor remote access is the main vector.** It must be: on demand (not
  permanent), approved by operations, against a **broker/jump host in the industrial DMZ**,
  with MFA, with the session recorded, limited to the zone and the asset in the contract, and **cuttable
  from the plant with a physical or policy switch**. An OEM with a permanent tunnel is a
  domain administrator account you do not manage.
- Incidents as an argument (verified, no cookbook): **Stuxnet** (logic manipulated in
  the controller and the operator's view falsified); **Industroyer/CrashOverride** (2016) and
  **Industroyer2** (2022), with electrical protocols implemented natively;
  **TRITON/TRISIS** (2017) against the SIS; **PIPEDREAM/INCONTROLLER** (2022), a modular
  *toolkit*; **FrostyGoop** (Dragos, discovered Apr-2024; Golang, Modbus/TCP 502, writes
  *holding registers*) — in the attack on a municipal heating company in **Lviv on
  22-23 January 2024** they got in through an **exposed MikroTik router**, downgraded the
  firmware of the ENCO controllers from versions 51/52 to **50** (loss of
  visibility) and left **more than 600 apartment blocks** without heating for almost two days below zero.
  **Mandatory nuance: Dragos assesses that FrostyGoop was *likely* the one used, it does not take it
  as proven**, and it does not attribute it to a group. The structural failure: router,
  management servers and controllers **unsegmented**. Dragos also reported ~46,000 ICS devices
  exposed to the internet speaking Modbus.
- The repeated lesson is not the malware: **96 % of OT incidents originate in a
  compromise of the IT network** (Dragos, 2025 — verify the figure and the report year, §8). The
  IT/OT boundary is where it is won or lost.

## 7. Life cycle, sustainability and prohibitions

- **A 20-30 year horizon**: the asset outlives several generations of IT, the software
  vendor and, frequently, the engineer who installed it. Design assuming that **the equipment
  will not be upgradable** and that the compensating control will have to last decades.
- Out-of-support Windows on HMIs and EWS is the norm, not the exception: it is usually tied to
  process validation or to a driver that does not exist for anything modern. Treatment: its own
  zone, no internet egress, no email, application control in allowlist mode,
  removable media blocked, and a **replacement date in the investment plan** — not a
  perpetual "pending item". Extended support contract if the vendor offers one; if not, the
  risk acceptance is signed by whoever pays for it.
- **Tested backup and restore of what is in no IT backup**: PLC projects,
  logic, HMI configuration, recipes, drive parameters and **the exact firmware
  in use**. A server restore does not bring a plant back into production. Custody of the
  integrator's code with an *escrow* clause in the contract.
- Regulation: **NIS2** (EU Directive 2022/2555) applies to essential and important entities,
  with duties on risk management, supply chain and notification. **In Spain the
  transposition was still not closed in 2026**: the draft Cybersecurity Coordination and Governance
  Bill approved in the Council of Ministers on **14-Jan-2025** and still in
  process; a reasoned opinion from the Commission on **7-May-2025** and a second demand on
  **19-May-2026** (file INFR(2024)0270). **Verify whether it has already been published in the BOE before
  citing deadlines (§8)** — the substantive obligations come from the directive and do not wait for the
  law. Add the **CRA** (EU Regulation 2024/2847) for the product you buy: IEC 62443-4-1/4-2
  are on their way to being harmonised (CENELEC TC65X WG3) but **as of August 2026 they are not harmonised
  standards yet** — do not promise presumption of conformity. And **NERC CIP** if you operate in
  the North American electricity system.
- Cadence: review of zones and conduits on **every process change**; review of
  inventory and of conduit rules at least annually; OT response exercise (with
  operations and with the vendor in the room) at least annually.

**FORBIDDEN**
- ❌ Actively scanning levels 0-2 (`nmap`, vulnerability scanner, probing agent)
  without prior bench testing, a window and written authorisation.
- ❌ Installing IT agents (EDR, inventory, patch management) on a controller, on an
  operator panel or on any equipment whose functional validation prevents it.
- ❌ Permanent vendor tunnel, third-party remote desktop on the HMI, 4G modem/router
  hanging off the cabinet "for maintenance".
- ❌ Applying the IT patching SLA to OT assets, or patching a controller in production.
- ❌ A direct route between level 4/5 and levels 0-2; corporate historian querying the PLC.
- ❌ SIS in the same zone as the DCS, or reachable from it.
- ❌ OPC UA with `SecurityMode None`, an anonymous user or `Basic128Rsa15`/`Basic256` policies.
- ❌ Assuming an industrial protocol authenticates anything because it runs over a VPN or a VLAN.
- ❌ Shared plant credentials, generic vendor accounts, passwords in the
  PLC project or stuck on the cabinet.
- ❌ Uncontrolled USB between the EWS and anything; the integrator's laptop plugged straight
  into the process network.
- ❌ **Publishing vendor default credentials, ready-made payloads or specific product
  bypasses.** This skill is methodology and governance, not an offensive cookbook; the offensive
  exercise goes with written scope and authorisation (`offensive-security-standards`).
- ❌ Declaring "we comply with 62443 SL 2" with no per-FR vector, no scope and without distinguishing
  SL-T/SL-C/SL-A.

## 8. Mandatory web verification

Before pinning a standard, edition, figure or date in a deliverable:

1. **Current edition of each IEC 62443 part** you cite (2-1, 3-2, 3-3, 4-1, 4-2) and its
   national adoption (ANSI/ISA, EN IEC); SL and FR quotes are required **verbatim**.
2. **NIST SP 800-82**: current revision (Rev. 3 as of August 2026) and whether errata have been published.
3. **NIS2 in Spain**: whether the Cybersecurity Coordination and Governance Act has been published
   in the BOE, registration and notification deadlines, and the status of file INFR(2024)0270.
4. **CRA (EU 2024/2847)**: dates of application and whether EN IEC 62443-4-1/4-2 already appear as
   harmonised standards.
5. **Vendor and CISA ICS advisories** for the specific models in the plant, and their
   life cycle and end of support.
6. **OPC UA status**: current and obsolete security policies at
   `profiles.opcfoundation.org`, and what the installed firmware version really supports.
7. **Annual OT threat reports** (Dragos, Claroty, Waterfall) to refresh figures;
   **cite the year and the report or do not use the figure**.

**Declared gap**: the SL 1-4 quotes and the seven FRs have been checked against consistent
secondary sources, not against the paid IEC 62443-3-3 PDF; **verify against the
official text before using them in a contractual or audit document.**

If the web contradicts this document, **the web wins** — flag the discrepancy.
