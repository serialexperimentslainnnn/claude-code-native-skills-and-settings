---
name: blockchain-web3-standards
description: Blockchain and web3 as infrastructure, custody and regulation — not as smart-contract code. Use when justifying whether a distributed ledger is needed at all versus a signed append-only database, evaluating permissioned ledgers (Hyperledger Fabric, LF Decentralized Trust, R3 Corda, Besu, Quorum), running or outsourcing nodes and JSON-RPC endpoints (geth, erigon, reth, nethermind, lighthouse, Infura, Alchemy, QuickNode, eth_call rate limits, archive versus full node, state growth, snap sync), choosing L1 versus L2 rollups and reading their trust assumptions (L2Beat stages, sequencer centralisation, 7-day optimistic challenge window, forced inclusion, escape hatch), cross-chain bridges and wrapped assets as a loss vector, key custody and signing process (hardware wallet, HSM, multisig, Safe, threshold MPC, seed phrase handling, signing ceremony, key compromise as the dominant theft cause), oracles and price-feed manipulation, MEV, sandwiching and private order flow at the application level, indexing and reorg-safe event ingestion (The Graph, subgraphs, block confirmations, finality), stablecoin and payment rails operations, wallet UX and address poisoning, or the regulatory constraints MiCA (Regulation (EU) 2023/1114), the Transfer of Funds Regulation (EU) 2023/1113 travel rule, AML/KYC on-ramps, accounting and tax treatment.
---

# Blockchain and web3 standards (infrastructure, custody and regulation)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

### 1.1 The prior, mandatory question: do you need a blockchain?

**This section is answered before any other technical decision, and in writing.** The
correct answer in the vast majority of enterprise cases is **no**.

A blockchain only contributes something when **all** of these conditions hold at once:

1. **Several parties write**, not a single organisation with departments.
2. **Those parties do not trust each other** — nor an intermediary that could arbitrate.
3. **No common accepted authority exists (or could exist)** to operate the register: no
   notary, no regulator, no consortium with a contracted trusted third party.
4. **Censorship or reversal resistance is needed**, not just traceability.
5. **The participants are neither known nor permanent**, or the set changes without anyone's
   permission.

If **any** of the five fails, the answer is: **relational database with an immutable audit
log, a digital signature per party and timestamping**. That gives integrity,
non-repudiation and verifiable traceability at a fraction of the cost, with ACID transactions,
SQL queries, GDPR deletion and a DBA who knows how to restore the backup.

Uncomfortable corollary: **the "private or permissioned blockchain" is almost always an
expensive database.** If a consortium decides who may write, who validates and who updates the
software, the common authority whose absence justified the chain already exists — and you have paid
for byzantine replication nobody needs. Hyperledger Fabric and Corda are serious pieces of
engineering (both **Apache-2.0**, raw `LICENSE`), and their real value when used
well is the **data and identity model shared between organisations**, not the
consensus. Before adopting them: check the project's real state and its cadence (§8), and
what happens to operations if the consortium dissolves.

Second corollary: **the chain does not validate the physical world.** Anchoring in an immutable
register a datum entered by a human does not make it true — it makes it *immutably false*. The
"oracle" problem is not technical, it is epistemological, and no chain solves it.

### 1.2 What this skill covers

Infrastructure (nodes, RPC, L1/L2, bridges, indexing), **key custody and the human
signing process**, oracles, MEV at the application level, and the regulatory,
accounting and tax constraints that condition the design.

Triggers: `geth`, `erigon`, `reth`, `nethermind`, `lighthouse`, `prysm`, `eth_call`,
`eth_getLogs`, `JSON-RPC`, `Infura`, `Alchemy`, `QuickNode`, `archive node`, `snap sync`,
`reorg`, `finality`, `L2Beat`, `sequencer`, `rollup`, `challenge period`, `bridge`,
`wrapped`, `Safe`, `multisig`, `MPC`, `seed phrase`, `hardware wallet`, `Ledger`, `Trezor`,
`HSM`, `oracle`, `price feed`, `MEV`, `mempool`, `The Graph`, `subgraph`, `Fabric`,
`chaincode`, `Corda`, `Besu`, `MiCA`, `travel rule`, `VASP`, `CASP`.

