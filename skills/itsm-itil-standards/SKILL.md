---
name: itsm-itil-standards
description: Use when IT runs as a service with a customer on the other side — writing or reviewing a service catalogue entry with a named service owner, separating request fulfilment from incident from problem records in a ticket tool, defining request categories and a request catalogue, standard pre-approved changes versus a CAB and the change record that satisfies an auditor, change freeze and blackout windows, writing an SLA, OLA or underpinning contract with service hours, response and resolution targets, credits and exclusions, distinguishing a contractual SLA from an engineering SLO, service desk tiering, escalation matrices and follow-the-sun coverage, CMDB and CI relationships, discovery versus manual maintenance, configuration item ownership and drift, known error database and workarounds, ITIL 4 practices and ITIL Version 5, PeopleCert and AXELOS licensing of ITIL material, ISO/IEC 20000-1 certification scope, FitSM, YaSM or VeriSM as license-free alternatives, service reporting and first-contact resolution, or operating ServiceNow, Jira Service Management, Freshservice, GLPI, iTop, Zammad, OTOBO or Znuny.
---

# ITSM / ITIL standards — the service contract with the business

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **IT service management as an explicit commitment to a customer**: which services exist
and who answers for each one, how work comes in (request, incident, problem, change), what is
promised in writing (SLA/OLA/underpinning contract), what is recorded as evidence and what is
measured.

Triggers: "service catalogue", "service owner", "service request", "request", "incident
vs. problem", "known error", "workaround", "change management", "CAB", "standard change", "change
window", "freeze", "RFC", "SLA", "OLA", "underpinning contract", "SLA penalty", "service
desk", "L1/L2/L3", "escalation", "CMDB", "CI", "discovery", "ITIL", "ITIL 4", "ITIL v5",
"ISO 20000", "FitSM", "ServiceNow", "Jira Service Management", "GLPI", "iTop", "Zammad", "OTOBO".

**Governing principle**: **ITSM is the service contract with the business, not the bureaucracy that
surrounds it.** The typical failure of an ITSM implementation is not a lack of process: it is the
**process that exists to protect rather than to deliver** — the committee that approves in order to
spread the blame, the ticket closed so as not to breach the SLA, the CMDB maintained for the
auditor. A falsifiable test to apply to any proposed process: **name the decision it makes and who
makes it; if it makes no decision that changes the outcome for the customer, it is removed.**

Operational corollary: **a process with no named owner does not exist** — the template exists.

**Not applicable**:
- `incident-management-standards` (**critical boundary**): the **management of the live technical
  incident** — declaration, severity, Incident Commander, crisis communication, status page,
  mitigation decision, blameless postmortem and its actions. Here, instead, **the service process
  around it**: the recording and categorisation of the ticket, the contractual SLA being consumed,
  the **hierarchical** escalation (notifying whoever answers to the customer, not whoever fixes it),
  the relationship with the customer and the conversion of the incident into a problem. Arbitration
  rule: while the service is down, `incident-management-standards` governs; the record, the
  contractual commitment and the subsequent follow-up are governed here. **Both writings must
  coexist in the same ticket without duplicating command.**
- `sre-practice-standards`: **SLIs, SLOs, error budget, burn policy, on-call and reliability** are
  theirs. Here the **contractual SLA**. **An SLA is not an SLO** (§3): confusing them produces one of
  two pathologies — committing the internal objective to the customer (impossible commitments) or
  deriving the internal objective from the contract (objectives with no engineering meaning). The
  DORA metrics are theirs.
- `cicd-standards`: **automated deployment and its gates** (tests, in-pipeline approvals,
  signing, artifact promotion). Here the **change record and its evidence**: what was deployed,
  who authorised it, against which CI and with what rollback plan.
- `grc-compliance-standards`: the **regulatory framework and the audit evidence** (ISO 27001, ENS,
  EU DORA, NIS2), control mapping and the formal acceptance of risk. Here only the service
  process that **generates** that evidence.
- `bcdr-standards`: continuity, BIA, RTO/RPO and DR activation. An incident that escalates to a
  disaster leaves this process.
- `observability-standards`: the telemetry with which it is detected and diagnosed.
- `onprem-standards`, `homelab-standards`: the platform the service runs on.
- `knowledge-management-standards`: the **knowledge base** — authorship,
  review, expiry and curation of articles. Here only its **hook into the process**: the KEDB and the
  mandatory article on closing a problem.
