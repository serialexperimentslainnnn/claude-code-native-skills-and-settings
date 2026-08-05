---
name: c-standards
description: C language engineering standards (staff-level). Trigger on .c files and C-only headers, -std=c11/c17/c23/gnu23, gcc/clang C invocations, Makefile/CMakeLists.txt/meson.build building C targets, compile_commands.json, .clang-tidy, .clang-format, cppcheck, -fanalyzer, -fsanitize=address/undefined/memory/thread, valgrind/memcheck, libFuzzer/AFL++/OSS-Fuzz harnesses, MISRA C or CERT C compliance, Unity/CMocka/Criterion tests, glibc/musl/newlib targets, _FORTIFY_SOURCE and binary hardening flags, or extern "C" ABI headers.
---

# Estándares C

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo en C: ficheros `.c` y cabeceras C, selección de `-std=`, flags de compilador y linker, `Makefile`/`CMakeLists.txt`/`meson.build` de targets C, `compile_commands.json`, configuración de sanitizers, análisis estático (`-fanalyzer`, clang-tidy, cppcheck), fuzzing, conformidad MISRA C / CERT C, tests unitarios y hardening del binario producido. Cubre firmware/embebido, drivers de espacio de usuario, librerías de sistema, CLIs y código de alto rendimiento. Fija **criterio**: qué se usa, qué está vetado y qué hay que verificar. No es un tutorial de C.

**Eje central de esta skill**: en C el compilador no gestiona recursos ni comprueba límites, así que **el ciclo de vida de cada recurso y el undefined behavior son requisitos de diseño**, no detalles de implementación. Todo lo demás (build, tests, CI) existe para hacer verificable esa disciplina.

**No aplica**: ver `cpp-standards` (todo lo que decida sobre C++: RAII, plantillas, la biblioteca estándar de C++, `new`/`delete`, excepciones, CMake orientado a targets C++ y el debate de memory safety del comité ISO C++ — aquí **nada** de C++). **Criterio de arbitraje** para código que compila en ambos: manda el **estándar bajo el que se compila el target** (`-std=c23` → esta skill; `-std=c++23` → `cpp-standards`), **no** la extensión del fichero ni el estilo del código; una cabecera consumida desde ambos mundos se diseña bajo `c-standards` (subconjunto C, sin construcciones solo-C++) y su envoltorio `extern "C"` es frontera compartida: la garantía ABI la fija esta skill, el consumo desde C++ lo fija `cpp-standards`. Ver también `rust-standards` (elección de lenguaje para **código de sistemas nuevo** — C no es el default por inercia — y el lado Rust de la FFI: `bindgen`/`cbindgen`, `#[repr(C)]`, `unsafe`), `bash-linux-scripting-standards` (scripts de build, wrappers y automatización por shell), `linux-hardening-standards` (hardening del **sistema**: kernel, sysctl, MAC, systemd; el hardening del **binario** — RELRO, PIE, stack protector, CFI — es de esta skill), `appsec-standards` (modelado de amenazas y proceso de AppSec), `vulnerability-management-standards` (triaje de CVEs, SLA de parcheo, VEX), `gpu-computing-standards` (CUDA/HIP, kernels y toolchain de GPU), `cicd-standards` (diseño de la pipeline y gates; aquí solo qué herramienta se ejecuta y con qué flags), `offensive-security-standards` (explotación), `kubernetes-standards` (imagen OCI del binario), `linux-storage-standards` y `observability-standards` para lo que corresponda. Lenguajes vecinos: `zig-standards` (**ya escrita**) para la alternativa moderna a C — **y para el caso especial de `zig cc`: usar Zig como toolchain de compilación cruzada es decisión suya, pero el C que compila sigue sujeto a esta skill**—, `nim-standards` (**ya escrita**: Nim **genera C** y lo compila con un compilador C; el Nim es suyo, **el C generado y los flags con que se compila caen aquí**), `lua-standards` (**ya escrita**: la **API C de Lua** —pila, `lua_State`, `luaL_*`, ciclo de vida de los valores frente al recolector— es frontera compartida; el C de la extensión nativa y su corrección son de esta skill, el contrato con el intérprete es suyo), `assembly-standards` (**ya escrita**) para ensamblador en línea e intrínsecos — **el `asm` dentro de una función C es frontera compartida**: la restricción del compilador y la corrección del `asm` son suyas, el resto de la función es de aquí—, `objective-c-standards` (**ya escrita**: Objective-C es superconjunto de C, así que **el C que contiene un `.m` sigue sujeto a esta skill**; lo específico del runtime de Objective-C es suyo).

## 2. Toolchain por defecto

> **Verificar la última versión por web antes de fijarla en un proyecto real** (§8). Lo siguiente es el estado verificado a **ago-2026**.

