---
name: govtech-eidas-standards
description: European e-government engineering — electronic identity, trust services and administrative procedure. Use when working with eIDAS Regulation (EU) No 910/2014 and its amendment Regulation (EU) 2024/1183, the European Digital Identity Wallet (EUDI Wallet) and its Architecture and Reference Framework, eID assurance levels low/substantial/high and the eIDAS node, qualified trust service providers and EU/national trusted lists (TSL, Commission Implementing Decision (EU) 2015/1505, the LOTL), advanced versus qualified electronic signatures (QES) and their legal effect, electronic seals, qualified electronic time stamps, qualified electronic registered delivery, QSCD and remote signing, signature formats XAdES, CAdES, PAdES and ASiC with baseline levels B, T, LT and LTA (Commission Implementing Decision (EU) 2015/1506, ETSI TS 103171/103172/103173/103174), signature validation with DSS or a validation service, long-term preservation and evidence renewal, Spanish e-government infrastructure (Cl@ve and the Cl@ve app, certificado FNMT, DNIe, @firma, AutoFirma, VALIDe, Notific@, Cl@ve Firma, SIA, DIR3), Ley 39/2015 and Ley 40/2015 identification and signature systems, the Esquema Nacional de Seguridad (Real Decreto 311/2022) and its básica/media/alta categories and CCN-STIC guidance, the Esquema Nacional de Interoperabilidad and public sector open data reuse, or a public procurement pliego that constrains the architecture of a public-sector system.
---

# European e-government standards (eIDAS)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when the software **produces, consumes or holds custody of an administrative act or a
document with legal effect**: identifying a citizen before an administration, signing
electronically, registering an application, giving legally effective notice, time-stamping, and
**preserving all of that for decades in a way that remains verifiable**.

**Domain thesis: signing is the easy problem; the real problem is preservation.** Signing is a
thirty-line operation. The hard part is that in **twenty years** someone can prove that the document
was signed, with which certificate, that the certificate was valid **at that moment**, that the CA
existed and was on the trusted list, and that the algorithm has not been broken along the way.
Almost every e-government project is designed around the act of signing and discovers the longevity
problem when the first certificate expires (§6). Corollary that changes the design from day one:
**a signature without a qualified time stamp and without embedded validation material expires with
the certificate**, and the proof expires with it.

**Second thesis, and it is an engineering constraint even if it does not look like one: in the public
sector, the architecture is set by the tender specification.** What is not in the tender specification is
not built, not invoiced and not maintained. A non-functional requirement that does not appear in the award
criteria —observability, testing, data migration, exit plan— does not exist for the project (§7.1).

Covers: electronic identity and assurance levels; the European wallet; trust services and trusted
lists; signature types and their evidential value; formats and longevity levels; long-term
preservation; the concrete Spanish infrastructure; and the procurement, accessibility and
interoperability constraints of the public sector.

**Not applicable**:
- `identity-access-management-standards` (**main boundary**): **OAuth 2.1/OIDC, SAML, the IdP
  as a product, passkeys/WebAuthn, SCIM, RBAC/ABAC/ReBAC, session and technical federation are
  theirs**. **From here: which identity has legal value before an administration and with which
  assurance level** —the eIDAS low/substantial/high levels are not an MFA scale, they are a
  regulatory qualification of a notified scheme—, the eIDAS node and the European wallet. Arbitration
  rule: *"how do I authenticate the user in my application?" is theirs; "does this means of
  identification make the act valid and get it recognised by another Member State?" is
  from here*.
- `cryptography-pki-standards` (**main boundary**): **algorithms, curves, key sizes,
  TLS, CA hierarchy, ACME, HSM/KMS and the certificate lifecycle as cryptography are
  theirs**. **From here: what makes a PKI *qualified* under eIDAS and which legal obligations
  that brings** —QTSP, QSCD, trusted lists, evidential value—, which is not a cryptographic property
  but a supervisory one. Reciprocal warning: the **post-quantum migration** of these signatures
  belongs to `post-quantum-crypto-standards`, **and it directly affects long-term preservation**
  (§6.3).
