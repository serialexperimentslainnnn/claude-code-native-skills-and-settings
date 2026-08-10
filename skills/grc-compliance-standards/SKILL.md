---
name: grc-compliance-standards
description: Governance, risk and compliance standards. Use when working with ISO 27001/27002/27005/27701, NIST CSF 2.0, CIS Controls v8.1, SOC 2, NIS2, DORA, ENS/CCN-STIC, Statement of Applicability, risk registers, control-to-evidence mapping, OSCAL, audit preparation, vendor questionnaires (SIG, CAIQ), or the regulatory notification clock after a breach — who must be told, within how many hours, and what evidence the filing needs.
---

# Governance, risk and compliance (GRC) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, implementing, auditing or reviewing:
- **ISMS** ISO/IEC 27001:2022: scope, clauses 4-10, Annex A, **Statement of Applicability (SoA)**.
- **Risk management**: methodology, scales, risk register, treatment, **formal acceptance**
  and exceptions with an expiry date.
- **Frameworks and regulation**: NIST CSF 2.0, CIS Controls v8.1, SOC 2, ENS (RD 311/2022), NIS2, DORA,
  CRA, ISO 27701/42001 — scope, obligations and deadlines.
- **Evidence and continuous compliance**: automatable control→evidence mapping, OSCAL, retention
  policy, internal and external audit preparation.
- **Third-party risk (TPRM)**: supplier tiering, SIG/CAIQ/CSA STAR, contractual clauses,
  DORA register of information.
- **Document hierarchy**: policy, standards, procedures, records; owners and cadences.

**Not applicable**: see vulnerability-management-standards (for CVE/CVSS/EPSS/KEV triage, patching
SLAs and VEX — here only the **formal acceptance** of residual risk), appsec-standards (for threat
modelling and OWASP/ASVS), sre-practice-standards (for SLOs, on-call and postmortems),
identity-access-management-standards (for technical IAM), cicd-standards, iac-standards,
kubernetes-standards, onprem-standards and the cloud skills (for the **concrete controls**: the
framework, the risk and the evidence live here, not the implementation). **Engineering** GDPR (DPIA
as a technical artefact, minimisation in the schema, retention implemented as deletion, data subject
rights as functionality, transfers by design, PII in telemetry) belongs to
`privacy-engineering-standards`: here only the **management** part (ISO 27701 as a PIMS, RoPA as a
register, risk acceptance, audit evidence). Continuity: the **management system** (ISO 22301,
policy, scope, audit) belongs here; the **plan and its engineering** (BIA, RTO/RPO, recovery order,
DR exercises) belongs to `bcdr-standards`. Incident handling and the technical investigation belong
to `incident-management-standards` and `incident-response-forensics-standards`; the authorised
offensive exercise, to `offensive-security-standards`. `enterprise-architecture-standards` (**the
control framework, the risk register and the audit evidence belong here**; **the application
inventory with its owner, criticality and lifecycle is theirs** — and it is the source that feeds
the scope of almost every control. A control whose scope cannot be enumerated is not auditable),
`opensource-licensing-standards` (the corporate regulatory obligation and its evidence belong here;
**the licence policy, the gate and the exception process are theirs**),
`govtech-eidas-standards` (**reciprocal, already declared from their side**: the **eIDAS regime** —
advanced versus qualified signature, qualified provider and trust lists, timestamping, AdES
and long-term preservation, electronic case file — and the obligations of Spanish administrative
procedure are **theirs**; **the ENS as a management framework** — Statement of
Applicability, categorisation, certification audit, risk register and the relationship with the
CCN — belongs here. Rule: *if the question is what legal value what you sign has, it is theirs; if it is
which control it evidences and with what evidence, it is ours*),
`accessibility-standards` (boundary with a real legal
obligation: **the applicable regulatory framework, the evidence register and the management of
sanction risk belong here**; **the accessibility statement — its content, its testing and
who signs it — is theirs** (§6.1), and this document only requires it as evidence — European Accessibility Act, EN 301 549, Ley 11/2023 and its
implementing rules, ADA Title II —; **the technical conformance criteria** — which WCAG criterion is met,
how it is tested and what automates it — **are theirs**. Warning both share: **a new version of
WCAG or of EN 301 549 does not by itself change the legal obligation**, which is anchored to the standard cited
in the law).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Situation | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Certifiable ISMS | **ISO/IEC 27001:2022** + Annex A (93 controls: 37 organisational, 8 people, 14 physical, 34 technological) with **27002:2022** implementation guidance | The transition from 27001:2013 closed on **31 Oct 2025**: a 2013 certificate is invalid and requires full recertification (Stage 1+2), not transition |
| Governance language and communication with the board | **NIST CSF 2.0** (CSWP 29, Feb 2024): GOVERN/IDENTIFY/PROTECT/DETECT/RESPOND/RECOVER functions, 106 subcategories, current/target Profiles | Using the **Tiers 1-4** as a maturity scale (they measure risk management, not maturity) |
| Prioritised technical baseline | **CIS Controls v8.1** (Jun 2024): 18 controls, 153 safeguards, **IG1 = 56** as a non-negotiable minimum | Starting at IG3 "because we are serious"; there is no v9 published as of Aug 2026 |
| Risk methodology | **ISO/IEC 27005:2022** with a **combined** approach: event-based (strategic scenarios) for the map, asset-based for the detail | Assets only (produces inventories, not decisions); events only (does not land controls) |
| Risk in the Spanish public sector | **MAGERIT v3** + the CCN's **PILAR** tool (free for the public sector and its suppliers) | The v3 catalogue (2012) does not name cloud/SaaS/containers/AI: reinterpret and document the equivalence |
| Quantification for investment decisions | Qualitative 5×5 with written criteria by default; **FAIR** when control cost has to be compared against expected loss | Colour matrices with no scale definition (made-up numbers with the appearance of rigour) |
| Assurance for customers (US/SaaS market) | **SOC 2 Type II**, TSP section 100 (TSC 2017 with 2022 *revised points of focus*), Security mandatory + categories according to commitments | Type I as a substitute for Type II; treating the *points of focus* as auditable requirements (TSP 100.07: they are not) |
| Spanish public sector and its suppliers | **ENS, RD 311/2022**: BÁSICA/MEDIA/ALTA category from risk analysis; **Perfiles de Cumplimiento Específicos** approved by the CCN (art. 30) where one exists for the sector | Certifying MEDIA/ALTA category without an accredited body (básica allows a declaration; media/alta require certification) |
| Privacy as a management system | **ISO/IEC 27701:2025** (14 Oct 2025): **standalone** PIMS, no longer an extension of 27001; harmonised structure 4-10; unified Annex A (A.1/A.2/A.3) | 27701:2019 certificates: transition until **Oct 2028** |
| AI systems | **ISO/IEC 42001** as an AIMS; integrate it with the ISMS, do not duplicate it | Handling AI risk outside the corporate risk register |
| Evidence interchange format | **OSCAL** (NIST, 1.1.x line) when the consumer supports it — FedRAMP requires machine-readable packages from **30 Sep 2026** | Requiring OSCAL from tools that only support it in name: test import/export first |

