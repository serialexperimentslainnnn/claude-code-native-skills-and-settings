---
name: cross-platform-desktop-standards
description: Shipping a desktop application to Windows, macOS and Linux from one codebase, and paying its real cost. Use when choosing between Electron (main.js, preload.js, BrowserWindow, contextIsolation, electron-builder, electron-forge, electron-updater, Squirrel), Tauri (tauri.conf.json, src-tauri, WebView2 / WKWebView / WebKitGTK, the Tauri updater and its signing key), Qt / PySide6 / PyQt (.pro, CMake with Qt6, .ui and .qrc files, qmake, windeployqt / macdeployqt, and the commercial-versus-LGPLv3-versus-GPLv3 licence choice and the relinking obligation), .NET MAUI or Avalonia (.axaml, WinUI 3, Mac Catalyst), Flutter desktop, wxWidgets or GTK, integrating with the OS (tray icon, native notifications, global hotkeys, launch at login, file associations, deep links, clipboard, the user's filesystem), packaging and signing (Authenticode signtool, an EV/OV code-signing certificate on an HSM or token, SmartScreen reputation, macOS codesign with hardened runtime, entitlements, notarytool and stapler, Gatekeeper, .dmg and .pkg, Flatpak manifests and flatpak-builder, snapcraft.yaml and strict versus classic confinement, AppImage, MSIX, MSI, WiX), auto-update channels and update signature verification, or desktop accessibility with UI Automation, NSAccessibility and AT-SPI.
---

# Estándares de escritorio multiplataforma

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **entregar una aplicación de escritorio a más de un sistema operativo desde una misma base
de código**: elegir la tecnología con su coste real, integrarse con el sistema, empaquetar, **firmar
y notarizar**, distribuir, actualizar y mantener eso durante años. Cubre también la pregunta previa:
**si de verdad tiene que ser una app de escritorio y no una web**.

Triggers: `main.js`/`preload.js` de Electron, `BrowserWindow`, `contextIsolation`, `electron-builder`,
`electron-forge`, `electron-updater`, `tauri.conf.json`, `src-tauri/`, WebView2, WKWebView,
WebKitGTK, `.axaml` de Avalonia, WinUI 3, Mac Catalyst, `.pro`/`qmake`/`CMakeLists.txt` con Qt6,
`.ui`, `.qrc`, `windeployqt`, `macdeployqt`, PySide6/PyQt, Flutter desktop, wxWidgets, GTK,
`signtool`, Authenticode, SmartScreen, `codesign`, *hardened runtime*, `.entitlements`, `notarytool`,
`stapler`, Gatekeeper, `.dmg`, `.pkg`, `.msix`, WiX, `flatpak-builder` y su manifiesto,
`snapcraft.yaml`, AppImage, bandeja del sistema, notificación nativa, atajo global, arranque al
iniciar sesión, asociación de ficheros, *deep link* con esquema propio, UI Automation,
NSAccessibility, AT-SPI.

**Principio rector**: **una app de escritorio se justifica por lo que la web no puede hacer.** Acceso
al sistema de ficheros del usuario sin fricción, presencia permanente (bandeja, atajo global,
arranque con la sesión), integración con otras aplicaciones, hardware, funcionamiento sin conexión
como estado normal y no como degradación. **Si la lista de razones está vacía, la respuesta es una
web** —o una PWA instalable, `pwa-standards`—, y te ahorras firma, notarización, actualizador,
empaquetado por plataforma y tres canales de distribución para siempre.

**Segunda tesis, la que más se subestima**: **elegir Electron es firmar un compromiso de seguridad
recurrente.** Empaquetas Chromium, así que **heredas su calendario de CVEs**: cada actualización de
Chromium es tuya, y una app que no actualiza es una superficie de ataque completa distribuida en el
puesto del usuario. Eso no es un detalle de mantenimiento: es la línea principal del presupuesto de
operación de la app (§7.1).

**No aplica**: ver `mobile-standards` (**iOS y Android nativos son suyos**: SwiftUI, Compose, firma y
publicación en App Store y Play, permisos y ciclo de vida móvil. **Frontera: si el mismo código
compila también a móvil —Flutter, MAUI, Compose Multiplatform—, la parte de escritorio se decide
aquí y la de tienda móvil, allí**), `pwa-standards` (**la web instalable como alternativa real a esta
skill**: *service worker*, manifiesto, caché *offline* y modelo de actualización son suyos. La
comparación honesta: una PWA no da bandeja, ni atajo global, ni arranque al iniciar sesión, ni acceso
completo al sistema de ficheros; una app de escritorio cuesta firma, notarización y actualizador. Ese
es el intercambio, y ninguna de las dos skills debe suavizarlo), `frontend-frameworks-standards` y
`frontend-web-platform-standards` (**la UI web que va dentro del webview es suya** —framework, modelo
de render, CSP, presupuesto de bundle, build—; **aquí la ventana, el proceso, el puente al sistema y
lo que se entrega firmado**), `typescript-standards`, `rust-standards`, `dotnet-standards`,
`dart-standards`, `cpp-standards`, `python-standards` (**el lenguaje, su build, su lint y sus tests
son suyos**; aquí la arquitectura de la app de escritorio y su entrega),
`accessibility-standards` (**WCAG y la conformidad son suyas**; aquí las APIs de accesibilidad
nativas —UI Automation, NSAccessibility, AT-SPI— y por qué un webview embebido las cumple de otra
forma), `cryptography-pki-standards` (elección de algoritmos y gestión de PKI; aquí el uso concreto
de la firma de código y de la verificación en el actualizador), `secrets-management-standards`
(**custodia y rotación de la clave privada de firma**; aquí la regla de que vive en HSM/token y de
que la firma ocurre en un paso aislado de CI), `cicd-standards` (la pipeline que construye, firma y
publica), `vulnerability-management-standards` (triaje y SLA de las CVEs que heredas de Chromium o de
Qt), `appsec-standards` (modelado de amenazas general; aquí los *sinks* concretos de un webview
embebido), `macos-fleet-standards` y `endpoint-security-standards` (**el despliegue gestionado en
flota, MDM y el control de aplicaciones son suyos**; aquí producir un artefacto que esos sistemas
puedan aceptar), `i18n-standards` (localización), `webassembly-standards` (Wasm dentro de la app).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

Coste real de cada opción. **No hay opción gratis**: la columna que decide es la última.

| Opción | Licencia (leída en crudo) | Motor de UI | Lo que cuesta de verdad |
|---|---|---|---|
| **Electron** | MIT | Chromium **empaquetado** | Tamaño (~100–200 MB por artefacto) y RAM por proceso; **soporte solo de los 3 majors estables más recientes**, con un major nuevo cada 8 semanas → **obligación permanente de reempaquetar por CVEs de Chromium** |
| **Tauri 2.x** | `Apache-2.0 OR MIT` (`Cargo.toml` del workspace) | **Webview del sistema**: WebView2 (Windows), WKWebView (macOS), **WebKitGTK 4.1** (Linux) | Artefacto pequeño, pero **fragmentación de motor**: tu app se comporta distinto por SO y por distro; WebKitGTK es el eslabón débil. Requiere Rust en el equipo |
| **Qt 6** | **Triple**: comercial, **LGPLv3**, y **GPLv3 para ciertos módulos** | Nativo propio | La licencia (§2.1). Widgets maduros, accesibilidad y rendimiento excelentes; curva y coste de C++ o del *binding* Python |
| **Avalonia** | MIT (`licence.md`) | Render propio (Skia) | .NET en todas partes **incluido Linux**; ecosistema menor que WPF y menos "nativo" visualmente |
| **.NET MAUI** | MIT | Nativo por plataforma | **No soporta Linux**: la doc oficial lista Android, iOS, **Mac Catalyst** y Windows (WinUI 3), más Tizen por Samsung. Si necesitas Linux, MAUI queda descartado de entrada |
| **Flutter desktop** | BSD-3-Clause | Render propio | Windows/macOS/Linux soportados; **la sensación no es nativa** y la integración con el escritorio depende de *plugins* de calidad desigual. Lenguaje: `dart-standards` |
| **wxWidgets** | **wxWindows Library Licence 3.1** (LGPL2+ con excepción de enlace) | Widgets nativos reales | API antigua; la excepción de la licencia permite distribuir binarios bajo tus términos, que es su ventaja frente a Qt |
| **GTK 4** | LGPL-2.1+ | Nativo GNOME | Excelente en Linux, **de segunda en Windows y macOS**. Elegirlo para multiplataforma es casi siempre un error |
| **Nativo por plataforma** | — | WinUI/AppKit/GTK | Tres bases de código. La mejor experiencia y el mayor coste; se justifica en apps de nicho profesional donde la integración lo es todo |

**Criterio de elección honesto, por tipo de aplicación:**

- **App interna de empresa, equipo web, plazo corto** → **Electron**, con el presupuesto de
  actualización aceptado por escrito.
- **Herramienta pequeña, sensible al tamaño o al consumo, equipo con Rust** → **Tauri**, aceptando la
  matriz de pruebas por motor de webview.
- **App de larga vida, con mucha UI, rendimiento, tablas grandes o accesibilidad exigente** →
  **Qt** (o nativo). Es la opción con mejor accesibilidad y peor coste de licencia.
- **Casa .NET que necesita Linux** → **Avalonia**. Casa .NET que no lo necesita → **WPF/WinUI**
  y ya no es multiplataforma.
- **App que ya existe en móvil con Flutter** → **Flutter desktop**, sabiendo que la parte de
  integración con el escritorio la escribirás tú.
- **Utilidad de sistema, herramienta de administración, algo sin apenas UI** → **CLI**. La mitad de
  las apps de escritorio propuestas son una CLI con una ventana encima.

### 2.1 Qt: la licencia es la decisión, no el detalle

Qt se ofrece bajo **licencia comercial**, **LGPLv3** y **GPLv3 según el módulo**. La documentación
oficial lo dice así: la comercial es *"appropriate for development of proprietary/commercial software
where you do not want to share any source code"*, y **hay módulos que "no están disponibles bajo LGPL
v3, sino bajo GPL"** —a ago-2026 la lista incluye Qt Quick 3D, Qt MQTT, Qt Virtual Keyboard y Qt
Wayland Compositor, entre otros (**la lista cambia entre versiones: verifícala, §8**). Usar uno de
esos módulos en un producto cerrado **convierte tu app en GPL o te obliga a comprar licencia**.

La trampa clásica es el **enlace estático**. Bajo LGPL, la FAQ de Qt es explícita: *"Dynamic linking
is usually recommended here"* y *"The user of your application has to be able to re-link your
application against a different or modified version of the Qt library"*; con LGPLv3 se añade que
*"the user needs to be able to run the re-linked binary on its intended target device"*. Traducido a
ingeniería:

- **Enlace dinámico** de Qt y no toques más: es el camino sin sorpresas.
- **Enlace estático bajo LGPL** obliga a entregar los objetos o el material necesario para
  **re-enlazar** tu binario con otra versión de Qt. Es posible, pero es un compromiso de entrega
  permanente, y casi nadie que lo hace lo cumple.
- **LGPLv3 prohíbe la tivoización**: si tu app va en un dispositivo bloqueado que impide sustituir la
  librería, LGPLv3 no te sirve. Ahí solo hay licencia comercial.
- **Prohibido mezclar**: la propia web de Qt dice que *"Combining or mixing the Commercial Qt
  licensing and the Qt Community Edition within the same application or device development project is
  not allowed"*.
- Los *bindings* tienen licencia propia y distinta: **PySide6 es LGPL**, **PyQt es GPL o comercial de
  Riverbank**. Elegir PyQt en un producto cerrado sin comprar licencia es la infracción más repetida
  del ecosistema Python.

### 2.2 Electron: el calendario es el contrato

Electron publica un major cada **8 semanas**, alineado con el ciclo de 4 semanas de Chromium, y
**"the latest three stable major versions are supported by the Electron team"**. A ago-2026 el
calendario oficial daba (verificar §8): **41 → Chromium M146**, **42 → M148**, **43 → M150**, con 44
(M152) previsto para el 25-ago-2026. Consecuencias que van al plan de proyecto, no al backlog:

- **Estás como mucho a ~16 semanas de quedarte sin soporte.** La cadencia de tu app **es** la de
  Electron: presupuesta una release de mantenimiento cada 8 semanas, sin excepción.
- **Sin actualizador automático funcionando no puedes cumplir esto.** El actualizador no es una
  característica: es el mecanismo de parcheo de seguridad de tu producto (§5.3).
- Si el ciclo de 8 semanas no cabe en tu organización (validación, certificación, entorno regulado),
  **Electron es la opción equivocada** y hay que decirlo antes de empezar, no después.

## 3. Estructura y convenciones

### 3.1 Separación de procesos y del puente

En cualquier tecnología de webview, el modelo es el mismo: **proceso privilegiado (main/backend) y
proceso de UI (renderer/webview) que se trata como no confiable**. El puente entre ambos es una **API
explícita y mínima**, nunca acceso genérico.

- Electron: `contextIsolation: true`, `nodeIntegration: false`, `sandbox: true` en todos los
  renderers. El `preload` expone **funciones concretas** por `contextBridge`, jamás `ipcRenderer`
  crudo. La propia documentación de Electron lo dice: *"It is paramount that you do not enable
  Node.js integration in any renderer that loads remote content"* y *"Do not expose Electron APIs to
  untrusted web content"*.
- Tauri: **lista de permisos y capacidades explícita** en la configuración; el comando expuesto valida
  sus argumentos como si viniesen de la red, porque efectivamente pueden.
- Regla común: **el proceso de UI nunca recibe una ruta de fichero arbitraria ni un comando de
  sistema.** El backend decide qué operación existe; la UI solo la invoca.

### 3.2 Integración con el sistema, que es la razón de existir de la app

Cada punto de integración es específico por plataforma y **hay que decidir qué se soporta en cada
una**, no descubrirlo en producción:

- **Notificaciones**: API nativa (Windows Toast con AUMID registrado, `UNUserNotificationCenter` en
  macOS, `org.freedesktop.Notifications` en Linux). En macOS requieren app firmada y permiso del
  usuario; **si no está firmada, no llegan**.
- **Bandeja / área de estado**: en Windows y macOS es estable; **en Linux es un campo de minas**
  (GNOME requiere extensión para `AppIndicator`). Si la app *depende* de la bandeja para funcionar,
  el diseño está mal: la bandeja es un acceso, no el único.
- **Atajos globales**: son un recurso compartido del sistema; **conflicto silencioso** con otras apps
  es lo normal. Configurables siempre, con detección de fallo al registrar. En Wayland, el registro
  global está restringido: se hace por portal, y puede no estar disponible.
- **Arranque al iniciar sesión**: `LaunchAgents`/`SMAppService` en macOS, clave `Run` o Tarea
  Programada en Windows, `.desktop` en `~/.config/autostart` en Linux. **Siempre opcional, siempre
  desactivable desde la propia app**, y desactivado por defecto salvo que el producto sea residente.
- **Asociaciones de fichero y esquemas propios (`miapp://`)**: son **superficie de ataque**. Un
  esquema propio permite que cualquier página web invoque tu app con parámetros; ese *handler* valida
  y rechaza como si fuese un endpoint público. Los ficheros abiertos por asociación se parsean con la
  misma desconfianza.
- **Portapapeles**: leerlo de forma continua es una fuga de datos (gestores de contraseñas). Se lee
  bajo acción explícita del usuario, nunca en un temporizador.
- **El sistema de ficheros del usuario es una responsabilidad, no una comodidad.** Reglas duras:
  escritura **atómica** (fichero temporal en el mismo volumen + `rename`), **nunca** borrar lo que no
  creaste, respetar las rutas del sistema (`%APPDATA%`, `~/Library/Application Support`,
  XDG en Linux) en vez de inventar directorios en `$HOME`, y **desinstalar sin dejar restos** salvo
  los datos del usuario, que se preguntan.

### 3.3 Empaquetado por plataforma

| Plataforma | Formato por defecto | Alternativa | Nota |
|---|---|---|---|
| Windows | **MSI o MSIX** para empresa | NSIS/Squirrel para consumo | Empresa necesita instalación desatendida y por GPO/Intune; un instalador por-usuario sin MSI se lo pone imposible al equipo de puesto |
| macOS | **`.dmg` firmado y notarizado** | `.pkg` si hay que instalar componentes del sistema | Universal binary (arm64 + x86_64) o dos artefactos, decidido explícitamente |
| Linux | **Flatpak** | AppImage para "descargar y ejecutar", `.deb`/`.rpm` para flota gestionada | Snap solo si el objetivo es Ubuntu y aceptas su tienda única |

**Diferencias reales de aislamiento en Linux, que no son cosmética:**

- **Flatpak**: *sandbox* real por defecto. La documentación oficial describe el estado inicial como
  *"no access to any host files except the runtime, the app, `~/.var/app/$FLATPAK_ID` …"*, *"no
  access to the network"*, *"no access to any device nodes"*, *"limited syscalls"*. El acceso se pide
  por **portales** (selector de ficheros, notificaciones), que dan permiso implícito por acción del
  usuario. **`--filesystem=home` anula casi toda la ventaja**: si tu manifiesto lo lleva, el sandbox
  es decorativo. Úsalo como señal de revisión.
- **Snap**: confinamiento **strict** con interfaces declaradas, o **classic**, que **no confina** y
  requiere aprobación manual de la tienda. Si tu snap es *classic*, no vendas aislamiento (verificar
  la redacción actual de la doc, §8).
- **AppImage**: **no hay sandbox, ninguno**. Es un binario portable con sus dependencias. Es cómodo
  para distribuir y **no aporta ninguna garantía de seguridad**; decirlo de otro modo es mentir al
  usuario.

## 4. Calidad y testing

Gates en orden de coste creciente:

1. **Lint y tests del lenguaje** (delegados a la skill del lenguaje) + **auditoría de dependencias**
   en cada build.
2. **Test de la frontera de procesos**: cada comando expuesto por el puente tiene test con entradas
   inválidas y maliciosas (rutas con `..`, rutas absolutas, símbolos de shell, tamaños absurdos).
3. **E2E de la app empaquetada, no del código fuente**: Playwright con el driver de Electron,
   WebdriverIO, o el *runner* nativo de la tecnología. Probar la app sin empaquetar deja fuera
   exactamente los fallos que solo aparecen empaquetados (rutas de recursos, firma, permisos).
4. **Matriz de plataformas real en CI**: Windows, macOS (arm64 **y** x86_64 si publicas ambos) y al
   menos dos entornos Linux distintos. Con Tauri, la matriz incluye **versión de WebKitGTK**, porque
   ahí es donde se rompe.
5. **Prueba de instalación, actualización y desinstalación** como caso de test, incluida la
   **actualización desde la versión N-2**. La migración de datos del usuario entre versiones se
   prueba con datos reales de la versión antigua, no con datos nuevos.
6. **Arranque en frío medido** y tamaño del artefacto **con umbral que rompe el build**. Sin umbral,
   ambos crecen monótonamente.
7. **Accesibilidad**: recorrido completo con teclado y con el lector de pantalla de cada plataforma
   (Narrator/NVDA, VoiceOver, Orca). Es el gate que casi nadie pone y el que más problemas evita.

## 5. Seguridad del stack

### 5.1 El webview embebido

Aplicar la lista oficial de Electron íntegra (equivalente en Tauri): **solo contenido por HTTPS**,
`contextIsolation` activo, `nodeIntegration` desactivado, `sandbox` activo, **CSP definida**,
`webSecurity` **nunca** desactivado, `allowRunningInsecureContent` desactivado, manejador explícito de
peticiones de permiso, y **`shell.openExternal` jamás con contenido no confiable** —la propia doc
avisa de que *"improper use of openExternal can be leveraged to compromise the user's host"*.

**Regla adicional que no aparece en las listas: no cargues una URL remota como UI de la aplicación.**
Si el contenido viene del servidor, cualquier XSS en tu web se convierte en ejecución con los
privilegios de la app de escritorio. La UI se empaqueta; lo remoto va en un `webview` aislado y sin
puente, o en el navegador del usuario.

### 5.2 Firma de código

- **Windows**: firma Authenticode con **sello de tiempo** (sin sello, el binario deja de validar
  cuando caduca el certificado). Desde el **1 de junio de 2023**, los *Baseline Requirements* del
  CA/Browser Forum exigen que la clave privada del suscriptor *"is generated, stored, and used in a
  suitable Hardware Crypto Module"* — es decir, **token/HSM obligatorio**, lo que hace imposible
  meter el `.pfx` en un secreto de CI y obliga a firmar con un servicio de firma en la nube o un
  *runner* con acceso al HSM. (Versión vigente de los BR a ago-2026: **3.11.0**, verificar §8.)
  **SmartScreen** es reputación, no firma: un certificado OV nuevo arrastra avisos hasta acumular
  descargas; EV los evita antes. Presupuéstalo.
- **Windows, kernel**: si el producto incluye un **driver en modo kernel**, el mundo es otro. Desde
  **Windows 10 versión 1607**, *"Windows will not load any new kernel-mode drivers which are not
  signed by the Dev Portal"*, con excepciones tasadas (equipo actualizado desde una versión anterior,
  **Secure Boot desactivado**, o certificado de entidad final emitido **antes del 29 de julio de
  2015** encadenado a una CA cross-signed soportada). Traducción: **el cross-signing ya no es una
  vía**; hay que registrarse en el Hardware Dev Center —lo que **exige un certificado EV**— y firmar
  por el portal (atestación o HLK).
