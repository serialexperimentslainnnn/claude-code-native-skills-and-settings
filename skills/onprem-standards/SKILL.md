---
name: onprem-standards
description: On-premise platform umbrella - the whole datacenter or server room as one system, and the router to the deep infra skill that owns each layer. Use when designing or reviewing a bare-metal fleet end to end, inventory-as-code with host naming and IPAM conventions, rebuild-from-code guarantees for every server, fleet-wide patch and end-of-life cadence, choosing a virtualization platform, setting the platform-wide invariants every layer must respect, or deciding which infrastructure skill a task belongs to.
---

# On-premise standards — platform umbrella skill

Criteria verified against the state of the ecosystem as of **August 2026**. For any specific
version, flag or parameter, **verify on the web before pinning it** (section 8).

> **This skill is an umbrella.** It sets the **invariants** of an on-premise platform and **routes**
> to the deep skill for each layer (§1.2). If the task lives in a single layer, the deep skill
> wins; this document wins when the decision is a **platform** one (how the layers fit together,
> what is demanded of all of them, what cannot be left without an owner).

## 1. Scope and triggers

### 1.1 What this skill decides

- **Whole-platform design**: which layers exist, who owns each one, how compute, storage,
  networking, backup and observability fit together in a datacenter or your own server room.
- **Choice of virtualization platform** and exit from VMware; cluster topology and quorum.
- **Fleet coherence**: that naming, IPAM and rebuildability from scratch exist and are the
  same across every layer — the *how* of each one is decided by its owner (§1.2).
- **Patch and end-of-life cadence** for the whole fleet.
- **Routing**: for an infra task, deciding which deep skill applies (§1.2).

### 1.2 Routing to deep skills