| Decisión | Default | Alternativa justificable | Motivo |
|---|---|---|---|
| Estándar | **C17** (`-std=gnu17`) para código portable en producción; **C23** (`-std=gnu23`) si el toolchain mínimo del proyecto es GCC ≥ 15 / Clang ≥ 18 y no hay compiladores de vendor de por medio | C11 en bases legacy o toolchains de vendor congelados | GCC declara *"GCC has support for ISO C23, the 2023 revision of the ISO C standard (published in 2024)"* y *"C23 mode is the default since GCC 15"*; Clang acepta `-std=c23` desde Clang 18 pero su soporte de C23 es **parcial por papeles** (ver `clang.llvm.org/c_status.html`). C99 es el mínimo absoluto: **prohibido** C89/K&R en código nuevo |
| Compilador | **GCC 16.x** (16.1, 2026-04-30) o **Clang/LLVM 22.x** (22.1.8, 2026-06-16) | Toolchain de vendor cuando el silicio lo impone | Compilar **con ambos** en CI: cada uno diagnostica lo que el otro calla |
| Build | **CMake ≥ 4.4** para librerías/proyectos que otros consumen; **Meson ≥ 1.11** cuando el proyecto es Linux-céntrico y se prioriza legibilidad | Make solo en proyectos de un binario y sin dependencias externas | Make a mano no escala a cross-compilación, sanitizer builds y `compile_commands.json` |
| Análisis estático | `clang-tidy` (mismo release que el Clang usado) + `gcc -fanalyzer` | `cppcheck` 2.21.x (GPL-3.0) como tercera opinión | `-fanalyzer` es el más maduro **para C**: en C++ es *best-effort*; en C es utilizable como gate |
| Tests | **Unity** 2.7.0 (MIT, 2026-07) en embebido y código sin libc completa; **Criterion** 2.4.3 (2025-10) en Linux/POSIX cuando se quiere aislamiento por proceso | CMocka 2.0.x cuando ya se usa (mocking por *link-time wrapping*) | Verificar mantenimiento antes de fijar: el **mirror de CMocka en GitHub está congelado en 1.1.5 (2019/2022)**; la fuente autoritativa es `cmocka.org` / el git de cryptomilk, que anuncia la serie 2.0 |
| Fuzzing | **libFuzzer** para harness in-process rápido + **AFL++** 5.02c (2026-06) para campañas largas | Honggfuzz | libFuzzer está **deprecado en el upstream de LLVM** en el sentido de que no recibe features nuevas: verificar su estado en las release notes de la versión concreta antes de basar un programa entero en él |
| Memoria dinámica | `malloc` de la libc del target | Allocador propio / arenas solo con justificación medida | Un allocador propio traslada la carga de la prueba: exige ASan+fuzzing propio |

Reglas de toolchain:
- **Nada de flags de compilador implícitos**: la línea de compilación completa vive en el build system y está versionada. `CFLAGS` inyectados por el entorno se **añaden**, no sustituyen.
- `compile_commands.json` generado siempre (`CMAKE_EXPORT_COMPILE_COMMANDS=ON` / Meson lo genera solo). Sin él no hay clang-tidy ni clangd ni análisis reproducible.
- Cross-compilación mediante *toolchain file* (CMake) o *cross file* (Meson) versionado — **prohibido** detectar el cross-compiler con condicionales ad-hoc.
- Warning set mínimo, y **es un gate**:

```
-std=gnu17 -Wall -Wextra -Werror
-Wshadow -Wconversion -Wsign-conversion -Wdouble-promotion
-Wformat=2 -Werror=format-security
-Wcast-qual -Wcast-align -Wpointer-arith -Wwrite-strings
-Wstrict-prototypes -Wold-style-definition -Wmissing-prototypes -Wmissing-declarations
-Wvla -Walloca -Wstack-protector
-Wnull-dereference -Wimplicit-fallthrough
-Werror=implicit-function-declaration -Werror=incompatible-pointer-types -Werror=int-conversion
```
- Los cuatro `-Werror=` de la última línea son **innegociables**: en C17 y anteriores esas tres construcciones son diagnósticos que muchos compiladores aceptaban con warning y son fuente directa de corrupción de memoria. C23 las convierte en errores del lenguaje; forzarlas antes evita la sorpresa al migrar.
- `-Wconversion`/`-Wsign-conversion` son ruidosos en código existente: se activan **por módulo nuevo** y se van extendiendo; nunca se apagan globalmente para "arreglar el build".
- `-Werror` **en CI siempre**; en el build local del desarrollador puede quedar como warning para no romper el flujo, pero el merge exige el build de CI.

## 3. Estructura, convenciones y ciclo de vida de los recursos

### Layout
- `src/` implementación, `include/<proyecto>/` cabeceras públicas (siempre con directorio de proyecto: los `#include` del consumidor son `<proyecto/foo.h>`), `tests/`, `fuzz/`, `cmake/` o `meson/`.
- **Una cabecera pública = un contrato**. Todo lo demás es `static` o vive en cabeceras internas fuera de `include/`. Visibilidad reforzada en el linker: `-fvisibility=hidden` + macro de export explícita en librerías compartidas.
- Include guards `#pragma once` si todos los compiladores del proyecto lo soportan; si hay toolchain de vendor dudoso, guards clásicos con nombre único `PROYECTO_MODULO_H`.
- Prefijo de proyecto **obligatorio** en todo símbolo con enlace externo (`px_buffer_new`): C no tiene namespaces y el linker resuelve colisiones en silencio con resultados absurdos.
- Cabeceras públicas: solo tipos y funciones, cero `#include` innecesarios (declaración adelantada donde baste), cero macros sin prefijo, y `extern "C"` guardado por `#ifdef __cplusplus` en toda cabecera que un consumidor C++ pueda incluir.

