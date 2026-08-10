---
name: lowcode-governance-standards
description: Governance of low-code and no-code platforms - shadow IT, ownership, data policies and the cost that shows up later. Use when working with Microsoft Power Platform (Power Apps, Power Automate cloud and desktop flows, Microsoft Dataverse, Copilot Studio, Power Pages), the tenant default environment, environment strategy and environment groups, managed environments, Power Platform data policies / DLP connector groups (Business, Non-Business, Blocked), premium and custom connectors, connection references and orphaned flows when the owner leaves, solutions and solution-aware ALM, the CoE Starter Kit and application inventory, Power Platform admin center and Get-AdminFlow / Set-AdminFlowOwnerRole PowerShell cmdlets, OutSystems, Mendix, Appian, Retool, n8n, Zapier or Airtable adoption, citizen developer programmes and maker enablement, an app built by a business team that 200 people now depend on, per-user versus per-app versus per-task versus consumption licensing and premium connector price jumps, or deciding when a low-code app must be rewritten as real software.
---

# Low-code / no-code governance standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Governance of development platforms with little or no code: who can build, where, with what
data, with what credentials, who answers for it afterwards and what it costs once you depend on it.

Triggers: Power Platform (Power Apps, Power Automate, Dataverse, Copilot Studio, Power Pages),
*default environment*, environments and environment groups, *managed environments*, data policies /
DLP and their connector groups, *premium* and custom connectors, connection references,
orphaned flows, solutions and ALM, CoE Starter Kit, `Get-AdminFlow`/`Set-AdminFlowOwnerRole`,
OutSystems, Mendix, Appian, Retool, n8n, Zapier, Airtable, *citizen developer*, *shadow IT*.

**The thesis of this skill, and everything else derives from it: the low-code problem is not technical, it is a
governance problem.** The platform works; what fails is that **nobody knows what exists, whose identity
it runs under, who maintains it and what it will cost next year**. A coding error produces an
exception; a governance error produces a critical application with no owner, a connector holding the
credentials of someone who no longer works here and a bill discovered at renewal time.

Falsifiable corollary, applicable to any *citizen development* programme anyone presents to you:
**show me the inventory.** If there is no list of applications and automations with a named owner,
criticality and last review date, there is no low-code programme: there is *shadow IT* with a
corporate logo. Second corollary, an uncomfortable one: **banning it is not a governance strategy** — it only
moves the activity into spreadsheets with macros and personal SaaS accounts, where you see nothing.

**Not applicable**: see `ai-governance-standards` (**critical and heavily travelled boundary**: **theirs** are the
AI system inventory, AI Act risk classification, the provider/deployer split,
human oversight, transparency and serious incident reporting. **Mine**, when that agent lives inside
a low-code platform: **where it is deployed, under what identity it runs, which connectors it
reaches, who owns it and what it consumes**. Arbitration rule: *if the question is whether that agent may
exist and under what obligations, it is theirs; if it is which environment it lives in, which credential it runs under and who
maintains it, it belongs here*. **The two inventories reference each other, they do not duplicate each other**),
`enterprise-architecture-standards` (**hard reciprocal**: the **corporate application inventory**
with owner, criticality and lifecycle is theirs, and it is the natural destination of whatever gets promoted from
here. A low-code app that becomes critical **enters their inventory**; the catalogue of those that remain
a personal tool stays here), `itsm-itil-standards` (the service, the SLA and the change
process once the app is already a supported service), `identity-access-management-standards`
(identity, SSO, service accounts and the joiner-mover-leaver cycle — **here the concrete effect of an
employee leaving on a connection**, §3.3), `secrets-management-standards` (custody and rotation
of credentials), `privacy-engineering-standards` (personal data, minimisation, retention and deletion
in citizen apps), `accessibility-standards` (WCAG technical criteria and their verification; here only the
**obligation that it apply to what the business builds too**), `grc-compliance-standards` (control
framework, risk and audit evidence), `finops-standards` (cost-per-economic-unit method;
here the **licensing model** and its jumps), `crm-salesforce-standards` (Salesforce as a configurable
platform has its own document: Flow, permissions, governor limits and packages),
`erp-sap-standards` (**relevant reciprocal warning**: a low-code flow that creates documents in SAP
triggers **indirect access** and gets billed — it is assessed there **before** being built here),
`opensource-licensing-standards` (**method boundary**: there SPDX, copyleft and the gate in the PR;
here **commercial platform** licences. Real point of contact: **n8n is not OSI open source**
—Sustainable Use License, *fair-code*— and that distinction is resolved with their method, §3.6),
`cicd-standards` (the pipeline; here what gets promoted and from where),
`refactoring-tech-debt-standards` (general technical debt; here the rewrite criteria, §3.7).

