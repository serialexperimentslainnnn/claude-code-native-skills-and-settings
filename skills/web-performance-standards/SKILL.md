---
name: web-performance-standards
description: Use when browser performance must be measured and defended as a budget — Core Web Vitals LCP, INP and CLS thresholds, the web-vitals JavaScript library, Chrome UX Report (CrUX) and the CrUX API, PageSpeed Insights, real user monitoring at the 75th percentile, Lighthouse CI with lighthouserc.js and budget.json performance budgets, a performance budget that fails the build, WebPageTest and its filmstrip and waterfall, DevTools Performance panel traces, Long Animation Frames API, long tasks and main-thread blocking, Total Blocking Time, Speed Index, Time to First Byte, JavaScript bundle cost and hydration cost, layout shift attribution and sources, content-visibility, requestIdleCallback and scheduler.yield, third-party script cost, or justifying performance work with conversion and bounce-rate data.
---

# Web performance standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the experience measured in a real user's browser**: which metric is collected,
with which threshold, at which percentile, who decides with it and which gate breaks the build when
the budget is exceeded. It covers performance budgets, Core Web Vitals, field and lab
measurement, JavaScript cost, visual stability, main-thread work and the
business justification of performance work.

Triggers: Core Web Vitals, LCP, INP, CLS, FID (retired), TTFB, FCP, TBT, Speed Index,
`web-vitals`, `onLCP`/`onINP`/`onCLS`, CrUX and the CrUX API, PageSpeed Insights, Search Console
(the Core Web Vitals report), Lighthouse, Lighthouse CI, `lighthouserc.js`,
`budget.json`, `assertions`, WebPageTest, the DevTools *Performance* panel, *Long Animation
Frames* (LoAF), `PerformanceObserver`, `longtask`, `layout-shift`, `element` timing,
`scheduler.yield()`, `requestIdleCallback`, `content-visibility`, `contain-intrinsic-size`,
JS weight budget, request count, hydration cost, third-party *script*
cost, 75th percentile, p75/p95, RUM.

**Thesis of this skill**: **performance is a budget that is agreed and defended in CI,
not a later optimisation.** Without a number agreed in writing, any regression is
negotiable and they all get approved one by one until the site is slow. With a budget, the
conversation stops being aesthetic ("it feels a bit slow") and becomes binary: **it passes or
it breaks the build**. Corollary: **the lab does not decide** (§2.3). The field decides, at the
75th percentile, on real devices. Second corollary: **a score is not an
experience** — chasing Lighthouse 100 is replacing the goal with its indicator.

