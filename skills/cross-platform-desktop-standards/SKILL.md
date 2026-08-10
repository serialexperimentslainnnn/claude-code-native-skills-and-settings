---
name: cross-platform-desktop-standards
description: Shipping a desktop application to Windows, macOS and Linux from one codebase, and paying its real cost. Use when choosing between Electron (main.js, preload.js, BrowserWindow, contextIsolation, electron-builder, electron-forge, electron-updater, Squirrel), Tauri (tauri.conf.json, src-tauri, WebView2 / WKWebView / WebKitGTK, the Tauri updater and its signing key), Qt / PySide6 / PyQt (.pro, CMake with Qt6, .ui and .qrc files, qmake, windeployqt / macdeployqt, and the commercial-versus-LGPLv3-versus-GPLv3 licence choice and the relinking obligation), .NET MAUI or Avalonia (.axaml, WinUI 3, Mac Catalyst), Flutter desktop, wxWidgets or GTK, integrating with the OS (tray icon, native notifications, global hotkeys, launch at login, file associations, deep links, clipboard, the user's filesystem), packaging and signing (Authenticode signtool, an EV/OV code-signing certificate on an HSM or token, SmartScreen reputation, macOS codesign with hardened runtime, entitlements, notarytool and stapler, Gatekeeper, .dmg and .pkg, Flatpak manifests and flatpak-builder, snapcraft.yaml and strict versus classic confinement, AppImage, MSIX, MSI, WiX), auto-update channels and update signature verification, or desktop accessibility with UI Automation, NSAccessibility and AT-SPI.
---

# Cross-platform desktop standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **shipping a desktop application to more than one operating system from a single code
base**: choosing the technology with its real cost, integrating with the system, packaging, **signing
and notarising**, distributing, updating and maintaining that for years. It also covers the prior question:
**whether it really has to be a desktop app and not a web app**.

Triggers: Electron's `main.js`/`preload.js`, `BrowserWindow`, `contextIsolation`, `electron-builder`,
`electron-forge`, `electron-updater`, `tauri.conf.json`, `src-tauri/`, WebView2, WKWebView,
WebKitGTK, Avalonia's `.axaml`, WinUI 3, Mac Catalyst, `.pro`/`qmake`/`CMakeLists.txt` with Qt6,
`.ui`, `.qrc`, `windeployqt`, `macdeployqt`, PySide6/PyQt, Flutter desktop, wxWidgets, GTK,
`signtool`, Authenticode, SmartScreen, `codesign`, *hardened runtime*, `.entitlements`, `notarytool`,
`stapler`, Gatekeeper, `.dmg`, `.pkg`, `.msix`, WiX, `flatpak-builder` and its manifest,
`snapcraft.yaml`, AppImage, system tray, native notification, global hotkey, launch at
login, file association, *deep link* with a custom scheme, UI Automation,
NSAccessibility, AT-SPI.

**Guiding principle**: **a desktop app is justified by what the web cannot do.** Frictionless access
to the user's filesystem, permanent presence (tray, global hotkey,
launch with the session), integration with other applications, hardware, working offline
as the normal state and not as a degradation. **If the list of reasons is empty, the answer is a
web app** — or an installable PWA, `pwa-standards` — and you save yourself signing, notarisation, an updater,
per-platform packaging and three distribution channels forever.

**Second thesis, the most underestimated one**: **choosing Electron is signing a recurring security
commitment.** You package Chromium, so **you inherit its CVE calendar**: every Chromium
update is yours, and an app that does not update is a complete attack surface distributed onto the
user's desk. That is not a maintenance detail: it is the main line of the app's operating
budget (§7.1).

