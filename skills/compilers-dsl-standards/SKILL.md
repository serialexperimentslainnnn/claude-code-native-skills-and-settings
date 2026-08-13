---
name: compilers-dsl-standards
description: Building a language or a language processor, and deciding first whether you need one at all. Use when designing an internal (embedded) or external DSL, writing a lexer and parser by hand or with a generator (ANTLR .g4 grammars, Tree-sitter grammar.js and node-types.json, lex/flex .l and yacc/bison .y files, PEG parsers with pest .pest / peg.js / Lark, parser combinators like nom, chumsky, megaparsec or FParsec), building an AST and its source spans, name resolution and scoping, a type checker or Hindley-Milner inference, choosing a backend (LLVM IR and llvm-sys/inkwell/llvmlite, Cranelift, WebAssembly as a target, transpiling to another language, or a tree-walking versus bytecode interpreter), deciding whether a JIT is worth it, designing compiler diagnostics with spans, labels and fix-its (ariadne, codespan-reporting, miette), snapshot-testing compiler output, fuzzing a parser, building a conformance suite, or shipping the tooling a language needs to be usable - a Language Server Protocol server, formatter, debugger and syntax highlighting.
---

# Compiler and DSL standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **building a language processor**: your own DSL, an interpreter, a compiler, a
transpiler, a *linter* with its own parser, or an input format with enough syntax to need a grammar.
It covers the prior decision (do you need a language?), the frontend, the intermediate
representation, the type system, the backend, diagnostic quality, testing and the tooling that makes
a language usable.

Triggers: ANTLR `.g4`, Tree-sitter `grammar.js` and `node-types.json`, flex/bison `.l`/`.y`,
`.pest`, `.lark`, `.ebnf`, combinators (`nom`, `chumsky`, `megaparsec`, `FParsec`, `parsec`),
`llvm-sys`/`inkwell`/`llvmlite`/`libLLVM`, `.ll` and `.bc`, Cranelift `cranelift-codegen`,
`wasm32` as the target of your own compiler, "AST", "IR", "SSA", "name resolution",
"type inference", "symbol table", "parser error recovery", "tree versus bytecode",
"should I add a JIT?", `textDocument/publishDiagnostics` and other LSP methods,
`ariadne`/`codespan-reporting`/`miette`, `insta`/`expect-test`/`lit`/`FileCheck`, "ambiguous
grammar", "shift/reduce conflict", "left recursion".

**Governing principle, and it is a prohibition before it is advice: your own DSL is the most
expensive over-engineering there is.** The parser is not the cost — the parser is a weekend —; the
cost is the documentation, the highlighting, the formatter, the LSP, the debugger, the error
messages, the training of every new person and the migration when the syntax changes, **for the
whole life of the system**. A language without that budget committed does not get started. The
ladder is climbed from the bottom up and you only climb a rung when the previous one has failed
**with a concrete, demonstrated case**:

1. **Data**: JSON/YAML/TOML with a validated schema (JSON Schema). It covers 80% of what people call
   a DSL.
2. **Library / API**: functions and types of the host language. Zero new tooling, the IDE already
   works, the *type checker* already exists.
3. **Internal (embedded) DSL**: a *builder*, operators, macros or host metaprogramming. It inherits
   the editor, the debugger, types and ecosystem. **It is the right answer almost always.**
4. **External DSL with its own grammar**: only if the user **is not a programmer**, or if the syntax
   has to be portable across several hosts, or if the language must be analysable/verifiable in a
   way the host prevents (e.g. guaranteed termination, *sandbox* execution).
5. **General-purpose language**: almost never, and not in a product project.

**Second thesis, which orders §3.5 and §4**: **the quality of the error messages is a product
feature, not later polish.** It is what decides whether a language is adopted or hated; and it is
the technical reason why almost every serious compiler ends up with a hand-written parser.

