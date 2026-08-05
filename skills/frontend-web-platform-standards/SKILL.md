---
name: frontend-web-platform-standards
description: Use when deciding what the browser itself must do - .html, .css, .browserslistrc, browserslist in package.json, browserslist-config-baseline, Baseline widely/newly available targets, stylelint-plugin-use-baseline or @eslint/css require-baseline, container queries, :has(), @layer, subgrid, @property, color-mix(), native CSS nesting, view transitions, Tailwind vs CSS Modules vs plain CSS, vite.config.ts, Vite 8, Rolldown, esbuild, Turbopack, Lightning CSS, postcss.config, bundle-size budgets and import-cost review, script type=module, defer/async, preload/preconnect/fetchpriority, font-display and subsetting, srcset/picture/AVIF/loading=lazy, fetch/AbortController/IntersectionObserver/URLPattern/structuredClone/Temporal polyfill decisions, Content-Security-Policy nonce and hash, Trusted Types, setHTML and the Sanitizer API, innerHTML sinks, SameSite cookies, CORS, Permissions-Policy, Subresource Integrity, X-Frame-Options/frame-ancestors, localStorage token storage, or npm lockfile and install-script supply-chain hardening.
---

# Estándares de plataforma web (frontend)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio sobre **lo que hace el navegador**: qué características de HTML, CSS y de las APIs de
plataforma se pueden usar y con qué política de soporte, cómo se carga la página, qué presupuesto tiene
el bundle, con qué herramienta se construye y qué controles de seguridad del cliente son obligatorios.

**Eje**: la plataforma antes que el framework. Antes de añadir una dependencia, la pregunta es si el
navegador ya lo hace y desde cuándo lo hace en **todos** los navegadores del objetivo.

Triggers: `.html`, `.css`, `.browserslistrc`, `browserslist` en `package.json`, `vite.config.ts`,
`postcss.config.*`, `lightningcss` config, cabeceras `Content-Security-Policy` / `Permissions-Policy` /
`Cross-Origin-*`, `<link rel=preload|preconnect>`, `srcset`/`<picture>`, `@font-face`, `@layer`,
`@container`, `innerHTML`, `localStorage`, `package-lock.json`/`pnpm-lock.yaml` visto como superficie
de ataque.

**Regla de arbitraje con `frontend-frameworks-standards`**: si la respuesta **cambiaría al cambiar de
framework**, es de `frontend-frameworks-standards`; si **seguiría siendo cierta en cualquiera** (o sin
ninguno), es de aquí. `fetchpriority` en la imagen LCP es de aquí; si esa imagen la emite `next/image`
o `<Image>` de Astro es detalle de allí.

**No aplica**:
- `frontend-frameworks-standards` — **decide qué framework se elige, con qué modelo de renderizado
  (CSR/SSR/SSG/ISR/islas/RSC) y cómo se estructura la aplicación**: enrutado, carga de datos, estado
  servidor vs. cliente, hidratación, límites de error, tests de componente. Aquí no se recomienda ni se
  veta ningún framework; aquí se fija lo que el navegador debe cumplir **sea cual sea** el elegido.
- `typescript-standards` — **el lenguaje TS/JS, `tsconfig.json`, el tipado, el lint con Biome/ESLint y
  el empaquetado para publicar en npm son suyos**. Aquí el bundle como *presupuesto de bytes servidos*
  y el build como herramienta, no las reglas del lenguaje ni la config del compilador.
- `accessibility-standards` (**Ola 6, ya escrita**) — WCAG 2.2, ARIA, navegación por teclado, tecnología
  asistiva y la auditoría son suyos. Aquí solo el HTML semántico como base estructural: elegir el
  elemento correcto es decisión de plataforma, **exigirlo como conformidad es de ella**.
- `web-performance-standards` (**Ola 6, en curso**) — Core Web Vitals, presupuestos de rendimiento y su
  medición son suyos. Aquí las decisiones de carga (orden, prioridad, formato) que los determinan.