- **macOS**: firma con **hardened runtime** y *entitlements* mínimos, **notarización obligatoria** y
  **`stapler`** para que funcione sin conexión. Gatekeeper, según Apple, *"verifies that the software
  is from an identified developer, is notarized by Apple to be free of known malicious content, and
  hasn't been altered"*. Sin notarizar, la app **no se abre** por la vía normal. Cada *entitlement*
  que pidas (`com.apple.security.cs.allow-unsigned-executable-memory`,
  `disable-library-validation`) desactiva una protección: se justifica uno a uno o no va.
- **Linux**: firma del repositorio (`.deb`/`.rpm`), firma del *bundle* Flatpak, y en AppImage
  **firma detached publicada junto al artefacto** — que casi nadie verifica, así que la verificación
  la tiene que hacer tu propio actualizador.
- **La clave privada nunca está en el repositorio ni en una variable de entorno de CI.** Token/HSM o
  servicio de firma; el paso de firma es un *job* aislado, con la mínima superficie posible, y
  auditado. Ver `secrets-management-standards`.

### 5.3 Actualización automática

**Un actualizador sin verificación de firma es una puerta trasera con nombre de característica.** Es
literalmente un mecanismo que descarga un binario y lo ejecuta con los privilegios del usuario.
Requisitos no negociables:

