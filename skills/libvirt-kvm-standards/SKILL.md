---
name: libvirt-kvm-standards
description: Bare KVM/QEMU with libvirt on standalone hosts, with no management platform above it. Use when running virsh, virt-install, virt-xml, virt-clone, virt-manager, virt-viewer, virt-sysprep, virt-customize, virt-df, guestfish or libguestfs tools, qemu-img and qemu-system-x86_64, editing domain XML under /etc/libvirt/qemu, libvirtd.conf, qemu.conf or the modular daemons (virtqemud, virtnetworkd, virtstoraged, virtnodedevd, virtproxyd), defining libvirt storage pools and volumes or virtual networks (default NAT, bridge, macvtap, open vswitch portgroup), pinning a versioned machine type (pc-q35-x.y) instead of an alias, choosing host-passthrough versus a named CPU model, OVMF/UEFI nvram and swtpm virtual TPM, hugepages, numatune and vcpupin, iothreads, qcow2 versus raw versus LVM/zvol backing with cache modes none/writeback/directsync and io=native/io_uring, discard=unmap, VFIO and IOMMU groups for PCI or GPU passthrough, internal versus external snapshots (snapshot-create-as, blockcommit, blockpull), live migration with virsh migrate and what breaks it, or sVirt confinement of the qemu process.
---

# KVM/QEMU with libvirt standards (no management platform)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: bare libvirt **has no cluster, no HA, no backup, no useful RBAC and no operations
> interface**. That is not a defect: it is the scope. If the project needs any of those
> four things, the correct answer is not to build them by hand on top of `virsh`, it is a platform
> (`proxmox-ve-standards`). Using bare libvirt where a platform was needed is this domain's expensive
> mistake, and it is paid for two years later, in production and all at once.

## 1. Scope and triggers

Applies to the **virtualisation substrate**: KVM as the kernel accelerator, QEMU as the user-space
process and libvirt as the API and object model above them, on **individual hosts with no platform**.
It covers the object model, the domain XML and which parts of it matter, VM storage and networking at
a low level, device passthrough, live migration, snapshots, the ecosystem's image tools,
and the security of the QEMU process.

Triggers: `virsh` (`define`, `edit`, `dumpxml`, `start`, `migrate`, `snapshot-create-as`,
`blockcommit`, `blockpull`, `attach-device`, `nodedev-*`, `pool-*`, `vol-*`, `net-*`, `domcapabilities`,
`capabilities`), `virt-install`, `virt-xml`, `virt-clone`, `virt-manager`, `virt-viewer`,
`virt-sysprep`, `virt-customize`, `virt-df`, `guestfish`, `libguestfs`, `qemu-img`,
`qemu-system-x86_64`, `/etc/libvirt/qemu/*.xml`, `/etc/libvirt/qemu.conf`, `/etc/libvirt/libvirtd.conf`,
`virtqemud`/`virtnetworkd`/`virtstoraged`/`virtnodedevd`/`virtproxyd`, `/var/lib/libvirt/images`,
`vfio-pci`, `/sys/kernel/iommu_groups`, `swtpm`, `OVMF_CODE.fd`/`OVMF_VARS.fd`, `machine type`,
`host-passthrough`, `macvtap`, `virtio-blk`/`virtio-scsi`/`virtio-net`.

### 1.1 When bare libvirt and when a platform

**Bare libvirt is the right answer when:**
- It is **one host** (or a few independent ones) and losing that host is an accepted event with a
  procedure, not a disaster.
- It is a lab, a development environment, a test bench or a **CI runner** that creates and destroys VMs.
- The VM infrastructure is **defined as code** (Terraform/Ansible) and the host is cattle, not a
  pet: it is rebuilt from scratch.
- You need fine-grained QEMU control that a platform hides: exotic passthrough, a specific NUMA
  topology, custom devices, confidential computing.

**It is not — and the answer is a platform — when any of these appear:**
- **Automatic failover** is needed when a host goes down: that is HA, and HA requires quorum and
  fencing. `virsh migrate` is a manual operation, not a failover.
- **Backup with retention, deduplication, verification and a proven restore** is needed: libvirt does
  not bring it. Saving `qcow2` files to an NFS share with `rsync` is not a backup plan.
- There are **several operators** who need different permissions: libvirt's real access control is
  membership of the socket's group, which is to say all or nothing over the host.
- There are **dozens of VMs** somebody must operate without reading XML.