### Ciclo de vida de recursos — el eje del lenguaje
- **Regla de propiedad explícita**: cada puntero que cruza una frontera de API tiene documentado en la cabecera quién libera y con qué función. Sin esa línea, la API está incompleta.
- **Constructor/destructor emparejados por tipo**: `T *t_new(...)` / `void t_free(T *)`, y `t_free(NULL)` es *no-op* (como `free`). Prohibido repartir la liberación en el llamante campo a campo.
- **Un único punto de salida para la limpieza** en funciones con varias adquisiciones: patrón `goto fail_*` en cascada inversa. Es el idioma correcto en C, no un *goto* prohibido — MISRA C:2025 **desaplica** la regla de punto único de salida, pero el criterio de proyecto sigue siendo: limpieza centralizada y en orden inverso.
- Tras liberar, **el puntero se anula** en la estructura dueña (`p = NULL`) si su vida continúa: el use-after-free se convierte en null-deref, que es un fallo determinista.
- **Ownership no compartida por defecto**. Si hace falta compartir, refcount explícito con documentación de la política y test de concurrencia; nunca "se libera cuando toque".
- `alloca` y VLAs: **prohibidos** (`-Walloca -Wvla`). El tamaño de pila es un recurso finito y no comprobable; una VLA con tamaño derivado de input es un desbordamiento de pila remoto.
- Buffers de tamaño derivado de entrada: comprobar el cálculo **antes** de multiplicar (`__builtin_mul_overflow` / `ckd_mul` de `<stdckdint.h>` en C23), no después.
- Cierre de descriptores y `FILE*`: mismo patrón que la memoria; comprobar el retorno de `fclose`/`close` cuando hubo escritura (los errores de I/O aparecen ahí, no en `write`).

### Undefined behavior como bug de primera clase
Un UB no es "algo que suele funcionar": el optimizador **asume que no ocurre** y borra el código que lo comprueba. Se trata como defecto de severidad alta aunque el binario actual funcione.
- Categorías que se revisan en todo code review: acceso fuera de límites, use-after-free/double-free, lectura de memoria no inicializada, overflow de entero **con signo**, desplazamiento ≥ ancho del tipo o con operando negativo, violación de *strict aliasing*, punteros desalineados, `memcpy` con punteros solapados (`memmove` es lo que corresponde), aritmética de punteros fuera del objeto (incluido `ptr + n` más allá de "uno pasado el final"), comparación de punteros a objetos distintos, división por cero, `NULL` pasado a funciones de `<string.h>` incluso con longitud 0, y *data races*.
- Los aritméticos se cazan en runtime con UBSan; los de aliasing, no: si el proyecto hace *type punning*, se hace con `memcpy` o con union, **nunca** con cast de puntero, o se compila con `-fno-strict-aliasing` **declarado y justificado en el build** (opción legítima, pero es una decisión de proyecto, no un parche silencioso).
- `-fwrapv` / `-fno-strict-overflow` como red de seguridad en bases heredadas: aceptable y explícito, pero no sustituye a corregir el overflow; y no es portable a compiladores de vendor.

### Enteros
- `size_t` para tamaños e índices; **nunca** `int` para longitudes. Tipos de ancho fijo (`<stdint.h>`) para formatos binarios, protocolos y registros de hardware; `int`/`long` solo para aritmética local.
- Las **promociones y conversiones implícitas** son el bug más frecuente del lenguaje: `-Wconversion -Wsign-conversion` activados y cero casts "para callar el warning". Un cast es una afirmación de que el rango está comprobado; si no lo está, es un bug con maquillaje.
- Comparar `signed` con `unsigned` está vetado (`-Wsign-compare` viene en `-Wextra`); en C23 hay `<stdckdint.h>` (`ckd_add`/`ckd_sub`/`ckd_mul`) — verificar disponibilidad real en la libc del target antes de depender de ella; en C17, `__builtin_*_overflow` de GCC/Clang.
- Overflow de entero **con signo es UB**; el de sin signo está definido pero suele ser igual de bug (truncamiento de tamaños). Ambos se comprueban.
- `char` sin `signed`/`unsigned` explícito tiene signo *implementation-defined*: para bytes, `uint8_t` o `unsigned char`.

