---
name: fintech-payments-standards
description: Use when software takes money — PCI DSS v4.0.1 scope and SAQ A / SAQ A-EP / SAQ D selection, hosted fields, iframes and the PAN never touching your servers, cardholder data environment and segmentation, sensitive authentication data and the ban on storing CVV/CVC/CAV2/CID after authorization, PSP tokenization and EMVCo network tokens, PSD2 strong customer authentication and the Regulation (EU) 2018/389 exemptions (TRA, low value, trusted beneficiary, MIT and recurring), EMV 3-D Secure 2.x, liability shift, authorize/capture/partial capture/void/refund state machines, Idempotency-Key and double-charge prevention, settlement and reconciliation against acquirer payout files, chargebacks and representment, SEPA credit transfer, SEPA Direct Debit mandates and Regulation (EU) 2024/886 instant payments, open banking pay-by-bank, MiCA duties for crypto payments, AML/KYC and fraud screening hooks, ISO 4217 minor units, integer minor-unit amounts instead of floats, and immutable double-entry ledgers.
---

# Payments and fintech standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when software **moves somebody else's money**: card payments, transfers,
direct debits, wallets, subscriptions and refunds. It covers the decision that dominates the whole
project —**PCI DSS scope**—, the life cycle of a transaction, strong authentication,
reconciliation against the money that actually arrives, disputes and the accounting
of the amount.

Triggers: PCI DSS, CDE, PAN, SAD, CVV/CVC2/CAV2/CID, SAQ A, SAQ A-EP, SAQ D, ROC, AOC, QSA,
ASV, tokenisation, *network token*, PSP, acquirer, issuer, card scheme, PSD2, SCA,
RTS (EU) 2018/389, TRA, MIT, CIT, 3-D Secure, EMV 3DS, *liability shift*, `authorize`,
`capture`, `void`, `refund`, `Idempotency-Key`, *settlement*, *payout*, `chargeback`,
*representment*, *pre-arbitration*, SEPA, SCT, SCT Inst, SDD Core, SDD B2B, mandate, `IBAN`,
`pain.001`, `camt.053`, ISO 20022, *open banking*, PIS/AIS, MiCA, KYC, AML, ISO 4217,
*minor units*, ledger, journal entry, `Stripe`, `Adyen`, `Redsys`, `Mollie`, `Braintree`.

**Thesis of the skill**: **PCI scope is an architecture decision, not a compliance one.**
It is decided on day one, with a single question: *does the PAN ever pass through a system of
mine?* If the answer is yes —even if it is a `POST` that only forwards, even if it is your own
JavaScript reading the `<input>`— the project changes category: from a dozen controls to a hundred
and fifty or more, with external audit, quarterly scans and network segmentation. **Touching
the PAN once costs more than all the rest of the product.**

Second thesis, just as expensive to learn late: **authorisation is not a charge, and what you
charge is not what you receive.** Between "approved" at the gateway and the euro in your bank there
are capture, settlement, fees, holdbacks, currency conversion and disputes. A system that assumes
`status == "approved"` ⇒ *money* has a guaranteed mismatch (§3.6).

**Not applicable**: see `e-commerce-standards` (**sister skill of this batch**: catalogue, cart,
inventory, checkout as a funnel, sales taxes and OSS/IOSS, shipping and returns,
promotions. Exact boundary: **the cart and the price are hers; from `POST /payments` to
the journal entry, mine**. The rule that avoids duplication: *who decides how much is charged →
`e-commerce`; what happens to that amount once it is sent to the PSP → this skill*),
`appsec-standards` (threat modelling, OWASP/ASVS, triage of application vulnerabilities;
here only the classes specific to the payment domain), `api-design-standards`
(**the HTTP contract and the semantics of `Idempotency-Key`, `409`, `Retry-After` and webhook
signing are hers**; here **why idempotency is not optional in payments** and what is used as the
key), `cryptography-pki-standards` (TLS, HSM/KMS, key management, encryption at rest; here only
which data must be protected and why), `identity-access-management-standards` (OAuth 2.1/OIDC,
FAPI, mTLS and *client credentials* against the bank's API; **PSD2 SCA is a regulatory payment
obligation and lives here**, the authentication engine and the factors live there),
`privacy-engineering-standards` (legal basis, minimisation, retention and data subject rights
over payment data; **watch out for the real conflict**: mandatory accounting retention beats the
right to erasure, and that collision is resolved there),
`grc-compliance-standards` (**the whole compliance programme is hers**: ISO 27001, SOC 2,
DORA, AML/KYC as a corporate obligation, risk acceptance, the relationship with the auditor.
Here only the technical control and who has to implement it), `solidity-standards` (EVM
contracts; here only what accepting crypto implies from a regulatory standpoint),
`ai-governance-standards` (an anti-fraud model that denies payments may be a high-risk system
under the AI Act and requires human oversight: the classification is hers),
`detection-engineering-standards` and `soc-operations-standards` (detection and response over
fraud telemetry), `incident-management-standards` (managing the incident once the mismatch or the
breach has already happened), `data-warehouse-modeling-standards` (**analytical modelling of the
`payment` fact is hers**; the immutable transactional ledger is ours), `sql-standards` (**exact
types**: `NUMERIC`/`DECIMAL` versus `float`, constraints and transactions),
`observability-standards` and `sre-practice-standards` (metrics platform, SLOs and error
budget; here which payment SLIs to export), `message-brokers-standards` (*at-least-once* delivery
and why it forces idempotent consumers), `microservices-architecture-standards`
(*outbox*, sagas and data ownership across services), `i18n-standards` (formatting the amount
and the currency for the user; **here the amount is stored and transmitted in minor units,
never formatted**), `accessibility-standards` (the accessible payment form),
`opensource-licensing-standards` (the licence of PSP SDKs and of *ledger* software).

