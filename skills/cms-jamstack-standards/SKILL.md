---
name: cms-jamstack-standards
description: Use when deciding where content lives and who edits it - choosing between Markdown/MDX files in the repo, a git-based CMS (Decap admin/config.yml, TinaCMS), self-hosted open-source headless (Strapi, Directus, Payload, Keystone), paid SaaS headless (Contentful, Sanity, Storyblok, Prismic, Hygraph) or a coupled CMS (WordPress wp-config.php and plugins, Drupal), content modeling with content types, fields, references, localization and schema migration, sanity.config.ts or contentful space migration scripts, content collections and frontmatter schemas, draft and preview modes, publish webhooks and on-demand revalidation or cache purge after publish, stale content after a publish, image CDNs and per-transformation billing (Cloudinary credits, Cloudflare Images, imgix), free-plan API-call quotas and what breaks when you exceed them, editor accounts roles and MFA, plugin supply chain, stored XSS from a rich-text editor, exposing the content API, webhook signature verification, or exporting content out of a CMS before you are locked in.
---

# CMS and Jamstack standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Axis**: choosing **where the content lives and who edits it**, with **the cost and the lock-in
explicit** from day one. It is not a matter of technological taste: it is an open-ended contract with
a provider, a data model and a human workflow. **A CMS you do not know how to leave is an indefinite
contract**, and the exit price is negotiated on the way in, not once it already hurts.

Triggers: `content/**/*.md`/`*.mdx` with frontmatter, `content.config.ts` / content collections,
Decap's `admin/config.yml`, `tina/config.ts`, `sanity.config.ts`, `strapi/config/`,
`docker-compose.yml` with Strapi/Directus, `payload.config.ts`, `keystone.ts`, `wp-config.php`,
Drupal's `composer.json`, Contentful space migration scripts, a CMS's `/graphql` or `/api/content`
endpoints, publish webhooks, `revalidatePath`/`revalidateTag`/purge-by-tag after publishing, image
CDN URLs with transformation parameters, API call quotas on a SaaS CMS plan.

**Not applicable**:
- `frontend-frameworks-standards` — **the framework, the rendering model (SSG/SSR/ISR/islands) and
  how data is loaded are theirs**. Here **which content event triggers which regeneration** and what
  the data contract the framework consumes is. If `next/image` or Astro's `<Image>` is what serves
  the image, that is theirs; **how much each transformation costs in the image CDN belongs here**.
- `frontend-web-platform-standards` — the browser platform, the HTML/CSS, the CSP and page weight.
  Here only the content injected into them and its sanitisation at the source.
- `design-systems-standards` — **reciprocal**: the design system provides the components that render
  what this content says. The content model does **not** define UI components, and the design system
  does **not** define content types. If the content types are named the same as the components, you
  have a CMS coupled to a redesign.
- `caching-cdn-standards` — **the HTTP cache, the CDN, `Cache-Control`, surrogate keys and purging
  are theirs**. Here only the **publish event** that triggers that purge and which keys it must
  purge.
- `api-design-standards` — **the content API contract** (REST/GraphQL, pagination, versioning, error
  codes) is theirs. Here which fields it exposes and to whom.
- `php-standards` — **WordPress and Drupal are PHP: the code, in-house plugins, Composer and code
  quality are theirs**. Here the **platform decision and its operation**: if WordPress is chosen, how
  it is updated, how it is protected and when headless is used.
- `appsec-standards` (methodology and threat modelling; here the concrete CMS controls),
  `identity-access-management-standards` (**editors' identity, SSO and MFA are theirs**; here that
  they are mandatory and with which roles), `secrets-management-standards` (custody of CMS API
  tokens and webhook secrets), `data-governance-quality-standards` (data and glossary ownership),
  `privacy-engineering-standards` (personal data in forms, cookie consent),
  `grc-compliance-standards`, `cicd-standards` (the pipeline that builds and deploys),
  `object-storage-standards` (where the binaries live), `kubernetes-standards` (if the self-hosted
  CMS runs there), `observability-standards`, `backup-recovery-standards` (**the CMS database backup
  and its tested restore are theirs**; here that the content falls within scope),
  `search-engines-standards` (site search).

## 2. Default decisions

> Verify the latest version, the licence and **the current price** on the web before committing to
> them (§8). Versions and licences read from the npm registry and from the raw `LICENSE` as of
> **Aug-2026**; prices from the provider's website. **Prices change without notice and secondary
> sources contradict each other.**

### Decision 0: is a CMS needed at all?

