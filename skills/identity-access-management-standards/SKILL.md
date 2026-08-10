---
name: identity-access-management-standards
description: Identity and access management standards. Use when working with OAuth 2.1/OIDC flows, PKCE, JWT or opaque tokens, SAML, Keycloak, Authentik, Authelia, Zitadel, Okta, passkeys/WebAuthn, MFA policy, SCIM provisioning, RBAC/ABAC/ReBAC engines (OpenFGA, SpiceDB, Cedar), SPIFFE/SPIRE workload identity, PAM/JIT elevation.
---

# Identity and access management (IAM) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, implementing or reviewing: OAuth 2.1/OIDC flows (`authorization_code`+PKCE,
`client_credentials`, device code, token exchange), token design and validation (JWT/opaque,
`aud`, `scope`, TTL, refresh rotation, revocation), SAML federation, deployment and
configuration of IdPs (Keycloak, Authentik, Authelia, Zitadel, FreeIPA, Entra ID, Okta,
Ory), passkeys/WebAuthn and MFA policy, SSO and SCIM provisioning, authorisation
models (RBAC/ABAC/ReBAC) and policy engines (OpenFGA, SpiceDB, Cedar, OPA), PAM and
just-in-time elevation, break-glass accounts, workload identity (SPIFFE/SPIRE,
OIDC federation towards cloud), session management and single logout, and the
joiner-mover-leaver cycle with access recertification.

**Not applicable**: see `aws-standards`/`azure-standards`/`gcp-standards` (the specific
provider's IAM: policies, roles, conditions, SCPs), `microservices-architecture-standards`
(mTLS/service mesh and context propagation between services), `appsec-standards` (authorisation
failures inside the application code: IDOR, broken access control),
`secrets-management-standards` (custody and rotation of static secrets),
`cryptography-pki-standards` (signature algorithms, JWKS at the cryptographic level, certificate
issuance), `cicd-standards` (configuration of the pipeline that consumes OIDC),
`windows-server-ad-standards` (the **directory** and the Windows platform: forest, GPO, Kerberos and
NTLM, Tier 0/PAW, gMSA/dMSA, `krbtgt`, AD CS — here, the modern federation and identity that sit
on top of it or replace it), `incident-response-forensics-standards` (mass revocation of
sessions and tokens during an identity compromise), `identity-threat-detection-standards`
(**the attack against identity, its detection and its response** —session theft, token abuse,
malicious OAuth consent, revocation as containment—; **here, identity architecture,
SSO, MFA and the account lifecycle**), `privacy-engineering-standards` (the personal
data the directory holds and its lifecycle).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8). This
> domain moved a lot in 2025-2026: do not pin versions or spec statuses from memory.

