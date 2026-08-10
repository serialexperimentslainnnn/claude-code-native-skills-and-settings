---
name: dart-standards
description: Use when writing or reviewing Dart code and its tooling - .dart files, pubspec.yaml, pubspec.lock, analysis_options.yaml, dart analyze, dart format, dart fix, dart test, dart compile exe/js/wasm, dart run build_runner, package:lints, package:flutter_lints, very_good_analysis, freezed, json_serializable, package:test, mocktail, mockito, golden tests, isolates, Future/Stream/async, dart:ffi, ffigen, jnigen, package:web and dart:js_interop, pub get/upgrade/publish, pub workspaces, or publishing to pub.dev.
---

# Estándares Dart (lenguaje y tooling)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **lenguaje Dart y su cadena de herramientas**, se use en Flutter, en CLI, en servidor o en
web. Triggers: `.dart`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `dart_test.yaml`,
`build.yaml`, `dart analyze` / `format` / `fix` / `test` / `compile` / `doc`, `dart pub`,
`build_runner`, `freezed`, `json_serializable`, `ffigen`, `jnigen`, publicación en pub.dev.

Cubre: sistema de tipos y null safety, patrones y `sealed`, resolución de dependencias y lockfile,
lint y formato, asincronía (`Future`/`Stream`), isolates, manejo de errores, generación de código,
tests, compilación (JIT/AOT/JS/Wasm), interop nativa y publicación de paquetes.

**No aplica**: ver `mobile-standards` (**el diseño de la app móvil es suyo**: arquitectura de la app,
navegación y ciclo de vida de la plataforma, permisos, almacenamiento seguro en el dispositivo
—Keychain/Keystore—, firma, publicación en App Store y Google Play, rollout y actualizaciones,
rendimiento percibido y accesibilidad móvil; **aquí solo el lenguaje Dart, `pub`, los lint, el
formato, los tests y la compilación**), `webassembly-standards` (el objetivo de
compilación Wasm, el runtime, los límites del sandbox y el tamaño del artefacto son suyos; aquí solo
el lado Dart —`dart:js_interop`, `package:web`, `--wasm`— del cruce), `api-design-standards` (diseño
del contrato HTTP/GraphQL/gRPC que consume o expone el código Dart), `appsec-standards` (modelado de
amenazas y clases de vulnerabilidad agnósticas; aquí los sinks concretos de Dart),
`identity-access-management-standards` (flujos OAuth 2.1/OIDC y emisión de tokens; aquí solo su
consumo), `secrets-management-standards` (custodia y rotación; aquí solo la regla de que un binario
de cliente no guarda secretos), `cicd-standards` (la pipeline que ejecuta los gates de §4),
`vulnerability-management-standards` (triaje y SLA de parcheo de las CVEs que encuentre el SCA),
`observability-standards` (pipeline de telemetría; aquí solo la instrumentación en código),
`git-workflow-standards` (rama, commits y tagging SemVer), `typescript-standards` (el frontend web
que no sea Flutter).

