---
name: identity-threat-detection-standards
description: ITDR — detecting and responding to attacks against identity itself, which is where the perimeter actually is. Use when investigating or defending against password spraying, adversary-in-the-middle session-cookie theft and token replay that survives MFA, refresh-token and primary-refresh-token abuse, MFA fatigue and push bombing, consent phishing and malicious OAuth application grants, device-code-flow phishing, SIM swapping, forged federation assertions (Golden SAML, stolen token-signing certificate, cross-tenant trust abuse), credentials or certificates silently added to an existing application or service principal, illicit device registration, hybrid identity attack paths through directory synchronization and authentication agents in both directions, deciding which identity telemetry you actually retain and what your licence tier silently drops, writing high-value identity detections and their triage, and identity-specific containment where revoking sessions, refresh tokens and consents matters far more than resetting a password. Also covers emergency access accounts and administrative tiering as they are watched, not as they are designed.
---

# Identity threat detection and response (ITDR) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the attack against identity, its detection and its response**: why identity is
the dominant vector and with what evidence that is sustained; the characteristic attack classes and
how they look in the logs; what telemetry is needed and what is lost depending on licence; the
detections that genuinely pay off; and identity-specific containment, which **is not changing the
password**. It includes watching emergency accounts and the administrative tier, not their
design.

Triggers: "compromised account", "impossible travel sign-in", "password spraying",
"password spraying", "credential stuffing", "AiTM", "adversary in the middle", "session cookie
theft", "token replay", "stolen token", "stolen refresh token", "PRT", "MFA fatigue",
"push bombing", "MFA push bombing", "consent phishing", "malicious OAuth
application", "consent grant", "device code phishing", "device code
flow", "SIM swapping", "Golden SAML", "token signing certificate", "cross-tenant
trust", "federation added to the domain", "credential added to the application",
"`addPasswordCredential`", "`addKeyCredential`", "service principal with a new secret",
"unrecognised device registration", "MFA method added by the attacker", "mail forwarding
rule created", "hash synchronisation", "PTA", "authentication agent",
"Entra Connect compromised", "revoke sessions", "ITDR".

**Governing principle**: **identity is the perimeter today, and an attacker who authenticates is
not exploiting anything: they are using the system as it was designed.** Hence the three
consequences that order this document:

1. **MFA is not a border, it is a toll**: it is paid once and what comes out the other side —a
   session cookie, a refresh token— **is a portable credential that never asks for MFA again**.
   Once the post-authentication artifact is stolen, MFA is irrelevant (§3.2).
2. **There is no malware to look for.** An identity attack leaves as its only trace a sign-in log,
   an audit log and a consent log. Without that telemetry retained there is no possible
   investigation — and **the licence tier decides how much there is** (§3.5).
3. **Resetting the password expels nobody.** A new password does not invalidate a stolen cookie
   nor a live refresh token. The correct response revokes, and in a specific order
   (§3.7).

**Strictly defensive and authorised posture.** The techniques are described as a **risk class,
observable evidence and control**, never as a reproducible procedure. There are no
payloads here, no parameterised attack tools, no exploitation steps.

