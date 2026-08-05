---
name: clojure-standards
description: Clojure and ClojureScript engineering standards (staff-level). Trigger on .clj/.cljs/.cljc/.edn files, deps.edn, project.clj, bb.edn, shadow-cljs.edn, tools.build build.clj, .clj-kondo/config.edn, .cljfmt.edn, tests.edn (kaocha), and on libraries such as ring, reitit, pedestal, next.jdbc, honeysql, integrant, component, mount, malli, clojure.spec, core.async, test.check, clj-kondo, eastwood or nREPL. Apply when writing, reviewing or setting up CI for Clojure, when doing REPL-driven development, and when choosing state management, schema validation or component lifecycle.
---

# Estándares Clojure

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo código Clojure/ClojureScript: ficheros `.clj`, `.cljs`, `.cljc`, `.edn`, `deps.edn`, `project.clj`, `bb.edn`, `shadow-cljs.edn`, `build.clj` (tools.build), `.clj-kondo/config.edn`, `.cljfmt.edn`, `tests.edn`, y los pipelines que compilan/testean Clojure. Cubre servicios backend, jobs, librerías, scripts (babashka) y el método de trabajo REPL-driven. Fija **criterio**: qué usar, qué está prohibido, qué verificar.

**No aplica**: ver `jvm-spring-standards` (**la JVM en sí y Spring**: distribución y versión del JDK, LTS, GC y su tuning, flags de arranque, JFR, contenedorización de la JVM — si un proyecto Clojure usa Spring, **manda `jvm-spring-standards` para Spring**; aquí solo el código Clojure, sus builds nativos —`deps.edn`/tools.build, Leiningen— y sus librerías), `scala-standards` (el otro lenguaje JVM del catálogo: mismo runtime, paradigmas opuestos —dinámico y homoicónico frente a tipado estático rico—; la elección entre ambos es de **equipo y ecosistema**, no de rendimiento), `lisp-standards` (**el resto de la familia Lisp, fuera de la JVM**: Common Lisp, Scheme y Emacs Lisp — imagen y `save-lisp-and-die`, sistema de condiciones y reinicios, CLOS y el MOP, ASDF/Quicklisp; **la frontera no es "es un Lisp"**: nada de aquello se extrapola a Clojure ni al revés), `data-engineering-standards` y `lakehouse-standards` (**Spark es suyo como plataforma**: pipeline, orquestación, formato de tabla y coste; el código Clojure/Scala del job es de las skills de lenguaje), `streaming-cdc-standards` (Kafka Streams/Flink como plataforma), `api-design-standards` (diseño del contrato HTTP; aquí solo su implementación con ring/reitit/pedestal), `sql-standards` (**el SQL en sí**: esquema, índices, planes — HoneySQL genera SQL y ese SQL queda sujeto a su criterio), `data-platform-standards` (modelado y tuning del motor), `microservices-architecture-standards` (corte de servicios, sagas, resiliencia distribuida), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas; aquí solo los sinks concretos de Clojure), `vulnerability-management-standards` (triaje y SLA de CVEs; aquí solo el gate de build), `secrets-management-standards`, `observability-standards` (pipeline OTel; aquí solo la instrumentación en código), `cicd-standards`, `kubernetes-standards`, `python-standards`/`go-standards`/`rust-standards` (elección de lenguaje), `groovy-standards` (**el tercer lenguaje JVM del catálogo**, con papel distinto: es sobre todo lenguaje de configuración de otras herramientas — el DSL Groovy de Gradle y el `Jenkinsfile` son suyos).