### Funciones prohibidas y sustituto real
| ❌ Prohibida | Sustituto | Nota |
|---|---|---|
| `gets` | `fgets` + comprobar el `\n` | Eliminada del lenguaje desde C11 |
| `strcpy`, `strcat` | Longitud comprobada explícita: medir y `memcpy`; `snprintf` para composición | `strncpy` **no** es el sustituto: no garantiza terminación |
| `strncpy` | `snprintf`, o `memcpy` con terminación manual | Rellena de ceros y trunca sin avisar |
| `sprintf`, `vsprintf` | `snprintf`/`vsnprintf` **comprobando el retorno** (`>= size` es truncamiento, y truncar suele ser un bug lógico) | |
| `atoi`, `atol`, `atof` | `strtol`/`strtoll`/`strtod` con `errno` a 0 antes y `endptr` comprobado | `atoi` no distingue error de cero: UB en overflow |
| `alloca`, VLA | `malloc` + límite, o buffer fijo dimensionado | |
| `rand`, `random` | CSPRNG del SO (`getrandom`, `arc4random_buf`, `BCryptGenRandom`) para cualquier uso de seguridad | |
| `system`, `popen` con string compuesta | `posix_spawn`/`fork`+`execve` con `argv` vectorizado | Concatenar input en un comando es inyección |
| `strtok` | `strtok_r`/`strsep` | Estado global: no reentrante |
| `gmtime`, `localtime`, `ctime`, `asctime` | Variantes `_r` | Buffer estático compartido |
| `memcpy` sobre regiones solapadas | `memmove` | UB aunque "funcione" |
| `scanf("%s")` | `fgets` + parseo, o `%<n>s` con anchura | |
| Anexo K (`strcpy_s`, `_s`) | No adoptarlo como estrategia | Soporte real casi inexistente fuera de MSVC y cuestionado por WG14: **no** es la solución portable |

Refuerzo mecánico: lista de símbolos vetados en clang-tidy (`bugprone-unsafe-functions`, `cert-*`) y, en proyectos de alta exigencia, `--defsym`/wrap o un check de linker sobre el símbolo importado.

### Concurrencia
- Un modelo de hilos por proyecto: `pthreads` en POSIX o los hilos de C11 (`<threads.h>`) si el toolchain los tiene de verdad (verificar: glibc los expone desde 2.28; algunas libcs no). **No mezclar**.
- Toda variable compartida está protegida por un mutex o es `_Atomic` con orden de memoria **explícito y justificado**; `volatile` **no** es una primitiva de concurrencia (sirve para MMIO y `sig_atomic_t`, nada más).
- Orden de adquisición de locks documentado y global; nada de locks anidados sin jerarquía.
- Manejadores de señal: solo funciones *async-signal-safe* y `volatile sig_atomic_t`; el patrón correcto es escribir en un pipe/eventfd (*self-pipe*) y procesar en el bucle principal.
- Data race = UB. TSan es el gate.

## 4. Calidad: formato, análisis, tests y gates de CI

### Formato
- `clang-format` con `.clang-format` versionado (base LLVM o GNU, ajustada una vez y no se rediscute). `clang-format --dry-run --Werror` en CI.
- **Prohibido** reformatear masivamente junto a cambios funcionales: el commit de formato va aparte y se registra en `.git-blame-ignore-revs`.

### Análisis estático (en orden de coste creciente)
1. Warnings del compilador con `-Werror` (ya cubierto, coste cero).
2. `gcc -fanalyzer` sobre el árbol C: caza doble free, use-after-free, leaks, deref de NULL y usos de descriptores. Ruidoso en macros; se tría, no se apaga. *(Estado verificado: su soporte para C++ es incompleto/best-effort — irrelevante aquí, es la skill de C.)*
3. `clang-tidy` con `.clang-tidy` versionado. Set de partida: `bugprone-*`, `cert-*`, `clang-analyzer-*`, `misc-*`, `performance-*`, `portability-*`, `readability-*` (recortando los de estilo que choquen con clang-format), y `-checks=-readability-magic-numbers` solo si el proyecto tiene una política de constantes propia. `WarningsAsErrors` para la parte estabilizada.
4. `cppcheck --enable=warning,style,performance,portability --error-exitcode=1` con supresiones versionadas (`suppressions.txt`) — tercera opinión, distinta familia de heurísticas. Verificar la licencia vigente antes de fijarlo como default corporativo (a ago-2026 el proyecto abierto es GPL-3.0 y existe además una edición comercial *Premium*: son productos distintos).
5. **CodeQL** en el repo (o el equivalente del proveedor) para consultas de flujo de datos entre unidades de traducción, programado además de en PR.

Ningún `// NOLINT` sin lint concreto y motivo; ningún `#pragma GCC diagnostic ignored` sin `push`/`pop` y comentario.

### Sanitizers (builds separados, nunca uno solo "con todo")
- **ASan + UBSan + LSan** en la misma build: `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all -g -O1`. LSan viene con ASan en Linux. Este es el build de tests por defecto en CI.
- **TSan** en build **separada**: `-fsanitize=thread`. **Incompatible con ASan**: los runtimes asumen mapas de memoria distintos y el compilador emite un error duro al combinarlos. Implica PIE y exige instrumentar todo el código.
- **MSan** en build **separada** y solo Clang/Linux (`-fsanitize=memory -fPIE -pie -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1`). Exige que **todas** las dependencias, incluida la libc++/libc según el caso, estén instrumentadas: sin eso genera falsos positivos. Si ese coste no es asumible, la cobertura de lectura de memoria no inicializada se cubre con **Valgrind Memcheck**, que sigue siendo la vía practicable en ese hueco.
- `-fno-sanitize-recover=all` obligatorio: un hallazgo debe **abortar** el test, no imprimir y seguir. `UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1`, `ASAN_OPTIONS=detect_stack_use_after_return=1:strict_string_checks=1:detect_leaks=1`.
- **Valgrind sigue teniendo sitio**, y por razones concretas, no por nostalgia: funciona sobre binarios **ya compilados** (código de terceros, blobs, artefactos ya publicados) y cubre memoria no inicializada sin recompilar el mundo. A cambio no ve desbordamientos en variables locales ni globales ni el *use-after-return*, y su coste es de un orden de magnitud sobre ASan. Criterio: ASan+UBSan en cada PR, TSan en job aparte, Valgrind en ejecución periódica o para triar un binario que no se puede recompilar.
- Producción **nunca** se despliega con sanitizers activos (son herramientas de depuración y amplían la superficie: `ASAN_OPTIONS` es leído del entorno).

