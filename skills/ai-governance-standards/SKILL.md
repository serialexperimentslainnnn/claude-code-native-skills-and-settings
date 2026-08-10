---
name: ai-governance-standards
description: Use when an organization must account for the AI it uses — building an AI system inventory and surfacing shadow AI, classifying systems into the EU AI Act tiers (prohibited practices, high-risk Annex I and Annex III, Article 50 transparency, minimal), deciding whether you are provider or deployer under Article 25 and when fine-tuning or repurposing turns you into a provider, GPAI duties under Articles 53-55 and the Code of Practice, the Regulation (EU) 2026/1744 Digital Omnibus dates, an internal acceptable-use policy and use-case approval process that does not drive staff into shadow AI, the Article 27 fundamental rights impact assessment and how it complements a DPIA, meaningful human oversight versus automation bias, synthetic content marking and disclosure, AI vendor due diligence (training on your data, retention, subprocessors, audit rights, exit), Article 73 serious incident reporting, an ISO/IEC 42001 AI management system with ISO/IEC 42005 and 42006, NIST AI RMF as a governance framework, AESIA and national supervisory authorities, or governance metrics that change decisions instead of filling a report.
---

# AI governance standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **This is not legal advice.** This skill fixes **engineering and management criteria** to
> build systems and processes that can comply, and to know what to ask. The legal
> qualification of a specific case, the interpretation of an article and the decision to notify belong to
> **legal / DPO / the competent authority**. When a date or an obligation decides something,
> **it is verified in the official source** (§8), not here and not from memory.

## 1. Scope and triggers

Applies when an organisation has to **know which AI it uses, decide what it can do with it and
answer for the result**. It is the **decision and accountability** layer, not the
construction one: AI system inventory, risk classification, allocation of roles and
obligations, internal usage policy and case approval, impact assessment, human oversight,
transparency, procurement and third parties, incidents, management frameworks and metrics.

Triggers: "AI system inventory", "shadow AI", "shadow AI", "is this high risk?",
"Annex III", "Annex I", "provider or deployer", "deployer", "does fine-tuning
make me a provider?", "GPAI", "general-purpose model", "systemic risk", "Code of
Practice", "art. 50", "watermark", "synthetic content", "FRIA", "FRIA", "fundamental rights
impact assessment", "human oversight", "human in the loop", "automation
bias", "AI usage policy", "can I put this into ChatGPT?", "approve a use
case", "AI clause in the contract", "do they train on our data?", "serious AI incident",
"notify the authority", "ISO 42001", "AIMS", "AIMS", "NIST AI RMF", "AESIA", "AI officer",
"AI committee", "AI Act", "Regulation (EU) 2024/1689", "Regulation (EU) 2026/1744".

**Domain thesis — it applies throughout this document**: **governance that does not change any
decision is theatre.** A control that produces a document and never stops, modifies or delays a
deployment is not a control: it is cost with the appearance of diligence. The test for every mechanism
in this skill is the same — *has it ever said no, or changed how something is done?* If the
answer is no over twelve months, the mechanism is broken or unnecessary. Uncomfortable corollary: most
existing "AI committees" and "AI policies" fail this test.

**Not applicable**:

- **`grc-compliance-standards`** — *main boundary, arbitration rule in one line*: **the
  general management system is theirs; the AI-specific extension is mine.** Theirs: ISO/IEC
  27001:2022 and its Annex A, the corporate risk methodology (ISO 27005, MAGERIT/PILAR, FAIR),
  the **Statement of Applicability**, the risk register, the audit evidence and its
  control→evidence mapping, NIST CSF 2.0, CIS, SOC 2, ENS, NIS2, DORA, generic TPRM and the
  documentation hierarchy. Mine: **ISO/IEC 42001 as an AIMS, the AI Act, the AI system
  inventory, AI risk classification, human oversight and the specific obligations of
  provider/deployer.** Operational consequence: **AI risk is integrated into the corporate
  risk register of `grc`, it does not live in a parallel register**; and the AIMS is implemented as an
  extension of the existing ISMS, not as a duplicate system (§3.7).
- **`privacy-engineering-standards`** — *they genuinely cross, and here is the line*: **theirs the
  personal data and its engineering** — lawful basis for training, minimisation, retention and
  deletion, data subject rights, **DPIA**, pseudonymisation and anonymisation,
  **model memorisation** and training-data extraction, international
  transfers, PII in telemetry. **Mine**: the **fundamental rights impact
  assessment (art. 27)**, the **AI Act risk classification**, the allocation of
  provider/deployer roles and the obligations that derive from it. **They cross at art. 27(4)**: the
  FRIA *complements* the DPIA, it does not replace it — the joint design is in §3.5. **Their AI Act
  deadlines are a source and are not contradicted**: those in this skill have been verified
  independently against the OJEU and **they match**; if they ever diverge, the official source
  wins and both skills are corrected.
