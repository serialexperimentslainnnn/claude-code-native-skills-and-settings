---
name: hpc-standards
description: High-performance computing clusters as an operated service — batch scheduling, the software environment and the parallel filesystem. Use when writing or debugging a Slurm job with sbatch, srun, salloc, squeue, scancel, sacct, sacctmgr, sinfo and scontrol, editing slurm.conf, slurmdbd.conf, cgroup.conf or a partition/QoS/fairshare/TRES limit definition, turning on job accounting, sizing a login/compute/management node split, a user who compiled on the login node, migrating from PBS Pro, OpenPBS qsub or IBM Spectrum LSF bsub, deciding whether a batch scheduler or a container orchestrator fits the workload, running an MPI job with Open MPI or MPICH and setting rank pinning and CPU affinity, measuring strong versus weak scaling, managing the software stack with environment modules, Lmod module load and module spider, Spack specs and environments, EasyBuild easyconfigs, or Apptainer .sif images and apptainer exec, operating Lustre with lfs setstripe and lfs quota, IBM Storage Scale/GPFS with mmlsfs, BeeGFS or CephFS under a small-file I/O pattern, setting a scratch purge policy against home and archive tiers, node provisioning with xCAT or Warewulf, benchmarking with HPL, HPCG or the Top500 list, or isolating users and sensitive data on a shared cluster.
---

# HPC standards — the compute cluster as an operated service

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the compute cluster as a multi-user service**: its node architecture, the job
scheduler and its accounting, the software environment users consume,
the parallel filesystem and its data policy, honest performance measurement, and
isolation between users sharing the machine.

**Guiding principle**: **an HPC cluster is not "lots of servers"; it is a scarce shared
resource with a queue in front of it.** Everything this skill decides —partitions, limits, quotas,
purging, accounting— exists to distribute scarcity with explicit criteria. A cluster with no
accounting and no limits is not shared: it is taken by whoever types `sbatch` fastest.

Triggers: `sbatch`, `srun`, `salloc`, `squeue`, `scancel`, `sacct`, `sacctmgr`, `sinfo`,
`scontrol`, `slurm.conf`, `slurmdbd.conf`, `cgroup.conf`, `gres.conf`, partition, QoS,
*fairshare*, TRES, `qsub`/`qstat` (PBS), `bsub` (LSF), "login node", "I compiled on the
login node and it's crawling", `mpirun`/`mpiexec`, *pinning*, affinity, strong/weak scaling,
`module load`, `module spider`, Lmod, `spack install`, `spack env`, `eb` / *easyconfig*,
`apptainer exec`, `.sif`, `lfs setstripe`, `lfs quota`, `mmlsfs`, BeeGFS, CephFS, *scratch*,
purge policy, per-project quota, GPU queue, HPL, HPCG, Top500, xCAT, Warewulf,
"the job is stuck in PENDING", "millions of small files".

