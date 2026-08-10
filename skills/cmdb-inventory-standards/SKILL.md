---
name: cmdb-inventory-standards
description: Knowing what you actually own — asset inventory and CMDB as engineering artifacts, not audit paperwork. Use when choosing or operating NetBox (DCIM racks/devices/interfaces, IPAM prefixes/IP ranges, cables, virtual machines, custom fields, Diode ingestion, Orb discovery agent, NetBox Assurance drift), Nautobot, GLPI and the GLPI Agent, Snipe-IT, Ralph, i-doit, OCS Inventory or a ServiceNow CMDB aligned to CSDM, populating records by automated discovery (Nmap sweeps, LLDP/CDP neighbours, SNMP, osquery, cloud provider APIs, hypervisor and Kubernetes APIs, agent check-ins) versus manual entry, reconciling conflicting data from several sources and deciding which wins per attribute, picking a stable unique asset identifier that is not the hostname or the IP, modelling service dependency and CI relationships so an incident can answer "what breaks if this dies", tracking hardware and software asset lifecycle from purchase to disposal, finding the running server nobody can explain or switch off, stale record detection and inventory coverage metrics, software license entitlement and true-up audits, or asserting that Terraform state, a monitoring target list or a spreadsheet is the inventory.
---

# Inventory and CMDB standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **knowing what you have**: the asset data model, how it is populated (discovery versus
declaration), how contradictory sources are reconciled, which identifier keeps it stable over
time, which relationships are modelled so the data is useful during an incident, and the asset
lifecycle through to disposal. It covers both the **hardware/software inventory** (which machines and which
licences) and the **CMDB** (which configuration items exist and how they relate).

**The distinction that decides the whole design**: a **CMDB records intent** —what should exist,
with its owner, its criticality, its contract and its relationships— whereas a **discovered inventory
records reality** —what answers on the network today. **They are not the same database and they are not
populated the same way.** Merging them produces the classic failure: a hand-maintained CMDB that **is stale within
three months**, that nobody consults because they do not trust it, and that keeps being filled in only for the auditor. The
correct architecture is explicit: **discovery populates reality; intent is declared;
the difference between the two is a finding**, not a data error.

Triggers: "inventory", "CMDB", "CI", "asset", "what is this machine?", "can this be switched off?",
"what goes down if I switch this off?", NetBox (`dcim`, `ipam`, `tenancy`, `virtualization`, `custom_fields`,
Diode, Orb agent, Assurance), Nautobot, GLPI / `glpi-agent`, Snipe-IT, Ralph, i-doit, OCS Inventory,
`cmdb_ci`, CSDM, `osquery`/`osqueryd`, `lldpctl`, `snmpwalk`, an `nmap -sn` sweep,
`aws ec2 describe-instances` as an inventory source, serial number / DMI UUID, `dmidecode -s
system-serial-number`, "licence true-up", "orphaned asset", "the server nobody switches off".

