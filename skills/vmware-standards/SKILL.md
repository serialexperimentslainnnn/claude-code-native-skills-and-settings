---
name: vmware-standards
description: VMware vSphere / VCF as a production platform under Broadcom, and the stay-or-exit decision. Use when running esxcli, vim-cmd, vsish, govc, PowerCLI cmdlets (Connect-VIServer, Get-VMHost, Get-VM, New-VM, Set-VMHostAdvancedConfiguration), the vSphere REST/vSphere Automation API or the terraform-provider-vsphere, operating vCenter Server Appliance (VCSA), vpxd, hostd, /var/log/vmkernel.log, .vmx, .vmdk, .nvram, .vswp or VMFS datastores, sizing a cluster with vSphere HA admission control, DRS, EVC baselines, vMotion and Storage vMotion, vSAN ESA/OSA disk groups and storage policies (SPBM), vSphere Distributed Switch, port groups, NSX segments or Tanzu/vSphere Supervisor, patching with vSphere Lifecycle Manager cluster images and baselines, VMware Tools and VM hardware version compatibility, VADP-based backup, VMSA advisories and ESXi/ESX CVE response, or costing VCF/VVF per-core subscriptions, the 16-core-per-CPU minimum, vSAN TiB entitlements, free ESXi, and whether to migrate off VMware.
---

# VMware vSphere / VMware Cloud Foundation standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: in 2026 the VMware decision on the table in almost every organisation is not
> technical, it is **economic**: stay or exit. The platform is still technically competent; what
> changed is the contract. Any answer that ignores the current licence model (§2) is an incomplete
> answer, however good the architecture is.

## 1. Scope and triggers

Applies to **vSphere/VCF as a production platform** and to the **economic decision** about it:
version and support calendar, licensing model and its minimums, cluster design (HA, DRS, vMotion,
EVC), storage (VMFS, NFS, vSAN, SPBM), hypervisor networking (vSS/vDS, and NSX only to bound it),
patching with vLCM, automation (PowerCLI, API, Terraform), hardening of the management plane, and
**the exit criteria** towards another platform.

Triggers: `esxcli`, `vim-cmd`, `vsish`, `govc`, `Connect-VIServer` and other PowerCLI cmdlets,
`terraform-provider-vsphere`, VCSA, `vpxd`, `hostd`, `/var/log/vmkernel.log`, `.vmx`, `.vmdk`,
`.nvram`, VMFS, `vmware-tools`/`open-vm-tools`, "admission control", "EVC baseline", "storage
policy", "vSphere Lifecycle Manager", "cluster image", "VADP", "VMSA-", "VCF", "VVF", "core
minimum", "VMware renewal".

**Naming**: with VCF 9.0 the hypervisor is renamed **ESX** (previously ESXi); the 2026 security
advisories already use "VMware ESX" (VMSA-2026-0006). Here they are used interchangeably.

**Not applicable**:
- `proxmox-ve-standards` — **migration destination no. 1** and sister skill: **everything decided
  with `pvecm`/`qm`/`pvesm` or in `/etc/pve/` is theirs**, including its import wizard from
  ESXi. Here it is decided **whether** to exit and **what is measured first**; there, how to land it.
- `libvirt-kvm-standards` — the KVM/QEMU substrate with no platform (`virsh`, domain XML). A valid
  destination only for standalone hosts: **exiting vCenter to bare libvirt is losing a platform**, not
  changing it.
- `onprem-standards` — **on-premise platform umbrella, with the routing table (§1.2)**: its
  §2 already fixes the default hypervisor choice; this skill develops the VMware case without
  contradicting it.
- `ha-clustering-standards` — Pacemaker/Corosync, quorum and fencing **generic** to Linux
  services. Here the hypervisor's **native** cluster: vSphere HA, admission control and isolation.
- `linux-storage-standards` and `zfs-standards` — LUN, multipath, filesystem and ZFS on the OS side;
  here VMFS/NFS/vSAN as vSphere objects. `object-storage-standards` — S3 and repositories.
- `networking-standards` — physical network, VLAN, MTU and fabric; here only vSwitch/vDS and port groups.
- `backup-recovery-standards` — **backup mechanics, retention, immutability and proven restore
  are theirs**; here only the backup API (VADP) and application consistency.
- `bcdr-standards` — RTO/RPO, DR plan and drills; business objectives are not set here.
- `incident-response-forensics-standards` and `incident-management-standards` — **when the
  hypervisor is the victim and not the support**: datastore encrypted from the host itself with SSH
  or ESXi Shell enabled, vCenter compromised, platform credentials rotated. The process and
  evidence preservation are theirs; **here the fact that decides the response**:
  vCenter and the hosts are **Tier 0** —managed by whoever manages the domain—, and a host
  suspected of being compromised **is rebuilt from trusted media, it is not cleaned**. Restoration
  does not start until eradication is verified (criteria from `bcdr-standards`).
