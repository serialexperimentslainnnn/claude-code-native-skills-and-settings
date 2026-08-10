---
name: selinux-standards
description: Mandatory access control on Linux with SELinux and AppArmor. Use when diagnosing AVC denials with ausearch, sealert, audit2allow or audit2why, managing labels and ports with semanage, restorecon, fixfiles, matchpathcon or chcon, toggling booleans with getsebool/setsebool, writing .te/.if/.fc or CIL policy modules with checkmodule, semodule, semodule_package, sepolicy generate, secilc or udica, editing /etc/selinux/config and enforcing/permissive modes, labeling containers (container_t, container_file_t, :z/:Z, container-selinux, seLinuxOptions/seLinuxChangePolicy), context= mount options for NFS, or writing AppArmor profiles with aa-genprof, aa-logprof, aa-complain, aa-enforce or aa-status.
---

# Mandatory access control standards (SELinux and AppArmor)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **operating, diagnosing and writing mandatory access control (MAC)** on Linux:
choosing between SELinux and AppArmor, modes and states, labelling of files and ports, booleans,
reading and triaging denials, developing and packaging your own policy, MAC in containers
and in shared storage, and AppArmor profiles.

Triggers: `AVC`, `avc: denied`, `ausearch`, `sealert`, `setroubleshoot`, `audit2allow`, `audit2why`,
`semanage`, `restorecon`, `fixfiles`, `setfiles`, `chcon`, `matchpathcon`, `getsebool`, `setsebool`,
`semodule`, `checkmodule`, `semodule_package`, `secilc`, `sepolicy generate`, `udica`,
`.te`/`.if`/`.fc`/`.cil`/`.pp` files, `/etc/selinux/config`, `getenforce`/`setenforce`, `sestatus`,
`container_t`, `container_file_t`, `:z`/`:Z`, `seLinuxOptions`, `seLinuxChangePolicy`, `context=`
as a mount option, `aa-genprof`, `aa-logprof`, `aa-status`, `/etc/apparmor.d/`,
"the service has not started since I enabled SELinux", "it works in permissive".

**Guiding principle**: **the right answer is almost never to switch it off, and it is almost always a
label.** The vast majority of SELinux incidents are **incorrect labelling** (a file,
directory or port with the wrong context), not a missing policy. The resolution order is
fixed and is not skipped: *is it a label problem?* → *is there a boolean for this?* → *is there a port
to register?* → and only then *your own policy, written and reviewed by hand*.

**Not applicable**: see `linux-hardening-standards` (**the baseline of the whole system and its measurement**:
CIS/STIG/ANSSI/CCN-STIC, OpenSCAP/Lynis, `sysctl`, SSH, auditd, sudo/PAM, mounts, systemd
sandboxing, measured boot — that skill **requires** "MAC in `enforcing`" as a control and audits it; this one
explains how the policy that makes it possible is operated and written), `onprem-standards` (platform
umbrella: hardware, OOB plane, hypervisor, fleet), `bash-linux-scripting-standards` (the scripts
that automate anything from here), `iac-standards` (Ansible as a tool and the CI of the infrastructure
repo — here only what is versioned and what is tested), `kubernetes-standards`
(the full `securityContext`, admission, Pod Security Standards and declarative cluster policy —
**here only the SELinux part**: `seLinuxOptions`, `seLinuxChangePolicy`, volume labelling),
`observability-standards` (collection, retention and correlation of AVC events in the SIEM),
`vulnerability-management-standards` (triage and SLA of the CVEs cited here),
`grc-compliance-standards` (MAC as a control required by ENS/ISO/NIST and its evidence),
`identity-access-management-standards` (identity, SSO, MFA and elevation — mapping confined
SELinux users belongs here, corporate identity belongs there), `networking-standards` (network
design and firewalling between zones; registering ports with `semanage port` belongs here),
`cryptography-pki-standards`, `appsec-standards` (failures in application code),
`homelab-standards`, `offensive-security-standards` (offensive verification of the confinement, with
scope and authorisation).

