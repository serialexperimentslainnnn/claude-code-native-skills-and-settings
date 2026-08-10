---
name: ocaml-fsharp-standards
description: OCaml and F# language engineering standards (the strict ML family). Trigger on .ml/.mli/.mll/.mly files, dune/dune-project/dune-workspace, .opam files and opam switches, .ocamlformat, .merlin, ocaml-lsp/Merlin, and on .fs/.fsi/.fsx files, dotnet fsi scripts, .fsproj, .fantomasignore, paket.dependencies. Covers OCaml 5 domains and effect handlers, functors and the module system, Lwt/Async/Eio, js_of_ocaml, Stdlib versus Jane Street Base/Core, Alcotest and QCheck, and on the F# side discriminated unions, computation expressions, type providers, Result-based domain modelling, Fantomas, Expecto, FsCheck, FsUnit and the C# interop boundary.
---

# OCaml and F# standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the two **strict** MLs in industrial use. **OCaml**: `.ml`/`.mli`/`.mll`/`.mly`, `dune`, `dune-project`, `dune-workspace`, `*.opam` files, `.ocamlformat`, opam switches, Merlin/ocaml-lsp. **F#**: `.fs`/`.fsi`/`.fsx`, `dotnet fsi`, `.fsproj`, `.fantomasignore`, `paket.dependencies`.

**They share lineage, they share nothing else.** OCaml and F# descend from ML and that is why they look alike on the surface —Hindley-Milner inference, ADTs, exhaustive pattern matching, immutability by default—, but **they share no ecosystem, no runtime, no package manager, no tooling and no concurrency model**. OCaml has its own native compiler, its own GC, `opam`/`dune` and a module system with functors that F# does not have. F# is a language on top of the CLR: its runtime, its GC, its package manager (NuGet) and its support calendar are .NET's, and its interop with C# is a design requirement, not an extra. No decision transfers from one to the other by analogy. That is why **each section below explicitly states which of the two governs**; the little that is common is marked as **[Both]**.

**Not applicable**:
- **`dotnet-standards` — critical boundary, no ambiguity.** These belong to **`dotnet-standards`**: the .NET SDK and `global.json`, the LTS version and its support calendar, `Directory.Build.props`/`Directory.Packages.props`, **NuGet and its security** (NuGetAudit, lockfiles, CPM), publishing and packaging, the runtime and Native AOT, **ASP.NET Core**, hosting, configuration, service observability and containerisation. These belong to **this skill**: **how F# is written** — the language and its idioms, discriminated unions and domain modelling with types, computation expressions, `Result` versus exceptions, `Fantomas`, `Expecto`/`FsCheck`, type providers, `dotnet fsi` as scripting, and **the boundary with C#** (nulls, `Option`, exposed interfaces). Arbitration rule: **if the problem is ASP.NET Core, `dotnet-standards` wins even if the code is F#**; if the problem is the shape of the type or of the F# code, this one wins.
- `haskell-fp-standards` (the other typed functional language: the boundary is **laziness versus strict evaluation** —here there are no thunks and no space leaks from `foldl`, and there is observable evaluation order— and the **class of type system**: modules/functors and effects via *handlers* here, type classes + higher-kinded types + monadic `IO` there).
- `scala-standards` (functional on the JVM: the boundary is the **runtime and Java interop**, plus its choice of Typelevel/ZIO/Pekko ecosystem).
- `rust-standards` (shares ML lineage and ADTs; the boundary is the **memory model** —ownership without GC versus GC— and the purpose: systems and bounded latency versus correctness of the logic).
- `jvm-spring-standards` (only if the problem comes in through JVM/Spring).
- `iac-standards` (**Nix as an infrastructure/deployment manager is theirs; Nix as a reproducible toolchain for this OCaml project —devShell, pinning opam/dune— is ours**).
- `cicd-standards` (the pipeline and its cache), `kubernetes-standards` (OCI image and deployment), `api-design-standards` (the HTTP/gRPC contract; here only its implementation with Dream/opium or Giraffe/Falco), `appsec-standards` (threat modelling and agnostic vulnerability classes; here only the concrete sinks of these languages), `vulnerability-management-standards` (CVE triage and SLA; here only the audit gate), `secrets-management-standards`, `observability-standards` (OTel pipeline and SLOs; here only the instrumentation), `sql-standards` (the SQL that Caqti/Petrol or Dapper/EF generate), `python-standards`/`go-standards`/`typescript-standards` (language choice when neither of these two is the answer).

## 2. Default decisions and toolchain

> Verify the latest version on the web before pinning it in a real project (§8). What follows is the state verified as of **Aug 2026**.

### OCaml

