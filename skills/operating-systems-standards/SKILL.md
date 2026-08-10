---
name: operating-systems-standards
description: Operating-system mechanics as an engineering constraint — what the kernel actually does to your program and which design decisions follow from it. Use when reasoning about CPU scheduling and latency (EEVDF versus the older CFS, sysctl_sched_base_slice, nice and sched_setscheduler, SCHED_FIFO/SCHED_RR/SCHED_DEADLINE via chrt, isolcpus and CPU pinning with taskset, sched_ext BPF schedulers, PREEMPT_RT and preempt=none/voluntary/full, interrupt latency and threaded IRQs, cyclictest), the real cost of a system call and a context switch (vDSO, KPTI and speculative-execution mitigation overhead, syscall batching), virtual memory (page faults, TLB misses, transparent huge pages and MADV_HUGEPAGE versus hugetlbfs, vm.overcommit_memory and Committed_AS, the OOM killer and oom_score_adj, memory.high versus memory.max in cgroup v2, PSI pressure metrics, swappiness and zram/zswap), I/O models (blocking versus O_NONBLOCK, select/poll/epoll, io_uring and its security history, O_DIRECT, readahead, page cache and dirty writeback tuning), filesystem durability semantics (fsync, fdatasync, sync_file_range, the fsync error-reporting problem and why a successful write is not a durable write, journalling modes, write barriers and volatile disk caches), namespaces and capabilities as the actual substance of a container, NUMA topology and numactl, virtualization and paravirtualization (KVM, virtio, steal time, ballooning), monolithic versus microkernel designs (seL4, QNX, Redox, Fuchsia/Zircon) and hard versus soft real-time requirements.
---

# Applied operating systems standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **using knowledge of the operating system to decide**: why a service has latency
spikes that the code does not explain, why the process died with no trace, why "I wrote it
and it was lost", how much a system call really costs, what a container does and does not
guarantee, and when a real-time requirement is real. **This is not university theory**: every section
exists because it decides a design choice or settles an argument.

Triggers: EEVDF, CFS, `sysctl_sched_base_slice`, `nice`, `sched_setscheduler`, `chrt`, `SCHED_FIFO`,
`SCHED_RR`, `SCHED_DEADLINE`, `SCHED_IDLE`, `taskset`, `isolcpus`, `nohz_full`, `sched_ext`/SCX,
`PREEMPT_RT`, `preempt=none|voluntary|full`, `cyclictest`, "interrupt latency", vDSO,
cheap `getpid()`, KPTI, speculative mitigations, context switch, `vm.overcommit_memory`,
`CommitLimit`, `Committed_AS`, OOM killer, `oom_score_adj`, `/dev/kmsg` with "Out of memory: Killed
process", `transparent_hugepage`, `MADV_HUGEPAGE`, `hugetlbfs`, TLB, `vm.swappiness`, `zswap`,
`zram`, `memory.max`, `memory.high`, `memory.pressure`, PSI (`/proc/pressure/*`), `cpu.max`,
"CPU throttling in the container", `epoll`, `io_uring`, `O_NONBLOCK`, `O_DIRECT`, `fsync`,
`fdatasync`, `sync_file_range`, `data=ordered`/`data=writeback`, *write barrier*, volatile disk
cache, `unshare`, `clone(CLONE_NEW*)`, `/proc/self/ns/`, `capabilities(7)`, `CAP_SYS_ADMIN`,
`numactl`, `numastat`, "remote NUMA memory access", KVM, virtio, *steal time*, *ballooning*,
microkernel, seL4, QNX, Redox, Fuchsia/Zircon, "hard real time", "soft real time".

**Guiding principle**: **the operating system is not an implementation detail; it is the one that decides.**
A program that is correct on false assumptions about the OS —that `write()` persists, that a container isolates,
that a memory limit produces an error and not a death, that `nice` gives real time— fails in
production in the worst way: late, with no trace and non-reproducibly. The working rule that
follows: **no OS behaviour is asserted from memory; it is read from its documentation or measured
on the specific system** (§4), because **the answer depends on the kernel version, the
filesystem, the hypervisor and the hardware**, and all four change.