- `grc-compliance-standards` (**boundary declared on both sides**): **the ENS as a management
  framework, its Statement of Applicability, the certification audit, the risk register and
  the relationship with the CCN are theirs** —it already cites RD 311/2022—. **From here: what the
  ENS forces on the architecture of a specific electronic service** (§2.5) and its relationship with
  the rest of this document.
- `accessibility-standards`: **all the technical conformance criteria are theirs** —WCAG 2.x, EN 301
  549, RD 1112/2018, the accessibility statement, how it is tested and who signs it—. **From here only
  the fact that decides priority: in the public sector it is a legal obligation, not an improvement** (§7.2).
- `privacy-engineering-standards` (personal data, minimisation, DPIA, rights, retention — **and the
  real clash with the obligation to preserve the case file**, §6.1),
  `api-design-standards` (service contracts), `data-governance-quality-standards` (data ownership and
  quality), `ai-governance-standards` (AI Act — **an administration that automates
  decisions is a high-risk deployer, and that is theirs**),
  `appsec-standards` and `vulnerability-management-standards`,
  `web-app-servers-standards` and `frontend-web-platform-standards` (the electronic office as a web
  application), `bcdr-standards` and `backup-recovery-standards`,
  `enterprise-architecture-standards` and `project-management-standards` (**programme portfolio and
  governance**; here only procurement insofar as it constrains the architecture),
  `opensource-licensing-standards` (reuse of public software and its licence),
  `healthtech-fhir-standards` (**sister**: the cross-border ePrescription and patient summary
  are theirs as clinical data; **the signature, the seal and the identity with which they
  travel, from here**), `offensive-security-standards` (**this skill is defensive**).

## 2. Default decisions

> Verify the consolidated text and the dates on the web before pinning them in a real project (§8).

### 2.1 Regulatory framework

| Piece | What it is | Verified as of Aug 2026 |
|---|---|---|
| **Regulation (EU) No 910/2014 (eIDAS)** | Electronic identification and trust services in the internal market | In force; **amended by Regulation (EU) 2024/1183** |
| **Regulation (EU) 2024/1183 ("eIDAS 2")** | Introduces the **European digital identity framework** and the **wallet (EUDI Wallet)** | Published in the OJEU on **30-04-2024**; entry into force cited as **20-05-2024** — *secondary sources disagree (one gives 30-05-2024)*: **verify it in the final article of the official text** (§8) |
| **Commission Implementing Decision (EU) 2015/1505** | Technical specifications for the **trusted lists** (art. 22.5) | Title verified verbatim (§2.4) |
| **Commission Implementing Decision (EU) 2015/1506** | Advanced signature and seal formats **that public sector bodies must recognise** | Title and arts. 1-2 verified verbatim (§2.3) |
| **Ley 39/2015** (common administrative procedure) | Identification (art. 9) and signature (art. 10) of the interested party, register, notification | Consolidated in the BOE |
| **Ley 40/2015** (legal regime of the public sector) | Electronic office, body seal, automated administrative action, archive | Consolidated in the BOE |
| **Real Decreto 311/2022 (ENS)** | *"Real Decreto 311/2022, de 3 de mayo, por el que se regula el Esquema Nacional de Seguridad"* (verbatim title, BOE) | **BÁSICA / MEDIA / ALTA categories** (art. 40 and annex I). The consolidated BOE text shows a **later amendment**: verify it (§8) |
| **Ley 6/2020** (electronic trust services) | Spanish implementation of eIDAS | Verify whether it is in force and any amendments (§8) |

### 2.2 Electronic signature: the three levels and their evidential value

The three levels are not "more or less secure": **they are different legal categories**.

| Level | What it is | Value |
|---|---|---|
| **Simple** | Data in electronic form used by the signatory to sign (a click, a name at the bottom) | Legal effect cannot be denied **solely** because it is electronic |
| **Advanced (AdES)** | Uniquely linked to the signatory, allows identifying them, created with data under their sole control and detects any subsequent change | It is the level administrations normally **require**; its cross-border recognition goes through 2015/1506 (§2.3) |
| **Qualified (QES)** | Advanced **+ qualified signature creation device (QSCD) + qualified certificate** from a supervised QTSP | **Equivalence with the handwritten signature**, §2.2.1 |

