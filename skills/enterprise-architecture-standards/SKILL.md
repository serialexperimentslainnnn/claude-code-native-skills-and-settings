---
name: enterprise-architecture-standards
description: The application landscape of an organization, not the design of one system. Use when building or repairing an application inventory (owner, criticality, cost, lifecycle, dependencies), running application portfolio rationalization with the Gartner TIME model (tolerate, invest, migrate, eliminate), choosing a modernization strategy from the R taxonomy (rehost, relocate, replatform, repurchase, refactor/re-architect, retire, retain), adopting or refusing TOGAF (Standard 10th Edition, ADM) and ArchiMate 3.2 and checking whether its licence lets you publish the notation, evaluating Archi, Structurizr, SAP LeanIX, Ardoq or Bizzdesign as an EA repository, building a business capability map as a stable mapping axis, setting a technology standard and the exception process with a mandatory expiry date, publishing a technology radar (Build Your Own Radar, adopt/trial/assess/caution rings), deciding build versus buy versus SaaS with exit cost and vendor lock-in, governing the integration landscape (point-to-point versus bus versus event-driven), designing an architecture review body that does not become a change advisory board, reconciling the application inventory with the ITSM CMDB and the service catalogue, or defining metrics for the EA function that are not a document count.
---

# Enterprise architecture standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Enterprise architecture exists so that systems decisions are taken with the complete landscape
in front of you.** Its product is not a diagram: it is that whoever decides to buy, build, migrate or
switch off knows what already exists, who pays for it, what it depends on and what breaks. **Its typical failure —and the
function's default failure mode— is producing documentation nobody uses**: models that are correct,
complete, updated once and consulted never.

Rule of existence, applicable on Monday: **an EA artifact that has not changed any decision
in the last 90 days is retired or is assigned the decision it was supposed to inform.** No exception
for "it is reference documentation".

Covers: the application inventory and its degradation, the lifecycle decision per application
(TIME), the modernisation "R"s, frameworks (TOGAF, ArchiMate and lightweight alternatives), the business
capability map, technology standards and their exception process, the technology radar,
build/buy/SaaS, the integration landscape as invisible debt, architecture governance and its
bottlenecks, the descent to team decisions and the function's metrics.

**Not applicable**:
- `software-architecture-patterns-standards` (**critical boundary**): **theirs** the internal design of
  **one** system —style, module boundaries, dependency rule, CQRS, ADR, C4—; **here** the
  organisation's landscape, the inventory, the cross-cutting standards and their governance. Arbitration:
  **if the question is how this system is structured, it is theirs; if it is which systems we have, which
  are redundant and what the standard is, it belongs here.**
- `itsm-itil-standards` (**fine boundary, written precisely**): **theirs** the CMDB, the configuration
  items and the service catalogue. **The CMDB inventories configuration items in order to
  operate** (what is affected by this change, which CI failed); **the application inventory
  inventories capabilities in order to decide** (what does this contribute to the business, what does it cost, is it kept or
  switched off). Different granularity, different cadence and different owner. **Rule: an application in the
  inventory references its CIs, it does not duplicate them** (§3.2); if they end up diverging, the CMDB wins on
  operational state and the inventory on the portfolio decision.
- `platform-engineering-standards` (the internal platform as a product and its paved road;
  **here the standard the platform implements, not its implementation**).
- `lowcode-governance-standards` (**theirs the catalogue of personal tools and its governance** —
  environments, connector DLP, flow identity, orphaned flows—; **the low-code app that becomes
  critical enters the application inventory here**, with owner, cost and lifecycle).
- `tech-leadership-standards` (the decision to invest, the negotiation and the organisational record;
  here the technical portfolio criteria that feed it).
- `project-management-standards` (how the migration programme is delivered; here what is migrated and
  why).
- `finops-standards` (**hard reciprocal**: cost per application is computed with their method —
  tagging, allocation of shared costs, economic unit— and **enters here as a mandatory input
  to the lifecycle decision**; §3.1).
- `grc-compliance-standards` (control framework, audit and evidence; here the compliance
  attribute as an inventory field, not the programme).
