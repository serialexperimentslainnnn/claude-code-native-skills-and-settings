---
name: bcdr-standards
description: Business continuity and disaster recovery as a program. Use for a business impact analysis (BIA), deriving RTO/RPO/MTPD from business impact rather than from what infrastructure can do today, mapping the dependency graph and the recovery sequence, choosing between backup-restore, pilot light, warm standby and active-active, multi-region or multi-cloud DR posture, who declares a disaster and under which activation criteria, crisis communication and alternate site, DR drills from walkthrough to live failover and failback, ransomware recovery with immutable or offline copies and backup infrastructure isolated from the production domain, building an isolated recovery environment (IRE) or clean room where restored systems are rebuilt and declared trustworthy before reconnection, identity-first recovery sequencing, SaaS and vendor dependency with exit and data-protection responsibility, encryption key escrow held outside the backed-up system, measured versus committed recovery objectives, ISO 22301 and ISO/TS 22317, and the continuity, backup and resilience-testing duties of DORA Articles 11-12 and NIS2 Article 21(2)(c).
---

# Business continuity and disaster recovery standards (BC/DR)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **continuity and recovery programme**: business impact analysis (BIA),
derivation of recovery objectives, recovery strategies and their cost, the dependency
chain and the **recovery order**, the plan as a living artifact and its activation criteria,
alternate site and people, exercises and their cadence, dominant design scenarios
(ransomware, site loss, outage of a critical third party), and the honest measurement of whether the plan
works.

Triggers: "BIA", "impact analysis", "RTO", "RPO", "MTPD", "MTO", "continuity plan", "BCP",
"disaster recovery plan", "DRP", "declare the disaster", "activate the plan", "alternate
site", "DR site", "pilot light", "warm standby", "active-active", "multi-region", "multi-cloud",
"recovery order", "dependency chain", "failover", "failing over",
"DR tabletop", "recovery drill", "ransomware recovery", "immutable copy",
"backup isolation", "directory recovery", "forest recovery", "isolated
recovery environment", "IRE", "clean room", "clean recovery environment",
"rebuild in isolation", "vendor exit", "ISO 22301", "DORA art. 11-12",
"NIS2 art. 21(2)(c)".

**Guiding principle**: **RTO and RPO are not chosen by whoever does the restoring, they are derived from the
business impact** — and if they are not derived from a BIA, they are wishes in the shape of a number. A double and
non-negotiable corollary: **an unrehearsed plan does not exist** and **a backup with no tested restore does not exist**
(invariant shared with `onprem-standards` §1.3).

**Not applicable**:
- `backup-recovery-standards` — **the most likely collision in the whole
  catalogue; a surgical boundary**: there lives the **mechanics** of backup (tool choice,
  repository, 3-2-1 topology, job cadence, deduplication, repository encryption,
  GFS retention schemes, integrity verification, catalogue, and the concrete restore
  procedure). Here lives the **plan and the why**: what is protected and with what objective derived from the
  business (RTO/RPO), in what **order** it is recovered, who declares the disaster, with what exercise it
  is demonstrated and what is communicated. Arbitration rule in one line: **"how is the copy made?" belongs to
  `backup-recovery`; "how much can we lose, in what order do we bring things up and who decides?" belongs to
  this skill.** Here only the principle (3-2-1, immutability, tested restore); **the mechanics are not
  developed here**, they are delegated to it.
- `incident-management-standards`: the incident management process — declaration, severity,
  Incident Commander, communication, postmortem. **The boundary is one of scale and is declared on both
  sides**: while the impact is recoverable within the service, it is an incident and that skill
  rules. When the continuity plan's activation threshold is crossed (§3.4), **the regime
  changes**: the IC hands command to the crisis director, the change is declared explicitly and with
  a timestamp in the channel, and from then on this document rules. The incident process does not
  disappear —it still governs communication and record-keeping— but it stops being the one that decides.
- `incident-response-forensics-standards`: the technical response to the compromise. Critical boundary in
  ransomware: **recovery does not start until eradication is verified**; restoring
  from a point later than the initial compromise also restores the attacker. The clean
  restore point is determined by the investigation, not by the hurry to get back. **Forensics is done in
  their analysis environment, not in the recovery one** (§3.6).
- `ctf-lab-standards`: a training and sample-detonation lab. **The isolated recovery
  environment (§3.6) is not that**: there the malicious is executed on purpose; here the working
  premise is that **nothing malicious is executing**.
- `sre-practice-standards`: **everyday** reliability — SLI/SLO, error budget and its policy, burn
  rate, on-call, capacity. **Boundary of regime**: the error budget governs the everyday and admits
  partial degradation; **RTO/RPO govern the disaster**, where the service is not degraded but
  absent. A service can meet its SLO all year and not survive the loss of its site:
  they are two different questions and **two different numbers**.
- `grc-compliance-standards`: **ISO 22301 as a certifiable management system**, SoA, risk
  register, audit evidence, contractual clauses and third-party register. Here, the
  **engineering of continuity**: the number, the chain, the exercise and its measurement.
- `privacy-engineering-standards`: boundary declared on both sides for **deletion**.
  The obligation to erase and its technical implementation (including reapplying deletions
  after a restore) belong to that skill; **the concrete retention window and the immutability of the
  repository belong to `backup-recovery-standards`** —this skill only sets the RPO from which it is
  derived—. Design that resolves the conflict: per-subject encryption from day 1.
- `onprem-standards`: platform umbrella — iron, hypervisor, physical redundancy, cluster
  topology. Its invariants (§1.3) rule and this document does not contradict them; its §6 marked as
  provisional exactly what is developed here.
- `ha-clustering-standards`: Pacemaker/Corosync, quorum, fencing, resources.
  **HA is not DR** (§3.1): HA absorbs the failure of a component within the same failure domain;
  DR assumes the entire domain disappears.
