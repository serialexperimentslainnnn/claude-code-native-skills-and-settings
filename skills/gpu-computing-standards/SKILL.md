---
name: gpu-computing-standards
description: Use when a GPU must be provisioned, shared, monitored or paid for — pinning the NVIDIA driver and CUDA toolkit to a compatibility matrix, nvidia-open versus proprietary kernel modules, DKMS rebuilds after a kernel update, Secure Boot module signing with MOK, blacklisting nouveau, nvidia-container-toolkit and nvidia-ctk with CDI, the Kubernetes device plugin, GPU Operator, DRA driver and nvidia.com/gpu requests, MIG profiles, CUDA MPS and time-slicing, nvidia-smi, nvidia-persistenced, DCGM and dcgm-exporter metrics, XID errors, ECC and thermal or power throttling, GPU TDP, rack density and liquid cooling, Slurm gres scheduling, AMD ROCm and HIP, or GPU utilization as a FinOps metric.
---

# GPU computing standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when the GPU is **an infrastructure resource that has to be installed, shared, measured,
powered, cooled and paid for** — whether it serves inference, training, scientific computing,
simulation or transcoding:

- **The stack and its coupled versions**: driver ↔ CUDA runtime ↔ framework.
- **Installation on Linux**: open modules (`nvidia-open`) vs. proprietary, DKMS, Secure Boot and
  module signing, `nouveau`, `nvidia-persistenced`.
- **Containers with GPU**: NVIDIA Container Toolkit, `nvidia-ctk`, CDI; on Kubernetes,
  *device plugin*, GPU Operator and the DRA driver.
- **Sharing the GPU**: MIG, MPS, *time-slicing*, and what isolation each one gives.
- **Monitoring**: `nvidia-smi`, DCGM, `dcgm-exporter`, XID, ECC, *throttling*.
- **Physical and sizing**: TDP, power, cooling, rack density.
- **Cost**: buy vs. rent, **utilisation as a FinOps metric**, job queues.
- **Alternatives to CUDA**: AMD ROCm/HIP, and their real maturity.
- **Reliability**: XID, GPU fallen off the bus, ECC, RMA.

