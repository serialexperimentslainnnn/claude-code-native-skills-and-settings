---
name: scala-standards
description: Scala engineering standards (staff-level). Trigger on .scala/.sc files, build.sbt, project/build.properties, project/plugins.sbt, build.mill/build.sc, scala-cli "//> using" directives, .scalafmt.conf, .scalafix.conf, MiMa/binary-compatibility checks, and on Scala libraries such as cats-effect, fs2, http4s, ZIO, Akka, Apache Pekko, circe, jsoniter-scala, doobie, Slick, munit, ScalaTest, ScalaCheck, weaver, Scala.js or Scala Native. Apply when writing, reviewing, migrating (2.13 to 3) or configuring CI for Scala code, and when choosing between the Typelevel, ZIO and Akka/Pekko ecosystems.
---

# Scala standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all Scala code: `.scala`/`.sc` files, `build.sbt`, `project/build.properties`, `project/plugins.sbt`, `project/*.scala`, `build.mill`/`build.sc`, scala-cli `//> using` directives, `.scalafmt.conf`, `.scalafix.conf`, `.jvmopts`, and the pipelines that compile/test Scala. Covers backend services, libraries, CLIs, jobs and the structural choice of effect ecosystem. It fixes **criteria**: what to use, what is forbidden, what to verify.

