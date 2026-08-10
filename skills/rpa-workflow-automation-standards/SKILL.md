---
name: rpa-workflow-automation-standards
description: Automating a business process with a robot that drives a user interface, and knowing when not to. Use when deciding between RPA and an API integration, when a screen-scraping or UI-driving automation is proposed against an ERP, a mainframe emulator, a legacy web app or a Citrix session, when building or reviewing robots in UiPath Studio (.xaml projects, Orchestrator queues, assets and Credential Stores), Automation Anywhere, SS&C Blue Prism, Power Automate Desktop (desktop flows, machine registration, attended versus unattended bots, Power Automate Premium/Process/Hosted Process licensing per bot), Robot Framework (.robot suites, SeleniumLibrary, Browser library) or Playwright driving a real application, when the robot needs an identity and credentials of its own instead of a named employee's account, when designing work queues, idempotent retries, partial-failure recovery and the half-completed transaction, when setting SLA, monitoring and alerting for an unattended process, when inventorying robots and finding the orphaned one still moving money, or when choosing a real workflow engine (Temporal, Camunda, Apache Airflow, Windmill, n8n) instead of RPA.
---

# RPA and process automation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **automating a business process end to end**: deciding what to automate it with,
building the robot or the flow, giving it an identity and credentials, orchestrating it, making it
resilient to partial failure, watching it and **governing it for the years it will keep running**.

Triggers: "automate this process", "the system has no API", UiPath Studio `.xaml`,
Orchestrator, queues and *assets*, Automation Anywhere Control Room, SS&C Blue Prism, *digital worker*,
Power Automate Desktop, *desktop flow*, machine registration, attended and unattended bot,
Robot Framework `.robot`, Playwright or Selenium driving a real application (not a test),
3270/5250 emulator, Citrix session, OCR over a screen, "the robot broke because they changed
the screen", work queue, retry, "the process was left half done", robot inventory,
"whose robot is this?", Temporal, Camunda, Airflow, Windmill, n8n.

**Hard rule that orders the whole document: if there is an API, RPA is the last option, not the first.**
RPA mimics a person in front of a user interface; API integration speaks the contract the
system publishes. The first breaks when somebody moves a button —and that somebody is not you—; the
second breaks when the vendor changes the contract, which is an announced, versioned and
negotiable event. **No tool compensates for that asymmetry.**

**RPA is legitimate, and only, when at least one of these holds and which one is documented:**

1. **The system has no API** and will not have one (closed product, mainframe, desktop application
   with no integration).
2. **The vendor has an API but does not open it**, or charges a multiple of the robot's cost for it.
3. **The cost of integrating is disproportionate to the life of the process**: a process that disappears
   in 12 months because of an already planned migration.
4. **An explicit temporary bridge**, with a written retirement date, while the real integration
   is being built.

Outside those four cases, a robot is **technical debt on the payroll**: you have bought the fragility
without any of the advantages.

**Second thesis, the one that causes the real incidents: the dangerous state is not the robot that is down, it is the
half-executed process.** A robot that fails at step 7 of 12 leaves an invoice recorded but not
posted, an order created but not confirmed, a payment started but not reconciled. The outage is visible; the
inconsistent state is not. The whole of §3.3 exists because of this.

