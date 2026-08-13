---
name: webassembly-standards
description: Use when WebAssembly is the compilation target or the runtime - .wasm and .wat modules, WIT files and wit-bindgen, the Component Model and WASI (wasip1/wasip2/wasip3, WASI 0.2/0.3), Rust targets wasm32-unknown-unknown/wasm32-wasip1/wasm32-wasip2, Emscripten emcc, TinyGo -target=wasip2, GOOS=wasip1, dotnet wasm, wasm-bindgen, wasm-pack, wasm-tools, wabt (wat2wasm/wasm2wat), binaryen wasm-opt, Wasmtime, WasmEdge, Wasmer, wazero, Extism plugin hosts, runwasi or containerd-shim-spin, edge functions running Wasm, or sandbox limits, fuel/epoch metering and module size budgets.
---

# WebAssembly standards (compilation target and runtime)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**WebAssembly is not a language: it is a compilation target and an execution model.** This skill
decides **whether Wasm is the answer**, which target and which runtime, which capabilities the host
imports, which resource limits are set and how much the artifact may weigh. The source code is
governed by the language's skill.

Triggers: `.wasm`, `.wat`, `.wit` files and `wit-bindgen`, `wasm-tools`, `wasm-opt`/binaryen,
`wat2wasm`/`wasm2wat` (wabt), `wasm-bindgen`/`wasm-pack`, Rust `wasm32-*` targets, `emcc`,
`tinygo -target=wasip2`, `GOOS=wasip1`, Wasmtime/WasmEdge/Wasmer/wazero, Extism, `runwasi` /
`containerd-shim-spin` / a Wasm `RuntimeClass`, edge functions in Wasm, and any discussion of
*sandbox*, *fuel*/epoch, memory limits or module size.

**Not applicable**:

- **The source language** (**theirs**: how the code is written, its build, its tests, its lint;
  **here**: the Wasm target, the runtime, the component model, the sandbox limits and the artifact
  size): `rust-standards`, `c-standards`, `cpp-standards`, `go-standards`,
  `dotnet-standards`, `typescript-standards`, `dart-standards` (the Dart language, `pub`,
  the lints and the tests are theirs; that Flutter web compiles to WasmGC belongs here).
- `kubernetes-standards` and `container-runtime-security-standards` (**Wasm as an alternative or a
  complement to the container**: the container runtime, admission, cluster policies and
  node isolation are **theirs**; the Wasm module, its embedded host and the capabilities that host
  imports belong **here**).
- `caching-cdn-standards` (the *edge* as a platform: caching, invalidation, propagation and cost;
  here only the module that runs on it and its limits).
- `webgl-webgpu-standards` (the two cross constantly because graphics engines
  ported from C++ arrive as Wasm and texture transcoders are Wasm modules. **The
  module, its size, its runtime and its imports belong here**; **the canvas, the GPU pipeline,
  the frame budget and the fallback to WebGL2 are theirs**), `pwa-standards` (the
  *service worker* that caches and serves the module, and its update model, are theirs — a `.wasm`
  precached with the wrong strategy is an old binary served fast).
- `compilers-dsl-standards` (**emitting Wasm from a backend of your own is theirs**: grammar, IR,
  code generation and diagnostics; **here the target, the runtime, the sandbox and the artifact**).
- `appsec-standards` (methodology: threat modelling, vulnerability classes, ASVS; **here** the
  concrete sandbox, the import surface and the resource limits).
- `local-inference-standards` and `gpu-computing-standards` (if Wasm turns up because of in-browser
  inference: the model, the quantisation and the acceleration are theirs; the module and its runtime,
  here).
- Common ones: `cicd-standards` (the pipeline that runs the §4 gates), `secrets-management-standards`
  (custody and rotation of the secrets the host **decides** to pass — or **not** — to the guest),
  `vulnerability-management-standards` (triage and SLA for runtime and toolchain CVEs),
  `api-design-standards` (the network contract the module exposes or consumes; the **WIT** contract
  belongs here), `observability-standards` (telemetry pipeline; here the instrumentation of the host
  and of the module).

## 2. Default decisions

> Verify the latest version on the web before committing to it in a real project (§8).

**Decision zero — Wasm or not?** See §7: most of the time the right answer is *no*. What
follows applies once the case is justified in writing.

