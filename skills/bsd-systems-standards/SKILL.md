---
name: bsd-systems-standards
description: FreeBSD, OpenBSD and NetBSD as deliberate production choices, and their derivatives. Use when working with FreeBSD (freebsd-update, pkg install/upgrade with quarterly or latest branches, ports tree and make.conf, /etc/rc.conf, sysrc, service(8), bectl boot environments, zfs and zpool on FreeBSD, jail(8) and /etc/jail.conf, ezjail, iocage, BastilleBSD, AppJail, vnet jails, bhyve and vm-bhyve, pf.conf and pfctl, CARP, netgraph, dtrace on FreeBSD, kldload, loader.conf, FreeBSD RELEASE/STABLE/CURRENT branches), OpenBSD (syspatch, sysupgrade, pkg_add, /etc/pf.conf and pfctl -sr, pledge(2) and unveil(2), relayd, httpd, smtpd, iked, doas and doas.conf, rcctl, W^X, KARL, retguard, errata patches, signify), NetBSD (pkgsrc, bmake, npf.conf, sysinst, rump kernels), and their derivatives pfSense CE or Plus, OPNsense, TrueNAS CORE, FreeNAS, HardenedBSD, GhostBSD or DragonFly BSD — including deciding which BSD to use, or whether to use one at all.
---

# BSD systems standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**BSD is not legacy: it is a living family chosen for concrete reasons**, and this skill exists
to set out which ones. Confusing it with inherited proprietary Unix is the framing error: nobody
here "stayed" on BSD — somebody chose it, and must be able to defend why.

All three have new releases in 2026, support policies **that differ from one another** (§2) and a
narrow use case of their own:

- **FreeBSD** — the general-purpose one: **first-class ZFS, jails, `bhyve` and `pf`**. Its strong
  case is **storage and networking**: a ZFS file server, a stateful firewall, a
  router, a small virtualisation server. Beyond that it goes head to head with Linux and
  usually loses on ecosystem (§7).
- **OpenBSD** — the minimal-surface one: **secure by default**, `pledge`/`unveil`, and **the origin
  of `pf`**. Its strong case is the **firewall/VPN and the small exposed service** (relay, authoritative
  DNS, mail, SSH jump host). It is not a general application platform and does not claim to be.
- **NetBSD** — the portable one. **Bound it**: its argument is running on architectures nobody else
  covers and `pkgsrc` as a cross-platform package tree. In an ordinary x86/ARM data centre
  **there is no reason at all to choose NetBSD over FreeBSD**; saying so is part of the criteria.

Covers: the status and support policy of each one (§2); FreeBSD conventions that decide the
operation (§3); jails versus Linux containers and `pf` versus `nftables` (§4); what
OpenBSD teaches even if you do not deploy it (§5); operability and the derivative ecosystem —pfSense, OPNsense,
TrueNAS— (§6); and **when not to choose BSD** (§7).

**Not applicable**:
- `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` and `zfs-standards` (**already written**): **Linux and ZFS are theirs** — the
  design of `zpool`, RAIDZ, snapshots, replication and ARC tuning belongs to `zfs-standards`; **here
  only what is specific to ZFS on FreeBSD** (boot environments, ZFS as root, integration with
  jails).
- `firewall-policy-standards` (**already written**): **the filtering policy is theirs** —what is allowed,
  zones, default-deny, rule review—; here only **`pf` as an engine** and what choosing it implies.
- `networking-standards`, `vpn-standards`, `dns-standards` (the protocols and their design).
- `onprem-standards` (**the platform umbrella with the routing table**), `homelab-standards`
  (**the home lab is theirs**, where pfSense/OPNsense and TrueNAS are natural neighbours; here
  the operating system and licence criteria), `ha-clustering-standards`,
  `backup-recovery-standards`, `bcdr-standards`, `os-provisioning-standards`,
  `server-hardware-standards`, `identity-access-management-standards`,
  `secrets-management-standards`, `vulnerability-management-standards`,
  `detection-engineering-standards` (**endpoint detection and its rules are theirs**),
  `endpoint-security-standards`, `grc-compliance-standards`, `iac-standards`,
  `legacy-modernization-standards` and `migration-projects-standards`.
- `podman-systemd-containers-standards` and `kubernetes-standards`: **the container ecosystem
  is theirs**; here only the honest comparison with jails (§4).
