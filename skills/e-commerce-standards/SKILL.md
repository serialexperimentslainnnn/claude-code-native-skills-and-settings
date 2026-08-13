---
name: e-commerce-standards
description: Use when building or operating an online store as a system — choosing between Shopify, WooCommerce, Magento Open Source / Adobe Commerce, PrestaShop, Saleor, Medusa, commercetools and VTEX, SaaS versus self-hosted total cost including per-transaction fees, monolith versus composable MACH, product catalog with variants SKUs and attributes, stock reservation and the oversell race condition, cart and guest session, price lists and EU VAT with OSS and IOSS, shipping rates and returns, checkout funnel and guest checkout, order and fulfillment state machines, product SEO with canonical URLs and schema.org Product structured data, URL migration and 301 redirect maps at replatform, faceted navigation and crawl traps, promotions coupon stacking and discount abuse, scalping bots and inventory hoarding, card-not-present fraud screening, Black Friday traffic peaks and capacity, European Accessibility Act duties for e-commerce services, Consumer Rights Directive withdrawal and the order-with-obligation-to-pay button, Omnibus prior-price rules, GPSR, and consent-aware commerce analytics.
---

# E-commerce standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, choosing a platform for, or reviewing an **online store as a system**:
catalogue, inventory, cart, price, taxes, shipping, checkout, order, return, promotions, product
search, catalogue SEO, traffic peaks and abuse. It also covers the prior decision — **whether
building your own store is worth it at all** — and the replatform decision.

Triggers: SKU, variant, product attribute, catalogue, *stock*, inventory reservation, overselling,
cart, checkout, guest versus registration, order, `order state machine`, *fulfillment*, shipping,
return, RMA, VAT, OSS, IOSS, coupon, promotion, `schema.org/Product`, JSON-LD, `canonical`, 301
redirect, redirect map, facets, `noindex`, `sitemap.xml`, `robots.txt`, Black Friday, *scalping*,
*bot*, CNP, `Shopify`, `WooCommerce`, `Magento`, `Adobe Commerce`, `PrestaShop`, `Saleor`,
`Medusa`, `commercetools`, `VTEX`, *headless*, *composable*, MACH.

**Thesis of this skill**: **a store is an inventory and accounting system with a website in front
of it**. The website is rebuilt every three years; the catalogue, the stock, the order history and
the URL map outlive every fashion — and they are what breaks at every replatform. Design for that,
not for the visual theme.

Second thesis: **almost every "store problem" is a concurrency problem or a URL identity problem
in disguise.** Overselling is a race condition; coupons stacked up to 100% are a race condition
with business logic; the traffic drop after a migration is an incomplete redirect map. None of the
three is fixed with more *cache*.

**Not applicable**: see `fintech-payments-standards` (**sister skill of this batch and a hard
dependency**: PCI DSS scope and SAQ selection, tokenisation, SCA/PSD2 and its exemptions, 3-D
Secure, the authorisation and capture state machine, charge idempotency, reconciliation and
settlement, *chargebacks*, accounting in minor units and the immutable ledger. **Exact boundary:
the amount to charge is decided here; from `POST /payments` onwards it is theirs.** Rule that
avoids duplication: *how much and why → this skill; what happens to that amount → payments*),
`gaming-infrastructure-standards` and `game-development-standards` (**a game's store is a store and
belongs here**: catalogue, price, virtual currency as a SKU, tax and cart, with the charge
delegated just like any other to `fintech-payments-standards`. What does not belong here: receipt
validation **on the game server** and signature verification of its *webhook*, which are theirs
because the client lies), `web-performance-standards` (**measurement and the performance budget are
theirs**: Core Web Vitals, field data, 75th percentile, budgets in CI. Here only **where it hurts
in a store** — product page and checkout — and what gets prioritised when you must choose. Do not
duplicate metrics or thresholds: delegate them), `caching-cdn-standards` (cache policy, key,
purging and CDN; here only **what is cacheable in a store and what never is**: catalogue yes, cart
and personalised price no), `search-engines-standards` (**the search engine, indexing, relevance,
synonyms and technical facets are theirs**; here what is expected of product search and why a
badly exposed facet creates a crawl trap), `accessibility-standards` (**the technical WCAG/EN 301
549 criterion, auditing and tooling are theirs**; here only **that e-commerce is a covered
service** under Directive (EU) 2019/882 and what that implies for the project — §3.10),
`appsec-standards` (threat modelling and OWASP; here only domain-specific abuse: coupons,
*scalping*, catalogue enumeration), `privacy-engineering-standards` (legal basis, consent,
retention and rights; here only the concrete friction point with commerce analytics — §3.11),
`analytics-bi-standards` (**the dashboard and its governance are theirs**; here which commerce
event must be emitted and why the funnel is measured on the server), `cms-jamstack-standards`
(**editorial content modelling and editing, *headless* CMS, preview and revalidation after
publishing**; here the catalogue as transactional data, which is not content),
`frontend-web-platform-standards` and `frontend-frameworks-standards` (building the storefront),
`i18n-standards` (language, price and date formatting, `hreflang`, multi-market catalogue),
`data-warehouse-modeling-standards` (the `order` fact for analytics), `message-brokers-standards`
(order and inventory events and their *at-least-once* delivery),
`microservices-architecture-standards` (**the criterion for when to split** — key to judging the
*composable* pitch in §3.2), `sre-practice-standards` and `observability-standards` (SLOs,
telemetry, capacity and campaign peak readiness), `opensource-licensing-standards` (**the
platform's licence decides what you can do with your own store**: Magento's and PrestaShop's
OSL-3.0 is not MIT and carries copyleft and network conditions — §3.1),
`grc-compliance-standards` (consumer, marketplace and sanctions obligations as a programme),
`ai-governance-standards` (recommender and dynamic pricing: transparency and classification).

