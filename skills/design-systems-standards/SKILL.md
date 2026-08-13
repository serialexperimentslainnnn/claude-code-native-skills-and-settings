---
name: design-systems-standards
description: Use when a UI component library is shipped as a versioned product for other teams - design tokens as tokens.json with DTCG $type/$value, style-dictionary config, Tokens Studio, semantic vs literal token naming, theming with CSS custom properties, color-scheme and light-dark(), choosing between headless primitives (radix-ui, @base-ui/react, react-aria-components, @ark-ui/react, @headlessui/react) and full libraries (@mui/material, antd, @chakra-ui/react, @mantine/core, @carbon/react), shadcn/ui components.json and copied-in component code, component public API design (props vs composition, slots, asChild, render props, boolean prop explosion), .storybook/main.ts and *.stories.tsx, Storybook 10 and the Vitest addon, Chromatic or Percy or Lost Pixel visual regression snapshots, per-component axe checks, changesets and semver for a component package, breaking-change policy and codemods, design system adoption metrics, contribution and exception process, or deciding whether to build a design system at all.
---

# Design system standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Core axis**: a design system is a **product with an owner, a version and consumers**, not a folder
of components. If it has no named maintainer, no published version and no written breaking-change
policy, it is not a design system: it is **technical debt with a logo** and a pretty slide deck.

This skill decides **the component contract and the system's governance**: when to build one and
when not, what to build it on, how tokens are modelled, how a component's public API is designed,
how it is versioned, how it is tested and how its adoption is measured.

Triggers: `tokens.json` / `*.tokens.json` with `$type`/`$value`, Style Dictionary's
`config.json`/`sd.config.js`, shadcn/ui's `components.json`, `.storybook/main.ts`,
`*.stories.tsx`/`*.stories.ts`, `chromatic.config.json`, `.changeset/`, `packages/ui/` in a
monorepo, a UI library's `theme.ts`/`preset.ts`, imports of `radix-ui`, `@base-ui/react`,
`react-aria-components`, `@ark-ui/react`, `@headlessui/react`, `@mui/material`, `antd`,
`@chakra-ui/react`, `@mantine/core`, `@carbon/react`, theme custom properties, `color-scheme`,
`light-dark()`, component migration codemods.

**Not applicable**:
- `frontend-web-platform-standards` — **the browser platform is theirs**: which CSS and which APIs
  can be used (the Baseline policy), the loading model, CSP/Trusted Types, the global byte budget
  and the npm supply chain. Here the system **consumes** that policy; it does not re-decide it.
  `light-dark()` or `@layer` are used if they are allowed there.
- `frontend-frameworks-standards` — **it chooses the framework, the rendering model and the
  application's architecture**. Here the component as a **published unit and its contract**,
  including the cost of that component bringing `"use client"` or requiring hydration. Which
  framework renders it belongs there.
- `accessibility-standards` — **the WCAG 2.2 conformance criterion, correct ARIA, the audit and the
  accessibility statement are theirs**. Here the architectural consequence: **the system's component
  is where that criterion is implemented once** and from where it propagates. An audit finding is
  translated into a component change; the audit itself is ceded.
- `web-performance-standards` — Core Web Vitals, budgets and measurement. Here only the **weight of
  the component system itself** (JS per imported component, theme CSS) as an API design criterion.
- `typescript-standards` — **the language, `tsconfig.json`, prop typing, the npm package's bundling
  (`exports`, ESM/CJS, `sideEffects`) and its publication are theirs**. Here what the API must
  express, not how it is typed nor how it is published.
- `testing-qa-standards` — the language-agnostic test strategy and the *flaky* policy. Here what is
  tested in a published component (§4).
- `git-workflow-standards` — SemVer, Conventional Commits, changesets and CHANGELOG as mechanics.
  Here **what counts as a breaking change in a UI**, which is the part no tool decides.
- `cicd-standards` (the pipeline that publishes the package and runs the gates),
  `cms-jamstack-standards` (**reciprocal**: the design system provides the presentation layer; the
  CMS provides the content that layer displays — neither decides for the other),
  `privacy-engineering-standards` (consent in form components), `mobile-standards` (native and
  cross-platform components), `observability-standards` (usage telemetry; here only which adoption
  metric matters).

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).
> Versions and licences read from the npm registry and the raw `LICENSE` as of **Aug-2026**.

### Decision 0: is a design system needed at all?

