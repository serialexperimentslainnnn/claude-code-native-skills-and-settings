---
name: mobile-standards
description: Native mobile engineering standards for iOS and Android. Use when working with .swift files, SwiftUI, Package.swift, Xcode projects (.xcodeproj/.xcworkspace), Info.plist, or with .kt files, Jetpack Compose, build.gradle.kts, libs.versions.toml, AndroidManifest.xml, or tasks about app signing, distribution, Keychain/Keystore, or mobile testing.
---

# Native mobile standards (iOS / Android)

## 1. Scope and triggers

Applies to native development: **iOS** (`.swift` files, `Package.swift`, `.xcodeproj`/
`.xcworkspace`, `Info.plist`, `.entitlements`, SwiftUI) and **Android** (`.kt`,
`build.gradle.kts`, `settings.gradle.kts`, `gradle/libs.versions.toml`, `AndroidManifest.xml`,
Jetpack Compose). Covers code, architecture, build, signing, distribution, security and testing.
Cross-platform (Flutter/RN/KMP-UI) is out of scope except for the native part they touch. **Boundary with
`dart-standards`, mirrored from its §1**: **the app's design belongs here** —architecture,
navigation, platform lifecycle, permissions, publishing on the App Store and Play, signing,
updates, perceived performance, accessibility, secure storage on the device—;
**the Dart language and its tooling** —`pubspec.yaml`, `analysis_options.yaml`, `dart format`, the lint
sets, `build_runner`, isolates, the `package:test` tests— **are theirs**. Native Swift and Kotlin
still belong here; `objective-c-standards` covers the Objective-C side of
interoperability with Swift in legacy code. **The installable web belongs to `pwa-standards`**:
service worker, manifest, offline cache and the update model. The comparison
of PWA versus native is decided with two facts that **neither of the two skills should soften**: on iOS
the Push API **only works in installed web apps**, and **a non-installed PWA has no
durable storage** —it is subject to ITP eviction—. If the requirement demands store
distribution, hardware capabilities or guaranteed presence, this skill wins.

**Not applicable**: see `jvm-spring-standards` (backend Kotlin with Spring: here Kotlin is only the language
of an Android app), `typescript-standards` (React Native and the web consuming the same API),
`api-design-standards` (design of the contract the app consumes: resources, codes, pagination,
versioning — here only the HTTP client and error handling on the device), `appsec-standards`
(threat modelling and agnostic vulnerability classes; here the mobile equivalent is OWASP MASVS
and it does belong to this skill), `identity-access-management-standards` (OAuth 2.1/OIDC flows, PKCE and
passkeys on the IdP side; here only their use from the device and the storage of the token in
Keychain/Keystore), `cryptography-pki-standards` (choice of algorithms and certificate pinning as
criteria; here their application with the platform APIs), `cicd-standards` (the pipeline; the
**signing and distribution** on the App Store/Play does belong to this skill), `observability-standards` (telemetry
backend; here crash reporting and client-side metrics), `cross-platform-desktop-standards`
(**the cross-platform desktop is theirs**: packaging, signing and notarisation, updates and
integration with the system. **Arbitration for Flutter, .NET MAUI and Compose Multiplatform: the
desktop target is decided there, the mobile target and its store, here**).

**Rule zero**: detect the real project first (versions in `Package.swift`/
`libs.versions.toml`, minimum targets, existing architecture) and respect its conventions;
this criteria governs what is new and what is flagged as debt.

## 2. Default toolchain

> **Verified note**: checked via the web on 2026-08-02 (developer.apple.com,
> developer.android.com, kotlinlang.org). **Verify on the web before pinning versions** in a
> project: Apple and Google move store and toolchain requirements several times a year.

**iOS**
- **Xcode 26.x** (current stable: 26.6) with **Swift 6.3**; Xcode 27/Swift 6.4 in beta — not for
  production until stable. The App Store requires building with SDK iOS 26+ since 2026-04-28.
- **Swift 6 language mode** (strict concurrency checked by the compiler) in new targets.
- **SwiftUI** by default for new UI; UIKit only for interoperability or a measured shortcoming.
- **Swift Concurrency** (`async/await`, actors, `Sendable`) — not Combine nor GCD for new code.
- **SPM** as the single dependency manager; CocoaPods/Carthage only in legacy, with an exit plan.
- Formatting/lint: **swift-format** or SwiftLint+SwiftFormat, in CI.

**Android**
- **Kotlin 2.4.x** (K2), **AGP 9.x** (current stable 9.1.1; requires **Gradle ≥9.1** and JDK 17;
  Kotlin comes integrated in AGP 9 — do not apply `org.jetbrains.kotlin.android` separately).
- **compileSdk/targetSdk 36** (Android 16): Google Play requires it for new apps and updates from
  2026-08-31. Native libraries aligned to **16 KB page size** (mandatory on Play since
  2026-05-31). `minSdk` by audience data, not by convenience.