- **`mlops-standards`**: **it operates; here things are decided and
  answered for.** The **model registry** —artifacts your organisation trains and serves, with their
  lineage, metrics and promotion— is theirs. The **AI system inventory** is mine and **is another
  thing**: it includes third-party SaaS tools you do not operate, AI embedded in products you already
  bought, and the shadow AI nobody registered. **A model can be in their registry and not
  in my inventory (and vice versa), and both cases are a failure.** Also: *fairness* as a
  **measured number** is theirs (their §6.5); **which disparity is acceptable, who signs it off and what happens
  if it is exceeded, is mine**.
- **`mlsecops-standards`**: security of the model's life cycle and supply
  chain — provenance and signing of weights, poisoning, *backdoors*, extraction,
  inversion, *red teaming*, AIBOM, MITRE ATLAS, OWASP GenAI. Unavoidable shared vocabulary:
  both cite **NIST AI RMF** and **AI Act** articles. The line: **there the RMF and art. 15
  are used to choose and implement technical controls against an adversary; here to
  structure the organisation's accountability.** If the question is "which technical
  control do I put in?", it is theirs; if it is "who answers, with what evidence and to whom?", it is mine.
  A **security incident** of an AI system can be at once a technical incident (theirs) and a
  **serious notifiable incident under art. 73** (§3.8, mine).
- `llm-evaluation-standards`: **quality measurement is theirs**. Here documented evaluation is
  **required** as a condition for approving a use case, but the
  methodology (eval sets, judges, calibration, significance) lives there.
- `llm-app-engineering-standards`, `rag-standards`, `ai-agents-standards`, `mcp-standards`,
  `local-inference-standards`, `gpu-computing-standards`: **construction**.
  Here nothing is said about how to write a prompt or how to bound an agent loop; what is said is which use
  cases are permitted, who approves them and what has to be demonstrable afterwards.
- **`claude-api`** (no `-standards` suffix, **installed skill, canonical reference for the
  Anthropic side**): model IDs, prices, parameters, retention and API behaviour. If a
  governance decision depends on a specific Anthropic datum —what is retained, what is used for
  training, what limits exist—, **it comes from there or from the contract**, never from memory.
- `incident-management-standards`: **the incident management process** — declaration,
  severity, roles, communication, postmortem. Here only **what counts as a serious AI incident and
  to whom it must be notified** (§3.8): the process that manages it is theirs and is not duplicated.
- `incident-response-forensics-standards` (technical and forensic response),
  `identity-access-management-standards` (who accesses which AI tool and with what
  identity — **the technical control that enforces the policy of §3.4**),
  `secrets-management-standards`, `vulnerability-management-standards`, `appsec-standards`,
  `bcdr-standards` (**dependence on an AI provider as a continuity risk**, §5),
  `data-platform-standards`, `observability-standards`, `sre-practice-standards`,
  `cicd-standards`, `kubernetes-standards`, `offensive-security-standards`.
- **`technical-hiring-standards`** — *crossing with a real legal obligation*: **mine the
  regulatory framing** —classification of the screening system as high risk under Annex III point 4,
  role of provider versus deployer, fundamental rights impact assessment,
  meaningful human oversight, registration in the AI system inventory—; **theirs the design
  of the selection process**: rubric, interview formats, predictive validity and what evidence is
  accepted to decide. Two warnings that neither of the two should soften: **the Annex III dates
  for employment were postponed to December 2027**, but **the article 5 prohibitions apply
  from February 2025** — and among them is **emotion recognition in the
  workplace**, which reaches automated analysis of video interviews.

## 2. Default decisions

