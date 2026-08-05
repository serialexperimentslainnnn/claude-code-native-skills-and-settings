---
name: pwa-standards
description: Use when a web app installs, caches or works offline - sw.js and service-worker.js, ServiceWorkerRegistration and navigator.serviceWorker.register with scope, Service-Worker-Allowed header, install/activate/waiting lifecycle, skipWaiting and clients.claim, updatefound and registration.update(), manifest.webmanifest and manifest.json with start_url/scope/display/icons 192-512, beforeinstallprompt and appinstalled, apple-mobile-web-app-capable and apple-touch-icon, Workbox and workbox-config.js, Serwist and @serwist/next, vite-plugin-pwa, ngsw-config.json and @angular/service-worker, Cache API and caches.open, cache-first vs network-first vs stale-while-revalidate, navigation preload, precache manifest and revisioned assets, IndexedDB with idb or Dexie for offline data, navigator.storage.estimate() and persist(), quota eviction, Web Push with VAPID and applicationServerKey, PushSubscription and pushsubscriptionchange, Notification permission prompts, Background Sync and Periodic Background Sync, Badging, Web Share Target, an unregistering kill-switch service worker, or a stale service worker serving an old build.
---

# Estándares de PWA (aplicación web instalable)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio sobre **la web que se instala, cachea y funciona sin red**: cuándo compensa hacer una
PWA, qué hace el service worker y cómo se actualiza, qué se cachea y con qué estrategia, dónde viven los
datos offline, cómo se instala y cómo se notifica.

**Eje**: una PWA **no es "una app pero en web"**. Es una web con capacidades adicionales y, sobre todo,
**con un modelo de actualización propio** — y ahí es donde se equivoca casi todo el mundo. Una web
normal se actualiza al recargar; una PWA puede dejar a un usuario clavado en la versión de hace seis
meses, sirviendo HTML viejo contra una API nueva, sin que ninguna métrica de despliegue lo delate.
El service worker es la pieza que da las capacidades **y** la que crea el problema.

Segunda regla de encuadre: **el service worker es código con persistencia dentro de tu origen**. Se
instala una vez y sobrevive al cierre de la pestaña, al despliegue y a tu intento de arreglarlo. Se
trata como infraestructura desplegada, no como un fichero más del bundle.

Triggers: `sw.js`, `service-worker.js`, `navigator.serviceWorker.register`, `manifest.webmanifest`,
`workbox-config.js`, `vite-plugin-pwa`, `@serwist/next`, `ngsw-config.json`, `caches.open`,
`skipWaiting`, `clients.claim`, `beforeinstallprompt`, `navigator.storage.persist()`, VAPID,
`PushSubscription`, `apple-mobile-web-app-capable`, y el síntoma clásico: "a algunos usuarios les sigue
saliendo la versión antigua".

**No aplica**:
- `frontend-web-platform-standards` (**ya escrita**) — **HTML, CSS, las APIs generales del navegador, el
  modelo de carga, la CSP y la herramienta de build son suyos**. Aquí solo el service worker, el
  manifiesto y el ciclo de vida de la instalación. Si la respuesta sigue siendo cierta sin service
  worker, es de allí.
- `frontend-frameworks-standards` (**ya escrita**) — **el framework y su modelo de renderizado**
  (CSR/SSR/SSG/islas/RSC) son suyos; aquí solo qué exige la PWA del artefacto que ese framework produce
  (assets con hash, HTML no precacheado a ciegas, ruta de fallback offline).
- `mobile-standards` — **la app nativa, su publicación en App Store / Google Play, las firmas, el
  ciclo de release y las APIs de plataforma son suyos**. **Aquí la web instalable.** La comparación
  PWA vs. nativa se escribe **desde aquí** (§2), con honestidad sobre iOS: si la decisión termina en
  "hace falta nativa", el resto es suyo.
- `caching-cdn-standards` — **la caché HTTP, el CDN, `Cache-Control`, `Vary` y la purga son suyos**.
  **Aquí la caché del service worker, que es otra capa y puede contradecir a la anterior**: un service
  worker que responde desde `caches` **no consulta al CDN ni honra sus cabeceras** — una purga de CDN
  perfecta no llega al usuario. Cuando ambas políticas discrepan, **manda la del service worker**, y
  por eso tiene que escribirse junto a la otra, no aparte.
- `web-performance-standards` (**ya escrita**) — **Core Web Vitals, presupuestos de rendimiento y su
  medición son suyos**. Aquí solo el efecto de la caché del service worker sobre la primera visita
  (ninguno) y sobre las siguientes.
- `accessibility-standards` (**ya escrita**) — **el criterio de conformidad WCAG es suyo**. Aquí su
  consecuencia técnica: un aviso de "nueva versión disponible" o de "sin conexión" es contenido
  dinámico y necesita anuncio accesible y foco correcto.
- Datos y sincronización: `data-platform-standards` / `nosql-standards` (modelo de datos, conflictos,
  CRDT y el motor de sincronización), `api-design-standards` (el contrato, la idempotencia y los
  ETags que hacen posible reintentar), `streaming-cdc-standards` (propagación de cambios).
  **Offline-first es un modelo de datos, no una caché** (§3): la caché es de aquí, el modelo es de allí.