- `design-systems-standards` (**ya escrita** — **el contrato público del componente y el gobierno del
  sistema como producto versionado**: tokens, API de props, política de cambios rompientes,
  documentación y adopción. Aquí el CSS y las APIs del navegador con las que se implementa),
  `cms-jamstack-standards` (**ya escrita** — **dónde vive el contenido, quién lo edita y cómo se
  publica**: modelado, previsualización, y la invalidación de caché al publicar),
  `pwa-standards` (service worker, manifest, offline), `webgl-webgpu-standards`
  (**Ola 6, en curso**), `i18n-standards` (**ya escrita** — **aquí las propiedades lógicas de CSS y
  la decisión de polirrellenar `Intl`/`Temporal`**; **allí qué se formatea y con qué reglas**:
  catálogos de mensajes, ICU MessageFormat, categorías plurales de CLDR, colación, normalización
  Unicode y zonas horarias. Regla útil: si el problema es *dónde cae el margen en RTL*, es de aquí;
  si es *cómo se pluraliza en polaco*, es suyo).
- `caching-cdn-standards` — **la caché HTTP, el CDN, `Cache-Control`, `Vary` y la purga son suyos**.
  Aquí solo qué cabeceras emite la propia aplicación y por qué (assets con hash = inmutables; HTML = no).
- `api-design-standards` (el contrato que el frontend consume), `appsec-standards` (metodología,
  modelado de amenazas y triaje; aquí los controles concretos del navegador),
  `secrets-management-standards` (**un secreto no vive en el cliente**: si hay que guardarlo, el diseño
  está mal — el criterio de custodia es suyo), `identity-access-management-standards` (flujos OIDC),
  `observability-standards` (plataforma de RUM y telemetría; aquí solo qué instrumentar en el cliente),
  `cicd-standards` (la pipeline que ejecuta los gates de §4), `webassembly-standards` (**ya escrita**:
  el módulo Wasm y su runtime), `mobile-standards` (app nativa), `dart-standards` (Flutter web).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Estado a ago-2026 | Por qué |
|---|---|---|---|
| Política de soporte | **Baseline Widely available** como objetivo por defecto | `baseline widely available` = soportado en Chrome, Edge, Firefox y Safari desde hace **30 meses** | Es la única definición de "navegador moderno" que no es una opinión. Medible y auditable |
| Expresión de la política | **Browserslist** con `extends browserslist-config-baseline` o la query `baseline widely available` | Queries `baseline widely available` / `baseline newly available` / `baseline <año>` soportadas nativamente | Una sola fuente que alimenta build, autoprefixer y linters |
| Reproducibilidad del target | Congelar a `baseline widely available on YYYY-MM-DD` en el build | Recomendación de `baseline-browser-mapping` | "Widely" es un blanco móvil: sin fecha fijada, dos builds del mismo commit no producen el mismo output |
| Gate de features | `@eslint/css` regla `css/require-baseline` **o** `stylelint-plugin-use-baseline`; `html-eslint` regla `use-baseline`; `eslint-plugin-baseline-js` para JS | Todos con el mismo knob (`widely` / `newly` / año) | Convierte la política en fallo de CI, no en costumbre |
| Bundler / dev server | **Vite** | **8.2.0** (8.0 estable 2026-03-12; **Rolldown** es ya el bundler único, esbuild y Rollup desaparecen del pipeline) | Un solo bundler dev/prod: se acaba la clase de bug "funciona en dev, rompe en build" |
| Bundler de bajo nivel | **Rolldown** | **1.2.2** (1.0 estable 2026-05-07, API `^1.0.0` bajo semver) | Solo si construyes tooling; en apps se consume vía Vite |
| Transpilador puntual | **esbuild** | **0.28.1** | Sigue vivo y es correcto para tareas sueltas. **Su 0.x rompe en minors**: se fija versión exacta |
| Bundler de Next.js | **Turbopack** | Default de dev y build desde Next 16 | No es una elección: viene con el framework (→ `frontend-frameworks-standards`) |
| Transformación CSS | **Lightning CSS** (integrado en Vite) o PostCSS si necesitas plugins concretos | Lightning CSS **1.33.0**, licencia **MPL-2.0** (no MIT) | Toma el target de Browserslist y degrada automáticamente (`oklch()`, `light-dark()`, prefijos) |
| Estilos | **CSS nativo + CSS Modules** por defecto; **Tailwind** si el equipo ya lo domina | Tailwind **4.3.3**, MIT; v4 requiere Safari 16.4+/Chrome 111+/Firefox 128+ | Ver el trade-off escrito en §3 |
| Fuentes | Self-hosting con `woff2` subsetteado + `font-display: swap` | — | Un `<link>` a un CDN de fuentes es un tercero en la ruta crítica y un dominio extra que conectar |
| Imágenes | `<picture>` AVIF → WebP → JPEG, con `width`/`height` siempre | AVIF Baseline desde 2024 (~94-95% global); WebP ~97% | AVIF ahorra ~30% sobre WebP. **JPEG XL no es opción**: ~15% de soporte |

