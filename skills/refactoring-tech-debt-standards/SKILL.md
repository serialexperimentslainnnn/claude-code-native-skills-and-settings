---
name: refactoring-tech-debt-standards
description: Standards for managing technical debt and refactoring legacy code. Use when writing or triaging a technical debt register or TODO/FIXME backlog, deciding what debt to pay and how to fund it (fixed capacity slice, boy scout rule, dedicated cleanup project), refactoring code smells (long method, god class, feature envy, primitive obsession, shotgun surgery), adding characterization or golden-master tests to untested legacy code, running large-scale migrations with strangler fig, branch by abstraction, expand/contract and parallel change, debating a full rewrite, reading SonarQube/CodeScene/Code Climate reports, cyclomatic complexity and maintainability index thresholds, change-coupling and hotspot analysis over git history, or separating a refactor commit from a behavioural change.
---

# Refactoring and technical debt standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the road from the code you have to the design you want**: what is debt and what is not, how it is recorded, how it is prioritised, how it is funded, and with which techniques it is paid down without breaking the system. Triggers: "technical debt", "refactor", "refactoring", "legacy code", "code smell", "characterization test", "golden master", "strangler fig", "branch by abstraction", "expand/contract", "parallel change", "rewrite", "big rewrite", "hotspot", "cyclomatic complexity", "maintainability index", "SonarQube", "CodeScene", "debt register", "boy scout rule".

**Guiding principle — technical debt is a financial metaphor and it is only useful if it is used as one.** It has a **principal** (the work of fixing it), **interest** (the extra cost you pay on every change while it is not fixed) and a **decision to pay it down** taken by comparing the two. If you cannot name the interest you are paying, you do not have debt: you have an opinion about the code. Hard corollary: **"debt" is not a synonym for "code I do not like"**, nor for "old code", nor for "the previous team's style".

**Not applicable**:
- `software-architecture-patterns-standards` (**reciprocal**: **theirs the destination** — which style, which boundaries, which pattern and which force justifies it; **here the road** — how you get there without breaking anything). Shared warning: **migrating to a new pattern without tests is swapping one debt for a bigger one**.
- `testing-qa-standards` (**already written — it is the precondition of this skill**: the test strategy, the pyramid, the coverage criteria and test quality are theirs; **here** only the non-negotiable requirement to **cover the behaviour before touching it** and the characterization technique for legacy).
- `code-review-standards` (**already written**: mechanics and criteria of review; from this side we fix that **a refactor and a functional change are not reviewed the same way and do not go in the same commit** — a refactor is reviewed against "is the behaviour still the same?", a functional change against "is the new behaviour correct?").
- `git-workflow-standards` (change size, branches, history, commit mechanics).
- `vulnerability-management-standards` (**theirs** the dependency CVEs, risk-based triage and EOL; **here** the debt of *not having updated* as a decision with growing interest).
- `opensource-licensing-standards` (a dependency that **relicenses** creates debt with an expiry date — its legal criteria belong to that skill; here, the record and the deadline).
- `cicd-standards` (the quality gate that is executed and how it is executed).
- `tech-leadership-standards` (the investment decision and its corporate record), `project-management-standards` (how the work is funded, planned and negotiated with stakeholders).
- `legacy-modernization-standards` (**reciprocal**: **theirs the decision of what to do with an entire system** —the "R" of the model, the archaeology of the platform, the routing to the skill for each inherited technology—; **here the techniques with which it is executed**: *strangler fig*, branch by abstraction, expand/contract, characterization before touching. A vocabulary warning that both uphold: **the "R" for *refactor* in that model is not refactoring** — there it means redesign, here it means changing the structure without changing observable behaviour).
- `migration-projects-standards` (**theirs the cutover**: rehearsal, window, rollback and shutdown of the old system; here what is done with the code in the meantime).
- **Rewrite arbitration**: when `legacy-modernization-standards` decides *rebuild*, **the exceptional conditions that authorise it are those in §6.2 of this skill** and they must be verified one by one. If they are not met, the answer is incremental refactoring, not a rewrite.
- `performance-engineering-standards` (**optimising is not refactoring**: optimisation changes observable characteristics and often deliberately worsens readability. It is measured, justified and reviewed separately).

