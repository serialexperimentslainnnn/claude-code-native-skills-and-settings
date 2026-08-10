---
name: ada-standards
description: Ada and SPARK for high-integrity software. Use when working with .ads/.adb specification and body files, .gpr GNAT project files and gprbuild/gprclean/gprinstall, alire.toml and the alr package manager, GNAT compilation with -gnat2012/-gnat2022/-gnatwa/-gnatwe/-gnata/-gnato/-gnatX, GNAT Pro versus GNAT FSF builds, gnatprove and SPARK_Mode with the Stone/Bronze/Silver/Gold/Platinum adoption levels, contract aspects Pre/Post/Contract_Cases/Type_Invariant/Predicate/Global/Depends/Loop_Invariant/Loop_Variant, subtype and range constraints with Constraint_Error, pragma Restrictions and pragma Profile (Ravenscar) or Profile (Jorvik), tasks protected objects entries and rendezvous, Ada.Containers Bounded and Formal containers, Unchecked_Deallocation and Unchecked_Conversion, representation clauses and Interfaces.C bindings, gnattest/AUnit, gnatcov coverage and gnatcheck/GNATformat, or evaluating Ada against Rust and Ferrocene for a DO-178C, EN 50128, IEC 61508 or ISO 26262 project.
---

# Ada and SPARK standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Ada and its verifiable subset **SPARK** in software where **a failure costs lives or irrecoverable
money**: avionics, rail, defence, space, automotive, medical devices and critical
infrastructure. It is still chosen for new systems in those domains, and there it is not
legacy — it is a current technical decision.

**The axis of this skill, and the language's reason to exist: in Ada most of the specification
is written in the type system, and the compiler or the prover checks it.** A valid range of
values is not an `if` at the start of the function: it is a subtype. A structural invariant
is not a comment: it is a `Type_Invariant`. An input/output contract is not a test: it is
`Pre`/`Post`, and with SPARK it is **proved** instead of exercised. All the criteria here consist of
**moving the check into the type and the contract** — Ada code written with `Integer` everywhere
and hand-written checks is C with odd syntax, and it buys nothing.

And the counterpart, said without decoration: **Ada is expensive**. Expensive in learning curve, expensive in
hiring (the market is small and concentrated in a few sectors and vendors), and expensive in
tooling if you are going to certify. §7 sets out where that pays for itself and where it is pure overhead.

Covers: language versions and their support; GNAT distributions and their licence; Alire as the
package manager; types, subtypes and contracts as a design mechanism; SPARK and the adoption levels;
tasking and real-time profiles; interoperability; and the honest comparison with Rust.

