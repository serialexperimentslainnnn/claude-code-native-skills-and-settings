---
name: typescript-standards
description: Use when writing, reviewing, or designing TypeScript or JavaScript code - .ts, .tsx, .mts, package.json, tsconfig.json, Node.js backends, React, Next.js, Express/Fastify/Hono, Zod, pnpm, Biome, ESLint, Vitest, Playwright, npm packages, or frontend/backend JS tooling and CI.
---

# Estándares TypeScript / Node / React (referencia: agosto 2026)

## 1. Alcance y triggers

Aplica a todo trabajo TypeScript/JavaScript: backend Node, frontend React/Next.js, librerías npm, tooling y CI.
Triggers: `.ts`, `.tsx`, `.mts`, `package.json`, `tsconfig.json`, Node, React, Next.js, Fastify/Hono/Express, Zod, Vitest, Playwright.
Este documento fija **criterio** (qué usar, qué está vetado, qué verificar), no tutoriales.

**No aplica**: ver `api-design-standards` (diseño del contrato HTTP/GraphQL/gRPC: recursos, códigos,
paginación, RFC 9457, versionado — aquí solo su implementación en Fastify/Hono/Next),
`microservices-architecture-standards` (corte de servicios, eventos, sagas, resiliencia distribuida),
`appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas del stack; aquí solo
los sinks y flags concretos de JS/TS), `mobile-standards` (iOS/Android nativo: React Native queda
fuera de ambas salvo su parte nativa), `data-platform-standards` (modelado, índices y tuning del
motor; aquí solo el uso de Drizzle/Prisma/kysely), `cicd-standards` (la pipeline que ejecuta los
gates de §4), `kubernetes-standards` (imagen OCI y despliegue), `observability-standards` (pipeline
OTel; aquí solo la instrumentación en el código), `git-workflow-standards` (rama, commits y tagging
SemVer; la publicación en npm sí es de esta skill), `identity-access-management-standards` (flujos
OAuth 2.1/OIDC y emisión de tokens; aquí solo cómo los consume y verifica la app), `sql-standards`
(el SQL que Prisma, Drizzle o Kysely generan, y el que se escribe a mano),
`testing-qa-standards` (**el runner y su configuración —Vitest, Playwright— son de
aquí**; **el reparto entre niveles, el criterio de cobertura, la política de tests inestables y qué
rompe el build son suyos**. El criterio de §4 de esta skill se conserva como convención concreta del
stack, pero **si contradice a `testing-qa-standards`, manda la suya**),
`frontend-web-platform-standards` (**lo que decide el navegador y el estándar** —HTML, CSS,
APIs de la plataforma, modelo de carga, CSP y seguridad del cliente, presupuesto de *bundle* y la
herramienta de build—; **aquí el lenguaje**: `tsconfig.json`, tipado, linting y publicación en npm.
Regla de arbitraje espejada desde su §1: *si la respuesta cambiaría al cambiar de framework, es de
`frontend-frameworks-standards`; si seguiría siendo cierta en cualquiera, es de
`frontend-web-platform-standards`; si no cambiaría al cambiar de navegador ni de framework, es de
aquí*), `frontend-frameworks-standards` (elección de framework, modelo de renderizado
—CSR/SSR/SSG/ISR/islas/RSC—, enrutado, carga de datos y estructura de la aplicación),
`webassembly-standards` (el módulo Wasm, su runtime, sus límites y su tamaño son suyos;
el JS/TS que lo carga y el coste del cruce de frontera JS↔Wasm se deciden con su criterio, y la
regla que ambas comparten es que **para manipular el DOM no compensa Wasm**), `solidity-standards`
(el contrato y su criterio de seguridad son suyos; **los scripts de despliegue y los
tests en TypeScript de Hardhat con `viem`/`ethers` se escriben con el criterio de aquí** — y una
clave privada de despliegue **nunca** vive en un `.env` versionado ni en el código del script). **Elección de
lenguaje** (manda la skill del lenguaje elegido): `python-standards`, `go-standards`,
`rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`, `ruby-standards`,
`elixir-erlang-standards`, `scala-standards`, `clojure-standards`, `haskell-fp-standards`,
`ocaml-fsharp-standards`.

## 2. Toolchain por defecto

> **Nota**: estado verificado a 2026-08. **Antes de fijar versiones en un proyecto real, verifica la
> última estable por web** (sección 8). Nunca fijes versiones de memoria.

| Pieza | Elección | Mínimo | Por qué |
|---|---|---|---|
| Runtime | **Node.js LTS** | **24 (Krypton)**, Active LTS hasta 2026-10, EOL 2028-04 | Node 20 EOL desde 2026-04; Node 26 será LTS en 2026-10. Bun/Deno solo por decisión explícita del proyecto |
| Gestor de paquetes | **pnpm** | 10+ | Estándar de facto: estricto (sin phantom deps), workspaces maduros, lifecycle scripts desactivados por defecto. Fijar con `packageManager` + corepack |
| Lenguaje | **TypeScript** | **6.0** (último basado en JS; strict y ESM por defecto) | TS 7 (tsgo, nativo Go, ~10x) en RC a 2026-06: verificar si ya es estable antes de adoptarlo; 6.0 compila idéntico a 7.0 por diseño |
| Lint+format (greenfield) | **Biome** | 2.5+ | Un binario, 10-25x más rápido; suficiente para la mayoría de proyectos |
| Lint (si hacen falta plugins) | **ESLint 9 flat config** + typescript-eslint (type-aware) + Prettier | 9+ | Obligatorio cuando necesitas `react-hooks`, `@next/eslint-plugin-next` o reglas custom; híbrido Biome+ESLint fino es válido |
| Validación runtime | **Zod** | **4** | Default del ecosistema (Standard Schema, tRPC, RHF). Valibot si el bundle frontend/edge es crítico; ArkType para modelado de tipos complejo |
| Tests unit/component | **Vitest** | 4+ (Browser Mode estable vía `@vitest/browser-playwright`) | + Testing Library (queries por rol). Jest solo en legacy |
| E2E | **Playwright** | — | Sustituyó a Cypress como estándar |
| Frontend framework | **Next.js** App Router | **16** (React Compiler estable, `middleware.ts` deprecado → proxy/edge según guía 16) | React **19.2** (parchear siempre a último 19.2.x: CVEs críticas RSC en 19.0.0–19.2.2) |
| SPA sin SSR | Vite + React Router / TanStack Router | — | No uses Next si no necesitas SSR/RSC |
| Backend HTTP | **Fastify** o **Hono** | — | Express solo en legacy (o 5.x ya existente); Hono si apuntas a edge/multi-runtime |
| ORM/DB | Drizzle o Prisma; **kysely** para SQL tipado | — | Elegir uno por proyecto; migraciones versionadas siempre |
| Env/config | Validación al arranque con Zod (`env.ts` que parsea `process.env` y falla rápido) | — | Config fuera del artefacto |
| Monorepo | pnpm workspaces + Turborepo/Nx | — | Protocolo `workspace:` |

## 3. Estructura y convenciones

- **ESM only** en código nuevo: `"type": "module"`, imports con extensión donde toque; CJS solo interop legacy.
- `tsconfig` base: `strict: true` y además `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`,
  `noImplicitOverride`, `verbatimModuleSyntax`, `isolatedModules`, `moduleResolution: "bundler"` (front) o `"nodenext"` (back).
- `package.json`: `engines.node` fijado, `packageManager` fijado, `exports` map en librerías (nunca solo `main`).
- Lockfile committeado; CI instala con `pnpm install --frozen-lockfile` **siempre**.
- Backend: capas claras — router (HTTP puro) → service (dominio) → repo (persistencia); DTOs validados con Zod en el borde y tipos **inferidos** del schema (`z.infer`), no duplicados a mano.
- Next.js App Router: Server Components por defecto; `"use client"` solo en hojas interactivas; mutaciones vía Server Actions o route handlers **con validación Zod y chequeo de authz dentro de cada action** (una Server Action es un endpoint público, trátala como tal).
- Estado frontend: server-state con TanStack Query o el caché de RSC; estado global de cliente mínimo (Zustand/jotai); nada de Redux por inercia.
- Errores tipados en dominio (Result/discriminated unions o clases de error propias); `throw` de strings vetado.
- **Diseño de API HTTP**: versionado explícito, errores con formato consistente (RFC 9457 problem+json o
  propio único), paginación obligatoria en colecciones, schemas Zod compartidos entre server y client
  (paquete `shared`/`contracts` en el monorepo) — o tRPC/OpenAPI generado si el contrato lo justifica.
- **Librerías publicables**: `exports` con tipos (`"types"` condition), dual ESM (CJS solo si hay consumidores
  legacy justificados), `sideEffects: false` si aplica, publicación desde CI con OIDC/provenance, SemVer + changelog
  (changesets en monorepos).
- Fechas y dinero: `Temporal` (o date-fns si el runtime aún no lo soporta — verificar) y enteros en unidad
  mínima (céntimos) o librería decimal; jamás aritmética de `number` flotante para dinero.

## 4. Calidad: formato, lint, tipos, tests

- **Formato**: Biome format (o Prettier si vas por la ruta ESLint). Cero debate de estilo en PRs.
- **Lint**: reglas recommended + `noExplicitAny` (o `@typescript-eslint/no-explicit-any`), exhaustividad de
  `react-hooks` intacta (jamás desactivar `exhaustive-deps` sin comentario justificado), imports ordenados.
- **Tipos**: `tsc --noEmit` como gate de CI aunque el bundler transpile (esbuild/SWC/turbopack no comprueban tipos).
  `any` prohibido salvo frontera anotada; usa `unknown` + narrowing. Genéricos con restricciones, `satisfies` para
  validar configs sin ensanchar. Sin `as` en cadena para "convencer" al compilador — si hace falta, el modelo de tipos está mal.
- **Tests**:
  - Unit (Vitest): lógica de dominio, schemas Zod (casos válidos **e inválidos**), utils. Rápidos, deterministas, sin red.
  - Component: Testing Library con queries por rol/label (no test-ids salvo último recurso); Vitest Browser Mode para componentes que JSDOM no cubre bien.
  - Integración backend: contra la app real (`fastify.inject` / fetch al server levantado) con DB real (testcontainers), no mocks del ORM.
  - E2E (Playwright): 20-30 flujos críticos (auth, pago, CRUD principal), con trace on-failure. No repliques en E2E lo que ya cubren capas inferiores.
  - Bordes y errores obligatorios: payload inválido, 401/403, timeouts, respuestas parciales, race de doble submit.
  - Async: sin `sleep`/`waitForTimeout` — `findBy*`, `waitFor`, web-first assertions de Playwright. Flaky = arreglar o borrar.
- **Gates de CI** (bloquean merge, lo barato primero):
  1. `pnpm install --frozen-lockfile`
  2. format check + lint (Biome `ci` o ESLint)
  3. `tsc --noEmit` (por paquete en monorepos, con project references o Turborepo cache)
  4. unit + integración con coverage (umbral acordado; señal, no meta)
  5. `pnpm audit` / SCA + build
  6. E2E Playwright contra preview deployment
  Main siempre verde; no se mergea con CI roja "porque es un flaky conocido".
- Pin exacto de toolchain en devDependencies (TS, Biome/ESLint, Vitest): sus majors cambian reglas y
  defaults; que un update rompa CI debe ser un PR de Renovate, no una sorpresa.
- Mismo comando en local y CI (`pnpm test`, `pnpm lint`, `pnpm typecheck` como scripts canónicos):
  si CI no es reproducible en local, es un bug del pipeline.

## 5. Seguridad del stack

- **Validación en todos los bordes** con Zod: body, query, params, headers relevantes, env vars, respuestas de APIs de terceros que alimentan lógica. `z.object(...).strict()` donde el exceso de propiedades sea sospechoso.
- **XSS**: React escapa por defecto — `dangerouslySetInnerHTML` solo con sanitización (DOMPurify) y revisión; nunca interpoles input en `href`/`src` sin validar esquema (`javascript:` URLs).
- **Server Actions / route handlers**: authn+authz **dentro** de cada handler (el middleware de Next no es frontera de seguridad y está deprecado en 16); IDs de recurso siempre re-verificados contra el usuario (IDOR).
- **Secretos**: solo server-side; en Next.js nada sensible con prefijo `NEXT_PUBLIC_`. Env validado al arranque. Jamás secretos en código, bundle, logs o lockfiles.
- **Inyección**: queries parametrizadas (el ORM lo hace; `sql.raw`/template strings con input = veto). `child_process` con array de args, nunca shell interpolado.
- **Cookies/sesión**: `httpOnly`, `secure`, `sameSite`; CSRF cubierto por el framework o token explícito en endpoints con cookies. JWT con algoritmo fijado y expiración corta.
- **Cadena de suministro**: `pnpm audit` + Renovate/Dependabot como gate; lifecycle scripts desactivados (default en pnpm 10) y allowlist explícita; `overrides` para forzar parches transitivos; publicar con provenance (`npm publish --provenance`). Ojo a typosquatting al añadir deps.
- **Headers**: CSP (Next 16 la facilita), HSTS, `X-Content-Type-Options`; rate limiting y límite de tamaño de body en el backend.
- **Errores**: nunca stack traces al cliente; error neutro + correlation id; log estructurado server-side.
- Parchear React/Next inmediatamente ante advisories RSC (precedente crítico dic-2025).

## 6. Rendimiento y operabilidad

- **Backend**:
  - Timeouts explícitos en todo cliente HTTP (`AbortSignal.timeout`), pool de DB acotado, `server.requestTimeout`/`keepAliveTimeout` configurados.
  - **Graceful shutdown**: capturar SIGTERM, dejar de aceptar conexiones, drenar in-flight con deadline, cerrar pools; readiness en rojo antes de morir. Sin esto no hay rolling deploys sanos.
  - No bloquees el event loop: CPU-bound a worker threads; monitoriza event loop lag.
  - Observabilidad: logs estructurados JSON (pino) con correlation id, OpenTelemetry (HTTP, DB, fetch), `/healthz` + `/readyz`, golden signals con SLOs.
  - Retries con backoff+jitter solo en idempotentes; circuit breaker hacia dependencias frágiles; idempotency keys en mutaciones expuestas a reintentos.
- **Frontend**:
  - Server Components para data-fetching; streaming + `Suspense`; caché explícito de Next 16 (nada de confiar en defaults implícitos de versiones previas).
  - React Compiler activado (estable en Next 16) antes que memoización manual masiva.
  - Presupuesto de bundle vigilado en CI; `next/image`, `next/font`, imports dinámicos para rutas pesadas.
  - Core Web Vitals medidos en campo (RUM), no solo Lighthouse local.
  - Errores de cliente a Sentry (o equivalente) con source maps subidos, no expuestos públicamente.
  - **Accesibilidad como gate, no como extra** (WCAG 2.2): HTML semántico y roles correctos — que los tests
    de Testing Library consulten por rol ya lo audita de facto; `eslint-plugin-jsx-a11y` (o reglas a11y de Biome)
    activas; foco visible y navegación por teclado en cada flujo E2E crítico.
  - i18n desde el principio si hay más de un locale previsto (next-intl o equivalente); nada de strings
    hardcodeados regados por los componentes.
- **Contenedores** (backend): imagen slim/distroless multi-stage, non-root, `NODE_ENV=production`,
  `pnpm deploy --prod` o standalone output de Next; señales bien propagadas (no envuelvas node en un shell
  que se traga SIGTERM — usa exec form o tini).
- Migraciones de datos compatibles hacia atrás (*expand/contract*): el código N-1 debe funcionar durante
  el rolling deploy; lo destructivo va en una release posterior.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: parches de seguridad inmediatos; minors semanal/quincenal vía Renovate agrupado; Node de LTS a LTS (entrar en la nueva LTS ~1-2 meses tras su promoción de octubre); majors de framework (Next, React) tras leer el upgrade guide oficial y con codemods (`npx @next/codemod`).
- TS 7 (tsgo): adoptar cuando sea estable y el ecosistema de plugins/API esté portado — compilar limpio en 6.0 hoy es la preparación.
- Una dependencia sin mantenimiento >18 meses se revisa o reemplaza; cada dep nueva se justifica (¿lo hace la plataforma ya? `fetch`, `structuredClone`, `node:test`… existen).
- Deprecaciones propias: warning + changelog + ventana; las de terceros son deuda con issue, no ruido silenciado.
- Renovate agrupado por riesgo: patches auto-merge con CI verde; minors en lote semanal; majors en PR
  individual con lectura del changelog. Nunca `^` flotante sin lockfile como estrategia de "actualización".
- Presupuesto de mantenimiento en cada sprint; deuda consciente = TODO con motivo e issue enlazada.

**Lista de prohibiciones (veto):**
- `any` (usa `unknown`), `@ts-ignore` (usa `@ts-expect-error` con motivo), `as unknown as X`, `!` non-null por comodidad.
- Desactivar `strict` o rebajar flags del tsconfig para "que compile".
- `npm install` en un repo pnpm; mezclar lockfiles; CI sin `--frozen-lockfile`; deps sin lockfile committeado.
- Node sin LTS en prod (odd releases, EOL como Node 20); `latest` como tag de imagen o dependencia.
- Confiar en validación solo de cliente; Server Action/route handler sin authz propia; secretos en `NEXT_PUBLIC_*`.
- `dangerouslySetInnerHTML` sin sanitizar; `eval`/`new Function` sobre datos externos.
- Silenciar promesas: `.then()` sin catch, floating promises (regla lint activa), `async` sin await encadenado a nada.
- Desactivar `react-hooks/exhaustive-deps` sin justificación escrita; `useEffect` para derivar estado o hacer fetching que corresponde a RSC/TanStack Query.
- Tests con `sleep`, dependientes de orden o de servicios públicos; snapshots gigantes como única aserción.
- CommonJS en código nuevo; `require` dinámico para eludir tipos.
- Redux/boilerplate de estado global "por defecto"; prop drilling masivo en vez de composición.
- Express nuevo sin justificar frente a Fastify/Hono; middleware de Next como única capa de auth.
- Copiar versiones/APIs de memoria o de blogs sin contrastar con changelog oficial.

## 8. Verificación web obligatoria

Antes de fijar versiones o APIs en un proyecto, **verifica online** (WebSearch/WebFetch):
1. LTS activa de Node (nodejs.org/endoflife.date) — **a partir de 2026-10 cambia el modelo de releases** (una major/año, todas LTS): confirma qué línea toca.
2. **¿TypeScript 7 (tsgo) ya es estable?** (devblogs.microsoft.com/typescript) — estaba en RC a 2026-06. Estado del plugin API nuevo si dependes de plugins.
3. Última de Next.js (¿16.3+? ¿17?) y React (parche 19.2.x vigente + advisories RSC en github.com/advisories y osv.dev).
4. Estado Biome vs ESLint para TU stack concreto: ¿cubre Biome ya las reglas type-aware y de framework que necesitas?
5. Vitest (¿v5 ya estable? betas en npm a mediados de 2026), Playwright y Zod: última major y breaking changes en changelog oficial.
6. pnpm major vigente y defaults de seguridad; CVEs recientes de todas las deps directas antes de fijar versión.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