- `chaos-engineering-standards`: **the continuous, bounded resilience experiment is theirs**
  —steady-state hypothesis, fault injection, *blast radius*, abort conditions—;
  **the full DR drill —site failover, RTO/RPO, declaration— belongs here**. The line:
  if the continuity plan is being rehearsed, it belongs here; if a fault is injected to refute a
  hypothesis in normal operation, it is theirs.
- `windows-server-ad-standards`: the concrete procedure for recovering the
  Active Directory forest from a system state copy, Tier 0, `ntdsutil` and directory
  hygiene. Here, **its position in the recovery order** (§3.3), the criterion that without
  identity nothing is recovered, and the requirement to rehearse it.
- `data-platform-standards`: PITR, replication and failover of the data engine.
  `cryptography-pki-standards`: key management and custody. `networking-standards`: DNS,
  routes, addressing of the alternate site. `aws-standards`/`azure-standards`/`gcp-standards`:
  each provider's region, zone and replication primitives. `kubernetes-standards`: recovery
  of cluster state. `homelab-standards`: a personal lab, where the criterion is cost and not an
  RTO commitment.

**This is not legal advice**: the regulatory framing (§5) is engineering criteria for
designing systems that comply; the interpretation of the obligation is set by legal/compliance.

## 2. Default decisions

> Verify on the web the edition of the standard, the regulatory obligation and the state of tools before
> pinning them in a real project (§8). Data from August 2026.

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Starting point | **BIA before technology.** Without a BIA there are no RTO/RPO, there are opinions | Reference: **ISO/TS 22301:2019 + Amd 1:2024** (management system) and **ISO/TS 22317:2021** (BIA guidance, it is a *Technical Specification*: not certifiable) |
| Who sets RTO/RPO | **The business owner of the process**, with impact data (loss per hour, contractual, regulatory, reputational, personal safety) | **FORBIDDEN** for the technical team to set them "according to what we can do": that is a capability, not an objective |
| Granularity | By **business process**, propagated to the services that support it. A service inherits the strictest RTO of the processes it serves | RTO per server: it means nothing to anybody |
| Tiers | **3-4 tiers** with RTO/RPO per tier and an associated strategy, not a number per system | Every system with its own number: ungovernable and impossible to rehearse |
| Default strategy | **The simplest one that meets the derived RTO**, and no more | Active-active "because we are serious": it multiplies cost and complexity and adds new failure modes (partition, data conflicts) |
| Critical artifact | **The recovery order** with the complete dependency chain (§3.3) | It is the artifact almost nobody has and the one that decides whether the exercise succeeds |
| Disaster declaration | **A named person with a deputy**, written criteria, authority delegated by management | **FORBIDDEN** for the decision to require a meeting, a committee or tracking down whoever is on holiday |
| Minimum exercise cadence | **Half-yearly tabletop** + **annual partial simulation** + **annual real failover** of tier 1 services | Full annual if the tier justifies it; **never** less than one real exercise per year — it is what DORA explicitly requires of the financial sector (§5) |
| Dominant design scenario | **Ransomware** (including compromise of identity and of the backup system itself), above site loss | The "the data centre burns down" scenario is easier than the real one: do not use it as the only exercise |
| Backup copies | **At least one immutable or offline**, with the backup infrastructure **isolated from the production identity domain** | A backup reachable with domain administrator credentials = a backup the attacker deletes first |
| Where you restore after a compromise | **An isolated recovery environment (IRE)** with the three isolations —network, **identity** and management plane— (§3.6), pre-provisioned cold and with the **build time measured** within the RTO | On demand from IaC in a separate account by default; permanent and dedicated only if the RTO or the regulation requires it. **FORBIDDEN** to rebuild on the compromised domain or to administer the IRE with production credentials |
| Key custody | **Outside the backed-up system**, with a tested recovery procedure and separation of duties | An encrypted backup whose key only lives inside the lost system = total loss with extra steps |
| Third parties and SaaS | **Your provider being down is your disaster.** Every critical SaaS enters the BIA with its own RTO/RPO, its exit plan and **your own backup of your data** | Assuming the SaaS backs up your data for you: it does not (§5) |
| Verification | **RTO/RPO measured in an exercise, with real volumes**, published alongside the committed ones | "Estimated" numbers on a slide: they are discovered to be false on the day they matter |

## 3. The programme

### 3.1 The three things that are constantly confused

| | What it absorbs | What it does **not** absorb | Metric |
|---|---|---|---|
| **High availability** | Failure of a component within the same failure domain (node, disk, AZ) | Logical corruption, deletion, ransomware, loss of the whole domain — **HA replicates the error at network speed** | Availability, SLO |
| **Backup** | Corruption, deletion, malicious encryption, human error | The outage itself: having the copy is not having the service | RPO, restore time |
| **DR** | Loss of the complete failure domain (site, region, provider, identity) | Nothing, if the recovery order does not exist or has not been rehearsed | End-to-end RTO |

All three are necessary and **none replaces another**. The domain's most expensive confusion is
"we have a cluster, we are covered": a badly filtered `DELETE`, ransomware encryption or a
broken schema change are replicated to all three nodes in milliseconds.

### 3.2 BIA: the number comes from the business

For each process, with the business owner and in writing:

- **Impact per unit of time** (1 h, 4 h, 1 day, 1 week): financial, contractual (penalties,
  customer SLAs), regulatory, reputational and **personal safety**. The curve is not
  linear: there is almost always a knee, and the knee is what defines the objective.
- **MTPD/MTO** (maximum tolerable period of disruption): the point beyond which the damage is
  irreversible. **The RTO is set below the MTPD, with margin**, never equal to it.
