---
name: safety-critical-standards
description: Functional safety and certification evidence for software whose failure can injure or kill. Use when working to IEC 61508 (SIL 1-4, systematic capability, route 1S/2S), ISO 26262 (ASIL A-D, HARA with severity/exposure/controllability, ASIL decomposition, freedom from interference, ISO 21448 SOTIF), DO-178C/ED-12C with its supplements DO-330, DO-331, DO-332 and DO-333, DAL/FDAL/IDAL assigned by ARP4754B and ARP4761A, DO-326A/ED-202A and DO-356A airworthiness security, EN 50128 or EN 50716:2023 and EN 50126/EN 50129 railway software, IEC 62304 software safety classes A/B/C with ISO 14971 risk management, ISO/SAE 21434 and UN R155/R156, a hazard log or safety case (GSN), FMEA/FMEDA, fault tree analysis, HAZOP, requirement-to-design-to-code-to-test traceability matrices, structural coverage (statement, decision, MC/DC) and dead or deactivated code, tool qualification (TQL-1..TQL-5, tool criteria 1/2/3, TCL1-3, T1/T2/T3), MISRA C or MISRA C++ or SPARK/Ada subsets, Ferrocene qualified Rust, WCET and stack analysis, ARINC 653 or MMU-based partitioning, watchdogs and safe degraded states, or assembling evidence for an assessor, DER or notified body.
---

# Safety-critical software standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **a software failure can injure or kill someone**, or destroy something whose loss
kills: a car, a train, an aircraft, a ventilator, an infusion pump, a press, a turbine. The purpose
of this skill **is not writing the code**: it is **producing the evidence** that that code was
developed under a process an authority, a notified body or an independent assessor will accept.
In this domain, **code without evidence does not exist**.

**The distinction that orders the whole document:**

- ***Safety***: that the system **does no harm** when it fails or when the world behaves in an
  unexpected way. Adversary: chance, wear, design error, the confused operator.
  Metric: probability of dangerous failure per hour, and process rigour.
- ***Security***: that **nobody manages** to make the system do harm. Adversary: an intelligent
  person, with resources, who **chooses** the worst moment and the worst path.

They are disciplines with different mathematics: *safety* reasons with random failure rates and
statistical independence; *security* reasons with an attacker who **deliberately breaks that
independence** —the common-cause failure mode is caused by him—. That is why a fault tree calculation
does not work for an attack, and why a 2oo3 redundancy of three channels with the same firmware
**buys nothing** against an adversary even though it buys a lot against chance.

**And today they cannot be separated, as a matter of regulation, not opinion**: regulation itself has
welded them together. Automotive: **UN R155** requires a cybersecurity management system (CSMS) as a
condition of **type approval**, and **UN R156** a software update management system (SUMS) —
mandatory for new vehicle types since **July 2022** and for all new vehicles since **July 2024**
(verify per country, §8). Avionics: the set **DO-326A/ED-202A** + **DO-356A/ED-203A** +
**DO-355/ED-204** treats information security **as an airworthiness process**, with EASA's AMC 20-42
as an acceptable means of compliance. Industrial: the ongoing revision of **IEC 61508** incorporates
cybersecurity aligned with **IEC 62443**. Railway: **EN 50716:2023** explicitly incorporates
cybersecurity considerations that EN 50128 did not have.

**House rule**: *a hazard analysis that does not consider the intentional cause is incomplete, and a
threat analysis that does not quantify the physical consequence is disconnected.*
Both are done, they are cross-checked, and the result goes **into the same risk register**.

Covers: which standard applies per sector and what integrity level is assigned and how; the V
lifecycle and its artifacts; traceability as the artifact that actually gets audited; structural
coverage; safety analysis (FMEA, FTA, HAZOP, HARA); tool qualification; language and subsets;
determinism, WCET, partitioning and safe state; and how it fits with information security.