**Not applicable**: see `linux-administration-standards` (**day-to-day administration is theirs, without
exception**: systemd units and their `Type=`/`Restart=`/dependencies, `journalctl` and retention,
`systemd-analyze blame`, host networking, packages, time, and the **operational diagnosis** of a host that
is slow or will not boot. **Precise boundary agreed from this side**: *the systemd knob is theirs, the
kernel semantics behind it are mine* — `MemoryMax=` and `systemd-oomd` are configured there;
**why `memory.high` throttles and `memory.max` kills, and why that is a design decision and not
an accident, belongs here**), `performance-engineering-standards` (**the measurement methodology and
profiling are theirs**: defining the latency objective as a percentile + concurrency + hardware,
open/closed load models, coordinated omission, sampling, *flame graphs*, continuous profiling,
USE and RED. **Arbitration rule: *"how is the number measured and how is it interpreted?" is theirs; "which
OS mechanism produces that number and what do you change to move it?" belongs here***. A tuning of this
skill without their measurement is superstition), `container-runtime-security-standards` (**container
isolation as a security control is theirs**: seccomp profiles, alternative
runtimes —gVisor, Kata—, escape, runtime detection, capabilities as Pod hardening.
**Here only the mechanism**: what a namespace is, what it shares and what it does not, and why a container is not
a virtual machine), `kernel-drivers-standards` (**direct sibling**: the **code** written
inside the kernel, its concurrency —spinlocks, RCU, atomic contexts—, its DMA, its debugging with
KASAN/lockdep and its upstream process. *"How do I write this driver?" is theirs; "why does the system
behave like this?" belongs here*), `linux-hardening-standards` (CIS/STIG baseline and its measurement; security
`sysctl`s are theirs, OS behaviour ones belong here), `selinux-standards`
(MAC), `linux-storage-standards` and `zfs-standards` (LVM, RAID, block layers, ZFS — **durability
semantics and `fsync` are argued here and implemented there**), `sre-practice-standards`
(SLO, error budget), `observability-standards` (telemetry platform), `libvirt-kvm-standards`,
`proxmox-ve-standards`, `vmware-standards`, `hyper-v-standards` and `xen-standards` (**operating the
hypervisor is theirs**; here only what virtualisation implies for the program running inside:
*steal time*, clock, virtual NUMA), `kubernetes-standards` (requests/limits as a declarative object;
**here what the kernel does when that limit is reached**), `embedded-iot-standards` (**sibling**:
the physical device, the RTOS and the superloop — **the hard real-time discussion is a
shared boundary**: the criteria for what real time is and what `PREEMPT_RT` guarantees belong here, the
choice of RTOS for an MCU is theirs), `bsd-systems-standards` and `aix-solaris-hpux-standards` (other
operating systems as a production platform), `c-standards`, `cpp-standards`, `rust-standards`
and `go-standards` (the language, its runtime and its abstractions over all of this).

## 2. Default decisions

> Verify on the web against the specific kernel version before committing to anything (§8). State
> **verified** as of August 2026 against the `git.kernel.org` tree and `kernel.org`.

