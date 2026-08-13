---
name: network-vendors-standards
description: What actually changes when the box has a different logo — vendor operating models, licensing, lifecycle and vendor risk. Use when working with Cisco IOS / IOS-XE / NX-OS / IOS-XR and deciding which one a platform runs, Cisco EEM applets and event manager, Smart Licensing Using Policy (SLP), SLAC authorization codes, CSSM, CSLU, "license smart url", "show license all", Catalyst Center (formerly DNA Center), Junos OS and its candidate configuration, "commit check", "commit confirmed", "rollback 3", "show | compare", "load replace", apply-groups and apply-path, Junos Evolved, Arista EOS, SysDB and NetDB, CloudVision / CVaaS / CVP and ZTP as a service, EOS extensions and "config session", MikroTik RouterOS 7 and Winbox, RouterOS package channels and "/system package update", Huawei VRP and its regulatory status as a high-risk supplier, Nokia SR Linux or SR OS, FortiOS or PAN-OS acting as a WAN router rather than a firewall, choosing single-vendor versus multivendor and pricing the lock-in, TAC and RMA contract coverage, PSIRT and security advisory subscription as a process, EoS/EoL and last-date-of-support milestones, or a vendor acquisition that changes the roadmap under you.
---

# Network vendor standards — the lock-in is in the operating model, not the CLI

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **the decision depends on who makes the box**: which network operating system each
platform runs and what that implies; the vendor's configuration model (transactional versus
immediate) and what safe operation it allows; **licensing** and what stops working when it
expires; the firmware lifecycle and the EoS/EoL milestones; consuming **PSIRT** advisories as a
process, not as occasional reading; support, TAC and RMA contracts and what they really cover;
**vendor risk** (acquisitions, regulatory restrictions, product-line discontinuation); and the
criteria for **standardising on one vendor versus multivendor**, with the real cost of each option.

Triggers: `IOS-XE`, `NX-OS`, `IOS-XR`, `Junos`, `Junos Evolved`, `EOS`, `RouterOS`, `VRP`,
`SR Linux`, `SR OS`, `FortiOS`, `PAN-OS`; `event manager applet`, `commit confirmed`,
`commit check`, `rollback`, `apply-groups`, `config session`, `show license all`,
`license smart url`, SLAC, CSSM, CSLU, Catalyst Center, CloudVision/CVaaS, Winbox, ZTP;
"EoS", "LDoS", "PSIRT", "TAC", "RMA", "licence renewal", "vendor change".

**Not applicable**: the catalogue already splits this up: `networking-standards` is the **trunk**
(addressing, VLAN, MTU, OOB plane, choice of edge platform) and **already delegates the
depth**; `routing-switching-standards` decides **what the campus and edge configuration must say**
(STP, MLAG, VRRP, BGP policy, RPKI, CoPP, AAA — here only **what that translates into** on each
OS); `datacenter-fabric-standards` decides the fabric (Clos, VXLAN/EVPN);
`network-automation-standards` decides **how a change is generated, tested and applied** (Ansible,
NAPALM, NETCONF/YANG, gNMI, containerlab, drift detection — here only **what each vendor exposes**
and with what fidelity); `firewall-policy-standards` (filtering policy as an artifact, including
FortiOS/PAN-OS **as a firewall**); `wireless-standards` (WLAN and controllers);
`load-balancing-standards`, `vpn-standards`, `dns-standards`, `network-troubleshooting-standards`
(reactive method). Outward: `vulnerability-management-standards` (**triage and patching SLA**;
here only the **subscription and consumption** of the PSIRT feed), `wan-legacy-standards` (MPLS,
SD-WAN and legacy circuits), `telco-5g-standards` (carrier equipment),
`high-speed-interconnect-standards` (InfiniBand/RoCE), `edge-computing-standards`,
`finops-standards` (multi-year cost model),
`opensource-licensing-standards` (free software licences — **network licensing is
contractual, not OSS**), `grc-compliance-standards` (vendor due diligence as a control),
`offensive-security-standards` (**this skill is defensive**).

