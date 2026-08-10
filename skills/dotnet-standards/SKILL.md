---
name: dotnet-standards
description: C#/.NET engineering standards for backend services. Triggers on C#, .NET, dotnet, ASP.NET Core, EF Core, Entity Framework, NuGet, xUnit, Blazor, Native AOT, .cs/.csproj/.sln/.slnx files, Directory.Build.props, Directory.Packages.props, appsettings.json.
---

# Estándares .NET: C# / ASP.NET Core

Criterio por defecto para proyectos C#/.NET. Fija decisiones; no es un tutorial.
Datos de versión verificados a **2026-08**: SIEMPRE re-verificar por web antes de fijar en un proyecto (ver sección 8).

## 1. Alcance y triggers

- Aplica a: servicios backend C# (APIs, workers, gRPC), librerías NuGet internas, tooling CLI en .NET.
- Triggers: ficheros `.cs`, `.csproj`, `.sln`/`.slnx`, `Directory.Build.props`, `Directory.Packages.props`, `global.json`, `appsettings*.json`, `.editorconfig`; menciones a .NET, ASP.NET Core, EF Core, NuGet, xUnit, Native AOT.
- **No aplica**: Unity (versión de C#/runtime propia). **El legacy de Microsoft tiene dueños
  propios**, y la frontera va en las dos direcciones: `dotnet-framework-legacy-standards`
  (**.NET Framework 4.x**: mantenimiento, lo que no tiene puerto —WebForms, WCF de servidor,
  Workflow, `AppDomain`, *remoting*— y la ruta de migración), `vbnet-standards` (**el lenguaje
  VB.NET, congelado por decisión de Microsoft**), `vb6-standards` y `classic-asp-standards`
  (**sin soporte de IDE ni de lenguaje: congelar, aislar o reescribir**) y `pascal-delphi-standards`
  (**Delphi / Object Pascal como origen habitual de migración a .NET**: el criterio de contención y
  salida de esa plataforma es suyo). **Lo que sí es de aquí, y
  conviene decirlo alto: el destino de cualquiera de esas migraciones** — la calidad del código
  resultante (SDK, versión LTS, ASP.NET Core, EF Core, NuGet, publicación, contenedor) se rige por
  esta skill, no por la de origen. Ver también `api-design-standards` (diseño del contrato HTTP/gRPC — aquí solo su
  implementación con Minimal APIs/ASP.NET Core), `microservices-architecture-standards` (corte de
  servicios, eventos, sagas, resiliencia distribuida), `appsec-standards` (modelado de amenazas y
  clases de vulnerabilidad agnósticas del stack; aquí solo los sinks y flags concretos de .NET),
  `data-platform-standards` (modelado, índices y tuning del motor; aquí solo EF Core y sus
  migraciones), `sql-standards` (**el lenguaje SQL**, incluido el que EF Core genera y el que se
  escribe a mano en `FromSql`: joins, CTEs, `NULL`, predicados SARGables y parametrización),
  `webassembly-standards` (Blazor WebAssembly y `dotnet wasm` compilan a Wasm — el
  runtime, los límites del sandbox y **el tamaño del artefacto descargado**, que aquí es la métrica
  crítica, se deciden con su criterio; el C#/F# y su build, aquí),
  `ocaml-fsharp-standards` (**el lenguaje F#**: idiomas, uniones discriminadas, *computation
  expressions*, modelado del dominio con tipos, `Fantomas`, `Expecto`/`FsCheck`, y la frontera de
  interoperabilidad con C# —`null` frente a `Option`—. Arbitraje: **el SDK, la versión LTS,
  `Directory.Build.props`, NuGet, la publicación, el runtime, ASP.NET Core, el hosting y la
  contenedorización se deciden aquí, aunque el código sea F#**; cómo se escribe ese F#, allí. Un
  `.fs` no enruta solo a esta skill),
  `powershell-standards` (**PowerShell corre sobre .NET y esa cercanía es la confusión**: si el
  problema pide una **aplicación** —servicio, API, biblioteca, binario distribuible—, manda esta
  skill; si pide **automatización administrativa** —un script, un módulo, una tarea sobre AD o
  sobre la máquina—, manda `powershell-standards`. La versión de .NET sobre la que corre PowerShell
  se decide aquí; cómo se escribe el script, allí), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen
  OCI, Native AOT en contenedor y despliegue), `azure-standards` (los servicios gestionados donde
  suele desplegarse; aquí solo el código), `observability-standards` (pipeline OTel; aquí solo la
  instrumentación), `git-workflow-standards` (rama, commits y tagging SemVer; la publicación en
  NuGet sí es de esta skill), `identity-access-management-standards` (diseño del IdP y de Entra ID;
  aquí solo cómo lo consume el servicio).

## 2. Toolchain por defecto

> Verificar última versión por web antes de fijar en un proyecto; las de abajo son el mínimo aceptable (estado 2026-08).

| Pieza | Elección | Mínimo (2026-08) | Nota |
|---|---|---|---|
| Runtime/SDK | **.NET 10 (LTS)** — soporte hasta 2028-11 | 10.0.x | .NET 8 y 9 mueren el 2026-11-10: migrar YA; STS (11, nov 2026) solo con motivo y plan |
| Lenguaje | **C# 14** (`LangVersion` implícito del TFM) | 14 | No fijar `LangVersion` inferior sin ADR |
| Web | **ASP.NET Core 10** — Minimal APIs por defecto | 10 | Controllers solo si el proyecto ya los usa o hay necesidad real (filters complejos, ApiConventions) |
| Datos | **EF Core 10** + provider oficial | 10 | Dapper/ADO.NET para hot paths medidos o escenarios AOT |
| Testing | **xUnit v3** (`xunit.v3`) + Testcontainers for .NET | 3.2.x | Sobre **Microsoft.Testing.Platform (MTP)**, no VSTest; v2 está en mantenimiento |
| Asserts/dobles | AssertJ-style: FluentAssertions o Shouldly; NSubstitute | actual | Verificar licencia de FluentAssertions ≥8 antes de elegir |
| Formatter | **CSharpier** + `dotnet format` (estilo/analyzers) | 1.3.x | CSharpier para layout; `.editorconfig` para naming/estilo semántico |
| Análisis | **Roslyn analyzers del SDK** + `.editorconfig` estricto | SDK 10 | `AnalysisLevel=latest-all`; añadir SonarAnalyzer.CSharp o Meziantou.Analyzer si se quiere más señal |
| SCA/deps | `dotnet list package --vulnerable` + NuGetAudit + Dependabot/Renovate | SDK 10 | Gate en CI |
| Contenedores | `dotnet publish /t:PublishContainer` o Dockerfile chiseled | — | Imágenes `mcr` chiseled/distroless, non-root |

- `global.json` versionado fijando la banda del SDK (`rollForward: latestFeature`): builds reproducibles.
- **Central Package Management** (`Directory.Packages.props`) obligatorio: versiones NuGet en un único sitio.
- `Directory.Build.props` raíz con las propiedades comunes: `<Nullable>enable</Nullable>`, `<ImplicitUsings>enable</ImplicitUsings>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<AnalysisLevel>latest-all</AnalysisLevel>`, `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`.

## 3. Estructura y convenciones de proyecto

- Solución por dominio: `src/` + `tests/`; proyectos por límite real (Api, Application, Domain, Infrastructure) solo si el dominio lo amerita — un proyecto bien organizado por features vence a 8 proyectos anémicos. **Organización por feature/vertical slice**, no por capa técnica global.
- **Nullable reference types activados en TODO** (`<Nullable>enable</Nullable>` global); `!` (null-forgiving) requiere comentario-motivo; ninguna API pública con nulabilidad ambigua.
- DTOs y mensajes como **records** inmutables; `required`/`init` en vez de setters públicos. Entidades EF nunca expuestas en la API.
- DI del contenedor nativo (`Microsoft.Extensions.DependencyInjection`); registro por feature con extension methods (`services.AddBilling()`); lifetimes conscientes (nada de capturar scoped en singleton).
- Configuración tipada con el **Options pattern** (`IOptions<T>` + `ValidateDataAnnotations().ValidateOnStart()`); prohibido `IConfiguration["clave"]` disperso.
- Errores: excepciones de dominio + `IExceptionHandler`/middleware único que mapea a **ProblemDetails (RFC 9457)**; `Result<T>` opcional para flujos esperables, pero un solo patrón por solución.
- `async/await` de extremo a extremo con `CancellationToken` propagado en toda API pública async; sin `async void` (solo event handlers).

**Contratos de API.**
- OpenAPI generado del código con **`Microsoft.AspNetCore.OpenApi`** (nativo desde .NET 9; Swashbuckle solo en legado); el spec es artefacto de CI y los breaking changes de contrato se detectan en pipeline (openapi-diff).
- Versionado de API explícito desde el día uno (**Asp.Versioning**, path `/v1` o media type); nunca romper `v1` para añadir `v2`.
- Paginación obligatoria en toda colección (límite acotado por servidor); mutaciones no idempotentes con soporte de **Idempotency-Key** cuando haya reintentos de clientes.
- Fechas/horas en API siempre ISO-8601 UTC (`DateTimeOffset`/`DateOnly`); dinero con `decimal` + moneda explícita, jamás `double`.

**Concurrencia y estado.**
- Servicios sin estado mutable compartido; estado en stores externos (BD/Redis) o estructuras concurrentes justificadas (`Channel<T>` acotado, `ConcurrentDictionary`).
- Transacciones en el borde de aplicación (una operación de negocio = una transacción/`SaveChanges`); prohibido IO remoto dentro de una transacción de BD abierta.
- Concurrencia sobre la misma fila: **concurrencia optimista** de EF (`rowversion`/token) por defecto; bloqueo pesimista solo con contención medida.

## 4. Calidad

**Formatter.** CSharpier como autoridad de layout (opinionated, cero debate); `dotnet format` para reglas de estilo del `.editorconfig`. Ambos con verificación en CI (`csharpier check .`, `dotnet format --verify-no-changes`).

**Análisis estático (gates, no sugerencias).**
- `AnalysisLevel=latest-all` + `TreatWarningsAsErrors=true` en `Directory.Build.props`; severidades afinadas en `.editorconfig` versionado (categorías CA + reglas IDExxxx).
- Nullable warnings SIEMPRE como error (los cubre TreatWarningsAsErrors); `#pragma warning disable` requiere motivo y enlace a issue.
- `EnforceCodeStyleInBuild=true` para que el estilo rompa el build, no solo el IDE.

**Testing.**
- Unitarios: **xUnit v3** sobre MTP; rápidos, deterministas, sin infraestructura. Cubren camino feliz, **bordes y errores** (null/empty, límites, cancelación, cultura/encoding, concurrencia donde aplique). `[Theory]` para tablas de casos.
- Integración: `WebApplicationFactory` para el pipeline HTTP real + **Testcontainers for .NET** con la MISMA imagen de BD que prod (versión pinneada). **Prohibido InMemory provider de EF como doble de la BD real** (no valida SQL, transacciones ni constraints); SQLite solo para tests de lógica sin SQL específico.
- `TimeProvider` inyectado en vez de `DateTime.UtcNow` directo cuando el tiempo afecta a la lógica (testeable sin hacks).
- Reglas de arquitectura como test: **NetArchTest/ArchUnitNET** (dependencias entre proyectos/features, "Domain no referencia Infrastructure") — el diagrama se verifica, no se dibuja.
- Cobertura con **coverlet** como señal (umbral orientativo sobre líneas nuevas vía diff-coverage), nunca meta que fabrica tests vacíos.
- Todo bugfix deja test de regresión. Un test flaky se arregla o se borra.

**Gates de CI (build roto si falla cualquiera):** format check → `dotnet build -warnaserror` (analyzers incluidos) → tests unit → tests integración (Testcontainers) → `dotnet list package --vulnerable --include-transitive` / NuGetAudit → publish de smoke (y del binario AOT si aplica).

## 5. Seguridad del stack

- **AuthN/AuthZ**: JWT bearer (`AddAuthentication().AddJwtBearer()`) con issuer/audience/lifetime validados; **políticas de autorización con nombre** (`AddAuthorizationBuilder().AddPolicy(...)`) y `RequireAuthorization()` por defecto en los grupos de endpoints — deny-by-default, `[AllowAnonymous]` es la excepción explícita. Identity/OpenIddict o IdP externo (Entra ID, Keycloak) antes que auth casera.
- **Inyección**: EF Core parametriza por defecto; SQL crudo solo con `FromSql`/interpolación segura de EF o parámetros ADO — nunca concatenación. Validación en el borde (DataAnnotations/FluentValidation) sobre DTOs de entrada, límites de tamaño de payload (`RequestSizeLimit`) y de paginación.
- **Secretos**: User Secrets solo en dev; en prod, env vars / Key Vault / AWS Secrets Manager vía `IConfiguration` providers. Escaneo de secretos en CI (el escáner lo fija `secrets-management-standards`); nunca en `appsettings.json` ni en el repo.
- **Serialización**: `System.Text.Json` (no Newtonsoft en código nuevo salvo dependencia dura); prohibido `BinaryFormatter` (eliminado en .NET 9+, no reintroducir) y deserialización polimórfica abierta sin discriminadores cerrados.
- **Headers y transporte**: HTTPS/HSTS, cabeceras de seguridad vía middleware; CORS con allowlist explícita, nunca `AllowAnyOrigin` + credenciales.
- **SSRF**: URLs de entrada validadas contra allowlist antes de que `HttpClient` las toque; `HttpClient` SIEMPRE vía `IHttpClientFactory`.
- **Dependencias**: NuGetAudit activo (falla con vulnerabilidad alta/crítica), lockfiles (`RestorePackagesWithLockFile`) en CI, Dependabot/Renovate; paquetes sin mantenimiento o con CVE sin parche = sustituir y registrar (ADR).
- **Hardening runtime**: contenedores chiseled/distroless `mcr.microsoft.com/dotnet/*`, non-root (default en .NET 8+: usuario `app`), read-only FS, capabilities mínimas.
- **Passwords y cripto**: Identity/`PasswordHasher` (o Argon2/bcrypt vía librería mantenida) para credenciales propias; **Data Protection API** con key ring persistido y compartido entre réplicas (nunca claves efímeras por pod); AES-GCM/`RandomNumberGenerator` del BCL, nada casero ni MD5/SHA-1 para seguridad.
- **Auditoría**: eventos de seguridad (login, cambios de permisos, accesos a datos sensibles) en log estructurado con actor + acción + recurso; PII enmascarada en todos los logs (redaction de `Microsoft.Extensions.Compliance` donde aplique).

## 6. Rendimiento y operabilidad

- **Timeouts y resiliencia explícitos**: `Microsoft.Extensions.Http.Resilience` (handler estándar: timeout total + por intento, retry con backoff+jitter solo en idempotentes, circuit breaker) en todo `HttpClient`; `CommandTimeout` en EF/ADO; **request timeouts middleware** en endpoints. Sin timeout definido = bug.
- **Límites**: Kestrel con límites de concurrencia/tamaño revisados; rate limiting middleware (`AddRateLimiter`) en APIs públicas; backpressure en colas (Channels acotados, no `Unbounded` por defecto).
- **Asignaciones bajo control en hot paths medidos**: `Span<T>`/`Memory<T>`, `ArrayPool`, `IAsyncEnumerable` para streaming — optimizar con BenchmarkDotNet y perfiles, nunca a ojo.
- **EF Core con criterio**: `AsNoTracking` en lecturas, proyecciones a DTO, `AsSplitQuery` contra explosión cartesiana, consultas compiladas en hot paths; migraciones versionadas aplicadas por pipeline (no `Database.Migrate()` al arrancar réplicas concurrentes), expand/contract para compatibilidad.
- **Observabilidad**: `Microsoft.Extensions.Telemetry` + **OpenTelemetry** (trazas, métricas, logs correlacionados; OTLP export); logging estructurado con `ILogger` + source-generated `LoggerMessage` en hot paths (nunca interpolación de strings en logs calientes); health checks (`AddHealthChecks` + endpoints liveness/readiness separados).
- **Graceful shutdown**: `IHostApplicationLifetime` respetado, `HostOptions.ShutdownTimeout` alineado con `terminationGracePeriodSeconds` de K8s; workers con `BackgroundService` que honran el `CancellationToken` de parada y drenan trabajo en curso.
- **Mensajería**: consumidores idempotentes SIEMPRE (at-least-once es la realidad); DLQ con alerta y runbook; publicación atómica con la transacción de BD vía **outbox pattern**; contratos de mensajes versionados con compatibilidad backward. Cliente oficial del broker o MassTransit/Wolverine si aporta — no bus casero.
- **Caching**: **HybridCache** (.NET 9+) o `IMemoryCache`/Redis con TTL SIEMPRE definido y clave versionada; invalidación diseñada, no "ya caducará". Nunca cachear respuestas con datos de autorización mezclados entre usuarios.
- **Native AOT si procede**: candidatos = serverless/Lambda, CLI, sidecar, arranque y memoria críticos. Requiere Minimal APIs + `CreateSlimBuilder` + **source generators de System.Text.Json**; **EF Core NO es candidato AOT** (usar Dapper AOT/ADO.NET en esa ruta). Decidir AOT al inicio (restringe reflexión y librerías), publicar y probar el binario AOT en CI. Para el resto: JIT con ReadyToRun/tiered PGO ya es excelente — no AOT por moda.

## 7. Sostenibilidad a largo plazo

**Cadencia de upgrades.**
- Runtime: **LTS a LTS** (10 → 12 en nov 2027) con migración completada antes del EOL del anterior; parches mensuales de .NET vía imagen base/SDK sin demora (el soporte exige el último patch).
- STS solo si una feature lo justifica, con compromiso escrito de saltar al siguiente LTS.
- NuGet: Renovate/Dependabot con automerge de patches y PR revisada para minors; majors con changelog leído.
- C#/analyzers: adoptar el `LangVersion` del TFM en cada upgrade; recorrer breaking changes oficiales de cada versión.
- Paquete sin release en >18 meses o sin respuesta a CVEs = candidato a sustitución; decisión registrada (ADR corto).
- `.NET Upgrade Assistant` como apoyo en majors, con revisión manual del resultado — nunca upgrade a ciegas.

**Deprecación.** `[Obsolete]` con mensaje que indica el reemplazo y versión de retirada; todo warning de obsolescencia abre issue. Nada se suprime sin motivo y enlace.

**PROHIBICIONES (anti-patrones vetados).**
- ❌ `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` sobre código async (deadlocks/pool starvation); `async void` fuera de event handlers.
- ❌ `<Nullable>disable</Nullable>` en proyectos nuevos; `!` sin comentario; APIs públicas con `object`/`dynamic` gratuitos.
- ❌ EF InMemory provider como doble de la BD real en tests; `EnsureCreated()` en producción; entidades EF expuestas en la API.
- ❌ Concatenar input en SQL; `BinaryFormatter`; deserialización polimórfica abierta.
- ❌ `new HttpClient()` por petición (socket exhaustion) — siempre `IHttpClientFactory`; llamadas HTTP sin timeout/resiliencia.
- ❌ `catch (Exception) { }` o log-and-continue sin decisión; excepciones como control de flujo.
- ❌ Secretos en `appsettings.json`/repo/logs; `AllowAnyOrigin` con credenciales; endpoints sin `RequireAuthorization` por omisión.
- ❌ `DateTime.Now` para lógica (UTC + `TimeProvider`); cultura implícita en parseo/formato (siempre `CultureInfo.InvariantCulture` o explícita).
- ❌ `Thread.Sleep`/polling en tests; `Task.Delay` como sincronización.
- ❌ Newtonsoft.Json en código nuevo sin dependencia que lo exija; AutoMapper para mapeos triviales que un método/record resuelve.
- ❌ Versiones NuGet dispersas por `.csproj` (CPM obligatorio); `latest` en imágenes; SDK sin `global.json`.
- ❌ Quedarse en un runtime fuera de soporte (hoy: .NET ≤9 tras 2026-11-10; .NET Framework 4.x para servicios nuevos).
- ❌ Lógica de negocio en controllers/endpoints (solo binding, validación y delegación); "God services" con decenas de dependencias inyectadas.
- ❌ Reflexión en hot paths o en proyectos AOT cuando un source generator resuelve lo mismo (JSON, logging, regex: `[GeneratedRegex]`).
- ❌ `Console.WriteLine` en servicios en vez de `ILogger`; logs con interpolación en caliente en lugar de `LoggerMessage`.

**Checklist de "done" para cambios en este stack.**
- [ ] `csharpier check .` + `dotnet build -warnaserror` + `dotnet test` verdes en local (analyzers y nullable incluidos).
- [ ] Bordes y errores cubiertos por test (null/empty, cancelación, cultura); bugfix con test de regresión.
- [ ] Sin secretos ni PII en código, config o logs añadidos; endpoints nuevos con `RequireAuthorization`/política explícita.
- [ ] `HttpClient`/consultas nuevos con timeout y resiliencia definidos; migraciones EF compatibles hacia atrás y aplicadas por pipeline.
- [ ] Dependencias nuevas: justificadas, licencia verificada, versión en `Directory.Packages.props`, sin CVEs (`dotnet list package --vulnerable`).
- [ ] Si el proyecto es AOT: `dotnet publish` AOT y smoke del binario verificados en CI.
- [ ] Métricas/trazas/logs cubren la funcionalidad nueva (se puede operar sin RDP/SSH).

## 8. Verificación web obligatoria

Antes de fijar versión o API en un proyecto, comprobar online (no de memoria):
- **LTS/STS vigente y fechas EOL**: dotnet.microsoft.com/platform/support/policy y endoflife.date/dotnet (¿sigue 10 como LTS actual? ¿ha salido 11 STS — nov 2026 — o el siguiente LTS?). Último patch disponible (el soporte lo exige).
- **Breaking changes** oficiales del salto concreto: learn.microsoft.com "Breaking changes in .NET X" antes de cualquier upgrade.
- **EF Core**: novedades y estado AOT en learn.microsoft.com/ef/core (¿sigue sin soporte AOT completo?); compatibilidad del provider (Npgsql, SqlClient) con la versión.
- **xUnit v3** (xunit.net/releases) y estado de MTP vs VSTest — el runner cambia con el SDK; **Testcontainers for .NET** (dotnet.testcontainers.org) última versión.
- **CSharpier** (github.com/belav/csharpier/releases) y analyzers de terceros elegidos (SonarAnalyzer, Meziantou): versión y compatibilidad con el SDK.
- **Licencias** de librerías de testing/utilidades (p. ej. FluentAssertions cambió de licencia): verificar antes de añadir.
- **CVEs activos** del stack (ASP.NET Core, Kestrel, SqlClient/Npgsql, System.Text.Json) en github.com/dotnet/announcements y NVD antes de congelar versiones.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
