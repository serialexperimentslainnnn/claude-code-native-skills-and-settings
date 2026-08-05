---
name: ocaml-fsharp-standards
description: OCaml and F# language engineering standards (the strict ML family). Trigger on .ml/.mli/.mll/.mly files, dune/dune-project/dune-workspace, .opam files and opam switches, .ocamlformat, .merlin, ocaml-lsp/Merlin, and on .fs/.fsi/.fsx files, dotnet fsi scripts, .fsproj, .fantomasignore, paket.dependencies. Covers OCaml 5 domains and effect handlers, functors and the module system, Lwt/Async/Eio, js_of_ocaml, Stdlib versus Jane Street Base/Core, Alcotest and QCheck, and on the F# side discriminated unions, computation expressions, type providers, Result-based domain modelling, Fantomas, Expecto, FsCheck, FsUnit and the C# interop boundary.
---

# Estándares OCaml y F#

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a los dos ML **estrictos** de uso industrial. **OCaml**: `.ml`/`.mli`/`.mll`/`.mly`, `dune`, `dune-project`, `dune-workspace`, ficheros `*.opam`, `.ocamlformat`, switches de opam, Merlin/ocaml-lsp. **F#**: `.fs`/`.fsi`/`.fsx`, `dotnet fsi`, `.fsproj`, `.fantomasignore`, `paket.dependencies`.

**Comparten linaje, no comparten nada más.** OCaml y F# descienden de ML y por eso se parecen en la superficie —inferencia Hindley-Milner, ADTs, pattern matching exhaustivo, inmutabilidad por defecto—, pero **no comparten ecosistema, ni runtime, ni gestor de paquetes, ni herramientas, ni modelo de concurrencia**. OCaml tiene compilador nativo propio, GC propio, `opam`/`dune` y un sistema de módulos con functores que F# no tiene. F# es un lenguaje sobre el CLR: su runtime, su GC, su gestor de paquetes (NuGet) y su calendario de soporte son los de .NET, y su interop con C# es un requisito de diseño, no un extra. Ninguna decisión se traslada de uno al otro por analogía. Por eso **cada sección de abajo dice explícitamente cuál de los dos manda**; lo poco que es común va marcado como **[Ambos]**.

**No aplica**:
- **`dotnet-standards` — frontera crítica, sin ambigüedad.** Son **de `dotnet-standards`**: el SDK de .NET y `global.json`, la versión LTS y su calendario de soporte, `Directory.Build.props`/`Directory.Packages.props`, **NuGet y su seguridad** (NuGetAudit, lockfiles, CPM), la publicación y el empaquetado, el runtime y Native AOT, **ASP.NET Core**, el hosting, la configuración, la observabilidad del servicio y la contenedorización. Son **de esta skill**: **cómo se escribe F#** — el lenguaje y sus idiomas, uniones discriminadas y modelado del dominio con tipos, computation expressions, `Result` frente a excepciones, `Fantomas`, `Expecto`/`FsCheck`, type providers, `dotnet fsi` como scripting, y **la frontera con C#** (nulos, `Option`, interfaces expuestas). Regla de arbitraje: **si el problema es de ASP.NET Core, manda `dotnet-standards` aunque el código sea F#**; si el problema es la forma del tipo o del código F#, manda esta.
- `haskell-fp-standards` (el otro funcional tipado: la frontera es **pereza frente a evaluación estricta** —aquí no hay thunks ni fugas de espacio por `foldl`, sí hay orden de evaluación observable— y la **clase de sistema de tipos**: módulos/functores y efectos por *handlers* aquí, type classes + higher-kinded types + `IO` monádico allí).
- `scala-standards` (*Ola 5, ya escrita* — funcional sobre JVM: la frontera es el **runtime y la interop Java**, más su elección de ecosistema Typelevel/ZIO/Pekko).
- `rust-standards` (comparte linaje ML y ADTs; la frontera es el **modelo de memoria** —ownership sin GC frente a GC— y el propósito: sistemas y latencia acotada frente a corrección de la lógica).
- `jvm-spring-standards` (*Ola 5, ya escrita* — solo si el problema entra por JVM/Spring).
- `iac-standards` (**Nix como gestor de infraestructura/despliegue es suyo; Nix como toolchain reproducible de este proyecto OCaml —devShell, pin de opam/dune— es de aquí**).
- `cicd-standards` (la pipeline y su caché), `kubernetes-standards` (imagen OCI y despliegue), `api-design-standards` (el contrato HTTP/gRPC; aquí solo su implementación con Dream/opium o Giraffe/Falco), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas; aquí solo los sinks concretos de estos lenguajes), `vulnerability-management-standards` (triaje y SLA de CVEs; aquí solo el gate de auditoría), `secrets-management-standards`, `observability-standards` (pipeline OTel y SLOs; aquí solo la instrumentación), `sql-standards` (*Ola 5, ya escrita* — el SQL que generen Caqti/Petrol o Dapper/EF), `python-standards`/`go-standards`/`typescript-standards` (elección de lenguaje cuando ninguno de estos dos es la respuesta).

## 2. Decisiones por defecto y toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Lo de abajo es el estado verificado a **ago-2026**.

### OCaml

