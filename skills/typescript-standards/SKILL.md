---
name: typescript-standards
description: Use when writing, reviewing, or designing TypeScript or JavaScript code - .ts, .tsx, .mts, package.json, tsconfig.json, Node.js backends, React, Next.js, Express/Fastify/Hono, Zod, pnpm, Biome, ESLint, Vitest, Playwright, npm packages, or frontend/backend JS tooling and CI.
---

# TypeScript / Node / React standards (reference: August 2026)

## 1. Scope and triggers

Applies to all TypeScript/JavaScript work: Node backend, React/Next.js frontend, npm libraries, tooling and CI.
Triggers: `.ts`, `.tsx`, `.mts`, `package.json`, `tsconfig.json`, Node, React, Next.js, Fastify/Hono/Express, Zod, Vitest, Playwright.
This document fixes **criteria** (what to use, what is vetoed, what to verify), not tutorials.

**Not applicable**: see `api-design-standards` (HTTP/GraphQL/gRPC contract design: resources, status codes,
pagination, RFC 9457, versioning — here only its implementation in Fastify/Hono/Next),
`microservices-architecture-standards` (service boundaries, events, sagas, distributed resilience),
`appsec-standards` (threat modelling and stack-agnostic vulnerability classes; here only
the concrete JS/TS sinks and flags), `mobile-standards` (native iOS/Android: React Native falls
outside both except for its native part), `data-platform-standards` (modelling, indexes and engine
tuning; here only the use of Drizzle/Prisma/kysely), `cicd-standards` (the pipeline that runs the
§4 gates), `kubernetes-standards` (OCI image and deployment), `observability-standards` (OTel
pipeline; here only the instrumentation in the code), `git-workflow-standards` (branch, commits and
SemVer tagging; npm publication does belong to this skill), `identity-access-management-standards` (OAuth
2.1/OIDC flows and token issuance; here only how the app consumes and verifies them), `sql-standards`
(the SQL that Prisma, Drizzle or Kysely generate, and the SQL written by hand),
`testing-qa-standards` (**the runner and its configuration —Vitest, Playwright— belong
here**; **the split across levels, the coverage criteria, the flaky-test policy and what
breaks the build are theirs**. The §4 criteria in this skill are kept as a concrete convention of the
stack, but **if they contradict `testing-qa-standards`, theirs wins**),
`frontend-web-platform-standards` (**what the browser and the standard decide** —HTML, CSS,
platform APIs, loading model, CSP and client-side security, *bundle* budget and the build
tool—; **here the language**: `tsconfig.json`, typing, linting and npm publication.
Arbitration rule mirrored from their §1: *if the answer would change when you change framework, it belongs to
`frontend-frameworks-standards`; if it would still hold in any of them, it belongs to
`frontend-web-platform-standards`; if it would not change when you change browser or framework, it belongs
here*), `frontend-frameworks-standards` (framework choice, rendering model
—CSR/SSR/SSG/ISR/islands/RSC—, routing, data loading and application structure),
`webassembly-standards` (the Wasm module, its runtime, its limits and its size are theirs;
the JS/TS that loads it and the cost of crossing the JS↔Wasm boundary are decided with their criteria, and the
rule both share is that **Wasm is not worth it for manipulating the DOM**), `solidity-standards`
(the contract and its security criteria are theirs; **the deployment scripts and the
TypeScript Hardhat tests with `viem`/`ethers` are written with the criteria from here** — and a
deployment private key **never** lives in a versioned `.env` nor in the script's code). **Language
choice** (the chosen language's skill wins): `python-standards`, `go-standards`,
`rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`, `ruby-standards`,
`elixir-erlang-standards`, `scala-standards`, `clojure-standards`, `haskell-fp-standards`,
`ocaml-fsharp-standards`.

## 2. Default toolchain

> **Note**: state verified as of 2026-08. **Before pinning versions in a real project, verify the
> latest stable on the web** (section 8). Never pin versions from memory.

| Piece | Choice | Minimum | Why |
|---|---|---|---|
| Runtime | **Node.js LTS** | **24 (Krypton)**, Active LTS until 2026-10, EOL 2028-04 | Node 20 EOL since 2026-04; Node 26 will be LTS in 2026-10. Bun/Deno only by explicit project decision |
| Package manager | **pnpm** | 10+ | De facto standard: strict (no phantom deps), mature workspaces, lifecycle scripts disabled by default. Pin with `packageManager` + corepack |
| Language | **TypeScript** | **6.0** (last JS-based one; strict and ESM by default) | TS 7 (tsgo, native Go, ~10x) in RC as of 2026-06: check whether it is already stable before adopting it; 6.0 compiles identically to 7.0 by design |
| Lint+format (greenfield) | **Biome** | 2.5+ | One binary, 10-25x faster; enough for most projects |
| Lint (if plugins are needed) | **ESLint 9 flat config** + typescript-eslint (type-aware) + Prettier | 9+ | Mandatory when you need `react-hooks`, `@next/eslint-plugin-next` or custom rules; a fine-grained Biome+ESLint hybrid is valid |
| Runtime validation | **Zod** | **4** | Ecosystem default (Standard Schema, tRPC, RHF). Valibot if the frontend/edge bundle is critical; ArkType for complex type modelling |
| Unit/component tests | **Vitest** | 4+ (Browser Mode stable via `@vitest/browser-playwright`) | + Testing Library (queries by role). Jest only in legacy |
| E2E | **Playwright** | — | Replaced Cypress as the standard |
| Frontend framework | **Next.js** App Router | **16** (React Compiler stable, `middleware.ts` deprecated → proxy/edge per the 16 guide) | React **19.2** (always patch to the latest 19.2.x: critical RSC CVEs in 19.0.0–19.2.2) |
| SPA without SSR | Vite + React Router / TanStack Router | — | Do not use Next if you do not need SSR/RSC |
| HTTP backend | **Fastify** or **Hono** | — | Express only in legacy (or an existing 5.x); Hono if you target edge/multi-runtime |
| ORM/DB | Drizzle or Prisma; **kysely** for typed SQL | — | Pick one per project; versioned migrations always |
| Env/config | Startup validation with Zod (`env.ts` that parses `process.env` and fails fast) | — | Config outside the artifact |
| Monorepo | pnpm workspaces + Turborepo/Nx | — | `workspace:` protocol |

## 3. Structure and conventions

- **ESM only** in new code: `"type": "module"`, imports with an extension where required; CJS only for legacy interop.
- Base `tsconfig`: `strict: true` plus `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`,
  `noImplicitOverride`, `verbatimModuleSyntax`, `isolatedModules`, `moduleResolution: "bundler"` (front) or `"nodenext"` (back).
- `package.json`: `engines.node` pinned, `packageManager` pinned, `exports` map in libraries (never just `main`).
- Lockfile committed; CI installs with `pnpm install --frozen-lockfile` **always**.
- Backend: clear layers — router (pure HTTP) → service (domain) → repo (persistence); DTOs validated with Zod at the boundary and types **inferred** from the schema (`z.infer`), not duplicated by hand.
- Next.js App Router: Server Components by default; `"use client"` only on interactive leaves; mutations via Server Actions or route handlers **with Zod validation and an authz check inside each action** (a Server Action is a public endpoint, treat it as one).
- Frontend state: server-state with TanStack Query or the RSC cache; minimal global client state (Zustand/jotai); no Redux out of inertia.
- Typed errors in the domain (Result/discriminated unions or custom error classes); throwing strings is vetoed.
- **HTTP API design**: explicit versioning, errors in a consistent format (RFC 9457 problem+json or
  a single custom one), mandatory pagination on collections, Zod schemas shared between server and client
  (a `shared`/`contracts` package in the monorepo) — or generated tRPC/OpenAPI if the contract justifies it.
- **Publishable libraries**: `exports` with types (`"types"` condition), dual ESM (CJS only if there are justified
  legacy consumers), `sideEffects: false` where applicable, publication from CI with OIDC/provenance, SemVer + changelog
  (changesets in monorepos).
- Dates and money: `Temporal` (or date-fns if the runtime does not support it yet — verify) and integers in the
  smallest unit (cents) or a decimal library; never floating `number` arithmetic for money.

## 4. Quality: formatting, lint, types, tests

- **Formatting**: Biome format (or Prettier if you take the ESLint route). Zero style debate in PRs.
- **Lint**: recommended rules + `noExplicitAny` (or `@typescript-eslint/no-explicit-any`), `react-hooks`
  exhaustiveness intact (never disable `exhaustive-deps` without a justified comment), ordered imports.
- **Types**: `tsc --noEmit` as a CI gate even if the bundler transpiles (esbuild/SWC/turbopack do not check types).
  `any` forbidden except at an annotated boundary; use `unknown` + narrowing. Generics with constraints, `satisfies` to
  validate configs without widening. No chained `as` to "convince" the compiler — if you need it, the type model is wrong.
- **Tests**:
  - Unit (Vitest): domain logic, Zod schemas (valid **and invalid** cases), utils. Fast, deterministic, no network.
  - Component: Testing Library with queries by role/label (no test-ids except as a last resort); Vitest Browser Mode for components JSDOM does not cover well.
  - Backend integration: against the real app (`fastify.inject` / fetch to the running server) with a real DB (testcontainers), not ORM mocks.
  - E2E (Playwright): 20-30 critical flows (auth, payment, main CRUD), with trace on-failure. Do not replicate in E2E what lower layers already cover.
  - Edges and errors mandatory: invalid payload, 401/403, timeouts, partial responses, double-submit race.
  - Async: no `sleep`/`waitForTimeout` — `findBy*`, `waitFor`, Playwright web-first assertions. Flaky = fix it or delete it.
- **CI gates** (block merge, cheapest first):
  1. `pnpm install --frozen-lockfile`
  2. format check + lint (Biome `ci` or ESLint)
  3. `tsc --noEmit` (per package in monorepos, with project references or Turborepo cache)
  4. unit + integration with coverage (agreed threshold; a signal, not a goal)
  5. `pnpm audit` / SCA + build
  6. Playwright E2E against a preview deployment
  Main always green; nothing merges with CI red "because it is a known flaky".
- Exact pin of the toolchain in devDependencies (TS, Biome/ESLint, Vitest): their majors change rules and
  defaults; an update breaking CI must be a Renovate PR, not a surprise.
- Same command locally and in CI (`pnpm test`, `pnpm lint`, `pnpm typecheck` as canonical scripts):
  if CI is not reproducible locally, it is a pipeline bug.

## 5. Stack security

- **Validation at every boundary** with Zod: body, query, params, relevant headers, env vars, third-party API responses that feed logic. `z.object(...).strict()` wherever excess properties are suspicious.
- **XSS**: React escapes by default — `dangerouslySetInnerHTML` only with sanitisation (DOMPurify) and review; never interpolate input into `href`/`src` without validating the scheme (`javascript:` URLs).
- **Server Actions / route handlers**: authn+authz **inside** each handler (Next's middleware is not a security boundary and is deprecated in 16); resource IDs always re-checked against the user (IDOR).
- **Secrets**: server-side only; in Next.js nothing sensitive with the `NEXT_PUBLIC_` prefix. Env validated at startup. Never secrets in code, bundle, logs or lockfiles.
- **Injection**: parameterised queries (the ORM does it; `sql.raw`/template strings with input = veto). `child_process` with an args array, never an interpolated shell.
- **Cookies/session**: `httpOnly`, `secure`, `sameSite`; CSRF covered by the framework or an explicit token on cookie-bearing endpoints. JWT with a pinned algorithm and short expiry.
- **Supply chain**: `pnpm audit` + Renovate/Dependabot as a gate; lifecycle scripts disabled (the default in pnpm 10) and an explicit allowlist; `overrides` to force transitive patches; publish with provenance (`npm publish --provenance`). Watch for typosquatting when adding deps.
- **Headers**: CSP (Next 16 makes it easier), HSTS, `X-Content-Type-Options`; rate limiting and a body size limit in the backend.
- **Errors**: never stack traces to the client; a neutral error + correlation id; structured server-side log.
- Patch React/Next immediately on RSC advisories (critical precedent Dec-2025).

## 6. Performance and operability

- **Backend**:
  - Explicit timeouts on every HTTP client (`AbortSignal.timeout`), bounded DB pool, `server.requestTimeout`/`keepAliveTimeout` configured.
  - **Graceful shutdown**: capture SIGTERM, stop accepting connections, drain in-flight with a deadline, close pools; readiness red before dying. Without this there are no healthy rolling deploys.
  - Do not block the event loop: CPU-bound work to worker threads; monitor event loop lag.
  - Observability: structured JSON logs (pino) with a correlation id, OpenTelemetry (HTTP, DB, fetch), `/healthz` + `/readyz`, golden signals with SLOs.
  - Retries with backoff+jitter only on idempotent operations; circuit breaker towards fragile dependencies; idempotency keys on mutations exposed to retries.
- **Frontend**:
  - Server Components for data-fetching; streaming + `Suspense`; explicit Next 16 caching (do not rely on implicit defaults from previous versions).
  - React Compiler enabled (stable in Next 16) before massive manual memoisation.
  - Bundle budget watched in CI; `next/image`, `next/font`, dynamic imports for heavy routes.
  - Core Web Vitals measured in the field (RUM), not just local Lighthouse.
  - Client errors to Sentry (or equivalent) with source maps uploaded, not publicly exposed.
  - **Accessibility as a gate, not as an extra** (WCAG 2.2): semantic HTML and correct roles — Testing Library tests
    querying by role already audits it de facto; `eslint-plugin-jsx-a11y` (or Biome's a11y rules)
    active; visible focus and keyboard navigation in every critical E2E flow.
  - i18n from the start if more than one locale is foreseen (next-intl or equivalent); no hardcoded
    strings scattered across components.
- **Containers** (backend): slim/distroless multi-stage image, non-root, `NODE_ENV=production`,
  `pnpm deploy --prod` or Next standalone output; signals properly propagated (do not wrap node in a shell
  that swallows SIGTERM — use exec form or tini).
- Backwards-compatible data migrations (*expand/contract*): the N-1 code must work during
  the rolling deploy; destructive changes go in a later release.

## 7. Long-term sustainability

- **Cadence**: security patches immediately; minors weekly/fortnightly via grouped Renovate; Node from LTS to LTS (move onto the new LTS ~1-2 months after its October promotion); framework majors (Next, React) after reading the official upgrade guide and with codemods (`npx @next/codemod`).
- TS 7 (tsgo): adopt when it is stable and the plugin/API ecosystem is ported — compiling cleanly on 6.0 today is the preparation.
- A dependency unmaintained for >18 months is reviewed or replaced; every new dep is justified (does the platform already do it? `fetch`, `structuredClone`, `node:test`… exist).
- Your own deprecations: warning + changelog + window; third-party ones are debt with an issue, not silenced noise.
- Renovate grouped by risk: patches auto-merged with CI green; minors in a weekly batch; majors in an
  individual PR with the changelog read. Never floating `^` without a lockfile as an "update" strategy.
- Maintenance budget in every sprint; conscious debt = a TODO with a reason and a linked issue.

**List of prohibitions (veto):**
- `any` (use `unknown`), `@ts-ignore` (use `@ts-expect-error` with a reason), `as unknown as X`, `!` non-null for convenience.
- Disabling `strict` or lowering tsconfig flags "so it compiles".
- `npm install` in a pnpm repo; mixing lockfiles; CI without `--frozen-lockfile`; deps without a committed lockfile.
- Non-LTS Node in prod (odd releases, EOL like Node 20); `latest` as an image or dependency tag.
- Trusting client-side validation only; a Server Action/route handler without its own authz; secrets in `NEXT_PUBLIC_*`.
- `dangerouslySetInnerHTML` without sanitising; `eval`/`new Function` over external data.
- Silencing promises: `.then()` without catch, floating promises (lint rule active), `async` without an await chained to anything.
- Disabling `react-hooks/exhaustive-deps` without written justification; `useEffect` to derive state or to fetch what belongs to RSC/TanStack Query.
- Tests with `sleep`, order-dependent or dependent on public services; giant snapshots as the only assertion.
- CommonJS in new code; dynamic `require` to dodge types.
- Redux/global-state boilerplate "by default"; massive prop drilling instead of composition.
- New Express without justification against Fastify/Hono; Next middleware as the only auth layer.
- Copying versions/APIs from memory or from blogs without checking against the official changelog.

## 8. Mandatory web verification

Before pinning versions or APIs in a project, **verify online** (WebSearch/WebFetch):
1. Active Node LTS (nodejs.org/endoflife.date) — **from 2026-10 the release model changes** (one major/year, all LTS): confirm which line applies.
2. **Is TypeScript 7 (tsgo) stable yet?** (devblogs.microsoft.com/typescript) — it was in RC as of 2026-06. Status of the new plugin API if you depend on plugins.
3. Latest Next.js (16.3+? 17?) and React (current 19.2.x patch + RSC advisories on github.com/advisories and osv.dev).
4. Biome vs ESLint status for YOUR specific stack: does Biome already cover the type-aware and framework rules you need?
5. Vitest (is v5 stable yet? betas on npm as of mid-2026), Playwright and Zod: latest major and breaking changes in the official changelog.
6. Current pnpm major and its security defaults; recent CVEs of all direct deps before pinning a version.

If the web contradicts this document, **the web wins** — flag the discrepancy.