**Presupuesto de bundle** (punto de partida, se ajusta con datos reales de la audiencia y **se declara en
el repo**): ≤ **150 KB** de JS comprimido en la ruta inicial y ≤ **50 KB** de CSS. Superarlo no está
prohibido: está prohibido superarlo **sin que CI lo diga y sin que alguien lo apruebe**.

## 3. Estructura y convenciones

### Política de soporte de navegadores

- La política **se escribe**, no se supone: un `.browserslistrc` versionado más una línea en el README
  con el motivo. "Los navegadores modernos" no es una política.
- **Widely available** es el default. **Newly available** solo con decisión explícita y consciente de que
  incluye versiones publicadas hace semanas; en producto masivo, casi nunca.
- Elegir el target **con analítica propia**, no con estadísticas globales: una intranet y una tienda
  pública no tienen la misma cola de navegadores.
- Una característica fuera del target no se prohíbe: se usa **como mejora progresiva** dentro de
  `@supports` (CSS) o tras `if ('x' in y)` (JS), de forma que su ausencia degrade la experiencia y no
  la rompa. Si la ausencia rompe la funcionalidad, no es mejora progresiva: es un fallo de política.
- Herramientas que ya exponen Baseline y conviene usar: hover cards de CSS en Chrome DevTools (desde
  Chrome 140), `webstatus.dev` y su API (`baseline_status:newly AND group:css`), el paquete
  `web-features`, el componente `<baseline-status>`. **Verifica el estado por feature, no por rumor.**

### HTML

- El elemento correcto antes que el `div` con rol: `<button>`, `<a href>`, `<nav>`, `<main>`, `<dialog>`,
  `<details>`, `<form>`, `<label for>`, encabezados en orden. Un `<div onclick>` no es un botón —
  pierde foco, teclado, semántica y el `role`/`tabindex` que hay que añadir a mano ya es la señal.
- Un solo `<h1>` por documento y jerarquía sin saltos; landmarks reales.
- Formularios: `name`, `autocomplete` y `type` correctos (`email`, `tel`, `url`, `search`) — el teclado
  móvil, el autocompletado y el gestor de contraseñas dependen de ellos.
- Validación nativa (`required`, `pattern`, `min`/`max`) como primera capa; **nunca como única**: la
  validación de verdad es la del servidor.
- `<title>` único por página, `<meta name=description>`, Open Graph, canonical, `lang` en `<html>`. Es
  SEO y es accesibilidad a la vez; no cuesta y se olvida siempre.
- Datos estructurados JSON-LD si el contenido lo justifica (producto, artículo, evento).

### CSS moderno: qué sustituye a qué

> Estado a ago-2026 según Baseline. **Re-verificar por feature en `webstatus.dev`/MDN (§8)**: esta tabla
> caduca sola.

| Usa | En lugar de | Estado |
|---|---|---|
| `@container` + unidades `cq*` | Media queries para componentes reutilizables | Widely available |
| `:has()` | Clases de estado puestas por JS al padre | Widely available |
| `@layer` | Guerra de especificidad, `!important`, `#id` para "ganar" | Widely available |
| `subgrid` | Grids duplicados o alineación manual con `calc()` | Widely available |
| Propiedades personalizadas + `@property` | Variables de preprocesador para tokens de tema | Widely available |
| `color-mix()`, `light-dark()`, `oklch()` | Funciones de color de Sass, dobles paletas | `color-mix()` widely; **verificar `light-dark()`/`oklch()`** |
| Anidado nativo | Anidado de Sass como única razón para tener Sass | Widely available |
| View transitions | Librerías de animación de transición de página | Same-document widely; **cross-document: Chromium y Safari sí; Firefox solo parcial desde 146 → mejora progresiva obligatoria** |
| Anchor positioning, scroll-driven animations, masonry | Posicionamiento con JS | **No asumir**: aún en camino, foco de Interop. Verificar |

