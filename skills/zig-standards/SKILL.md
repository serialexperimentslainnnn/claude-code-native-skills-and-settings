---
name: zig-standards
description: Zig engineering standards (staff-level). Trigger on .zig and .zon files, build.zig, build.zig.zon, zig build/zig build test/zig fetch --save, ReleaseSafe/ReleaseFast/ReleaseSmall build modes, std.heap allocators (DebugAllocator, ArenaAllocator, FixedBufferAllocator, smp_allocator), std.testing.allocator, std.Io, comptime, errdefer and error unions, zig fmt, zlint, or using zig cc / zig c++ as a C/C++ cross-compilation toolchain.
---

# Estándares Zig

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a ficheros `.zig` y `.zon`, `build.zig`, `build.zig.zon`, invocaciones `zig build`/`zig build test`/`zig fetch`, selección de modo de build, uso de asignadores de `std.heap`, `comptime`, *error unions*, `std.Io`, y al uso de **Zig como toolchain de C/C++** (`zig cc`, `zig c++`, cross-compilación). Fija criterio: qué versión, qué asignador, qué modo de build va a producción, qué está prohibido.

**La premisa que domina todo lo demás**: **Zig no ha llegado a 1.0 y no hay fecha**. Cada release menor rompe código. Adoptar Zig es aceptar un **coste de migración recurrente** como línea permanente del presupuesto de mantenimiento, no como incidencia puntual (§7).

