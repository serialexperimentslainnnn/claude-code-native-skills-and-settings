---
name: cryptography-pki-standards
description: Applied cryptography and PKI standards. Use when choosing algorithms or modes (AES-GCM, ChaCha20-Poly1305, Ed25519, RSA-PSS), Argon2id password hashing, TLS 1.3 config, testssl.sh, ACME/Let's Encrypt, step-ca, cert-manager, mTLS, HSM/KMS key rotation, cosign/GPG signing, crypto agility and CBOM inventory.
---

# Applied cryptography and PKI standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when choosing, implementing or reviewing: algorithms and modes (AEAD, encryption at rest,
signing), key derivation and password hashing, randomness generation, nonce/IV
management, digital signatures and JOSE/COSE formats, TLS configuration and its verification,
certificate lifecycle and ACME automation (Let's Encrypt, step-ca, cert-manager,
DNS-01 challenge), internal PKI design and CA hierarchy, mTLS and pinning, key management
with HSM/KMS (envelope encryption, wrapping, rotation, custody), code and artifact
signing, backup encryption, and post-quantum inventory and migration.

**Not applicable**: see `post-quantum-crypto-standards` (**critical boundary**: the PKI, the
certificate lifecycle and classical crypto are decided **here**; **the whole post-quantum transition
is theirs** — the status of FIPS 203/204/205/206 and HQC, the NIST IR 8547 and CNSA 2.0 timelines,
hybrids in TLS/SSH/IPsec and the migration order by data type. If the question carries a migration
date or the name of a PQC algorithm, the other one governs), `networking-standards` (TLS termination
at the edge, proxies, WireGuard, DNSSEC), `kubernetes-standards` (deploying cert-manager and
signature verification in admission), `cicd-standards` (artifact signing inside the pipeline and the
runner's OIDC), `identity-access-management-standards` (tokens, sessions and authentication policy),
`appsec-standards` (insecure crypto use found in code review),
`secrets-management-standards` (storage and distribution of already-generated
secrets), `assembly-standards` (**critical boundary**: the choice of algorithm,
curve, mode, key size and the whole key lifecycle is decided **here**; there, only the
constant-time **implementation** —no branches or memory accesses dependent on the secret— and
the erasure of secrets the compiler cannot optimise away. The rule both repeat and which admits
no exception: **FORBIDDEN to implement your own cryptography**; an audited library is used, and
if someone is writing cryptographic assembly, the prior question is why),
`solidity-standards` (the use of the primitives the chain already exposes —signature
verification, EIP-712, `ecrecover` and its malleability— is theirs; the choice and custody of the
keys, here), `govtech-eidas-standards` (**the eIDAS regime is theirs**: advanced versus qualified
electronic signature, qualified trust service provider and trusted lists, qualified time stamp,
AdES formats and their long-term preservation, and what evidential value each one has. **Here the
cryptography underneath** —algorithm, curve, HSM custody, chain and revocation—; the
rule that avoids the expensive mistake: **a technically valid signature is not a qualified
signature**, and that is decided by their framework, not by the algorithm).

## 2. Default decisions

> Verify the latest version on the web before committing to it in a real project (§8). The
> PQC migration dates and the maximum certificate lifetime changed in 2025-2026: do not
> state them from memory.

| Need | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Authenticated symmetric encryption | **AES-256-GCM** (managed nonce) or **ChaCha20-Poly1305** (no AES-NI) | **AES-GCM-SIV** (RFC 8452) or **AES-SIV** (RFC 5297) if the nonce cannot be guaranteed unique; XChaCha20-Poly1305 with a random nonce | ECB, CBC/CTR without a MAC, DES/3DES, RC4, Blowfish |
| Encryption with a low-entropy key (password/PSK) | An AEAD **with key commitment** or a construction that binds the key to the ciphertext | A strong KDF + a standard AEAD, documenting the risk | Plain AES-GCM/ChaCha20-Poly1305 (they are not key-committing) |
| Password hashing | **Argon2id** | scrypt; bcrypt in legacy; **PBKDF2-HMAC-SHA-256** if FIPS is required | MD5, SHA-1, "salted" SHA-256, home-made hashing |
| General-purpose hash | **SHA-256/SHA-512** or SHA-3/BLAKE2-3 | — | MD5, SHA-1 (not even in "checksums", they end up being used as security) |
| Digital signature | **Ed25519** (RFC 8032) | ECDSA P-256 (with RFC 6979) if NIST/FIPS is required; **RSA-PSS** ≥3072 for legacy interoperability | RSA PKCS#1 v1.5 in new designs, RSA <3072, DSA |
| Transport | **TLS 1.3**; TLS 1.2 only with AEAD+PFS suites | mTLS with your own PKI for east-west | TLS 1.0/1.1 (RFC 8996), insecure renegotiation, suites without PFS |
| Public certificates | **Automated ACME** (Let's Encrypt or another ACME CA) | A commercial CA when a third party requires it | Manual issuance, self-signed on public surfaces |
| Internal PKI | **step-ca** or the provider's managed CA; **cert-manager** in Kubernetes | Your own offline CA with an HSM for the root | Reusing the internal CA for public TLS; a CA with no revocation plan |
| Key custody | **KMS/HSM** (FIPS 140-3) with envelope encryption | A file encrypted with a key in the KMS, if there is no HSM | Keys in repos, images, environment variables in the clear or in the same backup as the data |
| Artifact signing | **Sigstore/cosign keyless** (the CI's OIDC, a transparency log) | minisign/`age` + SSH signing in small environments; GPG only for an external requirement | Unsigned artifacts on the path to production |
| File/backup encryption | **age** (or the native encryption of restic/kopia/borg) | GPG only for inherited interoperability | "Password-protected" ZIP, home-made encryption |

## 3. Structure and conventions

### AEAD, nonces and real limits

- **Never reuse a nonce with the same key**: in AES-GCM and ChaCha20-Poly1305, repetition
  does not degrade, it **breaks** things (recovery of the authenticator and of the plaintext).
- AES-GCM uses a 96-bit nonce: with **random** nonces, the practical limit is of the order
  of **2³² messages per key** (a birthday bound; SP 800-38D and FIPS 140-3 IG C.H
  additionally restrict how the nonce is generated). With a deterministic counter partitioned per
  sender, the ceiling is much higher — but it requires reliable state.
- If you cannot guarantee uniqueness: **AES-GCM-SIV / AES-SIV** (nonce-misuse resistant)
  or nonce extension (XChaCha20-Poly1305; constructions such as XAES-256-GCM or
  DNDK-GCM, still in CFRG draft — verify their status before depending on them).
- **Key commitment**: the standard AEADs are not key-committing. When the key derives
  from a password or a low-entropy PSK, or when the receiver tries several keys,
  *partitioning oracles* appear (USENIX Security '21) that allow recovering the key. Use an AEAD
  with commitment or explicitly bind the key (a hash of the key in the AAD).
- The AAD is not optional: put the context in it (tenant, schema version, object id)
  so a ciphertext is not reusable in another context.

### Password hashing (parameters, not "use bcrypt")

OWASP minimums (August 2026) — **they rise with hardware, re-verify (§8)**:

| Algorithm | Minimum parameters | Note |
|---|---|---|
| Argon2id | `m=19 MiB, t=2, p=1` (or equivalents: `m=12 MiB, t=3`…) | Tune **upwards** to ~250-500 ms of verification; RFC 9106 recommends considerably larger configurations |
| scrypt | `N=2^17, r=8, p=1` | The second option if there is no Argon2id |
| bcrypt | cost ≥ **10**, a **72-byte** limit | Pre-hash with SHA-256 (+base64) if you accept long passwords |
| PBKDF2 | ≥ **600,000** iterations with HMAC-SHA-256 | Only for a FIPS requirement |

- A unique salt per password (the library generates it). A **pepper** optionally in the KMS/HSM, as
  defence in depth, never as a substitute.
- Transparent rehashing when parameters are raised: it is detected at login and updated.
- Constant-time comparison in everything that compares secrets (tokens, HMACs, hashes).

### Randomness

- The system source **always**: `getrandom(2)`/`getentropy`, `/dev/urandom`,
  `BCryptGenRandom`, or the language's cryptographic wrapper (`secrets` in Python,
  `crypto/rand` in Go, `crypto.randomBytes`/`getRandomValues`, `SecureRandom`).
- **FORBIDDEN** for any value with a security function: `Math.random()`, `rand()`,
  `java.util.Random`, Python's `random` module, PRNGs seeded with the time or the PID.
- Careful with cloned VMs, containers and golden images: entropy and PRNG state get
  duplicated; guarantee a reseed at boot.

### Signatures and JOSE

- Ed25519 by default; ECDSA P-256 if the ecosystem requires it (with a deterministic signature or a
  correct RNG: a repeated `k` nonce reveals the private key); RSA-PSS rather than PKCS#1 v1.5.
- JOSE/JWT (RFC 8725): `alg` against the **verifier's allowlist**, never the token's;
  `none` forbidden; accepting HMAC where you expect asymmetric is forbidden (algorithm
  confusion); `kid` validated against the known JWKS; explicit `typ`.
- Commit/tag signing: SSH signing (`gpg.format = ssh`) with a versioned `allowed_signers`,
  or GPG if the process already requires it. Verification is done in CI, not "by eye".

### PKI: hierarchy and lifecycle

- **An offline root** (an HSM or split material), intermediates **by purpose** (server TLS,
  client mTLS, code signing) and **short-lived** leaves. A CA that issues everything is a
  single point of compromise.
- Restrict: minimal `keyUsage`/`extendedKeyUsage`, `nameConstraints` on the internal
  intermediates, a correct SAN (the CN is decorative), no wildcards shared between services.
- **Automation or there is no PKI**: ACME (step-ca, cert-manager, `certbot`/`lego`) with
  unattended renewal and a margin ≥ 1/3 of the certificate's lifetime. DNS-01 for wildcards and
  internal hosts, with **least-privilege** DNS credentials (delegate only
  `_acme-challenge` to a zone of your own).
- The maximum lifetime of public TLS certificates is being **reduced in phases** (the CA/Browser
  Forum's ballot SC-081, with milestones down to 47 days and a parallel reduction in domain
  validation reuse). **Verify the current timeline and figures (§8)**; the
  design consequence does not change: 100% automatic renewal with no human in the path.
- Revocation: CRL/OCSP have irregular delivery and adoption → the real defence is a **short
  lifetime + fast reissuance**. The mandatory operational question: if your CA revokes within 24 h
  (a Baseline Requirements obligation in incidents), can you reissue and deploy across the whole
  fleet in 24 h? If not, you have a latent incident.
- Monitor **Certificate Transparency** for your domains: it detects mis-issuance without the
  risks of pinning.

### mTLS and pinning

- Identity in the SAN (a SPIFFE or DNS URI), **full** chain validation against your CA
  (not against the system trust store) and automatic rotation of the leaves.
- **HPKP is dead** (removed from the browsers). If you pin in a native app: pin **public
  keys**, with a **pinset and backup pins**, only your own endpoints, with a **remote kill
  switch** and rotation monitoring. A pin with no rollback plan is a scheduled brick: the app
  store's review cycle is slower than any emergency rotation.
- Never pin third-party endpoints you do not control.

### Key management

- **Envelope encryption**: a DEK per object/tenant, wrapped by a KEK that lives in the KMS/HSM.
  Wrapping with AES-KW (RFC 3394) or an AEAD; never "encrypt the key with the same key".
- An explicit crypto-period per key and **tested rotation**: a key version identifier
  alongside the ciphertext so the KEK can be rotated without re-encrypting the whole corpus.
- Separation of duties: whoever administers the KMS does not decrypt data; every operation with a
  root key is audited and under dual control.
- Root custody: Shamir/quorum or split physical custody, with a **rehearsed** recovery
  procedure.
- Backups: encryption with a key that does **not** live in the backed-up system, immutable
  copies (Object Lock / an append-only repository) and a tested restore. `age` (v1.1.x already
  incorporates hybrid post-quantum recipients `mlkem768x25519` and `age-inspect`) or the native
  encryption of restic (0.18.x, zstd by default since 0.14), kopia or borg.

### Post-quantum — **ceded to `post-quantum-crypto-standards`**

The whole transition lives there: the real status of FIPS 203/204/205/206 and HQC, the timelines of
NIST IR 8547 and CNSA 2.0 with their provenance, hybrids in TLS/SSH/IPsec with code point and
support by version, key and signature sizes, and the migration order by data type.
**Do not duplicate any of those dates here**: they expire and they diverge.

What does remain this skill's business, because it is applied crypto and not transition:

- **Cryptographic agility** as a design requirement: algorithm and key version as
  metadata of the encrypted data, an isolated crypto layer behind an interface, and a **CBOM**
  (CycloneDX 1.6 = ECMA-424 introduced cryptographic assets; 1.7 refines them) generated in
  CI to know which algorithms you actually use. Without an inventory there is no migration — and the
  inventory is built with this skill's tools and exploited with the other one's.
- Backup encryption with a key that does not live in the backed-up system: `age` (v1.1.x already
  incorporates hybrid `mlkem768x25519` recipients) or the native encryption of restic/kopia/borg.

## 4. Quality and testing (CI gates)

1. **Crypto linters**: `gosec`/`bandit`/`semgrep`/language analyser rules
   for MD5/SHA-1/DES/ECB, `InsecureSkipVerify`/`verify=False`, hardcoded keys and non-cryptographic
   PRNGs. They break the build.
2. **Secret/key scanning** (the specific scanner and its licence are set by
   `secrets-management-standards`; verify before committing to it): a private key or CA material in
   the repo = a broken build and immediate rotation, not a TODO.
3. **Known-answer tests (KAT)** for any code that touches crypto of its own, plus negative
   tests: a corrupted tag, a detected repeated nonce, an expired certificate, an incomplete
   chain, a hostname that does not match, a tampered `alg`.
4. **TLS scanning** (`testssl.sh` or `sslyze`) against staging on every release and against
   production on a schedule: versions, suites, chain, OCSP stapling, HSTS.
5. **Expiry monitoring** as an operational test: an alert with a margin ≥ 3× the renewal
   cycle, and fail the pipeline if a managed certificate was not renewed in time.
6. **Signature verification** at deployment: an artifact without a valid signature is not installed
   (the pipeline detail is in `cicd-standards`, admission in `kubernetes-standards`).

## 5. Security

- **Forbidden to implement your own primitives.** Use the maintained cryptographic library of
  your platform (libsodium, the language's stdlib, OpenSSL/AWS-LC via a high-level
  wrapper). "Rolling your own crypto" includes composing an AEAD by hand, inventing padding or
  chaining hashes.
- Side channels: constant-time comparison, care with the cache and with distinguishable
  error messages (padding/MAC oracles). Decryption errors are **one single** generic
  error.
- Do not leak into logs keys, IVs/nonces alongside the ciphertext without control, nor fragments of
  sensitive material; exception dumps are an exfiltration channel.
- Private key files: `0600` permissions, a dedicated owner, outside the container image
  and outside the backup of the system they protect.
- Strict validation of the certificate/hostname pair in **every** client (SDKs included);
  disabling verification "temporarily" is a finding, even in development.
- Cryptographic dependencies: follow the CVEs of the TLS/crypto library in use and its support
  cycle (LTS vs non-LTS) — it is the component with the least tolerance for unpatched versions.
- Compliance: FIPS 140-3 replaces 140-2; the 140-2 certificates move to **Historical
  on 21-Sep-2026** (the systems keep working, but they stop counting for new
  federal acquisitions). If there is a requirement, verify the specific module in the CMVP, not the
  vendor's marketing claim.

## 6. Operability

- **Renewal is a service, not a task**: unattended ACME, process reload with no
  downtime (`nginx -s reload`, hot reload of the binary), and a periodic test that the reload
  really picks up the new certificate.
- The CA's rate limits (Let's Encrypt and equivalents) accounted for in the design: staging
  for tests, do not issue for every ephemeral deployment.
- Performance: TLS 1.3 with session resumption (careful with `0-RTT`: only for idempotent
  requests), OCSP stapling, and hardware acceleration where it exists. Software encryption
  is rarely the bottleneck; the **handshake** is.
- HSM/KMS: latency and the operations-per-second limit are plannable capacity (and
  cost). Cache unwrapped DEKs in memory with a TTL, never persist them in the clear.
- Observability: certificate expiry metrics, handshake failures by cause,
  negotiated version/suite, KMS errors and the renewal rate. Alert on symptoms
  (failed handshakes rising), not only on expiry.
- The clock: certificate validation depends on time. Reliable, monitored NTP; a clock
  drift presents itself as "TLS broken for no reason".

## 7. Sustainability and prohibitions

- **Cadence**: review password hashing parameters and TLS configuration at least
  annually (they rise with hardware) and the PQC plan **every six months** while the
  transition lasts. The reduction of certificate lifetimes forces a review of the automation each
  time a phase changes.
- Every exception (inherited RSA-2048, TLS 1.2 for an old client, GPG for a third party)
  carries an exit date and a ticket.
- Keep the **CBOM** alive, not as an annual export: it is the migration's work list.

**FORBIDDEN**
- ❌ MD5 and SHA-1 with a security function; DES/3DES, RC4, ECB mode.
- ❌ Encryption without authentication (bare CBC/CTR) and improvised MAC-then-encrypt.
- ❌ Reusing a nonce/IV with the same key; a predictable IV or a global counter with no partitioning.
- ❌ Passwords with a fast hash (salted SHA-256/512), home-made schemes or hand-rolled rounds.
- ❌ A non-cryptographic PRNG for keys, tokens, salts, nonces or identifiers.
- ❌ Private keys or CA material in repos, images, artifacts or logs.
- ❌ RSA <3072 in new keys; ECDSA with a dubious RNG; PKCS#1 v1.5 for signing in new designs.
- ❌ TLS 1.0/1.1, suites without PFS, `InsecureSkipVerify`/`verify=False`/`--no-check-certificate`.
- ❌ HPKP; pinning without backup pins, without a kill switch or over third-party endpoints.
- ❌ Certificates issued or renewed by hand in production; a wildcard shared between unrelated services.
- ❌ An online root CA, with no name constraints and no revocation plan; an internal CA used for public surfaces.
- ❌ Backups whose key lives in the backed-up system, or with no tested restore.
- ❌ Implementing your own cryptographic primitives.

### Quick review checklist

- [ ] Algorithm and mode from the §2 table; nonce with an explicit strategy and a documented per-key limit.
- [ ] Passwords with Argon2id (or a justified alternative) and parameters verified this year.
- [ ] System randomness for every secret; constant-time comparisons.
- [ ] TLS 1.3 verified with `testssl.sh`; certificates via ACME with automatic renewal and an expiry alert.
- [ ] PKI with an offline root, intermediates by purpose, `nameConstraints` and a 24 h reissuance plan.
- [ ] Keys in a KMS/HSM with envelope encryption, key version alongside the data and tested rotation.
- [ ] Artifacts signed and verified at deployment; private keys outside repos and images.
- [ ] A CBOM generated in CI and a PQC plan with verified dates.

## 8. Mandatory web verification

Before committing to an algorithm, version, date or parameter in a deliverable:

1. **NIST's PQC status**: FIPS 203/204/205 (and FIPS 206 / HQC), and the transition
   timeline of **NIST IR 8547** (RSA/ECC deprecation) and of **CNSA 2.0** by category.
2. **Maximum lifetime of public TLS certificates**: the current phase of the CA/Browser Forum's
   ballot SC-081 and the domain validation reuse periods.
3. **Hashing parameters** in the OWASP Password Storage Cheat Sheet (they change with
   hardware) and in the current revision of NIST SP 800-63B.
4. **Versions and EOL** of OpenSSL (or AWS-LC/BoringSSL), step-ca, cert-manager, `age`,
   restic/kopia/borg, cosign and `testssl.sh`, plus their open CVEs.
5. **Real support for PQC hybrids** in TLS (the exact group name, browsers, server)
   and in your KMS/HSM by region, before promising "quantum-safe".
6. **Your CA's news**: ACME profiles, ultra-short-lived certificates, changes in
   OCSP/CRL and rate limits.
7. **FIPS 140-3 validation** of the specific module in the CMVP if there is a compliance requirement.

If the web contradicts this document, **the web wins** — flag the discrepancy.