In addition:
`container-runtime-security-standards` (runtime security — seccomp, eBPF/Falco,
container escape detection. **Precise boundary: the container's MAC belongs to this skill**
—`container_t`, `container-selinux`, `:z`/`:Z`, udica, the container's AppArmor profiles—; **runtime
detection that something has escaped is theirs**),
`detection-engineering-standards` (turning AVCs into detection rules and SIEM use
cases), `linux-administration-standards` and `rhel-fedora-standards` (day-to-day of the
OS and RHEL-family specifics).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Which MAC is used | **The distro's native one**: SELinux on RHEL/CentOS Stream/Fedora/Rocky/Alma **and now also on SUSE**; AppArmor on Ubuntu and Debian | Changing a distro's MAC leaves you without the policy its packaging assumes and with the whole maintenance burden. Verified Aug 2026: **SLES 16.0 (GA 4 Nov 2025) removes AppArmor and boots with SELinux in enforcing** with a policy of **400+ modules**; openSUSE Tumbleweed since snapshot 20250211 and Leap 16 made the same change on new installations (exception: **SLES for SAP 16 is set to permissive automatically**) |
| Mode | **`enforcing`, always in production** | `permissive` is a diagnostic tool with an end date, not a deployment state (§4) |
| SELinux policy | **`targeted`** | It confines network services and leaves the rest unconfined: that is the right cost/benefit ratio. `mls` only with a formal multi-level requirement and a team that masters it; `minimum` only in very narrow cases |
| Disabling SELinux | **Never in production.** If a lab requires it: **`grubby --update-kernel ALL --args selinux=0`** | **Verified Aug 2026: `SELINUX=disabled` in `/etc/selinux/config` has been deprecated since RHEL 8 and kernel support was removed in RHEL 9.0.** The system boots with **SELinux enabled and no policy loaded**: the LSM hooks are still registered (and consuming resources), `sestatus` says "disabled" and it **looks** like it worked. It is the worst possible combination: neither protection nor clarity. Red Hat **explicitly discourages `selinux=0` in production** and recommends `permissive` for debugging |
| SELinux model | Labels on **all** objects (process, file, socket, port), domain transitions and confinement by type | It covers the whole system by label, survives `mv` and renaming, and also confines what has no predictable path. In exchange: a steep learning curve and failures from labelling |
| AppArmor model | Profiles **by path** of the executable, with reusable abstractions | Far easier to write and read; ideal for confining a specific application. In exchange: whatever has no profile is left **unconfined** (`unconfined` is the default state), and path-based confinement can be evaded with links, mounts and renames that SELinux does cover |
| SELinux userspace | The distro's; upstream **3.11** (1 Jul 2026; previous 3.10, Feb 2025) | 3.11 adds **`secilcheck`**, hardening of relabelling and security improvements in `libselinux`, `dbus`, `gui`, `mcstrans` and `sandbox`. Verified Aug 2026: **RHEL 10 ships userspace 3.8** and rebases `setools` to 4.6.0 in 10.2; Fedora 44 ships libselinux/policycoreutils **3.10** and `setools` 4.6.0 |
| Diagnostic tooling | **`setroubleshoot-server`** (`sealert`), **`policycoreutils-python-utils`** (`semanage`, `audit2allow`, `audit2why`), **`setools-console`** (`sesearch`, `seinfo`) | **They are not in the base install**: install them explicitly on the hosts where you are going to diagnose (and **restart auditd** after installing `setroubleshoot-server` so it loads the plugin). Verified Aug 2026: `setroubleshoot` **is still alive and maintained** in RHEL 10 (3.3.35) and Fedora 44 (3.3.36) — it is not deprecated |
| Containers | **`container-selinux`** (upstream **v2.250.0**) with `container_t` and per-container MCS separation | It is the default confinement of Podman/Docker/CRI-O and **the reason a container escape is not automatically a host escape**. Disabling it (`--security-opt label=disable`) is a risk decision, not a convenience one |
| Your own policy for a container | **`udica` v0.2.9** before hand-writing a `.te` | It generates policy from actual inspection of the container (Podman, Docker, containerd, CRI-O, LXD): blocks per exposed port, per mounted volume and its mode. It produces **CIL** loadable with `semodule -i`, and is applied with `--security-opt label=type:<type>.process` |
| Policy language | **`.te` + interface macros** (`selinux-policy-devel`) for your own policy; **CIL** when a tool generates it or you need to debug | **Everything ends up as CIL anyway**: `semodule` converts `.pp` files with the HLL compiler in `/usr/libexec/selinux/hll/`. Writing CIL by hand only pays off in automatic generation. Diagnostic trick: `/usr/libexec/selinux/hll/pp module.pp > module.cil` to read what a binary module does |
| Module priority | `semodule -X <1-999>` so your module beats the system's without touching it | Never edit or replace `selinux-policy` modules: they are lost on every update |
| AppArmor | **The 4.1 series (LTS, Apr 2025, 5 years of support)** as the stable base; 5.x only when the distro ships it | Verified Aug 2026: **5.0** (23 Apr 2026) is a declared *bridge* release with a **short life and no long-term support**; 5.0.1 (10 Jun 2026). **4.1.5 is defective — use 4.1.6+**. Packaging: Ubuntu 24.04 → 4.0.1; **Ubuntu 26.04 → 5.0.0~beta1**; Debian 13 → 4.1.0. Migration note: policy built with 4.1.x earlier than 4.1.4 could take 2-8× more space — **rebuild the policy caches after upgrading** |
| SELinux on Debian/Ubuntu | **No, unless explicitly required** (`selinux-basics` 0.6.0 exists in trixie and is maintained) | It is second-class support compared with AppArmor on those distros: the packaged policy does not get the same attention. If a framework requires it of you, validate it yourself, do not assume it |