## 2. Default decisions

> Verify on the web the current version of each standard, the dates and the fees before
> committing to them in a real project (§8). Data as of **August 2026**.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Touch the PAN? | **Never.** Hosted fields or the PSP's `iframe`; the browser talks directly to the PSP | It is the only decision that reduces the compliance cost by an order of magnitude (§3.1) |
| Target questionnaire | **SAQ A** | Set as a product requirement **before** choosing technology, not after (§3.2) |
| Storing a card | **PSP token**, never the PAN | And for a stored card, evaluate a *network token* with the PSP (§3.3) |
| CVV/CVC after authorisation | **FORBIDDEN to store it**, in any form, encrypted included | PCI DSS requirement 3.3.1.2, quoted verbatim in §3.3 |
| Amounts | **Integer in minor units** (`amount_minor`) + **ISO 4217 code** | Floating point in money is a bug, not a decision (§3.7) |
| Idempotency | **Mandatory idempotency key** on every operation that moves money | Without it, a network *timeout* is a double charge (§3.5) |
| Authorisation and capture | **Separate** when there is physical shipping or later verification | Capturing before you can fulfil is charging for something you may not deliver (§3.4) |
| SCA | **Delegate 3DS to the PSP** and decide exemptions with data, not by default | Who requests the exemption and who bears the fraud are not always the same (§3.9) |
| Retries | **Exponential backoff with *jitter* + idempotency key + hard cap** | A retry without a key is a new transaction |
| Reconciliation | **Daily and automatic** against the PSP's/acquirer's settlement file | The mismatch is detected on day 1, not at the quarterly close (§3.6) |
| Accounting | **Double entry, immutable entries, correction by contra-entry** | An `UPDATE` on an entry destroys the audit trail (§3.7) |
| PSP webhooks | **Verify the signature + treat as a hint, not as truth**; re-read the state via the API | A webhook can be lost, duplicated and reordered (§3.8) |
| Crypto as a payment method | **No**, unless there is an explicit business decision with a verified MiCA licence | §3.11 |
| Card data in logs | **FORBIDDEN**, with a filter in the logging layer, not in the programmer's discipline | §5 |

## 3. Technical criteria

### 3.1 Scope is decided by where the PAN lives

PCI DSS applies to the **CDE** (*cardholder data environment*): every system that stores,
processes or transmits cardholder data, **plus every system connected to them or that may affect
their security**. That second half is the surprising one: a log server, a bastion, a deployment
agent or a configuration service that reaches the CDE **falls in scope**.

Practical consequence: the payment architecture is chosen for the scope that results from it.

| Integration | The PAN passes through | Typical scope |
|---|---|---|
| Full redirect to the PSP | The PSP only | The smallest; no applicable *script* criterion (§3.2) |
| PSP `iframe` / hosted fields | The PSP only; the parent DOM is yours | Small, **but the containing page is not automatically out of scope** |
| Own form + direct `POST` to the PSP from the browser (*direct post*, your own JS) | Your JavaScript touches it | Large: it is SAQ A-EP |
| Server-to-server API with the PAN | Your servers | Maximum: SAQ D / ROC, segmentation, scans, pentest |

**Hard rule**: if any element of the payment page originates on your server, you are not in the
minimum scenario. And **the page containing the `iframe` still matters**: a "Pay" button hosted by
you, a compromised analytics *script* or a manipulated header can redirect the user before they
reach the `iframe`. The `iframe` protects the field, not the journey.

