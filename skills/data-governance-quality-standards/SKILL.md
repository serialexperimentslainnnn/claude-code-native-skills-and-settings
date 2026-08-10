---
name: data-governance-quality-standards
description: Use when data must be trustworthy and owned — naming a data owner and data steward per dataset versus the platform team, federated ownership and data mesh honesty, choosing or operating a data catalog (DataHub, OpenMetadata, Amundsen, Apache Atlas, Unity Catalog OSS, Collibra, Alation, Atlan), technical versus business metadata, column-level lineage and impact analysis, a business glossary where two teams define "active customer" differently, data contracts as schema plus semantics plus SLA plus owner (Open Data Contract Standard, Bitol ODCS/ODPS, datacontract.yaml) and what happens when one breaks, the quality dimensions (completeness, uniqueness, validity, consistency, timeliness, accuracy) turned into executable assertions, where to check them (source, pipeline, consumption), quality tooling (Great Expectations/GX Core, Soda, Elementary, Evidently), severity of a data incident and notifying the consumers who already decided with bad numbers, data classification tiers (public/internal/confidential/restricted) and their link to access control, dataset retention and decommissioning, or program metrics like contract coverage, time to detect and time to resolve.
---

# Data governance and quality standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when the question is **whose data this is, whether it can be trusted and who answers
when it can't**: ownership, catalog, glossary, lineage, data contracts, quality programme,
data incidents, classification and lifecycle.

Triggers: `datacontract.yaml`, `odcs.yaml`, `contract.yml`, `great_expectations/`,
`gx/`, `expectations/*.json`, `soda/checks.yml`, `soda-cl`, `elementary/`, `edr report`,
`schema.yml` with `tests:`/`data_tests:`, `owner:`/`owner_email`, `tags: [pii, confidential]`,
`glossary`, `lineage`, `datahub`/metadata ingestion `recipe.yml`, `openmetadata`,
`atlas`, `unitycatalog`, "whose table is this?", "is this reliable?", "what breaks if I
change this column?", "the two reports give different figures", "we've had stale
data for three weeks and nobody noticed", "what is an active customer?", "how long do we keep this?".

**Not applicable**: see
- `analytics-bi-standards` (**sister; boundary declared on both sides**): **governance decides
  whether the data is trustworthy and whose it is; BI presents it so someone can decide.** Certifying
  a report, retiring it, choosing a tool, dashboard performance and spreadsheet
  export are theirs; the owner of the underlying dataset, its contract, its committed
  freshness and its classification are ours. **A dashboard over ownerless data is an
  incident waiting to happen**, and the governance of BI itself (per-report owner, pruning) is theirs but
  inherits these ownership rules.
- `data-warehouse-modeling-standards`: **the canonical definition of a metric and the semantic layer
  are theirs** (§3.7 of that skill), as are the structural tests of the model (grain
  uniqueness, referential integrity, SCD2). Here the **business glossary** —the term and its
  agreed meaning— and the **programme** that makes those tests exist, have an owner and get
  reviewed. Cut-off rule: *"how is net revenue calculated?"* is theirs; *"who decides what
  active customer means and who answers when two areas disagree?"* is ours.
- `data-engineering-standards`: **it executes the assertions and the freshness gate inside the
  pipeline** (blocking versus warning, retries, backfill, data observability as
  instrumentation). Here we decide **what gets checked, at what severity, who owns the
  rule and what happens when it fails**. The mechanics are theirs; the programme is ours.
- `data-platform-standards` (**parent**): engines, encryption at rest, backups, PITR.
- `privacy-engineering-standards`: **personal data, minimisation, legal basis, retention and erasure
  of the subject, pseudonymisation and DPIA are theirs, without exception.** Here the **general**
  classification of data (including the "restricted" tier that usually contains personal data) and the
  lifecycle of the dataset as an asset. If the question mentions a data subject, a right or a
  legal basis, it is theirs.
- `grc-compliance-standards`: **regulatory framework, corporate risk, SoA, audit evidence and
  control-to-standard mapping are theirs.** Here the operational control over data; whether that control **serves
  as evidence** for ISO 27001, NIS2 or DORA is theirs to decide.
- `ai-governance-standards` (**direct boundary, declared on both sides**): **the governance of AI
  systems is theirs** —system inventory, AI Act, risk classification, FRIA,
  human oversight—. **Data governance is ours.** They meet at exactly one point: the
  data that feeds a model. Cut-off rule: the **provenance, ownership, quality, contract and
  classification of the training or retrieval dataset are ours**; what can be done
  with the resulting system, who authorises it and what regulatory obligation it generates is theirs. Both
  share the same thesis: **governance that changes no decisions is theatre.**