### Fuzzing
- **Todo parser, decoder, deserializador o punto de entrada de datos no confiables tiene harness de fuzzing**. No es opcional: es donde aparecen los bugs que el fuzzer encuentra en minutos y la revisión humana no ve en años.
- Harness `LLVMFuzzerTestOneInput` (compatible libFuzzer y AFL++ vía `afl-clang-lto`), compilado con ASan+UBSan, corpus **versionado** y minimizado (`-merge=1`), diccionario cuando el formato lo tenga.
- CI: ejecución corta (60–300 s) del corpus en cada PR como test de regresión; campaña larga programada (nocturna/semanal) con AFL++.
- Proyecto open source relevante: integrarlo en **OSS-Fuzz** (Google, activo — commits diarios a ago-2026). Todo *crash* reportado por el fuzzer entra como bug con test de regresión en el corpus.
- El binario fuzzeado **no** es el binario de release: builds distintas.

### Testing
- Framework según §2; cada test es un caso aislado, sin estado global compartido, y el runner reporta en formato consumible por CI (TAP/JUnit).
- Cobertura obligatoria de **bordes y errores**, no del camino feliz: longitud 0, longitud máxima, `NULL`, valores límite de cada tipo entero, fallo de `malloc` (inyección de fallo por wrapper o `LD_PRELOAD`), truncamiento, entrada no terminada.
- **Todo bug corregido deja test de regresión** que falla antes del fix; si vino de un fuzzer, además entra en el corpus.
- Cobertura como señal: `--coverage`/`llvm-cov` publicado, con foco en ramas de error. Un porcentaje no es un objetivo.
- Tests deterministas: nada de dependencia de timing, orden de hash o de red. Un test flaky se arregla o se borra.

### Gate mínimo de CI (todo rompe el build)
```
1. clang-format --dry-run --Werror
2. build GCC   -Wall -Wextra -Werror (+ set de §2)
3. build Clang -Wall -Wextra -Werror (+ set de §2)
4. clang-tidy sobre compile_commands.json (diff o árbol completo)
5. gcc -fanalyzer
6. tests bajo ASan+UBSan (-fno-sanitize-recover=all)
7. tests bajo TSan (job separado, si hay hilos)
8. fuzz corpus corto sobre cada harness
9. SCA de dependencias + SBOM del artefacto
10. build release limpia con los flags de hardening de §5 y verificación del binario
```
Main siempre verde. No se mergea con CI roja.

## 5. Seguridad del stack y hardening del binario

### Flags de hardening (build de release)
Base alineada con la *OpenSSF Compiler Options Hardening Guide for C and C++* (documento vivo: reverificar antes de congelarlo en un proyecto):

```
-O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough
-Werror=format-security
-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
-fstrict-flex-arrays=3
-fstack-clash-protection -fstack-protector-strong
-fPIE -pie
-Wl,-z,relro -Wl,-z,now
-Wl,-z,noexecstack -Wl,-z,nodlopen
-Wl,--as-needed -Wl,--no-copy-dt-needed-entries
```
- `-U_FORTIFY_SOURCE` antes de `-D_FORTIFY_SOURCE=3` **importa**: muchas distros ya lo definen y redefinirlo sin anular avisa o se ignora. `_FORTIFY_SOURCE` exige `-O1` o superior y depende de la libc (glibc lo implementa; en musl es esencialmente inoperante — **verificar en el target real**, no asumirlo).
- **Añadir además** (con medición de impacto):
  - `-ftrivial-auto-var-init=zero`: elimina la clase entera de "lectura de local no inicializada" en producción. Coste bajo; verificar soporte en la versión concreta de GCC/Clang del proyecto.
  - `-fcf-protection=full` (x86-64) y `-mbranch-protection=standard` (AArch64) para CFI de hardware.
  - `-fsanitize=cfi` con LTO (Clang) o `-fsanitize=undefined -fsanitize-minimal-runtime -fsanitize-trap=undefined` como UBSan de coste mínimo **en producción** para convertir UB detectable en *trap* determinista — decisión de proyecto, medir antes.
  - `-fno-delete-null-pointer-checks` y `-fno-strict-aliasing` en bases heredadas cuya corrección no se puede auditar completa (declarado y justificado).
