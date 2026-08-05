---
name: nim-standards
description: Nim engineering standards (staff-level). Trigger on .nim, .nims and .nimble files, nim.cfg, config.nims, nimble.lock, nimble install/build/lock, atlas, the --mm:orc/arc/refc/none memory-management switches, --styleCheck, --threads, nim c / nim cpp / nim js backends, macros and templates with macros/typetraits, staticExec and gorge at compile time, unittest and testament, nph or nimpretty formatting, or importc/dynlib FFI to C.
---

# Estándares Nim

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a ficheros `.nim`, `.nims`, `.nimble`, `nim.cfg`, `config.nims`, `nimble.lock`; a la elección de gestor de memoria (`--mm:`), de backend (`nim c`/`nim cpp`/`nim js`), al uso de macros y `template`, a la FFI con C (`importc`, `dynlib`, `header`), y a la ejecución en tiempo de compilación (`static:`, `staticExec`/`gorge`). Fija criterio: qué `--mm`, qué backend, cuándo NO escribir una macro, qué está prohibido.

**No aplica**: ver `zig-standards` (el nicho compilado de **control manual y explícito, sin runtime ni GC**: si el requisito es no tener recolector, no es Nim), `crystal-standards` (nicho compilado con **GC y ergonomía tipo Ruby**: sintaxis Ruby e inferencia global frente a la metaprogramación y el GC configurable de aquí) — la frontera entre los tres **no es el rendimiento, es el modelo de memoria y el propósito**: aquí, **GC configurable en tiempo de compilación (ORC/ARC/refc/none) y metaprogramación en AST como valor central**; `rust-standards` (**la comparación obligada y el default del catálogo para código de sistemas nuevo**: Rust da garantías comprobadas por el compilador, estabilidad de lenguaje con ediciones, ecosistema y contratación incomparablemente mayores. Nim se justifica frente a Rust por **velocidad de escritura y metaprogramación**, por binarios pequeños que compilan a C para plataformas raras, y por FFI con C sin ceremonia; **no** se justifica por rendimiento ni por seguridad de memoria — Nim con `--mm:arc/orc` no impide use-after-free ni carreras de datos); `c-standards` y `cpp-standards` (**el lado C/C++ de la FFI y del backend es suyo**: cabeceras, ABI, ciclo de vida de lo cedido, hardening del binario y elección de compilador C — Nim genera C y **ese C se compila con el toolchain que fije `c-standards`**; aquí solo `importc`/`exportc`/`dynlib` y las invariantes del lado Nim); `go-standards` (la otra vía a binarios distribuibles con GC y ecosistema maduro: para servicios de red suele ser la respuesta correcta antes que Nim); `cicd-standards`, `kubernetes-standards`, `appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`, `observability-standards`, `api-design-standards`, `sql-standards`.

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Valor verificado a ago-2026 | Motivo |
|---|---|---|
| Compilador estable | **2.2.10** (2026-04-24) | Última publicada en nim-lang.org/blog.html. Línea 2.0 en mantenimiento (último 2.0.16, abr-2025) |
| Licencia del compilador | **MIT** — «Nim -- a Compiler for Nim. https://nim-lang.org/ / Copyright (C) 2006-2026 Andreas Rumpf. All rights reserved.» (`copying.txt`, verbatim) | Sin fricción |
| Gestor de memoria | **`--mm:orc`** salvo justificación | Default desde Nim 2.0 y el único que soporta el `async` de la stdlib (ver §3) |
| Gestor de paquetes | **nimble** (incluido con el compilador) + **`nimble.lock` commiteado** | Es el registro real del ecosistema. `atlas` es alternativa de *clonado* con pin por commit git, no el default |
| Formato | **nph** (`nph --check` como gate) — MIT, «Copyright (C) 2023 Jacek Sieka. All rights reserved.» (`copying.txt`, verbatim); releases activos (v0.7.0, feb-2026) | Formatea el AST, no tokens: salida consistente estilo black/gofmt. `nimpretty` (oficial) solo hace ajustes locales |
| Lint de estilo | `--styleCheck:usages` mínimo; `:error` en código propio | Ver §3, es la peculiaridad que más daño hace |
| Tests | `std/unittest` en el proyecto; `testament` para suites del compilador/librerías grandes | |