## 2. Default decisions

> Verify the latest version, licence and price on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Precondition for refactoring | **Tests covering the affected behaviour** | None. If there are none, characterise first (§3) |
| Step size | **The smallest one that leaves the system green**; one commit per step | Larger steps only with a tool-automated refactor |
| Refactoring tool | **The IDE/toolchain one** (rename, extract, inline, move) | Manual only where it does not exist, and with a test first |
| Refactor vs functional change | **Separate commits, always** | — |
| Large migration | **Strangler fig** or **branch by abstraction** + **expand/contract** | Full rewrite: only with the criteria of §6 |
| Prioritisation | **Measured interest** (change frequency × cost of changing) | Never by age or by aesthetic score |
| Register | **Debt in the same backlog as everything else**, with an owner and a trigger | A separate register only if the main backlog does not support metadata |
| Funding | **Fixed percentage of capacity per iteration** + boy scout rule | Dedicated project only with the criteria of §6 |
| Static analysis | The stack's **linter/formatter**, in CI and blocking | A quality platform if it provides new signal (§4) |
| Decision metric | **Change heat map (git) crossed with difficulty of changing** | No aggregate index as a single metric (§4) |

### 2.1 The metaphor, correctly attributed and correctly used

- **Origin: Ward Cunningham**, *"The WyCash Portfolio Management System"*, **OOPSLA '92 experience report** (Addendum to the Proceedings, pp. 29–30, DOI `10.1145/157709.157715`; text at `c2.com/doc/oopsla92.html`). His formulation: shipping code first time **is like going into debt** — a little debt speeds up development **as long as it is paid back promptly with a rewrite**; the danger lies in not paying it back, because **every minute spent on not-quite-right code counts as interest**. **Attribution nuance**: in the text Cunningham develops the debt-and-interest metaphor; the "technical debt" label was consolidated later.
  - **What Cunningham did NOT say**: that debt means deliberately writing badly. His debt is the **mismatch between what the code expresses and what is now understood about the domain** — debt from learning, not from botching. Using his quote to justify haste is a misrepresentation.
- **Quadrant: Martin Fowler**, bliki *"Technical Debt Quadrant"*, **14 Oct 2009**. Two axes: **deliberate vs inadvertent** (did we know we were taking it on?) and **prudent vs reckless** (was it a reasoned decision?):
  - *Deliberate and prudent*: "we have to ship now and we accept the consequences" — legitimate **if it is recorded** (§5).
  - *Deliberate and reckless*: "we do not have time for design" — that is not debt, it is damage.
  - *Inadvertent and prudent*: "now we know how we should have done it" — unavoidable in any good team; it is Cunningham's.
  - *Inadvertent and reckless*: "what is this layering thing?" — solved with training, not with a backlog.
  - The Fowler observation worth retaining: **the useful distinction is not between debt and non-debt, but between deliberate and inadvertent debt.**
- **Operational consequence**: every register entry (§5) declares its quadrant. Reckless ones are not "managed": the cause is cut off (review, training, CI gate). Prudent ones are managed as real debt: principal, interest, trigger.

## 3. Refactoring: definition, precondition and mechanics

### 3.1 Canonical definition (verbatim) and its consequence

**Martin Fowler**, *Refactoring: Improving the Design of Existing Code* (definitions also published at `refactoring.com`):

> *"noun: a change made to the internal structure of software to make it easier to understand and cheaper to modify without changing its observable behavior"*
>
> *"verb: to restructure software by applying a series of refactorings without changing its observable behavior"*

Fowler specifies that **"observable behavior" is deliberately imprecise**: the code must do, broadly, the same as before; the call stack changes with an *extract function* and performance may vary — **nothing the user cares about must change**.

Non-negotiable consequences:
- **A refactor that changes behaviour is a functional change in disguise** and it is reviewed, tested and deployed as such. Labelling it "refactor" so that it gets less scrutiny is a process failure, not a naming detail.
- **Refactoring ≠ restructuring ≠ optimising ≠ rewriting.** Fowler uses "restructuring" as the general term; performance optimisation often **worsens** readability on purpose, and that is why it is not refactoring (→ `performance-engineering-standards`).
- A PR titled "refactor" with 40 files and a bug fix inside is unreviewable: nobody can tell what changed from what moved.

