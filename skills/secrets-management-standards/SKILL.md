---
name: secrets-management-standards
description: Secrets lifecycle for already-generated credentials. Use when working with HashiCorp Vault or OpenBao (policies, dynamic secrets, seal/unseal, vault or bao CLI), Infisical, Bitwarden Secrets Manager, consuming AWS Secrets Manager, Azure Key Vault or GCP Secret Manager, External Secrets Operator (ExternalSecret, ClusterSecretStore), Secrets Store CSI Driver, sealed-secrets, SOPS with age, systemd LoadCredential= and systemd-creds, gitleaks, betterleaks or trufflehog scans, .gitleaks.toml, responding to a leaked credential, rotation runbooks, or replacing a static credential with short-lived federated identity.
---

# Secrets management standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **operational lifecycle of already-generated secrets**: deciding on and deploying the
manager, modelling paths and policies, dynamic secrets with TTL, the injection mechanism into
the consumer (file, API, systemd credential, Kubernetes operator), automatic rotation
and testing it, responding to the exposure of a secret, detecting secrets in
code and history, encrypting secrets when they must live in the repository, secrets in
images, container layers, build artifacts, logs and backups, auditing and least
privilege over the manager itself, HA/sealing and behaviour when it goes down, and the separation
between human secrets and machine secrets.

Triggers: `vault`/`bao` CLI, `vault.hcl`, HCL policies, `bao operator unseal`,
`ExternalSecret`/`ClusterSecretStore`/`PushSecret`, `SecretProviderClass`, `SealedSecret`,
`.sops.yaml`, `sops -e`, `age`/`age-keygen`, `LoadCredential=`/`LoadCredentialEncrypted=`/
`systemd-creds`, `.gitleaks.toml`/`.gitleaksignore`, `gitleaks detect`, `trufflehog git`,
`bws`, `infisical run`, `aws secretsmanager get-secret-value`, `az keyvault secret show`,
`gcloud secrets versions access`, "rotate credential", "leaked secret", "push protection".

