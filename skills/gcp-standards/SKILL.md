---
name: gcp-standards
description: Google Cloud (GCP) architecture, security and FinOps standards. Use when working with GCP services (Cloud Run, GKE, Cloud Functions/Cloud Run functions, Cloud SQL, AlloyDB, Spanner, BigQuery, Pub/Sub, Cloud Storage, Artifact Registry, VPC, IAM, KMS, Secret Manager, Security Command Center, VPC Service Controls), the gcloud/gsutil/bq CLIs, or IaC files targeting GCP (Terraform *.tf with provider google, Infrastructure Manager).
---

# Google Cloud (GCP) standards

This skill sets the CRITERIA for designing, reviewing and operating on Google Cloud: what to use by default, what
is forbidden and what to verify before deciding. Framework: Google Cloud Architecture Framework +
enterprise foundations blueprint + zero-trust + FinOps. On conflict, security wins; on a
technical tie, the simplest and most managed option.

## 1. Scope and triggers

Applies to any task that touches GCP: Terraform/Infrastructure Manager,
`gcloud`/`gsutil`/`bq` commands, organisation and project design, IAM, security review, costs,
pipelines that deploy to GCP. In multi-cloud tasks, combine with `aws-standards` and
`azure-standards` and decide per workload.

**Not applicable**: see `iac-standards` (the **how** of Terraform/OpenTofu and Ansible code: modules,
state, backend, drift — here the **what** is decided: which service and with what configuration),
`kubernetes-standards` (manifests, charts and workloads that run **inside** GKE; here only the
control plane, Autopilot and its integration with IAM/VPC), `cicd-standards` (the pipeline and the
OIDC/Workload Identity federation from the runner), `identity-access-management-standards` (application
IdP: OAuth 2.1/OIDC, SAML, passkeys, SCIM — here Cloud IAM as access control to the
**platform**), `cryptography-pki-standards` (algorithm choice and key lifecycle;
here only Cloud KMS and Secret Manager as services),
`vulnerability-management-standards` (triage workflow and SLA; here only Security Command Center
as a source of findings), `cloud-security-posture-standards` (**what is cross-cutting to the three clouds**:
multi-project baseline, effective permission, attack paths and the choice of CSPM/CNAPP;
**here the concrete GCP service and its configuration**),
`appsec-standards` (security of the application code),
`observability-standards` (vendor-neutral OTel and Prometheus; here only Cloud Observability and its
cost), `sre-practice-standards` (SLO, error budget, on-call and postmortems — SRE practice is
agnostic even though it was born at Google), `grc-compliance-standards` (regulatory framework and audit
evidence), `networking-standards` (physical, on-prem and hybrid networks; here VPC),
`data-platform-standards` (modelling, indexes and tuning; here Cloud SQL/AlloyDB/BigQuery as
services), `finops-standards` (**method versus service**: the pricing model of
each GCP service, committed use discounts and levers of its own such as **the cost per
byte scanned in BigQuery** belong here; **the unit economics, the tagging policy and its
gate, normalisation with FOCUS and shared cost allocation are theirs**. *If the answer
changes when you change provider, it is theirs; if it depends on the GCP catalogue, it is ours*),
`platform-engineering-standards` (the internal abstraction offered on top of these
services).

## 2. Default decisions (reference service per use case)

> **Verify availability/status on the web before pinning any service**: region, that it is not
> deprecated (Google Cloud deprecations / release notes) and current pricing.

| Use case | Default | Alternative (when) |
|---|---|---|
| Stateless containers / APIs / web | **Cloud Run** (services; scale-to-zero) | — it is the default unless there is a real K8s requirement |
| Batch/containerised jobs | Cloud Run jobs | Batch for HPC/large compute queues |
| Event-driven functions | Cloud Run functions (formerly Cloud Functions — same Cloud Run platform) | — |
| Strategic Kubernetes | GKE **Autopilot** (mode recommended by Google) | GKE Standard only when custom nodes/node DaemonSets/exotic GPUs are needed |
| Relational | Cloud SQL for PostgreSQL | AlloyDB if extreme Postgres performance; Spanner if global scale + strong consistency |
| Analytics | BigQuery | — |
| Key-value/document | Firestore | Bigtable for time series/latency at scale |
| Objects | Cloud Storage (uniform bucket-level access, PAP enforced) | — |
| Messaging/events | Pub/Sub (+ DLQ and retry policy always) | — |
| Cache | Memorystore (Valkey/Redis — verify the current SKU on the web) | — |
| Secrets | Secret Manager (versions, rotation, expiry) | — |
| Artifact registry | **Artifact Registry** (Container Registry has been SHUT DOWN since Mar 2025) | — |
| IaC | **Terraform/OpenTofu** (google provider) — it is the canonical route; Infrastructure Manager if managed Terraform execution is wanted | Deployment Manager is RETIRED (EOL Mar 2026): forbidden |
| Organisational base | Enterprise foundations blueprint (terraform-example-foundation) / Fabric FAST | Never standalone projects with no folder or org policies |
| CI/CD | The repo's own (GitHub Actions/GitLab) with Workload Identity Federation; Cloud Build if all-GCP | Cloud Deploy for release progression to Cloud Run/GKE |