- **HTTPS con validación de certificado**, y **firma del artefacto y del manifiesto verificada por el
  cliente contra una clave embebida en la app**. Tauri lo impone por diseño: *"Tauri's updater needs a
  signature to verify that the update is from a trusted source. This cannot be disabled."* Ese es el
  listón para cualquier otra tecnología.
- **La clave de firma del actualizador es distinta de la de firma de código** y su pérdida es
  terminal: la propia doc de Tauri lo dice —*"if you lose this key you will NOT be able to publish new
  updates to the users that have the app already installed"*—. Custodia y copia con el mismo rigor que
  una CA raíz.
- **Protección contra *downgrade***: el cliente rechaza versiones inferiores a la instalada.
- **Despliegue por fases con interruptor de parada**, porque una actualización mala se distribuye a
  toda la base instalada en horas y **no se puede revertir desde el servidor**.
- **Sin telemetría obligatoria para actualizar**: el canal de actualización no es un canal de
  analítica. Ver `privacy-engineering-standards`.

### 5.4 Datos locales

Credenciales y tokens van al almacén del sistema (**DPAPI/Credential Manager**, **Keychain**,
**Secret Service/`libsecret`**), nunca en un JSON en `%APPDATA%`. Y la advertencia honesta: **el
almacén del sistema protege frente a otro usuario del equipo, no frente a malware ejecutándose como
el propio usuario.** Prometer más que eso es falso.

