---
name: product-discovery-standards
description: Reducing the risk of building something nobody needs, before it is built. Use when deciding how much discovery a decision deserves and whether it is reversible, addressing the four product risks (value, usability, feasibility, business viability) from Marty Cagan and SVPG, running customer interviews about past behaviour instead of future intent, building an opportunity solution tree (Teresa Torres, Continuous Discovery Habits) to trace a solution back to an outcome, writing a problem statement behind a requested feature, choosing an experiment (paper or clickable prototype, smoke test, fake door, concierge, Wizard of Oz) and its ethical and privacy limits, designing an A/B or online controlled experiment with a minimum detectable effect, power and sample-size calculation and duration fixed in advance, one primary metric plus guardrails, sample ratio mismatch checks, the peeking problem and always-valid or sequential inference, multiple-comparison correction, deciding when an A/B test is impossible (low traffic, network effects, structural change), separating outcome metrics from activity and vanity metrics, applying Goodhart's law to a target, using HEART or AARRR metric frameworks, running dual-track discovery alongside delivery, killing an idea as a successful outcome, or doing discovery for an internal product or platform with captive users.
---

# Product discovery standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Discovery exists to reduce the risk of building what nobody needs.** Criteria for its existence,
applicable on Monday: **if by the end of a discovery activity no decision has changed —not the scope,
not the order, not the "we are not doing it"—, it was not discovery, it was
theatre.** A discovery whose only possible outcome is "we carry on" is not an experiment:
it is an approval ceremony.

Corollary that governs everything else: **the decision to kill an idea is the most valuable outcome
of the process** (§6.3), and a discovery function that never kills anything is measuring its own
consensus.

Covers: the four product risks, the criteria for how much discovery a decision deserves,
behavioural interviews, opportunities and solutions (opportunity tree), experiments without
building (prototypes, smoke, concierge, Wizard of Oz) and their ethical limit, quantitative
experimentation (A/B with power, sample and duration fixed in advance), outcome metrics versus activity,
Goodhart, dual track, and discovery in internal products.

**Not applicable**:
- `project-management-standards` (**clean boundary**: **what gets built and why belongs here; how it
  is delivered —plan, dependencies, execution risk, status report— is theirs**).
- `analytics-bi-standards` (**theirs** the dashboard, the **canonical definition of each metric**
  and who decides with it; **here** which metric deserves to exist and which decision hangs on it. If a
  metric in this document is not defined there, it is not a metric: it is an opinion with a number).
- `llm-evaluation-standards` (**measuring a non-deterministic system is theirs**: the A/B of §5 does not
  apply as-is when the variant is a generative model).
- `data-governance-quality-standards` (quality, lineage and contracts of the data used to decide).
- `privacy-engineering-standards` (**hard precondition, not advice**: the **legal basis** for
  processing user data in an experiment —including *fake door*, concierge and Wizard of
  Oz— is decided by their rules **before** launching. Without a legal basis there is no experiment, however good
  the learning is).
- `accessibility-standards` (**conformance is not subjected to an A/B test**: WCAG is a requirement, not a
  hypothesis; a variant that degrades accessibility is discarded even if it wins on conversion).
- `platform-engineering-standards` (**reciprocal**: an internal platform is a product with
  customers who may not use it; **discovery of their needs happens here** and its adoption
  governance, there).
- `tech-leadership-standards` (who decides, decision record and budget).
- `web-performance-standards` (**the measured effect of performance on conversion is their data
  territory**; here only the design of the experiment that measures it).
- `enterprise-architecture-standards` and `knowledge-management-standards`. **The landscape decides which
  systems exist; discovery, what gets built; documentation is what remains written of
  both decisions.**

## 2. Default decisions

