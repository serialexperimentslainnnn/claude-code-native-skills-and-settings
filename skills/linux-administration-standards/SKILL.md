---
name: linux-administration-standards
description: Day-to-day Linux system administration, distribution-agnostic. Use when writing or debugging systemd units and .timer/.mount/.socket/.target files, systemctl edit overrides, Type=/Restart=/After=/Requires= semantics, systemd-analyze blame or critical-chain boot latency, systemd-run transient units, user units and loginctl enable-linger, journald retention (journalctl, journald.conf, SystemMaxUse, Storage=persistent), nsswitch.conf, /etc/fstab versus .mount units, autofs, cgroups v2 resource control (systemd-cgtop, MemoryMax=, CPUQuota=, IOWeight=, systemd-oomd, oomd.conf), NetworkManager/nmcli/nmstate versus systemd-networkd versus netplan renderer choice, resolvectl and /etc/resolv.conf, chrony or systemd-timesyncd clock drift, reboot-required policy after patching, rescue and emergency targets, chroot recovery, or diagnosing a slow or unbootable host with dmesg, iostat and pidstat.
---

# Linux system administration standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **day-to-day of the Linux operating system, regardless of distribution**:
the mental model of systemd and its units, boot and its latency, logging with journald,
users/groups/sessions, processes and resource control with cgroups v2, everyday mounts,
network configuration **from the host**, packages and reboot policy, system time, and the
**systematic diagnosis of a host** that is slow, will not boot or has run out of memory.

Triggers: `systemctl`, `systemctl edit`, `.service`/`.timer`/`.mount`/`.socket`/`.path`/
`.target`/`.slice` files, `Type=`, `Restart=`, `After=`, `Requires=`, `BindsTo=`, `WantedBy=`,
`systemd-analyze blame`/`critical-chain`/`verify`, `systemd-run`, `loginctl`, `enable-linger`,
`journalctl`, `journald.conf`, `SystemMaxUse=`, `Storage=persistent`, `systemd-cgtop`,
`systemd-cgls`, `MemoryMax=`, `MemoryHigh=`, `CPUQuota=`, `IOWeight=`, `systemd-oomd`,
`oomd.conf`, `/etc/nsswitch.conf`, `/etc/fstab`, `systemd-mount`, `autofs`, `nmcli`, `nmstate`,
`systemd-networkd`, `netplan`, `resolvectl`, `/etc/resolv.conf`, `chronyc`, `timedatectl`,
`needrestart`, `dnf needs-restarting`, `rescue.target`, `emergency.target`, recovery `chroot`,
`dmesg`, `iostat`, `pidstat`, "the server is slow", "it will not boot", "it ran out of
memory", "the disk filled up with logs".

**Guiding principle**: **almost nothing diagnosed as "the system" is the system.** A
host that "runs out of memory" is almost always **a unit with no limit**; a slow boot is
**one specific unit in the critical chain**; a full `/var` is **journal retention left unpinned**.
The work consists of **attributing the symptom to a specific unit, cgroup or configuration file**
before touching anything — and of not touching production blind.

**Boundary with the distribution**: this skill is **agnostic**. Everything that holds equally on Debian,
Ubuntu, SUSE and RHEL lives here. Whatever is a **Red Hat family particularity** (`dnf5`, RPM and
repos, `rpm-ostree`/`bootc`, `leapp`, `subscription-manager`, `grubby`, `tuned`, `firewalld`,
RHEL/Fedora/Alma/Rocky lifecycles) belongs to `rhel-fedora-standards`, which **develops** what is
here for that family and does not contradict it.

