---
name: frontend-web-platform-standards
description: Use when deciding what the browser itself must do - .html, .css, .browserslistrc, browserslist in package.json, browserslist-config-baseline, Baseline widely/newly available targets, stylelint-plugin-use-baseline or @eslint/css require-baseline, container queries, :has(), @layer, subgrid, @property, color-mix(), native CSS nesting, view transitions, Tailwind vs CSS Modules vs plain CSS, vite.config.ts, Vite 8, Rolldown, esbuild, Turbopack, Lightning CSS, postcss.config, bundle-size budgets and import-cost review, script type=module, defer/async, preload/preconnect/fetchpriority, font-display and subsetting, srcset/picture/AVIF/loading=lazy, fetch/AbortController/IntersectionObserver/URLPattern/structuredClone/Temporal polyfill decisions, Content-Security-Policy nonce and hash, Trusted Types, setHTML and the Sanitizer API, innerHTML sinks, SameSite cookies, CORS, Permissions-Policy, Subresource Integrity, X-Frame-Options/frame-ancestors, localStorage token storage, or npm lockfile and install-script supply-chain hardening.
---

# Web platform (frontend) standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Sets the criteria on **what the browser does**: which HTML, CSS and platform API features can be used
and under which support policy, how the page loads, what budget the bundle has, which tool builds it
and which client-side security controls are mandatory.

**Axis**: the platform before the framework. Before adding a dependency, the question is whether the
browser already does it and since when it does it in **every** targeted browser.

Triggers: `.html`, `.css`, `.browserslistrc`, `browserslist` in `package.json`, `vite.config.ts`,
`postcss.config.*`, `lightningcss` config, `Content-Security-Policy` / `Permissions-Policy` /
`Cross-Origin-*` headers, `<link rel=preload|preconnect>`, `srcset`/`<picture>`, `@font-face`, `@layer`,
`@container`, `innerHTML`, `localStorage`, `package-lock.json`/`pnpm-lock.yaml` seen as attack
surface.

**Arbitration rule with `frontend-frameworks-standards`**: if the answer **would change when the
framework changes**, it belongs to `frontend-frameworks-standards`; if it **would still hold with any
of them** (or with none), it belongs here. `fetchpriority` on the LCP image is here; whether that image
is emitted by `next/image` or Astro's `<Image>` is a detail over there.

**Not applicable**:
- `frontend-frameworks-standards` — **decides which framework is chosen, with which rendering model
  (CSR/SSR/SSG/ISR/islands/RSC) and how the application is structured**: routing, data loading, server
  vs. client state, hydration, error boundaries, component tests. Here no framework is recommended or
  vetoed; here we set what the browser must deliver **whichever one** is chosen.
- `typescript-standards` — **the TS/JS language, `tsconfig.json`, typing, linting with Biome/ESLint and
  packaging for npm publication are theirs**. Here the bundle as a *budget of bytes served* and the
  build as a tool, not the language rules nor the compiler config.
- `accessibility-standards` — WCAG 2.2, ARIA, keyboard navigation, assistive
  technology and the audit are theirs. Here only semantic HTML as a structural basis: choosing the
  right element is a platform decision, **requiring it as conformance is theirs**.
- `web-performance-standards` — Core Web Vitals, performance budgets and their
  measurement are theirs. Here the loading decisions (order, priority, format) that determine them.
- `design-systems-standards` (**the component's public contract and the governance of the
  system as a versioned product**: tokens, props API, breaking-change policy,
  documentation and adoption. Here the CSS and the browser APIs it is implemented with),
  `cms-jamstack-standards` (**where the content lives, who edits it and how it is
  published**: modelling, preview, and cache invalidation on publish),
  `pwa-standards` (service worker, manifest, offline), `webgl-webgpu-standards`,
  `streaming-multimedia-standards` (**the video/audio pipeline is theirs** —ingest,
  transcoding, HLS/DASH packaging, DRM—; **here `<video>`, Media Source Extensions and EME
  as web platform APIs** that consume what that pipeline delivers),
  `i18n-standards` (**here the CSS logical properties and
  the decision to polyfill `Intl`/`Temporal`**; **there what gets formatted and under which rules**:
  message catalogues, ICU MessageFormat, CLDR plural categories, collation, Unicode
  normalisation and time zones. Useful rule: if the problem is *which side the margin falls on in RTL*,
  it is here; if it is *how Polish pluralises*, it is theirs).
