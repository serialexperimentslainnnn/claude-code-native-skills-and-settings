---
name: webassembly-standards
description: Use when WebAssembly is the compilation target or the runtime - .wasm and .wat modules, WIT files and wit-bindgen, the Component Model and WASI (wasip1/wasip2/wasip3, WASI 0.2/0.3), Rust targets wasm32-unknown-unknown/wasm32-wasip1/wasm32-wasip2, Emscripten emcc, TinyGo -target=wasip2, GOOS=wasip1, dotnet wasm, wasm-bindgen, wasm-pack, wasm-tools, wabt (wat2wasm/wasm2wat), binaryen wasm-opt, Wasmtime, WasmEdge, Wasmer, wazero, Extism plugin hosts, runwasi or containerd-shim-spin, edge functions running Wasm, or sandbox limits, fuel/epoch metering and module size budgets.
---

# Estándares WebAssembly (target de compilación y runtime)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**WebAssembly no es un lenguaje: es un objetivo de compilación y un modelo de ejecución.** Esta skill
decide **si Wasm es la respuesta**, qué target y qué runtime, qué capacidades importa el host, qué
límites de recursos se fijan y cuánto puede pesar el artefacto. El código fuente lo manda la skill
del lenguaje.

Triggers: `.wasm`, `.wat`, ficheros `.wit` y `wit-bindgen`, `wasm-tools`, `wasm-opt`/binaryen,
`wat2wasm`/`wasm2wat` (wabt), `wasm-bindgen`/`wasm-pack`, targets `wasm32-*` de Rust, `emcc`,
`tinygo -target=wasip2`, `GOOS=wasip1`, Wasmtime/WasmEdge/Wasmer/wazero, Extism, `runwasi` /
`containerd-shim-spin` / `RuntimeClass` de Wasm, funciones edge en Wasm, y cualquier discusión de
*sandbox*, *fuel*/epoch, límites de memoria o tamaño de módulo.

**No aplica**:

- **Lenguaje de origen** (**suyo**: cómo se escribe el código, su build, sus tests, su lint;
  **aquí**: el target Wasm, el runtime, el modelo de componentes, los límites del sandbox y el tamaño
  del artefacto): `rust-standards`, `c-standards`, `cpp-standards`, `go-standards`,
  `dotnet-standards`, `typescript-standards`, `dart-standards` (el lenguaje Dart, `pub`,
  los lint y los tests son suyos; que Flutter web compile a WasmGC es de aquí).
- `kubernetes-standards` y `container-runtime-security-standards` (**Wasm como alternativa o
  complemento al contenedor**: el runtime de contenedores, la admisión, las políticas del clúster y
  el aislamiento del nodo son **suyos**; el módulo Wasm, su host embebido y las capacidades que ese
  host importa son de **aquí**).
- `caching-cdn-standards` (el *edge* como plataforma: caché, invalidación, propagación y coste; aquí
  solo el módulo que se ejecuta en él y sus límites).
- `webgl-webgpu-standards` (los dos se cruzan constantemente porque los motores gráficos
  portados desde C++ llegan como Wasm y los transcodificadores de textura son módulos Wasm. **El
  módulo, su tamaño, su runtime y sus importaciones son de aquí**; **el canvas, el pipeline de GPU,
  el presupuesto de fotograma y la degradación a WebGL2 son suyos**), `pwa-standards` (el
  *service worker* que cachea y sirve el módulo, y su modelo de actualización, son suyos — un `.wasm`
  precacheado con una estrategia equivocada es un binario viejo servido rápido).
- `compilers-dsl-standards` (**emitir Wasm desde un backend propio es suyo**: gramática, IR,
  generación de código y diagnósticos; **aquí el target, el runtime, el sandbox y el artefacto**).
- `appsec-standards` (metodología: modelado de amenazas, clases de vulnerabilidad, ASVS; **aquí** el
  sandbox concreto, la superficie de importaciones y los límites de recursos).
- `local-inference-standards` y `gpu-computing-standards` (si Wasm aparece por inferencia en el
  navegador: el modelo, la cuantización y la aceleración son suyos; el módulo y su runtime, de aquí).
