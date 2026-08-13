---
name: chaos-engineering-standards
description: Deliberate fault injection as an engineering discipline. Use when designing or reviewing chaos experiments with a steady-state hypothesis, blast radius and abort conditions, running game days, injecting faults with Chaos Mesh (PodChaos, NetworkChaos, IOChaos CRDs), LitmusChaos (ChaosEngine, ChaosHub, chaosctl), Gremlin, AWS Fault Injection Service (FIS experiment templates, aws fis start-experiment, AZ availability scenarios), Azure Chaos Studio (experiments.json, chaos targets and capabilities), Toxiproxy toxics (latency, bandwidth, timeout, slicer) in integration tests, Netflix chaosmonkey/SimianArmy, or deciding whether to experiment in production versus staging.
---

# Chaos engineering standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **deliberate resilience experiment**: formulating the steady-state hypothesis,
choosing and injecting the fault (process, network, resource, dependency, zone, region), bounding
the *blast radius*, defining abort conditions, running *game days* and turning what was learned
into fixes with an owner. Covers the choice of injection tool and the production-versus-staging
criterion.

**Thesis**: a chaos experiment is **not breaking things**: it is a controlled experiment with a
falsifiable hypothesis ("if X goes down, the user does not notice because Y"), measurement of the
steady state before/during/after, and an automatic stop. With no written hypothesis and no abort
condition, it is not chaos engineering: it is vandalism with a budget.

Triggers: "chaos experiment", "game day", steady-state hypothesis, *blast radius*,
`PodChaos`/`NetworkChaos`/`StressChaos`/`IOChaos` (Chaos Mesh), `ChaosEngine`/`ChaosResult`/
ChaosHub (Litmus), AWS FIS experiment templates and `aws fis`, Azure Chaos Studio,
Gremlin, Toxiproxy and its *toxics*, "what happens if the AZ goes down?", "kill pods at random".

