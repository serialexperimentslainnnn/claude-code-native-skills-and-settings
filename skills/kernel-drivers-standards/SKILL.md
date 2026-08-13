---
name: kernel-drivers-standards
description: Writing, reviewing and shipping code that runs inside an OS kernel, and deciding whether it should live there at all. Use when working on a Linux kernel module or driver (module_init/module_exit, MODULE_LICENSE, EXPORT_SYMBOL_GPL, struct file_operations, platform_driver, of_match_table and devicetree bindings, probe/remove, devm_* managed resources, misc/char/block/net/input subsystems, dma_alloc_coherent and DMA-API-HOWTO, request_irq and threaded IRQ handlers, spinlock_t vs mutex, might_sleep, in_atomic, RCU with rcu_read_lock and synchronize_rcu, copy_from_user/copy_to_user, an out-of-tree kmod or DKMS package), submitting patches upstream (scripts/checkpatch.pl, scripts/get_maintainer.pl, MAINTAINERS, git send-email, b4, Signed-off-by and the Developer Certificate of Origin, a linux-*@vger.kernel.org list, staging), kernel debugging and hardening (dmesg oops and taint flags, ftrace and trace_printk, kgdb/kdb, KASAN, UBSAN, KCSAN, KFENCE, lockdep, sparse, smatch, Coccinelle, KUnit, syzkaller), Rust in the kernel (rust/kernel crate, rustavailable, CONFIG_RUST, Rust MSRV), module signing under Secure Boot and kernel lockdown, or choosing a userspace alternative instead (FUSE, uio, vfio-pci, iommufd, spidev, i2c-dev, libusb, SPDK/DPDK) — and Windows KMDF/WDM/UMDF drivers with Partner Center attestation or WHQL signing, or macOS kexts versus DriverKit and System Extensions.
---

# Standards for development inside the kernel

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **writing code that runs in supervisor mode**: Linux kernel drivers and modules, their
relationship with upstream development, the kernel's concurrency and memory model, its debugging
and its signing; and, to a lesser extent but with its own criteria, Windows and macOS drivers. It
applies **before** the first line is written: the most valuable decision in this skill is
**deciding that a kernel driver is not needed**.

Triggers: `module_init`/`module_exit`, `MODULE_LICENSE`, `EXPORT_SYMBOL`/`EXPORT_SYMBOL_GPL`,
`struct file_operations`, `platform_driver`, `probe`/`remove`, `of_match_table`, devicetree
*bindings* in `Documentation/devicetree/bindings/`, `devm_kzalloc` and the `devm_*` family,
`misc_register`, `cdev_add`, `alloc_netdev`, `blk_mq`, `input_register_device`,
`dma_alloc_coherent`, `dma_map_single`, `request_irq`/`request_threaded_irq`, `spinlock_t`,
`mutex_lock`, `might_sleep`, `in_atomic`, `rcu_read_lock`, `synchronize_rcu`,
`copy_from_user`/`copy_to_user`, `container_of`, `ERR_PTR`,
`printk`/`pr_err`/`dev_err`, `Kbuild`/`Makefile` with `obj-m`, DKMS, `insmod`/`modprobe`/`modinfo`,
`scripts/checkpatch.pl`, `scripts/get_maintainer.pl`, `MAINTAINERS`, `git send-email`, `b4`,
`Signed-off-by`, `vger.kernel.org`, `drivers/staging/`, `dmesg`, "Oops", "kernel panic",
"tainted kernel", `ftrace`, `kgdb`, `KASAN`, `UBSAN`, `KCSAN`, `KFENCE`, `lockdep`, `sparse`,
`smatch`, `coccinelle`, `KUnit`, `syzkaller`, `CONFIG_RUST`, `make rustavailable`, `rust/kernel`,
`CONFIG_MODULE_SIG_FORCE`, `sign-file`, *lockdown*, MOK/`mokutil`, KMDF/WDM/UMDF, `.inf`, WDK,
Partner Center, WHQL, `kext`, DriverKit, System Extensions.

**Governing principle**: **inside the kernel there is no safety net.** There is no process to
kill, no `SIGSEGV` to contain, no service restart: a badly dereferenced pointer is the whole
system, and a fault deployed at scale is a global incident (§2.4). Hence the two house rules:
**(1) code that can live in userspace, lives in userspace**; **(2) code that does belong in the
kernel, goes upstream** — everything else is debt paid on every version, forever.

