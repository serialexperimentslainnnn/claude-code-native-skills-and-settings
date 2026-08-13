---
name: sre-practice-standards
description: SRE practice standards for service reliability. Use when defining SLIs, SLOs, error budgets, multi-window burn-rate alerts, on-call rotation sizing, paging and handover, toil measurement and reduction, production readiness reviews, change risk classification, reliability game days, capacity planning or DORA metrics.
---

# SRE practice standards — reliability as an engineering discipline

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when defining, reviewing or correcting a service's **reliability practice**: choosing SLIs from
user journeys, defining SLOs and windows, error budgets and the policy they trigger, burn-rate
alerts, on-call rotation and paging design, incident command and severities, communication during
outages, blameless postmortems and action follow-up, identifying and reducing toil, production
readiness reviews, change risk classification, capacity planning, game days and drills, DORA
metrics and the reliability vs. velocity negotiation.

Governing principle: **reliability is a product decision expressed as a number, not an aspiration**.
Without an SLO agreed with the service owner there is no error budget; without an error budget there is no objective criterion
for deciding between shipping features and fixing the platform, and the discussion degenerates into who shouts
loudest. Corollary: 100% is not the target — the target is the level of reliability the user notices and the business
pays for; the rest of the budget is deliberately spent on velocity.

**Not applicable**: see `observability-standards` (instrumentation, metrics, traces, logs and their pipeline —
here we decide *what* is measured and *what* wakes somebody up, not *how* it is instrumented),
`incident-management-standards` (**the incident management process**, cause-agnostic and
canonical: declaration criteria, severity matrix, roles and command handover, communication and the
spokesperson, closure, the postmortem as an artifact, process metrics, vendor or data incidents.
What this skill contains about incident command and postmortems is the **summary applied to a
reliability incident**: if the two diverge, that one wins),
`incident-response-forensics-standards` (a **security** incident: containment without destroying
evidence, acquisition, chain of custody, eradication and recovery, regulatory notification),
`bcdr-standards` (continuity and DR as a programme: RTO/RPO, alternate sites,
full recovery exercises), `chaos-engineering-standards` (**the design and the mechanics
of the chaos experiment are theirs** — steady-state hypothesis, injection tool,
*blast radius*, abort conditions; **the game day as a reliability practice and the SLO that
serves as the steady state belong here**), `itsm-itil-standards` (the service process: catalogue, CAB, request
management, contractual compliance), `web-performance-standards` (**the service's SLO
and its error budget belong here**; **the experience perceived in the browser** — Core Web
Vitals, RUM at the 75th percentile — **is theirs**. A service can meet its availability and
server latency SLO and still be slow for the user: they are two different measurements and neither
replaces the other), `performance-engineering-standards` (*"how much latency
can we afford and what do we do if we exceed it?"* belongs here; *"why is it slow and what
fixes it?"* is theirs), `knowledge-management-standards` (**the runbook's content — what it checks, which command
is run, what gets escalated — belongs here**; **that it exists, has an owner, a review date and has been
executed at least once is their criterion**. The rule both uphold: **a runbook nobody
has executed is fiction**, and discovering that during an incident is the worst way to find out),
`tech-leadership-standards` (**DORA metrics and SLOs belong here and measure
systems and teams**; **the prohibition on using them to evaluate people is reinforced there**, because
that pressure comes from the management line and not from the team. Neither of the two skills accepts a
"DORA per engineer"), `finops-standards` (**reliability versus cost is an explicit trade-off**: 
redundancy, over-provisioning and multi-AZ are decided here with the error budget as arbiter;
**how much that decision costs and in what economic unit it is expressed, there**. Neither of the two
cuts into the other without a declared decision), `platform-engineering-standards` (**the internal
platform is also a service and the SLOs, on-call and error budget from here apply to it**; its
design as a product, its paved road and its adoption are theirs), `itsm-itil-standards`
(**a contractual SLA is not an SLO** — the SLA and its credit regime are theirs, the SLO
and its error budget belong here, and confusing them produces impossible commitments or meaningless
internal targets), `testing-qa-standards` (canary, *feature flags* and *shadow traffic*
**are designed there as a type of test**; the decision to deploy that way, for reliability and error
budget reasons, belongs here).

