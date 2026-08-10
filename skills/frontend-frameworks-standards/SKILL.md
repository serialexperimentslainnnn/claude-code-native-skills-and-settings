---
name: frontend-frameworks-standards
description: Use when choosing or structuring a frontend framework application - deciding whether a framework is needed at all, picking a rendering model (CSR, SSR, SSG, ISR, streaming, islands, React Server Components), comparing React, Vue, Svelte, Angular, Solid, Qwik and Astro, choosing a meta-framework (next.config.ts, nuxt.config.ts, svelte.config.js, astro.config.mjs, angular.json, app.config.ts, TanStack Start, React Router framework mode, Remix), routing and data loading, loaders and server functions, server-vs-client state and TanStack Query cache invalidation, form handling and shared client/server validation, hydration cost and partial hydration, error boundaries and loading/suspense states, component testing with Vitest and Testing Library, Playwright end-to-end flows, or judging framework longevity, governance and migration risk before committing.
---

# Frontend frameworks standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Sets the criteria for **choosing and using** a framework: whether one is needed, which one, with which
rendering model, how the application is structured (routes, data loading, state, forms, errors) and
how it is tested. **It teaches no framework**: it decides between them and puts limits on their use.

Triggers: `next.config.ts`, `nuxt.config.ts`, `svelte.config.js`, `astro.config.mjs`, `angular.json`,
`app.config.ts`, `vite.config.ts` with a framework plugin, route files (`app/`, `routes/`,
`pages/`), `loader`/`action`/server functions, `"use client"`/`"use server"`, `createQuery`/
`useQuery`, error boundaries, `*.test.tsx`, Playwright `*.spec.ts`.

**Arbitration rule with `frontend-web-platform-standards`**: if the answer **would change when changing
framework**, it is ours; if it **would still be true in any of them** (or with none), it is theirs. "Where
the fetch happens and who revalidates the cache" is ours; "the `fetch` carries `AbortSignal.timeout` and the
LCP image carries `fetchpriority=high`" is theirs.

**Not applicable**:
- `frontend-web-platform-standards` — **it decides what belongs to the browser and the standard**: semantic HTML,
  modern CSS and support policy (Baseline), platform APIs, loading and network model, CSP/Trusted
  Types and client security, bundle budget, build tool (Vite/Rolldown/esbuild) and
  the npm supply chain. None of that is re-decided here: it is **inherited**. If a framework imposes its
  own bundler (Turbopack in Next), that imposition is documented here and its loading consequences are
  evaluated with their criteria.
- `typescript-standards` — **the language, `tsconfig.json`, typing, linting (Biome/ESLint), Zod and npm
  packaging are theirs**, as is their Next/React toolchain table. Here the *architectural* decision
  (which framework, which render model, where state lives), not the compiler config or the lint
  rules. Where both talk about Next.js, **their table wins for language and tooling versions** and this one
  for the choice criteria.
- `accessibility-standards` — WCAG 2.2, ARIA, keyboard, assistive technology and the
  audit. Here only that Testing Library's *role queries* already audit de facto and that the
  loading and error states must be announceable; **focus on route change and the announcement after a
  mutation are their criteria**, even if the mechanism is provided by the router here.
- `testing-qa-standards` — **the language-agnostic test strategy is theirs**: pyramid
  proportions, coverage thresholds, mutation, contracts, test data and *flaky* policy. Here only
  what to test in a framework UI and with which tool (§4).
- `web-performance-standards` — Core Web Vitals, budgets and measurement. Here
  hydration as an architectural cost, not its metric.
- `design-systems-standards` (**the component's public contract**: composition
  versus configuration, tokens, package versioning and breaking-change policy. Here
  how the framework consumes and renders it, not how its API is designed),
  `cms-jamstack-standards` (the headless CMS and the content are theirs; here how the
  framework renders it), `pwa-standards`, `webgl-webgpu-standards`.
- `api-design-standards` (the contract being consumed), `caching-cdn-standards` (`Cache-Control`, CDN and
  purge; here only *when* the app asks to revalidate), `appsec-standards` (methodology and triage),
  `secrets-management-standards` (**a secret does not live in the client**: variables exposed to the bundle
  are public by definition), `identity-access-management-standards` (OIDC flows),
  `observability-standards`, `cicd-standards`, `mobile-standards` (React Native and native apps),
  `dart-standards` (Flutter web), `webassembly-standards` (**already written**).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).