- **Jetpack Compose** with a **stable BOM** (currently `2026.04.01`, Compose 1.11) for ALL new UI;
  Views/XML maintenance only.
- **Coroutines + Flow** for asynchrony; `StateFlow` for observable state. No
  RxJava/AsyncTask/callbacks in new code.
- **Gradle version catalogs** (`libs.versions.toml`) mandatory: zero hardcoded versions in
  `build.gradle.kts`. Convention plugins for multi-module.
- Formatting/lint: **ktlint** or ktfmt + **Android Lint** + **detekt**, in CI.

## 3. Structure and conventions

**Common**
- **UDF (unidirectional data flow)** architecture: declarative UI with no logic; state in an
  observable holder; events go up, state comes down. Layers: UI → domain (optional) → data
  (repository as the single source of truth).
- Immutability by default (`let`/`val`, `struct`/`data class`); mutable state encapsulated.
- Constructor dependency injection: Hilt (Android), manual injection or factories (iOS) —
  no global service locators nor mutable singletons.
- Explicit errors: typed `Result`/`throws` on iOS; exceptions/`Result` + error states
  modelled in the UiState on Android. Forbidden to swallow errors (empty catch, silent `try?`
  without a conscious decision).

**iOS**
- SwiftUI: small, composable views; state with `@State`/`@Observable` (Observation macro,
  not `ObservableObject` in new code); navigation with `NavigationStack` and typed routes.
- Concurrency: UI on `@MainActor`; isolation with actors; shared types `Sendable`;
  `@unchecked Sendable` forbidden without a documented invariant.
- One SPM module per feature/layer when the project grows; test targets per module.

**Android**
- Compose: stateless composables (*state hoisting*), `Modifier` as the last parameter with a default,
  previews per state (loading/error/empty/content), stability watched (compose compiler
  metrics if there is jank).
- `ViewModel` + `StateFlow` with `collectAsStateWithLifecycle`; no logic in composables.
- Multi-module per feature (`:feature:x`, `:core:designsystem`, `:core:data`) when it scales;
  `api`/`implementation` used properly so as not to leak dependencies.

## 4. Quality: formatting, lint, static analysis, testing

