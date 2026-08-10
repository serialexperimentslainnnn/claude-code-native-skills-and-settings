---
name: os-provisioning-standards
description: Unattended OS installation on bare metal and VMs — network boot and the answer file that drives the installer. Use when configuring PXE or UEFI HTTP Boot with dnsmasq, pxelinux.0, syslinux, grubx64.efi, shimx64.efi, iPXE (undionly.kpxe, ipxe.efi, chainloading, embedded scripts), DHCP option 66/67, option 60 HTTPClient vendor class or DHCPv6 option 59 bootfile-url, TFTP versus HTTP boot, writing a Kickstart ks.cfg with %packages/%pre/%post and inst.ks=, a Debian preseed.cfg with d-i directives, a SUSE Agama JSON profile replacing AutoYaST autoinst.xml, Ubuntu autoinstall.yaml or subiquity.autoinstallpath, cloud-init NoCloud seed ISOs and the user-data / meta-data / vendor-data / network-config split with ds=nocloud and seedfrom, Butane .bu transpiled to Ignition .ign for Fedora CoreOS or RHCOS, Windows unattend.xml with WDS or Configuration Manager OSD after MDT retirement, golden images versus scripted installs, building images with mkosi, osbuild, image-builder or Packer, installing an image-mode host to disk, driving Cobbler, Foreman, MAAS or Tinkerbell, powering on hardware remotely with Redfish or ipmitool to boot an installer, or making a freshly installed host register itself in the inventory and the configuration management system.
---

# Operating system provisioning standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **how an operating system reaches a disk without anyone touching a key**: network boot
(PXE/BIOS, UEFI HTTP Boot, iPXE, the DHCP→TFTP/HTTP→bootloader→installer chain), the answer file
of each installer, the **golden image versus scripted install** decision, the
tools that build the image, the provisioning orchestrators, remote power-on of
the hardware (Redfish/IPMI) and —what is almost always missing— the **closing of the loop**: the freshly
installed machine registers itself in the inventory and in the configuration manager, or the provisioning
is not finished.

**Guiding principle**: **provisioning does not end when the installer reboots; it ends when the
host appears in the inventory, in the configuration manager and in monitoring.** The second
principle: **a reproducible install is proven by reinstalling**, not by reading the profile.

Triggers: `pxelinux.0`, `shimx64.efi`, `grubx64.efi`, `ipxe.efi`, `undionly.kpxe`, `dnsmasq.conf`
with `dhcp-boot`/`pxe-service`, DHCP options **66/67**, **option 60 `HTTPClient`**, DHCPv6 **option
59 `bootfile-url`**, `ks.cfg`, `inst.ks=`, `%pre`/`%post`/`%packages`, `preseed.cfg`, `d-i`,
`autoinst.xml`, **Agama** JSON profile, `autoinstall.yaml`, `subiquity.autoinstallpath`,
`user-data`/`meta-data`/`vendor-data`/`network-config`, `ds=nocloud`, `seedfrom`, `cloud-localds`,
`.bu`/`.ign`, `butane`, `unattend.xml`, `boot.wim`, WinPE/ADK, `mkosi.conf`, `osbuild`,
`image-builder`, `bootc install to-disk`, Packer, Cobbler, Foreman, MAAS, Tinkerbell
(Smee/Tootles/HookOS/Tink), `ipmitool chassis bootdev pxe`, Redfish `ComputerSystem.Boot`,
"install 40 identical servers", "the kickstart used to work and now it doesn't".

