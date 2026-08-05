---
name: performance-engineering-standards
description: Use when a backend, runtime or system is slow and someone must prove why — defining a latency objective as percentile plus concurrency plus hardware, tail latency at p99 and p99.9, coordinated omission in load generators, open versus closed workload models, wrk2 -R, vegeta -rate, k6 constant-arrival-rate and ramping-arrival-rate executors, Gatling injectOpen versus injectClosed, JMeter Open Model Thread Group, Locust, HdrHistogram, the USE method (utilization, saturation, errors) and the RED method (rate, errors, duration), perf record and perf script, FlameGraph flamegraph.pl and stackcollapse, bpftrace and eBPF tracing, perf_event_paranoid, go tool pprof and net/http/pprof, py-spy, async-profiler and JFR, continuous profiling with Pyroscope, Parca or Grafana Profiles Drilldown, OTLP profiles and the OpenTelemetry eBPF profiler, sampling versus instrumentation overhead, CPU and allocation profiles, Amdahl's law, Little's law and queueing saturation near full utilization, latency budgets split across services, load versus stress versus soak versus spike tests, or a benchmark whose result nobody can reproduce.
---

# Estándares de ingeniería de rendimiento

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la metodología de rendimiento del lado del servidor: sistema, runtime, servicio y
el camino que los une**. Qué se mide, con qué estadístico, con qué generador de carga, cómo se
perfila, en qué orden se buscan los culpables y qué evidencia hace falta para aceptar que una
optimización es una mejora y no una casualidad. **La tesis**: *medir antes de tocar, y saber
qué medir*. Una optimización sin medición previa y posterior no es ingeniería, es superstición
con commit.

Triggers: `perf record`/`perf report`/`perf script`/`perf stat`, `perf_event_paranoid`,
`flamegraph.pl`, `stackcollapse-perf.pl`, *flame graph*, *off-CPU*, `bpftrace`, eBPF, BCC,
`pprof`, `net/http/pprof`, `go tool pprof`, `py-spy`, `async-profiler`, JFR, `jemalloc` /
`heaptrack` / `massif`, Pyroscope, Parca, Profiles Drilldown, perfilado continuo, OTLP
Profiles, `wrk`/`wrk2 -R`, `vegeta -rate`, k6 `constant-arrival-rate` / `ramping-arrival-rate`
/ VU, Gatling `injectOpen` / `injectClosed` / `rampUsersPerSec`, JMeter *Open Model Thread
Group*, Locust, `ab`, HdrHistogram, *coordinated omission*, *tail latency*, p95/p99/p99.9,
USE, RED, *golden signals*, ley de Little, ley de Amdahl, presupuesto de latencia, prueba de
carga / estrés / *soak* / pico, N+1, *cold start*, pausa de GC.

