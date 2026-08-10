---
name: detection-engineering-standards
description: Security detection engineering — building and governing SIEM detections as code. Use when writing or tuning Sigma rules (sigma-cli, pySigma, sigma correlations), YARA or YARA-X rules, Elastic detection-rules TOML, KQL, SPL, EQL or YARA-L analytics, Suricata and Zeek signatures, Wazuh decoders and rules, ATT&CK Navigator coverage layers, DeTT&CT, Chainsaw or Hayabusa triage, alert runbooks and false-positive rates, detection unit tests in CI, OCSF or ECS log normalization, or onboarding a new log source into a SIEM.
---

# Detection engineering standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to designing, writing, testing, deploying, measuring and **retiring** detection content:
detection backlog and hypotheses, data model and source onboarding, schema
normalisation (OCSF, ECS), rule authoring in any format (Sigma, YARA/YARA-X, KQL, SPL,
EQL, YARA-L, Suricata, Zeek, Wazuh, Falco), the detection-as-code pipeline (repo, CI,
tests, deployment, versioning), coverage map against MITRE ATT&CK, enrichment and
deduplication, thresholds and severity, false positive management, per-alert runbook,
adversarial validation of the detection, use of threat intelligence, and the programme's
metrics (MTTD, coverage per source, FP per rule, alerts per analyst per hour).

Triggers: Sigma `*.yml` with `detection:`/`logsource:`, `sigma-cli`/`sigmac`, `pySigma`,
`*.yar`/`*.yara`, `yr` (YARA-X), `rules/**/*.toml` from `elastic/detection-rules`,
`detection_rules test`, `contentctl`/`contentctl-ng`, `panther_analysis_tool`, `suricata.yaml`
and `*.rules`, `*.zeek` scripts, Wazuh `local_rules.xml`/`decoders`, `falco_rules.local.yaml`,
ATT&CK Navigator `.json` layers, `chainsaw`, `hayabusa`, `atomic-red-team`, "detection
rule", "SIEM use case", "false positive", "tuning", "ATT&CK coverage", "MTTD".

**Guiding principle**: detection is an **engineering product with a lifecycle**, not a
catalogue of bought alerts. It is governed by three invariants: **(1) without the right source there is
no detection** — the data model precedes the rule; **(2) every rule is tested with the
real attack it claims to detect** before it is believed; **(3) an alert with no possible action is not
an alert, it is noise with an owner**. Uncomfortable corollary: **coverage ≠ detection**. "We cover
300 techniques" almost always means "we have 300 rules nobody has run against an
attack".

**Not applicable**: see `observability-standards` (telemetry for **diagnosing**: OpenTelemetry,
Prometheus, Loki, cardinality, cost, Alertmanager — **the boundary is the purpose, not the
tool**: the same log feeds both, there to explain an outage, here to discover
an adversary; the pipeline, retention and integrity of the telemetry are theirs, the
analytical content is mine), `sre-practice-standards` (on-call, SLOs, error budget, burn rate,
postmortems), `incident-management-standards` (**governance of the incident my alert
triggers**: declaration, severity, IC, communication — my deliverable ends exactly at the
handoff, and its retro sends work back to me), `incident-response-forensics-standards` (**technical
response and investigation**: containment, imaging, timeline, eradication — a
**bidirectional** boundary: there they investigate what I detect, and **every investigation must come back
turned into a new rule**; the use of YARA for forensic *hunting* and evidence triage is
theirs, the **authoring and governance of the rule** is mine), `offensive-security-standards` (purple
team, adversary emulation, Atomic Red Team and Caldera as **generators** of the authorised
attack and its deconfliction with the SOC — **they generate the activity, I write and validate
the detection**), `container-runtime-security-standards` (**which runtime signal matters** —
unexpected shell, writes to binaries, runtime socket, drift— and the deployment of the
eBPF agent: **the Falco rule is born there and is governed here**, with my lifecycle, my tests
and my coverage), `linux-hardening-standards` and `selinux-standards` (CIS baseline, `auditd` and
SELinux AVCs **as a source**: configuring the audit ruleset is theirs, turning
those events into detection is mine), `windows-server-ad-standards` (which AD event matters and
why), `networking-standards` (segmentation, NetFlow/IPFIX and the network Suricata/Zeek
observe), `appsec-standards` (**A09 Security Logging and Alerting Failures**: which events
the application must **emit** — authn, denied authz, privilege change; I consume that
emission, I do not design it), `vulnerability-management-standards` (CVE, CVSS/EPSS/KEV and patching
SLAs), `privacy-engineering-standards` (PII inside security logs, minimisation
and retention limits by purpose), `secrets-management-standards` (custody and rotation of
secrets — **shared boundary**: a leaked secret or a secret used from an anomalous origin is a
**detection case of mine**, fed by their manager and scanning telemetry), `grc-compliance-standards` (the
regulatory control requiring monitoring and its evidence), `identity-access-management-standards` (IdP design,
conditional access policies and OAuth flows — I detect their abuse, I do not configure them),
`threat-intelligence-standards` (**bidirectional boundary**: the hypothesis, the indicator and its
expiry are theirs, the rule is mine — and **the return of *sightings* is theirs**: an indicator that
expires for lack of sightings is retired there, by their criteria, not here).