- **Verificar el binario producido**, no confiar en los flags: `checksec`, `hardening-check` o `readelf -d` en CI, comprobando PIE, RELRO completo, NX, stack canary y ausencia de `RPATH`/`RUNPATH` inseguros. Que el flag esté en `CFLAGS` no significa que llegara al link.
- Strip de símbolos en el artefacto de release, con **build-id y símbolos de depuración archivados aparte** (`objcopy --only-keep-debug`) para poder simbolizar crashes.

### Cadena de suministro y dependencias
- **Cada dependencia C es código que ejecutará con los privilegios del proceso**: se justifica por escrito. Preferir la libc y lo ya presente antes que añadir una librería para una utilidad.
- Dependencias por *pin* exacto (tag + hash), nunca `master`. Vendorizar (submódulo/subproject con revisión fijada) es aceptable y a menudo preferible a un gestor de paquetes en C; lo que no es aceptable es copiar código sin registro de origen, versión y licencia.
- **SBOM** (SPDX o CycloneDX) generado en el build y publicado con el artefacto; SCA contra CVEs de las librerías embebidas. El código vendorizado es exactamente donde se pierden los CVEs.
- Licencias verificadas en el `LICENSE` real del proyecto, no en lo que diga un agregador.

### Código
- **Toda entrada externa se valida en el borde** (longitud, rango, terminación, codificación) antes de tocar el resto del programa. Un parser de formato binario asume input hostil siempre.
- Comprobar **todos** los retornos: `malloc`, `realloc` (nunca `p = realloc(p, n)` — se pierde el puntero original si falla), `snprintf`, `read`/`write` (parciales), `fclose`. Ignorar un retorno es una decisión que se marca (`(void)` + comentario), no un descuido.
- Secretos: nunca en código ni en logs; borrado de material sensible con `explicit_bzero`/`memset_explicit` (C23) — `memset` normal lo elimina el optimizador. Considerar `mlock` para claves y evitar que lleguen a *core dumps* (`prctl(PR_SET_DUMPABLE, 0)` donde aplique).
- Cripto: usar librería auditada (libsodium, OpenSSL 3.x, BoringSSL/mbedTLS según el target). **Nada de cripto propia**, ni de comparación de secretos con `memcmp` (tiempo constante: `sodium_memcmp`/`CRYPTO_memcmp`).
- Comparación de rutas y ficheros: `openat`/`O_NOFOLLOW`/`O_CLOEXEC` y ficheros temporales con `mkstemp`; nada de comprobar-y-luego-abrir (TOCTOU).
- `O_CLOEXEC`/`SOCK_CLOEXEC` por defecto en todo descriptor: la fuga de descriptores a procesos hijos es un escalado silencioso.

### MISRA C y CERT C — cuándo aplican
- **CERT C**: aplicable a cualquier proyecto C con superficie de seguridad; sus reglas se solapan con clang-tidy `cert-*`. Se adopta como conjunto de comprobaciones automatizadas, no como documento de lectura.
- **MISRA C**: obligatorio solo cuando el dominio lo exige (automoción/ISO 26262, IEC 61508, aviónica/DO-178C, dispositivos médicos/IEC 62304). Edición vigente verificada: **MISRA C:2025** (publicada marzo 2025), sucesora de MISRA C:2023; cubre C90/C99/C11/C18, ~225 guías activas, y **desaplica** la regla histórica de punto único de salida (aunque IEC 61508 / ISO 26262 puedan seguir exigiendo prácticas similares por su cuenta). Trata el código generado por IA igual que el escrito a mano a efectos de conformidad.
- MISRA exige **MISRA Compliance:2020** como marco: matriz de guías, desviaciones documentadas y aprobadas, y evidencia. Adoptar MISRA "de palabra" sin ese marco no es conformidad, es teatro.
- **No** aplicar MISRA a un proyecto que no lo necesita: penaliza construcciones legítimas y consume presupuesto de revisión que rinde más en sanitizers y fuzzing.

## 6. Rendimiento, ABI, portabilidad y operabilidad

### Rendimiento
- Medir antes de optimizar: `perf`, `flamegraph`, `cachegrind`. Un cambio de rendimiento sin número medido antes/después no se mergea.
- Benchmarks reproducibles (frecuencia fijada, *pinning* de CPU, varias repeticiones con dispersión reportada); nada de comparar tiempos de una sola ejecución.
- `-O2` es el default; `-O3` solo si el benchmark lo justifica en ese binario concreto. `-march=native` **prohibido** en artefactos distribuibles (genera binarios que fallan con SIGILL en otra máquina); *runtime dispatch* o *function multiversioning* si hace falta AVX-512.
- LTO (`-flto=thin` en Clang, `-flto` en GCC) por defecto en release si el tiempo de build lo permite; verificar que no rompe con símbolos alias/`__attribute__((used))`.
- Las micro-optimizaciones a mano son la última opción; el compilador de 2026 gana casi siempre. La ganancia real está en el algoritmo y en el patrón de acceso a memoria.