**No aplica**: ver `nim-standards` (el otro nicho compilado con **GC configurable y metaprogramación pesada**: si el proyecto quiere macros y recolección de basura ajustable, no es Zig), `crystal-standards` (nicho compilado con **GC y ergonomía tipo Ruby**: productividad de scripting con tipos, no control de memoria) — la frontera entre los tres **no es el rendimiento, es el modelo de memoria y el propósito**: aquí, control manual y explícito sin runtime ni GC; `rust-standards` (**la comparación obligada y el default del catálogo para código de sistemas nuevo**: Rust da garantías de memoria comprobadas por el compilador, lenguaje estable con ediciones, ecosistema y contratación mucho mayores. Zig se justifica frente a Rust por **cross-compilación e interoperabilidad C sin fricción**, por **simplicidad del modelo mental** y por control total de asignación; **no** se justifica por "es más fácil que Rust" ni para un servicio de negocio con plazo y rotación de equipo); `c-standards` y `cpp-standards` (**el C/C++ que se compile sigue siendo suyo**: `-std=`, MISRA/CERT, hardening del binario, ABI y cabeceras de la FFI. **`zig cc` es el caso especial**: decidir usar Zig como toolchain para compilar C es decisión *de aquí*, pero **el código C resultante sigue sujeto a `c-standards`** — usar `zig cc` no exime de `_FORTIFY_SOURCE`, sanitizers ni revisión MISRA); `go-standards` (la otra vía a binarios distribuibles sin dependencias, con GC y ecosistema maduro: para servicios de red suele ser la respuesta correcta antes que Zig); `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen OCI y despliegue), `appsec-standards` (clases de vulnerabilidad y modelado de amenazas), `vulnerability-management-standards` (triaje de CVE del árbol C que se enlace), `secrets-management-standards`, `observability-standards`, `api-design-standards`, `sql-standards`.

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Valor verificado a ago-2026 | Motivo |
|---|---|---|
| Compilador estable | **0.16.0** (2026-04-14) | Última estable en ziglang.org/download. 0.17 en desarrollo |
| Origen canónico | **Codeberg** (`codeberg.org/ziglang/zig`) | El proyecto migró desde GitHub en nov-2025; **el repo de GitHub es un mirror de solo lectura y su feed de releases está desactualizado** — no es un proyecto abandonado |
| Licencia del compilador | **MIT (Expat)** — «The MIT License (Expat) / Copyright (c) Zig contributors» (`LICENSE`, verbatim) | Sin fricción de distribución |
| Versión del compilador | **Fijada explícitamente por proyecto**, obligatorio | Cada minor rompe; sin pin, el build no es reproducible ni entre máquinas ni en el tiempo |
| Formato | `zig fmt` (integrado), gate de CI | No hay debate de estilo en Zig |
| Lint | `zlint` (opcional, releases activos: v0.9.1 jul-2026) | Complemento, no sustituto de `zig fmt`; no es oficial: evaluar antes de convertirlo en gate bloqueante |
| Gestor de paquetes | El integrado: `build.zig.zon` + `zig fetch --save` | No hay alternativa; ver §3 |

**Pin del compilador**: se fija en el fichero de entorno del proyecto (imagen de CI, `flake.nix`, `mise.toml`, `.tool-versions` o descarga verificada por hash en el Makefile) **y** se declara `.minimum_zig_version` en `build.zig.zon`. Aviso verificado: `minimum_zig_version` es **advisory** — el compilador aún no lo hace cumplir; no sustituye al pin real.

## 3. Estructura, build y paquetes

- `build.zig` (script de build, es código Zig) + `build.zig.zon` (manifiesto). El `.zon` declara `.name` (literal de enum, identificador Zig válido, ≤32 bytes), `.version` (SemVer), **`.fingerprint`** (identificador global del paquete: se genera una vez y **nunca se copia de otro proyecto**), `.paths` y `.dependencies`.
- **`.paths` es normativo**: solo lo listado entra en el hash y solo eso queda en disco al consumir el paquete. Listar lo necesario para compilar **más la licencia**; no listar `""` (raíz) por pereza en paquetes publicados.
- Dependencias: **siempre con `zig fetch --save <url>`**, nunca editando el `.hash` a mano. Cada dependencia lleva `url` + `hash`, o `path` para locales. Al cambiar de URL **se borra el hash antiguo**; conservarlo afirma que se espera el mismo contenido en otra URL.
- `.lazy = true` para dependencias opcionales; `zig build --fetch` prefetch completo (tras él, `zig build` no requiere red — usarlo en CI y en builds herméticos).
- 0.16 añadió **descarga de paquetes a un directorio local del proyecto** y la posibilidad de **sobrescribir un paquete localmente** (parchear una dependencia rota sin esperar upstream). Verificar la ruta y los flags exactos contra las release notes de la versión que se use (§8).
- Layout: `src/main.zig` (binario fino) + `src/root.zig` (librería), tests junto al código. Módulos por dominio.
- `comptime` es el sustituto de macros y de genéricos: los tipos se calculan con funciones normales que devuelven `type`. **Criterio**: `comptime` para lo que el compilador debe conocer (tablas, validación de configuración, generación de tipos); **prohibido** usarlo como sistema de plantillas creativo que nadie más pueda leer — la penalización es tiempo de compilación y mensajes de error ilegibles.
- **Sin ocultamiento de control de flujo** es criterio de diseño del lenguaje, no una carencia: no hay excepciones, no hay sobrecarga de operadores, no hay asignación de memoria oculta, no hay constructores/destructores implícitos. **Cualquier patrón que reintroduzca esa opacidad (envolver todo error en un `catch unreachable`, esconder un allocator en una global) contradice el motivo de elegir Zig.**

## 4. Memoria, errores y testing

### Asignadores — el rasgo central
Ninguna función de `std` que asigne memoria lo hace sin un `Allocator` explícito por parámetro. Criterio:

- **`std.heap.DebugAllocator`** — antes `GeneralPurposeAllocator`, **renombrado en 0.14.0** (el nombre viejo quedó como alias deprecado). Para desarrollo y tests: detecta fugas, doble-free y uso tras liberar de *su* memoria. `deinit()` devuelve `.ok`/`.leak`.
- **`std.testing.allocator`** en todos los tests. El runner falla el test si hay fuga: es el detector de fugas de facto y **no es opcional**.
- **`ArenaAllocator`** para vida por fase/petición: se asigna sin liberar individualmente y se tira todo con un `deinit`. Es la respuesta correcta a la mayoría del código de aplicación.
- **`FixedBufferAllocator`** para memoria acotada sin heap (embebido, rutas sin fallo de asignación).
- **`std.heap.smp_allocator`** para builds de release multihilo; `page_allocator` **no** para asignación general (no rastrea nada y su granularidad es la página).
- Regla: la función que asigna documenta **quién libera**. Un `deinit` por cada `init`, y `defer`/`errdefer` inmediatamente después de la adquisición.

### Errores
- *Error unions* (`!T`) y conjuntos de error inferidos; `try` para propagar. **`errdefer` para deshacer lo adquirido en el camino de error** — es la mitad que se olvida y la que produce las fugas.
- `catch unreachable` **prohibido** salvo invariante demostrada en comentario; `catch |e| { ... }` explícito o propagación. Tragar un error con `catch {}` es defecto de revisión.
- Conjuntos de error explícitos en la API pública de una librería (`error{A,B}!T`), no inferidos: el inferido es un contrato que cambia sin avisar.

### Modos de build y qué comprueba cada uno — **sé exacto**
- `Debug` y `ReleaseSafe`: **comprobaciones de seguridad en runtime activas**. Detectan *illegal behavior* detectable: índice fuera de rango, `unreachable` alcanzado, cast que no cabe, y **desbordamiento de enteros con y sin signo** (en Zig el overflow de *ambos* es illegal behavior; para envolver a propósito están `+%`, `-%`, `*%`). Además, en Debug y ReleaseSafe **Zig escribe `0xaa` en la memoria `undefined`** — mitigación, no detección.
- `ReleaseFast` y `ReleaseSmall`: **esas comprobaciones desaparecen**. El mismo desbordamiento pasa a ser comportamiento indefinido explotable.
- **`use-after-free` NO lo detecta ninguna comprobación del compilador, en ningún modo.** El compilador no rastrea vidas. Lo que detecta UAF de heap es el **asignador** (`DebugAllocator`), y solo de su propia memoria; el de pila no se detecta (equivale al problema de la parada) y solo se mitiga con el patrón `0xaa`. **Es la diferencia dura frente a Rust y hay que decirlo en cualquier evaluación de adopción.**
- **Producción: `ReleaseSafe` por defecto.** `ReleaseFast` solo con justificación medida (benchmark) y con el resto de defensas compensando (fuzzing, revisión, entrada acotada). Nunca `ReleaseFast` en un binario que procese entrada no confiable sin esa justificación escrita.
- `@setRuntimeSafety(false)` es una excepción local que requiere comentario justificativo; no se usa "para ir rápido".

### Testing
- Bloques `test "..."` junto al código; `zig build test` como comando único de CI. Cubrir camino feliz, **bordes y cada variante de error** (`std.testing.expectError`).
- Todo parser/decoder de entrada no confiable: **fuzzing** con el fuzzer integrado del build system, corpus versionado. Es obligatorio en Zig precisamente porque no hay garantías de memoria.
- Ejecutar la suite en **ambos** modos, `Debug`/`ReleaseSafe` y el modo de producción: los bugs que solo aparecen sin safety son los que llegan a producción.
- Gate de CI (todo rompe el build): `zig fmt --check .` → `zig build` → `zig build test` (con el pin de compilador del proyecto) → build cruzado de los targets soportados.

## 5. Seguridad del stack

- **Dependencias por URL con hash en `build.zig.zon`**: el hash es la fuente de verdad, no la URL. Prohibido apuntar a `#HEAD` o a una rama; se fija un commit/tag concreto. Un tarball de GitHub cuya generación cambie invalida el hash — preferir URLs inmutables. Revisar cada dependencia como decisión de confianza: **`build.zig` ejecuta código arbitrario en el build**, con los permisos del runner.
- El ecosistema de paquetes Zig **no tiene registro central, ni base de advisories, ni auditoría**. No existe el equivalente a `cargo deny`. Consecuencia operativa: número de dependencias mínimo, `zig build --fetch` + vendorizado o caché propia, y revisión manual de cada actualización. Declararlo en el análisis de riesgo del proyecto.
- **Entrada no confiable**: validar en el borde antes de indexar o asignar; toda longitud recibida de la red se acota contra un máximo explícito antes de `alloc`. En `ReleaseSafe` un índice inválido es panic (DoS, no RCE); en `ReleaseFast` es corrupción de memoria — el modo de build es una decisión de seguridad.
- **Aritmética**: con entrada no confiable, usar operaciones explícitas (`std.math.add`/`mul` que devuelven error, o `@addWithOverflow`) en vez de confiar en el panic de `ReleaseSafe`. Un panic en producción por un tamaño manipulado sigue siendo una caída provocada por el atacante.
- Secretos nunca en `build.zig`, `build.zig.zon` ni en el binario; env vars o gestor.
- Contenedores: binario estático (`-Dtarget=...-linux-musl`), imagen `scratch`/distroless, non-root, FS read-only. Zig cross-compila esto sin toolchain externa: es una de sus mejores bazas operativas.