## 2. Toolchain y decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Estado a 2026-08 | Nota |
|---|---|---|---|
| Lenguaje | **Clojure 1.12.5** (estable) | 1.13.0-alpha6 en curso | 1.13 exigirá **Java 17+** y saca `spec` del artefacto core |
| Build/deps | **`deps.edn` + `tools.deps` + `tools.build`** | CLI 1.12.5.x, tools.build 0.10.14 | Default para proyectos nuevos |
| Build alternativo | **Leiningen 2.13.0** | **Repo canónico movido a Codeberg**; GitHub es "temporary convenience mirror" | Vivo, no abandonado; se mantiene solo en repos que ya lo usan |
| Scripting | **babashka 1.13.x** | — | Sustituye bash en automatización no trivial |
| Lint (gate) | **clj-kondo** (calendar versioning, EPL-1.0) | v2026.08.x | **Gate de CI, no sugerencia** |
| Formato | **cljfmt 0.16.x** | — | Config versionada; formato no se debate |
| Lint semántico | **eastwood 1.4.3** | — | Opcional, complementa a clj-kondo; más lento (carga el código) |
| Test runner | **kaocha 1.91.x** (EPL-1.0) | — | Alternativa: `cognitect-labs/test-runner`, más simple |
| Propiedades | **test.check 1.1.3** | — | Obligatorio en lógica con invariantes |
| Esquemas | **Malli 0.20.x** (EPL-2.0) para código nuevo | `spec.alpha` 0.6.x sigue mantenida | **spec 2 (`spec-alpha2`) sin release: no arquitecturar sobre ella** |
| Ciclo de vida | **Integrant 1.0.x** | Component 1.2.0, mount 0.1.16 | Ver §3 |
| Web | **ring 1.15.x + reitit 0.10.x** | pedestal como alternativa | ring es el sustrato común |
| Datos | **next.jdbc 1.3.x + HoneySQL 2.7.x** | — | `clojure.java.jdbc` es legado |
| Concurrencia | **core.async 1.9.865** (estable) | 1.10.x en alpha | Ver §6 sobre hilos virtuales |
| SCA | **nvd-clojure 5.3.0** | **clj-holmes sin releases desde 2022/2023** | Ver §5 |

**Estabilidad como valor de diseño, no como estancamiento.** Clojure rompe compatibilidad muy raramente y las librerías de años atrás siguen funcionando. Consecuencias operativas:
- Una dependencia "sin commits en 3 años" **no es automáticamente abandono** en este ecosistema, al contrario que en otros. El criterio es: ¿resuelve el problema, tiene superficie pequeña, hay issues abiertos sin respuesta que te afecten, hay CVEs en sus transitivas? Se decide con esos datos, no con la fecha del último commit.
- El corolario: tampoco hay upgrade "gratis". Subir de versión de Clojure es barato; subir el **JDK** por debajo puede no serlo (1.13 mueve el mínimo a Java 17). Ese salto lo gobierna `jvm-spring-standards`.

**`deps.edn` frente a Leiningen.** Proyecto nuevo: `deps.edn` + tools.build (modelo de datos, alias componibles, sin plugins que ejecuten código de terceros en el build por defecto, es la herramienta del core team). Leiningen sigue vivo y mantenido —2.13.0, con el repo **canónico en Codeberg** desde 2025— y es defendible en un repo que ya lo usa y depende de sus plugins; migrar por moda es coste sin beneficio. **No mezclar los dos** en el mismo proyecto (dos fuentes de verdad de dependencias = clases duplicadas en el classpath). `deps.edn` versionado; alias `:dev`/`:test`/`:build` separados, y **las herramientas de desarrollo (nREPL, cider) nunca en las dependencias base** (§5).

## 3. Estructura, estado y arquitectura

**REPL-driven development es el método de trabajo, con reglas.**
- Se evalúa en el editor contra un REPL conectado al proyecto; el ciclo es escribir → evaluar la forma → probar en el REPL → **fijar el resultado como test**. Lo que funciona en el REPL y no se convierte en test no existe.
- **El estado vivo del REPL es también una fuente de bugs.** Una sesión larga acumula vars redefinidas, namespaces con definiciones borradas del fichero pero aún cargadas, protocolos recompilados con instancias viejas, multimétodos con métodos huérfanos y componentes a medio arrancar. Síntoma clásico: funciona en el REPL, falla en CI (o al revés).
- Regla: **recargar de forma dirigida** (`clojure.tools.namespace.repl/refresh` o el reset del sistema de componentes) tras cambios estructurales; **reiniciar el REPL** —no discutir con él— ante cualquiera de estos: cambio de protocolo/`deftype`/`defrecord`, cambio de dependencias, `refresh` que falla, o comportamiento inexplicable. Antes de decir "arreglado", el cambio se valida en un **proceso limpio** (`clj -M:test` desde cero), nunca solo en la sesión viva.
- Un sistema con ciclo de vida (§ abajo) hace el `reset` fiable; sin él, recargar es una lotería.

