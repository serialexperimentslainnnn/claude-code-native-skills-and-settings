---
name: incident-response-forensics-standards
description: Use for the technical response to a security compromise and its investigation — NIST SP 800-61r3 and SANS PICERL phases, containment that preserves evidence, RFC 3227 order of volatility, memory and disk imaging, hashing and chain of custody, cloud snapshot and control-plane log acquisition, container and ephemeral artifacts, super-timeline with plaso/log2timeline and Timesketch, Velociraptor, GRR, KAPE, Volatility 3, Autopsy/Sleuth Kit, YARA-X, CyberChef, IOC and ATT&CK mapping, eradication and rebuild from trusted source, mass credential and token rotation, ransomware, identity-compromise, supply-chain and insider playbooks, breach notification timelines under GDPR, NIS2 and DORA.
---

# Security incident response and digital forensics standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **technical response to a security compromise and to the investigation that explains it**:
forensic readiness, triage of indicators, containment without destroying evidence, acquisition and preservation
of evidence (memory, disk, cloud, containers, identity), analysis and timeline construction,
determination of scope and entry vector, eradication, verified recovery, playbooks by
type of compromise, coordination with regulatory notification and feeding the learning back into the
detection system.

Triggers: "compromise", "intrusion", "IOC", "malware", "ransomware", "exfiltration", "webshell",
"persistence", "lateral movement", "stolen token", "compromised account", "forensic image", "dd /
dcfldd / ewfacquire", "memory dump", "LiME", "evidence hash", "chain of custody",
"order of volatility", "RFC 3227", "PICERL", "NIST 800-61", "super timeline", "plaso",
"log2timeline", "Timesketch", "Velociraptor", "GRR", "KAPE", "Volatility", "Autopsy", "Sleuth Kit",
"YARA", "CyberChef", "forensic snapshot", "CloudTrail / Activity Log / Cloud Audit Logs", "auditd",
"$MFT", "prefetch", "shellbags", "eradication", "rebuild", "mass credential rotation".

**Guiding principle**: **the outcome of an incident is decided before it happens.** Whatever is not
instrumented, retained and accessible on day 0 cannot be investigated on day 1 — and no tool
compensates for the absence of telemetry. Operational corollary: **you do not restore what you have not understood**.
A service returned to production without knowing the entry vector is an incident that reopens, and the
second time round the attacker already knows how you respond.

**Not applicable**:
- `incident-management-standards`: the **management process** of any incident — declaration,
  severity, IC and roles, communication, cadence, closure, postmortem, process metrics. **A
  security incident uses both**: management governs it (who is in charge, who speaks, how decisions
  are made), this one investigates it (what happened, how it got in, what it touched, what is preserved). If you need to decide
  who communicates or what severity to assign, you go to the sibling skill; if you need to decide whether to power off
  the machine, you are in the right place.
- `sre-practice-standards`: reliability as a discipline (SLO, error budget, on-call, DORA). Its rule
  of "mitigate before you understand" **is partially suspended** when compromise is suspected: see
  §3.2. Reclassifying a reliability incident as a security incident is decided with the
  criteria in §3.1.
- `observability-standards`: instrumentation, telemetry pipeline and its **retention** — the
  prerequisite of this skill, not its content.
- `vulnerability-management-standards`: the CVE **before** it is exploited (triage, CVSS/EPSS/KEV,
  SLA, VEX). Once it has been exploited, the case belongs to this skill.
- `appsec-standards`: threat modelling and vulnerability classes in your own code.
- `grc-compliance-standards`: regulatory framework, formal obligations and audit evidence; here
  only the operational mechanics of preserving and of feeding the notification.
- `identity-access-management-standards`: break-glass, session and token revocation, MFA
  policy — the **how** of revoking during the incident.
- `cryptography-pki-standards`: rotation of compromised keys and certificates, revocation and
  reissuance.
