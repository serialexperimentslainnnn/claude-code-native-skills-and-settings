---
name: julia-standards
description: Use when writing, reviewing or deploying Julia code - .jl files, Project.toml, Manifest.toml, JuliaProject.toml, .JuliaFormatter.toml, Pkg REPL mode and Pkg.instantiate, juliaup channels, multiple dispatch and method definitions, type stability with @code_warntype or @inferred, @allocated/@benchmark/BenchmarkTools, @inbounds/@simd/@views broadcasting, Threads.@spawn/@threads/Distributed, ccall/PythonCall/PyCall/RCall interop, Test/Aqua.jl/JET.jl suites, Documenter.jl docs, or PackageCompiler/juliac binaries.
---

# Estándares Julia (referencia: agosto 2026)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo en Julia: paquetes, código numérico, entornos, tests, empaquetado y despliegue.
Triggers: `.jl`, `Project.toml`, `Manifest.toml`, `.JuliaFormatter.toml`, `test/runtests.jl`, `juliaup`,
`Threads.@spawn`, `@code_warntype`, `ccall`, `PythonCall`.

**Los dos ejes de esta skill.** (1) **El despacho múltiple es el lenguaje**: no es azúcar sobre OOP,
es el mecanismo de composición y de extensión, y casi todo error de diseño en Julia es un error de
diseño del despacho (jerarquías de tipos mal cortadas, *type piracy*, métodos demasiado específicos o
demasiado laxos). (2) **La latencia** ("time to first plot") es la objeción histórica del lenguaje y
hay muchísima información caducada al respecto: el problema no está resuelto, está **acotado** — la
caché de código nativo llegó en **1.9**, no en las versiones recientes, y el trabajo actual va por
*trimming* y binarios autónomos. Cualquier afirmación sobre latencia se verifica contra la versión que
vas a usar, no contra un blog de 2022.