## 2. Default decisions

> Verify the latest version, the EoS/EoL status and the exact name of each product on the web before
> pinning it in a real project (§8). **Commercial names change without the product changing**:
> Cisco renamed DNA Center to **Catalyst Center** and Viptela SD-WAN to **Catalyst SD-WAN** in 2023;
> the old documentation still uses the old names.

| Decision | Default | Justifiable alternative |
|---|---|---|
| Primary selection criterion | **Operating model** (transactionality, API, telemetry, lifecycle) | Purchase price, only if the 5-year TCO backs it |
| No. of vendors in the core | **One**, unless explicitly justified | Two, if vendor risk demands it (§7) |
| No. of vendors per domain (campus / DC / WAN) | One per domain, with a **clear boundary** at the interconnect | Multivendor within a domain: **almost never worth it** |
| Change interface | **NETCONF/YANG or gNMI** if the vendor supports it well | Structured CLI (`| display xml`, `| json`) — *screen scraping* only as a last resort |
| Rollback window | **Confirmed commit with a timer** whenever the OS offers it | Out of band + scheduled reload if it does not |
| Firmware cadence | The vendor's **extended-support/long-lived** release, not the latest | A new release only if it fixes an exploited CVE or a contracted feature |
| PSIRT subscription | **Mandatory** for every vendor in production, with a named owner | — |

### What each operating system is (and where it lives)

- **Cisco IOS / IOS-XE** — the campus and branch lineage. IOS-XE is classic IOS repackaged on top of
  a Linux kernel with plane separation: it supports `guestshell`, application containers, YANG and
  telemetry. Catalyst 9000, ISR/ASR 1000 and Catalyst 8000 run IOS-XE.
- **Cisco NX-OS** — the data centre line (Nexus). Modular model with restartable processes,
  `feature <x>` to enable functions, and VDC/VRF. It shares no commands with IOS-XE beyond
  appearance; **assuming it does is the classic mistake**.
- **Cisco IOS-XR** — the service provider and core line (ASR 9000, NCS). **It is the only one of the
  three with a genuinely transactional configuration model**: `commit`, `commit confirmed`, `show
  configuration commit changes`, `rollback configuration`. If the team comes from IOS-XE, the mental
  model changes completely.
- **Junos OS / Junos Evolved** — a single OS across the whole range, with the best configuration
  model in the industry (see below). Evolved is the rewrite on native Linux; **the CLI looks similar
  but feature parity is not total**: verify per platform.
- **Arista EOS** — a single binary for the whole range, on standard Linux, with **SysDB** as the
  in-memory state database and publish/subscribe between agents. The practical consequence: an
  agent that dies restarts and **re-reads its state from SysDB** without taking down the rest of the
  system. CVP / CVaaS aggregates the SysDB of the whole network (NetDB/NetDL).
- **MikroTik RouterOS 7** — Linux with a proprietary layer on top. Unbeatable cost per feature;
  operating model and security posture **far below** the rest (§5).
- **Huawei VRP** — proprietary OS, functionally competent and cheap. The problem is not technical:
  it is **regulatory and about continuity** (§5).
- **Nokia SR Linux / SR OS**, **FortiOS**, **PAN-OS** — SR Linux stands out for its open model
  (first-class gNMI/YANG). FortiOS and PAN-OS **act as routers** in branches; here only that,
  their filtering policy belongs to `firewall-policy-standards`.

## 3. Structure and conventions

### The configuration model is what decides operability

Junos's **candidate config + confirmed commit** is the best idea the networking industry has
produced, and the reason is concrete: **it decouples writing from applying, and applying from confirming**.

- You edit a **candidate configuration** that does not affect the device. Syntax and semantic errors
  are caught before touching anything (`commit check`).
- `show | compare` gives the **exact diff** of what is going to change. There is no need to guess
  the resulting state.