## 6. Zig como toolchain de C/C++

Motivo de adopción frecuente **sin escribir una línea de Zig**, y decisión legítima por sí sola:

- `zig cc` / `zig c++` son un frontend Clang empaquetado con **cabeceras y fuentes de libc (musl y glibc multi-versión)**, en un solo binario portable. Permiten cross-compilar C/C++ desde cualquier host a cualquier target soportado sin sysroot ni toolchain por plataforma. Casos reales: cross-compilación del monorepo Go de Uber, `hermetic_cc_toolchain` para Bazel.
- Criterio: usarlo cuando el dolor real es **la matriz de cross-compilación**, no la calidad del código C. Aporta hermeticidad y reproducibilidad; **no** aporta seguridad de memoria.
- **El C que compila sigue sujeto a `c-standards`**: warnings, sanitizers, `_FORTIFY_SOURCE`, hardening del binario y revisión estática no se relajan por cambiar de driver de compilador.
- Verificar la versión de glibc objetivo: con cross-compilación Zig aplica un default histórico si no se especifica — **fijarla explícitamente** según el sistema de destino más antiguo soportado, y verificar el rango disponible en la versión de Zig usada (§8).
- Contrapartida: se ata la build de C a la cadencia de breaking changes de Zig. Pinnear la versión de Zig es igual de obligatorio aquí.

