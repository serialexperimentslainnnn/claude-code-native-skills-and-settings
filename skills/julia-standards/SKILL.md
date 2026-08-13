---
name: julia-standards
description: Use when writing, reviewing or deploying Julia code - .jl files, Project.toml, Manifest.toml, JuliaProject.toml, .JuliaFormatter.toml, Pkg REPL mode and Pkg.instantiate, juliaup channels, multiple dispatch and method definitions, type stability with @code_warntype or @inferred, @allocated/@benchmark/BenchmarkTools, @inbounds/@simd/@views broadcasting, Threads.@spawn/@threads/Distributed, ccall/PythonCall/PyCall/RCall interop, Test/Aqua.jl/JET.jl suites, Documenter.jl docs, or PackageCompiler/juliac binaries.
---

# Julia standards (reference: August 2026)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all Julia work: packages, numerical code, environments, tests, packaging and deployment.
Triggers: `.jl`, `Project.toml`, `Manifest.toml`, `.JuliaFormatter.toml`, `test/runtests.jl`, `juliaup`,
`Threads.@spawn`, `@code_warntype`, `ccall`, `PythonCall`.

**The two axes of this skill.** (1) **Multiple dispatch is the language**: it is not sugar over OOP,
it is the mechanism of composition and extension, and almost every design error in Julia is a dispatch
design error (badly cut type hierarchies, *type piracy*, methods that are too specific or too lax).
(2) **Latency** ("time to first plot") is the language's historical objection and there is a great deal
of expired information about it: the problem is not solved, it is **bounded** — the native code cache
arrived in **1.9**, not in the recent versions, and current work is on *trimming* and standalone
binaries. Any claim about latency is verified against the version you are going to use, not against a
2022 blog post.

