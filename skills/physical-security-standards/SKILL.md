---
name: physical-security-standards
description: Physical security as it applies to IT assets — the controls that matter once someone can touch the hardware. Use when designing or auditing badge and biometric access control with antipassback and escort rules, handling tailgating as the failure that actually happens, managing master keys and key custody, specifying CCTV coverage, retention and its legal basis as personal data, intrusion detection and alarm response, deciding who else can reach your cage or your neighbours' racks in a colocation facility, sanitizing or destroying storage media under NIST SP 800-88 Clear/Purge/Destroy with degaussing, cryptographic erase or shredding, demanding and checking a certificate of destruction with serial numbers, responding to a lost or stolen laptop, phone or backup tape, closing off exposed USB ports, serial consoles, debug headers and live network sockets in meeting rooms and shared areas with 802.1X as a compensating control, governing visitors, cleaners, contractors and maintenance technicians, defending against in-person social engineering and pretexting, applying ISO/IEC 27001:2022 Annex A physical controls 7.1-7.14, or judging what full-disk encryption and measured boot really compensate for when an attacker has unsupervised physical access to a machine.
---

# IT asset physical security standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **the physical protection of whatever stores or processes information**: access control to
spaces and racks, keys, video surveillance, intrusion detection, custody and destruction of
media, lost or stolen devices, accessible ports and consoles, management of visitors and
of external personnel, in-person social engineering, and the threat model that decides what encryption
compensates for and what it does not.

Triggers: "access control", "proximity badge", "biometric reader", "antipassback",
"airlock", "tailgating", "slipping in behind", "master key", "key custody", "CCTV",
"video surveillance", "recording retention", "intrusion alarm", "volumetric detector",
"cage in the data centre", "colocation", "who else gets into my aisle", "secure erasure", "degaussing",
"disk destruction", "certificate of destruction", "NIST 800-88", "DIN 66399", "NAID AAA",
"stolen laptop", "lost backup tape", "USB port", "serial console", "JTAG", "network port
in the meeting room", "802.1X", "visitor log", "escorting", "maintenance
technician", "in-person impersonation", "unsupervised physical access", "evil maid",
"ISO 27001 A.7".

**Guiding principle**: **whoever has prolonged, unsupervised physical access to a machine ends up
compromising it.** That is not a catchphrase: it is the design assumption. From it follows everything that orders
this document:

1. **Encryption at rest and measured boot are compensating controls, not substitutes.**
   They reduce the damage of physical access; they do not prevent it. An encrypted, powered-off laptop is a brick;
   that same laptop suspended, with an open session or with the key unprotected, is not.
2. **The real failure is not technical, it is social.** No serious access control is defeated
   electronically: it is defeated by walking in behind someone whose hands are full. *Tailgating*
   is the dominant vector and training is the control, not the turnstile (§3.1).
3. **Physical security is the only layer that, when it falls, nullifies all the others**
   simultaneously: console, disk, network, and credentials in memory.
4. **A control without evidence does not exist.** An access log nobody reviews, a camera that
   records to a full disk and a certificate of destruction without serial numbers are documented
   theatre.

**Defensive and authorised posture.** This document describes **controls, evidence and governance**. It does not
contain lock-picking techniques, credential cloning, reader bypass or
impersonation scripts. Any physical intrusion test requires **scope and written
authorisation, with an authorisation letter in hand**, and is the territory of `offensive-security-standards`.