## 7. Sostenibilidad y prohibiciones

**Cadencia y coste de migración.** Sin 1.0 y sin fecha para él: 0.16 (abr-2026) reescribió toda la E/S alrededor de `std.Io` (todo lo que bloquea o introduce no determinismo se pasa por un parámetro `io`), tras 0.15 haber roto los `Writer`/`Reader`. Se anuncia que **0.17 rompe el sistema de build de prácticamente todo proyecto**. Planificación realista: **una migración por release**, presupuestada, con la versión anterior congelada hasta completarla. `zig build --fork` (parchear una dependencia rota localmente) existe precisamente porque la rotura del ecosistema es el modo normal de operación.

**Salud del proyecto.** Zig Software Foundation, 501(c)(3), equipo pequeño en torno a Andrew Kelley; ingresos ~$671k y gastos ~$523k en el ejercicio fiscal 2024 (Form 990), con el propio informe de 2025 admitiendo que el nivel de ingresos recurrente no permitía renovar todos los contratos del equipo. Donación comprometida de Mitchell Hashimoto de $400k repartidos en dos años (2026). Lectura: **proyecto vivo y financiado, pero con bus factor alto y dependiente de mecenazgo**. Es un dato que va en la decisión de adopción, no una nota al pie.

**PROHIBIDO** (excepción con justificación escrita):
- ❌ Usar Zig sin **fijar la versión del compilador** por proyecto; asumir que `latest` funcionará mañana.
- ❌ `ReleaseFast` en producción **sin benchmark que lo justifique**, y jamás en un binario que parsee entrada no confiable sin defensas compensatorias documentadas.
- ❌ Asumir que `ReleaseSafe` protege de use-after-free o de punteros colgantes. **No lo hace.**
- ❌ `catch unreachable`, `catch {}` o `orelse unreachable` como manejo de errores; `unreachable` alcanzable por entrada externa.
- ❌ Perder el `errdefer` que revierte una adquisición parcial; `init` sin `deinit` correspondiente.
- ❌ Ocultar el `Allocator` en una variable global o en un singleton: rompe el rasgo central del lenguaje y hace intestable el código.
- ❌ Dependencias apuntando a `#HEAD`/rama, o editar `.hash` a mano en vez de `zig fetch --save`.
- ❌ Tests sin `std.testing.allocator`; suite que solo corre en un modo de build.
- ❌ `@setRuntimeSafety(false)` o `@ptrCast`/`@alignCast` sin comentario que demuestre la invariante.
- ❌ `comptime` como sistema de plantillas ilegible; API pública con conjuntos de error inferidos.
- ❌ **Elegir Zig cuando**: el equipo rota, el plazo es fijo, la seguridad de memoria es un requisito normativo, se necesita ecosistema (HTTP, crypto, drivers de BD, ORM) ya resuelto y auditado, o se contrata en el mercado abierto. En esos casos la respuesta es **Rust** (sistemas nuevos con garantías) o **Go** (servicios de red y binarios distribuibles). Zig es defendible para: toolchain de cross-compilación C/C++, sistemas embebidos/bare-metal con control total de asignación, interoperar con una base C existente, o un equipo pequeño, estable y motivado que acepta el coste de migración por release.
- ❌ Introducir Zig en un componente crítico "para probarlo" sin acordar antes quién paga la migración del año que viene.