### 3.2 SAQ A versus SAQ A-EP versus SAQ D

Status verified as of August 2026: the current version is **PCI DSS v4.0.1** (limited revision
published in June 2024; v4.0 retired on 31-12-2024). The **51 "*future-dated*" requirements**
that were best practice until then **became mandatory on 31 March 2025** —
there is no grace period any more and the assessor tests them like any other. **Verify both
figures and the exact number of requirements in §8**: the count circulates misquoted.

Two of those requirements are the ones that define e-commerce today:

- **6.4.3** — inventory, authorisation and integrity control of **every *script* loaded on the
  payment page**.
- **11.6.1** — a **tamper-detection** mechanism that alerts on unauthorised changes
  to HTTP headers and to the content of the payment page.

Both exist to curb client-side *skimming* (the Magecart family): the server is
clean, the PAN is exfiltrated from the browser.

A 2025 change that is frequently misquoted: in **SAQ A**, items **6.4.3, 11.6.1 and 12.3.1 were
removed** and an **eligibility criterion** was added — the merchant must confirm that
its site *is not susceptible to script attacks that could affect its e-commerce systems*.
**It is not an exemption**: the requirements remain in force in the standard, in SAQ A-EP,
in SAQ D and in the ROC. It is a shift in form, not in substance, and it is satisfied by
implementing the protection or **obtaining written confirmation from the PSP** that their solution
includes it. With a full redirect the criterion does not apply; with an `iframe`, it does.
(PCI SSC FAQ 1588, 28-02-2025.)

**Verify in §8**: eligibility, the item count of each SAQ and the "whole site versus payment page"
interpretation — this last point is not settled and **it is decided by your QSA
and your acquirer, not by a generic document**.

### 3.3 Cardholder data and sensitive authentication data

Two categories with opposite rules:

- **Cardholder data** (PAN, name, expiry, service code): may be stored if there is a
  business need, with the PAN unreadable wherever it is kept.
- **SAD** (track content, verification code, PIN/PIN block): **they are not stored
  after authorisation**, full stop. Only issuers and issuer-support entities have an exception.

Text of the PCI DSS v4.0.1 requirements (third-party reproduction, §8 declares the gap regarding
the primary source):

> **3.3.1.1** The full contents of any track are not stored upon completion of the
> authorization process.
> **3.3.1.2** The card verification code is not stored upon completion of the authorization
> process.
> **3.3.1.3** The personal identification number (PIN) and the PIN block are not stored upon
> completion of the authorization process.

And from the PCI SSC itself (FAQ 1280), on the case that is always attempted:

> "These values are not needed for card-on-file or recurring transactions, and storage for
> these purposes is prohibited […] However, it is not permitted to retain card verification
> codes/values once the specific purchase or transaction for which it was collected has been
> authorized."

What this implies and is usually ignored:

- **Encrypting the CVV does not make it allowed.** The requirement forbids *storing*, not
  *storing in the clear*. Crypto-shredding does not help either: it is still stored.
- **A log, a trace, a `crash dump`, a backup or an audit row count as
  storage.** The standard's guidance explicitly lists transaction, debugging and error logs,
  history and trace files, database schemas and contents —local and in the cloud— and memory
  dumps.
- Retaining it briefly in **non-persistent memory** after authorisation is contemplated only
  with a legitimate business need, guarantees of non-persistence and immediate deletion. It is not
  a back door for "keeping it for a little while".
- Collecting it **before** authorising is not forbidden. Retaining it afterwards is.

**Tokenisation**: the PSP's token replaces the PAN in your systems and is the standard mechanism
for stored cards and subscriptions. **A PSP token is specific to that PSP**: changing provider
requires a negotiated token migration — ask about it *before* signing, it is one of the harshest
forms of vendor lock-in in the catalogue.

**Network tokens** (scheme tokenisation, EMVCo specification): the token is issued by the network
—not by the PSP— and updates itself when the card is renewed or replaced. Real and
measurable benefit: fewer declines from expired cards in subscriptions. Cost: it depends on the PSP
and the scheme, and **not all flows support it** — verify coverage by country and scheme.

### 3.4 The state machine of a card transaction

`authorise → (capture | void) → [settle] → (refund | dispute)`

- **Authorisation**: the issuer reserves the amount and returns a code. **No money moves.**
  It has an expiry (days, and it depends on the scheme and the merchant type): if you do not
  capture in time, the authorisation expires and it has to be requested again.