## 2. Default decisions

> Verify prices, licences, versions and regulatory status on the web before fixing them in a real
> project (§8). Data as of **August 2026**.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Own store at all? | **No, if you sell few SKUs or the channel is a marketplace** | §3.1 |
| Initial platform | **SaaS** (Shopify or equivalent) unless a requirement rules it out | The cost of operating a self-hosted store is paid in incidents, not licences |
| Architecture | **The platform's monolith**; *composable* only with a demonstrated case | §3.2 |
| Payment | **Delegated to the PSP with hosted fields** | Set by `fintech-payments-standards`: PCI scope rules |
| Price and amount | **Integer in minor units + ISO 4217** | Idem |
| Inventory | **Reservation with an atomic decrement and the condition in the write**; never read-check-write | §3.4 |
| Cart | **Server-side**, with a stable identity for guests | A cart that lives only in the browser is lost and is not measured |
| Checkout | **Guest by default**, optional registration at the end | §3.7 |
| Taxes | **A destination-based tax engine**, not a fixed rate in configuration | §3.6 |
| Product URL | **Stable and independent of the name**, with an explicit `canonical` | §3.9 |
| Facets | **`noindex` by default**, opened to indexing case by case | Guaranteed crawl trap otherwise (§3.9) |
| Search | **Dedicated engine** once the catalogue is beyond trivial | Delegated to `search-engines-standards` |
| Promotions | **Non-stackable by default**, with a cap and server-side validation | §3.8 |
| Analytics | **Server events as the source of truth**, client as a complement | Blockers and consent make the client incomplete by design (§3.11) |
| Replatform | **Redirect map before writing a single line of the new store** | §3.9 |

### 2.1 Platforms: licence and cost model

Licences **verified from the raw `LICENSE` file** (August 2026); prices **from the vendor's page**:

| Platform | Model | Verified licence / price |
|---|---|---|
| **Shopify** | SaaS | EUR prices from `shopify.com/pricing` (the page declares itself *"accurate as of August 4, 2026"*): Basic **€32/month** monthly or **€22/month** annual, Grow **€92 / €62**, Advanced **€384 / €289**, Plus **from €2,100/month**. **Third-party gateway fee: 2% / 1% / 0.6% / 0.2%** depending on plan; online card rates with Shopify Payments from **2.1% + €0.30** (Basic) down to **1.3% + €0.30** (Plus). **That percentage for using another PSP is the line item that decides the comparison** and the one almost nobody puts in the spreadsheet |
| **WooCommerce** | Self-hosted (WordPress plugin) | **GPL v3 or later**, verbatim from `license.txt`. Free; the cost is *hosting*, maintenance, and the paid extension ecosystem |
| **Magento Open Source** / **Adobe Commerce** | Self-hosted / commercial licence | **OSL 3.0** (`LICENSE.txt` of `magento/magento2`) — **it is not permissive**: it has copyleft and an external-use clause. Lifecycle (Adobe, updated 2026-06-02): **2.4.9 released 2026-05-12**; regular support for 2.4.8 until **2028-04-11**, for 2.4.7 until **2027-04-09**, for 2.4.6 until **2026-08-11**. Adobe Commerce is quoted; no public price |
| **PrestaShop** | Self-hosted | **Core OSL-3.0, modules AFL-3.0**, verbatim from `LICENSE.md`: *"PrestaShop Core is licensed under OSL-3.0 and PrestaShop Modules are licensed under AFL-3.0"* |
| **Saleor** | Self-hosted / cloud | **BSD 3-Clause** (`LICENSE` of `saleor/saleor`). Verify separately the licence of the dashboard and of the commercial components |
| **Medusa** | Self-hosted / cloud | **MIT** (`LICENSE` of `medusajs/medusa`) |
| **commercetools** | *Composable* SaaS | No public price: the page declares an **order-based** model, not GMV-based. **Gap: no published figure** |
| **VTEX** | SaaS | No public price: the form segments by **annual GMV band**, which suggests a revenue-linked model. **Gap: no published figure** |

