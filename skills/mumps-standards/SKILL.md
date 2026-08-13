---
name: mumps-standards
description: MUMPS/M language and globals-based systems, almost exclusively healthcare. Use when working with .m routine files, M routines and labels, globals (^GLOBAL subscripted nodes, SET/KILL/MERGE/$ORDER/$QUERY/$DATA/$GET, LOCK, TSTART/TCOMMIT), one-letter command abbreviations (S, W, D, Q, K, I, F, X) and indirection (@), namespaces and routine packages, InterSystems IRIS or Caché (ObjectScript .cls classes, %SYS, Studio, Terminal, Management Portal, iris session, csession, CACHE.DAT, IRIS.DAT), YottaDB or GT.M (ydb, mumps -run, gtmprofile, ydb_gbldir, global directory .gld, region and journal configuration, MUPIP, DSE, LKE), VistA (FileMan, RPC Broker, KIDS builds, routine namespacing by package prefix), Epic Chronicles, M-to-outside integration through HL7 v2 messages or FHIR facades, or deciding whether to migrate, encapsulate or freeze a MUMPS core system.
---

# MUMPS (M) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**MUMPS survives almost exclusively in healthcare, and there it is critical infrastructure**: electronic
health record and laboratory systems in continuous production, with decades of clinical and
regulatory rules inside. There are also pockets in banking (the GT.M engine underpins banking
applications), but the centre of gravity is clinical.

**The peculiarity that has to be said without hedging: what is expensive about MUMPS is not its age, it is that its data
model and its language are radically different from everything else.** A *global* is a
sparse, hierarchical, multidimensional and persistent array indexed by ordered subscripts; it is not a
table nor a document. The language has no types, it has stack-based scoping and it allows **indirection**
(building and executing code at runtime). Practical consequences:

- **There is no mechanical equivalence** between a global and a relational or document schema: the
  translation requires reconstructing the semantics that are *implicit in the position of the subscripts* and
  often only in the code.
- **Static analysis is limited by design**: with indirection and `XECUTE`, knowing what a
  program touches may require running it.
- **Code and data live in the same system**, which breaks almost every assumption of a
  standard CI/CD chain (§4).

Honest starting position:
- **No new system is written in MUMPS.** It is not a judgement about the language: it is that its
  ecosystem, its job market and its tooling do not sustain a new choice.
- **And even so, migrating an existing MUMPS core fails more than any other legacy migration**
  (§7). The right answer is usually **encapsulate and freeze**, not rewrite.
- **Writing new code *inside* an existing MUMPS system is normal and legitimate**, and that is where
  this skill sets the criteria.

Covers: where it really lives (VistA, Epic, InterSystems); the standard versus the implementations (IRIS/
Caché vs. YottaDB/GT.M) and their licenses; globals and their relationship with the relational and document
layers; language discipline (abbreviations, scoping, indirection); routines, packages and
namespaces; real integration (HL7 v2 and FHIR, not SQL); testing and version control; and the
decision whether or not to migrate.

**Not applicable**:
- `legacy-modernization-standards` (**umbrella skill of this block**): theirs is
  the modernization strategy, the portfolio analysis and the decision to invest, migrate or
  retire; **here the technical criteria of this platform**.
- `migration-projects-standards`: theirs is the **execution of the cutover** — rehearsal, window, coexistence with
  the new clinical system and its reconciliation, data reconciliation, rollback and shutdown of the source.
- `healthtech-fhir-standards`: **theirs is all the clinical
  interoperability criteria** — FHIR profiles, resources, terminologies (SNOMED CT, LOINC),
  IHE and the detail of HL7 v2. Here only **why clinical data goes out that way and not through SQL** (§6).
- `enterprise-architecture-standards` (**already written**): inventory, the **TIME** model and the **"R"s**.
- `tech-leadership-standards` and `project-management-standards` (how it is funded and decided).
- `refactoring-tech-debt-standards` (**theirs** are *strangler fig*, branch by abstraction and
  characterization of code without tests; here only what is specific to the platform).
- `testing-qa-standards` (test strategy), `cicd-standards` (the pipeline),
  `git-workflow-standards` (branches, commits, releases).