**Not applicable**: see **`solidity-standards`** (**hard, non-negotiable boundary**: the **smart
contract**, the **`solc` compiler**, the **EVM**, `pragma`, `evm_version`, proxies and
upgradeability, reentrancy, invariant tests, fuzzing, formal verification, code and gas
auditing. **Everything written in `.sol` and everything deployed is theirs, without
exception**; here only where it runs, who signs, with which key and under which rule),
`cryptography-pki-standards` (algorithm choice, curves, key management and lifecycle
in HSM/KMS — here only the **operational custody and signing process** applied to a key that
directly controls value), `post-quantum-crypto-standards` (**all** PQC migration and its
timetable; the quantum threat to ECDSA is not covered here), `secrets-management-standards`
(Vault/KMS, ephemeral credentials, rotation), `identity-access-management-standards`
(federation, OIDC, JWT and corporate identity governance),
`fintech-payments-standards` (**payments, accounts, reconciliation, PSD2/SEPA and running a
financial institution**; crypto-assets as a means of payment are coordinated with it — **not
duplicated**), `grc-compliance-standards` (risk framework, SoA, evidence and audit; here
only the translation into a design requirement), `privacy-engineering-standards` (**the structural
conflict between immutability and the right to erasure**: the criteria are theirs, here the
prohibition on writing personal data on chain), `appsec-standards` (STRIDE methodology,
OWASP and finding triage), `incident-response-forensics-standards` (incident handling,
fund tracing and coordination with exchanges), `offensive-security-standards` (offensive
testing with scope and authorisation; **this skill is defensive**), `observability-standards`
(telemetry platform and SLOs), `data-engineering-standards` and `streaming-cdc-standards`
(the pipelines that ingest chain events into an analytical store),
`vulnerability-management-standards` (CVE triage for the node client),
`opensource-licensing-standards` (stack licences), `rust-standards` / `go-standards` /
`typescript-standards` (the language of the services that talk to the chain),
`quantum-computing-standards` (nothing to do with "quantum web3").

## 2. Default decisions

> Verify on the web before committing to anything (§8). The regulatory and version data in this
> domain expire within months.

| Decision | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Blockchain? | **No.** Relational DB + signed audit log + timestamping | Public chain if the five conditions in §1.1 hold | Adopting it because a stakeholder asked for it by name |
| If there is a chain | **Established public chain** with an availability track record and an ecosystem of auditors | Permissioned **only** with a real consortium, written governance and an exit plan | A new chain because it has low fees |
| Nodes | **Own full node** for critical reads + RPC provider as *fallback* | Provider only if operations tolerate its outage and its censorship | **A single RPC provider** as a hard dependency |
| Confirmations | Wait for protocol **finality**, not "N blocks" copied from a blog | Fewer confirmations for non-financial UX, documented | Treating a transaction as final once mined |
| L2 | Choose by **documented trust assumptions** (L2Beat stage), not by TPS | Direct L1 if cost allows: fewer assumptions | Treating a *stage 0* L2 as if it were Ethereum |
| Bridges | **Avoid them.** Design so as not to cross chains | The rollup's own canonical bridge, never a third-party one, with exposure limits | Third-party bridges custodying material value (§5.2) |
| Custody | **Threshold multisig (Safe) or MPC**, signers on different devices and different people | Certified HSM if the operation is institutional | **A single hot key** with power to move funds |
| On-chain data | **Hashes and commitments only.** The data lives outside | Data public by nature and already published | Any personal data, not even encrypted (§5.5) |
| Oracle | **Decentralised, aggregated feed**, with range validation, *staleness* and circuit breaker | Own signed oracle if you are the consumer and take the risk | *Spot* price from a single DEX (§5.3) |
| Regulation | Determine **before designing** whether the activity falls under MiCA and whether you are a CASP | — | Designing first and consulting legal afterwards |

## 3. Infrastructure: what really costs

