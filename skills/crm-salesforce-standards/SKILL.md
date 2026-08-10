---
name: crm-salesforce-standards
description: Salesforce and configurable business SaaS - governor limits as an architectural constraint, clicks versus code, and licence cost as a design input. Use when working with Apex classes and triggers (.cls, .trigger), Lightning Web Components (.js-meta.xml, lwc/ directories), Visualforce, Flow Builder and .flow-meta.xml, Process Builder or Workflow Rule end of support and Migrate to Flow, SOQL and SOSL, Apex governor limits (100 SOQL, 150 DML, 10000 ms CPU, 6 MB heap) and bulkification, custom objects and __c / __r fields, record types, validation rules, profiles, permission sets and permission set groups, organization-wide defaults, role hierarchy, sharing rules and Apex managed sharing, WITH USER_MODE, WITH SECURITY_ENFORCED, Security.stripInaccessible and without sharing classes, sfdx-project.json, package.xml, Metadata API, Salesforce CLI (sf project deploy), scratch orgs, unlocked and managed packages, sandbox types and refresh intervals, change sets, AppExchange package due diligence and the security review, Salesforce API request allocations per edition, data and file storage allocations, Sales Cloud or Service Cloud edition pricing, or a Salesforce renewal negotiation.
---

# CRM Salesforce and configurable business SaaS standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Salesforce as a **configurable multi-tenant platform**: the limits it imposes and that are not
negotiable, the criteria for configuration versus code, the data model and its cost, record-level
and field-level security —which is where data leaks—, environment and deployment governance, the
*due diligence* of an AppExchange package, and **the licence and its cost as a design input, not
as a procurement line item**.

Triggers: `.cls`, `.trigger`, `lwc/`, `.js-meta.xml`, Visualforce, Flow Builder, `.flow-meta.xml`,
Migrate to Flow, SOQL/SOSL, governor limits, *bulkification*, `__c`/`__r` objects and fields,
record types, validation rules, profiles, permission sets and permission set groups,
OWD, role hierarchy, sharing rules, `WITH USER_MODE`, `WITH SECURITY_ENFORCED`,
`Security.stripInaccessible`, `without sharing`, `sfdx-project.json`, `package.xml`, Metadata API,
`sf project deploy`, *scratch orgs*, unlocked and managed packages, *sandboxes* and their refresh
interval, *change sets*, AppExchange, API allocation per edition, data and file storage,
editions and renewal.

**Thesis of this skill: in Salesforce you do not choose your architecture, you choose how you live
inside someone else's.** Governor limits, the three-releases-a-year calendar, the sharing model and
the price list are external constants. The whole of design consists of **accommodating them before
building**, because discovering them afterwards does not produce a refactor: it produces a redesign
with data already in production. Corollary that orders this document: **any decision that multiplies
records, API calls, storage or seats is a cost decision**, and cost is estimated at design time,
not on the invoice.