**No aplica**: ver `mlops-standards` (**el ciclo de vida del modelo es suyo**: registro y versionado
de modelos, *feature store*, servicio, monitorización de deriva, reentrenamiento, *train/serve skew* —
**cómo se escribe el Julia que entrena o puntúa es de aquí**), `data-engineering-standards` (ingesta,
orquestación, idempotencia, *backfill*, Parquet, SLA de frescura: la plataforma es suya; el código de
cálculo que la consume es de aquí), `analytics-bi-standards` (el cuadro de mando y quién decide con
él; el código que produce las cifras, de aquí), `data-warehouse-modeling-standards` (la forma del
modelo analítico), `lakehouse-standards` (formato de tabla y catálogo),
`sql-standards` (**el SQL que escribes vía `DBInterface`/`LibPQ` está sujeto a su criterio**),
`python-standards` (§7 fija cuándo la respuesta correcta es Python), `r-standards` (estadística y
comunicación de resultados; ver §7), `gpu-computing-standards` (la GPU como recurso que se
aprovisiona, comparte, monitoriza y paga: driver, CUDA, MIG, cuotas, coste; **el kernel y el código
`CUDA.jl`/`KernelAbstractions.jl` que la usa es de aquí**), `llm-app-engineering-standards` y
`rag-standards` (capa de aplicación de IA), `ai-governance-standards` (gobernanza y cumplimiento),
`c-standards`/`cpp-standards` (**el código nativo al otro lado de un `ccall`**: memoria, UB,
sanitizers, ABI; la frontera desde Julia —`ccall`, `Ptr`, `GC.@preserve`, `unsafe_*`, JLL— es de
aquí), `cicd-standards` (la pipeline que ejecuta los gates de §4), `kubernetes-standards` (imagen y
despliegue), `appsec-standards` (modelado de amenazas agnóstico; aquí solo los *sinks* de Julia),
`vulnerability-management-standards` (triaje y SLA del hallazgo; aquí solo el estado del escaneo),
`secrets-management-standards`, `observability-standards` (pipeline OTel/Prometheus; aquí solo la
instrumentación en el código), `api-design-standards` (el **contrato** de un servicio HTTP en Julia:
recursos, códigos, paginación, versionado).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Verificado a ago-2026 | Por qué |
|---|---|---|---|
| Runtime (producción) | **LTS** salvo necesidad concreta | **1.10.11 (2026-03-09)** es la LTS vigente | Julia soporta cada minor **solo hasta que sale la siguiente**: 1.11 ya está EOL. Sin LTS, "estable" implica upgrade cada ~4-5 meses |
| Runtime (features/rendimiento) | **Estable actual** | **1.12.6 (2026-04-09)** | 1.12 caducará al salir 1.13. **1.13 aún no es final a ago-2026** (rc2 el 2026-07-29); `master` ya es 1.14-dev |
| Instalador/versiones | **`juliaup`** con canales `lts` y `release` | 1.20.9 (2026-07-28) | Nunca el Julia del gestor de paquetes de la distro |
| Entornos | `Pkg` + `Project.toml` por proyecto | — | Un entorno por proyecto; jamás instalar en el entorno global `@v1.x` |
| Reproducibilidad | **`Manifest.toml` versionado en aplicaciones** | — | Ver §3: en **paquetes** el `Manifest.toml` NO se versiona |
| Formato | **`JuliaFormatter`** con `.JuliaFormatter.toml` | 2.12.4 (2026-07-31) | Cadencia de releases muy alta: **pin exacto** o el CI rompe solo |
| Análisis estático | **`JET.jl`** | 0.12.0 (2026-07-28) | Pre-1.0 y **acoplado a los internos del compilador**: la versión de JET depende de la de Julia |
| Calidad de paquete | **`Aqua.jl`** | 0.8.16 (2026-06-05) | Detecta *type piracy*, ambigüedades de método, exports rotos, deps sin usar, `[compat]` incompleto |
| Tests | `Test` (stdlib) | — | Suficiente; `TestItems`/`ReTest` solo si la ergonomía lo justifica |
| Benchmarks | **`BenchmarkTools.jl`** (`@benchmark`, `@btime`) | — | `@time` a secas mide compilación en la primera llamada: no sirve para medir |
| Documentación | **`Documenter.jl`** | 1.17.0 (2026-02-20) | *Doctests* en CI |
| Binario autónomo | **`PackageCompiler.jl`** (*sysimage*) / **`juliac`+`--trim`** (ejecutable) | PackageCompiler 2.4.0 (2026-06-10) | `--trim` es **experimental** (1.12+) y exige `--experimental`; requiere ausencia de despacho dinámico alcanzable |
| Interop Python | **`PythonCall.jl`** en código nuevo | — | `PyCall.jl` en modo mantenimiento; PythonCall aísla el entorno con CondaPkg y es *type-stable* por defecto |
| Interop R | `RCall.jl` | — | — |

**Criterio de versión**: si el servicio tiene SLA y no vas a dedicar una ventana de upgrade cada 4-5
meses, **LTS**. Si necesitas *trimming*, las mejoras de hilos o un paquete que ya solo soporta 1.12+,
estable — asumiendo el upgrade a 1.13 en cuanto salga. **No mezcles**: la versión de Julia se fija en
`[compat]` y en el CI, y el mismo número corre en local, en CI y en producción.

## 3. Estructura y convenciones

```
MiPaquete/
  Project.toml       # name, uuid, version, [deps], [compat] OBLIGATORIO
  Manifest.toml      # paquete: .gitignore  |  aplicación/servicio: versionado
  src/MiPaquete.jl   # módulo raíz; includes y exports
  test/runtests.jl   # + Project.toml propio en test/
  docs/              # Documenter
  ext/               # extensiones de paquete (weak deps)
```

- **`Manifest.toml`: la regla que más se incumple.** En una **aplicación** (servicio, pipeline,
  análisis que debe reproducirse) se **versiona siempre**: es el lockfile, y sin él `Pkg.instantiate()`
  resuelve versiones distintas cada día. En una **librería publicable** **no** se versiona: fijaría el
  árbol de dependencias de tus consumidores. La reproducibilidad de una librería la da `[compat]`,
  no el manifest. Despliegue: `Pkg.instantiate()` sobre el manifest versionado, nunca `Pkg.update()`.