- Comunes: `cicd-standards` (la pipeline que ejecuta los gates de §4), `secrets-management-standards`
  (custodia y rotación de los secretos que el host **decide** o **no** pasar al invitado),
  `vulnerability-management-standards` (triaje y SLA de las CVEs de runtime y toolchain),
  `api-design-standards` (el contrato de red que el módulo expone o consume; el contrato **WIT** es
  de aquí), `observability-standards` (pipeline de telemetría; aquí la instrumentación del host y del
  módulo).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

**Decisión cero — ¿Wasm o no?** Ver §7: la mayoría de las veces la respuesta correcta es *no*. Lo que
sigue aplica una vez el caso está justificado por escrito.

| Decisión | Elección por defecto | Estado a ago-2026 | Por qué |
|---|---|---|---|
| Runtime embebido en un producto | **Wasmtime** | v47.0.3 (2026-07-31); **Apache-2.0 WITH LLVM-exception** (el `LICENSE` incluye literalmente `--- LLVM Exceptions to the Apache 2.0 License ----`) | Runtime de referencia de la **Bytecode Alliance**; es donde aterrizan primero el Component Model y WASI. Gobernanza de fundación, no de una empresa |
| Runtime embebido en Go, sin CGO | **wazero** | v1.12.0 (2026-05-29); **Apache-2.0** (`LICENSE` en crudo) | Escrito en Go puro: **cero CGO**, cross-compila como cualquier binario Go. Si el host es Go, esto gana por operabilidad |
| Runtime para plugins de producto | **Extism** (sobre Wasmtime) | v1.30.0 (2026-07-16); **BSD-3-Clause** (`Copyright 2022 Dylibso, Inc.` + las 3 cláusulas, verificado en crudo — **no es MIT ni Apache**, comprueba la compatibilidad con tu política de licencias) | SDKs de host en muchos lenguajes y un modelo de plugin ya resuelto; evita reimplementar el ABI a mano |
| Runtime con foco edge/AI | **WasmEdge** | 0.17.1 (2026-07-06); **Apache-2.0** (`LICENSE` en crudo, rama `master`) | Proyecto CNCF, integración con containerd/runwasi |
| Wasmer | Solo por necesidad concreta (WASIX, dynamic linking) | v7.2.1 (2026-07-23); el `LICENSE` del repo principal es **MIT** (`Copyright (c) 2019-present Wasmer, Inc. and its affiliates.`) | **Ojo**: la empresa monetiza Registry y Wasmer Edge (servicios), y **WASIX es una extensión propia, no un estándar** — adoptarlo es lock-in. Verifica licencia **por crate/componente**, no solo el `LICENSE` raíz (§8) |
| Rust → navegador | `wasm32-unknown-unknown` + `wasm-bindgen` / `wasm-pack` | Target **Tier 2 sin host tools**; wasm-bindgen 0.2.126 | El target no aporta *ninguna* API de sistema: todo entra por importaciones que tú declaras |
| Rust → fuera del navegador | `wasm32-wasip1` (módulo core, soporte más amplio) o **`wasm32-wasip2`** (componente) | Ambos **Tier 2 sin host tools**. También existen `wasm32-wasip1-threads` (Tier 2), `wasm32v1-none` (Tier 2), `wasm32-unknown-emscripten` (Tier 2 con host tools), y **Tier 3**: `wasm32-wasip3`, `wasm64-unknown-unknown`, `wasm32-wali-linux-musl` | **Los nombres cambiaron**: `wasm32-wasi` ya no existe. **Tier 3 = sin garantías de que compile**: `wasm32-wasip3` no es una elección de producción hoy |
| C/C++ → Wasm | **Emscripten** (`emcc`) | 6.0.5 (2026-07-28) | Es el único camino realista si arrastras SDL/OpenGL/pthreads/filesystem; trae su propio shim de POSIX |
| Go → Wasm | Upstream Go `GOOS=wasip1 GOARCH=wasm` + `//go:wasmexport` para módulo core; **TinyGo `-target=wasip2`** si necesitas componente | TinyGo 0.41.1 | El compilador de Go upstream **no produce componentes**; y sus binarios son mucho más grandes que los de TinyGo (Go embarca runtime + GC completos) |
| Interfaz entre componentes | **WIT** + `wit-bindgen` | — | El contrato se escribe en `.wit` y se versiona como cualquier API |
| Herramientas | `wasm-tools` (validate/component/print), `wasm-opt` (binaryen), `wabt` | wasm-tools v1.255.0; binaryen version_131; wabt 1.0.41 | `wasm-tools validate` en CI; `wasm-opt -Oz` en release |