> Verify in the official source before pinning any date, article or edition of a standard (§8).
> **In this domain a wrongly cited date is the worst possible error**: it decides budgets,
> contracts and exposure to penalties.

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Certifiable management framework | **ISO/IEC 42001:2023** (1st edition, in force) as the AIMS, **integrated** with the ISO 27001 ISMS | Setting up an independent, parallel AIMS: it duplicates clauses 4-10, governance and audit, and guarantees divergence |
| Accredited certification of the AIMS | Possible: **ISO/IEC 42006:2025** sets the requirements for the bodies that audit and certify AIMS | Accepting a "42001 certificate" from a non-accredited body: verify the accreditation, not the logo |
| Impact assessment of the AI system | **ISO/IEC 42005:2025** as methodological guidance | **It is not certifiable and it does not replace the art. 27 FRIA or the DPIA**: it is method, not compliance |
| Non-regulatory risk framework / technical dialogue | **NIST AI RMF 1.0** (AI 100-1, Jan 2023) with the generative AI profile **NIST AI 600-1** (26-Jul-2024) | Both remain the versions in force: **there is no published revision** as of Aug 2026. Citing an "AI RMF 2.0" is inventing it |
| Applicable regulatory framework in the EU | **Regulation (EU) 2024/1689 (AI Act)**, as amended by **Regulation (EU) 2026/1744** (*Digital Omnibus on AI*) | Working with the original 2024 text without the 2026 amendments: the deadlines are no longer those (§3.3) |
| Programme starting point | **Inventory first** (§3.1). Without an inventory, everything else is hypothesis | Starting with the policy: it is written about an imaginary world and nobody complies with it |
| Stance towards shadow AI | **Legalise and channel**: an approved route that is fast and usable | **Blanket prohibition with no alternative**: it does not reduce the risk, it makes it invisible (§3.4) |
| Scope of governance | **Every AI system that touches a decision, a datum or a person**, whether built, bought or embedded | Governing only what the data team builds: it is the minority of the real inventory |
| System documentation | **Mandatory model card / system fact sheet** as a condition for entry in the inventory | Technical documentation that only exists when an auditor asks for it |
| National authority (Spain) | **AESIA** (RD 729/2023, based in A Coruña) as the central authority; **AEPD**, **Banco de España** and **CGPJ** as sectoral supervisory authorities | **National penalty regime: still in progress** (§3.3). Do not claim that it exists or that it does not without checking |

## 3. Structure and conventions

### 3.1 AI system inventory — you do not govern what you do not know exists

It is the foundational artifact. Without it there is no classification, no assessment, no oversight, no
answer to an authority. **Scope**: not only in-house models. The inventory includes:

1. Models trained or fine-tuned by the organisation (those in the `mlops-standards` registry).
2. **Applications that consume a third-party model** via API.
3. **AI functionality embedded in software you already bought** — the most forgotten category, and
   often the most numerous: the CRM that now scores leads, the ATS that ranks CVs, the
   payment provider's anti-fraud, the office suite's assistant.
4. **Tools used by employees**, approved or not (§3.2).

**Minimum fields per entry** (if a field cannot be filled in, that *is* the finding):
named business owner · purpose and decision it influences · **role of the organisation**
(provider / deployer / both, §3.2) · risk classification and its written
justification · data it processes (with a link to the RoPA if personal) · vendor and
contract · **nature and point of human oversight** · assessment performed and date ·
review date · life cycle status.

**The inventory is maintained with telemetry, not with surveys.** An inventory that depends on
people declaring it measures honesty, not reality. Verifiable sources: CASB/egress proxy and
DNS logs (AI tool domains), corporate card spend and SaaS invoicing,
OAuth grants to third-party applications in the IdP, browser extensions, and software
inventory. Review with a fixed cadence and an **owner**; without an owner, it expires in a quarter.

### 3.2 Shadow AI — the real starting point

**No governance programme starts from zero: it starts with shadow AI already installed.** The
2026 surveys converge on a wide but unambiguous range —from ~45 % to ~81 % of employees
using unapproved AI tools depending on methodology, with a substantial fraction
entering customer or internal data— and they agree on two uncomfortable findings: **management
offends as much as the rank and file or more**, and **most prefer not to ask rather than
risk a "no"**. (Specific figures: verify in §8; they vary a lot by study and are not
cited here as hard data.)

Operational, not moral, reading: **shadow AI is a signal of unmet demand.** It is
fought with an approved route that is *faster* than the unapproved one, not with a block. And it is
measured: the useful metric is not "shadow AI incidents" but **how long it takes an employee to
get an approved tool** (§6.1).

**Roles: provider versus deployer.** This is the distinction that decides which
obligations fall on you, and almost everyone self-classifies wrongly on the low side. Literal text of
**art. 25(1)** of the AI Act — a distributor, importer, deployer or other
third party becomes considered a **provider** of a high-risk system when:

> (a) "they put their name or trademark on a high-risk AI system already placed on the market or
> put into service";
> (b) "they make a substantial modification to a high-risk AI system that has already been placed
> on the market or has already been put into service in such a way that it remains a high-risk AI
> system";
> (c) "they modify the intended purpose of an AI system, including a general-purpose AI system,
> which has not been classified as high-risk and has already been placed on the market or put into
> service in such a way that the AI system concerned becomes a high-risk AI system".