- `webgl-webgpu-standards` — canvas, GPU y presupuesto de fotograma. Una PWA puede contener un canvas
  WebGPU: son capas distintas y no se solapan.
- `appsec-standards` (metodología y triaje; aquí los controles concretos del service worker),
  `privacy-engineering-standards` (**datos personales cacheados en el dispositivo**: base legal,
  minimización, retención y borrado son suyos), `secrets-management-standards` (**un secreto no vive en
  el cliente, y menos en una caché persistente**), `observability-standards` (plataforma de telemetría;
  aquí qué instrumentar del ciclo de vida del SW), `cicd-standards` (la pipeline que publica el SW),
  `i18n-standards`, `webassembly-standards`.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### La decisión previa: ¿PWA, web normal o app nativa?

**Por defecto no se hace una PWA.** Un service worker es infraestructura con estado en el dispositivo
del usuario; se añade cuando hay una razón, no como casilla de "app moderna".

| Señal | Decisión |
|---|---|
| Contenido que se consume online, sesiones cortas, sin uso sin red | **Web normal.** Sin service worker. La caché HTTP y el CDN ya hacen el trabajo (→ `caching-cdn-standards`) |
| Uso repetido por los mismos usuarios, arranque desde el escritorio/pantalla de inicio, tolerancia a red mala o intermitente (campo, almacén, transporte, taller) | **PWA.** Es el caso canónico y el que más rinde |
| Se necesita hardware o integración de sistema que la web no da: Bluetooth/USB/NFC en iOS, sensores de fondo, geolocalización continua en segundo plano, widgets, integración con contactos/llamadas, ejecución en segundo plano fiable | **Nativa** (→ `mobile-standards`). No hay atajo |
| La distribución en la tienda es un requisito de negocio (visibilidad, compras integradas, exigencia del cliente o del sector) | **Nativa** o envoltorio; una PWA no aparece en la App Store |
| Un solo equipo, presupuesto de un producto, iteración rápida, sin revisión de tienda en el camino | **PWA**: un despliegue, un código, sin gatekeeper |
| Retención medida como criterio | **Depende, y se mide**: la instalación web tiene menos fricción pero también menos permanencia. No se decide con benchmarks ajenos |

El coste real de "nativa" no es escribir la app: es **mantener dos o tres bases de código, dos ciclos de
release y dos superficies de bug**, para siempre. El coste real de "PWA" es **iOS**.

### La restricción que decide en la práctica: iOS

Verificado a ago-2026. **Cítalo así, no lo suavices:**

- **Instalación**: solo manual, con *Compartir → Añadir a pantalla de inicio*. **No existe
  `beforeinstallprompt`** en Safari (webstatus.dev: `beforeinstallprompt` → **Baseline limited**,
  solo Chrome/Edge 76+/79+) — no puedes ofrecer un botón "Instalar" que instale. Desde **iOS 16.4** se
  puede instalar desde el menú Compartir de Safari, Chrome, Edge, Firefox y Orion (MDN), pero todos
  usan WebKit: las capacidades son las de Apple.
- **Desde iOS 26 / iPadOS 26**, *cualquier* sitio añadido a la pantalla de inicio se abre **como web app
  por defecto** (antes había que configurarlo); el usuario puede desactivar "Open as Web App". El
  manifiesto sigue importando (iconos, `start_url`, `display`, offline con service worker).
- **Push**: la Push API en iOS **solo funciona en web apps añadidas a la pantalla de inicio**, no en una
  pestaña de Safari, y el permiso debe pedirse tras interacción del usuario. Web Push llegó en iOS 16.4.
  webstatus.dev clasifica `notifications-apps` ("Notifications from service workers and installed apps")
  como **Baseline widely available (widely desde 2025-09-27)** y `push` ("Push messages") también
  **widely desde 2025-09-27** — pero **ese "widely" no significa "igual en todas partes"**: el requisito
  de instalación previa en iOS no aparece en el estado Baseline. Es la trampa clásica de este dominio.
- **Almacenamiento y su caducidad**: WebKit, *Tracking Prevention*, verbatim:
  > "ITP deletes all cookies created in JavaScript and all other script-writeable storage after 7 days
  > of no user interaction with the website."

  y, también verbatim:
  > "The first-party domain of home screen web applications is exempt from ITP's 7-day cap on all
  > script-writeable storage, i.e. ITP always skips that domain in its website data removal algorithm."

  **Consecuencia operativa, que es lo único que importa**: en Safari **sin instalar**, IndexedDB,
  localStorage, Cache API y **el propio registro del service worker** se borran a los 7 días sin
  interacción. Una PWA no instalada en iOS **no tiene almacenamiento duradero**. Si el caso de uso
  depende de datos locales, o el usuario la instala o el diseño está mal.
- **Cuotas**: desde Safari 17 / iOS 17, hasta ~**80%** del disco total para el navegador y ~**20%** para
  otras apps que embeben contenido web; una web app instalada tiene la misma cuota de origen que en el
  navegador. **Verificar antes de dimensionar nada** (§8) y **no diseñar contra la cuota**: se mide con
  `navigator.storage.estimate()` y se degrada.
