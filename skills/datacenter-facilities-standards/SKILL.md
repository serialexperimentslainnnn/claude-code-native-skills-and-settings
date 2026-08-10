---
name: datacenter-facilities-standards
description: The physical plant of a data centre or server room — everything bolted to the rack but not inside the server. Use when sizing A/B utility feeds and per-phase load balance, specifying UPS topology (double conversion, line-interactive, eco mode) and real autonomy at measured load, running a generator load bank test or a black-building test, choosing switched and metered PDUs and reading per-outlet current, discovering that two PSUs share one circuit, planning hot/cold aisle containment, CRAC/CRAH versus in-row versus rear-door heat exchangers, direct-to-chip liquid cooling and immersion at high kW/rack, ASHRAE TC 9.9 Thermal Guidelines classes A1-A4 and H1 and the recommended versus allowable envelope, rack density in kW and floor loading on a raised floor, structured cabling and labelling (ANSI/TIA-568, ANSI/TIA-606), fire detection and suppression under NFPA 75, NFPA 76, NFPA 2001 and NFPA 855, VESDA aspirating detection and lithium battery off-gassing, physical access control mantraps and CCTV retention, Uptime Institute Tier I-IV and TCDD/TCCF/TCOS certification, EN 50600 and ISO/IEC 22237 availability classes, ANSI/TIA-942 ratings, PUE under ISO/IEC 30134-2, comparing colocation versus an own room versus cloud on cost, or writing the preventive maintenance and testing calendar for power and cooling plant.
---

# Data centre physical plant standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the physical installation that holds up the hardware**: power from the utility feed to the
rack strip, cooling from the chiller to the server air inlet, the space
(rack, floor, weight, cabling), fire protection, physical access control and
the **maintenance and testing** that make all of that true instead of a diagram.

**Boundary in one line, agreed with `server-hardware-standards`: if it is bolted to the rack
but not inside the server, it belongs here.** The chassis, the PSU, the BMC and the disk are theirs; the
circuit feeding that PSU, the UPS backing it, the PDU it plugs into, the air that goes
into it and the floor tile that holds it up belong here.

**Guiding principle**: **redundancy is proven by taking things away, not by drawing them.** A
diagram with two of everything is not redundant until one branch is powered off under real load and
the service does not notice. Almost every expensive plant failure is *paper redundancy*: two
power supplies on the same circuit, two UPS branches with a single upstream board, a generator
that starts unloaded every month and has never seen the load.