**Verification note that conditions the whole document**: **IEC, ISO, RTCA, SAE and CENELEC sell
their standards.** Their text **could not** be read verbatim here. What this document states about the
*content* of those standards comes from secondary sources (tool vendors, notes from bodies) and
**is marked as such in §8**. What was verified in accessible primary sources —IEC catalogue records,
CENELEC dates, vendor documentation— is cited with its exact data.
**Before committing to a certification plan, you buy the standard and read it.** A misquoted objective
here costs an audit cycle.

**Not applicable**: see `ada-standards` (**the Ada language, SPARK and its toolchain are theirs** —levels
Stone→Platinum, `gnatprove`, Ravenscar/Jorvik profiles, `gnatcov`, GNAT distributions and their
runtime exception—; **here, which coverage criterion and which evidence the standard demands for the
assigned level**, which is what that skill explicitly delegates), `rust-standards` (**Rust and its
toolchain are theirs**; here only the qualification status of the chain, §2), `c-standards` and
`cpp-standards` (**owners of MISRA C / MISRA C++ / CERT C, the sanitizers and binary hardening**;
here only *that* a subset is required and with which documented deviations),
`embedded-iot-standards` (**the physical target is theirs**: silicon, boot, device tree, memory,
power, firmware image and its field update; here the assurance process of the software that runs on
top), `kernel-drivers-standards` (supervisor-mode code and its upstream process),
`ot-ics-security-standards` (**the industrial plant and its security are theirs**:
IEC 62443, zones and conduits, Purdue model, fieldbus protocols, SIS as an operated asset —
**declared boundary: the *development* of the SIS software under IEC 61508/IEC 61511 belongs here; its
*operation*, segmentation and monitoring, theirs**), `grc-compliance-standards` (management framework,
SoA, formal acceptance of corporate risk and **general** audit evidence; here the technical functional
safety dossier, which is another artifact and goes to another auditor),
`appsec-standards` (STRIDE and application vulnerability classes),
`vulnerability-management-standards` (CVSS/EPSS/KEV triage — **and the reciprocal warning: an IT
patching SLA is not applicable to type-approved equipment**), `cryptography-pki-standards` (algorithms,
curves and key lifecycle, including firmware signing), `testing-qa-standards`
(**general test strategy and the pyramid**; here the coverage criterion **imposed by the standard**,
which is not negotiated with the team), `cicd-standards` (the pipeline that runs the gates in §4),
`healthtech-fhir-standards` (**sister skill, declared boundary**: **theirs** is health software as an
information product —FHIR, HL7 v2, terminologies, clinical record— and **the MDR/IVDR regulatory
classification of whether a piece of software is a medical device**; **from here** the IEC 62304
lifecycle process and the ISO 14971 risk management of that product once classified),
`ai-governance-standards` (AI Act, AI risk classification and accountability — **here the
problem, unsolved, that a learned component has no line-by-line traceable requirements**,
§7), `incident-management-standards` (incident governance),
`bcdr-standards`, `observability-standards`, `offensive-security-standards` (**this skill is
defensive**).

## 2. Default decisions

> Verify the edition in force and its withdrawal date on the web before pinning it in a real project (§8).

### 2.1 Which standard rules, by sector

| Sector | Software standard | Integrity scale | Verified as of Aug 2026 |
|---|---|---|---|
| Generic / industrial (E/E/PE) | **IEC 61508-3** | **SIL 1 – SIL 4** (4 = most demanding) | Edition **2.0, published 2010-04-30, in force, stability date 2027** (IEC catalogue record, verbatim). **Edition 3 at CDV**, publication expected ~2027: **do not plan against it** |
| Continuous process | **IEC 61511** (sector application of 61508) | SIL 1–3 in practice | Outside this skill's detailed scope; see `ot-ics-security` for its operation |
| Automotive | **ISO 26262-6** (software) | **ASIL A – ASIL D** (**D = most demanding**) + **QM** | 2018 series. **ISO 21448 (SOTIF)** covers what 26262 does **not**: *intended function* failures with no fault |
| Avionics | **DO-178C / ED-12C** | **DAL A – DAL E** (**A = most demanding**, E = no safety effect) | The **DALs are assigned by ARP4754B/ARP4761A**, not DO-178C (§2.2) |
| Railway | **EN 50716:2023** | SIL 0 – SIL 4 | **Verbatim title: "Railway Applications - Requirements for software development"**. Published **2023-11-16**; **supersedes EN 50128:2011 (+AC:2014, +A1:2020, +A2:2020) and EN 50657:2017 (+A1:2023)**; **DoW 30-10-2026** — the live date of this domain |
| Medical device | **IEC 62304** | **Class A / B / C** | Class A: no injury is possible; B: non-serious injury; C: death or serious injury (secondary source, §8). **Edition 2 in draft** with **two levels of rigour** instead of three classes: not verified against an IEC source (§8) |
| Medical device risk management | **ISO 14971** | — | A process, not a scale. Feeds the IEC 62304 classification |
| Space | ECSS-Q-ST-80C / ECSS-E-ST-40C | Criticality A–D | ECSS publishes its standards **openly**: use it, it is the only body of standards in this domain you can read verbatim without paying |

