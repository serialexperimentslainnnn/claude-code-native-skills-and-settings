---
name: offensive-security-standards
description: Use when scoping or running an authorized offensive engagement — Rules of Engagement and scoping documents, penetration test, red team, purple team or adversary emulation with MITRE ATT&CK, Caldera or Atomic Red Team, PTES / OSSTMM / NIST SP 800-115 / OWASP WSTG / MASTG methodology, DORA TLPT and TIBER-EU exercises, PCI DSS 11.4 testing, bug bounty and VDP safe harbor, deconfliction with the SOC, or writing the engagement report, evidence chain, severity rating and retest.
---

# Offensive security standards (pentest, red team, purple team)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **preparing, governing, running and closing an authorised offensive exercise** against
systems of the organisation or of a third party that has contracted the test: choice of exercise
type, Rules of Engagement and contract, reference methodology, reconnaissance with judgement,
secure operation of the offensive team, deconfliction with defence, report with evidence,
severity, retest and programme metrics. Triggers: "Rules of Engagement", "RoE",
"pentest scope", "red team", "purple team", "adversary emulation", "TLPT", "TIBER-EU",
"PTES", "NIST SP 800-115", "OWASP WSTG/MASTG", "ATT&CK Navigator", "Caldera", "Atomic Red
Team", "PCI DSS 11.4", "bug bounty", "VDP", "safe harbor", "pentest report", "retest",
"deconfliction", "stop condition".

### Hard precondition — non-negotiable

**Without written authorisation from the system owner, you do not proceed. There is no technical
exception, no urgency exception, and no "it is obvious they would want us to test it".** Before the
first network request there must exist **one** of these two things:

1. **Written and signed authorisation** by whoever holds authority over the assets:
   signed RoE with explicit scope, exclusions, time window, 24×7 emergency contacts,
   stop conditions and a no-harm clause (§3). If the asset is operated by a third party
   (cloud, hosting, SaaS, MSP), the client's authorisation **is not enough**: the operator's is
   also required, or compliance with its testing notification procedure.
2. **Your own lab environment, CTF or training platform** whose terms of service expressly
   authorise the activity → that is the domain of `ctf-lab-standards`,
   not of this skill.

Legal framing (Spain/EU, **indicative, not legal advice**): unauthorised access to an
information system and the interception of communications are
criminalised in the Spanish Criminal Code (arts. 197 bis and 197 ter, introduced by LO
1/2015 transposing Directive 2013/40/EU); computer damage, in art. 264.
**The owner's free, specific and informed consent is what makes the test lawful** — good
intentions are not a defence, and the law recognises no standalone "ethical hacking"
exemption. The technique used by a professional and by a criminal is
the same; the difference is the signed paper. **Every RoE, and in particular any doubt about
scope, jurisdiction or personal data, is validated with the legal department of both
parties.** Do not improvise the interpretation of the law.

**Not applicable**: see `ctf-lab-standards` (training in your own lab or on a platform with
permissive ToS, where authorisation is intrinsic to the environment and the goal is to learn, not
to deliver risk to a client), `appsec-standards` (**defensive** methodology: threat
modelling, vulnerability classes and their controls — the offensive side exploits them, the defensive side
prevents them and designs them out), `vulnerability-management-standards` (lifecycle of
third-party CVEs, CVSS/EPSS/KEV, SSVC, remediation SLAs and VEX — **it is the recipient of your
findings**, not the producer), `grc-compliance-standards` (regulatory framework, formal risk
acceptance, audit evidence, contractual obligation to test),
`identity-access-management-standards` (IdP design, OAuth/OIDC flows, PAM),
`cryptography-pki-standards` (algorithm and TLS assessment), `networking-standards`
(segmentation and firewalling that gets put to the test), `kubernetes-standards` (image
and admission hardening), `bash-linux-scripting-standards` (own tooling and automation),
`homelab-standards` (general personal lab: hardware, cost, self-hosting), the cloud and
language skills —among them `powershell-standards`, which **defers here** the offensive
techniques it forbids in its §7 (AMSI and *ScriptBlock Logging* evasion, obfuscation,
in-memory downloaders) and keeps the defensive criteria: script signing, JEA, *Constrained
Language Mode*, transcription and logging—, and `c-standards`/`cpp-standards` (they explain memory
vulnerability categories **in order to prevent them**; exploitation belongs here), `assembly-standards`
(it is a **defensive and engineering** skill — it sets when writing
assembly is justified and how it is maintained, and **explicitly declares that it includes no exploitation cookbook**
—shellcode, ROP gadgets, evasion—: that belongs here, with written scope and authorisation),
`solidity-standards` (it describes contract vulnerability classes **in order to
prevent them**; testing a third-party protocol requires explicit scope and permission and is governed by
this skill). Additionally: `detection-engineering-standards` (detection
rules, SIEM and analytic content — **shared boundary in purple team**: here the attack
telemetry is generated and the technique documented; there the detection is written and validated),
`incident-response-forensics-standards` (management of the real incident and forensics —
if during the exercise you detect a pre-existing compromise, you stop and escalate there),
`linux-hardening-standards`, `container-runtime-security-standards`.

