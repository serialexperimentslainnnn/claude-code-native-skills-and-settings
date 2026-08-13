---
name: ibm-i-rpg-standards
description: IBM i (AS/400, iSeries, System i) application engineering on Power. Use when working with RPG sources (.rpgle, .sqlrpgle, RPG III/RPGLE, **FREE fully free-form, /COPY and /INCLUDE prototypes), CL programs (.clle, CRTBNDCL, CL commands like WRKACTJOB, WRKSPLF, DSPFFD), DDS physical and logical files and display files (.pf, .lf, .dspf, .prtf), ILE modules, service programs, binding directories and activation groups (CRTRPGMOD, CRTSRVPGM, CRTPGM, ACTGRP), IFS and QSYS.LIB objects, library lists and *LIBL, Db2 for i with embedded SQL, SQL stored procedures, Run SQL Scripts, ACS, and IBM i Services SQL views (QSYS2, SYSTOOLS), record-level access opcodes (CHAIN, SETLL, READE, WRITE, UPDATE), journaling and commitment control, extracting business rules from RPG/CL/DDS for a characterization or modernization gate (DSPPGMREF, DSPDBR, QSYS2.PROGRAM_INFO, BOUND_MODULE_INFO, exit points via WRKREGINF or QSYS2.EXIT_POINT_INFO, Query/400 *QRYDFN, DDS validity-checking keywords, ADDPFTRG/ADDPFCST triggers and constraints), Db2 for i as a migration or CDC source (journals and journal receivers, CRTJRNRCV, CRTJRN, STRJRNPF, IMAGES(*BOTH), MNGRCV, ADDRMTJRN, RCVJRNE, QSYS2.DISPLAY_JOURNAL, remote journal, CPYTOIMPF and STMFCCSID, multi-member physical files and CREATE ALIAS, packed and zoned decimal, numeric dates, EBCDIC and CCSID 65535), IBM i Access Client Solutions, Rational Developer for i (RDi), VS Code with Code for IBM i, Merlin, Integrated Web Services (IWS), 5250 green-screen modernization, user profiles and adopted authority (USRPRF *OWNER, *ALLOBJ), QSECURITY system value, Technology Refresh levels, or IBM i release upgrades and per-core subscription licensing tiers.
---

# IBM i and RPG standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**IBM i (AS/400) is the legacy platform that ages best and is worst understood from the outside.** It
is not frozen: it has new releases, periodic *Technology Refreshes*, new hardware (Power11) and a
public roadmap (§2). Backward compatibility is real: an RPG program from the 90s compiles and runs
today. That is an engineering virtue, not a symptom of abandonment.

What is true —and has to be said here— is this:
- **It is a single-vendor platform.** Operating system, database, hardware and a good part of the
  tooling come from IBM. There is no partial exit: you are either on it or you are not.
- **The licensing model has moved to subscription** (§2), which turns a previously amortised cost
  into a recurring one. That is the relevant economic change of recent years, not the syntax of the
  language.
- **Writing new applications in RPG only makes sense inside an existing RPG base that is going to be
  kept**, and in that case it is written in **fully free-form format** (§3), without exception.
- **The real debt in almost all of these shops is not the language: it is the style** — monolithic
  programs with native record-level access, no ILE, no version control and the logic tied to the
  5250 screen.

Covers: releases and support; licence economics; RPG and the free-form rule; **ILE** (modules,
service programs, activation groups); **Db2 for i** and SQL versus native access; modern tooling and
real version control; integration (IWS, web services, **IBM i Services**); screen modernisation; and
profile and authority security.

**Not applicable**:
- `legacy-modernization-standards` (**umbrella skill for this block**): theirs is the modernisation
  strategy **for this system** —which "R" applies to it and with what seam— and the routing to the
  skill of each inherited platform; **here the technical criteria of what each "R" implies on IBM i**.
- `migration-projects-standards`: theirs is the **execution of the cutover** — rehearsal, window,
  coexistence and reconciliation between IBM i and the target, rollback criteria and decommissioning.
- `enterprise-architecture-standards`: theirs are the application inventory and the **TIME** model
  **at portfolio level** —which systems get touched, in what order and with what budget—; the "R" for
  **this** system is decided by `legacy-modernization-standards` within that frame, and **here what
  each option technically implies on IBM i**. The three levels, in one sentence: *the portfolio is
  EA's, the system is `legacy-modernization`'s, the platform is ours.*
- `erp-sap-standards` (**frequent target when this system is replaced by a package**, its
  §3.8: the standard-versus-own-process decision, the deployment and the licence are theirs —and
  they drive the date—; **here where the rule comes from and where the data comes from**, §3.4 and §3.5. The
  warning both uphold: **SAP bringing a standard process does not by itself uncover the rules
  this system executes today**, and those have to be extracted all the same).
- `tech-leadership-standards` and `project-management-standards` (how it is funded and decided).
- `refactoring-tech-debt-standards` (**theirs** are *strangler fig*, branch by abstraction and
  characterization of untested code **as a technique**; **here where the business logic lives on
  this platform, what you locate it with and what shape the executable case takes**, §3.4).