### 3.1 Nodes

- **A node is not a container you spin up and done.** It is a machine with a large and
  growing NVMe SSD, constant bandwidth, an initial sync of hours or days, and **state that
  grows monotonically**. Capacity is planned with the state's growth rate,
  not with today's size.
- **Full node vs *archive***: the *full* one answers about recent state; the *archive* one keeps
  every historical state and multiplies storage by an order of magnitude. Almost
  nobody needs *archive*: if the answer is "for historical queries", the right place
  is an **own index in an analytical database**, not an archive node.
- **Client diversity**: the Ethereum documentation says it explicitly —
  *"Multiple client implementations can make the network stronger by reducing its dependency
  on a single codebase. The ideal goal is to achieve diversity without any client dominating
  the network, thereby eliminating a potential single point of failure."* If you operate several
  nodes, **not all with the same client**.
- **Protocol upgrades (*hard forks*) are planned unavailability
  windows**: a node not updated in time ends up on a minority chain and serves
  false data without raising an error. Subscribing to the client's and the protocol's announcements is
  operations, not a personal interest.

### 3.2 The RPC provider irony

The decentralisation of the average application ends at **two or three RPC providers**. A
"decentralised" frontend pointing at a single managed endpoint has exactly the
same SPOF as any SaaS, plus the false sense of not having one. And on top of that the provider
**sees** all your users' addresses and queries: it is a correlation and censorship point,
not just an availability one.

Criteria: at least **two independent providers with automatic failover**, and for
critical reads (balances, payment confirmation, settlements) **an own node as the source
of truth**. Everything a third-party RPC returns is a **third party's assertion**, not a
cryptographic truth, unless you verify proofs.

### 3.3 L1, L2 and rollups: read the trust assumptions

- A rollup **inherits the L1's security only to the extent that its exit mechanisms
  work permissionlessly**. Check before deploying: is the sequencer single and
  centralised? is there **forced inclusion** from L1? is there an **escape hatch** if the
  operator disappears? who can upgrade the canonical bridge contracts and with what
  *timelock*? are there **active** fraud/validity proofs, or are they disabled "for now"?
- **The withdrawal period of optimistic rollups is a real operational risk, not a
  detail.** The OP Stack documentation: *"mainnet messages sent from Layer 2 to Layer 1
  cannot be relayed for at least 7 days"*. Arbitrum's mentions *"a 6.4-day challenge
  period"* for L2→L1 messages and *"a seven-day challenge period to safeguard withdrawals"* in
  the canonical bridge. L2Beat requires *"a ≥7 days challenge period for all Optimistic Rollups to
  be considered Stage 1"*.
  **Treasury consequence**: capital on the L2 is **illiquid for a week** via
  the canonical route. The fast alternatives are third-party liquidity bridges — which replace
  the delay with **counterparty risk**. If your financial model assumes immediate liquidity,
  it is wrong. Model the worst case: canonical withdrawal + L1 congestion.
- **L2Beat classification as a decision tool**, with its explicit criterion for Stage
  1: *"The only way (other than bugs) for a rollup to indefinitely block an L2→L1 message
  (e.g. a withdrawal) or push an invalid L2→L1 message (e.g. an invalid withdrawal) is by
  compromising ≥75% of the Security Council"*, and *"Users are able to exit without the help of
  the permissioned operators"*. Verify the current *stage* of the specific chain before
  committing funds (§8).

### 3.4 Indexing and reorganisations

- **Never read application state by querying the chain in the hot path.** You index into an
  own database and serve from there. Querying `eth_getLogs` on the hot path is
  slow, expensive and fragile.
- **The indexer must be reorg-safe**: recent blocks can disappear. Correct
  design: mark events by block number and hash, and **revert** the events of
  orphaned blocks; do not consume events below the finality threshold as definitive.
- **Idempotency is mandatory** in the consumer: the same event will be reprocessed. Deduplication
  key = (transaction hash, log index).
- Historical *backfill* and the live *tail* are two code paths with different failures:
  test both, and test restarting mid-*backfill*.