## 2. Default decisions

> Verify on the web before pinning it (§8): licences, quotas and product names of these
> platforms change **several times a year**, and prices for the enterprise-grade ones **are not
> published**.

| Decision | Default | Note |
|---|---|---|
| Tenant default environment | **Restricted and renamed**, never production | §3.2 |
| Where a new *maker* builds | **Their own development environment**, not the default | §3.2 |
| Environment creation | **Restricted to administrators** | §3.2 |
| Data policies (DLP) | **Default-deny**: every new connector blocked until classified | §3.4 |
| Execution identity of anything shared | **Service account / service principal**, never a person | §3.3 |
| Inventory | **Mandatory and automated**, with a named owner per artifact | §3.5 |
| Classification | Personal / departmental / **critical**, with written criteria | §3.5 |
| Critical app | Real ALM: solutions, separate environments, version control | §3.7 |
| Editing in production | **Forbidden** for anything classified as critical | §3.7 |
| Custom connector | Security review before publishing to the tenant | §3.4 |
| Personal data in a citizen app | Requires prior review; it is not the *maker*'s decision | §3.8 |
| Cost | Modelled **before** depending on it, with the success scenario | §3.6 |

## 3. Structure and conventions

### 3.1 What makes this domain different

Three properties change the problem relative to normal software, and they are worth making explicit:
1. **The builder is not from IT and does not have to be.** Any control that requires them to be
   fails: they route around it or stop using the platform.
2. **The artifact is not a file.** There is no repository by default, no PR, no `grep`. If you do not
   inventory it with the admin API, **it does not exist for you** even though it exists for 200 people.
3. **The execution identity is a person's by default.** That is the domain's original sin and the
   origin of nearly every incident (§3.3).

### 3.2 The *default environment*: open by design

Data verified verbatim in Microsoft's documentation (Aug 2026, §8), because it is the point that
gets misread the most:
- *"Each tenant has a default environment that's created automatically."* — **it already exists, whether you look at it or not.**
- *"All licensed users have the environment maker role"* — and the list of "licensed" includes
  **Microsoft 365** users and free or trial licences. In practice: **your whole company
  is a *maker* there**.
- *"Whenever a new user signs up for Power Apps, they're automatically added to the Maker role of the
  default environment. No users are automatically added to the Environment Admin role"* — **nobody
  administers it by default**.
- *"This is a predefined type of environment intended for experimentation, exploration, and
  lightweight, app trial development. The default environment doesn't provide any backup guarantees
  and shouldn't be used for production workloads."* — the vendor says so. Even so **it is where
  half of what is critical shows up**, because it is where the button takes you by default.
- *"You can't delete the default environment. You can't manually back up the default environment"* —
  **you cannot make it go away**: you can only govern it.
- Included capacity: **3 GB of Dataverse database, 3 GB of files, 1 GB of logs**, capped at
  **1 TB** of storage in the environment.

**Minimum actions, and they are day one of the programme:**
1. **Rename it** to something that says what it is (Microsoft literally suggests something like *Personal
   Productivity Environment*). The name is a control: it communicates that this is not production.
2. **Assign named administrators** —Microsoft warns of the risk of administrative lockout if
   nobody holds the system administrator role—, and do it with a few trusted users.
3. **Apply the tenant's strictest data policy** there (§3.4).
4. **Restrict environment creation** to administrators, and **give every *maker* their own development
   environment**: you are not asking them to stop building, you are giving them a better place.
5. **Inventory what is already inside** (§3.5) before touching anything: that is where the surprises are.
6. Design the **environment architecture** —development / test / production per domain, with environment
   groups and rules— for what gets promoted (§3.7).

### 3.3 Execution identity: the connector with the credentials of whoever leaves

**The mechanism, verified (Microsoft documentation, verbatim):** *"When a maker first adds a
connector to an app, they establish a connection by using the authentication protocols that the
connector supports. These connections represent a saved credential and are stored within the
environment that hosts the app or flow."* Translated: **the automation stores a person's credential
and acts as that person**, with all of their permissions, indefinitely.

