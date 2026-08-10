---
name: threat-intelligence-standards
description: Cyber threat intelligence as a production discipline — producing, scoring, ageing out and retiring knowledge about the adversary. Use when running the intelligence cycle, writing Priority Intelligence Requirements (PIR) and an intelligence collection plan, splitting strategic / operational / tactical products, modelling data in STIX 2.1 (indicator, malware, intrusion-set, threat-actor, campaign, attack-pattern, relationship, sighting, marking-definition, confidence) and exchanging it over TAXII 2.1 collections and channels, operating MISP (events, attributes, objects, galaxies, taxonomies, warninglists, sightings, feeds, sync servers, PyMISP) or OpenCTI (connectors, pycti, Community versus Enterprise Edition), evaluating an OSINT or commercial feed for volume, uniqueness, latency, accuracy and false-positive rate, assigning indicator confidence and a mandatory expiry, applying the Pyramid of Pain to decide what is worth tracking, mapping to MITRE ATT&CK technique and tactic IDs and surviving version migrations (v18 Detection Strategies and Analytics, v19 Stealth TA0005 and Defense Impairment TA0112), applying TLP 2.0 (TLP:RED, TLP:AMBER+STRICT, TLP:AMBER, TLP:GREEN, TLP:CLEAR) and PAP markings, joining an ISAC/ISAC-like sharing community or a CERT/CSIRT trust group, writing an attribution assessment with analytic confidence language, or deciding whether a paid intelligence subscription changes any decision you take.
---

# Threat Intelligence (CTI) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **producing, evaluating, distributing and expiring knowledge about the adversary**:
intelligence requirements, collection, processing, analysis, dissemination and feedback; modelling and
exchange (STIX/TAXII, MISP, OpenCTI); source quality; indicator lifecycle; mapping to
ATT&CK; marking and sharing; and attribution assessment.

**Guiding principle: intelligence is judged by the decision it changes, not by the volume it
produces.** A report nobody uses to decide where to look, what to patch first or what detection
to write is a subscription, not intelligence. Corollaries that order the whole document:

1. **Without PIRs there is no CTI**, only expensive curiosity. The requirement precedes collection.
2. **An IoC without an expiry date is debt**, not a control. It poisons detection for years and
   generates false positives that get paid for in analyst hours (§3).
3. **Attribution almost never decides anything operational** (§5). It is interesting; it is rarely actionable.

Triggers: those in the frontmatter. Arbitration rule in one line: **if the deliverable is
knowledge with confidence, source and expiry, it is ours; if it is a rule, a shift, a case or a
patch, it belongs to the neighbouring skill.**

**Not applicable**: see
- `detection-engineering-standards`: **the rule is written there**. Here we produce the hypothesis, the
  indicator and the ATT&CK mapping that feed it; the rule's lifecycle, its tests, its tuning and
  its coverage are theirs. **Bidirectional boundary**: detection returns *sightings* that here
  score and expire indicators. A CTI flow that receives no detection *feedback* is blind.
- `soc-operations-standards`: **the shift, the queue and triage**. Alert enrichment
  consumes what is produced here; handling, fixing or retiring an alert is their decision.
- `incident-response-forensics-standards`: **the live case**. The investigation consumes CTI and produces
  new indicators that **come back here to be normalised, marked and expired** — they do not stay in
  the ticket.
- `vulnerability-management-standards`: **EPSS, KEV, CVSS and the patching SLA are theirs**, without
  exception. Here only our own contribution — *this actor exploits this against this sector* — which is
  handed to them as a prioritisation input. **Their risk model is not duplicated.**
