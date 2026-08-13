---
name: accessibility-standards
description: Use when digital accessibility is a conformance requirement — WCAG 2.1/2.2 Level A/AA success criteria, EN 301 549, the European Accessibility Act (Directive 2019/882), Spain's Ley 11/2023 and Real Decreto 1112/2018, ADA Title II web rule and Section 508, axe-core, @axe-core/playwright, jest-axe, Pa11y and pa11y-ci with .pa11yci, Lighthouse accessibility category as a CI gate, WAVE, VPAT and Accessibility Conformance Report, an accessibility statement page, keyboard-only and screen-reader testing with NVDA/JAWS/VoiceOver/TalkBack, accessible name computation, aria-hidden, tabindex, role and aria-* attributes, focus management in dialogs and SPA route changes, focus-visible and outline, prefers-reduced-motion and prefers-contrast, alt text, form labels and error messaging, data table headers, captions transcripts and audio description, PDF/UA tagged documents, or accessibility overlay widgets.
---

# Digital accessibility standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when you have to **decide whether something conforms** and **prove it**: which standard
and which level is required, which specific conformance criterion is being failed, how it is
tested, who signs the statement and what legal obligation sits behind it. Covers web content, web
applications, documents and email. The **conformance criterion** is what belongs to this skill.

Triggers: WCAG 2.1 / 2.2, levels A / AA / AAA, a success criterion number (1.4.3, 2.4.7, 2.5.8,
4.1.2…), EN 301 549, Directive (EU) 2019/882 (*European Accessibility Act*), Directive (EU)
2016/2102, Ley 11/2023, Real Decreto 1112/2018, ADA Title II, Section 508, VPAT / ACR,
accessibility statement, `axe-core`, `@axe-core/playwright`, `@axe-core/react`, `jest-axe`,
`pa11y` / `pa11y-ci` / `.pa11yci`, Lighthouse's *accessibility* category, WAVE, ARC Toolkit,
NVDA, JAWS, VoiceOver, TalkBack, Orca, accessible name, `aria-*`, `role`, `aria-hidden`,
`aria-live`, `tabindex`, `:focus-visible`, `outline`, `prefers-reduced-motion`,
`prefers-contrast`, `alt`, `<label>`/`aria-labelledby`, `<caption>`/`<th scope>`, captions,
transcript, audio description, PDF/UA, accessibility *overlay*.

**Thesis of this skill**: **accessibility is a requirement, not an enhancement.** It is not
prioritised against features: it *is* a feature. And in the EU it is, on top of that, a **legal
obligation whose deadline has already passed** — Directive (EU) 2019/882, art. 31.2, verbatim:
*"They shall apply those measures from 28 June 2025."* Operational corollary: **an accessibility
failure in production is a defect, with its bug and its regression test**, not a backlog task
tagged `a11y`. Second corollary, an uncomfortable one: **automation cannot close it** (§4.1) —
whoever signs conformance is a person who has tested with a keyboard and with a screen reader.