- `microservices-architecture-standards` (the distributed topology of a system and its communication).
- `data-governance-quality-standards` (**theirs** data ownership, the data catalogue, the
  glossary and data contracts; **here the application as a source system, not the data**).
- `iac-standards` (how infrastructure is declared and deployed).
- `bcdr-standards` (**reciprocal**: criticality and RTO/RPO per application are derived from its BIA and
  **are stored as an inventory field**; they are not recalculated here).
- `knowledge-management-standards` (where what is written here lives and how it is maintained) and
  `product-discovery-standards` (what is built and for whom). **The landscape decides which systems
  exist; discovery, what is built; documentation is what remains written of both
  decisions.**
- **Legacy platform skills**: `mainframe-zos-cobol-standards`,
  `ibm-i-rpg-standards`, `mumps-standards`, `dotnet-framework-legacy-standards`,
  `aix-solaris-hpux-standards` and the rest of the legacy block. **Here it is decided what is done with an
  application** —the TIME model, the chosen modernisation "R", the cost and the owner—; **there, what
  that decision technically implies on that specific platform** and whether it is even viable. The rule
  that avoids the expensive error: **an "R" is chosen with the platform's technical criteria in front of you, not
  on a spreadsheet** — there are platforms where automated rewriting produces code
  nobody can maintain and others where freezing and encapsulating is the right answer.
  `legacy-modernization-standards` is the umbrella that routes between them.

## 2. Default decisions

> Verify the latest version/status/licence on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Root artifact | **Application inventory** with the 8 mandatory fields of §3.1 | None: without an inventory there is no EA function |
| Framework | **None in full.** Take from TOGAF only the ADM as a phase script and whichever views get used | The full TOGAF Standard 10th Edition only with a contractual/regulatory obligation or a required certification |
| Notation | **C4** for systems (→ `software-architecture-patterns-standards`) and **named boxes with a legend** for the landscape | **ArchiMate 3.2** if there is already a repository and trained modellers — **check the licence before publishing** (§2.2) |
| Modelling tool | **Archi** (MIT) over a git repository | Structure inside the EA tool if one is already paid for |
| Portfolio repository | **A versioned sheet/table or a lightweight database with owner and CI** up to ~150 applications | SAP LeanIX / Ardoq / Bizzdesign above that, priced by number of applications (§2.3) |
| Lifecycle decision | **TIME** (tolerate, invest, migrate, eliminate), reviewed on a fixed cadence | Any bespoke 4-quadrant taxonomy, **if it is written down and its axes defined** |
| Modernisation | **Retire and retain first**; the other Rs only after ruling out switching off | — |
| Mapping axis | **Business capability map** (stable) | Never the org chart as the primary axis (§3.3) |
| Standards | **Published technology radar**, with 4 rings and a date | A list of "approved technologies" only if it has an exception process (§4.2) |
| Exceptions | **With a mandatory expiry date** (§4.2) | None |
| Governance | **Advisory board with threshold-based review** (§6.1) | A committee that approves everything: **FORBIDDEN** (§7) |

### 2.1 TOGAF: what to take and what to throw away

- **Current version: TOGAF Standard, 10th Edition** (The Open Group, launch announcement of April
  2022; the C220 document bundle incorporates a 2025 technical corrigendum). There is no 11th edition
  as of Aug 2026 — **verify at `opengroup.org/togaf`** (§8). TOGAF® is a registered trademark of The Open
  Group: its use in materials and the certification have their own conditions.
- **Be honest: most organisations do not need the whole of TOGAF.** What is usable without
  adopting it entirely: the **ADM** as a phase script (vision → business → information systems →
  technology → opportunities → migration → governance → change management), the concept of
  **target vs. baseline architecture with gap analysis**, and the **architecture
  repository**. What is thrown away by default: the full metamodel, the exhaustive catalogue of
  deliverables and the chain of architecture contracts.
- **Criteria for full adoption**: only if (a) a contract, a regulator or a client requires it by
  name, or (b) there are ≥3 full-time architects. Below that, adopting the whole of TOGAF produces
  exactly the failure of §1.