## 2. Default decisions

> Verify on the web the status of each framework before citing it in a proposal or contract (§8).
> The following data is from August 2026 and expires.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Base report methodology | **NIST SP 800-115** as the process skeleton (planning → discovery → analysis → exploitation → post-testing) | It is the reference auditors require or accept. **Careful: it is still the 2008 edition, with no published revision** — it covers cloud, CI/CD and modern identity poorly: complement it, do not use it alone |
| Web technical methodology | **OWASP WSTG** (stable **v4.2**, Dec 2020; **v5.0 in development** in the repo) | Test cases referenceable by ID (`WSTG-v42-<cat>-<n>`) in the report. Always link to the **versioned** URL, never to `latest` or `stable` |
| Mobile technical methodology | **OWASP MASTG v2.0.0** (2026, first stable of the v2 refactor) + **MASVS v2.1.0** (Jan 2024, 8 categories) | The "L1/L2/R" levels are **no** longer in MASVS: risk is tiered by **MASTG profiles** (MAS-L1/L2/R). A report citing MASVS L2 is using the v1 model, withdrawn |
| Commercial procedure framework | **PTES** only as phase vocabulary | Without active formal governance and with aged technical parts (references to platforms that are already irrelevant, poor cloud and container coverage). Cite it for its 7 phases, not as a current technical standard |
| OSSTMM | **Not by default** | Still at **v3 (2010)**; v4 has been in draft for years and the new material is behind ISECOM membership. Useful if you need its **rav** metric or its multi-channel coverage (human, physical, wireless); otherwise it adds nothing |
| Technique taxonomy | **MITRE ATT&CK Enterprise v19.1** (v19 published 28 Apr 2026) | Common language with defence. Structural change in v19: **the Defense Evasion tactic splits into Stealth and Defense Impairment** — every earlier mapping, report or heatmap needs migration |
| Coverage visualisation | **ATT&CK Navigator** with layers versioned and stored in the exercise repo | A layer without the ATT&CK version annotated is useless within 6 months |
| Automated emulation | **Atomic Red Team** (Red Canary) for atomic detection tests; **MITRE Caldera** for chained campaigns | Atomic for continuous purple team (broad, mapped library); Caldera when an agent and a full chain are needed. **Verify release and project health before use** (§8) |
| Emulation of a specific adversary | **Threat intelligence first, TTPs after** | Emulating an actor that does not threaten the client is theatre. In TLPT the intelligence provider is mandatorily external |
| Severity | **CVSS v4.0 as input, never as output**, adjusted by demonstrated exploitability + exposure + business impact | See `vulnerability-management-standards` for the full model (CVSS-B vs CVSS-BTE, EPSS, KEV, SSVC). A report that sorts by base CVSS without context does not prioritise: it sorts panic alphabetically |
| EU financial sector | **TIBER-EU** (updated 11 Feb 2025 to align with DORA) as the route for the **TLPT** of DORA arts. 26-27 | The TLPT RTS was published on **18 Jun 2025** and applies from **8 Jul 2025**. The deadlines are triggered by the **authority's notification letter** (3 months for start-up documents, 6 for the scope), not by a universal date. **Purple teaming is mandatory** in DORA-aligned TIBER-EU |
| Payments | **PCI DSS v4.0.1 req. 11.4** | Internal and external **annually and after significant change**, both, not interchangeable; **segmentation** validation at least annually (more frequently for *service providers*); documented and industry-accepted methodology; testers with organisational independence. Confirm the exact wording with the QSA |
| Disclosure without a contract | **VDP with disclose.io-style safe harbor**; never unilateral testing | A public bug bounty programme **is** the authorisation, but only within its scope and its rules. With no programme and no contract there is no authorisation: the finding is reported, not pursued further |