| Decision | Default choice | Status as of Aug-2026 | Why |
|---|---|---|---|
| Runtime embedded in a product | **Wasmtime** | v47.0.3 (2026-07-31); **Apache-2.0 WITH LLVM-exception** (the `LICENSE` literally includes `--- LLVM Exceptions to the Apache 2.0 License ----`) | The **Bytecode Alliance**'s reference runtime; it is where the Component Model and WASI land first. Foundation governance, not a company's |
| Runtime embedded in Go, without CGO | **wazero** | v1.12.0 (2026-05-29); **Apache-2.0** (raw `LICENSE`) | Written in pure Go: **zero CGO**, cross-compiles like any Go binary. If the host is Go, this wins on operability |
| Runtime for product plugins | **Extism** (over Wasmtime) | v1.30.0 (2026-07-16); **BSD-3-Clause** (`Copyright 2022 Dylibso, Inc.` + the 3 clauses, verified raw — **it is neither MIT nor Apache**, check compatibility with your licensing policy) | Host SDKs in many languages and an already-solved plugin model; it avoids reimplementing the ABI by hand |
| Runtime with an edge/AI focus | **WasmEdge** | 0.17.1 (2026-07-06); **Apache-2.0** (raw `LICENSE`, `master` branch) | A CNCF project, integrated with containerd/runwasi |
| Wasmer | Only for a specific need (WASIX, dynamic linking) | v7.2.1 (2026-07-23); the main repo's `LICENSE` is **MIT** (`Copyright (c) 2019-present Wasmer, Inc. and its affiliates.`) | **Careful**: the company monetises Registry and Wasmer Edge (services), and **WASIX is an extension of their own, not a standard** — adopting it is lock-in. Verify the licence **per crate/component**, not just the root `LICENSE` (§8) |
| Rust → browser | `wasm32-unknown-unknown` + `wasm-bindgen` / `wasm-pack` | Target **Tier 2 without host tools**; wasm-bindgen 0.2.126 | The target provides *no* system API at all: everything comes in through imports you declare |
| Rust → outside the browser | `wasm32-wasip1` (core module, broader support) or **`wasm32-wasip2`** (component) | Both **Tier 2 without host tools**. There are also `wasm32-wasip1-threads` (Tier 2), `wasm32v1-none` (Tier 2), `wasm32-unknown-emscripten` (Tier 2 with host tools), and **Tier 3**: `wasm32-wasip3`, `wasm64-unknown-unknown`, `wasm32-wali-linux-musl` | **The names changed**: `wasm32-wasi` no longer exists. **Tier 3 = no guarantee it even compiles**: `wasm32-wasip3` is not a production choice today |
| C/C++ → Wasm | **Emscripten** (`emcc`) | 6.0.5 (2026-07-28) | It is the only realistic route if you drag SDL/OpenGL/pthreads/filesystem along; it brings its own POSIX shim |
| Go → Wasm | Upstream Go `GOOS=wasip1 GOARCH=wasm` + `//go:wasmexport` for a core module; **TinyGo `-target=wasip2`** if you need a component | TinyGo 0.41.1 | The upstream Go compiler **does not produce components**; and its binaries are much larger than TinyGo's (Go embeds a full runtime + GC) |
| Interface between components | **WIT** + `wit-bindgen` | — | The contract is written in `.wit` and versioned like any API |
| Tooling | `wasm-tools` (validate/component/print), `wasm-opt` (binaryen), `wabt` | wasm-tools v1.255.0; binaryen version_131; wabt 1.0.41 | `wasm-tools validate` in CI; `wasm-opt -Oz` on release |

## 3. Execution model: what the sandbox guarantees and what it does NOT

**What it does guarantee, by design:**

- **Isolated linear memory**: the module only addresses its own memory. An out-of-range access
  is a trap, not a read of the host process. There are no pointers into the host's space.
- **Control flow integrity**: the call stack is not addressable from the module; a return address
  cannot be overwritten. *Jumps* go to validated table indices.
- **Zero system access by default**: no files, no network, no clock, no entropy, no
  environment variables, no OS calls. **Everything the module can do with the outside world is the
  functions the host imports into it.** That is *the* security control; the rest is a consequence.
- **Determinism** within Wasm 3.0's deterministic profile (useful for replay and auditing).

