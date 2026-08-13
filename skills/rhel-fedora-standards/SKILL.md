---
name: rhel-fedora-standards
description: Red Hat family specifics - RHEL, CentOS Stream, Fedora, AlmaLinux, Rocky. Use when running dnf5 or dnf5daemon, dnf versionlock, dnf needs-restarting, dnf-automatic or dnf system-upgrade, editing .repo files in /etc/yum.repos.d, enabling EPEL, COPR or RPM Fusion, writing an RPM .spec with rpmbuild or mock, rpm-ostree, bootc upgrade/switch/rollback and image mode for RHEL, bootc-image-builder, Fedora Atomic or Silverblue, subscription-manager, Red Hat Insights or Satellite/Foreman, leapp preupgrade for a major in-place upgrade, grubby and kdump, tuned profiles, cockpit, authselect, AppStream and modularity, or choosing between RHEL, CentOS Stream, AlmaLinux and Rocky lifecycles and EUS/ELC/ELS entitlements.
---

# Red Hat family standards (RHEL, CentOS Stream, Fedora, AlmaLinux, Rocky)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **what is particular to the Red Hat family** and does not hold the same on Debian/Ubuntu: choosing
a distribution within the family and its lifecycles, `dnf5` and the RPM model, repositories and
their risks, building your own packages, the **image** paradigm (`rpm-ostree`, `bootc`,
image mode), subscriptions and entitlements, major version upgrades (`leapp`,
`dnf system-upgrade`), and the pieces the family ships by default (SELinux, firewalld, `tuned`,
`cockpit`, `podman`, `grubby`, `kdump`, `authselect`).

Triggers: `dnf5`, `dnf5daemon`, `/etc/dnf/dnf.conf`, `/etc/yum.repos.d/*.repo`, `dnf versionlock`,
`dnf needs-restarting`, `dnf-automatic`, `dnf system-upgrade`, `dnf offline`, `dnf module`,
`rpm -q`, `.spec`, `rpmbuild`, `mock`, `rpmlint`, `%post`/`%files`, `epel-release`, `copr`,
`rpmfusion`, `rpm-ostree`, `ostree`, `bootc`, `bootc upgrade`, `bootc switch`, `bootc rollback`,
`bootc-image-builder`, `Containerfile` with `rhel-bootc`, Silverblue/Atomic,
`subscription-manager`, `rhc`, `insights-client`, Satellite/Foreman, `leapp preupgrade`,
`leapp upgrade`, `grubby`, `kdump`/`kexec`, `tuned-adm`, `cockpit`, `authselect`, `AppStream`,
"Rocky or Alma?", "is CentOS Stream good enough for production?", "the system became unrecoverable after adding
a repo".

**Guiding principle**: **in this family, most unrecoverable systems were broken by
a repository, not by a bug.** Mixing third-party repos that replace base packages is cause
number one of a host that can no longer be updated or cleanly reinstalled, and `--nobest` /
`--skip-broken` is the gesture that turns a visible conflict into silent corruption. The
second principle: **the lifecycle is an architecture decision, not an installation
detail** — RHEL, Stream, Alma and Rocky are not interchangeable even if the packages look alike.

**Boundary with `linux-administration-standards`**: that skill is **distribution-agnostic** and
rules over everything that holds the same on Debian — systemd and its units, journald, cgroups v2,
`nsswitch`, mounts, host network management, time, and the **layered diagnostic method**. This
skill **does not repeat it**: it develops it where the Red Hat family differs (`dnf` instead of `apt`,
`grubby` instead of `update-grub`, `firewalld` instead of `ufw`, SELinux instead of AppArmor, `tuned`,
`kdump`). If the question starts with "how do I write this unit?", it is from there; if it starts with
"which repo?" or "which RHEL version?", it is from here.