**Inmutabilidad y estructuras persistentes** son el default: los valores no se modifican, se derivan (`assoc`, `update`, `conj`). Los transients (`transient`/`persistent!`) solo dentro de una función, sobre datos locales, cuando el profiler lo justifique; nunca escapando a otra parte del programa.

**Gestión del estado — cada primitiva tiene su caso, y ninguna es "el sitio donde guardo todo".**
| Primitiva | Cuándo |
|---|---|
| `atom` | Estado independiente, sincrónico, actualizado con función pura. El 90 % de los casos legítimos |
| `ref` (STM) | **Solo** cuando dos o más piezas de estado deben cambiar de forma coordinada y atómica |
| `agent` | Actualizaciones asíncronas serializadas sobre un valor (poco frecuente hoy; suele ser mejor una cola) |
| `var` con `binding` | Contexto dinámico acotado a la pila de llamadas (`*out*`, contexto de request). No es estado de aplicación |
| `volatile!` | Estado local no compartido en un transductor/bucle caliente |

- **Antipatrón del átomo global**: `(defonce app-state (atom {}))` como almacén de todo. Convierte el programa en un mundo con acoplamiento invisible, imposible de testear en paralelo y de razonar; los tests se contaminan entre sí y el orden de carga importa. El estado se pasa como argumento o vive en el componente que lo posee.
- Las funciones que mutan un `atom` reciben **la función pura** que calcula el nuevo valor (`swap!` con función testeable aparte). `swap!` puede reintentar: la función **debe ser pura** — nada de I/O ni de efectos dentro.
- Sin efectos secundarios ocultos en funciones aparentemente puras; los nombres con `!` marcan efecto.

**Componentes y ciclo de vida: hace falta algo.** Sin un sistema explícito, el estado con arranque/parada (pools de conexión, servidor HTTP, consumidores, schedulers) acaba en `defonce` + átomos globales: no se puede reiniciar sin reiniciar la JVM, el REPL se vuelve inconsistente y los tests de integración no pueden levantar dos instancias.
- **Integrant** por defecto: el sistema es **datos** (un mapa EDN de configuración), las claves son multimétodos `init-key`/`halt-key!`, las dependencias se expresan con `ig/ref`. Configuración fuera del código y sistema componible en tests.
- **Component** es igualmente válido y más antiguo (protocolo `Lifecycle`, sistema como registro); elegir uno por repo.
- **mount** solo si el equipo asume su modelo: usa vars globales, lo que reintroduce el acoplamiento implícito que Integrant/Component evitan. No es la opción por defecto.
- Regla dura, sea cual sea: **la dependencia se inyecta, no se busca**. Nada de que un handler alcance un `defonce` de otro namespace.

**Mapas como interfaz, registros y protocolos como excepción.**
- Los datos entre funciones y entre servicios son **mapas y colecciones planas**; `defrecord` solo cuando se necesita implementar un protocolo o el rendimiento de campos fijos está medido; `deftype` casi nunca.
- **Protocolos para polimorfismo en fronteras** (un adaptador de almacenamiento, un cliente externo) — así se sustituye por un doble en los tests. Multimétodos cuando el despacho es por un valor de los datos (tipo de evento) y el conjunto es abierto.
- **Namespaced keywords** (`:user/id`, `::db/spec`) en todo dato que cruce un límite: evitan colisiones al fusionar mapas y documentan procedencia.
- **Destructuring** en la firma para lo que la función usa de verdad (`{:keys [id email]}`); nada de arrastrar el mapa entero y buscar dentro. Clojure 1.13 añadirá directivas de destructuring comprobado (`:keys!`) que fallan si falta la clave — hoy, ese contrato se expresa con un esquema (§ abajo).
- **Namespaces**: uno por unidad de responsabilidad, nombre = ruta de fichero; capas explícitas (`app.http.*` → `app.domain.*` → `app.db.*`) con dependencias en un solo sentido y **sin ciclos** (clj-kondo los detecta). `:require` con alias explícito siempre; **prohibido `:refer :all`** y `use`.

