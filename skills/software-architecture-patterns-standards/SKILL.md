---
name: software-architecture-patterns-standards
description: Standards for choosing and justifying an internal architecture style. Use when deciding modular monolith vs distributing, applying layered, hexagonal/ports-and-adapters, clean or onion architecture, event-driven, pipes-and-filters, plugin/microkernel or space-based styles, drawing module boundaries and dependency rules, bounded contexts and ubiquitous language, CQRS and event sourcing, ADRs (Nygard/MADR templates), C4 model diagrams and Structurizr DSL, ArchUnit or dependency-cruiser fitness functions, ISO/IEC 25010 quality attributes and quality-attribute scenarios, or diagnosing big ball of mud, anemic domain model, shared database and excessive-layering antipatterns.
---

# Software architecture and patterns standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers the **internal design of a system**: choice of architectural style, module boundaries, dependency rules, domain modelling, data and consistency patterns within the deployment, documentation of decisions (ADR), notation (C4), quality attributes and their automatic verification (fitness functions). Triggers: "modular monolith", "hexagonal", "ports and adapters", "clean architecture", "onion", "layers", "event-driven", "pipes and filters", "plugin/microkernel", "space-based", "bounded context", "ubiquitous language", "CQRS", "event sourcing", "dependency rule", "coupling/cohesion", "ADR", "C4", "ArchUnit", "fitness function", "ISO 25010", "big ball of mud".

**Guiding principle — a pattern is the answer to a concrete force.** Before naming a pattern you have to name the force that justifies it (a measurable quality attribute, an expected axis of change, a business or regulatory constraint). **A pattern applied without that force is not architecture: it is accidental complexity**, and it is paid for on every future change. Operational corollary: in the ADR (§6) the section that decides is not "decision", it is "force and consequences".