- **`[compat]` es obligatorio** para toda dependencia y para `julia`. Sin él, el registro General ni
  siquiera acepta el paquete, y un `[compat]` con límite superior abierto convierte cualquier release
  ajena en un fallo tuyo. Usa límites SemVer (`"1"`, `"0.8.3"`), no `">=x"`.
- Registro: **General** por defecto; registro privado (`LocalRegistry`) para código interno. Nunca
  `Pkg.add(url=...)` a una rama en producción — o entra por registro, o se fija por commit en el manifest.
- Nombres: tipos `UpperCamelCase`, funciones y variables `lowercase`/`snake_case` sin subrayados si se
  lee bien, constantes `UPPER`; sufijo `!` en toda función que **muta** sus argumentos (y el argumento
  mutado va **primero**). Módulos = nombre del paquete.
- Exports mínimos: exporta lo que es API, el resto se accede cualificado. Todo lo exportado se
  documenta y entra en SemVer.
- Ficheros por concepto, no un `utils.jl`; `include()` solo desde el módulo raíz, en orden explícito.

**Tipos y despacho — las reglas duras:**
- Diseña **funciones genéricas con métodos**, no jerarquías. Los tipos abstractos definen *interfaces*
  (qué métodos deben existir), y esa interfaz se **documenta**: Julia no la verifica por ti.
- **Anota los tipos de los campos de un `struct`, siempre.** Un campo `::Any` (o un tipo paramétrico
  no concreto) destruye el rendimiento de todo lo que toque el objeto. Usa parámetros de tipo
  (`struct Punto{T<:Real}`) en vez de campos abstractos.
- `struct` **inmutable por defecto**; `mutable struct` solo cuando el estado tiene que cambiar.
- Anotar los tipos de los **argumentos** no acelera nada: sirve para el despacho y para documentar el
  contrato. Sé lo más genérico que puedas (`AbstractVector{<:Real}`, no `Vector{Float64}`), salvo que
  quieras restringir deliberadamente.
- **`Union{}` y `Any` en una inferencia son síntoma**: `Union{}` como tipo de retorno significa "esto
  siempre lanza"; `Any` significa que el compilador se rindió. Ambos aparecen en `@code_warntype`.

**Type piracy: antipatrón grave.** Definición del manual: *"«Type piracy» refers to the practice of
extending or redefining methods in Base or other packages on types that you have not defined."* Si ni
la función ni ninguno de los tipos del método son tuyos, estás pirateando: cambias el comportamiento
de código ajeno de forma global e invisible, y el resultado puede ir desde un bug remoto e imposible
de rastrear hasta, en casos extremos, tumbar Julia. Alternativas: define tu propio tipo envoltorio,
tu propia función, o usa un `struct` con el comportamiento deseado. `Aqua.jl` lo detecta — **haz que
ese test bloquee el merge**.

**Estilo de errores**: excepciones tipadas propias (`struct MiError <: Exception`) con `showerror`;
`ArgumentError`/`DomainError`/`BoundsError` de Base cuando encajan. `@assert` es para invariantes
internas y **puede desaparecer con `--check-bounds=no`/optimizaciones**: no lo uses para validar
entrada. Nada de `catch e end` vacío; `try/finally` (o los patrones `do`-block) para liberar recursos.

## 4. Calidad: formato, análisis, tests

- **Formato**: `JuliaFormatter` con `.JuliaFormatter.toml` versionado, comprobado en CI. **Pin exacto
  de la versión** en el entorno de CI: publica varias versiones por semana y un cambio de estilo
  rompe el gate sin que nadie haya tocado el código.
- **Análisis estático**: `JET.jl` (`report_package`) sobre el paquete. Realista: JET es **pre-1.0** y
  depende de los internos del compilador, así que un upgrade de Julia puede cambiar sus hallazgos.
  Introdúcelo como job **informativo** primero y conviértelo en gate cuando la línea base esté limpia;
  nunca lo dejes flotando de versión.
