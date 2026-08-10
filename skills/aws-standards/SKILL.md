---
name: aws-standards
description: AWS architecture, security and FinOps standards. Use when working with AWS services (Lambda, ECS, EKS, Fargate, S3, RDS, Aurora, DynamoDB, SQS, SNS, EventBridge, VPC, IAM, KMS, GuardDuty, Security Hub, CloudWatch, Organizations, Control Tower), the aws CLI, SAM, or IaC files targeting AWS (CloudFormation templates *.yaml/*.json, CDK cdk.json/*.ts/*.py, Terraform *.tf with provider aws).
---

# AWS standards

This skill sets CRITERIA for designing, reviewing and operating on AWS: what to use by default, what is
forbidden and what to verify before deciding. Bar: Well-Architected + zero-trust +
FinOps. On conflict, security wins; on a technical tie, the simplest and the managed option wins.

## 1. Scope and triggers

Applies to any task touching AWS: IaC code (CloudFormation/CDK/Terraform/SAM), `aws`
commands, architecture design, security review, cost estimation, pipelines that
deploy to AWS. If the task is multi-cloud, combine with the `azure-standards` and
`gcp-standards` skills and decide per workload, not by inertia.

**Not applicable**: see `iac-standards` (the **how** of Terraform/OpenTofu and Ansible code: modules,
state, backend, drift — here the **what** is decided: which service and with what configuration),
`kubernetes-standards` (manifests, charts and workloads running **inside** EKS; here only the
control plane, the data plane and their integration with IAM/VPC), `cicd-standards` (the pipeline and
OIDC federation from the runner), `identity-access-management-standards` (application IdP: OAuth
2.1/OIDC, SAML, passkeys, SCIM — here IAM/Identity Center as access control to the **platform**),
`cryptography-pki-standards` (algorithm choice and key lifecycle; here only KMS as a
service), `vulnerability-management-standards` (triage workflow and SLA; here only Security Hub /
Inspector as a source of findings), `cloud-security-posture-standards` (**what is cross-cutting to the
three clouds**: multi-account baseline, effective permission, attack paths and the choice of
CSPM/CNAPP; **here the specific AWS service and its configuration**),
`appsec-standards` (security of the application code),
`observability-standards` (vendor-neutral OTel and Prometheus; here only CloudWatch and its cost),
`sre-practice-standards` (SLO, on-call, postmortems), `grc-compliance-standards` (regulatory framework and
audit evidence), `networking-standards` (physical, on-prem and hybrid networks; here VPC),
`data-platform-standards` (modelling, indexes and engine tuning; here RDS/Aurora as a service), `finops-standards` (**method versus service boundary**: **the pricing model of each AWS service, its configuration and the concrete levers —storage class, instance family, Savings Plans— are ours**; **the method is theirs**: economic unit, tagging policy and its governance, normalisation with FOCUS, shared cost allocation, commitment coverage criteria and showback/chargeback. Rule: *if the answer changes when the provider changes, it belongs to `finops-standards`; if it depends on the AWS catalogue, it belongs here*), `platform-engineering-standards` (the internal abstraction offered on top of these services).

## 2. Default decisions (reference service per use case)

> **Verify availability/status on the web before pinning any service**: supported region,
> that it is not in Maintenance/Sunset at https://aws.amazon.com/products/lifecycle/ and current prices.

| Use case | Default | Alternative (when) |
|---|---|---|
| Event-driven compute / spikes / <15 min | Lambda (arm64/Graviton) | ECS Fargate if sustained throughput or >15 min |
| Containers with no K8s requirement | ECS + Fargate | EC2 capacity providers only with justification (GPU, sustained cost) |
| Strategic Kubernetes (portability, ecosystem) | EKS with Auto Mode (Karpenter) | Fargate profiles for isolated workloads |
| HTTP API | API Gateway (HTTP API) + Lambda | ALB + Fargate for always-on services |
| Relational | Aurora (PostgreSQL) / RDS PostgreSQL | Aurora Serverless v2 for variable load |
| Key-value / massive scale | DynamoDB (on-demand by default) | Provisioned + auto scaling if the pattern is stable and proven |
| Objects | S3 (SSE by default, Block Public Access) | — |
| Queue / decoupling | SQS (+ DLQ always) | — |
| Pub/sub and events | EventBridge (domain) / SNS (simple fan-out) | Kinesis / MSK only for real streaming with ordering and replay |
| Cache | ElastiCache (Valkey/Redis OSS) | — |
| Secrets | Secrets Manager (rotation) / SSM Parameter Store (config) | — |
| Container registry | ECR (scan on push, immutable tags) | — |
| Native IaC | CDK v2 (TypeScript/Python) over CloudFormation | Terraform/OpenTofu if the repo/organisation already uses it — do not mix within the same stack |
| Multi-account landing zone | Organizations + Control Tower; customisation with LZA (CDK) or CfCT | Never loose accounts with no OU and no SCP/RCP |
| CI/CD | The repo's own (GitHub Actions/GitLab) with OIDC towards AWS | CodePipeline/CodeBuild if all-AWS is a requirement |

**Deprecated/retired — FORBIDDEN to propose them** (closed to new customers since 2024 or in
sunset, source: AWS Product Lifecycle): CodeCommit (→ GitHub/GitLab), Cloud9 (→ local IDE +
CloudShell), S3 Select (→ Athena), CloudSearch (→ OpenSearch), SimpleDB (→ DynamoDB), Forecast
(→ SageMaker), Data Pipeline (→ Glue/Step Functions), Kinesis Data Analytics for SQL (shut down
Jan 2026 → Managed Service for Apache Flink), Inspector Classic (→ Inspector), Pinpoint (EOS
Oct 2026 → SES/End User Messaging), Proton (EOS Oct 2026), OpsWorks. For any "odd"
service, check the lifecycle page before using it.

## 3. Identity and access — ephemeral credentials ALWAYS

- **Static access keys forbidden** (IAM users with keys) for humans, CI/CD and workloads.
  Humans: IAM Identity Center (SSO federated with the corporate IdP) + MFA. CI/CD: OIDC federation
  (e.g. `token.actions.githubusercontent.com`) with short-lived roles and `sub` restricted to
  repo/branch. Workloads: instance/task roles (instance profile, ECS task role, IRSA/Pod
  Identity on EKS). Single exception: an external system with no OIDC/role support — documented, with
  automatic rotation and a usage alert.
- Real least privilege: policies with concrete actions and resources, conditions
  (`aws:SourceArn`, `aws:PrincipalOrgID`, tags). `Action: "*"`, `Resource: "*"` and
  the `AdministratorAccess`/`PowerUserAccess` managed policies are forbidden outside break-glass.
- Organisation guardrails: SCPs and RCPs (deny non-approved regions, deny disabling
  CloudTrail/GuardDuty, deny creating IAM users with keys). Permissions boundaries for roles
  created by pipelines.
- Management account: no workloads, no daily use; audited break-glass access. Separate accounts per
  environment (prod/non-prod) and per domain; dedicated log-archive and
  security-tooling accounts (Control Tower creates them).
- Verify access: Access Analyzer (external + unused access) enabled in every account.

## 4. Networks — default-deny, minimal exposure

- Own VPC per workload/environment; **do not use the default VPC** (delete it or leave it unused).
  Private subnets by default; public ones only for ALB/NLB/NAT. IPAM with no overlaps (RFC1918).
- Default-deny Security Groups: only the indispensable ingress, referencing other SGs, not broad
  CIDRs. **`0.0.0.0/0` on ingress is forbidden except for justified 443 at the public edge** (and
  then behind CloudFront/WAF + Shield). Egress is restricted too on sensitive workloads.
- Traffic to AWS services through VPC endpoints (Gateway for S3/DynamoDB — free; Interface for the
  rest) with endpoint policies; avoids unnecessary NAT (cost) and egress to the Internet (security).
- TLS 1.2+ everywhere (modern ALB security policy, HSTS); mTLS between services when the data
  demands it (ECS Service Connect / App Mesh successors — verify status on the web). Administrative access
  via SSM Session Manager, **never open SSH nor a bastion with public 22**.
- Minimal exposure: no public IPs on instances/tasks; internal ALB unless the service is
  genuinely public. Route 53 with minimal records; DNSSEC where applicable.

## 5. Data — encryption, proven backups, RTO/RPO

- Encryption at rest on EVERY resource: KMS with customer-managed keys (CMK) for sensitive
  data (alias per domain, annual rotation enabled, minimal key policies); SSE-S3/AWS-managed
  keys as the minimum floor. S3: account-level Block Public Access, versioning on data
  buckets, Object Lock for immutability (ransomware/compliance).
- RTO/RPO defined BEFORE choosing engine and topology; multi-AZ by default in prod; multi-region
  only if the RTO/RPO demands it (cost).
- Backups: centralised AWS Backup with a tag-based plan, vault with Vault Lock (immutable) and a
  cross-account/cross-region copy for an account-compromise scenario. **A backup with no proven
  restore does not exist**: periodic, documented restore game-day.
- Lifecycle: S3 lifecycle to IA/Glacier according to real access (S3 Storage Lens / Intelligent-Tiering
  for unknown patterns); retention and deletion compliant with GDPR (minimisation, right to erasure).
- Expand/contract schema migrations; never destructive changes in the same deploy.

## 6. Observability and operation

- Organisational CloudTrail (all accounts/regions, logs to the log-archive account, integrity
  enabled) — non-negotiable. VPC Flow Logs on prod VPCs.
- Structured logs (JSON) to CloudWatch Logs with explicit retention (**never "Never expire" by
  default** — it is cost and noise); metrics with actionable alarms on symptoms (golden signals),
  not on every resource; traces with X-Ray/ADOT (OpenTelemetry preferred for portability).
- SLOs with error budget for business services; alerts → on-call, not to a mailbox.
- Operational security: GuardDuty (all accounts, delegated admin, S3/EKS/RDS protections
  depending on use), Security Hub for aggregation/prioritisation — **careful**: since Dec 2025 "Security Hub"
  is the new unified service (OCSF, v2 APIs) and the classic one is called "Security Hub CSPM" (ASFF);
  verify on the web which one applies before writing automation, they are not interchangeable.
  Inspector (the current one, not Classic) for vulnerabilities in ECR/EC2/Lambda. AWS Config with
  conformance packs (CIS AWS Foundations v5) in every account.
- Every change through a pipeline with a reviewed plan/diff; canary/rolling deployments with proven
  rollback (CodeDeploy, feature flags). Runbooks and blameless postmortems.

## 7. FinOps — cost as a quality attribute

- **Mandatory and verified tagging**: at minimum `owner`, `env`, `project`/`cost-center`,
  `managed-by` (IaC). Enforced with tag policies + an SCP/Config rule that flags non-compliant ones.
  A resource with no tags = an orphan resource = a deletion candidate.
- Data Exports in **FOCUS** format (FinOps Foundation standard; verify the supported version on the
  web — 1.3 ratified Dec 2025) to S3/Athena; Budgets with alerts per account/project and
  Cost Anomaly Detection enabled from day 1.
- Default levers: Graviton/arm64 where the runtime supports it, Savings Plans for the stable
  baseline (decision with ≥30 days of data, not from memory), Spot for fault-tolerant workloads,
  scale-to-zero/off-hours in non-prod, right-sizing with Compute Optimizer.
- Design cost inside the architecture decision: NAT Gateway, inter-AZ/region transfer,
  Interface endpoints, CloudWatch ingest — they are estimated up front, not discovered on the bill.

## 8. Sustainability, lock-in and PROHIBITIONS

- **Conscious lock-in, not accidental**: proprietary services (DynamoDB, EventBridge, Step
  Functions) only with a clear benefit; app contracts behind own interfaces; portable
  standards where they cost nothing (OpenTelemetry, Postgres, S3 API, OCI containers).
- Upgrade policy: runtime/engine versions within standard support ALWAYS (Lambda
  runtimes, EKS N-2 at most, RDS with auto minor upgrade in a window); the upgrade is quarterly
  planned work, not an emergency. No paid extended support except by explicit decision.
- **LIST OF PROHIBITIONS** (they block a review):
  - Static IAM user access keys anywhere (code, CI, servers' `~/.aws`).
  - `0.0.0.0/0` on ingress with no written justification; public SSH/RDP; resources with an unnecessary
    public IP; the default VPC in use.
  - Resources without mandatory tags; resources created through the console in prod (**clickops**) — everything
    through IaC; unreconciled drift.
  - Public S3 or S3 without Block Public Access; unencrypted data; CMK without rotation; secrets in code,
    plaintext env vars in templates, or logs.
  - Disabling CloudTrail/GuardDuty/Config; wildcard `*` in IAM policies; accounts outside the
    organisation.
  - Proposing deprecated services (list in section 2); `latest` as an image tag in prod;
  - Logs with no defined retention; a single-AZ database in prod; a backup with no proven restore.

## 9. Mandatory web verification

Before pinning any concrete AWS fact in code or in an answer, **search the web** (official AWS
docs first): service status (lifecycle page), regional availability, supported runtime/engine
version, limits and quotas, prices, exact names of APIs/flags (e.g. Security
Hub v2 vs CSPM), and re:Invent/re:Inforce news from the last year. The model's memory is NOT a
valid source for: prices, EOL dates, recent feature names, regional availability.
If it cannot be verified, say so explicitly and mark the decision as provisional.

If the web contradicts this document, **the web wins** — flag the discrepancy.