| Pieza | Elección | Estado verificado (ago-2026) | Nota |
|---|---|---|---|
| Compilador | **OCaml 5.5.0** | publicado 2026-06-19 | Anterior: 5.4.1 (2026-02-17). Añade *module-dependent functions* y compilador reubicable |
| Línea 4.x | **4.14.4** (2026-06-15) | mantenimiento; soporte anunciado *al menos* hasta finales de 2026 | **Solo legado.** Ningún proyecto nuevo en 4.x; planificar la salida ya |
| Gestor | **opam ≥ 2.5.2** | 2.5.2 publicada 2026-07-08 | **Versión mínima por seguridad**, no por features (§5) |
| Build | **dune 3.24.0** | 2026-06-30 | *directory targets* pasan a disponibilidad general |
| Formatter | **ocamlformat 0.29.0** | 2026-03-17 | Fichero `.ocamlformat` **con la versión fijada** (obligatorio) |
| IDE | **Merlin 5.7.1-504** + **ocaml-lsp 1.26.0** | 2026-04-30 / 2026-04-10 | Merlin va emparejado a la versión de compilador (sufijo `-504`) |
| Concurrencia | **Eio 1.4** (2026-07-23) en proyectos nuevos sobre OCaml 5 | — | `Lwt 6.1.2` (opam 2026-04-29, MIT) sigue vivo y es la opción segura en código existente |
| Tests | **Alcotest** + **QCheck** | verificar versiones (§8) | Property-based no es opcional |
| Base | **Stdlib** por defecto | — | Jane Street `Base`/`Core` es una decisión de proyecto entera (abajo) |

**Mínimos no negociables**: **opam + dune**. Cualquier proyecto OCaml que no use los dos es un proyecto que nadie de fuera puede construir. Nada de Makefiles artesanales invocando `ocamlfind`, nada de `ocamlbuild`. El switch de opam se declara (`dune-project` + ficheros `*.opam` generados por dune, o `opam.locked` versionado) para que `opam switch create . --deps-only` reproduzca el entorno.

**Política de versión de OCaml.** Sin LTS formal: se publica ~una menor al año y las anteriores dejan de recibir arreglos rápidamente. Criterio: **estar en la menor vigente y aplicar la revisión de parche sin demora** — el precedente reciente (OSEC-2026-01, §5) es que los arreglos de seguridad del runtime salen como `5.x.1`/`4.14.z` y quedarse atrás es quedarse expuesto. El salto de menor se prueba en rama con toda la matriz de dependencias de opam: el ecosistema tarda semanas en actualizar los `ppx`, que son lo primero que rompe.

**Estado real de OCaml 5 y su multicore — hay mucha confusión, esto es lo verificado.**
- **Dominios (paralelismo de memoria compartida)**: el runtime multicore es la razón de ser de OCaml 5 y está en producción desde 5.0. Un dominio ≈ un core; el número útil de dominios es el de cores disponibles, no "miles". Para concurrencia masiva se usan fibras/efectos **dentro** de un dominio, no un dominio por tarea.
- **Effect handlers**: introducidos en 5.0; **el soporte sintáctico de handlers profundos llegó en 5.3**. Y el punto crítico, citado literalmente del manual de OCaml 5.5: *"Unlike languages such as Eff and Koka, effect handlers in OCaml do not provide effect safety; the compiler does not statically ensure that all the effects performed by the program are handled."* Es decir: **los efectos NO están en el sistema de tipos.** Se declaran extendiendo la variante extensible `Effect.t`, y un efecto sin handler es un **fallo en tiempo de ejecución** (`Effect.Unhandled`), no un error de compilación. No hay calendario para un sistema de efectos tipado.
- Limitaciones que hay que conocer antes de diseñar con efectos: **no hay continuaciones multi-shot** (no sirven para backtracking); los efectos no se pueden realizar desde un handler de señal, un finalizador, un callback de memprof o una alarma de GC, y **no cruzan la frontera de `caml_callback`** (FFI).
- **Biblioteca estándar y paralelismo**: la `Stdlib` no ofrece estructuras concurrentes generales; el estado mutable compartido entre dominios es responsabilidad tuya (`Mutex`, `Atomic`, o estructuras de una librería). **No asumir que una librería del ecosistema es *domain-safe*: la mayoría se escribió asumiendo un solo hilo.** Cada dependencia que se comparta entre dominios se verifica explícitamente.
- Conclusión operativa: **usar efectos para concurrencia a través de una librería que los encapsule (Eio), no a pelo**. Escribir handlers propios es una decisión de arquitectura que requiere ADR y dueño.

**`Lwt` frente a `Async` frente a `Eio` — criterio.**
- **Proyecto nuevo sobre OCaml 5**: **Eio** (1.4, jul-2026). Es la vía nativa de efectos: código *directo* sin monada de promesas, cancelación estructurada, integración con io_uring. Coste: ecosistema menor y APIs que aún se mueven — leer el changelog antes de subir de versión.
- **Código existente o dependencia dura del ecosistema**: **Lwt** (6.1.2, MIT). Sigue vivo y es lo que asumen muchísimas librerías. Migrar a Eio es un proyecto, no un refactor.
- **`Async`**: solo dentro de una base de código que ya vive en el ecosistema Jane Street (`Core` + `Async` + sus ppx). No se elige `Async` a la ligera: arrastra la pila entera.
- **PROHIBIDO mezclar dos de estos en el mismo binario** sin una capa de puente explícita y documentada. Es la fuente número uno de deadlocks silenciosos en OCaml.