**Not applicable**: see `mobile-standards` (**native iOS and Android are theirs**: SwiftUI, Compose, signing and
publishing on the App Store and Play, permissions and the mobile lifecycle. **Boundary: if the same code
also compiles to mobile — Flutter, MAUI, Compose Multiplatform — the desktop part is decided
here and the mobile store part, there**), `pwa-standards` (**the installable web as a real alternative to this
skill**: *service worker*, manifest, *offline* cache and update model are theirs. The
honest comparison: a PWA gives you no tray, no global hotkey, no launch at login, no full
filesystem access; a desktop app costs you signing, notarisation and an updater. That
is the trade-off, and neither skill should soften it), `frontend-frameworks-standards` and
`frontend-web-platform-standards` (**the web UI that goes inside the webview is theirs** — framework, render
model, CSP, bundle budget, build —; **here the window, the process, the bridge to the system and
what gets shipped signed**), `typescript-standards`, `rust-standards`, `dotnet-standards`,
`dart-standards`, `cpp-standards`, `python-standards` (**the language, its build, its lint and its tests
are theirs**; here the desktop app's architecture and its delivery),
`accessibility-standards` (**WCAG and conformance are theirs**; here the native accessibility
APIs — UI Automation, NSAccessibility, AT-SPI — and why an embedded webview meets them in a different
way), `cryptography-pki-standards` (algorithm choice and PKI management; here the concrete use
of code signing and of verification in the updater), `secrets-management-standards`
(**custody and rotation of the private signing key**; here the rule that it lives on an HSM/token and
that signing happens in an isolated CI step), `cicd-standards` (the pipeline that builds, signs and
publishes), `vulnerability-management-standards` (triage and SLA for the CVEs you inherit from Chromium or
Qt), `appsec-standards` (general threat modelling; here the concrete *sinks* of an embedded
webview), `macos-fleet-standards` and `endpoint-security-standards` (**managed fleet deployment,
MDM and application control are theirs**; here producing an artifact those systems
can accept), `i18n-standards` (localisation), `webassembly-standards` (Wasm inside the app).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

The real cost of each option. **There is no free option**: the column that decides is the last one.

| Option | Licence (read raw) | UI engine | What it really costs |
|---|---|---|---|
| **Electron** | MIT | **Bundled** Chromium | Size (~100–200 MB per artifact) and RAM per process; **support only for the 3 most recent stable majors**, with a new major every 8 weeks → **a permanent obligation to repackage for Chromium CVEs** |
| **Tauri 2.x** | `Apache-2.0 OR MIT` (workspace `Cargo.toml`) | **System webview**: WebView2 (Windows), WKWebView (macOS), **WebKitGTK 4.1** (Linux) | A small artifact, but **engine fragmentation**: your app behaves differently per OS and per distro; WebKitGTK is the weak link. It requires Rust on the team |
| **Qt 6** | **Triple**: commercial, **LGPLv3**, and **GPLv3 for certain modules** | Its own native one | The licence (§2.1). Mature widgets, excellent accessibility and performance; the curve and cost of C++ or of the Python *binding* |
| **Avalonia** | MIT (`licence.md`) | Its own renderer (Skia) | .NET everywhere **including Linux**; a smaller ecosystem than WPF and visually less "native" |
| **.NET MAUI** | MIT | Native per platform | **It does not support Linux**: the official docs list Android, iOS, **Mac Catalyst** and Windows (WinUI 3), plus Tizen from Samsung. If you need Linux, MAUI is ruled out from the start |
| **Flutter desktop** | BSD-3-Clause | Its own renderer | Windows/macOS/Linux supported; **the feel is not native** and desktop integration depends on *plugins* of uneven quality. Language: `dart-standards` |
| **wxWidgets** | **wxWindows Library Licence 3.1** (LGPL2+ with a linking exception) | Real native widgets | An old API; the licence exception allows distributing binaries under your own terms, which is its advantage over Qt |
| **GTK 4** | LGPL-2.1+ | Native GNOME | Excellent on Linux, **second-rate on Windows and macOS**. Choosing it for cross-platform work is almost always a mistake |
| **Native per platform** | — | WinUI/AppKit/GTK | Three code bases. The best experience and the highest cost; it is justified in niche professional apps where integration is everything |

**Honest choice criteria, by application type:**

- **Internal company app, web team, short deadline** → **Electron**, with the update budget
  accepted in writing.
- **A small tool, size- or consumption-sensitive, a team with Rust** → **Tauri**, accepting the
  per-webview-engine test matrix.
- **A long-lived app, with a lot of UI, performance, large tables or demanding accessibility** →
  **Qt** (or native). It is the option with the best accessibility and the worst licence cost.
- **A .NET shop that needs Linux** → **Avalonia**. A .NET shop that does not → **WPF/WinUI**
  and it is no longer cross-platform.
- **An app that already exists on mobile with Flutter** → **Flutter desktop**, knowing that the desktop
  integration part is one you will write yourself.
- **A system utility, an administration tool, something with barely any UI** → **a CLI**. Half of
  the desktop apps proposed are a CLI with a window on top.

### 2.1 Qt: the licence is the decision, not the detail

Qt is offered under a **commercial licence**, **LGPLv3** and **GPLv3 depending on the module**. The official
documentation puts it like this: the commercial one is *"appropriate for development of proprietary/commercial software
where you do not want to share any source code"*, and **there are modules that "are not available under LGPL
v3, but under GPL"** — as of Aug 2026 the list includes Qt Quick 3D, Qt MQTT, Qt Virtual Keyboard and Qt
Wayland Compositor, among others (**the list changes between versions: verify it, §8**). Using one of
those modules in a closed product **turns your app into GPL or forces you to buy a licence**.

The classic trap is **static linking**. Under LGPL, Qt's FAQ is explicit: *"Dynamic linking
is usually recommended here"* and *"The user of your application has to be able to re-link your
application against a different or modified version of the Qt library"*; with LGPLv3 it adds that
*"the user needs to be able to run the re-linked binary on its intended target device"*. Translated into
engineering terms:

- **Dynamic linking** of Qt and touch nothing else: it is the path without surprises.
- **Static linking under LGPL** obliges you to ship the objects or the material needed to
  **re-link** your binary with a different version of Qt. It is possible, but it is a permanent
  delivery commitment, and almost nobody who does it honours it.
- **LGPLv3 forbids tivoisation**: if your app goes onto a locked device that prevents replacing the
  library, LGPLv3 is no use to you. There, only a commercial licence works.
- **Mixing is forbidden**: Qt's own website says that *"Combining or mixing the Commercial Qt
  licensing and the Qt Community Edition within the same application or device development project is
  not allowed"*.
- The *bindings* have their own, different licences: **PySide6 is LGPL**, **PyQt is GPL or a
  Riverbank commercial licence**. Choosing PyQt in a closed product without buying a licence is the most repeated
  infringement in the Python ecosystem.

### 2.2 Electron: the calendar is the contract

Electron publishes a major every **8 weeks**, aligned with Chromium's 4-week cycle, and
**"the latest three stable major versions are supported by the Electron team"**. As of Aug 2026 the
official calendar gave (verify §8): **41 → Chromium M146**, **42 → M148**, **43 → M150**, with 44
(M152) planned for 25-Aug-2026. Consequences that go into the project plan, not the backlog:

- **You are at most ~16 weeks from running out of support.** Your app's cadence **is**
  Electron's: budget for a maintenance release every 8 weeks, without exception.
- **Without a working automatic updater you cannot meet this.** The updater is not a
  feature: it is your product's security patching mechanism (§5.3).
- If the 8-week cycle does not fit your organisation (validation, certification, a regulated environment),
  **Electron is the wrong option** and that must be said before starting, not afterwards.

## 3. Structure and conventions

### 3.1 Process and bridge separation

In any webview technology the model is the same: **a privileged process (main/backend) and
a UI process (renderer/webview) that is treated as untrusted**. The bridge between the two is an **explicit
and minimal API**, never generic access.

- Electron: `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true` in every
  renderer. The `preload` exposes **specific functions** through `contextBridge`, never raw
  `ipcRenderer`. Electron's own documentation says it: *"It is paramount that you do not enable
  Node.js integration in any renderer that loads remote content"* and *"Do not expose Electron APIs to
  untrusted web content"*.
- Tauri: an **explicit permission and capability list** in the configuration; the exposed command validates
  its arguments as if they came from the network, because they effectively can.
- Common rule: **the UI process never receives an arbitrary file path or a system
  command.** The backend decides which operation exists; the UI only invokes it.

### 3.2 Integration with the system, which is the app's reason to exist

Every integration point is platform-specific and **you have to decide what is supported on each
one**, not discover it in production:

- **Notifications**: the native API (Windows Toast with a registered AUMID, `UNUserNotificationCenter` on
  macOS, `org.freedesktop.Notifications` on Linux). On macOS they require a signed app and the user's
  permission; **if it is not signed, they do not arrive**.
- **Tray / status area**: on Windows and macOS it is stable; **on Linux it is a minefield**
  (GNOME requires an extension for `AppIndicator`). If the app *depends* on the tray to work,
  the design is wrong: the tray is one entry point, not the only one.
- **Global hotkeys**: they are a shared system resource; a **silent conflict** with other apps
  is the norm. Always configurable, with failure detection on registration. On Wayland, global
  registration is restricted: it is done through a portal, and it may not be available.
- **Launch at login**: `LaunchAgents`/`SMAppService` on macOS, the `Run` key or a Scheduled
  Task on Windows, a `.desktop` file in `~/.config/autostart` on Linux. **Always optional, always
  disableable from the app itself**, and off by default unless the product is resident.
- **File associations and custom schemes (`myapp://`)**: they are **attack surface**. A
  custom scheme allows any web page to invoke your app with parameters; that *handler* validates
  and rejects as if it were a public endpoint. Files opened through an association are parsed with the
  same distrust.
- **Clipboard**: reading it continuously is a data leak (password managers). It is read
  under an explicit user action, never on a timer.
- **The user's filesystem is a responsibility, not a convenience.** Hard rules:
  **atomic** writes (a temporary file on the same volume + `rename`), **never** deleting what you did
  not create, respecting the system paths (`%APPDATA%`, `~/Library/Application Support`,
  XDG on Linux) instead of inventing directories in `$HOME`, and **uninstalling without leaving remains** except
  for the user's data, which you ask about.

### 3.3 Per-platform packaging

| Platform | Default format | Alternative | Note |
|---|---|---|---|
| Windows | **MSI or MSIX** for enterprise | NSIS/Squirrel for consumer | Enterprise needs unattended installation and deployment through GPO/Intune; a per-user installer without MSI makes it impossible for the desktop team |
| macOS | **A signed and notarised `.dmg`** | `.pkg` if system components have to be installed | A universal binary (arm64 + x86_64) or two artifacts, decided explicitly |
| Linux | **Flatpak** | AppImage for "download and run", `.deb`/`.rpm` for a managed fleet | Snap only if the target is Ubuntu and you accept its single store |

**Real isolation differences on Linux, which are not cosmetic:**

- **Flatpak**: a real *sandbox* by default. The official documentation describes the initial state as
  *"no access to any host files except the runtime, the app, `~/.var/app/$FLATPAK_ID` …"*, *"no
  access to the network"*, *"no access to any device nodes"*, *"limited syscalls"*. Access is requested
  through **portals** (file chooser, notifications), which grant implicit permission through a user
  action. **`--filesystem=home` cancels almost all the advantage**: if your manifest carries it, the sandbox
  is decorative. Use it as a review signal.
- **Snap**: **strict** confinement with declared interfaces, or **classic**, which **does not confine** and
  requires manual store approval. If your snap is *classic*, do not sell isolation (verify
  the current wording of the docs, §8).
- **AppImage**: **there is no sandbox, none**. It is a portable binary with its dependencies. It is convenient
  for distribution and **it provides no security guarantee whatsoever**; saying otherwise is lying to the
  user.

## 4. Quality and testing

Gates in order of increasing cost:

1. **Language lint and tests** (delegated to the language skill) + **dependency audit**
   on every build.
2. **Process boundary tests**: every command exposed by the bridge has tests with invalid
   and malicious inputs (paths with `..`, absolute paths, shell symbols, absurd sizes).
3. **E2E of the packaged app, not of the source code**: Playwright with the Electron driver,
   WebdriverIO, or the technology's native *runner*. Testing the app unpackaged leaves out
   exactly the failures that only appear when packaged (resource paths, signing, permissions).
4. **A real platform matrix in CI**: Windows, macOS (arm64 **and** x86_64 if you publish both) and at
   least two different Linux environments. With Tauri, the matrix includes the **WebKitGTK version**, because
   that is where it breaks.
5. **Installation, update and uninstallation testing** as a test case, including the
   **update from version N-2**. Migration of the user's data between versions is
   tested with real data from the old version, not with new data.
6. **Measured cold start** and artifact size **with a threshold that breaks the build**. Without a threshold,
   both grow monotonically.
7. **Accessibility**: a complete run with the keyboard and with each platform's screen reader
   (Narrator/NVDA, VoiceOver, Orca). It is the gate almost nobody puts in and the one that avoids the most problems.

## 5. Stack security

### 5.1 The embedded webview

Apply Electron's official checklist in full (equivalent in Tauri): **HTTPS content only**,
`contextIsolation` on, `nodeIntegration` off, `sandbox` on, **a defined CSP**,
`webSecurity` **never** disabled, `allowRunningInsecureContent` off, an explicit handler for
permission requests, and **`shell.openExternal` never with untrusted content** — the docs themselves
warn that *"improper use of openExternal can be leveraged to compromise the user's host"*.

**An additional rule that does not appear in the checklists: do not load a remote URL as the application's UI.**
If the content comes from the server, any XSS on your website turns into execution with the
desktop app's privileges. The UI is packaged; the remote content goes into an isolated `webview` with no
bridge, or into the user's browser.

### 5.2 Code signing

- **Windows**: Authenticode signing with a **timestamp** (without one, the binary stops validating
  when the certificate expires). Since **1 June 2023**, the CA/Browser Forum's *Baseline Requirements*
  require the subscriber's private key to be *"generated, stored, and used in a
  suitable Hardware Crypto Module"* — that is, **a token/HSM is mandatory**, which makes it impossible
  to put the `.pfx` into a CI secret and forces you to sign with a cloud signing service or a
  *runner* with access to the HSM. (Current version of the BRs as of Aug 2026: **3.11.0**, verify §8.)
  **SmartScreen** is reputation, not signing: a new OV certificate drags warnings along until it accumulates
  downloads; EV avoids them from the start. Budget for it.
- **Windows, kernel**: if the product includes a **kernel-mode driver**, it is a different world. Since
  **Windows 10 version 1607**, *"Windows will not load any new kernel-mode drivers which are not
  signed by the Dev Portal"*, with limited exceptions (a machine upgraded from an earlier version,
  **Secure Boot disabled**, or an end-entity certificate issued **before 29 July
  2015** chained to a supported cross-signed CA). Translation: **cross-signing is no longer a
  route**; you have to register on the Hardware Dev Center — which **requires an EV certificate** — and sign
  through the portal (attestation or HLK).