The two faces of the same failure:
- **While the person is there**: the flow has a human's permissions, not the ones it needs. An
  administrator with broad access builds a flow that, in effect, exposes that broad access to
  anyone they share the app with. It is privilege escalation without an exploit.
- **When the person leaves**: the flow is left **orphaned**. Microsoft documents it under that name —
  *"An orphaned flow is a flow that no longer has a valid owner. These flows can fail if they use
  connections tied to that user account."* The operational consequence nobody rehearses: **payroll,
  reconciliation or the customer notification stops running the day HR disables the account**, and
  diagnosis takes weeks because nobody knew that process was a flow.

**Controls, in order of effectiveness:**
1. **Any automation that someone other than its author depends on runs under a service
   account or a service principal.** This is not a recommendation: it is the condition for classifying it
   above "personal" (§3.5).
2. **Mandatory co-owner** —at least two— on everything shared. It is the cheap minimum.
3. **The employee offboarding process includes a sweep of the platform.** It is detected with the
   admin API: in Power Platform, `Get-AdminFlow` + `Get-AdminFlowOwnerRole` against the directory,
   and `Set-AdminFlowOwnerRole` to reassign. Automated and **run before** the offboarding, not
   after. A *leaver* discovered through a broken flow is a failure of the identity process
   (`identity-access-management-standards`), and this is its most expensive manifestation.
4. **Reassigning the owner does not fix the connection**: the credential belongs to the user and the
   connection has to be **rebuilt**. Account for it in the runbook.
5. **Custom connectors and credentials**: never secrets embedded in the definition;
   custody per `secrets-management-standards`.

### 3.4 Data policies (DLP): a real control, with real limits

**How they work** (Microsoft documentation, Aug 2026): the policies classify **connectors** into
groups —business, non-business and blocked— and **an artifact cannot combine connectors from different
groups**. It is a **surface** control, and it is effective: it prevents building the bridge between the
corporate system and the personal destination.

**What you need to know so as not to overestimate it — and this decides the design of the control:**
- **It classifies connectors, not data.** It does not inspect content: if two connectors are in the same
  group, moving data between them is legitimate for the policy even if it is a leak.
- **Design time and run time are two different moments.** At design time the *maker* cannot save; at
  run time, what was already built moves to **suspended/quarantine** and blocked connections to
  **disabled**. That is: **a new policy breaks existing automations**. It is
  introduced by measuring impact first, with notice and a window — or it produces a self-inflicted outage.
- **Enforcement is not immediate**: verbatim, *"For the most extreme cases, the latency for full
  enforcement is 24 hours. In most cases, it's within an hour."* **It is not a real-time control
  and it is no use as an incident response.**
- **There are connectors that cannot be blocked** (*nonblockable*), and there are "virtual" connectors that
  govern functions rather than APIs, with their own evolving rules. **Verify which ones before assuming
  your policy covers everything.**
- **The custom connector is the side door**: it lets you reach any API. Its publication
  at tenant level is reviewed as a security change, not as a configuration.

**Default posture**: **default-deny** — new connector, blocked until someone classifies it;
strict policy in the default environment and in the development ones; per-environment/group policies for
production, with **named, justified and time-limited** exceptions.

### 3.5 Inventory, owner and criticality: the core of governance

**Without an inventory there is no governance, and the inventory has to be automatic.** It is built from
the platform's admin API (in Power Platform, the CoE Starter Kit is the usual and Microsoft-provided
route, but it is **an open source solution that you operate and maintain**, not a supported
product: treat it as an internal application with an owner). Minimum fields per artifact: **named
owner and deputy, purpose in one sentence, environment, connectors and systems it touches, number of
real users, personal data yes/no, criticality, last review date**.

**Classification, with written criteria and different consequences:**

| Level | Operational definition | What is required of it |
|---|---|---|
| **Personal** | A single user, no sensitive data, no impact if it goes down | Nothing. It is tolerated and the author is left alone |
| **Departmental** | Several users in one area; its failure is annoying but does not stop the business | Owner and deputy, co-ownership, inventory, annual review |
| **Critical** | Others depend on it to operate, or it touches personal/financial/regulated data | Real ALM, service account, backup, support, see §3.7 |

**The trigger nobody watches and must be watched: growth.** The app someone in
finance built for themselves and that 200 people depend on today **changed category without anyone
deciding it**. Hard rule: **the number of users and the criticality are reviewed periodically and
automatically, and crossing a threshold opens a ticket**, not an email. The question "who maintains this?"
has to be asked **before** the answer is "nobody, they left".