Blocking CI gates on both platforms — no green, no merge:
1. Formatting (swift-format / ktlint) in check mode.
2. Lint/static: SwiftLint with no new violations; Android Lint with `lintOptions.abortOnError`,
   detekt with no issues; **compiler warnings treated as errors** in our own code
   (including Swift 6's strict concurrency checking).
3. Unit + UI tests on emulator/simulator; a signable release build.
4. Baselines (lint/detekt) only for adoption in legacy: frozen and only ever shrinking.

Testing criteria:
- **Pyramid**: mostly unit tests over domain/ViewModels/state holders (fast, without an
  emulator); just enough integration; few and stable UI/E2E.
- **iOS**: **Swift Testing** (`@Test`, `#expect`) for new unit tests, XCTest where it already exists;
  XCUITest for critical flows; snapshot tests for high-value SwiftUI views.
- **Android**: JUnit + Turbine (Flows) + MockK; `runTest` with injected dispatchers (the
  `TestDispatcher` rule — never the real `Dispatchers.Main` in tests); `createComposeTestRule` for UI;
  screenshot tests (Compose Preview Screenshot Testing/Paparazzi) for the design system;
  Espresso/instrumentation only for critical E2E flows.
- Cover **edges and errors**: no network, timeout, malformed response, denied permission, killed
  process/state restoration, rotation, dark mode, accessible text sizes.
- Zero flakiness: an unstable test is fixed or deleted; no `sleep`s — use idling/waiting on a
  condition. Every bugfix leaves a regression test.

## 5. Stack security (OWASP MASVS as the reference)

- **Secure storage**: credentials/tokens ONLY in the **Keychain** (iOS;
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` by default, not syncing to iCloud what should
  not be) and the **Android Keystore** (hardware-backed keys; data encrypted with those keys —
  `EncryptedSharedPreferences` is deprecated: encrypt with Keystore + AES-GCM or use DataStore with
  your own encryption). FORBIDDEN: tokens in UserDefaults/SharedPreferences/cleartext files, logs
  with sensitive data, secrets hardcoded in the binary (they are extracted with `strings`).
- **Network**: TLS 1.2+ always; ATS active with no global exceptions (iOS); `networkSecurityConfig`
  without cleartext (Android). Certificate pinning only with a rotation plan (pin failure = dead
  app). Validate ALL input from the server: the backend is also a boundary.
- **Signing and distribution**:
  - iOS: automatic signing managed by Xcode Cloud/fastlane match with certificates in an encrypted
    repo or in the CI's manager; distribution keys NEVER in the repo nor on the laptop of
    a single person. App Store Connect API keys with the minimum role.
  - Android: **Play App Signing** mandatory (Google holds the signing key; you hold the
    upload one, rotatable if compromised). Upload keystore in the CI's secrets manager, never
    in the repo; `signingConfig` reads from env vars. AAB for Play; signed APK only for
    justified direct distribution.
  - Publishing through channels: internal → closed → production with gradual rollout and monitoring
    of crashes before widening the percentage.
- **Permissions and privacy**: least privilege, requested in context with justification; Privacy
  Manifest (iOS) and Data Safety (Play) truthful and maintained. Personal data: minimisation,
  encryption at rest, real deletion on account closure (GDPR).
- **SCA and supply chain**: pinned dependencies (`Package.resolved` and catalog + Gradle lockfile
  versioned); Dependabot/Renovate; no abandoned libraries. R8 active in release
  (Android); do not disable public symbol *stripping* without a reason.
- Do not implement homemade crypto: CryptoKit (iOS) / Keystore+AES-GCM or Tink (Android).
  `SecRandomCopyBytes`/`SecureRandom` for security randomness.

## 6. Performance and operability

- **Startup**: measure cold start (Instruments App Launch / Macrobenchmark + Baseline Profiles on
  Android — generate and version the baseline profiles); nothing heavy in `application(_:didFinish…)`
  / `Application.onCreate` — defer and initialise lazily (App Startup on Android).
- **Smooth UI**: no heavy synchronous work on the main thread/composition; in Compose watch
  recompositions (stable keys, `derivedStateOf`, stable lambdas); in SwiftUI avoid
  wide invalidations (granular state with Observation). Lists always lazy with stable ids.
- **Memory and energy**: Instruments (Leaks/Allocations) and LeakCanary in debug; beware of
  strong captures in long-lived closures/lambdas; background work with the system's
  APIs (BackgroundTasks / WorkManager with constraints), never your own timers/polling.
- **Observability**: crash reporting (Crashlytics/Sentry) + MetricKit and Android Vitals as SLIs
  (crash-free rate, ANR rate, startup); structured logs without PII; monitor every release
  during the gradual rollout and abort if it degrades.
- **Offline resilience**: the network ALWAYS fails — timeouts, retry with backoff+jitter, local cache
  (SwiftData/GRDB, Room) and UI with error/retry states; write operations
  idempotent against retries.
- App size watched in CI (app thinning / App Bundle); assets optimised.

## 7. Sustainability: upgrade cadence and prohibitions

**Cadence**:
- **iOS**: adopt the new Xcode/SDK every autumn within <6 months (the App Store turns it into a hard
  requirement every spring — in 2026 it was SDK iOS 26 from 28 April). Raise the deployment target
  to N-1/N-2 according to the real audience.
- **Android**: targetSdk at the level Play requires BEFORE the annual deadline of 31 August
  (2026: API 36); AGP/Gradle/Kotlin at the pace of stable Android Studio; stable Compose BOM
  quarterly.
- Dependencies: Renovate/Dependabot weekly; security patches in <72 h; one toolchain
  version per repo (pinned in the catalog/`.xcode-version`), not "whichever each machine has".

**LIST OF PROHIBITIONS** (they block review):
- Secrets, API keys or keystores in the repo or hardcoded in the binary.
- Tokens/credentials outside the Keychain/Keystore; logs with PII or secrets.
- Cleartext HTTP; a global ATS exception; disabling TLS validation "to test".
- iOS: `@unchecked Sendable` without a documented invariant; `DispatchSemaphore` to "wait" on async;
  force unwrap (`!`) and `try!` outside tests or proven invariants; new `ObservableObject` in
  targets where Observation is available.
- Android: hardcoded versions outside the catalog; `GlobalScope`; `runBlocking` on main;
  `Dispatchers` not injected; disk/network access on the main thread; `!!` as a style;
  `EncryptedSharedPreferences` in new code (deprecated).
- New UI in UIKit/XML without a written interoperability justification.
- Silencing strict concurrency warnings or lint with suppressions lacking a comment stating the reason.
- Publishing without a test channel or gradual rollout; disabling crash reporting in release.
- WebViews with `javaScriptEnabled` + untrusted content, or JS bridges exposed without an allowlist.
- Homemade jailbreak/root detection as the only security control (it is weak mitigation, not a
  boundary).

## 8. Mandatory web verification

Before pinning ANY version or requirement in a real project, **verify it on the web**:
- Stable Xcode/Swift and the App Store SDK requirement: developer.apple.com/news and Xcode
  release notes.
- Google Play requirements (targetSdk, deadlines, 16 KB pages): developer.android.com and Play
  Console Help.
- AGP ↔ Gradle ↔ Kotlin ↔ Compose BOM compatibility: official table at
  developer.android.com/build/releases and kotlinlang.org/docs/releases.html.
- CVEs of mobile dependencies (GitHub Advisories) before recommending a library.

If the web contradicts this document, **the web wins** — flag the discrepancy.