| Piece | Choice | Verified state (Aug 2026) | Note |
|---|---|---|---|
| Compiler | **OCaml 5.5.0** | released 2026-06-19 | Previous: 5.4.1 (2026-02-17). Adds *module-dependent functions* and a relocatable compiler |
| 4.x line | **4.14.4** (2026-06-15) | maintenance; support announced *at least* until the end of 2026 | **Legacy only.** No new project on 4.x; plan the exit now |
| Manager | **opam ≥ 2.5.2** | 2.5.2 released 2026-07-08 | **Minimum version for security**, not for features (§5) |
| Build | **dune 3.24.0** | 2026-06-30 | *directory targets* move to general availability |
| Formatter | **ocamlformat 0.29.0** | 2026-03-17 | `.ocamlformat` file **with the version pinned** (mandatory) |
| IDE | **Merlin 5.7.1-504** + **ocaml-lsp 1.26.0** | 2026-04-30 / 2026-04-10 | Merlin is paired to the compiler version (suffix `-504`) |
| Concurrency | **Eio 1.4** (2026-07-23) in new projects on OCaml 5 | — | `Lwt 6.1.2` (opam 2026-04-29, MIT) is still alive and is the safe option in existing code |
| Tests | **Alcotest** + **QCheck** | verify versions (§8) | Property-based is not optional |
| Base | **Stdlib** by default | — | Jane Street `Base`/`Core` is a whole-project decision (below) |

**Non-negotiable minimums**: **opam + dune**. Any OCaml project that does not use both is a project nobody from outside can build. No hand-crafted Makefiles invoking `ocamlfind`, no `ocamlbuild`. The opam switch is declared (`dune-project` + `*.opam` files generated by dune, or a versioned `opam.locked`) so that `opam switch create . --deps-only` reproduces the environment.

**OCaml version policy.** No formal LTS: roughly one minor a year is released and the previous ones stop receiving fixes quickly. Criteria: **be on the current minor and apply the patch revision without delay** — the recent precedent (OSEC-2026-01, §5) is that runtime security fixes ship as `5.x.1`/`4.14.z` and falling behind means staying exposed. The minor jump is tested on a branch with the whole opam dependency matrix: the ecosystem takes weeks to update the `ppx`es, which are the first thing to break.

**The real state of OCaml 5 and its multicore — there is a lot of confusion, this is what has been verified.**
- **Domains (shared-memory parallelism)**: the multicore runtime is OCaml 5's reason for existing and has been in production since 5.0. One domain ≈ one core; the useful number of domains is the number of available cores, not "thousands". For massive concurrency you use fibres/effects **inside** a domain, not one domain per task.
- **Effect handlers**: introduced in 5.0; **syntactic support for deep handlers arrived in 5.3**. And the critical point, quoted literally from the OCaml 5.5 manual: *"Unlike languages such as Eff and Koka, effect handlers in OCaml do not provide effect safety; the compiler does not statically ensure that all the effects performed by the program are handled."* That is: **effects are NOT in the type system.** They are declared by extending the extensible variant `Effect.t`, and an effect without a handler is a **runtime failure** (`Effect.Unhandled`), not a compilation error. There is no calendar for a typed effect system.
- Limitations you have to know before designing with effects: **there are no multi-shot continuations** (they are no use for backtracking); effects cannot be performed from a signal handler, a finaliser, a memprof callback or a GC alarm, and **they do not cross the `caml_callback` boundary** (FFI).
- **Standard library and parallelism**: `Stdlib` does not offer general concurrent structures; mutable state shared between domains is your responsibility (`Mutex`, `Atomic`, or structures from a library). **Do not assume a library from the ecosystem is *domain-safe*: most were written assuming a single thread.** Every dependency shared between domains is verified explicitly.
- Operational conclusion: **use effects for concurrency through a library that encapsulates them (Eio), not bare**. Writing your own handlers is an architectural decision that requires an ADR and an owner.

**`Lwt` versus `Async` versus `Eio` — criteria.**
- **New project on OCaml 5**: **Eio** (1.4, Jul 2026). It is the native effects route: *direct* code with no promise monad, structured cancellation, io_uring integration. Cost: a smaller ecosystem and APIs that are still moving — read the changelog before bumping the version.
- **Existing code or a hard dependency on the ecosystem**: **Lwt** (6.1.2, MIT). Still alive and what a great many libraries assume. Migrating to Eio is a project, not a refactor.
- **`Async`**: only inside a codebase that already lives in the Jane Street ecosystem (`Core` + `Async` + its ppxes). `Async` is not chosen lightly: it drags in the whole stack.
- **FORBIDDEN to mix two of these in the same binary** without an explicit and documented bridging layer. It is the number-one source of silent deadlocks in OCaml.