- **RPO**: how much work can be redone or lost. Watch the hidden cost: an RPO of 24 h is not "a
  day of data", it is **a day of manual re-entry** with its own error rate, and that work
  also consumes the RTO.
- **Seasonality and critical windows**: accounting close, campaign, payroll, enrolment period. The
  same process can have an MTPD of a week in August and of two hours on the 30th.
- **Minimum resources to operate in degraded mode**: people, systems, data, providers,
  facilities. It includes the **alternative manual procedure** where one exists: for many processes
  it is faster to work on paper for twelve hours than to restore, and nobody has it written down.
- **Interdependencies**: which processes depend on this one and which ones it depends on. §3.3 is born here.

BIA output: **tiers**, RTO/RPO per tier, and the list of tier 1 services — which is short if the
exercise has been done honestly. If everything is tier 1, there is no BIA: there is a wish list.

### 3.3 The recovery chain: the artifact almost nobody has

No application starts on its own. The real order, almost always ignored until the first exercise:

```
0. People and out-of-band communication     (if you cannot convene, none of the rest happens)
1. Power, physical network, WAN connectivity (alternate site reachable)
2. Addressing, DNS and resolution            (everything else depends on resolving names)
3. Identity and directory                    (without authentication nothing can be administered)
4. Secrets management and PKI/certificates   (without secrets or certificates the service does not start)
5. Time (NTP)                                (clocks: Kerberos, TLS and logs depend on it)
6. Storage and databases                     (restore and integrity validation)
7. Compute platform (hypervisor/cluster/orchestrator)
8. Application services by tier, in dependency order
9. Third-party integrations and reactivation of inbound flows
10. Functional verification with the business and communication of restoration
```

Rules:
- **The chain is documented as a dependency graph, not as a wish list**, and it is **validated in
  the exercise**: the exercise exists precisely to discover that step 8 needed something from
  step 3 that nobody had noted.
- **Circular dependencies**: the classic case is the secrets manager that authenticates against the
  IdP that needs a secret from the manager. They are detected by drawing the graph and broken with a
  documented cold-start path (a break-glass credential in physical or sealed custody, outside
  both systems).
- **The plan's self-reference**: the runbook, the inventory, the network documentation and the contact
  list **cannot live only in the system that goes down**. A copy out of band, accessible without
  corporate SSO, and **tested** — a phone list on the wiki that is down does not exist.
- **The backup system is recovered too**: if the backup server was part of the lost
  site, restoring the catalogue is the step preceding everything else. Rehearse it.

### 3.4 The plan: activation, command and people

- **Written, observable activation criteria**: loss of a site or region; unavailability of
  a tier 1 service with an estimated recovery **above its MTPD**; a confirmed
  compromise requiring rebuild; loss of a critical provider with no restoration date;
  unavailability of key personnel. When a criterion is met, **it is activated**: doubt is
  resolved by activating, because deactivating costs a notification and not activating costs the business.
- **Who declares**: a named role (typically management or the continuity lead) **with two
  deputies and a written order of succession**, with authority delegated in advance by management — the
  delegation is signed cold, not improvised at 03:00. The declaration is an explicit act, with
  a timestamp, recorded, and **it marks the change of regime** from the incident process
  (`incident-management-standards`) to this one.
- **Crisis structure**: crisis director (decides and prioritises, does not execute), technical
  recovery leads per layer, communication lead (internal, customers, regulators,
  press: **a single spokesperson**), business liaison (validates that what has been recovered is usable) and a decision
  log. Shifts from minute one: **a disaster lasts days, not hours**, and exhaustion is
  what produces the expensive decisions.
- **Crisis communication prepared cold**: templates per audience, a tested alternative channel,
  and the notification obligations matrix **already written** (coordinated with the
  incident skills). Improvising communication during the crisis is how a technical incident becomes
  a reputational crisis.
- **People — the assumption that breaks most plans**: people can be on sick leave, on holiday, out of
  coverage, at the affected site or unwilling to answer the phone at 4:00 on a Sunday. The plan
  requires: **two capable people per critical task** (no single hero), contact details outside the
  corporate system, procedures written so somebody who is not the author can execute them, and
  transport/accommodation arranged if the alternate site is physical. **The runbook's acid test:
  can it be executed by somebody who did not write it, at 03:00, without phoning anyone?** If not, it is not a
  runbook.
- **The plan is code, not a PDF**: versioned, with an owner, with the date of its last test visible and with
  a mandatory review after any relevant architectural change. A plan that cites servers
  that no longer exist is worse than no plan, because it generates false confidence.

### 3.5 Strategies and their real cost

| Strategy | Typical RTO | Typical RPO | Cost | When |
|---|---|---|---|---|
| **Backup–restore** | Hours to days | Hours | Low | Tier 3-4. The real RTO is dominated by **restoring and validating the volume**, not by launching the job |
| **Pilot light** | Hours | Minutes | Medium-low | A minimal core (replicated data, network and templates ready) switched on; the rest is brought up on activation |
| **Warm standby** | Tens of minutes | Seconds to minutes | Medium-high | A reduced environment but **running and exercised**; it scales on activation |
| **Active-active** | Close to zero | Close to zero | Very high | Only if the MTPD requires it. You pay: data consistency, conflict resolution, latency and a whole new class of failures |

- **Multi-region**: the default option for a regional disaster; the cost people forget is the
  **data transfer and the configuration drift between regions** — a secondary region that
  is not deployed from the same code diverges and fails on the day it is used.
- **Multi-provider**: it is sold as resilience and almost always buys complexity. It is defensible
  when the real risk is **the whole provider** (concentration, regulatory decision, contractual
  exit), and it requires giving up differentiating managed services or maintaining two
  implementations. **A one-way door decision: it requires an ADR with the operational and
  people cost quantified.** A more honest and much cheaper alternative: **a proven capacity to leave**
  (exportable data, portable IaC, a rebuild rehearsal) instead of running in two places at once.