| If the task is about… | Owner | Status |
|---|---|---|
| Instrumentation, metrics, traces, logs, alerts, dashboards | `observability-standards` | exists |
| SLO, error budget, on-call, postmortems, capacity as a practice | `sre-practice-standards` | exists |
| Routing, VLAN, BGP, DNS, firewall, VPN, traffic capture | `networking-standards` | exists |
| Shell scripts, system automation | `bash-linux-scripting-standards` | exists |
| Ansible, Terraform/OpenTofu, drift, infra policies | `iac-standards` | exists |
| CVE triage, remediation SLA, EOL, VEX | `vulnerability-management-standards` | exists |
| Internal PKI, ACME, mTLS, encryption at rest, key custody | `cryptography-pki-standards` | exists |
| IdP, SSO, MFA, bastion with PAM/JIT, federation | `identity-access-management-standards` | exists |
| ISO 27001/NIST CSF/ENS, SoA, audit evidence | `grc-compliance-standards` | exists |
| Personal lab, self-hosting, a single node, household cost | `homelab-standards` | exists |
| CIS hardening of the OS, auditd, OpenSCAP/Lynis, baseline | `linux-hardening-standards` | exists |
| SELinux/AppArmor: policies, `audit2allow`, contexts | `selinux-standards` | exists |
| Authorized offensive exercise: RoE, pentest, red team, report | `offensive-security-standards` | exists |
| Windows Server and Active Directory: domain, GPO, Tier 0, Kerberos | `windows-server-ad-standards` | exists |
| Security of the running container: seccomp, escape, Falco | `container-runtime-security-standards` | exists |
| Personal data: minimisation, retention, deletion, DPIA | `privacy-engineering-standards` | exists |
| Isolated security lab, CTF, training | `ctf-lab-standards` | exists |
| RTO/RPO, continuity plan, DR exercises, alternate site | `bcdr-standards` | exists |
| Incident declaration, IC, communication, postmortem | `incident-management-standards` | exists |
| Detection rules, SIEM, ATT&CK coverage, Sigma/YARA | `detection-engineering-standards` | exists |
| Security compromise: containment, evidence, forensics | `incident-response-forensics-standards` | exists |
| systemd, users, logs, packages, day-to-day of the OS | `linux-administration-standards` | exists |
| RHEL/Fedora family: `dnf5`, `rpm-ostree`, `bootc` | `rhel-fedora-standards` | exists |
| ZFS: pool topology, ARC, `zfs send`, scrub | `zfs-standards` | exists |
| Copy strategy, retention, immutability, restore | `backup-recovery-standards` | exists |
| Proxmox VE/PBS: cluster, SDN, PBS, RBAC | `proxmox-ve-standards` | exists |
| Pure KVM/libvirt, `virsh`, XML domains | `libvirt-kvm-standards` | exists |
| vSphere/ESX, vCenter, vSAN, Broadcom licensing, exit from VMware | `vmware-standards` | exists |
| Hyper-V, WSFC, S2D, Azure Local, Windows per-core licensing | `hyper-v-standards` | exists |
| Xen, XCP-ng, Xen Orchestra, legacy XenServer | `xen-standards` | exists |
| Podman, Quadlet, containers under systemd | `podman-systemd-containers-standards` | exists |
| LVM, multipath, NVMe, filesystems, I/O tuning | `linux-storage-standards` | exists |
| Pacemaker/Corosync, fencing, quorum, resources | `ha-clustering-standards` | exists |
| DNS server, zone, DNSSEC, mail records | `dns-standards` | exists |
| nftables/firewalld ruleset, filtering policy and its governance | `firewall-policy-standards` | exists |
| Tunnels and remote access: WireGuard, IPsec, meshes | `vpn-standards` | exists |
| "It won't connect / it's slow": reactive network diagnosis | `network-troubleshooting-standards` | exists |
| S3 and object storage, Object Lock, lifecycle | `object-storage-standards` | exists |
| Rack, power, UPS, generator set, cooling, fire, physical access | `datacenter-facilities-standards` | exists |
| Physical server: sizing, BMC/Redfish, firmware, warranty, disks, refresh | `server-hardware-standards` | exists |
| Unattended installation: PXE/UEFI HTTP boot, Kickstart, cloud-init, Ignition, golden image | `os-provisioning-standards` | exists |
| Inventory and CMDB: NetBox/GLPI/Snipe-IT, discovery, reconciliation, asset lifecycle | `cmdb-inventory-standards` | exists |
| Compute cluster: Slurm, MPI, queues, parallel filesystem | `hpc-standards` | exists |
| Fleet of remote nodes: A/B update, disconnected operation, zero-touch | `edge-computing-standards` | exists |
| File sharing: Samba/SMB, NFS, ACLs, shadow copies | `file-servers-standards` | exists |
| Web and application server: nginx/Apache/IIS, Tomcat, WSGI | `web-app-servers-standards` | exists |
| Mail: MTA, mailboxes, delivery and reception | `mail-servers-standards` | exists |

**Every layer already has an owner.** This document contains no provisional criteria for any of
them: if the task falls on a row of the table, that skill wins. What remains here is what does
**not** fit in any layer — the platform as a whole — and the invariants of §1.3.

### 1.3 Invariants (non-negotiable, valid for every layer)

1. **No telemetry, no production.** A host or service with no metrics and no actionable alert
   is not deployed: it is abandoned.
2. **A backup with no tested restore does not exist.** The proof is the timed restore, not the job
   showing green.
3. **HA without tested fencing is deferred corruption.** Before enabling HA, you power off a node.
4. **No snowflakes.** Every change in prod is born from code and from the inventory; drift is a finding.
5. **No host data from memory.** You query the inventory: IP, role, VLAN, owner, criticality.
6. **Nothing without an owner and an end-of-life date.** A service, server or certificate with no
   responsible party and no dated EOL is debt that will come due on its own.

**Not applicable**: besides the layers routed in §1.2 — which win over this document in their
domain —, see `kubernetes-standards` (containers, manifests and the K8s cluster even if they run on
this iron), `aws-standards`/`azure-standards`/`gcp-standards` (the cloud; here, the on-prem side of a
hybrid and the connectivity towards them), `data-platform-standards` (the data engine that runs on
top: modelling, tuning, replicas), `cicd-standards` (the pipeline that executes the changes),
`appsec-standards` (application code), `homelab-standards` (the boundary is the **rigour demanded**,
not the size: here, production with committed RTO/RPO and agreed windows; there, a personal
lab where the criteria are cost, noise and power draw). `green-it-standards` (**the physical
datacenter —redundant power, cooling, density, hardware lifecycle— is ours**; **its footprint
accounting and reporting obligations are theirs**, including the criteria on PUE, which **the very
standard that defines it advises against using as an overall grade**. A consequence both share:
**extending the useful life of equipment usually weighs more than optimising its power draw**,
because the embodied footprint is already spent).