- **No hay** Background Sync ni Periodic Background Sync (webstatus.dev: ambas **Baseline limited**, solo
  Chromium), ni Background Fetch, ni Web Share Target, ni File System Access. Lo que no llega, no llega:
  no se planifica una funcionalidad sobre una API que iOS no implementa.

### La DMA y las PWA en la UE: qué pasó de verdad

Hubo un intento de eliminarlas y **hubo marcha atrás**. Apple, en su página de soporte de la DMA
(verbatim):

> "UPDATE: Previously, Apple announced plans to remove the Home Screen web apps capability in the EU as
> part of our efforts to comply with the DMA. […] We have received requests to continue to offer support
> for Home Screen web apps in iOS and iPadOS, therefore we will continue to offer the existing Home
> Screen web apps capability in the EU. This support means Home Screen web apps continue to be built
> directly on WebKit and its security architecture, and align with the security and privacy model for
> native apps on iOS and iPadOS."

> "Developers and users who may have been impacted by the removal of Home Screen web apps in the beta
> release of iOS and iPadOS in the EU can expect the return of the existing functionality for Home
> Screen web apps with the availability of iOS 17.4 and and iPadOS 17.4 in early March." *(el "and and"
> está en el original)*

**Estado resultante: las PWA funcionan en la UE igual que en el resto del mundo, sobre WebKit.** Sigue
circulando documentación —y respuestas de modelos— que afirma lo contrario, que en la UE las PWA se
abren como pestaña de Safari: **es falso desde marzo de 2024**. Si alguien lo cita, la fuente es la
página de Apple, no un artículo de febrero de 2024.

### Toolchain

| Pieza | Elección | Estado a ago-2026 | Por qué |
|---|---|---|---|
| Service worker a mano | Solo si el caso es trivial (un `fetch` handler y una ruta offline) | — | Escribir precaching, versionado y limpieza de cachés a mano es reinventar bugs conocidos |
| Librería de service worker | **Workbox** | `workbox-build`/`workbox-window` **7.4.1** (2026-05-04), **MIT** (leído del `LICENSE`) | Sigue siendo el default histórico y **sigue publicando**; el backlog de issues es notable pero el proyecto no está deprecado |
| Alternativa mantenida | **Serwist** (fork de Workbox) | **9.5.12** (2026-07-22), **MIT** | Nació porque el desarrollo de Workbox se estancó; hoy conviven. Elección razonable si necesitas cadencia o soporte de App Router |
| Integración con Vite | **`vite-plugin-pwa`** | **1.3.0** (2026-05-05), MIT | Genera manifiesto, precache manifest y el flujo de actualización. `injectManifest` cuando necesitas lógica propia; `generateSW` para lo estándar |
| Integración con Next.js | **`@serwist/next`** | **9.5.12**, MIT | `next-pwa` original está sin mantenimiento; verificar antes de adoptarlo (§8) |
| Integración con Angular | **`@angular/service-worker`** + `ngsw-config.json` | **22.1.0** (2026-07-29), MIT | Viene con el framework; su modelo de versiones es propio y **no se mezcla con Workbox** |
| Datos offline | **IndexedDB** con un envoltorio (`idb`) o una base local con sincronización propia | — | `localStorage` es síncrono, pequeño y bloquea el hilo: **no es almacenamiento de aplicación** |
| Push | **Web Push + VAPID** con un servicio propio o gestionado | Push: Baseline widely (2025-09-27) | Estándar; sin acuerdo por navegador ni SDK propietario |

**Regla de tooling**: se usa **una** solución de service worker por proyecto. Dos capas que generan
service workers (p. ej. el del framework y otro añadido) es un ladrillo garantizado.

## 3. Estructura y convenciones

### Ciclo de vida: lo que hay que tener interiorizado

`register` → **`install`** (se precachean recursos; si algo falla, la instalación falla entera) →
**`waiting`** (hay un SW nuevo instalado pero el viejo sigue controlando las páginas abiertas) →
**`activate`** (limpieza de cachés viejas) → `controlling`.

- Un service worker nuevo **no toma el control** mientras quede una pestaña controlada por el anterior.
  "Recargar" no basta: la navegación normal mantiene el control. Hace falta cerrar todas las pestañas
  del origen, o `skipWaiting`, o `Clients.claim()`, o un `navigate` forzado.
- El navegador comprueba actualizaciones del script del SW en la navegación y, en general, cuando el
  script tiene más de 24 h en caché. **El script del service worker se sirve con `Cache-Control:
  max-age=0` (o `no-cache`)**. Un SW cacheado un año es un SW inmortal.
- `registration.update()` explícito en momentos de baja actividad (foco de ventana, cambio de ruta,
  temporizador de horas) para no depender del azar.

### La actualización es el problema central

El fallo del dominio no es "no funciona offline": es **el usuario atrapado en una versión vieja**,
combinando HTML de hace meses con una API que ya cambió el contrato. Se diseña explícitamente:

