---
name: prolog-standards
description: Logic programming in Prolog and its constraint solving niche. Use when working with .pl, .pro, .prolog, .plt, .P or .qlf files, SWI-Prolog (swipl, pack_install, library(clpfd), library(http/thread_httpd), plunit, :- begin_tests, saved states via qsave_program), SICStus Prolog (sicstus, spld, library(clpfd) and library(clpb)), GNU Prolog (gprolog, gplc), Scryer Prolog (library(clpz)), Trealla, XSB or Ciao, ISO Prolog conformance, Horn clauses, unification and backtracking, the cut operator, first-argument clause indexing, assert/asserta/assertz/retract of dynamic predicates, tabling and SLG resolution (:- table), DCG rules with --> and phrase/2, constraint programming with #=/#\=/label/labeling, or deciding between Prolog and a dedicated solver such as MiniZinc, OR-Tools CP-SAT or an SMT solver.
---

# Prolog and logic programming standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Prolog is alive, but its niche is much narrower than its fame suggests.** There are maintained
implementations (SWI-Prolog published the stable **10.0** series with patches in 2026), there is a
commercial vendor selling licenses (SICStus) and there is real production use in planning,
verification, program analysis and expert systems. What there almost never is, is a reason to write
a general-purpose application in Prolog.

**When you really do choose it** — and there are few cases, all with the same shape: *the problem is a
relation, not a procedure*:

1. **Combinatorial constraints** (CLP(FD)): timetabling, resource allocation, sequencing, product
   configuration. **It is the only niche where Prolog competes head to head**, and even there you
   have to compare (below).
2. **Language parsing and transformation** with **DCG**: declarative, reversible grammars, proven over
   decades; they are still excellent for irregular formats and symbolic NLP.
3. **Reasoning over facts and rules**: static analysis, queries over dependency graphs, policy
   checking, expert systems with backward chaining.
4. **Semantics prototyping**: interpreters, type systems, executable specifications.

**The honest comparison you have to make before choosing it** (and that almost nobody makes):

- **If the problem is pure constraints, a dedicated solver usually wins.** **MiniZinc** (2.10.0,
  Jul 2026) gives you a declarative modeling language and **lets you swap backend** —CP, MIP,
  SAT— without rewriting the model. **OR-Tools CP-SAT** (v9.15, 2026) is, on large scheduling and
  allocation problems, plainly faster and more operable, and it is called from Python or C++
  like any other library. An **SMT** (Z3, cvc5) is the answer when arithmetic and logic are
  mixed or you need to prove unsatisfiability. Prolog+CLP(FD) wins when the model is
  **interleaved with symbolic logic**, when you need to generate the model with the same rules that
  solve it, or when the bespoke search (`labeling/2` with your heuristic) is the value.
- **If the problem is "business rules", a rules engine or a decision table (DMN) is cheaper to
  operate and to audit**, and it can be maintained by someone who does not know Prolog.
- **If the problem is querying relations over data, it is a database.** Datalog (recursive,
  terminating, no cut) is a very reasonable middle ground and many engines speak it.