**2.2.1 — The text that decides, verbatim** (Regulation (EU) No 910/2014, **art. 25**, verified in
EUR-Lex):

> *"1. An electronic signature shall not be denied legal effect and admissibility as evidence in
> legal proceedings solely on the grounds that it is in an electronic form or that it does not meet
> the requirements for qualified electronic signatures.*
> *2. A qualified electronic signature shall have the equivalent legal effect of a handwritten
> signature.*
> *3. A qualified electronic signature based on a qualified certificate issued in one Member State
> shall be recognised as a qualified electronic signature in all other Member States."*

What this decides in engineering terms:
- **Art. 25.1 does not say that a simple signature is worth the same**: it says that effect cannot
  be denied **for the sole reason** of being electronic. Its evidential weight in litigation has to
  be proven with evidence — and that evidence has to have been kept (§4.3).
- **Art. 25.3 is what makes the internal market possible**: a Spanish QES is valid in Germany
  **with no bilateral agreement**. What holds it up technically are the trusted lists (§2.4).
- **QES is not "a signature with a certificate"**: it requires a **QSCD**. A qualified certificate in
  software, in a `.p12` file on disk, **does not produce a QES**. Confusing this is the costliest
  mistake in this domain, and it is inherited by the tender specifications.
- **Electronic seal** (organisation, not person) and **qualified time stamp** have their
  own articles with specific presumptions — **not verified verbatim here: declared gap**
  (§8). Do not cite them from memory in a legal report.
- **The signature does not evidence intent, it evidences integrity and the signatory.** What was signed,
  what the signatory saw on screen and under which legal text, is a design decision of the procedure (§3.2).

### 2.3 Formats and longevity levels — the verbatim text

**Commission Implementing Decision (EU) 2015/1506**, verified title: *"Commission Implementing Decision (EU)
2015/1506 of 8 September 2015 laying down specifications relating to formats of advanced electronic
signatures and advanced seals to be recognised by public sector bodies pursuant to Articles 27(5)
and 37(5) of Regulation (EU) No 910/2014"*. **Article 1, verbatim:**

> *"Member States requiring an advanced electronic signature or an advanced electronic signature
> based on a qualified certificate as provided for in Article 27(1) and (2) of Regulation (EU) No
> 910/2014, shall recognise XML, CMS or PDF advanced electronic signature at conformance level B, T
> or LT level or using an associated signature container, where those signatures comply with the
> technical specifications listed in the Annex."*

And the annex specifications, exactly as they appear: **XAdES → ETSI TS 103171 v.2.1.1**, **CAdES →
ETSI TS 103173 v.2.2.1**, **PAdES → ETSI TS 103172 v.2.2.2**, **ASiC (container) → ETSI TS 103174
v.2.2.1**.

| Format | Wraps | Use it when |
|---|---|---|
| **XAdES** | XML | The document **is** XML (electronic invoice, register entry, structured exchange) |
| **CAdES** | CMS/binary | Any binary file; detached signature (*detached*) |
| **PAdES** | PDF | The document is read as a PDF and the signature must travel inside it and be verifiable by a standard reader |
| **ASiC** | Container (ZIP) | Several files + their signatures as a unit. **The default choice for a case file** |

**Longevity levels — the axis of this whole document:**

| Level | What it adds | Consequence |
|---|---|---|
| **B** (*baseline*) | The signature and its minimum attributes | **Expires with the certificate.** Good for the moment, not for the archive |
| **T** | **Time stamp** over the signature | Proves **when** it was signed. Without this you cannot prove the certificate was valid |
| **LT** | Embeds the **validation material** (certificate chain, CRL/OCSP of the moment) | The signature validates **without depending on the CA still being alive or publishing revocation** |
| **LTA** | Archive time stamps **chained and renewable** | The only level that survives **algorithm obsolescence** (§6.3) |