**Not applicable**: see `onprem-standards` (**platform umbrella and routing table §1.2**; its
§1.3 invariants win, in particular *no snowflakes* and *every server rebuildable from
code* — **this skill is the mechanism that makes that true**), `cmdb-inventory-standards` (**the
register where the new host lands**: data model, stable identifier, reconciliation —
here only the *hook* that registers it), `server-hardware-standards` (the hardware and its BMC: firmware,
management network, warranty — **here only Redfish/IPMI as a boot trigger**),
`iac-standards` (**Ansible/Terraform and the code that configures the machine *after* the first
boot**; the exact boundary: **up to the first login this skill wins, from the first login
onwards `iac-standards` wins** — and a Kickstart `%post` acting as a configuration manager
is a vetoed antipattern, §7), `linux-administration-standards` (the already-installed OS),
`rhel-fedora-standards` (**`rpm-ostree`, `bootc`, image mode and `dnf` as the ecosystem of the
Red Hat family**; here `bootc install` only as an installation method), `linux-hardening-standards` (the
CIS/STIG baseline over what is installed: **a hardened golden image does not replace measuring the
baseline**), `proxmox-ve-standards`, `libvirt-kvm-standards`, `vmware-standards` (**the VM
template and cloning are theirs**: `qm clone`, `virt-sysprep`, vSphere templates; here the `cloud-init`
that customises it and the installer that creates it), `windows-server-ad-standards` (domain and GPO),
`macos-fleet-standards` (DEP/ADE and MDM: **Apple provisioning does not go through PXE**),
`cicd-standards` (the pipeline that builds the image), `network-troubleshooting-standards` (**"PXE
does not boot" as reactive diagnosis**), `bcdr-standards` (rebuild as a recovery
strategy), `homelab-standards` (proportionality: a `cloud-localds` and an ISO are enough, do not stand up
Foreman), `datacenter-facilities-standards` (rack, power and the physical
journey of the server before an IP exists), `hpc-standards`
(mass node provisioning, diskless boot, `xCAT`/Warewulf).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Boot transport | **UEFI HTTP Boot** (option 60 `HTTPClient` + option 67 with a **full URI**) | TFTP has neither flow control nor integrity and chokes on large images. PXE/TFTP only for firmware that does not support HTTP Boot; **legacy BIOS only on hardware that will not boot any other way** |
| Boot chain | **iPXE** chainloaded from the firmware, with an embedded and signed script | It gives you HTTP(S), scripting, retries and decisions by MAC/UUID; plain `pxelinux` does not. Alternative: `shim`+`grub` when Secure Boot demands the chain signed by the distribution (§5) |
| Minimum server | `dnsmasq` (DHCP proxy + TFTP) + an HTTP serving the artifacts | Enough and auditable for dozens of hosts. `dnsmasq` in **proxy-DHCP mode** if the corporate DHCP is not yours |
| Answer file | The **distribution's native one**: Kickstart (RHEL/Fedora), preseed (Debian), **Agama JSON** (SLES 16+), `autoinstall.yaml` (Ubuntu), Butane→Ignition (CoreOS/RHCOS), `unattend.xml` (Windows) | There is no common abstraction worth having; multi-distro wrappers break at every release |
| SUSE | **Agama** (JSON/Jsonnet profile) | **SLES 16 replaces YaST/AutoYaST with Agama**; AutoYaST does **not** migrate 1:1 (§8). On SLES 15 AutoYaST still applies |
| VM customisation in cloud/template | **cloud-init**, **NoCloud** datasource for on-prem | De facto standard. **Ignition** when the OS is immutable (CoreOS/RHCOS): it runs once in the initramfs and does not reconfigure on every boot |
| Image versus install | **Image built in a pipeline** for a homogeneous, ephemeral fleet; **scripted install** for heterogeneous, long-lived hardware | Rule: if you are going to reinstall more than you are going to patch, image; if not, install + configuration manager |
| Image builder | `mkosi` (declarative, from the systemd project, UKI out of the box), **osbuild's `image-builder`** in the RHEL world, Packer when the target is a hypervisor or a cloud | **`bootc-image-builder` has an announced deprecation** towards `image-builder` (§8) |
| Image OS | `bootc` / image mode when the fleet tolerates the bootable-container model | Upstream **v1.16.7 (4-Aug-2026)**, weekly cadence; **the repository lives at `bootc-dev/bootc`** |
| Orchestrator | **Foreman** with a mixed fleet and a long lifecycle; **MAAS** if the estate is Ubuntu and you want machines as a resource; **Tinkerbell** if the consumer is Kubernetes/Cluster API | **Cobbler** only if it is already there: still maintained but has spent years in the 3.3.x→4.0.0 transition. None of them if there are fewer than ~20 hosts: `dnsmasq` + HTTP + repo |
| Power-on and boot selection | **Redfish** (`Boot/BootSourceOverrideTarget`) | `ipmitool` only where there is no Redfish. BMC detail and its network: `server-hardware-standards` |