### Which exercise, and when

| Exercise | Question it answers | When to choose it | When it is a mistake |
|---|---|---|---|
| **Vulnerability assessment** | Which known weaknesses do I have? | Broad, cheap, repeatable coverage; the base of a nascent programme | Selling it as a pentest. There is no exploitation and no chaining |
| **Penetration test** | Can it be exploited, and how far does it go? | Bounded scope (app, network, cloud, mobile, ICS), technical depth, compliance (PCI 11.4) | Expecting it to measure **detection** capability: it does not measure it, and the noisy pentester does not even try |
| **Red team** | Do they detect and respond to a realistic adversary with concrete objectives? | Mature programme, with an operating SOC and detection already in place | With immature detection: you spend budget to discover what an assessment told you for 1/10 of the cost |
| **Purple team** | What do we see, what do we not see, and which rule is missing? | Maximum return per euro in detection maturity; mandatory in DORA-aligned TIBER-EU | Confusing it with a red team "with hints": it is collaborative by design and is measured in detections created |
| **Adversary emulation** | Do we withstand the TTPs of the actor that actually threatens us? | There is sector-specific intelligence; an actor is emulated, not "a hacker" | Without threat intel: you emulate an irrelevant actor and validate nothing |
| **TLPT (TIBER-EU / DORA)** | Does the financial entity withstand an attack aimed at critical functions? | Significant entity notified by its authority | Treating it as a normal red team: there is a Control Team, mandatory external intelligence, and the authority can reject the exercise |
| **Bug bounty / VDP** | What does the crowd find continuously? | Continuous complement once maturity is reached | As a substitute for the pentest: coverage biased towards what pays and what is easy to demonstrate |

## 3. Rules of Engagement: the contract as an engineering artifact

The RoE are not preliminary paperwork: they are **the control document of the exercise**. If
something is not written there, it is not authorised. Minimum content, all explicit:

- **Parties and authority**: who signs and why they have authority over those assets. A signature
  from someone without authority = absence of authorisation.
- **Positive scope**: IP ranges, domains, applications, cloud accounts, identities, mobile
  apps, physical locations, personnel in scope for social engineering. **Enumerated**, not
  described ("everything in the domain" is not a scope).
- **Explicit exclusions**: fragile systems, unsupported legacy, medical or
  industrial devices, third parties, critical business windows (financial close, campaigns).
- **Third parties and providers**: which assets belong to a third party, who asks them for permission, and what
  prior notification procedure each cloud or hosting provider requires. A third-party asset
  **without its authorisation is out of scope**, even if the client uses it.
- **Time window**: dates and **time slots**. Outside the window nothing is touched.
- **Authorised and forbidden techniques**: social engineering yes/no; phishing within what limits;
  physical access; wireless; credential attacks and their account-lockout limit; **DoS and
  resource exhaustion testing: forbidden unless explicitly and separately authorised**.
- **Testing in production**: if testing happens in production (the norm, because preproduction does not
  represent the risk), set rate limits, prohibition on modifying/deleting data, and a
  rollback procedure for any change.