## 2. Default decisions

> Data verified Aug 2026. **Verify the latest version, licence and status on the web before
> pinning it in a real project (§8)**: this ecosystem rotates in months and several projects
> changed governance in 2025-2026.

| Area | Default | Justifiable alternative / vetoed |
|---|---|---|
| Portable authoring format | **Sigma** — spec **v2.1.0** (Sep 2025, formalises *correlations* and *meta-rules*), `pySigma` **1.5.0**, `sigma-cli` **3.1.0**, `SigmaHQ/sigma` rules **r2026-07-01** | Writing directly in the SIEM's language **only** when translation loses semantics (§3). **Hard minimum: pySigma ≥ 1.3.0** — earlier versions executed code via *template vars* (today behind `--enable-template-vars` and a sandboxed Jinja2) |
| Files and memory | **YARA-X 1.19.0** | Classic YARA **4.5.8** only for third-party engine compatibility: VirusTotal declared it in **maintenance mode** when publishing YARA-X 1.0.0 (Jun 2025) and new modules (`macho`, `lnk`) only reach YARA-X. Migrate while validating the ruleset (≈99 % compatible at rule level) |
| Threat reference framework | **MITRE ATT&CK v19.1** (Apr 2026) + **Navigator 5.3.2** | None. It is the lingua franca. Watch two breaks: **v18.0** replaced *Detections* with **Detection Strategies (`DETxxxx`) + Analytics (`ANxxxx`)** and deprecated the legacy *Data Sources*; **v19** split **Defense Evasion** into **Stealth (TA0005)** and **Defense Impairment (TA0112)** — use the official *crosswalk*, do not renumber by hand |
| Coverage measurement | **DeTT&CT 2.2.0** over Navigator layers, scoring **data source quality**, not just rule presence | Your own spreadsheet (it desynchronises on its own). **Vetoed**: presenting "techniques with a rule" as coverage without scoring visibility |
| Adversarial validation | **Atomic Red Team** (MIT, *rolling* model with no tags) for atomic tests per technique | **Apache Caldera** for chains and campaign emulation — **it changed governance: MITRE contributed it to the Apache Incubator on 20 May 2026**, canonical repo `apache/caldera`. **Hard minimum ≥ 5.1.0** because of **CVE-2025-27364** (CVSS 10.0, preauth RCE in agent compilation) |
| Normalisation schema | **The one of the engine you consume**, declared explicitly: **ECS 9.4.0** in the Elastic/Sigma world; **OCSF 1.8.0** (Linux Foundation since Nov 2024) in a data lake and for multi-vendor interoperability | **There is no single winner today.** Frequent correction: **ECS was not donated to OCSF, but to OpenTelemetry (Apr 2023)**, and that convergence is still **incomplete**. Pick one per platform and write it down; translate at the edge, not in the rule |
| Low-cost self-hosted SIEM | **Wazuh 4.14.7** (GPLv2) | **Hard minimum 4.14.4+**. Wazuh has a serious history: **CVE-2025-24016** (CVSS 9.9, deserialisation in DAPI, fix 4.9.1) was **actively exploited by Mirai botnets**. It is a server exposed to agents: treat it as Tier 0 |
| Commercial SIEM | Whichever you already have; portability comes from Sigma, not the product | **Elastic Security 9.4.x** (**triple** licence: AGPLv3 / SSPL / Elastic License — verify which applies to your deployment); **Microsoft Sentinel**; **Google SecOps** (formerly Chronicle) with **YARA-L 2.0**; **Splunk ES** |
| Network — IDS/IPS | **Suricata** (8.0.6 and 7.0.17 in parallel, GPLv2) for signatures and protocol detection | **Zeek 8.0.9** (BSD) for network **metadata and context**: they do not compete, they complement each other. Zeek gives you the `conn.log`/`ssl.log` that makes the Suricata alert investigable |
| Container runtime | **Falco 0.44.1** (Apache-2.0, CNCF **graduated** since Feb 2024) | The choice of agent and the *what to watch* belongs to `container-runtime-security-standards`; here the content lifecycle |
| Offline EVTX triage | **Hayabusa 3.10.0** (AGPL-3.0, ATT&CK v19) or **Chainsaw 2.16.2** (GPL-3.0) — both run Sigma over evidence | Manual EVTX parsing. Also useful as a **test engine** for Windows Sigma rules in CI |
| Third-party content as a base | **SigmaHQ** (rules), **elastic/detection-rules**, **splunk/security_content (ESCU 6.3.0, Apache-2.0)**, **panther-analysis 3.112.0** (Apache-2.0), **Nextron `signature-base`** (**DRL 1.1** licence — check before using in a commercial product) | Consuming the whole package without calibrating (§7). **Vetoed**: closed vendor rules whose logic you can neither read nor version |

