---
name: legacy-modernization-standards
description: Umbrella skill for inherited systems - what to do with a system before touching its code, and the router to the platform skill that owns it. Use when facing a system nobody can rebuild from source, a production binary that does not match the repository, a lost or unreproducible build, code archaeology on an undocumented estate, choosing between the R strategies (rehost, replatform, refactor, rearchitect, rebuild, replace, retain, retire) for one system, a runtime or vendor that has stopped shipping updates with no upgrade path, business rules that exist only in the code and in one person about to retire, auto-translation or LLM-assisted rewrite of an old codebase, deciding to freeze and contain a system on purpose, or identifying which legacy platform skill applies to COBOL, RPG, MUMPS, VB6, Delphi, ColdFusion, Struts, Forms, ABAP or a proprietary Unix.
---

# Legacy system modernisation standards — umbrella skill

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **This skill is an umbrella.** It fixes the **invariants** of any modernisation and **routes** to the
> skill of the specific platform (§1.2). If the question is *"how is this done in COBOL / in RPG /
> in Delphi?"*, the deep skill wins. This document wins **before**: what is going to be done with the
> system, under which preconditions and with which stopping criteria.

## 1. Scope and triggers

### 1.1 What this skill decides

- **The strategy for an inherited system, before touching code**: which "R" is chosen and why,
  or whether the correct answer is **to do nothing and contain it** (§3.3).
- **The hard preconditions**: rebuilding the build, identifying the source that really corresponds
  to the production binary, characterising the behaviour — and what to do when none of that exists
  (**archaeology**, §4).
- **Real applicability of incremental patterns**: whether there is an interceptable seam or not (§3.1).
- **The cost of doing nothing**, explicit and dated: support, attack surface, people (§5).
- **Routing**: given a specific system, deciding which platform skill wins (§1.2).

### 1.2 Routing to the platform skills

| If the system is written in / runs on… | Wins | Status |
|---|---|---|
| COBOL, JCL, CICS, IMS, VSAM, Db2 z/OS — IBM Z mainframe | `mainframe-zos-cobol-standards` | exists |
| RPG, CL, DDS, ILE — IBM i / AS-400 / iSeries on Power | `ibm-i-rpg-standards` | exists |
| MUMPS/M and globals — IRIS/Caché, YottaDB/GT.M, VistA, Epic | `mumps-standards` | exists |
| Visual Basic 6 — `.vbp`/`.frm`/`.cls`, OCX, `msvbvm60.dll` | `vb6-standards` | exists |
| VB.NET — `.vb`, `.vbproj`, `Option Strict`, `Microsoft.VisualBasic` | `vbnet-standards` | exists |
| .NET Framework 4.x — WebForms, WCF, `packages.config`, `web.config` | `dotnet-framework-legacy-standards` | exists |
| Classic ASP 3.0 on IIS — `.asp`, `global.asa`, VBScript in `<% %>` | `classic-asp-standards` | exists |
| ABAP inside SAP ERP — SE38/SE80, transports, ECC→S/4HANA | `abap-sap-standards` | exists |
| PL/SQL, Oracle Forms and Reports — `.pks`/`.pkb`, `.fmb` | `plsql-oracle-forms-standards` | exists |
| CFML — Adobe ColdFusion, Lucee, BoxLang, `.cfm`/`.cfc` | `coldfusion-standards` | exists |
| JSP, scriptlets and Apache Struts 1/2 — `struts-config.xml`, OGNL | `jsp-struts-standards` | exists |
| Fortran — fixed form `.f`/`.for`, `COMMON`, `EQUIVALENCE`, numerical HPC | `fortran-standards` | exists |
| Ada and SPARK — `.ads`/`.adb`, GNAT, certified high integrity | `ada-standards` | exists |
| Object Pascal — Delphi/RAD Studio (`.pas`/`.dpr`/`.dfm`), Free Pascal/Lazarus | `pascal-delphi-standards` | exists |
| Common Lisp or Scheme — SBCL images, ASDF, `.lisp`/`.scm`/`.rkt` | `lisp-standards` | exists |
| Prolog — `.pl`/`.pro`, SWI/SICStus, Horn clauses, CLP(FD) | `prolog-standards` | exists |
| Smalltalk — live image, `.image`/`.changes`, Pharo, GemStone/S, VisualWorks | `smalltalk-standards` | exists |
| ActionScript, Flash, Flex and AIR — `.as`/`.fla`/`.swf`, AVM1/AVM2 | `actionscript-standards` | exists |
| AIX on Power, Solaris on SPARC, HP-UX on Itanium (proprietary Unix) | `aix-solaris-hpux-standards` | exists |
| FreeBSD, OpenBSD, NetBSD and derivatives (pfSense/OPNsense/TrueNAS) | `bsd-systems-standards` | exists |