**Honest comparison rule**: total cost is *subscription + per-transaction fee + extensions +
hosting + people*. A "free" platform with 0.5 points more in fees is more expensive than a paid one
from a surprisingly low volume onwards — **do the maths with your average order value and your
volume before choosing**, not with the feature table.

## 3. Technical criteria

### 3.1 When NOT to build your own store

Cases where the store is the wrong answer, said without diplomacy:

- **Fewer than ten SKUs and no recurrence**: a PSP payment link solves 100% of the problem with 2%
  of the code.
- **The real channel is a marketplace**: if your sales come from a third party, your own store is a
  fixed cost with vanity traffic. The decision is a business one and must be taken explicitly.
- **Digital product or pure subscription**: the problem is billing and access entitlements, not
  catalogue or logistics.
- **Nobody to operate it**: a store is a 24×7 production system handling money. Without someone
  responsible for patches, incidents and discrepancies, self-hosting is a breach with a date on it.
- **B2B with negotiated pricing and rep-placed orders**: that is an ERP with a portal, not a store.

And the licence trap discovered too late: **OSL-3.0 (Magento, PrestaShop core) is not MIT**. Before
assuming you can distribute a fork, package a multi-store SaaS or publish derived modules, run the
decision through `opensource-licensing-standards`.

### 3.2 Monolith versus *composable* / MACH

The *composable* pitch is real but badly sold. Honest criterion:

**The platform monolith wins** when the catalogue fits the standard model, the team is small, and
the competitive advantage is not in the storefront. A well-built theme on a mature platform solves
90% of stores.

***Composable* is justified** when: there are several channels or markets with different rules and
the same catalogue; the product model does not fit the standard (configurators, contract pricing,
units of measure); there are separate teams that need to deploy without blocking each other; or the
current platform is the **measured** bottleneck, not the suspected one.

**Cost omitted from the pitch deck**: every piece has its own contract, version, billing, latency
and failure mode — and **consistency across catalogue, price and stock stops being a database
transaction and becomes a distributed problem**. That leap is exactly the one in
`microservices-architecture-standards`: if you are not willing to pay for *outbox*, idempotency and
eventual consistency, you are not ready for *composable*. **Splitting a store does not make it
faster; it makes it harder to leave inconsistent without noticing.**

### 3.3 Catalogue, variants and attributes

- **Distinguish product from variant in the model**: the product is what is described and ranked;
  the **variant (SKU) is what has price, stock and weight**. Modelling them as a single entity is
  the structural mistake that forces a catalogue rebuild.
- **The SKU is a business identifier, opaque and stable**. Do not encode attributes inside it
  (`SHIRT-RED-XL` becomes a lie the day the colour changes).
- **Typed attributes** (number with unit, boolean, enumeration), not free strings: facets, filters
  and the product *feed* come out of them. A free-text attribute is neither filterable nor
  comparable.
- **Media is catalogue too**: a stable identifier per image, with size variants generated, not
  uploaded by hand.
- **Attribute schema versioning**: adding a mandatory attribute to a live catalogue is a migration,
  with its default value and its backfill plan.

### 3.4 Inventory: the race condition that defines the domain

**"Check then subtract" is a guaranteed bug under concurrency.** This pattern, in any language,
oversells:

```
stock = SELECT quantity FROM inventory WHERE sku = ?
if stock >= n:  ->  UPDATE inventory SET quantity = quantity - n WHERE sku = ?
```

Another request fits between the `SELECT` and the `UPDATE`. It is not unlikely: in a launch, it is
the norm. Correct alternatives, in order of preference:

1. **Atomic conditional decrement**: the check travels **inside** the write, and the database
   guarantees only one wins. `UPDATE ... SET quantity = quantity - :n WHERE sku = :sku AND
   quantity >= :n`, and **if it affects zero rows, there is no stock**. One statement, no prior
   read, no explicit lock.
2. **Reservation with expiry**: for long checkouts, stock is **reserved** on entering checkout and
   converted into consumption on confirmation, or it expires. It requires a process that releases
   expired reservations — and that process is part of the design, not an extra.
3. **A database constraint as a safety net**: `CHECK (quantity >= 0)`. It does not replace the
   above; it turns a silent oversell into a visible error.

Associated decisions:

- **Reservation is a business decision, not a technical one**: reserving on add-to-cart protects
  the buyer and enables bot hoarding (§3.8); reserving on payment maximises sales and produces
  cancellations. Choose explicitly, with an expiry.
- **Controlled overselling** (accepting an order without stock, restocking later) is a legitimate
  strategy if it is **explicit and communicated**, with its timeframe. Accidental overselling is a
  customer-support and reputation incident.
- **A single source of truth for stock**. If the ERP and the store each have their own number, the
  question is not which is right but which one wins and with what latency. Write it down.
- **Multi-warehouse** changes the problem: available stock depends on the destination and the
  shipping method. Do not model it as a global integer if you are going to need it.

### 3.5 Cart, order and their states

- **The cart lives on the server** with its own identifier, tied to the user when there is one and
  to a first-party cookie when there is not. Merging a guest cart with a user cart on login is a
  case that must be decided and tested (does it add up? does the most recent win?), not left to
  chance.
- **The price is recalculated on the server at confirmation time.** Any amount arriving from the
  client is a hostile suggestion. It is the oldest store vulnerability there is and it still
  shows up.
- **The order is immutable once confirmed**; changes are subsequent events (amendment, partial
  cancellation, return), not edits. This is what lets you explain to a customer — or to an
  inspector — why they were charged what they were charged.
- **Explicit state machine**, with allowed transitions declared: `created → paid → picked →
  shipped → delivered`, plus `cancelled` and `returned` with their rules. A free-text `status`
  column with no valid transitions ends up with orders in impossible states.
- **The order state is not the payment state** (`fintech-payments-standards`, §3.4). An order paid
  and not shipped and an order shipped and not charged are both possible and both need
  representation.

### 3.6 Price, taxes and VAT in the EU

- **Price with and without tax, separated in the model**, with the presentation criterion decided
  per market (B2C tax-inclusive, B2B usually exclusive).
- **The destination rules.** In the EU, for distance sales to consumers, the place of taxation is
  the customer's. The threshold is in Art. 59c of the VAT Directive (introduced by Directive (EU)
  2017/2455), verbatim: the exception only applies if *"the total value, exclusive of VAT, of the
  supplies referred to in point (b) does not in the current calendar year exceed EUR 10 000"* —
  and also the previous year. **Above €10,000 total intra-EU, the destination country's rate
  applies.**
- **OSS** (one-stop shop) allows declaring all of that in a single Member State instead of
  registering in each one. **IOSS** covers imports: it applies to consignments *"in consignments of
  an intrinsic value not exceeding EUR 150"* (Art. 369l, verbatim). Above that, a full customs
  declaration.
- **Engineering consequence**: the VAT rate is a function of *(product category, destination
  country, date)*. A fixed rate in configuration is correct exactly until the first cross-border
  sale. And **rates change**: store the applied rate on the order, do not recompute it from the
  current configuration when reprinting an invoice from two years ago.
- **Price reductions**: Directive (EU) 2019/2161 introduced Art. 6a into Directive 98/6/EC,
  verbatim: *"Any announcement of a price reduction shall indicate the prior price applied by the
  trader"*, and *"The prior price means the lowest price applied by the trader during a period of
  time not shorter than 30 days prior to the application of the price reduction."* Translated into
  product terms: **you need the 30-day price history as queryable data**, not as an audit log
  buried somewhere. If your platform does not store it, you have to add it.
- **Verify in §8** rates, thresholds and national transposition: this skill fixes the mechanics,
  not the rates.

### 3.7 Checkout: where the money is lost

- **Guest by default.** Forcing registration before payment is the most expensive self-inflicted
  friction in the funnel. Offer account creation *after* confirmation, with the password as the
  only extra field.
- **Fewer fields and fewer steps**, with inline validation and messages that say how to fix things.
  Browser autofill working (correct `autocomplete` on every field) is worth more than any redesign.