- `bcdr-standards` §3.6: **where the compromised estate is rebuilt** — the isolated recovery
  environment (IRE / *clean room*), its three isolations and who signs off that it is clean. Exact
  boundary, and in both directions: **this skill produces the clean restore point, the IRE
  consumes it**; you do not rebuild in the fallen environment nor with its credentials.
- `ctf-lab-standards`: isolated lab where samples are detonated and practice happens; this skill is **not** a
  training environment.
- `onprem-standards`, `kubernetes-standards`, `networking-standards`, `cicd-standards`,
  `data-platform-standards`, `aws-standards`/`azure-standards`/`gcp-standards`, `homelab-standards`:
  the operation of each platform.
- `detection-engineering-standards` (**bidirectional and
  declared** boundary: there is where the detection that **fires** the incident is written, and **every investigation
  here returns new rules** — an investigation that leaves no detection is a half-done investigation),
  `offensive-security-standards` (purple team, deconfliction with the SOC —
  all authorised offensive activity is deconflicted before treating it as a real incident, and
  finding a **pre-existing compromise during an exercise** stops the exercise and activates this
  process), `secrets-management-standards` (mass rotation after the compromise),
  `linux-hardening-standards` (`auditd` as a source of evidence and a baseline that reduces
  surface), `container-runtime-security-standards` (container and node forensics,
  runtime capture), `privacy-engineering-standards` (personal data breach),
  `bcdr-standards` (when recovery exceeds the service and activates continuity),
  `backup-recovery-standards` (verified restore and immutable backups),
  `assembly-standards` (it sets when you **write** your own assembly and how it is
  maintained; **analysing someone else's binary in order to respond to an incident belongs here** —chain of
  custody, order of volatility, artifact triage—), `solidity-standards` (the
  contract and its incident plan written before deployment are theirs; **managing the
  real incident and tracing funds, here**).

## 2. Default decisions

> Verify the latest version and the maintenance status on the web before pinning them (§8). The data
> is from August 2026 and expires: this ecosystem moves in months.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Reference framework | **NIST SP 800-61r3** (April 2025) for **governance** + **SANS PICERL** for **execution** | Rev. 3 restructures the recommendations around the six CSF 2.0 functions and stops being a phase manual; the operational cycle (Preparation, Identification, Containment, Eradication, Recovery, Lessons learned) is still the one you execute. **Citing Rev. 2 (2012) as current is an error** |
| Collection order | **RFC 3227** (BCP, still current and not obsoleted) | Its logic carries over to cloud and containers; the procedures change, the order does not |
| Remote collection at scale | **Velociraptor** (0.77.1, Jun 2026; AGPL, maintained by Rapid7 after the 2021 acquisition) | **GRR** (v4.0.0.0, Dec 2025) if it is already deployed; check its maintenance pace before betting on it |
| Windows endpoint triage | **KAPE** | Free for internal/government/educational use, **paid licence for third-party engagements**; opaque release cadence since 2024. OSS alternative: Velociraptor artifacts |
| Memory | **Volatility 3** (2.28.x, Apr 2026; v2 deprecated since 2.26 "feature parity") | Windows: automatic symbols via PDB. **Linux: symbol table generated with `dwarf2json` from a kernel with debug symbols, with the exact banner** — this is prepared *beforehand*, not during |
| Linux memory capture | **LiME** or AVML; in cloud, snapshot + live capture from the agent | Verify kernel compatibility **before** the incident |
| Disk image | **E01/EWF** format (`ewfacquire`) or raw (`dd`/`dcfldd`) with on-the-fly hashing | E01 for compression and case metadata; raw for interoperability |
| Timeline | **plaso/log2timeline** (monthly/quarterly releases, active) → **Timesketch** (Google, active, 2026 releases) | Super-timeline only when triage is not enough: it is expensive in time and in noise |
| Filesystem analysis | **Autopsy 4.23.x / Sleuth Kit 4.15.x** (Apr-May 2026, active) | Commercial tool if the case is judicial and third-party validation is required |
| Artifact detection rules | **YARA-X** (1.19.x, Jun 2026) | YARA 4.x is in **maintenance mode**: new rules in YARA-X |
| Ad-hoc data transformation | **CyberChef** (11.3.0, Jul 2026), **self-hosted and offline** | The public instance is third-party: **never** paste case data into it |
| Adversary taxonomy | **MITRE ATT&CK**, current version | v19 (Apr 2026) is the current one; v18 introduced Detection Strategies and Analytics replacing Data Sources — the old mapping does not translate on its own |
| IR retainer | **Contracted beforehand**, with an activation SLA and pre-agreed access | Contracting the response with the fire already burning costs days and multiplies the price |
| Ransom payment decision | **Not a technical one**: legal + management + insurance, with a sanctions assessment | See §5 and §8 |