**Not applicable**: see `identity-access-management-standards` (**hard boundary and the most
important of this skill**: **identity architecture is hers, without exception** — IdP choice, OAuth
2.1/OIDC flows and their design, SAML, passkeys/WebAuthn, **MFA and conditional access policy**,
SCIM and the joiner-mover-leaver cycle, authorisation engines, PAM/JIT, **design** of break-glass
accounts, workload identity. **Here**: how all of that is attacked, how it looks in the
logs, what is detected and what is done when it happens. One-line arbitration rule: *if the
question is "how do I configure it", it is hers; if it is "how do I know they are breaking it and
what do I do", it is ours*), `detection-engineering-standards` (**the rule is hers**:
authoring in Sigma/KQL, tests, thresholds, tuning, ATT&CK coverage, deployment in the SIEM and
schema normalisation. **Here, which identity hypothesis deserves a rule and why** — the rule is
born here and governed there),
`soc-operations-standards` (shift, queue, triage, escalation and closure of the alert this
generates), `incident-response-forensics-standards` (**the confirmed incident and its
investigation**: scoping, acquisition, timeline, eradication and rebuild; **here only
identity-specific containment and why its order matters**), `windows-server-ad-standards` (**the
domain itself**: forest, GPO, Kerberos/NTLM, `krbtgt`, AD CS, Tier 0/PAW, delegation, directory
hygiene and forest recovery. **Here only the bridge**: how a compromise in the directory becomes a
compromise of the cloud tenant and vice versa), `azure-standards`/`aws-standards`/`gcp-standards`
(**tenant configuration and its platform IAM**: conditional access, PIM, governance,
policies and conditions. Here, their abuse), `cloud-security-posture-standards` (**sister**:
excessive permission **at rest** —effective entitlement, wildcards, permission attack paths—;
**here the misuse in flight** of a legitimate identity), `endpoint-security-standards`
(**the workstation and its EDR**: the infostealer that steals the browser cookie is stopped and
detected there; **here what happens afterwards with that cookie**), `email-security-standards` (mail
as the phishing delivery channel; here the consequence on identity),
`threat-intelligence-standards` (the actor, the indicator and its expiry),
`vulnerability-management-standards` (CVE and patching SLA — **a permission and a stolen token have
no CVE**), `secrets-management-standards` (custody and rotation of the application secret; here
the detection that somebody has **added** a new one), `mobile-standards` (the device),
`grc-compliance-standards` (notification obligation and evidence), `privacy-engineering-standards`
(personal data inside sign-in logs: legal basis and retention),
`offensive-security-standards` (authorised simulation of these attacks, with scope in writing).

## 2. Default decisions

> Verify the latest version and the exact name of each capability on the web before committing to it
> (§8).

| Decision | Default | Justifiable alternative / nuance |
|---|---|---|
| Primary detection source | **Sign-in logs + IdP audit logs**, exported to your own storage from day 1 | None. Without export, default retention leaves you blind (§3.5) |
| Identity telemetry retention | **≥ 12 months hot or accessible** | Less, only with an explicit analysis of which investigation you are giving up on |
| The IdP's own risk detection | Enabled and **sent to the SIEM**, treated as one more source | Not as the only source: it is a proprietary black box with no real *tuning* |
| Containment of a compromised account | **Revoke sessions and refresh tokens → invalidate consents → rotate credentials → then the password** | The reverse order leaves the attacker inside (§3.7) |
| Emergency accounts | **Excluded from the policies that can lock you out, and with an alert on any use** | None. Their unannounced use is always an incident |
| Device code flow | **Blocked by policy except with a documented per-application exception** | Allowed only where there are real keyboard-less devices |
| Third-party OAuth applications | **User consent disabled or restricted to verified publishers and low-impact permissions** | An admin approval flow if the business requires it |
| Token binding to the device | **Enable where it exists** (token protection / cryptographic binding) | Pilot first: coverage by client and resource is partial (§3.7) |
| Cloud service identities | **Federation / managed identity**; a static credential only with a short expiry and monitored | None other |

## 3. Structure and conventions

### 3.1 The evidence, and what is folklore

Sustaining "identity is the dominant vector" with figures requires method. What is verifiable as of
August 2026:

- **Verizon DBIR 2025**: credential abuse appears as the initial access vector in
  **22 %** of breaches, followed by exploitation of vulnerabilities (20 %). **The denominator
  is not all breaches**: it is the subset with a known vector excluding error and misuse
  (n=9,891 out of 12,195 confirmed breaches). The report itself warns of **spill-over between the
  credential and phishing categories**, because often it cannot be determined where
  the credential came from. And the DBIR **is not a probability sample**: it is Verizon's caseload
  plus voluntary contributions, with a contributor list that changes between years and with no
  confidence intervals. **Defensible reading: credential abuse is consistently among the top two
  vectors.** Indefensible reading: "22 % of breaches are due to credentials" as a population
  parameter. (Verify the 2026 edition before citing figures: §8.)