- `commit confirmed` applies and arms a timer; if it is not confirmed with a second `commit`, the
  device **rolls back on its own**. **The default is 10 minutes, configurable from 1 to 65,535**
  (Juniper, *Commit the Configuration*, CLI User Guide). This eliminates the entire class of
  "I locked myself out" incidents.
- **Numbered rollback**: `rollback 0..49` recovers complete previous configurations, and
  `rollback rescue` one marked as good. It is not an external backup: it lives on the device.
- **Apply Groups** (`groups` + `apply-groups`, with `apply-path` to derive lists from another part
  of the config) apply common configuration by inheritance. They reduce repetition, but **they
  obscure the effective configuration**: always review with `show configuration | display inheritance`.

Translation to the others:

| Capability | Junos | IOS-XR | EOS | NX-OS / IOS-XE | RouterOS |
|---|---|---|---|---|---|
| Candidate config | Yes, native | Yes, native | `configure session` | Partial (`config replace`, `configure exclusive`) | No |
| Diff before applying | `show \| compare` | `show configuration` | `show session-config diffs` | `show archive config differences` | No |
| Confirmed commit | Yes (10 min default) | Yes | `commit timer` in session | `configure replace` + `reload in` as a substitute | No |
| Numbered rollback | 0–49 + `rescue` | Yes | Session snapshots | `archive` with files | Manual backups |

**Criteria**: on a device without confirmed commit, **every risky remote change carries a `reload
in <n>` armed before touching anything**, cancelled once verified. It is not optional.

### On-box automation: useful, and a maintenance trap

- Cisco **EEM** (`event manager applet`, with `event syslog`, `event timer`, `event none`, and
  `cli`, `syslog`, `mail` actions) allows reacting to events on the device itself. It is
  legitimate for **immediate containment** (shutting down a flapping port) and for bounded
  *self-healing*.
- ❌ **FORBIDDEN** to use EEM (or equivalent on-box scripts: Junos `op`/`event-options`, EOS
  extensions, RouterOS scheduler) as a **substitute for external automation**. An applet on 300
  devices is logic with no version control, no tests and no inventory. Every on-box script has an
  owner, is generated from the template and is audited as configuration.

### What can really be automated, by vendor

The real axis is not "does it have NETCONF?" but **does the YANG model cover what I need to
configure, and can operational state be read without parsing text?**

- **Model coverage**: OpenConfig is the promise; the reality is that almost everything interesting
  ends up in the vendor's **native** models. Verify case by case which subtree is supported.
- **Operational state**: gNMI `Subscribe` (streaming telemetry) replaces SNMP; check which *paths*
  the device emits and at what cadence. Without this there is no decent network observability.
- **`commit` fidelity**: NETCONF with `confirmed-commit` (RFC 6241) is only worth it if the device
  really implements it; many advertise NETCONF and underneath do CLI.
- ❌ **FORBIDDEN** to base an automation plan on CLI **screen scraping** as the target strategy.
  It is acceptable as a bridge for legacy equipment, with a written life expectancy and exit date;
  never as a design.

## 4. Quality and verification

- **Before buying**: demand from the vendor, in writing, (a) the YANG/gNMI support matrix for the
  exact platform, (b) the EoS/LDoS date of the model, (c) the commitment to the lifetime of the
  firmware branch, and (d) the RMA SLA in the real geography of the installation. **Without all
  four there is no decision, there is a bet.**
- **Acid test before standardising**: reproduce the most dangerous change that will be made in
  production (edge policy change, firmware upgrade with a reboot) in a virtual lab from the vendor
  itself, measuring the real rollback time. If the vendor does not offer a usable virtual image,
  **that is already a data point for the decision**.
- **Configuration validation**: `commit check` (Junos), `configure session` + `show session-config
  diffs` (EOS); an `nft` equivalent does not exist here — the gate belongs to the vendor. Independent
  verification (Batfish, pyATS/Genie) and pipeline tests belong to `network-automation`.
- **Firmware inventory as queryable data**: model, version, EoS date and date of the last applied
  PSIRT advisory, in the source of truth. An estate without this inventory **cannot respond** to a
  critical advisory within the deadline `vulnerability-management-standards` requires.

