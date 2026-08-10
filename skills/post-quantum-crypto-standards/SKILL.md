---
name: post-quantum-crypto-standards
description: Planning and executing the migration to post-quantum cryptography — the transition, not the PKI. Use when scoping harvest-now-decrypt-later exposure by data lifetime, building a cryptographic inventory or a CBOM (CycloneDX crypto assets), or working with FIPS 203 ML-KEM, FIPS 204 ML-DSA, FIPS 205 SLH-DSA, the pending FIPS 206 FN-DSA and HQC, legacy Kyber/Dilithium/Falcon/SPHINCS+ names, hybrid TLS 1.3 key exchange with X25519MLKEM768 (IANA group 4588 / 0x11EC) or the retired X25519Kyber768Draft00 (0x6399), OpenSSH KexAlgorithms mlkem768x25519-sha256 and sntrup761x25519-sha512@openssh.com, IKEv2 additional key exchanges (RFC 9370, ke1_mlkem768) and RFC 8784 preshared keys, liboqs / oqsprovider / Open Quantum Safe, PQC support in AWS KMS, Google Cloud KMS or Azure Managed HSM, signature and key sizes blowing up a handshake, a firmware image or a certificate chain, crypto-agility as a design requirement, or the migration deadlines in NIST IR 8547, SP 800-131A and NSA CNSA 2.0.
---

# Post-quantum migration standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the transition**: deciding what to migrate, in what order, on what deadline and with what
evidence. Covers: the *harvest now, decrypt later* (HNDL) threat model and prioritisation **by
data lifetime**, cryptographic inventory and CBOM, choice of PQC algorithm and
parameters, deployment of **hybrids** in TLS, SSH and IKEv2/IPsec, the specific problem of
**signatures** (size, certificate chains, firmware, secure boot), **crypto-agility**
as a design requirement, regulatory timelines (NIST IR 8547, SP 800-131A,
CNSA 2.0) and their translation into a multi-year budgeted plan.

Triggers: `ML-KEM`/`ML-DSA`/`SLH-DSA`/`FN-DSA`/`HQC`, `Kyber`/`Dilithium`/`Falcon`/`SPHINCS+`,
FIPS 203/204/205/206, `X25519MLKEM768`, `0x11EC`, `mlkem768x25519-sha256`,
`sntrup761x25519-sha512@openssh.com`, `ke1_mlkem768`, RFC 9370, RFC 8784, `liboqs`,
`oqsprovider`, `PQCSecretKey`, CBOM, "quantum-safe", "crypto-agility", "Q-day", CNSA 2.0,
NIST IR 8547.

**Not applicable**: see `cryptography-pki-standards` (**mother skill and hard boundary**: the choice of
classical algorithm, AEAD modes, password hashing, randomness, **the whole PKI** —
CA hierarchy, `nameConstraints`, ACME, certificate lifecycle and revocation—,
key custody in HSM/KMS, mTLS and pinning, and the ban on rolling your own crypto.
**Here only the transition**: what gets replaced, when, in what order and how it is proven. If
the question is "which CA and with which keys", it is theirs; if it is "when do I stop being able to use that
key and why do I replace it", it belongs here), `secrets-management-standards` (custody and
rotation of the already-generated secret), `networking-standards` and `load-balancing-standards`
(TLS termination at the edge and its configuration), `vpn-standards` (**the tunnel as a
service**: `wg0.conf`, `swanctl.conf`, IKEv2 proposals, the concentrator and its operation —
**here only which PQC key exchange to require and on what deadline**),
`identity-access-management-standards` (JOSE/JWT, tokens and federation),
`cicd-standards` (artifact signing and runner OIDC inside the pipeline),
`kubernetes-standards` (cert-manager and admission-time verification),
`vulnerability-management-standards` (CVE triage and patching SLA: **"quantum risk"
is not a CVE and does not enter their queue**), `grc-compliance-standards` (formal acceptance of
residual risk and audit evidence), `opensource-licensing-standards` (licence of the
PQC libraries you introduce), `solidity-standards` (chain signature primitives),
`assembly-standards` (constant-time implementation), `mlsecops-standards` and
`ai-governance-standards` (nothing to do with this: "quantum" in AI marketing is not this).

## 2. Default decisions

> **No datum in this table gets written from memory into a deliverable.** Dates and states of
> FIPS, IR 8547 and CNSA 2.0 are re-verified before committing to a plan (§8).

