---
name: hyper-v-standards
description: Hyper-V on Windows Server and Azure Local as a production virtualization platform. Use when running Hyper-V PowerShell cmdlets (New-VM, Set-VMProcessor, Get-VMSwitch, New-VMSwitch, Add-VMNetworkAdapter, Checkpoint-VM, Move-VM, Enable-VMResourceMetering) or Failover Clustering cmdlets (New-Cluster, Test-Cluster, Get-ClusterQuorum, Set-ClusterQuorum, Add-ClusterSharedVolume, Update-ClusterFunctionalLevel, Invoke-CauRun), sizing a Windows Server Failover Cluster (WSFC) with node majority, file share or cloud witness, Cluster Shared Volumes under C:\ClusterStorage, SMB3 file shares with Multichannel and RDMA, Storage Spaces Direct (S2D), Switch Embedded Teaming (SET) versus LBFO, SR-IOV, VMQ, generation 1 versus generation 2 VMs, .vhdx and .avhdx files, Secure Boot and vTPM in a VM, guarded fabric and shielded VMs with Host Guardian Service, Hyper-V checkpoints, live migration and CredSSP versus Kerberos constrained delegation, Cluster-Aware Updating and cluster OS rolling upgrade, Windows Admin Center, or costing Windows Server Standard versus Datacenter core licensing and guest virtualization rights.
---

# Hyper-V (Windows Server / Azure Local) standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: **Hyper-V is the hypervisor you have already paid for if you have Windows Server.** Its
> advantage is economic and one of domain integration, not technical: it does not beat KVM or vSphere at
> anything specific, but if you are going to licence Windows in the guests anyway, it frequently wins the
> cost comparison. Choosing it for any reason other than that is usually a badly made decision.

## 1. Scope and triggers

Applies to **Hyper-V as a production virtualization platform**: the role on Windows Server versus
Azure Local, per-core licensing and guest virtualization rights, a WSFC cluster with
its quorum and witness, storage (CSV, SMB3, S2D), virtual networking (virtual switch, SET, SR-IOV),
VM generation and security, and operation through PowerShell.