**Not applicable**: see `safety-critical-standards` (**theirs the whole functional safety
and certification process** — hazard analysis, DAL/SIL/ASIL allocation, objectives and
evidence for DO-178C/DO-330, EN 50128, IEC 61508, ISO 26262, tool qualification,
requirements traceability, audit and the relationship with the authority; **here only what the
language and formal proof contribute to that evidence, and with which flags**), `embedded-iot-standards`
(the physical target — MCU, boot, memory, peripherals, RTOS, power, field
update; **here the Ada code that runs on top and the choice of restricted runtime**),
`rust-standards` (**the direct competitor in memory safety and the obligatory comparison of §7**:
Rust and its toolchain are theirs; **the choice between the two for a high-integrity project is
argued here and there with the same data**), `c-standards` and `cpp-standards` (**the other side of
`Interfaces.C`**, and the owner of MISRA C / CERT C — the realistic alternative when the answer is
not Ada), `assembly-standards` (inserted machine code and its justification),
`cryptography-pki-standards` (algorithm choice), `appsec-standards`
(threat modelling), `vulnerability-management-standards` (triage and SLA),
`testing-qa-standards` (test strategy: **formal proof does not replace the strategy, it
complements it**), `cicd-standards` (the pipeline that runs the §4 gates),
`git-workflow-standards`, `opensource-licensing-standards` (**GNAT's runtime exception is the
fact that decides whether you can distribute your binary**, §2), `grc-compliance-standards` (general
regulatory framework), `refactoring-tech-debt-standards`, `legacy-modernization-standards` (there is a lot of old Ada 83/95 that is not "high integrity", just old — the portfolio
decision is theirs).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Choice | Verified as of Aug 2026 |
|---|---|---|
| Language version | **Ada 2012** as the safe baseline; **Ada 2022** when the compiler and the process allow it | **Ada 2022 = ISO/IEC 8652:2023, published May 2023**. GNAT implements it with `-gnat2022`; **GNAT's default is still Ada 2012** — if you want 2022, you ask for it |
| Status of Ada 2022 in GNAT | Implemented; **verify by *Ada Issue*, not wholesale** | The *GNAT Reference Manual* has a chapter "Implementation of Ada 2022 Features" organised **by WG9-approved AI**: that is the reference, not a "yes/no". GNAT Pro 22 declared the implementation complete |
| Experimental extensions | **Forbidden in production** | `-gnatX` enables features from the RFC platform; AdaCore marks them explicitly as not intended for production and subject to change |
| Commercial distribution | **GNAT Pro** (AdaCore) if you are going to certify | It is what brings support, tool qualification and certifiable runtimes. **No public pricing: declared gap (§8)** — the cost is negotiated and is a project line item, not a detail |
| Free distribution | **GNAT FSF** via **Alire** | **GNAT Community is discontinued: 2021 was the last release** (announced May 2022). Do not install it "because it comes up first on Google"; at most it serves for *bootstrap* |
| How it is installed today | **Alire (`alr`)**: it picks a compiler on first run and brings the most recent GNAT FSF | **Alire v2.1.1 (2026-05-29)**. SPARK is added with `alr with gnatprove`. The binaries come from `alire-project/GNAT-FSF-builds` (packages: `gnat`, `gprbuild`, `gnatprove`, `gnatdoc`, `gnatcov`, `gnattest`, `gnatformat`) |
| Alire licence | **GPL-3.0, verified by reading the raw `LICENSE.txt`** | It is the licence **of the `alr` tool**, not of your code nor of your dependencies — but **read it yourself before assuming "it will be MIT"**, which is exactly the assumption that fails |
| Runtime licence | **The fact that decides whether you can distribute** | GNAT's historical friction was the runtime under pure GPL (distributing the binary required GPL-compatible terms). AdaCore's current approach separates **GNAT Pro** (industrial) from **GNAT FSF** (community, *"without pure GPL run-times"*). **Verify the runtime exception of the exact distribution you use before distributing a closed binary** (§8) |
| Build | **gprbuild** with `.gpr` files | It is the ecosystem standard and what the tools understand (`gnatprove`, `gnatcov`, `gnattest`). Alire generates and manages the `.gpr` |
| Dependencies | `alire.toml` versioned; versions pinned | Small ecosystem: **audit every crate you pull in**, there is no volume to give statistical confidence |
| Formal proof | **SPARK / `gnatprove`**, adopted by levels (§4) | It applies to **subsets of the code**, not to the whole program — that is the intended usage model |
| Real time | **`pragma Profile (Ravenscar)`**; `Jorvik` if Ravenscar is too tight | **Jorvik is from Ada 2022** (AI12-0291) and is defined alongside Ravenscar in **RM D.13** |

## 3. Design: the type is the contract

- **Never use `Integer` for a bounded domain.** Declare the type or subtype with its range
  (`subtype Percent is Integer range 0 .. 100`), and the compiler inserts the check that raises
  `Constraint_Error` at the point of the violation — not 200 lines later. **A different physical
  unit is a different type**: mixing metres and feet must be a compile error, not an
  incident.
- **Contracts with aspects, not with comments**: `Pre`, `Post`, `Contract_Cases`,
  `Type_Invariant`, `Dynamic_Predicate`/`Static_Predicate`, `Default_Initial_Condition`. And for
  SPARK, additionally `Global` and `Depends` (which global state it touches and what each output depends on) and
  `Loop_Invariant`/`Loop_Variant` in loops.
- **`Global => null` is a strong and free assertion**: it declares that the subprogram touches no global
  state. Put it where it is true; the prover uses it and the reviewer reads it.
- **Packages with a private part**: the type is exported as `private` (or `limited private`) and the
  operations are the package's. Exposing the representation is the most common design failure in Ada
  written by people coming from C.
- **Aspects versus `pragma`**: Ada 2012 introduced the aspect syntax and **it is the preferred
  form** for what exists in both. `pragma` is left for what has no aspect
  (`Restrictions`, `Profile`, `Assertion_Policy`, `Ada_2022`).