## 3. Modelo de ejecución: qué garantiza el sandbox y qué NO

**Lo que sí garantiza, por diseño:**

- **Memoria lineal aislada**: el módulo solo direcciona su propia memoria. Un acceso fuera de rango
  es un trap, no una lectura del proceso host. No hay punteros al espacio del host.
- **Integridad del flujo de control**: la pila de llamadas no es direccionable desde el módulo; no se
  puede sobrescribir una dirección de retorno. Los *jumps* son a índices validados de tabla.
- **Cero acceso al sistema por defecto**: sin ficheros, sin red, sin reloj, sin entropía, sin
  variables de entorno, sin llamadas al SO. **Todo lo que el módulo puede hacer con el exterior son
  las funciones que el host le importa.** Ese es *el* control de seguridad; el resto es consecuencia.
- **Determinismo** dentro del perfil determinista de Wasm 3.0 (útil para replay y auditoría).

**Lo que NO garantiza — y aquí es donde se rompen los despliegues:**

- **No protege de un bucle infinito.** Sin metering, un módulo hostil o con un bug consume la CPU
  hasta que alguien lo mate. **Fija combustible o interrupción por tiempo, siempre**: `fuel` o
  `epoch_interruption` en Wasmtime, límites equivalentes en el runtime que uses. Un host que
  ejecuta código de terceros sin límite de ejecución no tiene sandbox, tiene una promesa.
- **No protege del agotamiento de memoria.** Fija el **máximo de páginas de memoria lineal** y el
  tamaño de pila; una memoria que crece sin techo es un OOM del proceso host, y el que muere es el
  host, no el invitado.
- **No protege de la lógica maliciosa dentro de lo que le has concedido.** Si le importas
  `open_file(path)` sin acotar, exfiltrará ficheros; si le importas `http_fetch(url)` sin allowlist,
  tienes SSRF con esteroides. **El sandbox mueve la frontera de confianza a la lista de
  importaciones**; si esa lista es generosa, no has aislado nada.
- **No protege de los bugs del propio runtime.** Wasmtime, WasmEdge y compañía han tenido CVEs de
  escape. El runtime es software privilegiado: se parchea con la misma urgencia que un hipervisor.
- **No arregla la memoria insegura del invitado.** Un desbordamiento en C compilado a Wasm sigue
  corrompiendo *sus* estructuras dentro de la memoria lineal — y en Wasm la memoria lineal **no tiene
  ASLR, ni páginas de guarda internas, ni NX dentro del heap del módulo**: un bug que en nativo sería
  un crash puede ser explotable *dentro* del módulo. Wasm contiene el daño al módulo; no lo elimina.
- **Los canales laterales no desaparecen** (timing, caché). Si el modelo de amenaza incluye
  co-tenencia hostil con secretos en el host, el sandbox de Wasm no es la respuesta completa.

**Presupuesto obligatorio por instancia** (escríbelo, no lo dejes al default): límite de combustible
o de tiempo de pared, memoria lineal máxima, profundidad de pila, número de instancias concurrentes,
timeout por llamada, y **qué pasa al agotarse** (trap → error de dominio manejado, nunca proceso host
caído). Instancia por petición y desechada; nada de reutilizar una instancia con estado entre
tenants.

## 4. Estandarización: qué es estándar y qué es propuesta

Este es el punto donde más información caducada circula. A ago-2026:

**WebAssembly 3.0 — estándar vivo desde 2025-09-17.** El anuncio oficial dice: *"Today, we are happy
to announce the release of Wasm 3.0 as the new 'live' standard."* Incluye, verbatim del anuncio:
*64-bit address space; Multiple memories; Garbage collection; Typed references; Tail calls; Exception
handling; Relaxed vector instructions; Deterministic profile; Custom annotation syntax; JS string
builtins.* Sobre despliegue: *"Wasm 3.0 is already shipping in most major web browsers, and support in
stand-alone engines like Wasmtime is on track to completion as well."*

- **GC / WasmGC**: **estandarizado en 3.0**. Es el cambio que importa (ver §5): el motor gestiona la
  memoria, y los lenguajes con GC dejan de embarcar el suyo.
