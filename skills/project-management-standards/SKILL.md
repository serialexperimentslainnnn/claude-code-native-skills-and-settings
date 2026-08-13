---
name: project-management-standards
description: Use when work is organized as a project or delivery programme — choosing predictive, agile or hybrid delivery for a given piece of work, writing a project charter, statement of work or product backlog, declaring which of scope, time, cost, quality and risk is fixed and which floats, estimating with ranges instead of single dates, relative estimation and story points, Monte Carlo forecasting over throughput data, planning fallacy and reference class forecasting, WIP limits, lead time and cycle time, cumulative flow and burnup charts, a RAID or risk-and-assumption log with owner and trigger, cross-team dependency tracking and critical path, a RACI and stakeholder communication plan, RAG status reports and watermelon reporting, milestone versus incremental delivery, change-request and scope-change control, decision records for management decisions, project closure with acceptance criteria and handover to operations, retrospectives with owned actions, PMBOK Guide Eighth Edition, PRINCE2 7, the Scrum Guide, SAFe, Kanban, or citing Standish CHAOS Report figures.
---

# Project and delivery management standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **how already-decided work is delivered**: choice of delivery approach, commitments and how
they are phrased, estimation and forecasting, flow management, risks and assumptions, cross-team
dependencies, stakeholder communication, decision records and closure with handover to operations.

Triggers: "project charter", "charter", "SOW", "scope", "iron triangle", "estimation", "story
points", "velocity", "Monte Carlo", "throughput", "lead time", "cycle time", "WIP", "burnup",
"critical path", "dependencies", "RAID", "risk register", "assumptions", "RACI", "communication
plan", "status report", "RAG", "traffic light", "milestone", "change control", "change request",
"retrospective", "project closure", "handover to operations", "PMBOK", "PRINCE2", "Scrum Guide",
"SAFe", "Kanban", "CHAOS Report".

**Governing principle**: **deliver value with known constraints and recorded decisions — do not
fill in templates.** A management artifact is only justified if it **changes a decision**: if the
risk register has not altered any priority in three months, it is not a risk register, it is a
document. Falsifiable test applicable to any proposed artifact or ceremony: **name the decision
it enables, who takes it and how many times it has actually been taken in the last quarter.**
Whatever does not pass is removed.

Corollary: **uncertainty is not eliminated by declaring a date; it is bounded and declared.**

**Not applicable**:
- `product-discovery-standards`: **what is built and why** — problem,
  user, hypothesis, validation, prioritisation by value and the decision to kill an idea. Here,
  **how what has already been decided is delivered**. Hard boundary: if the discussion is *"is this
  worth it?"*, it is not this skill; if it is *"when and with what risk will it be ready?"*, it is.
- `tech-leadership-standards`: technical decisions, team design,
  professional development, the *career ladder* and the one-to-one conversation. People are not
  managed here, work is.
- `sre-practice-standards`: **DORA metrics and unplanned work are hers**, as are SLOs,
  error budgets and capacity planning. Here the unplanned-work figure is used as a **capacity
  constraint** when committing, it is not defined.
- `itsm-itil-standards`: **the service, its catalogue, the SLA and continuous operation**.
  Reciprocal: **the project delivers, the service operates.** The handover is an artifact with
  acceptance criteria (canonical list in her §3) and **a project that delivers something nobody can
  operate has not finished**: without a service owner, runbook, alert and tested restore, the
  project is still open.
- `erp-sap-standards` and the packaged-vertical skills: **when the project is implementing
  third-party software, three of the five variables in §2 stop being negotiable here** — the
  date may be set by an end of maintenance, the scope is bounded by what the package does out of
  the box, and the cost depends on a licence metric that changes with architecture decisions.
  **That is not just any external constraint: it is the project's frame**, and it is read in its
  skill before committing to anything here.