| Situation | Answer |
|---|---|
| **One product, one team** | **No.** Adopt an existing library and customise it with tokens. Your own system for a single consumer is cost with no benefit: the system's gain is **consistency across consumers**, and with only one there is nothing to be consistent with |
| Two products, same team | Not yet. A shared `ui` package in the monorepo, with no governance, no documentation site and no independent release |
| Three or more products, or two teams that do not coordinate daily | **Yes**, and with an assigned owner and an explicit maintenance budget |
| A strong brand of your own, a cross-cutting accessibility requirement, or recurring audits | **Yes**: the system is the only place where those requirements are paid for once |
| "We want it so everything looks the same" with nobody to maintain it | **No.** With no named maintainer, the system is abandonware within six months and worse than not having it, because people copy and fork it |

A design system is a **multi-year commitment**: maintenance, consumer support, migrations,
documentation and answering requests. If nobody has that work in their role, do not start.

### Decision 1: the base to build on

Three strategies, chosen on criteria, not on preference:

| Strategy | When | Real cost |
|---|---|---|
| **Adopt a full library** (Material, Ant, Chakra, Mantine, Carbon) and theme it | Internal product, back-office tool, short deadline, weakly differentiated brand | You marry its theme model and its majors. Leaving it is a total refactor. The design ends up looking like the library, not like your brand |
| **Build on accessible primitives** (headless) | **Default for your own branded system**. They give you behaviour, focus, keyboard and ARIA; you supply all the CSS | You maintain your styling layer and the glue. You depend on the primitive's rhythm |
| **Start from scratch** | Only if you have requirements no primitive covers **and** people capable of maintaining accessibility for dialogs, menus, comboboxes and tables | Reimplementing focus, `aria-activedescendant`, portals, positioning collisions and keyboard navigation is **person-years** of work that is always underestimated. It is the most expensive decision and the one most often taken by mistake |

**Hard rule**: do not reimplement a `Dialog`, `Menu`, `Combobox`, `Select`, `Tooltip`, `Popover` or
`Tabs` from scratch. They are the components where accessibility and focus management fail silently
and where the audit always lands.

### Headless primitives (status as of Aug-2026)

| Library | Version | Licence | Criterion |
|---|---|---|---|
| **Base UI** (`@base-ui/react`) | **1.6.0** | **MIT** | **Default for new React.** Dedicated team (authors of Radix, Floating UI and MUI), stable API since 1.0, composition via *render prop* instead of `asChild`, and it covers the combobox and multi-select Radix lacks. **Watch the package**: the old `@base-ui-components/react` is frozen at `1.0.0-rc.0` — the published name is `@base-ui/react` |
| **Radix Primitives** (`radix-ui`) | **1.6.7** | **MIT** (copyright **WorkOS**) | Still the most widespread base and not abandoned, but its cadence dropped after the WorkOS acquisition. **A solid base for what already exists; not the obvious choice for greenfield.** Do not migrate for fashion: there is no urgency |
| **React Aria Components** (`react-aria-components`) | **1.20.0** | **Apache-2.0**, not MIT | The most rigorous accessibility and internationalisation implementation (Adobe): keyboard, touch, RTL, `Intl`. Choose it when accessibility and i18n are a contractual requirement. More verbose and with more concepts of its own |
| **Ark UI** (`@ark-ui/react`) | **5.38.0** | **MIT** | The only one with real **multi-framework** parity (React, Vue, Solid, Svelte) on top of state machines. Choose it if the system must serve products on different frameworks — which is the situation that usually forces a design system in a large company |
| **Headless UI** (`@headlessui/react`) | **2.2.10** | **MIT** | Small, closed scope, meant to accompany Tailwind. Enough for a handful of components; **insufficient as the base of a complete system** |

### shadcn/ui is not a dependency

`shadcn` (CLI **4.16.1**, MIT) **copies code into your repo**. It does not appear in `package.json`
as a component library: it appears as your own files. Consequences to accept in writing before using
it:

- **You are the maintainer** from minute one. There is no `npm update` bringing accessibility fixes
  or behavioural patches: you have to go read upstream and apply them by hand, component by
  component.
- **Updates are manual diffs.** If you have modified the component (which is why you copied it),
  upstream and your version diverge and reconciliation is human work every time.
- In exchange: zero abstraction layer, total control of markup and styles, and **no dependency that
  can change licence or direction**. For your own branded system it is a legitimate starting point —
  **as scaffolding, not as the system**.