### 3.2 The non-negotiable precondition

**Without tests covering the affected behaviour, you are not refactoring: you are rewriting blind.** The test is the only thing that turns "I changed the structure" into "I did not change the behaviour". The criteria and quality of those tests belong to `testing-qa-standards`; what is fixed here is that **they exist before the first change**.

**Legacy without tests** — reference work and terminology: **Michael Feathers**, *Working Effectively with Legacy Code* (2004). His operational definition, deliberately uncomfortable: **legacy code is "code without tests"** (not "old code"): without tests there is no way to verify that it still does what it did. Consequence: you can write legacy code today.

Procedure when there are no tests:
1. **Characterise first.** A **characterization test** (term coined by Feathers; also *golden master*) *"is a test that characterizes the actual behavior of a piece of code"*: it documents the **real** behaviour, **not the one you wish it had**. Mechanics from the book: write an assertion you know will fail, read the real value in the failure output and pin it.
2. **Bugs are characterised too.** If the current behaviour is incorrect, it is pinned as-is and noted; fixing it is a **separate functional change**, with its own decision and its own commit.
3. **Find the cut point** (*seam*) so you can instantiate and isolate the unit; break the dependency with the smallest possible intervention (the safest one first: extract and inject, do not redesign).
4. Only then refactor, in small steps.
5. For large migrations with tangled dependencies, the **Mikado Method** (Ola Ellnestam and Daniel Brolund, Manning, 2014) gives an explicit procedure: attempt the change, note what breaks as a prerequisite, **revert**, and attack the leaves of the graph. The key is that **you revert**: the tree is discovered with the system always green.

### 3.3 Mechanics: order, tooling and step size

- **Safe order**: first what the tool can do on its own (rename, extract, move, change signature), then what requires judgement (extract class, break a dependency, change the model). Never the other way round.
- **Automated refactor > manual** whenever it exists: the IDE preserves references and does not miss usages. Watch the blind spots: reflection, magic strings, injection by name, embedded SQL, templates, external configuration — there a "safe rename" is not safe.
- **Step size is the safety criterion, not speed.** Rule: if after the step you cannot run the tests and see them green, the step was too big. The worse you know the code, the smaller the step.
- **One commit per green step**, with a message saying which transformation it is. A readable refactoring history is what lets you bisect when something broke three weeks later.
- **Two-hats rule**: at any moment you are either adding functionality or refactoring, never both. If while refactoring you find a bug, note it and carry on; you fix it afterwards, in its own commit.

## 4. What gets paid: interest, heat maps and the metrics trap

### 4.1 Prioritise by interest, not by age or by ugliness

**Ugly code nobody touches costs nothing.** A horrible module, stable, with no incidents and no changes in two years has interest ≈ 0: refactoring it is pure expense and on top of that it introduces risk. The debt that gets paid is the one that **charges interest**:

**Interest ≈ change frequency × difficulty of changing × failure impact.**

Signals of real interest, all observable:
- **Change heat map**: commit frequency per file/module in the Git history, crossed with the difficulty of changing that code. Activity concentrates in a few modules: there, and only there, poor quality is paid for every week.
- **Change coupling**: files that always change together without being related by design (a signal of a badly placed boundary → `software-architecture-patterns-standards`).
- **Defect density and resolution time** per module.
- **Cycle time** of the changes that touch that area, compared with the average.
- **Bus factor**: if only one person can touch it, the interest includes the risk of them leaving.

### 4.2 The metrics trap

Aggregate metrics give a feeling of objectivity and replace the conversation. Real status of the two most cited ones:

