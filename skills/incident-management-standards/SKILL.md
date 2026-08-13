---
name: incident-management-standards
description: Use when running or designing the incident process itself — declaring an incident, severity matrix (SEV1-SEV4, impact x urgency), Incident Commander, operations lead, communications lead and scribe roles, incident channel and status page cadence, stakeholder and customer update templates, mitigate-before-diagnose calls, rollback decisions, command handover in long incidents, incident closure, blameless postmortem with owned action items, time-to-declare and time-to-mitigate metrics and MTTR pitfalls, ITIL major incident and problem management, game days and tabletop exercises, vendor outage and third-party or data-breach incidents.
---

# Incident management standards — the process, whatever the cause

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **end-to-end management process of an incident, regardless of its cause**:
detection and declaration criteria, severity classification, activation of command roles,
internal and external communication, mitigation decisions under uncertainty, escalation, closure,
blameless postmortem and the learning chain that turns incidents into changes. It covers equally
the reliability incident, the security one, the data quality one, the one caused by a vendor outage and the one
that is not technical (a personal data breach, the failure of a critical third party, operational fraud).

Triggers: "declare an incident", "severity", "SEV1/SEV2", "P1/P2", "incident commander", "IC",
"comms lead", "scribe", "incident channel", "status page", "war room", "stakeholder
update", "spokesperson", "mitigate", "rollback", "command handover", "IC handoff", "incident
closure", "postmortem", "follow-up actions", "MTTR", "time to declare", "major
incident", "problem management", "tabletop", "game day", "vendor outage".

**Governing principle**: an incident is managed with **an explicit command structure, not with the
sum of good intentions**. The dominant failure of organisations is not technical: it is that nobody
declared, nobody was coordinating and nobody was talking to whoever they had to talk to. Corollary: **declaring is
cheap, not declaring is expensive**. A SEV2 opened and downgraded after 10 minutes costs one notification;
an hour without coordination costs the entire incident.

**Not applicable**:
- `sre-practice-standards` (**critical boundary**, arbitration in §3): **service reliability**
  as a discipline — SLI/SLO, error budget and its policy, burn rate alerts, design and
  sizing of the on-call rota, PRR, toil, capacity planning, DORA. Its treatment of
  incident command and postmortems is the **summary applied to a reliability incident**; the
  canonical version of the process is this skill. If the two diverge, **this one wins**.
- `incident-response-forensics-standards`: the **technical response and the investigation** of a
  security incident — containment without destroying evidence, memory and disk acquisition,
  chain of custody, analysis, eradication and recovery, ransomware/identity playbooks.
  A security incident **uses both**: this one governs it (who commands, who speaks, how it is
  decided), that one investigates it (what happened, how they got in, what they touched, what is preserved).
- `observability-standards`: the telemetry with which it is detected and diagnosed, and its retention.
- `grc-compliance-standards`: the regulatory framework, audit evidence and formal risk acceptance;
  here, only the **trigger** of the duty to notify and its operational coordination.
- `vulnerability-management-standards`: the CVE **before** it is exploited (triage, SLA, VEX).
- `appsec-standards`: threat modelling and vulnerability classes in your own code.
- `identity-access-management-standards`: break-glass, session and token revocation.
- `onprem-standards`, `kubernetes-standards`, `networking-standards`, `cicd-standards`,
  `data-platform-standards`, `aws-standards`/`azure-standards`/`gcp-standards`, `homelab-standards`:
  the concrete mitigation on each platform.