**Neighbour**: if the requirement is HA for **Linux services** (not for VMs), that is
`ha-clustering-standards`. Bringing up VMs with Pacemaker + `VirtualDomain` over shared
storage is technically possible and **almost never the right choice versus a platform**:
you add fencing, a cluster filesystem and one more stack to maintain in order to reimplement, worse,
what PVE already brings. If it is done anyway, the quorum, fencing and STONITH criteria belong to that
skill and **are mandatory**, not optional.

**Not applicable**: see `proxmox-ve-standards` (**the sister boundary**: PVE uses KVM/QEMU but **does
not use libvirt** — it manages QEMU with `qemu-server` — so on a PVE node you do not edit domain XML
nor use `virsh`; there live cluster, quorum, HA, fencing, PBS, RBAC, SDN, LXC and the VMware import
assistant. Rule: **if the answer is written with `virsh` or with XML, it belongs here; if it
is written with `qm`/`pct`/`pve*` or by touching `/etc/pve`, it belongs there**), `onprem-standards`
(**umbrella**: its §2 sets the hypervisor choice and its §1.3 the platform invariants),
`ha-clustering-standards` (Pacemaker/Corosync, fencing, resources — §1.1),
`zfs-standards` (**the pool and the zvol underneath**: vdev topology, `ashift`, and above all the
`volblocksize` of the zvol backing a disk — **the pool design and the zvol properties are
theirs; the domain's `<disk>`, its `cache`, its `io` and its `discard` belong here**),
`linux-storage-standards` (LVM and LVM-thin, multipath, iSCSI, NVMe, the filesystems and LUKS backing
the images; `qemu-img` and the image format belong here, `lvcreate`/`multipath -ll` are theirs),
`linux-administration-standards` (the host OS: systemd, journald, cgroups, diagnostics — **the
modular daemons' units and their socket activation are theirs; which daemon to install and why
belongs here**), `linux-hardening-standards` (the host's CIS baseline, unit sandboxing as a
control), `selinux-standards` (**sVirt**: MAC confinement of the QEMU process per domain,
AVC denials, `virt_use_nfs` and friends, libvirt AppArmor profiles — **here, only that sVirt is not
disabled and what breaks when you do**), `networking-standards` (network **design**: VLANs, routing,
addressing; here, only the network model given to the VM),
`firewall-policy-standards` (filtering policy as an artifact; libvirt's `nwfilter` is decided
by that criterion), `iac-standards` (**the Terraform/OpenTofu and Ansible that define the VMs**: there
the module, the state, the CI and drift detection; **here, what the definition must contain for the
VM to be correct and migratable**), `kubernetes-standards` (containerised workloads; and if the question
is "VM or container?", see §3.1), `container-runtime-security-standards` (container isolation;
**a VM is a security boundary, a container is weaker** — Kata Containers lives there),
`observability-standards` (metric and alert design; here, **what** to watch on a KVM host),
`vulnerability-management-standards` (triage of a specific QEMU/kernel CVE),
`incident-response-forensics-standards` (**memory acquisition from a VM**: `virsh dump` is a
mechanism from here, the order of volatility and the chain of custody are theirs),
`cryptography-pki-standards` (certificates for libvirt's TLS transport),
`secrets-management-standards` (`virsh secret-*` and encrypted disk keys),
`windows-server-ad-standards` (Windows guests: **virtio-win** drivers, licensing, AD),
`homelab-standards` (a lab KVM host where the criteria are cost, noise and power draw),
`ctf-lab-standards` (disposable, isolated VMs for detonating binaries: there, isolation is the
purpose), `vmware-standards`, `hyper-v-standards` and `xen-standards` (the other
hypervisors, each with its own skill. **Importing a `.vmdk` or `.vhdx` disk and converting the format
belong here**; **the inventory of what must be migrated, its licensing and what is lost by leaving
belong to the source hypervisor's skill**. A warning all four share: **a hypervisor CVE does not
transfer from one to another** — the patching response belongs to the skill of the affected product).

## 2. Default decisions

> Verify the latest version on the web before committing to it on a real system (§8).

| Area | Default | Justifiable alternative / Forbidden |
|---|---|---|
| QEMU | The branch packaged by the distro with security support; upstream stable as of Aug-2026: **QEMU 11.0** (11.0.3, 24-Jul-2026) — 11.1 still in RC | ❌ Compiling QEMU by hand on a production host and leaving the patch channel |
| libvirt | The distro's; upstream as of Aug-2026: **12.6.0** (03-Aug-2026). Since **12.4.0** the minimum supported QEMU is **7.2.0** | ❌ Mixing a third-party libvirt with the distro's QEMU without verifying the support matrix |
| Daemons | **Modular daemons** (`virtqemud`, `virtnetworkd`, `virtstoraged`, `virtnodedevd`, `virtsecretd`, `virtnwfilterd`), socket-activated | Monolithic `libvirtd` **only** on legacy hosts: upstream will remove it and it is already a dead end. `virtproxyd` only if you need remote access/legacy compatibility |
| Remote access | **`qemu+ssh://`** (authentication and encryption over SSH, opening nothing new) | TLS with an internal PKI and `virtproxyd` if there are many clients; ❌ **plaintext TCP without authentication** (`listen_tls=0` + `auth_tcp="none"`): it is an open remote root host |
| Source of truth | **XML versioned in a repo** applied with `virsh define` (or generated by Ansible/Terraform) | `virsh edit` for diagnosis and one-off changes, **with the change returned to the repo**; ❌ the host as the only copy of the definition |
| `machine type` | **Versioned and pinned explicitly** (`pc-q35-<x.y>`, the most recent **non-deprecated** one) | ❌ Leaving the alias (`q35`, `pc`): on a QEMU upgrade the machine changes virtual hardware under the guest's feet and breaks migration and, on Windows, activation and boot |
| Firmware | **UEFI/OVMF** with per-domain NVRAM; Secure Boot enabled on guests that support it | SeaBIOS only for legacy guests that do not boot via UEFI |
| CPU | **A named model** common to the estate (the highest supported by every host) | `host-passthrough` only on a single host or a homogeneous estate with no migration; ❌ `host-passthrough` + migration between different CPUs |
| Disk | **virtio-scsi** with `discard='unmap'`, `io='native'` (or `io_uring`) and **`cache='none'`** | `virtio-blk` for minimum latency with few disks; ❌ `cache='writeback'` on data that matters (§3.4); ❌ emulated IDE/SATA |
| Format | **raw** over a zvol/LV for performance; **qcow2** over a file when you want snapshots and thin provisioning | ❌ qcow2 **on top of** a zvol or LV (two copy-on-write layers, double amplification); ❌ internal qcow2 snapshots in production (§3.6) |
| Network | **Bridge** to the physical network for VMs that provide a service | NAT (`default`) only for lab and CI; **macvtap** when you want simplicity and accept that **the host cannot talk to the VM** (§3.5); SR-IOV when performance demands it and you accept losing live migration |
| TPM | **swtpm** with an emulated TPM 2.0 on every Windows 11+ guest and on any guest using TPM-bound disk encryption | ❌ An emulated TPM without persistence of its state: it breaks BitLocker on the next boot |
| Snapshots | **External** (`--disk-only` + `blockcommit`) | ❌ **Internal** qcow2 snapshots as routine practice; ❌ any snapshot as a substitute for a backup |
| Backup | **Outside libvirt**: an agent in the guest or a `zfs send` of the zvol after an `fsfreeze` via the guest agent | ❌ Copying a `qcow2` hot without a *freeze* or a snapshot: the resulting image is garbage with a valid format |
| Automation | **cloud-init** (or ignition on Fedora CoreOS/RHCOS) over a clean template made with `virt-sysprep` | ❌ Cloning a VM without `virt-sysprep`: it drags along the machine-id, SSH host keys, MAC and hostname |

## 3. The model and the XML that matters

### 3.1 Object model

- Objects: **domains** (VMs), **storage pools** and their **volumes**, **networks**, **secrets**,
  **nwfilters** and **node devices**. Each with its XML, its `virsh` commands and its
  `define` → `start` → `autostart` lifecycle.
- **`virsh` is the real interface and the API is the source of truth**; `virt-manager` is a
  convenient client for inspection and for the 5% of interactive operations, **not the way to manage
  an estate**. Anything done more than twice is not done through a GUI.
- `define` is persistent, `create` is transient (it disappears when stopped). A domain created with
  `create` that "was lost on reboot" was not lost: it never existed on disk.
- **libvirt normalises and completes the XML when defining it**: what you write is not what remains.
  `virsh dumpxml` on an **active** domain shows the running configuration, which may differ from the
  persistent one (`--inactive`). Always diagnose knowing which one you are looking at.
- libvirt storage pools are a convenience, not a management layer: over ZFS or LVM the real work
  is done by `zfs`/`lvm` and the pool is a wrapper. Use them if they simplify; do not depend on them.
- **VM or container**: the VM provides **its own kernel and a real security boundary**; the
  container provides density and fast startup. Multi-tenancy, untrusted code, a different kernel
  or a regulatory isolation requirement → **VM**. Everything else, a container
  (`kubernetes-standards`, `podman-systemd-containers-standards`).

### 3.2 `machine type`: pin it or it will break you

- Versioned types **freeze the virtual hardware** the guest sees. It is what makes migration possible
  and what stops an `apt upgrade` of QEMU changing the motherboard of a running VM.
- **Verified QEMU policy**: versioned types are supported for **6 years ≈ 18 releases**; they are
  marked **deprecated after 3 years (9 releases)** and **removed 3 years later**. As of today, **all
  those of version `8.1.0` or earlier are deprecated**. Verbatim from the documentation: *"Newly deployed
  VMs should exclusively use a non-deprecated machine type, with use of the most recent version highly
  recommended."*
- **QEMU refuses to start a VM with a removed type.** QEMU 11.0 removed `pc-i440fx-2.6`,
  `pc-q35-2.6`, `pc-i440fx-2.7` and `pc-q35-2.7`. An upgraded host with old VMs **does not boot** them, and
  you find out after the reboot.
- Procedure: audit the `machine` of every domain against the deprecated list **before**
  every QEMU upgrade, and raise them during a service window (shut down → edit → start; not
  hot). A deprecated type is only kept in order to **receive migrations and restore saved
  state** from pre-existing VMs.
- **Never use the alias** (`q35`, `pc`) in the definition: it resolves to "whatever is newest today" and
  turns every upgrade into a lottery. On Windows, a machine change can invalidate
  activation.

### 3.3 CPU, NUMA and memory

- `host-passthrough` gives all the host's extensions and **pins the VM to that CPU**: no migration to
  different hardware, no boot after changing host. Fine for a single host; it is a trap in an
  estate.
- **A named model** (with `check='full'`) is what allows a migratable estate: you choose the highest
  model supported by **every** host, and document it as an estate decision. The specific
  flags are checked with `virsh domcapabilities` and `virsh cpu-baseline`/`hypervisor-cpu-baseline`,
  **not from memory**.
- **Nested virtualisation: disabled unless there is a demonstrated need** (see §5, Januscape). If the
  guest is not going to run another hypervisor, do not give it to them.
- **Hugepages** (2 MiB, or 1 GiB on very large VMs) reduce TLB pressure on memory-heavy workloads;
  they require a host reservation and **disabling ballooning** for that VM.
- **NUMA**: on multi-socket hosts, a VM crossing NUMA nodes without pinning loses performance
  silently and irregularly. With large VMs: `numatune` + `vcpupin` + `memnode` consistent with
  the real topology (`virsh capabilities`, `lscpu`, `numactl -H`), and a virtual topology exposed to
  the guest. On small VMs, pinning is over-engineering that gets in the scheduler's way.
- **`iothreads`**: dedicated I/O threads assigned to virtio disks; they separate I/O from the vCPU and stop
  a slow disk blocking the VM. One per disk with real load; not one per disk "just because".
- `<memballoon>` is useful in a lab and **gets in the way in production** with sized memory: pin the
  memory and disable it on databases, JVMs and workloads with hugepages.

### 3.4 Storage and caching

- **Choosing the backing**, on real criteria: `raw` over a **zvol or LV** = maximum performance and
  snapshots delegated to the layer below (which does them better); **qcow2 over a file** = snapshots,
  thin provisioning, backing chains and portability, at the cost of a layer of indirection.
- **Never stack copy-on-write**: qcow2 over a zvol or over LVM-thin doubles write amplification
  and consumption. If the backend already does CoW, the format is `raw`.
- **Cache modes and what they mean in a power cut** — the criterion is integrity, not the
  benchmark:
  - **`cache='none'`** — direct I/O to the backend, bypassing the host page cache, **honouring the
    guest's flushes**. It is the correct default and the only one allowing live migration with
    shared storage without tricks.
  - **`cache='directsync'`** — like `none` but with every write synchronous as well. Maximum safety,
    worse performance; for what cannot lose a write and has no protection of its own.
  - **`cache='writeback'`** — uses the host cache and **trusts the guest to issue flushes**. A
    guest that does not issue them (or a host failure) loses data already acknowledged. Acceptable in
    a lab and on rebuildable workloads; **forbidden on data that matters**.
  - `cache='unsafe'` **ignores flushes**: only for disposable installations and CI builds.
- The backend rules too: a zvol or LV **without a battery-protected write cache or honest flushes**
  is not saved by QEMU's cache mode. Integrity is a property of the whole stack.
- **`discard='unmap'` + `detect_zeroes`** so that deletion inside the guest frees space in
  the thin pool; with `fstrim.timer` active in the guest. Without this, a thin pool only grows.
- Performance: `io='native'` (AIO) or `io_uring` depending on what your QEMU/kernel supports; measure with `fio`
  **inside the guest** against the same workload profile, not with `dd`.

### 3.5 Networking

- **Bridge** to the physical segment: the VM is just another machine on the network. It is the default case
  for serving.
- **NAT (`default`)**: convenient, isolated and **sufficient for lab and CI**. In production it creates
  a dependency on `dnsmasq` on the host and complicates any inbound flow.
- **macvtap**: fewer layers and good performance, with a **known and surprising limitation**: the
  host **cannot talk to its own VMs** over that interface (the traffic does not come back through the NIC).
  It breaks any agent, backup or monitoring running on the host that queries the VM. In addition,
  many switches do not accept multiple MACs per port without prior configuration.
- **SR-IOV / VF passthrough**: near-native performance in exchange for **losing live migration** and
  tying you to the NIC model. A conscious and documented decision, not opportunistic optimisation.
- A consistent MTU along the whole path (bridge, bond, switch, VM): a misaligned MTU shows up as
  "it works fine until I transfer a large file".
- libvirt's `nwfilter` is good for basic per-VM anti-spoofing (MAC/IP); **it is not the environment's
  firewall policy**, which is decided in `firewall-policy-standards`.

### 3.6 Snapshots

- **External** (`virsh snapshot-create-as --disk-only [--quiesce]`): they create an overlay and leave the
  base image intact. They are consolidated with **`blockcommit`** (overlay → base) or discarded. It is the
  supported model and the one that allows copying the base cold.
- **Internal** (inside the qcow2): convenient and fragile — they corrupt more easily, degrade
  performance as layers accumulate and their support is worse. **Not in production.**
- **`--quiesce` requires the `qemu-guest-agent` in the guest**: it is what freezes the filesystems and
  makes the snapshot *crash consistent* instead of "whatever happened to be on the disk at that instant".
  Without the agent, a snapshot of a database is a gamble.
- **A snapshot with memory is not a backup.** It restores the RAM state and returns a live VM at
  the captured instant — with expired connections, expired Kerberos tickets, the clock
  behind and, if the snapshot is later than the compromise, with the attacker inside. It lives on the same
  storage as the original and dies with it.
- **Snapshot chains get consolidated.** A VM with six overlays accumulated over months is
  a failure in progress: degraded performance and a chain that, if it breaks in the middle, takes the
  whole VM with it. Inventory and prune.

### 3.7 Live migration

Requirements, all simultaneously:
1. **A compatible CPU** at the destination: the same named model or a superset. `host-passthrough` between
   different CPUs breaks it.
2. **The same `machine type`** available in the destination's QEMU (and not removed, §3.2).
3. **Storage**: shared and visible at the **same path** on both hosts, or block
   migration (`--copy-storage-all`/`--copy-storage-inc`), which is much slower and loads the network.
4. **The destination's QEMU/libvirt equal or newer**: backwards is not supported.
5. **Network**: connectivity between hosts for the migration stream, and the VM keeping its L2 on arrival
   (same bridge/VLAN).

What else breaks it: **passthrough devices (VFIO/SR-IOV)**, `<hostdev>` without `failover`,
disks with `cache='writeback'` on shared storage, and local files the VM has
open that the destination does not have. **Migration ≠ HA**: it is a manual operation for maintenance; if
the source host dies, there is no migration to do.

### 3.8 Device passthrough

- Preconditions: **IOMMU enabled** in firmware and kernel (`intel_iommu=on` / `amd_iommu=on`), and the
  device bound to **`vfio-pci`** before its native driver takes it.
- **The IOMMU group is the unit of isolation, not the device.** If there are more devices in the
  group, **they all go** or none does. Check `/sys/kernel/iommu_groups` **before**
  promising anything.
- **`pcie_acs_override` and similar patches break the isolation guarantee** between devices
  in the group: acceptable in your own lab, **forbidden in production and in multi-tenancy**.
- **GPU passthrough**: known traps — the host's primary GPU needs `vfio-pci` from
  boot or a stub, the **complete function group** must be passed (video + HDMI audio), the
  card's firmware (vBIOS) may need to be dumped, and the GPU's reset state may
  prevent starting the VM twice without rebooting the host. Budget integration time; it is not
  a checkbox.
- **Passthrough sacrifices live migration, suspend and, often, snapshots.** It is a trade-off,
  and it must be declared before committing to availability.
- Security surface: a passed-through device means DMA towards the host mediated by the IOMMU. With a
  badly configured IOMMU or with ACS overrides, **the guest can write host memory**.

### 3.9 Ecosystem tools

- **`qemu-img`**: `create`, `convert` (format and backend change), `info`, `check`, `resize`,
  `snapshot`. Run `qemu-img check` on a suspect qcow2 **before** starting it.
- **libguestfs**: `guestfish` (a shell over the guest's filesystem), `virt-df`, `virt-cat`,
  `virt-ls`, `virt-inspector`. **Never on the image of a running VM** except in read-only
  mode and knowing the view is inconsistent; writing to a live VM's image corrupts it.
- **`virt-sysprep`**: mandatory before turning a VM into a template — it erases the machine-id, SSH
  host keys, logs, histories, persistent network rules and credentials. Without it, all the
  cloned VMs share an identity (and DHCP and logging go mad).
- **`virt-customize`**: offline image customisation (packages, files, passwords) to
  build reproducible templates from code.
- **`virt-install` / `virt-xml`**: creating and modifying domains from a script, preferable to
  editing XML by hand in automation. `virt-clone` to clone (and **afterwards** `virt-sysprep`).
- **`virt-viewer`** (SPICE/VNC) for the console; the serial console (`virsh console`) is the one that saves you
  when the guest's network does not come up — configure it **before** needing it.

## 4. Quality gates

Before accepting a host or a VM definition:

1. **`machine type` audit**: no domain with a type deprecated or removed in the installed
   QEMU. It is checked **before** every QEMU upgrade, not after the reboot.
2. **XML in a repo**: `virsh dumpxml --inactive` of every domain matches the versioned definition.
   A difference = drift, and it is a finding.
3. **Estate CPU consistency**: every domain on the agreed named model; exceptions
   with `host-passthrough` listed and justified (and flagged as non-migratable).
4. **Cold boot tested**: the VM starts after a full host reboot, with `autostart` where
   appropriate and without manual intervention.
5. **A working serial console** on every production Linux VM (`virsh console`), verified.
6. **`qemu-guest-agent` active** on every guest: without it there is no `--quiesce`, no orderly shutdown, and no
   reported IPs.
7. **A proven restore**: rebuild a VM from its definition + its data copy, timed. If
   there is no copy with a proven restore, **the host is not in production** (`onprem-standards` §1.3).
8. **Clean snapshot chains**: no domain with accumulated overlays with no date or owner.
9. **sVirt active**: SELinux/AppArmor in enforcing mode and confining every domain; verified in the
   process labels, not assumed.
10. **No plaintext libvirt transport**: `qemu+tcp` without auth or TLS is a blocking failure.
11. **Patched versions**: kernel/KVM and QEMU up to date against the current escape CVEs (§5),
    verifying the **booted kernel**, not the installed package.

## 5. Security

- **A VM is a real security boundary, but it is not infinite.** QEMU is an enormous user-space
  process with emulated devices; guest→host escapes exist, are published and **are
  exploited**. Operational corollaries: reduce emulated devices to those needed, patch fast
  and do not treat "it's in a VM" as the end of the analysis.
- **Reference CVEs verified as of Aug-2026** (re-verify their status and search for later ones, §8):
  - **Januscape — `CVE-2026-53359`** (disclosed 06-Jul-2026): a **guest → host** escape in KVM's x86
    shadow MMU, affecting both Intel VMX/EPT and AMD SVM/NPT. **Patching 53359 is not enough**: full
    remediation also requires **`CVE-2026-46113`** (fixed May-2026, the *leaf shadow page* case;
    53359 covers the *non-leaf* one). Mitigation meanwhile: **disable nested
    virtualisation** where it is not essential.
  - **Escape via `virtio-snd` in QEMU** (Mar-2026): a heap overflow turned into a reliable escape,
    **with a public exploit**. Derived rule: **do not expose emulated devices the workload
    does not need** — audio, USB, webcam, extra serial ports. Every device is surface.
  - **`CVE-2026-0665`**: an off-by-one in QEMU's Xen-on-KVM support (`physdev` hypercall),
    out-of-bounds accesses from a malicious guest.
- **Nested virtualisation off by default.** It is the mitigation that appears again and again, and almost
  no VM needs it.
- **sVirt is mandatory**: SELinux (`svirt_t`/`svirt_image_t`) or AppArmor label each domain so
  that a compromised QEMU cannot reach the others' images. **Disabling SELinux/AppArmor "so the VM
  starts" removes the only control that contains a partial escape**; the correct diagnosis
  belongs to `selinux-standards` (booleans like the NFS ones, `virt-*`, image contexts). It is not
  disabled: it is labelled properly.
- **QEMU runs as an unprivileged user** (`qemu:qemu`, configurable in `/etc/libvirt/qemu.conf`).
  Never as root "to simplify permissions": if a file is not accessible, permissions and
  labels get fixed.
- **The libvirt socket is effectively root over the host.** Belonging to `libvirt`/`libvirt-qemu`
  is equivalent to being able to start a VM that mounts the host's disk: **treat it as passwordless sudo** and
  do not hand it out. libvirt **has no useful RBAC** (`polkit` gives coarse control); if you need
  per-VM and per-person permissions, you need a platform (§1.1).
- **Transport**: `qemu+ssh://` by default; TLS with an internal PKI if needed. **`auth_tcp="none"`
  is handing over remote root**; there is no justification in production.
- **Encryption at rest**: LUKS underneath (host) or the backend's native encryption; qcow2's
  internal encryption only with judgement and with the key managed by `virsh secret-*` and held outside.
- Untrusted guests: a dedicated VM, an isolated network, zero passthrough, zero shared folders, and
  the host treated as potentially reachable. If the purpose is detonating malware, the isolation
  criteria belong to `ctf-lab-standards`.
- **Forensic acquisition**: `virsh dump` (or a snapshot with memory) captures a live VM's RAM without
  touching the guest — an excellent mechanism. The order of volatility, the hash and the chain of custody
  belong to `incident-response-forensics-standards`.

## 6. Performance and operability

- **What to watch** (the stack's design belongs to `observability-standards`): the state of each domain,
  `steal time` in the guests, host memory pressure and swap activity (**a virtualisation host
  should never page**), backend I/O latency and saturation, `virtio`
  errors, temperature/SMART, and the status of the last copy and the last proven restore.
- The libvirt exporter/`libvirt_exporter` gives per-domain metrics; without it, "the VM is slow" is
  unsolvable.
- **Overcommit**: vCPUs are overcommitted with measurement (`steal` as the signal); **memory is not**,
  except with ballooning that is understood. A host that swaps drags all its VMs down at once.
- **Orderly host shutdown**: `libvirt-guests` (or equivalent) configured to **suspend or
  shut down the domains cleanly** when stopping the host, and tested. A cut that kills 20 VMs at once
  produces 20 filesystems to check.
- **Startup**: `autostart` on the domains that must come back on their own, and **ordering/delay** between them if
  there are dependencies (database before application). Checked with a real reboot.
- **The modular daemons are socket-activated** and exit on inactivity (typically
  `--timeout=120`), restarting when a client arrives. **Restarting `virtqemud` does not interrupt the
  running guests** — but avoid it with live VMs if you can.
- Capacity: reserve memory and CPU for the **host** (I/O, ZFS ARC, monitoring). Sizing
  100% of the RAM into VMs is how you get to a host that swaps.

## 7. Sustainability and prohibitions

**Cadence**
- QEMU and kernel/KVM: security patches at the distro's cadence, and **out of cycle in the face of an
  escape CVE** with a public exploit. It requires shutting down/restarting the VM (or the host, for the kernel):
  plan the window, do not improvise it.
- libvirt: follow the distro's branch; read the `NEWS` before a major jump (e.g. **12.4.0
  raised the minimum QEMU to 7.2.0**).
- **An annual `machine type` audit** of the whole estate against the deprecated list, with an upgrade
  plan. It is the debt that collects itself at the worst moment.
- Migration from monolithic `libvirtd` to **modular daemons** with a date: upstream will remove it and
  the distros already default to it on new installations.
- `virtio-win` on Windows guests: update it with the guest tools, do not leave it at
  the version from the installation.

**FORBIDDEN**
- ❌ Using bare libvirt where the real requirement was HA, integrated backup or multi-operator RBAC (§1.1);
  reimplementing a platform out of scripts on top of `virsh`.
- ❌ A `machine type` alias (`q35`, `pc`) in a definition; leaving deprecated types with no plan.
- ❌ Upgrading QEMU without first auditing the estate's `machine type`s.
- ❌ `host-passthrough` in an estate that must migrate between different hosts.
- ❌ Nested virtualisation enabled "just in case" (§5).
- ❌ `cache='writeback'` (let alone `unsafe`) on data that matters.
- ❌ qcow2 over a zvol or over LVM-thin; internal qcow2 snapshots in production.
- ❌ Copying an image hot without `--quiesce`/a snapshot and calling it a backup.
- ❌ Treating a snapshot — with or without memory — as a backup.
- ❌ Leaving overlay chains unconsolidated and without an owner.
- ❌ `qemu+tcp` without TLS or authentication; `auth_tcp="none"`.
- ❌ Handing out `libvirt` group membership as if it were a read permission: it is root on the host.
- ❌ Running QEMU as root; disabling SELinux/AppArmor so a VM will start.
- ❌ `pcie_acs_override` or equivalents in production or in multi-tenancy.
- ❌ Cloning a VM without `virt-sysprep`.
- ❌ Editing a running VM's image with libguestfs.
- ❌ A production VM without `qemu-guest-agent` or a serial console.
- ❌ The host as the only copy of the domain definition (XML only in `/etc/libvirt`).
- ❌ Overcommitting memory until the host swaps.
- ❌ Running a hand-compiled QEMU in production, outside the security patch channel.

## 8. Mandatory web verification

Before committing to any version, policy or feature name, **search for it — do not remember it**. What
was verified as of Aug-2026 and what remains open:

1. **QEMU**: verified **11.0.0 (22-Apr-2026)** as the latest stable of the series (point release **11.0.3**,
   24-Jul-2026); **11.1 still in RC** (11.1.0-rc2, 29-Jul-2026) — check whether it has been released. Verified
   that 11.0 **removes** `pc-i440fx-2.6`, `pc-q35-2.6`, `pc-i440fx-2.7` and `pc-q35-2.7` and **drops
   support for 32-bit hosts**.
2. **Machine type policy**: verified literally at `qemu.org/docs/master/about/deprecated.html`
   — 6 years/18 releases, deprecation after 3 years/9 releases, removal 3 years later, and **all
   `8.1.0` or earlier deprecated today**. **Re-read that page before every upgrade**: the list
   moves with each release.
3. **libvirt**: verified **12.6.0 (03-Aug-2026)** as the latest published (12.5.0 on 01-07-2026,
   12.4.0 on 01-06-2026, which **raised the minimum QEMU to 7.2.0**). Read the `NEWS` of the versions you
   skip.
4. **Modular daemons**: verified the split of responsibilities (`virtqemud` and company,
   `virtproxyd` for remote/legacy, socket with `--timeout=120`, restart without cutting off guests) and that
   upstream **will remove `libvirtd`**. **Declared gap**: no **specific date** for the removal of
   `libvirtd` has been confirmed, nor the exact status per distribution beyond RHEL 9 (new
   installations modular, upgrades from RHEL 8 monolithic) and SUSE. Confirm it for your distro.
5. **CVEs**: verified **CVE-2026-53359 ("Januscape", 06-Jul-2026)**, the dependency on
   **CVE-2026-46113** for full remediation, the **`virtio-snd` escape** of Mar-2026 with a
   public exploit, and **CVE-2026-0665** (Xen on KVM in QEMU). **Search for later CVEs** in QEMU,
   kernel/KVM and libvirt before setting a minimum version, and consult **your** distribution's advisory:
   upstream version numbers do not map mechanically to the packages.
6. **Additional declared gaps** (not verified on the web in this drafting; the criteria rest
   on the stack's documented behaviour, **confirm them before quoting them as fact**):
   - The **exact matrix of cache modes** (`none`/`writeback`/`directsync`/`unsafe`) against
     `cache.direct`/`cache.writeback`/`cache.no-flush` and their interaction with live migration in
     the installed QEMU version: read it in libvirt's documentation for `<driver cache=…>`.
   - The **status of `io_uring`** as a supported and recommended I/O backend in your QEMU/kernel.
   - The **macvtap host↔VM limitation** (§3.5): known and stable behaviour of the stack, but
     not re-verified against a primary source in this drafting.
   - The status and options of **confidential computing** (AMD SEV-SNP, Intel TDX) in libvirt
     and QEMU 11.x, which QEMU 11.0 extended with reboot support: **not covered in this document**.
   - The support policy for **`virtio-win`** and its recommended version for each Windows.
7. **Before any cross-upgrade** (libvirt ↔ QEMU ↔ kernel ↔ storage backend): the
   distribution's compatibility matrix, not intuition.

If the web contradicts this document, **the web wins** — flag the discrepancy.