- **Dynamic memory: by default, no.** In high integrity, heap allocation after
  initialisation is forbidden (`pragma Restrictions (No_Allocators)` or equivalent) and **bounded
  containers** (`Ada.Containers.Bounded_*`) or **formal** ones (`Ada.Containers.Formal_*`, provable with
  SPARK) are used. If a heap is needed, it goes with its own bounded *storage pool*.
- **`Unchecked_Deallocation` and `Unchecked_Conversion` have "Unchecked" in the name for a reason**:
  each use is an exception to the model, is justified in writing and is isolated in a small package with
  its own analysis. Same with `Address` and representation clauses.
- **Exceptions**: useful at application level, **restricted or forbidden** at certified
  level (analysis cost and runtime code). Decide the policy **once**, write it
  in `pragma Restrictions`, and let the compiler enforce it. An `others =>` that swallows and carries on is
  forbidden always.
- **Tasking**: under `Ravenscar` or `Jorvik`, or do not use it. The practical difference —verified in
  RM D.13— is that **Jorvik relaxes** `No_Implicit_Heap_Allocations`, `No_Relative_Delay`,
  `Max_Entry_Queue_Length => 1`, `Max_Protected_Entries => 1`, the dependency on `Ada.Calendar` and on
  `Ada.Synchronous_Barriers`, and replaces `Simple_Barriers` with `Pure_Barriers`; **`No_Requeue_Statements`
  remains forbidden in both**, and **all Ravenscar code is valid in Jorvik** (not the other way round).
  Criteria: **Ravenscar by default** because it is what gives the best timing analysis and the most
  established certification evidence; Jorvik when Ravenscar forces contortions (several entries per
  protected object, non-unit queues, relative `delay`) — **and that is justified in an ADR, because
  you buy expressiveness by paying with analysability**.

## 4. Verification: SPARK levels and CI gates

**SPARK is adopted by levels**, not all at once. **Verbatim** names from the joint AdaCore–Thales guide
*Implementation Guidance for the Adoption of SPARK*: *"Stone level – valid SPARK; Bronze level –
initialization and correct data flow; Silver level – absence of run-time errors (AoRTE); Gold level –
proof of key integrity properties; and Platinum level – full functional proof of requirements."*

And its usage recommendation, which is the part people skip: **Stone only as an
intermediate level during adoption; Bronze in as much of the code as possible; Silver as the default
objective for critical software; Gold only in the subset with a specific safety need**.
Each level is a subset of the previous one. **Platinum is exceptional**: full functional proof
against requirements, and very few people can justify its cost.

Default objective for a new high-integrity project: **Silver in the core, Bronze in the
rest, Gold in the properties that the hazard analysis flags.**

CI gates, in increasing order of cost:

1. **Compilation without warnings**: `-gnatwa -gnatwe` (all warnings, and warnings are errors),
   `-gnatf` (full messages), explicit `-gnat2012`/`-gnat2022` and `-gnaty` with the project's
   style in the `.gpr`. **`gnatcheck`** with the project's rules and **GNATformat** for
   formatting — formatting is not discussed in review.
2. **Validation build with all checks enabled**: `-gnata` (enables `Pre`/`Post` and
   assertions), `-gnato` (integer overflow checking), and **without disabling
   checks**. **`pragma Suppress` is forbidden except with a performance measurement and an ADR** —
   removing range checks is throwing away the only thing you are paying the language for.
3. **`gnatprove` at the committed level**, and **the level is a gate**: if the package is declared
   Silver, an undischarged proof obligation breaks the build. Justifications (`pragma
   Annotate` to dismiss a message) are reviewed **one by one** the way an `unsafe` is reviewed in
   Rust: each one is a human promise standing in for a proof.
4. **Tests with `AUnit`/`gnattest`** covering the happy path, **edges and errors** — including the
   exceptions the design allows. Formal proof covers absence of run-time errors and
   properties; **it does not cover whether you understood the requirement**.
5. **Coverage with `gnatcov`** to the criterion the allocation level demands (in avionics, up to
   MC/DC). **The coverage criterion is set by the standard, not by the team** — see `safety-critical`.
6. **Timing (WCET) and stack analysis** if there are real-time requirements: it is what the Ravenscar/Jorvik
   profile exists to make possible; if you do not measure it, the profile bought you nothing.