**Esquemas: Malli o spec, decidido una vez por repo.**
- **Malli** para código nuevo: los esquemas son **valores** (datos manipulables), registros locales, coerción y transformación integradas, buenos mensajes de error, generación de JSON Schema/OpenAPI e integración directa con reitit. Coste: la coerción integrada mezcla validación y transformación — se usa de forma explícita en los bordes, no implícita en todas partes.
- **`clojure.spec.alpha`** sigue mantenida y es defendible en bases que ya la usan, sobre todo si se apoyan en su generación para `test.check` y `instrument`. **`spec-alpha2` (spec 2) no tiene release ni tag; llevar años en alpha lo descarta como base de decisiones** — no planificar migraciones hacia ella. Ojo al cambio en curso: Clojure 1.13 saca spec del artefacto core a su propia librería.
- Dónde validar: **en los bordes** (entrada HTTP, mensajes de cola, ficheros, respuestas de terceros) y en las fronteras de módulo importantes. Validar todo en todas partes es coste sin señal.
- La instrumentación de funciones (`malli.dev`/`stest/instrument`) es de **desarrollo y test**, no de producción.

## 4. Calidad y testing

**clj-kondo es un gate de build, no un consejo.** `.clj-kondo/config.edn` versionado, `clj-kondo --lint src test --fail-level warning` en CI; exportar la config de las librerías (`--copy-configs`). Vetar por lint lo que §7 prohíbe: `:refer-all`, namespaces sin usar, vars redefinidas, shadowing de vars del core, uso de `clojure.core/read-string`, `eval` y `println` en código de servicio. Baseline solo para adopción en legado y **con fecha de caducidad**.

**cljfmt** con config versionada, `cljfmt check` en CI. **eastwood** opcional, en job aparte (carga el código y es lento); útil para *reflection warnings* y sospechas semánticas que clj-kondo no ve.

**Testing.**
- `clojure.test` es la base; **kaocha** aporta plugins (cobertura, watch, aleatorización, informes) y `tests.edn` versionado. `cognitect-labs/test-runner` si no se necesita más.
- **Property-based con `test.check` obligatorio** donde haya invariantes: serialización round-trip, funciones de transformación de datos, reglas de negocio combinatorias, cualquier parser. En un lenguaje dinámico, las propiedades son el sustituto real del type-checker.
- Cobertura de **bordes y errores**: `nil` en cada argumento que puede llegar `nil` (el `NullPointerException` sigue siendo el fallo número uno en Clojure), colecciones vacías, claves ausentes frente a claves con valor `nil` (**no son lo mismo**), números grandes y división por cero, entradas fuera de esquema.
- Fixtures explícitas (`use-fixtures`) para levantar/parar el sistema Integrant/Component; **cada test recibe su sistema**, no uno global compartido. Tests deterministas y paralelizables: nada de dependencias de orden ni de estado en vars globales.
- Dobles: `with-redefs` **solo en el test que lo necesita y sobre fronteras propias**; abusar de él es señal de que falta un protocolo inyectado. Nunca `with-redefs` en test concurrente (es global y no thread-safe).
- Integración contra dependencias reales con testcontainers (misma imagen y versión que prod); prohibido sustituir la BD real por una embebida distinta.
- Todo bugfix deja test de regresión. Test flaky: se arregla o se borra. Cobertura (cloverage) como señal, no como meta.

**Gates de CI, en orden de coste creciente (rompen el build):**
```
cljfmt check  →  clj-kondo --fail-level warning  →  tests unitarios  →  tests de integración  →  SCA de dependencias
```
Main siempre verde; no se mergea con CI roja.