**What it does NOT guarantee — and this is where deployments break:**

- **It does not protect against an infinite loop.** With no metering, a hostile or buggy module
  consumes CPU until someone kills it. **Set fuel or a time-based interruption, always**: `fuel` or
  `epoch_interruption` in Wasmtime, equivalent limits in whichever runtime you use. A host that
  runs third-party code with no execution limit does not have a sandbox, it has a promise.
- **It does not protect against memory exhaustion.** Set the **maximum number of linear memory
  pages** and the stack size; a memory that grows without a ceiling is an OOM of the host process,
  and the one that dies is the host, not the guest.
- **It does not protect against malicious logic within what you have granted it.** If you import
  `open_file(path)` unbounded, it will exfiltrate files; if you import `http_fetch(url)` with no
  allowlist, you have SSRF on steroids. **The sandbox moves the trust boundary to the list of
  imports**; if that list is generous, you have isolated nothing.
- **It does not protect against bugs in the runtime itself.** Wasmtime, WasmEdge and company have had
  escape CVEs. The runtime is privileged software: it is patched with the same urgency as a
  hypervisor.
- **It does not fix the guest's memory unsafety.** An overflow in C compiled to Wasm still
  corrupts *its own* structures inside the linear memory — and in Wasm the linear memory **has no
  ASLR, no internal guard pages and no NX inside the module's heap**: a bug that natively would be
  a crash may be exploitable *inside* the module. Wasm contains the damage to the module; it does not
  eliminate it.
- **Side channels do not go away** (timing, cache). If the threat model includes hostile
  co-tenancy with secrets on the host, the Wasm sandbox is not the complete answer.

**Mandatory budget per instance** (write it down, do not leave it to the default): a fuel or
wall-clock limit, maximum linear memory, stack depth, number of concurrent instances,
a per-call timeout, and **what happens when it is exhausted** (trap → a handled domain error, never a
downed host process). One instance per request, then discarded; no reusing a stateful instance
between tenants.

## 4. Standardisation: what is a standard and what is a proposal

This is the point where the most out-of-date information circulates. As of Aug-2026:

**WebAssembly 3.0 — a live standard since 2025-09-17.** The official announcement says: *"Today, we
are happy to announce the release of Wasm 3.0 as the new 'live' standard."* It includes, verbatim
from the announcement: *64-bit address space; Multiple memories; Garbage collection; Typed
references; Tail calls; Exception handling; Relaxed vector instructions; Deterministic profile;
Custom annotation syntax; JS string builtins.* On deployment: *"Wasm 3.0 is already shipping in most
major web browsers, and support in stand-alone engines like Wasmtime is on track to completion as
well."*

- **GC / WasmGC**: **standardised in 3.0**. It is the change that matters (see §5): the engine manages
  the memory, and languages with a GC stop shipping their own.
- **Exception handling**: **standardised in 3.0** (tags, `exnref`).
- **SIMD (128-bit)**: standardised earlier; **relaxed SIMD** enters in 3.0 with an explicit
  deterministic fallback.
- **Memory64**: standardised in 3.0. **But on the web the browsers impose their own cap** — do not
  assume 16 exabytes in a browser; measure.

**What is NOT standardised, however much it is talked about** (phases from the
`WebAssembly/proposals` repo, verified):

- **Threads: Phase 4** ("Standardize the Feature"), **not** Phase 5. It did not make the Wasm 3.0
  list. Outside the browser support is uneven: `wasm32-wasip1-threads` exists in Rust as a Tier 2
  target, but **parallelism is not a property you can take for granted**.
- **Shared-Everything Threads: Phase 1.** It is an early proposal; treating it as anything close is a
  planning error.
- **Component Model: Phase 1.** Yes, **phase 1** in the CG's process, even though the Bytecode
  Alliance pushes it as a central piece and WASI is already defined on top of it. **Criterion**: the
  Component Model is a **Bytecode Alliance specification with real implementations (Wasmtime, jco,
  wit-bindgen)**, not a W3C/WebAssembly CG standard. Adopting it is a reasonable decision; selling it
  internally as "a standard" is not, and its surface is still moving.
- **Stack Switching: Phase 3.** **Wide Arithmetic: Phase 3. Custom Page Sizes: Phase 3.**
- **Memory Control: Phase 1.**