- **Capture**: the instruction to charge. It may be **full, partial or multiple** depending on the
  PSP and the scheme. Partial capture is the correct answer when you ship half an order: **do not
  capture the full amount and refund the difference** — it generates a fee and an
  unnecessary movement on the customer's statement.
- **Void**: cancels an **uncaptured** authorisation. It is clean and usually leaves
  no trace for the customer. It stops being possible as soon as you capture.
- **Refund**: a **new** movement in the opposite direction, on a capture already made. It takes
  days to show up, **usually does not return the acquiring fees**, and may fail
  on its own.
- **Reversal / *auth reversal***: releasing an authorisation you are not going to capture is a
  courtesy with real impact —it frees the customer's credit— and avoids support complaints. Do it
  explicitly; do not rely on expiry.

**Design consequence**: the state of an order and the state of a payment are **two different state
machines** that are synchronised. Merging them into one `status` column is the root cause of most
mismatches.

### 3.5 Idempotency: a requirement, not an optimisation

Every operation that moves money runs over a network that **fails at the worst moment**: the
`timeout` where you do not know whether it arrived. If the client retries and the server does not
distinguish "this is the same one" from "this is another one", you charge twice.

Rules:

1. **The key is generated by the client**, not the server, and travels in the request
   (`Idempotency-Key`). It must be a unique identifier of *business intent*: for example,
   a UUID generated when creating the payment attempt — **never** a hash of the body nor the order
   ID on its own (two legitimate payments for the same order do exist: retry after failure, partial
   payment).
2. **It is persisted before calling the PSP**, in the same database transaction that creates the
   attempt record. Persisting it afterwards is a race against the retry.
3. **The response is stored and replayed as is** on a repeat, with the same status
   code. Retrying an already used key **with a different body** is a client error:
   answer it as a conflict, do not execute it.
