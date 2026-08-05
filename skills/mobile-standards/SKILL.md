---
name: mobile-standards
description: Native mobile engineering standards for iOS and Android. Use when working with .swift files, SwiftUI, Package.swift, Xcode projects (.xcodeproj/.xcworkspace), Info.plist, or with .kt files, Jetpack Compose, build.gradle.kts, libs.versions.toml, AndroidManifest.xml, or tasks about app signing, distribution, Keychain/Keystore, or mobile testing.
---

# Estándares móvil nativo (iOS / Android)

## 1. Alcance y triggers

Aplica a desarrollo nativo: **iOS** (ficheros `.swift`, `Package.swift`, `.xcodeproj`/
`.xcworkspace`, `Info.plist`, `.entitlements`, SwiftUI) y **Android** (`.kt`,
`build.gradle.kts`, `settings.gradle.kts`, `gradle/libs.versions.toml`, `AndroidManifest.xml`,
Jetpack Compose). Cubre código, arquitectura, build, firma, distribución, seguridad y testing.
Cross-platform (Flutter/RN/KMP-UI) queda fuera salvo la parte nativa que toquen. **Frontera con
`dart-standards` (Ola 5), espejada desde su §1**: **el diseño de la app es de aquí** —arquitectura,
navegación, ciclo de vida de la plataforma, permisos, publicación en App Store y Play, firma,
actualizaciones, rendimiento percibido, accesibilidad, almacenamiento seguro en el dispositivo—;
**el lenguaje Dart y su tooling** —`pubspec.yaml`, `analysis_options.yaml`, `dart format`, los lint
sets, `build_runner`, isolates, los tests de `package:test`— **son suyos**. Swift y Kotlin nativos
siguen siendo de aquí; `objective-c-standards` (**Ola 5**) cubre el lado Objective-C de la
interoperabilidad con Swift en código heredado. **La web instalable es de `pwa-standards`**
(**Ola 6**): service worker, manifiesto, caché offline y el modelo de actualización. La comparación
PWA frente a nativa se decide con dos datos que **ninguna de las dos skills debe suavizar**: en iOS
la Push API **solo funciona en web apps instaladas**, y **una PWA no instalada no tiene
almacenamiento duradero** —queda sujeta al borrado de ITP—. Si el requisito exige distribución por
tienda, capacidades de hardware o presencia garantizada, manda esta skill.

**No aplica**: ver `jvm-spring-standards` (Kotlin de backend con Spring: aquí Kotlin es solo lenguaje
de app Android), `typescript-standards` (React Native y la web que consume la misma API),
`api-design-standards` (diseño del contrato que consume la app: recursos, códigos, paginación,
versionado — aquí solo el cliente HTTP y el manejo de errores en dispositivo), `appsec-standards`
(modelado de amenazas y clases de vulnerabilidad agnósticas; aquí el equivalente móvil es OWASP MASVS
y sí es de esta skill), `identity-access-management-standards` (flujos OAuth 2.1/OIDC, PKCE y
passkeys del lado del IdP; aquí solo su uso desde el dispositivo y el almacenamiento del token en
Keychain/Keystore), `cryptography-pki-standards` (elección de algoritmos y certificate pinning como
criterio; aquí su aplicación con las APIs de la plataforma), `cicd-standards` (la pipeline; la
**firma y distribución** en App Store/Play sí es de esta skill), `observability-standards` (backend
de telemetría; aquí crash reporting y métricas de cliente), `cross-platform-desktop-standards`
(**el escritorio multiplataforma es suyo**: empaquetado, firma y notarización, actualización e
integración con el sistema. **Arbitraje para Flutter, .NET MAUI y Compose Multiplatform: el
objetivo escritorio se decide allí, el objetivo móvil y su tienda, aquí**).

**Regla cero**: detecta el proyecto real primero (versiones en `Package.swift`/
`libs.versions.toml`, targets mínimos, arquitectura existente) y respeta sus convenciones;
este criterio rige lo nuevo y lo que se señala como deuda.

## 2. Toolchain por defecto