- **Cyclomatic complexity (McCabe)**: published and unrefuted criticism.
  - **Shepperd, M. (1988), "A critique of cyclomatic complexity as a software metric", *Software Engineering Journal*** (IET, DOI `10.1049/sej.1988.0003`): poor theoretical foundations and, for much software, **it is no more than a proxy for lines of code**, often outperformed by them.
  - **Jay, G. et al. (2009), "Cyclomatic Complexity and Lines of Code: Empirical Evidence of a Stable Linear Relationship"** (*JSEA*): a stable and practically perfect linear relationship between CC and LOC, verified over more than 1.2 million files; they conclude that **CC adds no explanatory power of its own** beyond size.
  - **Permitted use**: a local threshold as a *smell* that opens a conversation about a specific function. **Forbidden use**: as a quality KPI, as a team target or as a debt prioritisation criterion.
- **Maintainability index (MI)** (Oman & Hagemeister, 1992): worse. It is a weighted combination of Halstead volume, cyclomatic complexity, LOC and comment ratio; **it inherits CC's problem and adds its own**.
  - **Arie van Deursen, "Think Twice Before Using the Maintainability Index" (2014)**: originated in an internal HP project with 16 projects rated by eye and dozens of regression models; the original authors proposed it for **relative comparisons within the same team**, a warning systematically ignored.
  - Tooling criticism (Teamscale, among others): **different tools compute different values** because they tweak the formula, and the developer **cannot predict** how their change will affect it — extracting a method lowers complexity but raises LOC, so improving the code can worsen the index. It also averages and hides the real distribution.
  - **Criteria: the MI is not used to decide anything.**
- **General rule**: a metric works as a **signal that opens an investigation**, never as a target (the moment it is a target, the metric gets optimised instead of the code). **Measuring quality by a single index is forbidden.**

### 4.3 Tools (verify licence and price, §8)

- **The stack's linter and formatter**, in CI and blocking: it is 80 % of the value for 0 % of the cost, and it removes the style argument from review.
- **Architecture fitness functions** (ArchUnit — Apache-2.0 — and equivalents) so that the structure does not erode while you pay down debt. The criteria for which rule to write belong to `software-architecture-patterns-standards`.
- **SonarQube**: **it is not simply "open source"**. Since **29 Nov 2024** the **SonarQube Community Build** binary (formerly *Community Edition*) remains under **LGPLv3**, but **the bundled analysers moved to the Sonar Source-Available License v1 (SSALv1)**, a *source-available* licence with a competitive-use restriction — **it is not open source** under the OSI definition. Community Build **does not analyse branches or decorate PRs**: that is the paywall. Commercial editions are billed **per line of code**, not per user, so the cost grows with the size of the repository. **Verify current pricing with the vendor before quoting it: the figures circulating on blogs are third-party and diverge from each other.**
- **Semgrep**: open source CLI engine (LGPL-2.1, copyleft — relevant if you package a product); the cloud platform is paid per contributor and **the rates published by third parties contradict each other** ($35 vs $40+ per contributor/month depending on the source): confirm with the vendor.
- **CodeScene**: behavioural analysis over the Git history (hotspots, change coupling, function-level X-Ray, *Code Health* metric). It is the category that best fits §4.1. **Commercial product** and **proprietary metric**: its supporting studies are authored by its founder and use its own metric — a conflict of interest that must be declared before citing them as independent evidence.
- **Cross-cutting rule**: no tool decides which debt gets paid. They produce candidates; the decision is human and goes into the register (§5).

## 5. The debt register (§5 substituted: "stack security" would be artificial in a process domain — security appears here as dependency debt and as a prioritisation criterion, and its management belongs to `vulnerability-management-standards`)

A debt entry that cannot be acted on is noise. Minimum fields, and **all mandatory**:

| Field | Why |
|---|---|
| **What it is** | Concrete and locatable description (module/file), not "the backend is bad" |
| **Quadrant** (§2.1) | Deliberate/inadvertent × prudent/reckless: determines whether it is managed or the cause is cut off |
| **Principal** | Estimate of the work to fix it |
| **Observed interest** | The evidence from §4.1, with data: "touched in 3 out of 4 sprints", "4 incidents in 6 months" |
| **Consequence if unpaid** | What degrades and for whom |
| **Owner** | A named person, not a generic team |
| **Trigger** | The event that turns it into planned work |
| **Review date** | When it gets looked at again to see if it still makes sense |