- `caching-cdn-standards` — **the HTTP cache, the CDN, `Cache-Control`, `Vary` and purging are theirs**.
  Here only which headers the application itself emits and why (hashed assets = immutable; HTML = not).
- `api-design-standards` (the contract the frontend consumes), `appsec-standards` (methodology,
  threat modelling and triage; here the concrete browser controls),
  `secrets-management-standards` (**a secret does not live on the client**: if it has to be stored, the
  design is wrong — the custody criteria are theirs), `identity-access-management-standards` (OIDC flows),
  `observability-standards` (RUM and telemetry platform; here only what to instrument on the client),
  `cicd-standards` (the pipeline that runs the §4 gates), `webassembly-standards` (**already written**:
  the Wasm module and its runtime), `mobile-standards` (native app), `dart-standards` (Flutter web).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Status as of Aug 2026 | Why |
|---|---|---|---|
| Support policy | **Baseline Widely available** as the default target | `baseline widely available` = supported in Chrome, Edge, Firefox and Safari for **30 months** | It is the only definition of "modern browser" that is not an opinion. Measurable and auditable |
| Expressing the policy | **Browserslist** with `extends browserslist-config-baseline` or the `baseline widely available` query | `baseline widely available` / `baseline newly available` / `baseline <year>` queries supported natively | A single source that feeds build, autoprefixer and linters |
| Target reproducibility | Freeze to `baseline widely available on YYYY-MM-DD` in the build | `baseline-browser-mapping` recommendation | "Widely" is a moving target: with no fixed date, two builds of the same commit do not produce the same output |
| Feature gate | `@eslint/css` rule `css/require-baseline` **or** `stylelint-plugin-use-baseline`; `html-eslint` rule `use-baseline`; `eslint-plugin-baseline-js` for JS | All with the same knob (`widely` / `newly` / year) | Turns the policy into a CI failure, not a habit |
| Bundler / dev server | **Vite** | **8.2.0** (8.0 stable 2026-03-12; **Rolldown** is already the sole bundler, esbuild and Rollup disappear from the pipeline) | A single dev/prod bundler: the "works in dev, breaks in build" class of bug is over |
| Low-level bundler | **Rolldown** | **1.2.2** (1.0 stable 2026-05-07, `^1.0.0` API under semver) | Only if you are building tooling; in apps it is consumed via Vite |
| One-off transpiler | **esbuild** | **0.28.1** | Still alive and correct for isolated tasks. **Its 0.x breaks on minors**: pin the exact version |
| Next.js bundler | **Turbopack** | Dev and build default since Next 16 | Not a choice: it comes with the framework (→ `frontend-frameworks-standards`) |
| CSS transformation | **Lightning CSS** (built into Vite) or PostCSS if you need specific plugins | Lightning CSS **1.33.0**, **MPL-2.0** licence (not MIT) | Takes the target from Browserslist and downgrades automatically (`oklch()`, `light-dark()`, prefixes) |
| Styles | **Native CSS + CSS Modules** by default; **Tailwind** if the team already masters it | Tailwind **4.3.3**, MIT; v4 requires Safari 16.4+/Chrome 111+/Firefox 128+ | See the trade-off written out in §3 |
| Fonts | Self-hosting with subsetted `woff2` + `font-display: swap` | — | A `<link>` to a font CDN is a third party in the critical path and one more domain to connect to |
| Images | `<picture>` AVIF → WebP → JPEG, always with `width`/`height` | AVIF Baseline since 2024 (~94-95% global); WebP ~97% | AVIF saves ~30% over WebP. **JPEG XL is not an option**: ~15% support |

**Bundle budget** (a starting point, adjusted with real audience data and **declared in
the repo**): ≤ **150 KB** of compressed JS on the initial route and ≤ **50 KB** of CSS. Exceeding it is not
forbidden: what is forbidden is exceeding it **without CI saying so and without someone approving it**.

## 3. Structure and conventions

### Browser support policy

- The policy **is written down**, not assumed: a versioned `.browserslistrc` plus a line in the README
  with the reason. "Modern browsers" is not a policy.