- If used: **version the result as your own package** with its changelog, and record which upstream
  revision each component came from. Copying without leaving a trace of provenance is what turns
  this into debt.
- Verified change (Jul-2026): **shadcn/ui adopts Base UI as the default for new projects**, with
  Radix still supported and an explicit recommendation **not to migrate** existing work as a matter
  of course.

### Full libraries (if Decision 1 was "adopt")

| Library | Version | Licence | Cost / lock-in note |
|---|---|---|---|
| **Material UI** (`@mui/material`) | **9.2.0** | MIT | The core is MIT, but **MUI X (advanced data grid, range pickers, charts, tree view) is commercial and paid per developer**. Verified: **from 2026-04-08 MUI X moves to a per-application licence** (single-app vs. multi-app) and raises prices; the Enterprise plan is always multi-app with a **minimum of 15 seats**. If your roadmap includes a serious data table, **that is a budget line**, not a detail |
| **Ant Design** (`antd`) | **6.5.3** | MIT | A very distinctive aesthetic and hard to depersonalise; documentation and ecosystem with a strong bias towards the Chinese market |
| **Chakra UI** (`@chakra-ui/react`) | **3.36.1** | MIT | v3 rewritten on top of Ark UI. A good balance, but the v2→v3 jump was a real migration: **count the historical churn before committing** |
| **Mantine** (`@mantine/core`) | **9.5.1** | MIT | Very broad ready-to-use coverage. Effective dependence on a single main maintainer: that is the risk to name |
| **Carbon** (`@carbon/react`) | **1.113.0** | **Apache-2.0**, not MIT | IBM's system, very complete and accessible, but **its visual language is IBM's brand**: adopting it is adopting their aesthetic |

**Do not mix two full libraries** in the same product: you duplicate tokens, themes, portals, focus
management and weight, and no team manages to keep both coherent.

### Tokens and documentation

| Piece | Choice | Status as of Aug-2026 |
|---|---|---|
| Token format | **DTCG** (`$value`, `$type`, `$description`) | First stable version: **2025.10**. **Note**: it is a W3C *Community Group Report*, **not a W3C Standard and not on the standards track**. The later drafts at `designtokens.org/tr/drafts` declare themselves not implementable |
| Transformation to platforms | **Style Dictionary** | **5.5.0**, licence **Apache-2.0** (not MIT) |
| Authoring from design | **Tokens Studio** for Figma | **A commercial product with a free plan** (Starter, includes Git sync); automation, multi-file and the Studio platform are paid. **Verify pricing and limits on their site before committing** |
| Living documentation | **Storybook** | **10.5.6**, MIT. Still the default because of the ecosystem. Alternatives: **Ladle** (React + Vite, much faster, no addon ecosystem) and **Histoire** (Vue/Svelte; its `.story.vue` format **is not CSF**, so leaving it means rewriting the stories) |
| Visual regression | See §4 — it is the system's real cost line |

## 3. Structure and conventions

### Tokens: semantics versus literal value

The distinction that decides whether the system survives a redesign:

| Layer | Example | Who consumes it |
|---|---|---|
| **Primitives** (literal value) | `color.blue.600`, `space.4`, `font.size.14` | **Only the semantic layer.** A component using this directly is a bug |
| **Semantic** (intent) | `color.action.background`, `color.text.muted`, `space.stack.md`, `color.feedback.danger.border` | Components and applications |
| **Component-level** (optional) | `button.primary.background` → an alias of a semantic token | Only the component. Useful in large systems; **unnecessary in small ones** |

- `color-primary-600` is a **value**: it says what it is. `color-action-background` is **semantics**:
  it says what it is for. In a redesign, the first one must be found and replaced in every consumer;
  the second changes once in the definition. **That second layer is the entire return on the token
  system.**
- **A consuming application never references a primitive.** If it needs one, a semantic token is
  missing: the request is served by adding it, not by opening the primitive scale to the public.
- Closed and small scales: spacing on a defined progression (not arbitrary values), typography with
  a counted number of sizes, enumerated radii and shadows. **A scale with 40 values is not a scale:
  it is a free palette with extra bureaucracy.**
- Tokens are **the contract with design** and live in a versioned file, not in Figma "and also" in
  the code. A single source of truth, exported to the rest. If Figma and the code can diverge, they
  already have.