## 5. Stack security

- **Ada eliminates by construction a good part of the classic CWEs** (buffer overflow, index out
  of range, silent integer overflow, use of uninitialised data with SPARK Bronze) — **provided
  you do not disable the checks**: a binary with `-gnatp` loses precisely that.
- **What Ada does NOT give you**: logical correctness, authorisation, injection into external
  systems, misused cryptography, secrets management, and **nothing that happens on the other side of
  `Interfaces.C`**. The real surface of an Ada system is its interfaces and its bindings.
- **Bindings**: each one is a boundary where the subtypes are lost. It is wrapped in a package that
  **revalidates on entry** (converts to the Ada subtype and lets `Constraint_Error` fire) and documents
  who frees what. The C side belongs to `c-standards`. Same with input data: it is validated by
  converting to restricted subtypes, not with scattered `if`s, and binary protocols are read with
  representation clauses, never with `Unchecked_Conversion` over the buffer.
- **Supply chain**: small ecosystem = few hands reviewing. Pin versions in
  `alire.toml`, audit what you pull in and **do not assume the licence** (§2). CVEs of the compiler, runtime,
  RTOS and linked C libraries, in `vulnerability-management-standards`.

## 6. Performance and operability

In this domain the dominant requirement is **determinism**, not average performance; a short section.

- **Size for the worst case** (WCET, maximum stack usage, memory bound), not for the average. A
  system that is fast "almost always" does not comply.
- **The cost of range checks is real but small and almost never the bottleneck.** Measure
  before suppressing; and if you must suppress, in the specific subprogram and **only if SPARK has proved
  that the check cannot fail** — the only defensible suppression, and that is what Silver is for.
- **No dynamic allocation after initialisation** (§3): out with fragmentation and unpredictable
  latency. **Runtime**: the smallest one that meets the requirements (light / light-tasking / embedded / full);
  each step up adds surface to justify in certification.
- **Operability**: a last-resort handler that logs and takes the system to a defined safe
  state. A `Constraint_Error` in production is a first-order diagnostic: it must be captured.

## 7. When Ada, when Rust, when neither — and prohibitions

**Ada/SPARK pays for itself when** there is (a) a certification requirement with admissible formal evidence,
(b) a catastrophic or irreversible cost of failure, (c) a system lifetime measured in decades —Ada ages
exceptionally well and 1990s code still compiles—, or (d) an Ada codebase and a
team that knows it already exist.

**Ada is pure overhead when** the problem is a business application, a web service, an
internal tool or anything with changing requirements and no catastrophic cost of failure.
The rigour of the type system does not offset the cost of hiring and of the ecosystem. **Saying so is
part of the criteria**: recommending Ada for technical elegance on a CRUD is bad advice.

**Ada versus Rust — the honest comparison, with 2026 data:**

| Axis | Ada/SPARK | Rust |
|---|---|---|
| Memory safety | Through checks + subtypes; **no guaranteed absence of use-after-free** except with restrictions and SPARK | Guaranteed at compile time by the *borrow checker* outside `unsafe` |
| Formal proof | **Mature and integrated into the language** (`gnatprove`, levels Stone→Platinum). It is its differentiating advantage and has no equivalent in Rust | Verification tools exist but **not at SPARK's level of maturity or integration** |
| Concurrency | Tasking in the language, with analysable profiles (Ravenscar/Jorvik) | Absence of *data races* through types (`Send`/`Sync`), with no standard timing-analysis profile |
| Certified toolchain | Decades of track record and acceptance by authorities | **Ferrocene**: qualified by TÜV SÜD for **ISO 26262 (ASIL D)**, **IEC 61508 (SIL 3)** and **IEC 62304 (Class C)**, and it **supports customer certification efforts towards IEC 61508 SIL 4 and DO-178C (DAL C)** — which is **not the same as being qualified at those levels**; some sources confuse the two. Release 26.02.0 adds **ISO 26262 (ASIL B)** for the certified subset of `core` |
| Ecosystem and hiring | Small, concentrated, expensive; scarce but very stable people | Much larger and growing; easier to hire, less track record in certification |