**Not applicable**: see `datacenter-facilities-standards` (**the physical plant is theirs, without exception** — power from the
utility feed, UPS, generator, PDU, cooling, hot/cold aisle, density per rack,
raised floor, structured cabling and **fire protection**, plus Tier/EN 50600 as
site classification. **Here, the security part**: who gets in, how it is proven, what is
recorded, what happens to the media and which port is left exposed. Arbitration rule: *if the risk is
that it goes down or burns, it is theirs; if the risk is that someone carries it off, opens it or plugs into it,
it is ours*), `server-hardware-standards` (**the server and its insides**: chassis, BMC and its management
network, firmware, warranty, RAID/HBA; here only the fact that whoever reaches the chassis reaches
those interfaces), `endpoint-security-standards` (**the endpoint as a logical control**: EDR, application
control, **disk encryption posture, secure and measured boot, attestation and custody of the
recovery key**; here, theft or loss as a physical event and what that encryption compensates for),
`privacy-engineering-standards` (**personal data as engineering**: legal basis, minimisation,
implemented retention, data subject rights; here, video surveillance and the access log
**as processing operations that must be respected**, without invading their territory — if the question is how
erasure is implemented or who the controller is, it is theirs),
`grc-compliance-standards` (**the framework and the audit evidence**: ISO 27001, SoA, ENS, risk
register; here the technical control and its operation), `identity-access-management-standards`
(logical identity, MFA, account lifecycle — **convergence between the physical credential
and the logical one is decided with them**), `identity-threat-detection-standards` (the
attack on digital identity and its detection), `windows-server-ad-standards` and
`linux-hardening-standards` (OS and console baseline), `networking-standards` and
`routing-switching-standards` (**802.1X, port-security and guest VLANs are network controls
of theirs**; here only why an accessible network socket demands them), `incident-response-forensics-standards`
(the investigation once physical access has already happened, and **the chain of custody of the evidence
—which is the same concept as that of destroyed media, applied to something else**),
`incident-management-standards` (incident governance), `backup-recovery-standards` (the copy and
its restoration; here the physical custody and transport of the media), `bcdr-standards` (loss
of the site as a continuity scenario), `ot-ics-security-standards` (industrial plant, where
physical access is governed with another risk in front: the safety of people),
`macos-fleet-standards` and `developer-workstation-standards` (the endpoint and its provisioning),
`cmdb-inventory-standards` (**the asset record and its location**: without an inventory you cannot
declare lost what you never knew existed), `vmware-standards`/`proxmox-ve-standards`
(the hypervisor), `homelab-standards` (proportionality: none of this applies literally at home).

## 2. Default decisions

