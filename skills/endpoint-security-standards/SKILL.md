---
name: endpoint-security-standards
description: Defending the endpoint as a control, and measuring whether the control is actually there. Use when selecting or operating an EDR/XDR agent (Microsoft Defender for Endpoint, CrowdStrike Falcon, SentinelOne, Elastic Defend) and deciding what to demand of it in a bake-off, weighing signature antivirus against behavioural telemetry, deploying application control with App Control for Business / WDAC versus AppLocker and its MSRC servicing-criteria gap, WDAC policy in audit versus enforced mode and managed installer, Attack Surface Reduction rules, LSA protection and Credential Guard, disk encryption posture with BitLocker TPM-only versus TPM+PIN, manage-bde protectors and recovery-key escrow, UEFI Secure Boot, Measured Boot and TPM PCR attestation, endpoint patch and third-party update coverage, EDR sensors on Linux (eBPF sensor versus loadable kernel module) and on macOS (Apple Endpoint Security API ceilings), the security agent itself as attack surface and as an availability risk after the July 2024 CrowdStrike Channel File 291 incident, Microsoft's Windows Endpoint Security Platform and the MVI move out of kernel mode, defensive awareness of BYOVD and userland unhooking, BYOD and MDM enrolment posture, endpoint DLP and why it leaks, or reporting real fleet agent coverage instead of licences purchased.
---

# Endpoint security standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **defending the endpoint and measuring it**: choosing an EDR/XDR and the real demands placed on it,
the ceiling of signature antivirus, application control, disk encryption and custody of the
recovery key, secure and measured boot and attestation, patching the endpoint and third-party
software, hardening local credentials, agent coverage on Linux and
macOS and its real limits, **the agent itself as attack surface and as an availability
risk**, BYOD and MDM policy, endpoint DLP, and the metrics that matter.

Triggers: EDR, XDR, MDE/Defender for Endpoint, Falcon, SentinelOne, Elastic Defend,
`WDAC`/App Control for Business, `AppLocker`, `CIPolicy`/`.cip`, ASR rules, Credential Guard,
LSA protection, `manage-bde`, BitLocker TPM+PIN, recovery key, Secure Boot, Measured
Boot, PCR, attestation, eBPF sensor vs kernel module, Apple Endpoint Security API,
BYOVD, *unhooking*, MDM, BYOD, endpoint DLP, "agent coverage".

**Strictly defensive posture.** Evasion techniques are described **to detect them
and to evaluate products**, never as a procedure.

**Not applicable**: see `detection-engineering-standards` (**the detection rule and its engineering
are theirs, without exception**: Sigma, SIEM content, normalisation, coverage, detection
tests. **Here the sensor that produces the telemetry and whether it is deployed**; there what is done
with it), `soc-operations-standards` (shift, queue, triage and closure of the alert your
agent generates), `incident-response-forensics-standards` (**the already-confirmed compromise**:
containment, acquisition, timeline, reconstruction — here only isolation as a
**capability** demanded of the product and rehearsed), `macos-fleet-standards` (**the Apple
fleet is theirs**: ABM/ADE, MDM and DDM, profiles, TCC/PPPC, Gatekeeper, XProtect, FileVault
escrow, system extensions. **Here only what can and cannot be demanded of a third-party EDR on
macOS, and why**), `developer-workstation-standards` (**the workstation of whoever
writes code**: dotfiles, provisioning as code, editor supply chain, keys in
hardware — **real boundary: a badly built endpoint policy breaks development
tools**, and it is negotiated by naming both sides), `linux-hardening-standards` (**the
Linux system baseline**: CIS/STIG, `sysctl`, auditd, SSH, mounts, LUKS with unattended
unlock, measurement with OpenSCAP/Lynis — here only the **EDR sensor** on that host and its
limits), `windows-server-ad-standards` (the server, the directory, Tier 0/PAW, LAPS and
gMSA), `container-runtime-security-standards` (**the container and the escape**: seccomp,
capabilities, Falco/Tetragon, drift — an endpoint EDR does not cover that),
`vulnerability-management-standards` (CVE triage and remediation SLA; here only the
**capability to deploy** the patch and its coverage), `identity-access-management-standards`
(IdP, MFA, sessions), `cryptography-pki-standards` (algorithms, modes, KMS and key life
cycle; here only the disk encryption **posture**), `privacy-engineering-standards` (personal
data, minimisation and classification that DLP presupposes), `grc-compliance-standards`
(control framework and evidence), `email-security-standards` (email as an entry channel),
`mobile-standards` (iOS/Android as an application platform),
`ot-ics-security-standards` (**sister skill**: the industrial endpoint that **takes no
agent** and why), `offensive-security-standards` (offensive exercise with written scope and
authorisation; this skill does not run it), `threat-intelligence-standards`.