### ABI e interoperabilidad
- **La ABI es un contrato**: cambiar el tamaño o el layout de una struct pública, el orden de un enum, el prototipo de una función exportada o el *calling convention* es un **breaking change** aunque la API compile.
- Librerías compartidas: `SONAME` versionado, `-fvisibility=hidden` + macro de export, y **version script** (`--version-script`) para controlar el conjunto exportado. `abi-compliance-checker` o `abidiff` (libabigail) en CI de librerías con contrato ABI.
- Structs públicas: preferir **tipos opacos** (`typedef struct px_ctx px_ctx;`) para poder evolucionar sin romper ABI. Si la struct debe ser pública, no se le añaden campos en medio y se documenta el padding.
- FFI: la frontera C es el mínimo común denominador para Rust/Python/Go/C++. Reglas: nada de tipos dependientes de plataforma en la firma (usar `<stdint.h>`), enteros de tamaño fijo, ownership documentada en cada parámetro, **nada de propagar `errno` como contrato** entre lenguajes, y una función `*_free` exportada para cada objeto devuelto por la librería (el consumidor no puede llamar a `free` de otra libc — en Windows es un fallo directo).
- Consumo desde C++: cabecera con `#ifdef __cplusplus extern "C" {`, sin `bool` de `<stdbool.h>` en la firma si hay compiladores viejos de por medio, sin *flexible array members* en tipos que C++ deba definir, y sin nombres que sean palabras reservadas en C++ (`class`, `new`, `template`, `operator`...). El lado C++ del contrato lo fija `cpp-standards`.

### Portabilidad
- Declarar explícitamente el conjunto de targets soportados (arquitectura, libc, SO, compilador y versión mínima) en el README **y probarlos en CI**. Lo no probado no está soportado.
- Asumir: `char` puede ser con o sin signo; los enteros pueden ser de 32 o 64 bits (`long` es de 32 en Windows y de 64 en Linux — usar `<stdint.h>`); el orden de bytes varía; los accesos desalineados abortan en algunas arquitecturas; el orden de evaluación de los argumentos de una función no está especificado.
- Macros de test de features (`_POSIX_C_SOURCE`, `_GNU_SOURCE`) definidas en el build system, no salpicadas en los `.c`.
- Sin dependencia del comportamiento de una versión concreta del compilador; los `__builtin_*` y `__attribute__` se envuelven en macros con fallback.

### Operabilidad
- Logging estructurado a `stderr` (o syslog/journald según el despliegue) con nivel configurable; **nada de `printf` de depuración** en código de producción.
- Códigos de salida con significado; errores por `errno`-like o enum propio documentado — nunca códigos mágicos sin tabla.
- Salida limpia ante SIGTERM/SIGINT: *self-pipe*, drenaje del trabajo en curso, liberación de recursos. Un daemon que solo muere por SIGKILL no es desplegable con rolling update.
- Crashes: `build-id`, símbolos archivados, `core_pattern`/coredumpctl o recolector de crashes; un crash sin traza simbolizable es tiempo perdido.
- `assert` no es manejo de errores y **desaparece con `NDEBUG`**: nunca poner efectos laterales dentro, ni usarlo para validar entrada externa. Para invariantes que deben mantenerse en release, comprobación explícita con `abort()` o un `static_assert` (C11+) si es de compilación.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia**: subir de compilador al menos una vez al año (GCC publica una major anual, ~abril; LLVM cada ~6 meses) y probar la siguiente en CI **antes** de que sea obligatoria — un salto de tres versiones acumula warnings nuevos y cambios de optimización que destapan UB latente. Un fallo nuevo al subir de compilador es, por defecto, un bug propio, no una regresión del compilador. Estándar del lenguaje: revisar la migración a C23 cuando el toolchain mínimo del proyecto lo permita; C2y/C29 (borrador de trabajo en curso, publicación prevista al final de la década) **no** se usa en producción.

**Deprecación**: en librerías con contrato ABI, deprecar con `__attribute__((deprecated("usar X")))`, ventana de al menos una versión mayor, y `SONAME` nuevo cuando la ABI rompe. En binarios internos, no se acumulan flags de compatibilidad "por si acaso".

