---
name: healthtech-fhir-standards
description: Clinical interoperability and health software engineering. Use when working with HL7 FHIR (R4 4.0.1, R5 5.0.0, R6 ballot), FHIR resources such as Patient, Encounter, Observation, Condition, MedicationRequest, DiagnosticReport, DocumentReference, Consent, AuditEvent and Provenance, StructureDefinition profiles and extensions, ImplementationGuide packages and the IG Publisher, hl7.fhir.us.core, hl7.fhir.uv.ips, hl7.fhir.uv.smart-app-launch, CapabilityStatement and $validate, Bundle transaction/batch/document, FHIR search parameters, _include, _revinclude, chained search and $everything, Bulk Data $export and NDJSON, FHIR Subscriptions and topic-based subscriptions, SMART on FHIR launch and scopes (patient/*.rs, user/*.rs, system/*.rs), HL7 v2.x pipe-and-hat messages (ADT, ORM, ORU, MSH/PID/OBX segments), MLLP interfaces and integration engines (Mirth/NextGen Connect, Rhapsody, Iguana, InterSystems Ensemble/HealthShare), CDA and C-CDA documents, IHE profiles (XDS.b, PIX/PDQ, ATNA, MHD), DICOM, DICOMweb, PACS, modality worklist and HL7-to-DICOM mapping, terminology servers and CodeSystem/ValueSet/ConceptMap with SNOMED CT, LOINC, ICD-10/ICD-11, CIE-10-ES, RxNorm or ATC, the International Patient Summary and MyHealth@EU, the European Health Data Space Regulation (EU) 2025/327, MDR/IVDR Rule 11 classification of software as a medical device, or clinical access auditing and patient consent as product requirements.
---

# Health software and clinical interoperability standards (FHIR)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when the system **handles clinical data about an identifiable person** and has to
exchange it with another system, another hospital, another country or with the patient themselves.

**Domain thesis, and it orders the whole document: interoperability is not transport, it is
meaning.** Moving a JSON from A to B is the easy part and solves nothing. The problem is that a laboratory
value **without** its LOINC code, its UCUM unit, its reference range, its method, its
date, its status (`preliminary`/`final`/`corrected`/`entered-in-error`) and its subject **is not
clinical data: it is a dangerous number**. A corollary that changes design decisions:

- **A free-text field is not interoperable.** If the receiver has to read it in order to act, you have not
  interoperated, you have sent mail.
- **The document's status is part of the data.** A corrected result that arrives without voiding the
  previous one is a clinical error, not a synchronisation bug.
- **Patient identity is the hard problem, not the easy one.** Patient *matching*
  between systems is where serious harm occurs (data on the wrong patient). It is never
  solved with "name and date of birth" (§3.5).

Second thesis, uncomfortable and necessary: **health software is not an app with a database, it is
critical infrastructure under two simultaneous regulatory regimes** — data protection
(special category under Art. 9 of the GDPR, §5.4) and, if it has a medical purpose, medical device
(MDR/IVDR, §7.1). Neither of the two is solved at the end of the project.

Covers: choice of FHIR version and profiles; modelling with resources, profiles, extensions and
implementation guides; REST, search, `Bundle` and transactions; terminologies and their licensing; HL7 v2 and
CDA as the installed reality; DICOM for imaging; SMART on FHIR and consent; access auditing;
and the European regulatory axis (EHDS, MDR/IVDR) in whatever decides architecture.

**Not applicable**:
- `mumps-standards` (**reciprocal boundary, already declared by that skill**): **the M/globals core, its
  language, its platform (IRIS/Caché, YottaDB/GT.M), VistA, FileMan, Epic Chronicles and the decision
  to migrate, encapsulate or freeze are theirs**. **From here, all the clinical interoperability
  criteria** —resources, profiles, terminologies, conformance, the detail of HL7 v2 and IHE—, including
  **the FHIR/HL7 v2 facade that that skill requires as the only way clinical data leaves**. Arbitration
  rule: *"how is it stored and who writes it?" is theirs; "under what contract does it leave and what
  does what leaves mean?" belongs here*.
- `safety-critical-standards` (**sibling, boundary declared on both sides**): **theirs the functional
  safety process of the medical device once classified** — the **IEC 62304** lifecycle and
  its classes A/B/C, risk management under **ISO 14971**, requirement→code→test traceability,
  structural coverage, tool qualification and evidence for the notified body. **From here:
  whether the software *is* a medical device** (MDR rule 11, §7.1) and the design of the clinical
  information it handles. Arbitration rule: *"is this a medical device and what clinical data
  does it exchange?" belongs here; "what process evidence must be produced to certify it?" is theirs*.
- `privacy-engineering-standards`: **theirs the GDPR as engineering** — minimisation, lawful basis,
  retention and erasure, data subject rights, DPIA, pseudonymisation and anonymisation, PII in
  telemetry. **From here only the specifically clinical part**: why health data is a special
  category (§5.4), why pseudonymising a medical record is more fragile than it
  looks, and access auditing as a functional requirement (§5.5).
- `grc-compliance-standards`: management framework, ISO 27001, ENS, NIS2, SoA and audit evidence.
- `identity-access-management-standards`: **the IdP, OAuth 2.1/OIDC, passkeys, SCIM and the
  authorisation engines are theirs**. From here only **SMART on FHIR** as a domain-specific
  OAuth2 profile, with its *scopes* and its launch context (§5.1).
- `api-design-standards`: general REST, versioning, RFC 9457, idempotency, pagination as
  patterns. **From here whatever FHIR already decides and is not renegotiated** (§3.3): FHIR **is** a
  published contract, and "improving" it with your own conventions breaks interoperability, which is the only
  reason to use it.
- `data-governance-quality-standards`: data ownership, glossary, data contracts and quality
  as a programme. From here, the **coded clinical meaning**, which is something else.
- `ai-governance-standards`: **the AI Act, risk classification of the AI system,
  provider/deployer roles, human oversight and Art. 73**. From here, the interaction: health
  software with AI usually accumulates **both** regimes (§7.3).
- `accessibility-standards` (patient portal: WCAG criteria and their testing),
  `cryptography-pki-standards` (algorithms, TLS, keys), `appsec-standards` (threat modelling
  and vulnerability classes), `data-platform-standards` and `object-storage-standards` (the engine and
  the store), `observability-standards`, `bcdr-standards` and `backup-recovery-standards` (a
  hospital has no downtime window), `legacy-modernization-standards` and
  `migration-projects-standards` (the portfolio and the cutover), `i18n-standards`,
  `offensive-security-standards` (**this skill is defensive**).

## 2. Default decisions

> Verify the latest version and its status on the web before pinning it in a real project (§8).

| Decision | Choice | Verified as of Aug 2026 |
|---|---|---|
| **FHIR version** | **R4 (4.0.1)** unless there is an explicit reason | **The fact that decides and almost nobody checks**: the history page at `hl7.org/fhir` describes R4 (2018-12-27) as *"First Normative Content + Trial Use Developments"*, and of **R5 (5.0.0, 2023-03-26)** it says verbatim: *"This 5th Major release of the FHIR specification is labeled as 'trial-use'... None of the content in this specification is considered Normative."* **R4 is still the normative baseline and the one real systems support** |
| **R5** | Only if you need a resource that does not exist in R4 and you control both ends | Trial-use. Scant real adoption in installed products |
| **R6** | **No** in production | In **ballot**: the `build.fhir.org` build identifies itself as **v6.0.0-ballot4** and declares *"This is the first full normative version of the standard - none of the content in this specification is considered trial-use"*, with the intent to *"move most of the resources in the Foundation, Base and Clinical layers to full Normative status"*. **It is the version that matters in the medium term, and it is not published yet** |
| **R4B (4.3.0)** | Avoid unless there is a specific requirement | 2022-05-28, *"Staging release of modifications in specific areas"* |
| **Base profile** | **The applicable national/regional IG if one exists; otherwise IPS** | **IPS (International Patient Summary): `hl7.fhir.uv.ips#2.0.1`, over FHIR 4.0.1** (HL7 International / Patient Care). Aligned with **ISO 27269** and with the unplanned cross-border care scenario |
| **US** | `hl7.fhir.us.core` | **v9.0.0, package `hl7.fhir.us.core#9.0.0`, over FHIR 4.0.1, published 2026-05-31**; anchored to **USCDI** and to ONC/ASTP certification |
| **Spain** | **Verify case by case: there is no single national IG equivalent to US Core** | There are Ministry of Health IGs for specific domains (e.g. **ÚNICAS**, `unicas-fhir.sanidad.gob.es`, v0.0.6, over **R5**, aligned with **MyHealth@EU NCPeH** and with IPS). **Declared gap (§8): no general FHIR guide for the HCDSNS has been located.** Do not invent its existence in a tender |
| **Clinical app authorisation** | **SMART App Launch** | `hl7.fhir.uv.smart-app-launch#2.2.0`, **STU 2.2, active since 2023-03-01**. Patterns *"based on OAuth 2.0"*; **the scope syntax changed from SMARTv1** — verbatim from the guide: *"The scope syntax has changed since SMARTv1"* |
| **Installed messaging** | **HL7 v2.x over MLLP** — it is not replaced, it is wrapped | §2.1 |
| **Documents** | **CDA / C-CDA** where it already exists; **FHIR Document** for new work | The signed clinical document is still a legal requirement in many flows |
| **Imaging** | **DICOM** and **DICOMweb** (WADO-RS/QIDO-RS/STOW-RS) | The DICOM standard is published **free of charge** at `dicom.nema.org`: use it verbatim, there is no excuse |
| **Clinical terminology** | **SNOMED CT** for findings, procedures and diagnoses | Licensing: §2.2 |
| **Laboratory and observations** | **LOINC** (what was measured) + **UCUM** (unit) | LOINC is free with registration |
| **Administrative diagnosis coding** | **ICD-10 / CIE-10-ES** in Spain; **ICD-11** where the authority already requires it | **They are not interchangeable with SNOMED CT**: a different purpose (statistics/billing vs. clinical recording) |
| **Terminology server** | A dedicated service with `$lookup`, `$validate-code`, `$expand`, `$translate` | A table of codes copied into your database **expires**, and with it the validity of the data |

### 2.1 HL7 v2 is still alive, and this is not nostalgia

**Most of the real clinical traffic circulating inside a hospital today is HL7
v2.x messages** —ADT for admission/discharge/transfer, ORM for orders, ORU for results— over MLLP, moved by
an integration engine (Mirth/NextGen Connect, Rhapsody, Iguana, Ensemble/HealthShare). **No
serious FHIR project starts without accepting that**, and whoever plans to "migrate everything to FHIR" is planning
a project that never ends. *(Quantification: no source with methodology has been located to
give a percentage. Predominance is asserted qualitatively, not with a figure — §8.)*

Operational criteria:
- **FHIR is the facade, v2 is the bus.** The destination of every **new** integration is FHIR; the
  internal interface with the existing HIS/LIS/RIS remains v2 for years, and that is correct.
- **The v2 → FHIR translation is not mechanical**: v2 has site-dependent semantics (the
  `Z` segments, local tables, creative use of `OBX`). Every v2 interface is an undocumented bilateral
  contract. **Budget for discovery, not for conversion.**
- **`OBX-5` without `OBX-6` (unit) or without a coded `OBX-3` is unusable data**: in the translation
  it is detected there, not in production.

### 2.2 SNOMED CT and its licence — the fact that decides and almost nobody verifies

**Verified verbatim at `snomed.org`:** *"SNOMED International does not charge for use of SNOMED CT
in SNOMED International Member countries or territories."* And for the rest: *"If you are using
and/or deploying SNOMED CT in a non-Member country/territory, you are required to apply for a
license through the Member Licensing & Distribution Service (MLDS) on an annual basis"*, with
*"Charges may apply for affiliate use of SNOMED CT in non-Member territories"*, calculated according to
use and territory (World Bank classification).

**Spain appears on the list of SNOMED International member countries** (verified at
`snomed.org/members`). Consequences that are decided **before** writing code:

- **Membership belongs to the territory, not to your company.** A SaaS serving from Spain into a
  **non**-member country falls under that country's licensing regime.
- Whoever deploys in a member country **registers with that country's National Release Centre (NRC)**.
- **The national extension matters**: a concept from the Spanish extension does not exist in the
  international edition. A `ValueSet` mixing both without declaring the edition version is a time
  bomb the moment you cross a border.
- **Verify your territory's membership status and conditions before signing the
  contract** (§8): the member list changes.

## 3. FHIR modelling and conventions

### 3.1 Resource, profile, extension, IG — in that order

1. **Use the standard resource as-is** whenever it fits. The temptation to create "our model"
   is exactly what FHIR exists to avoid.
2. **Profile (`StructureDefinition`)** to constrain: cardinalities, mandatory `ValueSet`s,
   *slicing* of `identifier`. A profile **constrains**, it never extends the semantics.
3. **Extend (`Extension`)** only when the data fits in no standard element, with your own canonical
   URL, a published definition and its own `ValueSet`. **An unpublished extension is private data
   dressed up as a standard.**
4. **Publish an IG** with the **IG Publisher** and distribute it as a **FHIR NPM package**
   (`org.domain.ig#x.y.z`). A profile that lives in a PDF is validated by nobody.
5. **Before creating anything, look for whether it already exists**: in the package registry, in the authority's
   IGs and in the international ones. Reinventing an already published profile is the typical expensive mistake.

### 3.2 Identifiers — where projects break

- **`Patient.identifier` is a list with a system**, and the `system` is mandatory and meaningful:
  hospital A's record number and hospital B's **are not the same space**, even if
  the digits coincide.
- **`Resource.id` is the server's key, not the business identifier.** It is never exposed as
  the "record number" nor reused when migrating.
- **In Spain, the identifier that crosses systems is the SNS/regional CIP and the DNI/NIE**;
  which one is the identity authority for your integration is decided and documented at the start, with its
  canonical `system`.
- **A `system` invented on the fly is permanent debt**: it appears in historical data for
  ever.

### 3.3 FHIR REST — what is already decided and is not renegotiated

FHIR **already defines** the API: `GET /Patient/{id}`, `PUT` with concurrency control via `ETag` and
`If-Match`, history through `/_history`, conditional `POST` with `If-None-Exist`, `OperationOutcome`
as the error body. **It is not replaced by your own conventions** (neither RFC 9457, nor `/api/v2/`, nor
`{data: ...}` wrappers): the only reason to use FHIR is so that the other end does not have to learn
your API. `api-design-standards` explicitly cedes here.

- **Versioning**: done by **FHIR version + IG version**, not by path prefix. A
  client negotiates through the `CapabilityStatement`, not through documentation.
- **A published and real `CapabilityStatement`**: it is the contract. If it declares `Observation.search` by
  `code` and it is not implemented, the client discovers the lie in production.
- **Search**: standard parameters; `_include`/`_revinclude` to avoid N+1; **chained**
  (`Observation?subject.name=`) with care, because it is expensive; `_summary` and `_elements` to reduce
  payload. **Every search paginated**, always, with the `Bundle`'s `next`/`self` links.
- **`Bundle`**: `searchset` for results; **`transaction` when everything must be applied or nothing**
  (atomic, with `fullUrl` and internal references resolved); `batch` when each entry is
  independent. **Confusing `batch` with `transaction` produces half-applied clinical states** — a
  `MedicationRequest` without its `Condition` is exactly the kind of failure that harms.
- **References**: relative within the server (`Patient/123`), absolute only when the resource
  lives on another server and that server is resolvable.

### 3.4 Status, correction and deletion

- **In clinical care you do not delete: you void.** `status = entered-in-error` is the mechanism; a physical
  `DELETE` destroys traceability and is usually illegal (the obligation to retain the medical
  record). Erasure under the GDPR right to erasure is **assessed** against that legal retention
  obligation: deciding it belongs to `privacy-engineering-standards`, but **the system has to
  be able to distinguish "voided" from "deleted"**.
- **`Provenance` and `meta.versionId` are not optional** in a system from which clinical decisions
  are derived: who wrote it, from which system and when.
- **A correction generates a new resource and voids the previous one**, and the consumer has to
  find out (§6.2). A corrected result that does not propagate is the worst failure of this layer.

### 3.5 Patient identification

- **Never do your own *matching* with name + date of birth.** A matching error is
  direct clinical harm (data on the wrong patient), and it is the most frequent class of incident
  in integration.
- The organisation's **identity service** is used (an MPI, or IHE's `PIX/PDQ`, or
  FHIR's `$match`) **as the source**, with its threshold and its human review queue for doubtful cases.
- **Automatic matching without human review for borderline cases is not acceptable**; and the
  threshold is documented as a clinical decision, not as a technical parameter.

## 4. Conformance, validation and testing

1. **Validation against the profile in CI**, with the official FHIR validator and your IG's package.
   **A resource that does not validate is not published.** It is the cheapest gate and the one that saves the most.
2. **Terminology validation against a real terminology server**, not against an embedded
   list: `$validate-code` over the `ValueSet` with the declared edition version.
3. **`CapabilityStatement` generated from the code and compared with the declared one** — the drift
   between the two is the classic silent defect.
4. **Conformance testing with the domain's public suites**: Touchstone (HL7), Inferno (US
   Realm), and the authority's battery if one exists. They are slow and they are what counts before a third party.
5. **Mandatory negative tests, and here they are not "edges":** missing unit, unknown code,
   date in the future, unexpected `status`, broken reference, patient without an identifier from the
   expected authority, a corrected result arriving **before** the original (yes, it happens),
   duplicate from a retry. **Each of these is potential harm, not a 500.**
6. **Synthetic test data, always.** Copying production to pre-production with real medical
   records is a special-category data breach the moment it is done, not if it leaks
   (a `privacy-engineering-standards` rule, here with no possible exception).
7. **Test the v2 ↔ FHIR translation with real anonymised messages from each sender**, not with the
   standard's example: `Z-segments` and local tables only show up there.

## 5. Security and privacy of clinical data

### 5.1 SMART on FHIR

- **Clinical and patient apps are authorised with SMART App Launch** (OAuth 2.0), not with an API key
  nor with a shared session. Two flows: **EHR launch** (the app opens from the record with
  patient and encounter context) and **standalone launch** (the patient logs in directly).
- **Scopes with real least privilege**: `patient/Observation.rs` instead of `patient/*.rs`, and
  `system/*` only for *backend services*, which is the one that does the most damage if leaked. **The scope
  syntax changed between SMART v1 and v2** (verbatim in §2): a client written against v1 requests
  permissions that a v2 server interprets differently.
- **The launch context is not authorisation.** The app receiving `patient=123` does not mean
  the server should serve anything belonging to 123: **authorisation is checked on the server,
  on every request**. It is the clinical variant of the IDOR/BOLA of `appsec-standards`, and here the object
  is a person's medical record.
- The IdP, the MFA policy, refresh rotation and revocation belong to
  `identity-access-management-standards`. **The particularity here: the professional attending
  an emergency cannot be locked out by a second factor being down** — emergency access
  (*break-glass*) exists, it is a clinical decision, and **its use is audited with mandatory
  subsequent review**, it is not avoided.

### 5.2 Consent

- **Consent is a queryable state, not a checkbox on a form.** It is modelled
  (`Consent`), it has validity, scope (which categories, which recipients, which purpose) and
  revocation, and **the access engine consults it on every decision**.
- **Consent to treatment ≠ GDPR lawful basis ≠ consent for secondary
  use.** They are three different things that the same button usually mixes up. The lawful basis is
  set by the DPO (§5.4); **the system has to be able to represent all three separately**.
- Revocation **has to propagate** to copies, replicas, indexes and third parties. If you cannot
  enumerate them, you cannot comply with it.

### 5.3 Pseudonymisation — and why it is more fragile here

A medical record is **extraordinarily re-identifiable**: a combination of a rare
diagnosis, postcode, sex and date of birth identifies a person with no need for the name.
Consequences:

- **Removing the name and the ID number anonymises nothing.** It is pseudonymisation, and the result **is
  still special-category personal data** under the GDPR.
- For secondary use, the technique and its threshold belong to `privacy-engineering-standards`;
  **from here the hard warning**: any claim of "anonymised" over a clinical dataset
  requires a re-identification risk analysis with the real cohort, not with theory.
- **Free-text notes are the worst vector**: they contain names, family relationships and
  addresses that no column-based process removes.

### 5.4 Health data is a special category — the text that says so

**GDPR, Art. 9(1), verbatim** (verified): *"Processing of personal data revealing racial or ethnic
origin, political opinions, religious or philosophical beliefs, or trade union membership, and the
processing of genetic data, biometric data for the purpose of uniquely identifying a natural person,
data concerning health or data concerning a natural person's sex life or sexual orientation shall be
prohibited."*

What it decides in engineering:
- **Processing starts from PROHIBITED** and is only lawful if it fits one of the exceptions in
  Art. 9(2) — among them **(h)** preventive or occupational medicine, medical diagnosis,
  the provision of care or the management of health systems and services, and **(i)** public interest
  in the area of public health. **Which one applies is decided by the DPO/legal, not by engineering**, but
  **the design has to be compatible with the one invoked**: Art. 9(2)(h) additionally requires
  processing by a professional subject to professional secrecy or under their responsibility.
- **Explicit consent (Art. 9(2)(a)) is rarely the correct basis in care delivery** and using it
  by default creates the trap that its withdrawal would force erasing what must legally be
  retained (§3.4).
- **HIPAA does not apply in Spain or in the EU.** It is US legislation and only binds *covered
  entities* (health plans, clearinghouses, providers that transmit electronically)
  and their *business associates*. **Citing it in a European project is a sign that the regulatory
  analysis has not been done** — and conversely: in a product sold in the US, the GDPR does not
  replace it. If you sell in both, you comply with both, and the design is done against the stricter
  requirement.

### 5.5 Access auditing — a requirement, not an *extra*

**Recording who has seen which record and when is a functional requirement of the product**, with
its user story, its tests and its query interface. It is not "logging".

- **Read access is recorded**, not just writes. The typical harm in healthcare is a
  professional looking at the record of a celebrity, a neighbour or an ex-partner: without read
  logging, it is undetectable.
- Model: **`AuditEvent`** (FHIR) or **IHE ATNA**; with who (a real identity, not a shared account),
  which resource, which patient, when, from where and with what declared purpose.
- **Retention in line with the legal obligation, integrity protected and access to the log restricted**
  and itself audited.
- **It is exploited, not just stored**: alerts for access to a patient with no active care
  relationship, for anomalous volume, for out-of-shift access. A log nobody looks at has prevented nothing.
- **Shared accounts: FORBIDDEN**, without exception. They break everything above and they are endemic in
  hospital environments; the correct answer is *single sign-on* with a card or *fast user
  switching*, not tolerating `nursing01`.

## 6. Performance and operability

- **A hospital has no downtime window.** 24×7 is real: the deployment is progressive, with
  backwards compatibility in the interfaces and coordination with clinical operations. A
  10-minute outage in a prescribing system is a patient safety event.
- **Documented degraded mode**: what happens when the FHIR server, the terminology server or the MPI goes down.
  Almost always the correct answer is **to reject clearly**, not to serve incomplete data: a
  result with no unit is worse than a visible error.
- **Latency with clinical judgement**: the query a doctor makes with the patient in front of them has a
  budget of seconds; the bulk `$export` does not compete with it (separate queues).
- **Bulk Data (`$export`, NDJSON)** for secondary use and analytics: **asynchronous, with
  `Content-Location` and polling**, never over the interactive API.
- **Change notification**: `Subscription` (in R4, with the known limitations; in R5,
  *topic-based*). A realistic and frequent alternative: the existing v2 bus. **What is not acceptable is
  *polling* the entire record**.
- **Idempotency on ingestion**: integration engines retry. A duplicated `ORU` that creates
  two observations is a clinical error; it is solved with `If-None-Exist`, a business identifier or
  a deduplication key, decided explicitly.
- **Clock and time zone**: clinical instants always with an offset (`instant`/`dateTime` with
  a zone). A medication administration time without a zone is ambiguous, and at a daylight-saving change the
  ambiguity is a full hour.
- **End-to-end traceability between v2 and FHIR**: the message control identifier
  (`MSH-10`) must be correlatable with the resulting resource. Without that, a clinical incident cannot
  be investigated.

## 7. Regulatory regime and prohibitions

### 7.1 When your software is a medical device

**It is not decided by marketing or by architecture: it is decided by the intended purpose you declare.**
If the software has a medical purpose (diagnosis, prevention, monitoring, prediction,
prognosis, treatment or alleviation of a disease) it is a medical device under **Regulation (EU)
2017/745 (MDR)**; if its purpose is to provide information from *in vitro* samples, under the
**Regulation (EU) 2017/746 (IVDR)**.

**Rule 11 of Annex VIII of the MDR** is the software-specific classification rule and **it is
the one that surprises everybody**: in substance, software intended to provide information
used to take decisions for diagnostic or therapeutic purposes is **class IIa**, unless those
decisions may cause death or an irreversible deterioration of health (**class III**) or
a serious deterioration or a surgical intervention (**class IIb**); software for monitoring
physiological processes moves up a class if the monitored parameters may create an immediate danger.

- **Practical consequence: rule 11 takes almost all clinical software out of class I**, which is
  the only self-certifiable one. Outside class I there is a **notified body**, and that means timescales of
  months or years and a budget that is not an engineering one.
- **Verification warning, and it is important: the text of rule 11 could NOT be quoted verbatim
  here** — `health.ec.europa.eu` returned **403** and the consolidated MDR text on EUR-Lex is
  truncated by size. The above is a **paraphrase from concurring secondary sources**.
  **Before classifying anything, read rule 11 on EUR-Lex and the MDCG 2019-11 guidance at its source**
  (§8). In a regulatory dossier, paraphrasing the classification rule is unacceptable.
- **There is a reform under discussion** that would rewrite rule 11 lowering classes: **not verified,
  do not plan against it** (§8).
- **Once classified, the whole process —IEC 62304, ISO 14971, evidence for the notified
  body— belongs to `safety-critical-standards`.**

### 7.2 EHDS — the European regulatory axis with dates

**Regulation (EU) 2025/327 of the European Parliament and of the Council of 11 February 2025 on
the European Health Data Space** (title verified on EUR-Lex). Published in the OJEU on
**5 March 2025**. It establishes obligations on **primary use** (patient access and
portability, priority categories such as the patient summary and electronic prescription/dispensation),
**requirements for electronic health record systems** (with their own conformity and
self-declaration regime, distinct from the medical device one) and **secondary use**
(health data access bodies, permits, secure processing environments).

**Dates — partially declared gap**: the final article on application **could not be
extracted verbatim from EUR-Lex** (the document is truncated). Secondary sources agree on:
entry into force **26 March 2025**, general application **26 March 2027**, the secondary
use chapter and the first priority categories **26 March 2029**, medical imaging, test results
and discharge reports **26 March 2031**. **Verify them in the final article of the official
text before putting them on a roadmap** (§8).

**What it decides today, regardless of the exact date**: if you are building an electronic health
record system for the European market, **its ability to export in the European exchange format
and its conformity regime are product requirements**, not a future feature. And
**MyHealth@EU** is the infrastructure over which cross-border patient summaries and electronic
prescriptions already circulate: aligning with IPS is not standards optionalism, it is the route.

### 7.3 AI in health software — accumulation of regimes

A medical device **with AI** accumulates: MDR/IVDR (with a notified body), the **AI Act** (a
medical device of a class requiring third-party assessment falls under the high risk of
Annex I), and the GDPR. **All the governance of the AI system —classification, provider/
deployer roles, human oversight, technical documentation, serious incidents— belongs to
`ai-governance-standards`**, and **the product safety process belongs to
`safety-critical-standards`**. From here only the architectural warning: **clinical training
data drags Art. 9 of the GDPR along with it, and the performance of a clinical model degrades
when the population changes** — the site and the validation cohort are part of the clinical contract.

### 7.4 Prohibitions

- ❌ **FORBIDDEN** to match patients with your own heuristic (name + date of birth) instead
  of the organisation's identity service (§3.5).
- ❌ **FORBIDDEN** to expose clinical data by reading the database or an SQL projection of the source
  system instead of going through the standard clinical interface. `mumps-standards` holds the same from
  the other side.
- ❌ Real patient data in development, test, demo or training environments (§4.6).
- ❌ Shared accounts in a system holding medical records (§5.5).
- ❌ Not logging **read** access to the medical record (§5.5).
- ❌ Physical `DELETE` of clinical information; it is voided with `entered-in-error` (§3.4).
- ❌ Sending a laboratory value without a code, without a unit or without a status (§1).
- ❌ Free text as an interoperability mechanism for something the receiver must act upon.
- ❌ Terminology codes **copied and frozen** into your schema instead of resolved against a
  terminology server with a declared version (§2, §4.2).
- ❌ Mixing the international edition and the national extension of SNOMED CT in a `ValueSet` without declaring
  the version (§2.2).
- ❌ Using SNOMED CT in a non-member territory without a valid MLDS licence (§2.2).
- ❌ Treating ICD-10/CIE-10 and SNOMED CT as interchangeable.
- ❌ FHIR extensions with an unpublished URL, or profiles that **extend** instead of constraining (§3.1).
- ❌ Replacing FHIR's REST contract with your own conventions (§3.3).
- ❌ Using `batch` where the case requires `transaction` (§3.3).
- ❌ Search without pagination against a clinical server.
- ❌ Citing **HIPAA** as the compliance framework of a European project, or the **GDPR** as a substitute
  for HIPAA in the US (§5.4).
- ❌ Claiming that a clinical dataset is "anonymised" without a re-identification analysis (§5.3).
- ❌ Declaring the medical device class **from memory or by analogy with a competitor**, without
  reading rule 11 and MDCG 2019-11 at source (§7.1).
- ❌ Announcing "we comply with EHDS" with dates not verified in the official text (§7.2).
- ❌ Planning the full replacement of HL7 v2 by FHIR as a project phase (§2.1).
- ❌ Putting **R6** into production or basing a contractual commitment on it before its publication (§2).

## 8. Mandatory web verification

Before committing anything in a real project, check on the web:

1. **The FHIR version and its status**, at `hl7.org/fhir/history.html` (verified here: **R4 = 4.0.1,
   2018-12-27, normative content; R5 = 5.0.0, 2023-03-26, *trial-use*, "None of the content in
   this specification is considered Normative"**) and the status of **R6** at `build.fhir.org`
   (verified: **v6.0.0-ballot4**, the first fully normative version **when it is published**).
   **Check whether R6 has already been published**: it is this domain's highest-impact pending change.
2. **The exact version of every IG you are going to use**, on its canonical page: **IPS
   `hl7.fhir.uv.ips#2.0.1`** (FHIR 4.0.1), **US Core `hl7.fhir.us.core#9.0.0`** (FHIR 4.0.1,
   2026-05-31), **SMART App Launch `hl7.fhir.uv.smart-app-launch#2.2.0`** (STU 2.2, 2023-03-01).
   All verified as of Aug 2026 and **all of them change on an annual or shorter cadence**.
3. **Spanish national guide**: **declared gap — no general FHIR IG for the
   HCDSNS has been located**. What is verified is the existence of sectoral IGs from the Ministry of Health (ÚNICAS,
   `unicas-fhir.sanidad.gob.es`, v0.0.6, over R5, aligned with MyHealth@EU NCPeH and IPS).
   **Consult the Ministry of Health, the competent autonomous community and HL7 Spain before
   committing to a profile in a tender.**
4. **SNOMED CT**: membership status of **your deployment territory** and that of your customers at
   `snomed.org/members` (**Spain appears as a member as of Aug 2026**), conditions verified
   verbatim at `snomed.org/get-snomed`, and the **edition version** (international + national
   extension) you are going to pin. Registration with the corresponding NRC.
5. **Rule 11 of Annex VIII of the MDR, on EUR-Lex, and the MDCG 2019-11 guidance at its official source.**
   **Declared gap**: it could not be quoted verbatim here — `health.ec.europa.eu` returned **403**
   and the consolidated MDR on EUR-Lex is truncated by size. **And check the status of the reform
   of the software classification**, which as of Aug 2026 is under discussion and not published.
6. **EHDS — Regulation (EU) 2025/327**: **partial declared gap**. Title and date of adoption
   (11-02-2025) and publication in the OJEU (05-03-2025) verified; **the final article on entry into
   force and application was NOT extracted verbatim** (EUR-Lex truncates the document) and secondary
   sources disagree with each other on the exact date of entry into force. **Read it in the official
   text before putting a date on a roadmap or in a bid.**
7. **GDPR Art. 9**: the enumeration of special categories is **verified verbatim** here
   (§5.4). The **specific lawful basis** that applies to your processing is set by the DPO, and its
   national implementation (in Spain, LOPDGDD and the health regulations on retention of the medical
   record) must be verified with `privacy-engineering-standards`.
8. **Conformance status of the FHIR server or of the vendor**: their real `CapabilityStatement`, not
   their brochure; and which FHIR version and which IGs they support **for real**.
9. **CVEs and advisories** for the FHIR server, the integration engine (Mirth/NextGen Connect, Rhapsody,
   Iguana), the PACS/DICOM and the terminology server. **The health sector is a preferred
   ransomware target**: coordinate with `vulnerability-management-standards` and `bcdr-standards`.
10. **The status of `mumps-standards` and `safety-critical-standards`** as reciprocal boundaries: the
    first delegates all clinical interoperability criteria here; the second owns
    IEC 62304 and ISO 14971 once the software is classified as a medical device.

If the web contradicts this document, **the web wins** — flag the discrepancy.