- **`skipWaiting` por defecto está PROHIBIDO.** Activar el SW nuevo mientras la página abierta ejecuta
  el bundle antiguo produce lo peor: chunks que ya no existen (los precacheó otra versión), respuestas
  de un esquema distinto y estado incoherente a mitad de un formulario. `skipWaiting` es aceptable
  **solo** en una app sin lazy-loading de chunks versionados o cuando lo dispara **el usuario**.
- **Patrón por defecto**: SW nuevo → queda en `waiting` → la app detecta `updatefound` /
  `registration.waiting` → **avisa al usuario** ("hay una versión nueva, recargar") → el usuario acepta
  → `postMessage({type:'SKIP_WAITING'})` → el SW hace `skipWaiting()` → en `controllerchange` la página
  hace `location.reload()` **una sola vez** (guarda un flag: el bucle de recarga infinita es el bug
  clásico de este patrón).
- **Recarga forzada sin preguntar** solo si hay un cambio incompatible (contrato de API roto). Entonces
  se avisa igual y se guarda el trabajo en curso antes de recargar. Perder un formulario a medias por
  un despliegue es un incidente, no un detalle.
- **Ventana de compatibilidad**: los assets de la versión anterior **se siguen sirviendo** durante el
  despliegue (mínimo el tiempo que un usuario puede tener la pestaña abierta: días). Borrarlos al
  desplegar convierte cada release en errores de carga de chunk.
- **Versión visible**: la versión del build está expuesta en el cliente (variable inyectada en el build)
  y **se envía en la telemetría**. Sin eso no puedes saber cuánta gente está atrapada; con eso, es una
  métrica: *distribución de versiones activas*, y una alerta si la cola vieja no baja tras un release.
- El SW se registra con la **versión del build en la query o en el nombre** solo si tu tooling no
  revisiona el script; la regla real es que **el contenido del script cambie en cada release**, porque
  el navegador compara byte a byte.

### Plan de desactivación de emergencia (el service worker convertido en ladrillo)

Nadie lo prepara y todo el mundo lo necesita una vez. **Se escribe antes de la primera release**, se
prueba en preproducción y se guarda como runbook:

1. **SW de desactivación** ("kill switch"): desplegar en la misma URL del service worker un script que
   **no cachea nada** y que en `install` hace `self.skipWaiting()`, en `activate` borra **todas** las
   cachés (`caches.keys()` → `caches.delete`), llama a `self.registration.unregister()` y recarga los
   clientes (`clients.matchAll()` → `client.navigate(client.url)`).
2. Requisito previo — **y esta es la parte que se pierde**: el navegador debe poder **descargar el
   script nuevo**. Por eso el script del SW **nunca** se sirve con caché larga y **nunca** se precachea a
   sí mismo. Si el SW roto cachea su propio script con caché larga, no hay kill switch: hay que esperar
   a la expiración o a que el usuario borre datos del sitio a mano.
3. `Clear-Site-Data: "storage"` (o `"*"`) en la respuesta como refuerzo — verificar soporte antes de
   depender de ella (webstatus.dev: `clear-site-data` **Baseline limited**, sin Chromium en la lista).
   Es refuerzo, **no** el plan.
4. La retirada definitiva de una PWA (se deja de ofrecer) **exige** el paso 1: si simplemente borras el
   fichero, el 404 deja al SW anterior vivo e indefinidamente al mando del origen.
5. Métrica de salida: la telemetría debe mostrar el descenso de clientes controlados por la versión
   afectada. Si no baja, el kill switch no está llegando.

### Estrategias de caché por tipo de recurso

| Recurso | Estrategia | Motivo |
|---|---|---|
| Assets con hash en el nombre (JS, CSS, fuentes, imágenes versionadas) | **Cache-first**, precacheados, inmutables | El nombre cambia con el contenido: no hay nada que revalidar |
| **HTML / documentos de navegación** | **Network-first** con timeout corto y **fallback a la copia cacheada** | Ver abajo |
| Datos de API que toleran estar un poco viejos | **Stale-while-revalidate** con expiración explícita | Respuesta instantánea, actualización en segundo plano |
| Datos que deben ser correctos (saldo, disponibilidad, permisos) | **Network-only** (o network-first con aviso visible de dato cacheado) | Un dato viejo que parece actual es peor que no tener dato |
| POST/PUT/DELETE y cualquier cosa con efecto | **Nunca se cachean**. Se encolan (§ offline) | |
| Recursos de terceros (analítica, mapas, anuncios) | No se precachean; opcionalmente stale-while-revalidate con límite de entradas | Precachear un tercero es adoptar su peso y su ciclo de vida |

**Cachear el HTML mal es lo que rompe los despliegues.** Un `index.html` precacheado con cache-first
sirve para siempre referencias a chunks que ya no existen: la app arranca y muere. Reglas duras:
- El documento de navegación **nunca** es cache-first sin revalidación.
- En una SPA con `app shell`, el shell **se revisiona en cada build** y forma parte del precache
  manifest generado por el tooling; jamás se precachea "index.html" como entrada fija sin revisión.