**Arbitration rule**: if the row exists, **that platform's technical criteria win over this
document** — there are platforms where automatic translation produces unmaintainable code and others
where freezing and encapsulating is the right answer, and only the platform skill knows that.
This document wins on **the prior decision** and on the invariants of §1.3, which admit no
platform exception. **If the row does not exist** (an in-house system in a living but
abandoned language), apply §1.3 + §3 + §4 and treat the absence of a skill as what it is: **there are no
verified specific criteria, so you investigate before deciding** (§8).

### 1.3 Invariants of any modernisation

Falsifiable: each one can be checked in an afternoon, and the result decides whether the project exists.

1. **A system nobody knows how to rebuild from source cannot be modernised: it can be
   rewritten.** The test is rebuilding the production artifact from the repository on a
   clean machine. If it does not come out, there is no modernisation project — there is an archaeology
   project (§4.2), and that one comes first.
2. **Without characterisation there is no change.** A behaviour that is not captured (test, *golden
   master*, recorded and reproducible traffic) **cannot be preserved**: it can only be trusted to
   be. Characterisation is the gate, not a later deliverable.
3. **The business logic is not where the documentation says.** It is assumed to be in the code and in
   people, until proven otherwise by checking both against real behaviour.
4. **Migrating without a shutdown date is not migrating, it is duplicating.** Every incremental strategy is born with
   the old system's retirement date written down and with an owner; without it, the default result is
   two live systems forever and double the cost.
5. **The data outlives the code.** The data model is the asset that gets transferred; the code is
   replaceable. If the plan does not say what happens to the data and how it is proven to reconcile, it is not a
   plan (§6).
6. **Freezing is a decision, not a defeat — but only if it has containment, a patching window and
   a dated exit plan.** Freezing without the three things is not freezing: it is abandoning (§3.3).
7. **Nothing is decided with a figure that has no methodology.** More myths than data circulate in this domain
   (§2.2). The valid argument is the mechanism and your system's inventory, not a percentage.

**Not applicable**: besides the platforms routed in §1.2 —which win over this document in their
domain—, see `migration-projects-standards` (**cutover execution**: dependency
inventory, rehearsal, *cutover* window, abort criteria, integrity verification,
decommissioning. **Hard boundary: the strategy and what to do with the system, here; the cutover, there**);
`refactoring-tech-debt-standards` (**theirs** are the techniques and their attribution: *strangler fig*, branch by
abstraction, expand/contract, characterisation tests as a technique, the debt register with
principal and interest. **Here only when they are applicable to an inherited system and what to do when
they are not**, §3.1); `enterprise-architecture-standards` (**theirs** are the application inventory, the
TIME model and the choice of "R" **at portfolio level**; here the "R" **for this system** with the
technical criteria up front); `software-architecture-patterns-standards` (the design of the target);
`project-management-standards` (how the programme is funded, planned and committed);
`microservices-architecture-standards` (**shared warning**: decomposing an inherited monolith into
services is a *rearchitect*, not a cheap modernisation); `data-engineering-standards` (the
extraction and reprocessing pipelines themselves); `testing-qa-standards` (test strategy);
`bcdr-standards` (RTO/RPO and disaster); `itsm-itil-standards` (the service and change in operation);
`product-discovery-standards` (whether the inherited functionality still has value);
`tech-leadership-standards` (the investment decision and its record).

## 2. Default decisions: the "R"s and the criteria for each one

### 2.1 Taxonomy, with verified attribution

> **There is no canonical taxonomy of "the R"s, and the ones in circulation do not mean the same thing.** Before
> using the term in a meeting, define which one. Two verifiable sources:

- **Gartner (Richard Watson), *"Migrating Applications to the Cloud: Rehost, Refactor, Revise,
  Rebuild, or Replace?"*** — five alternatives. It is the origin the others cite; **the document is
  paywalled and I could not read the original**, so the date (2010 according to secondary sources, 2011 according to
  whoever cites it) **is a Declared gap** (§8).