- **`Aqua.jl` como gate**: `Aqua.test_all(MiPaquete)` en `runtests.jl`. Cubre lo que ninguna revisión
  humana pilla: piratería de tipos, ambigüedades de método, `[compat]` incompleto, deps declaradas y
  no usadas, exports que no existen.
- **Tests (`Test` stdlib)**:
  - `@testset` anidados por unidad de comportamiento; un motivo de fallo por test.
  - Bordes obligatorios: colección vacía, un elemento, `NaN`/`Inf`/`-0.0`, desbordamiento de enteros
    (**`Int` en Julia envuelve en silencio**, no promociona), matriz singular, tipo inesperado,
    `missing` propagándose, índices fuera de rango.
  - Números en coma flotante: `≈` (`isapprox`) con `atol`/`rtol` **explícitos**, jamás `==`.
  - **`@inferred` sobre las funciones del camino caliente**: convierte "esto era type-stable" en un
    test que falla cuando alguien lo rompe. Es el test más valioso de un paquete Julia.
  - `Random`: semilla explícita por test (`StableRNGs` si el resultado debe ser idéntico entre
    versiones de Julia — **el flujo del RNG de `Random` puede cambiar entre minors**).
  - Todo bug arreglado deja test de regresión. Flaky = se arregla o se borra.
- **Gates de CI** (bloquean el merge, lo barato primero):
  1. `JuliaFormatter` en modo comprobación (versión fijada).
  2. `Pkg.instantiate()` reproducible + `Aqua.test_all`.
  3. `Pkg.test()` con cobertura (`Coverage.jl`/Codecov); umbral acordado, la cobertura es señal.
  4. `@inferred` / benchmarks de regresión de rendimiento en las rutas críticas.
  5. `JET.jl` (informativo → gate) y doctests de `Documenter`.
  6. Auditoría de dependencias (§5) y build del artefacto.
- **Matriz de CI**: LTS + estable + `nightly` (este último permitido fallar). Si soportas ambas líneas,
  ambas se testean — decirlo en el README sin testearlo es mentir.

## 5. Seguridad del stack

- **`Serialization` (`serialize`/`deserialize`): no es un formato de intercambio ni es seguro.**
  Documentación oficial: *"`deserialize` assumes the binary data read from `stream` is correct and has
  been serialized by a compatible implementation of `serialize`. `deserialize` is designed for
  simplicity and performance, and so does not validate the data read. Malformed data can result in
  process termination."* Además, *"The data format can change in minor (1.x) Julia releases"* y el
  tamaño de palabra (32/64 bits) de la máquina que lee y la que escribe **debe coincidir**. Reglas:
  **PROHIBIDO** deserializar entrada no confiable; **PROHIBIDO** usar `Serialization` como formato de
  persistencia entre versiones o entre máquinas. Para datos: JLD2, Arrow, Parquet, JSON o un formato
  propio versionado, siempre validado al leer.
- **`eval` y metaprogramación**: `@eval`/`eval` sobre cadenas construidas con entrada de usuario, y
  `Meta.parse` de input, son **ejecución de código arbitraria: PROHIBIDO**. Además, `eval` en tiempo de
  ejecución invalida código compilado y provoca recompilación (coste de latencia). Las macros son para
  transformación sintáctica en tiempo de compilación; si una macro puede ser una función, es una
  función. `include()` de rutas construidas con input: prohibido.
- **`ccall` y `unsafe_*`**: `ccall` es una frontera de confianza total — un error de firma es
  corrupción de memoria, no una excepción. Reglas: firmas verificadas contra la cabecera real,
  `GC.@preserve` alrededor de cualquier puntero a memoria gestionada por Julia que cruce la frontera,
  y `unsafe_load`/`unsafe_wrap`/`unsafe_store!` solo con longitud y propiedad verificadas. Binarios de
  terceros: paquetes **JLL** del ecosistema (BinaryBuilder), nunca `.so` descargados a mano.