## 2. Default decisions

> Verify version, exact feature name and dates on the web before pinning them
> (§8). Microsoft has **renamed** several of these and the documentation is out of step.

| Need | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Endpoint detection | **EDR with process telemetry and remote response**, with measured retention | Managed AV + telemetry to SIEM in small fleets | Signature-only AV as the sole defence |
| Application control (Windows) | **App Control for Business (WDAC)** | AppLocker only as a convenience layer or where WDAC does not reach | **AppLocker as a security boundary** (§3) |
| App control rollout | **Audit first, measured, then enforced** by rings | Direct enforcement only on fixed-purpose machines (kiosk, till, EWS) | Moving the whole fleet to *enforce* at once |
| Disk encryption (Windows) | **BitLocker with TPM+PIN** on laptops and machines that leave the premises | TPM-only **only** if the machine never leaves a controlled zone and there is physical control | TPM-only on a laptop; recovery key without escrow |
| Boot | **UEFI Secure Boot active + Measured Boot** and PCRs reviewed | — | Secure Boot disabled "because a driver won't load" |
| Sensor on Linux | **eBPF** with a verified kernel version floor | Kernel module only if the kernel is too old and with an exit plan | Proprietary module on kernels the vendor does not validate |
| Sensor on macOS | Agent on **Apple Endpoint Security** (+ NetworkExtension) | — | A product that still depends on *kexts* and demands lowering boot security |
| Agent update | **Rings + staged rollout of the content**, not just of the binary | — | Simultaneous *n-0* content update across the whole fleet (§5) |
| Coverage metric | **% of inventory assets with a healthy agent reporting in the last 24 h** | — | Counting purchased licences or installed consoles |

## 3. Application control: the difference that decides

- **Hard fact, and it is the one almost nobody quotes correctly**: Microsoft documents that **App Control for
  Business (formerly WDAC)** *"was designed as a security feature under the servicing criteria
  defined by the Microsoft Security Response Center (MSRC)"*, whereas **AppLocker**
  *"doesn't meet the servicing criteria for being a security feature"*.
  **Operational consequence**: an AppLocker *bypass* **is not necessarily** a
  vulnerability that MSRC patches; an App Control one is. That is why AppLocker **cannot be your
  security boundary**: it serves as a hygiene layer, not as a control you depend on.
  Microsoft explicitly recommends WDAC/App Control to anyone who can implement it, and AppLocker
  **only receives security fixes, not functional improvements**.
- Nuances to know before designing: the App Control policy applies **to the whole
  machine** (not per user; AppLocker does distinguish users and groups); its rules are based on
  signing certificate attributes, signed binary metadata or hash, **with no path rule**
  (AppLocker does have one, and that is why it is easier to bypass); and **some App Control
  features use AppLocker underneath** — notably the *managed
  installer*. They are not clean alternatives, they overlap.
- The name changed (**WDAC → App Control for Business**) and Microsoft's documentation is
  not synchronised across pages: the FAQ tends to be more up to date than the overview pages.
  **Verify the current name and behaviour before writing a policy (§8).**