| Need | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Key establishment | **ML-KEM-768 hybridised with X25519** (`X25519MLKEM768`) | ML-KEM-1024 if the requirement is CNSA 2.0 or the data lives for decades | ML-KEM **alone**, with no classical component, in production today |
| General-purpose signature | **ML-DSA-65** (or -87 if CNSA 2.0 demands it) | SLH-DSA when confidence in the assumption (hash only) matters more than size | FN-DSA (FIPS 206) before the final standard exists |
| Firmware / boot signature | **LMS or XMSS (SP 800-208)**, with serious state management | SLH-DSA if you cannot guarantee state (it is *stateless*) | Reusing a *stateful* key without index control: a repeated signature breaks the scheme |
| Alternative KEM | Wait for **HQC** as diversification, not as a replacement | — | Pinning HQC in a design before its FIPS is published |
| Deployment strategy | **Hybrid** (classical + PQC) for as long as the transition lasts | Pure PQC when the regulator requires it and the ecosystem supports it | "We'll migrate when the quantum computer shows up" |
| Order of work | **Long-lived confidentiality first**, signatures afterwards | Signature first if your product has a *root of trust* in firmware that cannot be updated | Prioritising by system ("let's start with production") instead of by data |
| Prerequisite | **Cryptographic inventory + CBOM** before touching anything | — | Migrating without knowing which algorithms you use: burnt budget and gaps |
| Library | The one from your platform vendor with PQC support (OpenSSL 3.5+, AWS-LC, BoringSSL, Go `crypto/tls`) | `liboqs`/`oqsprovider` for experimentation and for algorithms not yet integrated | `liboqs` in production without reading its own maturity warning |
| Progress metric | **% of connections/artifacts with PQC negotiated**, measured | — | "We're migrating" with no telemetry of what is actually negotiated |

## 3. HNDL: urgency is set by the data, not the system

- **Harvest now, decrypt later**: the adversary captures encrypted traffic today and decrypts it
  when a capable machine exists. That is why the deadline is **not** "when the
  quantum computer arrives": it is **today minus the data's lifetime**.
- Mosca's rule, and it is the only arithmetic needed: if **X** = years the data must
  stay secret, **Y** = years it takes you to migrate and **Z** = years until a
  CRQC (*cryptanalytically relevant quantum computer*) exists, **you have a problem if X + Y > Z**.
  Nobody knows Z; you do know X and Y, and they are the only ones you can change.
- **Prioritise by data type, not by system criticality**: medical records, genetic
  data, identity, trade secrets, classified material, legal files and
  **PKI and firmware root keys** have decade-long lifetimes. An encrypted shopping
  cart has a lifetime of minutes and is not urgent. A "critical" system that only moves
  perishable data is **less** urgent than an archived backup of personal data.
- Real HNDL surfaces: **VPNs and interconnections** (the traffic is interceptable and
  archivable), off-site backups and replication, encrypted messaging and mail, traffic
  towards cloud providers, and anything crossing a network you do not control.
- **Signatures do not suffer HNDL.** A signature only matters while it is being verified: forging it in
  2035 does not help whoever captured it in 2026. That is why **encryption is more urgent than
  signature** — with one exception that is urgent: **the root of trust that cannot be
  updated** (firmware, secure boot, field devices with a 15-20 year life). There the
  signature is decided today because there will be no second chance.

## 4. Inventory and CBOM: the first real step

- **Without an inventory there is no migration, there is burnt budget.** Before touching a single
  handshake: where crypto is used, with what algorithm, with what key size, with what
  library and version, who owns it and how long the data it protects lives.
- Sources that must be cross-referenced, because none is enough alone:
  1. **Static**: code and dependency scanning, `grep` for primitives, binary
     analysis. Finds what is written, not what runs.
  2. **Dynamic**: what is actually negotiated on the wire (TLS version, group, suite, certificate
     signature algorithm). Finds reality, not intent.
  3. **Certificate and key inventory**: internal CAs, stores, HSM/KMS, SSH keys,
     code- and firmware-signing keys. That is where the surprises live.
  4. **Third parties**: SaaS, suppliers, embedded devices and everything you cannot
     recompile. Here migration is **contractual**, not technical: put it in the clauses and
     in the supplier review now, not in 2032.
- **CBOM**: **CycloneDX 1.6** (also published as **ECMA-424**) introduced cryptographic
  assets; 1.7 refines them. **Verify the current version and the exact schema (§8).**
  It is generated **in CI**, not as an annual export: it is the living work list of the migration and the
  evidence the audit will ask for.
