---
name: scala-standards
description: Scala engineering standards (staff-level). Trigger on .scala/.sc files, build.sbt, project/build.properties, project/plugins.sbt, build.mill/build.sc, scala-cli "//> using" directives, .scalafmt.conf, .scalafix.conf, MiMa/binary-compatibility checks, and on Scala libraries such as cats-effect, fs2, http4s, ZIO, Akka, Apache Pekko, circe, jsoniter-scala, doobie, Slick, munit, ScalaTest, ScalaCheck, weaver, Scala.js or Scala Native. Apply when writing, reviewing, migrating (2.13 to 3) or configuring CI for Scala code, and when choosing between the Typelevel, ZIO and Akka/Pekko ecosystems.
---

# Estándares Scala

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo código Scala: ficheros `.scala`/`.sc`, `build.sbt`, `project/build.properties`, `project/plugins.sbt`, `project/*.scala`, `build.mill`/`build.sc`, directivas `//> using` de scala-cli, `.scalafmt.conf`, `.scalafix.conf`, `.jvmopts`, y los pipelines que compilan/testean Scala. Cubre servicios backend, librerías, CLIs, jobs y la elección estructural de ecosistema de efectos. Fija **criterio**: qué usar, qué está prohibido, qué verificar.

**No aplica**: ver `jvm-spring-standards` (**la JVM en sí y Spring**: distribución y versión del JDK, LTS, GC y su tuning, flags de arranque, JFR, contenedorización de la JVM, jlink/GraalVM, y todo criterio Spring/Spring Boot — si un proyecto Scala usa Spring, **manda `jvm-spring-standards` para Spring**; aquí solo el código Scala, sus builds nativos —sbt/Mill/scala-cli— y sus librerías), `clojure-standards` (el otro lenguaje JVM del catálogo: mismo runtime, paradigmas opuestos —tipado estático estructural vs. dinámico homoicónico—; la elección entre ambos es de **equipo y ecosistema**, no de rendimiento), `data-engineering-standards` y `lakehouse-standards` (**Spark es suyo como plataforma**: pipeline, orquestación, particionado, formato de tabla y coste; **el Scala que se escribe dentro del job —API, tipos, tests, build— es de esta skill**), `streaming-cdc-standards` (Flink/Kafka Streams como plataforma de streaming; aquí solo el código Scala del job), `api-design-standards` (diseño del contrato HTTP/gRPC; aquí solo su implementación con http4s/tapir/ZIO HTTP/Pekko HTTP), `sql-standards` (**el SQL en sí**: esquema, índices, planes — Doobie/Slick/quill generan SQL y ese SQL queda sujeto a su criterio), `data-platform-standards` (modelado y tuning del motor), `microservices-architecture-standards` (corte de servicios, sagas, resiliencia distribuida), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas; aquí solo los sinks concretos de Scala), `vulnerability-management-standards` (triaje y SLA de CVEs; aquí solo el gate de build), `secrets-management-standards`, `observability-standards` (pipeline OTel; aquí solo la instrumentación en código), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen OCI y despliegue), `python-standards`/`go-standards`/`rust-standards` (elección de lenguaje frente a Scala), `groovy-standards` (**el tercer lenguaje JVM del catálogo**, con un papel distinto: hoy es sobre todo lenguaje de configuración de otras herramientas — **el DSL Groovy de Gradle y el `Jenkinsfile` son suyos**, incluido el `build.gradle` de un proyecto Scala que use Gradle en vez de sbt).