**The real criterion is about people, not technology: if whoever edits is not whoever deploys, a CMS
is needed.** Everything else is secondary.

| Situation | Answer |
|---|---|
| The content is written by the same team that deploys, and they know how to use Git | **Files in the repo**: Markdown/MDX with typed frontmatter and a static generator. No database, no provider, no invoice, reviewable in a PR, with history and rollback for free |
| Technical documentation, engineering blog, changelog, release notes | **Files in the repo**, always. Putting a CMS here is adding a provider so engineers can write Markdown |
| Marketing, copywriting or the business edits, and they are not going to open a PR | **CMS.** And the discussion ends there: forcing a non-technical editor to use Git produces stale content and an engineer acting as a secretary |
| A non-technical editor but few changes a month, in a repo | **Git-based CMS** (Decap, Tina): an editing interface over commits. No database and no lock-in — the content is still yours, in your repo |
| Several languages, approval workflows, scheduled publishing, many concurrent editors | **A real CMS** (headless or coupled). A git-based CMS does not sustain concurrency or workflow |
| Content consumed by web **and** a mobile app **and** another channel | **Headless**, by definition |
| "Maybe some day marketing will edit it" | **Not an argument.** Migrating from files to a CMS is easy (the content is structured and exportable). Getting out of a SaaS CMS is the expensive part |

### Taxonomy and choice criteria

| Model | Examples | Choose it when | The real cost |
|---|---|---|---|
| **Content in the repo** | Markdown/MDX + the framework's typed collections | Technical people write it; content versioned with the code | Zero visual editor, zero approval workflow, zero concurrency |
| **Git-based** | Decap, Tina | One non-technical editor and low volume; you want zero lock-in | Every publish is a commit → a build. No concurrent drafts and no serious workflow |
| **Self-hosted open-source headless** | Strapi, Directus, Payload, Keystone | Control of the data, residency requirements, predictable cost, a bespoke content model | **You operate the service**: database, backups, patching, scaling, uptime. It is not free, it is "paid in operations" |
| **SaaS headless** | Contentful, Sanity, Storyblok, Prismic, Hygraph | You want zero operations, with availability and a content CDN included | An invoice that grows with traffic, limits that break the site when exceeded, and lock-in to a proprietary content model |
| **Coupled / traditional** | WordPress, Drupal | The content *is* the product; editors are used to it; the plugin ecosystem already solves the requirement | A large attack surface and mandatory continuous maintenance (§5) |

**Honesty rule**: "self-hosted open source" does not mean free, it means **the cost is in your
operations team**, and "SaaS" does not mean no engineering cost, it means **the cost is in the
invoice and in the exit**.

### Verified status as of Aug-2026 — licences and pricing model

