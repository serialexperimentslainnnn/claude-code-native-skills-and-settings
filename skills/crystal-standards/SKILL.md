---
name: crystal-standards
description: Crystal engineering standards (staff-level). Trigger on .cr files, shard.yml, shard.lock, shards install/update/build/--frozen, crystal build/run/spec, crystal tool format, ameba.yml, spec/*_spec.cr, Fiber::ExecutionContext and spawn, -Dpreview_mt or --threads build flags, nilable unions and .not_nil!, macro/{% %} metaprogramming, or the Lucky, Amber and Kemal web frameworks.
---

# Crystal standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to `.cr` files, `shard.yml`, `shard.lock`, `crystal build`/`run`/`spec`/`tool format` invocations, `shards`, `ameba.yml`, specs in `spec/`, execution contexts and fibers, macros, and to the Lucky/Amber/Kemal web frameworks. It sets the criteria: what you gain, what it costs and when the right answer is **not to use Crystal**.

**Not applicable**: see `zig-standards` (the compiled niche of **manual and explicit control, with no runtime and no GC**), `nim-standards` (compiled niche with **configurable GC and AST metaprogramming**: if the lever you are after is choosing the memory model or writing heavy macros, it is Nim) — the boundary between the three **is not performance, it is the memory model and the purpose**: here, **non-configurable GC and Ruby-like ergonomics with static typing**; `ruby-standards` (**the critical boundary, marked**: **compatibility with Ruby is syntactic, not semantic and not library-level**. It does not run gems, there is no runtime `method_missing` or `define_method`, no dynamic monkey patching, no `eval`, and the type system changes the design. Porting Ruby to Crystal is rewriting, not migrating); `rust-standards` (**the mandatory comparison and the catalog's default for new systems code**: Crystal is justified over Rust **only** by writing productivity on a team that already thinks in Ruby; Rust wins on compiler guarantees, ecosystem maturity, stability and hiring); `go-standards` (the other route to dependency-free distributable binaries, with a far larger ecosystem and hiring pool: for a new network service with a team that does not come from Ruby, it is usually the answer); `c-standards` and `cpp-standards` (the C side of the `lib`/`fun` *bindings*, binary hardening and the native toolchain); `api-design-standards` (the HTTP contract; here only its implementation), `sql-standards`, `cicd-standards`, `kubernetes-standards`, `appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`, `observability-standards`.

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Value verified as of Aug 2026 | Reason |
|---|---|---|
| Stable compiler | **1.21.0** (2026-07-16) | Latest published on crystal-lang.org. Roughly quarterly cadence; no declared LTS |
| License | **Apache License, Version 2.0** — «Apache License / Version 2.0, January 2004 / http://www.apache.org/licenses/» (`LICENSE`, verbatim) | Permissive with a patent clause |
| Dependency manager | **shards** (`shard.yml` + `shard.lock`) | The only one; see §3 |
| Formatting | **`crystal tool format --check`** as a CI gate | Official, built in, no configuration: zero style debate |
| Lint | **ameba** — **evaluate before setting it as a gate**: latest stable v1.6.4 (Nov 2024), with v1.7.0-**dev** (Jun 2026) as the only later tag. A sign of irregular maintenance | Complement, not a substitute for the formatter |
| Tests | **`crystal spec`** (built-in `spec` framework) | No external dependency needed |
| Platforms | **Tier 1**: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux-gnu`, `x86_64-linux-musl` | See §6: Windows is **Tier 3** |

**Compiler pin** in `shard.yml` (`crystal: "~> 1.21"`) **and** in the CI/development image. Without a pin, a minor compiler bump can break the build through inference changes.

## 3. The promise and its cost

**What it gives**: syntax almost identical to Ruby, **static typing with global inference** (there are barely any annotations), compilation to a native binary via LLVM, and native-order performance. A Ruby team writes Crystal with almost no syntax curve.

**What it costs — and this is the architecture decision, not a detail**: global inference forces analyzing **the whole program on every compilation**. The semantics are redone from scratch every time, including the stdlib and all the *shards*; **there is no incremental compilation**. Direct consequence: **compilation time grows with the size of the project and is not amortized by caching**, and the language tooling (LSP) suffers the same. It is a known structural problem, discussed since 2015, not a pending bug.

**Discard criteria, explicit**:
- If the team's workflow depends on an edit→see cycle of seconds (iterative web development, fine-grained TDD), **Crystal is discarded or confined to small components**. Measure the *clean build* of a representative project before committing, not when starting out with 500 lines.
- If the project is going to exceed tens of thousands of lines with a large team, measure the compilation curve **before** it is irreversible and define an abandonment threshold.
- Real mitigations, not solutions: split into several binaries/shards with a narrow API surface, and run the specs per file in development (`crystal spec spec/foo_spec.cr`) reserving the full suite for CI.

## 4. Type system, structure and testing

### Nil as a type — the real gain over Ruby
`Nil` is a type and it takes part in unions (`String | Nil`, or `String?`). When invoking a method on a union, **the compiler requires that the method exist and type-check for every member**; since `Nil` does not respond, **Ruby's runtime `NoMethodError` becomes a compilation error**. It is the central technical argument in favour of Crystal over Ruby.

- You take advantage of it with *flow typing*: `if x` narrows the type inside the branch; `x || default`; `x.try { ... }`.
- **`.not_nil!` is an ANTIPATTERN**: it checks nothing, it **asserts** — it turns an error visible at compile time into a `NilAssertionError` at runtime, exactly what you came to avoid. Forbidden in new code except with an invariant demonstrated in a comment; if used, **always with a message** (`not_nil!("...")`) so the trace is diagnosable. Review rule: every `.not_nil!` is a question to the author.
- Careful with `try`: if the value is nil the block **is skipped silently** — it swallows logic errors just as well as it handles nil. Use `if`/`case` when the nil case requires an action.
- Annotate types in the **public API** (arguments and return of public methods, instance variables) even if inference does not require it: it documents the contract, improves the error messages and bounds the compiler's work.

### Macros
Metaprogramming at **compile time** (`macro`, `{% %}`, `{{ }}`), not at runtime: there is no dynamic `define_method` nor hot monkey patching. They serve for what in Ruby was done with metaprogramming (DSLs, serializers, repetitive code).
**Criteria**: the simplest macro that solves the problem; never a macro where a generic or a normal method is enough. Every macro carries tests of the generated code and a named owner. Direct cost: compilation time (which is already the bottleneck) and unreadable compilation errors.

### Structure and dependencies (`shards`)
- `src/`, `spec/`, `shard.yml` and `shard.lock`. **Application: `shard.lock` committed. Library: `shard.lock` in `.gitignore`** (`crystal init` already does it this way).
- Git dependencies: they are resolved by **semver tags with a `v` prefix** (`v1.2.3`). **Floating `branch:`/`commit:` forbidden in production**: `shards install` with a branch dependency can drag in unpinned changes. You pin by version, or by immutable commit if there are no releases.
- CI and deployment: **`shards install --frozen`** (fails if `shard.lock` is missing or out of sync), with `--without-development`. `--production` alone is not enough: `--frozen` is the strict flag.
- No central registry with auditing and no advisory database: there is no `cargo deny` equivalent. Every dependency is a trust and bus-factor decision; minimize the number and review every bump by hand.

### Testing and gates
- `crystal spec` (`describe`/`it`/`should`), specs in `spec/*_spec.cr`. Cover the happy path, **edges and errors** — in particular every nil branch and every declared exception.
- Run the suite **also with `--release`**: the compiler optimizes differently and the timings and the concurrency behaviour change.
- CI gate, increasing cost: `crystal tool format --check` → `shards install --frozen` → `crystal spec` → `ameba` (if adopted, see §2) → `crystal build --release` of the supported targets.
- Compilation budget as a CI metric: if the clean build exceeds the agreed threshold, it is a defect to triage, not noise.

## 5. Stack security

- **Git dependencies in `shard.yml`** is the main vector: no signed registry, no advisories, no abandonment process. Mandatory `shard.lock` committed in applications + `--frozen` in CI, `branch:` forbidden, and diff review on every update. Vendor or cache the dependencies if the project is critical.
- The stdlib **has had network-exploitable vulnerabilities**: in Apr 2026 the team received a report of *HTTP request smuggling* in `HTTP::Server`, with a post mortem published in May 2026. Operational reading: the built-in HTTP server does **not** have the review surface of nginx or of a mature stack — **put a hardened reverse proxy in front** and follow the project's advisories closely.
- Untrusted input: validate at the boundary and take advantage of the type system (constructors that return the narrow type, not raw `String`). SQL parameterized only; forbidden to interpolate into the query — Crystal's interpolation invites the error just as much as Ruby's.
- Secrets never in `shard.yml`, in the code nor in the binary; env vars or a manager.
- Binary: static compilation against musl (`x86_64-linux-musl` is Tier 1) → `scratch`/distroless image, non-root, read-only FS. It is one of Crystal's best operational assets.

## 6. Concurrency, platforms and operability

### Execution contexts and multithreading — verify per version, it has changed
Status verified in **1.21.0**: the *execution contexts* (RFC 0002) are **enabled by default**, replacing the old `-Dpreview_mt`. From the announcement, verbatim: «Execution contexts from RFC 0002 are enabled by default. The default context has parallelism 1, i.e. it is single-threaded.» and «fibers are no longer pinned to one thread. Even with parallelism 1, fibers may switch threads.»

Consequences that have to be accepted in existing code (breakages declared in the announcement itself, verbatim):
- «Fibers in parallel execution contexts can resume in a different thread.»
- «Fibers in concurrent execution contexts can switch threads on a blocking syscall.»
- «Execution contexts don't support `spawn(same_thread:)`» — in parallel contexts it **raises at runtime**.

Criteria: **parallelism is not automatic**; you opt in explicitly (sizing the default context in code, or via the threads option in the build). **Any code that assumed a fiber stays on the same thread is broken** — *thread-local* variables, pointers to thread state and C bindings with per-thread state are audited one by one before moving up to 1.21. The state of the multithreading side has been in motion for years (funded by 84codes since ~2023): **verify against the specific version, never against a tutorial**.

### Platforms
Official tiers, verbatim: **Tier 1** «guaranteed to work»; **Tier 2** «expected to work»; **Tier 3** «partially works. The Crystal codebase has support for these platforms, but there are some major limitations».
- **Tier 1**: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux-gnu`, `x86_64-linux-musl`.
- **Tier 2**: `aarch64-linux-gnu`, `aarch64-linux-musl`, `arm-linux-gnueabihf`, `i386-linux-*`, `x86_64-freebsd`, `x86_64-openbsd`.
- **Windows is Tier 3** (`x86_64-windows-msvc`, `x86_64-windows-gnu`, `aarch64-windows-msvc`, `aarch64-windows-gnu`), despite the continued work on it (OpenSSL 4.x support on MSVC in 1.21). **Criteria: do not commit a production deployment on Windows**; for development on Windows, WSL2 over a Tier 1 target. Also `aarch64-linux-*` is Tier 2: verify before assuming ARM on the server.

### Web ecosystem — activity data, not reputation
- **Kemal** (micro-framework, Sinatra style): sustained and recent cadence (v1.12.0, Jul 2026). Default option for a small HTTP service.
- **Lucky** (full-stack, extreme typing): active but with very spaced-out releases (v1.5.0 Apr 2026; v1.4.0 Jun 2025; v1.3.0 Nov 2024).
- **Amber** (full-stack, Rails style): **it went almost three years without a release** (v1.4.1 Aug 2023) and it came back in Aug 2026 with v1.5.0 «Crystal 1.21 support» and a 2.0.0-beta series. Adopt only after verifying that the reactivation holds — a repo that revives is not the same as a maintained repo.
- In all three cases, the integration surface (auth, queues, payment gateways, cloud SDKs) is **a fraction** of that of Rails/Django/Spring: count the cost of writing those bindings.

### Operability
- Observability: do not assume an OpenTelemetry SDK comparable to that of mainstream languages — **verify the real status before designing the instrumentation**; if there is none, export your own metrics and traces through the HTTP boundary.
- Explicit timeouts in every client; orderly shutdown that closes the server and drains fibers before exiting.
- The GC is a conservative Boehm-Demers-Weiser and **it is not configurable as in Nim**: there is no latency lever. If the requirement is bounded latency, Crystal is not the language.

## 7. Sustainability and prohibitions

**Cadence and compatibility.** Post-1.0 (2021) the 1.x line maintains reasonable compatibility, but every minor brings bounded and announced breakages (1.21: execution contexts by default, end of the automatic *fallback* to legacy PCRE). **There is no LTS**: you follow the latest stable, reading the changelog of every minor. Upgrading implies recompiling the whole tree and re-testing concurrency.

**Project health, with figures.** Crystal lives off two sponsors: **84codes** and **Manas.Tech**, plus Open Collective and commercial support (Crystal Compass). `crystal-lang.org/sponsors` states, verbatim as of Aug 2026, €22,000/month since 1 Apr 2018 with an all-time total of €941,000, and $5,000/month since 19 Jun 2009 with an all-time total of $1,430,000. **Those pairs do not multiply out** — 101 months at €22,000 would be ≈€2.2M, and 206 months at $5,000 ≈$1.03M — so the monthly figure is a *current* rate, not a constant one, and the totals are the reliable number. **Quote the totals, never derive a duration from the monthly rate.** Recent leadership change: Beta Ziliani left the *lead* position in Sep 2025 and Johannes Müller took it. Honest reading: **a live, funded project with a team, but with a funding concentration in two companies and a small community**. It goes into the adoption decision.

**FORBIDDEN** (exception with written justification):
- ❌ `.not_nil!` as the habitual way of handling nilables; `.not_nil!` without a message; `try` where the nil case requires an action.
- ❌ Dependencies with `branch:` or unpinned in production; `shards install` without `--frozen` in CI; `shard.lock` not committed in an application.
- ❌ Committing a production deployment on a **Tier 3** target (Windows) or assuming Tier 2 (ARM Linux) without having tested it in CI.
- ❌ Moving up to 1.21+ without auditing the code that assumed fibers pinned to a thread (`spawn(same_thread:)`, *thread-local* state, C bindings with per-thread state).
- ❌ Exposing the stdlib's `HTTP::Server` directly to the Internet without a hardened reverse proxy in front.
- ❌ Macros for what a method or a generic solves; a macro without tests of the generated code.
- ❌ Adopting Crystal **without having measured the clean compilation time of a representative project**, nor having set the threshold that triggers a review of the decision.
- ❌ Promising "we port the Ruby app to Crystal": there are no gems, no runtime metaprogramming, no `eval`. **It is a rewrite.**
- ❌ **Choosing Crystal when**: the team does not come from Ruby (the only differential advantage evaporates); you have to hire on the open market; a mature and audited ecosystem is needed; the requirement is bounded latency or Windows in production; or the project will grow a lot and the compilation cycle is critical. In those cases: **stay in Ruby** (if the bottleneck is not the CPU — it almost never is in a web app, and Ruby brings incomparable ecosystem, hiring and iteration speed), **go to Go** (network services, distributable binaries, hiring) or **to Rust** (compiler guarantees, systems). Crystal is defensible for: a Ruby team with a specific CPU-bound component, medium-sized CLIs and daemons where the native binary and the instant startup matter, and small services with a controlled dependency surface.

## 8. Mandatory web verification

1. **Current stable and changelog**: https://crystal-lang.org/ and the release blog post (`crystal-lang.org/<year>/<month>/<day>/<v>-released/`); feed https://github.com/crystal-lang/crystal/releases.atom (not `api.github.com`: 403 unauthenticated).
2. **Multithreading status** in the specific version: the release announcement + RFC 0002 and the post «Releasing Execution Contexts». It is the area that has changed the most; **never trust tutorials nor mentions of `-Dpreview_mt`**.
3. **Platform tiers**: https://crystal-lang.org/reference/syntax_and_semantics/platform_support.html — check the tier of the deployment target **before** designing, especially Windows and ARM.
4. **Security advisories** from the project (blog and the repo's security advisories) before exposing the stdlib's `HTTP::Server`.
5. **Health of every shard** you are going to use: real release cadence (the repo's Atom feed), number of maintainers, license in the raw `LICENSE`. Apply this in particular to Lucky/Amber/Kemal and to `ameba`.
6. **`shards` flags** (`--frozen`, `--production`, `--without-development`) in the version used: `crystal-lang.org/reference/<v>/man/shards/`.

**Gaps not verified as of Aug 2026**: the exact syntax for raising the parallelism of the default context (build option vs. call in code) **not verified** against the official 1.21 documentation — only against forum threads, which offered two different forms; the status of **OpenTelemetry** support in the Crystal ecosystem **not verified**; whether an **LTS policy** or support policy for old versions exists **not verified** (no declaration was found); the detail and the severity assigned to the Apr 2026 *HTTP request smuggling* **not verified** beyond the existence of the report and the post mortem.

If the web contradicts this document, **the web wins** — flag the discrepancy.