**The SIL ↔ ASIL ↔ DAL cross-mapping that circulates in blog tables is NOT normative.** None of the
three standards publishes it as an equivalence, and the scales do not even measure the same thing:
**SIL is probabilistic** (dangerous failure rate per hour / probability of failure on demand), **ASIL is
qualitative** (S/E/C matrix), **DAL is a failure-condition category** assigned at system level.
Operational consequence, no exceptions: **a component certified SIL 3 is not declared
ASIL D or DAL B by analogy**; you do a documented *gap analysis*, identify the missing evidence
and produce it. Whoever sells a component as "SIL 3 / equivalent to ASIL D" is selling a
commercial argument, not evidence. `ada-standards` upholds this same prohibition.

### 2.2 The avionics nuance that almost everybody quotes wrong

**DO-178C does not assign the DAL.** The level comes from the safety process **at system and
aircraft level**: the functional hazard assessment and the safety analysis of **ARP4761A**
determine the severity of the failure condition, and **ARP4754B** assigns the **FDAL** (function
level) and derives the **IDAL** (item level) for the elements that implement it. **DO-178C
defines the assurance objectives to be met *given* that level**, and which ones are "with
independence".

**ARP4754B and ARP4761A were published on the same day, 2023-12-20** (SAE; harmonised with EUROCAE's
ED-79B and ED-135), and the split between the two changed: the detail of the safety assessment
activities moved to ARP4761A. **If your certification plan cites ARP4754A, check which revision your
authority accepts** before rewriting anything.

DO-178C supplements, and **when each one applies** (they are not optional if you use the technique):

| Supplement | Applies if | Effect |
|---|---|---|
| **DO-330 / ED-215** | You use **any tool** whose output you do not verify by other means | Defines the qualification process (§2.3) |
| **DO-331** | Model-based development (the model *is* the requirement or the design) | Modifies objectives and what "model review" means |
| **DO-332** | Object orientation and related techniques | Adds objectives for inheritance, polymorphism, dynamic memory management |
| **DO-333** | Formal methods **as a substitute** for a verification activity | Allows replacing testing with mathematical proof **under conditions** |

### 2.3 Tool qualification — the rule in one sentence

**A tool whose output you do not verify by other means has to be qualified.** The corollary that
saves money is the inverse and gets forgotten: **if you verify the output independently, there is no
need to qualify it**. Qualification exists to *replace* human work, not to be added to it.

- **DO-178C §12.2 / DO-330**: three tool **criteria** — **Criterion 1**, the tool can
  **insert** an error into the airborne software; **Criterion 2**, a verification tool that can
  **fail to detect** an error **and** is used to reduce another activity; **Criterion 3**, a
  verification tool that can fail to detect an error **and does not** reduce another activity. The
  criterion crossed with the software's DAL gives the **TQL, from TQL-5 (least demanding) to TQL-1 (rigour
  close to DAL A)** in Table 12-1 (secondary source, §8).
- **ISO 26262-8, cl. 11**: you determine **TI** (tool impact) and **TD** (confidence in its
  error detection) and from there comes the **TCL 1–3**; TCL1 requires no qualification measures.