- Preprocesador solo si aporta algo que el CSS nativo no tiene hoy. Sass "porque siempre" es deuda.
- `@supports` es la herramienta de degradación, no un adorno: envuelve lo que esté fuera del target.
- Reserva espacio siempre: `width`/`height` o `aspect-ratio` en imágenes, iframes y anuncios. El
  desplazamiento de contenido es un bug, no una molestia estética.

### Metodologías de CSS y Tailwind: el trade-off, sin bando

Se elige **una** convención por proyecto y se documenta. Las tres son defendibles:

| Opción | Gana | Cuesta |
|---|---|---|
| **CSS Modules** (+ `@layer` + custom properties) | Ámbito local sin runtime, CSS legible, salida pequeña, portable entre frameworks | Requiere disciplina de nomenclatura y un sistema de tokens propio |
| **Tailwind** | Cero decisiones de nombre, escala de diseño impuesta, purga agresiva, onboarding rápido en equipos que ya lo conocen | Markup ruidoso, `@apply` reintroduce el problema que venías a evitar, dependencia de build, v4 sube el suelo de navegador (Safari 16.4+), y salir de él es un refactor completo |
| **CSS-in-JS con runtime** | Estilos derivados de props | **Coste en runtime y penalización con SSR/RSC.** Si se elige, que sea zero-runtime (compilado en build). Es la opción que más ha envejecido |

Criterio: si el equipo ya es productivo con Tailwind, seguir con Tailwind es la respuesta correcta —
cambiar es coste sin beneficio. Para greenfield sin preferencia previa, **CSS nativo + Modules** porque
no ata el proyecto a una herramienta con su propio ciclo de majors. Lo que **sí está vetado** es mezclar
tres metodologías en el mismo repo "según quién tocó el fichero".

### Modelo de carga

- HTML crítico primero: el servidor emite markup útil, no un `<div id=root>` vacío que espera a JS.
  (Cómo se genera ese HTML es de `frontend-frameworks-standards`.)
- Scripts: `<script type="module">` (ya es `defer` implícito). `async` **solo** para scripts
  independientes del DOM y de otros scripts. Scripts bloqueantes en `<head>` = veto.
- `preconnect` a los orígenes críticos de terceros (2-3 como mucho: cada uno abre conexión y compite).
  `preload` solo para el recurso de la ruta crítica que el parser descubre tarde (la fuente, el CSS de
  un chunk). Precargar de más es peor que no precargar: roba ancho de banda al LCP.
- `fetchpriority="high"` en la imagen LCP; `fetchpriority="low"` en lo de debajo del pliegue. Es una
  **pista**, no una orden, y su efecto depende del navegador: úsala con moderación y mide.
- `loading="lazy"` en todo lo que no esté en el primer viewport; **nunca** en la imagen LCP.
- Fuentes: `woff2`, subset al rango de caracteres real, `font-display: swap` (o `optional` si el salto
  tipográfico molesta más que el retardo), `size-adjust`/`ascent-override` para reducir el salto entre la
  fallback y la definitiva. Dos familias como máximo y los pesos que se usen de verdad.
- Code splitting por ruta como default; `import()` dinámico para lo pesado y raro (editor, gráficas,
  mapas). Un chunk compartido enorme es un anti-patrón silencioso.
- Terceros (analítica, chat, tag manager) **fuera de la ruta crítica** y con presupuesto propio: cada
  uno es un tercero que puede caer, ralentizar o exfiltrar. Un tag manager sin gobernanza es una
  puerta de inyección abierta al departamento de marketing.

### JavaScript de plataforma frente a dependencias

Regla: **cada dependencia justifica por qué no basta la plataforma.** Estado a ago-2026:

| API | Estado | Sustituye a |
|---|---|---|
| `fetch` + `AbortController` + `AbortSignal.timeout()` | Widely available | axios y clientes HTTP propios |
| `IntersectionObserver`, `ResizeObserver`, `MutationObserver` | Widely available | Listeners de scroll/resize con debounce |
| `structuredClone` | Widely available | `lodash.cloneDeep`, `JSON.parse(JSON.stringify(...))` |
| `Intl.*` (`NumberFormat`, `DateTimeFormat`, `RelativeTimeFormat`, `Collator`, `Segmenter`) | Widely available | Librerías de formato y localización |
| `URL` / `URLSearchParams` | Widely available | Parseo de query a mano |
| `URLPattern` | **Newly available desde 2025-09** (widely ~2028-03) | `path-to-regexp` en enrutado propio y en service workers |
| Navigation API | **Newly available desde 2026-01** (Firefox 147, Safari 26.2; widely ~2028-07) | History API para SPA. Adopción real aún baja: feature-detect + fallback |
| `Element.setHTML()` / Sanitizer API | **No Baseline**: Firefox 148 (2026-02), Chrome 146; **Safari no** | DOMPurify — *cuando llegue*. Hoy no |
| `Temporal` | **No Baseline**: Chrome 144, Edge 144, Firefox 139; **bloqueado por Safari desde ene-2026**. TC39 Stage 4 (ES2026) | `Date`, date-fns, dayjs. Polyfill: +35-50 KB gz — **decisión de presupuesto, no automática** |
| `View Transitions` cross-document | Chromium y Safari sí; Firefox parcial desde 146 | Solo como mejora progresiva |

- Polyfill **solo** cuando la funcionalidad es esencial y el coste está medido. `Temporal` en una app de
  calendario compensa; en una landing con una fecha formateada, `Intl.DateTimeFormat` ya vale.
- Nada de polyfills globales "por si acaso" ni `core-js` completo: se paga en cada carga y para siempre.

### Dependencias, bundle y monorepo

- Antes de añadir una dependencia: ¿lo hace la plataforma? ¿cuánto pesa **con sus transitivas**?
  ¿está mantenida? ¿qué licencia tiene (**leída del `LICENSE`, no supuesta** — Lightning CSS es MPL-2.0)?
- Presupuesto de bundle **medido en CI** con el tamaño comprimido y fallo si sube más del delta acordado.
  Un análisis de bundle (`rollup-plugin-visualizer` o equivalente) en cada PR que toque dependencias.
- Prohibido importar una librería entera para una función: `import { x } from 'lib'` con tree-shaking real
  o nada. Verifica que el paquete es ESM y declara `sideEffects`.
- Monorepo solo cuando hay **varios artefactos desplegables que comparten código**. Un solo frontend no
  necesita monorepo: necesita carpetas. Si lo hay: workspaces del gestor de paquetes, protocolo
  `workspace:`, caché de tareas (Turborepo/Nx), y **un presupuesto de bundle por app**, no global.
- El gestor de paquetes, el lockfile y las reglas del `package.json` los fija `typescript-standards`.

## 4. Calidad y gates de CI

En orden de coste creciente; cada uno rompe el build:

1. **Formato y lint de CSS/HTML**: Stylelint (o `@eslint/css`) y `html-eslint`.
2. **Gate de Baseline**: `css/require-baseline` / `stylelint-plugin-use-baseline` /
   `eslint-plugin-baseline-js` con `available: "widely"`. Advertencia solo mientras se migra un
   proyecto existente; en greenfield, error.
3. **HTML válido**: validación del markup generado. Un `<div>` dentro de un `<p>` es un bug de render
   en cascada, no una pedantería.
4. **Presupuesto de bundle**: tamaño comprimido por entrypoint contra el límite declarado.
5. **CSP**: comprobar que la política emitida no contiene `unsafe-inline` ni `unsafe-eval` en `script-src`.
6. **SCA y lockfile**: auditoría de dependencias y verificación de que el lockfile no cambió sin PR.
7. **Visual/E2E** contra un despliegue preview (la herramienta la fija `frontend-frameworks-standards`).

Tests que corresponden a esta skill: que la mejora progresiva **degrada bien** (probar con la feature
desactivada, no solo con ella activa), que el CSP no bloquea la app en report-only antes de enforcement,
y que la página funciona **sin JS** en lo que deba funcionar sin JS.

## 5. Seguridad de la plataforma

### Content Security Policy

- CSP con **`nonce` por respuesta** (nonce único, criptográficamente aleatorio, nunca reutilizado) o con
  `hash` para scripts estáticos, más `strict-dynamic`. Una CSP con `'unsafe-inline'` en `script-src`
  **no protege de XSS**: es exactamente el vector que se pretendía cerrar, y su presencia convierte la
  cabecera en decoración de auditoría.