## 4. Key custody: the axis of the domain

**The datum that orders the priorities**: Chainalysis, 2025 crime report (2024 data):
*"Private key compromises accounted for the largest share (43.8%) of stolen crypto in 2024"*,
out of some *"$2.2 billion"* stolen. In the mid-2025 update: *"With over $2.17
billion stolen from cryptocurrency services so far in 2025…"* and *"At $1.5 billion, this
single incident not only represents the largest crypto theft in history, but also accounts
for approximately 69% of all funds stolen from services this year"* (Bybit). Methodology caveat
from the report itself: the data *"include only known stolen fund events… They are
therefore not a comprehensive view"* — they are a **lower bound**.

Engineering reading: **the dominant failure is not in the contract, it is in the key and in the
human who signs.** A budget that spends everything on code auditing and nothing on custody
is badly allocated.

### 4.1 Hard rules

- **No key with power to move funds lives on an application server, in an environment
  variable, in a `.env`, in a generic secrets manager or in CI.** If the process that
  serves HTTP requests can sign, an RCE is a total and irreversible loss.
- **Threshold multisig (m-of-n) by default** for treasury and for any privileged
  on-chain role. The signers: **different people, different devices,
  different locations, with at least one signer outside the blast radius of a compromise of the
  cloud provider**.
- **MPC/threshold** as an alternative when a single on-chain signature is needed (privacy,
  cost, chains without native multisig). It is not "better" than multisig: it moves the risk from the
  contract to the library provider and to its key generation ceremony.
- **HSM** when there is an institutional or certification requirement. An HSM protects the key from
  theft, **not from improper signing**: if the application can ask it to sign, so can the attacker who
  controls the application. The control is the **approval policy**, not the hardware.
- **Cold ≠ hardware wallet in a drawer.** Cold means: key generated offline, seed backup
  on durable material and in physical custody under dual control, a **rehearsed**
  recovery procedure and a record of who holds what. A seed written on paper in
  the CTO's safe with no restore rehearsal is a future loss.
- **The backup is tested.** Recover on a new device, with the real ceremony, at
  least once a year. A backup never restored does not exist.

### 4.2 The human signing process

The link that breaks is **blind signing**. A signer who sees a hex blob and
presses "approve" is not approving anything: they are delegating to whoever prepared the transaction.

Minimum procedure for any transaction of material value:

1. **Preparation** by one person, **independent review** by another, with the *intent* of
   the operation written in natural language.
2. **Out-of-band verification** of the destination address and the amount through a channel
   different from the one that brought the request. Supplier impersonation fraud lives here.
3. **Prior simulation** of the transaction against a fork of the current state, checking which
   balances actually change — not what the frontend says changes.
4. **Verification on the signing device**: what is approved is what the hardware screen
   shows, **not the computer's**, which may be compromised.
5. **Independent approvals** by the threshold signers, without one person preparing and signing
   twice with two of their own devices.
6. **Record** of who approved what and why, retained as evidence.

Unlimited approvals to contracts (`approve` for the maximum) are permanent debt:
**approve the exact amount and revoke what is no longer used**, with periodic review of live
approvals.

### 4.3 Address poisoning and destination errors

Addresses look alike and **transfers are irreversible**. Controls:
destination allowlist with two-step registration and a waiting period, verification of the
full characters (not just the first and last four), a minimum-amount test transaction
before a large send, and detection of addresses "similar" to those in the history —
the attack consists precisely of seeding the history with zero-value transfers
from an almost identical address.

## 5. Specific risks

### 5.1 Stack surface

- **Own RPC endpoint exposed**: never open to the Internet. Administrative methods
  (`admin_*`, `personal_*`, `debug_*`) disabled; `eth_*` only behind a proxy with
  authentication, rate limiting and per-query cost limits. An `eth_getLogs` without a bounded range is
  a free DoS.
- **Frontend**: the biggest recurring incident is not the contract, it is the **hijacking of the DNS or
  of the frontend bucket** to serve an interface that makes you sign something else. Controls:
  register the domain with transfer lock and MFA, DNSSEC, immutable and signed
  deployment, **SRI** on third-party scripts and integrity monitoring of the served
  bundle.