**Not applicable**: see `lowcode-governance-standards` (direct sister with a
sharp boundary, because Power Automate shows up in both: **hers the governance of the
low-code platform** —application and flow catalogue, environments and their lifecycle (ALM), *citizen
developers* and their enablement, connector data loss prevention policies, *shadow
IT*, the platform licensing model, who may create what—; **ours the robot and its
credential**: that the automation drives a user interface, the non-human identity with
which it does so, the vault it takes the password from, the work queue, the idempotent retry, the
recovery of the half-done process and the SLA of the automated process. A *cloud flow* calling a
connector is platform governance; a *desktop flow* that clicks buttons with somebody's credentials
is ours), `api-design-standards` (**the correct alternative**: contract, versioning,
pagination, idempotency and compatibility of the integration you should be building instead
of the robot), `identity-access-management-standards` (**IdP design, the lifecycle of the
non-human identity, RBAC and access review are hers**; here the requirement that the robot has its own
identity and what gets recorded of what it does), `secrets-management-standards` (**the vault, the rotation and
the issuance of ephemeral credentials are hers**; here the rule that the robot never stores the
password and what happens when rotation breaks the robot), `ai-agents-standards` (**the agentic
loop, tool design, the iteration limit, human approval and the OWASP ASI
risks are hers**; see §7.3: an LLM that clicks buttons inherits *all* the problems of this skill
and adds non-determinism), `ai-agent-workflow-standards` (coding agents in the team, not
business robots), `testing-qa-standards` (**Playwright, Selenium and Robot Framework as a *testing*
tool are hers**; here the same tools used to **operate** a system in production,
which is a different use with different risks), `data-engineering-standards` and
`streaming-cdc-standards` (**if the process is moving and transforming data, the answer is a pipeline,
not a robot**), `observability-standards` (telemetry platform; here what instruments an automated
process), `incident-management-standards` and `itsm-itil-standards` (on-call, escalation, change and
CMDB; here the robot as a service entering those processes), `grc-compliance-standards` (SoA,
control and audit; here the technical traceability that makes auditing the robot possible),
`privacy-engineering-standards` (**the robot sees screens with personal data and takes screenshots**:
minimisation, retention and processing are hers), `appsec-standards` (agnostic vulnerability
classes), `python-standards` / `powershell-standards` (**very often the honest answer is a
40-line script**, and its quality is governed by them), `git-workflow-standards` (versioning of the
robot, which is indeed mandatory §4), `cicd-standards` (deploying the robot across environments).

## 2. Default decisions / Toolchain

> Verify the latest version, licence and pricing model on the web before pinning them (§8).

### 2.1 The decision ladder, top down

You pick **the first one that solves the problem**. Going down a rung requires justifying in writing why
the previous one fails.

1. **Do not automate**: remove the step. Many processes are leftovers of a system that no longer exists.
   Automating a bad process produces a bad process, faster.
2. **Configure the system** so it does what the person does (rule, native *workflow*, scheduled
   report).
3. **API / event / webhook integration** between the systems involved.
4. **Database or exchange file**, if the vendor officially supports it.
5. **Workflow engine** with coded activities (Temporal, Camunda, Airflow) to orchestrate 3 and
   4 when the process is long, has states and needs durability.
6. **RPA**, with one of the four justifications from §1 and a **review date**.
7. **A person with a checklist**, if the volume does not justify any of the above. It is a valid
   answer and it is discarded far too early.

### 2.2 Tools

| Tool | Licence / cost model | When |
|---|---|---|
| **Power Automate Desktop** | Commercial, by subscription. As of Aug 2026, list prices: **Premium $15 user/month** (*attended* RPA), **Process $150 bot/month** (*unattended* RPA), **Hosted Process $215 bot/month** (includes hosted VM) | Microsoft shop with Entra ID and Power Platform already running. **The jump from attended to unattended multiplies the cost tenfold: that is the economic decision, not the technical one** |
| **UiPath** | Commercial. *Basic* entry tier published from ~**$25/month** with **2 robots**; the rest is "contact sales". Units: *Basic/Plus/Pro* users and *Unattended* robots | Large deployments with Orchestrator, queues and *Credential Store*. The orchestrator's maturity is its real advantage |
| **Automation Anywhere** | Commercial, per bot/user. **Not verifiable on the public web from this document** (§8) | Alternative in the same category |
| **SS&C Blue Prism** | Commercial, historically per *digital worker*. **Not verifiable from this document** (§8) | Heavily regulated environments with strong central control |
| **Robot Framework** | **Apache-2.0** (repository `LICENSE.txt`) | Keyword-driven automation, readable by the business, and above all **testing**. As production RPA it requires you to build orchestration, queues and vault yourself |
| **Playwright** | **Apache-2.0** (repository `LICENSE`) | Driving a browser reliably. **The best technical option when the target system is web**: robust selectors, auto-waiting, traces. No orchestrator: combine with 5 |
| **Temporal** | **MIT** (repository `LICENSE`) — managed service separate | Long-running processes with **execution durability**, retries and compensations. The process state **is** the code |
| **Camunda 8** | **Camunda License 1.0** — *source-available*, **not open source**: *"If Your Use of the Software does not comply with the terms and conditions described in this License, You must purchase a commercial license"* | Processes the business must **see and model** (BPMN), with human tasks |
| **Apache Airflow** | **Apache-2.0** (`LICENSE`) | **Scheduled batches with dependencies between tasks.** It is not a business process engine and has no human tasks |

