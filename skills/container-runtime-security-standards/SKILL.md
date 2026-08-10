---
name: container-runtime-security-standards
description: Container runtime security and container escape defense. Use when writing or debugging seccomp profiles (RuntimeDefault, seccomp.json, --security-opt seccomp), choosing or pinning a container runtime (runc, crun, gVisor/runsc, Kata Containers, RuntimeClass), rootless Podman or user namespaces (hostUsers, /etc/subuid), --privileged, capability drops (CAP_SYS_ADMIN, CAP_SYS_MODULE, CAP_BPF), a mounted docker.sock or containerd.sock, hostPath/hostPID/hostNetwork/hostIPC exposure, runtime detection with Falco rules, Tetragon TracingPolicy, Tracee or KubeArmor, eBPF agent privileges, container drift and read-only rootfs, or forensic container checkpointing with CRIU/checkpointctl and node/runtime log capture.
---

# Running-container security standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the security of the container once it is already running**: where the manifest no longer
protects because the process exists, has a shared kernel underneath and an attacker inside. Covers the
isolation model and its limits, the choice and pinning of the runtime, rootless and user
namespaces, seccomp, container escape paths and their mitigation, runtime detection
(eBPF, Falco, Tetragon, Tracee, KubeArmor), the drift of the immutable container, signature
verification at execution time, container and node forensics, and the applicable
benchmarks.

Triggers: `seccomp`, `RuntimeDefault`, `seccomp.json`, `--security-opt seccomp=`,
`SeccompDefault`/`--seccomp-default`, `runc`, `crun`, `runsc`/gVisor, `kata-runtime`,
`containerd-shim-kata-v2`, `RuntimeClass`, `hostUsers`, `/etc/subuid`, `/etc/subgid`, rootless
Podman, `--privileged`, `no-new-privileges`, `CAP_SYS_ADMIN`, `CAP_SYS_MODULE`,
`CAP_DAC_READ_SEARCH`, `CAP_BPF`, `docker.sock`, `containerd.sock`, `crio.sock`, `hostPath`,
`hostPID`, `hostNetwork`, `hostIPC`, mounted `/proc` and `/sys`, cgroups v1/v2, `falco`,
`falco_rules.yaml`, `tetragon`, `TracingPolicy`, `tracee`, `kubearmor`, `bpftool`,
`unprivileged_bpf_disabled`, `readOnlyRootFilesystem`, `criu`, `checkpointctl`, the kubelet's
`/checkpoint/`, `kube-bench`, `docker-bench`, "container escape", "the container has been modified at
runtime".

**Guiding principle**: **a container is a host process with namespaces and cgroups, not a
virtual machine.** It shares the kernel, and therefore shares the surface: every capability, every host
mount and every unfiltered syscall is a direct path to the node. The whole of §3 derives from that fact.
Operational corollary: **what prevents the escape is the runtime configuration; what tells you it has
happened is runtime detection. They are different controls and you need both.**

**Posture**: this skill is **defensive**. It describes **risk class, indicator and mitigation**.
It contains no payloads, exploitation chains or step-by-step recipes; authorised offensive work lives
in `offensive-security-standards`.

