---
name: cpp-standards
description: Modern C++ engineering standards (staff-level). Trigger on .cpp/.cc/.cxx/.hpp/.ixx/.cppm files, -std=c++17/20/23/2c or /std:c++latest, CMakeLists.txt with add_library/target_link_libraries, CMakePresets.json, vcpkg.json, conanfile.py/conanfile.txt, .clang-tidy with cppcoreguidelines-* checks, GoogleTest/Catch2/doctest suites, Google Benchmark, std::unique_ptr/shared_ptr/move semantics/concepts/constexpr/ranges/coroutines/std::expected, C++ modules and import std, Boost or Abseil usage, the C++ Core Guidelines and GSL, or C++ memory-safety profiles and hardened standard library decisions.
---

# Estándares C++

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo en C++: ficheros `.cpp`/`.cc`/`.cxx`/`.hpp`/`.h` de C++, interfaces de módulo (`.ixx`/`.cppm`), selección de `-std=`/`/std:`, `CMakeLists.txt` y `CMakePresets.json` de targets C++, `vcpkg.json`, `conanfile.py`, `.clang-tidy`, suites de GoogleTest/Catch2/doctest, benchmarks, y las decisiones de diseño del lenguaje (propiedad, plantillas, `constexpr`, corrutinas, manejo de errores).

**Eje central**: **C++ moderno no es "C con clases"**. La diferencia no es cosmética: en C++ la corrección de recursos se expresa en el **sistema de tipos** (RAII, propiedad, `const`, movimiento, concepts), lo que en C se delega en disciplina humana. Código C++ que gestiona memoria a mano con `new`/`delete`, pasa punteros crudos con propiedad implícita, usa arrays C y `#define` en vez de `constexpr`, o devuelve códigos de error enteros, **no es C++ mal escrito: es C mal ubicado**, y se revisa como defecto de diseño, no como cuestión de estilo.

**No aplica**: ver `c-standards` (todo lo que decida sobre C puro: `-std=c23`, funciones prohibidas de la libc, MISRA C/CERT C, `-fanalyzer`, layout y garantías de las cabeceras C, hardening del binario C, y el **diseño** de la cabecera `extern "C"`). **Criterio de arbitraje** recíproco para código que compila en ambos lenguajes: manda el **estándar bajo el que se compila el target** (`-std=c++23` → esta skill; `-std=c23` → `c-standards`), **no** la extensión ni el estilo. La frontera `extern "C"` es compartida: `c-standards` fija el contrato ABI y la forma de la cabecera; **esta skill fija el lado C++**: envolver el recurso C en RAII en el mismo punto donde se adquiere (nunca dejar un `FILE*`/handle crudo circulando por código C++), `noexcept` en callbacks invocados desde C (una excepción que cruza una frontera C es UB), y prohibición de exponer tipos C++ (`std::string`, plantillas, excepciones) a través de la frontera. Ver también `rust-standards` (elección de lenguaje para **componentes nuevos** cuando la respuesta de memory safety es cambiar de lenguaje, y el lado Rust de la FFI: `cxx`, `bindgen`, `#[repr(C)]`), `bash-linux-scripting-standards` (scripts de build), `linux-hardening-standards` (hardening del **sistema**; el del **binario** es de esta skill), `appsec-standards` (modelado de amenazas y proceso), `vulnerability-management-standards` (triaje de CVEs y SLA de parcheo), `gpu-computing-standards` (CUDA/HIP, kernels, toolchain de GPU), `cicd-standards` (diseño de pipeline y gates; aquí solo la herramienta y sus flags), `offensive-security-standards` (explotación), `kubernetes-standards` (empaquetado OCI), `observability-standards` (pipeline OTel). Lenguajes vecinos: `zig-standards` y `nim-standards` (**ya escritas**; Nim puede emitir C++ con `nim cpp`: el Nim es suyo, **el C++ generado y sus flags caen aquí**), `assembly-standards` (**ya escrita**; el `asm` en línea dentro de una función C++ es frontera compartida), `objective-c-standards` (**ya escrita**, para Objective-C++ en plataformas Apple: **el C++ que contiene un `.mm` sigue sujeto a esta skill**).

## 2. Toolchain y decisiones por defecto

> **Verificar la última versión por web antes de fijarla en un proyecto real** (§8). Lo siguiente es el estado verificado a **ago-2026**.