> Verify exact standard names, versions and legal obligations on the web before committing to them (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Authentication in a critical zone (data centre, comms room) | **Two factors**: badge + PIN or biometrics | A single factor only in general office areas |
| Access credential | **Technology with encryption and mutual authentication**, provisioned by the same joiner-mover-leaver cycle as the account | Never a read-only identifier credential, trivial to copy |
| Zones | **Concentric**: perimeter → building → floor/office → technical room → **rack** | Fewer layers only if the asset does not justify them |
| Antipassback | **Enabled in critical zones** (you cannot re-enter without having exited) | Disabled only with written justification: it breaks the headcount in an emergency |
| Door fail mode | **Fail-safe** (opens) where life is at stake; **fail-secure** where it is not | Evacuation regulations always override security ones (§6) |
| CCTV | Coverage of **decision points** (entrances, rack aisle, loading bay), not total coverage | Fewer cameras, better placed, always |
| CCTV retention | **The minimum that meets the purpose**, and in Spain **one month as the legal maximum** (§3.3) | More only if a fact has to be substantiated before a competent authority |
| Decommissioned media | **Certified physical destruction** by default | Cryptographic erase or verifiable overwrite if the media is reused internally (§3.5) |
| SSD and flash memory | **Physical destruction**; degaussing **does not work** on flash | Cryptographic erase if the manufacturer documents it and it is verified |
| Network socket in a common area | **Disabled by default**; if enabled, **802.1X** | Isolated guest VLAN, never the production one |
| Visitors in a technical zone | **Permanent escorting**, log and a visually distinct badge | None |
| Reference framework | **ISO/IEC 27001:2022 Annex A, theme 7 (14 controls, A.7.1–A.7.14)** | ENS or CIS if the context demands it; they are mapped, not duplicated |

## 3. Structure and conventions

### 3.1 Access control: what fails is not the reader

- **Tailgating (slipping in behind someone authorised) is the dominant failure**, and it is not a failure of the
  system: it is a conflict between security and courtesy. It is tackled with **physical measures where
  it matters** (single-person passage, turnstile, airlock) and with an **explicit, blame-free rule**: "do not
  hold the door" has to be written policy backed by management, or the employee who
  applies it comes across as the rude one.
- **Antipassback** prevents reusing a credential to enter twice without exiting — it is what
  turns badge lending into a visible failure. Real trade-off: it breaks the occupant headcount
  if someone leaves through an emergency door, and you need a reset
  procedure.
- **Biometrics are not a password**: they cannot be changed when leaked. They are used as a **second
  factor**, with the template stored locally and encrypted, never as a unique or
  exportable identifier, and they are **special category data** when used to identify (boundary with
  `privacy-engineering-standards`: the legal basis is decided there, not here).
- **The physical credential's lifecycle = the account's.** The departure of an employee who returns
  the laptop but keeps the badge is the typical case. **Periodic recertification of who has
  access to critical zones**, at the same cadence as logical access.
- **Access logs**: they are retained, **they are reviewed** (out-of-hours access, access to critical zones, by
  external personnel) and they are correlated. High-value, near-zero-cost correlation: **a credential
  used in the building while the account authenticates from another country**, or **access to the room without
  an associated change ticket**.
- **Keys and master keyrings**: they are the permanent back door. Named inventory, custody
  in a deposit with a withdrawal log, **copying forbidden**, and **lock cylinder replacement on loss** —
  not "it will turn up". A master key that opens the whole building and lives in a drawer voids the rest
  of the chapter.
- **The rack is a zone**, not a piece of furniture: an effective lock, side panels fitted, doors
  closed, and **a record of who opens it**. A data centre with perfect access control and open racks
  protects the room, not the servers.

### 3.2 Colocation: who else has physical access to your cage

A question that is almost never asked and that decides the threat model in a shared facility:

- **The provider's staff have physical access to your space.** It is unavoidable (fire, fault,
  building work) and it is correct; what has to be demanded is **procedure**: who can enter without you, under what
  circumstances, with what record and with what subsequent notification. It must be in the contract, not in
  goodwill.
- **Your neighbours share the aisle.** A mesh cage with an open top is a visual barrier, not a
  physical one. If the asset justifies it: a cage with a roof, blanking panels, your own lock with your
  key and **your own camera inside the cage** (and that camera is your processing, with your
  obligations).
- **What has to be requested in writing before signing**: an access log for your space deliverable
  on demand, escorting policy, control of remote hands (*remote hands*) and what it can
  do without explicit authorisation, procedure for material entering and leaving, and right of
  audit. **"It is a Tier III facility" answers none of these questions**: that classification
  speaks about availability, not about who gets in (boundary with `datacenter-facilities-standards`).
- **Remote hands is delegated privileged access**: the provider's technician plugging a
  keyboard into your server is doing physical administration with your authorisation. It is requested over an
  authenticated channel, scoped to the task and logged.

### 3.3 CCTV, alarms and their status as personal data processing

- **Every camera serves a documented purpose** or it is removed. Coverage by accumulation is
  unlawful and useless besides: nobody reviews 60 streams.
- **Legal basis and proportionality**: under the GDPR, security video surveillance typically relies
  on legitimate interest, with a **mandatory balancing test** against the data subject's
  rights and an analysis of whether there is a less intrusive means. The **EDPB Guidelines 3/2019 on
  processing of personal data through video devices** are the European reference.
  Forbidden in areas with an expectation of privacy (changing rooms, toilets, break areas), and **video
  surveillance cannot be an instrument of generalised worker monitoring**.
