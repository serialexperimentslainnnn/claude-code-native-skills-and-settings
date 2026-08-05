---
name: elixir-erlang-standards
description: Use when writing, reviewing or operating Elixir and Erlang/OTP systems on the BEAM - .ex/.exs/.erl/.hrl/.heex files, mix.exs, mix.lock, .formatter.exs, .credo.exs, rebar.config, GenServer/Supervisor/Task/Agent/Registry modules, ETS and :persistent_term, GenStage/Broadway/Flow pipelines, Ecto schemas migrations and Ecto.Multi, Phoenix contexts controllers channels and LiveView, Plug pipelines, ExUnit tests with Mox or StreamData, mix release and vm.args, distributed Erlang cookies epmd and TLS distribution, Dialyzer/Dialyxir, sobelow, or :telemetry and recon instrumentation.
---

# Estándares Elixir / Erlang (BEAM y OTP)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo sistema sobre la **BEAM**: Elixir, Erlang, OTP, Phoenix, Ecto, releases y su operación.
Triggers: `.ex`, `.exs`, `.erl`, `.hrl`, `.heex`, `mix.exs`, `mix.lock`, `.formatter.exs`, `.credo.exs`,
`rebar.config`, `vm.args`, `GenServer`, `Supervisor`, `Registry`, `:ets`, `Ecto`, `Phoenix`, `LiveView`,
`Plug`, `ExUnit`, `Mox`, `mix release`, `epmd`, `libcluster`.

El eje de esta skill es el **modelo de ejecución de la BEAM** (procesos aislados, supervisión,
distribución), no "otro lenguaje funcional". Casi toda decisión de diseño aquí se justifica por OTP.

**No aplica**: ver `api-design-standards` (el **contrato** de la API — recursos, códigos, paginación,
RFC 9457, versionado — es suyo; aquí solo su implementación en Plug/Phoenix/Absinthe),
`microservices-architecture-standards` (dónde se corta un servicio y cómo hablan entre sí; en la BEAM
la respuesta suele ser "no lo cortes todavía", pero la decisión es suya),
`kubernetes-standards` y `container-runtime-security-standards` (empaquetado OCI del release y runtime
del contenedor), `cicd-standards` (la pipeline y sus gates; aquí solo qué herramienta y con qué
configuración), `secrets-management-standards` (dueño de la elección de gestor de secretos y del
escáner de secretos; aquí solo cómo llegan al release y que `RELEASE_COOKIE` no viva en la imagen),
`appsec-standards` y `vulnerability-management-standards` (modelado de amenazas, proceso y triaje;
aquí el criterio de código y qué gate rompe el build), `sql-standards` (el lenguaje SQL en sí),
`data-platform-standards`, `mysql-mariadb-dba-standards`, `oracle-dba-standards` y
`sqlserver-dba-standards` (operación del motor: tuning, réplicas, backup, HA). Ecto decide **cómo
accede la aplicación**, no cómo se opera la base de datos.
`observability-standards` (estrategia y pipeline de telemetría, SLI y dashboards; `:telemetry` y su
instrumentación en el código son de esta skill), `sre-practice-standards` (SLO, error budget y
fiabilidad operativa; aquí el diseño de supervisión y back-pressure que los hace posibles),
`message-brokers-standards` (Kafka/RabbitMQ/NATS como infraestructura — **no confundir con
`Phoenix.PubSub` ni con el paso de mensajes entre procesos de la BEAM**: PubSub es *in-cluster*, sin
persistencia ni garantía de entrega, y no sustituye a un broker; Broadway es el consumidor de un
broker, no el broker).
Otros lenguajes: `ruby-standards`, `python-standards`, `go-standards`, `typescript-standards`,
`rust-standards`, `jvm-spring-standards`, `php-standards`, `haskell-fp-standards`, `scala-standards`,
`clojure-standards`, `ocaml-fsharp-standards`. Frente a **`ruby-standards`** en particular:
comparten origen sintáctico y buena parte de la comunidad, pero **no** el modelo de ejecución — la
frontera es la BEAM. Un patrón Rails traducido a Elixir sin repensar procesos y supervisión es un
error de diseño, no una migración.
`iac-standards` (aprovisionamiento del clúster) y `bash-linux-scripting-standards` (scripts de
sistema alrededor del release).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Mínimo | Por qué |
|---|---|---|---|
| Elixir | **1.20.x** | 1.18 | 1.20 salió 2026-06-03: primer hito del sistema de tipos completo |
| Erlang/OTP | **28** (o 29 si el ecosistema acompaña) | 27 | OTP 29 salió 2026-05-11 (EOL 2029-05-11); OTP 26 EOL 2026-05-26 |
| Compatibilidad | Elixir 1.20 → **OTP 27-29**; 1.19 → 26-28; 1.18 → 25-27 | — | Tabla oficial de compatibilidad; **fija ambas versiones**, no solo Elixir |
| Gestor de versiones | **mise** o `asdf` con los plugins de erlang y elixir | — | Ambas versiones en `.tool-versions`/`mise.toml`, nunca las del sistema |
| Dependencias | `mix` + **`mix.lock` committeado** | — | `mix deps.get --check-locked` en CI |
| Framework web | **Phoenix 1.8.x** | 1.7 | 1.8 trae *scopes*, `phx.gen.auth` con magic link, layouts simplificados; exige OTP 25+ |
| LiveView | **1.2.x** | 1.0 | 1.2 añade Colocated CSS (`@scope`) y avisos de test para formularios sin `id` |
| Servidor HTTP | **Bandit** | 1.12+ | Default en Phoenix moderno; Cowboy solo si una dependencia lo exige |
| Acceso a datos | **Ecto 3.14** + `ecto_sql` | — | Apache-2.0 |
| Formatter | `mix format` (nativo) | — | Cero discusión de estilo; `--check-formatted` en CI |
| Linter | **Credo 1.7.19** | — | MIT, activo (release jun-2026) |
| Análisis estático | **Dialyxir 1.4.7** sobre Dialyzer | — | Apache-2.0. Ver coste real abajo |
| Tests | **ExUnit** (nativo) + **Mox 1.2** + **StreamData 1.4** | — | — |
| SAST | **Sobelow 0.14.1** | — | Apache-2.0. Cadencia lenta (último release oct-2025): verifica actividad (§8) |
| SCA | **`mix deps.audit`** (`mix_audit` 2.1.5) + `mix hex.audit` | — | `mix_audit` cruza con la BD de avisos; `hex.audit` detecta paquetes *retired* |
| Back-pressure | **Broadway 1.3** (fuentes externas) / **GenStage 1.3** (pipelines propios) | — | Flow 1.2.4 sin releases desde 2023: úsalo solo si encaja exactamente |
| Releases | **`mix release`** (nativo) | — | Sin Distillery ni empaquetado artesanal |
| Telemetría | **`:telemetry` 1.4** + `telemetry_metrics` + exportador OTel/Prometheus | — | — |

