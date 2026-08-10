---
name: dart-standards
description: Use when writing or reviewing Dart code and its tooling - .dart files, pubspec.yaml, pubspec.lock, analysis_options.yaml, dart analyze, dart format, dart fix, dart test, dart compile exe/js/wasm, dart run build_runner, package:lints, package:flutter_lints, very_good_analysis, freezed, json_serializable, package:test, mocktail, mockito, golden tests, isolates, Future/Stream/async, dart:ffi, ffigen, jnigen, package:web and dart:js_interop, pub get/upgrade/publish, pub workspaces, or publishing to pub.dev.
---

# Dart standards (language and tooling)

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **Dart language and its toolchain**, whether used in Flutter, in a CLI, on a server or
on the web. Triggers: `.dart`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`,
`dart_test.yaml`, `build.yaml`, `dart analyze` / `format` / `fix` / `test` / `compile` / `doc`,
`dart pub`, `build_runner`, `freezed`, `json_serializable`, `ffigen`, `jnigen`, publishing to pub.dev.

Covers: the type system and null safety, patterns and `sealed`, dependency resolution and the lockfile,
lint and formatting, asynchrony (`Future`/`Stream`), isolates, error handling, code generation,
tests, compilation (JIT/AOT/JS/Wasm), native interop and package publishing.

**Not applicable**: see `mobile-standards` (**the design of the mobile app is theirs**: app
architecture, navigation and platform lifecycle, permissions, secure on-device storage
—Keychain/Keystore—, signing, publishing to the App Store and Google Play, rollout and updates,
perceived performance and mobile accessibility; **here only the Dart language, `pub`, the lints, the
formatting, the tests and the compilation**), `webassembly-standards` (the Wasm compilation target,
the runtime, the sandbox limits and the artifact size are theirs; here only the Dart side
—`dart:js_interop`, `package:web`, `--wasm`— of the crossing), `api-design-standards` (design of the
HTTP/GraphQL/gRPC contract that Dart code consumes or exposes), `appsec-standards` (threat modelling
and agnostic vulnerability classes; here the concrete Dart sinks),
`identity-access-management-standards` (OAuth 2.1/OIDC flows and token issuance; here only their
consumption), `secrets-management-standards` (custody and rotation; here only the rule that a client
binary does not store secrets), `cicd-standards` (the pipeline that runs the gates of §4),
`vulnerability-management-standards` (triage and patching SLA for the CVEs the SCA finds),
`observability-standards` (telemetry pipeline; here only the instrumentation in code),
`git-workflow-standards` (branch, commits and SemVer tagging), `typescript-standards` (the web
frontend that is not Flutter).

**Rule zero**: first detect the real project (the `sdk:` constraint of the `pubspec.yaml`, the pinned
Flutter version, the lint set active in `analysis_options.yaml`) and respect its conventions; these
criteria govern what is new and what is marked as debt.

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Minimum / status as of Aug 2026 | Why |
|---|---|---|---|
| Dart SDK | **The one that comes with Flutter's `stable` channel** if the project is Flutter | Dart **3.12.2** (bundled in Flutter stable **3.44.8**, 2026-07-23) | In a Flutter project **you do not choose the Dart version**: the Flutter SDK imposes it. Pinning Dart separately is a guaranteed source of misalignment |
| Dart SDK (non-Flutter project) | **Latest stable of dart-lang/sdk** | 3.12.x stable; **3.13.0 in beta** (Flutter 3.47.0-0.3.pre bundles it) | Dart is *non-Flutter* too (CLI, backend, tooling); there you do pin it directly |
| Constraint in `pubspec.yaml` | `environment: sdk: ^3.12.0` (caret, not an open range) | — | The caret expresses "this major, from this minor"; a hand-written `>=x <4.0.0` invites mistakes |
| SDK version management | **fvm** or the CI's manager, pinned in the repo | — | "Whatever version each machine has" is a reproducibility failure, not a preference |
| Lint (non-Flutter package) | **`package:lints`**, **`recommended`** set | — | The Dart team's own recommendation: *"We recommend using at least the `core` rule set… Or, better yet, use the `recommended` rule set"* |
| Lint (Flutter project) | **`package:flutter_lints`** | — | Official doc: *"If you're writing Flutter code, use the rule set in the `flutter_lints` package, which builds on `lints`"*. It is a superset of `recommended`, which in turn is one of `core` |
| Optional strict lint | `very_good_analysis` (10.3.0, MIT, from Very Good Ventures) | — | **Third-party, not official.** Adopt it only by an explicit team decision: it adds aggressive style rules and you do not control its major cadence |
| Formatting | **`dart format`** | — | The SDK's single formatter, with no style options. Zero debate in PRs |
| Analysis | **`dart analyze --fatal-infos`** in CI | — | Without `--fatal-infos` the infos accumulate until they are permanent noise |
| Tests | **`package:test`** (`dart test` / `flutter test`) | — | The ecosystem's only runner |
| Mocks | **`mocktail`** (1.0.5, MIT) by default; `mockito` only if it is already there | — | `mocktail` needs no codegen: *"no manual mocks or code generation"*. `mockito` forces `build_runner` for every mock |
| Codegen | `build_runner` + `json_serializable`; `freezed` only if the model justifies it | — | **Macros were cancelled** (Jan 2025, repo archived): codegen via `build_runner` is the official path and it will be for a long time |
| Native interop | `dart:ffi` + **`ffigen`** (C) / **`jnigen`** (Java-Kotlin) | — | Generated bindings, not hand-written |
| Web interop | **`package:web`** + **`dart:js_interop`** | — | `dart:html`, `package:js` and `dart:js` **are not compatible with compilation to Wasm** (§ compilation) |

## 3. Structure and conventions

**Types and language**

- **Sound null safety is not an option**: *"Dart has enforced sound null safety since Dart 3, released
  in May 2023"*. There is no "legacy code without null safety" that you can run on a 3.x SDK — what is
  left of the 2.12–2.19 era is abandoned packages that were never migrated: **they are not debt, they
  are an upgrade blocker**; they get replaced, not patched.
- `late` only with a real initialisation invariant (late injection, `initState`). `late` to shut the
  analyzer up is a `!` with more letters: **the failure moves from compile time to runtime**.
- `!` (bang) forbidden outside tests and proven invariants; use `?.`, `??`, promotion via
  `if (x != null)` or patterns.
- Explicit `required` on every named parameter with no sensible default; no nullable "just in case"
  that later gets dereferenced.
- **Patterns, records and `sealed`** have been available since **Dart 3.0**: model domain variants with
  a `sealed class` + an **exhaustive** `switch` (the analyzer checks exhaustiveness and will break the
  build when you add a case — that is exactly the effect you want). Chains of `if (x is A)` over closed
  hierarchies: veto.
- `records` for local multiple returns; **not** as a substitute for a named domain type.
- Class modifiers (`final`, `base`, `interface`, `sealed`) explicit in a package's public API: the
  absence of a modifier declares "anyone can extend this", and that is a contract.
- Generics with `extends` when there is a real constraint; `dynamic` vetoed except at an annotated
  boundary (use `Object?` + narrowing).
- Immutability by default: `final` on fields and locals, `const` where the value allows it.

**Package and dependencies**

- `pubspec.yaml`: constraints with a caret (`^1.2.3`), **never `any`** and no ranges open at the top.
  `dependency_overrides` is an emergency tool with an expiry date and a TODO linked to an issue, never
  a stable state.
- **Lockfile**, per Dart's official criteria, which depend on the type of package:
  - **Application** (Flutter app, CLI, service): *"we recommend that you commit the `pubspec.lock`
    file. Versioning the `pubspec.lock` file ensures changes to transitive dependencies are
    explicit"*. It is **always** versioned.
  - **Publishable package / library**: *"don't commit the `pubspec.lock` file. Regenerating the
    `pubspec.lock` file lets you test your package against the latest compatible versions of its
    dependencies"*. It is not versioned; in exchange, **CI must have a job that resolves against the
    latest permitted versions** — that is the point of the recommendation, and without that job you
    have merely lost reproducibility.
- Monorepos: **pub workspaces** (`workspace:` in the root `pubspec.yaml`) rather than `melos` in new
  projects; a shared resolution avoids skew between the repo's packages.
- Canonical layout: `lib/src/` for the implementation, `lib/<package>.dart` as the *barrel* that
  exports the public API. **What is not exported from `lib/` is not API**: importing
  `package:x/src/...` from outside is a boundary violation, not a shortcut.
- `analysis_options.yaml` at the root: `include:` of the chosen lint set + `analyzer: language:
  strict-casts, strict-inference, strict-raw-types` in new code. Exclude **only** generated files
  (`*.g.dart`, `*.freezed.dart`), never your own code.
- Names: `lowerCamelCase` for members, `UpperCamelCase` for types, `snake_case` for files and
  packages. A `_` prefix = private to the **library**, not to the class: keep that in mind when
  splitting files.
- Document the public API of publishable packages with `///`; `dart doc` in CI to detect broken
  references.