- **Activar Navigation Preload** cuando se use network-first en navegaciones: sin ella, el arranque del
  SW se suma a la latencia de la petición.
- Cada caché tiene **nombre versionado** y `activate` **borra las que no son de esta versión**. Una caché
  sin política de expiración ni límite de entradas crece hasta que el navegador expulsa todo el origen.
- **Rango de respuestas cacheables**: no cachees respuestas con `status` distinto de 200 ni opacas
  (`type: 'opaque'`) sin saber lo que haces — ocupan cuota (padding) y no puedes inspeccionar su estado.

### Almacenamiento

- **Cache API** para respuestas HTTP. **IndexedDB** para datos de aplicación. `localStorage`
  **PROHIBIDO** para datos de aplicación (síncrono, ~5 MB, bloquea el hilo principal) y para tokens.
- Cuota: `navigator.storage.estimate()` (webstatus.dev: `storage-manager` **Baseline widely** desde
  2023-09-18, widely 2026-03-18) **antes** de descargar un paquete grande de datos offline, y
  degradación explícita si no cabe. Un `QuotaExceededError` sin manejar corrompe el estado a medias.
- **Expulsión**: bajo presión de disco el navegador **borra todo el origen**, no una parte. El diseño
  asume que la caché **puede desaparecer entera en cualquier momento** y que la app debe reconstruirse
  desde la red. Datos que solo existen en el cliente = datos perdidos.
- **Almacenamiento persistente**: `navigator.storage.persist()` para pedir modo persistente. Se solicita
  **tras una señal real de compromiso** (instalación, login, primer trabajo guardado), no en la primera
  carga; se comprueba con `persisted()`; **no se asume concedido** — los criterios varían por navegador y
  cambian. En WebKit, la exención real de las PWA no viene de esta API sino de estar instalada (ver §2).
- Datos personales cacheados: hay **retención y borrado**. Al cerrar sesión se **borran cachés y bases
  locales del usuario**, no solo el token. El criterio legal es de `privacy-engineering-standards`.

### Offline de verdad: es un modelo de datos, no una caché

Una caché de lecturas te da "la app abre sin red". Eso **no** es offline-first. Offline-first significa
que **se puede escribir sin red** y que hay una respuesta escrita a qué pasa cuando dos dispositivos
escriben lo mismo.

- **Cola de mutaciones duradera** en IndexedDB (no en memoria), con reintentos con backoff, **claves de
  idempotencia** por operación (→ `api-design-standards`) y estado visible por elemento
  ("pendiente de sincronizar"). Sin idempotencia, un reintento duplica pedidos.
- **Resolución de conflictos decidida y escrita** antes de implementar: última escritura gana (con reloj
  del servidor, nunca del cliente), fusión por campo, CRDT, o intervención del usuario. "No pasará"
  no es una estrategia. El modelo lo fija la skill de datos correspondiente.
- **El reloj del cliente no es de fiar**: nunca se ordena por `Date.now()` del dispositivo.
- **Background Sync** solo como *optimización* en Chromium (webstatus.dev: **Baseline limited**). La
  sincronización debe funcionar igual **sin** ella, al recuperar foco o conectividad (`online`,
  `visibilitychange`). Lo mismo con Periodic Background Sync y Background Fetch.
- La UI **dice la verdad**: qué está sincronizado, qué está pendiente, qué falló y desde cuándo. Un
  indicador de "offline" y una fecha de "datos actualizados a las HH:MM" valen más que cualquier truco.

### Manifiesto e instalabilidad

Requisitos de instalación en navegadores Chromium, según MDN (verbatim):
> `name` or `short_name`; `icons` — must contain a 192px and a 512px icon; `start_url`; `display` and/or
> `display_override`; `prefer_related_applications` — must be `false` or not present

y: *"PWAs must be served using HTTPS, or from a local development environment using `localhost` or
`127.0.0.1`"*; sobre el service worker: *"While **not a requirement** for installability, many PWAs use
service workers to provide an offline experience."*

Estado por navegador a ago-2026 (MDN): **Chromium** instala en todos los escritorios soportados;
**Safari** ofrece *Add to Dock* en macOS (Safari 17+) con o sin manifiesto; **Firefox de escritorio
no instala PWAs con manifiesto**; en **Android** instalan Firefox, Chrome, Edge, Opera y Samsung
Internet; en **iOS 16.4+**, desde el menú Compartir de Safari, Chrome, Edge, Firefox y Orion.

- `beforeinstallprompt` es **Chromium-only** (Baseline limited). Un botón "Instalar" propio existe
  **solo** ahí: se guarda el evento, se ofrece el botón en un momento con sentido y se cae con
  elegancia (instrucciones manuales) en el resto. **Nunca** un botón que no hace nada en Safari.
- `scope` y `start_url` coherentes con el despliegue; `id` explícito en el manifiesto para que la
  identidad de la app no dependa de la URL.
- Iconos maskable además de los normales; `theme_color`, `background_color`, `display: standalone`
  (o `minimal-ui` si quieres barra de navegación). Las capacidades avanzadas del manifiesto
  (`shortcuts`, `share_target`, `file_handlers`, `protocol_handlers`, `launch_handler`) son
  **Baseline limited, casi todas Chromium-only**: mejora progresiva, jamás requisito funcional.