**Regla cero**: detecta primero el proyecto real (constraint `sdk:` del `pubspec.yaml`, versión de
Flutter fijada, lint set activo en `analysis_options.yaml`) y respeta sus convenciones; este criterio
rige lo nuevo y lo marcado como deuda.

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Mínimo / estado a ago-2026 | Por qué |
|---|---|---|---|
| SDK de Dart | **La que trae el canal `stable` de Flutter** si el proyecto es Flutter | Dart **3.12.2** (empaquetado en Flutter stable **3.44.8**, 2026-07-23) | En un proyecto Flutter **no se elige la versión de Dart**: la impone el SDK de Flutter. Fijar Dart aparte es una fuente garantizada de desalineación |
| SDK de Dart (proyecto no-Flutter) | **Última stable de dart-lang/sdk** | 3.12.x stable; **3.13.0 en beta** (Flutter 3.47.0-0.3.pre lo empaqueta) | Dart es *no-Flutter* también (CLI, backend, herramientas); ahí sí se pinea directo |
| Constraint en `pubspec.yaml` | `environment: sdk: ^3.12.0` (caret, no rango abierto) | — | El caret expresa "esta major, desde esta minor"; `>=x <4.0.0` a mano invita a errores |
| Gestión de versión del SDK | **fvm** o el gestor del CI, fijado en el repo | — | "La versión que tenga cada máquina" es un fallo de reproducibilidad, no una preferencia |
| Lint (paquete no-Flutter) | **`package:lints`**, conjunto **`recommended`** | — | Recomendación del propio equipo de Dart: *"We recommend using at least the `core` rule set… Or, better yet, use the `recommended` rule set"* |
| Lint (proyecto Flutter) | **`package:flutter_lints`** | — | Doc oficial: *"If you're writing Flutter code, use the rule set in the `flutter_lints` package, which builds on `lints`"*. Es superconjunto de `recommended`, que a su vez lo es de `core` |
| Lint estricto opcional | `very_good_analysis` (10.3.0, MIT, de Very Good Ventures) | — | **Tercero, no oficial.** Adóptalo solo por decisión explícita de equipo: añade reglas de estilo agresivas y su cadencia de majors no la controlas |
| Formato | **`dart format`** | — | Formateador único del SDK, sin opciones de estilo. Cero debate en PRs |
| Análisis | **`dart analyze --fatal-infos`** en CI | — | Sin `--fatal-infos` los infos se acumulan hasta ser ruido permanente |
| Tests | **`package:test`** (`dart test` / `flutter test`) | — | Único runner del ecosistema |
| Mocks | **`mocktail`** (1.0.5, MIT) por defecto; `mockito` solo si ya está | — | `mocktail` no necesita codegen: *"no manual mocks or code generation"*. `mockito` obliga a `build_runner` para cada mock |
| Codegen | `build_runner` + `json_serializable`; `freezed` solo si el modelo lo justifica | — | **Los macros fueron cancelados** (ene-2025, repo archivado): el codegen por `build_runner` es el camino oficial y va para largo |
| Interop nativa | `dart:ffi` + **`ffigen`** (C) / **`jnigen`** (Java-Kotlin) | — | Bindings generados, no escritos a mano |
| Interop web | **`package:web`** + **`dart:js_interop`** | — | `dart:html`, `package:js` y `dart:js` **no son compatibles con la compilación a Wasm** (§ compilación) |

## 3. Estructura y convenciones

**Tipos y lenguaje**

- **Sound null safety no es una opción**: *"Dart has enforced sound null safety since Dart 3, released
  in May 2023"*. No hay "código legacy sin null safety" que puedas ejecutar en un SDK 3.x — lo que
  queda de la era 2.12–2.19 son paquetes abandonados sin migrar: **no son deuda, son un bloqueo de
  upgrade**; se sustituyen, no se parchean.
- `late` solo con invariante de inicialización real (inyección tardía, `initState`). `late` para
  callar al analizador es un `!` con más letras: **el fallo pasa de compilación a runtime**.
- `!` (bang) prohibido fuera de tests e invariantes probadas; usa `?.`, `??`, promoción por `if (x
  != null)` o patrones.
- `required` explícito en todo named parameter que no tenga default sensato; nada de nullable "por si
  acaso" que luego se desreferencia.
- **Patrones, records y `sealed`** están disponibles desde **Dart 3.0**: modela las variantes de
  dominio con `sealed class` + `switch` **exhaustivo** (el analizador comprueba la exhaustividad y
  romperá el build cuando añadas un caso — ese es exactamente el efecto que buscas). Cadenas de
  `if (x is A)` sobre jerarquías cerradas: veto.
- `records` para retornos múltiples locales; **no** como sustituto de un tipo de dominio con nombre.
- Modificadores de clase (`final`, `base`, `interface`, `sealed`) explícitos en API pública de
  paquete: la ausencia de modificador declara "cualquiera puede extender esto", y eso es un contrato.
- Genéricos con `extends` cuando haya restricción real; `dynamic` vetado salvo frontera anotada
  (usa `Object?` + narrowing).
- Inmutabilidad por defecto: `final` en campos y locales, `const` donde el valor lo permita.

**Paquete y dependencias**

- `pubspec.yaml`: constraints con caret (`^1.2.3`), **nunca `any`** ni rangos abiertos por arriba.
  `dependency_overrides` es una herramienta de emergencia con fecha de caducidad y un TODO enlazado a
  un issue, jamás un estado estable.