- **JavaScript dependencies in the signing path**: a compromised library on `npm` that
  alters the destination address before signing is the most profitable supply-chain attack
  that exists. Pin by *digest*, review every update of the signing path, and
  minimise the number of packages that touch the transaction.

### 5.2 Bridges: the worst documented loss record

Chainalysis, August 2022: *"$2 billion in cryptocurrency has been stolen across 13 separate
cross-chain bridge hacks"*, and *"Attacks on bridges account for 69% of total funds stolen in
2022 so far"*. A bridge concentrates custody of assets from several chains under one set
of keys or one verification contract, and has neither the liquidity nor the scrutiny of the L1 it
imitates.

Criteria: **design so as not to need a bridge**. If it is unavoidable — the rollup's own canonical
bridge before a third-party one, **hard exposure limit** (maximum amount in transit and
in the bridge contract), monitoring of anomalous events, and explicit written acceptance of the
risk by whoever answers for the money. "Wrapped" assets are a **third party's IOU**,
not the original asset: account for them as such.

### 5.3 Oracles

Every on-chain price is manipulable with enough capital if its source is shallow. The
standard attack pattern is moving the price of a thin pool inside the same
transaction that consumes that price. Defences: **aggregation of multiple independent
sources**, use of time-weighted averages when the case allows, **range and
staleness validation** in the consumer, and a **circuit breaker**
that halts operation on an anomalous deviation instead of operating on absurd data.
A downed oracle must **stop the system**, not silently return the last known value.
The contract implementation belongs to `solidity-standards`; here the requirement that the
design accounts for it.

### 5.4 MEV at the application level

The public mempool is a **noticeboard of your intentions**. Any operation whose
result depends on the price at execution time can be front-run or sandwiched.
Design mitigations (not contract ones): **strict and explicit slippage limits**
by default in the client, **short validity deadlines**, submission via **private order flow**
for large operations, and slicing the operation. And a product rule: if your UX sets a
high default slippage "so it does not fail", you are paying the difference to a third party.

### 5.5 Immutability versus data protection

**No personal data on chain. Not encrypted, not hashed.** A public chain is
immutable, globally replicated and unerasable: it breaches by construction the right to
erasure and rectification, and today's encryption is decryptable tomorrow. A hash of a personal
datum from a small domain (a national ID, an email) is **brute-forceable** and therefore
still personal data. Correct pattern: the data outside, in a system with real deletion; on
chain only a commitment with a secret salt, and deleting the salt as a mechanism for
*crypto-shredding*. **The criteria, the DPIA and the reidentification analysis belong to
`privacy-engineering-standards`.**

## 6. Regulation, accounting and operations

### 6.1 MiCA (EU)

**Regulation (EU) 2023/1114** — *"REGULATION (EU) 2023/1114 … of 31 May 2023 on markets in
crypto-assets, and amending Regulations (EU) No 1093/2010 and (EU) No 1095/2010 and Directives
2013/36/EU and (EU) 2019/1937"*. European Commission: *"29 June 2023 … The Markets in
Crypto-assets Regulation (MiCA) came into force."* Official EUR-Lex summary on its
application: *"It will apply from 30 December 2024. However, rules on asset-referenced tokens
(Title III) and e-money tokens (Title IV) have applied since 30 June 2024."*

Transitional regime: ESMA describes the *grandfathering* clause of Article 143 whereby
entities providing crypto-asset services under national law before
30 December 2024 could continue **until 1 July 2026 or until they are granted or refused
MiCA authorisation**, with periods varying by Member State.
**Verify the current status and the specific Member State's deadline before assuming anything
(§8).**

Design consequence, not after-the-fact compliance: **determine before writing code
whether the activity makes the entity an issuer or a crypto-asset service provider
(CASP)**. Custodying clients' keys, exchanging for fiat money, executing orders,
operating a trading platform or transferring on behalf of third parties are regulated
activities. The difference between "I custody my users' keys" and "the user custodies
their own" is not a UX decision: **it is what decides whether you need an authorisation**.