- The token pipeline is a **reproducible build** (Style Dictionary → CSS custom properties, JS/TS,
  iOS/Android where applicable) and runs in CI. Tokens copied by hand between platforms is the
  guaranteed route to incoherence.

### Themes and dark mode

- Themes are implemented with **CSS custom properties** redefined per scope. No two full stylesheets
  and no reloading CSS when switching theme.
- `color-scheme` declared (`light dark`) so that native controls, scrollbars and forms follow the
  theme. It is always forgotten and it is what gives away a half-finished dark mode.
- `light-dark()` halves the colour declarations **if your Baseline policy allows it** (that policy
  belongs to `frontend-web-platform-standards`; **verify it, do not assume it**).
- **Respect `prefers-color-scheme` by default** and allow an explicit, persisted user override.
  Forcing a theme while ignoring the system preference is a product decision that must be justified.
- A theme **cannot change semantics**: `color.feedback.danger` still means danger in every theme. If
  a theme reassigns meanings, it is not a theme: it is another system.
- Contrast verified **per semantic combination in each theme**, not once in light mode. The
  conformance criterion belongs to `accessibility-standards`; the obligation to check it in both
  themes belongs here.

### A component's API is a public contract

Once published, changing it costs every consumer. It is designed the way an HTTP API is designed.

- **Composition before configuration.** `<Card><Card.Header/><Card.Body/></Card>` scales; a `Card`
  with `title`, `subtitle`, `icon`, `action`, `footer`, `variant`, `dense`, `bordered` does not: it
  grows with every request until it is unmaintainable.
- **Twenty boolean props are a design failure, not a flexible API.** Every boolean multiplies the
  possible states (2^n) and none of them is tested. Signs that the component must be broken into
  parts or the booleans replaced by an enumerated variant prop: mutually exclusive booleans
  (`primary`, `secondary`, `danger` → `variant`), booleans that only apply if another is true, and
  props that exist for a single consumer.
- **Slots** for the content the consumer must control; props for what the system must decide. If the
  consumer needs to put arbitrary markup where there is no slot, the outcome will be a CSS hack
  against your internal classes — and that hack will break in your next patch.
- Root element polymorphism (the `render` prop in Base UI, `asChild` in Radix, `as`) so as not to
  force a `<div>` where an `<a>` or an `<li>` belongs. Without it, correct semantics becomes
  impossible.
- **Pass the remaining props to the underlying element** (`...rest`) and **accept `ref`**: a
  component that does not let you set `id`, `aria-*`, `data-*` nor get the node forces a fork.
- **Internal classes and nodes are not public API.** Document explicitly what is public (props,
  slots, tokens, `data-*` state attributes) and what is not. Without that written boundary, any
  internal refactor is a de facto breaking change because somebody was styling
  `.ds-button__inner`.
- Forbidden: `style`/`className` as a universal escape hatch with no design: either there is a
  variant prop, or a slot, or a token. If it is still needed, see "escape route" in §7.
- Mandatory states on every interactive component: rest, hover, **focus-visible**, active, disabled,
  loading, error. A component with no visible focus state is not finished.
- **No business logic and no fetching inside a system component.** A `UserAvatar` that calls your API
  stops being reusable and drags the HTTP client into every consumer.
- The API is written **before** implementing and reviewed with at least one real consumer. Designing
  in the abstract produces components nobody uses the way you expected.

### Organisation

- **A published package**, not a directory shared by relative path: `@org/ui`, versioned, with
  `@org/tokens` separate if there are non-web consumers. Tokens are published separately because
  their lifecycle is slower and their audience broader.
- **Granular exports** and correct `sideEffects`: importing a button cannot drag in the whole
  package. A system that can only be imported wholesale imposes its full weight on every consumer.
- Explicitly mark the components that require the client (`"use client"`) and **keep as much as
  possible without it**: in a system consumed by RSC apps, a `"use client"` in the index
  contaminates the entire tree.
- The system's CSS in its own layer (`@layer`) so the consumer can win specificity without
  `!important`.

## 4. Quality and testing of a design system

A published component is tested **more** than an application one: its failure is multiplied by the
number of consumers. Gates in increasing order of cost, each one breaks the build:

1. **Typecheck and lint** of the package (language rules: `typescript-standards`).
2. **Frozen public API**: a report of the public surface (exported props, types) versioned in the
   repo, whose unreviewed change fails. It is the only gate that catches an accidental breaking
   change **before** publishing it.
