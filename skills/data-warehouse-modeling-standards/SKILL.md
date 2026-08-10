---
name: data-warehouse-modeling-standards
description: Use when deciding the shape of an analytical schema — star schema versus 3NF versus Data Vault (hubs, links, satellites, PIT and bridge tables), bronze/silver/gold or staging/intermediate/marts layering, declaring the grain of a fact table, additive versus semi-additive versus non-additive measures, factless facts, periodic and accumulating snapshots, surrogate versus natural keys, slowly changing dimensions (SCD type 0-7), conformed dimensions across marts, degenerate and junk dimensions, a date/calendar dimension with fiscal periods and business timezone versus UTC, One Big Table denormalization for a serving layer, the single definition of a metric and the semantic layer (MetricFlow, Cube, Apache Ossie/OSI semantic models), proving uniqueness and referential integrity on a model, or migrating a schema whose grain must change.
---

# Data warehouse modelling standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **deciding the shape of the analytical destination**: which tables exist, at what grain, with which
keys, how history is kept, how they are organised into layers and where the definition of a
metric lives.

Triggers: `fct_`/`dim_`/`stg_`/`int_`, `schema.yml`/`semantic_models`/`metrics:`, `hub_`/
`lnk_`/`sat_`, `_sk`/`_key`/`surrogate`, `valid_from`/`valid_to`/`is_current`/`dbt_valid_to`,
`dim_date`/`dim_calendar`, `unique_key`, "star schema", "grano", "grain", "SCD2", "historise",
"conformed dimension", "OBT", "wide table", "marts", "gold layer", "medallion", "metric",
"semantic layer", and the questions that give away a badly declared model: **"why does revenue not
match between these two reports?"**, "how many rows should this table have?", "what does
a row represent here?", "why does the sum come out double?", "we want to see how the customer looked in
March".

**Not applicable**: see
- `data-engineering-standards` (**sibling; boundary declared on both sides**): it **moves and
  transforms** —ingestion, ELT/ETL, orchestration, idempotency, *backfill*, Parquet, scan
  cost, freshness and data observability—; this one **decides the shape of the destination**. Cutting
  rule: if the question is "how do I reload March without duplicating?", it is theirs; if it is "what
  does a row represent and what happens when the customer changes segment?", it belongs here. A pipeline
  without a model produces a swamp; a model without a pipeline is a diagram.
- `data-platform-standards` (**parent**): **PostgreSQL as an operational engine** is theirs, with its
  normalised modelling, its indexes, its migrations and its partitioning. Here the **analytical
  destination** is modelled, which is something else and obeys other rules. Its guiding principle —**a warehouse by
  need, not by fashion**— is inherited: this skill does not authorise a new analytical warehouse; it assumes
  it was already justified. **A `dim_` is not created inside the transactional database.**
- `lakehouse-standards`: the **table format** —Iceberg, Delta, Hudi—,
  file-level schema evolution, hidden partitioning, *time travel* and engine snapshots. A fine and
  deliberate boundary: the table format's *time travel* gives you back **the table
  as it was**; an SCD type 2 tells you **how the business entity was**. They are not substitutes:
  the first is an infrastructure capability for recovery and technical audit, the second
  is a modelling decision that the business queries. **Never replace an SCD2 with *time
  travel*.**
- `analytics-bi-standards`: the BI tool, the dashboards, the
  governance of consumption and the performance of the presentation layer. **Explicit boundary
  decision: the canonical definition of a metric belongs here** (§3.7) —it lives in the repository,
  versioned, next to the model—; BI **consumes it**, it does not define it. A metric defined inside
  a report is a modelling defect, not a tooling choice.
- `data-governance-quality-standards`: catalogue, ownership, business
  glossary, contracts and quality as a programme. Here the **structural tests of the model** (§4).
- `streaming-cdc-standards`: change capture as a mechanism. Here only
  the use it is put to: feeding dimensional historisation.
- `microservices-architecture-standards`: **domain events, outbox and per-service data ownership
  are theirs**. A domain event is not an analytical fact: modelling the fact belongs here.