| Topic | Default | When to deviate, and with what evidence |
|---|---|---|
| Scheduling | **Do not touch anything.** The default scheduler is correct for 95% of workloads | Only with a measurement proving that scheduling latency —not something else— is the bottleneck |
| Real-time priority | **Forbidden by default** in general-purpose services | Only with bounded `SCHED_FIFO`/`SCHED_RR`, a limited CPU budget and a watchdog: **a loop at RT priority that never yields hangs the core** |
| CPU pinning | No | When there is strict core isolation (`isolcpus`, `nohz_full`) and the gain has been measured against the cost of losing balancing |
| Huge pages | **`madvise`**, not `always` | `always` only after measuring; `hugetlbfs` with reservation when the database or the VM explicitly asks for it |
| Overcommit | **Mode 0 (heuristic)**, the kernel default | Mode 2 only when it is required that the allocation fails instead of the process dying |
| Swap | **Yes, with swap configured** (even a small one, or `zram`/`zswap`) | Without swap the kernel loses the way to reclaim cold anonymous pages and reaches the OOM killer sooner: "removing swap" **does not avoid the OOM, it brings it forward** |
| Memory limit | **`memory.max`** as a safety net + **`memory.high`** to throttle beforehand | See §6.2: they are different mechanisms, not two forms of the same thing |
| Concurrent network I/O | **`epoll` in *level-triggered* mode**, whether directly or via the language runtime | `io_uring` only with measured justification and an explicit security decision (§5.3) |
| Durability | **`fsync`/`fdatasync` with the error treated as fatal** | Never "retry the `fsync`" (§6.4) |
| Strong isolation | Virtual machine | The container **shares the kernel**: if the threat model includes an escalation through a kernel flaw, the container is not the boundary (§5.2) |
| Real time | **It is almost always *soft* real time** and is solved with a latency budget and queues | `PREEMPT_RT` when the deadline is hard on Linux; an RTOS or a microkernel when the deadline is hard **and** it has to be certified |

### 2.1 The current scheduler — the fact most often misquoted

**CFS is no longer Linux's fair-class scheduler: it is EEVDF.** Verbatim from
`Documentation/scheduler/sched-eevdf.rst` in the current tree: *"The Linux kernel began transitioning
to EEVDF in version 6.6 … moving away from the earlier Completely Fair Scheduler (CFS) in favor of a
version of EEVDF proposed by Peter Zijlstra in 2023"*. Practical consequences:

- The classic CFS *tunables* (`sched_latency_ns`, `sched_min_granularity_ns`) **are no longer the
  model**; the relevant parameter is the base *slice* (`sysctl_sched_base_slice`). **Any
  tuning guide that talks about `sched_latency_ns` is describing a kernel you do not have.**
- EEVDF assigns each task a *request* (slice) and a virtual deadline, and picks the earliest-deadline
  one among those with non-negative *lag*. Operational translation: a task that wakes up and
  has consumed little **can preempt** the running one, which **improves** interactive latency and
  **can worsen** the aggregate throughput of batch workloads. If a kernel change moved the
  latency profile of a service, this is the first suspect.
- **`nice` is not real-time priority.** It is a weight within the fair class: a process with
  `nice -20` still yields to any `SCHED_FIFO` task, and it guarantees no deadline whatsoever.
- **`sched_ext` (SCX)** has been in mainline since 6.12: it allows loading schedulers written in eBPF and
  swapping them live, and the class hierarchy becomes `stop > deadline > rt > ext > fair (EEVDF)
  > idle`. It is a real tool —there are deployments in games and on servers— **and also a fast
  route to non-reproducible behaviour**: if it is used, the loaded scheduler is part of the
  system's versioned configuration and is declared in any performance report.

### 2.2 Real time: hard, soft and `PREEMPT_RT`

**Real time does not mean fast: it means bounded.** A hard real-time system is one that
has a deadline whose breach is a system failure, not a degradation. Almost everything
called "real time" in a backend discussion is **soft real time** and is solved with a
latency budget, bounded queues and controlled degradation — not by touching the scheduler.

`PREEMPT_RT` **is in the mainline tree**, as a configuration option. Verbatim from
`kernel/Kconfig.preempt`: *"This option turns the kernel into a real-time kernel by replacing various
locking primitives (spinlocks, rwlocks, etc.) with preemptible priority-inheritance aware variants,
enforcing interrupt threading and introducing mechanisms to break up long non-preemptible sections."*
What you must know before enabling it:

- It depends on `EXPERT` and on `ARCH_SUPPORTS_RT`: **not every architecture supports it**, and you must
  check for yours.
- **It reduces maximum latency at the cost of aggregate throughput.** It is a trade-off, not an improvement:
  whoever enables it "just in case" pays throughput without needing to.
- It does not make your application real time: if the application allocates memory on the critical path,
  page faults, touches disk or calls a remote service, it is the application that breaks the deadline. `PREEMPT_RT`
  guarantees the kernel, not your code.