**Not applicable**: see `frontend-web-platform-standards` (**the platform mechanism is theirs**:
`preload`/`preconnect`/`fetchpriority`, `defer`/`async`, `font-display` and *subsetting*,
`srcset`/`<picture>`/AVIF/`loading="lazy"`, `content-visibility` as a CSS feature, the
choice of *bundler* and its configuration, and the *bundle* size limits the build imposes.
**Here the budget those mechanisms must meet and the measurement that proves
they meet it** — which `preload` to add is theirs, **whether field p75 LCP improved is
ours**), `frontend-frameworks-standards` (the framework, the rendering model — CSR/SSR/
islands/RSC — and routing are theirs; **here their measurable consequences**: hydration as a
main-thread cost and its effect on INP, the cost of a client navigation),
`accessibility-standards` (**sibling skill**: they cross at `prefers-reduced-motion` — there a
conformance criterion, here a rendering saving — and at perceived speed; the
WCAG criteria and legal conformance are theirs), `caching-cdn-standards` (**HTTP caching,
the CDN and purging are theirs**: `Cache-Control`, `s-maxage`, `stale-while-revalidate`, cache
keys, *origin shield*, `Cache-Status`. **Here only the effect measured on the client**: a
`Cache-Status: hit` that does not move field p75 TTFB has improved nothing),
`observability-standards` (the telemetry platform: collectors, storage,
retention, sampling, dashboards and alerts. **Here which real-user metric is collected and at
which percentile the decision is made**), `sre-practice-standards` (**an important boundary**: SLOs,
*error budget*, reliability and availability of the **service in production** are theirs —
server latency included. **Here the experience perceived in the browser**: the server
can meet its p99 SLO and the user still see a blank page at 4 s because
of the JavaScript. Two numbers, two owners, no collision),
`performance-engineering-standards` (**the general methodology for profiling and optimising
*backend* and systems**: USE/RED, *flame graphs*, CPU and memory profiling, bottleneck analysis
in the server, the database and the operating system. **Here only the browser and
the real user**. The exact boundary: **the TTFB is the contact point** — how the
server response time is reduced is theirs; **that this TTFB goes into the LCP and how much it weighs
in the field p75 is ours**), `testing-qa-standards` (load and stress scripts — k6,
Gatling, Locust, JMeter — and the test strategy are theirs; here the browser measurement),
`api-design-standards` (the contract and pagination; here the measured cost of an
oversized response) and `cicd-standards` (the *pipeline*; **here which gate to put on it**, §4),
`design-systems-standards` (**the component contract and the governance of the system are theirs**;
here **the weight that system adds to the bundle and the cost of its dependencies** — a design
system is one of the biggest sources of unused JavaScript, and the budget is defended here),
`cms-jamstack-standards` (the CMS and its modelling are theirs; here **the measured cost of its images
and its third-party scripts**, which usually dominates the LCP of a content site),
`webgl-webgpu-standards` (**they are two different budgets and they do not get mixed**: here
the Core Web Vitals and the load budget; there **the frame budget and the GPU cost**.
A canvas can run at 60 fps and ruin the page's INP, or the other way round: neither metric
predicts the other), `pwa-standards` (the *service worker* cache radically changes
repeat-visit metrics — **measuring only the first visit hides what a PWA does**, and
a badly configured cache serves an old version fast, which is not an improvement).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

### 2.1 Current Core Web Vitals and their thresholds (verbatim)

**There are three, and all three are in the *Stable* state.** web.dev, verbatim: *"The Core Web Vitals
are at the following lifecycle stages: LCP : Stable CLS : Stable INP : Stable"*.

| Metric | Measures | Good | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | Loading | ≤2500 ms | >4000 ms |
| **INP** (Interaction to Next Paint) | Interactivity | ≤200 ms | >500 ms |
| **CLS** (Cumulative Layout Shift) | Visual stability | ≤0.1 | >0.25 |

Verbatim from web.dev, unreformulated:

> *"Largest Contentful Paint (LCP): measures loading performance. To provide a good user
> experience, LCP should occur within 2.5 seconds of when the page first starts loading.
> Interaction to Next Paint (INP): measures interactivity. To provide a good user experience,
> pages should have a INP of 200 milliseconds or less. Cumulative Layout Shift (CLS):
> measures visual stability. To provide a good user experience, pages should maintain a CLS
> of 0.1. or less."*

> *"To ensure you're hitting the recommended target for these metrics for most of your users,
> a good threshold to measure is the 75th percentile of page loads, segmented across mobile
> and desktop devices. Tools that assess Core Web Vitals compliance should consider a page
> passing if it meets the recommended targets at the 75th percentile for all three of the
> Core Web Vitals metrics."*

"Poor" thresholds verbatim: INP — *"An INP above 500 milliseconds means a page has poor
responsiveness."* CLS — *"Good CLS values are 0.1 or less. Poor values are greater than
0.25."* LCP — the *Defining the Core Web Vitals metrics thresholds* table gives **≤2500 ms**
(good) and **>4000 ms** (poor).

**FID is retired.** web.dev, verbatim: *"A stable metric can be retired and replaced by
another metric that addresses the problem area more effectively. This is exactly what
happened to FID as INP became a stable Core Web Vital metric in 2024."* **Any guide,
dashboard or alert still measuring FID is expired** — and there are many. INP is not "a better FID":
FID only measured the input delay of the **first** interaction; INP measures **the whole cycle
up to the next paint** across **all** the interactions in the life of the page, and it is the
metric that is failed most often.