**Not applicable**: see `rust-standards`, `c-standards`, `cpp-standards`, `zig-standards`,
`haskell-fp-standards`, `ocaml-fsharp-standards`, `typescript-standards`, `python-standards`,
`go-standards` (**the language you write the compiler in is theirs**: build, lint, unit tests,
dependency management, idioms. Here the architecture of the language processor, not how the code
that implements it is written. OCaml/Haskell/F# appear here because their sum types and *pattern
matching* are the natural tool for an AST, but that recommendation belongs to §2, it is not a scope
handover), `webassembly-standards` (**Wasm as a target and as a runtime is theirs**: the `wasm32-*`
target, the Component Model and WIT, *sandbox* limits, *fuel*/epoch and the module size budget. Here
only the decision to **emit** Wasm from your backend and what you lose by doing so),
`lowcode-governance-standards` (**the low-code platform as a third-party product and its
governance** — life cycle, ownership, catalogue, licences, *shadow IT* — is theirs. Clean boundary:
**building a language belongs here; governing the use of one you bought, to them**. A visual flow
editor that serialises to JSON is a platform, not a DSL in the sense of this document),
`sql-standards` (**SQL is already the DSL almost nobody needs to reinvent**; if the problem is
querying data, the answer is usually SQL, not a new grammar), `api-design-standards`
(**if the user is a program, the answer is an API, not a syntax**: contract, versioning and
compatibility are theirs), `testing-qa-standards` (general quality strategy; here the specific
techniques: *snapshot*, parser *fuzzing*, conformance suites), `appsec-standards` (threat modelling
and agnostic vulnerability classes; here only the *sinks* particular to executing third-party code),
`performance-engineering-standards` (measurement and profiling methodology; here only what to
measure in a compiler and when a JIT does not pay off), `opensource-licensing-standards` (the
licence as a legal constraint; here only the fact that LLVM is **Apache-2.0 WITH
LLVM-exception**), `ai-agents-standards` (an agent that *generates* code in your DSL; here the DSL).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before fixing it in a real project (§8).

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| A DSL? | **No.** Data with a schema or a host API | Internal DSL | The ladder in §1; rung 4 requires a written justification |
| Internal vs. external DSL | **Internal** | External if the user does not program | The internal one inherits IDE, types, debugger and ecosystem for free |
| Production parser | **Hand-written recursive descent** (+ *Pratt* for expressions) | A generator for prototyping or for someone else's already specified language | Total control of messages and **error recovery**; no opaque conflicts |
| Generator, if you use one | **ANTLR 4** (`.g4`, BSD-3-Clause) | bison/flex in legacy C | ALL(*) accepts left recursion; mature ecosystem. **Last release 4.13.2, August 2024** (verify §8): a stable project but with a very slow cadence — a risk datum, not a disqualifier |
| Incremental / editor parser | **Tree-sitter** (MIT, `0.26.x` as of Jul 2026) | LSP with a full reparse if the file is small | Incremental, error-tolerant reparse; it is what an editor wants. **Still on `0.x`: the API breaks between minors** |
| PEG | **Only with a documented alternative order** | — | The ordered `/` operator **removes ambiguity without telling you**: a rule that is never reached gives no error, it gives silence. See §7 |
| AST | Immutable sum types + **a `Span` on every node** | A CST/concrete tree if the original has to be reprinted | Without a `Span` there is no diagnostic, no *fix-it* and no LSP |
| Diagnostics | A rendering library with spans and labels (`ariadne`, `codespan-reporting`, `miette`) | Your own `file:line:col:` format, editor-compatible | A message with no highlighted code fragment is a useless message |
| Execution | **Bytecode interpreter** (stack VM) | A tree if the language is configuration and runs once | The tree is 5–20× slower; bytecode is not as complicated as it looks |
| JIT | **No, until you have the profile that demands it** | When the same code runs millions of times in a long-lived process | See §6.2 |
| Native backend | **LLVM** if you need quality machine code | **Cranelift** if compilation time dominates (JIT, Wasm) | LLVM optimises better; Cranelift compiles much faster and is pure Rust |
| "Cheap" backend | **Transpile** to C, Rust, Go or TypeScript | — | You inherit its optimiser, its portability and its debugger. The most underrated option |
| Portable target | **WebAssembly** | — | One backend, many platforms, *sandbox* included → `webassembly-standards` |
| Output tests | **Snapshot** (`insta`, `expect-test`, `lit`+`FileCheck`) | — | A compiler is a pure function from text to text: the snapshot is its natural test |
| Parser fuzzing | **Mandatory** (`cargo-fuzz`/libFuzzer/AFL++) | — | The parser is the attack surface; see §5 |
| Minimum tooling to publish | **LSP + formatter + highlighting** | — | Without the three, the language is not usable outside its author |

