---
name: iac-standards
description: Infrastructure as Code standards (staff/principal level). Use when writing or reviewing Terraform/OpenTofu code (*.tf, *.tfvars, *.tofu, modules, backend/state config, providers), Ansible content (playbooks, roles, inventories, ansible.cfg, molecule scenarios), IaC scanning configs (trivy, checkov), policy as code for infra (OPA/Conftest, Sentinel), or IaC CI/CD pipelines (plan/apply, drift detection).
---

# IaC standards (Terraform/OpenTofu and Ansible)

## 1. Scope and triggers

Applies when creating or reviewing: `*.tf`, `*.tofu`, `*.tfvars`, modules and root modules, backend/state configuration, Ansible playbooks and roles (`*.yml` with tasks/hosts), inventories, Molecule scenarios, plan/apply pipelines, infrastructure policies (Conftest/OPA) and scanner configuration (trivy, checkov). Does not apply to K8s/Helm manifests (see the `kubernetes-standards` skill); the overlap (the `kubernetes`/`helm` providers in TF) is decided here: **cluster and platform with TF/Tofu; workloads via GitOps**, not with `helm_release` from Terraform.

**Not applicable**: remaining boundaries — see `aws-standards`/`azure-standards`/`gcp-standards` (**which** service to choose and with what secure configuration; here the **how** the code that creates it is written, versioned and applied — Bicep/ARM and CloudFormation/CDK live in their own cloud's skill), `cicd-standards` (the pipeline that runs `plan`/`apply`, its OIDC and its gates; here what that pipeline must check about the IaC code), `ruby-standards` (**Chef and Puppet are written in Ruby and that closeness confuses people**: the **infrastructure DSL** — resources, idempotency, convergence, inventory — is decided here; the **Ruby that gets written** — style, gems, tests, `rubocop` — is theirs), `bash-linux-scripting-standards` and `powershell-standards` (standalone scripts: if Ansible can do it idempotently, no script gets written — and if the target is Windows, the script that Ansible or the `provisioner` invokes is written to the criteria of `powershell-standards`; **DSC and declarative Windows configuration are decided here**), `onprem-standards` (the server and the OS that Ansible configures, and its hardening), `kubernetes-standards`, `grc-compliance-standards` (regulatory framework and evidence; here the OPA/Conftest policies that make it verifiable), `vulnerability-management-standards` (triaging the findings checkov/OSV-Scanner produce), `git-workflow-standards` (branch, PR and review of the IaC repository), `cmdb-inventory-standards` (**the `.tfstate` is not a CMDB**: it describes what this code created, not the asset or its lifecycle — the model, the stable identifier, discovery and reconciliation are theirs, and the inventory **reads** the state, it is not replaced by it), `os-provisioning-standards` (**the provisioning boundary is first boot**: PXE/HTTP Boot, unattended installer, first-boot `cloud-init` and host registration are theirs; from the moment the machine exists and responds, the `apply` belongs here), `identity-access-management-standards` (credentials and federation of the identity that runs the `apply`), `finops-standards` (**the tagging policy — which tags, with which allowed values and for which allocation unit — is theirs**; **the gate that enforces it in the code and at admission belongs here**. A tagging policy without this gate does not exist), `platform-engineering-standards` (**the Terraform/OpenTofu module and its quality belong here**; **the abstraction offered on top to the product team — paved road, template, Crossplane or composition — and what is hidden from them, is theirs**).

## 2. Default toolchain

> **Mandatory web verification**: checked in **August 2026**. Re-verify versions and licence status with WebSearch before pinning anything in a real project.

| Tool | Stable line (2026-08) | Criterion |
|---|---|---|
| **OpenTofu** | **1.12.x** (MPL 2.0, Linux Foundation/CNCF) | **Default for new projects**: OSI licence, native state encryption, provider `for_each`, OCI registry; same providers as TF |
| Terraform | 1.15.x (BSL 1.1, IBM/HashiCorp) | Valid if there is already investment in HCP/Terraform Enterprise or Stacks; the BSL requires legal review if you compete with HashiCorp |
| ansible-core | **2.21.x** (Python ≥3.12); community package 14.x | Only the community package's latest major receives guaranteed maintenance |
| **checkov** (IaC misconfig) + **OSV-Scanner**/**Grype** (dependencies) + a secrets scanner — **verify which one before pinning it: as of Aug 2026 `gitleaks` declared itself *feature complete* (security patches only) and its README points to Betterleaks; on top of that `gitleaks-action` left MIT in v2.0.0 and requires a commercial licence for organisations. The criterion is set by `secrets-management-standards`** | latest stable | Default after the **Trivy supply-chain compromise (March 2026)**: tag poisoning of `trivy-action`/`setup-trivy`, malicious binaries and images, and CI secret theft. Trivy is still technically good: if you use it, **pin by commit SHA** (actions) and **digest** (images), verify signature/checksum and follow its advisories |
| terraform-docs, tflint, ansible-lint, Molecule | latest stable | Mandatory in CI |
| Infracost | latest stable | Cost visible in the PR (FinOps shift-left) |

- **Fork status (verified 2026-08)**: binary state compatible in both directions **except** if you enable OpenTofu's state encryption (a one-way decision). OpenTofu adoption ~12% and growing (Fidelity migrated >50k state files); Terraform retains the larger share. Choose **one** engine per organisation and document the decision in an ADR; do not mix engines over the same state.
- Pin the engine version with `required_version` (pessimistic range `~>`) and the providers with `required_providers` + a committed lockfile (`.terraform.lock.hcl`).

## 3. Structure and conventions

### Terraform/OpenTofu
- **Modules**: standard structure (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, a `README.md` generated with terraform-docs, `examples/`, `tests/`). One module = one composable responsibility; neither a "god module" nor single-resource wrappers with no logic.
- **Root modules per environment** (`envs/prod`, `envs/staging`) composing versioned modules, **with state separated per environment and per domain** (bounded blast radius). Workspaces only for ephemeral variants (PR previews), **not** to separate prod/staging: a workspace shares backend, credentials and code version — a mistaken `terraform workspace select` is an incident.

Reference layout:

```
infra/
├── modules/              # own modules, versioned (SemVer tags)
│   └── vpc/
│       ├── main.tf  variables.tf  outputs.tf  versions.tf
│       ├── README.md         # generated with terraform-docs
│       ├── examples/basic/   # an appliable example = integration test
│       └── tests/vpc.tftest.hcl
└── envs/
    ├── prod/             # root module: backend + composition + values
    │   ├── backend.tf  main.tf  providers.tf  terraform.tfvars
    └── staging/          # same module code, different values
```

Reference backend (S3, encryption + native locking):

```hcl
terraform {
  required_version = "~> 1.12"          # OpenTofu; "~> 1.15" if Terraform
  backend "s3" {
    bucket       = "org-tfstate-prod"
    key          = "network/terraform.tfstate"   # one key per domain
    region       = "eu-west-1"
    encrypt      = true
    kms_key_id   = "alias/tfstate"
    use_lockfile = true                  # native S3 locking (no DynamoDB)
  }
}
```
- **Remote state, encrypted, with locking, always**: S3+DynamoDB/native lockfile, GCS, Azure Blob or a managed backend; encryption at rest (KMS) and access by role with least privilege. With OpenTofu, evaluate state encryption (client-side) for state holding sensitive data — document that it breaks compatibility with Terraform.
- Variables typed with a strict `type` and `validation`; `sensitive = true` on everything secret; no `default` for values that must be decided per environment.
- Modules consumed **by version** (SemVer tag in a registry/Git, or an OCI registry with OpenTofu), never by branch (`ref=main` forbidden).
- Naming: `snake_case`, resources named by role (`this` in modules with one main resource), mandatory tags/labels (owner, env, cost-center, managed-by).
- No `local-exec`/`null_resource` as glue except as a last resort documented with a TODO/issue.

### Ansible
- **Idempotency as a contract**: every task uses declarative modules (`ansible.builtin.*`, certified collections); `shell`/`command` only with `creates`/`changed_when` and a justification. Second run = 0 changed.
- Structure in **roles** (galaxy layout: `tasks/`, `defaults/`, `handlers/`, `templates/`, `meta/`) packaged into collections when shared; thin playbooks that orchestrate roles.
- Inventories per environment (prefer a dynamic inventory against the provider); versioned `group_vars`/`host_vars`; **Ansible Vault or a lookup to a secrets manager** for every sensitive value — never in the clear.
- FQCN always (`ansible.builtin.copy`, not `copy`); `become` explicit and minimal, not global.
- `ansible.cfg` versioned in the repository; reproducible execution through execution environments (an image with pinned dependencies) in CI.
- Reference role layout:

```
roles/nginx/
├── defaults/main.yml     # the single defaults layer (documented)
├── tasks/main.yml        # idempotent tasks, FQCN
├── handlers/main.yml     # restarts/reloads, never in tasks
├── templates/            # *.j2 with {{ ansible_managed }}
├── meta/main.yml         # deps, supported platforms
└── molecule/default/     # create→converge→idempotence→verify→destroy
```

## 4. Quality and testing (CI gates)

**Mandatory TF/Tofu flow — plan in the PR, automated apply:**
1. PR: `fmt -check` → `validate` → `tflint` → scan (Trivy/checkov) → **`plan` with its output published in the PR** (plan artifact saved) → Infracost diff → human review of the plan (CODEOWNERS on prod paths).
2. Merge to main: **automated apply of the approved plan** (the same artifact: apply-what-you-planned, not a blind re-plan) from the pipeline with OIDC — **never apply from laptops**.
3. **Scheduled drift detection** (nightly/cron plan with `-detailed-exitcode`): drift = actionable alert + issue; it is fixed in Git (or imported), not ignored.

**Tests by level:**
- Unit/contract: `terraform test`/`tofu test` (`.tftest.hcl` files) for module logic, validations and outputs; Terratest only if you need assertions the native framework does not cover.
- Integration: each module's `examples/` applied in an ephemeral sandbox account/project in the module's CI (create → verify → destroy).
- Ansible: `ansible-lint` (production profile) as a gate + **Molecule** per role (create → converge → **idempotence** → verify → destroy) against containers or ephemeral VMs; the idempotence step is non-negotiable.
- Every IaC repository: pre-commit hooks (fmt, lint, docs, secret scan) mirroring the CI gates.

## 5. Security

- **Secrets: never in code, in state in the clear, in committed tfvars or in logs.** Single source: Vault/Secrets Manager/SSM, consumed at runtime (data sources, Ansible lookups) or injected by CI. Remember: **TF state contains secrets in the clear** → treat it as a secret (encrypted, least access, no local downloads).
- **Ephemeral credentials**: CI OIDC towards the cloud (short-lived roles); static access keys in CI or on laptops for prod are forbidden.
- **Scanning as a build-breaking gate**: Trivy (IaC misconfig + secret scanning) and/or checkov on every PR; CRITICAL/HIGH findings block, with exceptions via a versioned and justified baseline (inline skip with a comment and an issue, never silent).
- **Policy as code**: OPA/Conftest (or Sentinel in HCP) over the plan JSON — verifiable organisational rules: allowed regions, mandatory encryption, `0.0.0.0/0` forbidden on ingress, mandatory tags, approved instance types. The same policies in CI and (if one exists) in the TACOS.
- Third-party providers and modules: version pin + source review; external modules audited before adoption (a module is code running with your credentials).
- Least privilege on the pipeline role: the plan role is read-only; the apply role is scoped by domain/state.

## 6. Operability

- **Environments identical by construction**: the same module code with per-environment values; staging validates the change before prod (promotion = same commit/module version).
- **Destructive changes made visible**: review the `plan` looking for `destroy`/`replace`; `lifecycle.prevent_destroy` on resources holding data (databases, buckets); `create_before_destroy` where the replacement must be without downtime.
- **Tested rollback**: reverting the commit in Git + apply is the standard path; for stateful resources (data), rollback is a tested restore from backup, not an HCL revert — document RTO/RPO per critical resource.
- Pipeline observability: an auditable history of plans/applies (who, what, when, with which plan), notification of applies to prod, drift metrics.
- Ansible in production: `--check --diff` as a preceding phase in the pipeline; `serial` + `max_fail_percentage` for progressive rollouts; handlers for controlled restarts.
- Runbooks for state operations (import, `state mv`, unlock): these are surgery — with a prior state backup, in pairs, and recorded.

## 7. Sustainability and prohibitions

- **Upgrade cadence**: engine (Tofu/TF) and providers kept current with a **monthly** review via Renovate/Dependabot (automatic PR + plan in CI as a regression test); never more than one minor behind. ansible-core: only 3 majors receive fixes — plan the annual jump. Read the changelogs of major providers (breaking changes in majors) before merging.
- State refactors (`moved`, `removed`, `import` in a block) in dedicated PRs, separate from functional changes.
- One ADR per structural decision: chosen engine, state layout, environment strategy, TACOS (Atlantis/env0/Spacelift/Scalr) if adopted.

**FORBIDDEN** (automatic gate wherever possible):
- **Local state** or state in the repository; state without encryption or without locking; downloading state to a laptop.
- Manual `apply` from local machines to prod; infrastructure changes through the cloud console/CLI outside Git (except documented break-glass, reconciled with `import`).
- Secrets in the clear in `.tf`, `.tfvars`, playbooks, inventories, CI variables or log output; committed tfvars containing secrets.
- Static long-lived cloud credentials in CI.
- Modules referenced by branch (`ref=main`) or with no version; providers with no pin and no lockfile.
- Workspaces to separate prod/non-prod; a single monolithic state for the whole organisation.
- Interactive `-auto-approve` outside the pipeline; applying a plan different from the one reviewed.
- Ignoring drift or "fixing" it by hand-editing the state without a runbook.
- `shell`/`command` in Ansible without declared idempotency; roles without Molecule in shared repositories.
- Disabling the scanner or skipping a gate "temporarily" without a registered exception with an issue and an expiry date.

### Quick review checklist (every IaC PR)

- [ ] `plan` published in the PR and reviewed (watch for unexpected `destroy`/`replace`); the apply will use that same artifact.
- [ ] fmt + validate + tflint/ansible-lint + Trivy/checkov + Conftest green; exceptions with an issue and an expiry date.
- [ ] No secrets and no static credentials; sensitive variables with `sensitive = true`/Vault; OIDC in the pipeline.
- [ ] Providers/modules version-pinned and lockfile up to date; modules by tag, not by branch.
- [ ] Correct state (encrypted backend with locking for the target environment); state refactors in a separate PR.
- [ ] Cost (Infracost) reviewed; mandatory tags/labels present; change tested in staging or example/Molecule.

## 8. Mandatory web verification

Before pinning versions, the syntax of recent features or engine recommendations:
1. **WebSearch/WebFetch** the official releases (opentofu.org, HashiCorp releases, PyPI ansible-core) and endoflife.date — the cadences are fast and this document ages.
2. **Re-verify the Terraform versus OpenTofu situation** (licence, diverging features, adoption): the fork is actively diverging (state encryption, OCI registry, `terraform query`/Actions only in TF) and the recommendation may change.
3. Confirm breaking changes in major providers (aws/azurerm/google) for the target version before writing constraints.
4. If you cannot verify, say so explicitly in the deliverable instead of assuming.

If the web contradicts this document, **the web wins** — flag the discrepancy.