## 3. Operation and diagnosis

### 3.1 Concepts you need to handle (and none beyond these to start)

- **Context**: `user_u:role_r:type_t:level` on every object and process (`ls -Z`, `ps -Z`, `id -Z`).
  Under the `targeted` policy **the deciding element is the type**; user, role and MCS level matter in specific
  cases (confined users, containers).
- **Domain**: the type of a process. **Domain transition**: when executing a binary with an
  *entrypoint* type, the process changes domain. A service running as `unconfined_t` instead of its
  own domain **is a labelling failure of the binary or of the unit**, not "SELinux not applying".
- **Boolean**: a switch provided by the policy for common behaviour variants.
- **Modes**: `enforcing` (enforces and logs), `permissive` (logs only), `disabled` (see §2 — with
  important nuances in RHEL 9+).

### 3.2 The three states you must always distinguish

| State | What it means | What to do |
|---|---|---|
| **Real denial** | The operation was blocked and the service fails | Full diagnosis (§3.3) |
| **`dontaudit`** | The policy **silences** expected and harmless denials | They are only unsilenced temporarily for diagnosis (§3.4) |
| **Irrelevant denial** | It was logged, but the service works anyway | **It is not "fixed"**: adding permissions because of noise is widening the surface for free |

### 3.3 Diagnosis: the fixed order

1. **Confirm it is SELinux**: `ausearch -m AVC,USER_AVC,SELINUX_ERR -ts recent`, `journalctl -t
   setroubleshoot`, `dmesg`. If the failure persists in `permissive`, **it is not SELinux** — stop looking
   here (and go back to `enforcing` immediately).
2. **Actually read the AVC**, not the summary: which **`scontext`** (source domain), which **`tcontext`**
   (target context), which **`tclass`** (object class) and which **permission**. That quartet is the whole
   diagnosis. `sealert -l <id>` gives an explanation and suggestions ordered by confidence — **the
   first is usually right and the following ones are usually too broad**.
3. **Is it labelling?** It is the cause in 80 % of cases. Compare the real context with the one expected
   by the policy: `ls -Z`, `matchpathcon`/`selabel_lookup`, `restorecon -nv <path>` (a dry run that
   says exactly what would change). If the file is in an unusual place, the solution is not to
   allow the access: it is **registering the correct context for that path** (§3.6).
4. **Is there a boolean?** `semanage boolean -l | grep <hint>`, `getsebool -a`. If there is, use it
   (§3.5). Writing your own policy when a boolean exists is a beginner's error with a permanent cost.
5. **Is it a port?** A service listening on a non-standard port → `semanage port -a -t <type> -p tcp
   <port>` (`-m` if the port is already registered for another type). It is never solved with policy.
6. **Is it really policy?** Only then (§3.7). And with your own module, reviewed and versioned.

### 3.4 `dontaudit`: how not to lose half an afternoon

If the service fails and **you see no AVC at all**, suspect `dontaudit`:

- Disable temporarily: **`semodule -DB`** (`-D` removes the `dontaudit`s, `-B` rebuilds and
  reloads the policy).
- Reproduce the failure and look again: `ausearch -m AVC -ts recent`.
- **Always restore**: **`semodule -B`**. The "no dontaudit" state **survives a reboot**, so
  forgetting leaves the host generating noise indefinitely. Careful: any policy rebuild
  (`semodule -i`, `setsebool -P`) reverts it on its own, which produces irreproducible
  diagnoses if you are not tracking it.

### 3.5 Booleans before your own policy

```
semanage boolean -l          # listing with current state, pending state and description
getsebool -a                 # raw listing
setsebool <bool> on          # temporary, to test
setsebool -P <bool> on       # persistent (rebuilds the policy)
```
Rule: **if a boolean exists that covers the case, it is used and recorded in the configuration code
with a comment saying why**. A boolean enabled by hand on a host is drift and disappears
on the next rebuild of the server.