- **Retention — Spain, legal text verbatim** (Ley Orgánica 3/2018, LOPDGDD, art. 22.3):
  > «Los datos serán suprimidos en el plazo máximo de **un mes** desde su captación, salvo cuando
  > hubieran de ser conservados para acreditar la comisión de actos que atenten contra la
  > integridad de personas, bienes o instalaciones. En tal caso, las imágenes deberán ser puestas a
  > disposición de la autoridad competente en un plazo máximo de setenta y dos horas desde que se
  > tuviera conocimiento de la existencia de la grabación.»

  Two details that get lost when it is quoted from memory: **the period is "one month", not "30 days"** —the
  paraphrase circulates everywhere—, and **the exception is not "keep it just in case"**, but
  retaining it to substantiate a specific fact, with delivery to the authority within 72 hours.
- **Mandatory information sign** in a visible place, with the controller and how to exercise rights.
- **Engineering consequence**: the system must **delete on its own** when the period expires. An NVR
  configured to "overwrite when full" does not meet a period, it meets a disk capacity.
- **The recorder is a server**: on the management network, patched, without default credentials,
  without Internet exposure and with its own access control. The track record of IP cameras and NVRs
  exposed is long and has not improved.
- **Alarms**: detection without a **response with a committed time** is not a control. You define
  who receives it, in how long they respond and what they do; it is tested periodically; and the **false alarm
  rate** is measured, because an alarm that goes off daily stops being attended to (the same phenomenon as
  alert fatigue in `soc-operations-standards`).
- **Sensors lie towards the comfortable side**: a magnetic contact says the door is
  closed, not that nobody has gone through. Technologies are combined in critical zones.

### 3.4 Ports, consoles and anything that can be plugged in

- **An accessible network socket in a common area is an unauthenticated connection to your internal network.**
  Default control: port administratively disabled; if it has to be active,
  **802.1X** (or, as a worse minimum, MAC *port-security*, which only stops the careless). The
  design and operation of that belong to `networking-standards`; **here, the requirement that it exist**.
- **USB ports**: the realistic policy is not "glue the ports shut", it is **software blocking of
  mass storage and of the device classes that are not needed**, with managed exceptions.
  A physical port also accepts devices that present themselves as a keyboard, and against that
  class-based blocking is the control.
- **Serial console and KVM**: they give access prior to the operating system — boot loader, firmware,
  recovery. They are treated as administrative access: on an isolated management network, with
  authentication and logging. An accessible console server is the key to the entire aisle.
- **Debug headers (JTAG/SWD) and service ports** in network equipment, cameras,
  access controllers and embedded devices: they are assumed present and protected by
  **location and tamper detection**, because disabling them is rarely in your hands.
- **Factory reset button**: on many devices it restores default credentials and wipes the
  configuration. It is a one-second physical attack and it has to be counted in the model.
- **Tamper seals and tamper evidence** on unattended or remote equipment: they prevent nothing, but
  they turn a silent access into a finding — which is exactly what is needed when you
  cannot prevent it.

### 3.5 Media: custody, erasure and destruction

Technical framework: **NIST SP 800-88 Rev. 1**, which defines three categories, verbatim from the document:

> «**Clear** applies logical techniques to sanitize data in all user-addressable storage locations
> for protection against simple non-invasive data recovery techniques […]
> **Purge** applies physical or logical techniques that render Target Data recovery infeasible
> using state of the art laboratory techniques.
> **Destroy** renders Target Data recovery infeasible using state of the art laboratory techniques
> and results in the subsequent inability to use the media for storage of data.»

How it is decided, without ambiguity:
- **Clear** is enough if the media is reused **within** the same trust environment.
- **Purge** if it leaves your control but is reused (sale, warranty return, donation).
- **Destroy** if the data classification demands it, if the media **fails** (a disk that does not
  respond cannot be overwritten or verified) or if you cannot demonstrate the result.
- **Cryptographic erase**: destroying the key of a self-encrypting drive is fast and elegant, and
  **it depends entirely on the manufacturer's encryption and key management being correct**.
  It counts as *Purge* when the manufacturer documents it and there is verification; it does not count as an act of faith.
- **Flash and SSD**: overwriting does not reach remapped blocks or over-provisioning, and
  **degaussing has no effect whatsoever on flash memory** — it is an expensive myth. Cryptographic erase
  or physical destruction.