**Practical consequence that has to be said out loud**: taking a general-purpose model and
**fine-tuning it or repurposing it towards an Annex III use** —screening candidates, scoring creditworthiness—
falls squarely under point (c) and **turns you into a provider**, with technical documentation,
risk management system, conformity assessment and registration. Putting your own logo on
someone else's high-risk system (point a) does the same. **Neither of the two looks like a
regulatory decision when it is taken**: they look like product or brand decisions. That is why the role
is determined **at inventory entry**, with legal, and re-evaluated on every change of purpose.

### 3.3 Risk classification and calendar — verified

Four AI Act tiers: **prohibited practices** (art. 5) · **high risk** (Annex I, systems
embedded in already regulated products; Annex III, standalone use cases) · **limited risk** with
**transparency** obligations (art. 50) · **minimal** (no specific obligations). On top,
a cross-cutting axis: **general-purpose (GPAI)** models, arts. 53-55.

**Effective calendar verified against the OJEU (Aug 2026).** The *Digital Omnibus on AI* is
**Regulation (EU) 2026/1744, of 8 July 2026**, which amends Regulations (EU) 2024/1689,
2018/1139 and 2023/1230; voted by Parliament on **16-Jun-2026**, approved by the Council on
**29-Jun-2026**, published in the OJEU on **24-Jul-2026** and **in force on 27-Jul-2026**. It rewrites
the third paragraph of art. 113 of the AI Act.

| Date | What applies | Status |
|---|---|---|
| **2-Feb-2025** | **Prohibited** practices (art. 5) and AI literacy (art. 4) | **Unchanged** by the Omnibus |
| **2-Aug-2025** | **GPAI** obligations (arts. 53-55); governance; art. 99 penalty ceilings | **Unchanged**. Models already on the market before that date: transitional until **2-Aug-2027** |
| **27-Jul-2026** | Arts. 102-110 of the AI Act (amendments to sectoral legislation), through the new point (d) of art. 113 para. 3 | Entry into force of the Omnibus |
| **2-Aug-2026** | **Art. 50 transparency** and general date of application. Caveat: **art. 50(2) does not apply** to systems already placed on the market by that date. Start of **enforcement** by the Commission over GPAI | **Still in force** — the Omnibus did **not** move it |
| **3-Aug-2026** | National supervision of art. 4 (literacy, rewritten as a duty to *take measures to support* its development) | New |
| **2-Dec-2026** | **Art. 50(2)** (marking of synthetic content by providers) + **new art. 5 prohibitions**: non-consensual intimate images generated by AI and child sexual abuse material | New |
| **2-Aug-2027** | Member States must have at least one national **regulatory sandbox** (postponed from 2-Aug-2026) | Postponed |
| **2-Dec-2027** | **Annex III high risk** (standalone): previously 2-Aug-2026. Affects **Sections 1, 2 and 3 of Chapter III, excluding art. 6(5)** | **Postponed 16 months** |
| **2-Aug-2028** | **Annex I high risk** (embedded in a regulated product): previously 2-Aug-2027 | **Postponed** |

**These are absolute backstop dates**, independent of whether harmonised standards exist or not.
Two warnings of judgement: **(1)** the postponement of high risk **is not a moratorium on the
AI Act** — prohibitions, GPAI and transparency continue on their course, and the GDPR and sectoral legislation
apply in full with or without the AI Act; **(2)** a 16-month postponement **is not free time**:
the technical documentation, risk management and conformity assessment of a
high-risk system take longer than that if they are started late.

**GPAI**: the obligations of arts. 53-55 **have been in application since Aug 2025** and the Omnibus
**did not touch them**. The **Code of Practice** for general-purpose models was published
by the AI Office on **10-Jul-2025** and its **adequacy was confirmed** by the Commission and the
AI Board on **1-Aug-2025**; three chapters (transparency, copyright, and safety
for models with systemic risk). Nuance that decides contractual architecture: **adhering to the
Code is an adequate voluntary means of demonstrating compliance, but it is NOT a presumption of
conformity in the technical sense** — that figure is reserved by art. 40 to European
harmonised standards, whose adoption under the CEN-CENELEC mandate is still in progress. A non-signatory
must demonstrate compliance by other adequate means and, in practice, bears more
information requests.

**Spain**: **AESIA** has existed since **RD 729/2023** (based in A Coruña) and was the first
national authority of this kind in the EU. The **Draft Organic Law** for the good use and
governance of AI —which designates authorities and establishes the **national penalty regime**— was
approved in the Council of Ministers on **26-May-2026** and remains in **parliamentary
process**: at the date of verification **it was not definitively approved or in force**. Planned
supervision split: AESIA as the central body, **AEPD** (data), **Banco de España** (financial
system), **CGPJ** (justice); products already regulated sectorally keep their authority.
**Do not take the status of this law for granted in either direction: verify it (§8).**