- `iac-standards` — Terraform/Ansible as a practice; `powershell-standards` — PowerCLI script
  quality. Here only what gets automated and what stays coupled to vCenter.
- `kubernetes-standards` — containers on top (including whatever runs on Supervisor);
  `gpu-computing-standards` — GPU passthrough and partitioning (driver and partitioning are theirs).
- `linux-hardening-standards` and `vulnerability-management-standards` — guest OS baseline and
  CVE triage/SLA; `observability-standards` — telemetry as a practice.
- `finops-standards` — **cost per VM as an economic unit and the comparison method are
  theirs**; here the product's **licence model** that feeds that calculation.
- `enterprise-architecture-standards` — portfolio and ADR; `migration-projects-standards` — migration execution; `windows-server-ad-standards` — the Windows guest;
  `hyper-v-standards` and `xen-standards` — alternative hypervisors, each its own.

## 2. Version, calendar and licence model (the expensive section)

> Verify the latest version and **every price or minimum** on the web before pinning it (§8).

| Fact | Status verified Aug 2026 | Source |
|---|---|---|
| Current generation | **VCF/VVF 9.1**; VCF 9.0 GA **17 Jun 2025** | VCF TechDocs/blog |
| Cadence | Major ≈3 years; minor ≈9 months; maintenance ≈3 months in the first support phase | KB 410435, verbatim |
| vSphere 7.0 EoGS | **2 Oct 2025** (already passed) | KB 415405, verbatim |
| vSphere 8 EoGS | Widely cited as **11 Oct 2027** — **not confirmed in a primary source**: see §8 | — |
| Licence unit | **Per physical core**, term subscription. **No new perpetual licences** | KB 313548 / TechDocs |
| Minimum per CPU | *"You must license a minimum of 16 physical cores for each CPU (physical processor) in your ESXi hosts, even if a CPU has fewer than 16 cores."* | KB 313548, **verbatim** |
| vSAN included | VCF: *"1 TiB of vSAN entitlement for each VCF core purchased"*. VVF: *"0.25 TiB … (rounded up to the next TiB)"* | KB 313548, **verbatim** |
| 9.x mechanism | *"Subscription-based license files replace the use of the 25-character license keys."* Licensed from VCF Operations + the **vcf.broadcom.com** console | TechDocs Licensing Overview, **verbatim** |
| Mandatory telemetry | *"License usage reports are required at least once every 180 days to maintain your licenses"* | idem, **verbatim** |
| Free ESXi/ESX | **It is back** with 8.0U3e: *"fully production-ready release"*, but *"No official Broadcom support"*, *"Cannot be managed by vCenter Server"*, 2 physical CPUs/host, 8 vCPU/VM, no vMotion/DRS/HA/VADP, *"Usage of APIs to manage hosts is not supported"* | KB 399823, **verbatim** |

**Rules that follow and are not negotiable:**

- **Every physical core of every host running the product is licensed**: there is no per-VM nor
  per-capacity licence, no test/dev exemption, and switching cores off in BIOS does not reduce the count. Since the
  16/CPU minimum punishes small hosts, **the only real cost lever is consolidating onto fewer, denser
  hosts**, not buying less.
- **VVF vs VCF**: VVF is the base (vSphere + limited vSAN + operations); VCF adds NSX and automation.
  Buying VCF "because it came in the bundle" and not using NSX is the most common overspend.
- **Renewing late is penalised**: channel press (Arrow memo via CRN, *The Register* 28 Mar 2025)
  reports *"penalties for end customers who have not renewed their subscription licenses … on the
  anniversary date"*, of 20 % on the first year. **Not published by Broadcom**: a calendar risk,
  not a settled figure.
- **Declared discrepancy — 72-core minimum**: the same source reports *"the minimum number of
  cores required for VMware licenses will increase substantially, from 16 to 72 cores per command
  line"*, *"as of April 10th"* (2025). Later sources treat it as **clarified to 72 per
  product/order** or **withdrawn**, while the primary minimum of **16 per CPU** remains published
  unchanged. **There is no primary Broadcom source for the 72.** Plan with 16/CPU and **require the
  partner to state in writing the minimum applicable to your order**.
- **Channel**: the VMware Advantage programme ended on **31 Oct 2025** and moved to **invitation
  (Pinnacle)**; the **White Label model disappeared** and non-invited VCSPs stopped being renewed
  (staggered notices through Jan-Mar 2026). Source: channel press, **not primary**. Consequence:
  **verify your provider is still authorised before counting on it for the renewal.**