> Versions taken from npm/official feeds as of **Aug 2026**; licences read from the `LICENSE` or from the registry.

### Decision 0: is a framework needed?

| Case | Answer |
|---|---|
| Content site, blog, documentation, landing page, marketing | **No**. Generated HTML + CSS + spot JS. If there are many pages and components, **Astro** (islands) before an SPA |
| Simple form (contact, sign-up, search) | **No**. `<form>` with POST and server-side validation; JS to improve it, not to make it work |
| Interactive dashboard, editor, app with rich client state and a long session | **Yes**, a framework with routing and data |
| "But it will grow later" | **That is not an argument.** Migrating static content to a framework is cheap; getting out of an SPA you did not need is not |

A framework is a **permanent cost decision**: build, updates, hiring,
hydration and CVE surface. You pay for it when it solves a real problem, not by default.

### Rendering models (the real axis of the decision)

| Model | Solves | Real cost |
|---|---|---|
| **CSR** (SPA) | Rich interaction after load; no render server | Empty HTML at the start: worse first load, fragile SEO, all the JS up front |
| **SSG** | Content that changes rarely: precomputed HTML, cacheable in a CDN | The build grows with the number of pages; fresh content requires a rebuild |
| **SSR** | Per-request or personalised content, and useful HTML from the first byte | A server to maintain, scale and protect; origin latency on every navigation |
| **ISR / revalidation** | SSG page volume with bounded freshness | Invalidation complexity: it is a cache, and caches have coherence bugs |
| **Streaming + Suspense** | Sending what is ready without waiting for what is slow | It requires designing loading boundaries; it complicates handling late errors |
| **Islands** | A mostly static page with interactive parts: **only** the JS of those parts is sent | Communication between islands is deliberately awkward; a poor fit if "everything" is interactive |
| **RSC** | Components that run on the server and do not travel to the client | A double mental model (server/client), an ecosystem still settling, strong coupling to the framework |

**It is chosen per page or per route, not per project.** One product can have an SSG landing page,
an SSR listing and a CSR dashboard. Choosing a single model for everything is the frequent mistake.

### Frameworks: state, when yes and when no

| Framework | Version (Aug 2026) | Choose it when | Do not choose it when |
|---|---|---|---|
| **React** | **19.2.8** (MIT). Governance: **React Foundation** under the Linux Foundation since **2026-02-24**; React, React Native and JSX are no longer Meta's. **React 20 does not exist** (there is a lot of SEO content claiming it does) | You need to hire fast, a huge ecosystem, or you already have React. The safest three-year bet on governance and critical mass | The project is content and not interaction; the team is small and runtime weight matters |
| **Vue** | **3.5.40** stable; **3.6 in RC** with *Vapor Mode* (no virtual DOM) feature-complete and reactivity rewritten on alien-signals (MIT) | You want a progressive model, SFCs and a gentle curve; a mid-sized team with no appetite for React's churn | You need React's ecosystem depth for a specific niche |
| **Svelte** | **5.56.8** (MIT), runes. Rich Harris works at Vercel | Runtime weight and ergonomics matter more than ecosystem size | Hiring is hard in your market; you depend on libraries that only exist for React |
| **Angular** | **22.1.0** (MIT). v22 is **signal-first**: `OnPush` by default (`Default` renamed to `Eager`), Signal Forms and `resource()`/`httpResource()` stable; zoneless by default for new apps since v21 | A large enterprise, rotating teams, you value the framework imposing structure, DI and tooling; a predictable version cycle | A small team; you want to get going in a day. **Migrating an existing app to zoneless is real work: reactive forms are the riskiest part** |
| **Solid** | **1.9.14** stable; **2.0 in beta** (MIT) | Fine-grained reactivity performance with a mental model close to JSX, on a team that accepts a small ecosystem | You need abundant third-party libraries or easy hiring. **Do not adopt 2.0 in production while it remains in beta** |
| **Qwik** | `@builder.io/qwik` **1.20.0** stable; **Qwik 2 (`@qwik.dev/core`) is still in beta** (2.0.0-beta.38) (MIT) | Research or a case where resumability (zero hydration) is the dominant requirement | Production with deadlines. A v2 in prolonged beta is a signal to watch (§7) |
| **Astro** | **7.1.6** (MIT). Compiler rewritten in Rust, on **Vite 8/Rolldown**; requires Node 22.12+. **Governance: Cloudflare acquired The Astro Technology Company on 2026-01-16**; it remains open source and multi-platform according to the announcement | A content site with islands: docs, blog, marketing, catalogue e-commerce. It can embed React/Vue/Svelte components in islands | The application is mostly interactive and with state shared across zones |

