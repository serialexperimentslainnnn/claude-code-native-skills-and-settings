---
name: i18n-standards
description: Use when a product must work in more than one language, script, region or time zone — messages.json, .po/.pot, .xliff/.xlf, .arb, .resx, .properties or .ftl catalogs, ICU MessageFormat and MessageFormat 2.0, CLDR plural categories (zero/one/two/few/many/other), Intl.NumberFormat/DateTimeFormat/Collator/PluralRules/Segmenter/ListFormat/RelativeTimeFormat/DisplayNames, Temporal, tzdata/IANA time zone identifiers and UTC storage, Unicode normalization NFC/NFD, locale-dependent case mapping and the Turkish dotless i, collation versus code-point sort, grapheme versus code point versus byte length, libphonenumber and E.164 parsing, ISO 4217 currency minor units, personal name and postal address field design, BCP 47 tags and Accept-Language negotiation, i18next/FormatJS/react-intl/gettext/Fluent/Rails i18n, Weblate/Tolgee/Crowdin/Lokalise/Transifex, pseudolocalization, missing-translation CI gates, RTL and bidi layout, or machine and LLM translation review policy.
---

# Internationalisation (i18n) standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Internationalisation is an architecture decision you take at the start or pay for in full
afterwards.** It is not a layer you add on: it determines the database schema (which
fields exist for a name and an address, what type stores an instant, what collation a column
has), the API contract (date and amount format), the unit of text in the code
(formatted string vs. message with parameters) and the delivery flow (who translates and when).
Retrofitting it means rewriting those four things at once, with data already in production. **Operational
corollary: a monolingual product is designed i18n-ready even if it is never translated** — the
incremental cost before the first deployment is low; afterwards it is a data migration.

Three terms, one line each, and they are not revisited:
- **i18n**: preparing the system so that it *can* adapt to any locale without touching code.
- **l10n**: adapting it to a specific locale (translating, formatting, adjusting content and legals).
- **g11n**: the business decision to operate in a market — l10n + tax, legal, payment, support.

Triggers: `messages.json`, `.po`/`.pot`, `.xliff`/`.xlf`, `.arb`, `.resx`,
`.properties`, `.ftl`, `.strings`/`.xcstrings` catalogs; `ICU MessageFormat`, `MessageFormat 2.0`;
CLDR plural categories; `Intl.*`; `Temporal`; `tzdata`/`zoneinfo`; the IANA
zone identifier; NFC/NFD; `toLocaleUpperCase`; collation and `ICU`; `libphonenumber`; E.164; ISO 4217;
BCP 47 and `Accept-Language`; `i18next`, `FormatJS`/`react-intl`, `gettext`, `Fluent`,
`rails-i18n`; Weblate, Tolgee, Crowdin, Lokalise, Transifex; pseudolocalisation; RTL/bidi.