| Product | Version | Licence | Pricing model and limits |
|---|---|---|---|
| **Strapi** | `@strapi/strapi` **5.51.1** | **Dual, read from the `LICENSE`**: anything outside `ee/` is **MIT**; everything residing under an `ee/` directory is the **Enterprise Edition under a proprietary licence**. "Strapi is MIT" is a half-truth | Community self-hosted with no call or content limit; the team features (Releases, Content History, SSO, audit logs, review workflows) are paid. Growth quoted at **$45/month with 3 seats, +$15/seat**; SSO as a separate add-on. Enterprise bespoke. **Verify on strapi.io** |
| **Directus** | **12.2.0** | ⚠️ **No longer open source**: **Monospace Sustainable Core License (MSCL-1.0-GPL)**, copyright 2026 Monospace Inc. Source-available, derived from the Fair Core License. It forbids *Competing Use*; **each version becomes GPLv3 after 4 years**. It also forbids disabling or circumventing the licence key check | Free commercial use only under the **Open Innovation Grant** (verified: **<$5M annual revenue and <50 employees**), or within the limits of the *free core tier*; above that, a paid licence with a key. **The SDKs are still MIT.** This change (v12) is the most expensive finding in this table: **if your company exceeds the thresholds, Directus stops being free** |
| **Payload** | **3.87.0** | **MIT** | Free self-hosted. **Ownership change verified: Figma acquired Payload (Jun-2025)**; the team joined Figma, the MIT licence and the repo remain. **Payload Cloud closed new sign-ups**: if you were counting on their managed hosting, it is not an option. The risk to name is the "acquired and then neglected" pattern; MIT bounds the worst case but obliges nobody to maintain it |
| **Keystone** | `@keystone-6/core` **8.0.2** | **MIT** (Thinkmill) | Free self-hosted. **Keystone 5 is in maintenance mode**; the live line is 6. A single-consultancy project: name that dependency before choosing it |
| **Decap CMS** | `decap-cms-app` **3.15.1** | **MIT** | Free. Maintained by the community after the handover from Netlify (2023): **alive but low velocity**. No database and no lock-in — the content is files in your repo |
| **Tina** | `tinacms` **3.11.0** | **Apache-2.0**, not MIT | An editor over Git; the managed backend (Tina Cloud) is paid with a free plan. Self-hostable |
| **Contentful** | SDK `contentful` **11.12.7** (MIT) | Proprietary service | ⚠️ **Verified in their own changelog (announced 2025-12-09): on reaching the monthly asset bandwidth or API limit, the Free plan makes Contentful "automatically pause delivery APIs (CDA, CPA, GraphQL)" until the following month or until moving to a paid plan.** There is no overage: **the site stops serving content**. The jump to the first paid plan is thousands of euros a year |
| **Sanity** | SDK `@sanity/client` **7.26.0** (MIT) | Proprietary service, with an open-source Studio | **Usage-based** pricing: when you exceed what is included **it does not cut you off, it bills you**. It is the most benign model for availability and the most dangerous for the budget. **Usage alerts mandatory from day one** |
| **Storyblok** | SDK `@storyblok/js` **6.3.0** (MIT) | Proprietary service | Billed by **seats + languages + CDN calls + spaces**. On the lower plans, exceeding the limit **throttles the API**: silent degradation of the site with nobody receiving an invoice or an alert |
| **Prismic / Hygraph** | — | Proprietary service | Free plans with a **hard quota**; once exhausted, the service stops. The first paid tier is a big jump. Verify the figures on their site |
| **WordPress** | **7.0.2** (verified on `api.wordpress.org`) | GPLv2+ | Free core; the cost is in hosting, premium plugins and **continuous maintenance** (§5). See the dedicated section |
| **Drupal** | **11.4.4**; supported branches **10.6, 11.3, 11.4** | GPLv2+ | Free; the cost is in operations and in major upgrades, which are projects, not tasks |

**The three behaviours on exceeding the limit** — it is the selection criterion most people discover
too late. Choose knowing which of the three you can tolerate:

| Behaviour | Who | Consequence |
|---|---|---|
| **Hard cut-off** | Contentful (Free), Prismic (Free) | The site stops serving content. A production incident caused by an invoice |
| **Silent throttling** | Storyblok (low plans) | The site degrades and nobody notices until someone complains |
| **Billed overage** | Sanity, most paid plans | The site stays up and the surprise arrives in the invoice |

Whichever it is: **a usage alert at 70% of each quota**, and the number of calls to the CMS API is a
production metric with a threshold, not a curiosity on the provider's dashboard.

### WordPress: treated separately because of its market share

It is the most used platform on the web (~42% of sites according to W3Techs, Mar-2026) and therefore
the most attacked. Deciding about WordPress requires looking at three things that are usually
omitted:

- **Governance — a verifiable fact, taking no side.** Since Oct-2024 there has been a **public
  conflict and open litigation between WP Engine and Automattic/Matt Mullenweg**, still active in
  2026 (an injunction in WP Engine's favour in Dec-2025; an amended complaint in Feb-2026;
  *discovery* disputes and a sanctions motion in Jul-2026; settlement talks ongoing).
  Structurally: **wordpress.org has no formal governing body and no oversight board**, and the
  trademark is held by the WordPress Foundation with an exclusive commercial licence to Automattic.
  An attempt at reform towards an independent foundation ran out of funding in 2026.
  **An engineering consequence, not an opinion**: the ecosystem depends on the decisions of a single
  person with no public process. That is a **vendor risk** to be written into the risk register
  alongside the contingency plan (fork, exit to another CMS, alternative hosting). It is not an
  automatic reason to rule out WordPress; **it is a reason not to pretend it is a project with
  neutral governance**.
- **Attack surface.** Verified data from Patchstack's *State of WordPress Security in 2026* report
  (published Feb-2026, on 2025 data): **11,334 new vulnerabilities in the ecosystem (+42%
  year on year)**, of which **~91% in plugins and ~9% in themes**, with **a minimal figure in the
  core and of low risk**. **70% of those exploited are exploited within the first 7 days** and a
  significant share within the first hours; hosting defences blocked a small fraction.
  **The correct reading: the WordPress core is not the problem; your plugins are.** Every plugin is a
  dependency with administrator permissions on your site.
