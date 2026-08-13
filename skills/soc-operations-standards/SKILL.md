---
name: soc-operations-standards
description: Running the security operations function as an operation, not a product. Use when choosing between an in-house SOC, an MSSP or MDR provider and a hybrid model, sizing 24x7 shift coverage and follow-the-sun rotations, writing shift handover notes, managing the alert queue and its backlog, automated enrichment before triage, triage and escalation criteria, structured close codes and case management (TheHive, Cortex, IRIS, Shuffle, Tines, n8n, SOAR playbooks and what must never be automated), analyst tiering and why the tier model ages badly, alert fatigue and analyst burnout, actionable-alert ratio as a service-level indicator, the rule-retirement process, SOC metrics that survive scrutiny (time to detect, time to contain, telemetry coverage) versus vanity counts of closed alerts, SIEM ingest volume as the dominant cost driver and what to keep hot, warm or cold, scheduled threat hunting with a written hypothesis and a hunt report (PEAK, hunting maturity model), purple-team scheduling and deconfliction, SOC-CMM maturity assessment, or MITRE's 11 Strategies.
---

# SOC operations standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **operating the monitoring function**: SOC model and the build, buy or mix decision;
hours of coverage and shift sizing; roles and how they evolve; the **life cycle of an alert**
—enrichment, triage, escalation, closure with a structured reason—; queue and backlog
management; alert fatigue and team health; the process of **retiring or fixing** whatever
generates noise; service metrics and their audit; ingest cost as an operational decision;
automation with SOAR and its limits; **threat hunting** as a scheduled activity distinct from
triage; and the coordination of *purple team* exercises.

Triggers: "SOC", "MSSP", "MDR", "security operations centre", "shift", "handoff",
"handover", "SOC on-call", "alert queue", "alert backlog", "triage", "escalation",
"tier 1/2/3", "tier 1", "alert closure", "close code", "alert fatigue",
"analyst burnout", "SOAR playbook", "TheHive", "Cortex", "IRIS", "Shuffle", "Tines",
"n8n", "case", "case management", "hunt hypothesis", "threat hunting", "PEAK", "hunting
maturity model", "purple team", "deconfliction", "SOC-CMM", "11 Strategies", "ingest
cost", "GB/day", "alerts per analyst per hour", "time to contain".

**Guiding principle**: **a SOC is an operational function, not a tool.** People buy a SIEM and
believe they have built a SOC; what they have built is a log warehouse with an invoice.
And its typical failure is **measuring activity instead of outcome**: closing 4,000
alerts a month is a metric that rises on its own by closing faster and worse, and that peaks
exactly when the team has stopped looking. Corollary: **a SOC is not judged by what it
processes, but by what would have gone unnoticed and did not** — and by whether the person
on shift at 4 in the morning has what they need to decide.

**Not applicable**: the **detection rule, its analytic content, log normalisation and
ATT&CK coverage as engineering** are `detection-engineering-standards` —here you decide whether
a rule is attended to, fixed or retired; there it is written and tested—; the **confirmed
incident, evidence-preserving containment and forensics** are
`incident-response-forensics-standards`, and **the incident process** —severity, command,
communication, postmortem— is `incident-management-standards`: the SOC's deliverable
**ends exactly at the handoff**, and their postmortem hands work back to it.
The **telemetry platform** (pipeline, retention, integrity) is
`observability-standards` and **ingest cost as an economic unit** —pricing model,
commitment, cost per GB and per case calculation— is `finops-standards`; here only the
operational decision of what is kept, where and for how long. The **offensive exercise, with
scope and written authorisation**, is `offensive-security-standards` (this skill is **defensive**;
the SOC contributes the *deconfliction* and the learning, it does not run the attack), the **triage and
patching priority** of `vulnerability-management-standards`, **the indicator, its expiry and
the report it comes from** of `threat-intelligence-standards`, and **email as a channel with
its own controls** of `email-security-standards`.
Also: `identity-access-management-standards` (the privileged access of the analysts
themselves and the identity tooling they monitor), `dns-standards`,
`networking-standards` and `firewall-policy-standards` (the network signal and the control the SOC asks
to be applied), `privacy-engineering-standards` (**personal data inside logs and cases**:
legal basis, minimisation and retention), `grc-compliance-standards` (regulatory framework, duty
to notify and audit evidence), `itsm-itil-standards` (**the ticket and the contractual
SLA**, including the MSSP's), `sre-practice-standards` (on-call rotation design
and operational health), `mlsecops-standards` and `ai-governance-standards` (if there is AI
in the decision chain), `macos-fleet-standards` and `endpoint-security-standards`
(the endpoint agent and its telemetry).

## 2. Default decisions