## 6. Rendimiento y operabilidad

- **Presupuesto explícito y medido en CI**: tamaño del instalador, tamaño instalado, RAM en reposo
  tras 30 min con la app abierta, y **tiempo hasta ventana interactiva en arranque en frío** con
  disco frío. *Cualquier* cifra de consumo de Electron citada sin decir versión, número de renderers
  y metodología es folclore: **mide la tuya y ponla como umbral**, no cites la de un blog.
- **El coste real de un webview no es el binario, es el proceso por ventana.** Reducir ventanas y
  renderers vale más que optimizar el bundle.
- **Arranque**: ventana visible primero, contenido después; carga perezosa de todo lo no crítico.
- **Telemetría de escritorio, si existe**: **consentimiento explícito y desactivable**, sin
  identificadores persistentes salvo necesidad demostrada, y con lo que se envía documentado. Lo
  mínimo útil: versión, plataforma, y **fracción de la base instalada por versión** — sin ese dato no
  sabes cuánta gente sigue con una versión vulnerable, que es la métrica operativa clave.
- **Errores y *crash reports***: simbolizados, sin PII, con retención acotada, y **con un modo de
  desactivarlos** en despliegues gestionados.
- **Registro local rotado y acotado** en la ruta estándar de la plataforma, y accesible desde la
  propia app ("abrir carpeta de registros"): es la diferencia entre un ticket de soporte resoluble y
  uno eterno.