**Stdlib frente a Jane Street `Base`/`Core` — implicación real.**
- No es "una librería más": **`Base` está diseñada como reemplazo íntegro de la biblioteca estándar**. Tras `open Base`, los módulos y valores de la `Stdlib` quedan deprecados y hay que alcanzarlos vía `Stdlib.String`, `Stdlib.print_string`, etc. `Base` no reexporta lo no portable (I/O va aparte, en `stdio`). `Core` se apila encima y añade baterías (tiempo, contenedores, CLI, sexp).
- Lo que se gana: consistencia y seguridad reales — p. ej. la comparación polimórfica estructural de la `Stdlib`, que compila con cualquier tipo y hace lo que no esperas, en `Base` queda detrás de `Poly`. Y se abre la puerta al resto de la suite (Async, ppx_let, sexplib, bin_prot).
- Lo que se paga: **es una decisión de proyecto entera y de un solo sentido**. APIs divergentes que hay que reaprender, fricción con los ejemplos y librerías del resto del ecosistema, y un árbol de dependencias grande.
- **Criterio**: aplicación de un solo equipo, con gente dispuesta a aprender el dialecto ⇒ `Core` es defendible. **Librería publicada en opam ⇒ `Stdlib` (o como mucho `Base`)**: no se le impone al consumidor la elección de biblioteca base. Objetivos con restricción de portabilidad (js_of_ocaml, unikernels, embebido) ⇒ `Base` antes que `Core`. **Una sola elección por repositorio**, en un ADR.

### F#

| Pieza | Elección | Estado verificado (ago-2026) | Nota |
|---|---|---|---|
| Lenguaje | **F# 10** | sale con **.NET 10 (LTS)** y Visual Studio 2026 | Las features nuevas ya no necesitan `LangVersion=preview` en GA |
| SDK / runtime / soporte | **lo fija `dotnet-standards`** | — | El calendario LTS, `global.json` y el EOL no se deciden aquí |
| `FSharp.Core` | la que trae el SDK | — | Fijar una versión inferior a mano solo con motivo escrito |
| Formatter | **Fantomas** (Apache-2.0) | ver discrepancia abajo | `.editorconfig` para sus opciones; `.fantomasignore` versionado |
| Tests | **Expecto 11.1.0** (2026-06-17) | — | `xUnit`+`FsUnit` si el repo ya es .NET mixto |
| Property-based | **FsCheck 3.3.4** (2026-07-25) | — | El valor diferencial (§4) |
| Paquetes | NuGet — **gobernado por `dotnet-standards`** | — | Paket solo en repos que ya lo usan |

**Discrepancia declarada (Fantomas).** Las fuentes no concuerdan: NuGet mostraba como última versión **7.0.5 (2025-12-05)** mientras el repositorio de GitHub tiene *releases* fechadas en **abril de 2026**. No se fija número de versión aquí: **comprobar NuGet y GitHub antes de pinnearla** (§8). Lo que sí está verificado y es estable: **Fantomas está bajo Apache-2.0** (fichero `LICENSE.md` en crudo del repositorio).

**F# y su acoplamiento a .NET.** F# **no tiene versión independiente**: F# 10 es "el F# que trae el SDK de .NET 10". No se elige la versión de F#, se elige el SDK — y esa elección, con sus fechas de soporte, **es de `dotnet-standards`**. Consecuencias que sí son de aquí: `FSharp.Core` se actualiza con el SDK salvo pin explícito; las novedades de F# 10 relevantes al escribir código son el `#nowarn`/`#warnon` **con ámbito acotado** (suprimir un warning en una región en vez de en todo el fichero — usarlo así), la **validación de destino de atributos** (antes se aceptaban atributos mal colocados en silencio: al subir de SDK esto aparece como errores nuevos y es correcto), y `ParallelCompilation` como propiedad de proyecto (activada por defecto para `LangVersion=Preview` en .NET 10, con intención declarada de generalizarla en .NET 11 — verificar antes de asumirlo).

**`dotnet fsi` y scripting.** F# es la mejor opción de scripting del ecosistema .NET y hay que usarla como tal: `.fsx` con `#r "nuget: Paquete, X.Y.Z"` — **versión siempre explícita**, nunca `#r "nuget: Paquete"` a pelo, que resuelve lo último y no es reproducible. Los scripts que sobreviven a su primer mes se promueven a proyecto con tests; un `.fsx` de 500 líneas en producción es deuda. `dotnet fsi` es también la vía correcta de exploración interactiva (REPL con tipos reales), muy por delante de escribir un proyecto de consola desechable.

## 3. Estructura y convenciones

### OCaml

- Layout dune estándar: `lib/` (librería, todo lo importante), `bin/` (ejecutable fino), `test/`. `dune-project` en la raíz con `(lang dune 3.x)` fijado y **`(generate_opam_files true)`** para que los `*.opam` se deriven del `dune-project` en vez de divergir.
- **`.mli` obligatorio en todo módulo público.** No es burocracia: es el único punto donde se decide qué es API y qué es implementación, y el que hace que el `.ml` pueda cambiar sin romper a nadie. Un módulo sin `.mli` exporta todo lo que declara, incluidos los detalles.
- **Tipos abstractos por defecto**: `type t` en el `.mli` sin su definición, con constructores validadores. Es la versión OCaml de "estados imposibles irrepresentables", y es más fuerte que en la mayoría de lenguajes porque el compilador impide construir el valor de otro modo.
- Convención `t`: el tipo principal de un módulo se llama `t` (`User.t`, `Invoice.t`); las funciones toman `t` como último argumento para componer con `|>`.
- **El sistema de módulos y los functores son lo que de verdad diferencia a OCaml**, y es la razón técnica de elegirlo. Criterio de uso, no catálogo:
  - **`module type` (signatura) como contrato** es el mecanismo de inversión de dependencias del lenguaje. Se usa desde el principio: la capa de dominio depende de signaturas, no de implementaciones.
  - **Functor** = módulo parametrizado por otro módulo. Se justifica cuando hay **≥2 implementaciones reales** de la misma signatura (backend de almacenamiento real y en memoria, política de comparación, motor de BD) o cuando se quiere instanciar una estructura de datos sobre un tipo con sus operaciones (`Map.Make`, `Set.Make` — el uso canónico).
  - **Se veta functorizar "por si acaso"**: un functor con una sola instancia es indirección pura, empeora los mensajes de error y complica el `dune`. Empezar concreto, functorizar cuando aparezca la segunda implementación.
  - `include` para composición de módulos; el `open` global de un módulo grande en la cabecera de un fichero está desaconsejado (rompe el rastreo de dónde viene cada nombre) — `let open M in` acotado o `M.(...)`.