**Not applicable**: see `api-design-standards` (**hard boundary**: the integration **contract** —
OpenAPI, versioning, pagination, `Idempotency-Key`, error format, webhook signature. Here only
**how much that contract consumes of your allocation** and which platform limit breaks it),
`identity-access-management-standards` (SSO/SAML/OIDC, MFA, SCIM provisioning,
joiner-mover-leaver lifecycle. Here the **authorisation inside the org** —profiles, permissions,
sharing— which is a different thing: who gets in is theirs, what they see once inside is
ours), `cicd-standards` (the *pipeline*, its *gates*, OIDC and artifact signing. Here **what is
deployed and from where**, and why a change in production is the platform's original sin),
`privacy-engineering-standards` (**declared reciprocal, in constant use**: the obligation to
minimise, retain and delete, the DSAR and the anonymisation of non-production environments. Here,
**its implementation on this platform** and the fact that storage is a growing line item),
`data-governance-quality-standards` (data ownership, catalogue, quality dimensions),
`data-platform-standards` and `analytics-bi-standards` (analytics outside the CRM; getting data out
of the CRM into a warehouse is almost always the right answer, and its design is theirs),
`opensource-licensing-standards` (free software licences; here **commercial SaaS** licensing),
`erp-sap-standards` (**reciprocal of the block**: there the ERP as system of record and its
per-document licensing — and beware, **a CRM that creates orders in an SAP triggers indirect
access**: that decision is assessed there before it is built here), `appsec-standards` (threat
methodology and triage), `testing-qa-standards` (general test strategy), `frontend-frameworks-standards` (LWC
uses web standards, but its lifecycle and its limits belong to this platform),
`ai-governance-standards` (governance of the agents and copilots deployed on top of the CRM).

## 2. Default decisions

> Verify on the web before committing to it (§8): Salesforce limits, editions, prices and product
> names **change every release** (three a year) and prices went up in 2025.

| Decision | Default | Justifiable alternative |
|---|---|---|
| New automation | **Flow** (record-triggered), one per object and per context | Apex if there is logic Flow cannot express or it requires serious unit tests |
| Logic in a trigger | **One trigger per object**, delegating to a handler class | Never several triggers on the same object |
| Query and DML | **Always in bulk** (outside loops), no exceptions | None |
| Apex execution mode | **User mode** (`WITH USER_MODE` / `AccessLevel.USER_MODE`) | Explicit `SYSTEM_MODE`, documented and reviewed |
| Default sharing | **OWD `Private`** and open up with permissions/rules | `Public Read` only if the data is not sensitive and it is justified |
| Permission assignment | **Permission sets and groups**; minimal profile | The profile as a permission container is legacy |
| New UI | **LWC** | Visualforce only to maintain what exists |
| Deployment | **Metadata in version control + Salesforce CLI** | *Change sets* only as a recorded emergency patch |
| Internal packaging | **Unlocked packages** with explicit dependencies | Loose metadata if the domain is small and clear |
| Development environment | *Scratch org* or Developer sandbox per person | Sharing a development sandbox is a source of collisions |
| UAT environment | **Partial Copy** with template and masked data | Full only for final regression and load testing |
| Historical data and analytics | **Outside the org**, in the warehouse | Inside only if the operational process needs it |

## 3. Structure and conventions

### 3.1 Governor limits: an architectural constraint, not a detail

Verified in the *Apex Developer Guide* (Aug 2026, §8). **Per transaction**:

| Limit | Synchronous | Asynchronous |
|---|---|---|
| SOQL queries issued | **100** | **200** |
| Records retrieved by SOQL | **50,000** | 50,000 |
| DML statements | **150** | 150 |
| Records processed by DML | **10,000** | 10,000 |
| CPU time | **10,000 ms** | **60,000 ms** |
| *Heap* size | **6 MB** | **12 MB** |
| Outbound calls (callouts) | 100 | 100 |
| Cumulative callout timeout | 120 s | 120 s |
| `sendEmail` | 10 | 10 |
| Maximum transaction duration | 10 min | 10 min |
| Recursive trigger stack depth | 16 | 16 |

**What this forces, and it is the whole consequence:** the trigger does not run once per record,
it runs **once per batch**. All code is written assuming 200 input records:
- **No query or DML inside a loop.** It is the cause of 90 % of limit exceptions.
- Collections (`Map`, `Set`) to relate in memory instead of querying per record.
- **No recursion without a guard**: a trigger that updates the same object re-enters.
- What does not fit in one transaction goes **asynchronous** (`Queueable`, Batch) **by design from
  the start**, not as a patch when it blows up. Converting synchronous into asynchronous late
  changes the semantics visible to the user.
- **The CPU limit is the one that surprises most**: it is not consumed by the database, it is
  consumed by nested loops and by chains of *flows* and chained triggers. A CPU limit exhausted in
  production and not in the sandbox usually means **data volume**, not a code change.
- **Tests must exercise volume**: a test with one record proves nothing about the limit.
  Mandatory test with 200 records for any trigger or record-triggered flow.

### 3.2 Clicks or code: the honest criteria

A false, badly posed debate. The criteria is not "declarative whenever possible" but **who will be
able to understand it and change it three years from now, and with what safety net**.

| Choose **configuration** when | Choose **code** when |
|---|---|
| The logic fits into a decision with few branches | There is complex logic, real loops or an algorithm |
| The functional owner needs to change it without deploying | You need unit tests with serious assertions |
| There is no bulk performance requirement | You process thousands of records or consume CPU |
| The behaviour is visible and auditable in the UI | Fine-grained error handling and transactionality are needed |

**What the declarative side costs and almost nobody accounts for:**
- **The debt of the flow nobody knows exists.** A Flow does not show up in a `grep`, nobody reviews
  it in a PR if it is not in the repository, and it fires from any record change.
  Five flows on the same object produce an execution order **nobody can reason about**.
  Hard rule: **declarative metadata lives in version control just like code**, and every
  Flow has a description, an owner and a reason. An active Flow without an owner is deactivated.
- **The declarative chain is CPU.** Flows that trigger each other exhaust the same limit as Apex,
  and the resulting error points at a place that is not the cause.
- **Legacy already out of support**: Salesforce **ended support for Workflow Rules and Process
  Builder on 31 Dec 2025**. It is not a retirement —what is active keeps running— but **there is no
  support and no fixes**, and new ones can no longer be created. Treat migration to Flow as
  **urgent technical debt past its due date**, not as a maintenance task. Beware of legacy
  automations **inside managed packages**: you cannot edit them; the vendor has to migrate them, and
  that is a point in the *due diligence* of §3.6.

**Cross-cutting golden rule**: if the declarative solution requires fifteen steps, two subflows and
an unreadable formula, it is no longer declarative: it is code written with the mouse, and untested.

### 3.3 Data model and its cost

- **Standard objects before custom ones.** A `__c` object that duplicates `Opportunity` loses
  reports, forecasts, mobile apps and everything the platform gives for free.
- **Object, field and relationship limits depend on the edition** and are hard: verify them
  before designing (§8). A model that does not fit in the contracted edition is not a budget
  problem, it is a redesign.
- **Master-detail versus lookup relationships**: the former inherits sharing and cascade delete — it
  is a **security and lifecycle** decision, not a modelling one. Changing it with data loaded is
  expensive.
- **Formula and roll-up fields**: they are evaluated on the fly and consume; a report over
  cross-referenced formulas is the usual cause of a timeout nobody can explain.
- **Storage as a growing line item, and it is the cost that surprises:** allocation (verified,
  Aug 2026, secondary source — §8) of **10 GB of data per org** plus **20 MB per user**, and
  **10 GB of files per org** plus **2 GB per licence** in Enterprise/Performance/Unlimited. A
  record counts ~**2 KB** regardless of how full it is. Consequences:
  - **Activity history, emails and audit fields are what fill the org**, not business
    data. Ten million activity records are ~20 GB you pay for every year.
  - **Archiving and retention policy from day one**, with a destination outside the org and
    scheduled deletion. Without it, cost grows monotonically and is only discovered at renewal.
  - **Attachments**: the default pattern is to store the file outside (object storage) and keep
    the reference, unless there is an explicit requirement.

### 3.4 Security: this is where data leaks

**A layered model, and you have to understand that they add up:** organisation → object
(profile/permissions) → field (FLS) → record (OWD, roles, sharing rules) → code.

- **OWD `Private` by default** and it is opened upwards with the role hierarchy, sharing rules
  and manual sharing. Starting open and closing later is impossible in practice: nobody knows
  who depended on what.
- **Profiles to the minimum, everything else in permission sets and permission set groups.** The
  profile as a container for everything produces N nearly identical profiles nobody can audit.
- **Permissions reviewed one by one, always**: `Modify All Data`, `View All Data`,
  `Author Apex`, `Manage Users`, `Customize Application`, `API Enabled`, report export.
  Each one is a complete exfiltration path. A named list of who has them, reviewed
  quarterly.
- **Apex and security — the big change of 2026, verbatim from the documentation**: *"In API version
  67.0 and later, Apex runs in user context by default, meaning that the current user's permissions
  and field-level security (FLS) are enforced during code execution. In API version 66.0 and earlier,
  system mode is the default."* Operational consequences, and there are two in opposite directions:
  1. **New code**: it is written in user mode, full stop. `SYSTEM_MODE` is an explicit exception,
     commented with the reason and reviewed by someone else.
  2. **Existing code**: raising the API version of an old class **may break it** as FLS and sharing
     start being enforced. Raising the API version is a functional change, **it gets tested**.
- **`WITH USER_MODE` versus `WITH SECURITY_ENFORCED`**: the latter is the old mechanism and has
  known holes — **it only applies to the `SELECT` and `FROM` clauses**, so a field with no
  access used in `WHERE` or `ORDER BY` **does not error out**, and it does not cover DML. By
  default: **`WITH USER_MODE`**, which also respects restriction and scoping rules.
  `Security.stripInaccessible` when the requirement is to **degrade** (strip the inaccessible fields
  and carry on) instead of failing.
- **`without sharing`** only with justification written in the code itself. A `without
  sharing` class invoked from a component accessible to any user is a textbook IDOR.
- **Public sites and Experience Cloud**: the guest user is the classic vector for massive
  leaks. Its permissions and its OWD are reviewed separately and under a magnifying glass; any
  object accessible to the guest user is declared and justified.
- **SOQL with string concatenation** (`Database.query`) without `String.escapeSingleQuotes` or a
  *bind* is SOQL injection. Methodology in `appsec-standards`; here the veto (§7).
- **Personal data**: the CRM is, by definition, a store of personal data. Retention, deletion
  and DSAR are designed from the start (crosses with `privacy-engineering-standards`) and **reach
  the sandboxes**: a Full copy of production in a test environment is a breach with a name.

### 3.5 Environments and deployment: the original sin

**Changing directly in production is the platform's structural failure mode**, because the
platform allows it and makes it convenient. The consequence is not that something breaks today: it
is that **nobody can reconstruct how the org reached its current state**, and from then on no lower
environment represents reality.

Rules:
- **The source of truth is the repository**, not the org. Metadata in git, reviewed in a PR —
  including the declarative kind (§3.2).
- **Production is read-only for humans** except for a closed and documented set of changes
  (operational parameters, users). Everything else arrives deployed.
- **Emergency exception**: it exists, it is recorded with reason and author, and **it is returned to
  the repository within 24 h**. An unreconciled *hotfix* is a permanent divergence.
- **Sandbox types and their real constraint** (verified, Aug 2026 — secondary source, §8):

  | Type | Storage | Data | Minimum refresh |
  |---|---|---|---|
  | Developer | 200 MB | Metadata only | 1 day |
  | Developer Pro | 1 GB | Metadata only | 1 day |
  | Partial Copy | 5 GB | Sample by template | 5 days |
  | Full | Same as production | All records and attachments | **29 days** |

  **The Full sandbox's 29-day interval is a planning constraint, not a detail**: if your release
  plan needs a freshly refreshed Full twice a month, your plan is not executable. And the Full
  is the **only** valid environment for performance and load testing, as well as a cost line item
  of its own (it is usually sold separately or comes counted per edition).
- **Data in non-production**: Partial Copy with a template and **masked**. Copying all of production
  into UAT "to test properly" is the practice that turns a test into a privacy incident.
- **Unlocked packages** to modularise your own metadata with explicit dependencies; *change
  sets* only as a recorded patch. The mechanics of the pipeline belong to `cicd-standards`.

### 3.6 AppExchange: a managed package runs with your data

Installing a managed package is **granting execution inside your org to code you cannot read**.
Salesforce says so bluntly in its own documentation (verbatim): *"Notwithstanding any security
review of a Partner Application, Salesforce makes no guarantees regarding the quality or security of
any Partner Application."* The security review is a condition for publishing, **not a guarantee
for you**.

Minimum list before installing, and none of it is optional:
1. **What permissions it asks for** and what objects it touches. If it asks for `Modify All Data`,
   the default answer is no.
2. **Whether it makes outbound calls**, where to and with what data. Authorised remote sites,
   reviewed.
3. **What it consumes**: API calls, storage, custom object and field limits — which
   are finite per edition and **the package spends them out of your allocation**.
4. **The state of its legacy automations** (Workflow/Process Builder unsupported since
   Dec 2025): you cannot touch them yourself.
5. **Exit**: what is left after uninstalling, where the data it created goes and whether you take it
   with you.
6. **Vendor viability** and its calendar against Salesforce's three annual releases.
7. **Install in a sandbox first**, always, with a review of what shows up in the org.

### 3.7 Licence and cost: renewal is the only moment to negotiate

- **The API allocation is per edition and per licence** (verified, Aug 2026): Enterprise and
  Professional with API access, **1,000 calls per licence**; Unlimited and Performance, **5,000**;
  total = **100,000 + (licences × calls per type) + purchased add-ons**. Developer Edition,
  **15,000**. Full sandbox, **5,000,000**. **Concurrency**: 25 concurrent long-running requests in
  production and sandbox, 5 in Developer/trial.
  - **Design consequence**: an integration that polls every minute consumes ~43,200 calls/day
    **from your shared allocation**, and when it exhausts it **all integrations fail, not just the
    guilty one**. By default: events and bulk APIs (Bulk/Composite) over per-record polling.
    The concurrency limit also forces you to bound long queries: 25 is not a big number.
- **Editions and price**: Salesforce's public list changes and **went up in 2025**. As of Aug 2026,
  secondary sources put Sales Cloud at Starter Suite $25, Pro Suite $100, Enterprise $175,
  Unlimited $350 and the top tier (Agentforce 1 Sales, formerly Einstein 1) $550 per user per month
  billed annually. **`salesforce.com` returned 403 to automated verification: treat it as an
  order of magnitude and confirm it on the official page before using it (§8).** Many pages still
  quote the previous list ($165/$330): **a figure without a date is a useless figure**.
- **What is not in the per-seat price** and has to be budgeted separately: additional sandboxes
  (notably the Full one), additional API calls, storage above the allocation,
  higher support plans (a percentage of the net licence), and the licences for
  AppExchange packages.
- **Renewal is the only moment with real leverage.** Prepare it **six months ahead**, with:
  an inventory of seats **actually used** (login in the last 90 days), licence types
  matched to the job, measured API and storage consumption, and a list of contracted modules
  nobody uses. Without that data, renewal is accepting the vendor's proposal.
- **Audit of your own usage, quarterly**: inactive seats, administrative permissions, installed
  packages, active integrations. In SaaS cost does not grow by decision, it grows by accumulation.

## 4. Quality and verification

In order of increasing cost; the first three are gates that break the build:
1. **Static analysis** with Salesforce's code scanner (Code Analyzer / PMD with the Apex
   ruleset) over hard rules: DML or SOQL in a loop, unjustified `without sharing`, dynamic SOQL
   without escaping, absence of assertions.