- **Lockfile**, según el criterio oficial de Dart, que depende del tipo de paquete:
  - **Aplicación** (app Flutter, CLI, servicio): *"we recommend that you commit the `pubspec.lock`
    file. Versioning the `pubspec.lock` file ensures changes to transitive dependencies are
    explicit"*. Se versiona **siempre**.
  - **Paquete publicable / librería**: *"don't commit the `pubspec.lock` file. Regenerating the
    `pubspec.lock` file lets you test your package against the latest compatible versions of its
    dependencies"*. No se versiona; a cambio, **el CI debe tener un job que resuelva contra las
    versiones más recientes permitidas** — es el punto de la recomendación, y sin ese job solo has
    perdido reproducibilidad.
- Monorepos: **pub workspaces** (`workspace:` en el `pubspec.yaml` raíz) antes que `melos` en
  proyectos nuevos; una resolución compartida evita el skew entre paquetes del repo.
- Layout canónico: `lib/src/` para implementación, `lib/<paquete>.dart` como *barrel* que exporta la
  API pública. **Lo que no se exporta desde `lib/` no es API**: importar `package:x/src/...` desde
  fuera es una violación de frontera, no un atajo.
- `analysis_options.yaml` en la raíz: `include:` del lint set elegido + `analyzer: language:
  strict-casts, strict-inference, strict-raw-types` en código nuevo. Excluye **solo** ficheros
  generados (`*.g.dart`, `*.freezed.dart`), nunca código propio.
- Nombres: `lowerCamelCase` para miembros, `UpperCamelCase` para tipos, `snake_case` para ficheros y
  paquetes. Prefijo `_` = privado a **librería**, no a clase: tenlo presente al partir ficheros.
- Documenta con `///` la API pública de paquetes publicables; `dart doc` en CI para detectar
  referencias rotas.

**Asincronía**

- `async`/`await` por defecto; `.then()` encadenado solo donde el `await` no encaje.
- **Nada de `Future` sin esperar ni gestionar**: activa `unawaited_futures` en el lint y usa
  `unawaited(...)` explícito cuando el fire-and-forget sea deliberado. Un `Future` huérfano se traga
  su error y aparece como fallo inexplicable meses después.
- `Stream`: **single-subscription por defecto**; `broadcast` solo con motivo. Toda suscripción tiene
  un `cancel()` en el `dispose`/`close` correspondiente — las suscripciones sin cancelar son la fuga
  de memoria número uno en Dart.
- `Completer` solo para adaptar APIs de callback; nunca como mecanismo de control de flujo propio.
- Timeouts explícitos (`.timeout(...)`) en toda operación de red o IPC. Sin timeout no hay
  operabilidad.

**Isolates**

- **Dart no comparte memoria mutable entre isolates**: cada uno tiene su heap y su event loop; la
  comunicación es por paso de mensajes (`SendPort`/`ReceivePort`, `Isolate.run`). Esto elimina los
  *data races* por construcción — y también elimina la opción de "compartir el objeto y ya".
- Regla de uso: **isolate = CPU-bound**, no I/O-bound. El I/O ya es asíncrono en el isolate
  principal; meterlo en un isolate solo añade coste de serialización.
- `Isolate.run` para trabajo puntual; isolate de larga vida con puertos solo cuando el coste de
  arranque y el volumen de mensajes lo justifiquen.
- El coste real es la **serialización del mensaje** (con excepciones: tipos transferibles como
  `TransferableTypedData`). Mide antes de asumir que el isolate te sale rentable.

**Errores**

- **Criterio**: excepciones para lo *excepcional* (bug, invariante rota, fallo de infraestructura);
  **tipo de resultado** (`sealed class Result<T>` con `switch` exhaustivo, o `Either` de terceros)
  para lo **esperable y parte del contrato**: validación fallida, 404, credencial inválida, sin red.
  El criterio es "¿el llamante debe decidir sobre esto?" — si sí, es un valor de retorno, no una
  excepción invisible en la firma. Dart no tiene excepciones comprobadas: una excepción **no aparece
  en la firma**, y esa es exactamente la razón de la regla.
- Excepciones propias tipadas (`class PaymentDeclined implements Exception`); jamás `throw 'string'`.
- `catch (e)` genérico solo en la frontera (top-level de request, `runZonedGuarded`, handler de
  isolate) y **siempre relanzando o registrando con `StackTrace`** (`on X catch (e, st)`). `catch`
  vacío o que devuelve un default silencioso: veto.