- **`.ocamlformat` versionado y con la versión de la herramienta fijada dentro** (`version = 0.29.0`): sin esa línea, dos máquinas con ocamlformat distinto producen diffs enormes y el gate de formato se vuelve inútil. Cambiar la versión es un commit propio que reformatea todo el árbol.
- Merlin/ocaml-lsp en todos los puestos, con la versión emparejada al compilador del switch.
- `ppx` con moderación: cada uno es código que se ejecuta en tiempo de compilación, ata el proyecto a la versión del compilador y suele ser lo primero que rompe al subir de OCaml. Aceptables los del núcleo del ecosistema (`ppx_deriving`, `ppx_yojson_conv`, `ppx_expect`); un ppx propio requiere ADR y dueño.

### F#

- **El orden de los ficheros en el `.fsproj` es semántico**: F# solo ve lo declarado antes. Eso fuerza un grafo de dependencias acíclico y es una ventaja de diseño, no un estorbo — se aprovecha ordenando `Domain → Application → Infrastructure → Api`.
- **Modelar el dominio con tipos, no con validaciones**: records para datos, **uniones discriminadas para alternativas**, tipos de un solo caso (`type Email = private Email of string`) con módulo compañero que expone `create : string -> Result<Email, Error>`. La regla operativa: **si un estado no debe existir, que no se pueda escribir**; los `bool` sueltos y los `string` con significado son el olor a evitar.
- **`Result<'T,'TError>` para fallos esperables del dominio, excepciones para lo excepcional.** Un tipo de error como unión discriminada por operación, no `string`. `Option` para ausencia legítima, nunca para señalar un fallo cuyo motivo importa.
- **Computation expressions**: usar las que existen antes de escribir una. `task { }` para asincronía (**preferida a `async { }` en código nuevo por interop directa con `Task` y menor coste**); `result { }`/`option { }` (FsToolkit o equivalente) para encadenar sin pirámide de `match`; `seq { }` para generación perezosa. **Escribir una CE propia requiere ADR**: es una API con reglas propias que todo el equipo debe aprender, y depurar dentro de una CE ajena es caro. Nunca una CE para lo que resuelve `|>` y `Result.bind`.
- **Type providers**: potentes y peligrosos. Aceptables para exploración y scripts (`.fsx` sobre CSV/JSON/SQL). En código de producción compilado, requieren ADR: **acoplan el build a un recurso externo vivo** (un esquema de BD, un fichero de muestra, un servicio), rompen builds reproducibles y offline, y algunos han quedado sin mantenimiento. Alternativa por defecto: generar los tipos en un paso explícito y versionarlos.
- **Frontera con C# — donde vive el peligro.** Todo lo que llegue desde C#/BCL es potencialmente `null` aunque el tipo diga que no; `Option` de F# **no** protege de eso.
  - **Toda entrada desde C# se normaliza en el borde**: `Option.ofObj`, `isNull`, comprobación de nulos en el constructor, y a partir de ahí el interior del módulo F# es null-free por construcción.
  - **Toda salida hacia C# se diseña como API de C#**: `Option<'T>` es incómodo desde C# (se ve como `FSharpOption<T>`) — exponer `TryGet` con `out`, o `null`, o un tipo propio; las uniones discriminadas y las tuplas de F# no se consumen bien desde C#; los módulos F# aparecen como clases estáticas. Si una librería F# es consumida por C#, **su superficie pública se diseña para C# y se prueba desde C#**, no se asume.
  - Nulabilidad de referencias: hay soporte moderno para anotar tipos anulables en F#; **verificar el estado exacto y la sintaxis en la versión del SDK antes de usarlo** (§8) — no aplicar de memoria.
- **Inmutabilidad por defecto**: `mutable`/`ref`/arrays mutables son decisiones con motivo, normalmente de rendimiento medido y acotadas a una función.

### [Ambos] Pattern matching exhaustivo como gate del compilador

Es la garantía más valiosa que dan estos dos lenguajes y **se convierte en error de compilación, siempre**:

- **OCaml**: `(flags (:standard -w +a-4-9-40-41-42-44-45 -warn-error +8))` — como mínimo, el warning 8 (*pattern-matching is not exhaustive*) y el 9 (campos de record no mencionados, si el estilo lo permite) tratados como error. Regla práctica: el conjunto exacto de warnings se acuerda una vez en `dune-project`/`dune` y no se relaja por fichero; `[@warning "-8"]` local requiere comentario-motivo.
- **F#**: `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` y, como mínimo, **FS0025** (*incomplete pattern matches*) y **FS0049**/**FS0064** vigilados. Con F# 10, suprimir uno concreto se hace con `#nowarn` **acotado por región** y `#warnon` para reactivarlo — no a nivel de proyecto.
- **PROHIBIDO el comodín `_` como rama por defecto sobre una unión discriminada / variante de dominio.** Es exactamente lo que desactiva la garantía: al añadir un caso nuevo, el compilador debe romper todos los sitios que hay que revisar. `_` solo sobre tipos abiertos o infinitos (enteros, cadenas) o sobre tipos que no controlas.
- Corolario de diseño: modelar con uniones/variantes cerradas en vez de enteros, cadenas o banderas booleanas. La exhaustividad solo protege si el tipo es cerrado.

## 4. Calidad y testing