### 2.2 ArchiMate and its licence — it decides whether you can publish the notation

- **ArchiMate 3.2 Specification**, The Open Group, document **C226**, published in October 2022.
  ArchiMate® is a registered trademark of The Open Group.
- **Licence — the deciding point**: the specification **is not freely redistributable**. The Open
  Group publishes it under a tiered model: a **free 90-day evaluation licence** (internal
  use, keeping copyright and trademark notices) and, on expiry, you must **request a non-commercial
  or commercial licence** or withdraw the document. **All commercial use is subject to the annual
  commercial licence.** **Operational rule: modelling in ArchiMate for internal consumption is a
  workable route; embedding the specification, its reference cards or derived material in
  public documentation, paid training or consultancy deliverables requires checking the commercial
  licence first.** Verify at `opengroup.org/legal/licensing` (§8) —**it is a legal decision, not a
  technical one**.
- The specification separates **language concepts** from **notation**: the graphical notation it
  publishes is *one* default notation, not the only valid one. Practical corollary: **if the problem is
  that nobody understands the diagrams, changing the notation is legitimate and does not break the model.**
- **Archi** (`archimatetool.com`) is the default editor: **MIT licence** verified in raw —
  `The MIT License (MIT) / Copyright (c) 2013-2026 Phillip Beauvoir, Jean-Baptiste Sarrodie, The
  Open Group`. **The MIT tool does not license the specification**: they are two different things and the
  second is not inherited from the first.

### 2.3 Portfolio tools