**Not applicable**: see `itsm-itil-standards` (**hard, reciprocal boundary**: there the **CMDB as an ITIL
practice** —the process, who governs it, its relationship with change, incident and problem, and the criteria of
"if it does not answer questions people actually ask, it is not built"—; **here the data engineering**:
model, identifier, discovery, reconciliation, freshness metrics and automation. Arbitration
rule: *"which process maintains it and for which service decision?"* belongs there; *"where does
each attribute come from, who wins when two sources disagree and how do I know it is fresh?"* belongs here),
`iac-standards` (**Terraform/OpenTofu state is NOT a CMDB** — §3.5 —; there the code and its
state, here the inventory that consumes and cross-checks it; Ansible **reads** the inventory, it does not
replace it), `onprem-standards` (**umbrella**: its invariant *no host data from memory — you
query the inventory* is exactly what this skill makes possible; and its §1.2 should route
here), `os-provisioning-standards` (**automatic registration of the freshly installed host**: there the hook,
here the model it lands in), `server-hardware-standards` (warranty, contract, serial number and
lifecycle of the **iron**; here the record of all that and its expiry),
`networking-standards` (**the design** of addressing; **IPAM as a record** belongs here),
`network-automation-standards` (**the network as code**: if NetBox feeds configuration
templates, generating and deploying them is theirs), `vulnerability-management-standards` (**the
inventory is its precondition**: you cannot prioritise what you do not know exists),
`grc-compliance-standards` (the inventory as a **control** required by ISO 27001/ENS),
`bcdr-standards` (**the dependency graph for the recovery sequence** is theirs; here the
graph as maintained data), `opensource-licensing-standards` (licences **of dependencies** and SBOM;
here **purchased** licences versus what is installed), `finops-standards` (cloud cost and tagging),
`data-governance-quality-standards` (data quality as a general discipline),
`macos-fleet-standards` and `developer-workstation-standards` (**MDM is the inventory source for the
endpoint**), `datacenter-facilities-standards` (rack, power and physical
space — here only their representation in DCIM).

## 2. Default decisions

> Verify the latest version, licence and project status on the web before pinning it (§8).
> Licences checked by reading the raw file (§8 declares the gaps).

| Need | Default | Verified version / licence (Aug 2026) | Justifiable alternative |
|---|---|---|---|
| Source of truth for **network, IPAM and rack** | **NetBox** | v4.6.7 (30 Jul 2026); **Apache-2.0** (`LICENSE.txt` in raw) | **Nautobot** (v3.2.2, 3 Aug 2026; **Apache-2.0**) if you need *jobs* and automation-platform-style extensibility |
| Inventory of **IT assets and helpdesk** | **GLPI** + `glpi-agent` | **GPL-3.0** (`LICENSE` in raw) | **i-doit** if the relational CI model is the axis; **Ralph** (Apache-2.0) in large DC estates |
| Pure **asset management** (purchase, warranty, assignment to people) | **Snipe-IT** | **AGPL-3.0** (`LICENSE` in raw) | GLPI's asset module if you already have it: **one tool fewer is worth more than the perfect tool** |
| **Discovery on the host** | **osquery** | **Apache-2.0 OR GPL-2.0-only** (dual, declared in `LICENSE`) | The GLPI/OCS agent if it is already deployed |
| Corporate CMDB with an ITSM process on top | **ServiceNow aligned to CSDM** | **CSDM 5.0** (May 2025): 7 domains, *Foundation* first | Only if ServiceNow is already there. **CSDM is not bought: it is implemented by aligning data** |
| Discovery and drift detection on top of NetBox | **Orb agent** (open source, *public preview*) → **Diode** → **NetBox Assurance** | `network_discovery`, `device_discovery`, `snmp_discovery`, `gnmi_discovery` (beta) backends | Your own scripts against hypervisor/cloud APIs: perfectly valid and often sufficient |
| Source for cloud and virtualisation | **The provider's / hypervisor's API**, polled periodically | — | Never a hand-exported CSV |

**Selection rule that overrides the table**: choose **the tool you can populate
automatically next Monday**. A CMDB with the best data model and no discovery
loses to an ugly NetBox populated by API.

## 3. Data model: what decides whether it is useful

### 3.1 The stable identifier

**Neither the hostname nor the IP identifies an asset.** Both change, get reused and collide; an
inventory indexed by hostname produces duplicate assets and assets merged by mistake, which is
worse. Rule:

- **Physical hardware**: **manufacturer serial number** (and, if the model allows it, DMI UUID).
  It is the only identifier that survives a reinstall, a rename and a rack move, and
  the only one that matches the warranty and the support contract.
- **Virtual machine / instance**: the platform's **UUID or ID** (`instance-id`, `vm.uuid`).
- **The inventory's own identifier**: an immutable synthetic key of your own (never reused after
  decommissioning), because the serial of a chassis replaced under warranty **changes**.
- The hostname, the IP and the MAC are **attributes**, searchable and with history. Never primary keys.

### 3.2 Intent versus discovery, per attribute

Every attribute has **one** declared authoritative source, and the rest are observations. What
is discoverable is discovered; what no tool can know is declared and **expires**:

| Type of attribute | Authoritative source | Examples |
|---|---|---|
| Discoverable on the system | Agent / API | model, CPU, RAM, disks, OS and version, packages, services, IP in use, LLDP neighbours |
| Discoverable on the platform | Hypervisor/cloud/K8s API | state, physical host, network, tags, creation date |
| **Declarable only** | A person, with a **review date** | **owner**, business criticality, environment, contract and warranty, purpose, data classification, service it belongs to |

**The bottom row is the one that provides the value and the one that rots.** A declared attribute without a
review date is a false attribute of unknown age: give it an expiry (12 months at
most) and review it, or remove it from the model.

### 3.3 Reconciliation: who wins when two sources disagree

- **Precedence declared per attribute, not per global source.** The hypervisor wins on "how much RAM
  it has"; the agent wins on "which OS it runs"; the human wins on "who owns it". Written down, in the
  repository, not in the head of whoever built the integration.
- **Cascading matching**: serial → UUID → MAC → (last resort) hostname+domain. A
  match by hostname **is flagged as low confidence** and reviewed by hand.
- **A discrepancy is not resolved by overwriting the data: it is recorded.** A discovered machine that is
  not declared is *shadow IT* or an out-of-process deployment; a declared one that is not discovered
  is a dead asset or a coverage failure. **Both are findings with an owner and a deadline**, and that flow
  —not the report— is what keeps the database alive.