- **Update discipline, non-negotiable if you choose WordPress**: core with automatic minor updates
  enabled; plugin patches **within 24-48 h** for high severity, with a defined emergency window; a
  *staging* environment with a clone of production; a plugin inventory with an owner and a
  justification; **removal** (not deactivation) of everything unused; and a subscription to an
  ecosystem advisory feed. A WordPress site with nobody responsible for applying patches weekly is
  an incident pending a date.
- **When to use it headless**: when the editorial team already lives in WordPress and you are not
  going to move them, but the presentation layer needs to be something else. It provides: the
  frontend stops running PHP and stops exposing themes and plugins to the visitor. **It does not
  provide**: the admin backend is still exposed, is still the same target and still needs the same
  maintenance. **Headless is not a security measure**; it is a separation of layers that reduces the
  *public* surface, not the real one.

## 3. Structure and conventions

### Content modelling: a content schema is a data schema

And therefore **it is designed, versioned and migrated just like a database schema**. The expensive
mistake is treating it as configuration to be poked at in a web interface with no trace left behind.

- **Model by meaning, not by appearance.** A `Page` type with `block1`, `block2`,
  `backgroundColour`, `leftColumn` fields is an HTML editor in disguise: the content becomes useless
  for a second channel and dies with the next redesign. Field names describe **what** the data **is**
  (`summary`, `publicationDate`, `author`), never **where it is rendered**.
- **References instead of duplicates.** Author, category or product are referenced entities. Copying
  the author's name into every article guarantees 200 articles will be wrong the day they get
  married.
- **Fields required and validated in the CMS**, not just in the frontend: title length, mandatory
  image alternative text, date format. **Alternative text is a required field**, not a suggestion —
  it is the only way for content accessibility not to depend on goodwill (the conformance criteria
  belong to `accessibility-standards`).
- **The schema lives in code and in version control** (`sanity.config.ts`, Strapi/Payload types,
  Contentful space migration scripts). A schema that only exists in the provider's web interface
  cannot be reviewed, nor diffed between environments, nor recreated after a disaster.
- **Content migrations by script, idempotent and reversible**, run first in a
  pre-production environment with a copy of the real content. Renaming a field in production
  "because it is quick" is how content is lost without anyone noticing until weeks later.
- **Localisation decided at the start**: translatable field vs. an entry per language vs. a tree per
  region. Changing strategy later is a full migration. And note: **in several SaaS products languages
  are a billing axis**, so the modelling decision is also a cost decision.
- Rich content is stored in a **structured, portable** format (AST/Portable Text/blocks),
  not in raw HTML. Stored HTML is content coupled to a design and a source of stored XSS (§5).
- Files in the repo: frontmatter with a **schema validated at build time** (the framework's typed
  collections). A misspelled field must break the build, not appear empty in production.

### Publishing, generation and the real problem: cache invalidation

**This is where most people fail.** Publishing is easy; making the change appear —and only where it
should— is the hard part. The publish event is a distributed-system event with all its problems.

- Choose the strategy per page type, not per site (the rendering model belongs to
  `frontend-frameworks-standards`; here **what triggers it**):
  - **SSG with a full rebuild**: correct as long as the build takes minutes, not hours. With
    thousands of pages it stops being so and nobody reviews it until publishing takes 40 minutes.
  - **On-demand revalidation / purge by tag from a webhook**: the default for a site with content
    that changes over the course of the day. It requires **mapping every content entry to the routes
    and cache keys it affects** — and that mapping is the part that gets forgotten.
  - **ISR / time-based revalidation**: acceptable as a safety net **behind** the purge, never as the
    only mechanism: it means accepting stale content for the duration of the window.
- **The article's page is not the only one affected**: the index, the home page, the RSS feed, the
  sitemap, the category pages, the "related" items and the navigation. **Purging only the edited URL
  is the classic bug** — the editor sees their change and swears the home page is broken.
- **Purge by tag/surrogate key, not by URL** whenever the CDN allows it (the mechanics belong to
  `caching-cdn-standards`). By URL it does not scale and there is always one missing.
- **An unpublish and a delete must purge just like a publish**, and return 404/410 —not a cached
  page. It is the case nobody tests and the one that ends up in a legal incident when what was
  unpublished was a price or a press release.
- The webhook **fails**: retries with backoff, **a queue with manual retry** and a **periodic
  reconciliation** (scheduled revalidation of everything published in the last N hours). A publishing
  system whose only happy path is "the webhook arrived" produces the ticket "I published and it does
  not show".
- **Feedback to the editor**: the interface must say whether the change is already in production.
  Without that, the editor publishes five times, triggers five builds and calls support. It is the
  number one cause of inflated build bills.
