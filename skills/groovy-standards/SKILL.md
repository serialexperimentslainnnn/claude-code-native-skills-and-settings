---
name: groovy-standards
description: Use when writing or reviewing Groovy code - .groovy and .gvy files, Jenkinsfile (declarative or scripted), Jenkins Shared Libraries with vars/ and src/, @NonCPS annotations and Script Security sandbox approvals, build.gradle and settings.gradle in the Groovy DSL versus build.gradle.kts, gradle init defaults, Spock specifications in src/test/groovy, @CompileStatic/@TypeChecked/@DelegatesTo, AST transforms, GString interpolation, or codenarc.
---

# Groovy standards (reference: August 2026)

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Groovy today is above all a configuration language for other tools, not an application language.** Almost
all the Groovy written in 2026 is a `Jenkinsfile`, a `build.gradle` or a Spock specification.
Writing a backend in Groovy is a decision that has to be justified against Java or Kotlin, and
it almost never survives the justification (§7). This skill is structured by use case.

Triggers: `.groovy`, `.gvy`, `Jenkinsfile`, `vars/*.groovy`, `src/**/*.groovy` of a Shared Library,
`build.gradle`, `settings.gradle`, `gradle.properties`, `@NonCPS`, `@CompileStatic`, `@DelegatesTo`,
`codenarc`, Spock specs in `src/test/groovy`.

**Not applicable**:
- **`jvm-spring-standards` (critical boundary)**: **the JVM, the JDK, the GC, memory tuning, Spring
  and the application model are theirs**. The **Groovy language** and the **Gradle and Jenkins DSLs** are
  ours. If the question is "which JDK and with which flags", it is theirs; if it is "how do I write this
  `build.gradle`", it is ours.
- **`cicd-standards` (critical boundary, in both directions)**: **pipeline strategy, the
  gates, artifact signing, the SBOM, OIDC, runner security and isolation are theirs**.
  **How the `Jenkinsfile` is written as Groovy code** — declarative vs *scripted*, CPS, `@NonCPS`,
  Shared Libraries, the Script Security sandbox — **is ours**. A "the pipeline does not
  pass the gate" problem is theirs; a "the pipeline does not serialise and fails at step 3" one is ours.
- `scala-standards` and `clojure-standards` (the other JVM languages), `iac-standards`,
  `container-runtime-security-standards` (the isolation of the container where the agent runs),
  `lua-standards` and `perl-standards` (nothing in common), `appsec-standards`,
  `vulnerability-management-standards`, `secrets-management-standards`, `sql-standards`,
  `observability-standards`.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

**Apache Groovy is alive and actively maintained** — a relevant fact because the opposite is often
assumed. It is an **Apache Software Foundation** project (Apache-2.0) and as of Aug 2026 it maintains **three
parallel lines**, with releases from the same week:

| Line | Verified status (Aug 2026) |
|---|---|
| **Groovy 5.0.x** | **Current stable**. 5.0.8 (2026-07-29) |
| Groovy 4.0.x | Maintained. 4.0.33 (2026-07-29) |
| Groovy 6.0.0 | **BETA-1 (2026-08-01)**. Do not use in production |

**Groovy 5 JDK requirements** (official release notes): *JDK17+ to **build** Groovy* and
**JDK 11 is the minimum supported JRE version**; tested on JDK 11–25. In practice: you do not choose the
Groovy version if you work inside Gradle or Jenkins — **the tool imposes it**,
because it embeds its own Groovy. Check which one before using a language feature.

| Piece | Choice | Verified | Licence (raw LICENSE) |
|---|---|---|---|
| Language | Apache Groovy 5.0.x | 5.0.8 | **Apache-2.0** |
| Build | Gradle 9.x | 9.6.1 (2026-06-26); 9.7 in RC | **Apache-2.0** |
| CI | Jenkins LTS | 2.568.x line; *weekly* 2.575 | **MIT** |
| Tests | **Spock** | **2.4** (2025-12-11), stable after a long series of *milestones* | **Apache-2.0** |
| Lint | CodeNarc | see §8 (not verified) | see §8 |

### Gradle: `build.gradle` versus `build.gradle.kts`

The real criteria today, unambiguously:

- **New project → Kotlin DSL (`.kts`).** It is what Gradle generates by default. Verbatim from the release
  notes of version 8.2: *"Kotlin DSL is now the default option when generating a new project with the
  init task."* An engineering reason, not a fashion one: static typing, real autocompletion and navigation
  in the IDE, and compile-time errors in the build itself. The Groovy DSL is dynamic and its
  "API" is metaprogramming and delegation: the IDE guesses.
- **The Groovy DSL is NOT deprecated** and remains supported. There is no end-of-life pressure.
- **Existing `build.gradle` → do not migrate it for the sake of it.** Migrating a large build is a
  project with real risk (plugins, `ext`, closures with implicit delegation, ad-hoc logic in
  loose `.gradle` files) and its benefit is *developer experience*, not functionality. Criteria: migrate if you are already
  going to touch the build in depth, if the build is complex enough that the lack of types
  costs real time, or if you are going to move it to `buildSrc`/*convention plugins* (where the Kotlin DSL gains
  much more). Otherwise, it stays and is kept well written.
- Whichever the DSL: **build logic outside the script**. `buildSrc/` or an *included build* with
  *convention plugins*; `build.gradle(.kts)` must be declarative. Version catalog
  (`gradle/libs.versions.toml`) as the single source of versions. **Gradle Wrapper committed, with
  `gradle-wrapper.properties` pointing to a distribution with `distributionSha256Sum`** — a wrapper
  without a checksum is execution of downloaded code without verification.

## 3. Jenkins: the `Jenkinsfile` is not normal Groovy

This is the section that prevents the most incidents. **A `Jenkinsfile` looks like Groovy and does not behave like
Groovy.**

- **CPS transformation**: Jenkins compiles the pipeline with the Groovy parser but **does not execute its
  bytecode**: a `CompilationCustomizer` rewrites almost every operation into
  *continuation-passing* style, and its own interpreter executes them. Reason: **the complete program state
  is serialised to disk** (`program.dat` in the build directory) on every asynchronous
  operation, so that the build survives a Jenkins restart and continues where it was.
- **Consequences that must be internalised**:
  - Every variable live at the point of a *step* call **must be serialisable**. A regex `Matcher`,
    an `InputStream`, a `File` → `NotSerializableException` at an apparently
    random point. Rule: non-serialisable objects live and die inside a `@NonCPS`, or are
    discarded (`m = null`) before the next step.
  - **It is slow**, and the official documentation is explicit: it is not meant to be efficient and must
    be limited to high-level *glue code*, with the real logic in external programs via `sh`/`bat`.
    **A loop over 10,000 items inside a pipeline is a design error.** There are also Groovy
    constructs that the interpreter does not cover well (closures over collections, inheritance).
- **`@NonCPS`**: marks a method so that it is compiled and executed with native Groovy semantics (except for the
  sandbox checks). Hard rules:
  - **You cannot call CPS methods or pipeline *steps* from a `@NonCPS`.** Its only
    correct use is pure computation: serialisable data in, serialisable summary out.
  - Do not accept, return or store non-serialisable values from a `@NonCPS`.
  - `@Override`s of methods of binary classes (`toString()`, `equals()`) **must** be `@NonCPS`,
    because the binary code will call them from a non-CPS context.
  - Jenkins detects the most common error (calling CPS code from a non-CPS context) and warns about it in the
    log; that warning **is a failure, not noise**.
- **Declarative by default.** `pipeline { agent … stages { … } }` is the correct form for 95% of
  cases: fixed structure, validatable, with native `post`, `options`, `environment` and `matrix`, and
  much less loose Groovy to serialise. **Scripted** (`node { … }`) only for control flows
  that declarative cannot express, and even then a bounded `script { }` block inside the
  declarative is preferred over an entire *scripted* pipeline.
- **Shared Libraries** for everything repeated across repos: `vars/` (global steps, one file per
  step, with `call()`) and `src/` (normal Groovy classes, here you can indeed type and test). The library
  is **a repo versioned with tags**, and pipelines reference it **by tag or by commit**, never
  by a moving branch: `@Library('mylib@v3.2.0')`. A library referenced by `master` is a global
  change without review that applies to all pipelines at once.
  - It is tested: the `src/` classes with Spock, in their own build. A pipeline whose only test
    environment is production is not code, it is a bet.
- **`Jenkinsfile` short by design**: it orchestrates, it does not implement. Any logic longer than a few lines
  goes down to a script in the repo (`bash`/`python`) or to the Shared Library. Double benefit: it can be
  run and tested locally without Jenkins, and it does not go through CPS.

## 4. The language: what to use and what to avoid

- **`@CompileStatic` whenever possible; `@TypeChecked` at a minimum.** Dynamic Groovy pays for every
  call through runtime *dispatch* and does not detect a method typo until the line is executed — in
  a pipeline, that is "fails at minute 40 of the build". Apply it at class level in all the logic
  of a Shared Library (`src/`) and in any Groovy application code.
  - Real limit and why it is not applied everywhere: **the Gradle and Jenkins DSLs depend on
    dynamic metaprogramming** (delegation, `methodMissing`, `propertyMissing`), so the pipeline script
    and the `build.gradle` **cannot be `@CompileStatic`**. That is exactly the reason
    why the logic must leave the script and go down to classes that can be.
- **Closures and delegation** are the mechanism of the DSLs: `delegate`, `owner`, `resolveStrategy`.
  When you write your own DSL, annotate **`@DelegatesTo`** on the closure parameter — without that, neither the IDE
  nor `@CompileStatic` can resolve anything inside the block, and your DSL is untouchable.
- **AST transforms**: `@Immutable`, `@Canonical`, `@Builder`, `@Memoized`, `@Slf4j` are useful and
  legitimate. Writing **your own AST transforms** is vetoed except in extraordinary cases: they are code that
  runs in the compiler, almost impossible to debug and that breaks with every Groovy version.
- **GString and its interpolation trap** — two classic incidents, both vetoed:
  - **In SQL**: `sql.execute("SELECT * FROM t WHERE id = $id")` with `groovy.sql.Sql` **does**
    parameterise the GString (it is a deliberate special case), but
    `sql.execute("SELECT * FROM t WHERE id = ${id}".toString())` **does not**: converting to `String`
    loses the parameterisation and you have injection. Any concatenation or `.toString()` on a
    GString destined for SQL is vetoed. Use explicit placeholders and a parameter list.
  - **In logs**: `log.debug("payload: $obj")` **always evaluates the interpolation**, even if the DEBUG
    level is off. A hot-path cost and, worse, **leakage**: in a pipeline that can dump a
    credentials object into the build log. Use the logger's placeholder form, and never
    interpolate credential objects or environment maps.
- `?.` (*safe navigation*) and `?:` (Elvis) are idiomatic and correct; deeply chained `?.`
  is not robustness, it is hiding a `null` that should not exist — fail early at the edge.
- `def` versus types: with `@CompileStatic`, explicit types in public signatures always. `def` only
  for obvious locals.
- Groovy truth: `0`, `""`, `[]`, `[:]` and `null` are false. **It is not Java nor Lua**; an `if (x)`
  check on a number or a collection does not mean "it is not null".

## 5. Security: Groovy is arbitrary code execution on the JVM

**Starting point without nuance: a `Jenkinsfile` or a `build.gradle` from an untrusted repository
executes whatever it wants inside your runner, with your runner's identity.** It is not a configuration
file; it is a program. Everything that follows derives from that.

- **Gradle**: `./gradlew build` on an unknown repo executes its build code before compiling
  anything. A PR that modifies `build.gradle`, `settings.gradle` or `buildSrc/` is a PR that modifies what
  your CI executes. Consequence: **workflows that run builds from forks never receive secrets
  nor tokens with write permissions**; Gradle plugins are pinned to an exact version from the
  version catalog and resolved from an own repository or a mirror, never from an arbitrary
  repository declared in the script itself; the wrapper carries `distributionSha256Sum`.
- **Jenkins Script Security**: the Groovy sandbox is what prevents a pipeline from taking control of the
  controller. Its model is an allowlist of methods, with **manual approval** (*In-process Script
  Approval*) for whatever falls outside. Two rules:
  - **FORBIDDEN to disable the sandbox.** The Pipeline runtime has access to Jenkins
    internals: retrieving encrypted credentials, triggering deployments, deleting artifacts. A pipeline without
    a sandbox is full control of the controller for anyone who can write to the repo.
  - **Approving a method is a security decision, not an administrative unblock.** Approving things
    like `getClass`, `getDeclaredMethods`, anything reflection-related or `System.*` amounts to
    disabling the sandbox through the back door. If a pipeline needs something the sandbox does not
    allow, **the correct solution is to move it down to an approved Shared Library or to a plugin**, not
    to approve the method.
  - There have been and will be **sandbox bypass CVEs** (implicit casts of the Groovy runtime,
    default parameter expressions in CPS methods, rebuild of an unapproved script). Corollary:
    the sandbox is **containment, not a boundary**. The boundary is who can write to the repo and what
    the agent can reach.
- **Controller and agent hygiene**: nothing is compiled or executed on the controller — everything on
  ephemeral agents. The Jenkins script console (`/script`) is arbitrary execution as the
  Jenkins user: restricted and audited access.
- **Secrets**: through credentials binding (`withCredentials`), never in the `Jenkinsfile`, in
  the repo's `gradle.properties` nor in global environment variables. `set -x` in a `sh` and a
  GString interpolation are the two usual ways a secret ends up in the build log.
- **Runner supply chain** — the control that actually cuts. Precedent already established in this
  catalogue and verified: in 2026 **malicious packages published with cryptographically valid
  SLSA Build L3 attestations** were documented (the worm over 42 `@tanstack` packages in May 2026,
  and the wave over `@redhat-cloud-services` in June), because the attackers hijacked the
  *legitimate pipeline* and the provenance correctly described a compromised build. **Signed
  provenance is no longer enough**: it says where the artifact came from, not that it is safe. What does cut
  the vector, applied to the Groovy/CI world:
  - **Pin by SHA or by digest everything that enters the runner**: GitHub Actions by commit SHA
    (not by tag), agent images by digest, Gradle distribution by `distributionSha256Sum`,
    plugins and dependencies by exact version with checksum/signature verification
    (`gradle/verification-metadata.xml`), Shared Libraries by immutable tag or commit.
  - **No dependency resolution from an arbitrary repository** declared in the build script
    itself.
  - Ephemeral runner, without long-lived credentials, with bounded egress, and OIDC trust tied to a
    **specific workflow and protected branch**, not to "the repository". The full strategy lives in
    `cicd-standards`; what is ours is that **the Groovy file is the vector**.

## 6. Performance and operability

- In a pipeline the dominant cost is almost always the CPS interpreter: the lever is not optimising
  Groovy, it is **taking work out of the pipeline** towards `sh`/scripts on the agent.
- Gradle: build cache and configuration cache enabled; `--scan`/Develocity to know where the
  time goes before touching anything. Custom tasks with declared inputs/outputs (otherwise they are neither
  incremental nor cacheable). No logic in the configuration phase.
- Jenkins: `timeout` on every stage (**a pipeline without a timeout is an agent blocked forever**),
  `retry` only on idempotent steps, `disableConcurrentBuilds()` where there is shared state, and
  `buildDiscarder` — `program.dat` files and artifacts fill disks.
- Observability of CI as a service: duration per stage, failure and *flakiness* rate, time in
  queue. A pipeline without metrics cannot be improved (telemetry, in `observability-standards`).
- The same command must run locally and in CI. If a build only works on the agent, it is a build bug.

## 7. Sustainability and prohibitions

- **Cadence**: Gradle follows a fast cadence — update the wrapper regularly and read the
  *release notes* first (Gradle major jumps do break plugins). Jenkins: use the **LTS
  line**, with monthly updates and **plugin updates as a recurring task**, not annual: the
  majority of Jenkins security advisories are about plugins.
- A Jenkins plugin with no releases and no maintainer is security debt: it is replaced or retired.
  Audit the list of installed plugins once a quarter and **delete what is not used** (each
  plugin is attack surface on the controller).
- Own deprecations in a Shared Library: versioned with tags and with a retirement window; the
  pipelines pointing to an old tag are visible debt, which is exactly what is wanted.

**List of prohibitions (veto):**
- ❌ **FORBIDDEN** to disable the Jenkins Script Security sandbox.
- ❌ **FORBIDDEN** to approve reflection methods, `System.*`, `getClass`/`getDeclaredMethods` or similar
  in the *script approval*. If that is needed, the design is wrong.
- ❌ **FORBIDDEN** to run builds from forks or from untrusted repos with access to secrets or to
  credentials with write permissions.
- ❌ Referencing a Shared Library, an action or an image by branch or moving tag. Immutable tag, commit
  or digest.
- ❌ Gradle wrapper without `distributionSha256Sum`; dependencies without checksum/signature verification.
- ❌ Non-trivial logic inside the `Jenkinsfile` or the `build.gradle`: move it down to a Shared Library,
  `buildSrc`/convention plugin, or a script executable on the agent.
- ❌ Loops over large collections or real computation inside a CPS pipeline.
- ❌ Calling pipeline *steps* from a `@NonCPS` method; keeping non-serialisable objects alive
  across a step.
- ❌ GString converted to `String` in a SQL query; interpolation of credential objects or of the
  environment in logs.
- ❌ Dynamic Groovy (without `@CompileStatic`) in application code or in the `src/` of a Shared Library.
- ❌ Own AST transforms except with extraordinary written justification.
- ❌ Migrating a large and healthy `build.gradle` to `.kts` with no reason other than fashion.
- ❌ Running code on the Jenkins controller instead of on ephemeral agents.
- ❌ Pipeline without `timeout` or `buildDiscarder`.
- ❌ **Choosing Groovy for new application code.** Groovy is the correct choice in three places:
  a `build.gradle` that already exists, a `Jenkinsfile`, and a **Spock** suite (which remains an
  excellent test framework and a fully legitimate use, even for testing Java or Kotlin code).
  Outside that, a new service on the JVM is written in Java or Kotlin — static typing, tooling,
  performance, hiring and ecosystem all play against Groovy, and the project itself
  positions itself as a *scripting* and DSL language, not as an application platform.

## 8. Mandatory web verification

Before pinning versions or APIs, **verify online** (WebSearch/WebFetch and the Atom feeds
`https://github.com/OWNER/REPO/releases.atom`; `api.github.com` returns 403 unauthenticated):
1. **Groovy**: latest 5.0.x and the status of **Groovy 6** (as of Aug 2026 at `6.0.0-BETA-1`: **not production**),
   and the JDK matrix of the version you are going to use at `groovy-lang.org/releasenotes/`. Verified as of
   Aug 2026 for Groovy 5: **JDK 11 minimum JRE, JDK 17+ to build Groovy, tested up to JDK 25**.
2. **Which Groovy your tool embeds** (Gradle and Jenkins ship their own, usually older than
   the latest stable): it is what decides which language features you can use.
3. **Gradle**: latest stable (9.6.1 as of Aug 2026, with 9.7 in RC) and the release notes before
   bumping the wrapper. Confirm that the Groovy DSL is still **supported and not deprecated**.
4. **Jenkins**: the number of the current LTS and, above all, the **security advisories** of Jenkins and
   its plugins (`jenkins.io/security/advisories`) — including the Groovy sandbox *bypasses*.
5. **Spock**: latest stable (2.4 as of Aug 2026) and its declared compatibility with your Groovy
   and JUnit Platform versions.
6. CVEs of Groovy, Gradle and the Jenkins plugins in use (osv.dev / GitHub Advisories).

**Gaps not verified as of Aug 2026** (do not fill in from memory):
- **CodeNarc**: current version, licence and maintenance status **not verified**. Before pinning it
  as the default linter in a project, check its latest release and its raw `LICENSE`. If it is
  stalled, the Groovy quality gate rests on `@CompileStatic` + compilation + the tests, which
  is where the real value is anyway.

**Declared discrepancy**: the *What's new in Gradle 9* page on gradle.org places the adoption of the
Kotlin DSL as the recommended option in **"April 2023 (Gradle 8.2)"**, whereas the release notes of
version 8.2 on `docs.gradle.org` **show no publication date** confirming it and the real date
of 8.2 is not verified. What is verified verbatim in the 8.2 notes is the substantive
claim: *"Kotlin DSL is now the default option when generating a new project with the init task."*
Use the claim, not the date.

If the web contradicts this document, **the web wins** — flag the discrepancy.