- `bcdr-standards` (the boundary is **scale** — when the incident
  stops being recoverable within the service and activates the continuity plan, it stops being managed
  as an incident and becomes DR: the IC hands over command to the crisis director and the change of
  regime is declared explicitly), `detection-engineering-standards` (the detection
  that **triggers** the declaration), `privacy-engineering-standards` (a personal data
  breach, risk assessment for the data subjects and communication to those affected),
  `offensive-security-standards` (deconfliction: an authorised exercise must not consume the incident
  process, and a real finding during the exercise does activate it),
  `secrets-management-standards`, `backup-recovery-standards`,
  `tech-leadership-standards` (**the blameless postmortem as a process — format, deadlines,
  actions with an owner — belongs here**; **defending it when management asks for someone to blame is a
  leadership obligation and is theirs**. A blameless culture is not sustained by a document: it is
  sustained by someone who absorbs that pressure),
  `itsm-itil-standards` (**a boundary with real overlap that must be arbitrated**: **the live
  technical incident belongs here** — severity declaration, command, coordination, communication during
  the outage and blameless postmortem; **the service process wrapping it is theirs**: ticket logging and
  categorisation, catalogue, the contractual SLA and its credit regime, hierarchical
  escalation and the customer relationship. **Problem management** — eliminating the cause once
  service is restored, with its known error database — **is theirs**; here it ends when the
  service is restored and the postmortem has actions with owners. And the distinction neither of
  the two should erase: **a contractual SLA is not an SLO**, which belongs to `sre-practice-standards`).

## 2. Default decisions