| Decisión | Default | Alternativa justificable | Motivo |
|---|---|---|---|
| Estándar | **C++20** (`-std=c++20`) como base de producción; **C++23** (`-std=c++23`) si los tres compiladores del proyecto lo soportan de verdad | C++17 en bases con toolchain congelado o SDKs de vendor | GCC 16.1 (2026-04-30) **cambió el default del frontend C++ a GNU C++20** y dejó de marcar como experimentales las partes correspondientes de la biblioteca; la ABI de C++20 no fue estable hasta GCC 16 — dato decisivo si se mezclan binarios |
| C++26 | **No en producción todavía**; sí para prototipar features concretas con `-std=c++2c` | — | Trabajo técnico **completado el 28-29 de marzo de 2026** en la reunión de Londres (Croydon) y enviado a ballot DIS; GCC 16.1 soporta la mayoría de features. La disponibilidad real es desigual: p. ej. **contratos en GCC 16.1 solo emiten warnings**, y en MSVC están en roadmap |
| Compilador | **GCC 16.x** + **Clang/LLVM 22.x** (22.1.8, 2026-06-16; la serie 23 estaba en rc a jul-2026) en CI, ambos | MSVC cuando Windows es target de primera | Compilar con dos frontends distintos es el análisis estático más barato que existe |
| MSVC | **Build Tools 14.51** (compilador 19.51, VS 2026 v18.6, toolset v145) | 14.50 (VS 2026 v18.0) | **`/std:c++23` aún no es un switch final**: se usa `/std:c++23preview` (solo features ratificadas) o `/std:c++latest` (además, en curso/experimentales de C++26). El soporte pleno de `/std:c++23` llega cuando 14.52 sea el default no-preview. Servicing de 14.51: 9 meses. Compatibilidad binaria preservada desde VS 2015 |
| Build | **CMake ≥ 4.4** (4.4.2, 2026-07-31) con `CMakePresets.json` | Meson en proyectos Linux-céntricos; Bazel en monorepos que ya lo usan | CMake es el denominador común real del ecosistema C++ |
| Gestor de dependencias | Ver decisión razonada más abajo (**vcpkg** vs **Conan 2**) | `FetchContent`/subdirectorios solo en proyectos con ≤3 dependencias | |
| Tests | **GoogleTest 1.17.0** (BSD-3-Clause) si se necesita *mocking* (GMock) o el ecosistema Google; **Catch2 v3.15.x** (BSL-1.0, activo jul-2026) para tests expresivos sin dependencia pesada | **doctest v2.5.x** (MIT) cuando el tiempo de compilación de los tests manda (tests dentro del propio TU de producción) | Verificar mantenimiento: googletest **no publica release desde 1.17.0 (2025-04-30)** aunque el repo siga vivo (modelo *live at head*); Catch2 y doctest publicaron en jul-2026 |
| Benchmarks | **Google Benchmark 1.9.5** (Apache-2.0, 2026-01) | nanobench en proyectos pequeños | |
| Utilidades fuera de la stdlib | **Abseil** (Apache-2.0, LTS de mayo 2026) cuando ya se usa gRPC/protobuf | **Boost 1.91.0** (BSL-1.0) para lo que la stdlib no cubre (Asio si no se adopta `std::execution`, Beast, Spirit) | Regla dura: **la stdlib primero**; una dependencia solo entra si la stdlib no cubre el caso o su implementación disponible no lo hace |
| GSL | **microsoft/GSL 4.2.2** (MIT, 2026-05) solo si se adoptan las Core Guidelines con verificación | — | En C++20+ gran parte de la GSL está subsumida por `std::span`, `std::byte`, `<concepts>` y `[[nodiscard]]`: adoptar la GSL entera es hoy la excepción, no el default |

### vcpkg vs Conan 2 — decisión razonada
- **vcpkg** (Microsoft): registro plano con *baseline* de versiones, modo manifiesto (`vcpkg.json`) y toolchain file de CMake; catálogo mayor y más probabilidad de encontrar librerías oscuras. El sistema de **triplets** fuerza reconstrucciones cuando la configuración no coincide exactamente; caché binaria preferentemente sobre *feeds* NuGet (también caché local en disco). Releases con esquema por fecha (última verificada: `2026-07-29`).
- **Conan 2** (2.31.1, 2026-07-24): resolución de dependencias **por grafo** con rangos de versión y múltiples remotos, `conanfile.py`/`conanfile.txt`, `conan lock create` para lockfiles explícitos y **perfiles** que fijan compilador y settings — lo que reduce reconstrucciones innecesarias y hace la cross-compilación más manejable. Caché binaria pensada para Artifactory.
- **Criterio**: proyecto centrado en Windows/MSVC o que necesita librerías poco comunes → **vcpkg**. Proyecto multiplataforma, con cross-compilación o embebido, o que ya tiene Artifactory → **Conan 2**. **Un solo gestor por proyecto**, documentado; en ambos casos **versiones fijadas** (baseline + `vcpkg-configuration.json`, o lockfile de Conan) y consumo desde CMake vía `find_package`, de forma que el build no dependa del gestor concreto.
- **Conan 1 está fuera de discusión**: cualquier proyecto nuevo nace en Conan 2; una base en Conan 1 tiene la migración como deuda con fecha.

## 3. Estructura, propiedad y diseño

### CMake moderno — targets, no variables globales
- Todo se expresa como **propiedades de target**: `target_include_directories`, `target_compile_features`, `target_compile_options`, `target_link_libraries`, `target_compile_definitions`, con `PUBLIC`/`PRIVATE`/`INTERFACE` **siempre explícitos** (la usabilidad de la librería depende de eso). **Prohibidos** `include_directories`, `link_libraries`, `add_definitions`, y modificar `CMAKE_CXX_FLAGS` globalmente.
- `cmake_minimum_required(VERSION 3.28)` como suelo razonable (subirlo si se usan módulos o `import std`), targets con **namespace** (`add_library(px::core ALIAS px_core)`) para que el consumidor no distinga entre subdirectorio y paquete instalado.
- Estándar por target: `target_compile_features(px_core PUBLIC cxx_std_20)`; **prohibido** `set(CMAKE_CXX_STANDARD ...)` global como única fuente. `CXX_EXTENSIONS OFF`.
- `CMakePresets.json` versionado con presets de `debug`, `release`, `asan-ubsan`, `tsan`: la línea de compilación no se transmite por costumbre oral.
- Exportar paquete instalable (`install(TARGETS ... EXPORT)`, `*Config.cmake`, `write_basic_package_version_file`) en toda librería que otros consuman.
- **Prohibido** `file(GLOB)` para listar fuentes: rompe la reconstrucción incremental de forma silenciosa.

### Layout
- `include/<proyecto>/` cabeceras públicas, `src/` implementación y cabeceras internas, `tests/`, `bench/`, `cmake/`. Namespace del proyecto obligatorio; namespace anónimo para todo lo interno a un TU.
- **Prohibido** `using namespace` en cabeceras, en cualquier caso; en `.cpp`, solo local a función y con justificación (`using std::swap` para ADL sí).
- Cabeceras: `#pragma once`, includes mínimos (declaración adelantada donde baste), y `<...>` para dependencias externas / `"..."` para propias. IWYU (`include-what-you-use`) como comprobación periódica, no como gate obligatorio (es ruidoso).
- API pública mínima y estable: la implementación va en `src/` o en `detail::`; `detail` no es API y se documenta como tal.