- **SAP LeanIX**, **Ardoq** and **Bizzdesign**: **none publishes list pricing**; LeanIX and Ardoq
  license **by number of applications** (unlimited users in LeanIX's model). Purchasing consequence:
  **know the real number of applications before requesting a quote**, because it is the variable
  that sets the price and the only one that makes quotes comparable. Pricing → **gap in §8**.
- **You do not buy an EA tool to create the inventory.** You buy it when the inventory already
  exists, is maintained and the bottleneck is volume or integration with CMDB/billing.
  Buying it earlier reproduces the failure of §1 with an annual licence.

## 3. Structure and conventions

### 3.1 The application inventory — the only artifact that justifies the function

**Mandatory** fields; a row without them is not in the inventory, it is in a list:

| Field | Rule |
|---|---|
| Name and aliases | One canonical name; aliases are recorded, not argued about |
| **Business owner** (a person, not a team) | If nobody accepts being the owner, the application is a candidate for `eliminate` by definition |
| Technical lead | Team with on-call or vendor with a contract |
| **Criticality and RTO/RPO** | Derived from the BIA → `bcdr-standards`; only referenced here |
| **Total annual cost** | Licence + infrastructure + support + estimated internal effort → method from `finops-standards` |
| **Lifecycle state** | `invest` / `tolerate` / `migrate` / `eliminate` + date of the last review |
| End-of-support date | From the vendor or the version; empty ≠ "does not expire" |
| Business capabilities it supports | Link to the map (§3.3), 1..n |
| **Dependencies** | Applications and integrations it depends on and that depend on it (§5.1) |
| Data it processes | Classification and whether there is personal data → `privacy-engineering-standards`, `data-governance-quality-standards` |
| CI reference | Identifier in the CMDB; **a reference, not a copy** |

**Why it degrades, and what is done against each cause** —this is the function's real work:

1. **It is created as a project and not as a process.** Counter: the inventory has a named owner and a
   dated review in the calendar, not a project milestone.
2. **It is not in anybody's path.** Data that only serves the annual report rots. Counter:
   **tie it to an event that already happens** — application registration at project registration, cost from
   actual billing, dependencies from network/CMDB discovery, end of support from the
   vulnerability inventory.
3. **Opinion-based fields with no definition.** "High criticality" with no criteria produces 60 % of the
   applications at high. Counter: every field with closed values and a written assignment rule.
4. **Manual capture of what is already in another system.** Counter: **generate from the source and
   reconcile**, never type it twice (same principle as §4 of `knowledge-management-standards`).
5. **Nobody sees the consequence of lying.** Counter: **if cost comes out of the inventory, the budget
   comes out of the inventory**; data that decides money corrects itself.

**Inventory health metric (falsifiable)**: percentage of applications with a live owner and a review
in the last 12 months, and **the deviation between the inventory's cost and the actual invoice**. If the
deviation exceeds 10 %, the inventory is not usable for portfolio decisions.

### 3.2 Boundary with the CMDB, without ambiguity

| | Application inventory | CMDB (`itsm-itil-standards`) |
|---|---|---|
| Question it answers | Does this deserve to exist next year? | What is affected by this change or incident? |
| Unit | Application / capability | Configuration item |
| Cadence | Quarterly/annual review | Continuous, tied to change |
| Owner | Architecture + business owner | Service management |
| Source of truth in a conflict | Portfolio decision, cost, business owner | Operational state, deployment relationships |

**FORBIDDEN** to maintain two independent dependency graphs: one references the other.

### 3.3 Business capabilities as a stable axis

- It is mapped against **what the organisation does** (capabilities: "invoice", "originate a loan",
  "manage returns"), **not against who does it**. The org chart changes with every reorganisation;
  the capability does not. An inventory indexed by department becomes useless at the next
  reorganisation — and that happens sooner than the next portfolio review.
- **Two levels are enough** to decide portfolio; three only if an entire level is going to be outsourced or
  bought. A map with four levels and 300 leaves is a modelling project, not a tool.
- Real use: colour the map by **cost**, by **criticality** and by **duplication** (number of
  applications supporting the same capability). **Duplication in a non-differentiating capability
  is the finding that pays for the function.**

### 3.4 Lifecycle decision: TIME

- **TIME (Tolerate, Invest, Migrate, Eliminate)** is consistently attributed to **Gartner** as an
  application portfolio rationalisation framework. **Declared discrepancy**: I could not locate the
  primary research note (identifier and year) in open sources —the available ones are secondary,
  mostly from EA tool vendors—, **and its axes do not agree between sources**: some cross
  *technical fit × functional fit* and others *business value × technical fit*. **Operational
  consequence: if TIME is used, write in your own document which two axes are used and how they are scored**;
  citing it without pinning the axes guarantees that two people
  will classify the same application differently. Verify the primary source before attributing it in a
  formal document (§8).
- Hard rules that make the classification falsifiable:
  - `tolerate` **carries a mandatory re-review date**; without it, it is abandonment with a nice name.
  - `invest` requires an identified differentiating capability (§5.2) and allocated budget.
  - `eliminate` requires a **shutdown date, a data plan and notified consumers**; an application
    "eliminated" that is still running still costs money.
  - **No application is left unclassified**: with no explicit classification, the default
    state is `tolerate` with a 12-month review, and it is declared as such.

### 3.5 The modernisation "R"s

Working taxonomy (AWS names, in majority use): **rehost, relocate, replatform,
repurchase, refactor/re-architect, retire, retain**.

- **Origin, with the attribution chain declared**: secondary sources place the origin in
  **Gartner (2011, Richard Watson)** with **five** strategies —*rehost, refactor, revise, rebuild,
  replace*—, later extended and renamed by AWS to 6 and then to 7 Rs. **Divergence detected in
  the sources**: several pages attribute AWS's nomenclature to Gartner (*replatform*,
  *repurchase*, *retire*), which is not the original list. **Rule: when citing the taxonomy, say which
  list you are talking about (Gartner 5 or AWS 7) or do not cite it.** I could not confirm AWS's list
  verbatim against their official documentation in this pass (two failed fetch attempts);
  **verify in the AWS prescriptive guidance before using it in a formal document** (§8).
- **Mandatory order of evaluation, and this really is a criterion**: `retire` → `retain` → `repurchase` →
  `rehost`/`relocate` → `replatform` → `refactor` → `rebuild`. **Switching off is evaluated before moving,
  and buying before rewriting.** Rewriting is the most expensive option and the one most often
  chosen first.