- **AWS Prescriptive Guidance**, *About the migration strategies*, **verbatim**: *"There are seven
  migration strategies for moving applications to the cloud, known as the 7 Rs"* — **retire, retain,
  rehost, relocate, repurchase, replatform, refactor or re-architect**. Origin of the "6 R": Stephen
  Orban, *6 Strategies for Migrating Applications to the Cloud* (AWS blog, 2016), which explicitly
  credits Gartner's 5 Rs. **`relocate` is later.**

Practical consequence: **"refactor" in the Rs is not refactoring** in the sense of
`refactoring-tech-debt-standards` (changing structure while preserving behaviour). In the Rs it
means redesigning. It is the most expensive vocabulary confusion in this domain.

### 2.2 Figures that are NOT used

| Figure | Why not |
|---|---|
| "70 % of transformations fail" | No primary study; circular citation chain. **Already debunked in `project-management-standards` §2** — it is referenced, not repeated |
| CHAOS Report / Standish | Questioned methodology; **debunked in `project-management-standards`** (Eveleens & Verhoef) |
| "84 % of data migrations fail" | Restatement of **Bloor Research 2007**, which measured *overrun or aborted* (delay or cost overrun), **not failure**. Bloor itself published in **2011** a much lower figure with the same methodology. Both reports are **from a commercial analyst, vendor-sponsored and behind a form**: I could not read the primary source (§8). **A project that finishes a week late and an aborted one are not the same event** |
| "N billion lines of COBOL", "the 10x developer", "a bug costs 100× more later" | **Already discarded as folklore in this catalogue**; none has a published census or methodology. They are no use for justifying a modernisation |
| Any "% of applications that can be retired" | Circulates in vendor material with no census. **Your percentage comes from your inventory**, and it usually comes out high — but that is measured, not cited |

**Rule**: if a famous figure has no published methodology, **saying so is worth more than
citing it**. Modernisation is justified with the mechanism, the inventory and the measured cost (§5.2).

### 2.3 Criteria per strategy

> **Same taxonomy as `enterprise-architecture-standards` §3.5, with two proper names**: their
> `repurchase` is here *replace/repurchase*, and their `refactor/re-architect` is here *refactor/
> rearchitect*; this skill adds **rebuild** as a separate strategy because it has its own entry
> conditions. **Their order of evaluation —switch off before moving, buy before
> rewriting— applies to the portfolio**; here the specific system is decided, and **inverting that order
> requires written justification**, not technical preference.

| Strategy | When it is the right one | Sign that it is the wrong one |
|---|---|---|
| **Retain** (do not touch) | It works, it has current support, the cost of change exceeds the benefit, there are dependencies that migrate first | It is chosen out of not having looked; "retain" without a review date is §3.3 done badly |
| **Retire** (switch off) | Nobody uses it, or its function is covered by another system. **Proven with usage telemetry, not by asking** | It is switched off without measuring and up pops the quarterly process that did use it |
| **Rehost** (move the same binary) | The problem is the **hardware or the contract** (a datacenter closing, hardware with no spare parts, expired OS support), not the software | Fixing the infrastructure is expected to fix the application. It does not: you move the problem with fewer people who understand it |
| **Replatform** (minimal changes) | There is a specific component that can be replaced by a managed or supported one without touching the logic (DB engine, application server, runtime version) | The "minimal change" ends up touching the data model: it is no longer a replatform |
| **Refactor / rearchitect** | The system is yours, it can be characterised (§4.1), and there is an axis of change that the current design demonstrably blocks | It is justified with "it is a monolith". A monolith that does the job is not a reason |
| **Rebuild** (rewrite) | Only with the exceptional conditions of `refactoring-tech-debt-standards` §6.2 verified **and** the build rebuilt (§4.2). And even then, in parts | "We rewrite it in N months". See §7 |
| **Replace / repurchase** (buy) | The functionality is common to the sector and is not differentiating. **Exit cost assessed before signing** | It is bought to avoid doing archaeology. The data migration and the embedded rules are still yours, and now without source |

**The system is not chosen whole**: a real portfolio mixes several Rs per subsystem, and the choice is
reviewed when a fact changes (end of support, loss of the key person, security incident).

## 3. Incremental strategies and their real conditions

### 3.1 Strangler fig: it needs an interceptable seam

The technique and its attribution (Fowler, *Strangler Fig Application*; the current text on his bliki is
dated **22 Aug 2024** and describes the metaphor observed in Queensland in 2001) belong to
`refactoring-tech-debt-standards` §6.1. **What is decided here is the precondition**:

- **It requires a point where traffic can be intercepted and diverted function by function**, and
  **usage telemetry** to know when the old one stopped being used. Without both things it is not applicable.
- **Seams that do exist**: HTTP in front of the application, a queue or message *broker*, the
  database schema, an already exposed service layer, an exchange file between batches.
- **Seams people believe exist and do not**: a 5250/3270 screen, a compiled client-
  server form, a monolithic batch job that reads and writes the same database, code that composes
  and executes code at runtime (indirection, `EVAL`, dynamic SQL).
- **If there is no seam, the project's first task is to create one**, and it is a project in itself:
  interposing a facade, extracting a contract, or mediating through the data. **Presenting strangler fig as
  a plan when there is no seam is a plan that does not exist.**
- **Retiring the old one is part of the task**, with a date (invariant 4). A strangler fig without
  a retirement phase has created two systems.

### 3.2 Big bang: why it almost always fails and when it really is the only way

Mechanisms, not statistics: it concentrates all the risk in one instant with no intermediate
feedback; it forces functionality to be frozen for months while the old system keeps changing
(the finish line moves on its own); and the rollback is theoretical because the data has already moved.

**Honest exception — there are cases where it is the only way**, and denying it is as dishonest as
recommending it:
- **There is no seam and creating one costs more than the cutover**: small, monolithic and
  self-contained systems where interposing a facade is more work than redoing them.
- **The state cannot live split**: a ledger, a balances system or a legal register with
  transactional invariants that tolerate no double truth, not even for a few hours. Dual writing
  here does not reduce risk: it multiplies it.
- **The licence or the contract ends on a date** and there is no extension available for purchase: the cutover is the date,
  like it or not.
- **The source system does not allow technical coexistence**: a single licence seat, a single
  device identifier, an integrator that does not admit two consumers.

In those cases the big bang **is not mitigated with optimism, it is mitigated with rehearsal**: the execution
(prior rehearsal with real data, abort criteria, integrity verification, tested rollback)
belongs to `migration-projects-standards`.

### 3.3 Freezing with containment: a legitimate decision

> **The word is used for three different things in the catalogue and they are not interchangeable**: here,
> *freezing a system* —stopping its evolution for years, with containment—; in
> `migration-projects-standards`, *change freeze* around a cutover window, which
> lasts days and **requires a published end date**; in `erp-sap-standards`, the transport
> freeze, which is the previous case applied to a SAP landscape. Confusing them produces the
> typical error: a cutover freeze that nobody lifts and ends up being a de facto frozen system,
> but without any of the three conditions this section requires.

Freezing is the right answer when the system does the job, the knowledge to change it does not
exist, and the cost of modernising exceeds the **contained** residual risk. It requires the three things, in
writing and with an owner:

1. **Isolation**: network segmentation and default-deny, access only through a bastion, **filtered egress**,
   a facade in front so that no new consumer depends on its internal shape, and exposed
   surface reduced to the documented flows (`firewall-policy-standards`, `networking-standards`).
2. **Patching window**: what gets patched, at what cadence, and **what is done when the vendor
   stops publishing patches**. Verified Aug 2026 as an example that containment runs on someone
   else's clock: the Windows Server ESU programme is documented as *"a last resort option"* and for
   Windows Server 2012/2012 R2 it lasts **three years, ending 13 Oct 2026** — the date is set by the
   vendor, not by you (§8).
3. **Dated exit plan**: which event triggers the exit (end of support, loss of the person,
   exploitable CVE with no patch, regulatory change), who declares it and what is done that day.

**Freezing without the three is abandoning.** And **frozen does not mean untouchable**: it is fixed and
kept compliant; the new stuff is built outside, against the facade.

## 4. Hard preconditions: characterisation and archaeology

### 4.1 Characterisation before touching

- **The operational definition used here**: *legacy* is code without tests that capture its
  behaviour — **Michael Feathers, *Working Effectively with Legacy Code*, Prentice Hall PTR,
  2004**, which is also where the **characterisation test** comes from: it documents the
  **real** behaviour, not the correct one. If the observed differs from the specification, **the observed wins** and the
  discrepancy is recorded as a finding, it is not "fixed" along the way.
- **Forms that work on inherited systems**, in order of increasing cost:
  - **Batch golden master**: it is run with a representative input and the complete output is frozen
    (files, reports, resulting tables) as a binary or normalised reference.
  - **Traffic capture and replay**: real production traffic is recorded (respecting
    minimisation and personal data masking — `privacy-engineering-standards`) and replayed
    against old and new comparing responses. It is what makes a strangler fig verifiable.
  - **Parallel run (*shadow*)**: both systems process the same thing, only one responds, and
    differences are reconciled for weeks before switching over.