- **IEC 61508-3 / EN 50716**: classes **T1 / T2 / T3** — T1 does not generate output that affects the executable,
  T2 may fail to detect an error, T3 generates output that forms part of the executable.

**What this decides in practice**: the compiler is Criterion 1 / T3 / high TI. That is why a
**qualified** toolchain is a project decision with its own budget, and why
`ada-standards` insists on the exact status of Ferrocene.

### 2.4 Language and subset

| Option | When | Status as of Aug 2026 |
|---|---|---|
| **C with MISRA C** | What is installed, and what almost every qualified tool supports | Rules and deviations documented one by one; the subset and its tooling belong to `c-standards` |
| **C++ with MISRA C++** or an agreed subset | When the design justifies it and with **DO-332** in avionics | No exceptions, no RTTI, no dynamic allocation after initialisation |
| **Ada / SPARK** | Maximum integrity; formal proof of absence of run-time error and of properties | Mature chain, accepted by authorities for decades (`ada-standards`) |
| **Rust with Ferrocene** | New systems, when the required level falls within what is qualified | **Verified on ferrocene.dev, verbatim**: *"The compiler is TÜV SÜD-qualified for use in safety-critical development according to ISO 26262 (ASIL D)"*, and also **IEC 61508 (SIL 3)** and **IEC 62304 (Class C)**; *"A certified core subset is available for ISO 26262 (ASIL B) and IEC 61508 (SIL 2)"*. For **SIL 4** and **DO-178C (DAL C)** the text says **"supports customer certification efforts"** — **support for the customer's effort, NOT qualification at that level**. There is literature, academic included, that quotes it wrong |

**Cross-cutting prohibition of this section**: **you do not declare a toolchain qualification level that
does not appear on the body's certificate**. You read the certificate, not the press release.

## 3. Lifecycle, traceability and artifacts

### 3.1 The V lifecycle, and why it survives

The four standards describe a V lifecycle —requirements → architecture → design → code, and its
right-hand mirror verification branch— **not out of conservatism, but because the evidence that gets
audited is the correspondence between the two branches**. Agile is compatible: EN 50716:2023 explicitly
admits iterative cycles. What is **not** negotiable is that **each left-hand branch has its verification
on the right, and that both are linked**. A sprint that produces code with no traceable requirement
produces code that has to be thrown away.

### 3.2 Traceability is the product

What an assessor opens first is not the code: it is the **traceability matrix**. It must close
**bidirectionally** along the whole chain:

```
Hazard (hazard log)
  → Safety requirement (with its inherited SIL/ASIL/DAL/Class)
    → High-level software requirement
      → Architecture / design (low-level requirement)
        → Source code (file, function, line)
          → Test case (requirement-based, not code-based)
            → Execution result (with build and environment version)
              → Structural coverage evidence
```

Hard rules:
1. **No orphans upwards**: code or a test with no requirement to justify it = unrequested
   code. In avionics this is exactly the **dead code** finding (§4.3).
2. **No orphans downwards**: a requirement with no design, no code or no test = an open objective.
3. **Traceability is generated from the requirements management tool, never by hand in a
   spreadsheet.** A hand-maintained matrix is out of date the day it is delivered.