- **It is verified by measuring maximum latency under real load** (`cyclictest` with the system's
  background load, for hours), not by reading the configuration.

### 2.3 Monolithic versus microkernel — what actually decides

The debate is decided neither by elegance nor by performance: it is decided by **certification and the
driver ecosystem**.

| System | Verified status (Aug 2026) | What makes it eligible |
|---|---|---|
| **Linux** (modular monolithic) | Mainline 7.2-rc6, stable 7.1.6, LTS 6.18/6.12/6.6/6.1/5.15/5.10 | **Ecosystem**: it supports more hardware on more architectures than anything else. It is almost always the answer |
| **seL4** (microkernel) | Kernel under **GPL-2.0-only**, user-space code mostly **BSD-2-Clause** (`LICENSE.md`, SPDX per file); with a **syscall note** analogous to Linux's: using kernel services through a normal call does **not** make your code a derivative work | **Formal verification** of the kernel. Eligible when the mathematical guarantee is a requirement (defence, avionics, critical isolation) — and only then, because the ecosystem is minimal |
| **QNX** (microkernel, commercial) | Proprietary, with support and functional safety certifications | **Automotive and critical systems with certification and commercial support**. You pay for the paperwork, and sometimes the paperwork is the requirement |
| **Fuchsia / Zircon** (microkernel) | Alive: release **F30 (2026-04-07)**; its commercial deployment is still essentially Google smart displays | Technical and research interest. **It is not a platform on which to build third-party product today** |
| **Redox** (microkernel, Rust) | **MIT** (`LICENSE` at `gitlab.redox-os.org`) | A reference research and engineering project. Not a production platform |

Rule: **choosing a microkernel is choosing a small ecosystem in exchange for a specific property**
(formal verification, driver isolation, certification). If you cannot name that property
and who requires it in writing, the answer is Linux.

## 3. Mental model and invariants

The six invariants this skill requires you to assume in any design:

1. **A system call is not a function call.** It costs the mode switch, plus the cost of
   the speculative execution mitigations active on that system, plus the effect on caches and
   TLB. That is why the **vDSO** exists (`clock_gettime`, `getpid` and company resolved without entering the
   kernel), along with batched I/O and `epoll` versus one `poll` per descriptor. The cost **is not a
   universal constant**: it depends on the hardware and on which mitigations are active — **it is measured on the
   target system**.
2. **A context switch costs more than its CPU time**: it is paid mostly in cold caches and TLB.
   Hence "more threads" stops helping far sooner than intuition says, and CPU
   affinity matters.
3. **`write()` does not mean "on disk"; it means "in the page cache"** (§6.4).
4. **Virtual memory is not memory.** Reserving is not touching; `Committed_AS` is not RSS; a page
   only exists when it is faulted on. Measuring "memory used" by virtual size is measuring
   nothing.
5. **The container shares the kernel.** All that isolates it is namespaces, cgroups, capabilities and
   syscall filtering: mechanisms of the very kernel that is shared (§5.2).
6. **Under a hypervisor, the clock and the CPU lie.** *Steal time* means your vCPU was
   ready and was not running; unexplained latency in a VM is looked for **there first**, and a time
   measurement taken inside a guest has noise that does not exist on bare metal.

## 4. How an assertion about the system is verified (quality)

This skill has no *linter*; it has a discipline, and it is a gate: **an assertion about
OS behaviour does not enter a design, a report or a postmortem without one of these three
proofs**:

1. **A quote from the kernel documentation of the specific version** (`docs.kernel.org` or the raw file
   from `git.kernel.org`; `man 2`/`man 7` for the user interface). Not from a blog, not from
   memory — half the tuning guides in circulation describe kernels from ten years ago (§2.1
   is the canonical example).
2. **Reading the real state of the system**: `/proc/pressure/*`, `/sys/fs/cgroup/.../memory.*`,
   `/proc/meminfo`, `/proc/interrupts`, `numastat`, `/sys/kernel/mm/transparent_hugepage/enabled`,
   `chrt -p`, `taskset -pc`, `uname -r`. **The system knows how it is configured; nobody else does.**