**About LLVM, and this is the datum that breaks projects: LLVM's IR is not a stable format.** The
official policy says, textually, that *"The textual format is not backwards compatible. We don't
change it too often, but there are no specific promises."* For the *bitcode* there is a backward
reading guarantee (*"The current LLVM version supports loading any bitcode since version 3.0"*), but
with caveats that matter: *"Newer releases can ignore features from older releases, but they cannot
miscompile them"* and *"Debug metadata is special in that it is currently dropped during upgrades"*.
Operational, not theoretical consequences:

- **Pin LLVM's major version in the build and treat it as a platform dependency**, not as an
  interchangeable library. Moving up a major is a project, with its window and its tests.
- **Do not keep `.ll` or `.bc` as a long-term artifact** or as an interchange format between
  components that are updated separately. That is the classic mistake.
- The *binding* (`inkwell`, `llvmlite`, `llvm-sys`) is **tied to LLVM's major**: your project's
  update pace is set by the slower of the two.
- LLVM publishes two majors a year and frequent patches (as of Jun 2026, **22.1.8**; verify §8).
  Licence **Apache-2.0 WITH LLVM-exception**.

## 3. Structure and conventions

### 3.1 Phases, and the rule that each one produces a datum

```
text → [lexing] → tokens (+span) → [parsing] → CST/AST (+span)
     → [name resolution] → resolved AST → [types] → typed AST
     → [lowering] → IR → [optimisation] → IR → [backend] → output
```

- **Each phase is a pure function from one structure to another.** No mutating the AST in place from
  five different phases: it destroys traceability and makes per-phase testing impossible.
- **Each node carries its `Span`** (start offset, end offset, file id). The `Span` survives every
  phase; if it is lost in the *lowering*, the type error cannot point at code.
- **Centralised `SourceMap`**: offsets are bytes, conversion to line/column happens once at render
  time. Careful with UTF-8: the column an editor expects is usually **UTF-16** (the LSP uses UTF-16
  by default); this is decided and documented once, not per function.
- **Errors as data, not as exceptions**: the compiler accumulates diagnostics and carries on.
  Aborting on the first error is the worst possible experience and makes the LSP unviable.

### 3.2 Parser: why by hand

The generator is faster to write and worse to use. A generated parser produces *"syntax error at
line 42"*; a hand-written one produces *"missing `)` — the opening parenthesis is on line 39"*. What
tips the balance is not performance, it is this:

- **Error recovery**: the LSP needs a reasonable tree from a file the user is typing and which is by
  definition invalid. Recovery via synchronisation points (`;`, `}`, the start of a declaration) and
  **`Error` nodes in the tree**, not an exception.
- **Messages with context**: only you know what the parser was expecting and why.
- **Expression precedence**: *Pratt parsing* / *precedence climbing*, an explicit table of
  precedence and associativity. It is the part pure recursive descent does badly.
- If you use a generator: **prototype with it and switch to hand-written once the grammar
  stabilises**. Migrating with the grammar already written as a specification is cheap; starting by
  hand without knowing the grammar is not.

### 3.3 Name resolution and types

- **Name resolution is a phase of its own**, separate from the parser and from the *type checker*.
  Explicit scopes, not a mutable global table.
- **Inference**: Hindley-Milner (Algorithm W / level-based generalization) if the language is
  functional and you want full inference; bidirectional checking if there is subtyping, generics or
  overloading. **Pick one, and know which**, because mixing them by eye produces a type system that
  is impossible to explain and to give messages for.
- **Practical and unintuitive corollary: global inference makes error messages worse.** The error
  appears far from its cause. Requiring annotations at the boundaries (public functions, fields) is
  a usability decision, not a technical limitation.

### 3.4 Backend: choose the cheapest that does the job

By increasing cost: **tree interpreter → bytecode → transpile → Wasm → Cranelift → LLVM → your own
code generation**. You never climb a rung without a number to justify it. Transpiling to a language
with a good ecosystem is the most underrated route: you inherit the optimiser, the platforms, the
debugger and the profiler; the price is that **the target language's error messages leak to the
user** — and that has to be actively covered up with *source maps* or with a translation layer.

### 3.5 Diagnostics, as a specification