**Stdlib versus Jane Street `Base`/`Core` — the real implication.**
- It is not "one more library": **`Base` is designed as a full replacement for the standard library**. After `open Base`, `Stdlib` modules and values become deprecated and you have to reach them via `Stdlib.String`, `Stdlib.print_string`, etc. `Base` does not re-export what is not portable (I/O goes separately, in `stdio`). `Core` stacks on top and adds batteries (time, containers, CLI, sexp).
- What you gain: real consistency and safety — e.g. `Stdlib`'s structural polymorphic comparison, which compiles with any type and does what you do not expect, sits behind `Poly` in `Base`. And it opens the door to the rest of the suite (Async, ppx_let, sexplib, bin_prot).
- What you pay: **it is a whole-project, one-way decision**. Divergent APIs you have to relearn, friction with the examples and libraries of the rest of the ecosystem, and a large dependency tree.
- **Criteria**: a single-team application, with people willing to learn the dialect ⇒ `Core` is defensible. **A library published on opam ⇒ `Stdlib` (or at most `Base`)**: you do not impose the base library choice on the consumer. Targets with portability constraints (js_of_ocaml, unikernels, embedded) ⇒ `Base` rather than `Core`. **A single choice per repository**, in an ADR.

### F#

| Piece | Choice | Verified state (Aug 2026) | Note |
|---|---|---|---|
| Language | **F# 10** | ships with **.NET 10 (LTS)** and Visual Studio 2026 | New features no longer need `LangVersion=preview` at GA |
| SDK / runtime / support | **set by `dotnet-standards`** | — | The LTS calendar, `global.json` and EOL are not decided here |
| `FSharp.Core` | the one the SDK brings | — | Pinning a lower version by hand only with a written reason |
| Formatter | **Fantomas** (Apache-2.0) | see discrepancy below | `.editorconfig` for its options; `.fantomasignore` versioned |
| Tests | **Expecto 11.1.0** (2026-06-17) | — | `xUnit`+`FsUnit` if the repo is already mixed .NET |
| Property-based | **FsCheck 3.3.4** (2026-07-25) | — | The differential value (§4) |
| Packages | NuGet — **governed by `dotnet-standards`** | — | Paket only in repos that already use it |

**Declared discrepancy (Fantomas).** The sources do not agree: NuGet showed as the latest version **7.0.5 (2025-12-05)** while the GitHub repository has *releases* dated **April 2026**. No version number is pinned here: **check NuGet and GitHub before pinning it** (§8). What is verified and stable: **Fantomas is under Apache-2.0** (raw `LICENSE.md` file from the repository).

**F# and its coupling to .NET.** F# **has no independent version**: F# 10 is "the F# that the .NET 10 SDK brings". You do not choose the F# version, you choose the SDK — and that choice, with its support dates, **belongs to `dotnet-standards`**. Consequences that do belong here: `FSharp.Core` is updated with the SDK unless explicitly pinned; the F# 10 novelties relevant when writing code are `#nowarn`/`#warnon` **with bounded scope** (suppressing a warning in a region instead of in the whole file — use it that way), **attribute target validation** (misplaced attributes used to be accepted silently: on bumping the SDK this shows up as new errors and that is correct), and `ParallelCompilation` as a project property (enabled by default for `LangVersion=Preview` in .NET 10, with a declared intention to generalise it in .NET 11 — verify before assuming it).

**`dotnet fsi` and scripting.** F# is the best scripting option in the .NET ecosystem and it should be used as such: `.fsx` with `#r "nuget: Package, X.Y.Z"` — **always an explicit version**, never a bare `#r "nuget: Package"`, which resolves to the latest and is not reproducible. Scripts that survive their first month get promoted to a project with tests; a 500-line `.fsx` in production is debt. `dotnet fsi` is also the correct route for interactive exploration (a REPL with real types), far ahead of writing a throwaway console project.

## 3. Structure and conventions

### OCaml

- Standard dune layout: `lib/` (library, everything important), `bin/` (thin executable), `test/`. `dune-project` at the root with `(lang dune 3.x)` pinned and **`(generate_opam_files true)`** so that the `*.opam` files are derived from the `dune-project` instead of diverging.
- **`.mli` mandatory in every public module.** It is not bureaucracy: it is the only point where you decide what is API and what is implementation, and what makes it possible for the `.ml` to change without breaking anyone. A module without an `.mli` exports everything it declares, including the details.
- **Abstract types by default**: `type t` in the `.mli` without its definition, with validating constructors. It is the OCaml version of "make impossible states unrepresentable", and it is stronger than in most languages because the compiler prevents building the value any other way.
- `t` convention: a module's main type is called `t` (`User.t`, `Invoice.t`); functions take `t` as the last argument so they compose with `|>`.
- **The module system and functors are what really sets OCaml apart**, and they are the technical reason to choose it. Usage criteria, not a catalogue:
  - **`module type` (signature) as a contract** is the language's dependency inversion mechanism. It is used from the start: the domain layer depends on signatures, not on implementations.
  - **Functor** = a module parameterised by another module. It is justified when there are **≥2 real implementations** of the same signature (a real and an in-memory storage backend, a comparison policy, a DB engine) or when you want to instantiate a data structure over a type with its operations (`Map.Make`, `Set.Make` — the canonical use).
  - **Functorising "just in case" is vetoed**: a functor with a single instance is pure indirection, it worsens error messages and complicates the `dune`. Start concrete, functorise when the second implementation shows up.
  - `include` for module composition; a global `open` of a large module at the head of a file is discouraged (it breaks tracking of where each name comes from) — bounded `let open M in` or `M.(...)`.