- `object-src 'none'`, `base-uri 'none'`, `frame-ancestors 'none'` (o la lista de orígenes que pueden
  embeber). Desplegar primero en `Content-Security-Policy-Report-Only`, enumerar violaciones, luego
  aplicar. Nunca al revés.
- **Trusted Types**: `require-trusted-types-for 'script'; trusted-types <política>`. Verificado a
  feb-2026 como **Baseline** (Firefox fue el último motor en llegar) — ya no hay excusa de soporte.
  Es la única defensa estructural contra DOM XSS: convierte cada sink en un `TypeError` hasta que pase
  por una política explícita. Report-only primero, igual que la CSP.

### XSS y DOM

- `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`, `new Function` y
  `setTimeout` con string: **PROHIBIDOS con datos que no controlas**. Usa `textContent`, o construye
  nodos, o (cuando el soporte lo permita) `setHTML()`.
- `Element.setHTML()` es preferible a DOMPurify **por construcción** —filtra contra el parser real del
  navegador, así que desaparece la clase de mXSS que nace del doble parseo— pero **no es Baseline a
  ago-2026 (falta Safari)** y ya se le publicaron bypasses en may-2026. Criterio hoy: feature-detect
  (`'setHTML' in Element.prototype`) con **DOMPurify como fallback**, y **sanitización en el servidor
  igualmente**. `setHTMLUnsafe()` requiere justificación escrita.
- URLs: valida el esquema antes de asignar a `href`/`src`/`formaction`. `javascript:` y `data:` desde
  input de usuario son XSS.
- Nada de renderizar HTML recibido de una API "porque es nuestra API": esa API sirve lo que le metieron.

### Cabeceras y aislamiento

- `Strict-Transport-Security` con `max-age` largo y `includeSubDomains`; HTTPS sin excepciones.
- `X-Content-Type-Options: nosniff`.
- **Clickjacking**: `frame-ancestors` en CSP (y `X-Frame-Options: DENY` como respaldo para agentes viejos).
- `Referrer-Policy: strict-origin-when-cross-origin` como mínimo.
- `Permissions-Policy`: denegar explícitamente lo que no se usa (`camera=()`, `microphone=()`,
  `geolocation=()`, `payment=()`, `interest-cohort=()`). Aplica también a los iframes que embebes.
- `Cross-Origin-Opener-Policy: same-origin` y `Cross-Origin-Resource-Policy`; `COEP` solo si necesitas
  aislamiento cruzado (`SharedArrayBuffer`) — rompe embebidos, no se activa por adorno.
- **CORS es del servidor y no es autorización**: `Access-Control-Allow-Origin: *` con credenciales es
  contradictorio y el navegador lo rechaza; reflejar el `Origin` recibido sin allowlist es equivalente
  a no tener CORS. Nunca uses CORS para "proteger" un endpoint: protege el endpoint.
- **Subresource Integrity** (`integrity` + `crossorigin`) obligatorio en todo script o hoja servida
  desde un origen que no controlas. Si el recurso es mutable por el tercero, SRI lo romperá — eso es la
  señal de que no debería estar en tu ruta crítica.

### Sesión y almacenamiento

- Sesión en **cookie `HttpOnly` + `Secure` + `SameSite=Lax`** (o `Strict`; `None` solo con motivo real y
  entonces con protección CSRF explícita). Prefijos `__Host-` cuando aplique.
- **Un token en `localStorage` es una decisión de riesgo**: cualquier XSS lo lee, y sobrevive al cierre
  de pestaña. Si se toma, se escribe por qué, con qué vida útil corta y con qué revocación. No es "lo
  que hace todo el mundo": es aceptar que un XSS equivale a robo de sesión. `sessionStorage` reduce la
  ventana, no el problema. `IndexedDB` idem.
- **En el cliente no hay secretos**: ni claves de API con privilegio, ni feature flags que oculten
  funcionalidad de pago, ni lógica de autorización. Todo lo que llega al navegador es público —
  ver `secrets-management-standards`.
- Si hay datos personales en el cliente, hay retención y borrado; el almacenamiento del navegador no es
  un cajón sin fecha de caducidad.