**Asynchrony**

- `async`/`await` by default; chained `.then()` only where `await` does not fit.
- **No `Future` left unawaited or unmanaged**: enable `unawaited_futures` in the lint and use an
  explicit `unawaited(...)` when fire-and-forget is deliberate. An orphan `Future` swallows its error
  and shows up as an inexplicable failure months later.
- `Stream`: **single-subscription by default**; `broadcast` only with a reason. Every subscription has
  a `cancel()` in the corresponding `dispose`/`close` — uncancelled subscriptions are the number one
  memory leak in Dart.
- `Completer` only to adapt callback APIs; never as your own flow control mechanism.
- Explicit timeouts (`.timeout(...)`) on every network or IPC operation. Without a timeout there is no
  operability.

**Isolates**

- **Dart does not share mutable memory between isolates**: each has its own heap and event loop;
  communication is by message passing (`SendPort`/`ReceivePort`, `Isolate.run`). This eliminates
  *data races* by construction — and it also eliminates the option of "just share the object".
- Usage rule: **isolate = CPU-bound**, not I/O-bound. I/O is already asynchronous in the main isolate;
  putting it in an isolate only adds serialisation cost.
- `Isolate.run` for one-off work; a long-lived isolate with ports only when the start-up cost and the
  message volume justify it.