**Not applicable**:
- `microservices-architecture-standards` (**critical boundary**): **theirs** is all the distributed topology — cutting into separately deployable services, inter-process communication over the network (REST/gRPC/events), contracts between services and their governance, **saga and outbox in their execution**, database per service as an operational rule, distributed resilience (timeouts, circuit breaker, backpressure, DLQ), mTLS, API gateway and service mesh, distributed tracing. **Here** the internal design of a deployment and **the prior decision of whether distribution is needed at all**, plus the business criteria on eventual consistency. Arbitration rule: **if the question is how two processes separated by the network communicate, it is theirs; if it is how the code is structured within one deployment, it belongs here.**
- `api-design-standards` (the **outward contract**: resources, verbs, codes, pagination, contract versioning).
- `data-platform-standards` and `sql-standards` (physical modelling, engine, indexes, migrations, tuning).
- `enterprise-architecture-standards` (fine boundary: **theirs** is the organisation's application landscape, governance, inventory and cross-cutting standards; **here** the design of **one** system).
- `tech-leadership-standards` (the decision to invest, the record and the negotiation; here the technical criteria).
- `refactoring-tech-debt-standards` (**the path**: how you get from the current design to the one this skill decides; here the destination).
- `privacy-engineering-standards` (**theirs** the criteria on the right to erasure against an immutable log, legal basis, minimisation; here only the architectural consequence of choosing event sourcing).
- `performance-engineering-standards` (measurement, budgets and optimisation), `sre-practice-standards` (SLOs, error budget, operation), `testing-qa-standards` (test strategy), and the **language skills** (how the pattern is implemented in each stack).

## 2. Default decisions

> Verify the latest version/status on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Topology | **Modular monolith** (one deployment, modules with hard boundaries) | Distribute only with a demonstrated force → `microservices-architecture-standards` |
| Internal style | **Ports and adapters** (domain with no dependencies on technology) | Simple layers in CRUD with no domain logic; *pipes and filters* in data transformation; plugin/microkernel if variability is the dominant force |
| Module boundary | **By business domain** (vertical) | Never by technical layer as a first-level boundary |
| Domain model | **Bounded context + ubiquitous language** (strategic DDD) | Tactical DDD only where there are real invariants (§4) |
| Read/write | A single model | **CQRS** only with measured asymmetry of load or of model shape |
| Persistence | Current state in a relational DB | **Event sourcing** only with a real audit/temporality requirement and an ADR on versioning + deletion (§5) |
| Decisions | **ADR mandatory** for every *one-way* decision (Nygard or MADR template) | — |
| Notation | **C4 model** (Simon Brown; site and example diagrams under **CC BY 4.0**) | UML where the team already masters it |
| Diagrams | **Model as code** (Structurizr DSL, or PlantUML/Mermaid in the repo) | Graphical tool only if it is regenerated from source |
| Quality attributes | **ISO/IEC 25010:2023** (2nd ed., 15-Nov-2023) as a checklist | — |
| Verification | **Fitness functions in CI** (ArchUnit — Apache-2.0 — on the JVM; equivalent per stack) | — |

### 2.1 The prior decision: modular monolith by default

It is the most important decision and the cheapest to get right. **Default: one deployment, modules with explicit boundaries verified in CI.** It is not "monolith out of laziness": it is the topology that preserves the option to distribute later (extracting an already isolated module) without paying today for network latency, eventual consistency, partial failures and ×N operational cost.

Forces that **do** justify leaving the modular monolith (documented in an ADR; the resulting design is governed by `microservices-architecture-standards`):
- **Organisational**: several teams that need to deploy at different cadences and collide in the same repo/release.
- **Divergent scale or failure isolation** between domains, **measured** (not assumed): one domain needs a different resource curve or cannot go down with the rest.
- **Compliance or lifecycle**: a domain requires data, deployment or audit isolation by regulation.
- **Mandatory technological heterogeneity** (a domain requires a runtime that does not fit in the main process).

Forces that do **not** justify it: "it is fashionable", "it will scale some day", "that way the code is clean", "we want to use Kubernetes". A badly modularised monolith does not improve by distributing it: it becomes a distributed monolith, with the same couplings plus network latency on top.

**Conway's law** (Melvin E. Conway, *"How Do Committees Invent?"*, **Datamation 14(5):28–31, April 1968**; the name "Conway's law" is later — attributed to Fred Brooks in *The Mythical Man-Month*, with a prior claim by George Mealy in 1968): organisations produce designs that **copy their communication structure**. Practical consequence: the chosen architecture and the org chart have to be coherent; if you cannot change the teams, your real design margin is smaller than you think. **Honest nuance**: the original statement is one of correspondence, not causality — it does not claim that communication *causes* the structure.

## 3. Styles and the criteria for choosing them

There is no "best" style: there is the style that addresses the dominant force. Pick one as the base and apply the others as local patterns.

| Style | Force it addresses | Cost it imposes | Forbidden when |
|---|---|---|---|
| **Layers** | Minimal order, fast onboarding | Technical boundaries, not domain ones; tends to a ball of mud with lasagne on top | There is rich domain logic and several axes of change |
| **Ports and adapters / clean / onion** | Isolating the domain from technology; testability without infra | Indirection and mapping between models | The "domain" is pure CRUD (indirection with no benefit) |
| **Event-driven** | Temporal decoupling, extensibility, asynchronous reaction | Non-linear flow, hard debugging and ordering, eventual consistency | The use case demands an immediate, transactional answer |
| **Pipes and filters** | Data transformation in stages, stage reusability | Shared state is hard; accumulated latency | The process needs to decide with global context |
| **Plugin / microkernel** | Known variability: same core, many variants | An extension contract that has to be versioned and sustained | There are no real variants yet (speculative abstraction) |
| **Space-based** | Extreme scaling with contention on the database | Very high in-memory replication/consistency complexity | The contention has not been measured |

### 3.1 Hexagonal, clean and onion: the honesty required

- **Ports and adapters (hexagonal)**: **Alistair Cockburn** (documented on the Portland wiki; the name "Ports and Adapters" adopted around 2005; book *Hexagonal Architecture Explained*, with Juan Manuel Garrido de Paz). The hexagon does not mean "six": it was chosen so several ports could be drawn without the false linearity of layers.
- **Onion**: **Jeffrey Palermo** (2008). **Clean**: **Robert C. Martin** (2012; book *Clean Architecture*, 2017).
- **To a large extent they are the same idea under different names**: domain at the centre, technology at the edge and **all source-code dependencies pointing inwards**. Cockburn himself says so in *Hexagonal Architecture Explained*: onion and clean have the same dependency structure as ports and adapters, with two differences — **they do not require specifying ports** and **they add layers that ports and adapters does not impose**.
- **Criteria**: choose **one** nomenclature per system and write it in the ADR. Arguing about which of the three is "the right one" produces no quality attribute at all. What does matter and is verifiable in CI: **the domain names no technology**.

### 3.2 The dependency rule and its practical implication

Code dependencies point **towards the domain**; when the call goes the other way, it is inverted with an interface **declared by the domain** and implemented by the adapter. Implications that are actually felt:
- The domain **does not import** the ORM, the HTTP client, the web framework or the cloud provider's SDK. If your domain entity carries persistence annotations, you do not have this architecture: you have layers with a pretty name.
- Domain types **do not cross** outwards without translation; the adapter maps. The cost of mapping is the price of the rule — if you are not willing to pay it, choose layers and say so.
- **The rule is verified in CI or it does not exist** (§4). A dependency rule sustained only by human review erodes within months.

### 3.3 Modules: coupling, cohesion and what each module hides

- **Boundaries by domain, not by technical layer**. An `orders` module containing its own controller, domain and persistence is a boundary; a `repositories` module containing the repositories of eight domains is not.
- **A module is defined by what it hides**, not by what it groups: **David L. Parnas**, *"On the Criteria To Be Used in Decomposing Systems into Modules"*, **CACM 15(12):1053–1058, Dec. 1972** — decompose by **design decisions that are difficult or likely to change**, hiding each one behind a module, and **not** by the data flow diagram. Pocket criterion: if a foreseeable change forces you to touch several modules, the boundary is in the wrong place.
- **Precise coupling vocabulary**: the recent published taxonomy is that of **Vlad Khononov**, *Balancing Coupling in Software Design* (Addison-Wesley, **2024**; associated material at `coupling.dev`), which synthesises 1970s *structured design* and 1990s *connascence* into three dimensions:
  - **Integration strength** (how much knowledge is shared across the boundary), with four levels from higher to lower: **intrusive → functional → model → contract**. *Intrusive* is integrating through the other's internal details (reading its table, touching its private parts).
  - **Distance** (effort of changing both sides: same class < same module < same deployment < another service/team).
  - **Volatility** (how frequently that is expected to change).
  - Rule: **the greater the distance, the less knowledge should be shared** — that is why intrusive coupling between services is catastrophic and between two classes of the same module may be irrelevant. Strong coupling is not a sin in itself; it is when it coincides with large distance **and** high volatility.
- **Cohesion**: what changes together lives together. If two modules always show up in the same commit, either they are one or the boundary is in the wrong place (measurable signal: change coupling in the Git history, §4).

### 3.4 DDD: what it really contributes

- **The strategic part is what it contributes**: **bounded context** (within it a term means one single thing) and **ubiquitous language** (the same vocabulary in conversation, code and tests). It is the best available tool to **decide where the boundary goes** — and the boundary is the decision that is most expensive to correct.
- **Honest warning**: **tactical DDD is applied badly more often than it is applied well**. Aggregates, entities, value objects, repositories and domain services are useful **where there are business invariants to protect**; applied to a CRUD they produce ceremony with no benefit and an anaemic model with DDD names.
- Criteria: apply tactical **per subdomain**, and only in the **core** (the one that gives competitive advantage). In supporting and generic subdomains: the simplest thing that works, or buy instead of build.
- The anaemic model (**Martin Fowler, bliki, 25-Nov-2003**, discussed with Eric Evans) is not a failure if you have chosen it: it is a *transaction script*. It is a failure when you claim it is DDD.

## 4. Verification: quality attributes and fitness functions

**The real input to design is the quality attributes, not the patterns.** A non-functional requirement without a scenario is not verifiable and therefore does not constrain the design.

- **Reference catalogue: ISO/IEC 25010:2023** (2nd edition, published **15-Nov-2023**, ISO/IEC JTC 1/SC 7), **nine characteristics**. Changes from 2011 that you have to know: **Safety is added**; **Usability → Interaction capability** and **Portability → Flexibility**; the rest of the old model was split into **ISO/IEC 25002** (models overview) and **ISO/IEC 25019** (quality in use). Citing "ISO 25010" with the 2011 characteristics is a factual error.
- **Quality attribute scenario** (minimum format, ATAM/SEI style): *source → stimulus → artifact → environment → response → **response measure***. Without the response measure there is no scenario, there is a wish. Example: "under 3× the usual peak (stimulus) during business hours (environment), the listing responds below 300 ms p95 (measure)".
- **Fitness functions**: term introduced in ***Building Evolutionary Architectures*** (Neal Ford, Rebecca Parsons, Patrick Kua; O'Reilly **2017**; 2nd ed. **2023** with Pramod Sadalage). Definition from the 2nd edition: *"any mechanism that provides an objective integrity assessment of some architecture characteristic or combination of characteristics"*. Useful categories: **atomic vs holistic**, **triggered vs continuous**.
- **Minimum** fitness functions that must break the build:
  - **Dependency rules between modules and layers** (ArchUnit on the JVM — Apache-2.0; equivalents per stack: dependency-cruiser, import-linter, deptrac, `go list`/`depguard`, `cargo-deny`). Without this, the documented and the real architecture diverge.
  - **Absence of cycles** between modules.
  - **Ban on importing technology from the domain** (vetoed packages).
  - Performance and size budgets where the attribute demands it (delegate the method to `performance-engineering-standards`).
- Tests: the domain is tested **without infrastructure** (that is the practical reason for ports and adapters); the adapters are tested against the real technology (ephemeral containers). The full strategy belongs to `testing-qa-standards`.
- **Erosion signal**: change coupling in the history (files from different modules that always change together). It is evidence, not opinion — cross it with the debt criteria of `refactoring-tech-debt-standards`.

## 5. Data, consistency and expensive decisions

### CQRS
- **What it really solves**: the asymmetry between the model that needs to **protect invariants on write** and the one that needs to **serve queries** with a different shape, load or SLA. Lineage: **CQS** by **Bertrand Meyer** (*Object-Oriented Software Construction*, 1988) at method level; **CQRS** raises it to architectural level and is by **Greg Young** (also promoted by Udi Dahan; "CQRS Documents" paper from 2010).
- **What it costs**: two models to maintain and **eventual consistency visible to the user** if the projections are asynchronous. Fowler himself warns that in most systems CQRS adds risky complexity.
- **Criteria**: apply it **per bounded context**, never "across the whole system". Without measured asymmetry, it is not applied. CQRS does **not imply** two databases or event sourcing.

### Event sourcing — an almost irreversible decision
It stores every state change as a sequence of events and reconstructs the state by replaying them (**Martin Fowler**, *Event Sourcing*, **12-Dec-2005**; Fowler himself marks that material as a draft). It solves full audit, querying state at any instant and reprojection into new models.

**It is almost irreversible because the log is the system.** Before adopting it, the ADR must answer all three, with design:
1. **Event versioning**: the schema will change. Strategy decided up front (upcasting on read, versioned events, copy-and-transform of the stream) and **forbidden** to change the meaning of an already published event.
2. **Reprojection**: cost and time to rebuild every projection from scratch at the volume expected **3 years out**, and snapshots if it does not fit in the operational window.
3. **Deletion of personal data against an immutable log**: the right to erasure collides head-on with a log that by design is not deleted. Usual architectural technique: **crypto-shredding** (encrypt the subject's data with a per-subject key and destroy the key), or keep the personal data **outside the log** and reference it by identifier. **The legal and sufficiency criteria belong to `privacy-engineering-standards`**: here we only establish that **without that written answer event sourcing is not adopted**.

If what you need is "to know who changed what", an audit table or CDC is almost always enough: far cheaper and reversible.

### Consistency and data patterns
- **Within one deployment**: a database transaction. Do not invent eventual consistency where local ACID solves it — it is the most common form of accidental complexity.
- **Database per service, saga and outbox**: their **execution** belongs to `microservices-architecture-standards`. What is decided **here** is what comes first: **whether the business tolerates eventual consistency**, and that is not for the architect to decide alone.
- **When eventual consistency is acceptable** (business criteria, with the product owner in the ADR): the inconsistency window is **bounded and communicable**; there is a possible **business compensation** (cancel, refund, retry) and someone has accepted it in writing; the UX shows the intermediate state instead of lying ("in progress", not "done"); and no legal or security requirement demands a consistent read (balance, access control, stock with penalised overselling).
- **When it is not**: money or security invariants that would break during the window, and flows where compensation does not exist in the real world (email sent, goods shipped).

## 6. Decisions and documentation (§6 replaced: here "performance and operability" would be artificial — performance is treated as a quality attribute in §4 and its method belongs to `performance-engineering-standards`)

- **ADR mandatory** for every *one-way* decision: topology, base style, context boundaries, persistence (event sourcing, engine), internal contract format, adoption of a platform that is hard to abandon. Origin of the format: **Michael Nygard, "Documenting Architecture Decisions", 15-Nov-2011** (Cognitect), with lineage in Philippe Kruchten's *decision view*. Nygard template: **title, status, context, decision, consequences**; **MADR** adds *decision drivers* and *considered options* (MADR 3.x; in 3.0.0-beta it was renamed to "Markdown **Any** Decision Records").
- **ADR versioned alongside the code**, reviewed in a PR, **immutable once accepted**: it is not edited, it is **superseded** by another ADR. Minimum states: proposed → accepted → deprecated/superseded.
- **One-way vs reversible doors**: reversible ones are decided fast, at the lowest possible level and without ceremony; irreversible ones call for an ADR, alternatives and an explicit estimate of the exit cost. **Misclassifying a door is the expensive mistake**: treating an irreversible one as reversible is paid for over years; the opposite paralyses the team.
- **Default notation: C4 model** (created by **Simon Brown**; the site and the example diagrams are under **Creative Commons Attribution 4.0 International**). Four levels: **System Context, Container, Component, Code**. In practice: always keep **context and containers**; **components** only where it helps; **code** almost never (the IDE generates it better than you).
- **A diagram that goes stale on its own must not exist.** A diagram is valid if (a) it is generated from the code or from a versioned model (Structurizr DSL, PlantUML, Mermaid in the repo), or (b) it has a **named owner and a review date**. If it meets neither, delete it: a false diagram is worse than none because it is used to decide.
- Document the **why**, not the how: the how is told by the code; the why is lost as soon as the person who knew it leaves.

## 7. Sustainability, antipatterns and prohibitions

**Evolution**: architecture is judged by how much it eases the next change, not by its elegance. Review boundaries when the erosion signals appear (§4) and apply the path from `refactoring-tech-debt-standards`.

Antipatterns, with the consequence they cause:
- **Big Ball of Mud** (*Big Ball of Mud*, **Brian Foote and Joseph Yoder, PLoP '97**, Sept. 1997; also ch. 29 of *PLoPD 4*): structure dictated by convenience, not by design. Consequence: unpredictable cost of change and knowledge concentrated in a few people.
- **Lasagne architecture / excessive layering**: layers that only delegate (*pass-through* methods and classes). Consequence: each change touches N files without adding value. Known variant: *architecture sinkhole*, requests that traverse every layer with no logic.
- **Anaemic service/domain**: entities with no behaviour and logic scattered across services. Consequence: invariants with no owner, duplicated and divergent. Distributed, it multiplies.
- **Shared database** between modules or services: the schema becomes the real contract and nobody can change it. Consequence: *intrusive* coupling at maximum distance (§3.3), the worst possible quadrant.
- **`Enterprise`/`Manager`/`Helper`/`Util` in the name**: a name that does not reveal responsibility. Consequence: junk drawer, zero cohesion, impossible to split later.
- **Distributed monolith**: modules that are deployed and versioned together, but over the network. Consequence: all the costs of distributing, none of its advantages.

### List of prohibitions
- ❌ **FORBIDDEN to apply a pattern without naming the concrete force that justifies it** in the ADR (quality attribute, axis of change, legal constraint).
- ❌ Microservices by default, or without an ADR comparing against the modular monolith (§2.1).
- ❌ **Event sourcing without a written plan for event versioning, reprojection and deletion of personal data.**
- ❌ CQRS "across the whole system" or without measured asymmetry between read and write.
- ❌ Speculative abstraction: an interface with a single implementation "just in case", a plugin with no plugins, a portability layer for a database that will never be changed.
- ❌ First-level boundaries by technical layer (`controllers/`, `services/`, `repositories/` as the domain structure).
- ❌ A domain that imports a framework, ORM, cloud SDK or HTTP client.
- ❌ Dependency rules not verified in CI (documentation without a fitness function = fiction).
- ❌ **A diagram with no owner or review date, or not generated from a versioned source.**
- ❌ An ADR edited after being accepted (it is superseded, not rewritten) or a *one-way* decision without an ADR.
- ❌ Eventual consistency introduced without business/product accepting it in writing and without defined compensation.
- ❌ A distributed transaction (2PC/XA) used to paper over a badly cut boundary.
- ❌ Citing "ISO 25010" with the characteristics of the 2011 edition (§4).
- ❌ Migrating to a new pattern without tests covering the behaviour: **it is trading one debt for a bigger one** (see `refactoring-tech-debt-standards`).

## 8. Mandatory web verification

Before pinning anything from this document in a real deliverable, **verify with WebSearch/WebFetch** (the data is from August 2026):

1. **ISO/IEC 25010**: is the 2023 2nd ed. still in force? Status of ISO/IEC 25002 and 25019? The exact characteristics are cited from the purchased standard, not from blogs (the websites diverge when listing them).
2. **C4 model**: current licence of the site and the materials (CC BY 4.0 at the verification date), status of Structurizr (DSL, on-premises/cloud versions and their pricing model).
3. **ArchUnit** and the equivalent for your stack: latest version, licence read from the raw `LICENSE` (not from the README or aggregators) and compatibility with the language version.
4. **MADR / adr-tools**: current template version and real maintenance of the repository (last commit), not the GitHub star count. `api.github.com` returns 403 unauthenticated: use the web or the release Atom feeds.
5. **Cited bibliography**: current editions of *Fundamentals of Software Architecture* (2nd ed., Apr 2025), *Building Evolutionary Architectures* (2nd ed., 2023) and *Balancing Coupling in Software Design* (2024) before attributing a term to a specific edition.
6. **Figures**: this domain drags folklore along. **No figure is written without a locatable primary study and methodology**. Already discarded here for lack of a primary source: the "10×/100× cost per phase" (dead trail in internal IBM notes from 1981 via Pressman; documented by Bossavit, *The Leprechauns of Software Engineering*) and "80 % of the cost is maintenance" (it entered the literature as an informal estimate cited by Lientz & Swanson, not as a measurement).
7. **Boundary with `microservices-architecture-standards`**: if that skill changes scope, re-verify the arbitration rule of §1 in both directions.

If the web contradicts this document, **the web wins** — flag the discrepancy.