- **Widely available** is the default. **Newly available** only with an explicit decision and awareness that
  it includes versions released weeks ago; in a mass-market product, almost never.
- Choose the target **with your own analytics**, not with global statistics: an intranet and a public
  shop do not have the same browser tail.
- A feature outside the target is not forbidden: it is used **as progressive enhancement** inside
  `@supports` (CSS) or behind `if ('x' in y)` (JS), so that its absence degrades the experience and does not
  break it. If its absence breaks functionality, it is not progressive enhancement: it is a policy failure.
- Tools that already expose Baseline and are worth using: CSS hover cards in Chrome DevTools (since
  Chrome 140), `webstatus.dev` and its API (`baseline_status:newly AND group:css`), the
  `web-features` package, the `<baseline-status>` component. **Verify the status per feature, not by rumour.**

### HTML

- The right element before the `div` with a role: `<button>`, `<a href>`, `<nav>`, `<main>`, `<dialog>`,
  `<details>`, `<form>`, `<label for>`, headings in order. A `<div onclick>` is not a button —
  it loses focus, keyboard, semantics, and the `role`/`tabindex` you have to add by hand is already the signal.
- A single `<h1>` per document and a hierarchy without skips; real landmarks.
- Forms: correct `name`, `autocomplete` and `type` (`email`, `tel`, `url`, `search`) — the mobile
  keyboard, autofill and the password manager depend on them.
- Native validation (`required`, `pattern`, `min`/`max`) as the first layer; **never as the only one**: the
  real validation is the server's.
- A unique `<title>` per page, `<meta name=description>`, Open Graph, canonical, `lang` on `<html>`. It is
  SEO and accessibility at the same time; it costs nothing and is always forgotten.
- JSON-LD structured data if the content justifies it (product, article, event).

### Modern CSS: what replaces what

> Status as of Aug 2026 according to Baseline. **Re-verify per feature on `webstatus.dev`/MDN (§8)**: this table
> expires on its own.

| Use | Instead of | Status |
|---|---|---|
| `@container` + `cq*` units | Media queries for reusable components | Widely available |
| `:has()` | State classes set by JS on the parent | Widely available |
| `@layer` | Specificity war, `!important`, `#id` to "win" | Widely available |
| `subgrid` | Duplicated grids or manual alignment with `calc()` | Widely available |
| Custom properties + `@property` | Preprocessor variables for theme tokens | Widely available |
| `color-mix()`, `light-dark()`, `oklch()` | Sass colour functions, double palettes | `color-mix()` widely; **verify `light-dark()`/`oklch()`** |
| Native nesting | Sass nesting as the only reason to have Sass | Widely available |
| View transitions | Page-transition animation libraries | Same-document widely; **cross-document: Chromium and Safari yes; Firefox only partial since 146 → progressive enhancement mandatory** |
| Anchor positioning, scroll-driven animations, masonry | Positioning with JS | **Do not assume**: still on the way, an Interop focus. Verify |

- A preprocessor only if it brings something native CSS does not have today. Sass "because we always have" is debt.
- `@supports` is the degradation tool, not an ornament: wrap anything outside the target in it.
- Always reserve space: `width`/`height` or `aspect-ratio` on images, iframes and ads. Content
  shifting is a bug, not an aesthetic annoyance.

### CSS methodologies and Tailwind: the trade-off, without taking sides

**One** convention is chosen per project and documented. All three are defensible:

| Option | Wins | Costs |
|---|---|---|
| **CSS Modules** (+ `@layer` + custom properties) | Local scope with no runtime, readable CSS, small output, portable across frameworks | Requires naming discipline and a token system of your own |
| **Tailwind** | Zero naming decisions, an imposed design scale, aggressive purging, fast onboarding in teams that already know it | Noisy markup, `@apply` reintroduces the very problem you came to avoid, build dependency, v4 raises the browser floor (Safari 16.4+), and leaving it is a complete refactor |
| **CSS-in-JS with runtime** | Styles derived from props | **Runtime cost and an SSR/RSC penalty.** If chosen, make it zero-runtime (compiled at build time). It is the option that has aged worst |

Criteria: if the team is already productive with Tailwind, staying with Tailwind is the right answer —
changing is cost without benefit. For greenfield with no prior preference, **native CSS + Modules** because
it does not tie the project to a tool with its own major cycle. What **is vetoed** is mixing
three methodologies in the same repo "depending on who touched the file".