- `aix-solaris-hpux-standards` and `macos-fleet-standards`: **BSD is not proprietary Unix** —it is not
  inherited, it is chosen, and it has no vendor contract behind it— **and macOS is not a server
  fleet**, even though it shares BSD ancestry. The name "Unix" lumps them together and they share almost
  nothing operationally.

## 2. Verified status and support policy

> Verify the latest version on the web before pinning it in a real project (§8).

| System | Current as of Aug 2026 | Support policy (verified) |
|---|---|---|
| **FreeBSD** | **15.1-RELEASE** (16 Jun 2026); 14.4-RELEASE (10 Mar 2026) | *"Each minor release is only supported for three months after the next minor release within the same major version"*. **`stable/15` until 31 Dec 2029; `stable/14` until 30 Nov 2028.** From FreeBSD 15 on: *"each stable branch is explicitly supported for 4 years from its dot-zero release"* (it used to be 5) |
| FreeBSD — short dates | 15.0 ends **30 Sep 2026**; 14.4 ends **31 Dec 2026**; 15.1 ends **31 Mar 2027** | **The minor release expires fast**: plan to update within the branch every few months, not every year |
| **OpenBSD** | **7.9** (current) and **7.8** (previous) | **Only the last two releases receive errata**; `-stable` is maintained for a year. Six-monthly cadence ⇒ **one system update every six months, mandatory and without exception** |
| **NetBSD** | **11.0** (Aug 2026); 10.x branch maintained | A major release stops being supported **one month after the second subsequent major**. NetBSD 8 and earlier, EOL |

**What decides in that table**: FreeBSD has long branches (4 years) but very short minor
releases; OpenBSD has no long branch at all and **forces a six-month cadence on you**. If your
organisation cannot sustain two updates a year of a system, **OpenBSD is ruled out
before you even look at its virtues**. That is the real filter, not the list of mitigations.

**Derivative ecosystem, with the licence read raw:**

| Product | Licence | Status |
|---|---|---|
| **pfSense CE** | **Apache License 2.0** — verified by reading the repository's `LICENSE` raw (literal header: *"Apache License / Version 2.0, January 2004"*) | FreeBSD-based. **Trademark restricted by Netgate**: the code licence does not authorise you to redistribute under the name |
| **pfSense Plus** | **Proprietary, no public source code** | A different product, not an edition of the previous one. Free on Netgate hardware; on third-party hardware it requires a subscription (§8: price not verified against an official source) |
| **OPNsense** | **BSD 2-Clause** — verified by reading the `LICENSE` of the `opnsense/core` repository raw | FreeBSD-based, maintained by Deciso. **All the code, including the interface and the plugins, under the same licence**; the *Business Edition* is the same code with support and a conservative branch |
| **TrueNAS** | — | **It stopped being a BSD product.** The living line is Linux (25.10 "Goldeye"); **TrueNAS CORE is in sustaining mode**, with no FreeBSD 14 base, last delivery 13.3-U1.2 (Apr 2025) and **no announced end-of-life date** |

**A consequence of criteria, not of nostalgia**: **pfSense CE and OPNsense are not equivalent in
licence**, and the difference matters when there is an audit, a right to fork or resale. **And TrueNAS
is no longer an argument in favour of FreeBSD**: if you choose FreeBSD for storage today, you choose it
and you build it yourself, you do not inherit it from TrueNAS.

## 3. FreeBSD conventions that decide

- **ZFS as root, always**, and **boot environments (`bectl`) as the update mechanism**:
  you update onto a new BE and rolling back is a reboot. It is the main operational reason
  to choose FreeBSD; giving it up is throwing away the advantage. (Pool design belongs to
  `zfs-standards`.)
- **Choose the package branch deliberately**: `quarterly` for servers (bounded changes,
  backported security fixes) and `latest` only where you need fresh versions. **Mixing
  `pkg` with hand-compiled `ports` on the same machine is the number one source of broken
  dependencies**; if you need your own options, set up your own repository (poudriere) and serve
  packages, do not compile in production.
- **Configuration in `/etc/rc.conf` managed with `sysrc`**, versioned and applied by
  automation. **No configuration edited by hand in production without ending up in the
  repository** — the point of contact with `iac-standards`.