## 3. Structure and conventions

- **One provisioning repository**, versioned, with: profiles by role (not by host), answer file
  templates, iPXE scripts, and the artifact manifest (ISO/kernel/initrd) **with
  its checksum**. Everything the boot server serves comes out of there.
- **The profile is per role and the per-host difference is data, not template.** Hostname, IP, VLAN, role and
  owner are queried from the inventory at provisioning time (by MAC or by DMI serial
  number), not copied into 40 files. One profile per host is the first symptom of a *snowflake*.
- **`user-data`, `meta-data`, `vendor-data` and `network-config` are four different things** and
  confusing them is failure no. 1 with cloud-init. Literal from the 26.2 documentation: *"Cloud-init
  discovers four types of configuration at runtime"* (the four above, the **runtime
  configuration**) and *"The purpose of the discovery configuration is to tell cloud-init where it can find
  the runtime configurations"* (`ds=nocloud`, `seedfrom`, DMI or the kernel command line: the **discovery
  configuration**). Operational consequences: the instance identity (`instance-id`) goes in
  `meta-data` and **changing it re-runs the `per-instance` modules**; the network **cannot be
  changed from `user-data`** (it goes in `network-config`, in the system config or on the kernel
  command line); `vendor-data` belongs to the platform provider, not to you.
- **NoCloud without a server**: seed on an ISO/vfat with `user-data`, `meta-data` and optionally
  `network-config` (`cloud-localds -N`). With a server: `ds=nocloud;s=https://…/` — and `seedfrom`
  supports `__dmi.varname__` expansion, which is the clean way to **serve configuration by chassis
  serial number** without per-host templates.