**Errores.**
- **`ex-info` es el estándar**: `(throw (ex-info "mensaje" {:error/type ::db-timeout :ctx ...}))`, con datos estructurados en el mapa (`ex-data`) y `:cause` cuando envuelve otra excepción. Nada de `(throw (Exception. (str ...)))`: pierde la información que el llamante necesita para decidir.
- Se captura por **dato**, no por clase: `(catch clojure.lang.ExceptionInfo e (case (:error/type (ex-data e)) ...))`. Se relanza lo que no se sabe manejar.
- **El mapa de `ex-info` acaba en logs**: no meter secretos ni PII (§5).
- Errores esperables de dominio pueden devolverse como valor (`[:ok v]` / `[:error m]` o un mapa con `:error`) en vez de excepción; lo que **no** vale es mezclar ambos estilos en la misma capa sin regla.
- **Los stack traces de Clojure son un problema operativo real**: frames de la maquinaria (`clojure.lang.AFn`, `RestFn`, `invokeStatic`), nombres desmangled (`my_ns$my_fn`), la causa útil enterrada bajo varios envoltorios y, en `future`/`pmap`/pool, la traza del hilo trabajador sin el contexto de quien lo lanzó. Mitigaciones: contexto propio en `ex-data` (no fiarse de la traza), logging estructurado que serialice `ex-data` y la cadena de causas completa, un handler de nivel superior que registre `Throwable->map`, y `-XX:-OmitStackTraceInFastThrow` para no perder trazas repetidas.

## 5. Seguridad del stack

- **`read-string` está PROHIBIDO sobre entrada no confiable.** `clojure.core/read-string` usa el lector completo, que honra `*read-eval*` y por tanto **ejecuta código** (`#=(...)`) además de instanciar objetos vía tags. Para datos externos: **`clojure.edn/read-string` siempre**, con `:readers` explícitos si hacen falta tags y `:default` para tags desconocidos. `clojure.edn` no evalúa. Vetarlo en clj-kondo. Aplica igual a `read` sobre un stream de entrada y a los tagged literals de `data_readers.clj` de terceros.
- **`eval` prohibido sobre cualquier dato que provenga de fuera del código** (petición, BD, fichero, config remota). El "sistema de reglas configurable" que evalúa Clojure enviado por el usuario es RCE por diseño. Lo mismo para `load-string`, `load-reader`, `resolve`/`requiring-resolve` sobre símbolos de entrada (permitirlos equivale a invocar cualquier función del classpath) y `Compiler/load`.
- **nREPL en producción es ejecución remota de código sin autenticación**, por diseño: quien alcanza el puerto ejecuta lo que quiera con los permisos del proceso. Reglas: la dependencia y el arranque de nREPL viven **solo en el alias `:dev`**, nunca en el uberjar de producción; si en una emergencia hace falta un REPL en un entorno real, **bind a `127.0.0.1`** (el default de nREPL ya es localhost tras corregirse como fallo de seguridad) más túnel SSH, o TLS con autenticación por claves si de verdad hay que escuchar en otra interfaz; puerto cerrado en firewall/SecurityGroup/NetworkPolicy; sesión auditada y con caducidad. Un nREPL abierto es peor que un RCE típico: no necesita exploit.
- **Dependencias que se resuelven desde Git (`:git/url` + `:git/sha` en `deps.edn`) son una decisión de cadena de suministro.** Implicaciones: el artefacto **no está en Maven Central** ni firmado, no lo ve el escáner de SCA que consulta coordenadas Maven, se compila desde fuente en la máquina que lo resuelve, y su propio `deps.edn` arrastra transitivas igual de opacas. Criterio: preferir dependencias Maven/Clojars; una dependencia Git requiere **SHA completo fijado** (nunca una rama ni `:git/tag` sin `:git/sha`), justificación escrita, revisión del repo de origen y un mecanismo de seguimiento de actualizaciones propio (el bot no lo ve). `deps.lock`/`-Sdeps`/`clojure -P` en CI para resolución reproducible, y `~/.gitlibs` tratado como caché de código de terceros.
- **SCA**: `nvd-clojure` (activa, 5.3.0) contra el árbol de dependencias en CI y programada; recordar que solo cubre lo que tiene coordenadas Maven. **`clj-holmes` (SAST específico de Clojure) lleva sin releases desde 2022/2023: no fijarlo como gate obligatorio; verificar su estado antes de adoptarlo** (§8). `antq` para detectar dependencias desactualizadas. El SLA de triaje de CVEs lo fija `vulnerability-management-standards`.
- **SQL solo parametrizado**: `next.jdbc` con vector `["select ... where id = ?" id]` o **HoneySQL** (genera SQL parametrizado a partir de datos). **Prohibido `str`/interpolación para construir SQL**; ojo con los identificadores dinámicos (nombres de tabla/columna), que no son parametrizables: allowlist, nunca concatenación. El criterio del SQL resultante es de `sql-standards`.
- **Serialización Java nativa prohibida** para datos externos (`ObjectInputStream`, y por tanto también cualquier caché/sesión que la use por debajo). EDN, Transit o JSON con lectores acotados.
- **Entrada HTTP**: validación de esquema (Malli/spec) en el borde antes de tocar el dominio; límites de tamaño de body y de profundidad; en ring, **`wrap-anti-forgery` en apps con sesión** (no desactivarlo "porque molesta"), cookies `HttpOnly`/`Secure`/`SameSite`, y cabeceras de seguridad (`ring-defaults` con `secure-site-defaults` como punto de partida, revisando qué activa).
- **Secretos** nunca en `deps.edn`, `project.clj`, `resources/config.edn` versionado, `ex-data` ni logs. Config desde entorno o gestor (`aero`/`integrant` leyendo variables); en el REPL, cuidado especial: imprimir el sistema entero (`(ig/init ...)`) vuelca credenciales en el buffer del editor y en el historial.
- Aleatoriedad de seguridad con `java.security.SecureRandom`, nunca `rand`/`rand-int`.