### Meta-frameworks

| Meta-framework | Version (Aug 2026) | Criteria |
|---|---|---|
| **Next.js** | **16.2.12** stable (16.3 in preview/canary), MIT | React's default with SSR/RSC. It brings Turbopack as the default bundler (dev and build). It couples you to its cache model and to a deployment that performs better on Vercel: it is a trade-off, not a hidden defect |
| **React Router (framework mode)** | **8.3.0**, MIT. v8 GA 2026-06-17, **open governance and annual cadence**; middleware by default, **ESM-only packages (no CJS)**, requires Node 22.22+, React 19.2.7+ and Vite 7+ | The React option with the least magic and the least platform coupling. The annual cadence anchored to Node's EOL is a sign of maturity |
| **TanStack Start** | **v1** (React and Solid), on TanStack Router + Vite | Extreme route and data typing. **Verified risk note**: the `@tanstack/*` packages were a victim of the Mini Shai-Hulud campaign in May 2026 (CVE-2026-45321) — it is not the code's fault, but it forces the hygiene in §5 |
| **Nuxt** | **4.5.1** (the 3.x branch still gets releases), MIT. NuxtLabs and Nitro's creator are at **Vercel**; **a Jul 2026 security advisory with server-side RCE** — patching is mandatory | Vue's default |
| **SvelteKit** | **2.70.2** stable; **3.0 on `next`**, MIT | Svelte's default. Per-platform adapters |
| **Angular** (with its CLI and SSR) | v22 | Angular does not need an external meta-framework: it already is one |
| **Astro** | 7.1.6 | Content meta-framework; see above |
| **Remix 3** | **beta** (3.0.0-beta.x), no React, its own components | **Do not use in production**. Remix 2 continues as React Router v7/v8 |

### State, data and tests

