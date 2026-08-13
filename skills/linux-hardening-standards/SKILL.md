---
name: linux-hardening-standards
description: Linux OS hardening baselines and their measurement. Use when applying or auditing CIS Benchmarks, DISA STIG, ANSSI-BP-028 or CCN-STIC/ENS on Linux hosts, running oscap/OpenSCAP with SCAP Security Guide profiles, Lynis, Wazuh SCA, ansible-lockdown or devsec.hardening roles, or editing sshd_config, sysctl.d, audit.rules/auditd.conf, pam_faillock, faillock.conf, login.defs, sudoers, modprobe.d blacklists, fstab mount options (noexec/nosuid/nodev), SUID audits, systemd unit sandboxing (systemd-analyze security), AIDE, Secure Boot/TPM/LUKS unattended unlock, unattended-upgrades/dnf-automatic or kernel livepatching.
---

# Linux hardening standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **hardening the Linux operating system and proving it with a measurement**: choosing and
applying a baseline (CIS, STIG, ANSSI-BP-028, CCN-STIC/ENS), automating it as code,
auditing it with a scanner, the agreed score and the handling of drift. It covers minimal surface,
kernel parameters, accounts/sudo/PAM, SSH, auditd, integrity and measured boot, service containment
with systemd, mount options and SUID, security updates and livepatching, and
a hardened golden image.

Triggers: `oscap`, `ssg`/`scap-security-guide`, `lynis`, `cis`, `stig`, `anssi_bp28`, `ccn-stic`,
`sshd_config`, `/etc/sysctl.d/*.conf`, `/etc/audit/rules.d/*.rules`, `auditd.conf`, `faillock.conf`,
`pwquality.conf`, `login.defs`, `/etc/sudoers.d/`, `/etc/modprobe.d/*.conf`, `fstab`, `aide.conf`,
`systemd-analyze security`, `unattended-upgrades`, `dnf-automatic`, `kpatch`, "baseline",
"benchmark", "compliance score", "the hardening broke the service".

**Governing principle**: **a baseline without a measurement is an opinion, and a baseline applied
blind is a scheduled service outage.** Real hardening is three simultaneous things —
*applying it as code*, *measuring it with a scanner* and *documenting every exception with an owner and a reason*.
Missing any of the three turns the work into compliance theatre.

**Not applicable**: see `selinux-standards` (mandatory access control in depth: policy,
contexts, booleans, AVC diagnosis, AppArmor — here MAC in `enforcing` is only **required** as a
baseline control and measured, not explained in terms of how it is operated nor how policy is written),
`onprem-standards` (**platform umbrella**: hardware, the OOB/BMC management plane, hypervisor,
fleet topology, fleet patching cadence, platform invariants — its §1.3 invariants are
inviolable and this skill develops them at the OS layer),
`bash-linux-scripting-standards` (the scripts that run anything from here: `set -Eeuo
pipefail`, ShellCheck, bats), `iac-standards` (Ansible/Terraform as a tool: role
structure, Molecule, lint and CI of the IaC repo — here only which hardening role is chosen and with what
criteria it is applied), `vulnerability-management-standards` (CVE triage with CVSS/EPSS/KEV, remediation
SLA, VEX, EOL tracking — **they prioritise the patch, you harden so the patch
matters less**), `grc-compliance-standards` (ENS/ISO 27001/NIST CSF as a framework, SoA, risk
acceptance and audit evidence — here the **technical control and its proof**, which is what they
consume as evidence), `networking-standards` (network design: VLANs, routing, firewall policy
between zones, DNS, VPN; **the *host* firewall belongs to this skill** — `nftables`/`firewalld` on the
server itself as a baseline control: default-deny inbound, filtered egress, a versioned
ruleset —, whereas which flow is allowed between zones and why is decided by the network
topology), `cryptography-pki-standards` (the choice of algorithms and their cryptographic justification, LUKS
key management, SSH certificate issuance and the internal PKI — here only the **configuration** that
consumes them), `identity-access-management-standards` (IdP, SSO, MFA, JIT/PAM elevation and the bastion as
a service — here the local configuration: `sudoers`, `pam_faillock`, `AllowGroups`),
`kubernetes-standards` (declarative Pod hardening, `securityContext`, admission),
`observability-standards` (where and how auditd logs are collected, retained and correlated),
`appsec-standards` (application code vulnerabilities), `homelab-standards` (a personal
lab: the boundary is the rigour demanded, not the size), `offensive-security-standards`
(offensive verification of the hardening, with scope and authorisation), `ctf-lab-standards`
(a disposable training lab), `developer-workstation-standards` (a boundary
that really does collide: **here the hardening of the server and the fleet** — CIS/STIG baseline,
`sysctl`, auditd, sudoers, SELinux/AppArmor, applied by centralised configuration —; **there the
workstation**, whose threat model is different: disk encryption, keys in hardware,
editor extensions and `curl | sh` as a supply chain, and development credentials. **A
server baseline applied to a development workstation does not harden it, it makes it unusable**),
`endpoint-security-standards` (**third-party EDR/XDR and the posture of the encryption guard across the
fleet are theirs** — including the agent's real limits on Linux —; here the baseline control
applied by centralised configuration and measured with `oscap`).

