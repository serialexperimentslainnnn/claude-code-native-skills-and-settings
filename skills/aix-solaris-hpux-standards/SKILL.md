---
name: aix-solaris-hpux-standards
description: Proprietary Unix operating systems still in production — IBM AIX on Power, Oracle Solaris on SPARC and x86, and HP-UX on Itanium. Use when working with AIX (oslevel -s, Technology Levels and Service Packs, instfix, smit/smitty, lsattr, lsdev, lspv, chdev, mksysb, alt_disk_copy, NIM, Live Update, JFS2, LVM volume groups, rootvg, errpt, lparstat, nmon, topas, WPARs, PowerVM LPARs, VIOS and padmin, HMC, Update Access Key/UAK, SWMA), Solaris (svcs and svcadm SMF services, /etc/svc manifests, pkg and IPS publishers, beadm boot environments, SRU levels, zoneadm/zonecfg native and kernel zones, LDoms/ldm, ZFS on Solaris, dtrace, prstat, zpool, /etc/system, Oracle Lifetime Support tiers), HP-UX (swinstall/swlist/swremove, SD-UX depots, Ignite-UX recovery images, LVM/VxVM and vgdisplay, /etc/lvmtab, ioscan, setboot, Serviceguard packages, nPars and vPars, Integrity rx/rx2800 and Superdome Itanium hardware), illumos distributions (OmniOS, SmartOS, OpenIndiana, Tribblix), ksh88/ksh93 scripting for these platforms, or planning to freeze, extend support for, or migrate off any of them.
---

# Proprietary Unix standards: AIX, Solaris and HP-UX

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**These three systems are not in the same situation and the criteria depend on which one it is.** Throwing them
into a single "legacy Unix" bucket is the starting mistake:

- **AIX is alive.** Current release **7.3**, with a new *Technology Level* every year (TL4 released in
  **Dec 2025**), new hardware underneath (Power11, Jul 2025) and a roadmap. Here you plan
  **upgrades**, not an exit.
- **Solaris is frozen but contracted for a very long term.** Oracle stopped major development
  in 2018: **there is no Solaris 12**, only 11.4 with SRUs. But the published calendar reaches **2037**
  and in 2026 Oracle *lowered* the patch cadence (§2). Here you decide whether you lean on a maintenance
  contract for a platform with no functional future.
- **HP-UX is finished.** Standard support for 11i v3 on Integrity **ended on 31-Dec-2025**;
  what remains until 2028 is *mature support without sustaining engineering* — that is, **there are no
  new patches**, not even security ones. And there is no hardware: **Intel stopped shipping Itanium in
  2021**. Here you do not plan an upgrade: you plan an **exit or isolation**.

Covers: the calendar and current version of each one (§2); the platform-specific detail that decides
operations (§3); inventory and audit of what actually runs (§4); patching, accounts and
exposure (§5); hardware, spare parts and extended support contracts (§6); and the criteria for
freezing, isolating or migrating (§7).

**Why they are still alive** —and it has to be said without cynicism, because it is the real reason and sometimes it is
correct—: an **application certified by the vendor only on that system**, hardware already
written off with an almost zero marginal cost, and an organisation that **does not know what the machine does** and
therefore cannot estimate the migration. All three reasons are legitimate as a diagnosis and none
of them is legitimate as an indefinite plan.

**Not applicable**:
- `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` and `zfs-standards` (**already written**): **Linux and ZFS are theirs** —
  including ZFS as a technology; here only what ZFS means *inside Solaris* (§3.2).