### RAII y propiedad — el principio rector
- **Todo recurso tiene un dueño y su liberación está en un destructor.** Memoria, ficheros, sockets, locks, handles del SO, transacciones, temporizadores. Si un recurso de terceros no viene con clase RAII, se le escribe una envoltura antes de usarlo, no después.
- **La propiedad se expresa en el tipo de la firma**, y esto no es negociable:
  - `std::unique_ptr<T>` — propiedad exclusiva y transferible. Es el default.
  - `std::shared_ptr<T>` — propiedad **compartida de verdad**, con vida indeterminada en tiempo de compilación. Requiere justificación escrita: es contador atómico, es coste, y suele indicar un diseño de propiedad no resuelto.
  - `std::weak_ptr<T>` — romper ciclos de `shared_ptr`; su presencia obliga a documentar el ciclo.
  - `T&` / `const T&` / `T*` crudo / `std::span<T>` / `std::string_view` — **observación sin propiedad**, con vida garantizada por el llamante. Un puntero crudo en una firma significa "no soy dueño", nunca otra cosa.
- **Cuándo NO usar punteros inteligentes**: cuando el objeto es un valor (`std::string`, `std::vector`, un tipo propio con semántica de valor) — `unique_ptr<std::string>` es casi siempre un error de diseño; cuando el objeto es miembro por valor de su dueño; cuando es un observador (ahí van referencia, `span`, `string_view` o puntero crudo); cuando la vida es de ámbito de bloque; cuando es un objeto polimórfico almacenado en un contenedor de valores por `std::variant`. `shared_ptr` **nunca** como "puntero por defecto porque es cómodo".
- `std::make_unique`/`std::make_shared` en vez de `new` (`make_shared` combina la asignación; ojo si hay `weak_ptr` de larga vida sobre objetos grandes: mantiene el bloque vivo). **`new` y `delete` explícitos están prohibidos** fuera de la implementación de una envoltura RAII, de un allocador o de una arena, con comentario que lo justifique.
- Vidas: nunca devolver `string_view`/`span`/referencia a un temporal ni a un miembro de un objeto que muere; cuidado con `for (auto x : f().items())` cuando `f()` devuelve por valor (extensión de vida solo del temporal exterior — corregido en C++23 para range-for, verificar el estándar del target). `-Wdangling` y `clang-tidy bugprone-dangling-handle` activos.
- Los recursos compartidos entre hilos y su vida son un problema de diseño, no de `shared_ptr`: `shared_ptr` es *thread-safe* en el contador, **no** en el objeto apuntado.

### Semántica de movimiento y reglas de cero/tres/cinco
- **Regla de cero**: la mayoría de las clases no declaran destructor, copia ni movimiento — sus miembros son tipos que ya lo gestionan. Es el objetivo por defecto.
- Si se declara **uno** de {destructor, copia-ctor, copia-asignación, movimiento-ctor, movimiento-asignación}, se decide explícitamente sobre **los cinco** (`= default`/`= delete`/definición). Declarar un destructor **suprime** los movimientos generados y convierte movimientos silenciosamente en copias: es una regresión de rendimiento invisible.
- Movimiento-ctor y movimiento-asignación **`noexcept`** siempre que sea posible: sin `noexcept`, `std::vector` copia en vez de mover al realojar.
- Un objeto movido queda en estado **válido pero no especificado**: solo se le puede destruir o reasignar, salvo que la clase documente más. Nada de reutilizar un objeto movido "porque en esta implementación funciona".
- `std::move` sobre un `const` no mueve (copia en silencio); `std::move` en el `return` de una variable local **impide la NRVO** — no se pone. `std::forward` solo en referencias de reenvío.
- Parámetros: por valor + `std::move` cuando se va a almacenar (regla de sumidero); por `const&` cuando solo se lee; por `&&` solo en sobrecargas deliberadas. Evitar la proliferación de sobrecargas `const&`/`&&` sin medición.

### `const`-correctness y tipos
- `const` por defecto en variables locales, parámetros de solo lectura y métodos que no mutan estado observable. `constexpr`/`consteval` donde el valor se conoce en compilación. `mutable` solo para caché/mutex interno documentado.
- **`const` en un método es una promesa de *thread-safety* lógica** en la práctica del ecosistema estándar: si un método `const` muta estado interno, debe ser seguro invocarlo concurrentemente (mutex/atómico), o documentarse lo contrario.
- `[[nodiscard]]` en toda función cuyo retorno ignorar sea un bug (fábricas, funciones puras, tipos de error). `explicit` en constructores de un argumento y en operadores de conversión, salvo conversión deliberada.
- **Tipos fuertes** para IDs, unidades y flags: nada de tres `int` seguidos en una firma. `enum class` siempre (nunca `enum` sin ámbito). `std::optional` para ausencia, `std::variant` para alternativas, `std::span` para "puntero + longitud" (elimina la clase entera de errores de longitud desincronizada).
- **Sin arrays C** (`T v[N]`) en interfaces: `std::array` o `std::span`. Sin `char*` para texto: `std::string`/`std::string_view`. Sin `#define` para constantes o funciones: `constexpr`/`inline constexpr`/función.

### Plantillas, concepts y `constexpr`
- **Concepts en toda plantilla pública** (C++20): restringen la interfaz y convierten un muro de errores de instanciación en un diagnóstico legible. Plantilla sin restricción en API pública = defecto de diseño.
- SFINAE (`enable_if`, *tag dispatch*) queda para bases que aún no pueden usar concepts; en C++20+ es deuda a migrar.
- La metaprogramación se justifica por un requisito (rendimiento medido, eliminación de duplicación real, seguridad de tipos), nunca por elegancia. **Coste de compilación es coste operativo**: una plantilla que instancia mucho se mide (`-ftime-trace` en Clang) y se saca de la cabecera si domina.
- `constexpr` generoso (funciones puras, tablas, validación de literales); `consteval` cuando la evaluación en compilación es un requisito, no una opción; `static_assert` con mensaje para invariantes de tipo.
- Reflexión (C++26, disponible en GCC 16.1 y en la rama clang-p2996) resolverá muchos de los casos que hoy se hacen a mano — **no** se adopta en producción hasta que el soporte del toolchain del proyecto esté verificado.
- Preferir `if constexpr` a especialización cuando basta; `ranges` a bucles con iteradores crudos (C++20); algoritmos de la stdlib a bucles a mano.