- **Personal data and real data**: what to do if PII, medical records,
  payment data or secrets are accessed. Default rule: **access is demonstrated, the data is not
  extracted**. Capture the bare minimum, redacted, and notify immediately.
- **Stop conditions** — the exercise halts and is escalated immediately upon:
  unavailability of a production service caused or suspected; corruption or loss of
  data; evidence of **prior compromise by a real third party**; unintended access to a
  system out of scope; critical finding with trivial exploitation and internet exposure;
  impact on physical or personal safety; a stop request from the client.
- **Escalation and contacts**: names, phone numbers and 24×7 backups on both sides; emergency
  channel **out of band** (not the client's corporate email, which may be
  precisely what you are compromising or what the real attacker is watching).
- **No-harm and minimum-intrusion clause**: the test demonstrates the risk with the least
  possible impact; always choose the least destructive PoC that evidences the finding.
- **Deconfliction**: procedure and keyword so the SOC can distinguish your activity from
  a real attack, and vice versa (§6).
- **Ownership, custody and destruction of data**: who owns the findings and evidence,
  encryption, maximum retention and **certified destruction date**.
- **Confidentiality and publication**: NDA, and whether an anonymised case may be published.
- **Professional liability insurance** of the provider and limits of liability.

**Golden rule**: faced with any ambiguity about whether something is in scope, **it is out**
until it is clarified in writing. A scope extension is documented as a signed addendum,
never by chat message nor "verbally with the technician".

## 4. Quality of the offensive work

What separates a professional exercise from playing with tools.

### Reproducibility
- Each finding is documented with **exact steps, preconditions, account used, UTC time and
  expected result**. If the defender cannot reproduce it, they cannot verify the closure and
  the finding gets disputed.
- **Log all activity**: command log with timestamp and source IP. It is what
  lets you answer "was that you at 03:14?" during and after the exercise, and what
  exonerates you if something breaks for another reason.
- A tool that is run against production **is understood first**: what requests it sends,
  at what rate, what it writes and what it can break. Running a scanner with an aggressive profile against a
  fragile system without knowing it is negligence, not bad luck.

### Evidence chain of custody
- Minimum sufficient evidence: cropped and **redacted** screenshot, hash of the artifact, not the
  full dump of a database.
- **Encrypted at rest** storage, access limited to the exercise team, inventory of
  what was collected and where it lives.
- **Certified destruction** on the agreed date, including copies on laptops, temporary
  buckets, operating infrastructure and SaaS tools.

### False positives
- **Nothing goes into the report without manual verification.** The raw output of a scanner is not a
  finding: it is a hypothesis.
- Discard criteria: not reproducible in two attempts, mitigated by a control that does
  exist, or not applicable given the configuration → it is discarded and **the discard is documented** (it prevents
  it reappearing in the next exercise as something new).
- When it cannot be exploited due to a scope or RoE limit but the weakness is real: it is
  reported as an **unconfirmed finding**, with that label and the reason. Honesty over
  spectacle.

### Peer review
- **No report is delivered without review by a second operator**: severity, reproduction,
  wording, and a check that no PII or real credentials remain in the document.
- Specific review of the **severity justification**: every critical and high must withstand
  the question "why is it not a medium?" with business impact, not with adjectives.
- Coverage QA: what of the scope was **not** tested and why (time, blocker, RoE). A report
  that does not declare what it did not look at is implicitly asserting something false.

## 5. Security of the offensive operation

During the exercise the offensive team is **the client's largest concentrated risk**:
it holds accesses, credentials and data that nobody else brings together. It is protected accordingly.

- **Isolated operating infrastructure with a defined lifecycle**: dedicated per
  exercise and per client, **never shared between clients**, stood up and destroyed with IaC,
  with an inventory of everything deployed. Hardened and patched: a compromised offensive
  infrastructure turns the exercise into a real breach.
- **Client data**: encrypted in transit and at rest, in storage controlled by the
  service provider (never on laptops without disk encryption, never in personal SaaS nor
  in a public LLM), with MFA and least privilege. Minimum retention and certified deletion.