**Not applicable**: **no other language in the catalog competes directly with this one** — Prolog is
not replaced by a language, it is replaced by a solver or by a database. Formal boundary:
`python-standards`, `go-standards`, `rust-standards`, `typescript-standards`, `jvm-spring-standards`,
`clojure-standards`, `lisp-standards`, `haskell-fp-standards` (**general-purpose languages: the
system surrounding the logic engine is written in one of them, with their criteria — and in the
default architecture of §3, they are the host and Prolog the component**); `julia-standards` and
`classical-ml-standards` (**if the problem is numerical or statistical optimization, it is not from
here**); `sql-standards` and `graph-db-standards` (**queries over related data: if the recursion is
over a persistent graph, it is theirs**); `nlp-standards` (**statistical and model-based NLP**: here
only DCGs as a symbolic parser); `ai-agents-standards` and `llm-app-engineering-standards`
(**reasoning with LLMs**: here the symbolic, verifiable and deterministic part — they are
complementary, not alternatives); `data-governance-quality-standards` (data quality rules as
governance); `software-architecture-patterns-standards` (where a reasoning component fits);
`legacy-modernization-standards` (**umbrella skill** for an inherited Prolog engine: which "R" is
chosen, whether it is frozen, rewritten or retired) and `migration-projects-standards` (**the
execution of the cutover** once decided: rehearsal, window, data reconciliation, rollback and
shutdown of the source); `appsec-standards` and `vulnerability-management-standards` (methodology and
triage; here the concrete sinks, §5); `opensource-licensing-standards` (license analysis; here which
license each implementation has, §2); `cicd-standards` (the pipeline).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Choice | Verified note (Aug 2026) |
|---|---|---|
| Default implementation | **SWI-Prolog** | Stable series **10.0** (current downloads **10.0.2**); development series 10.1.x. It is the only one with a complete ecosystem: `pack`, HTTP server, `plunit`, tabling, CLP(FD), debugger, Wasm build |
| SWI-Prolog license | **Simplified BSD (BSD-2-Clause)** — read raw from the `LICENSE` | *"SWI-Prolog is covered by the Simplified BSD license"*. **This corrects a widespread belief: many secondary sources still say LGPL/GPL.** Warning from the file itself: it may link libraries with more restrictive licenses — **check your specific build with `?- license.`**, not the project's front page |
| Commercial implementation | **SICStus Prolog**, only with a requirement that justifies it (contractual support, performance of its CLP(FD)/CLP(B), certification, exotic platforms) | **4.10.1, published 3-Jul-2025**. Proprietary, licensed by RISE AB; **it does not publish rates**: license + annual maintenance, with a reinstatement surcharge if you let maintenance lapse. **License cost and its renewal is the expensive data point** |
| GNU Prolog | **Not for new projects** | Latest stable **1.5.0**, with a copyright notice up to **2021** and no later release published on its site. It compiles to native and is ISO-centric, but its ecosystem is minimal and its cadence, nil |
| Scryer Prolog | **Only for experimental or ISO conformance work** | Written in Rust, heavily focused on ISO and on `library(clpz)`. **Active repository (commits in Jul 2026) but the latest tagged release is v0.10.0 (Sep 2025) and the numbering is pre-1.0**: a live repo ≠ production-ready. Use it for its rigor, not for its stability |
| Standard | **ISO/IEC 13211** as the portability baseline | **Real code is not portable**: modules, tabling, CLP(FD), I/O and the libraries are outside it or diverge between implementations. **Assume you are choosing an implementation, not a language**, and say so in the ADR |
| Constraints | **`library(clpfd)`** in SWI/SICStus; `library(clpz)` in Scryer | **And compare it with MiniZinc / OR-Tools CP-SAT / SMT before deciding** (§1). If the model is pure constraints, document why you are not using the dedicated solver |
| Solver alternative | **MiniZinc 2.10.0** (Jul 2026) or **OR-Tools v9.15** (2026) | MiniZinc decouples model and backend; CP-SAT usually wins at scale. Both are operated from a mainstream language |
| Tabling (SLG) | **`:- table` for every recursive predicate over data** | It turns non-terminating left recursion into a terminating query with memoization. **It is what makes graph reasoning usable** and it avoids 90 % of defensive cuts |
| Arithmetic | `#=`/`#\=` (CLP(FD), relational and reversible) versus `is/2` (directional) | In constraint code, **`is/2` is a design error**: it breaks the reversibility that justified using Prolog |
| Tests | **plunit** (`:- begin_tests/end_tests`, `.plt` files) | Runnable from the CLI with an exit code; see §4 |
| Packaging | **Saved state** (`qsave_program`) or a script with a shebang; SWI `pack` for libraries | The saved state has the same reproducibility problem as a Lisp image: it is generated from a clean build, never from an interactive session |

## 3. Structure and conventions

- **Default architecture: Prolog is a component, not the application.** The logic engine lives
  behind an explicit interface (separate process, HTTP, or embedded with its C/Python API) and the
  rest of the system is written in a mainstream language. This bounds the succession risk, allows
  testing the model in isolation and makes it possible to **replace the engine with a solver** if §1
  changes its answer. Writing the HTTP service, the persistence and the whole operation in Prolog is
  the decision that turns a valuable component into a system nobody wants to touch.
- **Modules always** (`:- module(name, [pred/Arity, ...])`), with the export list as the
  contract. Without modules, every predicate is global and a silent redefinition is an hours-long bug.
- **Every predicate documented with its mode and determinism** (`+`/`-`/`?`, det/semidet/nondet/multi).
  In Prolog there are no types: **the mode and the determinism are the only contract**, and if it is
  not written down, it does not exist.