- **What must stop being cited**: **"MFA blocks 99.9 % of attacks"**. Origin: an entry
  on Microsoft's security blog from August 2019. The underlying figure **was not a controlled
  experiment** but an observational ratio —*more than 99.9 % of compromised accounts did not have
  MFA*— taken when enterprise MFA adoption was around 11 %: on that base, almost any
  compromised account would lack MFA even if MFA did nothing. Microsoft itself later published
  a study with a more conservative estimate (**99.22 % risk reduction**, and 98.56 %
  in leaked-credential cases) and its current documentation uses **"more than 99.2 % of account
  compromise attacks"**, not 99.9 %. Besides, the statement has been broadened in the citing: from
  "account compromise attacks" to "cyberattacks" in general. **Cite the 99.2 % with its source, or
  do not cite a percentage at all: the argument —MFA eliminates mass automated attack at a stroke—
  does not need it.**
- **"82 % of breaches involve the human factor"** and similar: they are figures from annual reports
  with the same sampling limitation, and they change year to year and by definition. **They are not
  cited without the edition, the denominator and the definition of "human factor".** None is written
  here.
- General rule of this skill: **a figure with no published methodology = it is not written**.
  Debunking it is worth more than repeating it.

### 3.2 Why MFA does not close the case: the post-authentication artifact

What the attacker wants is no longer the password, it is what comes afterwards:

- **The application's session cookie**: it is issued and controlled by **the application**, not the
  IdP. The IdP cannot revoke a session it does not govern; only the application can invalidate it,
  when it decides to revalidate.
- **Refresh token**: the master key. Long-lived —by default of the order of
  **90 days** on the major platforms—, it allows minting new access tokens
  silently and **survives a password change** in several scenarios.
- **Primary refresh token (PRT)** in joined-device scenarios: it is invalidated by a
  password change **only if the password was used to obtain it**. Those obtained by a passwordless
  method (authenticator app, FIDO2) **survive**.
- **Access token**: normally ~1 hour of life and **not revocable** by default. That is the floor
  of containment time unless the resource supports continuous access evaluation.

An operational consequence that must be written down before the incident: **between "I have reset
the password" and "the attacker has lost access" there may be hours, and if only the password was
reset, they may never lose it.**

### 3.3 Attack catalogue: what it is, what it leaves and what cuts it

Each entry = **mechanism → observable evidence → control**. No procedure.

- **Password spraying** (one common password against many accounts, below the
  lockout threshold). Evidence: many failures with **the same error code** spread across
  **many different users** from a few origins, often against legacy
  authentication endpoints that do not support MFA. Control: remove legacy authentication,
  smart lockout, banned-password lists, and detection **by distinct accounts
  touched per origin**, not by failures per account.
- **Credential stuffing**: same pattern, real credentials from leaks. Additional
  evidence: **a non-zero success rate** in the same batch.
- **AiTM (adversary in the middle)**: a reverse proxy that relays the legitimate sign-in and
  keeps the post-MFA cookie. **MFA genuinely completes** — which is why the log shows a
  successful sign-in with MFA satisfied. Evidence: the session replayed from another IP/ASN/geography
  shortly afterwards, an abrupt change of user agent, and almost always **a new MFA method
  registered or a mail forwarding rule created** in the following minutes. Real control:
  **phishing-resistant credentials (passkeys/FIDO2), device compliance and token binding
  to the device** — not "more MFA".
- **Token theft by infostealer**: no proxy and no phishing. The malware extracts cookies and cached
  tokens from the browser profile. Evidence: use of a valid token from a new origin with no
  preceding interactive authentication event. Control: it is a workstation problem
  (`endpoint-security-standards`) with an identity consequence; here, detecting the anomalous use
  and revoking.