- **Total cost visible early.** Shipping charges that show up in the last step are the abandonment
  cause that appears in every study; it is also what Art. 8(3) of Directive 2011/83/EU requires
  (indicating delivery restrictions and accepted means of payment **at the latest at the beginning
  of the ordering process**).
- **Confirmation button with an obligation to pay.** Art. 8(2), verbatim: *"the button or similar
  function shall be labelled in an easily legible manner only with the words 'order with obligation
  to pay' or a corresponding unambiguous formulation"*, and **if it is not complied with, "the
  consumer shall not be bound by the contract or order"**. A button saying "Continue" in the final
  step is not a copywriting detail: **it can invalidate the contract**.
- **No pre-selected extras.** Art. 22, verbatim: if the trader infers consent *"by using default
  options which the consumer is required to reject"*, the consumer is entitled to a refund of that
  amount. Insurance, premium shipping and donations ticked by default are illegal, not aggressive.
- **Performance**: the product page and the checkout are the two paths where performance turns into
  money — but **how it is measured and which threshold is required is set by
  `web-performance-standards`**. Here only the priority: if you have to choose where to spend the
  performance budget, spend it there, not on the home page.
- **Figures you must NOT cite** (§4 of intellectual hygiene, and see §8):
  - **"Every 100 ms of latency costs 1% in sales"**. It comes from a blog post by Greg Linden
    (2006) and from a later slide of his about an **internal Amazon experiment that was never
    published**: there is no experimental design, no sample size, no definition of "sales". It has
    been repeated ever since by circular citation, with the figure applied to revenue bases that
    differ by four orders of magnitude. **It is folklore, not evidence.** Measure your funnel.
  - **"70% of carts are abandoned"**. Baymard publishes **70.22%** as the **arithmetic mean of 50
    third-party studies** (2006-2025), with individual values between ~55% and ~84%, from different
    vendors and **with no common definition of "abandoned cart"**. The methodology is published and
    is honest *about what it claims to be*: an average of averages. Using it as a target for your
    store is a category error.
  - **"The industry average conversion rate is X%"**: it depends on the product type, the order
    value, the traffic channel and whether you count sessions or users. **Without those four
    variables the figure means nothing.** Compare yourself with yourself.

### 3.8 Promotions, abuse and bots

**Coupons are the most profitable business vulnerability there is**, because it requires exploiting
nothing: it is enough for the rules to compose in a way nobody modelled.

Defences, all server-side:

- **Non-stackable by default.** Stacking is an exception enabled per rule, with a **defined and
  deterministic** application order (is the percentage applied before or after the fixed amount?
  The answer changes the result).
- **Hard cap per order**: absolute maximum discount and maximum percentage, applied **after**
  combining everything. It is the net that catches what the logic did not foresee.
- **A discount can never make an amount negative** — not the line, not the shipping, not the total.
  Also check the case of a partial return of an order with a coupon: how much of a distributed
  discount is refunded is a decision, not an obvious calculation.
- **Usage limits per coupon and per customer**, applied with the same atomic discipline as stock
  (§3.4): a counter read and then incremented is bypassed with concurrent requests.
- **Unguessable codes** for personal coupons; sequential codes or ones based on the campaign name
  are enumerated in minutes.
- **A record of every discount application** with its rule and its amount, so you can later explain
  what happened and what it cost.

**Bots and resale (*scalping*)**: in limited launches the attacker breaks nothing — they use your
store faster than a person. Defensive stance:

- **Reservation on add-to-cart is the hoarder's ammunition.** If you reserve, use a short expiry
  and a limit per identity.
- **A limit per identity unit** (account, payment method, shipping address), knowing that each one
  can be multiplied and that a per-IP limit annoys legitimate users behind NAT.
- **A waiting queue** for launches: it turns a race into an order, and protects capacity along the
  way.
- **Behavioural detection**, not *user-agent* based: time to cart, absence of prior browsing, retry
  patterns. Feed telemetry, do not block blindly.
- **Honest metric**: the false-positive rate. An anti-bot that blocks real customers costs more
  than the resale it prevents.

**Card-not-present fraud**: screening, risk scoring and liability shift belong to
`fintech-payments-standards`. What this skill contributes: **commerce signals are the model's best
inputs** (mismatch between billing and shipping, an order far above the average value, a
just-created account, urgency for express shipping, high-resale items). Export them to the fraud
engine instead of reimplementing it.

### 3.9 Catalogue SEO and the URL migration

**URL migration is the most common way to destroy an online business**, and it is entirely
avoidable. In a replatform:

