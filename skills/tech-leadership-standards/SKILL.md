---
name: tech-leadership-standards
description: Technical leadership as a set of decisions and artifacts, not a personality trait. Use when defining or applying an engineering career ladder and the IC-versus-manager track, assigning work by Staff+ archetype (tech lead, architect, solver, right hand), writing or reviewing an ADR and classifying a decision as a one-way or two-way door, writing a design document and running a design review with acceptance criteria, deciding who decides and at what level, budgeting technical debt as an explicit business decision, protecting a blameless postmortem under management pressure, running a 1:1 with a report-owned agenda, giving written performance feedback, being asked for individual productivity metrics such as lines of code, commits, velocity or DORA per engineer, citing SPACE or DORA in a measurement argument, sizing a team and its cognitive load in the Team Topologies sense, mapping inter-team dependencies, resolving a technical disagreement and applying disagree-and-commit, deciding whether to adopt coding agents and who pays the organizational cost, or being handed responsibility without authority.
---

# Technical leadership standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the decisions taken by whoever leads technically and the artifacts in which they are
written down**: career tracks and the real scope of each level, staff+ role archetypes, who decides what
and how fast, the decision record, the design document and the design review, technical debt
as a budget line, the individual conversation and performance evaluation, team
sizing and its dependencies, and the resolution of technical disagreements.

Triggers: "career ladder", "level ladder", "senior/staff/principal", "IC vs. management",
"staff archetype", "tech lead", "ADR", "decision record", "one-way door",
"reversible", "design document", "design doc", "design review", "technical RFC", "technical
debt", "refactor budget", "blameless postmortem", "1:1", "feedback", "performance
review", "individual productivity metrics", "lines of code", "commits per person",
"DORA per engineer", "SPACE", "cognitive load", "Team Topologies", "team size",
"inter-team dependencies", "technical disagreement", "disagree and commit", "responsibility without
authority".

**Guiding principle**: **technical leadership is a set of decisions and artifacts, not a character
trait.** It is not evaluated by how the person is perceived, but by what exists in writing and by
what the team achieves: decisions recorded with their reversibility, designs reviewed before
building, interfaces between teams defined, debt with an assigned budget and people with
specific, dated feedback. **A falsifiable test applicable to any claim about leadership:
name the artifact it produces, who reads it and which decision it changes.** If it cannot be named, the
claim is motivational and does not get written here.

Hard corollary: **"lead by example", "foster trust" and phrases of the same genre fix
nothing.** They are not criteria, they are decoration. Their actionable equivalent always exists and is the only thing
this document accepts: *"every architecture decision lives in an ADR with declared
reversibility"*, *"the postmortem names no people and the leader defends it to management in writing"*.

**Not applicable**:
- `technical-hiring-standards`: **reciprocal and strict**. Here you decide **what profile is needed,
  why, and which gap in the team it fills** (§3.7); there **how a candidate is measured** — rubric,
  exercise format, method validity, bias, legal regime and onboarding. One-sentence boundary:
  **leadership defines the role; the selection process is the measuring instrument.**
- `project-management-standards` (**already written**): **delivery, the plan, the commitment, the
  estimate, the risk and the stakeholders are theirs**, including the record of *management*
  decisions. Here the **technical decision** and **team development**. Boundary: if the question
  is *"when will it be ready and with what risk?"*, it is theirs; if it is *"how is it built and who decides it?"*,
  it is ours. **The decision record format is the same in both** (§3.3) so as not to fork
  the repository.
- `product-discovery-standards`: **what gets built and why** — problem,
  user, hypothesis, prioritisation by value and the decision to kill an idea. Here the what is not decided.
- `enterprise-architecture-standards`: architecture governance for the
  organisation, capability roadmap and application portfolio. Here the scope is the team
  and its immediate neighbourhood, not the company. Reciprocal declared in their §1.
- `software-architecture-patterns-standards` and `refactoring-tech-debt-standards` (**already written**):
  **the technical criteria are theirs** — which pattern applies, when a module is refactored
  and with which technique. Here only **the decision to invest in it, its budget and how it is defended**
  (§3.5). Both already declare the reciprocal in their §1.
- `microservices-architecture-standards`: service boundaries and concrete contracts. Here, the
  organisational reflection of those boundaries (§3.6).
- `code-review-standards` (**already written**): **the review criteria are theirs** — what blocks, how
  the comment is written, what a high-risk change requires. Here only the rule that **review
  is not used as an instrument of power** (§3.8) and who arbitrates the disagreement that review
  does not close.
- `testing-qa-standards`: test strategy and gates. Here, the decision to fund it.
- `sre-practice-standards`: **SLOs, *error budget*, on-call, capacity and the DORA metrics are
  theirs**. Here, solely, that **DORA is a system measure and its individual use is forbidden**
  (§3.9, §7).
- `incident-management-standards`: **the incident process and the blameless postmortem are theirs**
  — roles, timeline, actions. Here what corresponds to leadership and only that: **protecting the
  blameless postmortem when there is pressure from above to name a culprit** (§3.10).
- `platform-engineering-standards` (**already written**): **the platform as an internal product**, its
  paved road, its SLOs and its adoption. Here, the decision to create the team and what load is
  transferred to it.
- `itsm-itil-standards`: service, catalogue and continuous operation.
- `grc-compliance-standards`: regulatory framework, formal evidence, segregation of duties.
- `ai-agent-workflow-standards` (**already written**): **the team policy on coding
  agents is theirs** — which task is delegated, instruction files, permissions, review of the
  diff, attribution. Here only **the decision to adopt it, who pays its organisational cost and which
  metrics are NOT used to justify it** (§3.11).
- `knowledge-management-standards`: where documentation lives and how it is
  kept alive. Here, the obligation that the decision be written down.

## 2. Default decisions