- `sql-standards`, `data-platform-standards`, `nosql-standards` (general-purpose engines and languages;
  here the global and IRIS's SQL projection only insofar as they decide something about the program).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (destinations of a
  rewrite or of the service layer: **the quality of the destination code is theirs**).
- `grc-compliance-standards` and `privacy-engineering-standards` (**compliance and personal data
  protection framework**: here only its technical landing, §5),
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **this skill is defensive**.
- `mainframe-zos-cobol-standards` and `ibm-i-rpg-standards`: **they are three different platforms that
  people lump into the same "legacy" bucket and that share almost nothing** — MUMPS has no JCL, no
  per-core licensing tiers, no relational engine underneath; its problem is the data model. Do not
  extrapolate criteria between them.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note |
|---|---|---|
| Language standard | It exists, but **it is not the practical reference**: the implementation rules | Latest ANSI: **X11.1-1995**; international **ISO/IEC 11756:1999** (defines the language as "M"), **reaffirmed by ISO in 2020**. ANSI accreditation lapsed when the M Technology Association dissolved on 1-Jan-2002; the MDC's 1998 revision was never submitted to ANSI |
| Commercial implementation | **InterSystems IRIS** (and *IRIS for Health*) | Version **2026.1** in GA, marked as an **EM (Extended Maintenance)** release. Commercial model: **proprietary subscription/support license negotiated with the vendor — it does not publish rates** (§8) |
| Caché / Ensemble | **End of life: you have to get out** | The **last maintenance releases of Caché and Ensemble are scheduled for Q1-2027**. A project still on Caché today has a migration to IRIS ahead of it with a date on it |
| Free implementation | **YottaDB** for new deployments or rehosting | Latest release verified in the official repository feed (GitLab): **r2.06, published 27-Apr-2026**, which fixes a compiler bug from **r2.04** (30-Mar-2026) — **use r2.06, not r2.04** |
| YottaDB license | **Verified by reading the tree raw** | `COPYING` = *"GNU AFFERO GENERAL PUBLIC LICENSE / Version 3, 19 November 2007"* → **AGPLv3**. The `LICENSE` file **is not the license text**, but copyright notes and clarifications about derivative works: do not confuse them |
| GT.M | The original that YottaDB is a fork of; **maintained by FIS**, oriented to their banking product | **AGPLv3 on Linux**, with a proprietary option (dual licensing). Cadence and public visibility lower than YottaDB |
| Implication of AGPL | **An architecture decision, not a formality** | AGPLv3 reaches network use: if you modify the engine and offer it as a service, there is a source obligation. **Using it unmodified, with your M application on top, is the normal case — but confirm it with legal counsel, not with this table.** See `opensource-licensing-standards` |
| Where it lives | **VistA** (public healthcare sector), **Epic** (Chronicles), laboratory and banking applications on GT.M | It determines what you can touch: in a closed commercial product, the margin for your own engineering is the integration layer, not the core |

## 3. Structure and conventions

- **The globals are the database, and their shape is the schema.** The meaning of each subscript
  —what it identifies, in what order, with what type— **must be documented outside the code**, with
  an owner. An M system without a maintained globals dictionary is a system whose migration is already
  impossible to estimate. In VistA, that dictionary is **FileMan** and it is the correct access route; in
  IRIS, the classes and their *storage definition*. **Accessing the global underneath the dictionary bypasses
  all the validation and the business logic: it is done only with a written reason.**
- **IRIS exposes relational and document structures on top** (SQL projection of the classes,
  JSON, partitioned tables in 2026.1). Use them for reading, reporting and integration; **do not
  confuse the projection with the model**: the globals are still the truth, and a projected
  table can hide the fact that the real data is sparse, hierarchical and governed by subscript rules.
- **Command abbreviations: a maintainability decision, not a style one.** The language allows
  `S X=1 I X D ^RTN`; you write `SET`, `IF`, `DO`. The compression was born of a memory
  restriction that **has not existed for decades** and today only buys illegibility: it is a material cause
  of these systems being expensive. **Everything new and everything that gets touched: full commands, one
  statement per line, a comment stating the purpose.** No mass expansion rewrites without characterization tests.
