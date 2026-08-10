---
name: jvm-spring-standards
description: JVM engineering standards for Java/Kotlin backends with Spring Boot. Triggers on Java, Kotlin, Spring Boot, Spring Security, Spring Data, JPA/Hibernate, Gradle, Maven, JUnit, Testcontainers, GraalVM, .java/.kt/.kts files, build.gradle.kts, pom.xml, application.yml.
---

# Estándares JVM: Java/Kotlin + Spring Boot

Criterio por defecto para proyectos backend en la JVM. Fija decisiones; no es un tutorial.
Datos de versión verificados a **2026-08**: SIEMPRE re-verificar por web antes de fijar en un proyecto (ver sección 8).

## 1. Alcance y triggers

- Aplica a: servicios backend Java/Kotlin, APIs REST/gRPC, workers/batch, librerías internas JVM.
- Triggers: ficheros `.java`, `.kt`, `.kts`, `build.gradle(.kts)`, `settings.gradle(.kts)`, `pom.xml`, `application.yml|properties`; menciones a Spring Boot/Security/Data, JPA, Gradle, Maven, JUnit, Testcontainers, GraalVM.
- **No aplica**: Android y Kotlin de app móvil (ver `mobile-standards`). **El legacy Java tiene
  dueño propio**: `jsp-struts-standards` (JSP con *scriptlets*, Struts 1 y 2,
  `struts-config.xml`, *tag libs*, y los servidores de aplicaciones heredados con su barrera
  `javax` → `jakarta`). **Lo que sí es de aquí: el destino de esa migración** — Spring Boot, la
  versión de JDK y la calidad del código resultante se rigen por esta skill. Aviso que ambas
  sostienen: **una aplicación Struts sin parches es un problema de seguridad antes que de
  mantenimiento**, y varias de sus vulnerabilidades figuran en el catálogo de explotadas conocidas
  de CISA. **Otros lenguajes de la JVM** — ver `scala-standards`, `clojure-standards` y `groovy-standards`. Arbitraje
  espejado: **la elección y operación de la JVM se decide aquí** —distribución y versión del JDK,
  GC y su tuning, flags de arranque, JFR, contenedorización de la JVM— **y todo lo que sea Spring
  es de aquí aunque el código no sea Java**; **cómo se escribe el código en Scala, Clojure o
  Groovy y sus builds nativos** —sbt/Mill/scala-cli, `deps.edn`/Leiningen, Gradle y Jenkins como
  DSL— **es de esas skills**. Ver también
  `api-design-standards` (diseño del contrato HTTP/gRPC — aquí solo su implementación con Spring
  MVC/WebFlux), `microservices-architecture-standards` (corte de servicios, eventos, sagas,
  resiliencia distribuida), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad
  agnósticas del stack; aquí solo Spring Security y los sinks concretos de la JVM),
  `data-platform-standards` (modelado, índices, tuning y réplicas; aquí solo JPA/Hibernate y
  Flyway/Liquibase), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards`
  (imagen OCI, Native Image en contenedor y despliegue), `observability-standards` (pipeline
  OTel/Prometheus; aquí solo Micrometer y la instrumentación), `git-workflow-standards` (rama,
  commits y tagging SemVer; la publicación en Maven Central sí es de esta skill),
  `identity-access-management-standards` (diseño del IdP; aquí solo cómo lo consume el servicio).

## 2. Toolchain por defecto

> Verificar última versión por web antes de fijar en un proyecto; las de abajo son el mínimo aceptable (estado 2026-08).

| Pieza | Elección | Mínimo (2026-08) | Nota |
|---|---|---|---|
| JDK | **Java 25 (LTS)** — Temurin/Liberica | 25 | Java 21 solo en legado; Java 26 (non-LTS) prohibido en prod |
| Kotlin | **2.4.x** (compilador K2) | 2.4.0 | Solo la última versión recibe fixes |
| Build | **Gradle con Kotlin DSL** | 9.6.x | Maven solo si el equipo/organización ya lo estandariza |
| Framework | **Spring Boot 4.1.x** (Spring Framework 7) | 4.1.0 | 3.5 alcanzó EOL OSS 2026-06; no arrancar nada en 3.x |
| Testing | **JUnit 6 (Jupiter)** + AssertJ + Testcontainers | JUnit 6.1.x, TC 2.0.x | Testcontainers 2.x usa artefactos `testcontainers-*` (p. ej. `testcontainers-junit-jupiter`, `testcontainers-postgresql`) |
| Mocking | Mockito (Java) / MockK (Kotlin) | actual | Mockear fronteras, no todo |
| Formatter | **Spotless** (`com.diffplug.spotless`) con google-java-format / ktfmt | plugin 8.9+ | ID antiguo `com.diffplug.gradle.spotless` deprecado |
| Análisis Java | **Error Prone** (`net.ltgt.errorprone`) + NullAway | plugin 5.1+ | Error Prone actual exige JDK 21+ para ejecutarse |
| Análisis Kotlin | **Detekt** | 1.23.8 (2.0 aún alpha) | Migrar a `dev.detekt` 2.x cuando sea estable |
| SCA/deps | OWASP Dependency-Check o Dependabot/Renovate + `gradle dependencyUpdates` | actual | Gate en CI |
| Native | **GraalVM for JDK 25** | 25 | Baseline obligatorio con Boot 4 (nuevo formato de metadata) |

- **Toolchains de Gradle** (`java.toolchain`) para fijar el JDK: el build no depende del JDK local.
- **Version catalog** (`gradle/libs.versions.toml`) obligatorio: versiones en un único sitio, sin strings mágicos en los build scripts.
- **Wrapper** (`gradlew` / `mvnw`) versionado en el repo; nadie compila con instalación local.
- Kotlin sobre Java para código nuevo cuando el proyecto no imponga Java; no mezclar ambos en el mismo módulo sin motivo.

## 3. Estructura y convenciones de proyecto

- **Paquetes por feature/dominio** (`com.acme.billing.invoice`), no por capa técnica (`controllers/`, `services/` globales). Dentro de cada feature: web → application → domain → infrastructure, con dependencias solo hacia adentro.
- **Multi-módulo Gradle** cuando haya límites reales que proteger (dominio sin Spring, adaptadores separados); monolito modular antes que microservicios prematuros.
- Inyección **por constructor siempre**; `@Autowired` en campo prohibido. Beans inmutables.
- Configuración tipada con `@ConfigurationProperties` + validación (`@Validated`); prohibido `@Value` disperso.
- DTOs de API como **records** (Java) / **data classes** (Kotlin); nunca exponer entidades JPA en la API.
- Nulabilidad: Kotlin la resuelve por tipo; en Java, **JSpecify** (`@Nullable`/`@NonNull`) + NullAway como gate.
- Errores: excepciones de dominio propias + un único `@RestControllerAdvice` que mapea a **Problem Details (RFC 9457)**. Prohibido capturar `Exception` genérica y silenciar.
- Perfiles: `application.yml` base + `application-{profile}.yml`; secretos NUNCA en esos ficheros (ver §5).

**Contratos de API.**
- Contrato documentado con **springdoc-openapi** generado del código (o contract-first si el equipo lo tiene establecido); el spec publicado es artefacto de CI y los breaking changes del contrato se detectan en pipeline (openapi-diff).
- Versionado de API explícito desde el día uno (path `/v1` o media type); nunca romper `v1` para añadir `v2`.
- Paginación obligatoria en toda colección (limit acotado por servidor); mutaciones no idempotentes con soporte de **Idempotency-Key** cuando haya reintentos de clientes.
- Fechas/horas en API siempre ISO-8601 UTC (`Instant`/`OffsetDateTime`); dinero con `BigDecimal` + moneda explícita, jamás `double`.

**Concurrencia y estado.**
- Beans singleton sin estado mutable; estado compartido solo en stores externos (BD/Redis) o estructuras concurrentes justificadas.
- `@Transactional` en el borde de aplicación (un método = una transacción); prohibido sobre métodos `private`/self-invocation (no aplica el proxy) y prohibido hacer IO remoto dentro de una transacción de BD.
- Operaciones concurrentes sobre la misma fila: bloqueo optimista (`@Version`) por defecto; pesimista solo con contención medida.

## 4. Calidad

**Formatter.** Spotless con google-java-format (Java) y ktfmt o ktlint (Kotlin) — elegir uno y no debatir estilo nunca más. `spotlessCheck` en CI, `spotlessApply` local/pre-commit.

**Análisis estático (gates, no sugerencias).**
- Java: Error Prone en el compilador con severidad error; NullAway con `@NullMarked` a nivel de paquete.
- Kotlin: Detekt con config versionada en el repo; `maxIssues: 0`, baseline solo para adopción en legado y con fecha de caducidad.
- Warnings del compilador como error: `-Werror` (javac) / `allWarningsAsErrors = true` (Kotlin).

**Testing.**
- Unitarios: JUnit 6 + AssertJ; rápidos, deterministas, sin Spring context. Cubren camino feliz, **bordes y errores** (null/blank, límites, timeouts, concurrencia donde aplique). Tests parametrizados para casos de borde.
- Integración: **Testcontainers 2.x** con `@ServiceConnection` para Postgres/Kafka/Redis — la misma imagen (y versión pinneada) que prod. **Prohibido H2 como sustituto de la BD real.**
- Slices de Spring (`@WebMvcTest`, `@DataJpaTest`) antes que `@SpringBootTest` completo; este último solo para smoke E2E del contexto.
- Reglas de arquitectura como test: **ArchUnit** (dependencias entre paquetes/features, "el dominio no importa Spring") — el diagrama se verifica, no se dibuja.
- Cobertura con JaCoCo como **señal** (umbral orientativo en líneas nuevas vía diff-coverage), nunca como meta que fabrica tests vacíos. Mutation testing (Pitest) opcional en módulos de lógica crítica.
- Asincronía en tests con **Awaitility**; relojes inyectados (`Clock` como bean) cuando el tiempo afecta a la lógica.
- Todo bugfix deja test de regresión. Un test flaky se arregla o se borra; no se reintenta.

**Gates de CI (build roto si falla cualquiera):** `spotlessCheck` → compilación con `-Werror` → Error Prone/NullAway/Detekt → tests unit → tests integración (Testcontainers) → SCA. Main siempre verde.

## 5. Seguridad del stack

- **Spring Security siempre**, incluso en servicios "internos": `SecurityFilterChain` como bean, **deny-by-default** (`anyRequest().denyAll()` o `.authenticated()` al final de la cadena, nunca `permitAll` residual).
- APIs stateless: **OAuth2 Resource Server con JWT** validado (issuer, audience, expiración); sesiones solo en apps web server-side, y entonces CSRF activado. No desactivar CSRF "porque molesta".
- Autorización por método (`@PreAuthorize`) para reglas de negocio; no confiar solo en el matching de URLs.
- **Inyección**: repositorios Spring Data o consultas parametrizadas; prohibido concatenar input en JPQL/SQL/comandos. Validación en el borde con Jakarta Validation (`@Valid` en DTOs de entrada).
- **Secretos**: env vars / Vault / Secrets Manager vía Spring Cloud config o buildpacks bindings; escaneo de secretos en CI (el escáner lo fija `secrets-management-standards`). Nunca en `application.yml`, logs ni imágenes.
- **Serialización**: Jackson con tipos cerrados; prohibido `enableDefaultTyping`/deserialización polimórfica abierta y la serialización nativa de Java para datos externos.
- **SSRF**: cualquier URL de entrada se valida contra allowlist antes de que `RestClient`/`WebClient` la toque.
- **Dependencias**: BOM de Spring Boot como fuente de versiones (no sobrescribir versiones gestionadas sin registrar por qué); SCA en CI rompe el build con CVE crítico/alto explotable; Renovate/Dependabot activo.
- **Imagen**: distroless o buildpacks (`bootBuildImage`), non-root, read-only FS; JRE mínimo vía `jlink` si no es nativo. Actuator: exponer solo `health` (y `prometheus` en puerto/red de management), nunca `env`/`heapdump` sin auth.
- Cripto: la del JDK/Spring Security (Argon2/bcrypt para passwords, AES-GCM, TLS 1.2+); nada casero, nada de MD5/SHA-1 para seguridad.
- **Cabeceras y abuso**: security headers (HSTS, `X-Content-Type-Options`, CSP donde aplique) vía la configuración de Spring Security; rate limiting en el borde (gateway) o Bucket4j en el servicio para endpoints sensibles (login, búsqueda).
- **Auditoría**: eventos de seguridad (login, cambios de permisos, accesos a datos sensibles) en log estructurado inmutable con actor + acción + recurso; PII enmascarada en todos los logs.

## 6. Rendimiento y operabilidad

- **Virtual threads ON** (`spring.threads.virtual.enabled=true`) para workloads IO-bound en el stack servlet; cuidado con `synchronized` que ancle (pinning) en dependencias antiguas. WebFlux solo con necesidad real de streaming/backpressure.
- **Timeouts explícitos en TODO cliente**: `RestClient`/`WebClient` (connect + read), JDBC (`loginTimeout`, `socketTimeout`), pool Hikari (`connectionTimeout`, `maxLifetime`); sin timeout por defecto = bug. Retries con backoff+jitter solo en operaciones idempotentes; circuit breaker (Resilience4j) hacia dependencias inestables.
- **Pools acotados y medidos**: Hikari dimensionado con datos (no 100 conexiones "por si acaso"); límites de tamaño de request y de paginación en toda lista.
- **JPA con criterio**: `open-in-view=false` SIEMPRE; fetch explícito (`@EntityGraph`/join fetch) contra N+1; proyecciones/DTOs para lecturas; migraciones con **Flyway** (o Liquibase), `ddl-auto=validate` en prod, expand/contract para cambios compatibles.
- **Observabilidad**: Actuator + Micrometer (métricas Prometheus) + **OpenTelemetry** (trazas + propagación W3C) + logs estructurados JSON (Boot los soporta nativo) con correlación traceId/spanId. Golden signals con alertas accionables.
- **Graceful shutdown**: `server.shutdown=graceful` + `spring.lifecycle.timeout-per-shutdown-phase` alineado con el `terminationGracePeriodSeconds` de K8s; liveness/readiness probes de Actuator (`management.endpoint.health.probes.enabled=true`).
- **Mensajería (Kafka/AMQP)**: consumidores idempotentes SIEMPRE (el at-least-once es la realidad); DLQ con alerta y runbook; publicación atómica con la transacción de BD vía **outbox pattern** (no "guardo y luego publico"); esquemas versionados (Avro/JSON Schema + registry) con compatibilidad backward.
- **Caching**: Spring Cache con Redis/Caffeine, TTL SIEMPRE definido y clave con versión; invalidación diseñada, no "ya se caducará". Nunca cachear respuestas con datos de autorización mezclados entre usuarios.
- **GraalVM native si procede**: candidatos = CLI, serverless, escalado a cero, arranque crítico. Requiere GraalVM 25+ con Boot 4; `RuntimeHintsRegistrar` para reflexión propia (no `reflect-config.json` a mano); los tests de integración corren TAMBIÉN contra el binario nativo en CI. No nativo por moda: JIT + CDS/Project Leyden (AOT cache) suele bastar para servicios de larga vida.

## 7. Sostenibilidad a largo plazo

**Cadencia de upgrades.**
- Spring Boot: cada minor tiene ~12 meses de OSS support — upgrade de minor **cada ≤6 meses**, sin excepción; planificar majors con la release notes de migración.
- JDK: LTS a LTS (25 → siguiente LTS) dentro de los 12 meses de su GA; parches de JDK mensualmente vía imagen base.
- Kotlin/Gradle/plugins: Renovate con merge automático de patches y PR revisada para minors.
- Dependencia sin release en >18 meses o sin respuesta a CVEs = candidata a sustitución; registrar la decisión (ADR corto).

**Deprecación.** Compilar con `-Xlint:deprecation`; todo uso de API deprecada abre issue con versión objetivo de retirada. Nada se suprime (`@SuppressWarnings`) sin comentario-motivo y enlace a issue.

**PROHIBICIONES (anti-patrones vetados).**
- ❌ Inyección por campo (`@Autowired` en atributo) y `@Component` con estado mutable compartido.
- ❌ H2/embedded como doble de la BD de producción en tests de integración.
- ❌ `spring.jpa.open-in-view=true` y `ddl-auto=update|create` fuera de sandbox local.
- ❌ Concatenar input en SQL/JPQL/comandos; deserialización polimórfica abierta de Jackson; serialización nativa Java para datos externos.
- ❌ `csrf().disable()` en apps con sesión; `permitAll` como default; secretos en YAML/properties/repo.
- ❌ Capturar y tragar excepciones (`catch (Exception e) {}` o log-and-continue sin decisión).
- ❌ `@SpringBootTest` como formato por defecto de test; tests con `Thread.sleep` para sincronizar (usar Awaitility).
- ❌ Lombok en código Kotlin; en Java nuevo, preferir records/sealed antes que Lombok (si el repo ya lo usa, solo `@Value`/`@Builder`, nunca `@SneakyThrows`/`@Data` en entidades JPA).
- ❌ `System.out.println` / `printStackTrace` en vez de SLF4J; logs con secretos o PII sin enmascarar.
- ❌ Fijar versiones sueltas que pisan el BOM de Boot sin ADR; `latest` en imágenes; wrapper sin versionar.
- ❌ Utilidades propias para lo que ya resuelve el JDK/Spring (fechas: solo `java.time`; nunca `java.util.Date`/`Calendar`/Joda).
- ❌ Non-LTS (Java 24/26...) en producción.

**Checklist de "done" para cambios en este stack.**
- [ ] `./gradlew spotlessCheck build` verde en local (compila con `-Werror`, pasan Error Prone/NullAway/Detekt y todos los tests).
- [ ] Bordes y errores cubiertos por test (no solo camino feliz); bugfix con test de regresión.
- [ ] Sin secretos ni PII en código, config o logs añadidos; endpoints nuevos con regla de autorización explícita.
- [ ] Clientes/consultas nuevos con timeout definido; migraciones Flyway compatibles hacia atrás.
- [ ] Dependencias nuevas: justificadas, con licencia compatible, versión en el catalog y sin CVEs conocidos.
- [ ] Si el servicio compila a nativo: build e integración del binario nativo verificados, hints registrados.
- [ ] Métricas/trazas/logs cubren la funcionalidad nueva (se puede operar sin SSH).

## 8. Verificación web obligatoria

Antes de fijar versión o API en un proyecto, comprobar online (no de memoria):
- **Java LTS vigente y su fecha de parches**: whichjdk.com / adoptium.net (¿sigue siendo 25 el LTS actual? ¿ha salido el siguiente?).
- **Spring Boot**: última release y ventanas OSS/EOL en endoflife.date/spring-boot y spring.io (¿4.1 sigue soportada? ¿hay 4.2/5.0?). Revisar release notes de migración del salto concreto.
- **Kotlin** (kotlinlang.org/docs/releases.html) y **Gradle** (gradle.org/releases) — y su matriz de compatibilidad mutua y con el JDK elegido.
- **JUnit** (junit.org), **Testcontainers** (java.testcontainers.org) — nombres de artefactos 2.x.
- **Error Prone / NullAway / Detekt / Spotless**: última versión y JDK/Kotlin soportados (Detekt 2.x: ¿ya estable? entonces plugin `dev.detekt`).
- **GraalVM**: versión alineada con el JDK y baseline exigido por la versión de Boot.
- **CVEs activos** del stack (Spring, Tomcat/Netty, Jackson, driver JDBC) en las advisories de spring.io/security y NVD antes de congelar versiones.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