- **`rebuild` (rewriting from scratch) exists and closes the list**: `legacy-modernization-standards`
  §2.3 treats it as a strategy in its own right and conditions it on the exceptions of
  `refactoring-tech-debt-standards` §6.2. **The two lists are the same**, with this equivalence:
  their *replace* is this `repurchase`, and their `refactor/rearchitect` is this
  `refactor`. When citing, say which list you are talking about.
- **The order is portfolio-level, not system-level**: it sets where you start looking when there are a hundred
  applications. **The specific platform's skill may invert it with written justification**,
  and sometimes must — on IBM i, for instance, modernising in place (ILE, SQL, APIs) is usually
  dramatically cheaper than buying, and almost nobody exhausts that route before proposing
  migration. Inverting the order without writing down why is skipping the criteria, not adapting them.
- `rehost` to the cloud **without a subsequent dated replatform plan** moves the debt and adds an
  invoice: it is accepted only with a written timing reason (data centre closure, hardware end of support).
- **No single R applies to the whole portfolio**: it is decided per application, with the cost of §3.1
  in front of you.

## 4. Standards, exceptions and radar

*(Section 4 of the template —quality and testing— replaced: in a judgement function, the equivalent
quality control is standard governance and its verification.)*

### 4.1 How a technology standard is set

A standard without these five pieces is not a standard, it is a preference:

1. **Scope**: what it applies to and what it explicitly does not.
2. **Reason**: which problem it avoids (support, security, hiring, cost), in one falsifiable sentence.
3. **Owner**: the person who maintains it and to whom the exception is requested.
4. **Date and review**: date of entry into force and of the next review. A standard with no review
   becomes the reason people work around it.
5. **Application to what exists**: if it only applies to new things, say so. Retroactive migration without
   a budget is an undeclared mass exception.

### 4.2 The exception process — **an exception without a date is a new standard**

- **Every exception carries: reason, scope, owner, exit condition and expiry date.**
  **INDEFINITE EXCEPTIONS ARE FORBIDDEN.**
- **Maximum recommended expiry: 12 months.** On expiry there are only two ways out: the standard is met
  or **the standard is changed** (because three exceptions against the same rule mean the rule
  is wrong, not that people are undisciplined).
- The exceptions register is internally public and is reviewed in the same session as the radar.
  **Metric**: number of expired unresolved exceptions. If it grows two quarters in a row, the
  problem is the standard.

### 4.3 The technology radar as an artifact

- Reference format: Thoughtworks's **Technology Radar**, published **twice a year**,
  with four quadrants (**Techniques, Platforms, Tools, Languages and Frameworks**) and four
  rings. **Verified correction: the outer ring is no longer called "Hold" but "Caution"**
  (adopt / trial / assess / **caution**) — if your template or your data says `Hold`, it is
  out of date.
- Tool: Thoughtworks's **Build Your Own Radar**, **AGPL-3.0** (copyright 2015 Bruno
  Trecenti; 2016 Thoughtworks). **Consequence of the AGPL: if it is deployed modified and served over
  the network, the licence's obligations apply** → cross-check with `opensource-licensing-standards`
  before forking it.
- Rules specific to the internal radar: every blip carries **a date and one sentence on why**; a blip in
  `caution` **names the replacement**; and the radar is published **on the same dates as the exceptions
  review**, because they are the same conversation.

## 5. Integration, and build/buy/SaaS

### 5.1 The integration landscape is the invisible debt

- **What prevents switching off an application is almost never the application: it is its integrations.** That
  is why the dependencies column of §3.1 is mandatory and not optional.
- **Every integration has an owner, a contract and known consumers.** An integration with no
  identifiable consumers is the first candidate for retirement, and its retirement is the cheapest
  way to shrink the landscape.