### 3.4 Internal usage policy and case approval

A useful AI policy answers **one specific question an employee asks themselves at 16:00**:
*can I put this into that tool?* It is answered with a **data × tool** matrix, not with
principles:

- **Data classification** reused from the one that already exists (`grc-compliance-standards`), not a
  new one invented for AI.
- **Tool tiers**: approved with an enterprise contract (and which data each one accepts),
  approved only for public data, and **forbidden**.
- Rules that **do not depend on the employee's judgement**: "do not put anything confidential in" is not a
  rule, it is a transfer of responsibility. "Customer data only in tool X, in
  tenant Y" is one.
- The policy is **enforced with technical controls** (IdP, egress proxy, DLP,
  SSO provisioning) —see `identity-access-management-standards`— because a policy that only
  lives in a PDF signed at onboarding governs nothing.

**Use case approval**: proportional to risk and with a **published SLA**. Fast track
(days, self-service with a record) for minimal-risk cases with non-sensitive data; full
review for everything else. **If approval takes weeks, you have designed a shadow AI generator**
(§3.2). The approval file contains: purpose, data, role (§3.2), risk classification
and its reason, assessment performed, human oversight design, withdrawal criterion and owner.

### 3.5 Impact assessment — the FRIA and its relationship with the DPIA

**A precision almost everyone skips: the art. 27 FRIA does NOT bind every high-risk
deployer.** Literal text of **art. 27(1)**:

> "Prior to deploying a high-risk AI system […] deployers that are **bodies governed by public
> law**, or are **private entities providing public services**, and deployers of high-risk AI
> systems referred to in **points 5(b) and (c) of Annex III**, shall perform an assessment of the
> impact on fundamental rights […]"