**Not applicable**: see `mlops-standards` (**the model lifecycle is theirs**: model registry and
versioning, *feature store*, serving, drift monitoring, retraining, *train/serve skew* —
**how the Julia that trains or scores is written belongs here**), `data-engineering-standards`
(ingestion, orchestration, idempotency, *backfill*, Parquet, freshness SLA: the platform is theirs; the
computation code that consumes it belongs here), `analytics-bi-standards` (the dashboard and who
decides with it; the code that produces the figures, here), `data-warehouse-modeling-standards` (the
shape of the analytical model), `lakehouse-standards` (table format and catalogue),
`sql-standards` (**the SQL you write via `DBInterface`/`LibPQ` is subject to their criteria**),
`python-standards` (§7 sets when the right answer is Python), `r-standards` (statistics and
communication of results; see §7), `gpu-computing-standards` (the GPU as a resource that is
provisioned, shared, monitored and paid for: driver, CUDA, MIG, quotas, cost; **the kernel and the
`CUDA.jl`/`KernelAbstractions.jl` code that uses it belongs here**), `llm-app-engineering-standards`
and `rag-standards` (the AI application layer), `ai-governance-standards` (governance and compliance),
`c-standards`/`cpp-standards` (**the native code on the other side of a `ccall`**: memory, UB,
sanitizers, ABI; the boundary from Julia —`ccall`, `Ptr`, `GC.@preserve`, `unsafe_*`, JLL— belongs
here), `fortran-standards` (**the Fortran kernel on the other side of a `ccall`**: `bind(c)`,
contiguity, index order, parallelism model and compiler flags are theirs; the boundary from Julia
belongs here), `cicd-standards` (the pipeline that runs the gates of §4), `kubernetes-standards`
(image and deployment), `appsec-standards` (agnostic threat modelling; here only the Julia *sinks*),
`vulnerability-management-standards` (triage and finding SLA; here only the state of scanning),
`secrets-management-standards`, `observability-standards` (OTel/Prometheus pipeline; here only the
instrumentation in the code), `api-design-standards` (the **contract** of an HTTP service in Julia:
resources, codes, pagination, versioning).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Verified as of Aug 2026 | Why |
|---|---|---|---|
| Runtime (production) | **LTS** unless there is a concrete need | **1.10.11 (2026-03-09)** is the current LTS | Julia supports each minor **only until the next one ships**: 1.11 is already EOL. Without LTS, "stable" implies an upgrade every ~4-5 months |
| Runtime (features/performance) | **Current stable** | **1.12.6 (2026-04-09)** | 1.12 will expire when 1.13 ships. **1.13 is not final as of Aug 2026** (rc2 on 2026-07-29); `master` is already 1.14-dev |
| Installer/versions | **`juliaup`** with the `lts` and `release` channels | 1.20.9 (2026-07-28) | Never the Julia from the distro's package manager |
| Environments | `Pkg` + `Project.toml` per project | — | One environment per project; never install into the global `@v1.x` environment |
| Reproducibility | **`Manifest.toml` versioned in applications** | — | See §3: in **packages** the `Manifest.toml` is NOT versioned |
| Formatting | **`JuliaFormatter`** with `.JuliaFormatter.toml` | 2.12.4 (2026-07-31) | Very high release cadence: **pin exactly** or CI breaks on its own |
| Static analysis | **`JET.jl`** | 0.12.0 (2026-07-28) | Pre-1.0 and **coupled to compiler internals**: the JET version depends on the Julia one |
| Package quality | **`Aqua.jl`** | 0.8.16 (2026-06-05) | Detects *type piracy*, method ambiguities, broken exports, unused deps, incomplete `[compat]` |
| Tests | `Test` (stdlib) | — | Sufficient; `TestItems`/`ReTest` only if the ergonomics justify it |
| Benchmarks | **`BenchmarkTools.jl`** (`@benchmark`, `@btime`) | — | A bare `@time` measures compilation on the first call: it is useless for measuring |
| Documentation | **`Documenter.jl`** | 1.17.0 (2026-02-20) | *Doctests* in CI |
| Standalone binary | **`PackageCompiler.jl`** (*sysimage*) / **`juliac`+`--trim`** (executable) | PackageCompiler 2.4.0 (2026-06-10) | `--trim` is **experimental** (1.12+) and requires `--experimental`; it requires the absence of reachable dynamic dispatch |
| Python interop | **`PythonCall.jl`** in new code | — | `PyCall.jl` is in maintenance mode; PythonCall isolates the environment with CondaPkg and is *type-stable* by default |
| R interop | `RCall.jl` | — | — |

**Version criteria**: if the service has an SLA and you are not going to dedicate an upgrade window
every 4-5 months, **LTS**. If you need *trimming*, the threading improvements or a package that only
supports 1.12+, stable — assuming the upgrade to 1.13 as soon as it ships. **Do not mix**: the Julia
version is pinned in `[compat]` and in CI, and the same number runs locally, in CI and in production.

## 3. Structure and conventions

```
MiPaquete/
  Project.toml       # name, uuid, version, [deps], [compat] MANDATORY
  Manifest.toml      # package: .gitignore  |  application/service: versioned
  src/MiPaquete.jl   # root module; includes and exports
  test/runtests.jl   # + its own Project.toml in test/
  docs/              # Documenter
  ext/               # package extensions (weak deps)
```

- **`Manifest.toml`: the most frequently broken rule.** In an **application** (service, pipeline,
  analysis that must be reproducible) it is **always versioned**: it is the lockfile, and without it
  `Pkg.instantiate()` resolves different versions every day. In a **publishable library** it is **not**
  versioned: it would pin your consumers' dependency tree. A library's reproducibility comes from
  `[compat]`, not from the manifest. Deployment: `Pkg.instantiate()` over the versioned manifest, never
  `Pkg.update()`.
- **`[compat]` is mandatory** for every dependency and for `julia`. Without it, the General registry
  does not even accept the package, and a `[compat]` with an open upper bound turns anyone else's
  release into your failure. Use SemVer bounds (`"1"`, `"0.8.3"`), not `">=x"`.
- Registry: **General** by default; a private registry (`LocalRegistry`) for internal code. Never
  `Pkg.add(url=...)` to a branch in production — either it comes in through a registry, or it is pinned
  by commit in the manifest.
