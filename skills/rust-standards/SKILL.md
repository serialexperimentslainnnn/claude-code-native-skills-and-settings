---
name: rust-standards
description: Rust engineering standards (staff-level). Trigger on any Rust work - files with .rs extension, Cargo.toml/Cargo.lock, workspace manifests, clippy/rustfmt config, deny.toml, or crates/frameworks like tokio, axum, actix-web, serde, thiserror, anyhow, sqlx. Apply when writing, reviewing, refactoring, or configuring CI for Rust code.
---

# Rust standards

## 1. Scope and triggers

Applies to all Rust work: `.rs` files, `Cargo.toml`/`Cargo.lock`, `rustfmt.toml`, `clippy.toml`, `deny.toml`, `rust-toolchain.toml`, CI pipelines that build/test Rust. Covers backend services, CLIs, libraries and multi-crate workspaces. This skill sets **criteria** (what to use, what is forbidden, what to verify); it is not a tutorial.

**Not applicable**: see `api-design-standards` (design of the HTTP/gRPC contract — here only its implementation with axum/tonic), `microservices-architecture-standards` (service decomposition, events, sagas, distributed resilience), `appsec-standards` (threat modelling and stack-agnostic vulnerability classes; here only `unsafe`, FFI and Rust's concrete sinks), `go-standards` (the other systems-language skill: Rust-vs-Go choice by workload, not by inertia), `c-standards` and `cpp-standards` (**reciprocal boundary for FFI and language choice**: the C/C++ side of the interface —headers, `extern "C"`, ABI, lifecycle of whatever is handed to the other side— is theirs; **the Rust side —`unsafe`, `bindgen`/`cbindgen`, the invariants the `unsafe` promises and `#[repr(C)]`— belongs here**. For **new** systems code, Rust is the catalogue default; C and C++ cover what already exists, what requires a specific ABI and what has a regulatory requirement —MISRA, CERT—), `haskell-fp-standards` and `ocaml-fsharp-standards` (**they share the ML lineage with Rust**: ADTs, exhaustive *pattern matching*, inference. The boundary is not "functional": it is the **memory model and the purpose** —here, control without a garbage collector and deployment as a systems binary; there, type-system expressiveness with GC—. If the discussion is *"algebraic types or inheritance?"* it belongs to none of these three in particular; if it is *"who frees this and when?"*, it belongs here), `zig-standards`, `nim-standards` and `crystal-standards` (**the three niche languages that compete with Rust and cite it as the obligatory comparison**; the boundary is not performance, it is the **memory model and maturity**: Zig, manual control without a runtime and **having never reached 1.0** —every minor version breaks—; Nim, configurable GC and metaprogramming; Crystal, GC and Ruby-like ergonomics. Rust remains the catalogue default for new systems code: choosing one of the three requires justifying ecosystem, hiring and language stability in an ADR), `ada-standards` (**the obligatory comparison when memory safety must also be *certifiable***: SPARK, its adoption levels and formal proof are theirs, and its §7 arbitrates Ada/SPARK against Rust —including the real qualification status of **Ferrocene**— with the same data used here), `data-platform-standards` (modelling, indexes and engine tuning; here only the use of sqlx/SeaORM), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI image and deployment), `observability-standards` (OTel pipeline; here only `tracing` and in-code instrumentation), `git-workflow-standards` (branching, commits and SemVer tagging; publishing to crates.io does belong to this skill), `cryptography-pki-standards` (algorithm choice and key management; here only which crypto crates to use and which are unmaintained), `assembly-standards` (`core::arch`, the intrinsics and `asm!` are a shared boundary — the criteria for **when writing assembly is justified and how it is maintained** are theirs, including ABIs and constant time; the `unsafe` around it and its invariants belong here), `webassembly-standards` (Rust is the most common source language for Wasm and the boundary is clean: **the Rust code, its build and its tests belong here**; **the compilation target, the runtime, the component model, the sandbox limits and the artifact size are theirs** — including the choice between `wasm32-unknown-unknown`, `wasm32-wasip1` and `wasm32-wasip2`, and the real support level of each target).

## 2. Default toolchain

> **Verify the latest version on the web before pinning it in a project** (releases.rs / blog.rust-lang.org). What follows is the state verified as of 2026-08-02.

- **Rust stable: 1.97.x** (1.97.1, 2026-07-16). 6-week cadence; **only the latest stable gets patches** — there is no LTS: falling behind means going without security fixes.
- **Edition: 2024** (stabilised in 1.85). Every new crate is born with `edition = "2024"`; migrate existing ones with `cargo fix --edition`. The next edition is expected ~2027.
- `rust-toolchain.toml` versioned with `channel = "1.97.1"` (or the current stable) for reproducible builds; `rust-version` (MSRV) declared in the `Cargo.toml` of libraries.
- **Core tooling**: `rustfmt` + `clippy` (official components), **cargo-deny** (subsumes cargo-audit: advisories + licences + bans + sources), `cargo-nextest` as the test runner in CI, `taiki-e/install-action` to install tooling in GitHub Actions.
- **Async runtime: tokio 1.x** (1.52.x current; LTS lines 1.47/1.51 available). There is no "tokio 2.0" despite articles claiming otherwise.
- **Web: axum 0.8** by default (tokio team, Tower, hyper). actix-web only if the team already operates it or needs its actor model.

## 3. Project structure and conventions

- **Workspace from the start** in any non-trivial project: `[workspace]` with `resolver = "3"`, crates in `crates/`, thin binaries that delegate to library crates.
- `[workspace.dependencies]` **mandatory**: every dependency version is declared once at the root and members use `dep.workspace = true`. Same with `[workspace.lints]` and `[workspace.package]` (edition, rust-version, license). Zero duplicated versions scattered around. Reference root:

```toml
[workspace]
resolver = "3"
members = ["crates/*"]

[workspace.package]
edition = "2024"
rust-version = "1.97"        # verify the current stable before pinning
license = "..."

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }   # trim features in each crate
axum = "0.8"
thiserror = "2"
anyhow = "1"

[workspace.lints.clippy]
all = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
unwrap_used = "deny"
dbg_macro = "deny"
todo = "deny"
undocumented_unsafe_blocks = "deny"

[profile.release]
lto = "thin"
codegen-units = 1
```
- `Cargo.lock` **always versioned**, in libraries too (current official recommendation).
- Modules by domain, not by technical type; no `mod.rs` — files named after the module (2018+ style). Minimal public API: `pub(crate)` by default, `pub` is a deliberate decision; `#![warn(missing_docs)]` in published libraries.
- Newtypes over primitives for IDs and units (`UserId(Uuid)`); impossible states unrepresentable (enums with data > boolean flags + Option). The type system is the first line of tests.

## 4. Quality: formatting, lint, testing

### Error handling (criteria by layer)
- **Libraries / domain crates**: typed errors with **`thiserror`** — one enum per module/operation, variants with context, `#[from]` for conversions. The caller must be able to match.
- **Binaries / applications (top layer)**: **`anyhow`** (`anyhow::Result`, `.context("reading config {path}")`) where the error is only reported, not discriminated.
- Rule: anyhow **never** in the public API of a library; thiserror in binaries only if the binary needs to distinguish variants.
- **Forbidden** `unwrap()`/`expect()` in production code unless the invariant is demonstrated with a comment (`// invariant: validated at construction`); in tests they are acceptable. `clippy::unwrap_used` enabled as warn/deny in production crates.
- Errors propagate with `?`; `let _ = fallible()` swallowing a `Result` is forbidden (`#[must_use]` exists for a reason).

### Formatting and lint (build-breaking gates)
- `cargo fmt --check` in CI; minimal `rustfmt.toml` (defaults + `imports_granularity` if the team agrees) — do not fight the formatter.
- `cargo clippy --workspace --all-targets --all-features -- -D warnings` in CI. Lints in `[workspace.lints]`: `clippy::all`, `clippy::pedantic` as warn (triaging exceptions), and as deny: `clippy::unwrap_used`, `clippy::dbg_macro`, `clippy::todo`, `clippy::undocumented_unsafe_blocks`.
- `#[allow]` always with a specific lint and a reason in a comment; never `#[allow(clippy::all)]`.

### Async (tokio)
- A single runtime: tokio. Forbidden to mix runtimes (async-std is discontinued) or to create nested runtimes.
- **Never block the executor**: synchronous I/O, CPU-bound >~100µs or `std::sync` locks held across `.await` go to `spawn_blocking` / `rayon`. Use `tokio::sync::{Mutex, RwLock}` only when the lock crosses an await; otherwise `std::sync` or `parking_lot`.
- Every spawned task has an owner: `JoinSet`/`TaskTracker` + `CancellationToken` (tokio-util) for lifecycle; forbidden fire-and-forget `tokio::spawn` whose `JoinHandle` and errors nobody observes.
- Cancellation is always possible in async: cancel-safe code in `select!`; document the cancel-safety of your own functions used in `select!`.
- Bounded channels (`mpsc::channel(n)`) by default — explicit backpressure; `unbounded` requires justification.

### Unsafe — forbidden unless documented and justified
- `#![forbid(unsafe_code)]` in every application crate and in libraries that do not need it.
- Exception only for FFI or **measured** performance: minimal block, encapsulated in a safe API, with a `// SAFETY:` that demonstrates the invariants (the `undocumented_unsafe_blocks` lint enforces it), a dedicated test and **Miri** in CI for crates with unsafe. Watch the unsafe inherited from the dependency tree with `cargo-geiger` when the risk profile demands it.

### Testing
- Unit tests next to the code (`#[cfg(test)]`), integration in `tests/`, doctests in libraries (they document and verify at the same time).
- Coverage of **edges and errors**: error variants of every API, empty/boundary inputs, future cancellation, timeouts.
- **Property testing** (`proptest`) for logic with invariants; **fuzzing** (`cargo-fuzz`) on every parser/decoder of untrusted input, corpus versioned.
- Concurrency: `tokio::test(start_paused = true)` for deterministic virtual time (no real sleeps in tests); `loom` for your own synchronisation primitives.
- Integration with real deps via `testcontainers` (Postgres, Redis...) rather than driver mocks; mock your own boundaries (traits), not the world.
- Every bugfix leaves a regression test that reproduces the bug before the fix.
- Minimum CI gate (everything breaks the build):

```
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo nextest run --workspace
cargo test --doc --workspace
cargo doc --no-deps          # RUSTDOCFLAGS="-D warnings"
cargo deny check
```

Main always green; no merging with red CI. Flaky test: fixed or deleted.

## 5. Stack security

- **Secrets**: never in code, `Cargo.toml`, logs or derived `Debug` — use `secrecy::SecretString` (redacts in Debug/Display) for credentials in config structs. Env vars or a manager (Vault/KMS).
- **SCA / supply chain**: `cargo deny check` on every PR **and scheduled** (daily) against RustSec; `cargo-vet` when human review of deps is required (high-risk profile). Starting `deny.toml` (`cargo deny init` and harden):

```toml
[advisories]
yanked = "deny"                 # unmaintained/unsound are triaged, not blindly ignored

[licenses]
allow = ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC", "Unicode-3.0"]  # allowlist, not denylist

[bans]
multiple-versions = "warn"      # raise to deny once the tree is clean
wildcards = "deny"

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```
- Remember the real threat model: `build.rs` and proc-macros **execute arbitrary code at build time** with the runner's permissions — every new dependency is a trust decision, not a free import. Minimise deps; prefer the stdlib and core-ecosystem crates (tokio/serde/tower).
- SQL only parameterised: `sqlx` (query checking) or diesel; forbidden to format input into queries. Validation at the boundaries with types (`serde` + validation in `TryFrom`/constructors, not "open" structs).
- Crypto: `ring`, `aws-lc-rs`, RustCrypto (AES-GCM, ChaCha20-Poly1305, SHA-256+, Argon2); `rustls` for TLS (not openssl unless required). Security randomness with `rand::rngs::OsRng`/`getrandom`. No home-made crypto.
- Containers: multi-stage build, release binary (`opt-level = 3`, `lto = "thin"`, `codegen-units = 1`, `panic = "abort"` in binaries if unwind is not needed), distroless/scratch image, **non-root**, read-only FS. `cargo auditable` to embed the dependency SBOM in the binary.

## 6. Performance and operability

- **Logging/tracing**: `tracing` + `tracing-subscriber` (JSON in prod) with per-request spans; OpenTelemetry (`tracing-opentelemetry`) for distributed traces and metrics. `println!`/`dbg!` forbidden in service code (clippy vetoes it).
- **Timeouts and limits at every boundary**: `reqwest`/`hyper` client with an explicit timeout (the no-timeout default is unacceptable), `tower` layers for timeout/concurrency-limit/rate-limit in axum, body limits (`DefaultBodyLimit`), bounded DB pools (`sqlx::PoolOptions`: max_connections, acquire_timeout). Retries with backoff + jitter only on idempotent operations.
- **Graceful shutdown mandatory**: `axum::serve(...).with_graceful_shutdown(SIGTERM/ctrl_c signal)`, `CancellationToken` propagated to workers, `TaskTracker::wait()` with a deadline to drain tasks, close resources in order. Without a clean shutdown there is no reliable rolling deploy.
- Separate health endpoints: trivial liveness and readiness that checks deps.
- Profile before optimising: `cargo flamegraph`, `criterion`/`divan` for comparable benchmarks; do not micro-optimise without measuring. `clone()` is not a sin until the profiler says so — clarity first, `Arc`/borrows where the data justifies it.
- Builds: `release` profile for prod always; CI cache (sccache or `Swatinem/rust-cache`) to keep pipelines <10 min.

## 7. Sustainability: upgrades and prohibitions

**Cadence**: move up stable within days of each release (6 weeks) — with no LTS, the old version gets no patches; point releases (1.x.y) immediately. Deps with Renovate/Dependabot grouped weekly; majors reviewed by hand with the changelog. New edition: migrate within the year following its stabilisation. In libraries, the declared MSRV is a contract: raising it is at least a minor bump and is recorded in the changelog.

**API stability**: strict SemVer (with `cargo-semver-checks` in the CI of published libraries); follow the Rust API Guidelines (C-*) in public crates. Deprecate with `#[deprecated(note = "...")]` and a migration window before removal.

**Conscious debt**: every shortcut leaves `// TODO(user): reason — link to issue`; no silent accidental complexity. Review TODOs in every planning cycle.

**FORBIDDEN** (requires written justification and approval to make an exception):
- `unsafe` without `// SAFETY:` + encapsulation + Miri (see §4); `unsafe` "for performance" without a benchmark that proves it.
- `unwrap()`/`expect()`/`panic!` as error handling in production; `todo!()`/`unimplemented!()` merged to main.
- `anyhow` in the public API of a library; errors as `String`/`Box<dyn Error>` in APIs that can be typed.
- Blocking the async executor (synchronous I/O or CPU-bound work in tasks); `std::sync::Mutex` held across `.await`; `block_on` inside an async context.
- Async runtimes other than tokio in the same tree; unbounded channels without justification.
- `Cargo.lock` outside VCS; deps with `git = ...` without a pinned `rev`; wildcard versions (`*`); unreviewed `default` features in heavy deps.
- Adding a dependency for what the stdlib or an already-present crate does (left-pad-ism); unmaintained crates (RUSTSEC unmaintained) — cargo-deny catches them.
- Global clippy `#[allow]`; CI without `-D warnings`; merging with red CI or flaky tests.
- MD5/SHA-1/DES/ECB, vendored openssl without reason, TLS <1.2.
- Your own procedural macros for what an existing derive or explicit code solves (compile cost + opacity).

## 8. Mandatory web verification

Before pinning versions or asserting the state of the ecosystem in a real project, **verify on the web** (not from memory):
1. Current Rust stable and edition: https://releases.rs and https://blog.rust-lang.org (endoflife.date/rust as a summary).
2. Versions of key crates (tokio and its LTS lines, axum, serde, sqlx): crates.io / docs.rs — distrust articles announcing non-existent majors ("tokio 2.0").
3. Advisories: https://rustsec.org and the real output of `cargo deny check advisories`.
4. Status of language features (stable? nightly?): The Rust Reference / official release notes, not third-party posts.

Rule: if a fact in this skill contradicts what web verification returns, **the web wins** and this skill should be updated.