**Not applicable**: see `jvm-spring-standards` (**the JVM itself and Spring**: JDK distribution and version, LTS, GC and its tuning, startup flags, JFR, containerising the JVM, jlink/GraalVM, and every Spring/Spring Boot criterion — if a Scala project uses Spring, **`jvm-spring-standards` rules for Spring**; here only the Scala code, its native builds — sbt/Mill/scala-cli — and its libraries), `clojure-standards` (the catalogue's other JVM language: same runtime, opposite paradigms — structural static typing versus dynamic homoiconic; the choice between them is one of **team and ecosystem**, not performance), `data-engineering-standards` and `lakehouse-standards` (**Spark is theirs as a platform**: pipeline, orchestration, partitioning, table format and cost; **the Scala written inside the job — API, types, tests, build — belongs to this skill**), `streaming-cdc-standards` (Flink/Kafka Streams as a streaming platform; here only the job's Scala code), `api-design-standards` (design of the HTTP/gRPC contract; here only its implementation with http4s/tapir/ZIO HTTP/Pekko HTTP), `sql-standards` (**SQL itself**: schema, indexes, plans — Doobie/Slick/quill generate SQL and that SQL is subject to their criteria), `data-platform-standards` (engine modelling and tuning), `microservices-architecture-standards` (service cuts, sagas, distributed resilience), `appsec-standards` (threat modelling and agnostic vulnerability classes; here only Scala's concrete sinks), `vulnerability-management-standards` (CVE triage and SLAs; here only the build gate), `secrets-management-standards`, `observability-standards` (the OTel pipeline; here only in-code instrumentation), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI image and deployment), `python-standards`/`go-standards`/`rust-standards` (choosing a language over Scala), `groovy-standards` (**the catalogue's third JVM language**, with a different role: today it is mostly a configuration language for other tools — **Gradle's Groovy DSL and the `Jenkinsfile` are theirs**, including the `build.gradle` of a Scala project that uses Gradle instead of sbt).

## 2. Toolchain and default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Status as of 2026-08 | Note |
|---|---|---|---|
| Language | **Scala 3** | Next **3.8.4**; LTS **3.3.8**; **3.9.0 in RC** (RC4) | 3.9 will be the new LTS line; 3.8 freezes features ahead of it |
| Baseline JDK | 3.8+/3.9 require **JDK 17+**; 3.3 LTS is still compatible with JDK 8 | — | The **JDK version is set by `jvm-spring-standards`**; here only the minimum the compiler imposes |
| Scala 2 | **2.13.18** (maintained line); 2.12 only because of an external dependency (Spark) | — | New code in Scala 2 **requires written justification** |
| Build | **sbt 2.0.x** (GA 2026-06-14; 2.0.4 current) for new projects; **sbt 1.12.x** still maintained | — | sbt 2 requires JDK 17+ and plugins written in Scala 3 |
| Alternative build | **Mill 1.x** (1.1.7) if the team prioritises build speed and readability | — | A team decision, not a purely technical one: fewer plugins than sbt |
| Scripts/prototypes | **scala-cli 1.16.x** | — | The standard for scripts, bug reproductions and documentation examples |
| Formatting | **scalafmt 3.11.x** (Apache-2.0) | — | `.scalafmt.conf` versioned with `version` and `runner.dialect` pinned |
| Refactor/lint | **scalafix 0.14.x** (BSD-3-Clause) | — | Semantic rules: `RemoveUnused`, `OrganizeImports`, `DisableSyntax` |
| Test | **munit 1.3.x** by default; **ScalaCheck 1.19.x** for properties | ScalaTest 3.2.20 (no release since 2024-06) | ScalaTest only if the repository already uses it; weaver now lives in **typelevel/weaver-test** (0.13.x), active |
| JSON | **jsoniter-scala 2.39.x** (performance) or **circe 0.14.x** (ergonomics) | — | Pick one per repository; do not mix |
| Binary compatibility | **MiMa** in every published library | — | A CI gate, not a report |

**Effect ecosystem — a structural decision, taken once per organisation and documented in an ADR.** The three stacks are mutually exclusive in practice: mixing them duplicates runtime, error types, thread pools and learning curve.

| Stack | When | Status as of 2026-08 |
|---|---|---|
| **Typelevel** (cats-effect 3.7, fs2 3.13, http4s 0.23.x, doobie 1.0.0-RCx) | Recommended default: the de facto standard effect model, broad interoperability, Apache-2.0 licences | cats-effect 3.7.0 (2025-07); stable http4s is still on the **0.23.x** line — 1.0 has been in milestones for years (M47); doobie is still at **1.0.0-RC13** (a long-running RC) |
| **ZIO** (2.1.x, zio-http 3.11.x) | Teams that want an integrated, opinionated single-vendor stack (effect, streams, HTTP, test, config) | ZIO 2.1.26 (2026-05). No evidence of a published ZIO 3 |
| **Akka / Apache Pekko** | Only with a real need for the **actor model**, cluster sharding or event sourcing (Akka Persistence) | Akka: repository moved to `akka/akka-core`, 2.10.x, **BSL**. Pekko: ASF TLP, 1.6.0 stable and 2.0.0-Mx in development |

**The Akka case is the most expensive licensing decision in the ecosystem.** Verified:
- **2022-09-07**: Lightbend announces the change. Verbatim: *"The new license for Akka is the Business Source License (BSL) v1.1"*, *"After 3 years, the BSL license indefinitely reverts to an Apache 2.0 license"* and *"The commercial license will be available at no charge for early-stage companies (less than US $25 million in annual revenue)"*. The change applies from **Akka 2.7**; published versions ≤2.6.x remain under Apache-2.0. **BSL is not an open source licence.**
- **Apache Pekko** is the community fork from Akka 2.6.x, today an **ASF Top-Level Project** (graduation announced by the ASF on **2024-05-16**), Apache-2.0, with equivalent modules (actor, streams, http, persistence, connectors) and adopted by Flink and Play.
- **Criterion**: for new code, **Pekko**, not Akka. Akka only with a current commercial licence, reviewed by legal and with the revenue threshold checked against the **current** terms (§8) — the $25M threshold is the one from the 2022 announcement, not an eternal figure. Migrating Akka 2.6.x → Pekko is mechanical (package renaming) and is the default path for any base still on 2.6.x.
- Watch the transitive dependency: a library dragging in `com.typesafe.akka` ≥2.7 puts BSL in your tree without anyone deciding it. Veto it in the licence policy (§5).

## 3. Structure and conventions

**Scala 3 is the present, with two verified caveats that change the migration plan**:
- **Interoperability is no longer bidirectional.** All of Scala 3 consumes 2.13 artifacts; the 2.13 TASTy reader (`-Ytasty-reader`) **will never be able to consume Scala 3.8+ artifacts** — 3.7 is the last line readable from Scala 2. Cause: 3.8 publishes `scala-library` compiled with Scala 3.
- Operational consequence: if modules remain on 2.13 consuming Scala 3 libraries, either they are pinned to artifacts ≤3.7 or the migration gets finished. The TASTy reader is a **migration aid with an expiry date**, not a permanent compatibility layer.

**Compatibility to know before publishing**: Scala 3 minors are *backwards* TASTy- and binary-compatible (*"code compiled with Scala 3.2.x can still be used in Scala 3.3.x, 3.4.x, 3.5.x or any other future version, indefinitely"*); patches are compatible in both directions. Derived rule: **libraries are published against LTS** (3.3 today, 3.9 tomorrow); applications run on Next.

- **Cross-building only when there are real consumers** on the other version. Cross 2.13+3 in an application is pure cost.
- Standard layout `src/main/scala` / `src/test/scala`; multi-module sbt/Mill when there are boundaries to protect (domain with no framework dependencies, adapters apart). Packages by domain, not by technical layer.
- **`given`/`using` with discipline**: type class instances in the companion of the type or of the type class (predictable implicit search); `given` **always with a name and an explicit type** in a public API. Forbidden to use `using` to pass business configuration or request context "because it is convenient" — that is a parameter. Implicit conversions: only through an explicit `Conversion` imported at the point of use; never a global implicit conversion.
- **`extension`** replaces implicit classes; group extensions by type and do not export methods that collide with the type's API.
- **Opaque types (`opaque type`) for identifiers and units** (`opaque type UserId = UUID`) — zero runtime cost and they prevent accidentally swapping two `String`s. A newtype with `case class` only when pattern matching is needed.
- **ADTs with `enum`** (including hierarchies with parameters) and `sealed trait` only if the hierarchy needs more than `enum` expresses. Impossible states unrepresentable; a `case class` with scattered `Option`s/booleans is the antipattern to avoid.
- **Typed errors, not exceptions**: `Either[DomainError, A]` (or the effect's error channel: `IO`+`EitherT`/`MonadError`, `ZIO[R, E, A]`) for every expected domain failure. Exceptions are left for **non-recoverable** failures and for the boundary with Java. Forbidden: `try/catch` as control flow, and catching `Throwable`/`NonFatal` to swallow the error.
- **`Future` is discouraged in new code**: eager evaluation (not referentially transparent), no cancellation, no bound resources. It is admitted only at the boundary with Java/Play/Slick libraries that impose it, converting immediately to the stack's effect (`IO.fromFuture`, `ZIO.fromFuture`).
- **Resources always bound**: `Resource`/`Scope` (or `Using` in effect-free code). No manual `close()` hoping no exception fires first.
- `null` does not exist in Scala except in Java interop: wrap in `Option` **on the call line**, not three layers up. `Option.get`, `head` on a possibly empty collection and `.asInstanceOf` are forbidden (§7).

**Scala.js and Scala Native — bounded.** Scala.js 1.22.x is the mature option for sharing the domain model and validations between backend and web frontend; the rest of the frontend criteria (bundling, framework, accessibility) **is not this skill's business**. Scala Native 0.5.x is viable for CLIs and fast startup (cats-effect 3.7 adds multithreading on Native), but it implies a reduced ecosystem and different debugging: adopt it with a written use case, not out of fashion.

## 4. Quality: formatting, flags, lint and testing

**Scala 3 compiler flags that are worth it** — set in the build's `scalacOptions`, not in the IDE:

```scala
scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation", "-feature", "-unchecked",
  "-Wunused:all",          // available from 3.3.4+
  "-Wvalue-discard",       // silently discarded results
  "-Wnonunit-statement",
  "-Werror",               // see note
  "-Wconf:cat=deprecation:ws,any:e",  // deprecations as warnings, everything else an error
  "-source:3.8"            // pin the source level explicitly
)
```
- **`-Werror`, not `-Xfatal-warnings`**: verified — `-Xfatal-warnings` is a legacy alias **deprecated since Scala 3.8**. `-Wall` exists from 3.5.2+ (backported to 3.3.5+) as a broad switch.
- `-Werror` **always on in CI**; locally it can be relaxed (`-Wconf`), but the CI build is the truth. One-off exceptions with a narrow `@nowarn("msg=...")` and a comment explaining why, never a global `-Wconf:any:s`.
- When running scalafix, disable fatal warnings for that task: otherwise the compiler breaks the build before scalafix can fix anything.
- **sbt-tpolecat** is acceptable so as not to maintain the list by hand, but review what it enables: it inherits flags that may lag behind 3.8's deprecations.

**Formatting and refactoring.** `scalafmt` with `version` pinned in `.scalafmt.conf` (different versions reformat differently → phantom diffs); `scalafmtCheckAll` in CI. `scalafix` with `RemoveUnused`, `OrganizeImports` and **`DisableSyntax`** configured to veto at build time what §7 forbids (`null`, `throw`, `var`, `asInstanceOf`, `Option.get`) in domain modules.

**Testing.**
- **munit** by default (fast, no bespoke DSL to learn); `munit-cats-effect`/`zio-test` depending on the stack. ScalaTest only through repository inertia.
- **ScalaCheck / property-based testing is mandatory** in all logic with invariants (parsers, round-trip serialisation, domain arithmetic, business rules with combinatorial cases). One well-chosen property test replaces twenty examples.
- Coverage of **edges and errors**: every variant of the error ADT, empty collections, numeric limits, timeouts and **cancellation** of the effect (a test that only exercises `IO`'s happy path proves nothing about its semantics).
- Virtual time (`TestControl` in cats-effect, `TestClock` in ZIO) instead of real sleeps; **`Thread.sleep` and `Await.result` are forbidden in tests**.
- Integration against real dependencies with **testcontainers-scala** (same image and version as production); H2 as a substitute for the real database is forbidden.
- Every bugfix leaves a regression test. A flaky test is fixed or deleted.
- Coverage (`scoverage`) as a signal, never as a goal.

**CI gates, in order of increasing cost (they break the build):**
```
scalafmtCheckAll  →  scalafixAll --check  →  compile with -Werror  →  test  →  mimaReportBinaryIssues (libraries)  →  dependency SCA
```
Main always green; nothing is merged on red CI.

**Compilation times are an engineering problem, not a complaint.** A build cycle measured in minutes destroys feedback and pushes the team into skipping tests.
- An explicit budget (e.g. incremental compilation of one module <20 s) and measurement with `-Vprofile` / `-Ystatistics` when it degrades.
- Usual, actionable causes: macros and aggressive inlining, automatic codec derivation at every point of use (**derive once in the companion, not `deriveEncoder` inline per call**), deep implicit search, very generic type hierarchies, monolithic modules.
- Split into modules along real dependencies, use `Test / parallelExecution` judiciously, `bloop`/a build server locally, CI caching (sbt 2 ships a Bazel-compatible cache; Mill caches per task).
- Before "optimising Scala", measure: most slow builds are one module and three files.

## 5. Stack security

- **Deserialisation**: the JVM's real risk. Java native serialisation of external data is forbidden, as is any open polymorphic deserialisation (Jackson `enableDefaultTyping`, `@JsonTypeInfo` without an allowlist). In Scala this is solved with codecs **derived from closed types**: `jsoniter-scala` (compile-time macros, no reflection, the fastest) or `circe` (explicit `deriveDecoder` in the companion). Every ADT deserialised from external input carries an explicit discriminator and a closed set of subtypes.
- Limits when parsing untrusted input: maximum body size in the HTTP server, JSON depth/length (jsoniter exposes `ReaderConfig` with `maxBufSize`/depth), read timeouts. A decoder without limits is a DoS.
- **Validate at the edge with types**: parse into a domain type (`Either[Error, Email]`), do not validate and carry on with `String`. *Parse, don't validate.*
- **Parameterised SQL only**: `doobie`/`Slick`/`quill` with safe interpolation (doobie's `sql"..."` is parameterised); building SQL with `s"..."` or `+` over input is forbidden. The criteria for the resulting SQL belong to `sql-standards`.
- **Dependencies in an ecosystem with a history of binary breakage** — a hard rule:
  - `evictionErrorLevel` set to error and **zero unmanaged evictions**: two different minor versions of a Scala library on the classpath is a `NoSuchMethodError` in production waiting for its moment.
  - Align the whole stack to a single line (a complete cats-effect 3.x; do not mix ZIO 1 and 2 modules).
  - `sbt-dependency-graph`/`dependencyBrowseTree` to audit the tree before adding anything; every new dependency is a trust decision that gets justified.
  - A library with no release in >18 months or with an eternal RC: accepted only with a recorded decision (the doobie 1.0.0-RCx and http4s 0.23.x cases: they are stable *de facto* and widely deployed, but the numbering is no guarantee — the guarantee is the project's binary compatibility policy).
  - **Licence policy in the gate**: an allowlist (Apache-2.0, MIT, BSD, EPL-2.0…) and an **explicit denylist of BSL/SSPL/Elastic** — so that transitive Akka ≥2.7 breaks the build instead of turning up in an audit.
- **SCA in CI**: dependency scanning (the specific scanner and the triage SLA are set by `vulnerability-management-standards`) that breaks the build on an exploitable critical/high CVE. Scheduled as well as on the PR, because CVEs appear without the code changing.
- **Build supply chain**: sbt plugins and Mill tasks **execute arbitrary code with the runner's permissions**. Plugins pinned by version, from known sources, reviewed on update; `project/build.properties` versioned; no unencrypted HTTP resolvers and no snapshots in release builds.
- **Secrets**: never in `build.sbt`, a versioned `application.conf`, logs or exception messages. Typed config (`pureconfig`/`ciris`/`zio-config`) with secrets from the environment or a manager; wrap them in a type that redacts in `toString`. A Scala-specific hazard: **`case class` generates a `toString` that prints every field** — a logged `case class Config(dbPassword: String)` leaks the password; override `toString` or use an opaque `Secret`.
- Crypto and TLS: those of the JDK/standard libraries (see `cryptography-pki-standards` for algorithm choice). Security randomness with `SecureRandom`, never `scala.util.Random`.
- Logs without PII; domain exceptions without sensitive data in the message (they end up in error responses and in the SIEM).

## 6. Performance and operability

- **The JVM (GC, heap, startup flags, JFR, container) is `jvm-spring-standards` territory.** Here, the Scala-specific parts:
- **Never block the effect's compute pool**: JDBC, files, blocking Java calls and heavy CPU go to a separate context (`IO.blocking`/`Sync[F].blocking`, `ZIO.attemptBlocking`, a dedicated dispatcher in Pekko). Blocking the work-stealing pool turns a service into a silent hang under load.
- **Explicit backpressure**: fs2/ZIO Streams/Pekko Streams with concurrency limits (`parEvalMap(n)`, `mapZIOPar`), **bounded** queues, and no `parTraverse` over a list of unbounded size (unlimited fan-out against a dependency = incident).
- **Timeouts at every edge** (HTTP client, JDBC, connection pool) and propagated cancellation; effects are cancellable — make sure the operation is *cancel-safe* and releases resources.
- **Collections**: `List` for sequential access, `Vector`/`ArraySeq` for indexed access, `LazyList` with care (it memoises). Forbidden: `++` in a loop over immutable structures (quadratic) and using `Seq` in a public API where performance matters (it may be a linked list). `view` to chain transformations over large collections.
- Benchmarks with **JMH** (`sbt-jmh`) before claiming anything is faster; boxing and implicit collection conversions are the usual suspects.
- **Observability**: `otel4s`/`zio-telemetry`/OTel instrumentation depending on the stack; structured logs (`log4cats`, `ZIO Logging`) with traceId. `println` is forbidden in service code. The pipeline and the SLOs belong to `observability-standards`.
- **Graceful shutdown is mandatory**: `IOApp`/`ZIOAppDefault` handle SIGTERM and finalizers; verify that the server drains connections and that `Resource`/`Scope` close pools before exiting, aligned with the orchestrator's grace period.
- Separate health endpoints: trivial liveness, readiness that checks dependencies.

## 7. Sustainability: upgrades and prohibitions

**Cadence.** Applications on **Scala Next**, moving up a minor in the quarter following its release; published libraries against **LTS**, with the LTS jump planned within the year following the new line (the previous LTS has patches guaranteed *"until at least a year after the release of the next LTS line"*). Dependencies with Scala Steward (the ecosystem standard) grouped weekly; majors by hand with the changelog. Migration 2.13 → 3: plan it before the TASTy reader's asymmetry makes it urgent (§3).

**Deprecation.** `@deprecated` with `since` and a `message` naming the replacement; a window of at least one minor before removal. In libraries, SemVer + **MiMa** in CI: breaking binary compatibility without a major bump is a consumer incident, not a detail.

**Conscious debt.** Every shortcut with `// TODO(user): reason — link to issue`.

**FORBIDDEN** (exception only with written justification and approval):
- ❌ `null` in Scala code (except Java interop, wrapped on the spot); `Option.get`, `.head`/`.last` on a possibly empty collection, `.asInstanceOf`, `isInstanceOf` as a substitute for pattern matching.
- ❌ `throw` as control flow for domain errors; `catch { case _ => }` or `case NonFatal(_) => ()` that swallows the error without a decision; catching `Throwable`.
- ❌ `Await.result`/`Await.ready` in production code; `unsafeRunSync()`/`Unsafe.unsafe` outside `main` or a test.
- ❌ `Future` in new code outside the boundary with a library that imposes it.
- ❌ Blocking the effect's compute pool (JDBC/synchronous IO/heavy CPU without `blocking`).
- ❌ Mixing effect ecosystems (cats-effect + ZIO + Pekko) in the same service without an explicit, approved interop layer.
- ❌ **Akka ≥2.7 (BSL) without a current commercial licence verified by legal**, including one arriving as a transitive dependency; for new code, Pekko.
- ❌ Global implicit conversions; `given` without an explicit type in a public API; `using` to smuggle in business configuration.
- ❌ `var` and shared mutable state in the domain; `mutable.Map` as a global cache with no concurrency control and no TTL.
- ❌ Inline codec derivation at every point of use (compilation cost) and `deriveEncoder` over open types with untrusted input.
- ❌ Unmanaged dependency evictions; two minor versions of the same library on the classpath; `+` (dynamic versions) or snapshots in release builds.
- ❌ CI without `-Werror`; a global `-Wconf:any:s`; warning suppression with no written reason; merging on red CI or with flaky tests.
- ❌ `println`/`printStackTrace` instead of structured logging; a config `case class` holding secrets with the default `toString`.
- ❌ Concatenating input into SQL; Java native serialisation or open polymorphic deserialisation of external data.
- ❌ Starting a new project in Scala 2 without an ADR; adding cross-building without real consumers.
- ❌ Home-grown macros/`inline` for what an existing derivation or explicit code solves (compilation cost + opacity).

## 8. Mandatory web verification

Before pinning versions or asserting the state of the ecosystem, check online (not from memory):
1. **Scala**: current Next and LTS versions and the JDK baseline — scala-lang.org/download/all.html and the release notes; has **3.9.0 final** shipped as the new LTS? (as of Aug 2026 it was at RC4). Compatibility policy at scala-lang.org/development/.
2. **2.13↔3 interop**: scala-lang.org, "State of the TASTy reader" — confirm the cut at 3.8 and up to which version artifacts remain consumable from 2.13.
3. **sbt / Mill / scala-cli**: `github.com/{sbt/sbt,com-lihaoyi/mill,VirtusLab/scala-cli}/releases.atom`; the state of the sbt 2 plugin ecosystem (sbt2-compat) before forcing sbt 2 on a repository with in-house plugins.
4. **Akka's licence**: akka.io/bsl-license-faq and akka.io/pricing — **the revenue threshold and the terms may have changed since 2022**; check with legal. Status and releases of **Apache Pekko** at pekko.apache.org (not just GitHub).
5. **Effect stacks**: releases of cats-effect/fs2/http4s/doobie and of ZIO; check whether http4s 1.0 or doobie 1.0 finals have shipped and whether ZIO published a new line.
6. **Tools**: scalafmt, scalafix, munit, ScalaCheck, MiMa, testcontainers-scala — latest version **and licence** (licence changes and projects in maintenance mode are a real risk to the catalogue).
7. **CVEs** in the tree (jackson, netty, JDBC drivers, logging libraries) in the projects' advisories and NVD before freezing versions.
8. **Declared gap, unverified as of Aug 2026**: the formal EOL date of the Scala 2.13 line and of 3.3 LTS (no published date located, only the relative guarantee "≥1 year after the next LTS"); ScalaTest's maintenance status (no releases since 2024-06, no official end-of-support statement found); Akka's exact current commercial terms.

If the web contradicts this document, **the web wins** — flag the discrepancy.