- **Explicit `NEW`** for every local variable: without it, the variable is visible downwards in the
  stack and a called routine can clobber it. **It is the classic bug and it is only avoided by discipline.**
- **Indirection (`@`) and `XECUTE`: forbidden in new code except with written justification.** Every
  use destroys static analysis, reference search and safe refactoring — for
  you and for any future migration tool.
- **`LOCK` and transactions**: concurrency is the programmer's explicit responsibility. Every
  lock with a timeout and guaranteed release; every multi-global update under
  `TSTART`/`TCOMMIT`. A `LOCK` without a timeout in a clinical system is an incident with a date on it.
- **Names**: respect the per-package/namespace prefixes (in VistA, the namespace assigned
  to the package). Colliding in routines or globals does not give a compilation error: it gives silent corruption.

## 4. Testing, versioning and CI (code and data in the same instance)

- **The canonical source lives in Git, outside the system**: `.m` routines and classes exported to
  files with automated import/export. The fact that the system edits and compiles hot
  **does not make it the repository**.
- **Structural problem**: code and data share an instance, so a test environment **is another
  instance** with its own set of globals. Without it there are no real tests. And **masked test
  data always**: copying clinical globals to test is this platform's most frequent breach.
- **Testing**: the implementation's unit framework (IRIS, or the YottaDB community one) over
  routines with explicit input and output — a practical reason not to pass parameters through stack
  variables. For the inherited core, **characterization by comparing globals before/after**.
- **Deployment**: a versioned, reproducible and **reversible** package (KIDS build in VistA, a class/routine
  package in IRIS). Importing routines by hand is not reversible: it does not reach production.
- **Minimum CI gate**: it compiles with no warnings, the suite passes against a clean instance with synthetic
  data, and no routine is edited in production.

## 5. Security and data protection

- **Here security is a legal requirement before a technical one** (health data, special category).
  The framework —legal basis, impact assessment, retention, rights, processors, breach
  notification— is set by **`grc-compliance-standards` and `privacy-engineering-standards`**; here only its
  landing on the platform.
- **Effective authorization is in the application, not in the engine**, and direct access to the global
  bypasses it. Direct access accounts (terminal, `iris session`, `mumps -direct`, DSE/MUPIP)
  **named, minimal, audited and with MFA**; zero shared maintenance credentials.
- **Auditing of accesses to the health record** enabled and exported outside the instance:
  "who looked up this patient" is legally required and is the first question of the incident.
- **Encryption** at rest and in transit for every interface, **including HL7 v2 over MLLP over TCP**,
  which historically travels in the clear inside the hospital. **An internal network is not a trusted channel.**
- **The attack surface is the interfaces** (MLLP, web services, terminal sessions,
  file transfers), not the language.
- **Journaling and copies**: the *journal* is what allows recovery; verify retention,
  replication outside the instance and **tested restore** (`backup-recovery-standards`,
  `bcdr-standards`).

## 6. Integration: why data goes out through HL7 v2 and FHIR

- **The clinical route is not SQL, and not for a technical limitation but a semantic one**: a `SELECT` over a
  projection returns rows without the context (patient identity, units, coding, document
  status, who and when) that the receiver needs in order to use the data safely. **HL7
  v2** is what is installed in hospitals; **FHIR**, the destination of every new integration.
- **Criteria**: every external consumer comes in through a standard clinical interface, never reading globals
  or projected tables; the SQL projection is reserved for internal reporting under control.
- **The detail of resources, profiles, terminologies and conformance belongs to
  `healthtech-fhir-standards`.** The facade is also **the decoupling that makes freezing the core possible**
  (§7): consumers come to depend on a contract, not on the shape of the global.

## 7. Migrating, not migrating and prohibitions

**Why MUMPS migration fails more than any other** (mechanisms, not statistics):

1. **There is no natural destination for the data model.** The global does not map to tables or to documents without
   a design decision for every structure, and those decisions number in the hundreds.
2. **The semantics are in the code, not in the schema.** Subscripts are not self-describing; the
   meaning lives in routines written by people who are no longer around.
3. **Indirection prevents reliable automatic translation**: what cannot be analyzed
   statically cannot be converted with guarantees.
