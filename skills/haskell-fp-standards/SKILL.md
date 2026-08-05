---
name: haskell-fp-standards
description: Haskell production engineering standards. Trigger on .hs/.lhs files, .cabal files, cabal.project/cabal.project.freeze, stack.yaml/stack.yaml.lock, package.yaml (hpack), hie.yaml, fourmolu.yaml/.ormolu, .hlint.yaml, ghcup/GHC toolchain pins, Stackage resolvers, and packages like base, text, bytestring, containers, aeson, servant, persistent, conduit, streaming, mtl, effectful, cleff, fused-effects, relude, rio, hspec, tasty, QuickCheck, hedgehog, criterion, async, stm. Apply when writing, reviewing or setting up CI for Haskell, and when deciding whether a team should adopt Haskell at all.
---

# Estándares Haskell en producción

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo en Haskell: `.hs`/`.lhs`, ficheros `.cabal`, `cabal.project` y `cabal.project.freeze`, `stack.yaml`/`stack.yaml.lock`, `package.yaml` (hpack), `hie.yaml`, `fourmolu.yaml`, `.hlint.yaml`, pins de GHCup y resolvers de Stackage, y las pipelines que compilan/testean Haskell. Cubre servicios backend, CLIs, compiladores/DSLs y librerías publicadas en Hackage.

**El eje de esta skill: adoptar Haskell en producción es una decisión de equipo antes que técnica.** El lenguaje no es el riesgo — el riesgo es el *bus factor*, la curva de entrada, el mercado de contratación y los tiempos de compilación. Un servicio Haskell bien escrito por una persona que se va es un pasivo, no un activo. Antes de escribir la primera línea hay que poder responder: ¿hay ≥3 personas que puedan operar y modificar esto?, ¿el equipo acepta un CI de 10-30 min en un build limpio?, ¿existe presupuesto de formación? Si la respuesta es no, la decisión correcta es otro lenguaje (§7). Donde Haskell gana de verdad: compiladores/parsers/DSLs, lógica de negocio con invariantes densas, transformación de datos correcta-por-construcción, y equipos que ya lo dominan. Donde no gana: CRUD sin invariantes, glue de infraestructura, código que rotará entre muchas manos.

**No aplica**: ver `ocaml-fsharp-standards` (los ML estrictos — la frontera es **pereza frente a evaluación estricta** y la clase de sistema de tipos: type classes + higher-kinded types + `IO` monádico aquí, módulos/functores y efectos por *handlers* allí; no "los dos son funcionales"), `scala-standards` (*Ola 5, ya escrita* — el otro funcional con type classes: la frontera es el **runtime JVM** y la interop Java como requisito de diseño, más su elección de ecosistema Typelevel/ZIO; `cats-effect`/`fs2` son suyos aunque el estilo se parezca), `rust-standards` (comparte ADTs y linaje ML: la frontera es el **modelo de memoria** —ownership/sin GC frente a GC + pereza— y el propósito: sistemas y latencia acotada frente a corrección de la lógica), `jvm-spring-standards` (*Ola 5, ya escrita* — solo si el problema entra por JVM/Spring), `iac-standards` (**Nix como gestor de infraestructura/despliegue es suyo; Nix como toolchain reproducible de este proyecto Haskell —`flake.nix`, `haskell.nix`, shells de desarrollo— es de esta skill**), `cicd-standards` (la pipeline que ejecuta los gates y su caché), `kubernetes-standards` (imagen OCI y despliegue del binario), `api-design-standards` (el contrato HTTP/gRPC — aquí solo su implementación con servant/wai), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas; aquí solo los sinks concretos de Haskell), `vulnerability-management-standards` (triaje y SLA de CVEs; aquí solo `cabal audit`/advisory-db en el gate), `secrets-management-standards` (dónde viven los secretos; aquí solo no filtrarlos por `Show`), `observability-standards` (pipeline OTel y SLOs; aquí solo la instrumentación y las métricas del RTS), `sql-standards` (*Ola 5, ya escrita* — el SQL que generen persistent/esqueleto/hasql), `python-standards`/`go-standards`/`typescript-standards` (la alternativa real cuando §7 dice que no toca Haskell).

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Lo de abajo es el estado verificado a **ago-2026**.