## 6. Rendimiento y operabilidad

- **La JVM (GC, heap, flags, JFR, contenedor) es territorio de `jvm-spring-standards`.** Aquí lo específico de Clojure:
- **Concurrencia — el mapa a 2026**: `core.async` **1.9.865** es la línea estable y ya reimplementa los `go` blocks sobre **hilos virtuales** cuando hay Java 21+ (propiedad `clojure.core.async.vthreads`: sin fijar = uso oportunista; `target` = exige vthreads; `avoid` = vuelve a la transformación IOC). Sigue vigente la regla de siempre: **I/O bloqueante no va dentro de `go`** — para eso está `io-thread`. `clojure.core.async.flow` (introducida en 2025) separa la lógica de la ejecución y es hoy la forma recomendada de construir topologías con core.async.
- Criterio: **core.async no es el default para "hacer cosas en paralelo"**. Con hilos virtuales, un `future`/executor virtual + colas normales resuelve la mayoría de los casos de concurrencia de I/O con muchísima menos complejidad conceptual. core.async se justifica cuando hay **canales, transducers, backpressure explícita o una topología de procesos** (ahí, `flow`); usarlo como reemplazo de un pool es complejidad accidental. Ojo con `pmap` (paralelismo fijo, chunked, malo para I/O) y con `future` sobre el pool `agent` no acotado.
- **Colas y límites acotados siempre**: buffers de canal con tamaño (`chan 100`), nunca `(chan)` sin buffer usado como cola infinita ni `dropping-buffer` sin decisión consciente; pools de conexión (HikariCP con next.jdbc) dimensionados con datos; timeouts en todo cliente HTTP/JDBC.
- **Perezosa por defecto = fugas y sorpresas**: una secuencia lazy que se consume fuera del `with-open` da "stream closed"; una lazy seq retenida por la cabeza se come el heap. Forzar con `doall`/`into`/`run!` dentro del ámbito del recurso, y usar **transducers** (`into`, `transduce`, `sequence`) para pipelines sin secuencias intermedias.
- **Type hints y reflexión**: activar `(set! *warn-on-reflection* true)` en los namespaces con interop; la reflexión en un bucle caliente es órdenes de magnitud más lenta. Cero *reflection warnings* en el build es un objetivo alcanzable.
- **Arranque**: la carga de namespaces domina el arranque de un servicio Clojure. AOT (`compile`) del entrypoint y uberjar de release; para CLIs, **babashka** o GraalVM native-image (con las restricciones conocidas: nada de `eval` dinámico ni carga de código en runtime).
- **Observabilidad**: logging estructurado (`mulog`, o `clojure.tools.logging` sobre SLF4J con appender JSON) con contexto de request y traceId; **prohibido `println`** en código de servicio. Serializar `ex-data` y la cadena de causas. Instrumentación OTel según `observability-standards`.
- **Graceful shutdown obligatorio**: hook de apagado que ejecuta `ig/halt!`/`component/stop` en orden inverso (drenar el servidor HTTP, cerrar consumidores, cerrar pools) alineado con el periodo de gracia del orquestador. Un servicio que no para limpio no soporta rolling deploy.
- Health endpoints separados: liveness trivial, readiness que comprueba dependencias.