**Stability of the set**: verbatim from web.dev, *"Stable Core Web Vitals metrics won't
change more than once per year. Any change to a Core Web Vital will be clearly communicated
in the metric's official documentation, as well as in the metric's changelog."* **As of Aug 2026
there is no record of a new metric announced nor of a threshold change** — but it is exactly the fact
that expires (§8): check the lifecycle stage (*experimental* / *pending* / *stable*) before
pinning anything.

**Supporting metrics, which are NOT Core Web Vitals** and are not used as targets: TTFB and FCP
(they diagnose LCP: slow server response and render-blocking resources,
respectively) and **TBT**, which web.dev describes as a **lab** metric useful for
detecting interactivity problems that affect INP. They are used **to diagnose**, never
to declare success.

### 2.2 Tooling

| Use | Default | Verified version / licence | Note |
|---|---|---|---|
| RUM in production | **`web-vitals`** | 6.0.1 — Apache-2.0 | `onLCP`/`onINP`/`onCLS` + the *attribution build* to know **which element** |
| Public aggregated field data | **CrUX / the CrUX API** and PageSpeed Insights | Google service | Rolling 28-day window, p75 |
| Reproducible lab | **Lighthouse** | 13.4.1 — Apache-2.0 | Diagnosis and relative comparison only |
| CI gate | **Lighthouse CI** (`@lhci/cli`) | 0.15.1 — Apache-2.0 | Active repo; last verified *push* 27 Mar 2026 |
| Deep load analysis | **WebPageTest** | ⚠ **PolyForm Shield License 1.0.0** | **It is not free software** (§2.4) |
| Main-thread profiling | DevTools *Performance* + LoAF | Browser | What explains a bad INP |

### 2.3 Field vs. lab: **the lab does not decide**

| | Field (RUM, CrUX) | Lab (Lighthouse, WebPageTest) |
|---|---|---|
| What it is | What happened to real users | A simulation under fixed conditions |
| What it is for | **Deciding**: pass or fail | **Diagnosing**: why and what to fix |
| INP | It is measured (it needs a real interaction) | **It is not measured** — there is no user interacting |
| Variability | Device, network, location, cache, route | Controlled, reproducible |

**Hard rules**:
- **A lab metric never settles a debate about whether the site is fast.** It settles the
  debate about which resource blocks rendering.
- **INP does not exist in the lab.** Lighthouse gives **TBT** as an approximation; TBT and INP
  correlate badly. Anyone claiming "we improved INP" while showing a Lighthouse run has not
  measured it.
- **The lab simulates a device; the field has the device.** If the lab
  does not emulate a slow CPU and a mobile network, it measures a world that does not exist (§6.1).
- Divergence between CrUX and your own RUM is **normal and expected** (different populations, sampling
  and windows). **It does not get "fixed": it gets explained.** You decide with **one** of the two,
  declared beforehand.

### 2.4 Status and licences — two verified warnings

- **WebPageTest is not open source.** Its raw `LICENSE.md` says: *"Licensed under the
  PolyForm Shield License 1.0.0"* (Catchpoint Systems Inc.). PolyForm Shield is
  **source-available with an anti-competition clause**, not a free licence. Besides, the
  `catchpoint/WebPageTest` repo had its last *push* on **19 Sep 2025** — nearly a year without
  activity as of Aug 2026. **Criterion**: using it as a diagnostic service, yes; **do not** pin it
  as a self-hosted dependency of a *pipeline* without going through legal review, and **do not**
  assume it is BSD/Apache as is repeated around.
- `lighthouse`, `@lhci/cli` and `web-vitals` are **Apache-2.0**, verified in their raw `LICENSE`
  files and in npm's `license` field. `lighthouse-ci` is **not archived** and still
  receives changes, but it **has 230 open issues**: it is not dead, nor is it attended to
  comfortably. Verify before betting the whole *pipeline* on it (§8).

## 3. The performance budget

**Without a budget no skill is worth anything.** The budget is a versioned file, reviewed
in PRs, with an **owner**. Three layers, and all three get declared:

### 3.1 Layer 1 — field targets (the ones that decide)

