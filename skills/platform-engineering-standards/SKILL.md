---
name: platform-engineering-standards
description: An internal platform is a product whose customers can refuse to use it. Use when deciding whether to build an internal developer platform at all, defining a golden path and its documented escape hatch, writing catalog-info.yaml or app-config.yaml, running or upgrading Backstage and its scaffolder software templates (template.yaml, the new frontend system, plugin migration), evaluating Port blueprints, Cortex, Humanitec Platform Orchestrator or a Backstage distribution, designing service catalog metadata and ownership, versioning the platform API as a contract, choosing between Crossplane (CompositeResourceDefinition, Composition, composition functions, namespaced XRs in v2) and reusable infrastructure modules or an operator, adopting Score (score.yaml) as a workload spec, building self-service with guardrails through admission policy, quotas and ephemeral environments, setting platform SLOs and a deprecation policy for a platform capability, measuring adoption by time-to-first-deploy and toil reduction instead of registered users, reducing team cognitive load in the Team Topologies sense, or citing DORA findings on internal developer platforms.
---

# Platform engineering standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**An internal platform is a product with internal customers who may choose not to use it.** Everything
else follows from that: it has an owner, a roadmap, versions, support, documentation, deprecation and
an adoption metric that can come out badly. If the team dodges it —deploys on its own, copies the
module and modifies it, opens a ticket to bypass it— **the platform has failed**, and the failure is
the platform's, not the team's.

Corollary that governs the rest of the document: **forced adoption hides the failure instead of
fixing it.** Mandating it by decree removes the only reliable signal the platform had —desertion—
and replaces the question *"why aren't they using it?"* with *"who is in breach?"*.
The platform is still bad and now nobody can measure it. This is **not** an argument against
mandatory controls: there are controls that genuinely are mandatory (security policy, compliance
gates). What cannot be mandatory is **convenience**: the paved road prevails because it is the
fastest, not because the other one is forbidden.

Covers: the decision to build it or not, the operational difference with DevOps and with SRE, the
paved road and its documented exit, the portal and the service catalog, the service creation
templates, the platform API as a versioned contract, infrastructure abstractions
(Crossplane and operators versus modules), self-service with guardrails
(admission, quotas, ephemeral environments), the platform as a product (owner, roadmap, metrics,
support, deprecation), DORA as an outcome measure and cognitive load as the theoretical foundation.

**Not applicable**: see `sre-practice-standards` (**SLOs, on-call, *error budget* and service
reliability are theirs**; **the platform also has SLOs and they apply to it as-is** —§6.1—: it is a
service in production whose failure blocks every team at once), `cicd-standards` (**the concrete
pipeline is theirs**: jobs, runners, OIDC, signing, SLSA; here only **that a pipeline template
exists on the paved road, who maintains it and how it is updated in the repos that already
use it**), `kubernetes-standards` and `iac-standards` (**the substrate**: how a manifest,
a module or a state is written; **here the abstraction offered on top, what is hidden and what is let
through**), `observability-standards` (the telemetry platform, its SLIs and its instrumentation;
**here only that the paved road brings it out of the box and with no work from the team**),
`identity-access-management-standards` (federation, RBAC, identity lifecycle; here the
identity **of the platform** as a privileged subject —§5), `secrets-management-standards`
(management, rotation and consumption of secrets; here that the template must not force anyone to paste one),
`container-runtime-security-standards` (isolation and runtime detection of what the
platform deploys), `api-design-standards` (**the contract of the platform API is designed
with their rules**: versioning, errors, pagination, compatibility; here only the obligation that
that API *exists* and is a contract), `developer-workstation-standards` (the
developer's machine, their dotfiles and their local environment; **here what runs on the
server side**; the meeting point is the reproducible development environment, which is decided there),
`testing-qa-standards` and `code-review-standards` (test strategy and quality control of the
diff; **the platform applies them to its own code like any product, it does not redefine them**),
`tech-leadership-standards`, `enterprise-architecture-standards`, `itsm-itil-standards`,
`knowledge-management-standards` and `product-discovery-standards` (governance,
enterprise architecture, service and knowledge management; **the platform is a product and its
needs discovery is governed by `product-discovery-standards`** — here we do not reinvent
how a user is interviewed), `microservices-architecture-standards` (decomposition into
services and system topology; **the platform does not decide how many services there should be, it only
makes creating and operating each one cheaper**), `finops-standards` (**reciprocal: the cost of the platform is
one more economic unit and is measured with their method**; and **the platform is where the
tagging gates** that skill defines are implemented).

## 2. Default decisions