### Módulos y `import std` — estado real, no promesa
Estado verificado a ago-2026, con más desinformación que hechos alrededor:
- **Compiladores**: `import std;` funciona en **GCC 15/16**, **Clang 21+** y **MSVC** (módulos desde toolset 14.34 / VS 17.4+). En GCC 16.1 hay un **gap de rendimiento** de módulos atribuido a que su formato BMI no está optimizado para cabeceras grandes, con mejora esperada en GCC 17+.
- **CMake**: `import std` sigue siendo **experimental** — requiere activar `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD` con un **GUID específico de la versión de CMake, que cambia entre releases** (un preset que funcionaba deja de funcionar al subir CMake). Solo con **generadores Ninja**; los generadores de Visual Studio no soportan construir BMIs para targets IMPORTED. Opt-in por target con la propiedad `CXX_MODULE_STD`, sobre targets con al menos C++23.
- **No soportado**: *header units* (`import <header>;`), y compilar BMIs desde targets IMPORTED.
- **Tooling/IDE es el eslabón débil**: clangd tiene soporte experimental (editar una interfaz de módulo **no** actualiza el BMI, y la versión de clangd debe coincidir exactamente con la de Clang); IntelliSense de VS sigue etiquetando módulos C++20 como experimental; extensiones de VS Code marcan `import std;` como error con GCC 15+.
- **Ecosistema**: casi ninguna librería distribuye definiciones de módulo (Boost tiene prototipo por-librería, con reducciones de tiempo de build reportadas en torno al 45 %).
- **Criterio**: **no** migrar una base existente a módulos en 2026. Aceptable en proyectos nuevos, internos, con toolchain fijado (Ninja + CMake reciente + un único compilador) y con el equipo consciente de que el IDE va a sufrir. Cabeceras precompiladas (`target_precompile_headers`) siguen siendo la mejora de tiempo de build con mejor relación coste/beneficio hoy.

### Corrutinas y concurrencia
- Corrutinas (C++20) **solo sobre una librería de tareas**, nunca a pelo: el estándar entrega el mecanismo del lenguaje sin tipos de tarea, planificador ni cancelación. Opciones: la librería del proyecto (Asio, cppcoro, folly, libunifex) o `std::execution` (sender/receiver, adoptado en C++26 — verificar soporte real antes de basar arquitectura en él).
- Trampas de corrutinas que se revisan siempre: capturar por referencia en un lambda-corrutina (la lambda muere antes que el frame), pasar parámetros por referencia a una corrutina (los parámetros se copian al frame, lo referenciado no), y falta de cancelación estructurada. La vida en código asíncrono es más difícil que en síncrono, no menos.
- Concurrencia general: `std::jthread` + `std::stop_token` en vez de `std::thread` (que en destrucción sin `join` llama a `terminate`); `std::scoped_lock` sobre múltiples mutex (evita deadlock por orden); `std::atomic` con orden de memoria **explícito y justificado** — `memory_order_relaxed` requiere argumento escrito.
- `volatile` **no** es sincronización. Data race = UB, y el gate es TSan.
- Estado global mutable prohibido; si es inevitable, `constinit`/`inline constexpr` o un singleton con `static` local (inicialización *thread-safe* garantizada) — sabiendo que el orden de destrucción entre TUs no está garantizado.

### Manejo de errores
- **Dos mecanismos, criterio explícito por proyecto y documentado**:
  - **Excepciones** para errores excepcionales que atraviesan capas. Requieren garantías documentadas (básica / fuerte / `noexcept`) y disciplina RAII total. `noexcept` en destructores, movimientos, `swap` y en toda función invocada desde C.
  - **`std::expected<T,E>`** (C++23) para errores esperados y locales (parseo, validación, I/O previsible), donde el llamante decide en el sitio. En C++20, `tl::expected` o un `Result` propio, con la migración planificada.
- Excepciones **desactivadas** (`-fno-exceptions`) es una decisión legítima en embebido, kernel o entornos con requisito de tiempo real acotado, pero es **una decisión de proyecto entera**: obliga a `expected`/códigos en todas partes y hace inutilizable parte de la stdlib. No se toma por módulo.
- **Prohibido**: códigos de error enteros crudos como estrategia general en C++ nuevo; `catch (...)` que traga sin registrar ni relanzar; excepciones para control de flujo esperado; lanzar desde un destructor; que una excepción escape de un `noexcept` (llama a `terminate`).
- Un tipo de error propio deriva de `std::exception` (o encapsula `std::error_code`) y transporta contexto suficiente para diagnosticar sin adivinar.

## 4. Calidad: análisis, testing y gates de CI

### Warnings (gate)
```
GCC/Clang: -Wall -Wextra -Wpedantic -Werror
  -Wshadow -Wconversion -Wsign-conversion -Wdouble-promotion
  -Wold-style-cast -Wcast-qual -Wuseless-cast
  -Wnon-virtual-dtor -Woverloaded-virtual
  -Wnull-dereference -Wimplicit-fallthrough -Wformat=2
  -Wextra-semi -Wmisleading-indentation -Wdangling
MSVC: /W4 /WX /permissive- /Zc:__cplusplus /Zc:preprocessor /EHsc
```
- `/permissive-` en MSVC es **obligatorio**: sin él, el compilador acepta código no conforme que no compila en ningún otro sitio. `/Zc:__cplusplus` porque sin él la macro miente.
- `-Wold-style-cast` es la línea que separa C++ de "C con clases": los casts en C++ son `static_cast`/`const_cast`/`reinterpret_cast`, y `reinterpret_cast` requiere justificación escrita.
- `-Wconversion`/`-Wsign-conversion` se introducen por módulo si el ruido en base existente lo impide; nunca se apagan globalmente.