## 3. Execution: from suspicion to recovery

### 3.0 Preparation (what decides the outcome)

It is audited **beforehand**, with these questions. A "no" is a finding, not a nuance:

- **Telemetry**: do logs exist for authentication, process execution (`auditd`/Sysmon/EDR), network,
  DNS, cloud control plane and data access? With what **retention**? The retention window is
  the hard limit on what you will be able to reconstruct: an attacker with 90 days of dwell time and 30 days of
  logs is an investigation that ends in "cannot be determined".
- **Integrity**: are the logs sent to a destination **out of reach of the local administrator and of the
  attacker**, with immutable or WORM storage? Logs the attacker can delete are not evidence.
- **Clocks**: is NTP synchronised and the time zone documented across the whole estate? **All analysis is
  normalised to UTC.** A clock skew ruins an entire timeline.
- **Inventory**: do you know what assets exist, who owns them and what data they hold? Without an inventory
  there is no scope, and without scope there is no correct notification.
- **Emergency access**: is there break-glass with MFA, audited, **independent of the corporate IdP**?
  The control question: **would you be able to respond with the domain / the IdP compromised?** If the answer
  depends on signing in with the SSO you are investigating, you have no plan.
- **Tools ready**: static, trusted binaries on your own media, isolated analysis
  workstation, evidence storage sized appropriately, and **tested** in a drill.
- **Playbooks** by incident type (§5) with the decision already taken in the cold, not at 03:00.
- **IR retainer and contacts**: external forensics, insurer, legal/DPO, reference CSIRT
  (INCIBE-CERT / CCN-CERT / ESPDEF-CERT in Spain) and law enforcement, with numbers and
  procedure outside the system that may be down or compromised.

### 3.1 Identification and triage

- **Reclassification criteria** from an operational incident to a security incident: unexplained
  authentication or permission change, unknown persistent process or binary, outbound traffic to an
  unexpected destination, deletion or alteration of logs, mass encryption or alteration of files,
  appearance of new accounts or keys, a detection alert with coherent context. **When in doubt,
  treat it as a compromise**: the cost of being wrong upwards is a few hours; downwards, the
  whole incident.
- **Triage before deep analysis**: collection of key artifacts at scale (Velociraptor/KAPE)
  to answer three questions in hours, not weeks — **is the attacker inside right now?**,
  **how far did they get?**, **what data did they touch?**. Deep analysis (malware, reverse engineering)
  comes afterwards and **only as far as it contributes to the response**: understanding the whole binary is
  research, not response.
- **Explicit hypotheses, tested**, with what would confirm them and what would refute them. A
  forensic report with no alternative hypotheses discarded is a narrative.
- **Confidence marker** on each conclusion: confirmed / probable / possible / discarded. The
  evidence supporting each one is documented.

### 3.2 Containment without destroying evidence

- **Isolate, do not destroy.** Taking it off the network (quarantine VLAN, deny-all security group, cluster
  network policy) keeps the system alive and with its memory; deleting, recreating or reinstalling kills the
  investigation.