### Cadena de suministro npm

- Lockfile versionado; CI instala **siempre** con instalación congelada (`--frozen-lockfile`).
- **Scripts de instalación desactivados por defecto** con allowlist explícita: se ejecuta código
  arbitrario con tus privilegios antes de que nadie evalúe el paquete.
- **La procedencia válida no es garantía de seguridad.** Precedente verificado: la campaña Shai-Hulud
  (2025-09 → 2026-05, TeamPCP) publicó paquetes maliciosos con **atestaciones SLSA Build Level 3
  válidas**, usando tokens OIDC de GitHub Actions robados; el caso TanStack de may-2026 (CVE-2026-45321,
  CVSS 9.6) ocurrió con trusted publishing, provenance firmada y 2FA en todas las cuentas. `npm audit
  signatures` responde "quién construyó esto", no "esto es benigno".
- Consecuencias operativas: mínimo de dependencias directas, pinning por versión exacta o lockfile
  estricto, actualizaciones agrupadas y revisadas (Renovate), CI aislada y con privilegio mínimo, y
  ante advisory, tratar como comprometida **toda máquina que instaló** la versión afectada.
- Auditar dependencias nuevas: cuentas de mantenedor, actividad, transitivas, typosquatting.

## 6. Rendimiento y operabilidad del cliente

- Medir **en campo**, no solo en laboratorio: la métrica que decide es la de usuarios reales. La
  plataforma de RUM la fija `observability-standards`; los umbrales, `web-performance-standards`. Aquí:
  qué instrumentar — navegación, recursos críticos, errores de JS no capturados, violaciones de CSP
  (`report-to`), fallos de carga de chunks.
- **Errores de carga de chunk** tras un despliegue son un fallo operativo real, no ruido: los assets
  antiguos deben seguir sirviéndose durante la ventana de transición.
- Assets con hash en el nombre → cacheables como inmutables. HTML → nunca. La política concreta es de
  `caching-cdn-standards`.
- Source maps: subidos al sistema de errores, **no servidos públicamente**.
- Degradación: la app debe sobrevivir a que un tercero no responda. Un `<script>` bloqueante de un
  tercero caído es una página en blanco.
- Un *feature flag* de cliente es sugerencia, no control de acceso.

## 7. Sostenibilidad y prohibiciones

- Revisar la política de soporte **cada 6-12 meses** con datos de analítica y mover el target: dejarla
  congelada tres años es la vía silenciosa a una base de código llena de polyfills inútiles.
- Cuando una feature entre en Widely available, **retirar su polyfill y su fallback**. Nadie lo hace y
  por eso los bundles solo crecen. Cada polyfill lleva la condición de retirada escrita al lado.
- Majors de Vite/Rolldown/Tailwind: leer el changelog y usar el codemod oficial si existe. Actualizar
  `browserslist-config-baseline`/`caniuse-lite` con cadencia, no cuando algo falla.
- Dependencia sin mantenimiento >18 meses: se revisa o se reemplaza.

**PROHIBIDO:**
- ❌ CSP con `'unsafe-inline'` o `'unsafe-eval'` en `script-src` — invalida la protección; equivale a no
  tener CSP y encima aparenta cumplimiento.
- ❌ `innerHTML` / `outerHTML` / `insertAdjacentHTML` / `document.write` con datos de usuario o de
  cualquier API. `eval`, `new Function`, `setTimeout("string")`: prohibidos sin excepción.
- ❌ Tokens de sesión o de acceso en `localStorage` sin decisión de riesgo escrita y firmada.
- ❌ Secretos, claves privilegiadas o lógica de autorización en el bundle del cliente.
- ❌ Script de un tercero sin `integrity`+`crossorigin`, o servido desde un origen mutable en la ruta crítica.
- ❌ CORS permisivo (`*` con credenciales, reflejo del `Origin` sin allowlist) o usado como control de acceso.
- ❌ `<div onclick>` como botón; `role`+`tabindex` a mano para recrear semántica que ya existe.
- ❌ Imágenes, iframes o anuncios sin dimensiones o `aspect-ratio` reservados.
- ❌ `loading="lazy"` en la imagen LCP; `preload` de todo "por si acaso".
- ❌ Fuentes servidas desde un CDN de terceros en la ruta crítica; más de dos familias tipográficas.
- ❌ "Soportamos navegadores modernos" como política; target de navegadores sin fichero ni analítica.
- ❌ Usar una feature fuera del target sin `@supports` / feature detection, o con un fallback que rompe.
- ❌ Añadir una dependencia que duplica algo que la plataforma ya hace (`fetch`, `structuredClone`, `Intl`,
  `URLPattern`, observadores).