### Formato y análisis estático
- `clang-format` con `.clang-format` versionado; `clang-format --dry-run --Werror` en CI. Reformateo masivo en commit aparte + `.git-blame-ignore-revs`.
- **`clang-tidy` es el gate central en C++**, con `.clang-tidy` versionado. Set de partida: `bugprone-*`, `cppcoreguidelines-*`, `modernize-*`, `performance-*`, `readability-*`, `concurrency-*`, `misc-*`, `clang-analyzer-*`. Checks que se activan explícitamente por su valor: `cppcoreguidelines-owning-memory`, `cppcoreguidelines-pro-type-reinterpret-cast`, `cppcoreguidelines-special-member-functions`, `modernize-use-nullptr`, `modernize-use-override`, `bugprone-use-after-move`, `bugprone-dangling-handle`, `performance-unnecessary-value-param`.
- Recortes razonables: `cppcoreguidelines-pro-bounds-*` es muy ruidoso en código con interoperabilidad C — se activa por módulo. `modernize-use-trailing-return-type` es estilo, se decide una vez.
- MSVC: `/analyze` (incluye análisis de vidas basado en las Core Guidelines) en el job de Windows.
- **`-fanalyzer` de GCC no cuenta como gate en C++**: su soporte C++ es incompleto y *best-effort* (RAII, smart pointers, excepciones y plantillas están mal cubiertos; los caminos a través de la biblioteca estándar son ruidosos). Es útil en el código C del árbol → `c-standards`.
- **CodeQL** (o equivalente) programado, para consultas de flujo de datos entre unidades de traducción.
- **C++ Core Guidelines** como referencia normativa del proyecto, aplicadas **por las comprobaciones automatizadas de clang-tidy y `/analyze`**, no por lectura. Advertencia de mantenimiento: el repositorio `isocpp/CppCoreGuidelines` es un documento vivo sin releases etiquetadas desde 2017 — se verifica su estado por actividad del repositorio, no buscando una versión.

### Sanitizers (builds separadas)
- **ASan + UBSan + LSan** en la build de tests por defecto: `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all -g -O1`.
- **TSan** en job separado (`-fsanitize=thread`): **incompatible con ASan** — los runtimes asumen mapas de memoria distintos y el compilador rechaza la combinación con un error. Implica PIE y exige instrumentar todo el código.
- **MSan** solo Clang/Linux y build aparte; exige instrumentar **todas** las dependencias, **incluida libc++** (`-stdlib=libc++` con libc++ instrumentada): si no se paga ese coste, no se usa, porque genera falsos positivos. Valgrind Memcheck es la alternativa practicable para memoria no inicializada sobre binarios ya construidos, a cambio de no ver desbordamientos en locales/globales ni use-after-return.
- Producción **nunca** con sanitizers.
- **Biblioteca estándar endurecida** — esta es la mitigación barata que se olvida:
  - libstdc++: `-D_GLIBCXX_ASSERTIONS` en release (ligero). `-D_GLIBCXX_DEBUG` es pesado y **rompe ABI**: solo en builds de depuración, con todo el árbol compilado igual.
  - libc++: `-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST` en producción; `_EXTENSIVE` y `_DEBUG` para tests.
  - MSVC: `_ITERATOR_DEBUG_LEVEL=1` para comprobaciones en release.
  - GCC ofrece además `-fhardened` como paraguas (incluye `_FORTIFY_SOURCE=3`): verificar qué activa exactamente en la versión usada antes de sustituir con él la lista explícita.

### Testing
- Framework según §2, un solo framework por proyecto. Tests como targets CMake registrados con `add_test`/`gtest_discover_tests`/`catch_discover_tests` y ejecutados con `ctest --output-on-failure`.
- Estructura AAA, un motivo de fallo por test, sin lógica en el test, sin estado global compartido entre tests.
- Cobertura obligatoria de **bordes y errores**: contenedores vacíos, límites de tipos, fallos de asignación, rutas de excepción (`EXPECT_THROW` y también la garantía de excepción: que el objeto quede consistente), `std::expected` en su rama de error, movidos-de, self-assignment, y **corrección `const`/thread** en los tipos que la prometan.
- **Mockear fronteras propias** (interfaces del proyecto), no la stdlib ni el sistema. Preferir inyección por plantilla o por interfaz según coste; GMock donde aporte.
- **Property testing** (RapidCheck) para invariantes algebraicas; **fuzzing** (libFuzzer/AFL++, corpus versionado, harness bajo ASan+UBSan) en **todo parser o deserializador de entrada no confiable** — obligatorio, y en OSS-Fuzz si el proyecto es abierto.
- Todo bug corregido deja test de regresión que falla antes del fix.
- Cobertura como señal, no como meta: `llvm-cov`/`gcovr` publicado, atención a las ramas de error.

### Gate mínimo de CI (todo rompe el build)
```
1. clang-format --dry-run --Werror
2. build GCC   (-Wall -Wextra -Wpedantic -Werror + set de §4)
3. build Clang (idem)
4. build MSVC  (/W4 /WX /permissive-)   [si Windows es target]
5. clang-tidy sobre compile_commands.json
6. ctest bajo ASan+UBSan (-fno-sanitize-recover=all)
7. ctest bajo TSan (job separado, si hay hilos)
8. fuzz corpus corto por harness
9. SCA de dependencias (vcpkg/Conan) + SBOM del artefacto
10. build release con hardening de §5 + verificación del binario (checksec)
11. [librerías con contrato ABI] abidiff contra la versión anterior
```

## 5. Seguridad del stack, hardening y memory safety