## 7. Sostenibilidad a largo plazo

### 7.1 El compromiso recurrente

Antes de escribir una línea, alguien firma esto: **cadencia de actualización del motor** (8 semanas
con Electron; con Tauri, lo que actualicen los sistemas de tus usuarios, que **no controlas**),
**renovación del certificado de firma** con su recordatorio a 90 días, **cuota anual del Apple
Developer Program** sin la cual dejas de poder notarizar —y por tanto de publicar—, y **matriz de
sistemas operativos soportados con fecha de retirada**. Una app de escritorio sin dueño de estas
cuatro cosas se queda sin poder publicar el día que caduca algo, normalmente en medio de un incidente.

### 7.2 Prohibiciones

- ❌ **PROHIBIDO** desactivar `contextIsolation` o activar `nodeIntegration` en un renderer que cargue
  contenido remoto.
- ❌ **PROHIBIDO** desactivar `webSecurity`, `sandbox` o la validación de certificados TLS "para
  desarrollo" en una rama que pueda llegar a *release*.
- ❌ **PROHIBIDO** exponer `ipcRenderer` o una API genérica de ejecución al webview: la superficie es
  una lista de comandos concretos y validados.
- ❌ **PROHIBIDO** cargar la UI principal desde una URL remota.
- ❌ **PROHIBIDO** distribuir sin firmar en Windows y macOS, y **prohibido publicar en macOS sin
  notarizar y sin `stapler`**.
