---
name: cloud-security-posture-standards
description: Cloud security posture as a transversal discipline across AWS, Azure and Google Cloud at once — what the per-provider skills cannot answer. Use when deciding what CSPM, CWPP, CIEM and CNAPP actually mean and which problem each one solves, choosing between open tooling (Prowler, ScoutSuite, CloudSploit, Steampipe and Powerpipe mods, Cartography, Cloud Custodian, Checkov, Conftest) and a commercial posture suite, running a CIS Foundations Benchmark assessment across several accounts, subscriptions or projects at once, building a multi-account or multi-tenant baseline and landing-zone guardrails, preferring preventive policy-as-code in the pipeline and in admission over after-the-fact findings, measuring effective permissions versus granted permissions and hunting wildcard or unused entitlements that no vulnerability scanner will ever report, replacing a flat list of findings with attack-path or toxic-combination analysis, inventorying internet-exposed resources, reconciling declared infrastructure against what actually exists (posture drift), replacing static long-lived cloud access keys with workload identity and OIDC federation, scoping the posture tool's own reader role so it cannot read every secret in the estate, or writing the buy-versus-build criterion for posture tooling.
---

# Cloud security posture standards (CSPM/CNAPP)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **cloud security seen from above and across all three providers at once**: what
each acronym in the market means and which problem it solves, how a baseline is established and measured
over dozens of accounts/subscriptions/projects, how the barrier is placed **beforehand** (policy
as code in the pipeline and in admission) instead of counting findings afterwards, how the
**effective permission** is measured against the granted one, how you go from a list of findings to **attack
paths**, how what is exposed to the Internet is inventoried, how the drift between what is declared
in IaC and what is real is detected, and with what criteria the tool is bought or built.

Triggers: "CSPM", "CWPP", "CIEM", "CNAPP", "KSPM", "DSPM", "cloud security posture",
"cloud CIS benchmark", `prowler`, `prowler aws|azure|gcp|kubernetes`, `scout aws`,
`cloudsploit`, `steampipe query`, `powerpipe benchmark run`, `cartography`, `custodian run`,
`checkov -d`, `conftest test`, "landing zone", "guardrail", "multi-account baseline",
"effective permissions", "unused permissions", "wildcard role", `"Action": "*"`, "Owner on the
subscription", `roles/owner`, "attack path", "toxic combination", "internet-exposed
resource", "public bucket", "configuration drift", "static access key", "pipeline OIDC
federation", "which CNAPP do we buy?".

**Guiding principle**: **in the cloud the dominant failure is not the exploit, it is the configuration and the
permission.** The control plane is an authenticated public API; whoever has the right credential or role
does not need to exploit anything. Corollaries that order the document:

1. **A role with `*:*` is not a vulnerability for any scanner** — it has no CVE, no CVSS
   and it does not show up in `vulnerability-management`. It is the real finding and it must be hunted with another
   tool and another data model (§3.3).
2. **Preventing is cheaper than detecting.** A `deny` in admission costs a policy; the same
   failure detected in production costs a ticket, a change window, an owner who argues and
   an exception that survives three years (§3.2).
3. **A list of 12,000 findings is not posture, it is a landfill.** What decides is the path:
   which exposed thing reaches which identity and from there which data (§3.4).
4. **The agent that audits is one more privileged user** (§5). A "read-only" role that can
   read every secret is an administrator role by another name.

**Defensive and authorised posture.** Everything here is run on your own environments or with
written authorisation. This document contains no exploitation: it describes **risk class,
evidence and control**.