**Not applicable**: see `frontend-web-platform-standards` (**semantic HTML, CSS, browser APIs,
the loading model and build tooling are theirs** — which native element exists, how it is styled,
which *Baseline* supports `:focus-visible` or `prefers-contrast`. **Here, only the conformance
criterion**: what WCAG requires, at which level, how it is tested and who declares it. Choosing
`<button>` instead of `<div role="button">` is their decision; **requiring it** as conformance is
this skill's), `frontend-frameworks-standards` (the framework and its rendering and routing model
are theirs; **here the measurable consequences**: focus on route change in an SPA §3.5, the dialog
component that traps focus, the status announcement after a mutation), `design-systems-standards`
(**the right place to solve accessibility once is a design-system component**: the accessible
button, field, dialog and menu are built there and audited there — not on every screen. Its
governance, versioning and documentation are theirs; here the criterion that component must
satisfy), `web-performance-standards` (**sister skill**: they meet at `prefers-reduced-motion` —
here as a conformance criterion, there as a rendering cost — and at perceived speed; the budget
and Core Web Vitals are theirs), `grc-compliance-standards` (the regulatory framework, audit
evidence, the legal risk register and the relationship with the regulator; **here the technical
conformance criterion and its proof**), `mobile-standards` (native app accessibility:
`UIAccessibility`, `AccessibilityNodeInfo`, TalkBack/VoiceOver as platform APIs and each store's
guidelines are theirs; here the web and the WebView), `privacy-engineering-standards` (personal
data processing; here only the warning that a third-party *overlay* is a third party with access
to the DOM, §5.2), `api-design-standards` (service contracts; the human-readable error messages
the API returns are theirs, their accessible presentation is this skill's) and `cicd-standards`
(the *pipeline*; **here which gate to put on it**, §4.2), `technical-hiring-standards` (the design
of the selection process is theirs; **the conformance of its tooling and reasonable adjustments —
alternative format, extra time, an accessible screen-reader-testable exercise — are governed by
the criterion here**. Shared warning: **an inaccessible selection process discards candidates
before evaluating them**, and that is not a user-experience failure but a validity failure of the
measuring instrument), `webgl-webgpu-standards` (**a `<canvas>` is opaque to assistive
technology** — it has no structure, no text, no focus. The conformance criterion and the
requirement of an equivalent alternative are this skill's; **how the canvas content is implemented
and how it performs, theirs**), `i18n-standards` (a boundary with real, concrete overlap: the
correct `lang` attribute and text direction are **a conformance criterion here** — without `lang`
the screen reader mispronounces —, whereas **the choice of languages, the message catalogue,
pluralisation, regional formatting and the translation workflow are theirs**. Shared warning: **an
interface translated into an RTL language is not the same interface mirrored**, and text in other
languages expands — a component that only fits in English fails in both skills).

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

### 2.1 Target standard

| Decision | Default | Justifiable alternative |
|---|---|---|
| Technical standard | **WCAG 2.2 Level AA** | WCAG 2.1 AA if the contract/regulator cites it literally (ADA Title II, EN 301 549 V3.2.1) |
| Level | **AA as the operational target** | AAA only on specific criteria that add value (e.g. 1.4.6 enhanced contrast on critical content) |
| EU standard | **EN 301 549**, the version cited in the OJEU | — |
| Conformance document | Accessibility statement (EU) / **VPAT-ACR** (US market) | — |

**Why AA and not AAA**: WCAG itself says so — it is not project policy but the standard's. WCAG
2.2, §5.2.1 Conformance Level, Note 2, verbatim: *"It is not recommended that Level AAA
conformance be required as a general policy for entire sites because it is not possible to satisfy
all Level AAA success criteria for some content."* AA is the level that **every** legal standard
cited below references. AAA is applied **per chosen criterion**, never as a global goal.

**WCAG 2.2 is the Recommendation in force**: published on **5 October 2023**, with an update on
**12 December 2024**. It does not repeal the earlier ones — W3C, verbatim: *"WCAG 2.2 does not
deprecate or supersede WCAG 2.1, and WCAG 2.1 does not deprecate or supersede WCAG 2.0."* The only
substantive change relative to 2.1: **4.1.1 Parsing** appears in the WCAG 2.2 index as *"4.1.1
Parsing (Obsolete and removed)"*.

**WCAG 3.0 is NOT in force and you do not plan against it.** The draft is a *W3C Working Draft* of
**03 March 2026**, and its own "Status of This Document" says verbatim: *"This is a draft document
and may be updated, replaced, or obsoleted by other documents at any time. It is inappropriate to
cite this document as other than a work in progress."* In WCAG 3.0 the acronym changes meaning
(*W3C Accessibility Guidelines*) and the conformance model is different (bronze/silver/gold-style
levels instead of A/AA/AAA). **A vendor selling "WCAG 3.0 certification" in 2026 is selling smoke**
— there is no stable conformance model to certify against. Candidate Recommendation and
Recommendation dates: **gap, not verified against a primary source** (§8).

### 2.2 Legal obligation — what decides

**You do not choose the level: it is set by whichever law applies to the product.** First of all,
determine jurisdiction and sector.

| Framework | Scope | Technical standard | Date |
|---|---|---|---|
| Directive (EU) 2019/882 (EAA) | Products and services **for consumers** (private sector included) | EN 301 549 | **Applicable since 28-Jun-2025** |
| Directive (EU) 2016/2102 | **Public sector** websites and apps in the EU | EN 301 549 | In force |
| Spain — Ley 11/2023 | Transposition of the EAA | EN 301 549 | Title I applicable since 28-Jun-2025 |
| Spain — RD 1112/2018 | Spanish public sector | EN 301 549 | In force |
| US — Section 508 | Federal ICT | **WCAG 2.0 A and AA** | In force since 18-Jan-2018 |
| US — ADA Title II | State and local government | **WCAG 2.1 Level AA** | **26-Apr-2027 / 26-Apr-2028** |

**EAA (Directive (EU) 2019/882)** — verbatim quotes from EUR-Lex:
- Art. 31.1: *"Member States shall adopt and publish, by 28 June 2022, the laws, regulations
  and administrative provisions necessary to comply with this Directive."*
- Art. 31.2: *"They shall apply those measures from 28 June 2025."*
- Art. 31.3: *"By way of derogation from paragraph 2 of this Article, Member States may
  decide to apply the measures regarding the obligations set out in Article 4(8) at the
  latest from 28 June 2027."* (emergency communications).
- Art. 4.5, **the exemption most often invoked wrongly**: *"Microenterprises providing services
  shall be exempt from complying with the accessibility requirements referred to in paragraph
  3 of this Article and any obligations relating to the compliance with those requirements."*
  → **the exemption is for microenterprises providing SERVICES, not for microenterprises that
  manufacture products.** Do not apply it from hearsay: check it against the text.
- Art. 32.1 (transitional): *"Member States shall provide for a transitional period ending on
  28 June 2030 during which service providers may continue to provide their services"* using
  products lawfully used before the date. **It is not a general extension until 2030.**

**Spain**: the transposition is **Ley 11/2023, de 8 de mayo, de trasposición de Directivas de la
Unión Europea en materia de accesibilidad de determinados productos y servicios, migración de
personas altamente cualificadas, tributaria y digitalización de actuaciones notariales y
registrales** (BOE-A-2023-11022); its Title I transposes the EAA. Verified subsequent development:
**Real Decreto 143/2026, de 25 de febrero, por el que se crea y regula la Unidad técnica de apoyo
y coordinación de las autoridades de vigilancia en materia de requisitos de accesibilidad**
(BOE-A-2026-4520), which develops art. 28 of Ley 11/2023 — that is, **the enforcement machinery
already exists**, this is not an obligation without an authority behind it. **Real Decreto
1112/2018, de 7 de septiembre, sobre accesibilidad de los sitios web y aplicaciones para
dispositivos móviles del sector público** remains the one governing the public sector, with its
mandatory **accessibility statement** (§6.1). The amounts under the penalty regime of Ley 11/2023
and the exact deadlines of its transitional provisions: **gap, check in the consolidated BOE text**
(§8).

**EN 301 549**: the version carrying presumption of conformity is the one **cited in the OJEU**,
not the latest ETSI has published. Verified: **V3.2.1 (2021-03)** is the referenced one; there is
a draft **V4.1.0 (2025-11)** published by ETSI that aligns clauses 9, 10 and 11 with WCAG 2.2 and
adds Annex ZA (Directive 2016/2102) and a clause A.2 for Directive 2019/882. The European
Commission puts it verbatim: *"New versions of the WCAG or of EN 301 549 do not automatically
change the legal obligations."* **The publication date of a V4.1.1 in the OJEU is a gap: "October
2026" circulates in secondary sources, without primary confirmation** (§8). Practical consequence:
**build against WCAG 2.2 AA even if the cited standard is still 2.1 AA** — 2.2 is a superset
except for 4.1.1, and it avoids re-auditing when the citation changes.

**US — important correction**: the ADA Title II rule was published on **24 April 2024** with a
technical standard, verbatim from ada.gov: *"The Web Content Accessibility Guidelines (WCAG)
Version 2.1, Level AA is the technical standard for state and local governments' web content and
mobile apps."* **The compliance dates were extended**: ada.gov, verbatim: *"On April 20, 2026, the
Federal Register published the Department's Interim Final Rule (IFR) extending the compliance date
for State and local government entities with a total population of 50,000 or more to April 26,
2027. The compliance date for public entities with a total population of less than 50,000, or any
special district government, is extended to April 26, 2028."* **Declared discrepancy**: a good
share of secondary sources (vendor blogs, "2026" guides) still cite **24/26 April 2026** as a live
date. That is out of date. **ada.gov wins.** What did **not** change: the technical standard, nor
the scope of covered content.

**Section 508** has not been updated to WCAG 2.1/2.2: it still incorporates **WCAG 2.0 levels A
and AA**, with the final rule in force since **18 January 2018**. Consequence: meeting 2.2 AA
covers 508; the reverse does not.

### 2.3 Tooling

| Use | Default | Verified version / licence | Note |
|---|---|---|---|
| Rules engine | **`axe-core`** | 4.12.1 — **MPL-2.0** | De facto standard; the basis of almost everything else |
| Unit/component test | `jest-axe` / `@axe-core/playwright` | See §8 | Audit the design-system component, not the whole page |
| Site crawl in CI | **`pa11y-ci`** (`.pa11yci`) | `pa11y` 9.1.1 — **LGPL-3.0-only** | **LGPL licence, not MIT**: relevant if it is packaged or linked |
| Page audit | **Lighthouse** | 13.4.1 — Apache-2.0 | Its *accessibility* category is axe-core with a subset of rules |
| CI gate | **Lighthouse CI** (`@lhci/cli`) | 0.15.1 — Apache-2.0 | Same binary as the performance budget |
| Manual exploratory | WAVE, ARC Toolkit, DevTools *Accessibility Tree* | — | Not automatable in CI |
| Screen readers | **NVDA + Firefox/Chrome (Windows)**, **VoiceOver + Safari (macOS/iOS)**, **TalkBack + Chrome (Android)** | — | JAWS if the target audience is corporate/public administration (§4.3) |

**`pa11y` is LGPL-3.0-only** — not MIT, as is usually assumed. Checked in its raw `LICENSE` and in
the npm `license` field. Use as a CI tool: no problem. Linking it inside a distributed product:
review with whoever owns licensing.

## 3. Most commonly failed criteria (and what they literally require)

**Empirical base, not intuition.** WebAIM Million, **February 2026** sample over the million most
popular home pages: **95.9% of home pages had detected WCAG 2 failures**, up from 94.8% in 2025 —
*"reversing a trend of small improvements each of the previous 6 years"*. And since only what is
automatically detectable is counted, the report itself concludes verbatim: *"this suggests that
the rate of full WCAG 2 A/AA conformance was certainly lower than 4.1%."*

The six failures that account for **96% of all detected errors** (home pages affected, Feb-2026):

| Failure | % of home pages | Criterion |
|---|---|---|
| Low-contrast text | **83.9%** | 1.4.3 |
| Missing alternative text on images | 53.1% | 1.1.1 |
| Missing form field label | 51.0% | 1.3.1 / 3.3.2 / 4.1.2 |
| Empty links | 46.3% | 2.4.4 / 4.1.2 |
| Empty buttons | 30.6% | 4.1.2 |
| Missing document language | 13.5% | 3.1.1 |

**Operational criterion**: if a project cannot fix everything at once, **these six first** — they
are cheap, automatable and cover most of the real volume.

### 3.1 Contrast and colour (verbatim from WCAG 2.2)

- **1.4.3 Contrast (Minimum) (Level AA)**: *"The visual presentation of text and images of
  text has a contrast ratio of at least 4.5:1"*, with exceptions: *"Large-scale text and
  images of large-scale text have a contrast ratio of at least 3:1"*; incidental, inactive or
  decorative text, and logotypes, with no requirement.
- **1.4.11 Non-text Contrast (Level AA)**: *"The visual presentation of the following have a
  contrast ratio of at least 3:1 against adjacent color(s): User Interface Components […]
  Graphical Objects"*. → **the field border, the *checked* state and the focus indicator also
  have a threshold**, not just text.
- **1.4.1 Use of Color (Level A)**: *"Color is not used as the only visual means of conveying
  information, indicating an action, prompting a response, or distinguishing a visual
  element."* → a field in red with no error text **fails**; a chart series distinguished only by
  colour **fails** (see also the `dataviz` skill if available).

### 3.2 Focus

- **2.4.7 Focus Visible (Level AA)**: *"Any keyboard operable user interface has a mode of
  operation where the keyboard focus indicator is visible."*
- **2.4.11 Focus Not Obscured (Minimum) (Level AA)**, new in 2.2: *"When a user interface
  component receives keyboard focus, the component is not entirely hidden due to
  author-created content."* → **a fixed bar (*sticky header*/*cookie banner*) covering the
  focused element fails.** It is the typical failure no automated tool sees.
- **2.4.3 Focus Order (Level A)**: *"If a web page can be navigated sequentially and the
  navigation sequences affect meaning or operation, focusable components receive focus in an
  order that preserves meaning and operability."*
- **2.4.13 Focus Appearance** is **AAA**, not AA: *"an area of the focus indicator […] is at
  least as large as the area of a 2 CSS pixel thick perimeter of the unfocused component […]
  and has a contrast ratio of at least 3:1 between the same pixels in the focused and
  unfocused states."* A good design target; **not enforceable as AA**.

### 3.3 Pointer target (new in 2.2)

- **2.5.8 Target Size (Minimum) (Level AA)**: *"The size of the target for pointer inputs is
  at least 24 by 24 CSS pixels"*, except for equivalent spacing (a 24 px circle that does not
  intersect another target), an equivalent control on the same page, an *inline* target within a
  sentence, a user-agent control or essential presentation.