## 2. Toolchain y decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Estado a 2026-08 | Nota |
|---|---|---|---|
| Lenguaje | **Scala 3** | Next **3.8.4**; LTS **3.3.8**; **3.9.0 en RC** (RC4) | 3.9 será la nueva línea LTS; 3.8 congela features de cara a ella |
| Baseline JDK | 3.8+/3.9 exigen **JDK 17+**; 3.3 LTS sigue compatible con JDK 8 | — | La **versión del JDK la fija `jvm-spring-standards`**; aquí solo el mínimo que impone el compilador |
| Scala 2 | **2.13.18** (línea mantenida); 2.12 solo por dependencia externa (Spark) | — | Código nuevo en Scala 2 **requiere justificación escrita** |
| Build | **sbt 2.0.x** (GA 2026-06-14; 2.0.4 actual) para proyectos nuevos; **sbt 1.12.x** sigue mantenido | — | sbt 2 exige JDK 17+ y plugins escritos en Scala 3 |
| Build alternativo | **Mill 1.x** (1.1.7) si el equipo prioriza velocidad y legibilidad del build | — | Decisión de equipo, no técnica pura: menos plugins que sbt |
| Scripts/prototipos | **scala-cli 1.16.x** | — | Estándar para scripts, reproducciones de bug y ejemplos de docs |
| Formato | **scalafmt 3.11.x** (Apache-2.0) | — | `.scalafmt.conf` versionado con `version` y `runner.dialect` fijos |
| Refactor/lint | **scalafix 0.14.x** (BSD-3-Clause) | — | Reglas semánticas: `RemoveUnused`, `OrganizeImports`, `DisableSyntax` |
| Test | **munit 1.3.x** por defecto; **ScalaCheck 1.19.x** para propiedades | ScalaTest 3.2.20 (sin release desde 2024-06) | ScalaTest solo si el repo ya lo usa; weaver vive hoy en **typelevel/weaver-test** (0.13.x), activo |
| JSON | **jsoniter-scala 2.39.x** (rendimiento) o **circe 0.14.x** (ergonomía) | — | Elegir uno por repo; no mezclar |
| Compat binaria | **MiMa** en toda librería publicada | — | Gate de CI, no informe |

**Ecosistema de efectos — decisión estructural, se toma una vez por organización y se documenta en ADR.** Las tres pilas son mutuamente excluyentes en la práctica: mezclarlas duplica runtime, tipos de error, pools de hilos y curva de aprendizaje.

| Pila | Cuándo | Estado a 2026-08 |
|---|---|---|
| **Typelevel** (cats-effect 3.7, fs2 3.13, http4s 0.23.x, doobie 1.0.0-RCx) | Default recomendado: modelo de efectos estándar de facto, interoperabilidad amplia, licencias Apache-2.0 | cats-effect 3.7.0 (2025-07); http4s estable sigue en la línea **0.23.x** — la 1.0 lleva años en milestones (M47); doobie sigue en **1.0.0-RC13** (RC de larga duración) |
| **ZIO** (2.1.x, zio-http 3.11.x) | Equipos que quieren una pila integrada y opinada de un solo proveedor (efecto, streams, HTTP, test, config) | ZIO 2.1.26 (2026-05). Sin evidencia de una ZIO 3 publicada |
| **Akka / Apache Pekko** | Solo con necesidad real de **modelo de actores**, cluster sharding o event sourcing (Akka Persistence) | Akka: repo movido a `akka/akka-core`, 2.10.x, **BSL**. Pekko: TLP de la ASF, 1.6.0 estable y 2.0.0-Mx en desarrollo |

**El caso Akka es la decisión de licencia más cara del ecosistema.** Verificado:
- **2022-09-07**: Lightbend anuncia el cambio. Verbatim: *"The new license for Akka is the Business Source License (BSL) v1.1"*, *"After 3 years, the BSL license indefinitely reverts to an Apache 2.0 license"* y *"The commercial license will be available at no charge for early-stage companies (less than US $25 million in annual revenue)"*. El cambio aplica a partir de **Akka 2.7**; las versiones ≤2.6.x publicadas siguen bajo Apache-2.0. **BSL no es licencia open source.**
- **Apache Pekko** es la bifurcación de la comunidad a partir de Akka 2.6.x, hoy **Top-Level Project de la ASF** (graduación anunciada por la ASF el **2024-05-16**), Apache-2.0, con módulos equivalentes (actor, streams, http, persistence, connectors) y adoptada por Flink y Play.
- **Criterio**: para código nuevo, **Pekko**, no Akka. Akka solo con licencia comercial vigente, revisada por legal y con el umbral de ingresos comprobado contra los términos **actuales** (§8) — el umbral de 25 M$ es el del anuncio de 2022, no un dato eterno. Migrar Akka 2.6.x → Pekko es mecánico (renombrado de paquetes) y es el camino por defecto para cualquier base que siguiera en 2.6.x.
- Ojo con la dependencia transitiva: una librería que arrastre `com.typesafe.akka` ≥2.7 mete BSL en tu árbol sin que nadie lo decida. Vetarlo en la política de licencias (§5).