| Decision | Default | Justifiable alternative |
|---|---|---|
| Protocol | **OIDC over OAuth 2.1** (current profile: PKCE mandatory, no implicit, no ROPC) | SAML 2.0 **only** against SaaS that does not offer OIDC |
| Access token format | **JWT** profiled (RFC 9068) validated locally by the resource | **Opaque** token + introspection (RFC 7662) if immediate revocation is required |
| Confidential client authentication | `private_key_jwt` or mTLS (RFC 8705) | `client_secret_basic` only in legacy, rotated and in a secrets manager |
| Token binding | **DPoP** (RFC 9449) or mTLS-bound for high-value tokens | Plain bearer only on internal traffic with a short TTL |
| Authentication factor | **Passkey/WebAuthn** phishing-resistant | TOTP as a transition; SMS/voice/email OTP only for recovery, never on privileged accounts |
| Self-hosted IdP | **Keycloak** (maturity, SAML+OIDC, federation) | Authentik/Zitadel (DX, multi-tenant), Authelia (lightweight portal/forward-auth), FreeIPA only as directory+Kerberos |
| Authorisation engine | **RBAC** in the IdP + **ReBAC** (OpenFGA/SpiceDB) for per-object permissions | Cedar for verifiable embedded policies; OPA/Rego for the platform (admission/IaC), not for high-cardinality per-object authz |
| Provisioning | **SCIM 2.0** (RFC 7643/7644) from the IdP as the source | Directory/HR-driven sync (midPoint, Syncope) in organisations with formal IGA |
| Workload identity | **SPIFFE/SPIRE** (X.509-SVID for mTLS, JWT-SVID for APIs) | The provider's native OIDC federation (workload identity) — never static keys |
| Privileged access | **JIT with approval and recording** (Teleport, Boundary, the provider's PIM) | Bastion + short-lived SSH certificates |

## 3. Structure and conventions

### Flow by client type (there are no other options)

| Client | Flow | Non-negotiable requirements |
|---|---|---|
| Web with backend | `authorization_code` + PKCE | Authenticated confidential client; tokens **only** in the backend |
| SPA / browser | `authorization_code` + PKCE with a **BFF** | Session in an `HttpOnly` cookie; tokens out of the JS |
| Mobile / native | `authorization_code` + PKCE (RFC 8252) | Custom Tab / `ASWebAuthenticationSession`; redirect via claimed app link; **never** an embedded WebView |
| Service→service | `client_credentials` with `private_key_jwt`/mTLS | Better still: SPIFFE or OIDC federation with no secret |
| TV/CLI/IoT | Device authorization grant (RFC 8628) | Short `user_code`, short TTL, confirmation screen naming the resource |
| Delegation/downscope | Token exchange (RFC 8693) | Reduced scope and `aud`, never widened |

**Dead**: `implicit` (`response_type=token`) and ROPC (`password` grant) — removed in
OAuth 2.1 and discouraged by the security BCP (RFC 9700). If they show up in a design,
they are a finding, not an option.

### Token design

- `aud` mandatory and **verified by every resource**; a token valid for "everything" is a
  master key. `iss`, `exp`, `nbf`/`iat` validated; `alg` against an explicit allowlist
  (RFC 8725): forbidden to accept the token's `alg` without a list, and forbidden `none`.
- TTL: access **5-15 min**; refresh **rotating** with reuse detection (reusing a
  refresh revokes the whole family). On public clients rotation is not optional.
- Revocation (RFC 7009) + propagation via CAEP/SSF. Assume revoking a JWT takes no
  effect until `exp`: the TTL **is** your revocation latency, size it accordingly.
- Fine-grained `scope` named by resource+action (`invoices:read`), never `admin:all`
  nor wildcards. Per-object permissions do not live in the token: they are queried from the PDP.
- Authorisation claims in the token only if they are stable and low-cardinality; dynamic
  roles in the token = stale permissions for the whole TTL.

### Session and logout

- BFF session cookie: `__Host-` prefix, `HttpOnly`, `Secure`, `SameSite=Lax`
  (`Strict` if the flow allows it), without `Domain`. Rotation of the session identifier on
  authentication and on privilege elevation.
- Logout: **RP-Initiated Logout** (user trigger) + **Back-Channel Logout** (effective
  server to server). The four OIDC logout specs have been Final Specifications since
  September 2022; **Session Management 1.0** (iframe + polling) is useless under
  third-party cookie restrictions: do not use it as the only mechanism.
- Inactivity **and** absolute timeouts defined by risk level; re-authentication
  (`prompt=login`, `max_age`) before sensitive operations (payments, MFA change, credential
  enrolment).

### Passkeys and MFA policy

- Passkey/WebAuthn by default. WebAuthn **Level 3** was proposed to W3C Recommendation on
  20 Jul 2026 (CR of 26 May 2026); check its status before citing the version.
- NIST SP 800-63B-4: AAL2 must **offer** a phishing-resistant option; AAL3 requires a
  phishing-resistant authenticator with a **non-exportable** key → a synced passkey
  reaches AAL2 at most, and administrators need a device-bound key (FIDO2
  hardware) or certificate-based authentication.
- Attestation: do not require it in public applications (it pushes the user to worse methods,
  such as SMS OTP); in corporate fleets requiring device-bound is reasonable.
- Portability solved: FIDO **CXF** (format, Proposed Standard) and **CXP** (encrypted
  transport) already deployed on iOS and on Android 14+ with Play Services 26.21+. Provider
  lock-in is no longer an argument for not adopting passkeys.

### Authorisation

- **RBAC** for the organisational axis (roles per domain, not per person), **ABAC** for
  conditions (tenant, data sensitivity, time, network, device posture),
  **ReBAC** (Zanzibar model: OpenFGA, SpiceDB) when the real question is "what relationship
  does this subject have with this object?" (hierarchies, sharing, inheritance).
- Centralised PDP (decision) + PEP in every service (enforcement). **Deny by default**. The
  frontend hides options; **it does not authorise**.
- The authorisation model is versioned code with tests (§4) and its decision is auditable:
  subject, action, object, result, policy and policy version.
- Multi-tenant: the `tenant` is derived from the token/context, **never** from a request
  parameter.

### Workload identity and federation

- Between services: SPIFFE/SPIRE SVIDs (X.509 for mTLS, JWT-SVID for APIs). Zero
  long-lived static secrets between services.
- OIDC federation towards cloud (CI, K8s): **exact per-claim** conditions. In GitHub
  Actions use `repository_id`, `job_workflow_ref` and `environment`; a `sub` with a wildcard
  requires `StringLike` (with `StringEquals` a `*` is compared literally and never matches, which
  tends to get "fixed" by widening permissions).
- GitHub issues an **immutable subject claim** (numeric IDs with `@`) on repos created,
  renamed or transferred from **15 Jul 2026**: if `AssumeRoleWithWebIdentity` fails
  after a rename, the condition is fixed — the wildcard is **never** widened.

```jsonc
// Trust policy: the minimum acceptable (neither a wildcard sub, nor an absent sub)
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
    "token.actions.githubusercontent.com:repository_id": "123456789",
    "token.actions.githubusercontent.com:environment": "production"
  },
  "StringLike": {
    "token.actions.githubusercontent.com:job_workflow_ref": "org/infra-workflows/.github/workflows/deploy.yml@refs/heads/main"
  }
}
```

### Joiner-mover-leaver cycle

- Single source of truth (HR → IdP). Onboarding, change and **offboarding** propagated by SCIM the same
  day; deprovisioning does not wait for the quarterly cycle.
- Recertification: privileged access **quarterly**, the rest half-yearly or yearly, with
  evidence and effective revocation of whatever is not confirmed (ISO 27001:2022 A.5.15/A.5.16/A.5.17/
  **A.5.18**; NIST SP 800-53 AC-2/AC-5/AC-6).
- Service accounts: named owner, expiry, rotation and review; no shared human
  accounts.
- **Third-party SaaS/OAuth integrations**: inventory of connected apps, minimum scopes,
  periodic review and immediate revocation during an incident. In the UNC6395 campaign against
  Salesloft Drift OAuth tokens (8-18 Aug 2025, 700+ organisations) there was no malware nor
  MFA bypass: valid tokens and legitimate APIs were enough.

### PAM, JIT and break-glass

- **Zero standing access to production**: JIT elevation with approval, short window,
  recorded reason and session recording. Ephemeral credentials (SSH/DB certificates lasting
  minutes), not stored passwords.
- Break-glass: **≥2 accounts**, credentials under split/physical custody, an MFA method
  **different** from the usual one (FIDO2 or cert-based), excluded from conditional access
  policies but **not** exempt from the platform's mandatory MFA (Entra enforces it at the
  client application level, independently of CA exclusions), an alert on every
  use and **documented periodic testing**. An untested break-glass does not exist.