Rules:
- **Debt with no owner and no date does not exist**: it is closed or deleted. A register that only grows is a graveyard and after six months nobody opens it.
- **The trigger is what prevents the graveyard register**. Useful forms: "when we touch this module for the third time", "before adding the second payment provider", "when version X reaches EOL (date)", "if the cycle time of this area exceeds N".
- Debt lives **in the same backlog** as the rest of the work and competes for priority with data, not in a parallel document no planning session ever looks at.
- **`TODO`/`FIXME` in the code are not a register**: they are notes. If something matters, it is recorded with an owner; if not, it is deleted. A `TODO` from 2019 is a signed lie.
- **Deliberate and prudent debt ⇒ recorded in the same PR that takes it on**, with its reason. That is the only moment when the context is fresh.

## 6. Large-scale strategies and funding (operability of change)

### 6.1 Strategies, with verified attribution

- **Strangler fig** — **Martin Fowler**, *"Strangler Application"*, **29 Jun 2004**, **later renamed to "Strangler Fig Application"** (the original text is preserved at `OriginalStranglerFigApplication.html`). The metaphor is taken from the strangler figs of the Queensland rainforest. Idea: grow the new system **at the edges** of the old one, diverting traffic feature by feature until the old one can be retired. Requirements: an interception point (facade, proxy, routing) and **usage telemetry** to know when the old one is no longer used. **Retiring the old code is part of the task**, not future debt.
- **Branch by abstraction** — **Paul Hammant** documented and named the term in **2007** (crediting the coinage to **Stacy Curl**); Hammant is explicit that **he did not invent it**, it was a known practice without a name. **Jez Humble** and **Martin Fowler** popularised it later with real cases. **Attributing the origin jointly to Hammant and Humble is incorrect.** Idea: introduce an abstraction over the current provider, migrate clients so that they only talk to it, implement the new provider behind it, switch over, and **remove the abstraction if it no longer adds anything**. It is the alternative to a long-lived branch: it lets you ship while the big change is half done.
- **Expand/contract (parallel change)** — the canonical reference is **Danilo Sato**, bliki *"ParallelChange"* on martinfowler.com, **13 May 2014**; the name "expand and contract" comes from the world of schema evolution (*Refactoring Databases*, Scott Ambler and Pramod Sadalage). Three phases: **expand** (add the new without removing the old) → **migrate** (move all consumers) → **contract** (retire the old).
  - **For a database schema**: never rename or drop in the same release that deploys the code; new column, dual write, backfill, read from the new one, and drop the old one **in a later release** with usage already at zero.
  - **For an API**: the new coexists with the old, usage is measured per consumer and it is retired with a communicated deadline (contract governance belongs to `api-design-standards` / `microservices-architecture-standards`).
  - **The *contract* phase is mandatory and must be planned.** An expand/contract that never contracts has doubled the debt with permission.

### 6.2 Why a full rewrite is almost always the worst option

Classic reference: **Joel Spolsky, "Things You Should Never Do, Part I", 6 Apr 2000**, written in the wake of Netscape 6, which he calls *"the single worst strategic mistake that any software company can make: They decided to rewrite the code from scratch"*. **It is an argument, not data**: it is cited for its reasoning, not as empirical evidence.

Reasons that hold up:
- The old code contains **years of fixes for real cases that are not documented anywhere else**. The rewrite loses them and rediscovers them in production, one by one.
- During the rewrite there are **two systems to maintain** and new functionality frozen; the business rarely tolerates that freeze, so the old one keeps growing and the finish line recedes.
- The new team usually **underestimates the domain, not the technology**: the hard part was not the framework.
- It is **big bang**: risk is concentrated in a single cutover, with no intermediate feedback and no realistic way back.

