---
name: migration-projects-standards
description: How a platform or infrastructure migration is actually executed - the cutover, not the strategy. Use when writing a cutover runbook or pre-migration checklist, scheduling a cutover window and its dress rehearsal, defining go/no-go and abort criteria and naming who declares them, planning migration waves versus a single all-at-once switch, running dual writes and reconciling both sides, backfilling and then proving row counts, checksums and control totals match after the move, rehearsing a rollback instead of assuming one, lowering DNS TTL before a switch, declaring a change freeze and pricing what it costs, notifying users of an outage window, running the hypercare or warranty period after the switch, or setting a dated decommissioning plan for the source system that is still powered on just in case.
---

# Migration execution standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **how the move is executed**, whether the source is legacy or not: migration of a datacenter, of
hypervisor, of cloud provider, of database engine, of mail or identity system, of one
application to another. **The object of this skill is the cutover** —the transition of traffic and data from the
source system to the target— and everything around it: dependency inventory, rehearsal, window,
abort criteria, verification, rollback and decommissioning.

**Guiding principle**: **a migration does not end when the new system starts up; it ends when the
old one is powered off and the data reconciles.** Anything declared "done" before that is an intermediate
state with two live systems, and that state is the most expensive and most common failure mode of the domain
(§7). Falsifiable corollary applicable to any migration plan you are shown: **if it does not contain a
shutdown date for the source with a named owner, it is not a migration plan, it is a
duplication plan.**

Second corollary, of immediate application: **"it started up" is not a success criterion.** The criterion is
that the data reconciles against the source with a check defined before the cutover (§4).

**Not applicable**: see `legacy-modernization-standards` (**hard and reciprocal boundary**: **there the
strategy and what to do with the system** —which "R", whether it is frozen, whether it is rewritten, the prior
characterisation and the build archaeology—; **here the execution of the cutover** once decided. Arbitration rule:
if the question is *"what do we do with this system?"*, it is theirs; if it is *"how do we move it
without breaking anything and when do we switch off the old one?"*, it belongs here); `project-management-standards` (project
management: delivery approach, estimation, RAID, reporting, stakeholders, closure. **Here
only the artifacts proper to the cutover**, which are not generic management: the *runbook*, the rehearsal and the
abort criteria); `erp-sap-standards` (**reciprocal: migration to a packaged ERP has
constraints that come not from technology but from the contract** — the maintenance calendar that
fixes the date, the licence that changes with the architecture, the split of responsibility of the deployment
model and transport governance. All of that is theirs and **conditions the cutover window
designed here**; the cutover itself, its rehearsal, its reconciliation and its rollback belong to this skill. The typical
error if they are not read together: fixing the window without knowing that the source landscape is in a transport
freeze with its own owner and date); `bcdr-standards` (**RTO/RPO and disaster**: a migration is a
planned change, not a disaster, and **its window is not an RTO**. Useful reciprocal: the rehearsal of a cutover and
a DR exercise are so alike that it is worth reusing the same runbook, but whoever declares the
activation and whoever declares the abort are not the same figure); `data-engineering-standards` (the
extraction, load and reprocessing pipelines **themselves**: orchestration, *backfill*, idempotency. Here
only what decides whether the cutover is aborted); `data-governance-quality-standards` (the data quality
dimensions and their continuous measurement; here the one-off check at the cutover);
`microservices-architecture-standards` (**theirs the mechanism** of atomic dual writing —
*transactional outbox*, sagas, data ownership—; **here dual writing as a transition technique
and its reconciliation**, §3.4); `enterprise-architecture-standards` (what is migrated and why,
at portfolio level); `itsm-itil-standards` (the migration as a **change** within the service
process, the change window and the handover to operations); `incident-management-standards` (if the
cutover turns into an incident, their process rules: IC, severity, crisis communication);
`dns-standards` (records, TTL and their mechanics); `cicd-standards` (application deployment,
which is not a migration); `backup-recovery-standards` (the pre-cutover copy and its proven
restore); the source and target platform skills, which rule over **how** each thing is moved.

## 2. Default decisions