- **MFA fatigue / push bombing**: the attacker already has the password and repeats the
  attempt until the victim approves out of exhaustion. Evidence: a burst of denied MFA
  requests followed by an approval. Control: **number matching and context in the
  notification** (it stops being "approve/deny"), an attempt limit, and **repeated denial is
  an alert in itself**.
- **Consent phishing and malicious OAuth applications**: no credential is stolen, **permission is
  requested**. The victim consents and the application obtains durable access to mail or files
  **with no password and no MFA**; changing the password does not revoke it. Evidence: consent
  grant events to previously unseen applications, an unverified publisher, broad
  mail or file read permissions. Control: restrict user consent, an approval flow,
  **periodic review of consented applications** and an alert on every new high-impact
  grant.
- **Device code flow phishing**: a standard OAuth flow designed for keyboard-less devices is abused.
  **The victim authenticates on the provider's legitimate page**, so there is no fake
  domain to detect nor proxy to intercept, and network controls do not fire.
  Publicly documented in campaigns since 2024–2025 and with later waves that chain the
  obtained token with **registration of an attacker's device** to obtain a PRT. Main and
  almost only control: **block the flow by policy** where it is not needed.
- **SIM swapping**: SMS MFA and phone recovery transfer with the number.
  Control: **remove SMS and voice call as a factor and as a recovery route** for any
  privileged account; the rest is mitigation.
- **Attacks on federation ("Golden SAML" class)**: with the federated identity provider's
  **token signing key**, the attacker **forges valid assertions for any user**,
  with whatever claims they want —including having performed MFA—. There is no authentication to
  observe: **the IdP log shows a perfect sign-in**. It is the extreme case of "a compromise of the
  identity infrastructure is not detected in the sign-in flow".
  Detection: correlate with the origin side (certificate use, access to the signing material,
  issuance with no corresponding event at the federated provider), watch **changes in the
  domain's federation configuration and in cross-tenant trusts** —adding a federated
  domain or a trust is a top-priority audit event— and treat the federation server as
  **Tier 0** (that belongs to `windows-server-ad-standards`).
- **Persistence via a credential added to an application**: the attacker does not create a new
  account —that is visible—; **they add a secret or a certificate to an already existing and
  legitimate application or service principal**, and from then on authenticate as that application,
  with no user, no MFA and no conditional access applying. It is the cleanest persistence in the
  ecosystem. Evidence: audit events for adding a credential to an application/service principal,
  granting new permissions to an existing application, assigning roles to a service principal.
  **Mandatory detection, no exceptions.**
- **Illicit device registration** and **MFA method addition**: both turn temporary
  access into durable access. Alert by default.
- **Hybrid identity, the bridge in both directions**: the directory synchronisation server
  and the authentication agents (hash synchronisation, pass-through authentication, seamless SSO)
  have, by design, **credentials or a privileged position on both sides**. Once the synchronisation
  server is compromised, the tenant is reached; once the tenant is compromised with the right
  privileges, action can be taken on-premise. **Hard consequence: if you have hybrid identity, your
  Tier 0 includes the cloud tenant, and the scope of an AD compromise includes the cloud — and vice
  versa.** These servers are not "application servers": they are identity infrastructure.
- **Abuse of service and workload identities**: no MFA possible, no user who notices
  anything, often with excessive inherited permissions. They are watched **by behaviour**: a new
  origin, a new time of day, an API never called before, an anomalous volume.

### 3.4 High-value detections (what deserves a rule; writing it belongs to `detection-engineering`)

In order of value/noise ratio:

1. **A credential or certificate added to an application or service principal**, and the grant of
   high-impact permissions to an application.
2. **A change in a domain's federation configuration, in the signing material or in
   cross-tenant trusts.**
3. **Use of an emergency access account** (any use, always).
4. **Consent granted to a new application** with mail, file or directory
   permissions.