- **Exception to "mitigate before you understand"**: when the mitigation is destructive and there is suspicion of
  compromise, you **preserve first**. The IC (see `incident-management-standards`) records the
  decision, who takes it and at what cost. If the business impact forces an immediate restore, at least memory
  and a snapshot are captured beforehand, and what is lost is put on record.
- **Power off vs. do not power off**, explicit criteria:
  - **Do not power off** by default: memory is lost (processes, connections, encryption keys, payloads
    resident only in memory, credentials), which is often the only proof of the vector.
  - **Power off (or pull the power)** if the ongoing damage exceeds the value of the memory: active encryption,
    exfiltration in progress with no way to cut the network, physical safety risk. **Pull the power** instead
    of shutting down cleanly when you fear a tampered shutdown script that destroys
    evidence (RFC 3227 warns about this explicitly).
  - **Never reboot** "to see if it fixes itself".
- **Order of volatility (RFC 3227)**: registers and cache → routing table, ARP cache, process
  table, kernel statistics, **memory** → temporary filesystems → **disk** →
  remote logging and monitoring → physical configuration and network topology → archival media.
- **Do not trust the binaries of the compromised system**: tools from your own trusted
  media. Every execution on the system leaves traces: document what was run, when and by whom.
- **OPSEC of the investigation**: assume the attacker sees what you touch. Do not investigate from the compromised
  account nor from the affected system; do not use the corporate channel if it may be compromised;
  do not block indicators one by one while investigating (you show them your progress and cause them to switch
  infrastructure or trigger a destructor). **Containment is planned and executed in one go**,
  once the scope is bounded — except with active damage, where you cut immediately.
- **Identity first in cloud**: revoke sessions and tokens, disable (do not delete) keys, and **do it
  as a coordinated action**. See `identity-access-management-standards`.

### 3.3 Acquisition and chain of custody

- **Hash at the moment of acquisition** (SHA-256; MD5 only as a legacy identifier and **never**
  as the sole guarantee) and **re-verification at every transfer**. Without a source hash, the evidence
  is just some file.
- **Write blocking** in physical acquisition; in cloud, snapshot and copy to a separate forensic
  account/project with immutable storage and versioning enabled.
- **Chain of custody** documented: what was acquired, from which system, when (UTC), with which
  tool and version, by whom, hashes, and every subsequent handover. **It matters even if it never reaches a
  court**: it is what makes your conclusion reproducible, reviewable by a third party and defensible
  before an insurer, a client, an auditor or a regulator. Custody discipline is method
  discipline, not legal formalism.
- **Work on copies**, never on the original; the original is preserved intact.
- **Evidence retention** defined and coordinated with legal (litigation hold if applicable) and with
  personal data minimisation — two obligations that can pull in opposite directions: it is
  arbitrated by legal/DPO, not by engineering.
- **By platform**:
  - **Linux**: memory (LiME/AVML), disk, `auditd`, `journald`/`syslog`, `/var/log/{auth,secure}`,
    `~/.*history`, systemd units and timers, `cron`, authorised SSH keys, `/tmp` and `/dev/shm`,
    kernel modules, packages with altered integrity.
  - **Windows**: memory, `$MFT`/`$UsnJrnl`, registry (SYSTEM/SOFTWARE/SAM/NTUSER), Event Logs
    (Security, System, PowerShell Operational, Sysmon if present), Prefetch, Amcache/Shimcache, scheduled
    tasks, services, persistent WMI, ShellBags, LNK/Jump Lists.
  - **macOS**: memory if feasible, Unified Logs, LaunchAgents/LaunchDaemons, TCC, FSEvents,
    quarantine attributes.
  - **Cloud**: **control plane first** (CloudTrail / Activity Log + Entra ID / Cloud Audit Logs),
    because it is what the attacker can disable or rotate; then instance metadata
    (configuration, IAM role, security groups, user data, tags, interfaces — **they change on containment and
    are not recoverable**), disk snapshots, and data access logs. Document what the provider does
    **not** give you: in SaaS there are only audit logs; in PaaS there is no operating system.
  - **Containers and ephemerals**: the evidence **evaporates by design**. Capture before the
    orchestrator recreates: container filesystem (`checkpoint`/`export`), process
    memory, `/proc` of the PID on the node, image and its digest, manifest and variables, runtime
    and node logs, and admission and API server events. If the pod has already been recreated, the evidence
    is on the **node** and in the image registry, not in the container.
  - **Identity**: authentication logs, tokens and refresh tokens issued, registered devices,
    OAuth application consents, mail forwarding rules, MFA changes. In an identity
    compromise, **this is the crime scene**, not the server.