**A fact that surprises people and has to be said: the recognition obligation of art. 1 of 2015/1506
covers levels B, T and LT — LTA does not appear in that enumeration.** That is: **the level you
really need for preservation is not the one the Decision obliges recognition of.** Operational
consequence: **you sign at least at T to produce, at LT to deliver, and you preserve at LTA** (§6), and
do not confuse "what has to be recognised" with "what has to be archived".

### 2.4 Trusted lists (TSL) — the mechanism that makes all of this work

**Commission Implementing Decision (EU) 2015/1505**, title and articles verified verbatim in EUR-Lex.
**Article 1:**

> *"Member States shall establish, publish and maintain trusted lists including information on the
> qualified trust service providers which they supervise, as well as information on the qualified
> trust services provided by them. Those lists shall comply with the technical specifications set
> out in Annex I."*

**Article 2:** Member States *"may include in the trusted lists information on non-qualified
trust service providers"*, and the list *"shall clearly indicate which trust service providers and the
trust services provided by them are not qualified."*
**Article 3:** Member States *"shall sign or seal electronically the form suitable for
automated processing of their trusted list"*, and the human-readable version, if published, *"contains
the same data as the form suitable for automated processing"* and is also signed or sealed.

**Why this is the heart of the system, and not a footnote:**
- **Trust is not cryptographic, it is supervisory.** A signature is valid not because the
  maths works out, but because the issuer of the certificate was **on the trusted list of the
  State supervising it, at the moment of signing**.
- Above the national lists there is a **list of lists (LOTL)** signed by the Commission. Your
  validator has to start from there, not from a root CA store copied by hand.
- **The list has history and states**: a provider may be `granted`, `withdrawn` or may have
  ceased. **Validating an eight-year-old signature "as of today" is a validation error**: it is
  validated against the state of the list **at the date of the time stamp**.
- **FORBIDDEN** to keep your own trusted certificate store for this (§7.3): the
  moment a provider is withdrawn from the list, your store lies.

### 2.5 Spain — the concrete infrastructure

| Piece | What it is | Criteria |
|---|---|---|
| **Cl@ve** | Unified identification system of the AGE and of the regions that have joined | It has been reorganised around the **Cl@ve app** and **Cl@ve Móvil** (authentication by QR or confirmation in the app), with **PIN by SMS** as an alternative; **Cl@ve Permanente** and registration by **video identification** coexist. **Verify the exact state and which method is still alive at `clave.gob.es`: it changes, and here there are only secondary sources — declared gap** (§8) |
| **FNMT certificate** | Natural/legal person certificate from the FNMT-RCM | The most widespread; **software by default → does not produce QES** except on a card/qualified device (§2.2) |
| **DNIe** | Certificate on the DNI chip | It is the clear case of a **qualified device**; its real friction is the reader and the *drivers* |
| **@firma** | Signature and certificate validation platform of the AGE | **Use it instead of writing your own validator** (§4.1) |
| **AutoFirma** | Desktop signing client | It is what the citizen has installed; its friction (Java, browser, `afirma://` protocol) is a real cause of procedure abandonment |
| **VALIDe** | Public service for signature validation and viewing | Manual and support checking |
| **European Digital Wallet** | The EUDI Wallet applied in Spain | **It does not replace Cl@ve/FNMT/DNIe: it adds to them.** Design for coexistence, not for migration |
| **ENS (RD 311/2022)** | **BÁSICA / MEDIA / ALTA** categories according to the impact on availability, authenticity, integrity, confidentiality and traceability | **The category is determined before designing**, because it changes mandatory measures. The **CCN-STIC** guides are the technical landing. The management framework and certification belong to `grc-compliance-standards` |

**The European wallet (EUDI Wallet) — the fact most often stated wrongly.** What is verified: art. 5a
of Regulation (EU) 2024/1183 establishes that *"each Member State shall provide at least one European
Digital Identity Wallet within 24 months of the date of entry into force of the implementing acts"*,
and that *"By 21 November 2024, the Commission shall, by means of implementing acts, establish a list
of reference standards"*. **That is where the deadline everybody quotes as "end of 2026" comes from — and
it is a derived date, not a date written in the Regulation.** Do not put it in a bid without
checking the text and the real date of entry into force of the implementing acts (§8). What you can
pin today: **if you build a public service, you have to be able to accept the wallet in addition
to what already exists**, and that is an identity architecture decision, not an `if`.