5. **An MFA method added / a new device registered** shortly after a sign-in
   from an infrequent origin.
6. **A forwarding or inbox-manipulation rule created** after an anomalous sign-in (a classic
   signal of mail compromise, and one of the highest-precision ones).
7. **A session used from an origin different from the authentication's** (a replay indicator), and a
   token used with no preceding interactive authentication event.
8. **A burst of denied MFA prompts followed by an approval.**
9. **Spraying**: N distinct accounts failing with the same error from the same origin in a
   window.
10. **Legacy / non-MFA authentication** against privileged accounts: it should be zero, and that is
    why any event is a signal.
11. **Privileged role assignment** outside the process, and elevation outside the approval
    window.
12. **A service identity authenticating from new infrastructure.**

Declared antipattern: **"impossible travel" as the primary alert**. It is the most famous
detection and one of the worst on its own: VPN, mobile and roaming trigger it constantly, and
an attacker with a proxy in the same city never triggers it. It serves as **enrichment**, not
as a case.

### 3.5 Telemetry, and what the licence takes away

**A figure that decides the architecture and that the vendor does not highlight.** Verified verbatim
in Microsoft's documentation (`reference-reports-data-retention`, January 2026 revision):

| Report | Entra ID Free | Entra ID P1 | Entra ID P2 |
|---|---|---|---|
| Audit logs | **7 days** | 30 days | 30 days |
| Sign-ins | **7 days** | 30 days | 30 days |
| Risky sign-ins | 7 days | 30 days | **90 days** |

Furthermore, in that same reference: Microsoft Graph activity logs **are only available with P1 and
P2** and are not retained unless archived; and **a retention change is not
retroactive** — when upgrading a tier, only what was still within the previous window is kept.

Consequences, and these are the ones to take to the budget meeting:
- **A typical identity investigation is discovered weeks after the initial access.** With 7 or
  30 days of native retention, the evidence **no longer exists** when the question arrives. It is
  not a tool problem: it is a contract problem.
- **Continuous export to your own storage (SIEM or cheap storage) is not optional**,
  and it is the first thing configured in a new tenant. It costs little and is unrecoverable after
  the fact.
- **Detection capability is also tiered**: post-authentication risk detections
  (anomalous session, anomalous token) live in the high tiers. Buying the low tier and
  expecting token theft detection is an expectation error, not a configuration one.
- This table is from a specific vendor because it is the best documented; **the pattern repeats with
  the others**: fine-grained identity telemetry is sold separately. **Verify with your provider what
  log exists, how long it lasts and what tier is needed, before designing the detection** (§8).

Telemetry minimums, regardless of provider: sign-ins (interactive **and non-interactive** — the
non-interactive ones are where token abuse lives), directory audit,
**consents and changes to applications and service principals**, token issuance and
refresh, device and authentication-method registration, and federation configuration
changes.

### 3.6 Emergency accounts and administrative tiering (what is watched here)

The **design** belongs to `identity-access-management-standards`; **the watching is ours**:
- At least **two emergency access accounts**, in the cloud, with no dependency on the on-premise
  directory nor on the federation server, **excluded from the policies that could lock you out**,
  with a phishing-resistant credential held out of band. **Excluding them from conditional access is
  the reason their use must always alert**: they are the only identities with no safety
  net.
- **Documented periodic testing** that they work. An emergency account nobody has tested
  is an unrehearsed continuity plan.
- **Tier separation**: the account that administers identity does not browse, does not read mail and
  is not used from a general-purpose workstation. Here the violation of that rule is watched
  —administration from a non-compliant device, elevation outside the process— and **that is a
  detection**, not an audit observation.

### 3.7 Identity-specific response

**A password change does not invalidate a stolen cookie.** Containment order, and the order matters:

1. **Revoke the identity's refresh tokens and sessions** (on the Microsoft platform, the session
   revocation action invalidates refresh tokens and browser cookies, moving the session validity
   timestamp). **This first**, because the refresh token is the key that reissues everything else.