1. **Export the full inventory of live URLs BEFORE touching anything**: a crawl of the current site
   + `sitemap.xml` + server logs from the last few months + pages with inbound links or organic
   traffic. The logs are the source nobody looks at and the one containing the URLs that still get
   visits.
2. **A 1:1 map from source to destination**, hand-reviewed for the highest-traffic ones. A redirect
   to the home page **is not a redirect**: it is a loss.
3. **`301` (permanent), not `302`**, and **no chains**: source → final destination, in one hop.
4. **Automated post-deploy verification**: walk the whole map and check status code and
   destination. It is a test, and it runs in CI.
5. **Parameters migrate too**: filters, pagination and campaign identifiers.
6. **Keep the redirects forever.** Removing them "because nobody uses them any more" is doing the
   migration again a year later.

The rest of the catalogue criteria:

- **Explicit `canonical` on every product page**, pointing at the reference URL. The same product
  reachable from several categories is a duplicate if you do not declare it.
- **Facets: `noindex` by default.** Every filter combination is a URL; N filters produce
  combinatorial growth and a crawl trap that eats crawl budget and produces near-identical content.
  **Specific cases** with demonstrated search demand are opened to indexing.
- **Out-of-stock or discontinued product**: the worst option is `404`. Keep the page with a clear
  status and alternatives, or redirect to the successor product or its category. Deleting
  accumulates errors and throws away the ranking you earned.
- **Structured data** `schema.org/Product` with offer, price, currency and availability, in JSON-LD.
  **They must match what the user sees**: marking a price different from the real one is grounds
  for a penalty, not an optimisation. **Verify the search engine's current requirements in §8**:
  they change and give no notice.
- **Pagination and infinite scroll**: if the listing is infinite, guarantee an equivalent crawlable
  path exists. Content that only appears after interaction does not exist for a crawler.

### 3.10 Accessibility and consumer obligations

**E-commerce is a service expressly covered** by Directive (EU) 2019/882 (European Accessibility
Act): Art. 2(2)(f) lists *"e-commerce services"* among the services provided to consumers **after
28 June 2025**, and Art. 31(2) sets that application date. Two verified nuances that avoid false
statements in either direction:

- **Microenterprise exemption** (Art. 4(5), verbatim): *"Microenterprises providing services shall
  be exempt from complying with the accessibility requirements referred to in paragraph 3 […]"*.
  Microenterprise is defined in Art. 3(23): **fewer than 10 persons and an annual turnover or
  balance sheet total not exceeding EUR 2 million**. The exemption covers services, not products.
- **Transitional regime** (Art. 32): Member States provide for a period **until 28 June 2030**
  during which services may continue to be provided using products lawfully used before; and
  service contracts agreed before 28-6-2025 may continue unaltered until they expire, for a maximum
  of five years.

**The technical conformance criterion — WCAG, EN 301 549, auditing, tooling — belongs to
`accessibility-standards`.** What this skill contributes: **it is mandatory and it affects the
checkout, which is exactly where it is usually worst** (error messages not announced, focus lost
after validation, reservation timers with no warning, variant selectors unreachable by keyboard).

Other consumer obligations that constrain the design (Directive 2011/83/EU, verbatim in §3.7): a
**14-day right of withdrawal** in distance contracts (Art. 9(1)), with its exhaustive exceptions in
Art. 16 — customised goods, sealed goods opened for hygiene reasons, perishable goods, digital
content already performed with express consent. And Regulation (EU) 2023/988 (**GPSR**), applicable
since **13 December 2024**, which imposes product information and traceability obligations on
online sellers and marketplaces. **The concrete implementation and the transpositions are verified
in §8**; here only their existence and their effect on the data model: **you need manufacturer and
EU responsible person data as product attributes**, not as loose text in the description.

### 3.11 Analytics, consent and personal data

- **The funnel is measured on the server.** Client events are systematically incomplete because of
  blockers, consent refusal and network failures — and the bias **is not random**, so rates computed
  only from client data are skewed in a way you cannot correct. Server events (order created,
  payment confirmed, shipment) are complete by construction.
- **No consent, no non-essential analytics.** The correct design is: the store works fully without
  consent, and analytics is additive. If your funnel breaks when the user says no, the problem is
  architectural. **The legal basis, consent design and retention belong to
  `privacy-engineering-standards`.**
- **Minimise what you keep from the order.** Shipping address and contact details are necessary;
  reconstructing an indefinite behavioural profile is not. And beware: **mandatory accounting and
  tax retention sits badly with the right to erasure** — that collision is resolved by separating
  the mandatory transactional data from the behavioural data, and it is documented.
