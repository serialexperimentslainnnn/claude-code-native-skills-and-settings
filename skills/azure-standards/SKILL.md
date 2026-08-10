---
name: azure-standards
description: Azure architecture, security and FinOps standards. Use when working with Azure services (AKS, Container Apps, App Service, Functions, Entra ID, Key Vault, VNet, Private Link, Azure Policy, Defender for Cloud, Azure Monitor, Storage, SQL Database, Cosmos DB, Service Bus, Event Grid), the az CLI, azd, or IaC files targeting Azure (Bicep *.bicep, ARM templates azuredeploy.json, Terraform *.tf with provider azurerm/azapi).
---

# Azure standards

This skill sets CRITERIA for designing, reviewing and operating on Azure: what to use by default, what is
forbidden and what to verify before deciding. Frame of reference: Cloud Adoption Framework (CAF) +
Well-Architected Framework (WAF) + zero-trust + FinOps. On conflict, security wins; on a
technical tie, the simplest and the managed option.

## 1. Scope and triggers

Applies to any task touching Azure: Bicep/ARM/Terraform, `az`/`azd` commands, landing zone
design, RBAC, security review, costs, pipelines that deploy to Azure. On multi-cloud
tasks, combine with `aws-standards` and `gcp-standards` and decide per workload.

**Not applicable**: see `iac-standards` (the **how** of Terraform/OpenTofu and Ansible code: modules,
state, backend, drift — here the **what** is decided: which service and with what configuration; Bicep/ARM
do belong to this skill), `kubernetes-standards` (manifests, charts and workloads running **inside**
AKS; here only the control plane and its integration with Entra ID/VNet), `cicd-standards` (the
pipeline and OIDC federation from the runner), `identity-access-management-standards` (application
IdP: OAuth 2.1/OIDC, SAML, passkeys, SCIM, authorisation engines — here Entra ID as
access control to the **platform** and its RBAC roles), `cryptography-pki-standards` (choice of
algorithms and key lifecycle; here only Key Vault/Managed HSM as a service),
`vulnerability-management-standards` (triage workflow and SLA; here only Defender for Cloud as a
source of findings), `cloud-security-posture-standards` (**what is cross-cutting to the three clouds**:
multi-subscription baseline, effective permission, attack paths and the choice of CSPM/CNAPP;
**here the specific Azure service and its configuration**),
`appsec-standards` (security of the application code),
`observability-standards` (vendor-neutral OTel and Prometheus; here only Azure Monitor and its cost),
`sre-practice-standards` (SLO, on-call, postmortems), `grc-compliance-standards` (regulatory framework and
audit evidence), `networking-standards` (physical, on-prem and hybrid networks; here VNet),
`dotnet-standards` (the application's C# code deployed on top), `finops-standards` (**method versus service**: the pricing model of each Azure service, its reservations and savings plans and its concrete levers are ours; **the economic unit, the tagging policy and its gate, normalisation with FOCUS, shared cost allocation and commitment coverage criteria are theirs**. *If the answer changes when the provider changes, it is theirs; if it depends on the Azure catalogue, it is ours*), `platform-engineering-standards` (the internal abstraction offered on top of these services).

## 2. Default decisions (reference service per use case)

> **Verify availability/status on the web before pinning any service**: region, SKU, that
> it is not in retirement (Azure Updates / Microsoft Lifecycle / Azure Advisor "Service Upgrade and
> Retirement") and current prices.

| Use case | Default | Alternative (when) |
|---|---|---|
| Containers with no K8s requirement | Azure Container Apps (scale-to-zero, Dapr, KEDA) | App Service for classic web apps already on that platform |
| Strategic Kubernetes | AKS **Automatic** (GA Sept 2025; Azure Linux, best practices by default) | AKS Standard only if you need node/kernel/node-level CIS control |
| Event-driven functions | Azure Functions (Flex Consumption plan — verify status on the web) | Container Apps jobs for containerised tasks |
| Relational | Azure Database for PostgreSQL Flexible Server / Azure SQL Database | — (Single Server is retired) |
| Global NoSQL | Cosmos DB (API according to the data model) | — |
| Objects/blobs | Storage Account (Blob, GPv2, LRS/ZRS according to RTO/RPO) | — |
| Simple queue | Storage Queues | Service Bus if sessions, ordering, DLQ, transactions |
| Enterprise messaging | Service Bus (queues/topics + DLQ) | — |
| Events | Event Grid (reactive) / Event Hubs (streaming) | — |
| Cache | Azure Managed Redis (verify on the web: it replaces Azure Cache for Redis, in retirement) | — |
| Secrets/keys | Key Vault (RBAC-mode, soft delete + purge protection) | Managed HSM if FIPS 140-3 L3 |
| Container registry | Azure Container Registry (Premium in prod: private link, geo-replication) | — |
| Native IaC | **Bicep + Azure Verified Modules (AVM)** | Terraform/OpenTofu + AVM if the organisation already uses it; ARM JSON only generated, never by hand |
| Landing zone | Azure Landing Zones (CAF) via an IaC accelerator with AVM (Bicep or Terraform) | Portal accelerator only for exploratory bootstrapping |
| CI/CD | The repo's own (GitHub Actions/Azure DevOps) with OIDC/workload identity federation | — |

**Retired/deprecated — FORBIDDEN to propose them** (source: Microsoft Lifecycle / Azure Updates):
everything classic/ASM (Cloud Services classic, ASE v1/v2 — retired Aug 2024), the Log Analytics agent
MMA/OMS (retired Aug 2024; ingestion may be cut off from Mar 2026 → **Azure Monitor Agent**),
PostgreSQL/MySQL Single Server (→ Flexible Server), Application Insights classic (→
workspace-based), the Container Apps Landing Zone Accelerator in CAF (retired May 2026 → Architecture
Center guidance). Check in Azure Advisor the retirements affecting live resources.

## 3. Identity and access — ephemeral credentials ALWAYS

- **Static secrets forbidden**: no connection strings with account keys, no long-lived
  SAS, no app registration client secrets in workloads, no plaintext keys in App Settings.
  Workloads on Azure: **Managed Identity** (user-assigned preferred: controlled lifecycle) for
  ALL access to Storage/Key Vault/SQL/Service Bus (Entra ID auth, not access keys). External CI/CD:
  **workload identity federation** (OIDC) against Entra ID — a service principal with a long-lived
  secret/certificate is forbidden. Humans: Entra ID + mandatory MFA (Conditional Access), with no
  local accounts.
- Storage/SQL/Cosmos: disable key/local auth (`allowSharedKeyAccess: false`,
  `disableLocalAuth: true`) where the service supports it; Entra ID only.
- Least-privilege RBAC: concrete built-in roles at the minimum scope (resource group, not
  subscription); Owner/Contributor at subscription level only for very tightly scoped platform pipelines.
  Privileged roles via **PIM** (just-in-time, approval, time-limited), never permanent.
  Periodic access reviews.
- Hierarchy: management groups per ALZ (Platform: identity/management/connectivity; Landing
  Zones: corp/online; Sandbox; Decommissioned); subscription as the isolation unit per
  workload+environment. Azure Policy assigned to management groups: deny non-approved regions,
  deny resources with a non-permitted public IP, require tags, require encryption — governance as
  code, not a wiki.

## 4. Networks — default-deny, minimal exposure

- Hub-spoke topology (or Virtual WAN at scale): hub with a firewall (Azure Firewall or NVA) and
  connectivity (ExpressRoute/VPN); spokes per workload, peered, **with no direct spoke-to-spoke
  transit** except via the hub. UDR forcing egress through the firewall on sensitive workloads
  (egress inspection and filtering, not just ingress).
- Default-deny NSGs on every subnet (the default rules allow too much intra-VNet: add an
  explicit deny); rules by Application Security Groups, not loose CIDRs. **`0.0.0.0/0`/`Any`
  inbound is forbidden without justification** — and then behind Front Door/Application
  Gateway with WAF.
- PaaS ALWAYS through **Private Link/Private Endpoints** (Storage, Key Vault, SQL, ACR, Cosmos…):
  `publicNetworkAccess: Disabled`. Private DNS zones centralised in the hub. Service
  endpoints are legacy: only if Private Link does not exist for that service (verify on the web).
- TLS 1.2+ minimum everywhere (`minimumTlsVersion`), HSTS on front ends; mTLS between services when
  the data demands it. Administrative access via Azure Bastion — **never public RDP/SSH**, nor
  JIT-VM-access as an excuse for a permanent public IP.
- DDoS Network Protection on VNets with prod public endpoints.

## 5. Data — encryption, proven backups, RTO/RPO

- Encryption at rest by default across the whole platform; **customer-managed keys (CMK) in Key
  Vault** for sensitive/regulated data (Storage, SQL TDE, Cosmos, disks with encryption at
  host). Key Vault: RBAC-mode, soft delete + purge protection non-negotiable, scheduled key
  rotation, one vault per workload/environment (blast radius).
- RTO/RPO defined before choosing SKU and redundancy: zone-redundant (ZRS/zonal) by default in
  prod; geo-redundancy (GRS/failover groups/Cosmos multi-region) only if the RPO/RTO demands it.
- Centralised Azure Backup (Recovery Services/Backup vault) with a tag-based policy, **soft delete
  + immutability enabled** (ransomware) and a cross-region copy if DR demands it. **A backup with no
  proven restore does not exist**: periodic, documented restore rehearsal. Azure Site Recovery
  for VM DR with an annual failover test as a minimum.
- Lifecycle management on Blob (hot→cool→archive according to real access); retention/deletion compliant with
  GDPR (minimisation, right to erasure). Expand/contract migrations.

## 6. Observability and operation

- Azure Monitor + a centralised Log Analytics workspace (per region/environment per ALZ); **Azure
  Monitor Agent** (AMA) with Data Collection Rules — MMA is dead. Diagnostic settings on EVERY
  prod resource (via Azure Policy deployIfNotExists, not by hand). Explicit per-table retention
  (cost); archive/basic logs for low-access data.
- Workspace-based Application Insights with OpenTelemetry (prefer the OTel SDK/distro over classic
  SDKs — verify status on the web); correlated traces, golden signals, SLOs with error
  budget; actionable alerts → on-call (action groups), not noise.
- **Microsoft Defender for Cloud**: plans enabled per resource type in prod (Servers,
  Storage, Containers, Databases, Key Vault…), Secure Score as a tracked metric, integration with
  the SIEM (Microsoft Sentinel) for detection and response; continuous export of findings.
- **Azure Policy as a gate**: initiatives (CIS/MCSB) assigned at management groups, with deny
  for the critical items and deployIfNotExists for the operational ones; compliance dashboard reviewed, zero
  exceptions without an expiry.
- Every change through a pipeline with a reviewed what-if/plan; blue-green/canary with slots or revisions
  (Container Apps) and proven rollback; runbooks and blameless postmortems.

## 7. FinOps — cost as a quality attribute

- **Mandatory tagging**: at minimum `owner`, `env`, `project`/`cost-center`, `managed-by`,
  enforced with Azure Policy (require + inherit from the resource group). No tags = orphan.
- Cost Management exports in **FOCUS** format (verify the supported version on the web — 1.3
  ratified Dec 2025) to Storage/warehouse; budgets with alerts per subscription/RG and anomaly
  detection active from day 1.
- Default levers: Reservations/Savings Plans for the stable baseline (with ≥30 days of data),
  Spot for fault-tolerant workloads, scale-to-zero (Container Apps/Functions) and auto-shutdown in
  non-prod, right-sizing with Azure Advisor. AKS: Flex CUDs/reservations according to the pattern — verify
  current offers on the web.
- Design cost inside the decision: Private Endpoints (per-hour+data), Azure Firewall, inter-region
  egress, Log Analytics ingest, DDoS Protection — estimated before deploying, not
  discovered on the bill.

## 8. Sustainability, lock-in and PROHIBITIONS

- **Conscious lock-in, not accidental**: proprietary services (Cosmos, Service Bus, Functions)
  only with a clear benefit; contracts behind own interfaces; cheap portability where possible
  (PostgreSQL flexible, OCI containers, OpenTelemetry, Dapr in Container Apps).
- Upgrade policy: supported versions ALWAYS (AKS N-2 at most with an auto-upgrade channel,
  current Functions/App Service runtimes, current ARM/Bicep API versions); review Azure
  Advisor retirements quarterly; the upgrade is planned work, not an emergency.
- **LIST OF PROHIBITIONS** (they block a review):
  - Static client secrets/keys where Managed Identity or workload identity federation exists;
    Storage access keys enabled without justification; long-lived SAS.
  - Public RDP/SSH; `Any`/`0.0.0.0/0` inbound without justification; PaaS with a public endpoint
    while Private Link is available; NSG missing on a workload subnet.
  - Resources created through the portal in prod (**clickops**) — everything through IaC (Bicep/Terraform);
    unreconciled drift; hand-written ARM JSON.
  - Resources without mandatory tags; permanent Owner/Contributor roles for humans; RBAC
    assignments to individual users instead of groups; privileged roles without PIM.
  - Key Vault without purge protection; secrets in app settings/code/logs; data without CMK when
    the classification demands it.
  - Retired services (list in section 2); the MMA agent; `latest` on prod images; classic/ASM
    resources.
  - Logs with no defined retention; single-zone prod while zones are available; a backup with no proven
    restore; a subscription outside the management group hierarchy.

## 9. Mandatory web verification

Before pinning any concrete Azure fact in code or in an answer, **search the web** (Learn
/ Azure Updates / Lifecycle first): service status and retirements, regional and SKU
availability, ARM/Bicep API version, exact plan/SKU names (they change often: Flex
Consumption, AKS Automatic, Azure Managed Redis…), prices and Build/Ignite news from the last
year. The model's memory is NOT a valid source for prices, retirement dates, recent feature
names or regional availability. If it cannot be verified, say so and mark the
decision as provisional.

If the web contradicts this document, **the web wins** — flag the discrepancy.