> **Nota de verificación**: comprobado vía web el 2026-08-02 (developer.apple.com,
> developer.android.com, kotlinlang.org). **Verifica en la web antes de fijar versiones** en un
> proyecto: Apple y Google mueven requisitos de tienda y toolchain varias veces al año.

**iOS**
- **Xcode 26.x** (estable actual: 26.6) con **Swift 6.3**; Xcode 27/Swift 6.4 en beta — no para
  producción hasta estable. App Store exige compilar con SDK iOS 26+ desde 2026-04-28.
- **Swift 6 language mode** (concurrencia estricta comprobada por el compilador) en targets nuevos.
- **SwiftUI** por defecto para UI nueva; UIKit solo por interoperabilidad o carencia medida.
- **Swift Concurrency** (`async/await`, actores, `Sendable`) — no Combine ni GCD para código nuevo.
- **SPM** como gestor de dependencias único; CocoaPods/Carthage solo en legado, con plan de salida.
- Formato/lint: **swift-format** o SwiftLint+SwiftFormat, en CI.

**Android**
- **Kotlin 2.4.x** (K2), **AGP 9.x** (estable actual 9.1.1; requiere **Gradle ≥9.1** y JDK 17;
  Kotlin viene integrado en AGP 9 — no apliques `org.jetbrains.kotlin.android` aparte).
- **compileSdk/targetSdk 36** (Android 16): Google Play lo exige para apps nuevas y updates desde
  2026-08-31. Librerías nativas alineadas a **16 KB page size** (obligatorio en Play desde
  2026-05-31). `minSdk` por datos de audiencia, no por comodidad.
- **Jetpack Compose** con **BOM estable** (actual `2026.04.01`, Compose 1.11) para TODA UI nueva;
  Views/XML solo mantenimiento.
- **Coroutines + Flow** para asincronía; `StateFlow` para estado observable. Nada de
  RxJava/AsyncTask/callbacks en código nuevo.
- **Gradle version catalogs** (`libs.versions.toml`) obligatorio: cero versiones hardcodeadas en
  `build.gradle.kts`. Convention plugins para multi-módulo.
- Formato/lint: **ktlint** o ktfmt + **Android Lint** + **detekt**, en CI.

## 3. Estructura y convenciones

**Común**
- Arquitectura **UDF (flujo de datos unidireccional)**: UI declarativa sin lógica; estado en un
  holder observable; eventos suben, estado baja. Capas: UI → dominio (opcional) → datos
  (repositorio como única fuente de verdad).
- Inmutabilidad por defecto (`let`/`val`, `struct`/`data class`); estado mutable encapsulado.
- Inyección de dependencias por constructor: Hilt (Android), inyección manual o factories (iOS) —
  sin service locators globales ni singletons mutables.
- Errores explícitos: `Result`/`throws` tipados en iOS; excepciones/`Result` + estados de error
  modelados en el UiState en Android. Prohibido tragar errores (catch vacío, `try?` silencioso
  sin decisión consciente).

**iOS**
- SwiftUI: vistas pequeñas y componibles; estado con `@State`/`@Observable` (macro Observation,
  no `ObservableObject` en código nuevo); navegación con `NavigationStack` y rutas tipadas.
- Concurrencia: UI en `@MainActor`; aislamiento con actores; tipos compartidos `Sendable`;
  prohibido `@unchecked Sendable` sin invariante documentada.
- Un módulo SPM por feature/capa cuando el proyecto crece; targets de test por módulo.

**Android**
- Compose: composables sin estado (*state hoisting*), `Modifier` como último parámetro con default,
  previews por estado (loading/error/vacío/contenido), estabilidad vigilada (compose compiler
  metrics si hay jank).
- `ViewModel` + `StateFlow` con `collectAsStateWithLifecycle`; nada de lógica en composables.
- Multi-módulo por feature (`:feature:x`, `:core:designsystem`, `:core:data`) cuando escala;
  `api`/`implementation` bien usados para no filtrar dependencias.

## 4. Calidad: formato, lint, análisis estático, testing