3. **A before/after measurement with the real load**, with the methodology of
   `performance-engineering-standards` and varying **one** parameter. A `sysctl` tweak without prior
   and subsequent measurement is folklore, and it gets reverted.

Additional rules: **the experiment is run on a system identical to production** (same
kernel version, same hypervisor, same filesystem) — a result obtained on a laptop
says nothing about the server. And **every `sysctl` change, boot parameter or scheduling
policy is versioned as code** with the reason written down; a `sysctl` set by hand in
production disappears at the next reboot, and its absence gets diagnosed as a "mysterious
regression".

## 5. Stack security

### 5.1 The boundary that matters is the privilege transition
The system's attack surface is **the set of system calls and kernel interfaces
a process can reach**. Reducing it is more effective than hardening the process: fewer
reachable calls, less kernel code exposed to hostile input. The concrete mechanisms
—seccomp profiles, MAC, Pod capabilities— belong to the sibling skills; **what this skill fixes
is the criteria**: every exposed service runs with the minimum set of capabilities and calls
it needs, and that set is determined by observing, not by guessing.

### 5.2 Namespaces and capabilities: the real substance of the container
- A container **is** a process with namespaces (pid, mount, net, uts, ipc, user, cgroup, time),
  a cgroup with limits, a set of capabilities and a syscall filter. **There is nothing else.**
  There is no hypervisor, there is no hardware boundary: **the kernel is one and it is the same one**.
- **`CAP_SYS_ADMIN` is equivalent to root** for practical purposes: it groups so many different operations
  that granting it voids the rest of the least-privilege exercise.
- **The *user namespace* is what changes the model**, because it lets the container's root not
  be the host's root. It has also, historically, been a source of vulnerabilities in itself:
  it is a conscious trade-off, not a free improvement.
- **Hard design rule**: if the threat model includes *"the attacker controls the process and there is
  a kernel flaw"*, **the container is not the security boundary**. That calls for a virtual machine or a
  runtime with its own kernel. Deciding that is an architecture decision, and it is documented.
- **What a namespace does not isolate is also design**: the clock (except with a *time namespace*), the
  scheduler, kernel state, many files under `/proc` and `/sys`, and —crucially for
  performance— **the information the runtime libraries see**: a runtime that reads
  the host's CPU count inside a container limited to half a CPU will size its thread pool wrongly
  and throttle itself (§6.3).

### 5.3 `io_uring`: performance with a history you must know
`io_uring` is Linux's modern asynchronous I/O interface and it is genuinely fast. **It has also
been, by a wide margin, the most productive source of kernel privilege escalations of recent
years**: Google reported in 2023 that **60% of the exploits** submitted to its bounty programme
in 2022 exploited `io_uring`, and that it was present in **every** submission that bypassed its
mitigations. The consequences are still current and operational: **Google disabled it in
ChromeOS** (at compile time) and restricted it in Android and on its servers, and **Docker and
containerd removed it from their default seccomp profile** — so that **in a container with the
standard profile, `io_uring` simply does not work**, and that is an expensive discovery if it is made in
production. The subsystem has matured a great deal since then and still receives CVEs because of its growing
surface.

**Criteria**: `io_uring` is enabled **deliberately, for the workload that justifies it with a
measurement**, with the risk decision written down — not by default everywhere. If the gain over
`epoll` has not been measured, there is no case.

### 5.4 OS mechanisms as a control, not as an accident
Resource limits (`RLIMIT_*`, `cgroup v2`), `oom_score_adj`, behaviour `sysctl`s and
namespaces **are availability controls**: a process with no memory limit on a shared
host is a denial of service waiting to happen, and the victim the OOM killer picks
probably will not be the culprit (§6.2). They are configured on purpose and documented.

## 6. Performance and operability

### 6.1 Virtual memory, TLB and huge pages
Every memory access goes through address translation; the **TLB** speeds it up and it is small. A
workload with a large working set and scattered access can spend a significant fraction of its
time in TLB misses **without it showing up in any CPU profile as anything recognisable**. *Huge
pages* attack exactly that: fewer entries to cover the same memory.