They are **always** expressed as *metric + percentile + segment + window*:

```
LCP p75 mobile (28 d, CrUX)   ≤ 2500 ms
INP p75 mobile (28 d, CrUX)   ≤ 200 ms
CLS p75 mobile (28 d, CrUX)   ≤ 0.1
```

**Mobile is the segment that rules**, unless the product is desktop by definition
(an internal tool, an operations dashboard). Desktop is measured the same but is not the target
that gets defended.

**The 75th percentile is not negotiable and the mean is forbidden** (§7). Reason: the distribution of
load times has a **long tail**. The mean is flattened by the bulk of fast sessions
— good devices, good network, warm cache — and **hides exactly the users who leave**. With p75 you
assert something checkable: *"3 out of 4 sessions are below this
number"*. The median (p50) lies for the same reason, more discreetly. If the product is also
critical, track p95 as a secondary tail metric.

### 3.2 Layer 2 — resource budget (the one that breaks the build)

Field targets take 28 days to move; **they do not work as a PR gate**. The gate is
a lab resource budget, which is deterministic. It is declared in
`budget.json` (Lighthouse format) or in the assertions of `lighthouserc.js`:

```json
[{
  "path": "/*",
  "resourceSizes": [
    { "resourceType": "script",     "budget": 170 },
    { "resourceType": "stylesheet", "budget": 60  },
    { "resourceType": "font",       "budget": 100 },
    { "resourceType": "image",      "budget": 300 },
    { "resourceType": "total",      "budget": 700 }
  ],
  "resourceCounts": [
    { "resourceType": "third-party", "budget": 10 },
    { "resourceType": "total",       "budget": 50 }
  ],
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 2500 },
    { "metric": "total-blocking-time",      "budget": 200  },
    { "metric": "cumulative-layout-shift",  "budget": 0.1  }
  ]
}]
```

**The numbers above are a template, not a truth.** How they really get set, in
order:
1. **Measure the current state** in the field, mobile p75. Without a baseline there is no budget.
2. **Measure the competitors** the user compares you with, in a comparable lab setup.
3. Set the budget **below the current state** (or below the best competitor
   if it is already met), and **never raise it without an explicit, signed decision**.
4. Budget **per route**, not global: the home page, the product page and the checkout flow
   have different budgets because they have different value.

**The JS budget is the one that matters.** A reference for reality, not for aspiration:
the **Web Almanac 2025** (*Page Weight* chapter, HTTP Archive) gives a median mobile home page of
**2,362 KB**, of which **632 KB of JavaScript**, 911 KB of images, 122 KB of fonts,
77 KB of CSS and 22 KB of HTML. **Declared discrepancy**: some reviews of the same edition
cite **697 KB** of JavaScript — probably desktop, or from a different chapter; the
2025 *JavaScript* chapter returned 404 during verification. **Use your own measured figure,
not the almanac's**: the almanac is useful to know the industry is in a bad state, not to copy
its budget.

### 3.3 Layer 3 — the no-regression rule

Beyond the absolute threshold, **forbid worsening**: any PR that increases the JS weight
of a route beyond an agreed delta (e.g. +5 KB compressed) requires
explicit approval, with a written reason. It is what avoids death by a thousand cuts: **nobody
adds 400 KB at once; it gets added in forty PRs of 10 KB that all looked reasonable.**

## 4. CI gates

In increasing cost order. **A budget that does not break the build is a suggestion.**

1. ***Bundle* size at build time** (`size-limit`, `bundlesize` or the *bundler*'s own
   limit): over the artifact, in seconds. The concrete tool belongs to
   `frontend-web-platform-standards`; **the number it must meet is ours**.
2. **Lighthouse CI with `assertions`** against `budget.json`, over the 3-5 highest-value
   routes. Run **N≥3 passes and take the median**: a single Lighthouse pass has
   enough noise to make the gate unstable, and **an unstable gate gets disabled within a
   week**.
3. **A no-regression assertion** against the main branch (§3.3).
4. **A field check on deployment**: after publishing, watch LCP/INP/CLS from your own RUM
   over a short window (hours, not 28 days) to detect a severe regression before it
   enters CrUX.

