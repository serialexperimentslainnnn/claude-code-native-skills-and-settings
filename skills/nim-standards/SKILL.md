---
name: nim-standards
description: Nim engineering standards (staff-level). Trigger on .nim, .nims and .nimble files, nim.cfg, config.nims, nimble.lock, nimble install/build/lock, atlas, the --mm:orc/arc/refc/none memory-management switches, --styleCheck, --threads, nim c / nim cpp / nim js backends, macros and templates with macros/typetraits, staticExec and gorge at compile time, unittest and testament, nph or nimpretty formatting, or importc/dynlib FFI to C.
---

# Nim standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to `.nim`, `.nims`, `.nimble`, `nim.cfg`, `config.nims`, `nimble.lock` files; to the choice of memory manager (`--mm:`), of backend (`nim c`/`nim cpp`/`nim js`), to the use of macros and `template`, to the C FFI (`importc`, `dynlib`, `header`), and to compile-time execution (`static:`, `staticExec`/`gorge`). It sets the criteria: which `--mm`, which backend, when NOT to write a macro, what is forbidden.

**Not applicable**: see `zig-standards` (the compiled niche of **manual and explicit control, with no runtime and no GC**: if the requirement is having no collector, it is not Nim), `crystal-standards` (compiled niche with **GC and Ruby-like ergonomics**: Ruby syntax and global inference as opposed to the metaprogramming and the configurable GC here) — the boundary between the three **is not performance, it is the memory model and the purpose**: here, **compile-time configurable GC (ORC/ARC/refc/none) and AST metaprogramming as the core value**; `rust-standards` (**the mandatory comparison and the catalog's default for new systems code**: Rust gives compiler-checked guarantees, language stability with editions, and an incomparably larger ecosystem and hiring pool. Nim is justified over Rust by **writing speed and metaprogramming**, by small binaries that compile to C for rare platforms, and by ceremony-free C FFI; it is **not** justified by performance or by memory safety — Nim with `--mm:arc/orc` does not prevent use-after-free or data races); `c-standards` and `cpp-standards` (**the C/C++ side of the FFI and of the backend is theirs**: headers, ABI, lifecycle of what is handed over, binary hardening and the C compiler choice — Nim generates C and **that C is compiled with the toolchain `c-standards` sets**; here only `importc`/`exportc`/`dynlib` and the invariants on the Nim side); `go-standards` (the other route to distributable binaries with a GC and a mature ecosystem: for network services it is usually the right answer before Nim); `cicd-standards`, `kubernetes-standards`, `appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`, `observability-standards`, `api-design-standards`, `sql-standards`.

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Value verified as of Aug 2026 | Reason |
|---|---|---|
| Stable compiler | **2.2.10** (2026-04-24) | Latest published on nim-lang.org/blog.html. The 2.0 line is in maintenance (last one 2.0.16, Apr 2025) |
| Compiler licence | **MIT** — «Nim -- a Compiler for Nim. https://nim-lang.org/ / Copyright (C) 2006-2026 Andreas Rumpf. All rights reserved.» (`copying.txt`, verbatim) | No friction |
| Memory manager | **`--mm:orc`** unless justified otherwise | Default since Nim 2.0 and the only one that supports the stdlib's `async` (see §3) |
| Package manager | **nimble** (shipped with the compiler) + **`nimble.lock` committed** | It is the ecosystem's real registry. `atlas` is a *cloning* alternative with git-commit pinning, not the default |
| Formatting | **nph** (`nph --check` as a gate) — MIT, «Copyright (C) 2023 Jacek Sieka. All rights reserved.» (`copying.txt`, verbatim); active releases (v0.7.0, Feb 2026) | It formats the AST, not tokens: consistent black/gofmt-style output. `nimpretty` (official) only makes local adjustments |
| Style lint | `--styleCheck:usages` as a minimum; `:error` in your own code | See §3, it is the quirk that does the most damage |
| Tests | `std/unittest` in the project; `testament` for compiler/large-library suites | |

**Mandatory pin of the Nim version**: it is declared in the `.nimble` (`requires "nim >= x.y.z"`) **and** pinned in `nimble.lock`, which records the Nim version to use. Verified caveat: Nim automatically adds everything in `~/.nimble/pkgs2` to the build *path* — **the lock file alone does not give you a reproducible build**; in CI and in images you start from a clean `~/.nimble` or from a container with only the dependencies in the lock.

## 3. Structural decisions

### The memory manager is *the* decision (`--mm:`)
It is chosen once, at the start, and it constrains libraries, concurrency and determinism. It is written into `config.nims`/`nim.cfg`, never left to the machine's implicit default.

- **`--mm:orc`** — the default and the default recommendation. ARC (reference counting with move optimisation, no *stop-the-world*, no atomic instructions in RC operations) **plus a cycle collector** by *trial deletion*. It is what you should use absent proof to the contrary.
- **`--mm:arc`** — ARC without a cycle collector: less machine code, deterministic freeing. Valid when the code **demonstrably** creates no cycles (annotate `acyclic`), typically embedded or size-constrained. **Verified caveat**: the stdlib's default `async` implementation **creates cycles and leaks memory with `--mm:arc`** — if there is `async`, it is `orc`.
- **`--mm:refc`** — the classic pre-Nim 2 GC (deferred counting + mark&sweep as a fallback, per-thread heaps). Only for legacy code that did not migrate; not for a new project.
- **`--mm:none`** — no management: memory is never freed. The documentation itself recommends `--mm:arc` instead. Legitimate use: short-lived *one-shot* processes, and little else.
- **Real time / bounded latency**: ARC/ORC give reference-counted freeing without global pauses, but **destroying a large graph is still an unbounded cost at the point of release**. If the requirement is hard latency, it is measured, not assumed.
- **None of the modes gives memory safety**: ARC/ORC do not prevent use-after-free with raw pointers, nor data races between threads. Say so explicitly in any comparison with Rust.

### Partial identifier insensitivity — the trap that has to be governed
Nim treats two identifiers as equal according to this algorithm (manual, verbatim): `a[0] == b[0] and a.replace("_", "").toLowerAscii == b.replace("_", "").toLowerAscii`. That is: **only the first letter distinguishes case; the rest is compared case-insensitively and underscores are ignored**. `myVar`, `my_var` and `myvar` are **the same** symbol.

- Criteria: **`--styleCheck:error` in your own code** (it prevents using one identifier in two different forms), with `--styleCheck:usages` as an intermediate step. Verified caveat: parts of the stdlib have historically failed under `--styleCheck:error`, even just by importing them — check against the pinned version before turning it into a hard gate; if it fails, `usages` + `nph` as the gate.
- **FFI**: this is where it really bites. C libraries with `foo_exp2` and `foo_exp_2` collide in Nim. On collision, explicit `importc` with the exact C name; never trust automatic name mapping.
- A single project convention (`camelCase` for procs/vars, `PascalCase` for types) enforced by `nph` — style is decided by the tool, not by the reviewer.

### Macros and metaprogramming — the differentiating value and the debt
Nim exposes the AST at compile time; it is the main reason a team picks Nim. It is also the main reason its code turns out impenetrable three years later. **Mandatory ladder: use the lowest rung that solves the problem.**
1. Generics and `concept`s. 2. `template` (simple substitution, debuggable). 3. `macro` — **last resort**.

**Do NOT write a macro when**: a generic or `template` covers it; it saves keystrokes but does not eliminate a possible error; it produces an API you cannot read without running `expandMacros`; or only its author understands it. **If one is written**: dedicated tests over the generated code, `expandMacros` documented in the module itself, explicit error messages (`error()` on the right node — a macro that fails with an unreadable compiler error is worse than the repeated code) and a named owner.

### Backends — what you lose in each one
- **`nim c` (C)**: the supported path. Everything works; the binary depends on the host's C toolchain (see `c-standards`).
- **`nim cpp` (C++)**: needed to interoperate with C++ libraries. It changes exception and destructor semantics at the boundary; the Nim library ecosystem is tested on C, not on C++ — assume some will break.
- **`nim js` (JavaScript)**: a real subset. There are no threads, no C FFI, the stdlib is only partially available and 64-bit integers and performance do not behave the same. Valid for sharing domain logic between server and browser; **not** for assuming "the same code runs in both places".
- The backend is pinned in `config.nims` and **the test suite runs on every backend the project declares it supports**. An untested backend is not supported.

### Concurrency
- `--threads` is **on by default since Nim 2.0**. Verified caveat (community reports, Aug 2025): that activation is associated with noticeable performance penalties and with multithreaded async code being slower than single-threaded, with `-d:useMalloc` as the usual mitigation. **Measure in your own project**; do not accept either the default or the workaround without data.
- `async`/`await` is implemented **in a library through macros**, not in the language: `std/asyncdispatch` and `chronos` coexist with incompatible APIs, and a library forces you to pick a side. **Criteria: pick one per project and declare it**; in applications that already depend on the Status stack, `chronos`. Verify which async backend each dependency uses before adding it: mixing them is Nim's characteristic failure mode.
- The stdlib `threadpool`'s `spawn` is a dead end for new code; the space is fragmented (taskpools, malebolgia, weave, `nim-lang/threading`). None is an ecosystem default: pick one, isolate it behind your own interface and document the decision.

## 4. Quality and testing

- **CI gate, in order of cost**: `nph --check .` → `nim check` of every target → `--styleCheck` at the chosen rung → `nimble test` (unittest) on **every** declared `--mm` and backend → release build.
- `std/unittest` (`suite`/`test`/`check`) for the project. `testament` for large libraries or when you need *spec tests* with expected output and a target matrix.
- Mandatory coverage of **edges and errors**: exceptions the API declares, empty/boundary inputs, and behaviour under the production `--mm`.
- Compile the suite **also with `-d:release`** (or `-d:danger` only if that is what gets deployed): Nim disables checks in release and the bugs that only show up there are the ones that reach production.
- Exceptions: use `{.raises: [].}` / `{.raises: [ValueError].}` in the public API to make the error contract compiler-verifiable. It is Nim's most underused tool and the one that pays off most in review.
- `-d:danger` disables **all** runtime checks (ranges, indices, overflow). **It is never the production default**; only with a benchmark that justifies it and never in binaries that process untrusted input.

## 5. Stack security

- **`staticExec` / `gorge` execute arbitrary shell commands during compilation** (`staticExec(command: string; input = ""; cache = ""): string`), just as `static:` can execute Nim code at compile time. **This is Nim's characteristic supply-chain risk**: installing and compiling a dependency amounts to executing its code with the permissions of the CI runner or of the developer. Mandatory operational consequences:
  - `nimble install` and `nim c` of untrusted code **only in an ephemeral container with no credentials, no egress network and no access to the SSH agent**. Never on a developer machine with secrets or on a runner with a deployment token.
  - Review `staticExec`/`gorge`/`static:` in the diff of every dependency update; `grep` for those symbols as an automated control in CI.
  - `config.nims` and `.nimble` files **are executable code**: treat them as such in review.
- **Package ecosystem**: the registry is a `packages.json` with names pointing at git repos. **There is no advisory database, no signing, no auditing and no abandonment process.** There is no equivalent to `cargo deny`/`pip-audit`. Consequence: minimum number of dependencies, `nimble.lock` committed, manual review of every bump and explicit assessment of each dependency's bus factor. Declare it in the risk analysis.
- **Untrusted input**: validate at the boundary; with `-d:danger` index and range checks disappear, so the release-flags decision is a security decision. Arithmetic: check the bounds explicitly instead of relying on `-d:release`'s overflow check.
- **FFI**: `importc` without properly declaring ownership is the main source of corruption. Document who frees each pointer that crosses; wrap the C API in a Nim type with `destroy=`/`=destroy` instead of exposing raw pointers.
- Secrets never in `.nimble`, `config.nims` or in the binary. SQL only parameterised (`db_connector`); interpolating into the query is forbidden.

## 6. Performance and operability

- The binary is compiled C: the standard hardening and observability of a native artifact apply (see `c-standards` and `observability-standards`). Static compilation against musl for `scratch` images.
- Measure before optimising: `--profiler:on`/`nimprof`, or perf/valgrind on the binary. Assumptions about the cost of ORC versus ARC are checked with data from your own *workload*.
- Explicit timeouts in every network client; orderly shutdown that closes the async *dispatcher* and drains tasks before exiting.

## 7. Long-term sustainability and prohibitions

**Cadence and compatibility.** Nim 2.0 (2023) was the real cutover: it changed the default to `--mm:orc` and turned `--threads` on by default — migrating from 1.x **is not a version bump**, it is a project. Within the 2.x line compatibility has been good and the cadence is patches every few months (2.2.2 Feb 2025 → 2.2.4 Apr 2025 → 2.2.6 Oct 2025 → 2.2.8 Feb 2026 → 2.2.10 Apr 2026). Practical policy: follow the latest of the 2.2 line and review the changelog on every bump; the 2.0 line only for frozen code.

**Honesty about the project and the community.** Nim is a language with a **very high bus factor**: the design and much of the compiler revolve around Andreas Rumpf (Araq), with a small team and no corporate backing or foundation comparable to other languages. The community is an order of magnitude smaller than Go/Rust; the documentation of the moving areas (concurrency, async) **lags behind the code** and much of the operational knowledge lives in forum threads, not in the docs. Consequences that go written into the adoption decision, not into a footnote: hiring Nim on the open market is unrealistic, every relevant dependency may have a single maintainer, and the support cost is borne by the team.

**FORBIDDEN** (exception with written justification):
- ❌ Leaving `--mm` at the implicit default or changing it mid-project without re-testing everything; `--mm:arc` with the stdlib's `async` (verified leak); `--mm:refc` in a new project; `--mm:none` in a long-lived process.
- ❌ `-d:danger` in production without a benchmark that justifies it, and **never** in binaries that process untrusted input.
- ❌ `nimble install` / `nim c -r` of unaudited code outside an ephemeral container and without credentials.
- ❌ Adding a dependency without reviewing its `staticExec`/`gorge`/`static:` or its bus factor; `nimble.lock` outside version control.
- ❌ Writing a `macro` where generics or a `template` suffice; a macro without tests of the generated code, without its own error messages and without a named owner.
- ❌ Relying on partial identifier insensitivity as a "convenience": a single convention + `nph` + `--styleCheck`. No symbol written in two forms in the same repo.
- ❌ Mixing `std/asyncdispatch` and `chronos` in the same dependency tree.
- ❌ Declaring support for a backend (`cpp`, `js`) that has no CI compiling and testing it.
- ❌ A public API without `{.raises.}` in libraries; exposing raw FFI pointers without a wrapper type that manages the lifetime.
- ❌ **Choosing Nim when**: the team rotates or you have to hire, memory safety is a regulatory requirement, you need a mature and audited ecosystem (crypto, drivers, ORM, cloud SDK), or the project will outlive its original authors. In those cases the answer is **Go** (services, distributable binaries, hiring) or **Rust** (compiler guarantees, systems). Nim is defensible for: an internal tool or CLI of a small, stable team, code that needs heavy metaprogramming with native performance, exotic targets reachable via C, and prototypes where writing speed rules.

## 8. Mandatory web verification

1. **Current stable and changelog**: https://nim-lang.org/blog.html and the release notes of the specific version; feed https://github.com/nim-lang/Nim/releases.atom (not `api.github.com`: it returns 403 unauthenticated).
2. **Default and semantics of `--mm`** for the pinned version: https://nim-lang.org/docs/mm.html — verify in the docs of *that* version, not in articles.
3. **State of concurrency and of `async`**: the official forum (forum.nim-lang.org) as well as the docs; it is the area with the largest gap between code and documentation. Verify which async backend each dependency uses.
4. **Real state of `nimble` vs `atlas`** and of the `nimble.lock` format in the version in use; and whether `--styleCheck:error` compiles with that version's stdlib.
5. **Licences and maintenance** of every dependency (raw `LICENSE` in the repo) and of the tools pinned here; check the real commit cadence before depending on a library with a single maintainer.
6. **Project health**: the latest published community survey and NimConf/blog activity before basing a multi-year adoption on it.

**Gaps not verified as of Aug 2026**: whether a Nim community survey later than the 2024 one exists is **not verified** (the blog does not list it); the performance penalty associated with `--threads:on` by default comes from **community reports of Aug 2025, not from an official or first-hand measurement** — treat it as a hypothesis to measure, not as data; whether `--styleCheck:error` still fails with the stdlib in 2.2.10 specifically is **not verified** (the failure is documented as a historical problem); the current official position of `atlas` versus `nimble` is **not verified** — there is no official statement designating one as the successor.

If the web contradicts this document, **the web wins** — flag the discrepancy.