## 3. Estructura y convenciones

**Scala 3 es el presente, con dos matices verificados que cambian el plan de migración**:
- **La interoperabilidad ya no es bidireccional.** Todo Scala 3 consume artefactos 2.13; el TASTy reader de 2.13 (`-Ytasty-reader`) **nunca podrá consumir artefactos de Scala 3.8+** — 3.7 es la última línea legible desde Scala 2. Causa: 3.8 publica `scala-library` compilada con Scala 3.
- Consecuencia operativa: si quedan módulos en 2.13 consumiendo librerías Scala 3, o se pinnan a artefactos ≤3.7 o se termina la migración. El TASTy reader es una **ayuda de migración con fecha de caducidad**, no una capa de compatibilidad permanente.

**Compatibilidad que hay que conocer antes de publicar**: minors de Scala 3 son *backwards* TASTy- y binario-compatibles (*"code compiled with Scala 3.2.x can still be used in Scala 3.3.x, 3.4.x, 3.5.x or any other future version, indefinitely"*); los patches son compatibles en ambos sentidos. Regla derivada: **las librerías se publican contra LTS** (hoy 3.3, mañana 3.9); las aplicaciones van en Next.

- **Cross-building solo cuando hay consumidores reales** en la otra versión. Cross 2.13+3 en una aplicación es coste puro.
- Layout estándar `src/main/scala` / `src/test/scala`; multi-módulo sbt/Mill cuando haya límites que proteger (dominio sin dependencias de framework, adaptadores aparte). Paquetes por dominio, no por capa técnica.
- **`given`/`using` con disciplina**: instancias de type class en el companion del tipo o de la type class (búsqueda implícita predecible); `given` **siempre con nombre y tipo explícito** en API pública. Prohibido usar `using` para pasar configuración de negocio o contexto de request "porque es cómodo" — eso es un parámetro. Conversiones implícitas: solo vía `Conversion` explícita e importada en el punto de uso; jamás una conversión implícita global.
- **`extension`** sustituye a las implicit classes; agrupar extensiones por tipo y no exportar métodos que colisionen con la API del tipo.
- **Tipos opacos (`opaque type`) para identificadores y unidades** (`opaque type UserId = UUID`) — coste cero en runtime y evitan el intercambio accidental de dos `String`. Newtype con `case class` solo cuando se necesite pattern matching.
- **ADTs con `enum`** (incluidas jerarquías con parámetros) y `sealed trait` solo si la jerarquía necesita más de lo que `enum` expresa. Estados imposibles irrepresentables; `case class` con `Option`/booleanos dispersos es el antipatrón a evitar.
- **Errores tipados, no excepciones**: `Either[DomainError, A]` (o el canal de error del efecto: `IO`+`EitherT`/`MonadError`, `ZIO[R, E, A]`) para todo fallo esperable de dominio. Las excepciones quedan para fallos **no recuperables** y para la frontera con Java. Prohibido `try/catch` como control de flujo y capturar `Throwable`/`NonFatal` para tragarse el error.
- **`Future` está desaconsejado en código nuevo**: evaluación ansiosa (no referencialmente transparente), sin cancelación, sin recursos ligados. Se admite solo en la frontera con librerías Java/Play/Slick que lo impongan, convirtiendo inmediatamente al efecto de la pila (`IO.fromFuture`, `ZIO.fromFuture`).
- **Recursos siempre atados**: `Resource`/`Scope` (o `Using` en código sin efectos). Nada de `close()` manual esperando que no salte una excepción antes.
- `null` no existe en Scala salvo interop Java: envolver en `Option` **en la línea de la llamada**, no tres capas más arriba. `Option.get`, `head` sobre colección posiblemente vacía y `.asInstanceOf` están prohibidos (§7).