**Requirements for the gate to survive**:
- **Deterministic**: fixed environment, fixed Chrome version, network and CPU emulated with the same
  factors on every pass.
- **With an owner**: if nobody is responsible for fixing it, it will be skipped with `--no-verify`.
- **With a registered exception path**: the exception is documented in the PR with a reason and an
  expiry date. **Silent exceptions, no.**

## 5. Security and third-party cost

- **Every third-party *script* is a performance dependency and a security dependency at once.**
  None enters without: a named owner, a measurement of its cost (bytes + main-thread
  time), a review date and a **removal plan**. A tag manager is a door
  left open for code to enter without a PR: **the contents of the tag manager are also
  part of the budget** and get audited on the same cadence.
- **`async`/`defer` reduces parser blocking, not CPU cost.** The third-party *script*
  still competes for the main thread when it runs, and that is where it wrecks
  INP.
- **RUM and privacy**: the `web-vitals` data sent to your own *endpoint* can
  carry URLs with identifying parameters and DOM selectors (in the *attribution build*).
  Sanitise before sending; see `privacy-engineering-standards`. Sampling does not exempt you from
  minimising.
- Third-party hardening (SRI, CSP, `Permissions-Policy`) belongs to
  `frontend-web-platform-standards`; **here only its measured cost**.

## 6. Where the time really goes

### 6.1 JavaScript cost dominates, and the device CPU rules

**The network can be bought; the user's CPU cannot.** An image byte gets downloaded and
painted. A JavaScript byte gets downloaded, **parsed, compiled, executed**, allocates
memory and triggers garbage collection — and all of that happens **on the main thread**, on a
mid-range phone that can be 4-6 times slower than the laptop of whoever wrote it.
Operational consequences:

- **Always measure with slow-CPU emulation** (*throttling* ≥4×) and a mobile network. Measuring on
  the team's laptop over fibre is measuring a user who does not exist.
- **Have a real mid-range device** for testing. It is the cheapest performance tool
  and the one that changes the most decisions.
- **INP is fixed on the main thread, not on the network.** Long tasks (>50 ms) chunked,
  yielding to the thread with `scheduler.yield()` where available (or `setTimeout(0)` /
  `requestIdleCallback` as an alternative), heavy work moved to a *Web Worker*, and **painting the
  response before doing the expensive work** (the user measures up to the next paint, not
  until the computation finishes).
- **INP diagnosis**: *Long Animation Frames* (LoAF) via `PerformanceObserver`, and the
  *attribution build* of `web-vitals`, which tells you **which element and which script**. Without
  attribution, optimising INP is guesswork.
- **Hydration is pure CPU cost** and is usually the peak that wrecks INP in the first
  second. The rendering model that generates it belongs to `frontend-frameworks-standards`;
  **here the number it produces**: how much main-thread time it costs and how much it raises TBT.

### 6.2 Visual stability (CLS) — the causes, not the symptoms

Five causes cover nearly everything:
1. **Images and videos without dimensions** (`width`/`height` or `aspect-ratio`) → the space is not
   reserved.
2. **Web fonts** that change metrics when they load (FOUT/FOIT) → reserve with fallback
   metrics.
3. **Content injected over what is already painted**: banners, cookie notices, ads,
   *toasts*. If it must appear, **reserve the space from the first paint**.
4. **Late-loading content that pushes** (recommendations, *widgets*): reserve a minimum
   height with `contain-intrinsic-size`.
5. **Animations on properties that trigger *layout*** (`top`, `left`, `width`, `height`)
   instead of `transform`/`opacity`.

**Rule**: a shift caused by a user action within the following 500 ms does not
count towards CLS. **Everything else does.** And CLS accumulates over **the whole life of the page**:
a shift in the footer after 30 s of *scrolling* counts the same as one at load time.

### 6.3 Rendering and the main thread