> A table of criteria, not of tools. Verify any specific product or limit on the web (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Cutover shape | **By waves**, grouped by dependency, with the first wave deliberately small and reversible | Single cutover, **only** with the conditions of `legacy-modernization-standards` §3.2 verified (indivisible state, no seam, contractual date) |
| Rehearsal | **Full rehearsal with masked real data on equivalent infrastructure**, timed | Partial rehearsal + *tabletop* for the rest, if the cost of the equivalent environment is prohibitive — **declared as accepted risk, not as an equivalent** |
| Rollback | **Rehearsed rollback** within the window, with its own stopwatch | ***Fix forward*** declared **before** the cutover, when rollback is impossible because the data has already moved. It is not improvised on cutover day |
| Data coexistence | **A single system of record at any instant**; the other is a read-only replica | **Dual writing** with automatic reconciliation (§3.4), only if coexistence is mandatory and its cost is accepted |
| Window | **With a declared outage** and communicated, however short: an honest outage is cheaper than a silent degradation | Cutover without outage (*live*), only with proven dual writing and the ability to switch traffic gradually |
| Verification | **Data reconciliation defined and automated before the cutover** (§4) | None. There is no alternative: without a reconciliation criterion there is no cutover |
| Freeze | **Bounded change freeze with an end date published** from the start | Partial freeze (only what the scope touches) if the business cannot bear it — with the divergence risk made explicit |
| Source shutdown | **Date committed in the same document that approves the cutover** | None. "We will switch it off eventually" is not an alternative (§7) |

## 3. Anatomy of the cutover

### 3.1 Step zero: inventory and dependencies

**Nothing starts until the inventory exists of what is moving and of what talks to it.** It is not the
organisation's application inventory (that is `enterprise-architecture-standards`) nor the
CMDB (`itsm-itil-standards`): it is **the dependency graph of the specific scope**, and it is built
with two sources that must be cross-checked because neither is enough:

- **The declared**: configuration, connection files, DNS, firewall rules, documentation.
- **The observed**: real connections over a period that includes **month-end close and the annual
  process**, measured with network flows, database connection logs or the load balancer itself.

What appears on only one of the two sides is the valuable finding: **a declared dependency that
nobody uses** (candidate for retirement) or **a real dependency that nobody had declared** (the one that
breaks the cutover). Mandatory outputs: who consumes the system, what it consumes, **who has
credentials or IPs hardwired by hand**, which batch jobs touch it and on what calendar, and which
window of the year is untouchable for the business.

### 3.2 Prior rehearsal

- **The whole cutover is rehearsed, not its pieces.** A valid rehearsal produces **three numbers**: how long
  each step took, how long the rollback took, and how many differences the verification found. Without the
  three, it was a meeting.
- The cutover *runbook* is a living document with task, **sequence, planned and actual duration,
  owner and success criterion per step**. Verifiable public reference (AWS Prescriptive Guidance,
  *Pre-cutover stage*, **verbatim**): *"we recommend that your cutover plan includes contingency
  plans and risk mitigation strategies for failure in the event of an unsuccessful cutover. Be sure
  to document a rollback procedure as part of the cutover plan"*, and among the elements to analyse
  beforehand: *"Impact to the business (for example, on revenue or trust) of an overrun of the allocated
  downtime window"*, *"Contingency for 'fix forward' activities in the event of unforeseen events"* and
  *"Rollback time in the event of a failure"*.
- **The rehearsal discovers what the plan did not know**: expired credentials, a certificate tied to the
  old hostname, a batch that only runs on the 1st and the 15th, permissions only one person has. That is why
  it is rehearsed **with the same people and in the same time slot** as the real cutover.
- **A runbook step that only one person knows how to execute is a risk, not a detail.** It is rehearsed
  with the substitute.

### 3.3 Success and abort criteria — beforehand, and with a name

**They are written and approved before the cutover, never during.** During the cutover, with the window
running and people tired, **the bias is always to continue**: the cost already invested weighs more than the
evidence. The criteria exist precisely to neutralise that.

| Element | Rule |
|---|---|
| **Success criterion** | Specific and automatable check, not "it works": data reconciliation (§4), end-to-end business transaction, latency within threshold, nightly batch completed |
| **Point of no return** | **Exact instant of the runbook from which rollback ceases to be possible**, marked in the document. Before crossing it there is an explicit go/no-go decision |
| **Abort criterion** | Objective and measurable conditions: the time allocated to a critical step is exceeded, verification fails, a failure of an unforeseen class appears |
| **Who declares it** | **A named person, with name and substitute**, with authority to abort without asking permission — and **it is not whoever executes the cutover**, who is inside the bias |
| **Decision clock** | A specific time ("at 04:00, if X is not there, we abort"). A criterion without a time is postponed until it is too late |

**Aborting according to the criterion is not a project failure: it is the project working.** If aborting
is experienced as personal failure, nobody will ever abort and the criterion is decorative. It is said beforehand, in
writing, and it is said by whoever is in charge.

### 3.4 Dual writing and reconciliation

- **Dual writing is not a distributed transaction.** Writing to two systems without atomicity
  produces guaranteed divergence under partial failure; the correct mechanism (*transactional outbox*,
  CDC from the log) belongs to `microservices-architecture-standards` and `streaming-cdc-standards`. Here the
  execution consequence: **dual writing forces a reconciler, and the reconciler is
  part of the deliverable, not a future task.**
- **A single direction of truth at any instant**: one system is the system of record and the other follows. Symmetric
  bidirectional dual writing without deterministic conflict resolution **is not done**.
- **The reconciler** runs continuously for as long as the coexistence lasts, compares by natural key,
  **alerts on divergence** and leaves a record. Growing divergence = abort criterion (§3.3).
- **Every migration write is idempotent and retryable**: retries happen, and a
  *backfill* that duplicates on retry makes verification impossible.
- **Coexistence has an end date from day one.** It is the same rule as the shutdown of the
  source (§7) and it is broken just as easily.

## 4. Integrity verification: "it reconciles", not "it started up"

**It is defined before the cutover, automated and executed in the rehearsal too.** Levels, in order of
increasing strength; the strongest that is feasible is chosen, not the most comfortable:

1. **Count per entity**: rows, objects, mailboxes, files — source against target, with the
   explicit policy on what was decided **not** to migrate (history, logical deletions, orphan
   files). An "expected" mismatch that was not written down beforehand is a mismatch.
2. **Business control totals**: totals of the magnitudes that matter (balances, amounts,
   units) per period. Detects what the count does not see: the migrated record with the wrongly
   converted value, the truncated decimal, the date shifted by time zone.
3. **Hash per record or per batch** over the fields that must be identical, first normalising
   what legitimately changes (technical identifiers, load timestamps, encoding).
   **Normalising is a decision that gets documented**: it is where the real errors hide.
4. **Functional comparison**: the same query or the same business report run against both
   and compared. It is the one that convinces the user, and the only one that validates the semantics.
5. **Targeted human sampling** over the known odd cases: the historically corrupt record, the
   customer with non-ASCII characters, the negative amount, the record from 1998.

Hard rules:
- **Encoding conversion, time zones and numeric precision**: the three most frequent causes of silent
  mismatch in migrations between different platforms. They are verified explicitly,
  not assumed.
- **Verification runs before releasing the users**, not after. If it only fits afterwards,
  the abort criterion is replaced by a **withdrawal** criterion with its own clock.
- **Warranty period (*hypercare*)**: after the cutover, reinforced on-call with declared owner and duration,
  and **reconciliation keeps running** during that period. Its end is an
  explicit decision, not the day people stop looking.
- **What cannot be verified automatically is declared**: it is residual risk accepted with a signature,
  not a silent gap.

## 5. Security during the migration

A migration is an **exposure window**: there are copies of data out of place, new
credentials, temporary firewall rules and people with elevated permissions at three in the morning.

- **Real data outside production** (rehearsal, parallel environment, intermediate extraction): masking
  and legal basis, with a **deletion date for the temporary copies** and a check that they
  were deleted. It is the most common residue of a migration (`privacy-engineering-standards`).
- **Encryption in transit and at rest also in the temporary**: the intermediate dump, the staging bucket
  and the USB disk used for the move are production data.
- **Credentials**: the target's are new and least-privilege from day one; **the source's are not
  cloned**. The elevated accesses of the cutover are temporary, nominative and with an automatic expiry
  date, not "we will remove them later".
- **Temporary network rules** (openings for replication) are created with expiry and their
  closure is verified at decommissioning (§7). A migration leaves as many orphan rules as copies.
- **The source powered off but not decommissioned is still attack surface**, with patches that
  nobody applies any more because "it is being migrated".

## 6. Freeze and communication

- **The change freeze has a cost and it must be said**: the longer it lasts, the more the source diverges
  from the already-tested target and the more pressure for exceptions, until the exception is the norm and the
  freeze is fiction. **It is declared bounded, with an end date published from the start and with an
  exception procedure with a single owner** — and every exception granted **is replicated in the
  target and re-verified** (§4), or the rehearsal has been broken.
- **The freeze is not free even if nobody asks for it**: during it the business accumulates demand. That
  cost goes into the comparison of options, it does not appear afterwards as a surprise.
- **Communication to users**: what stops, when the window starts and when it ends, **what they are
  expected to notice afterwards** (new routes, credentials, different performance), whom they notify if
  something fails, and **a real end notice**, not just a start one. The **abort** is also communicated if
  it happens: silence after the window generates more tickets than the outage.
- **Third parties and integrated providers are notified on their own lead time**, which is usually longer than the
  internal one and cannot always be accelerated. They appear in the §3.1 inventory or they do not appear at all.
- **A single status channel during the cutover** (the same one used in incidents) and a person
  dedicated to communicating who is **not** the one executing.

## 7. Decommissioning and prohibitions

**The old system left powered on "just in case" is the most expensive and most common failure of this domain**, and it is
a silent failure: it does not produce an incident, it produces an invoice, attack surface and ambiguity about
which is the system of record. Minimum plan, approved **in the same document that approves the cutover**:

1. **Shutdown date with a named owner**, not "when things calm down".
2. **Read-only retention period** bounded and justified, with the source **degraded to
   genuinely read-only** (not by convention): if it still accepts writes, there are still two
   systems of record.
3. **Logical shutdown before physical**: the service is stopped, it is observed for a declared period
   who complains and what breaks (that is the last dependency verification), and **only then**
   is it powered off and released.
4. **Archival of the data** that regulation requires to be retained, **with proven restore** — an archive
   that nobody knows how to read in five years is not archival (`backup-recovery-standards`).
5. **Cleanup of the trail**: temporary firewall rules, DNS records, monitoring entries,
   intermediate copies, service accounts, licences and support contracts. **Cancelling the contract
   is part of decommissioning**: it is where the saving that justified the project lives.

**FORBIDDEN**
- ❌ Cutting over **without abort criteria written and approved beforehand**, and **without a named person** with
  authority to declare them (§3.3).
- ❌ Cutting over **without a timed prior rehearsal**. An unrehearsed plan is a hypothesis with a schedule.
- ❌ Accepting a migration as good because **the system started up**, without a data reconciliation defined
  beforehand (§4).
- ❌ **Theoretical rollback**: documented and never executed. If it has not been executed in the rehearsal, it does not
  exist; *fix forward* is declared and assumed, or there is no cutover.
- ❌ **Ending the migration without a shutdown date for the source** with an owner (§7).
- ❌ Leaving the source powered on **accepting writes** after the cutover: two systems of record is
  data corruption with a date.
- ❌ Dual writing **without an automatic reconciler** and without an end date for the coexistence (§3.4).
- ❌ Rehearsing or migrating **with unmasked production data** outside production (§5).
- ❌ Leaving elevated credentials, temporary network rules or intermediate copies active after the cutover.
- ❌ Changing the scope inside the window ("while we are at it, let's also upgrade…"): it doubles the possible
  causes of failure and voids the rehearsal.
- ❌ Change freeze **without a published end date** or with exceptions without a single owner.
- ❌ Executing the cutover with **a single person who knows a critical step**, or without a status channel.
- ❌ Discovering dependencies **by asking** instead of by measuring real traffic during a complete business
  cycle (§3.1).

## 8. Mandatory web verification

Before pinning anything in a real project, **look it up — do not recall it**:

1. **Real limits and times of the replication and transfer tools** you are going to use
   (the provider's migration service, database engine replication, storage
   synchronisation): maximum window, replication latency, unsupported data types and what it does
   on a failure halfway through. **The duration of the cutover is calculated with your volume measured in the rehearsal, not
   with the brochure figure.**
2. **Compatibility matrix and supported upgrade paths** between source and target version:
   many migrations require an intermediate hop and that changes the shape of the plan.
3. **End of support and contract end date** of the source system: it sets the real deadline of the
   decommissioning and, often, the cost that justifies the project.
4. **Cutover guide from the target provider**, if it exists, to verify it is still current. Cited
   verbatim in §3.2: AWS Prescriptive Guidance, *Best practices for cutting over network traffic to
   AWS* — *Pre-cutover stage*. Confirm the page has not changed before relying on it.
5. **Migration failure figures**: **declared gap, and it is deliberate.** The ones in circulation
   (Bloor Research 2007 and 2011, and their derivatives of the "84 % fail" kind) **measure delay or
   cost overrun, not failure**, come from a self-selected survey by a commercial analyst sponsored
   by a vendor, and are behind a form: **I could not read the primary source**. Those on project management
   in general (CHAOS/Standish, "70 % of transformations") **are already debunked in
   `project-management-standards`**. **They are not used to justify or to advise against a cutover**;
   the argument is made with the inventory and with the rehearsal numbers (§3.2).
6. **Windows and calendars imposed from outside** that do not depend on you: fiscal close, campaigns,
   a third party's change windows, local holidays of the on-call team. They are checked, not
   assumed.
7. **Regulatory requirements on data transfer, residency and retention** applicable to the scope
   before moving anything outside its jurisdiction (`grc-compliance-standards`,
   `privacy-engineering-standards`).

If you cannot verify, say so explicitly instead of assuming.

If the web contradicts this document, **the web wins** — flag the discrepancy.