**But THP is not free** and the kernel's own documentation says so. Verbatim from
`Documentation/admin-guide/mm/transhuge.rst`: *"In certain cases when hugepages are enabled system
wide, application may end up allocating more memory resources"*, and the explicit recommendation:
*"Applications that gets a lot of benefit from hugepages and that don't risk to lose memory by using
hugepages, should use madvise(MADV_HUGEPAGE) on their critical mmapped regions"*, with the hard rule
for the other end of the spectrum: *"Embedded systems should enable hugepages only inside madvise
regions to eliminate any risk of wasting any precious byte of memory"*. Hence the §2 default:
**`madvise`, not `always`** — `always` has a history of erratic latencies from compaction and of
wasted memory, and several databases recommend disabling it. **It is decided by measuring, and the
decision is documented.**

### 6.2 Overcommit, OOM killer and limits — design decisions, not accidents
Linux **overcommits memory by default**, and that is a deliberate choice. Verbatim from
`Documentation/mm/overcommit-accounting.rst`, mode 0: *"Heuristic overcommit handling. Obvious
overcommits of address space are refused. Used for a typical system. It ensures a seriously wild
allocation fails while allowing overcommit to reduce swap usage. This is the default."* And mode 2:
*"Don't overcommit … in most situations this means a process will not be killed while accessing
pages but will receive errors on memory allocation as appropriate."*

**That is the whole trade-off, and it is an architecture decision**: either the system promises what
it does not have and one day kills somebody (mode 0/1), or it refuses allocations earlier and the failure appears as
a manageable error at the point of allocation (mode 2). Choosing mode 2 requires applications to
**handle the allocation failure**, which many do not. Choosing the default means accepting that
**the OOM killer is part of the system's design** and that you must tell it whom to prefer: that is
`oom_score_adj` and per-service limit allocation, not a prayer.

In `cgroup v2` there are **two different mechanisms**, and confusing them is the usual mistake. Verbatim from
`Documentation/admin-guide/cgroup-v2.rst`:
- `memory.high`: *"Memory usage throttle limit. If a cgroup's usage goes over the high boundary, the
  processes of the cgroup are throttled and put under heavy reclaim pressure. **Going over the high
  limit never invokes the OOM killer** and under extreme conditions the limit may be breached."*
- `memory.max`: *"Memory usage hard limit. This is the main mechanism to limit memory usage of a
  cgroup. If a cgroup's memory usage reaches this limit and can't be reduced, **the OOM killer is
  invoked in the cgroup**."*

Translated into criteria: **`memory.high` is the signal and the brake; `memory.max` is the trigger.** The
correct design puts `high` below `max` so the system throttles and warns before
killing, and **watches the pressure (PSI, `/proc/pressure/memory` and `memory.pressure`)**: pressure rises
long before death arrives, and it is the only signal that allows reacting in time. A
service with only `max` has no advance warning, it has an autopsy. Same with CPU: `cpu.max` produces
*throttling* that shows up as unexplained tail latency — **the cgroup's throttling metric
is mandatory to collect** in any deployment with limits.

### 6.3 NUMA, virtualisation and what the process thinks it knows about the machine
- **NUMA**: on a multi-socket server, remote memory is slower and its bandwidth is
  shared. A process whose threads migrate between nodes and whose memory is on the wrong node
  pays for it with nothing to indicate it. Look at `numastat` before theorising; pin (`numactl`) only with a
  measurement, because pinning badly is worse than not pinning.
- **Virtualisation**: *steal time* (the ready vCPU that was not running) is the first thing to look at when facing
  unexplained latency inside a VM; *ballooning* can pull memory out from under the
  guest; and paravirtualisation (virtio) versus full emulation changes I/O
  performance by orders of magnitude — **knowing which one is in use is a fact, not a curiosity**.