- **`@inbounds` y `@simd` son inseguros por construcción.** `@inbounds` **elimina la comprobación de
  límites**: con un índice erróneo lees o escribes fuera del array — corrupción de memoria silenciosa,
  no `BoundsError`. `@simd` promete al compilador que las iteraciones son independientes y que puede
  reordenar las operaciones (incluida la aritmética de coma flotante, con lo que **el resultado
  numérico puede cambiar**). Criterio: solo tras medir que aportan, solo en bucles cuyos índices se
  demuestran correctos por construcción, con un test que cubra los extremos, y nunca sobre índices
  derivados de entrada externa. `--check-bounds=no` a nivel global: **PROHIBIDO** en producción.
- **Auditoría de dependencias: el ecosistema es inmaduro y hay que decirlo.** A ago-2026 **no existe
  un `Pkg.audit`** en Pkg (sigue siendo propuesta abierta). Lo que sí existe: el **Julia Security
  Advisory Database** (`SecurityAdvisories.jl`), con avisos identificados como `JLSEC-YYYY-nnn` en
  formato compatible con **OSV**, y el **Security Working Group** creado en 2025-11. Práctica hoy:
  consumir esos avisos desde un escáner compatible con OSV sobre el `Manifest.toml`, y **asumir
  cobertura parcial** — en particular la de los >1500 paquetes **JLL**, que reempaquetan binarios de
  terceros cuyos CVE no se mapean automáticamente al nombre del JLL. Esta es la mayor superficie de
  riesgo del ecosistema y hoy **no está cubierta de forma fiable**. No inventes una herramienta que no
  existe; declara el hueco (§8).
- **SQL / comandos**: consultas parametrizadas vía `DBInterface.execute(stmt, params)`; interpolar
  input en SQL es veto absoluto. Los backticks de `Cmd` (`run(`cmd $arg`)`) **no** pasan por shell y
  eso protege de inyección de shell — pero `run(`sh -c $x`)` sí es inyección. Nunca construyas un
  `Cmd` a partir de una cadena con input.
- **Secretos**: variables de entorno o gestor; nunca en `Project.toml`, en el código, en `LocalPreferences.toml`
  ni en notebooks Pluto exportados. Cuidado con las salidas de `@show`/`dump` sobre estructuras de config.
- **Servicios HTTP**: valida y limita el tamaño del cuerpo, timeouts en toda llamada saliente, y no
  devuelvas *stack traces* al cliente — la traza de Julia expone rutas internas y nombres de paquetes.
- **Contenedores**: imagen basada en la oficial `julia:<version>` con versión exacta, non-root,
  multi-stage. **La imagen es grande** — el depósito de paquetes precompilados (`~/.julia`) pesa lo
  suyo y el *sysimage* de `PackageCompiler` añade cientos de MB. Precompila **en el build**
  (`Pkg.precompile()`), nunca en el arranque del contenedor, y descarta el compilador y las fuentes de
  build en la etapa final.

## 6. Rendimiento y operabilidad

**La estabilidad de tipos es el criterio de rendimiento número uno.** Si el compilador puede inferir
un tipo concreto para cada valor, genera código especializado comparable a C; si no, cae a despacho
dinámico y asignaciones, y pierdes uno o dos órdenes de magnitud. Protocolo, en este orden:
1. `@code_warntype` sobre la función: cualquier cosa en rojo (`Any`, `Union{...}` ancho) es el bug.
2. `@inferred` en el test para que no vuelva.
3. `@allocated`/`@benchmark`: en un bucle numérico bien escrito, las asignaciones tienden a **cero**.
   Asignaciones inesperadas = inestabilidad de tipos o copias accidentales.
4. `Profile`/`ProfileView` para localizar; nunca optimices sin haber medido.

Asesinos silenciosos concretos:
- **Variables globales no tipadas**: un global sin `const` puede cambiar de tipo, así que el
  compilador no infiere nada de él y todo su uso pasa a dinámico. Regla: **el trabajo va dentro de
  funciones**, con los datos como argumentos; los globales necesarios se declaran `const` (o con
  anotación de tipo). Un script de nivel superior con un bucle pesado es el patrón más lento posible.