**Strictly defensive posture.** This skill treats module signing, *lockdown*, vulnerable drivers
and kernel persistence mechanisms **as risks to mitigate**. It contains and will contain no BYOVD,
rootkit or evasion recipes (§7).

**Not applicable**: see `operating-systems-standards` (**direct sister, declared boundary**: the
operating system **concepts** and their engineering consequences — scheduling and latency, system
call cost, paging and TLB, OOM killer, `cgroup v2`, `fsync` semantics, `epoll` versus `io_uring`,
namespaces, NUMA, microkernel versus monolithic, hard versus soft real time — are **theirs**;
**here the code written inside the kernel and its process**. Arbitration rule: *"why does the
system behave like this?" is theirs; "how do I write, debug and submit this driver?" belongs
here*), `linux-administration-standards` (operating the host: systemd units, `journalctl`,
diagnosing a server — **loading a module to operate** is theirs; **writing it** belongs here),
`linux-hardening-standards` (system baseline, Secure Boot as a baseline control, `sysctl`, auditd —
**here module signing from the producer's side**),
`selinux-standards` (MAC and its policy), `container-runtime-security-standards` (**security eBPF
and the runtime agent are theirs**: Falco, Tetragon, Tracee, eBPF agent privileges — here only why
eBPF is the correct alternative to a module for observing the system),
`c-standards` (**the C is theirs**: `-std=`, UB, MISRA/CERT, userspace sanitizers, binary
hardening — **mandatory nuance**: the kernel is **not** compiled against libc, does not use
`malloc`, has its own style and its own sanitizers; **when a `c-standards` rule clashes with the
kernel, the kernel wins**), `rust-standards` (**Rust and its toolchain are theirs**; here only the
status and the constraints of Rust *inside* the kernel), `assembly-standards` (assembly and its
justification), `embedded-iot-standards` (**sister**: the physical device, boot, the device tree as
a description of the product's hardware and field updates — **here the code of the driver that
device tree binds**), `gpu-computing-standards` (CUDA/HIP and the GPU toolchain; the GPU kernel
driver belongs here), `performance-engineering-standards` (profiling and measurement methodology;
**`perf` and `ftrace` as a diagnostic tool for a driver belong here**), `appsec-standards` and
`vulnerability-management-standards` (application threat modelling, CVSS/EPSS/KEV triage),
`incident-response-forensics-standards` (forensic analysis of a system with a hostile module),
`offensive-security-standards` (exploitation, with scope and authorisation — **it is not here**),
`windows-server-ad-standards` and `macos-fleet-standards` (administration of those platforms; here
only driver development), `opensource-licensing-standards` (licence analysis as a programme; here
`MODULE_LICENSE` and the GPL-only symbol as a technical fact), `git-workflow-standards`
(**does not apply to the kernel**: the kernel uses email, `Signed-off-by`/DCO and `b4`, not *pull
requests*).

## 2. Default decisions

> Verify versions, status and dates on the web before fixing anything (§8). Status **verified** as
> of August 2026 against `kernel.org` and Torvalds' tree — **the Linux kernel does not live on
> GitHub**.

### 2.1 First things first: do you really need a kernel driver?

**The default answer is "no".** Before writing a module this list is exhausted, in order:

| Userspace alternative | What for | Real cost |
|---|---|---|
| **`spidev` / `i2c-dev`** (`/dev/spidev*`, `I2C_SLAVE` ioctl) | Any low-speed SPI or I²C peripheral | None: the bus is exposed as a *char device*, driven from C or from a script |
| **`libusb`** | Proprietary USB device, firmware updaters, instrumentation | Somewhat worse latency and throughput; in exchange, zero kernel code |
| **`uio`** | Memory-mapped registers and a simple interrupt, typical on FPGAs | **No IOMMU**: the device can write anywhere by DMA. Acceptable only with no DMA or with total trust in the hardware |
| **`vfio-pci` / `iommufd`** | Userspace driver with DMA **and IOMMU protection**, the basis of DPDK/SPDK and of passthrough to a VM | More complex (ioctls, binding), but it is **the only safe way** to do DMA from userspace |
| **FUSE** | A filesystem | Context switch cost; irrelevant in most cases and decisive in a few |
| **eBPF** | Observing, filtering or extending kernel behaviour without your own code in it | The verifier, the program limits, and an API that actually is stable |
| **`gpiod`, `iio`, `hidraw`, `sg`/`bsg`, `serial`** | A subsystem already exposing the data exists | Zero: **first check whether the subsystem already does it** |

**When you do have to be in the kernel**: microsecond interrupt latency; DMA that requires
configuring hardware and managing kernel buffers; participation in a subsystem (a network card
**is** a `net_device`, a disk **is** a `blk_mq`); the need for primitives that do not exist outside
(spinlocks, RCU, atomic contexts); or that the userspace process could be killed or suspended and
that being unacceptable. A userspace process **can be killed; a kernel module cannot** — that
asymmetry is the valid argument, and also the reason a fault costs so much.

### 2.2 Upstream or out-of-tree — it is not a preference, it is arithmetic

**The kernel's internal API is not stable, and it is not stable by design.** It is not an oversight
or a broken promise: it is explicit policy, documented in
`Documentation/process/stable-api-nonsense.rst`. Verbatim:

> *"This is being written to try to explain why Linux **does not have a binary kernel interface, nor
> does it have a stable kernel interface**."*

And its critical distinction, which is constantly confused:

> *"Please realize that this article describes the **in kernel** interfaces, not the kernel to
> userspace interfaces. The kernel to userspace interface is the one that application programs use,
> the syscall interface. That interface is **very** stable over time, and will not break."*

That is: **the ABI towards userspace is sacred** (breaking it is a `git revert`), and the
*internal* API changes when convenient. Hence the same document's conclusion about what to do with
an out-of-tree driver:

> *"Simple, get your kernel driver into the main kernel tree … If your driver is in the tree, and a
> kernel interface changes, it will be fixed up by the person who did the kernel change in the first
> place."*

**What it costs to submit it** (and it must be said in full, because the cost is real): writing in
the kernel's style, passing `checkpatch.pl`, documenting the devicetree *bindings* in their YAML
schema, finding the *maintainer* with `get_maintainer.pl`, sending by plain-text email, and
**enduring several rounds of public review that will be blunt**. Weeks or months. **What it costs
not to submit it**: porting the driver to every kernel version, forever, for every distribution and
every vendor branch; packaging it with DKMS and having it break on every kernel update at the
customer's site; being left out of any refactor that takes away the API you use; and not being able
to use `EXPORT_SYMBOL_GPL` symbols if the module is not GPL (§5.3). **It is permanent debt with
compound interest.**

`drivers/staging/` exists as an intermediate route for code that does not yet meet the bar, with
its own rules and with the explicit expectation that it either gets out of there or is deleted.
**It is not an indefinite car park**, and a driver in staging is maintained by nobody but its
author.

### 2.3 Versions and toolchain — verified at `kernel.org`

| Datum | Verified value (2026-08-05, `kernel.org/releases.json`) |
|---|---|
| mainline | **7.2-rc6** |
| stable | **7.1.6** |
| longterm | **6.18.42**, **6.12.101**, **6.6.148**, **6.1.180**, **5.15.213**, **5.10.262** |
| Minimum GCC | **8.1** (`Documentation/process/changes.rst`) |
| Minimum Clang/LLVM (optional) | **17.0.1** |
| Minimum binutils | **2.30** |
| Minimum Rust (optional) | **1.85.0** |
| Minimum bindgen (optional) | **0.71.1** |

**What you develop against**: new work is done against **mainline or `linux-next`**, not against
the distribution's kernel. A patch that only applies on top of a vendor's tree is not submittable
and will not be reviewed.

### 2.4 Rust in the kernel — real status, not folklore

It is the topic in the catalogue with the most misinformation in both directions ("everything is
already in Rust" / "it is an experiment that does not compile"). **Verified** status as of August
2026:

- **It is first-class but optional support**: `Documentation/process/changes.rst` lists Rust as
  *"(optional)"* with a minimum of **1.85.0**, and `bindgen` as *"(optional)"* with a minimum of
  0.71.1. Without `CONFIG_RUST`, the kernel compiles exactly as it always did. `make rustavailable`
  says why the toolchain is not available.
- **Minimum version policy**: since early 2026 the project **follows Debian Stable's Rust version**
  as the minimum supported one (Debian 13 *Trixie* → 1.85.0), in force since Linux v7.1. The LTS
  branches keep their own minimum (6.18.y is still on 1.78.0): **do not assume mainline's minimum
  when porting to an LTS**.
- **Supported architectures**, verbatim from `Documentation/rust/arch-support.rst`, all at level
  *Maintained*: `arm` (*"ARMv7 Little Endian only"*), `arm64` (*"Little Endian only"*), `loongarch`,
  `riscv` (*"riscv64 and LLVM/Clang only"*), `s390` (*"CONFIG_EXPOLINE must be disabled"*), `um`, and
  `x86` (*"x86_64 only"*). **It is not universal**: if the target is not in that table, there is no
  debate.
- **There are real drivers**: Binder in Rust was merged in 6.18, together with Tyr (Mali CSF GPU).
  The USB *bindings* are present but **disabled in the build** until a real driver arrives that
  uses them.
- **It still relies on unstable language features** inside the `kernel` *crate*; outside it (in
  drivers) only a minimal set is allowed. That is the open work.

**This skill's criterion**: for a new driver, on a supported architecture, in a subsystem where
Rust abstractions already exist, **Rust is a defensible choice and the contrary has to be
justified**. Outside those conditions, **C remains the kernel's default** — and that statement has
an expiry date: it is re-verified (§8), not inherited.

### 2.5 Windows and macOS

**Windows.** Default framework: **KMDF** (Kernel-Mode Driver Framework) for what must be in the
kernel, **UMDF** for what can be in userspace — and that is the first decision, just as in Linux.
**Raw WDM only when KMDF does not cover the case**, and with a written justification. Signing:
**since Windows 10 1607 a kernel driver only loads if Microsoft has signed it**; the vendor's EV
certificate signs the CAB uploaded to Partner Center, and Microsoft returns the signed binary
(*attestation signing*, or **WHQL** with HLK tests if you want distribution through Windows Update
and Windows Server coverage). ***Cross-signing* is dead**: withdrawn since 2021, with the
certificates expired, and the April 2026 update removed default trust in *cross-signed* drivers on
Windows 11 24H2/25H2/26H1 and Windows Server 2025 — **any old driver depending on it has to be
resubmitted**. Verify the exact status before planning (§8).

**The CrowdStrike precedent (July 2024) is this skill's argument, not an anecdote.** A security
vendor with a **WHQL-signed** kernel driver distributed a content file — not the driver — that the
driver consumed badly, and the result was a blue screen loop on millions of machines, with manual
recovery per machine. The three lessons are design lessons and apply to any driver: **(1)** the
blast radius of a kernel fault is the whole machine and no degradation is possible; **(2)** the
**data** the driver consumes is failure surface with the same weight as the code, and it has to be
validated with the same paranoia; **(3)** deploying anything that reaches the kernel demands a
**canary and phased rollout**, with no exception for urgency. The structural consequence is that
Microsoft is moving endpoint security **out of the kernel** (Windows Endpoint Security Platform,
within the Windows Resiliency Initiative) — the same movement that in Linux already happened when
agents moved from their own module to **eBPF**.

**macOS.** **Kexts have been deprecated since WWDC19**; since Big Sur macOS does not load by
default kexts that use deprecated KPIs, and the alternative is **DriverKit** (USB, serial, network,
HID) and **System Extensions** (Network Extension, Endpoint Security) — which **run in userspace**.
Verified as of 2026: **Apple has announced no full removal date** and kexts still load on current
versions, with user approval and reduced security on Apple Silicon. Criterion: **nothing new in a
kext**; DriverKit/System Extensions and request the corresponding *entitlement* from Apple
**before** committing the design, because it is not automatic.

## 3. Structure and conventions (Linux)

- **Style**: `Documentation/process/coding-style.rst` is the norm and is not up for debate — 8-wide
  tabs, kernel braces, lines per the tree's current limit. `clang-format` with the `.clang-format`
  **from the tree itself**, never the one from an outside project.
- **`scripts/checkpatch.pl` before submitting anything.** Its own documentation sets out how it is
  read, verbatim from `Documentation/process/submitting-patches.rst`: *"the style checker should be
  viewed as a guide, not as a replacement for human judgment"*, with three levels — *"ERROR: things
  that are very likely to be wrong / WARNING: things requiring careful review / CHECK: things
  requiring thought"* — and the rule that matters: *"You should be able to justify all violations
  that remain in your patch."* A clean `checkpatch` does not guarantee the patch is good; a dirty
  one guarantees it will not be read.
- **Recipients**: `scripts/get_maintainer.pl` on the patch itself. Verbatim from the same document:
  *"If you cannot find a maintainer for the subsystem you are working on, Andrew Morton
  (akpm@linux-foundation.org) serves as a maintainer of last resort"* and
  *"linux-kernel@vger.kernel.org should be used by default for all patches"* — with the explicit
  warning **not** to send to unrelated lists or people.
- **Submission by email, in plain text**, an ordered series, one logical change per patch, a message
  that explains **the why** (the what is already in the diff). `Signed-off-by:` is the **DCO**, not
  a formality: it is a legal statement about the provenance of the code. **`b4` is the recommended
  tool** for managing series, dependencies and submission; the document itself cites it as helping
  *"with things like tracking dependencies, running checkpatch and with formatting and sending
  mails"*.
- **Choose the right layer**: you do not write your own *char device* when a subsystem exists. A
  sensor is **IIO**; a button, **input**; a network card, **netdev**; a storage device, **blk-mq**;
  a regulator, **regulator**. A driver that invents its own `ioctl` for what a subsystem already
  exposes will be rejected upstream — and rightly so: it breaks every existing tool.
- **`ioctl` as a last resort, and when it is, with a bulletproof contract**: fixed and explicit-size
  structures, padding fields zeroed and verified, no embedded pointers if avoidable, 32/64-bit
  compatibility thought through from day one. **It is ABI towards userspace: once published, it is
  never changed.**
- **Devicetree**: the *bindings* are documented in a YAML schema in
  `Documentation/devicetree/bindings/` and validated with `make dt_binding_check`. The binding is a
  **contract with the firmware of thousands of boards** and is also ABI: it does not get broken.
- **Managed resources** (`devm_kzalloc`, `devm_request_irq`, `devm_ioremap_resource`) by default:
  they eliminate the entire class of leaks on the error path of `probe()`. When they cannot be used,
  the error path is written with labels in reverse order of acquisition, and is reviewed in full.

## 4. Quality and testing

In order of increasing cost. The first four are **gates**: if they do not pass, the patch does not
go out.

1. **Clean `checkpatch.pl`** (with the remaining violations justified) and compilation **with no
   new warnings** using `make W=1`.
2. **`sparse`** (`make C=1`): checks the address space annotations (`__user`, `__iomem`, `__rcu`)
   and endianness. **It is the tool that catches the most expensive and most silent kernel error:
   dereferencing a user pointer directly.**
3. **`smatch` and `coccinelle`** (`make coccicheck`): leaks on error paths, missing null checks,
   patterns already banned in the tree.
4. **Building the module against several versions** if — against the criterion of §2.2 — it lives
   out of tree: mainline, `linux-next` and every supported LTS. It is the price of not submitting.
5. **Sanitizers, on a development kernel, running the real workload**: `KASAN` (use-after-free and
   overflows; it is **the** typical driver finding), `UBSAN`, `KCSAN` (*data races*),
   `KFENCE` (low cost, suitable even in production on a large fleet), and **`lockdep`
   (`CONFIG_PROVE_LOCKING`) always enabled in development**: it detects incorrect lock ordering
   *before* it produces the deadlock, not after. `CONFIG_DEBUG_ATOMIC_SLEEP` to catch `might_sleep`
   in atomic context.
6. **KUnit** for the pure logic that can be isolated (parsing, computation, state machines). Not all
   of a driver is testable that way — but the part that decides **is**, and that is usually where
   the faults are.
7. **`syzkaller`** against any interface exposed to userspace (`ioctl`, `read`/`write`, `netlink`,
   sysfs). If the driver accepts user input and has never seen a *fuzzer*, it is not tested: it is
   unused.
8. **A real error-path test**: allocation failure, `probe` failing halfway, `remove` with the device
   in use, hot disconnection during a transfer, `rmmod` with an open file. **A driver's error paths
   are where most of its bugs live**, because they are the ones nobody executes.

**Debugging**: `dmesg` and the **taint flags** first (they say whether there is a proprietary
module, whether the kernel had already failed before, whether a load was forced);
`ftrace`/`trace_printk` for flow and latency without stopping the system; `dynamic_debug`
(`pr_debug` enabled at runtime) instead of leaving bare `printk`; `kgdb`/`kdb` for the case that
demands it; `crash`/`kdump` on the dump when the failure does not reproduce. **`printk` on a hot
path alters the problem itself** — it serialises, synchronises and changes the *timing* —: the same
argument as `printf` over UART in firmware.

## 5. Stack security

### 5.1 The boundary with userspace is a trust boundary
- **Every datum crossing from userspace is hostile.** `copy_from_user`/`copy_to_user` **always**
  with the return value checked; never dereference a user pointer. Validate lengths **before**
  using them, with arithmetic that does not overflow, and check for `TOCTOU`: a value copied twice
  may have changed between the two reads.
- **Kernel memory is never leaked to userspace**: structures to be copied fully zero-initialised
  (the *padding* too), with no kernel pointers or addresses in outputs or in logs (`%p` is obscured
  by default and that obscuring is not turned off "for debugging" in production).
- **Everything exposed is ABI forever**: every `ioctl`, every sysfs file and every debugfs attribute
  published will have to be sustained. Experimental things go to `debugfs` and are said to be
  experimental; stable things go where they belong and are documented in `Documentation/ABI/`.

### 5.2 Module signing, Secure Boot and *lockdown*
- The kernel signs modules with X.509 certificates and verifies them at load time. Verbatim from
  `Documentation/admin-guide/module-signing.rst`: *"Module signing increases security by making it
  harder to load a malicious module into the kernel. The module signature checking is done by the
  kernel so that it is not necessary to have trusted userspace bits."* Algorithms supported by the
  built-in facility, verbatim: *"the built-in facility currently only supports the RSA, NIST P-384
  ECDSA and NIST FIPS-204 ML-DSA public key signing standards"* — **there is already post-quantum
  signing in the tree; check the real support in the branch you use**.
- **`CONFIG_MODULE_SIG_FORCE`** (or `module.sig_enforce=1`) is what turns the signature into a
  control: without it, an unsigned module loads and merely *taints* the kernel. With Secure Boot
  active, the distribution also enables **lockdown**, which restricts the routes through which
  userspace can write into the kernel (`/dev/mem`, unsigned `kexec`, dangerous parameters).
- **The private signing key does not live on the system that boots.** Sign in an HSM or a signing
  service; for development, your own MOK enrolled with `mokutil` **only on lab machines** and never
  the same key as in production.

### 5.3 Licence: `MODULE_LICENSE` and the GPL-only symbol
`MODULE_LICENSE` is **not decorative metadata**: it determines whether the module can link against
symbols exported with `EXPORT_SYMBOL_GPL`. Verbatim from `include/linux/module.h`, on the purpose
of the string: *"The sole purpose is to make the 'Proprietary' flagging work and to refuse to bind
symbols which are exported with EXPORT_SYMBOL_GPL when a non free module is loaded."* And the same
comment clarifies the limits of what the tag means: *"the 'only/or later' distinction is completely
irrelevant and does neither replace the proper license identifiers in the corresponding source file
nor amends them in any way"* — that is, **the real licence is in the source file, not in the
macro**. Its three declared reasons, verbatim: *"1. So modinfo can show license info for users
wanting to vet their setup is free / 2. So the community can ignore bug reports including
proprietary modules / 3. So vendors can do likewise based on their own policies"*.

Practical consequences: a proprietary module **taints** the kernel, **cannot** use most of the
modern API (which is exported as GPL-only), **nobody is going to look at your bug report**, and any
GPL *shim* wrapping a proprietary blob to dodge the check is a legal problem, not a technical
trick. **Consult a lawyer, not Stack Overflow** — Greg KH's own document explicitly refuses to
address the legal side.

### 5.4 Vulnerable drivers as a risk (BYOVD), treated as defence
A signed driver with an exploitable flaw is a key to the kernel that **the attacker does not have
to manufacture: they bring it with them**. This skill treats it exclusively from two sides:

- **As an author**: your signed driver is attack infrastructure if it exposes generic primitives.
  **FORBIDDEN** to expose via `ioctl` arbitrary physical memory read/write, MSR access, I/O port
  access or mapping of arbitrary ranges "for a diagnostic tool" — it is the exact pattern of the
  drivers that end up on the block lists. Every privileged `ioctl` requires a capability check
  (`capable()`/`ns_capable()`) **and** a closed range of operations.
- **As a defender**: on Windows, **Microsoft's vulnerable driver blocklist** is enabled by default
  and is reinforced with **HVCI**, Smart App Control or S mode; the blocks appear in the event
  viewer (IDs 3023 and 3033). Microsoft explicitly warns that it **does not guarantee blocking every
  weak driver** for compatibility balance, and there is at least one documented gap
  (CVE-2025-59033) on systems **without HVCI**. Operational conclusion: **the blocklist does not
  replace application control with an allowlist**, and disabling it — which requires disabling HVCI
  first — is a risk decision that gets documented. On Linux, the equivalent is
  `CONFIG_MODULE_SIG_FORCE` + lockdown + not loading third-party modules with unverified
  provenance.

**FORBIDDEN in this document**: BYOVD procedures, lists of exploitable drivers with their
primitive, kernel hiding techniques, or any rootkit variant. The posture is defensive; offensive
work requires scope and authorisation and belongs to `offensive-security-standards`.

## 6. Concurrency, memory and operability

- **Knowing which context each function runs in is a requirement, not a detail.** Process context
  (can sleep) versus atomic context — ISR, with a spinlock held, RCU read side — where **sleeping is
  a fault**: no `mutex_lock`, no `kmalloc(GFP_KERNEL)`, no `copy_from_user`, no `msleep`. The
  expected context of each function is documented, and `might_sleep()` +
  `CONFIG_DEBUG_ATOMIC_SLEEP` check it at runtime.
- **Choice of primitive**: `mutex` by default in process context; `spinlock` only when sharing with
  an ISR or when the section is nanoseconds long (and then the critical section **must** be tiny);
  `spin_lock_irqsave` when the data is touched from an interrupt; **RCU** when reads overwhelmingly
  dominate and writes are rare — with the discipline it imposes (the reader cannot sleep in the
  classic section, the writer publishes with barriers and frees with `call_rcu`).
  **A lock order documented in writing** and `lockdep` enabled, always.
- **Interrupts**: the *top half* does the minimum and dispatches; the work goes to a *threaded IRQ*
  (`request_threaded_irq`), a *workqueue* or a *tasklet* depending on the latency required. A long
  ISR is latency for the whole system, not just for your device.
- **Memory**: `GFP_KERNEL` only where sleeping is possible, `GFP_ATOMIC` is a scarce resource that
  runs out and has to be justified; no large contiguous allocations if `vmalloc` or a scatter list
  will do; the kernel stack is **small and fixed** — no large arrays on the stack, no VLAs, no
  recursion.
- **DMA**: the **DMA API** is used (`dma_alloc_coherent`, `dma_map_single`/`dma_map_sg`), never
  physical addresses by hand; the device's masks are respected (`dma_set_mask_and_coherent`) as is
  buffer ownership (while it is mapped to the device, **the CPU does not touch it**). With an IOMMU
  and in a VM, this is not theory: it is the difference between working and corrupting somebody
  else's memory.
- **The unload path (`remove`/`rmmod`)**: it is the least tested and the one that breaks most.
  Everything registered is deregistered in reverse order, timers and *workqueues* are cancelled and
  waited on, and no live reference remains. An `rmmod` that causes a *use-after-free* is the classic
  bug.
- **Logging with judgement**: `dev_err`/`dev_warn`/`dev_info` (which identify the device) rather
  than `pr_*`; **no per-operation logs on a hot path** — they flood the journal and are a DoS vector
  from userspace —; `dev_err_ratelimited` for anything that can repeat.

## 7. Long-term sustainability and prohibitions

- **Cadence**: if the code is upstream, it follows the tree and the community absorbs the
  maintenance work. If it is out of tree, the project takes on an explicit commitment: **testing
  against every new LTS and against `linux-next`**, with an assigned budget. An out-of-tree module
  with nobody assigned to port it is not a product: it is an unwritten expiry date.
- **Backports**: fix patches go first to mainline and from there to stable; **never the other way
  round**. A fix that only exists in the vendor's branch disappears in the next version.

Explicit prohibitions:
- ❌ **Writing a kernel driver without having ruled out the alternatives in §2.1 in writing.**
- ❌ **Dereferencing a userspace pointer** or using a size coming from userspace without validating
  it. FORBIDDEN, with no nuance.
- ❌ **Sleeping in atomic context** (`mutex`, `GFP_KERNEL`, `copy_*_user`, `msleep` with a spinlock
  held or inside an ISR).
- ❌ **Ignoring the return value** of `copy_from_user`, `kmalloc`, `register_*` or any function that
  can fail. In the kernel there are no exceptions to catch the oversight.
- ❌ **An `ioctl` that exposes physical memory read/write, MSRs or arbitrary ports.** It is
  manufacturing a BYOVD signed with your name (§5.4).
- ❌ **Exposing new ABI without thinking of it as permanent**, and **FORBIDDEN to break already
  published user ABI**: it is the only truly inviolable rule of the kernel.
- ❌ **`MODULE_LICENSE("GPL")` on a module that is not**, or any GPL *shim* wrapping a blob to
  access `EXPORT_SYMBOL_GPL` symbols.
- ❌ **Disabling signature checking or lockdown in production** to load a module. If it is needed,
  the module gets signed; the control is not lowered.
- ❌ **Deploying to the fleet without a canary and without phases** any module, driver or **data
  file the driver consumes**. The July 2024 lesson (§2.5) is exactly this.
- ❌ **`printk` without rate limiting on a hot path** or dependent on user input.
- ❌ **Recursion, VLAs or large arrays on the kernel stack.**
- ❌ **Patching the distribution's tree instead of submitting upstream** when the change is of
  general interest: it guarantees having to redo it on every update.
- ❌ **A new kext on macOS** when DriverKit or a System Extension covers the case.
- ❌ **FORBIDDEN in this skill**: BYOVD recipes, rootkit techniques, module hiding, EDR evasion or
  abuse of third-party vulnerable drivers. Mitigation only.

## 8. Mandatory web verification

**The Linux kernel does not live on GitHub.** The authoritative sources are `kernel.org`,
`git.kernel.org` (in **plain** format, `.../plain/...`, to read the file with no summariser in
between), `docs.kernel.org`, `lore.kernel.org` for the lists and `lwn.net` for context. Check
before fixing anything:

1. **Current versions** in `kernel.org/releases.json`: mainline, stable and **which LTS branches
   are still supported and until when** — the longterm EOL calendar changes and decides what you
   backport to.
2. **Toolchain minimums** in `Documentation/process/changes.rst` of the specific tree: GCC, Clang,
   binutils, Rust, bindgen. They differ between mainline and each LTS.
3. **Status of Rust in the kernel**: `Documentation/rust/arch-support.rst` (the architecture table
   changes), the minimum version policy at `rust-for-linux.com/rust-version-policy`, and which
   subsystems have usable abstractions. **It is the datum in this document that ages worst.**
4. **The process documents quoted verbatim here** (`stable-api-nonsense.rst`,
   `submitting-patches.rst`, `coding-style.rst`, `module-signing.rst`, `include/linux/module.h`):
   read them from the tree you are working against, because the text gets edited.
5. **The specific subsystem**: `MAINTAINERS`, the corresponding list on `lore.kernel.org`, whether
   there is a refactor in flight (`linux-next`) that changes the API you are going to use, and
   whether a driver for that hardware already exists.
6. **Windows**: the status of *attestation signing* versus WHQL on `learn.microsoft.com`, the status
   of withdrawn *cross-signing*, the current version of the vulnerable driver blocklist, and the
   status (preview or general availability) of the out-of-kernel endpoint security platform.
7. **macOS**: whether Apple has announced a kext removal date yet, which KPIs have been removed in
   the target version and which DriverKit/Endpoint Security *entitlements* still require approval.
8. **CVEs of the subsystem** you are working in and whether the target LTS branch receives the
   patch.

**Declared gaps**: (a) the general availability status of Windows' out-of-kernel endpoint security
platform **could not be confirmed with a primary source dated 2026**; it is documented as an
announced initiative, not as an accomplished fact. (b) The definitive removal date of macOS kexts
**does not exist**: Apple has not announced it, and any document giving one is inventing it. (c) No
latency, *throughput* or overhead figures for the alternatives in §2.1 are given here because **they
depend on the hardware and the workload**: they are measured on the target system.

If the web contradicts this document, **the web wins** — flag the discrepancy.