**Pin obligatorio de la versión de Nim**: se declara en el `.nimble` (`requires "nim >= x.y.z"`) **y** se fija en `nimble.lock`, que registra la versión de Nim a usar. Aviso verificado: Nim añade automáticamente todo lo de `~/.nimble/pkgs2` al *path* de build — **el lock file por sí solo no da build reproducible**; en CI y en imágenes se parte de un `~/.nimble` limpio o de un contenedor con solo las dependencias del lock.

## 3. Decisiones estructurales

### El gestor de memoria es *la* decisión (`--mm:`)
Se elige una vez, al inicio, y condiciona librerías, concurrencia y determinismo. Va escrito en `config.nims`/`nim.cfg`, nunca dejado al default implícito de la máquina.

- **`--mm:orc`** — default y recomendación por defecto. ARC (conteo de referencias con optimización de moves, sin *stop-the-world*, sin instrucciones atómicas en las operaciones de RC) **más un colector de ciclos** por *trial deletion*. Es lo que hay que usar salvo prueba en contra.
- **`--mm:arc`** — ARC sin colector de ciclos: menos código máquina, liberación determinista. Válido cuando el código **demostradamente** no crea ciclos (anotar `acyclic`), típicamente embebido o restricción de tamaño. **Aviso verificado**: la implementación `async` por defecto de la stdlib **crea ciclos y con `--mm:arc` fuga memoria** — si hay `async`, es `orc`.
- **`--mm:refc`** — el GC clásico previo a Nim 2 (conteo diferido + mark&sweep de respaldo, heaps por hilo). Solo para código heredado que no migró; no para proyecto nuevo.
- **`--mm:none`** — sin gestión: la memoria no se libera nunca. La propia documentación recomienda `--mm:arc` en su lugar. Uso legítimo: procesos de vida corta tipo *one-shot*, y poco más.
- **Tiempo real / latencia acotada**: ARC/ORC dan liberación por conteo de referencias sin pausas globales, pero **la destrucción de un grafo grande sigue siendo un coste no acotado en el punto de liberación**. Si el requisito es latencia dura, se mide, no se supone.
- **Ninguno de los modos da seguridad de memoria**: ARC/ORC no impiden use-after-free con punteros crudos, ni carreras de datos entre hilos. Decirlo explícitamente en cualquier comparación con Rust.

### Insensibilidad parcial de identificadores — la trampa que hay que gobernar
Nim considera iguales dos identificadores según este algoritmo (manual, verbatim): `a[0] == b[0] and a.replace("_", "").toLowerAscii == b.replace("_", "").toLowerAscii`. Es decir: **solo la primera letra distingue mayúsculas; el resto se compara sin distinguir mayúsculas y los guiones bajos se ignoran**. `myVar`, `my_var` y `myvar` son **el mismo** símbolo.

- Criterio: **`--styleCheck:error` en el código propio** (impide usar un identificador de dos formas distintas), con `--styleCheck:usages` como escalón intermedio. Aviso verificado: partes de la stdlib han fallado históricamente bajo `--styleCheck:error`, incluso solo por importarlas — comprobar contra la versión pinneada antes de convertirlo en gate duro; si falla, `usages` + `nph` como gate.
- **FFI**: es donde muerde de verdad. Bibliotecas C con `foo_exp2` y `foo_exp_2` colisionan en Nim. Ante colisión, `importc` explícito con el nombre C exacto; nunca confiar en el mapeo automático de nombres.
- Convención de proyecto única (`camelCase` para procs/vars, `PascalCase` para tipos) aplicada por `nph` — el estilo lo decide la herramienta, no el revisor.

