---
name: pwa-standards
description: Use when a web app installs, caches or works offline - sw.js and service-worker.js, ServiceWorkerRegistration and navigator.serviceWorker.register with scope, Service-Worker-Allowed header, install/activate/waiting lifecycle, skipWaiting and clients.claim, updatefound and registration.update(), manifest.webmanifest and manifest.json with start_url/scope/display/icons 192-512, beforeinstallprompt and appinstalled, apple-mobile-web-app-capable and apple-touch-icon, Workbox and workbox-config.js, Serwist and @serwist/next, vite-plugin-pwa, ngsw-config.json and @angular/service-worker, Cache API and caches.open, cache-first vs network-first vs stale-while-revalidate, navigation preload, precache manifest and revisioned assets, IndexedDB with idb or Dexie for offline data, navigator.storage.estimate() and persist(), quota eviction, Web Push with VAPID and applicationServerKey, PushSubscription and pushsubscriptionchange, Notification permission prompts, Background Sync and Periodic Background Sync, Badging, Web Share Target, an unregistering kill-switch service worker, or a stale service worker serving an old build.
---

# PWA standards (installable web app)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Sets the criteria for **the web that installs, caches and works without a network**: when a PWA is
worth building, what the service worker does and how it updates, what gets cached and with which
strategy, where offline data lives, how it is installed and how it notifies.

**Core axis**: a PWA is **not "an app but on the web"**. It is a website with extra capabilities
and, above all, **with an update model of its own** — and that is where almost everyone gets it
wrong. A normal website updates on reload; a PWA can leave a user stuck on the version from six
months ago, serving old HTML against a new API, without any deployment metric giving it away. The
service worker is the piece that grants the capabilities **and** the one that creates the problem.

Second framing rule: **the service worker is code with persistence inside your origin**. It
installs once and survives the tab closing, the deployment and your attempt to fix it. Treat it as
deployed infrastructure, not as one more file in the bundle.

Triggers: `sw.js`, `service-worker.js`, `navigator.serviceWorker.register`, `manifest.webmanifest`,
`workbox-config.js`, `vite-plugin-pwa`, `@serwist/next`, `ngsw-config.json`, `caches.open`,
`skipWaiting`, `clients.claim`, `beforeinstallprompt`, `navigator.storage.persist()`, VAPID,
`PushSubscription`, `apple-mobile-web-app-capable`, and the classic symptom: "some users still get
the old version".

**Not applicable**:
- `frontend-web-platform-standards` (**already written**) — **HTML, CSS, general browser APIs, the
  loading model, CSP and the build tool are theirs**. Here only the service worker, the manifest
  and the installation lifecycle. If the answer is still true without a service worker, it belongs
  there.
- `frontend-frameworks-standards` (**already written**) — **the framework and its rendering model**
  (CSR/SSR/SSG/islands/RSC) are theirs; here only what the PWA requires of the artifact that
  framework produces (hashed assets, HTML not blindly precached, an offline fallback route).
- `mobile-standards` — **the native app, its App Store / Google Play publishing, the signing, the
  release cycle and the platform APIs are theirs**. **Here the installable web.** The PWA vs.
  native comparison is written **from here** (§2), with honesty about iOS: if the decision ends in
  "native is needed", the rest is theirs.
- `caching-cdn-standards` — **the HTTP cache, the CDN, `Cache-Control`, `Vary` and purging are
  theirs**. **Here the service worker cache, which is another layer and can contradict the previous
  one**: a service worker responding from `caches` **does not consult the CDN nor honour its
  headers** — a perfect CDN purge never reaches the user. When the two policies disagree, **the
  service worker's wins**, and that is why it must be written alongside the other, not apart.
- `web-performance-standards` (**already written**) — **Core Web Vitals, performance budgets and
  their measurement are theirs**. Here only the effect of the service worker cache on the first
  visit (none) and on the subsequent ones.
- `accessibility-standards` (**already written**) — **the WCAG conformance criterion is theirs**.
  Here its technical consequence: a "new version available" or "you are offline" notice is dynamic
  content and needs an accessible announcement and correct focus.
- Data and synchronisation: `data-platform-standards` / `nosql-standards` (data model, conflicts,
  CRDTs and the sync engine), `api-design-standards` (the contract, idempotency and the ETags that
  make retrying possible), `streaming-cdc-standards` (change propagation). **Offline-first is a
  data model, not a cache** (§3): the cache belongs here, the model belongs there.