- **2.5.7 Dragging Movements (Level AA)**: *"All functionality that uses a dragging movement
  for operation can be achieved by a single pointer without dragging, unless dragging is
  essential"*. → **every *drag & drop* needs a non-dragging alternative.** It is the criterion
  that most often breaks list reorderers and *kanban* boards.

### 3.4 ARIA and accessible name

**First rule of ARIA, verbatim from *Using ARIA* (W3C)**: *"If you can use a native HTML element
or attribute with the semantics and behavior you require already built in, instead of re-purposing
an element and adding an ARIA role, state or property to make it accessible, then do so."* The
exceptions the document itself admits: that the feature exists in HTML but is not implemented or
has no accessibility support; that visual design constraints prevent using the native element
because it cannot be styled as required; or that the feature does not exist in HTML today.

Derived, enforceable rules:
- **Badly applied ARIA is worse than none.** `role="button"` on a `<div>` forces you to implement
  focus, `Enter`, `Space` and the disabled state by hand. If all four are not there, it is a defect.
- **Every interactive control has an accessible name** (4.1.2 Name, Role, Value, Level A). The
  visible name must be contained in the accessible name (2.5.3 Label in Name, Level A) — otherwise
  a voice-control user cannot activate it by saying what they see.
- **An icon-button with no text needs a name**: `aria-label` or visually hidden text. A `title` is
  **not enough**.