- ❌ **PROHIBIDO** guardar el certificado de firma o su contraseña en el repositorio, en la imagen de
  CI o en una variable de entorno; y prohibido firmar sin sello de tiempo.
- ❌ **PROHIBIDO** un actualizador que no verifique firma del artefacto, o que acepte versiones
  inferiores a la instalada.
- ❌ **PROHIBIDO** quedarse en una versión de Electron sin soporte (fuera de los tres majors
  vigentes) en producto distribuido.
- ❌ **PROHIBIDO** enlazar Qt estáticamente bajo LGPL sin cumplir —y documentar— la obligación de
  re-enlace; y prohibido usar un módulo GPL-only de Qt en un producto cerrado sin licencia comercial.
- ❌ **PROHIBIDO** usar PyQt en producto cerrado sin licencia de Riverbank (PySide6 es la vía LGPL).
- ❌ **PROHIBIDO** `--filesystem=home` en un manifiesto Flatpak sin justificación revisada, y
  prohibido vender un AppImage o un snap *classic* como "aislado".
- ❌ **PROHIBIDO** guardar credenciales fuera del almacén del sistema.
- ❌ **PROHIBIDO** escribir en el sistema de ficheros del usuario de forma no atómica, fuera de las
  rutas estándar de la plataforma, o borrar ficheros que la app no creó.