**Not applicable**: see `kubernetes-standards` (**a split already agreed on both sides**: there
*admission*, Kyverno/Gatekeeper policies, Pod Security Standards, `securityContext` as **declarative
Pod hardening**, signing at admission and all image building; **here** what happens after
the Pod starts: runtime, seccomp, escape, detection, drift and node forensics);
`selinux-standards` (**the container's MAC is theirs, without exception**: `container_t`,
`container_file_t`, MCS categories, `container-selinux`, `:z`/`:Z`, `udica`, `seLinuxOptions`,
`seLinuxChangePolicy` and the authoring of AppArmor profiles. **Here**: `seccomp` —which belongs to
this skill—, and **detecting that the MAC has been disabled, bypassed or that a process has escaped
despite it**; if the problem is an AVC or a label, it belongs there); `linux-hardening-standards`
(**the node OS baseline**: CIS/STIG, `sysctl`, auditd, SSH, mounts, measured boot — the hardened node
is their boundary; here only the `sysctl`s and capabilities specific to the runtime and why they
matter); `operating-systems-standards` (**the mechanism is theirs**: what a namespace really is, what a
cgroup isolates and what neither of the two isolates; **here seccomp, the escape and its detection**);
`onprem-standards` (the platform umbrella: hardware, hypervisor, fleet, OOB plane);
`incident-response-forensics-standards` (**the full forensic process**: phases, chain of custody,
order of volatility, imaging, timeline, Velociraptor/Volatility — **here only what container and node
artifact exists, how long it lasts and how it is captured before it evaporates**);
`incident-management-standards` (incident governance: severity, IC, communication);
`detection-engineering-standards` (**a boundary decided and declared**: *which
runtime signal matters and what should fire* belongs to this skill —unexpected shell execution,
writes to binaries, capability change, socket mount—; *the rule's lifecycle*
—backlog, ATT&CK coverage, thresholds, tuning, false positive management, test framework and
destination in the SIEM— is theirs. The Falco rule **is born here and is governed there**);
`observability-standards` (collection, retention and correlation of the telemetry);
`vulnerability-management-standards` (triage and SLA for the runtime CVEs cited here);
`cicd-standards` (the pipeline that builds, signs and publishes); `iac-standards` (node
provisioning); `appsec-standards` (the flaw in the application code that gives the initial RCE);
`cryptography-pki-standards` (custody of signing keys); `secrets-management-standards`
(custody and rotation of the secrets the container consumes);
`bcdr-standards` (platform continuity and recovery);
`offensive-security-standards` and `ctf-lab-standards` (offensive verification of the isolation and
sample detonation, **with scope and authorisation in writing**; this skill is defensive);
`podman-systemd-containers-standards` (Podman and Quadlet as **a way of
running services** under systemd; **here their security**); `linux-administration-standards` and
`ha-clustering-standards`; `azure-standards`/`aws-standards`/
`gcp-standards` (the managed node's runtime and its node image advisories);
`grc-compliance-standards` (the required control and its evidence); `webassembly-standards`
(the sandbox of a Wasm module and its imports are theirs; **the isolation of the node
that runs the Wasm host is still ours** — a Wasm host is just another process, with its
`seccomp`, its capabilities and its escape surface).

Cross note: `windows-server-ad-standards` shares with this skill the pattern of *a platform whose
compromise is total* — a compromised node is compromised for all its containers just as a DC is for
the whole domain. The layered containment criterion is analogous; the technical domain is not.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8). This domain moves
> by escape CVE: a minimum version here expires overnight.

| Decision | By default | Reason / justifiable alternative |
|---|---|---|
| OCI runtime | **`crun`** on cgroup v2 hosts; `runc` where the platform imposes it | A far smaller codebase (C rather than Go), lower consumption and no compatibility cost. Verified Aug 2026: it is the **default in Podman on RHEL/Fedora and in OpenShift**; the change is transparent to the workload |
| Minimum runc version | **1.2.8 / 1.3.3 / 1.4.0-rc.3 or later** | It fixes the Nov 2025 escape triad (**CVE-2025-31133, CVE-2025-52565, CVE-2025-52881**): `maskedPaths` bypass, redirection of the `/dev/console` mount and bypass of LSM checks via `/proc/self/attr/*` towards `core_pattern`/`sysrq-trigger`. **containerd 1.6.39+ / 1.7.28-2+** incorporates the fix. A CVSS 4.0 "medium" **misleads**: it reflects runc's threat model, not Kubernetes' |
| Reinforced isolation | **gVisor (`runsc`)** for untrusted network-facing code; **Kata Containers** when gVisor breaks on kernel compatibility | They are enabled via `RuntimeClass`, not globally. gVisor interposes a userspace kernel (partial compatibility, no modules or exotic syscalls); Kata starts a microVM per Pod (full compatibility, at a start-up and memory cost). Kata **4.0.0** (20 Jul 2026); its Confidential Containers branch (SEV-SNP/TDX) is the next step up |
| When the cost is justified | **Hostile multi-tenant, execution of third-party code, sample detonation, building untrusted code** | Outside those cases, the overhead buys no avoided risk: spend that budget on rootless, seccomp and detection. An explicit and documented decision, never "just in case" |
| Execution model | **Rootless wherever possible** (rootless Podman; `hostUsers: false` in Kubernetes) | An escape in rootful gives **root on the node**; in rootless it gives **the unprivileged user**. Verified Aug 2026: **user namespaces GA in Kubernetes v1.36** (beta enabled by default since 1.33); **it requires kernel ≥6.3 on the node** — check `uname -r`, many managed nodes do not get there |
| Rootless Docker | **Only as a transition**; the destination is rootless Podman or Kubernetes with userns | It is an opt-in retrofit with networking and storage limitations (`fuse-overlayfs` instead of overlay2, ~25-30 % start-up overhead). In rootless Podman it is the design, not a mode |
| Capabilities | **`drop: ALL`** and add the minimum list justified in writing | Every added capability is a potential escape path. `CAP_SYS_ADMIN` is practically equivalent to root on the host |
| Escalation | **`no-new-privileges` / `allowPrivilegeEscalation: false`** always | It neutralises the SUID binary as a stepping stone inside the container. It has no real downside |
| seccomp | **`RuntimeDefault` as the universal floor**; a bespoke profile only for high-risk workloads | Verified Aug 2026: `SeccompDefault` is still a **kubelet feature gate + the `--seccomp-default` flag**, not a cluster default. **If you do not enable it, your Pods run `Unconfined`** unless the manifest says otherwise. On a managed control plane it may be out of your reach: then it is imposed by admission (`kubernetes-standards`) |
| Container MAC | **Active and enforcing** (`container_t` + MCS, or an AppArmor profile) | The policy and its authoring belong to `selinux-standards`. **Here the rule is**: disabling it (`label=disable`, `unconfined`) is a **security event** that must alert |
| Runtime detection | **Falco** as the base (CNCF **graduated since 29 Feb 2024**; **v0.44.1**, Jun 2026) | It is the default on maturity, neutral governance and rule ecosystem. **Tetragon** when you also want in-kernel *prevention* (`bpf_send_signal`) or you already have Cilium; **Tracee** for its forensic focus, accepting its higher cost; **KubeArmor** (CNCF *Sandbox*) when the goal is least-privilege *hardening* via LSM rather than detection, or there is edge/IoT |
| Filesystem | **`readOnlyRootFilesystem: true`** + `emptyDir` for what must be writable | Without this there is no immutable container and no credible drift detection |
| Signature verification | **At admission and, for critical workloads, also on the node at execution time** | Admission validates what is requested; the runtime validates what is actually executed (Podman/CRI-O `policy.json` with `sigstoreSigned`). They are not redundant |
| Scanning in the chain | **Grype + Syft** by default | Aligned with `kubernetes-standards` after the **compromise of `trivy-action`/`setup-trivy` (March 2026)**. If you use Trivy: pin by digest, verify the signature and follow its advisories |