**Scala.js y Scala Native — acotados.** Scala.js 1.22.x es la opción madura para compartir modelo de dominio y validaciones entre backend y frontend web; el resto del criterio de frontend (bundling, framework, accesibilidad) **no es de esta skill**. Scala Native 0.5.x es viable para CLIs y arranque rápido (cats-effect 3.7 añade multithreading en Native), pero implica ecosistema recortado y depuración distinta: se adopta con caso de uso escrito, no por moda.

## 4. Calidad: formato, flags, lint y testing

**Flags del compilador (Scala 3) que sí valen** — puestos en `scalacOptions` del build, no en el IDE:

```scala
scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation", "-feature", "-unchecked",
  "-Wunused:all",          // disponible desde 3.3.4+
  "-Wvalue-discard",       // resultados descartados silenciosamente
  "-Wnonunit-statement",
  "-Werror",               // ver nota
  "-Wconf:cat=deprecation:ws,any:e",  // deprecaciones como aviso, el resto error
  "-source:3.8"            // fijar el nivel de source explícitamente
)
```
- **`-Werror`, no `-Xfatal-warnings`**: verificado — `-Xfatal-warnings` es un alias heredado **deprecado desde Scala 3.8**. `-Wall` existe desde 3.5.2+ (backport a 3.3.5+) como interruptor amplio.
- `-Werror` **activo en CI siempre**; localmente se puede relajar (`-Wconf`), pero el build de CI es la verdad. Excepción puntual con `@nowarn("msg=...")` acotado y comentario de motivo, nunca `-Wconf:any:s` global.
- Al ejecutar scalafix, desactivar fatal warnings en esa tarea: si no, el compilador rompe el build antes de que scalafix corrija.
- **sbt-tpolecat** es aceptable para no mantener la lista a mano, pero se revisa qué activa: hereda flags que pueden ir por detrás de las deprecaciones de 3.8.

**Formato y refactor.** `scalafmt` con `version` fijada en `.scalafmt.conf` (versiones distintas reformatean distinto → diffs fantasma); `scalafmtCheckAll` en CI. `scalafix` con `RemoveUnused`, `OrganizeImports` y **`DisableSyntax`** configurado para vetar por build lo que §7 prohíbe (`null`, `throw`, `var`, `asInstanceOf`, `Option.get`) en los módulos de dominio.

**Testing.**
- **munit** por defecto (rápido, sin DSL propio que aprender); `munit-cats-effect`/`zio-test` según pila. ScalaTest solo por inercia de repo.
- **ScalaCheck / property-based obligatorio** en toda lógica con invariantes (parsers, serialización round-trip, aritmética de dominio, reglas de negocio con casos combinatorios). Un test de propiedad bien elegido sustituye a veinte ejemplos.
- Cobertura de **bordes y errores**: cada variante del ADT de error, colecciones vacías, límites numéricos, timeouts y **cancelación** del efecto (un test que solo prueba el camino feliz de `IO` no prueba nada de su semántica).
- Tiempo virtual (`TestControl` de cats-effect, `TestClock` de ZIO) en vez de sleeps reales; **prohibido `Thread.sleep` y `Await.result` en tests**.
- Integración contra dependencias reales con **testcontainers-scala** (misma imagen y versión que prod); prohibido H2 como sustituto de la BD real.
- Todo bugfix deja test de regresión. Test flaky: se arregla o se borra.
- Cobertura (`scoverage`) como señal, nunca como meta.

**Gates de CI, en orden de coste creciente (rompen el build):**
```
scalafmtCheckAll  →  scalafixAll --check  →  compile con -Werror  →  test  →  mimaReportBinaryIssues (librerías)  →  SCA de dependencias
```
Main siempre verde; no se mergea con CI roja.

