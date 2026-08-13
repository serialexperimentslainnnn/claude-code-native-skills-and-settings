---
name: embedded-iot-standards
description: Engineering a physical connected device — microcontroller or embedded Linux — from silicon choice to field update and its EU regulatory deadline. Use when working with prj.conf, west.yml, Kconfig fragments, boards/*_defconfig, devicetree .dts/.dtsi/.overlay files, FreeRTOSConfig.h, a Zephyr/FreeRTOS/NuttX/Eclipse ThreadX application, a superloop versus RTOS decision, NuttX Kconfig, Yocto bitbake recipes (.bb/.bbappend, local.conf, bblayers.conf, meta- layers, kas), Buildroot (make menuconfig, BR2_ options, br2-external, defconfig), a cross toolchain sysroot or arm-none-eabi-gcc, a linker script .ld with FLASH/RAM regions and .bss/.noinit sections, newlib-nano or picolibc, U-Boot bootcmd/bootargs and boot_targets, MCUboot slot0/slot1 and imgtool sign, A/B or dual-bank firmware slots with rollback counters, RAUC or SWUpdate or Mender or Eclipse hawkBit OTA campaigns, watchdog kick and reset-cause registers, low-power modes and coulomb-counter energy budgets, JTAG/SWD debugging with OpenOCD, probe-rs, J-Link or a reset-cause register, semihosting or printf-over-UART cost, static allocation and no-malloc firmware, a secure element or TPM or ARM TrustZone-M key store, per-device identity and provisioning, PSA Certified, ETSI EN 303 645, the EU Cyber Resilience Act (Regulation (EU) 2024/2847), or RED Delegated Regulation (EU) 2022/30 and EN 18031.
---

# Embedded systems and IoT device standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **building a physical product that runs your own software and, almost always, connects**:
choosing the silicon (MCU versus MPU), deciding whether an RTOS is needed or a superloop is enough,
setting up the cross toolchain and making the build reproducible, booting (bootloader, device tree),
**being able to update it in the field without a failure turning it into a brick**, watching over it
(watchdog), measuring its consumption, debugging it without an open port in production, managing
memory without a *heap*, and complying with the European regulatory framework that **already has
dates on the calendar**.

Triggers: `prj.conf`, `west.yml`/`west build`, `Kconfig` and `*.conf` fragments, `boards/*_defconfig`,
`.dts`/`.dtsi`/`.overlay`/`dtc`, `FreeRTOSConfig.h`, `configTOTAL_HEAP_SIZE`, `xTaskCreateStatic`,
`nuttx/.config`, Eclipse ThreadX / `tx_thread_create`, `arm-none-eabi-gcc`, `--specs=nano.specs`,
picolibc, an `.ld` with `MEMORY { FLASH ... RAM ... }`, `.noinit`, `bitbake`, `local.conf`,
`bblayers.conf`, `meta-*`, `kas`, `BR2_*`, `br2-external`, `u-boot.env`, `bootcmd`, `bootargs`,
`fw_setenv`, MCUboot, `imgtool sign`, slot0/slot1, `RAUC`, `SWUpdate`, `Mender`, `hawkBit`,
`swupdate.cfg`, RAUC's `system.conf`, `IWDG`/`WWDG`/`wdt_feed`, `PWR_CR`, "*stop* mode",
"energy budget", OpenOCD, `probe-rs`, J-Link, SWD, JTAG, semihosting, ATECC608, SE050,
on-device TPM 2.0, TrustZone-M / `CMSE`, PSA Certified, ETSI EN 303 645, EN 18031, RED,
Cyber Resilience Act, "per-device key", "it does not boot after the update".

**Governing principle**: **a device with no tested remote update path is a liability, not a
product.** Everything else in this skill — boot, partitioning, watchdog, identity, energy — exists so
that update is possible during the ten or fifteen years the thing is going to be plugged in. The
second house rule: **firmware cannot ask for help**. There is no operator, no `ssh`, no manual
restart — if the design assumes somebody will go and touch it, the design is wrong.

**Not applicable**: see `ot-ics-security-standards` (**industry and process are theirs, without
exception**: PLC, RTU, DCS, SCADA, SIS, the Purdue/ISA-95 model, IEC 62443 zones and conduits, field
protocols — Modbus, DNP3, PROFINET, IEC 60870-5-104, OPC UA —, passive monitoring and the shutdown
window. **Operational boundary: if the thing *acts on an industrial physical process* and its failure
is a human-safety problem, it is theirs; if it is a connected consumer, building, retail, metering or
logistics product, it is ours.** A controller that falls on both sides is designed under this skill
and **governed under theirs**), `edge-computing-standards` (**direct sibling**: **theirs is the node
with full Linux, compute pushed to the edge, the fleet as a distributed system, synchronisation and
remote orchestration**; **here the device as a physical object**: silicon, boot, memory, energy,
peripherals, the firmware image and its update. Arbitration rule: *"what runs at the edge and how is
the fleet coordinated?" is theirs; "what image boots on that board, how is it signed and how is it
replaced without bricking it?" is ours*. **Mirrored cut of the A/B updater**: MCUboot, RAUC,
SWUpdate, Mender and hawkBit — firmware image, slots and rollback counter — are ours; rpm-ostree,
bootc, greenboot and balenaOS — full OS image — are theirs; and **the campaign over the fleet is
always theirs**, with any mechanism), `c-standards`, `cpp-standards`, `rust-standards`,
`ada-standards` and `zig-standards` (**the language and its toolchain are theirs**, including
`-std=`, MISRA C/CERT C, sanitizers, binary hardening flags, Ada's restricted runtime and Rust's
`no_std` — **here only what restrictions the target imposes**: no `malloc`, no exceptions, no full
libc, bounded stack size), `assembly-standards` (assembly startup, vectors and critical routines),
`linux-administration-standards` (the day-to-day of systemd on a server — **not** on a read-only
embedded image), `linux-hardening-standards` (a CIS/STIG baseline for a full host: it is not the
model for a 32 MB device), `selinux-standards`, `container-runtime-security-standards` (the container
and its runtime, if the device ends up running them), `cryptography-pki-standards` (**the choice of
algorithm, curve, key size and the whole provisioning PKI: theirs** — here only where the key lives
in the silicon and why), `secrets-management-standards` (custody and rotation of the secret on the
server side), `performance-engineering-standards` (server profiling methodology),
`networking-standards`, `wireless-standards` (radio, spectrum, coexistence),
`opensource-licensing-standards` (distribution obligations: **a device that ships GPL is
distribution, and there that skill rules**), `vulnerability-management-standards` (triage and SLA for
the CVEs of the shipped tree), `grc-compliance-standards` (the regulatory framework as a programme;
here the dates that decide design), `mobile-standards` (the app that controls it),
`homelab-standards` (the board as a toy: the boundary is the rigour demanded, not the hardware).

## 2. Default decisions

> Verify the latest version, licence and date on the web before pinning anything in a real project
> (§8). What follows is the **verified** state as of August 2026, with the source cited.

### 2.1 MCU or MPU — the decision that conditions all the others

| Choose **MCU** (Cortex-M, embedded RISC-V, ESP32, nRF) if | Choose **MPU + Linux** (Cortex-A, RISC-V with MMU) if |
|---|---|
| The energy budget is measured in average µA or the thing runs on a battery for years | There is continuous power or a large rechargeable battery |
| Millisecond boot and deterministic response are required | Seconds of boot and tens-of-ms latencies are tolerated |
| The BOM rules: euro-level unit cost, RAM in KB, flash in hundreds of KB | A full network stack, modern TLS, a filesystem and package updating are needed |
| The function is fixed and known at design time | The function is going to change: apps, containers, models, remote orchestration |
| There is no MMU and no general-purpose operating system is wanted | Process isolation, an MMU and users are needed |

Hard rules: **an MPU is not chosen "just in case"** (it multiplies cost, consumption, attack surface
and the maintenance load of a full Linux tree for the whole life of the product), and **an MCU is not
chosen when it is already known that TLS 1.3, a filesystem and full-image OTA will be needed** — that
project ends up porting half of Linux by hand. If the doubt is real, **it is decided by the energy
budget and the software lifecycle**, not by fondness for the platform.

### 2.2 Superloop or RTOS

**A superloop is not a beginner's decision: it is the right answer more often than is admitted.** A
`while(1)` with a non-blocking state machine and an ISR that only raises flags is deterministic,
auditable at a glance, has no per-task *stack overflow* and no priority inversion, and fits in 8 KB
of RAM.

| A superloop is enough if | An RTOS is needed if |
|---|---|
| All the work is non-blocking and bounded; no path takes longer than the worst deadline | There are activities with very different deadlines that cannot be interleaved by hand |
| There are 1-2 event sources and no protocol with deep state machines | There is a TCP/IP, BLE, USB stack or a filesystem: almost all of them assume threads |
| The team can reason about the worst-case execution time of the full loop | Already-proven synchronisation primitives, timers and queues are needed |
| No third-party libraries that assume blocking are used | You want to take advantage of the RTOS ecosystem's drivers and middleware |

**Main antipattern**: *a superloop with a blocking `delay()` in the middle*. It stops being a
superloop and becomes a system with indeterminate deadlines. If a `delay()` longer than a handful of
microseconds appears in the loop, either the design is redone with a state machine or it is time for
an RTOS.

### 2.3 RTOS — verified status, governance and licence

| RTOS | Verified version (Aug 2026) | Licence read raw | Governance | When it is the default |
|---|---|---|---|---|
| **Zephyr** | **4.4.0** (2026-04-14, EOL 2027-04-12); **current LTS: 3.7.0** (2024-07-26, maintained until **2029-07-27**) — next LTS expected in 4.6 | **Apache-2.0** (`LICENSE` on `main`, the full text of the Apache License 2.0) | Linux Foundation, with its own security and CVE process | **Catalogue default** for a new product with connectivity: `west`, Kconfig+devicetree, integrated MCUboot, board support and an explicit LTS policy |
| **FreeRTOS Kernel** | **V11.3.0** | **MIT** (`LICENSE.md` on `main`) | Amazon (AWS) as *steward* since 2017 | A project that already uses it, a very small MCU, or when you want a scheduler and nothing else — **FreeRTOS is a kernel, not a distribution**: network, TLS, OTA and drivers are on you |
| **NuttX** | **13.0.0** | **Apache-2.0** (`LICENSE` on `master`) | **Apache Software Foundation** (top-level project) | When **POSIX compatibility** is the requirement: code that must compile the same on Linux and on the device, or portability of an existing application |
| **Eclipse ThreadX** | v6.4.x, quarterly cadence synchronised across components | **MIT** (`LICENSE.txt` on `master`, *"Copyright (c) 2024 - present Microsoft Corporation"*) | **Eclipse Foundation** since 2023-2024; there is a **ThreadX Alliance** (launched 2024-10-08) for sustainability and to licence the functional-safety documentation package | When an RTOS **with functional-safety certification** is needed and the vendor's ecosystem already ships it (STM32, Renesas, Microchip) |

Governance facts that are **constantly asserted wrongly**:
- **"Azure RTOS" no longer exists as a Microsoft product**: the brand was not transferable; the
  project is **Eclipse ThreadX** under the Eclipse Foundation, MIT. Writing "Azure RTOS" in a 2026
  document is a sign that the fact came from memory.
- The documentation repository `eclipse-threadx/rtos-docs` is **archived**; the live source is
  `rtos-docs-asciidoc`. The version cadence is synchronised across components **even when the code
  has not changed** — a new version does not imply a functional change: you have to read the notes.
- FreeRTOS has been MIT since v10 (before that, a modified GPL). If the project drags along a
  `FreeRTOS.h` from a decade ago, **the shipped licence is not the one you think**: it is read from
  the tree that gets compiled.

### 2.4 Embedded Linux — Yocto or Buildroot, with criteria

| Yocto Project | Buildroot |
|---|---|
| **A product with a long life and several hardware variants**: layers (`meta-*`) let you separate the vendor BSP, the distro and the product | **One product, one hardware, one image**: `defconfig` + `br2-external` and little else |
| Generates an **SDK and packages** (`ipk`/`rpm`/`deb`): it allows installing and updating per package if that is decided | **There is no package manager**: the image is the artifact, and that pushes — correctly — towards full-image OTA |
| **Real LTS**: Wrynose 6.0 (April 2026, supported until **April 2030**); Scarthgap 5.0 (April 2024, until **April 2028**) | Quarterly cycle (2026.05 is the latest verified); **LTS every two years with 3 years of support** — the 2025.02.x line is the current LTS, the next will be 2027.02 |
| Steep learning curve, long builds, `bitbake` opaque when it fails | Learned in a day, one-hour build, readable `make menuconfig` |
| Licence: **MIT** (OpenEmbedded/poky) | **GPL-2.0-or-later** (`COPYING`: *"Buildroot is distributed under the terms of the GNU General Public License … either version 2 of the License, or (at your option) any later version"*) — with the explicit caveat that **the packaged patches are governed by the licence of the software they apply to** |

**The real choice criterion, not taste**: choose **Yocto** when there is *more than one hardware or
product variant sharing a base*, when the vendor BSP already comes as a Yocto layer, or when the
lifecycle demands an LTS branch with security patches for years. Choose **Buildroot** when there is
*one hardware, a small team and one image*, and you prefer understanding the whole build to
delegating it. **Whoever chooses Yocto for a single simple product pays for complexity they did not
need; whoever chooses Buildroot for a family of six products ends up with six divergent trees.** Mind
the origin: **Buildroot is developed on GitLab (`gitlab.com/buildroot.org/buildroot`) and the GitHub
repository is a *mirror*** — issues and PRs there are seen by nobody.

### 2.5 Boot, toolchain and OTA

| Decision | Default | Reason / verified fact |
|---|---|---|
| MPU bootloader | **U-Boot** (latest verified: 2026.07 on `ftp.denx.de/pub/u-boot/`) | **GPL-2.0**, with an explicit exception for the *standalone applications* that use the *jump table* (`Licenses/README`) — a relevant fact for distribution compliance |
| MCU bootloader | **MCUboot 2.4.0**, **Apache-2.0** (`LICENSE`) | It is the de facto standard for A/B and signature verification on MCUs; integrated in Zephyr |
| Hardware description (MPU) | **Device tree** (`.dts`/`.dtsi`/`.overlay`), versioned with the product | Patching the vendor tree *in place* is forbidden: use your own `.dtsi` and overlays |
| OTA on embedded Linux | **RAUC** (v1.15.x, **LGPL-2.1**) or **SWUpdate** (2026.05.x, **GPL-2.0**) | Both do A/B with signature verification. **The licence matters**: LGPL versus GPL changes what you can link |
| Managed OTA / campaigns | **Eclipse hawkBit** (**EPL-2.0**) as the deployment server; **Mender** (client **Apache-2.0**, Northern.tech) if an integrated product is wanted | **Always** verify which part of the server is open and which is paid before committing architecture |
| Toolchain | Pinned to an exact version and **run inside a container or `kas`** | A build that depends on the `gcc` on the developer's laptop is neither reproducible nor auditable |

**Build reproducibility**: the toolchain version, the layer/package versions and the source versions
are pinned (explicit `SRCREV`, never moving branches; `BR2_DOWNLOAD_...` with a hash). The build
**produces and archives the manifest**: which version of each component went into that image. Without
that manifest you cannot answer "is my fleet affected by this CVE?", which is the question that will
arrive. The SBOM stops being hygiene and becomes a regulatory obligation (§5.4).

## 3. Structure and conventions

- **Strict separation**: `app/` (product logic, portable and testable on the host) — `hal/`
  (peripheral access, the only layer that knows the register) — `board/` (pinout, device tree,
  overlays, `defconfig`). The product logic **does not include vendor headers**: if it does, there
  are no host tests and no portability to the next silicon.
- **Configuration in Kconfig/`prj.conf`/`defconfig`, versioned**, never in scattered `#define`s nor in
  compilation flags passed by hand. One `defconfig` per product variant, diffable.
- **Explicit memory map in the linker script**: regions, per-task stack size, a `.noinit` section for
  what must survive the reset (cause of the last reset, failed-boot counter). Each stack's *high-water
  mark* is measured, not estimated.
- **A/B partitioning from day one**, even if the first version has no OTA. Adding A/B later forces a
  partitioning *update* in the field, which is exactly the operation that cannot be done safely.
  Minimum layout: bootloader (immutable, or separately updatable with extreme care) + slot A + slot B
  + persistent data + boot state store.
- **The reset cause is read and persisted on every boot** (the MCU's reset register, `bootcount` in
  U-Boot). A device that does not know why it restarted cannot be diagnosed in the field.
- **The clock is a problem, not a given**: without a battery-backed RTC, after a power cut the device
  does not know the date — and without the date, TLS certificate validation fails or, worse, gets
  disabled. It is decided explicitly: backed-up RTC, NTP/`chrony` with tolerant startup, or
  certificate validation with no clock dependency (a minimum time persisted monotonically).

## 4. Quality and testing

In increasing cost order; the first three are **gates that break the build**:

1. **A clean compilation with warnings as errors** for every `defconfig` variant of the product, not
   just the one the developer uses. Adding a variant and not putting it in CI is a guarantee that it
   will break silently.
2. **Host unit tests** for all the product logic, with the HAL replaced by a double. If the percentage
   of host-testable code is low, the problem is the architecture (§3), not the test. `twister` on
   Zephyr to run the suite on `native_sim` and in emulation.
3. **Static analysis and memory discipline**: the concrete set of tools and flags belongs to
   `c-standards`/`cpp-standards`/`rust-standards`; **what this skill demands is the check that there
   is no dynamic allocation where it was forbidden** (see §7) and that stack use is bounded and
   measured.
4. **Emulation**: Renode or QEMU to run the whole firmware in CI without hardware. It is what makes
   real CI possible in an embedded project; without it CI is limited to "it compiles".
5. **Hardware-in-the-loop** with a bench of real boards and a debug probe, running the suite over the
   signed binary that is going to be distributed. **This is where the update gets tested.**
6. **A mandatory update test in CI, and it is not negotiable**: (a) A→B correct; (b) **power cut in
   the middle of the write**, at several points, and a correct boot afterwards; (c) a corrupt image or
   one with an invalid signature → rejected; (d) a valid image that boots and **does not confirm** →
   automatic *rollback* to the previous slot; (e) an update **from the oldest version in the field**,
   not just from the previous one. An OTA that has only been tested on the happy path is not tested.
7. **Longevity**: a 72 h or longer test with the real duty cycle, watching fragmentation (if there is
   a heap), descriptor leaks, counter overflow and clock drift.

## 5. Stack security

### 5.1 Secure boot and chain of trust
- **Immutable root of trust in the silicon** (vendor ROM), which verifies the bootloader, which
  verifies the application. The chain breaks at the first link that does not verify the next: a signed
  bootloader that loads an application without checking the signature **contributes nothing**.
- **Fuses are burned in production, not on the bench**: enabling secure boot is irreversible. The
  provisioning process is rehearsed end to end on sacrificial units before touching the line.
- **Anti-*rollback* counter** to stop an attacker installing an earlier version with a known flaw. An
  A/B with a signature but without anti-rollback is an assisted downgrade mechanism.
- Firmware signing keys live in an **HSM or a signing service**, not in CI nor on a laptop. Signing
  key rotation is designed **before** the first shipment: if it cannot be rotated, the first leak
  forces a product recall.

### 5.2 Identity and key store
- **A unique key per device, no exceptions.** A key shared across the whole fleet is the classic
  design failure and its consequence is well known: extracting a single device from a drawer
  compromises the entire estate, and **there is no possible rotation without touching every unit**.
  The same applies to identical default passwords — it is literally the first recommendation of ETSI
  EN 303 645 (§5.4).
- **Where the private key lives, in order of preference**: a dedicated secure element (ATECC608,
  SE050) or TPM 2.0 → an enclave in the SoC itself (TrustZone-M with `CMSE`, TrustZone-A with a secure
  world) → a protected flash region with reading disabled → *(unacceptable)* a file in the filesystem
  or a constant in the binary. **The real criterion: the private key never leaves the element; it is
  used inside it.** If the design reads it into RAM to sign, there is no secure store, there is a
  drawer.
- **Identity is injected in manufacturing** with an audited process: who generated it, where the
  record of which serial has which certificate lives, and how a specific unit gets revoked. If there
  is no per-device revocation procedure, there is no identity, there is scenery.
- Encryption and algorithms: **that is `cryptography-pki-standards`' decision**. What this skill
  imposes is that the MCU **has an accelerator or a cycle budget** for whatever is chosen, verified by
  measurement, and that the randomness generator is a TRNG in the silicon — **not** an `srand(time())`,
  which on a device with no RTC produces the same seed across the whole fleet.

### 5.3 Debug surface in production
- **JTAG/SWD disabled or fuse-locked on the production unit.** An open debug port is a full read of
  the flash, key extraction and firmware modification with ten minutes of physical access.
- **Serial console**: no interactive *shell*, no passwordless `root`, no `bootdelay` that allows
  interrupting U-Boot and editing `bootargs` — **interrupting boot and adding `init=/bin/sh` is the
  textbook attack**. If a console is left for diagnostics, it is read-only and authenticated.
- **Re-enabling debug, if it is necessary for RMA, is done by a signed challenge-response** against
  the device identity, never by a common master password.
- Traces and logs: **the firmware does not print secrets, keys, tokens or full identifiers** — not
  over UART, not in the log file, and not in the crash dump uploaded to the cloud.

### 5.4 Regulatory framework — the fact that decides most and is cited worst

Verified as of August 2026, from official sources. **Always re-verify: these dates have already moved
once.**

- **Cyber Resilience Act — Regulation (EU) 2024/2847.** Source: `digital-strategy.ec.europa.eu`,
  verbatim: *"The CRA entered into force on 10 December 2024."* and *"The main obligations introduced
  by the Act will apply from 11 December 2027, with reporting obligations to apply as of 11 September
  2026."* In addition, the chapter on **notification of conformity assessment bodies applies from 11
  June 2026**. Design consequences, not paperwork: an obligation to manage vulnerabilities during the
  declared **support period**, an **SBOM**, a vulnerability disclosure channel, **security updates** —
  and notification of an actively exploited vulnerability and of a severe incident to ENISA and the
  national CSIRT **already in 2026**. Scope: every *product with digital elements* placed on the EU
  market, not just consumer IoT.
- **RED — Directive 2014/53/EU, article 3.3 (d), (e) and (f)**, activated by **Delegated Regulation
  (EU) 2022/30**. The original date of application (1 August 2024) **was postponed by twelve months**
  by Delegated Regulation (EU) 2023/2444: **they apply from 1 August 2025**. They cover network
  protection (d), personal data and privacy (e) and protection against fraud (f). Harmonised
  standards: **EN 18031-1/-2/-3**, cited in the OJEU with **restrictions** (Decision (EU) 2025/138);
  where those conditions are not met, **there is no presumption of conformity** and a notified body is
  required. The RED-DA is expected to be repealed when the CRA fully applies in 2027 — **verify that
  before planning on that assumption**.
- **ETSI EN 303 645** — current version **V3.1.3 (2024-09)**. It is the consumer IoT cybersecurity
  baseline: no default passwords, a vulnerability disclosure policy, updated software. **It is not a
  RED harmonised standard by itself** and it does not define a test method — that is what **ETSI TS
  103 701** is for. Using it as a design *checklist* is correct; presenting it as proof of regulatory
  conformity is not.
- **Architectural consequence**: the support period declared under the CRA fixes **how many years you
  must be able to issue new firmware for that hardware**. That decides today the flash size (a larger
  image must fit years from now), the choice of RTOS or distribution LTS, and whether the chosen
  silicon will still have a maintained BSP. **It is an engineering decision with a legal date.**

## 6. Performance and operability

- **An energy budget written before writing code**: current per mode (active, *sleep*, *deep sleep*),
  time in each mode per duty cycle, and the resulting average consumption against the battery
  capacity. It is **measured** with a current analyser or a coulomb counter on the real hardware — a
  budget computed with datasheet figures always comes out better than reality. What ruins the budget
  is almost never the MCU: it is the **radio** and a peripheral that was left powered.
- **An independent watchdog always enabled in production**, kicked from a single point that is only
  reached if **all** tasks have reported life. A `wdt_feed()` in a periodic ISR watches nothing: it
  survives a hung application perfectly well. The watchdog **is not disabled for debugging** in the
  production image, and the number of watchdog resets is first-class telemetry.
- **`printf` over UART costs what is not written down**: it blocks, it can alter the very *timing* you
  are trying to debug (heisenbug), it burns flash on formatting and it often leaves secrets on the
  wire. On the critical path use **mark-based tracing** (`ITM`/SWO, a toggled GPIO with a logic
  analyser, or a deferred binary log dereferenced on the host). Textual logging is left for boot and
  errors.
- **Minimum telemetry the device must upload**: firmware version, cause of the last reset, watchdog
  reset counter, stack *high-water mark*, result of the last update attempt, and connectivity status.
  Without that the fleet is opaque and the first failed OTA is discovered through customer support.
- **Phased OTA rollout is mandatory**: canary (tens of units) → increasing percentage → fleet. **With
  an automatic stop criterion** tied to the telemetry above: if the confirmed-boot ratio drops, the
  campaign stops itself. And the device **is never updated with the battery below the threshold** nor
  during a critical operation.
- **Degradation with the network down**: the device has to work without a connection. Retries with
  *backoff* and *jitter* — **the jitter is not a detail**: ten thousand devices retrying on the same
  second after an outage take the backend down with a self-inflicted denial of service.

## 7. Long-term sustainability and prohibitions

- **Cadence**: follow the **LTS** branch of the RTOS or the distribution (Zephyr 3.7 LTS until 2029;
  Yocto Wrynose 6.0 until 2030; Buildroot biennial LTS with 3 years) and **move from LTS to LTS as a
  planned project**, not all at once when a critical CVE lands. Staying on an unsupported branch is
  incompatible with the support period declared under the CRA.
- **Declared and published end of life**: the date until which there will be security firmware, what
  happens afterwards to the cloud service the device depends on, and whether the device is still
  useful without it. A product that becomes a brick the day the backend is switched off is a
  regulatory and reputational problem, not a clean business decision.

Explicit prohibitions:
- ❌ **A device with no tested remote update path.** It is the number one veto of this skill.
- ❌ **A key, password or certificate shared across the whole fleet**, including the "factory" ones and
  the "development only" ones that end up in production. FORBIDDEN.
- ❌ **An update without A/B and without automatic rollback**, or with a rollback that depends on
  somebody pressing something. FORBIDDEN to write over the only bootable copy.
- ❌ **Unsigned firmware, or firmware signed with a key that cannot be rotated.** FORBIDDEN to validate
  only a CRC or a hash without a signature: a hash authenticates nothing.
- ❌ **JTAG/SWD active, an interruptible `bootdelay` or an accessible U-Boot shell on a production
  unit.**
- ❌ **`malloc`/`free` at run time in MCU firmware.** All memory is reserved statically or in
  fixed-size arenas at startup; without an MMU, fragmentation is not recoverable and the failure shows
  up weeks later in the field, with no trace. If a third-party component requires a heap, it gets a
  bounded arena and is forbidden to grow. Justifiable and documented exception: allocation
  **exclusively during initialisation**, never freed afterwards.
- ❌ **Unbounded recursion, VLAs and `alloca` in firmware** — they overflow the stack without warning.
- ❌ **Blocking inside an ISR** (busy waits, `printf`, taking a mutex that can sleep).
- ❌ **A watchdog disabled or kicked from a blind timer** in the production image.
- ❌ **Depending on the end user to update**: the update is automatic by default, with a managed
  campaign. An "opt-in" model produces a mostly unpatched fleet.
- ❌ **Moving branches in the build** (`master`, `main`, `latest`) for any source, layer or toolchain
  container. FORBIDDEN: it kills reproducibility and with it CVE impact analysis.
- ❌ **Patching the vendor BSP *in place*** instead of maintaining your own layer/overlay: it blocks
  every future BSP update.
- ❌ **TLS certificates with validation disabled** "because the clock fails at boot". The problem is
  the clock (§3), and it gets solved there.
- ❌ **Telemetry with a personal or location identifier without a legal basis and without
  minimisation** — this is where article 3.3(e) of the RED and the GDPR come in, not just good taste.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web — **this list is deliberately short: it
is what changes and what gets cited wrongly**:

1. **CRA dates (Regulation (EU) 2024/2847)** on `digital-strategy.ec.europa.eu` and on EUR-Lex, and
   whether any later act (omnibus packages, implementing acts) has moved deadlines, widened exemptions
   or refined the categories of important/critical products.
2. **Status of the RED-DA**: whether Delegated Regulation (EU) 2022/30 is still in force or has
   already been repealed by the application of the CRA, and the status of the **restrictions** on
   EN 18031-1/-2/-3 in the OJEU (Decision (EU) 2025/138 or its successor).
3. **Current version of ETSI EN 303 645** and of ETSI TS 103 701 on `etsi.org` (as of Aug 2026:
   V3.1.3 of 2024-09).
4. **RTOS**: the latest stable **and the current LTS** of Zephyr
   (`docs.zephyrproject.org/latest/releases/`), the FreeRTOS Kernel version, NuttX's (Apache releases)
   and Eclipse ThreadX's cadence. **The licence is read from the raw file of the tree that is going to
   be compiled** (`LICENSE`, `LICENSE.md`, `LICENSE.txt`, `COPYING`), not from the label GitHub shows.
5. **Embedded Linux**: the current Yocto LTS branch (`wiki.yoctoproject.org/wiki/Releases`) with its
   end-of-support date, and Buildroot's current LTS (`buildroot.org/lts.html`) — remembering that
   **Buildroot development is on GitLab, not on GitHub**.
6. **Bootloader and OTA**: the latest U-Boot on `ftp.denx.de/pub/u-boot/`, and of MCUboot, RAUC and
   SWUpdate, and **which part of the campaign server is open and which is commercial** before
   committing architecture.
7. **CVEs in the shipped tree** (RTOS, TCP/IP stack, TLS, bootloader) and whether the branch in use
   receives the patch or only the next one does.
8. **Status of the chosen silicon**: whether the vendor maintains the BSP and until when, and whether
   there is an end-of-production notice (PCN/EOL) for the chip itself — a product with a declared
   ten-year support period on an MCU that gets discontinued in two is a decision that has to be taken
   knowingly.

**Declared gaps**: the full text of EN 18031-1/-2/-3 and of ETSI TS 103 701 is paid or
access-restricted; their concrete requirements **have not been verified verbatim** in this document
and must be read from the purchased standard before asserting conformity. Consumption, latency and
size figures are not given here because **they depend entirely on the silicon and the duty cycle**:
they are measured on the hardware, not quoted.

If the web contradicts this document, **the web wins** — flag the discrepancy.