- **`.ocamlformat` versioned and with the tool version pinned inside** (`version = 0.29.0`): without that line, two machines with different ocamlformat produce enormous diffs and the format gate becomes useless. Changing the version is a commit of its own that reformats the whole tree.
- Merlin/ocaml-lsp on every workstation, with the version paired to the switch's compiler.
- `ppx` in moderation: each one is code that runs at compile time, ties the project to the compiler version and is usually the first thing to break when bumping OCaml. Acceptable ones are the ecosystem core (`ppx_deriving`, `ppx_yojson_conv`, `ppx_expect`); a homegrown ppx requires an ADR and an owner.

### F#

- **File order in the `.fsproj` is semantic**: F# only sees what is declared before. That forces an acyclic dependency graph and is a design advantage, not a nuisance — take advantage of it by ordering `Domain → Application → Infrastructure → Api`.
- **Model the domain with types, not with validations**: records for data, **discriminated unions for alternatives**, single-case types (`type Email = private Email of string`) with a companion module exposing `create : string -> Result<Email, Error>`. The operational rule: **if a state must not exist, make it impossible to write**; loose `bool`s and `string`s with meaning are the smell to avoid.
- **`Result<'T,'TError>` for expected domain failures, exceptions for the exceptional.** An error type as a discriminated union per operation, not `string`. `Option` for legitimate absence, never to signal a failure whose reason matters.
- **Computation expressions**: use the ones that exist before writing one. `task { }` for asynchrony (**preferred over `async { }` in new code for direct interop with `Task` and lower cost**); `result { }`/`option { }` (FsToolkit or equivalent) to chain without a pyramid of `match`; `seq { }` for lazy generation. **Writing your own CE requires an ADR**: it is an API with its own rules that the whole team has to learn, and debugging inside someone else's CE is expensive. Never a CE for what `|>` and `Result.bind` solve.
- **Type providers**: powerful and dangerous. Acceptable for exploration and scripts (`.fsx` over CSV/JSON/SQL). In compiled production code they require an ADR: **they couple the build to a live external resource** (a DB schema, a sample file, a service), they break reproducible and offline builds, and some have been left unmaintained. Default alternative: generate the types in an explicit step and version them.
- **The boundary with C# — where the danger lives.** Everything arriving from C#/BCL is potentially `null` even if the type says otherwise; F#'s `Option` does **not** protect you from that.
  - **Every input from C# is normalised at the edge**: `Option.ofObj`, `isNull`, null checks in the constructor, and from there on the inside of the F# module is null-free by construction.
  - **Every output towards C# is designed as a C# API**: `Option<'T>` is awkward from C# (it shows up as `FSharpOption<T>`) — expose `TryGet` with `out`, or `null`, or a type of your own; F#'s discriminated unions and tuples are not consumed well from C#; F# modules appear as static classes. If an F# library is consumed by C#, **its public surface is designed for C# and tested from C#**, it is not assumed.
  - Reference nullability: there is modern support for annotating nullable types in F#; **verify the exact state and syntax in your SDK version before using it** (§8) — do not apply it from memory.
- **Immutability by default**: `mutable`/`ref`/mutable arrays are decisions with a reason, normally measured performance and bounded to one function.

### [Both] Exhaustive pattern matching as a compiler gate

It is the most valuable guarantee these two languages give and **it is turned into a compilation error, always**:

- **OCaml**: `(flags (:standard -w +a-4-9-40-41-42-44-45 -warn-error +8))` — at a minimum, warning 8 (*pattern-matching is not exhaustive*) and 9 (record fields not mentioned, if the style allows it) treated as errors. Practical rule: the exact set of warnings is agreed once in `dune-project`/`dune` and is not relaxed per file; a local `[@warning "-8"]` requires a reason comment.
- **F#**: `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` and, at a minimum, **FS0025** (*incomplete pattern matches*) and **FS0049**/**FS0064** watched. With F# 10, suppressing a specific one is done with `#nowarn` **bounded by region** and `#warnon` to re-enable it — not at project level.
- **FORBIDDEN: the `_` wildcard as a default branch over a domain discriminated union / variant.** It is exactly what disables the guarantee: when a new case is added, the compiler must break every site that has to be reviewed. `_` only over open or infinite types (integers, strings) or over types you do not control.
- Design corollary: model with closed unions/variants instead of integers, strings or boolean flags. Exhaustiveness only protects you if the type is closed.

## 4. Quality and testing

### [Both] Property-based testing is the differential value