| Piece | Choice | Version (Aug 2026) |
|---|---|---|
| Server cache on the client | **TanStack Query** (or the framework's equivalent: loaders, Angular's `resource()`, Nuxt's `useAsyncData`) | `@tanstack/react-query` **5.101.4** (v6 in beta), MIT |
| Global client state | The minimum: context or a small store (Zustand/jotai/the framework's native signals) | — |
| Unit and component tests | **Vitest** + **Testing Library** | Vitest **4.1.10** (v5 in beta), MIT; `@testing-library/react` **16.3.2**, MIT |
| E2E | **Playwright** | **1.62.1**, **Apache-2.0** licence (not MIT) |

## 3. Structure and conventions

### State: most of the "global state" is server cache

- Separate **server state** (data owned by the backend: entities, lists, permissions) from
  **client state** (active tab, open modal, form draft). Confusing them is the
  origin of 80% of the state boilerplate you see in reviews.
- Server state goes into a **cache with keys, invalidation, retries and loading/error states**
  (TanStack Query or the framework's loaders). It is not copied into a global store "to have it handy":
  that creates two sources of truth that diverge as soon as there is a second tab.
- The client state left after doing this is small. If it is still large, it is almost always
  derived state that should be computed, or URL state that should live in the URL.
- **The URL is state**: filters, pagination, tab, sort order and search go in the query string. It is
  shareable, bookmarkable, restorable with the back button and free.
- Choosing a global store before having the problem is over-engineering. Redux **by inertia**: vetoed.

### Routing and data loading

- **Data is loaded at route level**, not in a `useEffect` inside a leaf component: the
  "render → effect → fetch" pattern produces serial waterfalls and is the usual cause of a slow app.
- Parallel routes → parallel requests. A request that depends on another is a conscious waterfall,
  not an oversight.
- Code split by route; preload on link `hover`/`focus` when the destination is likely.
- Typed routing if the framework offers it: a broken link should be a compile error.
- Mutation → explicit invalidation of the affected keys. Optimistic updates **only** with
  reversion implemented and tested; if there is no rollback, there is no optimism, there is a lie.

### Forms and shared validation

- A **single** schema (Zod or equivalent; the library choice belongs to `typescript-standards`) used
  on the client **and** on the server. Two hand-written validations diverge by week three.
- **Client validation is UX; the one that counts is the server's.** No exception.
- The form must work with `<form>` and POST when the framework allows it (progressive
  enhancement): if the JS fails or is slow, the user can still submit.
- Mandatory states: submitting, field error, global error, success. Double submit blocked.
  Server errors mapped to the corresponding field, not to a generic `alert`.
- Files and uploads: size and type limits validated on the server, always.

### Server rendering and hydration as a cost

- **Hydrating is not free**: the HTML arrives fast and then the browser re-executes the tree to
  make it interactive. That gap between "it is visible" and "it responds" is real and it is where the sense
  of speed is lost. SSR without hydration control can be **worse** than CSR for the user.
- Strategies, in order of preference depending on how much interactivity there is: **zero JS** → **islands** →
  **partial/selective hydration** → **RSC** (the server component does not travel) → full
  hydration. Choosing "full hydration of the whole page" is the last-resort option, not the
  first.
- SSR forces isomorphic code: no `window`/`document` in the render path. And it forces a
  server with timeouts, limits and deployment — it is infrastructure, not a config checkbox.
- **A hydration mismatch is a bug**, not a warning to silence: it means server and
  client rendered different things (date, random, `localStorage`, `Date.now()`).
- Nothing sensitive in the payload serialised to the client: what goes into the SSR HTML is public.

### Error boundaries and loading states: a requirement, not an extra

- **Every route has an error boundary** and every asynchronous load has its pending and failure state.
  A blank screen on a network error is a product defect.
- The error boundary shows a neutral message and a recovery action (retry, go back);
  **never** the stack trace or the backend's message.
- Designed empty states (a list with no results ≠ error ≠ loading). Skeletons that reserve the real
  space, so as not to cause a shift when the data arrives.
- The error is reported to the observability system; the user sees something actionable.
- Classic offence: a `catch` that does `console.error` and carries on. An error that is neither shown nor reported
  does not exist until a customer opens it in a ticket.

## 4. Quality and testing

- **Observable behaviour is tested, not implementation.** Testing Library with **role and
  accessible-label** queries; `data-testid` is a last resort. If a test breaks when renaming an internal
  variable, the test was wrong.
- Split by cost:
  - **Unit (Vitest)**: pure logic, transformations, validation schemas with valid **and
    invalid** cases. Fast and without the network.
  - **Component (Vitest + Testing Library)**: real interaction (keyboard included), loading,
    error and empty states. Mock the **network boundary**, not your own hooks.
  - **E2E (Playwright)**: the flows that cost money if they break — auth, payment, sign-up, main CRUD.
    Between 20 and 30, not two hundred. Traces on failure.
- **Mandatory cases** (not optional, not "when there is time"): an API returning 500, network down,
  a slow response, a session expiring mid-flow, double submit, navigating with the back button during
  a load, an empty list.
- No `sleep`/`waitForTimeout`: `findBy*`, `waitFor`, web-first assertions. A flaky test = fixed or
  deleted the same day; a tolerated flaky poisons the signal of the whole suite.
- Giant snapshots as the only assertion: they are not a test, they are a photo.
- CI gates (the platform and language ones are set by the neighbouring skills): typecheck → unit and
  component → build → E2E against preview. Main always green.

## 5. Framework-specific security

- **Every framework endpoint is a public endpoint**: server action, server function, route handler
  or loader. Authentication and **authorisation inside each one**, verifying that the resource belongs to the
  user (IDOR). Middleware is not a security boundary: it is routing.
- **Everything that reaches the bundle is public**: variables with an exposure prefix (`NEXT_PUBLIC_`,
  `PUBLIC_`, `VITE_`, `NUXT_PUBLIC_`) are visible to anyone. A secret there is a leak,
  not an oversight — see `secrets-management-standards`.
- The framework's default escaping is respected: `dangerouslySetInnerHTML`, `v-html`, `{@html}` and
  equivalents only with sanitised content and explicit review (the sinks and sanitisation, in
  `frontend-web-platform-standards`).
- SSR with user data: do not serialise into the HTML anything the user must not see (tokens, internal
  fields, full session objects). Filter on the server what is sent to the client.
- Links and redirects with a destination taken from the URL: allowlist. An unvalidated `?next=` is an open
  redirect.
- **Patching the meta-framework is a critical operation**, not maintenance: verified precedents —
  Nuxt's advisory of Jul 2026 with **server-side RCE**, and SSRF protections added to
  Angular's `platform-server` in v22. Subscribe to the chosen framework's advisories.
- The npm supply chain and its hygiene belong to `frontend-web-platform-standards`; here the
  consequence: a framework drags in hundreds of transitive dependencies and **that is part of the cost of choosing it**.

## 6. Performance and operability

- The bundle budget and field metrics belong to the neighbouring skills. Here what the
  framework decides: **how much JS is sent per route** and **how much of it gets hydrated**.
- Chunk loading errors after a deployment: the previous version's assets must keep being
  served during the transition window, or users with the tab open break.
- Server rendering = a production service: timeouts, concurrency limits, orderly
  shutdown, health checks and observability. A backend failure cannot bring down the render of the whole
  page: degradation by section (streaming + error boundaries).
- Framework revalidation and caching: **explicit and documented**. Relying on implicit defaults that
  change between majors is how the "why am I seeing stale data" bugs appear.
- Instrument: uncaught client errors with source maps uploaded (not served), route
  navigation, per-route data loading failures.

## 7. Long-term sustainability, ecosystem churn and prohibitions

### Choosing so the decision survives three years

The frontend churns faster than the application's useful life. Criteria, in this order:

1. **Governance and ownership.** Who can change the licence or the direction overnight?
   A foundation or open governance > a single company. Facts verified as of Aug 2026: React moved to the **React
   Foundation** (Linux Foundation, Feb 2026); React Router adopted **open governance** with an annual
   cadence; **Astro was acquired by Cloudflare** (Jan 2026); Nuxt and Svelte have their main
   figures **on Vercel's payroll**. None of those facts is disqualifying on its own: they are the
   risk that has to be named before signing, not afterwards.
2. **Exit route.** How much does it cost to get out? The more standard what you write is (HTML, native
   forms, `fetch`, URL as state), the cheaper the exit. The expensive coupling is not in the
   framework: it is in its data model and in its deployment platform.
3. **Hiring.** A framework nobody in your market knows is a permanent onboarding cost.
   It is a legitimate technical criterion, not a lazy excuse.
4. **Predictable cadence.** Releases with a calendar and migration guides > surprise releases. A
   cadence anchored to something external and verifiable (e.g. Node's EOL) is a better signal than "when it is
   ready".
5. **Stability of the mental model.** If the framework has changed its core paradigm twice in three
   years, your code will do so too.

**Decline signals** (none decides alone; **three together do**):
- A key major that has been **in beta for more than a year** with no date (this applies today to Qwik 2, in beta as of Aug 2026).
- The core team moves its energy to a new project and the current one goes into maintenance.
- Open issues growing while merges fall; community PRs with no response for months.
- The documentation describes a version that is no longer the recommended one.
- The library ecosystem stops porting: plugins stay on the previous major.
- Blog posts move from "how to do X" to "how to migrate away".
- The single sponsor changes strategy or is acquired **and** stops hiring on the project.

### Cadence

- Framework security patches: **immediate**, with the advisory read.
- Minors: in batches, fortnightly or monthly, grouped by Renovate.
- Majors: their own PR, changelog read, official codemod if one exists, and **one major at a time** (React
  Router v8 requiring Vite 7 is the example of why chaining two migrations goes badly).
- Do not adopt a major on the day it comes out. Nor stay two majors behind: the migration becomes
  irreversible and security support runs out.
- A beta or RC in production **only** with a written decision, an owner and a review date (this affects Vue 3.6,
  Solid 2, Qwik 2, SvelteKit 3, Vitest 5, TanStack Query 6 and Remix 3 today).

**FORBIDDEN:**
- ❌ Putting a framework (or an SPA) into a content site or into a form that HTML already solved.
- ❌ Choosing a framework by fashion, by an isolated benchmark or by what was popular at the last conference.
  The decision is written down with a reason, the discarded alternative and the exit cost.
- ❌ A single rendering model imposed on all routes "for consistency".
- ❌ Data fetching in `useEffect` (or equivalent) when the framework offers route-level loading;
  serial request waterfalls without justification.
- ❌ Duplicating server state in a global client store; Redux (or any store) "by default".
- ❌ Filter/pagination/tab state outside the URL.
- ❌ A server action / route handler / server function without its own authn and **authz**; middleware as the only
  authorisation layer.
- ❌ Secrets or sensitive data in environment variables exposed to the client, or serialised into the SSR HTML.
- ❌ Silencing hydration mismatch warnings instead of fixing their cause.
- ❌ A route without an error boundary; an asynchronous load without a pending and a failure state; showing the raw backend
  error to the user.
- ❌ An optimistic update without reversion implemented and tested.
- ❌ Tests coupled to the implementation (internal state, CSS class names, `data-testid` out of convenience),
  with `sleep`, or dependent on order.
- ❌ A framework beta/RC in production without a written decision with an owner and a date. **Remix 3 does not go to production.**
- ❌ Mixing two UI frameworks in the same application out of convenience (Astro's islands are the
  exception designed for that; the rest is debt with two runtimes).
- ❌ Stating versions, release status, licence or governance from memory. Verified as of Aug 2026: **React 20
  does not exist** despite the volume of content announcing it.

## 8. Mandatory web verification

Before pinning anything, check online (Atom feeds `https://github.com/OWNER/REPO/releases.atom` and the
npm registry — **`api.github.com` gives 403 unauthenticated**; each project's official site to cross-check,
because the GitHub feed **is not the source of truth**; raw `LICENSE` for licences):

1. **Major version and status of each framework**: React (is it still 19.2.x? A real React 20, not from SEO blogs?),
   Vue (is 3.6 stable yet with Vapor Mode?), Svelte, Angular (v23 arrives on schedule), Solid (has 2.0 left
   beta?), Qwik (is Qwik 2 stable, or still in beta?), Astro.
2. **Meta-frameworks**: Next.js (is 16.3 stable? 17?), Nuxt (the 4.x branch and the state of 3.x), SvelteKit
   (is 3.0 stable?), React Router (v8.x current; v9 announced for ~May 2027), TanStack Start, Remix 3.
3. **Licence or governance changes** — an expensive fact, always verified: React Foundation, Cloudflare's
   acquisition of Astro, React Router's open governance, who employs the key maintainers.
   **Confirm that none has changed since Aug 2026.**
4. **Advisories of the chosen framework** (`github.com/advisories`, osv.dev, the project's security
   blog): verified precedents in 2026 — Nuxt's RCE (Jul 2026), RSC CVEs in React,
   the compromise of the `@tanstack/*` packages (CVE-2026-45321, May 2026).
5. **Test tools**: Vitest (is v5 stable?), Playwright (**Apache-2.0**, not MIT), Testing Library,
   TanStack Query (is v6 stable?).
6. **Platform requirements** of each major: minimum Node version, Vite version and ESM-only (React Router 8
   stopped publishing CJS; Astro 7 requires Node 22.12+).

**Gaps not verified as of Aug 2026** (do not fill in from memory):
- The exact version and GA status of **TanStack Start** ("v1" is documented but **the specific stable version
  number is not verified**; the repo feed is dominated by `2.0.0-beta.x` betas of the router
  packages).
- The release date of **Vue 3.6 stable** and of **SvelteKit 3**: **not verified**.
- The state of **Solid 2.0** beyond "beta": **not verified**.
- Real market share and hiring data per framework: **not verified** — the §2 table sets
  qualitative criteria, not figures. Use State of JS / the current year's surveys if you need numbers.
- Support and EOL policy per major for Next.js, Nuxt and Angular: **not verified**. Angular publishes
  LTS windows; check the current one before committing to a version.

**Declared discrepancies**:
- **React 20**: multiple 2026 articles announce its launch with specific benchmarks; the reliable
  sources deny it and react.dev does not publish it. Content generated for SEO. **react.dev wins.**
- **Vue 3.6 / Vapor Mode**: at least one source treats it as stable in "early 2026"; the official
  notes and the repo tags place it at **RC** as of Aug 2026. **The official notes win.**
- **React Router v8**: the website says 8.2.0 (Jul 2026) is current and the npm registry returns **8.3.0**;
  the registry is fresher. Check before pinning.
- **Astro / Cloudflare**: the acquisition is confirmed by Cloudflare's press release
  (2026-01-16); the commitment that Astro stays open source and multi-platform is a
  **statement by the acquirer**, not a verifiable future fact. Treat it as a risk to review.

If the web contradicts this document, **the web wins** — flag the discrepancy.