- `onprem-standards` (**platform umbrella, with the routing table**),
  `ha-clustering-standards` (generic clustering; here Serviceguard/PowerHA only as a platform
  fact), `backup-recovery-standards` (**theirs the mechanics of copy and restore**; here
  `mksysb` and Ignite-UX only as a system image), `homelab-standards`, `bcdr-standards`,
  `os-provisioning-standards`, `server-hardware-standards`,
  `identity-access-management-standards`, `secrets-management-standards`,
  `vulnerability-management-standards`, `detection-engineering-standards` (**theirs the detection
  rules**), `endpoint-security-standards`, `firewall-policy-standards`, `networking-standards`,
  `iac-standards`, `grc-compliance-standards`, `legacy-modernization-standards` and
  `migration-projects-standards` (**these two, theirs the portfolio strategy and the execution of the
  project; here what each option technically implies**).
- `ibm-i-rpg-standards` (**already written**): **IBM i is another operating system**, not a variant of
  AIX — they share Power and HMC/LPAR and nothing else. `mainframe-zos-cobol-standards` and `mumps-standards`:
  same mental drawer, criteria not extrapolable.
- `bsd-systems-standards` and `macos-fleet-standards`: **the name "Unix" lumps them together and they share
  almost nothing operationally** — BSD is not proprietary Unix (it is a living family that you choose, not one you
  inherit) and macOS is a fleet of workstations, not of servers.

## 2. Verified status of each platform

> Verify the latest version on the web before pinning it in a real project (§8).

| Platform | Current version | Published calendar | Hardware it is tied to |
|---|---|---|---|
| **AIX** | **7.3**, TL4 (`7.3.4`, Dec 2025) | IBM publishes *End of Fix Support* **per TL**: TL4 → 31-Dec-2028, TL3 → 31-Dec-2027, TL2 → 30-Nov-2026, TL1 expired 31-Dec-2025. *Enhanced* policy: minimum 5 years + a 3-year extension | Power (CHRP) POWER8/9/10/Power11. **Power11 requires HMC V11, which does not support POWER8** — and the HMC 7063-CR1 *is* POWER8: it gets replaced |
| **AIX 7.2** | TL5 still supported | **No verified published EOS date** (§8, gap) | POWER8/9/10 |
| **VIOS** | 4.1.1.10 | 4.1.0.40 end of service 30-Nov-2026; 3.1.4.60 on 30-Apr-2026; 4.1.1.10 until 31-Dec-2027 | Tied to the Power generation and to the HMC level |
| **Solaris** | **11.4** (GA Aug 2018), SRU93 (16-Jun-2026) | Premier until **Nov 2031**, Extended until **Nov 2037**, Sustaining indefinite. Solaris 10 and 11.3 move to Sustaining in **2027** | SPARC (Oracle's M8/T8, **Fujitsu's M12**) and **x86** |
| **Solaris — cadence** | Two deliveries per quarter since 11.4.92 | Announcement of 23-Apr-2026: quarterly **CPU** synchronised with Oracle's security cycle + **SRU** ~6 weeks later. Previously it was monthly | — |
| **HP-UX** | **11i v3 (11.31)**, latest delivery 2505.11iv3 (May 2025) | *"HPE Integrity: standard support through 31-Dec-2025"* (ended). Current status: *"Mature Software Product Support without Sustaining Engineering through at least 31-Dec-2028"* | **Itanium. Intel stopped shipping Itanium in 2021**: there is no and there will be no new hardware |
| **illumos** (Solaris derivatives) | **OmniOS r151058** (2026-05-04, end 2027-05-03); **LTS r151054** until 2028-05-01 | LTS every fourth delivery, **3 years**; stable, 1 year. Half-yearly cadence, sustained without gaps since 2017 | x86 (SPARC is not a practical target) |
| **SmartOS** | Active (platform image May 2026) | Rolling images, no versioned releases. **Owned by MNX since 2022** (bought from Joyent) | x86; the base of Triton DataCenter |

**illumos licence, quoted verbatim from its FAQ**: *"The bulk of the illumos source code is
available under the Common Development and Distribution License (CDDL)"*, with *"some components
with other licenses including BSD and MIT"* and GPL/LGPL software included. **CDDL is file-level
copyleft and incompatible with GPLv2**: that is what decides whether you can mix code, not the
"open source" label.