**Projects not to choose in 2026** (verified): **Matano** — no commits since Jan 2025;
**DetectionLab** — declared dead by its author since 2023. **Panther**: Databricks announced an
acquisition agreement on 16 Jun 2026 and **the release says nothing about the future of the OSS** —
`panther-analysis` is still Apache-2.0 and active, but it is a bet with governance risk.
Worth mentioning in case it applies to the European public sector: **OpenTIDE** (European Commission, EUPL 1.2,
org `OpenTideHQ`) is today the most complete formal open-source detection-as-code framework.

## 3. Structure and conventions

### 3.1 The lifecycle (a rule is a software artifact, not a ticket)

`idea/hypothesis → data source → rule → test → deployment by CI → measurement → tuning → retirement`

- **Idea/hypothesis**: every rule is born from a written hypothesis (`"an attacker with valid
  credentials will register a new device in Entra after device code phishing"`), with an
  ATT&CK technique, a reference actor or campaign, and **expected value**. Without a hypothesis there is no
  criterion for knowing whether the rule works or for retiring it.
- **Source before rule** (§3.2): if the event does not arrive, the rule is theatre.
- **Rule**: in the repo, with complete metadata (§3.4), reviewed in a PR by somebody other
  than the author.
- **Test**: mandatory unit test (§4), plus adversarial validation before raising the severity.
- **Deployment by CI**: never by hand in the SIEM console. The console is *read-only* for
  content; what is edited there is lost at the next sync or produces invisible
  *drift*.
- **Measurement**: FP rate, firings, actions taken. A rule with no telemetry about itself
  cannot be governed.
- **Retirement**: a rule that has fired nothing useful in its review window **is deleted or
  downgraded to informational**, in the same PR that establishes this. The cost of a dead rule is
  not zero: it consumes compute, dirties the coverage and wears down the analyst who triages it.

**Reference repo structure** (adapt it, but have one):

```
detections/
  rules/<platform>/<tactic>/<id>.yml        # Sigma or the engine's native format
  pipelines/<platform>.yml                  # pySigma processing pipelines
  tests/<id>/{positive,negative}.jsonl      # events that MUST and MUST NOT fire
  runbooks/<id>.md                          # mandatory (§3.5)
  coverage/navigator-*.json                 # generated layers, not hand-edited
  deprecated/                               # with reason and date, not silent deletion
```

### 3.2 Data model and telemetry: the part almost nobody does

- **Onboarding a source is a project, not a checkbox.** For every source:
  *which concrete events* (by ID/category, not "the AD logs"), *how they are transported*,
  *how they are normalised*, *how long they are retained*, *what they cost* and *which detections they enable*.
  If it enables none, it is not ingested.
- **Cost and retention are first-class design constraints**, exactly as in
  `observability-standards`. Healthy pattern: **short hot retention (interactive search) +
  long, cheap cold retention (investigation and compliance)**. Practical rule: the cold
  window must cover the *dwell time* you assume, not the one you would like.
- **Normalise at the edge, not in the rule.** A rule that slices strings to reconstruct a
  field the pipeline should have normalised is debt paid on every new source.
- **Measure source health as if it were an SLI**: ingestion latency, volume per hour
  with an expected band, and **alert on the absence of events** — a source's silence is
  indistinguishable from "nothing happened", and it is exactly what an attacker who
  disables the agent produces. *Detection of missing detection* is the first rule you write.
- **Integrity**: security logs are kept separate from operational telemetry (different access
  control, retention and **immutability**). The SIEM is the record an attacker
  will want to erase.