### 3.4 Analysis

- **Timeline first**, hypotheses afterwards. Timeline of key artifacts to bound it; **super-timeline**
  (plaso → Timesketch) when fine-grained correlation between sources is needed. Everything in **UTC**, with the
  source of each event annotated.
- **Determine and document**: entry vector (patient zero), first activity (not the first
  alert), persistence, escalation, lateral movement, compromised credentials, data accessed or
  exfiltrated, and **dwell time**. If you cannot determine something, say so: "could not be determined with the
  available telemetry" is a valid and actionable conclusion; making it up is not.
- **Scope by iteration**: every new indicator is searched for **across the whole estate**, not only on the affected
  machine. A compromise is closed when the search at scale stops yielding new results, not
  when the first machine is cleaned.
- **Map to ATT&CK** to communicate, to compare and to close detection gaps — not as a
  decorative exercise.
- **Bounded malware analysis**: extracting IOCs, capabilities, persistence and C2 is response; full
  reverse engineering is research and is outsourced or postponed. Detonation **only** in
  an isolated lab (see `ctf-lab-standards`), never on the corporate network nor in a VM on the production
  hypervisor.

### 3.5 Eradication and recovery

- **You do not restore until you can answer**: what was the vector?, is it closed?, what persistence
  was there and has all of it been removed?, which credentials were compromised and have they been rotated?
- **Rebuild from a trusted source > cleaning.** Cleaning a compromised system is almost never
  defensible: you cannot prove the absence of persistence on a system the attacker controlled,
  and modern techniques (firmware, tasks, WMI, accounts, keys, container images) survive
  cleaning. Justifiable exceptions: a system where rebuilding is not viable in the short term
  and the risk is accepted **formally and in writing**, with enhanced monitoring and a replacement date.
- **Restore from backup while verifying that the backup is not compromised**: identify the moment of the
  initial compromise (not of the detection) and restore from a point **before** it; verify the
  integrity of the backup and **scan it before reconnecting it**. A backup later than day 0 also restores
  the attacker. Coordinate with `backup-recovery-standards` and `bcdr-standards`.
- **Mass credential rotation** with a scope criterion, not a convenience one: passwords of
  affected and privileged accounts, `krbtgt` (twice, with the replication interval between the two)
  if there was a domain compromise, API keys and tokens, application secrets, SSH keys, signing
  keys and certificates (see `cryptography-pki-standards` and `secrets-management-standards`), sessions
  and refresh tokens (see `identity-access-management-standards`). **Rotating half is not rotating.**
- **Enhanced monitoring** post-recovery with a defined window (30-90 days) and case-specific
  detections: the return of the same attacker is the most frequent scenario.
- **Coordinated cut**: eradication is executed as a single, planned action (close the vector,
  remove persistence, rotate credentials, cut C2). Doing it piecemeal gives the attacker time
  to react and re-establish.

## 4. Investigation quality (the gates)

1. **Reproducibility**: another analyst, with the same evidence and the case notes, reaches the same
   conclusion. Case notes with timestamps, commands executed and tool versions. Without
   this, there is no investigation: there is opinion.
2. **Evidence integrity**: source hashes recorded and **re-verified** at closure; chain
   of custody complete and without gaps.
3. **Tested hypotheses**: each conclusion with the evidence supporting it, the alternatives
   considered and why they were discarded. Explicit distinction between **observed fact** and
   **inference**.