**Full lifecycle, or the inventory rots:** registration with an owner → measured usage → periodic review
(is it still used? does it still have an owner?) → **retirement**. Whatever nobody uses in a quarter gets
disabled after notice; whatever is disabled and nobody claims gets deleted. Without retirement, an inventory is a
list that grows until it is useless.

### 3.6 The cost that shows up later

**The pattern of the domain: cheap to start, expensive once you already depend on it.** The honest decision
point is **before** building, modelling the **success scenario** (what if 500 people use it?), not the
pilot with ten.

Microsoft prices verified verbatim on `microsoft.com` (Aug 2026, §8):
- **Power Apps Premium**: *"$20.00 user/month, paid yearly"*, with **250 MB of database and 2 GB of
  file** in Dataverse. With a minimum of 2,000 seats, *"$12.00 user/month, paid yearly"*.
- **Power Apps Developer Plan**: *"Free"*, **2 GB of database**, **750 flows per month** — it is a
  development plan, **not** a production one.
- **Power Automate Premium**: *"$15.00 user/month, paid yearly"*, includes **attended** RPA.
  **Power Automate Process**: *"$150.00 bot/month"*, **unattended** RPA. **Hosted Process**:
  *"$215.00 bot/month"*, with a managed virtual machine.
- **Copilot Studio**: *"sold as tenant-wide license which includes Copilot Credit capacity packs of
  25,000 Copilot Credits each, priced at $200.00/pack/month"*, and *"Whenever an action or response is
  completed by an agent, a varying number of Copilot Credits will be billed depending on the specific
  usage"*. **Governance translation: consumption per interaction is variable and it is not controlled by the
  budget, it is controlled by the agent's design.** A badly designed agent multiplies the cost without
  changing functionality — budgeting by number of users is a methodological error.

**The jump you discover late, and it deserves its own name: *premium* connectors.** Whatever gets
built with standard connectors comes out under the licence you already have; the moment the app touches a
*premium* connector —databases, many SaaS, generic HTTP, custom connectors—
**every user of that app needs a paid licence**. The operational rule that avoids disaster:
**the decision to use a premium connector is taken with the end-user count done**, not as a
technical detail of the *maker*. It is exactly the same error, under another name, on every platform.

**The other metering models, to recognise the pattern** *(via web search; apart from Microsoft and n8n,
**none of these figures is verified against the vendor's source** — OutSystems and Appian **do not
publish prices**: "not published" is the datum)*:

| Platform | Billed by | Where the cost jumps |
|---|---|---|
| Power Platform | User + capacity + AI credits | Premium connector, Dataverse capacity, credits |
| OutSystems | Application (application objects) + users; **quoted** | App complexity moves up a tier with no extra users |
| Mendix | Hybrid: user **and** capacity units per app | Capacity consumption and annual *true-ups* |
| Appian | User **per application**; **quoted** | Multiplying applications |
| Retool | Seat by role (builder / internal / external) + executions | Every new builder; execution quotas |
| Zapier | **Task executed**, not user | A many-step, high-volume flow |
| Airtable | **Editor** (readers do not count) + credits + automations | Record threshold that forces a plan upgrade |

**And the licence, not just the price**: **n8n is not open source according to the OSI**. Its `LICENSE.md`
(verified raw) is the **Sustainable Use License** —*fair-code*—: it grants use *"for your own
internal business purposes or for non-commercial or personal use"*, forbids commercial distribution
and **segregates the *enterprise* features** (files and directories with `.ee`) under a separate licence.
Self-hosting it does **not** free you from conditions. If someone puts it in the catalogue as "open source",
correct it: the analysis of the clause belongs to `opensource-licensing-standards`.

**Cross-cutting cost rule, and it is the only one that works: the licensing model is documented in the
artifact's inventory record** (§3.5), with the marginal cost of one more user. Renewal is
prepared **six months ahead** with measured consumption, seats actually used and a list of what nobody uses.

### 3.7 Real ALM, and when to stop using low-code

**For anything classified as critical, real ALM and no exceptions:** separate development, test
and production environments; the artifact packaged (in Power Platform, **solutions** with connection
references and environment variables, so that promotion does not drag credentials or development
URLs along); export to version control; automated deployment; and **production with no manual
editing**. "Editing in production" is the practice that makes no lower environment represent
reality, and from that point on no test means anything. The pipeline mechanics belong to
`cicd-standards`; **the rule that one must exist belongs here**.

