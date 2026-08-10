---
name: kubernetes-standards
description: Kubernetes and container standards (staff/principal level). Use when writing or reviewing Dockerfiles/Containerfiles, OCI images, Kubernetes manifests (*.yaml with apiVersion/kind), Helm charts (Chart.yaml, values.yaml, templates/), Kustomize overlays (kustomization.yaml), GitOps configs (Argo CD Application, Flux Kustomization/HelmRelease), admission policies (Kyverno, OPA/Gatekeeper), image signing (cosign) or SBOM tooling. Also for Windows nodes and Windows containers (Server Core, Nano Server, ltsc2022/ltsc2025 base images, host/image version compatibility, runAsUserName, HostProcess, gMSA and GMSACredentialSpec) and for batch scheduling on Kubernetes (job queues, gang scheduling, Kueue, Volcano, ResourceQuota).
---

# Kubernetes and container standards

## 1. Scope and triggers

Applies when creating or reviewing: `Dockerfile`/`Containerfile`, K8s manifests (`*.yaml` with `apiVersion`/`kind`), Helm charts (`Chart.yaml`, `templates/`), `kustomization.yaml`, Argo CD/Flux resources, Kyverno/OPA policies, pipelines that build/sign/deploy images. Does not apply to local development Compose (use proportionate judgement).

**Not applicable**: see `iac-standards` (provisioning of the cluster and the infrastructure with Terraform/OpenTofu and Ansible; the boundary is decided there: **cluster and platform with TF/Tofu, workloads via GitOps**), `aws-standards`/`azure-standards`/`gcp-standards` (the managed control plane —EKS/AKS/GKE—, its integration with IAM/VPC and its cost; here what runs inside), `container-runtime-security-standards` (what happens **after the Pod starts**: seccomp, runtime choice and pinning, container escape, runtime detection with Falco/Tetragon/eBPF, drift and node forensics; here admission, Kyverno policies, Pod Security Standards, declarative `securityContext` and signature verified at admission), `selinux-standards` (the container's MAC: `container_t`, MCS, `:z`/`:Z`, `udica`, AppArmor profiles), `networking-standards` (underlying physical network, VLAN, BGP and MTU; here Services, Gateway API and NetworkPolicy), `cicd-standards` (the pipeline that builds and signs the image and triggers the deployment; here the resulting manifest and the verification at admission), `observability-standards` (Prometheus, OTel Collector and their rules; here only probes, resources and the `ServiceMonitor`), `sre-practice-standards` (SLOs, capacity and on-call), `appsec-standards` (application code), `vulnerability-management-standards` (triage and SLA of the CVEs Grype/Syft report), `cryptography-pki-standards` (signing key management and internal PKI; here only the use of cosign and cert-manager), `identity-access-management-standards` (IdP and federation; here cluster RBAC and ServiceAccounts), `homelab-standards` and `onprem-standards` (single-node k3s/Talos and the hardware/OS underneath), `air-gapped-standards` (**the internal registry/mirror and the network isolation of a cluster with no route to the Internet are theirs**: how the image gets in and is verified inside the enclave, patching without feeds, time and the internal PKI; here the cluster, its admission and its manifests), `finops-standards` (`requests`/`limits`, scaling and scheduling belong here; **their cost and the split between teams sharing a node, theirs** — the allocation problem in Kubernetes is real and their method solves it), `platform-engineering-standards` (**the cluster and its operation belong here**; **the abstraction offered on top to the product team is theirs** — if the developer writes Kubernetes YAML by hand, the platform has not done its job, and that is their decision, not this skill's), `windows-server-ad-standards` (**the gMSA account in the directory is theirs**: KDS root key, `New-ADServiceAccount`, `PrincipalsAllowedToRetrieveManagedPassword`, SPN, joining the node to the domain; **its consumption from the Pod —CRD, RBAC and `gmsaCredentialSpecName`— belongs here**), `dotnet-framework-legacy-standards` (whether the app can be ported to modern .NET and at what cost: that decision is theirs and **overrides the decision to containerise**; here only how the Windows container is run if the answer is that it is not ported) and `legacy-modernization-standards` (the rehost/replatform/rewrite strategy for the monolith), `hpc-standards` (**the criteria for when batch should not run on Kubernetes and stays on Slurm are theirs**; here queues and gang scheduling *inside* the cluster) and `gpu-computing-standards`/`mlops-standards` (the GPU, its device plugin and the training pipeline; here how the batch is queued and scheduled), `webassembly-standards` (Wasm is sometimes sold as a container replacement: **the node runtime, admission, isolation and workload scheduling still belong here**, including runwasi/`containerd-shim-spin`-style *shims*; **the Wasm module, its host, its imports and its fuel and memory limits are theirs**. The boundary matters because **the Wasm sandbox does not replace node isolation**: it only bounds what the module can ask for).