4. **Explicit retention window** (typically 24 h at PSPs; verify your provider's) and later
   purging.
5. **Event consumers are idempotent too.** Brokers deliver
   *at-least-once*: processing the "payment captured" event twice duplicates an entry.
6. **End-to-end idempotency**: your API is idempotent towards your client *and* you propagate
   a key towards the PSP. Only one of the two layers is not enough.

Source warning: **`Idempotency-Key` is not an IETF standard**. The draft
`draft-ietf-httpapi-idempotency-key-header` is **expired** (version 07, last revised
2025-10-15, marked as expired in April 2026). It is a well-established industry convention
—Stripe, Adyen, PayPal and others implement it— but there is no RFC: **verify the exact semantics
in your PSP's documentation**, do not assume them.

### 3.6 Settlement and reconciliation: the money that arrives is never the money you charged

Between capture and payout there are: **PSP and acquirer fees**, *interchange* and scheme
fee, **holdbacks** (*reserve*, *rolling reserve*) from the acquirer, **currency conversion**
with its margin, refunds and disputes of the period, and taxes on the fees.
Besides, **a settlement groups N transactions** from several days and does not match 1:1 with
anything.

In the EU, the **interchange fee caps** are set by Regulation (EU) 2015/751
for consumer card transactions (verbatim, Art. 3(1)): *"Payment service providers
shall not offer or request a per transaction interchange fee of more than 0,2 % of the value of
the transaction for any debit card transaction"* — and **0,3 %** for credit (Art. 4). They apply
from 9-12-2015. **They do not cover commercial cards nor those of three-party schemes**, nor
are they your total fee: *interchange* is a component, not the price.

Minimum reconciliation design:

- **Automatic and daily** ingestion of the PSP's settlement file / *payout report*.
- **Matching by transaction identifier**, not by amount: amounts coincide by
  chance and matching by amount produces false positives.
- **Every movement on the statement has its counterpart** in the ledger: gross, fee,
  holdback, exchange difference. If you record only the net, you have lost the fee as
  an expense and the gross as revenue.
- **Alert on orphan items** in both directions: charges not settled past the
  expected deadline, and settlement lines with no local transaction. An orphan item **ages**;
  the useful SLI is the age of the oldest one, not the count.
- **Reconciliation is not "fixed" by editing the past**: it is corrected with a new entry.

### 3.7 Money in the code

- **Amount = integer in minor units + ISO 4217 code.** `amount_minor: 1999, currency:
  "EUR"`. Never `float`/`double`; never `19.99` as a number. In the database, integer or
  `NUMERIC` with an explicit scale — never a binary floating-point type.
- **Not all currencies have two decimals.** JPY and KRW have zero; some (e.g. those of
  the dinar family) have three. A `* 100` embedded in the code is a bug waiting
  for an international expansion. **The number of decimals is looked up in the ISO 4217 table, not
  assumed** (§8: iso.org blocks automated download; use the list maintained by your i18n
  library and verify).
- **Rounding is decided once and documented** (taxes, proration, splitting a discount
  across lines). Prorating without distributing the remainder produces one-cent mismatches
  that nobody can find.
- **Never convert currency on your own for accounting.** Record the original amount, the
  settled one and the rate applied by whoever applied it.
- **Double-entry, append-only ledger.** Every movement is an entry with debit and
  credit summing to zero; nothing is updated or deleted; a correction is a contra-entry.
  The balance is a derived projection, not an editable column. This is what makes it possible
  to reconstruct "why the balance is this" six months later — and what makes the system
  auditable (evidence for `grc-compliance-standards`).
- **Clock and time zone**: every instant in UTC with an explicit offset. The accounting cut-off of
  a day is a business decision, not whatever the server decides.

### 3.8 Webhooks and state

The PSP's webhook **can be lost, duplicated, arrive late and arrive out of order**. Rules:

- **Verify the signature** with the shared secret, with constant-time comparison, and
  **reject old timestamps** (replay defence).
- **Respond `2xx` quickly and process in the background.** A slow webhook is retried and
  duplicated.
- **Treat it as a notification that "something changed", not as the data.** On an event, **re-read
  the state via the API**. It is the difference between a system that withstands disorder and one
  that believes the last message that arrived.
- **Have a polling plan B**: a periodic job that reconciles payments in a non-terminal state.
  Webhooks fail and nobody finds out until the close.
- **Idempotency by event identifier**, not by content.

### 3.9 SCA, exemptions and 3-D Secure

**Strong customer authentication** (PSD2) requires two independent factors from
different categories —knowledge, possession, inherence— with a dynamic link to the amount and the
payee. The exemptions are exhaustively listed in **Delegated Regulation (EU) 2018/389**
(verbatim from EUR-Lex, CELEX 32018R0389):

| Exemption | Art. | Literal threshold |
|---|---|---|
| Low-value remote payment | 16 | ≤ **EUR 30**; and cumulative since the last SCA ≤ **EUR 100** *or* ≤ **five** consecutive transactions |
| Contactless at the point of sale | 11 | ≤ **EUR 50**; and cumulative ≤ **EUR 150** *or* ≤ **five** consecutive |
| Unattended transport/parking terminal | 12 | No threshold |
| Trusted beneficiary | 13 | **Creating or amending the list does require SCA** |
| Recurring transactions | 14 | **Same amount and same payee**; the first one requires SCA |
| Transfer between own accounts at the same provider | 15 | — |
| Dedicated corporate processes | 17 | Only non-consumer payers, with the authority's approval |
| Transaction risk analysis (TRA) | 18 | See the next table |

**TRA** (Art. 18): only if the provider's fraud rate is below the Annex's reference
*and* the amount does not exceed the exemption threshold value (ETV) *and* the real-time analysis
does not detect any of the six indicators in Art. 18(2)(c). Annex table, verbatim:

| ETV | Remote card payments | Remote credit transfers |
|---|---|---|
| EUR 500 | 0,01 % | 0,005 % |
| EUR 250 | 0,06 % | 0,01 % |
| EUR 100 | 0,13 % | 0,015 % |

And the part that decides architecture: **the exemption is not applied by the merchant, it is
applied by a payment service provider** — and Art. 20 requires **ceasing** the use of TRA in a
band if the fraud rate exceeds the reference **for two consecutive quarters**, without being able
to use it again until it has been back below for a quarter. Consequence: **requesting the exemption
is betting your fraud rate**. The issuer may also refuse the exemption and demand a *challenge*.

**EMV 3-D Secure 2.x** is the protocol that carries the context data to the issuer so it can
decide between a *frictionless* flow and a challenge. Status verified (emvco.com,
August 2026): the published line is **v2.2.0–2.3.1.1**; there is a **draft v2.4.0.0** whose
comment period ended on 1 July 2026. **Verify the version your PSP and your target issuers
actually support**, which lags behind the specification.

**Liability shift**: a transaction authenticated with 3DS shifts
responsibility for fraud to the issuer in most e-commerce scenarios.
**The details —which result codes protect you, which dispute reasons are excluded,
what happens with exempted transactions— are set by each scheme's rules (Visa,
Mastercard), not by European legislation.** Those rules are contractual and their current version
is verified with your acquirer. **Declared gap in §8**: do not assert percentages or guarantees of
liability shift without the rules document in hand.