- **`aria-live` for what changes without a reload**: 4.1.3 Status Messages (AA), verbatim:
  *"status messages can be programmatically determined through role or properties such that
  they can be presented to the user by assistive technologies without receiving focus."* The live
  region must exist **in the DOM before** receiving the message, or nothing is announced.

### 3.5 Regions, headings and focus in an SPA

- **Landmarks**: `<header>`/`<nav>`/`<main>`/`<footer>` — a single `<main>` per view, and a
  "skip to content" link as the first focusable element (2.4.1 Bypass Blocks, Level A).
- **Hierarchical headings with no skipped levels**; a single `<h1>` describing the view. A heading
  is not a font size.
- **Route change in an SPA — the classic failure**: navigating without a reload **does not** move
  focus nor announce anything. The screen-reader user stays where they were, with focus on a link
  that no longer exists. **Mandatory criterion in every SPA**: on completing a route change, (a)
  update `document.title`, (b) **move focus** to the new view's `<h1>` or to its container
  (`tabindex="-1"` + `.focus()`), and (c) announce the change via a live region if the destination
  takes time to paint. **Without all three, navigation is inaccessible even if each individual
  screen passes axe.** The *router* belongs to `frontend-frameworks-standards`; **the requirement
  is this skill's, and it is tested with keyboard and screen reader, not with an automated test.**