- `platform-engineering-standards`: the internal developer portal and the
  catalogue of *software templates*. The boundary is the customer: **the platform serves internal
  teams with self-service; ITSM serves a customer with a commitment**. The portal does not replace
  the service catalogue nor the other way round.
- `enterprise-architecture-standards`: the **application and capability
  inventory**. It crosses with the CMDB and the service catalogue: the application inventory is the
  architecture view (lifecycle, business capability, *fit*), the CMDB is the operational view
  (what is deployed and what it depends on). **The same object, two views: if two sources of truth
  are maintained with no single owner, both degrade** — name which one is authoritative per
  attribute.
- `cmdb-inventory-standards`: **the CI data model, its stable identifier, discovery, reconciliation
  between sources and the freshness of the record are theirs**. Here the process that consumes it
  and the service decision taken with it.
- `project-management-standards`: the **delivery** of the new or changed service. Reciprocal:
  **the project delivers, the service operates**; the handover is an artifact with acceptance
  criteria (§3) and **a project that delivers something nobody can operate has not finished**.

## 2. Default decisions

> Verify on the web the status of frameworks, editions and prices before committing to them in a real
> project (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Reference framework | **FitSM** as a citable skeleton (free, no per-user licence) + ITIL vocabulary where the customer demands it | ITIL 4 / ITIL (Version 5) if the contract or the customer imposes them; ISO/IEC 20000-1 if certification is sought |
| Normative material in internal documents | **Only FitSM or ISO** cited with a reference; **never paste ITIL text** | — (a legal restriction, not a matter of taste) |
| Formal certification | **No, unless a customer or a tender requires it** | ISO/IEC 20000-1 when a tender demands it |
| Record types | **Four separate, non-mergeable types**: request, incident, problem, change | — |
| Change approval | **Pre-approved standard change + peer review in the PR** as the normal route | CAB **only** for a major/non-standard change |
| CAB frequency | **On demand** (convened by a change that requires it) | A fixed cadence only if the volume of major change justifies it; never weekly by default |
| Commitment published to the customer | **An SLA with a threshold worse than the internal SLO**, with an explicit margin | — |
| CMDB | **Populated by automatic discovery**; minimum viable scope | Manual recording only for attributes no tool can discover (owner, criticality, contract) |
| Desk structure | **Swarming over a pool with the competence**, with a single entry point | Classic L1/L2/L3 only with high volume and genuinely repetitive work at L1 |
| Tooling | The **one already in use**, if it covers the four record types; greenfield: self-hosted GLPI or iTop (GPL/AGPL) | ServiceNow / Jira Service Management / Freshservice when size or integration imposes it |
| Headline metric | **Time to restoration as perceived by the user** and **% of requests resolved with no human intervention** | — |

**Real status of the frameworks (verified Aug-2026, re-verify §8)**:
- **ITIL is commercial property**. The trademark is today owned by **PeopleCert**, which **completed
  the acquisition of AXELOS Limited in July 2021** (the deal was announced on 21-Jun-2021).
  Previously, AXELOS was a *joint venture* of the UK Cabinet Office and Capita. Practical
  consequence: **ITIL material is paid for and its text cannot be reproduced in internal
  documentation or in a repository**; PeopleCert's official ITIL Foundation (Version 5) page lists
  exam packages **from €483 to €1,213 (VAT incl.)** at the time of verification. An internal process
  **is written with your own vocabulary or with a free source**, not by copying ITIL.
- **Current version**: PeopleCert publishes **ITIL (Version 5)**; its announcement page literally
  says *"ITIL 4 remains available for those who wish to continue their current certification
  journey"* and *"Your existing ITIL knowledge and certifications continue to hold their value as
  ITIL evolves"*. **Declared discrepancy**: the exact launch date (**12-Feb-2026** for Foundation)
  and the module calendar appear on **training providers' sites, not on the official page**, which
  shows no date; treat the date as unconfirmed until it is seen on peoplecert.org (§8). **ITIL 4
  defines 34 practices** (14 general, 17 service, 3 technical); the reorganisation in Version 5 must
  be verified against the official source before citing it — **it is not written from memory**.
- **ISO/IEC 20000-1:2018** (3rd edition) is still in force, with **Amd 1:2024 "Climate action
  changes"**, a minor change on context and interested parties. It is **certifiable** and **paid
  for** (the amendment is distributed at no cost; the base standard is not).
- **FitSM**: free and citable. Maintained by the FitSM working group of **ITEMO e.V.**; core
  FitSM-0/1/2/3 (+ FitSM-6 on maturity), version **3.0** (2021 edition, aligned with ISO/IEC
  20000:2018). **Declared discrepancy about the licence**: third-party sources say CC BY 4.0, but the
  official FitSM-1 V3.0 PDF links **Creative Commons Attribution-NoDerivatives 4.0 (CC BY-ND 4.0)**.
  **ND matters**: it can be redistributed and quoted in full, **not adapted nor published as a
  modified version**. Verify the licence printed in the specific PDF you download before deriving
  material from it.
- **YaSM**: a commercial template model (19 processes) with a free public wiki; useful as a map,
  **it is not a standard**. **VeriSM**: no signs of recent development beyond training; **it is not a
  standard and it does not certify organisations**. Neither of the two is used as a normative basis.

**Citability rule**: in an internal document, in a repository or in a response to a tender,
**cite FitSM or ISO/IEC 20000-1**. ITIL is mentioned as common vocabulary, never transcribed.

## 3. Structure and conventions

### Service, system and component

Three levels, three owners, three languages. Confusing them is the root cause of useless catalogues.

| Level | Operational definition | Named in | Owner |
|---|---|---|---|
| **Service** | What the customer buys or consumes and can describe without knowing about IT ("billing", "email") | Service catalogue, SLA | **Service owner** (a person, not a team) |
| **System** | A deployable unit that implements part of a service (an app, a cluster) | Application inventory, CMDB | Owning team |
| **Component / CI** | A manageable unit with a lifecycle of its own (VM, database, certificate, contract) | CMDB | Team or provider |

**Rule**: an SLA is signed **over a service**, never over a component. Promising the availability of
a VM means nothing to the customer and produces the worst outcome of all: the SLA is met while
the service is down.

### Service catalogue (mandatory artifact)

A file versioned in Git (YAML/Markdown), not a table in the wiki. **Minimum and mandatory** fields
per entry — an entry missing any of them **is not published**:

```yaml
- id: svc-billing
  name: Customer billing
  business_description: Issuing and sending monthly invoices   # no IT jargon
  service_owner: firstname.lastname                            # a person, not a team
  criticality: 1                                               # tier 1..4, derived from BIA (bcdr)
  service_hours: Mon-Fri 07:00-21:00 Europe/Madrid
  sla: sla-billing-v3.md                                       # or "no formal SLA", explicit
  supports_business_process: [monthly_close, collection]
  systems: [billing-api, billing-batch]                        # link to CMDB
  external_dependencies: [payment-gateway-x]                   # with an underpinning contract
  published_requests: [user-onboarding, invoice-reissue]
  review: 2026-06-01                                           # expires after 12 months
```

**Mandatory annual review with a hard expiry**: an entry not reviewed in 12 months is automatically
marked `OBSOLETE` and stops providing contractual cover. A catalogue with no expiry becomes
fiction in two years.

### The four record types (an operational definition, not a doctrinal one)

| Type | Objective | Ends when | Its own metric |
|---|---|---|---|
| **Request** | Delivering **foreseen work** already authorised (user onboarding, quota, access) | The user has what they asked for | % automated, delivery time |
| **Incident** | **Restoring the service** as soon as possible | The service works (even with a *workaround*) | Time to restoration |
| **Problem** | **Eliminating the cause** of one or more incidents | The cause is eliminated **or** formally accepted as a risk | Incidents avoided, age of the problem |
| **Change** | Modifying the environment with controlled risk and evidence | It is deployed and verified, or rolled back | Change failure rate, lead time |

**Why mixing them breaks the metrics** — it is arithmetic, not philosophy:
- A request filed as an incident **inflates the incident volume** and sinks the mean time: an
  improvement in MTTR is celebrated that only means more users have been onboarded.
- An incident closed with a *workaround* **without opening a problem** makes the pending work vanish:
  the same failure is paid for N times and appears in no indicator.
- A problem treated as a permanent incident keeps a ticket open for months and **destroys any
  measure of resolution time**.

**Hard rule**: an incident **never** turns into a problem; it is **closed** on restoration and a
linked problem is **created**. Closing the incident is not hiding the work: the problem inherits it.

**Self-service rule**: any request that recurs **>10 times a month** and requires no human judgement
is automated or removed from the catalogue. A recurring manual request is measured operational debt.

### Change management: the evidence matters, the committee does not

**A verified datum and its consequence.** DORA (Google) documents in *Streamlining change approval*
(updated 30-Oct-2025) that heavyweight external approvals **do not add stability**:

> "DORA's research shows that these approaches have a negative impact on software delivery performance."

> "Further, no evidence was found to support the hypothesis that a more formal, external review process
> was associated with lower change fail rates."

And the alternative the same source prescribes for the segregation of duties requirement:

> "Use peer review to meet the goal of segregation of duties, with reviews, comments, and approvals
> captured in the team's development platform as part of the development process."

Origin of the finding: the **State of DevOps Report 2019** (cited by the page itself). **Declared
caution**: the strong formulation that circulates on blogs — *"worse than having no approval process
at all"*, *"2.6 times more likely to be a* low performer*"* — **does not appear on the verified
dora.dev page**; it comes from the synthesis in the book *Accelerate* and from the 2019 report.
**Quote only the verbatim above**; if the figure is needed, take it from the original report and cite
it with its year and sample, never from a blog.

**Practical consequence, written as policy**:

1. **Standard change** (by default): low risk, a known procedure, reversible and with a pipeline.
   **Pre-approved** by the service owner via a **standard change template** with explicit eligibility
   criteria. It does not go through a committee. The authorisation is **the peer review of the PR**.
2. **Normal change**: it does not fit any standard template. Approved by the service owner + the
   technical owner. A committee **only** if it touches several tier 1 services or there is a window
   negotiated with the customer.
3. **Emergency change**: executed first, recorded **within 24 h** with the same evidence.
   An emergency process used in >10% of changes means the normal process is
   broken: fix the normal one, do not restrict the emergency one.

**Reconciliation with DevOps/SRE — the real knot of the domain.** The auditor does not ask for a
committee: they ask you to demonstrate **authorisation, segregation of duties, traceability and the
ability to roll back**. All of that is produced by the pipeline better than by a meeting. The minimum
evidence that satisfies an auditor **without slowing delivery**, generated automatically and linked
in the change record:

- **Authorisation**: a PR approved by someone other than the author (segregation of duties), with
  verifiable identity — a branch protection that enforces it, not a written rule
  (`git-workflow-standards`).
- **Traceability**: commit → signed artifact → deployment, with an immutable digest
  (`cicd-standards`).
- **Control evidence**: the result of the CI gates (tests, SCA, IaC scan) attached to the record.
- **Rollback**: the identifier of the previous version and the rollback method, tested.
- **Record**: the change ticket **is created from the pipeline via API**, not by hand. If a human
  types the change record, it will be filled in late, badly or never.

**Windows and freezes**: a freeze is a business decision with an end date and an owner, and
**it must declare what remains permitted** (always: critical security patches and rollbacks). An
indefinite freeze accumulates a large batch and **worsens** the risk it was meant to avoid.

### Agreements: SLA ≠ OLA ≠ underpinning contract ≠ SLO

| Object | Between | Owner | Nature | Consequence of breach |
|---|---|---|---|---|
| **SLA** | Provider ↔ **customer** | Service manager / commercial | **Contractual** | Penalty, credit, executive escalation |
| **OLA** | **Internal** teams | Service owner | Internal, binding | Internal escalation; **never** shown to the customer |
| **Underpinning contract (UC)** | Provider ↔ **third party** | Vendor manager | Contractual with the third party | A claim against the provider |
| **SLO** | **Engineering with itself** | The service's owning team | A technical objective with an error budget | Freeze features, prioritise reliability |

**An SLA is not an SLO.** Hard rules:
- The **SLA is published worse than the SLO** with an explicit margin (e.g. SLO 99.9% → SLA 99.5%).
  The margin is the buffer so a bad quarter is not a contractual breach.
- **Deriving the SLO from the SLA is forbidden**: the engineering objective is born of the impact on
  the user, not of what was signed. An SLO equal to the SLA turns every normal consumption of error
  budget into a legal risk.
- The chain has to close: **SLA ≤ min(OLAs) ≤ min(UCs)**. Promising 99.95% while relying on a
  provider with a contractual 99.9% is a scheduled breach. **Check it in writing before
  signing** — it is arithmetic, not negotiation.
- Every SLA declares: **service hours, exclusions (planned maintenance, customer causes,
  force majeure), the measurement method and who measures**. An SLA with no agreed measurement method
  will be disputed at the first incident.
- **An availability metric measured from the user** (successful requests / total requests with
  external probing), not from a ping to the server.

### Service desk and escalation

- **A single entry point** per published channel; the "informal channel" (a direct message to the
  engineer) does not exist as a way of working: it is always redirected into a record.
- **Tiered escalation is a source of latency** and must be treated as such. Every L1→L2→L3 hop
  adds a queue, a re-contextualisation and a loss of information. Rule: **if 30% or more of the
  tickets in a category end up at L3, that category should not go through L1** — it is routed
  directly.
- **Hierarchical escalation ≠ functional escalation**. Functional seeks technical competence;
  hierarchical seeks the authority to decide (spend, stop, communicate to the customer). **They are
  triggered by different criteria and documented separately.**
- **An explicit time threshold per severity and per category**, automatic: escalation does not depend
  on someone remembering. If the system does not escalate on its own, the process is the technician's
  goodwill.
- **Shift / follow-the-sun**: the handover is a written artifact (state, hypotheses ruled out, next
  step, who owns it now), not a conversation.

### CMDB: what justifies its cost

A CMDB **is only justified if it answers questions that are genuinely and frequently asked**. The
four canonical ones: *which service does this component affect?*, *what does this service depend
on?*, *who answers for this?*, *what changed before the failure?*. **If they are not going to be
asked, a CMDB is not built.**

- **Automatic discovery as the principle, manual maintenance as a justified exception**. The
  reason most CMDBs degrade is not laziness: it is that the environment changes faster
  than the human pace of updating, and a CMDB with 20% false data **stops being consulted**,
  after which it degrades to 100% without anyone noticing.
- **Minimum viable scope**: only CIs whose relationship with a service is needed to decide. Modelling
  every installed package is a guarantee of abandonment.
- **Permitted manual attributes** (the ones no tool discovers): owner, criticality, the service
  it belongs to, contract, end-of-support date. Everything else, discovered.
- **A mandatory, published health metric**: % of CIs with discovery in the last 24 h, % with a
  valid owner (an existing person), and **the number of real queries per month**. The third is what
  decides whether the CMDB is still alive: **a CMDB nobody consults is switched off, not improved**.
- It is **reconciled against architecture's application inventory** by declaring an authoritative
  source per attribute; two inventories with no reconciliation produce two lies.

### Handover to operations (the boundary with the project)

An acceptance artifact signed by the service owner **before** the project closes. Without these
items, **the service does not enter supported production** (and the project is not finished):

1. A published service catalogue entry, with an owner and a criticality.
2. Agreed SLA/OLA, or an explicit "no formal SLA" declaration signed by the business.
3. Runbooks for the three most frequent operations + a tested rollback procedure.
4. Actionable alerts with a defined on-call destination (`observability-standards`).
5. Backup with a **tested restore** and the date of the test (`backup-recovery-standards`).
6. Requests published in the catalogue and ticket categories created in the tool.
7. CIs in the CMDB with discovery working.
8. Recorded training of whoever is going to support it, and a *hypercare* period with an end date.

## 4. Process quality and verification

The equivalent of tests here are **automatic controls over the process data**. They run on a
schedule and their failure opens work, not a report.

| Control | Fails if | Action |
|---|---|---|
| Expired catalogue entries | review > 12 months | Mark `OBSOLETE`, notify the owner |
| Services with no person owner | `service_owner` empty or non-existent in the directory | Block publication |
| Agreement chain | SLA > min(OLA) or > min(UC) | Block signing |
| Orphan CIs | a CI with no associated service | Purge or assign within 30 days |
| Stale CIs | no discovery > 30 days | Mark `stale`, exclude from reports |
| Ticket reopenings | > 5% of those closed | Audit the closing criteria (a symptom of closing to meet an SLA) |
| Recurring incidents with no problem | ≥ 3 incidents of the same category in 30 days with no problem opened | Open a problem on the desk's own initiative |
| Emergency changes | > 10% of the total | Review the normal change process |
| Changes with no linked evidence | a record with no PR, no artifact or no rollback plan | Mark as non-conforming |

**Service metrics and the ones that game themselves.** Any metric a human can improve without
improving the service degrades when used as a target:
- ❌ **Ticket closing time** as a target: it is optimised by closing sooner, not by resolving sooner.
  Its symptom is the reopening rate; always measure **closing and reopening together, or neither**.
- ❌ **Tickets closed per technician**: it rewards slicing up the work and punishes automating.
- ❌ **Permanently green SLA compliance**: it measures the contract's margin, not the experience.
- ✅ **Time to restoration as perceived by the user**, **% of requests with no human intervention**,
  **incidents repeated from a known cause**, **age of open problems**, **cost per request**.
- **CSAT/survey**: only with the response rate published alongside the value. A CSAT of 4.8 with a 4%
  response rate is not a datum, it is noise.

**Service review**: a quarterly meeting with the customer over data published beforehand. If the
review is the first time the customer sees the numbers, the relationship is already broken.

## 5. Process security

- **The ITSM tool is a high-value target**: it contains the map of the infrastructure, the
  approval chain and often credentials pasted into tickets. Treat it as a tier 1 system: SSO with
  MFA, RBAC by process role, and an immutable audit log of approvals and state changes.
- **Pasting secrets into tickets or into the CMDB is forbidden**. Add secret scanning over the
  tickets' text fields, not just over the repository (`secrets-management-standards`). A secret in a
  ticket is a secret shared with the whole service desk and with its export history.
- **The service desk is the social engineering vector par excellence** (password reset,
  MFA enrolment, device change). An identity verification procedure that is
  **written, mandatory and without exception for urgency or hierarchy**; privileged credential
  resets require out-of-band verification (`identity-access-management-standards`).
- **Automating request fulfilment needs least privilege**: the account that creates
  users cannot also be able to create administrators. An automated request with excessive
  permissions is a privilege escalation with a form attached.
- **Retention and personal data**: tickets contain personal data and sometimes special
  categories. A retention policy with effective erasure, attachments included
  (`privacy-engineering-standards`). Attachments are the usual blind spot.
- **External portal**: if the customer opens tickets, the portal is exposed surface with
  authentication, multi-tenant isolation and access control over attachments. An IDOR flaw in the
  portal exposes the neighbouring customer's entire operation.

## 6. Operation and capacity of the process itself

- **Sizing by measured demand, not by intuition**: volume per category × mean handling time,
  with headroom for known peaks (month-end close, start of term, campaign). Publish the assumption.
- **Cost per contact as a management datum**: without it you cannot justify automating or argue for
  self-service. It is the figure that turns a discussion of opinion into a decision.
- **A work queue with limited WIP**: a desk with 40 tickets "in progress" per technician does not
  have 40 in progress, it has 39 stalled and one optimistic report.
- **The process degrades too**: a six-monthly review of each process with the criterion of §1 — what
  decision it makes, who makes it, what would happen if it were removed. Whatever does not survive
  that question is retired.
- **Tool ↔ pipeline integration by API** in both directions, with idempotent retries: create
  the change record from CI and close the ticket from the deployment. If the link is made by hand,
  it will stop being made.
- **The ITSM tool cannot depend on the service it manages**: if ticketing goes down with
  SSO, there is no way to manage the SSO outage. A documented and tested alternative escalation
  route.

## 7. Sustainability and prohibitions

**Cadence**: catalogue reviewed annually per entry; agreements reviewed at each contract
renewal and after any architecture change that alters the dependencies; processes reviewed
every six months; standard change templates reviewed after each failed change of that type.

**Deprecation**: retiring a service is a project with its own handover (communication to the
customer, data migration, end of support, deletion of CIs and of the catalogue entry). A "switched
off" service that remains in the catalogue generates tickets and contractual expectations for years.

FORBIDDEN:
- ❌ **A process with no named owner** (a person, not a team or a committee). With no owner there is
  no process, there is a document.
- ❌ **A fixed weekly CAB approving low-risk changes**. It contradicts the published evidence (§3),
  adds latency, enlarges the batches and does not reduce the failure rate. Low-risk change →
  pre-approved standard + peer review.
- ❌ **An approver who cannot in practice reject** (a committee that approves 100%): it is a rubber
  stamp, and a rubber stamp is latency disguised as control. Either it makes decisions or it is
  removed.
- ❌ **A CMDB nobody consults**. Switch it off. Maintaining data nobody reads is pure cost and false
  assurance.
- ❌ **Measuring performance by tickets closed** or by closing time in isolation. It rewards slicing
  and closing falsely, and punishes automating.
- ❌ **Closing an incident without opening a problem when it was restored with a *workaround***.
- ❌ **Recording requests as incidents** (or the other way round) to make an indicator add up.
- ❌ **An SLA over a component** instead of over a service.
- ❌ **An SLA equal to or more demanding than the internal SLO**; and **deriving the SLO from the
  SLA**.
- ❌ **Signing an SLA more demanding than the underpinning contract of the provider** you depend on.
- ❌ **Copying ITIL text into internal documentation or into a repository**: it is PeopleCert's
  proprietary material. Cite FitSM or ISO/IEC 20000-1.
- ❌ **An indefinite or ownerless change freeze**, or one that blocks critical patches and rollbacks.
- ❌ **An informal way of working** (a request by direct message that generates no record): it
  destroys measurement, sizing and traceability, and concentrates the knowledge in one person.
- ❌ **Secrets, credentials or dumps of personal data in tickets, comments or attachments**.
- ❌ **Buying a tool to fix an ownerless process**: you get the same mess, with an annual invoice and
  a migration project.
- ❌ **Certifying to ISO/IEC 20000 with no business need**: a recurring cost and a paper process.

## 8. Mandatory web verification

Before committing to any of these points in a real project:

1. **ITIL**: the current version and the real calendar of ITIL (Version 5) **on peoplecert.org** —
   the date 12-Feb-2026 comes from training providers and **is not confirmed on the official page**
   (declared discrepancy in §2). Also verify Version 5's practice structure against
   ITIL 4's 34, and the validity/expiry of ITIL 4 certifications.
2. **ITIL ownership and licence**: PeopleCert completed the purchase of AXELOS in Jul-2021 — check
   that it has not changed hands again and review the terms of use for the trademark and the material
   before citing it.
3. **ISO/IEC 20000**: whether -1:2018 is still the current edition or a 4th edition is under way; the
   status of Amd 1:2024 and of parts -2, -3, -6 and -10; price and national adoption (UNE/BS).
4. **FitSM**: the current version (is it still V3.0?) and the **exact licence printed in the PDF** —
   CC BY-ND 4.0 according to the official FitSM-1 V3.0 PDF, CC BY 4.0 according to third parties.
   **ND forbids derivative works**: confirm it before adapting the text.
5. **VeriSM and YaSM**: check whether they are still maintained before even mentioning them as an
   alternative.
6. **Evidence about the CAB**: re-read `dora.dev/capabilities/streamlining-change-approval/` (last
   update seen: 30-Oct-2025) and the most recent DORA/State of DevOps report. **Quote verbatim**;
   the strong formulations circulating on blogs ("2.6×", "worse than having no process") **are not on
   that page**: if they are used, take them from the original report with year and sample.
7. **Tooling**: the current status, version and pricing model of ServiceNow (per *fulfiller*, per
   module, with no public tariff), Jira Service Management (per agent; Atlassian has reorganised its
   offering into a *Service Collection* and is retiring Data Center — verify dates and prices on
   atlassian.com), Freshservice (per agent, with AI as an *add-on* on the low plans). The ServiceNow
   and Freshservice figures that circulate come from third-party blogs: **they are not quoted as a
   price**, only the licensing model. For the open-source ones (GLPI, iTop, Zammad, OTOBO, Znuny),
   **read the repository's raw `LICENSE`** and check what is left outside the free core
   (certified plugins, "Network"/enterprise editions).
8. **The applicable regulatory framework** (EU DORA, NIS2, ENS) in case it imposes requirements on
   change management, incident recording or notification with deadlines — cross-check with
   `grc-compliance-standards`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