## 3. Isolation model, escape and detection

### 3.1 What a container shares with the host (and why that is everything)

- **The kernel is shared**: syscalls, page tables, drivers, the host's `/proc` and `/sys`. A
  kernel flaw is a flaw in *all* the node's containers at once.
- **Namespaces** (pid, net, mnt, uts, ipc, user, cgroup) give a separate *view*, not separate
  *privilege* — except the **user namespace**, which is the only one that really separates identity.
- **cgroups** limit resources, not access. A cgroup does not contain an attacker; it stops them from
  taking the node down by consumption. **cgroups v2 is the requirement**: v1 has a known escape
  surface (controller delegation and `release_agent`) that v2 does not reproduce, besides being the
  model that modern tooling assumes. **A node on cgroups v1 in 2026 is a finding.**
- What actually confines: **seccomp** (which syscalls exist), **capabilities** (what it can ask
  the kernel for), **MAC** (which objects it can touch) and **user namespace** (with which real
  identity). All four at once or the model is a lie.

### 3.2 Escape paths: risk class, indicator and mitigation

They are listed as **surface to close and to watch**, not as a procedure.

| Risk class | Why it is total | Mitigation (mandatory) | Indicator to detect |
|---|---|---|---|
| **Mounted runtime socket** (`docker.sock`, `containerd.sock`, `crio.sock`) | Whoever talks to the socket **creates containers**: creating a privileged one with the node mounted is root on the host. Mounting it **is** granting root, not "giving access to the API" | **Forbidden** (§7). If an agent needs runtime data, use its API with RBAC and read-only, or a socket-proxy with an endpoint allowlist | A container with the socket in its mount list; creation calls from an identity that is not the orchestrator |
| **`--privileged` / `privileged: true`** | It gives back all the capabilities, disables the default filters and exposes devices: it is renouncing isolation in a single flag | **Forbidden** except by a signed exception, with an expiry, in its own namespace and on a dedicated node | Any privileged Pod not on the exceptions list |
| **`hostPath` to sensitive paths** (`/`, `/etc`, `/var/run`, `/var/lib/kubelet`, `/root`, `/proc`, `/sys`, block devices) | The node's filesystem mounted is persistence, theft of kubelet credentials and modification of host binaries | Forbidden to sensitive paths; what is legitimate is solved with CSI or a dedicated subpath and `readOnly: true` | A new hostPath mount; writes to host paths from a container |
| **`hostPID` / `hostNetwork` / `hostIPC`** | `hostPID` gives visibility of and signalling to node processes (and reading of their `/proc/<pid>/environ`); `hostNetwork` removes network isolation and exposes the node's local services; `hostIPC` shares memory with the host | Forbidden except for a justified infrastructure agent | An application workload with any of the three |
| **Dangerous capabilities**: `CAP_SYS_ADMIN`, `CAP_SYS_MODULE`, `CAP_SYS_PTRACE`, `CAP_DAC_READ_SEARCH`, `CAP_BPF`, `CAP_NET_ADMIN`, `CAP_SYS_RAWIO` | `SYS_ADMIN` is root for practical purposes; `SYS_MODULE` loads code into the kernel; `DAC_READ_SEARCH` reads any file by handle; `BPF` allows instrumenting the entire kernel | `drop: ALL` + a justified allowlist. `SYS_MODULE` and `SYS_RAWIO`: **never** | A change to the capability set of an already started process; kernel module loading |
| **Exposed or unmasked `/proc` and `/sys`** (`procMount: Unmasked`, mounting the host's `/proc`) | The runtime's `maskedPaths`/`readonlyPaths` exist precisely because `core_pattern`, `sysrq-trigger`, `uevent_helper` and `kcore` are direct paths to the node | Never `Unmasked`; never mount the host's `/proc` | Writes to `/proc` and `/sys` files that are normally masked |
| **Runtime escape CVE** (class, not recipe) | Verified precedent: the runc triad of **Nov 2025** (`CVE-2025-31133`, `-52565`, `-52881`), all of it through mount manipulation at container creation, reachable **from a hostile image or Dockerfile** | Pin a patched minimum version (§2), rebuild the node image, do not run images from an unverified source. Upstream mitigation if you cannot patch immediately: **user namespaces without mapping the host's root** | Node provider advisories (EKS/AKS/GKE) and the node image version in the inventory |
| **cgroups v1** | A known escape surface with no reason to exist today | Migrate the node to cgroups v2 (unified) | A node reporting cgroup v1 in the inventory |
| **Kernel compromised underneath the MAC** | A kernel flaw nullifies SELinux/AppArmor and the whole isolation (`selinux-standards` documents verified 2026 cases) | Kernel patching with priority; reinforced isolation for what is untrusted | The node's kernel version against the current advisory |

### 3.3 seccomp with judgement

- **`RuntimeDefault` is the floor, not the goal.** It blocks the group of syscalls that no legitimate
  workload uses (`kexec_load`, `init_module`, `bpf` without the capability, etc.) with a very low
  breakage rate. **Verify it is actually enabled**: the Kubernetes default without `--seccomp-default`
  is `Unconfined`, and that is the domain's most frequent silent failure.
- **The default profile differs between runtimes** (containerd vs CRI-O), between versions and between
  architectures. A profile tested on x86_64 is not tested on arm64.
- **A bespoke profile**: only for high-value workloads or ones exposed to untrusted input. It is
  generated from **real observation** (recording the workload's syscalls while it exercises its full
  path: start-up, traffic, log rotation, shutdown), not from a theoretical list.
- **A denylist, not an allowlist, unless you can maintain it**: a strict allowlist breaks with
  every update of the runtime, libc or the language itself. If you adopt it, take on the maintenance
  as part of the image's lifecycle.
- **`SCMP_ACT_LOG` before `SCMP_ACT_ERRNO`**: the new profile is deployed first in logging mode over
  real traffic, what it would have blocked is reviewed, and only then is it enforced.
  Skipping this phase is scheduling an outage.
- The profile is **versioned code** alongside the workload, with its test (§4). A profile that only
  exists on one node is drift.

### 3.4 Runtime detection

- **eBPF is the technology, not the control.** It gives visibility of syscalls and kernel events at low
  cost and with no modules. But **loading eBPF programs is a near-root capability**: `CAP_BPF` (plus
  `CAP_PERFMON`/`CAP_NET_ADMIN` depending on the program type) allows instrumenting the entire kernel.
  Hard rules:
  - `kernel.unprivileged_bpf_disabled = 1` on all nodes, plus JIT hardening
    (`net.core.bpf_jit_harden`), verified by the node baseline (`linux-hardening-standards`).
  - **An explicit inventory of who holds `CAP_BPF`/`CAP_SYS_ADMIN`**: it is almost always an
    observability or security DaemonSet. Each one is a supply chain target of the highest
    value: a compromised agent **can selectively silence its own alerts and keep looking
    healthy**.
  - **Loading a new eBPF program is itself a signal to detect.** An eBPF rootkit filters the
    event stream your agent reads, which will faithfully report already manipulated data: that is why
    you need a second independent source (the node's auditd, runtime telemetry, control plane).
  - A recent CVE verified as a risk class: **CVE-2026-64036** (OOB in the
    `css_rstat_updated()` path via a BPF kfunc, 7.8) — a repeated pattern of a kfunc/verifier bug
    reachable by whoever can already load programs.
- **Signals that really matter** (this skill decides *what* should fire; the rule's lifecycle
  belongs to `detection-engineering-standards`):
  - **Execution of a shell or interpreter inside a container** that does not have it as its entrypoint —
    the domain's highest value/noise ratio signal.
  - **Writes to the container's binaries or system paths** (`/bin`, `/usr`, `/lib`) and
    any write at all if the rootfs is read-only (impossible by design ⇒ a finding).
  - **A change to the capability set or to `no_new_privs`** of an already running process; unexpected
    use of `setuid`/`setgid`.
  - **Access to masked `/proc` and `/sys`**, to the runtime's `/var/run/*.sock`, or to the node's
    filesystem from a container.
  - **An outbound connection to an unforeseen destination** (C2, exfiltration, mining) and anomalous
    DNS resolution.
  - **Execution of a binary that did not come in the image** (drift, §3.5), downloading and executing
    in memory, `curl|sh`.
  - **Reading credentials**: the ServiceAccount token, `/var/lib/kubelet`, the provider's IMDS.
  - **Disabling controls**: MAC moved to permissive, an AppArmor `unconfined` profile, seccomp
    removed, the detection agent stopped.
- **Before writing your own rules, exhaust the maintained ruleset.** Falco ships community-reviewed
  rules; the real work is per-environment *tuning*, not creativity. Every rule of your own
  is born with its firing test (§4).
- **Detection without response is decoration.** Every high-confidence signal has a destination
  (`observability-standards`), an owner and an action — isolate the Pod, capture (§3.6), escalate.
  Without that, the agent only burns CPU.

### 3.5 Immutable container and drift

- The contract is: **the image is the container**. `readOnlyRootFilesystem: true`, writes only to
  declared volumes, zero package installation at runtime, zero operator `exec` in production
  outside break-glass.
- **A container that is modified at runtime is a finding**, not an operational anomaly: either it is a
  compromise, or it is a deployment practice that must be corrected. Both are investigated.
- The comparison *declared image ↔ running process* (an executed binary that is not in the
  layers, a new file in system paths) is a high-value, low-noise detection.
- `kubectl exec`/`podman exec` in production: logged, attributed to a person and alerted. It is at
  once a legitimate emergency tool and the most convenient technique for an attacker with
  control plane credentials.

### 3.6 Container and node forensics: the evidence evaporates by design

- **The problem**: the orchestrator **reschedules or restarts the Pod**, and with it go memory,
  processes, temporary files and the writable filesystem itself. In an incident, the platform's
  default behaviour **destroys the evidence** while it "recovers".
- **Golden rule**: on suspicion, **capture before containing**, and contain without deleting. Isolating
  the Pod's network and marking the node (`cordon`) preserves more than killing the Pod. The order of
  volatility and the chain of custody belong to `incident-response-forensics-standards`; **what
  follows is what artifact exists in this domain and how long it lasts**.
- **Forensic checkpoint (CRIU)**: the kubelet's checkpoint API creates a stateful copy
  (memory, descriptors, sockets) **without the container noticing**, to analyse it in an isolated
  environment. Verified Aug 2026: **alpha in v1.25, beta and enabled by default since v1.30**;
  it is invoked with a `POST` to the kubelet (`/checkpoint/<ns>/<pod>/<container>`, access restricted to
  cluster administrators) and inspected with **`checkpointctl`**. The **restore is deliberately not in
  the kubelet**: it happens outside Kubernetes, in the container engine. **A checkpoint
  contains secrets and personal data in memory: treat it with the same control as a RAM
  image.**
- **Artifacts that do survive and must be collected**: runtime (containerd/CRI-O) and
  kubelet logs on the node, the host's journal and auditd, control plane and API server events,
  detection agent (eBPF) records, image layers and the real digest executed, mounts and
  persistent volumes, and a disk/memory image of the **node** if the compromise is a node compromise.
- **If the compromise is of the node, the whole node is evidence and it is no longer trusted**: it is
  isolated, preserved and **rebuilt from a trusted source**; it is not "cleaned". Every credential that
  passed through it (ServiceAccount tokens, IMDS credentials, mounted secrets) is considered
  compromised and rotated.
- **Rehearse it.** A capture procedure nobody has ever executed does not work on the day it is
  needed, because by then the Pod has been rescheduled three times.

### 3.7 Supply chain at execution time

- Admission validates **what is requested**; the node runs **what is finally downloaded**.
  Signature verification also in the engine (`policy.json` with `sigstoreSigned` in Podman/CRI-O)
  for critical workloads, and **pin by digest** everywhere: a tag is mutable by definition.
- **Current precedent**: the compromise of `trivy-action`/`setup-trivy` in **March 2026** and the
  2026 tag poisoning campaign (documented in `offensive-security-standards`)
  demonstrate that **the security tool is a priority target** — it runs in CI and on the
  nodes, with high privileges, by design. Every runtime agent is pinned by digest, its signature is
  verified and its advisory channel is followed as if it were part of the kernel.
- A private registry with pull-through; never a direct pull from public registries in production.

### 3.8 Node hardening: the boundary

The node belongs to `linux-hardening-standards`, and its baseline (CIS/STIG, `sysctl`, auditd, mounts,
MAC enforcing) is a prerequisite, not a complement. **On this side there remain only** the invariants
that exist because of the fact of running containers:

- cgroups **v2**, kernel ≥6.3 if user namespaces are used, MAC enforcing and active for containers.
- `unprivileged_bpf_disabled=1` + JIT hardening; an inventory of `CAP_BPF` holders.
- The runtime socket with minimum permissions and **never** exposed over the network or mounted in
  containers.
- Nodes segmented by trust: hostile or multi-tenant workloads on **their own node pool**, with
  their reinforced `RuntimeClass`. Mixing hostile tenants with internal workloads on the same node
  nullifies any policy you write on top.
- A node image that is **immutable and rebuildable**, updated by replacement, not by live patching.

### 3.9 Applicable benchmarks

- **CIS Kubernetes Benchmark v1.11.0**, audited with `kube-bench` (`cis-1.11` profile). Verified
  Aug 2026: that profile **covers Kubernetes 1.29–1.32**; for newer clusters it is still the
  practical reference, but **the coverage is not official** — state that when reporting. **Never quote
  "the Kubernetes CIS" generically: CIS goes by product version.**
- **CIS Docker Benchmark**, audited with `docker-bench` (which picks the set according to the daemon
  version). **Declared gap (§8)**: the current version number was not confirmed in Aug 2026.
- **NSA/CISA Kubernetes Hardening Guidance**: verified Aug 2026, **the current version is still
  1.2, of 29 Aug 2022**, with no later revision located. It is a guide of *criteria* (it explains the
  why and the attacker's view) and it **complements** CIS, which is about *configuration*. Use it as a
  design argument, not as an automatable checklist, and **bear its age in mind**: it does not cover
  user namespaces GA, cgroups v2 or the current generation of eBPF detection.
- The benchmark **measures**, it does not protect. A high score with a mounted `docker.sock` is still a
  compromise one step away.

## 4. Quality gates (they break the build or the deployment)

1. **A seccomp profile tested, not assumed.** Functional gate: the workload exercises its full path
   (start-up, real traffic, log rotation, shutdown, restart) with the profile active and **without a
   single unexpected denied syscall**. That the container starts proves nothing — the missing syscalls
   show up in the rare case, in production, at 3 a.m. A mandatory prior phase in logging mode (§3.3).
2. **Runtime policy verified in CI and on the node.** The pipeline fails on `--privileged`,
   a mounted runtime socket, a `hostPath` to a sensitive path, `hostPID`/`hostNetwork`/`hostIPC`,
   a vetoed capability, the absence of `seccompProfile` or `readOnlyRootFilesystem: false` without a
   signed exception. The same policy runs at admission (`kubernetes-standards`) and **as a verification
   of the node's real state**, because what was admitted is not always what runs.
3. **A test that the detection fires — adversarial validation.** A gate of its own and non-negotiable:
   in a test environment, benign actions equivalent to the watched techniques are executed (opening a
   shell in a container that does not have one, writing to `/usr/bin`, reading a masked `/proc`
   file, mounting a socket, initiating an unexpected outbound connection) and **it is verified that the
   alert reaches its destination with the correct context**. A rule that has never been seen to fire is
   not deployed, it is written. It is re-run after every update of the agent, the kernel or the runtime.
4. **Runtime and kernel versions verified against the current advisory** on every node in the
   inventory, as a deployment gate. A node with runc below the minimum of §2 does not accept
   workloads.
5. **A forensic capture test rehearsed**: a checkpoint of a test Pod, inspection with
   `checkpointctl`, and collection of the §3.6 artifacts with their time measured. It is rehearsed at
   least once every six months and after every runtime change.
6. **An inventory of exceptions with an owner and an expiry**: every privileged Pod, every added
   capability, every `hostPath`, every container with MAC disabled. Without an owner and without a
   date, the exception is withdrawn.
7. **A benchmark run and trended** (`kube-bench`, `docker-bench`): the value is in the
   **time series and in the handling of the exceptions**, not in the number.

## 5. Security: what this protects and what it does not

- **What it gives you**: it turns "RCE in the application" into "RCE inside an unprivileged process,
  with no dangerous syscalls, with no access to the node and **with someone watching**". It is
  containment plus detection; neither of the two alone is enough.
- **What it does not give you**: it does not fix the application's vulnerability (`appsec-standards`)
  or a kernel flaw. **Against a kernel 0-day, the only real isolation is the one that does not share a
  kernel** (Kata/microVM) or does not share a node.
- **Hostile multi-tenant**: if you run third-party code, namespace isolation **is not
  sufficient by design**. The correct posture is reinforced isolation + a dedicated node + detection,
  and treating the escape as a scenario, not as a hypothesis.
- **The security agent is attack surface of the highest value**: privileged, on all
  nodes, with kernel access. It is pinned by digest, signed, verified and its own
  health is watched — a downed or silenced agent is a high-severity alert, not an
  observability incident.
- **Secrets at runtime**: environment variables visible in `/proc/<pid>/environ` (and therefore to
  anyone with `hostPID` or `CAP_SYS_PTRACE`), ServiceAccount tokens mounted by default,
  IMDS credentials reachable from the Pod. Prefer a file over an environment variable,
  `automountServiceAccountToken: false` and blocking IMDS access from workloads. Custody and
  rotation: `secrets-management-standards`.
- **Disabling a control "to make it work" is a risk decision**, and it is taken as such: with
  an owner, a ticket, an expiry and compensation. Never on the fly and never as a silent default.

## 6. Performance and operability

- **Realistic cost**: seccomp `RuntimeDefault` and MAC are practically free. gVisor pays in
  syscall-intensive work and I/O; Kata pays in start-up and memory per Pod. Rootless pays ~25-30 % of
  start-up and `fuse-overlayfs`. None of those costs justifies running as root: measure them on your
  workload before dismissing them on rumour.
- **Detection has a cost and noise**: size the agent's CPU and event volume, and treat it
  as a platform workload with its own limits. An unbounded agent that saturates the node is an
  availability incident caused by security. Verified Aug 2026: **Tracee consumes
  notably more than Falco or Tetragon** in high-volume environments (2-4× versus Tetragon according to
  reports) and its default configuration generates an overwhelming event volume — **it is deployed
  with filtering from day one, not afterwards**.
- **A written and tested runbook** for: a suspect Pod (isolate, capture, escalate), a suspect node
  (cordon, preserve, rebuild), a downed agent, and a rollback of a seccomp profile that breaks
  production. Without a runbook, the 3 a.m. incident ends in `--privileged`.
- **Rollback**: every runtime hardening step (a new profile, a reinforced `RuntimeClass`, userns) is
  deployed in rings with its reversal tested.
- **Kernel and runtime changes break profiles and agents**: every node update
  re-runs gates 1, 3 and 4 of §4. It is the number one cause of detection that stops working in
  silence.

## 7. Sustainability and prohibitions

**Cadence**
- **Runtime advisories (runc, crun, containerd, CRI-O, gVisor, Kata) actively tracked**: it is
  the channel through which the escape arrives. Review at least monthly and immediate reaction to
  anything critical.
- Node kernel: top patching priority when the finding allows escape or MAC bypass.
- Falco/Tetragon/Tracee/KubeArmor: version and ruleset reviewed quarterly; the ruleset ages
  faster than the binary.
- Quarterly review of the exceptions inventory (§4.6) and of the inventory of holders of
  `CAP_BPF`/`CAP_SYS_ADMIN`.
- Scheduled rebuilding of the node image even if nothing changes.

**FORBIDDEN** (an automatic gate wherever possible)
- ❌ **Mounting the runtime socket** (`docker.sock`, `containerd.sock`, `crio.sock`) in a
  container. It is granting root on the node, under another name.
- ❌ **`--privileged` / `privileged: true`** without a signed, bounded, expiring exception and on a
  dedicated node.
- ❌ **`hostPath` to sensitive paths** on the node (`/`, `/etc`, `/proc`, `/sys`, `/var/run`,
  `/var/lib/kubelet`, block devices), and any writable `hostPath` without justification.
- ❌ `hostPID`, `hostNetwork` or `hostIPC` in application workloads.
- ❌ Running as **root** (UID 0) without written justification; and root **with** `hostPath` or added
  capabilities, never.
- ❌ `CAP_SYS_MODULE`, `CAP_SYS_RAWIO`; `CAP_SYS_ADMIN`, `CAP_BPF`, `CAP_DAC_READ_SEARCH` and
  `CAP_SYS_PTRACE` outside approved infrastructure agents.
- ❌ **Disabling seccomp or the MAC "to make it work"** (`seccompProfile: Unconfined`,
  `--security-opt seccomp=unconfined`, `label=disable`, AppArmor `unconfined`). The correct path
  is a bespoke profile (seccomp, here) or a bounded policy (MAC, `selinux-standards`).
- ❌ `procMount: Unmasked` or mounting the host's `/proc`/`/sys`.
- ❌ **A container without runtime detection in a multi-tenant environment** or one that runs untrusted
  code. Without detection there is no evidence that the isolation holds.
- ❌ Running untrusted code with a shared runtime (`runc`/`crun`) without a dedicated node.
- ❌ Nodes on **cgroups v1**, or with a runtime below the patched minimum version of §2.
- ❌ **Modifying the container at runtime**: installing packages, hot patching, operator `exec` as
  routine practice, a writable rootfs with no reason.
- ❌ An image by mutable tag or without signature verification on the path to production.
- ❌ **Killing or restarting a suspect Pod before capturing evidence**; deleting the compromised
  node "to recover" without preserving it.
- ❌ Re-enabling `unprivileged_bpf_disabled=0` or handing out `CAP_BPF` without an inventory.
- ❌ A detection agent deployed without a firing test (§4.3), or with alerts without an owner or a
  destination.
- ❌ Pinning runtime versions, feature gate states or benchmark versions **from memory**, without
  the verification of §8.

### Quick review checklist (a workload entering production)

- [ ] Runtime on a patched version; node on cgroups v2; kernel up to date and ≥6.3 if there is userns.
- [ ] Rootless or `hostUsers: false` where the node allows it; if not, a written reason.
- [ ] `drop: ALL` + a justified allowlist; `allowPrivilegeEscalation: false`; not root or a signed exception.
- [ ] An explicit `seccompProfile` and **verified active on the node**; a bespoke profile tested if applicable.
- [ ] MAC active and enforcing for the container (policy: `selinux-standards`).
- [ ] No runtime socket, no sensitive `hostPath`, no `hostPID`/`hostNetwork`/`hostIPC`, no `privileged`.
- [ ] `readOnlyRootFilesystem: true` + declared volumes; drift detection active.
- [ ] Image by digest and signature verified; runtime agent pinned by digest and signed.
- [ ] Runtime detection deployed, with a **passed firing test** and alerts with an owner.
- [ ] Reinforced isolation (`RuntimeClass`) if the workload is untrusted or hostile multi-tenant.
- [ ] A forensic capture procedure rehearsed and accessible in the runbook.

## 8. Mandatory web verification

Before pinning any version, feature state or benchmark number, **look it up — do not
remember it**:

1. **Runtime escape CVEs**: it is the datum that expires fastest in the whole document. Verified
   Aug 2026: the **runc triad of Nov 2025** (`CVE-2025-31133`, `CVE-2025-52565`, `CVE-2025-52881`)
   is still the most recent significant set; patched in **runc 1.2.8 / 1.3.3 /
   1.4.0-rc.3+** and **containerd 1.6.39+ / 1.7.28-2+**. **Declared gaps**: the
   **exact stable version of runc, crun, containerd and CRI-O** was not verified in Aug 2026, nor could
   the isolated report of *active exploitation in Jun 2026* be confirmed (one source asserts it, the
   rest do not) — treat it as unconfirmed and consult the upstream advisory.
2. **The state of user namespaces in Kubernetes** (verified Aug 2026: **GA in v1.36**, Apr 2026;
   beta enabled by default since 1.33; **requires kernel ≥6.3**, which many managed nodes still
   do not have). Check your cluster version and the node's `uname -r`: this changes per release.
3. **`SeccompDefault`**: verified Aug 2026 that it **is still a kubelet feature gate + the
   `--seccomp-default` flag**, with no cluster default. **Declared gap**: it was not confirmed whether it
   has graduated to GA or whether there is a date to make it the default; consult **KEP-2413** and your
   version's seccomp reference.
4. **Forensic checkpoint**: verified Aug 2026 **beta and enabled by default since v1.30**. **Declared
   gap**: **its state in v1.36 could not be confirmed** (still beta, already GA?). Read it in your
   version's release notes before basing an incident procedure on it.
5. **The state of the detection tools**: verified Aug 2026 — **Falco graduated in CNCF
   (29 Feb 2024)**, **v0.44.1** (Jun 2026), with the legacy eBPF probe, gVisor and gRPC documentation
   withdrawn in May 2026; **Tetragon** active as a Cilium subproject in CNCF; **Tracee** active
   (Aqua) with a notably higher cost; **KubeArmor** in **CNCF Sandbox**. **Declared gaps**:
   **the current versions of Tetragon, Tracee and KubeArmor were not verified**, nor were hard
   maintenance health signals (commit cadence, number of maintainers, CNCF level changes in
   2026). Check it in their repos and in the CNCF landscape before betting a platform on it.
6. **Reinforced isolation versions**: verified Aug 2026 **Kata Containers 4.0.0**
   (20 Jul 2026), with a guest kernel bump for **CVE-2026-31431**. **Declared gap**: **the
   current version of gVisor was not verified** (it publishes very frequent releases) nor that of `crun`.
7. **Benchmarks**: verified Aug 2026 — **CIS Kubernetes Benchmark v1.11.0** (`kube-bench` profile
   `cis-1.11`, official coverage **K8s 1.29-1.32**) and **NSA/CISA Kubernetes Hardening Guidance
   v1.2 of 29 Aug 2022** as the current version, with no later revision found. **Declared
   gaps**: **the current version of the CIS Docker Benchmark could not be confirmed** (look it up at
   `cisecurity.org/benchmark/docker`, which only lists the supported ones), and **it was not checked
   whether a CIS Kubernetes Benchmark later than v1.11.0 already exists**.
8. **eBPF hardening and its CVEs**: verified Aug 2026 **CVE-2026-64036** (OOB via the
   `css_rstat_updated()` kfunc, 7.8 CVSS v3.1 according to kernel.org). Check your distro's tracker for
   the patch state and look for later verifier/kfunc CVEs before considering a kernel version safe.
9. **Supply chain compromises in security tools**: a verified precedent from the
   catalogue — **`trivy-action`/`setup-trivy`, March 2026**. Before introducing *any* new agent
   or scanner, look for recent incidents of the project: in this domain the tool runs
   privileged on every node.
10. **Managed node provider advisories** (EKS/AKS/GKE) for the node image version
    you are running: the runtime patch arrives through there, not through your pipeline.

If the web contradicts this document, **the web wins** — flag the discrepancy.