- `cross-platform-desktop-standards` — **cross-platform desktop is theirs** (Electron, Tauri,
  Avalonia, Qt: packaging, signing and notarisation, updating, system integration). **Here the
  installable web**; if the decision ends in "a desktop app is needed", the rest is theirs.
  Arbitration for Flutter, .NET MAUI and Compose Multiplatform: desktop there, mobile store in
  `mobile-standards`.
- `webgl-webgpu-standards` — canvas, GPU and frame budget. A PWA can contain a WebGPU canvas: they
  are different layers and do not overlap.
- `appsec-standards` (methodology and triage; here the concrete service worker controls),
  `privacy-engineering-standards` (**personal data cached on the device**: legal basis,
  minimisation, retention and deletion are theirs), `secrets-management-standards` (**a secret does
  not live in the client, least of all in a persistent cache**), `observability-standards`
  (telemetry platform; here what to instrument in the SW lifecycle), `cicd-standards` (the pipeline
  that publishes the SW), `i18n-standards`, `webassembly-standards`.

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

### The prior decision: PWA, plain website or native app?

**By default you do not build a PWA.** A service worker is stateful infrastructure on the user's
device; it is added when there is a reason, not as a "modern app" checkbox.

| Signal | Decision |
|---|---|
| Content consumed online, short sessions, no offline use | **Plain website.** No service worker. The HTTP cache and the CDN already do the job (→ `caching-cdn-standards`) |
| Repeated use by the same users, launched from the desktop/home screen, tolerance for bad or intermittent networks (field, warehouse, transport, workshop) | **PWA.** It is the canonical case and the one that pays off most |
| Hardware or system integration the web does not give: Bluetooth/USB/NFC on iOS, background sensors, continuous background geolocation, widgets, contacts/calls integration, reliable background execution | **Native** (→ `mobile-standards`). There is no shortcut |
| Store distribution is a business requirement (visibility, in-app purchases, customer or sector demand) | **Native** or a wrapper; a PWA does not appear in the App Store |
| One team, one product's budget, fast iteration, no store review in the way | **PWA**: one deploy, one codebase, no gatekeeper |
| Retention measured as a criterion | **It depends, and it is measured**: web installation has less friction but also less stickiness. Do not decide it with other people's benchmarks |

The real cost of "native" is not writing the app: it is **maintaining two or three codebases, two
release cycles and two bug surfaces**, forever. The real cost of "PWA" is **iOS**.

### The constraint that decides in practice: iOS

Verified as of August 2026. **Cite it like this, do not soften it:**

- **Installation**: manual only, via *Share → Add to Home Screen*. **`beforeinstallprompt` does not
  exist** in Safari (webstatus.dev: `beforeinstallprompt` → **Baseline limited**, only Chrome/Edge
  76+/79+) — you cannot offer an "Install" button that installs. Since **iOS 16.4** it can be
  installed from the Share menu of Safari, Chrome, Edge, Firefox and Orion (MDN), but they all use
  WebKit: the capabilities are Apple's.
- **From iOS 26 / iPadOS 26**, *any* site added to the home screen opens **as a web app by default**
  (previously it had to be configured); the user can disable "Open as Web App". The manifest still
  matters (icons, `start_url`, `display`, offline with a service worker).