- **PII found**: stop collecting, notify the agreed contact and document the
  exposure without copying the data. If there are indications of a breach with a notification obligation
  (GDPR), **the obligation to notify is the client's**; your duty is to inform them without delay.
- **Critical finding**: notified **immediately and out of band**, without waiting for the
  final report. An internet-exploitable critical held for three weeks "for the deliverable"
  is an indefensible decision.
- **Prior compromise detected**: immediate stop, notification of the emergency contact,
  preservation of the evidence without touching the system, and handover to incident response
  (`incident-response-forensics-standards`). Do not investigate someone else's incident yourself
  unless you are contracted for it: you contaminate the evidence.
- **Supply chain of your own toolchain**: 2026 has shown that security
  tools are the favoured target — the **TeamPCP** campaign (March 2026) compromised, through
  tag poisoning and residual credentials, several widely deployed CI/security tooling pieces,
  with secret theft, persistent backdoors and worm-like propagation. Operational
  consequence: pin dependencies and actions **by digest**, verify signature
  and provenance, run the tooling in an ephemeral environment without long-lived credentials, and
  **check on the web whether any tool you are going to use has a recent incident** (§8).
- **Accounts and credentials obtained** during the exercise: treated as classified client
  material. They are not reused outside the exercise, not kept after closure, and those
  created (users, keys, tokens) are **inventoried and withdrawn** in the cleanup phase.
- **Operator hygiene**: dedicated machine or exercise VM, not mixed with personal
  browsing nor with other clients' data; VPN and network egress identifiable and agreed with the
  client to allow attribution.

## 6. Operability of the exercise

### Planning
- Kick-off with the **three parties**: business (authorises and defines objectives), IT/operations (knows
  what breaks), and security/SOC (decides the degree of prior knowledge). Without IT in the room,
  the first service outage will be a contractual crisis.
- **Objectives in business language**, not technical: "can someone from the internet reach
  the payroll data?" instead of "test the DMZ". The objectives determine the scope, not the
  other way round.
- Honest sizing: if the assigned time does not cover the scope, the scope is cut or
  partial coverage is declared **before** signing. Selling impossible coverage is fraud.

### Communication during the exercise
- **Permanent channel** with the Control Team / point of contact, and an agreed cadence (daily in a
  pentest, milestones in a red team).
- **Immediate notification** of: exploitable critical, unavailability, a change made to a
  system, and each activation of a stop condition.
- **Decision log**: every extension, exception or one-off authorisation is recorded in
  writing in the exercise log and confirmed by the person granting it.

### Deconfliction with the SOC
- **Before starting**: hand the Control Team the **source IPs, ranges, domains and
  agents** used, plus an exercise keyword and a quick-query procedure. In a red team this
  information is held by the Control Team, not by the SOC, until the end.
- **During**: when the SOC detects something, it can ask over the deconfliction channel whether it is
  team activity. The answer is yes/no within minutes. **You never answer "no" to an
  activity that is in fact yours**: that turns an exercise into a false incident with a real cost.
- **Non-attributable activity is a finding, not noise**: if the SOC detects something that is not you,
  that is the most important thing the exercise has produced (see §5, prior compromise).
- **Deconfliction closure**: at the end, a joint session reconstructing the
  timeline — what you did, what they saw, what they did not see and why. **That cross-check is the deliverable
  of real value of a red team**, more than the list of flaws.

### Purple team and translation into detection
- Each technique executed is recorded with: **ATT&CK ID (with the matrix version)**, UTC
  time, host, account, and the telemetry it *should* have generated (log source, field).
- The exercise's output towards defence is a table **technique → prevented? / detected? /
  alerted? / responded to?**. The four columns are distinct: detecting without alerting is not
  detecting in practice.
- Detection gaps are delivered as **rule requirements**, not as written rules:
  the detection content is written and validated by whoever operates the SIEM
  (`detection-engineering-standards`). Writing the rule yourself without knowing the client's
  telemetry generates false positives that get disabled within a week.
- Re-run the technique **after deploying the detection** to validate it. A purple team that does not
  re-run has not closed the loop.