### Loading model

- Critical HTML first: the server emits useful markup, not an empty `<div id=root>` waiting on JS.
  (How that HTML is generated belongs to `frontend-frameworks-standards`.)
- Scripts: `<script type="module">` (already implicitly `defer`). `async` **only** for scripts
  independent of the DOM and of other scripts. Blocking scripts in `<head>` = veto.
- `preconnect` to the critical third-party origins (2-3 at most: each one opens a connection and competes).
  `preload` only for the critical-path resource the parser discovers late (the font, the CSS of
  a chunk). Preloading too much is worse than not preloading: it steals bandwidth from the LCP.
- `fetchpriority="high"` on the LCP image; `fetchpriority="low"` on what is below the fold. It is a
  **hint**, not an order, and its effect depends on the browser: use it sparingly and measure.
- `loading="lazy"` on everything not in the first viewport; **never** on the LCP image.
- Fonts: `woff2`, subset to the real character range, `font-display: swap` (or `optional` if the
  typographic shift is more annoying than the delay), `size-adjust`/`ascent-override` to reduce the jump between the
  fallback and the final one. Two families at most and only the weights actually used.
- Code splitting per route as the default; dynamic `import()` for the heavy and rare (editor, charts,
  maps). One huge shared chunk is a silent anti-pattern.
- Third parties (analytics, chat, tag manager) **out of the critical path** and with their own budget: each
  one is a third party that can go down, slow you down or exfiltrate. A tag manager without governance is an
  injection door left open to the marketing department.

### Platform JavaScript versus dependencies

Rule: **every dependency justifies why the platform is not enough.** Status as of Aug 2026:

| API | Status | Replaces |
|---|---|---|
| `fetch` + `AbortController` + `AbortSignal.timeout()` | Widely available | axios and homegrown HTTP clients |
| `IntersectionObserver`, `ResizeObserver`, `MutationObserver` | Widely available | Debounced scroll/resize listeners |
| `structuredClone` | Widely available | `lodash.cloneDeep`, `JSON.parse(JSON.stringify(...))` |
| `Intl.*` (`NumberFormat`, `DateTimeFormat`, `RelativeTimeFormat`, `Collator`, `Segmenter`) | Widely available | Formatting and localisation libraries |
| `URL` / `URLSearchParams` | Widely available | Parsing the query by hand |
| `URLPattern` | **Newly available since 2025-09** (widely ~2028-03) | `path-to-regexp` in homegrown routing and in service workers |
| Navigation API | **Newly available since 2026-01** (Firefox 147, Safari 26.2; widely ~2028-07) | History API for SPAs. Real adoption still low: feature-detect + fallback |
| `Element.setHTML()` / Sanitizer API | **Not Baseline**: Firefox 148 (2026-02), Chrome 146; **Safari no** | DOMPurify — *when it arrives*. Not today |
| `Temporal` | **Not Baseline**: Chrome 144, Edge 144, Firefox 139; **blocked by Safari since Jan 2026**. TC39 Stage 4 (ES2026) | `Date`, date-fns, dayjs. Polyfill: +35-50 KB gz — **a budget decision, not an automatic one** |
| `View Transitions` cross-document | Chromium and Safari yes; Firefox partial since 146 | Only as progressive enhancement |

- Polyfill **only** when the functionality is essential and the cost has been measured. `Temporal` in a
  calendar app pays off; on a landing page with one formatted date, `Intl.DateTimeFormat` is already enough.
- No global polyfills "just in case" and no full `core-js`: it is paid on every load and forever.

### Dependencies, bundle and monorepo

- Before adding a dependency: does the platform do it? how much does it weigh **with its transitives**?
  is it maintained? what licence does it have (**read from the `LICENSE`, not assumed** — Lightning CSS is MPL-2.0)?
- Bundle budget **measured in CI** with the compressed size and failing if it grows beyond the agreed delta.
  A bundle analysis (`rollup-plugin-visualizer` or equivalent) on every PR that touches dependencies.
- Importing an entire library for one function is forbidden: `import { x } from 'lib'` with real tree-shaking
  or nothing. Verify that the package is ESM and declares `sideEffects`.
