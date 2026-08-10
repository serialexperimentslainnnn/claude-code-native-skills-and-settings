---
name: windows-server-ad-standards
description: Windows Server and Active Directory Domain Services security standards. Use when working with AD DS forests, domains, OUs, sites and replication, Group Policy (GPO, gpresult, SYSVOL), Tier 0/Enterprise Access Model and Privileged Access Workstations, Domain Admins and AdminSDHolder, gMSA/dMSA service accounts, krbtgt rotation, Kerberos vs NTLM and Negotiate, SMB signing and LDAP channel binding, AD CS certificate templates, Protected Users, Windows LAPS, PingCastle, Purple Knight or BloodHound/SharpHound assessments, Microsoft Security Compliance Toolkit baselines, ntdsutil, dcdiag, repadmin, dsquery, Server Core, WSUS or Azure Update Manager patching, or AD forest recovery from system state backup.
---

# Windows Server and Active Directory standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, hardening, operating and recovering **the directory and the Windows Server
platform**: the on-prem AD DS vs Entra ID vs hybrid decision, forest/domain/OU/site design, tiered
administration model and PAW, privileged groups and delegation, service accounts, AD CS as a vector
for compromising the directory, Kerberos/NTLM authentication and its hardening, directory hygiene and
auditing, configuration baselines via GPO or Intune, OS operation and patching, secure PowerShell,
and **forest continuity and recovery**.

Triggers: `Active Directory`, `AD DS`, `ntds.dit`, `ntdsutil`, `dcdiag`, `repadmin`, `dsquery`,
`Get-ADUser`/`Get-ADDomain`/the `ActiveDirectory` module, `gpresult`, `SYSVOL`, `NETLOGON`, `GPO`,
`Domain Admins`, `Enterprise Admins`, `AdminSDHolder`, `adminCount`, `Protected Users`,
`krbtgt`, `SPN`, `gMSA`, `dMSA`, `msDS-ManagedAccountPrecededByLink`, `Kerberos`, `NTLM`,
`Negotiate`, `LmCompatibilityLevel`, `SMB signing`, `LDAP channel binding`, `ldapsigning`,
`AD CS`, `certsrv`, certificate templates, `Windows LAPS`, `LAPSAD`, `PingCastle`,
`Purple Knight`, `BloodHound`, `SharpHound`, `Security Compliance Toolkit`, `LGPO.exe`,
`Server Core`, `WSUS`, `Azure Update Manager`, `pwsh` vs `powershell.exe`, `JEA`, `WinRM`,
"forest recovery", "the DC is not replicating".

**Guiding principle**: **the forest is the security boundary, not the domain**, and **compromising
AD is compromising everything**. An attacker holding Domain Admin (or any of the dozens of
equivalent paths a real directory accumulates) has not compromised a server: they have compromised
the identity of the entire organisation, including that of the systems that "are not Windows" but
authenticate against it. Everything that follows is ordered by that asymmetry.

**Posture**: this skill is **defensive**. Attack techniques are described as a **risk class,
indicator and mitigation**, never as an exploitation procedure. The use of attack-path analysis
tooling (BloodHound) here is **the defender's**: seeing what the attacker sees in order to cut it
off. Authorised offensive work lives in `offensive-security-standards`.