- Rollout rule: **audit → measure the noise → named exceptions with an owner →
  enforce by rings**. An application control policy deployed in *enforce* without an
  audit phase is a self-inflicted availability incident, and it gets rolled back in a panic
  — which is exactly how these projects die.

## 4. Encryption, boot and local credentials

- **BitLocker in TPM-only mode releases the key with no user intervention**, and that key
  travels over a bus (LPC or SPI) that can be **sniffed with a cheap logic analyser**,
  with the machine powered off and physical access. It has been demonstrated on corporate laptops from
  several manufacturers in minutes. The mitigation documented by Microsoft is the
  **TPM+PIN** protector (pre-boot authentication): the key does not come out until the user enters
  the PIN, and the TPM's anti-*hammering* slows brute force.
- **Windows 11 24H2 enables device encryption by default** on a clean install with a
  Microsoft account, and the hardware requirements were relaxed (HSTI and Modern
  Standby were dropped). **Side effect that has to be accepted: the estate of *TPM-only*
  BitLocker volumes has exploded**, because the OOBE does not ask for a PIN. "Encryption on" in a report
  says nothing unless it says **with which protector**.
- Honest limit: the cold boot attack exploits DRAM remanence and **no protector
  stops it**; and there is research aimed at TPM+PIN configurations too.
  TPM+PIN raises the bar, it does not close it. For laptops: hibernate, do not suspend.
- **Custody of the recovery key is part of the control, not an extra**: escrow in the
  directory or in the MDM, with audited access and **tested restore**. A key that only
  lives in the user's personal account is not custody; it is pending data loss.
- **Secure Boot + Measured Boot + attestation**: measured boot records hashes in the TPM's PCRs
  and allows the state to be **remotely attested** before granting access to resources. It is
  the only control that answers "did this machine boot what I think it did?" — and the one that makes
  disabling Secure Boot stop being free. Verify what attestation your MDM
  or your conditional access service really supports before promising it.
- Local credentials: local administrator password **unique and rotated** by a management
  tool, LSA protection and Credential Guard where the hardware allows, and no secret
  in deployment scripts. A compromised endpoint with a reused credential turns one
  machine into the whole fleet.

## 5. The EDR as attack surface and as an availability risk