In languages with ADTs and pure functions, generating cases is cheap and finds what nobody writes by hand. **It is not optional in code with invariants.**

- **OCaml: QCheck** (integrable into Alcotest via `qcheck-alcotest`). **F#: FsCheck 3.3.4** (integrable with Expecto and with xUnit).
- Mandatory properties where they apply: **serialisation round-trip** (`decode (encode x) = x` for JSON, binary, persistence), *smart constructor* invariants (nothing built through the public API violates the invariant), laws of your own operations (associativity, idempotence, commutativity where they are claimed), and equivalence between an optimised implementation and an obviously correct one.
- **State model** (state-machine testing) for stateful or concurrent logic: the only practical way to find races and invalid sequences.
- Generators are written to produce **data that respects the domain's preconditions**, not random `string`s that only exercise input validation. A weak generator gives you a property that always passes and proves nothing.
- The minimal case a failure reduces to (*shrinking*) **is frozen as a regression unit test**: the property detects, the unit test documents.

### OCaml — tooling and gates

- **ocamlformat** with a versioned `.ocamlformat` (version pinned inside). Gate: `dune build @fmt` / `dune fmt --preview` failing if there are differences.
- Tests: **Alcotest** (readable output, good dune integration) or `ppx_expect` for expectation/golden tests — very convenient for large, stable outputs, and updatable with `dune promote`; the risk is promoting without reading the diff: **review every promotion in the PR**.
- **QCheck** for properties; `qcheck-alcotest` to see them in the same suite.
- Coverage with `bisect_ppx` as a signal, never as a goal.
- Documentation with **odoc** compiling in CI (`dune build @doc`): a well-documented `.mli` is the contract.
- CI gates, in order of cost:

```
dune build @fmt --diff-command=diff          # formatting
dune build @all --profile release            # warnings as errors (see §3)
dune runtest                                 # unit + properties + expect tests
dune build @doc                              # odoc compiles
opam lint *.opam                             # package metadata
# dependency audit: see §5 and §8 (there is no `opam audit` as of Aug 2026)
```

### F# — tooling and gates

- **Fantomas** as the formatting authority (Apache-2.0), configured through `.editorconfig`, with a versioned `.fantomasignore`. Gate: `dotnet fantomas --check .`.
- **Expecto 11.1.0** by default in F#-first projects (tests as values, composable, a good story with FsCheck and with parallel tests). **xUnit + FsUnit** if the repository is already mixed .NET and you want a single test infrastructure — coherence over preference.
- **FsCheck** integrated in the same suite (`Expecto.FsCheck`).
- Warnings as errors (§3) and SDK analysis: the common `.csproj`/`.fsproj` configuration, `Directory.Build.props` and the analysers **belong to `dotnet-standards`**; what this skill fixes is that **FS0025 is never ignored**.
- Minimum gate: `dotnet fantomas --check .` → `dotnet build -warnaserror` → `dotnet test`. The full pipeline (NuGet SCA, publish, container) is defined by `dotnet-standards`.

### [Both] Test strategy

- Fast, deterministic unit tests over pure logic, which is most of the code if the design is right: pure domain, effects at the edge.
- **Edges and errors** mandatory: empty inputs, numeric limits, invalid decoding, timeouts, cancellation, unicode.
- Integration with the real dependency (same engine version as production) rather than driver mocks; mock your own boundaries (a module signature in OCaml, an interface or injected function in F#), not the world.
- Every bugfix leaves a regression test that fails before the fix. A flaky test: it is fixed or deleted.

## 5. Stack security

### OCaml

- **`Marshal` over untrusted input — FORBIDDEN. It is code execution, not deserialisation.** `Marshal.from_string`/`from_bytes`/`from_channel` and `input_value` reconstruct runtime values without validating types: a manipulated datum corrupts the heap and from there you get to arbitrary execution. Verified precedent: **OSEC-2026-01 / CVE-2026-28364**, a *buffer over-read* in `runtime/intern.c` (missing bounds validation in `readblock()`, `memcpy()` with attacker-controlled lengths), fixed in **OCaml 5.4.1 and 4.14.3 (2026-02-17)**. And the nuance that settles the discussion: the advisory itself records that **`Marshal.from*` and `input_value` remain unsafe to use** — the fix hardens the runtime, it does not make the API safe. For data crossing a trust boundary: an explicit, parsed format (JSON with `yojson`/`ppx_yojson_conv`, `bin_prot` with known types and validation, protobuf), with size and depth limits.
- **`Obj.magic` and the `Obj` module — FORBIDDEN.** It annuls the entire type system; the result is not a type error, it is memory corruption and a failure a thousand lines from the origin. No exceptions in application code. In a very low-level library: a minimal block, encapsulated behind an `.mli` exposing a safe API, a comment demonstrating the representation invariant, and a test. `Obj.magic` to "shut the compiler up" is a bug waiting for a date.
- **opam ≥ 2.5.2 as a security minimum.** Verified: **OSEC-2026-10 / CVE-2026-57825** — escape from opam's installation *sandbox* via symbolic links (`.install` files did not check the symlink resolution of the destination), fixed in **opam 2.5.2 (2026-07-08)**; and **CVE-2026-41082** (Debian's DSA-6216-1), insufficiently restricted `.install` directives that allowed escaping the package's area. Correct reading: **`opam install` runs third-party code on your machine and on your CI runner**; the sandbox is a mitigation, not a barrier.
- **opam dependency auditing — the real state, unvarnished.** The **OCaml Security Advisory Database** exists (`github.com/ocaml/security-advisories`), maintained by the OCaml security team, feeding **osv.dev**; the repository itself describes itself as *work in progress*. **As of Aug 2026 there is NO published `opam audit` command**: it is proposed and under discussion, not delivered. Operational criteria in the meantime: consume the database via OSV in the CI gate (a generic scanner that reads OSV), subscribe to the OCaml security announcements channel, and **pin the switch with a versioned `opam.locked`** so the surface is known and reviewable. Verify the state of the tooling before writing the gate (§8).
- FFI (C stubs): a memory boundary with no safety net. Specific review, `[@@noalloc]` only if it is true, and remember that effects do not cross `caml_callback`.
- SQL parameterised only (`caqti` and similar). No concatenating queries.