2. **Apex tests with real assertions.** The **75 % coverage minimum to deploy is a platform
   threshold, not a quality goal**: a test without an `Assert` covers lines and checks nothing.
   `SeeAllData=true` is forbidden (§7); the test creates its data.
3. **Mandatory bulk test**: 200 records per trigger and per record-triggered flow. A one-record
   test says nothing about the limits of §3.1.
4. **Negative permission test**: run as a restricted-profile user (`System.runAs`) and
   check that it does **not** see what it must not. It is the only test that detects the leak of §3.4.
5. **Deployment validated against a Full sandbox** before production, with the local test suite.
6. **End-to-end business process regression** on each of Salesforce's **three annual
   releases**: the update arrives whether you are ready or not. The sandbox
   *preview* window exists for this and gets used.

## 5. Stack security

Covered in §3.4 (permission model and execution mode) and §3.6 (packages). Additions:
- **Event logging and monitoring**: report exports, bulk downloads and API accesses
  are watched. Typical exfiltration is not an exploit: it is a legitimate user exporting a
  complete report. It requires a specific edition/add-on — verify what yours gives you.
- **Integration accounts**: one per integration, with a minimal permission set, no user
  interface and with credentials in a secrets manager. Never a human administrator's account.
- **IP restriction and session policies** for administrative and integration profiles.
- **The administrator account is a priority target**: mandatory MFA, minimum number of
  administrators, named review. Identity detail in `identity-access-management-standards`.
