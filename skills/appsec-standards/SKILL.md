---
name: appsec-standards
description: Application security methodology. Use when threat modeling (STRIDE, abuse cases), reviewing code against OWASP Top 10 or ASVS, triaging IDOR/BOLA, SSRF, XSS, SQLi, SSTI, XXE, CSRF, CSP, deserialization or path traversal findings, or selecting SAST/DAST/SCA tools.
---

# Application security standards (AppSec)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, reviewing or auditing an application's security **as a discipline**: threat modelling, security requirements and acceptance criteria, identifying and triaging vulnerability classes in your own design and code, selecting and calibrating analysis tools (SAST/DAST/IAST/SCA) and the programme that sustains it (secure SDLC, security champions). Triggers: "threat modelling", "STRIDE", "attack tree", "abuse case", "OWASP Top 10", "ASVS", "security review", "IDOR", "BOLA", "SSRF", "XSS", "injection", "deserialisation", "CSP", "CORS", "mass assignment", "SAST false positive", "security acceptance criterion".

Governing principle: **a tool finds what it knows how to look for; the threat model finds what matters**. No static analyser detects broken authorisation, business logic abuse or a misplaced trust boundary (§4) — which is why the order is design → controls → automated verification, never the reverse.

**Not applicable**: see `vulnerability-management-standards` (for the lifecycle of third-party vulnerabilities: CVE, CVSS/EPSS/KEV, remediation SLAs, VEX, inventory), `cicd-standards` (for running the scanning gates in the pipeline, OIDC, signing and SBOM), `onprem-standards` (for executing patching and maintenance windows on servers), `linux-hardening-standards` (CIS baseline, auditd, OpenSCAP), `kubernetes-standards` (for image hardening and admission), `identity-access-management-standards` (for designing the identity provider: OAuth 2.1/OIDC flows, SAML, passkeys, SCIM, RBAC/ABAC/ReBAC policy engines — here only how the application **consumes and verifies** that identity and how it breaks), `microservices-architecture-standards` (for mTLS, identity propagation and authz between services), `offensive-security-standards` (the **authorised** offensive side: RoE, running the pentest/red team, the report and the retest — here the prevention and control of those same vulnerability classes; its findings come in through §4), `ctf-lab-standards` (training in an isolated lab), `sre-practice-standards` (for incident response and operating the telemetry), `iac-standards` and the cloud skills (for infrastructure controls), `grc-compliance-standards` (formal risk acceptance and the regulatory framework). **Stack-specific security** (APIs, sinks and concrete flags of each language) lives in §5 of the language's skill: `python-standards`, `typescript-standards`, `go-standards`, `rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`, `mobile-standards`, `c-standards` and `cpp-standards` (memory, integers and binary hardening), `sql-standards` (**how a query is built so that injection is impossible**: parameterisation, quoting of dynamic identifiers, generated versus hand-written SQL), `powershell-standards` (`ConvertTo-SecureString -AsPlainText`, execution policy, script signing, JEA) and `solidity-standards` (**vulnerability classes specific to EVM contracts**: reentrancy — including read-only reentrancy —, oracle manipulation, flash loans, storage collision in proxies, precision and rounding. The risk calculus is different from the rest of the catalogue: **deployed code is immutable, public and handles value**, so there is no patch and no rollback). `opensource-licensing-standards` (selecting SAST/DAST/SCA belongs here, but **whether the chosen tool is free, paid or *source-available* is decided by their policy** — the precedent that justifies it is that **Brakeman is not MIT but a proprietary licence requiring payment for commercial use**, despite being the default scanner of half the Ruby ecosystem). This skill is **methodology and vulnerability classes**, stack-agnostic: here it is decided **how a SQLi finding is triaged and tested**; there, **how the code is written so that it does not exist**.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8). The data below is from August 2026 and expires.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Verifiable requirements | **OWASP ASVS 5.0.0** (May 2025; next target, patch 5.0.1), **level L2** | L2 is the recommended baseline for business applications; L1 is a floor, not a goal; L3 only for high value or a regulated environment |
| Reference risk list | **OWASP Top 10:2025** (8th edition; announced Nov 2025, final Jan 2026) | Replaces 2021. Any rule, report or mapping still citing A10:2021 SSRF is out of date (§5) |
| APIs | **OWASP API Security Top 10 2023** | Still the current edition in 2026; there is no 2025/2026 edition |
| Control catalogue | **OWASP Proactive Controls v4 (2024)** | A constructive complement to the Top 10, which is descriptive and not prescriptive |
| Modelling method | **STRIDE** per element over a DFD + abuse cases; attack trees only for concrete high-value threats | Threat Modeling Manifesto: value over ceremony. PASTA if the driver is business risk; LINDDUN if it is privacy |
| Programme maturity | **OWASP SAMM v2** (Threat Assessment, Security Requirements, Secure Architecture) | A measurable improvement framework, not a certification or a checklist |
| SAST | **Semgrep** (readable, editable YAML rules, lightweight CLI, trivial CI integration) | **CodeQL** if you already use GitHub code scanning and want deep data-flow; SonarQube if you also need quality/coverage — its Community Build does **not** include taint analysis |
| DAST | **ZAP** (Apache-2.0, no paid tiers) | Mind the name: it left OWASP in 2023 (Linux Foundation / Software Security Project) and since Sept 2024 it is *ZAP by Checkmarx*; it remains OSS and governed by its core team |
| SCA | **OSV-Scanner** (Google) and/or **Grype**+Syft; Dependency-Track as a triage layer | See §6 on the Trivy supply-chain compromise (March 2026) before choosing it |
| IAST | **Not by default** | A very thin market, no mature OSS option, coverage limited to what the tests exercise and 2-5% overhead. Justify it or do not buy it |
| Human programme | **Volunteer security champions** (OWASP Security Champions Guide) | Assigning the role by decree does not work: it requires genuine interest and allocated time |