- **Long task = >50 ms.** They are measured with `PerformanceObserver` (`longtask`) and with LoAF.
- **`content-visibility: auto` + `contain-intrinsic-size`** for long off-screen
  sections: it avoids the *layout* and paint cost of what is not seen. Careful: badly sized
  it **causes CLS** — you pay with the other metric. The CSS feature belongs to
  `frontend-web-platform-standards`; **the decision to use it and the measurement of the trade-off
  are ours**.
- **Long lists**: virtualise beyond a few hundred rows. The threshold is measured, not
  assumed.
- **Do not animate properties that trigger *layout*.** `transform` and `opacity` go on the
  compositor.

### 6.4 Images, fonts and loading hints — the criteria only

The mechanisms (`srcset`, `<picture>`, AVIF/WebP, `loading="lazy"`, `font-display`,
*subsetting*, `preload`, `preconnect`, `fetchpriority`) belong to
`frontend-web-platform-standards`. **Here what decides a budget**:

- **The LCP image is never `loading="lazy"`.** It is the one-line mistake that ruins the most LCP.
  It is marked with `fetchpriority="high"` and, if it is discovered late, it gets a `preload`.
- **`preload` is a scarce resource**: every `preload` competes with the others. More than 2-3
  preloaded resources usually makes things worse instead of better. **Measure before and after,
  always.**
- **`preconnect` only to critical origins** (2-4 at most): each one costs a connection that
  may go unused.
- **Fonts**: an explicit budget for weight and for the number of families/variants. Every variant
  is a request and a CLS risk. `font-display: swap` trades FOIT for CLS — a
  trade-off decided with data, not out of habit.
- **Images**: a modern format, correct dimensions for the real slot and `srcset` by
  density and width. An image served at 3× its display size is pure weight.

### 6.5 Cache and server, seen from the client

- The **TTFB** is the floor of the LCP: there is no 2.5 s LCP with a 2 s TTFB. Server
  optimisation belongs to `performance-engineering-standards`; **the criterion here is that the TTFB
  goes into the LCP budget and is measured in the field, not in the server log**.
- **The cache is not measured by *hit ratio* but by its effect on the user**: the metric here
  is the p75 LCP of repeat visits versus first visits. The caching policy,
  purging and the CDN belong to `caching-cdn-standards`.
- **Segment the field data by first visit vs. repeat visit.** A pretty global p75 can hide
  a disastrous first visit; and the first visit is the one that converts.

## 7. Sustainability and prohibitions

- **Cadence**: re-check on the web the set of Core Web Vitals and their thresholds **every
  quarter** (§8). Review the budget **every time the state of the art or the
  competitor changes**, and at least once a year — a budget that is never reviewed ends up
  being either unattainable or irrelevant.
- **The budget is raised only by an explicit decision**, written, with a reason and with who
  approves it. Raising it "to unblock the release" with no record is how all
  budgets die.
- **Relationship with the business**: performance work is justified with **your own data**,
  not with third-party statistics. Method: correlate p75 LCP/INP per segment with the conversion
  rate, the bounce rate and the average order value **of your own site**, and — when
  possible — **measure it with an A/B experiment** in which the only variable is performance.
  The classic study (Deloitte, *Milliseconds Make Millions*, ~30 M sessions across 37 brands)
  reports that a 0.1 s improvement is associated with **+8.4% conversions in retail** and **+10.1%
  in travel**, with **+9.2% average order value in retail**. **A caveat almost nobody
  cites**: that "0.1 s improvement" was a composite of **First Meaningful Paint, Estimated Input
  Latency and Observed Load**, metrics that are **retired** today; and it is an observational study, not an
  experiment. It is useful for opening the conversation; it does **not** work as a promise of return.

Explicit prohibitions:

- ❌ **Optimising without measuring first.** Without a baseline there is no improvement, there is an
  opinion. Every performance task starts with the current metric and the target, written down.
- ❌ **Deciding with lab data only.** The lab diagnoses; **the field
  decides** (§2.3). In particular: **there is no lab INP**.
- ❌ **Chasing the Lighthouse score** instead of the real experience. A 100 with a field p75 LCP
  of 4 s is a useless 100. The score is an indicator; turning it into the target
  is Goodhart's law applied to the frontend.