- Names: types `UpperCamelCase`, functions and variables `lowercase`/`snake_case` without underscores
  if it still reads well, constants `UPPER`; a `!` suffix on every function that **mutates** its
  arguments (and the mutated argument goes **first**). Modules = the package name.
- Minimal exports: export what is API, the rest is accessed qualified. Everything exported is
  documented and enters SemVer.
- Files per concept, not a `utils.jl`; `include()` only from the root module, in explicit order.

**Types and dispatch — the hard rules:**
- Design **generic functions with methods**, not hierarchies. Abstract types define *interfaces* (which
  methods must exist), and that interface is **documented**: Julia does not verify it for you.
- **Annotate the field types of a `struct`, always.** An `::Any` field (or a non-concrete parametric
  type) destroys the performance of everything that touches the object. Use type parameters
  (`struct Punto{T<:Real}`) instead of abstract fields.
- `struct` **immutable by default**; `mutable struct` only when the state has to change.
- Annotating the types of the **arguments** does not speed anything up: it is for dispatch and for
  documenting the contract. Be as generic as you can (`AbstractVector{<:Real}`, not `Vector{Float64}`),
  unless you want to restrict deliberately.
- **`Union{}` and `Any` in an inference are a symptom**: `Union{}` as a return type means "this always
  throws"; `Any` means the compiler gave up. Both show up in `@code_warntype`.

**Type piracy: a serious antipattern.** The manual's definition: *"«Type piracy» refers to the practice
of extending or redefining methods in Base or other packages on types that you have not defined."* If
neither the function nor any of the method's types are yours, you are pirating: you change the
behaviour of someone else's code globally and invisibly, and the result can range from a remote and
untraceable bug to, in extreme cases, taking Julia down. Alternatives: define your own wrapper type,
your own function, or use a `struct` with the desired behaviour. `Aqua.jl` detects it — **make that
test block the merge**.

**Error style**: your own typed exceptions (`struct MiError <: Exception`) with `showerror`;
Base's `ArgumentError`/`DomainError`/`BoundsError` when they fit. `@assert` is for internal invariants
and **can disappear with `--check-bounds=no`/optimisations**: do not use it to validate input. No empty
`catch e end`; `try/finally` (or the `do`-block patterns) to release resources.

## 4. Quality: formatting, analysis, tests

- **Formatting**: `JuliaFormatter` with a versioned `.JuliaFormatter.toml`, checked in CI. **Pin the
  version exactly** in the CI environment: it publishes several versions a week and a style change
  breaks the gate without anyone having touched the code.
- **Static analysis**: `JET.jl` (`report_package`) over the package. Realistically: JET is **pre-1.0**
  and depends on compiler internals, so a Julia upgrade can change its findings. Introduce it as an
  **informative** job first and turn it into a gate when the baseline is clean; never leave its version
  floating.
- **`Aqua.jl` as a gate**: `Aqua.test_all(MiPaquete)` in `runtests.jl`. It covers what no human review
  catches: type piracy, method ambiguities, incomplete `[compat]`, declared and unused deps, exports
  that do not exist.
- **Tests (`Test` stdlib)**:
  - `@testset`s nested per unit of behaviour; one failure reason per test.
  - Mandatory edges: empty collection, one element, `NaN`/`Inf`/`-0.0`, integer overflow (**`Int` in
    Julia wraps silently**, it does not promote), singular matrix, unexpected type, `missing`
    propagating, out-of-range indices.
  - Floating point numbers: `≈` (`isapprox`) with **explicit** `atol`/`rtol`, never `==`.
  - **`@inferred` over the hot path functions**: it turns "this was type-stable" into a test that fails
    when somebody breaks it. It is the most valuable test in a Julia package.
  - `Random`: an explicit seed per test (`StableRNGs` if the result must be identical across Julia
    versions — **the `Random` RNG stream can change between minors**).
  - Every fixed bug leaves a regression test. Flaky = fixed or deleted.