- Deduplicate and batch: twenty changes in a minute are not twenty rebuilds. Debounce in the
  webhook receiver.

### Preview and drafts

- **The preview uses draft content and real data**, on a non-indexable URL and **behind
  authentication or a signed, short-lived token**. A guessable preview URL is an embargo leak — the
  typical case is the earnings release or the product launch.
- `X-Robots-Tag: noindex` on everything that is a preview, and checked. An indexed preview is
  duplicate content and sometimes confidential content in a search engine.
- The preview is **never served from the public cache** nor shares a cache key with production: it is
  the direct route to a draft appearing to an anonymous user.
- Scheduled content: future publication is executed by a system job, and **it must purge the cache
  when it activates**. Content "published at 9:00" that appears at 11:00 because nobody invalidated
  anything is the same old bug in a different disguise.

### Images and assets

- Binaries do not live in the CMS database or in the Git repo (see `object-storage-standards`).
  In the repo, moreover, a `.psd` or a video poisons the history forever.
- **The image CDN bills by transformation, by storage and by delivery, and all three count.**
  Verified as of Aug-2026 (**volatile prices: confirm on the provider's site, §8**):
  - **Cloudflare Images**: the first **5,000 unique transformations/month included**, then **$0.50
    per 1,000**; storage **$5 per 100,000 images/month**; delivery **$1 per 100,000/month**. On the
    Free plan, once the limit is exceeded the already-cached transformations keep being served and
    **new ones return error 9422** — partial degradation, at no charge.
  - **Cloudinary**: a system of fungible **credits** (1 credit ≈ 1,000 transformations **or** 1 GB of
    storage **or** 1 GB of delivery). Free quoted at **25 credits/month**. Being a single pot,
    **whatever you consume most eats the quota**, and it is usually bandwidth.
  - **imgix**: migrated to a **credit** model (previously by *origin images*); overage quoted at 120%
    of the price per credit and the possibility of blocking on reaching the limit.
  - Design consequence: **the set of variants is a budget.** Each size × format × crop
    is a billable transformation. Fix a **closed** list of widths and formats, do not generate
    variants from URL parameters open to the public, and **cache aggressively** — an uncached
    transformation URL is paid for every time.
  - **Never accept transformation parameters from the URL without an allowlist or a signature**: it
    is at once an open invoice to anyone and an amplification vector.
- Formats and `srcset` are decided by `frontend-web-platform-standards`; the weight thresholds, by
  `web-performance-standards`. Here: that the CMS **requires** uploading an original of sufficient
  quality and records dimensions and alternative text.

### Migration and exit: tested, not assumed

- **Before signing**, check: is there a complete export API (content, assets, references,
  versions, drafts and translations)? is it quota-limited? is the format reusable or is it a
  proprietary dump?
- **Run the full export during the evaluation phase**, not when you want to leave. If you cannot
  export it in the first month, you will not be able to in the third year.
- **Automated, periodic export to your own storage** from day one, with the same
  discipline as a backup: verified and with a tested restore (see `backup-recovery-standards`). A
  SaaS CMS **is not your backup** — its SLA covers its service, not your right to take the data away.
- What really ties you down is not the API: it is the **proprietary fields, the rich text format, the
  image transformations embedded in the provider's URLs and the reference model**. Minimise the
  coupling by keeping a **mapping layer** between the CMS response and the model your
  application uses. Without that layer, changing CMS means rewriting the frontend.
- Write the **estimated cost and timescale of the exit** into the initial decision. If nobody can
  state it, you have not yet evaluated the provider.

## 4. Quality and CI gates

In increasing order of cost; each one breaks the build or the deployment:

1. **Content schema validation**: typed frontmatter/collections, mandatory fields
   present, resolvable references. Invalid content **breaks the build**, it does not degrade
   silently.
2. **Internal links and assets**: a broken link or a missing image is a content defect
   detectable in CI. External links, in a separate scheduled job (they fail for external reasons).
3. **Schema migrations**: they are run against a copy of the production content in
   pre-production before touching production, with a tested rollback.
4. **Publishing path test** —the one nobody tests and the one that always fails—: publish in
   pre-production and automatically verify that (a) the page appears, (b) **the index and the home
   page are updated**, (c) an unpublish stops being served and returns 404/410, (d) a webhook failure
   is recovered by reconciliation.
5. **Preview**: verify that a preview URL is **not** accessible without a token and is **not**
   indexable.
6. **Build budget**: build duration and number of builds per publish, measured. If publishing
   a typo costs 30 minutes of build, the generation strategy is badly chosen.
7. **Provider quotas**: API calls, bandwidth and image transformations against the
   plan limit, with an alert at 70%.

## 5. Security: the CMS is the most common attack surface of a corporate site

A static site with no CMS has a minimal surface. As soon as there is a CMS, an administration panel
exposed to the Internet appears, along with human accounts, an editor that accepts HTML and a plugin
ecosystem. It is, by far, the component they get in through.

- **Editor accounts with mandatory MFA and SSO** where the organisation makes it possible (identity
  belongs to `identity-access-management-standards`). Attacks on WordPress and on CMS panels are
  massively credential-based: brute force, reuse and phishing of the marketing team, who do not get
  the security training the engineering team gets.
- **Minimal, reviewed roles**: the editor edits, does not install plugins nor change the schema nor
  see the configuration. **Nobody works day to day with the administrator account.** Quarterly review
  of accounts and **immediate deprovisioning on leaving the company or the agency** — external agency
  accounts are the hole that survives the commercial relationship by years.
- **The administration panel not publicly exposed** where feasible: IP restriction, VPN or
  pre-authentication at the edge. If it has to be public, then MFA, rate limiting and brute-force
  blocking are mandatory.
- **Plugins and extensions are supply chain with administrator privileges.** Rule: an inventory
  with an owner and a justification per plugin, as few as possible, none without recent maintenance,
  never a "nulled"/pirated one, and **removal** (not deactivation) of the unused ones — a deactivated
  plugin is still code on disk and has been a real exploitation vector. Data from §2: **~91% of the
  WordPress ecosystem's vulnerabilities are in plugins**, and a good share are exploited within
  hours.
- **Stored XSS from the rich text editor**: it is the structural vulnerability of every CMS.
  The editor stores HTML and someone renders it. Controls: store **structured format, not HTML**;
  **sanitise on the server both on save and on serve** (never only on the client, never only once);
  an allowlist of tags and attributes, not a denylist; and **embedding `<script>`, `<iframe>` or
  `onerror` from the editor is forbidden** — if an embed is genuinely needed, it is a specific field
  type with allowlisted providers, not free HTML. An editor with privileges is not a trusted user: it
  is an account that can be stolen.
- **File uploads**: validation by **real content**, not by extension or by `Content-Type`;
  an allowlist of types; a system-generated name; storage **outside the web root** or in object
  storage with **execution disabled**; `Content-Disposition: attachment` and
  `X-Content-Type-Options: nosniff` when serving; a size limit; and **SVG treated as executable
  code** (sanitised or outright forbidden). An uploads directory that executes PHP is the classic
  route to RCE.
- **Exposure of the content API**: the read token that goes to the frontend is public de facto — make
  it **read-only, published content only and for a single environment**. **Never a write or
  management token in the client or in the bundle.** And check what the API actually returns: many
  expose drafts, internal fields, author emails or the whole schema if you ask correctly.
- **Webhook secrets with a verified signature**, no exceptions: HMAC with a shared secret,
  **constant-time comparison**, timestamp validation to reject replays, and **rejection by default**
  if there is no valid signature. A revalidation endpoint with no signature is a free DoS against
  your build and your CDN, and sometimes something worse. The secrets, in
  `secrets-management-standards`; rotation included.
- **Environment separation**: the production CMS does not share credentials or a database with the
  pre-production one, and test content does not reach production. Copying production to
  pre-production drags personal data along: anonymise it (`privacy-engineering-standards`).
- **Forms and comments** are untrusted input on the public site: rate limiting, anti-spam
  protection, server-side validation and, if they collect personal data, a legal basis and retention
  (`privacy-engineering-standards`).
- **Backup of the content and of the database with a tested restore**
  (`backup-recovery-standards`). The realistic scenario is not disk failure: it is an editor deleting
  200 entries or a compromise that modifies them.

## 6. Operational cost, caching and outages

- **The cost has five axes and all of them grow with success**: CMS API calls, CDN bandwidth,
  image transformations, **build minutes** and **editor seats**. Seats and languages are the most
  surprising ones because they grow through business decisions, not traffic.
- **Model the cost at twice the projected traffic before signing.** If at 2× the plan becomes
  unaffordable, you already know the date of your forced migration.
- **Usage alerts at 70% of each quota**, with an owner. Discovering the limit because the site
  stopped serving content is an operational failure, not the provider's.
- **The cache is what saves you from the invoice and from the outage at the same time**: if the
  frontend queries the CMS API on every user request, you are paying per visit and your availability
  is the CMS's. Published content is served **from generated HTML or from the edge cache**, not from
  the CMS live. The concrete policy belongs to `caching-cdn-standards`.
- **What breaks when the provider goes down** — this is decided in advance:
  - **Statically generated** site: nothing visible breaks. Only publishing stops being possible.
    **It is the strongest availability argument in favour of generating**.
  - Site with **fetch at render time**: it goes down with the provider. Mandatory mitigation:
    `stale-if-error` at the edge, short timeouts, and **a local copy of the last good content** to
    serve degraded.
  - **Images**: if the image CDN goes down and your URLs point at it, the site looks broken even
    though the HTML is being served. Consider your own domain in front so you can repoint.
  - **Preview and the editing panel**: they go down. Acceptable — it is not end-user traffic.
- A publishing failure **must not take down the site**: the previous content keeps being served. If a
  malformed webhook can empty the whole cache, you have an exposed self-destruct button.
- Instrument: CMS API latency and errors, webhook success rate, the delay between publishing and
  appearing (**the real SLI of the editorial system**), build duration and count, and consumption
  against quota.

## 7. Sustainability and prohibitions

- **Review the provider every 12 months**: price, licence, ownership and plan changes. Verified in
  this very wave that in less than two years there were changes to **Directus's licence** (v12, it
  stops being open source), **Payload's ownership** (Figma) with sign-ups closed on their cloud, and
  **Contentful's free plan policy** (pausing the delivery APIs).