**Deuda consciente**: todo atajo deja `/* TODO(usuario): motivo — issue #N */`. Toda supresión de lint/sanitizer va con motivo y fecha de revisión.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- ❌ Las funciones de la tabla de §3 (`gets`, `strcpy`, `strcat`, `strncpy`, `sprintf`, `atoi`, `alloca`, `strtok`, `rand` para seguridad, `system` con string compuesta...).
- ❌ VLAs y `alloca` con tamaño derivado de entrada; buffers en pila dimensionados "con margen".
- ❌ Ignorar el retorno de `malloc`/`realloc`/`snprintf`/`read`/`write`/`fclose`; `p = realloc(p, n)`.
- ❌ Cast de puntero para *type punning* (violación de strict aliasing); casts para silenciar `-Wconversion`.
- ❌ `-Werror` desactivado en CI; `#pragma GCC diagnostic ignored` sin `push`/`pop` y motivo; `// NOLINT` sin lint concreto.
- ❌ Combinar ASan con TSan/MSan en la misma build (el compilador lo rechaza); desplegar producción con sanitizers.
- ❌ `-march=native` en artefactos distribuibles; `-O3` sin benchmark; `-ffast-math` en código que compare o valide flotantes.
- ❌ `volatile` como mecanismo de sincronización entre hilos; variables globales compartidas sin lock ni `_Atomic`.
- ❌ Aritmética de punteros fuera del objeto; comparar punteros de objetos distintos; `memcpy` con solape.
- ❌ Cabeceras públicas sin prefijo de proyecto, sin include guard o que arrastren `#include` innecesarios; símbolos externos sin prefijo.
- ❌ Estado global mutable en librerías (rompe reentrancia y tests); funciones con buffer estático de retorno.
- ❌ Macros que hacen lo que haría una función `static inline`; macros multi-sentencia sin `do { } while (0)`; macros que evalúan un argumento dos veces.
- ❌ Cripto propia, comparación de secretos con `memcmp`, `memset` para borrar secretos.
- ❌ Copiar código de terceros sin registro de origen, versión y licencia; dependencias apuntando a rama en vez de a tag+hash.
- ❌ Parser de entrada no confiable **sin harness de fuzzing**.
- ❌ Anexo K (`*_s`) como estrategia de portabilidad.
- ❌ Declarar "es solo un warning": un warning del compilador en C es un bug hasta que se demuestre lo contrario.
- ❌ **Incluir en esta skill o en el código que produce: exploits, ROP gadgets, bypasses concretos de mitigaciones, shellcode o payloads.** Esta skill es **defensiva**: describe clases de vulnerabilidad (desbordamiento, use-after-free, formato, TOCTOU, confusión de tipos) **para prevenirlas**, nunca para explotarlas. Trabajo ofensivo → `offensive-security-standards`, con alcance y autorización por escrito.

## 8. Verificación web obligatoria

Antes de fijar versiones, flags o afirmar estado del ecosistema, **verificar por web** (nunca de memoria):
1. **Estado real de C23 por compilador**: https://gcc.gnu.org/projects/c-status.html y https://clang.llvm.org/c_status.html (tabla papel a papel). No asumir paridad entre GCC y Clang: a ago-2026 GCC declara soporte C23 y default desde GCC 15; Clang acepta `-std=c23` desde 18 con soporte **parcial**.
2. **Versiones y ciclo de vida**: https://gcc.gnu.org/develop.html + https://gcc.gnu.org/releases.html (GCC no publica tabla formal de EOL: mantiene ~3 ramas y cierra la más vieja tras una release final — **dato a confirmar en cada momento**), releases de LLVM vía `https://github.com/llvm/llvm-project/releases.atom`, y las notas de MSVC si el proyecto lo soporta.
3. **Soporte real de la libc del target** para lo que se use de C23 (`<stdckdint.h>`, `memset_explicit`, `<threads.h>`) — glibc, musl y newlib **no** están al mismo nivel; comprobar en la doc de la libc, no en la del compilador.
4. **OpenSSF Compiler Options Hardening Guide** (documento vivo, cambia): https://best.openssf.org/Compiler-Hardening-Guides/ — releer antes de congelar el set de flags.
5. **Estado de mantenimiento y licencia** de toda herramienta antes de fijarla como default: precedentes del catálogo (Trivy cambió de licencia; gitleaks se declaró *feature complete* y su acción exige licencia comercial para organizaciones desde v2). Comprobar por feed Atom de releases (`/releases.atom`) y por el `LICENSE` en crudo desde `raw.githubusercontent.com`, no por lo que diga un agregador. Especial atención a: **CMocka** (mirror de GitHub congelado; fuente real `cmocka.org`), **cppcheck** (open source GPL-3.0 vs. edición *Premium* comercial) y **libFuzzer** (sin desarrollo activo de features en LLVM).
6. **MISRA**: edición vigente y addenda en https://misra.org.uk/publications/ (verificado: MISRA C:2025, marzo 2025). Verificar qué edición soporta realmente la herramienta de análisis contratada — suele ir por detrás.
7. **CERT C**: wiki oficial del SEI para la regla concreta antes de citarla como norma.
8. **Sanitizers**: las combinaciones soportadas y los flags exactos cambian entre releases — doc de Clang/GCC de la versión usada, no artículos.

**Huecos declarados (no verificados a ago-2026, verificar antes de usar como norma)**:
- Versión y estado de soporte de **MSVC** para C (su frontend C ha ido muy por detrás en C11/C17/C23): **no verificado**.
- Fechas de EOL formales de las ramas GCC 14/15/16 y de las releases de LLVM: **no verificado** (GCC no publica tabla de EOL; el patrón de ~3 ramas activas es descripción, no compromiso).
- Estado exacto de `-ftrivial-auto-var-init=zero` y de `-fsanitize=cfi` en la versión concreta de GCC/Clang del proyecto: **no verificado por versión**.
- Licencias verbatim de Criterion, CMocka y GSL/otras dependencias citadas de pasada: **no verificadas verbatim** (sí Unity → MIT, verificado en su `LICENSE.txt`; cppcheck → GPL-3.0 según el proyecto, confirmar en el fichero).
- Cobertura real de C23 en la libc de cada target (glibc/musl/newlib): **no verificada**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