## 2. Default platform decisions

> Note: versions verified Aug 2026; re-verify on the web before installing (section 8).
> This table sets **the choice of platform**, not its fine-grained operation: the detail of each
> piece belongs to the §1.2 skill that covers it. Versions are quoted only as a reference for the
> decision; the current version and its EOL are set by the skill that owns that layer.

| Area | Default | Forbidden |
|---|---|---|
| Base OS for servers | **Debian 13 "trixie"** (stable since Aug 2025, supported to 2028 + LTS 2030) or **Ubuntu Server 26.04 LTS** (supported to 2031) | EOL distros or ones with no security update channel; installing "testing" in prod |
| Hypervisor | **Proxmox VE** on KVM as the managed platform; pure libvirt only on standalone hosts. Operation, in `proxmox-ve-standards` and `libvirt-kvm-standards` | New VMware without justifying the cost post-Broadcom; unsupported hypervisors. Valid alternatives with their own owner: `vmware-standards` (stay or exit), `hyper-v-standards` (if the Windows licences are already paid for) and `xen-standards` (XCP-ng if the team masters it) |
| Backup | Copy **verified with a timed restore**; the mechanics are set by `backup-recovery-standards` and the plan by `bcdr-standards` | Backup = hypervisor snapshot; job showing green with no tested restore |
| Data filesystem | **ZFS** for data that matters; pool design is set by `zfs-standards`, the block stack by `linux-storage-standards` | RAID5/RAIDZ1 with large disks; hardware RAID underneath ZFS; RAID0 in prod |
| Monitoring | node_exporter on **every** host and one actionable alert per symptom; the stack and its design are set by `observability-standards` | Hosts with no telemetry ("no telemetry, no production"); email alerts with no defined on-call |
| Remote access | SSH with **ed25519 or FIDO2 (ed25519-sk) keys**, bastion, MFA | SSH passwords, root login, telnet, SNMP v1/v2c |
| Config management | Idempotent Ansible (or equivalent), versioned repo, executed from CI or AWX | Manual changes not captured (snowflakes); loose scripts with no idempotency |
| Time/DNS | Internal NTP (chrony) and redundant internal DNS; both monitored | Hosts with a free-running clock (breaks TLS, Kerberos, logs); a single DNS |

## 3. Structure and conventions

**Systemd**: unit design, timers, journald and the day-to-day of the OS belong to
`linux-administration-standards`; its sandboxing as a measured **security control**, to
`linux-hardening-standards`. What this skill demands of the whole fleet: **no in-house service
runs without a versioned unit**, and the unit is deployed from the repo, not written on the host.

**Fleet conventions**
- Inventory as code (single source of truth: hostname, IP, role, VLAN, owner, criticality).
  No host data "from memory": you query the inventory.
- Stable naming by role+location+index; IPAM with no overlaps (RFC1918), documented in the repo.
- Every server rebuildable from code (PXE/preseed/autoinstall/cloud-init + Ansible); the
  proof is reinstalling one and having it come out identical.
- VMs with virtio + qemu-guest-agent; ballooning and CPU type coherent per cluster (live migration).

## 4. Mandatory quality gates

- **IaC lint**: `ansible-lint`/`yamllint` (or equivalent) in CI; infra changes by PR/MR,
  never direct execution in prod from the laptop.
- **Audited hardening baseline**: the OS CIS Benchmark applied via code and verified with a
  scanner (OpenSCAP/Lynis/Wazuh SCA) with an agreed minimum score; drift is a finding, not an anecdote.
- **Pre-change validation**: `visudo -c`, `sshd -t`, `nginx -t`, `named-checkconf`… — every
  service with its own verifier is validated before reloading. SSH/firewall changes with a rescue
  session open (or OOB console) until access is confirmed.