**Guiding principle**: **the best secret is the one that does not exist**. Before storing a
credential, the job is to **eliminate it**: short-lived federated identity (CI OIDC into
the cloud, the provider's workload identity, SPIFFE/SPIRE between services) replaces the
static secret with no custody, no rotation and no leak risk. The secrets manager is for
**what cannot be eliminated**, and its real goal is not to be a vault of eternal
passwords, but to **issue dynamic credentials with a short TTL**. Corollary: an architecture
with many stored secrets is not a well-guarded architecture, it is a badly
designed one.

**Not applicable**: see `cryptography-pki-standards` (**algorithm choice, key
generation, randomness, PKI and certificate issuance, KMS/HSM as a cryptographic primitive and
envelope encryption — all of that is theirs**; here only the **custody, distribution, operational
rotation and consumption** of already-generated material),
`identity-access-management-standards` (**the preferred alternative to the static secret**: IdP,
OAuth 2.1/OIDC flows, tokens, federation, SPIFFE/SPIRE, PAM/JIT — before storing a secret
you check there whether it can not exist at all), `cicd-standards` (the pipeline, its OIDC, pinning
of actions and the gates that run the scan), `kubernetes-standards` (the `Secret` object,
encryption in etcd, RBAC and admission), `iac-standards` (**the Terraform state contains secrets
in clear text** and `sensitive` variables; handling the state is theirs), `aws-standards` /
`azure-standards` / `gcp-standards` (configuration, IAM and cost of the specific managed
service — here the criteria for use and consumption), `data-platform-standards` (credentials and
encryption at rest of the data engine), `windows-server-ad-standards` (gMSA/dMSA, LAPS and
`krbtgt` rotation: **directory** secrets), `bash-linux-scripting-standards` (the
script that consumes the secret without leaking it through `ps` or the log),
`incident-response-forensics-standards` (**mass credential rotation during a
compromise**: there the incident process, here the mechanism that makes it possible in hours and
not in weeks), `incident-management-standards` (declaration, severity and communication),
`detection-engineering-standards` (**shared and bidirectional boundary**: the telemetry of
this domain —anomalous reads from the manager, a secret detected in a push, use of a
credential from an impossible origin, a secret read after having been revoked— is a
**first-order detection source**; the scanning is mine, the rule that turns the finding
into an alert and its runbook are theirs), `privacy-engineering-standards` (**a personal data item is not
a secret** and is not managed with these tools), `grc-compliance-standards` (the regulatory
control that demands custody and rotation, and its evidence), `bcdr-standards` (custody of recovery
keys **outside** the backed-up system and their role in the continuity plan), and the
language skills —among them `powershell-standards`, which **delegates here** the choice of manager
and secrets scanner and keeps the code criteria: `SecretManagement`/`SecretStore` as
front-end, and the prohibition of `ConvertTo-SecureString -AsPlainText -Force` with a secret written
in the file—, `developer-workstation-standards` (**the choice of secrets manager and scanner
belong here**; **custody on the developer's machine is theirs** —key in hardware, PIN and
mandatory touch, a `credential.helper` that does **not** write in clear text, token outside the shell
history and the `~/.netrc`, and the credential scope a coding agent can reach—),
and `solidity-standards` (the contract is theirs; **custody of the deployment
key and of the `owner`/`upgrader` key belongs here** —HSM or multisig, rotation, threshold—.
Fact that orders the priority: **private key compromise explains more than 25 % of on-chain
thefts and four of the ten largest**; an upgradeable contract shifts all the risk to whoever
holds that key, so **a single hot key is not an acceptable architecture**).

## 2. Default decisions

> Data verified Aug 2026. **Verify version, licence and governance on the web before
> committing to a platform (§8)**: this domain had licence, foundation and
> maintenance changes in 2025-2026, and several of them invalidate earlier recommendations.

### 2.1 The decision hierarchy (in this order, always)

1. **Can the secret not exist?** → OIDC/workload identity federation (CI→cloud),
   SPIFFE/SPIRE (service→service), the provider's managed identity. **With no secret there is no
   custody, no rotation and no leak.**
2. **Can it be dynamic?** → the manager **generates** the credential on the fly with a TTL (database
   user, temporary cloud credential, short-lived certificate). The secret exists for
   minutes, not years.
3. **Can it be short-lived and revocable?** → token with TTL and effective revocation.
4. **Only then**: static secret in the manager, with an owner, policy, auditing and
   tested rotation.

### 2.2 Manager

| Need | Default | Justifiable alternative / vetoed |
|---|---|---|
| A single cloud, workloads only in it | **The native manager** (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) | It is the KISS option: IAM already exists, native integration and zero operations. Deploying Vault/OpenBao "just in case" with a single cloud is over-engineering |
| Multi-cloud, on-prem or serious dynamic secrets | **OpenBao 2.6.1** (MPL-2.0, **OpenSSF/Linux Foundation, Sandbox level** since Jun 2025) | **HashiCorp Vault 2.0.3** is still valid and is more mature in replication — but its licence is **BUSL 1.1 since Aug 2023 and has not changed** after the acquisition by **IBM closed (27 Feb 2025)**: today the *Licensor* in the LICENSE file is IBM. It is an **ADR decision with legal review**, not a technical one |
| "Product-grade" manager with DX and UI | **Infisical 0.162.15** (MIT core, `ee/` under a proprietary Enterprise licence) | An honest *open core* model but with key paid features (**dynamic secrets are in the Advanced tier**). Valid for small teams; check what you need that sits in `ee/` before committing |
| You already use Bitwarden for the team | **Bitwarden Secrets Manager** | **Little-known licence warning**: the server is AGPLv3, but the **SDK where the `bws` client lives (`bitwarden/sdk-sm`) is NOT open source** — a proprietary licence that forbids using it with software other than Bitwarden. The 2024 GPL controversy was resolved for the password manager, **not** for Secrets Manager. Its Kubernetes operator is officially installed with `--devel` (pre-release channel): undeclared maturity |
| **Human** secrets (team) | **Password manager** with shared vaults and MFA | **It is not the same problem nor the same tool** (§3.7). Vetoed: using the service secrets manager as the team's password vault, or the other way round |

**On Vault↔OpenBao compatibility (the most volatile fact in this skill)**: it remains
**practical in the essentials** (API, HCL policies, migration by Raft snapshot), but **the
divergence is real and accelerating** — verify it before assuming portability:
- OpenBao **removed `stored_shares`** (2.6.0) and **is retiring the built-in seals**
  (`awskms`, `azurekeyvault`, `gcpckms`, `ocikms`, `pkcs11`, `alicloudkms`) **in 2.7.0**,
  moving them to external `kms` plugins: it is a deployment change, not a cosmetic one.
- Its **namespaces have different semantics** from those of Vault Enterprise (identity store per
  namespace, no group inheritance; `unsafe_cross_namespace_identity` flag, `false` by default,
  to restore Vault's behaviour).
- In OpenBao's favour: namespaces at no cost (in Vault they are Enterprise), *namespace sealing*,
  distroless and non-root images, transactional storage, plugins via OCI. Verifiable real
  adoption: **GitLab Secrets Manager is built on OpenBao** and **EdgeX 4.0 made it
  its default secret store**, replacing Vault.
- In Vault's favour: DR and performance replication, integrated automated snapshots,
  Sentinel (OpenBao offers CEL). *(Comparison from a secondary source: confirm it.)*

### 2.3 Injection into the consumer — best to worst

| Mechanism | When | Note |
|---|---|---|
| **No secret**: federated token obtained at runtime | Whenever the platform allows it | The goal. `identity-access-management-standards` |
| **Manager API from the process**, with in-memory cache and TTL | Application that can be integrated | Allows rotation **without restart**, which is half the value of rotating |
| **File in tmpfs / `$CREDENTIALS_DIRECTORY`** | systemd services, containers | In systemd: **non-*swappable* memory, immutable if privileges allow, accessible only to the service's UID and destroyed on exit** — the best mechanism in the Linux ecosystem |
| **Mounted volume** (CSI driver, K8s secret as a volume) | Kubernetes | It is **refreshed** when the secret changes; environment variables are **not** |
| **Environment variable** | Last defensible resort | See below |

**Why environment variables are the worst defensible option** — with the
correct argument, because the one usually going around is badly framed:
- **`/proc/PID/environ` is NOT world-readable**: access to it is governed by a
  `PTRACE_MODE_READ_FSCREDS` check (same UID, or root/`CAP_SYS_PTRACE`). Using "anyone can
  read it" as an argument is **incorrect** and discredits you in the technical discussion.
- The arguments that **do** hold: **they are inherited automatically by the whole process
  tree** (any subprocess, including the one that should not see it, and any `curl` you
  launch from there); **there is no per-credential access control** (all or nothing); they appear in
  **dumps and crash traces**; they are readable by any process with the same UID and by root;
  they end up exposed in introspection interfaces (`kubectl describe pod`, `docker inspect`);
  **they cannot be rotated without restarting the process**; and they have size limits and problems with
  binary data. The systemd credentials document itself enumerates exactly these
  defects against its model, where access is checked in the kernel on every use.
- OWASP (Secrets Management Cheat Sheet) is explicit: *"using environment variables is
  therefore not recommended unless the other methods are not possible"*, and forbids Docker
  `ENV`/`ARG` for secrets.

### 2.4 Supporting tools

| Area | Default | Critical note |
|---|---|---|
| Secret scanning | **gitleaks 8.30.1** (MIT) as the already-integrated baseline; **Betterleaks 1.7.3** (MIT, *drop-in*, reads `.gitleaks.toml` and `.gitleaksignore`) as the successor | **Fact that changes the recommendation**: gitleaks declared itself **feature complete** — *"future releases will be security patches only"* — and its own README points to Betterleaks, maintained by the same authors. **And its GitHub Action is another matter**: `gitleaks-action` **since v2.0.0 left MIT and requires a commercial licence (`GITLEAKS_LICENSE`) for organizations**; furthermore **v2 stops working on 16 Sep 2026**. Scan with the **binary**, not with the action |
| Deep scanning / live credential verification | **trufflehog 3.96.0** (AGPL-3.0) | Its ability to **verify** whether the credential is still live is what sets it apart. Beware AGPL if you integrate it into a product |
| Alternatives | **Kingfisher** (MongoDB, Rust), **ggshield** (requires SaaS), **Titus** (Praetorian) | **Nosey Parker has been archived since 2026-04-24** (points to Titus) and **Yelp's detect-secrets has gone ~27 months without a release**: do not start anything new on them |
| Encrypting secrets in the repo | **SOPS 3.13.3** (MPL-2.0, CNCF **Sandbox**, `getsops` org) with **age 1.3.1** (BSD-3) or KMS | **Open governance risk**: `cncf/toc#2098` (Mar 2026) declares SOPS *"active but has some health issues"* and is evaluating whether it can be relicensed away from MPL; if not, it contemplates **archiving it or removing it from the CNCF**. It remains the best option, but **with vigilance and a plan B** |
| GitOps alternative on K8s | **sealed-secrets 0.38.4** | **Hard minimum 0.36.0+** (CVE-2026-22728: `/v1/rotate` allowed widening the scope to cluster-wide). **Verified trap**: `bitnamilegacy/sealed-secrets-controller` exists frozen at ~0.31.0 as a side effect of Bitnami's image archiving — repointing there nails you to an unpatched image. Valid alternative registry, signed with cosign: `ghcr.io/bitnami/sealed-secrets-controller` |
| Syncing to Kubernetes | **External Secrets Operator 2.8.0** | See §3.4: it is powerful but has a **history of governance issues and critical CVEs** you must know before adopting it |
| Direct mount in the pod | **Secrets Store CSI Driver 1.6.0** (Kubernetes SIG Auth) | Avoids materialising a K8s `Secret`. Trade-off: **privileged DaemonSet with the kubelet's hostPath**, and its maintainers are publicly asking for hands (low bus factor). In **1.6.0 rotation changed** to the `requiresRepublish: true` model and **the rotation RBAC was removed** |
| Workload identity | **SPIRE 1.15.2** (SPIFFE and SPIRE **graduated in the CNCF** since Aug 2022) | Vault 2.0.0 already accepts **SPIFFE JWT-SVID**; Entra ID documents federation with SPIFFE/SPIRE |

## 3. Structure and conventions

### 3.1 Dynamic secrets: the real goal

- **Database credential generated on the fly with a TTL** (minutes or hours), revoked when
  the lease expires. It eliminates in one go: manual rotation, the secret shared between
  services, the "we don't know who uses this password" and most of the impact of a
  leak.
- **Design requirements people discover late**: the application must **renew or
  reconnect** when the lease expires (a connection pool with an expired credential fails at
  the worst moment); the manager becomes a **dependency on the critical path** (§3.6); and the
  data engine must support creating/deleting users at that rate.
- It also applies to temporary cloud credentials, short-lived certificates and service
  tokens. **A secret with a long TTL is a decision, and is justified in the PR.**
- **Cloud managers do not rotate on their own, except in specific cases** — verify it before
  promising it:
  - **AWS Secrets Manager**: *managed rotation* without Lambda only for Aurora/RDS/DocumentDB/
    Redshift and a set of external integrations; the rest **still requires your Lambda**.
    Since Jul 2026 it emits change notifications to **EventBridge** at no cost: use them to
    detect rotations that do not happen.
  - **Azure Key Vault**: **it has no native rotation of *secrets*** (*keys* do). The
    official pattern is a `SecretNearExpiry` event → Event Grid → Function, with a
    **dual-key** scheme. Also, since Mar 2026 vaults created with the `2026-02-01` API use
    **Azure RBAC by default**, and **the earlier control plane APIs are retired on
    27 Feb 2027**.
  - **GCP Secret Manager**: **it does not rotate**; it emits a **`SECRET_ROTATE`** message to Pub/Sub at
    `next_rotation_time` and you create the new version. Cloud SQL credential rotation
    is in **Preview** (Jul 2026).

### 3.2 Modelling, policies and auditing of the manager

- **The manager is an extremely high-value target: its compromise is the organization's worst
  day.** It is treated as Tier 0: segmented network, administrative access separated from
  consumption access, MFA for humans, and its telemetry watched by
  `detection-engineering-standards`.
- **Paths by failure domain**, not by team or by convenience:
  `<environment>/<service>/<purpose>`. One policy per consuming identity, with **read-only
  access to its own paths**. Nobody —not an application, not a pipeline— reads `*`.
- **Separation of duties**: whoever administers the manager should not be able to read the business
  secrets in clear text; whoever reads them does not administer policies. Every operation with root
  material audited and with dual control.
- **Auditing that answers concrete questions**: who read what and when, which identity has
  never read a secret it has been granted (dead permission → it is withdrawn), and which secret has
  not been read in months (deletion candidate). **A secret nobody reads is pure risk.**
- **Alerting on the manager itself**: read spikes, a read from a new origin, policy
  change, auditing disabled, unplanned sealing/unsealing, and **repeated authentication
  failures**. With no `audit device` configured and with a monitored destination, there is no
  secrets management: there is a store.
- **Verify that the audit destination does not become the leak**: real precedent
  (HCSEC-2026-09) — GitHub webhook secrets were exposed in base64 in an
  HTTP header that ended up in load balancer, proxy and SIEM logs. The manager's audit logs
  are as sensitive as its contents.

### 3.3 Rotation: if it has never been run, it does not exist

- **Every credential has an explicit rotation period and an owner.** With no owner there is no rotation,
  there is intent.
- **Rotation is actually executed and on a schedule**, not "when it's due". A
  documented but never exercised rotation procedure fails exactly on the day of the
  incident, which is when it has to be run under pressure and en masse.
- **Design for overlap (dual-key / expand-contract)**: two credentials valid at
  once during the transition window. Without overlap, every rotation is a planned
  outage, and that is why nobody rotates.
- **Programme metric**: *time-to-rotate-everything* — how long it would take you to rotate **all**
  the credentials in a scope. If the answer is "weeks", you have a latent incident,
  just like a PKI that cannot reissue within 24 h.
- Rotation is a **recovery gate**, not just hygiene: the compromise response plan
  depends on this number being small.

### 3.4 Kubernetes: how the secret reaches the pod

Two valid paths, and the choice is documented:

- **External Secrets Operator (ESO)**: syncs from the manager to a Kubernetes `Secret`.
  Convenient and compatible with everything, but **it materialises the secret in etcd** (requires encryption at
  rest with a KMS provider and strict RBAC — `kubernetes-standards`). Before adopting it,
  know its history, because it changes the risk assessment:
  - **It is no longer `v0.x`**: 1.0 GA in Nov 2025, 2.0 in Feb 2026, today **2.8.0**. A **very
    short** support window: each minor dies when the next one ships.
  - **`v1beta1` is not deprecated: it was REMOVED in v0.17.0** (May 2025). Migration goes
    necessarily through v0.16.2, and **there is no official migration guide**. Added gotcha:
    in 0.16.x the webhook converts to `v1` even though it serves both, producing **permanent drift
    in Argo CD** if Git stays on `v1beta1`.
  - **Its own critical CVEs**: **CVE-2026-22822** (CVSS 9.3, `getSecretKey` retrieved
    **cross-namespace** secrets with the controller's rolebinding; fix 1.2.0),
    **CVE-2026-34984** (`getHostByName` in the templating engine → exfiltration via DNS; fix
    2.3.0), **CVE-2025-55196** (`PushSecret` without a namespace selector → cluster-wide read;
    fix 0.19.2). **Hard minimum: 2.3.0+.**
  - **Project health**: CNCF **Sandbox** since 2022 with no promotion; in Jul 2025 the
    maintainers **paused all releases** due to *burnout* and the CNCF TOC opened a
    **health review with an archiving checklist**; it was resolved with new governance, and
    the company backing it (*External Secrets Inc.*) **shut down in Nov 2025**. It is usable, but
    it goes into your risk register with an owner.
- **Secrets Store CSI Driver**: mounts the secret as a volume without creating a K8s `Secret`
  (unless you enable syncing, which cancels out the advantage). Preferable when the threat
  model includes "whoever reads etcd or has `get secrets` must not see this".
- **sealed-secrets / SOPS**: for GitOps **without** a manager. They are encryption in the repo, not secrets
  management: no rotation, no read auditing, no TTL, no revocation. Valid and KISS
  for a homelab and small teams; **their limit must be declared**, not discovered.
- **Vault/OpenBao on K8s**: **Vault Secrets Operator 1.5.0** (careful, *breaking*: it removes
  `spec.appRole.secretIDPath`) or **Vault Agent Injector (vault-k8s) 1.7.5**. HashiCorp does not
  recommend one over the other by default, but the **load on the manager does differ**: VSO is
  the lowest (per-node pool with cache), the CSI provider is in between, the **Agent Injector the
  highest** (sidecar per pod).

### 3.5 Where secrets actually leak

In order of observed frequency, not of drama:

- **Repository and Git history** (§3.8).
- **CI variables and logs**: `set -x`, debug `echo`, error output from an HTTP
  client. CI masking is **best effort**: it breaks with transformations (base64,
  chunking, escaped JSON) and **the payload of the Trivy compromise read the memory of the runner
  process precisely to bypass it**.
- **Container images and layers**: an `ARG`/`ENV` or a `COPY` of a file deleted in a
  later layer **is still in the image**. Use BuildKit's `--mount=type=secret`
  (`kubernetes-standards`).
- **Build artifacts and packaged configuration files**.
- **Terraform state** — in clear text by design (`iac-standards`).
- **Backups and snapshots**: if the backup contains the secret, the backup **is** the secret. Its
  encryption key lives outside the backed-up system (`cryptography-pki-standards`,
  `bcdr-standards`).
- **Telemetry**: URLs with a token in the query string, `Authorization` headers, request
  bodies, stack traces (`observability-standards`).
- **And the one almost nobody models: the compromised consumer.** The **Shai-Hulud** worm uses
  **TruffleHog** inside the victim's machine to harvest credentials, and its third
  wave (malicious `@bitwarden/cli` 2026.4.0, ~93 minutes on npm, Apr 2026) **directly emptied
  AWS Secrets Manager, SSM Parameter Store, GCP Secret Manager and Azure Key
  Vault** with the process's legitimate identity. **No manager protects you from a compromised
  consumer**: that is why the real defence is short TTLs, least privilege per identity and
  detection of anomalous reads — not the vault.

### 3.6 HA, sealing and the question nobody asks

**If the manager goes down, does your application start?** Answer it in writing before deploying it, not
during the outage:

- A manager on the critical startup path turns its unavailability into total
  unavailability. Mitigations: **in-memory cache with TTL** and degraded startup with the current
  credential; replicas and multi-AZ deployment; and **automatic unsealing** (auto-unseal against
  KMS/HSM) so that a restart does not require a human in the middle of the night.
- **Auto-unseal shifts the trust to the KMS**: if that KMS goes down or has its permissions withdrawn, the
  manager does not open. Document the procedure for **manual unsealing with a Shamir quorum**,
  with the keys held by different people and **the procedure rehearsed**. A recovery key
  nobody has tried to use is a key that does not exist.
- **In OpenBao, pay attention to the sealing changes**: `stored_shares` removed in 2.6.0
  and the built-in seals **leaving the binary in 2.7.0** towards external plugins.
- Backup of the manager (Raft snapshot) **encrypted, with the key outside the manager itself** and with
  **tested restore**. It is the only case where restoring badly means losing everything at once.
- **Watch its advisories like the kernel's.** Verified 2026 precedents: in OpenBao,
  **CVE-2026-63132** (CVSS 9.1, timing side channel in *recovery mode* that allowed extracting
  the recovery token; fix 2.6.0) and escalation via *wildcards* in templated policies (fix
  2.6.0); in Vault, **CVE-2026-5051** (bypass of the audit plugin directory guard),
  **CVE-2026-5052** (SSRF in the PKI engine's ACME challenge validation) and
  **CVE-2026-3605** (policy bypass by deleting KVv2 metadata via glob).

### 3.7 Humans ≠ machines

They are two problems with different solutions and **they do not get mixed**:

| | Human secrets | Machine secrets |
|---|---|---|
| Tool | Team password manager (shared vaults, MFA, recovery) | Service secrets manager (API, policies, TTL, auditing) |
| Unit | Person, with onboarding/offboarding | Workload identity, with the deployment's lifecycle |
| Goal | That nobody reuses or shares passwords | That the credential be dynamic and short-lived |
| Typical failure | Password shared over chat that outlives the departure of whoever created it | Static token from three years ago that nobody knows who uses |

Hard rule: **a credential a human can read and that a service also uses is a
credential that is already compromised for auditing purposes** — you cannot attribute its use.

### 3.8 Exposure response: rotate first, clean up afterwards

**A secret that has been in a repository, in a log or in a chat channel is burned.**
Rewriting history does not un-burn it: cloned, cached by the forge, indexed by bots
that sweep GitHub in seconds, and present in forks and in attackers' databases.

**Non-negotiable** order:
1. **Rotate/revoke the credential.** First. Before investigating how it got there.
2. **Verify the revocation** (that the old one no longer works) and **look for use** of the exposed
   credential in the logs from the moment of exposure — it is a case for
   `detection-engineering-standards`, and if there was use, an incident for
   `incident-response-forensics-standards`.
3. **Clean up the history** (`git filter-repo`, `git-workflow-standards`) and coordinate the
   force-push with whoever has clones.
4. **Fix the cause**: why the scan did not catch it earlier, why that static
   secret existed, and whether it could have been eliminated through federation.

**Reversing the order is forbidden.** "I'll delete it from the history and then we'll see" is the response that
turns a leak into a breach.

## 4. CI gates (they break the build)

1. **Local pre-commit + CI scan** of the diff with `gitleaks`/`betterleaks` — the pre-commit
   is convenience, **the CI gate is the control**, because the local hook is skipped with
   `--no-verify`.
2. **Full history scan** at least periodically (and always when opening a new repo
   or importing it): the diff only sees what arrives today.
3. **Forge push protection enabled**: on GitHub, free in public repos, but in
   private ones it requires **GitHub Secret Protection** (billed per *active committer*) and **at
   repo/organization level it is disabled by default** — enable it explicitly. On
   GitLab, **Secret Push Protection is Ultimate only** (GA in 17.5) and **it skips binaries,
   files > 1 MiB and pushes of more than 350,000 lines**: know its gaps, do not treat it as a
   total safety net.
4. **A finding = broken build + immediate rotation**, not a TODO nor a silent exception.
   Every suppression (`.gitleaksignore`, allowlist) carries a reason, an owner and an **expiry**.
5. **Scan of the built image and of the IaC state**, not just of the source code: the
   secrets appear in layers and in `terraform.tfstate`.
6. **Prohibition of static credentials in the pipeline**: a gate that fails if
   `AWS_ACCESS_KEY_ID`, a JSON service account key or a `client_secret` appears as a CI variable
   where OIDC exists (`cicd-standards`).
7. **Automated rotation test** in the pre-production environment: rotate, check that the
   service still works and that the old credential **no longer authenticates**. Without this, §3.3
   is an intention.
8. **Verification that the secret does not appear in the output**: a test that runs the service
   startup and fails if a known secret value appears in stdout/stderr or in the structured
   log.

## 5. Specific security

- **Least privilege all the way**: one identity, one set of secrets, read-only.
  The universal anti-pattern is the broad policy "so as not to block the team", which turns
  any compromise of any pod into total compromise.
- **Never pass secrets as command-line arguments** (visible in `ps`, in the
  shell history and in the process audit logs): file, stdin or environment variable
  of the process itself, in that order.
- **Never put them in the URL** (query string): they end up in access logs, in the `Referer` and
  in telemetry.
- **One secret per service and per environment.** Sharing a credential between services destroys
  attribution and multiplies the blast radius of every rotation.
- **The supply chain of the secrets tooling itself is attack surface**, and the
  precedent is explicit: the compromise of `tj-actions/changed-files` (**CVE-2025-30066**)
  dumped CI secrets into the build logs of more than 23,000 repositories, and the 2026 campaign
  against Trivy/Checkmarx stole CI credentials at scale. Consequence: **pin by SHA every
  action and by digest every image** that touches secrets, signature verification, and **restricted
  egress in the jobs that handle them**. Verified Aug 2026: **neither gitleaks, nor trufflehog,
  nor SOPS, nor ESO, nor sealed-secrets have suffered a supply chain compromise** — they have had
  their own vulnerabilities (§2.4, §3.4), which is a different thing.
- **OIDC federation: the trust policy is the control, and it changed in 2026.** GitHub Actions now issues
  **immutable subject claims** (`repo:org@<id>/repo@<id>:ref:...`), applied
  automatically since **15 Jul 2026** to new repos and to renamed or transferred ones:
  trust policies that match by path **break or, worse, stop matching what you
  thought**. In GitLab, `CI_JOB_JWT*` was **removed in 17.0** and the guidance is to trust by
  `project_id`/`namespace_id`, not by path (which a rename changes). In Azure, `issuer`,
  `subject` and `audience` are **case-sensitive** and there is a limit of **20 federated credentials
  per managed identity**. Never use broad wildcards in the `sub`.
- **No secrets in telemetry nor in error messages.** The "invalid credential" error
  does not print the credential, nor its prefix, nor its length.

## 6. Operability

- **Inventory**: which secrets exist, who consumes them, when they were last rotated and
  who the owner is. Without an inventory there is no possible emergency rotation, and therefore no
  compromise response.
- **Cache in the consumer with a TTL** so as not to turn every request into a call to the manager
  (cost, latency and a point of failure per operation). Cache in memory, **never on disk in
  clear text**, and respect the TTL as an upper bound.
- **Real cost**: AWS Secrets Manager bills ~0.40 USD per secret per month plus calls — a
  "one secret per microservice per environment" pattern shows up in the bill and pushes towards the
  anti-pattern of grouping everything into one giant shared secret. Design the granularity with
  cost and blast radius on the table.
- **Observability of the manager**: read latency and error rate, active leases, seal
  state, and **the age of the oldest unrotated secret** as a published metric.
- **Decommissioning**: when a service dies, its secrets and its policies are deleted in the same
  PR. Orphaned credentials are the residue with the highest return for an attacker.

## 7. Sustainability and prohibitions

- **Cadence**: review the manager's advisories (monthly — it has criticals regularly),
  the version of ESO/CSI driver/sealed-secrets (their support window is short), and **auditing of
  accesses and pruning of permissions and dead secrets, quarterly**.
- **Governance risks in the register, with an owner and a review date**: Vault's BUSL licence
  under IBM, the Sandbox level and the SOPS health review in the CNCF, the trajectory
  of ESO after the shutdown of the company backing it, and the *feature complete* status of
  gitleaks. None is cause for panic; all are cause for a written plan B.
- Every exception (static secret that cannot be eliminated, long TTL, broad policy) carries
  **a reason, an owner and an exit date**.

**FORBIDDEN**
- ❌ Storing a static secret where **short-lived federated identity** would have fit.
- ❌ Secrets in code, in the Git history, in `values.yaml`, in `*.tfvars`, in the state,
  in a Dockerfile's `ENV`/`ARG`, in image layers, in logs or in chat channels.
- ❌ Secrets as **command-line arguments** or in a URL's query string.
- ❌ **Environment variables as the default injection mechanism** (§2.3).
- ❌ **Rewriting the history before rotating**: rotate first, clean up afterwards. Always.
- ❌ Assuming an exposed secret is safe because "the repo was private" or "it was deleted straight away".
- ❌ Rotation documented but **never executed**; quorum unsealing procedure
  never rehearsed; manager backup without a tested restore.
- ❌ A credential shared between services, between environments, or between a human and a
  service.
- ❌ Wildcard policies over the manager, or OIDC trust policies with a wildcard `sub`.
- ❌ Secrets manager **with no audit device configured** and with that log unmonitored.
- ❌ A manager on the critical startup path **without having answered** what happens when it goes down.
- ❌ Treating `sealed-secrets` or SOPS as a substitute for a manager when rotation,
  revocation or read auditing is needed.
- ❌ Using `gitleaks-action` v2 without knowing its **commercial licence** and its end of
  operation (16 Sep 2026); relying only on the pre-commit hook with no CI gate.
- ❌ Pointing sealed-secrets at `bitnamilegacy/*` (frozen image with no patches).
- ❌ ESO below 2.3.0, sealed-secrets below 0.36.0, or any manager with a published critical
  CVE left unpatched.
- ❌ Starting something new on `detect-secrets` or Nosey Parker (unmaintained / archived).
- ❌ Actions or images by **mutable tag** in pipelines that handle secrets.

## 8. Mandatory web verification

Before pinning a version, licence, governance or behaviour, **look it up — do not recall it**.
Data verified Aug 2026 (the most volatile in the catalogue): Vault **2.0.3**, **BUSL 1.1 with no
change**, *Licensor* now **IBM** (acquisition closed 27 Feb 2025), new IBM support cycle
and **Community with no LTS**; OpenBao **2.6.1**, **MPL-2.0**, **OpenSSF/LF Sandbox level**;
Infisical **0.162.15**; `bws` **2.1.0**; ESO **2.8.0**; Secrets Store CSI Driver **1.6.0**;
sealed-secrets **0.38.4**; Vault Secrets Operator **1.5.0**; vault-k8s **1.7.5**; SOPS
**3.13.3** (CNCF Sandbox, open health issue); age **1.3.1**; gitleaks **8.30.1** (feature
complete) and Betterleaks **1.7.3**; trufflehog **3.96.0**; SPIRE **1.15.2** (SPIFFE/SPIRE
graduated in the CNCF); systemd **v261**.

1. **Vault's licence under IBM** and **OpenBao's real level in the Linux Foundation/OpenSSF**:
   it is the pair of facts most often misquoted. Read it from the `LICENSE` file and from the project's
   page, not from a blog.
2. **Vault↔OpenBao divergence** before assuming portability: built-in seals leaving the
   binary in 2.7.0, `stored_shares`, namespace semantics, replication.
3. **The manager's advisories** (HashiCorp's HCSEC, OpenBao security advisories): both
   published criticals in 2026.
4. **Maintenance status** of gitleaks/Betterleaks, SOPS (health issue in the CNCF), ESO
   and sealed-secrets before betting the pipeline on any of them.
5. **Current OIDC claims and trust policies** from GitHub/GitLab towards AWS/Azure/GCP: GitHub's immutable
   subject claims changed format in 2026 and break existing policies.
6. **Rotation mechanism and cost** of the specific cloud manager: none of the three rotates
   everything automatically, and what managed rotation covers changes every quarter.
7. **systemd credential directives** and their minimum version in your distribution before
   basing a deployment on them (`SetCredential=`/`LoadCredential=` since 247;
   `LoadCredentialEncrypted=`/`SetCredentialEncrypted=`/`systemd-creds` since 250;
   `ImportCredential=` since 254).
8. **Supply chain compromises** of any new tool in the secrets pipeline
   before adopting it.

**Declared gaps — not verified in this document, verify them yourself before using them**:
- **OpenBao's exact level in the OpenSSF today** (Sandbox according to the project's page; one
  reading of the index suggested "Incubation" and **no locatable promotion announcement exists**), and
  the **LF Edge entry/exit dates**.
- The comparison of **Vault features absent in OpenBao** (DR/performance replication,
  automated snapshots, Sentinel) comes from a **secondary source**.
- **Formal outcome of ESO's incubation application in the CNCF** (issue closed, with no
  publicly located resolution).
- **Existence and version of `ImportCredentialEx=`** in systemd, and the **exact mode/owner
  of the files** in `$CREDENTIALS_DIRECTORY` (the documentation was not accessible).
- **Exact date of systemd v261**.
- **Specific CIS or NIST SP 800-190 guidance** against environment variables for
  secrets: the argument in §2.3 rests on systemd and OWASP, **not** on NIST/CIS.
- **Who nominally maintains** the `gitleaks/gitleaks` repository today, and the tiers of
  gitleaks.io.
- **Existence of a Secret Store extension for AKS in the cloud** (the located documentation
  covers Arc-enabled Kubernetes; for AKS the supported path is the CSI driver add-on).
- **Maximum federated credentials per app registration** in Entra (the verified limit of 20
  is per *managed identity*).
- **Exact CVSS** of several 2026 Vault CVEs and CVE-IDs of some HCSEC bulletins.
- **Any incident not published via GHSA** in SaaS managers (Doppler and equivalents were not
  consulted).

If the web contradicts this document, **the web wins** — flag the discrepancy.