**Declared discrepancies:**
- **AIX**: third-party aggregators publish "AIX 7.3 EOS on 30-Sep-2026". **IBM does not publish the
  EOS date of an AIX release until it has passed**; what it does publish is the end of fix
  support *per TL*. Do not cite that 2026 as the end of life of 7.3.
- **HP-UX**: the date **31-Dec-2028** circulates as "extended support". It is not: it is mature
  product support **without sustaining engineering**. Treating it as security coverage is a
  risk error, not a nuance.
- **Solaris**: the 2031/2037 calendar comes from the *Oracle Lifetime Support Policy* document and from
  specialist press; **the official PDF was not retrievable in an automated way** in this
  verification (§8).

## 3. The platform-specific detail that decides

### 3.1 AIX
- **The deployment unit is the LPAR**, not the server: CPU and memory move live and
  I/O goes through **VIOS**. A VIOS without a pair is a SPOF that voids the HA of everything above it:
  **VIOS in a pair, always**, and its update is a procedure of its own, done before the rest.
- **TL and SP are not the same**: the TL brings function and resets the support clock; the SP fixes.
  The healthy cadence is **one TL a year and the current SP**, not "when there is a problem" (§5).
- **`mksysb` is the system image** and **NIM** is what deploys it; the one nobody has restored is
  not a copy, it is a file (policy in `backup-recovery-standards`). **Live Update** avoids the
  reboot for the kernel, not the window nor the testing: only validated on your LPAR/VIOS combination.
- **UAK (*Update Access Key*) is the new operational trap**: since **7.3 TL4** updates and
  migrations **fail** with an expired key — **a lapsed SWMA contract blocks patching**. Its
  date goes in the calendar, not in someone's head.
- `smit` generates commands: you automate the command (`chdev`, `lsattr`, `installp`), not the screen.
  **No production change is made by menu alone and without being recorded.**

### 3.2 Solaris
- **ZFS was born here**, and it is the reason these machines are still defensible: `zpool` with
  checksums, cheap snapshots and, above all, **boot environments (`beadm`)** — you update
  with a rollback guaranteed by reboot. **Any SRU is applied onto a new BE**;
  doing it any other way throws away the platform's only real advantage.
- **Zones before virtual machines**: the native zone is consolidation at almost no cost and remains
  the clean way to encapsulate an old application. **A `solaris10` branded zone is the containment
  play par excellence** when the application does not go beyond Solaris 10 (§7).
- **SMF** turns services into manifests with dependencies: inherited rc scripts are
  migrated, not wrapped. A service in `maintenance` is a failure, not a notice. **DTrace** is what
  makes the platform diagnosable, and what is missed at the migration destination.
- **Updating is `pkg update` to an SRU**, not reinstalling. Staying on an old SRU means going without
  Oracle's quarterly CPUs: the risk accumulates silently.
- **The illumos derivatives (OmniOS, SmartOS) are a real exit for *storage and
  virtualisation*, not for the certified application**: they keep ZFS, zones and DTrace, are
  maintained and are free, but **no commercial software vendor certifies them**. If the
  reason for staying on Solaris is vendor certification, illumos solves nothing.

### 3.3 HP-UX
- Everything decided here is **about the exit**: `swlist` to know what is installed, **Ignite-UX**
  to have a restorable image *today*, and `ioscan` for the inventory of hardware with no spare parts.
- **Serviceguard** may be sustaining an HA setup whose only irreplaceable piece is the hardware.
  A two-node Itanium cluster with no spares is not high availability: it is two clocks at once.
- **Freezing is a valid decision (§7); not patching without freezing is not.**

## 4. Inventory: knowing what runs

> *(The format's "quality and testing" section is omitted: there is no toolchain of its own to set.
> What takes its place here is the inventory, because it is the control missing in all of these cases.)*