- La instalación **no se ruega**. Un modal de "instala nuestra app" en la primera visita es el mismo
  antipatrón que el pop-up de notificaciones.

### Notificaciones push

- **Regla de producto, sin excepciones: pedir permiso al entrar es el antipatrón.** El permiso se pide
  **tras una acción del usuario que lo justifique** ("avísame cuando llegue el pedido"), explicando qué
  se va a enviar y con qué frecuencia, y con una alternativa si dice que no. Un `Notification.requestPermission()`
  en el `load` quema el permiso **para siempre** en ese navegador: el "denegado" es permanente y no se
  puede volver a pedir. Los navegadores además penalizan el patrón.
- Infraestructura: **Web Push con VAPID**. Claves VAPID: la **pública** va en el cliente
  (`applicationServerKey`), la **privada vive en el servidor** y en un gestor de secretos, nunca en el
  repo ni en el bundle (→ `secrets-management-standards`).
- El payload se cifra extremo a extremo hacia el navegador; aun así **no se envían datos personales ni
  sensibles en la notificación**: aparece en la pantalla de bloqueo de un dispositivo que puede ser
  compartido.
- Suscripciones: manejar `pushsubscriptionchange` y **purgar** las suscripciones que el servicio push
  rechaza (404/410). Una tabla de suscripciones que solo crece es un coste y un riesgo.
- Frecuencia y utilidad: cada notificación tiene un motivo y un enlace que lleva al sitio correcto.
  Un navegador puede revocar el permiso si el sitio abusa; el usuario, antes.
- En iOS, recordar: **solo si está instalada**, y el prompt requiere gesto del usuario.

### Capacidades del dispositivo

Cámara, micrófono, geolocalización, sensores, Bluetooth, USB, portapapeles, wake lock: **detección de
capacidad + permiso pedido en contexto + degradación**. Reglas:
- `if ('x' in navigator)` antes de usar; nunca detección por *user agent*.
- El permiso se pide **cuando el usuario intenta usar la función**, nunca al arrancar.
- La app funciona sin el permiso (con menos función), y explica qué se pierde.
- `Permissions-Policy` restringe lo que no se usa (la cabecera es de
  `frontend-web-platform-standards`).
- Un permiso denegado **no se vuelve a pedir en bucle**: se ofrece la ruta manual de ajustes.

## 4. Calidad y gates de CI

En orden de coste creciente; cada uno rompe el build:

1. **Lint del service worker** con el entorno correcto (`self`, `ServiceWorkerGlobalScope`), y
   prohibición por lint de `skipWaiting()` incondicional fuera del handler de mensaje.
2. **Validación del manifiesto**: campos obligatorios de instalabilidad, iconos 192/512 existentes y del
   tamaño declarado, `start_url` dentro de `scope`.
3. **Precache manifest revisado**: fallar si entra `index.html` sin revisión, si el precache supera el
   presupuesto acordado (se declara en el repo: MB y número de entradas) o si aparece un asset sin hash.
4. **Test de actualización** (el que nadie escribe y el que evita el incidente): en Playwright, cargar
   v1, desplegar v2, comprobar que aparece el aviso, que **no** se activa sin consentimiento, que tras
   aceptar se recarga **una vez** y que la versión activa es la nueva.
5. **Test de offline**: `context.setOffline(true)` y verificar que la app arranca, que la ruta de
   fallback offline aparece y que una mutación queda encolada y se envía al volver la red **una sola
   vez** (idempotencia).
6. **Test del kill switch** en preproducción, al menos una vez por trimestre: desplegar el SW de
   desactivación y comprobar que el cliente queda sin service worker y sin cachés.
7. **Lighthouse / auditoría de instalabilidad** como gate informativo; útil pero **no** sustituye a 4 y 5.

Probar siempre en un **perfil limpio y en dispositivo real iOS y Android**: el comportamiento de
instalación, push y almacenamiento **no** se reproduce en el emulador de escritorio.

## 5. Seguridad

**El service worker es un proxy con persistencia dentro del origen.** De ahí sale todo lo demás:

- **Si hay un XSS, hay un XSS persistente.** El atacante registra un service worker y a partir de ahí
  intercepta **todas** las peticiones del ámbito, sirve HTML propio, roba credenciales de formularios y
  sobrevive a la recarga, al cierre del navegador y al despliegue del parche. Un XSS en una app con
  service worker es **compromiso persistente del origen**, no un alert. La defensa primaria es la CSP
  con `nonce`/`strict-dynamic` y Trusted Types (→ `frontend-web-platform-standards`), más
  `worker-src`/`script-src` que restrinja de dónde puede venir un worker.
- **Alcance (`scope`)**: el mínimo necesario. Un SW registrado en `/` controla todo el origen. Si la app
  vive bajo `/app/`, el SW se sirve desde `/app/` y su ámbito es `/app/`. Ampliar el ámbito por encima
  de la ruta del script exige la cabecera `Service-Worker-Allowed`, que **no se emite salvo con
  justificación escrita**.
