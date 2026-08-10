---
name: mainframe-zos-cobol-standards
description: IBM Z mainframe engineering and the COBOL application estate on z/OS. Use when working with .cbl/.cob/.cpy COBOL sources and copybooks, JCL jobs (//STEP EXEC PGM=, SYSIN DD, IEBGENER, IDCAMS, SORT/DFSORT), CICS command-level EXEC CICS programs and BMS maps, IMS DB/TM and PSB/DBD, Db2 for z/OS with EXEC SQL and DCLGEN and BIND PACKAGE/PLAN, VSAM KSDS/ESDS/RRDS clusters, QSAM datasets and PDS/PDSE members, IBM MQ for z/OS, TSO/ISPF, SDSF, RACF ACF2 or Top Secret profiles, SMF records, WLM service classes, MSU MIPS and rolling four-hour average capacity billing, Tailored Fit Pricing and sub-capacity SCRT reporting, Enterprise COBOL for z/OS or GnuCOBOL compilation, EBCDIC to ASCII conversion, COMP-3 packed decimal and REDEFINES layouts, Rocket Git for z/OS and IBM Dependency Based Build with zAppBuild, Zowe and z/OSMF, z/OS Connect REST APIs over CICS, Wazi and zD&T emulation, or deciding whether to rehost, recompile, auto-translate or rewrite a COBOL application off the mainframe.
---

# z/OS mainframe and COBOL standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**The mainframe is not dead technology: it is expensive, opaque technology with very few people left to
maintain it.** It still has new hardware, an operating system with a roadmap and vendor
support (§2). What makes it a problem is not that it works badly —it usually works
better than its replacement— but three simultaneous facts: **the cost is licence and consumption, not
iron; the business logic is not where it looks like it is; and the knowledge is not written down.**

That is why, in almost every real engagement, **the decision on the table is whether to migrate**, and
this skill exists so that decision is taken with the right technical criteria —including the
very frequently correct option of **not migrating**.

Honesty up front, stated here and not hidden away in §7:
- **Writing a *new* application in COBOL on z/OS is not recommended** unless it plugs into
  an existing COBOL core that is going to be kept. This is not a criticism of the language: it is the
  labour market and the platform cost.
- **Maintaining and evolving the existing COBOL application is a legitimate option and often the
  cheapest one.** "Legacy" is not a diagnosis.
- **Almost every argument used to justify a migration is unmeasured** — the staffing
  risk first of all (§7).

Covers: z/OS lifecycle and support; the **licensing model as the dominant economic
fact**; the COBOL standard and compiler choice; the ecosystem where the logic really lives
(JCL, CICS, IMS, Db2, VSAM, MQ); the data (EBCDIC, `COMP-3`, `REDEFINES`, copybooks as
schema); real modern engineering (Git, CI/CD, testing, coverage); API exposure; and the
catalogue of migration strategies with their failure modes.

**Not applicable**:
- `legacy-modernization-standards` (**the umbrella skill of this block**): theirs
  the modernisation **strategy**, the portfolio analysis and the decision to invest, migrate or
  retire; **here the technical criteria of this platform**.
- `migration-projects-standards`: theirs the **execution of the cutover** — rehearsal, window, dual writing
  and its reconciliation during coexistence, data reconciliation, rehearsed rollback and the shutdown date
  of the source z/OS.
- `enterprise-architecture-standards` (**already written**): theirs the application inventory, the
  **TIME** model and the modernisation **"R"s**; here what each "R" technically implies *on z/OS*.
- `tech-leadership-standards` and `project-management-standards` (how a migration programme is funded
  and decided; the business case is not made here).
- `refactoring-tech-debt-standards` (**theirs** *strangler fig*, branch by abstraction and
  characterisation of untested code; here only what is platform-specific).
- `testing-qa-standards` (test strategy), `cicd-standards` (the pipeline),
  `git-workflow-standards` (branches, commits, releases).
- `sql-standards`, `data-platform-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`
  (engine and SQL language; **here Db2 for z/OS only in what it decides about the program**: BIND,
  copybook/DCLGEN, static access plan).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (usual
  targets of a rewrite: **the quality of the target code is theirs, not ours**).
- `grc-compliance-standards`, `privacy-engineering-standards`,
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **this skill is defensive**; it contains no attack techniques.
- `ibm-i-rpg-standards` and `mumps-standards`: **these are three different platforms that people lump into
  the same "legacy" bucket and that share almost nothing** — not the operating system, not the data
  model, not the language, not the economics. Do not extrapolate criteria between them.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note |
|---|---|---|
| z/OS release | The one currently in support, not the newest by fashion | **z/OS 3.2**: announced 22 Jul 2025, **GA 30 Sep 2025**. z/OS 3.1: GA 29 Sep 2023 |
| Support window | Plan the upgrade with ≥12 months of margin | IBM policy: service **5 years from GA** per release, extensible; ≥12 months of advance notice. Pattern confirmed on 2.3 (GA 29 Sep 2017 → EOS 30 Sep 2022). **EOS for 3.2 not published as of Aug 2026** (§8) |
| Hardware | z17 (Telum II) is the current generation | Announced 8 Apr 2025, GA Jun 2025 |
| COBOL standard | **ISO/IEC 1989:2023** (3rd edition, Jan 2023) | Cancels and replaces ISO/IEC 1989:2014. Paid (CHF 227 at ISO) |
| Compiler on z/OS | IBM's **Enterprise COBOL for z/OS** | The only one with full CICS/Db2/IMS support and hardware optimisations |
| Compiler off z/OS | **GnuCOBOL** for testing, CI and partial rehosting | Stable **3.2 (28 Jul 2023)**; trunk at `4.0-early-dev`. **Not a substitute for the IBM compiler in critical production** |
| GnuCOBOL licence | Verified by reading the raw tree | `COPYING` = *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"*; `COPYING.LESSER` = *"GNU LESSER GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"* → **compiler GPLv3, runtime LGPLv3** (your own COBOL binary is not contaminated) |
| ISAM in GnuCOBOL | Check which backend it was compiled with | Using Berkeley DB (`libdb`) for indexed files drags in Oracle licence conditions; alternatives: VBISAM or compiling without ISAM |
| z/OS licence model | **It is the dominant TCO variable, above any code decision** | See §2.1 |
| SCM | **Git** (Rocket Git for z/OS, or the Git in IBM Open Enterprise Foundation for z/OS) | The repository lives off the mainframe; ISPF/PDS is not version control |
| Build | **IBM Dependency Based Build (DBB)** + `zAppBuild` | Incremental dependency-driven build; orchestrable from Jenkins/GitLab/Azure DevOps |
| IDE access | **VS Code + Zowe** (or IDz/RDz if already paid for) | Connection via z/OSMF/SSH or RSE API |

### 2.1 The economic fact: MSU, R4HA and consumption

**Mainframe cost is billed by software capacity consumed, not per server.** Without
understanding this no migration can be evaluated:

- The unit is the **MSU**; **MIPS** are a marketing/capacity measure, not a billing one.
- The classic model (MLC sub-capacity) bills by the **monthly peak of the *rolling four-hour
  average*** (R4HA) of MSU per LPAR, reported to IBM with **SCRT**. Perverse consequence: **a four-hour
  peak once a month fixes the cost of the whole month**, hence practices such as *capping* and
  shifting batch to the night.
- **Tailored Fit Pricing (TFP)** is the family of alternatives to R4HA. Verified: the *Software
  Consumption Solution* bills the **MSU actually consumed over the year, aggregated by
  hour**, against a **committed annual baseline** plus a growth rate; there are also
  *Hardware Consumption*, *Enterprise Capacity*, *Application Development and Test* and *New
  Application*.
- **Hard criterion**: TFP is **not automatically cheaper**. The saving depends entirely on the
  negotiated baseline; a baseline above real consumption hands the saving back to IBM.
  **Demand a base-year analysis with your own SMF/SCRT data before signing.**
- Before proposing a migration on cost grounds, **measure**: MSU profile per LPAR and per application,
  weight of batch versus online, and what portion of the spend is third-party ISV (often larger than
  IBM's). **A migration whose business case does not separate IBM cost from ISV cost is not a business
  case.**
- Specialty engines (**zIIP**) shift eligible workload out of general-purpose
  billing: exploiting zIIP is a cost lever before it is a performance one.

## 3. Structure and conventions

- **The business logic is not only in the COBOL.** It is spread across **JCL** (step order,
  `COND`/`IF`, files created and deleted, `PARM`), **CICS transactions** and BMS maps,
  **IMS/DL-I routines**, **Db2 procedures and triggers**, **copybooks** and **parameter tables
  in VSAM**. An impact analysis that only reads COBOL programs **is incomplete by
  construction**: start from the JCL→PGM→copybook→file/table graph.
- **A copybook is a data schema, not an `#include`**: it is versioned and broken under the rules
  of a data contract. Changing a `PIC` is incompatible for every program that copies it and for
  every file already written. **Whoever touches a copybook publishes the affected programs and datasets.**
- **Data**: the native character set is **EBCDIC** (typically `IBM-1047`); every output to Git or to a
  distributed system goes through explicit conversion (that is what `.gitattributes` does in the ported Git). `COMP-3`
  and `COMP` **are not readable as text** and their width depends on the `PIC`; **`REDEFINES`** give
  different types to the same byte according to a discriminant that **is often not in the copybook**. That
  is why a "trivial" extraction gets stuck.
- Site naming conventions (HLQ, environments): **respect them**; RACF, JCL, backup and SMS
  route by prefix.
- **`GOTO`, `ALTER`, `PERFORM THRU`** are the real pattern of old code: do not rewrite them
  wholesale "for cleanliness"; only with a prior characterisation test
  (`refactoring-tech-debt-standards`).

## 4. Quality and CI

- **Real version control or nothing**: the code lives in Git and the mainframe is a deployment
  target. Move from PDS to Git **before** any modernisation.
- **Reproducible build with DBB/zAppBuild**, never manual compilation through ISPF: a deployment must
  be reproducible from a commit.
- **Testing**: program/module unit tests (z/OS test tooling, or execution under GnuCOBOL
  off-platform for pure batch) and **regression by comparing output files**, which
  in batch is what covers the most per euro. **Coverage measured by tooling, not estimated**; that
  it exists and does not fall matters more than the number.
- **Masked test data** and **environments separated by LPAR or CICS region** with their own
  catalogue. "The same place with another HLQ" is not an environment.

## 5. Stack security

- **The ESM (RACF, ACF2 or Top Secret) is the authority**; the program does not implement its own
  authorisation. Review excessive `UPDATE`/`ALTER` on production datasets, `SPECIAL`/`OPERATIONS`
  handed out widely, shared started-task IDs and service passwords that never expire.
- **In CICS the transaction definition and the region's `USERID` rule**: a program
  reachable through a poorly protected transaction bypasses any control written in COBOL.
- **Encryption**: *pervasive encryption* at rest with keys in ICSF/CEX and **quantum-safe**
  capabilities announced with z/OS 3.2 and z17. It is platform configuration: **do not invent
  encryption in COBOL**.
- **A high-value target with a modern surface.** The real risk is not an exotic attack on z/OS:
  it is **legacy FTP and Telnet without TLS**, static credentials in JCL or parameters, z/OS
  Connect APIs without granular authorisation, MQ without control and 3270 emulators with the session saved.
- **Secrets**: never in JCL, `SYSIN`, parameters or copybooks (`secrets-management-standards`).
  **SMF to the SIEM**: a mainframe whose SMF never leaves the platform is a blind spot.

## 6. API exposure and performance

- **z/OS Connect** and REST APIs over CICS/IMS/Db2 are the supported route. Rule: **wrapping is not
  modernising** — an API over a 3270 transaction inherits its conversational model, its
  granularity and its coupling. Say so when somebody presents the wrapper as the end of the project.
- Work is governed by **WLM**, not by process priority; and every change that moves CPU between
  hours moves the bill (§2.1): **performance and cost are the same conversation here.**

## 7. Migrate, do not migrate, and prohibitions

**Catalogue of strategies and what each one really buys:**

| Strategy | What it buys | What it does not fix |
|---|---|---|
| **Rehost / emulation** (COBOL on x86 or cloud, Wazi/zD&T and equivalents) | Getting out of the MSU bill while keeping the code | Nothing in the code; it adds a dependency on a new runtime vendor and the risk of numeric/EBCDIC divergence |
| **Recompilation** with another COBOL compiler | Portability, CI off-platform | Dialect differences, `COMP-3`, EBCDIC collation, and everything that was in JCL/CICS |
| **Automatic rewrite** (COBOL→Java/C#) | Apparent speed and a project milestone | **It produces unreadable code that nobody can maintain**: it preserves the COBOL structure (global variables, paragraphs, translated `GOTO`s) in a language that does not support it. The result is usually *worse* to maintain than the original |
| **Manual rewrite** (with *strangler fig*) | A genuinely maintainable system | It is the most expensive and the longest; it requires that somebody knows **what the system does**, and that is exactly the information that is missing |
| **Replacement by a product** (core banking, ERP) | It stops being your own engineering problem | The *gap fit* and the data migration; and the business process adapts to the product, not the other way round |

**Decision criteria**: do not choose a strategy without (a) a real inventory of artifacts —programs,
JCL, copybooks, transactions, tables—, (b) a **measured cost profile** (§2.1) and (c) at least one
module with a characterisation test proving you can reproduce the behaviour. Without all
three, any plan is a bet.

**Success rates and staffing risk**: the failure percentages that circulate **are not supported
by any locatable primary study**, and the staffing risk —the most cited argument— is almost
never measured. Measure it at home: how many people can deploy to production, who knows
each subsystem, real retirements, observed replacement time. Industry figures are
unreliable (§8).

**Prohibitions:**

- ❌ **FORBIDDEN** to cite as fact the famous COBOL figures ("800 billion lines",
  "95 % of ATMs", "80 % of in-person transactions", "average age 55"): they are
  extrapolations from vendor surveys or circular citations (§8).
- ❌ Presenting an **automatic rewrite** as modernisation without saying that the result inherits
  the structure of the original.
- ❌ Signing a licensing model (TFP included) **without a base-year analysis using your own
  data**.
- ❌ Treating the **copybook** as an implementation detail, or changing a `PIC` without analysing the
  data already written.
- ❌ Exporting EBCDIC/`COMP-3` data without first resolving the `REDEFINES` and their discriminants.
- ❌ **Copying production data to test without masking.**
- ❌ Using PDS/PDSE, a proprietary change manager or "whatever was there" **as a substitute for Git** in
  a new modernisation project.
- ❌ Writing new logic in JCL (`COND`, chained conditional steps) instead of in the
  program.
- ❌ Secrets in JCL, `SYSIN` or parameters; FTP/Telnet without TLS towards z/OS.
- ❌ Declaring a modernisation finished when all that has been done is putting an API in front (§6).
- ❌ Migrating "because it is legacy". **Retaining is a valid decision and you must be able to defend it.**

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Current z/OS release and its calendar.** **Declared gap**: as of Aug 2026 **I did not locate the
   announced end-of-service date for z/OS 3.2**; IBM's lifecycle page
   (`ibm.com/support/pages/zos320`) did not publish it. The general policy (5 years from GA,
   extensible, ≥12 months of notice) would point to the end of 2030, **but that is inference, not an
   announcement**: verify it in IBM's *lifecycle* by PID (5650-ZOS) before planning.
2. **Status of the consumption-based licensing models** (Tailored Fit Pricing and its variants):
   terms, baselines and conditions change by announcement and by contract. Prices and discounts
   **are not documented here**: they are negotiated and confidential.
3. **Current edition of the COBOL standard** (as of Aug 2026, ISO/IEC 1989:2023) and the real
   conformance level of the compiler you use; no compiler implements the full standard.
4. **GnuCOBOL**: stable version (as of Aug 2026, **3.2 of 28 Jul 2023**; 4.0 in development) and licence
   **read raw** (`COPYING` GPLv3 / `COPYING.LESSER` LGPLv3), plus the ISAM backend the binary
   you are going to use was compiled with.
5. **Git and CI/CD on z/OS**: which Git is supported on your release (Rocket Git for z/OS versus the
   one included in IBM Open Enterprise Foundation for z/OS), DBB/zAppBuild version and Zowe version.
6. **Domain figures — discarded here for lack of a primary study:**
   - *"800 billion lines of COBOL"*: survey commissioned by **Micro Focus** (a vendor of
     COBOL tooling, Feb 2022), run by Vanson Bourne over ~1,104 self-selected
     professionals; the Open Mainframe Project itself estimated ~250 billion. **Two
     estimates differing by more than 3× — declared discrepancy: neither is citable as data.**
   - *"95 % of ATMs" / "80 % of in-person transactions" / "43 % of banking
     systems"*: they come from a **2017 Reuters graphic** whose sources are vendor
     statements, with no published methodology or sample. **Do not cite.**
   - *"220 billion lines"*: traceable to 1990s estimates recycled by the
     press. **Do not cite.**
   - *"Average age of the COBOL programmer: 55"*: it comes from a Computerworld survey (2006,
     357 responses) where 22 % placed their staff at 55+ —not an average— and from later
     vendor statements. **A sign that it is a circular figure: it has not changed in two
     decades**, when the ageing of a fixed cohort would require it to rise. **Do not cite.**
7. CVEs and security advisories for z/OS, CICS, Db2 for z/OS, MQ and z/OS Connect on IBM's channel.

If the web contradicts this document, **the web wins** — flag the discrepancy.