- **CI gates** (they block the merge, cheapest first):
  1. `JuliaFormatter` in check mode (pinned version).
  2. Reproducible `Pkg.instantiate()` + `Aqua.test_all`.
  3. `Pkg.test()` with coverage (`Coverage.jl`/Codecov); agreed threshold, coverage is a signal.
  4. `@inferred` / performance regression benchmarks on the critical paths.
  5. `JET.jl` (informative → gate) and `Documenter` doctests.
  6. Dependency audit (§5) and artifact build.
- **CI matrix**: LTS + stable + `nightly` (the last one allowed to fail). If you support both lines,
  both are tested — saying so in the README without testing it is lying.

## 5. Stack security

- **`Serialization` (`serialize`/`deserialize`): it is neither an interchange format nor safe.**
  Official documentation: *"`deserialize` assumes the binary data read from `stream` is correct and has
  been serialized by a compatible implementation of `serialize`. `deserialize` is designed for
  simplicity and performance, and so does not validate the data read. Malformed data can result in
  process termination."* In addition, *"The data format can change in minor (1.x) Julia releases"* and
  the word size (32/64 bits) of the reading and the writing machine **must match**. Rules:
  **FORBIDDEN** to deserialise untrusted input; **FORBIDDEN** to use `Serialization` as a persistence
  format across versions or across machines. For data: JLD2, Arrow, Parquet, JSON or a versioned format
  of your own, always validated on read.
- **`eval` and metaprogramming**: `@eval`/`eval` over strings built with user input, and `Meta.parse`
  of input, are **arbitrary code execution: FORBIDDEN**. In addition, `eval` at runtime invalidates
  compiled code and causes recompilation (latency cost). Macros are for syntactic transformation at
  compile time; if a macro can be a function, it is a function. `include()` of paths built with input:
  forbidden.
- **`ccall` and `unsafe_*`**: `ccall` is a total trust boundary — a signature error is memory
  corruption, not an exception. Rules: signatures verified against the real header, `GC.@preserve`
  around any pointer to Julia-managed memory that crosses the boundary, and
  `unsafe_load`/`unsafe_wrap`/`unsafe_store!` only with verified length and ownership. Third-party
  binaries: **JLL** packages from the ecosystem (BinaryBuilder), never `.so` files downloaded by hand.
- **`@inbounds` and `@simd` are unsafe by construction.** `@inbounds` **removes the bounds check**:
  with a wrong index you read or write outside the array — silent memory corruption, not a
  `BoundsError`. `@simd` promises the compiler that the iterations are independent and that it may
  reorder the operations (including floating point arithmetic, so **the numerical result can change**).
  Criteria: only after measuring that they help, only in loops whose indices are provably correct by
  construction, with a test covering the extremes, and never over indices derived from external input.
  `--check-bounds=no` globally: **FORBIDDEN** in production.
- **Dependency auditing: the ecosystem is immature and that has to be said.** As of Aug 2026 **there is
  no `Pkg.audit`** in Pkg (it is still an open proposal). What does exist: the **Julia Security Advisory
  Database** (`SecurityAdvisories.jl`), with advisories identified as `JLSEC-YYYY-nnn` in an
  **OSV**-compatible format, and the **Security Working Group** created in 2025-11. Practice today:
  consume those advisories from an OSV-compatible scanner over the `Manifest.toml`, and **assume
  partial coverage** — in particular that of the >1,500 **JLL** packages, which repackage third-party
  binaries whose CVEs are not automatically mapped to the JLL name. This is the ecosystem's largest
  risk surface and today it is **not reliably covered**. Do not invent a tool that does not exist;
  declare the gap (§8).
- **SQL / commands**: parameterised queries via `DBInterface.execute(stmt, params)`; interpolating input
  into SQL is an absolute veto. `Cmd` backticks (`run(`cmd $arg`)`) do **not** go through a shell and
  that protects from shell injection — but `run(`sh -c $x`)` is injection. Never build a `Cmd` from a
  string with input.