### 6.2 Travel rule

**Regulation (EU) 2023/1113** — *"REGULATION (EU) 2023/1113 … of 31 May 2023 on information
accompanying transfers of funds and certain crypto-assets and amending Directive (EU)
2015/849 (recast)"*. It requires crypto-asset transfers to be accompanied by originator
and beneficiary information. An **architectural** requirement: if your system moves crypto-assets on
behalf of clients, it needs to carry, validate and retain that data, and to decide what it does
when the counterparty does not send it or the destination is a self-hosted address. That is not
bolted on at the end. **Verify the application date and the EBA guidelines (§8): this document
does not fix them.**

### 6.3 AML/KYC and on-ramps

Fiat↔crypto ramps are the point where regulation bites hardest: customer
identification, sanctions screening, transaction monitoring and reporting of
suspicious activity. Design: **the ramp is delegated to an authorised provider** unless
the entity wants to be the regulated one itself, with documented due diligence on that
provider. Screening of addresses against sanctions lists **before** sending, not
after.

This skill's stance: **defensive and compliance-oriented**. No techniques for obfuscating
flows, circumventing controls or evading regulation are documented.

### 6.4 Accounting and taxation as a design constraint

- **Every transaction is an accounting event and often a taxable event.** The system
  must record, per operation: date and time, counterparty, crypto amount **and its
  countervalue in the functional currency at that moment**, fees (including the network fee,
  which is often a deductible expense), and the on-chain reference.
- **The exchange rate needs a defined and stable source** (which market, which moment, which
  rounding) and must be auditable after the fact. Changing the criteria mid-year is a problem.
- **Reconciliation between the ledger and on-chain state must be automatic and
  daily**, and a mismatch is an operational alert. Discovering it at the annual audit is
  too late.
- Adding this at the end is a rewrite: **if the accounting record was not designed with the
  system, it cannot be reconstructed** — the chain has the amounts, but not the countervalue
  at the time nor the intent of the operation.

### 6.5 Operations

- **Domain-specific observability**: balance of the operating accounts and a low-threshold alert
  (an empty gas account halts the service), lag behind the chain head,
  pending transactions by age, daily fee cost, and drift between the
  indexed state and the chain's.
- **Fee management**: volatile gas price, stuck transactions and the need for
  replacement with a higher fee. A service that sends transactions needs a retry policy,
  a spend limit and stuck-transaction detection — not a `send()` and hope.
- **Nonces**: two processes signing with the same account clash on nonces and cancel each
  other. A single serialised sender per account, or separate accounts per process.
- **On-chain incident runbook** written **before** the incident: who can pause,
  who summons the signers, how it is communicated, and what is done in the first two hours.
  The response plan belongs to `incident-response-forensics-standards`; the on-chain mechanism,
  to `solidity-standards`.

## 7. Long-term sustainability

- Update node clients at the protocol's cadence, not the team's: *hard
  forks* have a date and you do not negotiate it.
- Review annually: active multisig signers (a departure from the company without revoking a
  signature is an open hole), live contract approvals, bridge exposure, and
  the validity of the used L2's rating.
- Documented exit plan per dependency: RPC provider, custodian, bridge, L2 and consortium.
  "What do we do if it disappears tomorrow?" must have a written answer.

**Explicit prohibitions:**

- ❌ **FORBIDDEN** to adopt a blockchain without having answered in writing, and in the
  negative, the five conditions of §1.1.
- ❌ **FORBIDDEN** to present a permissioned chain as "decentralised" when there is a
  consortium that decides who writes, who validates and who updates.
- ❌ **FORBIDDEN** for a key capable of moving funds to exist on an application server,
  in CI, in a `.env` or in a repository. No "temporary" exceptions.
- ❌ **FORBIDDEN** to sign blind: a transaction of material value without prior simulation,
  independent review and verification on the signing device's screen.
- ❌ **FORBIDDEN** to depend on a single RPC provider for critical reads, and to treat its
  response as verified truth.