- **What almost never gets replicated and sinks the exercise**: DNS and its delegation, certificates and PKI,
  secrets, in-flight queues, firewall and load balancer configuration, licences tied to hardware or
  to a MAC, outbound integrations with a source IP on the third party's allowlist, and **the backup
  and monitoring infrastructure itself**.

### 3.6 The isolated recovery environment (IRE / *clean room*)

When the disaster is a **compromise** and not a fire, production stops being a place to
restore to: you cannot demonstrate that it is clean, and if the directory is compromised there is not even
an identity with which to administer it. The **isolated recovery environment** is the place where
a service is restored, cleaned, validated and **declared fit** before returning it to production.
Its product is not a powered-on server: it is **rebuilt and signed trust**. With the directory
compromised, **it is the plan's first physical deliverable** — without it there is nowhere to restore anything.

**What it is not** (or stops being):
- **It is not a training or sample-detonation lab** (`ctf-lab-standards`): there
  the threat is executed on purpose and the isolation protects the world from the lab; here the
  premise is that **nothing malicious is executing** and the isolation protects the environment from the world.
- **It is not the forensic environment** (`incident-response-forensics-standards`): acquisition, *timeline*,
  chain of custody and the analysis workstation are theirs. The IRE **consumes** the result of that
  investigation —clean point, IOCs, persistence list— and **does not produce it**.
- **It is not preproduction, nor a test environment, nor burst capacity.** An IRE with a second use
  has users, credentials, integrations and production routes: it is no longer an IRE.
- **It is not a copy**: it is compute, network, storage and a management plane. The immutable repository
  is the input; the IRE is the machine that turns it into a service.

**The three isolations that define it** — all three, or there is no IRE:

1. **Network.** Real *default-deny*: no route to production nor to the management network, and no Internet
   except for **named, justified, temporary and logged** egress (EDR signatures and console,
   licence activation, verified download of a binary). **Its own DNS and NTP inside the IRE**:
   if it resolves names against production, it is not isolated — and the clock is not a detail, because
   Kerberos, TLS and log correlation depend on it (§3.3, step 5). The isolation is
   **checked from the inside** (an explicit attempt to reach and to resolve production, with the result
   recorded), it is not assumed from the diagram.
2. **Identity — the one most often got wrong.** Directory, credentials and MFA **belonging to the
   IRE**, created outside the compromised domain, **with no trusts and no federation** with it. The classic
   failure: an impeccably separate network is built and then administered with the usual domain
   administrator account — the one the attacker controls —, so the isolation lasts until the first
   login. Corollary of **clean source**: it is administered **from a device built
   from scratch from a trusted source** (a new administration workstation), not from the administrator's
   laptop nor from a production jump host. Microsoft says it literally for systemic identity
   compromise: *"ensure any actions taken are performed from a trusted device built from
   a clean source"* (verified Aug 2026, §8).
3. **Management.** Hypervisor, storage, backup console, deployment tooling,
   monitoring and out-of-band access itself (IPMI/KVM) **outside the domain being recovered**,
   with their own local accounts and independent MFA. **If the management plane is the same, there is no
   isolation**, however many VLANs are drawn: whoever controls the hypervisor controls all the
   machines restored inside it. It is the direct continuation of the §2 criterion (backup outside
   the domain) and of the Tier 0 scope of `windows-server-ad-standards`.

DORA turns part of this into an obligation for its sector: when restoring with its own systems it requires
using ICT systems **"physically and logically segregated from the source ICT system"** (art. 12(3);
verified Aug 2026 against a secondary source — cross-check it with the official text before citing it,
§8).

**Which medium you restore from and what you install with**:
- **Only from the immutable or offline copy.** The online copy lives in the same identity and
  network plane as the attacker: its integrity is not demonstrable, and demonstrating it is exactly what is
  needed. The copy is **mounted read-only** and restored **towards** the IRE, never the other way round; the
  credential the IRE uses against the repository **reads and does not delete**.
- **The backup catalogue and the encryption material go in first.** Without them, the immutable repository
  is expensive noise (§4, gate 8).
- **The binary comes from trusted media, not from the compromised environment.** ISOs, base images, agents,
  drivers, packages and IaC templates are obtained from the vendor's source with a **verified signature
  or hash**, or from sealed media kept cold. **Never** from the installers *share*, from the
  internal image registry, from the deployment server nor from the fallen environment's golden template:
  those are precisely the places where a backdoor survives the restore.
- **Structural preference**: **rebuild the system from a trusted source and IaC and restore only
  the data**, instead of restoring the full image — it is faster and does not drag along the attacker's
  persistence (consistent with `backup-recovery-standards` §3.8; the choice between the two routes is made
  **explicit** and the chosen one is rehearsed).

**Rebuild order inside the IRE — *identity-first***. It is the chain of §3.3 compressed and with
the compromise as a premise:

```
0. IRE management plane + administration workstation built from a clean source
1. IRE internal network, own DNS and NTP, isolation verification
2. Backup catalogue and encryption material
3. IDENTITY: directory restored from the point the investigation determines, in isolation,
   with persistence removal and rotations  → nothing else is restored until this is closed
4. Secrets and PKI: whatever lived in the compromised domain is REISSUED, not restored
5. Data and applications by tier, in dependency order
6. Functional validation with the business + IOC sweep + EDR reporting
```

- **Each layer is validated before stacking the next**: the IRE exists so that the problem appears
  there and not in production; stacking without validating turns the clean environment into a second copy of
  the disaster.
- The **concrete procedure** for the directory (DSRM, metadata cleanup, FSMO, RID, double
  `krbtgt` rotation) belongs to `windows-server-ad-standards` §3.9. **Here, the requirement that it happens
  inside the IRE and before everything else.**