**No aplica**: ver `web-performance-standards` (**la frontera más fina del catálogo, y ya está
escrita desde el otro lado**: suyos el **navegador y el usuario real** —Core Web Vitals, RUM
en p75, presupuesto de *bundle*, coste de hidratación, CLS—; **aquí el servidor, el runtime y
el sistema**. El punto de contacto es el **TTFB**: *es su métrica de entrada y mi métrica de
salida* — **cómo se reduce el tiempo de respuesta del servidor es de aquí; que ese TTFB entra
en el LCP y cuánto pesa en el p75 de campo es suyo**. Corolario operativo: un p99 de servidor
impecable no contradice una web lenta, y viceversa; **nunca se cierra un debate de una con el
número de la otra**), `sre-practice-standards` (**frontera importante**: SLO, SLI, *error
budget*, alertas de *burn rate*, planificación de capacidad y fiabilidad en producción son
suyos. Regla: ***"¿cuánta latencia podemos permitirnos y qué hacemos si la superamos?" es de
`sre-practice`; "¿por qué es lenta y qué la arregla?" es de aquí***. El SLO define el
objetivo; esta skill provee el método que lo cumple), `observability-standards` (**la
plataforma de telemetría es suya**: recolectores, OTel Collector, almacenamiento, retención,
muestreo de trazas, cardinalidad, tableros y alertas — **el perfilado continuo se ingiere y se
almacena allí**; **aquí qué se perfila, con qué frecuencia de muestreo y cómo se lee un *flame
graph***), `testing-qa-standards` (**recíproco declarado en ambas direcciones**: allí la
prueba de carga se **planifica** como tipo de prueba —escenarios, datos, criterio de parada, y
la regla de que nunca va en el gate de PR—; **aquí el modelo de carga (abierto o cerrado), la
metodología de medición y la interpretación del resultado**, §4. Un guion de carga escrito
allí que use un modelo cerrado contra un sistema abierto produce un número inválido según esta
skill), `data-platform-standards`, `sql-standards`, `mysql-mariadb-dba-standards`,
`oracle-dba-standards`, `sqlserver-dba-standards`, `nosql-standards`, `timeseries-db-standards`
y `search-engines-standards` (**el tuning del motor, el índice y el plan de consulta son
suyos**; aquí solo la metodología que demuestra que el cuello está en la base de datos y con
qué evidencia se entra por su puerta), `python-standards`, `go-standards`, `rust-standards`,
`jvm-spring-standards`, `dotnet-standards`, `cpp-standards`, `c-standards`,
`typescript-standards` y demás skills de lenguaje (**el perfilador concreto del runtime, sus
banderas y el ajuste de su recolector de basura son suyos**; aquí el método común y cuándo
recurrir a ellos), `gpu-computing-standards` (kernels, ocupación y memoria de GPU),
`caching-cdn-standards` (la política de caché HTTP, el CDN y la purga; **aquí la caché como
decisión de arquitectura con coste de coherencia**, §6.5), `networking-standards` y
`network-troubleshooting-standards` (**el diagnóstico de red es suyo**: RTT, pérdida, MTU,
*retransmits*, captura; aquí solo situar la red en el árbol de sospechosos y entregarles el
caso), `kubernetes-standards` (*requests*/*limits*, HPA, *throttling* de CPU por cgroup),
`linux-administration-standards` y `linux-storage-standards` (el ajuste del sistema y del
almacenamiento), `finops-standards` (**el coste como métrica y su presupuesto**; aquí el coste
solo aparece como argumento para dimensionar) y `microservices-architecture-standards` (el
reparto de responsabilidades entre servicios; aquí el reparto del **presupuesto de latencia**
entre ellos, §3.3), `refactoring-tech-debt-standards` (**Ola 6** — **optimizar no es refactorizar**: refactorizar
cambia la estructura **sin** cambiar el comportamiento observable; optimizar cambia una
característica observable —la latencia— y por tanto **se mide antes y después y se justifica con
ese dato**. El criterio de deuda, su registro y su financiación son suyos; la metodología de
encontrar y demostrar la mejora, de aquí. Y el aviso que comparten: **el código optimizado caduca**
y necesita fecha de revisión, mientras que un refactor bien hecho no),
`green-it-standards` (**Ola 6**: **la metodología de medir antes de tocar,
perfilar y demostrar la mejora es de aquí**; **la métrica de energía y de carbono es suya**, con
su propia contabilidad y sus propias trampas. Aviso que ambas comparten: **eficiencia de código y
reducción de huella no son lo mismo** — el orden de impacto real empieza por apagar lo ocioso y
dimensionar, y optimizar código por sostenibilidad solo se justifica a una escala que hay que
calcular, no heredar).

## 2. Decisiones por defecto

> Verificar la última versión y la licencia por web antes de fijarla en un proyecto real (§8).

### 2.1 Los dos métodos con nombre, citados en origen

No son estilos: son **listas de comprobación con autor, y se aplican a cosas distintas**.
Usarlas cruzadas es el error de encuadre más caro.

**USE — Brendan Gregg** (`brendangregg.com/usemethod.html`; publicado en su blog de dtrace.org
el 29-feb-2012 y en ACM Queue como *Thinking Methodically about Performance*, 2012, y en
CACM, 2013). Verbatim:

> *"For every resource, check utilization, saturation, and errors."*
> *"resource: all physical server functional components (CPUs, disks, busses, ...)"*
> *"utilization: the average time that the resource was busy servicing work"*
> *"saturation: the degree to which the resource has extra work which it can't service, often queued"*
> *"errors: the count of error events"*

Alcance declarado por el propio autor, verbatim: *"It solves about 80% of server issues with 5%
of the effort"*, y su límite, también verbatim: *"There are many problem types it doesn't
solve, which will require other methods and longer time spans"* / *"While the USE Method may
find 80% of server issues, latency-based methodologies (eg, Method R) can approach finding 100%
of all issues."* **Se cita el 80/5 como lo que es —una afirmación del autor, no un estudio— o
no se cita.**

**RED — Tom Wilkie**, creado **en 2015** (Grafana Labs, *The RED Method: How to Instrument Your
Services*, presentado en GrafanaCon EU 2018; Wilkie llegó a Grafana con la adquisición de
Kausal, y desarrolló RED en Weaveworks). Verbatim de la definición:

> *"Rate (the number of requests per second), Errors (the number of those requests that are
> failing), Duration (the amount of time those requests take)"*

Motivo declarado, verbatim: *"The USE Method doesn't really apply to services; it applies to
hardware, network disks, things like this. We really wanted a microservices-oriented monitoring
philosophy, so we came up with the RED Method."* Y la relación con las dos vecinas, verbatim:
sobre los *Four Golden Signals* (latencia, tráfico, errores, saturación), *"This is basically
the same as the RED Method, but includes saturation"*; y sobre el uso conjunto, *"the RED Method
is about caring about your users and how happy they are... and the USE Method is about caring
about your machines and how happy they are... They're complimentary."*

⚠ **Discrepancia declarada en la propia fuente**: el artículo de Grafana encabeza **las dos**
listas con *"For every resource, monitor:"*, incluida la de RED, pese a que el texto
inmediatamente anterior sostiene que RED existe precisamente porque USE **no** aplica a
servicios. La formulación coherente con el resto del artículo y con el uso universal es **"para
cada *servicio*"**. Al citar RED, citar la tríada, no el encabezado.

**Regla de uso**: **USE para recursos** (CPU, memoria, disco, red, controladoras, cgroups) y
**RED para servicios y endpoints**. En un incidente se recorren **las dos**: RED dice *qué
servicio* duele, USE dice *qué recurso* lo causa. Los *golden signals* del SRE Book son RED +
saturación y son de `sre-practice-standards`; **aquí se usan como índice de búsqueda, no como
alerta**.

### 2.2 Herramientas — estado y licencia verificados a ago-2026

| Uso | Por defecto | Licencia / estado verificado | Nota |
|---|---|---|---|
| Perfilado de CPU en Linux | **`perf`** | GPL-2.0 (`SPDX-License-Identifier: GPL-2.0` en `tools/perf` del árbol del kernel) | Muestreo, en el kernel; sin dependencias de terceros |
| Visualización de perfiles | **FlameGraph** (`stackcollapse-*.pl` + `flamegraph.pl`) | ⚠ **CDDL** — *"all files in this distribution are released under the Common Development and Distribution License (CDDL)"* (`docs/cddl1.txt`) | **No es MIT ni Apache**: copyleft por fichero. Si se empaqueta, pasa por revisión |
| Trazado dinámico ad hoc | **`bpftrace`** | Apache-2.0 (`LICENSE` en crudo) — v0.26.1 (2-jun-2026) | Para preguntas que ningún contador responde |
| Perfilado continuo (OSS) | **Grafana Pyroscope** | ⚠ **AGPL-3.0** (`LICENSE` en crudo) — releases semanales activas (ago-2026) | AGPL: relevante si se ofrece como servicio. UI: *Profiles Drilldown* (plugin, **public preview**, no GA) |
| Perfilado continuo (alternativa) | **Parca** | Apache-2.0 (`LICENSE` en crudo) — activo, motor de Polar Signals Cloud | Licencia permisiva; ecosistema menor |
| Estándar de intercambio | **OTLP Profiles** | ⚠ **Alpha pública desde el 26-mar-2026** | §2.4. **No** apostar producción crítica a él todavía |
| Carga con tasa constante | **`wrk2`** (`-R` obligatorio) | Apache-2.0 (`LICENSE` en crudo) | Referencia histórica de latencia corregida; **repo viejo, verificar antes de adoptar** |
| Carga programable | **k6** con executor `constant-arrival-rate` / `ramping-arrival-rate` | ⚠ **AGPL-3.0** (`LICENSE.md` en crudo) — v2.1.0 (30-jun-2026) | El default de VU es **modelo cerrado**: hay que elegir el executor a mano (§4.2) |
| Carga JVM | **Gatling** (`injectOpen`) | Apache-2.0 (`LICENSE.txt`; *"Gatling Open Source is licensed under Apache 2.0"*) — v3.15.1 (25-may-2026) | Gatling Enterprise es producto de pago aparte |
| Carga con GUI heredada | JMeter | Apache-2.0 — **5.6.3, sin release nueva desde ene-2024** | *Open Model Thread Group* declarado **experimental** (§4.2). No es el default de nada nuevo |
| Ataque HTTP simple | `vegeta` (`-rate`) | MIT (`LICENSE` en crudo) | Bueno para un endpoint, no para un recorrido de usuario |
| Carga en Python | Locust | MIT (`LICENSE` en crudo) | Requiere elegir explícitamente el modelo de llegada |
| Distribución de latencia | **HdrHistogram** | — | El registro de latencia **siempre** es un histograma, nunca una media acumulada (§3.2) |

**Avisos que corrigen suposiciones habituales**:
- **k6 es AGPL-3.0**, no Apache ni MIT. Si se embebe en un producto o se ofrece como servicio,
  es una decisión legal, no una elección de herramienta.
- **Pyroscope es AGPL-3.0**; **Parca es Apache-2.0**. Son la misma categoría con licencias
  incompatibles en propósito: la elección se toma con el abogado presente, no por la UI.
- **FlameGraph es CDDL**, no permisiva. Es el caso que más gente da por MIT.
- **JMeter lleva más de dos años sin release** en su web oficial (5.6.3, ene-2024). El feed de
  GitHub coincide aquí, pero **el feed de GitHub no es la fuente de verdad**: Apache publica en
  `jmeter.apache.org`. Comprobar allí (§8).

### 2.3 Muestreo frente a instrumentación

| | Muestreo (*sampling*) | Instrumentación (*tracing*/*instrumenting*) |
|---|---|---|
| Qué hace | Interrumpe a frecuencia fija y anota la pila | Registra cada evento que se ha marcado |
| Sesgo | Estadístico: pierde lo raro, ve bien lo caro | De observador: el coste crece con la frecuencia del evento |
| Coste | Acotado y predecible por frecuencia | **Ilimitado**: una función caliente instrumentada puede dominar su propio perfil |
| Uso | **Por defecto**, y el único aceptable en producción continua | Puntual, acotado, en la ruta ya sospechosa |
| Trampa | No ve el tiempo **fuera de CPU** (espera de E/S, bloqueo, planificador) | Un contador por llamada convierte lo barato en caro y **cambia el resultado que iba a medir** |