- The real cost is the **serialisation of the message** (with exceptions: transferable types such as
  `TransferableTypedData`). Measure before assuming the isolate pays off.

**Errors**

- **Criteria**: exceptions for the *exceptional* (a bug, a broken invariant, an infrastructure
  failure); a **result type** (`sealed class Result<T>` with an exhaustive `switch`, or a third-party
  `Either`) for what is **expected and part of the contract**: failed validation, 404, invalid
  credential, no network. The criterion is "must the caller decide about this?" — if yes, it is a
  return value, not an exception invisible in the signature. Dart has no checked exceptions: an
  exception **does not appear in the signature**, and that is exactly the reason for the rule.
- Your own typed exceptions (`class PaymentDeclined implements Exception`); never `throw 'string'`.
- A generic `catch (e)` only at the boundary (request top level, `runZonedGuarded`, isolate handler)
  and **always rethrowing or logging with the `StackTrace`** (`on X catch (e, st)`). An empty `catch`
  or one that returns a silent default: veto.
- Distinguish `Error` (a programmer bug: `StateError`, `ArgumentError` → **they are not caught**, they
  are fixed) from `Exception` (a runtime condition → they are handled).
- Always release resources: `try/finally`, `close()`/`dispose()` on every `StreamSubscription`,
  `HttpClient`, file and `ReceivePort`.

**Code generation**

- Codegen is a **permanent cost**: `build_runner` runs on every model change, on every clean checkout
  and in every CI job, and in large projects it dominates build time. Every new generator is justified
  in writing.
- Rule: `json_serializable` yes (serialising by hand is error-prone and repetitive). `freezed` **only**
  when you really need sealed unions + `copyWith` + structural equality across many types; if it is
  four models, a hand-written `sealed class` is cheaper than the dependency and the generator.
- Generated files (`*.g.dart`, `*.freezed.dart`): they **are versioned** if consumption requires it (a
  published package, a reproducible build without the generator) and they **are excluded from analysis
  and coverage** always. Decide a stance per repo and document it; the hybrid is what breaks.
- CI: `dart run build_runner build --delete-conflicting-outputs` and **`git diff --exit-code`** —
  out-of-date generated code = broken build, not a surprise locally.

**Architecture and state management**

Out of scope except for what is language: observable state is modelled with `Stream`/`Listenable` and
**immutable** types with `sealed` variants (loading/error/empty/data), and dependencies are injected
via the constructor. The choice of state framework and the app's architecture belong to
`mobile-standards`. What is a veto here: **mutable global singletons** and service locators as a
substitute for injection.

## 4. Quality: formatting, analysis, tests

**CI gates, in increasing order of cost (they block the merge):**