**Not applicable**: see `aws-standards`, `azure-standards` and `gcp-standards` (**the specific service and
its secure configuration are theirs, without exception**: which service to choose, which flag to enable, which
managed findings product to use and what it costs. **Here the transversal part**: the criteria that do not
change when you change provider —which acronym solves what, how effective permission is measured, how you
prioritise by attack path, which baseline is required in all three— and the **multi-cloud** problem,
which none of the three can solve from the inside. Arbitration rule: *if the answer changes
when you change provider, it is theirs; if it is the same in all three, it belongs here*), `iac-standards` (**the
code that creates the resource**: modules, state, backend, and the IaC scanner as a tool —
here, the drift between that code and reality, and why the policy must also exist
outside the pipeline), `kubernetes-standards` (**the cluster and its admission**: Kyverno/Gatekeeper, Pod
Security Standards, manifests; the KSPM sold inside a CNAPP is their turf),
`container-runtime-security-standards` (**the container already running**: seccomp, escape, Falco —
the suites' "runtime CWPP" is theirs), `detection-engineering-standards` (**the detection
rule over the control-plane log is theirs, without exception**; here only which configuration
and which permission matter and why), `soc-operations-standards` (shift, queue and triage of whatever
the tool generates), `incident-response-forensics-standards` (the already-confirmed compromise in
the cloud and its acquisition), `identity-access-management-standards` (**the design of identity**:
IdP, SSO, MFA, joiner-mover-leaver lifecycle, authorisation engines, SPIFFE; here only the **measurement
of the effective entitlement** over cloud resources and the replacement of the static key with
federation), `identity-threat-detection-standards` (**sister skill**: the **attack** against that
identity, its detection and its response — here the badly set permission in the cold, there the stolen token
in the heat), `vulnerability-management-standards` (**CVE, CVSS/EPSS/KEV and remediation SLAs**:
the vulnerable workload is triaged there; here why excessive permission never enters that
funnel), `appsec-standards` (the flaw in the application code), `secrets-management-standards`
(custody and rotation of the secret; here only who can read it), `cicd-standards` (the pipeline and its
OIDC), `grc-compliance-standards` (**the framework, the SoA and the audit evidence are theirs**: here
the benchmark as a measurable technical control, not as a compliance report),
`finops-standards` (cost of the tool and of the ingestion), `privacy-engineering-standards`
(the personal data inside the bucket declared as exposed), `platform-engineering-standards`
(the paved road that makes the guardrail painless), `datacenter-facilities-standards`
(the physical world, which does not exist here).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

**Licences read verbatim from the repository's `LICENSE` (August 2026)** — not from the web nor from
memory. This point has produced expensive errors in the catalogue:

| Tool | Role | Last seen (Aug 2026) | Licence (verbatim from `LICENSE`) |
|---|---|---|---|
| **Prowler** (`prowler-cloud/prowler`) | Multi-cloud, multi-account benchmark assessment | `5.37.1` | **Apache-2.0** |
| **ScoutSuite** (`nccgroup/ScoutSuite`) | Per-provider posture report, HTML output | `5.14.0` (2024-05-10) | **GPL-2.0** ⚠️ copyleft |
| **CloudSploit** (`aquasecurity/cloudsploit`) | Configuration checks | see §8 | **GPL-3.0** ⚠️ copyleft |
| **Steampipe** (`turbot/steampipe`) | Cloud as SQL: inventory and ad-hoc querying | `v2.4.4` | **AGPL-3.0** ⚠️ network copyleft |
| **Powerpipe** (`turbot/powerpipe`) | Benchmarks and dashboards over Steampipe | `v1.5.2` | **AGPL-3.0** ⚠️ network copyleft |
| **Cartography** (`cartography-cncf/cartography`) | Graph of assets and relationships in Neo4j | `0.139.1` | **Apache-2.0** |
| **Cloud Custodian** (`cloud-custodian`) | Policy + **remediation** as code | see §8 | **Apache-2.0** |
| **Checkov** (`bridgecrewio/checkov`) | Policy over IaC before the `apply` | `3.3.9` | **Apache-2.0** |
| **OPA / Conftest** | Generic policy and CI gate | see §8 | **Apache-2.0** |

Notes that change decisions, not decoration:
- **AGPL-3.0 in Steampipe and Powerpipe**: if a posture dashboard is offered **as a service** to
  third parties, the AGPL triggers its network clause. Internal use does not trigger it. Decide with
  `opensource-licensing-standards`, not here, but **do not assume "it is open source, it does not matter"**.
- **GPL-2.0 in ScoutSuite and GPL-3.0 in CloudSploit**: incompatible with embedding them inside a
  proprietary product. Running them as an external tool and consuming their output is not deriving.
- **ScoutSuite has had no release since 2024-05-10** (verified in the releases API). It is not
  disqualifying for one-off use, but **service coverage frozen in 2024 lies by omission**
  about everything the provider has released since. Verify the repository's activity
  before relying on it (§8).

Default decisions:

| Decision | Default | Justifiable alternative |
|---|---|---|
| First step in an unknown environment | **Prowler** against all three clouds with the CIS profile, in read mode | ScoutSuite if a browsable single-provider report is wanted |
| Inventory and cross-cutting questions | **Steampipe/Powerpipe** (SQL) or **Cartography** (graph) | The provider's native inventory if there is no multi-cloud |
| Attack path | **Cartography** + your own Cypher queries | A commercial suite if the graph has to cover identity + vulnerability + data |
| Prevention | **Checkov/Conftest in the pipeline** + the provider's native policy in the control plane | Pipeline only, solely if the `apply` is the **only** road to production — and it almost never is |
| Automatic remediation | **Cloud Custodian** in `--dryrun` mode first, and only for bounded classes | None: notify the owner (the default for anything that could take a service down) |
| Tool authentication | **Assumable role / workload identity with OIDC federation** | Never a long-lived static key (§5) |

**Buy-versus-build criterion, one line per axis**: the open tool gives you
**checks**; the commercial suite sells you **correlation**. If your problem is "I do not know what I have", the
open stuff is more than enough. If your problem is "I have 40,000 findings and I do not know which one kills", what you buy is
prioritisation by attack path, and **that is exactly what has to be tested in the PoC with your
data**, not in the vendor's demo. Knockout questions for a CNAPP: does it compute **effective
permission** or only list policies? Does it know whether the resource is **actually reachable** from the Internet or
only whether the security group is `0.0.0.0/0`? Which permissions does its role require and **can it read secrets**
(§5)? Does it export findings to your SIEM in a format that is not its own?

**About the taxonomy**: CSPM, CWPP, CIEM, CNAPP, KSPM, DSPM and CDR are **analyst categories**,
coined by Gartner and adopted by marketing. They describe markets, not architectures. Their
usefulness is bounding the purchasing conversation; their damage is making you believe you need seven
products. Honest translation, without the acronym:
- **CSPM** = is the control plane configured correctly?
- **CWPP** = is the workload running on top healthy (VM, container, function)?
- **CIEM** = who can do what, really?
- **CNAPP** = all of the above in one product, with **a graph** that correlates them — and that graph is
  the only thing that justifies the bundle over buying them separately.

## 3. Structure and conventions

### 3.1 Multi-account baseline and landing zone