**Interop con Java y las excepciones que cruzan la frontera.**
- La interop es de primera clase (`(.method obj)`, `Klass/staticMethod`, `(Klass. args)`), pero **es el punto por donde entran `null` y excepciones comprobadas** en un lenguaje que no las tiene: Clojure no obliga a declarar `throws`, así que **cualquier llamada Java puede lanzar sin que nada lo indique** — incluidas las que ocurren dentro de una secuencia lazy y explotan lejos, en el momento de la realización, o en otro hilo.
- Reglas: envolver la frontera Java en una función Clojure que capture y **traduzca a `ex-info`** con `:cause` y contexto de dominio; nunca dejar escapar una excepción de librería Java a la capa de negocio. Todo valor que venga de Java se trata como potencialmente `nil` en la propia línea. Recursos Java siempre con `with-open` (y forzar la secuencia dentro, ver arriba). No capturar `Throwable` para tragarlo.

**ClojureScript — acotado.** ClojureScript (1.12.x) con **shadow-cljs** como herramienta de build por defecto (interop npm y REPL sólidos) es la opción para compartir lógica y validaciones vía `.cljc` entre backend y frontend. Todo el criterio de frontend web (framework, bundling, rendimiento de UI, accesibilidad) **no es de esta skill**. Diferencias que sí importan aquí: no hay `ref`/`agent` ni STM, la interop y los errores son de JavaScript, y la eliminación de código muerto del compilador de Closure **penaliza el uso de `eval`/`resolve` dinámicos** — otra razón para no usarlos.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia.** Clojure: subir de versión estable en el trimestre siguiente a su release (los saltos son baratos); **planificar el requisito de Java 17+ de la línea 1.13 con antelación**. Dependencias revisadas con `antq` de forma programada; upgrade de las que traen CVEs, inmediato. Herramientas (clj-kondo, cljfmt, kaocha) siempre en su última versión: son gates, no runtime.

**Deprecación.** Metadatos `^:deprecated` con motivo y reemplazo en el docstring; ventana explícita antes de eliminar una función pública. Las librerías internas publican en un repositorio propio con versión, no se consumen por `:local/root` entre repos distintos.

**Deuda consciente.** Todo atajo con `;; TODO(usuario): motivo — enlace a issue`.