- **Price**: Broadcom **does not publish list prices**; everything goes through a partner. **No
  €/core figure is written without a signed quote** (§8).

## 3. Architecture and operations

**Cluster and compute**
- Cluster homogeneous in CPU and firmware. **EVC baseline set from day 1**: enabling it later
  forces VMs to be powered off. Per-VM EVC only for one-off mobility.
- **vSphere HA with explicit admission control** and reservation sized to the tolerated failure (N+1
  minimum). HA without a reservation is HA that does not start the VMs when it matters.
- **DRS in `fullyAutomated`** unless there is a written reason, with affinity/anti-affinity rules for what
  must stay apart. **Predictive DRS** only with the operations suite feeding it and with
  enough history; without that it is noise.
- vMotion and Storage vMotion on a **dedicated network** (its own VLAN, consistent MTU) and with
  redundant vmknics. Storage vMotion is planned: it consumes the array.

**Storage**
- **VMFS** for block, **NFS** when the array does it better, **vSAN** when it is accepted that
  storage becomes part of the cluster. **vSAN is licensed separately per TiB** beyond the
  included entitlement: it is the cost leak that shows up after two years.
- **SPBM always**: policy per service class, never per datastore by hand. **vSAN ESA** for
  new hardware; OSA only for legacy hardware. **vVols are deprecated in VCF/VVF 9.0**
  (KB 401070): nothing new is designed on them.

**Network**
- **vDS by default** in production: the config lives in vCenter, consistent and auditable. Standard
  vSwitch only for host bootstrap and rescue.
- **NSX only if there is a microsegmentation or overlay-network requirement the physical network does not cover.** It is
  a whole product with its own control plane and its own curve: adopting it **makes the exit more expensive** than
  any other decision on this list.

**Operations, backup and automation**
- **vLCM with a cluster image** (base + vendor addon + firmware), not baselines: it is the only thing that makes
  every host identical and reproducible. Rolling patching with DRS evacuating.
- **VMware Tools / open-vm-tools is a first-class dependency**: without it there is no quiesce, no orderly
  shutdown, no IP in inventory and no backup consistency. It is patched and monitored like the
  hypervisor. The **VM hardware version** is raised in waves: rolling back is expensive.
- Backup via **VADP** (snapshot + CBT from the backup product), never copying `.vmdk` while
  running; quiesce with VSS/scripts. Retention, immutability and restore: `backup-recovery-standards`.
- **PowerCLI** for operations, **REST/Automation API** for integration, **Terraform provider**
  for what must be reproducible (`powershell-standards`, `iac-standards`). **Every automation coupled to
  vCenter is exit debt**: inventory it (§7).

## 4. Quality and testing

**Omitted as artificial**: there is no build and no test suite. Enforceable equivalent: every cluster
change is validated in preproduction with the same image, and HA failover is tested annually.

## 5. Stack security

- **A compromised vCenter is a compromised data centre.** It gives control over every VM, their
  disks and their consoles: it is **Tier 0**, not "just another management application". Dedicated
  administrative workstation, MFA, named accounts, no shared SSO with the office estate and
  `administrator@vsphere.local` reserved and audited.
- **Isolated management plane**: vCenter, ESX management, iDRAC/iLO and vMotion on their own VLANs, **with
  no route from the user network**. Lockdown mode on the hosts; ESXi Shell and SSH off except for a
  window, with registered exceptions.
- **Hardening baseline**: official guide in the Broadcom repository
  `github.com/vmware/vcf-security-and-compliance-guidelines` (per version, already with 9.0). **CIS**: as of
  Aug 2026 the most recent is **ESXi 8.0 v1.3.0** and **there is no 9.0/ESX benchmark** — Broadcom as the
  technical baseline, CIS when the audit demands an attestable framework, and the gap declared.
- **Patching**: the advisories are **VMSA** and arrive without notice. Reference: **VMSA-2026-0006
  (29 Jul 2026)** — authentication bypass in vCenter (CVE-2026-59309, 9.8), traversal in its syslog
  (CVE-2026-59310) and **VM escape** via VMXNET3 (CVE-2026-47876, 9.3) **with no workaround**. Rule:
  **a VM escape or an authentication bypass in vCenter is an emergency change**; the general SLA is from
  `vulnerability-management-standards`.
- VM encryption and vTPM only with key custody solved (external KMS **and its backup**): losing
  the key provider is losing the VMs (`cryptography-pki-standards`).

## 6. Performance and operability

- Metrics that decide: `%RDY` and `co-stop` (vCPU oversubscription), host *ballooning* and *swap*,
  datastore latency and vMotion saturation. Export to `observability-standards`.
- Wide VMs (many vCPUs) penalise scheduling: size by real consumption, not by what the
  application vendor asked for. No reservations or limits by default; a forgotten CPU limit
  is the recurring root cause of "the VM is slow and nobody knows why".