Triggers: A/B utility feed, "how much autonomy does the UPS have?", generator, load bank
test (*load bank*), *black building test*, transfer switch (ATS/STS), switched/metered
PDU, "phase balancing", phase imbalance, "both power supplies on the same
strip", cold/hot aisle, containment, CRAC/CRAH, in-row, rear-door heat exchanger
(RDHx), CDU, *direct-to-chip*, single-phase/two-phase immersion, ASHRAE TC 9.9, classes A1–A4/H1,
*recommended* vs. *allowable*, kW per rack, kg per floor tile, raised floor, ANSI/TIA-568,
ANSI/TIA-606, patch cord labelling, NFPA 75/76/2001/855, VESDA, lithium *off-gassing*,
airlock/*mantrap*, CCTV retention, Tier I–IV, TCDD/TCCF/TCOS, EN 50600, ISO/IEC 22237,
ANSI/TIA-942, PUE, ISO/IEC 30134-2, "colo or our own room?", preventive maintenance plan.

**Not applicable**: see `server-hardware-standards` (**inside the chassis**: PSU, BMC, firmware,
warranty; here, the circuit that feeds it and the requirement that there be two distinct ones),
`onprem-standards` (**platform umbrella and its routing table §1.2**: this skill is the
physical layer it was missing; its §1.3 invariants win),
`cmdb-inventory-standards` (**the record**: rack, U, circuit and PDU are *inventory data*
and live in the DCIM — here we decide what they mean and which ones must be maintained),
`os-provisioning-standards` (the server's journey **from the moment there is power and an IP**),
`datacenter-fabric-standards` (the Clos/EVPN fabric that runs over that cabling),
`high-speed-interconnect-standards` (InfiniBand/RoCE and the link length imposed by the
physical topology), `networking-standards` and `routing-switching-standards` (addressing,
VLAN, campus), `network-automation-standards` (configuration as code),
`gpu-computing-standards` (**the GPU as a resource**: TDP, DCGM, *throttling*; here the kW/rack and
the liquid circuit that carries it away), `hpc-standards` (the cluster and its scheduler; here the
room where it lives), `green-it-standards` (**the metric and the report**: SCI, GHG Protocol, WUE,
CUE, ERF/REF, EED and the European data centre reporting scheme, waste heat as
footprint — here PUE only as a **design and operations decision**, not as regulatory reporting),
`bcdr-standards` (**RTO/RPO, alternate site and disaster declaration**; here site
resilience, not continuity strategy), `ha-clustering-standards` (service redundancy),
`linux-storage-standards` and `zfs-standards` (the data), `kubernetes-standards` (what runs
on top), `finops-standards` (cloud cost and its comparison),
`homelab-standards` (**proportionality**: at home the plant is a 1500 VA UPS and a
window; nothing in this document applies literally there),
`grc-compliance-standards` (physical security control as audit evidence for
ISO 27001 A.7 / ENS), `identity-access-management-standards` (logical identity; here the
badge and the turnstile), `incident-management-standards` (managing the incident when the room
goes down), `vulnerability-management-standards`, `iac-standards`, `observability-standards`,
`sre-practice-standards`, and `embedded-iot-standards` (the sensor and its
firmware; here, what has to be measured in the room).

## 2. Default decisions

> Verify on the web the current edition of every standard, product capabilities and prices before
> committing to anything (§8). The normative quotations in this document are taken **verbatim** from the source.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Own room vs. colocation | **Colocation** unless scale or a sovereignty requirement says otherwise | Building real redundant plant (2 utility feeds, generator, N+1 cooling, fire protection, 24×7 guard) has a fixed cost that does not amortise below tens of racks. An own room is justified by latency to a local process, by regulatory control or because it already exists and is amortised |
| Colocation vs. cloud | **Decided with measured load, not with a price list** | Cloud wins on variable load and short projects; colocation wins on stable 24×7 load over several years with your own hardware. **An honest comparison includes staff, transport, hardware refresh and data egress** — leaving any of them out invalidates the number |
| Power to the rack | **Two branches (A/B) on distinct circuits, boards and UPS** | It is *the* invariant of this skill. Each branch sized to carry 100 % of the load on its own |
| Load per branch | **≤ 40–45 % of the circuit rating in normal operation** | If each branch runs at 80 %, losing one branch trips the other's breaker. 2N redundancy requires that **each branch has room for the whole load**, not half of it |
| PDU | **Switched and metered per outlet**, with both branches on distinct racks | Without per-outlet metering there is no possible phase balancing and no drift detection. Switching avoids a physical trip for a power cycle |
| UPS topology | **Double conversion (VFI)** in a production room | *Eco* / *line-interactive* mode improves PUE at the cost of a transfer time and of exposing the load to mains quality. Accepted only with demonstrated tolerant load |
| UPS autonomy | **Whatever covers generator start and load pickup, with measured margin** | Datasheet minutes are at nominal load and with new batteries. **Real autonomy is measured with a load bank against the current profile**, and decays with battery age |
| Generator | **With a fuel contract and periodic testing under real load** | A generator tested unloaded proves nothing: it does not heat up, it does not reveal *wet stacking* or the ATS's capability under a load step |
| Cooling | **Cold/hot aisle with containment** as the baseline | Containment is the efficiency improvement with the best cost/benefit ratio in the whole room and does not depend on the vendor |
| Cooling redundancy | **N+1 in units and in pumps, with concurrent distribution** | Losing one unit must not require reducing the IT load. Careful: N+1 machines on a single pipe is still a single point |
| Setpoint temperature | **ASHRAE *recommended* envelope (18–27 °C at the machine inlet)** | See §3.3: it is measured at the **equipment inlet**, not at the return or in the ambient |
| Liquid cooling | **No, until density forces it** (§3.4) | It introduces water/dielectric, a CDU, new maintenance and new staff. Adopted on measured density, not on fashion |
| Site classification | **EN 50600 / ISO/IEC 22237** if a level has to be declared; **Uptime Tier** only if you really are going to certify | See §3.7: "we are Tier III" without a certificate means nothing |
| Suppression | **Very early aspirating detection + clean agent or pre-action**, per NFPA 75 and a risk assessment | See §5.3. The specific agent and concentration are set by NFPA 2001 and the fire protection engineer, not by this skill |
| Efficiency metric | **Annualised PUE, with the measurement category declared (ISO/IEC 30134-2)** | A PUE with no category, no boundary and no period is marketing (§6.2) |

## 3. Structure and conventions

### 3.1 Power: the whole chain and where it breaks

The chain is: **utility feed → main board → UPS → distribution board → rack circuit →
PDU → outlet → PSU**. Redundancy only exists if **every** link is duplicated.
The classic failure is not a missing UPS: it is that the two branches meet at a point nobody
drew (a shared board, a single ATS, a single electrical room).

- **Two power supplies on the same circuit are not redundancy.** They are two power supplies. They cover the failure of
  one PSU and **nothing else**: not the breaker, not the PDU, not the board, not the UPS, not
  maintenance on that branch. It is the most repeated mistake in the domain and it is detected with a single
  question to the inventory: *which circuit feeds each PDU in this rack?* If the DCIM does not
  know, nobody knows.
- **Phase balancing.** In three-phase distribution, each branch is spread across L1/L2/L3. A high
  imbalance overloads one phase and the neutral while the total looks comfortable. It is
  measured at the PDU and corrected by moving outlets, not by ignoring it.
- **Diversity factor.** The sum of the PSU labels is **not** the real load; the
  measured real load usually falls far below. Sizing by label wastes
  capacity; sizing by measurement with no peak and inrush margin trips protections.
  Size by **sustained measurement + observed peak + dated growth margin**.
- **Inrush current.** Powering up a whole rack at once after an outage has a peak far
  above steady state. Staggered start-up is a design requirement, not a courtesy.

### 3.2 Cooling: air, containment and water

- **The target is the equipment inlet temperature**, not the room's. Everything else
  (return, ambient, CRAC discharge) is intermediate instrumentation.
- **Containment**: cold aisle or hot aisle, plus **blanking panels in every empty U** and
  sealing of cable cut-outs. Without that, cold air recirculates, the CRAC works against itself and
  the top rack cooks with the whole room "at 21 °C".
- **Water to the door**: rear-door heat exchangers (RDHx) are the intermediate step between
  room air and liquid to the chip. They bring water to the rack without touching the server.
- **Dew point and humidity**: what matters is the upper dew point limit so as not to condense
  on cold pipework, and the lower one because of static electricity. See §3.3.

### 3.3 ASHRAE TC 9.9 — what it actually says

Reference: *Thermal Guidelines for Data Processing Environments*, **5th edition (2021)**,
ASHRAE Datacom Series Book 1 — **verify on the web whether there is a 6th edition before citing it** (§8).

A distinction that is almost always told wrong, in ASHRAE's own words (ASHRAE Journal, May 2022,
TC 9.9 column, verbatim):

> "The recommended range is likely the most important range for data center designers and
> operators. Facilities should be designed and operated to target the recommended range for
> most hours of the year."
> "ITE, on the other hand, should be designed to operate within the extremes of the applicable
> allowable environmental classes."

And the measurement point, verbatim from the same source:

> "Note that the temperature/humidity ranges listed in this column refer to the ITE inlet
> conditions and should not be confused with 'space' conditions, discharge air conditions from
> cooling equipment or return air conditions to cooling equipment."

Operational consequences:

- **Recommended (A1–A4): 64.4 °F–80.6 °F (18–27 °C)**, unchanged since the 2nd edition (2008).
  "Raising the room to 27 °C" is not heresy: it is the top end of the recommended envelope.
- **Allowable per class** (dry bulb temperature, equipment inlet): **A1 59–89.6 °F (15–32 °C)**,
  **A2 50–95 °F (10–35 °C)**, **A3 41–104 °F (5–40 °C)**, **A4 41–113 °F (5–45 °C)**. A3 and A4
  were added in the 3rd edition precisely to allow cooling without mechanical
  refrigeration.
- **Class H1**, added in the 5th edition for **high-density air-cooled equipment**
  (accelerators, HPC): its envelope is **colder**, not hotter — recommended
  **64.4–71.6 °F (18–22 °C)**. Counter-intuitive and decisive: **high density reverses the
  trend of raising room temperature**.
- **Who decides the class**: the equipment manufacturer. It cannot be deduced from what the server looks like.
- A piece of equipment's class is a **warranty limit**, not an operating target. Operating
  permanently at the edge of *allowable* shifts failure risk and fan power consumption
  onto the server.

### 3.4 Density and liquid cooling: when it stops being optional

**Data against the folklore** (Uptime Institute, *Global Data Center Survey 2025*, self-reported
by operators): the **modal** average density is around **9 kW/rack** and **more than 80 % of
operators report having no rack above the high-density threshold**. The average
room in the world is not a GPU room. **Designing the entire room for 100 kW/rack because the
industry is talking about AI is oversizing based on headlines.**

Criteria, with the discipline that **the exact threshold depends on the equipment and the project**:

- Up to ~**10–15 kW/rack**: room air with containment, done well, is enough.
- ~**15–40 kW/rack**: transition zone — strict containment, in-row cooling or rear-door
  heat exchanger. Here the problem is no longer the cold, it is **air flow and noise**.
- Above ~**40–50 kW/rack**: **air stops being viable in practice** and you move to
  direct-to-chip liquid (*direct-to-chip*, with a CDU and primary/secondary circuits).
- **Immersion** (single-phase or two-phase): niche. It solves very high densities and eliminates
  fans, but it changes the maintenance model completely (pulling a server out of a
  tank is not swapping a disk hot) and drags in fluid, manufacturer warranty
  and fire code constraints.
- **The real limit is usually electrical, not thermal**: a room designed for an average of 5–10 kW/rack
  does not take 50 kW racks even if the cooling is solved, because there is no circuit, no
  board, no UPS and no utility feed. **Before discussing the chiller, check the utility feed.**
- Adopting liquid **adds a new failure mode inside the room** (a leak) and a new maintenance
  plan (fluid quality, filters, leak detection, purging). It is not adopted
  without that plan in writing.

### 3.5 Space: rack, weight and floor

- **Weight**: a rack full of storage or GPUs approaches structural limits. **Point
  load on the floor tile and distributed load on the slab** are verified against the raised floor
  and building datasheets, **and so is the transport route** (goods lift, ramp,
  doors) — which is where it gets discovered too late.
- **Raised floor**: if it is used as a supply plenum, every badly placed perforated tile and
  every unsealed cable cut-out is a pressure leak. A raised floor used only as a
  cable pathway is a legitimate and simpler decision.
- **Depth and aisles**: rack depth is set by the longest servers and by
  rear cable management; aisles, by evacuation regulations and equipment removal.
- **U reserve**: a rack is not filled to 100 % of its U nor to 100 % of its circuit. Both
  reserves are recorded in the DCIM.

### 3.6 Cabling and labelling

- **Structured and documented**, per ANSI/TIA-568 (components and classes) and
  **ANSI/TIA-606 (administration and labelling)** — verify the current revision of both (§8).
- **Operational rule**: **every patch cord is labelled at both ends** with an identifier
  that exists in the inventory. An unlabelled cable is a cable nobody dares to remove,
  and that is how the tangles that outlive three generations of servers are born.
- **Length to suit the route, not random**: slack blocks rear airflow and is a real cause
  of hot spots. Power and data on separate trays; fibre with its bend radius.
- **Removal**: pulling the cable is part of decommissioning the equipment. If it is not in the
  procedure, it does not happen.

### 3.7 Uptime Institute Tier — what it means and what it does not

**It is one of the most misstated pieces of data out there.** Definitions **verbatim** from Uptime
Institute itself (*Explaining the Uptime Institute's Tier Classification System*):

> **Tier I:** "A Tier I data center provides dedicated site infrastructure to support
> information technology beyond an office setting."
> **Tier II:** "Tier II facilities include redundant critical power and cooling components to
> provide select maintenance opportunities."
> **Tier III:** "A Tier III data center requires no shutdowns for equipment replacement and
> maintenance."
> **Tier IV:** "Tier IV site infrastructure builds on Tier III, adding the concept of Fault
> Tolerance to the site infrastructure topology."

And the distinction between the three certificates, which is where most of the lying happens (same source,
verbatim):

> **Design (TCDD):** "Uptime Institute consultants review 100% of the design documents,
> ensuring each subsystem among electrical, mechanical, monitoring, and automation meet the
> fundamental concepts."
> **Constructed facility (TCCF):** "During a TCCF, a team of Uptime Institute consultants
> conducts a site visit, identifying discrepancies between the design drawings and installed
> equipment."
> **Operational sustainability (TCOS):** "Uptime Institute will assess the operational plans and
> parameters for any Tier Certified data center, and help the client understand where issues
> may occur."

Rules that follow, and that must be applied in any tender or comparison:

- **A design certificate (TCDD) says nothing about what was built.** It is the most common
  sales claim: a bare "certified Tier III" is usually TCDD. Ask for the **type** of certificate,
  the **award number** and the **date**.
- **TCDD is a prerequisite for TCCF, and both are prerequisites for TCOS.** There is no shortcut.
- **Uptime uses Roman numerals (Tier I–IV).** "Tier 3", "Tier 3+" and "Tier 4 ready" **are not
  Uptime designations**: they are marketing and are not accepted as a contractual requirement.
- **Tier is topology, not a component list.** The same N chillers and N UPS give
  Tier II or Tier III depending on how they are distributed.
- **Alternatives for specifying without certifying**: **EN 50600** and its international sibling
  **ISO/IEC 22237** (availability classes 1–4, plus a separate protection class, and
  applied per subsystem: power, environmental control, telecommunications) and **ANSI/TIA-942**
  (*ratings* 1–4). Verify on the web the current parts and editions of each (§8).

## 4. Acceptance and testing — the section that makes everything above real

**A generator with no load test is an ornament.** This section is the equivalent of
"tests" in a software skill: without it, §3 is documentation.

Testing ladder, from lowest to highest cost and confidence:

1. **Inspection and thermography** of the electrical board: loose connections and hot spots.
   Cheap, annual, finds faults before they become fires.
2. **Unloaded generator start** (weekly/monthly): only proves that it starts. **It does not count as
   a test.**
3. **Load bank test** (*load bank*): the generator takes real load, reaches temperature and
   reveals *wet stacking*, cooling, exhaust and regulation. **Annual at a minimum.**
4. **UPS autonomy test at measured real load**, not at catalogue nominal. It is the only
   way to know how many minutes there are.
5. **Switchover test**: open each power branch separately, under load, and
   check that nothing goes down. This is what validates the "two distinct circuits" of §3.1 and what
   uncovers the rack with two PSUs on the same branch.
6. **Black building test**: simulated total loss of the utility feed, with production load or
   equivalent. It is the definitive test and the scariest one; that is why almost nobody does it, and
   that is why the failures show up on the real day.

Rules:

- **Every test is planned with a window, a back-out plan and abort criteria in writing**, and
  leaves a report with measurements. A test with no report did not happen.
- **Test before you need it**: site acceptance (*commissioning*, levels L1–L5)
  is done **before** putting production load in, not after.
- **Batteries**: an impedance/discharge test is the only honest indicator of their state;
  battery age is an estimate, not a measurement.
- **Preventive maintenance record** per asset, with the date of the last test and of the
  next one, **in the inventory** (`cmdb-inventory-standards`), not in somebody's spreadsheet.

## 5. Facility security

### 5.1 Physical access

- **Least privilege here too**: access by role and by time window, not permanent;
  periodic review of the list and **immediate removal on leaving the organisation** (an active badge
  belonging to an ex-employee is the physical equivalent of an orphan account). Two factors at the
  door (badge + PIN or biometrics) and an airlock/*mantrap* where the risk justifies it.
- **Escorting of third parties** (maintenance, construction, carrier) recorded and non-delegable.
- **Locked racks** and, in colocation, **your own cage**: the neighbour is not trusted.
- **CCTV** with a defined retention, **and that retention is personal data**: period, legal basis and
  access are documented (see `privacy-engineering-standards`).
- **Log of material entering and leaving**: a server that leaves the room without a record
  is a potential data leak. Decommissioning includes certified erasure or destruction of the
  media before the equipment leaves physical control.

### 5.2 The surface everybody forgets

- **The electrical room, the battery room and the generator yard are part of the perimeter.** Cutting
  power from outside is easier than getting into the room.
- **Plant BMS/DCIM/SCADA**: environmental and power management is a connected industrial network,
  often with default credentials and unpatched. **It goes in its own VLAN, with no route to
  the Internet and no access from the user network.**
- **Emergency power off button (EPO)**: mandatory by regulation in many places and a documented cause
  of accidental outages. It is physically protected against involuntary activation.
- **Leak sensors** under the floor and in the liquid circuit; **water detection** in every
  room with pipework.

### 5.3 Fire

- Framework: **NFPA 75** (protection of IT equipment) and **NFPA 76** (public network
  telecommunications facilities); the clean agent system itself is governed by **NFPA 2001**;
  battery energy storage, by **NFPA 855**. Verify the current editions (§8):
  the **2024 edition of NFPA 75** moved lithium battery requirements to NFPA 855 and
  **added requirements for immersion cooling equipment and for *off-gassing*
  detection**.
- **Very early aspirating detection (VEWFD/VESDA)** in the room: it detects combustion before
  there is a flame, which is when you can still intervene without discharging anything.
- **Double-interlock pre-action** rather than a wet sprinkler over racks; clean agent
  when the risk of water damage justifies it.
- **Lithium batteries**: the risk is not the same as with lead. *Off-gassing*, thermal runaway
  and re-ignition change the detection and compartmentation strategy.
- **Acoustic discharge**: agent discharge through a nozzle generates noise levels capable of
  **damaging hard disks**. It is a real, documented failure, and it is mitigated in design.
- The specific design (agent, concentration, hold time, room integrity) is signed off by a
  fire protection engineer. **This skill requires that it exists and has been tested, it does not
  design it.**

## 6. Operation and efficiency

### 6.1 Minimum instrumentation

Without these measurements the room is operated blind, and they are exactly the ones missing when there is an
incident:

- **Power**: per utility feed, per UPS, per board, **per rack circuit and per PDU outlet**.
- **Environment**: temperature **at the rack inlet** (top, middle, bottom — the vertical gradient
  is the recirculation signal), humidity, dew point, differential pressure in the plenum.
- **State**: UPS (load, estimated autonomy, battery state, bypass), generator (fuel
  level, hours, start failure), chillers, water detection, doors.
- **Alerts on symptoms**: power branch lost, circuit above the switchover
  threshold, inlet temperature outside the envelope, UPS on bypass, generator in fault.
  **Everything else is noise.**

### 6.2 PUE — why the vendor's number is almost never comparable

Standard: **ISO/IEC 30134-2**. Verified: **edition 2 is ISO/IEC 30134-2:2026, published on
16 January 2026**, and it replaces 30134-2:2016 (withdrawn) and its Amd 1:2018. **Any
document citing "ISO/IEC 30134-2:2016" is out of date** — verify before citing (§8).

PUE = total facility energy / IT equipment energy. It is a trivial division, and
that is exactly why it is manipulated without lying:

- **System boundary**: does the office count? the lighting? the medium-voltage transformer
  losses? the cooling of the electrical room? Different boundary, different number.
- **Measurement category**: the standard defines categories according to **where** IT energy is measured
  (UPS output, PDU output, equipment inlet) and with what temporal granularity. **A
  PUE with no declared category is not comparable with any other.**
- **Period**: annualised PUE ≠ instantaneous PUE on the best winter day. The *design PUE* in a
  brochure is a simulation, not a measurement.
- **Partial load**: a room at 20 % occupancy has a dreadful PUE by physics, not by bad
  operation. Comparing PUE between sites with different occupancy says nothing.
- **Climate**: a Nordic site wins by geography. It is not an engineering achievement.
- **Reference figure, with its methodology and its limits**: Uptime Institute (*Global Data
  Center Survey 2025*) reports a **weighted average of 1.54**, the sixth consecutive year
  essentially flat, over **n≈681 self-reported responses** to the question about **the organisation's
  largest data centre**. It is **self-reported, not audited and not weighted by
  load**, so it does not represent a world average: hyperscalers are under-represented.
  **It is cited with those four caveats or it is not cited.**
- **What PUE does not measure**: anything the IT equipment does. Switching off zombie servers
  **worsens** PUE and improves everything else. That is why PUE is accompanied by total energy and
  useful work, never on its own.
- **Sibling metrics** (WUE for water, CUE for carbon, ERF/REF for heat reuse) and all
  regulatory reporting belong to `green-it-standards`. Here we only decide **to measure them** and **not
  to optimise PUE at the cost of blowing up water consumption**, which is the silent trade-off of
  evaporative cooling.

### 6.3 Waste heat

Heat reuse stops being anecdotal once there is liquid: **the hot water from a
direct-to-chip circuit is far more usable than the lukewarm air from a hot aisle**.
The decision is one of urban planning and of a contract with a nearby heat consumer, not of room
engineering; the accounting (ERF/REF) belongs to `green-it-standards`.

## 7. Long-term sustainability and prohibitions

**Minimum cadence**: annual review of the preventive maintenance plan and of the testing
matrix; capacity review (kW, U, tons of cooling, ports) quarterly with DCIM
data; review of the physical access list at least every six months; review of the editions of standards
cited in tenders, annually (§8).

**Capacity curve**: the room fills up through **the first resource that runs out** — almost always
power or cooling, almost never U space. It is projected from measurement, with a date, and **you decide
what to do at 70 % occupancy, not at 95 %**, because expanding plant takes months or years.

Prohibitions:

- ❌ **Two power supplies of the same server on the same circuit** and calling it redundant.
- ❌ **Declaring a generator operational without a documented load test** in the last
  year. Starting it unloaded does not count.
- ❌ **Declaring UPS autonomy from the manufacturer's datasheet** instead of a
  measurement against the current load profile.
- ❌ **Putting a room into production without documented *commissioning***, or bringing load in before
  the acceptance tests.
- ❌ **Racks without blanking panels** and unsealed cable cut-outs in a room with containment: you are
  paying for cooling in order to recirculate it.
- ❌ **Loading both branches beyond the point where one alone cannot carry the total.** That is
  accounting redundancy, not electrical redundancy.
- ❌ **Patch cords without a label at both ends**, or labels that do not exist in the inventory.
- ❌ **Claiming a Tier without a certificate**, confusing TCDD with TCCF, or using "Tier 3+" / "Tier IV
  ready" as if it were an Uptime Institute designation.
- ❌ **Publishing or comparing a PUE without boundary, measurement category (ISO/IEC 30134-2) and period.**
- ❌ **Quoting a room temperature without saying where it is measured.** Only the equipment inlet counts.
- ❌ **Operating permanently at the *allowable* extreme of the ASHRAE class** as if it were the
  design target.
- ❌ **Adopting liquid cooling without a leak detection, fluid maintenance and
  intervention plan**, or without first verifying that the utility feed and the board deliver that power.
- ❌ **BMS/DCIM on the corporate network or exposed to the Internet**, with default credentials or without
  a patching cycle.
- ❌ **Taking a server out of the room without recording the exit** and without certified erasure or
  destruction of the media.
- ❌ **Quoting server lifetime figures ("5 years") or industry average PUE as facts.**
  If they do not come with methodology, sample and boundary, they are cited as an estimate or not cited.
- ❌ **Designing the whole room for AI densities without load to justify them.** Density is
  measured; headroom is planned by zone, not by applying the worst case to the whole building.

## 8. Mandatory web verification

Before committing any figure from this document to a tender, a design or a report:

1. **ASHRAE TC 9.9, *Thermal Guidelines for Data Processing Environments***: confirm that the
   **5th edition (2021)** is still current and that there is no 6th. The envelopes in §3.3
   are taken **verbatim** from the TC 9.9 column in *ASHRAE Journal*, May 2022 (Quirk,
   Davidson, Schmidt), which reproduces the tables of the 5th edition. **Declared gap**: the
   ASHRAE book is paid-for and could not be read raw; the figures have been cross-checked
   against that column published by ASHRAE, not against the book.
2. **Uptime Institute**: the Tier I–IV and TCDD/TCCF/TCOS definitions in §3.7 are
   **verbatim** from *Explaining the Uptime Institute's Tier Classification System*
   (journal.uptimeinstitute.com). **Declared gap**: the normative document *Tier Standard:
   Topology* is not freely accessible; it has not been read raw. Before contracting, ask the
   provider for the specific certificate and verify it with Uptime.
3. **ISO/IEC 30134-2**: verified that the current edition is **ISO/IEC 30134-2:2026 (edition
   2.0, published on 16 January 2026)** — confirmed on the IEC Webstore record
   (publication 111538) — and that the 2016 edition and its Amd 1:2018 are withdrawn. **Declared gap**:
   `iso.org` returns 403 and the text of the standard is paid-for; **the clauses have not been read**,
   so the exact definition of the measurement categories must be consulted in the standard before
   declaring one in a report. Boundary note: `green-it-standards` cites this standard without a
   year; it is worth checking whether its text assumes the 2016 edition.
4. **EN 50600 / ISO/IEC 22237 / ANSI/TIA-942 / ANSI/TIA-568 / ANSI/TIA-606**: check the published
   parts and current revision of each. The ISO/IEC 22237 series was **incomplete** in
   the sources consulted; it has not been verified part by part. **Declared gap.**
5. **NFPA 75 / 76 / 2001 / 855**: verify the current edition (NFPA reissues on ~3–4 year
   cycles). Confirmed that **NFPA 75 edition 2024** exists and that it moved lithium
   battery requirements to NFPA 855 and added immersion and *off-gassing* requirements; **declared
   gap**: the NFPA text is paid-for and has not been read raw.
6. **Density thresholds for liquid (§3.4)**: **there is no normative figure**. The
   40–50 kW/rack range comes from manufacturer guidance, which disagrees with itself (thresholds
   from ~35 kW have been seen). It is used as an order of magnitude, **never as an acceptance criterion**; the
   number that governs is the one on the specific equipment's datasheet.
7. **Industry figures**: any average of PUE, density or lifetime is cited with
   source, year, sample size and collection method. The one in §6.2 is self-reported.
8. **Product and price**: UPS, PDU, CDU and chiller capabilities, lead times
   (critical and highly variable for electrical equipment) and colocation rates are verified
   against the manufacturer and the provider, never from memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