**Not applicable**: see `onprem-standards` (**platform umbrella**: hardware, OOB/BMC plane,
hypervisor, fleet topology and inventory, fleet patching cadence — its §1.3 invariants are
inviolable; **this skill takes over the systemd block that its §3 marked as
provisional criteria**), `rhel-fedora-standards` (Red Hat family particularities),
`linux-hardening-standards` (**everything that is a measurable security control**: CIS/STIG/
ANSSI/CCN-STIC baselines, OpenSCAP/Lynis, `sysctl.d`, `sshd_config`, `auditd`, `sudoers`, `pam_faillock`,
`login.defs`, `noexec`/`nosuid`/`nodev` mount options, SUID auditing, **unit sandboxing as a
control** (`ProtectSystem=`, `PrivateTmp=`, `systemd-analyze security`), AIDE,
Secure Boot/TPM/LUKS, unattended security updates and livepatching — **here the
`Type=`, the `Restart=`, the dependencies and the diagnosis; there the confinement and its measurement**),
`selinux-standards` (MAC: AVC denials, `semanage`, `restorecon`, booleans, custom policy;
if a service does not start **because of a denial**, the diagnosis is there — here the diagnosis of
why the unit fails through dependencies, ordering, resources or configuration),
`bash-linux-scripting-standards` (hygiene of the script that automates anything from here:
`set -Eeuo pipefail`, ShellCheck, `flock`, `mktemp`, bats), `iac-standards` (**the boundary is
repeatability**: what is applied to more than one host or more than once **is automated there** with
idempotent Ansible and its CI; **here it is decided what is configured, with what criteria and how it is
diagnosed when it fails** — a playbook that does not know which `Type=` to set is not fixed with more
`ansible-lint`), `networking-standards` (network **design**: addressing, VLAN, routing, BGP,
firewall policy between zones, DNS as a service, VPN, proxies — **here only the
host's own network configuration**: which manager is used, how an interface is declared and how `resolvectl` is read),
`observability-standards` (where metrics and logs are sent, retained and correlated; **here the
local side**: journald, its retention and its forwarding), `vulnerability-management-standards` (CVE
triage with CVSS/EPSS/KEV and remediation SLA — **here the reboot policy after the patch**),
`identity-access-management-standards` (IdP, SSO, MFA, bastion and JIT elevation — here `nsswitch`,
`loginctl` and the local session), `windows-server-ad-standards` (**explicit decision**: the forest, the
domain, GPO, Kerberos and the design of corporate identity are theirs; **the integration of the Linux
host with AD — `realmd`, `sssd.conf`, `adcli`, `nsswitch`, `pam_sss`, UID/GID mapping, `id` of a
domain user, keytab expiry — falls on this side**, because it is Linux system configuration;
the Kerberos ticket that fails to validate because of clock drift is also from here, §6),
`kubernetes-standards` (the host as a cluster node: kubelet, pod cgroups, draining),
`container-runtime-security-standards` (seccomp, container escape, runtime detection),
`homelab-standards` (personal lab: the boundary is the **rigour required**, not the size),
`incident-management-standards` (the incident declaration, the IC and the communication while you
diagnose), `incident-response-forensics-standards` (**if the host may be compromised, stop
and hand over**: the order of volatility overrides performance diagnosis; rebooting "to see if it
fixes itself" destroys evidence), `bcdr-standards`, `grc-compliance-standards`, `perl-standards` (the system Perl is
part of the distribution and **is not touched**; application Perl and its dependency management are
theirs), `lua-standards` (the nginx configuration is network and platform; the Lua
embedded in it, theirs), `operating-systems-standards` (**the systemd knob is from here, the
kernel semantics behind it are theirs**: what `memory.high` really does versus
`memory.max`, when the OOM killer kicks in and with what criteria; here how it is declared in the unit and
how it is diagnosed).

Also:
`linux-storage-standards` (LVM, multipath, NVMe, filesystem design and tuning,
`fstrim`, software RAID — **here only the day-to-day mount**: `fstab` vs. `.mount` units,
`systemd-mount`, autofs, and "the disk is full"; **there** how it is sized and tuned),
`backup-recovery-standards` (copy and restore mechanics),
`podman-systemd-containers-standards` (Podman and Quadlet — **precise boundary**: the
`.container`/`.pod`/`.volume`/`.image` Quadlet units and their generator are theirs; the
behaviour of systemd that runs them —`Type=notify`, ordering, `Restart=`, cgroup, journal— is from
here), `zfs-standards`, `ha-clustering-standards` (Pacemaker/Corosync — a resource
managed by the cluster **is not touched with `systemctl`**, §7), `dns-standards`,
`firewall-policy-standards`, `vpn-standards`, `libvirt-kvm-standards`, `proxmox-ve-standards`,
`network-troubleshooting-standards` (**delicate and explicit boundary**: the diagnosis
**of the host** belongs to this skill —is the interface `UP`?, is the correct network manager managing it?,
is there a default route?, does `resolvectl status` resolve?, is the socket in `LISTEN` with `ss -ltnp`?,
does the service fail because of a resource limit or because of a dependency?—; the diagnosis **of the network** is theirs
—capture with `tcpdump`/Wireshark, MTU/MSS and fragmentation, path and latency between hosts, loss,
route asymmetry, which intermediate firewall drops—. **The cut-off rule**: if the problem reproduces
with an `ss`, an `ip`, a `journalctl` and a `curl` to `localhost`, it is yours; if you need to
look at both ends at once or put a sniffer in place, it is theirs).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Service manager | **systemd**, stable branch **v261** (v261.2, 23-Jul-2026); live maintenance branches: 258.x, 259.x, 260.x | Verified Aug 2026 via `api.github.com`. **Do not assume the upstream version in your distro**: check with `systemctl --version` — the distro lags behind and the new directives will not exist |
| SysV compatibility | **None. Native unit always** | Verified in the v260 `NEWS`: **System V script support was removed** (`systemd-sysv-generator`, `systemd-rc-local-generator`/`rc-local.service`, `systemd-sysv-install`). v260 also raises the **kernel baseline to 5.10** (5.14 recommended; 6.6 for full functionality). An `/etc/init.d/` or an `/etc/rc.local` that "works" today **disappears** when v260 reaches your distro: audit now and migrate |
| cgroup hierarchy | **v2 (unified), only** | Verified in the v258 `NEWS`: **cgroup v1 support (`legacy` and `hybrid`) removed**; v2 is always mounted at boot and in `systemd-nspawn`. Minimum kernel raised to 5.4 in v258. If `/proc/cmdline` has `systemd.unified_cgroup_hierarchy=0`, that is debt: remove it before updating |
| Scheduled tasks | **systemd timers** for everything new | Logs in the journal, `Persistent=true` recovers missed runs, `RandomizedDelaySec=` avoids the thundering herd, real dependencies and queryable state (`systemctl list-timers`). `cron` only for legacy that will not be touched; the two **are not mixed** for the same task |
| Unit overrides | **`systemctl edit <unit>`** → `/etc/systemd/system/<unit>.d/override.conf` | The unit installed by the package is **never** edited: the next update overwrites it, silently. `systemctl edit --full` only if it has to be rewritten entirely, and then it is documented why |
| Transient unit | **`systemd-run`** (with `--unit=`, `--property=`, `--on-calendar=`, `--scope`) | A one-off task that must survive the SSH session, or that needs resource limits, goes in a transient unit — **not in `nohup`, `screen` or `&`**: no cgroup, no logs, no limits and no traceability |
| Logging | **journald with persistent storage** (`Storage=persistent`) and explicit limits (`SystemMaxUse=`, `SystemMaxFileSize=`, `MaxRetentionSec=`) | The volatile default loses the log of the previous boot — exactly the one needed after a crash. With no explicit limit, `/var/log/journal` grows to 10% of the FS |
| Log aggregation | **Forwarding to a central aggregator** from journald (`systemd-journal-upload`, or a vector/promtail/rsyslog agent) | The stack design is set by `observability-standards`. Here the invariant: **the log that only exists on the host that failed does not exist** |
| Local syslog | Only if a consumer requires it (`ForwardToSyslog=yes`) | Keeping rsyslog **and** journald writing the same thing duplicates the disk and the work. Pick one as the source and the other as transport |
| Host network management | **The distro's native one, only one**: NetworkManager (`nmcli`/`nmstate`) on RHEL/Fedora and on desktops; **netplan** on Ubuntu (renderer `networkd` on server, `NetworkManager` on desktop); `systemd-networkd` on Debian/minimalist servers and containers | Verified Aug 2026. **The hard rule is not to mix**: two managers on the same interface produce duplicate IPs, overwritten DNS and boots that hang for 2 minutes. NetworkManager is *greedy* (it manages whatever it is not forbidden); `networkd` only manages what is declared to it |
| Host DNS resolution | **`systemd-resolved`** with `/etc/resolv.conf` → symlink to `/run/systemd/resolve/stub-resolv.conf`, and **`resolvectl status` as the source of truth** | `cat /etc/resolv.conf` **does not tell you what is resolving** when there is a stub, per-interface split-DNS or DNS via VPN. Editing `/etc/resolv.conf` by hand on a system with `resolved` is a change that is lost at the next network event |
| Time | **chrony** on servers; `systemd-timesyncd` (SNTP) only on clients/VMs with no requirement | chrony converges faster, tolerates bad networks, supports NTS and serves as a server. `timesyncd` **is not an NTP server** nor does it discipline well after suspend |
| Memory control | **Limits in the unit** (`MemoryMax=`, `MemoryHigh=`, `MemoryMin=`) per service, plus `systemd-oomd` where the distro ships it | Verified: `systemd-oomd` comes **enabled by default on Fedora** (since F34, it replaced earlyoom) and **packaged but disabled on RHEL** (`systemctl enable --now systemd-oomd`, `/etc/systemd/oomd.conf`). It acts on **PSI** before the kernel OOM killer, and kills the **cgroup**, not a lone process |
| Reboot policy after patching | **Explicit and automated**: `needrestart` (Debian/Ubuntu) or `dnf needs-restarting -r` (RPM family), with a defined window | A `glibc`/`openssl` patch applied without restarting the process **is not applied**. See §5 for the `needrestart` CVE |
| User units | `systemctl --user` for the user's processes; **`loginctl enable-linger <user>`** only if they must survive logout | Without *lingering*, the user unit dies when the last session closes — the usual cause of "the rootless container stops by itself at night" |

## 3. Structure and conventions

### 3.1 Anatomy of a correct unit

Every service unit of your own complies, without exception:

- **Correct `Type=`**, and this is not cosmetic: `notify` if the software speaks `sd_notify` (the
  best: systemd knows when it is *really* ready); `exec` if it is a normal foreground
  process; `oneshot` + `RemainAfterExit=` for initialisation tasks; `forking` **only** if the
  software daemonises and cannot be asked to do otherwise (and then with `PIDFile=`).
  `Type=simple` is considered "ready" as soon as it does `fork/exec`: it **lies** about availability
  and breaks any `After=` that depends on it.
- **`Restart=on-failure`** with `RestartSec=` and **`StartLimitIntervalSec=`/`StartLimitBurst=`**
  tuned. `Restart=always` hides permanent failures in a loop; with no start limit, a
  broken service punishes the CPU and fills the journal.
- **Real dependencies, not decorative ones.** This is the most common and most expensive mistake:
  - `After=` is **ordering only**, not a requirement. `Requires=` is a **requirement**, not ordering. You need
    **both** for "start after X and do not start if X failed".
  - `Wants=` is a **weak** dependency (it starts X, but carries on if it fails): it is the correct
    default for most cases.
  - `BindsTo=` for "if X stops, I stop" (devices, mounts, sockets).
  - **`After=network.target` is almost never what you want**: it means "after the network has been
    *configured*", not "with an IP and a route". If the service does `bind()` to a specific IP or
    needs to reach the network at startup, it is `Wants=network-online.target` **and**
    `After=network-online.target`, **and** the corresponding wait service enabled
    (`NetworkManager-wait-online` or `systemd-networkd-wait-online`). And even then: **a service
    that retries is better than a `network-online.target` that delays boot by a minute.**
  - Dependency on a mount: `RequiresMountsFor=/path` — not `After=` on the `.mount` unit
    guessed by hand.
- **Sandboxing**: it is a **security control and its criteria are set by `linux-hardening-standards`**
  (`ProtectSystem=strict`, `PrivateTmp=`, `NoNewPrivileges=`, `CapabilityBoundingSet=`,
  `systemd-analyze security`). Here only the operational invariant: **a unit of your own without a
  dedicated user (`User=` or `DynamicUser=`) is a finding**, and `systemd-analyze security` is
  run before signing the unit off.
- **Explicit resource limits** on any service that can grow: `MemoryMax=`,
  `MemoryHigh=`, `CPUQuota=`, `TasksMax=`, `IOWeight=`. See §6.
- **No logic in the unit**: `ExecStart=` points to a binary or to a versioned script from the repo,
  not to a chain of `sh -c` with pipes and `&&`. If logic is needed, it is a script
  (`bash-linux-scripting-standards`).

### 3.2 File conventions

- Your own units in `/etc/systemd/system/`; **never** in `/usr/lib/systemd/system/` (package
  territory). Overrides in `<unit>.d/override.conf`.
- `systemctl daemon-reload` after any unit file change; `systemctl
  reenable` if the `WantedBy=` change. A `systemctl restart` without `daemon-reload` applies the old
  unit: the classic cause of "I changed the file and it has no effect".
- Configuration by *drop-in* in everything that supports it (`/etc/systemd/*.conf.d/`,
  `/etc/sysctl.d/`, `/etc/systemd/journald.conf.d/`, `/etc/NetworkManager/conf.d/`), not by editing
  the package's main file. Numeric prefix for ordering (`50-`).
- A service's credentials with **`LoadCredential=`/`systemd-creds`**, not in `Environment=` nor in
  an `EnvironmentFile` readable by everyone (the detail belongs to `secrets-management-standards`).
- Mounts: `/etc/fstab` is still valid and is the sensible default (systemd translates it into `.mount`
  units automatically). You move to an explicit `.mount` unit when you need
  **ordering or a dependency** that `fstab` does not express. Network mounts and anything that may not be
  available: `noauto,x-systemd.automount` or autofs — **never** a blocking network mount without
  `_netdev` and without a timeout, because it turns a downed NFS into a host that will not boot.

### 3.3 Fleet conventions (inherited from the umbrella)

- Every host **rebuildable from code**; a manual change in prod is *drift* and is a finding.
  The repeatable is automated in `iac-standards`; **what is written by hand is the documented
  exception, not the habit**.
- **No host data from memory**: IP, role, VLAN, owner and criticality come from the inventory.
- No service, host or certificate without an owner and without an end-of-life date.

## 4. Quality: validate before reloading, verify afterwards

In increasing order of cost. **None is optional in production.**

1. **Syntax validators before applying**, whenever they exist:
   - `systemd-analyze verify /etc/systemd/system/<unit>` — detects invalid directives,
     non-existent dependencies and misplaced paths **without starting anything**.
   - `sshd -t` (or `sshd -T` to dump the effective config), `visudo -c` / `visudo -f`,
     `nginx -t`, `named-checkconf`, `chronyd -Q`, `nft -c -f`, `netplan generate` (not `apply`),
     `nmcli con show` after `nmcli con modify`.
   - `systemd-analyze security <unit>` for the sandboxing (criteria in `linux-hardening-standards`).
2. **Post-change smoke test, always**: `systemctl is-active` **is not a test**. A service
   `active (running)` that does not listen on its port is still down for the user. The gate is:
   port in `LISTEN` (`ss -ltnp`), health endpoint response, and **journal with no new errors**
   (`journalctl -u <unit> --since "-2 min" -p warning`).
3. **Rescue session open when touching remote access.** Before reloading `sshd`, host firewall,
   network or PAM: a second already-authenticated SSH session (or the OOB/serial console) open and
   **verified**, and the change confirmed from a **third** new connection before closing
   anything. Cheap complement: a `systemd-run --on-active=5m systemctl restart NetworkManager`
   (or reverting the config) as a safety net, cancelled as soon as access is confirmed.
4. **Change reversible by design**: the revert command is known **before** applying. If the
   revert does not fit on one line, it is not a change, it is a project — and it goes through a window.
5. **Real boot test** after any change to `fstab`, mount units, initramfs,
   network or boot manager: **reboot in a window**. A host that has been up for 400 days with
   changes and no reboot is a host whose boot nobody has tested.
6. **Rehearsal outside production** for anything touching boot, kernel or storage. The
   staging host exists for this.

## 5. Day-to-day security

> The baseline (CIS/STIG), `sysctl`, auditd, `sudoers`, PAM and sandboxing as a control belong to
> `linux-hardening-standards`; MAC belongs to `selinux-standards`. Here only what is inherent to
> daily operation.

- **Reboot policy = part of the patch.** `needrestart` / `dnf needs-restarting -r` decides;
  the result is recorded and there is a window. An updated `libssl` with 40 processes using the
  old binary in memory is an open CVE with a closed ticket.
  - **Relevant CVE in the tool itself**: `needrestart` **< 3.8** carried five local root
    escalations discovered by Qualys (Nov-2024), among them **CVE-2024-48990** (via
    the `PYTHONPATH` of a process of an unprivileged user). If you operate Debian/Ubuntu, verify
    the installed version and that the patch is applied — it is the perfect example of why the
    operations tool is also attack surface.
  - **CVE-2025-32463** (`sudo`, `-R`/`chroot` option): local root escalation. `sudo` is the
    tool that runs most on a managed host: its patching does not wait for the monthly
    window. The triage and the SLA are set by `vulnerability-management-standards`.
- **Journal as evidence**: `Storage=persistent`, `Seal=yes` (FSS) where the journal must be
  verifiable, and immediate forwarding to an aggregator **off the host** — an attacker with root wipes
  the local journal in a second. Retention and correlation belong to `observability-standards`;
  the chain of custody, to `incident-response-forensics-standards`.
- **Sessions and `nsswitch`**: the order in `/etc/nsswitch.conf` decides where users and
  groups come from. An `sss` before `files` with the directory down leaves the host unable to resolve even
  `root` for some operations; a `files` first with a local account sharing a name with a domain
  one is a silent back door. **It is reviewed explicitly, not inherited from the
  installer.**
- **`systemd-run` and transient units are not a permissions shortcut**: they inherit the context of
  whoever launches them. A "temporary" task launched as root that is still alive three months later is an
  undeclared service — it is declared or it is killed.
- **Before diagnosing performance, rule out compromise.** Unexplained CPU consumption, processes
  with no parent unit, odd outbound connections: that is not a capacity problem. You stop, you
  preserve and `incident-response-forensics-standards` takes over. **Rebooting destroys evidence.**

## 6. Performance, resources and operability

### 6.1 cgroups v2 is the real model

- **"The server ran out of memory" almost always means "a unit with no `MemoryMax=`".** With no
  limits, the kernel OOM killer picks the victim heuristically — and it usually picks badly (it kills the
  database, not the process that ran away). With per-unit limits, the failure stays **contained
  in the guilty service** and is attributable.
- Attribution tools, in this order: `systemd-cgtop` (consumption **per unit/slice**, which is
  the useful view), `systemd-cgls` (hierarchy), `systemctl status <unit>` (current memory and
  tasks), `systemctl show <unit> -p MemoryCurrent,MemoryMax,CPUQuotaPerSecUSec,TasksCurrent`.
- Directives: `MemoryHigh=` (**pressure and reclaim**, the preferred brake: it degrades instead of killing),
  `MemoryMax=` (**hard wall**, triggers cgroup OOM), `MemoryMin=`/`MemoryLow=` (protection of what is
  critical against reclaim), `CPUQuota=`/`CPUWeight=`, `IOWeight=`/`IOReadBandwidthMax=`,
  `TasksMax=` (containment of *fork bombs* and thread leaks).
- **They apply live**: cgroup properties take effect without restarting the service
  (`systemctl set-property <unit> MemoryHigh=2G` to test; the permanent change goes in the
  override, §3). Testing live and **then** persisting is the correct flow.
- **Group by *slice*** when there are workload classes: `system.slice`, `user.slice`, and your own slices
  (`app.slice`) with an explicit share. Protecting `system.slice` from `user.slice` prevents an
  interactive session from taking the host down.
- `systemd-oomd` acts on **PSI** before the OOM killer and kills the whole cgroup. Useful, but it **does
  not replace the limits**: it is the safety net, not the policy. Review
  `DefaultMemoryPressureLimit=` and `DefaultMemoryPressureDurationSec=` before enabling it on a
  server — the defaults are designed for the desktop.

### 6.2 Boot

- `systemd-analyze` (total time, firmware/loader/kernel/userspace) → `systemd-analyze blame`
  (units by time, **misleading**: a slow unit running in parallel delays nothing) →
  `systemd-analyze critical-chain [unit]` (**the view that matters**: the chain that actually
  determines the time) → `systemd-analyze plot > boot.svg` for the visual detail.
- Usual suspects for a boot that takes minutes: `*-wait-online` waiting for an interface that
  never arrives (DHCP on a VLAN with no server, half-configured bonding), network mounts without
  `_netdev`/timeout, a `Requires=` on something that does not exist, blocking DNS resolution.
- A slow boot **is measured before and after**. "It seems faster now" is not data.

### 6.3 Journald

- **What is NOT solved by rotating files by hand**: journald **does not use logrotate** and its retention
  is set in `journald.conf` (`SystemMaxUse=`, `SystemKeepFree=`, `SystemMaxFileSize=`,
  `MaxRetentionSec=`, `MaxFileSec=`). Deleting files from `/var/log/journal` by hand leaves the index
  inconsistent; the correct way is `journalctl --vacuum-size=`/`--vacuum-time=` and **fixing the
  policy**, not the symptom.
- **A `/var` full of logs is a policy problem, not a disk problem.** Adding space without setting
  retention guarantees repeating the incident with a more expensive disk. And if the volume comes from a
  service in a restart loop, the fix is the service (§3.1: `StartLimitBurst=`), not the
  retention.
- `journalctl` used with judgement: `-u <unit>` (unit), `-b -1` (**previous boot**: the one that matters
  after a crash — requires a persistent journal), `-p err..alert` (severity), `--since/--until`,
  `-f` (follow), `-k` (kernel), `-o json`/`-o verbose` (structured fields, including
  the real `_SYSTEMD_UNIT` and `_PID`), `--disk-usage`, `--verify`.
- Rotation ratio and space as a **monitored metric**, not as a surprise.

### 6.4 Time — the root cause nobody ever suspects

**Clock drift shows up in disguise**: "TLS broken for no reason" (certificate *not yet valid* /
*expired* according to the host), Kerberos rejecting tickets (typical tolerance of 5 minutes), logs
impossible to correlate across hosts, invalid JWT tokens, database replicas that
diverge, backups that overlap.

- `timedatectl` and `chronyc tracking` / `chronyc sources -v` in **every** diagnosis of "authentication
  fails" or "the certificate is not valid". It is the 5-second check that saves the afternoon.
- **Drift metric monitored with an alert** across the whole fleet (the threshold and the stack are set by
  `observability-standards`). A host with no working NTP is a host that has not failed yet.
- Time zone: **UTC on servers**, always. *localtime* is a presentation matter.

### 6.5 Layered diagnostic method

Faced with "it is slow" / "it does not respond", in this order and **noting what is ruled out**:

1. **What changed?** Last deployment, last patch, last config change. `journalctl --since`
   over the change window, `rpm -qa --last` / `zgrep` of the package manager log,
   history of the IaC repo. Most incidents are a recent change.
2. **Boot and kernel**: `systemctl --failed`, `systemctl list-jobs` (stuck units),
   `dmesg -T --level=err,warn` (OOM, disk reset, NIC errors, MCE, `blocked for more than
   120 seconds`).
3. **Resources, attributed by cgroup**: `systemd-cgtop`, `uptime`/*load average* read alongside
   `vmstat 1` (distinguish CPU from I/O wait in `D-state`), `free -m` with `available` (not
   `free`), pressure with **PSI** (`/proc/pressure/{cpu,memory,io}` — the most direct signal of "this
   is saturated" and the one `systemd-oomd` uses).
4. **I/O**: `iostat -xz 1` (`%util`, `await`, `aqu-sz`), `pidstat -d 1` (**which process**),
   `iotop`/`biolatency` if available. A high `await` with low `%util` points to remote storage,
   not to the disk.
5. **Network from the host**: `ip -br a` / `ip r` (interface, route), `resolvectl status` (effective DNS,
   **not `/etc/resolv.conf`**), `ss -ltnp` / `ss -s` (sockets, retransmissions), error/drop counters
   in `ip -s link`. **If the problem does not close here, cross the boundary** towards
   `network-troubleshooting-standards` (§1).
6. **Space and inodes**: `df -h` **and `df -i`** (the second is forgotten and is the cause of 20% of
   the "I cannot write" cases with apparently free disk), `du -x --max-depth=1`,
   `journalctl --disk-usage`, and **deleted files with the descriptor still open** (`lsof +L1`) — the
   classic "I deleted the log and the disk does not go down".
7. **The service**: `systemctl status`, `journalctl -u`, effective config (`sshd -T`, `nginx -T`),
   dependencies (`systemctl list-dependencies --before/--after`).

**Recovery when it will not boot**, in order of invasiveness:

- Console (OOB/serial/hypervisor) **first**: with no console there is no boot diagnosis, only
  blind reboots. This is a platform requirement (`onprem-standards`).
- `systemd.unit=rescue.target` (minimal multi-user, with FSs mounted) → `emergency.target`
  (shell only, root in *read-only*) → `rd.break` (stop in the initramfs) from the kernel
  command line, edited **for that boot**, not persisted.
- `systemd.log_level=debug` / `systemd.log_target=console` when boot fails without saying why;
  `journalctl -b -1 -p err` as soon as access is recovered.
- **Recovery chroot** (install media in *rescue* mode): mount the root, `mount
  --bind` of `/dev`, `/proc`, `/sys`, `/run`, enter, fix, **regenerate initramfs and
  update the boot manager if anything boot-related was touched**, exit cleanly. Specific
  precaution for the Red Hat family: if SELinux is active, a change made in a chroot can leave
  files mislabelled — the relabelling is planned (`selinux-standards`).
- **Production is never touched blind.** If there is no hypothesis, there is no change: there is data collection.
  And every live change during an incident is noted in the incident channel
  (`incident-management-standards`) with time and author — the postmortem is written from that.

## 7. Sustainability and prohibitions

**Cadence**
- OS security update: automatic in low tiers, weekly and orchestrated in production,
  **with a reboot policy** (§5). The fleet cadence is set by `onprem-standards`; the triage of the
  specific CVE, by `vulnerability-management-standards`.
- Major distro version jump: **rehearsed on a twin host**, with a tested revert and a
  window. Never on the host that matters first.
- Every systemd version that comes in with the distro: **read the `NEWS` of the versions skipped**
  before updating, looking for "Feature Removals and Incompatible Changes". That is where
  the things you had been using for years disappear (SysV in v260, cgroup v1 in v258).
- Half-yearly debt audit: `/etc/init.d/` with content, `/etc/rc.local`, `cron` with tasks
  that should be timers, package units edited by hand, mounts in `fstab` with no owner,
  `systemd-analyze verify` over all your own units.

**FORBIDDEN**
- ❌ Editing the unit installed by the package instead of a drop-in with `systemctl edit`.
- ❌ `Type=simple` (or the default) on a service others depend on: it lies about being ready.
- ❌ `After=` without `Requires=`/`Wants=` when what you want is a requirement — or the other way round.
- ❌ `After=network.target` expecting real connectivity. And `network-online.target` put in "just in
  case" everywhere, which delays the boot of the whole host.
- ❌ `Restart=always` on a permanent failure, or without `StartLimitBurst=`: an infinite loop that
  burns CPU and fills the journal.
- ❌ Services of your own without `User=`/`DynamicUser=` and without resource limits.
- ❌ Long-lived processes launched with `nohup`, `&`, `screen` or `tmux` in production: no cgroup,
  no limits, no logs, no owner. They go in a unit (or `systemd-run` if they are one-off).
- ❌ Adding new tasks to `cron` when timers exist; or duplicating the same task in cron **and** a timer.
- ❌ A volatile journal on a server, or one without a size limit; deleting files from
  `/var/log/journal` by hand instead of `--vacuum-*` and fixing the retention.
- ❌ Solving a full `/var` by growing the disk without setting the retention policy.
- ❌ Editing `/etc/resolv.conf` by hand on a system with `systemd-resolved`, or diagnosing DNS
  by reading that file instead of `resolvectl status`.
- ❌ Two network managers active on the same interface (NetworkManager + `systemd-networkd`,
  netplan + NM without a coherent renderer, `ifupdown` coexisting with any of them).
- ❌ Touching `sshd`, PAM, network or firewall **without a rescue session open or an OOB console**.
- ❌ Reloading a service without passing its validator (`sshd -t`, `visudo -c`, `nginx -t`,
  `systemd-analyze verify`) when one exists.
- ❌ Signing a change off because `systemctl is-active` says `active`.
- ❌ Blocking network mounts in `fstab` without `_netdev`, `nofail` or `x-systemd.automount`: a downed NFS
  turns into a host that will not boot.
- ❌ A production host with no working NTP or with a local time zone.
- ❌ `systemctl start/stop/restart` on a resource managed by a cluster (Pacemaker): it is
  managed with the cluster's tools or you cause a fencing.
- ❌ Rebooting "to see if it fixes itself" before collecting data — and **always** if compromise is
  suspected (it destroys volatile evidence).
- ❌ Manual changes in production that do not make it back to code/inventory (*snowflakes*).
- ❌ Disabling SELinux/AppArmor, the host firewall or `systemd-oomd` "to make it work", with no
  diagnosis and no revert date.
- ❌ Keeping SysV scripts or `/etc/rc.local` as a strategy: they disappear with systemd v260.

## 8. Mandatory web verification

Before pinning any version, directive, behaviour or date, **look it up — do not recall it**:

1. **systemd version in your distro** (`systemctl --version`) **and** the current upstream line. A
   directive that exists upstream may not exist on your host. Verified Aug 2026 via
   `api.github.com`: stable branch **v261** (v261.2, 23-Jul-2026); maintenance on 258.x, 259.x,
   260.x. **Do not read versions or dates from the HTML render of GitHub Releases: use `api.github.com` or
   the Atom feeds.**
2. **Upstream `NEWS` of every version you skip**, section "Announcements of Future Feature Removals
   and Incompatible Changes" — read directly from
   `raw.githubusercontent.com/systemd/systemd/vNNN/NEWS`, not from blogs.
3. **Unit directives**: `systemd.exec(5)`, `systemd.resource-control(5)`, `systemd.unit(5)`
   of **your** version. Defaults change between versions.
4. **The distro's default network manager** and exact versions before writing network
   configuration; and which `*-wait-online` service corresponds.
5. **Active CVEs** of the operations tools you use daily (`sudo`, `needrestart`,
   `openssh`, `systemd`, `chrony`, `polkit`) — they are attack surface with privileged local
   access. Prioritise with KEV/EPSS (`vulnerability-management-standards`).
6. **Distro EOL** on `endoflife.date` and in the vendor source before planning any
   patching or migration cycle.

**Declared gaps — NOT verified while writing this document; verify them before
relying on them:**

- **Removal of cgroups v1 in the specific distros** (not in systemd, which is already done: removed in
  v258). In which version of Debian/Ubuntu/SUSE it stops booting with
  `systemd.unified_cgroup_hierarchy=0` — **not verified**. There is also a claim circulating
  in blogs that "v260 disables cgroup v1 by default" which **contradicts** the v258 `NEWS`
  (where it is already removed): treat the blog source as unreliable and confirm in the `NEWS`.
- **Debian 13/14 and Ubuntu 26.04: exact default network manager per installation profile** —
  described here from secondary sources (`ifupdown` on Debian server, netplan+networkd on
  Ubuntu Server, netplan+NM on Ubuntu Desktop). **Not confirmed against official documentation.**
- **systemd version packaged by each live distro** (Debian stable, Ubuntu LTS, RHEL 9/10,
  Fedora 43/44) — **not verified one by one**. Check on the host before using any
  recent directive.
- **State and defaults of `systemd-oomd` on RHEL 10 and Ubuntu 26.04** — only verified that on
  Fedora it comes enabled by default since F34 and that on RHEL it is packaged disabled; the default
  thresholds in each version **not verified**.
- **Dates and details of the cited CVEs** (`CVE-2024-48990` in `needrestart` < 3.8,
  `CVE-2025-32463` in `sudo`): identified by search, **CVSS, exact affected versions and
  KEV status not verified**. Consult them at the source before setting an SLA.
- **`systemd-analyze verify` and its real coverage** (which classes of error it detects and which not) — not
  checked against the documentation of the current version.

If the web contradicts this document, **the web wins** — flag the discrepancy.