### F#

- **The security of the .NET stack —NuGet and its auditing, secrets, ASP.NET Core, headers, container hardening— belongs to `dotnet-standards`.** Here only what is language-specific:
- **Deserialisation**: `System.Text.Json` with concrete types. Discriminated unions **do not serialise in an obvious way** — they require an explicit converter (`FSharp.SystemTextJson` or equivalent); improvising a DU format at the edge of an API is a classic source of incompatibility and of accepting unexpected payloads. **`BinaryFormatter` is forbidden** as is all open polymorphic deserialisation.
- **Nulls as a security problem, not a style one**: a `null` coming in from C#/BCL into an F# value whose type declares it non-nullable produces a `NullReferenceException` in the wrong place, and in the worst case skips a validation. Normalisation at the edge (§3) is a control, not a courtesy.
- **NuGet auditing**: set by `dotnet-standards` (NuGetAudit, lockfiles, CPM). What this skill adds: **F# ecosystem libraries are small community projects** — before pinning one, verify maintenance, licence (by reading the real `LICENSE`, not the package field) and whether it has a replacement in the BCL. Precedent from the catalogue: tools that change licence or declare themselves *feature complete* with a commercial action.

### [Both]

- Validation at the edge with types: the *smart constructor* returning `Result`/`option` is the input control. No "the layer above will validate it".
- Secrets never in the tree, in logs or reachable by a `%A`/automatic printing derivation: types containing credentials carry explicit redacted printing.
- Crypto: a maintained library from the respective ecosystem, verified at the time (§8). Nothing homegrown, no MD5/SHA-1/DES/ECB, TLS 1.2+.

## 6. Performance and operability

### OCaml

- **Domains ≈ cores.** The number of domains is sized by available CPUs and **is adjusted to the container's limit**, not to the physical machine; over-subscribing domains degrades through GC contention. Concurrency for many tasks is done with fibres/effects inside the domain (Eio), not with one domain per task.
- State shared between domains: `Atomic`, `Mutex`, or concurrent structures from a library, **with the dependency's safety verified explicitly** (§2). Compile and run code that shares state between domains with **TSan**; there is support and it was used to fix real bugs in the runtime itself.
- GC: OCaml's generational GC has short pauses by design, but you measure before claiming it. Levers (`OCAMLRUNPARAM`: `s` minor heap size, `o` major overhead) **only with measurement**, not copied from a blog.
- Profiling: `perf` over the native binary, `landmarks`/`memtrace` for allocation. `dune build --profile release` for production; the `dev` profile carries assertions and less optimisation.
- **Compiling to JavaScript: `js_of_ocaml`** — it compiles the bytecode to JS and is the mature route for reusing an OCaml domain in the browser (or `wasm_of_ocaml` for WebAssembly; verify maturity before committing — §8). Criteria: **sharing the domain core between server and client is the legitimate use case**; writing an entire SPA in OCaml is a team decision of the same calibre as §7. Bundle size is measured and watched in CI.
- Observability: structured logging (`logs` with a JSON reporter) and process metrics; verify the state of the OpenTelemetry binding before committing (§8). Explicit timeouts on every network operation; structured cancellation with Eio (`Switch`) or `Lwt.cancel` carefully. Graceful shutdown with `SIGTERM` handling that drains before closing.

### F#