- **macOS**: signing with the **hardened runtime** and minimal *entitlements*, **mandatory notarisation** and
  **`stapler`** so that it works offline. Gatekeeper, according to Apple, *"verifies that the software
  is from an identified developer, is notarized by Apple to be free of known malicious content, and
  hasn't been altered"*. Without notarisation, the app **does not open** through the normal route. Every *entitlement*
  you request (`com.apple.security.cs.allow-unsigned-executable-memory`,
  `disable-library-validation`) disables a protection: it is justified one by one or it does not go in.
- **Linux**: repository signing (`.deb`/`.rpm`), signing of the Flatpak *bundle*, and on AppImage
  **a detached signature published alongside the artifact** — which almost nobody verifies, so the verification
  has to be done by your own updater.
- **The private key is never in the repository nor in a CI environment variable.** A token/HSM or
  a signing service; the signing step is an isolated *job*, with the smallest possible surface, and
  audited. See `secrets-management-standards`.

### 5.3 Automatic updates

**An updater without signature verification is a backdoor with a feature's name.** It is
literally a mechanism that downloads a binary and runs it with the user's privileges.
Non-negotiable requirements:

- **HTTPS with certificate validation**, and **the artifact's and the manifest's signature verified by the
  client against a key embedded in the app**. Tauri imposes it by design: *"Tauri's updater needs a
  signature to verify that the update is from a trusted source. This cannot be disabled."* That is the
  bar for any other technology.