- **PROHIBIDO servir el service worker desde una ruta que un usuario pueda controlar**: subida de
  ficheros, contenido generado, CDN de terceros, subdominio compartido. Si un usuario puede colocar un
  fichero JS en tu origen y hacerlo servir con `Content-Type` de JavaScript, puede tomar el control de
  ese ámbito. Corolario: **no hay contenido subido por usuarios en el mismo origen que la PWA** — va a
  un origen distinto (→ `frontend-web-platform-standards`, `object-storage-standards`).
- **Datos cacheados en dispositivo compartido**: la Cache API y IndexedDB **no están cifradas** y son
  legibles por cualquiera con acceso al perfil del navegador. En un kiosco, un portátil compartido o un
  terminal de almacén: no se cachean datos personales ni de negocio sensibles, y el cierre de sesión
  borra cachés y bases. Un "logout" que solo borra el token deja los datos en disco.
- **Nada de secretos en el service worker**: es un fichero descargable. Ni claves de API, ni lógica de
  autorización, ni endpoints "ocultos".
- El SW **no** añade cabeceras de autenticación por su cuenta ni cachea respuestas autenticadas sin
  particionar por usuario. Cachear la respuesta de `/api/me` y servírsela al siguiente usuario del
  dispositivo es una fuga de datos real, y ocurre.
- HTTPS obligatorio (los service workers solo funcionan en contexto seguro; `localhost` es la única
  excepción).
- Push: verificar la firma/origen del mensaje en el handler y **no confiar en su contenido** para
  renderizar HTML. Un `showNotification` con datos sin sanear es una superficie más.
- La caché del SW **puede anular la política del CDN**: una respuesta con `no-store` que el SW guarda en
  `caches` sigue viva. Respetar en el SW la intención de las cabeceras de origen es parte del diseño, no
  una cortesía.

## 6. Rendimiento y operabilidad

- **La primera visita no se beneficia de nada**: el SW se instala *después*. Precachear 10 MB en la
  primera visita compite con la carga real. El precache es pequeño (shell y lo crítico); lo demás,
  bajo demanda o en `requestIdleCallback`.
- Instrumentar y **alertar** sobre: instalaciones y activaciones de SW, fallos de `install`, errores en
  el handler de `fetch`, tasa de aciertos de caché, `QuotaExceededError`, y sobre todo la
  **distribución de versiones activas** en clientes. Sin esa métrica, "hay gente en una versión vieja"
  se descubre por un ticket de soporte.
- Un error dentro del `fetch` handler **puede tumbar toda la navegación**: cada estrategia lleva
  `try/catch` con caída a `fetch(event.request)` sin intervención. Un service worker que falla debe
  comportarse como si no existiera.
- El SW se despierta y se duerme: **no mantiene estado en variables globales** entre eventos. Lo que
  deba persistir, en IndexedDB.
- Runbook mínimo escrito: (a) usuarios atrapados en versión vieja, (b) SW roto → kill switch, (c)
  cuota agotada, (d) push masivamente rechazado. → `incident-management-standards`.
- Despliegue: el SW se publica **en el mismo release** que los assets a los que apunta, y los assets
  antiguos permanecen durante la ventana de transición.

## 7. Sostenibilidad y prohibiciones

- El modelo de actualización se **prueba en cada release**, no se supone. Es la parte que se rompe en
  silencio.
- Revisar cada 6-12 meses: estado de las capacidades en iOS (cambia con cada versión mayor), cuotas,
  vigencia de Workbox/Serwist, y si alguna API "Chromium-only" ya es interoperable — para **retirar** el
  camino alternativo, no solo para añadir el nuevo.
- Cada API detrás de feature detection lleva escrita su **condición de retirada**.
- Si se abandona la PWA: **primero** el service worker de desactivación, luego se retira el resto.

**PROHIBIDO:**
- ❌ `skipWaiting()` incondicional en `install` — deja al usuario con HTML nuevo y bundle viejo (o al
  revés). Solo tras confirmación del usuario o con justificación escrita.
- ❌ Precachear el documento HTML sin revisión, o servirlo cache-first sin revalidación.
- ❌ Servir el script del service worker con caché larga, o precachearlo a sí mismo: **anula el kill
  switch** y el SW se vuelve inmortal.
- ❌ Desplegar una PWA sin plan de desactivación de emergencia escrito y probado.
- ❌ Registrar el service worker desde una ruta que un usuario pueda controlar, o usar
  `Service-Worker-Allowed` para ampliar el ámbito sin justificación.
- ❌ Cachear respuestas autenticadas sin particionar por usuario; conservar cachés y bases locales tras
  el cierre de sesión.
- ❌ `Notification.requestPermission()` (o el prompt de instalación) al cargar la página.
- ❌ Diseñar una funcionalidad sobre Background Sync, Periodic Background Sync, Background Fetch,
  Web Share Target, File System Access o `beforeinstallprompt` como si fueran universales:
  **son Baseline limited y en su mayoría Chromium-only**.