That is: the public sector, private entities providing public services, and the two specific cases of
point 5 of Annex III. A private deployer of a high-risk system outside that perimeter
**does not have the art. 27 obligation** (which does not exempt it from the rest of the deployer's duties).
Claiming otherwise inflates the scope and burns the programme's credibility.

**Relationship with the DPIA** — literal text of **art. 27(4)**:

> "If any of the obligations laid down in this Article is already met through the data protection
> impact assessment conducted pursuant to Article 35 of Regulation (EU) 2016/679 […] the
> fundamental rights impact assessment […] shall **complement** that data protection impact
> assessment."

**It complements, does not replace, and not the other way round**: they are assessments with different objects —the
DPIA looks at the risk to personal data and the data subject; the FRIA, the impact on the fundamental rights of the
people affected by the use of the system—. Recommended design: **a single procedure with two
sections and a common trigger**, run by the same team, with the DPIA governed by
`privacy-engineering-standards` and the fundamental rights section by this skill. **Two
separate processes produce two documents that contradict each other.** If there is no personal data, there can
be a FRIA without a DPIA; if there is personal data and it is not high risk, a DPIA without a FRIA.

Re-assessment triggers: change of purpose, of affected population, of provider or of
underlying model; and **change of the provider's model version**, which happens without warning you and is
the trigger nobody has automated.

### 3.6 Meaningful human oversight — where governance becomes design

This is the point where a paper obligation turns into a product requirement, and where most
programmes fail. **A human who approves in bulk is not oversight: it is a signature.**

**Automation bias** —the tendency to accept the machine's recommendation, stronger
the greater the workload, the time pressure and the apparent accuracy of the
system— is not corrected with training or with an on-screen warning. It is corrected with **design**.
Minimum conditions for oversight to be real, all necessary:

1. **Information**: the supervisor sees the input, the output **and why** (factors, uncertainty,
   similar cases). A score without context is not supervisable.
2. **Time**: the pace of work allows genuine review. If the productivity target was
   set assuming the recommendation is accepted, oversight is already fictitious by design.
3. **Real authority to reverse**, at no personal cost: deviating does not penalise in the
   performance review and does not require more justification than acceptance does. **If contradicting the
   system is more expensive than accepting it, nobody contradicts it.**
4. **Competence**: the supervisor understands the domain and the system's limitations.
5. **Measurement**: the **override rate** is recorded and investigated. A rate
   close to zero **is not good news**: either the model is perfect, or oversight does not
   exist — and it is almost always the latter. A very high rate indicates the model adds nothing.

Treat the override rate and its distribution as an **SLI of the control**, with periodic review and
an owner. It is the most honest metric in this whole document.

### 3.7 Third parties, procurement and dependence

Almost all of an organisation's AI belongs to someone else. What must be required **by contract**, with
a written answer before signing:

- **Use of your data to train or improve the model**: by default **no**, and in writing. That
  it is not enabled in the console today is not a contractual commitment.
- **Retention**: how long inputs and outputs are kept, where, and whether there is retention for abuse
  review or by legal requirement. It is the datum that usually breaks the privacy assessment.
- **Subprocessors and location** of the processing and of the inference; regime for international
  transfers (`privacy-engineering-standards`).
- **Evaluations and documentation**: what the provider evaluated, over which population, with what
  result. A marketing *system card* is not technical documentation.
- **Right to audit** or, failing that, an equivalent accredited certification (ISO 42001 with
  a body accredited under 42006, SOC 2) and its full report, not the public summary.
- **Change notification**: change of underlying model, of version or of behaviour, with
  prior notice. Without this, your assessment expires silently.
- **Incident notification** within a timeframe compatible with your own obligations (§3.8): if the
  provider tells you in 30 days, you cannot meet a 2-day deadline.
- **Exit**: portability of data and configuration, and what happens to your *prompts*, *embeddings*
  and tuning when it ends.

**Dependence as a continuity risk**, not only a cost one: a provider can withdraw a
model, change prices, change behaviour or disappear. If a business process depends on
a specific model, the **degradation plan** —to another provider, to an open model, to a rule,
or to a human decision— is designed and tested (`bcdr-standards`). Generic TPRM —tiering,
questionnaires, vendor register— belongs to `grc-compliance-standards`: **here only what is specific
to AI**.

### 3.8 AI incidents

A model failure with impact is managed with the process of `incident-management-standards`. What is
specific here is **what counts as serious and who is notified**.

**Art. 3(49)** defines a *serious incident* as an incident or malfunctioning of an
AI system that directly or indirectly causes: **(a)** the death or serious harm to a person's
health; **(b)** a serious and irreversible disruption of the management or operation of
critical infrastructure; **(c)** the infringement of obligations under Union law
intended to protect fundamental rights; **(d)** serious harm to property or the
environment.

**Art. 73(1)**: *"Providers of high-risk AI systems placed on the Union market shall report any
serious incident to the market surveillance authorities of the Member States where that incident
occurred."* Deadlines, literal:

| Case | Deadline |
|---|---|
| General (art. 73(2)) | *"not later than **15 days** after the provider or, where applicable, the deployer, becomes aware of the serious incident"* |
| Widespread infringement or serious incident under art. 3(49)(b) (art. 73(3)) | *"not later than **two days** after […] becomes aware of that incident"* |
| Death (art. 73(4)) | *"not later than **10 days** after the date on which […] becomes aware of the serious incident"* |

A parallel and distinct route: providers of **GPAI with systemic risk** report serious
incidents **to the AI Office** under **art. 55(1)(c)**, without undue delay. The Commission
published **draft guidance on art. 73 reporting (26-Sep-2025)**; verify whether there is already a
final version (§8).

**Engineering implication, which is what this skill contributes**: a **two-day** deadline is
incompatible with discovering the impact by reviewing logs by hand. It requires, *before* the incident:
sufficient and retained logging of the AI system, the ability to reconstruct which model version
served which decision and whom it affected, a detection channel that does not depend on a customer complaint,
and a procedure with an on-call owner. **Notification is prepared at design
time; at incident time it is already too late.** The decision to notify belongs to legal/DPO; **being able to do it is
yours**.

### 3.9 Transparency and synthetic content

- **Informing that one is interacting with an AI** (art. 50): at the point of interaction, not buried
  in the terms of service. Applies from **2-Aug-2026**.
- **Marking of synthetic content** by the provider (art. 50(2)): from **2-Dec-2026**, and it does **not**
  apply to systems already placed on the market as at 2-Aug-2026. **Mandatory technical honesty**:
  watermarks in text are fragile and image ones are lost with cropping, recompression or
  re-editing; provenance metadata (content signing schemes) are verifiable but
  are trivially removed and their verification depends on the consumer implementing it. **It is a
  traceability measure, not an anti-abuse control**: do not sell it internally as the latter.
  Verify the real state of interoperability of these schemes before committing (§8).
- **Technical documentation and model card** as a condition for entry in the inventory (§3.1) — not as
  an audit deliverable. See `mlops-standards` §3.3 for the artifact's content.

## 4. Governance gates

Controls that **block**, in increasing order of cost. If none has blocked anything in twelve
months, review whether they are real (§1).

1. **Entry in the inventory** before first productive use. Uninventoried system = not
   authorised. It is the cheapest gate and the one that catches the most.
2. **Determination of the role** (provider / deployer, §3.2) with legal, recorded. Blocks until
   it is decided.
3. **Risk classification** documented **with its reason**. "Minimal risk" without written
   justification does not pass: it is the box ticked by default to avoid doing the work.
4. **Impact assessment** (DPIA and/or FRIA, §3.5) completed when triggered, **before**
   deployment, not in parallel.
5. **Human oversight design** reviewed against the five conditions of §3.6. A "there is a
   human reviewing" without the five does not pass.
6. **Evidence of quality and bias evaluation** (methodology in `llm-evaluation-standards` and
   `mlops-standards`) within the agreed thresholds.
7. **Contractual clauses of §3.7** closed before the data leaves the organisation.
8. **Notification capability** verified (§3.8): logging, version traceability and an on-call
   owner, tested.
9. **Review date and withdrawal criterion** assigned. A system without an expiry date on the
   assessment is a system that will only be audited when it fails.

**Evidence**: each gate leaves a record with date, decision, reason and who decided, in the
evidence system of `grc-compliance-standards` — **not in a shared directory**. Internal audit
of the AIMS with a cadence and a management review with minutes and decisions: if the minutes contain
no decision, the review did not happen.

## 5. Specific risks that governance must cover

- **Data leakage through an unapproved tool** (§3.2): the most frequent and least
  sophisticated vector. Control: identity, network egress and a usable approved alternative.
- **Automated decision with no basis and no recourse**: if the system decides about people, you must
  be able to explain the specific decision and offer human review. The regime of art. 22 GDPR and
  the AI Act overlap; coordinate with `privacy-engineering-standards` and legal.
- **Bias with an impact on rights**: it is measured (`mlops-standards` §6.5), has an agreed threshold and
  an owner, and is re-measured in production. Without a written threshold, the measurement governs nothing.
- **Silent reclassification**: the minimal-risk system that someone repurposes towards an
  Annex III case and **turns you into a provider** (§3.2, art. 25(1)(c)) without anyone noticing. The
  control is the re-assessment trigger on change of purpose (§3.5).
- **Provider model change** that invalidates your assessment without you changing a line of
  code.
- **Drift of the AIMS scope**: if the management system covers three systems and the inventory
  has eighty, the certificate does not mean what people think.

## 6. Governance metrics

### 6.1 The ones that work

| Metric | What it reveals |
|---|---|
| **% of the inventory discovered by telemetry and not declared** | Real quality of the registration process; if it is high, the inventory is wishful |
| **Time from request to approved tool/case** | The no. 1 predictor of shadow AI (§3.4). If it rises, the shadow grows |
| **Human override rate** (§3.6), per system and per operator | If it is ~0, oversight probably does not exist |
| **No. of cases **rejected or modified** by the approval process** | If it is 0, the process is a rubber stamp |
| **Systems with an expired assessment** | Accumulated governance debt, measurable |
| **Time from detection of a model failure to the decision to notify** | Real capability against the art. 73 deadlines (§3.8) |
| **Inventory coverage against AI spend** | Cross-check against invoicing: it finds what nobody declared |

### 6.2 The ones that only fill a report

Number of policies published · employees who took the course · AI committee meetings ·
"compliant" systems with no defined conformity criterion · a compliance percentage that
never goes down. They all share the same defect: **they go up even when risk goes up**.

## 7. Sustainability and prohibitions

- **Cadence**: this domain is reviewed every **3 months**. In 2025-2026 legal deadlines moved,
  the text of the Regulation changed and supporting standards were published. **§8 is what separates this
  document from a source of expensive errors.**
- **Integration over duplication**: AIMS inside the ISMS, AI risk in the corporate register,
  FRIA alongside the DPIA, incidents in the existing incident process. Every parallel structure
  you create will diverge and will have to be audited twice.
- **Proportionality**: the weight of governance scales with the risk of the case. An internal ticket
  classifier does not carry the same file as a candidate screening system. A programme
  that treats everything the same is ignored entirely.

**FORBIDDEN**
- ❌ Citing a date, an article or a deadline of the AI Act **from memory**. Always the official source.
- ❌ Claiming that the high-risk postponement is a moratorium on the AI Act, or that the GDPR waits.
- ❌ Presenting this skill —or any derived analysis— as legal advice.
- ❌ Starting the programme with the policy instead of with the inventory.
- ❌ A blanket prohibition of AI tools without offering an approved, fast alternative.
- ❌ An inventory maintained only with surveys and voluntary declarations.
- ❌ Classifying as "minimal risk" without written justification.
- ❌ Self-classifying as a deployer after fine-tuning or repurposing a model towards an
  Annex III case — that is art. 25(1)(c) and it turns you into a **provider**.
- ❌ Extending the FRIA obligation to every high-risk deployer: art. 27(1) delimits the
  perimeter (§3.5). Inflating the scope burns the programme.
- ❌ Replacing the DPIA with the FRIA or vice versa: they complement each other (art. 27(4)).
- ❌ Calling human oversight an approve button with no information, no time and no authority
  to reverse; or celebrating an override rate close to zero.
- ❌ Signing with an AI provider without a written answer on training with your data,
  retention, subprocessors, notification of changes and of incidents, and exit.
- ❌ Treating the marking of synthetic content as an anti-abuse control: it is fragile traceability.
- ❌ Presenting adherence to the GPAI Code of Practice as a presumption of conformity.
- ❌ Accepting an "ISO 42001 certificate" without checking the body's accreditation (ISO 42006).
- ❌ Confusing the **model registry** of `mlops-standards` with the **AI system
  inventory**: the second includes what you do not operate.
- ❌ An AIMS whose scope covers a fraction of the inventory, presented as if it covered everything.
- ❌ Metrics that go up while risk goes up (§6.2).
- ❌ Keeping a control that in twelve months has not changed any decision.

## 8. Mandatory web verification

**No legal date, article or edition of a standard is pinned without checking it in the official source.**
A wrongly cited deadline here is the worst possible error in the catalogue.

1. **Consolidated text of the AI Act**: Regulation (EU) 2024/1689 **as amended by
   Regulation (EU) 2026/1744** (*Digital Omnibus on AI*, OJEU L of 24-Jul-2026, in force
   27-Jul-2026). Check in EUR-Lex whether there are later amendments. **The literal quotations of
   arts. 25, 27 and 73 in this document were requested verbatim; re-verify them before using them
   to decide.**
2. **Art. 113 calendar**: confirm 2-Aug-2026 (art. 50 and general application), 2-Dec-2026
   (art. 50(2) and new prohibitions), 2-Aug-2027 (sandboxes; transitional for pre-existing GPAI),
   **2-Dec-2027 (Annex III)** and **2-Aug-2028 (Annex I)**.
3. **GPAI**: status of the Code of Practice, updated list of signatories on the
   Commission's site, and progress of the **CEN-CENELEC harmonised standards** (they are the ones that give the presumption of
   conformity of art. 40).