### Hardening del binario
Base alineada con la *OpenSSF Compiler Options Hardening Guide for C and C++* (documento vivo, reverificar antes de congelarlo):
```
-O2 -Wall -Wformat=2 -Werror=format-security -Wconversion -Wimplicit-fallthrough
-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
-D_GLIBCXX_ASSERTIONS            # o -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST
-fstrict-flex-arrays=3
-fstack-clash-protection -fstack-protector-strong
-fPIE -pie
-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,-z,nodlopen
-Wl,--as-needed -Wl,--no-copy-dt-needed-entries
```
Añadir con medición: `-ftrivial-auto-var-init=zero`, `-fcf-protection=full` (x86-64) / `-mbranch-protection=standard` (AArch64), y `-fsanitize=cfi` con LTO (Clang) para *forward-edge CFI* en jerarquías polimórficas — que en C++ es donde la confusión de tipos y los vtables corrompidos se convierten en ejecución de código. **Verificar el binario producido** (`checksec`, `readelf -d`), no confiar en que el flag llegó al link. Strip del release con símbolos archivados aparte (build-id) para simbolizar crashes.

### Dependencias y cadena de suministro
- Versiones **fijadas** (baseline vcpkg / lockfile Conan) y el fichero de bloqueo versionado. Actualización de dependencias como cambio revisado, no automático a ciegas.
- **SBOM** (SPDX/CycloneDX) generado en el build y publicado con el artefacto; SCA contra CVEs de lo embebido. El código vendorizado/`FetchContent` es exactamente donde se pierden los CVEs.
- Licencias verificadas en el `LICENSE` real del proyecto (verificado a ago-2026: GoogleTest BSD-3-Clause, Catch2 Boost Software License 1.0, doctest MIT, Google Benchmark Apache-2.0, Abseil Apache-2.0, microsoft/GSL MIT, Boost BSL-1.0), no en lo que diga un agregador — y **reverificar** antes de fijar un default: el catálogo tiene precedentes de cambio de licencia (Trivy) y de proyectos declarados *feature complete* con acción comercial (gitleaks v2).
- Toda dependencia nueva es una decisión de confianza y de coste de compilación, no un import gratis. Abseil impone el modelo *live at head* (LTS trimestrales si no se puede seguir HEAD); Boost impone peso de build. Ambos se justifican.

### Código
- Entrada externa validada en el borde, con tipos que la representen (`span`, `string_view`, tipos fuertes) y no con "el llamante ya lo comprobó".
- Índices y aritmética: `.at()` o comprobación explícita en las rutas con datos externos; `size_t` y `-Wsign-conversion` para no mezclar signos; `std::ssize` cuando la resta de tamaños pueda ir negativa.
- `reinterpret_cast` y *type punning*: `std::bit_cast` (C++20) es el mecanismo correcto; `reinterpret_cast` requiere comentario que justifique la validez y no vale como puente de aliasing.
- Secretos: nunca en código ni en logs; borrado con función que el optimizador no pueda eliminar (`explicit_bzero`, `SecureZeroMemory`, o `std::fill` sobre `volatile` — verificar la garantía en el compilador concreto); comparación en tiempo constante para material criptográfico.
- Cripto con librería auditada (libsodium, OpenSSL 3.x, BoringSSL, mbedTLS). Nada de cripto propia.
- SQL/comandos: siempre parametrizado / `argv` vectorizado; nunca concatenación de entrada.

### Memory safety en C++ — estado real y postura del proyecto
Verificado a ago-2026; es una decisión de estrategia técnica, no un tema de opinión:
- **Presión regulatoria**: la guía conjunta **CISA/FBI "Product Security Bad Practices"** (iniciativa *Secure by Design*) fija que, para productos existentes escritos en lenguajes memory-unsafe, no tener publicada una **hoja de ruta de memory safety antes del 1 de enero de 2026** *"is dangerous and significantly elevates risk to national security, national economic security, and national public health and safety"*. Es **guía voluntaria**, no norma con sanción: el riesgo es de responsabilidad y reputación, y hay exención para productos cuyo soporte acaba antes del 1 de enero de 2030. La NSA lista Rust, Java, C#, Go, Delphi/Object Pascal, Ruby, Python y Swift como memory-safe. **Consecuencia práctica**: un proyecto C++ con superficie de red o criptografía necesita una hoja de ruta escrita — priorizar componentes expuestos, y decidir por componente entre reescribir en lenguaje seguro, aislar, o endurecer.
- **Safe C++ (P3390)**: el subgrupo de seguridad votó **priorizar *profiles* sobre Safe C++**, y Sean Baxter declaró en junio de 2025 que no continúa el trabajo. Matiz importante: no fue un rechazo formal — según Erich Keane (co-chair de EWG) el voto de aliento fue ~20 de 45 a favor del papel de Baxter y ~30 de 45 a favor de trabajar en profiles, y Baxter sigue siendo bienvenido a estandarizar. El desacuerdo es de diseño: EWG adoptó principios de evolución que desaconsejan una anotación de función "segura" que solo pueda llamar a funciones seguras — el núcleo de la propuesta. **No contar con un subconjunto seguro estilo Rust dentro de C++ a medio plazo.**
- **Qué sí llegó en C++26**: **contratos** (`pre`/`post`, `contract_assert`, con semánticas de evaluación *ignore/observe/enforce*; la votación de finalización fue **no unánime**: 114 a favor, 12 en contra, 3 abstenciones, precisamente por los contratos), **biblioteca estándar endurecida** (P3471: convierte UB de la stdlib, como el acceso fuera de rango de `vector`, en violaciones de contrato cuando el *hardening* está activo — *"initial cross-platform library security guarantees, including bounds safety for dozens of the most widely used bounded operations on common standard types"*), **reflexión** (P2996) y **`std::execution`**.
- **Qué se aplazó a C++29**: el atributo **`[[profiles::enforce]]`** y el marco general de perfiles (P3081 de Sutter, P3589 de Dos Reis, P3984 de Stroustrup), que siguen en SG23 con destino C++29. El ciclo C++29 se adoptó como otro ciclo de tres años, con la seguridad de memoria como foco declarado.
- **Postura de proyecto que fija esta skill**: no esperar a los perfiles. Lo que **está disponible hoy** y por tanto es exigible: RAII y propiedad en el tipo (§3), biblioteca estándar endurecida activada en release (§4), sanitizers como gate, fuzzing de todo parser, hardening del binario y CFI, y **hoja de ruta escrita** para los componentes de mayor exposición. Contratos y perfiles se adoptan cuando el toolchain del proyecto los soporte de verdad — recordar que en GCC 16.1 los contratos **solo emiten warnings**.