- Contenedores con tipo abstracto: `Vector{Any}`, `Dict{String,Any}`, o un `struct` con campos `Any`.
- Funciones que devuelven tipos distintos según una rama.
- *Closures* que capturan variables cuyo tipo cambia.

Memoria y asignaciones:
- **`@views` / `view` en vez de copias** al rebanar arrays (`A[:, 1]` **copia**). En bucles calientes,
  la diferencia es todo.
- *Broadcasting* con `.` se **fusiona** en un solo bucle sin temporales (`@.` para no olvidar un punto);
  encadenar operaciones sin `.` crea un array temporal por operación.
- Preasigna y usa las variantes `!` (`mul!`, `map!`, `sort!`) en el camino caliente.
- Arrays con tipo de elemento concreto y `StaticArrays` para vectores pequeños de tamaño fijo.

**Latencia (TTFX) — estado real, sin folclore**: la caché de **código nativo** existe desde **Julia
1.9** (*package images*); a cambio, la precompilación es más lenta y las cachés más grandes. Sigue
habiendo latencia en la primera ejecución de código no cacheado. Herramientas por orden de coste:
(a) precompilar en el build de la imagen; (b) cargas de trabajo de precompilación en el propio
paquete (`PrecompileTools`); (c) *sysimage* con `PackageCompiler`; (d) ejecutable autónomo con
`juliac --trim` (**experimental**, 1.12+, requiere `--experimental` y **falla si hay despacho dinámico
alcanzable desde el punto de entrada** — es decir, exige código estrictamente inferible). Para
CLIs y funciones cortas y frecuentes, la latencia sigue siendo un argumento en contra de Julia (§7).

Paralelismo:
- **Hilos** para memoria compartida: `Threads.@spawn` + `fetch`, `Threads.@threads` para bucles
  homogéneos. Desde **1.12** hay por defecto **1 hilo interactivo además del de trabajo** (`-t1,1`),
  y `Threads.@spawn :samepool` para no saltar de *threadpool*. `--gcthreads`/`JULIA_NUM_GC_THREADS`
  controla los hilos del GC. Los hilos de Julia son **reales, sin GIL** — y por eso las carreras de
  datos también son reales: sin sincronización explícita (`Atomic`, `ReentrantLock`, canales) el
  código con estado compartido mutable es incorrecto, no lento.
- Las tareas **migran entre hilos** dentro de un mismo *threadpool*: no asumas afinidad ni uses
  `threadid()` para indexar buffers por hilo (patrón roto clásico); usa `OncePerTask`/estructuras por
  tarea o particiona el trabajo explícitamente.
- **`Distributed`** (o `MPI.jl`) para multiproceso/multinodo cuando el problema no cabe en una máquina
  o cuando quieres aislamiento. Coste: serialización entre procesos y arranque de *workers*.
- Nunca lances más hilos que los núcleos asignados al contenedor: fija `JULIA_NUM_THREADS` de forma
  explícita en el despliegue.

Operabilidad:
- Logging estructurado sobre `Logging` con *correlation id*; métricas y trazas exportadas
  (`observability-standards` para el pipeline). Endpoints `/healthz` y `/readyz` en servicios.
- Timeouts explícitos en toda llamada saliente; `Base.exit_on_sigint(false)` y manejo de SIGTERM para
  apagado limpio de tareas y conexiones.
- Fija la semilla y registra la versión de Julia y el hash del `Manifest.toml` junto a cualquier
  resultado numérico publicado: sin eso no es reproducible aunque el código esté en git.
- Interop: `PythonCall` respeta el GIL — el paralelismo real termina en la frontera con Python; toda
  llamada `ccall` larga bloquea puntos de seguridad del GC salvo `@ccall ... gc_safe=true`.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: minors cada ~4-5 meses, **cada minor soportado solo hasta que sale el siguiente**.
  Elegir "estable" implica un compromiso de upgrade continuo; elegir LTS implica quedarse fuera de
  features durante años y aceptar que **paquetes del ecosistema empiezan a exigir 1.12+**. Es una
  decisión de operación, no de gusto: decídela explícitamente y ponla en el `[compat]`.