- **Post-change smoke test**: the playbook/handler checks that the service responds (port,
  health endpoint), not just that systemd is `active`.
- **Verified backup as a gate**: periodic **real restore** job (file + full VM) with the
  result in monitoring; a backup with no tested restore counts as non-existent.
- **Tested HA**: failover exercised (powering off a cluster node) in an agreed window, at least
  every six months; the result feeds the runbook.

## 5. Security

> **OS hardening** (CIS, auditd, OpenSCAP/Lynis) belongs to `linux-hardening-standards`, mandatory
> access control to `selinux-standards` and the filtering policy to
> `firewall-policy-standards` (§1.2). What follows **is not hardening criteria**: it is the minimum
> demanded of the **whole** platform, including what none of them covers — the physical management
> plane (BMC/IPMI) and fleet discipline.

**Hardening (CIS as the baseline)**
- Minimum installed: no unnecessary services/ports; host firewall **default-deny inbound**
  (nftables) on top of the perimeter one; egress filtered in sensitive zones.
- SSH: `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  ed25519/FIDO2 keys, `AllowGroups`, legal banner; access to prod only via **bastion** with
  session recording/auditing. Automatic security updates of sshd/the OS itself.
- Accounts: named sudo with logging (no shared root), local passwords only for emergencies in
  a secrets manager, service credentials with rotation.
- Kernel/platform: microcode up to date, mitigations enabled, SELinux/AppArmor enforcing,
  auditd with a minimum set of useful rules forwarded to the SIEM.
- Secure Boot + TPM where the hardware allows it; encryption at rest (LUKS/ZFS encryption) on
  disks with data and on backups; keys in a manager (not on the host itself).

**Network** — network design (routing, VLAN, BGP, DNS, firewall policy) is set by
`networking-standards`; here, only what the server platform must guarantee:
- Segmentation by VLANs, minimum: management / services / storage-replication / users /
  DMZ; **default-deny between zones**, every permitted flow documented in the network repo.
- **Separate, out-of-band management plane**: IPMI/iDRAC/iLO, the management interfaces of the
  hypervisor and switches on a dedicated VLAN with no route from user networks; access only via
  bastion/VPN (WireGuard). BMC with patched firmware and unique credentials per host.
- Corosync/cluster and replication traffic on a dedicated network (latency and isolation).
- 802.1X/port-security on access where applicable; SNMPv3 only; TLS 1.2+/mTLS on east-west
  traffic between internal services; internal PKI with ACME (step-ca) rather than manual certificates.

**Operational least privilege**
- RBAC in Proxmox/libvirt (roles by function, API tokens with scope, no `root@pam` for automation).
- Ansible with dedicated accounts and sudo restricted to what is needed; secrets in Vault/sops, never
  in the clear in the repo.

## 6. Operability

**Observability**
- node_exporter + specific exporters (zfs, smartctl, libvirt/PVE, blackbox) on every host;
  federated scrape or a Prometheus per site with long retention (Thanos/Mimir only if the volume demands it — KISS).
- **Actionable alerts on symptoms** (golden signals + disk full with prediction, SMART,
  RAID/ZFS degradation, failed backup or **failed restore-test**, certificate about to expire,
  cluster node down, NTP drift). Every alert links a runbook; an alert with no possible action is removed.
- Dashboards per layer (hardware / hypervisor / VM / service) and **SLOs with error budget** for
  the services that matter; blameless postmortems with actions.

**HA with no SPOF** — Pacemaker/Corosync, fencing and resources in detail go to `ha-clustering-standards`
(§1.2); here, topology and physical redundancy, which are platform decisions:
- Clusters of 3+ nodes (real quorum; 2 nodes only with a qdevice); **fencing/watchdog configured and
  tested** before enabling HA — HA without fencing is deferred corruption.
- Physical redundancy: dual PSU on different feeds, LACP bonding to stacked/MLAG switches, monitored
  UPS with a tested ordered shutdown, cooling under watch.
- Shared storage with replication (Ceph from 3-5 homogeneous nodes upwards; ZFS replication
  for pairs) — pick the simplest one that meets the RPO, not the most powerful.

**Backups and DR** — the continuity plan, the RTO/RPO derived from the business, the recovery
order and the DR exercises **already belong to `bcdr-standards`**; the mechanics of the copy belong to
`backup-recovery-standards` (§1.2). Here, the minimum demanded of the platform:
- **3-2-1** rule with at least one **immutable or offline** copy (remote PBS with encrypted sync,
  S3 object-lock, or tape) — ransomware attacks the accessible backups first.
- Retention by criticality (e.g. 7d/4w/12m), encryption at rest and in transit, **encryption keys
  held outside** the backed-up system (an encrypted backup with no key = total loss).
- **RTO/RPO per service, in writing**, and **scheduled DR exercises** (annual minimum, ideally
  every six months): restore the critical service on alternate hardware/site, timed, with a report.
  Also switch/firewall configs and the backup infrastructure itself.
- Operational runbooks: ordered startup/shutdown of the datacenter, node loss, site loss,
  selective restore. Tested, versioned, with an owner.

## 7. Sustainability and prohibitions

**Patch/upgrade cadence** — the triage of a specific CVE (CVSS+EPSS+KEV, SLA, VEX) is set by
`vulnerability-management-standards`; here, the fleet's cadence:
- OS security: automatic (`unattended-upgrades`, security only) in low tiers; weekly
  orchestrated with a reboot in a window for prod. Kernel/microcode: monthly or on an exploitable CVE (CVSS+EPSS+KEV triage).
- Hypervisor/PBS: minor updates monthly, rolling across the cluster (migrate→patch→reboot→rebalance);
  majors after reading the release notes and testing on a staging node/cluster. Do not let support
  windows die (PVE 8 EOL Aug 2026: plan the jump to 9.x before, not after).
- Firmware (BIOS/BMC/NIC/disks) and switches: quarterly review; BMC on any CVE.
- Prometheus/Grafana: follow the LTS/latest minor line; read breaking changes before a major.

**FORBIDDEN**
- Manual changes in prod not reflected in the code/inventory (snowflakes); uncorrected drift.
- Backups with no tested restore; a single copy; a backup on the same chassis/pool as the source;
  backup encryption keys stored only inside the backed-up system.
- SSH by password, remote root login, telnet, SNMP v1/v2c, management interfaces (BMC/PVE/
  switches) exposed to user networks or to the Internet.
- HA without tested fencing; 2-node clusters with no qdevice; "HA" with a single switch/PSU/UPS.
- RAID5/RAIDZ1 with large disks; hardware RAID under ZFS; ZFS pools >80% full with no plan.
- Disabling SELinux/AppArmor or the firewall "to make it work" with no diagnosis and no revert.
- Running EOL versions in prod (OS, hypervisor, services) with no dated exit plan.
- Noisy alerts kept "just in case"; permanent silences with no expiry.
- Editing the package's systemd units instead of overrides; services as root with no sandboxing.
- Sharing BMC/IPMI root credentials between hosts; factory default credentials.

## 8. Mandatory web verification

Before pinning any specific piece of data, **look it up — do not recall it**:
- Current stable version and EOL of: Proxmox VE/PBS (roadmap + endoflife.date), Debian/Ubuntu,
  Prometheus (LTS line), Grafana, OpenZFS. Verified Aug 2026: PVE 9.2, PBS 4.2, Debian 13.6,
  Ubuntu 26.04 LTS, Prometheus 3.13 LTS, Grafana 13.x — but it expires fast.
- The CIS Benchmark in force for the exact OS version before applying/auditing hardening.
- Active CVEs (with KEV/EPSS) of the affected stack before deciding the cadence of an urgent patch.
- Compatibilities before cross upgrades (PVE↔PBS, kernel↔ZFS, Ceph↔PVE) in the official release
  notes, and the official upgrade procedure (pve-upgrade-checklist) — not from memory.
- The state of the market if the decision is a platform one (Broadcom/VMware licensing, maturity of
  XCP-ng/alternatives) — it changes quarter by quarter.

If you cannot verify, say so explicitly instead of assuming.

If the web contradicts this document, **the web wins** — flag the discrepancy.