**WASI**: there are three milestones — **0.1 (Preview 1)**, **0.2 (Preview 2)** and **0.3 (Preview
3)**.

- **WASI 0.3.0 was published on 2026-06-11** and the Bytecode Alliance declares it stable: *"WASI 0.3
  has passed the WASI Subgroup vote. This is a stable release, which means programs you compile for
  it today are guaranteed to keep working in the future."* Its central change is **native async in
  the Component Model** (`stream<T>`, `future<T>`, `async func`) and the **disappearance of
  `wasi:io`**, whose functionality *"is now part of the canonical ABI, where the Component Model now
  offers these primitives natively"*.
- **Real support**: Wasmtime 45 ran the RC and **Wasmtime 46 brings it with Component Model Async
  enabled by default**; jco supports all of WASI 0.3. **But the guest toolchains (Rust, Go,
  JavaScript, Python…) were still "in progress"**. That is the operational constraint that decides
  your project, not the ratification of the spec.
- **Criterion as of Aug-2026**: **WASI 0.2 (`wasip2`) is the production target**; **WASI 0.1
  (`wasip1`)** is still the most compatible with old runtimes and remains valid for simple core
  modules; **WASI 0.3 (`wasip3`)** is adopted when **your** guest toolchain supports it —
  in Rust its target is **Tier 3**, and Tier 3 means there is not even a guarantee it compiles.

**Declared discrepancy**: the Component Model's official documentation
(`component-model.bytecodealliance.org`) was still stating as of Aug-2026 that *"The current stable
release of WASI is WASI 0.2.0, which was released on January 25, 2024"*, while the Bytecode Alliance
itself had announced WASI 0.3.0 as a stable release on 2026-06-11. The documentation lags behind the
announcement: **verify the status against the `WebAssembly/WASI` repo and Wasmtime's release notes,
not against the docs site**.

## 5. Use cases: when Wasm wins