- **Verification**: without sampling and recording the result, erasure is an intention.

**The certificate of destruction is the evidence, and it is demanded with content**: serial numbers of
each piece of media, method, date, responsible party and traceability. A certificate that says "10 disks
destroyed" without serial numbers is worthless to an auditor and, above all, **does not let you know which one
is missing**. Market references: the **NAID AAA** certification (i-SIGMA) for destruction
providers, with unannounced audits and verification of serial numbers before and after;
and the German standard **DIN 66399**, which classifies by material type and protection level (P for
paper, H for hard disks, etc.) and replaced the old DIN 32757. Criteria: **the level
is specified in the contract**, it is not left to the provider's judgement.

In addition:
- **Witnessed or recorded destruction** is the only way to close the window between "it leaves the
  building" and "it is destroyed". Transport is the weak link.
- **Chain of custody from the moment the media leaves the rack**: who removes it, where it is stored
  while it waits, who hands it over. A cupboard with disks pending destruction is a concentrated
  prize.
- **Paper and minor media count**: network diagrams, listings, notes and labels with host
  names. Secure destruction of paper is part of the same process, not an office matter.
- **Closed loop with the inventory**: the asset's decommissioning is only closed with the associated
  certificate (boundary with `cmdb-inventory-standards`).

### 3.6 Lost or stolen devices

- **Prerequisite: inventory.** Without it you cannot declare lost what you did not know existed,
  nor know what it contained.
- **Full disk encryption active and verified across the whole fleet**, with custody of the recovery
  key (encryption posture and its escrow belong to `endpoint-security-standards`; here the
  requirement that it exist before it is needed).
- **Procedure with a clock**: declare → revoke that identity's credentials and sessions (§ of
  `identity-threat-detection-standards`) → remote wipe if possible → assess whether there was personal
  data and whether notification applies (`privacy-engineering-standards` / `grc-compliance-standards`)
  → police report if applicable → removal from inventory.
- **Remote wipe is a "maybe"**: it requires the device to connect. **Encryption is the "yes"**.
  Design as if the remote wipe were never going to run.
- **Culture of immediate, blame-free reporting.** If losing a laptop costs you a telling-off, it gets
  reported the following Monday, and those hours are the ones that matter.

### 3.7 People: visitors, maintenance and in-person impersonation

- **Visitor = permanent escorting** in a technical zone, a visually distinct badge,
  a log with entry and exit times and the reason. A log that only has entries is not a
  log.
- **Cleaning and maintenance staff have, in practice, the broadest and least
  supervised access in the building**, often out of hours and through a contractor. Same screening, same minimum
  scope, same logging. Being from an external company does not reduce the risk: it spreads it.
- **A provider's technician**: **an appointment confirmed in advance through a known channel** —not through the phone number
  on their card—, identity verification, escorting and work scoped to what was agreed.
  The most effective in-person impersonation pattern is always the same: **uniform, urgency and
  authority**, and it works because stopping it looks discourteous and risky for whoever is at
  reception.
- **The control is organisational**: reception with **explicit authority and written backing to
  say no**, a phone number to call and no consequences for making someone wait.
  Training on the specific failure (holding the door, accepting the urgency, not asking for identification)
  pays off more than any general talk.
- **Clear desk and clear screen** (control A.7.7): credentials on sticky notes, open sessions and
  documents on the desk are the loot of the five-minute visit.
- **Delivery and removal of material**: nobody takes hardware out without recorded authorisation. It is the control
  that turns internal theft into a detectable event.

### 3.8 The honest threat model

Steps of physical access, with what each one grants:

| Access | What the attacker gets | What compensates (partially) |
|---|---|---|
| Sight of the screen / desk | Credentials, data, context for impersonation | Clear desk, privacy filter |
| A port or a network socket | Presence on the internal network | 802.1X, USB class blocking |
| Powered-off machine, a few minutes | Disk: nothing if it is properly encrypted | **Full encryption with a key that is not trivially derivable** |
| Machine powered on or suspended | Keys in memory, live session, DMA interfaces | Power off (do not suspend), lock, DMA protection |
| Prolonged, unsupervised access | **Persistent compromise in firmware or hardware** | Secure and measured boot, attestation, tamper evidence |