> Verify authorship, version and source on the web before citing them in a formal document (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Risk taxonomy | **Four risks**: value, usability, feasibility, business viability (SVPG / Marty Cagan) | None; extending it requires justifying which risk it does not cover |
| Discovery effort | **Proportional to irreversibility and cost** (§3.1) | None |
| Primary source | **Interview about past behaviour**, continuous | Usage analytics when the question is "how much", not "why" |
| Survey | **Only to size something already observed** | Never as a substitute for observation (§7) |
| Traceability | **Opportunity tree** (outcome → opportunity → solution → experiment) | Any equivalent explicit tracing, written down |
| Prototype | **The lowest fidelity that answers the question** | High fidelity only for usability risk |
| Quantitative | **A/B with sample, power and duration fixed in advance** | Sequential / *always-valid* inference **if decided in advance** (§5.3) |
| Success metric | **One primary outcome metric + guardrails** | Never two primaries |
| Cadence | **Continuous dual track** | None: discovery is not a preceding phase (§6.1) |
| Admissible outcome | **Includes "we do not build it"** | None |

### 2.1 The four risks and their origin

- Reference formulation: **Silicon Valley Product Group / Marty Cagan, essay *The Four Big
  Risks*** (`svpg.com/four-big-risks/`) and ***INSPIRED*, 2nd edition**. Evolution declared by the
  author himself: the 1st edition used three attributes (valuable, usable, feasible) and **value
  was later split into *value* and *business viability*** because viability was systematically
  ignored.
  - **Value**: the customer will not buy it or the user will not choose it.
  - **Usability**: the user will not know how to use it.
  - **Feasibility**: it cannot be built with the available time, capabilities and technology.
  - **Business viability**: the rest of the organisation —legal, finance, sales, marketing,
    brand— cannot sustain it.
- **Citation caution**: the short sentence going around ("Before we build, we must address four big
  risks…") **does not appear verbatim** in the essay consulted; it is a paraphrase. **Cite the essay and the
  book, not the sentence.** The author has also used "desirability" instead of "value" — if cited,
  say which version.
- **Operational rule**: all four are addressed **before building**, and **the risk most often skipped
  is business viability** because it has no natural owner in the technical team. Giving it a named owner
  is part of the process design, not a detail.

## 3. How much discovery, and about what

### 3.1 The effort criteria: reversibility × cost

| Situation | Proportionate discovery |
|---|---|
| Reversible and cheap (flag, copy, order of a list) | **None beforehand: it is launched and measured.** Discussing it in a meeting costs more than testing it |
| Reversible and expensive (a sprint's worth of functionality) | Interviews + prototype + success criteria written in advance |
| **Irreversible** (data migration, multi-year contract, pricing model change, public API) | Formal discovery: experiment with hypothesis, evaluated alternative and recorded decision (ADR / decision record → `tech-leadership-standards`) |
| Regulatory or accessibility | **It is not discovered: it is complied with.** It is not a hypothesis |

**Anti-paralysis rule**: the cost of discovery cannot exceed the cost of getting it wrong and
correcting it. If building the experiment costs more than building the functionality, **the
functionality is built behind a flag and measured**.

### 3.2 Interviews: past behaviour, not future intent

- **"Would you use this?" carries no information** and its answer is systematically positive: the
  interviewee answers out of politeness, out of imagination and at no cost. An answer that cannot be
  "no" is not data.
- Ask about **dated facts**: *"tell me about the last time you had to do X"*, *"what
  exactly did you do?"*, *"how long did it take you?"*, *"what did you use instead?"*, *"what happened
  next?"*. The concrete story contains behaviour; the opinion contains a desire to please.
- **FORBIDDEN in an interview**: describing the solution before understanding the problem, asking in
  the hypothetical, asking about price in the abstract ("would you pay €20?"), and stringing together closed questions.
- Process rules: **weekly cadence** (one sustained weekly interview is worth more than twenty in
  a dead month), **the three heads attend** (product, design, engineering) because second-hand
  learning does not change decisions, and **notes are stored linked to the opportunity**
  (`knowledge-management-standards`).
- **Recruitment bias**: interviewing only the customers who reply to the email produces the
  product wanted by the customers who reply to the email. **Those who left and those who never
  came in are the missing sample**, and their absence is declared.

### 3.3 Opportunity and solution: the tree as traceability

- **Opportunity tree** (*opportunity solution tree*): **Teresa Torres**, formulated in **2016**
  and developed in ***Continuous Discovery Habits*** (2021, ISBN 978-1736633304); intellectual root
  acknowledged in Bernie Roth's (Stanford) work on connecting desired solutions with
  underlying needs. Structure: **outcome → opportunities → solutions → experiments**.
- Real use, not decorative: **every solution on the roadmap hangs from an opportunity, and every
  opportunity from a measurable outcome.** A solution that hangs from nothing is a request, not a
  decision.
- **The trap of the feature list with no problem behind it**: a backlog is a list of
  solutions; without the associated opportunity it cannot be prioritised (there is nothing to compare against), it cannot
  be killed (there is no criterion) and it cannot be replaced by something cheaper that solves the same thing.
  **Rule: every roadmap item carries, written in one sentence, the opportunity it attacks and
  how it will be known whether it solved it.** Without that sentence it does not get in.
- **Comparing alternative solutions for the same opportunity is mandatory**: a single evaluated
  option is not a decision, it is a justification.

## 4. Qualitative experiments and their ethical limit

*(Section 4 of the template —quality and testing— reinterpreted: the equivalent here is what can be
learned without building and under what conditions the learning is legitimate.)*

| Technique | Which risk it attacks | What it does **not** prove |
|---|---|---|
| Paper / low-fidelity prototype | Usability and comprehension of the concept | That someone would actually use it |
| High-fidelity clickable prototype | Fine-grained usability, flow | Value |
| **Smoke test / *fake door*** (ad or button for something that does not yet exist) | **Value**: revealed intent with a cost | Neither retention nor willingness to pay |
| Landing page with a waiting list | Value and messaging | Usage |
| **Concierge** (the service is delivered manually, the user knows it) | Value and operational viability | Neither scalability nor unit cost at scale |
| **Wizard of Oz** (it looks automatic, there are people behind it) | Value of automation before automating it | Technical feasibility |
| Technical prototype / *spike* | **Feasibility** | Value |

**Hard limits, not recommendations:**

- **The user is not deceived about the processing of their data.** In concierge and Wizard of Oz **there are
  people reading user content**: that is processing which must have a legal basis,
  information for the data subject and access control → `privacy-engineering-standards`. **The simulation
  may hide the implementation; never who sees the data.**
- **Fake door**: the user who presses a button for something non-existent deserves an honest, immediate
  answer ("not available yet") and **must not pay, nor lose work, nor be left in an
  inconsistent state**. A fake door in a purchase flow or in a critical flow is **FORBIDDEN**.
- An experiment that only works if the user does not find out **is not launched**. Test: if you had
  to explain it afterwards in public, would you defend it?
- Personal data collected "just in case" in an experiment: **FORBIDDEN** (minimisation).

## 5. Quantitative experimentation

### 5.1 What is fixed **before** launching (and written down)

1. **Hypothesis** in falsifiable form: what changes, in which metric, in which direction, and **what result
   would make it be discarded**.
2. **One primary metric** of outcome. **Two primaries = none**, because there will always be one that
   wins.
3. **Guardrails** that can kill the experiment even if the primary wins: errors, latency
   (`web-performance-standards`), accessibility, complaints, unit cost (`finops-standards`).
4. **MDE** (minimum detectable effect) **decided by its business relevance**, not by what comes out
   significant: what improvement justifies the cost of maintaining this change forever?
5. **Power and sample-size calculation** with that MDE (80 % power and α 0.05 as a starting
   point; declare it if changed).
6. **Duration fixed in advance**, and **never shorter than a full weekly cycle** (Monday behaviour
   is not Saturday's). If the sample is reached in two days, the week is completed anyway.
7. **Written decision rule**: what is done if it wins, if it loses and if it is inconclusive. **"Not
   conclusive" is a result, and its default action is not to launch.**

### 5.2 Validity: what invalidates a result

- **Sample Ratio Mismatch (SRM)**: if the observed split deviates from the designed one in a
  statistically improbable way, **the experiment is not analysed, it is debugged**. Kohavi documents the case
  of 821,588 vs. 815,482 users (50.2 % versus 50.0 %) with p ≈ 1.8e-6 → result discarded.
  **SRM check mandatory before looking at the primary metric**, and on the randomisation
  unit (not on page views or sessions). References: Fabijan et al., *Diagnosing
  Sample Ratio Mismatch in Online Controlled Experiments*, KDD '19; Kohavi, Tang & Xu, *Trustworthy
  Online Controlled Experiments*, ch. 21.
- **Contamination**: same user in both arms (multi-device, cache, anonymous session → login).
- **Novelty effect and primacy effect**: the first week's spike is not the effect.
- **Post-hoc segmentation without correction**: looking for the segment where the result comes out well is
  manufacturing significance (§5.4).

### 5.3 *Peeking* — **stopping on seeing significance is forbidden**

- Repeatedly looking at a test designed with a fixed sample and stopping as soon as it crosses the threshold **produces
  false positives systematically**: naively reapplying conventional tests at every
  instant ends up detecting an effect even when none exists (Johari, Koomen, Pekelis & Walsh, *Peeking at
  A/B Tests*, KDD '17; extended version in *Operations Research*, 2021).
- **Rule**: with a fixed-sample design, **the result is read once, upon reaching the planned sample and
  duration**. Full stop.
- **If you need to look earlier**, it is decided **before launching** to use **sequential /
  *always-valid* inference** (always-valid p-values, mSPRT, *alpha spending*). It is not free: **it is paid for
  in power**, and detecting small effects becomes harder. Changing method halfway through the test
  invalidates both.
- **Legitimate and sole exception**: early stopping due to **harm** (broken guardrail, error, revenue
  loss). The harm threshold is defined in advance and only that is monitored.

### 5.4 Multiple comparisons

- A test with one primary and many secondary metrics **will produce "significant" secondaries
  by chance**: with α=0.05 and 20 independent metrics, one false one per test is expected.
- **Rule**: the decision hangs **only** on the primary. Secondaries are hypothesis
  generators, and **when analysing them a correction is applied** (Bonferroni if there are few and the decision is
  critical; Benjamini-Hochberg-style FDR control if there are many and they are exploratory). **Declare which one was
  used.**
- The same for variants: an A/B/C/D is a multiple-comparisons problem, not four tests.

### 5.5 When an A/B test **cannot** be done

- **Insufficient traffic**: if the calculation in §5.1 yields a duration longer than the horizon of the
  decision (e.g. > 6-8 weeks), the test does not exist. Alternatives: measure a bigger change, use a
  more sensitive metric upstream, or decide with qualitative evidence and own it in writing.
- **Network effects / two-sided markets**: the control arm is contaminated by the treatment one
  (marketplaces, messaging, social networks). Alternatives: *cluster* randomisation (city,
  team, cohort) or *switchback* experiments, both with less power and more assumptions.
- **Structural changes**: complete redesign, price change, platform migration. The
  effect measured in the short term will be dominated by surprise, not by value. Alternatives: progressive
  rollout with guardrail monitoring, cohorts over time, test markets.
- **Small and captive populations** (internal product, B2B with 40 customers): **there is no test**; there are
  interviews, pilots and observed adoption (§6.4).
- **Regulatory or accessibility matters**: they are not tested.
- **When it cannot be tested, the rule is to declare the uncertainty and make the change reversible**
  (flag, rollback plan), not to fake rigour with an underpowered test. **A test without power is not
  weak evidence: it is noise that looks like data.**

## 6. Metrics, cadence and contexts without external users

### 6.1 Outcome, activity and vanity

| Type | Example | What happens to it when it becomes a target |
|---|---|---|
| **Outcome** (customer behaviour or business effect) | Tasks completed per week, 30-day retention, time to first value | It is the only defensible one; even so it requires guardrails |
| **Activity** (what the team does) | Features delivered, stories closed, experiments launched | It is trivially inflated; it says nothing about the user |
| **Vanity** (always grows and decides nothing) | Cumulative registered users, total downloads, page views | It never goes down, so it never disproves anything |

**Metric test**: *what different decision would we take if this number dropped by 20 %?* Without a
concrete answer, the metric is not published.

### 6.2 Goodhart's law, with its original formulation

- **Original (Charles Goodhart, 1975)**: *"Any observed statistical regularity will tend to collapse
  once pressure is placed upon it for control purposes."* (context: United Kingdom monetary
  policy; also collected in *Monetary Theory and Practice*).
- **Frequent correction**: the popular version *"When a measure becomes a target, it ceases to be a
  good measure"* **is not Goodhart's**: it is due to **Marilyn Strathern (1997)**, citing Keith
  Hoskin's (1996) formulation. If the short sentence is cited, it is attributed to Strathern. Related
  to **Campbell's law** (formulations from 1969 onwards), which probably precedes it.
- **Operational use, not ornamental citation**: (a) **every primary metric carries guardrails** that
  detect its cheap way of going up; (b) **the metric that sets the team's target cannot be
  the same one used to evaluate people** (→ `tech-leadership-standards`); (c) if a
  metric goes up while the business outcome does not move, **the metric is being optimised, not
  the product**.

### 6.3 Metric frameworks, with their origin

- **HEART** (Happiness, Engagement, Adoption, Retention, Task success) + **Goals-Signals-
  Metrics** process: Rodden, Hutchinson & Fu, *Measuring the User Experience on a Large Scale:
  User-Centered Metrics for Web Applications*, **CHI 2010** (Google). Oriented to **experience
  quality**.
- **AARRR "pirate metrics"** (Acquisition, Activation, Retention, Referral, Revenue): **Dave
  McClure, 2007**. Oriented to the **growth funnel**. (Sources disagree about the exact
  presentation event —Ignite Seattle or a Seedcamp workshop—; the year, 2007, is consistent.)
- **Usage rule**: a metric framework **does not choose the metric, it only prevents omissions**. **One
  primary per objective** is chosen and defined canonically in `analytics-bi-standards`. **Adopting HEART or
  AARRR wholesale and reporting their five boxes every month is activity, not measurement.**

### 6.4 Dual track: **discovery is not a preceding phase**

- **Same team, same period, two streams**: discovery (what to build and why) and delivery
  (building it well). Not two teams, not two phases, not "sprint 0".
- Signs it has degraded into a phase: delivery waits for "discovery to finish"; there is
  a discovery backlog approved months in advance; the delivery team receives
  specifications it cannot discuss.
- **Minimum weekly commitment**: at least one customer contact and at least one discovery
  decision recorded per week. Less than that, and it is not continuous.
- **Killing an idea is the best possible outcome.** For it to be possible it has to be made cheap:
  (a) success criteria **written in advance** —without them nobody can declare the failure—, (b) with no author's
  name stuck to the idea, (c) **publicly celebrating the saving**, quantified in person-weeks not
  spent. **Metric for the function: number of ideas discarded after discovery per quarter. If
  it is 0, the process is validating, not discovering.**

### 6.5 Discovery without external users (internal product, platform)

- The internal customer **is not captive even if it looks that way**: they can dodge the tool, build their
  own or open a ticket to bypass it. **Desertion is the signal**, and forced adoption
  destroys it (premise of `platform-engineering-standards`).
- Advantages to be exploited: **unlimited access to the users** (they are in the building) and
  **real telemetry of their work**. The excuse "we have no users" is false in internal products.
- Real limitation: **there is no traffic for A/B**. Substitutes: pilot with a volunteer team, observed
  usage (not a satisfaction survey), **time to first useful result** and **30-day
  abandonment**.
- **Specific trap**: confusing the one who pays (an executive) with the one who uses (the teams). The
  sponsor approves; the user decides whether it lives. **You interview the one who uses it.**
- An experiment with employees as subjects **also** has privacy and employment-relationship
  requirements: monitoring a person's work is not just product telemetry →
  `privacy-engineering-standards`.

## 7. Long-term sustainability and prohibitions

- **Sustainable cadence**: weekly customer contact; quarterly review of the opportunity
  tree against the outcome; **retirement of metrics** that no longer decide anything (same pruning
  criteria as dashboards in `analytics-bi-standards`).
- **Preserving the learning**: every experiment leaves a record with hypothesis, design, result
  and **decision taken**, linked to the opportunity and stored where it will be searched for
  (`knowledge-management-standards`). **A learning that cannot be recovered gets paid for again.**
- Prohibitions:
  - ❌ **Validating an idea by seeking confirmation.** You design the experiment that **could kill it**; if
    no possible result kills it, it is not an experiment.
  - ❌ **Survey as a substitute for observation.** The survey sizes what has already been observed; it does not
    discover.
  - ❌ **Asking about future intent** ("would you use…?", "would you pay…?") and treating the answer as data.
  - ❌ **A/B test without a prior calculation of sample, power and duration.**
  - ❌ **Stopping a test on seeing significance** (§5.3), except for a harm stop defined in advance.
  - ❌ **Changing the primary metric, the design or the segmentation with the test running.**
  - ❌ **Reporting a significant secondary without multiple-comparisons correction.**
  - ❌ **"A customer asked for it" as the sole justification.** A request is a proposed solution: you have
    to recover the problem, and check how many it affects.
  - ❌ **Discovery that never kills anything** (§6.4).
  - ❌ **Fake door in a critical or payment flow**, and any experiment that deceives about **who sees
    the user's data** (§4).
  - ❌ **Subjecting an accessibility, privacy or legal requirement to an A/B test.**
  - ❌ **Citing product failure rates or feature usage rates without a primary source and
    methodology** (§8): in an investment discussion, a figure without a source destroys the entire
    argument when somebody checks it.
  - ❌ **Roadmap with dates for items not yet discovered**: it turns discovery into
    a formality (→ `project-management-standards` for how a commitment is communicated).

## 8. Mandatory web verification

Check before committing to or citing anything:

1. **Four risks**: `svpg.com/four-big-risks/` and *INSPIRED* 2nd ed. **The short sentence going around
   is a paraphrase, not verbatim** — verified in this pass; cite the essay/book.
2. **Opportunity tree**: Teresa Torres, 2016; *Continuous Discovery Habits* (2021). Confirm
   on `producttalk.org` before attributing variants of the diagram.
3. **Goodhart's law**: original 1975 formulation (verbatim in §6.2) and **correct attribution of
   the popular version to Strathern (1997), not to Goodhart**.
4. **Peeking and always-valid**: Johari et al., KDD '17 / *Operations Research* 2021. **SRM**: Fabijan
   et al., KDD '19 and Kohavi/Tang/Xu ch. 21. Verify the concrete method implemented by the
   tool you use **before** trusting its "significance".
5. **HEART**: Rodden, Hutchinson & Fu, CHI 2010. **AARRR**: McClure, 2007 (**declared discrepancy**
   in the sources about the exact presentation event).
6. **Famous figures — discarded, and why. Do not use them:**
   - **"95 % of new products fail"** (attributed to Clayton Christensen): **no study,
     paper or dataset** in the sources located; it propagates as a classroom anecdote. The works
     that separate *launched* products from concepts that died in R&D put commercial failure at a
     much lower order of magnitude. **Discarded.** If a figure is needed, look for the reference studies
     from the PDMA and Castellion & Markham (*JPIM*, 2013) on the origin of the inflated rates —
     **not verified in this pass**.
   - **"80 % of features are not used"**: concrete origin **Pendo, 2019 Feature Adoption
     Report**, over **615 Pendo subscriptions**, measuring **click volume** of features
     **labelled by the customer themselves**. Self-selected sample, "feature" defined by
     whoever labels it, click as a proxy for value and **a vendor with a commercial interest in the
     finding**. The earlier Standish lineage gives **45 %, 64 %, 75 % and 80 %** depending on the edition —
     an inconsistency that is itself the criticism. **It can be used as a hypothesis to check in your
     own product; not as a fact.**
   - **"It costs 5 times more to acquire than to retain"**: the citation chain leads to Reichheld & Sasser,
     *Zero Defections* (HBR, 1990), **whose documented finding is the effect of retention on
     profit in a few financial services firms, not a generalisable acquisition cost
     multiple**. The multiple circulates as 5×, 6-7× and 5-25×, a sign of a weak source.
     **Discarded.**
   - **Adoption statistics for product frameworks** ("X % of teams use continuous
     discovery"): **declared gap**, no primary source located. They are not written down.
7. **Privacy precondition**: before any experiment with user data, check the
   legal basis and obligations in force with `privacy-engineering-standards` — **regulations change and
   this document is not the source**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