- **Exception handling**: **estandarizado en 3.0** (tags, `exnref`).
- **SIMD (128-bit)**: estandarizado desde antes; **relaxed SIMD** entra en 3.0 con fallback
  determinista explícito.
- **Memory64**: estandarizado en 3.0. **Pero en la web los navegadores imponen su propio tope** — no
  asumas 16 exabytes en un navegador; mide.

**Lo que NO está estandarizado, por mucho que se hable de ello** (fases del repo
`WebAssembly/proposals`, verificadas):

- **Threads: Phase 4** ("Standardize the Feature"), **no** Phase 5. No entró en la lista de Wasm 3.0.
  Fuera del navegador el soporte es desigual: `wasm32-wasip1-threads` existe en Rust como target
  Tier 2, pero **el paralelismo no es una propiedad que puedas dar por hecha**.
- **Shared-Everything Threads: Phase 1.** Es una propuesta temprana; tratarla como algo cercano es un
  error de planificación.
- **Component Model: Phase 1.** Sí, **fase 1** en el proceso del CG, pese a que la Bytecode Alliance
  lo empuja como pieza central y a que WASI ya se define sobre él. **Criterio**: el Component Model es
  una **especificación de la Bytecode Alliance con implementaciones reales (Wasmtime, jco,
  wit-bindgen)**, no un estándar del W3C/WebAssembly CG. Adoptarlo es una decisión razonable; venderlo
  internamente como "estándar" no lo es, y su superficie sigue moviéndose.
- **Stack Switching: Phase 3.** **Wide Arithmetic: Phase 3. Custom Page Sizes: Phase 3.**
- **Memory Control: Phase 1.**

**WASI**: hay tres hitos — **0.1 (Preview 1)**, **0.2 (Preview 2)** y **0.3 (Preview 3)**.

- **WASI 0.3.0 se publicó el 2026-06-11** y la Bytecode Alliance lo declara estable: *"WASI 0.3 has
  passed the WASI Subgroup vote. This is a stable release, which means programs you compile for it
  today are guaranteed to keep working in the future."* Su cambio central es **async nativo en el
  Component Model** (`stream<T>`, `future<T>`, `async func`) y la **desaparición de `wasi:io`**, cuya
  funcionalidad *"is now part of the canonical ABI, where the Component Model now offers these
  primitives natively"*.
- **Soporte real**: Wasmtime 45 corría el RC y **Wasmtime 46 lo trae con Component Model Async
  activado por defecto**; jco soporta todo WASI 0.3. **Pero los toolchains de invitado (Rust, Go,
  JavaScript, Python…) seguían "in progress"**. Esa es la restricción operativa que decide tu
  proyecto, no la ratificación de la spec.
- **Criterio a ago-2026**: **WASI 0.2 (`wasip2`) es el objetivo de producción**; **WASI 0.1
  (`wasip1`)** sigue siendo lo más compatible con runtimes viejos y sigue siendo válido para módulos
  core simples; **WASI 0.3 (`wasip3`)** se adopta cuando **tu** toolchain de invitado lo soporte —
  en Rust su target es **Tier 3**, y Tier 3 significa que ni siquiera hay garantía de que compile.

**Discrepancia declarada**: la documentación oficial del Component Model
(`component-model.bytecodealliance.org`) seguía afirmando a ago-2026 que *"The current stable release
of WASI is WASI 0.2.0, which was released on January 25, 2024"*, mientras la propia Bytecode Alliance
había anunciado WASI 0.3.0 como release estable el 2026-06-11. La documentación va por detrás del
anuncio: **verifica el estado contra el repo `WebAssembly/WASI` y las notas de release de Wasmtime,
no contra la web de docs**.

## 5. Casos de uso: cuándo Wasm gana

**A. Plugins y extensión segura de un producto — el caso más fuerte hoy.**
Es el único donde Wasm es claramente la mejor herramienta y no solo una alternativa: quieres ejecutar
código que **no controlas** dentro de tu proceso, con una frontera fuerte y sin pagar el arranque de
un contenedor o de un proceso. Wasmtime o wazero embebidos, o **Extism** si no quieres construir el
ABI. Criterios: superficie de host **explícita y mínima** (una función por capacidad, con los
parámetros ya acotados: no `open(path)`, sino `read_config()`), instancia por invocación, límites de
§3 en todas, y contrato de plugin versionado (WIT o el esquema de Extism).