- **Representativeness, not coverage**: the characterisation input must include month-end close,
  the public holiday, the historically corrupt record and the rare case that motivated a patch in 2009. A clean
  synthetic dataset **characterises a system that does not exist**.
- **What characterisation cannot capture** —side effects outside the system (emails,
  files to third parties, printing, integrations) and clock-dependent behaviour— is
  inventoried explicitly. That is where the cutover incidents come from.

### 4.2 Archaeology: rebuilding the build and finding the source

Order of work, without skipping steps:

1. **Rebuild the build on a clean machine**, not on that of the colleague who has been there twenty years.
   Exact compiler, exact version, libraries, *toolchain* licences, link order,
   local patches. **Until this comes out, the modernisation project has not started.**
2. **Compare the rebuilt artifact with the production binary.** Expected differences
   (timestamps, build paths, non-deterministic ordering) are neutralised before concluding anything:
   `SOURCE_DATE_EPOCH` is exactly that — *"a standardised environment variable that distributions
   can set centrally and have build tools consume this in order to produce reproducible output"*
   (reproducible-builds.org, verbatim).
3. **If they do not match**, and that is the norm, the repository source **is not** the production one. There are
   patches applied hot, a branch that was never merged or a lost build machine. What
   is done:
   - It is **decompiled or disassembled just enough to locate the difference**, not to rewrite.
   - It is searched for in backups, images of retired servers and workstations of
     former staff — **with authorisation and with personal data criteria**.
   - If the difference cannot be explained, **the binary is the specification**: the binary is characterised
     (§4.1) and the source is downgraded to low-confidence documentation. It is written down that way in
     the ADR, with a name and a date.
4. **Freeze the result**: the reproducible build, its environment (container or versioned image) and
   the procedure go into the repository. It is the deliverable that survives even if the project is
   cancelled, and the only one that makes any future decision estimable.

## 5. Security and the cost of doing nothing

- **The default posture of an inherited system is "assume compromisable"**: unpatched runtime,
  obsolete cryptography, dependencies with no vendor. The detail belongs to the platform skill (§1.2)
  and to `vulnerability-management-standards`; here the consequence: **containment (§3.3) is a
  security control, not a convenience**, and its absence is recorded as an accepted risk with a signature.
- **Production data outside production**: any characterisation, rehearsal or parallel environment
  using real data requires masking and a legal basis. It is the most frequent breach in these
  projects and it is avoidable (`privacy-engineering-standards`).
- **The cost of doing nothing is calculated and put in the same table as the cost of modernising**, with three
  line items and **with your invoice, not with benchmarks**:
  1. **Extended support and contracts**: the price of vendor support, its annual escalation and its
     **hard end date** (§3.3). Verified Aug 2026: Microsoft **does not publish the ESU price on
     the programme page** — the figure comes from your quote, not from this skill (§8).
  2. **Security risk**: exposed surface, CVEs with no patch available and the cost of the
     compensating control you are already paying for.
  3. **People**: not "shortage of X programmers" in the abstract, but **how many people in your
     organisation can modify the system today, and their horizon**. If the answer is one, you already
     have the reason and the date.

## 6. The two real assets: the data and the person

- **The data model is the asset that gets transferred.** Before choosing a strategy: where the
  data is, which is the system of record, **which integrity rules live outside the schema** (in
  the code, in a nightly batch, in a spreadsheet) and what happens to the history that the new
  application does not model. Documenting it with an owner is **the only work that has to be done even if it is never
  migrated**.
- **Extraction is not the migration.** Getting the data out is the easy part; proving that it reconciles at the target is
  what gets underestimated, and its execution belongs to `migration-projects-standards` (integrity,
  reconciliation) with the pipelines in `data-engineering-standards`.
- **Logic that exists only in the code and in one person** is a risk with an owner and a date: what is extracted
  from that person is **the rule, not the documentation** —what it decides, with which inputs, with which
  exceptions— and **each rule becomes an executable characterisation case** (§4.1). An
  interview with no associated test evaporates; its preservation belongs to `knowledge-management-standards`.