In addition:
`container-runtime-security-standards` (seccomp, eBPF/Falco, container escape detection
and runtime security), `detection-engineering-standards` (what is done with
auditd telemetry — Sigma rules, use cases, SIEM), `bcdr-standards` (RTO/RPO and
continuity), `linux-administration-standards` (day-to-day OS work, systemd, packages,
users without a security angle), `rhel-fedora-standards` (the specifics of the RHEL
family — `dnf5`, `rpm-ostree`, `bootc`, image builder).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8). The facts are from
> **August 2026** and baseline content (CIS, SSG) is revised every few weeks.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Reference baseline | **The CIS Benchmark for the exact distro version**, Level 1 Server as the floor, Level 2 on hosts processing sensitive data | It is the only one with automated content, mapping to controls and continuous updates. **The version number goes per distro version**: "the CIS for Linux" does not exist. Verified Aug 2026 on cisecurity.org: **RHEL 10 v1.0.1**, **RHEL 9 v2.0.0**, **RHEL 8 v4.0.0**, **Ubuntu 24.04 LTS v2.0.0**, **Ubuntu 22.04 LTS v3.0.0**, **Debian 13 v1.0.0**, **Debian 12 v2.0.0**; STIG-flavored variants: RHEL 9 STIG v1.0.0, RHEL 8 STIG v2.0.0, Ubuntu 24.04 STIG v1.0.0 |
| **A coverage gap to watch** | **There is no CIS Benchmark for Ubuntu 26.04 LTS** (verified Aug 2026) | If you standardise on 26.04, your baseline **cannot be CIS yet**: use ANSSI-BP-028 or `devsec.hardening` and plan the migration when CIS publishes. Extrapolating the 24.04 benchmark to 26.04 without reviewing it rule by rule is forbidden (§7) |
| Profile (L1/L2, Server/Workstation) | **Server** on servers, **Workstation** only on workstations; L1 = "should not break anything", L2 = **extends** L1 accepting functional impact | Four profiles per benchmark (L1/L2 × Server/Workstation) and **L2 is not standalone: it includes L1**. Applying the Workstation profile to a server, or L2 with no exception plan, is the number one cause of "the hardening broke the service" |
| Baseline in the Spanish public sector | **CCN-STIC 610-25 "Perfilado de seguridad para distribuciones Linux (servidor o cliente)"** over the ENS (**RD 311/2022**), category BÁSICA/MEDIA/ALTA | Verified Aug 2026: the unified 610-25 guide (produced on Rocky Linux 10) defines the Linux **PCTE** with **14 measures** that are technically applicable and profiles **ENS / DIFUSIÓN LIMITADA / INFORMACIÓN CLASIFICADA**, with per-distro annexes (**A** Rocky, **B** Arch, **E** Debian; Ubuntu and Fedora also announced). In practice it supersedes the per-product `610Axx` series. The 600 series is **incremental**: the OS guide + a guide per service. SSG ships an `ens` profile |
| Baseline in allied defence/government | **DISA STIG** when the customer requires it contractually | Verified Aug 2026 (third-party sources, see §8): **RHEL 9 V2R8**, **RHEL 10 V1R1**, **Ubuntu 24.04 LTS V1R5** (13 May 2026). DISA publishes quarterly: always confirm on `public.cyber.mil` |
| Baseline with your own technical criteria | **ANSSI-BP-028 v2.0** (Oct 2022), levels `minimal` → `intermediary` → `enhanced` → `high` | The four levels are **cumulative** and have been implemented as SCAP profiles since SSG **0.1.73**. It is the best-reasoned baseline for deciding *how much* to harden, not just *what*. Careful: `R1`, `R2`… are **rule identifiers** within the document, not levels |
| Audit content | **SCAP Security Guide / ComplianceAsCode v0.1.81** (1 Jun 2026) | The single source of the `cis_server_l1/l2`, `cis_workstation_l1/l2`, `stig`, `anssi_bp28_{minimal,intermediary,enhanced,high}`, `pci-dss`, `ospp`, `ens`, `e8`, `hipaa`, `cui` profiles. It covers RHEL 8/9/10, Ubuntu, **Debian 13**, SLE. Red Hat delivers the current CIS versions in SSG ≥ 0.1.80. A relevant change: the PAM rules use **authselect** — they do not apply if the PAM stack was edited by other means |
| Compliance scanner | **OpenSCAP ≥ 1.4.4** (NEWS 04 Mar 2026, released 09 Apr 2026) — `oscap xccdf eval` | It is the formal, auditable measurement (XCCDF/OVAL, ARF). The 1.4.x line: `oscap xccdf generate fix --fix-type kickstart` (an unattended install already hardened), `oscap-im` for **bootc/Image Mode** images, `autotailor` with multi-profile JSON tailorings, `oscap info` lists a profile's rules and variables, `--skip-valid` **removed** → `--skip-validation`. **Warning**: the distros lag far behind (Ubuntu 24.04 packages **1.3.9**) — use your OS vendor's binary and do not assume 1.4.x features |
| Complementary scanner | **Lynis 3.1.7** (25 Jun 2026; CISOfy, maintained at a slow ~8-month cadence) | Agentless and without SCAP: a fast, useful signal on hosts outside SSG's scope. **The distros package old versions**: use the CISOfy repo or the tarball, and `lynis --check-update`. Its "hardening index" **is not a compliance score**: do not mix it with OpenSCAP's |
| Continuous fleet scanner | **Wazuh 4.14.x** (4.14.7, 29 Jul 2026) with its **SCA** module (YAML policies aligned to CIS, extensible) | OpenSCAP measures well and at a point in time; drift is detected continuously. Both, for different things. Wazuh 5.0 in development changes the SCA/FIM synchronisation cycle: do not plan on it until its GA |
| Applying the baseline | **A maintained Ansible role**, not home-made scripts | Verified Aug 2026, both **active**: **ansible-lockdown** (RHEL9-CIS **v2.2.0**, 27 Feb 2026, GPG-signed; UBUNTU24-CIS **v1.6.0**, 5 May 2026; ~93 repos with commits in Jul-Aug 2026; the `-CIS`/`-STIG` pattern = remediation and `-Audit` = verification with GOSS; MIT) and **devsec.hardening 10.6.0** (26 May 2026; roles `os_hardening`, `ssh_hardening`, `nginx_hardening`, `mysql_hardening`; Apache-2.0; already supports **Ubuntu 26.04** and Fedora 42-44) |
| Choosing between the two | **ansible-lockdown** if the requirement is *to meet a numbered benchmark and prove it*; **devsec.hardening** if it is *a sensible multi-distro baseline without numbering* (and today, if your OS is **Ubuntu 26.04**, which still has no CIS) | Do not mix them on the same host: they step on each other in `sysctl.d`, `sshd_config` and `login.defs`. One, plus your exceptions on top. Operational note: **the ansible-lockdown roles do not support check mode** — they are remediation, not auditing |
| Writing it by hand | **Only** for what the role does not cover or for the exceptions | A home-made baseline ages: nobody re-evaluates it when the new benchmark version comes out. You adopt maintained content and add your delta |
| MAC | **SELinux or AppArmor in `enforcing`, always** — a baseline control, not an option | How it is operated, diagnosed and how policy is written: `selinux-standards`. Verified Aug 2026: **SLES 16.0 (GA 4 Nov 2025) removes AppArmor and boots with SELinux enforcing** (+400 modules); openSUSE Tumbleweed since snapshot 20250211 and Leap 16 likewise |
| Host firewall | **nftables** (directly or via `firewalld`), **default-deny inbound**, a versioned ruleset applied by code | systemd v259 already removes iptables/libiptc from `networkd`/`nspawn`: iptables-legacy is debt. Filtered egress is mandatory in sensitive zones |
| Security updates | **Automatic and scoped to security**: `unattended-upgrades` with `-security` origins, or `dnf-automatic` with `upgrade_type = security` + `apply_updates = yes`; orchestrated within a window for prod | The real decision point **is not installing, it is rebooting**: kernel, glibc and OpenSSL do not take effect until the reboot. Mandatory verification before trusting it: `unattended-upgrades --dry-run --debug` / `dnf-automatic /etc/dnf/automatic.conf`, plus `journalctl -u` and `/var/run/reboot-required` |
| Livepatching | **Only if the RTO does not allow the reboot**, and **never as a substitute for the reboot** | Verified Aug 2026: **kpatch** (RHEL 9 since 9.0, **RHEL 10 since 10.2**; eligible kernels designated **quarterly**, patched for up to 1 year; 2 years with EUS and 4 with Update Services for SAP; it forces you to update the kernel and reboot **≥2 times a year**; **reverting a live patch without rebooting is not supported**; Red Hat repo RPMs only). **Canonical Livepatch** (up to 10 years with Ubuntu Pro, +5 with Legacy; patches per kernel only for **9-13 months** from its release; **incompatible with FIPS and real-time kernels**; **ARM64 arrives with 26.04**). **KernelCare/TuxCare** (RHEL, Oracle, Rocky, Alma, CentOS, Ubuntu, Debian — **SLES is not listed**; incompatible with Canonical Livepatch on the same host). Treat the coverage figures in vendor comparisons as marketing |
| auditd | **audit-userspace 4.x** with a minimal set of useful rules in `/etc/audit/rules.d/` | Verified Aug 2026: since **audit-4.0 the rules are loaded by `audit-rules.service`**; 4.1.0 added `libauplugin`; 4.1.2 sped up `ausearch`/`aureport` considerably and moved `audit.pid`/state to `--runstatedir` (`/run`) — **if you have your own MAC policy over those paths, update it**. `report_interval` (≥4.0.5) dumps metrics to `/run/audit/auditd.state` |
| File integrity | **AIDE ≥ 0.19.2** (14 Aug 2025) with the database **off the host**; the agent's FIM (Wazuh) where an agent already exists | **0.19.2 is the minimum safe version** (CVE-2025-54409: null-pointer deref → local DoS in 0.13–0.19.1). No releases in 2026: a slow-cadence project. An AIDE database that lives on the host it audits is worth nothing after a compromise |
| Boot | **Secure Boot + TPM 2.0** where the hardware allows it, signed kernel and modules, `lockdown` at `integrity` as a minimum | systemd v259 **removed TPM 1.2** from `systemd-boot`/`systemd-stub`. The `lockdown` LSM **had no maintainer from 5.4 until Linux 6.17**, when it regained active maintenance: before 6.17 treat it as a stable but non-evolving control |
| Encryption at rest | **LUKS2**; unattended unlock with **Clevis/Tang** in the datacenter and **`systemd-cryptenroll` with TPM2** on machines with Secure Boot | Verified Aug 2026: TPM2 in `systemd-cryptsetup` requires systemd ≥ 251 and kernel ≥ 5.17 for PCR policies; **sealing to PCR 0/1/2/4 breaks with every kernel/initramfs/GRUB update** and **PCR 7 on its own is attackable** (the initrd can be replaced without changing PCRs) → use **signed PCR policies (PCR 11 + `--tpm2-signature`)** or a PIN. The upstream `linux-system-roles/nbde_client` role is **Clevis-centric and does not support TPM2**. The choice of algorithms and key custody: `cryptography-pki-standards` |

