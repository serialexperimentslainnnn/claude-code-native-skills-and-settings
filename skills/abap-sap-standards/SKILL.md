---
name: abap-sap-standards
description: ABAP custom development inside SAP ERP - the clean core decision and the S/4HANA clock. Use when working with .abap sources, SE38 reports, SE80 / SE24 / SE11 repository objects, ADT (ABAP Development Tools for Eclipse), ABAP Cloud and the ABAP for Cloud Development language version, released APIs and C0/C1 release contracts, CDS view entities (DEFINE VIEW ENTITY), AMDP methods marked with AMDP_MARKER_HDB, RAP behavior definitions and projections, SEGW and OData service exposure, BAdI / user exits / enhancement points / implicit enhancements / modifications with SSCR key, packages and transport requests (SE09, SE10, STMS, $TMP), abapGit, ATC and Code Inspector variants such as SAP_CP_READINESS_REMOTE, ABAP Unit and CL_ABAP_UNIT_ASSERT, AUTHORITY-CHECK and authorization objects, SY-SUBRC handling, native SQL via EXEC SQL or ADBC, SELECT inside LOOP and other performance antipatterns, SNOTE and SAP Security Notes, or assessing what a S/4HANA move breaks in custom ABAP code.
---

# ABAP development standards in SAP

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Custom code inside an SAP ERP: classic ABAP and ABAP Cloud, repository objects, transports,
performance on HANA, extensibility and the exit route towards S/4HANA. Triggers: `.abap`,
ADT/Eclipse, SE38/SE80/SE24/SE11, `DEFINE VIEW ENTITY`, AMDP, RAP, SEGW/OData, BAdIs and
*enhancements*, SE09/SE10/STMS, abapGit, ATC/SCI, ABAP Unit, `AUTHORITY-CHECK`, `EXEC SQL`, SNOTE.

**The axis: ABAP is not a language you choose, it is the language of the ERP you already have.**
Nobody starts a new project in ABAP on its technical merits; you write ABAP because the logic lives
inside an SAP the company already pays for. Everything else follows from that: **no technical
decision here is independent of SAP's maintenance calendar**, and that calendar is set by a vendor
with a commercial interest in you moving. Verified data (Aug-2026, sources in §8):

- **SAP Business Suite 7 / SAP ERP 6.0 (ECC)**: *mainstream* maintenance until **2027-12-31**, and
  mind the nuance that falls out of almost every slide deck: that date is **for EhP 6-8**; with
  **EhP 1-5 maintenance already ended on 2025-12-31**. An ECC on EhP5 today **is already out**.
- **Optional extended maintenance 2028-2030**, with a surcharge of **+2 percentage points** on the
  maintenance base. Whoever does not contract it moves **automatically** to *Customer-Specific
  Maintenance* (with an active support contract), which **is not the same thing**: corrections on
  what is already known, without the commitment to deliver new legal/regulatory changes — and in an
  ERP that detail is what decides, because payroll and taxes change by law every year.
- **The date has already moved once**: Suite 7's *mainstream* was 2025 and SAP moved it to 2027 in
  the announcement of **2020-02-04**, the same one that set the S/4HANA commitment through 2040. The
  trade press and analysts agree in Aug-2026 that **there will be no further extension**; that is a
  forecast, not a written commitment: **do not plan counting on it in either direction**.
- **S/4HANA**: the "until 2040" is an **innovation commitment**, not the lifetime of your release:
  SAP commits that **there will always be at least one release under maintenance** until the end of
  2040. Since the **2023 release** the cadence is **one major release every two years** (2023 → 2025
  → 2027 planned) with half-yearly *feature packs* and **7 years of mainstream per release**
  (previously 5): 2023 until the end of **2030**, 2025 until the end of **2032**. Being "on S/4HANA"
  does not take you off the clock: it puts you on a different one.
- **Compatibility Packs** (ECC functions temporarily usable in S/4HANA): on-premise they expired on
  2025-12-31 and SAP extended them to **2026-05-31** — announcement of Dec-2025, declared *final*;
  under **RISE / SAP Cloud ERP Private** the right of use runs to **2030-12-31** (note 2269324). It
  is a right of use, not a technical block: **the transaction still starts after expiry**, and that
  is where the audit trap lies.