- **Modal dialog**: focus moves inside the dialog on open, focus is **trapped** while it is open,
  `Escape` closes it, and **focus returns to the element that opened it**. Use `<dialog>` with
  `showModal()` or an already-audited design-system component; do not reimplement it per screen.

### 3.6 Forms and errors

- **Every field has an associated `<label>`** (`for`/`id`) or `aria-labelledby`. A `placeholder` is
  **not a label**: it disappears as you type and usually fails contrast.
- **3.3.1 Error Identification (Level A)**, verbatim: *"If an input error is automatically
  detected, the item that is in error is identified and the error is described to the user in
  text."* → **in text**, not just with a red border or an icon.
- **3.3.3 Error Suggestion (Level AA)**: *"If an input error is automatically detected and
  suggestions for correction are known, then the suggestions are provided to the user, unless
  it would jeopardize the security or purpose of the content."*
- **3.3.2 Labels or Instructions (Level A)**: *"Labels or instructions are provided when
  content requires user input."* Expected format, whether it is required and any constraints
  **before** submitting, not after.
- The error message is associated with the field (`aria-describedby`), `aria-invalid` is set, and
  focus goes to the first erroneous field or to a focusable error summary.
- **3.3.8 Accessible Authentication (Minimum) (AA)**, new in 2.2: do not require a cognitive test
  (remembering, transcribing, solving a puzzle) without an alternative. **It directly affects
  CAPTCHAs and one-time codes that block pasting** — if the field prevents `paste`, it fails.

### 3.7 Data tables

`<table>` only for data, never for layout. `<caption>` with the title, `<th>` with
`scope="col"`/`scope="row"`, `<thead>`/`<tbody>`. Complex tables: `headers`/`id`. A "table" made of
`<div>`s requires full `role="table"`/`row`/`cell` — **it is more work than using the native
element** (§3.4).

### 3.8 Motion and user preferences

- **2.3.1 Three Flashes or Below Threshold (Level A)**: nothing that flashes more than three times
  per second. It is a **physical safety** criterion (photosensitive epilepsy), not an aesthetic one.
- **2.2.2 Pause, Stop, Hide (Level A)**: any automatic motion lasting more than 5 s can be paused,
  stopped or hidden. Applies to carousels and logo *marquees*.
- **`prefers-reduced-motion: reduce`**: respect the system preference **by default** —
  transform/movement animations disabled or reduced to an opacity change. Crossover with
  `web-performance-standards`: there the same query is used to avoid burning main-thread time;
  here it is a conformance requirement.
- **`prefers-contrast: more`** and the OS forced-contrast mode: the interface must remain usable;
  do not override system colours with `!important`.

### 3.9 Multimedia, documents and email

| Content | Minimum requirement (AA) |
|---|---|
| Video with audio, prerecorded | **Captions** (1.2.2, A) + **audio description** (1.2.5, AA) |
| Audio-only, prerecorded | Text transcript (1.2.1, A) |
| Live | Live captions (1.2.4, AA) |
| Player | Keyboard-operable controls with an accessible name; no autoplay with sound |

- **Unreviewed automatic captions do not conform**: 1.2.2 requires captions, and captions with
  transcription errors do not convey the content. Human review.
- **Transcript ≠ captions**: a transcript does not cover 1.2.2 for video.
- **The technical delivery of the track belongs to `streaming-multimedia-standards`**
  (WebVTT/TTML/IMSC, CEA-608/708, declaration in the HLS/DASH manifest, audio-description
  *rendition*). Here the conformance criterion and who signs it; there, that it reaches the player.
  **A track that is produced but not declared in the manifest fails all the same**: the gate is
  that it shows up in the client.