**Arbitration criteria**: if you need **formal proof of functional properties**, it is SPARK, no
discussion. If you need **memory safety in systems code with a viable ecosystem and hiring
pool** and the required certification level is within what the Rust toolchain covers today, Rust
is defensible and increasingly so. **And do not mix levels across standards**: the cross-mapping
SIL↔ASIL↔DAL that circulates in tables **is not normative** —ISO 26262 does not define it, not even informatively,
and ASIL is qualitative while SIL is probabilistic—, so a SIL 3 component is **not** declared
ASIL D without its own evidence. Besides, DALs are allocated by **ARP4754/ARP4761**; DO-178C defines the
assurance objectives for the given DAL. Cite it correctly or `safety-critical` will correct you.

**Prohibitions:**

- ❌ **FORBIDDEN** `pragma Suppress` / `-gnatp` without a performance measurement and without SPARK proof that
  the suppressed check cannot fail. It is throwing away the only thing that justifies the language.
- ❌ Compiling without `-gnatwa -gnatwe`, or shipping with warnings.
- ❌ `-gnatX` (experimental extensions) in production: AdaCore explicitly advises against it.
- ❌ Bare `Integer`/`Float` for bounded domains; declaring the subtype is the rule.
- ❌ `Unchecked_Conversion`, `Unchecked_Deallocation`, `Address` and representation clauses without
  written justification and without isolation in a small package.
- ❌ Dynamic allocation after initialisation in certified code.
- ❌ Tasking without `pragma Profile (Ravenscar)` or `(Jorvik)` in real time; and **Jorvik without an ADR**.
- ❌ `when others =>` that catches and carries on without logging or taking the system to a safe state.
- ❌ Declaring a SPARK level and not making it a CI gate: a level that does not break the build is marketing.
- ❌ `gnatprove` justifications (`pragma Annotate`) accepted wholesale or without a reviewer: they are
  reviewed one by one.
- ❌ Installing **GNAT Community**: discontinued, last release 2021 (§2).
- ❌ Distributing a closed binary without having read the runtime exception of your GNAT
  distribution (§2, §8).
- ❌ Presenting the SIL↔ASIL↔DAL mapping as normative (§7).
- ❌ Recommending Ada for a domain with no integrity requirement "because it is safer": the cost of
  ecosystem and hiring is not recovered.

## 8. Mandatory web verification

Before committing anything in a real project, check on the web:

1. **Status of Ada 2022 in your compiler**, in the *"Implementation of Ada 2022 Features"* chapter
   of the GNAT Reference Manual, **by Ada Issue**. Also confirm that Ada 2022 = **ISO/IEC
   8652:2023 (May 2023)**.
2. **GNAT distribution**: current GNAT Pro version and its roadmap; the GNAT FSF version that
   Alire serves; and **that GNAT Community is still discontinued** (last release 2021).
3. **Alire**: version (as of Aug 2026 **v2.1.1**, 2026-05-29) and licence — **GPL-3.0 verified by reading
   the raw `LICENSE.txt`**; the packages available in `GNAT-FSF-builds`.
4. **The runtime exception of your exact distribution**, read raw, **before distributing a
   binary**. It is the expensive licensing fact of this domain and it is not settled by analogy with another
   GCC project. With `opensource-licensing-standards`.
5. **Cost of GNAT Pro and of the qualified tools**: **declared gap — AdaCore does not publish
   pricing**. Any cost figure must come from your contractual quote. The same for the
   cost of tool qualification (DO-330) and of certifiable runtimes.
6. **SPARK**: `gnatprove` version, the provers it bundles, and **the exact names of the five
   levels** in the current edition of *Implementation Guidance for the Adoption of SPARK*.
7. **Ferrocene** (for the §7 arbitration): **qualified** levels versus levels **supported
   for customer certification efforts** — as of Aug 2026, ASIL D / SIL 3 / IEC 62304 Class C
   qualified, and SIL 4 and DO-178C DAL C as support; release 26.02.0 with ASIL B for the
   `core` subset. **This nuance is misread in secondary sources, including academic ones.**
8. **Current editions of the standards** (DO-178C/DO-330, EN 50128, IEC 61508, ISO 26262) and their
   level names **verbatim** — with `safety-critical-standards`, which is
   **the owner of all that criteria**.
9. CVEs and advisories for the compiler, the runtime, the RTOS and the linked C libraries.

If the web contradicts this document, **the web wins** — flag the discrepancy.