**Deprecated/retired — FORBIDDEN to propose them**: Deployment Manager (EOL 31-Mar-2026 →
Infrastructure Manager/Terraform), Container Registry gcr.io (shut down Mar 2025 → Artifact
Registry), service account keys as the default mechanism (→ WIF, section 3), SCC
Enterprise tier (deprecated, shutdown May 2027 → Premium tier; verify status on the web). For
any doubtful service, consult its release notes/deprecations before using it.

## 3. Identity and access — ephemeral credentials ALWAYS

- **Exported service account keys (JSON) are forbidden** — it is Google's official posture and
  this skill's. Workloads on GCP: attached service account (Cloud Run/GCE) or **Workload
  Identity Federation for GKE** (pods). CI/CD and external systems: **Workload Identity
  Federation** (OIDC) with restricted attributes (repo/branch) and, preferably, a direct
  principal with no intermediate SA; SA impersonation only when needed. Humans: Cloud Identity
  federated with the IdP + mandatory MFA/2SV; elevated access via groups and with expiry, not
  permanent individual bindings.
  Enforce with org policy: `iam.disableServiceAccountKeyCreation` and
  `iam.disableServiceAccountKeyUpload` at organisation level (per-project exceptions,
  documented and with an expiry).
- Least privilege: concrete predefined roles at the minimum scope (resource/project, not
  folder/org); `roles/owner`/`roles/editor` **forbidden** in prod (basic roles); IAM conditions
  (time, resource) where they add value. Policy Intelligence/Recommender to trim unused
  permissions; IAM Recommender applied quarterly.
- Hierarchy: Organisation → folders per environment/domain (per the foundations blueprint) → projects
  as the unit of isolation (one workload+environment per project; the project is the blast radius).
  Org Policies from day 1: `iam.allowedPolicyMemberDomains` (domain restriction),
  `compute.vmExternalIpAccess` deny, `sql.restrictPublicIp`, `storage.publicAccessPrevention`,
  `compute.requireShieldedVm`, `gcp.resourceLocations` (approved regions), and the two for SA keys.
- Regulated/sensitive data: **VPC Service Controls** — a perimeter around the projects with
  data APIs (Storage, BigQuery, etc.) to cut off exfiltration with stolen credentials;
  access levels with Access Context Manager; dry-run before enforce.

## 4. Networking — default-deny, minimum exposure

- **The default network is forbidden** (org policy `compute.skipDefaultNetworkCreation`). Shared VPC per
  environment: network host project managed by the platform, service projects for workloads;
  regional subnets with planned ranges (no RFC1918 overlaps).
- Default-deny firewall: use **network firewall policies** (hierarchical and network) over classic
  VPC rules; rules by service account/secure tags, not by broad CIDR; **`0.0.0.0/0` forbidden
  on ingress without justification** — and anything public only behind an External Application Load
  Balancer + **Cloud Armor** (WAF, rate limiting, DDoS protection).
- No public IPs on compute: Cloud NAT for egress (with logging), **Private Google Access** on
  every subnet and Private Service Connect for Google APIs and published services; Cloud SQL over
  private IP (or connector with IAM auth), never public IP. Cloud Run: internal ingress +
  load balancer unless the service is genuinely public; egress via Direct VPC egress.
- Administrative access via **IAP** (TCP forwarding for SSH/RDP) — never public management
  ports nor an exposed bastion. TLS 1.2+ on frontends (modern SSL policy, not the default), HSTS;
  service-to-service mTLS where the data demands it (Cloud Service Mesh on GKE — verify name and
  status on the web). VPC Flow Logs + Firewall Rules Logging in prod.

## 5. Data — encryption, tested backups, RTO/RPO

- Encryption at rest by default across the whole platform; **CMEK (Cloud KMS)** for
  sensitive/regulated data (Storage, BigQuery, Cloud SQL, disks, Pub/Sub): keyring per
  environment/region, scheduled automatic rotation, minimum IAM on keys, org policy
  `gcp.restrictNonCmekServices` where compliance demands it. Autokey to simplify at scale
  (verify status on the web).
- RTO/RPO defined before choosing topology: Cloud SQL with regional HA (standby) by default in
  prod; cross-region replicas/Spanner multi-region only if the RTO/RPO demands it (cost).
- Backups: **Backup and DR Service** or managed native backups (Cloud SQL automated backups +
  PITR enabled; Backup for GKE; bucket with versioning + soft delete + bucket lock for
  ransomware immutability). Copy in a separate project/region for a compromise scenario.
  **A backup without a tested restore does not exist**: periodic and documented drill.