4. **Verification has to be possible**: an unverifiable requirement ("the system shall be
   robust") is a requirement defect, and it is rejected in review.
5. **Test cases are derived from the requirement**, not from the code. A test written by reading the
   implementation proves that the code does what it does.

### 3.3 The safety case

A structured argument for why the system is acceptably safe **in its declared context of use**,
with: claim → argument → evidence. **GSN** (Goal Structuring Notation) is the usual notation and it
is open. It is written **at the beginning**, not at the end: a safety case drafted after
implementation is a rationalisation, and the assessor can smell it.

**And the honest corollary that closes the document (§7): a safety case proves that a process was
followed, not that there are no failures.**

## 4. Quality, analysis and verification

### 4.1 Hazard analysis — which one, for what

| Technique | Direction | Use |
|---|---|---|
| **HAZOP** | Exploratory, guided by keywords (*no, more, less, reverse, other than*) | Process systems; finds hazards nobody had stated |
| **FMEA / FMEDA** | **Inductive**: from the component failure mode to the system effect | Bottom-up; FMEDA adds diagnostic data and feeds diagnostic coverage and hardware SIL |
| **FTA** (fault tree) | **Deductive**: from the hazardous event to its combinations of causes | Top-down; gives the structure to quantify and to find **common-cause failure modes** |
| **HARA** (ISO 26262-3) | Automotive risk classification | Output: safety goals, each with its ASIL |
| **STPA** | Control-theory based: hazards from **interactions**, not from component failure | What FMEA/FTA do not see: correct software that as a whole produces an accident |

**ASIL determination** (secondary source, §8): for each *hazardous event* three parameters are
scored and their combination gives the ASIL in a matrix — **Severity S0–S3** (S0 no injuries, S3
potentially fatal), **Exposure E0–E4** (frequency of the **operational situation**, not of the
internal failure), **Controllability C0–C3** (ability of the driver or another road user to
control the situation). The extreme **S3 + E4 + C3 gives ASIL D**; any parameter at 0 degrades to
**QM** (outside the standard's scope). Two consequences that get forgotten:
- **Exposure is of the situation, not of the failure.** Scoring it with the fault rate is the most
  common error and artificially lowers the ASIL.
- **Controllability does not credit the item's own technical countermeasures.** If the argument is
  "the driver can correct it because the system warns him", the argument is circular.
- Where there is justified doubt, **the higher class is chosen** and the reason documented. An ASIL lowered
  without traceable justification is the most expensive finding of an audit.

**ASIL decomposition** (ISO 26262-9) allows splitting a high ASIL between redundant elements
**only if independence is demonstrated**; without demonstrated *freedom from interference* (memory,
timing, information exchange), the decomposition is not valid and **the whole set inherits
the highest ASIL**. The same thing, under another name, in IEC 62304: the system's class is the highest of
its items unless architectural independence is demonstrated.

### 4.2 Structural coverage — what each level demands

**It is not a quality metric, it is a check that requirement-based testing exercised
the whole structure.** It is measured on tests derived from requirements; **a test written to raise
coverage invalidates the argument**.

| Criterion | What it demands | DO-178C (secondary source, §8) |
|---|---|---|
| **Statement** | Every statement executed at least once | **DAL C** and above |
| **Decision** | Every decision point takes both outcomes | **DAL B** and above |
| **MC/DC** | In addition, **each condition is shown to independently affect the outcome** of the decision | **DAL A** |
| — | No structural coverage requirement | DAL D and DAL E |

**MC/DC in DO-178C admits the *masking* and *short-circuit* forms, in addition to DO-178B's
*unique-cause*** (a change with respect to DO-178B, secondary source). It is what makes MC/DC achievable
on real code: it demands `n+1` cases for `n` conditions instead of `2^n`.

In IEC 61508-3, ISO 26262-6 and EN 50716 the equivalent criterion appears as a **recommended
(R) or highly recommended (HR) method per level**, not as an absolute number; the level of rigour rises with
SIL/ASIL. **The standard fixes the criterion, not the team** — and that sentence is literally the boundary that
`ada-standards` delegates here.

### 4.3 Dead code and deactivated code — they are not the same

- **Dead code**: not executable and **with no requirement**. It is a **defect**: it is
  **removed**, and whatever is touched is re-verified. It is not justified, not commented out, not left "just in
  case".
- **Deactivated code**: exists **with a requirement**, and is intentionally
  inactive in this configuration (a variant, a factory mode). It is **justified**, the mechanism that
  guarantees it cannot be activated is documented, and **that mechanism** is verified.
  Confusing the two is the classic finding of a coverage audit.

### 4.4 Gates that break the build, in order of increasing cost

1. **Compilation with no warnings**, with the exact flags of the qualified environment. A binary with warnings
   is not delivered.
2. **Static analysis of the subset** (MISRA / project rules) with **zero unapproved
   deviations**. Every deviation has a record: rule, reason, scope, impact analysis, approver.
3. **Static analysis of run-time errors** (overflow, division by zero, out-of-range
   access) or **formal proof** where the language allows it.
4. **Requirement-based testing**, including **robustness and error cases** — out-of-range
   values, corrupted inputs, redundant channel failure. In this domain **error cases are not "edges":
   they are the requirement**.
5. **Structural coverage at the level's criterion**, with analysis of each gap (not with a
   global exception).
6. **Timing (WCET) and stack analysis** (§6).
7. **Verification of full traceability** as a CI job: any orphan breaks the build.
8. **Build reproducibility**: the delivered binary is rebuilt bit for bit from the
   repository in the declared environment. **A binary that cannot be rebuilt cannot be
   certified** or patched ten years from now.

## 5. Stack security (where *safety* and *security* touch)

- **A mandatory threat analysis, with the physical consequence as the impact.** STRIDE belongs to
  `appsec-standards`; what is specific here is that **the impact is not "data leak", it is "the brake does
  not act"**. In automotive, the **ISO/SAE 21434** TARA is the artifact; in avionics, the
  risk assessment of **DO-326A**; in industrial, the **IEC 62443-3-2** assessment.
- **The attack surface is a functional safety architecture decision**: every
  interface added (diagnostics, telemetry, OTA, shared bus) is a new path to the
  critical element and **its isolation has to be argued in the safety case**, not just in the
  security one.
- **Field update**: firmware **signed and verified before execution**, with anti-rollback
  and boot to a known good image on failure. In a type-approved product, **an update
  can invalidate the type approval**: the change process (impact on the evidence, re-verification,
  notification to the authority or notified body) is defined **before** the first OTA, not on
  the first vulnerability. UN R156 exists precisely for this.
- **Debug ports**: JTAG/SWD/console disabled or cryptographically locked in
  production; their state is a verifiable requirement with its test, not a manufacturing task.
- **Vulnerability management**: the IT patching SLA **cannot be applied** to type-approved
  equipment with years-long re-verification cycles. What is required: **an SBOM of the embedded tree**,
  active CVE watch over it, **real exploitability analysis in the product's context**
  (VEX) and **documented compensating controls** for what will not be patched. `ot-ics-security`
  upholds the same criteria for the plant.
- **Domain segregation**: the critical does not share core, memory or bus with the non-critical without
  a demonstrated partitioning mechanism (§6.3). An infotainment and a traction control on the same
  SoC **is a functional safety decision**, and it has to be defended.

## 6. Determinism, timing and safe state

### 6.1 Determinism before performance

In this domain, **the worst case is the only case that matters**. Design consequences, not
recommendations:

- ❌ **No dynamic memory allocation after the initialisation phase.** Everything there is is
  reserved at start-up; the *heap* is not analysable and its fragmentation is not boundable.
- ❌ **No unbounded recursion** (and with the bound demonstrated, not assumed).
- ❌ **No loops with an undemonstrable bound.**
- **Stack size calculated and verified**, not estimated. Stack overflow is the classic silent
  failure of this domain.

### 6.2 WCET — and its honesty

The **worst-case execution time** is **analysed**, not measured with a `benchmark`: measurement
gives the worst *observed* case, which is not the worst case. The usual methods are static analysis
of the binary, hybrid measurement on the real hardware, or both. **And the warning that decides architecture:
on a multicore with shared caches and buses, a task's WCET depends on what the others do**;
without interference control (cache partitioning, memory bandwidth budgeting),
a WCET analysis per isolated task is not valid. In avionics this has its own guidance
(CAST-32A / AMC 20-193, verify the status with your authority, §8).

### 6.3 Partitioning

If different criticalities coexist on the same processor, you must demonstrate **spatial and temporal
independence**: MMU/MPU for memory, budgeted scheduling for time, and control of
the shared channels (cache, DMA, bus, interrupts). **ARINC 653** is the reference model
in avionics; in automotive, the *freedom from interference* of ISO 26262-6 annex D. Without that
demonstration, **all the core's software inherits the highest level** — which is usually
economically unviable, and that is why partitioning is decided at the beginning or it is not decided.

### 6.4 Safe state and degradation

- **Every design declares its safe state** and the **fault tolerant time interval** (FTTI in
  ISO 26262): how long the system can be in a fault state before the hazard materialises. The whole
  detection + reaction budget has to fit in there.
- **"Shutting down" is not always safe.** A train stops safely; an aircraft in flight does not; a
  ventilator does not either. **The safe state is domain-specific and is justified in the hazard
  analysis**, it is not assumed.
- **Watchdog external to the processor it watches**, with a window (minimum and maximum), fed by a
  real progress check and not by a timer that *kicks* no matter what. A
  watchdog fed from an interrupt independent of the application watches nothing.
- **Explicit and tested degraded mode**: which functions are lost, how the operator is informed, and
  how it is exited. An untested degraded mode is an unknown mode.
- **Logging for later investigation**: what is logged, where it survives a power cut, and how it is
  extracted. In an accident, evidence that does not exist cannot be reconstructed.

## 7. Sustainability, honesty and prohibitions

**Long lifecycle**: these products live 15–30 years. Consequences decided today:
freeze and **archive the complete build environment** (exact compiler, version, patches, operating
system, tools and their certificates) reproducibly; keep the traceability of the
evidence with the product, not on the laptop of whoever left; and budget for **re-verification
per change** from day one — in this domain, **the cost of a change is the cost of demonstrating it
again**, not of writing it.

**Standard transition**: EN 50716 has **DoW 30-10-2026**; IEC 61508 Ed. 3 is expected ~2027;
IEC 62304 Ed. 2 is in draft. **A multi-year project picks its reference edition and documents
it**; changing edition midway is a scope change, with its impact analysis.

**The learned component (ML) is the open problem of this domain.** It has no line-by-line traceable
requirements, its structural coverage means nothing, and its out-of-distribution
behaviour is not demonstrable with the methods in §4. Emerging guidance exists (ISO 21448 SOTIF for
intended-function failure, EASA and automotive industry work), but **as of today there
is no universally accepted route to certify a critical function implemented with
learning**. If your design depends on one, the argument has to be **architectural** —a
deterministic, verifiable monitor that bounds what the model can do— not statistical. The
governance of the AI system belongs to `ai-governance-standards`; **the safety argument belongs here, and
today it is hard**.

**The final honesty, and it is the sentence to say to whoever signs the cheque: certification
does not prove the absence of failures. It proves that a recognised process was followed with rigour
proportional to the risk, and that there is evidence of it.** Certified systems have killed people.
Treating the certificate as a guarantee of correctness is exactly the error that produces the next
accident; treating it as what it is —a disciplined reduction of the probability of systematic
error— is what makes the process worth its cost.

**Prohibitions:**

- ❌ **FORBIDDEN to present the SIL↔ASIL↔DAL mapping as normative**, or to reuse a component across
  standards without a documented *gap analysis* (§2.1). `ada-standards` forbids the same.
- ❌ **FORBIDDEN to state the content of a standard you have not read.** If you do not have the copy, say so and
  cite the secondary source as such.
- ❌ Saying that "DO-178C assigns the DAL". ARP4754B/ARP4761A assign it (§2.2).
- ❌ Confusing "qualified for X" with "supports certification efforts towards X" in a
  toolchain (§2.4). It is the most frequent citation error about Ferrocene.
- ❌ Using a tool whose output you do not verify **without qualifying it** — and also its inverse:
  qualifying a tool whose output you **do** verify independently, paying for nothing.
- ❌ Writing tests **to raise coverage**. It invalidates the entire argument of §4.2.
- ❌ Leaving **dead code** justifying it as "deactivated" (§4.3).
- ❌ Dynamic memory allocation after initialisation, unbounded recursion, loops with no demonstrable
  bound (§6.1).
- ❌ Declaring a WCET measured with a benchmark, or a per-isolated-task WCET on a multicore with
  shared resources and no interference control (§6.2).
- ❌ Mixing criticalities on one processor **without demonstrating** spatial and temporal partitioning (§6.3).
- ❌ A watchdog fed by a blind timer, or internal to the element it watches.
- ❌ A degraded mode that has not been tested, or a "safe state" that was assumed without coming out of the
  hazard analysis.
- ❌ Debug ports active in production.
- ❌ A deliverable binary that cannot be rebuilt bit for bit from the repository (§4.4).
- ❌ A traceability matrix maintained by hand in a spreadsheet (§3.2).
- ❌ A safety case written after the implementation.
- ❌ Applying an IT patching SLA to a type-approved product, and its inverse: **using the type approval
  as an excuse not to watch CVEs or maintain an SBOM** (§5).
- ❌ Deploying an OTA without having first defined the change's impact on the evidence and on the
  type approval (§5).
- ❌ Treating the certificate as proof that the software has no failures (§7).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **The edition in force of your standard and its withdrawal date**, in the body's catalogue:
   the **IEC** record (accessible and reliable: that of **IEC 61508-3:2010, ed. 2.0, 2010-04-30, in force,
   stability 2027**, is verified here), the **CENELEC** catalogue for EN 50716 (**published
   2023-11-16, DoW 30-10-2026**, verified) and **iso.org** — warning: **iso.org returns 403 to
   automated fetching**; use the catalogue of your national standards body (UNE/AENOR,
   DIN, BSI).
2. **Status of the ongoing revisions**: **IEC 61508 Ed. 3** (at CDV, publication expected ~2027) and
   **IEC 62304 Ed. 2** (draft, with the change to **two levels of rigour** instead of three classes).
   **Both data points come from secondary sources and have NOT been verified against an IEC source: declared
   gap.** Do not plan against an unpublished edition.
3. **The normative content cited in §2, §4.1 and §4.2 —IEC 62304 classes, the ASIL S/E/C matrix,
   structural coverage per DAL, TQL/Table 12-1 of DO-178C, T1/T2/T3 criteria— comes from secondary
   sources (tool vendors and consultancies), because IEC, ISO, RTCA, SAE and CENELEC do not
   publish the text. Declared gap: check it against the purchased copy of the standard before
   committing to it in a certification plan.**
4. **Which ARP4754/ARP4761 revision your authority accepts**: **ARP4754B and ARP4761A were published on
   2023-12-20** (verified as a date; the content, not). Many live plans still cite
   ARP4754A and the authority may accept both.
5. **Qualification status of your toolchain**, read **on the body's certificate**,
   not on the marketing site. For Ferrocene, the distinction **qualified** (ISO 26262
   ASIL D, IEC 61508 SIL 3, IEC 62304 Class C; `core` subset certified for ASIL B and SIL 2)
   versus **"supports customer certification efforts"** (IEC 61508 SIL 4, DO-178C DAL C) is
   verified verbatim on `ferrocene.dev` as of Aug 2026 — **check it again, it changes with every
   release**, and coordinate it with `ada-standards`, which upholds the same data point.
6. **Your authority's multicore guidance** (CAST-32A, EASA's AMC 20-193 and its FAA equivalent): its
   status and what exactly it demands about interference. **Not verified here: declared gap.**
7. **Sector regulatory dates**: UN R155/R156 (new types Jul 2022, all new
   vehicles Jul 2024 in the EU, per a secondary source and the British agency VCA — **verify it in
   the UNECE text and in your jurisdiction**), status of cybersecurity in avionics (EASA's AMC 20-42,
   FAA rulemaking in progress), and the **Cyber Resilience Act** with `embedded-iot-standards`.
8. **ECSS standards**: published openly at `ecss.nl`. If your domain is space, it is the only
   corpus in this document you can read verbatim without paying — use it.
9. **CVEs of the embedded tree** (RTOS, network stack, cryptography, C libraries), with
   `vulnerability-management-standards`, and maintenance status of every third-party component
   with safety evidence ("SEooC", *safety element out of context*) you have bought.

If the web contradicts this document, **the web wins** — flag the discrepancy.