- **Butane/Ignition**: you write `.bu` and transpile it with `butane --strict`; **the `.ign` is a
  generated artifact and is not edited by hand**. Pin `variant: fcos` and a **stabilised version**
  (as of Aug 2026 the latest stable is **1.7.0 → Ignition 3.6.0**; 1.8.0 is experimental and the
  documentation itself warns: *"Do not use experimental specifications for anything beyond development
  and testing as they are subject to change without warning or announcement"*).
- **Windows**: `unattend.xml` with Configuration Manager OSD or your own WinPE from the ADK. **MDT has been
  retired since 6-Jan-2026** (no updates, downloads withdrawn) and **WDS no longer supports
  deploying Windows 11 or Server 2025 with the `boot.wim` from the installation media**; WDS PXE
  still works with your own boot image (§5 for the security side).
- **Deterministic names and partitioning**: explicit partitioning scheme in the profile (never
  "use the whole disk" on hardware with an array attached), disk selection by WWN/serial and not by
  `/dev/sda`, and predictable interface names. An installer that picks by enumeration order
  installs on the wrong LUN sooner or later.

## 4. Validation: how you know it works

- **Gate 1 — syntax, on every commit**: `ksvalidator` (Kickstart), `butane --strict`,
  `cloud-init schema --config-file`, `autoinstall.yaml` schema validation, `mkosi` in build
  mode. Cheap and it catches half the failures.
- **Gate 2 — real install on an ephemeral VM, on every profile change**: the VM is brought up,
  provisioned from scratch and assertions are checked (users, network, partitioning, packages, services,
  inventory registration). Without this gate, the profile is validated in production.
- **Gate 3 — install on representative hardware, per distribution release**: firmware, NIC,
  controller and disk change the outcome. A profile validated only on a VM **is not validated for
  bare metal**.
- **Periodic reinstall as an exercise**: one host of each role is reinstalled from scratch in an agreed
  window. It is the only proof that "rebuildable from code" is true and that the distribution's
  artifact is still available.
- **Provisioning time measured** (from power-on to host in inventory and monitoring):
  it decides whether the image model is worth it, and it makes a DR plan credible.

## 5. Security: network boot is not authenticated

**The critical point of this skill.** The DHCP→TFTP→bootloader sequence **authenticates nothing by
default**: anyone in the same broadcast domain can answer DHCP before you do and serve
their own bootloader. Controls, in order:

- **Isolated provisioning network** (its own VLAN, no internet egress, no users). It is the
  primary control; the rest are defence in depth.
- **DHCP snooping** on the access switch: it blocks unauthorised DHCP servers. **And it breaks your
  provisioning if your server sits on an untrusted port** — the conflict is real and is
  resolved by declaring the boot server's port *trusted*, not by disabling snooping.
- **HTTPS instead of TFTP/HTTP** for everything you can (UEFI HTTPS Boot requires the root
  certificate enrolled in the firmware) and **verified integrity**: artifact checksum in
  the iPXE script.
- **Secure Boot active during installation too**: `shim`→`grub`→kernel chain signed.
  **Calendar warning, Aug 2026**: the **Microsoft Corporation KEK CA 2011 expired on 27-Jun-2026** and
  the **Windows Production PCA 2011 expires in October 2026**; without the 2023 CAs enrolled (KEK
  2K CA 2023, UEFI CA 2023, Option ROM UEFI CA 2023) the machine **still boots but can no longer
  receive DB/DBX updates nor trust binaries signed with the new keys**. It affects
  Linux: new `shim` is signed with the 2023 CA. **Check the state per host before retiring
  the 2011 CA** and treat it as a firmware task (`server-hardware-standards`).
- **FORBIDDEN to serve secrets in `user-data`, in the Kickstart or in `unattend.xml`.** They travel in the clear over
  the network, they stay in `/var/lib/cloud/instance/` and in `/root/anaconda-ks.cfg`, and they appear in the installer's
  logs. What is delivered at first boot is a **single-use, short-lived, minimum-scope
  credential** (Ansible/Vault/Foreman registration token), and the real secret is
  obtained afterwards from the secrets manager. A public SSH key, yes; a private one, a password
  or a long-lived token, never.
- **Verified case study**: **CVE-2026-0386** (WDS, CVSS 3.1 = 7.5, AV:A) — the `unattend.xml`
  travelled over an unauthenticated RPC channel and was accessible through the `RemoteInstall` share without
  authentication, allowing it to be intercepted, embedded credentials to be stolen or code to be injected that
  runs during deployment. Microsoft **disabled *hands-free* deployment by default** with
  the **14-Apr-2026** updates (phase 2; phase 1 on 13-Jan-2026). It is not a Windows flaw:
  it is exactly the threat model of any badly segmented provisioning server.
- **Installation passwords**: `rootpw` hashed with a modern algorithm or, better, **no root
  password and SSH key only**; delete the answer file from the installed system in the `%post`.
  **Sign your iPXE script**: a generic iPXE downloaded from the internet is code with no provenance in your
  boot path.

## 6. Closing the loop: the newborn host registers itself

Provisioning **must end in three automatic registrations**, performed by the host itself at its
first boot and not by a person:

1. **Inventory**: creation or update of the asset with its **stable identifier** (serial number
   / DMI UUID, **not the hostname nor the IP**), MAC(s), role and date. Model and reconciliation:
   `cmdb-inventory-standards`.
2. **Configuration manager**: registration against Ansible/Foreman/Salt with a **single-use token**, and
   a first full convergence. From here on `iac-standards` wins.
3. **Observability**: registration in metrics discovery and log shipping. The `onprem-standards`
   invariant is literal: *no telemetry, no production*.

**And the inverse closing, which almost nobody implements**: when the host is retired it is deregistered in all three
places. An asset that provisioned itself and was retired by hand leaves ghosts in the inventory, orphaned
alerts and live credentials.

## 7. Sustainability and prohibitions

Cadence: the base artifact (ISO, kernel/initrd, bootc image) is **refreshed at least with every minor
release** of the distribution; a year-old golden image is hundreds of patches that get
applied at the first boot of every host. Check every release that the profiles still validate: the
installers change keys between major versions with no friendly warning.

- ❌ **FORBIDDEN** an answer file with long-lived secrets (§5).
- ❌ **FORBIDDEN** one profile per host when the difference is four data points: they go to the inventory.
- ❌ Using the Kickstart `%post` (or cloud-init's `runcmd`) **as a configuration manager**. Its
  job ends at "it boots, it has network and identity, and it calls the configuration manager".
- ❌ A golden image built by hand from a VM "that was already fine". If it does not come out of a versioned
  file and a pipeline, it is not golden: it is a *snowflake* replicated N times.
- ❌ Boot server on the user VLAN or with internet egress.
- ❌ Disabling DHCP snooping "so that PXE works". You declare the right port trusted.
- ❌ Disabling Secure Boot to install and "we'll enable it later". It never gets enabled.
- ❌ Pinning an **experimental** Butane spec version in production (§3).
- ❌ Depending on MDT (retired) or on WDS with media `boot.wim` for Windows 11 / Server 2025.
- ❌ Depending on WDS *hands-free* deployment by re-enabling the CVE-2026-0386 override.
- ❌ Selecting the install disk by `/dev/sdX` on hardware with external storage attached.
- ❌ Declaring "rebuildable from code" without ever having reinstalled that role (§4).
- ❌ Considering provisioning finished without the three registrations of §6.

## 8. Mandatory web verification

Before pinning anything, check on the web —with a literal quote, not an automatic summary:

1. **cloud-init**: current version (as of Aug 2026 the published documentation is **26.2**, at
   `docs.cloud-init.io`) and, above all, the **NoCloud** page: the *discovery /
   runtime configuration* nomenclature is recent and the `ds=` syntax has changed between versions. **Declared
   gap: it was not possible to verify the exact status (valid, obsolete or withdrawn) of `ds=nocloud-net`
   nor of the old `seedfrom` form — the current page only documents `ds=nocloud`.** Check it
   against the version *your* distribution packages, which usually lags upstream.
2. **Butane/Ignition**: the table at `coreos.github.io/butane/specs/` changes with every stabilisation.
   As of Aug 2026: stable **fcos 1.7.0 → Ignition 3.6.0**; experimental 1.8.0 → 3.7.0-experimental.
3. **bootc and image-builder**: `bootc` version (**repository at `bootc-dev/bootc`**, not at
   `containers/`) and, critically, the **`bootc-image-builder` deprecation notice** at
   `osbuild.org/docs/bootc/deprecation-notice/`, whose calendar is expressed in RHEL versions
   (9.8/10.2 → 9.9/10.3 → RHEL 11), not in dates. Verify which dates those correspond to today.
4. **SUSE**: that Agama is still the SLES 16+ installer and **which AutoYaST constructs do not
   migrate**; SUSE documents *high* compatibility but explicitly **not 1:1**.
5. **Windows**: Microsoft's guidance on **CVE-2026-0386** (13-Jan and 14-Apr-2026 phases) and the
   current matrix of which versions WDS supports. Also confirm the retirement status of MDT
   (announced as immediate on 6-Jan-2026).
6. **Secure Boot**: status of the 2011 CA calendar (KEK CA 2011 expired on 27-Jun-2026;
   Windows Production PCA 2011 in Oct-2026) and **the availability of firmware with the 2023 CAs for
   your specific server model**. On out-of-support hardware it may never arrive: that is a
   renewal criterion, not a detail.
7. **Orchestrators**: current version and support of Foreman (short cycle: only two versions
   supported at a time), MAAS (**3.7 requires PostgreSQL 16**) and Cobbler (3.3.x→4.0.0 transition still
   open as of May-2026). **Tinkerbell is still in CNCF *Sandbox***, not incubation: weigh it as an
   adoption risk. **Declared gap: the licences of Cobbler, Foreman, MAAS and Tinkerbell were not
   verified by reading the raw `LICENSE`.** Read them before citing them.
8. **Server firmware**: whether it supports **UEFI HTTP(S) Boot** and with which limitations (download
   size, TLS, CA enrolment). It varies by manufacturer and by BIOS version, and it is what decides whether
   you can abandon TFTP.

If the web contradicts this document, **the web wins** — flag the discrepancy.