- Inventory output: each asset with **data class, lifetime, current algorithm, who
  changes it and in what window**. Without those five columns it is not an inventory, it is a list.

## 5. How it is deployed today (real, verifiable state)

### Published and pending standards

- **Published on 13 Aug 2024, effective 14 Aug 2024** (Federal Register,
  89 FR / issuance announcement): **FIPS 203 — Module-Lattice-Based Key-Encapsulation Mechanism
  Standard (ML-KEM**, from CRYSTALS-Kyber), **FIPS 204 — Module-Lattice-Based Digital Signature
  Standard (ML-DSA**, from CRYSTALS-Dilithium) and **FIPS 205 — Stateless Hash-Based Digital
  Signature Standard (SLH-DSA**, from SPHINCS+). The same day the CMVP updated **SP 800-140C**
  (FIPS 204/205 as approved signature methods) and **SP 800-140D** (FIPS 203 as an approved
  KEM) — a datum that matters if you have a FIPS 140-3 requirement.
- **FIPS 206 (FN-DSA**, from FALCON): **still not a final standard as of August 2026**. NIST
  submitted the draft for approval on 28 Aug 2025 and at the PQC standardisation conference of
  Sep 2025 it was listed as "still under development"; final is expected between late 2026 and
  2027. Reason for the delay: the signature's floating-point Gaussian sampling is hard to
  implement in constant time. **Do not pin it in a design until the final exists.**
- **HQC**: selected on **11 Mar 2025** as a **diversification** KEM (code-based, not
  lattice-based), as plan B if lattices fall. FIPS expected around 2027.
  **It is not a replacement for ML-KEM nor a reason to wait.**
- Names: **always use the FIPS names** (ML-KEM, ML-DSA, SLH-DSA). "Kyber" and "Dilithium"
  designate the **pre-standard** versions, incompatible on the wire with the final ones — the
  TLS code point change from `0x6399` to `0x11EC` exists for exactly that reason.

### TLS

- The de facto hybrid is **`X25519MLKEM768`**, IANA code point **4588 = 0x11EC**
  (`draft-ietf-tls-ecdhe-mlkem`), over **TLS 1.3**. It replaced `X25519Kyber768Draft00`
  (`0x6399`), which is **retired** — if your inventory finds it, that is debt, not PQC.
- Real client deployment, verified: Chrome 124 (Apr 2024) enabled the pre-standard by default
  and **Chrome 131 (Nov 2024) switched to `X25519MLKEM768`**; Edge followed via
  Chromium; **Firefox 132** by default on HTTPS and **135** on QUIC/HTTP-3; Apple added it in
  macOS Tahoe 26 / iOS 26 (autumn 2025). Go retired `x25519Kyber768Draft00` and uses
  `X25519MLKEM768` by default in `crypto/tls`.
- Adoption measured at Cloudflare: **~2 % in early 2024 → ~38 % in Mar 2025 → >50 % of
  human traffic in Oct 2025 → >60 % of PQ-capable client traffic in Feb 2026** (Cloudflare
  Radar); a 2026 study measures **57.4 %** of browser-initiated connections with a
  `X25519MLKEM768` *key share* — the difference is the measurement base, not a contradiction.
  **Cite the source and the date or do not use the figure (§8).**
- **The origin lags far behind**: ~10 % on the origin server side in early 2026,
  after Akamai turned it on by default in Jan 2026. Operational conclusion: **the browser is no longer
  your problem; your origin, your load balancers and your internal services are**.
- A side effect to know about before "fixing it": the ~1,088-1,216-byte *key share*
  is already used as a **bot detection signal**. A client claiming to be a modern
  browser that does not offer `X25519MLKEM768` stands out. If you disable PQC "for compatibility", you are
  changing your fingerprint.

### SSH, IKEv2/IPsec and the rest

- **SSH**: OpenSSH negotiates hybrid **by default since 10.0** (`mlkem768x25519-sha256`; 9.9
  introduced it; **10.1 warns when the KEX is not post-quantum**). Pin
  `KexAlgorithms mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com` where both
  ends can reach it. **Verify versions before pinning them (§8).**
- **IKEv2/IPsec**: **RFC 9370** (additional key exchanges, `ke1..ke7`) allows adding
  a PQC KEM on top of the classical DH — a `ke1_mlkem768`-style proposal in strongSwan. Interim
  measure when the other end cannot get there: **RFC 8784** (post-quantum preshared key mixed
  into the derivation). Tunnel operation and its config belong to `vpn-standards`.