A corollary that must be said out loud to management: **against prolonged, unsupervised
physical access, there is no logical control that guarantees the machine's integrity.** From that point on
you work with **detection** (tamper evidence, boot attestation, firmware verification)
and with **reducing the value of the target** (so that the machine does not hold what it does not need).
Measured boot and encryption **raise the cost and make the attack noisy**; they do not prevent it. Anyone
selling the opposite is selling.

## 4. Verification and testing

- **Tailgating and escorting test**, with scope and written authorisation and with the
  knowledge of at least one manager: it is the test that teaches the most and the one that causes the most
  discomfort. Expected result: not "we got in", but **how many people and at what point had
  the opportunity to stop it and did not**, and what organisational change fixes it.
- **End-to-end alarm test**, timed, including the human response.
- **Recording test**: not "does it record?", but **can the recording of a
  specific incident from three weeks ago be retrieved and viewed, and can someone be identified at that quality?**
- **Audit of active credentials** against the personnel list: every badge that opens a critical
  zone with a living, current holder.
- **Key audit**: every master key located and signed for.
- **Sampling of the destruction process**: pick N assets decommissioned in the previous quarter and
  follow their trail to the serial number on a certificate. **This is where the
  holes show up**, always.
- **Quarterly physical walkthrough** looking for the mundane: wedged doors, open racks, live network
  sockets in common rooms, boxes of "pending" disks, missing signs, cameras turned or
  blocked by a new shelving unit.
- **Mapping to ISO/IEC 27001:2022 Annex A theme 7** (A.7.1–A.7.14) as a coverage
  checklist, **not as the work**: control A.7.4 (physical security monitoring) is the
  only new one in the theme in the 2022 revision and it is usually the gap.

## 5. Stack security (the physical security systems themselves)

The systems that protect the building are IT systems, and they are usually the worst managed in the
inventory:

- **Access controllers, NVRs, door entry systems and alarm panels**: on their **own segmented
  VLAN**, with no route to the Internet, with no default credentials, with patching that has an owner and with
  a maintenance contract that includes firmware. Many run old operating systems that
  nobody updates because "they belong to the installer".
- **The installer's remote access is permanent privileged access**: it is governed like
  any third-party access (on demand, authenticated, logged, revocable) and **not** like an
  open tunnel for life.
- **The access system's database contains personal data** —who was where and
  when— and in many cases biometric data. Its own access control, defined retention and its legal
  basis (`privacy-engineering-standards`).
- **A backup of the access configuration and of the video** exists and is tested, or the
  first serious incident is left without evidence.
- **Power and network dependency**: what happens to doors, readers and recording when the
  power or the network goes down. It is decided and documented beforehand, not during (§6).

## 6. Operability

- **Fail mode of every door, decided and written down.** *Fail-safe* (opens when power is lost)
  where there is risk to people; *fail-secure* where there is not. **Evacuation regulations always win**:
  an exit that does not open in an emergency is a bigger problem than any intrusion.
  And the uncomfortable corollary: **a power cut can be an attack on access control** — you have
  to know what is left open.
- **Autonomy**: readers, controllers, recording and alarms need backed-up power. The
  sizing of that power belongs to `datacenter-facilities-standards`; **the requirement that
  this equipment be on it belongs here**, and it is the classic omission.
- **Degradation with the network down**: a controller that only validates against a central server stops
  working when it goes down. **Local validation with a cache** and subsequent synchronisation of the
  events are required.
- **Recording capacity consistent with the legal retention**: it is sized by days of retention,
  not by "whatever fits".
- **Log review with an owner and a cadence.** Without an owner it is never reviewed.
- **Metrics that decide something**: active badges without a current holder, mean revocation time
  after a departure, percentage of decommissioned assets with an associated certificate of destruction,
  access incidents detected by a control versus detected by chance, and false alarm
  rate. **Nothing like "number of cameras installed".**