Triggers: `New-VM`, `Set-VMProcessor`, `Get-VMSwitch`/`New-VMSwitch`, `Checkpoint-VM`, `Move-VM`,
`New-Cluster`, `Test-Cluster`, `Set-ClusterQuorum`, `Add-ClusterSharedVolume`, `Invoke-CauRun`,
`Update-ClusterFunctionalLevel`, `C:\ClusterStorage\`, `.vhdx`/`.avhdx`, "SET", "LBFO", "VMQ",
"SR-IOV", "gen 1 vs gen 2", "vTPM", "shielded VM", "Host Guardian Service", "checkpoint",
"live migration", "Windows Admin Center", "Standard or Datacenter".

**Not applicable**:
- `windows-server-ad-standards` (**already written**) — **the Windows OS, the domain, GPOs, Kerberos and the
  Tier 0 model are theirs**. Here only the Hyper-V role and the cluster that holds it up. Boundary: if the
  answer is written with `Get-ADUser`/GPO, it belongs there; with `Get-VM`/`Get-Cluster`, here.
- `powershell-standards` (**already written**) — **script quality**: modules, error handling,
  `-WhatIf`, tests. Here what gets automated, not how the `.ps1` is written.
- `vmware-standards` and `xen-standards` — each skill covers its own hypervisor; the economic comparison
  against VMware is made from `vmware-standards` (§7, exit criteria).
- `proxmox-ve-standards` and `libvirt-kvm-standards` — **the catalog's KVM platforms**, and the
  alternative migration destination when the shop is not Microsoft.
- `onprem-standards` — **the on-premise platform umbrella with the routing table (§1.2)**.
- `ha-clustering-standards` — Pacemaker/Corosync, quorum and fencing **generically** on Linux. **WSFC belongs
  to the hypervisor and is decided here**; the quorum principle is common, the implementation is not.
- `linux-storage-standards`, `zfs-standards`, `object-storage-standards` — storage outside
  CSV/S2D/SMB3.
- `incident-response-forensics-standards` and `incident-management-standards` — **when the
  hypervisor is the victim**: the process and evidence preservation are theirs; **here the fact
  that decides the response**: the Hyper-V host is domain-joined, so **a compromised AD
  is a compromised hypervisor** — it is Tier 0 by definition — and a suspect host **is rebuilt
  from trusted media, it is not cleaned**. Restoration does not start until eradication
  has been verified (criteria from `bcdr-standards`).
- `networking-standards` — physical network, VLAN, MTU, jumbo frames and the ToR switch; here the virtual
  switch and SET.
- `backup-recovery-standards` — **backup mechanics, retention, immutability and a tested restore**;
  here only the VSS provider and application consistency. `bcdr-standards` — RTO/RPO and the plan.
- `iac-standards` — Terraform/Ansible/DSC as a practice; `kubernetes-standards` — containers on
  top; `gpu-computing-standards` — DDA/GPU-P: the driver and the partitioning are theirs.
- `azure-standards` — everything that lives in Azure; here Azure Local only as an on-premise product.
- `vulnerability-management-standards` and `observability-standards` — CVE triage and telemetry.
- `finops-standards` (**already written**) — **the cost per VM and the comparison method are theirs**;
  here the licensing model. `enterprise-architecture-standards` and `migration-projects-standards`
  — portfolio decision and migration execution.

## 2. Version, calendar and licence (the calculation that decides density)

> Verify the latest version and **every licence minimum or right** on the web before pinning it (§8).

| Fact | State verified Aug 2026 | Source |
|---|---|---|
| Current LTSC | **Windows Server 2025** (available since 1-Nov-2024). There is no announced "Windows Server 2026": the next LTSC is in preview without a name | Microsoft Learn / release health |
| LTSC lifecycle | *"5 years of mainstream support and 5 years of extended support for a total lifecycle of 10 years"* | Learn, **verbatim** |
| WS 2025 | End of mainstream support **13-Nov-2029**; extended **14-Nov-2034** | MS lifecycle |
| WS 2022 | **End of mainstream support 13-Oct-2026** — imminent: plan now | MS lifecycle |
| WS 2016 | End of support **12-Jan-2027** | MS lifecycle |
| Licensing unit | Per **physical core**: *"a minimum of 8 core licenses per physical processor and a minimum of 16 core licenses per server"* | WS2025 licensing guide, **verbatim** |
| Per VM | *"Licensing by virtual machine requires subscription licenses or licenses with active Software Assurance."* | idem, **verbatim** |
| Standard | *"Windows Server Standard provides rights to use two operating system environments (physical or virtual OSEs)"* | idem, **verbatim** |
| Stacking | *"for each additional set of two OSEs or two Hyper-V containers the customer wishes to use, the server must be relicensed for the same number of core licenses."* | idem, **verbatim** |
| Datacenter | *"Windows Server Datacenter provides rights to use any number of operating system environments (physical or virtual OSEs)"* | idem, **verbatim** |
| Azure Local | *"priced per physical core on your on-premises machines, plus any consumption-based charges … All charges roll up to your existing Azure subscription."* | Learn Azure Local, **verbatim** |

**The density calculation, which is the decision:**
- **Standard stacks**: 2 OSEs per full set of server licences. With *N* Windows VMs on
  a host you have to licence the host `ceil(N/2)` times. **The crossover point with Datacenter is
  around 12-14 Windows VMs per host** depending on the negotiated price — **calculate it with your
  contract prices, not with this figure** (§8).
- **Linux VMs do not consume Windows OSEs**, but **the host is still licensed in full**: a host
  with Hyper-V and only Linux guests needs a Windows Server licence for the host. There Hyper-V
  loses its economic advantage and the comparison with KVM flips sign.
- **Standard allows using the physical OSE only to host and manage the virtual ones.** Putting roles
  on the host (file, IIS, domain controller) consumes one of the two OSEs and is besides bad
  security practice.
- **CALs separately**, per user or device, and **they are version-specific**: budget for them together
  with the host upgrade, not afterwards.
- **Datacenter is the mandatory edition for Storage Spaces Direct**: if the design is
  hyperconverged, the edition is already decided and the density calculation is moot.

**Hyper-V role vs. Azure Local:**
- **Hyper-V role on Windows Server**: owned by you, perpetual licence + SA, no cloud dependency.
  It is the default option for classic on-premise virtualization.
- **Azure Local** (formerly **Azure Stack HCI**; renamed by Microsoft) is **a per-core subscription
  billed in Azure**, on **certified hardware**, with Azure Arc as the control plane and
  **a monthly release cadence with short support per version** — it is not "Windows Server under another
  name": it is a product with a cloud dependency and a far more aggressive patching cycle.
- **Criteria**: Azure Local only if there is a real requirement for management from Azure, for Azure services
  on premises or for centrally managed branch offices. If the requirement is "virtualize in my data centre",
  **the Hyper-V role on Windows Server**. Adopting Azure Local without that requirement is replacing a capital
  cost with a subscription and a connectivity dependency.

## 3. Architecture and operation

**Cluster (WSFC)**
- **Homogeneous** nodes in CPU, firmware and OS version. Full `Test-Cluster` before creating the
  cluster and after every hardware change: **without a clean report, the cluster is not supportable**.
- **Quorum always with a witness** (mandatory with an even number of nodes, advisable with an odd one):
  a **cloud** witness or **a file share witness at a third site**; never on a node
  of the cluster itself nor in the same array.
- Separate and redundant networks for management, CSV/storage and live migration. A single
  flat network turns a micro-outage into a cascading failover.

**Storage**
- **CSV** (`C:\ClusterStorage\`) for simultaneous access from every node: a real requirement of
  live migration without copying the disk. **SMB3** (Multichannel + RDMA) is a valid alternative to SAN,
  against a scale-out file cluster, not against a standalone server.
- **Storage Spaces Direct** — non-negotiable requirements: **Datacenter edition**, **2 to 16
  servers** certified in the Windows Server catalog, disks directly attached through an
  **HBA in pass-through mode, not a RAID controller**, the same number and type of disks on every node,
  SSDs with power-loss protection, a network of **at least 10 GbE with RDMA recommended** (iWARP or
  RoCEv2, and RoCEv2 requires configuring the ToR switch). **S2D on unvalidated hardware is the main
  cause of S2D going wrong**: buy a validated solution or do not do it.
- **VHDX always** (not VHD). Fixed or dynamic disk depending on the workload; **pass-through only with a written
  reason** (it breaks checkpoints, backup and migration).

**Network**
- **External virtual switch over SET**. **LBFO is deprecated under Hyper-V**: *"The Hyper-V
  Virtual Switch no longer has the capability to be bound to an LBFO team. Instead, it must be bound
  via Switch Embedded Teaming (SET)"* (Learn, verbatim). A new design over LBFO: forbidden.
- **SR-IOV** only with a demonstrated latency requirement: it bypasses the virtual switch and with it
  port security, QoS and — depending on configuration — live migration. An exception, not a tuning knob.
- VLAN on the VM's port group, not in the guest; consistent MTU (`networking-standards`).

**VM**
- **Generation 2 by default** (UEFI, Secure Boot, SCSI boot, vTPM); generation 1 only for
  guests without UEFI. **The generation cannot be changed afterwards**: it is the VM's irreversible decision.
  Secure Boot on, with the right template for Linux (`MicrosoftUEFICertificateAuthority`).
- **Shielded VMs / guarded fabric with HGS**: they work, but they have been *"no longer in development"*
  since Windows Server 2022 — Microsoft redirects to Azure confidential computing and removed the shielded-VM
  RSAT from the client. **Nothing new is designed on HGS**: if the requirement is protecting the VM
  from the host administrator, solve it with organisational controls and in-guest encryption, and
  leave it written down as an accepted risk.
- **Integration services** up to date (Windows Update on Windows guests, `hv_*` in the Linux
  kernel): without them there is no orderly shutdown, no heartbeat and no consistent backup.

**Operation**
- **A checkpoint is NOT a backup.** It is a delta (`.avhdx`) on the same storage as the
  VM: it does not survive the loss of the volume, it degrades performance and it grows without limit. **Production**
  checkpoints (VSS) only as a rollback for a change window, **with mandatory deletion
  when the window closes**. The real backup belongs to `backup-recovery-standards`.
- **Live migration with Kerberos constrained delegation, not with CredSSP** (which forces you to log
  in on the source node and exposes credentials). A dedicated network, and encryption if it leaves the VLAN.
- **Cluster-Aware Updating** to patch without downtime and **cluster OS rolling upgrade**
  to jump versions without draining it: **the functional level is raised at the end and there is no going
  back** (`Update-ClusterFunctionalLevel`); before that, all nodes updated and stable for days.
- **PowerShell is the default path**, not the advanced alternative: it is the only thing that is reproducible,
  auditable and versionable. Windows Admin Center for diagnosis, not for configuring
  (`powershell-standards`).

## 4. Quality and testing

**Omitted as artificial**: there is no build and no test suite. Operational equivalent: `Test-Cluster` with
a clean report before production and after every hardware change, a provoked failover annually, and the
restore validation from `backup-recovery-standards`.

## 5. Stack security

- **The host is Tier 0**: whoever administers the host administers every VM, their disks and their memory.
  Hyper-V hosts and the cluster are treated with the tiering model from `windows-server-ad-standards`:
  separate administrative accounts, dedicated administrative workstations, **no interactive domain
  administrator session on the host**.
- **Role-based delegation** (Windows Admin Center / PowerShell **JEA**), **never by putting operators
  into the host's local administrators group**: JEA is the mechanism for "restart their VMs and
  nothing else".
- **Isolated management plane**: a dedicated VLAN for host management, BMC/iDRAC/iLO and live migration,
  **with no route from the user network**; WinRM over HTTPS and restricted by source.
- **Server Core** by default on the hosts (less surface and fewer reboots); Desktop Experience
  only with justification. The **host is not a server for anything else**: not files, not a DC, not backup.
- **NTLMv2 is deprecated** in Windows Server 2025 (*"NTLMv2 will continue to work but will be removed
  from Windows Server in a future release"*, Learn, verbatim): authentication between hosts and towards
  the cluster goes over Kerberos. Hardening by Microsoft Security Baselines / CIS; the OS detail belongs
  to `windows-server-ad-standards` and `vulnerability-management-standards`.

## 6. Performance and operability

- The counters that decide: `Hyper-V Hypervisor Logical Processor \ % Total Run Time` (not the host's
  `% CPU`, which lies), memory pressure, per-VHDX latency and CSV queues
  (`observability-standards`).
- **Dynamic memory only where the guest supports it**, never with pinned memory (SQL Server, NUMA
  sensitive), and with a configured minimum and maximum. VMs that do not fit in one NUMA node pay a penalty.
- Cluster capacity reserve for the tolerated failure (N+1): a cluster at 90 % cannot fail over
  and its HA is decorative.

## 7. Long-term sustainability and prohibitions

**Hyper-V is the right answer when:**
- The organisation is already a **Microsoft shop**: an AD domain, mostly Windows guests,
  a team that operates with PowerShell, and Windows Server licences that get paid for anyway.
- **Datacenter is already bought** (or the number of Windows VMs justifies it): the hypervisor effectively
  comes with no incremental licence cost.
- You need natural integration with AD, WSFC, SMB3 and the Windows backup ecosystem.

**It is not when:**
- The estate is **mostly Linux**: you pay for Windows Server on the host for nothing. There
  `proxmox-ve-standards` or `libvirt-kvm-standards` rules.
- You are after a **first-class platform API and automation** for cross-platform infrastructure as
  code: the ecosystem is poorer than KVM's or vSphere's.
- The requirement is **hyperconvergence** and you want neither Datacenter nor validated S2D hardware.
- Operations are Linux and nobody knows PowerShell: the learning curve is not the hypervisor, it is the whole shop.

**Prohibitions:**
- ❌ **FORBIDDEN** to use checkpoints as a backup, and ❌ to leave them alive beyond the change
  window.
- ❌ **FORBIDDEN** to design a new virtual switch over **LBFO**: SET, always.
- ❌ **FORBIDDEN** S2D outside Datacenter, on a RAID controller, with heterogeneous nodes or on
  uncertified hardware.
- ❌ **FORBIDDEN** an even-node cluster **without a witness**, or with the witness hosted in the
  cluster itself or in the same array.
- ❌ **FORBIDDEN** live migration with **CredSSP** in production: Kerberos constrained delegation.
- ❌ **FORBIDDEN** to run application roles, a domain controller or a backup console on the
  Hyper-V host.
- ❌ **FORBIDDEN** to put operators into the host's local administrators group instead of
  delegating by role/JEA.
- ❌ **FORBIDDEN** to raise the cluster functional level before having all nodes updated
  and stable: **there is no going back**.
- ❌ **FORBIDDEN** to design on **shielded VMs / HGS** in new work (no active development).
- ❌ **FORBIDDEN** to budget Standard vs Datacenter with a generic figure: it is calculated with
  contract prices and the real count of Windows VMs per host.
- ❌ **FORBIDDEN** pass-through disks or VHD (not VHDX) without written justification.

## 8. Mandatory web verification

Before pinning anything, check in the primary source (Microsoft Learn, Microsoft lifecycle, the current
licensing guide) and with a date:
1. **Current LTSC version** and whether a successor to Windows Server 2025 already exists with a name and dates.
2. **Exact lifecycle dates** of the deployed version (2016/2019/2022/2025) — the 2022 one
   reaches end of mainstream support in **Oct 2026**.
3. **Current licensing guide**: per-processor and per-server minimums, OSE rights per
   edition, terms of per-VM licensing and CALs. **It changes between versions.**
4. **Declared gap — prices**: no €/core figure or Standard/Datacenter crossover point is written
   down without contract prices or a quote. The crossover point cited in §2
   (12-14 VMs) is indicative and **must be recalculated**.
5. **State of Azure Local**: current name, version, support duration per release and per-core
   pricing model (it was renamed from Azure Stack HCI and its cadence is monthly).
6. **State of shielded VMs / HGS** and of NTLMv2: whether they have gone from deprecated to removed.
7. **S2D requirements** for the specific version and the certified hardware catalog.
8. Recent Hyper-V CVEs (VM escape) and of the cluster stack; patching SLA in
   `vulnerability-management-standards`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
