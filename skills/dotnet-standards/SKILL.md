---
name: dotnet-standards
description: C#/.NET engineering standards for backend services. Triggers on C#, .NET, dotnet, ASP.NET Core, EF Core, Entity Framework, NuGet, xUnit, Blazor, Native AOT, .cs/.csproj/.sln/.slnx files, Directory.Build.props, Directory.Packages.props, appsettings.json.
---

# .NET standards: C# / ASP.NET Core

Default criteria for C#/.NET projects. It fixes decisions; it is not a tutorial.
Version data verified as of **2026-08**: ALWAYS re-verify on the web before pinning it in a project (see section 8).

## 1. Scope and triggers

- Applies to: C# backend services (APIs, workers, gRPC), internal NuGet libraries, CLI tooling in .NET.
- Triggers: `.cs`, `.csproj`, `.sln`/`.slnx`, `Directory.Build.props`, `Directory.Packages.props`, `global.json`, `appsettings*.json`, `.editorconfig` files; mentions of .NET, ASP.NET Core, EF Core, NuGet, xUnit, Native AOT.
**Not applicable**: Unity (its own C#/runtime version). **Microsoft legacy has its own
  owners**, and the boundary runs in both directions: `dotnet-framework-legacy-standards`
  (**.NET Framework 4.x**: maintenance, what has no port —WebForms, server-side WCF,
  Workflow, `AppDomain`, *remoting*— and the migration route), `vbnet-standards` (**the
  VB.NET language, frozen by Microsoft's decision**), `vb6-standards` and `classic-asp-standards`
  (**no IDE or language support: freeze, isolate or rewrite**) and `pascal-delphi-standards`
  (**Delphi / Object Pascal as the usual origin of migration to .NET**: the containment and
  exit criteria for that platform are theirs). **What does belong here, and it is
  worth saying out loud: the destination of any of those migrations** — the quality of the
  resulting code (SDK, LTS version, ASP.NET Core, EF Core, NuGet, publishing, container) is
  governed by this skill, not by the origin one. See also `api-design-standards` (design of the HTTP/gRPC contract — here only its
  implementation with Minimal APIs/ASP.NET Core), `microservices-architecture-standards` (service
  decomposition, events, sagas, distributed resilience), `appsec-standards` (threat modelling and
  stack-agnostic vulnerability classes; here only the concrete .NET sinks and flags),
  `data-platform-standards` (modelling, indexes and engine tuning; here only EF Core and its
  migrations), `sql-standards` (**the SQL language**, including the SQL EF Core generates and the SQL
  written by hand in `FromSql`: joins, CTEs, `NULL`, SARGable predicates and parameterisation),
  `webassembly-standards` (Blazor WebAssembly and `dotnet wasm` compile to Wasm — the
  runtime, the sandbox limits and **the size of the downloaded artifact**, which is the
  critical metric there, are decided by their criteria; the C#/F# and its build, here),
  `ocaml-fsharp-standards` (**the F# language**: idioms, discriminated unions, *computation
  expressions*, domain modelling with types, `Fantomas`, `Expecto`/`FsCheck`, and the boundary of
  interoperability with C# —`null` versus `Option`—. Arbitration: **the SDK, the LTS version,
  `Directory.Build.props`, NuGet, publishing, the runtime, ASP.NET Core, hosting and
  containerisation are decided here, even if the code is F#**; how that F# is written, there. A
  `.fs` does not route on its own to this skill),
  `powershell-standards` (**PowerShell runs on .NET and that closeness is the confusion**: if the
  problem calls for an **application** —service, API, library, distributable binary—, this
  skill wins; if it calls for **administrative automation** —a script, a module, a task over AD or
  over the machine—, `powershell-standards` wins. The .NET version PowerShell runs on
  is decided here; how the script is written, there), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI
  image, Native AOT in a container and deployment), `azure-standards` (the managed services where it
  is usually deployed; here only the code), `observability-standards` (OTel pipeline; here only the
  instrumentation), `git-workflow-standards` (branch, commits and SemVer tagging; publishing to
  NuGet does belong to this skill), `identity-access-management-standards` (IdP and Entra ID design;
  here only how the service consumes it).

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a project; the ones below are the minimum acceptable (state as of 2026-08).

| Piece | Choice | Minimum (2026-08) | Note |
|---|---|---|---|
| Runtime/SDK | **.NET 10 (LTS)** — supported until 2028-11 | 10.0.x | .NET 8 and 9 die on 2026-11-10: migrate NOW; STS (11, Nov 2026) only with a reason and a plan |
| Language | **C# 14** (`LangVersion` implicit from the TFM) | 14 | Do not pin a lower `LangVersion` without an ADR |
| Web | **ASP.NET Core 10** — Minimal APIs by default | 10 | Controllers only if the project already uses them or there is a real need (complex filters, ApiConventions) |
| Data | **EF Core 10** + official provider | 10 | Dapper/ADO.NET for measured hot paths or AOT scenarios |
| Testing | **xUnit v3** (`xunit.v3`) + Testcontainers for .NET | 3.2.x | On **Microsoft.Testing.Platform (MTP)**, not VSTest; v2 is in maintenance |
| Asserts/doubles | AssertJ-style: FluentAssertions or Shouldly; NSubstitute | current | Verify the FluentAssertions ≥8 licence before choosing |
| Formatter | **CSharpier** + `dotnet format` (style/analyzers) | 1.3.x | CSharpier for layout; `.editorconfig` for naming/semantic style |
| Analysis | **Roslyn analyzers from the SDK** + strict `.editorconfig` | SDK 10 | `AnalysisLevel=latest-all`; add SonarAnalyzer.CSharp or Meziantou.Analyzer if more signal is wanted |
| SCA/deps | `dotnet list package --vulnerable` + NuGetAudit + Dependabot/Renovate | SDK 10 | Gate in CI |
| Containers | `dotnet publish /t:PublishContainer` or chiseled Dockerfile | — | `mcr` chiseled/distroless images, non-root |

- `global.json` versioned, pinning the SDK band (`rollForward: latestFeature`): reproducible builds.
- **Central Package Management** (`Directory.Packages.props`) mandatory: NuGet versions in a single place.
- Root `Directory.Build.props` with the common properties: `<Nullable>enable</Nullable>`, `<ImplicitUsings>enable</ImplicitUsings>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<AnalysisLevel>latest-all</AnalysisLevel>`, `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`.

## 3. Project structure and conventions

- Solution per domain: `src/` + `tests/`; projects per real boundary (Api, Application, Domain, Infrastructure) only if the domain warrants it — one project well organised by features beats 8 anaemic projects. **Organisation by feature/vertical slice**, not by global technical layer.
- **Nullable reference types enabled EVERYWHERE** (`<Nullable>enable</Nullable>` globally); `!` (null-forgiving) requires a reason comment; no public API with ambiguous nullability.
- DTOs and messages as immutable **records**; `required`/`init` instead of public setters. EF entities never exposed in the API.
- DI from the native container (`Microsoft.Extensions.DependencyInjection`); registration per feature with extension methods (`services.AddBilling()`); deliberate lifetimes (never capture a scoped in a singleton).
- Typed configuration with the **Options pattern** (`IOptions<T>` + `ValidateDataAnnotations().ValidateOnStart()`); scattered `IConfiguration["key"]` forbidden.
- Errors: domain exceptions + a single `IExceptionHandler`/middleware mapping to **ProblemDetails (RFC 9457)**; `Result<T>` optional for expected flows, but one single pattern per solution.
- `async/await` end to end with `CancellationToken` propagated through every public async API; no `async void` (event handlers only).

**API contracts.**
- OpenAPI generated from the code with **`Microsoft.AspNetCore.OpenApi`** (native since .NET 9; Swashbuckle only in legacy); the spec is a CI artifact and contract breaking changes are detected in the pipeline (openapi-diff).
- Explicit API versioning from day one (**Asp.Versioning**, `/v1` path or media type); never break `v1` to add `v2`.
- Pagination mandatory on every collection (server-bounded limit); non-idempotent mutations with **Idempotency-Key** support whenever clients retry.
- Dates/times in the API always ISO-8601 UTC (`DateTimeOffset`/`DateOnly`); money with `decimal` + explicit currency, never `double`.

**Concurrency and state.**
- Services with no shared mutable state; state in external stores (DB/Redis) or justified concurrent structures (bounded `Channel<T>`, `ConcurrentDictionary`).
- Transactions at the application boundary (one business operation = one transaction/`SaveChanges`); remote IO inside an open DB transaction forbidden.
- Concurrency over the same row: EF **optimistic concurrency** (`rowversion`/token) by default; pessimistic locking only with measured contention.

## 4. Quality

**Formatter.** CSharpier as the layout authority (opinionated, zero debate); `dotnet format` for the style rules in `.editorconfig`. Both verified in CI (`csharpier check .`, `dotnet format --verify-no-changes`).

**Static analysis (gates, not suggestions).**
- `AnalysisLevel=latest-all` + `TreatWarningsAsErrors=true` in `Directory.Build.props`; severities tuned in a versioned `.editorconfig` (CA categories + IDExxxx rules).
- Nullable warnings ALWAYS as errors (TreatWarningsAsErrors covers them); `#pragma warning disable` requires a reason and a link to an issue.
- `EnforceCodeStyleInBuild=true` so that style breaks the build, not just the IDE.

**Testing.**
- Unit: **xUnit v3** on MTP; fast, deterministic, no infrastructure. They cover the happy path, **edges and errors** (null/empty, limits, cancellation, culture/encoding, concurrency where applicable). `[Theory]` for case tables.
- Integration: `WebApplicationFactory` for the real HTTP pipeline + **Testcontainers for .NET** with the SAME DB image as prod (pinned version). **EF InMemory provider FORBIDDEN as a double for the real DB** (it validates neither SQL, nor transactions, nor constraints); SQLite only for logic tests without specific SQL.
- `TimeProvider` injected instead of `DateTime.UtcNow` directly when time affects the logic (testable without hacks).
- Architecture rules as tests: **NetArchTest/ArchUnitNET** (dependencies between projects/features, "Domain does not reference Infrastructure") — the diagram is verified, not drawn.
- Coverage with **coverlet** as a signal (indicative threshold over new lines via diff-coverage), never a target that manufactures empty tests.
- Every bugfix leaves a regression test. A flaky test is fixed or deleted.

**CI gates (build broken if any fails):** format check → `dotnet build -warnaserror` (analyzers included) → unit tests → integration tests (Testcontainers) → `dotnet list package --vulnerable --include-transitive` / NuGetAudit → smoke publish (and of the AOT binary if applicable).

## 5. Stack security

- **AuthN/AuthZ**: JWT bearer (`AddAuthentication().AddJwtBearer()`) with issuer/audience/lifetime validated; **named authorisation policies** (`AddAuthorizationBuilder().AddPolicy(...)`) and `RequireAuthorization()` by default on endpoint groups — deny-by-default, `[AllowAnonymous]` is the explicit exception. Identity/OpenIddict or an external IdP (Entra ID, Keycloak) before home-made auth.
- **Injection**: EF Core parameterises by default; raw SQL only with `FromSql`/EF's safe interpolation or ADO parameters — never concatenation. Validation at the boundary (DataAnnotations/FluentValidation) over input DTOs, payload size limits (`RequestSizeLimit`) and pagination limits.
- **Secrets**: User Secrets in dev only; in prod, env vars / Key Vault / AWS Secrets Manager via `IConfiguration` providers. Secret scanning in CI (the scanner is set by `secrets-management-standards`); never in `appsettings.json` nor in the repo.
- **Serialisation**: `System.Text.Json` (not Newtonsoft in new code unless a hard dependency); `BinaryFormatter` forbidden (removed in .NET 9+, do not reintroduce) and open polymorphic deserialisation without closed discriminators.
- **Headers and transport**: HTTPS/HSTS, security headers via middleware; CORS with an explicit allowlist, never `AllowAnyOrigin` + credentials.
- **SSRF**: input URLs validated against an allowlist before `HttpClient` touches them; `HttpClient` ALWAYS via `IHttpClientFactory`.
- **Dependencies**: NuGetAudit enabled (fails on high/critical vulnerability), lockfiles (`RestorePackagesWithLockFile`) in CI, Dependabot/Renovate; unmaintained packages or ones with an unpatched CVE = replace and record (ADR).
- **Runtime hardening**: chiseled/distroless `mcr.microsoft.com/dotnet/*` containers, non-root (default in .NET 8+: user `app`), read-only FS, minimum capabilities.
- **Passwords and crypto**: Identity/`PasswordHasher` (or Argon2/bcrypt via a maintained library) for your own credentials; **Data Protection API** with a key ring persisted and shared across replicas (never ephemeral keys per pod); AES-GCM/`RandomNumberGenerator` from the BCL, nothing home-made and no MD5/SHA-1 for security.
- **Auditing**: security events (login, permission changes, access to sensitive data) in a structured log with actor + action + resource; PII masked in all logs (`Microsoft.Extensions.Compliance` redaction where applicable).

## 6. Performance and operability

- **Explicit timeouts and resilience**: `Microsoft.Extensions.Http.Resilience` (standard handler: total and per-attempt timeout, retry with backoff+jitter only on idempotent calls, circuit breaker) on every `HttpClient`; `CommandTimeout` in EF/ADO; **request timeouts middleware** on endpoints. No defined timeout = bug.
- **Limits**: Kestrel with reviewed concurrency/size limits; rate limiting middleware (`AddRateLimiter`) on public APIs; backpressure in queues (bounded Channels, not `Unbounded` by default).
- **Allocations under control in measured hot paths**: `Span<T>`/`Memory<T>`, `ArrayPool`, `IAsyncEnumerable` for streaming — optimise with BenchmarkDotNet and profiles, never by eye.
- **EF Core with judgement**: `AsNoTracking` on reads, projections to DTO, `AsSplitQuery` against cartesian explosion, compiled queries in hot paths; versioned migrations applied by the pipeline (not `Database.Migrate()` when starting concurrent replicas), expand/contract for compatibility.
- **Observability**: `Microsoft.Extensions.Telemetry` + **OpenTelemetry** (traces, metrics, correlated logs; OTLP export); structured logging with `ILogger` + source-generated `LoggerMessage` in hot paths (never string interpolation in hot logs); health checks (`AddHealthChecks` + separate liveness/readiness endpoints).
- **Graceful shutdown**: `IHostApplicationLifetime` respected, `HostOptions.ShutdownTimeout` aligned with K8s `terminationGracePeriodSeconds`; workers with `BackgroundService` honouring the stop `CancellationToken` and draining in-flight work.
- **Messaging**: idempotent consumers ALWAYS (at-least-once is the reality); DLQ with an alert and a runbook; atomic publishing with the DB transaction via the **outbox pattern**; versioned message contracts with backward compatibility. The broker's official client or MassTransit/Wolverine if it helps — no home-made bus.
- **Caching**: **HybridCache** (.NET 9+) or `IMemoryCache`/Redis with a TTL ALWAYS defined and a versioned key; invalidation designed, not "it will expire eventually". Never cache responses with authorisation data mixed between users.
- **Native AOT where appropriate**: candidates = serverless/Lambda, CLI, sidecar, critical startup and memory. It requires Minimal APIs + `CreateSlimBuilder` + **System.Text.Json source generators**; **EF Core is NOT an AOT candidate** (use Dapper AOT/ADO.NET on that route). Decide AOT up front (it restricts reflection and libraries), publish and test the AOT binary in CI. For everything else: JIT with ReadyToRun/tiered PGO is already excellent — no AOT out of fashion.

## 7. Long-term sustainability

**Upgrade cadence.**
- Runtime: **LTS to LTS** (10 → 12 in Nov 2027) with the migration completed before the EOL of the previous one; monthly .NET patches via the base image/SDK without delay (support requires the latest patch).
- STS only if a feature justifies it, with a written commitment to jump to the next LTS.
- NuGet: Renovate/Dependabot with automerge for patches and a reviewed PR for minors; majors with the changelog read.
- C#/analyzers: adopt the TFM's `LangVersion` at every upgrade; go through the official breaking changes of each version.
- A package with no release in >18 months or with no response to CVEs = replacement candidate; decision recorded (short ADR).
- `.NET Upgrade Assistant` as support on majors, with manual review of the result — never a blind upgrade.

**Deprecation.** `[Obsolete]` with a message stating the replacement and the removal version; every obsolescence warning opens an issue. Nothing is suppressed without a reason and a link.

**PROHIBITIONS (banned anti-patterns).**
- ❌ `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` over async code (deadlocks/pool starvation); `async void` outside event handlers.
- ❌ `<Nullable>disable</Nullable>` in new projects; `!` without a comment; public APIs with gratuitous `object`/`dynamic`.
- ❌ EF InMemory provider as a double for the real DB in tests; `EnsureCreated()` in production; EF entities exposed in the API.
- ❌ Concatenating input into SQL; `BinaryFormatter`; open polymorphic deserialisation.
- ❌ `new HttpClient()` per request (socket exhaustion) — always `IHttpClientFactory`; HTTP calls without timeout/resilience.
- ❌ `catch (Exception) { }` or log-and-continue with no decision; exceptions as flow control.
- ❌ Secrets in `appsettings.json`/repo/logs; `AllowAnyOrigin` with credentials; endpoints without `RequireAuthorization` by default.
- ❌ `DateTime.Now` for logic (UTC + `TimeProvider`); implicit culture in parsing/formatting (always `CultureInfo.InvariantCulture` or explicit).
- ❌ `Thread.Sleep`/polling in tests; `Task.Delay` as synchronisation.
- ❌ Newtonsoft.Json in new code without a dependency that demands it; AutoMapper for trivial mappings a method/record solves.
- ❌ NuGet versions scattered across `.csproj` (CPM mandatory); `latest` in images; SDK without `global.json`.
- ❌ Staying on an unsupported runtime (today: .NET ≤9 after 2026-11-10; .NET Framework 4.x for new services).
- ❌ Business logic in controllers/endpoints (binding, validation and delegation only); "God services" with dozens of injected dependencies.
- ❌ Reflection in hot paths or in AOT projects when a source generator solves the same thing (JSON, logging, regex: `[GeneratedRegex]`).
- ❌ `Console.WriteLine` in services instead of `ILogger`; logs with interpolation in hot paths instead of `LoggerMessage`.

**"Done" checklist for changes in this stack.**
- [ ] `csharpier check .` + `dotnet build -warnaserror` + `dotnet test` green locally (analyzers and nullable included).
- [ ] Edges and errors covered by tests (null/empty, cancellation, culture); bugfix with a regression test.
- [ ] No secrets or PII in the code, config or logs added; new endpoints with `RequireAuthorization`/an explicit policy.
- [ ] New `HttpClient`/queries with timeout and resilience defined; EF migrations backward compatible and applied by the pipeline.
- [ ] New dependencies: justified, licence verified, version in `Directory.Packages.props`, no CVEs (`dotnet list package --vulnerable`).
- [ ] If the project is AOT: AOT `dotnet publish` and binary smoke test verified in CI.
- [ ] Metrics/traces/logs cover the new functionality (it can be operated without RDP/SSH).

## 8. Mandatory web verification

Before pinning a version or an API in a project, check online (not from memory):
- **Current LTS/STS and EOL dates**: dotnet.microsoft.com/platform/support/policy and endoflife.date/dotnet (is 10 still the current LTS? has 11 STS shipped — Nov 2026 — or the next LTS?). Latest patch available (support requires it).
- **Breaking changes** official for the specific jump: learn.microsoft.com "Breaking changes in .NET X" before any upgrade.
- **EF Core**: news and AOT status at learn.microsoft.com/ef/core (still no full AOT support?); provider compatibility (Npgsql, SqlClient) with the version.
- **xUnit v3** (xunit.net/releases) and the state of MTP vs VSTest — the runner changes with the SDK; **Testcontainers for .NET** (dotnet.testcontainers.org) latest version.
- **CSharpier** (github.com/belav/csharpier/releases) and the third-party analyzers chosen (SonarAnalyzer, Meziantou): version and SDK compatibility.
- **Licences** of testing/utility libraries (e.g. FluentAssertions changed its licence): verify before adding.
- **Active CVEs** in the stack (ASP.NET Core, Kestrel, SqlClient/Npgsql, System.Text.Json) at github.com/dotnet/announcements and NVD before freezing versions.

If the web contradicts this document, **the web wins** — flag the discrepancy.