### [Ambos] Property-based testing es el valor diferencial

En lenguajes con ADTs y funciones puras, generar casos es barato y encuentra lo que nadie escribe a mano. **No es opcional en código con invariantes.**

- **OCaml: QCheck** (integrable en Alcotest vía `qcheck-alcotest`). **F#: FsCheck 3.3.4** (integrable con Expecto y con xUnit).
- Propiedades obligatorias donde apliquen: **round-trip de serialización** (`decode (encode x) = x` para JSON, binario, persistencia), invariantes de los *smart constructors* (nada construido por la API pública viola la invariante), leyes de las operaciones propias (asociatividad, idempotencia, conmutatividad donde se afirmen), y equivalencia entre una implementación optimizada y una obviamente correcta.
- **Modelo de estado** (state-machine testing) para lógica con estado o concurrente: la única forma práctica de encontrar carreras y secuencias inválidas.
- Los generadores se escriben para producir **datos que respetan las precondiciones del dominio**, no `string` aleatorias que solo ejercitan la validación de entrada. Un generador flojo da una propiedad que siempre pasa y no prueba nada.
- El caso mínimo que reduce un fallo (*shrinking*) **se congela como test unitario de regresión**: la propiedad detecta, el test unitario documenta.

### OCaml — herramientas y gates

- **ocamlformat** con `.ocamlformat` versionado (versión fijada dentro). Gate: `dune build @fmt` / `dune fmt --preview` con fallo si hay diferencias.
- Tests: **Alcotest** (salida legible, buena integración con dune) o `ppx_expect` para tests de expectativa/golden — muy cómodos para salidas grandes y estables, y actualizables con `dune promote`; el riesgo es promocionar sin leer el diff: **revisar toda promoción en el PR**.
- **QCheck** para propiedades; `qcheck-alcotest` para verlas en la misma suite.
- Cobertura con `bisect_ppx` como señal, nunca como meta.
- Documentación con **odoc** compilando en CI (`dune build @doc`): un `.mli` bien documentado es el contrato.
- Gates de CI, en orden de coste:

```
dune build @fmt --diff-command=diff          # formato
dune build @all --profile release            # warnings como error (ver §3)
dune runtest                                 # unitarios + propiedades + expect tests
dune build @doc                              # odoc compila
opam lint *.opam                             # metadatos del paquete
# auditoría de dependencias: ver §5 y §8 (no hay `opam audit` a ago-2026)
```

### F# — herramientas y gates

- **Fantomas** como autoridad de formato (Apache-2.0), configurado por `.editorconfig`, con `.fantomasignore` versionado. Gate: `dotnet fantomas --check .`.
- **Expecto 11.1.0** por defecto en proyectos F#-first (tests como valores, composables, buena historia con FsCheck y con tests en paralelo). **xUnit + FsUnit** si el repositorio ya es .NET mixto y se quiere una sola infraestructura de test — coherencia por encima de preferencia.
- **FsCheck** integrado en la misma suite (`Expecto.FsCheck`).
- Warnings como error (§3) y análisis del SDK: la configuración del `.csproj`/`.fsproj` común, `Directory.Build.props` y los analizadores **son de `dotnet-standards`**; lo que fija esta skill es que **FS0025 no se ignora jamás**.
- Gate mínimo: `dotnet fantomas --check .` → `dotnet build -warnaserror` → `dotnet test`. La pipeline completa (SCA de NuGet, publish, contenedor) la define `dotnet-standards`.

### [Ambos] Estrategia de test

