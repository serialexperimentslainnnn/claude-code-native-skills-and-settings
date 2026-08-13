---
name: analytics-bi-standards
description: Use when data reaches a human for a decision — deciding whether a dashboard changes any decision at all and retiring dead ones, choosing or operating a BI tool (Power BI and Fabric F-SKU capacity versus Pro/PPU per-user licensing, Tableau Creator/Explorer/Viewer seats, Looker platform fee and LookML, Metabase, Apache Superset, Lightdash, Evidence, Preset), .pbix/.pbip/.twb/.twbx/.lkml/model.lkml/explore.lkml files, dashboard and report design driven by audience and decision, self-service tiers and certified versus exploratory content, extracts and imports versus direct/live query, pre-aggregates, caching and refresh schedules as a cost pattern, report certification, per-report ownership and periodic pruning, row-level and column-level security and whether to enforce it in the warehouse or in the tool, spreadsheet export as a governance leak, scheduled report delivery, data alerts, embedded analytics, and showing data freshness or staleness inside the report itself.
---

# Analytics and BI standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **consumption layer**: reports, dashboards, self-service, distribution and embedded
analytics. Everything that happens between the warehouse and the person who decides.

Triggers: `.pbix`, `.pbit`, `.pbip`, `.twb`, `.twbx`, `.tds`, `.hyper`, `.lkml`,
`model.lkml`, `explore.lkml`, `view.lkml`, `manifest.lkml`, Lightdash `dashboards/*.yml`,
Evidence `pages/*.md` with SQL blocks, `superset_config.py`, `metabase.db`, "dashboard",
"report", "KPI", "drill-down", "extract", "scheduled refresh",
"subscription", "data alert", "embedded analytics", "RLS", "row-level security",
"export to Excel", and the phrases that give away a problem in this layer: **"the two reports give
different numbers"**, "the report takes two minutes to open", "does anyone still look at this?",
"I need it refreshed every 5 minutes", "why is yesterday missing?".

**Not applicable**: see
- `data-warehouse-modeling-standards` (**owner of the metric definition**): **the canonical
  definition of a metric and the semantic layer are theirs**, they live in the repository next to
  the model, versioned and with an owner. **This skill consumes them; it does not define them, does
  not redefine them and does not duplicate them.** Grain, dimensions, SCD and which breakdowns are
  legal, also theirs. If the question is "how is net revenue calculated?" or "why does it come out
  double when summed?", it is theirs.
- `dataviz` (**skill with no `-standards` suffix; the visual design of the chart is theirs, without
  exception**): mark type choice, palette and colour by series, axes, scales, legends, *tooltips*,
  sequential and diverging palettes, stat tiles, *sparklines*, heatmaps and chart accessibility.
  **Read it before writing the first line of chart code.** Here it is decided **whether the
  dashboard should exist, for whom, with what data and who answers for it**; there, **how it is
  drawn**. Do not duplicate a single colour rule.
- `data-governance-quality-standards` (**sister; boundary declared on both sides**): **governance
  decides whether the data is trustworthy and whose it is; BI presents it for deciding.** Dataset
  owner, contract, freshness SLA, classification, catalogue, glossary and data incident are theirs.
  **A dashboard over ownerless data is an incident waiting to happen**: if there is no owner
  upstream, the report is not certified. The governance of **BI itself** (report certification,
  per-report owner, pruning) belongs here, and inherits their ownership and classification rules.
- `data-engineering-standards`: the pipeline that fills the tables, its instrumented freshness and
  its scan cost. Here only the consumption: what the report queries, how much that query costs and
  what is shown when the data has not arrived yet.
- `lakehouse-standards`: table format and technical catalogue; the format's access control is
  theirs. Here where the filter the user sees is **applied**.
- `data-platform-standards` (parent), `privacy-engineering-standards` (**personal data,
  minimisation, retention and erasure; a report that exposes PII to the wrong people is a privacy
  incident, and the policy is theirs**), `grc-compliance-standards` (**framework, risk and audit
  evidence**), `ai-governance-standards` (**governance of AI systems**: an "ask your data"
  assistant embedded in the BI tool **is an AI system and falls into their inventory**, even if the
  data it consumes belongs to this layer).
- `identity-access-management-standards`: **identity, SSO, SCIM and groups are theirs**; here only
  how the identity propagates down to the row filter.