## 5. Security and vendor risk

### PSIRT as a process, not as news

- Subscribe to the official channels of **all** vendors in production and **route them to a queue
  with an owner**: Cisco Security Advisories (openVuln API), Juniper JSA, Arista Security
  Advisories, Fortinet PSIRT, Palo Alto Security Advisories, MikroTik `mikrotik.com/supportsec`.
- The trigger for action is not publication: it is **triage** (is the platform affected? is the
  vulnerable feature enabled? is it exposed?). The SLA and prioritisation (CVSS + EPSS + KEV)
  belong to `vulnerability-management-standards`; **the commitment here is that the advisory
  arrives and has an owner**.
- ❌ **FORBIDDEN** to operate a network device whose firmware branch no longer receives security
  fixes and that is exposed to an untrusted network. If it cannot be updated, it is isolated.

### MikroTik: the best price on the market and the worst exposure

RouterOS offers high-end features at low-end prices, and that makes it the most widely deployed
device by people with no network operation behind them. The result is measurable:

- CISA has issued ICS advisories about RouterOS and Cloud Hosted Router in 2026 — among others
  **ICSA-26-211-01 (CVE-2026-14227**, insufficient session expiration in the API, with extraction of
  the WireGuard private key from a low-privilege session) and **ICSA-26-209-05
  (CVE-2026-16347**, absence of brute-force protection in API authentication).
  **Verify the patch status on the web (§8): when this data was collected no patch was on record.**
  The API listens on TCP 8728/8729.
- The historical pattern is constant and is not about CVEs: **management interface exposed to the Internet**.
  The botnet campaigns against MikroTik (Mēris and successors) have reused devices compromised
  years earlier, where **updating was not enough** because the credentials were already stolen and
  the attacker's scripts and rules remained on the device.
- **Operational criteria**: if MikroTik is used, (a) management **only** over OOB or VPN, never exposed;
  (b) Winbox/API/SSH/WWW restricted by `address-list`; (c) after any suspicion of
  compromise, **clean reinstall and credential rotation**, not an update; (d) explicit review
  of `/system scheduler`, `/system script`, users and unrecognised NAT/firewall rules.
- ❌ **FORBIDDEN** to deploy MikroTik at a critical edge without an assigned operational owner. The
  purchase saving is eaten by the first incident.

### Huawei: the risk is not technical

- The EU had had the **5G Toolbox** since 2020 as a **non-binding** recommendation, applied
  unevenly: **fewer than half of the 27 Member States** had used legal powers to
  impose restrictions. The cybersecurity package presented by the Commission on **20 January
  2026** proposes turning those measures into **mandatory** ones, with a phased removal of equipment
  from high-risk vendors and an extension of scope beyond 5G (fibre included).
  **It is a legislative proposal, not applicable law yet**: the adoption and
  transposition deadlines are the data point to verify (§8), and **they vary by country**.
- **Criteria**: for infrastructure with a 7–10 year service life, the question is not whether Huawei
  works (it does), but **whether the regulatory framework of the country of deployment will let it be amortised**.
  A removal mandate turns a cheap purchase into an unbudgeted migration.
- This same reasoning applies to **any** vendor subject to export control or to a
  sectoral restriction. It is risk analysis, not geopolitics.

### Acquisitions: the roadmap changes under your feet

- **HPE closed the acquisition of Juniper Networks on 2 July 2025**, for some USD 13.4 billion; JNPR
  stopped trading. The DOJ imposed conditions (divestiture of Instant On and auction of a
  non-exclusive licence to the Mist AI source code). Juniper operates as a subsidiary and its
  ex-CEO runs HPE's networking division, which keeps both brands.
- **What it means for a purchase decision**: Junos as an OS is not evaporating, but **the lines
  overlapping with Aruba are the natural candidates for rationalisation**. Before standardising on a
  specific range, demand in writing the roadmap commitment and the EoS dates of **that** model.
  Verify the current status on the web (§8): post-merger portfolio decisions are announced
  in dribs and drabs.