**A. Plugins and safe extension of a product — the strongest case today.**
It is the only one where Wasm is clearly the best tool and not just an alternative: you want to run
code you **do not control** inside your process, with a strong boundary and without paying for
starting a container or a process. Wasmtime or wazero embedded, or **Extism** if you do not want to
build the ABI. Criteria: an **explicit and minimal** host surface (one function per capability, with
the parameters already bounded: not `open(path)`, but `read_config()`), one instance per invocation,
the §3 limits on all of them, and a versioned plugin contract (WIT or Extism's schema).

**B. In the browser — when it pays off against JS.**
It pays off when: (1) there is **heavy, sustained computation** —codecs, cryptography, CAD,
simulation, image/audio processing, large parsers—; (2) you want to **port an existing, proven
C/C++/Rust codebase** instead of rewriting it; (3) you need **predictable** performance (without the
warm-up and deoptimisations of the JS JIT).
**It does not pay off when**: (1) the work is **DOM manipulation** — Wasm **has no direct access to
the DOM** and every touch crosses into JS; (2) the module is small and the logic is glue: the
**download and compilation cost of the `.wasm`** eats any gain; (3) the pattern is **many short
calls** crossing the JS↔Wasm boundary — the crossing and the type conversion dominate, and you end up
slower than in plain JS. **Rule**: few and fat calls, not many and thin ones. And **measure first**:
if you do not have a benchmark of the JS version, you have no justification.

**C. Edge / serverless.**
Here the real argument is **cold start**: instantiating a Wasm module is orders of magnitude
cheaper than starting a container, which allows density and multi-tenancy at the edge. The cost
is that you are on a provider's platform with **their** set of APIs: portability limited by
the host's capabilities, not by the standard. Before committing: which subset of WASI it offers,
which CPU/memory limits it imposes, how it is debugged, and **how much it costs to leave**.

**D. WASI as an alternative to containers — be honest.**
The argument (millisecond start-up, an artifact of MB instead of hundreds, a sandbox by default,
architecture portability with no multi-arch build) is real. The maturity, not so much: the route is
`runwasi` as a containerd shim + a Kubernetes `RuntimeClass` (or SpinKube for Spin), and it works,
but **it is the ecosystem around it that is missing**: almost none of the software you already
operate has a Wasm build, thread and socket support is uneven, debugging is bad (§6) and the
integrations (agents, sidecars, service mesh, runtime security tooling) assume containers.
**Criterion**: Wasm replaces the container for **new, small, stateless, high-density** workloads;
in any other case it is a **complement** inside a cluster that remains container-based.
Migrating an existing workload to Wasm "to reduce start-up" almost never pays off.

**E. Why WasmGC changes the distribution of languages.**
Before WasmGC, a language with a garbage collector had to **compile its own GC into linear
memory** and ship it in every module: enormous artifacts, slow start-up and two collectors fighting
in the browser. With **GC standardised in Wasm 3.0**, the engine manages structs and arrays and the
language stops shipping its memory runtime — that is what makes Dart/Flutter web, Kotlin,
Java and Scala on Wasm viable. **Nuances that cannot be skipped**: WasmGC does not offer an object
system or closures, only the primitives; languages whose runtime needs more than that (**the case of
.NET is reported**, see §8) stay in linear memory; and **browser support is not uniform** —
Chromium/V8 since 119, Firefox announced stable support in 120 but it *"currently doesn't work"*
because of a known limitation, Safari supports it with a compatibility bug, and **on iOS it does not
work in any browser** because they all use WebKit. Any "web on WasmGC" plan needs a **fallback to
JS** or excludes iOS. See `dart-standards` for the Dart side of this.

## 6. Quality, size, debugging and operability

**Artifact size: a first-class metric.** In the browser it is user latency; at the
edge it is cost and density; in a plugin it is memory per instance multiplied by N.

- A CI gate with a **byte budget** that breaks the build when exceeded (`.wasm` and `.wasm.br`).
- `wasm-opt -Oz` (binaryen) on release; `wasm-strip`/`--strip-debug` for production, **keeping
  the symbols separately** to symbolise stack traces.
- Rust: `panic = "abort"`, `lto`, `opt-level = "z"`/`"s"`, `codegen-units = 1`; avoid `format!` and
  error formatting on the hot path (it drags in half of `core::fmt`).
- Upstream Go to Wasm gives large binaries by design (runtime + GC): if size matters, it is
  **TinyGo**.
- C/C++ with Emscripten: review which shims you are dragging in (filesystem, pthreads, SDL) — each
  one is paid for in bytes.
- Compress in transport (Brotli) and serve with the correct MIME type to allow streaming compilation.

**CI gates** (increasing cost):

1. `wasm-tools validate` over the generated module/component (and `wasm-tools component wit` to
   verify that the exported WIT is the expected one).
2. **WIT contract diff**: an incompatible change in a `.wit` must break the build, just like an
   incompatible change in a `.proto`.
3. **Guest** tests with its language's toolchain (governed by the language's skill).
4. **Host** tests: instantiate the real module and exercise the boundary — including **the trap case,
   the fuel exhaustion case and the guest OOM case**. If you have not proven that a plugin in an
   infinite loop is cut off cleanly, you have not tested it.
5. A size budget.
6. A comparative benchmark against the previous implementation (if Wasm replaces something, prove it
   wins).

**Debugging and observability: the weakest point, accept it before choosing Wasm.**

- **DWARF** in the `.wasm` works in the browser with the C/C++ DevTools extension and in some
  standalone runtimes; **it inflates the module enormously** — a debug build with DWARF, a release
  build without, and **archived symbols** per version to symbolise afterwards.
- **Source maps** for the web case; Flutter web on Wasm generates them with `--source-maps`.
- **Profiling**: irregular support. Wasmtime offers output for `perf`/VTune; in the browser the
  profiler attributes to Wasm functions if you keep the names (`name` section). **Without names, a
  production profile is unreadable**: decide whether you keep the `name` section (weight vs.
  diagnostics) and be aware that it also makes reversing your module easier.
- **Logs and traces**: the guest has no output of its own — **the host imports it**. Instrument in
  the host: duration per invocation, fuel consumed, traps by type, peak memory, input/output
  size. Correlate with the host's trace by propagating the context **explicitly** across the
  boundary (there is no ambient context that crosses).
- Capacity metrics: concurrent instances, instantiation time, compiled-module cache hits
  (**precompile and cache the module**: compiling on every request is the classic host performance
  mistake).

## 7. Sustainability and prohibitions

**Cadence**