Gates de CI bloqueantes en ambas plataformas — sin verde no hay merge:
1. Formato (swift-format / ktlint) en modo check.
2. Lint/estático: SwiftLint sin violaciones nuevas; Android Lint con `lintOptions.abortOnError`,
   detekt sin issues; **warnings del compilador tratados como errores** en código propio
   (incluida la comprobación estricta de concurrencia de Swift 6).
3. Tests unitarios + de UI en emulador/simulador; build de release firmable.
4. Baselines (lint/detekt) solo para adopción en legado: congeladas y solo decrecen.

Criterio de testing:
- **Pirámide**: mayoría unitarios sobre dominio/ViewModels/state holders (rápidos, sin
  emulador); integración los justos; UI/E2E pocos y estables.
- **iOS**: **Swift Testing** (`@Test`, `#expect`) para unitarios nuevos, XCTest donde ya exista;
  XCUITest para flujos críticos; snapshot tests para vistas SwiftUI de alto valor.
- **Android**: JUnit + Turbine (Flows) + MockK; `runTest` con dispatchers inyectados (regla de
  `TestDispatcher` — nunca `Dispatchers.Main` real en tests); `createComposeTestRule` para UI;
  screenshot tests (Compose Preview Screenshot Testing/Paparazzi) para el design system;
  Espresso/instrumentación solo para flujos E2E críticos.
- Cubre **bordes y errores**: sin red, timeout, respuesta malformada, permiso denegado, proceso
  muerto/restauración de estado, rotación, dark mode, tamaños de texto accesibles.
- Cero flakiness: test inestable se arregla o se borra; nada de `sleep`s — usa idling/espera por
  condición. Todo bugfix deja test de regresión.

## 5. Seguridad del stack (OWASP MASVS como referencia)