- **Secrets in metadata**: forbidden. Not in formulas, nor in visible custom settings,
  nor in Flows. Named Credentials and Protected Custom Metadata.

## 6. Performance and operability

- **Performance depends on data volume, not on code**: an object with millions of records
  degrades reports and queries. It is designed with **indexes** (unique, external, standard
  `Salesforce` fields) and controlled **ownership skew** (many records with the same owner degrade
  the sharing calculation).
- **Archiving**: the policy in §3.3 is also a performance policy.
- **Errors in integrations**: retry with backoff and **backpressure**. A client retrying in
  a loop against the API limit locks the rest of the company out.
- **Observability**: platform status is published by the vendor and has to be consumed; your part
  is measuring your integrations' errors, API allocation consumption and storage **with an alert
  before the threshold**, not when it is already failing.
- **Exit**: periodic and tested export of data and metadata out of the platform. An
  export that has never been restored anywhere is not an exit, it is a file.

## 7. Sustainability and prohibitions

- ❌ **FORBIDDEN** SOQL or DML inside a loop. No exceptions.
- ❌ **FORBIDDEN** more than one trigger per object, and triggers with logic inside them.
- ❌ **FORBIDDEN** `@isTest(SeeAllData=true)` and tests without assertions. The 75 % coverage is a
  platform toll, not a quality measure.