- Monorepo only when there are **several deployable artifacts sharing code**. A single frontend does not
  need a monorepo: it needs folders. If there is one: package manager workspaces, the
  `workspace:` protocol, task caching (Turborepo/Nx), and **one bundle budget per app**, not a global one.
- The package manager, the lockfile and the `package.json` rules are set by `typescript-standards`.

## 4. Quality and CI gates

In increasing order of cost; each one breaks the build:

1. **CSS/HTML formatting and linting**: Stylelint (or `@eslint/css`) and `html-eslint`.
2. **Baseline gate**: `css/require-baseline` / `stylelint-plugin-use-baseline` /
   `eslint-plugin-baseline-js` with `available: "widely"`. Warning only while migrating an
   existing project; in greenfield, error.
3. **Valid HTML**: validation of the generated markup. A `<div>` inside a `<p>` is a cascading render
   bug, not pedantry.
4. **Bundle budget**: compressed size per entrypoint against the declared limit.
5. **CSP**: check that the emitted policy contains no `unsafe-inline` or `unsafe-eval` in `script-src`.
6. **SCA and lockfile**: dependency audit and verification that the lockfile did not change without a PR.
7. **Visual/E2E** against a preview deployment (the tool is set by `frontend-frameworks-standards`).

Tests that belong to this skill: that progressive enhancement **degrades well** (test with the feature
disabled, not only with it enabled), that the CSP does not block the app in report-only before enforcement,
and that the page works **without JS** in whatever must work without JS.

## 5. Platform security

### Content Security Policy

- CSP with a **`nonce` per response** (a unique, cryptographically random nonce, never reused) or with a
  `hash` for static scripts, plus `strict-dynamic`. A CSP with `'unsafe-inline'` in `script-src`
  **does not protect against XSS**: it is exactly the vector it was meant to close, and its presence turns the
  header into audit decoration.
- `object-src 'none'`, `base-uri 'none'`, `frame-ancestors 'none'` (or the list of origins allowed to
  embed). Deploy first in `Content-Security-Policy-Report-Only`, enumerate violations, then
  enforce. Never the other way round.
- **Trusted Types**: `require-trusted-types-for 'script'; trusted-types <policy>`. Verified as of
  Feb 2026 as **Baseline** (Firefox was the last engine to arrive) — there is no longer a support excuse.
  It is the only structural defence against DOM XSS: it turns every sink into a `TypeError` until it goes
  through an explicit policy. Report-only first, just like the CSP.

### XSS and DOM

- `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`, `new Function` and
  `setTimeout` with a string: **FORBIDDEN with data you do not control**. Use `textContent`, or build
  nodes, or (when support allows) `setHTML()`.
- `Element.setHTML()` is preferable to DOMPurify **by construction** —it filters against the browser's real
  parser, so the class of mXSS born from double parsing disappears— but **it is not Baseline as of
  Aug 2026 (Safari missing)** and bypasses were already published for it in May 2026. Criteria today: feature-detect
  (`'setHTML' in Element.prototype`) with **DOMPurify as fallback**, and **server-side sanitisation
  regardless**. `setHTMLUnsafe()` requires written justification.
- URLs: validate the scheme before assigning to `href`/`src`/`formaction`. `javascript:` and `data:` from
  user input are XSS.
- No rendering HTML received from an API "because it is our API": that API serves whatever was put into it.

### Headers and isolation

- `Strict-Transport-Security` with a long `max-age` and `includeSubDomains`; HTTPS with no exceptions.
- `X-Content-Type-Options: nosniff`.
- **Clickjacking**: `frame-ancestors` in the CSP (and `X-Frame-Options: DENY` as a backstop for old agents).
- `Referrer-Policy: strict-origin-when-cross-origin` as a minimum.
- `Permissions-Policy`: explicitly deny what is not used (`camera=()`, `microphone=()`,
  `geolocation=()`, `payment=()`, `interest-cohort=()`). It also applies to the iframes you embed.
- `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Resource-Policy`; `COEP` only if you need
  cross-origin isolation (`SharedArrayBuffer`) — it breaks embeds, it is not enabled for decoration.