### Deliverable
- **Executive summary** in business language: what real risk exists, in which scenario and what
  has to be decided. No jargon, no CVSS, no tool names. One page.
- **Attack narrative**: the chain, not the list. Five chained mediums that lead to
  domain are a critical; the loose list of five mediums communicates nothing.
- **Findings**: description, reproducible evidence, **justified severity** (CVSS v4.0 +
  demonstrated exploitability + exposure + business impact; EPSS/KEV when the finding is
  a known CVE), and an **actionable recommendation** — root cause and concrete remedy, not
  "apply good practices".
- **Coverage and limitations**: what was tested, what was not and why. Explicit.
- **Retest**: included in the contract from the start, with a defined window. What is verified is
  **real closure**, not the declaration of closure. The retest result is annexed to the original
  report; a finding is closed when the retest confirms it, never before.
- **Cleanup and closure**: inventory of **everything** deployed (accounts, scheduled tasks,
  keys, files, implants, rules, hosts) with its withdrawal confirmed and signed by both
  parties. Whatever cannot be withdrawn is documented and handed to the client to remove.
- **Handover to vulnerability management**: the findings enter the queue of
  `vulnerability-management-standards` with an owner and an SLA; the report is not the end of the process,
  it is its input.

### Honest programme metrics
- They measure **defensive improvement**, not offensive output: coverage of ATT&CK techniques detected,
  time to detection and to containment per exercise, new detections deployed and
  validated, % of findings closed within SLA, and recurrence of the same root cause across
  exercises.
- **Vetoed**: number of vulnerabilities found, number of "domains compromised",
  and any metric that rewards noise or penalises the client for letting you find things.
  Root-cause recurrence is the metric that hurts most and serves most.

## 7. Sustainability and prohibitions

### Cadence
- **RoE and contract template**: annual review and after any incident during an
  exercise; legal validation whenever the applicable regulation changes.
- **ATT&CK mappings**: review at each major release of the matrix. v19 (Apr 2026) split
  Defense Evasion into **Stealth** and **Defense Impairment**: every earlier heatmap, Navigator layer or
  report needs explicit migration, not automatic relabelling.
- **Methodologies**: verify on the web at the start of each exercise the current version of WSTG,
  MASTG/MASVS and ATT&CK that will be cited in the report (§8).
- **Toolchain**: quarterly review of health, licence and **supply chain
  incidents** of every tool in the arsenal.
- **Exercise frequency**: annually and after significant change as the floor (PCI DSS
  11.4 requirement); triennial for TLPT under DORA; continuous for purple team and bug bounty. The frequency is
  set by the system's rate of change, not by the audit calendar.

### FORBIDDEN

**Of this skill as a document** (editorial criteria, not a footnote):
- ❌ Including **ready-to-use payloads**, weaponised exploitation chains or exploit code.
- ❌ Documenting **concrete bypasses** of a named security product (EDR, WAF, MFA).
- ❌ Listing third parties' **default credentials** or where to find them.
- ❌ Collecting **detection evasion techniques** for real use outside an authorised
  and documented exercise.
- ❌ Turning this into a cookbook. **Methodology and governance**: the technical "how it is done" lives
  in the methodologies cited and in training, under authorisation.

**Of the operation**:
- ❌ Touching anything **without written authorisation** or outside the agreed window or
  scope. No exception, no urgency that justifies it.
- ❌ Accepting a scope extension verbally, by chat, or from someone without authority.
- ❌ **Running a tool against production without understanding what it does**: what requests
  it sends, at what rate, what it writes, what it can break.
- ❌ DoS, resource exhaustion testing or destructive attacks without explicit, separate
  and written authorisation.
- ❌ **Exfiltrating real client data "as proof"**. Access is demonstrated, the data is not
  extracted. Never mass dumps, never full PII, never to your own infrastructure.
- ❌ Leaving **artifacts, accounts, tasks, keys or implants unwithdrawn and undocumented**.
  Each one is a back door that you left behind.