- ❌ **FORBIDDEN** `without sharing` without justification written in the code itself and reviewed.
- ❌ **FORBIDDEN** dynamic SOQL with concatenated input without escaping or a *bind*.
- ❌ **FORBIDDEN** changing configuration or metadata **directly in production** outside the closed
  and documented set, and forbidden to leave a *hotfix* unreconciled with the repository.
- ❌ **FORBIDDEN** copying production into a sandbox without masking personal data.
- ❌ **FORBIDDEN** installing an AppExchange package directly in production or without the list in
  §3.6. Salesforce's security review **is not a guarantee**, and they say so in writing.
- ❌ **FORBIDDEN** creating a custom object that duplicates a standard object without a recorded
  decision.
- ❌ **FORBIDDEN** granting `Modify All Data` or `View All Data` for convenience, and forbidden for an
  administrative profile to lack MFA.
- ❌ **FORBIDDEN** a per-record polling integration when a bulk API or an event exists.
- ❌ **FORBIDDEN** leaving an active Flow without an owner, without a description and outside version
  control.
- ❌ **FORBIDDEN** quoting a Salesforce price without a date and without a source: the list changed in
  2025 and half the internet quotes the previous one.
- **Cadence**: the **three annual releases** are mandatory and are not postponed — each has a
  *preview* window in a sandbox that is used for the regression in §4. Quarterly review of seats,
  administrative permissions, installed packages and active integrations. Contract review **six
  months before** renewal.