- **PDF**: if a PDF is published, it goes out **tagged** (structure, reading order, alternative
  text, language, document title) — reference **PDF/UA**. Preferred criterion: **publish HTML and
  offer the PDF as a secondary download**, not the other way round. A scanned PDF with no text
  layer is inaccessible content, no nuance.
- **Email (HTML)**: alternative text on images, sufficient contrast, heading hierarchy, and a
  **plain-text version** in the `multipart/alternative`. An email that is just a linked image is
  inaccessible.

## 4. Testing method and CI gates

### 4.1 What automation actually automates — the data, not intuition

**No automated tool closes conformance.** Verified figures, with their source and declared bias:

- **Deque (maker of `axe-core`)**, over >2,000 audits, >13,000 pages and ~300,000 issues:
  *"57.38% of total issues were identified using its automated tests"*. The `axe-core`
  documentation repeats it: *"With axe-core, you can find on average 57% of WCAG issues
  automatically"*. **It is a vendor study about its own product**, and it measures **issue
  volume**, not the percentage of success criteria covered.
- **UK Government Digital Service**: the best tool it tested found **40%** of the known barriers.
- Deque puts its *Intelligent Guided Tests* (semi-automated, with human intervention) at around
  **80%**; the 57%→80% jump **is not automation, it is a guided person**.

**Fixed criterion**: treat **~40%** as the conservative working figure and **57%** as the
optimistic vendor upper bound. **Between 43% and 60% of real problems are seen by no tool.**
Direct consequence: **a score of 100 in Lighthouse's *accessibility* category does not mean the
site is accessible**, it means it passed the rules that can be checked without understanding the
content. Nothing that is a semantic judgement — whether the `alt` describes the image, whether the
focus order makes sense, whether the error is understandable, whether the dialog returns focus —
is automatable.

### 4.2 CI gates (in increasing order of cost)