- Unitarios rápidos y deterministas sobre la lógica pura, que es la mayoría del código si el diseño es correcto: dominio puro, efectos en el borde.
- **Bordes y errores** obligatorios: entradas vacías, límites numéricos, decodificación inválida, timeouts, cancelación, unicode.
- Integración con la dependencia real (misma versión de motor que producción) antes que mocks del driver; mockear las fronteras propias (una signatura de módulo en OCaml, una interfaz o función inyectada en F#), no el mundo.
- Todo bugfix deja test de regresión que falla antes del fix. Test flaky: se arregla o se borra.

## 5. Seguridad del stack

### OCaml

- **`Marshal` sobre entrada no confiable — PROHIBIDO. Es ejecución de código, no deserialización.** `Marshal.from_string`/`from_bytes`/`from_channel` e `input_value` reconstruyen valores del runtime sin validar tipos: un dato manipulado corrompe el heap y desde ahí se llega a ejecución arbitraria. Precedente verificado: **OSEC-2026-01 / CVE-2026-28364**, *buffer over-read* en `runtime/intern.c` (falta de validación de límites en `readblock()`, `memcpy()` con longitudes controladas por el atacante), corregido en **OCaml 5.4.1 y 4.14.3 (2026-02-17)**. Y el matiz que zanja la discusión: el propio aviso deja constancia de que **`Marshal.from*` e `input_value` siguen siendo inseguros de usar** — el arreglo endurece el runtime, no convierte la API en segura. Para datos que cruzan una frontera de confianza: formato explícito y parseado (JSON con `yojson`/`ppx_yojson_conv`, `bin_prot` con tipos conocidos y validación, protobuf), con límites de tamaño y profundidad.
- **`Obj.magic` y el módulo `Obj` — PROHIBIDO.** Anula el sistema de tipos completo; el resultado no es un error de tipos, es corrupción de memoria y un fallo a mil líneas del origen. Sin excepciones en código de aplicación. En una librería de muy bajo nivel: bloque mínimo, encapsulado tras un `.mli` que expone una API segura, comentario que demuestre la invariante de representación, y test. `Obj.magic` para "callar al compilador" es un bug esperando fecha.
- **opam ≥ 2.5.2 como mínimo de seguridad.** Verificado: **OSEC-2026-10 / CVE-2026-57825** — escape del *sandbox* de instalación de opam mediante enlaces simbólicos (los ficheros `.install` no comprobaban la resolución del symlink del destino), corregido en **opam 2.5.2 (2026-07-08)**; y **CVE-2026-41082** (DSA-6216-1 de Debian), directivas de `.install` insuficientemente restringidas que permitían salir del área del paquete. Lectura correcta: **`opam install` ejecuta código de terceros en tu máquina y en tu runner de CI**; el sandbox es una mitigación, no una barrera.
- **Auditoría de dependencias de opam — estado real, sin adornos.** Existe la **OCaml Security Advisory Database** (`github.com/ocaml/security-advisories`), mantenida por el equipo de seguridad de OCaml, que alimenta a **osv.dev**; el propio repositorio se describe como *work in progress*. **A ago-2026 NO existe un comando `opam audit` publicado**: está propuesto y en discusión, no entregado. Criterio operativo mientras tanto: consumir la base vía OSV en el gate de CI (escáner genérico que lea OSV), suscribirse al canal de anuncios de seguridad de OCaml, y **fijar el switch con `opam.locked` versionado** para que la superficie sea conocida y revisable. Verificar el estado de la herramienta antes de escribir el gate (§8).
- FFI (C stubs): frontera de memoria sin red de seguridad. Revisión específica, `[@@noalloc]` solo si es cierto, y recordar que los efectos no cruzan `caml_callback`.
- SQL solo parametrizado (`caqti` y similares). Nada de concatenar consultas.

### F#

- **La seguridad del stack .NET —NuGet y su auditoría, secretos, ASP.NET Core, cabeceras, hardening del contenedor— es de `dotnet-standards`.** Aquí solo lo específico del lenguaje:
- **Deserialización**: `System.Text.Json` con tipos concretos. Las uniones discriminadas **no serializan de forma obvia** — requieren convertidor explícito (`FSharp.SystemTextJson` o equivalente); improvisar un formato de DU en el borde de una API es una fuente clásica de incompatibilidad y de aceptar payloads inesperados. **Prohibido `BinaryFormatter`** y toda deserialización polimórfica abierta.
- **Nulos como problema de seguridad, no de estilo**: un `null` que entra desde C#/BCL en un valor F# que el tipo declara no anulable produce `NullReferenceException` en el sitio equivocado, y en el peor caso salta una validación. La normalización en el borde (§3) es un control, no una cortesía.
- **Auditoría de NuGet**: la fija `dotnet-standards` (NuGetAudit, lockfiles, CPM). Lo que añade esta skill: **las librerías del ecosistema F# son proyectos comunitarios pequeños** — antes de fijar una, verificar mantenimiento, licencia (leyendo el `LICENSE` real, no el campo del paquete) y si tiene sustituto en la BCL. Precedente del catálogo: herramientas que cambian de licencia o se declaran *feature complete* con acción comercial.

### [Ambos]

- Validación en el borde con tipos: el *smart constructor* que devuelve `Result`/`option` es el control de entrada. Nada de "ya lo validará la capa de arriba".
- Secretos nunca en el árbol, en logs ni alcanzables por un `%A`/derivación automática de impresión: los tipos que contengan credenciales llevan impresión redactada explícita.
- Cripto: librería mantenida del ecosistema respectivo, verificada en el momento (§8). Nada casero, nada de MD5/SHA-1/DES/ECB, TLS 1.2+.

## 6. Rendimiento y operabilidad

### OCaml

- **Dominios ≈ cores.** El número de dominios se dimensiona por CPUs disponibles y **se ajusta al límite del contenedor**, no a la máquina física; sobre-suscribir dominios degrada por contención de GC. La concurrencia de muchas tareas se hace con fibras/efectos dentro del dominio (Eio), no con un dominio por tarea.
- Estado compartido entre dominios: `Atomic`, `Mutex`, o estructuras concurrentes de librería, **con la seguridad de la dependencia verificada explícitamente** (§2). Compilar y ejecutar con **TSan** el código que comparta estado entre dominios; hay soporte y se usó para arreglar bugs reales del propio runtime.
- GC: el generacional de OCaml es de pausas cortas por diseño, pero se mide antes de afirmarlo. Palancas (`OCAMLRUNPARAM`: `s` tamaño del vivero, `o` overhead del major) **solo con medición**, no copiadas de un blog.
- Perfilado: `perf` sobre el binario nativo, `landmarks`/`memtrace` para asignación. `dune build --profile release` para producción; el perfil `dev` lleva aserciones y menos optimización.
- **Compilación a JavaScript: `js_of_ocaml`** — compila el bytecode a JS y es la vía madura para reutilizar dominio OCaml en el navegador (o `wasm_of_ocaml` para WebAssembly; verificar madurez antes de comprometerse — §8). Criterio: **compartir el núcleo de dominio entre servidor y cliente es el caso de uso legítimo**; escribir una SPA entera en OCaml es una decisión de equipo del mismo calibre que la de §7. El tamaño del bundle se mide y se vigila en CI.
- Observabilidad: logging estructurado (`logs` con un reporter JSON) y métricas del proceso; verificar el estado del binding de OpenTelemetry antes de comprometerse (§8). Timeouts explícitos en toda operación de red; cancelación estructurada con Eio (`Switch`) o `Lwt.cancel` con cuidado. Apagado ordenado con manejo de `SIGTERM` que drena antes de cerrar.

### F#

- **Casi todo lo operativo lo fija `dotnet-standards`** (observabilidad, health checks, timeouts y resiliencia de `HttpClient`, límites, apagado ordenado, contenedor, AOT). Lo específico del lenguaje:
- **`task { }` sobre `async { }`** en código nuevo: menos asignaciones y frontera directa con el `Task` del resto del ecosistema. Convertir en el borde, no salpicar conversiones por el código.
- **Asignación**: los records, las uniones discriminadas y las tuplas son de referencia por defecto; en rutas calientes **medidas**, valorar `[<Struct>]` en DUs y records pequeños, y `struct` tuples. Nunca sin BenchmarkDotNet delante.
- Listas de F# (`list`) son listas enlazadas inmutables: excelentes para el dominio, malas para colecciones grandes con acceso indexado o construidas por concatenación repetida. `array`/`ResizeArray` en el interior de una función caliente es aceptable si el resultado sale inmutable.
- `Seq` es perezosa y **se puede enumerar dos veces**: materializar antes de reutilizar; un `Seq` sobre un recurso ya cerrado es un bug clásico.
- Compilación: `ParallelCompilation` (§2) reduce el tiempo de build en proyectos grandes; verificar el default de la versión del SDK antes de asumirlo.

## 7. Sostenibilidad a largo plazo

- **Riesgo de equipo, con perfiles distintos.** **OCaml**: comunidad pequeña, contratación difícil, y la mayor parte del ecosistema industrial gravita alrededor de una empresa (Jane Street) cuyas librerías son excelentes pero definen un dialecto. Aplica el mismo listón que en `haskell-fp-standards`: **bus factor ≥3 y presupuesto de formación antes de aprobar el stack**. **F#**: el riesgo es menor porque el runtime, el tooling, el hosting y la contratación .NET son mainstream; el riesgo real es **quedar como el único proyecto F# en un departamento de C#**, sin nadie que lo revise ni lo mantenga. Mitigación honesta: F# gana cuando el equipo ya es .NET y el problema es de modelado del dominio; si no hay ni una persona más que lea F#, la respuesta es C# con buen modelado.
- **Cadencia de upgrades.** OCaml: menor vigente + parche sin demora; el salto de menor se prueba antes por los `ppx` y por las dependencias de opam, que son el cuello de botella real. `opam.locked` versionado y actualizado en un PR propio, no mezclado con features. F#: la cadencia la marca el SDK y **la fija `dotnet-standards`** (LTS a LTS); lo de aquí es revisar los warnings nuevos que trae cada versión del compilador de F# — la validación de destino de atributos de F# 10 es el ejemplo: aparecen errores que antes eran silencio, y arreglarlos es lo correcto.
- **Documentación como mitigación**: `.mli` documentados con odoc en OCaml, firmas y XML doc en F#; ADRs de las decisiones estructurales (Stdlib frente a Core; Eio frente a Lwt; type providers sí o no; Expecto frente a xUnit) y un `CONTRIBUTING` que arranque de cero (`opam switch create . --deps-only` / `dotnet restore`).
- **Deuda consciente**: todo atajo con `TODO(usuario): motivo — issue`. Ningún warning silenciado sin comentario y enlace.

**PROHIBICIONES (requieren ADR y aprobación para excepcionar).**
- ❌ **[OCaml] `Marshal.from*` / `input_value` sobre datos que cruzan una frontera de confianza.** Es ejecución de código. El endurecimiento de 5.4.1/4.14.3 no lo convierte en seguro.
- ❌ **[OCaml] `Obj.magic` y el módulo `Obj`** en código de aplicación; `Obj.magic` para acallar el compilador.
- ❌ **[Ambos] Comodín `_` como rama por defecto sobre una unión/variante de dominio**; desactivar el warning de exhaustividad (OCaml warning 8, F# FS0025) a nivel de proyecto.
- ❌ [Ambos] Warnings sin `-warn-error` / `TreatWarningsAsErrors`; supresión global de un warning que se resuelve acotándolo.
- ❌ [OCaml] Proyecto sin `opam` + `dune`; Makefiles artesanales sobre `ocamlfind`; `ocamlbuild`.
- ❌ [OCaml] `.ocamlformat` sin la versión de la herramienta fijada; módulo público sin `.mli`.
- ❌ [OCaml] Mezclar Lwt, Async y Eio en el mismo binario sin puente explícito y documentado; escribir handlers de efectos propios sin ADR.
- ❌ [OCaml] Asumir que una librería es *domain-safe* sin comprobarlo; compartir estado entre dominios sin `Atomic`/`Mutex` y sin pasar TSan.
- ❌ [OCaml] Functorizar con una sola implementación; `open` global de módulos grandes.
- ❌ [OCaml] opam < 2.5.2 (escape de sandbox, §5); OCaml 4.x en un proyecto nuevo; instalar dependencias en CI sin lock versionado.
- ❌ [F#] `Option`/uniones discriminadas expuestas crudas en una API pensada para consumo desde C#, sin prueba desde C#.
- ❌ [F#] Consumir valores de C#/BCL sin normalizar nulos en el borde.
- ❌ [F#] `#r "nuget: X"` sin versión en scripts; `.fsx` de producción sin promover a proyecto con tests.
- ❌ [F#] Type providers en código de producción compilado sin ADR (acoplan el build a un recurso externo).
- ❌ [F#] Computation expression propia sin ADR; CE para lo que resuelve `|>` + `Result.bind`.
- ❌ [F#] `BinaryFormatter`; DUs serializadas sin convertidor explícito.
- ❌ [F#] Decidir aquí lo que decide `dotnet-standards` (SDK, LTS, NuGet, ASP.NET Core, contenedor): es una violación de frontera, no un atajo.
- ❌ [Ambos] `string`/`bool`/`int` como sustituto de un tipo del dominio cuando existe una variante cerrada.
- ❌ [Ambos] Property-based testing ausente en código con invariantes; caso reducido por *shrinking* sin congelar como regresión.

**Cuándo NO elegir estos lenguajes (prohibición honesta).**
- ❌ **OCaml** cuando no hay bus factor ≥3, cuando el equipo no puede sostener un ecosistema pequeño, o cuando el proyecto depende de SDKs cloud/ML de primera línea que en OCaml no existen o son wrappers de terceros. Tampoco si el trabajo es glue de infraestructura → `go-standards`/`python-standards`.
- ❌ **OCaml** si el requisito es paralelismo con estructuras concurrentes maduras "de fábrica": OCaml 5 da el runtime, pero el ecosistema aún asume un solo hilo en muchos sitios.
- ❌ **OCaml y F#** para latencia dura / tiempo real: los dos tienen GC → `rust-standards`.
- ❌ **F#** cuando no hay una segunda persona en la organización capaz de leerlo y revisarlo. Un servicio F# aislado en una casa de C# es deuda organizativa, por buena que sea la solución.
- ❌ **F#** si la decisión real es "quiero funcional en .NET" sin un problema de modelado que lo justifique: C# moderno con records, patrones y nullable references cubre mucho.
- ❌ Cualquiera de los dos elegido "porque el equipo quiere aprender" en un sistema con SLA.

## 8. Verificación web obligatoria

Antes de fijar versión, flag o afirmar el estado del ecosistema, **verificar por web** (no de memoria):

1. **OCaml vigente y estado de la 4.x**: `ocaml.org/releases` y `ocaml.org/changelog`; anuncios en `discuss.ocaml.org`. ¿Sigue 5.5.0 siendo la última? ¿Ha salido 5.6? ¿Ha terminado el mantenimiento de 4.14 (anunciado *al menos* hasta finales de 2026)?
2. **Qué es realmente estable de OCaml 5 hoy**: manual oficial de la versión concreta (`ocaml.org/manual/5.x/effects.html`) — **releer la frase sobre *effect safety* antes de afirmar nada**; a ago-2026 los efectos **no están tipados** y no hay calendario para que lo estén. Comprobar también el estado de continuaciones multi-shot y de las restricciones sobre `caml_callback` y señales.
3. **Seguridad de OCaml y opam**: `github.com/ocaml/security-advisories` y OSV. Verificado a ago-2026: **OSEC-2026-01 / CVE-2026-28364** (Marshal, corregido en 5.4.1 / 4.14.3) y **OSEC-2026-10 / CVE-2026-57825** (escape de sandbox de opam, corregido en **opam 2.5.2**, 2026-07-08). Comprobar si ya existe **`opam audit`** — a ago-2026 está **propuesto pero no entregado**, y ese es el hueco del gate de SCA.
4. **Tooling OCaml**: dune (3.24.0, 2026-06-30), ocamlformat (0.29.0, 2026-03-17), opam (≥2.5.2), Merlin (5.7.1-504) y ocaml-lsp (1.26.0). Merlin va emparejado a la versión de compilador: comprobar el sufijo.
5. **Concurrencia OCaml**: Eio (1.4, 2026-07-23) y Lwt (6.1.2 en opam, 2026-04-29, MIT). El feed de releases de Lwt mezcla líneas 5.x y 6.x — **contrastar con `ocaml.org/p/lwt`, que es la fuente correcta**. Estado y madurez de Async fuera del ecosistema Jane Street.
6. **F# y su SDK**: la versión de F# la trae el SDK — verificar en `learn.microsoft.com/dotnet/fsharp/whats-new` cuál trae el SDK vigente (a ago-2026: **F# 10 con .NET 10 LTS**) y **las fechas de soporte de ese SDK en `dotnet-standards`**, no aquí. Confirmar el default de `ParallelCompilation` en la versión concreta y el estado de la anotación de referencias anulables en F#.
7. **Tooling F# y licencias**: **Fantomas — verificado Apache-2.0; discrepancia de versión declarada en §2 (NuGet 7.0.5 de dic-2025 frente a releases de GitHub de abr-2026): comprobar ambas fuentes antes de pinnear.** Expecto (11.1.0, 2026-06-17) y FsCheck (3.3.4, 2026-07-25): versiones verificadas, **licencias NO verificadas**. FsUnit y FsToolkit: sin verificar. Precedentes que obligan a mirar la licencia y el modo de mantenimiento antes de fijar una herramienta: Trivy (cambio de licencia), gitleaks (*feature complete* + acción con licencia comercial para organizaciones desde v2).

**Huecos declarados (no verificados a ago-2026, no rellenar de memoria):**
- Versiones y estado de mantenimiento de **Alcotest, QCheck, ppx_expect, bisect_ppx, odoc, yojson, caqti, Dream/opium** y del binding **OpenTelemetry** para OCaml.
- Estado y licencia de **Jane Street `Base`/`Core`/`Async`** y su versión actual; los argumentos de §2 sobre el coste de adopción provienen de discusión comunitaria en buena parte anterior a 2022 y **deben reconfirmarse con datos actuales** (p. ej. dependencias inversas en opam).
- Madurez actual de **`js_of_ocaml`** y, sobre todo, de **`wasm_of_ocaml`** (versión, limitaciones, tamaño de salida).
- Licencias de **Expecto, FsCheck, FsUnit, FsToolkit.ErrorHandling** y estado de mantenimiento de **FSharp.SystemTextJson** y de los type providers habituales.
- Versión exacta de **Fantomas** (ver discrepancia) y estado del soporte de nulabilidad de referencias en F#.
- Existencia y nombre definitivo de una herramienta de auditoría de opam.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