## 3. Structure and conventions

### 3.1 The baseline is applied with documented exceptions, never blind

There are CIS controls that **break real services** — `noexec` on `/var` or `/tmp` against
installers and runtimes that execute from there, `nodev` on paths a container needs,
`umask 027` against services that share a group, restricting unprivileged user namespaces
against rootless Podman or browsers, `cron`/`at` restrictions, SSH algorithms that leave out
old clients, `pam_pwquality` against service accounts. The baseline is **not applied
100%**: it is applied 100% *minus a set of explicit exceptions*.

Mandatory exception format, in the repo, next to the code that implements it:

| Field | Content |
|---|---|
| Rule | The exact benchmark ID (`xccdf_org.ssgproject.content_rule_…` or the CIS number) |
| Scope | Which hosts/group, not "production" |
| Reason | The concrete failure observed, with evidence (log, trace, ticket) |
| Compensation | Which alternative control covers the risk |
| Owner and expiry | Person and re-evaluation date. **Without a date it is not an exception: it is abandonment** |

The exception is implemented as a **profile tailoring** (`autotailor`, XCCDF/JSON tailoring
files) so the scanner **does not count it as a failure**. An exception that keeps appearing
as a finding in every report trains the team to ignore the reports.

### 3.2 Order of work (non-negotiable)

1. **Measure before touching**: `oscap xccdf eval` with the target profile against the host as it is.
   That report is the baseline and the argument for the conversation.
2. **Apply in non-production** the full role, with no exceptions, and **break things there**.
3. **Catalogue what broke** → exceptions (§3.1) + tailoring.
4. **Apply in production in waves**, with a functional smoke test after each wave (§4).
5. **Re-measure and set the agreed score** as the CI threshold.
6. **Watch the drift** continuously; every deviation is a finding with an owner.

Never: applying the full role directly to production "because it is a standard baseline".

### 3.3 Minimal surface

- **Packages**: a minimal installation as the starting point (`Minimal Install`, `debootstrap`,
  `--no-install-recommends`). Everything installed afterwards is justified. No compilers,
  no unnecessary network clients (`telnet`, `ftp`, `rsh`, `tftp`), no X servers on servers.
- **Services and ports**: `systemctl list-units --type=service --state=running` and `ss -lntup`
  against the role's expected list. An undeclared listening port is a finding.
- **Unnecessary kernel modules**, with a real blacklist (`install <mod> /bin/true` in
  `/etc/modprobe.d/`, not just `blacklist`, which does not prevent on-demand loading): exotic
  filesystems (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `udf`, `squashfs` if unused),
  unusual network protocols (`dccp`, `sctp`, `rds`, `tipc`), `usb-storage` on servers,
  `firewire-core`, `bluetooth`. Verify that the blacklisting survives the `initramfs`.