- **The case that must be cited with data, not with anecdote — CrowdStrike, 19-Jul-2024**:
  - **04:09 UTC**: a sensor configuration update is published (**Channel File
    291**). **05:27 UTC**: identified and reverted — **79 minutes**. The damage was already done.
  - Scope: **Microsoft estimated 8.5 million Windows devices affected, less than 1 %
    of the estate**. Flights cancelled, emergency services down, hospitals stopped.
  - Root cause (CrowdStrike's public RCA, Aug-2024): a new **Template Type** for IPC
    defined **21 input fields** while the code invoking the *Content Interpreter*
    supplied **20 values**. The mismatch got through several validation layers because in testing the
    21st field matched a **wildcard**. On 19 July an instance was deployed with a
    **non-wildcard** criterion for that 21st field → **out-of-bounds read** → BSOD.
  - Recovery cost: each machine required **manual boot into safe mode or WinRE**
    to delete the file. Without physical or out-of-band remote access, there was no fix.
  - **It was not exploitable**: the analysis itself and a third-party review confirmed it; the
    out-of-bounds read does not allow writing arbitrary memory nor controlling execution.
  - **Lessons that are yours, not the vendor's**: (1) **detection content is
    deployed as code**, with rings and a window — demand from your vendor staged rollout control
    of the **content**, not just of the sensor; (2) the EDR is a **platform-level availability**
    dependency, and it must be in your BIA; (3) have a **rehearsed**
    procedure for mass recovery with no network and with disk encryption on —
    that is where custody of the recovery key stops being bureaucracy.
- **Structural industry shift**: after the incident Microsoft launched the **Windows
  Resiliency Initiative** and a **Windows Endpoint Security Platform** allowing partners in
  the **MVI** programme to run antivirus and EDR **outside the kernel**, in user mode.
  Private preview announced for partners (CrowdStrike, Bitdefender, ESET, Trend Micro,
  SentinelOne, Trellix, WithSecure and others) from mid-2025. **As of August 2026
  it was still work in progress, not a general product — verify the status before
  planning on it (§8)**, and do not assume that "outside the kernel" means zero privileged
  access: the proposal grants part of that access, it does not remove it.
- **The agent widens your surface**: it runs with maximum privilege, on every machine, with
  an update channel that executes third-party content. Treat it as such: track its
  CVEs with the same priority as the operating system, restrict who can uninstall it or
  put it in *bypass* mode from the console (**the EDR console is a Tier 0 target**),
  demand MFA and audit logging on that console, and separate administration from investigation.
- **Evasion, described to detect it and to evaluate products — no cookbook**:
  - **BYOVD** (*bring your own vulnerable driver*): the attacker brings a **signed and
    legitimate** but vulnerable driver to get kernel execution and blind the agent. Defence:
    vulnerable driver blocklists applied and **verified** (not merely enabled),
    hypervisor-enforced code integrity where the hardware allows, and an alert on unusual driver
    loads. Purchasing question: *does your product survive the loading of a known vulnerable
    driver, and will you demonstrate it to me in the pilot?*
  - **Unhooking** in user space: the malware restores the functions the agent had
    hooked, blinding it without touching the kernel. It is the reason why **telemetry
    that comes only from user-mode *hooks* is not trustworthy**; demand from the vendor telemetry from
    sources the attacked process does not control.
  - Derived evaluation rule: in a *bake-off*, the question is not "does it detect this sample?"
    but **"what happens when the attacker attacks the agent?"** and **"what remains logged
    when the agent fails?"**.

## 6. Real coverage: Linux, macOS, BYOD and the metric that matters

- **Linux**: the modern sensor is **eBPF** (verified in the kernel, no module, updatable
  without a reboot; Defender for Endpoint on Linux uses it by default from its corresponding
  agent version). Limits to check **before** promising coverage: **kernel version
  floor** (Falco asks for 5.8 minimum, 5.15+ recommended), **incompatibilities with specific
  distributions and kernels** (there are documented builds that hang with eBPF enabled), and
  the fact that **the eBPF verifier is itself attack surface** — range-tracking flaws have been
  found in it on older kernels. In a heterogeneous estate,
  the heterogeneity **is** the coverage gap.
- **macOS**: the agent lives **in user space** on top of the **Endpoint Security** API
  (plus NetworkExtension), and there are hard ceilings there: **the ES API does not deliver network events**
  (separate sensors are needed), **Apple rate-limits events** to protect
  performance, the **unified log requires a private *entitlement*** that EDRs do not have,
  and installation **cannot be silent** (system extension approval, network
  filter, permissions). Consequence: **a cross-platform EDR does not see the same on macOS as on
  Windows**, and anyone telling you otherwise has not read the API. A product that still depends on
  *kexts* and demands reducing boot security: **discarded**.
- **BYOD**: decide **beforehand** between device management (full MDM) and management only of the
  application/data. If the device is personal, demanding a full agent is both a
  legal problem and a promise that is not kept. Defensible posture: conditional access based on
  **verifiable device state**, a separate work container, and **no access to
  sensitive data from an unmanaged machine**. Anything in between is theatre.
- **Windows 10 reached end of support on 14-Oct-2025.** The **consumer ESU programme was extended
  to 12-Oct-2027** (announced discreetly in the documentation, contradicting the
  "October 2026" that almost everyone repeats; in the EEA it was made free under regulatory
  pressure). **Verify the terms and calendar of the commercial ESU separately
  (§8)**: they are neither the same programme nor the same deadline.
- **Endpoint DLP fails, and that has to be said before buying it**: it depends on classifying
  the data properly (which is almost never done), it does not see inside encrypted channels it does not
  intercept, it is sidestepped with screenshots, phone photos, the clipboard, transformed
  formats and new channels every quarter, and it generates a volume of false positives that
  ends up in permanent "audit only" mode. Defensible use: **detection of accidental leakage and
  deterrence with evidence**, not prevention of a motivated insider. If the use case is the
  insider, the answer is access control and data minimisation, not an agent.
- **The metric**: **real fleet coverage**, defined as *assets in the authoritative
  inventory with an agent installed, healthy and reporting in the last 24 h*. Purchased licences
  and machines in the console are not coverage: the gap is exactly the difference
  between the inventory and the console, and that is where the attacker gets in. Supporting metrics: % with
  encryption **and the correct protector**, % with application control in *enforce*, median
  days to patch deployed, and **% of agents in degraded or *bypass* mode**.

## 7. Sustainability and prohibitions

- **Cadence**: quarterly review of coverage and of exceptions; annual review of the product
  against what was demanded of it at purchase (not against the quadrant of the day); annual exercise of
  **mass recovery** and of **host isolation** — containment capability is rehearsed
  or it does not exist.
- Every scan exclusion (path, process, extension) carries an **owner, a reason and a review
  date**. Exclusions are security debt and they grow by themselves.
- Operating system end of support **planned with a budget**, not discovered the month
  before. A machine out of support without ESU is a signed risk acceptance, not a
  "pending item".

**FORBIDDEN**
- ❌ Presenting **purchased licences or machines in the console** as fleet coverage.
- ❌ Treating **AppLocker as a security boundary**: it does not meet MSRC's servicing criteria
  for a security feature.
- ❌ Deploying application control in *enforce* without a measured audit phase.
- ❌ **BitLocker TPM-only on machines that leave the premises**, or encryption without tested custody
  of the recovery key.
- ❌ Disabling Secure Boot so that a driver loads; using products that demand reducing
  boot security on macOS.
- ❌ Broad EDR exclusions (`C:\`, `*.exe`, user folders) or excluding for the convenience of
  the development team without a written agreement with that team.
- ❌ EDR console without MFA, without auditing, or with uninstall/*bypass* permission handed around.
- ❌ Accepting vendor **content** updates without staged rollout control,
  and not having a rehearsed mass recovery procedure.
- ❌ Selling endpoint DLP as prevention against a motivated insider.
- ❌ Demanding a full agent on a personal device as a substitute for a real BYOD policy.
- ❌ **Publishing evasion procedures, loaders, specific vulnerable drivers or
  ready-made bypasses for a product.** This skill is methodology, purchasing criteria and
  detection; offensive work goes with written scope and authorisation
  (`offensive-security-standards`).

## 8. Mandatory web verification

Before pinning a product, feature name, version or date in a deliverable:

1. **Current name and behaviour** on Microsoft Learn for App Control for Business/WDAC and
   AppLocker (the FAQ tends to be ahead of the overview pages), and the **MSRC servicing
   criteria** sentence quoted **verbatim**.
2. **BitLocker countermeasures guidance** (TPM-only vs TPM+PIN, DMA, cold boot) and the
   default behaviour of the Windows version you deploy.
3. **Windows Endpoint Security Platform / MVI**: real status (private preview, general or
   product), partners and what runs outside the kernel.
4. **Life cycle**: end of support of your Windows/macOS/distribution version, and
   terms and calendar of **consumer ESU and commercial ESU separately**.
5. **Your EDR**: minimum supported version, open agent CVEs, kernel requirements of the
   eBPF sensor per distribution, and which events it really delivers on macOS.
6. **Vulnerable driver blocklists**: current version, how it is distributed and how you
   verify it is applied (not merely enabled).
7. **Independent evaluation results** (MITRE ATT&CK Evaluations, AV-Comparatives,
   AV-TEST) from the **most recent** round, and read as data, not as a ranking — the
   vendor's interpretation is not the result.

If the web contradicts this document, **the web wins** — flag the discrepancy.