- **Naming trap**: since Sapphire 2025, **"SAP Business Suite" designates the umbrella of the cloud
  offering**, not the Business Suite 7 that expires in 2027. In a document, always write the version.

**Not applicable**: `erp-sap-standards` (**SAP as a company decision**: maintenance calendar,
RISE/GROW and deployment model, licensing, indirect access and the annual audit, master data
governance. **Arbitration in one line: *if it is written into a repository object it belongs to
ABAP; if it is signed in a contract or declared in a licence measurement, it belongs to ERP***).
`legacy-modernization-standards` is the block's umbrella, `migration-projects-standards` the
execution of the cutover to S/4HANA (rehearsal, window, data reconciliation, coexistence, rollback
and shutting down the source ECC) and `enterprise-architecture-standards` (**already written**)
provides the inventory, the TIME model and the modernisation "R"s — here only what each option
implies **technically** inside SAP. The database and the SQL language belong to
`oracle-dba-standards`, `sqlserver-dba-standards` and `sql-standards` (**already written**), and
analytics outside the ERP to `data-platform-standards`, `data-engineering-standards` and
`analytics-bi-standards`; here SQL only as ABAP SQL and *code pushdown*. *Side-by-side*
developments on BTP are written in Java/Node/Python and their quality is governed by
`jvm-spring-standards`, `typescript-standards` and `python-standards` (**already written**), with
`api-design-standards` for the contract and `microservices-architecture-standards` for the split.
Security methodology and triage in `appsec-standards` and `vulnerability-management-standards`
(**already written**) — here only ABAP's concrete *sinks* —, identity in
`identity-access-management-standards`, and process in `refactoring-tech-debt-standards`,
`testing-qa-standards`, `cicd-standards`, `git-workflow-standards`, `project-management-standards`,
`tech-leadership-standards` and `grc-compliance-standards` (**already written**). Sister skills of
the legacy block: `mainframe-zos-cobol-standards`, `ibm-i-rpg-standards`,
`plsql-oracle-forms-standards`, `classic-asp-standards`, `vb6-standards`,
`dotnet-framework-legacy-standards`. **They share the "legacy" label and little else.**

## 2. Default decisions

> Verify on the web before fixing it (§8): SAP's calendar and the *clean core* model move.

| Decision | Default | Note |
|---|---|---|
| Extensibility model | **Clean core**: extension via released API, never modification | §3; it is *the* structural decision |
| Language version for new code | **ABAP for Cloud Development** (ABAP Cloud) | Standard ABAP only with a written justification |
| Development tool | **ADT (Eclipse)** | It is the **only** one possible for ABAP Cloud; SE80 only for classic work |
| Programming model | **RAP** for new services and applications | SEGW/BOPF/Dynpro = maintenance, not a destination |
| Data access | **CDS view entity** + ABAP SQL; AMDP only where CDS cannot reach | `SELECT *` and `SELECT` in a loop: forbidden (§6) |
| Version control | **abapGit** (MIT, verified raw) on top of the transport, not instead of it | §3: it does not replace STMS |
| Quality | **ATC** with a corporate variant, blocking on transport release | §4 |
| Patching | **SAP Security Patch Day: the second Tuesday of every month** | A monthly cycle with an allocated window, not "whenever" |
| Logic that is not the ERP's | **Outside the ERP** (§7) | The ERP is not your general-purpose application server |

## 3. Clean core, repository and transport

**The decision that dominates everything: where the extension lives.** Three places, in order of
preference:

1. **Clean on-stack (ABAP Cloud)**: code in the system itself, in `ABAP for Cloud Development`,
   consuming **only APIs released** by SAP with a stability contract. It is what survives an
   *upgrade* untouched.
2. **Side-by-side on BTP**: a separate service talking to the ERP over OData/a released API. The
   right choice when the logic is not core ERP, when it needs its own lifecycle or when its natural
   language is not ABAP.
3. **Classic on-stack (Standard ABAP)**: where the above cannot reach. **It is declared debt**, with
   an owner and a review date, not a technical tie.

**And one that is not on the list: modifying the core.** Touching an SAP object (a modification with
an SSCR key, an *implicit enhancement* in standard code, copying a standard program into the Z
namespace) is exactly what makes it **impossible to upgrade**: every *upgrade* or *support package*
forces you to reconcile every modification by hand (SPAU/SPDD), at a cost that grows over time and
that in S/4HANA conversions is the line item that derails the project. **Extending at the point SAP
offers (BAdI, event, *extension point*, released API) is reversible; modifying is not.**