**PSD3 / PSR — actual status**: **they are not approved**. Verified in the European Parliament's
Legislative Observatory (August 2026): PSD3 = procedure **2023/0209(COD)**, PSR =
**2023/0210(COD)**; both with the latest event *"05/05/2026 — Approval in committee of the text
agreed at early 2nd reading interinstitutional negotiations"*, status **"Awaiting Council's 1st
reading position"** and an **indicative plenary date of 14/12/2026**. There is no final act nor
publication in the OJEU. **Do not plan against an application calendar that does not yet exist**:
what applies today is still PSD2 and its RTS.

### 3.10 Disputes, *chargebacks* and fraud

A *chargeback* is a reversal initiated by the issuer at the cardholder's request. General flow:
**dispute → submission of evidence (*representment*) → pre-arbitration → arbitration**, with
deadlines per stage and a fixed cost per case, win or lose. Besides, **the dispute rate is
monitored by the schemes**: exceeding their thresholds puts the merchant into monitoring
programmes with fines and, in the extreme, loss of the ability to take payments.

The **specific deadlines and thresholds are scheme rules and change**: do not write them from
memory, get them from your acquirer. What is stable criterion:

- **Preserve the evidence from day one**: IP and device fingerprint, timestamp,
  consent record, proof of delivery, communications and the 3DS result. Gathering it
  when the dispute arrives is too late.
- **Recognisable statement descriptor**: a large share of "I do not recognise this charge"
  disputes is friendly fraud caused by a cryptic descriptor. Best cost/benefit ratio
  in the area. And **cancelling is cheaper than disputing**: friction in refunding turns
  into a *chargeback*, which costs more.
- **Anti-fraud**: rules + scoring, with **thresholds that are a business decision** (every point
  of fraud blocked costs legitimate sales). Measure **both** rates: fraud and false positives;
  a model with no measure of legitimate rejections optimises only one side.
- **AML/KYC**: identity, sanctions and PEP screening, monitoring and reporting. **The obligation
  and its governance belong to `grc-compliance-standards`**; here only that the hook points go in
  from the design — adding them later means redoing the onboarding flow.

### 3.11 Beyond the card

- **SEPA SCT / SCT Inst**: euro credit transfer. Regulation (EU) 2024/886 sets (verbatim)
  that euro-area PSPs offer **receipt** of instant credit transfers **from
  9-1-2025** and **sending from 9-10-2025**; outside the euro area, **9-1-2027** and **9-7-2027**.
  With sending comes the obligation of the **verification of payee service** (*VoP*):
  checking name and IBAN before the payer authorises. Product effect: **the payee's name
  stops being decorative** and a mismatch creates real friction in the flow.