- **NetBox is deliberately intent**, and this is quoted verbatim from its documentation because it decides
  the architecture: *"NetBox intends to represent the desired state of a network versus its
  operational state"* and *"All data created in NetBox should first be vetted by a human to ensure its
  integrity"*. Its documentation explicitly excludes *"Network monitoring"*, *"DNS server"*,
  *"RADIUS server"*, *"Configuration management"* and *"Facilities management"*. Operational conclusion:
  **dumping raw discovery into NetBox breaks its model**; discovery comes in through an
  ingestion channel with review (Diode/Assurance or your own) and produces *diffs*, not writes.

### 3.4 Relationships: the only thing that makes a CMDB useful in an incident

A flat inventory of 4,000 rows does not answer the one question asked in the small hours: **"if this
goes down, what stops working, and who do I notify?"**. Model, at minimum and in this order of value:

1. **Business service → systems that implement it → infrastructure CIs** (the chain that
   turns a downed host into an explainable impact).
2. **Dependencies between services** (calls / depends on), including **external and SaaS** ones.
3. **Physical location and power** (rack, unit, PDU, circuit): an electrical
   maintenance needs this relationship and almost nobody has it.
4. **Technical owner and business owner**, by name. A CI with no owner is a CI nobody will review.

**Minimum viable depth**: model only the relationships somebody is going to query. A complete
and unmaintained graph lies more than a partial, fresh one.

### 3.5 Why Terraform state is not a CMDB

Structural reasons, not maturity ones: **(1)** it only contains what that code created —the iron, the
manual and the inherited do not exist—; **(2)** it is **fragmented** across dozens of state files with no
common identifier and no global view; **(3)** it does not model services, owners or criticality; **(4)**
**it contains secrets in the clear**, so it cannot have the broad read permissions an
inventory needs; **(5)** its lifecycle is that of `apply`: a destroyed resource disappears,
whereas the inventory must **keep the retired asset with its history**. Correct use: state
is a **source that feeds** the inventory, just like the hypervisor.

## 4. Data quality: the metrics that decide whether it stays alive

> *(§6 "Performance and operability" of the format is deliberately omitted: in this domain it reduces to operating a
> web application and its database, which is not criteria owned by this skill.)*

Published on a visible dashboard, not in a quarterly report:

- **Coverage**: % of discovered assets that exist in the inventory, and its inverse —**declared
  assets not seen for N days**—. Coverage is measured against an independent source
  (network sweep, the switch's ARP/MAC table, cloud billing), never against itself.
- **Freshness**: % of CIs with discovery in the last 24 h; age of the oldest declared
  attribute. **A CI unseen for 30 days is flagged `stale` and drops out of the reports**, it is not deleted.
- **Completeness of what is not discovered**: % of assets with a named owner, criticality and contract.
  It is usually the lowest metric and the most expensive to raise; it is also the one that provides all the value.
- **Usage**: queries and API calls per week, and **from which systems**. It is the survival
  metric: *a CMDB nobody consults gets switched off, not improved* (criteria shared with
  `itsm-itil-standards`).
- **Recommended CI gate**: the automation that consumes the inventory **fails** if the record
  of the host it is about to touch is `stale` or has no owner. That is what turns data quality into
  a problem for whoever degrades it, and not for whoever maintains it.

## 5. Inventory security

- **A complete inventory is an attack map**: topology, OS versions, services and sometimes
  management credentials. A **high-value** system: SSO with MFA, scoped RBAC, API tokens with
  minimum permissions and an expiry, and **read auditing**, not just write auditing.
- **FORBIDDEN to store secrets in the inventory** (BMC passwords, SNMP communities, keys): they go
  to the secrets manager, here only **the reference**.
- **Discovery credentials are the weak link**: a dedicated account, **read-only**,
  per segment, rotated, and **never the same one automation uses to change things**.
- **A sweep is traffic the IDS must know about**: agreed, with a window and a fixed origin. Aggressive
  `nmap` against OT/ICS or old storage arrays can knock them over — on those segments, passive
  discovery (LLDP, ARP, flows) before active.
- **The tool has CVEs too**: as of Aug 2026 NetBox fixed **CVE-2026-29514** (arbitrary code
  execution via `ExportTemplate`'s `environment_params`).
- **Asset decommissioning = decommissioning its access**: retirement triggers revocation of credentials,
  certificates and firewall rules. Without that link, you document that the iron is gone and leave its
  identity alive.

## 6. Lifecycle and the asset nobody can explain

Minimum, explicit states: `planned → being provisioned → in production → obsolete (dated end of
support) → retired → destroyed (with a wipe certificate)`. Every transition has an owner and a
date; **"obsolete" with an end-of-support date is the data that feeds the renewal plan** and the
only thing that avoids discovering an EOL on the day you have to patch.

**The hard, universal case: the powered-on machine nobody can explain.** It is not switched off blindly and
it is not left forever either. Procedure with an owner and a deadline:

1. **Observe before touching**: for **a full business cycle, year-end close included** —what
   connections come in and out, what processes, what scheduled jobs, who authenticates—. The
   integration nobody remembers shows up at year-end close, not in April.
2. **Look for the owner by evidence, not by memory**: who logs in over SSH, which address its
   `cron` jobs mail, which certificate it presents, which invoice or contract references it, who created it according to
   the hypervisor audit log.
3. If it still has no owner: **reversible shutdown with notice** —announcement with a deadline, shutdown in a window with
   an immediate reversal plan and **the system preserved, not destroyed**, for a defined period (60–90
   days is usual; you set it)—. It is the only honest way to find out what it was for.
4. **Destroy only after the quarantine period**, with a verified restorable copy and certified
   wiping. And with the record kept in the inventory: **a retired asset is not deleted from the
   database, it is archived**.

## 7. Sustainability and prohibitions

- ❌ **FORBIDDEN** an asset identifier based on hostname or IP (§3.1).
- ❌ **FORBIDDEN** to populate the CMDB by hand with what an API can discover. It is the direct cause of it
  going stale within three months.
- ❌ A declared attribute (owner, criticality, contract) **without a review date**.
- ❌ Dumping raw discovery into NetBox: it breaks its intent model (§3.3).
- ❌ Presenting **Terraform state**, the Prometheus *targets* list, DNS or a spreadsheet
  as "the inventory" (§3.5).
- ❌ Two sources writing the same attribute with no declared precedence.
- ❌ Secrets inside the inventory, or discovery credentials with write permissions (§5).
- ❌ Deleting the asset record on retirement: it is archived with its history.
- ❌ Modelling an exhaustive relationship graph nobody is going to maintain (§3.4).
- ❌ Maintaining a CMDB whose only consumer is the auditor. **If it does not answer real questions, it is
  switched off** — criteria shared and non-negotiable with `itsm-itil-standards`.
- ❌ Switching off an unknown server without the observation cycle of §6 — and equally leaving it powered on
  indefinitely "just in case": both are the same refusal to decide.
- ❌ Buying a CMDB tool before having decided **which questions it must answer** and
  **which source each attribute comes from**.

## 8. Mandatory web verification

Before pinning anything, check on the web —with a verbatim quote, not an automatic summary:

1. **NetBox**: current version (as of Aug 2026, **v4.6.7**, 30 Jul 2026) and open CVEs. **Licence
   verified by reading `LICENSE.txt` in raw: Apache-2.0** — note that the file is **not** called
   `LICENSE`, which returns 404. **Declared gap: the exact split of features
   between NetBox Community, NetBox Enterprise and NetBox Labs' NetBox Cloud was not verified**, nor whether Assurance/Diode
   require a commercial licence. Before designing on Assurance, confirm it with the vendor.
2. **Nautobot**: v3.2.2 (3 Aug 2026), **Apache-2.0** verified in raw. It also keeps a live
   2.4.x branch: check which one is supported for you.
3. **GLPI (GPL-3.0)**, **Snipe-IT (AGPL-3.0)** and **Ralph (Apache-2.0)**: licences verified in
   raw. **AGPL in Snipe-IT matters** if you plan to offer it as a service to third parties or modify it.
   **Declared gap: the current version of none of the three was verified**, nor the actual licence
   of **i-doit Open** (the community cites it as AGPLv3 and the vendor maintains the product —there is
   news of an internal reorganisation in Jan 2026—, but **the raw file was not read** and there is
   public debate about what is left out of the Open edition). Read it before citing it.
4. **osquery**: **dual licence `Apache-2.0 OR GPL-2.0-only`**, declared in its `LICENSE`. The
   choice is yours and has consequences if you redistribute: do not cite it as plain "Apache".
5. **ServiceNow CSDM**: current version of the model (**5.0**, May 2025, 7 domains) and its mapping to the
   platform release you have. **Declared gap: the names of the 7 domains come from
   partner sources, not from ServiceNow's official portal**; confirm them there before using them in a
   design.
6. **Orb agent / Diode / Assurance**: still labelled *public preview* in the documentation
   consulted. Verify their maturity and their licensing model before making them a dependency.
7. **Regulation**: if the inventory is compliance evidence (ISO 27001 A.5.9, ENS, NIS2),
   check the current text of the control — the required scope (does it include software? SaaS? data?)
   changes between revisions and is what determines what you must model.

If the web contradicts this document, **the web wins** — flag the discrepancy.
