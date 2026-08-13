---
name: macos-fleet-standards
description: Managing a fleet of corporate Macs — enrollment, MDM, compliance and lifecycle, not using one Mac. Use when working with Apple Business Manager or Apple School Manager, Automated Device Enrollment (ADE/DEP), supervision, MDM enrollment profiles and .mobileconfig payloads, declarative device management (DDM) declarations, activations, assets and status subscriptions, software update enforcement declarations, Jamf Pro or Jamf Connect, Kandji, Mosyle, Addigy, Workspace ONE, Intune for macOS, NanoMDM, MicroMDM, KMFDDM or NanoHUB, APNs push certificates and MDM server tokens, kernel extensions versus system extensions (DriverKit, NetworkExtension, EndpointSecurity, kmutil, systemextensionsctl), FileVault with personal or institutional recovery keys, escrow and bootstrap token, secure token, volume ownership, Secure Enclave, SIP (csrutil), Gatekeeper, notarization, spctl, XProtect and XProtect Remediator, TCC and PPPC configuration profiles, Platform SSO with Entra ID or Okta, Munki, Installomator, AutoPkg, Homebrew on a corporate Mac, productbuild/pkgutil and signed or notarized .pkg installers, profiles(1), sudo mdmclient, softwareupdate, or the CIS macOS Benchmark and the macOS Security Compliance Project (mSCP).
---

# Corporate macOS fleet standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**This is about managing a fleet of corporate Macs, not about using a Mac.** The difference is
everything: a Mac well configured by its owner is a problem solved once; a fleet is a
problem of **device ownership, enrolment, declared state, evidence and lifecycle**,
where nothing that depends on somebody doing something right on their own machine counts as a control.

The three statements that order everything else:

1. **A fleet without automated enrolment (ADE) is not a fleet you control**: with no supervision,
   with the management profile **removable by the user** and with no guarantee of re-enrolment
   after a wipe, it is a device you trust voluntarily.
2. **The current model is declarative (DDM), not command-based**: the old routes **have already stopped
   working** in the 27 cycle (§2).
3. **What breaks automation on macOS is consent (TCC)**, not a lack of
   tools: whatever is not pre-configured by MDM ends up in a dialogue somebody has to
   click — and in a fleet that means it does not happen.

**Not applicable**:
- `developer-workstation-standards` (**already written — a critical boundary**): **theirs is the machine of one
  person who writes code** (environment, personal hardening, provisioning as code,
  local credentials); **here the corporate fleet** (enrolment, MDM, baseline, compliance,
  asset lifecycle). **Two different problems on the same hardware, and both have to be
  solved**: if the development machine is provisioned outside the fleet you have an unmanaged
  machine; if the fleet leaves no room for what that skill decides, you have somebody working on their
  personal laptop. **Neither rules over the other.**
- `mobile-standards` (**already written**): **theirs are iOS and iPadOS as an application platform**;
  **here device management** (ABM, ADE, MDM, DDM), common to every Apple platform.
- `identity-access-management-standards` (**already written**): **theirs is the identity provider**
  (federation, MFA, account lifecycle); **here only how the machine's sign-in consumes it**
  (Platform SSO, §5).
- `grc-compliance-standards` (**theirs are the control framework and evidence**; here the technical baseline that
  produces it), `detection-engineering-standards` (**theirs is endpoint detection and its
  rules**), `endpoint-security-standards` (**theirs is the endpoint protection product**: the third-party
  EDR, its requirement and its measurement, and **the fleet-wide posture of the encryption enforcer** — what
  is required and how it is measured; here the MDM profile that applies it and escrows the FileVault key —),
  `secrets-management-standards`, `vulnerability-management-standards`.
- `onprem-standards` (**the platform umbrella with the routing table**), `homelab-standards`,
  `linux-administration-standards`, `rhel-fedora-standards`, `linux-hardening-standards`,
  `linux-storage-standards` and `zfs-standards` (**already written: Linux and ZFS are theirs**),
  `firewall-policy-standards`, `networking-standards`, `iac-standards`,
  `os-provisioning-standards`, `server-hardware-standards`, `backup-recovery-standards`,
  `bcdr-standards`, `ha-clustering-standards`, `legacy-modernization-standards`,
  `migration-projects-standards`.