**Status of the model as of Aug-2026 — a fact that corrects the usual assumption**: the well-known
**3-*tier* model** (tier 1 ABAP Cloud / tier 2 *wrapper* / tier 3 classic ABAP) **was replaced in the
Aug-2025 update of the *ABAP Extensibility Guide*** by a model of **clean core levels (A, B, C, D)**,
which broadens the available APIs and reduces the need for *wrappers*. Operational criterion, stable
under both models: **always extend at the highest possible level**, and an extension is worth **the
worst technology it uses inside**. Verify the current definition of each level before writing it into
an internal standard (§8).

**A wrapper as a bridge, not as a destination**: if the API you need is not released, the supported
pattern is to wrap the unreleased object in an object of your own and consume the *wrapper* from the
restricted code, **asking SAP to release it** (Customer Influence) and **deleting the wrapper when it
arrives**. A *wrapper* with no release ticket and no date is debt disguised as a pattern.

**Repository and transport: why the lifecycle does not look like Git.** The ABAP object lives in the
system's database, not in files; it is organised into **packages** (`$TMP` = local, not
transportable: nothing productive can stay there) and moves between environments DEV → QAS → PRD
inside **transport requests** along the route STMS defines. Consequences you have to accept:

- Locking is **pessimistic and per object**: two people do not edit the same object at once. There
  are no branches, there is no *merge*; the "conflict" is resolved by taking turns.
- **What gets promoted is the request, not the commit.** If the request goes out incomplete — a
  dependent object is missing — the target ends up broken and the diagnosis arrives in the wrong
  environment.
- **Import order matters**: two requests out of sequence overwrite each other.

**abapGit** (licence **MIT**, verified by reading the raw file) exports and reimports repository
objects as files, and that enables code review on a Git server, readable history, a real *diff* and
branch testing. **What it does not do: replace the transport.** Going to production is still the
transport request, and **using abapGit as the deployment mechanism to PRD decouples the system from
the change record the audit expects**. Correct use: Git as the source of truth for reviewing and
sharing, STMS as the promotion mechanism; both, not one.

## 4. Quality and testing

- **ATC (ABAP Test Cockpit)** with a **single, versioned corporate variant**, run locally before
  releasing and as a **blocking check on transport request release**. Without that hook, ATC is a
  report nobody reads.
- ***Clean core* checks**: the variant must include the ABAP Cloud/released API ones — the global
  Code Inspector variant **`SAP_CP_READINESS_REMOTE`** verifies the `ABAP for Cloud Development`
  scope and flags *"Usage of not released API"* and syntax errors outside the restricted scope. It is
  the tool that turns "we want clean core" into a number.
- **ABAP Unit** (`CL_ABAP_UNIT_ASSERT`) for new logic. **The real difficulty, said without
  decoration**: legacy ABAP is practically untestable — logic in report programs with embedded
  `SELECT`s, global state, Dynpro dependencies and dependencies on specific customer data. It is not
  fixed by writing tests over that, but by **extracting the logic into classes with injected
  dependencies** and testing the class; for the rest, **characterisation before touching**
  (`testing-qa-standards`). RAP/EML test doubles and
  `CL_OSQL_TEST_ENVIRONMENT`/`CL_CDS_TEST_ENVIRONMENT` let you test against simulated data without
  depending on the system's content: use them or the test is a report on the state of the client.
- **Coverage as a signal, not a goal** — and prioritise: payroll, invoicing, taxes and any
  calculation that appears on a legal document come first.
- **CI**: there is no comfortable "native" pipeline, but there are real levers — ATC via API or
  `abapLint` over the repository exported with abapGit, and scheduled ABAP Unit runs. The minimum
  gate: **syntax + priority 1 ATC + ABAP Unit of the touched package**, and no request is released
  with open priority 1 findings.

## 5. Security

- **Authorisations**: the check is explicit and **a program that does not call `AUTHORITY-CHECK` has
  no access control**. Hard rule: `AUTHORITY-CHECK` **immediately followed by evaluating `SY-SUBRC`**
  (`IF sy-subrc <> 0` → exit); an `AUTHORITY-CHECK` whose result is not looked at is worse than none,
  because it looks like control. A custom authorisation object for custom functionality, and never
  `SAP_ALL` nor a wildcard role "to make it work".