- `incident-management-standards`: **the incident process is theirs** —declaration, severity,
  Incident Commander, communication, blameless postmortem—. Here only what is data-specific: what
  makes bad data an incident, how to notify whoever already decided with it, and why silent
  failure does not fit the standard severity matrix.
- `observability-standards`: telemetry **of the system** (OTel, metrics, traces). **Data
  observability —freshness, volume, schema, distribution— is ours as a programme and
  `data-engineering-standards`' as instrumentation.** Line: if the signal describes the process, it is
  theirs; if it describes the data, it is not.
- `identity-access-management-standards`: **who accesses and with what identity is theirs**; here only
  the **classification that determines what deserves which control**.
- `sre-practice-standards` (SLOs and on-call as a practice), `backup-recovery-standards`,
  `bcdr-standards`, `cicd-standards`, `iac-standards`, `api-design-standards`,
  `object-storage-standards`, `mlops-standards`, `rag-standards`,
  `llm-app-engineering-standards`, `python-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (Purview, Dataplex, DataZone/SageMaker
  Catalog **as managed services**: provisioning, IAM and cost are theirs; the governance
  criteria on top are ours).
- `lakehouse-standards`: **the table format and the technical catalog are theirs** —Iceberg/Delta,
  REST Catalog, Polaris, Nessie, snapshots, *time travel*, maintenance—, including table/row/column-level
  access control in the format and deletion inside an immutable format.
  Here the **governance catalog** (owner, glossary, certification, business lineage), which is a different
  thing even if it shares the word: a *technical catalog* answers where the files are; a
  governance one, whether you can trust them.
- Specific engines: `nosql-standards`, `graph-db-standards`, `vector-db-standards`,
  `search-engines-standards`, `streaming-cdc-standards` (**change events and their transport
  contract are theirs**; the data contract of the resulting dataset is ours), and
  `timeseries-db-standards`, `message-brokers-standards`,
  `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`,
  `caching-cdn-standards`.

### Domain thesis

**Data quality is an ownership problem, not a tooling problem.** Without a named person
per dataset, no tool fixes anything: the catalog fills up with undescribed
tables, assertions fail permanently red and nobody looks at them, and the glossary documents
terms nobody uses. With an owner, almost any tool works. Buying a catalog before
naming owners is the most expensive and most frequent inverted sequence in the sector.

**Corollary, the same criteria as `ai-governance-standards`: governance that changes no decisions
is theatre.** A control that only produces a slide is not a control. Before adding
any piece to the programme, answer: *what decision does this change and who takes it?* If the
answer is "it lets us show that we govern it", delete it. This domain accumulates more theatre per
square metre than any other in the discipline: committees that approve what is already in
production, policies nobody reads, catalogs with 90 % of entries autogenerated and empty,
and quality dashboards whose green percentage is a function of which rules were written,
not of whether the data is fit for use.

## 2. Default decisions

> Verify status, licence and owner on the web before committing to anything in a real project (§8).
> This segment consolidated heavily in 2025-2026 and **at least two pieces changed licence or
> owner without changing name**.

### 2.1 Programme sequence (non-negotiable order)

| Step | Deliverable | Why before the next one |
|---|---|---|
| 1 | **Inventory of the datasets that matter** (those feeding decisions or systems, not all of them) | Governing everything is governing nothing |
| 2 | **Named owner per dataset**, a person with a name and a role, published | Without this, the rest is decoration |
| 3 | **Minimum contract** for published datasets: schema, semantics, freshness SLA, owner | Turns tacit expectations into a verifiable commitment |
| 4 | **Executable assertions** derived from the contract | A contract that is not checked is a promise |
| 5 | **Data incident process** with severity and communication | Without this, detecting is useless |
| 6 | **Catalog** | It is the shop window of the previous work, not a substitute for it |
| 7 | **Business glossary** for disputed terms (not the whole dictionary) | It only has value where there is real disagreement |

**Installing the catalog first is the canonical mistake of the domain.** It gives a sense of progress
—there is a website, there are tables, there is a search box— without changing any decision. A catalog populated
automatically over ownerless data is an inventory of the swamp.

### 2.2 Catalog and discovery

A catalog solves **exactly two questions**, and you must demand those two and no more:

1. **Find the data** I need without asking a human.
2. **Know whether I can trust it**: who the owner is, when it was last updated, whether it
   is certified, whether its checks are green and where it comes from.

Everything else catalogs sell (approval workflows, *stewardship* campaigns,
aggregate quality scores) is optional and, in practice, the first thing to be abandoned.

| Option | Licence and governance (verified Aug 2026) | Real status | Verdict |
|---|---|---|---|
| **OpenMetadata** | Apache-2.0; company behind it: Collate | **Very active**: 1.13.x branch with releases in Jul 2026 and **2.0.0-rc1** (Jul 2026) | **OSS default** for a general-purpose catalog |
| **DataHub** | Apache-2.0; company behind it: Acryl Data / DataHub Cloud | **Active**: v1.6.0 (May 2026), *release candidates* in Aug 2026 | Right when the scale of the metadata graph and event-based ingestion matter; **higher operational cost** |
| **Unity Catalog (OSS)** | Apache-2.0; **sandbox** at LF AI & Data (entry level, neither incubation nor graduated) | 0.5.1 (Jul 2026). **APIs declared unstable** | **This is not Databricks' Unity Catalog.** What is open is the REST specification and a reference server; lineage, quality, ABAC, system tables and auditing **belong to the commercial product**. Useful as an interoperable metadata layer; **do not sell it as a governance catalog** |
| **Apache Atlas** | Apache-2.0, ASF | Alive but slow: 2.5.0 (Apr 2026), 2.6.0-rc0 (Aug 2026) | Only if you already live in the Hadoop/Ranger ecosystem. Not a new choice |
| **Amundsen** | Apache-2.0, LF AI & Data | **Effectively stalled**: last release **v1.0.0 (Jun 2025)**; last commit on `main` **Apr 2025** | ❌ **Do not adopt it in 2026.** If you have it, plan the exit |
| **Collibra / Alation / Informatica / Atlan** | Commercial, negotiated pricing (order of magnitude published by analysts: **hundreds of thousands of € per year** in an enterprise deployment) | All four appear as leaders in the 2026 Gartner quadrant for data and analytics governance platforms, which already evaluates **AI model governance** as a criterion | They are justified when there is a formal regulatory obligation, thousands of assets and a dedicated governance team. **Do not buy them to solve "we don't know whose table this is" across 200 tables** |

**Lineage: the feature most paid for and least maintained.** It is the one that closes the sale and the
one that degrades silently. Concrete reasons: column-level lineage is only reliable where
the engine emits it or the SQL parser understands it, and a single stored procedure, a job in
Python, an export to a spreadsheet or a dynamically generated `CREATE TABLE AS` is enough to
break the graph. The typical result is a **partial graph presented as complete**, which is
worse than not having it: someone decides that "nothing depends on this table" and deletes it.

Lineage rules:
- **Require lineage to be derived from real execution** (query logs, engine metadata,
  orchestrator events), not from hand-entered documentation. Manual lineage expires within
  weeks.
- **Measure and publish coverage** ("lineage covers 70 % of the consumption-layer assets").
  A graph without declared coverage invites false conclusions.
- **Its only use that justifies the cost is impact analysis**: *"what breaks if I change
  this?"* and *"who do I notify that this data was wrong?"*. If nobody uses it for that, don't pay for it.

**Technical versus business metadata**: technical metadata (schema, types, size, freshness,
lineage) is **collected automatically and is free**; business metadata (what it means, who
uses it, for what decision, which rules were applied to it) **is written by hand and is the only kind that
has value**. A catalog with 100 % technical metadata and 5 % business metadata has
automated what didn't matter. Operational corollary: **do not populate the whole catalog**. Start
with the certified assets and leave the rest visible but explicitly ungoverned.

### 2.3 Quality tooling

| Tool | Licence and status (verified Aug 2026) | Correct use |
|---|---|---|
| **Transformation engine tests** (dbt tests / SQLMesh audits) | Part of the tool you already use | **Default.** The first line of assertions lives where the transformation lives, not in a separate system |
| **Soda Core** | ⚠️ **Elastic License 2.0** — *source-available*, **not OSI open source** (verified verbatim in the repo's `LICENSE` file). Active: 4.19.0 (Jul 2026) | Legitimate for internal use. **Ruled out if your policy requires an OSI licence**, or if you are going to embed it in a product you offer to third parties |
| **Great Expectations (GX Core)** | Apache-2.0. **GX Cloud was acquired by FICO and stopped being publicly available**; **Fivetran announced on 13 May 2026 that it is taking over *stewardship* of the community and of GX Core**. `CloudDataContext` now raises an exception | Only if you need its *expectations* catalog or validation outside SQL (Pandas/Spark). **GX 1.0 (Aug 2024) broke the API relative to 0.x**: any 0.x material is useless |
| **Elementary** | OSS + SaaS. Active (0.25.1, Jul 2026). ⚠️ **See §5: version 0.23.3 was published compromised on 24 Apr 2026** | Observability over dbt projects. Adopt it **with the hash-pinning discipline of §5**, not without it |
| **Evidently** | Active OSS; **licence not verified raw in this revision (§8)** | **It is a distribution drift tool, not a business assertion engine.** Right for watching drift in data that feeds models (boundary with `mlops-standards`); wrong as a substitute for validity rules |
| **dbt-expectations** (Calogica) | ❌ **Unmaintained** (repo declared without active support) | Do not introduce it in new projects |

**Selection criteria, in one line**: the best quality tool is **the one already in the
pipeline**. A separate quality system adds another deployment, other warehouse credentials
(§5), another dashboard and another place to look. It is justified when you need to check data that
**does not pass through your transformation** (third-party files, the source before ingesting it, someone
else's operational system).

### 2.4 Data contracts

A data contract is **four things or it is nothing**:

1. **Schema**: columns, types, nullability, allowed values.
2. **Semantics**: what each field means and what a row represents (the grain is declared by
   `data-warehouse-modeling-standards`; the contract **publishes** it).
3. **SLA**: committed freshness, correction window, availability. **Freshness and
   availability are different** and confusing them is the usual mistake.
4. **Owner** and contact channel.

A "contract" that only has a schema is a schema definition with a pompous name.

- **Where they live**: **in the repository, versioned, next to the code that produces the data**, and
  reviewed by *pull request*. Never in a wiki, never only inside the catalog. The contract
  being in Git is what allows breaking it to break a CI.
- **Specification**: **Open Data Contract Standard (ODCS)**, under the **Bitol** project of LF AI &
  Data, is today the one with the most traction, alongside the Data Contract Specification (`datacontract.com`),
  with declared harmonisation work between the two. Verify the version before pinning it: as of
  Aug 2026 the documentation publishes **v3.1.0** while the repository's `main` declares **v3.0.2**
  (a real discrepancy, see §8). The adoption figures going around (114 organisations as of
  31 May 2026) come from an **internal registry of the project itself and are self-declared**:
  use them as a signal of direction, not as market share.
- **Adopt the specification for hygiene, not for portability.** Its immediate value is having an
  agreed, validatable format; the ecosystem of tools that consume it is still thin.
- **The producer's contract, not the consumer's.** It is signed by whoever produces the data. A contract
  drafted by the data team over a system it does not control is a wish list.

**What happens when it breaks** — this is the only part that matters and the one that is almost never defined:

| Type of break | Required effect | Who decides |
|---|---|---|
| **Compatible** (new column, new value in an open catalog) | Announced; does not block | Producer |
| **Incompatible** (column removed or renamed, type changed, grain changed, semantics changed) | **Breaks the producer's CI.** Not published without an expand/contract migration, notice to known consumers and a coexistence period | **Producer and affected consumers; the data owner arbitrates** |
| **SLA break** (arrives late, 0 rows arrive, out of band) | Data incident (§4.3) | Data on-call |

Hard rule: **if breaking a contract breaks nothing, there was no contract.** And the corollary that avoids
theatre: **whoever finds out has to be whoever can fix it**, not a mailing list.

### 2.5 Ownership and organisational model

Three distinct roles, constantly confused:

| Role | What they decide | What it is NOT |
|---|---|---|
| **Data owner** | Person **from the business** responsible for the asset: what it means, who can access it, how long it is retained, whether a change is acceptable, and **arbitrates when two areas disagree** | Not whoever maintains the table. Not a team. Not "the data area" |
| **Data steward** | Executes and maintains: documents, defines and maintains the quality rules, answers questions, curates the catalog | Does not decide policy or access |
| **Platform team** | Provides the substrate: catalog, check engines, lineage, permissions, telemetry. **Makes it possible for the others to do their job** | **It is nobody's data owner**, and the moment it is, the organisation stops governing |

**Hard rule: nominal ownership, not departmental.** "It belongs to Finance" is not an owner; it is a
polite way of saying there isn't one.

**Federated model (data mesh), with honesty and without the sales pitch.** The 2026 retrospective is
reasonably clear and worth stating in full:

- **What survived**: domain ownership, the **data product** as the unit of governance,
  federated governance with common standards and the central team as an **enabler, not as a
  gatekeeper**. Mature implementations scope strict governance to a **small** number of
  critical data products (on the order of tens) and leave the rest queryable but
  **explicitly uncertified** — an excellent pattern, adopt it whatever it is called.
- **What did not survive**: maximalist decentralisation. Thoughtworks, the origin of the concept,
  describes 2026 as hard-won maturity alongside "a silent graveyard of stalled
  projects"; Gartner went as far as projecting it would become obsolete before reaching the plateau. Both
  things can be true: the diagnosis was good, the prescription overshot.
- **What it really demands**: domains with their own engineering capability, product budget
  (not project budget, and this is the factor that has killed the most implementations) and a self-service
  platform that exists **before** responsibility is handed out. **Without all three, federating is
  outsourcing the problem to teams that cannot solve it**, and the result is worse than the
  centralisation you were fleeing.

Criteria: **centralise by default in organisations with fewer than ~50 data people**; federate
only where the domain already sustains its own software in production. And do not call "mesh" handing out
tables without handing out capability.

### 2.6 Business glossary

Its value is not documenting; it is **resolving disagreements**. The real problem is not that "customer" is not
defined: it is that Sales and Finance call **"active customer"** different things, both
are right in their context, and nobody has written it down.

- **Only a term that is in dispute or that appears in a management report goes into the
  glossary.** A glossary of 800 terms is a graveyard; one with 30 gets read.
- **If two areas need different definitions, they are two terms with two names**
  (`cliente_activo_ventas`, `cliente_activo_facturacion`), not one ambiguous term. Forcing a single
  definition where the business has two realities produces a definition nobody uses.
- **Every term has a business owner and a date of agreement.**
- **The glossary is linked to real columns and metrics.** A term that points at
  no asset is an opinion.
- **The canonical definition of a computable metric lives in the model**
  (`data-warehouse-modeling-standards`), not here. The glossary says **what it means**; the model
  says **how it is calculated**. Duplicating the calculation in the glossary guarantees they diverge.

## 3. Quality dimensions and where they are checked

### 3.1 The six dimensions and their assertion

They are only useful if translated into something executable. Whatever cannot be translated gets deleted from the programme.

| Dimension | Question | Typical executable assertion |
|---|---|---|
| **Completeness** | Is everything there that should be? | No nulls in critical columns; row count within band; **0 rows is a failure, not a success**; no gaps in the partition series |
| **Uniqueness** | Are there duplicates? | Uniqueness of the declared key (the grain one; see `data-warehouse-modeling-standards`) |
| **Validity** | Are the values admissible? | Types, ranges, formats (email, IBAN, postcode), values within the allowed catalog |
| **Consistency** | Does it reconcile across places? | Referential integrity; aggregate sum = detail sum; the same metric computed by two paths matches |
| **Timeliness** | Is it on time? | Age of the most recent data against the contract's freshness SLA |
| **Accuracy** | Does it reflect reality? | **The only one that cannot be checked on its own**: it requires reconciliation with the source system or with an external source, and human sampling. Do not fake it with syntactic rules |

**Accuracy is the honest dimension.** All the others can be verified inside the system;
accuracy is only verified against the world. A green quality dashboard does not say that
the data is correct: it says it passes the rules someone wrote.

### 3.2 Where it is checked

Three points, and all three are needed:

1. **At the source** (input validation in the system that generates the data). **The cheapest and the
   most ignored**, because it requires negotiating with a team that isn't yours. A mandatory field in
   the form avoids ten downstream rules and an impossible correction three years later.
2. **In the pipeline** (blocking assertions before publishing). This is where bad data is **stopped**.
   **The mechanics belong to `data-engineering-standards`**; here the policy: what is blocking,
   what is a warning and who can change that classification.
3. **At consumption** (reconciliations and cross-checks over what was published). Detects what the rules did not
   foresee and what broke between layers.

**Checking only at the end is finding out late, and late means after someone had already decided.**
The cost of bad data grows with distance from the source: at the source it gets corrected; in the
pipeline it gets stopped; at consumption it has already been used, and you have to notify, recompute and explain.

### 3.3 Rule discipline

- **Every assertion has an owner and a reason.** A rule without a written reason cannot be retired, because
  nobody knows whether it is still needed.
- **Two severities, not five**: **blocking** (halts publication) or **warning** (counted
  and reviewed). Five levels only serve to leave nobody knowing what to do.
- **A warning rule nobody looks at gets deleted.** Quality noise trains the team to ignore
  quality alerts, and that is a permanent loss.
- **Permanent red = broken rule or broken data; neither is tolerated.** A check left
  red for a month has stopped being a check.
- **The "quality percentage" is FORBIDDEN as a management figure**: it is an average of heterogeneous
  rules that goes up by writing easy rules. Measure contract coverage and times (§6).

## 4. Gates

These gates break the build or block publication. In increasing order of cost.

### 4.1 CI gates (repository)

1. **Every published dataset has a declared owner in the code** (`owner:` in the
   model's or the contract's metadata). Without an owner, it doesn't merge.
2. **Every published dataset has a declared classification** (§5.1).
3. **The contract validates against its schema** (ODCS or equivalent) and **matches the real schema**
   of the artifact it produces.
4. **An incompatible contract change** (column removed/renamed, type changed, grain
   changed, semantics changed) **breaks the build** unless there is registered approval from the owner and from the
   known consumers.
5. **Every new quality rule declares owner, severity and reason.**
6. **Referenced glossary terms exist** and point at a real asset.
7. **Dependencies pinned by hash** in any environment with warehouse credentials (§5.2).

### 4.2 Runtime gates (publication)

8. **Blocking assertions green** before publishing the consumption layer. **Publishing bad
   data is worse than not publishing** — executing these checks belongs to
   `data-engineering-standards`; that they exist and at what severity, to here.
9. **Freshness within the contract's SLA**, checked **before** transforming and **after**
   publishing.
10. **Row count within band**, with **0 rows explicitly treated as a failure**.
11. **Reconciliation of the canonical metric** between the atomic fact and any published aggregate.

### 4.3 Process gate — data incidents

12. **Every dataset with a published SLA has an assigned on-call.** If nobody answers out of
    hours, **do not publish an out-of-hours SLA**: an SLA without on-call is a documented
    lie.
13. **Every high-severity data incident produces a notification to known consumers**
    (lineage serves for this or it serves for nothing) and a **blameless postmortem** with actions with
    owner and date. The process belongs to `incident-management-standards`; what is data-specific is:

**Severity of a data incident** — the generic incident matrix does not fit, because here the
system is green:

| Sev | Criteria |
|---|---|
| **1** | Incorrect data **already consumed** for an external, regulatory or financial decision; or published to customers |
| **2** | Incorrect or missing data in a certified asset, not yet consumed for a known decision |
| **3** | Freshness SLA breach without data corruption |
| **4** | Degradation in an uncertified asset |

**Silent failure is worse than an outage.** An outage is visible, escalates by itself and generates urgency; a
table that has been serving three-week-old data for three weeks is discovered in a management
committee, and by then decisions have been taken on it. Mandatory operational
consequences:

- **Alert on absence, not only on error**: "nothing has arrived" must fire just like
  "it failed".
- **Communicating the correction is part of the fix.** Silently correcting data someone already used
  is the most efficient way to destroy trust in the platform. **Trust is lost through
  silence, not through errors.**
- **Mark the data as suspect while the incident lasts**, visible at the point of consumption
  (see `analytics-bi-standards` §"perceived quality"), not in a channel the consumer does not read.

## 5. Security, classification and lifecycle

### 5.1 Classification

Four tiers, no more. Five tiers produce debates and no decision:

| Tier | Operational definition | Control consequence |
|---|---|---|
| **Public** | Can be published outside without harm | No restriction |
| **Internal** | Default for everything corporate | Authenticated access; no restriction by role |
| **Confidential** | Its disclosure causes harm (commercial, contractual, competitive) | Access by justified role; encryption; access auditing |
| **Restricted** | Sensitive personal data and regulated data. **Secrets are not a tier of this scale**: a credential is not classified, it is custodied — its lifecycle belongs to `secrets-management-standards` and personal data is not a secret | Strict least privilege, nominal and audited access, row/column-level security, bounded retention |

Rules:
- **Classification is an attribute of the data, not of the system.** Copying it elsewhere does not
  declassify it; **the classification travels with the copy**, including BI extracts and
  spreadsheets — which is exactly where it evaporates (see `analytics-bi-standards`).
- **Classifying is a business act, done by the owner**, not by the platform team nor by an automatic
  classifier. Automatic PII detection **proposes**; the owner **decides**.
- **Classification determines access control, not the other way round.** If the tier changes no
  permission, you are not classifying: you are labelling.
- **Unclassified = internal at minimum**, never "public by default".
- Personal data additionally inherits all of `privacy-engineering-standards`; **the legal basis, the
  processing, the DPIA and erasure of the subject are theirs, not ours.**

### 5.2 Security of the quality programme itself

Quality tools are **the most profitable target in the data supply chain**,
because by definition they hold read credentials over the whole warehouse.

- **A live precedent, not a hypothesis**: `elementary-data` **0.23.3** was published on PyPI on
  **24 Apr 2026** with an *infostealer*, after a script injection into a GitHub Actions
  workflow triggered by a PR comment. The *payload* travelled in a `.pth` file, which Python executes
  **when the interpreter starts**, and stole SSH keys, AWS/GCP/Azure credentials, Kubernetes
  secrets and configuration files. An image was also published to GHCR with the `latest` tag.
  **Fixed in 0.23.4.** Same pattern in `trivy` (Mar 2026), LiteLLM (Mar 2026) and
  `durabletask` (May 2026).
- **Mandatory consequences**: pinning by hash and by image *digest*; **never `latest`**; a
  quarantine window of days before adopting a freshly published version in environments with production
  credentials; the quality tool's runner **holds credentials for no more than one
  environment**; a read-only identity, per schema, distinct from the pipeline's.
- **Quality results are sensitive data**: a failure message that prints the offending
  row is a PII leak into a log that is usually less protected than the warehouse. Log
  the key or the count, **never the content**.
- **The catalog is a treasure map**: it contains table names, columns, descriptions and
  statistical profiles (sometimes sample values). Treat it as a confidential-tier system,
  with corporate authentication and no anonymous internal access.

### 5.3 Retention and lifecycle

- **Every dataset has a declared retention period in its contract.** "Forever" is
  a valid decision that someone has to sign off, not a default value.
- **Partition by date so you can delete.** A retention that requires a massive `DELETE` over a
  table of billions of rows will never be applied.
- **Retention of personal data, erasure of the subject and legal exceptions belong to
  `privacy-engineering-standards`.** Here only the lifecycle of the asset: creation, certification,
  degradation, retirement.
- **Active retirement**: a dataset with no measured consumption for a quarter → it is flagged,
  communicated and retired. **The data inventory grows by accumulation by default**, and every live
  table is breach surface, storage cost and one more source of contradiction.
- **The ungoverned copy is the real failure**: extracts, `SELECT *` to CSV, shared
  spreadsheets and "temporary" analysis databases. No catalog sees them. The mitigation is
  not technological: it is providing governed access comfortable enough that copying is not worth it.

## 6. Programme metrics

Only metrics that change a decision. Each carries a threshold and an accountable person.

| Metric | What it decides | Trap |
|---|---|---|
| **Ownership coverage** (% of certified assets with a nominal owner) | Where the only indispensable thing is missing | Counting "team X" as an owner |
| **Contract coverage** (% of published assets with a complete contract: schema+semantics+SLA+owner) | The quarter's work priority | Counting contracts that only have a schema |
| **Time to detect** (incident → someone knows) | Whether your checks are any use. **If the consumer detects it before you do, the metric is "infinity"** and that is the honest number | Measuring it only over those the system detected |
| **Time to resolve** (detection → correct data published **and communicated**) | Sizing of the team and the on-call | Closing the incident before communicating |
| **Incidents per affected consumer** | Prioritises by real harm, not by number of failures | Ignoring that an asset with 200 consumers weighs differently from one with 2 |
| **Freshness SLA breaches per asset** | Whether the promised SLA is realistic or has to be renegotiated | Lowering the SLA instead of fixing the pipeline and calling it an improvement |
| **Ignored warning rules** (red >30 days without action) | What to delete from the programme | Leaving them "just in case" |

**Metrics explicitly forbidden as vanity**: number of catalogued assets, number of
glossary terms, number of quality rules, aggregate "quality percentage", number of
catalog users. All go up by working and none changes a decision.

**Definitive test of the programme**, which no tool answers: *how long does it take a new
person to find the right data and know whether they can trust it, without asking anyone?* If it takes
days, you don't have governance: you have documentation.

## 7. Sustainability and prohibitions

- **Cadence**: quarterly review of licences and ownership of the pieces of the quality and catalog
  *stack* (this segment changes owner and licence without changing name); half-yearly
  review of the list of certified assets and of the contracts in force.
- **Mandatory ADR** for: adopting a catalog, adopting a quality tool separate from the pipeline,
  federating ownership, adopting a contract specification, and setting the classification
  tiers.
- **What is governed is deliberately scoped**: define the set of certified assets and
  leave the rest visible but marked as uncertified. Promising governance over the whole
  data estate is the promise that sinks programmes.

**FORBIDDEN**
- ❌ **Buying or deploying a catalog before naming owners.** The canonical inverted sequence.
- ❌ An owner that is a department, a team or "the data area" instead of a person.
- ❌ The platform team appearing as the owner of business data.
- ❌ A data contract that only has a schema, or that does not live versioned in the repository.
- ❌ A contract whose breach breaks nothing.
- ❌ Publishing a freshness SLA with no on-call behind it.
- ❌ Treating "0 rows" as a correct run.
- ❌ Silently correcting data already consumed; closing an incident without communicating to consumers.
- ❌ A quality rule without an owner, without a reason or with tolerated permanent red.
- ❌ More than two assertion severities.
- ❌ Aggregate "quality percentage" as a management metric.
- ❌ Vanity metrics (catalogued assets, glossary terms, rules written).
- ❌ Hand-entered lineage, or presenting a partial lineage as complete and deciding deletions with it.
- ❌ An encyclopaedic glossary; or the same term with two meanings and a single name.
- ❌ Duplicating the **calculation** of a metric in the glossary or in the catalog: the canonical definition belongs
  to `data-warehouse-modeling-standards`.
- ❌ A published asset without classification, or "public" as the default value.
- ❌ A classification that changes no permission: that is labelling, not classifying.
- ❌ Federating ownership without a prior self-service platform or engineering capability in the domain.
- ❌ Calling "data mesh" handing out tables without handing out budget or capability.
- ❌ **Amundsen in new deployments** (no releases since Jun 2025, no commits on `main` since
  Apr 2025).
- ❌ Presenting Unity Catalog OSS as equivalent to Databricks' Unity Catalog.
- ❌ Introducing Soda Core where policy requires an OSI licence (it is **ELv2**, *source-available*).
- ❌ `dbt-expectations` in new projects (unmaintained).
- ❌ Dependencies not pinned by hash/digest, or the `latest` tag, in any environment with
  warehouse credentials (§5.2).
- ❌ Printing offending rows in quality logs.
- ❌ A dataset without declared retention; a raw layer "forever" without a sign-off.
- ❌ A governance committee that only produces slides: if it changes no decisions, it is dissolved.
- ❌ Pinning versions, licences, ownership or adoption figures from memory (§8).

## 8. Mandatory web verification

The data in §2 and §5 is from **August 2026**. Before committing to anything in a deliverable, verify:

1. **Catalogs**: real activity (releases and commits, not the project website) of **OpenMetadata**
   (1.13.x and the state of 2.0), **DataHub** (v1.6.x), **Apache Atlas** (2.6.0 was at rc) and
   **Amundsen** (stalled since 2025 — confirm before discarding it definitively). **Unity
   Catalog OSS**: level at LF AI & Data (it was *sandbox*), API stability and which governance
   capabilities remain exclusive to the Databricks product.
2. **Quality**: **GX Core**'s stewardship by Fivetran after the May 2026 announcement and what it implies for
   the licence and the roadmap; post-acquisition status of **GX Cloud** by FICO; current
   licence of **Soda Core** (ELv2 verified verbatim in its `LICENSE`; check whether it has changed
   again); activity of **Elementary**; and **the licence and positioning of Evidently**.
3. **Supply chain**: before adding **any** package to an environment with warehouse
   credentials, check recent compromises (precedents: `elementary-data` Apr 2026, `trivy`
   Mar 2026, LiteLLM Mar 2026, `durabletask` May 2026) and publications in the last 72 hours.
4. **Contracts**: current version of **ODCS** (as of Aug 2026 the documentation said v3.1.0 and the
   repository v3.0.2 — resolve the discrepancy against the repository, not against a blog), status
   of **ODPS**, and whether harmonisation with the Data Contract Specification has produced anything real.
5. **Data mesh**: whether new evidence has appeared —for or against— beyond vendor material
   and the 2026 retrospectives.
6. **Commercial vendors**: moves by Collibra, Alation, Informatica and Atlan (acquisitions
   and model changes are frequent) and the current edition of the Gartner quadrant if you are going to
   cite it.

**Declared gaps of this revision** (do not fill from memory):
- **Evidently**: **licence not verified raw** (its `LICENSE` was not read) nor its current
  commercial model. Do not claim "Apache 2.0" without checking it.
- **DataHub**: its **formal governance** not verified (whether it is under a foundation or is a company
  project) nor the exact OSS/Cloud split of governance features.
- **OpenMetadata 2.0**: only verified that a `2.0.0-rc1` from Jul 2026 exists; **not verified** whether
  it has reached stable nor whether it brings breaking changes.
- **Soda**: the code's ELv2 licence verified; **not verified** its commercial pricing model
  nor the exact date of the relicensing (secondary sources give 2023, 2024 and Jan 2026 —
  contradicting each other).
- **Collibra / Alation / Atlan / Informatica**: **prices not verified**; the figures going around
  come from comparisons written by competitors. Do not cite amounts.
- **ODCS**: the adoption figures are **self-declared by the project itself**; there is no
  independent data. The number of tools with real import/export support not verified.
- **Apache Atlas 2.6.0**: verified only as a *release candidate*; its final publication not
  verified.
- **Purview, Dataplex and SageMaker/DataZone Catalog** not verified in this revision.

If the web contradicts this document, **the web wins** — flag the discrepancy.