**Not applicable**: see `local-inference-standards` (**serving models**: engine choice,
quantisation, KV cache sizing, OpenAI endpoint and its security — **if the server has no GPU
(CPU, Apple Silicon), it is still theirs and not this skill's**; here rules when the problem is
*the GPU*, there when the problem is *the model*), `libvirt-kvm-standards` and
`proxmox-ve-standards` (**GPU passthrough to a VM: THEIRS, not here** — VFIO, `vfio-pci`,
IOMMU groups, `intel_iommu=on`/`amd_iommu=on`, vBIOS dumping, card reset and the loss of live
migration are covered in their §3.8; this skill goes up to the hypervisor boundary and **does not
cross it**: what does belong here is the driver *inside* the guest, non-virtualised sharing and
everything in §5-§6), `kubernetes-standards` (manifests, Helm, GitOps, admission policies — here
only the criterion of **which** GPU resource is requested and how),
`container-runtime-security-standards` (seccomp, container escape, `--privileged` — here only
NVIDIA's toolkit-specific surface, §5.2), `podman-systemd-containers-standards`
(`--device nvidia.com/gpu=all` in a Quadlet unit), `onprem-standards` (**platform umbrella**:
rack, redundant power, UPS, OOB management plane, hardware life cycle — this skill is a layer
inside their §1.2 and respects their §1.3 invariants; **the GPU does not exempt you from
telemetry, tested backup or fencing**), `homelab-standards` (**GPU at home**: there budget, noise,
consumption and proportionality rule — a second-hand 3090 in a lab is not sized with data centre
criteria), `linux-administration-standards` (systemd, kernel, packages), `rhel-fedora-standards`
(`dnf module`, `akmods`, `rpm-ostree` with a driver), `linux-hardening-standards` (CIS baseline,
`modprobe.d`, sysctl), `selinux-standards` (device node contexts and policies),
`observability-standards` (Prometheus, PromQL, alerts — here only **which** GPU metric matters and
why), `sre-practice-standards` (SLOs, capacity as a practice),
`iac-standards` and `cicd-standards` (automating installation and version pinning),
`vulnerability-management-standards` (triage and SLA for the CVEs in §5),
`bcdr-standards` and `backup-recovery-standards` (continuity of a GPU cluster),
`networking-standards` (the cluster's data network),
`high-speed-interconnect-standards` (**the compute network is theirs, and it is not designed with
the data network's criteria**: InfiniBand, RoCE v2, iWARP, `opensm` and P_Key partitions, UCX,
NCCL/RCCL and its network backend, GPUDirect RDMA, NVMe over Fabrics, and the criterion for when
NVMe/TCP is enough. **Here the accelerator and its consumption of that network**; there the
network), `firewall-policy-standards`,
`identity-access-management-standards`, `grc-compliance-standards`,
`datacenter-facilities-standards` (**the room**: density per rack, electrical distribution and
liquid cooling — CDU, loop, aisle — **are theirs**; here the TDP and the thermal requirement of
the accelerator handed to them as a datum),
`python-standards`, `julia-standards` and `r-standards` (code that uses the GPU),
`fortran-standards` (**reciprocal, already declared from their §1**: the `!$acc`/`!$omp target`
written in the `.f90` and its correctness are theirs; the kernel, the occupancy and the GPU
programming model, here), `cpp-standards` and `c-standards` (**CUDA/HIP kernels are C++ and that
closeness is confusing**: the GPU programming model — thread hierarchy, shared memory, occupancy,
*streams*, coalescing — belongs here; the **host C++** — standard, RAII, dependency management,
`clang-tidy`, tests — is theirs), `green-it-standards` (rack density, TDP, liquid cooling and
consumption as a physical limit belong here; **their footprint accounting — energy and embodied —
and the criteria for reporting it, theirs**), `webgl-webgpu-standards` (**they are two different
GPUs**: here the **server's**, which is provisioned, shared, monitored and paid for — driver,
CUDA/ROCm, MIG, DCGM, rack density —; there the **client's**, seen through the browser, with a
permission and context-loss model that does not exist on the server), `assembly-standards` (PTX
and SASS are assembly; the criterion for **when you drop to that level, how it is justified with a
measurement and how it is maintained** — including its expiry when the microarchitecture changes —
is theirs), `llm-app-engineering-standards`, `rag-standards`,
`ai-agents-standards`, `mcp-standards` (AI application layer), and `claude-api`
(**canonical reference for Anthropic's API**: the alternative to buying a GPU is not buying it —
no Claude model datum, price or limit is asserted from memory).

Also: `mlops-standards` (training, experiments and model life cycle — **the hardware is here, the
pipeline is there**), `llm-evaluation-standards`, `mlsecops-standards` (model artifact supply
chain), `ai-governance-standards`.

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

### 2.1 The stack and its coupled versions

**It is the number one source of "it doesn't work".** Four layers that are versioned separately
and break together:

```
kernel driver (nvidia.ko / nvidia-open)
   └── CUDA driver API (libcuda.so — shipped by the DRIVER, not the toolkit)
        └── CUDA runtime / toolkit (libcudart, cuBLAS, cuDNN, NCCL)
             └── framework (PyTorch, JAX, TensorRT, inference engine)
```

What must be clear and **not** confused:

- **The driver is backward compatible**: an application compiled against an old CUDA keeps
  working with a newer driver. **The converse is not true**.
- **Minor version compatibility** (text verified in the release notes of the toolkit in force,
  Aug 2026): **CUDA 13.x requires driver ≥ 580; 12.x, ≥ 525; 11.x, ≥ 450**. That is, within a
  major branch you do not need to raise the driver on every toolkit update.
- **The toolkit in force as of August 2026 is CUDA 13.3 Update 1**; the current production driver
  branch published as *open kernel modules* is **610.43.03** (Jul 2026), with earlier branches
  595 and 580 still active.
- **Since CUDA 13.1 the Windows driver is no longer bundled with the toolkit.** On Linux the
  separation was always conceptually like that: **install the driver through the distribution's
  package manager and the toolkit separately** (or, better, inside the container).
- **PyTorch ships its own CUDA runtime in the wheel** (`torch-2.13.0+cu130`, `+cu132`,
  `+rocm7`, `+xpu` according to the official index as of August 2026). **From the system it only
  needs the driver.** That is why the classic error "I have CUDA 12 installed and PyTorch wants
  13" is almost always a badly chosen wheel, not a toolkit problem.

**Golden rule: on the host, only the driver. Everything else, inside the container.** It is what
turns "update the framework" into an image change instead of an intervention on the host. On the
host you install driver + `nvidia-container-toolkit` and nothing else.

**Everything is pinned**: driver version, CUDA base image **by digest**, framework version, NCCL
version. The exact combination is recorded as a versioned artifact (`iac-standards`). A driver
update is a platform change with a window and a rollback, not a Tuesday `dnf update`.

### 2.2 Installation on Linux (NVIDIA)

| Decision | Default | Reason / alternative |
|---|---|---|
| Module flavour | **Open kernel modules** (`nvidia-open`) | NVIDIA's official doc, verbatim: *"Starting in the 560 driver release series, the open kernel module flavor is the default and suggested installation"*. Requires **Turing or later**. The proprietary one is left for Maxwell/Pascal/Volta (architectures already out of the new branches) and as an emergency exit |
| Package origin | **The distribution's repository or NVIDIA's for that distro**, not the `.run` | The `.run` does not integrate with the package manager: it breaks on every `dnf/apt upgrade` and leaves no auditable trace |
| Module build | **DKMS** (or `akmod` on Fedora/RHEL) | Rebuilds on kernel update. **Without this, the next reboot comes up with no GPU** |
| `nouveau` | **Explicitly blacklisted** in `modprobe.d` + regenerate the initramfs | If `nouveau` grabs the card first, the proprietary driver does not load. It is the most frequent installation failure |
| Secure Boot | **Sign the module and enrol the MOK**, or disable Secure Boot **with a written decision** | With Secure Boot active and an unsigned module, the kernel refuses to load it and the symptom is "there is no GPU" with no obvious error. The signing key is a secret (`secrets-management-standards`) |
| Persistence | **`nvidia-persistenced` active** on servers | Without it, the GPU state is torn down when the last client exits: slow initialisation on every process start (more noticeable with open modules and GSP) |
| ECC | **Enabled** on data centre GPUs | Costs some VRAM and some bandwidth; in exchange, it detects and corrects silent corruption. ❌ Disabling ECC "to gain memory" in production |
| Compute mode | Default, unless required otherwise | `EXCLUSIVE_PROCESS` only if the use case demands it |

**Number one operational risk: the kernel updates and the module does not build.** A new kernel
can break the DKMS build of the installed driver. Mandatory mitigation:

1. **Pinned kernel** on GPU nodes, with a deliberate and tested update, not an automatic one.
2. **Boot gate**: the node does not return to service until `nvidia-smi` responds correctly and a
   CUDA test load passes (§4).
3. **Be able to go back**: the previous kernel present in the boot manager.
4. In automated patching (`linux-hardening-standards`, `unattended-upgrades`/`dnf-automatic`),
   **explicitly exclude kernel and driver** on GPU nodes.

### 2.3 Containers with GPU

| Component | Verified status (Aug 2026) | What for |
|---|---|---|
| **NVIDIA Container Toolkit** (`nvidia-ctk`) | **v1.19.1** (May 2026) stable; **v1.20.0-rc.1** (Jul 2026) in RC | Exposes the GPU to the container on Docker/Podman/containerd. **CDI (Container Device Interface)** is the preferred mechanism today: declarative, and the legacy *hooks* mode is where several of the CVEs in §5.2 have lived |
| **NVIDIA GPU Operator** | **26.3.3** (Jun 2026) | On Kubernetes, it manages driver, toolkit, device plugin, DCGM and `node-feature-discovery` as a whole. **It is the default route in a cluster**: installing each piece by hand diverges |
| **k8s-device-plugin** | **v0.19.3** (Jun 2026) | Advertises `nvidia.com/gpu` as an *extended resource*. Classic mechanism: **whole, no oversubscription** (`nvidia.com/gpu: 1` = one whole GPU) |
| **DRA driver for NVIDIA GPUs** (`kubernetes-sigs/dra-driver-nvidia-gpu`) | Chart **0.4.x** (Jun 2026). **DRA in the Kubernetes core is GA since 1.34**; NVIDIA's GPU driver is declared **technology preview** (the *ComputeDomains* part for multi-node NVLink, supported) | The future of GPU scheduling: declarative feature requests, controlled sharing, dynamic MIG. **It is not yet the production default**: evaluate it, do not bet the platform on it |

**Criterion**: on Kubernetes, **GPU Operator + device plugin** today; DRA as a pilot, with a
planned migration, not an improvised one. Outside Kubernetes, **CDI** with
`nvidia-ctk cdi generate` and `--device nvidia.com/gpu=…`.

### 2.4 Sharing the GPU

GPUs are not oversubscribed the way CPUs are. "Sharing" means three very different things:

| Mechanism | Memory isolation | Fault isolation | Requirements | When |
|---|---|---|---|---|
| **Time-slicing** | ❌ None | ❌ None: they share a fault domain; an OOM affects everyone | Any GPU; a flag in the device plugin | **Development, same-team, non-critical** workloads. Raises density, gives no guarantees |
| **CUDA MPS** | ❌ **There is no hardware isolation**: the limits are applied at the CUDA API layer, not in silicon | ❌ **Worse than time-slicing**: a fatal CUDA error from one client **takes down the MPS server and with it all the other clients** | **Trusted** processes, a single user | Many small processes from the same owner that waste the GPU separately. **Designed for a single-user environment** |
| **MIG** | ✅ **Hardware partitioning** | ✅ Real: you exhaust your partition and the neighbour never notices | GPU with MIG support (Ampere+/data centre); **static profiles**, planned in advance; maximum 7 instances | **The only valid option with distinct tenants**: teams, customers, separate blast radii |

Rules:

- **Real multi-tenancy ⇒ MIG, or a whole GPU.** Time-slicing and MPS **are not security
  boundaries** and must not be presented as such.
- **MPS and MIG do not combine** (verify in the GPU Operator version in force).
- **The static MIG profile wastes**: if the smallest profile is 20 GB and your model takes 12, you
  throw away 8 GB per instance. The partition is planned with workload data, and is reviewed.
- **Sharing does not create capacity.** If the GPU is already saturated, splitting it only splits
  the queue.

### 2.5 AMD ROCm and alternatives — honestly

- **Versions (Aug 2026)**: the official compatibility doc publishes **ROCm 7.14.0**; at the same
  time there are releases of the **7.2.x** line (7.2.4, May 2026). **There is more than one
  release stream (production vs. *technology preview*) and the numbers are not comparable with
  each other**: verify which is the production stream before pinning. PyTorch publishes `+rocm7`
  wheels.
- **Where it works today**: PyTorch + vLLM/SGLang on Instinct (MI300X/MI355X and family) is the
  viable combination. HBM capacity per card is a real structural advantage: large models with less
  tensor parallelism.
- **Where it does not**: **there is no equivalent to TensorRT-LLM or FlashAttention 3**; custom
  PTX kernels have to be ported; `hipify` translates CUDA code but **does not translate calls to
  CUDA libraries** (cuDNN, cuBLAS, TensorRT). Consumer cards are well behind the Instinct ones in
  kernel maturity.
- **The real cost is not performance, it is ecosystem**: when CUDA fails there is a decade of
  published answers; when ROCm fails, there are GitHub *issues*. Your team pays that cost in
  hours, and it has to be budgeted.
- **Criterion**: ROCm is a **legitimate and evaluable** option if (a) your stack is PyTorch + vLLM
  with no custom kernels, (b) you have people willing to debug, and (c) the cost or memory
  advantage is measurable in your workload. **Outside that, CUDA remains the default**, and the
  premium you pay buys ecosystem, not just FLOPs. ❌ Choosing ROCm out of ideology or list price
  without a measured pilot.
- **Intel (`+xpu`)**: PyTorch publishes wheels; treat it as evaluable, not as a default.
  **Maturity not verified in this pass** (§8).

## 3. Structure and conventions

- **GPU nodes are a separate node class**: labelled (`node-feature-discovery`), with *taints* so
  that non-GPU workloads do not sneak onto them, pinned kernel and their own patching window.
  Mixing them with the general fleet guarantees that a routine patching run breaks them.
- **Inventory**: GPU model, VRAM, compute capability (SM), serial number, driver version, VBIOS
  version and ECC status — as code, alongside the rest of the fleet (`onprem-standards`).
- **A single source of versions**: a versioned file with driver, toolkit, framework and container
  toolkit for each environment. Without it, "it works on my node" is unarguable.
- **Rebuildable from scratch**: a GPU node is re-provisioned from code, including driver
  installation and module signing. ❌ Artisanal nodes.
- **No compiling inside the production node**: the image with the framework is built in CI
  (`cicd-standards`) and promoted by digest.

## 4. Quality and gates

**Validation of a GPU node before putting it into service** (and after every kernel or driver
update) — in order of increasing cost:

1. **`nvidia-smi` responds** and lists all the expected GPUs, with the expected driver version.
   If one is missing, the node does not enter.
2. **Module loaded and signed**: the module loads with Secure Boot active; DKMS/akmod reports
   `installed` for the running kernel **and** for the previous one.
3. **Health status**: ECC enabled and **no uncorrectable errors**; no GPU in a degraded mode;
   PCIe link at the expected width and generation (an x16 negotiated at x4 explains mysterious
   performance problems); no recent XID in the journal.
4. **Functional compute test**: a container with the toolkit runs a real CUDA workload and checks
   the result. `nvidia-smi` inside the container is not enough: it tests visibility, not compute.
5. **Stress and thermal test**: sustained load for minutes, watching temperature, power and
   **throttling reasons**. Power and cooling failures only show up under sustained load, never in
   a short test.
6. **Multi-GPU**: GPU-to-GPU bandwidth test (NVLink/PCIe) and an NCCL collective test. A
   misdetected topology turns an expensive cluster into a slow one.
7. **DCGM diagnostics** (`dcgmi diag`) at the appropriate level, as the final step before
   accepting the node or returning it after an incident.

**CI/CD gates** that break the build or the deployment:

- Driver/toolkit/framework versions **declared and pinned by digest**; drift detected against the
  inventory breaks the pipeline.
- The image does not include the host driver (classic error); it does include the runtime and is
  tested against the minimum supported driver version.
- CVE scanning of the CUDA base image and of the container toolkit
  (`vulnerability-management-standards`).
- No manifest requests `nvidia.com/gpu` without a limit or without a *toleration*; no GPU pod runs
  as root or with `--privileged` (`container-runtime-security-standards`).

## 5. Security

### 5.1 Driver surface

- **The GPU driver is a huge kernel module, partly proprietary, with a wide `ioctl` interface
  exposed to unprivileged processes through `/dev/nvidia*`.** It is first-order local escalation
  surface, and the record confirms it.
- Verified in NVD (Aug 2026): **CVE-2026-24187** (CVSS 8.8, *use-after-free* in the **Linux**
  driver, with `S:C` — scope change — and consequences that include code execution),
  **CVE-2026-24199** (4.7, race condition in the kernel module, DoS). The associated bulletin
  (May 2026) patches branches **R595, R580 and R535**, and leaves **R570 as EOL with no fix**: if
  your `nvidia-smi` says 570.x, there is no patch, there is a branch migration.
  **Verify the bulletin in force before acting** (§8).
- **Rule**: NVIDIA's bulletins are subscribed to and triaged like the kernel's
  (`vulnerability-management-standards`). The GPU driver is **not** "a desktop component".
- Hardening: restrictive permissions on `/dev/nvidia*`, confinement of the process that can issue
  `ioctl`s against the driver (`selinux-standards`), and **unload the module on hosts that do not
  use the GPU**.

### 5.2 Container Toolkit — a documented history of escapes

**The NVIDIA Container Toolkit has had real and repeated container escapes.** Verified in NVD:

| CVE | CVSS | What |
|---|---|---|
| **CVE-2024-0132** | **9.0** | TOCTOU in the default configuration: a crafted container image can **access the host filesystem**. NVIDIA's own description notes that it **does not affect cases where CDI is used** |
| **CVE-2025-23359** | 8.3 | TOCTOU, bypass of the previous one; same impact |
| **CVE-2025-23266** | **9.0** | Vulnerability in container initialisation *hooks*: code execution with elevated permissions |
| **CVE-2025-23267** | 8.5 | *Link following* in the `update-ldcache` hook |
| **CVE-2026-24260** | 8.5 | TOCTOU again (Jul 2026), with `AV:N` and `S:C` |
| CVE-2024-0133/0134/0135/0136/0137 | 4.1–7.6 | Improper isolation; **0134 also affects the GPU Operator** |

Derived criterion:

- **Prefer CDI** over the legacy *hooks* mode: it is the declarative mechanism and several of the
  flaws are specific to the hooks.
- **The toolkit is patched fast and pinned by version**: it is the component with the worst record
  in the stack and it is on the critical path of every GPU container.
- **Giving a container a GPU widens its surface**, not just its compute. Containers that run
  untrusted workloads **do not get a GPU** without an additional layer
  (`container-runtime-security-standards`).
- ❌ `--privileged` "to make the GPU work": if it is needed, the toolkit's configuration is wrong.

### 5.3 Tenant isolation on a shared GPU

- **Time-slicing and MPS do not isolate GPU memory.** In MPS the processes share address space and
  the limits are applied at the API layer, not in hardware: a hostile process can read or corrupt
  another's GPU memory. **FORBIDDEN to use them as a boundary between tenants.**
- **MIG is the only hardware-backed partition.** Even so, it is not a hypervisor: for truly
  hostile tenants, a dedicated GPU or passthrough to a VM (`libvirt-kvm-standards`,
  `proxmox-ve-standards`).
- **GPU memory is not guaranteed to clear itself between jobs.** With sensitive data, an explicit
  reset/clean policy between jobs of different tenants, and verify it — do not assume it.
- **Passthrough has its own risk and its own owner**: a passed-through device does DMA towards the
  host, mediated by the IOMMU; with a badly configured IOMMU or with ACS *overrides*, the guest
  can write host memory. **That is governed by `libvirt-kvm-standards` §3.8.**

## 6. Performance, observability and physical operation

### 6.1 Monitoring: what each metric really measures

- **`nvidia-smi`'s `utilization.gpu` (and `DCGM_FI_DEV_GPU_UTIL`) is misleading.** It measures
  **the fraction of time in which at least one kernel was resident**, not how much work is done. A
  trivial kernel on 1 of 132 SMs reads **100%**. In LLM *decode* this is the normal state: 100%
  "utilisation" with the SMs almost empty.
  **FORBIDDEN to use `utilization.gpu` as a capacity, sizing or FinOps metric.**
- **What is actually measured** (DCGM, *profiling* metrics):
  - `DCGM_FI_PROF_SM_ACTIVE` — cycles with an active SM / total cycles.
  - `DCGM_FI_PROF_SM_OCCUPANCY` — fill at the *warp* level.
  - `DCGM_FI_PROF_PIPE_TENSOR_ACTIVE` versus `DCGM_FI_PROF_DRAM_ACTIVE` — **the useful
    diagnosis**: tensor high ⇒ compute bound; DRAM high and tensor low ⇒ memory bound (the normal
    situation in *decode*); both low with `GPU_UTIL` at 100% ⇒ small kernels, launch overhead or
    data *starvation*.
  - **Memory used versus memory reserved** (an inference engine reserves almost all the VRAM by
    design: the reservation metric says nothing about saturation).
  - **Temperature, power, and `clocks_throttle_reasons`** — thermal or power *throttling* is the
    most frequent explanation of "it's slower than yesterday".
  - **ECC**: correctable errors (trend) and **uncorrectable ones (immediate alert)**; retired
    pages / *row remapping*.
  - **Link**: negotiated PCIe generation and width; NVLink errors.
- **Collection caveats**: *profiling* metrics require privileges (the `nv-hostengine` runs as
  superuser), not all of them can be collected at once on all hardware (DCGM multiplexes by
  sampling), and there are known issues with anomalous values on MIG devices. **Do not build a
  critical alert on a metric you have not seen behave on your hardware.**
- **Tools (Aug 2026)**: **DCGM 4.6.0** (Jul 2026) and **dcgm-exporter `4.6.0-4.8.3`**
  (Jul 2026) towards Prometheus. On Kubernetes it is deployed by the GPU Operator.
  `nvidia-smi` is for interactive diagnosis, **not** for continuous monitoring.
- The rest (retention, cardinality, alert design, dashboards as code) belongs to
  `observability-standards`.

### 6.2 Reliability: XID and company

- **XIDs are the driver's error channel.** They appear in the journal as
  `NVRM: Xid (PCI:0000:xx:00): <n>, …`. **They are collected, correlated and alerted on**; they
  are not log noise.
- **XID 79 — "GPU has fallen off the bus"**: the GPU disconnects from the PCIe bus. Typical
  pattern: visible and fine at idle, drops when load is applied. Usual causes in order of
  probability: **insufficient or unstable power, riser/adapter (OCuLink, expansion chassis, eGPU),
  temperature, connector seating, faulty hardware** — and only after that, software.
  Diagnosis: collect the `nvidia-bug-report.sh` **before** unloading the module, review PCIe AER
  in the journal, and **test the card in another slot and in another machine**. If after a reboot
  the GPU does not appear, assume hardware.
- **"GPU Reset Required" XID**: the node must be drained and the GPU or the host restarted. A node
  in that state does not accept jobs: **automate the *cordon*/*drain*** instead of discovering it
  through failing jobs.
- **Uncorrectable ECC ⇒ the node leaves service.** You do not "keep an eye on it". Increasing
  retired pages ⇒ RMA candidate.
- **Every long job must have *checkpointing***: in a GPU fleet, a card failing during a
  days-long training run is not a hypothesis, it is a statistical certainty.
- **Mandatory runbook** per failure family (XID, ECC, throttling, NCCL drop) with the action and
  the RMA criterion (`incident-management-standards`, `onprem-standards`).

### 6.3 Sizing and physical operation — the GPU changes the data centre design

- **The GPU is not sized like a server.** A traditional server rack moves in the 5-15 kW range;
  current GPU platforms are an order of magnitude above that: rack-scale Blackwell-generation
  systems are specified at around **~120-140 kW per rack** (the GB200 NVL72 reference is
  documented up to **132 kW**), and the following generations point higher. **Verify the figure
  for the specific model in its data sheet** (§8).
- **Consequences that are not negotiable**:
  - **Direct-to-chip liquid cooling** stops being optional above ~40-50 kW per rack: the air does
    not reach, and rear-door heat exchangers do not cover that density. That drags in a CDU, a
    facility water loop, flow rate and inlet temperature.
  - **Dedicated three-phase power** sized for full load, with matching PDUs and protections
    (`onprem-standards`).
  - **Weight and structure**: a GPU-scale rack weighs around a tonne. The floor and the access
    matter.
  - **Design with headroom**: rack density has been doubling every 18-24 months. A data centre
    specified exactly to the current generation is born obsolete.
  - **In a homelab** all of this translates into: idle consumption, noise, and whether the house's
    electrical circuit copes. `homelab-standards` rules.
- **Power limit as a lever**: lowering the power ceiling usually costs little performance and
  saves a lot of energy and heat. **It is measured on your workload**, not assumed.

### 6.4 Cost: buying, renting and the metric that matters

- **A GPU's FinOps metric is utilisation, and not `nvidia-smi`'s** (§6.1): it is the *fraction of
  time with useful work* against the amortised time. **A GPU at 15% is burnt money** — and worse,
  it is invisibly burnt money, because the dashboard reads "100% GPU util".
- **Buying** is justified by: sustained high utilisation, a 2-3 year horizon, data that cannot
  leave, and the capacity to operate the hardware. **Renting** (cloud or *bare metal* by the hour)
  is justified by: bursty load, uncertainty about the model or the size, training peaks, and not
  wanting to buy an architecture that goes stale.
- **Total cost of ownership**: purchase + electricity (24×7, and **with PUE**, not just the card's
  TDP) + cooling + space + network + warranty/RMA + **operation**. The operation line is the one
  that gets forgotten and the one that grows most.
- **Job queues** to squeeze the hardware — without them utilisation collapses:
  - **Slurm** (`gres.conf`, `--gres=gpu:N`, partitions, QoS, *preemption*, *fairshare*) for batch
    workloads, HPC and training: it is the standard of the scientific world and it does well what
    Kubernetes does poorly (priority queues and *backfill*).
  - **Kubernetes** when the load is service-shaped (inference) or the rest of the platform is
    already there; for batch, with a queueing scheduler on top because the default scheduler
    **has no queues and no gang scheduling** — the specific choice (Kueue, Volcano) and its
    criteria belong to `kubernetes-standards` §6, which has them verified.
  - **Rule**: do not run both **for the same class of workload**. That a batch scheduler and a
    service scheduler coexist is normal in a real cluster — and the criterion for that split
    belongs to `hpc-standards` §2.2, which rules here —; what is not done is duplicating the route
    of the **same** workload just in case, because then nobody knows where to look when a GPU is
    missing.
- **Chargeback/showback per team** with the correct metric: without it, nobody releases a GPU
  reserved "just in case", and the idle reservation is the biggest cost sink in any GPU fleet.

## 7. Long-term sustainability and prohibitions

- **Cadence**: review NVIDIA's security bulletins and Container Toolkit CVEs **monthly**; review
  the driver branch and its EOL **quarterly** (an EOL branch receives no patch: you have to
  migrate); review the driver/CUDA/framework matrix **before every framework upgrade**.
- **Driver branch policy**: use supported branches (LTS/production) and **plan the exit from a
  branch before its EOL**, not on discovering that there is no patch for a critical CVE.
- **Updating driver and kernel at the same time is asking for a double incident**: they are done
  separately, with the §4 validation in between.
- **Hardware life cycle**: the previous GPU generation is not thrown away, it is demoted to
  development, to less demanding inference or to a lab. But **the electricity consumption of old
  hardware can make it more expensive than replacing it**: it is calculated, not assumed.

**FORBIDDEN**

- ❌ Using `utilization.gpu` / `DCGM_FI_DEV_GPU_UTIL` as a capacity, saturation or cost metric.
- ❌ Presenting time-slicing or MPS as isolation between tenants.
- ❌ Disabling ECC in production to gain VRAM.
- ❌ Installing the driver with the `.run` on a package-managed server.
- ❌ Automatic kernel updates on a GPU node, or patching with no subsequent validation gate
  (`nvidia-smi` + a real CUDA workload).
- ❌ Leaving `nouveau` unblacklisted and expecting the driver to load.
- ❌ Disabling Secure Boot "because the module does not load", with no written decision and
  without evaluating MOK signing.
- ❌ `--privileged` to access the GPU from a container.
- ❌ An unpatched Container Toolkit, or the legacy *hooks* mode when CDI is available.
- ❌ Giving a GPU to a container that runs untrusted workloads.
- ❌ Returning to service a node with recent XIDs or uncorrectable ECC errors without diagnosis.
- ❌ Long jobs without checkpointing in a GPU fleet.
- ❌ Installing the full CUDA toolkit on the host when the framework ships it in the container.
- ❌ Mixing driver versions within the same scheduling pool.
- ❌ Designing the room, power or cooling with CPU rack assumptions.
- ❌ Buying a GPU without a calculation of expected utilisation and without a queue to fill it.
- ❌ Adopting ROCm (or any alternative to CUDA) without a measured pilot on your workload.
- ❌ Covering passthrough/VFIO here: it belongs to `libvirt-kvm-standards` and
  `proxmox-ve-standards`.
- ❌ Asserting from memory a driver, CUDA or ROCm version, a TDP or a rack density figure.

## 8. Mandatory web verification

Before fixing any version, number or name:

1. **Versions**, via `api.github.com/.../releases/latest` or via the `releases.atom` feed
   (**never via the HTML of the releases page: the summariser invents the year**).
   Checked that way in August 2026: `nvidia-container-toolkit` **v1.19.1** (May 2026) with
   **v1.20.0-rc.1** (Jul 2026), **GPU Operator 26.3.3** (Jun 2026), `k8s-device-plugin`
   **v0.19.3** (Jun 2026), **DCGM 4.6.0** (Jul 2026), `dcgm-exporter` **4.6.0-4.8.3**
   (Jul 2026), `open-gpu-kernel-modules` **610.43.03** (Jul 2026), **ROCm 7.14.0** (Jul 2026)
   and **7.2.4** (May 2026).
2. **CUDA**: version in force and the **minor version compatibility table** in the official
   release notes. Verified verbatim (Aug 2026): toolkit **13.3 Update 1**; 13.x ⇒ driver
   **≥ 580**, 12.x ⇒ **≥ 525**, 11.x ⇒ **≥ 450**.
3. **Driver ↔ CUDA ↔ framework matrix**: PyTorch's wheel index
   (`download.pytorch.org/whl/torch/`) says exactly which builds exist. Verified
   (Aug 2026): `torch 2.13.0` with `+cu126`, `+cu129`, `+cu130`, `+cu132`, `+rocm7`, `+xpu`.
4. **Module flavour and supported architectures**: NVIDIA's installation guide and the README of
   the specific branch. **Careful, there is a discrepancy between official sources** (§ gap
   below).
5. **NVIDIA security bulletins** (driver, vGPU, Container Toolkit, TensorRT-LLM) and NVD for the
   detail and the CVSS. Verified in NVD (Aug 2026): CVE-2026-24187 (8.8),
   CVE-2026-24199 (4.7), CVE-2026-24260 (8.5), CVE-2025-23266 (9.0), CVE-2025-23267 (8.5),
   CVE-2025-23359 (8.3), CVE-2024-0132 (9.0).
6. **EOL of the driver branch you use**: the May 2026 bulletin left **R570 with no fix**. Check
   your branch's status **before** you need it.
7. **DRA status** for GPUs in your Kubernetes version and NVIDIA driver (GA in the core since
   1.34; the GPU driver, technology preview as of August 2026).
8. **Exact DCGM field names** in the installed version and in the `dcgm-exporter` doc.
9. **XID codes**: NVIDIA's canonical list (`docs.nvidia.com/deploy/xid-errors`).
10. **TDP, rack density and cooling requirements** of the specific model, in the manufacturer's
    data sheet. Not from a blog.

**Declared gaps (not verified in this pass, do not fill from memory)**

- **Module flavour by architecture: official sources in conflict.** The data centre installation
  guide says the open modules are *"only for Turing and newer architectures"* and that the
  proprietary ones are needed for *"older GPUs from the Maxwell, Pascal, or Volta
  architectures"*; the README of recent branches indicates that the proprietary flavour covers
  Turing–Hopper and that **Blackwell and later are open only**, and that branch 580 was the last
  with Maxwell/Pascal/Volta support. **Consult the README of the exact branch you are going to
  install**; the general guide may be out of date.
- **ROCm: which is the production release stream**. Numbering schemes coexist (7.2.x and 7.1x.x)
  that appear to correspond to different streams (production vs. *technology preview*/TheRock).
  **Not verified which one should be pinned.**
- **ROCm performance figures against CUDA**: the published ranges go from "37-66% of an H100" to
  "90-95% parity", depending on the source, the model and the tuning effort. **None
  independently verified.** Do not cite a number without your own pilot.
- **Maturity of the Intel XPU backend**: not evaluated.
- ~~**Status of Kueue / Volcano**~~ — **gap CLOSED**: verified in `kubernetes-standards`
  §6 (version, API, governance and licence). Re-verify there, not here.
- **MIG detail**: maximum number of instances, profiles and architectures supported today cited
  from secondary sources. **Verify in NVIDIA's MIG doc** before planning a partition.
- **Rack density**: the figures in §6.3 are from reference rack-scale platforms, not from your
  server. **The datum that rules is the data sheet of the model you buy.**
- ~~**InfiniBand / RoCE with no owner**~~ — **gap CLOSED**: it belongs to
  `high-speed-interconnect-standards`, which covers IB, RoCE v2, iWARP, subnet manager, GPUDirect
  RDMA and NVMe-oF. Do not improvise the compute network here: load it.
- **Module signing with MOK and its automation** (kmodsign, per-distro procedure): criterion
  fixed, specific commands **not verified** in this pass.

If the web contradicts this document, **the web wins** — flag the discrepancy.