- The **runtime is privileged software**: security patches in <72 h, just like a hypervisor.
  Wasmtime publishes patches on several branches at once (on 2026-07-31 47.0.3, 46.0.2, 36.0.13 and
  24.0.12 came out simultaneously) — stay on a supported branch and keep moving up.
- The proposals move: review the phase status and WASI **every quarter**, not once.
- Pin the toolchain (compiler version, `wasm-opt`, `wasm-tools`, `wit-bindgen`) in the repo and in the
  CI image; a different `wasm-opt` generating a different binary is a reproducibility failure.
- **Record an ADR with the reason for having chosen Wasm and with the exit condition.** If the reason
  stops being true, it is reverted; a platform decision with no reversion criterion is a trap.

**When Wasm is NOT the answer** (the most valuable section: there is a lot of enthusiasm and few
cases where it genuinely wins)

- ❌ **As an accelerator for a normal web app.** If the work is DOM, forms, network and state, Wasm
  has nothing to offer: it adds a toolchain, size and a boundary crossing that costs.
- ❌ **For code you write yourself and trust.** The sandbox is valuable against **someone else's
  code**. If the code is yours and runs in your process, isolating it with Wasm is cost with no
  benefit: use a library.
- ❌ **To "make portable" what you already package in a container** and works. The Wasm artifact gives
  you nothing the container did not, and you lose the whole operational ecosystem.
- ❌ **For stateful workloads, heavy I/O, many sockets or a strong OS dependency.** Support
  is uneven, and where it exists it is usually slower than native.
- ❌ **As a substitute for a hypervisor or for gVisor/Kata against a determined attacker with shared
  secrets on the host.** It is a process sandbox, not a machine boundary (see
  `container-runtime-security-standards`).
- ❌ **As "the replacement for Docker".** It is not, and planning on that premise is guaranteed debt.
- ❌ **When nobody on the team knows how to debug a trap in production.** Debugging is the weak
  link (§6); if you have no plan for that, do not put Wasm in the critical path.