**Tiempos de compilación: son un problema de ingeniería, no una queja.** Un ciclo de compilación de minutos destruye el feedback y empuja al equipo a saltarse tests.
- Presupuesto explícito (p. ej. compilación incremental de un módulo <20 s) y medición con `-Vprofile` / `-Ystatistics` cuando se degrade.
- Causas habituales y accionables: macros e inline agresivo, derivación automática de codecs en cada punto de uso (**derivar una vez en el companion, no `deriveEncoder` inline por llamada**), implicit search profunda, jerarquías de tipos muy genéricas, módulos monolíticos.
- Partir en módulos con dependencias reales, usar `Test / parallelExecution` con criterio, `bloop`/servidor de build en local, caché de CI (sbt 2 trae caché compatible con Bazel; Mill cachea por tarea).
- Antes de "optimizar Scala", medir: la mayoría de builds lentos son un módulo y tres ficheros.

## 5. Seguridad del stack

- **Deserialización**: el riesgo real de la JVM. Prohibida la serialización nativa de Java para datos externos y cualquier deserialización polimórfica abierta (Jackson `enableDefaultTyping`, `@JsonTypeInfo` sin allowlist). En Scala se resuelve con codecs **derivados de tipos cerrados**: `jsoniter-scala` (macros en compilación, sin reflexión, el más rápido) o `circe` (`deriveDecoder` explícito en el companion). Todo ADT deserializado desde entrada externa lleva discriminador explícito y conjunto cerrado de subtipos.
- Límites en el parseo de entrada no confiable: tamaño máximo de body en el servidor HTTP, profundidad/longitud del JSON (jsoniter expone `ReaderConfig` con `maxBufSize`/profundidad), timeouts de lectura. Un decoder sin límites es un DoS.
- **Validación en el borde con tipos**: parsear a un tipo de dominio (`Either[Error, Email]`), no validar y seguir con `String`. *Parse, don't validate.*
- **SQL solo parametrizado**: `doobie`/`Slick`/`quill` con interpolación segura (`sql"..."` de doobie es parametrizada); prohibido construir SQL con `s"..."` o `+` sobre input. El criterio del SQL resultante es de `sql-standards`.
- **Dependencias en un ecosistema con historial de rupturas binarias** — regla dura:
  - `evictionErrorLevel` en error y **cero evictions no gestionadas**: dos versiones minor distintas de una librería Scala en el classpath es un `NoSuchMethodError` en producción esperando su momento.
  - Alinear la pila entera a una sola línea (cats-effect 3.x completa; no mezclar módulos de ZIO 1 y 2).
  - `sbt-dependency-graph`/`dependencyBrowseTree` para auditar el árbol antes de añadir nada; toda dependencia nueva es una decisión de confianza que se justifica.
  - Librería sin release en >18 meses o con RC eterno: se acepta solo con decisión registrada (caso doobie 1.0.0-RCx y http4s 0.23.x: son estables *de facto* y ampliamente desplegadas, pero la numeración no es garantía — la garantía es la política de compatibilidad binaria del proyecto).
  - **Política de licencias en el gate**: allowlist (Apache-2.0, MIT, BSD, EPL-2.0…) y **denylist explícita de BSL/SSPL/Elastic** — así el Akka ≥2.7 transitivo rompe el build en vez de aparecer en una auditoría.
- **SCA en CI**: escaneo de dependencias (el escáner concreto y el SLA de triaje los fija `vulnerability-management-standards`) que rompe el build ante CVE crítico/alto explotable. Programado además del PR, porque los CVE aparecen sin que cambie el código.
- **Cadena de suministro del build**: los plugins de sbt y las tareas de Mill **ejecutan código arbitrario con los permisos del runner**. Plugins pinneados por versión, de fuentes conocidas, revisados al actualizar; `project/build.properties` versionado; nada de resolvers HTTP no cifrados ni snapshots en builds de release.
- **Secretos**: nunca en `build.sbt`, `application.conf` versionado, logs ni mensajes de excepción. Config tipada (`pureconfig`/`ciris`/`zio-config`) con los secretos desde entorno o gestor; envolver en un tipo que redacte en `toString`. Cuidado específico de Scala: **`case class` genera `toString` que imprime todos los campos** — un `case class Config(dbPassword: String)` logueado filtra la contraseña; sobreescribir `toString` o usar un `Secret` opaco.
- Cripto y TLS: los del JDK/librerías estándar (ver `cryptography-pki-standards` para elección de algoritmos). Aleatoriedad de seguridad con `SecureRandom`, nunca `scala.util.Random`.
- Logs sin PII; excepciones de dominio sin datos sensibles en el mensaje (acaban en respuestas de error y en el SIEM).