- **Push**: the Push API on iOS **only works in web apps added to the home screen**, not in a Safari
  tab, and permission must be requested after user interaction. Web Push arrived in iOS 16.4.
  webstatus.dev classifies `notifications-apps` ("Notifications from service workers and installed
  apps") as **Baseline widely available (widely since 2025-09-27)** and `push` ("Push messages")
  also **widely since 2025-09-27** — but **that "widely" does not mean "the same everywhere"**: the
  prior-installation requirement on iOS does not show up in the Baseline status. It is the classic
  trap of this domain.
- **Storage and its expiry**: WebKit, *Tracking Prevention*, verbatim:
  > "ITP deletes all cookies created in JavaScript and all other script-writeable storage after 7 days
  > of no user interaction with the website."

  and, also verbatim:
  > "The first-party domain of home screen web applications is exempt from ITP's 7-day cap on all
  > script-writeable storage, i.e. ITP always skips that domain in its website data removal algorithm."

  **Operational consequence, which is the only thing that matters**: in Safari **without
  installing**, IndexedDB, localStorage, the Cache API and **the service worker registration
  itself** are deleted after 7 days without interaction. A non-installed PWA on iOS **has no durable
  storage**. If the use case depends on local data, either the user installs it or the design is
  wrong.
- **Quotas**: since Safari 17 / iOS 17, up to ~**80%** of total disk for the browser and ~**20%**
  for other apps embedding web content; an installed web app has the same origin quota as in the
  browser. **Verify before sizing anything** (§8) and **do not design against the quota**: measure
  it with `navigator.storage.estimate()` and degrade.
- **There is no** Background Sync nor Periodic Background Sync (webstatus.dev: both **Baseline
  limited**, Chromium only), no Background Fetch, no Web Share Target, no File System Access. What
  is not there is not there: do not plan a feature on top of an API iOS does not implement.

### The DMA and PWAs in the EU: what actually happened

There was an attempt to remove them and **it was reversed**. Apple, on its DMA support page
(verbatim):

> "UPDATE: Previously, Apple announced plans to remove the Home Screen web apps capability in the EU as
> part of our efforts to comply with the DMA. […] We have received requests to continue to offer support
> for Home Screen web apps in iOS and iPadOS, therefore we will continue to offer the existing Home
> Screen web apps capability in the EU. This support means Home Screen web apps continue to be built
> directly on WebKit and its security architecture, and align with the security and privacy model for
> native apps on iOS and iPadOS."

> "Developers and users who may have been impacted by the removal of Home Screen web apps in the beta
> release of iOS and iPadOS in the EU can expect the return of the existing functionality for Home
> Screen web apps with the availability of iOS 17.4 and and iPadOS 17.4 in early March." *(the "and and"
> is in the original)*

**Resulting state: PWAs work in the EU exactly as in the rest of the world, on WebKit.**
Documentation — and model answers — still circulate claiming the opposite, that in the EU PWAs open
as a Safari tab: **that is false since March 2024**. If someone cites it, the source is Apple's
page, not a February 2024 article.

### Toolchain

| Piece | Choice | Status as of Aug-2026 | Why |
|---|---|---|---|
| Hand-written service worker | Only if the case is trivial (one `fetch` handler and an offline route) | — | Writing precaching, versioning and cache cleanup by hand is reinventing known bugs |
| Service worker library | **Workbox** | `workbox-build`/`workbox-window` **7.4.1** (2026-05-04), **MIT** (read from the `LICENSE`) | Still the historical default and **still publishing**; the issue backlog is notable but the project is not deprecated |
| Maintained alternative | **Serwist** (Workbox fork) | **9.5.12** (2026-07-22), **MIT** | It was born because Workbox development stalled; today they coexist. A reasonable choice if you need cadence or App Router support |
| Vite integration | **`vite-plugin-pwa`** | **1.3.0** (2026-05-05), MIT | Generates the manifest, the precache manifest and the update flow. `injectManifest` when you need your own logic; `generateSW` for the standard case |
| Next.js integration | **`@serwist/next`** | **9.5.12**, MIT | The original `next-pwa` is unmaintained; verify before adopting it (§8) |
| Angular integration | **`@angular/service-worker`** + `ngsw-config.json` | **22.1.0** (2026-07-29), MIT | Ships with the framework; its version model is its own and **does not mix with Workbox** |
| Offline data | **IndexedDB** with a wrapper (`idb`) or a local database with its own sync | — | `localStorage` is synchronous, small and blocks the thread: **it is not application storage** |
| Push | **Web Push + VAPID** with an own or managed service | Push: Baseline widely (2025-09-27) | Standard; no per-browser deal nor proprietary SDK |