## 4. Quality and testing (CI gates)

1. **Negative token tests** (mandatory, they break the build): expired, foreign `aud`,
   invalid signature, tampered `alg` and `none`, different `iss`, unknown `kid`, replay of the
   `code`, missing PKCE or incorrect `code_verifier`, `redirect_uri` not an exact match,
   reused refresh (must revoke the family).
2. **Policy as code with tests**: OpenFGA/Cedar/OPA ship a test runner. Permit **and**
   deny cases, including cross-tenant. Policy without a test = policy not
   reviewed.
3. **Federated trust scanning**: a linter/policy that fails on a `sub` with a broad
   wildcard, an absent `sub`/`aud` condition, or `StringEquals` with `*` in trust policies.
4. **Secret scanning** of tokens and client secrets in repos and logs (the scanner is set by
   `secrets-management-standards`, as is the rotation procedure after the leak).
5. **Conformance** when implementing or parameterising an OP/RP: pass the OpenID
   Certification suites before exposing it, not after the incident.
6. **Deprovisioning test**: an integration test verifying that offboarding in the source
   of truth cuts access in the target systems.

## 5. Security

- Flow surface: `redirect_uri` with an **exact match** (no wildcards or
  suffixes), `state` and `nonce` verified, `iss` parameter in the response (RFC 9207) to
  avoid mix-up between several IdPs, PAR (RFC 9126) and/or JAR (RFC 9101) in high-risk
  profiles.
- **Consent phishing / device code phishing**: a consent screen naming the
  application and the data, **controlled** client registration (no open dynamic client
  registration), and an alert on new high-privilege consents.
- **Token theft**: a stolen bearer = access. Bind (DPoP/mTLS) what is valuable, short TTL,
  anomalous-use detection (geo/UA/volume) and propagated revocation.
- SAML (legacy only): validate the signature over the `Response` **and** the `Assertion`, `Audience`,
  `Recipient`, `Destination`, `InResponseTo`, `NotOnOrAfter`; reject unsigned assertions;
  watch for XML Signature Wrapping and canonicalisation; metadata and signing certificates
  rotated with overlap.
- User enumeration: uniform responses and timings in login, registration and recovery.
- Account recovery: it is the weak link of the entire MFA policy — treat it at the
  same level (do not fall back to SMS/email OTP to recover an account with a passkey).
- Passwords (where they exist): hashing and policy in `cryptography-pki-standards` and
  `appsec-standards`; here only the rule — no composition rules, no periodic
  expiry without a reason, with a check against breached lists.

## 6. Operability

- **Authentication events as first-class telemetry**: login ok/failed, MFA,
  method change, consents, token issuance/refresh/revocation, break-glass use
  and role changes. Logs kept intact and retained for forensics; alert on
  patterns (distributed brute force, MFA fatigue, break-glass use, credential enrolment on a
  privileged account).