### 3.6 Persistent labelling: `semanage fcontext` + `restorecon`, never `chcon`

```
semanage fcontext -a -t httpd_sys_content_t "/data/nginx(/.*)?"   # rule in the policy
restorecon -Rv /data/nginx/                                        # apply to the files
```
- **`chcon` is not persistent**: it is lost on the next relabel or `restorecon`. It is good for a
  30-second test and nothing else (§7).
- It is a **regular expression, not a glob**, and **the quotes are mandatory**: `(/.*)?` means "the
  directory and everything under it".
- `-a` add, `-m` modify, `-d` delete, `-l` list (**`-C` to see only the local ones**, which is
  what you actually want to audit).
- By default `restorecon` **only fixes the `type` field**; use **`-F`** to reset all four
  fields. `-n` for a dry run, `-R` recursive, `-v` to see what changes.
- **Full relabel**: `fixfiles relabel` or `touch /.autorelabel` + reboot. On a large host
  it costs real time: plan it, do not fire it off live.
- New files **inherit the type of the parent directory** unless the policy defines a
  `type_transition`. That is why "I moved the file with `mv` and it stopped working" is a classic:
  `mv` keeps the source context, `cp` inherits the destination's.
- **Change in RHEL 10 to bear in mind**: `semanage` **no longer sorts local `fcontext`
  definitions** — the order in which you add them matters. And the binary format of `file_contexts.bin`
  changed: **files in the old format are ignored**, the policy has to be rebuilt.

### 3.7 Writing your own policy

- **`audit2allow` is a draft generator, not a solution.** It generates rules from what it
  saw, and what it saw is usually *too much* — it grants broad permissions over generic types and, if the
  process was doing something it should not, **it grants it permission to do so**. Applying its output without
  reading it is forbidden (§7). Correct use:
  ```
  ausearch -m AVC -ts recent | audit2allow -R          # suggestions with interface macros
  ausearch -m AVC -ts recent | audit2allow -M mymodule # generates .te and .pp
  audit2allow -w -a                                     # audit2why: why it was denied
  ```
  The `.te` **is read line by line**, generic types are replaced with specific ones,
  the permissions that are not needed are removed, and **only then** is it compiled. If the generated `.te` has
  dozens of rules, the problem is almost certainly labelling, not policy. (Verified Aug 2026: on
  RHEL 10, `audit2allow -C` produces output in **CIL**.)
- **A clean starting point**: `sepolicy generate` (from `policycoreutils-devel`) for a new
  service, or **`udica`** if it is a container. They produce a skeleton with a domain, a transition and coherent
  `.te`/`.if`/`.fc` files, which is a far better base than an accumulated `audit2allow`.
- **Anatomy**: `.te` (rules and types), `.if` (interfaces reusable by other modules), `.fc`
  (file contexts by path). Classic compilation:
  ```
  checkmodule -M -m -o mymodule.mod mymodule.te
  semodule_package -o mymodule.pp -m mymodule.mod -f mymodule.fc
  semodule -X 400 -i mymodule.pp
  ```
  CIL modules are loaded directly with `semodule -i mymodule.cil`.
- **Development cycle**: write → load on a test host → run the service in
  `permissive` **only on that host** → collect AVCs → refine → back to `enforcing` → **test that the
  service actually works** → package.
- **Packaging and distribution**: your own policy is distributed as a **package** (an RPM with the
  `.pp`/`.cil` and the `semodule -i`/`-r` scriptlets) or as an idempotent role, **versioned in the
  same repo as the rest of the service's configuration**. A policy that only exists on the
  host where somebody loaded it by hand is a guaranteed snowflake.

### 3.8 SELinux and containers

- **Model**: container processes run as **`container_t`**, can only read and execute
  from `/usr` and write over **`container_file_t`**; the runtime assigns **two unique MCS categories**
  per container, which is what isolates one container from another. `spc_t` (super privileged container) is
  the legitimate escape hatch: an `spc_t` container **is not confined** — treat it as code on the host.
- **Volumes**: `:z` = `relabel=shared` (a label allowing access to **all**
  containers); `:Z` = `relabel=private` (a unique MCS category, only that container). **`:Z` by
  default**; `:z` only when several containers share the volume on purpose. **Classic
  danger**: `:Z` over a system directory (`/home`, `/var`, `/usr`) recursively relabels
  **the host's real directory** and can leave it unusable. Mount dedicated subdirectories, never system
  paths.