**On these systems nobody knows what runs**, and it is almost always literal: whoever set it up left, the
documentation is from another decade and the application "just works". Before deciding anything —freeze,
extend support or migrate— you have to produce, dated and in the repository:

1. **Which processes listen and who talks to them**: ports and connections observed over a complete
   business cycle, year-end close included. **The integration nobody remembers shows up at the
   year-end close, not in April.**
2. **What third-party software is there and at which version** (`lslpp`/`pkg list`/`swlist`), what is
   certified by the vendor and **against which exact version of the operating system**.
3. **What scheduled jobs exist** (`cron` for all users, corporate scheduler).
4. **Who has access and from where**, including service accounts and old trusts (§5).
5. **What gets restored and in how long**, tested — not the procedure, the rehearsal.

Without these five points, any migration estimate is fiction and any decision to
stay is inertia disguised as criteria.

## 5. Security and patching

- **A real cadence, written down and with an owner.** The usual thing here is "we patch when there is an outage",
  which means every two years. Set: AIX → one TL a year and the current SP; Solaris → every quarterly CPU
  onto a new BE; HP-UX → **there are no patches: that is why you have to isolate** (§7).
- **Historical accounts.** Users of people who left, application accounts with a shared
  password and `sudo`/`root` handed out with no record. Inventory, a named owner per service
  account and removal of the rest: **an account without an owner is disabled, not documented.** Centralised
  authentication against the corporate identity provider where the system supports it — the point
  of contact with `identity-access-management-standards`.
- **Trust without authentication**: `.rhosts`, `hosts.equiv`, cleartext rsh/rlogin/telnet/FTP and NIS
  still exist in these estates. All out; SSH with a key and **no direct `root` login**.
  And **crypto frozen with the system**: verify which algorithms it actually negotiates, not which version
  it claims to have.
- **Audit exported off the machine** (`errpt`, `audit`, remote syslog). If the records
  only live on the host you are trying to protect, there is no forensic evidence.
- **When there is no patch, the control is the network**: segmentation, access only through a bastion and egress
  filtering. It is the right answer for HP-UX and for any out-of-support system.

## 6. Contracts, spare parts and the extended-support trap

- **Paid extended support is a decision that renews itself.** You sign "one more year" with
  the migration promised for the next one, and after five years the accumulated cost exceeds that of the
  project you were avoiding. Rule: **every renewal requires an explicit comparison against the cost
  of leaving, in writing and with a decision date**; if there is none, it is not signed.
- **The real risk is usually not the software: it is the part** (power supply, array, tape, a discontinued
  SAS disk, **the HMC itself**). Verify by contract the coverage, the replacement time and whether the
  spare is new or grey market: **software support on hardware with no spare parts is
  fictitious coverage**. Have on top of that a "the hardware died today" plan —emulation, a cold machine or
  a managed service—; without it, the real RTO is "however long eBay takes".
- **Usual migration pattern**, in order of increasing friction: (1) **Linux on the same
  Power** if you come from AIX and the application allows it —it preserves the hardware investment—; (2) to
  **x86** (Linux) by rewriting or recompiling, which is where the real work of
  *endianness*, toolchains and vendor dependencies appears; (3) to a **managed
  platform** (including Power as a cloud service) when what you want off your hands is
  the hardware, not the operating system. Solaris adds a specific fourth route: **x86 with
  Solaris 11.4 or an illumos derivative**, which keeps zones and ZFS.

## 7. Freeze, isolate or migrate — and prohibitions

**Freezing and isolating is the right decision when** the application is stable and subject to no change, the
migration costs more than the value the system delivers, and **you can reduce its exposure to almost
zero**: no access from the internet, in its own segment with ingress **and egress** filtering,
human access only through a bastion with logging, integrations reduced to an explicit list, a tested
restorable image and **a review date in the calendar**. Freezing is an active security posture
with an owner, not ceasing to touch the machine.