**Regulation with dates (status Aug 2026, verify §8):**
- **DORA** (Regulation (EU) 2022/2554): applicable since **17 Jan 2025**. The ESAs designated the
  first **19 critical ICT providers (CTPPs)** on **18 Nov 2025** (hyperscalers and large SaaS),
  under direct oversight with periodic penalty payments of up to 1% of average daily worldwide turnover.
  As a regulation, it **applies directly**: it does not depend on transposition.
- **NIS2** (Directive (EU) 2022/2555): transposition deadline expired on **17 Oct 2024**. Spain
  **still has not transposed** it as of Aug 2026: the draft *Ley de Coordinación y Gobernanza de la
  Ciberseguridad* (Council of Ministers, 14 Jan 2025) is still in progress; the Commission issued a
  reasoned opinion on 7 May 2025 and a second request on **19 May 2026** (INFR(2024)0270).
  RDL 7/2025 partially transposed it for the electricity sector. Art. 23: early warning **24 h**,
  notification **72 h**, final report **1 month**. Art. 34: minimum fines of **€10M or 2%** of
  worldwide turnover (essential) and **€7M or 1.4%** (important) — these are **floors**, Member States
  may raise them. Art. 20: approval and **mandatory training of the management body**, with
  personal liability and possible temporary disqualification.
- **CRA** (Regulation (EU) 2024/2847): reporting obligations from **11 Sep 2026** (early warning
  24 h, notification 72 h, final report 14 days/1 month, via the *Single Reporting Platform*); full
  application on **11 Dec 2027**. It covers a product already on the market if it remains available after Sep 2026.

## 3. Structure and conventions

**Document hierarchy (4 levels, no more):**
`Security policy` (1 document, approved by the board, the "what" and the "who is accountable") →
`Standards` per domain (the "what must be complied with", measurable) → `Procedures` (the "how", with an
operational owner) → `Records/evidence` (the proof). Every document: named owner, version, approval
date, approver and **next review date**. A document without an owner is dead.