**Política de versiones**: Elixir aplica *bug fixes* solo a la última minor y **parches de seguridad a
las últimas 5 minors** (verbatim de la doc oficial: *"Elixir applies bug fixes only to the latest
minor branch. Security patches are available for the last 5 minor branches"*). OTP mantiene 3 ramas
(la actual y las dos anteriores). Traducción operativa: **una minor de Elixir por release (2/año) y
una major de OTP al año**. Quedarse dos años atrás en OTP significa quedarse sin parches.

**Sistema de tipos de Elixir — estado real a 2026-08** (esto ha cambiado y no debe afirmarse de
memoria): Elixir 1.20 completó el **primer hito** de los *gradual set-theoretic types*: el compilador
**infiere y comprueba tipos de todo programa Elixir sin anotaciones**, reportando código muerto y
violaciones garantizadas en runtime, con baja tasa de falsos positivos. Lo que **no** hay todavía:
**firmas de tipo definidas por el usuario ni API pública del sistema de tipos**. Los siguientes hitos
anunciados son structs tipados y luego firmas de función. Consecuencias:
- Los avisos del compilador de tipos **son errores**: `--warnings-as-errors` en CI, sin excepciones.
- El pattern matching es ahora *load-bearing*: escribir `%User{} = user` da evidencia al compilador.
  Matchear la struct explícitamente pasa de estilo a decisión técnica.
- `@spec` sigue siendo la única forma de declarar intención y **sigue siendo cosa de Dialyzer**, no
  del compilador. No los confundas ni asumas que uno sustituye al otro.

**Dialyzer/Dialyxir — coste real, decide con los ojos abiertos**: es *success typing*, no un type
checker; no falla por falta de especificación y produce falsos negativos con gusto. La primera
ejecución construye una PLT que tarda minutos, y sus mensajes son notoriamente crípticos. Criterio:
- Adóptalo **solo** con PLT cacheada en CI y con `.dialyzer_ignore.exs` versionado y **vacío como
  objetivo**, no como vertedero.
- `@spec` obligatorio en el **API público** de cada módulo y en los *behaviours*; opcional dentro.
- Si el equipo no va a leer sus avisos, no lo instales: un gate que todo el mundo salta es peor que
  ninguno. Con Elixir 1.20 el compilador ya cubre parte de lo que antes justificaba Dialyzer:
  reevalúa el coste/beneficio en cada upgrade (§8).

## 3. Estructura y convenciones: el modelo de concurrencia

**Lo que la BEAM te da y qué implica**: procesos ligeros con **heap propio** (sin memoria compartida
mutable), planificados de forma preventiva, que solo se comunican por **paso de mensajes asíncrono**.
De ahí salen las reglas, no del gusto:

- **Un proceso por unidad de concurrencia real**, no por unidad de código. Un proceso no es un
  objeto: si no representa una actividad concurrente, un estado con dueño o un aislamiento de fallo,
  es una función.
- **`let it crash` bien entendido**: significa *no programar defensivamente contra errores que no
  esperas*, dejando que el proceso muera y el supervisor restaure un estado limpio y conocido.
  **No** significa no manejar errores. Regla operativa:
  - Errores **esperados** del dominio (validación falla, recurso no existe, remoto devuelve 429) →
    valor de retorno `{:ok, _} | {:error, _}`, tratados explícitamente. Crashear aquí es un bug.
  - Errores **inesperados** (invariante rota, estado imposible, bug) → crash. No los rescates.
  - `try/rescue` es la excepción, no el estilo. `rescue` que traga y sigue con estado corrupto está
    **prohibido**: has convertido un crash recuperable en corrupción silenciosa.
  - Un crash sin **telemetría ni supervisión pensada** no es *let it crash*, es una caída.
- **Árbol de supervisión = diseño, no boilerplate**. Cada aplicación declara su árbol en
  `application.ex` con orden de arranque explícito. Estrategias:
  - `:one_for_one` — hijos independientes. Default; si no sabes cuál usar, es esta.
  - `:one_for_all` — los hijos comparten estado o conexión: si cae uno, el resto es inconsistente.
  - `:rest_for_one` — dependencia en cadena (el hijo N depende de los anteriores). Es la que casi
    nadie usa y la correcta con más frecuencia de lo que parece.
  - `max_restarts`/`max_seconds` con valores **pensados**: si un hijo no puede arrancar (config mala,
    dependencia caída), quieres que el supervisor se rinda y el proceso muera de verdad para que el
    orquestador lo reprograme, no un bucle de reinicio infinito que el healthcheck no ve.
  - `:transient` para trabajo que termina normalmente; `:temporary` para tareas que no deben
    reiniciarse (un job idempotente lo reencola su cola, no el supervisor).
  - `DynamicSupervisor` para procesos por entidad (una conexión, una partida, un dispositivo) +
    `Registry` para localizarlos por clave. Ese es el patrón, no un mapa global en un GenServer.
- **Cuándo NO usar un GenServer** — el antipatrón más caro de la BEAM: un GenServer es un **cuello de
  botella de un solo hilo**. Todo `handle_call` serializa. Está prohibido usarlo para:
  - Guardar configuración o datos de solo lectura → `:persistent_term` (lectura sin copia, escritura
    carísima: solo para datos casi inmutables) o `:ets` con `read_concurrency: true`.
  - Cachear datos leídos por muchos procesos → `:ets` (tabla `:public`/`:protected`, `named_table`),
    no un GenServer que copia el valor en cada `call`.
  - Envolver funciones puras "para tener estado" → pásalo por argumento.
  - Paralelizar trabajo → `Task.async_stream` con `max_concurrency` y `timeout` explícitos.
  - **Regla**: si el proceso solo lee, no es un proceso. Si `handle_call` aparece en un perfil como
    tiempo de espera, ya tienes el cuello de botella.
  - `Agent` es un GenServer con menos ceremonia y **los mismos** problemas de serialización: para
    estado trivial y sin concurrencia. Si empieza a crecer, es un GenServer y hay que revisar si
    debería ser ETS.
- **Estado en el proceso**: el `state` de un GenServer se pierde al reiniciar — ese es el punto. Lo
  que no puede perderse va a la base de datos o a ETS con dueño supervisado; lo que se pierde debe
  poder reconstruirse en `init/1` (y `init/1` debe ser rápido: trabajo pesado en
  `handle_continue`, nunca bloqueando el arranque del supervisor).
- **`:ets`**: la tabla muere con su proceso dueño → el dueño es un proceso supervisado dedicado
  (o usa `heir`). `:ets` no está replicada entre nodos y no es una base de datos.
- **Back-pressure — obligatorio en toda ingesta**: la mailbox de un proceso es **ilimitada**. Un
  productor más rápido que el consumidor no da error: llena la memoria hasta que el nodo muere por
  OOM. Nunca hagas `GenServer.cast` en bucle sobre datos de entrada.
  - Fuente externa (SQS, Kafka, RabbitMQ, HTTP) → **Broadway**: demanda, lotes, reintentos,
    *rate limiting* y telemetría de serie.
  - Pipeline interno con etapas → **GenStage** (demanda explícita).
  - Trabajo puntual sobre una colección acotada → `Task.async_stream` con `max_concurrency`.
  - `Flow` solo para procesamiento de colecciones en paralelo y si aceptas su cadencia de
    mantenimiento (sin releases desde 2023).
- **Timeouts**: `GenServer.call/3` con timeout explícito (el default de 5000 ms también es una
  decisión, tómala a conciencia). Un `call` entre dos GenServers que pueden bloquearse mutuamente es
  un deadlock esperando: rompe el ciclo con `cast` + respuesta asíncrona o reordena la
  responsabilidad.
- **Nomenclatura y organización**: un módulo por fichero, `lib/<app>/<contexto>/`; nada de un
  `Utils` cajón de sastre. Módulos de proceso (`GenServer`) separados de los de lógica pura — la
  lógica se testea sin arrancar procesos.

**Ecto**:
- `Repo` es el único punto de acceso a la base de datos. Prohibido SQL crudo interpolado
  (`Ecto.Adapters.SQL.query!` con string interpolado); si necesitas SQL, `fragment/1` con parámetros.
- **Changesets** en el borde: `cast/4` con lista de campos explícita (nunca todos los campos del
  esquema), `validate_*`, y las **constraints de base de datos** (`unique_constraint`,
  `foreign_key_constraint`, `check_constraint`) declaradas — una validación sin constraint es una
  condición de carrera, no una validación.
- **`Ecto.Multi`** para toda operación con más de una escritura: una transacción, errores tipados por
  paso, y nada de `Repo.transaction(fn -> ... end)` con excepciones como control de flujo.
- **El pool de conexiones es el límite real de concurrencia de la app**, no el número de procesos.
  Con `pool_size: 10`, la undécima consulta simultánea espera. Dimensiona contra `max_connections`
  del motor y el número de nodos (`pool_size × réplicas ≤ límite del motor`), fija `queue_target` y
  `queue_interval`, y **alerta sobre la espera de checkout**: es la métrica que anticipa el incidente.
  Consultas largas o analíticas van a un `Repo` aparte con su propio pool.
- N+1: `preload` explícito (o `Ecto.Query` con `join` + `preload`). Ecto no hace lazy loading — si
  ves `Ecto.Association.NotLoaded`, es que el diseño de la consulta está mal, no que falte magia.
- Migraciones: reversibles (`up`/`down` o `change` verificable), **compatibles hacia atrás**
  (expand/contract) porque la versión N-1 del código sigue viva durante el rolling deploy;
  índices en PostgreSQL con `concurrently: true` y `@disable_ddl_transaction true`. Las destructivas
  en una release posterior. Migraciones de datos **no** van en migraciones de esquema: script o job.

**Phoenix**:
- **Contextos**: la frontera pública del dominio. El controller/LiveView llama al contexto; **nunca**
  a `Repo` ni a un esquema directamente. Un contexto que solo hace `Repo.all/1` es una capa vacía:
  o tiene reglas, o el corte está mal hecho. Phoenix 1.8 introduce *scopes* para que las funciones de
  contexto lleven el ámbito de acceso (usuario/organización) en la firma — úsalo: convierte el
  control de acceso en algo que el compilador y el generador ven.
- **LiveView — el estado vive en el servidor**, un proceso por conexión:
  - **Autorización en CADA evento**, no solo en `mount/3`. `handle_event` recibe datos del cliente y
    el cliente puede enviar cualquier evento en cualquier orden: si la comprobación solo está en el
    montaje, tienes IDOR. Lo mismo en `handle_params` y en los `handle_info` disparados por PubSub.
  - Los *assigns* que no se renderizan siguen viviendo en memoria del servidor: **no metas secretos,
    tokens ni datasets grandes en assigns**. Multiplica por número de conexiones para dimensionar.
  - Lo que va al cliente (atributos `phx-value-*`, formularios) es **entrada no confiable**. Valida
    con changeset igual que en un controller.
  - La sesión de LiveView se establece en el handshake: `live_session` con `on_mount` para
    autenticación, y `Phoenix.LiveView.Socket` firmado — pero el *firmado* garantiza integridad, no
    autorización vigente. Revalida permisos que puedan haber cambiado.
  - Trabajo lento en `handle_event` bloquea la UI de ese usuario: `start_async`/`assign_async` o una
    `Task` supervisada.
  - `temporary_assigns` y streams para listas grandes; enviar 10 000 filas en cada diff es el bug de
    rendimiento clásico de LiveView.
- **Channels / PubSub**: `join/3` autoriza el topic (nunca aceptes un topic construido con datos del
  cliente sin comprobarlo), y cada `handle_in` vuelve a autorizar. `Phoenix.PubSub` es *best effort*
  dentro del clúster: sin persistencia, sin orden global, sin entrega garantizada. Si el mensaje no
  se puede perder, va a un broker (`message-brokers-standards`) o a la base de datos.
- **Plug**: pipelines explícitas por tipo de tráfico (`:browser`, `:api`); CSRF activo en las de
  sesión; el plug de autenticación **antes** que cualquier router de recursos, y la autorización lo
  más cerca posible del dato, no solo en el pipeline.

**Releases y despliegue**:
- `mix release` con `MIX_ENV=prod`, `runtime.exs` para toda la config que dependa del entorno
  (`config.exs` se congela en tiempo de compilación: un secreto ahí queda **dentro del artefacto**).
- **Hot code upgrade — casi nunca lo quieres.** Verbatim de la doc oficial de `mix release`:
  *"this feature is not supported out of the box by Elixir releases"*, porque *"they are very
  complicated to perform in practice, as they require careful coding of your processes and
  applications as well as extensive testing"*, y *"Given most teams can use other techniques that are
  language agnostic to upgrade their systems, such as Blue/Green deployments, Canary deployments,
  Rolling deployments, and others, hot upgrades are rarely a viable option."* Criterio: **rolling o
  blue/green**. El hot upgrade solo se justifica en sistemas con estado imposible de drenar
  (telecomunicaciones, dispositivos embebidos sin ventana de reinicio) y con presupuesto para
  `.appup`/`.relup` a mano y probarlos.
- Apagado ordenado: SIGTERM → `:init.stop` drena el árbol de supervisión de arriba abajo. Da margen
  suficiente en el orquestador (`terminationGracePeriodSeconds`) para que los procesos con trabajo en
  vuelo terminen; un `terminate/2` que no se ejecuta es trabajo perdido y `terminate/2` **no está
  garantizado** en todos los casos (kills brutales, `:brutal_kill`) — no pongas ahí lógica crítica.

## 4. Calidad y testing

- **Formato**: `mix format` con `.formatter.exs` versionado; `mix format --check-formatted` en CI.
  Cero discusión de estilo.
- **Compilación**: `mix compile --warnings-as-errors`. Con el sistema de tipos de 1.20 esto ya no es
  higiene, es un type checker con gate.
- **Credo**: `mix credo --strict`. Reglas de diseño (`Credo.Check.Design.*`) ajustadas una vez y
  fijadas en `.credo.exs`; nada de silenciar comprobaciones de `Warning` o `Readability` en masa.
- **ExUnit**:
  - `async: true` **por defecto**, y entiende cuándo rompe: cualquier test que toque **estado global
    compartido** — un proceso con nombre registrado global, `:persistent_term`, una tabla `:ets`
    nombrada, `Application.put_env`, el sistema de ficheros, un puerto fijo, o la base de datos con
    `Ecto.Adapters.SQL.Sandbox` en modo `:shared` — debe ser `async: false`. Con el sandbox en modo
    `:manual` y checkout por test, los tests de Ecto **sí** pueden ser async.
  - Un motivo de fallo por test, AAA, nombres que describen comportamiento observable.
  - Cubrir camino feliz **y bordes y errores**: entrada inválida, timeout del proceso remoto, caída
    del proceso supervisado (verifica que el supervisor reinicia y el sistema converge), mailbox
    llena, conflicto de constraint bajo concurrencia.
  - **Prohibida la lógica en los tests** y prohibido `Process.sleep` para sincronizar: usa
    `assert_receive`/`refute_receive` con timeout, `Task.await`, o mensajes de `:telemetry`.
  - Testea la lógica pura sin arrancar procesos; testea el proceso por su **contrato observable**
    (mensajes que emite, efectos que produce), no por su `state` interno.
- **Mox y el patrón de *behaviours*** — la única forma de mockear aquí:
  - Define un `@behaviour` para la frontera (cliente HTTP, pasarela de pago, reloj), inyecta la
    implementación por configuración, y `Mox.defmock` en test. `set_mox_global` solo si no queda
    remedio, y entonces `async: false`.
  - **Mockea solo fronteras del sistema**, nunca módulos propios. Sustituir tu propio código por un
    mock es testear el mock.
  - ❌ Librerías que reescriben módulos en runtime (`meck` y derivados): rompen `async: true` y
    ocultan cambios de firma.
  - Verificación en `setup :verify_on_exit!`: un mock no llamado es un test que miente.
- **Property-based con StreamData** para lógica con invariantes (parsers, serialización,
  normalización, máquinas de estado, aritmética de dominio): no sustituye a los tests de ejemplo, los
  complementa. `ExUnitProperties` con semilla registrada para reproducir fallos.
- **Gates de CI** (bloquean merge, de barato a caro):
  1. `mix deps.get --check-locked` + `mix format --check-formatted`
  2. `mix compile --warnings-as-errors`
  3. `mix credo --strict`
  4. `mix deps.audit` + `mix hex.audit` + `mix sobelow --exit` (en proyectos Phoenix)
  5. `mix test` (con `--warnings-as-errors`)
  6. `mix dialyzer` con PLT cacheada (el más caro; si tarda demasiado, en un job aparte, pero
     **bloqueante**)
- Cobertura (`mix test --cover`, ExCoveralls) como señal, no como meta.

## 5. Seguridad del stack

- **Agotamiento de atoms — la vulnerabilidad característica de la BEAM**. Los atoms **no se recolectan
  como basura** y la tabla de atoms tiene un límite fijo (configurable con `+t` en `vm.args`);
  alcanzarlo mata el nodo entero. Por tanto:
  - ❌ **PROHIBIDO** `String.to_atom/1` con cualquier dato que venga de fuera (request, mensaje de
    cola, fichero, base de datos). Usa `String.to_existing_atom/1` dentro de un `try/rescue` o, mejor,
    un `case` con la allowlist de valores permitidos.
  - ❌ `:erlang.binary_to_atom/2`, `List.to_atom/1`, `Module.concat/1` con entrada de usuario
    (`Module.concat` crea atoms **y** puede resolver a un módulo cargable: es ejecución arbitraria).
  - ❌ `Jason.decode!(payload, keys: :atoms)` — el atajo que convierte cada clave del atacante en un
    atom permanente. Usa `keys: :strings` (default) o `keys: :atoms!`.
  - ❌ Claves dinámicas de `:telemetry`, nombres de proceso o de tabla ETS derivados de entrada.
- **Deserialización**. Recomendación verbatim del Erlang Ecosystem Foundation Security WG:
  *"Use the `:safe` option when calling :erlang.binary_to_term/2 on untrusted input"*, con la
  limitación explícita de que *"The safe option does not affect the deserialisation of functions and
  other unsafe terms"*. Criterio:
  - ❌ **PROHIBIDO** `:erlang.binary_to_term/1` (sin opciones) sobre datos externos.
  - Con datos externos: `Plug.Crypto.non_executable_binary_to_term/2` con `[:safe]` — cubre a la vez
    la creación de atoms y la deserialización de funciones.
  - Mejor aún: **no uses External Term Format como formato de intercambio con el exterior**. JSON o
    Protobuf en el borde; ETF solo entre nodos de tu propio clúster.
- **Ejecución dinámica**: ❌ `Code.eval_string/3`, `Code.eval_quoted/3`, `Code.compile_string/2`,
  `EEx` con plantilla controlada por el usuario, `apply/3` con módulo o función procedentes del
  request. Si necesitas despacho dinámico, allowlist explícita.
- **Puertos y NIFs**: ❌ `System.cmd/3` o `:os.cmd/1` con interpolación de entrada (`System.cmd`
  con lista de argumentos y sin shell es la forma correcta). Un NIF que falla **mata el nodo entero**,
  saltándose todo el modelo de aislamiento: trata cada NIF de terceros como código privilegiado y
  audítalo antes de añadirlo.
- **Elixir distribuido — NO es seguro por defecto. Esto es lo más importante de esta sección.**
  Citas verbatim del EEF Security WG:
  - *"Cookies enable rudimentary access control, letting nodes decide which other nodes can join a
    cluster. The cookie value is not transmitted on the wire (a challenge/response mechanism is used),
    but no protections are in place against an active (man-in-the-middle) attack."*
  - *"The default distribution protocol transmits all application data in the clear, using a variant
    of External Term Format."*
  - *"The EPMD protocol allows unauthenticated clients to look up a node by name, as well as to
    retrieve the full list of known nodes... Running EPMD on an untrusted network therefore exposes
    information about the distributed Erlang cluster(s) known at the host."*
  - Recomendaciones textuales: *"Enable strong authentication, confidentiality and integrity
    protection by using TLS rather than TCP for the distribution protocol"*, *"Isolate the
    distribution protocol and EPMD from client facing network interfaces"*, *"Use an SSH tunnel or
    VPN for remote access to the Erlang shell"*.
  - Consecuencia que hay que decir en voz alta: **quien alcanza el puerto de distribución y conoce la
    cookie ejecuta código arbitrario en todos los nodos del clúster**. La cookie es efectivamente una
    credencial de root distribuida.
  - **En Kubernetes**, esto se traduce en requisitos concretos y no negociables:
    1. Cookie **generada aleatoriamente**, en un `Secret`, inyectada como `RELEASE_COOKIE` — nunca en
       la imagen, en el repo, ni en `vm.args` committeado. Una cookie por entorno.
    2. `NetworkPolicy` de *default deny* que solo permita el puerto 4369 (EPMD) y el rango de
       distribución **entre los pods del propio release**; jamás expuestos en un Service o Ingress.
    3. Rango de distribución fijado (`inet_dist_listen_min`/`max`) para que la política de red sea
       escribible.
    4. **TLS de distribución** (`-proto_dist inet_tls`) con verificación mutua contra una CA del
       clúster, en cuanto el tráfico entre nodos salga de un plano de red de confianza. Asume que
       cuesta trabajo: los certificados de la distribución Erlang son quisquillosos.
    5. Descubrimiento con `libcluster` y `Service` headless; opcionalmente `-start_epmd false` con un
       `epmd_module` propio para eliminar EPMD.
    6. ❌ **Nunca** uses la distribución Erlang para atravesar capas de la arquitectura (aplicación →
       base de datos, o entre dos servicios de dominios distintos): no aporta aislamiento alguno.
  - `:observer` y `remote_console` en producción: solo por túnel autenticado, con cuenta nominal y
    auditoría. Una `iex` remota es una shell de root sobre el sistema completo.
- **Phoenix hardening**: `sobelow` como gate (detecta XSS en `raw`, config insegura, traversal, CSRF
  desactivado, `Code.eval` y secretos en el repo). Además: `secret_key_base` desde el entorno,
  `force_ssl` con HSTS, `put_secure_browser_headers` con CSP explícita, `check_origin` de los sockets
  **con lista real** (❌ `check_origin: false` en producción), cookies de sesión `secure`,
  `http_only`, `same_site`.
- **XSS en HEEx**: HEEx escapa por interpolación por defecto; ❌ `raw/1` y `Phoenix.HTML.raw` sobre
  contenido de usuario. Atributos construidos dinámicamente y `href` con esquema del usuario son
  vectores que el escape **no** cubre.
- **Autorización**: default deny; el ámbito viaja en la consulta (`from u in User, where: u.org_id ==
  ^scope.org_id`), no en un `if` posterior. Con los *scopes* de Phoenix 1.8, en la firma del contexto.
- **SCA y cadena de suministro**: `mix.lock` committeado y verificado en CI; `mix deps.audit` y
  `mix hex.audit` como gates; revisión humana de toda dependencia nueva (mantenedor, actividad,
  descargas, licencia). Recuerda que `mix deps.compile` **ejecuta código de terceros** (`mix.exs`,
  compiladores propios, NIFs que compilan C): el job que instala dependencias no debe tener a mano
  credenciales de producción.
- **Secretos**: `runtime.exs` leyendo del entorno o de un gestor; ❌ secretos en `config/prod.exs`
  (quedan compilados dentro del release), en la imagen o en logs. Filtra parámetros sensibles en
  Phoenix (`filter_parameters`) y en la telemetría.

## 6. Rendimiento y operabilidad

- **`:telemetry` es la instrumentación nativa y no es opcional**: eventos en las fronteras (HTTP,
  Ecto, jobs, clientes externos, LiveView), `telemetry_metrics` para agregación y un exportador
  (OpenTelemetry o Prometheus). Phoenix y Ecto ya emiten eventos: consúmelos, no reinventes.
  - Métricas mínimas del runtime: **longitud de las mailboxes** (una mailbox que crece es el aviso
    temprano de casi todo incidente en la BEAM), número de procesos vs `+P`, memoria por tipo
    (procesos/binarios/ETS/atoms), utilización de los schedulers, **espera de checkout del pool de
    Ecto**, tiempo de cola de los jobs, reinicios de supervisores.
  - ❌ Nombres de evento de telemetría construidos con datos del usuario (crea atoms, §5).
- **Diagnóstico en vivo**: `:observer` (o `observer_cli`) en desarrollo; en producción **`recon`** es
  la herramienta correcta — está diseñada para ser segura en un nodo cargado (`recon:proc_count/2`,
  `recon:bin_leak/1` para el clásico crecimiento por *refc binaries* fragmentadas). ❌ `:erlang.processes()`
  + inspección manual en un nodo de producción con cientos de miles de procesos.
- **Binarios**: los binarios >64 bytes van al heap compartido con refcount; una `:binary.part/3` sobre
  un binario grande mantiene vivo el original entero. Usa `:binary.copy/1` cuando guardes fragmentos
  de payloads grandes en estado de larga vida — es la causa habitual de "la memoria sube y no baja".
- **Dimensionado**: la BEAM usa todos los cores por defecto; en contenedor **fija los schedulers al
  límite real de CPU** (`+S`/`+SDio` o la variable equivalente) o el planificador competirá consigo
  mismo bajo *cgroup throttling*. Reserva memoria contando: heaps de procesos + binarios + ETS.
- **Cuellos de botella clásicos, en orden de frecuencia**: (1) un GenServer serializando trabajo,
  (2) el pool de Ecto, (3) mailbox creciendo por falta de back-pressure, (4) `:ets` con contención de
  escritura (`write_concurrency`), (5) binarios retenidos. Perfila (`recon`, `:fprof` en desarrollo)
  antes de optimizar.
- **Fiabilidad**: timeouts explícitos en todo cliente externo (Finch/Req con `receive_timeout`),
  circuit breaker en dependencias frágiles, reintentos con backoff+jitter solo en operaciones
  idempotentes. Un `Task` sin supervisar que muere se lleva silencio: usa `Task.Supervisor`.
- **Jobs persistentes**: la cola de trabajo **no** es un proceso en memoria. Si el trabajo debe
  sobrevivir a un reinicio, va a una cola persistente (Oban u otra respaldada en base de datos —
  verifica su licencia y estado en §8), con idempotencia, límite de reintentos y cola muerta
  monitorizada. Un `Task.start/1` no es un job.
- **Salud**: endpoint de liveness que solo comprueba que la VM responde y readiness que comprueba
  dependencias (pool de Ecto, migraciones aplicadas). Un nodo con el árbol de supervisión reiniciando
  en bucle debe fallar el readiness, no seguir recibiendo tráfico.
- **Logs** estructurados con metadata (`request_id`, `trace_id`); nivel `:info` en producción,
  `:debug` activable; ❌ datos personales o secretos en logs.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: parches de seguridad de inmediato; Elixir una minor por release (2 al año, dentro de
  los 6 meses); OTP una major al año. Recuerda que Elixir solo parchea seguridad en las **últimas 5
  minors** y que la matriz de compatibilidad ata las dos versiones: planifica los saltos juntos.
- Deprecaciones de Elixir/Phoenix/Ecto: se resuelven en la release en curso. `mix compile
  --warnings-as-errors` ya lo fuerza; no lo desactives "temporalmente".
- Una dependencia Hex sin releases en >18 meses se revisa o se sustituye (Flow es el ejemplo vivo).
  `mix hex.outdated` en la revisión periódica, `mix hex.audit` en CI.
- Deuda consciente: atajo = TODO con motivo e issue enlazada.

**Lista de prohibiciones (veto):**
- ❌ **PROHIBIDO** `String.to_atom/1` (y `binary_to_atom`, `List.to_atom`, `Module.concat`) con
  entrada de usuario. ❌ `keys: :atoms` al decodificar JSON externo.
- ❌ **PROHIBIDO** `:erlang.binary_to_term/1` sin `[:safe]` sobre datos externos; usa
  `Plug.Crypto.non_executable_binary_to_term/2`.
- ❌ `Code.eval_string`/`Code.eval_quoted`/`Code.compile_string`, `EEx` con plantilla del usuario,
  `apply/3` con módulo o función del request.
- ❌ `System.cmd`/`:os.cmd` con interpolación de entrada.
- ❌ Exponer el puerto de distribución o EPMD fuera del clúster; cookie en la imagen, en el repo o
  compartida entre entornos; distribución Erlang entre capas o entre servicios de dominios distintos.
- ❌ `check_origin: false`, CSRF desactivado, `raw/1` sobre contenido de usuario en producción.
- ❌ Autorizar solo en `mount/3` de un LiveView: cada `handle_event`/`handle_params` reautoriza.
- ❌ Secretos o datasets grandes en los assigns de LiveView; secretos en `config/prod.exs`.
- ❌ GenServer como caché, como almacén de configuración de solo lectura o como envoltorio de
  funciones puras. ❌ `Agent` para estado que crece.
- ❌ Enviar mensajes a un proceso sin mecanismo de back-pressure (`cast` en bucle sobre una ingesta).
- ❌ `try/rescue` que traga la excepción y continúa con estado potencialmente corrupto; usar
  excepciones como control de flujo del dominio.
- ❌ Lógica crítica en `terminate/2` (no está garantizado que se ejecute).
- ❌ `Process.sleep` para sincronizar tests; tests con lógica; `async: true` en tests que tocan
  estado global, `:persistent_term`, ETS nombrada o `Application.put_env`.
- ❌ Mockear módulos propios o reescribir módulos en runtime (`meck`); mocks sin `verify_on_exit!`.
- ❌ SQL interpolado en `Ecto.Adapters.SQL.query!`; `cast/4` con la lista completa de campos del
  esquema; validación de unicidad sin `unique_constraint` y sin índice único.
- ❌ Migración destructiva en la misma release que el código que deja de usar la columna.
- ❌ Hot code upgrade como estrategia de despliegue por defecto (rolling o blue/green).
- ❌ Desplegar sobre Elixir u OTP fuera de la ventana de parches de seguridad, o con una combinación
  fuera de la matriz de compatibilidad oficial.
- ❌ Añadir un NIF de terceros sin auditarlo: un NIF que falla mata el nodo entero.

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmaciones en un proyecto, **verifica online**:
1. **Elixir**: última estable y política de soporte (`elixir-lang.org`, `endoflife.date/elixir`).
   ¿Sigue 1.20 como serie actual o ya salió 1.21? Recuerda: bug fixes solo en la última minor,
   seguridad en las 5 últimas.
2. **Erlang/OTP**: última major y EOL (`erlang.org`, `endoflife.date/erlang`). OTP 29 (2026-05-11,
   EOL 2029-05-11), OTP 28 y OTP 27 vivos; OTP 26 EOL 2026-05-26 → confirma.
3. **Matriz de compatibilidad Elixir ↔ OTP**: tabla oficial en
   `hexdocs.pm/elixir/compatibility-and-deprecations.html`. Nunca la asumas de memoria; cambia en
   cada release.
4. **Sistema de tipos**: ¿el hito de *structs tipados* o de *firmas de función* ya está disponible?
   A 2026-08 **no hay firmas de tipo de usuario ni API pública**. Fuente: `elixir-lang.org/blog` y
   `gradual-set-theoretic-types.html`, no blogs de terceros.
5. **Phoenix y LiveView**: versión mayor actual (1.8.x / 1.2.x a 2026-08) y si hay 1.9 / 1.3 con
   cambios de generadores o de autenticación. `phoenixframework.org/blog`.
6. **Herramientas**: Credo, Dialyxir, Sobelow (cadencia lenta: **confirma que sigue mantenido antes
   de fijarlo como gate**), Mox, StreamData, Broadway, GenStage, Flow (sin releases desde 2023),
   `mix_audit`, Bandit, Ecto.
7. **Licencias y modelo de negocio** de todo lo que vayas a fijar como default — comprueba el
   `LICENSE` en crudo, no la etiqueta del README. Precedentes recientes que rompieron pipelines:
   **Trivy** cambió de licencia y **gitleaks** se declaró *feature complete* con su acción exigiendo
   licencia comercial para organizaciones desde v2. Aplica el mismo escrutinio a **Oban** (tiene
   ediciones de pago) antes de asumirlo como cola por defecto.
8. **Seguridad**: avisos de la Erlang Ecosystem Foundation Security WG (`security.erlef.org`),
   `erlang.org/doc` para la distribución, GitHub Advisories / osv.dev para Hex. Verifica en concreto
   si hay avisos posteriores en `ssh`/`ssl` de OTP y si la guía de hardening de distribución ha
   cambiado.

**Huecos declarados (no verificados a ago-2026)**:
- Estado de mantenimiento actual de **Sobelow** (último release localizado: 0.14.1, oct-2025) y de
  **Mox** (1.2.0, ago-2024): **no verificado** si siguen activos o en modo mantenimiento.
- Versión, licencia y modelo de **Oban** como cola de jobs por defecto: **no verificado**.
- Si OTP 29 tiene ya adopción suficiente en el ecosistema Hex (NIFs y precompilados) para ser el
  default en greenfield frente a OTP 28: **no verificado**.
- Valor por defecto del límite de la tabla de atoms (`+t`) en OTP 28/29: **no verificado** — léelo de
  `erlang.org/doc/apps/erts/erl_cmd.html` antes de citarlo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