- Updates of the self-hosted CMS: security patches **immediately**; majors planned as a
  project with schema migration and testing. A self-hosted CMS two majors behind is a breach
  waiting for a date.
- The content outlives the site: **periodic export to your own format** is the project's life
  insurance and it is tested, like a backup.

**FORBIDDEN:**
- ❌ Putting in a CMS when whoever edits is whoever deploys. Documentation and technical blogs go in
  the repo.
- ❌ Choosing a SaaS CMS **without having read what happens when each quota is exceeded** and without
  modelling the cost at 2× the traffic. Verified: Contentful **pauses the delivery APIs** on the Free
  plan; Storyblok **throttles** on the low plans; Sanity **bills you for the excess**.
- ❌ Stating a CMS's licence from memory. Verified as of Aug-2026: **Directus is no longer open
  source** (MSCL-1.0-GPL, free only under the Open Innovation Grant: <$5M revenue and <50 employees),
  **Strapi is dual** (`ee/` is proprietary) and **Tina is Apache-2.0**.
- ❌ Adopting a CMS without running **a full content export** during the evaluation.
- ❌ Modelling the content by its appearance (`block1`, `leftColumn`, `backgroundColour`) instead of
  by its meaning. And ❌ duplicating entities instead of referencing them.
- ❌ Changing the content schema directly in the production interface, with no script, no versioning
  and no rehearsal in pre-production.