- Capacity measured against **licensed cores**, not against installed cores: in this model,
  idle capacity is paid for.

## 7. Sustainability and exit criteria

**Before deciding to stay or exit, this is measured — and it is measured, not estimated:**
1. **Real cost per VM per year** with the renewal already quoted (method in `finops-standards`), against
   the same calculation on the destination platform including hardware, support, backup and **staff
   hours**.
2. **Dependency on vSAN and NSX**: if storage or microsegmentation live there, the
   exit stops being "moving VMs" and becomes redesigning two layers.
3. **Disk format and boot**: `.vmdk` to qcow2/raw, BIOS vs UEFI, controllers (PVSCSI→virtio),
   guest drivers, and the network interface renaming that takes static IPs and firewall rules
   down with it.
4. **Backup**: the current product may not support the destination, or support it worse. The
   **restore** is validated on the destination before migrating anything, not afterwards.
5. **Coupled automation**: every PowerCLI script, pipeline with the vSphere Terraform provider
   and API integration is rewrite work that does not show up on the spreadsheet.
6. **Staff**: the team knows vSphere. The destination platform's curve is a real cost for
   12-18 months, and the operational risk in that period is greater than the first year's saving.

**That is why the exit costs more than the spreadsheet says**: the spreadsheet compares licences, and the
project pays for storage and network redesign, automation rewrite, backup and DR revalidation,
downtime windows and a learning curve. **Exiting may still be correct
—and often is—, but it is decided with the full cost, not with the licence delta.**

**Prohibitions:**
- ❌ **FORBIDDEN** to write a €/core, €/VM or "estimated saving" figure without a signed quote.
- ❌ **FORBIDDEN** to size a purchase without the per-CPU core minimum **confirmed in writing**
  by the partner for that specific order (§2, the 72 discrepancy).
- ❌ **FORBIDDEN** free ESXi in production: no support, no vCenter, no HA/vMotion and **no
  VADP** — that is, no API-based backup. Lab and nothing else.
- ❌ **FORBIDDEN** to expose vCenter or the ESX management interfaces to the user network or to
  the Internet, and ❌ to use `administrator@vsphere.local` as a daily working account.
- ❌ **FORBIDDEN** to treat a vSphere snapshot as a backup, and ❌ to leave snapshots alive beyond
  the change window (delta growth and impossible consolidation).
- ❌ **FORBIDDEN** to design on **vVols** (deprecated in 9.0) or on editions that are no longer
  renewed without a destination plan.
- ❌ **FORBIDDEN** heterogeneous clusters without EVC, and ❌ enabling EVC "later on".
- ❌ **FORBIDDEN** to defer a VM-escape or authentication-bypass VMSA to the ordinary cycle.
- ❌ **FORBIDDEN** to start an exit migration without a **restore proven on the destination** and without
  a documented fallback per wave.
- ❌ **FORBIDDEN** to assume the current provider will be able to renew: its authorisation is verified.

## 8. Mandatory web verification

Before pinning anything, check in a primary source (Broadcom TechDocs, support portal KBs,
VMSA advisories) and with a date:
1. **Current version** of VCF/VVF and its components, and its **EoGS/EoTG in the Product Lifecycle
   Matrix**. **Declared gap**: the vSphere 8 EoGS date (widely cited as 11 Oct 2027) has not been
   confirmed in a primary source, nor has the EoGS of 9.0/9.1 — verify in the matrix.
2. **Declared gap — prices**: there is no public list. **No figure is written without a quote**.
3. **Declared gap — order minimum**: the "72-core minimum" only appears in channel press and
   is reported as clarified or withdrawn. Confirm in writing with the partner. What is primary and current is
   **16 cores per CPU** (KB 313548).
4. **Declared gap — late renewal penalty** (20 %): channel press, not primary.
5. Status of the **partner programme** and of the purchasing route: it changed three times between 2024 and 2026.
6. Status of the sellable **editions** (VVF/VCF versus Standard/Enterprise Plus): the secondary
   sources contradict each other about which ones are still being renewed. **Cross-check with the partner.**
7. Current conditions of **free ESXi/ESX** (version offered, limits, whether it is still available).
8. **VMSA** advisories later than VMSA-2026-0006 and their exploitation status (KEV/CISA).
9. Status of the **CIS Benchmark** for ESX 9.0 and the current version of Broadcom's hardening
   repository.
10. Maturity and status of the destination platforms (Proxmox VE, Nutanix, Hyper-V/Azure Local,
    OpenStack, OLVM, XCP-ng) — **the criteria for each are their skill's**, not this one's.

If the web contradicts this document, **the web wins** — flag the discrepancy.
