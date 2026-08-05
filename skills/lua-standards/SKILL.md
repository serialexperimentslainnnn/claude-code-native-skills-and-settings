---
name: lua-standards
description: Use when writing or reviewing Lua code - .lua files, .luacheckrc, selene.toml, stylua.toml, .rockspec and luarocks, busted spec files, LuaJIT vs Lua 5.1/5.4/5.5 targets, OpenResty content_by_lua_block/access_by_lua_file/ngx.shared.DICT/lua-nginx-module, Neovim init.lua and vim.api/vim.uv plugins with lazy.nvim, Redis or Valkey EVAL/EVALSHA/FUNCTION scripts, Teal .tl files, lua-language-server ---@ annotations, or sandboxing untrusted Lua with load/setfenv/_ENV.
---

# Estándares Lua (referencia: agosto 2026)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Lua casi nunca se usa solo: **se usa embebido, y el host decide casi todo** — versión del intérprete,
bibliotecas disponibles, modelo de concurrencia, qué se puede llamar y qué te mata el proceso. La
primera pregunta de cualquier trabajo en Lua no es "qué versión del lenguaje" sino **"quién es el
host"**. Esta skill está estructurada por host.

Triggers: `.lua`, `.tl`, `.rockspec`, `.luacheckrc`, `selene.toml`, `stylua.toml`, `init.lua`,
`*_spec.lua` (busted), `content_by_lua_block`/`access_by_lua_file`/`ngx.*`, `vim.api`/`vim.uv`,
`EVAL`/`EVALSHA`/`FUNCTION LOAD`, `luarocks`, anotaciones `---@`.