## 3. Structure of an electronic procedure

### 3.1 The full chain, and where it breaks

```
Identification (assurance level required by the procedure)
  → Presentation of the content to be signed (what the citizen actually sees)
    → Signature (required level: advanced or qualified)
      → Qualified time stamp
        → Inbound register (entry with authoritative number, date and time)
          → Receipt for the citizen (with the same evidential value)
            → Processing (with body seal on automated actions)
              → Legally effective notification (with acknowledgement and deadline computation)
                → Electronic archive (LTA, with a preservation plan) ← almost everything dies here
```

Hard rules:
1. **The required assurance level is set by the procedure**, not by the developer's convenience, and it
   must be justifiable. Requiring a qualified certificate to check the status of a case file is
   an access barrier; accepting low identification for a waiver of rights is a defect.
2. **The submission receipt is the product**, not a courtesy email: it is what the
   citizen will use to prove they filed on time. It carries the administration's signature or seal and
   a time stamp.
3. **Administrative deadlines are critical business logic**: working days, national, regional and
   local holidays, and the criterion for computing the notification. It is the most frequent source of
   errors and the one that produces defencelessness.
4. **The electronic office has its own requirements** (identification of the office, seal, publication
   of services, accessibility) which are not those of a corporate website.
5. **Automated administrative action**: if the act is produced by the system without human
   intervention, it has to have been provided for and sealed with a **body seal**, with the responsible
   body defined and published. An automatic process that issues decisions without that cover produces
   voidable acts.

### 3.2 What is signed, exactly

- **You sign the document, not the form.** A stable, viewable representation of the content is
  generated (normally PDF/A), shown, and **that** is what is signed. Signing a JSON that
  the citizen never saw evidences nothing useful.
- **WYSIWYS** (*what you see is what you sign*): if the document contains dynamic elements
  —JavaScript in the PDF, remote content, non-embedded fonts— what is seen may not be what
  was signed. **PDF/A and everything embedded**, without exception.
- **What was displayed is preserved**, together with the signature and its evidence.
- **Multiple signature**: decide explicitly whether it is **parallel** (several sign the same thing,
  independently) or **cascaded/countersignature** (each one signs the previous signature). Changing
  criteria halfway breaks validation.

### 3.3 Evidence — what is kept besides the signed document

The signed document **is not enough** as proof. Kept alongside it and inseparably from it:
qualified time stamp, full certificate chain, **OCSP or CRL responses from the moment of
signing**, the state of the applicable trusted list, the signature policy if one was declared, and
the validation report generated at the moment of acceptance. **This is exactly what the LT level
incorporates inside the signature itself** — which is why LT is not a luxury, it is what avoids having to
reconstruct the proof by hand ten years from now.

## 4. Validation and testing

### 4.1 Validating