- **The cut (`!`) is the language's greatest maintainability cost.** It is not an optimization: it
  changes the declarative semantics, and a cut added to "fix" a duplication breaks the correct
  solution in the case you have not tested yet. Criteria:
  - **Red cut forbidden** (the one that alters the solution set). If you need it, the logic is badly
    factored.
  - To choose between alternatives, **`( Cond -> Then ; Else )`**, which is local and readable.
  - For determinism, **first indexing and guards at the start of the body**; the green cut only when
    those two are not enough, with a comment saying which choice it prunes.
  - A cut inside a disjunction or after a `->` is almost always an error.
- **Performance = clause indexing, and indexing is on the first argument.** The design of the
  predicate head *is* the design of the index: put the discriminating argument first, with a functor
  or a constant atom. A predicate with thousands of clauses and a variable first argument walks all
  of them on every call. **Before optimizing anything else, look at the indexing** (SWI additionally
  supports multi-argument and JIT indexing: verify what your implementation does, §8).
- **DCG (`-->`, `phrase/2,3`) for all parsing**: do not write a parser by hand manipulating lists.
  And **`phrase/2` with explicit `string_codes`/`atom_codes`**, not with implicit representations.
- **`assert`/`retract` as global state: forbidden except for facts loaded once.** They are global
  variables with the worst possible profile: they break backtracking, invalidate indexes, are not
  transactional and make tests order-dependent. State is passed through arguments.
- **No *failure-driven loops*** (`forall/2` and `foldl/4` exist); **no left recursion without
  `:- table`**; **difference lists only where the profile justifies it** (they destroy
  readability).

## 4. Quality and CI

- **plunit mandatory, runnable from the CLI** (`swipl -g run_tests -t halt`) with a non-zero exit
  code on failure. A test that only runs in the toplevel is not a gate.
- **Test determinism, not just the result**: a predicate that should have been `semidet` and returns
  two solutions is this language's characteristic bug, and `assertion/1` with
  `forall(Goal, ...)` or an explicit check of the second choice point detects it.
  Also cover **failure** and **exception** as expected outcomes, not just success.
- **Minimum gate**: (1) it loads with no *singleton variable* or undefined predicate warnings —in
  Prolog a typo in a variable name is a warning, not an error, and it produces a silent failure;
  (2) static checking available in your implementation (in SWI, `check/0`, `list_undefined/0`,
  `xref`); (3) `plunit` green; (4) for CLP(FD) models, **a case with a known solution and an
  unsatisfiable case**, both with a **time limit**, because an unbounded search does not fail: it hangs.
- **Every search goal carries a budget**: `call_with_time_limit/2`, `call_with_inference_limit/3`
  or your implementation's equivalent. Without a bound there is no operability.

*§6 is deliberately omitted*: the observability, the deployment and the capacity of a service that
embeds Prolog belong to the host platform's skill (§3) and to `observability-standards`; the only
specific thing —inference and time bounds— is in §4, and search memory consumption, in §5.

## 5. Stack security

- **`read_term/2` and family over untrusted input is code execution and resource exhaustion.**
  Reading someone else's term **creates arbitrary atoms and functors** (atom table: a memory DoS
  surface) and, if that term is then passed to `call/1`, it is direct RCE. Criteria:
  **never `call/1`, `=..` nor `assert/1` over terms derived from external input**; parse with
  DCG into a closed structure and validate against a whitelist of functors.
- **SWI's `library(sandbox)` exists and is the right answer if you have to evaluate user
  goals** (e.g. a query endpoint). Verify its status and its limitations before trusting it with
  anything: a language sandbox is a bypass surface, not a guarantee.
- **SWI-Prolog's HTTP server is a full application server**: if you expose it, all of
  `appsec-standards` applies to it (authentication, headers, TLS terminated where appropriate).
  **By default, do not expose it**: serve behind a proxy and listening on localhost.
- **`shell/1,2` and `process_create/3`**: never with arguments concatenated from external input.
- **DoS by search**: a goal with no time or inference bound is a trivial denial vector against any
  interface that accepts user parameters (§4). The limit is mandatory **at the boundary**, not
  entrusted to the model.