## 6. Rendimiento y operabilidad

- **Medir antes de optimizar**: Google Benchmark para micro, `perf`/VTune para macro, `-ftime-trace` (Clang) para tiempo de compilación. Un cambio de rendimiento sin número antes/después no se mergea.
- Cuidado con los micro-benchmarks: `benchmark::DoNotOptimize`/`ClobberMemory` o el compilador borra el código medido; reportar dispersión, no una ejecución.
- El coste real está en asignaciones, indirecciones y fallos de caché, no en `virtual`: preferir contenedores contiguos (`vector` por defecto; `map`/`unordered_map` solo cuando el acceso lo justifique), `reserve()` cuando el tamaño se conoce, y evitar `shared_ptr` en bucles calientes.
- `-O2` default; `-O3` solo con benchmark. **`-march=native` prohibido en artefactos distribuibles**. LTO (`-flto=thin`) en release si el tiempo de build lo permite. `-ffast-math` prohibido en código que valide o compare flotantes.
- **Tiempo de compilación es coste operativo**: cabeceras precompiladas, `extern template` para plantillas caras, idioma pImpl donde la cabecera arrastre medio mundo, y evitar `#include` innecesarios en cabeceras públicas. Vigilar con `-ftime-trace` y con builds de CI cronometradas.
- **ABI**: cambiar el layout de un tipo público, añadir un miembro virtual, cambiar el orden de un `enum` o el `noexcept` de una función exportada rompe ABI aunque compile. Librerías con contrato ABI: pImpl, `-fvisibility=hidden` + macro de export, version script, `SONAME` versionado y **`abidiff` en CI**. Recordar que la **ABI de C++20 en libstdc++ no fue estable hasta GCC 16**.
- **Operabilidad**: logging estructurado con nivel configurable (`std::format`/fmt; **nada de `std::cout` de depuración** en producción); métricas y trazas por OpenTelemetry (pipeline → `observability-standards`); salida limpia ante SIGTERM con destrucción ordenada de recursos (`jthread` + `stop_token`); *crash handler* que vuelque diagnóstico simbolizable; `std::stacktrace` (C++23) donde el toolchain lo soporte.
- `assert` desaparece con `NDEBUG` y **no** es validación de entrada; para invariantes que deben mantenerse en release, comprobación explícita, o contratos cuando el toolchain los aplique de verdad.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia**: probar la siguiente major de GCC (anual, ~abril) y de LLVM (~semestral) en CI **antes** de que sea obligatoria; MSVC 14.51 tiene 9 meses de servicing, así que el salto se planifica, no se sufre. Estándar del lenguaje: revisar la subida a C++23 cuando los tres compiladores del proyecto lo cubran; C++26 entra por features concretas y verificadas, no en bloque. Deudas con fecha: SFINAE → concepts, `enable_if` → `requires`, macros → `constexpr`, `tl::expected` → `std::expected`, Conan 1 → Conan 2, `std::thread` → `std::jthread`.

**Deprecación**: `[[deprecated("usar X")]]` con ventana de al menos una versión mayor; en librerías con contrato ABI, `SONAME` nuevo cuando rompe. Documentar la política de estándar mínimo soportado como contrato con los consumidores.

**Deuda consciente**: todo atajo deja `// TODO(usuario): motivo — issue #N`; toda supresión de lint/sanitizer con motivo y fecha de revisión.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- ❌ **Escribir C en ficheros C++**: `malloc`/`free` en vez de RAII, arrays C en interfaces, `char*` para texto, `#define` para constantes o funciones, casts al estilo C, `printf` en vez de `std::format`/fmt, códigos de error enteros como estrategia general. Es defecto de diseño, no de estilo.
- ❌ `new`/`delete` explícitos fuera de la implementación de una envoltura RAII o un allocador; `delete` de un puntero no propietario; `new[]`/`delete[]` en vez de `std::vector`/`std::array`.
- ❌ `shared_ptr` como puntero por defecto; `unique_ptr` sobre tipos que ya son valores; punteros crudos con propiedad implícita en firmas.
- ❌ Declarar un destructor sin decidir sobre los cinco miembros especiales; movimientos sin `noexcept`; usar un objeto movido-de más allá de destruir/reasignar.
- ❌ `using namespace` en cabeceras (en cualquier caso); `using namespace std;` en producción; macros sin prefijo en cabeceras públicas.
- ❌ `reinterpret_cast` sin justificación escrita; `const_cast` para escribir sobre un objeto originalmente `const` (UB); type punning por cast de puntero en vez de `std::bit_cast`/`memcpy`.
- ❌ Devolver `string_view`/`span`/referencia a un temporal o a un objeto que muere antes; capturar por referencia en lambdas que sobreviven al ámbito (y muy especialmente en corrutinas).
- ❌ Excepciones para control de flujo esperado; `catch (...)` que traga en silencio; lanzar desde un destructor; dejar escapar una excepción de un `noexcept` o a través de una frontera `extern "C"`.
- ❌ `volatile` como sincronización; estado global mutable; `std::thread` sin `join`/`detach` gestionado (use `jthread`); `memory_order_relaxed` sin argumento escrito.
- ❌ Herencia para reutilizar implementación (composición); herencia pública sin destructor virtual o sin `final` cuando no es base; jerarquías profundas por elegancia; clases base sin `-Wnon-virtual-dtor` limpio.
- ❌ CMake con variables globales (`include_directories`, `CMAKE_CXX_FLAGS` sobrescrito, `link_libraries`, `add_definitions`), `file(GLOB)` de fuentes, y `CMAKE_CXX_STANDARD` global como única declaración de estándar.
- ❌ Dos gestores de dependencias en el mismo proyecto; dependencias sin versión fijada; Conan 1 en proyecto nuevo.
- ❌ `-Werror` desactivado en CI; MSVC sin `/permissive-`; `// NOLINT` sin lint concreto ni motivo; `#pragma warning(disable)` sin `push`/`pop`.
- ❌ Combinar ASan con TSan/MSan en la misma build (el compilador lo rechaza); desplegar producción con sanitizers; release sin biblioteca estándar endurecida en código que procese entrada externa.
- ❌ `-march=native` en artefactos distribuibles; `-O3` sin benchmark; `-ffast-math` con validación de flotantes.
- ❌ Parser de entrada no confiable sin harness de fuzzing.
- ❌ Migrar una base existente a módulos C++ en 2026 basándose en un artículo en vez de en el soporte verificado del toolchain y del IDE del equipo (§3).
- ❌ Adoptar la metaprogramación como fin: plantillas sin `concepts` en API pública, TMP donde bastan `if constexpr`, `ranges` o una función normal.
- ❌ **Incluir en esta skill o en el código que produce: exploits, ROP/JOP gadgets, bypasses concretos de mitigaciones, shellcode o payloads.** Esta skill es **defensiva**: describe clases de vulnerabilidad (use-after-free, confusión de tipos, corrupción de vtable, desbordamiento, doble liberación, *iterator invalidation*) **para prevenirlas**, nunca para explotarlas. Trabajo ofensivo → `offensive-security-standards`, con alcance y autorización por escrito.