- `observability-standards` (system telemetry), `incident-management-standards` (the incident
  process), `api-design-standards`, `cicd-standards` (deployment of the BI artifact),
  `iac-standards`, `secrets-management-standards`, `mlops-standards`,
  `llm-app-engineering-standards` and `rag-standards` (**the conversational product over data is
  theirs**), `nosql-standards`, `search-engines-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (QuickSight, Fabric/Power BI Service and Looker
  **as managed services**: provisioning, network, IAM and billing are theirs).
- `streaming-cdc-standards`: capture and processing in motion. Here only consumption: **a
  "real-time" dashboard with nobody acting at that latency is spend, not capability**.
- `product-discovery-standards`: **the dashboard, the canonical definition of the metric and its
  governance belong here**; **deciding what gets built from that number is theirs**, as is the
  design of the experiment that moves it. A warning both share: **a metric degrades as soon as it
  becomes a target** — Goodhart's law — and that is why a business metric needs guardrail metrics,
  not just a threshold.
- `r-standards` and `julia-standards`: **replacing a dashboard with a Quarto/R Markdown report or
  with a Shiny app is a decision of this skill** — who consumes it, at what latency, who maintains
  the metric definition and what happens when the author leaves —; **the code of that report or
  that app** — `renv`, structure, tests, deployment and its security — belongs to `r-standards`.
  A warning both share: **a Shiny app in production is a web application**, with its attack surface
  and its operating cost, not a report.
- `timeseries-db-standards`,
  `message-brokers-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`, `caching-cdn-standards`: their engines and their operation.

### The prior question

**Does this dashboard change any decision?** It is the only question that has to be answered before
building anything, and it has to be answered by naming **who** decides **what** and **when**. If
the answer is "for visibility", "because the director asked for it" or "to monitor the business",
there is no decision: there is **maintenance cost disguised as value**. Every published dashboard
is a recurring query that gets paid for, an artifact that breaks when the model changes, an access
surface to audit and a potential source of contradiction with another report.

**Corollary almost nobody applies: the life cycle includes retiring.** No organisation has a
problem of "we are missing dashboards"; they all have a graveyard problem. A mature BI practice is
recognised by what it **deletes**, not by what it publishes. If you have not retired a single
report in the last year, your report catalogue is lying about what the organisation uses.

## 2. Default decisions

> Verify licence, status and **pricing model** on the web before fixing anything (§2.2 is the
> section that changes most and the one that decides the choice) (§8).

### 2.1 Before choosing a tool

| Real need | Simplest solution | When it stops working |
|---|---|---|
| A number somebody looks at once a month | **A report scheduled by email** or a saved query | When it has to be crossed, filtered or compared |
| A table a team consults | **A view or saved query** in the warehouse | When the consumer does not know SQL |
| A handful of charts versioned next to the code | **BI as code** (Evidence, Lightdash) | When the consumer needs to build their own |
| Free exploration of a model by business people | **A full BI tool** | — |
| Analytics inside a product you sell | **Embedded** — it is another product, another price and another security model (§5.4) | — |

No dashboard is free. The cost is not building it: it is keeping it aligned with a model that
changes, for years, while whoever asked for it moves to another role.

### 2.2 Tool choice

**The criterion that decides is the pricing model, not the feature list**, because features
converged years ago and price did not. And there is a second, structural criterion: **the tool is
replaced every few years; the data model outlives all of them.** Hence the most important rule in
the domain: **do not put business logic in the tool.** Every transformation, rule and metric that
lives inside the `.pbix`, the `.twb` or the LookML is work thrown away on migration, and in the
meantime it is a definition nobody outside the tool can audit.

| Tool | Licence (verified Aug 2026) | Pricing model | When it is the answer |
|---|---|---|---|
| **Power BI / Fabric** | Commercial | **Dual**: per user (Pro, Premium Per User) **or per capacity** (Fabric `F` SKUs, billed per second, reservable). The legacy `P` SKUs are being retired towards `F`. **Above a certain capacity level viewers no longer need an individual licence** — that threshold is the economic inflection point of the whole platform | Organisations already on Microsoft 365. **Model the cost with your real author/viewer split before signing**: below the threshold you pay per head, above it you pay fixed capacity |
| **Tableau** | Commercial (Salesforce) | **Per user with roles**: Creator / Explorer / Viewer, billed annually, with Cloud tiers (Standard/Enterprise) that change the price substantially. Server also supports **per-core** licensing | Strong visual culture and many authors. **The cost lever is the role mix**: over-provisioning Creator to people who only consult is the classic waste |
| **Looker** | Commercial (Google) | **High platform fee + users + capacity** (query call and API limits per edition). Price **not public, negotiated**. AI metering announced with billing starting Oct 2026 | When you want a governed modelling layer (LookML) and can pay the entry fee. **Real hidden cost: LookML is an engineering practice with dedicated staff**, not a configuration |
| **Metabase** | **OSS: AGPL-3.0**; the `enterprise/` directory is under the *Metabase Commercial License* (**verified verbatim in `LICENSE.txt`**). Versions `0.x` = OSS, `1.x` = commercial | Free self-hosted OSS; commercial per plan | **Default when the need is "let people answer their own questions" without a project.** Careful with AGPL if you are going to embed it or modify and distribute it |
| **Apache Superset** | **Apache-2.0** (verified verbatim in `LICENSE.txt`), an ASF **top-level project** | Free; the cost is operating it (or paying Preset, the dominant commercial vendor) | When you need a permissive licence and have platform capacity. **Support policy: only two major versions at a time** — an old deployment runs out of patches fast |
| **Lightdash** | **MIT**, except `packages/backend/src/ee` under a commercial licence (**verified verbatim in `LICENSE`**) | Free self-hosted; Cloud per plan **with no seat charge** | BI over dbt with the metric defined upstream. **Fits well with the golden rule** of §2.3 |
| **Evidence** | **MIT** | Free OSS; Cloud/Studio per seat + AI credits | Reports versioned in Git, reviewed by PR, with no drag-and-drop editing. ⚠️ **Verified: the OSS repository records no commits on `main` since Feb 2026** while the effort goes to the commercial "Studio" platform; the team states it will keep developing the open version. **Risk signal to watch, not a disqualification** |

Choice rules:
- **Per-user cost versus per-capacity cost**: the per-user model is predictable and penalises
  spread (each new viewer costs); the capacity one is fixed and penalises underuse (you pay for the
  peak even when nobody looks). **Model both with your real author and viewer split and with your
  3-year growth**; the crossover point is the number that decides, and it is almost never where you
  intuit. If the capacity model "comes out cheaper" only by assuming a number of viewers you do not
  have today, you are buying a forecast, not a tool.
- **Systematic hidden cost**: training, modelling staff (LookML, semantics, DAX), migration of the
  existing reports and **the warehouse compute the tool triggers**, which appears in no price
  comparison and often exceeds the licence.
- **One tool, not three.** Two BI tools in the same organisation guarantee two definitions of the
  same metric. If there are two for historical reasons, there is a convergence plan with a date.
- **Distrust every comparison written by a competitor**: in this segment almost all of them are.

### 2.3 The golden rule: the metric is defined once, upstream

**Business logic does not live in the BI tool.** It lives in the model, versioned, with an owner
and with tests — and that is the remit of `data-warehouse-modeling-standards`, which owns it.

The classic **"two reports, two numbers"** is almost never a data failure: it is a mechanical
consequence of having allowed each report to implement its own version of the rule. It is enough
for two authors to filter cancelled orders differently, or for one to use the order date and the
other the invoice date, for the figures to diverge undetectably and perfectly explicably after the
fact. When this happens three times, the organisation learns that **data is a matter of opinion**,
and that lesson is not unlearned with a *hotfix*.

- **In the tool there can only live**: selecting the already-defined metric, filtering, breaking
  down by dimensions declared legal, and presentation.
- **Forbidden in the tool**: calculations that redefine the metric, joins that replicate the model,
  calculated fields that implement business rules, and cleaning transformations.
- **The migration test**: if changing tools would force you to reimplement business rules, the
  logic was in the wrong place. It is the same argument for why the tool must not be the place:
  **it is the most volatile piece of the stack**.
- **If the tool offers its own semantic layer** (tabular model, LookML, Metabase models), use it as
  a **projection** of the canonical definition, not as its origin. And consume it from a single
  source.

## 3. Dashboard design

**The visual design of the chart belongs to the `dataviz` skill.** Here only what precedes it: for
whom, for what decision and with what structure.

### 3.1 Audience and decision first

Before opening the tool, in writing and in the artifact itself:

1. **Who** is going to look at it (a concrete role, not "management").
2. **What decision** they take with it and **at what cadence** (daily, weekly, quarterly). The
   cadence of the decision determines the refresh cadence, not the other way round (§4.3).
3. **What action** is triggered when the number is wrong. If there is no action, there is no
   dashboard: there is a query.
4. **What data** feeds it and **who owns it** (if there is no owner, it is not certified; see
   `data-governance-quality-standards`).

Three audiences, three different artifacts, and confusing them is the most common design error:

| Audience | Artifact | Rule |
|---|---|---|
| **Management** | Few indicators, comparison against target or previous period, no exploration | If it does not fit on one screen without scrolling, it is not a management dashboard |
| **Operations** | Current state and actionable deviations, with enough detail to act today | It must let you reach the record that is acted upon |
| **Analysis** | Free exploration over a governed model | **It is not a dashboard**: it is an exploration layer. Do not publish it as if it were the same thing |

### 3.2 Structure

- **Descending hierarchy**: the conclusion at the top, the breakdown after, the detail at the end.
  Whoever comes in must know in five seconds whether something is wrong.
- **Mandatory context on every number**: comparison (target, previous period) and unit. A number on
  its own is not information, it is trivia.
- **One dashboard, one topic.** If it needs tabs per area, they are several artifacts with
  different owners.
- **Sensible and visible default filters.** The hidden filter with a preselected value is the
  silent cause of half the discrepancies between two people looking at "the same" report.
- **Every artifact carries visible metadata**: owner, data date (§6), definition or link to the
  definition of the metrics, and certification status.
- **Stable and explicit names.** "Sales report v3 (final) copy" is a governance decision, not an
  aesthetic slip.

## 4. Gates

### 4.1 Publication gates (every certified report)

1. **Declared decision**: audience, decision, cadence and action, written in the artifact. Without
   this it is not published.
2. **A named report owner** (a person, not a team) and an existing, verified upstream data owner.
3. **Zero business logic in the tool**: the review checks that the metrics come from the canonical
   definition and that there are no calculations reimplementing it. **Review gate.**
4. **Reconciliation against the canonical source**: the report's main figure matches the model's,
   with a declared tolerance. A report that does not reconcile the day it is published will never
   reconcile.
5. **Freshness visible in the artifact itself** (§6).
6. **Access reviewed**: who sees it, and if the data is confidential or restricted, that the filter
   is **upstream** (§5.1).
7. **Estimated cost**: query per open × expected opens + scheduled refreshes. If nobody has
   estimated it, it will only be estimated on the invoice.
8. **Explicit status**: `certified` or `not certified`. **There is no intermediate state**, and
   everything not certified must be visible as such in the interface.

### 4.2 Periodic review gates (quarterly)

9. **Usage measured per report.** The tool records it; if it does not, that is a defect of the
   tool.
10. **No use in a quarter → the owner is notified and it is retired** (archive, do not delete). The
    owner's silence is consent to retirement. **Without this gate there is no life cycle, there is
    accumulation.**
11. **Duplicate reports detected and merged**: two reports with the same metric and different
    results is a data incident, not an aesthetic nuisance.
12. **Recertification**: certification **expires**. A report certified two years ago over a model
    that changed is a lie with an official stamp.
13. **Review of access and of scheduled subscriptions** (§5.3).

### 4.3 Performance and cost gates

14. **A declared open-time budget** (rule of thumb: a few seconds on first render). A report that
    takes a minute is not used: it is requested by email from an analyst, which is exactly the work
    the report came to avoid.
15. **The refresh cadence is justified by the cadence of the decision.** **The dashboard that
    refreshes every 5 minutes because somebody ticked a box** is the most widespread and least
    questioned spending pattern in the domain: it multiplies warehouse compute by 288 a day to feed
    nobody. Intraday refresh only with a documented action that happens intraday.
16. **BI queries tagged** (by report or by user) so cost can be attributed. Without attribution, BI
    cost is a black hole in the warehouse invoice.

## 5. Access, security and self-service

### 5.1 Row-level and column-level security: upstream, almost always

**Default rule: the filter is applied in the warehouse, not in the BI tool.** The reason is
architectural, not a preference: the rule that lives in the tool **only protects the path that goes
through that tool**, and today there are many more paths — a notebook, a direct query, a second BI
tool, an integration, an agent that generates SQL. The further the rule is from the data, the more
services have to be trustworthy for it to hold.

- **Enforcement floor**: the warehouse's native policies (row access policies, column masking,
  authorised views). BI **passes the identity**, it does not decide.
- **Live query (direct query) for sensitive data**, so the policy is applied on every query. **An
  extract materialised in the tool can bypass the warehouse policy entirely** — it is the most
  common design failure and the most silent.
- **Security in the tool is a usability complement**, not a boundary. Use it to narrow what is
  seen, never as the sole control over what can be seen.
- **Define the policies before opening the tool**: if somebody queries the table before the rule
  exists, self-service is born with a hole.
- **Performance**: a row policy with *joins*, text transformations or nested lookups turns every
  query into a planning problem. Precompute the permission assignment table and filter with direct
  predicates over existing columns. The dimension that determines visibility **has to exist in the
  model** (a `data-warehouse-modeling-standards` decision; if it is added later, it is a migration
  of the history).
- **Legitimate and unique exception**: multi-tenancy in embedded analytics where the filter depends
  on the application session — and even then the filter is **pushed to the warehouse** as a
  predicate, it is not resolved only in the presentation layer (§5.4).

### 5.2 Self-service: what gets opened and what does not

Self-service is a **negotiation between democratising and creating a swamp of contradictory
reports**, and it has to be resolved explicitly, not left to drift.

| Layer | Who | What they can do | Guarantee |
|---|---|---|---|
| **Certified** | Everyone | Consume, filter, break down by legal dimensions | **The organisation answers for these numbers** |
| **Exploratory** | Trained analysts | Build on the governed model, publish in their own space | Visibly marked as not certified; **not shared outside the area without certifying** |
| **Free (SQL)** | Technical profiles with permission | Direct query against the warehouse | No guarantee; subject to warehouse security (§5.1) |

- **The model is opened, not the raw tables.** Self-service over the raw layer produces plausible
  and wrong analyses, and nobody detects it.
- **Promotion from exploratory to certified is a process with review**, not a change of folder.
- **Training is not optional**: whoever does not know what a row represents will produce inflated
  figures in complete sincerity. Self-service without training is delegating the error.
- **The alternative to governed self-service is not order: it is the spreadsheet.** If governed
  access is inconvenient, people will export. That is why the balance is resolved by making the
  right thing convenient, not by forbidding the wrong one.

### 5.3 Spreadsheet export: where governance evaporates

The moment a user exports to CSV or Excel, **everything is lost at once**: row security,
classification, freshness, the metric definition, lineage and the ability to correct. The file is
forwarded, edited, combined with another and comes back into the organisation as "data" three weeks
later, already incorrect and with no traceability. It is, without argument, the biggest governance
leak in the consumption layer.

Realistic posture (forbidding it does not work and pushes people to screenshots and copy-paste):

- **Allowed by default on internal data**; **restricted or disabled** in reports with confidential
  or restricted data (classification belongs to `data-governance-quality-standards` and **travels
  with the copy**).
- **Watermark on the export**: data date, applied filters, source report and an expiry notice. A
  CSV without context is indistinguishable from an invented CSV.
- **Log the exports** of reports with sensitive data, and review the log: massive and repeated
  export is both an exfiltration signal and the symptom that **the report does not give the user
  what they need**. Treat it as an uncovered requirement before treating it as a crime.
- **Scheduled export to a shared directory is an ungoverned data pipeline.** If it exists, it
  becomes a dataset with an owner and a contract, or it is removed.

### 5.4 Distribution and embedded analytics

- **Scheduled reports (subscriptions)**: useful and cheap, but **they expire just like
  dashboards** and nobody ever reviews them. Every subscription has an owner and a review date; the
  one nobody opens is cancelled. A daily email everybody files without reading is not distribution:
  it is noise with a compute cost.
- **Data alerts**: alerts fire on a **threshold with a defined action**, not on an interesting
  variation. Every alert carries **who acts and what they do**. And a rule that is always
  forgotten: **the alert that does not fire because the data did not arrive is a silent false
  negative** — watch freshness as well as the threshold (§6).
- **Embedded analytics**: it is **another product**, with another pricing model (usually per
  capacity or per session, not per seat), another isolation model between customers and another
  level of availability demand. Hard requirements: per-tenant isolation **verified with tests** (not
  trusted to a parameter), the filter pushed to the warehouse, service credentials that **never**
  reach the browser, and per-tenant query limits so one customer cannot degrade the others.
- **A conversational assistant over the data** inside the BI tool **is an AI system**: it enters
  the `ai-governance-standards` inventory, and its output is treated as unreliable (see
  `llm-app-engineering-standards`). Do not certify it as a source.

## 6. Performance, cost and perceived quality

### 6.1 Performance and cost

- **Aggregate upstream, not in the tool.** If a dashboard scans the atomic fact on every open, an
  aggregate is missing from the model. The tool is not the place to fix a modelling problem.
- **Extract/import versus live query** — a conscious decision, with consequences:

| Mode | Advantage | Real cost |
|---|---|---|
| **Live query** | A single place with the truth; **warehouse security is always applied**; no duplication | Latency dependent on the warehouse; every open is paid for; real concurrency against the engine |
| **Extract / import** | Fast and cheap to serve; independent of warehouse load | **Duplicates the data and can bypass access policies** (§5.1); introduces lag; becomes a parallel warehouse with no governance |

Default: **live query over a well-modelled aggregate**; an extract only for non-sensitive data with
a measured performance problem and with freshness declared in the report itself.
- **Cache with a TTL aligned to the data's freshness SLA.** Caching for longer than the freshness
  adds nothing; for less, it wastes compute. And a cache serving an already-corrected datum is a
  covered-up incident: invalidation is part of the fix.
- **Scheduled refreshes overlap and pile up**: dozens of reports refreshing at 08:00 produce the
  peak that makes everything else slow. Stagger them, and review the full list of schedules at
  least once a year — it is full of dead artifacts still consuming.
- **Attribute the cost to the report and publish it with its owner.** It is the only thing that
  turns spend into a decision instead of a complaint.

### 6.2 Perceived quality: when data is missing or arrives late

The user does not distinguish "bad data" from "bad report": for them, **BI has failed**. Trust is
managed here or lost here.

- **Show freshness in the report itself, always and visibly**: "data up to `<date/time>`", not a
  footnote in light grey. The user finding out on their own that yesterday is missing is the worst
  possible outcome.
- **Explicit status when the data has not arrived**: a clear notice of incomplete or delayed data.
  **Never show a chart that drops to zero because the last partition is missing**: the user will
  read a business collapse, will act on it, and you will have turned a delay into a decision
  incident. A declared gap is infinitely better than a false zero.
- **Mark the report as suspect while a data incident lasts** (coordinated with
  `data-governance-quality-standards` §4.3), **at the point of consumption**, not on a channel the
  consumer does not read.
- **Communicating the correction is part of the fix.** If the number changed retroactively, it is
  said. Trust is lost through silence, not through errors.
- **Partial figures for the current period, labelled as such.** The current month compared with
  complete months is the most frequent misleading comparison in all dashboards.

## 7. Long-term sustainability and prohibitions

- **Cadence**: quarterly usage review and pruning (§4.2); annual review of the contracted pricing
  model against real usage (capacity and seat models drift apart fast); and review of the supported
  versions of the self-hosted tool.
- **Mandatory ADR** for: choosing or changing the BI tool, adopting a second BI product, the
  extract-versus-live-query decision on sensitive data, where row security is enforced, and opening
  self-service to a new group.
- **Written exit plan** at contract time: how the definitions are exported, how much work it costs
  to reimplement the reports and what stays trapped. If the answer is "an enormous amount", the
  logic was in the wrong place (§2.3).
- **Versioned BI artifacts** whenever the tool allows it (LookML, Lightdash, Evidence, Power BI
  project formats). A report that only exists inside a web interface has no history, no review and
  no recovery.

**FORBIDDEN**
- ❌ **Building a dashboard without a declared decision, audience and action.**
- ❌ **Defining or redefining a metric inside the BI tool** — the canonical definition belongs to
  `data-warehouse-modeling-standards`.
- ❌ Business logic, cleaning or joins that replicate the model inside the BI artifact.
- ❌ The same metric published with two different values: it is an incident, not a discrepancy.
- ❌ Duplicating chart design rules here: **they belong to `dataviz`**.
- ❌ Publishing a report over a dataset **with no owner** upstream.
- ❌ A report with no named owner, or whose certification never expires.
- ❌ A report catalogue with no pruning: with no measured use in a quarter, it is retired.
- ❌ Ambiguous status: either certified or visibly marked as not certified.
- ❌ **Row-level security implemented only in the BI tool** when the data is confidential or
  restricted.
- ❌ A materialised extract of sensitive data that bypasses the warehouse policies.
- ❌ Service credentials or connection secrets reachable from the client/browser.
- ❌ **Intraday refresh with no documented action that happens intraday.**
- ❌ A report published with no cost estimate and no attribution of its queries.
- ❌ Showing a chart that drops to zero because the last partition is missing.
- ❌ A report with no visible indication of the data date.
- ❌ Comparing a current period with complete periods without labelling it.
- ❌ An alert with no threshold, no action or no owner; an alert blind to data that did not arrive.
- ❌ Scheduled export to a shared directory treated as anything other than an ungoverned pipeline.
- ❌ Free export of reports with confidential or restricted data, or export with no context (date,
  filters, source).
- ❌ Self-service over the raw layer, or without training on what a row represents.
- ❌ Two BI tools in production with no dated convergence plan.
- ❌ Buying a tool without modelling the cost with the real author and viewer split and without an
  exit plan.
- ❌ Fixing licences, versions or pricing models from memory (§8).

## 8. Mandatory web verification

The data in §2 is from **August 2026**, and **the pricing model is what changes most and what
decides the choice**. Before fixing anything in a deliverable, verify:

1. **Power BI / Fabric**: current prices of Pro and Premium Per User, the `F` SKU catalogue, the
   status of the `P` SKU retirement and — the decisive part — **the capacity level above which
   viewers no longer need an individual licence**, on Microsoft's official page, not in
   comparisons.
2. **Tableau**: Creator/Explorer/Viewer prices per edition (Standard/Enterprise), the status of
   Server's per-core licence and what the top tier includes.
3. **Looker**: current platform fees per edition, query call and API limits, and **the AI metering
   whose billing was announced for October 2026** (check whether it came into force and at what
   rates).
4. **OSS**: current licence of **Metabase** (as of August 2026, AGPL-3.0 outside `enterprise/`,
   verified verbatim; `0.x` OSS / `1.x` commercial), **Superset** (Apache-2.0, ASF; **current
   stable version and the two-major support policy**), **Lightdash** (MIT except
   `packages/backend/src/ee`) and **Evidence** (MIT) — and the pricing models of their managed
   versions.
5. **Real activity of the OSS projects** measured in commits and releases, not on the project's
   website. Specifically **Evidence**: whether the open repository has recorded activity on `main`
   again (stopped since Feb 2026) or whether development has moved definitively to the commercial
   platform.
6. **Row/column-level security** in your specific engine (Snowflake, BigQuery, Databricks,
   Fabric, Redshift): syntax, limits, cost of the policy and how the identity propagates from the
   tool.
7. **Supply chain** of any component you deploy (Superset/Metabase images, Evidence/Lightdash
   packages): recent compromises and CVEs. Live precedents in the data ecosystem:
   `elementary-data` (Apr 2026), `trivy` and LiteLLM (Mar 2026), `durabletask` (May 2026).

**Declared gaps of this review** (do not fill from memory):
- **All price figures**: the **models** are verified (per user, per capacity, platform fee, per
  seat + credits); **the specific amounts are not fixed here** because the available sources were
  third-party and competitor comparisons, contradicting each other. Do not cite amounts without the
  vendor's official page.
- **Power BI**: the **exact value of the capacity threshold** that frees viewers from an individual
  licence is not verified in an official source (secondary sources agree that it exists and that it
  is the inflection point, but differ on cost figures).
- **Apache Superset**: **current stable version not verified in an ASF source**. The available
  sources (the commercial vendor's blog) point to a 6.1.0 in May 2026; the repository's tag feed
  only returned Helm chart tags. Verify at `superset.apache.org`.
- **Metabase**: the licence is verified verbatim; **the current plans and prices** of the
  commercial edition **are not verified**.
- **Looker**: the rates are not verified, nor whether the AI metering came into force.
- **Evidence**: MIT verified and the absence of commits on `main` since Feb 2026; **not verified**
  what public commitment exists about the future of the open version.
- **Preset, QuickSight, Sigma, Hex, Omni and Zoho** not evaluated in this review.

If the web contradicts this document, **the web wins** — flag the discrepancy.