> Verify the status of the frameworks and references on the web before committing to them in a real project (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Command framework | **Adapted ICS** (Google's IMAG / PagerDuty Incident Response) | Any of them, if it defines a single unambiguous command |
| Severity scale | **SEV1-SEV4**, defined by **observable user impact**, not by component or by team | P1-P4 if it is already in place; never two scales coexisting |
| Declaration criteria | **An explicit and automatic threshold** (SLO at risk, indication of compromise, incorrect data published, critical vendor down) | Discretionary declaration **always permitted**: anyone can declare, nobody needs permission |
| Rule when in doubt | **Declare high and downgrade** | — |
| Minimum roles | **IC** + **Ops lead** + **Comms lead** + **Scribe** | At SEV3-4 the IC also takes Comms and Scribe; **never** also Ops |
| Who is IC | Whoever **coordinates**, not whoever knows the most. A rotated and trained role, independent of the affected area | Whoever declares assumes IC until a formal handover |
| Channel | **One only per incident**, written, persistent and auditable; an optional voice bridge hanging off the channel | Voice as the primary channel only if the written channel is not viable — with a mandatory scribe |
| Communication cadence | Fixed by severity (SEV1 every 15-30 min) **even when there is no news** | — |
| External spokesperson | **A single one**, the Comms lead; nobody else talks to customers, press or regulators | — |
| Order of work | **Mitigate > diagnose > fix**, except for the evidence exception (§3) | — |
| Default option after a recent change | **Rollback** | Fix forward only with explicit IC judgement and bounded risk |
| Postmortem | **Mandatory** for SEV1-SEV2, for every recurrence and for every security incident, blameless, with actions with an **owner and a date** | — |
| Cause taxonomy | **Closed and reviewed**, applied at the closure of every incident | — |
| Headline metric | **Time to declare** and **time to mitigate** | MTTR only as a distribution segmented by severity (§6) |
| Exercises | **Quarterly tabletop** + **game day** with real injection (see `sre-practice-standards`) | — |
| ITSM framing | Take **major incident** and **problem management** from ITIL 4; leave out the CAB and the request workflow | — |

## 3. The lifecycle as an engineering process

### Boundary arbitration (read this before routing)

- "How much can this service fail, what measures it and who is on call?" → `sre-practice-standards`.
- "Who is in command right now, what is communicated and how is it decided?" → **this skill**.
- "What did the attacker do, what did they touch and what is preserved?" → `incident-response-forensics-standards`.
- **Accepted and declared** duplication: severities, the IC role and postmortems appear in all three.
  The source of truth for the **process** is this one; the others apply it to their domain.

### 3.1 Detection and declaration

- Declaration is an **explicit and timestamped act**, not a state of mind. It is recorded
  who declares, when, with what severity and why.
- **Anyone can declare**, including support, an internal customer or an on-call intern. Requiring
  approval to declare is the most effective mechanism for turning a SEV3 into a SEV1.
- **Automatic thresholds** that declare on their own (or at least propose): error budget burn above
  the paging threshold, an indication of compromise confirmed by detection, data loss or corruption,
  a critical vendor outage, a suspected personal data leak.
- The **regulatory clock starts at "awareness" of the incident, not at the diagnosis** (§6):
  recording the detection time precisely is an operational obligation, not a detail.

### 3.2 Classification: severity with observable criteria

Severity is decided in **≤ 60 seconds** with a table that a tired human at 03:00 reads without
interpreting. It is set by **impact × urgency**, with impact expressed in user language:

| | High urgency (worsening / irreversible) | Medium urgency | Low urgency (stable, contained) |
|---|---|---|---|
| **Critical impact** (main journey down for everyone, data lost, confirmed compromise, legal obligation triggered) | SEV1 | SEV1 | SEV2 |
| **High impact** (degraded journey, a large subset, expensive workaround) | SEV1 | SEV2 | SEV3 |
| **Medium impact** (secondary functionality, viable workaround) | SEV2 | SEV3 | SEV3 |
| **Low impact** (cosmetic, internal, no user affected) | SEV3 | SEV4 | SEV4 |

Hard rules of classification:

- Each level defines a **response**, not prestige: who gets woken up, communication cadence,
  whether a postmortem is mandatory, whether a status page is needed.
- **Every indication of compromise, exfiltration or exposed personal data enters as SEV1 or SEV2 by
  default**, and only comes down after assessment — never the other way round.
- Severity is **reviewed continuously** and can go up or down; the change is announced in the channel
  with a reason. What is not done is negotiating it down because of its consequences.
- An incident that triggers a regulatory notification **cannot** be lower than SEV2.

### 3.3 Roles: who commands and who speaks

- **Incident Commander**: decides, prioritises, delegates, maintains the state and cuts off discussions. **They
  do not debug, do not type, do not investigate.** Their value is coordination bandwidth, not
  knowledge of the system — which is why the best expert is usually the **worst** IC: as soon as they get
  into the problem, there is no IC any more. If the IC has their hands on the keyboard, there is no IC.
- **Operations lead**: the only person authorised to execute changes on production during the
  incident, or to delegate them by name. It prevents three people mitigating simultaneously and treading on each other.
- **Communications lead**: internal (management, support, sales, legal) and external (status page,
  customers). Translates into user language and shields the Ops lead from interruptions.
- **Scribe**: a live timeline with timestamps — facts, hypotheses, decisions and who took them.
  Reconstructing the timeline after the fact is 90% of the cost of the postmortem and 100% of its errors.
- **Experts (SMEs)**: they come in, contribute, leave. The channel is not a spectator gallery; the IC has
  explicit authority to **eject whoever is not contributing, including any executive**.
- **Escalation by time, not by heroics**: if in N minutes there is no mitigation or hypothesis, it is
  escalated. The thresholds are written down, not implicit.
- **Command handover in long incidents**: maximum shifts (2-4 h per IC), an **explicit handover
  announced in the channel** ("IC moves from A to B at 04:12"), with a state briefing: what is known, what
  has been ruled out, what is in flight, what has been communicated and to whom, which decisions are pending.
  A 12-hour incident with a single IC ends in bad decisions through exhaustion.

### 3.4 Communication

- **A single channel**, with a predictable name (`#inc-YYYYMMDD-<slug>`), persistent and exportable. Coordinating
  by DM is forbidden: context in private is context lost.
- **An update template** (always the same structure, so it can be skim-read):
  `[SEV<n>] <service> — <impact in user language> · Status: investigating|identified|mitigating|monitoring|resolved · Current action: <what> · Next update: <time>`.
- **A fixed cadence even when there is no news**. "No news, still working" is information: it stops five
  people coming in to ask and breaking the response.
- **Language**: describe **impact**, not architecture. Neither panic nor euphemism: "intermittent
  problems" is forbidden when the service is down, and speculating about the cause before you have it is
  forbidden. Never promise a resolution time you do not control; promise the time of the **next
  update**, which you do control.
- **A status page** for external impact, with written criteria for when it is published (not "when somebody
  remembers"). The first message goes out before the cause is known. The absence of a status page during
  an outage does not hide it: it turns it into a trust incident as well as a technical one.
- **In a security incident**: external communication is coordinated with legal/DPO **before**
  publishing, and technical detail is omitted (§5 and the sister skill). Furthermore, if the attacker is
  suspected of having access to the corporate channel, coordination moves to an out-of-band channel.

### 3.5 Deciding under uncertainty

- **Mitigate before understanding.** The user does not get paid in explanations. Levers in order: rollback,
  disable a feature flag, drain traffic, degrade functionality, scale capacity, failover.
- **The exception that must be said out loud**: when compromise is suspected, destructive
  mitigation (reinstall, recreate, power off) **destroys the evidence and with it the ability to know
  whether the attacker is still inside**. In that case it is coordinated with `incident-response-forensics-standards`:
  preserve first (memory and disk), isolate instead of destroying, and the IC leaves a record of the
  decision and who took it. A service restored on top of a still-compromised system is an
  incident that reopens worse.
- **Rollback is the default option** in the face of any correlated recent change. Fix forward
  requires explicit justification from the IC and a time limit after which it is rolled back anyway.
- **Timeboxing hypotheses**: every investigation line has assigned time; once exhausted, it is
  reported and another route is taken. Without this, three people chase the same hunch for an hour.
- **When to stop**: the incident is declared mitigated when the user impact ceases and is
  verified with telemetry, not when "it looks like it's fine". It moves into **monitoring** for a
  defined window before closing.

### 3.6 Closure and learning

- **Closure** with: mitigation and resolution times (which are different), quantified impact (users,
  requests, time, money if possible), the cause classified according to the taxonomy, open actions,
  the regulatory obligations triggered and their status.
- **A blameless postmortem** within ≤ 5 working days. Minimum content: impact, timeline, contributing
  factors (in the plural — never *the* singular root cause), what worked, what did not, **why
  detection took as long as it did**, and actions. The right question is "what made this action
  seem reasonable at the time?", not "who got it wrong?".
- **Blameless is not impunity**: an honest error in a system that allowed it is dealt with in the
  postmortem; deliberate or negligent conduct is dealt with through another channel and is not diluted here.
- **Actions**: a named owner (a person, not a team), a date, and in the **same backlog** as the product.
  Each action is classified by effectiveness: eliminate the failure class > automate > detect earlier >
  document > "be careful" (that last one is not an action, it is a wish — it is not accepted).
- **Review of execution, not of prose**: a monthly review of the status of open actions.
  The process metric is the **percentage of actions closed on time**; if it is low, the
  postmortem is theatre and you must either stop writing them or start executing them.
- **Problem management** (ITIL 4): incidents sharing contributing factors are aggregated into
  a *problem* with its own owner and engineering budget. Three identical incidents are not three
  incidents: they are one unresolved one.
- **A quarterly trend review**: distribution by cause taxonomy, by service and by time
  of day; recurrences; incidents detected by the customer before the telemetry (a metric
  of detection quality, fed back to `observability-standards` and
  `detection-engineering-standards`).

## 4. Process quality (the gates)

The **process** is audited, not the people. Gates, in order of increasing cost:

1. **Was it declared, and in time?** The difference between the first signal (alert, ticket, tweet) and the declaration.
   If the pattern is "it was declared when the customer already knew", the problem is in the declaration
   threshold or in the fear of declaring, not in the on-call team.
2. **Was there a named and announced IC?** An incident with no identifiable IC in the channel is a process
   failure even if the technical outcome was good.
3. **Was the communication cadence respected?** Countable over the channel: gaps > 2× the cadence are
   a finding.
4. **Is there a live written timeline?** A postmortem reconstructed from memory 3 days later is fiction
   with timestamps.
5. **Does the postmortem have actions with a named owner and a date, and were they closed?** See §3.6.
6. **Did the assigned severity survive later review?** Both chronic over-sizing
   (everything is SEV1 → nothing is) and systematic under-sizing are bugs in the table.
7. **Exercises**: a quarterly tabletop (around a table, no systems: decisions, roles and communication —
   including a security scenario and a vendor outage one) and a game day with real injection. Every
   exercise produces findings with owners; an exercise that cannot fail is a demonstration.
8. **A test of the regulatory notification chain**: simulate an incident with personal data and
   time how long the organisation takes to have the minimum information to notify. If it takes
   longer than the deadline, the deadline will not be met on the real day (§6).

## 5. Process security

- **The incident tooling is a first-tier target**: paging, chat, status page and
  runbook documentation. Whoever controls them controls the response. MFA, its own access control
  and **a tested alternative route** in case the chat provider is precisely what is down.
- **An out-of-band plan**: contact list, voice bridge and alternative channel, accessible without the
  corporate SSO and **tested** (a phone list living in the wiki that is down does not exist).
  Coordinate with `identity-access-management-standards` for break-glass.
- **Compartmentalisation in security incidents**: the general management channel may be
  compromised and the investigation may need stealth. The IC decides what is said in the broad channel
  and what in the restricted IR channel; the decision is documented.
- **Communication without leaks**: the status page describes impact, not architecture or versions;
  public postmortems are sanitised of PII, internal paths and exploitable detail.
- **Personal data in the channel**: pasting dumps with PII into the incident channel is forbidden.
  Reference identifiers; the channel is archived and replicated in more places than you think.
- **The duty to notify**: it is decided by legal/DPO with the information incident management
  provides, and **it is not postponed until the full diagnosis is available** — you notify with what is known
  and expand later (§6). This is not legal advice: the legal criteria are set by legal/DPO.

## 6. Operability: metrics, deadlines and load

### Metrics that are useful

- **Time to declare** (first signal → declaration): it measures the process, it is actionable and almost
  nobody measures it. The most underrated metric of the domain.
- **Time to mitigate** (declaration → impact ceasing): it is what the user notices.
- **Percentage of postmortem actions closed on time**: it measures whether learning exists.
- **Incidents detected by the customer before the telemetry**: it measures detection.
- **Recurrence by cause taxonomy**: it measures whether the failure class or the symptom is being attacked.
- **Incident load per person and per shift**: it measures the sustainability of the process.

### MTTR pitfalls (do not use it blindly)

- It is a **mean over a long-tailed distribution**: one 20 h incident and nine of 5 min give an
  "MTTR of 2 h" that describes none of them. Use **median and p90 segmented by severity**, or the
  full distribution.
- It is **easy to game**: by closing early, by not declaring the small ones, or by reclassifying downwards.
- It mixes distinct phases (detect, declare, diagnose, mitigate, resolve): aggregated, it hides
  exactly the bottleneck you are looking for.
- **Never** as an individual, team or bonus target: the number gets optimised, not the service.

### Regulatory deadlines (verify every figure in §8 — do not quote them from memory)

Data verified in August 2026; **the legal criteria belong to legal/DPO, not to engineering**.

> **The single source for the deadlines: `grc-compliance-standards`.** The same regimes appear in
> three skills (here, `incident-response-forensics-standards` and that one). **If they diverge,
> `grc-compliance-standards` wins** and the other two are corrected in the same change. What is
> irreducibly from here is not the figure, it is the operational criterion: **the clock runs from
> awareness, not from the diagnosis**, and whoever decides to notify is not whoever is mitigating.

- **GDPR art. 33**: notification to the supervisory authority (AEPD in Spain) **without undue delay
  and at most within 72 h** from **awareness** of the breach, unless it is unlikely to
  entail a risk to rights and freedoms; communication to the **data subjects** if the risk is high
  (art. 34). The processor notifies the controller without undue delay. **Phased**
  notification is admissible (partial within the deadline, expanded later). Document **every** breach, whether notified or not.
- **NIS2**: an **early warning within 24 h**, **notification within 72 h**, **final report within 1 month** from
  awareness of the significant incident; an interim report if the authority asks for one. In Spain, the
  reference CSIRT is **INCIBE-CERT** (private sector), **CCN-CERT** (public sector) and ESPDEF-CERT
  (defence). **The Spanish transposition (Ley de Coordinación y Gobernanza de la Ciberseguridad)
  had still not been published in the BOE as of August 2026** — verify its status before asserting anything.
- **DORA** (financial entities): initial notification of a **major** incident within **4 h of the
  classification as major and in any case ≤ 24 h from detection**, an interim report ≤ 72 h and a
  final report ≤ 1 month from the last interim one. The RTS templates have applied since March 2025.
- **ENS (RD 311/2022)**: notification to CCN-CERT via LUCIA, with staggered deadlines by impact according to
  guide CCN-STIC 817. The specific deadlines per level come from secondary guides: **cross-check them
  against the text in force before using them** (§8).
- **Concurrency**: the same incident can trigger GDPR + NIS2 + DORA + ENS + a customer contract
  simultaneously, with different clocks starting at different moments. It is managed with **a
  single obligations matrix per incident type, prepared in advance**, not improvised at 03:00.

### Sustainable on-call (a process lens)

Sizing, compensation and alert hygiene live in `sre-practice-standards`. From the
incident process:

- **Incident load is a process metric**, not an individual one: if one person has taken three
  SEV1s in a month, the problem is the system.
- **Alert fatigue** = undeclared incidents. It is the most common way for the process to fail
  silently.
- **After a night-time SEV1 there is compensated rest**; an exhausted IC takes expensive decisions.
- **Nobody is IC and Ops at the same time in SEV1-SEV2**. If there are not enough people to separate the roles, the incident
  is already telling you the real size of your response capacity.

### Incidents that are not technical

- **Vendor / SaaS outage**: it is still your incident in front of your user. Identical roles; the Ops
  lead manages the workaround and the **contractual** escalation with the vendor (have the support channel
  and the contract number **beforehand**, not during). Document the impact for the third-party risk
  review (`grc-compliance-standards`).
- **A personal data breach**: activate legal/DPO **at declaration**, not at closure; the 72 h
  clock runs in parallel with the mitigation. The risk assessment for the data subjects and the
  communication to those affected are not decided by engineering.
- **A data failure / an incorrect calculation published**: the impact is reputational and sometimes regulatory,
  and mitigation includes **correcting backwards** what was already issued. Coordinate with
  `data-platform-standards`.
- **A crisis that exceeds the service** (site loss, prolonged unavailability): a formal handover
  to the continuity plan; see `bcdr-standards`.

## 7. Sustainability and prohibitions

- **Cadence**: the severity table and the regulatory obligations matrix reviewed at least
  annually and after any incident where they caused doubt; communication templates reviewed
  after every SEV1; the cause taxonomy reviewed at the close of each quarter.
- **The process is adopted incrementally**: start with severities + IC + a single channel + postmortems.
  A 40-page process nobody reads produces zero well-managed incidents.
- **What is not used during an incident gets deleted**. Incident documentation is measured by its
  use at 03:00, not by its completeness.
- **Real training**: nobody is IC without having shadowed another IC and having been through a tabletop. The
  role is trained, not assigned by seniority.

**FORBIDDEN**
- ❌ Not declaring "so as not to make noise", or waiting to be sure before declaring.
- ❌ Requiring hierarchical approval to declare an incident.
- ❌ Negotiating the severity down because of its consequences (politics, SLA, customer, monthly report).
- ❌ Lowering the severity of a possible compromise or a possible breach before the assessment.
- ❌ An incident without a named IC, or an IC who debugs, types or investigates.
- ❌ IC and Ops lead in the same person in SEV1-SEV2.
- ❌ Coordinating by DM, by parallel threads or across three channels; an incident with no live written timeline.
- ❌ An indefinite IC shift in a long incident, or a command handover not announced in the channel.
- ❌ Hunting for the root cause while the user is affected, with a rollback available.
- ❌ Mitigating by destroying evidence (reinstall, recreate, power off) when compromise is suspected, without
  coordinating with `incident-response-forensics-standards`.
- ❌ External silence during a visible outage, or "intermittent problems" when it is down.
- ❌ Promising a resolution time; speculating publicly about the cause; multiple voices speaking
  outwards.
- ❌ Exploitable technical detail or PII on a status page, in a public postmortem or in the incident channel.
- ❌ A postmortem with culprits, with "human error" as its conclusion, or with *the* root cause in the singular.
- ❌ A postmortem without actions with a named owner and a date, or actions in a separate list nobody
  prioritises or reviews.
- ❌ Actions of the "be more careful", "train the team" or "review better" type as the sole remedy.
- ❌ Closing the incident without verifying the mitigation with telemetry.
- ❌ Using MTTR (or the incident count) as an individual, team or bonus target.
- ❌ Delaying the regulatory notification until the full diagnosis is available.
- ❌ Improvising the map of legal obligations during the incident.
- ❌ Tabletops and game days announced as a demonstration; if it cannot fail, it is not an exercise.
- ❌ Turning the process into ITSM bureaucracy: CAB, forms and approvals inside the incident.

## 8. Mandatory web verification

Before committing to any figure, deadline or reference, **search for it — do not remember it**. Legal deadlines
are where inventing costs the most:

1. **GDPR art. 33-34 and the AEPD's guidance** on breach notification: the deadline, the electronic
   office channel and the risk criteria. Verified Aug-2026: 72 h from awareness, phased
   notification admissible.
2. **NIS2 (Directive 2022/2555) and its Spanish transposition**: 24 h / 72 h / 1 month confirmed as of
   Aug-2026; **pending**: the Ley de Coordinación y Gobernanza de la Ciberseguridad had still not been
   published in the BOE — confirm its status, the exact recipient and whether the NIS2 revision proposed
   by the Commission (January 2026, with reporting of ransom details in ransomware) is already in force.
3. **DORA**: 4 h / 24 h / 72 h / 1 month and the reporting RTS (Regulation 2025/301 and its annexes).
   There are sources describing a four-milestone model instead of three: **cross-check**.
4. **ENS (RD 311/2022) and guide CCN-STIC 817**: deadlines by impact level (24 h / 72 h / 5 days
   circulate in secondary guides). **Not verified against the primary source** — confirm it before
   using it.
5. **ITIL**: ITIL 4 remains operative; PeopleCert announced **ITIL v5 in February 2026** with
   publications still pending. Verify the status before quoting normative ITSM guidance.
6. **Incident command references**: `response.pagerduty.com` (roles, IC training) and Google's
   incident management guide (`sre.google`, IMAG, chapter 9 of the SRE Workbook).
   Check whether they have changed before quoting them as canon.
7. **Stance on ransom payment**: verified Aug-2026 — the **United Kingdom** is advancing a
   ban for the public sector and CNI plus a duty to notify before paying; the **EU and Spain**
   do not prohibit paying and regulate through transparency and sanctions/AML. It changes fast: verify it, and the
   decision to pay **is not technical** (see `incident-response-forensics-standards`).
8. **Management tools** (paging, status page, incident bots) you are going to recommend: status,
   licence and any recent security incident at the vendor.

**Declared gap**: the ENS deadlines by impact level (§6) and the exact detail of DORA's milestone
model have not been cross-checked against the primary source in this review. Do not use them without
verifying them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