2. **Review and revoke application consents and added credentials**: if the attacker
   left a consented application or a secret on a service principal, steps 1 and 3 do not
   affect them at all. **This is the most forgotten step and the one that leaves the attacker
   inside.**
3. **Remove MFA methods and devices registered by the attacker.**
4. **Change the password** and force re-enrolment of the factor.
5. **Review mail rules, delegations and mailbox permissions** created during the window.
6. **Rotate any secret that identity had access to** (boundary with
   `secrets-management-standards`).

Operational warnings that must be known **before** the incident:
- **Revocation is not instantaneous.** There is propagation of minutes, and **access tokens already
  issued remain valid until they expire** (typically ~1 hour) unless the resource supports
  **continuous access evaluation**. With that evaluation, revocation is near real time, with a
  documented latency of **up to ~15 minutes** due to event propagation; **clients and
  resources that do not support it are left out**, and there the floor is again the token's
  lifetime.
- **Counter-intuitive nuance**: in sessions with continuous evaluation the token lifetime
  **is extended** (up to the order of 28 hours) because revocation comes to depend on events, not on
  the clock. A long token replayed against a path that does not evaluate continuously is a problem,
  not an improvement.
- **Application sessions are closed by the application**, not by the IdP. Closing the IdP session
  does not guarantee closing all the ones below. They have to be enumerated.
- **Federated accounts and external users**: revocation in your tenant does not govern their home
  tenant. Explicit coordination.
- **If there is suspicion of a compromise of the identity infrastructure** (federation server,
  synchronisation server, signing material), **per-account containment is useless**: arbitrary
  identity issuance must be assumed and it escalates to rotating the signing material and to
  rebuilding — territory of `incident-response-forensics-standards` and
  `windows-server-ad-standards`.
- **Do not notify the compromised account through the compromised channel.** If the attacker is in
  the mailbox, they read the notification.

## 4. Quality and testing

- **Every identity detection is validated against the real activity it claims to detect**, in a test
  tenant or with an authorised exercise **deconflicted** with the SOC. A spraying rule
  nobody has triggered is not tested.
- **Response rehearsal**: time end to end "detection → effective revocation →
  confirmation that the token no longer works". **That number is the real SLA**, and it almost
  always comes as a surprise.
- **Revocation coverage test**: verify per application which ones honour revocation
  quickly and which do not. The resulting list is a risk deliverable.
- **Testing of emergency accounts** on a fixed cadence and recorded.
- **Telemetry test**: generate an event of each critical type (consent, credential
  added to an application, device registration) and **check that it reaches the SIEM with the
  necessary fields**. An event that exists in the portal but is not exported is not telemetry.
- **Honest measurement**: precision per rule, time to contain, and **percentage of privileged
  accounts with a phishing-resistant credential** — the last one is the metric that moves risk the
  most and the easiest to measure.

## 5. Stack security

- **ITDR tools request permissions over the directory**, often broad read and sometimes
  write in order to respond. That service principal is a first-order target and
  falls in the list of §3.4.1: **whoever can add a credential to it is an administrator of your
  identity**. Minimum permissions, periodic review, alert on its modification.
- **The SIEM that receives the identity logs contains the map of who is who**: its own access
  control and personal data inside (boundary with `privacy-engineering-standards`).
- **No automatic response flow should be able to disable accounts en masse** without human
  control: it is a textbook internal denial-of-service vector.
- **The account that operates ITDR is administered as Tier 0**, not as just another analyst
  account.

## 6. Performance and operability

- **Volume**: non-interactive sign-ins are by far the most voluminous log
  of a large tenant, and **it is precisely where token abuse lives**. It is not trimmed for cost
  without an explicit written decision.
- **Telemetry latency**: identity logs from SaaS platforms have a delay
  of minutes to tens of minutes. **Detection time has that floor**, and promising less
  in an SLA is lying.
