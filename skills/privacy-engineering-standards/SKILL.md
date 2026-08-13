---
name: privacy-engineering-standards
description: Use when privacy must be built into the system rather than written in a policy — PII discovery in source and columns, minimization and purpose limitation by design, automated deletion that actually deletes everywhere, LINDDUN privacy threat modelling (GO/PRO/MAESTRO), NIST Privacy Framework, DPIA/EIPD triggers, k-anonymity, l-diversity, t-closeness and differential privacy budgets (OpenDP, SmartNoise, Tumult, Google DP), tokenization, masking, synthetic test data, Presidio, crypto-shredding with per-data-subject keys, GDPR data subject rights (access, portability, rectification, erasure) implemented as software across every copy, consent as versioned auditable state, PII leaking into logs, traces and metrics, EU-US Data Privacy Framework and international transfer design, personal data in AI training, model memorization and the AI Act, and personal data breach impact assessment.
---

# Privacy engineering standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when privacy has to exist **inside the system**: schemas, pipelines, APIs,
telemetry, non-production environments and models. It covers the inventory and classification of
personal data, minimisation and purpose limitation translated into design decisions, privacy
threat modelling, de-identification techniques and their real honesty, the
data subject's rights implemented as functionality, consent as state,
PII-free telemetry, how AI systems processing personal data fit in, and the technical part
of a breach.

Triggers: "PII", "personal data", "special category", "minimisation", "purpose
limitation", "retention", "erasure", "right to be forgotten", "deletion", "access", "portability",
"rectification", "DSAR", "consent", "banner", "anonymise", "pseudonymise", "k-anonymity",
"l-diversity", "differential privacy", "tokenisation", "masking", "synthetic data",
"test data", "copy production to staging", "crypto-shredding", "per-subject key", "LINDDUN",
"DPIA", "EIPD", "international transfer", "SCC", "Data Privacy Framework", "training with
personal data", "personal data breach", "PII in logs".

**Governing principle**: **the only privacy control that never fails is the data you do not
collect.** Everything else — encryption, access control, retention, erasure — is mitigation of a risk
you chose to take on. Corollary: a privacy policy protects nobody; a scheduled `DROP`,
a destroyed key and a field that was never asked for do.

**Not applicable**:
- `grc-compliance-standards`: the **management framework** — ISO/IEC 27701:2025 as a certifiable PIMS,
  SoA, risk register, record of processing activities (RoPA) as a governance artifact,
  audit evidence, contracts with processors and third-party questionnaires. Here live
  **the engineering and the verifiable technical control**; there, the management system that certifies it.
  Arbitration rule: if the question is answered with a signed document, it is `grc`'s; if it is
  answered by running a query, a test or a deployment, it is this skill's.
- `data-governance-quality-standards`: **the catalogue, data ownership and the corporate
  classification scale are theirs**, and classifying an asset is a business act signed by its
  owner. Here, **the technical per-field gate** — without `class`, `purpose` and `retention` nothing
  gets merged. **Precedence rule, because the two gates coexist**: theirs decides *who* classifies
  and with which scale, ours decides *that no code enters without the label in place*. If the owner has
  not classified, the field does not pass: the technical gate does not invent the class, it demands it.
- `data-platform-standards`: the translation into **the concrete store** — retention by partitions and
  `retention.ms`, cache TTLs, the engine's encryption at rest, Kafka tombstones, RLS. Here, the
  **obligation, the full scope of the erasure and its end-to-end verification** (which includes
  stores that skill does not cover: search indexes, queues, the data lake, backups and third parties).
- `backup-recovery-standards`: **the repository's retention window, its immutability and the
  GFS scheme are theirs**; here the obligation to erase and its technical implementation.
- `bcdr-standards`: **the RTO/RPO and the recovery order** derived from the business, and the continuity
  plan. Boundary declared on both sides: the obligation to erase is this skill's; the
  recovery objective is `bcdr`'s; **the concrete retention of the copy is
  `backup-recovery-standards`'**. The conflict between the two (§3.5) is resolved by design, not by arguing.
- `cryptography-pki-standards`: the choice of algorithms, key management and custody, KMS/HSM. Here
  only the **pattern** (a key per subject) and the requirement that the destruction be real and auditable.
- `secrets-management-standards`: application secrets; a piece of personal data
  is not a secret and is not managed the same way.
- `identity-access-management-standards`: authentication and authorisation of whoever accesses the data,
  including verifying the identity of the person requesting a right.