- `streaming-cdc-standards` (**CDC as a discipline is theirs**: log versus triggers versus
  polling, ordering and delivery semantics, event schema, initial *snapshot* and operation of the
  stream. **Here the mechanism of this platform** —journals and receivers, what to turn on, what it
  costs and what it breaks—, §3.5. Short rule: **the journal is ours; reading it as a change stream is theirs.**
  Warning: **their catalogue of mechanisms by engine does not include Db2 for i** (§8)).
- `testing-qa-standards` (test strategy), `cicd-standards` (the pipeline),
  `git-workflow-standards` (branches, commits, releases).
- `sql-standards` and `data-platform-standards` (the SQL language and generic data design;
  **here Db2 for i only in what it decides about the program**), `oracle-dba-standards` and
  `sqlserver-dba-standards` (other engines).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (targets of a
  rewrite: **the quality of the target code is theirs**).
- `grc-compliance-standards`, `privacy-engineering-standards`,
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **this skill is defensive**.
- `mainframe-zos-cobol-standards` and `mumps-standards`: **they are three distinct platforms that
  people lump into the same "legacy" bag and that share almost nothing** — IBM i is not a
  mainframe, it does not charge by MSU, it does not use JCL and its database is part of the operating
  system. Do not extrapolate criteria between them.