## 3. Threat modelling and secure SDLC

### When you model (not "once a year")
Mandatory **before writing code** for: a new system or service, a change of trust boundary (a new external integration, a new type of actor, a new data store), a change in authn/authz, and any new processing of personal or payment data. For everything else: **iterative and incremental** — you model the functionality added, not the whole system.

### The four questions (minimum framework)
1. **What are we building?** A DFD with processes, stores, flows and **trust boundaries drawn explicitly**. Without trust boundaries the diagram is documentation, not a model.
2. **What can go wrong?** STRIDE per element: Spoofing, Tampering, Repudiation, Information disclosure, Denial of service, Elevation of privilege. Complement it with **abuse cases** ("as an attacker, I want…") for business logic, which is exactly what textbook STRIDE does not cover.
3. **What are we doing about it?** Every threat closes with an explicit decision: **mitigate / transfer / eliminate / accept**. Accepting is valid and is documented with an owner and a review date; "pending" is not a decision.
4. **Did we do a good job?** Every agreed mitigation becomes a verifiable requirement and a test. A model whose mitigations never reach the backlog has served no purpose.

**Attack trees** only when they add something: the attacker's goal at the root, alternative paths in the branches, to reason about defence in depth for one concrete asset ("extract the customer database"). They do not replace STRIDE and are not done for everything.

### From threat to acceptance criterion
Stories carry **explicit, verifiable security acceptance criteria**, in the same format as the functional ones and in the same story, not in a separate document. Every criterion references the ASVS requirement with a **version prefix** (`v5.0.0-<chapter>.<section>.<requirement>`) and gets tested.

- ❌ Bad: "the endpoint must be secure".
- ✅ Good: "an authenticated user requesting `/invoices/{id}` from another tenant receives a 404 and an authz-denied event is logged with `user_id` and `resource_id`" — verifiable, testable, covers A01.

**Security Definition of Done** (in addition to the one in `CLAUDE.md`): the change's threats reviewed, security criteria proven by an automated test, gate findings resolved or with a registered exception, and no new secret in code, logs or history.

### Requirement traceability
ASVS numbering **is not stable between versions**: always cite with the prefix. ASVS 5.0 removed the mappings to CWE and NIST 800-63 (future alignment via CRE): if you need CWE traceability for an audit, you build and maintain it yourself.

## 4. Verification: gates, tools and triage

### Order of increasing cost (what breaks the build)
1. **Secret scanning** in pre-commit and in CI over the whole PR diff. A detected secret breaks the build **always** and triggers rotation: the secret is already burned even if the commit is rewritten.
2. **Incremental SAST** over the diff, not over the whole repository. It breaks on **new** high-severity findings; the inherited stock goes to the backlog with an owner and a date, not blocking every PR.
3. **SCA** of direct and transitive dependencies (triage of the resulting CVEs belongs to `vulnerability-management-standards`).
4. **DAST** against a deployed environment, nightly or pre-release: it is slow and needs the application running; it does not fit in every PR.
5. **Manual design and authorisation review** for sensitive changes. Irreplaceable, see below.

### Calibration: what to actually expect from the tools
The public data is humbling and the programme must be designed assuming it: in evaluations against real vulnerabilities the detection rates of leading tools sit in the 11-27% range individually and around 39% combining four, with very high false-positive rates on synthetic benchmarks. Operational consequences:

- **No pattern-matching tool detects broken authz, IDOR/BOLA or business logic abuse.** Those classes are covered by design (§5) and human review. If your programme delegates them to SAST, they are not covered.
- **Choose by signal-to-noise on your own code**, with a proof of concept in your repository, not by a feature comparison table.
- **A noisy gate disables itself**: if the team starts silencing findings en masse, the problem is calibration, not discipline. Adjust the rules before raising the blocking severity.
- Every suppression (`nosem`, `# noqa`, platform suppression) carries a **reason and an owner**; without written justification it does not pass review.
- **Custom rules** are the asset that distinguishes a mature programme; the vendor's generic ones are the starting point.

### Security tests as tests
- Every relevant **abuse case** becomes an automated test; the first ones are the negative authz tests per role and per tenant.
- Every fixed security bug leaves a **regression test** — the same rule as any bug (`CLAUDE.md`), with no exception for being security-related.
- **Negative** authz tests over the full matrix: every role × every foreign resource must fail. Testing only the admin role's happy path verifies nothing.

## 5. Vulnerability classes: control criteria

Reference order, **OWASP Top 10:2025**: A01 Broken Access Control (absorbs SSRF), A02 Security Misconfiguration, A03 Software Supply Chain Failures (new), A04 Cryptographic Failures, A05 Injection, A06 Insecure Design, A07 Authentication Failures, A08 Software or Data Integrity Failures, A09 Security Logging and **Alerting** Failures, A10 Mishandling of Exceptional Conditions (new).

### Broken authorisation (A01) — the number one class, and the one no tool sees
- **Deny by default**: the absence of a rule is a denial. The authorisation decision is **centralised** in a single point, invoked by every path (API, jobs, GraphQL, admin), never reimplemented endpoint by endpoint.
- **IDOR / BOLA**: every object reference is authorised **against the request's subject and the concrete object**, server-side, on every access. Unguessable identifiers (UUIDv4/ULID) are defence in depth, **never** the control: obfuscation is not authorisation.
- **BFLA** (function or level): the UI menu is not a control; every privileged operation checks the role server-side. Protecting the `/admin/*` route is not enough if the operation is reachable by another route.
- **Multi-tenant**: the `tenant_id` **always** comes from the authenticated context, never from a parameter, body or header. Isolate at the data layer (a mandatory filter in the repository or RLS in the database), not query by query.
- **SSRF** (inside A01 since 2025): an allowlist of outbound destinations, non-HTTP(S) schemes forbidden, internal ranges and the cloud metadata endpoint blocked, DNS resolution validated **and revalidated after every redirect** (DNS rebinding), egress through a proxy. Never validate by URL regex.