**Not applicable**: see `high-speed-interconnect-standards` (**the RDMA network is theirs**: InfiniBand,
RoCE v2, `opensm`, P_Key partitions, UCX, GPUDirect, fat-tree topology and its
oversubscription — here we only **require** that it exists and that MPI uses it, and we measure the effect),
`gpu-computing-standards` (**the GPU itself**: driver, CUDA, MIG/MPS, DCGM, XID, power draw — here
only the GPU **as a schedulable and accounted resource**),
`datacenter-facilities-standards` (**the facility**: power, kW/rack, liquid cooling,
weight and floor loading; the dense cluster lives there before it lives here),
`server-hardware-standards` (the node as hardware, BMC and firmware),
`os-provisioning-standards` (**the mass installation mechanism**: PXE, Kickstart, image —
here xCAT/Warewulf only as an HPC-specific option and the stateless node criteria),
`linux-storage-standards` (local block, LVM, NVMe, I/O schedulers),
`zfs-standards` and `object-storage-standards` (other storage layers; here the
**parallel** one and the archive), `kubernetes-standards` (**the container orchestrator and its
cluster** — see §2.2: it is not a direct substitute for a batch scheduler),
`podman-systemd-containers-standards` (containers on a standalone host),
`mlops-standards` and `deep-learning-standards` (**training a model**: pipeline, registry,
drift, DDP/FSDP; here only the queue that gives it the nodes),
`local-inference-standards` (serving a model), `fortran-standards`, `c-standards`,
`cpp-standards`, `julia-standards`, `r-standards`, `python-standards` (**the numerical code and
its quality are theirs**; here how it is compiled, packaged and launched),
`performance-engineering-standards` (**the general measurement methodology**: load model,
percentiles, profiling — here the domain's own metric, which is scalability),
`observability-standards`, `sre-practice-standards`, `ha-clustering-standards` (service
HA; here the cluster is *scale-out*, not *high-availability*),
`backup-recovery-standards` (**and its criteria apply in reverse in §3.6: the `scratch` is not
backed up, and that is declared**), `identity-access-management-standards` (the IdP that authenticates the
user), `linux-hardening-standards`, `selinux-standards`, `privacy-engineering-standards`
(personal data on the cluster), `grc-compliance-standards`, `finops-standards` (cloud cost and
the comparison against owned hardware), `green-it-standards` (the footprint of the computation),
`onprem-standards` (**platform umbrella and its routing table §1.2**: its invariants
win), `homelab-standards` (**proportionality**: four machines at home are not an HPC
cluster and do not need Slurm), and `embedded-iot-standards`.

## 2. Default decisions

> Verify the latest version, the state of the project and **the licence by reading the file
> raw** before pinning anything (§8).

### 2.1 Toolchain

| Piece | Default | Reason / justifiable alternative |
|---|---|---|
| Scheduler | **Slurm** | De facto standard in academic HPC and in much of the commercial world; GPL (with an OpenSSL exception), commercial support from SchedMD available. Justifiable alternatives below |
| Module environment | **Lmod** | Hierarchical, with `module spider` and conflict blocking; replaces classic `environment-modules` without breaking the `module load` syntax |
| Software builds | **Spack** for the site's stack | Dual **Apache-2.0 / MIT** (verified raw). Models variants, compilers and dependencies as *specs*; generates Lmod modules. **EasyBuild** (GPL-2.0, verified raw) is a legitimate and mature alternative, with more prescriptive *easyconfigs* |
| Containers | **Apptainer** (`.sif`) | **BSD-3-Clause** and a Linux Foundation project (verified raw, see §3.4). Runs as the user, with no daemon, and mounts the parallel filesystem. **Docker does not fit** because of its privilege model |
| MPI | **Open MPI** unless there is a reason | The network vendor's MPI usually wins on performance and is a legitimate alternative; **MPICH** is the other solid base and the one many commercial MPIs derive from |
| Parallel filesystem | **Lustre** in large installations; **CephFS** if Ceph is already there | See §2.3: the choice is driven as much by licence and support as by the I/O pattern |
| Node provisioning | **Stateless or rebuildable compute nodes** (image, not accumulated configuration) | A *snowflake* compute node breaks the reproducibility of results, which here is the product. `xCAT` and `Warewulf` are the niche's own tools; the general criteria belong to `os-provisioning-standards` |
| Accounting | **`slurmdbd` from day one** | It is not optional (§3.2) |

Versions observed in August 2026 — **they are verified, not copied** (§8): Slurm **26.05.x**
(half-yearly `YY.MM` cadence, 18 months of support), Open MPI **5.0.x**, Apptainer **1.5.x**,
Spack **1.2.x**, Lustre LTS **2.15.x** with feature branch **2.17.x**.

### 2.2 Alternatives to the scheduler, and the comparison that is made badly

- **PBS Pro / OpenPBS** (Altair). **Licence warning, verified raw**: OpenPBS is
  **AGPL-3.0-or-later**, not GPL and not permissive. The opposite is frequently believed; if there is
  any modification exposed as a service, the legal conversation changes. PBS Professional
  is Altair's commercial edition under a proprietary licence.
- **IBM Spectrum LSF**: proprietary, strong in industrial and EDA environments. Migrating from LSF to
  Slurm is translatable in the basics (`bsub` → `sbatch`) and painful in everything else: policies,
  accounting and user scripts.
- **Kubernetes**: **it is not a direct substitute for a batch scheduler**, and presenting it as
  one is the fashionable design error. Differences that a plugin does not close:
  - K8s schedules **pods that must keep running**; Slurm schedules **jobs that must
    finish**, with whole-node reservation, *backfill* and a time limit as a contract.
  - An MPI job needs **gang scheduling**: all ranks
    start at once or none starts. The default K8s scheduler does not do that; there are
    projects that add it (Volcano, Kueue, Slinky/Slurm-on-K8s). **The criteria for queues and
    *gang scheduling* inside the cluster belong to `kubernetes-standards` §6**, which has them
    verified; **the criteria for when that workload must not run on Kubernetes belong here** and
    win over the choice of tool. Slinky remains a Declared gap (§8).
  - The native equivalent of **fairshare and per-project consumption accounting** is missing, and that is
    the whole reason a shared cluster exists.
  - **When it does fit**: service workloads, inference, portals, CI and data flows around the
    cluster. **Coexisting is normal; replacing, almost never.** The decision is made on the work
    model (finish vs. keep running), not on platform preference.

### 2.3 Parallel filesystems — licence and I/O pattern

**None of these licences is asserted from memory; they are read raw or from the vendor's
source** (§8).

| System | Licence / model | When, and what kills it |
|---|---|---|
| **Lustre** | Kernel modules under `GPL-2.0 WITH Linux-syscall-note` (verified in the repo's `COPYING`); other components under GPL-2.0-compatible licences | The workhorse of big HPC: extremely high sequential throughput with *striping*. **Metadata kills it**: millions of small files saturate the MDS long before the bandwidth |
| **IBM Storage Scale** (formerly **Spectrum Scale**, formerly **GPFS**) | **Proprietary, paid**, with editions (Data Access / Data Management / Erasure Code) and a licence metric by capacity or by socket | Enterprise ecosystem, data life cycle management and integrated tiers. The cost and the licence metric are part of the decision, not a detail |
| **BeeGFS** | **It is not open source.** The kernel client is GPL-2.0; **everything else is governed by the *BeeGFS License Agreement*** (raw file verified, **"As of February, 2026"**), with internal use, scale limits and **technical licence keys from version 8 onwards** | Easy to deploy and very fast on small and medium workloads. **Check the terms and thresholds before sizing**: they changed in 2026 |
| **CephFS** | LGPL-2.1/LGPL-3.0 (Ceph); verify raw before citing | Coherent if Ceph is already operated for block and object. Less throughput per client than Lustre in the classic HPC case; in exchange, a single platform to operate |

**Cross-cutting rule, and the one users find hardest**: **the enemy of every parallel
filesystem is the small file.** It is designed for a few huge files read and
written in parallel. A job that creates 10 million 4 KB files —typical of meshes,
image datasets and per-rank *checkpoints*— degrades the **whole** cluster, not just
its own job. Mitigation: pack them (tar, HDF5, dataset formats), collective I/O
(MPI-IO, parallel HDF5), one file per job instead of one per rank, and use the node's
local disk when it exists.

## 3. Structure and conventions

### 3.1 Cluster architecture

Separate roles, no exceptions:

- **Login node(s)**: the front door. Edit, submit jobs, look at results. Nothing else.
- **Compute nodes**: where the work happens. No interactive users except through a scheduler
  reservation.
- **Management node(s)**: `slurmctld`, `slurmdbd`, the database, imaging and
  monitoring services. **Separate from the login node**, because the login node is the node users bring down.
- **Parallel filesystem servers**: dedicated (MDS/OSS or equivalents).
- **Data transfer node(s)** when there is bulk ingress/egress, so that the
  transfer does not compete with the login node.

**Why nobody compiles on the login node**: the login node is shared by dozens of users
with no resource isolation. A `make -j$(nproc)` consumes all the CPU and all the memory of the
node **everyone** comes in through; the result is that nobody can even look at their queue.
Besides, the resulting binary inherits the login node's processor capabilities, which may not
be those of the compute nodes — a `-march=native` there produces an executable that blows up
with an illegal instruction on the compute side, or that runs below its potential.
**You compile in an interactive job (`salloc`/`srun`) or on a node dedicated to builds.**
And you apply **per-user resource limits on the login node** (cgroups via systemd, `ulimit`,
`arbiter`-like), because a written rule is not enough: it is enforced or it does not exist.

### 3.2 Slurm — what has to be decided

- **Partitions by *function*, not by whim**: short and interactive, long, big-memory,
  GPU, debugging. Every partition with an **explicit time limit**. A partition
  without `MaxTime` is a queue where jobs move in permanently.
- **Whole node or shared**: decide it and document it. Sharing a node requires
  **`cgroup.conf` with real CPU and memory containment**, or a job that overruns its memory
  kills its neighbour. Without *cgroups*, the node is allocated whole.
- **Per-association limits** (account/user/partition): queued jobs, running
  jobs, nodes, CPU-hours. They exist so that a single user cannot occupy the cluster; they are set
  **before** the incident.
- **QoS** to express priority and policy: high priority with *preemption*,
  low priority and *preemptible* for opportunistic backfill, debug QoS with a short limit and
  little waiting.
- ***Fairshare***: priority is computed against historical consumption relative to the assigned
  quota. It is what makes a group that consumed a lot last month give way. **It does
  not work without accounting.**
- ***Backfill***: it fills gaps with short jobs, and **it only works if users request
  realistic times**. Requesting the maximum "just in case" is what degrades the cluster's overall
  efficiency; it is fought by showing the user their real efficiency (`seff`/`sacct`).
- **Accounting (`slurmdbd`) — a requirement, not a luxury.** Without it there is no *fairshare*, no
  per-project usage report, no way to justify the next purchase, no way to
  know whether the cluster is used or wasted, and no trace of who ran what. It is installed
  on day one; retrofitting it does not recover the lost history.
- **Upgrades**: Slurm supports live upgrades from the supported previous major
  versions, in a specific order (`slurmdbd` first) and **with a copy of the database
  taken beforehand**. Verify the matrix for the specific version (§8) — skipping an unsupported
  version forces a manual migration.
- **Prologue/epilogue**: clean up orphaned processes, delete the node's temporary files and sanitise the
  state between jobs. A node that drags along processes from the previous job is the
  silent cause of "my job runs half as fast as yesterday".

### 3.3 MPI, affinity and scalability

- **Affinity is always pinned.** Without *pinning*, the operating system scheduler moves
  ranks between cores and between NUMA nodes; performance becomes non-reproducible and drops.
  It is set by the launcher (`srun --cpu-bind`, the MPI's *mapping* options) and **it is verified**
  by printing the rank-to-core map before believing a measurement.
- **The classic error of the domain: measuring scalability without pinning affinity.** The resulting
  curve does not measure the code, it measures the scheduler's randomness. Every scalability measurement
  declares: affinity, MPI and compiler versions, rank distribution, problem
  size, and whether the node was exclusive.
- **Strong scaling** (fixed problem, more resources: does the time go down?) versus **weak**
  (problem grows with the resources: does the time hold?). You declare **which one** you are
  measuring. A strong-scaling curve that flattens is not a failure: it is Amdahl's
  law, and the point where it flattens **is** the useful result, because it marks the number of nodes
  beyond which asking for more is wasting quota.
- **A single node first.** Before scaling, you check that the code uses one node well:
  vectorisation, memory, threads. Scaling inefficient code multiplies the waste.
- **Hybrid MPI+OpenMP**: it reduces ranks and communication, but it requires placing threads by NUMA node.
  It is justified by measurement, not by default.

### 3.4 Software environment

- **The user does not compile their dependencies by hand.** They are given a stack built with Spack or
  EasyBuild and exposed through Lmod. The opposite is a cluster with twelve versions of the same
  library and no reproducible results.
- **Modules are versioned explicitly.** `module load fftw` without a version makes next
  week's job use a different library with no warning. In a job script, the
  version is written down.
- **The job's environment is declared inside the script**, it is not inherited from the user's
  shell. Inheriting `~/.bashrc` is the usual cause of "it works in my session and not in the queue".
- **Containers in HPC: Apptainer**, and the reason is the privilege model. Docker requires a
  daemon with root privileges and puts the user in a group equivalent to root on the
  node; on a shared multi-user machine that is unacceptable. Apptainer runs the image
  **as the user who launches it**, with no daemon, with the parallel filesystem and the node's
  network visible, and with the image as **a single `.sif` file** — which is also
  friendly to the parallel filesystem, unlike a tree of layers.
  - **Naming and governance note, verified**: the project was called **Singularity** and was
    renamed **Apptainer** when it joined the **Linux Foundation**; in parallel there is a
    commercial product of the same name from a different company. When citing documentation you have to look at **which** of the two
    it is. Licence read raw: **BSD-3-Clause**.
  - The container **exempts you from nothing**: the image is versioned, signed or verified by
    digest, and declared in the job. A `.sif` with no provenance is an opaque binary running
    with the user's data.

### 3.5 Storage: home, scratch and archive

Three tiers with different purposes, and **confusing them is the origin of most of the
domain's data incidents**:

| Tier | What for | Quota | Backup | Performance |
|---|---|---|---|---|
| `home` | Code, scripts, configuration | Small and strict | **Yes** | Modest |
| `scratch` (parallel) | Data of running jobs | Large | **No** | Maximum |
| `archive` / object / tape | Results that must be kept | Large | Yes, and that is its reason for existing | Slow, high latency |

- **The purge policy is mandatory, and it is announced.** The `scratch` is purged by access
  age (typically weeks). Without purging, the `scratch` fills up, and a full `scratch` stops
  the whole cluster, not one user.
- **The purge is communicated in advance, notified individually and applied without exception.**
  Informal exceptions are how a purge system stops working.
- **The `scratch` is not backed up, and that is stated in writing** in the service documentation and
  in every user's onboarding. A user who loses three months of results because
  they believed there was a copy is a service communication failure, not a user failure.
- **Per-project quotas as well as per-user ones**, in space **and in number of inodes**. The inode
  quota is what really curbs the small-file problem (§2.3).
- ***Checkpointing*** of the application: long jobs write state periodically and
  know how to resume. It is what turns a node failure into an hour lost instead of a week,
  and what allows short, healthy partition time limits.

### 3.6 GPUs in the cluster

- **The GPU is a schedulable and accounted resource**, just like CPU and memory: it is
  requested in the job, isolated by *cgroup* and **accounted as a TRES** so that it enters
  the *fairshare*. A cluster that does not account for GPU-hours distributes the most expensive thing it has with
  no policy at all.
- **Real utilisation is measured.** The dominant pattern is the job that reserves 8 GPUs and uses
  one at 20 %. It is instrumented and the figure is given back to the user; otherwise, the next
  expansion buys hardware to waste it just the same.
- **Separate GPU queues** from the CPU ones, with their own limits: they are the scarce and
  expensive resource. Everything else about the GPU (driver, MIG, DCGM, XID, power) belongs to
  `gpu-computing-standards`.

### 3.7 Measuring the cluster honestly

- **HPL** (the Top500 *benchmark*) measures dense linear algebra with very high arithmetic
  intensity and **almost no** memory or network pressure relative to the compute. It is a valid
  acceptance test that the machine performs as purchased, and **a terrible prediction** of the
  performance of a real application.
- **HPCG** exists precisely because of that divergence: sparse patterns, limited by memory
  bandwidth and by communication. Systems typically reach in HPCG a very
  small fraction of their HPL figure, and **that gap is the information**: it tells you how much of the
  purchased machine is reachable by real code. Consult the current lists before citing figures
  (§8); the Top500 is published twice a year (June and November).
- **The measurement that decides is the site's application**, with its data, on a set of
  representative cases. It is kept as a baseline and repeated after every change of compiler,
  MPI, driver or kernel.
- **Every figure is published with its conditions**: nodes, exclusivity, versions, affinity, problem
  size, and whether the system was in production. Without that, it is not a number, it is an anecdote.

### 3.8 Multi-user: isolation and sensitive data

- **A shared cluster is a hostile environment by default.** Users see the same machine,
  the same filesystems and the same nodes.
- **Per-project permissions**: group directories with `setgid` and ACLs, restrictive `umask` by
  default. A world-readable `home` is the most common and most boring data leak
  in the domain.
- **Per-job containment with *cgroups***: CPU, memory and devices. Without it, one job
  takes its neighbours down and no sharing policy is worth anything.
- **Compute nodes do not reach the Internet** by default, and access to a node is granted
  **only** while the user has a job allocated on it.
- **No shared credentials and no group accounts.** Identity is individual because
  accounting and traceability depend on it.
- **Sensitive data (personal, health, classified) on a shared cluster**: it does not get put in "and
  we'll see". It requires a prior decision — a segregated partition or cluster, encryption at rest,
  node restriction, export control and access logging — and coordination with
  `privacy-engineering-standards` and `grc-compliance-standards`. A shared, unbacked-up
  `scratch` is the worst possible place for regulated data.
- **Surface specific to the domain**: the scheduler runs user code on hundreds of
  nodes with its own privileged daemon. Slurm CVEs are high-risk by design; the
  scheduler's patching is treated like that of an exposed service, not like that of an internal
  utility (`vulnerability-management-standards`).

## 4. Quality and service operation

- **Cluster acceptance test before opening it**: HPL or equivalent at full load (which
  also validates the room's power and cooling), end-to-end verification of the compute
  network, throughput and metadata testing of the parallel filesystem, and a real application.
- **Node health check** integrated into the scheduler: before and after every
  job, memory, mounted filesystems, temperature and the state of the network
  and the accelerators are checked. **A node that fails is automatically marked `DRAIN`**, it is not left
  returning corrupt or slow results. This is the most profitable quality control in the
  domain: without it, a single sick node contaminates weeks of results.
- **Metrics that matter**: occupancy per partition, queue wait time per QoS,
  failed jobs by cause, CPU and memory efficiency per job, GPU utilisation,
  throughput and **metadata operations** of the parallel filesystem, nodes in `DRAIN`.
- **Per-project usage portal or report**: consumption is shown to whoever pays for it and whoever
  consumes it. Without that, accounting is a file nobody looks at.
- **Service documentation** with the minimum: how to log in, how to submit, which partitions exist,
  which limits apply, where to write, **what gets purged and when**, and what is not backed up. It is part of the
  product.
- **Announced maintenance windows with a scheduler reservation**, not manual shutdowns:
  a reservation is created that drains the queue without killing running jobs.

## 5. Long-term sustainability and prohibitions

**Cadence**: Slurm follows half-yearly `YY.MM` versions with ~18 months of support — plan
at least one major upgrade a year and **do not accumulate jumps beyond the supported direct
upgrade window**. The software stack (Spack/EasyBuild) is rebuilt in
generations, with the previous generation coexisting for a declared period. The parallel
filesystem is upgraded with a verified client/server and kernel compatibility
matrix — it is the riskiest upgrade in the cluster.

**Debt specific to the domain**: the cluster accumulates modules nobody uses, data nobody
claims and accounts of people who left three years ago. Annual review of all three, with a
date.

Prohibitions:

- ❌ **Compiling or running computation on the login node.** And prohibiting it in the
  documentation is not enough: it is limited with *cgroups*.
- ❌ **A cluster in production without `slurmdbd`** or accounting. Without it there is no *fairshare*, no
  report, and no trace.
- ❌ **Partitions without a time limit** or without per-association limits.
- ❌ **Shared nodes without CPU and memory containment by *cgroup*.**
- ❌ **`scratch` without a purge policy**, or with an announced purge that is not applied.
- ❌ **Promising or implying that the `scratch` is backed up.** It is stated explicitly that it is not.
- ❌ **Millions of small files on the parallel filesystem** as an accepted pattern; they are
  packed, and the inode quota enforces it.
- ❌ **`module load` without a version** in a job script.
- ❌ **Publishing a scalability measurement without declaring affinity**, versions, problem
  size and node exclusivity.
- ❌ **Using HPL as a prediction of a real application's performance**, or citing a
  Top500/HPCG figure without the list and the date.
- ❌ **Docker with a privileged daemon on shared compute nodes.**
- ❌ **`-march=native` compiled on a node different from the execution one** without verifying that the
  architecture matches.
- ❌ **Shared accounts or group credentials.**
- ❌ **Putting personal or regulated data on the shared `scratch`** without a prior decision on
  segregation and control.
- ❌ **Asserting the licence of Lustre, BeeGFS, Storage Scale, Slurm, Apptainer, Spack or OpenPBS
  from memory.** Four of them are not what people believe, and one changed in 2026 (§2.3).
- ❌ **Presenting Kubernetes as a substitute for a batch scheduler** without having explicitly
  solved gang scheduling, *fairshare* and accounting.

## 6. Mandatory web verification

Before pinning any datum in this document:

1. **Slurm**: latest version and the supported direct upgrade window. Verified in August
   2026: tags `v26.05.2` and `v25.11.7` in the repository; half-yearly `YY.MM` cadence with
   18 months of support (confirmed in SchedMD's roadmap presented at SC'25).
   **`schedmd.com/slurm-support/release-announcements/` redirects to GitHub Releases** — use the
   tags Atom feed, not the releases feed and not an unauthenticated API.
2. **Licences, read raw — result of this verification**:
   - Slurm: the repository's `COPYING` → **GPL with an explicit exception for linking with OpenSSL**.
   - Apptainer: `LICENSE.md` → **BSD-3-Clause**, "Apptainer a Series of LF Projects LLC".
   - Lustre: `COPYING` → `SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note` for the
     kernel modules; other components, GPL-2.0-compatible licences.
   - OpenPBS: `LICENSE` → **AGPL-3.0-or-later** (Altair). **It is neither GPL nor permissive.**
   - Spack: **Apache-2.0 / MIT** dual. EasyBuild: **GPL-2.0**.
   - BeeGFS: `LICENSE.txt` refers to the *BeeGFS License Agreement*; the raw text declares itself
     **"As of February, 2026"** and limits the use of the Community edition to internal use, with
     technical licence keys from version 8 onwards. **It is not free software.** Re-verify
     before any deployment: the terms changed in 2026 and may change again.
   - **Declared gap**: the licence of **CephFS** has been taken as known (LGPL) but **it has not
     been read raw in this pass**; read it before citing it.
   - **Declared gap**: **IBM Storage Scale** is proprietary and its licence metrics
     (capacity versus socket, editions) have been taken from IBM documentation, not from a
     contract. Any cost figure is requested from IBM or the reseller.
3. **Lmod**: **declared gap** — the licence file was not located at the path
   tried (`COPYRIGHT` on `master` returns 404). Read it in the TACC repository before
   asserting it.
4. **Names and governance**: Apptainer ↔ Singularity (renamed when joining the Linux
   Foundation, plus a commercial product of the same name from a different company) and GPFS ↔ Spectrum Scale ↔
   **IBM Storage Scale**. Check which one the documentation you are reading is talking about.
5. **Kubernetes for HPC**: ~~status and licence of Volcano and Kueue~~ — **gap CLOSED**: they are
   verified in `kubernetes-standards` §6 (with their version, API, governance and licence); use
   that one and re-verify there. **Still open**: the Slurm–Kubernetes integrations (Slinky and
   equivalents), which have not been verified and are cited as an option to evaluate, not as a
   recommendation.
6. **Versions**: Open MPI (5.0.x observed), MPICH, Apptainer (1.5.x), Spack (1.2.x), Lustre
   (LTS **2.15.x**, feature branch **2.17.x**) — and the **kernel and client/server compatibility
   matrix** of the filesystem, which is what breaks a migration.
7. **Scheduler and filesystem CVEs**: triage with CVSS + EPSS + **KEV**. Slurm
   has had high-impact escalation vulnerabilities; it is actively watched.
8. **Figures**: Top500/HPCG are published in June and November; every cited figure carries its list and
   date. **No estimate of "average cluster efficiency" or of "percentage of peak
   achievable" is written without a source and a methodology.**

If the web contradicts this document, **the web wins** — flag the discrepancy.