- `observability-standards`: the telemetry pipeline, sampling and log retention. Here, **what must not
  enter** it and how that is checked.
- `appsec-standards`: STRIDE and vulnerability classes. LINDDUN **complements** STRIDE, it does not
  replace it: a system can be secure and at the same time abusive with the data (§3.2).
- `incident-management-standards` and `incident-response-forensics-standards`: governance and technical
  response to the incident. Here, the **assessment of the breach from the data subject's point of view** and what
  engineering must be able to answer within hours (§5). The criterion for notifying belongs to legal/DPO.
- `api-design-standards`, the language skills and `kubernetes-standards`/`cicd-standards`: the
  contract, the code and the pipeline the data flows through.
- `ai-governance-standards`: governance of the AI system — model
  risk, evaluation, technical documentation and provider obligations under the AI Act. Here, the
  **privacy of the data that feeds it**: the lawful basis for training, memorisation and
  extraction, and rights over an already-trained model.
- `technical-hiring-standards`: the design of the selection process, its rubric and its
  validity are theirs; **the personal data of the applications is ours** — lawful basis,
  minimisation, retention period and **effective erasure across every copy, including the one in the
  applicant tracking system and the one in the interviewers' mailboxes**. A hard precondition both
  uphold: **a selection process processes personal data of people who are neither customers nor
  employees**, and most organisations have never set its erasure deadline.

**This is not legal advice.** It sets engineering criteria for building systems that
comply; the lawful basis, the legal risk assessment and the decision to notify are set by
legal/DPO. When this skill says "verify it", that is exactly what it means.

## 2. Default decisions

> Verify on the web every standard, version and regulatory status before pinning it in a real project
> (§8). **This is the catalogue domain with the most volatile facts**: those in this table are from
> August 2026 and some were in active motion when it was written.

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Privacy threat modelling | **LINDDUN** alongside STRIDE, not in its place. Current variants: **GO** (card deck, lightweight analysis), **PRO** (systematic over a DFD), **MAESTRO** (model-driven) | Current categories: **Linking, Identifying, Non-repudiation, Detecting, Data Disclosure, Unawareness, Non-compliance**. Citing the old breakdown (*linkability, identifiability, …, disclosure of information*) is a frequent error: the official site already uses the new one |
| Privacy risk framework | **NIST Privacy Framework** aligned with CSF 2.0 | **Status as of Aug 2026: v1.1 still had no confirmed final publication** (IPD Apr 2025; NIST announced final "in 2026"). Cite the edition you verify, not the one you remember (§8) |
| Unit of design | **The data subject**, not the table: every piece of personal data must be locatable, exportable and destructible **per subject** across every store | Designs where a person's data can only be found by scanning: that is an erasure that will not be deliverable |
| Retention | **Scheduled automatic deletion**, with an owner and an alert if it does not run | "Documented" retention with no job enforcing it = there is no retention |
| De-identification by default | **Pseudonymisation** (still personal data) and saying so | Calling pseudonymised data "anonymised": technically false and an **aggravating factor** before the AEPD |
| Real anonymisation | Only with a **documented re-identification assessment** (singling out, linkability, inference) and control of the publication context | k-anonymity **as a floor, not as a guarantee**: it falls to high-dimensional data and auxiliary knowledge; complement it with l-diversity/t-closeness and accept that it is still not a formal guarantee |
| Formal guarantee | **Differential privacy** when statistics are published or models are trained over personal data — it is the only framework with a provable guarantee, and **it is paid for in utility**: an explicit ε budget, accounted for and published | Applying it without budget accounting (every query spends) or with a high ε "so the numbers come out": that is theatre with Greek notation |
| DP tooling | **OpenDP Library** (Harvard/OpenDP) and the **SmartNoise SDK**; **Tumult Analytics**; **Google DP** (Java/Go/C++) as an independent stack | **`smartnoise-core` is deprecated** and redirects to the OpenDP library: do not introduce it into anything new. Verify version and activity before choosing (§8) |
| Erasure at scale in immutable stores | **Crypto-shredding**: an encryption key **per data subject**, with audited destruction of the key | It is the only practical route in append-only logs, event sourcing, WORM and backups; it does **not** replace real erasure where real erasure is possible |
| PII detection | **Presidio** (analyzer/anonymizer/image-redactor/structured) in CI and in the data pipeline | **It changed owner**: it is a **community project under the *Data Privacy Stack***, images at `ghcr.io/data-privacy-stack/presidio-*`; the ones at `mcr.microsoft.com` are legacy and **are no longer updated**. Automatic detection = a net, never a guarantee |
| Data in pre-production | **Synthetic or generated**; if that is not viable, pseudonymised with a key irreversible to whoever operates the environment and **separate environments** | **FORBIDDEN** to copy production with real data to staging/QA/development. It is the most common breach and the cheapest to avoid |
| Consent | **Versioned state, with a timestamp, the exact text shown, the policy version and evidence of the action**; queryable and revocable via API | A banner that writes a cookie and nothing else; consent as a *boolean* with no history |
| Transfers outside the EEA | A design that is **agnostic to the transfer basis**: a known region, locatable data and a **proven ability to change region or provider** | Verify the status of the **EU-US Data Privacy Framework** before relying on it (§5 and §8): still in force but under challenge |
| DPIA/EIPD | **Triggered by written technical criteria** (§3.6), assessed as an engineering artifact and **before** the design, not before the launch | A DPIA written after building the system: that is a justification, not an assessment |
| PII in telemetry | **Forbidden by default**, with redaction at the edge and a test that verifies it | Trusting that "the team will be careful" when doing `log.info(user)` |