- ❌ **When your source language does not yet support the target you need well** (see the "in
  progress" state of the guest toolchains for WASI 0.3, and Tier 3 for `wasm32-wasip3`).

**LIST OF PROHIBITIONS** (they block review)

- ❌ FORBIDDEN to run third-party code **without a fuel/epoch limit and without a memory limit**.
- ❌ FORBIDDEN to import a generic capability into the guest (`open`, `exec`, `fetch(url)` with no
  allowlist, host FS access without a bounded preopen). One import = one bounded operation.
- ❌ Preopening `/` or the host's working directory "to keep it simple"; inheriting the host's
  environment variables wholesale (the secrets are in there).
- ❌ Reusing a stateful instance across invocations from **different tenants**.
- ❌ Letting a guest trap take down the host process, or silently ignoring it. Trap = a domain error,
  logged and returned.
- ❌ Loading a third-party `.wasm` **by URL or by a mutable tag**. It is pinned by **digest** (see the
  next section).
- ❌ Compiling the module on every request instead of caching the compiled module.
- ❌ Publishing the release module **with full DWARF** or **with the `name` section** without having
  decided it consciously (weight and reversing surface).
- ❌ Treating the **Component Model** or **shared-everything threads** as consolidated standards: they
  are **Phase 1**.
- ❌ Writing against `wasm32-wasi` (a removed target) or assuming it exists.
- ❌ Adopting a runtime's proprietary extensions (e.g. WASIX) without recording the lock-in in an ADR.
- ❌ Assuming thread, socket or 64-bit support without checking it in **your** runtime and **your**
  target browser.
- ❌ Choosing Wasm without a comparative benchmark against the alternative it replaces.
- ❌ Stating versions, targets or proposal statuses from memory instead of against the official
  source.

**Stack security — supply chain and trust boundary**

- **The sandbox is not a trust boundary if the host imports capabilities without judgement.** The
  security audit of a Wasm system is the **audit of the list of imports**: every function the host
  exposes, what the worst possible guest can do with it, and which limits bound it.
  Write it down; review it in every PR that touches it.
- **Least privilege in the imports**: specific capabilities already parameterised by the host,
  not general primitives. Directory preopens bounded to the minimum. No network except an allowlist
  of destinations, enforced **in the host** (a hostile module with free egress is SSRF with
  persistence).
- **Secrets**: they do not go into the module. Not into the linear memory at instantiation, nor
  through inherited environment variables. The host performs the operation that needs the secret and
  returns the result. A `.wasm` is as inspectable as any binary, and easier to decompile
  (`wasm2wat`) — see `secrets-management-standards`.
- **Input validation at the boundary, in both directions**: the host validates what it hands to the
  guest **and what it receives from it** (lengths, pointers into linear memory, indices, UTF-8). A
  pointer/length returned by the guest is **untrusted input**: checking the range against the
  memory's size is mandatory, and omitting it is the classic host vulnerability.
- **Supply chain of third-party modules**: signing and provenance (cosign, attestations,
  distribution as an OCI artifact) **are necessary but not sufficient**. A precedent from the
  catalogue: **valid SLSA L3 attestations were issued for malicious packages** — an attestation
  proves *where and how* something was built, **not that it is benign**. The control that does cut is
  **pinning by immutable digest** (`sha256:…`), replicating the artifact in your registry and
  promoting the **same digest** between environments. A mutable tag = no control at all.
- The runtime is patched as a privileged component; follow its advisories (RustSec/GitHub Advisories
  for Wasmtime and wazero, WasmEdge/Wasmer releases).
- General threat methodology: `appsec-standards`. Node isolation and cluster admission:
  `container-runtime-security-standards` and `kubernetes-standards`.

## 8. Mandatory web verification

Before committing to a version, target, runtime or feature status, **verify online**:

1. **Proposal phases**: `github.com/WebAssembly/proposals` — it is the only source that settles what
   is standardised. Check in particular whether **Threads** moved from Phase 4 to 5 and whether the
   **Component Model** has left Phase 1; both change the criteria of §4.
2. **Wasm 3.0 and engine support**: `webassembly.org/news/2025-09-17-wasm-3.0/` and the table at
   `webassembly.org/features/` (**it is loaded by JS**: it may not be readable by a simple fetch —
   use the `WebAssembly/website` repo or the MDN/caniuse matrix).
3. **WASI**: the releases of `github.com/WebAssembly/WASI` and `bytecodealliance.org/articles/WASI-0.3`.
   Check **the support in your guest toolchain**, which as of Aug-2026 lagged behind the spec, and
   **do not trust `component-model.bytecodealliance.org` for the version status** (declared
   discrepancy in §4).
4. **Rust targets and their tier**: `doc.rust-lang.org/rustc/platform-support.html`. The names have
   changed (`wasm32-wasi` → `wasm32-wasip1`) and `wasm32-wasip3` is **Tier 3**.
5. **Runtime versions and licences**, from the Atom feeds (`.../releases.atom`) and the **raw**
   `LICENSE` (`raw.githubusercontent.com`), never from a third-party comparison table: Wasmtime,
   WasmEdge, Wasmer, wazero, Extism. **For Wasmer verify the licence per crate/component and the
   status of its commercial services** — the root `LICENSE` being MIT says nothing about the
   subcomponents nor about Registry/Edge.
6. **Runtime and toolchain CVEs** before pinning a version: RustSec, GitHub Advisories, osv.dev.
7. **Wasm on Kubernetes**: the status of `runwasi`, `containerd-shim-*` and SpinKube (versions,
   maturity, compatibility with the cluster's containerd/K8s version).

**Declared gaps, not verified as of Aug-2026** (marked on purpose, left unfilled):

- **WasmGC browser support with current figures**: the claim in §5 comes from Flutter's
  documentation (Chromium ≥119; Firefox 120 announced but *"currently doesn't work"*;
  Safari with a compatibility bug; iOS no). **Not verified against caniuse/MDN nor against the
  original bugs** (bugzilla 1788206, webkit 267291) in this drafting: check it before excluding or
  including a platform.
- **"WasmGC does not cover the needs of the .NET runtime"**: it comes from a secondary source, **not
  confirmed against official .NET documentation**. Verify in Microsoft's docs before setting a
  criterion for .NET.
- **The governance and funding status of the Bytecode Alliance** (current members, projects under
  its umbrella) not verified in this drafting beyond the fact that Wasmtime is its reference runtime.
- **Relative performance of Wasm vs JS vs native**: deliberately without figures. It depends on the
  workload, the engine and the version; **it is measured in your case**, not quoted.

If the web contradicts this document, **the web wins** — flag the discrepancy.