**Not applicable**: see `identity-access-management-standards` (**modern federation is theirs**:
OAuth 2.1/OIDC, SAML, passkeys/WebAuthn and MFA policy, SCIM, RBAC/ABAC/ReBAC authorisation
engines, SPIFFE, generic PAM/JIT and break-glass as a pattern, the joiner-mover-leaver cycle.
**Here**: the **directory** —objects, OUs, GPOs, delegation, replication— and **Kerberos/NTLM** as
domain protocols, plus the concrete application of tiering and PAW on top of AD); `azure-standards`
(**Entra ID as the platform IdP**, Conditional Access, PIM, tenant governance and AKS — the
"AD DS or Entra" decision is taken here, tenant operation is there); `cryptography-pki-standards`
(**PKI as a design is theirs**: CA hierarchy, algorithms, HSM, key lifecycle and rotation,
ACME, mTLS. **Here, only the abuse of the directory through AD CS**: templates, enrolment
permissions, CA ACLs and the certificate↔account mapping. If the question is "which CA and with which
keys", it is theirs; if it is "who can request a certificate that impersonates an admin", it belongs here);
`linux-hardening-standards` (**the Linux parallel to which this skill is the Windows equivalent**:
CIS/STIG baselines, measurement with OpenSCAP/Lynis, auditd — same criteria, different OS);
`onprem-standards` (platform umbrella: hardware, hypervisor, OOB plane, fleet topology —
its invariants apply, and **the virtualisation hosting a DC is Tier 0 by definition**);
`networking-standards` (segmentation, firewalling between zones, DNS as a network service — here, the DNS
integrated into AD and the ports the domain requires); `detection-engineering-standards`
(**settled boundary**: *which AD event matters and why* belongs to this skill; *the
rule lifecycle* —ATT&CK coverage, tuning, thresholds, testing, SIEM— is theirs);
`observability-standards` (collection, retention and integrity of those events);
`incident-response-forensics-standards` (**the forensic process and the response to compromise**:
containment, imaging, timeline, eradication and mass credential rotation — **here, only which
directory artifact exists and what its recovery demands**); `incident-management-standards`
(incident governance); `bcdr-standards` (RTO/RPO, continuity plan and DR
exercises **for the organisation** — **forest recovery specifically belongs here**, as
a procedure intrinsic to the directory and not a server restore);
`vulnerability-management-standards` (triage, SLAs and EOL tracking);
`secrets-management-standards` (custody and rotation of application
secrets); `grc-compliance-standards` (the control demanded by ISO/ENS/NIST and its evidence);
`dotnet-standards` (the C# code running on top); `powershell-standards` (**a reciprocal and
constant boundary**: here we decide **what** is administered —forest, OUs, GPOs, Kerberos, gMSA, Tier 0— and **which
module and cmdlet** does it; **how the script is written** —approved verbs, `SupportsShouldProcess`
with `-WhatIf`, `Set-StrictMode`, error handling, `PSScriptAnalyzer`, Pester, JEA and signing— is
theirs. **Duplicating language criteria here is forbidden.**); `iac-standards` (Ansible/Terraform as
tooling); `cicd-standards`; `offensive-security-standards` and `ctf-lab-standards`
(offensive exercises with written scope and authorisation, and isolated labs — this
skill is defensive); `homelab-standards` (lab domain with proportionate criteria);
`container-runtime-security-standards` and `kubernetes-standards` (the other platform whose compromise
is total — same layered containment criteria, different domain).

## 2. Default decisions

> Verify the latest version, EOL date and feature status on the web before pinning it (§8). In
> this domain, memory fails especially badly with NTLM, WSUS, LAPS and support dates.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| On-prem AD DS? | **Only if there is a real dependency that demands it** | These justify your own domain: applications that only speak Kerberos/LDAP/NTLM, file and print servers, GPO over machines Intune cannot manage, OT/industrial, a requirement to operate without connectivity. **These do not justify it**: "we have always had it", mail, VPN, modern web SSO or laptop management — all of that lives better in `identity-access-management-standards`/`azure-standards` |
| Hybrid | **It is the real state of almost everyone**, and it must be **designed**, not left to happen | The risk of hybrid is **plane fusion**: an account with privilege in AD that also holds it in the tenant turns an on-prem compromise into a cloud compromise. Privileged cloud accounts **only in the cloud** and vice versa; the synchronisation server is **Tier 0** |
| OS version | **Windows Server 2025** for new deployments and for DCs | Verified Aug 2026: GA 1 Nov 2024, mainstream support until **13 Nov 2029**, extended until **14 Nov 2034**. **Server 2016 dies on 12 Jan 2027** (urgent migration) and **Server 2022 leaves mainstream support on 13 Oct 2026** (still patched, no new functionality). Server 2019 in extended support until 9 Jan 2029 |
| Installation | **Server Core** for DCs and infrastructure roles | Less surface, fewer patches, less "somebody browsed the web from the server". GUI only when justified by an application dependency |
| Functional level | The highest supported by **all** DCs, plus a plan to raise it | Recent security features (including those for Kerberos and service accounts) depend on the functional level, not just on the DC version |
| Administration model | **Enterprise Access Model** (*control* / *management* / *data-workload* planes) as the framework, with the **AD tier model (Tier 0/1/2) as its on-prem implementation** | Verified Aug 2026: Microsoft **has not retired the tier model**; it reclassified it as *legacy guidance* and documents it as an **EAM component**. Where there is no cloud migration, the tiered approach remains a high-priority recommendation. **The three rules have not changed**: (1) a higher-tier credential is never exposed on a lower-tier system; (2) the lower tier consumes services from the higher one, never the other way round; (3) **whoever can manage a system belongs to its tier, like it or not** — including the hypervisor, the backup and the management tool |
| Administration workstation | Dedicated **PAW** for Tier 0, with no mail, no browsing, no office software | Without a PAW, tiering is a diagram: the admin credential ends up typed into the machine used to read attachments |
| Service accounts | **gMSA** by default (password managed by the domain, automatic rotation, no human-held secret) | The user account with an SPN and a static password is the most profitable structural vulnerability in the directory. **dMSA**: see §3.4 — introduced in Server 2025, with a known security history; adopt it with the mitigation applied, not by default |
| Local admin password | **Windows LAPS** (built into the OS) | Verified Aug 2026: **legacy LAPS is deprecated**, its MSI **blocked** on Windows 11 23H2+ and receiving no code changes; it is supported only until the EOL of the OS where it was already installed. Windows LAPS adds **backup to Entra ID, password encryption in AD, history and management of the DSRM password on DCs** — the latter matters directly for §3.9 |
| Configuration baseline | **Microsoft Security Compliance Toolkit** (versioned baseline + `LGPO.exe`), applied via **GPO** on domain servers and via **Intune** on modernly managed estate | Verified Aug 2026: SCT is still the supported route (SCM is retired); current Server 2025 baseline **v2602 (Feb 2026)**, with an accelerated revision cadence since v2506. It complements —does not replace— CIS or STIG where there is a formal requirement |
| Patching | **Planned transition off WSUS** | Verified Aug 2026: **WSUS has been deprecated since 20 Sep 2024** (no new functionality and no new feature requests) **but it is not dead**: it still ships with Server 2025, publishes updates, underpins the ConfigMgr Software Update Point and **has no announced end date** (it inherits the Server 2025 cycle, through 2034). Microsoft's recommended replacement is **split in two**: **Intune/Windows Autopatch** for clients and **Azure Update Manager** (via Arc for non-Azure) for servers. **There is no 1:1 substitute** |
| PowerShell | **7.6 LTS** for new automation; **Windows PowerShell 5.1 is kept**, not uninstalled | Verified Aug 2026: **7.6 LTS** (18 Mar 2026, on .NET 10) supported until **14 Nov 2028**; **7.4 LTS and 7.5 both die on 10 Nov 2026** along with .NET 8 — jumping from 7.4 to 7.5 buys no time. 5.1 has no EOL of its own: it follows the OS cycle |
| Measured hygiene | **PingCastle** (score and trend) + **Purple Knight** (exposure and compromise indicators) | Both free for self-assessment. **PingCastle**: acquired by **Netwrix**, Open Source edition under **NPOSL-3.0** (internal use yes, monetising or auditing third parties no, that requires a commercial licence) and it **expires per version** — once a version reaches end of support, the binary stops running (3.3.0.0 expired on 31 Jan 2026): plan the upgrade as a recurring task. **Purple Knight** (Semperis): Community 5.0, 210+ indicators, mapping to MITRE ATT&CK and ANSSI, GCC High support since Apr 2026 |
| Attack paths | **BloodHound Community Edition** (Apache-2.0, SpecterOps) used **defensively**, recurrently | It is the tool with which the defender sees the real privilege graph —what the attacker sees— and **cuts the edges**. The measure of success is not the report: it is the reduction in the number of paths to Tier 0 between runs. BloodHound Enterprise adds continuous coverage of AD, Entra, AWS and Okta |
| External reference guidance | **"Detecting and Mitigating Active Directory Compromises"** (Five Eyes: ASD/ACSC, CISA, NSA, CCCS, NCSC-NZ, NCSC-UK) | Verified Aug 2026: published on **26 Sep 2024**. 17 observed techniques with their mitigations, covering AD DS, AD FS and AD CS. It is the best single free reference in the domain; use it as a work plan |

## 3. Design, hardening and operation

### 3.1 Directory design

- **The forest is the security boundary. The domain is not.** An extra domain "for security"
  provides no separation: whoever is admin in a domain has a path to the forest. If you need real
  separation (a different legal entity, a regulatory requirement, an isolated network), it is
  **another forest**, with selective trust, SID filtering and a written reason.
- **One domain, one forest, by default.** Inherited multiple domains almost never survive a
  cost/benefit analysis: consolidating reduces surface, replication complexity and
  escalation paths.
- **OUs by administrative function, not by org chart**: the OU is the unit of delegation and of
  GPO application. An OU tree that copies the org chart produces absurd delegations and GPOs
  impossible to reason about. Explicit OU separation by **tier** (Tier 0/1/2) so that
  privilege is visible in the structure.
- **Sites and replication** modelled on the real network topology (registered subnets, link
  costs, windows). Classic symptom: slow or erratic authentication because subnets are not
  associated with a site and clients pick a remote DC.
- **AD-integrated DNS** with zones replicated to the forest or the domain according to scope; no
  forwarders to uncontrolled resolvers and **with each DC's DNS pointing at the others, never at
  itself as the only server** (it blocks replication at boot). Correct delegation of the
  `_msdcs` zone, or DC location fails in ways that are hard to diagnose.
- **Trusts**: as few as possible, one-way where that suffices, **selective** and with **SID filtering
  enabled**. A two-way trust with filtering disabled turns two forests into one as far as
  compromise is concerned. Inventoried and reviewed: trusts are debt nobody remembers
  taking on.
- **DCs are Tier 0 and nothing else**: no additional roles (no IIS, SQL, file shares, applications,
  hypervisor, backup or unapproved agents), no Internet browsing and no general
  outbound access. **Everything that manages a DC is Tier 0**: hypervisor, storage, backup, EDR, PXE,
  deployment tooling and the management console. That inventory is usually the most
  uncomfortable finding of an honest assessment.

### 3.2 Tiering, PAW and the administration plane

- **Tier 0** = everything that can control the directory (DCs, AD CS, ADFS, the Entra
  synchronisation server, identity managers, directory backup, the virtualisation that
  hosts them). **Tier 1** = servers and applications. **Tier 2** = user workstations.
- **Administrative accounts separated by tier**, with no mailbox, no browsing, no interactive use
  outside their plane. One person = several accounts; one account = one tier.
- **PAW** for Tier 0 (and for privileged cloud administration), hardened with its own baseline,
  secure boot, encryption, no mail or general browser, with access only to the destinations of its
  tier. Without a PAW there is no tiering.
- **Logon containment**: deny by GPO interactive, service and batch logon
  for Tier 0 accounts on Tier 1 and Tier 2 (and reciprocally where applicable). It is the control
  that makes rule 1 effective. `Authentication Policy Silos` and **Protected Users** reinforce it.
- **Zero standing access**: elevation with approval and a short window, on-prem too. The generic
  PAM/JIT pattern belongs to `identity-access-management-standards`; **here, its application to the
  directory**.
- **Golden operational rule**: if a Tier 0 credential has ever been used on a lower-tier
  system, it is considered compromised. There is no middle ground and no "it was only for a moment".

### 3.3 Groups, privilege and delegation

- **`Domain Admins`, `Enterprise Admins` and `Schema Admins` empty in normal operation.**
  Membership is an elevation event with a ticket, a window and an alert, not a state. Same for
  the domain's `Administrators`, `Backup Operators`, `Account Operators`, `Print Operators` and
  `Server Operators`, which are Tier 0 de facto because of their privileges and are almost never needed.
- **Granular delegation per OU** instead of membership of privileged groups: user creation,
  password resets, domain join, computer management. Documented and **audited** — delegated
  ACLs accumulated over 15 years are the substrate of most escalation paths.
- **`AdminSDHolder` and `adminCount`**: the template that reimposes ACLs on protected groups every
  hour (SDProp). Two practical consequences: (1) **modifying `AdminSDHolder` is a persistence
  route** — its ACL is audited and changes are alerted on; (2) orphaned objects with `adminCount=1`
  (accounts that left a protected group and keep the ACL and broken inheritance) are
  dangerous noise: clean them up.
- **`SeEnableDelegationPrivilege`, `DCSync` (Replicating Directory Changes All), `WriteDACL`,
  `GenericAll`, `WriteOwner` over higher-tier objects**: these are equivalent to Domain Admin
  even if nobody calls them that. **Inventory them and cut them**; it is exactly what the BloodHound
  graph reveals.
- **Protected Users**: membership for all privileged accounts. It forces Kerberos (no NTLM,
  no delegation, no weak ciphers, no credential caching), at the cost of breaking legacy
  flows — deploy it in rings and validate the dependencies. **Careful**: it does not apply to service
  accounts that need delegation, and it does not protect the account if the DC is not up to date.
- **Service accounts**: **gMSA** by default. Every user account with an SPN and a static password
  is a finding — its password is *offline-crackable* by any domain user (risk
  class: mass service ticket requests). If a dependency prevents migration: a long,
  random password (≥25 characters), real rotation, least privilege, **never** in privileged
  groups and **never** with unconstrained delegation.

### 3.4 dMSA: adopt it with the mitigation in place

- **What they are**: *delegated Managed Service Accounts*, introduced in **Windows Server 2025**, which
  extend gMSA by adding **migration of an existing unmanaged service account** to a
  managed account, bound to a machine identity.
- **Known risk — BadSuccessor** (Akamai, Yuval Gordon): **abuse of the migration functionality**,
  not a memory bug. Risk class: whoever can **create objects in an OU** can
  create a dMSA and **link it to a privileged account** through the migration attributes
  (`msDS-ManagedAccountPrecededByLink`, `msDS-DelegatedMSAState`), obtaining from the KDC tickets carrying that
  account's SIDs — **without touching its groups or its credential**. Verified Aug 2026: it works in
  a default configuration, and in **91 %** of the environments Akamai analysed there were accounts
  outside Domain Admins with the necessary permissions. **A single Server 2025 DC in the
  forest is enough to be exposed.**
- **Mandatory mitigation before introducing the first Server 2025 DC**:
  1. **Restrict creation of `msDS-DelegatedManagedServiceAccount` objects** to a designated
     administrative group, reviewing **who can create objects in each OU** (which is the permission
     that almost nobody audits).
  2. **Audit SACL on dMSA creation** (**event 5137**) and on modification of its
     migration attributes; alert on creation by an unexpected identity or from an unexpected location.
  3. Consider **blocking the migration use case at the forest schema level** (method
     published by Semperis) if you are not going to use the functionality.
- **Rule**: dMSA **is not the default**. gMSA is. dMSA is adopted when its migration brings real
  value and with the three controls above verified.

### 3.5 AD CS: the PKI that compromises the directory

- **Boundary**: PKI design (hierarchy, algorithms, HSM, key lifecycle) belongs to
  `cryptography-pki-standards`. **Here, the abuse of the directory through AD CS.**
- **Families of vulnerable configuration** (risk class and mitigation, without procedure):
  - **Template that lets the requester set the subject** (`Enrollee Supplies Subject`) with a client
    authentication EKU and enrolment open to low-privileged users → **impersonation of
    any identity, including an administrator's**. *Mitigation*: remove the flag, or restrict
    enrolment and require certificate manager approval.
  - **Template with an "any purpose" EKU or no EKU** and broad enrolment → a certificate
    usable for authentication. *Mitigation*: explicit and minimal EKU per template.
  - **Write or ownership permissions over the template** held by unprivileged groups →
    the attacker **creates** the vulnerable configuration. *Mitigation*: audit the owner and ACL of
    **every** template, not just the published ones.
  - **CA-level configuration that allows the subject alternative name to be specified regardless of
    the template** → it turns safe templates into exploitable ones. *Mitigation*: disable it and audit
    the flag.
  - **Excessive permissions over the CA itself** (CA management / certificate management) → arbitrary
    issuance and approval. *Mitigation*: separation of duties between PKI and AD
    administration; the CA is **Tier 0**.
  - **Web enrolment and endpoints exposed without TLS or channel protection** → authentication
    relay towards the CA. *Mitigation*: HTTPS, Extended Protection for Authentication, and
    removal of the endpoints that are not used.
- **Strong certificate↔account mapping**: verified Aug 2026, the **KB5014754** cycle is **closed**
  — DCs moved to **full enforcement in February 2025** and in **September 2025 Microsoft
  removed the ability to go back to compatibility mode**. Consequences: a certificate without the
  SID extension **does not authenticate**; smart cards, 802.1X, VPN and devices
  enrolled via third-party SCEP that do not include the SID break. **It requires all DCs on Server 2019+.**
  This raises the bar considerably against SAN impersonation, but **it does not replace template
  hygiene**: the other vectors are still alive.
- **Continuous auditing**: an inventory of published templates with their flags, EKUs, enrolment
  permissions and owner; alert on issuance of authentication certificates for
  privileged accounts. It is one of the best effort/risk reviews in the domain.

### 3.6 Authentication: Kerberos, NTLM and the channel

- **Kerberos is the protocol; NTLM is debt.** Verified Aug 2026, precisely (it is the datum
  most often misquoted from memory):
  - Microsoft **deprecated NTLM in July 2024** (recommendation: `Negotiate` or Kerberos). *Deprecated
    ≠ removed*: NTLM still works.
  - **NTLMv1 was indeed removed** as a protocol in **Windows 11 24H2 and Windows Server 2025**. Remnants
    of NTLMv1 cryptography survive in specific scenarios (e.g. MS-CHAPv2 in a domain environment);
    **Credential Guard** covers them and the changes under way only affect machines **without** Credential
    Guard.
  - The `BlockNTLMv1SSO` key (`HKLM\SYSTEM\CurrentControlSet\Control\Lsa\msv1_0`): deployed in
    **audit** mode since the Sep 2025 updates (event **4024** when NTLMv1-derived credentials
    are used), and Microsoft **flips the default to *enforce* in October 2026** unless
    you have set it yourself. **Action**: deploy it yourself in audit mode, collect and fix before that date.
  - On the way: **IAKerb** and **Local KDC** (Kerberos for local accounts and workgroup
    scenarios), expected in the second half of 2026, which remove common reasons for falling back to
    NTLM.
- **Realistic NTLM plan**: audit (the improved logs in 24H2/Server 2025 identify account,
  process, machine and IP, on client and server) → remove dependencies → restrict by policy
  (`Network security: Restrict NTLM`) in rings → block. Start with the **DCs**. A block without
  an audit phase is a guaranteed outage.
- **NTLMv1 and LM: forbidden** (`LmCompatibilityLevel` at the value that only allows NTLMv2 and rejects
  LM/NTLMv1 on client and server).
- **Kerberos delegation**:
  - **Unconstrained: FORBIDDEN**, no exceptions. A server with unconstrained
    delegation stores the TGT of whoever connects — including those of privileged accounts and **those of
    the DCs themselves**. It is a domain backdoor with a feature's name.
  - **Constrained** (to specific services) or **RBCD** (control at the resource, which is the healthier
    model) applied with judgement, inventoried and reviewed. **Careful**: whoever can write the resource's
    delegation attribute controls who can impersonate against it — that permission is privilege.
  - Sensitive accounts marked as *not delegable* and/or in **Protected Users**.
- **Channel hardening**, non-negotiable:
  - **Mandatory SMB signing** on client and server (required, not "if the other side wants it"), and
    **SMBv1 uninstalled**. Signing is what cuts off the relay risk class.
  - **LDAP with mandatory signing and *channel binding* (EPA)** on the DCs; **LDAPS** for whatever still
    queries in the clear; *simple bind* without TLS is forbidden.
  - Kerberos ciphers: **AES**; RC4 and DES retired by policy (checking first what breaks:
    old trusts and appliances are usually the blocker).
- **`krbtgt`**: its key signs every ticket in the domain. Risk class: whoever obtains it can
  forge arbitrary tickets and **survives a reset of every password**. Rules: **double
  rotation** (two changes, separated by more than the maximum ticket lifetime **and** by at least one
  full replication cycle verified to all DCs — doing them back to back invalidates valid tickets
  and causes an authentication outage), **scheduled** rotation (not only after an incident) and
  **mandatory** rotation on any suspicion of DC compromise. **Rotating `krbtgt` does not evict
  an attacker who retains other persistence mechanisms**: it is one step of eradication, not
  eradication.
- **Machine passwords**: automatic rotation every 30 days by default — **do not disable it**
  (a computer account with a frozen password is a long-lived static credential). Careful with
  VM restores: a reverted snapshot can desynchronise the password and break the machine's
  trust.
- **Modern password policy**: high length (passphrase), **no arbitrary periodic
  expiry**, **no composition rules**, with **blocking against a list of compromised passwords**
  (Entra Password Protection on-prem too, or an equivalent), *fine-grained password policies* for
  privileged and service accounts, and **MFA** on all administrative access (mechanisms and policy
  in `identity-access-management-standards`). Smart lockout against *password spraying*, which
  is the technique actually used.

### 3.7 Measured hygiene and continuous auditing

- **AD hygiene is measured with a score and a trend, not with opinions.** Minimum quarterly
  cadence, with the historical series visible:
  - **PingCastle**: risk score by category; useful for direction and for the conversation with
    the business. Watch out for per-version expiry (§2).
  - **Purple Knight**: exposure and compromise indicators, with mapping to ATT&CK and ANSSI.
  - **BloodHound CE**: the graph. The metric that matters is **how many paths reach Tier 0 and from
    how many source accounts**, and that this number **goes down** between runs. A report nobody
    turns into cut edges is theatre.
  - Collection with SharpHound/AzureHound treated as a privileged operation: who runs it,
    from where and **where the file ends up** (a dump of the domain graph on a laptop is a
    gift to the attacker). It is kept encrypted, with bounded retention.
- **Recurring structural cleanup**: inactive accounts and computers, orphaned `adminCount`, unnecessary
  SPNs, unused delegations, unlinked GPOs, forgotten trusts, members of privileged
  groups, "temporary" permissions from years ago. **AD's surface grows on its own**; if nobody
  prunes, the graph fills with paths.
- **Events that really matter** (what to watch; the rule lifecycle belongs to
  `detection-engineering-standards`, its collection to `observability-standards`):
  changes to privileged groups and to **`AdminSDHolder`**; creation or modification of **dMSA** and its
  migration attributes (**5137**); changes to certificate templates and **issuance of authentication
  certificates for privileged accounts**; creation or change of an **SPN**; modification of
  **delegation** attributes; **replication requested from a source that is not a DC** (an indicator of
  directory extraction); **NTLM** authentication towards DCs and use of credentials derived from
  **NTLMv1** (**4024**); lockouts and mass failures (*spraying*); logon of a Tier 0 account
  on a lower-tier system; GPO changes and writes to **SYSVOL**; creation of accounts and
  of trusts; `krbtgt` change; auditing being stopped or the security log being cleared.
- **DC logs leave the DC**: forwarded to the SIEM with integrity and retention sufficient to
  investigate months back — sophisticated actors persist far longer than the default
  retention. A log that only lives on the compromised DC is not evidence.
- **Advanced auditing configured by baseline** (detailed categories, not the legacy policy),
  including **command line in process creation** and **PowerShell script block
  logging**, with the SIEM verifying that it ingests them.

### 3.8 OS operation and PowerShell

- **GPO** remains the domain mechanism for joined servers and machines; **Intune** for the
  modern fleet. Deliberate coexistence, not accidental: define what each one governs and avoid
  settings in both places (silent win/lose). Baseline applied **and verified**, not
  merely linked (§4).
- **GPO as code**: exported, versioned and reviewed by PR; drift detection and detection of orphaned
  or unlinked GPOs. **Edit permissions on a GPO linked to Tier 0 are Tier 0.**
- **SYSVOL** is code execution across the whole fleet: its ACL, its scripts and its integrity are
  audited. Never passwords in scripts or in GPO preferences.
- **Secure PowerShell** (all four at once, or it does not count):
  - **Script Block Logging** and **Module Logging** enabled by GPO, with transcription to a protected
    location and forwarding to the SIEM.
  - **JEA** (Just Enough Administration) for delegated tasks: restricted endpoints with a bounded
    command set and execution under a virtual identity, instead of granting full
    administration.
  - **Remoting** only over an authenticated and encrypted channel, **with CredSSP forbidden** (it exposes
    credentials on the destination) and restricted by source; administration from a PAW.
  - **AppLocker or WDAC** in restrictive mode wherever possible, and **Constrained Language Mode** as
    a useful consequence of a well-implemented application control policy.
  - `pwsh` 7.6 LTS for new automation; **5.1 is kept** for documented dependencies.
    No policy should delete 5.1 "to modernise".
- **Server surface**: Server Core, minimal roles, **no browsing from servers**,
  host firewall enabled with explicit rules, local accounts managed by Windows LAPS,
  **Credential Guard** and **LSA Protection** enabled where the hardware allows (they are front-line
  controls against in-memory credential theft), and secure boot + BitLocker on DCs
  (especially in branch offices and on any DC that is not physically controlled).
- **RODC** for sites without physical security, with a restrictive password replication
  policy — but do not mistake it for a strong control: it is damage reduction, not isolation.

### 3.9 Continuity: the worst possible day

- **A normal backup is not enough.** Recovering a compromised forest **is not restoring
  servers**: it is a procedure of its own, long and fragile, that almost nobody has ever executed.
  The differences that make it distinct:
  - You restore the **system state** of one DC per domain, in **Directory Services Restore
    Mode (DSRM)**, **with the network isolated** to stop a compromised surviving DC from
    reinfecting or replication from propagating the bad state.
  - You must **clean up metadata** for all DCs that are not recovered, **seize the FSMO roles**,
    **invalidate the RID pool**, **rotate `krbtgt` twice**, rotate trust accounts and service
    credentials, and only then rebuild the remaining DCs **from scratch** (never
    restoring the other backups: they are promoted clean and replicate from the recovered one).
  - **The DSRM password is part of the plan** and you have to know it on the day of the incident: managed
    by Windows LAPS on the DCs (§2) and held in custody outside the domain.
  - All the necessary material —media, backup encryption keys, credentials, documentation,
    contacts— must be **outside the domain that has fallen**. A runbook hosted on a file server
    in the domain does not exist on the day it is needed.
- **Backups**: system state of **at least two DCs per domain**, in different locations,
  **encrypted**, **immutable/offline** (against ransomware, which today goes for the backup first) and
  within the **tombstone lifetime** of deleted objects — a backup older than that
  **is not restorable**, and that is the mistake discovered at the worst possible moment.
- **The AD Recycle Bin enabled** (recovery of deleted objects without restoring) is a
  distinct and complementary control: it covers accidental deletion, not compromise.
- **Mandatory rehearsal**: forest recovery tested in the **isolated recovery environment
  (IRE)** specified by `bcdr-standards` §3.6 —it is not a "lab": a lab protects the
  world from what runs inside it, an IRE protects what runs inside it from the world, and in particular
  from the compromised domain—, at least
  annually and after structural changes, with **measured time** and the runbook updated with what was
  learned. The full process is counted in days, not hours: if your RTO says otherwise, the RTO is
  fiction. The continuity framework and organisational RTO/RPO belong to `bcdr-standards`; **this
  procedure belongs here**.
- **If the compromise is domain-wide, the decision is not "clean or recover"**: the Five Eyes guidance is
  explicit that persistence in AD resists ordinary remediation and can last months or years.
  Plan for **recovery from a known good state**, and take the decision with the process in
  `incident-response-forensics-standards` and `incident-management-standards`, not in the heat of the moment.

## 4. Quality gates

1. **Hygiene measured with a score and a trend.** PingCastle and Purple Knight run at least
   quarterly, with the **historical series** published and an improvement target. A one-off score without
   a trend says nothing; a flat trend is a management finding.
2. **Attack-path graph with a reduction metric.** Recurring BloodHound CE runs, with the
   number of paths to Tier 0 and **evidence of edges cut** between runs. Every new path
   has an owner and a date.
3. **Forest recovery rehearsed** in the IRE (`bcdr-standards` §3.6), with **real measured time**, an updated
   runbook, the DSRM password verified and a check that the backup is within the
   *tombstone lifetime*. Without a rehearsal, it is explicitly declared that **there is no recovery
   capability**, and that goes up to the risk register.
4. **Baselines applied and verified.** Linking the GPO is not enough: the effective state on the host
   is checked (`gpresult`, a compliance tool, a scan) and the deviation is reported.
   The current SCT baseline for the OS version, with documented exceptions, with an owner and with
   an expiry date.
5. **Tiering gate**: no Tier 0 account logs on outside its plane, verified by
   querying the logs, not by written policy. A single occurrence is an incident and forces rotation of
   that credential.
6. **Privileged inventory reconciled**: members of privileged groups, permissions equivalent
   to DA (DCSync, WriteDACL, delegation), service accounts with SPNs, delegations, trusts and
   dangerous certificate templates — compared against what was approved. Any difference is a
   finding.
7. **NTLM coverage measured**: auditing enabled and **the number of NTLM authentications towards DCs
   falling**, with a target blocking date ahead of the October 2026 default change
   (§3.6).
8. **EOL inventory with no silent exceptions**: no out-of-support OS in the domain; those
   that remain, with ESU contracted, isolation and a retirement date (tracked in
   `vulnerability-management-standards`).

## 5. Security: where a domain is really lost

- **The three patterns that cause most compromises** are not exotic: (1) a privileged
  credential used on a user machine; (2) a service account with an SPN and a weak password
  reused with excessive privilege; (3) a forgotten delegated permission that grants control over a
  higher-tier object. None of them is fixed by buying a product.
- **AD is the number one target of an attack on an enterprise**, by accumulated design: permissive
  defaults, complex relationships, legacy protocols still alive and little native tooling to
  diagnose its security. Assume the attacker will enumerate the directory with **ordinary
  user credentials** — almost everything is readable by any member of the domain.
- **Hygiene > product**: a directory with Tier 0 empty, no unconstrained delegation, with gMSA and
  with sanitised certificate templates holds up better than one full of agents and with Domain
  Admins in daily use.
- **The administrator's workstation is the real weak link.** Without a PAW, everything else is paper.
- **Hybrid fuses planes unless you prevent it**: the synchronisation server, its accounts and the
  privileged cloud roles are Tier 0. Strict separation of privileged on-prem and cloud
  identities.
- **Assume compromise when designing detection**: the events in §3.7 exist to discover somebody
  who is **already inside**. If the SIEM does not ingest them and nobody looks at them, the directory is
  defenceless even if the score is high.
- **Patching priority**: the DCs first, always. An unpatched DC is the whole domain
  unpatched. (Recent precedent in the management ecosystem: **CVE-2025-59287**, critical RCE in
  **WSUS**, Oct 2025 — a compromised patching server distributes code to the whole fleet; treat it
  as Tier 0 or migrate off it.)

## 6. Operability

- **Monitoring the directory as a service**: replication health (`repadmin /replsummary`,
  `dcdiag`), inter-site lag, FSMO availability, space and state of `ntds.dit`, time
  (clock drift breaks Kerberos and is a classic incident cause), and authentication
  latency per site. Alerts on symptoms, not on every event.
- **Correct time hierarchy**: the root domain's PDC emulator as the source, synchronised with a
  trusted external origin; the rest by domain hierarchy. On virtualised DCs, **disable the
  hypervisor's time synchronisation** or it fights with the domain.
- **DC virtualisation**: `VM-GenerationID` support to avoid dangerous USN rollbacks,
  **never restore a DC from a snapshot** as a recovery method, and the hypervisor treated as
  Tier 0 (including its storage and its console).
- **Capacity and placement**: at least **two DCs per domain**, distributed, with at least one
  physically controlled; a site with a local DC where latency justifies it.
- **Tested runbooks**: FSMO seizure, metadata cleanup, `krbtgt` rotation,
  deleted object recovery, DC promotion and demotion, and response to "a DC has not replicated
  for N days" (replication silence is both a fault and a possible indicator).
- **Change management in the directory**: schema changes, functional level changes, trust changes and
  Tier 0 GPO changes are irreversible or nearly so. Window, approval, verified prior backup and a
  rollback plan — a schema change **cannot be undone**.

## 7. Sustainability and prohibitions

**Cadence**
- Measured hygiene (PingCastle/Purple Knight/BloodHound): **quarterly**, with a trend.
- Review of privilege, delegations, trusts, service accounts and certificate templates:
  **quarterly** for the privileged, half-yearly for the rest.
- Forest recovery rehearsal: **annually** at a minimum and after structural changes.
- Scheduled `krbtgt` rotation (double, with replication verification between steps).
- SCT baseline: review with each published revision (accelerated cadence since v2506) and with each
  new OS version.
- EOL retirement plan with a date: **Server 2016 → 12 Jan 2027** is a calendar milestone, not an
  intention.
- PingCastle upgrade before the end of support of the version in use (it expires and stops
  running).
- Migration off WSUS planned with a date, even though no EOL has been announced.

**FORBIDDEN**
- ❌ **Unconstrained Kerberos delegation**, on any server and for any
  reason.
- ❌ **Service accounts with a static password and an SPN**: they are migrated to gMSA. If they cannot be, a signed
  exception with a long password, real rotation and least privilege.
- ❌ **Domain administration accounts used daily**, or logging on to
  workstations, application servers or any system outside Tier 0.
- ❌ `Domain Admins`/`Enterprise Admins`/`Schema Admins` with permanent members in normal operation.
- ❌ **NTLMv1 and LM** enabled; SMBv1 installed; optional SMB signing; LDAP without signing or *channel
  binding*; *simple bind* in the clear.
- ❌ **Domain controllers with additional roles** (IIS, SQL, file shares, applications, hypervisor,
  backup) or **browsing the Internet**.
- ❌ **Out-of-support servers in the domain** without ESU, isolation and a retirement date.
- ❌ Certificate templates that let the requester set the subject with an authentication EKU and
  broad enrolment; write permissions on templates for unprivileged groups; a CA with
  the configuration that ignores the template when setting the subject alternative name.
- ❌ **dMSA in a forest with Server 2025 DCs without the BadSuccessor mitigation applied** (§3.4).
- ❌ **Legacy LAPS** in new deployments; local administrator passwords shared or identical
  across machines.
- ❌ Passwords in scripts, in SYSVOL, in GPO preferences, in scheduled tasks or in the
  description of AD objects.
- ❌ **CredSSP** in remoting; DC administration from a general-purpose workstation.
- ❌ Rotating `krbtgt` **twice in a row without waiting for** replication and the maximum ticket lifetime (it causes
  an authentication outage), or **not rotating it** after a suspicion of compromise.
- ❌ Disabling machine account password rotation; restoring a DC from a hypervisor
  snapshot.
- ❌ A directory backup that is unencrypted, without an immutable/offline copy, or **older than the
  *tombstone lifetime***.
- ❌ Declaring "we have an AD backup" **without a documented forest recovery rehearsal**.
- ❌ Two-way trusts with SID filtering disabled, or trusts with no owner and no review.
- ❌ Running collection tools (SharpHound) without control over where the dump ends up.
- ❌ Pinning EOL dates, NTLM retirement states, versions or feature names **from memory**,
  without the verification in §8.

### Quick review checklist (assessing an existing domain)

- [ ] Tier 0 identified **completely** (includes hypervisor, backup, PKI, Entra synchronisation) and isolated.
- [ ] Privileged groups empty in operation; elevation with ticket, window and alert; PAW in real use.
- [ ] Delegations, DA-equivalent ACLs and trusts inventoried and reconciled.
- [ ] Service accounts on gMSA; no user account with an SPN and a static password.
- [ ] No unconstrained delegation; RBCD/constrained inventoried; Protected Users for the privileged.
- [ ] AD CS templates audited (flags, EKUs, permissions, owner); CA treated as Tier 0.
- [ ] NTLM auditing enabled with a downward trend; NTLMv1/LM blocked; SMB and LDAP signing mandatory.
- [ ] Windows LAPS deployed, including the DSRM password on the DCs.
- [ ] SCT baseline applied **and verified** on DCs and servers; Server Core wherever possible.
- [ ] Script block logging, command line in process creation and forwarding of DC logs to the SIEM.
- [ ] PingCastle/Purple Knight/BloodHound with a historical series and paths to Tier 0 falling.
- [ ] System state backup of ≥2 DCs, encrypted, immutable, within the *tombstone lifetime*.
- [ ] **Forest recovery rehearsed** with measured time and a runbook outside the domain.
- [ ] No out-of-support OS; a dated plan for Server 2016 (12 Jan 2027).

## 8. Mandatory web verification

Before pinning any date, version, retirement state or feature name, **look it up — do not
recall it**. This domain is where memory gets it wrong most often:

1. **Windows Server lifecycle** (verified Aug 2026: **2025** GA 1 Nov 2024, mainstream until
   13 Nov 2029, extended until 14 Nov 2034; **2022** end of mainstream support 13 Oct 2026; **2019**
   extended until 9 Jan 2029; **2016** EOL **12 Jan 2027**; **23H2** already EOL since 24 Oct 2025).
   Confirm it against Microsoft's official lifecycle before planning migrations.
2. **NTLM retirement — the fact most often quoted from memory and worst remembered.** Verified Aug 2026:
   NTLM **deprecated** in Jul 2024 (not removed); **NTLMv1 removed** in Windows 11 24H2 and Windows
   Server 2025; the `BlockNTLMv1SSO` key in audit mode since Sep 2025 (event 4024) and a **default change
   to *enforce* expected in October 2026**; **IAKerb** and **Local KDC** announced for the
   second half of 2026. **Declared gaps**: it was not verified whether the October 2026 default change
   has been brought forward, delayed or already applied, nor the **actual availability status of IAKerb and
   Local KDC** at this date. Read it in Microsoft's support article for your build.
3. **dMSA and BadSuccessor** (verified Aug 2026: Akamai technique, abuse of the migration
   functionality, works in a default configuration, 91 % of analysed environments exposed).
   **Declared gap**: **it could not be confirmed whether Microsoft has already published a patch or behaviour
   change** — the sources consulted indicate that at the time none existed and that the response
   was configuration and detection. **Verify it before introducing a Server 2025 DC**; it is the
   point in this document most likely to have changed.
4. **Windows LAPS versus the legacy one** (verified Aug 2026: legacy **deprecated**, MSI blocked on
   Windows 11 23H2+, no code changes, supported only until the EOL of the OS where it was already installed;
   Windows LAPS available from Server 2019 and supported clients, with encryption in AD, history,
   backup to Entra ID and DSRM password management). **Declared gap**: it was not verified whether
   Microsoft has since announced a concrete retirement date for the legacy one.
5. **WSUS** (verified Aug 2026: **deprecated on 20 Sep 2024**, no new functionality, **no announced
   EOL date**, still included in Server 2025 and supporting the ConfigMgr SUP; the recommended
   replacement split between **Intune/Windows Autopatch** for clients and **Azure Update Manager**
   —with Arc— for servers; the driver synchronisation shutdown planned for Apr 2025 was
   postponed). **Declared gap**: the current status of that driver synchronisation was not confirmed.
6. **Strong certificate mapping (KB5014754)** (verified Aug 2026: **full enforcement since
   Feb 2025** and **removal of compatibility mode in Sep 2025**; requires all DCs on Server
   2019+). No later milestone was found in 2026; confirm it if you depend on smart
   cards, 802.1X or third-party SCEP.
7. **Enterprise Access Model and the tier model** (verified Aug 2026: the tier model is
   **reclassified as legacy guidance but still current**, documented as an EAM component, with a
   repository and deployment guide published by Microsoft). Check the current name and URL
   of the guidance before citing it in a deliverable: Microsoft has renamed and reorganised this material
   several times.
8. **Hygiene tools**: **PingCastle** (verified Aug 2026: acquired by **Netwrix**,
   Open Source edition **NPOSL-3.0**, internal use allowed, auditing third parties requires a commercial
   licence, **per-version expiry** — 3.3.0.0 stopped running on 31 Jan 2026) and
   **Purple Knight** (verified: Semperis, **Community 5.0**, free, 210+ indicators, GCC High
   support since 21 Apr 2026). **Declared gaps**: **the current PingCastle version as of Aug 2026
   and its next expiry date were not verified**.
9. **BloodHound** (verified Aug 2026: **Community Edition** free under **Apache-2.0**, maintained
   by SpecterOps; **Enterprise** covers AD, Entra, AWS and Okta; a **Scentry** offering for attack-path
   management programmes; recent releases include the fix for **CVE-2026-16221**).
   **Declared gap**: **the current CE version number was not verified**; check it on their releases
   page. Useful warning from SpecterOps themselves (Apr 2026): much of the training material and
   third-party documentation is out of date with respect to the current platform.
10. **Microsoft Security Compliance Toolkit and baselines** (verified Aug 2026: **it is still the
    supported route**, SCM retired; Windows Server 2025 baseline **v2602 of Feb 2026**, with an accelerated
    revision cadence since v2506; in Intune the baselines are consumed directly without importing,
    derived from the client baseline). **Declared gap**: it was not verified whether a revision
    later than v2602 was published between Feb 2026 and Aug 2026.
11. **PowerShell** (verified Aug 2026: **7.6 LTS** since 18 Mar 2026 on .NET 10, supported until
    14 Nov 2028; **7.4 LTS and 7.5 end on 10 Nov 2026** with .NET 8; **5.1 with no EOL of its own**, it follows
    the OS cycle). Verify the current servicing version before pinning it in a deployment.
12. **Five Eyes guidance "Detecting and Mitigating Active Directory Compromises"** (verified Aug 2026:
    published on **26 Sep 2024**, led by ASD/ACSC with CISA, NSA, CCCS, NCSC-NZ and NCSC-UK, 17
    techniques). **Declared gap**: **no later revision was located**; check whether an
    update has been released before using it as normative reference.
13. **CVEs in the management ecosystem and the directory**: verified precedent **CVE-2025-59287**
    (critical RCE in WSUS, Oct 2025). Before assuming a platform is safe, review Microsoft's
    bulletins and CISA's KEV catalogue for AD DS, AD CS, AD FS, WSUS and the management agent you
    use.
14. **Status of the applicable benchmarks** if there is a formal requirement (CIS for the exact version of
    Windows Server, DISA STIG, CCN-STIC/ENS). **Declared gap**: **the current versions of CIS and of
    STIG for Windows Server 2025 were not verified** as of Aug 2026. Remember that CIS goes by
    product version: never cite "the Windows Server CIS" generically.

If the web contradicts this document, **the web wins** — flag the discrepancy.