4. **The system cannot be stopped.** It is healthcare: the migration is hot, with
   dual writing and reconciliation, over years.
5. **The embedded clinical and regulatory rules** are not specified anywhere except
   the code itself, and getting them wrong has consequences for care, not just financial ones.
6. **In commercial products (Epic, and much of integrated VistA) the core is not yours**: the
   migration is not an engineering project, it is a vendor replacement.

**On failure percentages**: figures for clinical migration failure circulate with no locatable primary
study. **Do not use them.** Argue with the six mechanisms above and with the
inventory of your system.

**What is done instead — the default strategy:**

1. **Encapsulate**: all the access logic goes behind routines/services with an explicit
   contract; nobody new reads globals directly.
2. **Expose over FHIR**: external consumers hook into the facade, not into the core.
3. **Freeze the core**: it is fixed and kept compliant, but new functionality is
   built outside, against the facade (*strangler fig*, from `refactoring-tech-debt-standards`).
4. **Document the globals dictionary** as an asset with an owner: it is the only work that makes the
   future migration estimable, and **it has to be done even if you never migrate**.
5. **Replace by domain**, if you replace: laboratory, pharmacy, billing — never the
   whole system at once.

**Prohibitions:**

- ❌ **FORBIDDEN** to plan a *big bang* rewrite of the core. No exceptions and no matter
  what the conversion tooling vendor promises.
- ❌ Automatic translation of M routines to another language presented as modernization: it inherits the
  structure of the original and adds a layer that nobody understands.
- ❌ Writing new code with one-letter abbreviations, without `NEW`, or with indirection/`XECUTE`.
- ❌ Accessing a global underneath the dictionary (FileMan, IRIS classes) without a written reason.
- ❌ `LOCK` without a timeout; multi-global updates without a transaction.
- ❌ Editing routines directly in production, or treating the instance as a code repository.
- ❌ **Copying clinical globals from production to a test environment without masking.**
- ❌ Integrating an external consumer by reading globals or projected tables instead of through a standard
  clinical interface (§6).
- ❌ HL7 v2 interfaces over MLLP in the clear "because it is an internal network".
- ❌ Staying on **Caché/Ensemble with no exit plan**: there is a date for the last maintenance
  release (§2).
- ❌ Assuming an M engine's license from what its site or a file called `LICENSE` says:
  **you read the `COPYING` raw** (§2, §8).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **InterSystems IRIS**: current version (as of Aug 2026, **2026.1**, EM release), support
   calendar for the one you use and platforms withdrawn in each release. **Declared gap: InterSystems
   does not publish rates nor the detail of the licensing model**; any cost figure has to
   come from your contractual quote, not from this skill.
2. **Caché/Ensemble**: confirm the end-of-maintenance calendar (verified as of Aug 2026:
   last maintenance releases scheduled for **Q1-2027**) before committing to a migration
   plan.
3. **YottaDB**: latest release **in the official GitLab repository** (as of Aug 2026, **r2.06** of
   27-Apr-2026; **r2.04 has a compiler bug fixed in r2.06**) and the license read raw
   (`COPYING` = AGPLv3). **Warning: the GitHub mirror and its release feed are not the source of
   truth; the project lives on GitLab.**
4. **GT.M**: current release and maintenance status by FIS, and its dual license (AGPLv3 on
   Linux / proprietary). **Declared discrepancy**: the latest publicly documented release that
   I could date is from Dec 2024, with sparse public announcements; **that does not prove abandonment** —the engine
   underpins banking applications in production— but it does prove that **its calendar is not verifiable
   from outside**. If you depend on GT.M, demand the calendar by contract.
5. **Language standard**: ISO/IEC 11756:1999 and its reaffirmation status; and above all **which
   proprietary extensions your code uses**, which is what decides real portability between
   implementations.
6. **Scope of AGPLv3 in your deployment** (network use, modifications, distribution): consult it
   with legal counsel and with `opensource-licensing-standards`; do not resolve it with this table.
7. CVEs and security advisories for the implementation and for the integration components (HL7
   engines, web gateways).
8. **`healthtech-fhir-standards` already exists**: **all the clinical interoperability criteria are
   theirs** and this skill only references them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