- The general clause: **every standardisation on a vendor must have written down what is done if the
  vendor is acquired, discontinues the line or becomes restricted**. Without that paragraph,
  standardisation is an uncovered bet.

### Licensing: what stops working when it expires

- **Cisco Smart Licensing Using Policy (SLP)** is **mandatory from IOS-XE 17.3.2** (Smart
  Licensing was mandatory from 16.10.1a to 17.3.1, and optional between 16.5.1 and 16.9.8). SLP
  removed the PAK and prior registration: **no registration or key generation is required except
  for *export-controlled* or *enforced* licences**. Transports: `smart` (HTTP direct to Cisco),
  `cslu` (mediated by on-premise CSLU) and offline for isolated networks; `call-home` is being
  retired and must not be used on new versions. For controlled licences or throughput >250 Mbps you
  need to install a **SLAC**.
- **Operational consequence** that is ignored until it hurts: an isolated network needs a licence
  usage reporting plan (CSLU or offline file) **from day one**. Verify `show license
  all` / `show license status` as part of the inventory, not when the warning fires.
- **Cross-cutting rule**: before buying, demand in writing **which functions degrade or are
  blocked** when the licence expires or connectivity to the licence server is lost, and **how
  a device that reboots without being able to validate behaves**. It is the difference between a
  log warning and a branch office down.
- ❌ **FORBIDDEN** to size a network budget counting only the hardware CAPEX. The
  multi-year subscription, support and renewal are part of the price (`finops-standards`).

## 6. Operability — support, RMA and lifecycle

- **The milestones that matter** (exact names vary by vendor; verify §8): end-of-sale
  announcement (EoS), last order date, end of software maintenance, end of vulnerability
  support and **last date of support (LDoS)**. The only one that decides is the **end of
  security fixes**: from then on the device is debt with a date.
- **Support contract**: verify the actual level contracted (response time ≠ replacement
  time), the geographic coverage of the RMA stock and whether it includes access to software downloads.
  **With several vendors, without a valid contract you cannot even download the security patch** —
  that turns renewal into a security control, not an administrative expense.
- **Spares**: for edge devices without 4h RMA at the real location, a cold spare on site
  is usually cheaper than raising the contract level. Decide it with the RTO, not with the catalogue.
- **Second-hand / grey equipment**: legitimate for lab and cold spare. ❌ FORBIDDEN in
  critical production: no support coverage, no guarantee of firmware provenance and with
  supply chain risk.

### Standardising on one vendor versus multivendor — the real cost

| Axis | One vendor | Multivendor |
|---|---|---|
| Operating cost | **Lower**: one learning curve, one commit model, one pipeline | Higher: each OS is a set of templates, tests and failure modes |
| Negotiating power | Degrades over time; the vendor knows it | **Better**, if credible (you have to be able to actually switch) |
| Correlated failure risk | **High**: one critical CVE affects the whole estate at once | Lower, at the cost of more total surface |
| Vendor risk (acquisition, EoL, regulation) | Concentrated | Diversified |
| Automation | Simple and high fidelity | Requires real abstraction (NetBox + per-platform templates), not an `if vendor ==` |

**Default criteria**: **one vendor per domain** (campus, DC, WAN), with standard protocol
boundaries at the interconnect. Multivendor *within* a domain is only justified if the second
vendor is **genuinely operated** — not bought "just in case". A secondary vendor that nobody knows
how to configure does not diversify risk: it increases it.

**Real vendor lock-in is not in the CLI.** Changing syntax is a week's work. What
ties you down is everything else: the source of truth modelled after the vendor's data model, the
templates, the management platform (Catalyst Center, CVP, Mist, Apstra) with its inventory and its
workflows, the team's operational knowledge, the multi-year contracts and the proprietary features
with no standard equivalent. **Every decision to buy the vendor's management platform must be
evaluated as a lock-in decision**, not as a hardware accessory.