- Choice of topology (**implementation is delegated**):
  - **Point to point**: the default below ~10 integrations. Real cost = n·(n−1)/2 in the
    worst case; it is abandoned when that number stops fitting on a whiteboard.
  - **Bus / centralised integration**: when the problem is mediation and routing, not
    volume. **Declared risk: business logic inside the bus** — it is forbidden in writing or the
    bus becomes the most critical and least testable system in the house.
  - **Events**: when the producer must not know the consumers and eventual consistency
    is acceptable to the business. Implementation → `message-brokers-standards`,
    `microservices-architecture-standards`, `streaming-cdc-standards`.
- **Contract before technology**: who publishes, which schema, what compatibility and what SLA →
  `api-design-standards`, `data-governance-quality-standards`.

### 5.2 Build vs. buy vs. SaaS

It is decided with four questions, in this order. The first is eliminating:

1. **Is it a differentiating capability?** Would a customer choose the organisation because of how it does this?
   If not, **it is not built**. Building your own ERP, CRM or payroll system is the most
   expensive known way of not differentiating.
2. **Total 5-year cost**, not licence price: licence + integration + operation + support +
   people + **the cost of the version that will have to be migrated**. The cost of building includes
   maintaining it for those 5 years; almost no "build" business case includes it, and that is why almost all of them
   win on the spreadsheet and lose in reality.
3. **Vendor dependency**: is the data exportable in a usable format? is there an API? does the
   contract allow auditing? what happens if the price goes up 40 %? → vendor due diligence in
   `grc-compliance-standards` and `bcdr-standards`.
4. **Exit**: **the exit plan is written before signing** (export format, data
   ownership, return deadline, estimated migration cost). Without a written exit plan, SaaS is
   a *one-way* decision disguised as a monthly subscription.

**Additional rule**: customising a bought product beyond its supported configuration point
turns a purchase into a build, with the worst cost profile of both. If it is
needed, the right answer is usually to change the business process or change product.

## 6. Governance, descent to delivery and metrics

### 6.1 Who decides what

| Type of decision | Decided by | Architecture contributes |
|---|---|---|
| Internal design of a system | The team | The applicable standard and a review on request |
| Adoption of technology outside the radar | Team + standard owner | Exception with an expiry (§4.2) |
| New application in the portfolio / purchase | Business owner + architecture | Duplication, total cost, fit with capabilities |
| Switching off an application | Business owner | Dependencies and affected consumers |
| Change to a cross-cutting standard | Architecture board | Proposal and consequences |

- **Threshold, not universal review**: what is *one-way* is reviewed (irreversible spend, personal data,
  long-term vendor dependency, a change affecting more than one team). **Everything else is
  decided in the team and communicated.**