**Source of truth = internal control catalogue, not the frameworks.** Every control has its own stable
`ID`; the frameworks are **views** that point to it. The other way round (one file per standard) duplicates
the work and they contradict each other. Versioned in git, reviewable by PR:

```yaml
# controls/CTRL-014.yaml — one control, N frameworks, N pieces of evidence
id: CTRL-014
nombre: Review and approval of production changes
dueño: jefatura-plataforma          # accountable for it OPERATING
frecuencia: continua
implementacion: "Mandatory PR + 1 approval other than the author + green CI"
mapeos:                              # one piece of evidence serves several standards
  iso27001_2022: [A.8.32]
  nist_csf_2_0:  [PR.PS-06]
  cis_v8_1:      ["4.1"]
  soc2_tsc:      [CC8.1]
  ens_rd311:     [op.exp.5]
evidencia:
  tipo: automatizada                 # automatizada | manual — the % is measured
  fuente: "Forge API: PRs merged without approval in the period"
  consulta: "scripts/evidence/prs_sin_aprobacion.py"
  periodicidad: mensual
  retencion: 24m
prueba_eficacia: "Sample over the full period; 0 unjustified exceptions"
```

**Risk register — mandatory fields** (if one is missing, the risk is not managed):
ID · scenario in *source → event → consequence* format (not "a hack") · affected process/asset ·
**risk owner** (business, named, with authority to accept; different from the control owner) ·
likelihood and impact on the defined scale · **inherent** risk · existing controls ·
**residual** risk · decision (mitigate/transfer/avoid/**accept**) · plan with an owner and a
date · next review date · link to the evidence.

**SoA — the document auditors look at most.** The 93 Annex A controls, each with:
applicable yes/no, **explicit justification** for inclusion *and* for exclusion, implementation status,
reference to the internal control (`CTRL-xxx`) and to the evidence. It is updated on **every material change**
to the scope or to the risks, not once a year before the audit.

**Exceptions and risk acceptance:** a single form with the associated risk, compensating controls,
**mandatory expiry date (max. 12 months)**, approver according to the risk level (written authority
matrix: who may accept what) and review on expiry. An exception with no date is an undocumented
architecture decision.

## 4. Quality gates and continuous compliance

In increasing order of cost; the first three are automatic and break the pipeline:
1. **Policy as code in CI**: OPA/Conftest, Kyverno or equivalent over IaC and manifests; IaC and
   image scanning, SBOM and **secret scanning**. A critical finding breaks the build — and **the signed,
   timestamped output of the gate IS the evidence**, not a screenshot taken afterwards.
2. **Scheduled evidence collection**: every control with `evidencia.tipo: automatizada` generates
   its artefact at its frequency, with a timestamp, traceable origin and verifiable integrity (hash),
   in storage with retention and **restricted access**.
3. **Coverage dashboard**: controls with no evidence within their window = open finding, just like a
   broken test. Without a dashboard, "we comply" is an opinion.
4. **Internal audit** (clause 9.3 and annual programme): planned **by risk**, not by
   checklist; findings with root cause, plan, owner and date; follow-up until verified closure.
5. **External audit / SOC 2 Type II**: requires evidence **throughout the whole observation
   period** and auditor sampling. A bulk collection the week before is a finding, not
   preparation.

**Design vs. operation**: proving that the control *exists* (design effectiveness) does not prove that it
*works* (operating effectiveness). For each control, define in advance what sample and what
deviation threshold count as a failure.

## 5. Security of the compliance programme

- **Evidence is sensitive data**: minimise it (redact secrets, credentials, PII, internal IPs if
  they add nothing), control access to the evidence repository, encrypt it and define retention. A
  badly protected evidence repository is a map of the organisation for an attacker.
- **Segregation of duties**: whoever operates a control does not approve their own evidence; internal
  audit with real independence from the audited function.
- **Third parties (TPRM)**: tiering by criticality and by data access, with a differentiated cadence
  (critical: full annual review + continuous monitoring; low risk: 24-36 months).
  **CAIQ** questionnaires (CSA, aligned with CCM; STAR Level 1 self-assessment, Level 2 attestation)
  for SaaS/cloud and **SIG** (Shared Assessments, ~21 domains; SIG Lite for screening) for the rest.
  When you receive a supplier's SOC 2 or ISO: **read the scope, the period and the exceptions** — a
  certificate whose scope you have not read says nothing. Contract with a right to audit, incident
  notification with deadlines **aligned to yours** (if you are held to 24 h, your supplier cannot give you
  72), subprocessors and exit/portability. In financial entities, the DORA **register of information**.
- **Regulatory deadlines live in the incident response plan**, not in a compliance
  document: the NIS2/CRA 24 h clock starts on *becoming aware*, and if personal data is involved it
  runs in parallel with the data protection one.

## 6. Programme operability

**Metrics reported to the board** (signal, not vanity):
% of controls with automated evidence · average age of the evidence · open findings
by age and severity · **exceptions in force and expired without review** · risks above
the declared appetite · % of critical suppliers reviewed on time · mean time to close a
finding. The trend matters more than the absolute value.

**Minimum cadence**: risk register review quarterly (critical) / annual (the rest) ·
management review annually with the clause 9.3 inputs and outputs · internal audit annually ·
SoA on every material change · **quarterly regulatory radar** (§8).

**Translation between frameworks — the real saving is here.** A single well-defined piece of evidence covers N
standards: the change approval record serves ISO A.8.32, SOC 2 CC8.1, CIS 4.x, ENS op.exp.5 and
CSF PR.PS-06 simultaneously. Keep the mappings in the control catalogue (§3) and use the official
informative references (NIST **CPRT** for CSF 2.0, mappings published by CIS, Annex B of
27002:2022) instead of inventing them. When a mapping is partial, **note it as partial**: an
optimistic mapping is discovered in the audit, not before.

## 7. Sustainability and prohibitions

**Lifecycle**: put dated standards transitions in the calendar of the year they are announced
(ISO 27001:2013 → 2022 closed on 31 Oct 2025; 27701:2019 → 2025 closes in Oct 2028). Amd 1:2024 to
27001 requires the determination on climate change in the context to be **recorded**, even if
the conclusion is "not relevant": the auditor asks for it directly.

**FORBIDDEN**
- ❌ **Compliance theatre**: template policies never adapted, procedures nobody
  executes, described controls that do not exist. It is document fraud with pretty formatting.
- ❌ An SoA with everything marked "applicable", or exclusions with no written justification.
- ❌ Risks with no named owner, or with the control owner as the risk owner.
- ❌ **Verbal risk acceptance**, by stray email, or signed by someone without authority under
  the matrix. Without a signature with name, date and expiry, the risk is not accepted: it is ignored.
- ❌ Perpetual exceptions, or ones renewed automatically without re-assessing the risk.
- ❌ Fabricated, backdated evidence, or evidence collected only before the audit; a screenshot as the only
  evidence of a control the tool can export via API.
- ❌ Certifying an artificially trimmed scope so it comes out cheap and selling it as full
  coverage of the organisation.
- ❌ Confusing the CSF 2.0 **Tiers** with maturity levels, or the SOC 2 *points of focus* with
  mandatory requirements.
- ❌ Delegating the NIS2 **management body responsibility** (art. 20) to a supplier: it is non-delegable.
- ❌ Assuming that "since Spain has not transposed NIS2, there is nothing to do": DORA and the CRA are
  directly applicable regulations, contracts and customers already require NIS2, and the law will arrive with
  short registration deadlines.
- ❌ Sending questionnaires to suppliers and reading neither the answers nor the attached evidence.
- ❌ One control file per framework (guaranteed duplication and contradictions within a year).
- ❌ Closing a finding without verifying the fix or recording the root cause.

## 8. Mandatory web verification

Before pinning any concrete fact, **search for it — do not recall it**. European regulation
moves by quarters:
- **NIS2 in Spain**: whether the *Ley de Coordinación y Gobernanza de la Ciberseguridad* has been published
  in the BOE, its registration deadlines, the split of competent authorities and the final penalties
  (BOE + status of file INFR(2024)0270).
- **DORA**: RTS/ITS adopted and in force, and the updated list of **CTPPs** designated by the ESAs.
- **ENS**: whether RD 311/2022 is still in force unamended, and the **Perfil de Cumplimiento Específico**
  and the **CCN-STIC** guides applicable to the exact sector before sizing measures.
- **CRA**: Commission guidance and the status of the *Single Reporting Platform* before 11 Sep 2026.
- **ISO**: current edition and transition period of 27001/27002/27005/27701/42001, and whether there is a
  revision under way (ISO Online Browsing Platform / committee website).
- **CIS Controls**: current version (v8.1 as of Aug 2026; check whether v9 has been released) and its mappings.
- **NIST**: CSF 2.0, Quick Start Guides and **CPRT** for updated informative references; current
  **OSCAL** line and its actual support in the target tools.
- **SOC 2**: whether the AICPA has published new TSC or revision drafts.

If you cannot verify, say so explicitly instead of assuming.
If the web contradicts this document, **the web wins** — flag the discrepancy.