- ❌ **PROHIBIDO** leer el portapapeles de forma continua o en segundo plano.
- ❌ **PROHIBIDO** registrar un esquema `miapp://` sin tratar sus parámetros como entrada hostil.
- ❌ **PROHIBIDO** telemetría activada por defecto sin consentimiento, o actualización condicionada a
  aceptarla.
- ❌ **PROHIBIDO** entregar sin recorrido de teclado completo ni prueba con lector de pantalla.
- ❌ **PROHIBIDO** citar consumos de RAM o tamaños "típicos" de Electron sin medición propia (§6).

## 8. Verificación web obligatoria

- **Electron**: `releases.electronjs.org/schedule` — qué majors están dentro de los tres soportados
  **hoy**, sus fechas de EOL y la versión de Chromium asociada. A ago-2026: 41/42/43 (M146/M148/M150),
  con 44 (M152) previsto para el 25-ago-2026.
- **Tauri**: versión actual (2.11.5 a ago-2026), `rust-version` mínima del workspace, motores de
  webview y versiones mínimas por plataforma, y estado de WebKitGTK en las distros objetivo.
- **Qt**: **lista actual de módulos GPL-only** en `doc.qt.io/qt-6/licensing.html` —cambia entre
  versiones— y condiciones de la licencia comercial vigente. **Leer la licencia del *binding*
  concreto** (PySide6 vs. PyQt) antes de elegirlo.