**B. En el navegador — cuándo compensa frente a JS.**
Compensa cuando: (1) hay **cómputo pesado y sostenido** —códecs, criptografía, CAD, simulación,
tratamiento de imagen/audio, parsers grandes—; (2) quieres **portar una base C/C++/Rust que ya existe
y está probada** en lugar de reescribirla; (3) necesitas rendimiento **predecible** (sin el
calentamiento y las desoptimizaciones del JIT de JS).
**No compensa cuando**: (1) el trabajo es **manipulación del DOM** — Wasm **no tiene acceso directo al
DOM** y cada toque cruza a JS; (2) el módulo es pequeño y la lógica es de pegamento: el **coste de
descarga y compilación del `.wasm`** se come cualquier ganancia; (3) el patrón es **muchas llamadas
cortas** cruzando la frontera JS↔Wasm — el cruce y la conversión de tipos dominan, y acabas más lento
que en JS puro. **Regla**: llamadas pocas y gordas, no muchas y finas. Y **mide antes**: si no tienes
un benchmark de la versión JS, no tienes justificación.

**C. Edge / serverless.**
Aquí el argumento real es el **arranque en frío**: instanciar un módulo Wasm es órdenes de magnitud
más barato que arrancar un contenedor, lo que permite densidad y multi-tenencia en el borde. El coste
es que estás en la plataforma de un proveedor con **su** conjunto de APIs: portabilidad limitada por
las capacidades del host, no por el estándar. Antes de comprometerte: qué subconjunto de WASI ofrece,
qué límites de CPU/memoria impone, cómo se depura, y **cuánto cuesta salir**.

**D. WASI como alternativa a contenedores — sé honesto.**
El argumento (arranque en milisegundos, artefacto de MB en vez de cientos, sandbox por defecto,
portabilidad de arquitectura sin build multi-arch) es real. La madurez, no tanto: la ruta es
`runwasi` como shim de containerd + `RuntimeClass` de Kubernetes (o SpinKube para Spin), y funciona,
pero **el ecosistema alrededor es el que no está**: casi nada del software que ya operas tiene un
build Wasm, el soporte de hilos y de sockets es desigual, la depuración es mala (§6) y las
integraciones (agentes, sidecars, service mesh, herramientas de seguridad de runtime) asumen
contenedores. **Criterio**: Wasm sustituye al contenedor en cargas **nuevas, pequeñas, sin estado y
de alta densidad**; en cualquier otro caso es un **complemento** dentro de un clúster que sigue siendo
de contenedores. Migrar una carga existente a Wasm "para reducir arranque" casi nunca sale a cuenta.

**E. Por qué WasmGC cambia el reparto de lenguajes.**
Antes de WasmGC, un lenguaje con recolector de basura tenía que **compilar su propio GC a memoria
lineal** y embarcarlo en cada módulo: artefactos enormes, arranque lento y dos recolectores luchando
en el navegador. Con **GC estandarizado en Wasm 3.0**, el motor gestiona structs y arrays y el
lenguaje deja de embarcar su runtime de memoria — eso es lo que hace viables Dart/Flutter web, Kotlin,
Java y Scala sobre Wasm. **Matices que no se pueden saltar**: WasmGC no ofrece un sistema de objetos
ni closures, solo los primitivos; los lenguajes cuyo runtime necesita más que eso (**se reporta el
caso de .NET**, ver §8) siguen en memoria lineal; y **el soporte de navegador no es uniforme** —
Chromium/V8 desde la 119, Firefox anunció soporte estable en 120 pero *"currently doesn't work"* por
una limitación conocida, Safari lo soporta con un bug de compatibilidad, y **en iOS no funciona en
ningún navegador** porque todos usan WebKit. Cualquier plan de "web en WasmGC" necesita **fallback a
JS** o excluye iOS. Ver `dart-standards` para el lado Dart de esto.

## 6. Calidad, tamaño, depuración y operabilidad

**Tamaño del artefacto: métrica de primera clase.** En el navegador es latencia de usuario; en el
edge es coste y densidad; en un plugin es memoria por instancia multiplicada por N.

- Gate de CI con **presupuesto de bytes** que rompe el build al superarse (`.wasm` y `.wasm.br`).
- `wasm-opt -Oz` (binaryen) en release; `wasm-strip`/`--strip-debug` para producción, **guardando
  aparte los símbolos** para simbolizar stack traces.