**No aplica**: ver `caching-cdn-standards` y `networking-standards` (nginx/OpenResty **como
plataforma**: configuración, TLS, upstreams, caché, límites — **el Lua que corre dentro es de aquí**),
`data-platform-standards` y `nosql-standards` (Redis/Valkey **como motor**: memoria, persistencia,
eviction, clustering — **el script `EVAL` es de aquí**), `homelab-standards` (self-hosting del stack),
`appsec-standards` (metodología y clases de vulnerabilidad; aquí solo el sandboxing concreto de Lua),
`c-standards` (**la API C de Lua, `lua_State`, extensiones nativas y su memoria son suyas**; aquí solo
la frontera vista desde Lua), `perl-standards` y `groovy-standards` (nada en común más allá de "es un
lenguaje dinámico"), `secrets-management-standards`, `vulnerability-management-standards`,
`observability-standards`, `sql-standards`.

## 2. Decisiones por defecto: versión y toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

**La fractura del ecosistema es real y no se resuelve eligiendo "la última"**: el host impone la
versión y muchas librerías de LuaRocks solo funcionan en una rama.

| Rama | Estado verificado a ago-2026 | Cuándo es tu target |
|---|---|---|
| **Lua 5.1** | Fin de línea (5.1.5, feb-2012). Sigue siendo **la versión más desplegada** vía LuaJIT | Solo porque el host la impone (LuaJIT, Redis, OpenResty) |
| Lua 5.2 / 5.3 | Sin mantenimiento activo; 5.3.6 es de sep-2020 | Nunca en proyecto nuevo |
| **Lua 5.4** | 5.4.8 (4-jun-2025), última de la rama | Default para Lua **standalone** si el host no manda |
| **Lua 5.5** | **5.5.0 publicada el 22-dic-2025** | Greenfield standalone; verificar soporte de tus rocks antes |
| **LuaJIT** | **Activo**: modelo de *rolling release* sobre la rama `v2.1`, con commits en ago-2026. Sin tarballs ni tags de release; la versión es `2.1.<timestamp del commit>` | Cuando manda el rendimiento o el host (OpenResty, Neovim) |

**LuaJIT es apoyable**, con condiciones explícitas: es **compatible con Lua 5.1** más un subconjunto
de extensiones de 5.2/5.3 — **no** es "Lua moderno". Un proyecto nuevo sobre LuaJIT acepta escribir
5.1 para siempre. Reglas operativas de upstream que hay que respetar: seguir la rama `v2.1` del git
(no `master`, no el tag `v2.1.ROLLING`, no `2.1.0-beta3`), **no usar tarballs de terceros ni el
tarball automático de GitHub** (sin `.git` no compila la versión correcta), y si el build necesita
"un release", tomar snapshots fechados de la rama.

| Pieza | Elección | Verificado | Licencia (LICENSE en crudo) |
|---|---|---|---|
| Formatter | **StyLua** | v2.5.2 (may-2026) | **MPL-2.0** (no MIT) |
| Linter | **selene** | 0.31.0 (may-2026), desarrollo activo | **MPL-2.0** (no MIT) |
| Linter (alternativa) | `luacheck` (`lunarmodules/luacheck`) | v1.2.0, may-2024 — **sin releases desde entonces** | MIT |
| Tipos | **lua-language-server** (LuaLS) + anotaciones `---@` | 3.18.2 (abr-2026) | MIT |
| Tipado real | **Teal** (`tl`) | v0.24.8 (oct-2025) | MIT |
| Tests | **busted** | v2.3.0 (ene-2026) | MIT |
| Paquetes | **LuaRocks** | 3.13.x | MIT |

Criterio: **selene por defecto** en proyecto nuevo (activo, rápido, `selene.toml` con la *standard
library* declarada por host: `lua51`, `lua54`, `roblox` o una propia). `luacheck` sigue siendo válido
donde ya está, pero **su falta de releases desde 2024 es un riesgo declarado**. `stylua.toml`
committeado y `stylua --check` como gate.

**Tipado**: en código nuevo no trivial, o **Teal** (compila a Lua, tipos reales; solo si controlas el
build del host) o Lua plano **con anotaciones `---@` de LuaLS** verificadas en CI
(`lua-language-server --check`). Sin una de las dos, un refactor en Lua es a ciegas.

**LuaRocks es el punto frágil del stack**: resuelve mal versiones transitivas, muchos rocks no
declaran la compatibilidad de rama (5.1 vs 5.4) y los que llevan C necesitan toolchain y cabeceras
del intérprete concreto. Regla: **árbol de rocks local por proyecto** (`luarocks --tree ./.rocks`),
`.rockspec` con `dependencies` acotadas por versión, y para OpenResty/Neovim **vendorizar** la
dependencia en el repo antes que depender de LuaRocks en el runtime de producción.

## 3. El lenguaje: lo que realmente rompe

- **Las variables son globales por defecto. Es el mayor fallo de diseño operativo de Lua.** Un typo
  crea una global silenciosa; en un host de larga vida (nginx worker, servidor de juego) eso es una
  fuga de memoria y una contaminación de estado entre peticiones. **`local` siempre**, sin excepción.
  Habilita detección: `luacheck`/`selene` marcan globales no declaradas, y en hosts que lo permitan
  carga un módulo `strict` que hace *error* al leer/escribir una global no declarada.
- **La tabla es la única estructura**: array, hash, objeto, módulo y namespace. No hay más.
  1-indexado. `#t` y `ipairs` **solo son fiables sin agujeros**; con `nil` en medio el resultado es
  indefinido — para colecciones dispersas, `pairs` y un contador explícito.
- **Metatablas y `__index`**: la herencia es una cadena de `__index`; úsala poco, explícita y plana
  (cada nivel es una indirección en el camino caliente). Documenta toda metatabla que no sea `__index`
  — `__gc`, `__close` (5.4+) y `__newindex` son potentes y opacos.
- **Los errores son valores, y `pcall` es el mecanismo**: `error()` desenrolla hasta el `pcall` más
  cercano. Convención: las funciones de librería devuelven `nil, err` (comprobable) y reservan
  `error()` para violaciones de contrato del programador. `xpcall` con `debug.traceback` para
  conservar la traza — con `pcall` la pierdes. **Un `pcall` cuyo error se descarta sin log es un veto.**
- **`nil` vs `false`**: solo `nil` y `false` son falsos; **`0` y `""` son verdaderos**. Distingue
  "ausente" (`nil`) de "presente y falso" (`false`) en toda API que devuelva flags. La coerción
  aritmética (`"10" + 1`) esconde bugs: convierte con `tonumber` y comprueba `nil`.
- En 5.3+ hay **enteros y floats separados** (`3/2` es float, `//` entera); en LuaJIT/5.1 todo es
  double. El mismo código sobre ambos, haciendo aritmética de índices o de dinero, **se comporta
  distinto**: fíjalo con tests.
- **Cierres**: baratos y el idioma natural para callbacks; ojo con capturar `self` o tablas grandes en
  cierres de larga vida (retienen memoria).
- **GC**: incremental por defecto; **5.4 añade modo generacional** (`collectgarbage("generational")`),
  que suele ganar con mucha basura joven. No toques sus parámetros sin medir pausas antes y después.

## 4. Criterio por host

### OpenResty / nginx (`lua-nginx-module`)
- **Prohibición dura: ninguna llamada bloqueante en el ciclo de eventos.** Un worker de nginx sirve
  miles de conexiones en un hilo; una llamada bloqueante las congela todas. Vetado en el código de
  petición: `os.execute`, `io.*` sobre ficheros, `socket.*` de LuaSocket, cualquier librería con I/O
  síncrono, `ngx.sleep` en bucle de espera activa, y librerías C que bloqueen. Usa **cosockets**
  (`ngx.socket.tcp`), `ngx.timer.at`, `resty.http`, `lua-resty-redis`, `lua-resty-mysql`.
- Cada petición corre en una **corrutina ligera** gestionada por el módulo: `ngx.thread.spawn` /
  `ngx.thread.wait` para paralelizar subpeticiones; el objeto cosocket **no se comparte entre
  peticiones ni entre corrutinas**.
- **Fases del ciclo de vida**, cada una con lo que puede hacer: `init_by_lua` (arranque del master:
  precarga de módulos y datos inmutables), `init_worker_by_lua` (timers y estado por worker),
  `set_by_lua` (**bloquea, solo cómputo trivial**), `rewrite`/`access_by_lua` (auth, routing),
  `content_by_lua`, `header_filter`/`body_filter_by_lua` (**sin I/O**), `log_by_lua` (**sin cosockets
  bloqueantes**: usa buffer + timer). Elegir la fase equivocada es el bug más común.
- **`ngx.shared.DICT` es el único estado compartido entre workers**: tamaño fijo declarado en
  `nginx.conf`, valores solo escalares/strings, y **puede evictar por LRU cuando se llena** — comprueba
  el segundo retorno de `:set()` (`err == "no memory"`) y trata el fallo. No es una base de datos ni
  sustituye a Redis; es una caché de proceso con lock global por operación.
- `lua_code_cache on` en producción **siempre**; `off` solo en desarrollo (recompila cada petición).
- Un módulo `require`-ido se cachea por worker: **el estado a nivel de módulo persiste entre
  peticiones**. Nada mutable por petición a nivel de módulo — es la fuente clásica de fuga de datos
  entre usuarios.
- Prefiere `*_by_lua_file` a `*_by_lua_block` en cuanto el código pase de unas líneas: el Lua incrustado
  en `nginx.conf` no se lintea, no se testea y no se revisa bien.

### Neovim
- El intérprete es **LuaJIT**: escribes Lua 5.1 con extensiones. No asumas `goto`, `integer division`
  ni APIs de 5.4.
- `init.lua` como único punto de entrada; configuración partida en `lua/<usuario>/*.lua` cargada con
  `require`. Nada de lógica en `init.lua` más allá del bootstrap del gestor de plugins.
- **API**: `vim.api.nvim_*` (API estable y tipada) por defecto; `vim.fn.*` solo para funciones de
  Vimscript sin equivalente; `vim.opt`/`vim.o` para opciones. **`vim.loop` está deprecado: usa
  `vim.uv`** (mismo binding de libuv). Cachea el handle (`local uv = vim.uv`) en rutas calientes.
- Estructura de plugin: `lua/<plugin>/init.lua` con `M.setup(opts)` idempotente, `plugin/<plugin>.lua`
  solo para lo que debe correr al cargar, `doc/` con `:help`. **Nada de trabajo pesado en el nivel
  superior del módulo**: eso se ejecuta al `require` y se paga en el tiempo de arranque.
- Gestor: **lazy.nvim**, con `lazy-lock.json` **committeado** (es el lockfile: sin él tu config no es
  reproducible). Carga perezosa por `event`/`ft`/`cmd`/`keys`, no `lazy = false` por comodidad.
- Autocomandos siempre en un `augroup` propio con `clear = true` — si no, se duplican al recargar.
- No bloquees la UI: I/O con `vim.uv` async o `vim.system()`; `vim.schedule` para volver al hilo
  principal desde un callback. `vim.fn.system()` síncrono en un autocomando es un editor congelado.

### Redis / Valkey (`EVAL` / `EVALSHA` / Functions)
- El intérprete es **Lua 5.1** con sandbox: `os`, `io` y acceso al sistema no existen.
- **El script es atómico y bloquea el servidor entero mientras corre.** Corolario operativo: los
  scripts son **cortos y acotados**; nada de bucles sobre colecciones de tamaño no acotado, ni `KEYS *`,
  ni O(n) sobre estructuras grandes. Un script lento es una caída de latencia global.
- **Determinismo**: histórico y todavía criterio correcto. Hoy la replicación es **por efectos** (los
  comandos de escritura se replican, no el script) — por defecto desde Redis 5.0 y **la replicación
  verbatim ya no se soporta desde Redis 7.0**, lo que relaja la restricción del motor. **La regla de
  ingeniería no se relaja**: no generes aleatoriedad ni leas el tiempo dentro del script. Pasa el
  timestamp y cualquier valor aleatorio **como argumento (`ARGV`)** desde el cliente: es
  reproducible, testeable y auditable. Si necesitas la hora del servidor, `redis.call('TIME')`, nunca
  una fuente Lua.
- **Todas las claves accedidas van en `KEYS`**, nunca construidas dentro del script: es el contrato
  que permite funcionar en cluster (todas las claves deben caer en el mismo slot; usa *hash tags*).
- `local` en cada variable: **contaminar el estado global de Lua rompe la consistencia** del servidor.
- Despliegue: `SCRIPT LOAD` + `EVALSHA` con *fallback* a `EVAL` ante `NOSCRIPT` (el caché de scripts se
  pierde al reiniciar y no se replica de forma fiable). Para lógica estable y versionada, **Redis
  Functions** (`FUNCTION LOAD`) es preferible a un `EVAL` suelto: se persiste y se replica.
- Los scripts son **código versionado en el repo**, no strings pegados en el código de aplicación.

### Juegos y modding
- Lua embebido en un motor con el fin explícito de que **terceros escriban código**: eso es §5 y no es
  negociable. Sandbox obligatorio, superficie de API mínima y auditada, y presupuestos de CPU/memoria.
- El estado del mod vive en el host, no en globales de Lua; expón funciones, no tablas mutables del
  motor. Cuidado con `__gc` y con retener referencias a objetos nativos: es la vía habitual de
  *use-after-free* a través de la frontera C.

### Otros hosts (acotado)
**Wireshark** (dissectors en Lua: código de análisis que corre sobre tráfico no confiable — trátalo
como parser hostil), **HAProxy** (`lua-load`, mismo veto de bloqueo que OpenResty sobre su bucle de
eventos), **Kong** (plugins sobre OpenResty: aplica la sección de OpenResty tal cual, más el ciclo de
vida de plugin de Kong). Para cada uno, la regla es idéntica: **lee qué versión de Lua embebe, qué
bibliotecas expone y qué operaciones bloquean su bucle** antes de escribir una línea.

## 5. Seguridad: ejecutar Lua de usuario es ejecutar código

**Punto de partida, sin matices: si cargas Lua que no has escrito tú, estás ejecutando código
arbitrario dentro de tu proceso.** El sandbox reduce el daño; no lo elimina.

- **Superficie de carga**: `load` / `loadstring` / `loadfile` / `dofile` / `require` sobre contenido
  no confiable son el sink. Usa `load(chunk, name, "t", env)` — el modo **`"t"` (solo texto) es
  obligatorio**: aceptar bytecode (`"b"`) es fatal, porque **el verificador de bytecode de Lua no es
  robusto** y un chunk precompilado malicioso corrompe la memoria del intérprete y escapa del sandbox
  sin necesidad de ninguna función peligrosa.
- **Entorno**: en 5.2+ pasa un `_ENV` explícito como cuarto argumento de `load`; en 5.1/LuaJIT,
  `setfenv` sobre la función cargada. El entorno es una **allowlist** construida desde cero, nunca
  una copia de `_G` con cosas borradas.
- **Fuera del entorno, siempre**: `os` (`execute`, `getenv`, `remove`, `rename`, `exit`, `tmpname`),
  `io` completo, `package` y `require` (permite cargar cualquier `.so`), `debug` **entero** (`debug`
  rompe cualquier sandbox: `getupvalue`/`setupvalue`/`getregistry` dan acceso al estado del host),
  `load`/`loadstring`/`loadfile`/`dofile`, `collectgarbage`, `rawset`/`rawget` sobre tablas del host,
  y `string.dump`. De `os`, como mucho `os.time`/`os.clock`/`os.date` si el determinismo no importa.
- **Cuidado con las referencias indirectas**: `("").format` alcanza la metatabla de strings, que es
  **global y compartida**; si el sandbox puede modificarla, contamina al host. Protege la metatabla de
  strings (`debug.setmetatable` en el host, `__metatable` para bloquear `getmetatable`) y congela las
  tablas del entorno con `__newindex = function() error(...) end`.
- **Un sandbox en Lua puro nunca es suficiente**, porque no acota recursos:
  - **CPU**: `while true do end` cuelga el proceso. Mitigación: hook de conteo de instrucciones
    (`debug.sethook(co, fn, "", N)`) que aborta al superar el presupuesto — instalado **desde el
    host**, sobre una corrutina, y sabiendo que el propio `debug` no debe quedar expuesto al invitado.
    Es mitigación parcial: hay operaciones (patrones de `string`, concatenaciones enormes) que gastan
    mucho tiempo en pocas instrucciones.
  - **Memoria**: una tabla que crece sin límite agota la RAM del host. Mitigación real: **asignador
    con límite** (`lua_newstate` con tu propio allocator que falle al superar el cupo) — se hace en C,
    no en Lua.
  - **Patrones**: `string.find`/`gsub` con patrones del usuario sobre entradas grandes son un DoS
    (retroceso). No aceptes patrones de usuario; si debes, acota longitud de patrón y de sujeto.
- **Aislamiento real**: para código verdaderamente no confiable, el control que corta es **el
  proceso**: intérprete en proceso separado, sin privilegios, con `rlimit` de CPU/memoria/ficheros,
  seccomp y sin red, y comunicación por IPC acotado. El sandbox in-process es defensa en profundidad,
  no la frontera.
- **Inyección clásica**: nunca construyas código Lua concatenando input (`load("return "..x)`) — es
  `eval` con otro nombre. Nunca construyas SQL, comandos ni rutas por concatenación desde Lua.
- **Secretos**: fuera del código y fuera de `nginx.conf`; en OpenResty entran por entorno
  (`env` + `os.getenv` en `init_by_lua`) o por un fetch en arranque, y **nunca a `ngx.shared.DICT`
  ni a logs**. Cuidado con volcar tablas de contexto en logs de error: llevan tokens.
- **SCA**: LuaRocks no tiene un ecosistema de auditoría comparable a npm/PyPI. Consecuencia práctica:
  minimiza dependencias, fija versiones exactas en el `.rockspec`, y **revisa el código** de los rocks
  con extensiones C que entren en producción.

## 6. Rendimiento y operabilidad

- Perfila antes de optimizar; en LuaJIT, comprueba primero que tu camino caliente **compila** (`-jv`,
  `-jdump`): un bail-out a intérprete por una construcción NYI cuesta más que cualquier micro-ajuste.
- Coste real y medible: concatenación en bucle es O(n²) (acumula en tabla y `table.concat`); una
  global es un lookup en hash (cachea `local ngx = ngx`, `local fmt = string.format` en el módulo).
- **Timeouts explícitos en todo I/O**: `settimeout`/`set_timeouts` en cada cosocket; el default de
  muchas librerías es demasiado alto o infinito. Reintentos con backoff solo en operaciones idempotentes.
- Observabilidad: logs estructurados con id de correlación (en OpenResty, `ngx.var.request_id`);
  métricas por worker vía `ngx.shared.DICT` en un endpoint interno. Un error que solo aparece en
  `error.log` sin nivel ni contexto es un incidente invisible.
- Vigila `collectgarbage("count")` como métrica: en hosts de larga vida, el crecimiento monótono es el
  síntoma de globales acumuladas o cierres retenidos. En OpenResty, el cambio de Lua exige `reload`:
  diseña el arranque barato e idempotente.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: LuaJIT se actualiza siguiendo la rama `v2.1` con snapshots fechados y revisión de los
  cambios, no una vez al año. Lua 5.4/5.5 se actualizan en patch sin drama; el salto de rama (5.1→5.4,
  5.4→5.5) es un **proyecto**, no un bump de versión.
- Toda dependencia sin release en >18 meses se revisa (aplica hoy a `luacheck`); toda extensión C se
  audita antes de entrar.
- Migrar de LuaJIT a Lua 5.4 solo con motivo (necesitas 5.4 de verdad) y midiendo: se pierde el JIT y
  la FFI, y eso puede ser un orden de magnitud en el camino caliente.

**Lista de prohibiciones (veto):**
- ❌ Variables globales implícitas. `local` o justificación escrita en el código.
- ❌ **PROHIBIDO** cualquier llamada bloqueante en el ciclo de eventos de OpenResty/HAProxy
  (`os.execute`, `io.*`, LuaSocket, librerías C síncronas). Es una caída, no un *code smell*.
- ❌ **PROHIBIDO** `load`/`loadstring` con modo que acepte bytecode (`"b"`/`"bt"`) sobre entrada no
  confiable. Solo `"t"`.
- ❌ **PROHIBIDO** exponer `debug`, `package`, `require`, `os` o `io` a código no confiable; y
  **PROHIBIDO** tratar un sandbox en Lua puro como frontera de seguridad sin límites de CPU/memoria
  impuestos desde el host.
- ❌ Construir código Lua, SQL o comandos por concatenación de input.
- ❌ Aleatoriedad o lectura del reloj dentro de un script de Redis/Valkey; claves no declaradas en
  `KEYS`; scripts con bucles no acotados.
- ❌ `pcall` cuyo error se descarta sin log ni propagación.
- ❌ Estado mutable por petición a nivel de módulo en OpenResty; globales que persisten entre peticiones.
- ❌ Depender de `#t`/`ipairs` sobre tablas con agujeros.
- ❌ Publicar/desplegar sin `lazy-lock.json` (Neovim) o sin versiones fijadas en el `.rockspec`.
- ❌ Lua incrustado en `nginx.conf` más allá de unas líneas (usa `*_by_lua_file`).
- ❌ `lua_code_cache off` en producción.
- ❌ Tarballs de LuaJIT de terceros o el tarball automático de GitHub; el tag `v2.1.ROLLING` como pin.
- ❌ **Elegir Lua para código nuevo que no está embebido en un host que lo exija.** Lua brilla como
  lenguaje de extensión dentro de un proceso ajeno; como lenguaje de aplicación standalone, su
  ecosistema (paquetes, auditoría, tipos, librería estándar mínima) es un coste que casi nunca compensa
  frente a Python o Go.

## 8. Verificación web obligatoria

Antes de fijar versiones o APIs, **verifica online** (WebSearch/WebFetch, y los feeds Atom
`https://github.com/OWNER/REPO/releases.atom` — `api.github.com` devuelve 403 sin autenticar):
1. **LuaJIT**: actividad de la rama `v2.1` (commits recientes) y estado del proyecto en `luajit.org/status.html`.
   Es el dato que decide si un proyecto nuevo puede apoyarse en él. No hay tags de release: no busques una.
2. **Lua**: `lua.org/news.html` y `lua.org/versions.html` — última de 5.4, estado y adopción de **5.5.0**
   (publicada el 22-dic-2025), y si ha salido ya 5.5.1 o 5.4.9.
3. Versiones y **licencias en crudo** de StyLua y selene (**ambas MPL-2.0**, no MIT), LuaLS, Teal,
   busted y LuaRocks; y si `luacheck` ha vuelto a publicar release.
4. Versión de **OpenResty** y de `lua-nginx-module` (a ago-2026 la rama 0.10.32 estaba en *release
   candidate*: no fijes un `rc` en producción sin comprobar si ya hay final).
5. **Neovim**: versión estable (0.12.x a ago-2026) y la lista de deprecaciones (`:help deprecated`)
   antes de escribir un plugin — `vim.loop`→`vim.uv` no es la única.
6. **Redis/Valkey**: versión de Lua embebida en la versión concreta que despliegas y estado de
   Functions vs `EVAL`; las reglas de replicación cambiaron en 5.0 y 7.0.
7. CVEs del intérprete y de las extensiones C que uses (osv.dev / GitHub Advisories).

**Discrepancia declarada**: el feed Atom de releases de LuaRocks presenta un `updated` de feed
(2025-12-28) anterior al de su entrada más reciente (LuaRocks 3.13.0, `updated` 2026-01-28). La
versión 3.13.0 se da por buena; **su fecha de publicación no queda verificada** — confírmala en
`luarocks.org` antes de citarla.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
