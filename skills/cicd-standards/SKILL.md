---
name: cicd-standards
description: CI/CD standards for GitHub Actions and GitLab CI. Use when creating or reviewing pipelines, workflows, .github/workflows/*.yml, .gitlab-ci.yml, runners, deploy/release automation, OIDC cloud auth, SBOM/signing (cosign, SLSA), or CI security gates.
---

# CI/CD standards — GitHub Actions and GitLab CI

Criteria verified against the state of the ecosystem in **August 2026**. For any concrete data point
(action version, flag, OIDC claim), **verify on the web before pinning it** (section 8).

## 1. Scope and triggers

Applies when creating, modifying or reviewing:
- `.github/workflows/*.yml`, composite/reusable actions, `dependabot.yml`, rulesets.
- `.gitlab-ci.yml`, templates/`include`, GitLab Runners.
- Any build, test, release or deploy pipeline; scripts invoked from CI.
- Runner configuration (self-hosted or managed) and its hardening.
- **Artifact supply chain**: SBOM, signing (cosign/Sigstore), SLSA provenance and its
  verification before deploying. There is no separate supply chain skill: it lives here.

**Not applicable**: see `git-workflow-standards` (branching strategy, Conventional Commits, PR size,
CODEOWNERS, branch protection, SemVer and CHANGELOG: this skill assumes the repo is already governed
by that one and starts where the event fires the pipeline), `iac-standards` (how the
Terraform/Ansible code the pipeline applies is written), `kubernetes-standards` (the `Dockerfile`, the manifest and
the admission policy that verifies the signature at the destination), `aws-standards`/`azure-standards`/
`gcp-standards` (which federated role/identity exists on the other side of the OIDC and what permissions it carries),
`appsec-standards` (methodology and triage of the findings the SAST/DAST/SCA gates produce;
here only their **execution** and breaking threshold), `vulnerability-management-standards` (remediation
SLA and VEX for those findings), `cryptography-pki-standards` (choice of algorithms, custody
and rotation of the signing keys; here only their use from the pipeline),
`identity-access-management-standards` (IdP design; here the job's ephemeral identity),
`sre-practice-standards` (deployment strategy from the reliability angle: canary, error
budget, rollback as an operational decision), `bash-linux-scripting-standards` and `powershell-standards` (the scripts the
pipeline invokes; the second one, in addition, on Windows runners and in the `pwsh` step),
`groovy-standards` (**critical boundary with Jenkins, mirrored from its §1**: **pipeline
strategy, gates, signing, SBOM, OIDC and runner security are decided here**; **how the
`Jenkinsfile` is written as Groovy code** —declarative versus *scripted*, CPS and `@NonCPS`,
Shared Libraries, the Script Security sandbox and script approval— **is theirs**. The rule
neither side negotiates: **FORBIDDEN to disable the sandbox**), `observability-standards` (DORA metrics and telemetry of the pipeline itself), `opensource-licensing-standards` (**the pipeline runs the licence gate** —the
runner, the job, the cache and the artifact signature belong here—; **the threshold, the list of allowed
licences, the exception process and what breaks the build are theirs**. And the SBOM this skill already
generates for signing and provenance **has a second consumer**: licence obligations),
`platform-engineering-standards` (**the design of the concrete pipeline, its gates and its
security belong here**; **that a pipeline template exists in the paved road, who maintains it
and how it is deprecated, is theirs**), `finops-standards` (the cost of CI itself
—runner minutes, caches, artifacts— is one more economic unit and is measured with their method),
`developer-workstation-standards` (**parity between what runs locally and what
runs here**: the same runtime version, the same formatter and the same linter, pinned in the
repository and not on the machine. **If the gate only fails in CI, the problem is workstation
provisioning, not the pipeline**), `ai-agent-workflow-standards` (**the agent that runs
in a job is one more identity and its token and scope are bounded here**; which task is delegated to it and
how its change is reviewed, there), `testing-qa-standards` (**the pipeline and the threshold that breaks the build belong here**;
**what is tested, in what proportion and with what quality criteria, there**), `code-review-standards`
(what a machine checks before the merge belongs here; **what a person reviews and
with what criteria, there** — and the rule both share: **if formatting is discussed in a review,
a formatter is missing from this pipeline**), `accessibility-standards` and `web-performance-standards`
(the gate runs here; **the conformance criteria and the threshold are set by them**),
`solidity-standards`
(the pipeline and its generic gates belong here; **the specific gate for deploying a
contract is theirs and is harder than that of any other artifact** — nothing is deployed without invariant
tests, without an external audit and without an on-chain incident plan written **beforehand**, because
there is no rollback).

## 2. Default decisions

> Note: every version/feature cited here expires. Verified Aug 2026; re-verify on the web
> before encoding it in a new pipeline (section 8).

| Decision | Default | Forbidden |
|---|---|---|
| Cloud authentication | **OIDC/workload identity federation** (GH: `id-token: write`; GitLab: `id_tokens`) | Static credentials (`AWS_ACCESS_KEY_ID`, SA keys JSON) in variables/secrets |
| Action references | **Pin by full commit SHA** + comment with the version; Dependabot/Renovate to update them | `@main`, `@master`, mutable tags without a SHA pinning policy |
| GH artifacts | `actions/upload-artifact`/`download-artifact` **v4+** (v6/v7 with Node 24 runtime; v3 fails since 2025-01-30) | v3 or earlier |
| Action runtime | **Node 24** (Node 20 removed from runners on 2026-09-16) | Actions pinned to Node 16/20 with no migration plan |
| Artifact signing | **cosign v3.x** (Sigstore bundle by default, `--bundle` mandatory; install with `cosign-installer` **v4**) | cosign v2 in new pipelines; signatures without subsequent verification |
| Provenance | **SLSA Build L3**: GH Artifact Attestations (`actions/attest-build-provenance`) from a **reusable workflow**; verification with `gh attestation verify` or `slsa-verifier`. **The attestation is necessary but is NO longer sufficient** (see warning below) | Publishing without attestation; "generate and never verify"; **treating a valid attestation as proof that the artifact is benign** |
| SBOM | **Syft** (CycloneDX 1.6 JSON or SPDX 3.0.1) + **Grype** for CVE matching | Decorative SBOM, neither archived nor scanned |

> ⚠️ **Signed provenance no longer proves the artifact is benign** (verified Aug 2026).
> **Mini Shai-Hulud (CVE-2026-45321)**, active since late Apr 2026, extracts OIDC tokens from the
> **runner memory** of GitHub Actions and **issues valid SLSA L3 attestations for malicious
> packages**: if the runner is compromised, the signature certifies a build that did happen
> there, and that is exactly what the attacker wanted. Precedents of the same pattern: **CanisterWorm**,
> the compromise of **Trivy** (Mar 2026), the **LiteLLM** backdoor on PyPI and `elementary-data`
> (Apr 2026), all three with persistence via `.pth` or via CI without a *pin*.
> **Operational consequence**: the attestation remains mandatory —it proves *where* it was built—
> but the control that actually cuts this class off is **pinning by SHA/digest everything that enters the
> runner**, minimising what the runner can reach, and **being able to rotate any CI credential at
> any time**. Do not treat it as the last link in the chain of trust.
| GitLab OIDC | `id_tokens` with explicit `aud`; trust policy by **`project_id`/`namespace_id`** (stable claims, gitlab.com) in addition to `sub` | `CI_JOB_JWT*` (removed in GitLab 17.0); trust policies by path only (vulnerable to rename) |
| GH OIDC subject | New repos (post 2026-07-15) issue an **immutable sub** `repo:org@id/repo@id`; for existing repos, opt-in after updating trust policies | Trust policies with a broad wildcard (`repo:org/*`) or with no branch/environment filter |
| Workflow permissions | Top-level `permissions:` **read-only** (`contents: read`); elevate per job only | `permissions: write-all` or default permissions left undeclared |

Active caution (Aug 2026): there are reports of supply chain compromises in **Trivy**; before
using it as a gate, verify its current status. Syft+Grype is the default alternative.

## 3. Structure and conventions

- **Pipelines as code**, versioned and reviewed by PR/MR with **CODEOWNERS over
  `.github/workflows/` / `.gitlab-ci.yml`** — a workflow is privileged code.
- One workflow = one purpose (ci / release / deploy). Complex logic outside the YAML: versioned
  scripts (`ci/` or `scripts/`) invoked from steps, testable locally.
- Reuse: GH **reusable workflows** (which additionally enable SLSA L3) and your own composite
  actions; GitLab `include:` of centralised templates with a pinned ref (tag/SHA, not branch).
- **`concurrency`** with `cancel-in-progress` in PR CI; never in deploy jobs (use a queue).
- Explicit `timeout-minutes` on every job. Without a timeout there is no failure budget.
- Config outside the artifact: the same binary/image for every environment, per-environment
  configuration injected at deploy (env vars/config store), never baked in at build.
- Descriptive and stable job/step names (branch protection gates reference them by
  name; renaming a job breaks the gate silently).

## 4. Mandatory quality gates

All of them block the merge (required checks / `allow_failure: false`). Main always green.

1. **Format** (formatter in check mode) and **lint**.
2. **Type-check**, strict where the language allows it.
3. **Tests**, unit + integration, deterministic; a flaky test is fixed or deleted.
4. **SAST** (CodeQL / GitLab SAST / Semgrep).
5. **Dependency SCA** (Dependabot/Renovate + Grype or OSV-Scanner) — breaks the build on exploitable critical/high.
6. **Secret scanning** (GH secret scanning + push protection / Gitleaks) — a finding = broken build + secret rotation, not just deleting the commit.
7. **IaC scanning** (Checkov/KICS/tfsec) and **image** scanning (Grype) before pushing to the registry.
8. **Policy as code** where there is a cluster: signature+provenance verification at admission (Sigstore Policy Controller / Kyverno).

Cut-off severity defined in writing (e.g. CRITICAL+HIGH with a fix available break the build; the rest,
an issue with an SLA). Exceptions only via a versioned allowlist with a reason and an expiry date.

## 5. Security

**Supply chain**
- Build once: the artifact is built **once**, identified by **digest** (not tag) and the same digest is
  **promoted** dev→staging→prod. Rebuild per environment = different artifacts = forbidden.
- Every release: **archived SBOM + keyless cosign signature (OIDC) + SLSA provenance**; the deploy
  **verifies** signature and provenance (expected builder, repo, ref) before executing.
- GitHub **immutable releases** enabled (tag and assets non-modifiable, release attestations).
- Base images and dependencies **pinned by digest**; lockfiles committed and verified in CI
  (`npm ci`, `--frozen-lockfile`, `pip install --require-hashes`…).
- GH organisation policy: **SHA pinning enforcement** and action allowlist/blocking
  (available since Aug 2025); in GitLab, an allowlist of job images from your own registry.

**Hardened runners**
- Preference: **ephemeral** runners (GH-hosted, or autoscaled single-use self-hosted).
  Persistent self-hosted only for justified needs, **never** for public repos.
- On GH-hosted: **Harden-Runner** (StepSecurity) with an egress policy in sensitive workflows;
  egress filtering = anti-exfiltration control, not optional in jobs with secrets.
- Self-hosted: isolated by group/label and by trust level, non-root, without long-lived
  credentials on disk, minimum host IAM, patched on a cadence (section 7).
- Cache: aware of **cache poisoning** — do not share cache between untrusted triggers
  (GH already issues read-only cache tokens for triggers without write permission since Jun 2026);
  never cache directories containing secrets.

**Secrets and privilege**
- Zero static secrets towards clouds: OIDC with narrow trust policies (repo+ref/environment;
  immutable/stable claims where they exist). Residual secrets: central manager (Vault/KMS),
  short-lived and rotated, scoped by **environment** with required reviewers for prod.
- `pull_request_target`, `workflow_run` and triggers over fork code: no access to secrets
  nor checkout of the fork's code with elevated permissions. Explicit review in the diff of
  any change to these triggers.
- No secret in logs (masking is no guarantee: do not `echo`/`env` whole blocks).

## 6. Operability

- **Safe deployment by default**: canary or blue/green with automatic health checks over
  metrics (error rate, latency) and **automated and tested rollback** — a rollback that has never
  been executed does not exist. Rolling only for low-risk stateless services.
- **Feature flags** to decouple deploy from release; dark code deploy is the normal
  way to integrate large pieces of work.
- **Expand/contract migrations**: every data migration backwards compatible; code N
  and N-1 coexist with the same schema. `expand` (deploy) → migrate data → `contract` (later
  release). Never a destructive migration in the same deploy as the code that requires it.
- Observable pipeline: duration and failure rate per job as metrics; deploy events annotated
  in Grafana/APM; CI logs retained and correlatable with releases (digest+commit+run id).
- **Runbook per deploy pipeline**: how to pause, how to roll back, whom to notify. Linked
  from the workflow itself (comment/summary).
- GitLab environments (`environment:`) / GH Environments declared: they give traceability of which digest
  runs where and apply protections (reviewers, wait timers) in prod.

## 7. Sustainability and prohibitions

**Cadence**
- Weekly: Dependabot/Renovate for actions, base images and dependencies (with
  `enable-beta-ecosystems` if needed for SHA pins on GH).
- Monthly: review of platform deprecations (GH Actions changelog / GitLab release notes)
  — the 2025-2026 pace (artifacts v3, Node 20, cache v2, GitLab JWT) proves that "don't touch it" breaks on its own.
- Per platform release: GitLab self-managed to the latest supported minor; self-hosted runners
  updated within a fixed window.

**FORBIDDEN**
- Deploying with CI red or skipping gates (`--no-verify`, skipping checks, admin merge without a gate).
- Static cloud credentials in CI (access keys, SA JSON, long-lived tokens).
- Actions/templates referenced by branch or mutable tag without a pinning policy.
- Rebuilding per environment; promoting by mutable tag; `latest` in prod.
- Cleartext secrets in YAML, logs, artifacts or cache; secrets reachable by fork triggers.
- Persistent self-hosted runners for public repos or third-party PRs.
- Manual changes to what the pipeline manages (snowflake deploys, hotfix over SSH).
- Destructive migrations coupled to the code deploy; deploying without a defined rollback.
- Flaky tests retried as a matter of course (`retry` to paper over instability).
- Disabling a gate "temporarily" without an issue, a reason and an expiry date.

## 8. Mandatory web verification

Before pinning any concrete data point in a pipeline, **look it up — do not recall it**:
- Action versions/SHAs and the current major (`actions/checkout`, `upload-artifact`, `cache`,
  `cosign-installer`): GitHub releases + the `github.blog/changelog` changelog.
- Current format of OIDC claims (GH immutable sub in rollout since Jul 2026; GitLab
  `project_id`/`namespace_id`) before writing a trust policy.
- Security status of every third-party tool you put in the pipeline (any recent
  compromises? the Trivy case, 2026) and active GH/GitLab deprecations.
- Stable versions of cosign, Syft, Grype, slsa-verifier and the current syntax of their flags
  (cosign v3 changed verification flags relative to v2).

If you cannot verify, say so explicitly instead of assuming.

If the web contradicts this document, **the web wins** — flag the discrepancy.