- ❌ Purging only the edited URL: the index, the home page, the feed, the sitemap and the categories
  change too.
- ❌ Making "the webhook arrived" the only freshness mechanism. Without retries, a queue and scheduled
  reconciliation, stale content is guaranteed.
- ❌ Unpublishing or deleting without purging the cache and without returning 404/410.
- ❌ A preview URL without a short-lived token, without `noindex` or served from the public cache.
- ❌ A CMS write or management token in the client, in the bundle or in the repository.
- ❌ A revalidation or webhook endpoint **without signature verification** (HMAC, constant-time
  comparison, timestamp). And ❌ accepting it "because the URL is secret".
- ❌ Storing raw HTML from the rich text editor and rendering it without sanitising on the server.
  ❌ Allowing `<script>`, `<iframe>` or `on*` from the editor.
- ❌ Uploads validated by extension or by `Content-Type`; an uploads directory with execution enabled;
  SVG served without sanitising.
- ❌ Editor accounts without MFA; editors with an administrator role "because it is more convenient";
  external agency accounts that outlive the contract.
- ❌ A WordPress/Drupal plugin with no owner or justification, with no recent maintenance, or
  "nulled". ❌ Leaving deactivated plugins on the server instead of removing them.
- ❌ Operating WordPress with nobody responsible for applying patches within 24-48 h. ❌ Selling
  "headless" as if it were a security measure for the backend.
- ❌ Querying the CMS API on every user request with no cache: you pay per visit and you inherit its
  availability.
- ❌ Generating image variants from open URL parameters, with no allowlist or signature: it is an open
  invoice to anyone.
- ❌ Treating the SaaS CMS as the content's backup.

## 8. Mandatory web verification