**Source priority today** (by value/cost ratio, not by tradition):
1. **Identity and the cloud control plane** — it is the main surface (§3.7).
2. **Endpoint/EDR** (process, command line, parent/child, module loading).
3. **Authentication and directory** (AD, Entra, IdP).
4. **CI/CD and the artifact registry** (§5).
5. **Network** (DNS, proxy/egress, `conn.log`): indispensable for investigating, mediocre for
   detecting on its own.

### 3.3 ATT&CK coverage with honesty

- Coverage is scored by **visibility quality × detection quality**, not by
  rule count. Minimum scale per technique: `no telemetry` → `telemetry with no rule` →
  `unvalidated rule` → `rule validated against a real execution` → `rule validated and with
  a response procedure`. Only the last two count as coverage.
- **A technique covered by a single variant is not covered.** ATT&CK enumerates
  behaviours, not commands: if the rule only matches the binary the atomic test used, you have
  covered the tool, not the technique.
- Prioritise by **relevant threat** (adversary profile, sector, real surface), not by
  filling the matrix. A uniformly green matrix is a sign the colour has been optimised.
- **Generate the Navigator layers from the repo in CI.** A hand-edited coverage map
  lies as soon as the next PR is merged.
- When jumping ATT&CK versions, **use the official crosswalk** (the split of Defense
  Evasion in v19 invalidates previous mappings) and treat the migration as a change with a PR and
  review, not as a `sed`.

### 3.4 Anatomy of a rule that can be governed

Mandatory metadata, no exceptions: a stable `id` (UUID, never reused), an actionable
`title`, `status` (`experimental` → `test` → `stable` → `deprecated`), a `description` with
the hypothesis, `author`/`owner` (a team, not a person), `date`/`modified`, a justified `level`,
ATT&CK `tags` with the framework version, `falsepositives` **populated with real observed
cases**, `references` and **a link to the runbook**.

- **Severity is earned, not declared.** A rule is born in `experimental` with informational
  severity; it goes up only with data: N days in production, a measured FP rate, and
  adversarial validation passed. Raising the severity "because the technique is serious" is the direct route to
  alert fatigue.
- **Actionable context in the event itself**: who (a resolved identity, not a GUID), which
  asset (with owner and criticality), what happened (relevant raw command/fields), what is expected
  of the analyst. An alert that forces you to open four consoles to know whether it matters has already
  failed.
- **Enrichment in the pipeline, not in the analyst's head**: asset inventory,
  criticality, owner, geolocation, reputation, and **whether that activity was
  authorised** (change window, deconflicted red team exercise).
- **Deduplication and grouping**: the unit of work is the **incident**, not the alert. It is
  grouped by the entities that define *one and the same case* (identity, host, session, campaign) with
  a time window. **Sigma v2 correlations** (`event_count`, `value_count`,
  `temporal`) are the portable mechanism for expressing chains and thresholds without tying yourself to the engine.
- **Portability with a declared limit**: Sigma is the authoring format; the backend translates.
  When the semantics do not survive translation (complex correlation, joins, engine-specific
  functions, sequence analysis), **write it in the native language and declare
  the exception in the rule** — do not force a Sigma that translates into something other than what it says.
- **Freshness of pySigma backends: verify it, do not trust the label.** The
  official directory marks abandoned backends as *stable* (`sentinelone` unpublished
  since 2023, `ibm-qradar-aql` and `insightidr` equally behind). Before betting a
  platform on a backend, look at the date of the last release, not the badge.

### 3.5 Mandatory runbook: a rule with no action is not deployed

Every alert carries a runbook versioned **in the same repo and in the same PR**, with: what the
firing means, **how it is verified in 5 minutes** (concrete queries, not "investigate"), what is
known benign, what immediate action is appropriate (contain, revoke session, isolate,
escalate), to whom it is escalated and at what severity, and which data to preserve before touching anything
(preservation belongs to `incident-response-forensics-standards`; the link is mandatory).

**If you cannot write the runbook, you do not know what the rule detects: it is not merged.**

### 3.6 Adversarial validation and regression detection

- **No rule leaves `experimental` without having fired against a real execution of the
  technique.** The attack generator belongs to `offensive-security-standards`; the evidence of
  the firing is my deliverable.
- **Purple team ≠ red team**: the value is not "they got in", it is the **executed
  vs. detected vs. alerted vs. responded** matrix by technique. Every undetected execution opens
  a backlog item with an owner and a date.