### 2.3 Workflow engine ≠ RPA

They are constantly confused and they do not compete:

- **RPA** = the **hand** that operates an interface that does not belong to you. Fragile by construction.
- **Workflow engine** = the **brain** that knows which step the process is on, retries, compensates,
  waits for a person and survives a restart. It touches no screen.
- **They are used together**: the engine orchestrates and the robot is one of its activities, the most fragile one, with
  its own *timeout* and compensation. **A robot that orchestrates other robots is a home-made
  workflow engine, badly built and without durability** — that is the most common antipattern of the domain.
- Differences that decide: Temporal gives **execution durability** (the process survives the
  *worker* restart without writing state by hand); Camunda gives a **BPMN model visible to the business and
  human tasks**; Airflow gives **batch scheduling with a dependency graph**. Choosing Airflow
  for a business process with human waits is a category error.

## 3. Structure and conventions

### 3.1 The robot as a system, not as a recording

- **Every robot lives in version control** and is deployed by pipeline across environments
  (`git-workflow-standards`, `cicd-standards`). A robot that only exists in the orchestrator is a
  robot that cannot be reviewed, reverted or audited.
- **No record and replay.** Recording produces selectors by coordinate and by index, which
  is exactly what breaks. Selectors **by stable identifier, by role or by anchored
  text**; never by on-screen position, never by table index, never by pixel capture
  if another route exists.
- **Configuration outside the robot**: URLs, paths, thresholds, mailboxes. A robot with the environment
  embedded cannot be tested in pre-production.
- **Separation by layers**: (a) *connectors* that talk to each system, (b) *business rules*,
  (c) *orchestration*. A screen change must touch only (a). Without this separation, every vendor
  change forces you to re-read the whole process.
- **OCR and computer vision are the last resort**, with an explicit confidence threshold and **rejection
  to an exception queue** below it. OCR without a threshold invents figures silently, and that is the
  worst possible property in a financial process.

### 3.2 Work queues

The unit of work is the **queue item**, not "the robot run". Looping over
an in-memory list makes partial retry and observability impossible.

- Each item has a **unique business identifier** (invoice number, order number), an explicit
  **state** (`pending`/`in progress`/`done`/`business exception`/`system exception`),
  an **attempt counter** and a **trace**.
- **Distinguish a business exception from a system exception.** The first (the customer does not exist, the
  document is missing) **is not retried**: it goes to human review. The second (the screen did not respond) is
  retried with exponential backoff and a maximum. Confusing them produces robots that retry 200
  times something that will never work, or that discard valid work.
- **Retry limit and an explicit final destination** (dead queue with an owner), never infinite
  retry.
- **Mandatory idempotency**: before creating anything, check whether it already exists by its business key.
  A retry **cannot** duplicate a payment, an order or a ledger entry. If the target system accepts an
  idempotency key, it is used; if not, you query before writing.

### 3.3 The half-executed process

This is a design requirement, not an improvement:

- **A checkpoint after every step with an external effect**, persisted outside the robot.
- **A compensation defined for every reversible step** and an **explicit boundary for the irreversible ones**:
  there are steps that cannot be undone (an email sent, a payment issued) and the design must
  concentrate them **at the end** and behind full validation.
- **Recovery by resumption**, not by full re-execution: on start-up, the robot queries the
  real state of the target system and decides, instead of assuming it starts from scratch.
- **Clean shutdown**: on a stop signal or a maintenance window, the robot **finishes the item
  in progress and does not take another**. Killing the process midway through an item is how the inconsistent
  states nobody finds until the accounting close get generated.
- **A global stop switch** reachable without deploying anything, and **tested**. When a robot
  starts doing damage, the time to stop it is the metric that matters.

### 3.4 Execution environment

- **The unattended robot runs on its own machine or session**, dedicated, not on anybody's
  laptop. Microsoft's documentation says it bluntly: before registering a machine to
  run flows from the cloud, *"ensure the machine is secured and the machine's admins are
  trusted"*, and when creating a connection *"you allow Power Automate to create a Windows session on your
  machine to run your desktop flows. Make sure you trust co-owners of your flows before using your
  connection in a flow."* Operational translation: **whoever administers that machine or co-owns that flow
  has, de facto, the robot's permissions.**
- **A machine rebuildable from code** (image + configuration), because it is going to get corrupted.
- **Attended versus unattended is not just price**: the attended one runs with the session and permissions
  of a person who is present and therefore **inherits their identity** —it is the fast lane to the problem in §5.1—;
  the unattended one requires its own identity and is therefore the only correct way to operate in production.

## 4. Quality and testing

Gates in order of increasing cost:

1. **Code review of the robot**, with the same rules as any other code
   (`code-review-standards`). A `.xaml` is code.
2. **The tool's static analysis** (UiPath analysers, `robocop` for Robot Framework):
   fragile selectors, cleartext credentials, deprecated activities → they break the build.
3. **Tests of the business rules isolated from the interface.** If the logic can only be tested by
   clicking buttons, the architecture in §3.1 is wrong.
4. **A pre-production environment with realistic data** and a full run of the process. **FORBIDDEN
   to test in production "because there is no other environment"**: if the target system has no test
   environment, that is a project risk to be escalated, not an excuse.
5. **Injected failure test**: kill the robot midway through an item, cut the network, return an
   unexpected screen, expire the session. **Verify that the state is left consistent and resumable.**
   This is the test that tells a serious robot from a recording.
6. **Credential rotation test**: rotate the secret and check that the robot carries on. Without this
   test, rotation ends up being disabled "because it breaks the robots", and that is where you lose the game.
7. **Interface-change resilience test**: at least a periodic run against the most recent version
   of the target system, and **a subscription to its release notes** — which is the only advance warning
   you are going to get.

## 5. Stack security

### 5.1 The original sin: the robot's credential

The structural failure of the domain is a robot running **with a real person's account**,
usually the analyst who built it, with their full permissions, with no expiry and with no way
to tell in the log what the person did and what the robot did. When that person changes
job or leaves, either the robot disappears or somebody "inherits" a ghost account. It is, moreover,
the direct route to undetectable fraud: **the target system's audit log says it was done by
Juan**.

Hard rules:

- **Its own identity per robot and per process.** A named service account (`svc-rpa-<process>`),
  not generic, not shared between robots, not a person's. **Not even shared between two
  different processes of the same robot**: if they share, you cannot withdraw permissions from one without breaking the
  other.
- **Real least privilege**: the process's permissions, not the analyst's. And **periodic review**
  like any other identity (`identity-access-management-standards`).
- **The password lives in the vault, not in the robot nor in the orchestrator in cleartext**: UiPath's
  Credential Store, Azure Key Vault, HashiCorp Vault, CyberArk. **Ephemeral credentials or automatic
  rotation whenever the target system supports it**; if it does not, scheduled rotation and
  documented as an accepted risk.