**Not applicable**: see `linux-administration-standards` (OS-agnostic day-to-day, systemd, journald,
resources, host diagnostics), `onprem-standards` (platform umbrella: hardware, OOB/BMC plane,
hypervisor, inventory and fleet cadence; its §1.3 invariants rule),
`selinux-standards` (**all of MAC**: `enforcing` is a non-negotiable of the family here, but AVC
diagnosis, `semanage`, `restorecon`, booleans, `container-selinux`, `udica` and custom
policy are theirs), `linux-hardening-standards` (CIS/STIG/ANSSI/**CCN-STIC** baseline, OpenSCAP with
SSG, `sysctl.d`, `sshd_config`, auditd, `sudoers`, `pam_faillock`, unit sandboxing, and
`dnf-automatic` **as a security control** — here `dnf-automatic` only as an update
mechanism and its reboot policy), `networking-standards` (**the design** of the network and of the
firewall policy between zones; **here only the `firewalld` mechanism**: which zone, how an
interface is assigned and why it is not mixed with raw `nftables`),
`vulnerability-management-standards` (CVE triage with CVSS/EPSS/KEV, SLA, VEX and EOL
tracking — **they prioritise the patch; here where it comes from, how it is applied and which lifecycle
delivers it**), `iac-standards` (Ansible as a tool and its CI: what is repeatable is automated there),
`bash-linux-scripting-standards` (the scripts that run anything from here),
`kubernetes-standards` (OpenShift/OKD and the cluster; **here the node and its image mode**),
`container-runtime-security-standards` (container runtime security),
`observability-standards`, `identity-access-management-standards` (IdP and federation;
`subscription-manager` and Red Hat entitlements are from here),
`windows-server-ad-standards` (the forest and the domain; **host integration with AD —
`realmd`, `sssd`, `authselect`, `adcli`— is from `linux-administration-standards` as system
configuration**, and this skill only contributes that in this family the PAM stack is touched **with
`authselect`**, never by editing `/etc/pam.d` by hand, because the SSG/CIS content assumes it),
`grc-compliance-standards`, `homelab-standards` (personal lab: the boundary is rigour),
`bcdr-standards`, `incident-response-forensics-standards`, `perl-standards` (the system's
Perl interpreter and its RPM packages are from here — **FORBIDDEN to touch them or install modules on top of
them: it breaks the OS's own tooling**—; **application** Perl, with its `perlbrew`/`plenv`,
`cpanfile` and its code criteria, is theirs).

Additionally:
`podman-systemd-containers-standards` (Podman, Quadlet, rootless, `podman auto-update`
— **precise boundary**: here only that **Podman is the family default and Docker the exception to
justify**, and bootc's *logically bound images*; the rest is theirs),
`linux-storage-standards` (LVM, Stratis, XFS and their tuning; here only that XFS is the
default filesystem of RHEL and **cannot be shrunk**), `backup-recovery-standards`,
`ha-clustering-standards` (RHEL HA Add-on, Pacemaker/Corosync, `pcs`),
`libvirt-kvm-standards`, `proxmox-ve-standards`, `zfs-standards` (and incidentally the reason
why ZFS is not a first-choice option in this family — out-of-tree DKMS against a kernel that
updates itself), `dns-standards`, `firewall-policy-standards`, `vpn-standards`,
`network-troubleshooting-standards`.

## 2. Default decisions

> Verify the latest version and **every** EOL date on the web before pinning it in a real project
> (§8). The data is from **August 2026** and lifecycle dates change by commercial decision,
> not by technical calendar.

### 2.1 Which distribution of the family

| Case | Choice | Reason / nuance |
|---|---|---|
| Production with contractual support, ISV certifications or an audit requirement | **RHEL 10** (latest minor **10.2**, GA of 10.0 on 2025-05-20) | It is the only one with an SLA, hardware/ISV certification, Insights and an extended support path. RHEL 9 (latest **9.8**) is still fully alive and is the conservative choice if your stack is not certified on 10 yet |
| Production without a contract, I want "free RHEL" and **application compatibility** | **AlmaLinux 10** (10.2; GA 2025-05-27) | Goal is **ABI-compatible**, not a binary clone: it builds from CentOS Stream sources and **reserves the right to patch bugs Red Hat has not yet fixed**. Concrete and decisive advantage on old hardware: **it is the only one publishing a build for `x86-64-v2`** (Nehalem+), whereas RHEL 10 and Rocky 10 require **`x86-64-v3`** (Haswell+, ~2013) |
| Production without a contract and I need it to behave **exactly** like RHEL | **Rocky Linux 10** (10.2; GA 2025-06-11) | Declared goal is **bug-for-bug**: if it is a bug in RHEL, it is the same bug in Rocky. It is what you want if you validate against RHEL behaviour. Downside: `x86-64-v3` mandatory, and there is third-party software that has dropped support for it (cPanel ≥134) |
| Development, lab, workstation, upstream | **Fedora 44** (2026-04-28) | It is the real upstream of the family: what is normal here will be RHEL years from now. **~13-month cycle**: Fedora 43 dies on 2026-12-09 and Fedora 42 is already EOL (2026-05-27). **It is not a long-life server distro** and putting it in production means accepting a major version jump every six months |
| I want to see what the next RHEL minor will bring / develop against it | **CentOS Stream 10** (2024-12-12, supported until 2030-05-31; Stream 9 until 2027-05-31) | **It is upstream of RHEL, not a derivative**: it runs *ahead* of the published minor. It is good for development, CI and contribution. **Using it "as if it were RHEL"** means accepting continuous change with no stable minors, no ISV certification and no EUS/ELC — a legitimate decision only if it is conscious and written down |
| I need real RHEL, free, on a few hosts | **Red Hat Developer Subscription for Individuals**: up to **16 systems**, **annual** renewal | Verified Aug 2026: Red Hat explicitly allows small-scale production use on those 16. There is also **RHEL for Business Developers** (Jul 2025) up to **25 instances, dev/test only**. **Real risk to document**: there are *compliance* readings that treat it as a convenience and not as a production entitlement — if the company audits licensing, put it in writing first |

**RHEL lifecycle — the current model** (verified Aug 2026 on `access.redhat.com`):
- **Full Support** (~5 years: security and bug errata, hardware enablement, new minors) →
  **Maintenance Support** (~5 years: errata only, no new functionality or hardware, **no new
  minors**) → **Extended Life Phase** (access to already published content; **no patches**).
- **ELC (Extended Life Cycle)** **replaces EUS, Enhanced EUS and E4S from RHEL 9 onwards**: 6 years from
  the GA of certain **even minors** (9.2, 9.4, 9.6, 9.8, 9.10 / 10.2, 10.4, 10.6, 10.8,
  10.10). The **Long-Life (LL)** add-ons renew annually on top of that. **Practical
  consequence**: if you need to stay on a minor, **stay on an even one**, or you will have no errata
  stream.
- **RHEL Extended Life Cycle, Premium** (from 2026-04-02): up to **14 years** of lifecycle, with
  coverage of Critical, Important and Moderate CVEs with **CVSS ≥ 7.0**.
- Reference dates (verified on `endoflife.date`, **cross-check them with Red Hat**): RHEL 8 ends
  2029-05-31 (ext. 2033), RHEL 9 ends 2032-05-31 (ext. 2036), RHEL 10 ends 2035-05-31 (ext. 2039).

### 2.2 Tools and mechanisms

| Area | Default | Reason / nuance |
|---|---|---|
| Package manager | **`dnf5`** (upstream 5.4.2.1, May 2026). It is **the default since Fedora 41**; `/usr/bin/dnf` is a symlink to `dnf5` and DNF4 is no longer in the base set | Written in C++ with `libdnf5`: faster, no mandatory Python dependency. **What really changes** (§3.2): rewritten Python API, different plugins, `--downloaddir` → `--destdir`, and **dnf4 and dnf5 transactions do not see each other** |
| Automatic updates | **`dnf-automatic`** with `apply` in low tiers and `download-only` + a window in production | **It does not know how to reboot**: there is no native reboot support. The reboot policy is built separately with `dnf needs-restarting -r` in an `ExecStartPost=` of the override, with a time window. Using `dnf-automatic` **as a measurable security control** belongs to `linux-hardening-standards` |
| Pinning versions | **`dnf versionlock`** for what cannot move (kernel of a certified driver, an ISV agent), **with an owner and an expiry date** | A `versionlock` without a date is a CVE with an indefinite expiry date. It is audited every quarter |
| Third-party repositories | **None by default.** Whatever gets in, gets in with **priority**, bounded `includepkgs`/`excludepkgs`, **mandatory GPG signature** (`gpgcheck=1`, `repo_gpgcheck=1` where it exists) and written justification | See §5. An unbounded third-party repo that replaces base packages is the direct route to the unrecoverable system |
| Containers | **Podman** (rootless by default) + **Quadlet** under systemd | It is the family default: no daemon, no root, integrated with systemd and SELinux. Docker is the **exception to justify** (a hard dependency on a tool that only speaks to the Docker socket). The detail belongs to `podman-systemd-containers-standards` |
| MAC | **SELinux `enforcing`, always. Non-negotiable** | See §5 and `selinux-standards`. Disabling it is prohibition number one of this family |
| Host firewall | **`firewalld`** with zones, not raw `nftables` | It is what the rest of the family's ecosystem assumes (`podman`, Cockpit, certified Ansible roles). Mixing direct `nft` rules with firewalld produces rulesets that get lost on the next `reload`. The **design** of the policy belongs to `networking-standards` |
| Performance | **`tuned`** with an explicit per-role profile (`throughput-performance`, `virtual-guest`, `latency-performance`…) chosen and **versioned**, not the one the installer left | `tuned-adm active` in the inventory. A default profile on the wrong role is the silent cause of odd latencies. Changing `sysctl` by hand underneath `tuned` produces config that reverts itself |
| Boot loader | **`grubby`** for kernel parameters and the default entry | It is the correct interface in this family (`grubby --update-kernel=ALL --args=...`), and it works the same on BIOS/UEFI and on ostree systems. Editing `/etc/default/grub` + regenerating is the long, error-prone road |
| Kernel dump | **`kdump` enabled and tested** on physical servers and VMs that matter | A kernel panic without a `vmcore` is an incident with no possible root cause. Reserve memory (`crashkernel=`) and **test the dump** (`echo c > /proc/sysrq-trigger` during a window): an untested kdump does not exist |
| Management console | **`cockpit`** only where it adds value and **never exposed to a user network or to the Internet** | Useful for standalone hosts, quick diagnostics and people who do not live in the terminal. **It does not replace automation**: what is done through Cockpit is an uncaptured manual change (*snowflake*) unless it is replicated in code |
| PAM and NSS stack | **`authselect`** exclusively | Verified: the SSG/CIS content for PAM rules **assumes authselect and does not apply if the stack was edited by other means**. On RHEL 10, additionally, the kickstart commands `auth`/`authconfig` were **removed** |
| Kernel | **The distro's, and only the distro's** | **In this family there is no official `kernel-lt` or `kernel-ml`** (that is ELRepo, a third party). Legitimate variants: `kernel`, `kernel-rt` (real time, with its add-on), `kernel-debug` (**careful**: it inflates the "reboot required" detection of `tracer`/Satellite), `kernel-64k` (64K pages on aarch64). A third-party kernel breaks support, SELinux, the kABI of certified drivers and Secure Boot |

## 3. Structure and conventions

### 3.1 RPM, AppStream and modularity

- **AppStream vs. BaseOS**: BaseOS is the OS with the major's lifecycle; AppStream are the
  userspace components, **each with its own cycle, which can be shorter than the distro's**.
  That is the detail people forget: having RHEL 10 supported until 2035 does not mean having
  that language or that database supported until 2035. **EOL is inventoried per component**,
  not per OS (invariant of `onprem-standards`: nothing without an end-of-life date).
- **Modularity: it is over.** Verified Aug 2026: on **RHEL 10 modularity is deprecated, no modular
  content is shipped** and `dnf module` emits a deprecation warning; Application Streams
  are installed as normal RPMs. The `module` kickstart command is deprecated and Anaconda deprecated its
  modularity support. **Criteria**: do not design anything new on top of modules; whatever is left from RHEL 8/9 with
  `dnf module enable` is debt to retire in the migration, and it is one of the things that produces the most noise in
  `leapp`.
- **Always the full package name in automation**: `name-version-release.arch`. A
  playbook that installs plain `nginx` installs different things on 9 and on 10.
- **`dnf history`** is the rollback tool (`dnf history undo <id>`), and it is the reason
  why transactions matter: they are planned as a single transaction, not as ten loose `install`
  commands. Careful (§3.2): the dnf4 history and the dnf5 history **are not the same**.

### 3.2 `dnf5`: what really changes with respect to dnf4

Verified Aug 2026 (dnf5 5.4.2.1). This is what breaks existing scripts:

- **The Python API was rewritten entirely**: you have to port to `python3-libdnf5`; **it is not source-level
  compatible** with DNF4's `dnf` module. Any automation that imports `dnf` in
  Python breaks.
- **Plugins**: they are not compatible (different API, the old ones were Python). The essentials live in
  `dnf5-plugins`. On a default Fedora 44 installation, `builddep`, `changelog`,
  `config-manager`, `copr`, `needs_restarting`, `repoclosure`, `repomanage` and `reposync` load.
  **Deliberately dropped**: `generate_completion_cache` and `migrate`. Verify the specific plugin
  you use **before** migrating, not after.
- **Options that change**: `--downloaddir` (dnf4) → **`--destdir`** (dnf5); dnf5 **rejects**
  `--downloaddir`. `dnf offline-upgrade` **no longer exists** as a subcommand → `dnf upgrade --offline`
  followed by `dnf offline reboot`.
- **Transaction histories are not shared**: packages installed as a dependency by one
  appear as user-installed to the other, which prevents their auto-removal. If a
  host carries both, you clean up the state, you do not coexist.
- **Offline transactions**: `dnf upgrade --offline` / `dnf5 system-upgrade download` leave the
  transaction stored (`/usr/lib/sysimage/libdnf5/offline`) and it is applied with `dnf5 offline
  reboot` in a minimal environment. Subcommands: `status`, `log`, `clean`, `--poweroff`. **It is the
  correct mode** for large updates: less interference with running processes.
- **`dnf5daemon`** exposes the functionality over D-Bus for graphical clients and Cockpit. Verified:
  **on Fedora 44 the PackageKit backend moved to DNF5** — concrete operational consequence: if
  GNOME Software prepares an offline transaction and you left another repo state via CLI, the
  transaction fails. **One transaction source per host**.

### 3.3 Repositories: the minimal, safe model

- Each `.repo` in `/etc/yum.repos.d/` declares: `enabled`, `gpgcheck=1`, `gpgkey` (key
  **verified by fingerprint**, not downloaded blindly), `priority` if there is overlap risk, and
  `includepkgs=`/`excludepkgs=` to **bound what it can replace**. The whole set is
  versioned in the IaC repo (`iac-standards`).
- **EPEL**: the de facto community repo. **Real and concrete risk**: it contains packages that can
  replace or conflict with AppStream, and **it has no stability or lifecycle commitment**;
  a package can disappear or jump a major version. **It is enabled in a bounded way**
  (a one-off `--enablerepo=epel`, or `includepkgs`), never "open and permanent" on a server that
  matters.
  - **EPEL 10 changed its model**: there are **per-minor repos** of RHEL 10 (`epel10.N`), with `epel10`
    acting as the leading branch (rawhide-style, aligned with CentOS Stream 10). Packages are
    carried from one minor to the next. **There is no automatic carry-over from `epel9`**: the
    package sets of EPEL 9 and EPEL 10 overlap but neither is a subset of the other —
    **verify that your packages exist in EPEL 10 before planning the migration**, it is a
    common and surprising blocker.
- **COPR**: personal build repos. It is **an individual's build**, with no review or guarantee.
  It is fine for testing and for the lab; in production it demands an owner, a version pin, an exit plan and
  written risk acceptance. Never for base system packages.
- **RPM Fusion**: multimedia and non-free codecs. It is **desktop**, not server. Verified
  Aug 2026: supported on Fedora 44; and **VLC and LAME now ship in Fedora 44's main
  repos**, so it is needed for fewer things than before.
- **The rule that avoids 90 % of the disasters**: a third-party repo **never** replaces packages from
  BaseOS/AppStream. If it does, either it is bounded with `excludepkgs` in the base repo, or it does not get in. And if it already
  got in: `dnf distro-sync` with the repo disabled, **before** it piles up.

### 3.4 Building your own RPM

**When yes**: internal software that must be installed in the system path, integrate with systemd,
declare real dependencies, have the correct SELinux context and be uninstallable and auditable
(`rpm -qa`, `rpm -V`). A `.tar.gz` unpacked into `/opt` by a script is none of those
things.

**When no**: if the application can live in a **container**, it goes in a container. Packaging in
RPM an application with its own dependency ecosystem (Node, Python with wheels, JVM with a
*fat jar*) is recurring work that never pays for itself.

Minimum conventions:
- `.spec` versioned in the project's repo, with a reproducible `Source0`, a real `%changelog`,
  declared dependencies (`Requires`, `BuildRequires`) and **no heavy logic in `%post`**.
- **`mock` for every build destined for production**: clean chroot, against the exact set
  of repos of the target. Building on the developer's laptop introduces
  implicit `BuildRequires` that do not exist on the target.
- `rpmlint` in CI as a gate; GPG signature of the package and of the internal repo (key custody is
  set by `cryptography-pki-standards`).
- Running all of this in a pipeline belongs to `cicd-standards`; the internal artifact repo
  as well.

### 3.5 Image mode: `rpm-ostree` and `bootc`

**The paradigm shift**: the operating system stops being the accumulated result of N
package transactions and becomes a **versioned, signed and reproducible container
image**, deployed A/B with rollback. It is built with a `Containerfile`, it is
published to a registry and it is deployed with `bootc`.

Verified Aug 2026:
- **`bootc` replaces `rpm-ostree`**. It is explicit: on systems in image mode **it is not
  supported to use `rpm-ostree` to install content or make changes**, and upstream development
  of `rpm-ostree` has shifted to bootc/dnf — it will keep receiving important fixes
  (especially security ones), but **new client functionality is unlikely**. Upstream of
  bootc: **v1.16.6** (2026-07-28, via `api.github.com`).
- **RHEL image mode** is documented as a product feature on RHEL 9 and 10. **From RHEL
  10.0 image mode replaces RHEL image builder for edge images** (bootable containers
  are mandatory there), and the base image is `registry.redhat.io/rhel10/rhel-bootc`.
  **Careful with the GA status per piece**: creating and deploying an ISO with `bootc-image-builder`
  is **Technology Preview**, and it depends on the `%ostreecontainer` kickstart command, also TP.
  **Verify the exact status for your version before committing to a deployment** (§8).
- **Operation**: `bootc upgrade` (updates the image being tracked) and `bootc switch <image>`
  (changes the tracked image) have **the same effect** except for which image is tracked; both
  preserve `/etc` and `/var` (host SSH keys, home). Changes are **staged** and are not
  applied until reboot unless `--apply`. Verified extras: `--download-only`,
  `upgrade --from-downloaded`, and `--apply --soft-reboot=required|auto`. **Pinning by digest
  turns `bootc upgrade` into a no-op** — with a pin, you update with `switch`.
- **Logically bound images**: symlinks in `/usr/lib/bootc/bound-images.d` pointing to
  Quadlet `.image`/`.container` files; bootc downloads them on `upgrade`/`switch`, keeps those of
  the rollback installation and garbage-collects. It allows updating the app without rebuilding the OS
  image and vice versa. Verified limitation: they use the global pull secret (`/etc/ostree/auth.json`);
  **per-image `PullSecret` is not supported yet**.
- **Verified migration traps that bite**:
  - **`/opt` is a link to `/var/opt`** on ostree/bootc systems. Software that installs into `/opt`
    needs to install under `/usr` and create the link with `/usr/lib/tmpfiles.d`.
  - ***Identity drift*** when converting an existing RHEL for Edge system to image mode: the UID/GIDs
    of the container may not match those of the original system, breaking SSH access and file
    ownership in `/var`. Systems in image mode use `altfiles`, with users in
    `/usr/lib/passwd` and groups in `/usr/lib/group`.
  - RHEL for Edge systems **9.6 or higher** deployed with the *simplified installer* can be
    converted to image mode **without reinstalling**.
- **When it is worth it compared to package mode**: a **homogeneous and numerous** estate, edge, cluster
  nodes, any case where reproducibility and atomic rollback are worth more than
  flexibility. **When not**: unique, heavily customised hosts, workloads that require changing the OS
  live, or a team that does not already have an image pipeline with registry, signing and
  promotion. **Image mode does not reduce work: it moves it from the night of the incident to the build
  pipeline.** If that pipeline does not exist, you build it first.
- **Fedora Atomic / Silverblue / Kinoite / CoreOS**: the same paradigm upstream, and the
  right place to learn it before taking it to RHEL. Verified: **OpenShift is transitioning to bootc
  over the course of 2026** (RHCOS today uses rpm-ostree native containers, the technology that inspired
  bootc).

### 3.6 Major version upgrades

**They are not improvised. They are rehearsed, on a clone of the host, with a tested revert and a window.** It is the
operation with the highest probability of leaving a system in an unsupported state.

- **RHEL: `leapp`.** Verified: **only between consecutive majors** (8→9, 9→10). RHEL 8→10 are
  **two** chained upgrades. Supported paths are published **per specific minor** (table 1.1
  of the official guide), and they are updated with each minor: **consult it, do not deduce it**. Flow:
  `leapp preupgrade` (inhibitors and report) → resolve **everything** → `leapp upgrade` → reboot.
  Verified details that matter:
  - **`leapp` leaves SELinux in `permissive` during the process; restore `enforcing` by hand
    afterwards** (and plan the relabelling — `selinux-standards`).
  - Without RHSM or with RHUI: `--no-rhsm`. With extended entitlements: `--channel eus|aus` — **with the
    arrival of ELC, confirm the current channel name before using it** (§8).
  - PAYG with RHUI: **only the latest available path** is supported.
  - With SAP HANA, a specific guide; do not extrapolate.
  - **Third-party repos are the number one source of inhibitors**: EPEL, COPR and ISV drivers are
    resolved **beforehand**, not during.
- **Fedora: `dnf system-upgrade`**, one version at a time.
  `dnf upgrade --refresh` → `dnf5 system-upgrade download --releasever=NN` →
  `dnf5 system-upgrade reboot`, and then `dnf5 offline status`/`log`. `dnf-plugin-system-upgrade` is
  **no longer needed** (that was the DNF4 era). Verify beforehand which third-party repos still have no
  build for the target release: **it is the usual cause of an upgrade that does not resolve**.
- **Image mode**: the major upgrade stops being an in-place operation and becomes
  a `bootc switch` to an image based on the new major, with trivial rollback. It is the strongest
  operational argument in favour of image mode.
- **An alternative always on the table: reinstall.** If the host is rebuildable from code
  (invariant of `onprem-standards`), a clean reinstall is usually faster, cheaper and more
  predictable than an in-place. The in-place is justified when there is local state that cannot be
  rebuilt — and then the real question is why that state is not backed up.

### 3.7 Subscriptions, entitlements and fleet management

- **`subscription-manager`** (or `rhc` to connect the host) is the gateway to the repos. A RHEL host
  that is not registered **does not receive security patches**: monitoring the registration status and the
  entitlements is an operational requirement, not an administrative task.
- **Satellite / Foreman** (high level): mirrored repositories, **content views and lifecycle
  environments** — the promotion of an exact set of packages from dev→prod, which is what makes
  patching a fleet reproducible. It is the correct answer to "how do I guarantee that all
  hosts received the same set of packages". Its **Tracer** function decides which services
  to restart after an update (same idea as `dnf needs-restarting`; same known trap:
  `kernel-debug` installed leaves the host marked as "reboot required" forever).
- **Insights**: analysis and recommendations from telemetry sent to Red Hat. **A conscious
  decision**: it sends host data outside. It is enabled if the value (CVE detection, configuration
  drift, known risks) is worth it, with a privacy and data policy review
  (`privacy-engineering-standards`/`grc-compliance-standards`), not by default.
- **Entitlements and lifecycle**: if your plan is "we stay on this minor", it has to be an **even** minor
  (ELC) and with the add-on contracted. A host pinned to a minor without an ELC entitlement is without errata:
  that is a finding, not a strategy.

## 4. Quality: what is validated before touching anything

> The generic gates (validators before reloading, smoke test, rescue session) belong to
> `linux-administration-standards` §4 and **also apply here**. What follows is what is specific
> to the family.

1. **Clean `dnf check` and `rpm -Va`** as a baseline before any large operation. A
   system with broken dependencies is not updated: it is fixed first.
2. **Rehearse the transaction without applying it**: `dnf upgrade --assumeno` / `dnf --setopt=tsflags=test` and
   **read the plan**. If the plan downgrades, removes or replaces base packages, you stop. **A plan
   that only passes with `--nobest` or `--skip-broken` is a plan that is not executed** (§7).
3. **`leapp preupgrade` with the report resolved 100 %** before `leapp upgrade`. High-severity
   warnings are not "accepted": they are resolved or the upgrade is cancelled.
4. **Rehearsal on a clone**: any major upgrade, kernel change or mode change (package→image)
   is tested first on a copy of the real host, not on a "similar" host.
5. **`rpmlint` + `mock` in CI** for every in-house RPM; **verified signature** before publishing.
6. **Image mode**: the image is built in CI, **signed** and verified before deploying; it is
   deployed to a canary first; the **rollback is tested** (`bootc rollback` + reboot) before
   considering the deployment complete. Scanning the image (`oscap-im` for bootc, per
   `linux-hardening-standards`) as a gate.
7. **Post-patch**: `dnf needs-restarting -r` (and `-s` for services) decides the reboot; the
   result is recorded. Known and verified: the tool has documented false positives and false
   negatives — **when in doubt after a kernel or glibc change, you reboot**.
8. **Post-upgrade of RHEL**: verify **`getenforce` → `Enforcing`** (leapp left it in
   `permissive`), repo status, `dnf check`, critical services and the full boot with an
   additional reboot.

## 5. Security specific to the family

- **SELinux `enforcing`. Always. On every host.** It is this family's differential security
  advantage and disabling it annuls it entirely. A verified nuance you must know:
  `SELINUX=disabled` in `/etc/selinux/config` is **deprecated since RHEL 8 and the kernel support
  was removed in RHEL 9.0** — the system boots with SELinux enabled **and with no policy**, which is
  the worst possible state (neither protection nor clarity). To debug: `permissive` **with an end
  date**. Everything else, in `selinux-standards`.
- **The package supply chain**: `gpgcheck=1` with no exceptions, GPG keys verified by
  **fingerprint** against the official source, and `repo_gpgcheck=1` where the repo supports it. A
  `gpgcheck=0` in a `.repo` is an open door to code execution as root.
- **Third-party repos as attack surface, not just a stability issue**: COPR is one person's
  build; EPEL has community review but no commitment; an unofficial mirror is an
  attacker with root on your fleet. They are pinned, bounded and audited.
- **Image mode and signing**: if you adopt bootc, the OS image is a first-class supply
  chain artifact — **signing (cosign/Sigstore), provenance verification and pinning by
  digest** are mandatory, just as for any container image
  (`kubernetes-standards`/`cicd-standards`). A `bootc switch` to a mutable tag of a registry with no
  verification is a remote root compromise by design.
- **Insights and telemetry**: data that leaves the perimeter. A documented decision, not a default.
- **Firewalld and zones**: the default zone of a new interface decides its exposure. It is assigned
  explicitly; `public` "because that is how it came" on a management interface is a finding. The design,
  in `networking-standards`.
- **Cockpit**: it is an administration console with privileges over HTTPS. Only reachable from
  the management network, behind a bastion/VPN, with strong authentication. Never on the Internet.
- **CVEs of this family's tooling**: `sudo` **CVE-2025-32463** (local escalation to root via
  `chroot`) affects the whole family and `sudo` runs on every managed host: priority
  patching, not a monthly window. Formal triage, in `vulnerability-management-standards`.

## 6. Operability

- **Tested `kdump`** and `vmcore` with a destination that has space, retention and monitoring. A panic without
  a dump is a root cause that will never be found.
- **`tuned-adm active` in the inventory** of every host, alongside the role. A wrong profile
  shows up as inexplicable latency months later.
- **Subscription and repo status monitored**: an unregistered host, a disabled repo or an
  expired `versionlock` are alerts, not audit discoveries.
- **`dnf history` and the transaction log forwarded** to the aggregator: "what changed on this host and
  when" must be answerable without logging into the host (`observability-standards`).
- **A "reboot pending" metric** per host, with age. An estate with patches applied and not
  rebooted is an unpatched estate (§4.7).
- **XFS is the default filesystem of RHEL and cannot be shrunk**: sizing an LV with
  XFS is a one-way decision. Storage design belongs to `linux-storage-standards`.
- **RHEL 10 removed Xorg** (Xwayland remains; the X11 protocol still works for most
  clients) and **Motif**. If something in your stack depends on a real X server, it is a migration
  blocker that must be detected in the `preupgrade`, not in production.

## 7. Long-term sustainability and prohibitions

**Cadence**
- Security errata: continuous/automatic in low tiers, weekly and orchestrated in production, with
  a reboot policy.
- RHEL minors: they are adopted within the support window of the previous minor; **if you pin,
  pin to an even minor with an ELC entitlement**.
- Fedora: **every version, without skipping**, and with the jump planned — the cycle is ~13 months and
  EOL versions receive nothing. Fedora on a server is a six-monthly upgrade obligation
  accepted in writing.
- Third-party repos, `versionlock` and exceptions: **quarterly audit with an owner and a date**.
- Major: planned **12 months** in advance, with a rehearsal, and considering "reinstall" as a
  legitimate alternative to the in-place.

**FORBIDDEN**
- ❌ **Disabling SELinux** (or leaving it in `permissive` with no end date) to make something work.
- ❌ **Mixing incompatible repositories**: EPEL/COPR/RPM Fusion/ELRepo/third-party mirrors
  replacing BaseOS or AppStream packages. Repos with no `priority`, unbounded and enabled
  permanently on a server.
- ❌ **`--nobest`, `--skip-broken` or `--allowerasing` as a habit.** They are one-off diagnostic
  tools; using them so "the update goes through" is how an unrecoverable
  system is manufactured.
- ❌ `gpgcheck=0`, or importing GPG keys without verifying the fingerprint against the official source.
- ❌ Jumping a major version on RHEL **without `leapp`**, or running `leapp upgrade` with unresolved
  `preupgrade` inhibitors, or chaining 8→10 in a single jump.
- ❌ Leaving SELinux in `permissive` after a `leapp` (it leaves it that way: it is restored and verified).
- ❌ Upgrading Fedora skipping versions, or keeping an EOL Fedora in production.
- ❌ **Using CentOS Stream as if it were RHEL** without understanding that it runs ahead, has no stable
  minors, no EUS/ELC, and no ISV certification — and without writing it down as a decision.
- ❌ Installing third-party kernels (ELRepo's `kernel-lt`/`kernel-ml`) or out-of-tree modules without
  accepting in writing the loss of support, of certified kABI and of Secure Boot.
- ❌ Using `rpm-ostree` to install content on a system in image mode (it is not supported), or
  making manual changes on a bootc host expecting them to survive.
- ❌ Deploying bootc from a **mutable tag with no signature or digest verification**.
- ❌ Adopting image mode without a build, signing and promotion pipeline already working.
- ❌ Designing anything new on top of **modularity** (`dnf module`): deprecated and with no content on RHEL 10.
- ❌ Editing `/etc/pam.d/` by hand instead of using `authselect` (it breaks the SSG/CIS content).
- ❌ Mixing direct `nft` rules with `firewalld` on the same host.
- ❌ `versionlock` with no owner or expiry date.
- ❌ Administering production hosts through Cockpit as the usual method (uncaptured manual change),
  or exposing Cockpit outside the management network.
- ❌ Running RHEL in production unregistered (no errata) or with expired entitlements.
- ❌ Putting into production a pinned **odd** minor expecting ELC coverage.
- ❌ Running `rpmbuild` outside `mock` for packages destined for production.

## 8. Mandatory web verification

Before pinning any version, date, EOL or GA status, **look it up — do not recall it**. And in
particular: **never read versions or dates from GitHub's HTML render — use `api.github.com` or the
Atom feeds.**

1. **RHEL lifecycle** at `access.redhat.com/support/policy/updates/errata`: phases, minors
   with ELC, and which add-on covers what. It is commercial content and changes without prior notice.
2. **Current version and EOL** of RHEL, Fedora, CentOS Stream, AlmaLinux and Rocky at `endoflife.date`
   **and** at the vendor's source. Verified Aug 2026: RHEL 10.2 / 9.8 / 8.10; Fedora 44 (F43 EOL
   2026-12-09, F42 already EOL); CentOS Stream 10 until 2030-05-31 and Stream 9 until 2027-05-31;
   AlmaLinux 10.2 and Rocky 10.2, both with EOL 2035-05-31.
3. **The official table of supported `leapp` paths** (by source and target minor) in the guide
   "Upgrading from RHEL 9 to RHEL 10" before planning any jump, and the current name of the
   `--channel` after the replacement of EUS by ELC.
4. **GA vs. Technology Preview status of each image mode piece** in the release notes of your
   exact version (bootc, `bootc-image-builder`, `%ostreecontainer`). It changes per minor.
5. **The `dnf5` version on your distro** and the status of the specific plugin you need at
   `github.com/rpm-software-management/dnf5` — plugin parity has mostly been closed, but
   niche gaps remain.
6. **Availability of your packages in EPEL 10** (per-minor repo) before committing to a
   migration to EL10.
7. **Active CVEs** of `sudo`, `dnf`/`rpm`, `podman`, `subscription-manager` and of the base image you
   use, prioritised with KEV/EPSS (`vulnerability-management-standards`).
8. **Microarchitecture requirement** (`x86-64-v2` vs `v3`) of the target hardware before choosing a
   distribution: it is a hard blocker, not a performance degradation.

**Declared gaps — NOT verified while writing this document; verify them before
relying on them:**

- **Whether RHEL 10 uses `dnf5` as the default manager** — **not verified**. What is confirmed is that
  `dnf5` is the default **on Fedora since 41**. Do not assume anything about RHEL 10 without checking it on
  the host or in the release notes.
- **Removal of `iptables` on RHEL 10**: the absence of the kernel module appears in a *downstream*
  report (moby/moby); **not confirmed against the "Removed features" chapter of the official release
  notes**. `nftables` is the replacement in any case.
- **RPM Fusion status for EL10** (RHEL/Alma/Rocky 10) — **not verified**. Only confirmed for
  Fedora 44.
- **EOL of EPEL 9 and the end-of-life policy of the `epel10.N` branches** — **not verified**.
- **The specific version of `tuned`, `cockpit`, `podman` and `leapp`** on each live distro — **not
  verified**. They have been described by usage criteria, without pinning a number.
- **The exact GA status of image mode per RHEL version** (what is a supported product and what is
  Technology Preview on 9.x vs 10.x, minor by minor) — only verified that the ISO via
  `bootc-image-builder` and `%ostreecontainer` are TP; **the rest has not been broken down per minor**.
- **Exact end-of-Full-Support dates for RHEL 9 and 10** (the move to Maintenance) — the
  end of lifecycle has been cited, **not the boundary between phases**.
- **Current legal terms of the Developer Subscription** (production use of the 16 systems):
  there is a contradiction between Red Hat's FAQ and third-party *compliance* readings. **Not
  resolved**: consult the official terms before deploying.
- **Detail of the cited CVEs** (`CVE-2025-32463`): CVSS, affected versions and KEV status
  **not verified**.
- **`dnf-automatic` and native reboot**: verified that Red Hat documents it as **not supported**,
  but **it has not been checked whether some recent version added `reboot`/`reboot_command`** to the
  package on your distro.

If the web contradicts this document, **the web wins** — flag the discrepancy.