- **SEPA SDD**: direct debit is based on a **mandate** signed by the debtor, with a
  unique identifier, the creditor's reference and preserved proof of consent. Two
  schemes: **Core** (consumers, with a right of return without a reason within a deadline, and
  extended if there was no valid mandate) and **B2B** (only between businesses, without that
  right, with prior mandate verification by the debtor's bank). **The exact deadlines are
  published by the EPC and change between rulebook versions**: verify them (§8). Design: store the
  mandate as a first-class entity with its history; a mandate lapsed through inactivity is the
  classic cause of the mass return.
- **Open banking / pay by transfer** (PIS under PSD2): the user authorises at their bank;
  there is no card, no *chargeback*, typically a lower fee and **the risk shifts to
  fraud through manipulation of the payer**, which no SCA stops. With no reversal available, the
  refund policy is yours, entirely. Watch out for availability too: **you depend on the user's
  bank's API**, with its maintenance window and its error rate.
- **Crypto-assets**: in the EU **MiCA, Regulation (EU) 2023/1114** applies — applicable from
  **30-12-2024** (Titles III and IV from 30-6-2024), with the transitional regime of **Art.
  143(3)** verbatim: providers that were already providing services *"may continue to do so until 1
  July 2026 or until they are granted or refused an authorisation pursuant to Article 63,
  whichever is sooner"*, and with the power of Member States to shorten it. **That period has
  already expired**: as of August 2026, providing crypto-asset services in the EU without
  authorisation is outside the law. Engineering corollary: **accepting crypto is not "adding a
  payment method", it is entering an authorisation regime** — or delegating entirely to an
  authorised provider and verifying its registration. It also adds volatility, irreversibility and
  AML traceability. **Verify the state of the provider's registration in §8.**

## 4. Quality and testing

- **Everything is tested against the PSP's *sandbox***, with its test cards, decline
  codes and 3DS scenarios. A mock of your own tests your mock.
- **Mandatory cases** besides the happy path: decline for funds and for suspected
  fraud, expired authorisation, `timeout` with no response (the idempotency case), duplicate,
  out-of-order and invalidly signed webhooks, partial capture, partial refund, refund
  larger than the capture, zero-decimal currency, currency change, dispute received.
- **Ledger property**: for any sequence, debits = credits and derived balance =
  balance recomputed from scratch.
- **Real concurrency**: N simultaneous requests with the same idempotency key produce
  **one** charge. Genuinely in parallel, not in sequence.
- **Reconciliation with a real anonymised file**, including an orphan item and a negative fee.
- **Negative log test**: run a payment and **fail if the dump contains anything that looks like
  a PAN or a CVV**. It is the only thing that makes the prohibition in §5 not depend on memory.
- **CI gates**, in increasing cost: static analysis that **forbids `float`/`double` in monetary
  types** and detects PAN/CVV patterns → *secret scanning* → ledger unit tests →
  contract with the PSP (record/replay) → SCA → integration with the *sandbox*.

## 5. Stack security

- **Never log** the full PAN, CVV, track, PIN or the PSP's raw response. The filter goes
  **in the logging layer** (allowlist-based redactor), not in every `logger.info`. The most
  frequent escapes are APM traces, error reports and exception dumps.
- **Client-side skimming (Magecart)** is the dominant vector and **it does not touch your server**:
  minimise third-party *scripts* on the payment page, restrictive CSP, SRI, *script* inventory and
  authorisation (6.4.3) and tamper detection (11.6.1). The *frontend* is payment surface.
- **Object authorisation**: `GET /payments/{id}` without checking ownership is the domain's IDOR,
  with financial-data impact. And **who can refund, up to how much and with what
  second approval** is a business control, not an interface one — internal fraud lives there, just
  as in the separation between who sets prices and who approves mass credits.
- **PSP secrets** in a manager with rotation, different keys per environment; the production key
  **is forbidden** outside production. Modern TLS end to end; **pin the PSP's certificate only if
  you have a rotation process** — otherwise it is a scheduled incident.
- **Card testing**: validating stolen cards with micro-charges against your form. It is detected by
  an **anomalous decline rate**, not by volume. Without rate limiting by card, account and
  IP, your endpoint is somebody else's validator and you pay for the authorisations.
- **Enumeration**: unguessable payment identifiers (UUID/ULID), never sequential.
- **Retention**: define and **apply** deletion. Card data you do not keep does not leak.

## 6. Performance and operability

- **SLIs that matter**: approved authorisation rate (by PSP, method, country and BIN), p95/p99
  latency and PSP error rate, webhook delay, age of the oldest unreconciled item, dispute and
  refund rate, effective cost per transaction.
- **A drop in the approval rate is an incident** that no infrastructure monitor
  sees: everything green and the money is not coming in. Alert on deviation from the baseline
  **per segment**, not on an absolute threshold.
- **Explicit and short timeouts** towards the PSP, with an idempotency key ready to retry.
  Without a timeout, a slow PSP is your outage.
- **Degradation**: if the PSP does not respond, **do not guess the outcome**. Payment in "pending
  confirmation", a message that promises nothing, and resolution by reconciliation. The worst
  possible design is to assume failure and let the user retry on a charge that did go through.
- **Multi-PSP** is resilience and cost, not decoration: two integrations, two reconciliations, two
  token models and a routing layer. Justifiable with high volume or geographic
  dependency; **premature almost always**.
- **Peaks**: the campaign hits payment at the end of the funnel, with the user already committed.
  Load-test the complete payment flow and agree rate limits with the PSP in
  advance.
- **Traceability**: one correlation identifier crossing order → attempt → call to the
  PSP → webhook → ledger entry → settlement line. Without it, a lost cent costs days.

## 7. Sustainability and prohibitions

- **Cadence**: review of PCI scope **on every change to the payment page**, and in any
  case annually; annual validation (SAQ/ROC) and quarterly ASV scans where applicable;
  tracking the PSP's API versions and their retirement dates — **PSPs retire
  API versions and do not wait**.
- **Decision record (ADR)** for: choice of PSP, integration architecture and target SAQ,
  capture policy, SCA exemption policy, refund policy.

Prohibitions:

- ❌ **FORBIDDEN to store CVV/CVC2/CAV2/CID, track content or PIN after authorisation**,
  in a database, log, cache, queue, backup, spreadsheet or support ticket. Encrypted
  included.
- ❌ **FORBIDDEN to represent money with floating point.** Not in the API, not in the domain, not
  in the database, not in JSON.
- ❌ **FORBIDDEN to `UPDATE` or `DELETE` an accounting entry already written.** It is corrected with
  a contra-entry.
- ❌ **FORBIDDEN to call the PSP without an idempotency key** in any operation that moves
  money.
- ❌ **FORBIDDEN to treat a webhook as the source of truth** without re-reading the state via the
  API, and **forbidden to process it without verifying the signature**.
- ❌ **FORBIDDEN to forward the PAN through your server "just passing through"**. That one-line
  *proxy* turns the entire service into CDE.
- ❌ **FORBIDDEN to capture before you can deliver**, unless there is a business model that
  justifies it and it is communicated.
- ❌ **FORBIDDEN to infer the state of a payment from the HTTP code of a lost response.** A
  `timeout` is not a failure: it is an unknown.
- ❌ **FORBIDDEN to disable SCA "because it converts worse"** without an applicable exemption and
  without somebody who applies it legitimately.
- ❌ **FORBIDDEN to have a payment endpoint without rate limiting** (it is somebody else's stolen
  card validator, and you pay for the authorisations).
- ❌ **FORBIDDEN to record only the net settled amount.** Gross, fee, holdback and exchange,
  each with its own entry.
- ❌ **FORBIDDEN to copy from this document a dispute deadline, a fee or a scheme threshold
  without verifying it with your acquirer.**
- ❌ **FORBIDDEN to collect card data by email, chat, recorded phone call or support
  ticket.** It is the shortcut that turns customer service into part of the CDE.

## 8. Mandatory web verification

Check **before** committing to anything:

1. **PCI DSS**: current version (as of August 2026, **v4.0.1**), the status of the requirements
   that stopped being best practice on **31-03-2025**, and their exact number. Primary source:
   `pcisecuritystandards.org` → Document Library. **Declared gap**: the PCI DSS v4.0.1 PDF
   returns **HTTP 403** to automated download (it requires accepting the licence agreement);
   the text of requirements 3.3.1.1/3.3.1.2/3.3.1.3 quoted in §3.3 comes from a
   **third-party reproduction** (`sammy.codific.com`), not from the primary source. **Cross-check
   it against the official PDF before using it as audit evidence.** The only PCI SSC text
   quoted here from a direct source is FAQ 1280 from the official blog.
2. **SAQ A / A-EP / D**: current eligibility criteria, FAQ 1588 and its revision, and the
   number of items in each questionnaire. And above all, **what your acquirer and
   your QSA require**, which override any generic reading.
3. **PSD2 / SCA**: Delegated Regulation **(EU) 2018/389** on EUR-Lex (CELEX 32018R0389) and the
   **EBA** guidelines and opinions, which are what set the operational interpretation
   (SCA delegation, MIT versus recurring, scope of *one-leg*).
4. **PSD3 / PSR**: status in the EP's Legislative Observatory —**2023/0209(COD)** and
   **2023/0210(COD)**— and on EUR-Lex. As of August 2026 **there is no final act published**; the
   indicative plenary date is 14/12/2026. Any source that treats them as approved or that sets
   application dates is getting ahead of itself.
5. **MiCA**: Regulation (EU) **2023/1114**, the end of the national transitional regimes
   (Art. 143(3)) and **ESMA's register of authorised providers** to verify your
   counterparty.
6. **SEPA**: current **EPC** rulebooks (SCT, SCT Inst, SDD Core, SDD B2B) — return,
   presentation and mandate validity deadlines change between versions — and Regulation
   (EU) **2024/886**.
7. **EMV 3DS**: published version and drafts at `emvco.com`, and **which version your PSP
   really supports** (it lags behind).
8. **Scheme rules (Visa, Mastercard)**: dispute deadlines and reasons, thresholds of monitoring
   programmes, exact conditions of liability shift. **Declared gap**:
   Visa's public rules PDF returns **HTTP 403** to automated download; get it
   through your acquirer. **No deadline or percentage from those rules is asserted here.**
9. **Interchange fees**: Regulation (EU) **2015/751** (0,2 % consumer debit / 0,3 % consumer
   credit) and its exclusions; and **your PSP's real price**, which is quoted from its pricing
   page with a date or not quoted at all.
10. **`Idempotency-Key`**: status of the IETF draft (as of August 2026, **expired**) and the
    specific semantics —window, conflict, key scope— **in your PSP's
    documentation**.
11. **ISO 4217**: number of decimals per currency. `iso.org` blocks automated download
    (**HTTP 403**): use the maintained list from your i18n library and verify the specific
    cases you are going to operate with.
12. **Your PSP**: current API version and retirement calendar, changes to the 3DS flow,
    token portability conditions in case of a provider change.

If the web contradicts this document, **the web wins** — flag the discrepancy.
