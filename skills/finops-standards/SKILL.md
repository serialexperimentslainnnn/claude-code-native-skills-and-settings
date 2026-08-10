---
name: finops-standards
description: Cost as an engineering metric, not a monthly invoice report. Use when defining a unit-economics metric (cost per request, per active user, per GB processed, per token), building a tag or label policy and the IaC/admission gate that enforces it, designing account/subscription/project layout as an allocation boundary, splitting shared and platform cost, deciding commitment coverage for reserved instances, savings plans or committed-use discounts, normalizing billing data with FOCUS (focus.finops.org, BilledCost, EffectiveCost, ContractedCost, ListCost, ChargeCategory, CommitmentDiscountId, AllocatedResourceId, ConsumedUnit, SkuId), reading a cost and usage export in a warehouse, wiring cost anomaly alerts and budget thresholds, choosing showback versus chargeback, running OpenCost or IBM Kubecost for Kubernetes cost allocation, adding infracost breakdown or infracost diff to a pull request, hunting idle resources, orphaned volumes, unattached public IPs, load balancers, non-production environments and data-egress or observability bills, tracking AI inference and token spend, or applying the FinOps Framework phases, domains, capabilities and Scopes.
---

# FinOps standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**FinOps is the discipline of deciding with cost as an engineering metric, not a monthly report on
the invoice.** A report describes the past and changes nothing; an engineering metric enters the
design review, the PR and the alert, and **blocks or unblocks decisions**. If cost only shows up on
a slide at the end of the month, there is no FinOps practice here: there is accounting.

**Hard constraint of this skill: it keeps the METHOD and cedes the specific SERVICE.** The cost
criteria for a given service —which instance class, which storage tier, which billing model that
managed database has, which flag makes it cheaper— **already live in `aws-standards`,
`azure-standards` and `gcp-standards`**, and that is where they are decided. Here we decide **how it
is measured, how it is allocated, who is accountable and which gate enforces it**, independently of
the provider. If this skill and a cloud skill give a figure about the same service, **the cloud
skill wins**.