- Rust: `panic = "abort"`, `lto`, `opt-level = "z"`/`"s"`, `codegen-units = 1`; evita `format!` y
  formateo de errores en el camino caliente (arrastra media `core::fmt`).
- Go upstream a Wasm da binarios grandes por diseño (runtime + GC): si el tamaño importa, es **TinyGo**.
- C/C++ con Emscripten: revisa qué shims estás arrastrando (filesystem, pthreads, SDL) — cada uno se
  paga en bytes.
- Comprime en transporte (Brotli) y sirve con MIME correcto para permitir compilación en streaming.

**Gates de CI** (coste creciente):

1. `wasm-tools validate` sobre el módulo/componente generado (y `wasm-tools component wit` para
   verificar que el WIT exportado es el esperado).
2. **Diff del contrato WIT**: un cambio incompatible en `.wit` debe romper el build, igual que un
   cambio incompatible en un `.proto`.
3. Tests del **invitado** con la toolchain de su lenguaje (los manda la skill del lenguaje).
4. Tests del **host**: instanciar el módulo real y ejercitar la frontera — incluyendo **el caso de
   trap, el de agotamiento de combustible y el de OOM del invitado**. Si no has probado que un plugin
   en bucle infinito se corta limpiamente, no lo has probado.
5. Presupuesto de tamaño.
6. Benchmark comparativo frente a la implementación previa (si Wasm sustituye algo, demuestra que
   gana).

**Depuración y observabilidad: el punto más débil, asúmelo antes de elegir Wasm.**

- **DWARF** en el `.wasm` funciona en navegador con la extensión de DevTools de C/C++ y en algunos
  runtimes standalone; **infla el módulo enormemente** — build de debug con DWARF, build de release
  sin, y **símbolos archivados** por versión para simbolizar después.
- **Source maps** para el caso web; Flutter web en Wasm los genera con `--source-maps`.
- **Perfilado**: soporte irregular. Wasmtime ofrece salida para `perf`/VTune; en navegador el profiler
  atribuye a funciones Wasm si conservas nombres (`name` section). **Sin nombres, un perfil de
  producción es ilegible**: decide si conservas la `name` section (peso vs. diagnóstico) y sé
  consciente de que también facilita el reversing de tu módulo.
- **Logs y trazas**: el invitado no tiene salida por sí mismo — **el host la importa**. Instrumenta en
  el host: duración por invocación, combustible consumido, traps por tipo, memoria pico, tamaño de
  entrada/salida. Correla con el trace del host propagando el contexto **explícitamente** por la
  frontera (no hay contexto ambiental que cruce).
- Métricas de capacidad: instancias concurrentes, tiempo de instanciación, aciertos de caché de
  módulos compilados (**precompila y cachea el módulo**: compilar en cada petición es el error de
  rendimiento clásico del host).

## 7. Sostenibilidad y prohibiciones

**Cadencia**

- El **runtime es software privilegiado**: parches de seguridad en <72 h, igual que un hipervisor.
  Wasmtime publica parches en varias ramas a la vez (a 2026-07-31 salieron simultáneamente 47.0.3,
  46.0.2, 36.0.13 y 24.0.12) — quédate en una rama soportada y súbela.
- Las propuestas se mueven: revisa el estado de fases y de WASI **cada trimestre**, no una vez.
- Fija toolchain (versión de compilador, `wasm-opt`, `wasm-tools`, `wit-bindgen`) en el repo y en la
  imagen de CI; que un `wasm-opt` distinto genere otro binario es un fallo de reproducibilidad.
- **Registra un ADR con el motivo de haber elegido Wasm y con la condición de salida.** Si el motivo
  deja de ser cierto, se revierte; una decisión de plataforma sin criterio de reversión es una trampa.

**Cuándo Wasm NO es la respuesta** (la sección de más valor: hay mucho entusiasmo y pocos casos donde
de verdad gane)

- ❌ **Como acelerador de una app web normal.** Si el trabajo es DOM, formularios, red y estado, Wasm
  no tiene nada que ofrecer: añade toolchain, tamaño y un cruce de frontera que cuesta.
- ❌ **Para código que ya escribes tú y confías.** El sandbox es valioso frente a **código ajeno**. Si
  el código es tuyo y va en tu proceso, aislarlo con Wasm es coste sin beneficio: usa una librería.