- ❌ Asumir almacenamiento duradero sin instalación en iOS (los 7 días de ITP), o dimensionar sin
  `navigator.storage.estimate()` ni manejar `QuotaExceededError`.
- ❌ Datos que **solo** existen en el cliente. La expulsión borra el origen entero, sin aviso.
- ❌ Cola de mutaciones sin clave de idempotencia, o resolución de conflictos "ya lo veremos".
- ❌ Ordenar o resolver conflictos con el reloj del dispositivo.
- ❌ `localStorage` como almacén de datos de aplicación o de tokens.
- ❌ Dos generadores de service worker en el mismo proyecto.
- ❌ Llamar "PWA" a una web con manifiesto y sin estrategia de actualización: es una web con un icono.
- ❌ Repetir que "en la UE las PWA no funcionan por la DMA": Apple revirtió el cambio en marzo de 2024 (§2).
- ❌ Copiar de memoria el estado de una capacidad en iOS. Se comprueba (§8).

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (WebSearch/WebFetch; MDN, `webstatus.dev` y su API,
`web-features`, WebKit.org, `developer.apple.com`, changelogs oficiales; feeds Atom de GitHub para
versiones — **`api.github.com` da 403 sin autenticar**; licencias leídas del `LICENSE` en crudo):

1. **Estado de las capacidades en iOS/WebKit**, versión por versión: qué añadió el último Safari
   (instalación, push, almacenamiento, APIs de dispositivo). Es el factor que decide y **cambia cada
   septiembre**. Fuente: notas de versión de Safari y el blog de WebKit, no un artículo de tendencias.
2. **Baseline por feature** en `webstatus.dev`/MDN, una por una: `service-workers` (widely),
   `push` (widely 2025-09-27), `notifications-apps` (widely 2025-09-27), `background-sync` (**limited**),
   `periodic-background-sync` (**limited**), `background-fetch` (**limited**), `beforeinstallprompt`
   (**limited**), `badging` (**limited**), `app-share-targets` (**limited**), `manifest` (**limited**),
   `storage-manager` (widely), `indexeddb` (widely), `clear-site-data` (**limited**).
   **El estado Baseline no captura los condicionantes de plataforma** (en iOS, push exige instalación):
   leerlo junto a la documentación de WebKit.
3. **Cuotas y política de expulsión** por navegador (WebKit *Storage Policy*, MDN *Storage quotas and
   eviction criteria*) y criterios reales de `navigator.storage.persist()`. Cambian sin aviso.
4. **Versiones y licencias**: Workbox (7.4.1, MIT), Serwist (9.5.12, MIT), `vite-plugin-pwa` (1.3.0,
   MIT), `@angular/service-worker` (22.1.0, MIT), `@serwist/next` (9.5.12, MIT). Comprobar además si
   alguna pasó a modo mantenimiento o cambió de propiedad.
5. **Estado de mantenimiento de Workbox**: publica (última 7.4.1, may-2026) pero **arrastra backlog**;
   si el proyecto entrara en mantenimiento, Serwist es la salida. Verificar antes de empezar un proyecto
   nuevo.
6. **Criterios de instalabilidad** por navegador en MDN: cambian (p. ej. el service worker dejó de ser
   requisito en Chromium). No copiar listas de blogs.
7. **Web Push**: RFC de Web Push / VAPID vigente y el estado de *Declarative Web Push* en WebKit.

**Huecos no verificados a ago-2026** (no rellenar de memoria; comprobar antes de usar):
- **Estado de *Declarative Web Push*** (Safari) y si ya es la vía recomendada en WebKit: **no verificado**.
- **Cifras exactas de cuota por navegador** más allá de los porcentajes de WebKit citados en §2
  (Chromium y Firefox): **no verificado**.
- **Criterios concretos de concesión de `navigator.storage.persist()`** por navegador a ago-2026:
  **no verificado**.
- **Estado de mantenimiento de `next-pwa`** (el original, no `@serwist/next`): **no verificado**.
- **Comportamiento exacto de las web apps instaladas en iOS 26 en segundo plano** (qué se congela y
  cuándo): **no verificado**; hay reportes de mejoras con límites por batería, sin documentación
  normativa localizada.
- **Datos de retención PWA vs. nativa**: **no verificado** y probablemente no generalizable. Se mide en
  el propio producto; **no se cita una cifra de un blog** para justificar la decisión de §2.
- **Presupuesto de precache** (MB y número de entradas) de §4: es un acuerdo de proyecto, **no un dato
  medido**.

**Discrepancia declarada**: fuentes secundarias (guías "PWA en iOS 2026", blogs de proveedores de push)
siguen afirmando que en la UE Apple degradó las PWA a accesos directos de Safari por la DMA. **La página
de soporte DMA de Apple dice lo contrario desde marzo de 2024** (texto verbatim en §2): la capacidad se
mantiene. Manda Apple. En sentido inverso, `webstatus.dev` marca `push` y `notifications-apps` como
**Baseline widely available**, lo que leído solo puede hacer creer que push funciona en cualquier web en
iOS: **no es así** — requiere instalación en la pantalla de inicio. Baseline mide motores, no
condicionantes de plataforma.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