3. **Component tests** (Vitest + Testing Library, or Storybook's Vitest addon since v9/10, which
   **replaces the old `@storybook/test-runner`**): keyboard interaction, loading, error, empty and
   disabled states. Stories are the test cases: **one story per state**, not one "playground" story
   with controls.
4. **Per-component accessibility**, automated (axe on every story). It covers ~30-40% of the
   criteria: **the rest is manual review and is the responsibility of `accessibility-standards`**. A
   green axe gate is not a conformance statement and asserting it is a legal risk, not just a
   technical one.
5. **Contract tests with consumers**: build at least one real consuming application against the
   candidate version before publishing. That is what turns "I think it does not break" into a fact.
6. **Visual regression** — see below.

### Visual regression: choose with the cost in front of you

It is indispensable (CSS has no types: nothing else detects that a token change moved a padding in
30 components) and it is **the system's recurring cost line**. It is billed per *snapshot* = story ×
viewport × browser × theme, so **the cost grows multiplicatively** and the bill always surprises.

| Option | Model | Verified as of Aug-2026 |
|---|---|---|
| **Playwright screenshots** / BackstopJS | Free, self-hosted | Cost = maintaining the reference images and the noise between environments. **Requires a runner with a pinned OS** (container), or antialiasing produces eternal false positives |
| **Lost Pixel** | Open source + optional cloud | Free plan cited at **7,000 snapshots/month** — the most generous of those compared. **Confirm on their site** |
| **Chromatic** | SaaS, coupled to Storybook | **5,000 snapshots/month free**; once exhausted, *"testing and review will pause until the next month"* — **there is no overage: it stops**. Paid from ~$149-179/month depending on the source (**the sources disagree**). Stable Chrome only; Firefox/Safari in beta. TurboSnap reduces the volume |
| **Percy** (BrowserStack) | SaaS | ~5,000 screenshots/month free; billed **per screenshot** (page × browser × width): 2 pages × 2 browsers × 3 widths = **12**. Do the multiplication before signing |
| **Applitools** | Enterprise, no public pricing | AI-based visual comparison, the most mature at noise reduction. No public rate = negotiation and lock-in |

Criterion: start with the free runner in a pinned container and **only** pay once the noise is
costing you more hours than the invoice. And as soon as you pay, **limit the number of stories with
snapshots**: not every story needs a capture in four browsers.

## 5. Security of the system

- The system is **a dependency of all your products at once**: a compromise of its package is a
  compromise of the whole portfolio. npm supply chain hygiene belongs to
  `frontend-web-platform-standards`; here the consequence: publication with **trusted
  publishing/OIDC**, no long-lived tokens, a minimum of maintainers with publish permission and
  mandatory 2FA.
- **No prop of a published component renders raw HTML.** If a `RichText` is unavoidable, sanitisation
  goes **inside** the component and is neither optional nor disableable by prop, because the consumer
  will disable it. Sinks and sanitisation live in `frontend-web-platform-standards`.
- A system component does not compose destination URLs without validating the scheme: a `<Link href>`
  that accepts `javascript:` is an XSS distributed to every consumer.
- Zero hidden telemetry in the components: a design system that phones home from a customer's app is
  a privacy incident, not an adoption metric (§7 explains how to measure without it).
- The system's SVG icons and illustrations: **sanitised at build time** (SVG can carry `<script>` and
  handlers). Third-party SVGs are never injected at runtime.
- Keep the system's own dependencies to a minimum: every one of them is inherited by all consumers
  and none of them chose it. Adding a dependency to the system requires a written justification.

## 6. Performance and operability

- **Per-component weight measured and published**, not just the package's total weight: the consumer
  needs to know what importing the date picker costs them. Without verified real tree-shaking, the
  system imposes its worst case on everyone.
- The system's own budget: a component dragging a heavy dependency (editor, charts, date mask) is
  published in a **separate subpath** and its cost documented. Global thresholds belong to
  `web-performance-standards`.
- Theme CSS: one custom-properties stylesheet, not one per component loaded at the wrong time. A
  theme change must not cause a flash of unstyled content nor a global recalculation.
- **The documentation site is production**: if Storybook is down or out of date, the system does not
  exist for its consumers. It is deployed by CI on every merge, with the version visible in the
  documentation itself.
- Useful instrumentation: which version of the system each application uses (monorepo lockfiles or
  querying the repos), not runtime telemetry.