**Exceptional conditions in which it can indeed be the right option** (all verified, and in an ADR — `software-architecture-patterns-standards`):
- The base platform is **dead or unsupported** and there is no migration path (discontinued runtime/language/vendor with no way out).
- The system is **small and its behaviour is specified or reproducible** (it can be characterised in full and outputs compared in parallel).
- **There is nobody** who can modify it and acquiring the knowledge is not viable (the code is already a de facto black box).
- The new requirement is **incompatible at its core** with the current model (e.g. multi-tenancy or regulation that cuts across the whole data model) and the cost of adapting exceeds that of redoing it, **calculated**, not guessed.
- Even so: do it **in parts with strangler fig and parallel run comparing outputs**, not as a single cutover.

### 6.3 How the work is funded

Three models; they are combined, not chosen exclusively. Negotiation and planning belong to `project-management-standards`.

| Model | When | Risk |
|---|---|---|
| **Fixed percentage of capacity** (e.g. an agreed fraction of each iteration) | **Default**. Continuous, predictable debt, no case-by-case justification needed | It evaporates under pressure if it is not protected; it must be made visible in planning, not invisible |
| **Opportunism / boy scout rule** | Local debt, in code you are going to touch anyway. Almost zero marginal cost | It only scales to the small; if the fix overflows the PR, it is recorded and planned |
| **Dedicated project** | Only structural migrations with a large, indivisible principal (engine, platform or data model change) | High (see below) |

- **Boy scout rule**: "leave the code better than you found it", **adapted to software by Robert C. Martin** in *Clean Code* (2008) from the scouting motto — **popularisation and adaptation, not invention**: the campsite formulation is much older. Operational limit: **the opportunistic improvement must not bloat the diff of the functional change** (it clashes with `code-review-standards`). If it does not fit in the same PR in a reviewable way, it goes in its own refactor PR, before or after.
- **Why the dedicated "cleanup" project usually fails**: it delivers no visible value for months, so it is the first to be cancelled when the business squeezes; it freezes or duplicates the product team's work; it is measured by work done and not by interest eliminated, so it tends to clean what is easy instead of what is expensive; and it ends up being a covert rewrite with the risks of §6.2. **If it is done: closed scope, incremental deliverable every few weeks, a measurable success criterion over interest (§4.1) and an end date.**
- **Honest negotiation rule**: argue with **interest**, not with morality. "This module is touched in 3 out of 4 iterations and each change costs twice the average" convinces; "the code is dirty" does not, and rightly so.

## 7. Debt that is not code, sustainability and prohibitions

Debt does not live only in the code. These categories are recorded the same way (§5) and usually have **growing interest and a hard date**:

- **Dependencies not updated**: the cost of skipping N versions grows faster than linearly. Default: continuous, automated updating (dependency bot) with CI that validates it; the big jump is avoided, not planned. CVEs and their triage belong to `vulnerability-management-standards`.
- **Versions out of support (EOL)**: it is the only debt with a **date known in advance**; it enters the register with the trigger set on the day the end-of-support calendar is published, not the day it expires.
- **A dependency's licence change**: relicensing upstream (to *source-available* or strong copyleft) turns a harmless dependency into debt with a deadline. Detecting it requires reading the raw `LICENSE`, not the README. Legal criteria: `opensource-licensing-standards`.
- **Non-reproducible infrastructure**: pet servers, manual configuration, environments that only work on one machine. The interest is charged in full on the day of the incident.
- **Knowledge in a single head**: it is debt with a total-default risk. It is amortised with cross-review, rotation, documentation of the *why* and pairing on the critical module.
- **Test debt**: a slow suite (nobody runs it), flaky tests (nobody believes them), coverage concentrated on the trivial and absent on the critical, tests coupled to the implementation (they prevent refactoring — the worst of all, because **it blocks paying down the rest of the debt**). The criteria for what a good test is belong to `testing-qa-standards`.
- **Process and data debt**: manual deployments, absence of a tested rollback, historical data with incompatible schemas.