## 6. Rendimiento y operabilidad

- **La JVM (GC, heap, flags de arranque, JFR, contenedor) es territorio de `jvm-spring-standards`.** Aquí lo específico de Scala:
- **Nunca bloquear el pool de cómputo del efecto**: JDBC, ficheros, llamadas Java bloqueantes y CPU pesada van a un contexto separado (`IO.blocking`/`Sync[F].blocking`, `ZIO.attemptBlocking`, dispatcher dedicado en Pekko). Bloquear el work-stealing pool convierte un servicio en un cuelgue silencioso bajo carga.
- **Backpressure explícita**: fs2/ZIO Streams/Pekko Streams con límites de concurrencia (`parEvalMap(n)`, `mapZIOPar`), colas **acotadas**, y nada de `parTraverse` sobre una lista de tamaño no acotado (fan-out ilimitado contra una dependencia = incidente).
- **Timeouts en todo borde** (cliente HTTP, JDBC, pool de conexiones) y cancelación propagada; los efectos son cancelables — asegurarse de que la operación es *cancel-safe* y libera recursos.
- **Colecciones**: `List` para acceso secuencial, `Vector`/`ArraySeq` para acceso indexado, `LazyList` con cuidado (memoriza). Prohibido `++` en bucle sobre estructuras inmutables (cuadrático) y usar `Seq` en API pública donde importa el rendimiento (puede ser lista enlazada). `view` para encadenar transformaciones sobre colecciones grandes.
- Benchmarks con **JMH** (`sbt-jmh`) antes de afirmar que algo es más rápido; el boxing y las conversiones implícitas de colecciones son los sospechosos habituales.
- **Observabilidad**: `otel4s`/`zio-telemetry`/instrumentación OTel según pila; logs estructurados (`log4cats`, `ZIO Logging`) con traceId. Prohibido `println` en código de servicio. El pipeline y los SLO son de `observability-standards`.
- **Graceful shutdown obligatorio**: `IOApp`/`ZIOAppDefault` gestionan SIGTERM y finalizadores; verificar que el servidor drena conexiones y que los `Resource`/`Scope` cierran pools antes de salir, alineado con el periodo de gracia del orquestador.
- Health endpoints separados: liveness trivial, readiness que comprueba dependencias.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia.** Aplicaciones en **Scala Next**, subiendo de minor en el trimestre siguiente a su release; librerías publicadas contra **LTS**, con salto de LTS planificado dentro del año siguiente a la nueva línea (el LTS anterior tiene patches garantizados *"until at least a year after the release of the next LTS line"*). Dependencias con Scala Steward (estándar del ecosistema) agrupado semanal; majors a mano con changelog. Migración 2.13 → 3: planificar antes de que la asimetría del TASTy reader la haga urgente (§3).

**Deprecación.** `@deprecated` con `since` y `message` que indique el reemplazo; ventana de al menos una minor antes de eliminar. En librerías, SemVer + **MiMa** en CI: romper compatibilidad binaria sin bump mayor es un incidente de consumidores, no un detalle.

**Deuda consciente.** Todo atajo con `// TODO(usuario): motivo — enlace a issue`.