Before committing to anything, check online (the npm registry and Atom feeds
`https://github.com/OWNER/REPO/releases.atom` — **`api.github.com` gives 403 unauthenticated**; **the
project's and the provider's official sites to cross-check**, because the GitHub feed **is not the
source of truth**; the raw `LICENSE` for licences; **the provider's pricing page** for cost, never an
aggregator):

1. **Licences, one by one and from the raw `LICENSE`**: Directus (is it still MSCL? have the Open
   Innovation Grant thresholds changed?), Strapi (what is left outside `ee/`?), Payload, Keystone,
   Decap, Tina. **This is the datum that has changed most in this domain.**
2. **Project ownership and status**: Payload under Figma (is it still maintained? did Payload Cloud
   reopen?), Keystone (is 6 still active or did it follow 5 into maintenance?), Decap (real commit
   velocity, not the badge).
3. **Price and free-plan limits, and what happens when they are exceeded**, on the provider's site:
   Contentful, Sanity, Storyblok, Prismic, Hygraph, Strapi Growth/Cloud, Tina Cloud. Confirm in
   particular whether Contentful still pauses CDA/CPA/GraphQL on the Free plan.
4. **Versions**: WordPress (`https://api.wordpress.org/core/version-check/1.7/` gives the current one
   and the minimum PHP) and Drupal (`https://updates.drupal.org/release-history/drupal/current` gives
   the supported branches and the EOL of 10).
5. **Status of the WordPress litigation and governance**: primary sources (the court docket, the
   parties' statements). **Taking no side**: the datum that matters is whether the vendor risk
   changed.
6. **Ecosystem vulnerability data**: the current year's annual Patchstack/Wordfence report, and
   advisories for the specific plugins you have installed.
7. **Image CDN prices** (Cloudflare Images, Cloudinary, imgix, ImageKit, bunny.net): they change
   model, not just price — imgix has already migrated from *origin images* to credits.
8. **CVEs for the chosen CMS** (`github.com/advisories`, osv.dev, project bulletins) before each
   deployment and on a continuous basis.

**Gaps not verified as of Aug-2026** (do not fill from memory):
- **Exact figures for Contentful's Free plan** (API calls/month, bandwidth, users): **not
  verified** — the secondary sources openly contradict each other (100K vs. 1M calls). What **is**
  verified from a primary source is the **behaviour on exceeding it** (pausing CDA/CPA/GraphQL).
- **Prices for Strapi Growth/Enterprise, Sanity, Storyblok, Prismic and Hygraph**: **not verified
  from a primary source**; the figures quoted in §2 come from third-party analyses and must be
  confirmed on the provider's site before budgeting.
- **The exact limits of Directus's *free core tier*** (above the Open Innovation Grant): **not
  verified**. What is verified, from their `LICENSE` and their announcement: the MSCL licence, the
  conversion to GPLv3 after 4 years and the Grant thresholds (<$5M, <50 employees).
- **Cloudinary's and imgix's current prices and credits**: **not verified from a primary source**
  (**Cloudflare Images' are**, they come from their official documentation).
- **The real maintenance status of Keystone 6 and of Decap**: **not verified** beyond the date of the
  last release. Look at commits, closed issues and the response to advisories, not downloads.
- WordPress's market share (~42%, W3Techs Mar-2026): **a third-party figure**, not re-verified.
- The real cost of operating a self-hosted headless (database, backups, HA, on-call): **it depends on
  your organisation**; the table in §2 does not estimate it.

**Declared discrepancies**:
- **The WordPress core in Patchstack's 2026 report**: some coverage cites **six** vulnerabilities
  in the core in 2025 and other coverage **two**; their own live 2026 statistics show **0** in the
  core and a plugins/themes split different from the annual report's (~80/20 versus 91/9). **The
  conclusion does not change** —the risk is in plugins, not in the core— but **do not quote the exact
  figure without going to the report**.
- **WordPress version**: several third-party trackers were still listing 6.8 or 6.9.x as current in
  2026. **`api.wordpress.org` returns 7.0.2**: the official API wins.
- **Contentful's entry price after the Free plan**: the sources quote $300/month and "a minimum of
  $3,600/year" as the same jump; **unresolved**. contentful.com/pricing wins.
- **Directus**: a good part of the documentation and of third-party articles still describe it as
  "open source" or under BSL. **The repository's `license` file says MSCL-1.0-GPL, copyright 2026
  Monospace Inc.** The file wins.
- **Decap**: there are listicles that give it up for abandoned; the registry shows releases in 2026.
  Those lists are usually a competitor's marketing — cross-check against the repository.

If the web contradicts this document, **the web wins** — flag the discrepancy.