- **Licencias en crudo** (`LICENSE`, `LICENCE`, `licence.md`, `COPYING`, ojo con `master` vs. `main`)
  de cualquier framework de UI que enlaces. Verificadas para este documento: Tauri
  `Apache-2.0 OR MIT`, Avalonia MIT, wxWidgets **wxWindows Library Licence 3.1**.
- **Firma de código Windows**: versión vigente de los *Baseline Requirements* del CA/Browser Forum
  (3.11.0, efectiva 16-jun-2026, a ago-2026) y los requisitos de módulo hardware; oferta actual de
  servicios de firma en la nube compatibles con CI.
- **macOS**: requisitos vigentes de notarización, herramienta actual (`notarytool`; `altool` está
  retirado) y cambios de Gatekeeper o de *entitlements* en la última versión de macOS.
- **Linux**: redacción actual de los modos de confinamiento de Snap (*strict*/*classic*/*devmode*) y
  del proceso de aprobación de *classic* — **este documento no pudo verificarlo en la fuente
  oficial** (la doc de Snapcraft no respondió); trátalo como pendiente. Estado de los portales de
  Flatpak para atajos globales y autoarranque bajo Wayland.
- **.NET MAUI / Avalonia / Flutter**: plataformas soportadas y versiones mínimas en la doc oficial —
  a ago-2026 **MAUI no lista Linux**.
- **CVEs**: de Chromium (si Electron), de WebKitGTK y WebView2 (si Tauri), de Qt (si Qt). Es un flujo
  continuo, no una comprobación puntual → `vulnerability-management-standards`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