- `aix-solaris-hpux-standards` and `bsd-systems-standards`: **macOS is not a server fleet** and
  **BSD is not proprietary Unix**. The "Unix" surname lumps the three together and they share almost nothing
  operationally: here the managed object is a **workstation with a human owner**.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criterion | Verified note |
|---|---|---|
| Device ownership | **Every corporate Mac bought through Apple Business Manager (or School Manager) and assigned to the MDM server before being handed over** | It is what makes enrolment **automated and non-removable** |
| Enrolment | **ADE mandatory**; user enrolment only for BYOD, with reduced expectations | Without ADE there is no supervision and no guarantee of re-enrolment |
| Management model | **DDM by default**; the classic MDM command only where there is no equivalent declaration | Apple, WWDC26, literally: *"Legacy software update management no longer functions in all 27.0 operating systems. This includes: Software update commands, Software update queries, Recommended cadence settings, Software update restrictions, like deferrals and Background Security Improvements"* |
| Target version | The **macOS 26 (Tahoe)** line in production; **macOS 27** in the cycle Apple announced for 2026 (§8) | macOS 26 is **the last version compatible with Intel Macs**: that turns the Intel estate into a retirement plan with a date, not a preference |
| Updates | **A DDM declaration with a target version and a deadline** | It is what replaces deferrals and commands. Indefinite postponement is no longer a technical option |
| Commercial MDM | **Jamf Pro, Kandji or Mosyle** depending on size and the automation needed; Intune if the organisation already lives in Microsoft and accepts its lesser macOS coverage | **Pricing: not verified against official rate cards — declared gap (§8).** They all charge per device/month with purchase minimums and tiers; ask for it in writing |
| Open source MDM | **NanoMDM** — **MIT** licence (verified by reading the raw `LICENSE` of `micromdm/nanomdm`). Only with in-house engineering capacity | **MicroMDM v1 went into maintenance in Jun 2025**; NanoMDM is the active successor. **It is not a product**: no interface, no catalogue, no support. APNs, TLS, availability and on-call are yours, and below a certain scale **it costs more than the subscription** |
| Extensions, encryption, identity and baseline | System extensions only (§3.3); FileVault enforced with the key and bootstrap token escrowed (§5); **Platform SSO** against the corporate provider (§5); **mSCP** as the baseline generator (§4) | A *kernel extension* requirement is grounds for rejecting the vendor |

## 3. Structure and conventions

### 3.1 Enrolment and ownership
- **The Mac enters ABM before it reaches anybody's desk**: purchase through a channel that feeds ABM,
  assignment to the MDM and the enrolment profile ready before unboxing. Buying retail to
  "solve it quickly" creates permanent debt — **adding to ADE afterwards is only possible through
  limited routes and with deadlines**.
- **Supervised versus unsupervised is not a nuance**: supervision (which arrives with ADE) is what
  enables non-removable management, additional restrictions and control of Activation
  Lock. An unsupervised Mac is managed **with its user's permission**.
- **BYOD is a different product** (user enrolment, corporate data only, **no expectation of machine
  compliance**). And at offboarding: release Activation Lock and **remove the device from ABM** —
  a Mac sold without release is a brick for the buyer.

### 3.2 MDM: the protocol and its limits
Apple's MDM is **a command queue delivered by push notification**: the server asks, the
device answers when it can. **It is not remote execution**: no guaranteed order, no guaranteed
time, no shell. DDM changes the model — declared desired state, applied and reported by the
device — but not that. Consequence: whatever cannot be expressed as a profile or a declaration needs an
**agent**, and the more your operation depends on the agent, the worse it ages with each macOS version.
**What Apple knows how to do declaratively is done declaratively.**

**Choosing an MDM**, in order: (1) real DDM coverage and **the speed of support for the new macOS
version each September** — the criterion that hurts most when it fails —; (2) what it automates without
programming; (3) API and management as code; (4) price with minimums and tiers; (5) exit: how you
take your inventory with you and how you migrate enrolment.

### 3.3 The end of kernel extensions
- Replaced by **system extensions** in user space: DriverKit (devices),
  NetworkExtension (networking and VPN), EndpointSecurity (security). On Apple Silicon, loading a kext requires
  **lowering the boot policy to "Reduced Security"** and approving on the machine: degrading secure
  boot for the whole machine and touching it physically.
