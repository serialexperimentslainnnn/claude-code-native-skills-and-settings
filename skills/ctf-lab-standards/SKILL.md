---
name: ctf-lab-standards
description: Use when building or running an isolated security training lab or playing CTFs — host-only or internal-network VMs with snapshots, Kali, REMnux, FLARE-VM, INetSim, detonating challenge binaries or malware samples in a disposable VM, Hack The Box, TryHackMe, PortSwigger Web Security Academy, pwn.college, OverTheWire, Proving Grounds, CTFtime events, jeopardy vs attack-defense vs king-of-the-hill formats, writeups and platform terms of service, or planning OSCP/CPTS study.
---

# Security lab and CTF standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **training offensive security in an environment where authorisation is intrinsic**:
lab construction and isolation, safe execution of challenge binaries and malware
samples, use of training platforms within their terms, CTF competition,
learning method and progress measurement, competition ethics and transfer (or not)
of what is learned to real work. Triggers: "security lab", "disposable VM",
"host-only", "snapshot before detonating", "Kali", "REMnux", "FLARE-VM", "INetSim",
"Hack The Box", "HTB", "TryHackMe", "PortSwigger Web Security Academy", "pwn.college",
"OverTheWire", "Proving Grounds", "CTFtime", "jeopardy", "attack-defense", "king of the hill",
"writeup", "flag", "pwn", "reversing", "OSCP", "CPTS".

### Hard precondition — where the authorisation lives here

In this domain authorisation **is not signed, it comes from the environment**, and that is why you
must check that the environment really gives it. You only practise on **one** of these three things:

1. **Your own infrastructure** in an isolated lab (VMs, vulnerable targets you have
   deployed, your own code).
2. **A training platform** whose **terms of service in force** explicitly authorise
   the activity, and **only within its scope**: its target machines, not its
   infrastructure, not other users.
3. **A CTF or event** in progress, within its published rules and its window.