**Tooling rule**: use **one** service worker solution per project. Two layers generating service
workers (e.g. the framework's plus another one added) is a guaranteed brick.

## 3. Structure and conventions

### Lifecycle: what has to be internalised

`register` → **`install`** (resources are precached; if anything fails, the whole install fails) →
**`waiting`** (a new SW is installed but the old one still controls the open pages) →
**`activate`** (old caches are cleaned up) → `controlling`.

- A new service worker **does not take control** while a tab controlled by the previous one
  remains. "Reload" is not enough: normal navigation keeps control. You need to close every tab of
  the origin, or `skipWaiting`, or `Clients.claim()`, or a forced `navigate`.
- The browser checks for updates to the SW script on navigation and, in general, when the script
  has been in cache for more than 24 h. **The service worker script is served with `Cache-Control:
  max-age=0` (or `no-cache`)**. An SW cached for a year is an immortal SW.
- Explicit `registration.update()` at low-activity moments (window focus, route change, an hourly
  timer) so as not to depend on chance.

### Updating is the central problem

The domain's failure is not "it does not work offline": it is **the user trapped in an old
version**, mixing HTML from months ago with an API whose contract has already changed. It is
designed explicitly:

- **`skipWaiting` by default is FORBIDDEN.** Activating the new SW while the open page is running
  the old bundle produces the worst outcome: chunks that no longer exist (another version precached
  them), responses from a different schema and incoherent state halfway through a form.
  `skipWaiting` is acceptable **only** in an app with no lazy-loading of versioned chunks, or when
  **the user** triggers it.
- **Default pattern**: new SW → stays in `waiting` → the app detects `updatefound` /
  `registration.waiting` → **tells the user** ("a new version is available, reload") → the user
  accepts → `postMessage({type:'SKIP_WAITING'})` → the SW calls `skipWaiting()` → on
  `controllerchange` the page does `location.reload()` **exactly once** (keep a flag: the infinite
  reload loop is this pattern's classic bug).
- **Forced reload without asking** only when there is an incompatible change (broken API contract).
  Then you still warn and save the work in progress before reloading. Losing a half-filled form to a
  deployment is an incident, not a detail.
- **Compatibility window**: the previous version's assets **keep being served** during the
  deployment (at minimum for as long as a user might keep the tab open: days). Deleting them at
  deploy time turns every release into chunk load errors.
- **Visible version**: the build version is exposed in the client (a variable injected at build
  time) and **is sent in the telemetry**. Without that you cannot know how many people are trapped;
  with it, it is a metric: *distribution of active versions*, plus an alert if the old tail does not
  fall after a release.
- The SW is registered with the **build version in the query string or in the name** only if your
  tooling does not revision the script; the real rule is that **the script's content changes on
  every release**, because the browser compares byte by byte.

### Emergency kill plan (the service worker turned into a brick)

Nobody prepares it and everybody needs it once. **It is written before the first release**, tested
in pre-production and kept as a runbook:

1. **Kill-switch SW**: deploy at the same service worker URL a script that **caches nothing** and
   that on `install` calls `self.skipWaiting()`, on `activate` deletes **all** caches
   (`caches.keys()` → `caches.delete`), calls `self.registration.unregister()` and reloads the
   clients (`clients.matchAll()` → `client.navigate(client.url)`).
2. Prerequisite — **and this is the part that gets lost**: the browser must be able to **download
   the new script**. That is why the SW script is **never** served with a long cache and **never**
   precaches itself. If the broken SW caches its own script with a long cache, there is no kill
   switch: you have to wait for expiry or for the user to clear site data by hand.
3. `Clear-Site-Data: "storage"` (or `"*"`) in the response as reinforcement — verify support before
   depending on it (webstatus.dev: `clear-site-data` **Baseline limited**, no Chromium in the list).
   It is reinforcement, **not** the plan.
4. Definitively retiring a PWA (it is no longer offered) **requires** step 1: if you simply delete
   the file, the 404 leaves the previous SW alive and indefinitely in charge of the origin.
5. Exit metric: telemetry must show the decline of clients controlled by the affected version. If it
   does not fall, the kill switch is not landing.

### Cache strategies by resource type

| Resource | Strategy | Reason |
|---|---|---|
| Assets with a hash in the name (JS, CSS, fonts, versioned images) | **Cache-first**, precached, immutable | The name changes with the content: there is nothing to revalidate |
| **HTML / navigation documents** | **Network-first** with a short timeout and **fallback to the cached copy** | See below |
| API data that tolerates being slightly stale | **Stale-while-revalidate** with explicit expiry | Instant response, background update |
| Data that must be correct (balance, availability, permissions) | **Network-only** (or network-first with a visible notice that the data is cached) | Stale data that looks current is worse than no data |
| POST/PUT/DELETE and anything with an effect | **Never cached**. They are queued (§ offline) | |
| Third-party resources (analytics, maps, ads) | Not precached; optionally stale-while-revalidate with an entry limit | Precaching a third party is adopting its weight and its lifecycle |

**Caching HTML badly is what breaks deployments.** An `index.html` precached cache-first serves
forever references to chunks that no longer exist: the app boots and dies. Hard rules:
- The navigation document is **never** cache-first without revalidation.
- In an SPA with an `app shell`, the shell **is revisioned on every build** and is part of the
  precache manifest generated by the tooling; never precache "index.html" as a fixed entry without
  revisioning.
- **Enable Navigation Preload** when using network-first on navigations: without it, the SW boot
  time is added to the request latency.
- Every cache has a **versioned name** and `activate` **deletes those not belonging to this
  version**. A cache with no expiry policy and no entry limit grows until the browser evicts the
  whole origin.
- **Range of cacheable responses**: do not cache responses with a `status` other than 200 nor opaque
  ones (`type: 'opaque'`) without knowing what you are doing — they take up quota (padding) and you
  cannot inspect their status.

### Storage

- **Cache API** for HTTP responses. **IndexedDB** for application data. `localStorage`
  **FORBIDDEN** for application data (synchronous, ~5 MB, blocks the main thread) and for tokens.
- Quota: `navigator.storage.estimate()` (webstatus.dev: `storage-manager` **Baseline widely** since
  2023-09-18, widely 2026-03-18) **before** downloading a large offline data package, and explicit
  degradation if it does not fit. An unhandled `QuotaExceededError` corrupts the state halfway.
- **Eviction**: under disk pressure the browser **deletes the whole origin**, not a part of it. The
  design assumes the cache **can disappear entirely at any moment** and that the app must be able to
  rebuild from the network. Data that only exists on the client = lost data.
- **Persistent storage**: `navigator.storage.persist()` to request persistent mode. It is requested
  **after a real signal of commitment** (installation, login, first saved piece of work), not on the
  first load; it is checked with `persisted()`; **it is not assumed granted** — the criteria vary by
  browser and change. In WebKit, the real PWA exemption does not come from this API but from being
  installed (see §2).
- Cached personal data: there is **retention and deletion**. On logout, **the user's caches and
  local databases are deleted**, not just the token. The legal criterion belongs to
  `privacy-engineering-standards`.

### Real offline: it is a data model, not a cache

A read cache gives you "the app opens without a network". That is **not** offline-first.
Offline-first means **you can write without a network** and that there is a written answer to what
happens when two devices write the same thing.

- **A durable mutation queue** in IndexedDB (not in memory), with retries with backoff,
  **idempotency keys** per operation (→ `api-design-standards`) and per-item visible status
  ("pending sync"). Without idempotency, a retry duplicates orders.
- **Conflict resolution decided and written down** before implementing: last write wins (with the
  server's clock, never the client's), field-level merge, CRDTs, or user intervention. "It will not
  happen" is not a strategy. The model is set by the corresponding data skill.
- **The client clock is not trustworthy**: never sort by the device's `Date.now()`.
- **Background Sync** only as an *optimisation* in Chromium (webstatus.dev: **Baseline limited**).
  Synchronisation must work equally **without** it, on regaining focus or connectivity (`online`,
  `visibilitychange`). The same goes for Periodic Background Sync and Background Fetch.
- The UI **tells the truth**: what is synced, what is pending, what failed and since when. An
  "offline" indicator and a "data as of HH:MM" timestamp are worth more than any trick.

### Manifest and installability

Installation requirements in Chromium browsers, per MDN (verbatim):
> `name` or `short_name`; `icons` — must contain a 192px and a 512px icon; `start_url`; `display` and/or
> `display_override`; `prefer_related_applications` — must be `false` or not present

and: *"PWAs must be served using HTTPS, or from a local development environment using `localhost` or
`127.0.0.1`"*; on the service worker: *"While **not a requirement** for installability, many PWAs use
service workers to provide an offline experience."*

Per-browser status as of Aug-2026 (MDN): **Chromium** installs on every supported desktop; **Safari**
offers *Add to Dock* on macOS (Safari 17+) with or without a manifest; **desktop Firefox does not
install PWAs with a manifest**; on **Android** Firefox, Chrome, Edge, Opera and Samsung Internet
install; on **iOS 16.4+**, from the Share menu of Safari, Chrome, Edge, Firefox and Orion.

- `beforeinstallprompt` is **Chromium-only** (Baseline limited). Your own "Install" button exists
  **only** there: store the event, offer the button at a meaningful moment and degrade gracefully
  (manual instructions) elsewhere. **Never** a button that does nothing in Safari.
- `scope` and `start_url` consistent with the deployment; an explicit `id` in the manifest so the
  app's identity does not depend on the URL.
- Maskable icons in addition to the normal ones; `theme_color`, `background_color`, `display:
  standalone` (or `minimal-ui` if you want a navigation bar). The manifest's advanced capabilities
  (`shortcuts`, `share_target`, `file_handlers`, `protocol_handlers`, `launch_handler`) are
  **Baseline limited, nearly all Chromium-only**: progressive enhancement, never a functional
  requirement.
- Installation **is not begged for**. An "install our app" modal on the first visit is the same
  antipattern as the notifications pop-up.

### Push notifications

- **Product rule, no exceptions: asking for permission on entry is the antipattern.** Permission is
  requested **after a user action that justifies it** ("notify me when the order arrives"),
  explaining what will be sent and how often, and with an alternative if they say no. A
  `Notification.requestPermission()` on `load` burns the permission **forever** in that browser: a
  "denied" is permanent and cannot be asked again. Browsers also penalise the pattern.
- Infrastructure: **Web Push with VAPID**. VAPID keys: the **public** one goes in the client
  (`applicationServerKey`), the **private one lives on the server** and in a secrets manager, never
  in the repo nor in the bundle (→ `secrets-management-standards`).
- The payload is end-to-end encrypted towards the browser; even so **no personal or sensitive data
  is sent in the notification**: it shows up on the lock screen of a device that may be shared.
- Subscriptions: handle `pushsubscriptionchange` and **purge** the subscriptions the push service
  rejects (404/410). A subscriptions table that only grows is a cost and a risk.
- Frequency and usefulness: every notification has a reason and a link that goes to the right place.
  A browser can revoke the permission if the site abuses it; the user, sooner.
- On iOS, remember: **only if installed**, and the prompt requires a user gesture.

### Device capabilities

Camera, microphone, geolocation, sensors, Bluetooth, USB, clipboard, wake lock: **capability
detection + permission requested in context + degradation**. Rules:
- `if ('x' in navigator)` before use; never *user agent* detection.
- Permission is requested **when the user tries to use the feature**, never at start-up.
- The app works without the permission (with less functionality), and explains what is lost.
- `Permissions-Policy` restricts what is not used (the header belongs to
  `frontend-web-platform-standards`).
- A denied permission **is not asked again in a loop**: offer the manual settings route.

## 4. Quality and CI gates

In increasing order of cost; each one breaks the build:

1. **Service worker lint** with the correct environment (`self`, `ServiceWorkerGlobalScope`), and a
   lint ban on unconditional `skipWaiting()` outside the message handler.
2. **Manifest validation**: mandatory installability fields, 192/512 icons that exist and are the
   declared size, `start_url` inside `scope`.
3. **Revisioned precache manifest**: fail if `index.html` enters unrevisioned, if the precache
   exceeds the agreed budget (declared in the repo: MB and number of entries) or if an unhashed
   asset shows up.
4. **Update test** (the one nobody writes and the one that prevents the incident): in Playwright,
   load v1, deploy v2, check the notice appears, that it does **not** activate without consent, that
   after accepting it reloads **once** and that the active version is the new one.
5. **Offline test**: `context.setOffline(true)` and verify the app boots, that the offline fallback
   route appears and that a mutation is queued and sent when the network returns **exactly once**
   (idempotency).
6. **Kill-switch test** in pre-production, at least once a quarter: deploy the kill-switch SW and
   check the client ends up with no service worker and no caches.
7. **Lighthouse / installability audit** as an informational gate; useful but **not** a substitute
   for 4 and 5.

Always test in a **clean profile and on real iOS and Android devices**: installation, push and
storage behaviour **do not** reproduce in the desktop emulator.

## 5. Security

**The service worker is a proxy with persistence inside the origin.** Everything else follows from
that:

- **If there is an XSS, there is a persistent XSS.** The attacker registers a service worker and
  from then on intercepts **all** requests in scope, serves their own HTML, steals form credentials
  and survives the reload, the browser closing and the patch deployment. An XSS in an app with a
  service worker is **persistent compromise of the origin**, not an alert box. The primary defence
  is a CSP with `nonce`/`strict-dynamic` and Trusted Types (→ `frontend-web-platform-standards`),
  plus `worker-src`/`script-src` restricting where a worker can come from.
- **Scope (`scope`)**: the minimum necessary. An SW registered at `/` controls the whole origin. If
  the app lives under `/app/`, the SW is served from `/app/` and its scope is `/app/`. Widening the
  scope above the script's path requires the `Service-Worker-Allowed` header, which **is not emitted
  without a written justification**.
- **FORBIDDEN to serve the service worker from a path a user can control**: file uploads, generated
  content, third-party CDN, shared subdomain. If a user can place a JS file on your origin and have
  it served with a JavaScript `Content-Type`, they can take control of that scope. Corollary:
  **there is no user-uploaded content on the same origin as the PWA** — it goes to a different
  origin (→ `frontend-web-platform-standards`, `object-storage-standards`).
- **Data cached on a shared device**: the Cache API and IndexedDB **are not encrypted** and are
  readable by anyone with access to the browser profile. On a kiosk, a shared laptop or a warehouse
  terminal: no personal or sensitive business data is cached, and logout deletes caches and
  databases. A "logout" that only deletes the token leaves the data on disk.
- **No secrets in the service worker**: it is a downloadable file. No API keys, no authorisation
  logic, no "hidden" endpoints.
- The SW **does not** add authentication headers on its own nor cache authenticated responses
  without partitioning per user. Caching the response of `/api/me` and serving it to the next user
  of the device is a real data leak, and it happens.
- HTTPS mandatory (service workers only work in a secure context; `localhost` is the only
  exception).
- Push: verify the message's signature/origin in the handler and **do not trust its content** to
  render HTML. A `showNotification` with unsanitised data is one more surface.
- The SW cache **can override the CDN's policy**: a response with `no-store` that the SW stores in
  `caches` stays alive. Respecting the intent of the origin headers inside the SW is part of the
  design, not a courtesy.

## 6. Performance and operability

- **The first visit benefits from nothing**: the SW installs *afterwards*. Precaching 10 MB on the
  first visit competes with the actual load. The precache is small (shell and what is critical);
  everything else on demand or in `requestIdleCallback`.
- Instrument and **alert** on: SW installs and activations, `install` failures, errors in the
  `fetch` handler, cache hit rate, `QuotaExceededError`, and above all the **distribution of active
  versions** across clients. Without that metric, "some people are on an old version" is discovered
  via a support ticket.
- An error inside the `fetch` handler **can take down all navigation**: every strategy carries a
  `try/catch` falling back to `fetch(event.request)` with no intervention. A failing service worker
  must behave as if it did not exist.
- The SW wakes up and goes to sleep: **it does not keep state in global variables** between events.
  Whatever must persist goes into IndexedDB.
- Minimum written runbook: (a) users trapped on an old version, (b) broken SW → kill switch, (c)
  quota exhausted, (d) push massively rejected. → `incident-management-standards`.
- Deployment: the SW is published **in the same release** as the assets it points to, and the old
  assets remain during the transition window.

## 7. Sustainability and prohibitions

- The update model is **tested on every release**, not assumed. It is the part that breaks silently.
- Review every 6-12 months: the status of capabilities on iOS (it changes with every major
  version), quotas, the health of Workbox/Serwist, and whether any "Chromium-only" API is now
  interoperable — in order to **remove** the alternative path, not just to add the new one.
- Every API behind feature detection carries a written **retirement condition**.
- If the PWA is abandoned: **first** the kill-switch service worker, then retire the rest.

**FORBIDDEN:**
- ❌ Unconditional `skipWaiting()` in `install` — it leaves the user with new HTML and an old bundle
  (or the other way round). Only after user confirmation or with a written justification.
- ❌ Precaching the HTML document without revisioning, or serving it cache-first without
  revalidation.
- ❌ Serving the service worker script with a long cache, or having it precache itself: **it kills
  the kill switch** and the SW becomes immortal.
- ❌ Deploying a PWA without a written and tested emergency kill plan.
- ❌ Registering the service worker from a path a user can control, or using `Service-Worker-Allowed`
  to widen the scope without justification.
- ❌ Caching authenticated responses without partitioning per user; keeping caches and local
  databases after logout.
- ❌ `Notification.requestPermission()` (or the install prompt) on page load.
- ❌ Designing a feature on top of Background Sync, Periodic Background Sync, Background Fetch,
  Web Share Target, File System Access or `beforeinstallprompt` as if they were universal:
  **they are Baseline limited and mostly Chromium-only**.
- ❌ Assuming durable storage without installation on iOS (ITP's 7 days), or sizing without
  `navigator.storage.estimate()` and without handling `QuotaExceededError`.
- ❌ Data that exists **only** on the client. Eviction deletes the whole origin, with no warning.
- ❌ A mutation queue with no idempotency key, or "we will see about it" conflict resolution.
- ❌ Ordering or resolving conflicts with the device clock.
- ❌ `localStorage` as a store for application data or tokens.
- ❌ Two service worker generators in the same project.
- ❌ Calling "PWA" a website with a manifest and no update strategy: it is a website with an icon.
- ❌ Repeating that "in the EU PWAs do not work because of the DMA": Apple reverted the change in
  March 2024 (§2).
- ❌ Quoting the status of a capability on iOS from memory. It is checked (§8).

## 8. Mandatory web verification

Before fixing anything, check online (WebSearch/WebFetch; MDN, `webstatus.dev` and its API,
`web-features`, WebKit.org, `developer.apple.com`, official changelogs; GitHub Atom feeds for
versions — **`api.github.com` returns 403 unauthenticated**; licences read from the raw `LICENSE`):

1. **Status of capabilities on iOS/WebKit**, version by version: what the latest Safari added
   (installation, push, storage, device APIs). It is the deciding factor and **it changes every
   September**. Source: Safari release notes and the WebKit blog, not a trends article.
2. **Baseline per feature** on `webstatus.dev`/MDN, one by one: `service-workers` (widely),
   `push` (widely 2025-09-27), `notifications-apps` (widely 2025-09-27), `background-sync`
   (**limited**), `periodic-background-sync` (**limited**), `background-fetch` (**limited**),
   `beforeinstallprompt` (**limited**), `badging` (**limited**), `app-share-targets` (**limited**),
   `manifest` (**limited**), `storage-manager` (widely), `indexeddb` (widely), `clear-site-data`
   (**limited**). **The Baseline status does not capture platform constraints** (on iOS, push
   requires installation): read it alongside the WebKit documentation.
3. **Quotas and eviction policy** per browser (WebKit *Storage Policy*, MDN *Storage quotas and
   eviction criteria*) and the real criteria of `navigator.storage.persist()`. They change without
   notice.
4. **Versions and licences**: Workbox (7.4.1, MIT), Serwist (9.5.12, MIT), `vite-plugin-pwa` (1.3.0,
   MIT), `@angular/service-worker` (22.1.0, MIT), `@serwist/next` (9.5.12, MIT). Also check whether
   any has gone into maintenance mode or changed ownership.
5. **Workbox maintenance status**: it publishes (latest 7.4.1, May-2026) but **carries a backlog**;
   if the project went into maintenance, Serwist is the exit. Verify before starting a new project.
6. **Installability criteria** per browser on MDN: they change (e.g. the service worker stopped
   being a requirement in Chromium). Do not copy lists from blogs.
7. **Web Push**: the Web Push / VAPID RFC in force and the status of *Declarative Web Push* in
   WebKit.

**Gaps not verified as of Aug-2026** (do not fill from memory; check before using):
- **Status of *Declarative Web Push*** (Safari) and whether it is already the recommended route in
  WebKit: **not verified**.
- **Exact quota figures per browser** beyond the WebKit percentages cited in §2 (Chromium and
  Firefox): **not verified**.
- **Concrete grant criteria for `navigator.storage.persist()`** per browser as of Aug-2026: **not
  verified**.
- **Maintenance status of `next-pwa`** (the original, not `@serwist/next`): **not verified**.
- **Exact behaviour of installed web apps on iOS 26 in the background** (what is frozen and when):
  **not verified**; there are reports of improvements with battery-based limits, with no normative
  documentation located.
- **PWA vs. native retention data**: **not verified** and probably not generalisable. It is measured
  in your own product; **do not cite a figure from a blog** to justify the §2 decision.
- **Precache budget** (MB and number of entries) in §4: it is a project agreement, **not a measured
  figure**.

**Declared discrepancy**: secondary sources ("PWA on iOS 2026" guides, push vendor blogs) still
claim that in the EU Apple downgraded PWAs to Safari shortcuts because of the DMA. **Apple's DMA
support page says the opposite since March 2024** (verbatim text in §2): the capability remains.
Apple wins. In the opposite direction, `webstatus.dev` marks `push` and `notifications-apps` as
**Baseline widely available**, which read on its own can make you believe push works on any website
on iOS: **it does not** — it requires installation to the home screen. Baseline measures engines,
not platform constraints.

If the web contradicts this document, **the web wins** — flag the discrepancy.