- **Useful booleans before policy**: `container_use_devices`, `container_connect_any`,
  `container_manage_cgroup`, `container_read_certs`, `container_can_execstack`. Each one widens the
  surface: enable the one that is needed, not the one that "seems reasonable".
- **`--security-opt label=disable` is forbidden as a shortcut** (§7). If a container needs more
  than `container_t` grants, the answer is **udica** (your own narrowed policy) and
  `--security-opt label=type:<type>.process`, not removing the confinement.
- **Kubernetes** — verified Aug 2026 (§8): `securityContext.seLinuxOptions` (user/role/type/level)
  is stable at Pod and container level. In **v1.36**, **`SELinuxMountReadWriteOncePod`
  and `SELinuxChangePolicy` went GA**; **`SELinuxMount` remains in beta and disabled by default**, and it is
  expected to go GA enabled in **v1.37** (not yet released as of this date). The change is real:
  recursive relabelling is replaced by **`mount -o context=`**, which speeds up Pod startup
  a great deal **but imposes a single label per mount** — two Pods with different labels
  sharing a volume on the same node will fail to start. Mandatory actions before
  migrating: enable the `selinux-warning-controller` in `kube-controller-manager` and watch the
  `selinux_warning_controller_selinux_volume_conflict` and
  `volume_manager_selinux_volume_context_mismatch_warnings_total` metrics; the per-workload opt-out is
  `spec.securityContext.seLinuxChangePolicy: Recursive`. It also requires the CSI driver to declare
  `CSIDriver.spec.seLinuxMount: true`.

### 3.9 SELinux, systemd, NFS and shared storage

- **systemd**: the service's confinement depends on the binary having the correct *entrypoint*
  type. If `ps -Z` shows the service in `unconfined_service_t`, check the label of the binary
  and of the unit before touching policy. systemd sandboxing is **complementary**, not
  a substitute: `systemd-analyze security` **ignores SELinux and AppArmor** (see
  `linux-hardening-standards`).
- **Filesystems without xattr** (classic NFS, FAT, CIFS): `semanage fcontext` + `restorecon` **are
  no use** — there is nowhere to write the label. The mechanism is the **mount option**:
  - `context=<context>` — forces a single context for the **whole** mount. It is not written to disk;
    the original contexts reappear when mounting without the option.
  - `defcontext=` — default context for unlabelled files (new ones **do** persist).
  - `fscontext=` — labels the superblock without changing the files' labels.
  - `rootcontext=` — labels the root inode before it is visible to userspace.
- By default NFS mounts get the type **`nfs_t`**, which is what usually stops `httpd` or
  another service reading the share without `context=` or without the corresponding boolean.
- **Labeled NFS** (real transport of contexts): requires **NFSv4.2**, the **`security_label`
  option on the server's export** (explicit since kernel 4.11; before that it was the default behaviour)
  and the client mounting with **`vers=4.2`** — **there is no `security_label` option on the client**.
  `context=` and native labelling are **mutually exclusive**. A known bug to keep in mind: the
  mount point may transiently appear as `unlabeled` right after mounting, producing
  denials on `unlabeled_t`.

### 3.10 AppArmor: usage criteria

- **Profiles in `/etc/apparmor.d/`**, versioned in the service's repo, leaning on the
  **abstractions** (`abstractions/base`, `nameservice`, `openssl`…) instead of rewriting rules.
- **Cycle**: `aa-genprof <binary>` for the draft while running the app, `aa-logprof` to refine from
  the log, `aa-complain` (equivalent to `permissive`, **per profile**) during tuning,
  `aa-enforce` when finished. `aa-status` to know what is actually confined — and **whatever does not
  appear there is unconfined**, which is the structural difference from SELinux.
- **Honest limits versus SELinux**: confinement **by path**, not by label (links,
  bind mounts and renames require explicit care); no comparable type control over sockets and
  ports; no MCS to isolate N instances of the same binary from one another; and **everything that
  has no profile is left `unconfined`**. In exchange: it can be written and read in an afternoon.