## 7. Long-term sustainability

- **The access control system lasts 10–15 years and the credential technology ages sooner**:
  plan the badge technology migration as a project, not as an emergency on the day it is
  published that yours is trivial to copy.
- **Every move, building work or change of provider reopens the whole chapter**: new keys, new sockets,
  new staff. It is handled as a change with a security review, not as logistics.
- **Convergence with logical identity** (single joiner and leaver for physical credential and account) as an
  objective: it eliminates at the root the failure class "they left and their badge still opens doors".

**FORBIDDEN**:
- ❌ Locks and systems with **default credentials or codes** left unchanged. (And **FORBIDDEN
  to include in this document default credentials of third-party products**: methodology, not
  recipe book.)
- ❌ Documenting here **lock-picking, credential cloning or reader bypass
  techniques**, and carrying out any physical intrusion test without written scope and authorisation.
- ❌ Retaining recordings beyond the legal period, or "keeping them just in case" outside the exception
  in art. 22.3 LOPDGDD.
- ❌ Cameras in areas with an expectation of privacy, or video surveillance as generalised worker
  monitoring.
- ❌ Biometrics as a single factor, or biometric templates that are exportable or centralised without a legal
  basis and unencrypted.
- ❌ Accepting a **certificate of destruction without serial numbers**, or decommissioning an asset without one.
- ❌ Degaussing as a sanitisation method for **SSDs or flash memory**.
- ❌ Taking media out of the building without a chain of custody, or piling up disks pending destruction
  in an uncontrolled cupboard.
- ❌ Active network sockets in common areas without 802.1X, and serial consoles or KVMs accessible outside the
  management network.
- ❌ Visitors, technicians or cleaning staff without escorting in a technical zone.
- ❌ Presenting disk encryption or measured boot as if they **prevented** compromise with
  prolonged physical access: they are compensating controls and that is how it has to be put to management.
- ❌ Signing a colocation contract without settling in writing who accesses your cage, with what
  record and with what notification.
- ❌ Leaving the network of the physical security systems (access control, CCTV, alarms) unsegmented,
  unpatched or reachable from the Internet.

## 8. Mandatory web verification

Before committing to anything in a real project, check on the web:
1. **The legal obligation applicable to video surveillance in your jurisdiction**. What is cited here is Spain:
   **LOPDGDD art. 22.3, transcribed verbatim from the consolidated BOE text**; and the **EDPB
   Guidelines 3/2019**. Check the AEPD's current guidance (there is material updated in 2026) and, if
   the processing is employment-related, the specific rules. **This is not legal advice**: the
   interpretation is set by legal / data protection.
2. **NIST SP 800-88**: current revision (here, **Rev. 1**, definitions transcribed verbatim from the official
   PDF) and whether there is a later draft. **Declared gap**: it was not checked whether a later
   revision is under way.
3. **ISO/IEC 27001:2022 and 27002:2022**: exact numbering and titles of the theme 7 controls
   (A.7.1–A.7.14) and any later amendment. **The titles here come from consistent secondary
   sources, not from the text of the standard (which is paid-for): verify against the standard before
   using them in an SoA.**
4. **DIN 66399** (validity and levels) and **NAID AAA / i-SIGMA** (criteria and validity of the specific
   provider's certificate). Verify the certification **of the provider you are going to contract**, not the
   existence of the programme.
5. **The physical credential technology** you use or are going to buy: the public state of its security
   and whether the manufacturer already offers a replacement. It is the fastest-ageing piece of data in this document.
6. **Advisories and CVEs for your access control system, NVR and alarm panel**: they enter the
   `vulnerability-management-standards` process like any other asset, and they almost never do.
7. **Sector requirements** imposing specific physical controls (ENS, PCI DSS, healthcare
   or financial sector) and their current version.

If the web contradicts this document, **the web wins** — flag the discrepancy.