4. **Commission guidance on art. 73**: whether the 26-Sep-2025 draft already has a
   final version, and whether it covers the art. 55(1)(c) route for GPAI.
5. **Spain**: status of the parliamentary process for the Draft Organic Law on AI governance
   (BOE/Congress), effective powers of **AESIA** and the national penalty regime.
6. **ISO/IEC**: current edition of 42001 (as of Aug 2026, the **1st of 2023**; "EN ISO/IEC 42001:2026"
   is the **European adoption of the 2023 content**, not a second edition), and status of 42005,
   42006, 42007, 12792, TS 6254 and TR 20226. Check whether a revision of 42001 is under way by looking at
   **the stage code** on the ISO project page or the work programme of JTC 1/SC 42.
7. **NIST**: whether AI RMF 1.0 (AI 100-1) and AI 600-1 (Jul 2024) are still in force, or whether there is already a published
   revision; and the status of the profiles and drafts under way (critical infrastructure,
   cybersecurity for AI, CAISI agent standards initiative).
8. **Marking of synthetic content**: real state of interoperability and adoption of the provenance
   schemes before committing to a contractual obligation or a product requirement.

**Declared gaps (not filled from memory):**
- **Spanish national penalty regime**: in process at the date of verification; **its approval and
  entry into force have not been confirmed**. Nothing is asserted in either direction.
- **Final art. 73 guidance**: only the existence of a **draft** has been verified
  (26-Sep-2025). Final status not confirmed.
- **Revision of ISO/IEC 42001**: it was not possible to consult the official ISO page (HTTP 403); the
  existence of a second edition under way **is neither confirmed nor ruled out**.
- **Signatories of the GPAI Code of Practice**: the current list has not been obtained.
- **Shadow AI figures**: the 2026 studies diverge widely (~45 %–81 %) by
  methodology. §3.2 uses the range, **not a specific figure**; if you need a figure for a
  report, cite the study and its method, not this document.
- **CEN-CENELEC harmonised standards for AI**: adoption status not verified in detail.
- **Content provenance schemes**: real adoption and interoperability not verified;
  that is why §3.9 does not name any as recommended.

If the web contradicts this document, **the web wins** — flag the discrepancy.