- **Secrets**: environment variables or a manager; never in `Project.toml`, in the code, in
  `LocalPreferences.toml` or in exported Pluto notebooks. Careful with the output of `@show`/`dump`
  over config structures.
- **HTTP services**: validate and limit the body size, timeouts on every outbound call, and do not
  return *stack traces* to the client — a Julia trace exposes internal paths and package names.
- **Containers**: an image based on the official `julia:<version>` with an exact version, non-root,
  multi-stage. **The image is large** — the precompiled package depot (`~/.julia`) weighs a fair
  amount and the `PackageCompiler` *sysimage* adds hundreds of MB. Precompile **in the build**
  (`Pkg.precompile()`), never at container start-up, and discard the compiler and the build sources in
  the final stage.

## 6. Performance and operability

**Type stability is performance criterion number one.** If the compiler can infer a concrete type for
each value, it generates specialised code comparable to C; if not, it falls back to dynamic dispatch
and allocations, and you lose one or two orders of magnitude. Protocol, in this order:
1. `@code_warntype` over the function: anything in red (`Any`, a wide `Union{...}`) is the bug.
2. `@inferred` in the test so it does not come back.
3. `@allocated`/`@benchmark`: in a well-written numerical loop, allocations tend to **zero**.
   Unexpected allocations = type instability or accidental copies.
4. `Profile`/`ProfileView` to locate; never optimise without having measured.

Concrete silent killers:
- **Untyped global variables**: a global without `const` can change type, so the compiler infers
  nothing from it and all its use becomes dynamic. Rule: **the work goes inside functions**, with the
  data as arguments; the globals you do need are declared `const` (or with a type annotation). A
  top-level script with a heavy loop is the slowest possible pattern.
- Containers with an abstract type: `Vector{Any}`, `Dict{String,Any}`, or a `struct` with `Any` fields.
- Functions that return different types depending on a branch.
- *Closures* that capture variables whose type changes.

Memory and allocations:
- **`@views` / `view` instead of copies** when slicing arrays (`A[:, 1]` **copies**). In hot loops, the
  difference is everything.
- *Broadcasting* with `.` **fuses** into a single loop with no temporaries (`@.` so as not to forget a
  dot); chaining operations without `.` creates one temporary array per operation.
- Preallocate and use the `!` variants (`mul!`, `map!`, `sort!`) on the hot path.
- Arrays with a concrete element type and `StaticArrays` for small fixed-size vectors.

**Latency (TTFX) — real state, no folklore**: the **native code** cache has existed since **Julia 1.9**
(*package images*); in exchange, precompilation is slower and the caches larger. There is still latency
on the first execution of uncached code. Tools in order of cost: (a) precompile in the image build;
(b) precompilation workloads in the package itself (`PrecompileTools`); (c) a *sysimage* with
`PackageCompiler`; (d) a standalone executable with `juliac --trim` (**experimental**, 1.12+, requires
`--experimental` and **fails if there is dynamic dispatch reachable from the entry point** — that is,
it demands strictly inferable code). For CLIs and short, frequent functions, latency is still an
argument against Julia (§7).

Parallelism:
- **Threads** for shared memory: `Threads.@spawn` + `fetch`, `Threads.@threads` for homogeneous loops.
  Since **1.12** there is by default **1 interactive thread in addition to the worker one** (`-t1,1`),
  and `Threads.@spawn :samepool` to avoid jumping *threadpool*. `--gcthreads`/`JULIA_NUM_GC_THREADS`
  controls the GC threads. Julia's threads are **real, with no GIL** — and that is why data races are
  real too: without explicit synchronisation (`Atomic`, `ReentrantLock`, channels) code with mutable
  shared state is incorrect, not slow.
- Tasks **migrate between threads** within the same *threadpool*: do not assume affinity and do not use
  `threadid()` to index per-thread buffers (the classic broken pattern); use `OncePerTask`/per-task
  structures or partition the work explicitly.