- **Ubuntu 24.04+/26.04**: the restriction on unprivileged user namespaces is implemented **as
  AppArmor** (`kernel.apparmor_restrict_unprivileged_userns=1` by default). It is a real security
  control: before lowering it for an app that "does not start", write a profile for that app
  (upstream's `bwrap-userns-restrict` pattern). Context: Qualys published in Mar 2025 **three bypasses**
  of that restriction (via `aa-exec` towards permissive profiles and via busybox's default
  profile) — do not treat it as a hard boundary.
- **Known current risk — CrackArmor (Qualys, 12 Mar 2026)**: nine vulnerabilities in the
  **kernel's AppArmor module**, present since v4.11 (2017), with assigned CVEs
  (**CVE-2026-23268, -23269, -23403 … -23411**). Central vector: *confused deputy* — an unprivileged
  user induces a privileged binary to write to
  `/sys/kernel/security/apparmor/{.load,.replace,.remove}`, with impacts reaching **policy
  manipulation** (loading a deny-all profile for `sshd`), local escalation to root via a use-after-free in
  profile load/replace, and DoS through nested subprofiles that exhaust the kernel stack. **Action**:
  patch the distro kernel and confirm coverage in the vendor's tracker.

## 4. Quality gates

1. **You never deploy in `permissive` "and we will see".** `permissive` is used **only** in non-production,
   **only** during policy development, and with an **end date in the ticket**.
   A host that has been in permissive for months is not protected and nobody has noticed.
   Mechanical gate in CI/inventory: `getenforce` different from `Enforcing` in production = **a finding**, just like a
   pending patch.
2. **Proof that the policy does not break the service**: the gate is functional, not startup. Exercise
   the real path (requests, writing files, connecting to the database, log rotation, service
   restart) with the policy loaded and in `enforcing`, and **verify that no new AVC
   appears**: `ausearch -m AVC -ts <test-start>` must come back empty. systemd saying
   `active` proves nothing.
3. **Restart and relabel test**: the policy and the labels must survive a reboot and
   a `restorecon -R` over the affected paths. This gate is the one that catches clandestine `chcon`s.
4. **Policy versioned in the repo, alongside the rest of the service's configuration**: `.te`, `.fc`,
   `.if` (or `.cil`), `semanage fcontext` and `semanage port` rules and booleans, all as idempotent
   code. PR review with the same rigour as any security change.
5. **Mandatory human review of all `audit2allow` output** before compiling, with a
   per-rule justification in the commit. Nobody merges a `.te` they have not read.
6. **Drift detection**: booleans, local contexts (`semanage fcontext -C -l`, `semanage port
   -C -l`) and loaded modules (`semodule -l`) are compared with what is declared. Any difference is a
   finding — it is the typical signature of "somebody fixed something at 3 in the morning".
7. **AVCs go to the SIEM and have an owner.** A denial in production is a signal: either configuration
   is missing or somebody is doing something they should not. A stream of AVCs nobody looks at
   turns MAC into decoration (telemetry destination: `observability-standards`; its
   exploitation as detection: `detection-engineering-standards`).

## 5. Security: what MAC protects and what it does not

- **What it provides**: containment after exploitation. A compromised service stays locked inside its
  domain; a container escape hits `container_t` and the MCS categories. It is the control
  that turns "RCE in the web service" into "RCE inside `httpd_t`".
- **What it does not provide**: it does not fix vulnerabilities and does not replace patching. **A kernel flaw
  can nullify its guarantees entirely**, and 2026 has produced verified examples: **CVE-2026-53362**
  (RHSB-2026-009: out-of-bounds write in the IPv6 path → arbitrary kernel read/write,
  **SELinux bypass** and container escape, exploitable because RHEL 10's default
  configuration grants user namespaces to unprivileged users) and **CVE-2026-64600**
  ("RefluXFS", Qualys, Jul 2026: a race in the XFS copy-on-write path giving root on the host **even
  with SELinux in Enforcing**, because it operates below the policy layer; the only reliable
  mitigation: patch and reboot). Prioritise kernel patching: MAC is defence in depth, not a
  substitute.
- **Your own policy widens the surface**: every `allow` you add is a permission the attacker
  also has. Write the minimum, review the diff, and prefer an existing boolean to a new
  rule.
- **Watch the unconfined domains**: services running as `unconfined_service_t`,
  containers in `spc_t`, processes with `--security-opt label=disable`, executables with no AppArmor
  profile. That inventory **is** your real surface, and it usually surprises.
- **Users are confined too**: `semanage login` to map accounts to SELinux users
  (`user_u`, `staff_u`, `guest_u`) on multi-user or shared-access hosts. Little used and very
  effective when it applies.
- **`setenforce 0` is a security event, not a routine operation**: it must raise an alert,
  be logged and require justification. It is exactly what an attacker with root does.

## 6. Performance and operability

- **Cost**: the SELinux check is cheap; what is expensive is **relabelling**. A `fixfiles relabel` or
  a `touch /.autorelabel` on a large filesystem is a maintenance window, not a command.
  Same with `:Z` over enormous container volumes: every start relabels. That is exactly the
  problem solved by mounting with `-o context=` in Kubernetes (§3.8).
- **`restorecon -R` scoped to the affected path** instead of a global relabel; on hosts with little memory
  and many hard links, RHEL 10.2 adds `setfiles -A` to disable inode conflict
  tracking.
- **A written and tested diagnostic runbook**: how AVCs are collected, how `permissive` is enabled on
  **one** host with a ticket and an expiry, how it is reverted, and to whom it is escalated. Without a runbook, the
  3 a.m. incident ends in a permanent `setenforce 0`.
- **Packaging in RHEL 10 to bear in mind**: EPEL-only policy modules moved out of
  `selinux-policy` into `-extra` subpackages (CRB repo), which reduces size and speeds up
  policy rebuild and load. If an EPEL service "has no policy", check that the
  subpackage is installed before writing your own.
- **Rollback**: `semodule -r <module>` and `semanage -d` of the added entries, tested. Every
  policy of your own is deployed with its uninstallation verified.

## 7. Sustainability and prohibitions

**Cadence**
- Review your own policy on every major distro and `selinux-policy` update: the
  interfaces change and a module that compiled may stop doing so (RHEL 10 also changed the
  binary format of `file_contexts.bin` and ignores the old one).
- Rebuild AppArmor policy caches after updating within the 4.1.x series and when jumping from 4.x to 5.x
  (4.0 policy is compatible in 5.0, but 5.0 introduces non-backwards-compatible features).
- Review the exceptions inventory quarterly: enabled booleans, loaded custom modules,
  containers with `label=disable`, executables with no AppArmor profile. Every exception with an
  owner and a re-evaluation date.
- Patch the kernel as a priority when the finding affects the LSM module itself (CrackArmor) or
  allows a MAC bypass (§5).

**FORBIDDEN**
- ❌ **`setenforce 0` as a solution.** It is a temporary diagnostic on one host, with a ticket, and it is reverted
  in the same session. As a "fix", it is disabling the security control and leaving it that way.
- ❌ **`selinux=0` on the boot line** of a production system (nor a permanent `enforcing=0`).
  And **`SELINUX=disabled` in `/etc/selinux/config`** on RHEL 9+, which does not even do what
  it appears to (§2).
- ❌ **Applying `audit2allow` output without reading it**, or merging a generated `.te` without human
  review rule by rule.
- ❌ **`chcon` as a permanent fix**: use `semanage fcontext` + `restorecon`. A `chcon` in a
  playbook or in a startup script is debt that blows up on the next relabel.
- ❌ **Custom policy without tests**: without a functional test in `enforcing`, without a reboot and
  relabel test, and without verifying that no new AVCs appear.
- ❌ Custom policy that only exists on one host, loaded by hand and not versioned.
- ❌ Editing or replacing the system's `selinux-policy` modules instead of loading your own module with a
  priority (`semodule -X`).
- ❌ Deploying in `permissive` "until there is time", or leaving `semodule -DB` in place after
  diagnosing.
- ❌ **`--security-opt label=disable`**, `privileged` with MAC disabled or containers in `spc_t`
  as the usual way of resolving a denial.
- ❌ `:Z` over the host's system directories (`/`, `/usr`, `/var`, `/home`) — it relabels
  recursively and can leave the host unusable.
- ❌ Adding rules because of **noise**: logged denials that do not affect operation are
  investigated, not allowed.
- ❌ Replacing the distro's native MAC (SELinux↔AppArmor) without a real need and without taking on the
  full maintenance of the policy.
- ❌ Treating MAC as a substitute for kernel patching (§5).
- ❌ Pinning versions, type names, mount options or feature states **from memory** without the
  verification of §8.

## 8. Mandatory web verification

Before pinning any concrete data point, **look it up — do not recall it**:

1. **Status of `SELINUX=disabled`** in the exact version of your distro (verified Aug 2026:
   deprecated since RHEL 8, **kernel support removed in RHEL 9.0**; supported method
   `grubby --update-kernel ALL --args selinux=0`). **Declared gap**: no equivalent
   **Fedora** note explicitly stating this was located; the behaviour is assumed to be the same
   because kernel and userspace are shared, but **it is not verified**.
2. **Version of `selinux-policy`, userspace and `container-selinux`** in your distro (verified
   Aug 2026: upstream userspace **3.11**, 1 Jul 2026, with `secilcheck`; **RHEL 10 ships userspace
   3.8**; Fedora 44 ships 3.10 and `selinux-policy` 44.5; `container-selinux` **v2.250.0**).
   **Declared gaps**: the **exact NVR of `selinux-policy` on RHEL 9.x and 10.x GA**, the **userspace
   version on RHEL 9**, and the **release dates of `container-selinux` 2.250.0 and of `udica`
   0.2.9** could not be confirmed.
3. **Status of `setroubleshoot`/`sealert`** in your version (verified Aug 2026: **not deprecated**,
   present and maintained in RHEL 10 and Fedora 44). **Declared gaps**: the
   *Deprecated functionality* chapter of the RHEL 10.x notes could not be read (403) — the absence of deprecation is
   inferred, not read; nor was it confirmed **whether it is still installed by default** (in minimal
   images and Image Mode probably not).
4. **Tooling changes by version**: `audit2allow -C` (CIL output), `semanage` no longer
   sorting local fcontexts, the new `file_contexts.bin` format, `setfiles -A`, `seinfo
   --role_types` — all verified in the RHEL 10.x notes, but **read them for your version** before
   taking a syntax for granted. **Declared gaps**: whether the **`matchpathcon`** binary has been
   removed (it has been obsolete at the API level for years in favour of `selabel_lookup`) and the
   exact status of **`sepolicy generate`** on RHEL 10.
5. **`semodule -DB` / `-B`** versus `semanage dontaudit off/on`: **declared gap** — only
   `semodule -D/-B` is precisely documented in the man page; the equivalence of `semanage dontaudit`
   comes from an informal mailing list answer. Use `semodule`.
6. **Status of the SELinux feature gates in Kubernetes** in the cluster's exact version
   (verified Aug 2026: `SELinuxMountReadWriteOncePod` and `SELinuxChangePolicy` **GA in v1.36**;
   `SELinuxMount` **beta and off by default in v1.36**, with GA expected in v1.37, **not yet
   released**). This changes per release: do not quote it from memory. **Declared gap**: the
   specific **CRI-O** configuration was not verified.
7. **Status of labeled NFS per distro**: **declared gap** — no formal support statement
   (supported? *tech preview*?) was found for RHEL 10 or others. Verify it before designing
   on top of it.
8. **AppArmor**: latest version and its support series (verified Aug 2026: **5.0** 23 Apr 2026 as a
   *bridge* release with no long support, **5.0.1** 10 Jun 2026, **4.1 LTS** from Apr 2025; **4.1.5
   defective**; Ubuntu 24.04 → 4.0.1, Ubuntu 26.04 → 5.0.0~beta1, Debian 13 → 4.1.0). **Declared
   gaps**: the upstream date of **5.0.2**, the detail of 5.0's tooling manifest, and
   a confirmation from a **Debian** release note that AppArmor is the default MAC in
   trixie.
9. **Status of SELinux support on Debian/Ubuntu**: `selinux-basics` 0.6.0 exists and is
   maintained in trixie. **Declared gap**: **there is no verified evaluation of its real usability**
   (coverage and freshness of the packaged policy) — do not take it as good without testing it yourself.
10. **CVEs**: verified and citable — **CrackArmor** (kernel AppArmor, Qualys 12 Mar 2026,
    CVE-2026-23268/23269/23403-23411), **CVE-2026-53362** (RHSB-2026-009, SELinux bypass and container
    escape), **CVE-2026-64600** ("RefluXFS", root with SELinux in Enforcing), and the three
    bypasses of Ubuntu's userns restriction (Qualys, Mar 2025, **with no CVE assigned**).
    **Declared gaps**: **no 2025-2026 CVE specific to the SELinux userspace was found**
    (`libselinux`, `policycoreutils`, `setools`) nor to `container-selinux` — the 3.11 release mentions
    generic security improvements with no associated CVE; and **CrackArmor's per-vendor patch dates
    were not verified** (check them in your distro's tracker). `CVE-2025-0078` circulates
    as a "SELinux bypass": **it is Android/AOSP's, not the upstream userspace's** — do not cite it as
    such.
11. **SUSE's migration to SELinux** if you operate that family (verified Aug 2026: SLES 16.0 GA
    4 Nov 2025 with AppArmor removed and SELinux enforcing; SLES for SAP in permissive; openSUSE
    Tumbleweed since snapshot 20250211 and Leap 16). **Declared gap**: the status of **SLE 15
    SP7** was not verified individually.
12. **Plan for source policy towards CIL**: **declared gap** — no evidence was found of
    any announcement to migrate `selinux-policy`/refpolicy to CIL as the default **source** language.
    Today the supported path is still `.te` + interface macros.

If the web contradicts this document, **the web wins** — flag the discrepancy.