**PROHIBIDO** (excepción solo con justificación escrita y aprobación):
- ❌ **`clojure.core/read-string` (o `read`) sobre entrada no confiable** — se usa `clojure.edn/read-string` con `:readers`/`:default`.
- ❌ **`eval`, `load-string`, `resolve`/`requiring-resolve` sobre datos externos**; "reglas configurables" que evalúan código enviado por el usuario.
- ❌ **nREPL (o cualquier REPL de red) en la imagen/uberjar de producción**; nREPL escuchando en `0.0.0.0` sin TLS ni autenticación.
- ❌ Dependencias `:git/url` sin `:git/sha` completo fijado, o apuntando a una rama; dependencias Git sin justificación y sin seguimiento propio de actualizaciones.
- ❌ Interpolación de string para construir SQL; identificadores dinámicos sin allowlist.
- ❌ **Átomo global como almacén de estado de aplicación**; `defonce` con estado de servicio en vez de un sistema con ciclo de vida; buscar dependencias en vars de otros namespaces en lugar de inyectarlas.
- ❌ I/O o efectos dentro de la función pasada a `swap!` (puede reintentarse); `ref`/STM con efectos secundarios dentro de `dosync`.
- ❌ I/O bloqueante dentro de un `go` block; canales sin buffer usados como colas de trabajo; `pmap` para I/O.
- ❌ `:refer :all` y `use`; `:require` sin alias; ciclos entre namespaces.
- ❌ `with-redefs` en tests concurrentes o como sustituto sistemático de inyección de dependencias; tests que dependen del orden o de estado global compartido.
- ❌ Devolver secuencias lazy fuera del ámbito del recurso que las alimenta (`with-open` + lazy seq sin forzar).
- ❌ `(throw (Exception. "..."))` en vez de `ex-info` con datos; capturar `Throwable` y seguir sin decisión; secretos o PII dentro de `ex-data`.
- ❌ `println`/`prn` como logging en código de servicio; imprimir el sistema completo (con credenciales) en el REPL o en logs.
- ❌ Declarar "arreglado" validando solo en la sesión viva del REPL, sin ejecutar en un proceso limpio.
- ❌ Mezclar `deps.edn` y Leiningen como fuentes de dependencias en el mismo proyecto.
- ❌ Arquitecturar sobre **spec 2 / `spec-alpha2`** (sin release); mezclar Malli y spec como validadores de borde en el mismo repo sin regla escrita.
- ❌ Reflexión en rutas calientes con `*warn-on-reflection*` desactivado; macros propias para lo que resuelve una función (las macros no componen y complican el debug).
- ❌ CI sin clj-kondo como gate; baseline de lint sin fecha de caducidad; merge con CI roja o tests flaky.

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmar estado del ecosistema, comprobar online (no de memoria):
1. **Clojure**: estable vigente y estado de 1.13 (¿ya salió final? ¿confirma Java 17+ y la salida de spec del artefacto core?) — clojure.org/releases/downloads y clojure.org/news.
2. **Herramientas del core**: versión de la CLI/`tools.deps` y de `tools.build` (clojure.org/releases/tools). **Leiningen: releases y estado en `codeberg.org/leiningen/leiningen`**, no en el mirror de GitHub.
3. **core.async**: última estable frente a la línea alpha, y si la guía sobre hilos virtuales o `flow` ha cambiado (clojure.org/news; releases del repo). Contrastar contra la política de JDK que fije `jvm-spring-standards`.
4. **Malli vs spec**: última de Malli, estado de `spec.alpha` y **si `spec-alpha2` ha publicado por fin algún release/tag** (a ago-2026, ninguno).
5. **Calidad**: clj-kondo (calendar versioning, se mueve rápido), cljfmt, kaocha, eastwood, test.check — última versión **y licencia**.
6. **Seguridad de dependencias**: estado de mantenimiento de **clj-holmes** (sin releases desde 2022/2023) y de **nvd-clojure**; comprobar si han cambiado de licencia o han sido sustituidos antes de fijarlos como gate.
7. **Stack web y datos**: ring, reitit, pedestal, next.jdbc, HoneySQL, Integrant/Component/mount — versiones y advisories.
8. **CVEs** de las transitivas Java del árbol (Jetty/undertow, Jackson, drivers JDBC, logging) en NVD antes de congelar versiones.
9. **Huecos declarados, no verificados a ago-2026**: fecha exacta de release final de Clojure 1.13; si Leiningen ha declarado formalmente modo mantenimiento (solo se verificó el cambio de hosting a Codeberg, no una declaración de estado); versión exacta de core.async en la que `flow` dejó de ser alpha; estado actual del proyecto clj-holmes (dormido, no declarado archivado).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