- **The updater's signing key is different from the code-signing one** and losing it is
  terminal: Tauri's own docs say so — *"if you lose this key you will NOT be able to publish new
  updates to the users that have the app already installed"*. Custody and backup with the same rigour as
  a root CA.
- **Protection against *downgrade***: the client rejects versions lower than the installed one.
- **Phased rollout with a stop switch**, because a bad update is distributed to
  the whole installed base within hours and **it cannot be reverted from the server**.
- **No mandatory telemetry in order to update**: the update channel is not an analytics
  channel. See `privacy-engineering-standards`.

### 5.4 Local data

Credentials and tokens go to the system store (**DPAPI/Credential Manager**, **Keychain**,
**Secret Service/`libsecret`**), never into a JSON file in `%APPDATA%`. And the honest warning: **the
system store protects against another user of the machine, not against malware running as
the user themselves.** Promising more than that is false.

## 6. Performance and operability

- **An explicit budget measured in CI**: installer size, installed size, RAM at rest
  after 30 min with the app open, and **time to an interactive window on cold start** with
  a cold disk. *Any* Electron consumption figure quoted without stating the version, the number of renderers
  and the methodology is folklore: **measure your own and set it as the threshold**, do not quote one from a blog.
- **A webview's real cost is not the binary, it is the process per window.** Reducing windows and
  renderers is worth more than optimising the bundle.