### List of prohibitions
- ❌ **FORBIDDEN to call anything "debt"**: without principal, observable interest and a declared consequence, it is a style preference. And style is solved by the formatter, not by the backlog.
- ❌ **FORBIDDEN to refactor without tests covering the affected behaviour.** If they do not exist, characterise first (§3.2).
- ❌ **FORBIDDEN to mix refactor and functional change in the same commit** (and, except in trivial cases, in the same PR): they are reviewed with different criteria and together they are unreviewable.
- ❌ Labelling as "refactor" a change that alters observable behaviour.
- ❌ **Full rewrite as the default answer**, or without meeting and documenting the exceptional criteria of §6.2.
- ❌ **Measuring quality by a single index** (cyclomatic complexity, maintainability index, coverage, debt in a tool's "days") or turning it into a team target.
- ❌ Using the **maintainability index** to decide priorities (§4.2).
- ❌ Prioritising debt by age, by ugliness or by tool score instead of by measured interest.
- ❌ Refactoring stable code nobody touches "while we are at it" (risk with no return).
- ❌ Debt entries **without an owner, without a trigger or without a review date**.
- ❌ `TODO`/`FIXME` with no associated issue as a substitute for the register.
- ❌ A long-lived refactor branch in parallel to the development one (use branch by abstraction; see `git-workflow-standards`).
- ❌ Expand/contract without the **contract** phase planned and executed.
- ❌ Fixing a bug discovered during characterisation inside the same commit: the real behaviour is pinned and the fix goes separately.
- ❌ **Migrating to a new pattern or architecture without tests: it is swapping one debt for a bigger one** (reciprocal of `software-architecture-patterns-standards`).
- ❌ Citing figures from this domain without a primary study and methodology (§8).

## 8. Mandatory web verification

Before committing anything from this document to a real deliverable, **verify with WebSearch/WebFetch** (the data is from August 2026):

1. **SonarQube**: current licence of the Community Build binary (LGPLv3 as of this date) **and of the analysers** (SSALv1 since 29 Nov 2024) read at `sonarsource.com/license/` and in the repository's raw `LICENSE`; what is left out of Community Build (branch analysis, PR decoration); **current prices confirmed with the vendor** — third-party blog tables are estimates and **contradict each other**. Same for **Semgrep** (LGPL-2.1 for the CLI; cloud rates disputed between sources) and for **CodeScene** (commercial; its price is not clearly published).
2. **ArchUnit** and per-stack equivalents: version and licence from the raw `LICENSE`, not from aggregators (MvnRepository lists licences mixed in from bundled dependencies).
3. **Status of the methodological criticisms** in §4.2 (Shepperd 1988; Jay et al. 2009; van Deursen 2014): check whether a later refutation exists before relying on them. As of Aug 2026 none has been located.
4. **Bibliography and attributions**: date and canonical URL for Fowler (*TechnicalDebtQuadrant*, *StranglerFigApplication*), Sato (*ParallelChange*), Hammant (*Branch by Abstraction*), Cunningham (OOPSLA '92) and the current edition of Fowler's *Refactoring* and Feathers' *Working Effectively with Legacy Code*. **An incorrect attribution is a factual error.**
5. **EOL of the dependencies** you declare as debt with a date: `endoflife.date` and the project's official source. `api.github.com` returns **403 unauthenticated**: for a repository's activity, use the website or the Atom feed of releases.

**Declared gap (no research budget in this draft)** — pending verification before use:
- **Cost figures for technical debt**: no primary study with sound methodology has been located that would allow asserting a percentage of development time lost to poor quality. **Discarded for lack of a primary source**: the "10×/100× cost of fixing a defect by phase" (the trail dies in internal IBM notes from 1981 via Pressman; documented by Bossavit, *The Leprechauns of Software Engineering*) and the "80 % of lifecycle cost is maintenance" (it entered the literature as an informal estimate cited in Lientz & Swanson, not as a measurement). **Declared discrepancy**: the widely circulated "up to 42 % of developers' time wasted" comes from vendor surveys, not from measurement; the *Code Red* study (Tornhill & Borg, TechDebt 2022, DOI `10.1145/3524843.3528091`) is indeed peer-reviewed and with a replication package, but **it uses the proprietary metric of the tool belonging to one of its authors** — cite it declaring that conflict of interest, or do not cite it.
- **Concrete thresholds** for any metric (complexity, size, coverage): they are deliberately not fixed here; any number adopted must be justified against your own code base, not copied.

If the web contradicts this document, **the web wins** — flag the discrepancy.