- **The robot cannot have interactive MFA** — that is its technical limitation and it is not solved
  by disabling MFA for the whole organisation nor by "remembering the device". It is solved with
  non-interactive authentication (certificate, managed key, workload identity) or it is
  documented as a risk with compensations (network isolation, time window, amount limits).
- **Traceability**: every robot action links `process id + queue item id + robot
  version + who launched it`. Auditing an automated process without that link is impossible.
- **Segregation of duties**: whoever builds the robot does **not** approve its deployment to production nor
  administer its credential. In financial processes this is control, not bureaucracy
  (`grc-compliance-standards`).

### 5.2 The robot's surface

- **The robot's machine is a production system** with privileged access to business systems:
  it is hardened, patched and monitored as such. **FORBIDDEN** to use it as anybody's desktop or
  to give it free browsing.
- **Screenshots and logs with personal data**: the robot sees payslips, records and
  accounts. Screenshots only on error, with short retention, encrypted and with restricted access
  (`privacy-engineering-standards`).
- **Untrusted input**: the data the robot reads from emails, PDFs or screens is third-party
  input. It is validated before being written anywhere, and **never interpolated into a command,
  a query or a formula**.
- **Action limits**: maximum amount, maximum number of items per run, allowed time
  window. A robot with no ceiling is an amplification of errors at machine speed.

## 6. Performance and operability

- **The SLA belongs to the business process, not to the robot.** "The robot was up 99 %" says nothing;
  what is measured is **items completed within the committed deadline**.
- Minimum metrics per process: items processed, **business exception rate** and **system
  exception rate** separately, time per item, age of the oldest item in the queue, and
  **backlog** — which is the early signal that something is wrong.
- **Alerts on business symptoms**: "the queue is growing", "zero items processed in the
  expected window", "the exception rate exceeds the threshold". Not on "the process is not responding".