- **Dependencies**: `pack_install/1` downloads and **compiles** third-party code (packages with C
  extensions). Verify the origin, pin the version and review what it compiles; the ecosystem is small
  and has no audit process.

## 7. Sustainability, migration and prohibitions

**Adoption criteria** (decided beforehand, and in writing):
1. **Is the problem a relation or a procedure?** If it is a procedure, it is not Prolog.
2. **Do a dedicated solver or Datalog solve it?** If so, use it: it operates and hires better (§1).
3. **Is the component bounded behind an interface?** If the plan is to write the whole system in
   Prolog, the answer is no.
4. **Are there ≥2 people able to maintain it, and a way to train a third?** The job market is
   tiny; the knowledge is teachable, but it has to be budgeted.

**Migration criteria for an existing Prolog**: it is not translated to another language —a mechanical
translation of backtracking and unification produces unreadable and slower code—. It is
**respecified**: extract the rules into a declarative form (decision table, MiniZinc model, Datalog
schema), verify it against the live system with real cases, and replace by domain. If the system works
and is bounded, **freezing it is a legitimate option**; document the mode and determinism of every
public predicate as part of the freeze.

**Prohibitions:**
- ❌ **FORBIDDEN: the red cut**; a cut inside a disjunction or after `->`; cuts added to
  "remove extra solutions" without understanding where they come from (§3).
- ❌ **FORBIDDEN** `call/1`, `=..` or `assert/1` over terms coming from external input; `read_term`
  over untrusted data without a whitelist of functors (§5).
- ❌ `assert`/`retract` as mutable application state.
- ❌ Search goals with no time or inference limit exposed to a user.
- ❌ Recursion over graphs or data without `:- table` "because it terminates in the tests".
- ❌ `is/2` where the model should have been CLP(FD) and reversible.
- ❌ Public predicates with no documented mode or determinism.
- ❌ Programming without modules.
- ❌ Choosing Prolog for a pure constraints problem **without having compared it with MiniZinc, CP-SAT
  or an SMT** and without putting it in writing.
- ❌ Writing the complete system (HTTP, persistence, operation) in Prolog.
- ❌ Assuming ISO portability between implementations (§2), or assuming SWI-Prolog's license from
  what a secondary source says: **you read the `LICENSE` raw and you run `?- license.`**.
- ❌ Choosing GNU Prolog or Scryer for production (§2).
- ❌ Committing a project to SICStus without the license cost **and the annual maintenance** in
  writing, knowing that letting it lapse carries a reinstatement surcharge.
- ❌ Exposing SWI-Prolog's HTTP server directly to the Internet.

## 8. Mandatory web verification

1. **SWI-Prolog**: current stable version (as of Aug 2026, series **10.0**, downloads **10.0.2**; the
   odd-minor series are development) and its changelog; and **the license read raw**
   (`LICENSE` = Simplified BSD) plus `?- license.` on **your** build, because of the linked libraries.
2. **SICStus**: current release (as of Aug 2026, **4.10.1 of 3-Jul-2025**) and, above all, **the price —
   declared gap: RISE does not publish rates**. Any figure has to come from a quote.
   Also confirm the surcharge for lapsed maintenance before letting it expire.
3. **Scryer**: whether a release later than v0.10.0 has appeared and whether it has reached 1.0; **GNU Prolog**: whether there is
   anything later than 1.5.0. In both cases, look at **commits**, not just releases (§ catalog rule:
   a repo without recent releases does not imply a dead project, nor the other way round).
4. **MiniZinc and OR-Tools**: current version (as of Aug 2026, **MiniZinc 2.10.0** of Jul 2026 and **OR-Tools
   v9.15** of 2026) and which backends each one supports — it is the comparison that decides whether Prolog gets in.
5. **Tabling and indexing of your implementation**: what it indexes (first argument, multi-argument, JIT),
   which tabling modes it offers (`incremental`, `subsumptive`, *answer subsumption*) and their memory
   limits. It is what determines whether the model scales, and it varies by implementation and version.
6. **`library(sandbox)`**: status, known limitations and warnings, before evaluating user
   goals.
7. CVEs and security advisories for the implementation and for the HTTP/TLS stack you embed, and for the
   native code brought in by the `pack`s you install.
8. **ISO conformance** of the specific implementation and its documented deviations, if
   portability is a real requirement (usually it is not: §2).

If the web contradicts this document, **the web wins** — flag the discrepancy.