- **Debt characteristic of the domain**: the org that accumulates fifteen years of configuration by
  people who are no longer there. It is fought with a single discipline — **nothing active without a
  named owner**: no Flow, no field, no report, no integration, no package. What has no owner is
  deactivated after notice, and what is deactivated and nobody claims within a quarter is deleted.

## 8. Mandatory web verification

Before committing to any datum in this document:

1. **Governor limits**: the table in §3.1 was verified verbatim in the *Apex Developer Guide*
   (`developer.salesforce.com`, `apex_gov_limits.htm`). **Revalidate per release**: Salesforce publishes
   three a year and limits per edition vary.
2. **Default execution mode**: the v67.0 quote comes verbatim from
   `apex_classes_perms_enforcing.htm`. Verify the API version of **your** classes before assuming
   which mode applies.
3. **API and storage allocations**: the API allocation was verified in the *Salesforce Developer
   Limits Cheat Sheet*. **The storage allocation and the sandbox table in §3.3 and §3.5
   come from matching secondary sources** —`help.salesforce.com` could not be retrieved in an
   automated way (JavaScript-rendered page)—: **declared gap**, confirm them in the official
   help or in your own org's Setup, which is the definitive source.
4. **Prices and editions**: **declared gap** — `salesforce.com/sales/pricing` returned **403** to
   automated verification in Aug 2026; the figures in §3.7 come from secondary sources
   later than the 2025 increase. **The only price that applies to you is the one in your contract**, and
   discounts are not published.
5. **End of support and retirements**: Workflow Rules and Process Builder (31 Dec 2025) and any
   retirement announced in the notes of the current release. Also check which API versions
   are marked as retired: Salesforce retires old versions and that **breaks integrations**.
6. **Product names and packaging**: Salesforce renames frequently (Einstein 1 →
   Agentforce). Verify the exact name before writing it into a contract or a document.
7. **Release notes** for the three deliveries of the year, for new limits, changes to security
   defaults and features that change edition.

If the web contradicts this document, **the web wins** — flag the discrepancy.