- Distingue `Error` (bug del programador: `StateError`, `ArgumentError` → **no se capturan**, se
  arreglan) de `Exception` (condición de runtime → se manejan).
- Libera recursos siempre: `try/finally`, `close()`/`dispose()` en cada `StreamSubscription`,
  `HttpClient`, fichero y `ReceivePort`.

**Generación de código**

- El codegen es **coste permanente**: `build_runner` corre en cada cambio de modelo, en cada checkout
  limpio y en cada job de CI, y en proyectos grandes domina el tiempo de build. Cada generador nuevo
  se justifica por escrito.
- Regla: `json_serializable` sí (serializar a mano es error-prone y repetitivo). `freezed` **solo**
  cuando de verdad necesites uniones selladas + `copyWith` + igualdad estructural en muchos tipos; si
  son cuatro modelos, `sealed class` a mano sale más barato que la dependencia y el generador.
- Ficheros generados (`*.g.dart`, `*.freezed.dart`): **se versionan** si el consumo lo requiere
  (paquete publicado, build reproducible sin generador) y **se excluyen del análisis y de la
  cobertura** siempre. Decide una postura por repo y documéntala; el híbrido es lo que rompe.
- CI: `dart run build_runner build --delete-conflicting-outputs` y **`git diff --exit-code`** —
  generado desactualizado = build roto, no sorpresa en local.

**Arquitectura y gestión de estado**

Fuera de alcance salvo en lo que es lenguaje: el estado observable se modela con `Stream`/`Listenable`
y tipos **inmutables** con variantes `sealed` (loading/error/vacío/dato), y las dependencias se
inyectan por constructor. La elección de framework de estado y la arquitectura de la app son de
`mobile-standards`. Lo que sí es veto aquí: **singletons mutables globales** y service locators como
sustituto de inyección.

## 4. Calidad: formato, análisis, tests

**Gates de CI, en orden de coste creciente (bloquean merge):**

1. `dart pub get` (o `flutter pub get`) — en aplicaciones, contra el lockfile versionado.
2. `dart format --output=none --set-exit-if-changed .` — **no negociable, sin excepciones**. No hay
   opciones de estilo que discutir porque el formateador no las ofrece.
3. `dart analyze --fatal-infos --fatal-warnings`.
4. Codegen verificado (`build_runner` + `git diff --exit-code`) si el repo usa generadores.
5. `dart test` / `flutter test` con cobertura (umbral acordado; **señal, no meta**).
6. SCA de dependencias + `dart pub outdated` informativo.
7. Golden tests y build de release (compilación real) al final.

**Testing**

- **Pirámide**: mayoría de unitarios sobre dominio y lógica pura (sin plataforma, sin red, sin
  reloj real); integración los justos; widget/E2E pocos y estables.
- `package:test`: `group`/`test` con nombres que describen comportamiento; AAA; un motivo de fallo por
  test. `setUp`/`tearDown` para fixtures — nada de estado compartido entre tests.
- **Bordes y errores obligatorios**: entrada nula/vacía, JSON malformado, timeout, error de red,
  respuesta parcial, cancelación, permiso denegado.
- Asincronía en tests: `expectLater(stream, emitsInOrder([...]))`, `fakeAsync`/`FakeAsync` y relojes
  inyectados. **`await Future.delayed(...)` como forma de "esperar a que pase algo": veto** — es la
  fuente de flakiness número uno.
- Mocks en la **frontera** (cliente HTTP, repositorio, plataforma), no de los propios tipos de
  dominio. `mocktail` por defecto; registra `registerFallbackValue` para tipos custom.
- **Golden tests** solo para el design system y componentes de alto valor. Advertencia operativa: los
  goldens son **sensibles al entorno de renderizado** — fíjalos a una plataforma y versión de
  toolchain en CI o pasarás más tiempo regenerando `.png` que probando. Un golden que se regenera "a
  ver si pasa" no prueba nada; bórralo.
- Todo bug arreglado deja **test de regresión**. Test inestable: se arregla o se borra, nunca se
  reintenta en CI.

## 5. Seguridad del stack