## 2. Default toolchain

> **Mandatory web verification**: these versions were checked in **August 2026**. Before pinning versions in a real project, re-verify with WebSearch (official releases + endoflife.date). Do not pin from memory.

| Tool | Stable line (2026-08) | Criteria |
|---|---|---|
| Kubernetes | **1.36.x** (1.37 ships 2026-08-26); supported N-2: 1.34–1.36 | Never operate a minor outside upstream/managed support |
| Helm | **4.2.x** (Helm 3 EOL: fixes until 2026-09, security until 2027-02) | New projects on Helm 4; plan the migration of v2 charts |
| Argo CD | **3.4.x** (3.5 in RC: internal mTLS, commit signature verification) | Only 3 minors receive patches: keep a quarterly cadence |
| Flux | **2.8.x** | A valid alternative; pick one per organisation, not both |
| Kyverno | **1.18.x** | Admission by default (CEL + `ImageValidatingPolicy`); OPA/Gatekeeper only if Rego is already there |
| cosign | **3.x** (bundle format by default; v4 will remove deprecated flags) | Do not use deprecated v2 flags in new pipelines |
| **Grype + Syft** (image and SBOM), **checkov**/**kubescape** (manifests) | latest stable | Default after the **Trivy supply-chain compromise (March 2026)**: tag poisoning of `trivy-action`/`setup-trivy` with theft of CI secrets. If you use Trivy, **pin by SHA/digest**, verify the signature and follow its advisories — the scanner runs in CI with access to secrets by design |

- **Ingress NGINX is retired** (no releases or patches since 2026-03-24): forbidden in new deployments; migrate to Gateway API (Envoy Gateway, Cilium, the provider's ingress).
- Gateway API over Ingress for new north-south traffic.

## 3. Structure and conventions

### Dockerfile / OCI image
- **Multi-stage always**: build stage with the full toolchain, minimal final stage. The final artifact contains no compilers, package shells or caches.
- **Minimal base**: distroless (`gcr.io/distroless/*`), chainguard or `scratch` for static binaries. Alpine only if you need a shell and you justify it.
- **Pin by digest** on the base image: `FROM registry/image:tag@sha256:...` (the tag is documentation; the digest is the contract). Renovate/Dependabot updates the digests.
- **Non-root**: numeric `USER` (`USER 65532:65532`), never `USER app` (a name does not verify the UID at admission).
- One process per container; `ENTRYPOINT` in exec form (`["binary"]`), signals propagated correctly (correct PID 1 or tini).
- `.dockerignore` mandatory; no secrets in build args or in layers (use BuildKit's `--mount=type=secret`).
- OCI labels (`org.opencontainers.image.source|revision|version`) for traceability.

Canonical skeleton:

```dockerfile
FROM golang:1.24-bookworm@sha256:<digest> AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12:nonroot@sha256:<digest>
COPY --from=build /out/app /app
USER 65532:65532
ENTRYPOINT ["/app"]
```

### K8s manifests (every prod workload)
- **`resources.requests` and `limits` always**: realistic requests (basis for scheduling and HPA); memory limit = request (avoids surprise OOM); CPU limit optional and justified (throttling).
- **Probes**: `readinessProbe` mandatory; `livenessProbe` only if the process can hang without dying (misused, it kills healthy pods); `startupProbe` for slow starts.
- **Explicit `securityContext`** (pod and container): `runAsNonRoot: true`, `readOnlyRootFilesystem: true` (+ `emptyDir` for tmp), `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`.
- **Pod Security Standards `restricted`** enforced per namespace (labels `pod-security.kubernetes.io/enforce: restricted`); exceptions documented per workload, never `privileged` at the level of an application namespace.
- **PDB** for every Deployment/StatefulSet with >1 replica (`maxUnavailable: 1` as a sane default). Without a PDB, a node drain is an incident.
- **Default-deny NetworkPolicy** (ingress and egress) per namespace + explicit allowlist per flow. DNS (53/UDP+TCP towards kube-dns) is the only implicitly permitted egress.
- `topologySpreadConstraints` or multi-AZ anti-affinity for replicas; `priorityClassName` defined.
- ≥2 replicas in prod; HPA on real metrics, not just CPU if the bottleneck is elsewhere.
- `:latest` and mutable tags forbidden in `image:`; `imagePullPolicy: Always` forbidden as a patch for mutable tags.

Canonical container `securityContext` (the default, not the exception):

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities: { drop: ["ALL"] }
  seccompProfile: { type: RuntimeDefault }
```

Base default-deny NetworkPolicy per namespace (ingress+egress, DNS allowed):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny }
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  egress:
    - to: [{ namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: kube-system } } }]
      ports: [{ port: 53, protocol: UDP }, { port: 53, protocol: TCP }]
```

### Helm / Kustomize
- **Helm** for distributable/parameterisable software; **Kustomize** for your own environment overlays. Recommended pattern: base chart + per-environment overlays, or per-environment values in Git (`values-<env>.yaml`).
- Charts: `values.yaml` with safe defaults (the chart renders safely with no overrides), `values.schema.json` mandatory, `helm-docs` for the README, SemVer versioning of the chart independent of `appVersion`.
- No complex logic in templates: if you need more than one nested `if/range`, move the decision up to values or to a helper.
- Charts published in an **OCI registry** (not legacy HTTP repos), signed with cosign.

### GitOps (Argo CD / Flux)
- **Git is the only path to prod**: every change of cluster state goes through a PR. Manual `kubectl apply`/`edit`/`scale` against prod is forbidden except for documented break-glass (and it is reconciled afterwards).
- **App-of-apps** pattern (Argo) or hierarchical `Kustomization` (Flux); a "deploy" repo/dir separate from the app code (or a dedicated directory with CODEOWNERS).
- `syncPolicy.automated` with `prune: true` and `selfHeal: true` in non-production environments; in prod, auto-sync only with gates (health checks + windows) or approved manual sync — an explicit decision per organisation.
- Drift = alert: `selfHeal` or notification, never silent drift.
- Promotion between environments = promotion of the **same image digest** through Git (image updater or automated PR), never a rebuild per environment.

### Windows nodes and containers

Everything above assumes Linux. On a Windows node **the canonical invariants of §3 are not degraded: they are inapplicable or false**, and the expensive failure mode is a manifest that declares them, passes admission and protects nothing. Typical scenario: a .NET Framework monolith on IIS that is containerised because it cannot be ported.

**Host↔image compatibility (the hard rule).** The host's OS build and the base image's **must match**; only the revisions (4th digit) may differ from 1809 onwards. Microsoft offers Hyper-V isolation as an escape hatch for mismatched versions, but **Kubernetes does not support it** ("Kubernetes does not support running Windows containers with Hyper-V isolation") — in a cluster that escape hatch **does not exist**: the image simply does not start (`0xc0370101`, `ContainerCannotRun` → `CrashLoopBackOff`).

| Host | Images that start on K8s (process isolation) |
|---|---|
| Windows Server 2025 | ltsc2025, ltsc2022 |
| Windows Server 2022 | ltsc2022 |
| Windows Server 2019 | ltsc2019 (but WS2019 is no longer a supported node) |

- **Kubernetes 1.36 supports Windows Server 2022 and 2025 as nodes, nothing else.** WS2022 leaves mainstream on **2026-10-14** (extended until 2031-10-15) and *"Containers released with Windows Server 2022 follow the same lifecycle dates"* → new nodes and images go to **ltsc2025**; a WS2022 node today is born with two months of full support left.
- Automatic label `node.kubernetes.io/windows-build`: **WS2022 = `10.0.20348`**, **WS2025 = `10.0.26100`**. With two Windows versions in the cluster it is mandatory in the `nodeSelector`, not optional.

**Base image: there is no distroless, no `scratch`, nothing like it.** Sizes measured from the MCR manifests (compressed in registry, Aug 2026):

| Image | Size | What it ships |
|---|---|---|
| `windows/nanoserver:ltsc2025` | **0.19 GB** | No PowerShell, no WMI, **no servicing stack, no .NET Framework**. Modern .NET only |
| `windows/servercore:ltsc2025` | **2.3 GB** | The **only** one that runs .NET Framework and IIS |
| `windows/server:ltsc2025` | **6.55 GB** | Full API, GPU, no IIS connection limit. Only if Server Core is not enough |

- An IIS monolith **goes to Server Core**: that is a platform fact, not a choice. Start from `mcr.microsoft.com/dotnet/framework/aspnet:4.8.1-windowsservercore-ltsc2025` instead of installing IIS by hand.
- No `latest` tag on these images since 2019-04-16; the digest pinning of §3 applies just the same, and now it weighs 12-30× more on pull and on node disk.
- **One process per container is not met**: Server Core starts the Service Control Manager and IIS runs as a service (`w3wp`). Do not try to force it; monitor the service, not PID 1.
- **`USER 65532:65532` is impossible**: Windows has no UID/GID, identity is a SID. The equivalent is `USER ContainerUser` in the Dockerfile or `securityContext.windowsOptions.runAsUserName` in the Pod (`ContainerUser`, `ContainerAdministrator`, `NT AUTHORITY\NETWORK SERVICE`…).
- **The default user is not non-root**: verified against the config blob in MCR, `servercore` and `windows/server` **do not set `USER`** → the process runs as `ContainerAdministrator`; only `nanoserver` sets `USER ContainerUser` (ltsc2022 and ltsc2025). That is, **the image the IIS monolith needs is exactly the one that starts as administrator**: setting `runAsUserName` is mandatory, not hygiene.

**A `securityContext` that is silently ignored — the dangerous failure.** With `.spec.os.name: windows`, the API server **rejects** a Pod that sets `hostPID`, `hostIPC`, `shareProcessNamespace`, `seLinuxOptions`, `seccompProfile`, `fsGroup`, `fsGroupChangePolicy`, `sysctls`, `supplementalGroups`, `runAsUser`, `runAsGroup`, `capabilities`, `readOnlyRootFilesystem`, `privileged`, `allowPrivilegeEscalation` or `procMount`. **Without `.spec.os.name`, the very same manifest is admitted and those fields do absolutely nothing.** The canonical `securityContext` of §3 on a Windows node passes CI, passes admission, passes the checklist — and gives zero protection.

- → **`.spec.os.name` is mandatory on every Pod** (`windows` and `linux` alike): it is the only mechanism that turns that silence into a rejection. Kyverno gate to require it.
- At the Pod level only `securityContext.runAsNonRoot` and `securityContext.windowsOptions` work. Here `runAsNonRoot: true` means "not `ContainerAdministrator`", not "UID≠0".
- `readOnlyRootFilesystem` **is not implementable** on Windows ("write access is required"): do not ask for it, do not audit it, do not put it in the exception.
- **PSS `restricted` stops enforcing half of it**: privilege escalation, seccomp and capabilities are *Linux only* controls since 1.25 (`spec.os.name != windows`). What is left alive: `runAsNonRoot`, no HostProcess, no host namespaces, no hostPath. A mixed namespace labelled `restricted` **does not mean the same thing for each half** — document what it actually controls on each.
- **There are no privileged containers on Windows**; the equivalent is **HostProcess** (`windowsOptions.hostProcess: true`, stable since 1.26), which runs on the host with its privileges. Treat it like `privileged`: forbidden except for a signed exception for node agents.

**Scheduling in a mixed cluster.**
- `nodeSelector: kubernetes.io/os: windows` on every Windows workload; `.spec.os.name` **does not affect scheduling**.
- **Taint the Windows nodes** (`--register-with-taints='os=windows:NoSchedule'`) + toleration in the Pod. Without the taint, any Linux Deployment with no selector lands on a Windows node.
- **A Linux DaemonSet without a `nodeSelector` breaks by definition**: a DaemonSet goes to *every* node that tolerates its taints, and many agents (CNI, logs, node-exporter, runtime scanner, CSI) ship broad tolerations that cancel out the taint. **Review every DaemonSet in the cluster before adding the first Windows node**, not after the incident.
- `RuntimeClass` with `scheduling.nodeSelector` + `tolerations` encapsulates the pair when there are many workloads.
- The kubelet on Windows **does not enforce memory or CPU limits**: `--kube-reserved`/`--system-reserved` only subtract from `NodeAllocatable`, `PIDPressure` is not implemented and there is no OOM eviction. `limits` do not protect the node the way they do on Linux → size with headroom and alert on **node** memory. There is also no full `kubectl exec`, no pod metrics, no HPA, no ResourceQuota and no scheduler preemption with the same semantics: do not take any part of §6 for granted without checking it on Windows.

**gMSA: domain identity for the Pod** (what an IIS monolith almost always needs for integrated authentication against AD).
- CRD `GMSACredentialSpec`, group `windows.k8s.io`, **`apiVersion: windows.k8s.io/v1`** (`v1alpha1` deprecated and non-storage), plus the two webhooks from `kubernetes-sigs/windows-gmsa` (**v0.13.0**, Apache-2.0, verified in raw): one *mutating* that expands the name into the full credspec, one *validating* that checks authorisation.
- Authorisation = RBAC over the credspec: `apiGroups: ["windows.k8s.io"]`, `resources: ["gmsacredentialspecs"]`, `verbs: ["use"]`, `resourceNames: [<credspec>]`, bound to the workload's ServiceAccount. Without that binding the webhook rejects. **One credspec per application**, never a shared one: it is a domain identity, not a ConfigMap.
- Consumption: `securityContext.windowsOptions.gmsaCredentialSpecName`, at Pod or container level.
- **The password is never in the cluster**: the **node** retrieves it from Active Directory. Design consequence: the Windows node is a domain principal and **any authorised pod on that node acts as the service account** — compromise of the node is compromise of the account. A domain-joined Windows node inside a multi-tenant cluster is a risk decision, not an installation detail.
- Boundary: the account in the directory belongs to `windows-server-ad-standards` (§1).

**Coupled patching (real operational impact).** The Windows base image **has no servicing stack**: it is not patched inside, it is **rebuilt**. Microsoft republishes the bases on the **second Tuesday of every month** ("B release") and that is *"the only regular release that include new security fixes"*.
- **Mandatory monthly rebuild** of every Windows image even if the app does not change, aligned with the B cycle — not "when convenient". The scheduled rebuild of §7 here has a fixed date imposed from outside.
- The host is patched in the same window and at the same cadence: **the node's patching calendar overrides the app's deployment calendar**, the opposite of Linux.
- Host and image do not need the same revision (1809+), but they do need the same build. A WS2022→WS2025 node upgrade forces rebuilding **every** image to ltsc2025 first, not afterwards.

**When NOT to containerise Windows** (honest criteria, decided before writing the Dockerfile):
- Interactive installer, GUI, drivers, access to hardware or to the host registry, or local state that must survive a restart → **VM**. There is no shortcut.
- If the real destination is modern .NET: **porting to .NET 8+ and a Linux container is usually less total work** than containerising the Framework, and the result does get the invariants of §3 (distroless, non-root, read-only, full PSS). That comparison is decided by `dotnet-framework-legacy-standards`.
- If there are no Windows nodes in production already, the cost is not the image: it is a **second node pool** with licences, coupled monthly patching, 2-6.5 GB images, and the whole ecosystem of DaemonSets, observability and security duplicated and verified on Windows. For 1-3 applications it rarely pays off.
- An app deployed twice a year gains nothing from Kubernetes: what you gain is scaling and frequent deployment. If you do not need them, the VM is cheaper and simpler.
- Containerising Windows is valid as an **intermediate step with an exit date**, not as a permanent destination. If there is no date, it is an expensive VM with more moving parts.

## 4. Quality and testing (CI gates)

Minimum pipeline that **breaks the build**:
1. **Lint**: `hadolint` (Dockerfile), `yamllint`, `helm lint` + render (`helm template` with no errors), `kustomize build` of every overlay.
2. **Schema validation**: `kubeconform` (with CRD schemas) over the rendered YAML of **all** environments.
3. **Policies in CI (shift-left)**: `kyverno apply` / `conftest` with the same policies as the cluster's admission — what breaks at admission must break earlier in CI.
4. **Chart tests**: `helm unittest` for template logic; `chart-testing` (`ct lint`/`ct install`) against kind/k3d in chart PRs.
5. **Scanning**: **Grype + Syft** over the image (CVEs and SBOM, gate on CRITICAL/HIGH with documented triage) and **checkov**/**kubescape** over the manifests — not Trivy by default (§2), and if it is used, pinned by digest and with its advisories followed. Secret scanning: the scanner and its licence are set by `secrets-management-standards` (as of Aug 2026 `gitleaks` is *feature complete* and its GitHub action requires a commercial licence for organisations: verify before pinning it).
6. **Visible diff in the PR**: render of the resulting YAML (argocd diff / flux diff / helm diff) as a comment — what is going to be applied is reviewed, not just the template.