A complete diagnostic has: a **stable code** (`E0308`, `TS2345`) documented and searchable; a
**severity**; a **primary span** with the rendered fragment; **labelled secondary spans** ("it was
declared as `Int` here"); a **note** explaining the rule; and, when a mechanical correction exists, a
structured **`fix-it`** (range + replacement text) the LSP can apply. The error code is a contract:
**once published it is not reused for something else**.

## 4. Quality and testing

Gates in order of increasing cost; the first three break the build.

1. **Unit tests per phase**: lexer, parser, resolution, types. Each with its minimal input.
2. **Snapshot of the output**, and of the **errors**: for each test program the serialised AST, the
   IR and **the exact text of the diagnostic** are frozen. Having the error message under version
   control is what stops it degrading without anyone noticing. `insta`, `expect-test`, or `lit` +
   `FileCheck` LLVM-style.
3. **A suite of invalid programs, as large as the valid one.** A compiler is judged by what it
   rejects and by how it explains it. Every defined error has at least one case.
4. **Parser fuzzing** (libFuzzer/AFL++, with a seed corpus from the suite): the target is **zero
   *panics*, zero stack overflows, zero infinite loops** on any input. A recursive parser overflows
   the stack with nested parentheses: **an explicit depth limit**, not trust.
5. ***Round-trip* / properties**: `parse(print(parse(x))) == parse(x)` for the formatter; random
   generation of valid ASTs and checking that they print and reparse.
6. **Differential**, if you are reimplementing something existing: compare against the reference
   implementation over a real corpus.
7. **Conformance**: if the language has a specification (yours or someone else's), the conformance
   suite is a separately versioned artifact, and the conformance percentage is published. **Without a
   suite, the "specification" is the implementation**, and then there is no specification.
8. **Performance regression**: compilation time over a fixed corpus, measured in CI with a
   threshold. A compiler that becomes slow loses users exactly as one that gives bad errors does.

## 5. Stack security

- **Running someone else's language is running someone else's code.** If the DSL is written by
  users, customers or an LLM, the interpreter is a trust boundary: **an instruction limit, a memory
  limit, a wall-clock limit, a recursion depth limit and a data nesting limit**, all mandatory and
  all configurable. Without them, a three-line loop is a denial of service.
- **Decide and document whether the DSL is Turing-complete.** If it does not need to be, **do not
  make it so**: a total language (with no unbounded loops) can be analysed, bounded and executed
  without fear. That is the real advantage of a DSL over "let them write Python".
- ***Host* surface: the list of native functions exposed is the complete attack surface.** No
  exposing the filesystem, the network or `exec` "for convenience". An explicit allowlist, reviewed
  the way a public API is reviewed.
- **Denial of service in the parser**: exponential backtracking in PEG and in regular expressions
  (ReDoS), nesting depth, unbounded input sizes. All with a limit and with a test.
- **No host `eval`** to implement the DSL. A "DSL" that compiles to Python/JS `eval()` **is not a
  DSL: it is code injection with pretty syntax**.
- **The compilation cache is a supply chain vector**: if you keep compiled artifacts (bytecode,
  `.bc`, objects) or download third-party grammars/plugins, they come with integrity verification. A
  Tree-sitter grammar file compiles to native C that gets loaded into your process.
- **Error messages do not leak absolute paths or the environment** when the compiler runs as a
  service. This error is as classic as it is boring.

## 6. Performance and operability

### 6.1 What to measure

Time per phase (lexing, parsing, types, backend) over a fixed corpus; **the split is almost never
what you think** — in mature compilers the backend and resolution dominate, not the parser. In an
LSP, what matters is **perceived latency**: *completion* and *hover* below ~100 ms, and diagnostics
below ~500 ms from the last keystroke. That is achieved with incremental parsing and lazy querying
(a *query-based* architecture with memoisation), not by optimising the lexer.

### 6.2 When a JIT does not pay off

A JIT only wins when the **accumulated execution time of the hot code comfortably exceeds the cost
of compiling it**, and that cost includes what almost nobody counts: debugging complexity, the
impossibility of W^X on platforms that forbid it (iOS, consoles, many environments with strict
`seccomp`/SELinux), the attack surface of writable executable pages, and the work of maintaining it
per architecture. **It does not pay off** in: short processes, code that runs once (configuration,
templates, rules), I/O-dominated workloads, and anywhere portability matters more than the peak.
**Before a JIT**: compact bytecode, *inline caching*, *superinstructions*, and — first of all —
checking that the interpreter is not wasting its time on memory allocations.

### 6.3 Tooling without which the language does not exist

- **LSP** (spec 3.18 in development as of August 2026; 3.17 is the last one published as stable —
  verify §8). Minimum viable: diagnostics, *hover*, go to definition, autocompletion, document
  symbols.
- **A canonical formatter with no options.** The `gofmt` lesson: zero configuration removes the
  debate forever. It ships **from the first version**, because a retroactive formatter rewrites all
  the existing code at once.
- **Highlighting**: a Tree-sitter grammar (modern editors) and/or TextMate `.tmLanguage.json` (VS
  Code, and still the lowest common denominator).
- **Debugging**: if the language is transpiled or compiled, either you emit real debug information
  (DWARF, *source maps*) or you assume **nobody will be able to debug**. A conscious, documented
  decision.
- **Language versioning**: SemVer over the **syntax and the semantics**, not over the binary. A
  change that makes a previously valid program invalid is *breaking*, always.

## 7. Long-term sustainability

**A DSL with no owner is debt that cannot be refactored.** A language has no reliable *find usages*
outside its own tooling, so the code written in it becomes untouchable as soon as the person who
designed it leaves. Requirements of existence, not recommendations: **a named owner**, a **written
specification** (even if it is a short document), a **conformance suite**, a **compatibility
policy** and an **automated migration plan** (`fix`/*codemod*) for every syntax change. If any of
them is missing, the DSL is not approved.

- ❌ **FORBIDDEN** to create an external DSL without having exhausted — and documented why they fail
  — rungs 1 to 3 of the ladder in §1.
- ❌ **FORBIDDEN** to implement the DSL on top of the host language's `eval()`/`exec()`.
- ❌ **FORBIDDEN** to run user code without time, memory, instruction and depth limits.
- ❌ **FORBIDDEN** to expose to the DSL native file, network or process functions without a reviewed
  allowlist.
- ❌ **FORBIDDEN** an AST with no `Span`. A node with no position is a diagnostic that cannot be
  given.
- ❌ **FORBIDDEN** to abort compilation on the first syntax or type error.
- ❌ **FORBIDDEN** to treat LLVM's IR as a stable interchange or storage format (§2), and forbidden
  to leave LLVM's major version unpinned in the build.
- ❌ **FORBIDDEN** to publish a language with no formatter and no highlighting. "It will come later"
  means never.
- ❌ **FORBIDDEN** to change a diagnostic's text without a snapshot recording it.
- ❌ **FORBIDDEN** to reuse a retired error code for another meaning.
- ❌ **FORBIDDEN** a PEG grammar with alternatives whose order is not documented: an unreachable rule
  **gives no error, it gives silence** (§2).
- ❌ **FORBIDDEN** a recursive parser with no depth limit and no *fuzzing* test verifying it.
- ❌ **FORBIDDEN** "we will optimise it with a JIT" with no prior profile (§6.2).
- ❌ **FORBIDDEN** to break the syntax with no *codemod* and no notice period with both forms valid.
- ❌ **FORBIDDEN** to leave "the specification" as a synonym for "whatever the current implementation
  does".

## 8. Mandatory web verification

Before fixing anything in a real project, check on the web:

- **LLVM**: the latest major and patch version, the release calendar, and **re-read the *IR
  Backwards Compatibility* section of `llvm.org/docs/DeveloperPolicy.html`** — that is the source,
  not this summary. Compatibility of the *binding* you use (`inkwell`, `llvmlite`, `llvm-sys`) with
  that major.
- **ANTLR**: the latest release and the project's activity (as of August 2026 the last one published
  was **4.13.2, from August 2024**; if it is still the same, weigh it as a maintenance risk).
  Licence **BSD-3-Clause**, read in the repository's `LICENSE.txt`.
- **Tree-sitter**: version (still on `0.x`, with breakage between *minors*), the state of the
  *bindings* API and the **MIT** licence read in `LICENSE`.
- **Cranelift / Wasmtime**: version, supported architectures and production status.
- **LSP**: whether 3.18 has been published as final or is still "under development"; changes in the
  negotiation of `positionEncoding` (UTF-8 vs. UTF-16).
- **Raw licences** (`LICENSE`, `COPYING`, `LICENSE.txt`, careful with `master` versus `main`) of
  every parsing, *codegen* or *runtime* library you link — especially if you link LLVM: it is
  **Apache-2.0 WITH LLVM-exception** and the exception matters.
- **CVEs** of the *runtime* you embed (LLVM, regular expression engines, native grammar loaders).
- The state of the Wasm *target* if you compile to it: WASI 0.2/0.3, the Component Model, and which
  runtime supports it today.

If the web contradicts this document, **the web wins** — flag the discrepancy.