**Not applicable**: see `ot-ics-security-standards` and `safety-critical-standards` (**the hard
limit of this skill, §7**: where the fault reaches a physical process or a safety function, nothing
is injected — it is tested on a rig or a twin and their criteria rule, with *Safety* ahead of
availability), `gaming-infrastructure-standards` (**stateful, non-interruptible workload**: the
experiment is bounded to free servers and the replenishment path, never to `Allocated` ones),
`sre-practice-standards` (**SLOs, the error budget and game days as a reliability
practice are theirs**; here the design and mechanics of the experiment the game day
executes — the service's SLI is precisely the steady-state metric used here),
`testing-qa-standards` (deterministic edge and error testing in CI is theirs; Toxiproxy in
an integration test lives on the boundary: the *toxic* is configured to the criteria here, the
test and its gates are theirs), `incident-management-standards` (the real incident and its process;
if an experiment turns into an incident, it is aborted and that skill takes over),
`incident-response-forensics-standards` (security incident), `bcdr-standards` (**the full DR
drill — site failover, RTO/RPO — is theirs**; the continuous, bounded resilience experiment
belongs here), `kubernetes-standards` (the platform where the CRDs run; cluster RBAC and
admission), `performance-engineering-standards` (load testing and profiling: injecting
load to measure capacity is not chaos; combining load + fault is, and the load part is
theirs), `observability-standards` (the instrumentation the experiment is observed with).

## 2. Default decisions / Toolchain

> Verify the latest version and maintenance status on the web before pinning it in a real
> project (§8). Status verified as of Aug 2026:

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Chaos on Kubernetes | **LitmusChaos** (CNCF incubating, monthly release cadence in 2026) or **Chaos Mesh** (CNCF incubating; v2.7.x, roughly half-yearly cadence "for lack of maintainers" according to its own release guide) | — | Both alive; Litmus with more community momentum in 2026, Chaos Mesh simpler to operate and the one Azure Chaos Studio integrates for AKS |
| Managed chaos on AWS | **AWS Fault Injection Service (FIS)** | Gremlin | Prefabricated AZ/region scenarios (including "gray failures": *AZ Application Slowdown*, *Cross-AZ Traffic Slowdown*, Nov 2025), integration with Resilience Hub (Aug 2026) and native *safety controls* |
| Chaos on Azure | **Azure Chaos Studio** | Chaos Mesh directly on AKS | Managed service; *Workspaces/Scenarios* in public preview (Jul 2026, GA expected late 2026 — verify) |
| Commercial multi-cloud platform | **Gremlin** (active and independent as of Aug 2026; launched "Reliability Intelligence" in 2025) | Harness Chaos Engineering (based on Litmus) | Support, agents outside Kubernetes, scenario library |
| Network faults in integration tests | **Toxiproxy** (Shopify; v2.12.0, Mar 2025, MIT, active repository) | tc/netem by hand | Deterministic, scriptable, runs in CI |
| Random instance termination | **Do not use Netflix chaosmonkey**: SimianArmy archived (2021) and `Netflix/chaosmonkey` with no push since Jan 2025 and coupled to Spinnaker — de facto unmaintained | The equivalent FIS/Litmus/Gremlin action | "Chaos Monkey" is a concept today, not a recommendable tool |
| First experiment | **Staging, a single target, during working hours, with the team watching** | — | Confidence is earned before widening the radius |
| Production | **Yes, as an explicit goal of the programme** — staging does not have the real traffic, data or topology | Never, if the service has no SLO and no observability | A system only proves resilience where it matters; but production demands the prerequisites in §3 |

## 3. Structure and conventions

Every experiment is written **before** it is run, versioned in the repository, with this contract:

```
Hypothesis:       steady state (SLI + threshold) that must NOT break
Injected fault:   what, where, magnitude, duration
Blast radius:     maximum reach (n pods / 1 AZ / x% of traffic) — start minimal
Abort conditions: measurable thresholds that stop the experiment AUTOMATICALLY
Rollback:         how the injection is reverted and who verifies it was reverted
Result:           hypothesis confirmed / refuted + actions with owner and date
```

- **Hard prerequisites for production**: an SLO defined and measured, a working burn-rate alert,
  observability of the affected path, a tested abort mechanism, prior notice to on-call and to
  dependent teams, and an agreed window (never during an active incident, a campaign or a freeze).
- **Incremental radius**: instance → group → AZ → region; staging → canary → production. A step is
  not skipped because the previous one "would obviously pass".
- **Game day**: a scheduled exercise where the team runs 1-3 experiments with roles (who injects,
  who observes, who can abort) and a written record of results. It is the practice's entry route;
  how it fits into the reliability programme → `sre-practice-standards`.
- **The most profitable experiment is usually the most boring one**: kill the cache (does the
  origin survive?), degrade a dependency with latency (do the timeouts and the circuit breaker
  trip?), lose a pod (does the user notice?). Before simulating a region outage, verify that
  timeouts, retries and *health checks* do what they say.

## 4. Quality and testing

Omitted as its own section: the experiment **is** the test. Two rules: results
(ChaosResult, the FIS report, the game-day record) are archived under version control alongside the
hypothesis; and an experiment that refutes the hypothesis produces tracked actions — repeating the
experiment after the fix is the resilience regression test. Automatable experiments (Toxiproxy in
integration, Litmus in the pipeline) enter CI only once they have passed a supervised run.

## 5. Stack security

- Chaos tools are **destructive capability holding credentials**: an agent that kills pods, cuts
  the network or stops instances is exactly what an attacker wants. Strict least privilege
  (RBAC per namespace in Chaos Mesh/Litmus, an IAM role per template in FIS with a
  `Condition` on target tags), no wildcards in target selectors, and their control plane
  **never exposed** (unauthenticated Chaos Mesh/Litmus dashboards have been a recurring pentest
  finding).
- Auditing: every run is recorded (who, what, when, on what) — it is also what
  distinguishes an experiment from an incident in the postmortem.
- Watch for CVEs in the chaos platform itself (Litmus patched CVE-2026-33186 in 2026): it runs
  with high privileges, so its patching window is short.
- Experiments on systems holding personal or regulated data: the injected fault must not
  cause loss or exposure of real data; if the experiment can degrade a security control
  (e.g. taking down the authz service), it is treated as a sensitive change requiring approval.

## 6. Performance and operability

Omitted as its own section (one line): the operability of the experiment is already in §3
(observability as a prerequisite, automatic abort, verified rollback); that of the target service
belongs to `sre-practice-standards` and `observability-standards`.

## 7. When NOT to / Prohibitions

**When NOT to practise chaos**: with no SLO and no observability (do that first — you cannot refute
a hypothesis you cannot measure); during an incident, a freeze or a business peak; on a system
already known to be fragile (fix the known before hunting the unknown); in production without
having gone through staging and without a tested abort mechanism.

**Hard limit: if the fault can hurt someone, nothing is injected here.** Industrial control and
physical process systems (OT/ICS, PLC, DCS and above all **SIS**), medical devices,
automotive, rail, aviation and any certified safety function are **outside
this skill without exception**: their priority order is *Safety → Availability → Integrity →
Confidentiality* and it does not admit the trade-off chaos takes for granted. The legitimate
equivalent there is testing on a **rig or a twin**, to the criteria of `ot-ics-security-standards`
and `safety-critical-standards`, never on the plant. The rule in one sentence: **the blast radius
is measured in requests, not in people**; if it is measured in people, it is not an experiment, it
is a risk.

- ❌ An experiment **with no written hypothesis, no bounded blast radius or no automatic abort
  condition**. "Let's see what happens" is not an experiment.
- ❌ Unannounced randomness in production, classic Chaos Monkey style, **as the programme's first
  initiative**: continuous randomness is the graduation, not the start.
- ❌ Chaos in production **as a surprise to on-call** or with no auditable record. An unannounced
  experiment is indistinguishable from an attack.
- ❌ A chaos tool with broad cluster/account permissions or wildcard selectors
  (`namespace: *`). The blast radius is bounded in IAM/RBAC too, not only in the YAML.
- ❌ Recommending `Netflix/chaosmonkey` or SimianArmy in a new design (§2: unmaintained).
- ❌ Selling a load test as a chaos experiment, or a chaos experiment as a substitute for the DR
  drill (`bcdr-standards`) or the deterministic test (`testing-qa-standards`).
- ❌ Running and not closing: an experiment that refutes the hypothesis and produces no action with
  an owner is cost without return; one that confirms it and is never re-run expires.
- ❌ Using fault-injection techniques against systems that are not yours or without authorisation:
  this is a defensive discipline on your own systems, with permission and a record.
- ❌ Injecting faults into **stateful, short-lived, non-interruptible workloads** as if they were a
  stateless microservice. The canonical case is the match server
  (`gaming-infrastructure-standards`): killing an `Allocated` pod refutes no hypothesis —
  it destroys real people's session and the very SLI you came to protect. The experiment is
  bounded to **free** resources and the replenishment path, not to the occupied ones.

## 8. Mandatory web verification

1. **Chaos Mesh**: version and supported branches at `chaos-mesh.org/supported-releases/` and
   `api.github.com/repos/chaos-mesh/chaos-mesh/releases` (as of Aug 2026: 2.7.x documented, 2.8 in
   preparation); confirm it is still CNCF incubating and its real release cadence.
2. **LitmusChaos**: releases at `api.github.com/repos/litmuschaos/litmus/releases` and the
   quarterly updates on the CNCF blog (last verified: Q1-Q2 2026, Aug 2026).
3. **AWS FIS**: the current catalogue of actions and scenarios in the FIS Actions reference at
   `docs.aws.amazon.com` (the partial-failure scenarios are from Nov 2025; the Resilience Hub
   integration from Aug 2026) and pricing.
4. **Azure Chaos Studio**: status of *Workspaces/Scenarios* (as of Aug 2026 **public preview**, GA
   "expected late 2026" — this is a moving figure), supported regions and faults at
   `learn.microsoft.com`.
5. **Toxiproxy**: latest release at `api.github.com/repos/Shopify/toxiproxy/releases/latest`
   (v2.12.0, 2025-03-18) and repository activity.
6. **chaosmonkey**: repository status at `api.github.com/repos/Netflix/chaosmonkey` (verified
   Aug 2026: `archived: false` but last push 2025-01-06 — confirm before citing it).
7. **CVEs** of the chosen chaos platform (project/CNCF advisories).
8. **Declared gaps** (unverified — do not fill them from memory): Gremlin pricing and tiers;
   the exact version and licence of Harness Chaos Engineering; the exact GA date of Azure Chaos
   Studio Workspaces; the minimum Litmus version that fixes CVE-2026-33186 (seen in a CNCF blog
   summary, not in the project advisory).

If the web contradicts this document, **the web wins** — flag the discrepancy.