**Reglas duras**:
- **En producción se perfila por muestreo.** Instrumentación fina en producción solo con
  ámbito acotado, ventana de tiempo y desactivación automática.
- **Frecuencia por convención: valores no redondos** (p. ej. `perf record -F 99` en vez de
  100 Hz). Una frecuencia que coincide con la de un temporizador, un `tick` o un bucle del
  sistema muestrea siempre la misma fase y produce un perfil sesgado con aspecto perfecto.
- **Un perfil de CPU no explica una latencia de espera.** Si el servicio está lento pero la CPU
  está ociosa, el perfil de CPU saldrá vacío de culpables: hace falta perfil **fuera de CPU**
  (bloqueo, planificador, E/S) o trazas. Es el error de diagnóstico más frecuente después de la
  *coordinated omission*.
- **El *flame graph* se lee por anchura, no por altura.** La altura es profundidad de pila; la
  anchura es tiempo. Una pila alta y estrecha no cuesta nada.
- **Perfilar CPU y perfilar asignación de memoria son dos preguntas distintas.** El perfil de
  asignación (*allocation*/*heap*) es el que explica la presión de GC y muchas latencias de
  cola; el de CPU no lo ve. Ambos, o el diagnóstico está incompleto.

### 2.4 OpenTelemetry Profiles — estado verificado, y por qué importa

**Estado: Alpha pública desde el 26-mar-2026** (anuncio oficial de OpenTelemetry, *OpenTelemetry
Profiles Enters Public Alpha*, firmado por la Profiling SIG). Lo verificable del anuncio:

- Formato con deduplicación de pilas y tablas de diccionario; enlace opcional a `trace_id` /
  `span_id` para **correlación entre señales** (perfil ↔ traza); reducción de tamaño en cable
  citada por el propio anuncio como **"40% smaller wire size"** para el diccionario de cadenas.
- Relación con `pprof`, verbatim: *"Originally inspired by the pprof format and developed in
  collaboration with pprof maintainers, OTLP Profiles has evolved into an independent standard...
  Data in the original pprof format can be round-trip converted to/from OTLP Profiles with no
  loss of information."*
- El **perfilador eBPF de sistema completo donado por Elastic** es ya componente oficial del
  Collector (receiver), con simbolización on-target de Go, ARM64 para Node.js/V8, soporte
  inicial de BEAM y .NET 9/10.
- Aviso del propio anuncio, verbatim: *"As the signal is still under development,
  production-ready backends have not yet emerged but multiple vendors are working on supporting
  OpenTelemetry Profiles."*

**Criterio**: **Alpha significa alpha.** Se adopta OTLP Profiles como **formato de destino** al
diseñar hoy (evita quedarse atado a un agente propietario), pero **el respaldo de producción
sigue siendo Pyroscope o Parca**, y el compromiso de arquitectura se revisa en cada release
(§8). Fijar hoy un backend crítico sobre la señal alpha es deuda con fecha.

## 3. La disciplina previa: definir el objetivo antes de medir

### 3.1 Un objetivo de rendimiento sin estas cuatro piezas no es un objetivo

**Métrica + percentil + carga + hardware.** Falta una y el número no es comparable con nada,
ni siquiera consigo mismo la semana siguiente.

```
p99 de latencia de /api/orders  ≤ 300 ms
  con 500 req/s sostenidos (modelo de llegada abierto, Poisson)
  sobre 3 réplicas de 2 vCPU / 4 GiB, base de datos con el conjunto de datos de producción
  medido en el cliente, no en el servidor
```

- **"Rápido" no es un objetivo.** "Menos de 300 ms" tampoco, si no dice a qué percentil ni con
  cuánta carga: cualquier sistema cumple cualquier latencia con un usuario.
- **El objetivo se expresa en términos de usuario**, no de componente: "la búsqueda responde en
  X", no "la consulta tarda Y". El presupuesto por componente se **deriva** del objetivo (§3.3),
  nunca al revés.
- **Se mide en el cliente.** El tiempo que el servidor cree que ha tardado excluye el encolado
  de aceptación, el TLS, y precisamente la cola que causa el problema.

### 3.2 Por qué la media miente, y qué se usa en su lugar

- **La distribución de latencias no es normal**: tiene cola larga a la derecha y suele ser
  multimodal (acierto de caché / fallo de caché; ruta rápida / ruta lenta; con GC / sin GC).
  **Sobre una distribución multimodal la media puede caer en un valle donde no hay ninguna
  petición real.** Una media de 120 ms es compatible con "todas tardan 120 ms" y con "el 90 %
  tarda 20 ms y el 10 % tarda un segundo": son dos sistemas distintos y solo uno es aceptable.
- **La media es insensible a la cola por construcción**; la cola es exactamente lo que el
  usuario recuerda y lo que satura el sistema aguas arriba.
- **La mediana miente igual, con más disimulo.** Se decide con **p99** como mínimo, y con
  **p99.9** en servicios con abanico interno (§3.4).
- **Los percentiles no se promedian y no se suman.** La media de los p99 de diez instancias no
  es el p99 del conjunto; sumar el p99 de tres dependencias no da el p99 del total. Se agrega
  con histogramas (HdrHistogram, `histogram_quantile` sobre *buckets*), nunca con aritmética
  sobre cuantiles ya calculados. Un tablero que promedia percentiles está roto aunque parezca
  bonito.
- **La desviación típica sobre una distribución con cola larga no significa nada.** No se
  reporta.
- **Máximo y p100**: se registran (delatan el peor caso y los *outliers* patológicos), no se
  usan como objetivo — un solo evento fija el número.

### 3.3 Presupuesto de latencia y su reparto

El objetivo de usuario se **divide** entre las etapas del camino, y **la suma de los
presupuestos es menor que el objetivo**, no igual: el margen paga los reintentos, la varianza y
lo que aún no existe.

- El presupuesto se escribe **por dependencia**, con dueño nombrado, en el repositorio.
- **Un servicio no puede prometer un p99 mejor que el peor p99 de su camino crítico.** Antes de
  comprometer un número, se suma el suelo de las dependencias síncronas.
- **Cada salto síncrono añadido consume presupuesto de forma permanente.** Añadir una llamada
  de red a una ruta caliente es una decisión de arquitectura con precio; el precio se escribe
  en el ADR (`microservices-architecture-standards`).
- **Los reintentos multiplican la carga en el peor momento.** Un reintento sin *backoff* con
  *jitter* y sin presupuesto de reintento convierte una degradación en un colapso. El patrón
  es de fiabilidad (`sre-practice-standards`); **el efecto sobre la latencia de cola es de
  aquí**: el reintento es tiempo del usuario.
- **Los tiempos límite (*timeouts*) se derivan del presupuesto, no se copian.** Un *timeout* de
  cliente mayor que el presupuesto de la etapa es un *timeout* decorativo.

### 3.4 Amplificación de la cola: por qué el p99 interno es el p50 del usuario

Si una petición de usuario abre **N** llamadas internas en paralelo y espera a todas, la
probabilidad de que **ninguna** caiga en la cola lenta decae con N. Con N=100 llamadas
independientes y un p99 interno, la probabilidad de que las 100 estén por debajo del p99 es
0,99¹⁰⁰ ≈ **0,366**: es decir, **~63 % de las peticiones de usuario tocan al menos una llamada
por encima del p99 interno**. Es aritmética, no un estudio.

Consecuencias operativas, y son duras:
- **En servicios con abanico se optimiza p99.9, no p99.** El p99 interno ya es el caso típico
  del usuario.
- **Reducir el abanico es una optimización de latencia de primer orden**, a menudo mayor que
  cualquier micro-optimización de código.
- **Un solo componente lento en el camino domina el resultado** por mucho que los demás sean
  rápidos. Ver §5.1 (Amdahl).

## 4. Medir: pruebas de carga que producen un número válido

### 4.1 Coordinated omission — el error de medición más caro y menos conocido

**Qué es.** Término acuñado por **Gil Tene**. El generador de carga **se coordina sin querer
con el sistema medido**: si el siguiente envío depende de que el anterior haya terminado,
cuando el sistema se atasca **el generador deja de enviar** durante justo el intervalo malo.
Resultado: en lugar de las N peticiones lentas que un usuario real habría sufrido, el
histograma registra **una sola** muestra lenta. Los percentiles altos salen **órdenes de
magnitud** mejores de lo que fueron.

**Por qué es tan tóxico**: no es un fallo del sistema medido, es un fallo del que mide, y
**empeora exactamente cuando el sistema empeora** — es decir, la herramienta te miente más
cuanto más importa la verdad. Un generador cerrado puede reportar p99 excelente sobre un
servicio que se para segundos enteros.

**Ilustración canónica** (mecánica, no cifra empírica): objetivo 10 req/s, servicio normal de
50 ms; el sistema se para 5 s. Un generador cerrado registra **una** petición de ~5 s y ninguna
de las ~50 que debía haber enviado en ese hueco. La latencia "corregida" contabiliza también el
tiempo que cada petición pendiente **debería** haber estado esperando desde su instante de
llegada previsto.

**Qué lo evita, verificado**:

| Herramienta | Modelo | Estado verificado |
|---|---|---|
| **`wrk2`** | Tasa constante obligatoria (`-R`), HdrHistogram, reporta latencia **corregida** y **sin corregir** | Diseñado por Tene específicamente contra CO |
| **k6** | `constant-arrival-rate` / `ramping-arrival-rate` = abierto; **VU en bucle = cerrado** | Sus propios documentos lo nombran, verbatim: *"In some testing literature, this problem is known as coordinated omission"* — describiendo su **modelo cerrado** |
| **Gatling** | `injectOpen` (abierto, `rampUsersPerSec`) vs. `injectClosed` (cerrado); **no se pueden mezclar en un escenario** | Elección explícita en el guion |
| **`vegeta`** | `-rate` = abierto por diseño | Un endpoint, no un recorrido |
| **Locust** | Requiere elegir; su documentación advierte de que un test que no alcanza el objetivo de rendimiento muestra tiempos de respuesta artificialmente bajos | Config explícita |
| **JMeter** | *Open Model Thread Group*, verbatim de su documentación: ***"This thread group is experimental, and it might change in the future releases."*** | Los *Thread Group* clásicos son **cerrados** |
| **`ab`, `wrk` (original)** | Cerrados, sin corrección | **Vetado** para medir percentiles (§7) |

**Reglas duras**:
- **El modelo de llegada se declara por escrito en el informe de la prueba.** Un resultado sin
  declarar modelo abierto o cerrado es un número sin unidades.
- **Sistema abierto → generador abierto.** Una API pública, una web, una base de datos con
  clientes independientes son sistemas abiertos: los usuarios reales **no esperan** a que
  terminen los de al lado antes de pulsar. Medirlos con un generador cerrado es medir otro
  sistema.
- **El modelo cerrado es legítimo** cuando el sistema real *es* cerrado: una cola de trabajos
  con N workers fijos, un lote, un cliente interno con concurrencia acotada. La regla no es
  "abierto siempre", es **"el modelo del generador debe ser el modelo del sistema"**.
- **Si el generador alcanza sus propios límites** (CPU, sockets, descriptores, un solo nodo
  contra un clúster), la prueba es **inválida y se descarta** — no se interpreta. Se
  monitoriza el generador con la misma seriedad que el objetivo.
- Al usar `wrk2`, se reporta **la latencia corregida**. Publicar la no corregida sin decirlo es
  publicar el error.

### 4.2 Los cuatro tipos de prueba, y qué responde cada una

Se planifican en `testing-qa-standards`; **la interpretación es de aquí**.

| Tipo | Pregunta | Duración | Señal de fallo |
|---|---|---|---|
| **Carga** | ¿Cumple el objetivo con la carga esperada? | Suficiente para estabilizar | Se supera el presupuesto de latencia |
| **Estrés** | ¿Dónde está el punto de ruptura y **cómo** rompe? | Rampa hasta degradar | Rompe de forma no controlada (sin *shed*, sin degradación, con cascada) |
| **Resistencia (*soak*)** | ¿Se degrada con el tiempo? | Horas o días | Deriva creciente de memoria, descriptores, conexiones, latencia; fragmentación; caché envenenada |
| **Pico (*spike*)** | ¿Sobrevive a un salto brusco y se recupera? | Minutos | No recupera al nivel previo tras el pico — el fallo más caro y el que menos se prueba |

**El *soak* es el que más gente omite y el que más incidentes evita**: las fugas de memoria y
de descriptores no aparecen en una prueba de diez minutos, por definición.

### 4.3 Requisitos de validez de una prueba

Falta **uno** y el resultado no se publica:

1. **Paridad de entorno declarada.** **Una prueba de carga contra un entorno que no es paridad
   de producción no produce un número: produce un número inútil.** Los factores que la rompen y
   no son negociables: **volumen y distribución de datos** (un índice sobre mil filas siempre
   cabe en memoria y siempre es rápido; el plan de consulta puede ser *otro* con el volumen
   real), **topología** (una réplica frente a tres, con o sin balanceador y proxies reales),
   **clase de máquina y vecinos ruidosos**, **latencia de red real entre componentes**,
   **límites de cgroup / *throttling* de CPU**, y **configuración de runtime idéntica** (GC,
   *pools*, *timeouts*). Si no hay paridad, el resultado solo sirve para **comparar consigo
   mismo** entre ejecuciones idénticas, y se escribe así en el informe.
2. **Calentamiento y descarte.** JIT, cachés, *pools* de conexión, tablas de páginas y cachés
   del sistema de ficheros necesitan un periodo de calentamiento **que se descarta del
   resultado**. Incluir el arranque en el histograma contamina la cola con un artefacto.
3. **Datos representativos y con cardinalidad realista.** Un solo usuario, una sola clave o un
   solo producto convierte la prueba en una prueba de caché. La distribución de acceso importa
   tanto como el volumen (Zipf, no uniforme).
4. **Duración suficiente para llegar a estado estacionario** y para que ocurran los eventos
   periódicos: GC mayor, rotación de conexiones, expiración de cachés, tareas programadas,
   *compaction*.
5. **Repetibilidad**: N≥3 ejecuciones. Si la varianza entre ejecuciones supera la diferencia que
   se quiere demostrar, **no se ha demostrado nada**.
6. **Sistema bajo prueba observado durante la prueba**: USE en cada recurso, RED en cada
   servicio. Una prueba que solo produce el número final no permite diagnosticar nada.
7. **Registro reproducible**: versión del artefacto, *commit*, configuración, conjunto de datos,
   herramienta, guion, modelo de llegada y hardware. **Un resultado que nadie puede reproducir
   es una anécdota.**

### 4.4 Microbenchmarks

- **Un microbenchmark mide el microbenchmark.** Es válido para comparar dos implementaciones de
  la misma función, y **no** para predecir la latencia del servicio.
- Se usa el arnés del lenguaje (es suyo: JMH, `go test -bench`, `criterion`, `pytest-benchmark`),
  con calentamiento y significación estadística. **Sin varianza reportada, no se acepta.**
- **El compilador puede eliminar el código medido.** Si el resultado no se consume, la
  optimización lo borra y se mide un bucle vacío. Es un fallo silencioso.
- **Prohibido justificar un cambio de arquitectura con un microbenchmark** (§7).

## 5. El orden correcto de la búsqueda

### 5.1 Ley de Amdahl: el techo lo fija lo que no optimizas

Amdahl (1967, *AFIPS Conference Proceedings* vol. 30, pp. 483-485 — verificar la referencia
antes de citarla en un documento formal, §8). Formulación: si una fracción **p** del tiempo se
acelera un factor **s**, la mejora total es **1 / ((1−p) + p/s)**.

Consecuencia que decide el orden del trabajo: **hacer infinitamente rápida una parte que ocupa
el 5 % del tiempo produce, como máximo, un 5,3 % de mejora.** Por tanto:

1. **Medir el camino caliente completo antes de tocar nada.** La distribución del tiempo por
   etapas es el primer artefacto, siempre.
2. **Optimizar por orden de fracción de tiempo, no por orden de facilidad ni de interés.**
3. **Recalcular después de cada cambio**: al eliminar el cuello, el cuello es otro y la lista
   de prioridades cambia entera. La lista de tareas de rendimiento **caduca en cuanto se
   completa la primera**.
4. **Escalar horizontalmente no arregla lo serializado.** Es el corolario práctico: si el 20 %
   del trabajo es serie (un bloqueo global, una tabla caliente, un servicio único), duplicar
   réplicas no da 2×. La Ley Universal de Escalabilidad de Gunther añade el término de
   **coherencia** (el coste de que las réplicas se pongan de acuerdo), que puede hacer que
   **añadir capacidad empeore el rendimiento**. Verificar formulación antes de citarla (§8).

### 5.2 El árbol de sospechosos, por capa y en este orden

Se recorre de arriba abajo, y **se descarta cada capa con evidencia**, no con intuición:

1. **Trabajo innecesario** — la optimización que siempre gana. ¿Se está calculando algo que
   nadie mira? ¿Se pide más de lo que se usa? ¿Se serializa un objeto entero para leer un
   campo? Se elimina; no se optimiza.
2. **Aplicación**: complejidad algorítmica sobre el tamaño **real** de la entrada; **N+1** de
   consultas o de llamadas remotas (el clásico y el más caro); serialización y deserialización
   (a menudo el mayor consumidor de CPU en un servicio "de red"); copias de datos; bloqueos y
   contención; trabajo síncrono que debía ser asíncrono.
3. **Runtime**: pausas y presión del recolector de basura, tamaño y política del *heap*,
   *pools* mal dimensionados (conexiones, hilos), arranque en frío, JIT. **El ajuste concreto
   es de la skill del lenguaje**; aquí solo la evidencia de que es ahí.
4. **Base de datos**: consulta sin índice, plan cambiado, bloqueos, agotamiento del *pool*,
   transacciones largas, `N+1`. **Se entra por la puerta de la skill del motor con evidencia**:
   la consulta, su plan y su proporción del tiempo total.
5. **Red**: RTT, saltos, MTU, pérdida y retransmisión, TLS handshake, DNS.
   **`network-troubleshooting-standards` diagnostica**; aquí solo se sitúa y se entrega.
6. **Disco / almacenamiento**: latencia de servicio, profundidad de cola, patrón aleatorio vs.
   secuencial, `fsync`, saturación de IOPS.
7. **Kernel y plataforma**: planificador, *throttling* de cgroup (la causa favorita de p99 malo
   en Kubernetes con *limits* de CPU agresivos), NUMA, agotamiento de descriptores, tabla de
   conntrack, presión de memoria.

**Regla transversal**: **la capa se descarta con una medida, no con un argumento.** "No puede
ser la base de datos" no descarta la base de datos.

### 5.3 Latencia frente a rendimiento (*throughput*): mejorar uno empeora el otro

No son la misma magnitud y **se optimizan con técnicas que se oponen**:

| Técnica | Efecto en rendimiento | Efecto en latencia |
|---|---|---|
| Agrupar en lotes (*batching*) | ↑↑ | ↑ (espera a llenar el lote) |
| Cola más profunda | ↑ (absorbe picos) | ↑↑ (más tiempo de espera) |
| Más concurrencia | ↑ hasta saturar | ↑ pasada la saturación |
| Compresión | ↑ si la red es el cuello | ↑ CPU en ambos extremos |
| Ejecución especulativa / peticiones cubiertas (*hedged*) | ↓ (trabajo duplicado) | ↓↓ en la cola |

**Regla dura**: **se declara cuál de los dos se está optimizando antes de empezar.** Un equipo
optimizando rendimiento y otro optimizando latencia sobre el mismo sistema se deshacen el
trabajo mutuamente. Y **una cola más grande nunca arregla un problema de capacidad**: solo
convierte errores rápidos en esperas largas, que es peor.

## 6. Colas, saturación y dimensionado

### 6.1 Ley de Little

**J. D. C. Little (1961), *A Proof for the Queuing Formula: L = λW*, Operations Research
9(3):383-387.** L = número medio de unidades en el sistema, λ = tasa media de llegada, W =
tiempo medio en el sistema. Es **independiente de la distribución** de llegadas, de servicio y
de la disciplina de la cola: por eso se puede aplicar casi siempre.

Forma útil en sistemas: **concurrencia = rendimiento × latencia**. De ahí salen tres cálculos
que se hacen **antes** de tocar configuración:

- **Dimensionar un *pool***: para servir 500 req/s con 40 ms de latencia hacen falta 500 × 0,04
  = **20** peticiones en vuelo. Un *pool* de 200 hilos no da más rendimiento: da 180 hilos
  esperando y una cola oculta.
- **Detectar una medida imposible**: si el generador dice 1000 req/s con 10 ms de latencia y
  solo mantiene 2 conexiones, los números no cierran (2 ≠ 10). **Uno de los tres está mal
  medido** — normalmente la latencia, por *coordinated omission*.
- **Saber cuánta cola hay de verdad**: L crece cuando la latencia crece a rendimiento
  constante. Es la definición operativa de saturación.

### 6.2 Por qué la latencia se dispara cerca del 100 % de utilización

En el modelo **M/M/1** (llegadas Poisson, servicio exponencial, un servidor), con utilización
ρ = λ/μ y tiempo de servicio S = 1/μ, el tiempo de respuesta medio es **R = S / (1 − ρ)**.
Consecuencia aritmética directa —**no es un dato empírico, es el modelo**:

| Utilización ρ | Tiempo de respuesta R |
|---|---|
| 50 % | 2 × S |
| 80 % | 5 × S |
| 90 % | 10 × S |
| 95 % | 20 × S |
| 99 % | 100 × S |

Lo que hay que llevarse, y es lo que rompe casi todos los planes de capacidad:

- **La relación entre utilización y latencia no es lineal: es una asíntota.** Los últimos puntos
  porcentuales de utilización son insoportablemente caros en latencia.
- **Un recurso al 95 % no está "casi bien": está saturado.** El margen no es holgura, es el
  precio de la latencia de cola.
- **La variabilidad empeora la curva.** M/M/1 es el caso *benigno*; con servicio más variable
  que el exponencial (la norma en software real: multimodal, con GC, con fallos de caché) la
  latencia sube antes y más.
- **Nunca se dimensiona a utilización objetivo sin declarar el objetivo de latencia asociado.**
  "Objetivo 80 % de CPU" sin latencia al lado es media decisión. El **número concreto de
  utilización objetivo depende del sistema y se deriva del presupuesto de latencia**: esta
  skill no lo fija (§8).
- **Cualquier tabla de utilización objetivo copiada de un blog es sospechosa.** La derivación
  se hace con el propio S medido y el propio objetivo de p99.

### 6.3 Saturación: qué mirar, no qué suponer

La utilización esconde la saturación. Se vigilan **las colas**, que es donde vive la latencia:
profundidad de cola de ejecución (*run queue*), espera de E/S, cola del *pool* de conexiones,
cola de aceptación de sockets (*backlog*), profundidad de cola del dispositivo de bloque,
*throttling* de cgroup. **Una CPU al 60 % con cola de ejecución permanente está saturada**; el
porcentaje de utilización no lo dice.

### 6.4 Concurrencia, no capacidad, es lo que hay que limitar

- **Los límites de admisión se ponen en concurrencia en vuelo**, no solo en peticiones por
  segundo: es lo que protege de la asíntota de §6.2.
- **Descartar carga (*load shedding*) rápido es mejor que encolarla**: una cola que crece
  indefinidamente convierte un pico en una caída total y arruina también a las peticiones que
  sí se podían haber servido. El diseño de degradación y *shedding* es de
  `sre-practice-standards`; **el argumento de por qué es de aquí**.
- **Reintentos**: multiplican la carga justo cuando el sistema está saturado.

### 6.5 Caché: es una decisión con coste, no un parche

- **Una caché no arregla un algoritmo malo: lo esconde hasta que falla la caché.** Antes de
  cachear, se responde por escrito: ¿por qué es caro lo que se va a cachear, y no se puede
  hacer barato?
- **El coste real de una caché es la invalidación y la coherencia**, no la memoria. Toda caché
  añade: una fuente de verdad ambigua, un modo de fallo nuevo (dato viejo servido como bueno),
  y un escenario de arranque en frío en el que el sistema **no** aguanta su carga nominal.
- **Se declara siempre**: qué invalida cada entrada, cuánto tiempo se tolera el dato viejo, y
  **qué pasa cuando la caché está vacía o caída**. Si la respuesta a lo último es "se cae todo",
  la caché no es una optimización: es un componente crítico sin redundancia.
- **La caché se mide por su efecto en la latencia p99, no por su tasa de aciertos.** Una tasa de
  aciertos del 95 % con el 5 % restante a 2 s deja un p99 espantoso.
- **Los picos de recarga simultánea (*stampede*)** convierten un fallo de caché en una caída.
  Mecánica y mitigación: `caching-cdn-standards`.

## 7. Sostenibilidad y prohibiciones

### 7.1 El registro del trabajo

- **Toda optimización se acompaña de medición previa y posterior, en el mismo entorno, con el
  mismo guion y con varianza reportada.** Sin las dos mitades, el cambio se revierte: no hay
  forma de distinguirlo de ruido.
- **Registro de rendimiento por servicio**, versionado en el repositorio: objetivo vigente,
  línea base con fecha, optimizaciones aplicadas con su medición, y **fecha de revisión**.
- **El código optimizado caduca.** Toda optimización no evidente lleva comentario con: qué se
  midió, cuánto ganó, sobre qué versión de qué dependencia, y **fecha de revisión**. Los
  motivos por los que caduca son rutinarios: cambia el compilador o el JIT, cambia el volumen de
  datos, cambia el hardware, cambia la biblioteca — y la optimización pasa de ser una ventaja a
  ser complejidad que nadie se atreve a tocar. **Una optimización sin fecha de revisión es deuda
  con intereses.**
- **Optimización prematura — el criterio, no la cita.** La regla no es "no optimices": es que el
  coste de una optimización es **complejidad permanente** y su beneficio es **hipotético hasta
  que se mide**. Por tanto: se optimiza cuando (a) hay un objetivo escrito que no se cumple, y
  (b) hay una medición que señala a ese código concreto. Ninguna de las dos condiciones se puede
  sustituir por experiencia. **Excepción explícita**: las decisiones **caras de revertir** —
  esquema de datos, modelo de concurrencia, límite entre servicios, formato de serialización—
  se razonan con órdenes de magnitud **antes** de construir. Eso no es optimización prematura:
  es diseño. Confundir ambas cosas es la lectura perezosa de la frase de Knuth.
- **Cadencia**: revisar por web el estado de las herramientas de perfilado y de OTLP Profiles
  **cada trimestre** mientras la señal siga en alpha (§8). Revisar los objetivos de rendimiento
  cuando cambie el volumen de datos, el hardware o la topología — y como mínimo una vez al año.

### 7.2 Prohibiciones explícitas

- ❌ **Optimizar sin medir antes.** Sin línea base no hay mejora: hay opinión con `git commit`.
- ❌ **Declarar una mejora sin medición posterior** en el mismo entorno y con la misma
  metodología que la línea base.
- ❌ **Decidir con la media.** Y prohibido también el gráfico que solo muestra la media, y el
  tablero que **promedia percentiles** entre instancias o los suma entre servicios (§3.2).
- ❌ **Reportar percentiles obtenidos con un generador de carga cerrado contra un sistema
  abierto**, o sin declarar el modelo de llegada. Es *coordinated omission* y el número es
  falso (§4.1).
- ❌ **`ab` o `wrk` original para medir percentiles.** Sin corrección de CO, sirven para "¿está
  vivo?" y nada más.
- ❌ **Publicar el resultado de una prueba de carga sin declarar la paridad del entorno**, el
  conjunto de datos y el hardware. Y **PROHIBIDO** presentar como capacidad de producción un
  número obtenido en un entorno que no es paridad.
- ❌ **Prueba de carga contra producción sin autorización escrita, ventana acordada y plan de
  parada.** Es una denegación de servicio propia.
- ❌ **Micro-optimizar antes de tener el reparto del tiempo del camino caliente completo** (§5.1).
- ❌ **Justificar una decisión de arquitectura con un microbenchmark** (§4.4).
- ❌ **Añadir una caché para tapar una consulta lenta** sin haber respondido por qué es lenta y
  sin declarar invalidación y comportamiento en frío (§6.5).
- ❌ **Aumentar el tamaño de un *pool*, una cola o un *timeout* como respuesta a la saturación.**
  Es mover el problema a un sitio donde tarda más en verse y duele más cuando aparece (§6.4).
- ❌ **Dimensionar a una utilización objetivo sin objetivo de latencia asociado** (§6.2).
- ❌ **Perfilar en producción con instrumentación no acotada** o con una herramienta sin límite
  de coste y sin desactivación automática (§2.3, §7.3).
- ❌ **Concluir que "la CPU está ociosa, luego no es rendimiento"**: falta el perfil fuera de CPU.
- ❌ **Comparar dos ejecuciones con datos, versiones o entornos distintos** y llamarlo mejora.
- ❌ **Adoptar OTLP Profiles como respaldo de producción crítica** mientras siga en alpha (§2.4).
- ❌ **Fijar Pyroscope, k6 o FlameGraph en un producto sin revisar su licencia** (AGPL-3.0,
  AGPL-3.0 y CDDL respectivamente, §2.2).
- ❌ **Copiar de un blog una tabla de "utilización objetivo" o de "p99 recomendado"** en vez de
  derivarla del propio presupuesto y de la propia medición.

### 7.3 Perfilar en producción sin abrir un agujero

- **Los perfiles llevan datos.** Nombres de función, rutas de fichero, símbolos y —en perfiles
  de asignación y volcados de *heap*— **contenido**. Un volcado de memoria es material de
  máxima sensibilidad: contiene secretos en claro, tokens y datos personales. Se trata con el
  control de acceso del dato más sensible que atraviese el proceso, no con el del repositorio.
- **eBPF y `perf` son privilegio.** `perf` requiere ajustar `perf_event_paranoid` o
  `CAP_PERFMON`; eBPF requiere `CAP_BPF` (más `CAP_PERFMON` / `CAP_SYS_ADMIN` según el caso).
  Bajar `perf_event_paranoid` a nivel de nodo abre superficie de canal lateral entre inquilinos.
  El endurecimiento del contenedor y del nodo es de `container-runtime-security-standards` y
  `linux-hardening-standards`; **aquí la regla es que el privilegio se concede acotado, con
  ventana y con registro, no de forma permanente "por si acaso"**.
- **El coste del perfilado se mide, no se supone.** El perfilado continuo se justifica por ser
  de coste bajo y acotado; ese coste se **verifica** en el propio sistema antes de dejarlo
  encendido, y se vigila.
- **Un símbolo mal resuelto miente.** Sin `debuginfo`/símbolos, el *flame graph* atribuye tiempo
  a direcciones o a marcos incorrectos, y se optimiza el sitio equivocado con total convicción.
  Verificar la simbolización antes de creerse el perfil.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un proyecto real:

1. **USE y RED — origen y formulación**: releer `brendangregg.com/usemethod.html` y el artículo
   de Grafana *The RED Method: How to Instrument Your Services* y copiar las definiciones
   **verbatim**. **Discrepancia declarada** (§2.1): el artículo de Grafana encabeza la lista de
   RED con *"For every resource, monitor:"* pese a argumentar en el párrafo anterior que RED
   existe porque USE no aplica a servicios. Comprobar si la fuente se ha corregido; hasta
   entonces, citar la tríada, no el encabezado. Verificar también la fecha de creación de RED
   (Grafana la sitúa en **2015**) y las referencias de publicación de USE (blog de dtrace.org
   29-feb-2012; ACM Queue 2012; CACM 2013).
2. **Coordinated omission**: revisar la documentación **vigente** de la herramienta que se vaya
   a usar y confirmar qué modelo aplica **por defecto**. Verificado a ago-2026: k6 nombra el
   problema en sus documentos de *open vs closed model* (*"In some testing literature, this
   problem is known as coordinated omission"*) refiriéndose a su modelo cerrado; el *Open Model
   Thread Group* de JMeter sigue declarado ***"experimental, and it might change in the future
   releases"***. **Comprobar si JMeter lo ha estabilizado** antes de apoyarse en él.
3. **Versiones y estado verificados a ago-2026, todos caducables**: k6 **v2.1.0** (30-jun-2026),
   Gatling **v3.15.1** (25-may-2026), `bpftrace` **v0.26.1** (2-jun-2026), Pyroscope con
   releases semanales activas, Parca activo. **JMeter sigue en 5.6.3 (ene-2024)** según su web
   oficial `jmeter.apache.org/download_jmeter.cgi`: **más de dos años sin release**, dato a
   reconfirmar antes de recomendarlo. Recordar que **el feed de releases de GitHub no es la
   fuente de verdad**: Apache publica en su propio sitio, y varios proyectos del catálogo se han
   mudado de registro.
4. **Licencias — leer el `LICENSE` en crudo, siempre**. Verificado a ago-2026: **k6 AGPL-3.0**,
   **Pyroscope AGPL-3.0**, **FlameGraph CDDL**, Parca Apache-2.0, `bpftrace` Apache-2.0, `wrk2`
   Apache-2.0, Gatling Open Source Apache-2.0, Locust MIT, `vegeta` MIT, `perf` GPL-2.0
   (SPDX en el árbol del kernel). Las tres primeras son las que más gente da por permisivas.
5. **OpenTelemetry Profiling**: estado del ciclo de vida. Verificado: **Alpha pública desde el
   26-mar-2026**, con aviso propio verbatim de que *"production-ready backends have not yet
   emerged"*. **Comprobar si ha pasado a Beta/GA** y qué respaldos lo soportan de verdad, antes
   de comprometer arquitectura.
6. **Grafana Profiles Drilldown**: verificado como **public preview**, no GA. Confirmar estado
   antes de depender de su UI.
7. **Referencias académicas a confirmar antes de citarlas en un documento formal**: Little
   (1961), *A Proof for the Queuing Formula: L = λW*, *Operations Research* 9(3):383-387 —
   verificado en fuentes secundarias coincidentes, **no en el artículo original**. Amdahl (1967),
   AFIPS vol. 30, pp. 483-485 — **misma advertencia**. La Ley Universal de Escalabilidad de
   Gunther se menciona sin fijar su formulación: **verificarla antes de usarla para dimensionar**.
8. **Hueco declarado — utilización objetivo**: este documento **no fija** una cifra de
   utilización objetivo (ni 70 %, ni 80 %, ni ninguna). Circulan por la web como si fueran
   universales y **no se ha encontrado una fuente primaria que las respalde como umbral
   general**. La tabla de §6.2 es aritmética del modelo M/M/1, no una recomendación empírica: el
   objetivo propio se **deriva** del presupuesto de latencia y del tiempo de servicio medido.
9. **Hueco declarado — coste del perfilado continuo**: no se fija aquí ningún porcentaje de
   sobrecarga ("menos del 1 %" y similares circulan sin fuente primaria contrastable). **Se mide
   en el sistema propio** antes de dejarlo encendido.
10. **Hueco declarado — el 80 % / 5 % de USE**: es una afirmación del autor del método en su
    propia página, **no un resultado medido**. Citarla como tal o no citarla.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