- **WireGuard** does not negotiate: its optional PSK (`PresharedKey`) gives symmetric HNDL resistance; its
  own PQC path is external layers such as Rosenpass. Verify status before promising.
- **Files and backups**: `age` added hybrid `mlkem768x25519` recipients in the
  1.1.x series — verify version and recipient compatibility before encrypting with them anything
  you have to decrypt ten years from now.
- **KMS/HSM**: AWS KMS offers ML-DSA in validated HSMs (GA since 2025-06-13), Google Cloud KMS
  took ML-DSA, SLH-DSA and ML-KEM to GA, and Azure Key Vault/Managed HSM was lagging in 2026.
  **Availability by region and by service tier: verify it before designing (§8).**

## 6. Signatures: size, chains and why it hurts differently

- Encryption is migrated by changing a group in the handshake; **the signature changes the format of everything
  signed**. A certificate, a chain, a firmware image and a token all grow at once.
- **Sizes, verbatim from the official tables** (FIPS 203 Table 3, FIPS 204 Table 2,
  FIPS 205 Table 2), in bytes. Compare them with the 32 B of an X25519 key and the 64 B of an
  Ed25519 signature:

  | Parameter | Public key | Private key | Ciphertext / Signature |
  |---|---|---|---|
  | ML-KEM-512 | 800 | 1,632 | 768 (ct) |
  | **ML-KEM-768** | **1,184** | 2,400 | **1,088** (ct) |
  | ML-KEM-1024 | 1,568 | 3,168 | 1,568 (ct) |
  | ML-DSA-44 | 1,312 | 2,560 | 2,420 (sig) |
  | **ML-DSA-65** | **1,952** | 4,032 | **3,309** (sig) |
  | ML-DSA-87 | 2,592 | 4,896 | 4,627 (sig) |
  | SLH-DSA-128s / 128f | 32 | — | **7,856** / **17,088** (sig) |
  | SLH-DSA-192s / 192f | 48 | — | 16,224 / 35,664 (sig) |
  | SLH-DSA-256s / 256f | 64 | — | 29,792 / **49,856** (sig) |

  Reading: ML-KEM adds ~1 KB per side to the handshake and is bearable; **ML-DSA multiplies the
  signature by ~30-50× versus Ed25519**; **SLH-DSA reaches ~50 KB per signature** — tiny public key,
  huge signature and slow signing, in exchange for resting on hashes alone. The `s` variant
  optimises size and `f` speed: choosing wrong doubles the problem.
- Concrete consequences to size up **before** migrating:
  - **Certificate chain**: a PQC chain can go from ~4 KB to tens of KB. The
    ClientHello/ServerHello stops fitting in the initial packets, extra *round trips* appear
    and **amplification** in QUIC. Measure real latency, not just bytes.
  - **Firmware and boot**: devices with scarce flash and RAM, and with a large public key
    burnt into ROM that cannot be changed. If the *root of trust* is not updatable, **the
    signature decision is taken now and for the whole life of the product** — and that is why this is the
    only front where the signature comes before encryption.
  - **Tokens and JOSE/COSE**: an ML-DSA signature in a cookie or header can blow up size limits
    of proxies and browsers. Verify the limit beforehand, not in production.
- **Crypto-agility is the real deliverable.** Design as if the algorithm were going to
  change twice more:
  - **Algorithm identifier and key version as metadata alongside the data/artifact**,
    never implicit.
  - All crypto **behind your own interface**; no calling the primitive from 40
    places. The measure of agility is: *how many files do I touch to change algorithm?*
  - **Negotiation, not a fixed algorithm in the protocol**; and the ability to **disable** an
    algorithm by configuration without recompiling or redeploying.
  - Test agility **by exercising it**: an algorithm rotation drill, just like a
    restore drill. An unrehearsed agility does not exist.

## 7. Timeline, sustainability and prohibitions

- **NIST IR 8547 — "Transition to Post-Quantum Cryptography Standards"**: as of August 2026
  it was still an **initial public draft (IPD, 12 Nov 2024)**, with the comment period
  closed on 10 Jan 2025 and a planning note of 21 Jan 2025 — **there is no confirmed final version;
  do not cite it as settled law**. Its proposed timeline: RSA, ECDSA, ECDH,
  DSA and FFDH **deprecated after 2030** and **disallowed after 2035**, including the large
  sizes (RSA-3072, P-384). Correct reading: **2030 is not a migration end date**, it is the
  date from which continuing to use them requires risk analysis and documented justification
  from the data owner; 2035 removes that option. **Hybrid modes do not fall under the
  2035 prohibition** — that is what makes the phased approach viable. AES-256, SHA-2 and
  SHA-3 are **not** on that timeline.