- Ecosistema pre-1.0: gran parte de los paquetes viven en `0.x`, donde SemVer da a `0.x.y → 0.(x+1).0`
  categoría de ruptura. `[compat]` estricto y upgrades con la suite verde, no `Pkg.update()` a ciegas.
  Una dependencia crítica pre-1.0 con un único mantenedor es riesgo de proyecto: mídelo.
- El ecosistema es **más pequeño que el de Python o R**. Antes de adoptar: mantenimiento reciente,
  número de mantenedores, y si el paquete sigue a la última LTS. La respuesta "lo escribimos nosotros"
  es más frecuente aquí — y es un coste, no una ventaja.
- Deprecaciones propias: `Base.depwarn` + changelog + ventana; las de terceros son deuda con issue.
- **Deuda del análisis que se convierte en servicio**: un script de investigación con globales,
  `include()` en cadena y estado de nivel superior **no se envuelve en un servidor HTTP: se reescribe
  como paquete con tests, tipos anotados y `@inferred` en el camino caliente**. En Julia esto no es
  solo higiene: el código de nivel superior con globales no tipados es además el patrón más lento del
  lenguaje, así que la deuda se cobra en latencia y en factura de CPU desde el primer día.

**Cuándo NO elegir Julia** (honestidad primero):
- ❌ CLI o *serverless* de arranque frecuente y ejecución corta: la latencia de arranque te come, salvo
  que asumas `juliac --trim` (experimental) o un *sysimage* y sus limitaciones.
- ❌ Backend web/CRUD, integración de sistemas, *scripting* de infraestructura: ecosistema mucho más
  pobre y equipo de mantenimiento más difícil de encontrar.
- ❌ Julia "porque es más rápido" **antes de haber medido Python vectorizado (NumPy/Polars) o R con
  `data.table`**. Si el trabajo ya es una llamada a BLAS o a una librería nativa, Julia no te dará nada.
- ❌ Julia porque una persona del equipo la conoce, en un artefacto con SLA que mantendrán otros.
- ✅ **Julia sí es la respuesta correcta** cuando el cuello de botella es **un bucle numérico que no se
  puede vectorizar** (simulación paso a paso, resolución de EDO/EDP, optimización, métodos de
  Monte Carlo, autodiferenciación sobre código propio), y hoy la alternativa es "prototipo en Python +
  reescritura en C++" — es decir, cuando eliminar el **problema de los dos lenguajes** es el beneficio
  real. También cuando quieres composición genérica entre librerías (unidades, números duales,
  incertidumbre) que en otros lenguajes exigiría reescribir la librería.
- ✅ **Python** (ver `python-standards`) cuando el trabajo es ingeniería alrededor del cálculo:
  servicio, integración, ML de producción, orquestación, o cuando el ecosistema ya tiene la librería.
- ✅ **R** (ver `r-standards`) para modelado estadístico, bioestadística, gráficos publicables e
  informes reproducibles. **La elección casi nunca es "R o Julia"**: comparten el nicho de "lenguaje
  científico que no es Python" y nada más — R es estadística y comunicación de resultados, Julia es
  rendimiento numérico.

**Lista de prohibiciones (veto):**
- ❌ Aplicación o servicio desplegado sin `Manifest.toml` versionado; `Pkg.update()` en despliegue.
- ❌ Publicar un **paquete** con `Manifest.toml` versionado, o sin `[compat]` para todas sus deps.
- ❌ Instalar dependencias en el entorno global `@v1.x` de un proyecto.
- ❌ `deserialize()` sobre entrada no confiable; `Serialization` como formato de persistencia o de
  intercambio entre versiones/máquinas.