4. **Confidence marker** on every statement (confirmed / probable / possible) and an explicit statement
   of the **limitations**: what could not be determined and why (insufficient retention, deleted
   logs, absence of telemetry). It is one of the most useful parts of the report: it feeds the backlog.
5. **Peer review** mandatory before issuing the report or communicating to management, client or
   regulator — especially if legal or contractual obligations derive from it.
6. **Verifiable scope closure**: the search for indicators at scale has been executed over the
   **complete inventory** and the last iteration produced no new results.
7. **Verification of the eradication** before restoring: vector closed (proven), persistence
   removed (specifically searched for), credentials rotated (listed), new detections active.
8. **Lessons to the detector**: **every incident produces new detection rules** and new
   telemetry requirements, with an owner and a date, handed over to `detection-engineering-standards` and
   `observability-standards`. An investigation that leaves no detection leaves the same hole open.
9. **Exercising the capability**: periodic forensic drill — acquire memory and disk from a real
   system, with the real tools and the real people, against the clock. Find out that LiME does not compile
   against the current kernel in the drill, not during the incident.

## 5. Special cases and legal framing

### Ransomware

- **Contain the encryption first** (isolate en masse, cut propagation, disable abused service
  accounts); preserving the memory of a machine still powered on may contain the key.
- **Assume exfiltration prior to encryption**: double extortion is the dominant pattern. The incident is
  a **data breach** until proven otherwise, with the obligations that triggers.
- **Verify the backups before trusting them**: deleting or encrypting backups is part of the
  attacker's playbook. **Immutable and offline** backups are the control that decides the outcome.
- **The decision to pay is not technical**: it is taken by management, legal and the insurer. Considerations:
  paying does not guarantee decryption nor the deletion of what was exfiltrated, it funds the ecosystem, and **it may
  constitute an offence if the recipient is sanctioned**. In the United Kingdom a ban is advancing
  for the public sector and CNI plus a duty to notify before paying; in the EU and Spain there is no
  general ban and the route is transparency and the sanctions/AML regime (§8: **verify it, it changes
  fast**). Paying **does not extinguish** the obligation to notify nor stop the criminal investigation.
- Check `nomoreransom.org` in case a decryptor exists before any decision.

### Identity / token compromise

- The scene is the IdP: sessions, tokens, devices, OAuth consents, mail rules,
  registered MFA methods. **Changing the password does not invalidate already-issued tokens**: you have to
  revoke sessions and refresh tokens explicitly.
- Look for identity persistence: applications with consent, client credentials added
  to service principals, tampered federation, compromised token signing keys (the worst case:
  it invalidates everything issued and requires reissuance).

### Supply chain

- The scope is not your network: it is **everything that consumed the compromised artifact**. Determine affected
  versions by digest, not by tag. Precedent from the catalogue: the compromise of **Trivy in March
  2026** forced it to be dropped as the default.
- Preserve the malicious artifact and its provenance; notify upstream and downstream. Review the
  pipeline as a scene (`cicd-standards`): runners, OIDC credentials, secrets and signatures.

### Insider

- Coordination with HR and legal is **mandatory before** any technical action; preservation
  is done without alerting the subject and respecting the applicable employment and data protection framework.
- Here the chain of custody does frequently end in a formal proceeding: maximum rigour from the
  first minute.

### Regulatory notification (framing, **not legal advice**)

**Whoever decides whether there is an obligation to notify is legal/DPO, not engineering.** The role of this skill is
to produce the minimum information in time: what happened, when it became known, what data and categories,
approximately how many affected, what measures have been taken. Current deadlines verified as of August 2026 —
**verify them anyway (§8)**.

> **Single source for the deadlines: `grc-compliance-standards`.** The same regimes appear in three
> skills (here, `incident-management-standards` and it). **If they diverge, `grc-compliance-standards`
> wins**; fix all three in the same change. What belongs here is only the
> **mechanics**: what evidence supports the notification and how it is preserved without stopping the clock.