Covers: the FinOps framework and its vocabulary (phases, domains, capabilities, Scopes), **unit
economics**, allocation (tagging and its governance, account hierarchy, shared cost), commitments and
discounts, the impact order of the levers, the hidden-cost catalogue, forecasting and budgeting,
anomalies, *showback*/*chargeback*, normalising billing data with **FOCUS**, cost in
Kubernetes, AI inference cost and tooling (`OpenCost`, `Kubecost`, `Infracost`).

**Not applicable**: see `aws-standards`, `azure-standards`, `gcp-standards` (**the specific service,
its pricing model and its configuration are theirs**; here the method, unit economics, allocation
and governance), `kubernetes-standards` (*requests*, limits, *autoscaling* and scheduling; **here
only the cost they produce and its split across tenants**), `iac-standards` (**tagging is enforced
in the code: the tool, the module and the state are theirs; the tag policy —which keys, which
values, what is mandatory— is from here**), `data-platform-standards`,
`lakehouse-standards` and `data-engineering-standards` (**scan cost and partitioning as a cost
decision already live there**: this skill does not re-decide a Parquet layout or a partition
key, it only demands that that cost has an owner and a unit), `gpu-computing-standards`
(**the GPU as an expensive resource that is shared, measured and planned is already theirs**; here
inference cost as a spend category and its unit), `caching-cdn-standards` (egress, *hit ratio* and
CDN billing), `object-storage-standards` (classes, lifecycle and per-request cost),
`sre-practice-standards` (**reliability versus cost is an explicit trade-off and the *error budget*
is theirs**: no cost optimisation is approved here if it consumes error budget without a decision
recorded there), `green-it-standards` (carbon footprint and
energy efficiency; cost and emissions **correlate but are not the same metric** —§6.4),
`grc-compliance-standards` (internal control, audit and segregation of duties over spend),
`platform-engineering-standards` (**the cost of the internal platform is one more unit economic and
is measured with the method from here**; tagging gates are implemented in their paved road and in
their admission layer), `enterprise-architecture-standards` (**the cost per application produced by this skill is
one of the inputs to their lifecycle decision** —tolerate, invest, migrate, eliminate—; the
inventory, the criticality and the governance of the standard are theirs. An expensive application
with no owner is not a cost problem, it is a portfolio problem), `green-it-standards` (**reciprocal
boundary because the two share levers and do not share a metric**: switching off what is idle, right-
sizing and choosing a region reduce cost **and** carbon, which is why they get confused. **Unit
economics belong here; the carbon unit is theirs.** They diverge more than it looks: **the embodied
footprint of hardware makes extending the useful life of a machine weigh more than optimising its
consumption**, which can contradict a replacement decision taken on cost alone; and a cheap region is
not necessarily a low-carbon-intensity region. **When the two metrics point in opposite directions,
both are declared and the business decides** — neither skill trims the other in silence).

## 2. Default decisions

> Verify the latest version and the state of the cited sources on the web before committing to anything (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Reference framework | **FinOps Framework** from the FinOps Foundation (a Linux Foundation programme), **2026** edition | None: there is no other framework with a vocabulary shared with the providers |
| Billing data format | **FOCUS**, version **1.4** (ratified on **4 Jun 2026**) as the target schema | 1.3 / 1.2 if the provider does not yet emit 1.4; **never** the proprietary schema as the consumption layer |
| Success metric | **Cost per business unit** (unit economics) | Absolute cost **only** for treasury and commitment, never to evaluate engineering |
| Allocation | **Account/subscription/project** as the primary boundary + tags as a secondary dimension | Tags only if the hierarchy cannot be touched — accepting the leakage that implies |
| Tag governance | **Gate in IaC (mandatory) + admission gate (Kubernetes)**; policy declared as code | Corrective sweep afterwards **only** as a transition with an end date |
| Split model | **Showback** by default | **Chargeback** only with a real per-team budget and the ability to act (§6.5) |
| Kubernetes cost | **OpenCost** (Apache-2.0, CNCF *Incubating*) | **IBM Kubecost** if long retention or commercial support is needed (§2.1) |
| Cost before deployment | **Infracost** in the PR (`infracost breakdown` / `infracost diff`) | Your own calculation over the provider's pricing API if Infracost does not cover the resource |
| Anomalies | Provider-native detection + **one actionable alert with an owner**, not an email to a list | Your own detection over the FOCUS export in the warehouse, if a business dimension is needed |

### 2.1 Tool status and licence (verified raw)

| Tool | Licence (read from the `LICENSE`) | Status / ownership | Pricing model |
|---|---|---|---|
| **OpenCost** | **Apache-2.0** (`opencost/opencost`) | **CNCF**: accepted on 17 Jun 2022, **Incubating since 25 Oct 2024**. Maintained by IBM Kubecost, Randoli and the community | Free; you pay for the infrastructure that sustains it (Prometheus/storage) |
| **Kubecost** | Proprietary product (the open core is OpenCost) | **Acquired by IBM** (announcement of **17 Sep 2024**), integrated into IBM's FinOps suite alongside Cloudability and Turbonomic; its website redirects to `apptio.com` | **Foundations "Always free"** tier: *"Unlimited clusters up to 250 cores"*, *"15-day metric retention"*. **Enterprise Self-hosted and Enterprise Cloud: price not published** — you have to ask |
| **Infracost** | **Apache-2.0** (`infracost/infracost` and the new `infracost/cli`) | Alive; code refactored into separate repos (`infracost/cli` is now the core) | **Free: 1,000 runs/month** · **Starter: $250/mo, 10,000 runs** · **Cloud: $1,000/mo** · **Enterprise: on request**. The hosted pricing API is a service **separate from the code**: it can be self-hosted (`INFRACOST_PRICING_API_ENDPOINT`) to bypass the limit |

**The licence trap, the one most often missed**: the CLI being Apache-2.0 does **not** make the
service free. Infracost is the canonical case: permissive code, **hosted pricing API with a quota**.
The purchasing decision is taken on the service, not on the `LICENSE`. Before pinning any of these
three as a project default: **read its raw `LICENSE` and its pricing page on the same day** (§8).

### 2.2 The FinOps framework, 2026 edition (verified)

Current definition, **verbatim** from `finops.org`: *"FinOps is an operational framework and cultural
practice which maximizes the business value of technology, enables timely data-driven decision
making, and creates financial accountability through collaboration between engineering, finance,
and business teams."* (published on **19 Mar 2026**).

- **Phases** (verbatim): `Inform` · `Optimize` · `Operate`. Maturity, verbatim: *"A FinOps approach of
  'Crawl, Walk, Run' enables organizations to start small, and grow in scale, scope, and
  complexity."*
- **4 domains and 22 capabilities** (verbatim from the framework page):
  - **Understand Usage & Cost**: Data Ingestion · Allocation · Reporting & Analytics · Anomaly Management
  - **Quantify Business Value**: Planning & Estimating · Forecasting · Budgeting · KPIs & Benchmarking · **Unit Economics**
  - **Optimize Usage & Cost**: Architecting & Workload Placement · Usage Optimization · Rate Optimization · Licensing & SaaS · Sustainability
  - **Manage the FinOps Practice**: **Executive Strategy Alignment** · FinOps Practice Operations · Governance, Policy & Risk · FinOps Education & Enablement · Invoicing & Chargeback · FinOps Assessment · Automation, Tools & Services · Intersecting Disciplines
- **Changes in the 2026 edition** (this one has genuinely been reviewed and extended, do not assume the previous edition):
  **`Executive Strategy Alignment` is a new capability** in `Manage the FinOps Practice`; the
  **Scopes** construct is deepened with more *Technology Category pages*; convergence with adjacent
  disciplines is added; and the definition is updated. The rename from
  *"Optimize Cloud Usage and Cost"* to **"Optimize Usage & Cost"** comes from the **2025** edition,
  which was the one that introduced **Scopes** as an element of the framework.
- **Scope**, verbatim: *"A FinOps Scope is a defined segment of technology-related spending –
  aligned to business constructs such as products, cost centers, or environments."* The operational
  consequence: **the framework is no longer only about public cloud** — SaaS, licences, data centre and **AI**
  are technology categories in their own right.
- **The FinOps Foundation is a Linux Foundation programme** and updated its mission, verbatim:
  *"from 'Advancing the People who manage the value of Cloud' to 'Advancing the People who manage
  the Value of Technology.'"*

**Do not use the framework as an org chart template.** It is a common vocabulary so that engineering,
finance and business say the same thing with the same words, and a capability map for spotting
gaps. Setting up a committee per capability is the usual way to fail with it.

## 3. Structure and conventions

### 3.1 Unit economics is the only indicator that matters

Hard rule: **every system with material cost declares a unit economic before any optimisation action
is approved for it.** With no denominator there is no optimisation, there is cutting.

```
unidad_económica = coste_asignado_del_sistema / unidad_de_valor_del_sistema
```

The unit of value is set by the product owner, not by engineering, and there is **one** per system:
cost per **transaction**, per **active user (DAU/MAU)**, per **request served**, per **GB
processed**, per **order**, per **document indexed**, per **token** or **per use case
resolved** in AI.

**Why absolute total spend is a misleading metric in a growing system**: a service that goes
from €100,000 to €130,000 a month while tripling its traffic has **improved its efficiency by 57 %**,
and in the report it shows up as a +30 % deviation. The practical consequence is worse than the
statistics: penalising the absolute **rewards not growing** and punishes the team that absorbed
demand. And conversely: a flat total with falling traffic is a silent deterioration.
Corollary: **a budget alert on an absolute value is not an efficiency alert**; it serves treasury
and the spend ceiling, not the evaluation of engineering.

Rules for the metric:
- It is published **next to the business metric that denominates it**, on the same dashboard. A cost
  figure without its denominator visible is not published.
- It is compared **against itself over time**, not against another team nor against a provider
  *benchmark*. A valid target is written as *"cost per order ≤ €X by date Y"*, not as
  *"cut spend by 20 %"*.
- It is recalculated when the denominator changes (a change in the definition of "active user") and the
  change is annotated on the series: a time series with the definition changed halfway through **is a lie**.
- A system with no identifiable unit of value (internal tool, platform) uses **cost per team
  served** or **cost per service deployed** — but it declares one.

### 3.2 Allocation: tags, hierarchy and shared cost

**A tag policy with no gate enforcing it does not exist.** It is the central rule of this
section: the naming document that nobody can mechanically breach produces, six
months later, a fraction of non-allocatable spend that grows on its own. Therefore:

1. **Policy declared as code**, not in a wiki. Minimum mandatory set, with closed-domain values
   wherever possible:

   | Key | Mandatory | Values | What it decides |
   |---|---|---|---|
   | `owner` | Yes | Team identifier from the directory, **not** a personal email | Who gets asked and who switches it off |
   | `cost-center` | Yes | Closed list from finance | Accounting split |
   | `service` | Yes | Name from the service catalogue | Joining cost with unit economics |
   | `environment` | Yes | `prod` / `staging` / `dev` / `sandbox` | Non-production sweep (§3.5) |
   | `data-classification` | Yes if there is data | Classes from `grc-compliance-standards` | Cost/retention cross-check |
   | `expires` | Yes in `sandbox` and ephemeral | ISO-8601 date | Automatic shutdown |

2. **Gate 1 — IaC**: the resource is not created without the mandatory keys. The *tool* (policy
   as code in the plan, modules with default tags, provider *default tags*) is
   decided by `iac-standards`; **the list of keys and their valid values is decided by this skill.**
3. **Gate 2 — admission**: in Kubernetes, an object without the mandatory labels is rejected in the
   *admission controller* (implementation: `platform-engineering-standards`).
4. **Gate 3 — detection**: weekly report of non-taggable spend, with a **hard threshold**: if
   non-allocatable spend exceeds **5 % of the total**, allocation is not reliable and **no split
   decisions are taken** until it is fixed. That 5 % is a governance threshold proposed here, **not an
   empirical industry figure**: adjust it to the size of the account, but set one and write it down.

**Known limit of tagging, non-negotiable**: there are costs that **carry no tag** by
construction (support, platform fees, inter-zone traffic, services with no resource dimension,
organisation-level commitment discounts). That is why:

**The hierarchy of accounts/subscriptions/projects is the primary allocation boundary, and tags the
secondary dimension.** Reason: the account boundary enforces itself, does not depend on
someone writing it correctly and survives resources that do not accept tags. Design rule:
**one account/project per (team × environment)** as the default grain; group further only with written
justification, because every grouping turns direct cost into shared cost.

**Shared cost and how it is split.** Categories: platform (cluster, mesh, CI), observability,
network and Internet egress, security, licences, support and commitment discounts. Default method,
in this order:
1. **Real consumption metric** if it exists and is cheap to obtain (CPU·hour and GiB·hour reserved in
   Kubernetes; GB ingested in logs; requests on the internal API).
2. **Proportional to the consumer's direct cost**, if there is no metric.
3. **Fixed split per head/team** only for the irreducible (support, corporate licences).

**Why a perfect split is not worth it**: the split has an engineering cost and a
political cost that grow much faster than its precision. Operational criterion: **the split model
is refined only while a change in the split could change a decision.** If going from 90 % to 97 %
precision makes no team act differently, the work is pure accounting theatre —
declare it `unallocated`, split it simply and in a documented way, and put that effort into
unit economics. A **stable and understandable** split model is worth more than an exact one that nobody
understands nor can challenge.

### 3.3 FOCUS: normalise before analysing

FOCUS (*FinOps Open Cost and Usage Specification*) is **the most actionable piece of the domain** and
the only point where an open standard replaces N proprietary schemas. Verified status:
**version 1.4, ratified by the FOCUS Steering Committee on 4 Jun 2026**; earlier versions
1.3, 1.2 (29 May 2025), 1.1 (7 Nov 2024), 1.0.

Criteria: **the consumption layer (dashboards, alerts, unit economics, splits) is built against
FOCUS columns, not against the provider's proprietary schema.** The native export is ingested as is
and transformed into FOCUS in the modelling layer; nobody writes a business query against
a column name that only exists in one provider. The real and verifiable benefit: the same
query answers across all three clouds and a migration does not rewrite the dashboards.

Columns you have to be able to tell apart (exact names from the specification):

| Column | What it is | When it is used |
|---|---|---|
| `ListCost` | List price before discounts | Measuring the discount achieved; **never** for allocation |
| `ContractedCost` | Price after **negotiated** discounts | Negotiation with the provider |
| `BilledCost` | **Cash** view: what the issuer billed | Reconciliation with finance and treasury |
| `EffectiveCost` | Cost **recognised on consumption** (amortises commitments) | **The only valid one for unit economics and allocation** |

Derived rule, the one most often broken: **using `BilledCost` for unit economics produces
false steps** — the month a reservation is bought efficiency collapses and the next one
looks miraculous. Unit economics and *showback* always go with `EffectiveCost`; accounting
reconciliation, with `BilledCost`.

Other decision columns: `ChargeCategory` (`Usage`/`Purchase`/`Tax`/`Credits`/`Adjustments`) to
separate consumption from purchase; `ChargeClass` to isolate corrections; `CommitmentDiscountId`,
`CommitmentDiscountType` and `CommitmentDiscountStatus` to measure coverage and utilisation (§3.4);
`SkuId`, `ConsumedQuantity`, `ConsumedUnit`, `PricingQuantity`, `PricingUnit`; `ServiceCategory`;
`Tags`; `InvoiceId`.

Changes in 1.3 and 1.4 that shift criteria:
- **1.3** (ratified on **4 Dec 2025**) added the columns for **explicit shared-cost
  allocation** — `AllocatedResourceId`, `AllocatedResourceName`, `AllocatedMethodId`,
  `AllocatedMethodDetails` — and the **Contract Commitment** *dataset*, plus data recency and
  completeness markers. Direct consequence: **the split method stops being a secret in a
  spreadsheet and starts travelling with the data**; demand it from your generators.
- **1.4** adds the **Invoice Detail** and **Billing Period** *datasets* and ~17 commitment columns,
  so that reconciliation with accounts payable is done **against the same data** that
  engineering uses. The four *datasets* of 1.4: `Cost and Usage` (mandatory), `Billing Period`,
  `Contract Commitment` and `Invoice Detail`.
- **Declared discrepancy**: on the ratification date of 1.3, the specification page
  gives **4 Dec 2025** and there are secondary sources saying 5 Dec 2025, with the public announcement on
  11 Dec 2025. The specification's date is used; if it matters contractually, verify it in the
  repository changelog.
- **Uneven coverage**: per-provider adoption lags the specification (there are
  general-availability announcements for **1.2** coexisting with the publication of 1.3/1.4).
  **Never assume your provider emits the latest version**: check it before designing the model.
  There is also a **conformance certification** programme for data generators announced
  for 2026: verify its status before demanding it by contract (§8).

### 3.4 Commitments and discounts

Reserved instances, savings plans, committed-use discounts and their equivalents in
other providers. **Committing is a bet on the future architecture**, it is not an
optimisation: flexibility is traded for a discount, and whoever signs accepts the risk that the
system being committed to stops existing before the commitment does.

Decision criteria, in order:
1. **First right-size, then commit.** Committing over an oversized fleet
   buys the mistake for three years. Reversing the order is forbidden.
2. **Target coverage over the stable floor of consumption**, never over the peak nor over the average.
   The floor is computed with the low percentile of daily consumption over the last few months, and **the
   coverage target is written as the team's own decision, with its window and its percentile**. No
   universal percentage is set here: whoever gives you an "80 % coverage" as an industry truth
   is not looking at your load profile. What is a rule: **coverage is decided on a documented
   historical series, not on intuition**.
3. **Two mandatory metrics, and they are different**: **coverage** (what fraction of eligible consumption
   is under commitment) and **utilisation** (what fraction of the purchased commitment is being used).
   High coverage with low utilisation is burned money; 100 % utilisation with low coverage is
   an unexploited discount. Both come out of `CommitmentDiscountId`/`Status` in FOCUS.
4. **The term is chosen by the expected life of the architecture, not by the discount.** Falsifiable
   rule: **if the team cannot write down why that service will still exist in that shape
   at the end of the term, the term is too long.**
5. **Prefer the most fungible commitment** (the one covering broad families/regions/services) over
   the most specific one, unless the discount difference is quantified and consumption is
   rigid and demonstrated.
6. **Owner and review date**: every commitment has a named accountable person and a review before
   expiry. A commitment renewed out of pure inertia is a mistake that doubles.
7. **Secondary market and cancellation**: before signing, verify whether the specific commitment can
   be sold, exchanged or cancelled and with what penalty — **that is decided by the corresponding
   cloud skill**, but **do not sign without having looked**.

### 3.5 The levers, in order of real impact

The order matters because the effort is almost always spent in the wrong place. From highest to lowest
return per engineering hour:

1. **Switch off what is not used.** It is the only one that gives 100 % savings on the resource and has no
   architectural risk. Targets: non-production environments outside working hours, orphaned resources
   (unattached volumes, old snapshots, reserved public IPs with no use, load balancers with no
   targets, addresses and NAT with no traffic), expired *sandboxes* (`expires`), test clusters,
   data in hot classes that nobody reads, and **whole services that nobody calls any more** — cross
   cost with observed traffic, not with the team's opinion.
2. **Right-size.** Adjust to observed demand (not to requested demand), autoscaling, scale to zero
   where the model allows it. Controlled risk: margin is traded for cost, and that margin **is
   reliability** → coordinated with `sre-practice-standards`.
3. **Choose the right pricing model.** On demand / spot capacity (*spot*) / committed,
   storage classes and lifecycle, included licence versus your own. It is the lever with the
   best effort/savings ratio **once 1 and 2 are done**, and the one that goes worst if done
   earlier (§3.4, rule 1).
4. **Architecture.** Change the pattern: eliminate data shuffling between zones, replace polling
   with events, move compute next to the data, replace an expensive managed service with a cheaper
   one at the same SLO, change the format or the compression.

**Why architectural optimisation arrives late if it was not thought about at design time**: when the system
is in production with customers, changing the pattern means data migration, coexistence,
client rewrites and a risk window — months of work whose savings are compared against
switching off idle resources in an afternoon. The cost of an architecture **is fixed at the design
review**, and that is where the estimate has to go. Hence the gate in §4.2: **the cost
estimate is a design deliverable, not one from the invoice post-mortem.**

### 3.6 The hidden-cost catalogue

What shows up on the invoice and nobody planned for. It is reviewed **in full** at every design review:

| Category | Why it surprises | What to do |
|---|---|---|
| **Data transfer and egress** | It is not visible in the design: it is the consequence of where you put things. Includes Internet egress, **between availability zones** and inter-region | Draw the data flow with volumes **before** building; count it as its own budget line |
| **Object storage requests** | The GB stored is budgeted and the number of operations is billed. A pattern of many small files can cost more in requests than in storage | Measure operations/month, not just GB; see `object-storage-standards` |
| **Public IPs, load balancers and NAT** | They cost by existing, not by being used; they are left behind after deleting what they served | Periodic inventory of resources with no target and no traffic |
| **Logs, metrics, traces and APM** | **Telemetry can cost more than what it observes.** Cost grows with cardinality and with retention, and both grow on their own if nobody governs them | Explicit observability budget as a percentage of the observed system; retention per data class; trace sampling; label cardinality control. See `observability-standards` |
| **Forgotten non-production** | No customer complains about an expensive `staging`; nobody looks at it | Scheduled shutdown by default, mandatory `expires` in `sandbox`, and **non-production cost as a separately reported metric** |
| **Data that only grows** | With no retention policy, storage is a perpetual liability | Lifecycle and retention decided with `grc-compliance-standards` (legal obligation) and `data-platform-standards` |
| **AI inference** | New category (§3.7) | See below |
| **SaaS and licences** | Off the cloud team's radar; the 2026 framework brings them in | Inventory, active seats versus purchased ones, renewal date with an owner |
| **Support and platform fees** | A percentage of spend: they grow automatically with everything else | Account for them as shared and split them (§3.2) |
| **Provider exit egress** | An economic impediment to migrating | **Legal framework in the EU**: EU Data Act, Art. 29(1), verbatim: *"From 12 January 2027, providers of data processing services shall not impose any switching charges on the customer for the switching process."* Art. 29(2): in the period *"From 11 January 2024 to 12 January 2027"* reduced charges may be imposed, which per 29(3) *"shall not exceed the costs incurred by the provider ... that are directly linked to the switching process"*. Egress charges fall within the definition of *switching charges*. **Consequence**: do not automatically renew contracts with migration clauses predating that date; review before expiry |

### 3.7 The cost of AI inference

A new category and already a first-order one: the framework treats it as its own **Technology Category
(*FinOps for AI*)** within Scopes, and the annual survey places it as the future priority declared by
practitioners (§6.6, with its methodology caveat).

Criteria:
- **Mandatory unit economics, and a business one, not a technical one.** **Cost per token** works as a
  normalising metric between models —the framework's guidance defines it as
  `Cost Per Token = Total Cost / Number of Tokens Used`— but **it is not the decision metric**: the
  decision metric is **cost per use case resolved** (query answered, document summarised,
  ticket closed). Cost per token can fall while cost per resolved case rises, because
  the system retries more or reasons for longer. If you only measure tokens, you do not see that.
- **Break the token down**: input versus output, **cached versus uncached**, and per model.
  They are different prices and different levers; aggregating them hides the only cheap optimisation
  that exists (prompt caching and choosing the model per task).
- **Measure retries and errors**: a failure that is retried is paid for twice and produces no value.
  Retry cost as its own line.
- **Separate training/fine-tuning (batch, schedulable, suitable for spot capacity) from inference
  (interactive, with an SLO)**. They are opposite purchasing profiles.
- **Dedicated GPU versus per-token API**: the break-even point depends on the real utilisation of
  the GPU, and the GPU is paid for whether it is busy or not. **Sizing, sharing and measuring
  GPU utilisation belong to `gpu-computing-standards`**; here only the rule: **no GPU is bought or
  reserved without a measured utilisation series**.
- **FOCUS already covers it with no special columns**: generators express AI consumption with
  a per-token charge `SkuId` and `ConsumedUnit`/`ConsumedQuantity` in tokens. Do not invent a parallel
  schema.
- See `llm-app-engineering-standards`, `rag-standards` and `local-inference-standards` for the
  technical levers (cache, model routing, quantisation); here only their accounting.

## 4. Quality and gates

### 4.1 The gates, in increasing order of cost

| # | Gate | When | Breaks |
|---|---|---|---|
| 1 | **Mandatory tags present and with a valid domain value** | IaC validation in the PR | Yes |
| 2 | **Mandatory labels on admission** (Kubernetes) | *Admission controller* | Yes |
| 3 | **Cost estimate of the change in the PR** (`infracost diff` or equivalent) | PR | **Informational comment by default**; breaks if it exceeds the repo threshold (§4.2) |
| 4 | **Budget/threshold per account or project** with an alert to a named owner | Continuous | Notifies; does **not** break deployments |
| 5 | **Anomaly detection** with an owner and a runbook | Daily | Opens an incident |
| 6 | **Sweep of orphaned resources and expired `expires`** | Weekly | Switches off in non-production; opens a ticket in production |
| 7 | **Review of commitment coverage/utilisation** | Monthly | Documented decision |
| 8 | **Review of unit economics per system** | Monthly, with the product owner | Action or written justification |

### 4.2 The cost gate in the PR: how to do it right

- **Start by informing, not blocking.** A gate that blocks from day one with estimates that
  the team does not understand gets switched off in two weeks. Sequence: comment → high threshold that breaks →
  adjusted threshold.
- **The threshold is on the estimated monthly delta, not on the total**, and the repository sets it.
  Write it in the repo; do not inherit it from a tool default.
- **Estimate ≠ invoice.** The estimate does not know the usage (requests, egress, scaling). It is
  compared with reality at least once a quarter on the large systems; if the deviation
  is systematic, the model is fixed or the number stops being used to decide.
- **An architectural change with cost impact is not approved without an estimated figure in the
  PR description or in the ADR.** It is the gate that saves the most and the only one that acts in time (§3.5).

### 4.3 How to prove the cost data is correct

Covering the happy path **and the edges**, because a broken cost model is worse than not having one: it gives
false confidence.
- **Reconciliation**: the sum of `BilledCost` for the period matches the provider's invoice, with
  a declared tolerance. Without this, everything else is decorative.
- **Allocation closure**: `Σ (allocated cost) + unallocated = total`, and `unallocated ≤` threshold
  (§3.2). Automated test, not visual review.
- **Edges that must be tested explicitly**: credits and promotional discounts (`ChargeCategory
  = Credits`) that mask the real cost; retroactive corrections (`ChargeClass`) that rewrite
  closed months; currency change; 28/31-day months compared without normalising; one-off
  purchases (`ChargeCategory = Purchase`) contaminating the consumption series; resources created and
  destroyed within the same period; taxes.
- **Test of the series itself**: a dashboard that changes shape when the definition of the
  unit economic changes and does not annotate it **is broken**. Annotating definition changes is mandatory.

## 5. Security and governance of cost data

- **Billing data is sensitive business information**: it reveals volume, customers,
  growth and architecture. It is classified at least as internal, with role-based access control and
  query auditing. A cost dashboard open to the whole organisation is a decision, not an
  oversight.
- **Credentials for cost tools: read-only, always.** OpenCost/Kubecost/third-party agents
  do not need write permissions. A FinOps agent with shutdown permission is a
  denial-of-service switch with access to the whole account.
- **Automation that switches resources off is a destructive action**: non-production environments
  only, an explicit exclusion list, prior notice to the owner, and **never deletion** — switch-off or
  a reversible class change. Deletion is authorised by a person.
- **Third-party FinOps SaaS**: it receives the full billing export, which is a map of your
  infrastructure. Vendor due diligence, least privilege, encryption and a documented contract exit
  before signing (`grc-compliance-standards`).
- **Cost optimisation cannot degrade security or compliance controls without a
  recorded decision**: audit log retention, backups, encryption, high
  availability and multi-region **are not fat**. If a cost action touches one of these, it goes to an
  ADR and is signed by whoever is accountable for the risk, not by whoever is accountable for the budget.
- **Fraud and abuse**: a cost spike can be a security incident (mining after a
  credential compromise, mass exfiltration that drives up egress). **The cost anomaly
  alert is also routed to security**, not only to finance — it is one of the fastest and
  cheapest detectors that exist (`incident-response-forensics-standards`).

## 6. Operation: forecasting, budgeting and splits

### 6.1 Anomalies

- An anomaly alert **with no named owner and no runbook is not created**. An email to a distribution
  list is noise with an attention cost.
- Detection is done on **the series at the granularity at which someone can act** (per
  service and account), not on the organisation total: in the total, everything cancels out and nothing
  is visible.
- **Double threshold mandatory**: relative (deviation from expected) **and** absolute minimum. Without
  the absolute, a €3 resource that doubles generates the same alert as a €30,000 one.
- Every anomaly is closed with a **cause** (code change, traffic change, provider price
  change, error, security incident), not with "resolved".

### 6.2 Forecast versus commitment

They are two different things and confusing them is the expensive mistake: the **forecast** is an estimate with
uncertainty that serves for planning; the **commitment** is a signed contractual obligation
(§3.4). **You do not sign a commitment with the central scenario of a forecast, you sign with its conservative
floor.** The forecast is published with its interval and with its assumptions written down (traffic
growth, planned launches, known price changes); a forecast with no written assumptions
is not auditable and is useless for negotiating.

### 6.3 Budget

- The budget is set on the **allocation unit that has an owner** (account/project/team),
  not on fragile tags.
- Tiered thresholds with **a different action at each one** (notice to the owner → review with finance →
  freeze on creating new resources in non-production). A threshold with no associated action is
  decoration.
- It is **FORBIDDEN** for an exceeded budget to stop production deployments automatically: that
  turns an accounting deviation into an availability incident. It also applies to the **admission
  quota** implemented by `platform-engineering-standards`: it can hold back new resources and
  ephemeral environments, **not the rollout of a service already in production**.
- **Renegotiating an SLO downwards because it does not fit the budget is a legitimate and
  ruled decision, not a silent cut.** Procedure, agreed with `sre-practice-standards`:
  this skill supplies the cost per nine —what the redundancy, the multi-zone or the
  retention that sustain the target cost—; **only whoever is accountable for the SLO changes the target**, by
  signed ADR, with the user impact declared and communicated to whoever depends on the service.
  Without that ADR there is no renegotiation: there is a cut that will be discovered in the next outage.

### 6.4 Cost and sustainability

**They correlate but are not the same metric** and treating them as one leads to false decisions:
switching off idle resources improves both; moving a workload to a cheaper region **can worsen**
the footprint if that region has a worse energy mix, and vice versa. Rule: if a decision is
justified by sustainability, it is measured with its own metric and the effect on cost is declared, and
vice versa. **The criteria for footprint, emission factors and methodology belong to
`green-it-standards`**; here only the warning not to use cost as a proxy for the footprint.
The FinOps framework does have `Sustainability` as a capability of the `Optimize Usage & Cost` domain: use it
as a point of contact, not as a source of calculation methodology.

### 6.5 Showback versus chargeback

| | Showback | Chargeback |
|---|---|---|
| What it is | The team is shown its cost; **no money moves** | The cost is charged to the team's budget |
| **Default** | **Yes** | No |
| When | Always, from day one | Only if **all three** hold: (a) reliable allocation (§3.2, unallocated threshold met), (b) the team has its own budget and real decision-making power, (c) the team **can act** on what is charged to it |
| Risk | That nobody looks | That it gets optimised against the metric and not against the business: refusing useful work, avoiding redundancy, arguing about the split instead of reducing consumption |

**Hard rule**: charging a team a cost it has no control over (a platform
decision, a shared service it did not choose) **is not chargeback, it is a tax** — it generates
accounting disputes and zero savings. If the three conditions are not met, it stays at *showback*.

### 6.6 Practice metrics

The practice is measured by what changes decisions:
- **Allocation coverage** (% of spend with an identifiable owner) — the enabler of everything else.
- **Declared unit economics** over systems with material spend (%).
- **Trend of each unit economic**, per system.
- **Time from the anomaly to its identified cause.**
- **Commitment coverage and utilisation** (§3.4).
- **Non-production cost** as a fraction of the total.
- **Forecast deviation** versus actuals, and whether that deviation is shrinking.

**Forbidden** to measure the practice by **cumulative absolute savings**: it is the metric that can be
invented (it is enough to inflate the reference price it is compared against), it does not distinguish real
savings from avoided growth, and it rewards one-off cutting over sustained efficiency. If savings
must be reported, they are reported **with the baseline, the date and the calculation method written down**, and
their expiry is marked.

**On industry figures — methodological warning.** The *State of FinOps* from the FinOps
Foundation (**2026** edition, published on **19 Feb 2026**) is the most cited public source:
**1,192 respondents**, and headlines such as *"98% are managing AI spend"* (versus 31 % two years
earlier), *"Nine of 10 practitioners are now being asked to manage SaaS"*, *"64% manage licensing"* and
*"48% manage data centers"*, over organisations representing more than $83bn of annual cloud
spend. **It is a self-selected survey among practitioners already affiliated with the community**, and the
public site **does not document the field date range, the sampling frame nor the cleaning or
deduplication criteria**; furthermore an alternative figure of 966 "deduplicated" responses circulates in
third-party analyses — **declared discrepancy**. Use it as **a signal of where the practice is heading, never
as the basis of a business case nor as a comparative *benchmark*.** Any savings figure published
by a tool vendor (of the "30-50 % savings" kind) **is discarded**: with no baseline,
sample or method, it is not data.

## 7. Sustainability and prohibitions

- **Cadence**: review the edition of the **FinOps Framework** and the version of **FOCUS** at least
  **annually** (both have moved in the last twelve months); review the status, the licence and
  the price of the tools in §2.1 **before every renewal** and on any change of
  ownership.
- **Deprecation**: a cost dashboard nobody has opened in a quarter is retired. A report that
  has not changed any decision in two quarters is retired. The FinOps practice accumulates
  dead artifacts faster than any other.

Prohibitions:

- ❌ **Cutting cost by breaking reliability with no explicit decision.** Reducing redundancy, backup
  retention, multi-zone, reserve capacity or observability coverage **requires an ADR signed by
  whoever is accountable for the SLO** and declared consumption of the *error budget* (`sre-practice-standards`).
  Savings paid for with an outage were not savings.
- ❌ **Optimising with no unit economics.** With no denominator you cannot know whether the system improved; you
  are cutting blind.
- ❌ **Committing to 3 years over a 6-month architecture.** And in general: signing a term that
  the team cannot justify in writing (§3.4, rule 4).
- ❌ **Measuring success in absolute savings** (§6.6), or comparing total spend month over month without
  normalising by the business unit or by the days in the period.
- ❌ **A tag policy with no gate.** Publishing the convention and trusting discipline. If there is no
  gate in IaC and in admission, the policy does not exist.
- ❌ **Using `BilledCost` for unit economics or allocation** (§3.3): it produces false steps.
- ❌ **Building the analysis layer against the provider's proprietary schema** when FOCUS is available.
- ❌ **Chargeback without the three conditions in §6.5.** Charging uncontrollable cost is a tax.
- ❌ **Automation that deletes resources** on cost grounds. Switching off and downgrading yes; deleting is
  authorised by a person.
- ❌ **Granting write permissions to cost tools**, your own or third-party.
- ❌ **Chasing the perfect split of shared cost** when no alternative split changes
  a decision (§3.2).
- ❌ **Stopping production deployments automatically** on an exceeded budget (§6.3).
- ❌ **Presenting a savings figure with no baseline, date and method**, or citing a vendor's savings
  percentage as data (§6.6).
- ❌ **Duplicating here the cost criteria of a specific service** that already live in `aws-standards`,
  `azure-standards` or `gcp-standards`: two sources of truth about the same price guarantee that
  one is stale.
- ❌ **Using cost as a proxy for the carbon footprint** (§6.4).

## 8. Mandatory web verification

Before committing anything from this document in a real project:

1. **FinOps Framework**: current edition at `finops.org/framework`, the definition of FinOps, the
   number of capabilities and the changes relative to the 2026 edition (March 2026). It has moved in
   2025 and 2026 in consecutive years: **assume it has moved again**.
2. **FOCUS**: current ratified version and its date at `focus.finops.org/focus-specification/`
   (as of Aug 2026: **1.4, ratified on 4 Jun 2026**), the repository changelog, and **which version
   each provider you use actually emits** — they lag. Status of the **conformance
   certification programme** announced for 2026.
3. **Tools in §2.1**: the **raw** `LICENSE` (`raw.githubusercontent.com`, not the label in
   the GitHub interface nor third-party documentation) for OpenCost, Infracost (`infracost/cli`
   **and** `infracost/infracost`), and the **pricing page on the same day**. Check whether any has
   changed licence, changed owner or gone into maintenance. Reminder: **the GitHub releases
   feed is not the source of truth**; cross-check against the project's official website.
4. **Kubecost**: its website redirects to `apptio.com` after the IBM acquisition; **the prices of the paid
   tiers are not published** — you have to ask for them. Verify the current limits of the free
   tier (as of Aug 2026: *"Unlimited clusters up to 250 cores"*, *"15-day metric retention"*).
5. **AI cost**: the framework's `FinOps for AI` technology category page and its metrics
   guidance; per-token prices change with every model version, and **no model price
   is written from memory**. For anything relating to Claude/Anthropic, the canonical source is the skill
   `claude-api`, not this one.
6. **EU Data Act**: confirm the text and the dates of articles 29 and 34 in EUR-Lex (primary
   source) before relying on them contractually, and whether the Commission has adopted delegated
   acts on the monitoring mechanism foreseen in 29(7).
7. **State of FinOps**: current edition and **its published methodology** before citing any
   percentage. With no methodology, the figure is not written down.
8. **Declared gaps in this document** (they were not filled for lack of a source with methodology, not
   from oversight):
   - **There is no numeric commitment coverage target here**: it depends on the load profile and
     no source with a published methodology justifies a universal number (§3.4).
   - **There is no reference percentage here for observability cost as a share of the total** nor for
     non-production cost: no source with a sample and a method was found. Set your own with your
     own historical series and annotate it (§3.6).
   - **The 5 % non-allocatable spend threshold in §3.2 is a governance criterion proposed in this
     document**, not an industry figure: it is marked as such in the text.
   - **Paid Kubecost prices: not published** (point 4).
   - **There are no typical savings figures for any lever**: all the ones in circulation are from vendors
     and without methodology (§6.6).

If the web contradicts this document, **the web wins** — flag the discrepancy.