- **`SY-SUBRC` in general**: after `SELECT`, `CALL FUNCTION`, `READ TABLE`, `OPEN DATASET` and
  `AUTHORITY-CHECK`. Ignoring it produces execution with empty or partial data — and in an ERP that
  is a badly posted accounting entry, not a visible exception.
- **Injection in native SQL and in dynamic statements**: ABAP SQL with *host* variables is safe; the
  risk lies in **`EXEC SQL`/ADBC with a concatenated query**, and in dynamic clauses (`WHERE
  (lv_cond)`, `SELECT (lv_fields)`, dynamic table). Rule: **no user input in a dynamic clause**; the
  dynamic part is built from a **closed allowlist** of fields and operators, and values go **always**
  through a *host* variable. The same for `CALL TRANSACTION`, executing programs by name and file
  access with a path derived from input.
- **Execution and files**: `OPEN DATASET`/`CALL 'SYSTEM'` with paths or commands derived from input
  are arbitrary execution on the application server. Path validated against an allowlist and a file
  authorisation check (`S_DATASET`).
- **SAP security notes as a process, not as an isolated ticket**: **SAP Security Patch Day on the
  second Tuesday of every month**; the minimum process is to review the month's notes, assess
  applicability by component, apply via SNOTE in DEV and transport with the same rigour as a
  development, with an SLA per criticality. Notes are released **outside** patch day: the process
  must absorb them.
- **External surface**: RFC, ICF services and the *gateway* are the door through which real attacks
  on SAP come in. Disable the ICF services that are not used, RFC destinations without stored dialog
  user credentials, `reginfo`/`secinfo` closed, and **the system never directly exposed to the
  internet**. Secrets outside the code (`secrets-management-standards`).
- **Personal data**: non-production systems are **anonymised** — copying production into a
  development environment with real payroll data is an incident waiting to happen.

## 6. Performance

**There is one golden rule: the computation happens where the data is (*code pushdown*).** Bringing
millions of rows to the application server to filter them in ABAP is the dominant mistake in this
ecosystem, and on HANA it is even more expensive in relative terms. Order of preference: **CDS view
entity** (declarative aggregation, *join*, filtering, reusable and consumable by OData) → **AMDP**
only when procedural logic is needed in the engine (and accepting that it ties the code to HANA) →
well-written ABAP SQL → logic in ABAP as a last resort.

Classic antipatterns, all grounds for rejection in review:

- **`SELECT` inside a `LOOP`** — the most expensive and the most frequent. It is replaced by `FOR ALL
  ENTRIES` (with the base table **checked as non-empty**, or it deletes the condition and reads the
  whole table) or, better, by a *join*/CDS that brings the set in one go.
- **`SELECT *`** when three fields are used: over columnar storage it is a direct waste. An explicit
  field list, always.
- **`SELECT ... ENDSELECT`** and row-by-row reads: `INTO TABLE` and process in memory.
- **Internal tables without the right key**: `READ TABLE ... WITH KEY` over a **standard** table is a
  linear search; inside a loop it is quadratic. Choose the type (`SORTED`/`HASHED`) or declare
  secondary keys according to the access pattern, and use `WITH TABLE KEY`/`BINARY SEARCH` with the
  table sorted. It is the second cause of programs that "suddenly" take hours when the data grows.
- **Filtering or aggregating in ABAP what the database knows how to do**; and `SELECT` with no
  `WHERE` over document tables.
- **Absence of block processing** in bulk loads: packages with a bounded `COMMIT WORK`, not a
  transaction lasting hours nor a `COMMIT` per record.

Measurement before intuition: SQL Trace (ST05), ABAP Trace (SAT/SE30), ST12 and HANA's performance
analysis. **No performance change is declared done without a measurement before and after.**

## 7. Sustainability, exit and prohibitions

**When a development should NOT be in the ERP** — an honest criterion, because the team's reflex is
to put it inside: if it neither consumes nor produces ERP master data or documents; if its lifecycle
is faster than the ERP's; if it needs to scale or be exposed to external users; if its natural
language is not ABAP (analytics, integration, portals, anything with its own front end). All of that
goes **side-by-side**, and its quality is governed by the target language's skills, not this one.