- **GDPR art. 33**: ≤ **72 h** from becoming aware, to the supervisory authority (AEPD); communication to
  the data subjects if there is high risk (art. 34). **Phased** notification is allowed: you notify with what
  you know and expand later. Document every breach even if it is not notified.
- **NIS2**: **early warning ≤ 24 h**, **notification ≤ 72 h**, **final report ≤ 1 month**. In Spain
  the reference CSIRT is INCIBE-CERT (private sector), CCN-CERT (public sector) and ESPDEF-CERT (defence).
  The Spanish transposition was still **unpublished in the BOE** as of August 2026.
- **DORA** (financial): initial ≤ **4 h** from classification as major and ≤ 24 h from
  detection, intermediate ≤ 72 h, final ≤ 1 month.
- **ENS (RD 311/2022)**: notification to CCN-CERT via LUCIA with deadlines tiered by impact
  (CCN-STIC 817) — **not checked against a primary source in this revision** (§8).
- **The clock runs from awareness, not from the diagnosis.** Holding back the notification until
  the forensics are closed is the most expensive and most common error.
- Technical detail that goes outside is coordinated with legal and with the Comms lead
  (`incident-management-standards`): neither hide the impact nor publish the map of your network.

## 6. Operability of the response capability

- **Minimum useful retention**: 12 months for authentication, cloud control plane and security
  logs; 90 days as an absolute floor for the rest. Typical dwell time comfortably exceeds
  30 days: retaining 30 is guaranteeing incomplete investigations. Cost and value are decided **beforehand**
  (see `observability-standards`).
- **Immutability**: log destination out of reach of local administrators; WORM/object lock on
  the evidence and backup store.
- **Analysis workstation** isolated, with its own storage, without access to production and without
  corporate credentials; tools verified by signature or hash before use. Samples are
  handled encrypted and password-protected, and are only detonated in the lab (`ctf-lab-standards`).
- **Automate the acquisition**: in cloud, a trigger that snapshots and isolates on receiving the alert.
  Ephemeral evidence does not wait for someone to wake up.
- **Size the evidence storage** in advance: a medium-sized case is terabytes, and
  discovering that halfway through an acquisition forces you to choose which evidence to lose.
- **Verify the tools before you need them**: Volatility symbols for your kernels, LiME
  compiled for your versions, Velociraptor agent deployed and tested. An agent that has to be
  deployed during the incident is a change to the scene and a delay of hours.
- **Download tools only from upstream and with verification**: mirrors and repackagers run
  months behind (documented case with YARA-X). Pin by digest and verify signature/attestation.

## 7. Sustainability and prohibitions

- **Cadence**: playbooks reviewed twice a year and after every incident that uses them; tool
  catalogue reviewed twice a year (maintenance, licence, their own CVEs); matrix of notification
  obligations reviewed annually and on any regulatory change.
- **Deprecation**: remove from the playbooks every tool without active maintenance. An abandoned
  forensic tool = indefensible results and added attack surface.
- **The capability is trained or it atrophies**: a forensic drill at least annually, with real
  acquisition and a stopwatch.
- **Minimum living documentation**: playbook per incident type, map of evidence sources with their
  retention, acquisition procedure per platform, chain of custody template, notification matrix
  and out-of-band contact list.

**FORBIDDEN**
- ❌ Powering off or rebooting a compromised system without explicit criteria, destroying the memory.
- ❌ Reinstalling, recreating or "cleaning" before preserving; deleting the pod and losing the node with it.
- ❌ Investigating with the compromised account, from the affected system or with the binaries of the system
  itself.