- **Purchasing rule**: if a product requires a kext, **it is ruled out**, and that is stated in the tender, not
  when it is discovered during deployment. What usually breaks: old antivirus products, legacy VPNs,
  virtualisation, low-level backup and specialised peripherals.
- System extensions are **pre-approved by MDM**; otherwise the installation ends in a dialogue
  nobody should have to interpret.

### 3.4 Updates
- **The current mechanism is the DDM declaration with a target version and a deadline**; commands,
  queries, restrictions and deferrals **no longer work in the 27 cycle** (§2, Apple's literal
  quote). If your patching policy rested on deferrals, **it is already broken** even though nobody has
  warned you: the commands are sent and the device ignores them.
- **Delaying updates on macOS is more expensive than on Windows**: (a) **one major version a year**
  concentrates features and management changes; (b) security fixes are **coupled to the system
  version**, browser included, with no decoupled patch; (c) **new hardware arrives with the new
  version and cannot be downgraded**, so falling behind fragments the estate by
  purchase date; (d) support for earlier versions is short and uneven. **The only sustainable
  policy is adopting the major version within the year**, in rings: IT → volunteers → a representative
  pilot (with development machines and unusual peripherals) → the rest, with a deadline on each
  one.

### 3.5 Applications and packages
- **All corporate software comes from a catalogue**: ABM purchases and **signed and
  notarised in-house packages** (Munki for a real catalogue independent of the MDM; **Installomator** to install
  and update by downloading from the vendor). An unsigned `.pkg` installed by bypassing Gatekeeper teaches
  the workforce exactly the behaviour an attacker needs.
- **Homebrew installs in the user's space and outside the management chain**: the MDM does not see it,
  it does not go through your catalogue, it updates at each person's discretion and its provenance is community-based.
  **It is not a corporate software manager.** It is legitimate and often necessary on a **development
  machine** — a `developer-workstation-standards` decision — and then it is declared: which machines,
  which inventory, which accepted risk. What is vetoed is the corporate tool arriving that way.

## 4. Compliance and evidence

- **The baseline is generated, not hand-written.** The **macOS Security Compliance Project**
  (the technical implementation of **NIST SP 800-219**) produces, from the chosen baseline (CIS
  Level 1/2, 800-53, 800-171, STIG, CMMC), **profiles, checking and remediation scripts and
  audit documentation**: the control, the setting and the evidence come from the same place. **The CIS Benchmark
  for macOS** is covered there — do not maintain two sources of truth. **Work on the branch for
  your macOS version**, never on the main one (as of Aug 2026, *tahoe_rev2*, Dec 2025, with mSCP 2.0
  in progress — §8).
- **The evidence is the periodic check on the device, not the profile that was sent.** Report
  with **coverage** (how many machines have reported in the last N days) as well as a percentage:
  **the ones that do not report are the risk and they vanish from the average**. The control framework and the
  exceptions belong to `grc-compliance-standards`.

## 5. Platform security and identity

- **FileVault enforced and the key escrowed.** Without **verified** escrow, encryption is an
  elegant way of losing data: check that the key is in the MDM, define who can
  recover it under dual control with logging, and **rotate it after every use**. The same goes for the **bootstrap
  token and volume ownership**, which is what lets updates and certain
  management changes work without somebody typing their password: if they are missing, it shows up
  much later as "updates that do not apply".
- **SIP, Gatekeeper and full secure boot, enabled**; disabling them changes the posture of the whole
  machine. **XProtect and its remediator** up to date and verified in the inventory — they do not replace
  corporate detection (`detection-engineering-standards`, `endpoint-security-standards`).
- **TCC is the consent model and it is what breaks automation.** Full disk,
  screen recording, accessibility, camera, microphone, user folders: whatever
  your agent, your backup tool or your security product needs **is pre-granted by a PPPC profile
  before deployment**. What Apple reserves to the user is documented as a manual step in
  onboarding, not discovered in production.
- **Remote wipe and lock tested** and coordinated with **Activation Lock**: locking
  a machine whose release you do not control turns an incident into a lost asset.
- **The trap of the local password versus corporate identity.** The Mac account has
  **its own password**: the corporate policy does not apply to it and **it is not revoked when the
  account is disabled in the identity provider** — a laptop in a drawer still opens with the
  password of somebody who no longer works here. The answer is **Platform SSO**, with password
  synchronisation or a key backed by the Secure Enclave; with **macOS 26** registration happens
  **during Setup Assistant** (*Simplified Setup*) and **the first local account is created
  from the corporate identity**. **Do not stack two synchronisation mechanisms**: they conflict.