- **Start-up**: a visible window first, content after; lazy loading of everything non-critical.
- **Desktop telemetry, if it exists**: **explicit and disableable consent**, without
  persistent identifiers unless a need is demonstrated, and with what is sent documented. The
  useful minimum: version, platform, and **the fraction of the installed base per version** — without that data you do not
  know how many people are still on a vulnerable version, which is the key operational metric.
- **Errors and *crash reports***: symbolised, without PII, with bounded retention, and **with a way to
  disable them** in managed deployments.
- **A rotated and bounded local log** at the platform's standard path, and accessible from the
  app itself ("open log folder"): it is the difference between a solvable support ticket and
  an eternal one.

## 7. Long-term sustainability

### 7.1 The recurring commitment

Before writing a line, someone signs up to this: **the engine's update cadence** (8 weeks
with Electron; with Tauri, whatever your users' systems update to, which **you do not control**),
**renewal of the signing certificate** with its 90-day reminder, the **annual Apple
Developer Program fee** without which you can no longer notarise — and therefore no longer publish —, and a **matrix
of supported operating systems with a retirement date**. A desktop app with no owner for these
four things ends up unable to publish the day something expires, usually in the middle of an incident.

### 7.2 Prohibitions

- ❌ **FORBIDDEN** to disable `contextIsolation` or enable `nodeIntegration` in a renderer that loads
  remote content.