**Criteria for "clean": what you must be able to assert before reconnecting.** It is not "it passed the antivirus".
In writing, with evidence and with whatever **could not** be determined declared explicitly:
- the restore point is **earlier than the initial compromise according to the investigation**, not according to the
  detection date;
- the vector is closed and **tested**, and persistence has been specifically searched for and removed
  (gate 7 of `incident-response-forensics-standards`);
- the credentials in scope are rotated, **including those that only exist inside what was
  restored** (service accounts, embedded keys, integration tokens, client certificates):
  rotating half is not rotating;
- the case's IOCs have been swept over what was restored and the **EDR is installed and reporting before**
  reconnection, not after;
- what was restored **does what it is supposed to do** (functional test validated by the business), not just
  starts;
- the subsequent enhanced monitoring is active and with a defined window.

**Who signs it off**: **technical security** fitness (verified eradication) is signed by the
investigation lead; the **functional** one, by the business liaison; and **reconnection to
production is authorised by the crisis director** (§3.4), with a timestamp and a record. They are three
different questions and **one signature does not cover all three**.

**When it is built — the trap.** An IRE designed on the day of the incident is designed with no identity to
authenticate with, without the documentation (which was in the fallen domain) and with no margin to buy
or contract anything. Mandatory split:
- **Pre-provisioned and tested cold** (non-negotiable): the IRE's emergency identity and its
  *break-glass* credential in physical or sealed custody; access to the immutable repository and to the
  keys, with its separation-of-duties procedure; runbook, inventory and contacts out of
  band; a separate management plane with its own local accounts; and the **written decision of where it is
  stood up**, with capacity, contracts and licences checked.
- **Improvisable on D-day**: exact sizing, number of machines, internal addressing and which
  tier services are brought up first.
- **Cut-off rule**: **anything requiring authentication against the compromised domain, or contracting,
  buying or waiting for a third party, is not improvisable** — either it is resolved cold, or it does not exist.
- **It is exercised against**: the test restore and the partial simulation (§3.7) are executed
  **in the IRE**, not in a comfortable test environment. It is the only way to know that the IRE exists and
  how long it takes to exist.

**Cost and proportionality.** A permanent, dedicated IRE is expensive and **is not always justified**;
what is not optional is having **decided and tested how one is obtained**. The scale, from minimum to
maximum:

| Level | What it is | When it suffices |
|---|---|---|
| **Minimum acceptable** | The pre-provisioned items above + a **written and rehearsed procedure** for standing up the IRE on demand, with the **build time measured** and counted within the RTO | It is the floor **for everybody**. If the build time has not been measured, the RTO of a compromise scenario is fiction |
| **On demand in the cloud or from IaC** | A **separate** account, subscription or *tenant* —another administrative failure domain (§5)—, templates ready and deployment tested periodically | **The default option for most**: near-zero cost at rest and a bounded, measurable build time |
| **Permanent and dedicated** | Capacity switched on, with no other use, with its own management plane and its own identity | Only if the tier 1 RTO does not allow the time to build it, or if the regulation or the contract requires it |

The costs people forget and that decide the exercise: **licences and support** for the software that has to be
brought up there (more than one is tied to hardware, a MAC or an activation server on the Internet that the
IRE cannot reach), and the **time and cost of retrieval** from an archive storage class.
Both are checked cold, not on D-day.

### 3.7 Exercises: the only proof that the plan exists

A progressive scale; none replaces the next:

1. **Tabletop** (half-yearly): around a table, no systems. It tests **decisions, roles, authority and
   communication**. Cheap and it always finds something: usually that nobody knows who declares.
2. **Partial simulation** (annual): a real restore of a service **to the IRE** (§3.6), with real
   data and **real volume**, timed — including the time to **build the IRE itself**.
   It reveals that the estimated RTO was optimistic by a factor of 3 to 10.
3. **Real failover** (annual for tier 1): the service is genuinely switched over, in an agreed window, and it is
   operated from the alternate site **long enough for the problems to appear** (hours, not
   ten minutes). It includes the **way back** (*failback*), which is the forgotten half and often the most
   difficult.

Rules of the exercise:
- **Everything is timed** and compared with the committed RTO/RPO. That contrast is the deliverable.
- **An exercise that cannot fail is a demonstration**, not an exercise. It is allowed to go wrong;
  that is exactly what it is for.
- **Rotate the participants**: if it is always executed by whoever wrote the runbook, you are measuring that
  person, not the plan.
- **Scenarios that must be exercised** beyond "the data centre goes down": ransomware with attacked backups,
  directory compromise, outage of the cloud provider or a critical SaaS, loss of key personnel,
  silent corruption detected late (up to which date do you have good copies?), and failure of the backup
  system itself.
- **Every finding comes out with a named owner and a date**, and its closure is reviewed. An exercise with no closed
  actions is tourism.

## 4. Gates (they break the programme, not the build)

1. **Without a tested restore there is no backup.** The indicator is "we restored and **validated** X in Y
   minutes", with a date, not "the job finished green". The **age of the last validated restore**
   per system is a first-class SLI, with an alert when it gets old.
2. **Without an exercise in the last 12 months there is no plan**: a tier 1 service with no exercise moves to
   "no declared coverage" status and is escalated to a risk formally accepted by its business owner
   (via `grc-compliance-standards`). It is not glossed over.
3. **RTO/RPO measured and published alongside the committed ones.** If the measured one exceeds the committed one, either
   the architecture is corrected or **the commitment is corrected**: keeping the false number is the most expensive
   governance failure in the domain.
4. **Coverage**: % of tier 1 services with RTO/RPO derived from a BIA, with a documented recovery
   order and with an exercise within its window. All three at once, or it does not count.