- **`Distributed`** (or `MPI.jl`) for multi-process/multi-node when the problem does not fit on one
  machine or when you want isolation. Cost: serialisation between processes and *worker* start-up.
- Never launch more threads than the cores assigned to the container: set `JULIA_NUM_THREADS`
  explicitly in the deployment.

Operability:
- Structured logging over `Logging` with a *correlation id*; metrics and traces exported
  (`observability-standards` for the pipeline). `/healthz` and `/readyz` endpoints in services.
- Explicit timeouts on every outbound call; `Base.exit_on_sigint(false)` and SIGTERM handling for a
  clean shutdown of tasks and connections.
- Pin the seed and record the Julia version and the hash of the `Manifest.toml` alongside any published
  numerical result: without that it is not reproducible even if the code is in git.
- Interop: `PythonCall` respects the GIL — real parallelism ends at the boundary with Python; every
  long `ccall` blocks GC safepoints unless `@ccall ... gc_safe=true`.

## 7. Long-term sustainability

- **Cadence**: minors every ~4-5 months, **each minor supported only until the next one ships**.
  Choosing "stable" implies a continuous upgrade commitment; choosing LTS implies staying out of
  features for years and accepting that **ecosystem packages are starting to require 1.12+**. It is an
  operational decision, not a matter of taste: decide it explicitly and put it in `[compat]`.
- Pre-1.0 ecosystem: a large share of packages live in `0.x`, where SemVer gives `0.x.y → 0.(x+1).0`
  the status of a break. Strict `[compat]` and upgrades with a green suite, not a blind `Pkg.update()`.
  A critical pre-1.0 dependency with a single maintainer is project risk: measure it.
- The ecosystem is **smaller than Python's or R's**. Before adopting: recent maintenance, number of
  maintainers, and whether the package follows the latest LTS. The answer "we will write it ourselves"
  is more frequent here — and it is a cost, not an advantage.
- Your own deprecations: `Base.depwarn` + changelog + window; third-party ones are debt with an issue.
- **The debt of analysis that becomes a service**: a research script with globals, chained `include()`
  and top-level state **is not wrapped in an HTTP server: it is rewritten as a package with tests,
  annotated types and `@inferred` on the hot path**. In Julia this is not just hygiene: top-level code
  with untyped globals is also the slowest pattern in the language, so the debt is charged in latency
  and in a CPU bill from day one.

**When NOT to choose Julia** (honesty first):
- ❌ A CLI or *serverless* with frequent start-up and short execution: start-up latency eats you alive,
  unless you take on `juliac --trim` (experimental) or a *sysimage* and its limitations.
- ❌ Web/CRUD backend, systems integration, infrastructure *scripting*: a far poorer ecosystem and a
  maintenance team that is harder to find.
- ❌ Julia "because it is faster" **before having measured vectorised Python (NumPy/Polars) or R with
  `data.table`**. If the work is already a call into BLAS or a native library, Julia will give you
  nothing.
- ❌ Julia because one person on the team knows it, in an artifact with an SLA that others will
  maintain.
- ✅ **Julia is the right answer** when the bottleneck is **a numerical loop that cannot be vectorised**
  (step-by-step simulation, ODE/PDE solving, optimisation, Monte Carlo methods, autodifferentiation
  over your own code), and the alternative today is "prototype in Python + rewrite in C++" — that is,
  when eliminating the **two-language problem** is the real benefit. Also when you want generic
  composition across libraries (units, dual numbers, uncertainty) that in other languages would require
  rewriting the library.
- ✅ **Python** (see `python-standards`) when the work is engineering around the computation: service,
  integration, production ML, orchestration, or when the ecosystem already has the library.
- ✅ **R** (see `r-standards`) for statistical modelling, biostatistics, publishable graphics and
  reproducible reports. **The choice is almost never "R or Julia"**: they share the niche of "a
  scientific language that is not Python" and nothing else — R is statistics and communication of
  results, Julia is numerical performance.