- **Un binario de cliente no guarda secretos.** Todo lo que compilas en la app —API keys, endpoints
  privados, claves de firma, credenciales de terceros— **es público**: se extrae con `strings`, con
  un desensamblador o interceptando el tráfico. Ofuscar (`--obfuscate --split-debug-info`) eleva el
  coste del atacante, **no es un control de confidencialidad**. Si un tercero exige una clave secreta
  desde el cliente, la llamada va por tu backend: no hay alternativa correcta.
- **Validación en la frontera**: todo lo que entra —respuesta de API, deeplink, argumento de CLI,
  fichero, variable de entorno, mensaje de otro isolate— se parsea y valida antes de tocar el
  dominio. `json_serializable` valida **forma**, no **semántica**: rangos, enums desconocidos y
  campos obligatorios ausentes son tuyos. Un `as` sobre un `Map<String, dynamic>` sin comprobación es
  un crash en producción esperando el payload equivocado.
- **Dependencias de pub.dev**: pub.dev **no audita el código**. Sus métricas (pub points, likes,
  *downloads*, badges de *Dart 3 compatible*, *verified publisher*) son señal de mantenimiento y
  ergonomía, **no de seguridad**. Antes de añadir una dependencia: publisher verificado, repositorio
  público con actividad real, última publicación reciente, número de deps transitivas y licencia
  leída — y comprueba el nombre carácter a carácter (**typosquatting**). Constraints acotadas +
  lockfile en aplicaciones; SCA y advisories (osv.dev, GitHub Advisories) en CI.
- **Cripto**: `package:cryptography` o las APIs de la plataforma; jamás implementación casera.
  Aleatoriedad de seguridad **solo** con `Random.secure()` — `Random()` es un PRNG predecible y
  usarlo para tokens, nonces o IDs de sesión es una vulnerabilidad, no un descuido de estilo.
- **Almacenamiento en dispositivo y Keychain/Keystore**: es de `mobile-standards`. Aquí solo la
  regla: nada sensible en ficheros en claro ni en preferencias sin cifrar.
- **Logs**: sin PII, sin tokens, sin cuerpos de respuesta completos. En release, sin `print`.
- **Inyección**: `Process.run`/`Process.start` **con lista de argumentos y `runInShell: false`** —
  nunca componiendo una línea de shell con input externo. SQL parametrizado siempre.
- **TLS**: nunca sobreescribas `badCertificateCallback` para devolver `true`, ni "temporalmente para
  probar". Si aparece en un diff, es un bloqueo de review.
- `dart:mirrors` está fuera de AOT y no debe aparecer en código nuevo.

## 6. Rendimiento y operabilidad

- **JIT en desarrollo, AOT en producción.** El JIT da hot reload y arranque rápido de iteración; el
  AOT da arranque en frío y rendimiento estables. No perfiles nunca en modo debug/JIT: las cifras no
  se parecen a las de release.
- **Formatos de `dart compile`** (verificados en la doc oficial):
  - `exe`: ejecutable autocontenido (Windows/macOS/Linux); soporta cross-compilation a targets Linux
    (ARM, ARM64, RISCV64, x64) desde Dart 3.8+. **Sin `dart:mirrors` ni `dart:developer`.**
  - `aot-snapshot`: módulo AOT específico de arquitectura, ejecutado con `dartaotruntime`.
  - `jit-snapshot`: IR con código optimizado de una *training run*; pico de rendimiento potencialmente
    mejor que AOT **si el training run es representativo** — y peor si no lo es.
  - `kernel`: `.dill` portable.
  - `js`: JavaScript desplegable (la doc recomienda `webdev` para builds de producción).
  - `wasm`: **"Currently under development"** en la doc de `dart compile` — ver §8, hay discrepancia
    aparente con el estado de Flutter web.