1. `dart pub get` (or `flutter pub get`) — in applications, against the versioned lockfile.
2. `dart format --output=none --set-exit-if-changed .` — **non-negotiable, no exceptions**. There are
   no style options to argue about because the formatter does not offer any.
3. `dart analyze --fatal-infos --fatal-warnings`.
4. Codegen verified (`build_runner` + `git diff --exit-code`) if the repo uses generators.
5. `dart test` / `flutter test` with coverage (agreed threshold; **a signal, not a target**).
6. Dependency SCA + informative `dart pub outdated`.
7. Golden tests and the release build (real compilation) at the end.

**Testing**

- **Pyramid**: mostly unit tests over the domain and pure logic (no platform, no network, no real
  clock); just enough integration; few and stable widget/E2E.
- `package:test`: `group`/`test` with names that describe behaviour; AAA; one failure reason per test.
  `setUp`/`tearDown` for fixtures — no shared state between tests.
- **Mandatory edges and errors**: null/empty input, malformed JSON, timeout, network error, partial
  response, cancellation, permission denied.
- Asynchrony in tests: `expectLater(stream, emitsInOrder([...]))`, `fakeAsync`/`FakeAsync` and injected
  clocks. **`await Future.delayed(...)` as a way of "waiting for something to happen": veto** — it is
  the number one source of flakiness.
- Mocks at the **boundary** (HTTP client, repository, platform), not of the domain types themselves.
  `mocktail` by default; register `registerFallbackValue` for custom types.
- **Golden tests** only for the design system and high-value components. Operational warning: goldens
  are **sensitive to the rendering environment** — pin them to one platform and toolchain version in
  CI or you will spend more time regenerating `.png`s than testing. A golden that gets regenerated
  "to see if it passes" proves nothing; delete it.
- Every fixed bug leaves a **regression test**. An unstable test: it gets fixed or deleted, never
  retried in CI.

## 5. Stack security

- **A client binary does not store secrets.** Everything you compile into the app —API keys, private
  endpoints, signing keys, third-party credentials— **is public**: it is extracted with `strings`, with
  a disassembler or by intercepting the traffic. Obfuscating (`--obfuscate --split-debug-info`) raises
  the attacker's cost, **it is not a confidentiality control**. If a third party demands a secret key
  from the client, the call goes through your backend: there is no correct alternative.
- **Validation at the boundary**: everything that comes in —an API response, a deeplink, a CLI
  argument, a file, an environment variable, a message from another isolate— is parsed and validated
  before touching the domain. `json_serializable` validates **shape**, not **semantics**: ranges,
  unknown enums and missing mandatory fields are yours. An `as` over a `Map<String, dynamic>` without a
  check is a production crash waiting for the wrong payload.
- **pub.dev dependencies**: pub.dev **does not audit the code**. Its metrics (pub points, likes,
  *downloads*, *Dart 3 compatible* badges, *verified publisher*) are a signal of maintenance and
  ergonomics, **not of security**. Before adding a dependency: verified publisher, a public repository
  with real activity, a recent last publication, the number of transitive deps and the licence read —
  and check the name character by character (**typosquatting**). Bounded constraints + a lockfile in
  applications; SCA and advisories (osv.dev, GitHub Advisories) in CI.
- **Crypto**: `package:cryptography` or the platform APIs; never a home-made implementation.
  Security randomness **only** with `Random.secure()` — `Random()` is a predictable PRNG and using it
  for tokens, nonces or session IDs is a vulnerability, not a style slip.
- **On-device storage and Keychain/Keystore**: that belongs to `mobile-standards`. Here only the rule:
  nothing sensitive in cleartext files or in unencrypted preferences.
- **Logs**: no PII, no tokens, no full response bodies. In release, no `print`.
- **Injection**: `Process.run`/`Process.start` **with an argument list and `runInShell: false`** —
  never composing a shell line with external input. Parameterised SQL always.
- **TLS**: never override `badCertificateCallback` to return `true`, not even "temporarily for
  testing". If it appears in a diff, it is a review blocker.
- `dart:mirrors` is outside AOT and must not appear in new code.

## 6. Performance and operability

- **JIT in development, AOT in production.** The JIT gives hot reload and fast iteration start-up; AOT
  gives stable cold start and performance. Never profile in debug/JIT mode: the figures bear no
  resemblance to release ones.