- ❌ **Para "hacer portable" lo que ya empaquetas en un contenedor** y funciona. El artefacto Wasm no
  te da nada que el contenedor no te diera, y pierdes todo el ecosistema operativo.
- ❌ **Para cargas con estado, I/O intensivo, muchos sockets o dependencia fuerte del SO.** El soporte
  es desigual, y donde existe suele ser más lento que nativo.
- ❌ **Como sustituto de un hipervisor o de gVisor/Kata frente a un atacante decidido con secretos
  compartidos en el host.** Es un sandbox de proceso, no una frontera de máquina (ver
  `container-runtime-security-standards`).
- ❌ **Como "el reemplazo de Docker".** No lo es, y planificar sobre esa premisa es deuda garantizada.
- ❌ **Cuando nadie del equipo sabe depurar un trap en producción.** La depuración es el eslabón
  débil (§6); si no tienes plan para eso, no metas Wasm en el camino crítico.
- ❌ **Cuando tu lenguaje de origen aún no soporta bien el target que necesitas** (ver "in progress"
  de los toolchains de invitado para WASI 0.3, y Tier 3 de `wasm32-wasip3`).

**LISTA DE PROHIBICIONES** (bloquean review)

- ❌ PROHIBIDO ejecutar código de terceros **sin límite de combustible/epoch y sin límite de memoria**.
- ❌ PROHIBIDO importar una capacidad genérica al invitado (`open`, `exec`, `fetch(url)` sin
  allowlist, acceso al FS del host sin preopen acotado). Una importación = una operación acotada.
- ❌ Preabrir `/` o el directorio de trabajo del host "para simplificar"; heredar variables de entorno
  del host en bloque (los secretos van dentro).
- ❌ Reutilizar una instancia con estado entre invocaciones de **tenants distintos**.
- ❌ Que un trap del invitado tumbe el proceso host, o que se ignore silenciosamente. Trap = error de
  dominio, registrado y devuelto.
- ❌ Cargar un `.wasm` de terceros **por URL o por tag mutable**. Se fija por **digest** (§ siguiente).
- ❌ Compilar el módulo en cada petición en vez de cachear el módulo compilado.
- ❌ Publicar el módulo de release **con DWARF completo** o **con la `name` section** sin haberlo
  decidido conscientemente (peso y superficie de reversing).
- ❌ Tratar el **Component Model** o **shared-everything threads** como estándares consolidados: son
  **Phase 1**.
- ❌ Escribir contra `wasm32-wasi` (target retirado) o dar por hecho que existe.
- ❌ Adoptar extensiones propietarias de un runtime (p. ej. WASIX) sin registrar el lock-in en un ADR.
- ❌ Asumir soporte de hilos, de sockets o de 64 bits sin comprobarlo en **tu** runtime y **tu**
  navegador objetivo.
- ❌ Elegir Wasm sin benchmark comparativo contra la alternativa que sustituye.
- ❌ Fijar versiones, targets o estados de propuesta de memoria en vez de contra la fuente oficial.

**Seguridad del stack — cadena de suministro y frontera de confianza**

- **El sandbox no es una frontera de confianza si el host importa capacidades sin criterio.** La
  auditoría de seguridad de un sistema Wasm es la **auditoría de la lista de importaciones**: cada
  función que expone el host, qué puede hacer con ella el peor invitado posible, y qué límites la
  acotan. Escríbela; revísala en cada PR que la toque.
- **Mínimo privilegio en las importaciones**: capacidades específicas y ya parametrizadas por el host,
  no primitivas generales. Preopens de directorio acotados al mínimo. Sin red salvo allowlist de
  destinos, aplicada **en el host** (un módulo hostil con salida libre es SSRF con persistencia).
- **Secretos**: no entran en el módulo. Ni en la memoria lineal al instanciar, ni por variables de
  entorno heredadas. El host hace la operación que necesita el secreto y devuelve el resultado. Un
  `.wasm` es tan inspeccionable como cualquier binario, y más fácil de descompilar
  (`wasm2wat`) — ver `secrets-management-standards`.
- **Validación de entrada en la frontera, en ambos sentidos**: el host valida lo que entrega al
  invitado **y lo que recibe de él** (longitudes, punteros a memoria lineal, índices, UTF-8). Un
  puntero/longitud devueltos por el invitado son **input no confiable**: comprobar rango contra el
  tamaño de la memoria es obligatorio, y omitirlo es la vulnerabilidad clásica de host.