- **Expected noise**: travel, VPN, mobile roaming and automated deployments. It is enriched with
  identity context (role, change window, compliant device) before alerting; the shift and
  the triage belong to `soc-operations-standards`.
- **Cost**: long identity retention is cheap compared with network or endpoint retention and it is
  the one that yields the most per euro in investigations. If something has to be cut, it is cut
  elsewhere.

## 7. Long-term sustainability

- **This surface changes by product, not by version**: new authentication flows,
  new conditional access capabilities and new attack classes appear between quarters.
  Quarterly review of the §3.3 catalogue and of the §3.4 detections.
- **Migration to phishing-resistant credentials as a programme**, not as a perpetual pilot: it is
  the only change that removes whole families from this list at a stroke (AiTM, MFA fatigue,
  successful spraying).
- **Periodic review of consented applications and of service principal credentials**:
  they grow on their own and nobody retires them. Mandatory expiry on application secrets.

**FORBIDDEN**:
- ❌ Closing an identity incident **with a password change alone**.
- ❌ Revoking sessions and **not reviewing consents or credentials added to applications**: it is
  leaving the back door open and believing it has been closed.
- ❌ Treating MFA as a terminal control, or presenting "MFA at 100 %" as if identity risk
  were solved.
- ❌ SMS or voice call as a factor or recovery route on privileged accounts.
- ❌ Citing **"MFA blocks 99.9 % of attacks"**, or any percentage from an annual report
  without the edition, denominator and methodology (§3.1).
- ❌ Designing identity detection **before** confirming which logs exist, how long they are retained
  and what licence tier is needed.
- ❌ Depending on the provider's native retention with no export of your own.
- ❌ "Impossible travel" as the primary detection.
- ❌ Emergency accounts with no use alert, with no periodic testing or with a dependency on the
  on-premise directory or on the federation server.
- ❌ Duplicating here the design of MFA, of conditional access or of the account life cycle: it
  belongs to `identity-access-management-standards`. Nor writing the SIEM rule here: it belongs to
  `detection-engineering-standards`.
- ❌ Running simulations of these attacks without scope and authorisation in writing, and without
  deconfliction with the SOC. **This document contains no offensive procedure and must not
  be extended in that direction.**

## 8. Mandatory web verification

Before committing to anything in a real project, check on the web:
1. **Log retention by licence tier** at your identity provider, and which signals
   require a higher tier. The table in §3.5 was transcribed verbatim from Microsoft's
   documentation with a January 2026 revision; **it changes without notice** and it is the figure
   that constrains the most decisions.
2. **Exact name and current availability** of the capabilities cited without a brand: token
   binding to the device, continuous access evaluation and its **coverage by client and resource**,
   consent restriction, blocking the device code flow. Partial coverage
   is what decides whether the control is any use.
3. **Default token lifetimes** (access, refresh, PRT) and **what invalidates them** in your tenant:
   they are what sets the floor of containment time and they have changed historically.
4. **Current campaigns and advisories** on device code phishing, token theft and abuse of
   OAuth applications: the pattern moves fast. Prefer advisories from national CERTs and from the
   vendor over third-party summaries.
5. **DBIR and equivalents**: current edition, exact figure, **denominator and n**, before citing
   anything. What is written here corresponds to the 2025 edition.
6. **Declared gap**: it was not possible to verify against a primary source a regulatory or
   public-body reference on the "Golden SAML" class and the compromise of federation signing
   material; the mechanism described in §3.3 is consolidated engineering criteria, but **if it is
   going to be cited in a report, look for the corresponding official advisory**. Nor is the figure
   from the 2026 DBIR edition cited here: it was seen mentioned in third-party summaries and **was
   not verified against the report**.
7. **End of support and replacement** of the hybrid identity components cited (synchronisation and
   authentication agents): their life cycle changes and an unsupported component in that
   position is Tier 0 without patches.

If the web contradicts this document, **the web wins** — flag the discrepancy.