### Macros y metaprogramación — el valor diferencial y la deuda
Nim expone el AST en tiempo de compilación; es la razón principal por la que un equipo elige Nim. También es la razón principal por la que su código resulta impenetrable tres años después. **Escalera obligatoria: usar el escalón más bajo que resuelve el problema.**
1. Genéricos y `concept`s. 2. `template` (sustitución simple, depurable). 3. `macro` — **último recurso**.

**NO escribir una macro cuando**: existe un genérico o `template` que lo cubre; ahorra teclas pero no elimina un error posible; genera una API que no se puede leer sin ejecutar `expandMacros`; o solo la entiende quien la escribió. **Si se escribe**: tests dedicados sobre el código generado, `expandMacros` documentado en el propio módulo, mensajes de error explícitos (`error()` en el nodo correcto — una macro que falla con un error del compilador ilegible es peor que el código repetido) y un dueño nombrado.

### Backends — qué se pierde en cada uno
- **`nim c` (C)**: el camino soportado. Todo funciona; el binario depende del toolchain C del host (ver `c-standards`).
- **`nim cpp` (C++)**: necesario para interoperar con librerías C++. Cambia semántica de excepciones y de destructores en la frontera; ecosistema de librerías Nim probado sobre C, no sobre C++ — asumir que algunas romperán.
- **`nim js` (JavaScript)**: subconjunto real. No hay hilos, no hay FFI a C, la stdlib está parcialmente disponible y los enteros de 64 bits y el rendimiento no se comportan igual. Válido para compartir lógica de dominio entre servidor y navegador; **no** para asumir que "el mismo código corre en los dos sitios".
- El backend se fija en `config.nims` y **la suite de tests corre en todos los backends que el proyecto declare soportar**. Un backend no testeado no está soportado.

### Concurrencia
- `--threads` está **on por defecto desde Nim 2.0**. Aviso verificado (reportes de comunidad, ago-2025): esa activación se asocia a penalizaciones de rendimiento notables y a código async multihilo más lento que monohilo, con `-d:useMalloc` como mitigación habitual. **Medir en el propio proyecto**; no aceptar ni el default ni el workaround sin datos.
- `async`/`await` está implementado **en librería mediante macros**, no en el lenguaje: coexisten `std/asyncdispatch` y `chronos` con APIs incompatibles, y una librería obliga a elegir bando. **Criterio: elegir uno por proyecto y declararlo**; en aplicaciones que ya dependan del stack de Status, `chronos`. Verificar el backend async de cada dependencia antes de añadirla: mezclarlos es el modo de fallo característico de Nim.
- El `spawn` del `threadpool` de la stdlib está en vía muerta para código nuevo; el espacio está fragmentado (taskpools, malebolgia, weave, `nim-lang/threading`). Ninguno es un default del ecosistema: elegir uno, aislarlo tras una interfaz propia y documentar la decisión.

## 4. Calidad y testing

- **Gate de CI, en orden de coste**: `nph --check .` → `nim check` de todos los targets → `--styleCheck` según el escalón elegido → `nimble test` (unittest) en **todos** los `--mm` y backends declarados → build de release.
- `std/unittest` (`suite`/`test`/`check`) para el proyecto. `testament` para librerías grandes o cuando se necesitan *spec tests* con salida esperada y matriz de targets.
- Cobertura obligatoria de **bordes y errores**: excepciones que la API declara, entradas vacías/límite, y comportamiento bajo el `--mm` de producción.
- Compilar la suite **también con `-d:release`** (o `-d:danger` solo si es lo que se despliega): Nim desactiva comprobaciones en release y los bugs que solo aparecen ahí son los que llegan a producción.
- Excepciones: usar `{.raises: [].}` / `{.raises: [ValueError].}` en la API pública para hacer el contrato de errores verificable por el compilador. Es la herramienta más infrautilizada de Nim y la que más vale en revisión.
- `-d:danger` desactiva **todas** las comprobaciones en runtime (rangos, índices, overflow). **Nunca es el default de producción**; solo con benchmark que lo justifique y nunca en binarios que procesen entrada no confiable.