- **Almost everything operational is set by `dotnet-standards`** (observability, health checks, `HttpClient` timeouts and resilience, limits, graceful shutdown, container, AOT). What is language-specific:
- **`task { }` over `async { }`** in new code: fewer allocations and a direct boundary with the `Task` of the rest of the ecosystem. Convert at the edge, do not sprinkle conversions through the code.
- **Allocation**: records, discriminated unions and tuples are reference types by default; on **measured** hot paths, consider `[<Struct>]` on small DUs and records, and `struct` tuples. Never without BenchmarkDotNet in front.
- F# lists (`list`) are immutable linked lists: excellent for the domain, bad for large collections with indexed access or built by repeated concatenation. `array`/`ResizeArray` inside a hot function is acceptable if the result comes out immutable.
- `Seq` is lazy and **can be enumerated twice**: materialise before reusing; a `Seq` over an already closed resource is a classic bug.
- Compilation: `ParallelCompilation` (§2) reduces build time in large projects; verify the default for your SDK version before assuming it.

## 7. Long-term sustainability

- **Team risk, with different profiles.** **OCaml**: a small community, hard hiring, and most of the industrial ecosystem gravitating around one company (Jane Street) whose libraries are excellent but define a dialect. The same bar applies as in `haskell-fp-standards`: **bus factor ≥3 and a training budget before approving the stack**. **F#**: the risk is lower because the runtime, the tooling, the hosting and .NET hiring are mainstream; the real risk is **ending up as the only F# project in a C# department**, with nobody to review it or maintain it. Honest mitigation: F# wins when the team is already .NET and the problem is domain modelling; if there is not one more person who reads F#, the answer is C# with good modelling.
- **Upgrade cadence.** OCaml: current minor + patch without delay; the minor jump is tested first because of the `ppx`es and the opam dependencies, which are the real bottleneck. `opam.locked` versioned and updated in a PR of its own, not mixed with features. F#: the cadence is set by the SDK and **is fixed by `dotnet-standards`** (LTS to LTS); what belongs here is reviewing the new warnings each version of the F# compiler brings — F# 10's attribute target validation is the example: errors appear where there used to be silence, and fixing them is the right thing.
- **Documentation as mitigation**: `.mli` documented with odoc in OCaml, signatures and XML doc in F#; ADRs for the structural decisions (Stdlib versus Core; Eio versus Lwt; type providers yes or no; Expecto versus xUnit) and a `CONTRIBUTING` that starts from zero (`opam switch create . --deps-only` / `dotnet restore`).
- **Conscious debt**: every shortcut with `TODO(user): reason — issue`. No warning silenced without a comment and a link.