- **Regressions**: a rule that used to work stops working on its own when the agent changes,
  or the vendor's schema, the OS version or a binary's path. **Scheduled and automatic**
  execution of a subset of atomics against a controlled environment, with an alert if the expected
  detection does not appear. A real and recent example of why this is not theoretical: Defender's
  *advanced hunting* schema renamed `AADSignInEventsBeta` to
  `EntraIdSignInEvents` and **removed the legacy tables on 9 Dec 2025**, and on 25 Feb 2026 the
  booleans went from `1`/`0` to `True`/`False` — each of those changes breaks rules
  silently.
- Every adversarial execution is **deconflicted with the SOC** beforehand: an exercise that consumes the
  real incident process is a process failure, not a test passed.

### 3.7 Identity and cloud: where the detection that matters lives today

The perimeter is identity. The minimum sources, with **exact names** (verify §8):

- **Entra ID**: `SigninLogs` (interactive), `AADNonInteractiveUserSignInLogs`,
  `AADServicePrincipalSignInLogs`, `AADManagedIdentitySignInLogs`, `AuditLogs` and
  **`MicrosoftGraphActivityLogs`** (requires P1/P2). In 2026 **Agent logs** were added for
  *Entra Agent ID*, and `AADNonInteractiveUserSignInLogs` now carries an `Agent` column: AI
  agent identities are a new surface and must be ingested from day one.
- **AWS CloudTrail**: there are now **four** categories, not two — *Management*, *Data*, ***Network
  activity*** (`eventCategory = NetworkActivity`; the only valid `errorCode` is
  `VpceAccessDenied`, useful for seeing credentials outside your organisation using your VPC
  endpoints) and *Insights*. **Only management is on by default**: data and network events
  are enabled explicitly and budgeted for.
- **GCP**: `cloudaudit.googleapis.com%2Factivity` (Admin Activity, always),
  `%2Fdata_access` (**disabled by default** except for BigQuery), `%2Fsystem_event`,
  `%2Fpolicy`. For consent abuse in Workspace, the key log is the **OAuth Token
  Audit** (`applicationName=token`, `authorize`/`revoke` events, with `scope_data`,
  `client_id`, `app_name`); default retention **6 months** — if your investigation
  window is longer, export it.
- **GuardDuty Extended Threat Detection** is on by default and at no extra cost, with a rolling
  24 h window. **Verified operational trap: it ignores archived findings,
  including those archived by your own suppression rules** — aggressive tuning blinds you to
  attack sequence correlation.

**Mandatory identity use cases** (defensible ATT&CK chain:
`T1566.002 → T1528 → T1550.001 → T1098.005 / T1098.001`; **there is no dedicated sub-technique for
device code phishing** — the one that mentions it explicitly is T1566.002, not T1528):

- **Device code phishing**: the decisive field in Entra is `AuthenticationProtocol == "deviceCode"`.
  It is the technique of **Storm-2372** (Microsoft, Feb 2025; **reclassified on 31 Jul 2026 as a
  sub-cluster of Midnight Blizzard/SVR**), which pivoted to the client ID
  `29d9ed98-a469-4536-ade2-f981bc1d605e` (*Microsoft Authentication Broker*) to obtain a
  **PRT** and register a device. Preventive control: the Conditional Access **"Authentication flows"**
  condition. Planning notice: Microsoft is rolling out a **managed policy
  "Block device code flow"** which it creates in *report-only* and **enables on its own after a minimum of 45
  days**, warning 28 days in advance; audit it by filtering `AuditLogs` on the initiator
  `Microsoft Managed Policy Manager`. Critical caveat: **a CA policy targeting users
  does not cover service principals**.
- **Device registration and new credential**: adding or changing credentials on
  *service principals* and *app registrations*. It is exactly the pattern of the
  **Commvault/Metallic** case (CISA, May 2025, **CVE-2025-3928** in KEV): theft of *client secrets*
  from a cross-tenant app.
- **Abuse of a third-party integration's OAuth token**: the **Salesloft Drift / UNC6395** case
  (Aug 2025) exfiltrated Salesforce data with legitimate OAuth tokens, searching with mass
  SOQL for strings such as `AKIA`, `Snowflake`, `password`, `secret`, and **deleting the records of
  the query jobs**. Signals: Salesforce Event Monitoring `UniqueQuery` events, UA
  `Salesforce-Multi-Org-Fetcher/1.0`. Design lesson: **a third-party app's consent
  is a permanent key with no MFA** — inventory and watch consents the way you
  watch administrators.
- **Impossible travel and session anomaly**: useful, but **only as enrichment or a low-severity
  signal**. In a workforce with a corporate VPN and mobiles it generates massive FPs; never
  as a paging alert on its own.