> Verify on the web the status of the cited sources before relying on them (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| What distinguishes one level from another | **Scope of impact, type of decision and time horizon** (§3.1) | Never years of experience and never mastery of a technology |
| Career track | **Two tracks with parity of level, scope and pay**, published | A single track only in organisations with < 15 engineers, and declaring it |
| Staff+ work assignment | **By declared archetype** (§3.2), agreed with the person and revisable | — |
| Record of technical decisions | **ADR mandatory**, Nygard format, in the repository of the affected code | A central record **only** if the decision crosses several repositories |
| Decision speed | **Derived from reversibility** (§3.3): reversible → fast and at the lowest level; irreversible → informed and higher up | — |
| Before building anything non-trivial | **A reviewed design document** with acceptance criteria (§3.4) | A throwaway prototype with a time box, if the problem is that it is not understood |
| Technical debt | **An explicit and recurring budget line**, with its unit of measure (§3.5) | Never "when there is time" |
| Measure of a technical leader | **The team's result**: delivery, reliability, autonomy, recorded decisions | — |
| The leader's contact with the code | **The minimum sufficient to judge** (§3.8): reviewing, reading the design, touching the system periodically | — |
| Individual productivity metric | **It does not exist.** Forbidden (§7) | Qualitative evaluation with written and dated evidence |
| 1:1 cadence | **Weekly or fortnightly, the report's agenda**, never a status report (§3.9) | — |
| Team size | **Stable, with bounded load and a single owner for each system** (§3.6) | — |
| Technical disagreement | **Resolved with data, with a deadline, and closed with disagree-and-commit** (§3.7) | Escalation **only** after exhausting the bounded experiment |

### Sources: what is cited and with what caveat

- ✅ **One-way / two-way doors.** Primary source: **Jeff Bezos, 2015 letter to Amazon
  shareholders** (`ir.aboutamazon.com`, PDF). **Verbatim** (extracted from the official PDF,
  not from a summary): *"Some decisions are consequential and irreversible or nearly
  irreversible – one-way doors – and these decisions must be made methodically, carefully, slowly,
  with great deliberation and consultation. If you walk through and don't like what you see on the
  other side, you can't get back to where you were before. We can call these Type 1 decisions. But
  most decisions aren't like that – they are changeable, reversible – they're two-way doors. If
  you've made a suboptimal Type 2 decision, you don't have to live with the consequences for that
  long. You can reopen the door and go back through. Type 2 decisions can and should be made quickly
  by high judgment individuals or small groups."* And the diagnosis that matters here: *"As
  organizations get larger, there seems to be a tendency to use the heavy-weight Type 1
  decision-making process on most decisions, including many Type 2 decisions. The end result of this
  is slowness, unthoughtful risk aversion, failure to experiment sufficiently, and consequently
  diminished invention."* **Declared discrepancy**: numerous secondary sources place the framework
  in the **2016** letter; that is incorrect — the Type 1 / Type 2 terminology appears in the **2015** one.
  The 2016 one contains related material (*disagree and commit*), which is a different thing.
- ✅ **ADR.** Primary source: **Michael Nygard, "Documenting Architecture Decisions", 15-Nov-2011**,
  originally published on the Relevance/ThinkRelevance blog and today at `cognitect.com`. A five-section
  template: **Title** (a short noun phrase with a sequential number that is never reused),
  **Status** (proposed / accepted / deprecated / superseded by ADR-NNNN), **Context** (the forces
  at play, in neutral language), **Decision**, **Consequences** (positive and negative). Derived
  rule: **an accepted ADR is not edited**; if the conclusion changes, a new one is written that
  supersedes the previous one and updates its status.
- ⚠️ **Staff+ archetypes.** A published reference taxonomy does exist: **Will Larson, *Staff
  Engineer: Leadership beyond the management track* (2021)** and its origin in the open
  (`lethain.com/staff-engineer-archetypes/`, `staffeng.com/guides/staff-archetypes/`). Four
  archetypes: **tech lead**, **architect**, **solver**, **right hand**. **Explicit caveat**: it is
  a **descriptive taxonomy observed in fast-growing technology companies, not a
  research result**, and it has published criticism from practitioners (Sean Goedecke: the
  archetypes exist but are bad advice as a career target, because *solver* and *right hand*
  depend on accumulated trust and cannot be pursued directly; Alex Ewerlöf: they should not
  be used as job titles). **Permitted use: vocabulary for distributing work and clarifying
  expectations. Forbidden use: turning them into levels, titles or boxes on a ladder.**
- ⚠️ **Team cognitive load.** Original source **John Sweller, "Cognitive load during problem
  solving: Effects on learning", *Cognitive Science* 12(2):257-285 (1988)** — a theory of
  **individual learning and instructional design**. Its transfer to teams is from **Matthew Skelton and
  Manuel Pais, *Team Topologies* (2019)**. **Treat it as a useful analogy, not as a validated measurement**,
  exactly as in `platform-engineering-standards` §6.4: team cognitive load **has
  no measurable unit**, the sum of individual loads is not a construct defined in the original
  theory, and DevOps academic literature points out that the book **provides no scientific evidence**
  and rests on experience and cases. It is useful for **deciding how systems are distributed between teams**; it is
  not useful as a number on a slide.
- ✅ **SPACE.** **Nicole Forsgren, Margaret-Anne Storey, Chandra Maddila, Thomas Zimmermann, Brian
  Houck and Jenna Butler, "The SPACE of Developer Productivity: There's more to it than you think",
  *ACM Queue* 19(1):20-48 (2021), DOI 10.1145/3454122.3454124** (also in *CACM*). Five
  dimensions: satisfaction and well-being, performance, activity, communication and collaboration,
  efficiency and flow. The operational rule taken from it: **measure at least three dimensions at
  once, combining objective metrics and a survey**; activity **never in isolation** to reward
  or penalise. **Declared discrepancy and usage warning**: the claim circulates that "SPACE
  measures the individual and DORA the team" — **that is a misreading**: one of the myths the article
  itself dismantles is that productivity is *only* individual performance, and its central thesis is
  that it is not captured by a single metric nor by activity data. **It has not been possible to retrieve the
  full text verbatim** (ACM Queue and CACM return 403 to automated download): the
  formulations above come from consistent secondary sources and **must be checked against
  the original article before quoting them literally** (§8).
- ✅ **DORA as a system measure.** The four metrics measure **team and system delivery**,
  not people. Report **2025: *State of AI-assisted Software Development*** (`dora.dev/dora-report-2025/`,
  ~5,000 professionals); report **2026: *The ROI of AI-Assisted Software Development*** (InfoQ
  coverage, May-2026). **Caveat about the 2026 one**: there is published criticism that, compared with the
  research rigour of previous editions, it is largely a set of speculative
  recommendations. Cite the edition and the year; **never a bare "DORA says"**.

### Famous figures: what is NOT used as data

This domain is saturated with numbers that circulate with no locatable primary study or with
dismantled methodology. These are expressly discarded:

- ❌ **The "10x programmer".** Origin: **Sackman, Erikson and Grant, "Exploratory Experimental Studies
  Comparing Online and Offline Programming Performance", *CACM* 11(1):3-11, Jan-1968**. Methodological
  refutation: **Lutz Prechelt, "The 28:1 Grant/Sackman legend is misleading, or: How large is
  interpersonal variation really?", Technical Report 1999-18, Universität Karlsruhe, Dec-1999**
  (`page.mi.fu-berlin.de/prechelt/Biblio/varianceTR.pdf`). Flaws in the original: **12 subjects**,
  trivial tasks of a mathematical nature, and **a mix of low-level and high-level language
  programmers in the same group**, which inflates the best/worst ratio. Prechelt reanalyses a much
  larger dataset and argues that **comparing the best with the worst is the wrong comparison**: against
  the median of the worst quartile versus that of the best, the ratio **rarely exceeds 4**, and the
  standard deviation/mean ratio is around **0.5**. **Permitted use**: "there is substantial
  interpersonal variation, of the order of 2-4x depending on the task, with overlapping distributions". **Forbidden use**:
  "10x", and above all **using it to justify pay, staffing or redundancies**.
- ❌ **"An interruption costs 23 minutes and 15 seconds".** **The paper that backs it does not
  exist.** The paper that gets cited, **Mark, González and Harris, "No Task Left Behind? Examining the
  Nature of Fragmented Work", CHI '05**, measures the **probability of resuming a task on the same day**
  and **does not contain that figure**. The other one usually cited, *"The Cost of Interrupted Work: More
  Speed and Stress"*, finds that **interrupted subjects completed the tasks faster**,
  with more stress. The figure comes from **a 2006 interview** with Gloria Mark, not from a peer-reviewed
  article. **It is not written, not even with caveats.** What is defensible without a figure: fragmentation has a cost
  and **the argument for protecting blocks of work does not need an invented number**.
- ❌ **"70 % of the variance in team engagement is determined by the manager"** (Gallup, *State
  of the American Manager*, 2015). **Proprietary analysis, not peer reviewed, with no raw data
  published**, and with two interpretation problems that its diffusion ignores: it refers to variance
  **between teams** (it is not an individual-level claim), and the "manager effect" absorbs everything
  that clusters at team level (function, location, load, staffing). **It is not used as data to
  justify a decision.**
- ❌ **"People leave managers, not companies"** (*First, Break All the Rules*, Gallup). There is a published
  refutation from **Culture Amp (2017)** over 175 teams: people do leave bad managers, but **it is not
  the first reason**, and in bad organisations **having a good or bad manager barely changes the decision to
  leave**. The weak version holds ("the manager's quality is *one* of the factors, conditional on
  the organisation being decent"); the slogan does not.
- ❌ **Turnover percentages attributed to a "bad manager"** and **the cost of a bad hire
  expressed as a multiple of salary** (§ `technical-hiring-standards`): discarded for the same
  reason, there in detail.

**General rule**: **a figure with no primary study, year, sample and method does not go into a document,
a slide or a budget request.** If the argument only stands with the figure, the
argument was bad.

## 3. Structure and conventions

### 3.1 Career tracks: what actually changes

**What changes when you move up a level is not "the level": it is three observable variables.**

| Variable | Senior | Staff | Principal |
|---|---|---|---|
| **Scope of impact** | Their team and the system they answer for | Several teams, or a critical area the organisation depends on | The engineering organisation or a cross-cutting capability |
| **Type of decision** | How it is implemented; chooses between known options | Which options exist; defines the problem and the interfaces | What is stopped; irreversible decisions and trade-offs between areas |
| **Time horizon** | Weeks to a quarter | Quarters to a year | One to several years |
| **Required evidence** | Systems delivered and operable | Other people's designs improved, decisions recorded, people levelled up | Changes of direction the organisation followed and that can be traced |

Hard rules:
1. **The ladder is published.** A ladder only the manager knows is not a ladder, it is a retroactive
   excuse. Public references exist so as not to start from zero — **Rent the Runway (2015, with
   Camille Fournier as CTO), Dropbox, CircleCI, Square, Kickstarter**, aggregated at
   `progression.fyi` and `github.com/bmoeskau/engineering-ladders`. **They are adapted, not copied**: someone
   else's ladder describes someone else's organisation.
2. **Real parity between tracks.** The individual contributor track and the management one have **the same
   level ceiling, the same salary band and the same presence in decision-making forums**. Without those
   three, the technical track is decorative and everyone knows it within six months.
3. **Managing is not a promotion, it is a change of job.** The work, the measure and the skill are
   different. Operational corollary: **there is a declared way back**, and using it is not a failure
   recordable in the evaluation.
4. **The level is assigned on written evidence**, not on seniority and not on likeability. If the evidence cannot
   be written down with dated facts, there is no level.
5. **No level is defined by a technology.** "Kubernetes senior" is not a level, it is a
   dependency on a tool with an expiry date.

### 3.2 Staff+ archetypes: what they are really for

They serve one purpose, and that is why they are here: **avoiding assigning work the person cannot
do from where they are.** Taxonomy and caveats in §2.

| Archetype | Work that belongs to them | Work that destroys their impact |
|---|---|---|
| **Tech lead** | Approach and execution of **one** team, alongside the manager | Being the bottleneck for the decisions of another three teams |
| **Architect** | Direction, quality and approach of **one critical area**, with a multi-year horizon | Firefighting outside their area; making their area depend on their presence |
| **Solver** | Going into a hard, bounded problem and coming out with the path resolved | Becoming the permanent owner of what they fixed |
| **Right hand** | Extending an executive's reach in a large organisation | Existing in an organisation that does not need one: it reproduces hierarchy without adding judgement |

Rules:
- **The archetype is agreed in writing with the person and is reviewed** (by default, every six months or
  when the project changes). A *solver* who gets handed the maintenance of everything they touched
  stops being a *solver* within a quarter.
- **Architect and right hand only appear at a certain scale.** Larson observes them emerging around
  ~100 and ~1,000 engineers respectively. **Creating them earlier manufactures a decision layer with no
  problem to solve.**
- **FORBIDDEN to use them as titles** or as levels on the ladder (§7).

### 3.3 Decisions: what is decided, who decides and how fast

**Who decides, by default:**

| Type of decision | Decided by | Consulted | Recorded in |
|---|---|---|---|
| Implementation inside a module of the team's own | **Whoever implements it** | The PR reviewer | The code and the PR |
| Choice of library or pattern within the team | **The team**, the tech lead arbitrates | — | **The repository's ADR** |
| Contract or interface between two teams | **Both teams, jointly** | The area's architect | **ADR + versioned contract** (`api-design-standards`) |
| A new technology in the organisation, or the retirement of an existing one | **Staff+ level or architecture**, with published criteria | Platform, security, FinOps | **ADR + inventory** |
| A scope or date commitment | **Not this skill** | — | `project-management-standards` |
| Acceptance of a regulatory risk | **Whoever has the formal authority** | — | `grc-compliance-standards` |

**The ADR is an obligation, not a courtesy.** Minimum rule: **if a technical decision is going to condition the
work of someone who was not in the conversation, it gets written.** Nygard format (§2), in the
affected repository, numbered and not editable once accepted.

**Speed is set by reversibility, not by perceived importance** (Bezos 2015, verbatim in §2):

| | One-way door (Type 1) | Two-way door (Type 2) |
|---|---|---|
| Typical examples | Public data model, identity scheme, API format exposed to third parties, lossy migration, choice of a vendor with an expensive exit | Internal library, folder structure, internal log format, test framework |
| Speed | **Slow, deliberate, informed**: design document, alternatives evaluated, formal review | **Fast**, by the person or the small group closest to the problem |
| Level that decides | Higher up, with consultation | The lowest possible |
| Cost of being wrong | High and permanent | Low: the door reopens |

- **Every ADR carries a `reversibilidad` field with an explicit value.** Without it, the organisation treats
  everything as Type 1 and grinds to a halt — the failure the 2015 letter itself describes.
- **The classification can be challenged, but in writing and with an argument.** "This is irreversible"
  is a falsifiable claim: you ask for the estimated cost of reverting it.
- **A Type 2 decision that has been under discussion for three weeks already cost more than being wrong.** Rule:
  a time box, and if it expires, the person with the responsibility decides and it is recorded.

### 3.4 Design document and design review

**The design review is the point in the cycle where a mistake is still cheap.** Afterwards there is
code, dependencies, migrated data and people who have already defended it in public.

**When a design document is mandatory** (any one is enough):
- The decision crosses a team boundary or creates/changes an interface between teams.
- It is a one-way door (§3.3).
- It touches personal data, authentication, authorisation, cryptography or money.
- The estimated effort exceeds a threshold the team publishes (by default: **two person-weeks**).
- A technology the organisation does not yet operate is introduced.

**Minimum template. A document without sections 5, 6 and 8 is sent back unreviewed.**

```markdown
# Diseño: <nombre>            Autor: <persona>   Estado: borrador|en revisión|aceptado|sustituido
1. Problema            # qué falla hoy, con evidencia observable (dato, incidente, ticket)
2. Restricciones       # plazo, presupuesto, normativa, compatibilidad, equipo disponible
3. No objetivos        # lo que este diseño explícitamente NO resuelve
4. Propuesta           # la solución, con el diagrama mínimo que la explique
5. Alternativas descartadas   # >=2, con el motivo del descarte. Sin esto no hay diseño, hay preferencia
6. Criterios de aceptación    # falsables y medibles: cómo se sabrá que funcionó, y cuándo se mira
7. Impacto             # migración, compatibilidad hacia atrás, coste recurrente, operabilidad, seguridad
8. Reversibilidad      # Tipo 1 o Tipo 2, y coste estimado de revertir
9. Riesgos abiertos    # con dueño
```

**Review rules:**
- **The problem is reviewed before the solution.** If the reviewers do not agree on the
  problem, discussing the solution is wasted time and it always ends in aesthetics.
- **Mandatory pre-reading, with a deadline** (48 h by default). A meeting where the document is read
  live is a reading meeting, not a review.
- **Comments are labelled as blocking or non-blocking**, just as in code review
  (`code-review-standards`). A reviewer who marks nothing as blocking has approved.
- **The review ends with a decision and a date, not with "let's keep talking".** The
  valid states are: accepted, accepted with listed conditions, rejected with a reason, or postponed with
  a date and with what remains to be found out.
- **The accepted document becomes an ADR or links to one.** A design that leaves no trace of a decision
  gets discussed again in six months.
- **Acceptance criteria with a check date.** They are revisited when due: if they were not met,
  that is information about how the team designs, and it is the cheapest input there is for improving.

### 3.5 Technical debt: a business decision with a budget

The technical criteria —what to refactor, with which technique and with which test net— belong to
`refactoring-tech-debt-standards` (**already written**). **Here only the decision to invest and
how it is defended.**

1. **Debt is recorded like any other work**, in the same backlog, with an owner and with the
   **cost it imposes today** — not with adjectives. Admissible formulation: *"every change in the
   billing module requires touching four places and last quarter it generated 3 of the 7 incidents"*.
   Inadmissible formulation: *"the code is bad"*.
2. **Distinguish deliberate debt from degradation.** Deliberate debt was incurred with a recorded
   decision and a review date (if it does not have one, it was not a decision: it was an oversight).
   Degradation is silent accumulation and is detected by symptom, not by opinion.
3. **An explicit and recurring budget.** A percentage of capacity per cycle is declared,
   published and **protected the way a committed date is protected**. A percentage that gets cancelled in
   the first quarter under pressure was not a budget: it was an intention.
4. **How it is defended to whoever pays — and this is what always fails.** Technical debt is not
   defended as code quality: **it is defended with the cost the business is already paying**, in
   its vocabulary. Arguments that work because they are verifiable:
   - **Lead time**: the same change takes X in this module and Y in the rest.
   - **Reliability**: the proportion of incidents concentrated in the component
     (`incident-management-standards` provides the datum).
   - **Direct cost**: oversized infrastructure, licences, hours of manual operation
     (`finops-standards`).
   - **Risk with a name**: an unsupported dependency, a version with no security patches
     (`vulnerability-management-standards`), regulatory non-compliance (`grc-compliance-standards`).
   - **The option that is lost**: what will not be doable, and when, if it is not touched.
5. **A refactor request with none of those five arguments is rejected**, whoever makes
   it. And it is rejected here, inside engineering, before the business rejects it: **credibility
   is spent once**.
6. **Never "a refactor release" that delivers nothing.** Debt work is delivered in
   increments with an observable effect; if it cannot be split, the problem is the design of the
   intervention, not the calendar.

### 3.6 The team as a system

- **A single owner per system.** A system with no named owner is maintained by whoever had the bad luck
  of touching it last. Two owners is zero owners.
- **Bounded load, in the analogical sense of cognitive load** (§2, with its caveat): a team
  answers for as many systems as it can **understand, operate and improve**. An operational and
  falsifiable test that requires no invented metric: *can the team deploy, diagnose in
  production and explain the data model of every system it answers for, without depending on one
  specific person?* If not, the load exceeds the team — the scope is reduced or extraneous load
  is transferred to the platform (`platform-engineering-standards`).
- **Stable teams.** Reorganising teams resets system knowledge and trust
  relationships. **Every reorganisation is justified in writing with the problem it solves and its expected
  cost**, or it is not done.
- **Size**: small enough that everyone knows everyone's work, large enough
  to sustain an on-call rota without burning anyone (`sre-practice-standards` fixes the latter).
  **Adding people to a saturated team adds coordination before it adds capacity**
  (`project-management-standards` §6).
- **Inter-team dependencies: they are managed by interface, not by meeting.** Preference, in order:
  (1) eliminate the dependency, (2) decouple with an interface contract and a simulator, (3) sequence
  with a mutual commitment from the providing team, (4) escalate. **Adding a recurring
  sync meeting is choosing (4) and calling it (3).**
- **The team's structure and the system's converge** (Conway). Practical consequence: **if you
  want a different architecture, you have to change the team boundaries, not just the
  diagram.**

### 3.7 Technical conflict

**A technical disagreement with no procedure gets resolved by hierarchy or by exhaustion, and both
produce the worst decision available.** Procedure, in this order and with a deadline:

1. **Make the disagreement explicit**: each side writes, in one paragraph, what they defend and **what evidence
   would make them change their mind**. Whoever cannot answer the second has no technical position,
   they have a preference — and preferences do not block.
2. **Find the datum**: prototype, measurement, load test, review of a past incident. **With
   a fixed time box agreed beforehand.**
3. **If the datum does not discriminate** (a real tie), **whoever answers for the consequences** decides —
   normally the owner of the affected system — and it is recorded in an ADR with the alternatives and the
   tie declared.
4. **Disagree and commit, as an explicit team rule.** Reference: Amazon's leadership
   principle **"Have Backbone; Disagree and Commit"** (`amazon.jobs`) — the obligation to challenge the
   decision respectfully even when it is uncomfortable, and **full commitment once it is taken**. The term is
   older than Amazon (Intel, *constructive confrontation*). The local rule, which is what applies:
   **once the decision is closed, nobody passively sabotages it or reopens it in corridors**; it is reopened
   only with new evidence and through the same channel.
5. **When it is escalated**: when the disagreement crosses the boundary of two teams and blocks work for more
   than a week, or when it involves a security, legal or personal-data risk. **Escalating is not
   losing**: escalating late is.
6. **A disagreement that repeats is an organisational design problem**, not a people problem: the
   boundaries of responsibility are badly drawn (§3.6).

### 3.8 The technical leader's work that is not writing code

**Their value is measured in the team's result, not in their own *output*.** Direct consequences:
if the most productive person on the team is the leader, the team is underused; if the leader
is on the critical path of every delivery, they are a SPOF with holidays.

Work that is theirs, and that produces leverage:
- **Unblocking**: identifying who is stuck and why, and getting it out of the way. It is the highest-return
  activity of the job and the first one sacrificed when the leader starts programming.
- **Defining interfaces between teams** before two teams build against different
  assumptions (§3.6).
- **Reviewing other people's designs and decisions** (§3.4) — not rewriting them.
- **Writing what the organisation will need to remember**: ADRs, context, criteria.
- **Creating the conditions for someone else to take the decision**, and accepting that they take it differently from how
  the leader would have taken it if the result is acceptable. **A leader who only delegates the decisions that
  would have matched their own has delegated nothing.**
- **Developing people** (§3.9): it is work with a calendar, not a by-product.

**The opposite trap, and it is just as real: the leader who stops touching the code loses the ability
to judge.** With no contact with the system, other people's estimates become uncheckable, designs
get approved out of trust in the person and not because of the content, and technical debt becomes
a story with no evidence. **Non-negotiable operational minimum:**
- Review code properly and regularly (`code-review-standards`), including changes they do not
  fully understand, which is where you learn where the system is.
- **Be in the on-call rotation** if the team has one, or at least take part in incident
  response (`incident-management-standards`).
- **Take real work, but never on the critical path**: internal tooling, fixes,
  tests, the task nobody wants. **FORBIDDEN to take the quarter's critical feature**:
  it turns them into a bottleneck and leaves the team without the developmental part.
- Arbitration rule between the two traps: **if the team delivers just as well when the leader is
  away for two weeks, the split is correct.** It is the only test that matters, and it can be run
  literally.

**Code review is not used as an instrument of power.** Vetoed manifestations: blocking a
PR out of aesthetic preference, demanding your own solution with no technical argument, withholding approval
as leverage in a negotiation unrelated to the diff. The criteria for what blocks belong to
`code-review-standards`; **the obligation that the leader does not distort it belongs here**.

### 3.9 1:1s, feedback and evaluation

**The 1:1 belongs to the report.** Concrete rules:
- **The agenda is set by whoever reports**, and it exists before the meeting. If there is no agenda, the default
  question is not "how is X going?" but **"what is getting in your way most?"**.
- **FORBIDDEN for it to be a status report**: the state of the work is in the management system
  (`project-management-standards`) and consulting it is the leader's responsibility, not minutes of the
  person's time.
- **A fixed and protected cadence** (weekly or fortnightly by default). **Cancelling it repeatedly
  communicates a priority more clearly than any speech.**
- **Shared notes and commitments with an owner and a date.** A 1:1 with no trace repeats identically for
  a year.
- At least once a quarter, the 1:1 is about **career**: current level, missing evidence,
  archetype (§3.2), what work needs to be sought to get there. With the published ladder in front of you.

**Feedback:**
- **Specific, dated and about observable behaviour**, not about traits. *"In the review of the payments
  design on 12 May you closed the discussion before Ana presented her alternative"* is
  actionable. *"You are not very collaborative"* is not: what cannot be observed cannot be corrected.
- **Close to the event.** Feedback saved for six months for the annual review is not feedback: it is an
  ambush, and it destroys the credibility of the whole process.
- **No surprises in the evaluation.** Falsifiable rule: **if something appears in the annual review and it is
  the first time the person hears it, the failure is the leader's, and it is recorded as such.**
- Difficult feedback is given in private, in writing as well as verbally, and **with what is expected
  differently and by when**.

**Why individual engineering productivity metrics are counterproductive** — and this
is the part you have to be able to defend to management with the source in hand:
1. **The published position of the sector's reference research.** **DORA**: the four metrics
   measure **team and system delivery** and must not be used to evaluate the performance of
   individual engineers; applying them to people creates perverse incentives. **SPACE** (Forsgren et
   al., 2021, §2) dismantles two directly applicable myths: that productivity is activity, and
   that it is **only** individual performance; and it establishes that **activity metrics are never used
   in isolation to reward or penalise**.
2. **They are trivial to game and gaming them is rational**: lines, commits, PRs and points are
   free to inflate and the cost of inflating them is paid by someone else (the reviewer, the maintainer).
3. **They measure the visible and punish the valuable**: reviewing, pairing, mentoring, being on call,
   deleting code and preventing the unnecessary from being built leave no trace in any counter.
4. **Engineering work is interdependent**: attributing the result to an individual within
   a system with queues, dependencies and review is an attribution error, not an imprecise
   measurement.
5. **The alternative that is used**: qualitative evaluation **with written and dated evidence** against
   the published ladder (§3.1) — designs, recorded decisions, incidents resolved, people
   developed, systems that work without their author. **It is more work for the leader. That is the
   cost of the job.**

### 3.10 Incidents: what corresponds to leadership

The full process belongs to `incident-management-standards`. **Here only the part that only
leadership can do, and which is where the blameless culture breaks in practice:**
- **Protecting the blameless postmortem when there is pressure from above to name someone.** The
  pressure is real and arrives in the form of a reasonable question ("who deployed it?"). The standard
  answer, in the same language as whoever asks: **the system allowed an individual error
  to reach production; that is the defect and that is what gets fixed, because it is the only one that will not
  recur.** Replacing the person leaves the system identical for the next one.
- **Verifiable drafting rule**: **the postmortem contains no proper names as a cause.** If
  "X ran Y" appears, it is rewritten as "the procedure allowed Y to be run without confirmation".
- **Honest contraindication**: blameless **does not mean without responsibility**. Repeated
  negligence, knowingly bypassing controls or acting without authorisation are a conduct matter and are
  handled **outside the postmortem, through another channel and with HR.** Mixing them destroys both.
- **The postmortem's actions get funded.** A postmortem whose actions do not enter the next
  cycle's plan teaches the team that the exercise is theatre, and from then on postmortems
  are written to be filed.
- **The leader publicly owns the team's failure and publicly attributes the success.** It is a
  conduct rule with a verifiable effect: without it, nobody reports a problem early.

### 3.11 Coding agents: what leadership decides

The concrete policy —which task is delegated, instruction files, permissions, review of the diff,
attribution— belongs to `ai-agent-workflow-standards`. **Here, three decisions and one prohibition:**
- **The decision to adopt**: it is taken like any other technical decision, with an ADR and declared
  reversibility. And with what almost never gets declared: **what happens to the review cost**. An agent
  shifts effort from writing to **reviewing**, and the team's review capacity is finite and does not
  grow by itself.
- **Who pays the organisational cost**: training, review time, permission governance and
  response to quality incidents. If explicit capacity is not assigned, it is funded by cutting
  review — which is exactly the control that adoption makes more necessary.
- **The effect on junior people's development**: if the developmental work is fully automated,
  the organisation stops manufacturing seniors. **You decide and declare what work is reserved
  for learning**, you do not discover it two years later.
- ❌ **FORBIDDEN to justify adoption with individual acceptance or generated-volume metrics**
  (§3.9, §7). Admissible evidence is system-level and is cited with its edition and its year
  (`ai-agent-workflow-standards` maintains the state of the evidence).

## 4. Verifiable controls over the leadership system

Auditable controls, not climate surveys. They are run on a fixed cadence; **their failure opens work
with an owner, it does not generate a report**.

| Control | It fails if | Action |
|---|---|---|
| Unrecorded decision | there is a technical decision in production with no ADR explaining it | Write it retroactively and name the decider |
| ADR with no reversibility | the `reversibilidad` field is absent | Reject the ADR |
| One-way door decided in a meeting | with no design document and no alternatives | Reverse the process: it is informed and decided again |
| Design with no discarded alternatives | section 5 empty | Send back unreviewed |
| Acceptance criteria not revisited | the check date has passed without evaluation | Evaluate and record the result, met or not |
| Unpublished ladder | the level ladder is not accessible to the whole team | Block any promotion until it is published |
| Surprise in the evaluation | a point appears for the first time in the review | Record as the leader's failure; it does not count against the person |
| Cancelled 1:1 | > 2 consecutive cancellations by the leader | Escalate to the level above |
| Debt with no budget | 0 % of capacity assigned in the cycle | Declare it in writing as a decision, with its reason and review date |
| Postmortem with a proper name as a cause | a person appears as a root cause | Rewrite; whoever approved it answers for it |
| Unfunded postmortem actions | they are not in the next cycle's plan | Escalate: the postmortem loses its function |
| System with no owner | a system in production with no named owning team | Assign it or retire it |
| Leader on the critical path | the team blocks when the leader is away | Redistribute; it is a team design defect |
| Individual metric in circulation | there is a dashboard ranking people by commits, lines, PRs or points | Remove it; §7 |

**Absence test, applicable literally**: the team must deliver and operate normally
during two weeks of the leader's absence. **It is the only indicator of technical leadership that cannot
be faked.**

## 5. Security, risk and ethics of the role

- **Authority and responsibility travel together.** Assigning someone responsibility for a result
  without the authority to take the decisions that determine it (budget, priority, people,
  architecture) **is not delegating: it is transferring blame**. Rule: **when delegating you write down what the
  person decides without consulting, what they consult on and what they escalate.** Without that written split, there is no delegation.
- **The leader is a social engineering target and a point where privilege accumulates.** Review
  periodically what accesses they have and why (`identity-access-management-standards`); production
  access **only if their role actually requires it**, not as a precaution. A leader with permissions for everything
  "just in case" is a single account compromise with total reach.
- **Information about people**: 1:1 notes, evaluations, pay and health are **personal
  data, some of it special category**. Access control, retention period and
  deletion (`privacy-engineering-standards`). **FORBIDDEN** in team chat channels, in
  tickets or in documents with an open link.
- **Pressure to act against technical judgement** (skipping a security review, deploying
  without control, hiding an incident): you respond **in writing**, with the risk named and the
  decision attributed to whoever has the authority to accept it. **Accepting risk verbally is accepting it
  alone**; the formalisation of the acceptance belongs to `grc-compliance-standards`.
- **Notification obligations**: an incident can trigger legal deadlines
  (`incident-response-forensics-standards`, `grc-compliance-standards`, `privacy-engineering-standards`).
  **The leader does not decide whether to notify**: they escalate immediately to whoever does decide. Staying silent is the
  only response that makes the problem worse in every scenario.
- **Retention through pressure** (counteroffers, "you can't leave now"): an orderly exit is planned
  — handover of systems, revocation of accesses, an exit interview whose content is used. Access
  provisioning and deprovisioning belong to `identity-access-management-standards`; the process, to
  `technical-hiring-standards`.

## 6. Sustainability of the role itself and of the team

*(The canonical §6 —performance and operability— does not apply to a process domain; **it is replaced,
declaring it so**, by the operability of the role and that of the team as a system.)*

- **Declared succession.** For every critical responsibility of the leader there is someone who has already
  exercised it, not someone who "could". It is proven by exercising it: rotating who runs the design
  review, who answers for incidents, who handles the relationship with another team.
- **Bus factor per system and per decision.** A system only one person knows how to operate is an operational
  risk with a name; a decision only one person can justify is the same discussion
  again in a year. Both are fixed with a document, not with trust.
- **On-call load and hours**: out-of-hours operation belongs to `sre-practice-standards`, but
  **the decision to sustain an on-call rota with insufficient staffing is a leadership decision, and it is a risk
  decision**: it is declared in writing with its review date, like any accepted risk.
- **Urgency is not a management method.** A team in permanent urgency cannot distinguish what is
  important, stops investing in what would reduce the urgency, and stops believing the real urgencies.
  **Falsifiable indicator**: the proportion of unplanned work in the cycle (`sre-practice-standards`
  defines it). If it sustainedly exceeds the threshold the team publishes, **the cause is in the
  planning or in the system, and that is the conversation**, not demanding more effort.
- **The leader's time audited like any other resource**: if more than ~50 % goes on meetings with no
  associated decision, the §1 test is applied to every recurring meeting and whatever does not pass is eliminated.
- **Minimum review cadence**: ladder and levels, annually; archetypes and staff+ assignments,
  half-yearly; debt budget, per planning cycle; ADRs with an expired review date,
  quarterly; team boundaries and dependencies, half-yearly or on a reorganisation.

## 7. Long-term sustainability and prohibitions

**Deprecation of a team norm**: every rule the leader introduces is introduced **with the
condition that would make it unnecessary**. With no retirement condition, a norm is permanent by
omission, and that is how the process nobody ever explicitly defended accumulates.

**Handover of the role**: a leader who changes job hands over in writing the map of open decisions,
the commitments with other teams, the development state of each person and the pending
decisions with their dates. **Without that document, the successor discovers the problems by way of the
incident.**

FORBIDDEN:
- ❌ **Deciding without recording.** If it conditions someone who was not in the room, it gets written (§3.3).
  An unrecorded decision gets discussed again, and the second discussion is more expensive.
- ❌ **An ADR with no reversibility field**, and **treating every decision as irreversible**: it is the
  documented cause of organisational paralysis (Bezos 2015, §2).
- ❌ **Measuring people by lines of code, commits, PRs, points, *velocity* or individual DORA
  metrics**, not in evaluations, not in dashboards, and not "just to look at it". It contradicts the published
  position of DORA and of SPACE (§3.9) and it gets gamed the day it is published.
- ❌ **Classifying people with the "10x" vocabulary** or with any individual productivity
  ratio: the founding figure has been dismantled (Prechelt 1999, §2).
- ❌ **Using figures with no primary study, sample and method** in a document, a slide or a
  budget request (§2). It applies in particular to the minutes per interruption and to the
  turnover percentages attributed to a bad manager.
- ❌ **Using urgency as a management method.** Everything urgent = nothing prioritised, and the team stops
  believing the next urgency, which will be the real one.
- ❌ **Being the bottleneck for every decision.** If nothing moves without the leader, the problem
  is the distribution of authority, not the team's capability (§3.8, absence test in §4).
- ❌ **Delegating responsibility without authority** (§5). It is a transfer of blame, and it is detected because
  the person cannot name a single decision they can take without consulting.
- ❌ **The leader taking the quarter's critical feature**: it creates a SPOF and switches off the
  developmental part of the work.
- ❌ **Stopping touching the system entirely.** With no contact there is no judgement: designs get approved
  out of trust in the person instead of because of their content (§3.8).
- ❌ **Using code review as a lever of power**: blocking on aesthetics, imposing your own
  solution with no argument, or withholding approval to negotiate something else.
- ❌ **Naming people as a root cause in a postmortem**, and **giving in to pressure from above to
  identify a culprit** (§3.10).
- ❌ **Closing a postmortem whose actions do not enter the next cycle's plan.**
- ❌ **Staff+ archetypes turned into titles, levels or boxes** on the ladder (§3.2): the
  taxonomy itself is descriptive and has published criticism.
- ❌ **An unpublished level ladder**, or a promotion with no written evidence against it.
- ❌ **Surprises in the performance review**: if it is the first time the person hears it, the failure
  is the leader's.
- ❌ **A 1:1 turned into a status report**, or systematically cancelled by the leader.
- ❌ **Defining a level by a technology** ("senior in X"): it expires with the tool.
- ❌ **Reorganising teams with no problem declared in writing and no expected cost.**
- ❌ **A "refactor release" that delivers nothing observable**, and **refactor requests with no quantified
  business cost** (§3.5).
- ❌ **Adopting coding agents without assigning review capacity** or declaring what work is
  reserved for junior learning (§3.11).
- ❌ **Writing in this skill —or in any of the team's leadership documents— a sentence that decides
  nothing.** "Foster trust", "lead by example", "culture of excellence": if it does not
  name an artifact, a threshold or a prohibition, it is superfluous.

## 8. Mandatory web verification

Before fixing any of these points:

1. **SPACE — declared gap.** The full text **could not be retrieved verbatim**: ACM
   Queue (`queue.acm.org/detail.cfm?id=3454124`) and CACM return **403** to automated
   download, and `dl.acm.org` is behind a wall. The formulations in §2 and §3.9 come from consistent
   secondary sources. **Before quoting the article literally, obtain the PDF through a route
   with access** (institutional library, the Microsoft Research publication page) and
   confirm the exact wording of the myths and of the recommendation to measure ≥ 3 dimensions.
2. **DORA**: the current edition and its title at `dora.dev`. As of Aug 2026: **2025 = *State of AI-assisted
   Software Development***; **2026 = *The ROI of AI-Assisted Software Development*** (per InfoQ
   coverage, May-2026, **not confirmed against `dora.dev` in this verification** — confirm it).
   There is published criticism of the 2026 report for resting on speculative recommendations rather
   than the previous research rigour: **verify the declared method before citing it as evidence**.
   Also confirm that the position of not using the metrics at an individual level still holds.
3. **Staff+ archetypes**: whether `staffeng.com` / `lethain.com` still maintain the four archetypes and the
   scale thresholds (~100 / ~1,000 engineers), and whether criticism or an alternative taxonomy
   with a better basis has appeared. **Never present them as a research result.**
4. **Cognitive load and team topologies**: check whether **empirical evidence** has appeared
   (a validated instrument, a replication) that would allow the analogy's status to be raised. Until then it is
   cited as an analogy, not as a measurement, consistent with `platform-engineering-standards` §6.4.
5. **Bezos's 2015 letter**: the verbatim in §2 was extracted from the official PDF. If it is cited again,
   **extract it from the PDF, not from a summary** — most secondary sources misdate it to 2016.
6. **ADR**: whether `adr.github.io` recommends a different default format and whether the Nygard template is still
   the reference; tools (`adr-tools` and successors) and their real maintenance —
   **read the raw `LICENSE`** before adopting any of them.
7. **Any figure about people, productivity, turnover or interruptions**: locate the primary
   study, year, sample and method **before** using it. If it does not appear, or if the methodology is
   contested (10x/Sackman, the 23 minutes, Gallup's 70 % — §2), **it is not used**. This is the
   catalogue's domain with the highest density of folkloric figures.
8. **Public career ladders**: whether `progression.fyi` and `github.com/bmoeskau/engineering-ladders`
   are still alive and which ladders they maintain. Check the date of each one: several are from 2015-2019 and
   describe organisations that no longer exist in that form.
9. **The applicable employment framework** for evaluation, pay, professional classification and dismissal in the
   specific jurisdiction (in Spain: the applicable collective agreement and the Estatuto de los Trabajadores). **This
   document fixes engineering criteria, not employment advice**: the part with legal effects
   is checked with legal counsel and with HR.
10. **Use of AI in decisions about people** (evaluation, promotion, assignment): a legal regime in
    evolution — `ai-governance-standards` and `technical-hiring-standards` §5 maintain the state of the
    **AI Act** and its dates. Verify it before introducing any tool that scores
    people.

If the web contradicts this document, **the web wins** — flag the discrepancy.