**PROHIBIDO** (excepción solo con justificación escrita y aprobación):
- ❌ `null` en código Scala (salvo interop Java, envuelto en el acto); `Option.get`, `.head`/`.last` sobre colección posiblemente vacía, `.asInstanceOf`, `isInstanceOf` como sustituto de pattern matching.
- ❌ `throw` como control de flujo de errores de dominio; `catch { case _ => }` o `case NonFatal(_) => ()` que traga el error sin decisión; capturar `Throwable`.
- ❌ `Await.result`/`Await.ready` en código de producción; `unsafeRunSync()`/`Unsafe.unsafe` fuera del `main` o de un test.
- ❌ `Future` en código nuevo fuera de la frontera con una librería que lo imponga.
- ❌ Bloquear el pool de cómputo del efecto (JDBC/IO síncrona/CPU pesada sin `blocking`).
- ❌ Mezclar ecosistemas de efectos (cats-effect + ZIO + Pekko) en el mismo servicio sin capa de interop explícita y aprobada.
- ❌ **Akka ≥2.7 (BSL) sin licencia comercial vigente verificada por legal**, incluido el que entra como dependencia transitiva; para código nuevo, Pekko.
- ❌ Conversiones implícitas globales; `given` sin tipo explícito en API pública; `using` para colar configuración de negocio.
- ❌ `var` y estado mutable compartido en el dominio; `mutable.Map` como caché global sin control de concurrencia ni TTL.
- ❌ Derivación de codecs inline en cada punto de uso (coste de compilación) y `deriveEncoder` sobre tipos abiertos con entrada no confiable.
- ❌ Evictions de dependencias sin gestionar; dos versiones minor de la misma librería en el classpath; `+` (versiones dinámicas) o snapshots en builds de release.
- ❌ CI sin `-Werror`; `-Wconf:any:s` global; supresión de warnings sin motivo escrito; merge con CI roja o tests flaky.
- ❌ `println`/`printStackTrace` en vez de logging estructurado; `case class` de config con secretos y `toString` por defecto.
- ❌ Concatenar input en SQL; serialización nativa Java o deserialización polimórfica abierta de datos externos.
- ❌ Empezar un proyecto nuevo en Scala 2 sin ADR; añadir cross-building sin consumidores reales.
- ❌ Macros/`inline` propios para lo que resuelve una derivación existente o código explícito (coste de compilación + opacidad).

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmar estado del ecosistema, comprobar online (no de memoria):
1. **Scala**: versión Next y LTS vigentes y baseline de JDK — scala-lang.org/download/all.html y las release notes; ¿ya salió **3.9.0 final** como nueva LTS? (a ago-2026 estaba en RC4). Política de compatibilidad en scala-lang.org/development/.
2. **Interop 2.13↔3**: scala-lang.org, "State of the TASTy reader" — confirmar el corte en 3.8 y hasta qué versión llegan los artefactos consumibles desde 2.13.
3. **sbt / Mill / scala-cli**: `github.com/{sbt/sbt,com-lihaoyi/mill,VirtusLab/scala-cli}/releases.atom`; estado del ecosistema de plugins sbt 2 (sbt2-compat) antes de forzar sbt 2 en un repo con plugins propios.
4. **Licencia de Akka**: akka.io/bsl-license-faq y akka.io/pricing — **el umbral de ingresos y los términos pueden haber cambiado desde 2022**; contrastar con legal. Estado y releases de **Apache Pekko** en pekko.apache.org (no solo GitHub).
5. **Pilas de efectos**: releases de cats-effect/fs2/http4s/doobie y de ZIO; comprobar si http4s 1.0 o doobie 1.0 finales ya salieron y si ZIO publicó una línea nueva.
6. **Herramientas**: scalafmt, scalafix, munit, ScalaCheck, MiMa, testcontainers-scala — última versión **y licencia** (cambios de licencia y proyectos en modo mantenimiento son riesgo real del catálogo).
7. **CVEs** del árbol (jackson, netty, drivers JDBC, librerías de logging) en las advisories del proyecto y NVD antes de congelar versiones.
8. **Hueco declarado, no verificado a ago-2026**: fecha de EOL formal de la línea Scala 2.13 y de 3.3 LTS (no hay fecha publicada localizada, solo la garantía relativa "≥1 año tras la siguiente LTS"); estado de mantenimiento de ScalaTest (sin releases desde 2024-06, sin declaración oficial de fin de soporte encontrada); términos comerciales actuales exactos de Akka.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