Anything else —a third party's system, a service that "looks like a test one", the neighbour's
router, your former employer's website— **is not authorised**, and the criminal framework is the
same as for a real attack (see §1 of `offensive-security-standards`: in Spain, arts. 197 bis and
197 ter and 264 CP; **the owner's consent is what makes the test lawful**). That it is
"to learn" is no defence. **This is not legal advice**: when in doubt, consult
a lawyer.

**Not applicable**: see `offensive-security-standards` (**authorised** offensive exercise **against
third-party or organisation systems**: pentest, red team, purple team, bug bounty,
RoE, report, retest — there the authorisation is signed and there is a client assuming risk;
**here there is no client and no business risk, only learning**), `homelab-standards`
(personal **general-purpose** lab: hardware, power draw, cost, self-hosting,
backups of services you actually use — **the boundary is purpose and isolation**:
here the lab exists to detonate hostile things and that is why it is segmented and
disposable; there it exists to provide a service and that is why it gets backed up), `appsec-standards`
(vulnerability classes and their prevention in your own code),
`vulnerability-management-standards` (CVE, CVSS/EPSS/KEV, remediation SLA),
`networking-standards` (real network design, VLANs and production firewalling),
`kubernetes-standards`, `bash-linux-scripting-standards` (quality of your own tooling),
`grc-compliance-standards`, `cryptography-pki-standards`,
`identity-access-management-standards`, `air-gapped-standards` (**theirs the internal
registry/mirror and network isolation as a discipline**; **here the direction of the threat is the
opposite**: there isolation protects the enclave from the world, here it protects the world from the
lab), the cloud and language skills. Also:
`incident-response-forensics-standards` (real forensics and IR — here only the
forensics category of a CTF, which resembles it little),
`detection-engineering-standards`, `linux-hardening-standards`,
`container-runtime-security-standards`.

## 2. Default decisions

> Verify on the web versions, platform status and **their terms of service
> in force** before pinning anything (§8). The data is from August 2026 and expires.

| Scope | Default | Reason / justifiable alternative |
|---|---|---|
| Lab network isolation | **`host-only` / hypervisor internal network, with no route to the home LAN or to the internet** | It is the primary control. Any other measure is secondary; if the lab routes to your LAN, it is not a lab, it is a vector |
| Internet simulation | **INetSim** on the lab's Linux VM answering DNS and services | It lets the sample "see the internet" without there being one. Minimum check: from the Windows VM, resolving a domain must return the local service's IP and external traffic must fail |
| Windows analysis VM | **FLARE-VM** on Windows in a dedicated VM, **never the host** | It requires disabling the system's antivirus protection (or the install fails), which makes it unacceptable outside an isolated, disposable VM |
| Linux analysis/services VM | **REMnux** (prebuilt image or on top of an Ubuntu LTS base) | It brings the analysis instrumentation and acts as "fake internet" with INetSim |
| Offensive distribution | **Kali Linux** in a VM, exclusive to the lab | Never as the host OS or that of the work laptop: it is an arsenal on the machine from which you run your life |
| VM state | **Clean snapshot before every detonation; always revert afterwards** | The VM is considered compromised the moment something hostile runs. It is not "cleaned": it is reverted |
| Credentials and data in the lab VMs | **None real**: no personal accounts, no tokens, no SSH keys, no browser sessions, no folders shared with the host | Shared folders and the hypervisor clipboard are documented escape routes. They get disabled |
| Web platform (base) | **PortSwigger Web Security Academy** | Free, maintained by PortSwigger's research team, interactive labs and learning paths from beginner to expert. It is the best starting point for web |
| Systems and pwn fundamentals | **pwn.college** (open university curriculum) and **OverTheWire** for shell wargames | Structured and free progression; verify current status before recommending them (§8) |
| Machine platform | **Hack The Box** and/or **TryHackMe**, depending on the goal | THM guides more and holds the beginner back less; HTB penalises more and teaches the intermediate more. HTB has a **strict AUP** on writeups and on use of its content (§4) |
| Competition calendar | **CTFtime** | Reference for events, formats and ranking. Formats it lists: **Jeopardy**, **Attack-Defence** and mixed/hack-quest — *King of the Hill* is not a formal label of theirs |
| Certification | **None by default**; if one is needed, whichever the target market demands | **OSCP** is still the one recruiters filter by; **CPTS** (HTB) is far cheaper and its 10-day exam is closer to a real engagement, but it is less recognised by ATS and recruiters. The certification opens the door; the lab is what gives the competence |

## 3. Building the lab

### Minimum topology

```
[ HOST ]  ── no bridge ──  ( hypervisor internal / host-only network )
                                        │
                    ┌───────────────────┼───────────────────┐
              [ Analyst/attacker ]   [ Services ]       [ Victim ]
              Kali / REMnux          INetSim, DNS,      Windows + FLARE-VM
                                     capture            or vulnerable target
```

Design rules, in order of importance:

1. **No bridge or NAT towards the LAN.** Every lab VM's network adapter goes to a hypervisor
   internal network. If you need to download tools, it is done **beforehand**, with the VM
   on NAT, and you switch to the internal network **before** introducing anything hostile.
2. **Verify the isolation, do not assume it.** Explicit check after every topology
   change: from the victim VM, neither the real gateway nor a public IP must
   answer; the local simulated service must answer. **A lab whose isolation has not been
   checked is considered not isolated.**
3. **Host firewall on** and, if the hypervisor allows it, rules that block
   forwarding from the lab network. Defence in depth: the internal network is the control, the
   firewall is the backstop when someone leaves an adapter misconfigured.
4. **Nothing shared with the host**: shared folders disabled, bidirectional
   clipboard disabled, drag-and-drop disabled, USB not exposed. They are
   precisely the channels through which a sample escapes the VM.
5. **Snapshots with a name and a purpose**: `clean-base`, `tools-installed`,
   `pre-detonation`. Reverting is the normal operation, not the exception.
6. **Additional physical or logical segmentation** if the host is on a shared network: a dedicated
   VLAN or, better, separate hardware. A malware lab in the same broadcast
   domain as the work laptop or the home devices is not isolated.

### Running challenge binaries and samples: the risk is real

- A CTF challenge binary is **arbitrary code from a stranger**. That it comes from a
  reputable platform reduces the probability, it does not eliminate it, and in a CTF with challenges
  uploaded by participants it does not reduce it much either.
- A malware sample **does exactly what the name says**: it encrypts, it spreads across the
  network it can reach, it steals browser credentials, it persists. That is why it is detonated in a
  disposable VM, on an internal network, with no credentials, with a prior snapshot and a revert afterwards.
  There is no "quick" version of this.
- **The VM is not a perfect security boundary**: hypervisor escapes have existed and will
  exist. For targeted samples or samples of unknown origin, dedicated hardware physically
  isolated, not a VM on the work laptop.
- **Never run anything from a challenge on the host**, not even "just to see what strings it has". Static
  analysis is also done in the VM.
- Upload samples to public analysis services with judgement: **what you upload is published**
  for the industry. A sample from a real incident may contain client data and uploading it
  tells the attacker they were detected. In a CTF it does not matter; in real work, it does.

### Toolchain hygiene
- Tools are installed **in the lab VM, never on the host**. The host keeps only
  the hypervisor.
- Third-party repository tools: they are reviewed like any binary you run and
  they are run inside the lab. In 2026 the dominant attack pattern has been compromising
  **security and CI tooling** (TeamPCP campaign, March 2026) — the security community is a
  priority target, and a script "from a writeup" is a perfect vector.
- **Never blindly run a command from a writeup.** Read it, understand it, and run it in the
  VM. That habit is moreover exactly the one an authorised engagement will demand of you.

## 4. Learning quality

> This section replaces the template's CI gates: what has to be controlled here is
> the learning and the integrity of the lab, not a build.

### Categories and what each one trains

| Category | Real skill it builds | Transfer to work |
|---|---|---|
| **Web** | Understanding of the protocol, of authorisation logic and of the client-server trust chain | **High**. It is the one that most resembles real work |
| **Pwn / binary exploitation** | Memory model, ABI, mitigations and how they are broken | **Medium**: you will rarely apply it, but it is what makes you truly understand what protects a system |
| **Reversing** | Reading what a binary does without source; structured patience | **High** if you are going into malware/IR; medium if not |
| **Crypto** | Telling "using crypto" apart from "using it well"; why ECB, nonce reuse and rolling-your-own fail | **Medium-high** conceptually, low operationally. See `cryptography-pki-standards` |
| **Forensics** | Evidence methodology, filesystems, memory, timelines | **Medium**: the challenges are puzzles; real IR is process, scale and pressure |
| **OSINT** | Correlation of open sources | **High** in reconnaissance, with a legal and ethical limit the CTF does not teach (§5) |
| **Hardware / ICS** | Protocols and physical surfaces | Low/niche, high if it is your sector |
| **Cloud** | Identity, permission and metadata confusion: where the modern compromise happens | **Very high**. Underrepresented in CTFs relative to its real weight |

### Formats
- **Jeopardy**: independent challenges by category and points. The entry format, and 90 %
  of what you will play.
- **Attack-Defence**: identical services that you defend while attacking the others. It is the one
  that most resembles operating under pressure, and the only one that teaches that **patching scores too**.
  Infrastructure-heavy, almost always on-site and with limited places.
- **King of the Hill**: shared objectives that are taken and held. It teaches
  persistence and evicting the rival; uncommon for beginners.

### Method (what separates playing from learning)
- **Your own notebook, from day one.** The command, why you ran it, what you
  expected, what came out. The value of a CTF is in the record, not in the flag: the flag is forgotten
  in a week.
- **Your own writeup of everything you solve**, even if you do not publish it (and even if you cannot
  publish it, §5). Writing forces you to reconstruct the reasoning and detects where you got
  lucky instead of using judgement. It is moreover the direct rehearsal of a real exercise's deliverable
  (`offensive-security-standards` §6).
- **When to look at the hint**: when you have gone ~30-45 min with no new hypothesis to test —
  not when the current hypothesis fails. Getting stuck with no hypothesis teaches nothing; testing and failing
  with judgement does.
- **How to use someone else's writeup**: read only the next step, go back to the challenge, and **redo the
  whole challenge from scratch afterwards**. Reading a full walkthrough before attempting it produces
  the illusion of competence, which is worse than not knowing, because it does not warn you.
- **Do not burn out**: CTFs punish through failure, and burnout is the most common failure mode
  of this discipline. Bounded sessions, graded difficulty, and stopping when it stops teaching.
  Sustained cadence > marathons.
- **Measure progress** by real signals: reduction in the time to the first valid
  hypothesis, challenges solved without a hint, ability to explain the solution to someone else, and **redoing an
  old challenge without notes**. Ranking and the number of flags do not measure competence.
- **Specialise after sweeping**: first a broad pass through all the categories to
  know what exists; then depth in one or two. The other way round builds an early ceiling.

### Lab integrity (the "gates" here)
Before each detonation session, this check is mandatory and non-negotiable:
1. Network adapter of every VM involved on an **internal/host-only network** — verified, not
   assumed.
2. Shared folders, clipboard and drag-and-drop **disabled**.
3. **Clean snapshot taken** and named.
4. No real credentials, keys or sessions inside the VM.
5. Host firewall on.

After the session: **revert to the snapshot**, always. And periodically: rebuild the base VM
from scratch, because accumulated snapshots hide state you no longer control.

## 5. Ethics and limits

- **Do not attack the platform's infrastructure**, only its targets. The platforms expressly
  forbid it: HTB, for example, forbids direct communication between members'
  systems and attacking other users' clients, and **forbids DoS against any
  machine, inside or outside its network**, requiring immediate notification of any accidental
  DoS. If you find a flaw in the platform, it is reported through its disclosure
  programme, it is not exploited.
- **Do not share flags or solutions beyond what is permitted.** Sharing the flag does not help
  anyone learn and is usually grounds for a ban. On HTB the sharing of solutions is
  limited to the closed scope of your team, and publishing them outside its approved list breaches
  the terms, with "retired" content as the general criterion for writeups. **TryHackMe is
  in practice more permissive with public walkthroughs.** Verify each platform's policy in force
  before publishing (§8): they change and they are the ones in charge.
- **Event rules above custom**: no collaboration between teams if it is forbidden,
  no multiple accounts, no attacking the scoreboard, no flag-sharing. In
  attack-defence, no destroying the rival's service beyond what the rules allow.
- **Terms of service in force, not remembered.** AUPs get updated: HTB's, in force
  since **1 Apr 2026**, added, among other things, the prohibition on using its content to
  train, evaluate or benchmark AI/LLM models, the limitation of the use of its resources to
  training purposes, and the prohibition on sharing or distributing exploits and attack tools
  intended to harm systems outside the designated training environments.
- **The bridge to real work**: nothing learned here is applied against a system
  that is not yours without written authorisation. That is the domain of
  `offensive-security-standards`, and its §1 is a hard precondition, not a recommendation. The
  CTF gives you **no** permission for anything outside the CTF.
- **OSINT has a legal and ethical limit** the CTF does not teach: the challenge rewards finding the
  person; the law and decency limit what is collected about real people, and the GDPR
  applies. Practising OSINT on real people with no engagement or consent is not training,
  it is surveillance.
- **AI in CTFs**: autonomous systems already solve medium-level jeopardy in minutes, with
  cases reported in 2026 of agents dispatching complete challenge sets and beating
  most human teams on entry-level platforms. Consequences: (a) respect the
  event's policy on AI use, which varies and sometimes forbids it; (b) delegating the
  solving destroys the purpose — the goal is for you to learn; (c) the differential human
  value shifts towards what AI does worse: context, prioritisation and business logic.

## 6. From CTF to real work

What transfers and what does not. Ignoring this produces professionals who are very good at solving
things that do not happen.

**Transfers well**: enumeration method, tolerance of frustration, reading other people's code and
protocols, the habit of documenting, agility with the instrumentation, and the intuition of
"this smells wrong".

**Does not transfer**: the bias towards the exotic. CTFs reward the clever chain and the rare
trick because they have to be fun and have a unique solution. **Real work is
mostly broken authorisation, default configuration, credentials where they should not
be, missing patches and segmentation that does not exist** — boring findings with enormous
impact. A CTF with no "IDOR in the invoices endpoint" flags does not mean that finding is not
the most common and the most profitable in a real engagement.

**Nor does this transfer**:
- **Scope and restrictions**: in a CTF anything goes; in a real exercise there is a window, RoE,
  exclusions and stop conditions.
- **No harm**: in a CTF you can break the challenge; in production, breaking is the exercise's failure.
- **Communication**: real work is a report, justified severity, deconfliction and
  retest. You do not hand the flag to anyone.
- **Scale and noise**: in a CTF there are 5 services; at a client, 5000 assets and the problem is
  prioritising, not finding.
- **Defence**: the CTF barely teaches what telemetry you leave. Purple teaming does.

**Certifications and their real role**: they are a hiring filter, not a measure of
competence. **OSCP** is still the name recruiters filter by; since Nov 2024 it
coexists with **OSCP+**, valid for three years and renewable, while the "classic" OSCP is
for life. Its exam still has a ~24 h format plus report, with Active Directory mandatory,
**with no bonus points**, which raises the effective bar. **CPTS** (HTB) is markedly cheaper
and its 10-day exam is closer to a real engagement, at the cost of less formal
recognition. A 2026 signal about the institutional weight of these titles: ISC2 cut in April
2026 its list of certifications that waive experience for CISSP, removing OSCP from it.
Choose by the market you are aiming at and **verify price, format and validity policy at the
official source** (§8): they change frequently and the aggregators do not agree with each other.

## 7. Sustainability and prohibitions

### Cadence
- **Each platform's terms of service**: reread before publishing any writeup and at
  least annually. They are living documents (HTB's AUP changed in April 2026).
- **Event rules**: read them in full before each CTF. They are not presumed by analogy with
  another event.
- **Base VM**: rebuild from scratch periodically, do not chain snapshots indefinitely.
- **Lab tools**: update inside the lab and review provenance; check
  supply-chain incidents for what you install (§8).
- **Isolation**: re-verify after any change of hypervisor, home network or lab
  topology. A hypervisor update can re-enable shared folders.

### FORBIDDEN

**Of this skill as a document**:
- ❌ Including **ready-to-use payloads**, weaponised exploits or solutions to specific challenges.
- ❌ Documenting **specific bypasses** of security products or detection evasion
  techniques for real use.
- ❌ Listing third parties' **default credentials**.
- ❌ Turning this into a cookbook: lab and learning method, not a walkthrough.

**Of the practice**:
- ❌ Practising against **any system that is not yours, not from a platform that authorises it or
  not from a CTF in progress**. No exceptions, no "just looking", no "it belongs to a company that no
  longer exists".
- ❌ Running challenge binaries or samples **on the host**, or in a VM with a bridged network, or with
  shared folders or clipboard enabled.
- ❌ Detonating without a **prior snapshot**, or continuing to use the VM after detonation without reverting.
- ❌ Storing real credentials, SSH keys, sessions or personal data inside the lab
  VMs.
- ❌ Connecting the lab to the home or corporate LAN, or sharing a broadcast domain with
  it.
- ❌ Installing the offensive arsenal on the work machine or using Kali as the host OS.
- ❌ **Attacking the platform's infrastructure**, other users, or launching DoS against
  any target (expressly forbidden by the platforms, inside and outside their network).
- ❌ Sharing flags, or publishing solutions to active content when the terms
  forbid it.
- ❌ Running commands from a writeup **without understanding them**, still less outside the lab.
- ❌ Uploading to public analysis services samples that may contain a real client's data
  or alert an active attacker.
- ❌ Using OSINT on real people with no engagement, consent or legal basis.
- ❌ Applying in production or at a client what is learned here without the written authorisation
  `offensive-security-standards` §1 requires.
- ❌ Confusing ranking, flags or certification with professional competence.
- ❌ Pinning from memory versions, platform status or terms of service without the
  verification of §8.

## 8. Mandatory web verification

Before recommending a platform, tool or version, or publishing anything:

1. **Terms of service and AUP in force** for every platform you are going to use, at its official
   source: what may be attacked, what may be published and about which content. Reference
   as of August 2026: **HTB**'s AUP in force since **1 Apr 2026**. **Pending
   verification**: the exact text of **TryHackMe's Acceptable Use Policy** (its clauses
   on infrastructure and writeups could not be confirmed in a primary source; the reading of
   "more permissive with walkthroughs" comes from observing the ecosystem, not from the document).
2. **Current status and model of the platforms**: that they still exist and with what access
   model. Verified as of August 2026: **PortSwigger Web Security Academy** active and free.
   **Pending verification**: current status, model and terms of **pwn.college**,
   **OverTheWire** and **OffSec Proving Grounds** — they were not confirmed in a primary source.
3. **The specific event's rules** before each CTF, including its policy on AI use.
4. **Current versions** of **Kali Linux**, **REMnux** and **FLARE-VM** at kali.org, remnux.org
   and the official FLARE-VM repository. **Pending verification**: no specific version was
   pinned in this document because the sources located were secondary and discrepant.
5. **Provenance and supply-chain incidents** of any tool you install
   — 2026 precedent: the **TeamPCP** campaign (March 2026) compromised widely deployed security
   and CI tooling. Security tooling is a priority target.
6. **Certifications**: price, exam format, validity and renewal policy on the issuer's
   official website. The data in §6 (OSCP/OSCP+ format, relative cost of CPTS, cut to
   the CISSP exemption list in April 2026) comes from secondary sources that
   agree but are **not contrasted against the official source**: reconfirm them before
   deciding on a purchase.
7. **Legal framework**: the criminal framing in §1 is indicative and may have changed; **it is not
   legal advice**. In case of any doubt about the lawfulness of a practice, consult
   a lawyer.
8. **Hypervisor escapes**: before detonating anything serious, check whether there is a known and
   unpatched escape vulnerability in your hypervisor's version. **Pending verification**:
   the state of hypervisor escape CVEs as of August 2026 was not reviewed.

If the web contradicts this document, **the web wins** — flag the discrepancy.