- **The recommender and dynamic pricing are automated decisions with impact**: run them past
  `ai-governance-standards` before personalising prices, which is where the real regulatory and
  reputational risk lives.

## 4. Quality and testing

- **Concurrency test on stock**: N simultaneous purchases of the last unit ⇒ **one** sale and N−1
  rejections. In real parallel, against the real database. It is the test that defines whether the
  system is correct.
- **Concurrency test on a single-use coupon**: same pattern.
- **Promotion composition test**: a combination of rules that tries to push the total below zero or
  above the cap; it must fail in a controlled way.
- **Price tampering test**: a request with an amount altered from the client ⇒ rejection.
- **Tax matrix test** (category × country × date), with at least one rate-change case and one
  old-invoice reprint case.
- **Redirect map test** after every deploy touching URLs: every source returns `301` to the
  expected destination, in one hop.
- **Structured data test** against the search engine's validator and against the real rendered
  price.
- **Automated accessibility test on the product page and checkout** as a *gate*, with a manual audit
  of the checkout — the automated one does not see what breaks a checkout (delegated to
  `accessibility-standards`).
- **Load test of the full purchase flow** before each campaign, not of the catalogue alone.
- **CI gates**, increasing cost: *linters* and types → unit tests for price, tax and discount →
  concurrency tests for stock and coupon → redirect map validation → automated accessibility →
  performance budget (`web-performance-standards`) → integration with the PSP *sandbox*.

## 5. Stack security

- **Every amount and every rule is validated on the server.** Price, discount, shipping, tax,
  quantity. No exception.
- **Object-level authorisation on every customer resource**: order, invoice, address, return.
  `GET /orders/{id}` without an ownership check exposes complete purchase histories, and it is the
  most repeated finding in stores.
- ***Frontend* supply chain**: every third-party *script* on the payment page is a card *skimming*
  risk (**and a PCI DSS requirement**, see `fintech-payments-standards` §3.2). Inventory, CSP and
  integrity control; **marketing does not add pixels to the checkout without review**.
- **Extension ecosystem**: on self-hosted platforms, the third-party plugin is the dominant vector.
  Policy: minimum number, known origin, kept updated, and none abandoned. Treat them as dependencies
  with SCA (`appsec-standards`).
- **Enumeration**: non-sequential order identifiers; rate limiting on search, login, password
  recovery and coupon validation.
- **Account takeover**: order history, addresses and the stored payment method are the loot. MFA
  available, an email alert on address or password change, and reauthentication before sensitive
  operations.
- **Returns and refunds as a business control**: who can issue one, up to what amount and with what
  second signature. Internal fraud lives here.
- **Card data**: never in your system. Delegated and non-negotiable (`fintech-payments-standards`
  §3.1).

## 6. Performance and operability

- **What is cacheable**: catalogue, product page, listings and static assets, yes — under the rules
  of `caching-cdn-standards`. **Cart, personalised price, exact availability and any session page,
  no.** Caching a personalised response at the edge is a data leak, not an optimisation.
- **Published availability versus exact stock**: the product page may serve a cached value at
  coarse granularity ("in stock" / "few left"), and **the truth is checked at reservation time**.
  Trying to serve the exact real-time number from the catalogue is what takes the database down in
  a campaign.
- **Store SLIs**: conversion rate per funnel step, checkout error rate, latency of shipping and tax
  calculation (external dependencies), shipping-provider failure rate, age of the oldest unprocessed
  order, oversell rate.
- **Campaign peaks**: the pattern is **catalogue × 20, checkout × 5, and everything concentrated in
  minutes**. Preparation: load test with the real profile, an activatable waiting queue, rate limits
  agreed with the PSP and the carrier, a degradation plan (disable recommendations and
  personalisation before payment), and a **deployment freeze** during the window.
- **External dependencies with a timeout and a fallback**: if real-time shipping calculation does
  not respond, serve a fallback rate; **do not block the checkout waiting for a third party**.
- **Asynchronous work**: emails, marketplace *feeds*, ERP synchronisation and search indexing go
  into a queue, never in the purchase request.
- **An order is never lost because of a failure after payment.** Persisting it is the operation that
  cannot fail; everything else is retriable.

## 7. Sustainability and prohibitions

- **Cadence**: platform and extension patches within their support window (see lifecycle dates in
  §2.1 and verify them in §8); an annual review of the extension catalogue to remove what is
  unused; a review of the redirect map on every URL structure change.
- **Planned exit**: before marrying a platform, check **how catalogue, customers, orders and
  payment tokens are exported**. A store with no exit route is a hostage.