> Verify the latest version and status of the projects cited on the web before committing to anything (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Build a platform? | **No, until the threshold in §3.1 is met** | Yes, with a named owner and a permanent budget |
| Initial scope | **One paved road, for the most repeated case** | Several, only if they are genuinely different |
| Primary interface | **Git + the existing pipeline** (the developer already lives there) | Web portal if scattered information must be aggregated (§3.5) |
| Portal | **Backstage** (Apache-2.0, CNCF *Incubating*) if self-hosted | Commercial product (Port, Cortex, Humanitec) if there is no team to maintain the portal as software of your own (§2.1) |
| Deployment contract | **Versioned platform API** (declarative, in Git) | `Score` (`score.yaml`, CNCF *Sandbox*) if a workload spec portable across targets is needed |
| Infrastructure abstraction | **Reusable IaC modules** for 80 % of cases | **Crossplane** when continuous reconciliation and a Kubernetes API of your own are needed (§3.7) |
| Guardrails | **Policy as code at admission** + quotas | Human review only where policy cannot be expressed |
| Ephemeral environments | **By default, with TTL and automatic destruction** | Permanent per-team environments if the startup cost is prohibitive |
| Main success metric | **Time to first production deploy of a new service** + **reduction of *toil*** | — |
| Adoption | **Voluntary and earned** | Mandatory **only** for security and compliance controls, never for convenience (§1) |

### 2.1 Status, licence and governance of the pieces (verified)

| Piece | Licence (raw `LICENSE`) | Status / governance | Decision note |
|---|---|---|---|
| **Backstage** | **Apache-2.0** (`backstage/backstage`) | **CNCF**: accepted **8 Sep 2020**, **Incubating since 15 Mar 2022**; **still not graduated** as of Aug 2026. Created at Spotify (2016), open-sourced in 2020 | It is a **framework**, not an installable product: you build an application of your own. That is its biggest cost and the no. 1 reason for abandonment |
| **Crossplane** | **Apache-2.0** (`crossplane/crossplane`) | **CNCF Graduated since 28 Oct 2025** (accepted 25 Jun 2020, incubating 14 Sep 2021). Current line **v2.x** | **v2 changed the architecture** (§3.7): do not assume v1 documentation |
| **Score** | Open specification (`score.dev`) | **CNCF Sandbox** since **8 Jul 2024**; no promotion to incubation on record as of Aug 2026. Origin: Humanitec | Sandbox = low maturity. Adopt only with the reference implementation proven |
| **Port** | Commercial product (SaaS) | Private company | Pricing and terms per vendor: do not pin from memory (§8) |
| **Cortex** (`cortex.io`) | Commercial product (SaaS) | Private company | **Name collision, a real trap**: in the CNCF catalog, `Cortex` is the scalable Prometheus metrics project, **not** this portal. Do not confuse the maturity status of one with the other's |
| **Humanitec** | Commercial product (Platform Orchestrator, Portal) | Private company, headquartered in Berlin; **no acquisition on record** as of Aug 2026, despite recurring rumours | Verify before pinning it as a strategic dependency |

**Backstage version policy, verbatim from its documentation** (it matters because it determines the
maintenance effort, which is the real cost): main line *"Monthly, specifically on the
Tuesday before the third Wednesday of each month"*; `next` line *"Weekly, specifically on
Tuesdays"* with *"fewer guarantees around breaking changes in these releases, where moving from one
release to the next may introduce significant breaking changes"*. On security: *"Vulnerabilities
with a severity of `high` or `critical` will always be backported to releases for the last 6 months
if feasible."* Deprecation of stable exports: *"The deprecation must have been released for at
least one mainline release before it can be removed."*

**Decision consequence, non-negotiable**: **a monthly release with a 6-month security backport
window implies a continuous maintenance commitment**, not an "we install it and we're
done". If nobody has recurring time assigned to upgrade Backstage, **Backstage is not chosen**.
That calculation is made beforehand, not once the instance has gone a year without updating. On top of that
comes the migration to the **New Frontend System**, which is not a "Backstage 2.0" but an
architectural change delivered within the 1.x line (APIs stabilised and migration recommended from
v1.42.0 onwards, with a documented hybrid phase): **it is planable migration work, not
optional in the long run**.

## 3. Structure and conventions

### 3.1 When NOT to build a platform

Entry rule: **no platform is built until the same delivery problem has been
solved ad hoc at least three times by different teams**. Before that there is no pattern, there is
an assumption, and what gets built is the wrong abstraction — which costs more to retire than
having done nothing at all.

**Do not build it if**:
- **There is a single product team.** With one team, "the platform" is the team's repository.
  A layer of indirection between you and yourself only adds latency.
- **The organisation is small.** There is no magic number published with a methodology, and one is not going to be
  invented here (§8): the falsifiable criterion is the three repetitions and the one in §6.2 (if you cannot
  name the concrete *toil* you eliminate and quantify it in hours/month, there is no case).
- **The real problem is process, not tooling.** Honest diagnosis: if deployments
  take three weeks because there is an approval committee, a platform does **not** fix that — it
  puts a pretty interface on the committee. Same for teams that cannot deploy for lack of
  permissions, an architecture that prevents deploying in parts, or an organisational
  bottleneck. **The question test**: *"if we build this and it works perfectly, does the
  problem go away?"* If the answer is no, the problem was not technical.
- **Nobody can own it full time.** A platform without an owner degrades into a set of
  scripts with no maintainer that everyone is afraid to touch. Worse than not having it.
- **You are copying what a company 50 times bigger did.** Their platform solves their problem
  of organisational scale, not yours.

**The permanent cost, which almost nobody budgets for.** A platform is never "finished": it is maintained.
Budget explicitly, and in writing, before starting:
1. **Substrate upgrades** (Kubernetes, provider, portal) that break its abstractions.
2. **Support for internal users**: questions, debugging failures that look like the platform's and
   are not (or the other way round). It is the line item that is most underestimated.
3. **Documentation** that expires with every change.
4. **Migrations** that the platform imposes on its users when it deprecates something.
5. **On-call**: if a team cannot deploy because the platform is down, someone
   brings it back up (§6.1).
6. **The infrastructure cost of the platform itself**, measured as an economic unit
   (`finops-standards`).

If those six line items have no people assigned, the project is not approved: it is a gamble.

### 3.2 The difference with DevOps and with SRE, written precisely

No slogans. The three coexist and answer different questions:

| | Question it answers | Object | Way of working | Fails when |
|---|---|---|---|---|
| **DevOps** | How do we eliminate the handoff between whoever builds and whoever operates? | The **workflow** and *end-to-end* ownership | Cultural and organisational; **it is not a team nor a product** | A "DevOps team" is created that is the old operations team with a new name: it reinstates the handoff it came to eliminate |
| **SRE** | How do we guarantee that the service in production meets its reliability target? | The **service in production**: SLO, *error budget*, on-call, capacity, postmortem | Engineering applied to operations, with an error budget as the arbiter | It becomes the team that fixes what others break, with no power to halt deployments |
| **Platform engineering** | How do we reduce the product team's cognitive load regarding the substrate? | An **internal product** with users, versions and support | Product: discovery, roadmap, measured adoption, deprecation | It is measured by what it builds instead of by what its users achieve; or it is imposed by decree (§1) |

The split in one sentence in case of doubt: **DevOps is how the organisation works; SRE is who
answers for the service being alive and with what budget; the platform is what product is
offered to both so that it costs them less.** The platform does **not** absorb the production
responsibility of the product team: if the team stops answering for its service because "the
platform handles it", the operations silo has been rebuilt under another name.

### 3.3 The paved road (*golden path*)

**Operational definition**: a complete, opinionated and supported journey, from *nothing exists* to
*it is in production and observed*, for **one concrete type of work**. A paved road is not
a list of recommended tools nor a wiki page: it is something that is **executed** and produces
a working service.

It covers, as a minimum and with no work from the team:
- Repository created, with ownership, branch protection and review configured.
- Build, test and deploy pipeline **working on the first commit**.
- Workload identity and access to secrets, **without anyone pasting a credential**.
- Observability out of the box: structured logs, metrics and traces already emitted and already visible
  (`observability-standards`), with a base dashboard and alert.
- Non-production environment and route to production.
- Registration in the catalog with an owner (§3.5).
- Mandatory cost tags already in place (`finops-standards` §3.2).

**What distinguishes it from a mandate**, point by point:

| | Paved road | Mandate |
|---|---|---|
| Why it is used | Because it is **the fastest route** to the same result | Because the other one is forbidden |
| What happens if it does not fit | You take the documented exit (below) and **that is a product signal** | You request an exception from a committee and a breach is recorded |
| What measures its success | Voluntary adoption (§6.2) | Compliance — which says nothing about whether it is good |
| Who bears the bad fit | The platform: fixing it is its job | The product team |

**Hard rule: a documented exit must exist.** Every paved road publishes, in the same
place as the usage guide: which cases it does **not** cover; how to exit (lower-level interface, required
permissions, minimal template); **what you lose by exiting** (support, automatic updates,
out-of-the-box dashboards), written unambiguously; and **what is still required regardless** (security
and compliance controls are not part of the paved road, they are requirements of the environment — they
are applied at admission and hold for everyone, §3.8).

Without a documented exit, the team's options are to comply even though it does not fit or to build itself a
shadow platform. The second is what always happens, and on top of that with nobody seeing it.
**Every use of the exit is a product data point**: it is counted, the reason is asked for and it feeds the
roadmap. If the exit is used a lot for the same reason, that reason is the next piece of work.

### 3.4 The platform API is a versioned contract

The surface the platform offers —the service descriptor schema, the custom
resources, the template parameters, the deployment endpoint— **is a public API
with clients you do not control**. Therefore:

- **Explicitly versioned** and backwards compatible within a major version. The
  concrete design (schema, errors, field deprecation, version negotiation) is governed by
  `api-design-standards`; here only the obligation to treat it as an API.
- **Declarative and in Git**. The team's intent lives in its repository; the platform reconciles.
  A platform whose only interface is a button on a web page is neither reproducible nor auditable, and it is
  no use for disaster recovery.
- **Incompatible change = migration with a deadline, tooling and communication**, never a silent *breaking
  change* in a minor release (§7.2).
- **Minimal surface**: every exposed field is a perpetual commitment. It is cheaper to add a
  field a year from now than to retire one.
- **The default values are the most important product decision the platform makes**:
  they determine what 95 % of services do. They are reviewed and versioned as code, they are not
  dropped into an `if` in a template.

### 3.5 Portal, catalog and templates

**The portal is justified when information that is scattered today has to be aggregated** (who owns
what, which version is deployed, what depends on what, what alerts it has, what documentation
exists). If that is already solved, the portal is one more layer to maintain. **A portal is not a
platform**: it is an interface. Building the portal first and the platform afterwards is the domain's most
frequent sequencing mistake — you end up with a pretty directory of services that nobody
can create or deploy from there.

**Service catalog**. It is the substrate of everything else, and its only hard requirement is that it **be
true**. Minimum metadata per entry, with a mechanical owner:
- **Owner**: **team** identifier from the corporate directory, **never** a person. People
  leave; teams are reassigned explicitly.
- **Criticality level** (determines SLO, on-call and deployment requirements).
- **Declared dependencies** (what it consumes, what it exposes).
- **Live links**: repository, pipeline, dashboard, runbook, documentation.
- **Data classification** it handles (`grc-compliance-standards`, `privacy-engineering-standards`).
- **Cost tags** consistent with `finops-standards` §3.2.
- **Lifecycle**: experimental / production / **deprecated**. Without the third state, the catalog
  grows forever.

**Catalog rules, falsifiable**:
1. **It is generated from code**, not filled in by hand. The descriptor lives in the service's
   repository (e.g. `catalog-info.yaml`) and is discovered; a hand-maintained catalog is
   out of date within a quarter.
2. **An entry without a valid owner = a broken entry.** It is detected automatically and reported, and there is a
   deadline after which the service is visibly flagged as orphaned.
3. **A catalog with false data is worse than no catalog**: people make decisions with it. Automatic
   consistency test (the owner exists in the directory, the links respond, the declared service
   exists in the cluster).

**Service creation templates (*scaffolding*)**. Central rule, and it is the one that separates a
living platform from a debt generator: **generating code from a template creates a copy
that no longer receives improvements**. Mandatory strategy:
- **What must evolve centrally is not copied: it is referenced.** Pipeline as a versioned reusable
  template (owned by `cicd-standards`), common configuration as a dependency,
  infrastructure modules as a pinned version. The template generates **the minimum that is specific to the
  service**.
- **Updating what has already been generated**: if something is copied, a mechanism must exist to
  update the repositories that copied it (automated PR or migration tool) **and it must be
  tested**. Without that, every new template is a future fire spread across N repositories.
- **The template is tested in CI**: it is executed, the generated service is built, it is deployed to an
  ephemeral environment and destroyed. A broken template blocks every new service at once.
- **Templates are executable code with privileges**: see §5.

### 3.6 Infrastructure abstractions: when Crossplane, when modules

**Crossplane, verified status**: Apache-2.0, **CNCF Graduated since 28 Oct 2025**, line
**v2.x**. **It has had a relevant architectural change and all third-party documentation
predating it is misleading**:

- In **v2**, *composite resources* (XR) and **all** *managed resources* become
  **namespaced**; an XR can compose **any** Kubernetes resource, not just *managed
  resources*.
- ***Claims* disappear.** They were the mechanism by which a namespaced object
  produced a cluster-scoped XR. With XRs already *namespaced* they stop making sense: what used to be
  a *Claim* now **is directly an XR**. In the API reference, `claimNames` is marked
  as deprecated and is not supported in `apiextensions.crossplane.io/v2`.
- The XRD gains a **`scope`** field with three values: `Namespaced` (**the v2 default** and the
  recommended one, for isolation and by Kubernetes convention), `Cluster` (for platform-level
  resources) and **`LegacyCluster`** (v1 compatibility, the only one that still supports *claims*; it is
  what `scope` resolves to if the v1 version of the XRD API is used).
- **Practical consequence**: any design, tutorial or module that revolves around *claims* is
  describing v1. Before copying it, check which version it is written against.

**Choice criteria**, in this order:

| Situation | Choice |
|---|---|
| Infrastructure that is created, changes little and is destroyed with the service | **Versioned IaC module.** It is what the team already understands, it is debugged with the usual tools and it does not add a control plane to maintain |
| **Continuous reconciliation** is needed (drift corrected by itself, not at the next `apply`) | **Crossplane** or an **operator** |
| You want to offer a **domain API of your own** ("a product database") consumable from Kubernetes by the same means as everything else | **Crossplane** (XRD + Composition) |
| The behaviour to automate is **specific to a product and has lifecycle logic of its own** (failover, backup, major upgrade) | **Dedicated operator** from that product's vendor, not a homemade composition |
| The platform team **does not have the capacity to operate an additional control plane** | **Modules.** Crossplane adds one more critical component to the deployment path |

**Honesty warning**, because this is where most money is lost: **an abstraction that only
forwards parameters adds nothing and costs maintenance.** If the XRD or the module exposes
practically the same fields as the underlying resource, you have not abstracted: you have added a layer of
indirection, a new vocabulary to teach and a point of failure. The abstraction is justified
when it **decides** something (applies the right default values, composes several pieces, imposes
policy) and **hides** something the team should not have to know. The rule about what **not** to hide
is in §7.

### 3.7 Self-service with guardrails

Self-service without guardrails is an incident waiting for a date; guardrails without self-service is a
ticket process with more steps. Both, always together:

- **Policy as code at admission**, not in human review. It is the only point where the control
  is applied **regardless of the path the team has taken** — paved road, documented
  exit or a tool of their own. That is why mandatory controls live here and not in the
  template: a template can go unused. The admission mechanics and their tooling belong to
  `kubernetes-standards`; **the decision about what is mandatory for everyone** is taken with security and
  compliance, the platform does not invent it alone.
- **Every new policy enters in warning mode first**, with a report of how many existing objects
  it would flag, and only then blocks. Publishing a policy that breaks already deployed workloads is the
  fastest way to lose the trust that voluntary adoption needs.
- **The denial has to explain how to fix it.** An admission rejection with a cryptic
  message turns self-service into a ticket, which is exactly what you came to eliminate. Message
  with: which rule, why it exists, what to change and whom to ask.
- **Quotas per namespace/team** as an upper bound on damage (resources and cost). A
  quota nobody has ever hit is badly calibrated or decorative: review it.
  **Hard limit, aligned with `finops-standards` §7**: a quota may **halt the creation of
  new resources**, and in non-production it may halt it entirely; **FORBIDDEN for hitting the quota to
  block the deployment of a new version of a service already running in production** —that
  turns an accounting deviation into an availability incident—. If the quota is reached in
  production, admission **warns and escalates to the budget owner**, it does not deny the rollout.
- **Ephemeral environments**: the three requirements are **mandatory TTL**, **verified automatic
  destruction** (and alerted if it fails) and **non-production data**. An ephemeral environment that survives is
  a permanent environment with no owner, no patches and with data of unknown origin. Creating
  ephemeral environments without a TTL "temporarily" is forbidden.
- **Everything that can be created via self-service has to be destroyable via self-service.** If
  creating is a button and deleting is a ticket, the organisation accumulates resources forever.

## 4. Quality and gates

The platform is production software and `testing-qa-standards` and
`code-review-standards` apply to it with no discount. What is specific to the domain:

| # | Gate | What it tests | Breaks |
|---|---|---|---|
| 1 | Lint and schema validation of the descriptors (catalog, templates, XRD/Composition) | That the contract is syntactically valid | Yes |
| 2 | **Contract test of the platform API** | That a descriptor from the previous version **is still accepted** | Yes |
| 3 | **End-to-end test of each template**: generate → build → deploy to an ephemeral environment → check health → destroy | That the paved road works today | Yes. **It is the platform's most valuable gate** |
| 4 | Test of the admission policies with cases that **must** pass and cases that **must** be rejected | That the guardrail neither blocks the legitimate nor lets the forbidden through | Yes |
| 5 | Upgrade rehearsal: apply the new version of the platform on top of an environment with services created by the previous version | That existing users are not broken | Yes |
| 6 | Daily catalog verification (owners exist, links live, orphaned entries) | That the catalog is true (§3.5) | Reports and opens a ticket |
| 7 | Periodic synthetic check of the paved road in production | That creating a new service works **now** | Alerts the platform on-call |

**Edges that must be tested explicitly**, because they are the ones that break in production: a service
name that already exists; an existing repository; insufficient permissions of the user running
the template; **the template half-way through** (repository created and pipeline not) — creation must
be idempotent and retry without duplicating, or leave a clean state; the cloud provider returning
a quota error; the generated service with non-ASCII characters or long names; the update of
a service created by an old version of the template.

## 5. Security: the platform is a single point of compromise

This section is the reason the platform has to be better than the average of what it deploys.
**Its credentials, its templates and its supply chain affect everything it deploys**: whoever
controls it can deploy arbitrary code in every environment, with the platform's legitimate
identity and without triggering any "unauthorised change" alarm, because deploying is exactly
what it does. It is a high-value target by design.

- **Identity**: the platform does **not** use a single credential with permissions over everything. Identity
  per operation and per environment, federated and short-lived (OIDC), with the minimum permission for the
  concrete action. A static admin token in the platform is the organisation's worst
  secret (`identity-access-management-standards`, `secrets-management-standards`).
- **The platform never sees the application's secret**: it wires the workload to the secrets manager
  and steps aside. If the value passes through the platform, the platform is now the company's largest store
  of secrets and nobody designed it that way.
- **Templates are executable code with the platform's privileges.** Concrete
  and verified precedent, not hypothetical: in Backstage, most of the *scaffolder* security advisories
  depend on the attacker being able to **register or edit a template in the catalog**
  — server-side template injection with git token capture (**CVE-2024-53983**,
  medium), path traversal, remote code execution in `v1beta3` templates (the engine assumed
  templates were trusted), stored XSS in the catalog, and **CVE-2026-29184** (March
  2026), a bypass of log redaction that allows exfiltrating secrets from a run through
  the task events. **Design conclusion**: *who can register a template* is a
  first-tier security control, equivalent to *who can deploy to production*. Templates
  live in a repository with `CODEOWNERS` and mandatory review; registering
  templates from arbitrary repositories is **forbidden**.
- **Supply chain of the platform itself**: its base images, its third-party plugins and its
  modules are transitive dependencies of **every** service. Pin by digest, SBOM, signing and
  provenance verification (`cicd-standards`). Catalog reminder: **signed provenance
  is not enough** — malicious packages with valid attestations have circulated; the real cut is the pin
  by digest and the review of what is added.
- **Third-party portal plugins**: in a portal that is built as an application of your own (Backstage),
  a plugin **runs with the portal's privileges** and sees what the portal sees. Every new plugin is
  a security decision with review, not a box that gets ticked.
- **Multi-tenancy**: the boundary between teams is enforced in the substrate (namespaces,
  network policies, RBAC, quotas), **not** in the interface. If the only thing preventing a team from
  seeing or touching another's is that the portal does not show it the button, there is no isolation: there is
  concealment.
- **Audit**: every self-service action leaves an immutable record of **who, what, when, on
  which environment and with which template version**. It is what turns self-service into something
  defensible before `grc-compliance-standards`, and what makes it possible to answer "what deployed this?"
  during an incident.
- **The platform cannot be the only route to production in an emergency.** A documented and
  **rehearsed** break-glass procedure must exist, with a distinct identity, an automatic alert when used and
  a subsequent review. If the platform goes down and nobody can deploy a fix, the platform has
  turned its own unavailability into an unavailability of every
  product (`bcdr-standards`, `incident-management-standards`).

## 6. Operation and measurement

### 6.1 The platform has SLOs and on-call

It is not optional and it is not negotiable: **the platform is a production service whose failure blocks
every team at once.** The SLOs are defined and operated with the method of
`sre-practice-standards` (SLIs, *error budget* and on-call policy live there); here, what has to be
declared as a minimum:

- **Availability of the deployment path** — the route from a commit to production. It is the SLI that
  matters; the portal's *uptime* is secondary.
- **Provisioning latency** of the resources the platform offers (percentile, not mean).
- **Success rate of service creation** from a template.
- **Freshness and correctness of the catalog** (§3.5).

And a rule of conduct: **the platform's error budget consumption is communicated to its
users**, just as an external provider communicates its status. An internal user who does not know whether the
failure is theirs or the platform's loses twice as much time.

### 6.2 Real adoption metrics

**The correct metric is the time to first production deploy of a new service and
the reduction of *toil*.** Both measure the same thing from the two ends: how much it costs to start and
how much it costs to keep going.

| Metric | How it is measured | Why it is the correct one |
|---|---|---|
| **Time to first production deploy** of a new service | From the decision to create it until it serves real traffic, measured end to end, including waits for approvals and access | It is the outcome the platform exists for. It includes everything the team suffers, not just what the platform automates |
| **Reduction of *toil*** | Hours/month of manual, repetitive and automatable work the product team no longer does. It is estimated beforehand and measured again afterwards | It is the saving that pays for the platform. If the concrete *toil* cannot be named, there is no business case (§3.1) |
| Voluntary adoption | % of new services that choose the paved road **having an alternative** | Without an alternative, the number means nothing |
| Use of the documented exit | No. of times and **reason** (§3.3) | It is the roadmap writing itself |
| Internal user satisfaction | Short and periodic survey, with an open question | Detects discontent before desertion |
| Resolution time of platform support requests | Same as an external product | Slow support cancels out any saving |
| Cost of the platform per team served | Economic unit (`finops-standards`) | It is a product and it has a price |

**Why the number of registered users is a false metric**: it counts registration, not use;
it goes up when someone comes in once to look; it goes up automatically when single sign-on is
integrated, without anyone having used anything; and **it is incapable of going down** — so it cannot detect a
failure, which is the only thing you would ask of an adoption metric. The same applies to the number of
services in the catalog (it measures how many services there are, not how much the platform helps) and to the number of
installed plugins.

### 6.3 DORA as an outcome measure, with its nuances

**Verified status of the source, which almost everyone cites wrongly**: DORA stopped publishing under
the name *Accelerate State of DevOps*; the **2025** edition is titled **"State of AI-assisted Software
Development"**, and the most recent publication as of Aug 2026 is **"The ROI of AI-Assisted Software
Development (2026.01)"**. **There is no "DORA State of DevOps 2026"**: what circulates under that
name for 2026 is the **Puppet** report (*State of DevOps Report: Platform Engineering
Edition*) and the **Perforce** one, which are by other authors and use another methodology. Cite the
correct edition or do not cite.

**What DORA actually says about internal platforms**, and it is counterintuitive — verbatim from
`dora.dev`:

- *"platforms improve productivity and organizational performance, they can sometimes lead to a
  decrease in throughput and change stability if not carefully managed."*
- *"developer independence, the ability to perform tasks without relying on an enabling team,
  resulted in a 5% improvement in productivity at both the team and individual levels."*
- On the interaction with AI: *"When platform quality is high, the effect of AI adoption on
  organizational performance becomes strong and positive. Conversely, when platform quality is low,
  the effect of AI adoption on organizational performance is negligible."*

Three direct consequences, and they are the core of this document's criteria:

1. **A platform can make delivery worse.** It is not a theoretical risk: it is a finding from the
   sector's reference source. The explanations that get put forward —additional steps before
   production, new layers of complexity, more handoffs and dependencies, and functionality that
   fits badly when use is mandatory— **can be checked in your organisation**: measure
   *throughput* and stability **before** introducing the platform and measure again afterwards. If the
   platform team cannot show those two series, it does not know whether it is helping.
2. **Developer independence is the variable to optimise**, not centralisation.
   A platform that replaces "open a ticket to operations" with "open a ticket to platform"
   has not moved the needle: the measured effect is associated with **being able to do things without depending on
   another team**.
3. **Platform quality as a multiplier**: it is the honest argument for investing in
   internal quality rather than in more functionality. A mediocre platform not only fails to help: it cancels out
   the effect of other investments.

**Figures**: the **2024** edition is the one that quantified the effect of platforms, and the figures that
circulate (improvements in individual and team productivity, with drops in *throughput* and
stability, the latter associated with **mandatory and exclusive use** of the platform) come mostly
from **secondary readings of the report**, not from the official page. **They are not pinned here as
data**: if you are going to cite a percentage, take it from the report's PDF and cite its year, or do not cite it. And
discard without exception the figures from platform vendors ("*N* % faster with our
tool") that publish neither sample nor method: they are not data, they are marketing material.

**DORA usage warning, the most important one**: the four metrics measure **the delivery
system**, not the team. Turning them into an individual objective or into a comparison between teams
destroys them (you deploy more often and smaller to move the number, with no added value). And they are
**product outcome metrics**, not platform metrics: the platform influences them, it does not
own them. The platform's own measure is §6.2.

### 6.4 Cognitive load: the theoretical foundation

The argument for why this domain exists. Original source: **John Sweller, "Cognitive load during
problem solving: Effects on learning", *Cognitive Science* 12(2), 257–285 (1988)** — a theory
formulated about **individual learning and instructional design**. Its transfer to software teams
is by **Matthew Skelton and Manuel Pais, *Team Topologies* (2019)**, which turns it into an
organisational design constraint: the team is sized and bounded so that it can understand, operate and
improve its part of the system. The three types: **intrinsic** (inherent to the problem and to the
technology), **extraneous** (imposed by the environment: configuring, deploying, fighting with the substrate)
and **germane** (the one that does produce value: the business domain).

The decision rule that follows, and it is the only one needed: **the platform exists to eliminate
extraneous load; never to eliminate germane load.** Extraneous load —setting up an environment, wiring
observability, writing the thousandth pipeline— is pure cost and is automated without remorse.
Germane load —the business domain, design decisions, responsibility for the
production behaviour of what is yours— **is the work**, and a platform that takes it away from the
team does not relieve it: it disempowers it and rebuilds the operations silo (§3.2).

**Honesty about the source, because the catalog does not cite marketing**: the extension of a construct
from **individual** cognitive psychology to a **team** is a useful analogy, not a validated
measurement. Team cognitive load **has no measurable unit**; using it as a qualitative
design argument is legitimate, presenting a "cognitive load index" as hard data is not.
What can be measured is the proxy: how many different tools, repositories, technologies and systems
a team has to sustain, and how many hours a month it spends on something that is not its domain.

### 6.5 The platform as a product: owner, roadmap, support, deprecation

- **Single, named owner**, with the authority to say no. A product with several owners has
  none. It is the entry condition of §3.1 and the first prohibition of §7.
- **Public roadmap for its users**, with what will **not** be done written
  explicitly. A clear "no" lets the team solve it on its own; silence makes it wait.
- **Needs discovery with a method**, not by whichever ticket shouts loudest nor by whatever the
  platform team feels like building. The technique belongs to
  `product-discovery-standards`; what is mandatory here is that a formal channel exists and that **the use of the
  documented exit (§3.3) is one of its inputs**.
- **Support with a published channel, hours and response expectation.** An internal product without
  declared support is abandoned at the first blocker.
- **Documentation treated as part of the product**: it is versioned with the code, it is tested
  (executable examples are run in CI) and **it is deleted when it expires**. Lying documentation
  costs more than none.
- **Explicit deprecation cycle for each capability**: announcement → **available and
  documented** alternative → coexistence period with a deadline → migration tool or automated PR →
  removal. **Deprecating without a ready alternative is forbidden**: that is not deprecating, it is leaving the
  user stranded. And **the migration is paid for by the platform**, in work or in tooling: it is the one who
  decided the change.
- **A capability nobody uses is retired.** Every live feature costs maintenance, attack
  surface and documentation. Periodic review with usage data.

## 7. Sustainability and prohibitions

### 7.1 Cadence

- **Backstage**: monthly release and a **6-month** security backport window (§2.1) →
  update cadence **monthly or, at most, quarterly**. Past the half-year mark, you are
  running with high or critical vulnerabilities with no patch available in your line.
- **Crossplane**: verify the supported line and plan the migration from v1 to v2 with the change of
  scope and the removal of *claims* (§3.6) as a project of its own, not as a side effect of a
  `helm upgrade`.
- **Substrate**: every major Kubernetes or provider upgrade can break a platform
  abstraction. Test it in gate 5 of §4 **before** it reaches users.
- **Annual review of the platform's own existence**: if its §6.2 metrics do not improve
  over a year, the correct decision may be to shrink it, not to expand it.

### 7.2 Prohibitions

- ❌ **A platform without an owner.** Without a responsible person with authority, it is not approved, it is not
  started and it is not maintained. It is the leading cause of zombie platforms.
- ❌ **Mandating its use to justify its existence.** Forced adoption removes the failure
  signal (§1). Security and compliance controls are mandatory, and that is why they live in
  admission and are applied to every path alike (§3.7): that is the difference.
- ❌ **Abstracting what the team needs to control.** Forbidden to hide: the configuration the
  team has to tune to meet its SLO (resources, scaling, timeouts,
  retries); what it needs in order to **debug** in production (logs, traces, access, the relationship
  between its abstraction and the real resources); and what it will be asked for in an audit. An
  abstraction you have to break in order to diagnose an incident **is a broken abstraction** — and it
  always breaks at the worst moment.
- ❌ **Measuring adoption by registered users** (§6.2), by services in the catalog or by
  installed plugins.
- ❌ **Building the portal before the paved road.** You end up with a directory of services
  from which nothing can be done.
- ❌ **A paved road without a documented exit** (§3.3). It produces shadow platforms that nobody
  sees or governs.
- ❌ **Deprecating without an available alternative and without a migration route** (§6.5).
- ❌ **Templates that copy code which must later evolve centrally**, without a proven mechanism
  to update what has already been generated (§3.5).
- ❌ **Registration of *scaffolder* templates from arbitrary repositories or without review.** It is
  code execution with the platform's privileges (§5).
- ❌ **A single, static credential with broad permissions** for the platform (§5).
- ❌ **The platform being the only route to production** without a rehearsed break-glass
  procedure (§5).
- ❌ **Isolation between tenants based on the interface.** If the portal is the only thing separating
  two teams, there is no separation.
- ❌ **An ephemeral environment without a TTL** or without verified destruction (§3.7).
- ❌ **An abstraction that only forwards parameters** (§3.6): cost with no benefit.
- ❌ **Citing platform figures without a methodology** —from a vendor, or a DORA percentage without
  stating the report edition— and **citing a "DORA State of DevOps 2026"**, which does not exist (§6.3).
- ❌ **Presenting team cognitive load as a measured quantity** (§6.4).
- ❌ **The product team ceasing to answer for its service in production because "the
  platform handles it"** (§3.2).

## 8. Mandatory web verification

Before pinning anything from this document in a real project:

1. **Backstage**: current stable version (as of Aug 2026 the line is **1.5x**; the repository's Atom feed
   mixes weekly `next` releases with the monthly ones — **filter out the `-next` ones**),
   raw `LICENSE` (Apache-2.0 verified), status of the **version and security backport
   policy**, open security advisories, status of the **New Frontend System** and
   its migration route, and **whether it has graduated in the CNCF** (as of Aug 2026 it is still *Incubating* since
   15 Mar 2022). Catalog reminder: **the GitHub releases feed is not the source of
   truth** — cross-check with `backstage.io`.
2. **Crossplane**: supported line and status of the v1→v2 migration (`scope`, `LegacyCluster`,
   removal of *claims*), and confirm the CNCF maturity (as of Aug 2026: **Graduated since
   28 Oct 2025** — a lot of third-party documentation still says *Incubating*).
3. **CNCF**: the project page for each piece you pin, for its maturity level and its dates.
   **Beware the name collision**: the CNCF's `Cortex` is **not** the `cortex.io` portal
   (§2.1).
4. **Port, Cortex, Humanitec**: company status, current pricing and terms, and **whether there has been
   an acquisition or a change of model**. None of this is written from memory; as of Aug 2026 there is no record of an
   acquisition of Humanitec, but it is exactly the kind of data that expires.
5. **Score**: whether it is still in CNCF *Sandbox* or has been promoted; the status of its reference
   implementations. Sandbox implies adoption risk.
6. **DORA**: **the current edition and its exact name** (it changed: it is no longer *Accelerate State of DevOps*),
   what the current edition says about internal platforms, and **which report and year any
   percentage you are going to cite comes from**. Do not confuse it with the Puppet or Perforce reports, which are by
   other authors (§6.3).
7. **Licences**: raw `LICENSE` of every tool you pin as a default, including the
   ones "everybody knows" are open. The catalog accumulates cases to the contrary, the latest
   a product that stopped being open source while third-party documentation still said
   it was. Also check whether any has changed ownership or is in maintenance mode.
8. **Declared gaps in this document** (not filled in for lack of a source with a methodology, not
   through oversight):
   - **There is no organisation size here above which to build a platform**: no
     source with a published methodology was found. The falsifiable criterion of the three
     repetitions and that of quantified *toil* is used (§3.1).
   - **There is no recommended platform team size here**: DORA's capabilities page
     does not specify it and the figures that circulate come from vendors.
   - **The DORA percentages about platforms are not pinned**: the official page gives the direction
     of the effect but not the numbers; the ones that circulate come from secondary readings of the 2024 report
     (§6.3). Take them from the PDF with their year or do not use them.
   - **Pricing of Port, Cortex and Humanitec: not pinned** (point 4).
   - **There is no typical *toil* reduction figure here**: it is measured in your organisation, before and
     after (§6.2).

If the web contradicts this document, **the web wins** — flag the discrepancy.