5. **Cold-start test of the critical chain**: identity, DNS, secrets and PKI recovered
   from scratch, without depending on themselves. It is the gate that most plans fail.
6. **Backup isolation test**: demonstrate that the production administrator credential
   **cannot** delete or alter the copies, and that the immutable copy withstands a deliberate
   attempt (executed in an exercise, not assumed).
7. **Plan drift**: compare the plan with the real inventory. References to systems that do not
   exist, or systems in production with no entry in the plan, are findings.
8. **Key custody verified**: recover an encrypted copy using **only** the material
   held outside, with the designated people and their separation-of-duties procedure.

## 5. Scenarios and regulatory framing

### Ransomware: the scenario that dictates the design

- **The attacker attacks the backups first.** Backup is not a recovery layer if it shares
  the identity domain and the production network. Requirements: **isolated backup infrastructure**
  (ideally **outside the domain** — domain-joined backup servers are a documented vector),
  its own non-reused credentials, independent MFA, a separate management plane,
  and **at least one immutable or offline copy** (object lock, removable media, a repository with
  retention enforced by the provider).
- **Backup infrastructure is critical and exposed software**: during 2026 multiple critical
  RCEs were published in a leading backup product (**Veeam Backup & Replication**: the March 2026 batch
  and **CVE-2026-44963**, CVSS v4 9.4, patched on 9 Jun 2026, exploitable by any
  low-privilege domain user on **domain-joined** installations), and CISA has catalogued
  earlier flaws in the same product as actively exploited by ransomware groups. Patch
  the backup system with the same urgency as an exposed service, and **take it out of the domain**.
  Verify the current status before citing any CVE (§8).
- **Identity recovery first.** If the directory is compromised, the recovery order
  changes completely: nothing is restored on top of an identity the attacker controls.
  Restoring the directory is not restoring a copy: it is **restoring trust** —a clean copy
  earlier than the compromise, an isolated environment, removal of persistence (hidden privileged
  accounts, `AdminSDHolder`, `SidHistory`, manipulated GPOs), validation and only then reconnection—.
  **That isolated environment is the IRE of §3.6, and it is pre-provisioned before it is needed**; the
  concrete procedure for AD belongs to `windows-server-ad-standards` (§3.9).
- **The clean restore point is determined by the investigation**, not by the hurry: the initial
  compromise is usually much earlier than the detection, so the **retention depth** must cover
  the plausible *dwell time* (months, not days). Coordinate with `incident-response-forensics-standards`.
- **Recovery time with real volumes, measured**: restoring tens of TB does not happen at the speed of
  the commercial datasheet. Measure, and if the number does not fit inside the RTO, change the strategy or the
  commitment.
- **Double extortion**: recovering the service does not close the incident. There is still a breach, with its
  obligations (see `privacy-engineering-standards` and `incident-response-forensics-standards`). The
  decision to pay **is not technical**.

### Third parties and SaaS

- **Your provider being down is your disaster**, and your customer does not accept "it is the provider's fault". Every
  critical third party enters the BIA with its effective **contractual** RTO/RPO (read it: the SLA usually
  compensates with credit, not with recovery) and with its contingency plan: degraded mode,
  alternative, or manual procedure.
- **SaaS does not back up your data for you.** The shared responsibility model leaves the
  **protection of the data** on the customer's side in every model (IaaS, PaaS and SaaS), and the provider's
  replication **is not backup**: a deletion, a corruption or malicious encryption are
  replicated all the same. The native recycle bin has limited retention and an attacker with permissions can
  empty it. Microsoft expressly recommends in its services agreement backing up content with
  third-party applications; there is also a paid native service (**Microsoft 365 Backup**, GA
  since late 2024, consumption by protected GB) with **partial workload coverage** —
  verify what it covers today before assuming it is enough (§8).
- **Vendor exit**: real exportability of the data (tested, not documented), a usable
  format, the availability window after termination and the exit cost. It is tested once a year as
  part of the exercise, just like a restore.
- **Concentration**: if your production, your backup and your plan B are with the same provider and in the same
  account, your DR covers the failure of a region, not that of the provider nor of the account (compromise,
  administrative closure, billing error). At least one copy must be in **another administrative failure
  domain**.

### Regulatory obligations (status Aug 2026, **verify every point in §8**)

- **DORA** (EU Regulation 2022/2554, applicable since 17 Jan 2025, financial entities) is
  the most prescriptive framework on continuity and the one worth using as a bar even outside the
  sector: **art. 11** (ICT continuity policy and response and recovery plans) and **art.
  12** (backup policies and restoration and recovery procedures). It requires, among
  others: **RTO and RPO per function**, determined considering whether it is a critical or important function and its
  impact on market efficiency (art. 12(6)); restoration with **physically and logically
  segregated systems** from the source; adequate **redundant capacities** (except for microenterprises); a **secondary
  site sufficiently distant** to have a different risk profile, capable of sustaining the
  critical functions and immediately accessible to staff; **post-recovery checks and reconciliations**
  to guarantee data integrity; and **testing of the plans at least
  annually** and upon substantial changes, **including cyberattack scenarios and switchover between
  the primary and the redundant infrastructure**, with a crisis management and communication function
  (art. 14). Advanced resilience testing (TLPT) is the territory of
  `offensive-security-standards`.
- **NIS2** (EU Directive 2022/2555), **art. 21(2)(c)**: "business continuity, such as backup
  management and disaster recovery, and crisis management". The
  **Implementing Regulation (EU) 2024/2690** (17 Oct 2024) develops the technical and
  methodological requirements: it is **binding only on certain categories of digital entities** (DNS,
  TLD registries, cloud providers, data centres, CDNs, managed service and managed security
  providers, online marketplaces, search engines and social networking platforms), but
  ENISA and several national authorities treat it as a **de facto technical reference** for
  the whole of art. 21. It requires, in what matters here: minimum plan content, copies in
  **secure locations geographically distant** from the primary site, inclusion of cloud data
  within the scope of the copy, **periodic restore tests with a documented result**,
  RTO/RPO per critical process and a **sequenced restoration order validated in
  exercises**. ENISA published technical implementation guidance: use it as a reference.