- **CORS belongs to the server and is not authorisation**: `Access-Control-Allow-Origin: *` with credentials is
  contradictory and the browser rejects it; reflecting the received `Origin` without an allowlist is equivalent
  to having no CORS. Never use CORS to "protect" an endpoint: protect the endpoint.
- **Subresource Integrity** (`integrity` + `crossorigin`) mandatory on every script or stylesheet served
  from an origin you do not control. If the resource is mutable by the third party, SRI will break — that is the
  signal that it should not be in your critical path.

### Session and storage

- Session in an **`HttpOnly` + `Secure` + `SameSite=Lax` cookie** (or `Strict`; `None` only with a real reason and
  then with explicit CSRF protection). `__Host-` prefixes where applicable.
- **A token in `localStorage` is a risk decision**: any XSS reads it, and it survives closing the
  tab. If taken, write down why, with what short lifetime and with what revocation. It is not "what
  everybody does": it is accepting that an XSS equals session theft. `sessionStorage` reduces the
  window, not the problem. `IndexedDB` likewise.
- **There are no secrets on the client**: no privileged API keys, no feature flags hiding
  paid functionality, no authorisation logic. Everything that reaches the browser is public —
  see `secrets-management-standards`.
- If there is personal data on the client, there is retention and deletion; browser storage is not
  a drawer with no expiry date.

### npm supply chain

- Versioned lockfile; CI **always** installs with a frozen install (`--frozen-lockfile`).
- **Install scripts disabled by default** with an explicit allowlist: arbitrary code runs
  with your privileges before anyone has evaluated the package.
- **Valid provenance is no guarantee of security.** Verified precedent: the Shai-Hulud campaign
  (2025-09 → 2026-05, TeamPCP) published malicious packages with **valid SLSA Build Level 3
  attestations**, using stolen GitHub Actions OIDC tokens; the TanStack case of May 2026 (CVE-2026-45321,
  CVSS 9.6) happened with trusted publishing, signed provenance and 2FA on every account. `npm audit
  signatures` answers "who built this", not "this is benign".
- Operational consequences: a minimum of direct dependencies, pinning by exact version or a strict
  lockfile, grouped and reviewed updates (Renovate), isolated CI with least privilege, and
  on an advisory, treat as compromised **every machine that installed** the affected version.
- Audit new dependencies: maintainer accounts, activity, transitives, typosquatting.

## 6. Client performance and operability

- Measure **in the field**, not only in the lab: the metric that decides is the one from real users. The
  RUM platform is set by `observability-standards`; the thresholds, by `web-performance-standards`. Here:
  what to instrument — navigation, critical resources, uncaught JS errors, CSP violations
  (`report-to`), chunk loading failures.
- **Chunk loading errors** after a deployment are a real operational failure, not noise: the old
  assets must keep being served during the transition window.
- Assets with a hash in the name → cacheable as immutable. HTML → never. The concrete policy belongs to
  `caching-cdn-standards`.
- Source maps: uploaded to the error system, **not served publicly**.
- Degradation: the app must survive a third party not responding. A blocking `<script>` from a
  third party that is down is a blank page.
- A client-side *feature flag* is a suggestion, not access control.

## 7. Sustainability and prohibitions

- Review the support policy **every 6-12 months** with analytics data and move the target: leaving it
  frozen for three years is the silent path to a codebase full of useless polyfills.
- When a feature reaches Widely available, **retire its polyfill and its fallback**. Nobody does it and
  that is why bundles only grow. Every polyfill carries its retirement condition written next to it.
- Vite/Rolldown/Tailwind majors: read the changelog and use the official codemod if there is one. Update
  `browserslist-config-baseline`/`caniuse-lite` on a cadence, not when something breaks.
- Dependency unmaintained for >18 months: it is reviewed or replaced.

**FORBIDDEN:**
- ❌ CSP with `'unsafe-inline'` or `'unsafe-eval'` in `script-src` — it invalidates the protection; it is equivalent to having
  no CSP and on top of that it feigns compliance.
- ❌ `innerHTML` / `outerHTML` / `insertAdjacentHTML` / `document.write` with user data or data from
  any API. `eval`, `new Function`, `setTimeout("string")`: forbidden without exception.