- **Where to look for the rule in the code is decided by the platform skill**, not this one: on IBM i,
  `ibm-i-rpg-standards` §3.4 says in which eight places it hides (RPG, CL, *triggers*, DDS, the
  5250 sequence itself, exit points, Query/400 and the spreadsheets hanging off ODBC) and
  with which tools it is located, **with its blind spots declared**. This gate requires the
  artifact; **the specific archaeology is theirs**.
- **Warning**: the key person is usually also the one keeping the system standing. Scheduling their
  succession and the modernisation at the same time is the most common way of losing both things.

## 7. Sustainability and prohibitions

**Cadence**: the decision about an inherited system **expires**. It is reviewed at least annually and
whenever a fact changes: announced end of support, exploitable CVE with no patch, departure of the
key person, regulatory change, or the vendor selling the product. The review produces a
dated decision, not a report.

**FORBIDDEN**
- ❌ **Rewriting without characterisation tests.** Without captured behaviour you are not migrating
  functionality: you are guessing what it was.
- ❌ **Migrating and keeping both versions alive indefinitely with no shutdown date.** Every
  incremental strategy is born with the old one's retirement date and with an owner (invariant 4).
- ❌ **"We rewrite it in N months" without having rebuilt the build first** (§4.2). An estimate
  about a system nobody knows how to compile is not an estimate.
- ❌ Presenting **strangler fig** as a plan when **there is no interceptable seam** (§3.1).
- ❌ **Automatic code translation to another language presented as modernisation**: it inherits
  the original's structure, loses the target's idioms and replaces a system somebody understood
  with one nobody understands. As an intermediate step with characterisation and a subsequent
  rehumanisation plan, it can be worth it; **as a final deliverable, no**.
- ❌ **Justifying the decision with failure figures that have no methodology** (§2.2), in any direction.
- ❌ **LLM-assisted rewriting presented with a productivity figure.** The only randomised
  trial with published methodology in this line —METR, arXiv 2507.09089— measured **the opposite
  of what was expected** on experienced developers working on **their own** mature code, and **METR
  itself marks it as historical**; the evidence is maintained by `ai-agent-workflow-standards`. **The
  consequence here**: the LLM is excellent at **reading** inherited code —explaining a routine, locating
  where something is decided, proposing candidate characterisation tests— and **its output is verified
  against the characterisation, always**. Its honest limit: it does not know which business rule lies behind
  a special case written in 1998, because that information **is not in the code**.
- ❌ Freezing **without** isolation, a patching window and a dated exit plan (§3.3).
- ❌ Copying production data to a characterisation or rehearsal environment **without masking**.
- ❌ Switching off a system **without usage telemetry** proving nobody uses it (§2.3, *retire*).
- ❌ Choosing an "R" in a spreadsheet **without the platform's technical criteria up front** (§1.2).
- ❌ Treating the repository source as the production one **without having checked it** (§4.2).

## 8. Mandatory web verification

Before committing to anything in a real project, **look it up — do not recall it**:

1. **End of support and of extended support** for each component of the system (OS, runtime, DB
   engine, application server, hardware), on the **vendor's lifecycle page**, not on
   an aggregator. It is the datum that fixes the exit plan's date (§3.3) and the one that expires fastest.
2. **Price and conditions of extended support** (§5): **declared gap** — neither Microsoft on the
   ESU page nor Oracle, IBM or SAP publish a rate. It comes from your contract; it is not cited from a blog.
3. **CVEs with no patch available** in the legacy stack, with KEV/EPSS, before deciding to contain instead
   of migrating (`vulnerability-management-standards`).
4. **Taxonomy of the Rs** (§2.1): **declared gap** — the Gartner document is paywalled and the
   secondary sources disagree between 2010 and 2011. The AWS list is public and is cited
   verbatim; confirm it has not changed.
5. **Migration failure figures** (§2.2): **declared gap** — the Bloor Research reports
   (2007 and 2011, Philip Howard) are behind a form and vendor-sponsored and **I could not read
   the primary source**. If you need to cite them, read them yourself and say **what exactly they measure**.
6. **Evidence on LLM assistance with legacy code**: the state of the studies with published
   methodology via `ai-agent-workflow-standards`, which is the one that maintains it. **Any productivity
   figure from a tool vendor is marketing material** unless it publishes design
   and data.
7. **Status of the platform skills in §1.2** and whether a new one has appeared: the table is the
   main value of this skill and degrades silently if it goes stale.

If you cannot verify, say so explicitly instead of assuming.

If the web contradicts this document, **the web wins** — flag the discrepancy.