- ❌ Reusing operating infrastructure or credentials between clients.
- ❌ Keeping client data, evidence or credentials past the agreed destruction
  date, or in personal storage, an unencrypted laptop or public SaaS/LLM.
- ❌ Hiding or delaying a critical finding, an unavailability you caused or a pre-existing
  compromise detected.
- ❌ Denying, under deconfliction, an activity that is in fact yours.
- ❌ Continuing the exercise after a stop condition has triggered.
- ❌ Putting raw scanner output into the report without manual verification, or severities
  inflated to justify the price.
- ❌ Testing third-party assets (cloud, SaaS, provider) without their authorisation or without following their
  notification procedure, even if the client uses and pays for them.
- ❌ Using at a client what was learned in a CTF without checking that the technique is applicable, non-
  destructive and within the RoE (see `ctf-lab-standards`).
- ❌ Presenting a vulnerability assessment as a pentest, or a pentest as a red team.
- ❌ Pinning versions of matrices, guides or regulations from memory without the verification of §8.

## 8. Mandatory web verification

Before citing any framework, version or deadline in a proposal, RoE or report:

1. **ATT&CK**: current version of the Enterprise matrix and of the Navigator, and changelog of the
   latest major release (as of August 2026: **v19.1**, after v19 of 28 Apr 2026 with the split of
   Defense Evasion). Always note the version used in the report.
2. **OWASP**: whether **WSTG v5.0** has left development (stable as of August 2026: **v4.2**), and
   current versions of **MASTG** (**v2.0.0**) and **MASVS** (**v2.1.0**).
3. **NIST SP 800-115**: check on csrc.nist.gov whether a revision or draft later than
   the **2008** edition exists — as of August 2026 none is on record, and that is a data point worth
   reconfirming before basing a report on it alone.
4. **PTES and OSSTMM**: real maintenance status. As of August 2026, PTES without active formal governance
   and OSSTMM at **v3 (2010)** with v4 in draft for years. **Pending
   verification**: whether ISECOM has published OSSTMM 4 (the new material is behind membership and could
   not be confirmed from public sources).
5. **DORA / TIBER-EU**: TLPT RTS applicable from **8 Jul 2025**; TIBER-EU aligned since
   **11 Feb 2025**. Verify which national authority applies to the client, whether it has already adopted the
   aligned framework, and the deadlines triggered by its notification letter. The "first
   cycle" dates circulating in sector blogs (e.g. before 17 Jan 2028) **are not
   confirmed in an official source**: cross-check them with the NCA.
6. **PCI DSS**: current version and exact wording of req. 11.4 in the official document of the PCI
   SSC or via a QSA; blogs number the sub-requirements wrongly.
7. **CVSS / EPSS / KEV**: current version and status — **the owner of that criteria is
   `vulnerability-management-standards`**, which keeps it verified; consult it there instead
   of duplicating it here, and re-verify on the web if you are going to pin a decision on it.
8. **Arsenal tools** (including **Caldera** and **Atomic Red Team**): current release,
   licence, governance and, **mandatorily**, whether there is a recent supply chain incident
   — 2026 precedent: the **TeamPCP** campaign of March 2026 against security and CI tooling.
   No tool enters an exercise without that check. **Pending verification**:
   the latest Caldera release (the available reference, v5.3.0 of April 2025, comes from
   a secondary source and was not cross-checked against the repository).
9. **C2 frameworks and post-exploitation tools**: **not verified in this
   document** and deliberately not recommended by product — their choice is decided per
   exercise, against primary sources, and by checking licence, provenance and the project's
   support activity.
10. **Legal framework**: any legal assertion in §1 is validated with the legal department
    of both parties and against the current text of the Criminal Code and the sectoral regulation. This
    skill **is not legal advice** and its framing may have become outdated.
11. **Safe harbor / VDP**: current terms of the specific programme before touching anything, and
    current status of the disclose.io references and of the platform's terms
    (HackerOne/Bugcrowd). A programme's scope changes without notice.

If the web contradicts this document, **the web wins** — flag the discrepancy.