- **Accounts**: no system accounts with a valid shell; no orphan accounts; explicit
  `nologin`. No shared local accounts — all access is named.

### 3.4 Kernel and parameters

No "list of `sysctl`s copied from a blog". Every parameter set is justified and grouped
in `/etc/sysctl.d/` by purpose, with the file versioned (careful: on **Debian 13**
`/etc/sysctl.conf` is no longer honoured — you have to write into `sysctl.d`, something `devsec.hardening`
fixed in its 10.4 line).

The axes, with the criterion for why:

- **Network**: anti-spoofing (`rp_filter`), ignore ICMP redirects and source routing, do not forward
  packets unless the host is a router, `tcp_syncookies`, and `accept_ra`/`disable_ipv6` **only if
  IPv6 really is not used** — disabling IPv6 "just in case" breaks modern services and hardens
  nothing. The filtering policy itself belongs to the firewall, not to `sysctl`.
- **Kernel information exposure**: `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1`,
  a high `kernel.perf_event_paranoid` on hosts without profiling, `fs.protected_hardlinks`/`_symlinks`/
  `_fifos`/`_regular`. Real operational cost: they make diagnosis harder — decide it, do not inherit it.
- **Tracing and dump restrictions**: `kernel.yama.ptrace_scope` ≥ 1 (2 or 3 on hosts that do not
  debug anything; `devsec.hardening` 10.6.0 hardened it explicitly in May 2026),
  `fs.suid_dumpable=0`, core dumps disabled or directed to a controlled path (a core dump can
  contain keys in memory).
- **Boot and code chain**: mandatory **module signing**, `kernel.modules_disabled=1`
  at the end of boot on fixed-function hosts, `kexec_load_disabled=1`, and **`lockdown`** —
  `integrity` as the floor (it blocks modifying the running kernel and loading unsigned
  modules), `confidentiality` on hosts handling secrets, **measuring first** what breaks
  (profiling, debugging, hibernation, some proprietary drivers). `lockdown` transitions are
  **one-way**: you can only harden, never relax at runtime. On
  EFI x86/arm64 many distros enable it by themselves with Secure Boot. A limitation declared by its author:
  it protects the **integrity of the kernel, not of the whole system** — complement it with dm-verity and MAC.
- **Unprivileged namespaces**: on Ubuntu 24.04+/26.04 the restriction goes through AppArmor
  (`kernel.apparmor_restrict_unprivileged_userns=1` by default). Before disabling it for an app
  that "does not start", understand what uses it: it is historic escalation surface, and Qualys published in
  Mar 2025 **three bypasses** of that restriction (via `aa-exec` to permissive profiles and via busybox's
  default profile). On **RHEL 10** the default configuration grants user namespaces to
  unprivileged users, which widened the impact of recent kernel flaws: review it.
- **CPU mitigations**: **on by default, always**. If the cost is unacceptable, it is measured with
  the real workload, the loss is documented, it is scoped to specific hosts and it is approved by the risk
  owner. `mitigations=off` on a multi-tenant host or one running third-party code is forbidden
  (§7). A verified reference for the real cost: **VMSCAPE (CVE-2025-40300**, Sep 2025; guest→hypervisor
  leak on all AMD Zen 1-5 generations and Coffee Lake) is mitigated with conditional IBPB
  after VMexit (`vmscape=`, `vmscape=force` with untrusted guests) at a cost of **~10% with
  an emulated device and ~1% on Zen 4** — that is the order of magnitude of the conversation, not "the
  mitigations cost half the performance". A recurring pattern: **the kernel patch alone is
  not enough, microcode/UEFI is needed in parallel**. Real status: `lscpu` and
  `/sys/devices/system/cpu/vulnerabilities/*`.

### 3.5 Accounts, sudo and PAM

- **Named and scoped sudo**: rules per group, with explicit commands and absolute paths, in
  versioned `/etc/sudoers.d/` files validated with `visudo -c`. `Defaults logfile` or
  `log_output` for elevated commands. **`NOPASSWD: ALL` is forbidden** (§7); `NOPASSWD` scoped to
  a specific command for automation is acceptable **if** the command does not allow escaping to a shell
  (careful with `vi`, `less`, `find -exec`, `tar --to-command`, package managers).
- **`sudo` is first-class attack surface, not inert infrastructure**: CVE-2025-32462 and
  **CVE-2025-32463** (root escalation via `--chroot`, CVSS 9.3, **in the CISA KEV catalogue since
  29 Sep 2025**, and **exploitable without being in sudoers**) were fixed in **sudo 1.9.17p1**. Upstream
  has announced that the chroot option will be removed. Verify the installed version, and forbid the use
  of `--chroot`/`-R` in your rules.
- **`pam_faillock`** configured in `/etc/security/faillock.conf` (lockout after N failures, a window,
  a non-zero `unlock_time` unless explicitly required, and **excluding root from permanent lockout**
  so you do not lock yourself out). Verify the unlock with `faillock --user X --reset` before considering it
  done. In the RHEL family, **the PAM stack is managed with `authselect`**: editing the files by
  hand means the SSG rules do not apply and the next `authselect apply-changes` reverts
  your change.
- **`pam_namespace` disabled unless genuinely used**: CVE-2025-6020 and its complete fix CVE-2025-8941
  (CVSS 7.8, with a public exploit) allow root escalation via symlinks over paths controlled by
  the user. Fixed in linux-pam 1.7.1. If you need it, mount with `nosymfollow` and do not point it
  at user-writable paths.
- **An evidence-based password policy, not a baroque one**: modern evidence (NIST SP 800-63B) calls for
  **a high minimum length + checking against lists of compromised passwords**, and advises against
  mandatory periodic expiry and composition rules. The CIS baseline still asks for
  expiry and complexity: if your framework forces you, comply; if you have room, document the
  deviation *towards the better practice* with the same rigour as any other exception. Checking
  against lists: `pam_pwquality` with a dictionary or a source of leaked credentials. Local hashing:
  yescrypt or SHA-512 with a high round count depending on the distro.
- **Limits**: `/etc/security/limits.d/` with bounded `nproc`/`nofile`/`core` to contain
  fork bombs and descriptor exhaustion; it complements, it does not replace, systemd's limits.