## 5. Seguridad del stack

- **`staticExec` / `gorge` ejecutan comandos de shell arbitrarios durante la compilación** (`staticExec(command: string; input = ""; cache = ""): string`), igual que `static:` puede ejecutar código Nim en tiempo de compilación. **Es el riesgo de cadena de suministro característico de Nim**: instalar y compilar una dependencia equivale a ejecutar su código con los permisos del runner de CI o del desarrollador. Consecuencias operativas obligatorias:
  - `nimble install` y `nim c` de código no confiable **solo en contenedor efímero sin credenciales, sin red de salida y sin acceso al agente SSH**. Nunca en la máquina de un desarrollador con secretos ni en un runner con token de despliegue.
  - Revisar `staticExec`/`gorge`/`static:` en el diff de cada actualización de dependencia; `grep` de esos símbolos como control automático en CI.
  - Los ficheros `config.nims` y `.nimble` **son código ejecutable**: tratarlos como tal en revisión.
- **Ecosistema de paquetes**: el registro es un `packages.json` con nombres apuntando a repos git. **No hay base de advisories, ni firma, ni auditoría, ni proceso de abandono.** No existe equivalente a `cargo deny`/`pip-audit`. Consecuencia: número de dependencias mínimo, `nimble.lock` commiteado, revisión manual de cada bump y evaluación explícita del bus factor de cada dependencia. Declararlo en el análisis de riesgo.
- **Entrada no confiable**: validar en el borde; con `-d:danger` desaparecen las comprobaciones de índice y de rango, así que la decisión de flags de release es una decisión de seguridad. Aritmética: comprobar los límites explícitamente en vez de confiar en la comprobación de overflow de `-d:release`.
- **FFI**: `importc` sin declarar bien el ownership es la fuente principal de corrupción. Documentar quién libera cada puntero que cruza; envolver la API C en un tipo Nim con `destroy=`/`=destroy` en vez de exponer punteros crudos.
- Secretos nunca en `.nimble`, `config.nims` ni en el binario. SQL solo parametrizado (`db_connector`); prohibido interpolar en la query.

## 6. Rendimiento y operabilidad

- El binario es C compilado: aplica el hardening y la observabilidad estándar del artefacto nativo (ver `c-standards` y `observability-standards`). Compilación estática contra musl para imágenes `scratch`.
- Medir antes de optimizar: `--profiler:on`/`nimprof`, o perf/valgrind sobre el binario. Las suposiciones sobre coste de ORC frente a ARC se comprueban con datos del propio *workload*.
- Timeouts explícitos en todo cliente de red; apagado ordenado que cierre el *dispatcher* async y drene tareas antes de salir.

## 7. Sostenibilidad y prohibiciones

**Cadencia y compatibilidad.** Nim 2.0 (2023) fue el corte real: cambió el default a `--mm:orc` y activó `--threads` por defecto — migrar desde 1.x **no es un bump de versión**, es un proyecto. Dentro de la línea 2.x la compatibilidad ha sido buena y la cadencia es de parches cada pocos meses (2.2.2 feb-2025 → 2.2.4 abr-2025 → 2.2.6 oct-2025 → 2.2.8 feb-2026 → 2.2.10 abr-2026). Política práctica: seguir la última de la línea 2.2 y revisar el changelog en cada bump; la línea 2.0 solo para congelados.

**Honestidad sobre el proyecto y la comunidad.** Nim es un lenguaje con **bus factor muy alto**: el diseño y buena parte del compilador giran en torno a Andreas Rumpf (Araq), con un equipo pequeño y sin respaldo corporativo ni fundación comparable a otros lenguajes. La comunidad es de orden de magnitud menor que Go/Rust; la documentación de las áreas en movimiento (concurrencia, async) **va por detrás del código** y buena parte del conocimiento operativo vive en hilos de foro, no en la doc. Consecuencias que van escritas en la decisión de adopción, no en una nota al pie: contratar Nim en el mercado abierto es poco realista, cada dependencia relevante puede tener un único mantenedor, y el coste de soporte lo asume el equipo.