The unit of isolation is **the account / subscription / project**, and the baseline is applied **in
the hierarchy**, not resource by resource. Invariants, the same in all three clouds (the specific mechanism
is provided by the provider's skill):

- **Organisational hierarchy before any control**: without an organisational unit / management
  group / folder there is nowhere to hang the policy, and it ends up being copied N times.
- **Inherited preventive barrier** at the root (SCP / Azure Policy `Deny` / organisation policy),
  which **no administrator of the child account can disable**. That is the point: a guardrail
  that the resource owner can remove is not a guardrail.
- **Centralised audit log, in a separate account, with write but not delete** from
  the producing accounts. If the attacker who compromises the account can delete their trail, there is no
  possible investigation (boundary with `incident-response-forensics-standards`).
- **New account = baseline applied on day 0**, via automated vending. An account created by
  hand is a permanent hole because it never appears in the scan's scope.
- **The scan covers 100 % of the accounts or it means nothing.** The metric that matters is not
  "findings resolved", it is **coverage**: how many accounts/subscriptions/projects exist and in
  how many the assessment is run. Everything else is measured over a false denominator.

Benchmarks: **CIS Foundations Benchmark** per provider as the minimum auditable baseline. The
versions move every year and **they are not comparable with each other** (a renumbered control is not a
new control). Verified in August 2026: **CIS Microsoft Azure Foundations Benchmark v6.0.0**
and **CIS Google Cloud Platform Foundation Benchmark v5.0.0** appear as current in NIST's
NCP; **the current version of the AWS one could not be confirmed against a primary source** — verify at
`cisecurity.org` before quoting it (§8). Operational warning: **the benchmark is a floor, not a ceiling**. Meeting
CIS 100 % and having a role with `*:*` is perfectly possible.

### 3.2 Preventive guardrail versus after-the-fact finding

Three layers, in increasing order of cost per failure detected:

1. **Code (IaC)**: `checkov`/`conftest` in the PR. Cost of the failure: a comment.
2. **Admission / control plane**: the provider's native policy that **rejects** the creation, and
   admission in the cluster (that part belongs to `kubernetes-standards`). Cost: an error in the `apply`.
3. **Posture (detection)**: the periodic scan that finds what slipped through. Cost: ticket,
   owner, window, argument and exception.

**Layer 3 does not replace 1 and 2, and 1 does not replace 2**: there are more roads to production
than the pipeline (console, CLI, an operator, a service that creates resources on its own). A
policy that only lives in the IaC repository protects exactly the team that was already doing things
right. Rule: **every posture rule that repeats should become a preventive
barrier or disappear**; if a finding shows up 200 times a month, the problem is not the finding,
it is that there is no `deny`.

Honest counterpart: the preventive barrier breaks things and generates exceptions. That is why it is deployed
in **audit mode first**, with a metric of how many times it would have blocked and whom, and it is
promoted to `deny` with that evidence. An exception **carries an owner and an expiry**; without an expiry it is a
repeal.

### 3.3 Excessive permission: effective entitlement versus granted entitlement

This is the finding nobody reports and the one that decides the blast radius of a compromise.

- **Granted entitlement** = what the attached policies say. **Effective entitlement** = what the
  identity can actually do, after resolving **hierarchy inheritance, boundary policies,
  explicit denies, conditions, resource-based policies, role assumption chains and
  service account impersonation**. They almost never match, and the difference goes both
  ways: there are roles that look broad and are bounded by a condition, and roles that look
  bounded and can escalate to administrator **by chaining an `iam:PassRole` permission,
  impersonation or editing the policy itself**.
- **The escalation permission is the one to hunt first**: whoever can modify policies,
  create credentials for another identity, attach a role to themselves or deploy code in a
  privileged context **is already an administrator**, whatever their name says.
- **The wildcard is the cheap symptom**: `*:*`, `Owner` over the subscription, `roles/owner`,
  `roles/editor` at project level. A mandatory search with immediate results, but
  insufficient.
- **Permission granted and not used**: almost every cloud exposes the last time a
  service or permission was used per identity. **It is the only objective source for reducing without breaking**: it
  is trimmed to what was used in a representative window (careful with quarterly and annual things: closes,
  audits and DR use permissions once a year).
- **Path to reduction without drama**: log → propose a minimal policy derived from usage →
  apply **in audit mode** → measure the denials that would have occurred → apply. Trimming
  blind is the fastest way for the security team to lose permission to touch IAM.
- **Non-human identities > human ones** in number, in permissions and in being forgotten. The service account of
  a dead project still has `editor`. The inventory of **non-human** identities with their
  owner is a deliverable, not a note.

### 3.4 Attack path versus list of findings

What makes a posture tool useful or useless: **if it gives you independent findings, the
correlation work stays with you**. What matters is the combination:

> A machine reachable from the Internet → with an exploitable vulnerability → whose instance role
> can read a store with regulated data → and can also assume a role in another account.

None of those four facts is critical on its own; together they are the incident. Practical
consequences:
- **The severity of an isolated finding is almost always false** (high or low). Context sets it:
  real exposure, sensitivity of the reachable data and privilege of the identity involved.
- **"Internet-exposed" has to be computed, not declared**: open security group + public
  IP + route + network access control list + resource policy + load balancer in front.
  A "public" bucket behind a policy that denies everything is not; a "private" machine
  behind a public load balancer is.
- **Without an inventory there is no path**: the graph (Cartography or equivalent) is a prerequisite. The
  boundary with `cmdb-inventory-standards` is that the asset record lives there and here the security
  relationships between them.
- Useful metric: **the number of paths from the Internet to classified data**, and its evolution. It is
  a small number, understandable by management, and it drops when things actually get fixed.

### 3.5 Drift between what is declared and what is real

- Posture is assessed **against the live environment**, not against the repository. The IaC scan says
  what was intended; the cloud says what is there.
- **Every difference is a signal**, and there are three causes: a manual change (fix and prevent), a resource
  created outside IaC (adopt or delete), or the provider itself changing defaults (read the notes).
- **A resource with no identifiable owner = a governance incident**, not a minor finding: you cannot
  fix what has nobody to ask. A mandatory owner tag, **verified at
  admission**, not on a spreadsheet (the tagging policy is set by `finops-standards`; here
  only the requirement that it exist).

## 4. Quality and testing

- **Policy is code and it is tested as code**: every custom `conftest`/`checkov` rule carries
  a case that **must** fail and another that **must** pass. A policy without a negative test is not
  tested: it always passes.
- **CI gates, in increasing order of cost**: (1) lint and unit test of the policies;
  (2) `checkov`/`conftest` over the plan/template, breaking the build on high severity;
  (3) posture assessment over an ephemeral environment or a test account; (4) full scheduled scan
  of the estate, which does not break the build but opens work.
- **Validate the barrier, not just write it**: deploy a deliberately non-compliant resource in a
  test environment and check that the `deny` fires. A badly scoped policy that
  applies to nothing is indistinguishable from one that works, except through this test.
- **False negatives before false positives**: the question to ask the tool is not "how many
  findings does it give?" but "what does it NOT see?". Services with no coverage, unscanned regions, missing
  accounts and unknown resource types are silent gaps. Demand the **coverage
  inventory** by service and region.
- **Exception regression**: every exception with an expiry has a test that reopens it when it expires.
- **No gate on the aggregate score**: "posture score 87 %" is a vendor metric.
  It goes up by cleaning out empty accounts. Measure by coverage, by number of attack paths and by
  time to fix what is reachable from the Internet.

## 5. Stack security

**The posture tool is the most privileged asset you are going to deploy.** It reads the whole
estate, in every account, continuously. Treating it as one more utility is the
recurring mistake.

- **"Read-only" does not mean harmless.** The broad read roles offered by the
  providers **include reading the content of secrets, of parameters and of sensitive
  configuration** in several services. An audit role that can read the secrets manager is a
  deferred administrator role: whoever compromises the scanner has the credentials to everything
  else. **Verify permission by permission what the read role the vendor asks for implies, and
  explicitly deny reading secret material** unless there is a specific justification.
- **OIDC federation, never a static key.** The posture SaaS that asks for a long-lived
  key pair is asking for the master key with no expiry. An assumable role with a condition on the
  tenant's external identifier (or its equivalent), and **verify that that identifier is unique
  per customer**: if it is guessable, any other customer of the same SaaS can assume your role —
  the *confused deputy* problem, real and documented in this kind of integration.
- **Deployment model**: agent in your account > SaaS assuming a role in your account > SaaS with a copy
  of your inventory. Each step to the right adds a third party holding the complete map of your
  attack surface. If SaaS is chosen, that decision is third-party risk and it goes to
  `grc-compliance-standards` with a name attached.
- **No write permissions by default.** Automatic remediation requires change permissions, and
  with them the scanner becomes able to **delete** production. If it is enabled: minimal scope, explicit
  allowlisted action classes, mandatory `dry-run` first, logging of every action and
  the ability to undo.
- **Findings are intelligence about your own weakness**: the posture report describes
  exactly where to attack. It is handled with the same access control as a pentest result.
- **Drift in the scanner's own permission** is watched: if someone broadens the audit role,
  that is an alert, not an administrative change.
- **Long-lived static credentials in general**: they are the finding with the best
  effort/value ratio in the whole catalogue. Inventory them, measure age and last use, replace with
  workload identity and **forbid them by preventive policy**, not by reminder.

## 6. Performance and operability

- **The provider's API limits**: a full scan of a large estate consumes control-plane
  quota and can degrade everything else. Stagger it by account and region, respect the *backoff* and
  measure. A scan that causes `429` for the application is an incident caused by security.
- **Cadence by class, not a single one**: identity and Internet-exposure changes, continuously
  (from control-plane events); full benchmark, daily or weekly; path graph, at whatever
  cadence the cost supports.
- **Cost**: control-plane event ingestion and inventory storage are the real
  bill of a CSPM, not the licence. Size it beforehand (`finops-standards`).
- **Noise**: a product that delivers thousands of findings on day one has not found thousands of
  problems; it has found an environment with no baseline. An **initial cut line** is established
  (everything before date X enters as debt with a plan) and from there the new flow is worked. Without that cut,
  the team gives up in two weeks.
- **An owner per finding or there is no process**: automatic routing by owner/account tag to the
  responsible team. A central dashboard nobody looks at is the default end state.
- **Open output**: require export (SARIF, OCSF, documented JSON) so as not to depend on the vendor's
  dashboard and to be able to correlate in the SIEM.

## 7. Long-term sustainability

- The clouds publish services and change *defaults* continuously: **the tool's coverage
  expires on its own**. Quarterly review of which new services are in use and whether they are covered.
- The benchmark version **explicitly pinned** in the configuration and updated as a conscious
  change, with a note on which controls have been added or renumbered. Jumping versions without reading the
  diff produces a spike of findings that looks like a regression and is not.
- Exceptions are reviewed every cycle; **expired ones reopen by themselves**.

**FORBIDDEN**:
- ❌ Duplicating here the criteria of `aws`/`azure`/`gcp` on how a specific service is configured.
- ❌ Accepting a tool's licence **without reading the repository's `LICENSE`**. False
  assumptions have already cost sixteen corrections in this catalogue.
- ❌ Long-lived static access keys for humans, for pipelines or for the scanner itself.
- ❌ Granting the scanner write permissions "just in case", or accepting without review the
  read role the vendor asks for.
- ❌ Presenting a **posture score** as a management metric, or "0 critical findings"
  over a scope that does not cover every account.
- ❌ Treating excessive permission as a vulnerability management finding: **it has no CVE and it does
  not enter that funnel**; if it is put there, it gets lost.
- ❌ Automatic remediation over unbounded classes, without a prior `dry-run` and without logging.
- ❌ Exceptions with no owner and no expiry date.
- ❌ Quoting **"99 % of cloud security failures will be the customer's fault"** as if it were
  a measurement. It is a Gartner **prediction** (a direct descendant of an earlier one of "at least
  95 % through 2022"), with a 2025 horizon, repeated by hundreds of sources that have turned it into
  established fact, changed its date and replaced "customer's responsibility under the
  shared responsibility model" with "user error". **The underlying thesis —the dominant failure
  is in configuration and permission, not in the provider's hypervisor— stands without
  needing that number.** If a figure must be quoted, let it come with methodology; if it has none,
  state the argument and omit the percentage.
- ❌ Buying a CNAPP without a PoC on your own data over the two questions that decide it: effective
  permission and real reachability from the Internet.
- ❌ Running any assessment on third-party environments without written authorisation.

## 8. Mandatory web verification

Before committing anything in a real project, check on the web:
1. **Current version of each CIS Foundations Benchmark** (AWS, Azure, GCP) at `cisecurity.org`.
   **Declared gap**: in August 2026 Azure v6.0.0 and GCP v5.0.0 were confirmed from a secondary source (NIST's NCP);
   **the current version of the AWS one could not be verified against a primary
   source and is not written here**.
2. **Latest version and activity** of Prowler, ScoutSuite, CloudSploit, Steampipe, Powerpipe,
   Cartography, Cloud Custodian and Checkov. Seen in August 2026 via the releases API:
   Prowler `5.37.1`, ScoutSuite `5.14.0` (2024-05-10, **no release since then**), Checkov
   `3.3.9`, Cartography `0.139.1`, Steampipe `v2.4.4`, Powerpipe `v1.5.2`.
3. **The licence, by re-reading the repository's `LICENSE`** — not the website nor an aggregator's entry.
   Verified verbatim in August 2026: Prowler Apache-2.0, ScoutSuite GPL-2.0, CloudSploit
   GPL-3.0, Steampipe AGPL-3.0, Powerpipe AGPL-3.0, Cartography Apache-2.0, Cloud Custodian
   Apache-2.0, Checkov Apache-2.0, OPA/Conftest Apache-2.0. **Also check whether the project has
   relicensed or split out paid components since then.**
4. **Provider *default* changes** that invalidate a control (public access block,
   encryption by default, minimum TLS versions): the cloud's skill rules.
5. **The exact permissions of the audit role** each tool asks for, and whether the provider's read role
   includes reading secrets. It changes between versions.
6. **Any figure** before quoting it: primary source, methodology and denominator. Those in this
   document have been quoted only where all three exist.
7. The status of **Cartography in the CNCF** (the repository now lives under the `cartography-cncf` organisation)
   and its maturity level, if that weighs on the adoption decision.

If the web contradicts this document, **the web wins** — flag the discrepancy.