## 3. Design: privacy as a built property

### 3.1 Data inventory and taxonomy

Without an inventory there is no minimisation, no erasure and no correct breach notification. **The source of
truth is the annotated schema, not a spreadsheet**: it is versioned in git, validated in CI and the
documentation is generated from it, not the other way round.

```yaml
# data-catalog/users.yaml — per-field annotation, verified in CI
table: users
subject: user_person              # whose data it is (the key to everything else)
fields:
  email:
    class: direct_pii             # direct identifier
    purpose: [authentication, transactional_notification]   # NOT "marketing" unless consented
    lawful_basis: contract        # set by legal/DPO; recorded and enforced here
    retention: 30d_after_closure
    treatment: per_subject_encryption
  signup_ip:
    class: indirect_pii
    purpose: [antifraud]
    retention: 90d
  health_category:
    class: special_category       # Article 9 GDPR: demands reinforced justification and isolation
    purpose: [service_delivery]
    treatment: per_subject_encryption + restricted_access + access_auditing
destinations:                      # where it flows: without this, erasure is not complete
  - postgres.primary
  - postgres.reporting_replica
  - opensearch.users_index
  - kafka.topic.user_updated
  - s3://datalake/bronze/users
  - transactional_email_provider  # processor: contract + erasure procedure
```