**When it does stay inside**: transactional logic coupled to the SAP document, validations that must
run in the same business transaction, and field extensions on standard objects. For that, inside and
clean (§3).

**Conversion to S/4HANA**: the custom code is **inventoried and pruned before converting** (real
usage from execution statistics: in every large installation a third of the Z code has not been run
in years — it is deleted, not migrated), then it is analysed with the compatibility checks, and only
then is it planned. **Converting dead code is the easiest expense to avoid in the whole project.**

- ❌ FORBIDDEN to **modify standard SAP objects** (a modification with a key, an *implicit
  enhancement* in standard code) outside an SAP note or an approved, documented and dated exception.
- ❌ FORBIDDEN to copy a standard program into the Z namespace to "adapt it": you freeze the copy and
  lose all of SAP's future corrections, silently.
- ❌ FORBIDDEN to write into standard SAP tables with direct `INSERT`/`UPDATE`/`MODIFY`, bypassing the
  function module or the business API. It breaks consistency, the *update task* and the audit trail.
- ❌ FORBIDDEN `SELECT` inside a loop, `SELECT *` when unnecessary and `SELECT ... ENDSELECT`.
- ❌ FORBIDDEN `FOR ALL ENTRIES` without checking that the base table is not empty.
- ❌ FORBIDDEN to concatenate user input into `EXEC SQL`, into dynamic clauses or into executable
  object names.
- ❌ FORBIDDEN an `AUTHORITY-CHECK` whose `SY-SUBRC` is not evaluated, and omitting the authorisation
  check at any new entry point.
- ❌ FORBIDDEN to ignore `SY-SUBRC` after `SELECT`, `READ TABLE`, `CALL FUNCTION` or `OPEN DATASET`.
- ❌ FORBIDDEN to leave productive objects in `$TMP` or to release incomplete requests.
- ❌ FORBIDDEN to use abapGit as the **deployment mechanism to production** in place of STMS.
- ❌ FORBIDDEN new development in SE80/Dynpro/SEGW when ADT + RAP cover the case.
- ❌ FORBIDDEN to release a request with open priority 1 ATC findings.
- ❌ FORBIDDEN credentials, endpoints or certificates embedded in ABAP code.
- ❌ FORBIDDEN to copy production data into development without anonymising it.
- ❌ FORBIDDEN to plan against a **remembered** SAP maintenance date: it is checked in the support
  portal, with the system's exact EhP and release, every time (§8).

## 8. Mandatory web verification

Always check, in the **SAP support portal** (many pages require an S-user; notes **2881788**,
**1648480**, **52505** and **2269324** are the reference ones) and cross-checking against the
*Product Availability Matrix*: end of *mainstream* for **Business Suite 7 / ERP 6.0 according to the
specific EhP**, terms and price of extended maintenance 2028-2030, what exactly *Customer-Specific
Maintenance* includes regarding **legal changes**, end of *mainstream* for **the installed S/4HANA
release** and the timetable for the next one, validity of the **Compatibility Packs** per contractual
model, the current definition of the **clean core levels** in the *ABAP Extensibility Guide*, the
list of **released APIs** for the target release, and the **security notes** of the monthly patch
day.

**Declared gaps (no verified data, do NOT fill from memory)**: (a) the contractual detail of **"SAP
ERP, private edition, transition option"** — a support option beyond 2030, conditional on migration
commitments — appears in the trade press but **has not been verified against a primary SAP source**:
do not quote terms or price; (b) the claim that *Customer-Specific Maintenance* **does not deliver
new legal changes** comes from the secondary sources consulted, not from the original note (it
requires an S-user): verify it before using it as an argument in a steering committee; (c) SAP's
official maintenance pages returned **HTTP 403** to the automated query, so **all the dates in §1
come from secondary sources that agree with each other**, not from a verbatim quote from the portal —
reconfirm with an S-user before fixing them in a plan; (d) not verified: the release timetable nor
the end of maintenance of S/4HANA **2027**.

**Flagged discrepancy**: SAP presents every extension as definitive and its track record says
otherwise — Business Suite 7 moved from 2025 to 2027, and the on-premise Compatibility Packs from
2025-12-31 to 2026-05-31 with the announcement described as *final*. Neither assume another extension
nor rule out that one arrives: plan against the current date and review it every quarter.

If the web contradicts this document, **the web wins** — flag the discrepancy.