**PROHIBIDO** (excepción con justificación escrita):
- ❌ Dejar el `--mm` al default implícito o cambiarlo a mitad de proyecto sin re-testear todo; `--mm:arc` con `async` de la stdlib (fuga verificada); `--mm:refc` en proyecto nuevo; `--mm:none` en un proceso de vida larga.
- ❌ `-d:danger` en producción sin benchmark que lo justifique, y **jamás** en binarios que procesen entrada no confiable.
- ❌ `nimble install` / `nim c -r` de código no auditado fuera de un contenedor efímero y sin credenciales.
- ❌ Añadir una dependencia sin revisar sus `staticExec`/`gorge`/`static:` ni su bus factor; `nimble.lock` fuera del control de versiones.
- ❌ Escribir una `macro` donde bastan genéricos o un `template`; macro sin tests del código generado, sin mensajes de error propios y sin dueño nombrado.
- ❌ Confiar en la insensibilidad parcial de identificadores como "comodidad": convención única + `nph` + `--styleCheck`. Ningún símbolo escrito de dos formas en el mismo repo.
- ❌ Mezclar `std/asyncdispatch` y `chronos` en el mismo árbol de dependencias.
- ❌ Declarar soporte de un backend (`cpp`, `js`) que no tiene CI que lo compile y lo teste.
- ❌ API pública sin `{.raises.}` en librerías; exponer punteros crudos de la FFI sin tipo envolvente que gestione la vida.
- ❌ **Elegir Nim cuando**: el equipo rota o hay que contratar, la seguridad de memoria es requisito normativo, se necesita ecosistema maduro y auditado (crypto, drivers, ORM, SDK de cloud), o el proyecto sobrevivirá a sus autores originales. En esos casos la respuesta es **Go** (servicios, binarios distribuibles, contratación) o **Rust** (garantías del compilador, sistemas). Nim es defendible para: herramienta interna o CLI de un equipo pequeño y estable, código que necesita metaprogramación pesada con rendimiento nativo, targets exóticos alcanzables vía C, y prototipos donde la velocidad de escritura manda.

## 8. Verificación web obligatoria

1. **Estable vigente y changelog**: https://nim-lang.org/blog.html y las release notes de la versión concreta; feed https://github.com/nim-lang/Nim/releases.atom (no `api.github.com`: devuelve 403 sin autenticar).
2. **Default y semántica de `--mm`** para la versión pinneada: https://nim-lang.org/docs/mm.html — verificar en la doc de *esa* versión, no en artículos.
3. **Estado de la concurrencia y del `async`**: foro oficial (forum.nim-lang.org) además de la doc; es el área con mayor desfase entre código y documentación. Verificar qué backend async usa cada dependencia.
4. **Estado real de `nimble` vs `atlas`** y del formato de `nimble.lock` en la versión usada; y si `--styleCheck:error` compila con la stdlib de esa versión.
5. **Licencias y mantenimiento** de cada dependencia (`LICENSE` en crudo en el repo) y de las herramientas fijadas aquí; comprobar cadencia real de commits antes de depender de una librería con un solo mantenedor.
6. **Salud del proyecto**: última encuesta de comunidad publicada y actividad de NimConf/blog antes de fundamentar una adopción a varios años.

**Huecos no verificados a ago-2026**: si existe una encuesta de comunidad Nim posterior a la de 2024 **no verificado** (el blog no la lista); la penalización de rendimiento asociada a `--threads:on` por defecto proviene de **reportes de comunidad de ago-2025, no de una medición oficial ni propia** — tratar como hipótesis a medir, no como dato; si `--styleCheck:error` sigue fallando con la stdlib en 2.2.10 concretamente **no verificado** (el fallo está documentado como problema histórico); la posición oficial actual de `atlas` frente a `nimble` **no verificada** — no hay declaración oficial que designe uno como sucesor.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