- **Graph↔sign-in correlation** (verified canonical pattern):
  `MicrosoftGraphActivityLogs | join ... on $left.SignInActivityId == $right.UniqueTokenIdentifier`
  — it is what turns "a token did things" into "this session, of this user, from this
  origin, did these things".

### 3.8 Threat intelligence: pyramid of pain, not shopping list

- **IoCs expire; TTPs do not.** Hashes and IPs are rotated in hours and their value is almost purely
  retrospective; tools and TTPs cost the adversary and survive months or years. The
  engineering effort goes to the **top** of the pyramid; IoCs are automated and forgotten.
- **Every IoC comes in with an expiry and a provenance.** A feed with no expiry date is a
  source of FPs that grows on its own. Indiscriminate free feeds generate more triage than they
  save: they are measured like any rule (§6) and cut if they do not pay off.
- **Systematic retro-hunt**: every new IoC is searched **backwards** in the cold retention, not
  only forwards. That is where the IoC does earn its keep.
- The ultimate goal of TI is not the list: it is **prioritising the detection backlog** by
  relevant adversary.

## 4. Quality gates (they break the build)

In increasing order of cost. The first four are blocking on every detection PR.

1. **Lint and schema**: the rule parses, validates against the format's schema (Sigma spec 2.1,
   `detection-rules` TOML, the engine's schema) and **compiles with the target backend**
   (`sigma convert`). A rule that does not translate does not exist.
2. **Complete metadata**: a unique, non-reused `id`, owner, `status`, ATT&CK tags
   **existing in the declared version** of the framework, non-empty `falsepositives`.