- `testing-qa-standards` and `code-review-standards`: the technical ***Definition of Done*
  lives there** — coverage, gates, merge criteria. Here the **delivery** DoD (accepted by the
  stakeholder, deployed, operable, communicated). They are not duplicated: the management DoD
  **includes by reference** the technical one, it does not rewrite it.
- `git-workflow-standards`: PR size, branches, versioning and releases. The integration cadence is
  hers; here its consequences on flow.
- `cicd-standards`: pipeline and deployment automation.
- `enterprise-architecture-standards`: capability roadmap, architecture
  governance and the application portfolio. The **project** portfolio intersects with it: which
  project touches which capability.
- `finops-standards`: **cost as a measured constraint** — cloud budget,
  unit economics, spend forecasting. Here cost is one of the variables of the commitment; its
  modelling and control belong there.
- `grc-compliance-standards`: regulatory obligations that constrain scope and the formal approval
  evidence required by a framework.
- `refactoring-tech-debt-standards`: **what debt exists, what its interest costs and which
  technique pays it off is hers**; **how that work is funded within the delivery is ours** —
  a fixed percentage of capacity, opportunism or a dedicated project, and the negotiation with
  stakeholders. A warning both share and that this skill must hold under pressure: **the
  dedicated "clean-up" project usually fails** because it competes with features and loses;
  sustained allocation of capacity is what does work.
- `software-architecture-patterns-standards`: the technical criteria for style, boundaries and
  recorded decisions are hers; here the plan, the risk and the date commitment surrounding that
  decision.

## 2. Default decisions