- **Almacenamiento seguro**: credenciales/tokens SOLO en **Keychain** (iOS;
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` por defecto, sin sincronizar a iCloud lo que no
  deba) y **Android Keystore** (claves hardware-backed; datos cifrados con esas claves —
  `EncryptedSharedPreferences` está deprecado: cifra con Keystore + AES-GCM o usa DataStore con
  cifrado propio). PROHIBIDO: tokens en UserDefaults/SharedPreferences/ficheros en claro, logs
  con datos sensibles, secretos hardcodeados en el binario (se extraen con `strings`).
- **Red**: TLS 1.2+ siempre; ATS activo sin excepciones globales (iOS); `networkSecurityConfig`
  sin cleartext (Android). Certificate pinning solo con plan de rotación (fallo de pin = app
  muerta). Valida TODO input del servidor: el backend también es frontera.
- **Firma y distribución**:
  - iOS: firma automática gestionada por Xcode Cloud/fastlane match con certificados en repo
    cifrado o en el gestor del CI; claves de distribución NUNCA en el repo ni en el portátil de
    una sola persona. API keys de App Store Connect con rol mínimo.
  - Android: **Play App Signing** obligatorio (Google custodia la clave de firma; tú la de
    upload, rotable si se compromete). Keystore de upload en el gestor de secretos del CI, nunca
    en el repo; `signingConfig` lee de env vars. AAB para Play; APK firmado solo para
    distribución directa justificada.
  - Publicación por canales: internal → closed → producción con rollout gradual y monitorización
    de crashes antes de ampliar porcentaje.
- **Permisos y privacidad**: mínimo privilegio, pedidos en contexto con justificación; Privacy
  Manifest (iOS) y Data Safety (Play) veraces y mantenidos. Datos personales: minimización,
  cifrado en reposo, borrado real al cerrar cuenta (GDPR).
- **SCA y cadena de suministro**: dependencias fijadas (`Package.resolved` y catálogo + lockfile
  de Gradle versionados); Dependabot/Renovate; sin librerías abandonadas. R8 activo en release
  (Android); no deshabilites el *stripping* de símbolos públicos sin motivo.
- No implementes cripto casera: CryptoKit (iOS) / Keystore+AES-GCM o Tink (Android).
  `SecRandomCopyBytes`/`SecureRandom` para aleatoriedad de seguridad.

## 6. Rendimiento y operabilidad

- **Arranque**: mide cold start (Instruments App Launch / Macrobenchmark + Baseline Profiles en
  Android — genera y versiona los baseline profiles); nada pesado en `application(_:didFinish…)`
  / `Application.onCreate` — difiere e inicializa perezoso (App Startup en Android).
- **UI fluida**: sin trabajo síncrono pesado en main thread/composición; en Compose vigila
  recomposiciones (claves estables, `derivedStateOf`, lambdas estables); en SwiftUI evita
  invalidaciones amplias (estado granular con Observation). Listas siempre lazy con ids estables.
- **Memoria y energía**: Instruments (Leaks/Allocations) y LeakCanary en debug; cuidado con
  capturas fuertes en closures/lambdas de larga vida; trabajo en background con las APIs del
  sistema (BackgroundTasks / WorkManager con constraints), nunca timers/polling propios.
- **Observabilidad**: crash reporting (Crashlytics/Sentry) + MetricKit y Android Vitals como SLI
  (crash-free rate, ANR rate, arranque); logs estructurados sin PII; monitoriza cada release
  durante el rollout gradual y aborta si degrada.
- **Resiliencia offline**: la red SIEMPRE falla — timeouts, retry con backoff+jitter, caché local
  (SwiftData/GRDB, Room) y UI con estados de error/reintento; operaciones de escritura
  idempotentes frente a reintentos.
- Tamaño de app vigilado en CI (app thinning / App Bundle); assets optimizados.

## 7. Sostenibilidad: cadencia de upgrades y prohibiciones

**Cadencia**:
- **iOS**: adopta el Xcode/SDK nuevo cada otoño en <6 meses (App Store lo convierte en requisito
  duro cada primavera — en 2026 fue SDK iOS 26 desde el 28 de abril). Sube el deployment target
  a N-1/N-2 según audiencia real.
- **Android**: targetSdk al nivel exigido por Play ANTES del deadline anual del 31 de agosto
  (2026: API 36); AGP/Gradle/Kotlin al ritmo de Android Studio estable; Compose BOM estable
  trimestral.
- Dependencias: Renovate/Dependabot semanal; parches de seguridad en <72 h; una versión de
  toolchain por repo (fijada en catálogo/`.xcode-version`), no "la que tenga cada máquina".

**LISTA DE PROHIBICIONES** (bloquean review):
- Secretos, API keys o keystores en el repo o hardcodeados en el binario.
- Tokens/credenciales fuera de Keychain/Keystore; logs con PII o secretos.
- Cleartext HTTP; excepción global de ATS; desactivar validación TLS "para probar".
- iOS: `@unchecked Sendable` sin invariante documentada; `DispatchSemaphore` para "esperar" async;
  force unwrap (`!`) y `try!` fuera de tests o invariantes probadas; nuevos `ObservableObject` en
  targets con Observation disponible.
- Android: versiones hardcodeadas fuera del catálogo; `GlobalScope`; `runBlocking` en main;
  `Dispatchers` sin inyectar; acceso a disco/red en main thread; `!!` como estilo;
  `EncryptedSharedPreferences` en código nuevo (deprecado).
- UI nueva en UIKit/XML sin justificación de interoperabilidad escrita.
- Silenciar warnings de concurrencia estricta o lint con supresiones sin comentario de motivo.
- Publicar sin canal de pruebas ni rollout gradual; deshabilitar crash reporting en release.
- WebViews con `javaScriptEnabled` + contenido no confiable, o puentes JS expuestos sin allowlist.
- Detección casera de jailbreak/root como único control de seguridad (es mitigación débil, no
  frontera).

## 8. Verificación web obligatoria

Antes de fijar CUALQUIER versión o requisito en un proyecto real, **verifícalo en la web**:
- Xcode/Swift estables y requisito de SDK de App Store: developer.apple.com/news y notas de
  release de Xcode.
- Requisitos de Google Play (targetSdk, deadlines, 16 KB pages): developer.android.com y Play
  Console Help.
- Compatibilidad AGP ↔ Gradle ↔ Kotlin ↔ Compose BOM: tabla oficial en
  developer.android.com/build/releases y kotlinlang.org/docs/releases.html.
- CVEs de dependencias móviles (GitHub Advisories) antes de recomendar una librería.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