## 7. Sustainability, governance and prohibitions

### The system is a product: owner, version, consumers

- **A named owner with allocated time.** Without that, do not start (§2, Decision 0).
- **Strict SemVer on the package.** In a UI, the following count as **breaking**: removing or
  renaming a prop, changing a prop's default, changing the root HTML element, removing a token, and
  **every visual change a consumer may have compensated for** (a padding, a line height). That last
  one is what almost nobody versions correctly: if the visual change forces someone to touch their
  CSS, it is a major.
- **A written breaking-change policy**: breaking changes are grouped into planned majors, with a
  deprecation period of **at least one major** during which the old API keeps working and warns
  (`console.warn` in development, an `@deprecated` mark in the types).
- **A codemod is mandatory** for every mechanical migration in a major (prop renames, import
  changes, token replacements). Publishing a major without a codemod is transferring your work to N
  teams and guaranteeing half of them stay on the old version. The rule: **if the change can be
  automated, it is automated; if it cannot, it is documented with a before/after example per case.**
- A declared support window: which majors receive security and accessibility patches and until when.
- A changelog per component, not just per package: the consumer cares whether the `Select` changed,
  not about reading 200 lines.

### Adoption and governance

- **Adoption is measured**, or there is no way to know whether the system is any use: (a) the
  percentage of each application's components that come from the system versus local ones, (b) the
  number of applications on the current version and on earlier ones, (c) the number of CSS
  *overrides* against internal classes — **this is the most honest metric**: every override is a
  place where the system did not cover the case.
- **A written contribution process**: who proposes, who reviews, how long it takes and what happens
  if nobody answers. A contribution process whose response time is "when we can" produces forks, and
  the fork is the death of the system.
- **Exceptions are recorded, not banned.** An uncovered case is solved locally, labelled as an
  exception and **reviewed every quarter**: if three teams did the same thing, that is a missing
  component, not three deviations.
- **A system with no escape route gets avoided instead of used.** If the consumer cannot solve their
  case — via slot, token, variant or composition with the primitives — they do not abandon the case:
  they abandon the system, copy the component and fork it. So **the escape route is designed on
  purpose**: primitives exposed for composition, `@layer` so their CSS wins without `!important`,
  and a channel to request the missing variant. Closing the door does not produce compliance: it
  produces copies outside your control.
- Maturity states per component, visible in the documentation: **experimental** (may break in a
  minor, marked as such), **stable** (under SemVer), **deprecated** (with a replacement and a date).
  Publishing everything as stable from day one prevents iteration.
- **Accessibility is solved once, here.** It is the system's strongest economic argument: focus,
  keyboard, ARIA and contrast are paid for in the component and collected in every consumer.
  Corollary: a system component with an accessibility failure is a **high-priority incident**,
  because it is deployed across all products at once. The conformance criterion belongs to
  `accessibility-standards`; the place where it is implemented is this one.

**FORBIDDEN:**
- ❌ Creating a design system for **a single product and a single team**. Use a library and theme it.
- ❌ Starting a system without a **named maintainer**, without a published version and without a
  breaking-change policy. That is not a system: it is debt with a logo.
- ❌ Reimplementing dialogs, menus, comboboxes, selects, tooltips or tabs from scratch when
  maintained accessible primitives exist.
- ❌ A consuming application referencing a **primitive token** (`color.blue.600`) instead of a
  semantic one. And ❌ having only a primitive layer: then you do not have a token system, you have
  constants.
- ❌ A component with twenty boolean props, or with mutually exclusive booleans instead of an
  enumerated variant.
- ❌ Components that do not accept `ref`, do not forward `...rest`, do not allow `aria-*`/`data-*` or
  force the root element. They force a fork.
- ❌ Business logic, `fetch`, global application state or product copy inside a system component.
- ❌ Changing a component's appearance in a **patch** or a **minor** because "it is only a pixel".
- ❌ Publishing a major without a codemod for what is automatable nor a migration guide for the rest.
- ❌ Treating internal classes and nodes as if they were public API — and ❌ not documenting which
  ones are not.
- ❌ Mixing two full component libraries in the same product.
- ❌ Using shadcn/ui without accepting in writing that **maintenance and upstream reconciliation are
  yours**, and without recording which revision each component came from.
- ❌ A prop that renders unsanitised HTML, or sanitisation that can be disabled from outside the
  component.