## 2. Default decisions

> Verify the latest version and the status of the references on the web before committing to them in a real project (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| SLI source | A **critical user journey** measured as close to the user as possible (edge/client) | A server metric if there is no client telemetry — document the bias |
| No. of SLOs per service | **2-3** (availability + latency; freshness if there is a pipeline) | More only in services with genuinely distinct failure modes |
| SLO window | **28 rolling days** | A calendar quarter if the business cycle demands it; never a "calendar month" for paging |
| Initial target | Derived from **historical performance**, not from wishes: measure 4 weeks and set it just below | — |
| Budget alert | **Multi-window multi-burn-rate** (§6) | Only if traffic is sufficient; on low traffic, synthetic probes or an aggregated SLO |
| Error budget policy | **Written, signed by product and engineering, with an automatic consequence** | — |
| Severities | **SEV1-SEV4** defined by user impact, not by component | Any scale, if it is unambiguous within 10 seconds |
| Incident command | Separate **IC / Comms / Ops** roles (ICS); the IC does not debug | In small incidents, the IC may also take Comms |
| Postmortem | **Mandatory for SEV1-SEV2 and for every recurrence**, blameless, with actions with an owner and a date | — |
| On-call load | **≤ 2 actionable pages per shift**; a rotation of **≥ 6 people** (ideally 8) | Follow-the-sun if there are teams in 2+ regions |
| Toil ceiling | **≤ 50%** of the team's time, measured, with a quarterly reduction target | — |
| Launch to production | **A passed PRR** (§4) before real user traffic | — |
| Delivery metrics | **DORA, 5 metrics** (§6): deployment frequency, lead time, change failure rate, time to recover and **rework rate** | — |

## 3. Structure and conventions

### From the user journey to the SLI

1. Enumerate the service's **critical user journeys** (CUJs) in user language: "the customer completes the
   payment", "the nightly report is available at 07:00". If you cannot name the journey, the SLO you
   write will measure a machine, not a user.
2. For each CUJ choose the SLI type from the menu, do not invent it:
   - **Request/response**: availability (the proportion of valid requests served OK), **latency**
     (the proportion of requests faster than a threshold) and quality/correctness.
   - **Pipeline / data processing**: freshness, correctness, coverage (the proportion of data processed).
   - **Storage**: durability, read latency.
3. Formulate the SLI **always as a proportion of good events over valid events** (`good/valid`), not
   as a mean. Means hide the tail; the tail is the angry user.
4. Define explicitly what a "valid event" is: which codes, which routes, which traffic is excluded (health
   checks, bots, requests aborted by the client). That exclusion is part of the contract.

**Latency**: threshold + proportion (`99% of requests < 300 ms`), not "p99 = 300 ms" as a target — a
percentile as a target is neither composable nor summable in a budget. Use two thresholds when the journey
warrants it (fast / tolerable).

### The SLO specification

Every SLO is written as a versioned artifact in the service's repo (SLO as code, reviewed in a PR) with:
the CUJ name, the exact SLI (numerator, denominator, data source), the target, the window, the business owner,
the consequences (the budget policy) and the date of the next review. An SLO without a business owner is a
vanity metric.

### The error budget policy (the artifact that gives the SLO its value)

Written **before** the budget is exhausted, not during the row. Minimum content:

- **The exhaustion threshold** and what it triggers: a freeze on changes unrelated to reliability,
  reallocation of a percentage of the team's capacity to reliability work, a mandatory review
  with product.
- Named **exceptions** (security patches, changes that reduce risk) and who can approve them.
- **Who decides** the unblocking and with what evidence.
- **An escape hatch**: what happens if the budget is exhausted by an external cause (a cloud provider) — it is documented, not
  ignored; if it happens repeatedly it is an architecture decision, not bad luck.
- A policy that has never stopped anything is not a policy: it is decoration.

### On-call and escalation

- A rotation of **≥ 6 people** per primary shift (with 6 the structural toil floor is already ~33%; with fewer,
  on-call eats the team). Shifts with overlap and a **written handover** in a shared channel — never by DM.
- The handover includes: open incidents, half-formed hypotheses, changes in flight, silenced alerts and their
  expiry. Context cannot live in one person's head.
- **Escalation by time, not by heroics**: if the primary on-call does not acknowledge within N minutes, it escalates on its own; if
  there is no mitigation within M minutes, the secondary/IC comes in. The thresholds are written down, not implicit.
- Regulated compensation and rest; a shift with a broken night is deducted from the following day. On-call without
  compensated rest is people debt and ends in staff turnover.
- **Every page links a runbook**; an alert with no runbook and no possible action is deleted, not silenced forever.

### Incident command

- Declare early and **downgrade freely**: it is cheap to open a SEV2 and lower it; it is expensive to discover an hour in
  that nobody was coordinating.
- **The IC coordinates and decides, they do not debug.** If the IC has their hands on the keyboard, there is no IC.
- Roles: **IC** (decision, priority, delegation), **Comms** (status to stakeholders and the status page), **Ops**
  (hands). A single channel per incident, with a live written timeline — the later reconstruction is
  90% of the postmortem's cost.
- **Mitigate before understanding**: rollback, feature flag, drain traffic, scale capacity. The root cause
  is investigated afterwards; the user does not get paid in explanations.
- External communication: a fixed cadence by severity (e.g. SEV1 every 15-30 min) **even when there is no news**;
  impact in user language, with no speculative technical cause and no details that would facilitate an attack (§5).

## 4. Quality and verification

Gates that break the launch or the change, in order of increasing cost:

1. **A Production Readiness Review (PRR)** before receiving real traffic. Minimum checklist: an SLO defined and
   agreed; golden signal dashboards; alerts wired to a **named** on-call; a runbook with the 3-5
   known failure modes; a rollback plan and **rollback test**; limits and timeouts on dependencies; capacity
   sized with load data; verified backups/restores if it is stateful; an owner and an escalation
   path. Without a passed PRR, there is no user traffic — with no "temporary" exception.
2. **Change risk classification** (§6) applied in the PR/pipeline; high-risk changes require
   a canary with automatic abort criteria.
3. **A review of postmortem actions** with an owner and a date, tracked in the same backlog as the product
   until closure. Process health metric: **the percentage of actions closed on time** — if it is low,
   the postmortems are theatre.
4. **Quarterly game days**: a failure injected in a realistic environment with the real on-call responding. It is
   assessed on detection (did it alert?), diagnosis (was the runbook useful?) and mitigation (did the rollback work?). Every
   finding enters the backlog as an action with an owner.
5. **A DR drill** at the frequency set by the continuity programme (see `bcdr-standards`); from
   SRE comes the SLO criterion during the degradation and the validation of runbooks.
6. **A quarterly SLO review**: does the target still reflect what the user notices? Was budget burned
   without complaints (a target that is too strict) or were there complaints without budget burned (a badly chosen SLI)? Both are bugs in the
   SLO, not in the service.

## 5. Operational process security

- **Emergency access (break-glass)**: an elevation account/role with MFA, logged use, an automatic alert
  when used and a mandatory subsequent review. Urgency justifies the access, never the lack of auditing.
- Incident tooling (paging, incident chat, status page) with strong authentication and its own access
  control; they are a first-tier target — whoever controls them controls the response.
- **A reliability incident can be a security incident**: define the reclassification criteria
  (an indication of intrusion, exfiltration, altered data) and the immediate handover to the security process
  (`incident-response-forensics`). As soon as compromise is suspected, **preserve evidence before mitigating**
  by destroying state (do not reinstall the host "so it comes back").
- **Communication without leaks**: the status page describes impact, not internal architecture; public
  postmortems are sanitised of PII, internal paths, exact versions and exploitable details.
- Internal postmortems with user data: minimise, reference identifiers instead of copying data, and
  apply the same retention as for other artifacts with PII.
- A blameless culture **is not impunity**: it applies to an honest error in a system that allowed it. Deliberate
  or negligent conduct is dealt with through another channel — it is not diluted in the postmortem.

## 6. Operability: alerts, capacity and velocity

### Golden signals and alerts

- Instrument and watch all four: **latency, traffic, errors, saturation** (queues/lag and utilisation in
  work systems). They are the basis of diagnosis; **not all of them are a reason to page**.
- **You page on a user symptom (an SLO at risk), you diagnose on a cause.** High CPU does not wake
  anybody; a degraded CUJ does.
- **Multi-window multi-burn-rate alerting** as the default (Google SRE Workbook, the "Alerting on SLOs" chapter,
  iteration 6). A starting table — verify it and **tune it per service**:

  | Budget consumed | Long window | Short window | Burn rate | Action |
  |---|---|---|---|---|
  | 2% | 1 h | 5 min | 14.4 | **Page** |
  | 5% | 6 h | 30 min | 6 | **Page** |
  | 10% | 3 days | 6 h | 1 | Ticket |

  Rule: short window = 1/12 of the long one; the short one guarantees the alert clears shortly after the
  mitigation and can fire again if it relapses.
- **Forbidden to use `for`/duration** as a criterion in SLO alerts: a series of short error spikes never
  reaches the duration and consumes the budget just the same.
- **Low traffic breaks the model**: with few requests the ratio is noise. Alternatives: synthetic probes
  generating a known volume, aggregating several services into a common SLO, or lengthening windows and accepting
  slower detection — decided explicitly, not as a silent default.
- Alert hygiene every quarter: every alert that has not prompted an action in 90 days is deleted or
  downgraded to a non-paging channel. Group the cascades: a DB failure is **one** response thread, not twelve pages.

### Toil

- Operational definition (all at once): manual, repetitive, automatable, tactical, with no lasting value and
  **scaling linearly with the service**. Boring but engineering work is not toil.
- **Measure it before attacking it**: 2-3 weeks of logging by category, ranked by hours. Without measurement,
  what gets automated is the fun part, not the expensive one.
- Order of attack: **eliminate** the need (change the design or refuse the task) > **self-service** for
  whoever asks for it > **automate** the procedure. Automating a process that should not exist is toil
  with more steps.
- A numeric target per quarter (e.g. "from 30% to 20% of the team's time"), reviewed like any
  other engineering target.

### Capacity and change risk

- **Capacity planning with two inputs**: forecast organic demand (trend + seasonality + known
  business events) and inorganic demand (launches, campaigns). It is translated into resources via a **load
  model validated with tests**, not by a rule of three over average CPU.
- Load testing before committing to a new SLO and before expected peaks; know the saturation point
  and the degradation mode (does it degrade or does it fall over?).
- **Change risk classification** — it determines the rigour of the deployment:
  - *Low*: reversible, with no schema or contract change, behind a feature flag → automatic rolling.
  - *Medium*: touches the critical path or dependencies → canary with abort metrics and a tested rollback.
  - *High*: data migration, contract change, irreversible in practice → expand/contract, an agreed
    window, a written and rehearsed rollback plan, prior communication.
- **Change is the dominant cause of incidents**: if you do not know what changed, start there. Every deployment
  leaves a mark correlatable with the telemetry.

### DORA metrics

Five current metrics (DORA extended the classic four with **rework rate**): deployment frequency, lead
time for changes, change failure rate, time to recover and rework rate. Use them to **diagnose the
delivery system**, never to evaluate people or compare teams against each other. Throughput and stability are
read **together**: raising deployments while the change failure rate grows is not an improvement, it is debt accelerating.

### Negotiating reliability versus velocity

- The error budget is the negotiation mechanism: while there is budget, **product decides**; when it is
  exhausted, the agreed policy decides. That turns a political conflict into a rule.
- If the team never consumes budget, **it is being too conservative**: there is surplus reliability and a shortage of
  velocity — raise the pace or lower the target (and save the cost).
- **Lowering the target because the cost does not sustain it**: it is the legitimate counterpart of the previous
  point and **it is decided here, not on the cost sheet**. `finops-standards` provides how much
  each nine costs; **the signature belongs to whoever answers for the SLO**, it goes in an ADR with the user impact
  declared, and it is communicated to whoever consumes the service. A target lowered so that the
  alert stops firing — or to make a budget balance without saying so — is not a renegotiation: it is a
  commitment broken in silence.
- Extra reliability above the SLO is not sellable: every additional nine multiplies the cost and users no
  longer perceive it (their network, their phone and their dependencies impose a ceiling). Say it with numbers in the discussion.

## 7. Sustainability and prohibitions

- **Cadence**: SLOs reviewed quarterly; the error budget policy reviewed at least annually or after
  any incident in which it was ignored; runbooks reviewed when the game day proves they fail.
- **Deprecating alerts and SLOs**: they are retired with the service; an orphan SLO generates pages with no owner.
- **Minimum living documentation**: per service, the SLO + runbook + dependency diagram + escalation path.
  What is not used during an incident gets deleted.
- SRE practice is **adopted incrementally**: start with the most critical service with 1 SLO and its policy;
  extending to 40 services at once produces 40 ignored SLOs.

**FORBIDDEN**
- ❌ A 100% SLO, or an SLO without an error budget, or an error budget without a written policy with a consequence.
- ❌ Setting the target by wish or by copying another team, instead of by historical measurement + user need.
- ❌ An SLI measured on a machine metric when there is telemetry for the user journey.
- ❌ A percentile as an SLO target (`p99 = X`) instead of a proportion over a threshold.
- ❌ Paging on causes (CPU, memory, pod restarts) instead of on a user symptom.
- ❌ An alert with no runbook, no owner or no possible action; permanent silences with no expiry date.
- ❌ SLO alerts with `for`/duration, or with a single window.
- ❌ An on-call rotation below 6 people sustained over time, or on-call without compensation or rest.
- ❌ An IC who debugs, an incident without a written timeline, or an incident coordinated by DM instead of a common channel.
- ❌ Hunting for the root cause before mitigating when the user is affected.
- ❌ A postmortem with people's names as its conclusion ("human error"), or without actions with an owner and a date.
- ❌ Postmortem actions in a separate list nobody prioritises.
- ❌ Launching to production without a PRR: with no SLO, no runbook, no named on-call or no tested rollback.
- ❌ Declaring automated a process whose failure still requires undocumented manual intervention.
- ❌ Using DORA (or the incident count) as an individual performance metric or as a ranking between teams.
- ❌ Freezing changes indefinitely as a response to an incident: it is the opposite of the budget policy.
- ❌ Game days and drills announced as a demonstration; if it cannot fail, it is not an exercise.

## 8. Mandatory web verification

Before committing to any figure, name or reference in this document, **search for it — do not remember it**:

1. **The burn rate and window table** current in the SRE Workbook (`sre.google/workbook/alerting-on-slos/`):
   the 14.4/6/1 factors and their windows are the published starting point, not a universal constant.
2. **The status of the Google SRE books**: verified Aug-2026 — there are still three (*SRE* 2016, *SRE
   Workbook* 2018, *Building Secure & Reliable Systems* 2020), with no new edition announced; `sre.google`
   publishes per-chapter updates and new material (e.g. the reliable operation of AI systems).
   Check whether a new edition has come out before quoting.
3. **DORA**: verified Aug-2026 — the report was renamed to *State of AI-assisted Software Development*
   (the 2025 edition) and the official set went from 4 to **5 metrics** (adding *rework rate*); the
   performance level model was replaced by team archetypes. Confirm on `dora.dev` whether there is already a 2026
   edition and whether the benchmarks have changed before using them.
4. **SLO-as-code tools** you are going to recommend (Sloth, OpenSLO, slo-generator, Pyrra…): maintenance
   status, real MWMB support and compatibility with your stack — they vary by version.
5. **Industry benchmarks** for the target (typical availability for that type of service) before proposing
   a number to the business.

If the web contradicts this document, **the web wins** — flag the discrepancy.