- **`umask 027`** (or `077` on sensitive hosts) in `/etc/login.defs` and in the shell profile, with
  care for services that share a group. `UMask=` in the systemd unit for the service.
- **Sessions**: `TMOUT`/`ClientAliveInterval` for idle sessions, a legal banner
  (`/etc/issue.net`) — the banner is a compliance control, not a security one: treat it as such.

### 3.6 Hardened SSH

- **Baseline**: `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  `PermitEmptyPasswords no`, `AllowGroups <group>` (an explicit allowlist, not a denylist),
  `X11Forwarding no`, a low `MaxAuthTries`, `LogLevel VERBOSE` (it records the fingerprint of the key used,
  which is what you will need in the investigation).
- **Post-quantum — verified Aug 2026** (OpenSSH **10.4**, 06 Jul 2026): **9.9** added
  `mlkem768x25519-sha256`; **10.0** (Apr 2025) made it **the default KEX**; **10.1** (Oct 2025)
  makes **the `ssh(1)` client warn** when the server does not offer a post-quantum KEX (*"WARNING:
  connection is not using a post-quantum key exchange algorithm"*) and adds **`WarnWeakCrypto`** to
  `ssh_config` to silence it. The previous hybrid `sntrup761x25519-sha512@openssh.com` (default
  since 9.0) is still supported and serves to interoperate with 9.0-9.8 servers. **Criterion**:
  the server must negotiate `mlkem768x25519-sha256`; **silencing the warning on the client instead of
  updating the server is forbidden** (§7). OpenSSH does **not** yet have post-quantum signatures for
  identity keys: the warning is about KEX only.
- **Algorithms**: do not copy `KexAlgorithms`/`Ciphers`/`MACs` lists from three years ago — a list
  pinned by hand ages towards *weaker* than the current binary's default (since 10.0 the default cipher
  order is ChaCha20-Poly1305 → AES-GCM → AES-CTR: **an old list undoes that
  improvement**). Start from the installed version's default and **remove**, do not rebuild. Verify what
  it actually negotiates (`ssh -Q kex`, `sshd -T`). **DSA was removed entirely in OpenSSH 10.0**;
  RSA only with SHA-2 and ≥ 3072 bits if there is no alternative; by default **ed25519** or **ed25519-sk**
  (FIDO2). Migration note: 10.x changed `Match` to shell-style *quoting* — **it can break existing
  configs**, and there is a security fix in `DisableForwarding`, which did not disable X11 or
  agent forwarding as documented.
- **Short-lived SSH certificates > `authorized_keys`**: an internal SSH CA with certificates lasting
  hours removes the problem of revocation and of orphan keys scattered across the fleet
  (`TrustedUserCAKeys`, `principals`, `HostCertificate` to authenticate the server too and kill
  TOFU). Issuance, the CA and its custody: `cryptography-pki-standards`; JIT elevation and the
  bastion as a service: `identity-access-management-standards`. Here: **the host only trusts the
  CA and `AllowGroups`**.
- **Access only via a bastion**, with `Match Address` restricting the source and no direct access
  from user networks. Any change to `sshd_config` is validated with `sshd -t` **and reloaded
  with a second session open** (§4).

### 3.7 auditd

- **A minimal set of useful rules.** A list of 400 rules copied from a generic repo produces gigabytes
  a day, saturates the disk, degrades the host and **nobody reads it**: it is signal loss disguised as
  compliance. Detection intelligence (TTPs, tool signatures) lives in the SIEM as
  Sigma rules, not in the auditd ruleset — see `detection-engineering-standards`.
- A defensible core: changes to `/etc/passwd`, `/etc/shadow`, `/etc/group`, `sudoers` and
  `sudoers.d`; execution of relevant SUID/SGID binaries; `execve` of shells by service
  accounts; module load/unload; time changes; mounts; modification of auditd's own configuration
  and of SSH's; denied accesses (`EACCES`/`EPERM`) on critical paths. Every rule with
  `-k <key>` so it can be searched and correlated.
- **Syntax and deployment**: syscall rules require `-a always,exit` (a bare `-S execve`
  generates nothing); human-user rules use `-F auid>=<UID_MIN> -F auid!=unset`
  substituting `UID_MIN` from `/etc/login.defs` **at deployment time** (auditd has no
  variables); `-e 2` at the end to make the ruleset immutable **only when the set is stable**
  (it requires a reboot to change it). Verification: `augenrules --check`, `augenrules --load`,
  `auditctl -l`, `auditctl -s`.
- **Operation**: in the RHEL family, `systemctl reload auditd` **does not work** (`service auditd
  restart` or `augenrules --load`); since audit-4.0 the rules are loaded via `audit-rules.service`.
- **Integrity and retention**: `/var/log/audit` on **its own partition** (auditd filling the root
  disk is an outage, and `space_left_action`/`admin_space_left_action` with `SUSPEND` **silently stop
  auditing** — decide between availability and auditing, and document it). Forwarding to the SIEM
  with `audisp-syslog`/`audisp-remote` from `/etc/audit/plugins.d/` (on Debian/Ubuntu it requires
  `audispd-plugins`). **The local log is weak evidence**: an attacker with root edits it; the remote
  copy, with a synchronised clock, is the one that counts. Where it goes and how long it is retained, in
  `observability-standards`.

### 3.8 Integrity and boot

- **Secure Boot enabled** and kernel + modules signed (with your own MOK if you compile out-of-tree
  modules). Without Secure Boot, `lockdown` is not a real boundary.
- **TPM 2.0 with measurement**: the PCRs measure the boot chain; useful only if something *checks* the
  measurement — sealing LUKS keys to PCRs or remote attestation. A TPM nobody queries is an expensive
  chip. Beware the fragility of PCRs and the attack on PCR 7 on its own (§2).
- **LUKS2** on disks with data, **and on the backups**. Unattended: **Clevis/Tang** (two or more
  Tang servers so as not to create a SPOF; `sss` with a threshold — **Tang stores no secrets**) or TPM2 with
  a signed policy. Hard rule: **if the host does not boot without a human, it is not in production**.
- **AIDE** (or the agent's FIM) with the database signed and stored off the host,
  initialised **after** applying the baseline and **re-initialised after every approved change** —
  otherwise everyone learns to ignore its reports.

### 3.9 Service containment with systemd (a front-line hardening control)

systemd sandboxing is a real containment control and **complementary to MAC**: MAC defines
what a domain can touch according to its label; systemd trims what the process *can ask* of the
kernel (namespaces, capabilities, syscalls, FS views). **Both** are applied;
`systemd-analyze security` **explicitly ignores SELinux and AppArmor**, so a good score does not
replace `enforcing` nor the other way round.

Every unit of your own (and every third-party unit exposing the network) carries, as a floor:
a dedicated `User=` or `DynamicUser=yes`, `NoNewPrivileges=yes`, `ProtectSystem=strict`,
`ProtectHome=yes`, `PrivateTmp=yes`, `PrivateDevices=yes`, `ProtectKernelTunables=yes`,
`ProtectKernelModules=yes`, `ProtectKernelLogs=yes`, `ProtectControlGroups=yes`,
`ProtectClock=yes`, `ProtectHostname=yes`, `ProtectProc=invisible`, `RestrictSUIDSGID=yes`,
`RestrictRealtime=yes`, `RestrictNamespaces=yes`, `LockPersonality=yes`,
`CapabilityBoundingSet=` (empty, with only the indispensable added),
`SystemCallFilter=@system-service` + `SystemCallArchitectures=native`,
`RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`, explicit `ReadWritePaths=`,
`IPAddressDeny=any` + `IPAddressAllow=` when the service talks to known destinations.

- **Threshold**: `systemd-analyze security <unit>` gives an *exposure level* from 0.0 to 10.0, with
  predicates (`UNSAFE` / `EXPOSED` / `MEDIUM` / `OK`). Target **< 4.0** on your own services;
  **measure and record** the value before/after. Since systemd v250 you can pass a **JSON
  policy** with your own requirements and compare units against it: that is what goes into CI, not
  a remembered number. Official caveat: it does not analyse the program's internal hardening, and there are services
  (`sshd`, `crond`, `atd`) that score badly **by design** — do not "fix" them blindly.
- **Overrides in `/etc/systemd/system/<unit>.d/override.conf`**, never editing the package's
  unit (§7). Relevant release notes: **v259** (17 Dec 2025) moves `libselinux`, `pam`,
  `audit`, `libseccomp` to `dlopen` and stops linking `libcap` — verify your minimal image
  includes them before assuming the sandbox is active; **v260** (17 Mar 2026) **removes support for
  SysV scripts** (`systemd-sysv-generator`, `rc-local.service`); **v261** is the current line.
- `MemoryDenyWriteExecute=yes` only where the runtime tolerates it (it breaks JIT: JVM, .NET, V8). It is a
  good example of a control that **is tested, not presumed**.

### 3.10 Filesystem, mounts and SUID

- **Partitioning**: `/var`, `/var/log`, `/var/log/audit`, `/tmp` and `/home` separated — the real
  goal is that **no disk consumer can take the host down** nor prevent logging.
- **Mount options**: `nodev` on everything that is not `/` or `/dev`; `nosuid` on `/tmp`,
  `/var/tmp`, `/home`, `/dev/shm` and network mounts; `noexec` on `/tmp`, `/var/tmp` and `/dev/shm`
  **measuring first** (installers, `pip`, package managers and some runtimes execute from
  `/tmp`; the exception, if any, is your own `TMPDIR`, not removing `noexec`).
- **SUID/SGID binaries**: an explicit inventory, compared at every audit
  (`find / -xdev -type f \( -perm -4000 -o -perm -2000 \)`). A new undeclared SUID is a security
  finding, not noise. Remove `setuid` from those not in use. Prefer **scoped capabilities** or
  systemd (`AmbientCapabilities=`) over a new SUID.
- **`/boot`** mounted with `nodev,nosuid,noexec` and a GRUB password for editing the boot
  line on hosts with uncontrolled physical access (useful precisely because `selinux=0` or
  `init=/bin/bash` are written there).

### 3.11 Golden image

- The hardening is applied **in the image**, not host by host: `oscap xccdf generate fix --fix-type
  kickstart` or `oscap-im` for **bootc/Image Mode** images (OpenSCAP 1.4.x), or the profile's Ansible
  remediation, integrated into the build (image builder, Packer).
- The image is **verified with the same scanner and the same profile** as the fleet, in the pipeline, and
  it is published **signed and versioned**. *Build once, promote the same artifact*: the image that is
  audited is exactly the one that gets deployed.
- The image carries *zero secrets*: no pre-embedded SSH host keys (regenerate on first
  boot), no credentials, no builder's `authorized_keys`.

## 4. Quality gates (they break the build or the deployment)

In increasing cost order:

1. **Lint and syntax validation** before any application: `visudo -c`, `sshd -t`,
   `augenrules --check`, `nft -c -f`, `ansible-lint`. Cheap, and it avoids most access
   lockouts.
2. **Application in check mode** in non-production (`--check --diff`) and review of the diff.
   Warning: the ansible-lockdown roles **do not support check mode** — do not use it as your only net.
3. **Compliance scan in CI** over the golden image, with the project's profile and tailoring:
   `oscap xccdf eval --profile <profile> --tailoring-file <t.xml> --results-arf arf.xml
   --report report.html`. **The build breaks if the score drops below the agreed threshold** or
   if a *new* failure appears that is not covered by a current exception. The threshold goes up over time; it is never
   lowered to make the build pass (§7).
4. **Post-hardening functional smoke test**: the decisive gate. After hardening you check that
   **the service really responds** (port, health endpoint, synthetic transaction, real
   authentication), not that systemd says `active`. Hardening without this test is a gamble.
5. **An access test with a rescue net**: changes to SSH, PAM, the firewall or `sudoers` are applied
   **with a second session open or an OOB console available**, and a fresh login is validated before
   closing the first one. Non-negotiable.
6. **Continuous fleet scanning** (Wazuh SCA or equivalent) with **drift as a finding**: a ticket
   with an owner and a date, just like a vulnerability. A host that drifts from the baseline between
   audits is exactly the one that will get you compromised.
7. **Baseline verification after every change** touching the OS (a major upgrade, a new role,
   a new service): automatic rescan and comparison against the previous report. Distro
   updates **reintroduce** default configuration frequently.
8. **A tested reboot**: a hardened host that does not boot after a reboot is worse than an
   unhardened one. A mandatory reboot in the validation pipeline — mounts, `lockdown`, module
   signing, TPM/LUKS, `modules_disabled` and `initramfs` are only really verified at boot.

## 5. Security of the hardening process itself

- **The baseline's supply chain is a supply chain**: hardening roles are pinned
  by version/tag — never `main` —, the diff is reviewed on update and they are run from
  your own repo or an internal mirror. A role that runs as root across the whole fleet is the most
  profitable target you have. Verify the signature when the provider publishes it (ansible-lockdown
  releases are GPG-signed).
- **An abandoned role = a risk, not a saving**: before adopting any hardening content,
  verify the last release and its activity (§8). An unmaintained role applies an expired benchmark and
  gives a feeling of compliance.
- **The scanner is not harmless**: `oscap` with `--remediate` modifies the system. Automatic remediation
  in production from the scan is forbidden; the scan measures, the code applies.
- **Secrets**: GRUB passwords, boot hashes, LUKS keys, `become_pass` and
  agent credentials go in Vault/sops, never in the repo nor in role variables in the clear. A
  GRUB password hash in a public repo is an exposed credential.
- **Compliance reports are sensitive data**: an OpenSCAP ARF/HTML is a map of the host's exact
  weaknesses. Restricted access, not in an open bucket nor in the pipeline's public
  artifact.
- **A record of who hardens**: baseline changes are run from CI with their own identity
  and are audited. Nobody applies a hardening role from their laptop with their personal account.
- **Hardening does not replace patching**: 2026 has left explicit examples of kernel flaws
  that **void the baseline's guarantees** (local root escalations and MAC bypasses operating below
  the policy layer). When the finding is in the kernel, the only reliable mitigation is to
  patch and reboot — coordinate it with `vulnerability-management-standards`.

## 6. Operability and cost

- **Every control has a cost; the one you do not measure is paid for in production**. Measure with the real workload
  before pinning: CPU mitigations (verified order of magnitude: ~1-10% depending on the case, §3.4),
  `auditd` (I/O and CPU proportional to the number of rules), AIDE (scan I/O: off-peak),
  `MemoryDenyWriteExecute` (incompatible with JIT), `noexec` (breaks installers),
  `lockdown=confidentiality` (breaks profiling and debugging).
- **Compliance telemetry**: export the score per host as a metric and alert on a
  *downward trend* and on *hosts not scanned in N days*. A host that has stopped reporting is
  a control failure, not a gap in the dashboard.
- **Diagnosis under a hardened system**: document in the runbook how to debug with
  `dmesg_restrict`, `ptrace_scope` and `ProtectProc=invisible` active — otherwise, the first serious
  incident will end with somebody disabling everything "temporarily".
- **Rollback**: every hardening change has a known and tested revert (the role must be able to
  unapply the specific control). Without a tested revert, production is not touched.
- **Reboots**: livepatching does not remove the reboot, it postpones it — and the vendors themselves require it
  (kpatch forces you to update the kernel and reboot ≥2 times a year; Canonical only generates patches for
  a kernel for 9-13 months). A scheduled reboot window and **the uptime counter as a risk
  signal**, not a source of pride.
- **Compatibility**: hardening and automation get in each other's way (`noexec` on `/tmp` against Ansible,
  `nosuid` against `become`, `RestrictNamespaces` against containers). Solve it with
  configuration (your own `remote_tmp`, `pipelining=true`), not by removing the control.

## 7. Sustainability and prohibitions

**Cadence**
- Review the **benchmark version** quarterly (CIS publishes continuous updates; DISA,
  quarterly) and when each major distro version comes out. Changing benchmark is a project.
- Update **SSG/ComplianceAsCode and OpenSCAP** with the distro; do not mix SSG content from one
  minor version with another (Red Hat explicitly advises against it: hardening content and components
  may not be backward compatible).
- Review **expired exceptions** every cycle: an exception without a date does not exist.
- Re-evaluate the `sysctl` list, blacklisted modules and SSH algorithms when moving to a new major
  kernel or OpenSSH version: **what was hardening three years ago can be degradation today**.
- Do not leave an EOL distro in production without a dated exit plan. Verified Aug 2026: **RHEL 10.2
  and RHEL 9.8** (both 20 May 2026; RHEL 10 Full Support until May 2030, RHEL 9 until May 2027);
  **Fedora 44** (28 Apr 2026); **Debian 13.6 "trixie"** (11 Jul 2026; full support to Aug 2028,
  LTS to Jun 2030) with **Debian 12 leaving regular support on 11 Jul 2026**; **Ubuntu 26.04 LTS**
  (23 Apr 2026 → Apr 2031, ESM to 2036) and **24.04 LTS** (→ Apr 2029). **The RHEL trap**: during
  Maintenance Support **only the latest minor receives patches** — staying on 9.7 with 9.8 published is
  being de facto unsupported.

**FORBIDDEN**
- ❌ **Disabling a control "to make it work"** without diagnosis, without a documented exception and without
  a planned revert. That includes `setenforce 0`, stopping the firewall, `chmod 777` and removing `noexec`.
- ❌ **Applying CIS/STIG blind in production** without a prior rehearsal and without an exception catalogue.
- ❌ **Extrapolating a benchmark from another distro version** (e.g. applying the Ubuntu 24.04 CIS to
  26.04, which has no benchmark yet) without a rule-by-rule review and without declaring it as your own baseline.
- ❌ A baseline **without documented exceptions** (even if all are applied: an empty list is
  declared), or exceptions **without an owner and without an expiry date**.
- ❌ **Lowering the score threshold** to make the build pass, or marking rules as "not applicable" without a
  written reason.
- ❌ `NOPASSWD: ALL` in sudo; rules with wildcards over paths; binaries that allow escaping to a
  shell; allowing `sudo --chroot`/`-R`; `sudo` for a generic "all technicians" group.
- ❌ Editing the PAM stack by hand on distros managed by `authselect`.
- ❌ Shared accounts, remote root login, SSH password authentication, non-expiring SSH keys
  scattered across the fleet.
- ❌ **Silencing OpenSSH's post-quantum warning** (`WarnWeakCrypto`) instead of updating the
  server; pinning `Ciphers`/`KexAlgorithms`/`MACs` lists copied from an old guide without
  checking what the current binary negotiates.
- ❌ `mitigations=off` (or disabling individual mitigations) without measurement, without approval from the
  risk owner, and **never** on multi-tenant hosts or ones running third-party code.
- ❌ Disabling MAC (`selinux=0`, AppArmor stopped) as a solution — see `selinux-standards`.
- ❌ Giant auditd rulesets copied without review; `/var/log/audit` without its own partition; an auditd
  that only writes locally with no forwarding to the SIEM.
- ❌ An AIDE database stored only on the host it audits; integrity reports
  nobody reviews; AIDE < 0.19.2.
- ❌ Editing the package's systemd units instead of using `override.conf`; network services running
  as root without sandboxing.
- ❌ Automatic remediation (`oscap --remediate`) directly against production.
- ❌ Applying two hardening roles simultaneously (ansible-lockdown + devsec.hardening) on the
  same host.
- ❌ Using livepatching as an excuse never to reboot, or as a substitute for the patching cycle.
- ❌ Sealing LUKS keys to fragile PCRs without a signed policy, without a PIN and without a recovery
  passphrase held off the host.
- ❌ Pinning benchmark versions, distro versions, EOLs or algorithms **from memory** without the verification in §8.

## 8. Mandatory web verification

Before pinning any concrete fact, **look it up — do not remember it**:

1. **The current CIS Benchmark version for the exact distro** on `cisecurity.org` or CIS WorkBench.
   Verified Aug 2026 (§2), including the finding that **Ubuntu 26.04 LTS has no benchmark yet**.
2. **The SCAP Security Guide / ComplianceAsCode release** and the profiles available for your product
   (verified Aug 2026: **v0.1.81**, 1 Jun 2026). **Declared gap**: it was not possible to obtain the
   **exhaustive list of profiles per product** (`complianceascode.github.io/content-pages/
   product-guides.html` → 404 and `static.open-scap.org/ssg-guides/` → 403); check with
   `oscap info` against the installed datastream, not from memory.
3. **The DISA STIG release** for your OS. **Declared gap**: RHEL 9 V2R8, RHEL 10 V1R1 and Ubuntu 24.04
   V1R5 were verified **via third parties** (Tenable, BigFix, Red Hat), **not** on `public.cyber.mil` —
   confirm at the official source before committing contractually.
4. **The current ANSSI-BP-028 version** on `cyber.gouv.fr` (verified: **v2.0**, Oct 2022, in SSG
   since 0.1.73). **Declared gap**: it was not possible to rule out the existence of a later version.
5. **The applicable CCN-STIC guides** on `ccn-cert.cni.es` and the ENS portal (verified:
   **CCN-STIC 610-25** with annexes A/Rocky, B/Arch, E/Debian). **Declared gaps**: the **letter of
   the Ubuntu and Fedora annexes**, and whether 610-25 **formally repeals** the per-product
   `610Axx` series (which is still published). The text of **RD 311/2022** was not verified against the BOE either.
6. **OpenSCAP, Lynis and Wazuh**: version and maintenance (verified Aug 2026: OpenSCAP **1.4.4**,
   Lynis **3.1.7**, Wazuh **4.14.7**; all three active). Also check **which version your distro
   packages**, which usually lags far behind.
7. **Ansible hardening roles**: the latest release and activity before adopting them (verified
   Aug 2026: ansible-lockdown RHEL9-CIS **v2.2.0** and UBUNTU24-CIS **v1.6.0**; devsec.hardening
   **10.6.0**). Do not adopt a role with no release in the last year. **Declared gap**: the exact
   minimum `ansible-core` version devsec.hardening 10.6.0 requires (the documentation says ≥ 2.16 and
   the release declares 2.21) — check it in the `galaxy.yml` of the version you install.
8. **OpenSSH**: the installed version and the real default algorithms (`ssh -Q kex`, `sshd -T`) and the state
   of the post-quantum KEX on `openssh.com/pq.html` (verified Aug 2026: **10.4**, 06 Jul 2026).
   **Declared gap**: the **exact list of default MACs in 10.x** was not verified (with AEAD the
   MAC list is not used, so its practical relevance is low), nor whether DSA was disabled at
   compile time in 9.8 or in 9.9 — its **complete removal in 10.0 is verified**.
9. **systemd**: the installed version and the sandboxing directives in that version's man page (verified
   Aug 2026: **v261** is the current line; v260 17 Mar 2026; v259 17 Dec 2025). **Declared gaps**:
   the **exact date of v261** and the **numeric cut-offs of the exposure score** (the predicates exist;
   the 9.0/7.5/5.0 thresholds circulate on forums but **are not in the manual**) — do not cite cut-off
   numbers, cite the predicate the tool returns.
10. **audit-userspace**: version and operational changes (verified Aug 2026: the 4.1.x/4.2 line; rule
    loading via `audit-rules.service` since 4.0; state in `/run` since 4.1.2).
11. **Distro versions and EOLs** on `endoflife.date` or the vendor's official lifecycle (verified
    Aug 2026 in §7). **Declared gap**: a discrepancy in the **end of ELS for RHEL 9** between
    2035-05-31 and 2036-05-31 — confirm with Red Hat before using it in a plan.
12. **Current CVEs** in the chain you touch, with KEV/EPSS. Verified and citable: **sudo
    CVE-2025-32462 / CVE-2025-32463** (fix in 1.9.17p1; 32463 in KEV since 29 Sep 2025);
    **linux-pam CVE-2025-6020 and CVE-2025-8941** (`pam_namespace`, fix in 1.7.1); **AIDE
    CVE-2025-54409** (fix in 0.19.2); **VMSCAPE CVE-2025-40300**. **Declared gaps**: the 2026
    CVEs in `polkit`/PackageKit/glibc could only be corroborated with **medium-reliability sources**
    (security blogs and PoCs, not NVD/upstream) — **they are not cited here**; consult them in your
    vendor's advisory. And never cite an identifier from memory.
13. **The state of your vendor's livepatching**: coverage, architectures, windows and limits
    (verified Aug 2026 in §2). **Declared gap**: **SUSE Linux Enterprise Live Patching**
    (historically kGraft) was not verified against a SUSE source.
14. **CPU mitigations**: microarchitectural vulnerabilities published since the last
    review and their cost. **Declared gap**: **no new confirmed disclosure in 2026** was found
    (the most recent verifiable one is VMSCAPE, Sep 2025) and **there is no up-to-date figure for the
    cost of `mitigations=off`** — measure it with your workload and check
    `/sys/devices/system/cpu/vulnerabilities/`.
15. **Kernel hardening sysctls** (`kptr_restrict`, `dmesg_restrict`, `yama.ptrace_scope`,
    module signing). **Declared gap**: they were not verified against a primary source; no
    changes from the classic recommendation were detected, but confirm it in the kernel documentation for your
    version before pinning them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