> Verify on the web the current editions, ownership and prices before committing to them in a real
> project (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Delivery approach | **Iterative with a deliverable increment** (Scrum or Kanban depending on demand variability) | Predictive when scope is contractually fixed and the cost of late change is low |
| Framework cited in documents | **Scrum Guide** (free) and **Kanban / flow metrics** | PMBOK/PRINCE2 only if the client or the tender requires it |
| Unit of commitment | **Deployed and accepted increment** | A documentary milestone **only** with an explicit contractual obligation |
| Shape of a date | **Range with a probability** ("85 % before 12 Nov") | A single date **only** if it is an imposed external constraint, and then scope floats |
| Forecasting method | **Monte Carlo over historical throughput** (≥ 8-12 periods) | Relative estimation + velocity if there is no history; absolute estimation in hours only for known, bounded tasks |
| Variable that floats | **Scope**, declared in writing in the charter | Cost (adding people rarely helps) or quality (**never**: forbidden in §7) |
| Flow management | **Explicit WIP limit per column**, reviewed monthly | — |
| Risk register | **Living RAID** with owner, trigger and review date | — |
| Decision record | **ADR for technical matters** + **management decision record** with the same format | — |
| Status report | **Status by observable evidence**, not by subjective colour | RAG **only** with a published numeric criterion that determines the colour |
| Headline metric | **Item lead time and probabilistic date forecast** | — |
| Metric forbidden as a target | Velocity, people utilisation, hours booked (§7) | — |

**Actual state of the frameworks (verified Aug 2026, re-verify §8)**:
- **PMI / PMBOK**: PMI's official standards page lists **A Guide to the Project Management
  Body of Knowledge (PMBOK Guide) — Eighth Edition** together with *The Standard for Project
  Management*; it keeps the 7th edition's principles and performance domains and reintroduces
  process guidance in a non-prescriptive way. **Paid** (historically with the PDF included in PMI
  membership).
  **Declared discrepancy**: the exact publication dates (Nov 2025 vs. early 2026) and the PMP exam
  update date come from training blogs and **contradict each other**; the PDF of the
  index hosted on pmi.org carries a Sep 2025 stamp. **Do not cite a date without confirming it on
  pmi.org.** The PMP exam is governed by the *Examination Content Outline*, not by the PMBOK: they
  are different objects.
- **PRINCE2**: **owned by PeopleCert**, which acquired AXELOS (acquisition completed in Jul 2021;
  before that it was a *joint venture* of the UK Cabinet Office and Capita). Current edition
  **PRINCE2 7**, available since **Sep 2023**; the "themes" were renamed **practices**. **Paid
  material**: the manual is included with the exam and **cannot be reproduced in internal
  documentation**.
- **Scrum Guide**: current version **November 2020**, free at `scrumguides.org`, maintained by
  Schwaber and Sutherland independently of any company. **It is the only framework in this list that
  can be quoted and redistributed at no cost**; scrum.org and Scrum Alliance publish commentary, not
  the standard.
- **SAFe**: **paid and with a trademark licence**. Scaled Agile **has abandoned version numbers**:
  6.0 was the last numbered one and it is now published by date (`[year].[month]`), with the current
  brand **AI-Native SAFe** (Jun 2026 announcement). **Practical consequence: writing "SAFe 7" in a
  document is a factual error.** Verify the exact name and release date before citing it.
- **Citability rule**: in internal documentation or in a tender response, **cite the Scrum
  Guide or describe the process in your own vocabulary**. PMBOK, PRINCE2 and SAFe are mentioned as
  references, never transcribed.

**Famous figures: what is NOT used as data.**
- ❌ **Standish Group / CHAOS Report**. It is the canonical example of a famous figure with a
  questioned methodology. **Eveleens and Verhoef, "The Rise and Fall of the Chaos Report Figures",
  *IEEE Software* 27(1):30-36, Jan 2010** (DOI 10.1109/MS.2009.154) document four flaws: misleading
  definitions based only on estimation accuracy, a one-sided accuracy measure, perverse incentives,
  and aggregation with unknown bias; applying Standish's definitions to 5,457 forecasts over
  1,211 real projects, the results did not reproduce Standish's. Add that **the raw
  data and the sampling frame are not public** and that the original design (asking IT executives
  for failure stories) introduces selection bias. **Last edition: CHAOS 2020**, so any
  "CHAOS 2025 figure" is recycled. **Permitted use**: as a *direction*, explicitly citing the
  report, its year and the Eveleens-Verhoef critique. **Forbidden use**: as a percentage in a
  justification, a slide or an investment decision.
- ❌ **"70 % of transformations fail"** and variants. It circulates with no locatable primary study.
  **It is not written.**
- ✅ **What is citable with a source**: the **planning fallacy**, named
  by **Kahneman and Tversky, "Intuitive Prediction: Biases and Corrective Procedures", TIMS Studies
  in Management Science 12:313-327 (1979)** — the systematic tendency to underestimate time, cost
  and risk even with direct experience of similar cases; and its correction, the **outside view /
  *reference class forecasting*** (Lovallo and Kahneman 2003; Flyvbjerg 2008, *European Planning
  Studies* 16(1):3-21), endorsed by the American Planning Association since 2005. **There is recent
  criticism** of RCF (*Production Planning & Control*, 2025): its experimental basis is limited and
  in practice it is applied as a *post hoc* surcharge. Cite it with that reservation, not as a law.

## 3. Structure and conventions

### Choosing the approach: by the nature of the work, not by fashion

It is decided with these four questions, answered in writing in the charter. **There is no scoring:
if any answer falls in the right-hand column, the purely predictive approach is ruled out.**

| Question | Predictive suitable if… | Iterative suitable if… |
|---|---|---|
| Are the requirements known in enough detail to build? | Yes, and they are stable | No, or they will be learned by using the product |
| How much does it cost to change your mind late? | Little (build-to-plan, migration with a fixed destination) | A lot (product with users, unknown integration) |
| Is there a contractual or regulatory obligation of fixed scope and date? | Yes | No |
| Can value be delivered in usable chunks? | No (a certification; **the final cutover** of a migration) | Yes |

> **Nuance that `migration-projects-standards` forces**: *migration* is not a synonym for
> *indivisible*. What is indivisible is **the cutover**, and its default is **by waves**, with the
> first deliberately small and reversible; the single cutover only with its conditions verified.
> Treating the whole project as one block is what produces the *big bang* both skills forbid.

**Honest hybrid**: the project has **phases of different nature** and each uses its own approach,
with the boundary declared — e.g. hardware and civil works predictive with a delivery date, software
on top iterative with floating scope. It is written down which is which and what is committed in
each.

**Hybrid as an excuse** (recognisable and vetoed): it runs in sprints but **the scope, the date and
the cost stay fixed from day one**. That is not hybrid, it is predictive with ceremonies: you pay
the cost of both (the overhead of iteration and the rigidity of the plan) without getting the
benefit of either. **Diagnostic symptom**: there is a "prioritised" backlog in which nothing has
ever been deprioritised.

### The triangle and its honest version

Five variables, not three: **scope, time, cost, quality and risk**. Rule:

> **At most two are fixed. At least one floats, and which one is declared in writing, in the
> charter, signed by whoever pays.**

- **Quality is not a variable that floats.** Cutting quality does not free time: it brings it
  forward and charges it with interest in operations. What can float is the **scope of quality**
  (which scenarios are supported, which browsers, what load), explicitly declared — not the rigour
  applied to what is delivered.
- **Risk is the variable that gets forgotten and the one that explodes.** Compressing a schedule
  without reducing scope does not make the work disappear: it turns it into tacitly accepted risk.
  If it is accepted, it is accepted **in writing and with a name** (`grc-compliance-standards` for
  the formalism of risk acceptance).
- Sentence that must appear literally in the charter: *"X is fixed. Y floats. In case of conflict, Y
  is sacrificed and Z decides."* Without it, at the first conflict quality will be sacrificed
  silently.

### Estimation and forecasting

1. **Absolute estimates fail systematically and directionally**, not randomly: it is the planning
   fallacy (§2, Kahneman and Tversky 1979). Consequence: **averaging optimistic estimates does not
   correct them**; external distributional information must be introduced.
2. **Relative estimation** (sizes, points) to order and size the backlog. **It is never converted
   to hours or euros**: the conversion reintroduces the bias and adds false precision.
3. **Probabilistic forecasting as a defensible method**: Monte Carlo over **historical throughput**
   (items finished per period) answers *"when will N items be ready?"* and *"how many items by
   date D?"* with probabilities. Hard requirements for the result to mean anything:
   - **≥ 8-12 periods** of history from the **same team and the same type of work**.
   - **A stable process with limited WIP**. Without a WIP limit there is no stable flow and the
     forecast is noise formatted as a chart.
   - **Re-run every 1-2 weeks**; a forecast is perishable, not a commitment.
   - Publish **percentiles 50 / 85 / 95**, not the mean. The mean of a long-tailed distribution
     is not a useful date.
4. **Outside view before committing**: find 3-5 comparable finished pieces of work and their real
   duration. If the internal estimate is better than **all** the comparables, the estimate is wrong —
   not the world.
5. **Commitment rule, no exceptions**:

   > **No date is committed without a range.** A single date is a range whose interval has been
   > hidden, and it is always read as the 50th percentile presented as the 95th.

   Valid formulation: *"85 % probability of being ready before 12 Nov; 50 % before 28 Oct"*.
   Invalid formulation: *"it will be ready on 28 October"*.
6. **Decomposition as quality control of the estimate**: if an item cannot be decomposed,
   it is not understood; **estimating it in hours is simulating knowledge** (forbidden, §7). It is
   first turned into a *spike* with a fixed timebox and a documented result.
7. **Estimation costs money.** If the work is homogeneous and there is history, **counting items
   forecasts just as well as estimating them**: stopping estimating is a legitimate and measurable
   decision.

### Flow

- **WIP limited per column** and visible. The justification is arithmetic, not cultural: by Little's
  law, `lead time = WIP / throughput`; with throughput given, **doubling WIP doubles lead time
  without delivering more**. Every additional piece of work in progress is work finished later.
- **Minimum public flow metrics**: `lead time` (from the commitment to the customer to
  delivery — it is what the customer experiences), `cycle time` (from when work starts),
  `throughput`, **age of work in progress** (the only one that allows acting *today*: an item that
  exceeds the 85th percentile of cycle time is escalated before it becomes a surprise) and
  **% of unplanned work** (`sre-practice-standards` defines it; here it is subtracted from
  committable capacity).
- **People utilisation is counterproductive as a target, and this is queueing theory, not opinion**:
  in any system with variability, waiting time grows non-linearly with occupancy
  and tends to infinity as it approaches 100 %. Planning at 100 % occupancy **guarantees** that
  any unforeseen event propagates as delay. What is optimised is the flow of the **work**, not the
  occupancy of the **people**. A team with slack delivers sooner; a saturated one delivers late and
  with more defects.
- **Rework delay**: account for rework as a category of its own. An apparently healthy flow
  with 30 % rework is not a healthy flow.

### Risks and assumptions: a living register or it does not exist

A register that is written at the start and never looked at again is a liability: it gives false
coverage. Mandatory minimum format per entry — **an entry with no `trigger` and no `owner` is not
accepted**:

```yaml
- id: R-014
  type: risk                         # risk | assumption | issue | dependency
  statement: "If supplier X does not deliver the API before 30 Sep, the payments module cannot start"
  owner: name.surname                # person with authority to act, not the PM by default
  trigger: "30 Sep with no supplier test environment"   # observable and dated
  probability: medium                # or qualitative, but consistent across the register
  impact: "3 weeks' delay on the payments milestone"    # quantified
  response: "Mitigate: build an API simulator (5 d)"    # avoid|mitigate|transfer|accept
  action_by: 2026-09-15              # a date, not 'in progress'
  status: open
  reviewed: 2026-08-20
```

- **An assumption is a risk with its probability set to 1 for convenience.** Every assumption
  carries an invalidation trigger; when it fires, it becomes a risk or an issue the same day.
- **Fortnightly review with a quorum**; each entry is closed, reassessed or changes owner. An entry
  unreviewed for two cycles is escalated: either it matters, or it is deleted.
- **Accepted risk = recorded decision** (below), with the name of whoever accepts it. "We'll live
  with it" said in a meeting is not risk acceptance.

### Cross-team dependencies: the dominant cause of real delay

In organisations with several teams, **time is lost waiting, not executing**. The average
execution of a task rarely explains the delay; the queue in front of the team you depend on does.

- **Explicit dependency register**: who needs what, from whom, by when, and **what is done if it
  does not arrive** (alternative route). A dependency with no plan B is a date given away to another
  team.
- **Every dependency has a commitment date agreed with the providing team**, not assigned by the
  one that depends on it. An unagreed date is not a commitment, it is an expectation.
- **Strategy in order of preference**: (1) **eliminate** the dependency (duplicate or self-service),
  (2) **decouple** with an interface contract and a simulator, (3) **sequence** with a mutual
  commitment, (4) escalate. Option (1) is almost never considered and is usually the cheapest.
- **Metric**: time blocked by an external dependency as a % of lead time. If it exceeds 30 %, the
  problem is not one of planning but of organisational architecture: escalate it as such
  (`enterprise-architecture-standards`, `platform-engineering-standards`).

### Stakeholders and communication

- **Stakeholder map with decision level**: who approves, who must be consulted, who is only
  informed. A RACI **with a single A per decision**; two "accountable" is zero.
- **Fixed cadence and fixed content**, written in advance:

| Audience | Cadence | Content |
|---|---|---|
| Team | Daily (≤ 15 min) | Blockers and age of work in progress; **not** an individual status report |
| Sponsor / budget owner | Fortnightly | Forecast with a range, risks with an expired trigger, decisions they need to take |
| Wider stakeholders | Per delivered increment | What can be used already and what changed relative to the plan |
| Steering committee / management | Monthly or by exception | Deviation from the declared commitment and the decision being requested |

- **The report that does not lie**. The pattern to avoid has a name: ***watermelon reporting*** —
  green on the outside, red on the inside; the status gets greener as it goes up the hierarchy, and
  suddenly turns red when there is no margin left. Its root cause **is not individual dishonesty but
  a culture of blame**: if reporting red brings reproach instead of help, nobody reports red.
  Concrete and verifiable countermeasures:
  1. **The colour is computed, not opined**: it derives from a published numeric criterion (e.g. the
     85th-percentile forecast exceeds the committed date → red). If the colour is chosen by hand, it
     is an opinion formatted as data.
  2. **Every non-green cell requires the associated request** ("I need X from Y before Z"). A red
     without a request is a complaint; a red with a request is management.
  3. **The forecast is reported, not the percentage of progress.** "80 % complete" is not
     information; "85 % probability of finishing before 12 Nov" is.
  4. **Forbidden to change the colour when moving up a level.** The aggregated report links the
     original without retouching it; any nuance goes as a signed comment, not as a recolouring.
  5. **Red is treated as a request for help**, and whoever declares it early receives no reproach.
     This is a rule of conduct for the sponsor, and without it the previous four do not work.

### Recorded decisions

**A decision with no record gets discussed again** — and the second discussion is more expensive
because there is already code written and egos invested. Two registers with the same format and the
same repository:

- **ADR** for technical decisions (architecture, technology, pattern).
- **Management decision record** for scope, sequencing, hiring, risk acceptance,
  change of commitment.

Minimum fields: `date`, `decision-maker` (a person), `context`, `options considered`, `decision`,
`consequences`, `review date` and **`reversibility`** (one-way / two-way door).
**Speed rule derived from reversibility**: a reversible decision is taken fast and at the lowest
possible level; an irreversible one is worked up, documented and decided at the top. **Treating all
decisions as irreversible is the most common form of paralysis in management.**

Scope changes: **every change request is recorded with its impact on the five variables (§3)
before being accepted or rejected**. Accepting scope without declaring what moves is the exact
mechanics of *scope creep* — not an accident, an omission.

### Closure

A project closes when **the recipient accepts it and somebody can operate it**, not when the budget
runs out nor when the team is disbanded.

1. **Acceptance criteria written before starting** and verified by the stakeholder who
   wrote them, not by the team that implemented them.
2. **Complete handover to operations** per the list in `itsm-itil-standards` §3 (service owner,
   catalogue, SLA or OLA, runbooks, alerts, backup with tested restore, CMDB, training,
   *hypercare* with an end date). **Without it the project is not closed**, whatever the state of
   the invoice.
3. **Retrospective with actions somebody executes**: each action has an owner, a date and appears in
   the next cycle's backlog. **A retrospective whose actions are not executed teaches the team that
   the retrospective is theatre**, and it is worse than not holding one. Metric: % of retro actions
   closed in the following cycle; if it drops below 70 %, stop generating actions and fix the
   mechanism.
4. **Forecast vs. actual comparison archived**: it feeds the reference class of the next project
   (outside view, §3). Without this step the organisation repeats the planning fallacy indefinitely.
5. **Administrative closure**: contracts, licences, revoked access, temporary environments destroyed
   and inherited recurring cost declared (`finops-standards`).

## 4. Management quality and controls

Automatable controls over the management system's data. They run on a schedule; their failure opens
work, not a report.

| Control | Fails if | Action |
|---|---|---|
| Commitment without a range | there is a committed date with no associated percentile | Block publication of the commitment |
| Floating variable not declared | charter without the phrase "X is fixed, Y floats" | Do not start the project |
| Risk without an owner or a trigger | empty field | Reject the entry |
| Stagnant register | entry unreviewed for 2 cycles | Escalate to the sponsor |
| Expired assumption | trigger date passed without evaluation | Convert into a risk or an issue the same day |
| Dependency without an agreed date | confirmation from the providing team missing | Mark as a risk, not as a plan |
| WIP above the limit | exceeds the column's limit | Stop starting, start finishing |
| Aged item | age > 85th percentile of cycle time | Escalate before it becomes a surprise |
| Status without evidence | colour not derivable from the published numeric criterion | Reject the report |
| Retro actions | < 70 % closed in the following cycle | Stop generating actions; fix the mechanism |
| Expired forecast | Monte Carlo not re-run in > 2 weeks | Mark the forecast as invalid |

**The delivery DoD** (distinct from the technical one, which lives in `testing-qa-standards` and
`code-review-standards`, and **included by reference**): accepted by the named stakeholder, deployed
in production, operable per the handover, documented for whoever will use it, and communicated to
those affected. **An item that is "finished" but not deployed is not finished** — it is inventory,
and inventory in software only depreciates.

## 5. Security and confidentiality of management information

- **Management artifacts are sensitive information**: the risk register, the real forecast and the
  charters contain exploitable weaknesses, supplier data and sometimes information about people.
  Role-based access control, not "everybody with the link".
- **Forbidden to put credentials, personal data or customer data in tickets, tracking
  spreadsheets or charters**. The backlog is a free-text repository with history: what goes in,
  stays (`secrets-management-standards`, `privacy-engineering-standards`).
- **Regulatory and security requirements are scope, not "non-functionals" trimmed at the end.**
  They are identified in the charter with their regulatory source (`grc-compliance-standards`). A
  project that discovers in week 20 that it needs a DPIA is already 20 weeks late without knowing
  it.
- **Suppliers and subcontractors**: contractual dependency goes into the risk register with its
  exit clause. A critical supplier with no exit plan is a continuity risk
  (`bcdr-standards`).
- **Management tool**: SSO with MFA, audit of status changes and of committed dates.
  A committed date that can be edited without a trace invites rewriting history.

## 6. Sustainability of the management system and capacity

*(The canonical §6 —performance and operability— does not apply to a process domain; **it is
replaced, and this is declared**, by the operability of the management system itself.)*

- **Committable capacity = gross capacity − historical unplanned work − absences − support**.
  Committing on gross capacity is the most common and least discussed way of failing to deliver. The
  historical percentage of unplanned work is taken from the data, not from hope.
- **Every ceremony and every artifact is audited half-yearly** with the test in §1 (which decision
  it enables, who takes it, how many times it has been taken). Whatever does not pass is removed —
  management overhead grows by accumulation, never by decision.
- **Coordination cost**: adding people to a late project adds coordination before capacity.
  Before hiring, exhaust: reduce scope, eliminate dependencies, raise the flow limit.
- **Multi-project**: a person on three projects does not contribute a third to each; context
  switching takes a share that is not accounted for anywhere. **Default allocation: one person, one
  workflow.**
- **Knowledge continuity**: the decision record and the handover to operations are the only things
  that outlive the team. A project whose state exists only in the PM's head has a SPOF that goes on
  holiday.
- **Role succession**: if the PM disappears for a week, the system must remain legible. If it is
  not, the problem is not the PM: it is that the state is not written down.

## 7. Long-term sustainability and prohibitions

**Cadence**: charter and fixed variables reviewed at every change of commitment; RAID fortnightly;
forecast every 1-2 weeks; WIP limits monthly; ceremonies and artifacts half-yearly; reference class
updated at the closure of each project.

**Process deprecation**: every management rule is introduced together with the condition that would
make it unnecessary. A rule with no retirement condition is permanent by omission, and that is how
the bureaucracy nobody ever explicitly defended accumulates.

FORBIDDEN:
- ❌ **Committing date, scope and cost at the same time.** It is the project's founding lie: it will
  be discovered late and paid for with quality, which is the only variable nobody declared.
- ❌ **Estimating in hours what is not understood.** If it cannot be decomposed, it is not
  estimated: it is investigated with a fixed-timebox *spike*.
- ❌ **Converting points or sizes into hours or euros.** It reintroduces the bias and adds false
  precision.
- ❌ **Committing a date without a range or a probability.**
- ❌ **Managing by milestones with no deliverable increment.** A documentary milestone measures
  activity, not value, and allows being "80 % there" for months.
- ❌ **Using velocity as a measure of individual productivity** (nor of one team against another).
  It inflates immediately: points are free. It measures a team's capacity against itself, nothing
  more.
- ❌ **People utilisation targets** (≥ 90 % billable/occupied). It guarantees queues and delays.
- ❌ **The report that is green out of courtesy** (*watermelon*): a colour not derivable from a
  published criterion, recoloured when aggregating upwards, or a red with no associated request.
- ❌ **Cutting quality as a schedule lever.** It brings work forward, it does not eliminate it, and
  it charges for it in operations.
- ❌ **A risk register written at the start and never reviewed**, or with entries lacking an owner or
  a trigger.
- ❌ **Accepting a scope change without declaring what moves** in time, cost or existing scope.
- ❌ **A dependency with a date assigned unilaterally** to the providing team and with no alternative
  route.
- ❌ **Closing a project without an accepted handover to operations** (`itsm-itil-standards` §3): if
  nobody can operate it, it has not finished.
- ❌ **Retrospectives without actions with an owner and a date**, or with actions that are
  systematically not closed.
- ❌ **Citing CHAOS Report figures (or other failure figures with no public methodology) as data** to
  justify a decision or a budget (§2).
- ❌ **Copying text from PMBOK, PRINCE2 or SAFe into internal documentation**: proprietary material
  of PMI, PeopleCert and Scaled Agile respectively. The Scrum Guide is cited or it is described in
  your own vocabulary.
- ❌ **Writing "SAFe 7"**: Scaled Agile dropped numeric versioning (§2).
- ❌ **Adopting a scaling framework to solve a problem of architectural dependencies**: it adds
  ceremonies on top of the same coupling and makes the symptom more expensive without touching the
  cause.
- ❌ **One person assigned to more than two simultaneous workflows** without declaring the cost of
  context switching.

## 8. Mandatory web verification

Before committing to any of these points in a real project:

1. **PMI**: current edition at `pmi.org/standards/pmbok` — as of Aug 2026 the **8th edition**
   appears, but **the publication date is contradictory across third-party sources** (Nov 2025 vs.
   early 2026; the index hosted on pmi.org carries a Sep 2025 stamp). Confirm the date, price, member
   access conditions and the state of the PMP *Examination Content Outline*, which is updated
   separately.
2. **PRINCE2**: whether PRINCE2 7 (Sep 2023) is still the current edition and whether PeopleCert is
   still the owner; trademark and material terms of use before citing it.
3. **Scrum Guide**: check at `scrumguides.org` whether the **November 2020** version is still
   current — it is this document's default free reference and a revision would change vocabulary.
4. **SAFe**: name and date of the current release at `framework.scaledagile.com` (scheme
   `[year].[month]`, brand **AI-Native SAFe** as of Jun 2026) and licensing terms. **Never write a
   version number without verifying it.**
5. **Figures**: before using any percentage of failure, success or "transformations that fail",
   locate the **primary study, its year, its sample and its method**. If it does not turn up, or if
   the methodology is questioned (the CHAOS/Standish case, §2), **it is not used**. Also verify
   whether Standish has published anything after CHAOS 2020.
6. **Planning fallacy and *reference class forecasting***: check the state of the debate — there is
   recent published criticism of RCF (*Production Planning & Control*, 2025) worth citing alongside
   Kahneman-Tversky (1979) and Flyvbjerg (2008) so as not to present the correction as more solid
   than it is.
7. **Management and forecasting tools**: status, licence and price of whatever is proposed (Jira and
   its offering reorganisation and Data Center retirement, Azure DevOps, ActionableAgile, free
   alternatives). For *open source*, **read the repository's raw `LICENSE`**.
8. **Contractual and regulatory framework** of the specific project (tender, EU DORA, NIS2, ENS, EU
   AI Act if there is an AI component): it may impose a management framework, formal evidence or
   deadlines — `grc-compliance-standards` and `ai-governance-standards`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