- ❌ **Deciding with the mean (or with the median) instead of the 75th percentile.** The mean hides
  whoever leaves (§3.1).
- ❌ **Loading a whole library to use one function.** First: does the platform do it?
  is there an alternative an order of magnitude smaller? can just that part be imported with
  real *tree-shaking* (and verified in the artifact, not in theory)?
- ❌ **`loading="lazy"` on the LCP image** or on any above-the-fold image.
- ❌ **Adding a third-party *script* with no owner, no measurement and no removal plan** (§5).
- ❌ **A budget that does not break the build.** A warning in the CI console is not a budget.
- ❌ **A performance gate with a single Lighthouse pass**: the noise makes it unstable and
  an unstable gate ends up disabled.
- ❌ **Measuring performance only on the development machine** (powerful laptop, fibre, warm
  cache). CPU and network emulation, or a real device (§6.1).
- ❌ **Still measuring FID**, or keeping dashboards and alerts based on it (§2.1).
- ❌ **Treating performance as a final phase** ("we will optimise it before launch"). By
  then the decision that ruined it — the framework, the rendering model, the six
  marketing *scripts* — can no longer be reverted without redoing everything.

## 8. Mandatory web verification

Before pinning any fact from this document in a real project:

1. **Core Web Vitals**: `web.dev/articles/vitals` — **which metrics they are today, in which
   lifecycle stage (*experimental* / *pending* / *stable*) and with which thresholds**.
   Copy the thresholds **verbatim** from `web.dev/articles/lcp`, `/inp`, `/cls` and
   `/defining-core-web-vitals-thresholds`: an automatic summariser that rounds a number
   changes whether something passes or not. Also check whether any new metric has been announced — the
   page itself warns that a stable metric can be retired and replaced.
2. **Percentile and window**: confirm it is still **p75** and the CrUX window (rolling 28
   days) before writing a target.
3. **`web-vitals`**: current version and API (verified 6.0.1, Apache-2.0). Check whether the
   *attribution build* has changed how it is imported.
4. **Lighthouse / Lighthouse CI**: versions (verified `lighthouse` 13.4.1, `@lhci/cli`
   0.15.1, both Apache-2.0), the current format of `lighthouserc.js` and `budget.json`, and **the real
   state of the repository** — `lighthouse-ci` is not archived (last verified *push*:
   27 Mar 2026) but it has 230 open issues. Remember that **the GitHub releases feed
   is not the source of truth for a project**: cross-check with its official site before declaring
   either of them dead or alive.
5. **WebPageTest — mandatory licence check**: read `LICENSE.md` **raw**.
   Verified as of Aug 2026: **PolyForm Shield License 1.0.0**, source-available with an
   anti-competition clause, **not** free software; and the repo had had no *push* since
   **19 Sep 2025**. If it is going to be self-hosted or integrated into a product, take it through
   legal review.
6. **Industry data**: Web Almanac / HTTP Archive publish a new edition every year.
   **Declared and unresolved discrepancy**: the 2025 *Page Weight* chapter gives **632 KB**
   of JavaScript on the median mobile home page, while reviews of the same edition cite
   **697 KB**; the 2025 *JavaScript* chapter returned **404** during verification. Check
   the current edition and the exact chapter before citing any figure.
7. **Declared gap**: no figure for the percentage of sites passing all three CWV has been
   verified in a primary source (43% INP failure and 48% passing on mobile circulate, all from
   secondary sources). **Do not use without checking against CrUX / the public Chrome
   report.**
8. **Declared gap**: the Deloitte study cited in §7 has not been read in its original PDF
   during this verification; the figures (+8.4% / +10.1% / +9.2%) and the caveat about the composite
   metrics come from summaries. **Cross-check against the report before using it in front of the
   business.**
9. **Diagnostic APIs**: the status and availability of *Long Animation Frames*,
   `scheduler.yield()` and `content-visibility` in the target browsers — support is
   checked in `frontend-web-platform-standards`, it is not assumed here.

If the web contradicts this document, **the web wins** — flag the discrepancy.