- ❌ **FORBIDDEN** to model treasury assuming instant withdrawals from an optimistic
  rollup: the challenge period is days, not minutes.
- ❌ **FORBIDDEN** to write personal data on chain, neither encrypted nor hashed.
- ❌ **FORBIDDEN** to consume the price of a single pool as an oracle, or to keep operating with a
  stale price without a *circuit breaker*.
- ❌ **FORBIDDEN** to grant unlimited approvals for convenience, or to leave live approvals
  without periodic review.
- ❌ **FORBIDDEN** to cite vendor TPS figures as operational capacity (§8).
- ❌ **FORBIDDEN** to design the system and afterwards ask whether the activity falls under MiCA or
  requires authorisation.
- ❌ **FORBIDDEN** to document or implement techniques for obfuscating flows, circumventing
  sanctions, KYC or reporting obligations. Defensive and compliance-oriented stance.
- ❌ **FORBIDDEN** to duplicate contract code criteria here: that belongs to `solidity-standards`.

## 8. Mandatory web verification

Before committing to anything in a real project:

1. **MiCA**: status of the Article 143 transitional regime **in the specific Member State** —
   ESMA described continuity *"until 1 July 2026 or until they are granted or refused a
   MiCA authorisation"*, a deadline that as of Aug 2026 has already expired or is expiring. Consult ESMA,
   the list of authorised CASPs and the national supervisor (CNMV/Banco de España in Spain).
   **Source of the application dates**: official EUR-Lex summary, verbatim; the full
   text of Article 149 **could not be obtained raw** (EUR-Lex truncated the document) — its
   exact wording came via **WebSearch** and must be confirmed against the official journal.
2. **Regulation (EU) 2023/1113 (travel rule)**: its application date and the EBA
   guidelines on thresholds and transfers to self-hosted addresses **were not verified
   verbatim** in this pass (EUR-Lex truncated the text before the final article). **Declared
   gap**: confirm before using them.
3. **Theft figures**: re-verify the current Chainalysis report. What was verified here:
   43.8 % from private key compromise in 2024 out of $2.2bn (2025 report), $2.17bn
   stolen from services in the first half of 2025 and Bybit $1.5bn ≈ 69 % of that total. All
   are **lower bounds** by the report's own declared methodology. The claim that
   key compromise explains *four of the ten largest thefts* comes from a previous verification
   of the catalogue and **was not re-verified here**.
4. **TPS: debunked folklore.** Solana's famous number comes from its own *white paper*
   (v0.8.13, Yakovenko), literally: *"The protocol is analyzed on a 1 gbps network, and
   this paper shows that throughput up to 710k transactions per second is possible with todays
   hardware."* It is a **theoretical vendor analysis on a 1 Gbps network**, not a
   production measurement. Every TPS figure published by a project about its own chain
   is measured in a lab, with trivial transactions and without state contention: **it is
   useless for sizing**. If you need a figure, measure it yourself with your load, or do not use it.
5. **L2**: the chain's current *stage* on L2Beat, who controls the sequencer, whether the
   proofs are active, the bridge's upgrade *timelock* and the exact duration of the
   challenge period. They change, and the last verification is not valid for the next quarter.
6. **Hyperledger Fabric / Corda**: current stable version and LTS policy — as of Aug 2026 the
   LTS branch documented in Fabric's `README` was **v2.5.x**, while the documentation
   mentioned release notes for **v3.1.5**: **unresolved discrepancy**, confirm which one is
   the recommended one. Also verify the current governance (Hyperledger was folded into LF
   Decentralized Trust: **the date of the change could not be confirmed in a primary source**) and the
   project's real health: number of maintainers, release cadence and live deployments.
   Both projects **Apache-2.0** according to their raw `LICENSE` files.
7. **CVEs and advisories**: for the node client you operate and for the signing libraries. A flaw in
   nonce generation or in key derivation is a total loss.
8. **Taxation and accounting**: the applicable treatment in the specific jurisdiction and the
   current financial year. This document **fixes no tax criteria**: it requires that they exist and
   that the system supports them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