- **"Thin" jails** with a common template and a shared read-only filesystem; `vnet`
  jails when each service needs its own network stack. Choose **one** management tool
  (Bastille, AppJail, iocage) and only one: mixing jail managers leaves orphans.
- **`bhyve` is enough for modest virtualisation**, and only that: no live migration
  comparable to a high-end hypervisor, no management ecosystem. If you need a virtualisation
  platform, that decision belongs to `onprem-standards`, not here.
- **`freebsd-update` for binaries on RELEASE.** Running `-CURRENT` in production is vetoed (§7);
  `-STABLE` only with your own build and a written reason.

## 4. Jails versus containers, and `pf` versus `nftables`

> *(Replaces the format's "quality and testing" section, which would be artificial here: there is no
> testing toolchain of its own to set. What decides instead are these two comparisons.)*

**Jails**: full system isolation, very cheap, with native ZFS and network integration. What
you **gain** over a Linux container: maturity, small surface, clear boundaries, and the fact that a
jail is a system, not a packaged process. What you **lose**, and it is a lot: **there are no OCI
images, no registry, no tooling ecosystem, no orchestrator**. A jail is not rebuilt from
a `Containerfile` that somebody else understands, nor deployed from your pipeline without work of your own.

Rule: **jails for long-lived services managed as machines** (storage, networking,
infrastructure services). **Containers for application workloads with a continuous delivery
cycle.** Do not turn jails into a hand-crafted substitute for Kubernetes: you will end up maintaining an
orchestrator of your own that nobody else knows how to operate.

**`pf` versus `nftables`**: `pf` wins on readability —the rule set reads like a
policy and gets reviewed in a code review— and it brings `pfsync`/CARP for stateful synchronised
pairs. `nftables` wins on integration: it is what sits underneath Kubernetes, containers and the
network automation tooling of the Linux world. **Choose the engine by where the rest of
your infrastructure lives, not by elegance of syntax.** The filtering **policy** —zones,
default deny, egress, review— is identical in both cases and lives in
`firewall-policy-standards`.

## 5. Security: what OpenBSD teaches even if you do not deploy it

OpenBSD is **the reference for mitigations**, and its value to the rest of the catalogue is doctrinal:

- **Genuinely secure by default**: minimal install, almost nothing listening, services in a `chroot`
  from the first boot. The transferable lesson: **the correct posture is "nothing exposed except
  what is declared"**, not "harden afterwards".
- **`pledge(2)` and `unveil(2)`**: the program **declares which system calls and which paths it
  needs** and the kernel kills it if it steps outside. It is least privilege applied inside the process, and it is
  the right mental model for writing seccomp profiles, SELinux policies or hardened systemd
  units on Linux. **If a service cannot enumerate the files it needs, the problem
  is the service.**
- **Exploit mitigations by default** (W^X, ASLR, kernel relinked at every boot,
  return protections, `malloc` with abuse detection): they are not options you switch on, they are
  the system. The lesson: **mitigations you have to remember to enable do not get enabled.**
- **`syspatch`/`signify`**: signed, binary patches, applicable without compiling. **A system whose
  security update requires compiling does not get updated.**
- **Honesty about scope**: OpenBSD protects the base system. **The third-party code you
  install on top (`pkg_add`) does not inherit that level of review** and remains your attack
  surface; managing its vulnerabilities belongs to `vulnerability-management-standards`.
- **`doas` instead of `sudo`**: less surface and a configuration that fits in your head.
  Transferable as criteria: the elevation tool is chosen by how small its configuration
  is, not by habit.

## 6. Operability and derivative ecosystem

- **Hardware and drivers are BSD's real operational risk**, not stability. Before
  committing to a platform: check the compatibility list for your specific NIC, HBA and management
  platform, and check whether there is an agent from your backup, monitoring and
  endpoint security vendor. **Many corporate products have no BSD agent**: that alone
  decides it outright.
- **pfSense CE versus OPNsense** as a firewall appliance: same lineage, different licences
  (§2) and a different update cadence. Criteria: **if you need a guarantee of fully open
  source, a right to fork or source auditing, OPNsense**; if you already operate Netgate hardware with
  contracted support, pfSense Plus is coherent **on the assumption that it is proprietary software**. What
  is not defensible is choosing one believing the other is the same thing under a different name.