- **What the process thinks it knows**: CPU count, total memory and topology read from the host inside
  a limited container produce badly sized thread pools and heaps, and the result is
  self-throttling. **Every runtime that sizes resources automatically is configured
  explicitly in environments with limits.** It is one of the most common and most silent causes of
  latency in Kubernetes.

### 6.4 Durability: "I wrote it" does not mean "it is on disk"
A successful `write()` leaves the data in the **page cache**; the kernel will write it when it
sees fit. Only `fsync`/`fdatasync` (or `O_DIRECT` under the right conditions, or `O_SYNC`) ask for
persistence — and even then, **if the disk has a volatile cache and write barriers are
disabled, the data may still not be on stable media**. Every durability promise
depends on the whole chain: application → filesystem → block layer → controller →
disk. **One lying link invalidates the entire chain.**

**And `fsync` can lie in a specific and well-documented way.** The episode known as
*fsyncgate* (PostgreSQL, 2018) established the correct mental model: when the deferred write
fails, the kernel marks the error and **delivers it only once**; a second `fsync` on the same
descriptor **may return success even though the data never reached disk**, because the error was already
consumed and the pages were marked clean. Linux itself improved *writeback* error
reporting (the `errseq_t` infrastructure from 4.13 onwards and later refinements), but **the
design rule that came out of it is still the correct one and it is this skill's**:

> **A failed `fsync` is a fatal failure, not a retry.** The buffer cannot be rewritten
> —both the application's and the kernel's may already have been reused—; the only valid
> recovery is to abort and rebuild from the log (WAL) or from the copy.

That is exactly what PostgreSQL did: panic on a failed `fsync`, a change backported to
all supported branches. **Any of your own code that persists data and treats `fsync` as
retryable has the same latent flaw.** Corollary for systems design: **if the data
matters, durability is tested by yanking the machine's power** (a real or
device-level simulated power cut) and checking that the last acknowledged commit survives. A
durability promise without that test is an assumption.

### 6.5 I/O model
- **Blocking with one thread per connection** scales as far as the thread count scales; it is simple and
  correct, and it is still the right answer for moderate concurrency. It is not discarded out of
  fashion.
- **`epoll` in *level-triggered* mode** is the default for high concurrency: *edge-triggered* is
  faster on paper and **is a classic source of bugs from lost events** if the descriptor is not
  fully drained. `epoll` is almost always chosen through the language runtime, not by
  hand.
- **`O_DIRECT` bypasses the page cache**: useful when the application manages its own cache
  (databases), **counterproductive in almost everything else**, and with strict alignment
  requirements that are easily breached.
- **Deferred writing (*dirty writeback*) is a latency spike waiting for you**: accumulating
  gigabytes of dirty pages and flushing them all at once produces visible stalls. If the write
  profile is large and bursty, the dirty page thresholds **are a design parameter**, not
  an esoteric tweak.

## 7. Long-term sustainability and prohibitions

- **The kernel version is an architecture decision with a date.** A supported **LTS** branch
  is chosen, its EOL is known and the jump is planned **before** it arrives. A tuning validated on
  one version **is revalidated** on the jump: EEVDF (§2.1) is the demonstration that a scheduler
  change can move a service's latency profile without anybody touching the code.
- **Every `sysctl`, boot parameter, scheduling policy and cgroup limit lives as
  versioned code**, with the reason and the measurement that justified it. Without that, in a year nobody
  will know whether it can be removed — and it will never be removed.

Explicit prohibitions:
- ❌ **Touching the scheduler, memory `sysctl`s or I/O parameters without a before-and-after measurement**, and
  without varying a single parameter per experiment. FORBIDDEN: "tuning" copied from a blog.
- ❌ **Quoting `sched_latency_ns`, `sched_min_granularity_ns` or "CFS" as if they described the
  current scheduler.** It has been EEVDF since 6.6 (§2.1).
- ❌ **Giving real-time priority (`SCHED_FIFO`/`SCHED_RR`) to a process that can consume CPU without
  yielding.** It hangs the core. If it is done, with a bounded CPU budget and proof that it does not exhaust it.
- ❌ **Retrying a failed `fsync`** or assuming that a successful `write()` is durable (§6.4).
  FORBIDDEN, with no nuance.