- ❌ `eval`/`@eval`/`Meta.parse` sobre entrada de usuario. `include()` de ruta construida con input.
- ❌ **Type piracy** (métodos sobre funciones y tipos que no son tuyos). `Aqua.jl` debe bloquearlo.
- ❌ `@inbounds` sin haber probado que los índices son correctos; `--check-bounds=no` en producción;
  `@simd` sobre iteraciones no independientes o donde el resultado numérico deba ser determinista.
- ❌ Trabajo pesado en el nivel superior del script; globales mutables no tipados como configuración.
- ❌ `struct` con campos de tipo abstracto o `Any` en la ruta caliente.
- ❌ `@time` como medida de rendimiento (mide compilación); optimizar sin `@code_warntype` previo.
- ❌ `threadid()` para indexar estado por hilo (las tareas migran).
- ❌ Estado compartido mutable entre hilos sin sincronización explícita.
- ❌ `catch e end` vacío; `@assert` para validar entrada de usuario.
- ❌ `ccall` sin `GC.@preserve` sobre memoria gestionada por Julia; `.so` de terceros fuera de un JLL.
- ❌ Correr en una versión EOL (1.11 lo está) "porque funciona".
- ❌ Dejar `JuliaFormatter` o `JET.jl` sin versión fijada en CI.

## 8. Verificación web obligatoria

Antes de fijar versiones o decisiones, **verifica online** (WebSearch/WebFetch; para versiones, feeds
Atom de GitHub Releases y `julialang.org/downloads/manual-downloads` — no el resumidor sobre HTML de
GitHub Releases):
1. **Estable y LTS actuales y cuál está EOL** (`julialang.org/downloads/manual-downloads`,
   `endoflife.date/julia`). A ago-2026: estable **1.12.6 (2026-04-09)**, LTS **1.10.11 (2026-03-09)**,
   **1.11 EOL**. **1.13 no era final a ago-2026** (rc2 el 2026-07-29): comprueba si ya salió, porque
   al hacerlo **1.12 pasa a EOL** y hay que decidir si la LTS se mueve.
2. **Estado real de la latencia**: hay mucha información caducada. La caché de código nativo es de
   **1.9**; verifica en las notas de release de la versión que vayas a usar qué ha cambiado desde
   entonces, y el estado de `--trim`/`juliac` (a ago-2026: **experimental**, requiere `--experimental`,
   sin despacho dinámico alcanzable). No cites cifras de TTFX de blogs sin reproducirlas.
3. Versiones de `juliaup`, `PackageCompiler.jl`, `JuliaFormatter.jl`, `Documenter.jl`, `Aqua.jl` y
   **`JET.jl`** — este último es pre-1.0 y su compatibilidad va atada a la versión de Julia:
   comprueba qué release de JET soporta tu Julia antes de meterlo en CI.
4. **Auditoría de vulnerabilidades**: si ya existe `Pkg.audit` (a ago-2026 **no**, sigue como propuesta
   abierta en Pkg.jl) y qué escáneres consumen ya los avisos `JLSEC-*` de `SecurityAdvisories.jl` en
   formato OSV. **Hueco no verificado a ago-2026**: la cobertura efectiva de los paquetes **JLL**
   (mapeo del binario upstream y su CVE al nombre del JLL) no la he podido cuantificar —
   trátala como **no cubierta** y no afirmes lo contrario.
5. **Hueco no verificado a ago-2026**: el estado de soporte de **Python 3.14 en `PythonCall.jl`**
   (fuentes indican fallos y falta de soporte, sin fecha de resolución) y si `PyCall.jl` sigue siendo
   la única vía en ese caso.
6. Cambios de **licencia o modo mantenimiento** de cualquier herramienta que fijes por defecto antes
   de adoptarla (precedentes en otros ecosistemas: Trivy, gitleaks, Brakeman). Julia y sus stdlib son
   MIT, pero verifica el `LICENSE` en crudo de cada paquete de terceros que entre en la ruta crítica.
7. Breaking changes desde el `NEWS.md` oficial de Julia antes de cualquier upgrade de minor —
   nunca de blogs de terceros sin contrastar con la fuente.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