**Not applicable**: see
`frontend-web-platform-standards` (**the CSS and the browser APIs are theirs**: logical
properties `margin-inline`/`padding-block`/`inset-*`, `writing-mode`, `text-wrap`, and the
*Baseline* status of any `Intl.*` or of `Temporal`. Here **what i18n demands of that CSS and that
API**: that there is no `margin-left` that breaks in Arabic, that the formatting is done by the
platform and not by a concatenation);
`accessibility-standards` (**cedes completely**: the document's and each fragment's `lang`
attribute, `dir`, language as a WCAG conformance criterion and **how assistive technology
consumes it** are *their* criteria, not ours. If the question is "does the screen reader
pronounce it in the right language?", it is theirs. If it is "does the translation exist and is it
well formatted?", it belongs here);
`design-systems-standards` (the component that must survive RTL and a
text 40 % longer is built and audited there, once only — not on every screen. Here
the criteria that component must meet, not its API or its versioning);
`api-design-standards` (**the contract is theirs**: ISO 8601/RFC 3339 in the date field,
amounts in minor units with their ISO 4217 code, language negotiation in the header. Here
the consequence in the client and in the catalog);
`data-platform-standards` and `sql-standards` (**collation and ordering in the engine are
theirs**: `COLLATE`, `ICU` as the provider, `lc_collate`, reindexing after a collation version
change. Here only the visible consequence — that a list ordered by the engine may not
match the one the client orders, and that you have to choose where the ordering happens);
`privacy-engineering-standards` (**personal data**: a catalog with real example names or addresses
is a processing activity; legal basis, minimisation and retention are theirs);
`grc-compliance-standards` (**a legal language requirement**: in which language a contract,
labelling, privacy notice or interface must be in each jurisdiction — it is a regulatory obligation,
not a product decision. Here only the technical capability to comply with it);
`mobile-standards` and `dart-standards` (i18n of a native app and of Flutter: `.arb`, `.xcstrings`,
resources by *qualifier*, and the system locale as the source of truth);
`ai-agent-workflow-standards` (**a fine boundary**: machine translation with an LLM appears in
both. **The workflow with the model is theirs** — what task it is given, how it is reviewed,
what permissions it has. **The criteria of linguistic quality and of where an unreviewed
translation is unacceptable belong here**);
`python-standards`, `typescript-standards`, `dotnet-standards`, `jvm-spring-standards`,
`ruby-standards`, `php-standards`, `go-standards`, `rust-standards` (**the specific i18n library
of each stack belongs to its skill**; here the criteria that library must satisfy),
`frontend-frameworks-standards` (routing by locale and data loading),
`web-performance-standards` (the cost in bytes of serving catalogs),
`cicd-standards` (the pipeline that runs the gates of §4).

## 2. Default decisions

> Verify the latest version and the status of each component on the web before pinning it (§8).
> CLDR, ICU and `tzdata` publish several times a year and **`tzdata` changes by political decision,
> not by calendar**.

| Decision | By default | Justifiable alternative / reason |
|---|---|---|
| Locale data source | **CLDR** (via ICU or via the platform's `Intl`) | Nothing else. Any home-made table of months, currencies or plurals is guaranteed debt |
| Number, date, list and unit formatting | **The platform's `Intl.*`** | A library only if the runtime does not ship it or if you need an ICU `skeleton` that is not exposed. `Intl.NumberFormat`/`DateTimeFormat`/`Collator` have been in every engine for years (§2.1) |
| Message syntax | **ICU MessageFormat 1** today | **MF2 is stable in CLDR since CLDR 47, but the platform API is not**: `Intl.MessageFormat` is still at **Stage 1** in TC39 and adoption in tooling is marginal (§2.2). MF2 only with a *polyfill* and as a conscious decision |
| Instants | **UTC in storage, the user's IANA zone in presentation** | See §3.5. Never a fixed *offset* as a substitute for a zone |
| Date type | **Distinguish instant / civil date / date+time without zone** | A date of birth **is not an instant**: storing it as a *timestamp* moves it a day when crossing zones |
| Date API in JS | `Temporal` **only after checking the runtime**; otherwise a library with zone support | `Temporal` is ES2026 and ships without a *flag* in Node 26, but **it is not Baseline**: Safari is missing (§2.1) |
| Time zone | **IANA identifier** (`Europe/Madrid`), never an abbreviation (`CET`; `IST` is ambiguous) | — |
| Phone | **`libphonenumber` (Apache-2.0)**, stored in **E.164** | Never a home-made regex. In Node, a third-party wrapper (§2.3) |
| Currency | **An integer in the minor unit + the ISO 4217 code**, formatted with `Intl.NumberFormat` | Never a `float`. The number of decimals **depends on the currency** (JPY 0, TND 3): do not assume 2 |
| Locale identifier | **BCP 47** (`es-ES`, `zh-Hans-CN`, `sr-Latn`) | Never bare two-letter codes to decide formatting: the script and the region matter |
| Negotiation | `Accept-Language` as the **default value**, an explicit user preference as the winner, persisted | Never IP geolocation as the sole signal: the country is not the language |
| Unicode normalisation | **NFC on entry** (validation boundary), comparison over the normalised form | NFD only if the domain requires it (historical macOS, some corpora). What is forbidden is *not deciding* |
| Translation platform | **Weblate** self-hosted if there is a team to operate it; **Tolgee** if the flow is developer-driven; SaaS if you do not want to operate anything (§2.4) | — |
| Pseudolocalisation | **Mandatory**, generated and tested in CI (§4.2) | — |
| Machine/LLM translation | Allowed **only** with human review before publishing, and **forbidden** in the classes of §5.3 | — |

### 2.1 Verified state of the JS platform (Aug 2026)

Data from `@mdn/browser-compat-data` **8.0.9** (`timestamp: 2026-08-03T15:35:50Z`) and from
`nodejs.org/dist/index.json`:

| API | Chrome | Firefox | Safari | Safari iOS | Node |
|---|---|---|---|---|---|
| `Temporal` | 144 | 139 | **`preview`, behind the `useTemporal` *runtime flag*** | **no** | 26.0.0 |
| `Intl.Segmenter` | 87 | 125 | 14.1 | 14.5 | 16.0.0 |
| `Intl.DurationFormat` | 129 | 136 | 16.4 | 16.4 | 23.0.0 |
| `Intl.ListFormat` | 72 | 78 | 14.1 | 14.5 | 12.0.0 |
| `Intl.PluralRules` | 63 | 58 | 13 | 13 | 10.0.0 |
| `Intl.Collator` / `NumberFormat` | 24 | 29 | 10 | 10 | 0.12.0 |

- **`Temporal` is not Baseline.** MDN marks it *verbatim*: «Limited availability — This feature
  is not Baseline because it does not work in some of the most widely-used browsers.» It reached
  Stage 4 (ES2026) and Node 26 ships it without a *flag*, but **on the web it still requires a polyfill
  or detection**. Node 26 is *Current*, **not LTS**: in `dist/index.json` `v26.6.0` (2026-08-03)
  has `lts: false`; the active LTS is the 24 line (`Krypton`).
- **Node < 13 shipped *small-icu*** (only `en-US` data) — noted in the BCD itself for
  `PluralRules`, `ListFormat`, `RelativeTimeFormat`, `Collator` and `NumberFormat`. In any
  runtime or minimised build, **verify that full ICU is present before trusting `Intl`**: without
  data, `Intl` does not fail, it *silently degrades* to English. That is the dangerous failure mode.

### 2.2 MessageFormat 2 — two states that do not match

- **Specification**: MF2 became **Stable in CLDR 47** and is a normative part of UTS #35 (LDML).
  In CLDR 48, `:currency` and `:percent` became Stable. Parts of the `u:` space are still *Draft*.
- **Platform**: `tc39/proposal-intl-messageformat` declares *verbatim* `Stage: 1`, champions
  «Eemeli Aro (Mozilla/OpenJS Foundation), Ujjwal Sharma (Igalia)», with the open thread in the
  repository itself titled **«This proposal is stuck»**.
- **Rule**: a stable standard with a stalled platform API and marginal adoption in TMSs and
  frameworks **is not a default**. MF2 is adopted when the full chain (catalog → TMS →
  runtime) supports it, not when only the paper does. `messageformat@4.0.0` (Apache-2.0)
  is the route with a *polyfill*.

### 2.3 Phones

- `google/libphonenumber` is **alive and with a declared fortnightly cadence**; latest tag in
  the releases feed: `v9.0.36`. **Licence verified in the repo's raw `LICENSE`:
  Apache-2.0** (not BSD, not MIT).
- **There is no official Google npm package** (the JS port is coupled to Closure). Two routes, and
  **they are not the same software**:
  - `google-libphonenumber` (a wrapper of the official port; npm declares `(MIT AND Apache-2.0)`,
    `3.2.46`) — same behaviour, **heavy**.
  - `libphonenumber-js` (**an independent reimplementation**, npm declares `MIT`, `1.13.10`) —
    much lighter, **not equivalent in coverage**: if you validate numbers from all over the world
    with legal requirements, verify the difference before choosing.
- **Store E.164** (`+34600000000`) and, if the domain requires it, store the country of origin
  separately. Format for display; **never store the pretty format**.

### 2.4 Translation management platforms (verified on the official page, Aug 2026)

| Platform | Software licence | Self-hostable | Free plan (datum from the official page) |
|---|---|---|---|
| **Weblate** | **GPLv3+** (raw `LICENSE`: GNU GPL v3; site footer: «Licensed GNU GPLv3+») | Yes | **Libre plan free** for free projects: «It has the same limits as the 160k plan, and is only for public projects». Cloud from €47/month (10k plan). Self-hosting support: €53/month basic, €106/month extended. Current release in the feed: `Weblate 2026.8` |
| **Tolgee** | **Apache-2.0 with an exception**: the `LICENSE` says that «All content that resides under the "ee/" and "/webapp/src/ee" directory […] is licensed under the license defined in "ee/LICENSE"» — **the core is Apache-2.0, the *enterprise* part is not**. Calling it plain "Apache-2.0" is incorrect | Yes | Free €0: **500 keys, 3 seats**. Team €49/month, Business €179/month, Advanced €499/month (annual) |
| **Crowdin** | Proprietary | No | **Free for open source on request**: «If you want to use Crowdin for an Open Source project, sign up for a free account, set up your project and send us a request». General pricing by *hosted words* via a calculator; 14-day trial of the Team plan |
| **Lokalise** | Proprietary | No | **There is no free plan.** Entry point: Explorer $144/month; Growth $375/month; Advanced $999/month; Enterprise bespoke. Only a 14-day trial |
| **Transifex** | Proprietary | No | Starter / Growth / Enterprise+, priced by *hosted words*. **Free for open source projects with no revenue model and no funding** |

- **Correction of a frequent assumption**: software comparison directories (GetApp,
  Vendr and aggregators) list a "free version" for Lokalise and fixed entry prices for
  Crowdin and Transifex. **The official page contradicts both**: Lokalise publishes no free
  plan and the other two are priced by hosted word volume. A directory price =
  an unverified datum.
- **Selection criteria, in this order**: (1) is the flow driven by developers or
  translators? Weblate and Pontoon are translator-oriented; Tolgee, developer-oriented.
  (2) is there anyone to operate the instance? Self-hosting adds patching, backup and availability.
  (3) are there external contributors? Then §5.1 is mandatory. (4) exit cost: **demand full
  export to a standard format before signing** — the lock-in here is the catalog's.

## 3. The catalogue of false assumptions

Every entry is an assumption that **breaks systems in production**. The general rule: if the
data model encodes a local custom, the system is not internationalisable.

### 3.1 Personal names

- ❌ `first_name` + `last_name`. **There is no universal decomposition**: there are cultures with two
  surnames (Spain), with the surname first (Hungary, much of East Asia), with a
  patronymic (Iceland, Russia), with a single name and no surname (Indonesia, parts of India) and
  with particles that are not part of the surname for sorting purposes.
- ✅ **One mandatory `full_name` field (the full name as the person writes it)** and, if
  the business requires it, an optional `display_name`/`preferred_name` for greetings. Any
  additional decomposition is **optional and never mandatory**.
- ❌ A "safe" maximum length. There is none. If a limit has to be set, make it **high and by
  graphemes** (§3.4), and justified by storage, not by the form design.
- ❌ Restricting to `[A-Za-z ]`, to ASCII, or rejecting apostrophes, hyphens, multiple spaces,
  full stops, non-Latin characters or single-letter names. All of that exists.
- ❌ Assuming the name does not change (marriage, transition, legal correction). The name is a
  **mutable field with history**, not a key.
- ❌ Deriving gender, title or pronoun from the name. If it is needed, **you ask**, it is
  optional and it admits "prefer not to say".
- References to check before designing the form: W3C *Personal names around the world*
  and the classic *Falsehoods programmers believe about names* (§8).

### 3.2 Addresses and postcodes

- ❌ Fixed `street` / `number` / `city` / `province` / `postcode` fields. The order, the existence and the
  obligatoriness of each component **depend on the country** (Ireland had no national
  postcode until Eircode; Hong Kong has none; in Japan the order goes from largest to smallest).
- ✅ **A form whose set and order of fields derives from the selected country**, with a free
  `address_lines[]` as a fallback, and the country as the **first** field of the form.
- ❌ Validating the postcode with a universal regex, or assuming it is numeric, or assuming a fixed length.
  The United Kingdom, the Netherlands and Canada are alphanumeric with a significant space.
- ❌ A mandatory "state/province". Many countries do not have that subdivision.
- ❌ Deducing the country from the IP and not letting it be changed.
- The standard to consult for international postal format: **UPU S42** (§8). For the country
  code: **ISO 3166-1 alpha-2**, with the warning that **the list changes** and that some
  entries are politically sensitive; do not *hardcode* the list, take it from CLDR.

### 3.3 Phones, currencies and decimals

- ❌ A phone regex, a fixed length, assuming a national prefix or that a number identifies a country
  of residence. See §2.3.
- ❌ Assuming two decimals. **ISO 4217 defines the minor units per currency**: JPY 0, most
  2, TND/KWD/BHD 3. An amount is stored as **an integer in the minor unit + the currency code**.
- ❌ `float`/`double` for money. Never.
- ❌ Assuming the decimal separator, the thousands separator, its presence, or that the symbol goes in front.
  `Intl.NumberFormat` solves it; a `"$" + x.toFixed(2)` template does not.
- ❌ Assuming the currency symbol identifies the currency (`$` is at least twenty different
  currencies). **Show the ISO code alongside the symbol when there is real ambiguity.**
- ❌ Converting currency with a cached rate with no date and no source. The rate is a datum with a
  timestamp and with a provider; a converted amount **does not replace** the original amount.

### 3.4 Text: Unicode, normalisation, case, collation and length

- **Normalisation**: `"é"` can be one code point (NFC, U+00E9) or two (NFD, U+0065 U+0301).
  They look the same, **they are not equal byte for byte**, and a unique index, a `WHERE`, a
  password comparator and a file name treat them as different. **Rule: normalise
  to NFC at the input boundary, before validating, indexing or comparing.** Document the choice.
- **Language-dependent case mapping — the canonical case is the Turkish `i`**: in `tr`/`az`,
  `"i".toUpperCase()` is `"İ"` (dotted I) and `"I".toLowerCase()` is `"ı"` (dotless i). That is
  why **`toUpperCase()`/`toLowerCase()` without a locale is a latent bug** and `toUpperCase()` to
  compare identifiers breaks authentication on a device with a Turkish locale. Besides, case
  change **does not preserve length**: `"ß".toUpperCase()` gives `"SS"`.
  - ✅ For **presentation**: `toLocaleUpperCase(locale)` with an explicit locale.
  - ✅ For **comparing**: locale-independent *case folding* (`toUpperCase` with the root locale or
    the *case folding* function of the stack's ICU library), **never** the interface's.
  - ❌ Writing capitals in the catalog or forcing them with `text-transform` as a substitute for
    having the right string: there are languages with no case distinction and others where the
    initial capital changes the meaning (German) or is not used the same way (Spanish in titles and
    month names).
- **Ordering**: sorting by code point **is not alphabetical order in any language**. `"Z"`
  comes before `"a"`, `"ñ"` falls after `"z"`, and in Swedish `"ä"` goes at the end of the alphabet while in
  German it goes next to `"a"`. ✅ **CLDR/ICU collation** (`Intl.Collator` in JS, `COLLATE` with the
  ICU provider in the engine). **Decide where the ordering happens** — if the server paginates, the
  server orders; ordering the page in the client produces a globally incorrect list.
  - `Intl.Collator` with an explicit `sensitivity` for search and `numeric: true` for lists with
    embedded numbers. *Natural* string comparison is also a locale decision.
- **Length: `.length` lies.** Three different units and **none is interchangeable**:
  - **Bytes** — what it takes up (column, header, payload limit).
  - **Code points** — what `.length` counts in Python; in JS `.length` counts **UTF-16
    units**, so an emoji outside the BMP counts as 2.
  - **Graphemes** — what a person perceives as "one character". An emoji with a skin
    tone modifier or a family with ZWJ is **one grapheme and many code points**.
  - ✅ Interface limit and truncation: **by graphemes** (`Intl.Segmenter` with
    `granularity: 'grapheme'`). Storage limit: **by bytes**, and validated at the boundary.
    Truncating by code unit index **splits graphemes and produces corrupt text**.
  - Segmenting by words with `split(' ')` is incorrect in Chinese, Japanese and Thai:
    `Intl.Segmenter` with `granularity: 'word'`.

### 3.5 Dates and time zones — the other great bug generator

- **Base rule**: **an instant in UTC in storage; the user's IANA zone in
  presentation**; the zone is stored as a user preference, it is not inferred on every request.
- **An `offset` is not a zone.** `+02:00` does not let you compute the time of a future event
  because it does not know when daylight saving changes. Store `Europe/Madrid`.
- **Dates without a time are not instants.** Birthdays, invoice dates, public holidays and due
  dates are **civil dates**. Storing them as a `timestamp` shifts them a day when crossing
  zones. A `DATE` type or a `YYYY-MM-DD` string, and civil arithmetic, not instant arithmetic.
- **Recurring future events** (an alarm at 09:00) are stored as **local time + zone +
  recurrence rule**, not as a precomputed UTC instant: if the zone's rule changes, the
  computed instant is wrong.
- **`tzdata` is a dependency that gets updated and that changes by political decision**, not by
  calendar. Verified in IANA's `NEWS`, *verbatim*, release **2026c (2026-07-08)**:
  «Alberta moved to permanent -06 on 2026-06-18.» and «Morocco moves to permanent +00 on
  2026-09-20.» Hard operational consequence: **a system with an old `tzdata` computes future times
  wrongly and gives no error at all**. Updating `tzdata` is a patching task with the same urgency
  as an availability CVE, and it affects the container base image, the JDK, the runtime,
  the database and the embedded copy in the date library — **that is five different copies
  and they get out of sync**.
- Remaining traps, all real: times that **do not exist** (the spring forward) and times that
  **happen twice** (the autumn fall back) — all local arithmetic must decide what it does in
  both cases; **days that do not have 24 hours**; **`tzdata` changes identifiers and replaces them
  with links** (`Europe/Kyiv` vs. `Europe/Kiev`); non-Gregorian calendars in presentation
  (Islamic, Hebrew, Japanese by eras, Buddhist) — `Intl.DateTimeFormat` with an explicit `calendar`;
  and weeks whose **first day depends on the locale** (not always Monday, not always Sunday).
- ❌ Date arithmetic by adding milliseconds. ❌ `new Date("dd/mm/yyyy")`: parsing non-ISO strings
  **is implementation-dependent**. ❌ Trusting the server's zone: set `UTC` in the
  process and be explicit in every conversion.

### 3.6 Pluralisation, gender and concatenation as the central antipattern

- **String concatenation is the central antipattern of i18n.** `"You have " + n + " messages"`
  assumes word order, assumes the plural is an `s`, does not let you move the number within
  the sentence and does not allow gender agreement. **Any sentence fragment in the code is an i18n
  bug**: the translatable unit is **the complete sentence with parameters**, never its pieces.
- **CLDR's plural categories are not "singular/plural"**: there are up to **six** —
  `zero`, `one`, `two`, `few`, `many`, `other` — and **which numbers fall into each is decided
  by CLDR per language**, not by the translator or the developer. English uses two; Arabic uses all
  six; Polish and Russian use `one`/`few`/`many`/`other`; Japanese uses only `other`.
  Besides, **`one` does not mean "one"**: in French 0 goes in `one`.
  - ✅ The catalog declares the categories the **target** language needs; the tool generates them
    from CLDR. ❌ A binary `_plural` key: it breaks as soon as a language with
    three or more forms comes in.
  - ✅ `Intl.PluralRules` to select at runtime when a full ICU engine is not used.
  - **Ordinals are another rule** (`type: 'ordinal'`): `1st/2nd/3rd/4th` does not follow the cardinals.
  - **Ranges** ("3–5 items") have their own selection (`selectRange`).
- **Gender**: it is not solved with an improvised `select` in the code. ICU MessageFormat has
  `select` for that, and **the gender variable must reach the message as a parameter**, not be
  decided outside. There are languages where the verb, the article and the adjective agree; an interface
  that says "Bienvenido" is not translatable without that datum.
- **Text expansion**: the German or Finnish translation can be considerably longer than
  the English and the Chinese one much shorter. **No design can depend on the length of the
  original text**; it is tested with pseudolocalisation (§4.2), not with estimates.

## 4. Quality, testing and CI gates

In increasing order of cost. The first three **break the build**.

### 4.1 Static gates (seconds)

1. **A literal string with no key in the code** → *broken build*. A lint rule for the stack
   (`i18next/no-literal-string`, `formatjs/no-literal-string-in-jsx`, `rubocop-i18n`,
   the equivalent in each language). Without this gate, the catalog degrades on its own.
2. **A key used and not declared** → *broken build*. It is a deferred runtime error; the
   extractor detects it in seconds.
3. **A key declared and not used** → a warning, and **deletion** in the periodic cleanup. A catalog with
   dead keys pays for translating text nobody sees.
4. **Invalid ICU syntax in any language** → *broken build*. A translator can break a
   `{count, plural, ...}`; it is detected by compiling the catalog, not in production.
5. **Placeholders that do not match between source and translation** (one missing, one extra, a name
   changed) → *broken build*. It is the most common cause of a runtime exception from a translation.
6. **Translation coverage per language**: an explicit threshold per language. A language **below its
   threshold is not offered in the selector**; showing half an interface in English is worse than not offering it.
7. **Catalog normalisation**: the files are stored in **NFC** and with a stable key order;
   otherwise every export from the TMS produces an unreadable diff.

### 4.2 Pseudolocalisation — an automatic test, not a game

A synthetic locale (`en-XA` or equivalent) is generated from the source catalog, applying at
once: **expansion** (lengthening the string by a fixed percentage), **accenting** of every
character (to detect unextracted text: whatever reads normally is *hardcoded*),
**delimiters** at both ends (to detect truncation and overflow) and, in a second
variant, **bidi inversion** for the RTL rehearsal.

- ✅ It is deployed to an accessible environment and **the existing E2E tests are run against it**: if
  a selector depends on the visible text, the pseudolocale breaks it — and that is a finding too.
- ✅ A visual capture of the key screens in pseudolocale, compared as a visual regression.
- It detects, with no translator and at no cost: an unextracted string, a container that overflows, truncated
  text, concatenation (an unaccented chunk appears in the middle) and layout that does not survive RTL.

### 4.3 Behaviour tests (not implementation tests)

- **Formatting**: set an **explicit** locale and zone in every test. A test that passes on the
  developer's machine and fails in CI because of the environment's locale is a badly written test. ❌ Asserting
  the exact string `Intl` returns — **CLDR changes between ICU versions and the test breaks
  on its own**; assert properties (it contains the number, it uses the locale's separator) or pin
  the runtime's ICU version in the image.
- **Mandatory edges**: 0, 1, 2, 5, 11, 21, 100 in a language with `few`/`many` (Russian or Polish)
  and in Arabic; a name with an apostrophe and with non-Latin characters; text with a ZWJ emoji for
  truncation; a date at the instant of the daylight saving change in both directions; an amount in
  JPY (0 decimals) and in KWD (3); a string in NFD compared against the same one in NFC.
- **Error cases**: the translation is missing → a defined and **logged** *fallback*, never the raw
  key on screen; a corrupt catalog → a failed start-up, not silent degradation.

### 4.4 Translation workflow

- **A semantic key, never the English text as the key.** `checkout.payment.error.card_declined`,
  not `"Your card was declined"`. With the text as the key: any correction of a comma in the
  original invalidates all the translations, you cannot distinguish two uses of the same text that
  are translated differently (`Open` as a verb and as a state), and the key becomes unreadable in a
  non-English language.
- **Mandatory context on every key**: a description of what it is for, where it appears, a length
  limit if there is one, and **what each placeholder is**. A string without context gets translated badly and the
  error is only seen in production. If the format supports it (`.po` with extracted comments,
  XLIFF with `<note>`), the context travels in the file, not in a separate document.
- **A screenshot as context** when the platform supports it: it is what raises
  quality most per unit of effort.
- **The original is never edited in the TMS**: it is edited in the repository and flows towards the
  platform. The repository is the source of truth for the source text; the platform, for the
  translations.
- **Freeze the original before translating.** Translating text that is still changing multiplies the cost.
- **A glossary and a style guide per language** (formal/informal address, product
  terminology, what is **not** translated). Without this, each translator decides and the product speaks with
  several voices.

## 5. Security

### 5.1 A translation is untrusted input

**If the catalog can be edited by external contributors, the translated string is input
controlled by a third party and it goes straight into the interface.** Real vectors:

- **XSS through interpolation into HTML**: the translated string ends up in a `dangerouslySetInnerHTML`,
  `v-html`, `innerHTML` or `Html.Raw` because the original carried a `<b>`. ✅ **The catalog does not
  contain HTML**: the markup is passed as a *component/function* to the message (`<b>{x}</b>` resolved
  by the i18n runtime, not concatenated), and if it is unavoidable, **an allowlist of tags and
  sanitisation at the boundary**, with a CSP that prevents inline `script`.
- **Format injection**: a translation that introduces a non-existent placeholder or a
  malformed `{count, plural}` causes an exception or leaks the parameter object. Gate of §4.1.
- **Open redirect and *phishing***: a URL inside a translatable string. ✅ **URLs do not go
  in the catalog**: they go as a parameter from the code.
- **Unicode spoofing**: bidi control characters (`U+202E` and family) and homoglyphs in
  a translation visually alter what is read without changing the logical text. ✅ **Reject
  bidi control characters in the catalog** unless explicitly justified, and normalise.
- **Change control**: if there is open collaboration, **mandatory review before merging
  into the published language** and separation between "suggested" and "approved". The same criteria as a PR.
- **The translation platform is a third party with access to the product's text and to the accounts of
  those who translate**: it goes into the supplier inventory, with SSO and with revocation.

### 5.2 Personal data in the strings

- ❌ Real names, emails, phones or identifiers as **example text** in the
  catalog or in the context screenshots. It is processing of personal data exported to a
  third party (the TMS) and to external people. Synthetic data, always.
- ❌ Dumping user content into the translation platform "to give context".
- The personal data that is processed (name, address, phone) inherits the criteria of
  `privacy-engineering-standards`: minimisation, legal basis, retention. Here only the hard rule:
  **the catalog is not a place where personal data can end up**.

### 5.3 Machine translation and LLMs in the flow

- **Acceptable, with human review before publishing**: high-volume, low-risk content
  — help documentation, catalog descriptions, user-generated content,
  a first draft of non-critical interface strings.
- **FORBIDDEN to publish without review by a human professional competent in the target language**:
  - **Legal or contractual** text (terms, privacy notice, consent).
  - Text with a **medical, safety or financial consequence** (dosages, warnings, amounts,
    emergency instructions).
  - **Critical interface**: confirmation of an irreversible action, error messages that guide a
    decision, payment flows, authentication and account recovery.
  - Any text subject to a **regulatory language requirement** (see `grc-compliance-standards`).
- Cross-cutting rule: **unreviewed machine translation is marked as such in the system**
  (a state in the TMS) and **is never promoted to "approved" by a machine**. An LLM can propose
  and can detect inconsistencies; it cannot sign off.
- The LLM translates **the complete message with its context and its glossary**, not loose strings; and
  it is given the length constraint and the target language's plural categories as part of the
  assignment, or it will return strings that break §4.1.

## 6. Performance and operability

- **One catalog per language, loaded per language.** ❌ Serving every language to the client. Splitting
  by route or by view only if the catalog is genuinely large; measure first.
- **ICU data in the client**: if you use a library that bundles CLDR, **it is the largest cost
  in bytes of i18n**. Using the platform's `Intl` eliminates that cost entirely — it is the
  operational reason why `Intl` is the default of §2.
- **Server-side rendering**: the locale must be resolved **before** rendering; if the server
  renders in one language and the client hydrates in another, there is a hydration mismatch and flicker.
  The locale is part of the **cache key** (and of `Vary`, see `caching-cdn-standards`).
- **Minimum observability**: a metric of **missing keys per language and per version** (a rise
  indicates a code deployment without the catalog), a metric of languages actually used (to withdraw
  the ones nobody uses), and a log of the *fallback* applied. Without this, the degradation is invisible.
- **The runtime's ICU/CLDR version in production as an observable datum**: two replicas with different
  ICU format differently and sort differently. Pin it in the image.
- **Update cadence**: `tzdata` with every IANA release (several a year, §3.5); ICU and
  CLDR with the runtime's, checking that the collation changes do not invalidate indexes in the
  engine (that is governed by `sql-standards`, but **it is detected here**).

## 7. Sustainability and prohibitions

- **i18n-ready design from day one even if the product is monolingual.** What is expensive is not
  translating: it is discovering that the schema, the API and the templates assume a single language.
- **Declared debt**: if a shortcut is taken (a split name field, manual formatting), a
  `TODO` with the reason and an issue is left, not a comment.
- **Periodic catalog review**: dead keys out, coverage per language reviewed, and
  explicit withdrawal of a language nobody uses (with notice, not in silence).

Forbidden, without exception:

- ❌ **Concatenating sentence fragments** to build a message. This includes building the sentence with
  two-piece templates and injecting the verb by variable.
- ❌ **Using the English text as the catalog key**.
- ❌ `toUpperCase()` / `toLowerCase()` **without an explicit locale** for presentation, and using the
  interface's for comparison (the Turkish `i`, §3.4).
- ❌ **Sorting strings by code point** and calling it alphabetical order.
- ❌ Truncating or limiting text **by code unit** instead of by grapheme.
- ❌ A **home-made regex** to validate a phone, postcode, name or internationalised email.
- ❌ `float` for amounts; assuming **two decimals** in any currency.
- ❌ Storing an **offset** instead of an IANA zone identifier.
- ❌ Storing a **civil date as an instant** (birthday, due date, public holiday).
- ❌ Shipping a container image or a runtime to production **without an up-to-date `tzdata`**.
- ❌ **HTML inside the translation catalog**, and **URLs inside the catalog**.
- ❌ Publishing machine translation **without human review** in the classes of §5.3.
- ❌ Accepting a translation from an external contributor **without review** in a published language.
- ❌ A **binary** plural (`singular`/`plural`) in the catalog or in the code.
- ❌ Assuming that **RTL is the same layout mirrored**: directional icons are mirrored
  ("next" arrow, "undo") but **the non-directional ones are not** (a clock, a logo,
  some media); numbers and embedded code are still read left to right
  inside the RTL paragraph; charts, progress and tables change origin; and **it has to be
  tested in real Arabic or Hebrew**, not just with `dir="rtl"` over Latin text. The
  implementation with CSS logical properties is set by `frontend-web-platform-standards`.
- ❌ Setting the language by **IP geolocation** without allowing it to be changed and without persisting the
  choice.
- ❌ Asserting in a test the **exact string** produced by `Intl`/ICU without pinning the ICU version.
- ❌ Deploying code with new keys **without the corresponding catalog** (it breaks §4.1 and reaches
  production as a raw key on screen).

## 8. Mandatory web verification

Check **before pinning anything** in a real project:

1. **CLDR**: current version and date. Verified: CLDR 48 (2025-10-29), 48.1 (2026-01-08), 48.2
   (2026-03-17), and a JSON patch 48.2.1 for `tzdb` 2026c. **CLDR 49 + ICU 79 were announced
   for October 2026.** *Declared discrepancy*: the directory
   `https://www.unicode.org/Public/cldr/49/` **already exists** in the public listing but it only
   contains `README.html` — **the existence of the directory is not a release**; check
   `cldr.unicode.org/index/downloads` and the Unicode blog before asserting that CLDR 49 shipped.
2. **ICU**: the current version of ICU4C/ICU4J and the one your runtime ships. *Declared discrepancy*: the
   Atom feed of `unicode-org/icu` **mixes ICU4X tags** (`icu4x/2026-07-01/79.x`) with
   ICU releases (`ICU 78.3`, `ICU 78.2`, `ICU 78.1`); **the highest number in the feed is not the
   ICU version**. Cross-check with `icu.unicode.org`.
3. **Unicode**: 17.0 shipped on 2025-09-09; **18.0 was planned for 2026-09-15** —
   verify whether it has shipped and which Unicode version your runtime implements (not always the latest).
4. **`tzdata`**: the latest release at `data.iana.org/time-zones/tzdb/NEWS` (verified: **2026c,
   2026-07-08**) and, above all, **which version each copy on your system has**: base image, JDK,
   runtime, database and embedded date library.
5. **`Temporal`**: the status in `@mdn/browser-compat-data` and on MDN (verified: **not Baseline**,
   Safari only in *preview* behind the `useTemporal` flag, Safari iOS no). Also verify whether Node
   26 has entered LTS (in Aug 2026 it was *Current*, `lts: false`).
6. **`Intl`**: the real support for the specific API you are going to use in your browser and runtime
   targets, and **whether the runtime carries full ICU or *small-icu***.
7. **MessageFormat 2**: the status in CLDR/UTS #35 **and separately** the status of
   `tc39/proposal-intl-messageformat` (verified: `Stage: 1`) and the real support in your TMS and in
   your library. Do not confuse a stable standard with an available API.
8. **`libphonenumber`**: the latest tag (verified `v9.0.36`) and **the licence read from the raw
   `LICENSE`** (verified Apache-2.0). If you use an npm wrapper, verify that it is still maintained and
   that its coverage is the one you need.
9. **Translation platforms**: price, free plan limits, open source plan terms and
   **the real licence read from the repository's `LICENSE`**, not from the *marketing*.
   Verified in Aug 2026 (§2.4). **Warning**: software comparison directories
   gave incorrect data for Lokalise (they listed a free plan; the official site has none) and
   fixed entry prices for Crowdin and Transifex, which are priced by volume. **Source = the official
   page and the raw `LICENSE`.**
10. **ISO 4217** (minor units per currency) and **ISO 3166-1** (country list): take them from
    CLDR, not from a copy; both change.
11. **UPU S42** for international address format, and the name references of §3.1
    (W3C *Personal names around the world*; *Falsehoods programmers believe about names*) —
    verify that they are still accessible and whether there is a more recent version.
12. **Declared gap (no verification budget in this pass)**: the status, licence and limits of other
    relevant platforms have not been verified (**Phrase, Pontoon, Locize,
    Localazy, Weglot, Smartling**), nor the detail of the machine translation credits in Tolgee's
    free plan (the page does not publish them in figures). **It is not filled in by analogy**:
    if the project considers them, verify them on their official page and in their `LICENSE`.
13. **Declared gap**: no study with a published methodology has been located on the
    impact of pseudolocalisation or of human review on the localisation defect rate.
    The figures circulating in TMS vendors' commercial material
    («X % fewer defects», «Y % savings») **have no published methodology and are deliberately
    discarded**: there is no number here because there is no source.

If the web contradicts this document, **the web wins** — flag the discrepancy.