- **A firewall appliance is still a server**: inventory, patching cycle, a copy of the
  configuration and centralised logging; configuration exported and versioned at the very least.
- **Storage**: FreeBSD + ZFS is still excellent, but **today you build it yourself** (§2). If
  you want an appliance, evaluate the TrueNAS Linux line or your own ZFS design on Linux — the
  platform decision is not sentimental.
- **Updates as a calendar, not as a reaction**: FreeBSD, a window per minor release (they expire
  in months, §2); OpenBSD, twice a year on a fixed date. If it is not on the calendar, it does not happen.

## 7. When NOT to choose BSD, and prohibitions

**Do not choose BSD when:**

- **The application ecosystem is not there**: data platforms, proprietary agents,
  GPU drivers and commercial suites that only ship for Linux. Reason number one, and it is
  not solved by willpower. **Or the workload is containers**: if the natural destination is
  OCI/Kubernetes, BSD leaves you off the beaten path (§4).
- **You need commercial support with an SLA on the operating system.** It exists (Deciso, Netgate,
  specialist vendors) but **it is not comparable in coverage to that of an enterprise Linux
  distribution**, and that honest comparison is part of the decision.
- **There are no people.** Hiring and replacing whoever operates BSD is measurably worse than on Linux: **a
  system only one person knows how to operate is a continuity risk**.
- **You already operate a homogeneous Linux fleet** and this adds a second operating system with its patching,
  inventory, agents and knowledge, for a marginal improvement.

**Prohibitions:**

- ❌ **FORBIDDEN** to use `-CURRENT` in production, or a FreeBSD minor release already expired — and they
  expire **in months**, not years (§2).
- ❌ Running OpenBSD without committing to the six-monthly update. **Without that cadence, OpenBSD is
  less secure than a maintained Linux**, not more.
- ❌ Mixing binary packages and hand-compiled ports on the same machine, or compiling ports in
  production.
- ❌ Updating FreeBSD without a new boot environment and a tested rollback.
- ❌ Treating **pfSense CE and pfSense Plus** as the same thing: one is Apache-2.0, **the other is
  proprietary with no source**. Nor citing a derivative's licence without having read its `LICENSE`
  raw.
- ❌ Redistributing or rebranding pfSense relying only on the code licence: the **trademark** is
  restricted separately.
- ❌ Presenting TrueNAS as an argument that "FreeBSD has a storage ecosystem": the living
  line is Linux (§2).
- ❌ Choosing NetBSD for an ordinary x86/ARM platform without a written portability reason.
- ❌ Reinventing an orchestrator on top of jails for workloads that called for containers (§4).
- ❌ Deploying BSD without having first verified drivers, backup agent and endpoint
  security agent (§6).
- ❌ Leaving the firewall appliance out of the inventory, the patching cycle or centralised logging.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web —and with a **literal quote**, never with an
automated summary:

1. **FreeBSD**: official security page, table of supported branches and dates. Those in §2 are
   taken literally from there as of Aug 2026; **the date of the minor release you use expires in
   months**.
2. **OpenBSD**: current release and its errata page; confirm you are still within the **last
   two**.
3. **NetBSD**: current branch after 11.0 and the real status of 10.x.
4. **pfSense and OPNsense**: **read the repository's `LICENSE` raw** before asserting anything — not
   the label shown on the GitHub front page, and not the releases feed, which is not the source of
   truth if the project moves. Verified that way as of Aug 2026: **pfSense CE = Apache-2.0**,
   **OPNsense = BSD 2-Clause**. **Declared gap: the prices** (pfSense Plus TAC subscription,
   OPNsense *Business Edition*) **were not verified against the official pricing page** — do not
   quote them from here. **Declared gap**: neither was the exact scope of Netgate's trademark
   policy verified against an official source.
5. **TrueNAS**: whether there are still CORE deliveries and whether iXsystems has finally announced an
   end-of-life date. As of Aug 2026 **there was none**: sustaining with no date, which for planning
   purposes is treated as an unannounced end of life.
6. **Hardware compatibility** for your specific model and availability of third-party agents
   (§6): that is what rules the platform out, more than any design consideration.
7. **CVEs** of the base system and **of third-party packages separately**: they are two different
   advisory streams with different calendars.

If the web contradicts this document, **the web wins** — flag the discrepancy.