### Authentication and session (A07)
- MFA; passwords with **Argon2id** or bcrypt (never MD5/SHA-1/bare SHA-256), without absurd composition rules and checked against breached-password lists.
- **Session identifier rotation** on every privilege change (login, elevation, password change) and **server-side** invalidation on logout or credential change: a JWT that cannot be revoked is not a session.
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`, `__Host-` prefix, absolute expiry in addition to idle expiry.
- Tokens: verify `iss`, `aud`, `exp` and the algorithm **against an explicit allowlist** (`alg: none` and HS/RS confusion are the classic failures). Short lifetime and rotating refresh with reuse detection.
- Anti-enumeration: identical responses and timings in login, registration and recovery; rate limiting and progressive lockout per account **and** per origin.

### Injections (A05)
A single rule: **separate code from data** in every interpreter. Sanitising is not a control; escaping is, and it **depends on the output context**.
- **SQL/NoSQL**: parameterised queries always, and no concatenation in the ORM's raw fragments either. Dynamic identifiers (table, column, `ORDER BY`) go through an allowlist, not through a parameter.
- **Command injection**: do not invoke a shell. Use the process API with an argument array, the binary by absolute path, a controlled environment. If a shell is needed, there is a design error.
- **XSS**: escaping **by context** (HTML, attribute, JS, URL, CSS) delegated to the template engine with auto-escaping; `innerHTML`, `dangerouslySetInnerHTML` or `v-html` only with HTML sanitised by a maintained library (DOMPurify or equivalent). CSP is defence in depth, not a substitute.
- **SSTI**: never build templates with user input; the input is *data* passed to the render, never part of the template. If the product accepts user templates, use a sandboxed engine — and an audited one, because template sandboxes get escaped.
- **LDAP**: escaping of the DN and of the filter (they are different rules), bind with a least-privilege service account, never an anonymous bind with user input.
- **XXE**: DTDs and external entities disabled in **every** XML parser — including SVG, OOXML (XLSX/DOCX), SOAP and SAML. Prefer formats without entities.

### Deserialisation and integrity (A08)
- **Forbidden**: native deserialisation of untrusted data (`pickle`, `ObjectInputStream`, `BinaryFormatter`, `unserialize`, unsafe `yaml.load`, `Marshal.load`). Use data formats (JSON with a schema, protobuf) and map to explicit types.
- If unavoidable: an allowlist of types and a signature/MAC verified **before** deserialising. Verifying afterwards is worthless.
- Integrity of artifacts and updates: signature verified before executing (see `cicd-standards`).

### Input, files and paths
- **Validation at the edge and by allowlist** (type, format, range, length) over data that is **already decoded and canonicalised**; validating before normalising is a known bypass.
- **Path traversal**: do not build paths with user input. Resolve to a canonical path and **check that the prefix is still inside the permitted directory** after resolving symbolic links; the file name is generated by the server.
- **File upload**: an allowlist of types verified by content (never by extension or `Content-Type`), a maximum size, a generated name, storage **outside the webroot** or in object storage with no execution, served from a separate origin with `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff`. Antivirus when the file is shared between users. SVG and HTML are script execution: treat them as such.
- **Mass assignment / over-posting**: an explicit input DTO per endpoint with an **allowlist of fields**; never bind the body to the domain entity. Fields such as `role`, `is_admin`, `price` or `tenant_id` simply do not exist in the input DTO.
- **TOCTOU**: do not separate check from use. For files, operate on already-open descriptors (`openat`, `O_NOFOLLOW`) and private directories, not on re-resolved paths. In business logic (balance, stock, coupons), check and mutate in **one transaction with a lock** or through a conditional atomic operation; the idempotency key prevents double spending on retry.

### Browser: CSRF, CORS and headers (A02)
- **CSRF**: cookies with `SameSite` plus a synchronised anti-CSRF token on every operation with an effect if the session travels in a cookie. Authentication via the `Authorization` header is not vulnerable to classic CSRF, but then the token cannot live in `localStorage` without accepting the XSS risk.
- **CORS**: an **explicit** allowlist of origins; `Access-Control-Allow-Origin` never reflected from `Origin` without validation and **never** `*` together with `Allow-Credentials: true`. CORS relaxes the browser's policy: it is not an authorisation control.
- **Strict CSP** based on a **nonce or hash** (`script-src 'nonce-…' 'strict-dynamic'`), with `object-src 'none'`, `base-uri 'none'` and `frame-ancestors 'none'`. Forbidden: `unsafe-inline`, `unsafe-eval` and per-domain CDN allowlists (they are bypassable). Deploy first in `Report-Only` with a reporting endpoint.
- The rest: `Strict-Transport-Security` with `preload`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, a restrictive `Permissions-Policy`.

### Exceptional conditions (A10, new in 2025)
- **Fail closed**: on an error, exception or timeout from the authn/authz provider, the default decision is to **deny**. Failing open (CWE-636) is the essence of this category.
- Global exception handler: to the client, a generic error with a correlation identifier; to the log, the detail. Never stack traces, internal paths or database errors to the user (CWE-209).
- **Limits on everything**: rate limiting, quotas, maximum request and response size, query depth and cost in GraphQL, timeouts on every outbound call. Anything unbounded ends in DoS, brute force or a cloud bill.

### Cryptography and data (A04)
Modern crypto per `CLAUDE.md` (AES-GCM, ChaCha20-Poly1305, Argon2/bcrypt, TLS 1.2+). AppSec additions: never implement your own primitives, compare secrets in **constant time**, take randomness from a CSPRNG (never `random()` for tokens), keys outside the code with rotation, and classify the data before choosing the control.

### Supply chain (A03, new in 2025)
A category of its own since 2025. The operational criteria live in `cicd-standards` and `vulnerability-management-standards`; from AppSec what matters is that **a dependency is your code in production** and enters the threat model like any in-house component.

## 6. Programme operability

- **A09 — logging *and alerting***: the category was renamed in 2025 precisely because logging without alerting detects nothing. Minimum events, structured and correlated: failed and successful authn, **denied authz**, privilege change, credential change, access to sensitive data, use of administrative functions. Each with actor, resource, outcome, origin and `trace_id`.
- **Forbidden to log** passwords, tokens, session cookies, unnecessary PII/PHI or card data. The log is a data store with its own classification and retention — and **encode the output written to the log**: log injection is a real vector against the SIEM.
- Actionable alerts on abuse patterns (spikes of denied authz per user, enumeration, distributed brute force) with a runbook. Logs kept intact and retained for *forensics readiness*.
- **Programme metrics** (to improve, not to police): finding density by severity, remediation time by severity, *escape rate* (what reaches production versus what was caught earlier), threat-modelling coverage over sensitive changes and the false-positive ratio per rule. Scan coverage is a signal, not a goal.
- **Security champions**: one per team, **a volunteer**, with allocated time and training. Typical duties: facilitating threat modelling, first security review of design and code, and triaging their team's findings. They do not replace the security team, they scale its reach.
- **The scanner is attack surface**: the Trivy supply-chain compromise of March 2026 (tag poisoning of `trivy-action` and `setup-trivy`, malicious binaries and images) is a reminder that these tools run in CI with access to secrets by design. Pin actions by **immutable commit SHA**, images by **digest**, verify checksums and signatures, and assume CI credentials must be rotatable at any moment.

## 7. Sustainability

- **Threat model review** on every change of trust boundary and, at minimum, annually in critical systems. An out-of-date model is worse than none: it gives false confidence.
- **SAST rules versioned in the repository** and reviewed in the PR as code, with their own changelog.
- **Migrating mappings to the Top 10:2025** as a planned task: rules, reports and audit evidence still treating SSRF as its own category (A10:2021) or citing "Logging and Monitoring" are obsolete.
- Cadence: review this skill and the tooling every 6 months. ASVS and the Top 10 move on multi-year cycles; the tools, on monthly ones.
- Security debt **registered with an owner and a review date**, never silenced: an explicit exception > an anonymous suppression.

### List of prohibitions
- ❌ Trusting automated tools to detect broken authz, IDOR/BOLA or business logic flaws.
- ❌ Authorisation based on what the UI shows, on unguessable identifiers or on the endpoint's route.
- ❌ `tenant_id`, `user_id`, `role` or `price` taken from a client parameter, body or header.
- ❌ Concatenating input into SQL, commands, templates, LDAP filters or file paths.
- ❌ Sanitising as a substitute for parameterising or for escaping by output context.
- ❌ Native deserialisation of untrusted data, or verifying the signature **after** deserialising.
- ❌ XML parsers with DTDs or external entities enabled.
- ❌ `Access-Control-Allow-Origin` reflected without validation, or `*` together with credentials.
- ❌ CSP with `unsafe-inline`, `unsafe-eval` or a CDN domain allowlist.
- ❌ Uploaded files served from the same origin, with the client's name, or from the webroot.
- ❌ Binding the request body directly to the domain entity (mass assignment).
- ❌ Failing open on an error or timeout from the authn/authz provider.
- ❌ Returning stack traces, internal paths or database errors to the client.
- ❌ Secrets, tokens or PII in logs; log output written without encoding.
- ❌ An endpoint with no rate limiting, no size limit and no timeout.
- ❌ Home-grown cryptography, non-constant-time secret comparison or `random()` for tokens.
- ❌ Silencing a finding without a written reason and an owner.
- ❌ Blocking the merge on the inherited stock of findings instead of on the new ones in the diff.
- ❌ A "security" user story with no verifiable, testable acceptance criterion.
- ❌ Citing ASVS requirements without a version prefix: the numbering is not stable between versions.
- ❌ Security tool actions or images referenced by a mutable tag.

## 8. Mandatory web verification

Before pinning any version, category or recommendation from this document into a deliverable, **verify with WebSearch** (the data is from August 2026 and expires):

1. **OWASP Top 10**: is the **2025** edition still current or is there a later one? Exact names of A01-A10 and the mapped CWEs at `owasp.org/Top10/`.
2. **ASVS**: is it still 5.0.0 (May 2025) or has 5.0.1 / 5.1 shipped? Chapter structure and levels in the `OWASP/ASVS` repository.
3. **API Security Top 10**: check whether it is still the 2023 edition at `owasp.org/API-Security`.
4. **Proactive Controls**: is it still v4 (2024) at `top10proactive.owasp.org`?
5. **Tooling**: status, licence, governance and **recent security incidents** of the tool you are going to recommend (ZAP is no longer an OWASP project; Trivy suffered a supply-chain compromise in March 2026). Check the vendor's own advisories before putting it in CI.
6. **Headers and CSP**: current directives and real support (MDN) before pinning a policy; the recommendations change with the browsers.
7. If the project touches AI/LLM, check the status of the **OWASP Top 10 for LLM Applications / Agentic AI**: it is a separate project, with its own cycle, and it is not covered here.

If the web contradicts this document, **the web wins** — flag the discrepancy.