- ❌ **FORBIDDEN** to disable `webSecurity`, `sandbox` or TLS certificate validation "for
  development" on a branch that can reach a *release*.
- ❌ **FORBIDDEN** to expose `ipcRenderer` or a generic execution API to the webview: the surface is
  a list of specific and validated commands.
- ❌ **FORBIDDEN** to load the main UI from a remote URL.
- ❌ **FORBIDDEN** to distribute unsigned on Windows and macOS, and **forbidden to publish on macOS without
  notarising and without `stapler`**.
- ❌ **FORBIDDEN** to store the signing certificate or its password in the repository, in the CI
  image or in an environment variable; and forbidden to sign without a timestamp.
- ❌ **FORBIDDEN** an updater that does not verify the artifact's signature, or that accepts versions
  lower than the installed one.
- ❌ **FORBIDDEN** to stay on an unsupported Electron version (outside the three current
  majors) in a distributed product.
- ❌ **FORBIDDEN** to link Qt statically under LGPL without meeting — and documenting — the re-linking
  obligation; and forbidden to use a GPL-only Qt module in a closed product without a commercial licence.
- ❌ **FORBIDDEN** to use PyQt in a closed product without a Riverbank licence (PySide6 is the LGPL route).
- ❌ **FORBIDDEN** `--filesystem=home` in a Flatpak manifest without reviewed justification, and
  forbidden to sell an AppImage or a *classic* snap as "isolated".