- **WasmGC en Flutter web**: `flutter build web --wasm` y `flutter run -d chrome --wasm` existen y
  están documentados como camino soportado, pero **no es un objetivo universal**: Chromium/V8 soportan
  WasmGC desde la versión 119; Firefox anunció soporte estable en 120 pero **"currently doesn't
  work"** por una limitación conocida; Safari ya soporta WasmGC pero tiene un **bug de
  compatibilidad**; y en **iOS no funciona en ningún navegador** (*"Flutter compiled to Wasm can't run
  on the iOS version of any browser"*), porque todos usan WebKit. **Criterio**: Wasm solo con
  *fallback* a JS y midiendo, no como default. Consecuencia dura de migración: `dart:html`,
  `package:js` y `dart:js` **no son compatibles** con la compilación a Wasm — hay que migrar a
  `package:web` y `dart:js_interop`, y revisar las diferencias de `is`/`as` y de propagación de `Zone`
  en callbacks de interop. Diagnóstico en producción: `--source-maps`, y `--no-strip-wasm` solo para
  staging/QA.
- **Tamaño del artefacto** como métrica vigilada en CI (tree-shaking depende de que no haya
  reflexión ni entry points dinámicos ocultos).
- **Event loop**: nada de trabajo CPU-bound largo en el isolate principal — trocea o mueve a
  `Isolate.run`. Un `for` de 200 ms es un frame perdido, no un detalle.
- **Perfilado**: DevTools (CPU profiler, memory, timeline) **sobre un build de release/profile**.
  Optimizar sin medir está vetado.
- **Fugas**: `StreamSubscription` sin cancelar, `Timer` sin cancelar, `ReceivePort` sin cerrar y
  closures de larga vida capturando objetos grandes. Es el patrón recurrente; búscalo primero.
- **Observabilidad**: logs estructurados (`package:logging` con handler propio, no `print`), errores
  no capturados a `runZonedGuarded`/`Isolate.current.addErrorListener`, y crash reporting con símbolos
  subidos cuando se ofusca (sin `--split-debug-info` guardado, los stack traces de release son
  ilegibles y el ofuscado se vuelve un tiro en el pie).
- **Publicación en pub.dev**: `dart pub publish --dry-run` en CI, `CHANGELOG.md` y SemVer estrictos,
  `example/`, `topics:` en el pubspec, publisher verificado y publicación **automatizada desde CI con
  OIDC** (nada de tokens de pub en portátiles). Las métricas de pub.dev (pub points, likes, downloads)
  son señal de calidad de empaquetado, no de corrección.

## 7. Sostenibilidad y prohibiciones

**Cadencia**

- Proyecto Flutter: se sigue el canal **stable** de Flutter y la versión de Dart va de paquete; se
  adopta la nueva stable en semanas, no en trimestres — el desfase se paga en incompatibilidades de
  paquetes, no en comodidad. Nunca `master`/`main` de Flutter en producción; `beta` solo para probar.
- Dart publica minors con cadencia aproximadamente trimestral: lee el changelog y la página de
  *breaking changes* antes de subir el constraint del SDK.
- Dependencias: Renovate/Dependabot; parches de seguridad en <72 h; `dart pub outdated` revisado
  periódicamente. Una dependencia sin publicar >18 meses o sin soporte de la major actual de Dart se
  revisa o se reemplaza.
- Toolchain fijado en el repo (fvm / `.tool-versions` / imagen de CI), no en la máquina de cada uno.

**LISTA DE PROHIBICIONES** (bloquean review)

- ❌ `dynamic` como escape del sistema de tipos; `as` sin comprobación previa sobre datos externos.
- ❌ `!` (bang) por comodidad; `late` para silenciar al analizador.
- ❌ Cadenas de `is`/`if` sobre jerarquías `sealed` en vez de `switch` exhaustivo.
- ❌ `Future` sin `await` ni `unawaited()` explícito; `.then()` sin `onError`/`catchError`.
- ❌ `catch` vacío, `catch` que devuelve un default silencioso, o capturar sin `StackTrace`.
- ❌ `throw` de un `String` o de un tipo que no implemente `Exception`/`Error`.
- ❌ `StreamSubscription`, `Timer` o `ReceivePort` sin cancelar/cerrar.
- ❌ `await Future.delayed(...)` como espera en tests; tests dependientes de orden, de reloj real o de
  servicios de red públicos.
- ❌ PROHIBIDO desactivar `dart format` o mantener un formateador alternativo.
- ❌ PROHIBIDO ignorar diagnósticos con `// ignore:` sin comentario de motivo, y `ignore_for_file` en
  ficheros de código propio.
- ❌ Excluir código propio del `analysis_options.yaml` para que pase el análisis.
- ❌ `any` como constraint de versión; `dependency_overrides` sin issue enlazada y fecha de salida.
- ❌ Aplicación (app/CLI/servicio) **sin `pubspec.lock` versionado**; paquete publicable **con** lock
  versionado y sin job de CI que resuelva contra lo último permitido.
- ❌ Importar `package:otro/src/...` (API privada de otro paquete).
- ❌ Secretos, API keys o endpoints privados compilados en el binario de cliente; confiar en la
  ofuscación como control de confidencialidad.
- ❌ `Random()` para tokens, nonces, IDs de sesión o cualquier uso de seguridad (usa `Random.secure()`).
- ❌ `badCertificateCallback => true`, ni "temporalmente".
- ❌ `Process.run` con línea de shell compuesta a partir de input externo.
- ❌ `print` en código de release; logs con PII o tokens.
- ❌ `dart:mirrors` en código nuevo.
- ❌ Añadir un generador de código sin justificar su coste de build por escrito; commitear generado
  desactualizado.
- ❌ Singletons mutables globales y service locators en vez de inyección por constructor.
- ❌ Fijar versiones de Dart/Flutter de memoria o de un blog en lugar del changelog oficial.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, flag o capacidad en un proyecto real, **verifica online**:

1. **Última stable de Flutter y su Dart empaquetado**: `releases_linux.json` /
   `releases_macos.json` de `storage.googleapis.com/flutter_infra_release/releases/` (campos
   `current_release.stable`, `version`, `dart_sdk_version`) — es la fuente que no miente. A ago-2026:
   stable **Flutter 3.44.8 / Dart 3.12.2** (2026-07-23); beta **3.47.0-0.3.pre / Dart 3.13.0-282.3**.
2. **Última stable de Dart** para proyectos no-Flutter: `dart.dev/get-dart/archive` y el blog oficial.
   **Ojo**: el feed Atom de `dart-lang/sdk` está dominado por builds `-dev` (a 2026-08-03 el más
   reciente era `3.14.0-85.0.dev`) — un `-dev` **no es** la stable. **Discrepancia declarada a
   ago-2026**: el blog de Dart no tenía aún post de anuncio de 3.13 y la página de *breaking changes*
   seguía marcándolo como no publicado, mientras Flutter beta ya empaqueta 3.13.0-beta. Confirma el
   estado de 3.13/3.14 antes de asumir nada.
3. **Lint set recomendado hoy**: `dart.dev/tools/linter-rules` (`lints`: `core`/`recommended` vs
   `flutter_lints`) y la última major de esos paquetes en pub.dev. `very_good_analysis` es de
   terceros: comprueba versión, licencia y actividad antes de adoptarlo.
4. **Estado de WasmGC como target de Flutter/Dart**: `docs.flutter.dev/platform-integration/web/wasm`
   y `dart.dev/tools/dart-compile`. **Discrepancia declarada a ago-2026**: la doc de `dart compile`
   califica el output `wasm` como *"currently under development"*, mientras la doc de Flutter web
   documenta `flutter build web --wasm` como camino soportado con caveats de navegador. No son lo
   mismo (CLI standalone vs. pipeline de Flutter web) pero el estado exacto de cada uno debe
   confirmarse antes de comprometer una plataforma; y el soporte de Firefox/Safari/iOS cambia — mira
   los bugs enlazados (bugzilla 1788206, webkit 267291) antes de descartarlo o darlo por bueno.
5. **Estado de los macros / metaprogramación estática**: cancelados en ene-2025 (`dart-lang/macros`
   archivado); comprobar si **augmentations** ya han llegado al lenguaje, porque cambiaría el criterio
   sobre codegen de §3.
6. **Breaking changes del SDK** antes de subir el constraint: `dart.dev/resources/breaking-changes` y
   `dart.dev/changelog`.
7. **CVEs y advisories** de cada dependencia directa (osv.dev, GitHub Advisories) y estado de
   mantenimiento en pub.dev antes de fijarla.

**Hueco no verificado a ago-2026**: no se ha comprobado en esta redacción el estado actual de
`mockito` (versión, mantenimiento) ni el de `freezed` 3.x más allá del contexto de la cancelación de
macros; ni las cifras concretas de coste de `build_runner` en proyectos grandes, que son dependientes
del repo y deben medirse, no citarse.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
