---
name: jvm-spring-standards
description: JVM engineering standards for Java/Kotlin backends with Spring Boot. Triggers on Java, Kotlin, Spring Boot, Spring Security, Spring Data, JPA/Hibernate, Gradle, Maven, JUnit, Testcontainers, GraalVM, .java/.kt/.kts files, build.gradle.kts, pom.xml, application.yml.
---

# JVM standards: Java/Kotlin + Spring Boot

Default criteria for backend projects on the JVM. It pins decisions; it is not a tutorial.
Version data verified as of **2026-08**: ALWAYS re-verify on the web before pinning in a project (see section 8).

## 1. Scope and triggers

- Applies to: Java/Kotlin backend services, REST/gRPC APIs, workers/batch, internal JVM libraries.
- Triggers: `.java`, `.kt`, `.kts`, `build.gradle(.kts)`, `settings.gradle(.kts)`, `pom.xml`, `application.yml|properties` files; mentions of Spring Boot/Security/Data, JPA, Gradle, Maven, JUnit, Testcontainers, GraalVM.
**Not applicable**: Android and mobile-app Kotlin (see `mobile-standards`). **Java legacy has its own
  owner**: `jsp-struts-standards` (JSP with *scriptlets*, Struts 1 and 2,
  `struts-config.xml`, *tag libs*, and the legacy application servers with their
  `javax` → `jakarta` barrier). **What is ours: the destination of that migration** — Spring Boot, the
  JDK version and the quality of the resulting code are governed by this skill. A warning both
  uphold: **an unpatched Struts application is a security problem before it is a
  maintenance one**, and several of its vulnerabilities appear in CISA's known exploited
  catalog. **Other JVM languages** — see `scala-standards`, `clojure-standards` and `groovy-standards`. Mirrored
  arbitration: **the choice and operation of the JVM is decided here** —JDK distribution and version,
  GC and its tuning, startup flags, JFR, containerising the JVM— **and anything Spring
  is ours even when the code is not Java**; **how code is written in Scala, Clojure or
  Groovy and their native builds** —sbt/Mill/scala-cli, `deps.edn`/Leiningen, Gradle and Jenkins as a
  DSL— **belongs to those skills**. See also
  `api-design-standards` (design of the HTTP/gRPC contract — here only its implementation with Spring
  MVC/WebFlux), `microservices-architecture-standards` (service boundaries, events, sagas,
  distributed resilience), `appsec-standards` (threat modelling and stack-agnostic vulnerability
  classes; here only Spring Security and the concrete JVM sinks),
  `data-platform-standards` (modelling, indexes, tuning and replicas; here only JPA/Hibernate and
  Flyway/Liquibase), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards`
  (OCI image, Native Image in a container and deployment), `observability-standards` (the
  OTel/Prometheus pipeline; here only Micrometer and the instrumentation), `git-workflow-standards` (branching,
  commits and SemVer tagging; publishing to Maven Central does belong to this skill),
  `identity-access-management-standards` (IdP design; here only how the service consumes it).

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a project; the ones below are the acceptable minimum (as of 2026-08).

| Piece | Choice | Minimum (2026-08) | Note |
|---|---|---|---|
| JDK | **Java 25 (LTS)** — Temurin/Liberica | 25 | Java 21 only in legacy; Java 26 (non-LTS) forbidden in prod |
| Kotlin | **2.4.x** (K2 compiler) | 2.4.0 | Only the latest version gets fixes |
| Build | **Gradle with Kotlin DSL** | 9.6.x | Maven only if the team/organisation already standardises on it |
| Framework | **Spring Boot 4.1.x** (Spring Framework 7) | 4.1.0 | 3.5 reached OSS EOL 2026-06; do not start anything on 3.x |
| Testing | **JUnit 6 (Jupiter)** + AssertJ + Testcontainers | JUnit 6.1.x, TC 2.0.x | Testcontainers 2.x uses `testcontainers-*` artifacts (e.g. `testcontainers-junit-jupiter`, `testcontainers-postgresql`) |
| Mocking | Mockito (Java) / MockK (Kotlin) | current | Mock boundaries, not everything |
| Formatter | **Spotless** (`com.diffplug.spotless`) with google-java-format / ktfmt | plugin 8.9+ | Old ID `com.diffplug.gradle.spotless` deprecated |
| Java analysis | **Error Prone** (`net.ltgt.errorprone`) + NullAway | plugin 5.1+ | Current Error Prone requires JDK 21+ to run |
| Kotlin analysis | **Detekt** | 1.23.8 (2.0 still alpha) | Migrate to `dev.detekt` 2.x when it is stable |
| SCA/deps | OWASP Dependency-Check or Dependabot/Renovate + `gradle dependencyUpdates` | current | Gate in CI |
| Native | **GraalVM for JDK 25** | 25 | Mandatory baseline with Boot 4 (new metadata format) |

- **Gradle toolchains** (`java.toolchain`) to pin the JDK: the build does not depend on the local JDK.
- **Version catalog** (`gradle/libs.versions.toml`) mandatory: versions in a single place, no magic strings in the build scripts.
- **Wrapper** (`gradlew` / `mvnw`) versioned in the repo; nobody builds with a local installation.
- Kotlin over Java for new code when the project does not impose Java; do not mix both in the same module without a reason.

## 3. Project structure and conventions

- **Packages by feature/domain** (`com.acme.billing.invoice`), not by technical layer (global `controllers/`, `services/`). Within each feature: web → application → domain → infrastructure, with dependencies only inwards.
- **Multi-module Gradle** when there are real boundaries to protect (Spring-free domain, separate adapters); modular monolith before premature microservices.
- **Constructor injection always**; field `@Autowired` forbidden. Immutable beans.
- Typed configuration with `@ConfigurationProperties` + validation (`@Validated`); scattered `@Value` forbidden.
- API DTOs as **records** (Java) / **data classes** (Kotlin); never expose JPA entities in the API.
- Nullability: Kotlin resolves it by type; in Java, **JSpecify** (`@Nullable`/`@NonNull`) + NullAway as a gate.
- Errors: your own domain exceptions + a single `@RestControllerAdvice` mapping to **Problem Details (RFC 9457)**. Catching generic `Exception` and swallowing it is forbidden.
- Profiles: base `application.yml` + `application-{profile}.yml`; secrets NEVER in those files (see §5).

**API contracts.**
- Contract documented with **springdoc-openapi** generated from the code (or contract-first if the team has that established); the published spec is a CI artifact and breaking contract changes are detected in the pipeline (openapi-diff).
- Explicit API versioning from day one (`/v1` path or media type); never break `v1` to add `v2`.
- Pagination mandatory on every collection (server-bounded limit); non-idempotent mutations with **Idempotency-Key** support when clients retry.
- Dates/times in the API always ISO-8601 UTC (`Instant`/`OffsetDateTime`); money with `BigDecimal` + explicit currency, never `double`.

**Concurrency and state.**
- Singleton beans with no mutable state; shared state only in external stores (DB/Redis) or justified concurrent structures.
- `@Transactional` at the application boundary (one method = one transaction); forbidden on `private` methods/self-invocation (the proxy does not apply) and forbidden to do remote IO inside a DB transaction.
- Concurrent operations on the same row: optimistic locking (`@Version`) by default; pessimistic only with measured contention.

## 4. Quality

**Formatter.** Spotless with google-java-format (Java) and ktfmt or ktlint (Kotlin) — pick one and never debate style again. `spotlessCheck` in CI, `spotlessApply` locally/pre-commit.

**Static analysis (gates, not suggestions).**
- Java: Error Prone in the compiler at error severity; NullAway with `@NullMarked` at package level.
- Kotlin: Detekt with config versioned in the repo; `maxIssues: 0`, baseline only for legacy adoption and with an expiry date.
- Compiler warnings as errors: `-Werror` (javac) / `allWarningsAsErrors = true` (Kotlin).

**Testing.**
- Unit: JUnit 6 + AssertJ; fast, deterministic, no Spring context. They cover the happy path, **edges and errors** (null/blank, limits, timeouts, concurrency where applicable). Parameterised tests for edge cases.
- Integration: **Testcontainers 2.x** with `@ServiceConnection` for Postgres/Kafka/Redis — the same image (and pinned version) as prod. **H2 as a substitute for the real DB is forbidden.**
- Spring slices (`@WebMvcTest`, `@DataJpaTest`) before a full `@SpringBootTest`; the latter only for a context E2E smoke test.
- Architecture rules as tests: **ArchUnit** (dependencies between packages/features, "the domain does not import Spring") — the diagram is verified, not drawn.
- Coverage with JaCoCo as a **signal** (indicative threshold on new lines via diff-coverage), never as a target that manufactures empty tests. Mutation testing (Pitest) optional in modules with critical logic.
- Asynchrony in tests with **Awaitility**; injected clocks (`Clock` as a bean) when time affects the logic.
- Every bugfix leaves a regression test. A flaky test is fixed or deleted; it is not retried.

**CI gates (build broken if any fails):** `spotlessCheck` → compilation with `-Werror` → Error Prone/NullAway/Detekt → unit tests → integration tests (Testcontainers) → SCA. Main always green.

## 5. Stack security

- **Spring Security always**, even in "internal" services: `SecurityFilterChain` as a bean, **deny-by-default** (`anyRequest().denyAll()` or `.authenticated()` at the end of the chain, never a residual `permitAll`).
- Stateless APIs: **OAuth2 Resource Server with validated JWT** (issuer, audience, expiry); sessions only in server-side web apps, and then CSRF enabled. Do not disable CSRF "because it gets in the way".
- Method-level authorisation (`@PreAuthorize`) for business rules; do not rely on URL matching alone.
- **Injection**: Spring Data repositories or parameterised queries; concatenating input into JPQL/SQL/commands is forbidden. Validation at the boundary with Jakarta Validation (`@Valid` on input DTOs).
- **Secrets**: env vars / Vault / Secrets Manager via Spring Cloud config or buildpacks bindings; secret scanning in CI (the scanner is pinned by `secrets-management-standards`). Never in `application.yml`, logs or images.
- **Serialisation**: Jackson with closed types; `enableDefaultTyping`/open polymorphic deserialisation and native Java serialisation for external data are forbidden.
- **SSRF**: any input URL is validated against an allowlist before `RestClient`/`WebClient` touches it.
- **Dependencies**: the Spring Boot BOM as the source of versions (do not override managed versions without recording why); SCA in CI breaks the build on a critical/high exploitable CVE; Renovate/Dependabot enabled.
- **Image**: distroless or buildpacks (`bootBuildImage`), non-root, read-only FS; minimal JRE via `jlink` if not native. Actuator: expose only `health` (and `prometheus` on a management port/network), never `env`/`heapdump` without auth.
- Crypto: the JDK/Spring Security one (Argon2/bcrypt for passwords, AES-GCM, TLS 1.2+); nothing homegrown, no MD5/SHA-1 for security.
- **Headers and abuse**: security headers (HSTS, `X-Content-Type-Options`, CSP where applicable) via the Spring Security configuration; rate limiting at the edge (gateway) or Bucket4j in the service for sensitive endpoints (login, search).
- **Auditing**: security events (login, permission changes, access to sensitive data) in an immutable structured log with actor + action + resource; PII masked in all logs.

## 6. Performance and operability

- **Virtual threads ON** (`spring.threads.virtual.enabled=true`) for IO-bound workloads on the servlet stack; watch out for `synchronized` that pins in old dependencies. WebFlux only with a real need for streaming/backpressure.
- **Explicit timeouts on EVERY client**: `RestClient`/`WebClient` (connect + read), JDBC (`loginTimeout`, `socketTimeout`), Hikari pool (`connectionTimeout`, `maxLifetime`); no timeout by default = bug. Retries with backoff+jitter only on idempotent operations; circuit breaker (Resilience4j) towards unstable dependencies.
- **Bounded and measured pools**: Hikari sized with data (not 100 connections "just in case"); request size and pagination limits on every list.
- **JPA with judgement**: `open-in-view=false` ALWAYS; explicit fetching (`@EntityGraph`/join fetch) against N+1; projections/DTOs for reads; migrations with **Flyway** (or Liquibase), `ddl-auto=validate` in prod, expand/contract for compatible changes.
- **Observability**: Actuator + Micrometer (Prometheus metrics) + **OpenTelemetry** (traces + W3C propagation) + structured JSON logs (Boot supports them natively) with traceId/spanId correlation. Golden signals with actionable alerts.
- **Graceful shutdown**: `server.shutdown=graceful` + `spring.lifecycle.timeout-per-shutdown-phase` aligned with K8s' `terminationGracePeriodSeconds`; Actuator liveness/readiness probes (`management.endpoint.health.probes.enabled=true`).
- **Messaging (Kafka/AMQP)**: idempotent consumers ALWAYS (at-least-once is the reality); DLQ with an alert and a runbook; atomic publication with the DB transaction via the **outbox pattern** (not "I save and then I publish"); versioned schemas (Avro/JSON Schema + registry) with backward compatibility.
- **Caching**: Spring Cache with Redis/Caffeine, TTL ALWAYS defined and a versioned key; invalidation designed, not "it will expire eventually". Never cache responses with authorisation data mixed between users.
- **GraalVM native where appropriate**: candidates = CLI, serverless, scale to zero, critical startup. Requires GraalVM 25+ with Boot 4; `RuntimeHintsRegistrar` for your own reflection (not a hand-written `reflect-config.json`); the integration tests run ALSO against the native binary in CI. Not native for fashion: JIT + CDS/Project Leyden (AOT cache) is usually enough for long-lived services.

## 7. Long-term sustainability

**Upgrade cadence.**
- Spring Boot: each minor has ~12 months of OSS support — minor upgrade **every ≤6 months**, no exceptions; plan majors with the migration release notes.
- JDK: LTS to LTS (25 → next LTS) within 12 months of its GA; JDK patches monthly via the base image.
- Kotlin/Gradle/plugins: Renovate with automatic merge of patches and a reviewed PR for minors.
- A dependency with no release in >18 months or with no response to CVEs = a candidate for replacement; record the decision (short ADR).

**Deprecation.** Compile with `-Xlint:deprecation`; every use of a deprecated API opens an issue with a target removal version. Nothing is suppressed (`@SuppressWarnings`) without a reason-comment and a link to an issue.

**PROHIBITIONS (vetoed anti-patterns).**
- ❌ Field injection (`@Autowired` on an attribute) and `@Component` with shared mutable state.
- ❌ H2/embedded as a double for the production DB in integration tests.
- ❌ `spring.jpa.open-in-view=true` and `ddl-auto=update|create` outside a local sandbox.
- ❌ Concatenating input into SQL/JPQL/commands; open polymorphic Jackson deserialisation; native Java serialisation for external data.
- ❌ `csrf().disable()` in apps with sessions; `permitAll` as the default; secrets in YAML/properties/repo.
- ❌ Catching and swallowing exceptions (`catch (Exception e) {}` or log-and-continue with no decision).
- ❌ `@SpringBootTest` as the default test format; tests with `Thread.sleep` to synchronise (use Awaitility).
- ❌ Lombok in Kotlin code; in new Java, prefer records/sealed over Lombok (if the repo already uses it, only `@Value`/`@Builder`, never `@SneakyThrows`/`@Data` on JPA entities).
- ❌ `System.out.println` / `printStackTrace` instead of SLF4J; logs with secrets or unmasked PII.
- ❌ Pinning loose versions that override the Boot BOM without an ADR; `latest` in images; an unversioned wrapper.
- ❌ Homegrown utilities for what the JDK/Spring already solves (dates: only `java.time`; never `java.util.Date`/`Calendar`/Joda).
- ❌ Non-LTS (Java 24/26...) in production.

**"Done" checklist for changes in this stack.**
- [ ] `./gradlew spotlessCheck build` green locally (compiles with `-Werror`, Error Prone/NullAway/Detekt pass and all tests pass).
- [ ] Edges and errors covered by tests (not just the happy path); bugfix with a regression test.
- [ ] No secrets or PII in the code, config or logs added; new endpoints with an explicit authorisation rule.
- [ ] New clients/queries with a defined timeout; Flyway migrations backwards compatible.
- [ ] New dependencies: justified, with a compatible licence, version in the catalog and with no known CVEs.
- [ ] If the service compiles to native: native binary build and integration verified, hints registered.
- [ ] Metrics/traces/logs cover the new functionality (it can be operated without SSH).

## 8. Mandatory web verification

Before pinning a version or API in a project, check online (not from memory):
- **Current Java LTS and its patch date**: whichjdk.com / adoptium.net (is 25 still the current LTS? has the next one shipped?).
- **Spring Boot**: latest release and OSS/EOL windows at endoflife.date/spring-boot and spring.io (is 4.1 still supported? is there a 4.2/5.0?). Review the migration release notes for the specific jump.
- **Kotlin** (kotlinlang.org/docs/releases.html) and **Gradle** (gradle.org/releases) — and their mutual compatibility matrix and with the chosen JDK.
- **JUnit** (junit.org), **Testcontainers** (java.testcontainers.org) — 2.x artifact names.
- **Error Prone / NullAway / Detekt / Spotless**: latest version and supported JDK/Kotlin (Detekt 2.x: stable yet? then the `dev.detekt` plugin).
- **GraalVM**: version aligned with the JDK and the baseline required by the Boot version.
- **Active CVEs** in the stack (Spring, Tomcat/Netty, Jackson, JDBC driver) in the spring.io/security advisories and NVD before freezing versions.

If the web contradicts this document, **the web wins** — flag the discrepancy.