1. **Static lint** (`eslint-plugin-jsx-a11y` or the framework's equivalent): over the *diff*, in
   the *pre-commit*. Cost ~0.
2. **`axe-core` at component level** (`jest-axe`) on design-system components: **zero violations,
   breaks the build**. It is the most profitable gate because one fixed component fixes all its
   instances.
3. **`@axe-core/playwright` on the critical E2E journeys** (sign-up, login, checkout, search),
   **in every relevant state**: empty form, form with errors, dialog open, menu expanded. **An
   analysis of the page's initial state is worthless**: the failures live in the states.
4. **`pa11y-ci` with `.pa11yci`** crawling the set of representative URLs *nightly*, not on every
   PR.
5. **Lighthouse CI** with an assertion on the *accessibility* category: **an absolute threshold
   and, on top of that, a ban on regression** relative to the main branch. Same binary and same
   configuration as the `web-performance-standards` budget.

**Failure policy**: `axe-core` **serious** and **critical** break the build without exception.
`moderate`/`minor` warn and go into the register. **Exclusions (`disableRules`, excluded
selectors) are declared in the configuration file with a reason and an associated issue, never
inline and never silently.**

### 4.3 What cannot be automated (and is mandatory)

**Non-substitutable requirement**: before declaring conformance, every critical journey is tested

- **Keyboard-only**, no mouse: `Tab`/`Shift+Tab` traverse everything interactive in a logical
  order, focus is always visible (§3.2), there are no focus traps, `Escape` closes what opens and
  **focus returns where it should**.
- **With at least two real screen readers**, in their natural browser pairing: **NVDA + Firefox or
  Chrome (Windows)** and **VoiceOver + Safari (macOS/iOS)**; **TalkBack + Chrome** if there is a
  mobile web; **JAWS** if the target audience is corporate or public administration. Screen readers
  **do not behave the same as each other**: a pattern that works in VoiceOver may stay silent in
  NVDA. **Emulating with the DevTools accessibility tree does not replace the test**; the tree says
  what is there, not what is heard.
- **At 200% and 400% zoom** (1.4.4 Resize Text, 1.4.10 Reflow) and with forced text spacing
  (1.4.12).
- **With users with disabilities** when the product is critical or mass-market. It is the only test
  that catches usability problems that technically "conform".

## 5. Stack security and risks

### 5.1 Accessibility overlays: FORBIDDEN as a conformance strategy

**Formal position of the community**, verbatim from the *Overlay Fact Sheet* (**1,031 signatories**
as consulted in Aug-2026):

> *"1. We will never advocate, recommend, or integrate an overlay which deceptively markets
> itself as providing automated compliance with laws or standards
> 2. We will always advocate for the remediation of accessibility issues at the source of the
> original error
> 3. We will refuse to stay silent when overlay vendors use deception to market their products
> 4. More specifically, we hereby advocate for the removal of web accessibility overlay and
> encourage the site owners who've implemented these products to use more robust, independent,
> and permanent strategies to making their sites more accessible"*

**And there is a regulator's resolution, not just opinion**: the **FTC** ordered **accessiBe** to
pay **USD 1,000,000** over deceptive claims about its `accessWidget` widget (announcement of
3-Jan-2025; final order approved on 24-Apr-2025). The order bars it from representing that its
automated products can make any website WCAG-conformant or maintain that conformance without
substantiating evidence, and also from passing off its own reviews as independent opinions. The
FTC documented on sites with the *overlay* installed: missing or incorrect `alt`, missing focus
indicator, keyboard traps and wrong heading levels — **that is, the overlay does not even fix what
it claims to fix**. Note for rigour: it was a settlement **without admission** of the practices.

**Criterion**: an overlay is **not** installed as a conformance solution. If one is already
installed, **removing it** is part of the remediation plan. An in-house preferences widget
(contrast, text size) built and audited by the team **is not an overlay** and is legitimate — the
difference is that it does not promise conformance nor inject itself over someone else's DOM.

### 5.2 Third-party risk

An overlay or a third-party accessibility widget is **third-party JavaScript with full access to
the DOM**, which often intercepts focus and keyboard input. Implications usually overlooked: XSS
and supply-chain surface, incompatibility with a strict CSP (it frequently forces `unsafe-inline`
or `unsafe-eval`), and **processing of data about users with disabilities** — a specially
sensitive category under the GDPR (see `privacy-engineering-standards`). If it goes in anyway, it
goes in with SRI, with a CSP review and with a signed DPA.

### 5.3 Accessibility and security controls

- **CAPTCHA**: if it is the only way through, it fails 3.3.8 (§3.6). Alternatives: interaction-free
  detection, attestation tokens, rate limiting. If there is a CAPTCHA, **a non-visual and
  non-cognitive alternative is mandatory**.
- **MFA**: one-time codes must be **pasteable** and readable by the password manager
  (`autocomplete="one-time-code"`). Blocking paste "for security" is a failure with a negative
  security cost.
- **Session timeouts**: 2.2.1 Timing Adjustable (Level A) requires warning and allowing an
  extension. A silent logout after 15 minutes breaks anyone who needs more time.
- **Content hidden for security**: `aria-hidden="true"` **never** on anything focusable (§7). If it
  must be hidden from everyone, `hidden`/`display:none`/`inert`.

## 6. Operability: declare, measure and do not regress

### 6.1 Accessibility statement

Where the law requires it (EU public sector: Directive 2016/2102; Spain: **RD 1112/2018**), the
statement **is a deliverable with prescribed content**, not a page of good intentions. It must
include, as a minimum: compliance status (conformant / partially conformant / non-conformant),
**which parts of the content are not accessible and why**, alternatives offered, a feedback and
accessible-information request mechanism, a **complaints and claims procedure**, the date of the
statement and **the date of the last review**. RD 1112/2018 additionally requires **periodic
reviews** and keeping it up to date. **A statement claiming full conformance without a manual audit
behind it is a documented falsehood with the responsible person's name on it.** Drafting it as
partially conformant with an honest list of exceptions is the correct and defensible option.

For the US market the equivalent document is the **VPAT / ACR**, which the buyer asks for in the
tender, not the regulator.

### 6.2 Audit and report

Scope by **user journeys**, not by page count. Every finding carries: the failed success criterion
(number and level), severity by user impact (not by ease of fixing), reproduction steps, the
assistive technology and browser used, and a remediation proposal. **Findings go into the same
backlog as every other bug, with the same severity SLA.** A separate accessibility board is a board
nobody looks at.

### 6.3 Non-regression

- Metric tracked: **`serious`+`critical` violations per critical journey**, monthly trend. Target:
  zero, and **no regression** between releases.
- **Manual audit coverage**: % of critical journeys tested with keyboard and screen reader in the
  last N months. That is the honest metric; the rest is the 40-57%.
- Design-system components are audited when a major version is published and their report is
  versioned with the component.

## 7. Sustainability and prohibitions

- **Cadence**: review on the web the state of WCAG, EN 301 549 and the legal dates **every
  quarter**; the tooling, at the normal dependency cadence. `axe-core` changes rules between minor
  versions: **pin the version and review the *changelog*** before bumping, because a new version
  can break the build with legitimate new findings (that is good: they get fixed, not silenced).
- **Do not plan against WCAG 3.0** (§2.1). Plan against 2.2 AA.
- **Accessibility is estimated inside the story**, not as a separate story. A story without
  accessibility acceptance criteria does not meet the *Definition of Ready*.

Explicit prohibitions:

- ❌ **Accessibility overlays as a conformance solution** (accessiBe, UserWay, AudioEye and the
  like in *widget* mode). See §5.1: there is a formal position with 1,031 signatories and an FTC
  order of USD 1M.
- ❌ **`outline: none` (or `outline: 0`) with no substitute focus indicator** meeting 1.4.11 and
  2.4.7. It is the industry's most repeated one-line failure.
- ❌ **`aria-hidden="true"` on interactive content or content containing it**. It creates an
  element that is focusable and invisible to assistive technology: the worst of both worlds. Use
  `inert`.
- ❌ **Positive `tabindex`** (`tabindex="1"` and above). It breaks document order across the whole
  page, not just where it is applied. Only `0` and `-1`.
- ❌ **Text inside images** for content (1.4.5 Images of Text, AA). It does not scale, is not
  translated, cannot be selected and usually fails contrast. Exceptions: logotypes and cases where
  the presentation is essential.
- ❌ **`placeholder` as a field's only label**.
- ❌ **`<div>`/`<span>` with `onclick`** without `role`, without `tabindex="0"` and without
  keyboard handling. Before that, `<button>` (§3.4).
- ❌ **Announcing "WCAG AA conformant" without a manual audit** with keyboard and screen reader.
  With a signed legal statement, it is not only false but a liability.
- ❌ **Silencing `axe-core` rules inline** or excluding selectors with no written reason and
  associated issue.
- ❌ **`user-scalable=no` / `maximum-scale=1`** in the `viewport`: it blocks zoom (1.4.4).
- ❌ **SPA route change with no focus management or announcement** (§3.5).
- ❌ **Automatic captions with no human review** presented as compliance with 1.2.2.
- ❌ **Untagged PDF** as the only format of essential content.
- ❌ **Treating accessibility as a final phase** ("we'll run it through axe before shipping"). The
  43-60% automation does not see is discovered then, when the redesign no longer fits.

## 8. Mandatory web verification

Before committing any fact from this document in a real project, verify against the primary source:

1. **WCAG**: `w3.org/WAI/standards-guidelines/wcag/` — which version is a Recommendation today and
   the date of the last update. Normative text of each criterion at `w3.org/TR/WCAG22/`, **copied
   verbatim**: a mistranscribed nuance changes whether something conforms or not.
2. **WCAG 3.0**: `w3.org/TR/wcag-3.0/` — check it is still a *Working Draft*. **Declared gap**:
   expected Candidate Recommendation and Recommendation dates, with no primary source; the figures
   circulating (Q4-2027, ≥2028, 2029) are third-party.
3. **EAA**: EUR-Lex CELEX `32019L0882` — arts. 4, 31 and 32 in their consolidated text. **Do not
   trust summaries**: art. 31.1 (28-Jun-2022, transposition) is systematically confused with 31.2
   (28-Jun-2025, application), and an automatic summariser inverted them during this very
   verification.
4. **Spain**: BOE-A-2023-11022 (Ley 11/2023) — **declared gaps**: neither the amounts under the
   penalty regime nor the exact deadline of the transitional provision on self-service terminals
   have been verified against a primary source (a secondary source says 10 years, the EAA speaks of
   economic useful life with a cap; **unresolved discrepancy**). BOE-A-2018-12699 (RD 1112/2018)
   and BOE-A-2026-4520 (RD 143/2026).
5. **EN 301 549**: the ETSI page and **the citation in the OJEU**, which is what confers
   presumption of conformity. **Declared gap**: the publication of V4.1.1 in the OJEU ("October
   2026" is cited in secondary sources) is not confirmed by a primary source. Remember the
   Commission's verbatim: *"New versions of the WCAG or of EN 301 549 do not automatically change
   the legal obligations."*
6. **US**: `ada.gov` for Title II — **the dates in force are 26-Apr-2027 and 26-Apr-2028**, not the
   2026 ones vendor guides keep repeating (**declared discrepancy**, §2.2). `section508.gov` to
   confirm whether it is still on WCAG 2.0 AA.
7. **Automation figures**: the 57% is Deque's about its own tooling and the 40% is GDS's. Check
   whether there is a more recent independent study before citing either.
8. **WebAIM Million**: published annually (last verified: **February 2026**). Check the current
   edition before citing percentages.
9. **Overlays**: `overlayfactsheet.com` (number of signatories, verified: **1,031**) and `ftc.gov`
   for the status of the order against accessiBe and any subsequent action against other vendors.
10. **Tooling — version and licence, reading the raw `LICENSE`**: `axe-core` (verified 4.12.1,
    **MPL-2.0**), `pa11y` (9.1.1, **LGPL-3.0-only** — not MIT), `lighthouse` (13.4.1, Apache-2.0),
    `@lhci/cli` (0.15.1, Apache-2.0). Also check whether any has gone into maintenance mode or
    changed repository: **the GitHub releases feed is not a project's source of truth**; cross-check
    against its official site.
11. **Declared gap**: the adoption of WCAG 2.2 as **ISO/IEC 40500** (a 2025 edition is cited) has
    not been verified against ISO or against W3C. Do not assert it without checking.

If the web contradicts this document, **the web wins** — flag the discrepancy.