- `privacy-engineering-standards`: **retention, erasure, minimisation, pseudonymisation and
  personal data classification are theirs**; here they are **executed in the model** —which columns do not
  enter a dimension, how a subject is erased from an SCD2 without destroying the facts, where
  the mapping table lives—.
- `object-storage-standards` (S3 as the substrate), `observability-standards`, `mlops-standards`
  (**feature store and train/serve skew are theirs**; a *features* table is not a mart),
  `rag-standards`, `ai-governance-standards`, `grc-compliance-standards`, `bcdr-standards`,
  `backup-recovery-standards`, `cicd-standards`, `iac-standards`,
  `identity-access-management-standards`, `secrets-management-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (**Redshift, BigQuery, Synapse/Fabric as
  managed services: cost, networking, IAM and provisioning are theirs; the modelling criteria
  on top belong here**), `api-design-standards`.
- Non-analytical engines: `nosql-standards`, `graph-db-standards`, `timeseries-db-standards`,
  `search-engines-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`.
- `sql-standards` (**the SQL language**, including the SQL contained in a dbt/SQLMesh model).
  Boundary mirrored from its §1: *"what does a row represent?"* —grain, facts, dimensions, SCD,
  layers, canonical metric definition— **belongs here**; *"how do I express that SCD2 in SQL without a
  correlated subquery?"* is theirs. **SQL living inside a model does not exempt it from
  the language criteria.**

**Domain thesis — modelling still matters**. The argument that cheap storage
and elastic compute retired modelling confuses the cost that disappeared with the ones that remain.
Disk stopped mattering; **compute, comprehension and trust did not**:

- **Compute**: in modern engines you pay per scan. A table with no declared grain is
  queried badly and paid for every time.
- **Comprehension**: if nobody knows what a row represents, every analyst invents their interpretation and
  all of them are plausible.
- **Trust**: it is the scarce resource. **Two reports that disagree destroy trust in the
  platform faster than an error that is detected and fixed** — an error gets fixed; the
  discrepancy teaches the organisation that data is a matter of opinion.

What has changed is the **implementation**: fewer physical star schemas built by hand, more
tool-managed models and semantic layers on top. The obligations that survive are
the same: **declare the grain, separate fact from dimension, conform dimensions and historise what
changes**.

## 2. Default decisions

> Verify on the web the status of the references, specifications and tools before pinning them
> in a real project (§8).

### 2.1 Choice of paradigm

| Paradigm | When it is the right answer | Real cost | Verdict |
|---|---|---|---|
| **Kimball / dimensional (star)** | **Default.** The destination is queried to answer business questions | Requires declaring the grain and conforming dimensions — intellectual work, not technical | **Adopt this unless there is a written reason** |
| **Inmon / corporate 3NF** | Integration of many systems with complex business rules and a central team that sustains it, feeding dimensional marts downstream | Slow to deliver; incomprehensible for the end consumer: **it is never the consumption layer** | Intermediate layer in large organisations |
| **Data Vault 2.0** (hubs, links, satellites) | Many changing sources **and** a requirement for full auditability: who said what, when and from which system (banking, insurance, regulated sector) | **Table explosion** (of the order of 3× against the equivalent relational model) and unmanageable *joins*; it forces *PIT* and *bridge* tables just to be able to query; and building dimensional marts on top **anyway** | **It solves an audit and integration problem most people do not have.** The adoption data confirms it: adopters themselves cite as the main drawbacks training needs (~48 %), implementation complexity (~35 %) and query performance (~32 %), and only ~31 % say their implementation fully meets the standard. It requires automation and trained staff |
| **One Big Table (OBT)** | **Serving layer**, derived from a model, for a dashboard or a specific case (§3.6) | It is rebuilt in full; it specialises and multiplies | Correct as a destination, **never as the source of truth** |

Rule: **Data Vault without an explicit audit requirement is over-engineering**, and specifically the
worst kind of over-engineering: the kind that imposes a permanent explanation tax on everyone who
joins the team.

### 2.2 Modelling toolchain

| Area | Default | Note (Aug 2026) |
|---|---|---|
| Canonical dimensional reference | **Kimball & Ross, *The Data Warehouse Toolkit*, 3rd ed. (2013)** | **There is no 4th edition**; the Kimball Group ceased its consulting/training activity in 2016. It is still the reference, with the caveat that its ETL chapters describe a pre-ELT era |
| Metric definition | **In the repository, in versioned YAML, next to the model** | **MetricFlow** relicensed to **Apache 2.0** (Oct 2025). **Cube** as a *headless* alternative (it defines **and serves**: they are not interchangeable) |
| Semantic interchange specification | **Apache Ossie (incubating)**, formerly *Open Semantic Interchange* (OSI) | Apache-2.0, JSON/YAML specification. It is a **specification**, not a product: it stores nothing and serves nothing. Watch the real adoption of importers before betting on portability |
| Model tests | Versioned declarative assertions (uniqueness, not null, relationships, accepted values) | Execution gate (§4) |
| Grain documentation | In the model itself, not in a wiki | A grain documented outside the code stops being true within a quarter |

## 3. Structure and conventions

### 3.1 Layers

Three, with separated responsibilities. The names vary (bronze/silver/gold,
*staging*/intermediate/marts); the rules do not:

| Layer | Content | Hard rule |
|---|---|---|
| **Raw / bronze** | Faithful copy of the source, immutable | It is not modelled. It belongs to `data-engineering-standards` |
| **Intermediate / silver** | Typing, deduplication, entity conformance, business rules | This is where the ugly logic lives, and **only here** |
| **Consumption / gold / marts** | Facts and dimensions, or the OBT derived from them | **It must be boring**: stable names, stable types, zero surprises |

That the consumption layer is boring is a requirement, not a style. It is the layer people read without
asking you, the one that breaks reports when it changes and the one that sets the contract with the business. Every
surprise (a column that is sometimes null, a `status` with new values and no warning, a metric
whose definition changed silently) is paid for in trust, and trust is not recovered with a
*hotfix*.

**Forbidden to skip the intermediate layer** by putting business logic in the consumption layer: the
result is marts that contradict each other because each one reimplemented the same rule slightly
differently.

### 3.2 Facts: the grain is the decision

**The grain is the most important decision and the one most often got wrong.** It is declared **first**, in a
natural-language sentence, before writing a single column:

> "One row = **one line of an order** at the moment it was confirmed."

Rules:
- **The grain is written in the model** (the table's description), not in anybody's head.
- **Atomic grain by default**: the finest the source allows. Aggregating afterwards is trivial;
  disaggregating is impossible. Pre-aggregates are derived optimisations, not the fact.
- **One grain per table.** Mixing order lines and order headers in the same table is the
  root cause of half of the industry's inflated figures: any sum multiplies by the
  number of lines.
- **The grain is tested, not believed** (§4): if the declared key is not unique, your grain is not what you
  think it is, and everything built on top is wrong.

**Measure types** — the classification decides which aggregations are legal, and it must be declared:

| Type | Sums over any dimension | Example | Trap |
|---|---|---|---|
| **Additive** | Yes | Sales amount | — |
| **Semi-additive** | Yes, except over time | Account balance, inventory level | Summing 12 months of balances gives a meaningless figure. Over time: last value or average |
| **Non-additive** | No | Ratios, percentages, unit margins | **Never store the ratio**: store the numerator and denominator and divide when aggregating. Summing ratios is always incorrect |

**Fact table types**:
- **Transactional**: one row per event, atomic grain. The default.
- **Periodic snapshot**: one row per entity and period (daily balance, weekly inventory). For
  semi-additive measures and for "how much was there" questions. It grows predictably.
- **Accumulating snapshot**: one row per process with multiple milestones, **which is updated** as it
  progresses (ordered → paid → shipped → delivered). To measure latencies between phases. It is the only
  fact table that gets updated, and it must be stated explicitly because it breaks the expectation
  of immutability.
- **Factless**: it records that something happened or that a relationship exists, with no measure.
  Attendance, coverage, eligibility. Legitimate and heavily under-used: the usual alternative is
  inventing a `count = 1` column, which is the same thing with a worse name.

In addition: **degenerate dimensions** (order/ticket number) live in the fact, with no table of their own;
**junk dimensions** group low-cardinality flags that do not deserve one dimension
each.

### 3.3 Dimensions

- **Surrogate keys** in historised dimensions (SCD2) — they are **mandatory** there, because
  the natural key stops being unique once there are several versions. In non-historised dimensions, the
  natural key is acceptable and simpler; a conscious decision, not an automatism.
- **The natural key never disappears from the model**: it is kept as a column, because it is the only thing
  that allows reconciling with the source system when someone asks.
- **Never use the surrogate key as an integration key between systems** nor expose it to the
  outside: it is an internal detail of the warehouse.
- **Every dimension has an "unknown"/"not applicable" row** with a fixed key (typically `-1`).
  Without it, facts with a missing dimension are lost in the `INNER JOIN` and the figures drop without
  anyone knowing why. This is a `LEFT JOIN` that silently unbalances the total.
- **Hierarchies**: inside the dimension itself (country → region → city) as long as they are fixed.
  Ragged or variable-depth hierarchies require a *bridge* table — and they are the
  most frequent excuse for complicating a model that did not need it.

**Slowly changing dimensions (SCD)** — Kimball defines types 0 to 7; in practice
only three are used, and the choice is made by business question, not by habit:

| Type | Behaviour | When |
|---|---|---|
| **0** | The attribute never changes | Original sign-up date, country of birth |
| **1** | Overwrite | **The default.** The business does not need the previous value (fixing a typo, current phone number) |
| **2** | New row with `valid_from`/`valid_to`/`is_current` | **When the business needs to analyse the past with the values of that time**: change of customer segment, of sales territory, of tariff |
| **3** | A "previous value" column | A real niche: a one-off reorganisation where you must report by the old structure **and** the new one at the same time. It is not a general alternative to type 2 |

Decision criterion, in one question: **"when this attribute changes, should historical reports
reflect the value of that time or the current one?"** If it is "of that time", type 2. If it is "the current
one", type 1. If nobody can answer, it is type 1 — and the fact that it was asked is documented.

**SCD type 2 is not free** and that is why it is in the prohibitions without further need: it multiplies rows,
forces **every** *join* from the fact to use the surrogate key valid at the event's date
(not the current one), breaks naive counts of the dimension (`COUNT(*)` stops being "number of
customers") and complicates erasure under the right to be forgotten. Apply it to the attributes that require it,
**not to the whole dimension**.

**Conformed dimensions** — the mechanism that makes two marts comparable. A conformed
dimension is the same dimension (same keys, same attributes, same meaning) used by
several facts. Without them, "sales by region" and "returns by region" cannot be crossed
because "region" does not mean the same thing, and nobody discovers it until the figures do not match in a
meeting. Rule: **one business entity = one dimension = one owner.** If a mart needs
a variant, it is justified in writing or the dimension is conformed.

### 3.4 The date dimension

A physical table, populated in advance, with one row per day (and another per hour/minute if needed,
**separate**). It is not optional and it is not replaced by the engine's date functions: it exists to
hold what the engine does not know —holidays, fiscal calendar, working weeks, seasons— and so
that queries filter by attribute instead of by expression.

- Key in `YYYYMMDD` format (integer) or a date: readable in the fact, sortable, no *join* to
  debug.
- **Fiscal calendar** as its own columns (`fiscal_year`, `fiscal_quarter`, `fiscal_period`):
  the fiscal year almost never matches the calendar one, and reimplementing it in every query guarantees
  that some will match and others will not.

### 3.5 The date problem — local time versus UTC

A recurring source of discrepancies between reports that nobody can explain. A rule in three parts,
all mandatory:

1. **Always store the instant in UTC** with a zoned type (`timestamptz`/`TIMESTAMP` with zone).
   Never a type without a zone: "2 pm" with no zone is an incomplete datum disguised as a complete one.
2. **Also store the business date key** (`date_key`) already resolved in the **business
   time zone**, decided and documented. It is the column you filter and group by. Without it,
   every query converts in its own way and "yesterday's sales" gives three different figures depending on who
   asks.
3. **Document what the business zone is and what happens with multi-country operations**: either a single
   canonical zone, or a local `date_key` **per country** in addition to the canonical one — chosen
   explicitly and written in the model.

Additions: store the *offset* if the daylight-saving change matters (23- and 25-hour
days exist and break annual reconciliations); and decide which date rules —event date, posting
date, ingestion date— per fact. **The three are different and all three are necessary**; the
one used to partition is not necessarily the one used to report.

### 3.6 Deliberate denormalisation: OBT

Flattening everything into a wide table is **correct** when: (a) it serves a specific consumption case,
(b) it **is derived** from a dimensional model that still exists, (c) its rebuild is
automatic, and (d) it is documented as a serving view.

The gain is real and measurable —columnar MPP engines favour the wide table over the *join*
at query time—, but it is a **last-mile** gain.

It is **laziness** when: it replaces the model instead of being derived from it, every team has its own with
different rules, nobody knows what grain it is at, or the metric is defined inside the table itself and
gets duplicated in the next one. Unmistakable symptom: **there are three wide "sales" tables and none
matches the others**.

### 3.7 Metrics and the semantic layer

**The definition of "revenue" or of "active customer" is a repository artifact, versioned,
reviewed by *pull request* and with an owner.** It does not live in a report, nor in a spreadsheet,
nor in the head of whoever has been there longest.

- **One definition, one name.** If the business has two notions of revenue (gross and net of
  returns), they are **two metrics with two names**, not one ambiguous metric.
- **The metric is defined over the dimensional model**, declaring the measure, the aggregation and the
  dimensions it is legal to break it down by. A metric with no declared dimensions will be
  broken down by something that makes no sense.
- **The semantic layer does not fix a bad model**: if the grain is wrong, the metric computed
  on top is wrong with more steps and better presentation.
- **Portability, with measured scepticism**: Apache Ossie (incubating) is the interchange
  specification, and MetricFlow (Apache 2.0) its reference declarative format. The specification
  does not carry the serving architecture —cache, pre-aggregates, multi-tenancy, APIs—: that is not
  portable even if the definition is. Adopt the specification out of hygiene; do not assume it as
  a guarantee of exit.
- **A metric with no owner = a dead metric.** When two reports disagree, there has to be
  someone who decides which is correct, and within how long.

## 4. Quality and testing — gates

A model's tests are not a matter of opinion: they are what proves the model is what you say
it is. In increasing order of cost; **all of them are gates on publishing the consumption layer**
unless stated otherwise.

1. **Uniqueness of the grain key.** The test that proves the declared grain is real. If
   the key is composite, the combination is tested. **Without this test there is no model, there is a table.**
2. **Not null** on keys, on dimension foreign keys and on the columns a metric
   depends on.
3. **Referential integrity**: every dimension key in the fact exists in the dimension. Analytical
   warehouses do not enforce FKs; therefore it is tested, or it does not exist.
4. **Accepted values** on catalogue columns (`status`, `type`, `channel`): it catches the new
   value the source introduced without warning **before** it shows up as "other" in a report.
5. **Ranges and signs**: amounts that cannot be negative, dates that cannot be in the
   future, bounded quantities.
6. **SCD2 integrity** — systematically forgotten and the place where things break most silently:
   - Exactly **one** current row (`is_current`) per natural key.
   - The `[valid_from, valid_to)` intervals of the same natural key **do not overlap and leave no
     gaps**.
   - The first version starts at the beginning of time and the current one has no end (or has a
     documented sentinel date, always the same one).
7. **Reconciliation with the source**: row count and sum of a key measure against the source system,
   with a declared tolerance. It is the only test that detects row loss upstream.
8. **Reconciliation between layers and between marts**: the canonical metric computed from the atomic fact and
   from the aggregate/OBT must match. **If two marts publish the same metric, a test compares
   their results** — this is the test that prevents the domain's most expensive failure.
9. **Non-multiplication (*fan-out*) test**: after the model's *joins*, the fact's row
   count does not change. It catches the *join* with a dimension that was not unique, which is the
   mechanical cause of inflated figures.
10. **Unit tests of the business logic** with fixed input rows and expected output,
    covering edges: nulls, an SCD2 version change exactly at the instant of the event, a row arriving
    out of order, an entity with no dimension, a zero amount, a full refund.
11. **Consumption-layer contract**: removing or renaming a published column, or changing the
    type, **breaks the build** unless there is explicit recorded approval. The consumption layer is an API.
12. **Documentation as a gate**: a model with no grain description and no documented columns does not
    merge.

## 5. Security and personal data in the model

- **Classify while modelling, not afterwards.** Every column of a dimension knows whether it is public, internal,
  confidential or personal. The classification decides who sees it and how long it lives
  (see `privacy-engineering-standards`).
- **Minimisation in the model**: a dimension is not a dumping ground for every field in the source.
  Every copied attribute is an attribute you have to retain, erase and explain in a breach. Copying
  the whole `customer` table "just in case" is a privacy decision taken by omission.
- **The right to be forgotten and SCD2 collide head-on**: erasing a subject from a historised
  dimension destroys the traceability of the facts if it is done naively. Design from the
  start: **identifying attributes separated** from the analytical ones (segment, region, cohort),
  so that the identifying part can be anonymised while preserving the structure of the fact.
  Alternative: pseudonymisation with a mapping table under strict control, or
  *crypto-shredding*. A decision for `privacy-engineering-standards`; **the structure that makes it
  possible is decided here, and if it is not decided here, later it is a migration**.
- **Facts do not carry PII.** They carry keys. If a fact needs the name or the email, the
  model is wrong.
- **Granularity as a control**: publishing the aggregated mart instead of the atomic fact is often the
  simplest and most effective mitigation. A mart from which you cannot get to the person does not need
  half the controls of one where you can.
- **Row/column-level security** applied in the consumption layer and **modelled**: the dimension
  that determines visibility (organisation, territory) has to exist in the fact in order to
  filter. If it is added later, it is a migration of the entire history.
- No real PII in the model's development environments (see `data-engineering-standards` §4).

## 6. Model performance and operability

- **Materialise by consumption, not by habit**: the atomic fact materialised; intermediate layers
  as views if they are queried rarely; aggregates and OBT materialised only with measured demand. Every
  materialised table nobody queries is paid for on every run.
- **Aggregates are derived and must be rebuildable** from the atomic fact. An aggregate
  that cannot be recomputed is an accidental source of truth.
- **Sorting/clustering by the usual filter column** (event date, and sometimes the
  highest-cardinality filtering dimension). Physical partitioning and its cost belong to
  `data-engineering-standards`; **which column deserves to be the filter one is said by the model**.
- **Small wide dimensions, tall narrow facts**: it is the split that columnar
  engines reward. A dimension with 40 attributes and 50,000 rows is healthy; a fact with 40
  descriptive columns is a modelling error.
- **Watch the growth of SCD2s**: a dimension historised on a volatile attribute grows
  without bound and degrades every *join*. If it grows faster than the fact, the attribute was not
  dimensional: it was a measure.
- **Model health metrics**, reviewed on a cadence: number of marts publishing the same
  metric (target: one), models with no documented grain (target: zero), tests per model,
  models with no consumption in the last quarter.
- **An owner per conformed dimension and per metric**, published. Without an owner, the
  discrepancy between reports is resolved by nobody and becomes folklore.

## 7. Sustainability and prohibitions

- **Schema evolution**: **adding is easy, changing the grain is a migration.** Adding a
  column or a dimension is additive and compatible. Changing a fact's grain, changing a
  dimension from type 1 to type 2, or redefining a metric **are not**: they require rebuilding the
  history, communicating with consumers and a coexistence period for the old and the
  new version. Treat them as a migration with expand/contract, not as a code change.
- **Redefining a metric is a communication event, not a commit.** The published figures
  will change retroactively; if nobody announces it, the business concludes the data is
  unreliable. Version the metric and keep both for the duration of the transition.
- **Active retirement**: a mart, dimension or metric with no measured consumption for a quarter is flagged and
  retired. The warehouse grows by accumulation by default.
- **Mandatory ADR** for: modelling paradigm, the grain of each central fact, historisation
  policy per dimension, canonical time zone and fiscal calendar, and the decision to publish
  an OBT.
- **Review cadence**: half-yearly for the status of the semantic layer specifications
  (Apache Ossie, MetricFlow, Cube), which are actively moving.

**FORBIDDEN**
- ❌ **Modelling without declaring the grain** in writing and in the model itself. It is the root defect of the
  domain.
- ❌ More than one grain in the same fact table.
- ❌ Publishing a table without a uniqueness test on its key: the grain is not proven.
- ❌ **SCD type 2 without a demonstrated need**, or applied to the whole dimension instead of to the
  attributes that require it.
- ❌ Replacing an SCD type 2 with the table format's *time travel*.
- ❌ **Marts that redefine metrics** already defined elsewhere; or the same metric with the same
  name and two definitions.
- ❌ Defining a metric inside a report or a BI tool.
- ❌ Storing ratios, percentages or averages as an aggregatable measure.
- ❌ Summing a semi-additive measure over time.
- ❌ A dimension with no "unknown" row, or an `INNER JOIN` to a dimension that silently discards facts.
- ❌ A surrogate key exposed outside the warehouse or used as an integration key.
- ❌ Losing the source's natural key when modelling.
- ❌ Storing instants without a time zone, or lacking an explicit business `date_key`.
- ❌ Reimplementing the fiscal calendar in every query instead of having it in the date dimension.
- ❌ OBT as the source of truth, or several OBTs of the same domain with different rules.
- ❌ Business logic in the consumption layer, or a consumption layer that skips the intermediate one.
- ❌ Data Vault without a written audit requirement.
- ❌ 3NF normalisation as the consumption layer for business users.
- ❌ PII in fact tables; dimensions that copy the entire source "just in case".
- ❌ Changing the grain, the type or the name of a published column without a migration and without warning.
- ❌ Trusting referential integrity "because the data comes in clean": in an analytical warehouse
  there are no FKs, there are tests.
- ❌ Documenting the grain in a wiki instead of in the model.
- ❌ Pinning versions, licences or specification status from memory (§8).

## 8. Mandatory web verification

The data in §2 is from **August 2026**. Before committing anything to a deliverable, verify:

1. **Kimball reference**: whether a 4th edition of *The Data Warehouse Toolkit* has appeared
   (as of Aug 2026 the current one is the **3rd, from 2013**, with no announced successor).
2. **Data Vault 2.0**: the status of the standard and of its automation ecosystem; updated adoption
   data before quoting percentages (those in §2.1 come from a commercially sponsored BARC study:
   **treat them as an order of magnitude, not as an exact figure**).
3. **Semantic layer**: the status of **Apache Ossie** (ASF incubator, formerly OSI; specification
   v1.0 published in early 2026) and **the real adoption of importers/exporters by
   vendors** — it is the only thing that turns the specification into portability. Licence and
   activity of **MetricFlow** (Apache 2.0 since Oct 2025) and of **Cube**.
4. **dbt after the merger with Fivetran** (completed 1 Jun 2026): which part of the semantic layer is
   OSS and which part requires the paid platform; the metric serving API has been tied to the
   commercial product (see `data-engineering-standards` §2 and §8).
5. **Table format**: schema evolution and *time travel* capabilities of Iceberg/Delta,
   in case they shift the boundary with `lakehouse-standards` (Iceberg 1.11.0 in May 2026).
6. Functions and limits of the specific engine (BigQuery, Snowflake, Redshift, Databricks, Fabric) in whatever
   the model takes for granted: *clustering*, materialised views, row-level security.

**Declared gaps of this revision** (do not fill in from memory):
- **Apache Ossie**: the number of vendors with an **actually published** importer/exporter has not been
  verified; secondary sources suggest adoption lags far behind the announcement.
  Do not promise metric portability without checking it product by product.
- **Data Vault 2.0**: Dan Linstedt's current position has not been verified, nor any revision of the
  standard after 2025.
- **Cube**: version, current licence and current business model not verified in this revision.
- **OBT versus star performance figures**: the percentages in circulation come from a
  vendor *benchmark*. Measure on your engine and with your data before using them to decide.

If the web contradicts this document, **the web wins** — flag the discrepancy.