- **Do not write your own validator.** Use **DSS** (the Commission's reference library),
  the administration's validation service (**@firma** / **VALIDe** in Spain) or a qualified
  validation service. A homegrown validator is where false "valid" results hide.
- **Validation starts from the LOTL**, not from your own root store (§2.4).
- **You validate against the instant of the time stamp**, not against "now".
- **The validation result is stored** with the case file: in the future it may not be
  reproducible.
- **A result is not a boolean.** Distinguish `TOTAL-PASSED`, `INDETERMINATE` and `TOTAL-FAILED`, and
  **decide what the procedure does with `INDETERMINATE`** (which is what a signature whose revocation
  material cannot be obtained returns). Treating indeterminate as valid is the most common failure.

### 4.2 Testing — the negative catalogue, which here is the main catalogue

Every one of these cases has to exist as an automated test:
**expired** certificate; certificate **revoked before** signing; certificate revoked **after**
signing (it must remain valid if there is a prior time stamp); **CA withdrawn** from the trusted
list; document **modified by one byte** after signing; signature with an obsolete algorithm; **incomplete
chain**; **OCSP unavailable**; time stamp missing; **foreign signature** from another Member
State (art. 25.3); PDF with dynamic content; ASiC with more files than were signed; and
**archive stamp renewal** in an LTA. Without this catalogue, the system "works" and proves
nothing.

### 4.3 Longevity test

**Rehearse the ten-years-from-now scenario, today**: take a signed document, move the clock of the
test environment past the expiry of the certificate and of the CA, and **validate**. If it fails,
your electronic archive is not an archive, it is a folder. It is the test nobody runs and the one that
shows whether the design of §6 really exists.

## 5. Security

- **The administration's signing keys (body seal, office seal, time stamping) in an
  HSM**, never in a file. Their lifecycle, custody and rotation belong to
  `cryptography-pki-standards`; **from here the requirement that the signing operation be
  authorised, logged and attributable to a specific procedure**.
- **Server-side (remote) signing concentrates the risk**: a badly authorised signing API signs
  anything on behalf of anyone. Per-transaction authorisation, with the content to be signed
  bound to the authorisation (not "permission to sign", but "permission to sign *this*").
- **Identity enrolment and video identification**: the most attacked point of the system is not
  the cryptography, it is **enrolment**. Impersonation with a forged document, video *deepfake*
  and presentation attacks. The assurance level of the scheme depends on this, not on the
  authentication protocol.
- **The electronic office is a target**: spoofing the office to capture credentials and
  signatures is a direct attack on the citizen. Office certificate, domain under control with DNSSEC
  where possible, HSTS, and **clear communication to the citizen of which is the legitimate office**.
- **ENS**: the category determines mandatory measures; **it is decided at the start of the design**,
  because it affects architecture (segregation, traceability, encryption, continuity) and it cannot
  be added at the end. The **CCN-STIC** guides are the concrete landing.
- **Traceability as an ENS requirement**: who accessed which case file and when, with integrity
  protected and retention defined. It is a functional requirement with its tests, not *logging*.

## 6. Long-term preservation — the real problem

### 6.1 The conflict that has to be named

The administrative case file has a **legal preservation obligation** for long periods, and the
GDPR right to erasure **does not automatically override it**. That conflict is resolved by design
(what is preserved, on what legal basis, what can be dissociated), and **the decision belongs to
`privacy-engineering-standards` and the DPO**. What this skill requires: **that the system can
distinguish "preserved by legal obligation" from "preserved because nobody deleted it"** and be able to
enumerate where each copy lives.

### 6.2 How preservation really works

1. **Signature at LTA** from the archive onwards, with **chained** archive time stamps.
2. **Scheduled renewal** of the archive stamp **before** the algorithm or the stamper's certificate
   weaken. This is an **operational process with a schedule and an owner**, not a
   property of the format: an LTA that nobody renews degrades just the same.
3. **Stable document format**: **PDF/A** with everything embedded; XML with its schema preserved
   alongside the document (an XML whose XSD disappeared is text).
4. **Container and case file metadata**: ASiC or another container, with archival metadata
   (identifier, body, date, document type, preservation policy) according to the **Esquema
   Nacional de Interoperabilidad** and its technical standards.
5. **Planned media and format migration**, with the evidence that the migration preserved
   integrity — the migration is itself an act that has to be provable.
6. **Periodic restore and validation testing** of the archive (§4.3). An archive that has not been
   validated is not known to exist.

### 6.3 Cryptographic obsolescence, and post-quantum

**Every signature ages because the algorithm ages.** The only mechanism that solves it is
**re-stamping the whole set (document + signatures + evidence) with a current algorithm before the
previous one breaks** — which is exactly what LTA exists for. And here comes the warning that has to
be put in writing today: **the post-quantum transition affects already-signed archives, not only
new ones**. A document signed with RSA/ECDSA and preserved for thirty years will need an archive
stamp with a resistant algorithm **before** the previous one stops being valid. **The schedule and the
choice of algorithm belong to `post-quantum-crypto-standards`; the obligation to have a re-stamping
plan is from here, and it has to be budgeted now.**

## 7. Public sector context and prohibitions

### 7.1 Public procurement as an architectural constraint

- **What is not in the tender specification is not done.** If observability, automated testing, data
  migration, architecture documentation, training and an **exit plan** are not requirements with their
  own scoring criterion, they will not be delivered. **The place where the quality of a public
  system is decided is the tender specification, not the sprint.**
- **Fixed scope clashes with incremental development.** A fixed-price, fixed-scope contract
  over two years turns any learning into a contract amendment. When you can choose:
  service- and capacity-based contracts, with small lots and verifiable deliverables.
- **Vendor lock-in** — the endemic pathology. Antidotes that are written into
  the tender specification, not afterwards: **ownership of the source code and of the data by the
  administration**, open formats and protocols, delivery of the architecture and deployment
  documentation as a deliverable, **environment reproducible from the repository**, and **exit test executed during
  the contract**, not described in an annex.
- **Reuse**: check before building whether a solution already exists in the catalogue of
  reusable public administration solutions. And publish yours; its licence is decided with
  `opensource-licensing-standards`.
- **Knowledge continuity is a requirement**: the contractor's team changes with each
  tender. Whatever is not in the repository and in the documentation is lost at every succession.

### 7.2 Accessibility and interoperability

- **Accessibility is a legal obligation in the public sector, and therefore a functional requirement with
  an acceptance criterion.** All the technical criteria —which WCAG criterion, how it is tested, the
  accessibility statement and its review— belong to **`accessibility-standards`**. **From here only the
  procurement consequence: if it is not in the tender specification with a scoring criterion, what will be
  delivered is a statement that does not match the site.** And the concrete warning from this domain: **the
  critical step of a procedure —the signature— is usually the least accessible** (applets, pop-up windows,
  timers, untagged PDFs).
- **Interoperability**: the **ENI** and its technical standards set the electronic document and case file,
  the signature policy, the standards catalogue and the data model for exchange. **The
  common identifiers (DIR3 for organisational units, SIA for procedures) are not bureaucracy:
  they are the foreign keys of the public sector** and without them exchange between administrations does
  not close.
- **Open data and reuse**: published data goes out in open and documented formats,
  with a clear licence and a **stable API**; and **anonymisation prior to publication
  is analysed seriously** (`privacy-engineering-standards`) — a badly anonymised public dataset
  cannot be withdrawn from the internet.

### 7.3 Prohibitions

- ❌ **FORBIDDEN** to call a signature with a software-file certificate a QES: without a **QSCD** there is no
  qualified signature (§2.2).
- ❌ **FORBIDDEN** to keep your own store of trusted CAs instead of the corresponding **LOTL / trusted
  list** (§2.4).
- ❌ Validating an old signature against **today's** trust state instead of that of the date of the
  time stamp (§4.1).
- ❌ Treating an `INDETERMINATE` validation result as valid (§4.1).
- ❌ Writing your own signature validator (§4.1).
- ❌ Signing at level **B** something that has to be preserved; archiving in anything other than **LTA** (§2.3, §6).
- ❌ An LTA **with no operational stamp renewal process**, with an owner and a schedule (§6.2).
- ❌ Signing content the citizen has not seen, or a PDF with dynamic content or non-embedded
  fonts (§3.2).
- ❌ Discarding the validation evidence after accepting the document (§3.3).
- ❌ Requiring an assurance or signature level higher than the procedure needs: it is an access
  barrier, and in the public sector that is exclusion.
- ❌ Issuing acts by automated procedure without the cover of **automated administrative
  action** and without a body seal (§3.1).
- ❌ Computing administrative deadlines with calendar days or without a complete holiday calendar (§3.1).
- ❌ Putting **European wallet dates** in a tender specification, a bid or a press release without
  having verified them in the official text and in the implementing acts (§2.5, §8).
- ❌ Claiming that the European wallet replaces Cl@ve, the FNMT certificate or the DNIe (§2.5).
- ❌ Delivering a public system without ownership of the code and the data, without a reproducible environment and
  without a tested exit plan (§7.1).
- ❌ Treating accessibility as a final phase or as a statement without a test (§7.2).
- ❌ Publishing open data without a re-identification analysis (§7.2).
- ❌ Citing an article of eIDAS, of Ley 39/2015 or of the ENS from memory in a document with legal
  effect. It is cited from the consolidated text (§8).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Consolidated text of Regulation (EU) No 910/2014 with the amendments of Regulation (EU)
   2024/1183**, in EUR-Lex. Verified verbatim here: full **art. 25** (legal effects of the
   signature) and **art. 8.1 and 8.2** (low, substantial and high assurance levels). **Declared gap: the
   articles on the legal effects of the electronic seal and of the qualified time stamp could NOT
   be extracted verbatim** —EUR-Lex truncates the consolidated document by size— **so they are
   not cited here. Read them before using them.**
2. **European wallet (EUDI Wallet) dates**: entry into force of Regulation (EU) 2024/1183
   —**published in the OJEU on 30-04-2024; secondary sources give 20-05-2024 and some 30-05-2024,
   and it has not been resolved verbatim: declared gap**— and, above all, **the real date of entry into
   force of the implementing acts of art. 5a**, which is what triggers the 24-month deadline. What is
   verified from art. 5a: *"within 24 months of the date of entry into force of the implementing
   acts"* and *"By 21 November 2024, the Commission shall, by means of implementing acts, establish a
   list of reference standards"*. **The "end of 2026" everybody repeats is a derived date.
   Check it.** Also check the state of the wallet's **Architecture and Reference Framework**
   and of the large-scale pilots.
3. **Implementing decisions 2015/1505 (trusted lists) and 2015/1506 (formats)**: verified
   verbatim here in their original version. **Check whether a consolidated version with
   amendments exists** —in particular whether the ETSI references in the annex of 2015/1506 (TS 103171
   v.2.1.1, TS 103172 v.2.2.2, TS 103173 v.2.2.1, TS 103174 v.2.2.1) have been updated to the
   **EN 319 122 / 319 132 / 319 142 / 319 162** standards. **The ENs have not been verified here:
   `etsi.org` returned 403 to automated access — declared gap.**
4. **List of lists (LOTL) and the trusted list of your country**, and **the specific provider** you are
   going to accept: its state (`granted` / `withdrawn`) and the qualified services it provides. It is checked
   in the list, never on the provider's commercial website.
5. **Spain**: consolidated text in the **BOE** of **Ley 39/2015** (arts. 9 and 10, admitted
   identification and signature systems), **Ley 40/2015**, **Ley 6/2020** and **Real Decreto
   311/2022** (*"Real Decreto 311/2022, de 3 de mayo, por el que se regula el Esquema Nacional de
   Seguridad"*, title verified). **Warning: the consolidated ENS text shows an amendment subsequent to
   its publication; the detail of that amendment has NOT been verified — declared gap.** And the
   **CCN-STIC guide** applicable to your category.
6. **State of Cl@ve**: which methods are still alive (Cl@ve app, Cl@ve Móvil, PIN by SMS, Cl@ve
   Permanente, video identification) and their notified assurance level, **at `clave.gob.es` and on the
   Administración Electrónica portal**. **Here there are only secondary sources: declared gap.**
   Also check the state of **@firma**, **AutoFirma**, **VALIDe** and their supported
   versions — **AutoFirma is a desktop dependency of the citizen and its compatibility with
   browsers and with Java changes**.
7. **State of the DSS library** and of your validation service: version, supported algorithms and
   security advisories.
8. **Post-quantum**: migration schedule and algorithms, with `post-quantum-crypto-standards`, and
   **their impact on the archive re-stamping plan** (§6.3).
9. **CVEs** of the signing platform, of the electronic office server, of the document manager and of the
   desktop client, with `vulnerability-management-standards`.
10. **ENI technical interoperability standards** in force (electronic document, electronic
    case file, signature policy, standards catalogue) and the **DIR3** and **SIA** catalogues.

If the web contradicts this document, **the web wins** — flag the discrepancy.