## 8. Verificación web obligatoria

Antes de fijar versiones, flags o afirmar estado del ecosistema, **verificar por web** (nunca de memoria):
1. **Soporte por compilador de cada feature**: tabla de https://en.cppreference.com/w/cpp/compiler_support **contrastada** con las release notes oficiales — https://gcc.gnu.org/projects/cxx-status.html, https://clang.llvm.org/cxx_status.html, https://libcxx.llvm.org/Status/ y https://learn.microsoft.com/cpp/overview/visual-cpp-language-conformance. Lenguaje y **biblioteca** se verifican por separado: tener la feature del lenguaje no implica tener la de la stdlib.
2. **Módulos e `import std`**: doc de CMake `cmake-cxxmodules(7)` de la versión exacta usada (el GUID de `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD` **cambia entre releases**) y las release notes del compilador. Es el área con más desinformación: **no** aceptar afirmaciones de blogs sin contrastarlas con la doc de la versión concreta.
3. **Versiones y ciclo de vida**: GCC (https://gcc.gnu.org/develop.html, https://gcc.gnu.org/releases.html), LLVM (`https://github.com/llvm/llvm-project/releases.atom`), MSVC (blog del equipo C++ y la tabla de conformidad; comprobar qué toolset es el default no-preview y su ventana de servicing).
4. **Gestores de dependencias**: releases de vcpkg (esquema por fecha) y de Conan 2 vía sus feeds Atom; cambios en el modelo de caché binaria y en los registros.
5. **Estado de mantenimiento y licencia** de toda librería antes de fijarla como default: feed `/releases.atom` + `LICENSE` en crudo desde `raw.githubusercontent.com`. Precedentes del catálogo: Trivy cambió de licencia; gitleaks se declaró *feature complete* y su acción exige licencia comercial para organizaciones desde v2. Atención específica a **googletest** (sin release etiquetada desde 1.17.0, 2025-04-30, modelo *live at head*) y a **C++ Core Guidelines** (sin releases desde 2017; es documento vivo — medir por actividad del repo).
6. **Memory safety**: actas y *trip reports* del comité (isocpp.org, herbsutter.com) para el estado de perfiles con destino C++29, y CISA/NSA/ONCD para la evolución de la exigencia regulatoria. Es un área que se mueve por reunión y por administración.
7. **OpenSSF Compiler Options Hardening Guide** (documento vivo): https://best.openssf.org/Compiler-Hardening-Guides/ — releer antes de congelar flags.

**Huecos declarados (no verificados a ago-2026, verificar antes de usar como norma)**:
- Fecha efectiva de **publicación ISO de C++26** (el trabajo técnico se completó en marzo de 2026 y pasó a ballot DIS; la publicación se esperaba "más adelante en 2026"): **no verificada**.
- **Fechas de EOL formales** de GCC 14/15/16 y de las ramas de LLVM: **no verificadas** (GCC no publica tabla de EOL).
- Fecha en que **MSVC 14.52** pasa a ser el default no-preview y con ello `/std:c++23` pleno: **no verificada**.
- Soporte por versión concreta de `-ftrivial-auto-var-init=zero`, `-fsanitize=cfi`, `-fhardened` y `std::stacktrace` en el toolchain del proyecto: **no verificado por versión**.
- Licencia **verbatim** de Conan y de vcpkg, y estado de licencia de Boost por librería individual: **no verificadas verbatim** (sí verificadas verbatim: GSL → *"This code is licensed under the MIT License (MIT)"*; Catch2 → *"Boost Software License - Version 1.0 - August 17th, 2003"*; doctest → *"The MIT License (MIT)"*; Abseil → *"Apache License Version 2.0"*).
- Estado de **`std::execution`** en implementaciones reales de la stdlib (no solo en el frontend del compilador): **no verificado**.
- Cobertura de C++26 por biblioteca estándar (libstdc++ / libc++ / STL de MSVC) más allá del titular "GCC 16.1 soporta la mayoría de features de C++26": **no verificada por feature**.

**Discrepancia declarada**: sobre la finalización de C++26, las fuentes consultadas dan **28 de marzo de 2026** y **29 de marzo de 2026** como fecha del cierre del trabajo técnico en la reunión de Londres/Croydon; el *trip report* de Herb Sutter dice literalmente *"On Saturday, the ISO C++ committee completed technical work on C++26"* sin fijar día en la frase. No se elige una: si la fecha exacta importa, verificar en las actas oficiales del comité.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