- **`dart compile` formats** (verified in the official doc):
  - `exe`: a self-contained executable (Windows/macOS/Linux); it supports cross-compilation to Linux
    targets (ARM, ARM64, RISCV64, x64) from Dart 3.8+. **No `dart:mirrors` and no `dart:developer`.**
  - `aot-snapshot`: an architecture-specific AOT module, run with `dartaotruntime`.
  - `jit-snapshot`: IR with optimised code from a *training run*; peak performance potentially better
    than AOT **if the training run is representative** — and worse if it is not.
  - `kernel`: a portable `.dill`.
  - `js`: deployable JavaScript (the doc recommends `webdev` for production builds).
  - `wasm`: **"Currently under development"** in the `dart compile` doc — see §8, there is an apparent
    discrepancy with the state of Flutter web.
- **WasmGC in Flutter web**: `flutter build web --wasm` and `flutter run -d chrome --wasm` exist and
  are documented as a supported path, but **it is not a universal target**: Chromium/V8 support WasmGC
  from version 119; Firefox announced stable support in 120 but **"currently doesn't work"** because
  of a known limitation; Safari already supports WasmGC but has a **compatibility bug**; and on **iOS
  it does not work in any browser** (*"Flutter compiled to Wasm can't run on the iOS version of any
  browser"*), because they all use WebKit. **Criteria**: Wasm only with a JS *fallback* and with
  measurement, not as the default. Hard migration consequence: `dart:html`, `package:js` and `dart:js`
  **are not compatible** with compilation to Wasm — you have to migrate to `package:web` and
  `dart:js_interop`, and review the differences in `is`/`as` and in `Zone` propagation in interop
  callbacks. Diagnostics in production: `--source-maps`, and `--no-strip-wasm` only for staging/QA.
- **Artifact size** as a metric watched in CI (tree-shaking depends on there being no reflection and no
  hidden dynamic entry points).
- **Event loop**: no long CPU-bound work in the main isolate — chunk it or move it to `Isolate.run`. A
  200 ms `for` is a dropped frame, not a detail.
- **Profiling**: DevTools (CPU profiler, memory, timeline) **over a release/profile build**.
  Optimising without measuring is vetoed.
- **Leaks**: an uncancelled `StreamSubscription`, an uncancelled `Timer`, an unclosed `ReceivePort` and
  long-lived closures capturing large objects. It is the recurring pattern; look for it first.
- **Observability**: structured logs (`package:logging` with your own handler, not `print`), uncaught
  errors to `runZonedGuarded`/`Isolate.current.addErrorListener`, and crash reporting with symbols
  uploaded when you obfuscate (without a saved `--split-debug-info`, release stack traces are
  unreadable and obfuscation becomes a shot in the foot).
- **Publishing to pub.dev**: `dart pub publish --dry-run` in CI, a strict `CHANGELOG.md` and SemVer,
  `example/`, `topics:` in the pubspec, a verified publisher and publishing **automated from CI with
  OIDC** (no pub tokens on laptops). The pub.dev metrics (pub points, likes, downloads) are a signal of
  packaging quality, not of correctness.

## 7. Sustainability and prohibitions

**Cadence**

- Flutter project: you follow Flutter's **stable** channel and the Dart version comes bundled; the new
  stable is adopted in weeks, not quarters — the lag is paid in package incompatibilities, not in
  comfort. Never Flutter `master`/`main` in production; `beta` only for testing.
- Dart publishes minors on an approximately quarterly cadence: read the changelog and the *breaking
  changes* page before raising the SDK constraint.
- Dependencies: Renovate/Dependabot; security patches in <72 h; `dart pub outdated` reviewed
  periodically. A dependency not published in >18 months or without support for the current Dart major
  gets reviewed or replaced.
- Toolchain pinned in the repo (fvm / `.tool-versions` / CI image), not on each person's machine.

**LIST OF PROHIBITIONS** (they block review)

- ❌ `dynamic` as an escape from the type system; `as` without a prior check over external data.
- ❌ `!` (bang) for convenience; `late` to silence the analyzer.
- ❌ Chains of `is`/`if` over `sealed` hierarchies instead of an exhaustive `switch`.
- ❌ A `Future` without `await` or an explicit `unawaited()`; `.then()` without `onError`/`catchError`.
- ❌ An empty `catch`, a `catch` that returns a silent default, or catching without the `StackTrace`.
- ❌ `throw` of a `String` or of a type that does not implement `Exception`/`Error`.
- ❌ A `StreamSubscription`, `Timer` or `ReceivePort` left uncancelled/unclosed.
- ❌ `await Future.delayed(...)` as a wait in tests; tests dependent on order, on the real clock or on
  public network services.
- ❌ FORBIDDEN to disable `dart format` or to keep an alternative formatter.
- ❌ FORBIDDEN to ignore diagnostics with `// ignore:` without a reason comment, and `ignore_for_file`
  in your own code files.
- ❌ Excluding your own code from `analysis_options.yaml` so that analysis passes.
- ❌ `any` as a version constraint; `dependency_overrides` without a linked issue and an exit date.
- ❌ An application (app/CLI/service) **without a versioned `pubspec.lock`**; a publishable package
  **with** a versioned lock and without a CI job that resolves against the latest permitted.
- ❌ Importing `package:other/src/...` (another package's private API).
- ❌ Secrets, API keys or private endpoints compiled into the client binary; trusting obfuscation as a
  confidentiality control.
- ❌ `Random()` for tokens, nonces, session IDs or any security use (use `Random.secure()`).
- ❌ `badCertificateCallback => true`, not even "temporarily".
- ❌ `Process.run` with a shell line composed from external input.
- ❌ `print` in release code; logs with PII or tokens.
- ❌ `dart:mirrors` in new code.
- ❌ Adding a code generator without justifying its build cost in writing; committing out-of-date
  generated code.
- ❌ Mutable global singletons and service locators instead of constructor injection.
- ❌ Pinning Dart/Flutter versions from memory or from a blog instead of the official changelog.

## 8. Mandatory web verification

Before pinning any version, flag or capability in a real project, **verify online**:

1. **The latest Flutter stable and its bundled Dart**: `releases_linux.json` /
   `releases_macos.json` from `storage.googleapis.com/flutter_infra_release/releases/` (fields
   `current_release.stable`, `version`, `dart_sdk_version`) — it is the source that does not lie. As of
   Aug 2026: stable **Flutter 3.44.8 / Dart 3.12.2** (2026-07-23); beta **3.47.0-0.3.pre / Dart
   3.13.0-282.3**.
2. **The latest Dart stable** for non-Flutter projects: `dart.dev/get-dart/archive` and the official
   blog. **Careful**: the `dart-lang/sdk` Atom feed is dominated by `-dev` builds (as of 2026-08-03 the
   most recent was `3.14.0-85.0.dev`) — a `-dev` **is not** the stable. **Declared discrepancy as of
   Aug 2026**: the Dart blog had no announcement post for 3.13 yet and the *breaking changes* page was
   still marking it as unpublished, while Flutter beta already bundles 3.13.0-beta. Confirm the state
   of 3.13/3.14 before assuming anything.
3. **The recommended lint set today**: `dart.dev/tools/linter-rules` (`lints`: `core`/`recommended` vs
   `flutter_lints`) and the latest major of those packages on pub.dev. `very_good_analysis` is
   third-party: check version, licence and activity before adopting it.
4. **The state of WasmGC as a Flutter/Dart target**: `docs.flutter.dev/platform-integration/web/wasm`
   and `dart.dev/tools/dart-compile`. **Declared discrepancy as of Aug 2026**: the `dart compile` doc
   describes the `wasm` output as *"currently under development"*, while the Flutter web doc documents
   `flutter build web --wasm` as a supported path with browser caveats. They are not the same thing
   (standalone CLI vs. the Flutter web pipeline) but the exact state of each must be confirmed before
   committing to a platform; and Firefox/Safari/iOS support changes — look at the linked bugs
   (bugzilla 1788206, webkit 267291) before ruling it out or accepting it.
5. **The state of macros / static metaprogramming**: cancelled in Jan 2025 (`dart-lang/macros`
   archived); check whether **augmentations** have already landed in the language, because that would
   change the codegen criteria of §3.
6. **SDK breaking changes** before raising the constraint: `dart.dev/resources/breaking-changes` and
   `dart.dev/changelog`.
7. **CVEs and advisories** for every direct dependency (osv.dev, GitHub Advisories) and the maintenance
   status on pub.dev before pinning it.

**Gap not verified as of Aug 2026**: this drafting did not check the current state of `mockito`
(version, maintenance) or that of `freezed` 3.x beyond the context of the macros cancellation; nor the
concrete figures for `build_runner` cost in large projects, which are repo-dependent and must be
measured, not quoted.

If the web contradicts this document, **the web wins** — flag the discrepancy.