## 5. Security

### Supply chain
- **Signing with cosign (keyless, CI's OIDC)** of every image and chart that reaches prod; **verification at admission** (Kyverno `ImageValidatingPolicy`/verifyImages): an image without a valid signature does not run.
- **SBOM** (syft, SPDX or CycloneDX format) generated at build, attached as an attestation (`cosign attest`), not as a loose file.
- SLSA provenance (builder provenance attestation) verified where the registry/CI supports it.
- Private registry with pull-through cache; direct pulls from Docker Hub forbidden in prod (rate limits + supply chain).
- Renovate/Dependabot for bases and images: updating a digest is a PR, not a manual event.

### Runtime and cluster
- Admission with Kyverno in `Enforce` mode for the baseline (non-root, no privileged, digests, allowed registries, requests/limits, probes); `Audit` only as an introduction phase, with a date for moving to Enforce.
- Minimal RBAC: no `cluster-admin` for humans or for app ServiceAccounts; `automountServiceAccountToken: false` unless needed.
- **Secrets never in the clear in Git**: External Secrets Operator against Vault/Secrets Manager (preferred) or SOPS+age if there is no manager. `Secret` in plain YAML or in Helm values without encryption is forbidden.
- Secrets encryption at rest in etcd (KMS provider) and east-west mTLS (mesh or Cilium) where the risk profile calls for it.

## 6. Operability

- **Non-negotiable observability**: Prometheus metrics (`/metrics`), structured JSON logs to stdout, OTLP traces. Without telemetry, there is no prod deployment.
- Real health endpoints: readiness reflects critical dependencies (with judgement: do not take the pod down for a degraded dependency that has a fallback).
- **Safe deployment**: rolling update with `maxUnavailable: 0` as the default; canary/blue-green (Argo Rollouts or Flagger) for critical services, with automatic analysis over metrics.
- **Tested rollback**: `helm rollback`/Git revert rehearsed in staging; a backwards-incompatible data migration blocks the rollback — use expand/contract.
- `terminationGracePeriodSeconds` matched to the app's real drain; the app handles SIGTERM.
- Alerts on symptoms (golden signals) + GitOps state (app OutOfSync/Degraded, failed reconcile), not on every restart.

### Batch queues and gang scheduling

All of §6 assumes long-lived services. For batch (distributed training, simulation, bulk ETL) the cluster **does not ship what is needed** and it has to be added explicitly.

**What the default scheduler does not do.** `kube-scheduler` *"selects an optimal node to run newly created or not yet scheduled (unscheduled) pods"* in two phases, *filtering* and *scoring*, and assigns **Pod by Pod**. There is no job queue, no service priority between batches, no group semantics: neither the scheduler docs nor the `Job` docs mention gang, queuing or all-or-nothing.

**What that breaks.** A job that needs its N pods **at the same time** (synchronous training, MPI, anything with pod-to-pod communication) can end up with N-1 pods running and occupying resources, waiting indefinitely for the last one. With two such jobs competing, each blocks the other: **resource deadlock**. Verbatim from the Kueue docs: *"a pair of such jobs may deadlock if the physical availability of resources do not match the configured quotas in Kueue. The same pair of jobs could run to completion if their pods were scheduled sequentially."* Nobody detects it and nothing breaks: the signal is low utilisation with eternally `Pending` pods and a cluster that "is full". Outside a real load test it does not show up; in production, it does.

**`ResourceQuota`/`LimitRange` are not the solution** and mistaking them for it is the usual error. `ResourceQuota` *"provides constraints that limit aggregate resource consumption per namespace"*, and on violation *"the control plane rejects that request with HTTP status code `403 Forbidden`"*: that is **rejection at admission, not queuing** — no service order, no retry, no "it gets in when there is room". It also acts object by object, so nothing stops it admitting N-1 pods of the job and rejecting the last one. `LimitRange` only sets defaults and min/max per object. They are consumption guardrails; **they are not a scheduler**.

`schedulingGates` (Pod Scheduling Readiness, **GA in 1.30**) and `Job.spec.suspend` are the *hooks* on which a queue manager is built — they hold individual pods or objects so an external integrator can decide. They provide no group semantics by themselves.

**The two real options** (verified Aug 2026; both Apache-2.0 read in raw):

| | **Kueue** | **Volcano** |
|---|---|---|
| What it is | **Job-level** queue manager on top of the default scheduler | **Full batch scheduler**, replacing/added to the default one |
| Version | **v0.19.0** (2026-07-22) | **v1.15.1** (2026-07-30) |
| Governance | `kubernetes-sigs`, **official SIG Scheduling subproject** | **CNCF Incubating** (accepted 2020-04-09, incubating 2022-03-21) |
| API | `kueue.x-k8s.io/**v1beta2**` (v1beta1 deprecated, non-storage). **There is no v1 GA** | `scheduling.volcano.sh/v1beta1` (PodGroup, Queue) and `batch.volcano.sh/**v1alpha1**` (Job) |
| CRDs | ClusterQueue, Cohort, AdmissionCheck, Topology (cluster) · LocalQueue, Workload (namespaced) | PodGroup (ns), Queue (cluster), Job (ns) |
| All-or-nothing | `waitForPodsReady` in the controller's Configuration | `gang` plugin over `PodGroup.minMember`/`minResources` |
| Requirement | K8s ≥ 1.29 | — |

- **Kueue** suspends and queues the Workload until there is quota; `waitForPodsReady` (30 min timeout by default, `recoveryTimeout`, `requeuingStrategy` with backoff) evicts and requeues the job if not all its pods start. With `blockAdmission: true` it admits **sequentially** to break the deadlock — at the cost of serialising starts even when there is plenty of room. It is a mitigation, not strict gang scheduling.
- **Volcano** does real gang: `minMember` — *"if there's not enough resources to start all tasks, the scheduler will not start anyone"* — plus fair-share between `Queue`s and scheduling policies (binpack, NUMA, topology). The price: **a second scheduler in the cluster** and a Job API still on `v1alpha1` despite years in incubation. Weigh it up.
- **Criteria**: if what is missing is **queues, per-team quotas and job admission**, Kueue (you keep a single scheduler and it fits `Job`, JobSet and the training operators). If you need **strict gang and scheduling policies**, Volcano. **One per organisation, not both**: two schedulers deciding over the same node pool is an incident waiting to happen; if they coexist, partition by taints and be explicit about which nodes each one manages.
- **JobSet** (`jobset.x-k8s.io/v1alpha2`, v0.12.0, sig-apps) groups several `Job`s as a unit for HPC/ML. Still **alpha**: it complements Kueue, it does not replace it.
- **Forbidden to simulate gang by hand**: `initContainers` waiting for their peers, creative `podAffinity` or startup sleeps are the same deadlock with more steps and no observability.

**When the right answer is not to use Kubernetes.** If the batch is classic HPC —tight MPI, low-latency interconnect, whole-node reservation, accounting by CPU-hours, users submitting with `sbatch`— **the answer is usually Slurm, not a Kubernetes cluster with two operators on top**. Those criteria belong to `hpc-standards` and are consulted there before building anything here. The practical boundary: if what you already have lives in Kubernetes and all that is missing are queues, Kueue/Volcano; if what you have is a computing centre, do not reimplement it in YAML.

## 7. Sustainability and prohibitions

- **Upgrade cadence**: K8s publishes 3 minors/year and supports N-2 → plan **at least 2 minor upgrades per year**; never more than one minor behind the managed provider's support. Before upgrading: read the deprecations (`kubectl api-resources`, Pluto for removed APIs), update charts/operators, rehearse in staging.
- Argo CD/Flux/Kyverno: stay within the 3 supported minors (quarterly review cadence).
- Refresh base images even if the app does not change (scheduled weekly/monthly rebuild: the CVEs arrive on their own).

**FORBIDDEN** (automatic gate wherever possible):
- `:latest` or mutable tags in prod; images without a digest.
- Manual `kubectl apply`/`edit`/`scale`/`port-forward` against prod outside documented break-glass.
- Root containers, `privileged`, `hostNetwork`/`hostPID`/`hostPath` without a signed exception.
- Secrets in the clear in Git, in values, in the manifest's env or in logs.
- Workloads without requests/limits, without a readiness probe or without a PDB (multi-replica) in prod.
- Application namespaces without a default-deny NetworkPolicy or PSS `restricted`.
- An unsigned image or one without an SBOM on the path to prod.
- Ingress NGINX in new deployments (retired project, no security patches).
- Helm 2/3 in new projects; charts without `values.schema.json`.
- Tolerated drift: resources in the cluster that do not exist in Git.
- A mixed Linux/Windows cluster with Pods lacking `.spec.os.name`, lacking a `kubernetes.io/os` `nodeSelector` or with untainted Windows nodes; a Linux DaemonSet without a selector after adding the first Windows node.
- Taking the protection of a Linux `securityContext` (seccomp, capabilities, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`) at face value on a Windows workload: it does not protect, it is ignored.
- A Windows image without a monthly rebuild aligned with the "B release"; a base image whose build does not match the node's.
- Gang scheduling simulated with `initContainers`, affinities or waits; two batch schedulers over the same node pool without partitioning.

### Quick review checklist (every workload PR to prod)

- [ ] Image by digest, signed, with an SBOM; distroless/minimal base and numeric non-root.
- [ ] requests/limits, readiness probe, PDB (if >1 replica), multi-AZ topology.
- [ ] Full restricted securityContext; namespace with PSS `restricted` + default-deny NetworkPolicy.
- [ ] No secrets in the clear; dedicated ServiceAccount with minimal RBAC and the token not mounted if unused.
- [ ] Render validated (kubeconform) + admission policies passed in CI; YAML diff visible in the PR.
- [ ] Metrics/logs/traces exposed; SIGTERM handled; rollback rehearsed or an expand/contract plan if there is a migration.
- [ ] If Windows: `.spec.os.name: windows`, `nodeSelector`+toleration, image build equal to the node's (`node.kubernetes.io/windows-build`), `runAsUserName` set, no Linux `securityContext` fields, and a monthly rebuild planned.
- [ ] If multi-pod batch: queue manager (Kueue or Volcano) declared and all-or-nothing semantics configured — not `ResourceQuota` as a substitute.

## 8. Mandatory web verification

Before pinning any version, API (`apiVersion`), flag or feature in deliverables:
1. **WebSearch/WebFetch** of the component's official release and endoflife.date (K8s, Helm, Argo CD/Flux, Kyverno, cosign) — the ecosystem rotates every quarter and this document ages.
2. Verify the K8s API deprecations of the target version jump (official release notes + Pluto).
3. Cosign: confirm whether v4 has shipped (it removes v3's deprecated flags) before writing signing pipelines.
4. **Windows**: re-verify on MS Learn (`version-compatibility`, `container-base-images`, `update-containers`) the host↔image matrix and the lifecycle before choosing a base — it is where the most stale information circulates. Check on `kubernetes.io/docs/concepts/windows/intro` which Windows Server versions are supported nodes on your K8s minor (as of 1.36: **only 2022 and 2025**) and whether the list of unsupported `securityContext` fields has changed. **WS2022 leaves mainstream on 2026-10-14**: from that date this table no longer describes a viable option for new nodes. The image sizes were measured from the MCR manifests in Aug 2026 and change with every "B release": measure them again (`/v2/<img>/manifests/<tag>` → sum of `layers[].size`), do not quote them from here.
5. **Batch**: re-verify the version and maturity of **Kueue** (is it still on `v1beta2` or is there a `v1` GA?) and of **Volcano** (is it still Incubating in the CNCF or has it graduated? is its `Job` still on `v1alpha1`?), and the status of **JobSet** (alpha as of Aug 2026). Cross-check the project's official site against `api.github.com`, not against the releases feed.
6. If you cannot verify, say so explicitly in the deliverable instead of assuming.

**Declared gaps (Aug 2026), to be verified before using them as data**:
- The on-disk (uncompressed) sizes of the Windows images **were not measured**: the figures in the table are the registry's compressed sizes. On node disk they are significantly larger.
- Kueue's official installation page (`kueue.sigs.k8s.io/docs/installation/`) **could not be fetched**: v0.19.0 is backed by `api.github.com` + the Atom feed + the repo source at the tag, but **without confirmation from the project's website**.
- Of Kueue's CRDs, the manifests for ClusterQueue, AdmissionCheck, Topology and Workload were read; **`LocalQueue` and `ResourceFlavor` are assumed to follow the same `v1beta1` deprecated / `v1beta2` storage pattern by extrapolation**, not by direct reading.
- For the Volcano `Job`, the group, kind and `v1alpha1` version were confirmed, but **not the `served`/`storage` booleans** of the manifest. The chain `Job.minAvailable` → `PodGroup.minMember` is reasoned inference: the CRD does not document that field.
- The CNCF TAG that Volcano belongs to **was not verified** against a current primary source.
- The **v0.13.0** version of `windows-gmsa` comes from `api.github.com`; the project does not publish its own website to cross-check it against.

If the web contradicts this document, **the web wins** — flag the discrepancy.