- **Suspicious silence**: a scheduled robot that does **not** run generates no errors. Alerting on
  absence (*dead man's switch*) is mandatory; without it, a stopped robot goes unnoticed for weeks.
- **Fallback to the manual process**: for every critical automated process there is a written manual
  procedure and an estimate of how many people it takes. If automating removed the capacity to
  do it by hand and the robot goes down at month-end close, the problem is the business's, not IT's.
- **Real cost per process**: bot licence, machine, maintenance and **the human time spent
  managing the exception queue**, which is what nobody adds up. A process with 30 % exceptions is not
  automated.

## 7. Long-term sustainability

### 7.1 Governance: the orphaned robot

**A robot with no business owner keeps moving money.** It does not stop by itself, it does not warn and it does not appear in
any application inventory. Requirements for it to exist:

- **A central robot inventory** with: process, systems it touches, **named business owner**,
  technical owner, identity it uses, permissions, criticality, date of last review and **expiry
  date**.
- **Expiry by default**: every robot is reviewed at least annually; if nobody claims it, **it is
  switched off** (with a grace period and notice). It is the only known way to avoid accumulation.
- **Registration in the CMDB and in the change process** (`itsm-itil-standards`): a change to a system
  a robot depends on must be able to identify that robot **before** the change.
- **Exit plan**: for each robot, the condition under which it is replaced by a real integration and
  who watches for it. Without this, the "temporary bridge" of justification 4 in §1 is permanent.

### 7.2 Prohibitions

- ❌ **FORBIDDEN** to build a robot against a system that **does** expose an API, without written
  and approved justification.
- ❌ **FORBIDDEN** for a robot to run with a natural person's account.
- ❌ **FORBIDDEN** to share one identity between several robots or processes.
- ❌ **FORBIDDEN** to store credentials in the robot, in a file, in the repository or in the
  orchestrator in cleartext.
- ❌ **FORBIDDEN** to disable an organisation's MFA, or to exclude real users from MFA, "so that
  the robot works".
- ❌ **FORBIDDEN** to record and replay, and forbidden are selectors by coordinate, by positional
  index or by pixel comparison when an alternative exists.
- ❌ **FORBIDDEN** a robot that is not in version control.
- ❌ **FORBIDDEN** to deploy and test directly in production.
- ❌ **FORBIDDEN** a step with an external effect without a prior idempotency check.
- ❌ **FORBIDDEN** to retry a business exception, and forbidden is retry without a maximum or a
  final destination.
- ❌ **FORBIDDEN** a process without a tested stop switch.
- ❌ **FORBIDDEN** a robot in production without a named business owner or a review date.
- ❌ **FORBIDDEN** to use the robot's machine as a workstation or to give it free browsing.
- ❌ **FORBIDDEN** to capture screens with personal data outside an error, without encryption and without
  bounded retention.
- ❌ **FORBIDDEN** to justify an RPA programme with the vendor's FTE saving figures. **Figures
  of the "RPA saves X % of FTE" kind are marketing material with no published methodology.** If
  the investment must be justified, you measure **the specific process before and after**, counting the exception
  queue and the maintenance; if it has not been measured, you say it has not been measured.
- ❌ **FORBIDDEN** to call "automated" a process whose percentage of manual exceptions is not
  published.

### 7.3 When the robot is an LLM

An agent that "uses the computer" (clicks buttons, reads screens) **is RPA**, and therefore inherits everything
above: its own identity, vault, least privilege, queue, idempotency, limits, traceability,
stop switch. **And it adds two problems classic RPA does not have**:

1. **Non-determinism**: the same screen can produce two different actions. Everything that in classic
   RPA is tested once must be tested statistically here
   (`llm-evaluation-standards`).
2. **Indirect prompt injection**: the text on the screen the agent reads **is the attacker's
   input**. An email, a PDF or a form field can contain instructions. With
   business credentials and access to transactional systems, this is the full lethal trifecta.

Operational consequence, not philosophical: **mandatory human approval before any
irreversible action or any action with economic impact**, without exception, and amount and volume limits enforced
**outside** the agent. The design of the loop, its caps and its *sandbox* belong to `ai-agents-standards`; that
it also complies with what is here is not optional.

## 8. Mandatory web verification

- **Pricing models, which change and are half the decision**: the official pricing page of
  Power Automate (as of Aug 2026, list: **Premium $15 user/month**, **Process $150 bot/month**, **Hosted
  Process $215 bot/month**), of UiPath (*Basic* from ~**$25/month** with 2 robots; the rest "contact
  sales"). **Declared gaps: neither the pricing model nor the licensing terms
  of Automation Anywhere or SS&C Blue Prism could be obtained** from public sources (one returned 404 and the other
  did not resolve). Before comparing them, demand the offer in writing from the vendor and **verify whether the
  price is per concurrent robot, per process or per run** — the difference decides the TCO.
- **Licences read raw**, not by the GitHub label: Robot Framework **Apache-2.0**
  (`LICENSE.txt`), Playwright **Apache-2.0** (`LICENSE`), Temporal **MIT** (`LICENSE`), Airflow
  **Apache-2.0** (`LICENSE`), and **Camunda: `Camunda License 1.0`, *source-available* and not OSI** —
  re-read it before assuming anything, because it conditions use in a product.
- **Version and support** of the chosen RPA tool, and **its compatibility matrix with the
  version of the target system** (browser, ERP, emulator). It is the number one cause of breakage after
  an update.
- **Release notes of the target system**: subscription mandatory; it is the only advance warning that
  the interface is going to change.
- **CVEs** of the orchestrator and of the robot *runtime*: they are systems with business credentials, not
  desktop tools.
- The current state of models' "computer use" capabilities and of their safety guidance
  before proposing an agent for a transactional process.

If the web contradicts this document, **the web wins** — flag the discrepancy.