**List of prohibitions (veto):**
- ❌ An application or service deployed without a versioned `Manifest.toml`; `Pkg.update()` at deploy time.
- ❌ Publishing a **package** with a versioned `Manifest.toml`, or without `[compat]` for all its deps.
- ❌ Installing a project's dependencies into the global `@v1.x` environment.
- ❌ `deserialize()` over untrusted input; `Serialization` as a persistence or interchange format
  across versions/machines.
- ❌ `eval`/`@eval`/`Meta.parse` over user input. `include()` of a path built with input.
- ❌ **Type piracy** (methods over functions and types that are not yours). `Aqua.jl` must block it.
- ❌ `@inbounds` without having proved the indices are correct; `--check-bounds=no` in production;
  `@simd` over non-independent iterations or where the numerical result must be deterministic.
- ❌ Heavy work at the top level of the script; untyped mutable globals as configuration.
- ❌ A `struct` with abstract-typed or `Any` fields on the hot path.
- ❌ `@time` as a performance measurement (it measures compilation); optimising without a prior
  `@code_warntype`.
- ❌ `threadid()` to index per-thread state (tasks migrate).
- ❌ Mutable shared state between threads without explicit synchronisation.
- ❌ Empty `catch e end`; `@assert` to validate user input.
- ❌ `ccall` without `GC.@preserve` over Julia-managed memory; third-party `.so` files outside a JLL.
- ❌ Running on an EOL version (1.11 is one) "because it works".
- ❌ Leaving `JuliaFormatter` or `JET.jl` without a pinned version in CI.

## 8. Mandatory web verification

Before pinning versions or decisions, **verify online** (WebSearch/WebFetch; for versions, GitHub
Releases Atom feeds and `julialang.org/downloads/manual-downloads` — not the summariser over the GitHub
Releases HTML):
1. **The current stable and LTS and which one is EOL** (`julialang.org/downloads/manual-downloads`,
   `endoflife.date/julia`). As of Aug 2026: stable **1.12.6 (2026-04-09)**, LTS **1.10.11
   (2026-03-09)**, **1.11 EOL**. **1.13 was not final as of Aug 2026** (rc2 on 2026-07-29): check
   whether it has shipped, because when it does **1.12 goes EOL** and you have to decide whether the
   LTS moves.
2. **The real state of latency**: there is a lot of expired information. The native code cache is from
   **1.9**; verify in the release notes of the version you are going to use what has changed since
   then, and the state of `--trim`/`juliac` (as of Aug 2026: **experimental**, requires
   `--experimental`, no reachable dynamic dispatch). Do not quote TTFX figures from blogs without
   reproducing them.
3. Versions of `juliaup`, `PackageCompiler.jl`, `JuliaFormatter.jl`, `Documenter.jl`, `Aqua.jl` and
   **`JET.jl`** — the last one is pre-1.0 and its compatibility is tied to the Julia version: check
   which JET release supports your Julia before putting it in CI.
4. **Vulnerability auditing**: whether `Pkg.audit` exists yet (as of Aug 2026 **no**, it remains an
   open proposal in Pkg.jl) and which scanners already consume the `JLSEC-*` advisories of
   `SecurityAdvisories.jl` in OSV format. **Gap not verified as of Aug 2026**: the effective coverage of
   the **JLL** packages (mapping the upstream binary and its CVE to the JLL name) is something I have
   not been able to quantify — treat it as **not covered** and do not claim otherwise.
5. **Gap not verified as of Aug 2026**: the state of support for **Python 3.14 in `PythonCall.jl`**
   (sources indicate failures and a lack of support, with no resolution date) and whether `PyCall.jl`
   is still the only route in that case.
6. **Licence changes or maintenance mode** of any tool you pin as a default before adopting it
   (precedents in other ecosystems: Trivy, gitleaks, Brakeman). Julia and its stdlibs are MIT, but
   verify the raw `LICENSE` of every third-party package that enters the critical path.
7. Breaking changes from Julia's official `NEWS.md` before any minor upgrade — never from third-party
   blogs without cross-checking against the source.

If the web contradicts this document, **the web wins** — flag the discrepancy.