- ❌ Session or access tokens in `localStorage` without a written and signed risk decision.
- ❌ Secrets, privileged keys or authorisation logic in the client bundle.
- ❌ A third-party script without `integrity`+`crossorigin`, or served from a mutable origin in the critical path.
- ❌ Permissive CORS (`*` with credentials, reflecting the `Origin` without an allowlist) or used as access control.
- ❌ `<div onclick>` as a button; `role`+`tabindex` by hand to recreate semantics that already exist.
- ❌ Images, iframes or ads without reserved dimensions or `aspect-ratio`.
- ❌ `loading="lazy"` on the LCP image; `preload` of everything "just in case".
- ❌ Fonts served from a third-party CDN in the critical path; more than two typographic families.
- ❌ "We support modern browsers" as a policy; a browser target with no file and no analytics.
- ❌ Using a feature outside the target without `@supports` / feature detection, or with a fallback that breaks.
- ❌ Adding a dependency that duplicates something the platform already does (`fetch`, `structuredClone`, `Intl`,
  `URLPattern`, observers).
- ❌ CI without a frozen lockfile; install scripts enabled without an allowlist; trusting the
  provenance attestation as proof that a package is safe.
- ❌ Mixing three CSS methodologies in the same repo; `!important` to win specificity when `@layer` exists.
- ❌ Copying a feature's support status from memory (or from a blog). It is checked (§8).

## 8. Mandatory web verification

Before pinning anything, check online (WebSearch/WebFetch; `webstatus.dev`, MDN, `web-features`,
official changelogs; GitHub Atom feeds for versions — `api.github.com` returns 403 unauthenticated):

1. **Baseline status of every feature you use**, one by one, on `webstatus.dev`/MDN. The §3 table
   expires by design. Check in particular whether these have already changed: `Temporal` (does Safari ship it yet?),
   Sanitizer API / `setHTML()` (Safari?), cross-document view transitions in Firefox (partial in 146),
   `light-dark()`, `oklch()`, anchor positioning, scroll-driven animations, masonry.
2. **Interop 2026 focus** and its dashboard: what is about to become interoperable (cross-document view
   transitions, CSS scroll snap, `shape()`, extended `attr()`, `:open`, `popover="hint"`,
   WebTransport, ESM module loading). This year's list is usually Baseline the next one.
3. **Versions**: Vite (is it still 8.2.x? is there a 9?), Rolldown, esbuild (**its 0.x breaks on minors**),
   Lightning CSS, Tailwind, and the version of `browserslist-config-baseline` / `caniuse-lite`.
4. **Licences read from the raw `LICENSE`**, not assumed. Verified as of Aug 2026: Vite MIT,
   Rolldown MIT, esbuild MIT, Tailwind MIT, **Lightning CSS MPL-2.0**.
5. **Advisories and supply chain**: `github.com/advisories`, osv.dev and the Shai-Hulud waves
   (is there a generation after "Mini Shai-Hulud"?) before updating dependencies en masse.
6. **Security headers**: Trusted Types support status (Baseline since Feb 2026 — reconfirm),
   new or deprecated CSP directives, and the status of `Permissions-Policy` (its feature list changes).
7. **Your audience's data**: your own analytics beats any global statistic when choosing
   the browser target.

**Unverified gaps as of Aug 2026** (do not fill them from memory; check before using):
- Exact Baseline status of `light-dark()` and `oklch()`: **not verified**.
- Status of anchor positioning, scroll-driven animations and CSS masonry: **not verified** beyond
  being declared Interop targets.
- `speculationrules` (declarative prerender/prefetch) support outside Chromium: **not verified**.
- Exact figures for the §2 bundle budget: they are a starting point, **not a measured datum**; they are
  set with the project's real audience.
- Current version of `browserslist-config-baseline` and of the Baseline lint plugins
  (`eslint-plugin-baseline-js` **still has no major**, its API may change): **not verified**.

**Declared discrepancy**: on cross-document view transitions, several secondary sources still
claim that "Firefox and Safari do not support it"; the compatibility data indicate that **Safari does**
(since 18.4 iOS / 18.5 desktop) and that **Firefox supports it partially since 146**. Confirm on MDN
before deciding. Likewise, `content-security-policy.com` and the `django-csp` documentation
kept listing Trusted Types as unsupported in Firefox and Safari after it reached Baseline
in Feb 2026: **MDN/Baseline wins**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