- **Spain and NIS2**: the transposition (**Cybersecurity Coordination and Governance Act**)
  **was still unpublished in the BOE in August 2026**; the draft bill was approved by the Council of
  Ministers on 14 Jan 2025 and the Commission issued a second formal notice on **19 May 2026**
  (case INFR(2024)0270), with an assessment of progress expected for September 2026. **Do not
  take it as published nor as indefinitely pending: verify it** (§8). In the meantime, the
  directive and customer contracts already apply in practice, and an existing ENS or ISO 27001 is the
  fastest base for covering art. 21.
- **ISO 22301:2019 (+ Amd 1:2024, climate action)** is still the current edition and is **under
  revision** (committee draft, with no confirmed publication date). **ISO/TS 22317:2021** is the
  current BIA guidance, confirmed in 2025, and it is a *Technical Specification*: **it is not certifiable**.
  ISO 27031 (ICT readiness for continuity) is the natural complement. The management system and
  its certification belong to `grc-compliance-standards`.

## 6. Operability and metrics

- **RTO/RPO measured vs. committed**, per service and with the exercise date. It is the programme's
  headline metric; everything else is support.
- **Age of the last validated restore** and **of the last exercise**, per tier 1 service. With
  an alert as it ages, just like a certificate about to expire.
- **Coverage**: % of tier 1 services with a BIA, a recovery order and an exercise within its window.
- **Plan drift**: number of discrepancies between plan and inventory detected by automated
  review.
- **Open exercise findings and their age**: if they are not closed, the exercise is expensive theatre.
- **Programme cost per tier**, explicit and compared with the impact it avoids. It is the only way
  to have the "why are we paying for a secondary region?" conversation with data and not with fear.
- **Monitoring of the DR itself**: replication with lag watched and alerted, alternate site capacity
  reviewed as production grows (a secondary sized three years ago no longer copes), and
  backup system telemetry treated as a production service — including an alert for a
  **failed test restore**, not just for a failed backup.
- **Alternate site capacity as an explicit decision**: 100 % or a degraded mode agreed with the
  business? If it is degraded, **what gets switched off and in what order** is decided cold and written down.

## 7. Sustainability and prohibitions

**Cadence**: BIA reviewed annually and on a material business change; the plan reviewed after each
relevant architectural change, after each exercise and after each incident that activates it; the matrix of
regulatory obligations reviewed annually; contacts and the order of succession verified every six
months (people change jobs and phone numbers faster than the architecture does).

**The programme is adopted incrementally**: a BIA of the three most critical processes → RTO/RPO signed
by their owner → the recovery order drawn → one tested restore → one tabletop. That is already more
real continuity than an unrehearsed 200-page manual.

**FORBIDDEN**
- ❌ RTO/RPO set by the technical team according to what the infrastructure allows today.
- ❌ A continuity plan with no BIA behind it: they are invented numbers with the appearance of rigour.
- ❌ Declaring a plan "done" with no exercise; an unrehearsed plan does not exist.
- ❌ A backup with no restore tested and timed with real volume.
- ❌ Confusing HA with DR, or replication with backup.
- ❌ A backup copy reachable with production administrator credentials; a backup server
  joined to the production domain; the absence of an immutable or offline copy.
- ❌ Backup encryption keys held **only** inside the backed-up system.
- ❌ Restoring after a compromise with no verified eradication, or from a point later than the
  initial compromise.
- ❌ Rebuilding **on the compromised domain**, or joining the recovery environment to that domain
  "so it can be administered".
- ❌ Administering the IRE with **production administration credentials**, or from the administrator's
  usual machine instead of a workstation built from scratch from a trusted source.
- ❌ Connecting the IRE to the production or management network **"just for a moment"** —to copy a
  file, check a piece of data, install an agent—: from that instant it stops being an IRE and you have to
  start again.
- ❌ A management plane (hypervisor, backup console, deployment, IPMI) **shared** with the
  environment being recovered: that is not isolation, it is a VLAN.
- ❌ Declaring something **clean** when all it has passed is an antivirus: without a sweep for the case's IOCs, without EDR
  reporting before reconnection and without a verified eradication sign-off, there is no reconnection.
- ❌ Restoring into the IRE from the **online** copy, or installing binaries, images or templates
  coming from the compromised environment.
- ❌ An IRE shared with preproduction, testing or burst capacity.
- ❌ An IRE that only exists on paper: **without a rehearsal and without a build time measured within the
  RTO** it is not a capability, it is an intention.
- ❌ Retention shorter than an attacker's plausible *dwell time*.
- ❌ A plan that lives solely in the system that goes down (wiki, SharePoint, password manager).
- ❌ A single hero per critical task; a plan that assumes everybody is available and reachable.
- ❌ A disaster declaration requiring a committee, a meeting or an authorisation nobody can give in the small hours.
- ❌ A scripted exercise that cannot fail, or one always executed by whoever wrote the runbook.
- ❌ An exercise with no findings with an owner and a date, or with findings nobody closes.
- ❌ Publishing committed RTO/RPO that the exercise has shown to be unachievable.
- ❌ Assuming the SaaS backs up your data, or that its SLA is equivalent to an RTO.
- ❌ Production, backup and plan B in the same account and the same provider with no documented decision.
- ❌ Multi-cloud adopted by reflex, with no ADR and with no operational and people cost quantified.
- ❌ A secondary site that has never served real traffic nor been deployed from the same code.
- ❌ Forgetting the *failback* in the design and in the exercise.
- ❌ Pinning regulatory obligations, articles or editions of standards **from memory** (§8).