| Pieza | Elección | Estado verificado (ago-2026) | Criterio |
|---|---|---|---|
| Instalador | **GHCup** | único soportado; Haskell Platform muerto hace años | Nunca GHC del gestor de paquetes de la distro |
| Compilador | **GHC 9.14.x (primera release LTS)** | 9.14.1 publicada 2025-12-19; 9.14.2-rc1 en curso | LTS ⇒ ≥2 años de bugfixes; **no la más nueva, la LTS** |
| GHC vivos | 9.14 (LTS), 9.12.4, 9.10.3, 9.8.4, 9.6.7 | 9.4 y anteriores **EOL** | ≤9.4 en producción = sin parches |
| Edición | **`GHC2024`** declarada explícitamente | introducida en GHC 9.10.1; **el default sigue siendo `GHC2021`** | El default puede cambiar: fijar la edición siempre |
| Build | **cabal-install 3.18.x** | 3.18.1.0 (2026-07-29) | Default sobrio: GHCup + cabal |
| Build alt. | **Stack 3.11.x** | 3.11.1 (2026-06-15) — **activo, no abandonado** | Solo si se quiere el conjunto curado como modelo de build |
| Conjunto de deps | **Stackage LTS** como oráculo de compatibilidad | LTS 24.x ⇒ ghc-9.10.3; Nightly 2026-08-01 ⇒ ghc-9.12.4 | Ver la discrepancia LTS-de-GHC vs LTS-de-Stackage abajo |
| IDE | **HLS (haskell-language-server)** | 2.14.0.0 (2026-04-27) | Instalado por GHCup, versión atada al GHC |
| Formatter | **fourmolu** | 0.20.0.0 (2026-06-18), BSD-3-Clause | `ormolu` si se quiere cero configuración; uno solo por repo |
| Linter | **hlint** | 3.10 (2025-02-02), BSD-3-Clause | Cadencia baja: útil pero **verificar antes de fijarlo como gate duro** |
| Efectos | **`ReaderT Env IO`** | — | `effectful` 2.6.1.0 (2025-08-30, BSD-3) si el default no basta |
| Tests | **hspec** o **tasty** + **QuickCheck**/**Hedgehog** | verificar versiones (§8) | Property-based no es opcional (§4) |

**Discrepancia declarada (importante).** Hay **dos nociones de "LTS" que no coinciden**: la LTS de GHC (9.14, desde dic-2025) y la LTS de Stackage (serie 24, construida sobre ghc-9.10.3 a ago-2026). Adoptar GHC 9.14 hoy significa **salir del conjunto curado de Stackage** y resolver dependencias con el solver de cabal + freeze propio. Decisión por defecto: **el GHC lo fija la disponibilidad de un snapshot curado que compile tus dependencias**, no el número más alto. Documentar la elección en un ADR y revisarla cuando Stackage promocione una LTS sobre 9.14.

**Política de upgrade de GHC.** LTS-a-LTS. Las no-LTS salen ~cada 6 meses con vida corta; el solapamiento entre LTS consecutivas es de ~6 meses, y esa es la ventana de migración real. Adoptar una `.1` en producción es innecesario: esperar a `.2`/`.3`. Cada salto se prueba primero en una rama de CI con la matriz completa (`-Wall -Werror` incluido) porque **`-Wall` gana warnings nuevos entre versiones** — ejemplo verificado: `-Wincomplete-record-selectors` entró en `-Wall` en GHC 9.14, y las librerías con `-Werror` rompen por eso.

**GHCup / Stack / Cabal / Nix — criterio real, no catálogo.**
- **GHCup + cabal**: default. Menos piezas, es lo que asume el resto del ecosistema y HLS.
- **Stack**: elegir solo si el valor es *el conjunto curado como modelo de build* (equipo grande, muchos repos, deseo de "un resolver y punto"). Sigue activo (3.11.1, jun-2026) — no es una decisión de legado. No mezclar los dos en el mismo repo.
- **Nix** (`flake.nix` + `haskell.nix` o `nixpkgs`): solo cuando el requisito es **bit-reproducibilidad o dependencias de sistema no-Haskell no triviales** (libpq, ICU, ffmpeg, cross-compilación). Nix multiplica por dos la superficie de tooling que el equipo debe saber depurar; entra con un dueño designado o no entra. Si entra, entra para todos: nada de "unos con Nix y otros con cabal" — el `shell.nix`/devShell es el entorno canónico y CI usa el mismo.

**Stackage frente a Hackage — cómo se fija un conjunto reproducible.**
- **Hackage** es el registro (sin curar, cualquiera publica). **Stackage** es un conjunto de versiones *verificadas por compilar juntas* contra un GHC concreto; los snapshots son **inmutables** una vez publicados.
- Con Stack: `resolver: lts-XX.YY` + `stack.yaml.lock` versionado. Extra-deps de Hackage con hash, y cada una es deuda a justificar.
- Con cabal: `cabal.project` puede importar el snapshot de Stackage como `import: https://www.stackage.org/lts-XX.YY/cabal.config` y **además** se versiona `cabal.project.freeze` (`cabal freeze`). Sin freeze no hay build reproducible: el solver resolverá distinto mañana.
- Regla: **el lockfile/freeze se versiona siempre**, también en librerías (para su CI; la librería publica rangos, no pins).
- Dependencia fuera del snapshot ⇒ decisión explícita: mirar mantenimiento, licencia y árbol transitivo. Ningún `git:` sin `--sha256`/rev fijado.

## 3. Estructura y convenciones

- Layout: `src/` (librería), `app/` (ejecutable fino), `test/`, `bench/`. **Toda la lógica vive en la librería**; el ejecutable solo parsea CLI, construye el `Env` y llama a `main`. Esto es lo que hace testeable y reusable el código, y lo que evita el `Main.hs` de 2000 líneas.
- Multipaquete desde que hay dos límites reales: `cabal.project` con `packages: ./pkg-*`. `common` stanzas en el `.cabal` para no repetir `ghc-options`/`default-extensions`.
- Módulos por **dominio**, no por tipo técnico (`Billing.Invoice`, no `Types`/`Utils`). Listas de exportación explícitas en todo módulo: la API es una decisión, no un accidente.
- Tipos primero: newtypes sobre primitivos (`newtype UserId = UserId UUID`), *smart constructors* que validan en el borde, estados imposibles irrepresentables con ADTs. `NonEmpty` en vez de "lista que nunca está vacía". El sistema de tipos es la primera capa de tests.
- Campos de records **estrictos por defecto** (`!Int`) en tipos de datos de dominio; `StrictData` por módulo cuando el tipo es un contenedor de datos.
- `deriving stock`/`newtype`/`anyclass` **siempre explícito** (`DerivingStrategies` ya viene en `GHC2024`): el deriving implícito es ambiguo al leer.

### Extensiones de lenguaje

- **Declarar `default-language: GHC2024`** en el `.cabal`. Verificado: `GHC2024` se introdujo en GHC 9.10.1 y **añade sobre `GHC2021`**: `DataKinds`, `DerivingStrategies`, `DisambiguateRecordFields`, `ExplicitNamespaces`, `GADTs`, `MonoLocalBinds`, `LambdaCase`, `RoleAnnotations`. El default de GHC sin declarar nada **sigue siendo `GHC2021`** (por compatibilidad), por eso se declara.
- Si el proyecto está atado a GHC <9.10: `GHC2021` + `default-extensions` mínimas.
- Añadidos habitualmente sanos por proyecto: `OverloadedStrings`, `StrictData`, `DerivingVia`, `TypeFamilies` (si el diseño lo pide).
- **Vetadas por coste de mantenimiento** (requieren ADR y dueño): `UndecidableInstances`, `IncoherentInstances`, `OverlappingInstances`/`{-# OVERLAPPING #-}` a granel, `AllowAmbiguousTypes` como parche a un diseño confuso, `ImpredicativeTypes`, `TemplateHaskell` fuera de lo que ya lo exige (aeson/persistent/lens) — TH cuesta tiempo de compilación, rompe cross-compilación y es opaco al depurar. `CPP` solo para bandas de compatibilidad de versión, nunca para lógica.
- `unsafeCoerce` y `GeneralizedNewtypeDeriving` sobre clases con métodos peligrosos: PROHIBIDO sin justificación escrita (§7).

### `String` / `Text` / `ByteString`

- **`String = [Char]` es un bug de rendimiento por defecto**: lista enlazada de caracteres boxed, un cons-cell por carácter. No es una elección de estilo.
- **`Text`** (`text`, UTF-8 desde text-2.0) para **todo texto humano**. **`ByteString`** para **bytes** (I/O, red, binario, ficheros). `String` solo en la frontera con APIs antiguas (`FilePath`, `Show`, algunas de `base`) y se convierte de inmediato.
- `OverloadedStrings` activado; literales sin `pack` disperso.
- Lazy frente a strict: `Data.Text` / `Data.ByteString` estrictos por defecto; las variantes `.Lazy` solo para *streaming* de datos grandes que no caben en memoria, y entonces con criterio explícito.
- Decodificación de bytes a texto **siempre con manejo de error explícito** (`decodeUtf8'`/`decodeUtf8With`), nunca `decodeUtf8` sobre entrada no confiable: lanza excepción imposible de capturar en código puro.
- Rutas de fichero: `OsPath`/`OsString` cuando el proyecto toque rutas no-ASCII o binarias; `FilePath = String` es la trampa clásica.

### Pereza y fugas de espacio — categoría de bug de primera clase

La pereza es la característica distintiva del lenguaje y la **primera fuente de incidentes de producción**: un thunk acumulado no falla en tests, falla a las 6 horas con el heap lleno.

- **`foldl` está vetado.** Usar `foldl'`. Verificado: `foldl'` se exporta desde `Prelude` a partir de **base-4.20 (GHC 9.10)** (CLC #167) — antes hay que importarlo de `Data.List`/`Data.Foldable`. En GHC <9.10 el import explícito es obligatorio; nada de "es que no estaba a mano".
- Acumuladores estrictos: `BangPatterns` (`go !acc x = ...`), `seq`/`force` (`deepseq`) donde el acumulador sea estructurado.
- Estructuras: `Data.Map.Strict` y `Data.IntMap.Strict` por defecto — la variante lazy solo con motivo. `modifyIORef'`/`atomicModifyIORef'`, nunca las versiones lazy. `foldl'` sobre `Map`, no `foldr` acumulando.
- Campos de record que acumulan estado: **estrictos** (`!`) o `StrictData`. `State` lazy es un generador de fugas: usar `Control.Monad.State.Strict`.
- **Perfilado de heap como herramienta rutinaria, no de emergencia**: build con `-prof -fprof-auto`, ejecutar con `+RTS -hc -hy -hb -l-au`, visualizar con `eventlog2html`/`hp2ps`; `ghc-debug` para inspeccionar el heap de un proceso vivo. Todo servicio de larga vida se perfila **antes** de salir a producción, no después del primer OOM.
- Métrica operativa: `live bytes` del RTS con tendencia creciente y sostenida = fuga hasta que se demuestre lo contrario (§6).
- `-Wall` no detecta fugas de espacio. No hay linter que sustituya al perfilado.

### `Prelude` alternativo

- Default: **`Prelude` estándar**. Un `Prelude` custom es una barrera de entrada para cada persona nueva y una fuente de fricción con ejemplos y librerías.
- **`relude`**: elegible en un proyecto nuevo y greenfield donde el equipo lo acuerde — quita las funciones parciales, usa `Text` por defecto, trae `NonEmpty`. Se declara con `mixins`/`NoImplicitPrelude` de forma uniforme en todo el repo.
- **`rio`**: elegible si además se adopta su arquitectura (`RIO env`, logging, manejo de recursos) como un todo. Adoptar `rio` solo por el Prelude es pagar el coste sin el beneficio.
- Regla dura: **cero o uno**. Nunca dos preludios distintos en el mismo árbol, ni un módulo `MyProject.Prelude` casero que crezca sin dueño.

### Manejo de errores

- Dos ejes distintos que no hay que mezclar: **fallos esperables del dominio** frente a **fallos excepcionales/de infraestructura**.
- Dominio ⇒ **tipos**: `Either MiError a`, `ExceptT MiError` en la capa que lo necesite, ADT de error por operación. El llamante hace pattern matching y el compilador comprueba la exhaustividad.
- Infraestructura (I/O, red, disco, timeouts, `bracket`) ⇒ **excepciones de `IO`**, que en Haskell son inevitables (async exceptions incluidas). Capturar con `safe-exceptions` (o `Control.Exception` con criterio): **`bracket`/`finally` para todo recurso**, nunca `catch` sobre `SomeException` que trague también las asíncronas (`ThreadKilled`, timeouts).
- **PROHIBIDOS en código de producción**: `error`, `head`, `tail`, `init`, `last`, `fromJust`, `read`, `(!!)`, `maximum`/`minimum` sobre listas posiblemente vacías, `undefined`. Alternativas: pattern matching, `uncons`, `listToMaybe`, `NonEmpty`, `lookup`, `readMaybe`.
- Estado verificado de `base`: **`head` y `tail` de `Data.List` llevan `{-# WARNING #-}` con categoría `x-partial` desde base-4.19 (GHC 9.8)**, código `[GHC-63394]`. Matices que hay que conocer: (a) **es un warning, no una deprecación** — la CLC lo dejó explícitamente fuera de deprecar/eliminar; (b) **`init` y `last` NO están marcadas**, así que el warning no cubre la clase entera; (c) se silencia con `-Wno-x-partial` y hay presión en GHC para sacarlo de `-Wdefault`. **Conclusión operativa: no delegar la prohibición al compilador.** El gate real es `hlint` + revisión + `-Werror`, y `-Wno-x-partial` está prohibido en este catálogo.
- Nunca se silencia un error convirtiéndolo en valor por defecto (`fromMaybe 0` sobre un fallo real). El error se propaga con contexto o se decide explícitamente.

### Arquitectura de efectos — criterio, no catálogo

Orden de decisión, de menos a más maquinaria. **No subir de nivel sin un problema concreto que el nivel anterior no resuelva.**

1. **`ReaderT Env IO` (patrón `ReaderT` sobre `IO`) — default sobrio.** Un record `Env` con las capacidades (conexión de BD, logger, cliente HTTP, config) inyectado por `ReaderT`. Testable sustituyendo el `Env`. Rendimiento predecible, errores del compilador legibles, cualquiera lo entiende en una tarde. **La inmensa mayoría de los servicios no necesita nada más.**
2. **`mtl`** (`MonadReader`/`MonadState`/`MonadError` como constraints): útil para funciones polimórficas en la capa de dominio. Coste: el problema *n²* de instancias al añadir transformadores propios, y mensajes de error que empeoran rápido. Aceptable en dosis pequeñas sobre el patrón (1).
3. **Sistema de efectos** (`effectful` como opción por defecto de esta categoría — 2.6.1.0, ago-2025, BSD-3-Clause; `cleff`, `fused-effects` como alternativas): solo cuando hay **varios efectos ortogonales que se necesitan interpretar de más de una forma** (real / mock / dry-run / instrumentado) y eso ya duele. Coste real: una dependencia estructural en todo el código, una curva más para cada persona nueva, y ecosistema fragmentado. `effectful` se elige por rendimiento (`IO` + `ReaderT` por debajo) y por errores de tipo tolerables; `polysemy` está fuera del default por su coste de rendimiento e inferencia salvo que se demuestre lo contrario hoy (§8).
- Decidir **una** y documentarla en un ADR. Un repo con `ReaderT` en un módulo, `mtl` en otro y `effectful` en un tercero es el peor resultado posible.
- Regla transversal: la capa de dominio es **pura y sin efectos**; los efectos viven en el borde. Eso es lo que da el valor, no el framework.

### Concurrencia

- Hilos ligeros de GHC (`forkIO`): baratos, miles de ellos son normales. No hay pool que gestionar.
- **Nada de `forkIO` desnudo**: todo hilo tiene dueño. `async` (`withAsync`, `concurrently`, `race`, `mapConcurrently`) o `ki` para *structured concurrency*; el hilo padre observa la excepción del hijo. Un `forkIO` cuyo error nadie ve es una pérdida silenciosa de trabajo.
- **STM por defecto para estado compartido**: `TVar`/`TQueue`/`TBQueue` componen; `MVar` solo para exclusión mutua simple o *empty-full* explícito; `IORef` solo para estado sin contención (y con `atomicModifyIORef'`). Prohibido I/O dentro de `atomically` (el tipo ya lo impide — no burlarlo con `unsafePerformIO`).
- Colas **acotadas** (`TBQueue`, no `TQueue`) por defecto: backpressure explícita.
- `timeout` en toda operación de red; excepciones asíncronas respetadas: `bracket`/`bracketOnError` para liberar recursos aunque llegue `ThreadKilled`; `uninterruptibleMask` solo en el hueco mínimo y documentado.
- Ojo con los thunks compartidos entre hilos: un `TVar` lazy acumula el trabajo hasta que alguien lo fuerza — `modifyTVar'`, siempre la prima.

## 4. Calidad y testing

### Formato y lint

- **fourmolu** (0.20.0.0, BSD-3-Clause) con `fourmolu.yaml` versionado, o **ormolu** si se prefiere cero configuración. Uno solo por repo; no se debate el estilo, lo decide la herramienta.
- **hlint** con `.hlint.yaml` versionado. Verificado: última release **3.10 (feb-2025)** — cadencia baja; sigue siendo el estándar de facto pero **verificar su estado antes de convertirlo en gate bloqueante** (§8). Reglas propias para prohibir las funciones parciales que `base` no marca (`init`, `last`, `fromJust`, `(!!)`, `read`) — el linter cubre el hueco del compilador.
- **HLS** en todos los puestos, con la versión atada al GHC del proyecto vía GHCup.

### Warnings: `-Wall -Werror` y cuáles

- `ghc-options` base en la `common` stanza:

```cabal
common warnings
  ghc-options:
    -Wall
    -Wcompat
    -Widentities
    -Wincomplete-record-updates
    -Wincomplete-uni-patterns
    -Wmissing-export-lists
    -Wmissing-home-modules
    -Wpartial-fields
    -Wredundant-constraints
    -Wunused-packages
```

- **`-Werror` en CI, nunca en el `.cabal` de una librería publicada** (rompe el build de terceros con un GHC más nuevo). En CI se pasa por flag: `cabal build --ghc-options=-Werror`.
- `-Wincomplete-patterns` (dentro de `-Wall`) es **el gate más valioso del lenguaje**: un match no exhaustivo es un `error` en tiempo de ejecución. Como error, sin excepciones.
- Advertencia verificada: `-Wall` **cambia de contenido entre versiones de GHC** (`-Wincomplete-record-selectors` entró en `-Wall` en 9.14). Cada upgrade de GHC se hace en una rama con `-Werror` activo y se triaña lo nuevo; nunca `-Wno-*` a granel para "que compile".
- `{-# OPTIONS_GHC -Wno-... #-}` siempre a nivel de fichero, con lint concreto y comentario-motivo. `-Wno-x-partial` está **PROHIBIDO** (§3).

### Testing

- Framework: **hspec** (BDD, buen output) o **tasty** (agrega múltiples tipos de suite). Uno por repo.
- **Property-based testing es el valor diferencial de Haskell y no es opcional** en código con invariantes. **QuickCheck** (generación aleatoria, shrinking por tipo) o **Hedgehog** (generadores integrados con shrinking, mejor por defecto en propiedades con precondiciones). Propiedades obligatorias donde apliquen: round-trip de serialización (`decode . encode == id` para JSON/binario/DB), leyes algebraicas de las instancias propias (`Functor`, `Monoid`, `Ord` — con `quickcheck-classes` o equivalente), idempotencia, invariantes de estructuras de datos propias.
- **Modelo de estado** (`quickcheck-state-machine`, `hedgehog` state machines) para lógica concurrente o con estado: es la única forma práctica de encontrar carreras.
- Tests unitarios convencionales para el camino feliz y los **bordes y errores**: listas vacías, límites numéricos, decodificación inválida, timeouts, cancelación.
- **Golden tests** (`tasty-golden`) para salidas grandes y estables (renders, SQL generado, specs).
- Integración con dependencias reales (`testcontainers-hs` o Docker Compose en CI) con la **misma versión de motor que producción**; mockear las fronteras propias, no el mundo.
- `doctest` en librerías publicadas: los ejemplos del Haddock se verifican.
- Todo bugfix deja test de regresión que falla antes del fix. Test flaky: se arregla o se borra.

### Gates de CI (rompen el build, en orden de coste)

```
fourmolu --mode check $(git ls-files '*.hs')
hlint .
cabal build all --ghc-options=-Werror        # -Wall -Werror + -Wunused-packages
cabal test all
cabal check                                   # sanidad del .cabal (paquetes publicables)
cabal haddock all                             # los docs compilan
cabal audit / cabal-audit contra security-advisories   # verificar nombre y estado (§8)
```

Main siempre verde. Matriz de GHC en CI: **el GHC de producción como obligatorio** + el siguiente como *allowed-to-fail* (así el upgrade no es un big bang). No compilar contra 5 versiones "porque sí": cada una es minutos de CI.

## 5. Seguridad del stack

- **`unsafePerformIO` — PROHIBIDO.** Rompe la transparencia referencial, y con ella todo razonamiento del compilador: el optimizador puede duplicar, eliminar o reordenar el efecto. Excepción única: bindings FFI encapsulados en una API pura demostrablemente pura, con `{-# NOINLINE #-}`, comentario `-- SAFETY:` que justifique la invariante y test dedicado. `unsafeDupablePerformIO`, `unsafeInterleaveIO`, `unsafeCoerce` y `accursedUnutterablePerformIO`: la misma regla, endurecida.
- **`Text.Read.read` sobre entrada no confiable — PROHIBIDO.** `read` lanza una excepción imposible de manejar en código puro y su parser no está pensado como frontera de confianza. Usar `readMaybe` y, para formatos reales, un parser (`attoparsec`, `megaparsec`) con límites de tamaño y profundidad.
- **Dependencias de Hackage sin curar**: Hackage no revisa nada. Toda dependencia fuera del snapshot de Stackage es una decisión de confianza: mirar último release, número de mantenedores, licencia (fichero `LICENSE` real, no el campo del `.cabal`) y árbol transitivo (`cabal-plan`). Recordar que **`Setup.hs` y Template Haskell ejecutan código arbitrario en tiempo de build** con los permisos del runner de CI — cada dependencia nueva es superficie de supply chain, no un import gratis.
- SCA: la **Haskell Security Response Team** mantiene `security-advisories` (advisory-db) y hay herramienta de auditoría; **verificar el nombre exacto, la integración y su estado antes de fijarla como gate** (§8). Ejecutar en cada PR y además de forma programada.
- **Deserialización**: JSON con `aeson` y tipos concretos + `FromJSON` derivado, nunca decodificar a `Value` y navegar a mano. Límites de tamaño de payload en el borde HTTP (`wai` middleware / servant) y de profundidad de anidamiento. Nada de deserialización que instancie tipos arbitrarios.
- **SQL solo parametrizado**: `persistent`/`esqueleto`, `hasql`/`rel8` o `postgresql-simple` con placeholders. Prohibido construir SQL concatenando `Text`; `rawSql` solo con parámetros.
- **Secretos**: nunca en `Show`/`Generic`-derived. Envolver credenciales en un newtype con `Show` manual que redacta, o usar una librería de secretos; los logs derivan de `Show` con más frecuencia de la que se cree. Nada de secretos en el `.cabal`, en el árbol o en el eventlog.
- **Cripto**: `crypton`/`cryptonite`-sucesor y `tls`/`crypton-connection` mantenidos; verificar estado de mantenimiento antes de fijar (§8). AES-GCM, ChaCha20-Poly1305, Argon2/bcrypt, TLS 1.2+. Aleatoriedad de seguridad con un CSPRNG (`crypton`'s `getRandomBytes`), **nunca `System.Random`**.
- **Contenedores**: build multi-stage, binario enlazado y despojado (`-split-sections`, `strip`), imagen distroless o `scratch` si es estático, **non-root**, FS read-only. Comprobar que las librerías C dinámicas (libgmp, libpq) están en la imagen final — el fallo clásico.
- Servicios de larga vida: **cerrar `-rtsopts` en el binario de producción** o limitar los flags aceptados. `+RTS` desde una variable de entorno controlada por el atacante es ejecución de configuración arbitraria del runtime.

## 6. Rendimiento y operabilidad

- **RTS flags: se compilan y se justifican, no se copian.** Compilar con `-threaded -rtsopts "-with-rtsopts=..."`. Puntos de partida a **medir**, no a asumir:
  - `-N` con capacidades **explícitas y ajustadas al límite de CPU del contenedor** (`-N4`), no `-N` a secas: en K8s, `getNumProcessors` ve la máquina física y sobre-suscribe. Este es el error de operación número uno de Haskell en contenedores.
  - `-A` (nursery) mayor que el default para reducir GCs menores en servicios con mucha asignación (p. ej. `-A64m`) — medir latencia p99 antes y después.
  - `-M` (heap máximo) alineado con el límite de memoria del pod, para que el proceso muera con error de heap diagnosticable en vez de por OOM-kill del kernel.
  - `--nonmoving-gc` como opción para latencia de pausa acotada en heaps grandes: **solo con medición**, no por defecto.
- **Observabilidad**: métricas del RTS exportadas siempre (`GHC.Stats`/`getRTSStats` con `-T`), vía exporter Prometheus o EKG; **verificar el estado de mantenimiento de la librería concreta antes de fijarla** (§8). Series mínimas: live bytes, GC wall/cpu time y pausa máxima, hilos vivos, capacidades. La **tendencia de live bytes es el detector de fugas en producción**.
- Logs estructurados (`katip`, `co-log`, o el logger de `rio`) en JSON; trazas con OpenTelemetry cuando el ecosistema del proyecto lo soporte (verificar madurez del binding — §8). **Prohibido `putStrLn`/`print`/`trace` en código de servicio**; `Debug.Trace` no se mergea.
- **Timeouts y límites en todo borde**: cliente HTTP (`http-client` con `responseTimeout` explícito — el default no basta), pool de BD acotado, `timeout` en llamadas a servicios, límite de tamaño de request. Sin timeout definido = bug.
- **Graceful shutdown obligatorio**: handler de `SIGTERM` que deja de aceptar conexiones, drena las en curso con deadline y cierra recursos con `bracket`. `warp` con `setInstallShutdownHandler`/`setGracefulShutdownTimeout`. Sin esto no hay rolling deploy fiable.
- Health endpoints separados: liveness trivial, readiness que comprueba dependencias.
- **Perfilar antes de optimizar**: `-prof -fprof-auto` + `+RTS -p` para tiempo, `-h*` para heap, eventlog + `ghc-events`/`eventlog2html` para concurrencia y GC. `criterion`/`tasty-bench` para microbenchmarks comparables. Ojo: el build con profiling **cambia el código generado** — confirmar hallazgos en el binario normal.
- Optimización: `-O2` en producción (`-O0`/`-O1` en desarrollo por velocidad de build). `INLINABLE`/`SPECIALIZE` en funciones polimórficas de hot path (GHC 9.14 mejoró bastante la especialización); fusión de listas/`vector`/`text` es real pero se rompe con facilidad — verificar con `-ddump-simpl` antes de afirmar que ocurre.

### Tiempos de compilación y CI — riesgo operativo, no molestia

Los tiempos de build son **el coste recurrente más subestimado de Haskell** y la razón habitual de que el equipo deje de correr el CI completo.

- Presupuesto explícito: build limpio y build incremental medidos y vigilados; si el incremental supera ~2 min, es un bug de arquitectura del proyecto.
- Palancas, en orden: **caché de CI del store de cabal/stack y de `dist-newstyle`** (con clave por GHC + plan de dependencias); dividir en paquetes para paralelizar y acotar la recompilación; **eliminar `TemplateHaskell` innecesario** (invalida caché agresivamente y bloquea cross-compilación); recortar `-O2` fuera de release; `-j` alineado con los cores del runner; `-fwrite-ide-info` solo donde se use.
- `-Wunused-packages` activado: dependencias muertas que siguen costando minutos.
- Runners con RAM suficiente: GHC con `-O2` y TH consume gigas; un OOM de compilador se diagnostica mal y se sufre semanas.

## 7. Sostenibilidad a largo plazo

**Es la sección que decide si el proyecto sobrevive.** El riesgo dominante en Haskell no es técnico.

- **Bus factor ≥3 como requisito de entrada**, no como aspiración. Con 1 persona que domine el código, un servicio Haskell es un pasivo desde el día en que esa persona rota. Antes de aprobar el stack: nombrar por escrito quién más puede desplegar, depurar una fuga de espacio y subir de GHC.
- **Contratación**: el mercado es pequeño y caro, pero de calidad alta; contratar "gente buena que aprenda Haskell" funciona mejor que buscar haskellers. Presupuestar **3-6 meses** hasta productividad plena para alguien senior sin experiencia previa en FP tipada. La curva no está en la sintaxis: está en pereza, `IO`/efectos y en leer errores de tipo de librerías con tipos elaborados.
- **Documentación como mitigación de bus factor**: Haddock en toda API pública, ADRs de las decisiones estructurales (efectos, Prelude, build tool, Nix sí/no) y un `CONTRIBUTING` que arranque de cero con GHCup. El código Haskell es autoexplicativo para quien ya sabe Haskell — para nadie más.
- **Cadencia de upgrades**: LTS de GHC a LTS de GHC, aprovechando el solape de ~6 meses. Point releases (`.2`, `.3`) sin demora. Dependencias con Renovate/Dependabot agrupado; majors a mano con changelog. Snapshot de Stackage: subir de LTS trimestralmente o al menos cada semestre — dejar el snapshot congelado dos años convierte el upgrade en un proyecto.
- **Librerías publicadas**: PVP (no SemVer: en Haskell el versionado es `A.B.C.D` con `A.B` como major) y `cabal check` en el gate. Bandas de versión en las dependencias, `Cabal.project.freeze` solo para el CI propio.
- **Deuda consciente**: todo atajo con `-- TODO(usuario): motivo — issue`. Nada de `-Wno-*` ni `hlint: ignore` sin comentario y enlace.

**PROHIBICIONES (requieren ADR y aprobación para excepcionar).**
- ❌ `error`, `undefined`, `head`, `tail`, `init`, `last`, `fromJust`, `read`, `(!!)`, `maximum`/`minimum` sobre listas — en producción. Los warnings de `base` cubren solo `head`/`tail`: el gate es hlint + revisión.
- ❌ `unsafePerformIO`, `unsafeDupablePerformIO`, `unsafeInterleaveIO`, `unsafeCoerce`, `Obj`-tricks vía FFI — salvo la excepción documentada de §5.
- ❌ `foldl` (usar `foldl'`), `Data.Map` lazy y `Control.Monad.State` lazy por inercia, `modifyIORef` sin prima, `TQueue` no acotada como bus de trabajo.
- ❌ `String` como tipo de texto en código nuevo; `decodeUtf8` sin manejo de error sobre entrada no confiable.
- ❌ `catch`/`handle` sobre `SomeException` que trague excepciones asíncronas; recursos sin `bracket`; `forkIO` sin dueño ni observación del resultado.
- ❌ `-Wno-x-partial` y `-Wno-*` a granel; `-Werror` en el `.cabal` de una librería publicada; CI sin `-Werror`.
- ❌ Mezclar Stack y cabal en el mismo repo; lockfile/freeze fuera del VCS; `git:` sin rev y hash; dependencias fuera del snapshot sin justificación.
- ❌ Dos Preludios alternativos en el mismo árbol; un `Prelude` casero sin dueño.
- ❌ Más de una arquitectura de efectos en la misma base de código; subir a un effect system sin un problema que `ReaderT Env IO` no resuelva.
- ❌ `UndecidableInstances`/`IncoherentInstances`/`ImpredicativeTypes`/`AllowAmbiguousTypes` sin ADR; `TemplateHaskell` nuevo sin medir su coste de compilación.
- ❌ `putStrLn`/`print`/`Debug.Trace` en servicios; secretos alcanzables por `Show` derivado.
- ❌ `-N` sin capacidades explícitas en contenedor; binario de producción con `-rtsopts` abierto; desplegar un servicio de larga vida sin haber perfilado el heap.
- ❌ GHC fuera de soporte (hoy: ≤9.4) en producción; adoptar una `.1` de GHC en producción.
- ❌ Un solo humano capaz de mantener el servicio.

**Cuándo NO elegir Haskell (prohibición honesta).**
- ❌ Cuando el equipo no puede sostener bus factor ≥3 ni presupuestar la curva. Esto solo ya descarta el stack.
- ❌ CRUD y glue sin invariantes que el tipo capture: el retorno de la inversión no aparece, y sí aparece el coste.
- ❌ Requisitos de **latencia dura o tiempo real**: hay GC, y las pausas no son acotables de forma trivial → `rust-standards`.
- ❌ Trabajo que dependa de un ecosistema donde Haskell es débil: ML/ciencia de datos (→ `python-standards`), frontend web y móvil nativo, ecosistemas cloud SDK-céntricos (→ `go-standards`/`typescript-standards`).
- ❌ Entornos con rotación alta de personal o entrega por proveedores externos intercambiables.
- ❌ "Porque el equipo quiere aprender Haskell" en un servicio de producción. Aprender está bien; el vehículo no es un sistema con SLA.

## 8. Verificación web obligatoria

Antes de fijar versión, flag o afirmar el estado del ecosistema, **verificar por web** (no de memoria):

1. **GHC vigente y política LTS**: `haskell.org/ghc` y `discourse.haskell.org` (anuncio de calendario/LTS en `haskell.org/ghc/blog/20250702-ghc-release-schedules.html`); resumen de EOL en `endoflife.date/ghc`. ¿Sigue 9.14 siendo la LTS? ¿Ha salido la siguiente LTS preanunciada? ¿Qué versiones han entrado en EOL?
2. **Qué trae la edición de lenguaje**: users guide oficial, `exts/control.html` de la versión concreta. ¿Ha cambiado el default de `GHC2021` a `GHC2024`? ¿Hay `GHC20xx` nueva?
3. **`-Wall` de la versión destino**: release notes del GHC concreto — los warnings nuevos que entran en `-Wall` rompen builds con `-Werror`.
4. **Estado de las funciones parciales en `base`**: `hackage.haskell.org/package/base/changelog` y las issues de `haskell/core-libraries-committee`. ¿Sigue `x-partial` en `-Wdefault` (hay presión para sacarlo, GHC #24322)? ¿Se han marcado `init`/`last`? ¿Ha habido deprecación real?
5. **Snapshot de Stackage**: `stackage.org/snapshots` — última LTS, su GHC y si ya existe una LTS sobre el GHC que quieres. **Aquí se resuelve la discrepancia declarada en §2.**
6. **Herramientas de build**: releases de `commercialhaskell/stack` y `haskell/cabal` (feeds `/releases.atom`; la API de GitHub puede devolver 403 sin auth). Comprobar que Stack sigue con releases recientes antes de repetir el mito de que está abandonado — a ago-2026 lo está: 3.11.1, jun-2026.
7. **Calidad**: `hlint` (última release verificada 3.10, feb-2025 — **comprobar si sigue viva antes de hacerla gate bloqueante**), `fourmolu`/`ormolu`, HLS y su matriz de GHC soportados (`haskell-language-server.readthedocs.io/en/latest/support/ghc-version-support.html`).
8. **Advisories y auditoría**: `github.com/haskell/security-advisories` — nombre exacto de la herramienta de auditoría (`cabal audit` integrado frente a `cabal-audit` externo), su estado y cómo se integra en CI. **No verificado a ago-2026 en detalle: hueco.**
9. **Licencias y mantenimiento** de toda librería que se fije como default, leyendo el `LICENSE` en crudo (`raw.githubusercontent.com`), no el campo del `.cabal`. Precedentes del catálogo: herramientas que cambian de licencia (Trivy) o se declaran *feature complete* con acción comercial (gitleaks v2). **Verificado a ago-2026: hlint BSD-3-Clause, fourmolu BSD-3-Clause, effectful BSD-3-Clause. Sin verificar: ormolu, relude, rio, aeson, servant, crypton, katip.**

**Huecos declarados (no verificados a ago-2026, no rellenar de memoria):**
- Versión y tag `recommended` actual de **GHCup** (el tag lo define su metadata; comprobar con `ghcup list -t ghc`).
- Versiones y estado de mantenimiento de **hspec, tasty, QuickCheck, Hedgehog, aeson, servant, persistent/esqueleto, hasql, conduit, warp, http-client**.
- Estado de **EKG** y de los exporters de métricas del RTS (varios candidatos, mantenimiento desigual) y madurez del binding **OpenTelemetry** para Haskell.
- Estado comparativo actual de **`cleff`, `fused-effects`, `polysemy`** (el juicio de §3 sobre `polysemy` es histórico y debe reconfirmarse).
- Estado de **`crypton`/`tls`** y de `testcontainers-hs`.
- Fecha exacta de la próxima LTS de GHC (el plan publicado apuntaba a 9.22 hacia 2028; es plan, no compromiso).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