- **Nobody is a permanent local administrator**: a standard account and one-off elevation, audited and
  time-limited. The management administrative account, **with a unique per-machine password that is rotated** — one
  shared across the whole fleet is the most expensive and most frequent vulnerability in this domain.

## 6. Operation

- **Inventory with freshness** (last check-in, version, FileVault, profile coverage,
  XProtect): **a machine that has not reported for 45 days is an open incident**, not just another row.
- **September is the critical date of the year** (major version, management changes, removals): capacity is
  reserved, validating the MDM, security, VPN and in-house packages against the beta from the summer.
- **The fleet's configuration is code** (profiles, baselines, declarations, catalogue), with
  review and ring-based deployment — the how is in `iac-standards`. And a timed **rebuild test**
  of a machine from scratch: without it, replacing a lost laptop is a hypothesis.

## 7. Prohibitions

- ❌ **FORBIDDEN**: a corporate Mac **without automated enrolment (ADE)** and without supervision. It is the
  root prohibition: everything else in this document rests on it.
- ❌ **FileVault with no verified key escrow**, escrow with no control over who recovers it and no
  rotation after use, or **an unescrowed bootstrap token**.
- ❌ **Depending on a local administrator account** — the user's or one shared across the
  fleet — as a management mechanism.
- ❌ **Installing software outside the catalogue** or distributing internal packages unsigned and unnotarised.
  **Homebrew is not the corporate catalogue** (§3.5).
- ❌ Accepting a product that requires a **kernel extension**, or leaving machines in "Reduced Security"
  permanently. Disabling SIP or Gatekeeper without a written, named, expiring exception.
- ❌ Basing the update policy on **deferrals and MDM commands** (they no longer work, §2) or
  postponing the major version by more than one annual cycle.
- ❌ Deploying without **pre-granting through PPPC** the TCC permissions your tools need.
- ❌ Treating user-enrolled BYOD as a managed machine; offboarding a machine without releasing
  Activation Lock and removing it from ABM.
- ❌ Adopting an MDM without checking its **DDM** coverage and its track record of support on macOS
  launch day; or standing up NanoMDM "because it is free" with no team to sustain APNs, TLS,
  availability and on-call.
- ❌ Counting compliance as the percentage over the machines that report, ignoring those that do not
  (§4).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web — and with a **literal quote**, never with an
automatic summary:

1. **macOS versions and their support**: as of Aug 2026 macOS 26 (Tahoe) is the deployed line and
   **Apple documents changes for the 27 cycle** (iOS 27, iPadOS 27, macOS 27, tvOS 27, visionOS 27,
   watchOS 27, quoted literally in the WWDC26 device management note). **Declared
   gap: the marketing name and the exact date of macOS 27 were not verified.** Confirm
   up to which version the models in your estate receive patches.
2. **Updates and DDM**: the removal of the old mechanism is verified literally (§2).
   Check which declarations exist today and **what your specific MDM supports** — they are almost never the
   same —; DDM's scope grows every cycle and determines how much agent you need. Also verify
   the removal calendar for **kernel extensions** before accepting a product that uses them.
3. **mSCP**: the branch for your macOS version and the status of the **mSCP 2.0** redesign, ongoing during 2026.
   **Do not work from the main branch.** And the current version of the **CIS Benchmark** for macOS.
4. **MDM solutions — status, licence and price**. Verified as of Aug 2026 by reading the raw `LICENSE`:
   **NanoMDM = MIT**; **MicroMDM v1 in maintenance since Jun 2025**. **Declared gap:
   no Jamf, Kandji, Mosyle, Addigy or Intune price was verified against an official rate card** — the
   figures in circulation come from aggregators. **Do not quote prices from here: request a quote**, with
   minimums, tiers and renewal increases. A GitHub feed does not prove a project is alive.
5. **Platform SSO**: your provider's exact requirements (minimum macOS version, application,
   certificates, authentication mode) and the status of registration during Setup Assistant.
6. **Apple Business Manager**: changes to terms, federated identities and the current procedure
   for adding devices bought outside the channel.

If the web contradicts this document, **the web wins** — flag the discrepancy.