- ❌ **FORBIDDEN** to store credentials outside the system store.
- ❌ **FORBIDDEN** to write to the user's filesystem non-atomically, outside the
  platform's standard paths, or to delete files the app did not create.
- ❌ **FORBIDDEN** to read the clipboard continuously or in the background.
- ❌ **FORBIDDEN** to register a `myapp://` scheme without treating its parameters as hostile input.
- ❌ **FORBIDDEN** telemetry enabled by default without consent, or an update conditional on
  accepting it.
- ❌ **FORBIDDEN** to ship without a complete keyboard run and a screen-reader test.
- ❌ **FORBIDDEN** to quote "typical" Electron RAM consumption or sizes without your own measurement (§6).

## 8. Mandatory web verification

- **Electron**: `releases.electronjs.org/schedule` — which majors are within the three supported
  **today**, their EOL dates and the associated Chromium version. As of Aug 2026: 41/42/43 (M146/M148/M150),
  with 44 (M152) planned for 25-Aug-2026.
- **Tauri**: current version (2.11.5 as of Aug 2026), the workspace's minimum `rust-version`, webview
  engines and minimum versions per platform, and the state of WebKitGTK in the target distros.
- **Qt**: the **current list of GPL-only modules** at `doc.qt.io/qt-6/licensing.html` — it changes between
  versions — and the terms of the current commercial licence. **Read the licence of the specific
  *binding*** (PySide6 vs. PyQt) before choosing it.
- **Raw licences** (`LICENSE`, `LICENCE`, `licence.md`, `COPYING`, watch out for `master` vs. `main`)
  of any UI framework you link against. Verified for this document: Tauri
  `Apache-2.0 OR MIT`, Avalonia MIT, wxWidgets **wxWindows Library Licence 3.1**.
- **Windows code signing**: the current version of the CA/Browser Forum's *Baseline Requirements*
  (3.11.0, effective 16-Jun-2026, as of Aug 2026) and the hardware module requirements; the current offering of
  cloud signing services compatible with CI.
- **macOS**: the current notarisation requirements, the current tool (`notarytool`; `altool` is
  retired) and Gatekeeper or *entitlement* changes in the latest macOS version.
- **Linux**: the current wording of Snap's confinement modes (*strict*/*classic*/*devmode*) and
  of the *classic* approval process — **this document could not verify it in the official
  source** (the Snapcraft docs did not respond); treat it as pending. The state of Flatpak's portals
  for global hotkeys and autostart under Wayland.
- **.NET MAUI / Avalonia / Flutter**: supported platforms and minimum versions in the official docs —
  as of Aug 2026 **MAUI does not list Linux**.
- **CVEs**: of Chromium (if Electron), of WebKitGTK and WebView2 (if Tauri), of Qt (if Qt). It is a
  continuous flow, not a one-off check → `vulnerability-management-standards`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