- **SP 800-131A**: the current final revision is **Rev. 2 (2019)**; **Rev. 3 is in
  initial public draft (Oct 2024)**, raises the minimum from 112 to 128 bits of strength and merges
  the asymmetric transition with the post-quantum one. Verify whether it has been finalised (§8).
- **CNSA 2.0 (NSA, for National Security Systems only)** — timeline by category,
  cross-checked in agreeing secondary sources; **I could not download the original NSA
  PDF (403 from `media.defense.gov`): declared gap in §8, verify it against the original
  before committing to it in a contract**:

  | Category | *Support and prefer* | *Exclusively use* |
  |---|---|---|
  | Software and firmware signing | 2025 (start immediately) | **2030** |
  | Web browsers/servers and cloud services | 2025 | 2033 |
  | Traditional networking equipment (VPN, routers) | 2026 | **2030** |
  | Operating systems | 2027 | 2033 |
  | Niche equipment (constrained devices, large PKIs) | 2030 | 2033 |
  | Custom applications and legacy equipment | — | Update or replace by 2033 |

  CNSA 2.0 algorithms: **ML-KEM-1024**, **ML-DSA-87**, AES-256, SHA-384/SHA-512 and **LMS or
  XMSS (SP 800-208)** for software and firmware signing. The date that really bites is not
  any of those in the table: **from 1 Jan 2027 every new NSS acquisition is expected to be
  CNSA 2.0 compliant**. FAQ v2.1 (Dec 2024) **excludes SLH-DSA from use in NSS**, forbids
  HashML-DSA, excludes HSS and XMSS^MT and rules out FN-DSA — **verify it against the original
  document: it is exactly the kind of detail that gets misquoted**. And note: **CNSA 2.0 does not apply to
  anyone who does not operate NSS**; using it as an excuse to demand ML-KEM-1024 on a commercial website is
  over-engineering.
- **Public CAs and the CA/Browser Forum — the asymmetry that defines 2026**: **key
  exchange** is already post-quantum on most traffic, but **the server certificate
  is still ECDSA P-256 or RSA-2048**. State verified as of August 2026:
  - **S/MIME first**: ballot **SMC013** (Jul 2025) introduced ML-DSA and ML-KEM into the
    S/MIME Baseline Requirements, with **non-hybrid** PQC certificates, for experimentation.
  - **TLS not yet**: the Server Certificate WG keeps a PQC ballot *tracker* and a
    proposal "SC0XX: Allow ML-DSA", but **as of May 2026 there was no baseline requirement
    permitting ML-DSA in publicly trusted certificates** (SCWG minutes of 21 May 2026:
    disagreement on whether traditional X.509 should be part of the transition, doubts about
    the CT logs, ballot pending a rewrite). Microsoft maintains a **pilot of ML-DSA roots
    for testing only**; Chrome announced support for ML-DSA anchors for **private PKI**
    in TLS 1.3 from Chrome 150. **No public ML-DSA root chains to the stores
    of Mozilla, Apple, Microsoft or Chrome**, and a Jun 2026 study of 32,011 domains
    measured **0 % adoption** of post-quantum hybrid certificates.
  - **The chosen path is not changing the signature, it is changing the format**: **Merkle Tree
    Certificates (MTC)**. Let's Encrypt published its roadmap on **3 Jun 2026** (*staging* environment
    issuing MTC by late 2026, production in 2027), Chrome declared them its
    preferred route for the public web and Cloudflare runs an experiment with real traffic; the
    work is in the IETF **PLANTS** WG. **Reason**: a naive signature change would push
    the HTTPS handshake above **10 KB**, which breaks on the order of **5 %** of
    connections on real networks. Collateral pressure: SC-081 cuts the maximum certificate
    validity in phases, which favours amortising a PQ signature across many certificates
    (the SC-081 timeline is set by `cryptography-pki-standards`; **verify the current phase**).
  - **Available today for private PKI**: ML-DSA in DigiCert Private CA, AWS Private CA (GA
    since Nov 2025) and OpenSSL 3.5 with the OQS provider. **Planning consequence: your
    internal PKI can migrate signatures now; your public chain does not depend on you.**
- **Cadence**: review the PQC plan **every six months** for as long as the transition lasts and regenerate
  the CBOM on every release. Every exception (a third party that cannot get there, a device that cannot be
  updated) carries an exit date, an owner and a ticket.

