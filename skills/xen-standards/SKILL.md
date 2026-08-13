---
name: xen-standards
description: The Xen hypervisor, XCP-ng and the XenServer legacy - dom0/domU, PV/HVM/PVH and when Xen is still the right answer. Use when running xl (xl create, xl list, xl info, xl dmesg, xl sched-credit2, xl vcpu-pin), editing /etc/xen/*.cfg domain config files or xl.conf, sizing dom0_mem, dom0_max_vcpus and dom0 pinning on the Xen command line, choosing between PV, PVH and HVM guests or using pv-shim, running xenstore-ls, xentop, xl debug-keys or the credit2/null schedulers, operating XCP-ng and XenServer hosts with xe CLI, xsconsole, xapi, toolstack, SR and VDI storage repositories (LVM, ext, thin provisioning, XOSTOR/LINSTOR), PIF/VIF/network objects and bonds, pool masters and HA, managing them with Xen Orchestra, XO Lite, XOA or xo-server, migrating from VMware into XCP-ng, tracking Xen Security Advisories (XSA) and the pre-disclosure list, or deciding between Xen and KVM for a new deployment.
---

# Xen, XCP-ng and the XenServer legacy standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: Xen is the type-1 hypervisor a good part of the public cloud runs on
> and, at the same time, **the one least deployed in the enterprise these days**. This skill exists for three things: operating
> well what is already deployed, deciding honestly whether Xen contributes anything to a new deployment
> (§7: almost never), and separating three things that get confused daily — **the Xen project**, **XCP-ng**
> (Vates) and **XenServer** (Cloud Software Group, formerly Citrix Hypervisor).

## 1. Scope and triggers

Applies to: Xen architecture (dom0/domU, virtualisation modes), operating **XCP-ng** as a
platform and its ecosystem (xapi, `xe`, Xen Orchestra, XOSTOR), the state of the commercial product
**XenServer**, the project's security process (XSA), and **the selection criteria** against KVM.

Triggers: `xl` (`create`, `list`, `info`, `dmesg`, `sched-credit2`, `vcpu-pin`), `/etc/xen/*.cfg`,
`xl.conf`, `dom0_mem`, `dom0_max_vcpus`, `xenstore-ls`, `xentop`, `pv-shim`, `xe` (`vm-list`,
`sr-list`, `pool-*`, `host-*`), `xsconsole`, `xapi`, "SR"/"VDI", "PIF"/"VIF", "pool master",
"XOSTOR", "Xen Orchestra", "XOA", "XO Lite", "XSA-", "dom0", "domU", "PVH", "XenServer",
"Citrix Hypervisor".

**Not applicable**:
- `proxmox-ve-standards` and `libvirt-kvm-standards` (**already written**) — **the catalogue's KVM
  platforms and the default choice for a new deployment** (§7). Boundary: if the answer is
  written with `qm`/`pvesm` it belongs to PVE; with `virsh`/domain XML, to libvirt; with `xl`/`xe`, here.
- `vmware-standards` and `hyper-v-standards` — each skill covers its own hypervisor. The **criteria for exiting
  VMware** (what gets measured before deciding) are in `vmware-standards` §7; here only XCP-ng as a
  possible destination.
- `onprem-standards` — **the on-premise platform umbrella with the routing table (§1.2)**.
- `ha-clustering-standards` — generic Pacemaker/Corosync, quorum and fencing; here the pool and HA
  **native to XCP-ng/XenServer**.
- `linux-storage-standards`, `zfs-standards`, `object-storage-standards` — storage outside
  the SR/VDI model.
- `networking-standards` — physical network, VLANs, MTU; here only PIF/VIF, bonds and pool networks.
- `backup-recovery-standards` — **retention, immutability and a tested restore**; here only which backup
  API exists and its limits. `bcdr-standards` — RTO/RPO and the plan.
- `linux-administration-standards` and `linux-hardening-standards` — the dom0 OS as Linux; here
  dom0 **as a hypervisor component** and its surface.
- `vulnerability-management-standards` — CVE triage and SLAs; here the XSA process and its calendar.
- `iac-standards` (Terraform/Ansible), `kubernetes-standards` (containers on top),
  `gpu-computing-standards` (GPU pass-through), `observability-standards` (telemetry).
- `opensource-licensing-standards` — general licensing criteria; here the concrete licences
  verified raw (§2). `finops-standards` — cost per VM as an economic unit.
- `enterprise-architecture-standards` and `migration-projects-standards`.

## 2. Versions, licences and commercial model

> Verify the latest version and **any price** on the web before pinning it (§8).

| Component | Status verified Aug 2026 | Licence (read **raw**) |
|---|---|---|
| **Xen Project** (hypervisor) | Latest verified: **4.21**, announced Nov 2025. Stable branches maintained in parallel | **GPL-2.0 *only*** — `COPYING`: *"the only valid version of the GPL … is _this_ particular version (i.e., *only* v2, not v2.2 or v3.x …)"* |
| **XCP-ng** (Vates) | **8.3 LTS** is the recommended version; released **2024-10-07**, supported until **2028-11-30**. 8.2 LTS reached end of support in 2025. **9.0 is not GA yet**: *"XCP-ng 9.0 might follow the same path"* | **GPL-2.0** (`xcp-ng/xcp/LICENSE`) |
| **xapi** (XCP-ng/XenServer toolstack) | The central component of the pool and of `xe` | **LGPL-2.1 with a linking exception** (`xapi-project/xen-api/LICENSE`) |
| **Xen Orchestra** | `xo-server` 5.207.x, `xo-web` 5.201.x (versions read from `package.json`) | **AGPL-3.0-or-later** — real implication: **modifying it and offering it as a service obliges you to publish the code** |
| **XenServer** (Cloud Software Group) | **XenServer 9** announced ≈Jul 2026; 8.4 the previous generation. **Citrix Hypervisor 8.2 CU1 reached end of life on 25 Jun 2025** | Proprietary |

**Commercial model — what to know before choosing:**

- **XCP-ng is fully open source, with no paid features in the hypervisor.** The project's README
  states it: *"Fully Open Source: no paywalls or complicated licenses, all the features are free"*.
  What you pay for is **support**, not functionality.
- **Xen Orchestra does have a paid part, and that is the usual trap**: **XO from source is free
  (AGPL) and installed by hand**; **XOA** is the prebuilt appliance and **the only route to professional
  support**, priced **per host per year, in tiers**. **Figures: not written here** — they are
  quoted with Vates (§8). Criterion: in production, either XOA with support is bought, or it is explicitly
  accepted that management and backup are maintained by the team from source.
- **Backup**: in XCP-ng the real backup capability comes from Xen Orchestra (jobs, delta, replication, XO Proxy).
  **Without XO there is no backup platform**: that makes XO a critical dependency, not an
  optional interface. Mechanics and a tested restore: `backup-recovery-standards`.
- **XenServer no longer has a free edition**: it was replaced by a **90-day Trial Edition
  limited to a small pool**, and Citrix virtual desktop licences no longer entitle you to the
  hypervisor. Consequence: **XenServer is only justified inside a Citrix shop**; outside
  it, XCP-ng covers the same ground without that contract. (Source: XenServer docs + press, Jul 2026 — §8.)

## 3. Architecture and operation

**dom0 / domU**
- **dom0 is a privileged domain, not "the host"**: it runs the toolstack and the backend drivers.
  The hypervisor is small; **the real attack surface is the size of dom0**. Hence the rules:
  **minimal dom0** (nothing installed that is not needed), **pinned memory** with `dom0_mem=Xg,max:Xg`
  — never ballooning in dom0 — and **bounded, pinned vCPUs** (`dom0_max_vcpus`, `dom0_vcpus_pin`) so that
  a domU cannot steal CPU from it. In XCP-ng dom0 is an appliance: **you do not install arbitrary
  packages in it**; it breaks support and the update cycle.
- Isolating drivers in **service domains** (driver domains) is Xen's historic architectural
  card. It is real and remains its best technical argument, but **outside Qubes OS and
  high-security niches almost nobody deploys it**: do not propose it as if it were free.

**Virtualisation modes — status verified in Xen's `SUPPORT.md` (verbatim):**
- **x86/PV**: *"Status, x86_64: Supported"*, but **`x86_32` without the shim: *"Supported, not security
  supported"*** — that is, a mode retired in practice. **PV is classic paravirtualisation,
  with no hardware extensions, and it is the mode with the largest surface in the hypervisor.**
- **x86/HVM**: *"Status, domU: Supported"*. Full virtualisation with QEMU as the device
  model: it is QEMU that contributes most of the exposed code.
- **x86/PVH**: **the modern mode and the default choice**. domU *"Supported"*; **dom0
  *"Supported, with caveats"*** — the documentation itself warns: *"PVH dom0 hasn't received the
  same test coverage as PV dom0"*, and it lacks at least **PCI SR-IOV** and native NMI forwarding.
  **Criterion: PVH for domU whenever the guest supports it; PVH dom0 only with your own testing.**
- **An important correction**: PV **is not deprecated upstream** (it is still "Supported" and still
  receives XSAs). The retirement is **downstream**: **XCP-ng dropped PV support** and only allows
  booting PV guests through **`pv-shim`** (PV inside a PVH container), which **is not the recommended
  route**. Do not confuse the two when reading documentation.

**XCP-ng: storage and networking**
- The model is **SR (Storage Repository) → VDI (virtual disk) → VBD**, not loose files.
  SR choice: **LVM over block (iSCSI/FC)** for predictable performance without thin provisioning;
  **ext/file over local or NFS** when you want thin provisioning and cheap snapshots; **XOSTOR (LINSTOR/DRBD)**
  for hyperconverged replication. **Thin provisioning and snapshot support depend on the SR
  type and that choice cannot be changed without emptying the SR**: decide it once, with the data in front of you.
- **The chain of snapshots/linked VDIs is this platform's classic operational failure**:
  forgotten snapshots that do not coalesce fill the SR and block the pool. **Watching the SR's free
  space and the coalesce queue is a mandatory alert**, not a pretty dashboard.
- Networking: **PIF/VIF** objects, bonds at pool level, VLANs on the pool network and not in the guest. The
  physical network, MTU and LACP belong to `networking-standards`.
- **Pool**: one **pool master** holding the xapi database. Native HA requires a **heartbeat SR** and is
  configured at pool level. **A pool with no reachable master is a pool with no control plane**:
  database replication and a documented, **tested** promotion procedure.

**Guest tools**: XCP-ng's **guest tools** (PV drivers and agent) are a first-class
dependency — without them there is no orderly shutdown, no IP in the inventory and no quiesce. They get patched.

## 4. Quality and testing

**Omitted as artificial**: there is no build and no test suite of the deployment itself. The operational
equivalent: a rolling pool update with `xe` and prior evacuation, an HA failover tested
at least once a year, and restore validation from XO in `backup-recovery-standards`.

## 5. Security

- **The process is the XSA (Xen Security Advisory)** and it must be understood because it sets the patching
  calendar: there is a **pre-disclosure list** for significant operators and distributors, with an
  embargo — *"One working week between notification arriving at security@xenproject and the issue of
  our own advisory to our predisclosure list … Two working weeks between issue of our advisory to our
  predisclosure list and publication"* — and on the embargo date *"we will publish the advisory, and
  push bugfix changesets to public revision control trees"*. **For organisations the entry bar is
  high**: *"a rule of thumb is that 'large scale' means an installed base of 300,000 or
  more Xen guests"*. Translation: **you will not be on the list**; you find out on publication day,
  so the emergency patching procedure must be written **beforehand**.
- **Track record**: Xen accumulates a high volume of hypervisor advisories (the XSA index well above
  400 by mid-2026, including escapes and cross-domain leaks). That **is not a signal of a bad
  product**: it is a signal of a project with disciplined disclosure and of the fact that **the hypervisor is
  a security boundary that genuinely fails**. The operational consequence is the same in Xen as
  in any other: **a domain-escape XSA is an emergency change**, not a monthly cycle.
- **The size of dom0 is the attack surface**: every package, service and driver in dom0 widens
  what an escape can reach. Rule: minimal dom0, no network services other than the toolstack,
  and management (`xe`, XO, SSH) on an **isolated management VLAN with no route from the user network**.
- **HVM puts QEMU in the threat model**: a large share of the XSAs with escape impact are in
  the device model. Preferring **PVH** where the guest allows reduces the problem by
  construction — that is the real technical argument for PVH, not performance.
- Pool and XO authentication integrated with the corporate IdP (`identity-access-management-standards`);
  **never a shared pool `root` as a working account**.

## 6. Performance and operability

- **Scheduler**: `credit2` as the general one; `null` only for static 1:1 assignment in deterministic
  latency scenarios (telco, real time). It is a platform decision, not per-VM tuning.
- **CPU pinning and NUMA** matter more in Xen because of dom0's effect: dom0 pinned and separated from the domU
  CPUs on loaded hosts. **No aggressive ballooning** in dom0 or in sensitive memory.
- Metrics that decide: CPU per domain (`xentop`), memory pressure, **SR free space and the coalesce
  queue**, VDI latency and the pool master's status (`observability-standards`).

## 7. Sustainability, selection criteria and prohibitions

**Said plainly: for a new enterprise deployment, the catalogue's default choice is
KVM — through `proxmox-ve-standards` (platform) or `libvirt-kvm-standards` (standalone host).** Reasons:
installed base, tooling and backup ecosystem, a pool of people who know how to operate it, and
integration with everything else. **Xen is not worse technology; it is a bet with fewer people behind it in
the enterprise segment**, and that is paid for in hiring, in third-party support and in diagnosis
time.

**Xen (through XCP-ng) is justified when:**
- **XenServer/Citrix Hypervisor is already deployed** and you want out of the contract without redoing the
  operating model: XCP-ng is the lowest-friction route (same `xe`, same pool/SR/VDI model).
- There is an **isolation requirement** that rests on Xen's architecture: service domains,
  a small hypervisor, high-security or certification cases (a Qubes-style profile, automotive,
  critical systems).
- There is concrete **legacy compatibility** with XenServer images, tools or integrations.
- The team **already knows XCP-ng** and operates well with Xen Orchestra: changing platform out of fashion alone
  is a worse decision than staying.

**Xen as a VMware exit destination** is a live option and is Vates's current commercial case
(VMware import in XO), but **it is not the catalogue's default route**: the criteria for what
gets measured before leaving are in `vmware-standards` §7 and the default destination in
`proxmox-ve-standards`. Choosing XCP-ng over PVE must be justified by one of the four reasons
above, not by a feature comparison.

**Prohibitions:**
- ❌ **FORBIDDEN** to deploy **PV** guests in new production. PVH if the guest supports it;
  HVM if not. ❌ `pv-shim` as a permanent solution.
- ❌ **FORBIDDEN**: `x86_32` PV without the shim: the documentation itself marks it **not security supported**.
- ❌ **FORBIDDEN** to install arbitrary packages, services or agents in XCP-ng's **dom0**.
- ❌ **FORBIDDEN**: dom0 with dynamic memory or without a pinned `dom0_mem`.
- ❌ **FORBIDDEN** to expose `xe`, xapi, XO or dom0 to the user network or to the Internet.
- ❌ **FORBIDDEN** to run in production **without monitoring SR free space and the coalesce queue**:
  that is the failure mode that stops the pool.
- ❌ **FORBIDDEN** to treat a VDI snapshot as a backup, and ❌ to leave snapshots alive with no expiry.
- ❌ **FORBIDDEN**: production on XCP-ng **pre-releases**: *"Vates does not offer commercial
  support for pre-releases"* and *"may not receive urgent security updates as promptly"*.
- ❌ **FORBIDDEN** to build backups on Xen Orchestra without explicitly deciding either XOA with support
  or XO from source with an assigned internal owner.
- ❌ **FORBIDDEN** to modify Xen Orchestra and offer it as a service without complying with the **AGPL-3.0**.
- ❌ **FORBIDDEN** to defer an XSA with domain-escape impact to the ordinary patching cycle.
- ❌ **FORBIDDEN** to choose Xen for a new deployment without writing down which of the four reasons in §7
  applies.

## 8. Mandatory web verification

Before pinning anything, check the primary source (xenproject.org, `SUPPORT.md` in the Xen tree,
docs.xcp-ng.org, docs.xen-orchestra.com, docs.xenserver.com) with a date:
1. **The current Xen hypervisor version** — 4.21 verified (Nov 2025); **check whether 4.22 has shipped**
   and which stable branches are still maintained.
2. **XCP-ng**: recommended version, the status of **9.0** (as of Aug 2026 **not GA**) and end-of-support
   dates. 8.3 LTS: supported until **2028-11-30**.
3. **The `SUPPORT.md` of the specific version**: the status of PV/PVH/HVM and of PVH dom0 changes between
   versions. Do not take this table as valid without rereading it.
4. **Declared gap — pricing**: no XOA or Vates support figure is written without a
   quote. The verified model is **per host per year, in tiers**; the amounts are quoted.
5. **Declared gap — XenServer**: the status of XenServer 9, its editions and the exact scope of the
   Trial Edition come from product documentation and press (Jul 2026); **cross-check against
   docs.xenserver.com and against the contract** before basing a decision on them.
6. **Recent XSAs** and whether any affects the modes or devices in use; also check the
   QEMU advisories if there are HVM guests.
7. Licences **raw** if anything changes: Xen's `COPYING`, the `LICENSE` of `xcp-ng/xcp` and of
   `xapi-project/xen-api`, and the `license` field of Xen Orchestra's `package.json` files. Verified as of
   Aug 2026: **GPL-2.0 only**, **GPL-2.0**, **LGPL-2.1 with an exception** and **AGPL-3.0-or-later**.
8. The state of the third-party backup ecosystem for XCP-ng (real coverage, not announcements).

If the web contradicts this document, **the web wins** — flag the discrepancy.