- ❌ CI sin lockfile congelado; scripts de instalación habilitados sin allowlist; confiar en la
  atestación de procedencia como prueba de que un paquete es seguro.
- ❌ Mezclar tres metodologías de CSS en el mismo repo; `!important` para ganar especificidad habiendo `@layer`.
- ❌ Copiar de memoria (o de un blog) el estado de soporte de una feature. Se comprueba (§8).

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (WebSearch/WebFetch; `webstatus.dev`, MDN, `web-features`,
changelogs oficiales; feeds Atom de GitHub para versiones — `api.github.com` da 403 sin autenticar):

1. **Estado Baseline de cada feature que uses**, una por una, en `webstatus.dev`/MDN. La tabla de §3
   caduca por diseño. Comprobar en particular si ya cambiaron: `Temporal` (¿Safari ya lo envía?),
   Sanitizer API / `setHTML()` (¿Safari?), view transitions cross-document en Firefox (parcial en 146),
   `light-dark()`, `oklch()`, anchor positioning, scroll-driven animations, masonry.
2. **Foco de Interop 2026** y su dashboard: qué está a punto de volverse interoperable (view transitions
   cross-document, CSS scroll snap, `shape()`, `attr()` extendido, `:open`, `popover="hint"`,
   WebTransport, ESM module loading). Lo de la lista de este año suele ser Baseline el siguiente.
3. **Versiones**: Vite (¿sigue 8.2.x? ¿hay 9?), Rolldown, esbuild (**su 0.x rompe en minors**),
   Lightning CSS, Tailwind, y la versión de `browserslist-config-baseline` / `caniuse-lite`.
4. **Licencias leídas del `LICENSE` en crudo**, no supuestas. Verificado a ago-2026: Vite MIT,
   Rolldown MIT, esbuild MIT, Tailwind MIT, **Lightning CSS MPL-2.0**.
5. **Advisories y cadena de suministro**: `github.com/advisories`, osv.dev y las oleadas Shai-Hulud
   (¿hay generación posterior a "Mini Shai-Hulud"?) antes de actualizar dependencias en masa.
6. **Cabeceras de seguridad**: estado de soporte de Trusted Types (Baseline desde feb-2026 — reconfirmar),
   directivas CSP nuevas o deprecadas, y estado de `Permissions-Policy` (su lista de features cambia).
7. **Datos de tu audiencia**: la analítica propia manda sobre cualquier estadística global al elegir
   el target de navegadores.

**Huecos no verificados a ago-2026** (no rellenar de memoria; comprobar antes de usar):
- Estado exacto de `light-dark()` y `oklch()` en Baseline: **no verificado**.
- Estado de anchor positioning, scroll-driven animations y CSS masonry: **no verificado** más allá de
  ser objetivos declarados de Interop.
- Soporte de `speculationrules` (prerender/prefetch declarativo) fuera de Chromium: **no verificado**.
- Cifras exactas del presupuesto de bundle de §2: son un punto de partida, **no un dato medido**; se
  fijan con la audiencia real del proyecto.
- Versión vigente de `browserslist-config-baseline` y de los plugins de lint de Baseline
  (`eslint-plugin-baseline-js` **aún no tiene major**, su API puede cambiar): **no verificado**.

**Discrepancia declarada**: sobre view transitions cross-document, varias fuentes secundarias siguen
afirmando que "Firefox y Safari no lo soportan"; los datos de compatibilidad indican que **Safari sí**
(desde 18.4 iOS / 18.5 desktop) y que **Firefox lo soporta parcialmente desde 146**. Confirmar en MDN
antes de decidir. Del mismo modo, `content-security-policy.com` y la documentación de `django-csp`
seguían listando Trusted Types como no soportado en Firefox y Safari después de que alcanzara Baseline
en feb-2026: **manda MDN/Baseline**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