What is almost never done and must be done: **backup and restore testing** of the artifact and its
data, and **tests** —even if they are a signed manual checklist— for anything critical. Careful: the
default environment **offers no backup guarantees**, and the vendor says so (§3.2).

**Criteria for rewriting it as real software.** It is not "low-code is worse": it is that there are signals
indicating that the cost of staying already exceeds the cost of leaving. **Two or more of these → the
rewrite gets planned**:
- The logic no longer fits: dozens of steps, nested conditions and nobody can reason about the flow.
- **It cannot be tested** automatically and its failure has real consequences.
- **Performance or volume** hit the platform's limits recurrently.
- The **licensing cost** per user exceeds building and operating it (do the maths in years,
  not months).
- People **outside** the organisation need it, or it is customer-facing.
- **Vendor risk**: you are locked into a proprietary engine with no documented way out.
- IT already maintains it in practice, so the saving that justified low-code **no longer exists**.

**And the symmetrical criterion, which gets forgotten**: if none of them holds, **rewriting destroys value**.
The three-screen application that solves a real problem for a department does not need
to become a microservice. The right answer is often to **adopt it as it is**:
give it an owner, a service account, a backup and a line in the inventory.

### 3.8 Personal data and accessibility in citizen apps

- **The *maker* does not decide about personal data.** Any artifact that processes personal data goes through
  prior review: legal basis, minimisation, retention and deletion (`privacy-engineering-standards`).
  The typical and forbidden case: extracting a listing with employee or customer data to a personal
  file "to work with it".
- **Retention and deletion also apply to the run history** of the automations and to the
  data left behind on the platform. It is defined at registration, not when the DSAR arrives.
- **Accessibility**: if the app is used by your own staff or by the public, **accessibility obligations
  apply just the same** — the fact that someone in finance built it with an assistant does not change the rule. The
  corporate template and a minimum checklist are the cheap control;
  the technical criteria belong to `accessibility-standards`.
- **Agents and copilots inside the platform**: they go into the AI inventory and the risk classification
  of `ai-governance-standards`. What is required here: environment, execution identity,
  reachable connectors, owner and consumption (§3.3, §3.6).

## 4. Controls and verification

In increasing order of cost. The first three are the baseline of any programme:
1. **Automated and up-to-date inventory** of every artifact, environment, custom connector and
   connection, with an owner (§3.5). Without this, no subsequent control has an enumerable scope.
2. **Scheduled orphan sweep**, cross-checking owners against the directory (§3.3), integrated
   with the employee offboarding process.
3. **Data policy applied** with a prior impact inventory and a notice window (§3.4).
4. **Review of critical artifacts**: that they have a service account, a co-owner, a backup,
   their own production environment and a documented test.
5. **Review of custom connectors** published at tenant level, as a security change.
6. **Consumption and cost measurement** per environment and per artifact, with an alert before the threshold (§3.6).
7. **Quarterly audit**: artifacts with no usage, no owner, with broad permissions or shared with
   "the whole organisation" — this last one is the local equivalent of a public bucket.

## 5. Security

- **Sharing with "everyone in the organisation"** is a security decision and is treated as such:
  it is recorded, reviewed and discouraged by default.
- **The *maker*'s permissions are the artifact's permissions** (§3.3). A flow cannot access
  less than its credential accesses: **least privilege is implemented in the service account**,
  not in the design of the flow.
- **Exfiltration via connector**: the canonical scenario is personal mail or storage in the
  same group as a corporate system. It is exactly what the policies in §3.4 exist to
  cut off, and that is why their classification cannot be lax.
- **Platform audit log** enabled and retained, with who created, shared and ran
  what. Check whether your licence includes it: **on several platforms fine-grained auditing is a higher
  price tier** — and discovering that during an incident is too late.
- **Portals and public sites** built with these platforms are applications exposed to
  the Internet: threat modelling and prior review are mandatory (`appsec-standards`). That they were
  built with a mouse does not change their attack surface.
- **Secrets**: never in visible variables, in the body of the flow or in the definition of a custom
  connector.

## 6. Operability

- **Anything critical needs alerting and on-call.** A flow that fails silently and nobody looks at is a
  deferred incident. Minimum: failure notification to a team mailbox (**not to a person**) and a
  reviewed panel of failed runs.