**PROHIBITIONS (an exception requires an ADR and approval).**
- ❌ **[OCaml] `Marshal.from*` / `input_value` over data crossing a trust boundary.** It is code execution. The hardening in 5.4.1/4.14.3 does not make it safe.
- ❌ **[OCaml] `Obj.magic` and the `Obj` module** in application code; `Obj.magic` to silence the compiler.
- ❌ **[Both] The `_` wildcard as a default branch over a domain union/variant**; disabling the exhaustiveness warning (OCaml warning 8, F# FS0025) at project level.
- ❌ [Both] Warnings without `-warn-error` / `TreatWarningsAsErrors`; global suppression of a warning that is resolved by bounding it.
- ❌ [OCaml] A project without `opam` + `dune`; hand-crafted Makefiles over `ocamlfind`; `ocamlbuild`.
- ❌ [OCaml] `.ocamlformat` without the tool version pinned; a public module without an `.mli`.
- ❌ [OCaml] Mixing Lwt, Async and Eio in the same binary without an explicit, documented bridge; writing your own effect handlers without an ADR.
- ❌ [OCaml] Assuming a library is *domain-safe* without checking; sharing state between domains without `Atomic`/`Mutex` and without passing TSan.
- ❌ [OCaml] Functorising with a single implementation; global `open` of large modules.
- ❌ [OCaml] opam < 2.5.2 (sandbox escape, §5); OCaml 4.x in a new project; installing dependencies in CI without a versioned lock.
- ❌ [F#] `Option`/discriminated unions exposed raw in an API meant for consumption from C#, without a test from C#.
- ❌ [F#] Consuming values from C#/BCL without normalising nulls at the edge.
- ❌ [F#] `#r "nuget: X"` without a version in scripts; a production `.fsx` not promoted to a project with tests.
- ❌ [F#] Type providers in compiled production code without an ADR (they couple the build to an external resource).
- ❌ [F#] Your own computation expression without an ADR; a CE for what `|>` + `Result.bind` solves.
- ❌ [F#] `BinaryFormatter`; DUs serialised without an explicit converter.
- ❌ [F#] Deciding here what `dotnet-standards` decides (SDK, LTS, NuGet, ASP.NET Core, container): it is a boundary violation, not a shortcut.
- ❌ [Both] `string`/`bool`/`int` as a substitute for a domain type when a closed variant exists.
- ❌ [Both] Property-based testing absent in code with invariants; a case reduced by *shrinking* not frozen as a regression.

**When NOT to choose these languages (honest prohibition).**
- ❌ **OCaml** when there is no bus factor ≥3, when the team cannot sustain a small ecosystem, or when the project depends on first-line cloud/ML SDKs that do not exist in OCaml or are third-party wrappers. Nor if the work is infrastructure glue → `go-standards`/`python-standards`.
- ❌ **OCaml** if the requirement is parallelism with mature concurrent structures "out of the box": OCaml 5 gives you the runtime, but the ecosystem still assumes a single thread in many places.
- ❌ **OCaml and F#** for hard latency / real time: both have a GC → `rust-standards`.
- ❌ **F#** when there is no second person in the organisation capable of reading and reviewing it. An isolated F# service in a C# house is organisational debt, however good the solution is.
- ❌ **F#** if the real decision is "I want functional on .NET" without a modelling problem that justifies it: modern C# with records, patterns and nullable references covers a lot.
- ❌ Either of the two chosen "because the team wants to learn" in a system with an SLA.

## 8. Mandatory web verification

Before pinning a version, a flag or claiming the state of the ecosystem, **verify on the web** (not from memory):

1. **Current OCaml and the state of 4.x**: `ocaml.org/releases` and `ocaml.org/changelog`; announcements on `discuss.ocaml.org`. Is 5.5.0 still the latest? Has 5.6 come out? Has 4.14 maintenance ended (announced *at least* until the end of 2026)?
2. **What is really stable in OCaml 5 today**: the official manual for the specific version (`ocaml.org/manual/5.x/effects.html`) — **re-read the sentence about *effect safety* before claiming anything**; as of Aug 2026 effects are **not typed** and there is no calendar for them to be. Also check the state of multi-shot continuations and the restrictions on `caml_callback` and signals.
3. **OCaml and opam security**: `github.com/ocaml/security-advisories` and OSV. Verified as of Aug 2026: **OSEC-2026-01 / CVE-2026-28364** (Marshal, fixed in 5.4.1 / 4.14.3) and **OSEC-2026-10 / CVE-2026-57825** (opam sandbox escape, fixed in **opam 2.5.2**, 2026-07-08). Check whether **`opam audit`** already exists — as of Aug 2026 it is **proposed but not delivered**, and that is the gap in the SCA gate.
4. **OCaml tooling**: dune (3.24.0, 2026-06-30), ocamlformat (0.29.0, 2026-03-17), opam (≥2.5.2), Merlin (5.7.1-504) and ocaml-lsp (1.26.0). Merlin is paired to the compiler version: check the suffix.
5. **OCaml concurrency**: Eio (1.4, 2026-07-23) and Lwt (6.1.2 on opam, 2026-04-29, MIT). Lwt's release feed mixes the 5.x and 6.x lines — **cross-check with `ocaml.org/p/lwt`, which is the correct source**. State and maturity of Async outside the Jane Street ecosystem.
6. **F# and its SDK**: the F# version comes with the SDK — verify on `learn.microsoft.com/dotnet/fsharp/whats-new` which one the current SDK brings (as of Aug 2026: **F# 10 with .NET 10 LTS**) and **that SDK's support dates in `dotnet-standards`**, not here. Confirm the `ParallelCompilation` default in the specific version and the state of nullable reference annotation in F#.
7. **F# tooling and licences**: **Fantomas — verified Apache-2.0; version discrepancy declared in §2 (NuGet 7.0.5 of Dec 2025 versus GitHub releases of Apr 2026): check both sources before pinning.** Expecto (11.1.0, 2026-06-17) and FsCheck (3.3.4, 2026-07-25): versions verified, **licences NOT verified**. FsUnit and FsToolkit: unverified. Precedents that force you to look at the licence and the maintenance mode before pinning a tool: Trivy (licence change), gitleaks (*feature complete* + an action with a commercial licence for organisations since v2).

**Declared gaps (not verified as of Aug 2026, do not fill from memory):**
- Versions and maintenance state of **Alcotest, QCheck, ppx_expect, bisect_ppx, odoc, yojson, caqti, Dream/opium** and of the **OpenTelemetry** binding for OCaml.
- State and licence of **Jane Street `Base`/`Core`/`Async`** and their current version; the arguments in §2 about adoption cost come largely from community discussion predating 2022 and **must be reconfirmed with current data** (e.g. reverse dependencies on opam).
- Current maturity of **`js_of_ocaml`** and, above all, of **`wasm_of_ocaml`** (version, limitations, output size).
- Licences of **Expecto, FsCheck, FsUnit, FsToolkit.ErrorHandling** and maintenance state of **FSharp.SystemTextJson** and of the usual type providers.
- Exact version of **Fantomas** (see discrepancy) and the state of reference nullability support in F#.
- Existence and definitive name of an opam auditing tool.

If the web contradicts this document, **the web wins** — flag the discrepancy.