## 8. Verificación web obligatoria

1. **Estable vigente y notas de release**: https://ziglang.org/download/ y https://ziglang.org/news/ — **no** el feed de releases de GitHub: el repo de GitHub es mirror de solo lectura desde nov-2025 y va desfasado. Origen canónico: https://codeberg.org/ziglang/zig.
2. **Breaking changes de la versión objetivo**: release notes completas de esa versión (`ziglang.org/download/<v>/release-notes.html`) y el devlog (`ziglang.org/devlog/`) antes de planificar cualquier migración.
3. **Nombres exactos de `std`**: han cambiado y seguirán cambiando (`GeneralPurposeAllocator`→`DebugAllocator` en 0.14; `std.Io` en 0.16). Verificar contra la **documentación de la versión pinneada**, nunca contra tutoriales.
4. **Formato de `build.zig.zon`** y flags de `zig fetch`/`zig build` de la versión concreta: `doc/build.zig.zon.md` del repo en la etiqueta correspondiente.
5. **Estado de las librerías de terceros** que se vayan a usar: comprobar que ya soportan la versión pinneada — en Zig el retraso del ecosistema tras cada release es la norma.
6. **Rango de versiones de glibc y targets** de `zig cc` en la versión usada (`zig targets`, `zig libc`), y la licencia de cualquier librería que se vendorice.
7. **Salud de ZSF**: informe financiero anual y devlog (`ziglang.org/news/`) antes de fundamentar una decisión de adopción a varios años.

**Huecos no verificados a ago-2026**: la ruta y el nombre exactos del directorio local de paquetes introducido en 0.16 y los flags de *override* local **no verificados** contra la documentación oficial de 0.16 (solo contra el titular de las release notes); el alcance exacto de la rotura del sistema de build anunciada para 0.17 **no verificado** (0.17 no publicada); el estado de mantenimiento a largo plazo de `zlint` (no oficial) **no verificado** más allá de su cadencia de releases.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