- Cloud Storage: uniform bucket-level access + public access prevention ALWAYS; lifecycle to
  Nearline/Coldline/Archive according to real access; retention/deletion in line with GDPR (minimisation,
  right to erasure). Sensitive Data Protection (DLP) for PII discovery/classification.
  Expand/contract migrations.

## 6. Observability and operation

- Cloud Logging with **explicit retention** per log bucket and aggregated sinks at organisation
  level into a central logging project (immutable audit logs, with lock). **Admin
  Activity audit logs** always; Data Access audit logs enabled in projects with sensitive
  data (cost assessed, not an excuse).
- Structured logs (JSON), Cloud Monitoring with actionable alerts on symptoms (golden
  signals) and **SLOs with error budget** (Cloud Monitoring SLO API — SRE is home-grown here: use it);
  traces with Cloud Trace via OpenTelemetry (preferred for portability). Alerts → on-call, not to
  a mailbox.
- **Security Command Center** at organisation level: Premium tier (Enterprise deprecated —
  verify on the web), Security Health Analytics + Event Threat Detection active; findings
  triaged with an SLA, exported to SIEM. Assured Workloads if there are regional compliance requirements.
- Every change through a pipeline with a reviewed `terraform plan`; canary/gradual deployments (Cloud Run
  revisions with traffic splitting; Cloud Deploy for progression) and tested rollback; runbooks and
  blameless postmortems. Binary Authorization on GKE/Cloud Run for signed images
  (cosign/attestations) in prod.

## 7. FinOps — cost as a quality attribute

- **Mandatory labels** on every resource: at least `owner`, `env`, `project`/`cost-center`,
  `managed-by`; enforced via IaC (modules with required labels) and audited — no labels =
  orphan. One project per workload+environment makes attribution almost free: take advantage of it.
- Billing export to **BigQuery** (detailed usage cost) + **FOCUS** view (verify the supported
  version on the web — 1.3 ratified Dec 2025); budgets with alerts per project and programmatic
  thresholds (Pub/Sub) from day 1; anomaly detection active.
- Default levers: scale-to-zero (Cloud Run), CUDs (resource-based or flex — verify
  current offerings, e.g. Autopilot Flex CUDs) for a stable baseline with ≥30 days of data, Spot
  VMs/pods for fault-tolerant workloads, right-sizing with Recommender, shutting non-prod down outside
  working hours. BigQuery: partitioning+clustering, query quotas, slots/editions according to pattern —
  uncontrolled on-demand is the classic surprise bill.
- Cost of the design in the decision: inter-region/Internet egress, Cloud NAT, logging ingest,
  Private Service Connect — estimated before deploying.

## 8. Sustainability, lock-in and PROHIBITIONS

- **Conscious lock-in, not accidental**: proprietary services (Spanner, BigQuery, Firestore)
  only with a clear benefit; contracts behind your own interfaces; cheap portability where it
  costs nothing (Postgres, OCI containers on Cloud Run/GKE, OpenTelemetry, Terraform).
- Upgrade policy: GKE on a release channel (Regular by default) with maintenance windows —
  never clusters with no channel or versions out of support; current Cloud Run
  functions runtimes; Terraform provider updated on a cadence. Review GCP deprecations
  quarterly; the upgrade is planned work, not an emergency.
- **LIST OF PROHIBITIONS** (they block a review):
  - Service account keys (JSON) created/exported (org policy must prevent it); API keys for
    services that accept IAM; `roles/owner`/`roles/editor` in prod; bindings to individual
    users instead of groups.
  - Default network in use; `0.0.0.0/0` on ingress without justification; public IPs on VMs/Cloud SQL;
    exposed management ports (no IAP); public buckets or buckets without public access prevention.
  - Resources created through the console in prod (**clickops**) — everything through Terraform; unreconciled
    drift; Deployment Manager; images on gcr.io; `latest` on prod images.
  - Resources without mandatory labels; projects outside the folder/org policy hierarchy;
    billing without BigQuery export or budgets.
  - Secrets in code/env/logs in clear (use Secret Manager); sensitive data without CMEK when
    the classification demands it; audit logs disabled or without a central sink.
  - Prod without regional HA (Cloud SQL single instance, zonal GKE); backup without a tested restore;
    logs without defined retention; VPC-SC perimeter absent on regulated data projects.

## 9. Mandatory web verification

Before pinning any concrete GCP fact in code or in an answer, **search the web** (cloud.google.com
docs / release notes / deprecations first): service status and deprecations
(they change name and tier frequently: SCC tiers, Memorystore SKUs, Cloud Functions → Cloud
Run functions…), regional availability, GKE versions supported per channel, limits/quotas,
pricing and Cloud Next news from the last year. The model's memory is NOT a valid source for
pricing, EOL dates, recent feature names or regional availability. If it cannot be
verified, say so and mark the decision as provisional.

If the web contradicts this document, **the web wins** — flag the discrepancy.