- **JWKS**: cache per `kid` respecting the TTL, tolerance to rotation (publish the new key
  before signing with it, retire the old one afterwards), and do not hit the endpoint on every request.
  JWKS failure = **fail-closed**.
- **The IdP is a SPOF**: multi-AZ HA, capacity sized for the login peak, rehearsed DR
  and a degradation plan (what keeps working with the IdP down, and for how long).
- **SSF/CAEP** (SSF 1.0, CAEP 1.0 and RISC 1.0 approved as Final Specifications on
  2 Sep 2025; CAEP interoperability profile in final review until 25 Sep 2026) to
  propagate revocation and risk changes in real time between providers.
- Rate limiting and anti-automation protection on `/token`, `/authorize`, login and
  recovery.

## 7. Sustainability and prohibitions

- **Cadence**: review the IdP's version and CVEs at least quarterly; self-hosted IdPs and IGA
  systems receive critical advisories frequently (e.g. Apache Syncope published in
  July 2026 patches for six vulnerabilities, including the privilege escalation
  CVE-2026-62183, with no binary hotfixes: they force an upgrade or a recompile).
- Follow the specs' status, not memory: OAuth 2.1 **was still an Internet-Draft**
  (`draft-ietf-oauth-v2-1-15`, 2 Mar 2026) in August 2026, although its content is already
  enforceable via RFC 9700 and the RFCs it consolidates.
- Debt with a fixed deadline: every exception (legacy client with a static secret, SAML, TOTP on
  admins) carries a date and a ticket.

**FORBIDDEN**
- ❌ `implicit` and ROPC (`password` grant) in any new design.
- ❌ Tokens in `localStorage`/`sessionStorage` or in the URL; tokens in logs.
- ❌ `redirect_uri` with a wildcard or prefix/suffix matching.
- ❌ Accepting the token's `alg` without an allowlist; `alg: none`; not verifying `aud` or `iss`.
- ❌ Non-rotating refresh tokens on public clients; access tokens lasting hours or days.
- ❌ Long-lived static secrets between services or in CI (OIDC federation exists).
- ❌ Federated trust policies with a wildcard `sub` (`repo:org/*`, `:*`) or without a `sub` condition.
- ❌ Shared human accounts, permanent admins, and break-glass without periodic testing.
- ❌ SMS/voice/email OTP as a factor on privileged accounts.
- ❌ Authorisation decided in the frontend or duplicated ad-hoc in every service.
- ❌ Dynamic client registration open to the internet without control or review.
- ❌ Manual deprovisioning or deprovisioning deferred to the audit cycle.
- ❌ Syncing passwords between systems instead of federating identity.

### Quick review checklist

- [ ] Correct flow per client type, PKCE present, exact `redirect_uri`, `state`/`nonce` verified.
- [ ] Token with verified `aud`, `alg` on an allowlist, short TTL, rotating refresh, revocation with a plan.
- [ ] Phishing-resistant MFA; passkeys; admins with a device-bound key; recovery at the same level.
- [ ] Centralised authz, deny-by-default, tenant derived from the token, decisions audited and with tests.
- [ ] Workload identity without secrets; federated conditions by exact claim.
- [ ] SCIM with same-day deprovisioning; recertification with evidence; connected apps inventoried.
- [ ] JIT with approval and recording; break-glass ≥2 with independent MFA, alerted and tested.
- [ ] Auth events in the SIEM; JWKS cached and fail-closed; IdP with HA and rehearsed DR.

## 8. Mandatory web verification

Before pinning a version, spec status or behaviour in a deliverable:

1. **OAuth 2.1**: status in the IETF datatracker (is it still an Internet-Draft or already an RFC?) and
   the current revision; also the BCP for browser-based applications
   (`draft-ietf-oauth-browser-based-apps`) and FAPI 2.0 if it applies to the profile.
2. **Versions and EOL of your IdP** (Keycloak, Authentik, Authelia, Zitadel, FreeIPA, Ory) and
   its breaking changes in the latest major, plus open CVEs for the component.
3. **WebAuthn Level 3**: is it already a W3C Recommendation? Status of CXP/CXF and of real support in
   browsers and platforms.
4. **SSF/CAEP/IPSIE**: status of the interoperability profile and what your provider really
   supports (what is published ≠ what is implemented).
5. **Authorisation engines**: version and status of OpenFGA, SpiceDB, Cedar and OPA (syntax/major
   changes that break existing policies) and of SPIRE.
6. **Federated claim format** of the provider (GitHub, GitLab, K8s) before writing
   conditions: they change and break deployments.
7. **NIST SP 800-63B-4** and the current phishing-resistant MFA guidance, if there is a compliance
   requirement.

If the web contradicts this document, **the web wins** — flag the discrepancy.