- **Minimum runbook per critical artifact**: what it does, what it depends on, what to do if it fails, who to
  notify. It fits on one page; its absence is what turns an outage into three days of archaeology.
- **Retries and volume**: an automation retrying in a loop against a corporate system is
  both an outage and a bill (of tasks, of credits or of indirect access).
- **Platform service limits** (requests per connection, size, concurrency): they are
  verified before designing anything high-volume. If the design depends on sitting just below
  a limit, the design is wrong.

## 7. Sustainability and prohibitions

- ❌ **FORBIDDEN** for an automation that more than one person depends on to run under someone's
  personal credential.
- ❌ **FORBIDDEN** a shared artifact with no named owner, deputy and inventory entry. With no owner, it gets
  disabled after notice.
- ❌ **FORBIDDEN** to use the **default environment** as production. The vendor says so and it offers no
  backup guarantees.
- ❌ **FORBIDDEN** to leave the default environment with no strict data policy and no named
  administrators.
- ❌ **FORBIDDEN** to deploy a data policy without measuring beforehand which artifacts it breaks: **it suspends
  what exists**, and with up to 24 h of latency.
- ❌ **FORBIDDEN** to edit in production an artifact classified as critical.
- ❌ **FORBIDDEN** to process personal data in a citizen app without prior review, and **forbidden** to copy
  production data into a test environment without masking.
- ❌ **FORBIDDEN** to use a *premium* or custom connector without the end-user cost count done
  and without a security review of the connector.
- ❌ **FORBIDDEN** to publish a custom connector at tenant level without review.
- ❌ **FORBIDDEN** to ban low-code without offering an alternative: it pushes the activity to where you cannot see it.
- ❌ **FORBIDDEN** to cite low-code productivity figures ("X times faster", "10× less code")
  as a decision argument. **They are vendor marketing figures, with no published methodology or sample,
  and they compare a pilot against a full development.** What is defensible is measured at home:
  time to first real use and total cost over three years, including licence, maintenance and the
  rewrite if it comes (§3.7). The catalogue has already dismantled the same pattern with the CHAOS Report
  (`project-management-standards`) and with ERP failure rates (`erp-sap-standards`).
- ❌ **FORBIDDEN** to declare "we have low-code governance" without being able to show the inventory with owners and
  the date of the last review.
- **Cadence**: continuous inventory, orphan sweep on every employee offboarding, criticality
  and usage review quarterly, review of data policies and new connectors quarterly
  (the platforms **add connectors constantly**, and an unclassified new connector is a
  hole by omission), and contract review six months before renewal.

## 8. Mandatory web verification

Before pinning any datum from this document:

1. **Default environment and environment types**: verified verbatim at
   `learn.microsoft.com/power-platform/admin/environments-overview` (Aug 2026). Check included
   capacities and roles, which Microsoft changes without notice.
2. **Data policies**: verified verbatim at `learn.microsoft.com/power-platform/admin/wp-data-loss-prevention`.
   **Check in particular the list of *nonblockable* connectors and the status of virtual
   connectors and of the *advanced connector policies*, which were in transition as of Aug 2026.**
3. **Orphaned flows**: procedure and cmdlets verified in the raw source of the Microsoft
   support article (`SupportArticles-docs`, `manage-orphan-flow-when-owner-leaves-org.md`,
   document date 11 Jun 2026). **Warning**: the official example uses the AzureAD module, which is
   **deprecated** — rewrite it against Microsoft Graph before using it.
4. **Microsoft prices**: verified verbatim on `microsoft.com` (Power Apps, Power Automate,
   Copilot Studio) as of Aug 2026. They change, and the Copilot Studio model migrated from "messages" to
   "credits": **verify the current name and unit before budgeting**.
5. **Prices of the other platforms**: **declared gap.** The figures for OutSystems, Mendix,
   Appian, Retool, Zapier and Airtable in §3.6 come from **web search and third-party pages**, not
   from the vendor's source; **OutSystems and Appian do not publish prices** and only quote. Use them
   to recognise the **metering model**, never as a figure in a budget.
6. **n8n licence**: verified raw (`LICENSE.md` from the repository). Re-read it before
   deploying: it is *fair-code*, not OSI, and **the terms have changed in the past**.
7. **Product status**: retirements, renames and packaging changes. In this domain the
   names change every few quarters and the service limits with them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