- **Cadena de suministro de módulos de terceros**: firma y procedencia (cosign, atestaciones,
  distribución como artefacto OCI) **son necesarias pero no suficientes**. Precedente del catálogo:
  **hubo atestaciones SLSA L3 válidas emitidas para paquetes maliciosos** — una atestación demuestra
  *dónde y cómo* se construyó algo, **no que sea benigno**. El control que sí corta es **fijar por
  digest inmutable** (`sha256:…`), replicar el artefacto en tu registro y promover el **mismo digest**
  entre entornos. Tag mutable = ningún control.
- El runtime se parchea como componente privilegiado; sigue sus advisories (RustSec/GitHub Advisories
  para Wasmtime y wazero, releases de WasmEdge/Wasmer).
- Metodología general de amenazas: `appsec-standards`. Aislamiento del nodo y admisión en clúster:
  `container-runtime-security-standards` y `kubernetes-standards`.

## 8. Verificación web obligatoria

Antes de fijar versión, target, runtime o estado de una feature, **verifica online**:

1. **Fases de las propuestas**: `github.com/WebAssembly/proposals` — es la única fuente que zanja qué
   está estandarizado. Revisa en particular si **Threads** pasó de Phase 4 a 5 y si el **Component
   Model** ha salido de Phase 1; ambos cambian el criterio de §4.
2. **Wasm 3.0 y soporte de motores**: `webassembly.org/news/2025-09-17-wasm-3.0/` y la tabla de
   `webassembly.org/features/` (**se carga por JS**: puede no ser legible por fetch simple — usa el
   repo `WebAssembly/website` o la matriz de MDN/caniuse).
3. **WASI**: releases de `github.com/WebAssembly/WASI` y `bytecodealliance.org/articles/WASI-0.3`.
   Comprueba **el soporte en tu toolchain de invitado**, que a ago-2026 iba por detrás de la spec, y
   **no te fíes de `component-model.bytecodealliance.org` para el estado de versión** (discrepancia
   declarada en §4).
4. **Targets de Rust y su tier**: `doc.rust-lang.org/rustc/platform-support.html`. Los nombres han
   cambiado (`wasm32-wasi` → `wasm32-wasip1`) y `wasm32-wasip3` es **Tier 3**.
5. **Versiones y licencias de runtimes**, desde los feeds Atom (`.../releases.atom`) y el `LICENSE`
   **en crudo** (`raw.githubusercontent.com`), nunca de una tabla comparativa de terceros: Wasmtime,
   WasmEdge, Wasmer, wazero, Extism. **En Wasmer verifica licencia por crate/componente y el estado
   de sus servicios comerciales** — el `LICENSE` raíz siendo MIT no dice nada de los subcomponentes ni
   del Registry/Edge.
6. **CVEs de runtime y toolchain** antes de fijar versión: RustSec, GitHub Advisories, osv.dev.
7. **Wasm en Kubernetes**: estado de `runwasi`, `containerd-shim-*` y SpinKube (versiones, madurez,
   compatibilidad con la versión de containerd/K8s del clúster).

**Huecos no verificados a ago-2026** (marcados a propósito, sin rellenar):

- **Soporte de WasmGC por navegador con cifras actuales**: la afirmación de §5 procede de la
  documentación de Flutter (Chromium ≥119; Firefox 120 anunciado pero *"currently doesn't work"*;
  Safari con bug de compatibilidad; iOS no). **No verificado contra caniuse/MDN ni contra los bugs
  originales** (bugzilla 1788206, webkit 267291) en esta redacción: compruébalo antes de excluir o
  incluir una plataforma.
- **"WasmGC no cubre las necesidades del runtime de .NET"**: procede de una fuente secundaria, **no
  confirmado contra documentación oficial de .NET**. Verifica en la doc de Microsoft antes de fijar
  criterio para .NET.
- **Estado de gobernanza y financiación de la Bytecode Alliance** (miembros actuales, proyectos bajo
  su paraguas) no verificado en esta redacción más allá de que Wasmtime es su runtime de referencia.
- **Rendimiento relativo Wasm vs JS vs nativo**: deliberadamente sin cifras. Depende de la carga, el
  motor y la versión; **se mide en tu caso**, no se cita.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