- `aix-solaris-hpux-standards` (**the most frequent confusion of all, because they share
  hardware**): **AIX and IBM i run on Power and can coexist as partitions of the same
  server, but they are different operating systems and share nothing of the application criteria.**
  AIX is Unix —`smit`, LVM, JFS2, `mksysb`, shell and binaries— and belongs to that skill; IBM i has objects,
  libraries, ILE and Db2 integrated into the operating system, and belongs here. **What they do share and
  lives there**: PowerVM, LPAR, VIOS and the HMC, the Power hardware lifecycle and the support
  contract. Short rule: **if the answer changes when you change partition, it belongs to the operating
  system skill; if it is about the hypervisor or the iron, it belongs to the proprietary Unix one.**

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note |
|---|---|---|
| Target release | **IBM i 7.6** for new hardware; **7.5** if there is Power9 in the estate | 7.6: announced 8 Apr 2025, **GA 18 Apr 2025**; requires **Power10 or higher**. 7.5 available since May 2022 |
| Release to abandon | **7.4** | Withdrawn from marketing 30 Apr 2026; **service level date change 30 Sep 2026**; paid extension until 30 Sep 2029 (*Enhanced* policy: 5 years + 3 of extension). 7.4 GA: 21 Jun 2019 |
| Hardware ceiling | The release is limited by the Power generation, not by the software | Power8 → 7.4 is the last; Power9 → 7.5 is the last; Power10/11 → 7.5 and 7.6 |
| Cadence | Apply **Technology Refresh** on its own calendar | A TR brings new functions, not just fixes; staying on an old TR closes doors (IBM i Services, open source) |
| Licence | **By processor *tier* (P05/P10/P20/P30) and, in low tiers, by users** | P05/P10: processor + users (with unlimited option); **P20 and above: by core only**. Verified in IBM's *software tiers* document |
| Commercial model | **Subscription**: perpetual is being withdrawn | P05/P10 perpetuals withdrawn 7 May 2024; **P20/P30 withdrawn effective 1 Jan 2026**; on Power11 IBM i licences are **subscription only** |
| Language | **RPG in fully free-form format (`**FREE`)** for everything new | See §3 |
| Data access | **Embedded SQL (`.sqlrpgle`) by default** | See §3.2 |
| Program architecture | **ILE**: modules + service programs + binding directory | See §3.1 |
| IDE | **VS Code + Code for IBM i** as the default option; **RDi** if already licensed | Code for IBM i: repo `codefori/vscode-ibmi`, **MIT licence** (verified in the repo's `package.json`), published on the Marketplace by HalcyonTech. **It is not an IBM product and has no IBM support** |
| RDi | Watch its calendar | RDi **9.8 support discontinued 30 Apr 2026**; **9.9** released 5 Dec 2025. RDi is an IBM product developed and supported by Fortra |
| Administration | **IBM i Services** (SQL views and procedures in `QSYS2`/`SYSTOOLS`) | See §3.3 |
| SCM | **Git**, with the source in the **IFS** (not in source members) | See §4 |

**Declared discrepancy**: IBM's terminology changed — what used to be called *end of
standard support* is now announced as *date change for service level*. Third-party sources publish
it as "end of support for 7.4 on 30 Sep 2026", but **it is not end of life**: there is a paid
extension until 2029. Do not quote "EOL 2026" without that nuance.

**On the perpetual vs. subscription cost comparison**: percentages circulate (of the order of
+20 %/+40 % over seven years) coming from trade-press analyses, not from published
tariffs. **IBM does not publish prices in announcement letters**: any figure you use has to
come from your own partner quote. See §8.

## 3. Structure and conventions

### 3.1 ILE is the line that separates maintainable from unmaintainable

- **No new monolithic programs.** Logic in **modules** (`CRTRPGMOD`), grouped into
  **service programs** (`CRTSRVPGM`) and linked by **binding directory**. The
  entry program only orchestrates.
- **Prototypes and interface `/COPY`**: the signature of each exported procedure lives in a shared
  copy source; nobody calls a procedure with a hand-written signature.
- **Activation groups**: a deliberate and documented choice. `*NEW` per call is a startup
  cost; `*CALLER` propagates; a named group per application is the usual. **`*DFTACTGRP` is
  OPM compatibility: not in new code.** The activation group determines the scope of the
  commitment control and of the open files: getting this wrong produces transaction bugs,
  not performance ones.
- **Service program signature**: manage the export file under version control.
  Adding exports at the end is compatible; reordering them forces a recompile of all
  clients. It is a binary contract.

### 3.2 SQL versus native record-level access

- **Embedded SQL is the modern default**, and not out of fashion: the optimiser (SQE) works on
  sets, exploits indexes you do not have to open by hand, and **the code says what it wants, not
  how to traverse it**. A `CHAIN`/`READE` inside a loop is a hand-written *join* with no
  statistics.
- What has to be replaced when leaving the native *opcodes*: explicit control of record locking
  and the "read one row by key" (cursor or `SELECT INTO`). Neither of the two justifies
  writing the whole application in native access.
- **Hard rule**: new code with SQL; the old converts **only** when it has to be touched for another
  reason and with a test that compares results. **There is no mass conversion campaign that ends well.**
- **DDS in maintenance mode for data**: new tables, views and indexes **with SQL DDL**, not
  PF/LF. DDS is still what there is for screens (DSPF) and printouts (PRTF).
- **Journaling and commitment control enabled** on every business file: it is the prerequisite
  for recovery and for replication, and it is discovered late.
- The **`*LIBL`** is dynamic resolution and an inexhaustible source of incidents: **the library
  list of a production job is versioned configuration**, not a session setting.

### 3.3 Administer with SQL, not with screens

**IBM i Services** (SQL views and procedures in `QSYS2`/`SYSTOOLS`) are **the modern way to
administer**: objects, PTFs, jobs, authorities, users and network are queried with `SELECT`, which
is automatable, comparable across environments and auditable — a `WRKxxx` leaves no evidence. Every
periodic check (excessive public authorities, inactive profiles, pending PTFs) is written
as a saved query in the repository, not as a manual procedure.

### 3.4 Where the business logic lives and how it is located

**This is the work that decides whether an IBM i migration succeeds or not**, and the one nobody does
before signing the project. `legacy-modernization-standards` turns it into a gate —*no
characterization, no change*— and `refactoring-tech-debt-standards` provides the generic technique
(*characterization test*, *golden master*). **What is decided here is where to look on this
platform, what you search with and what limit each tool has.**

**The rule is not in "the RPG programs". It is spread across at least eight places:**

1. **Fixed-format RPG and RPG III/OPM**: beyond the code, the logic is in the **program
   cycle** (what runs without anyone writing it), in the **output specifications** and in
   the **numeric indicators** — an `*IN37` that decides a discount **is** a business rule, and
   you do not find it by searching text. It is the most expensive to read and where most of the rule is.
2. **Free-form RPG and ILE**: it is the readable part, and that is why it gets overweighted. If the system is already in
   procedures and service programs (§3.1), extraction is cheaper, but **it covers the part
   of the system with the least risk**.
3. **CL**: it passes for "plumbing" and it is not always that. A `CL` that decides which program to call according to the
   content of a data area, or that sets the `*LIBL` of a process, carries rules
   —calendar, company, environment— that appear in no RPG.
4. **The database**: *triggers* (`ADDPFTRG`, or `CREATE TRIGGER` in SQL) and **constraints**
   (`ADDPFCST`: key, check, referential). A trigger is logic that runs **without
   any program calling it**: if you migrate the data without migrating the trigger, the rule disappears in
   silence.
5. **DDS**: validity checking lives in the keywords of the DDS itself —`COMP`/`CMP`,
   `RANGE`, `VALUES`, `CHECK`, with `CHKMSGID` for the message— and **is copied from the physical file to
   the display file by field reference at the moment the DSPF is created**. Verified in the
   IBM DDS documentation. Double consequence: (a) there are domain rules declared outside every
   program; (b) **they only apply when going through the screen**: ODBC, DFU, SQL or a web service
   write without them. If the rule matters, it is not where people think it is.
6. **The 5250 screen itself**: field order, fields protected depending on the case, the sequence
   of screens that prevents reaching an invalid state. It is process design turned into access
   control; it is lost entirely when the interface is replaced.
7. **Exit points**: programs registered in the **registration facility**
   (`WRKREGINF`, and the SQL views `QSYS2.EXIT_POINT_INFO` and `QSYS2.EXIT_PROGRAM_INFO`, available
   since 7.4 TR3 / 7.3 TR9 — verified in the IBM i Services documentation). They filter FTP, ODBC,
   DDM or session startup, and often carry business rules ("this user cannot
   download this table"). **They do not show up by reading the application**: you have to go looking for them.
8. **What lives outside the code**: **Query/400** definitions (`*QRYDFN` objects, `WRKQRY` /
   `RUNQRY`; the product is still shipped with the operating system after IBM's licensing
   simplification, it is not withdrawn) and, above all, **the end user's spreadsheets**
   hanging off the system over ODBC. That is where the real calculation of commissions, margins
   or forecasting usually is — the system only stores the data. **An inventory that does not include them underestimates the
   scope completely.**

**The system's own tools, and what they do NOT see:**

| Tool | What it gives | Limit that has to be declared |
|---|---|---|
| `DSPPGMREF` | Objects referenced by each program or SQL package: files (with their use: input/output/update), programs, data areas, `*SRVPGM` | **It is what there was at compile time**, not what there is: names may not match if there was an *override*. When updating an ILE program (`UPDPGM`/`UPDSRVPGM`) **entries are added but never removed**, so there is stale information left over. **It does not accept more than one library per invocation**: you have to walk them. Output to file with format `QWHDRPPR` (`QADSPPGM` in `QSYS`) so it can be queried with SQL |
| `DSPDBR` | Logical and physical files dependent on a given one, and dependencies at member level | **It does not show all parent/child constraint relationships** — a limit acknowledged by IBM support itself, which publishes `DSPEDBR` inside `QMGTOOLS` to cover it |
| IBM i Services (`QSYS2.PROGRAM_INFO`, `BOUND_MODULE_INFO`, `BOUND_SRVPGM_INFO`, `PROGRAM_EXPORT_IMPORT_INFO`) | The full ILE graph **in SQL**: which modules are in each program, which service programs are bound, what is exported and imported, with which source it was compiled | Expensive to materialise at system level; **IBM expressly recommends taking a snapshot into a table** and querying over it. They only cover ILE with useful depth |
| SQL catalogue (`QSYS2.SYSTRIGGERS`, `SYSCST`, `SYSKEYCST`, `SYSINDEXES`, `SYSTABLES`, `SYSCOLUMNS`) | The logic declared **in the database**: existing triggers and constraints | Only what is declared in the database; nothing of what the program does |
| `QSYS2.EXIT_POINT_INFO` / `EXIT_PROGRAM_INFO` | Exit points and registered programs | See point 7 above |

**The common blind spot, and it has to be said before promising coverage**: everything above is
**static analysis**. It does not see calls resolved at runtime (`CALL` with the name in a
variable), nor dynamic SQL, nor which library actually resolved the `*LIBL` of that job. **A
static analysis of IBM i is never complete**, and the gap has exactly the shape of what you least
expect. It is complemented with execution evidence (trace, audit journal, real object
usage) to know **what is used**, and with the ecosystem's commercial analysis tools
if the budget allows — **do not quote one by name without verifying that it is still alive and what it covers**
(§8).

**What is a business rule and what is plumbing.** Without this filter, 200,000 lines get "extracted" and
nothing gets characterized. **It is a rule** if a business owner could want to change it without
touching technology: calculation (price, discount, commission, tax, interest), eligibility and
condition ("this customer cannot order on credit above X"), state transition (what happens
when an order is confirmed and what becomes forbidden afterwards), deadline and calendar, and **data derivation**
(how a field is filled from others). **It is plumbing** —and it is not extracted, it is discarded or
rewritten in the target with its own rules— screen navigation, format validation,
number and date formatting and editing, subfile and window handling, I/O error
handling, file *overrides*, `*LIBL` handling and opening and closing
of files. **Hard rule: if describing it in one sentence brings up a company concept, it is a
rule; if only platform concepts appear, it is plumbing.** The doubtful case —the validation
that is both format and domain— is resolved on the expensive side: it is treated as a rule.

**The warning that holds up everything else**: **a rule that only exists in the code and that nobody in the
business recognises is still the rule the company runs on today.** It is not discarded because it does not
appear in any document nor because the owner says "that is not how it is done": it has been deciding
for years, and the target that does not reproduce it will change results on day one. It is documented as
**observed behaviour**, taken to an explicit business decision —keep, change or
remove— and **the change, if decided, is a functional change separate from the cutover**, never a side
effect of the migration. The same with defects: a calculation that has been wrong since 1998 is
characterized **as it is** and corrected afterwards.

**What is delivered** (it is the artifact that `legacy-modernization-standards` requires as a gate, with the
shape it takes on this platform):
- **Inventory of objects with owner and real usage**: programs, files, triggers, constraints,
  exit points, `*QRYDFN` and external consumers over ODBC/DDM — generated with SQL over the
  views above, **versioned in Git and regenerable**, not a one-off Excel.
- **Rule catalogue**: each rule with identifier, statement in business language, inputs and
  outputs, exceptions, **evidence** (program, procedure and line; or trigger; or DDS
  keyword) and business owner who has confirmed or rejected it.
- **One executable characterization case per rule**, with its data: on this platform, what
  works is comparing the outputs of **batch processes** against reference files and the
  direct call to ILE procedures (§3.1, §4). A rule without an executable case **is not
  characterized**: it is noted.
- **Explicit list of what is not covered**: the dynamic, the interactive that can only be tested over 5250 and
  what lives in spreadsheets. **A declared gap is the deliverable; a silent gap is the
  risk.**

### 3.5 Db2 for i as a data source: journals, extraction and reconciliation

**Explicit split of authority**: `streaming-cdc-standards` owns **CDC as a discipline**
—why the log beats triggers and timestamp polling, ordering and delivery semantics,
event schema and contract, management of the *backfill* and the initial *snapshot*, and the operation of the
stream—. **Ours is the concrete mechanism of this platform**: what the journal is, what has to be
turned on, what it costs and what it breaks. And it has to be said because the confusion is expensive: **the catalogue of
capture mechanisms by engine does not include Db2 for i** (§8), so whoever arrives looking for "the
binlog of the AS/400" finds nothing. The equivalent exists and **is first class**: the *journal*.

**What a *journal* and a *journal receiver* are.** The **journal** (`*JRN`) is the logical object that
defines what is recorded; the **journal receiver** (`*JRNRCV`) is the object that **physically
contains the change entries**. Each change to a journalled file writes an entry with the
type of operation, the record image, and who, which program, which job and when. It is the same
mechanism that underpins commitment control, recovery and the high-availability replication
of the platform: **that is why, in most of these shops, it is already turned on**, and
discovering it changes the budget of the migration. When creating an SQL schema, Db2 for i creates journal and
receiver and **automatically journals** the tables created in it (`QSQJRN`); what is created with DDS, no —
there it has to be enabled by hand.

**What has to be turned on and what it costs:**
- The receiver is created (`CRTJRNRCV`), the journal is created (`CRTJRN`) and journalling of each
  physical file is started (`STRJRNPF`). Commands verified in the IBM documentation.
- **`IMAGES(*BOTH)` versus `IMAGES(*AFTER)`** is the decision that most conditions the target:
  `*AFTER` records only the after image; `*BOTH` also records the before one, and **it is what allows
  reconstructing an `UPDATE` as a change and not as a "new state"**. Commercial CDC tools
  require `*BOTH` or `*AFTER` depending on the case. It costs twice the writing in the receiver: it is decided,
  not inherited.
- **Receiver management**: with `MNGRCV(*SYSTEM)` the system detaches the full receiver and attaches
  a new one when the threshold is reached; `DLTRCV` decides whether it also deletes them. **This is the number one
  operational trap of a CDC over IBM i**: if the system deletes receivers that the reader has not yet
  processed, **there is silent data loss**. Receiver retention is a requirement
  agreed with the systems team before connecting anything, and coordinated with the backup policy
  (receivers live on disk and are among the fastest growing things).
- **Cost**: journalling writes to disk on every change and there is additional overhead from opening and
  closing objects; the more journalled objects, the more impact. It is sized with the operations
  team, it is not turned on massively on a Friday.
- **Journal cache** (`JRNCACHE`, option **42 of the operating system, *HA Journal Performance*,
  chargeable): improves performance by grouping entries in memory, but **cached entries are
  not visible** to `DSPJRN`, `RCVJRNE`, `RTVJRNE` nor the `QjoRetrieveJournalEntries` API, **nor are they
  sent to the remote journal**. Verified in the IBM documentation. Translation: if the CDC reader
  "keeps losing the tail", it may not be a fault of the reader. And on a system crash, what is in
  memory is lost.
- **Remote journal**: it is added with `ADDRMTJRN` (not with `CRTJRN`) and allows reading the stream from another
  machine, distinguishing between committed and uncommitted entries. **It is the way not to put the
  CDC reader on the production system.**

**Reading and extraction routes, with criteria:**

| Route | When | Warning |
|---|---|---|
| `QSYS2.DISPLAY_JOURNAL` (SQL table function, available since 7.1) | Reading journal entries **with SQL**; it is what several commercial tools build on | The input parameters have to be bounded or the cost explodes; **interpreting the BLOB with the record image is not trivial** and it is where everyone who builds it by hand gets stuck |
| `RCVJRNE` / `RTVJRNE` / `QjoRetrieveJournalEntries` API | The program route: `RCVJRNE` delivers entries continuously to an exit program, and it is what replication products use | Exit program on the machine; subject to the journal cache (above) |
| **SQL over the catalogue and the tables** (JDBC/ODBC, `Run SQL Scripts`) | Initial load, profiling and reconciliation | It is the correct route for the *snapshot*; the impact on the production system is negotiated and executed in a window |
| `CPYTOIMPF` to a stream file in the IFS | Delimited dump when there is no direct connectivity | **The CCSID is decided explicitly** (`STMFCCSID`): the stream inherits by default the EBCDIC CCSID of the table. Verified in the IBM documentation |
| DDM / DRDA / web services (IWS, §6) | Point integration and querying, not bulk load | DDM and DRDA are also an access surface to control (§5) |
| Third-party tools | When the CDC is continuous and the project pays for it | **Verify product, version and mechanism before quoting it** (§8) |

**On third-party tools, without marketing**: the ones that lean on this platform read the
journal, by one of the two routes above. As of Aug 2026 it has been verified that **Qlik Replicate** and the
**Fivetran/HVR** connector capture via `DISPLAY_JOURNAL`, that **Informatica PowerExchange** captures
from the receivers, and that **Matillion** publishes a *streaming* connector for Db2 for i based on
journal entries. **Debezium's official Db2 connector is for Db2 for Linux/UNIX/Windows and does not
cover Db2 for i**; there is a third-party community connector that does read the journal — **do not treat it
as equivalent in support**. This list is a market signal, not a recommendation: it gets re-verified (§8).

**The data traps that break the migration** (this is what makes the project slip, not
the volume):
- **Packed and signed** (*packed* / *zoned*): numbers stored with the sign in the last
  half byte. Decades of programs writing directly leave **values with an invalid sign or digit
  nibble** that no sample `SELECT` uncovers and that blow up when converting in bulk.
  **100 % of the numeric columns are profiled before moving anything**, not a sample.
- **Dates in numeric of 6, 7 or 8 digits**: `YYMMDD`, the 7-digit format with the century in front, or
  `YYYYMMDD`. It brings `0`, `999999`, day 31 in months of 30, and **century windows implicit in the
  code** ("less than 40 is 20xx") that have to be extracted as a rule (§3.4), not guessed. Each
  sentinel combination is decided with the business: not all of them mean "null".
- **Multi-member files**: a physical file with several members —typically a history per
  year or per company—. **SQL has no equivalent and uses the first member by default**, so an
  extraction over SQL takes one chunk and looks correct. Verified in the IBM documentation: it
  is accessed with `CREATE ALIAS` over the specific member (or with a logical over all of them, or `OVRDBF`).
  **Checking for the existence of multiple members is a mandatory step of the inventory**, and moreover
  partitioning by member **is** an implicit business rule.
- **Fixed length with padding**: `CHAR` values come padded with blanks; business keys that in the
  target are compared with `VARCHAR` stop matching. A trimming policy is decided **once** and
  applied the same way in load and in reconciliation.
- **EBCDIC and CCSID**: the data is born in EBCDIC. **`CCSID 65535` (`*HEX`) means "do not convert"** and is
  the classic finding: the ODBC/JDBC client treats it as binary or fails. You have to distinguish the
  column that is **truly binary** from the one that is text that was never tagged, and tag it; done
  blind, accents, `Ñ` and currency symbols get corrupted. **Redefining the CCSID does not rewrite the
  bytes: it changes how they are interpreted** — so an error here is invisible until someone reads
  a proper name.
- **Redefined and reused fields**: a field whose meaning depends on the value of another, a
  `CHAR(30)` that carries three subfields inside, a "status code" to which new meanings were added
  without changing the structure, or fields declared and no longer used that are still
  full of old data. **No tool detects it: it comes out of profiling real values plus
  the rule extraction of §3.4.** A field with two meanings **is split into two in the
  target**, and that is a business decision with an owner.

**Reconciliation is not optional and is designed before extracting.** Minimum: row counts and **control
sums per business numeric column** (amounts, not identifiers) per partition
—fiscal year/company/warehouse—, compared against the source **at the same logical instant**; count
of distinct values and of nulls/sentinels in the key columns; and for CDC, the lag between the
last applied journal entry and the source's. Reconciliation **is executed in the rehearsal and in the
cutover**, with the tolerance agreed **in writing beforehand** —the execution of the cutover and its
reconciliation belong to `migration-projects-standards`; **the definition of what is reconciled on this
platform belongs here**—. An extraction that does not reconcile **is not fixed by hand in the target**: the
process is fixed and it is executed again, because the manual fix is not repeatable and the cutover is
executed more than once.

## 4. Quality, version control and CI

- **The source lives in Git, in the IFS** (`.rpgle`/`.sqlrpgle`/`.clle`/`.sql`), **not in members of
  `QSYS.LIB`**: a member with a modification date is not history and does not allow branches, diff nor
  review. **It is the change with the highest return of the whole modernisation, and it comes before the others.**
- **Reproducible build**: versioned script (Code for IBM i ecosystem utilities, or your own CL)
  that rebuilds from scratch in a clean library. If nobody knows how to recompile everything, there is no
  delivery: there is patching.
- **Environments separated by library and `*LIBL`**, with their own **masked** test data.
- **Tests**: unit over ILE procedures (made possible by the design of §3.1) and regression by
  comparison of batch outputs. A monolithic program that can only be tested over 5250 is, in
  practice, not testable: that is the first thing that has to be broken.
- **Minimum CI gate**: compiles clean without ignoring warnings, the suite passes, and **no object is
  created by hand in production**.

## 5. Stack security

- **`QSECURITY` 40 as a minimum**; 50 in regulated environments. Below 40 the integrity of the
  system is not guaranteed; raising it is a project, but **staying at 30 is not defensible**.
- **`*ALLOBJ` is the problem.** Every profile with `*ALLOBJ`/`*SECOFR` is a total administrator of the system
  and of the data. Inventory who has it —including via group profile—, justify it one
  by one and remove the rest: this is where application profiles and service users with total
  authority show up.
- **Public authority**: `*EXCLUDE` on data objects and granting by authorization list.
  `*PUBLIC *CHANGE` on business libraries is the guaranteed audit finding.
- **Adopted authority (`USRPRF(*OWNER)`)** grants access only while the program runs, and it is a risk
  if the program allows reaching a command line. Adopt from the smallest object possible,
  control propagation (`USEADPAUT`), and **no program that adopts authority offers command
  entry**.
- **The back door is not the 5250**: it is the open interfaces (FTP, ODBC/JDBC, DRDA, DDM,
  REST). A user limited by menu can read all the tables over ODBC if there are no exit
  programs nor object-level authority. **Security goes on the object, not on the menu.**
- **Native MFA**: 7.6 incorporates TOTP into the operating system, applicable to all authentication
  points (5250, FTP) and to SST/DST profiles, at no additional cost — reason enough, by
  itself, to plan the jump. 7.6 also adds encryption of the system ASP (SYSBAS): verify
  the operational impact before enabling it.
- **`QAUDJRN` enabled and exported to the SIEM**: if the audit journal does not leave the machine, it is
  a blind spot.

## 6. Integration and interface modernisation

- **Web services**: **IWS** exposes a program or procedure as REST/SOAP without leaving the
  platform; for consumption, native HTTP client or SQL functions. With volume or complex integration,
  the alternative is an external service that speaks Db2 for i over SQL.
- **The usual trap: wrapping the 5250 screen in web without redesigning the flow.** Out comes the same
  sequence of screens with CSS, with its step-by-step navigation, its field-by-field validation and its
  conversational session: **you gain looks, not usability nor decoupling**. Prerequisite to
  any new interface: that the logic be in ILE procedures callable without a screen
  (§3.1). While it lives in the DSPF's program, the web layer is make-up.
- **API before screen**: the unit of reuse is the procedure, not the interactive
  program.

## 7. When to stay, when to migrate and prohibitions

**Staying is correct —and it is more often than people think— when:**
- The application covers the business, the total cost (licence + support + staff) is known and
  competitive, and there is Power hardware in support with a path to 7.5/7.6.
- The operation is what the platform does exceptionally well: reliable batch, integrated
  database, very little administration per transaction, high availability with a small team.
- It can be modernised *inside*: ILE, SQL, Git, CI, APIs. **That route is dramatically cheaper
  than rewriting and almost nobody exhausts it before raising migration.**

**Migrating makes sense when** the single vendor is a risk accepted by management, when the
subscription cost stops being competitive against the value, when the functionality is bought ready
made (ERP), or when there is no staff and there will not be — **measured in your shop, not in an article**.

**Prohibitions:**

- ❌ **FORBIDDEN** to write new code in fixed-format RPG (columns), in RPG III/OPM or with
  numeric indicators as logic. Everything new: **`**FREE`**, procedures, named
  variables.
- ❌ New monolithic programs without ILE, or `DFTACTGRP(*YES)` in new code.
- ❌ Native record-level access for new set logic (`CHAIN`/`READE` loops that are a
  *join*).
- ❌ Defining new tables with DDS instead of SQL DDL.
- ❌ **`QSYS.LIB` source members as version control.** The source goes to Git, in the IFS.
- ❌ Compiling or creating objects by hand in production.
- ❌ `QSECURITY` below 40; `*ALLOBJ` handed around; `*PUBLIC *CHANGE` on data libraries.
- ❌ Programs that adopt authority and allow a command line.
- ❌ Entrusting security to the 5250 menu while leaving ODBC/FTP/DDM uncontrolled.
- ❌ Presenting as modernisation a web wrapper of the same 5250 screens (§6).
- ❌ **Promising that the business logic has been extracted from static analysis** (`DSPPGMREF`,
  IBM i Services views) **without declaring the blind spot**: dynamic calls, dynamic SQL and
  resolution by `*LIBL` are not seen there (§3.4).
- ❌ Discarding a rule because nobody in the business recognises it, or fixing it inside the same change
  that migrates it. It is characterized as it is and the functional change goes separately (§3.4).
- ❌ Considering the logic inventoried without having looked at **triggers, constraints, validity
  keywords in DDS, exit point programs, `*QRYDFN` and the spreadsheets over ODBC** (§3.4).
- ❌ **Extracting over SQL from a multi-member file without checking the members**: SQL uses the first and
  the result looks correct (§3.5).
- ❌ Converting numeric columns or numeric dates **over a sample**: profiling is of
  100 % of the rows (§3.5).
- ❌ Moving data ignoring the CCSID, or "fixing" a `CCSID 65535` by changing the tag without deciding
  first whether the column is binary or untagged text (§3.5).
- ❌ Setting up a CDC over journals **without agreeing receiver retention beforehand** with the systems
  team: if they are deleted before being processed, the loss is silent (§3.5).
- ❌ Diagnosing a CDC reader "that loses the tail" without ruling out the **journal cache**: its
  entries are not visible nor sent to the remote journal (§3.5).
- ❌ Executing a cutover without a defined reconciliation and a tolerance agreed in writing, or repairing by hand in the
  target what did not reconcile (§3.5).
- ❌ Planning a release upgrade without first checking the ceiling imposed by the Power generation.
- ❌ Quoting perpetual-vs-subscription cost figures or IDE market share without naming the
  source and its method (§8).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Current IBM i release and its calendar**: as of Aug 2026, 7.6, 7.5 and 7.4 are supported (the last
   one with a service level change on 30 Sep 2026 and extension until 30 Sep 2029). **Declared
   gap: IBM had not announced end-of-support dates for 7.5 or 7.6.** Do not infer them
   as if they were an announcement; consult IBM's official release support page (PID
   5770-SS1).
2. **Release ↔ Power generation matrix** and minimum firmware level before committing to an
   upgrade.
3. **Current licensing model**: which tiers still have perpetual, conditions of the
   subscription and of the *5250 Enterprise Enablement*. **Prices are not documented here: IBM does not
   publish them in announcement letters and they are only reliable via a partner quote.**
4. **Status and licence of Code for IBM i**: as of Aug 2026, `codefori/vscode-ibmi`, **MIT licence**
   verified in the repository; **community** project, **without IBM support**. Verify also whether
   it is still the active repository before basing a decision on it — the GitHub releases
   feed is not the source of truth if the project moves.
5. **RDi status**: 9.8 with support discontinuation on 30 Apr 2026; 9.9 released
   5 Dec 2025. Verify the 9.9 calendar and who supports it (IBM contracts Fortra).
6. **Technology Refresh level** current for your release and which IBM i Services it adds: the list of
   SQL views grows with each TR and determines what you can automate.
7. IBM i security bulletins, cumulative security PTFs and CVEs of the ported open
   source components (which arrive on their own calendar).
8. **Tool adoption figures** (market surveys of the Fortra type): they are self-reported
   surveys with an unpublished sample; **use them as a trend signal, never as hard data**.
9. **Every command or SQL view name in this skill, against `ibm.com/docs` for the client's
   release, before typing it.** Verified as of Aug 2026 in IBM documentation: `DSPPGMREF`
   (output format `QWHDRPPR` over `QADSPPGM`, a single library per invocation, entries that
   are added but not removed when updating an ILE program), `DSPDBR` (and the limit with the
   parent/child constraints, which IBM covers with `DSPEDBR` from `QMGTOOLS`), `WRKREGINF`,
   `QSYS2.EXIT_POINT_INFO` and `EXIT_PROGRAM_INFO` (7.4 TR3 / 7.3 TR9), `QSYS2.PROGRAM_INFO`,
   `BOUND_MODULE_INFO`, `BOUND_SRVPGM_INFO`, `PROGRAM_EXPORT_IMPORT_INFO`, the DDS keywords
   `COMP`/`CMP`, `RANGE`, `VALUES`, `CHECK` and `CHKMSGID`, `CRTJRNRCV`, `CRTJRN`, `STRJRNPF`,
   `CHGJRN`, `IMAGES(*BOTH)`/`(*AFTER)`, `MNGRCV(*SYSTEM)`, `DLTRCV`, `ADDRMTJRN`, `RCVJRNE`,
   `RTVJRNE`, `QjoRetrieveJournalEntries`, `JRNCACHE` (option 42, *HA Journal Performance*),
   `QSYS2.DISPLAY_JOURNAL` (since 7.1), `CPYTOIMPF` with `STMFCCSID`, and `CREATE ALIAS` over a
   specific member. **An invented command costs a day to whoever types it: if you do not confirm it,
   do not write it.**
10. **Declared gap — exact syntax and parameters**: here **what is decided** is fixed, not the
    syntax. The concrete parameters of `RCVJRNE`, `RCVSIZOPT`, `FIXLENDTA` and the format of the
    journal entries **are not documented in this skill** and are consulted in the *Journal
    management* manual of the release in use. Part of the verification above relied on documentation of
    releases 7.1-7.6 indistinctly: **confirm on the client's release** before committing to a
    design.
11. **Third-party CDC and analysis tools**: as of Aug 2026 it was verified that Qlik Replicate and the
    Fivetran/HVR connector capture via `QSYS2.DISPLAY_JOURNAL`, that Informatica PowerExchange
    captures from the journal receivers, and that Matillion publishes a *streaming* connector for
    Db2 for i based on journal entries. **Debezium's official Db2 connector is for Db2 LUW**;
    for IBM i there is a third-party community connector. **Declared gap: this was contrasted with
    product documentation and community discussion, not with a support matrix published by
    Debezium** — verify before basing a purchase decision on it, and verify likewise any
    commercial code analysis tool of the ecosystem before naming it.
12. **Db2 for i does not appear in the catalogue of capture mechanisms of `streaming-cdc-standards`**
    (verified in the skills catalogue itself, Aug 2026): that skill enumerates PostgreSQL's WAL,
    MySQL/MariaDB's binlog, Oracle's LogMiner, SQL Server's CDC and MongoDB's *change streams*. The
    mechanism of this platform is the journal and it is in §3.5. **Do not infer from that absence that IBM i
    does not have log-based capture: it has it, and it is first class.**

If the web contradicts this document, **the web wins** — flag the discrepancy.