Hard rules:
- **A field without `class`, `purpose` and `retention` does not get merged.** The gate is in §4.
- **Special categories** (health, biometrics, orientation, beliefs, origin…) and high-impact
  identifiers (national ID, children's data, precise geolocation, financial data) live
  **isolated**: their own schema or service, audited access by default, never in a shared
  `SELECT *`, never in a generic domain event.
- **`destinations` is the list of places where erasure must happen.** If it is incomplete, the erasure lies.

### 3.2 Minimisation and purpose limitation, applied

- **Real minimisation is a schema matter, not a policy one**: the field that is not in the table does not leak,
  does not get exported, does not get lost and does not have to be erased. For every new field: *which concrete
  product decision cannot be made without it?* If the answer is "just in case", it is not collected.
- **Minimum sufficient precision**: date of birth → age band; coordinates → municipality;
  exact timestamp → truncated hour. Reducing precision is the cheapest minimisation and the one
  nobody does.
- **Derive and discard**: if you only need "of legal age", compute the boolean at the edge and do not
  store the date. If you only need "returning customer", do not keep the full history.
- **Purpose limitation in the pipeline, not in the contract**: the purpose travels with the data
  (a column, an event header, a dataset label) and **a consumer that does not declare a compatible
  purpose does not receive the field**. One topic or one dataset per purpose is simpler and more
  defensible than a universal table with baroque access rules.
- **Analytics and product do not share a store**: derived datasets carry surrogate keys with no
  PII; the mapping table lives under the strictest access control in the system and with
  audited access.
- **LINDDUN over the DFD** in every new design or data-flow change, in the same session as
  STRIDE: STRIDE asks *"who can break it?"*; LINDDUN asks *"what does this system do to
  the person even when it works perfectly?"*. Threats STRIDE does **not** see: linkability between
  sessions, identification by combination, inference, detectability (the mere fact that you exist in
  the system already reveals something), lack of transparency. Start with **GO** (cheap, as a team); move to
  **PRO/MAESTRO** when the system is large or the data sensitive.

### 3.3 Pseudonymisation, anonymisation and the usual lie

- **Pseudonymised is still personal data.** Every obligation applies. It reduces risk, not
  scope.
- **Anonymisation is irreversible and is assessed against the context**, including the additional
  information available to whoever processes the data and what is reasonably accessible. Almost everything the
  industry calls "anonymised" is not: removing the name anonymises nothing when
  postcode + date of birth + sex remain, or a geolocation trace, or a purchase pattern.
- **k-anonymity**: it guarantees that each record is indistinguishable from k-1 others **on the
  quasi-identifiers you declared**. It fails through: high dimensionality (with dozens of attributes, a
  useful k is unreachable), homogeneity attacks (everyone in the group shares the sensitive
  attribute → **l-diversity**), distribution skew (**t-closeness**) and external auxiliary
  knowledge, which you cannot bound. Use it as a publishable floor, never as proof of anonymity.
- **Differential privacy** is the only thing with a formal guarantee: it bounds how much an
  observer can learn about a specific individual, **regardless of what they already know**. Real cost:
  noise, and therefore loss of utility in low-frequency queries and tails — accept that before
  promising a dashboard. It requires **ε budget accounting** across all queries
  and publications over the same dataset: without accounting, the guarantee disappears by the third
  query.
- **An AEPD criterion that must be internalised**: if what you called "anonymised" allows
  re-identification, the processing is personal data processing with all its consequences — and having
  documented as "anonymous" what was pseudonymous is an aggravating factor, because it contradicts the
  accountability principle. The guidance **"Orientaciones y garantías en los procedimientos de anonimización"**
  additionally requires **separation of environments and of roles**: whoever works with the anonymised set does not access
  the original data or the anonymisation keys.

### 3.4 Techniques: when to use each one

| Technique | Used for | The limit that must be said out loud |
|---|---|---|
| **Tokenisation** | Taking the sensitive data out of the system that uses it (payments, national ID) leaving a worthless token | The vault concentrates all the risk; its compromise is the maximum incident |
| **Per-data-subject encryption** | Enabling **crypto-shredding** and compartmentalising the blast radius | It complicates queries and joins: decide **at design time** which fields are encrypted and which stay in the clear for querying |
| **Masking** (static/dynamic) | Reducing exposure in support, BI and operational access | **Dynamic** masking does not protect against `pg_dump`; static masking only works if the source never leaves |
| **Synthetic data** | Pre-production, demos, load and performance tests | A generator trained on production **can memorise and leak**: generate from the schema and business rules, or apply DP to the generator. And validate that it does exercise the edge cases |
| **Aggregation / precision reduction** | Metrics, reports, product signals | Successive aggregates over the same data allow reconstructing the individual (differential attacks) |
| **Differential privacy** | Publishing statistics and training with a guarantee | Reduced utility; a budget that gets exhausted |

### 3.5 Data subject rights as functionality

They are **endpoints and jobs with an SLA**, not a mailbox with a person searching by hand. Minimum
design:

- **Access and portability**: a complete per-subject export, in a structured and commonly used format,
  generated **from the catalogue** (§3.1) — if a store does not appear in `destinations`, it is not exported and
  the answer is incomplete. Delivery over an authenticated channel, with an expiring link, without attaching
  the dump to an email.
- **Rectification**: propagable. A value corrected in the DB and not in the search index, the cache,
  the CRM and the email provider is an incorrect value still alive in four places.
- **Erasure**: it is the right that reveals whether the system was well designed. Scope **complete and
  demonstrable**:
  1. **Primary store**: real deletion. An eternal *soft delete* **is not erasure**.
  2. **Replicas and standbys**: it propagates on its own; verify it, do not assume it.
  3. **Caches and sessions**: explicit invalidation, do not wait for the TTL.
  4. **Search indexes** (OpenSearch/Elastic/vector): explicit deletion; vector indexes
     and embeddings are **also** data derived from the subject.
  5. **Queues and event logs**: tombstone + compaction where it exists; where it does not, crypto-shredding.
  6. **Data lake / warehouse**: including *time travel*, snapshots and table versions (Delta,
     Iceberg, BigQuery, Snowflake). Shrink the window **before** deleting or document the residue.
  7. **Logs and telemetry**: if they contain PII, the problem is earlier (§5); while it exists, it falls
     within scope.
  8. **Processors and third parties**: a contractual erasure procedure **with verification**, not an
     email asking for it. Record the date and the confirmation.
  9. **AI models trained on the data**: see §5.
  10. **Backups**: see below.
- **The honest, defensible answer about backups.** Deleting a specific record inside an
  intact or immutable backup is, in general, **impossible without destroying the backup**, and destroying it puts
  continuity at risk — which is also an obligation. What is defensible is, in this order:
  1. **Design so that you do not need it**: per-subject encryption from the start, so that
     destroying the key also reaches what gets restored. This is the only complete solution, and
     it is a day-1 architecture decision: retrofitting is extremely expensive.
  2. **Bound and document the window**: the backup's retention is finite, known, published to the
     data subject and **actually enforced** (the retention and immutability policy is set by
     `bcdr-standards`). The residue extinguishes itself when the window expires.
  3. **Put the data out of use**: the backup is not used for anything other than disaster
     recovery, with restricted and audited access.
  4. **Reapply the erasure after any restoration**: the list of pending erasures is an
     operational artifact (a *tombstone* register with timestamps) that is replicated **outside**
     the backed-up system, and the restore runbook includes reprocessing it as a mandatory and
     verified step. A restore that resurrects deleted data is a new breach.
  5. **Say it**: inform the data subject of the real extinction deadline. Promising an immediate erasure
     that does not happen is worse than explaining the window.
  - **Verify the status of the regulatory recognition of crypto-shredding** as a form of
    erasure before relying on it alone: the sources contradict each other (§8). The technical control is
    solid; its legal qualification is set by legal/DPO.
- **Every rights operation leaves evidence**: who requested it, how their identity was verified, which
  stores were touched, what was executed, when and with what result — **without creating unnecessary
  PII again** in the evidence record itself.

### 3.6 Consent and DPIA

**Consent** = versioned, auditable state, not a banner:
`subject · purpose · granularity (one per purpose, no bundles) · version of the exact text
shown · timestamp · evidence of the action · channel · state (granted/withdrawn) · full
history`. Withdrawing must be **as easy as granting**, with the effect propagated to every consumer
(it is not enough to stop showing the banner). And the rule most often broken: **the system must not
be able to process the data for a purpose without valid consent** — it is checked in the code,
not in a meeting.

**DPIA/EIPD as an engineering artifact**, triggered by written technical criteria and assessed
**before** building. Minimum triggers: large-scale processing of special categories; systematic
observation of publicly accessible areas or of behaviour; profiling
with legal or significant effects; automated decisions; children's or vulnerable people's data;
combining datasets from different origins; the use of new technology
(including AI) over personal data; transfer of sensitive data outside the EEA. **Also consult
the list of processing operations the supervisory authority publishes** (§8): in Spain the AEPD has its
own list. The DPIA is **reviewed** when the processing changes — it is not a one-off PDF.

## 4. Quality gates (they break the build)

In increasing cost order. The first four are automatic:

1. **Annotated schema**: no migration adding or changing a field gets merged without `class`,
   `purpose` and `retention` in the catalogue (§3.1). It is a 40-line *linter* and it avoids 80% of the
   problem.
2. **PII detection in code and in data**: Presidio (or another detector) over (a) the diff, looking for
   literal PII, real test data and dumps; (b) samples of logs and events in staging; (c)
   new columns, comparing the actual content with the declared class. A field declared
   `internal` with emails inside is a finding that breaks the build. **Automatic detection is a
   net, not a guarantee**: it does not replace explicit annotation.
3. **A "the erasure really erases" test**, across every store: create a synthetic subject,
   propagate it through the whole system (DB, replica, cache, index, topic, lake, export to third parties in a
   *sandbox*), run the erasure and **search for the identifier in every store**. It fails if it appears in
   any of them. It is the test no organisation has and the only one that proves the right. Mandatory
   extension: repeat the search **after a test restore** (coordinated with
   `bcdr-standards`) to verify that erasures get reapplied.
4. **Pre-production without real data**: a scheduled scanner over non-production environments looking for
   PII patterns and **any identifier that exists in production**. A hit is an incident,
   not a warning. Complementary: a technical (not merely procedural) prohibition of the paths that copy
   production downwards — no production read credentials in the staging refresh pipeline.
5. **Retention test**: check that the retention deletion job ran and **how many rows
   it deleted**. A job that runs successfully and deletes 0 rows forever is a broken job. Alert on
   missing runs and on the maximum age of the oldest record per table.
6. **Purpose test**: a consumer without a declared compatible purpose does not get the field.
   A contract verified in CI, not trust.
7. **Consent test**: consent-based processing fails (it stops, it does not continue) if
   there is no valid consent; withdrawal propagates and is verified.
8. **Privacy review at design time**: LINDDUN applied and its threats with mitigation, documented
   acceptance or a reasoned "not applicable". Without this, the PR for a new data flow is not approved.

## 5. Specific fronts

### PII in telemetry and logs — where most of it leaks

It is the number one leak point, always by accident: `log.debug(request)`, an exception with the
whole body, a URL with the email in the *query string*, a `user_id` that is the email, a metric
label with the identifier (which also blows up cardinality), an APM *breadcrumb*, a
recorded front-end session.

- **Redaction at the edge, not at the destination**: it is filtered before leaving the process; relying on the
  log backend's redaction leaves the PII in transit and in every intermediate replica.
- **An allowlist, not a blocklist**: the declared fields get logged; everything else is discarded.
  A blocklist always arrives late for the new field.
- **Opaque** identifiers in logs and traces (never email, phone number or national ID as a correlation key).
- **The log's retention = the retention of the data it contains.** A log with PII at 400 days is a PII store
  at 400 days, and it falls within the scope of erasure (§3.5).
- Session recording and heatmaps: prior consent, field masking by default and
  total exclusion of sensitive forms. **It is product analytics, not operational
  telemetry**: `observability-standards` does not cover it and it must not be used as an alibi for putting it
  in the same pipeline. Its business justification belongs to `analytics-bi-standards`; the
  processing and the lawful basis, here.

### International transfers (status Aug 2026, **verify it**)

- The **EU-US Data Privacy Framework adequacy decision is still in force**. The General Court
  dismissed the Latombe action (T-553/23) on **3 Sep 2025**; there is an **appeal pending
  before the CJEU (C-703/25 P)**. In addition, the US Supreme Court's judgment in *Trump v.
  Slaughter* (**29 Jun 2026**), which removed the protection against removal of FTC
  commissioners, has reopened the debate about the independence of the supervisor enforcing the framework,
  with a formal request from noyb to the Commission to withdraw it, and the PCLOB remains unable to carry out
  the reviews EO 14086 itself requires.
- **An engineering criterion, not a legal one**: the framework has fallen twice (Safe Harbor, Privacy Shield)
  and is under challenge for the third time. **Design so that its fall is a configuration change, not a
  redesign**: a known and declared region per dataset, a proven ability to move the processing to
  an EEA region, encryption with keys under your own control (and not accessible to the provider), and a
  register of sub-processors with their location. A provider being certified does not exempt you from knowing
  **where your data is and who can access it**.
- What legal/DPO decides: the applicable transfer basis (adequacy, SCCs, BCRs, derogations) and
  the transfer impact assessment. Engineering provides the real technical map.

### Personal data and AI systems

- **Training on personal data is processing** and needs its own lawful basis; the basis of the
  original service **does not extend** to training by default. Status Aug 2026: the *Digital Omnibus*
  proposal that would introduce an explicit legitimate interest for AI development (new
  art. 88c) and would narrow the definition of pseudonymised personal data **is still a proposal,
  not law in force**, with express opposition from the EDPB and the EDPS (Joint Opinion 2/2026,
  10 Feb 2026). **Do not design assuming it will be adopted.**
- **A model is not anonymous just by being a model**: the EDPB (Opinion 28/2024, 17 Dec 2024) establishes that a
  model's anonymity must be demonstrated case by case and that the threshold is high — the likelihood of extracting
  personal data, directly or through queries, must be insignificant for **each**
  data subject. Practical consequence: memorisation and extraction are privacy risks that get
  **tested** (membership inference and extraction attacks before publishing the model), not
  assumed solved.
- **Erasure and models**: retraining can be disproportionate, and *machine unlearning* is not a
  mature technique. Defensible routes: training with DP from the start, excluding the data from the next
  training cycle with a verifiable procedure, filtering at the output, and **documenting the
  limitation honestly**. Promising a model erasure you cannot execute is worse than
  explaining the limit.
- **Prompts, RAG and inference logs are personal data stores**: they enter the catalogue, the
  retention and the scope of erasure. A vector index built over documents with
  PII is a PII store.
- **AI Act — effective calendar verified as of Aug 2026** (after the *Digital Omnibus* on AI, adopted
  by Parliament on 16 Jun 2026 and by the Council on 29 Jun 2026, in force in July 2026):
  **2 Aug 2026** the transparency obligations of art. 50 apply (with the exception of art. 50(2)
  for systems already on the market on that date); **2 Dec 2026**, art. 50(2) (marking/watermarking)
  for legacy systems and the new prohibited practices added; **2 Dec 2027**, the
  high-risk obligations of Annex III (standalone); **2 Aug 2028**, those of Annex I
  (embedded). **The high-risk postponement does not change the GDPR**: privacy obligations
  still apply today, in full, with or without the AI Act. **Declared gap**: the dates of the
  obligations already applicable before 2026 (prohibitions, AI literacy, GPAI) have not been
  cross-checked in this review (§8).

### Personal data breach

The process, the roles and the deadlines belong to `incident-management-standards` and
`incident-response-forensics-standards`; **the criterion for notifying belongs to legal/DPO**. What this
skill demands is that engineering can answer **in hours, not weeks**:

- **Which categories of data** were in the affected system → it comes from the catalogue (§3.1). Without a
  catalogue, the answer is "we do not know", which is the worst of all.
- **Approximately how many data subjects**, and from which groups (children, patients, employees).
- **Whether the data was readable**: encryption with a non-compromised key radically changes the risk
  assessment for the data subject — and therefore the obligation to communicate to those affected. This is decided
  the day the encryption is designed, not the day of the breach.
- **What an attacker can do with it**: the assessment is of the risk **to the person**
  (impersonation, discrimination, physical harm, financial loss), not to the company.
- **Document every breach**, whether notified or not. The AEPD publishes guidance and an assessment tool:
  use them as a reference, verifying that they are current (§8).

## 6. Operability

- **Internal rights SLA**: measure the time from the request to full execution, with a
  target **well below** the legal deadline (which is verified in §8) — the legal deadline is the limit,
  not the target. Alert on requests close to expiring.
- **Metrics that matter**: number of personal data fields per service (**target: going down**);
  % of fields with automated and executed retention; age of the oldest record per table
  against its declared retention; rights requests by type and time to serve; PII findings
  in logs and in pre-production; accesses to sensitive data per person and their review; ε budget
  consumed per published dataset.
- **Cost as an argument**: every personal field costs encryption, retention, erasure, auditing, breach
  risk and rights work. Minimising is the most profitable optimisation in the system and the only
  argument that usually convinces whoever asks to "keep it just in case".
- **Access review** to sensitive data on a cadence and with consequences; bulk exports
  with approval and an audit trail (exfiltration control).
- **Purging as a first-class operation**: the retention job has an owner, a runbook, an alert and a
  metric, just like a backup. And like any destructive operation, it is tested in an environment with
  representative data before being let loose on production.

## 7. Sustainability and prohibitions

**Cadence**: the data catalogue reviewed quarterly (new fields, new destinations,
new providers); the DPIA reviewed on any material change of the processing; a **quarterly
regulatory radar** — this domain moves by quarters and §8 is what stops you asserting something
expired —; an annual review of the consent texts and of the privacy policy against
what the system **actually** does.

**Privacy debt**: every exception (a field that cannot be erased, a store without erasure
coverage, a third party without a verified procedure) is recorded with an owner, a risk and an **expiry
date**. Without a date, it is an undocumented architecture decision.

**FORBIDDEN**
- ❌ Copying production data to development, QA or demo. No "temporary" exceptions.
- ❌ Calling a pseudonymised set "anonymised", in the code, in the DPIA or in a contract.
- ❌ Publishing or sharing "anonymised" data without a documented re-identification assessment.
- ❌ Collecting a field "just in case", or keeping more precision than is needed.
- ❌ Retention written in a policy and not implemented as verified automatic deletion.
- ❌ An eternal *soft delete* as the answer to the right to erasure.
- ❌ An erasure that does not reach replicas, caches, indexes, queues, the lake, logs and processors.
- ❌ Restoring a backup without reapplying the pending erasures.
- ❌ Promising the data subject an immediate erasure the architecture cannot execute.
- ❌ PII in logs, traces, metrics, error messages, URLs or cache keys.
- ❌ Personal identifiers (email, phone, national ID) as a correlation key or as `user_id`.
- ❌ Consent as a boolean with no version, no text and no history; bundled consents;
  withdrawal harder than granting.
- ❌ Processing data for a purpose other than the declared one because "we already have it".
- ❌ Training models on personal data without their own lawful basis and without a memorisation assessment.
- ❌ Assuming that a model trained on personal data is anonymous.
- ❌ Special categories in the same schema, event or index as ordinary data.
- ❌ A DPIA written after building the system, or never reviewed.
- ❌ Resting the whole design on a specific adequacy decision without a proven ability to change
  region or provider.
- ❌ Applying differential privacy without ε budget accounting.
- ❌ Introducing `smartnoise-core` (deprecated) or Presidio images from `mcr.microsoft.com` (no longer
  updated) into anything new.
- ❌ Relying on an automatic PII detector alone as a compliance control.
- ❌ Fixing legal deadlines, standard names or regulatory status **from memory** (§8).

## 8. Mandatory web verification

Before pinning any standard, deadline, version or status, **look it up — do not remember it**. Here
inventing is the worst possible error:

1. **EU-US Data Privacy Framework**: whether the adequacy decision is still in force; the status of appeal
   **C-703/25 P** before the CJEU; the consequences of *Trump v. Slaughter* (29 Jun 2026) on the
   independence of the FTC and on the position of the Commission and the EDPB; the status of the PCLOB. It is the
   fact most often cited from memory and the most likely to be expired.
2. **AI Act**: the effective calendar after the *Digital Omnibus* on AI (adopted Jun 2026, in force
   Jul 2026). Verified: 2 Aug 2026 art. 50; 2 Dec 2026 art. 50(2) legacy + new prohibitions;
   2 Dec 2027 high risk Annex III; 2 Aug 2028 Annex I. **Declared gap**: the dates of the
   obligations prior to 2026 (initial prohibited practices, AI literacy, GPAI) have not been
   cross-checked.
3. **Digital Omnibus — the GDPR/ePrivacy track**: as of Aug 2026 it was still at **proposal stage** (the definition
   of pseudonymised personal data, art. 88c on legitimate interest for AI, processing of special
   categories for bias detection), with opposition from the EDPB/EDPS (Joint Opinion 2/2026).
   **Verify whether it has been adopted and in what terms before basing a design on it.**
4. **NIST Privacy Framework**: whether the final **v1.1** has been published (as of Aug 2026 it was not confirmed;
   IPD Apr 2025, new section 1.2.2 on AI and privacy, alignment with CSF 2.0). Cite the verified
   edition.
5. **LINDDUN**: the current variants (GO/PRO/MAESTRO) and the current breakdown of the acronym on
   `linddun.org`. **Declared gap**: the site does not publish a version number; there is an
   "Enhanced LINDDUN GO" revision of the cards with no date located.
6. **EDPB**: the **final** status of the *Guidelines 01/2025 on Pseudonymisation* (adopted for
   consultation on 16 Jan 2025; **the final version not confirmed** as of Aug 2026) and of the CJEU
   judgment in **C-413/23 P** (*EDPS v SRB*), whose conclusion on pseudonymised data in the hands of a
   third party may change the criterion. Opinion 28/2024 on AI models, and any new
   guidance on anonymisation, *scraping* or erasure.
7. **Crypto-shredding**: **a declared gap and a source conflict** — it has not been possible to confirm whether the
   EDPB (Guidelines 5/2019 on the right to be forgotten) expressly recognises cryptographic
   erasure as erasure under Article 17, nor the AEPD's current position. Verify it against a primary
   source before relying on it alone.
8. **AEPD**: whether the guidance *"Orientaciones y garantías en los procedimientos de anonimización"*
   and the *Guía básica de anonimización* are current; the guidance and assessment tool for **personal data
   breaches** and its notification channel; the **list of processing operations requiring a DPIA**; its criterion
   on real data in test environments. **Declared gap**: it has not been verified whether a later
   edition of those guides exists, nor the exact response deadline for rights currently in force — do not cite it
   from memory.
9. **Deadlines**: breach notification (Articles 33/34 GDPR) and response to rights — cross-check them with the
   incident skills and with the primary source; the legal criterion belongs to legal/DPO.
10. **Tools** before recommending them: **Presidio** (a community project under the *Data Privacy Stack*,
    2.2.363 of Jun 2026, `presidio-analyzer` on PyPI Jul 2026, images at
    `ghcr.io/data-privacy-stack`), the **OpenDP Library** and the **SmartNoise SDK** (`smartnoise-core`
    deprecated), **Tumult Analytics**, **Google DP**. **Declared gap**: neither the current
    version nor the cadence of the OpenDP library has been confirmed — verify it before pinning it. Also check
    the licence and any recent **supply-chain incident** (a precedent from the
    catalogue: Trivy dropped as the default after the March 2026 compromise).

If you cannot verify it, **say so explicitly instead of assuming**.
If the web contradicts this document, **the web wins** — flag the discrepancy.