- ❌ Declaring accessibility conformance because axe is green in CI.
- ❌ A system with no documented escape route; answering an uncovered case with "it is not
  supported".
- ❌ Asserting from memory the version, licence or pricing model of a UI library. Verified as of
  Aug-2026: **React Aria and Carbon are Apache-2.0**, **Style Dictionary is Apache-2.0**, **MUI X is
  paid and changed its licence model in Apr-2026**, and Base UI's stable package is `@base-ui/react`,
  not `@base-ui-components/react`.

## 8. Mandatory web verification

Before fixing anything, check online (the npm registry and Atom feeds
`https://github.com/OWNER/REPO/releases.atom` — **`api.github.com` returns 403 unauthenticated**; the
project's official site to cross-check, because **the GitHub feed is not the source of truth**; the
raw `LICENSE` for licences; the vendor's pricing page for cost):

1. **DTCG status**: is **2025.10** still the latest stable? Any new stabilised module? **Do not
   assert that a "W3C token standard" exists: it is a Community Group Report off the standards
   track.** Check on `designtokens.org` and the CG's blog.
2. **Style Dictionary** (still 5.x? full DTCG support?) and **Tokens Studio**: current pricing, what
   the free plan includes and what is lost when you exceed it.
3. **Primitives**: version and licence of `@base-ui/react`, `radix-ui`, `react-aria-components`,
   `@ark-ui/react`, `@headlessui/react`. **Confirm the published package name** before installing.
4. **Radix's cadence**: has it accelerated again under WorkOS, or is it still in low-speed
   maintenance? It is the variable that decides whether it is a valid base for greenfield.
5. **Full libraries**: version and licence of MUI, Ant, Chakra, Mantine, Carbon, and above all
   **MUI X's commercial model after the 2026-04-08 change** (real price per application and per
   seat).
6. **Storybook**: the current major, the status of the Vitest addon, and whether
   `@storybook/test-runner` is fully retired. Maintenance status of **Ladle** and **Histoire**.
7. **Visual regression**: prices and free-plan limits of Chromatic, Percy, Lost Pixel and Argos —
   **they change and secondary sources contradict each other**. Primary source, always.
8. **Advisories** for the libraries entering the system (`github.com/advisories`, osv.dev): a CVE in
   your component base is a CVE in all your products.

**Declared gaps as of Aug-2026** (do not fill from memory):
- **Exact price of MUI X Pro and Premium after 2026-04-08**: **not verified**. The official
  announcement confirms the date, the per-application licence and the 15-seat minimum for
  Enterprise, but **refers to the pricing page for the figures**. The ~$15/dev/month and
  ~$50/dev/month cited by aggregators are **from before the change**: do not use them.
- **Tokens Studio pricing** (Starter Plus, Essential, Organisation) and the exact free-plan limits:
  **not verified** against a primary source (a secondary source cites ~€39/month for Starter Plus).
- **Lost Pixel's free plan (7,000 snapshots/month)**: taken from a secondary source, **not
  verified** on their site.
- Current maintenance status of **Histoire** and **Ladle**: **not verified** beyond third-party
  download figures.
- Real usage share of each primitive and library: **not verified** — the download figures in
  circulation come from third-party comparisons, not from the registry.
- Whether `light-dark()` is within your Baseline policy: **that is
  `frontend-web-platform-standards`' data, and they mark it as not verified**. Check it before using
  it.

**Declared discrepancies**:
- **Base UI**: the package `@base-ui-components/react` is still published and its `latest` is
  `1.0.0-rc.0` (modified Jul-2026), which leads people to believe Base UI never reached stable.
  **The official site and the registry agree that the current package is `@base-ui/react`, version
  1.6.0 (Jun-2026), MIT.** It is a literal case of "the old name lies": verify the package, not just
  the version.
- **Chromatic's entry price**: one source puts it at $149/month and another at $179/month (Starter,
  Jun-2026) with 35,000 snapshots. **Unresolved**; their pricing page wins.
- **Storybook comparisons**: several 2026 pages compare "Storybook 8" against Ladle and Histoire
  while the npm registry serves **10.5.6**. Those comparisons are out of date and their download and
  start-up figures are not reliable.
- **Radix**: the ecosystem describes it as "slowed down after the acquisition"; automated analysers
  mark it as "healthy" for publishing releases in the last three months. Both are true and they
  measure different things — look at the commit and closed-issue history, not the badge.

If the web contradicts this document, **the web wins** — flag the discrepancy.
