---
name: zig-standards
description: Zig engineering standards (staff-level). Trigger on .zig and .zon files, build.zig, build.zig.zon, zig build/zig build test/zig fetch --save, ReleaseSafe/ReleaseFast/ReleaseSmall build modes, std.heap allocators (DebugAllocator, ArenaAllocator, FixedBufferAllocator, smp_allocator), std.testing.allocator, std.Io, comptime, errdefer and error unions, zig fmt, zlint, or using zig cc / zig c++ as a C/C++ cross-compilation toolchain.
---

# Zig standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to `.zig` and `.zon` files, `build.zig`, `build.zig.zon`, `zig build`/`zig build test`/`zig fetch` invocations, build mode selection, use of `std.heap` allocators, `comptime`, *error unions*, `std.Io`, and to the use of **Zig as a C/C++ toolchain** (`zig cc`, `zig c++`, cross-compilation). It sets the criteria: which version, which allocator, which build mode goes to production, what is forbidden.

**The premise that dominates everything else**: **Zig has not reached 1.0 and there is no date**. Every minor release breaks code. Adopting Zig is accepting a **recurring migration cost** as a permanent line in the maintenance budget, not as a one-off incident (§7).

**Not applicable**: see `nim-standards` (the other compiled niche with **configurable GC and heavy metaprogramming**: if the project wants macros and tunable garbage collection, it is not Zig), `crystal-standards` (compiled niche with **GC and Ruby-like ergonomics**: scripting productivity with types, not memory control) — the boundary between the three **is not performance, it is the memory model and the purpose**: here, manual and explicit control with no runtime and no GC; `rust-standards` (**the mandatory comparison and the catalog's default for new systems code**: Rust gives memory guarantees checked by the compiler, a stable language with editions, and a far larger ecosystem and hiring pool. Zig is justified over Rust by **cross-compilation and frictionless C interoperability**, by **simplicity of the mental model** and by total allocation control; it is **not** justified by "it is easier than Rust" nor for a business service with a deadline and team turnover); `c-standards` and `cpp-standards` (**the C/C++ that gets compiled is still theirs**: `-std=`, MISRA/CERT, binary hardening, ABI and FFI headers. **`zig cc` is the special case**: deciding to use Zig as a toolchain to compile C is a decision *from here*, but **the resulting C code remains subject to `c-standards`** — using `zig cc` does not exempt you from `_FORTIFY_SOURCE`, sanitizers or MISRA review); `go-standards` (the other route to dependency-free distributable binaries, with GC and a mature ecosystem: for network services it is usually the right answer before Zig); `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI image and deployment), `appsec-standards` (vulnerability classes and threat modeling), `vulnerability-management-standards` (CVE triage of the C tree that gets linked), `secrets-management-standards`, `observability-standards`, `api-design-standards`, `sql-standards`.

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Value verified as of Aug 2026 | Reason |
|---|---|---|
| Stable compiler | **0.16.0** (2026-04-14) | Latest stable on ziglang.org/download. 0.17 in development |
| Canonical origin | **Codeberg** (`codeberg.org/ziglang/zig`) | The project migrated from GitHub in Nov 2025; **the GitHub repo is a read-only mirror and its release feed is outdated** — it is not an abandoned project |
| Compiler license | **MIT (Expat)** — «The MIT License (Expat) / Copyright (c) Zig contributors» (`LICENSE`, verbatim) | No distribution friction |
| Compiler version | **Explicitly pinned per project**, mandatory | Every minor breaks; without a pin, the build is not reproducible across machines nor over time |
| Formatting | `zig fmt` (built in), CI gate | There is no style debate in Zig |
| Lint | `zlint` (optional, active releases: v0.9.1 Jul 2026) | Complement, not a substitute for `zig fmt`; it is not official: evaluate before turning it into a blocking gate |
| Package manager | The built-in one: `build.zig.zon` + `zig fetch --save` | There is no alternative; see §3 |

**Compiler pin**: set in the project's environment file (CI image, `flake.nix`, `mise.toml`, `.tool-versions` or a hash-verified download in the Makefile) **and** declare `.minimum_zig_version` in `build.zig.zon`. Verified caveat: `minimum_zig_version` is **advisory** — the compiler does not enforce it yet; it does not replace the real pin.

## 3. Structure, build and packages

- `build.zig` (build script, it is Zig code) + `build.zig.zon` (manifest). The `.zon` declares `.name` (enum literal, valid Zig identifier, ≤32 bytes), `.version` (SemVer), **`.fingerprint`** (global package identifier: generated once and **never copied from another project**), `.paths` and `.dependencies`.
- **`.paths` is normative**: only what is listed enters the hash and only that stays on disk when the package is consumed. List what is needed to compile **plus the license**; do not list `""` (root) out of laziness in published packages.
- Dependencies: **always with `zig fetch --save <url>`**, never editing the `.hash` by hand. Every dependency carries `url` + `hash`, or `path` for local ones. When changing URL **the old hash is deleted**; keeping it asserts that the same content is expected at another URL.
- `.lazy = true` for optional dependencies; `zig build --fetch` full prefetch (after it, `zig build` requires no network — use it in CI and in hermetic builds).
- 0.16 added **package download to a project-local directory** and the possibility of **overriding a package locally** (patching a broken dependency without waiting for upstream). Verify the exact path and flags against the release notes of the version in use (§8).
- Layout: `src/main.zig` (thin binary) + `src/root.zig` (library), tests next to the code. Modules by domain.
- `comptime` is the substitute for macros and generics: types are computed with normal functions that return `type`. **Criteria**: `comptime` for what the compiler must know (tables, configuration validation, type generation); **forbidden** to use it as a creative template system that nobody else can read — the penalty is compile time and unreadable error messages.
- **No hidden control flow** is a design criterion of the language, not a shortcoming: there are no exceptions, no operator overloading, no hidden memory allocation, no implicit constructors/destructors. **Any pattern that reintroduces that opacity (wrapping every error in a `catch unreachable`, hiding an allocator in a global) contradicts the reason for choosing Zig.**

## 4. Memory, errors and testing

### Allocators — the central trait
No `std` function that allocates memory does so without an explicit `Allocator` parameter. Criteria:

- **`std.heap.DebugAllocator`** — formerly `GeneralPurposeAllocator`, **renamed in 0.14.0** (the old name stayed as a deprecated alias). For development and tests: it detects leaks, double-free and use-after-free of *its own* memory. `deinit()` returns `.ok`/`.leak`.
- **`std.testing.allocator`** in every test. The runner fails the test if there is a leak: it is the de facto leak detector and **it is not optional**.
- **`ArenaAllocator`** for per-phase/per-request lifetimes: allocate without freeing individually and throw it all away with one `deinit`. It is the right answer for most application code.
- **`FixedBufferAllocator`** for bounded memory without heap (embedded, paths with no allocation failure).
- **`std.heap.smp_allocator`** for multithreaded release builds; `page_allocator` **not** for general allocation (it tracks nothing and its granularity is the page).
- Rule: the function that allocates documents **who frees**. One `deinit` for every `init`, and `defer`/`errdefer` immediately after acquisition.

### Errors
- *Error unions* (`!T`) and inferred error sets; `try` to propagate. **`errdefer` to undo what was acquired along the error path** — it is the half that gets forgotten and the one that produces the leaks.
- `catch unreachable` **forbidden** except with an invariant demonstrated in a comment; explicit `catch |e| { ... }` or propagation. Swallowing an error with `catch {}` is a review defect.
- Explicit error sets in a library's public API (`error{A,B}!T`), not inferred: the inferred one is a contract that changes without warning.

### Build modes and what each one checks — **be exact**
- `Debug` and `ReleaseSafe`: **runtime safety checks active**. They detect detectable *illegal behavior*: index out of range, `unreachable` reached, a cast that does not fit, and **integer overflow both signed and unsigned** (in Zig the overflow of *both* is illegal behavior; to wrap on purpose there are `+%`, `-%`, `*%`). Also, in Debug and ReleaseSafe **Zig writes `0xaa` into `undefined` memory** — mitigation, not detection.
- `ReleaseFast` and `ReleaseSmall`: **those checks disappear**. The same overflow becomes exploitable undefined behavior.
- **`use-after-free` is NOT detected by any compiler check, in any mode.** The compiler does not track lifetimes. What detects heap UAF is the **allocator** (`DebugAllocator`), and only for its own memory; stack UAF is not detected (it is equivalent to the halting problem) and is only mitigated by the `0xaa` pattern. **It is the hard difference against Rust and it has to be stated in any adoption evaluation.**
- **Production: `ReleaseSafe` by default.** `ReleaseFast` only with measured justification (benchmark) and with the rest of the defenses compensating (fuzzing, review, bounded input). Never `ReleaseFast` in a binary that processes untrusted input without that written justification.
- `@setRuntimeSafety(false)` is a local exception that requires a justifying comment; it is not used "to go fast".

### Testing
- `test "..."` blocks next to the code; `zig build test` as the single CI command. Cover the happy path, **edges and every error variant** (`std.testing.expectError`).
- Every parser/decoder of untrusted input: **fuzzing** with the build system's built-in fuzzer, versioned corpus. It is mandatory in Zig precisely because there are no memory guarantees.
- Run the suite in **both** modes, `Debug`/`ReleaseSafe` and the production mode: the bugs that only appear without safety are the ones that reach production.
- CI gate (everything breaks the build): `zig fmt --check .` → `zig build` → `zig build test` (with the project's compiler pin) → cross build of the supported targets.

## 5. Stack security

- **Dependencies by URL with a hash in `build.zig.zon`**: the hash is the source of truth, not the URL. Forbidden to point at `#HEAD` or at a branch; a specific commit/tag is pinned. A GitHub tarball whose generation changes invalidates the hash — prefer immutable URLs. Review every dependency as a trust decision: **`build.zig` executes arbitrary code at build time**, with the runner's permissions.
- The Zig package ecosystem **has no central registry, no advisory database and no auditing**. There is no equivalent to `cargo deny`. Operational consequence: minimum number of dependencies, `zig build --fetch` + vendoring or your own cache, and manual review of every update. Declare it in the project's risk analysis.
- **Untrusted input**: validate at the boundary before indexing or allocating; every length received from the network is bounded against an explicit maximum before `alloc`. In `ReleaseSafe` an invalid index is a panic (DoS, not RCE); in `ReleaseFast` it is memory corruption — the build mode is a security decision.
- **Arithmetic**: with untrusted input, use explicit operations (`std.math.add`/`mul`, which return an error, or `@addWithOverflow`) instead of relying on the `ReleaseSafe` panic. A production panic caused by a manipulated size is still an attacker-triggered crash.
- Secrets never in `build.zig`, `build.zig.zon` nor in the binary; env vars or a manager.
- Containers: static binary (`-Dtarget=...-linux-musl`), `scratch`/distroless image, non-root, read-only FS. Zig cross-compiles this without an external toolchain: it is one of its best operational assets.

## 6. Zig as a C/C++ toolchain

A frequent adoption reason **without writing a single line of Zig**, and a legitimate decision on its own:

- `zig cc` / `zig c++` are a Clang frontend packaged with **libc headers and sources (musl and multi-version glibc)**, in a single portable binary. They allow cross-compiling C/C++ from any host to any supported target without a sysroot or a per-platform toolchain. Real cases: cross-compilation of Uber's Go monorepo, `hermetic_cc_toolchain` for Bazel.
- Criteria: use it when the real pain is **the cross-compilation matrix**, not the quality of the C code. It brings hermeticity and reproducibility; it does **not** bring memory safety.
- **The C it compiles remains subject to `c-standards`**: warnings, sanitizers, `_FORTIFY_SOURCE`, binary hardening and static review are not relaxed by changing compiler driver.
- Verify the target glibc version: with cross-compilation Zig applies a historical default if none is specified — **pin it explicitly** according to the oldest supported target system, and verify the available range in the Zig version being used (§8).
- Trade-off: the C build is tied to Zig's breaking-change cadence. Pinning the Zig version is just as mandatory here.

## 7. Sustainability and prohibitions

**Cadence and migration cost.** Without 1.0 and without a date for it: 0.16 (Apr 2026) rewrote all I/O around `std.Io` (everything that blocks or introduces non-determinism is passed through an `io` parameter), after 0.15 had broken `Writer`/`Reader`. It is announced that **0.17 breaks the build system of practically every project**. Realistic planning: **one migration per release**, budgeted, with the previous version frozen until it is completed. `zig build --fork` (patching a broken dependency locally) exists precisely because ecosystem breakage is the normal operating mode.

**Project health.** Zig Software Foundation, 501(c)(3), small team around Andrew Kelley; revenue ~$671k and expenses ~$523k in fiscal year 2024 (Form 990), with the 2025 report itself admitting that the recurring revenue level did not allow renewing all the team's contracts. Committed donation from Mitchell Hashimoto of $400k spread over two years (2026). Reading: **a live and funded project, but with a high bus factor and dependent on patronage**. It is a data point that goes into the adoption decision, not a footnote.

**FORBIDDEN** (exception with written justification):
- ❌ Using Zig without **pinning the compiler version** per project; assuming that `latest` will work tomorrow.
- ❌ `ReleaseFast` in production **without a benchmark justifying it**, and never in a binary that parses untrusted input without documented compensating defenses.
- ❌ Assuming that `ReleaseSafe` protects against use-after-free or dangling pointers. **It does not.**
- ❌ `catch unreachable`, `catch {}` or `orelse unreachable` as error handling; `unreachable` reachable by external input.
- ❌ Losing the `errdefer` that reverts a partial acquisition; `init` without a corresponding `deinit`.
- ❌ Hiding the `Allocator` in a global variable or in a singleton: it breaks the central trait of the language and makes the code untestable.
- ❌ Dependencies pointing at `#HEAD`/a branch, or editing `.hash` by hand instead of `zig fetch --save`.
- ❌ Tests without `std.testing.allocator`; a suite that only runs in one build mode.
- ❌ `@setRuntimeSafety(false)` or `@ptrCast`/`@alignCast` without a comment demonstrating the invariant.
- ❌ `comptime` as an unreadable template system; public API with inferred error sets.
- ❌ **Choosing Zig when**: the team turns over, the deadline is fixed, memory safety is a regulatory requirement, you need an ecosystem (HTTP, crypto, DB drivers, ORM) already solved and audited, or you hire on the open market. In those cases the answer is **Rust** (new systems with guarantees) or **Go** (network services and distributable binaries). Zig is defensible for: a C/C++ cross-compilation toolchain, embedded/bare-metal systems with total allocation control, interoperating with an existing C codebase, or a small, stable and motivated team that accepts the per-release migration cost.
- ❌ Introducing Zig into a critical component "to try it out" without first agreeing who pays for next year's migration.

## 8. Mandatory web verification

1. **Current stable and release notes**: https://ziglang.org/download/ and https://ziglang.org/news/ — **not** the GitHub release feed: the GitHub repo is a read-only mirror since Nov 2025 and it lags. Canonical origin: https://codeberg.org/ziglang/zig.
2. **Breaking changes of the target version**: full release notes for that version (`ziglang.org/download/<v>/release-notes.html`) and the devlog (`ziglang.org/devlog/`) before planning any migration.
3. **Exact `std` names**: they have changed and will keep changing (`GeneralPurposeAllocator`→`DebugAllocator` in 0.14; `std.Io` in 0.16). Verify against the **documentation of the pinned version**, never against tutorials.
4. **`build.zig.zon` format** and `zig fetch`/`zig build` flags of the specific version: `doc/build.zig.zon.md` from the repo at the corresponding tag.
5. **Status of the third-party libraries** you are going to use: check that they already support the pinned version — in Zig the ecosystem's lag after each release is the norm.
6. **glibc version range and targets** of `zig cc` in the version being used (`zig targets`, `zig libc`), and the license of any library that gets vendored.
7. **ZSF health**: annual financial report and devlog (`ziglang.org/news/`) before basing a multi-year adoption decision on it.

**Declared gaps, not verified as of Aug 2026**: the exact path and name of the project-local package directory introduced in 0.16 and the local *override* flags **not verified** against the official 0.16 documentation (only against the release notes headline); the exact scope of the build system breakage announced for 0.17 **not verified** (0.17 not published); the long-term maintenance status of `zlint` (not official) **not verified** beyond its release cadence.

If the web contradicts this document, **the web wins** — flag the discrepancy.