- **Why a committee that reviews everything becomes a bottleneck —with the available
  evidence—**: DORA/*Accelerate*'s finding on approval by an external body (CAB or
  management) is that **external approvals correlate negatively with lead time,
  deployment frequency and time to restore, and do not correlate with change failure
  rate**; DORA states it found no evidence that a formal external process reduces
  failures. **The "2.6× more likely to be a low performer" figure circulates attributed to the 2019 report: I do not
  use it, because I could not verify it against the primary source it is attributed to.** The
  qualitative argument stands without it. Alternative recommended by DORA: **peer review
  during development + automation of controls** → `code-review-standards`, `cicd-standards`.
- Corollary: **an architecture board that approves designs is a CAB under another name.** Its
  job is to set standards, resolve exceptions and arbitrate conflicts between teams; **not
  to approve anybody's work**.

### 6.2 The descent to delivery — **architecture that does not descend to concrete decisions does not exist**

- Every standard materialises in something executable or it does not count: a template in the paved road
  (`platform-engineering-standards`), an IaC module, an admission policy, a CI gate, a
  *fitness function* (`software-architecture-patterns-standards`). **The PDF is not a compliance
  mechanism.**
- **The architect accompanies the first team that applies a new standard.** If nobody from architecture
  has used the standard they wrote, the standard is untested.
- Mandatory link with the ADR: a team's decision that departs from a standard **is written
  as an ADR and as an exception with an expiry** (same fact, two records with different owners).

### 6.3 Metrics for the function (none counts documents)

| Metric | What it diagnoses | Alarm signal |
|---|---|---|
| % of applications with a live owner and a review < 12 months | Inventory health | < 80 % |
| Deviation of inventory cost vs. invoice | Usefulness of the inventory for deciding | > 10 % |
| Number of applications switched off per period | That the function also subtracts | 0 in a year |
| Duplication per non-differentiating capability | Portfolio overlap | Growing |
| Expired unresolved exceptions | Standard misaligned with reality | Grows for 2 quarters |
| Median age of the artifact consulted | Living vs. dead documentation | Nobody consults anything |
| Response time to an architecture query | Whether the function is a service or a customs post | Days |

## 7. Long-term sustainability and prohibitions

- Minimum cadence: **quarterly portfolio review** (TIME state, additions and removals), **radar and
  exceptions half-yearly**, **capability map annually or when the business model changes** (not when
  reorganising).
- **Deprecating standards**: a withdrawn standard is marked as withdrawn with a date; it is not deleted,
  because there are systems built against it.
- Prohibitions:
  - ❌ **A diagram with no owner and no date.** A diagram without both is folklore; it is deleted or adopted.
  - ❌ **A standard with no exception process.** It produces silent non-compliance, which is worse than the
    recorded exception because it is not measured.
  - ❌ **An exception with no expiry date** (§4.2).
  - ❌ **An inventory nobody updates**: if it is not tied to an event that already happens (§3.1), do not
    start it.
  - ❌ **Choosing a framework before a problem.** "We are going to implement TOGAF" is not an objective; "we know which
    applications duplicate the invoicing capability and what they cost" is.
  - ❌ **Ivory tower**: an architect who produces the target and accompanies no implementation.
  - ❌ **An architecture board that approves every design** (§6.1).
  - ❌ **Two sources of truth** for dependencies or for cost (§3.2).
  - ❌ **Rewriting without having evaluated retire and repurchase**, and **rehost without a date for the replatform**.
  - ❌ **Signing SaaS without a written exit plan**.
  - ❌ **Citing framework figures or failure rates without a primary source** in an architecture
    document: it is the fastest way to lose credibility with whoever decides the money.
  - ❌ **Publishing ArchiMate notation or derived material outside the organisation without checking the
    applicable licence** (§2.2).

## 8. Mandatory web verification

Check before pinning anything:

1. **TOGAF**: current edition and corrigenda at `opengroup.org/togaf`; ownership and trademark
   conditions. Here: 10th Edition (2022), 2025 corrigendum in the C220 bundle.
2. **ArchiMate**: current version (3.2, C226, Oct 2022) and **the licence applicable to your specific use**
   at `opengroup.org/legal/licensing` — 90-day evaluation / non-commercial / annual commercial.
   **Legal decision: consult before publishing.**
3. **TIME**: **declared gap** — the primary Gartner note (identifier and year) was not located, nor
   a definition of axes consistent between sources. If formal attribution is needed, consult
   Gartner's library under subscription. **Do not invent the citation.**
4. **The "R"s**: confirm AWS's current list *verbatim* in their prescriptive guidance and, if
   attributed to Gartner, use the original 2011 list (rehost, refactor, revise, rebuild, replace).
   **Not confirmed verbatim in this pass.**
5. **Tools**: status, licence and **pricing** of LeanIX / Ardoq / Bizzdesign — **gap: none
   publishes pricing**; a per-application model in LeanIX and Ardoq, to be confirmed in a quote.
   Archi's licence verified in raw (MIT, `License.txt` in the repository).
6. **Build Your Own Radar**: **AGPL-3.0** licence and current rings (`caution`, not `hold`),
   confirmed as of Aug 2026; re-verify before forking.
7. **Evidence on external approval**: read the cited DORA/*Accelerate* report in its primary
   source before reproducing any figure. **The 2.6× figure is discarded as unverifiable
   against the source it is attributed to.**
8. Figures for "percentage of organisations adopting framework X" and "failure rate of transformation
   programmes": **discarded by default**; used only with a primary study and accessible methodology.

If the web contradicts this document, **the web wins** — flag the discrepancy.