- `incident-management-standards` (incident governance), `offensive-security-standards`
  (adversary emulation with written scope and authorisation; **this skill is defensive** and
  produces the TTP profile the exercise emulates), `observability-standards` (telemetry pipeline and
  retention), `grc-compliance-standards` (notification duty, audit evidence and
  the NIS2/DORA framework), `privacy-engineering-standards` (**personal data inside the intelligence**:
  an indicator can be a person's IP, and sharing it either has a legal basis or it does not),
  `identity-access-management-standards`, `email-security-standards` (phishing as a channel with
  its own controls), `finops-standards` (subscription cost as an economic unit),
  `ai-governance-standards` and `llm-app-engineering-standards` (if an LLM is used to summarise or
  classify reports: **an invented summary is an intelligence failure, not a product one**).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note |
|---|---|---|
| Data model and exchange | **STIX 2.1 + TAXII 2.1**, no alternative | Both have been an **OASIS Standard since 10-Jun-2021** (STIX v2.1 CS03, TAXII v2.1 CS01). **There is no STIX 2.2 published as of Aug 2026**; the CTI TC's work is tracked in `oasis-tcs/cti-stix2`. Designing against a vendor-proprietary format is accepting lock-in |
| Sharing platform | **MISP** if the centre of gravity is *sharing with a community* | The 2.5 series is active in 2026 (2.5.32 Jan, 2.5.35 Mar, 2.5.37 Apr, 2.5.38 May…). Licence verified **by reading the raw `LICENSE`**: *"GNU AFFERO GENERAL PUBLIC LICENSE / Version 3, 19 November 2007"* → **AGPLv3** |
| Correlation platform | **OpenCTI** if the centre of gravity is *modelling and relating knowledge* | **Licence read raw — and it contradicts what "everybody knows"**: the `LICENSE` says *"The OpenCTI Community Edition is licensed under the Apache License, Version 2.0"* and *"The OpenCTI Enterprise Edition is licensed under the OpenCTI Enterprise Edition License"*. **It is not AGPL.** It is *open core*: enterprise features (e.g. OIDC/LDAP/SAML SSO) sit under a proprietary licence — verify **what you need** before designing |
| MISP and OpenCTI together | **Legitimate and frequent**, not redundant | MISP as the exchange bus with the community; OpenCTI as the internal knowledge graph. What is **not** legitimate is having both without deciding which is the source of truth for each object |
| TTP framework | **MITRE ATT&CK**, with the **version annotated in every product** | **v18 (28-Oct-2025) retired *Data Sources* and the classic *Detections* and replaced them with *Detection Strategies* (`DETxxxx`) and *Analytics* (`ANxxxx`)** — ~691 strategies and >1,700 analytics. **v19 (28-Apr-2026) split *Defense Evasion* in Enterprise: *Stealth* inherits `TA0005` and *Defense Impairment* is the new `TA0112`**; `T1562` was merged into `T1685`. **Enterprise-only change**: Mobile and ICS keep Defense Evasion |
| ATT&CK version migration | **Planned, with the official crosswalk** | MITRE published a *crosswalk* of the split in JSON and CSV. **Measured trap**: rules and dashboards that reference `TA0005` **still match but against a narrower set** — coverage falls silently, it does not error |
| Marking | **TLP 2.0, verbatim and with no local dialects** | Version 2.0 authoritative since **August 2022**. Labels: `TLP:RED` *"For the eyes and ears of individual recipients only, no further disclosure"*; `TLP:AMBER+STRICT` (the organisation only, no clients); `TLP:AMBER` *"…need-to-know basis within their organization and its clients"*; `TLP:GREEN` *"…spread this within their community"*; `TLP:CLEAR` *"…spread this to the world, there is no limit on disclosure"*. **`TLP:WHITE` is TLP 1.0 and is retired**: if it shows up, the sender has not updated |
| Indicator prioritisation model | **Pyramid of Pain** (Bianco) | Hashes and IPs are at the base: cheap for the attacker, they expire within hours. **TTPs at the top: expensive to change, and that is why that is where you invest.** A programme that only produces hashes and IPs is a programme the adversary defeats by changing servers |
| Feeds | **None is ingested without prior evaluation (§4)** | Academic evidence: *Reading the Tea Leaves* (USENIX Security '19) measured the overlap and precision of public and commercial feeds and found **significant limitations**; among them, that **most IP indicators appear only once** (37 of 47 feeds with >80 % unique indicators). **Consequence: overlap between feeds is low, so "buying more feeds" does not converge on coverage, and none can be treated as truth** |
| Commercial subscription | **Justified by the PIR it covers, not by the catalogue** | See §4: criteria for when it adds nothing |

## 3. The cycle, the levels and the indicator lifecycle

**Intelligence cycle** — you run it all the way through or it is not intelligence: **requirements → collection →
processing → analysis → dissemination → feedback**. The step that always gets skipped is the
last one, and it is the only one that tells you whether it was any use.

- **PIRs (Priority Intelligence Requirements)**: between 3 and 10, written down, with a business owner and
  **reviewed at least annually**. A PIR is a question someone will use to decide ("which
  actors attack our sector with ransomware and through which initial vector?"), not a topic
  ("ransomware"). **Without PIRs, collection is defined by the vendor.**
- **Collection plan**: each PIR is mapped to the sources that answer it and to the gaps nobody
  covers. **A declared gap is a deliverable**; papering over it with a generic feed is self-deception.
- **Three levels, three products, three audiences** — mixing them is the most common formatting mistake:
  **strategic** (trends, sector risk, intent; audience is leadership, no IoCs and no jargon,
  with an investment implication); **operational** (campaigns, TTPs, infrastructure; audience is SOC,
  detection and IR — **the highest-value level and the most neglected**, because it is the most expensive to produce);
  and **tactical** (atomic indicators; audience is machines — **it is consumed automatically or it is not
  consumed**: an IoC hand-copied into a SIEM already arrived late).

**Indicator lifecycle (hard rule):**

- **Every indicator is born with: source, observation date, confidence, `valid_until` and the context
  that makes it actionable.** Without all five, it does not enter the platform. The field people omit is
  always `valid_until`, and it is the one that decides whether the system ages well.
- **Expiry by type, not uniform**: a file hash can live for years; a C2 IP on shared
  hosting lives for days and after that is a guaranteed false positive; a domain, in between. **A configured
  automatic decay (MISP has *decay* models) is mandatory, not optional.**
- **Warninglists / allowlists before publishing**: cloud ranges, public resolvers, CDNs, domains
  of legitimate services. **A CDN's IP published as an IoC is a service outage with a
  known cause.**
- **The *sightings* are the quality mechanism**: an indicator nobody ever sees for months is
  downgraded; one that only fires false positives is retired **and the sender is told**. Without the loop
  back to `detection-engineering`, the scoring is theory.
- **Precision over volume, always.** The number of indicators on the platform is not a programme
  metric: it is an accumulation metric.

**Mapping to ATT&CK:**
- Every operational product carries **technique, sub-technique, tactic and the ATT&CK version used**.
  Without the version, the product is not comparable two releases later (§2).
- **Map what you have observed, not what the vendor report says.** Copied mapping inflates
  apparent coverage and does not survive a review.
- **`TA0005` changed meaning in v19.** Every mapping predating Apr 2026 is reviewed with the
  crosswalk before being reused in a coverage metric.

## 4. Source and product quality

**Evaluate a feed before ingesting it — five axes, measured, not promised:**

1. **Volume** and its distribution over time (a spike is an event, not a trend).
2. **Uniqueness**: how much it adds that you do not already have. With the low overlap measured in the literature
   (§2), **it has to be measured against your current sources**, not assumed.
3. **Latency** between observation and publication: a feed 30 days behind is history.
4. **Precision / false-positive rate**, measured against your own traffic in observation mode.
5. **Context**: does it bring actor, campaign, TTP and confidence, or is it a list of strings? A list without
   context cannot be triaged or expired with any judgement.

**Mandatory trial before buying or blocking**: ingest in *no-block* mode for an agreed
period, measuring the five axes. **No feed goes straight to blocking.**

**When a commercial feed adds nothing — rejection criteria:** it repeats what you already have from
open sources; its uniqueness is high but **irrelevant to your PIRs**; it does not cover your sector,
geography or stack; it delivers volume with no context and no expiry (it transfers the analysis to you and charges you for it);
it only gives atomic indicators and no TTP analysis; **you cannot evaluate it** — with no trial on your
data and no published methodology, **a vendor who does not allow the trial is telling you the
result** —; or **the team has no capacity to consume it**, which is the most expensive way of not
doing CTI.

**Programme metrics** (few, and ones that change decisions): **PIRs covered versus declared
gaps**; **products that triggered a traceable action** (a new rule, a prioritised patch,
a changed control, a hunt started) — the only one that justifies the team —; false-positive rate per
source; and **average age of the active indicator** (if it goes up, decay is not working).
❌ **These are not metrics**: number of indicators, of reports read or of feeds.

## 5. Security, marking and attribution

- **TLP is applied verbatim and propagates to every derivative.** Downgrading the label on someone else's product
  is a breach of trust that gets you thrown out of the sharing community, and that expulsion is
  permanent. When in doubt about the level, **you ask the sender**.
- **PAP (Permissible Actions Protocol) is different from TLP and has to be honoured separately**:
  it governs what actions you may take with the data (resolving a domain, scanning an IP, detonating a
  sample) without tipping off the adversary. **Querying the attacker's infrastructure from your
  corporate IP is free counterintelligence for them.**
- **OPSEC of the CTI team itself**: research infrastructure separated from the corporate one,
  managed research identities, no corporate credentials on hostile sources,
  and an isolated detonation sandbox (`ctf-lab-standards` for the lab).
- **The CTI platform is a high-value target**: it contains what you know about the adversary and, therefore,
  what you do not know. MISP/OpenCTI **never exposed to the Internet without strong authentication and
  segmentation**; and watch out for CVEs in the platform itself (verified: MISP published in 2026
  fixes for SQL injection, privilege escalation and RCE — it is security software, not
  secure software).
- **Personal data**: an indicator can be an identifiable person's IP or email address.
  Sharing it needs a legal basis and minimisation (`privacy-engineering-standards`). **"It is an
  IoC" is not a legal basis.**
- **Attribution — the section that has to be said without ornament**:
  - **It almost never changes a defensive decision.** Knowing the actor is "APT-whatever" does not alter what
    you patch, what you detect or how you contain. What does alter it is their **TTPs**, and those are obtained without
    attributing.
  - It is written with **explicit analytic confidence language** ("we assess with
    moderate confidence…"), separating **observation**, **inference** and **assumption**. Never a flat
    assertion.
  - **Attribution indicators are falsifiable by design**: reused infrastructure,
    language fingerprints, compilation timestamps, leaked and public tooling. *False flags*
    are a documented technique, not an exotic hypothesis.
  - **Attribution with legal, diplomatic or insurance consequences is not made by a corporate CTI
    team.** It is escalated; it is not published.

## 6. Operation

- **Automate ingestion and expiry; do not automate analysis.** Volume versus judgement.
- **MISP synchronisation between organisations**: define and review which direction each
  distribution flows in — a misconfigured sync rule publishes outward what was internal, and it is
  this tool's classic incident.
- **Ingestion budget**: every indicator sent to the SIEM costs storage and correlation
  (`finops-standards`, `soc-operations-standards`). Sending the whole platform to the SIEM breaks the
  budget without improving a single detection.
- **Retention**: an expired indicator **is not deleted, it is archived** — it is useful for retrospective
  *hunting* and for forensics. Expiring ≠ forgetting.
- **Continuity**: the platform is backed up and its restore is tested (`backup-recovery`); the
  accumulated knowledge graph cannot be rebuilt.

## 7. Long-term sustainability and prohibitions

- **Cadence**: the ATT&CK version is reviewed every release and the migration is planned (§2); the
  platforms are patched with the SLA of exposed software, not of an internal tool.
- **Every product has a review date and an owner.** A three-year-old actor profile with no
  review is disinformation with your logo on it.

- ❌ **FORBIDDEN to publish or ingest an indicator without an expiry date.** Rule number one.
- ❌ Blocking with a feed that has not passed a trial in observation mode (§4).
- ❌ Sending the entire CTI platform to the SIEM "just in case".
- ❌ Downgrading a TLP label, or using `TLP:WHITE` (retired in TLP 2.0) and local dialects.
- ❌ Ignoring the PAP: querying, scanning or detonating adversary infrastructure from
  attributable corporate infrastructure.
- ❌ Publishing an attribution as fact, or letting it influence the technical response (§5).
- ❌ Copying the ATT&CK mapping from a vendor report and presenting it as your own coverage.
- ❌ Using volume metrics (number of IoCs, feeds or reports) as programme health.
- ❌ Buying a feed with no PIR to justify it, or that the team cannot consume.
- ❌ Writing detections here (`detection-engineering-standards`) or duplicating the vulnerability
  prioritisation model: **EPSS and KEV belong to `vulnerability-management-standards`**.
- ❌ Exposing MISP/OpenCTI to the Internet without segmentation, MFA and up-to-date patching.
- ❌ Sharing indicators containing personal data without a legal basis or minimisation.
- ❌ Taking a CTI platform's licence on faith from what its website says: **you read the
  raw `LICENSE`** (§2 — OpenCTI is **not** AGPL).
- ❌ Treating an LLM-generated summary of a threat report as an intelligence product without
  human verification against the source.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Current MITRE ATT&CK version** at `attack.mitre.org/resources/updates/` (as of Aug 2026: **v19,
   published on 28-Apr-2026**, with v19.0 and v19.1 data in MITRE/CTI) and **what changed relative to the
   one your mappings use**. The two changes that break things silently: **v18** (Data Sources and
   Detections → **Detection Strategies `DET…` + Analytics `AN…`**) and **v19** (**`TA0005` = Stealth**,
   **`TA0112` = Defense Impairment**, `T1562`→`T1685`, Enterprise only). **Use the official crosswalk
   for the split, not a conversion of your own.**
2. **STIX/TAXII**: that 2.1 is still the current OASIS Standard version and whether there is work towards 2.2
   (`oasis-tcs/cti-stix2`). As of Aug 2026 no 2.2 is on record as published.
3. **TLP**: current version at `first.org/tlp` and **the exact text of each label** (verified:
   TLP 2.0, authoritative since Aug 2022). If your documentation cites TLP 1.0, it is out of date.
4. **MISP**: current release at `misp-project.org` (**the project website, not the GitHub feed**) and
   **the platform's security advisories**, which in 2026 included SQLi, privilege
   escalation and RCE. Licence verified raw: **AGPLv3**.
5. **OpenCTI**: current version and, above all, **which features stay in Enterprise Edition** —
   it changes between releases and it decides whether the project is viable on Community. Licence verified
   raw: **Community = Apache-2.0; Enterprise = Filigran proprietary licence**. Consult
   `opensource-licensing-standards` before committing architecture.
   - **Declared gap**: OpenCTI uses a date-based version scheme (the 7.26xxxx series in 2026) and
     **I could not pin down on the web with any confidence the exact number of the current release or the terms
     of the LTS licence**; verify at `docs.opencti.io` before planning an upgrade.
6. **Feeds you use**: status, cadence and terms of use — many open feeds change
   licence or disappear without notice, and their URL survives returning stale data.
7. **Applicable sharing regulatory framework** (NIS2, DORA, sector obligations of the ISAC you
   take part in): it is set by `grc-compliance-standards`, but **verify that the marking level
   you use is compatible with your notification duty**.
8. **Feed quality studies**: the reference used here is *Reading the Tea Leaves* (USENIX
   Security '19). **It is from 2019: look for a more recent measurement before citing it as the state of the art** —
   the mechanism (low overlap, high IP churn) still holds; the specific figures
   may not.

If the web contradicts this document, **the web wins** — flag the discrepancy.