- ❌ Blocking indicators one by one while investigating, warning the attacker of your progress.
- ❌ Coordinating the investigation in the corporate channel when it may be compromised.
- ❌ Restoring without eradicating, or restoring from a backup later than the initial compromise without verifying it.
- ❌ Partial credential rotation after a domain or identity compromise.
- ❌ Working on the original evidence instead of on a hash-verified copy.
- ❌ Evidence without a source hash, without chain of custody or without normalisation to UTC.
- ❌ Stating a fact without distinguishing it from an inference, or issuing a report without peer review.
- ❌ Declaring "there was no exfiltration" when what is missing is telemetry: that is "could not be determined".
- ❌ Detonating samples outside an isolated lab, or uploading case samples and artifacts to
  public services (VirusTotal, CyberChef online, pastebins) without explicit authorisation: it is
  exfiltration on your part and a warning to the attacker.
- ❌ Contracting the IR retainer when it is already burning.
- ❌ Delaying the regulatory notification until the investigation is closed.
- ❌ Deciding a ransom payment at the technical level, or paying without a sanctions assessment.
- ❌ Closing the case without new detection rules or telemetry requirements with an owner.
- ❌ Unmaintained forensic tools, from third-party mirrors or without signature verification.
- ❌ Using YARA 4.x for new rules, or citing NIST SP 800-61 **Rev. 2** as current guidance.

## 8. Mandatory web verification

Before pinning any version, deadline or reference, **look it up — do not recall it**:

1. **NIST SP 800-61**: verified Aug 2026 — **Rev. 3, April 2025**, *Incident Response Recommendations
   and Considerations for Cybersecurity Risk Management: A CSF 2.0 Community Profile*, supersedes
   Rev. 2 (2012) and is structured around the six CSF 2.0 functions instead of the phase cycle.
   **Declared gap**: the full PDF has not been read to confirm the exact treatment it gives to
   containment/eradication/recovery — verify it before citing its structure in detail.
   Complement with SP 800-86 (integrating forensics into the response) if it is still current.
2. **Notification deadlines** (GDPR 72 h, NIS2 24/72 h/1 month, DORA 4/24/72 h/1 month, ENS/CCN-STIC 817):
   verify **every figure** and the recipient before using it, and the status of the Spanish
   transposition of NIS2 (unpublished in the BOE as of Aug 2026) and of the NIS2 revision proposed by the
   Commission in January 2026. **The ENS deadlines by impact level have not been checked against a
   primary source in this revision.** The legal criterion belongs to legal/DPO.
3. **Stance on ransom payment**: United Kingdom (ban for the public sector and CNI + duty of
   prior notification, via the Cyber Security and Resilience Bill — **check whether it is already in force**),
   EU/Spain (no general ban; transparency and sanctions). Changes fast.
4. **Tool status** before recommending them — verified Aug 2026: Velociraptor 0.77.1
   (Jun 2026, AGPL, Rapid7); Volatility 3 2.28.x (Apr 2026, v2 deprecated); plaso (2026 releases with
   quarterly cadence); Timesketch (2026 releases, minimum OpenSearch 2.19.5); Autopsy 4.23.x /
   Sleuth Kit 4.15.x (Apr-May 2026); YARA-X 1.19.x (Jun 2026, YARA 4.x in maintenance); CyberChef
   11.3.0 (Jul 2026); GRR v4.0.0.0 (Dec 2025 — **check its maintenance pace**); KAPE
   (maintained by Kroll, **opaque release cadence since 2024 and restricted licence for
   third-party work**).
5. **Supply-chain incidents** in any tool you are going to introduce into the
   response environment (precedent: Trivy, March 2026). Verify signature and provenance attestation.
6. **MITRE ATT&CK**: current version and model changes — v19 (Apr 2026) is the current one; v18 replaced
   Data Sources with Detection Strategies/Analytics. Confirm before mapping.
7. **Provider cloud forensics guides** (AWS, Azure, GCP): snapshot procedures,
   control-plane log retention and their limits. They change with the services.
8. **RFC 3227**: verified Aug 2026 — it is still BCP and has not been obsoleted. Confirm that no
   successor has appeared before citing it as the sole reference.

If the web contradicts this document, **the web wins** — flag the discrepancy.