## 8. Mandatory web verification

Before pinning any figure, article, edition or tool, **look it up — do not recall it**:

1. **DORA**: current text of **arts. 11, 12 and 14** and of the applicable RTS/ITS (content of the
   continuity policy, segregation requirements for restoration systems, distance and
   risk profile of the secondary site, testing cadence and scenarios). Verified as of Aug 2026 in
   secondary sources: **cross-check against the text of Regulation (EU) 2022/2554 before citing it
   as a requirement**. Status of the designation of critical ICT providers (CTPP) by the ESAs.
2. **NIS2**: **art. 21(2)(c)** and the **Implementing Regulation (EU) 2024/2690** (exactly whom it binds
   and what its Annex requires on continuity, backups and testing), plus **ENISA's technical
   implementation guidance** and its current version. **Declared gap**: the detail of the CIR's Annex
   has been taken from secondary sources and **has not been cross-checked against the official text**.
3. **NIS2 in Spain**: whether the *Cybersecurity Coordination and Governance Act* has already been published
   in the BOE, its deadlines and the competent authority. As of Aug 2026 it **was not published** and
   case INFR(2024)0270 was still open (second formal notice 19 May 2026). **Do not take it for
   granted in either direction.**
4. **ISO**: current edition of **ISO 22301** (as of Aug 2026, the 2019 one + Amd 1:2024, with a revision at
   committee draft stage and **no confirmed publication date**), of **ISO/TS 22317** (2021,
   confirmed in 2025) and of **ISO 27031**. Consult the ISO Online Browsing Platform, not a
   commercial website.
5. **ENS (RD 311/2022)** and applicable **CCN-STIC** guidance if the system belongs to the Spanish public sector or
   to one of its suppliers: continuity requirements (`op.cont.*`) by category. **Declared gap**:
   not verified in this revision.
6. **CVEs and status of the backup and replication software** you are going to recommend. Verified as of
   Aug 2026 for **Veeam Backup & Replication**: a batch of 7 critical CVEs on 12 Mar 2026 (including
   CVE-2026-21708, CVSS 9.9) and **CVE-2026-44963** (CVSS v4 9.4, patch 12.3.2.4854 of 9 Jun 2026,
   affecting domain-joined installations); CISA has catalogued earlier flaws in the product as
   exploited by ransomware. **Check fixed versions and active exploitation before acting**,
   and equally review any **supply chain incident** affecting the tool (precedent from
   the catalogue: Trivy dropped as the default after the March 2026 compromise).
7. **Coverage of the native SaaS backup services** before assuming they are sufficient:
   **Microsoft 365 Backup** (GA since late 2024, consumption per GB of protected content) **did not
   cover several workloads in 2026** (Teams chats, private channels, Planner, Whiteboard, Loop,
   Stream, according to secondary sources). Verify the current scope, and the equivalent for Google
   Workspace and any other critical SaaS, in the provider's documentation.
8. **The cloud provider's DR primitives** (cross-region replication, object lock/immutability,
   quota limits during a mass failover, real restore times from cold storage
   and their retrieval costs) in the official documentation. Quota limits in the
   secondary region are a classic and silent failure mode.
9. **Identity recovery**: the current Active Directory / Entra ID forest recovery
   procedure in Microsoft's documentation and the status of third-party tools
   before relying on them. Verified Aug 2026 in a primary source (*AD Forest Recovery — Perform
   initial recovery*, Microsoft Learn): the first writable DC is restored **with the network cable
   disconnected or the adapter on another network**, and afterwards the recovered DCs are joined to *"a common
   network that is isolated from the rest of the environment"* to validate health and replication
   before touching production. Verify that the page still says that before citing it.
10. **Isolated recovery environment (§3.6)**:
    - **DORA art. 12(3)** —restoration with systems *"physically and logically segregated from the
      source ICT system"*— verified Aug 2026 **against a secondary source**: **cross-check it against the
      text of Regulation (EU) 2022/2554 on EUR-Lex** before citing it as a requirement, and check
      whether the applicable RTS develops it.
    - **Clean source for administration**: the formulation *"ensure any actions taken are performed
      from a trusted device built from a clean source"* comes from *Recovering from systemic identity
      compromise* (Microsoft Learn, Azure security fundamentals), verified Aug 2026 via a search
      result; **the full page was not opened** — re-verify before quoting it verbatim.
    - **Declared gap — there is no public standard specifying the IRE**: the term comes from
      vendor documentation (Broadcom/VMware defines it as *"an industry accepted acronym for
      Isolated Recovery Environment, ... a clean and secure network environment used specifically for
      recovery from ransomware attacks"*, verified Aug 2026) and **NIST SP 800-184** (2016, the current
      final version) does not name it as a concept. Treat it as **engineering criteria, not as a
      citable requirement**, and if you need regulatory backing use DORA art. 12(3) or CIR (EU)
      2024/2690 (§2 of this list).
    - **Declared gap — CISA**: the text of the **#StopRansomware Guide** could not be retrieved (CISA's
      website and the mirrored PDFs returned HTTP 403 in this revision), so **none** of its
      sentences about a clean recovery VLAN or about trusted installation media **is cited**.
      Retrieve it and cross-check before relying on it.
    - **Vendor IRE products** (VMware Live Cyber Recovery, Rubrik, Commvault Cloud, Dell
      PowerProtect Cyber Recovery, Veeam and equivalents): what they actually isolate, whether they include their own
      identity and what remains your responsibility. **Not verified in this revision**; the §3.6 criteria hold
      regardless of the product, and that is how they should be used.

If you cannot verify, **say so explicitly instead of assuming**.
If the web contradicts this document, **the web wins** — flag the discrepancy.