**Migrating rather than freezing when** the system is exposed to uncontrolled networks, processes regulated
data with a patching obligation, or **the hardware no longer has guaranteed spare parts**. On HP-UX,
by default, it is this.

**Prohibitions:**

- ❌ **FORBIDDEN** to leave an unsupported system reachable from the flat corporate network or from
  the internet. Without a patch there is no technical control: the control is segmentation.
- ❌ Treating HP-UX mature product support (until 2028) as if it included security
  patches. **It does not include sustaining engineering.**
- ❌ Renewing paid extended support without the written comparison against the cost of leaving (§6).
- ❌ Signing software support on hardware whose spare parts are not covered by contract.
- ❌ Applying a Solaris SRU without a new **boot environment**, or an AIX TL without a recent `mksysb`
  and a tested rollback.
- ❌ Letting AIX's **UAK**/SWMA expire: it blocks the very ability to patch (§3.1).
- ❌ Upgrading to Power11 without first checking the HMC and VIOS level (§2).
- ❌ A single VIOS without a pair in a production LPAR.
- ❌ Cleartext `rsh`/`rlogin`/`telnet`/FTP, `.rhosts`, `hosts.equiv` or NIS. Service accounts without
  a named owner.
- ❌ Production changes made only through `smit`/`sam` without recording the equivalent command.
- ❌ Planning the migration without having first done the §4 inventory — including the year-end
  close cycle.
- ❌ Presenting an illumos derivative as a replacement for Solaris when the reason for staying was
  vendor certification (§3.2).
- ❌ Extrapolating criteria between these three platforms, or from IBM i: they are in different phases.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web —and with a **verbatim quote**, not with an
automated summary:

1. **AIX**: current TL and SP and their *End of Fix Support* dates; minimum HMC, VIOS and
   firmware level for your Power generation. **Declared gap: the official end-of-support (EOS) date
   for the AIX 7.2 and 7.3 releases was not verified as of Aug 2026** — IBM does not publish it until it has
   passed and `ibm.com` rejects automated retrieval (HTTP 403). Look it up on IBM's
   lifecycle page before citing it; **third-party aggregator dates are no good**.
2. **Solaris**: Premier/Extended/Sustaining dates in the *Oracle Lifetime Support
   Policy — Oracle and Sun System Software and Operating Systems* document, and the current SRU. **Declared
   partial verification: Oracle's PDF was not automatically retrievable**; the §2 dates
   come from search and specialist press. Confirm them in the PDF before backing a
   contractual decision.
3. **Solaris SRU cadence**: it changed in Apr 2026 to two deliveries per quarter. Verify whether it has
   changed again before planning annual patching windows.
4. **HP-UX**: status in HPE's support matrix. The two quotes in §2 are taken verbatim
   from press coverage of 5-Jan-2026; contrast them against HPE's official matrix.
5. **Hardware**: end-of-life and end-of-support dates for the specific model (not for the family) and
   **real availability of spare parts**, including the HMC. Fujitsu SPARC M12 and Oracle M8/T8 have
   different calendars from each other.
6. **illumos and derivatives**: the OmniOS calendar (verified verbatim on `omnios.org/schedule`:
   r151058 until 2027-05-03, LTS r151054 until 2028-05-01) and SmartOS activity. **Declared
   gap: the exact licence of SmartOS/Triton was not verified by reading the raw `LICENSE`**;
   the "CDDL or MPL 2.0" claim comes from the 2022 handover announcement to MNX. **Read it raw
   in the repository before pinning it — and do not take at face value the licence label shown by
   GitHub.**
7. **Prices**: neither IBM, nor Oracle, nor HPE publish extended support rates. **No monetary
   figure in §6 must come from here**: it comes from your quote.
8. **CVEs** of the ported components (OpenSSH, OpenSSL, Java and Python stacks) in their version
   *packaged by the vendor*, which does not match the upstream one.

If the web contradicts this document, **the web wins** — flag the discrepancy.