## 7. Long-term sustainability and prohibitions

- Refresh the EoS/LDoS inventory **every quarter** and budget for replacement **two
  years in advance** of the end of security fixes. Discovering it in the same year is how you
  end up patching by exception.
- Freeze the firmware branch per domain and update on a planned window, not per device.
  Leave that cadence only for an exploited CVE or a contractual requirement.
- Document in an ADR (`software-architecture-patterns-standards`) the vendor decision with its
  date, the discarded alternative and **the condition that would reopen it** (acquisition, EoL of
  the range, regulatory change, price rise above a threshold).

Prohibitions:

- ❌ **FORBIDDEN** to write from memory a version, an EoS/LDoS date, a feature name, a
  licence level or a CVE identifier. It is verified on the vendor's website (§8).
- ❌ **FORBIDDEN** to apply a risky remote change without an armed rollback window (confirmed
  commit or `reload in`).
- ❌ **FORBIDDEN** to expose the management of a network device to the Internet (Winbox,
  administrative HTTP/HTTPS, API, SSH without source restriction). Management over OOB or VPN.
- ❌ **FORBIDDEN** to deploy with factory credentials, SNMP communities or certificates. And
  **forbidden to document third-party default credentials** in this catalogue: if they are needed,
  they are looked up in the vendor's documentation at deployment time and changed.
- ❌ **FORBIDDEN** to operate a vendor in production without a PSIRT subscription with a named owner.
- ❌ **FORBIDDEN** to treat CLI screen scraping as the target automation architecture.
- ❌ **FORBIDDEN** to deploy firmware downloaded from a source other than the vendor, or without
  verifying its published signature/hash.
- ❌ **FORBIDDEN** to standardise on a vendor without a written clause on what is done in the event
  of acquisition, discontinuation or regulatory restriction.
- ❌ **FORBIDDEN** to quote TCO figures, "automation savings" or market share coming
  from the vendor's commercial material without published methodology. If there is no methodology,
  you say there is none.

## 8. Mandatory web verification

**Always** check before deciding, in the primary source of the vendor or the regulator:

1. **Firmware version and branch** recommended for the exact platform (not the family), and whether
   it is an extended-support branch.
2. **Lifecycle milestones** of the specific model: EoS, end of software maintenance, **end of
   security fixes** and LDoS. Cisco EoL Notices, Juniper EOL, Arista lifecycle policy.
3. **Open PSIRT advisories** for the platform and the version, and whether a patch is available. In
   particular, **the patch status of the RouterOS advisories cited in §5 (CVE-2026-14227,
   CVE-2026-16347): when this document was compiled no vendor patch was on record.**
4. **Regulatory status of the vendor** in the country of deployment: the Commission proposal of
   **20 January 2026** making the 5G Toolbox binding, its legislative status, its removal
   deadlines and **the applicable national rule**, which differs by Member State.
5. **Status of the post-acquisition HPE–Juniper portfolio** (closing: 2 July 2025): which ranges are
   kept, which are rationalised and with what dates.
6. **Current licensing model and policy**: the version threshold where SLP is mandatory, what
   requires SLAC, which transports are still supported and **what degrades on expiry**.
7. **Real YANG/gNMI coverage** of the platform: matrix of supported models and published telemetry
   *paths*.
8. **Current commercial names** — they are renamed without warning (DNA Center → Catalyst Center;
   Viptela → Catalyst SD-WAN). Writing the old name means the documentation cannot be found.

**Declared gaps**: (a) the patch status of the July 2026 MikroTik advisories could not be
confirmed in a primary source — `cisa.gov` returned HTTP 403 when attempting the verbatim citation,
and the data comes from a search summary; **verify on `mikrotik.com/supportsec` before acting**. (b) The
adoption and transposition dates of the EU cybersecurity package were not verified in the
official text: the presentation date is known, not the calendar in force. (c) No EoS/LDoS matrices
of specific models were verified: they depend on the platform and are not written from memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