3. **Runbook present and linked.** No runbook, no merge (§3.5). Non-negotiable.
4. **Unit test with positives and negatives**: at least one event that **must** fire and
   several that **must not** (the rule's own known FPs). Valid engines:
   `detection_rules test` (Elastic), `panther_analysis_tool test`, Hayabusa/Chainsaw over
   sample EVTX, or the backend's runner. **A rule with no negative test is not tested:
   it is declared.**
5. **Schema non-regression test**: the test events are validated against the current
   schema (ECS/OCSF/vendor table), so that a field rename breaks the build
   and not the detection in silence (§3.6).
6. **Coverage**: the Navigator layer is **regenerated in CI** and the diff is reviewed. Adding a
   rule that does not move the declared coverage is a sign of a duplicate.
7. **Adversarial validation** before promoting to `stable` or raising severity: a real
   atomic execution and evidence of the firing attached to the PR.
8. **Deployment by pipeline** with versioning and rollback: `Sentinel repositories` (GA
   Mar 2026), `elastic/detection-rules` with a *version lock* per stack branch, or the equivalent
   mechanism. **Manual deployment in the console is forbidden.**

**Measurable promotion rule** (adjust the numbers, but fix some): `experimental` → `test`
after compiling and passing tests; `test` → `stable` after ≥ 2 weeks in production with a **measured
FP rate < 20 %** and adversarial validation passed. **It is measured before raising the severity,
never after.**

## 5. Security of the detection programme itself

- **The supply chain of security tooling is a first-order target, and 2026
  proved it.** The compromise of **Trivy** by the actor *TeamPCP* (**CVE-2026-33634**, CVSS
  9.4, in **CISA KEV** since 26 Mar 2026) went as far as **force-pushing 76 of 77 tags** of
  `trivy-action` and all 7 of `setup-trivy`, with a payload that **read the memory of the
  `Runner.Worker` process to extract masked secrets**; the same campaign hijacked the 35 tags
  of `Checkmarx/kics-github-action`. Analogous precedent: `tj-actions/changed-files`
  (**CVE-2025-30066**). Operational consequences, without exception:
  - **Pin by commit SHA** every GitHub Action in the detection pipeline; **pin by
    digest** every image; verify signatures and checksums of the detection binaries.
  - **Immutable releases** enabled in your own content repos.
  - **Do not confuse provenance with goodness**: the *CanisterWorm* variant went as far as **generating
    valid SLSA Build L3 attestations via Sigstore for malicious packages**. The signature
    proves **who** built it, not **what** it does.
  - The detail of pipeline hardening belongs to `cicd-standards`; here it is an entry
    requirement.
- **Verified Aug 2026: none of the recommended detection tools (Sigma,
  YARA/YARA-X, Atomic Red Team, Caldera, Falco, Suricata, Zeek, Wazuh, Elastic) appears as a
  victim of a repository compromise in 2025-2026.** The vector, however, applies to them
  just the same: do not treat it as ruled out, but as not having happened yet.
- **The SIEM and its rules are sensitive data.** The ruleset reveals exactly what you see and what
  you do not: access control on the detection repo, review of who can disable or modify
  rules, and **an alert on the modification or silencing of the content itself**. Disabling
  a rule is a security event.
- **Never embed secrets in rules or in queries** (API tokens, enrichment
  credentials, webhook keys). They go to the secrets manager
  (`secrets-management-standards`).
- **PII and minimisation**: security logs contain personal data by definition.
  Legal basis, retention by purpose and access control belong to
  `privacy-engineering-standards`; the requirement here is that **the rule and its enrichment do not
  widen the set of personal data** beyond what is needed to decide.
- **Integrity and non-repudiation** of the evidence: append-only logs, a synchronised and
  verified clock (clock drift destroys any temporal correlation and any
  forensic timeline) and control over who can purge.

## 6. Operability, cost and programme metrics

**Metrics that are published (and what corrupts them)**

| Metric | What it measures | How it gets corrupted |
|---|---|---|
| **MTTD** | Time from the adversary's activity to detection | Measuring from ingestion, not from the event; excluding what was never detected (survivorship bias). It is only honest with purple team, where you know the real `t0` |
| **Coverage per source** | % of assets of each class reporting the expected source | Counting configured sources instead of sources **that are sending events now** |
| **FP rate per rule** | Firings closed as benign / total firings | Not recording the analyst's disposition; then there is no data and tuning is opinion |
| **Alerts per analyst per hour** | Real triage load | Counting alerts instead of **grouped incidents**. An alarm threshold for the programme, not for the shift |
| **Orphaned rules** | No owner, no firings, no runbook, no review within its window | None: it is the metric hardest to dress up and the one that best predicts the programme's collapse |
| **% of adversarially validated rules** | Real coverage | Counting written rules |

- **Alert fatigue is the domain's modal failure.** If the analyst ignores the queue,
  detection does not exist even if the rules are perfect. Work priority when the queue
  overflows: **reduce noise before adding coverage**, always.
- **Tuning ≠ disabling.** The correct order is: (1) fix the data or the enrichment,
  (2) narrow the rule's condition, (3) a **narrow, documented exception with an
  expiry**, (4) downgrade to informational, (5) retire. A broad and permanent suppression is
  a detection hole shaped like tuning — and on AWS it also blinds GuardDuty's
  correlation (§3.7).
- **Cost**: the SIEM is paid for by ingestion, by retention or by query compute depending on the
  product — **find out your billing unit before designing**, because it decides what to optimise.
  Levers in order: do not ingest what does not enable detection; filter and aggregate at the edge;
  tiered retention to cheap storage; efficient scheduled queries. Ingesting "just in
  case" is the most expensive way of detecting nothing.
- **Rule performance**: scheduled queries with a coherent window and frequency
  (window ≥ frequency + ingestion latency, or you lose events at the edge), no joins
  over the whole history, no catastrophic regexes. A rule that does not finish within its
  interval does not detect: it skips executions.
- **Platform change with a hard date**: if you use **Microsoft Sentinel**, the product is already
  GA in the Defender portal (Jan 2026) and **stops being supported in the Azure portal
  after 31 Mar 2027**. It is a migration project with a date, not a UI change.

## 7. Sustainability and prohibitions

- **Cadence**: review ATT&CK and remap on every major framework release (~half-yearly;
  v18 and v19 brought structural breaks); review the entire ruleset **quarterly** with
  explicit pruning; update `pySigma`/backends and the community ruleset monthly;
  review sources and their health continuously.
- **Every exception and every suppression carries an expiry and an owner.** Without a date, they become
  permanent holes nobody remembers opening.
- Third-party content is **calibrated on adoption**, not "some day": it enters the repo, passes
  the gates of §4 and is assigned an owner, or it does not enter.
- When a project changes governance (Caldera → Apache Incubator; Panther → Databricks),
  **review it as a platform risk**, not as a press release: licence, release cadence
  and who responds to a CVE.

**FORBIDDEN**
- ❌ Deploying a rule **without a unit test** (positive **and** negative).
- ❌ Deploying a rule **without a runbook** with a concrete action.
- ❌ **Raising the severity without having measured** the FP rate in production.
- ❌ Creating or editing content **directly in the SIEM console**, with no repo and no PR.
- ❌ Enabling the product's default rule pack **without calibrating** — the domain's central
  antipattern: a SIEM full of rules nobody has touched is not coverage, it is a
  noise queue that guarantees the good alert goes unnoticed.
- ❌ Presenting a **count of rules or techniques** as coverage without scoring visibility and
  validation.
- ❌ Rules with no owner, no stable `id`, no ATT&CK version tags or with empty
  `falsepositives`.
- ❌ Writing rules for a source **not confirmed in ingestion**, or leaving the **absence of events**
  from a source without an alert.
- ❌ Broad, permanent or ownerless suppressions; silencing a rule instead of fixing it.
- ❌ Alerting on IoCs with no expiry or provenance, or building the programme on IoCs instead
  of on TTPs.
- ❌ Impossible travel (or other pure anomaly heuristics) as a standalone paging alert.
- ❌ Consuming GitHub Actions or images in the detection pipeline **by mutable tag** instead of
  by SHA/digest, or treating an SLSA attestation as proof that the artifact is benign.
- ❌ Running adversarial validation **without prior deconfliction** with the SOC.
- ❌ Secrets or credentials embedded in rules, queries or enrichment pipelines.
- ❌ Starting anything new on **Matano** or **DetectionLab** (unmaintained), or on classic
  YARA when YARA-X is available.
- ❌ Running Wazuh or Caldera on versions earlier than the minimums of §2 (critical CVEs, one
  of them mass-exploited).
- ❌ Forcing into Sigma a logic the backend does not support and trusting the
  result.

## 8. Mandatory web verification

Before pinning any version, licence, project status or table/field name,
**look it up — do not recall it**. Data verified Aug 2026 (it expires fast): Sigma spec
**v2.1.0**, pySigma **1.5.0**, sigma-cli **3.1.0**, SigmaHQ rules **r2026-07-01**; ATT&CK
**v19.1** (Apr 2026) and Navigator **5.3.2**; ATT&CK Workbench **4.10.0**; OCSF **1.8.0** (LF
since Nov 2024); ECS **9.4.0**; Elasticsearch **9.3.0** / Elastic Security **9.4.4**; Wazuh
**4.14.7**; Suricata **8.0.6** and **7.0.17**; Zeek **8.0.9**; Falco **0.44.1** (CNCF graduated
Feb 2024); YARA-X **1.19.0** and YARA **4.5.8**; Splunk ESCU **6.3.0**; `panther-analysis`
**3.112.0**; Chainsaw **2.16.2**; Hayabusa **3.10.0**; DeTT&CT **2.2.0**.

1. **The current ATT&CK version and its changelog**, including the *crosswalk* for the split of
   Defense Evasion (v19) and the Detection Strategies/Analytics model (v18) — **before**
   remapping anything.
2. **The real freshness of the pySigma backend** you are going to use: the date of the last release in the
   `pySigma-plugin-directory`, not the `stable` badge.
3. **Governance and health** of Caldera (Apache Incubator since May 2026, **current version not
   verified here**) and of Panther (acquisition by Databricks announced Jun 2026, **future
   of the OSS not declared**).
4. **Exact names of the vendor's tables, fields and logs** before writing the query:
   the Defender/Entra, CloudTrail and Cloud Audit Logs schemas changed in 2025-2026 and
   keep changing.
5. **Hard platform dates**: end of support for Sentinel in the Azure portal
   (31 Mar 2027, verify), status of the content migrations under way.
6. **Advisories and CVEs** for your SIEM and your agents (Wazuh and Elastic have had recent
   criticals) and for the tooling you run in CI.
7. **Supply chain compromises** of any new action, image or binary in the
   detection pipeline before adopting it (§5).

**Declared gaps — not verified in this document, verify them yourself before using them**:
- **The current version of Apache Caldera (incubating)**.
- **The version of Splunk Enterprise Security** and product news after the acquisition by
  Cisco (the official documentation was not accessible during verification).
- **Formal EOL dates for the Suricata 7.0 and 8.0 branches**, and whether a 9.0 release exists or is
  planned (the upgrade guide mentions it; no release has been published).
- **The status of OCSF support in Elastic Security and in Splunk** in 2026.
- **Whether Red Canary (maintainer of Atomic Red Team) is today part of Zscaler** — a secondary
  source, unconfirmed against a primary release.
- **GA dates** for the Conditional Access "Authentication flows" condition, for CloudTrail's
  *network activity events* and for GuardDuty Extended Threat Detection.
- **Secondary ATT&CK IDs** cited in identity literature (T1621, T1539, T1550.004,
  T1078.004, T1098.002/.003, T1606.002): not individually verified against the site.
- **Whether the recommended detection projects consumed** `trivy-action` or
  `tj-actions/changed-files` during their exposure windows: not ruled out, just not
  found.

If the web contradicts this document, **the web wins** — flag the discrepancy.