- **ADR** for: platform choice, monolith/composable architecture, stock reservation policy,
  promotion stacking policy, and URL strategy.

Prohibitions:

- ❌ **FORBIDDEN: the read-check-subtract pattern on stock, balance or coupon counter.** The
  condition goes inside the atomic write.
- ❌ **FORBIDDEN: trusting any amount, quantity, discount or tax sent by the client.**
- ❌ **FORBIDDEN: touching the PAN.** See `fintech-payments-standards` §3.1.
- ❌ **FORBIDDEN: replatforming without a verified redirect map**, and **forbidden to redirect
  everything to the home page**.
- ❌ **FORBIDDEN: deleting the URL of a discontinued product** leaving a `404`.
- ❌ **FORBIDDEN: exposing indexable facets without control**: it is a crawl trap.
- ❌ **FORBIDDEN: an order confirmation button that does not express the obligation to pay**, and
  **forbidden pre-selected extras** (Art. 8(2) and Art. 22 of Directive 2011/83/EU).
- ❌ **FORBIDDEN: announcing a price reduction without the lowest prior price of the previous 30
  days.**
- ❌ **FORBIDDEN: caching at the edge any response that depends on the session.**
- ❌ **FORBIDDEN: forcing registration in order to buy** without a written business justification.
- ❌ **FORBIDDEN: adding third-party *scripts* to the payment page without review** — it is a PCI
  DSS requirement, not a preference.
- ❌ **FORBIDDEN: justifying a decision with "100 ms costs 1%" or "70% abandon the cart"** without
  measuring your own funnel (§3.7).
- ❌ **FORBIDDEN: letting the funnel stop being measured when the user refuses consent**: that means
  you depend on the client for data that should have been server-side.
- ❌ **FORBIDDEN: installing an abandoned extension** on a self-hosted platform.

## 8. Mandatory web verification

Check **before** fixing anything:

1. **Platform prices and fees**: each vendor's official page, with the date. Those in §2.1 are from
   `shopify.com/pricing` in **EUR** (the page itself is dated **2026-08-04**) and vary by country
   and currency. **Declared gaps: commercetools and VTEX publish no figures** — their pages point to
   sales; any number you find on a blog is an unverified leak.
2. **Licences**: the `LICENSE`/`LICENSE.md` file **raw from the repository**, never the GitHub label
   nor an article. Verified that way: Magento OSL-3.0, PrestaShop OSL-3.0 + AFL-3.0 for modules,
   Saleor BSD-3-Clause, Medusa MIT, WooCommerce GPL-3.0-or-later. **Check it again**: this catalogue
   has already disproved sixteen licence assumptions.
3. **Adobe Commerce / Magento lifecycle**: Adobe's released versions page (last verified update:
   2026-06-02). End-of-support dates move.
4. **EU VAT**: the Art. 59c threshold (€10,000), the IOSS limit (€150), rates by country and
   category and the status of the **ViDA** package — which modifies the regime and whose timetable
   is **not asserted here**. Primary source: EUR-Lex and the Commission's taxation portal.
5. **Consumer rights**: Directive 2011/83/EU (Arts. 8, 9, 16, 22), Directive (EU) 2019/2161 (Art. 6a
   of Directive 98/6/EC) and **their national transposition**, which is what applies to you.
6. **Accessibility**: Directive (EU) 2019/882 (Arts. 2, 3(23), 4(5), 31, 32) and **the national
   transposing law**, plus the harmonised standard in force. In Spain the reference is Ley 11/2023 —
   **verify it, this skill has not checked it raw** (declared gap).
7. **GPSR**: Regulation (EU) 2023/988, applicable since 2024-12-13, and its application guidance.
8. **Structured data**: the search engine's current requirements for product listings (mandatory
   properties, price and availability policies). They change without notice and a listing that
   complied yesterday may not today.
9. **Industry figures**: **distrust by default.** Before citing an abandonment, conversion or
   latency-impact rate, demand a published methodology. The two most repeated ones are dismantled in
   §3.7: the 100 ms one **has no primary source** (a 2006 blog post and slide about an unpublished
   internal experiment) and the 70% one is an **average of 50 vendor studies** with a range of ~55%
   to ~84% and no common definition.
10. **PCI DSS** applied to the payment page (requirements 6.4.3 and 11.6.1, SAQ A eligibility):
    **verify it in `fintech-payments-standards` §8**, which is where that check lives.

If the web contradicts this document, **the web wins** — flag the discrepancy.