> Verify version, licence and status of each framework or tool on the web before pinning it (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Model | **Hybrid**: MDR covers first-line 24×7; the in-house team keeps deep triage, hunting, engineering and the relationship with the business | Fully in-house when regulation demands it or knowledge of the environment is non-transferable; purely managed only in organisations with no security team |
| Coverage | **Extended in-house hours + external 24×7**. Your own 24×7 is justified by the cost of an hour without response, not by prestige | Own 24×7 with ≥3 sites (*follow-the-sun*) and sufficient volume |
| Work organisation | **By competence and flow** (triage / investigation / engineering / hunting), with rotation between them | Classic tiers 1-2-3 in a very large SOC or in an MSSP contract that demands them |
| Case management | **Dedicated** tool with case, timeline, artifacts and close code (TheHive/IRIS or equivalent) | The corporate ITSM if it already does the job, and **never** a chat channel as the system of record |
| Automation | **SOAR to enrich and decide less**, not to respond on its own | Automated response **bounded and reversible**, with human approval on anything destructive |
| Reference framework | **MITRE, *11 Strategies of a World-Class Cybersecurity Operations Center*** (2nd ed., 2022; Knerler, Parker and Zimmerman — succeeds *Ten Strategies*, Zimmerman, 2014), free download | **SOC-CMM** (Rob van Os) for maturity self-assessment, with the instrument freely downloadable and commercial services around it |
| Hunting methodology | **PEAK** (*Prepare, Execute, Act with Knowledge*; Splunk's SURGe team, Bianco and Fetterman), tool-agnostic, with its three hunt types and the **Hunting Maturity Model** (HMM0-HMM4) | Any method with a **written hypothesis and a recorded outcome**; without that it is not hunting, it is browsing the SIEM |
| Labelling of what gets shared | **TLP 2.0** from FIRST (authoritative since August 2022): **four labels** `TLP:RED`, `TLP:AMBER` (with `TLP:AMBER+STRICT` to restrict to the organisation), `TLP:GREEN`, `TLP:CLEAR` | — The labels are neither translated nor invented |

**The real cost of your own 24×7, with the arithmetic in plain sight**: a post covered without
interruption is **8,760 h/year** (365×24). Divided by the genuinely productive hours of
an FTE —those of your collective agreement minus holidays, public holidays, training and absence— you get on the order
of **5 to 6 FTE per post**, and that is the theoretical minimum **with no slack**. Two simultaneous
analysts are 11-12 people before counting supervision, engineering or sick leave. Do that
division with your own numbers **before** the conversation, and compare it against what it solves: if
time to contain in the small hours does not change because whoever decides is not on call, you have
paid for presence, not capacity.

## 3. The life of an alert

1. **Automatic enrichment, always before the human.** Every alert reaches the analyst already
   carrying: asset and its criticality, owner, user and their context (department, travel, recent
   onboarding), reputation and age of the indicators, related prior cases and the **rule's
   runbook**. If the analyst has to open five tabs to get started, the design is
   wrong and the cost is paid on every alert, every day.
2. **Triage with an explicit stopping criterion**: what evidence is enough to dismiss and what is enough
   to escalate. Without that criterion written down, each analyst invents their own and the FP metric
   stops meaning anything.
3. **Escalation by criterion, not by hierarchy**: you escalate when you need a capability you
   do not have (access, context, business decision, authority to disconnect), not when
   "it is hard". The handoff to an incident is declared and recorded: that is the moment
   `incident-management-standards` takes over.
4. **Closure with a structured, mandatory reason**, from a short closed list: *expected
   legitimate activity*, *undocumented legitimate activity* (→ generates inventory work),
   *authorised test* (→ *deconfliction*), *rule tuning needed* (→ goes to detection
   engineering), *contained true positive*, *escalated to incident*, *insufficient data*
   (→ goes to telemetry coverage). **A free-text closure is lost data**: the close
   reason is the raw material of all process improvement.
5. **Shift handover with a fixed format**: what is open and why, what is degraded, what
   changes are in flight in the organisation, what is expected to happen. The verbal handover and
   "it is all in the chat" are the usual cause of a case dying between two shifts.

**Why the tier model ages badly**: tier 1 was born so that cheap people could filter
volume by hand. When enrichment and dismissal are automated —which is where the
investment should go—, **what is left in tier 1 is exactly what cannot be automated**,
that is, the hard part. The outcome of the pure model is predictable: the least experienced
person is hired for the work that demands the most judgement, is forbidden from investigating and is
measured by closure speed; they churn within a year and take the knowledge with them. The alternative that
works is **a single queue with rotation by competence**, where whoever triages also investigates,
also hunts and also fixes the rule that annoys them.

## 4. Metrics: the ones that say something and the ones that game themselves

- **Ones that do say something**: **time to detect** and **time to contain** (medians and
  90th percentile, never the mean, which a single long tail destroys); **percentage of actionable
  alerts** out of the total; **log source coverage** against the asset inventory
  —what percentage of the estate emits the telemetry the rules assume—; **queue backlog**
  and its trend; **ratio of self-detection versus external notification**; **time from the
  closure of a noisy rule to its correction**.
- **Ones that game themselves and are forbidden as a target**: number of alerts closed,
  number of rules deployed, number of indicators loaded, percentage of "ATT&CK
  coverage" without adversary validation, and any mean without its percentile. All of them rise by working
  worse.
- **The false positive rate is a SOC SLI, with a declared target and an owner**. It is measured
  **per rule** (a single bad rule poisons the aggregate) and reviewed on a fixed cadence. The
  acceptable noise threshold is agreed in writing: if a rule exceeds its FP budget
  for two cycles, it enters the correction process **with a date**.
- **A rule nobody attends to: fix it or retire it. There is no third option.** A rule the
  queue systematically ignores is worse than not having it, because it shows up in the coverage report
  and creates the illusion that that path is watched. **Retirement is a normal, documented
  decision**, with its reason and its date; a SOC without a retirement process accumulates debt until
  the queue becomes useless.
- **Audit the metric against reality**: at least once a quarter, take a sample
  of alerts closed as false positives and **review them again blind**. It is the only way
  to know whether the FP number measures noise or measures fatigue.
- **External reference, with its bias declared**: *M-Trends 2026* (Mandiant/Google Cloud),
  built on **more than 500,000 hours of its own 2025 investigations**, puts the
  **global median attacker dwell time at 14 days** (up from 11), at **122 days**
  for espionage and North Korean IT worker operations, and puts at **52 %** the cases in
  which the organisation detected it by itself (versus 43 % in 2024). **Bias that has to be said
  out loud**: the sample is the customers who hired incident response after a
  serious breach — it is not a census, and comparing your number against it is useful for orientation, **never
  as a target**.

## 5. Automation, SIEM and cost

- **What gets automated without argument**: enrichment, correlation of duplicate cases,
  context gathering, opening and updating the case, notification, and the **low-impact
  reversible actions** (quarantining an already-delivered email, forcing
  reauthentication, flagging an asset for review).
- **What is never automated without explicit human approval**: any action
  **that is destructive or cuts service** — shutting down or isolating a production server, mass-disabling
  accounts, blocking a network range, deleting files, revoking certificates. The
  criterion is twofold: **is it reversible in minutes?** and **how much damage does it do if the trigger is a
  false positive?** If the answer to the second is "it stops the factory", there is a human in the loop,
  even at 4 in the morning. And every automation carries a **kill switch** and a record
  of each action with its justification.
- **Ingest is the SIEM's biggest expense and therefore an architecture decision, not a
  procurement one.** Rule: **the log comes in if it feeds a detection, an investigation or an
  obligation**; if it meets none of the three, it stays in cheap storage or is not
  collected. Tiers: *hot* (queryable in seconds, weeks of retention) for what
  the rules and triage use; *warm* for months-long investigation; *cold/object* for the
  regulatory obligation and old forensics. **Filtering at source** —not ingesting debug
  noise— is cheaper than any licence negotiation.
- **Buying the SIEM before having the sources is the classic expensive mistake**: the product is paid for
  from day one and the sources take quarters. The correct order is asset inventory
  → available sources and their value → use cases → estimated volume → platform.
- **Integrity and access**: security logs are written to **append-only** storage
  and with immutable retention for the critical ones; the SOC itself must not be able to alter them. Analyst
  access is privileged and audited: it contains personal data and evidence.

## 6. Threat hunting and purple team

- **Hunting is not triage under another name.** Triage reacts to an alert; hunting looks for
  what **no alert was ever going to raise**. If your "hunting" consists of going through the queue more calmly,
  you are not hunting.
- **Every hunt starts with a written hypothesis** —what adversary behaviour you expect, in
  which source it would be visible, what pattern would distinguish it from legitimate noise— and **ends in a
  short report with the outcome, including the negative one**. A hunt that finds nothing but proves
  that the necessary telemetry does not exist is a success: it has turned an assumption into a known
  gap.
- **Every hunt result has a mandatory destination**: a new or tuned rule (→
  `detection-engineering-standards`), a telemetry gap with an owner and a date, a control to
  change, or a discarded hypothesis with its reason. **A hunt that leaves no actionable trace has
  not been done.**
- **It is scheduled as a capability, not as free time**: assigned hours, protected from the shift.
  Hunting is the first thing to die when the queue gets tight, and that is why it has to be shielded.
- **Purple team**: the value is not in the attack, it is in the **joint session** where a
  technique is executed, you look at whether it appears in the telemetry, you see whether it raises an alert and you fix
  what is missing on the spot. The SOC contributes visibility, detection judgement and the record of
  what was seen and what was not; **the offensive exercise, its scope and its written authorisation belong to
  `offensive-security-standards`**. And the operational rule that avoids disaster: **prior
  deconfliction** —the SOC knows there is an exercise and has the channel to ask— with the counterpart
  that **a finding of real compromise during the exercise stops it** and activates the incident
  process.

## 7. Sustainability and prohibitions

Quarterly review of the catalogue of attended rules (usage, FP, retirement), of the source
inventory and of the load per shift; annual maturity self-assessment; review of the managed
provider's contract against what it actually delivers, not against what the SLA promises.

- ❌ **Measuring the SOC by alerts closed**, by mean time to close or by any counter
  that rises by working worse, and all the more so if it is tied to a bonus.
- ❌ **Buying a SIEM before having the log sources** and the asset inventory.
- ❌ **Operating without a formal rule-retirement process**, or retiring rules tacitly
  by ignoring them in the queue.
- ❌ **Automating a destructive or service-cutting response without human approval**, without
  a kill switch and without an auditable record of every action.
- ❌ Closing alerts in **free text** or with a single generic code such as "false positive".
- ❌ Letting **the queue backlog be the adjustment variable**: when there is not enough time, you
  reduce the incoming noise or you add capacity; **you do not quietly lower the bar**.
- ❌ **Contracting an MDR without defining what it escalates, within what time, with what evidence and to whom**,
  or without demanding the raw telemetry and the detail of its detections. A provider that will not let you
  audit its closures is selling you a number, not a service.
- ❌ Treating **24×7 as an end in itself**: presence without the authority to decide or the capacity to
  contain is cost without outcome.
- ❌ Using **chat as the system of record** for cases, or email as a queue.
- ❌ Putting the least experienced person in charge of deciding alone on what demands the most judgement, and
  measuring them by speed on top of that.
- ❌ **Shifts that prevent sleep** (backward rotation, chained nights without rest) or a
  night shift with no escalation available: the 4 a.m. mistake is a shift design failure,
  not the analyst's.
- ❌ Reporting **ATT&CK coverage as if it were detection**, without adversary validation.
- ❌ Ingesting "everything just in case" and discovering the cost on the invoice, or dropping sources on
  price without checking which detections depended on them.
- ❌ Hunting **without a written hypothesis or a report**, or sacrificing it the moment the queue gets tight.
- ❌ Running a **purple team without deconfliction** with the shift, or continuing it after finding
  signs of real compromise.

## 8. Mandatory web verification

1. **MITRE, *11 Strategies of a World-Class Cybersecurity Operations Center***: confirm
   the current edition and the free download URL (the 2nd ed. is from 2022 and succeeds *Ten
   Strategies*, 2014). **Declared gap**: the PDF hosted on `mitre.org` returned **403**
   from this environment; verify availability and whether there is a later edition.
2. **SOC-CMM**: **declared gap** — it has not been possible to confirm against an accessible
   primary source **the current version or the licence terms** of the instrument (the site serves
   the content via JavaScript). Confirmed only: created by **Rob van Os** and today sustained by
   an entity with commercial services (training, support, certification) around a
   free download. **Verify the licence before using it in a contractual deliverable.**
3. **MITRE ATT&CK**: verified **v19.1 (28 Apr 2026)** as the current version, with **two recent
   structural changes** that break old reports and layers: in **v18 (Oct 2025)** the
   *Detections* were replaced by **Detection Strategies** and **Analytics**, and the **Data Sources
   were deprecated**; in **v19** the *Defense Evasion* tactic **was split into Stealth (keeps
   TA0005) and Defense Impairment (TA0112)**. Check the version before reusing any
   coverage layer or mapping.
4. **TLP**: confirm that FIRST's **version 2.0** and its **four** labels are still current.
5. **External metrics**: any dwell time, cost or volume figure is re-checked against the
   primary source and **cited with its methodology and its bias**. Verified here: *M-Trends 2026*
   states >500,000 hours of its own 2025 investigations — a sample of incident response
   customers, not the general population.
6. **Figures discarded for lack of public methodology**: "the average analyst receives N alerts
   a day", "X % of alerts are never investigated", the average cost of a breach and the
   noise-reduction rates published by any SIEM, SOAR or MDR vendor about its
   own product. If whoever publishes the number sells the solution that number justifies and does not
   publish sample or method, **it is not used**: it is replaced by measuring your own queue,
   which is also the only one that is any use for deciding.
7. Status, licence and maintenance of the case management or SOAR tool being
   proposed, before pinning it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