**FORBIDDEN**
- ❌ Writing a deprecation or prohibition date **from memory**. A misquoted year
  shifts a multi-year plan and a budget.
- ❌ Citing NIST IR 8547 as a final standard while it remains a draft, or presenting 2030 as
  a "migration deadline".
- ❌ Deploying ML-KEM **without a classical component** in production during the transition: if
  a lattice weakness appears, the hybrid saves you and the pure one does not.
- ❌ Pinning FN-DSA/FIPS 206 or HQC in a design before the final standard exists.
- ❌ Using `Kyber`/`X25519Kyber768Draft00` (`0x6399`) or any pre-standard variant in
  production, or treating them as equivalent to the final ones.
- ❌ Implementing a PQC algorithm yourself. The rule from
  `cryptography-pki-standards` still holds: **FORBIDDEN to implement your own primitives**, and here more so,
  because side-channel attacks on lattices are an active field.
- ❌ Migrating without an inventory or CBOM, or prioritising by system instead of by data lifetime.
- ❌ *Stateful* keys (LMS/XMSS) without strict index control: reusing an index
  **breaks** the scheme, it does not degrade it.
- ❌ Selling "quantum-safe" or "quantum-proof" without saying which concrete surface is migrated and
  measured. It is the most inflated claim in the industry.
- ❌ Buying QKD or "quantum crypto" as a substitute for PQC: they are different things, and several
  national agencies advise against QKD for general use — verify their current position
  before spending (§8).
- ❌ Demanding CNSA 2.0 parameters on systems that are not National Security Systems "just in
  case".

## 8. Mandatory web verification

Before pinning an algorithm, date, figure or state in a deliverable:

1. **NIST's CSRC**, publication by publication: FIPS 203/204/205 (final), **FIPS 206**
   (still a draft?), **HQC** (is there a FIPS yet?), **IR 8547** (IPD or final? exact dates
   of *deprecated*/*disallowed*), **SP 800-131A** (Rev. 2 or Rev. 3 final?) and SP 800-208.
   **Transition tables are quoted verbatim.**
2. **CNSA 2.0**: the NSA's **current advisory and FAQ**, with their version number and date.
   Timeline and exclusions (SLH-DSA, HashML-DSA, HSS/XMSS^MT, FN-DSA) **verbatim**.
3. **Sizes** of key, ciphertext and signature (§6): taken verbatim from FIPS 203 Table 3,
   FIPS 204 Table 2 and FIPS 205 Table 2 in this revision; re-check if the edition changes.
4. **TLS deployment state**: code point and exact group name, support by
   browser and by server, and **measured adoption with source and date** (Cloudflare Radar or
   another). Never a figure without an origin.
5. **Versions**: OpenSSH (hybrid KEX by default and non-PQ KEX warning), OpenSSL/AWS-LC/
   BoringSSL, strongSwan, Go, `age`, `liboqs`/`oqsprovider` and their open CVEs.
6. **PQC in your KMS/HSM**: algorithms, regions and FIPS 140-3 validation of the specific module in
   the CMVP, not the press release.
7. **Public CAs and the CA/Browser Forum**: state of the ML-DSA ballot in the TLS Baseline
   Requirements, progress of **Merkle Tree Certificates** (PLANTS WG, Let's Encrypt, Chrome) and
   what your CA supports today.
8. **CycloneDX/CBOM**: current version of the cryptographic assets schema.
9. **European regulators**: PQC roadmap from the Commission and from ENISA, and the guidance from ANSSI,
   BSI and CCN — they impose their own deadlines in public procurement.

**Declared gaps in this version** (close them before using the document in a real plan):
- The **original CNSA 2.0 PDF and the NSA FAQ could not be downloaded** (403 from
  `media.defense.gov`): the timeline and the exclusions come from agreeing secondary sources,
  **not from a verbatim quote of the original**.
- Final state of **FIPS 206**, of **HQC** and of **SP 800-131A Rev. 3**: verified as
  pending as of August 2026 via secondary sources; confirm against CSRC.
- The **versions of OpenSSH, `age`, AWS/Google/Azure KMS** in §5 are inherited from
  `cryptography-pki-standards` (verified there); re-confirm them before pinning them.

Already **closed in this revision** (do not repeat the work): FIPS 203/204/205 sizes taken
verbatim from the official tables, and the state of the CA/Browser Forum and of Merkle Tree Certificates.

If the web contradicts this document, **the web wins** — flag the discrepancy.