- ❌ **Disabling swap "so there is no OOM"**: it brings the OOM forward instead of avoiding it.
- ❌ **Disabling the OOM killer globally** or setting `oom_score_adj` to the minimum in large services
  without having thought about whom you want the system to kill instead.
- ❌ **Setting `memory.max` without `memory.high` and without watching PSI**: it is choosing the autopsy over the
  warning (§6.2).
- ❌ **Deploying with CPU limits and not collecting the cgroup's throttling metric.** It is
  tail latency invisible by construction.
- ❌ **Letting a runtime size threads or heap by reading the host's topology inside a
  limited container.**
- ❌ **Treating the container as a security boundary against an attacker with code execution**
  when the threat model includes kernel flaws (§5.2).
- ❌ **Granting `CAP_SYS_ADMIN`** and calling that least privilege.
- ❌ **Enabling `io_uring` by default** without a written risk decision and without a measured gain (§5.3).
- ❌ **`transparent_hugepage=always` without measuring**, especially under databases.
- ❌ **Enabling `PREEMPT_RT` "just in case"**: it is paid for in aggregate throughput and it does not fix an
  application that allocates memory or touches disk on the critical path (§2.2).
- ❌ **Choosing a microkernel without being able to name the specific property needed and who requires it**
  (§2.3).
- ❌ **Measuring "memory used" by the process's virtual size.**
- ❌ **Extrapolating a measurement taken on a laptop, on another kernel version or on another hypervisor.**

## 8. Mandatory web verification

Authoritative sources: `kernel.org` and `docs.kernel.org`, the raw file from the tree
(`git.kernel.org/.../plain/...`, which avoids any summariser in between), `man7.org` for the user
interfaces, and `lwn.net` for a subsystem's context and history. Check before
committing to anything:

1. **The target system's kernel version** and **which LTS branches are still supported and until when**
   (`kernel.org/releases.json`). Everything else depends on this fact.
2. **The current scheduler and its parameters** in `Documentation/scheduler/` of that version, and the status
   of `sched_ext`. Verified as of Aug 2026: **EEVDF** since 6.6, `sched_ext` in mainline since 6.12.
3. **`PREEMPT_RT`**: support for your architecture (`ARCH_SUPPORTS_RT`) and the status of the options in
   `kernel/Kconfig.preempt` of that version.
4. **The exact semantics of the `cgroup v2` files** you are going to use in
   `Documentation/admin-guide/cgroup-v2.rst` **of your kernel**: the files and their behaviour are
   added to and refined between versions.
5. **Overcommit modes and OOM behaviour** in `Documentation/mm/` of your version.
6. **Security status of `io_uring`**: recent CVEs, whether your distribution ships it enabled, and whether
   your container runtime's default seccomp profile blocks it (as of Aug 2026, Docker and
   containerd block it in `RuntimeDefault`).
7. **The durability semantics of your specific filesystem** (ext4, XFS, Btrfs, ZFS, NFS) and of
   the block stack: *journal* mode, write barriers, and whether the device cache is
   volatile. **NFS and network filesystems have their own semantics** and the local ones are not assumed.
8. **The status of the projects cited in §2.3** if they are going to decide anything: latest release and real
   deployment of Fuchsia, the licences of seL4 and Redox read **from the repository's raw file**
   (seL4 lives on GitHub, **Redox at `gitlab.redox-os.org`**), and QNX's commercial terms.

**Declared gaps**: (a) **no figures are given here for the cost of a system call, of a context
switch or of the overhead of speculative mitigations**, because they depend on the microarchitecture,
on which mitigations are active and on the kernel: **they are measured on the target system**, and any
absolute number quoted from memory would be wrong. (b) The exact status of `io_uring` in ChromeOS and in
Android's SELinux policy as of today **could not be confirmed with a dated primary source**;
what is verified is the original restriction and its effect on the seccomp profiles of container
runtimes. (c) QNX's documentation and its certifications are behind commercial registration and **have
not been verified verbatim**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
