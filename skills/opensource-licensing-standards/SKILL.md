---
name: opensource-licensing-standards
description: Use when a dependency's license is a hard engineering constraint — checking a LICENSE, COPYING, NOTICE or LICENSES/ file before adding a package, SPDX identifiers and expressions (MIT, BSD-3-Clause, Apache-2.0, Apache-2.0 WITH LLVM-exception, MPL-2.0, LGPL-3.0-only, GPL-2.0-only, GPL-3.0-or-later, AGPL-3.0-only, EPL-2.0, CDDL-1.0, CC-BY-NC-SA-4.0), source-available and fair-source terms (BUSL-1.1, Elastic License 2.0, SSPL-1.0, RSALv2, PolyForm Shield/Noncommercial, Functional Source License FSL, Fair Core License FCL, Monospace Sustainable Core License), a dependency that relicensed under you and the community fork that followed (Pekko, OpenTofu, OpenBao, Valkey, OpenSearch, Railroader), static versus dynamic linking and whether a SaaS distributes, AGPL network copyleft, Apache-2.0 patent grant and its GPL-2.0 incompatibility, dual licensing with a proprietary ee/ directory, an allowed/review/forbidden license policy and the CI gate that enforces it (dependency-review-action allow-licenses, cargo-deny deny.toml, go-licenses, pip-licenses, liccheck, license-checker, ORT, ScanCode Toolkit, FOSSology, Syft, Trivy), REUSE compliance and reuse lint, generating and consuming an SBOM in SPDX or CycloneDX, EU Cyber Resilience Act SBOM duties, a THIRD-PARTY-NOTICES attribution file, CLA versus DCO and Signed-off-by, or the license of a model, dataset or generated artifact.
---

# Open source licensing and compliance standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**The licence is an engineering constraint, and it is verified at the moment the dependency is
added — not when the customer turns up asking.** An incompatible licence discovered in a
two-year-old `git log` is not a legal finding: it is an **architectural debt** that is already
in production, in the customer's installer and in the image you signed. Checking it costs
seconds in the PR; discovering it in *due diligence* costs a redesign.

Operational corollary, and it is the entire thesis of this document: **the gate goes in the PR
that adds the dependency**. A quarterly scan of the whole tree produces reports; a gate in the PR
produces decisions. If you can only have one, have the gate.

**Scope notice — this is NOT legal advice.** What is here is engineering and compliance
criteria: what gets verified, what breaks the build, what gets recorded and who approves an
exception. **The interpretation of a clause, the assessment of contractual risk and any
decision with legal exposure are referred to qualified legal counsel** — notably: strong
copyleft entanglement in a distributed product, obligations under a vendor contract,
non-compete clauses of *source-available* licences, ownership of an employee's or contractor's
work, and any response to a compliance claim. This document says **when you have to ask a
lawyer**; it does not answer for one.

Covers: what is and is not open source (the OSI's OSD and the *source-available* /
*fair-source* debate); licence families and what they actually require; compatibility and the
direction of combinations; the distinctions that cause almost every mistake (static vs. dynamic
linking, distribution vs. internal use, container vs. binary, SaaS); **SPDX** as the canonical
identifier; **SBOM** and its real regulatory obligation; the **process**: policy, CI gate,
scanning, inventory, exceptions and attribution; what to do when a dependency
**relicenses**; contributing outwards (CLA vs. DCO); and the licence of models, datasets and
content.

Triggers: `LICENSE`, `LICENSE.md`, `LICENSE.txt`, `COPYING`, `NOTICE`, `LICENSES/`,
`REUSE.toml`, `.reuse/dep5`, `THIRD-PARTY-NOTICES`, `deny.toml`, `.licenserc`,
`dependency-review-action`, `allow-licenses`, `deny-licenses`, `cargo deny check licenses`,
`go-licenses`, `pip-licenses`, `liccheck`, `license-checker`, `reuse lint`, `scancode`,
`FOSSology`, ORT (`.ort.yml`, `evaluator.rules.kts`); SPDX identifiers (`MIT`,
`Apache-2.0`, `MPL-2.0`, `GPL-3.0-or-later`, `AGPL-3.0-only`, `LGPL-3.0-only`, `EPL-2.0`,
`CDDL-1.0`, `BSD-3-Clause`, `WITH LLVM-exception`, `LicenseRef-*`); SPDX expressions
(`AND`, `OR`, `WITH`); *source-available* (`BUSL-1.1`, ELv2, SSPL, RSALv2, PolyForm, FSL, FCL,
MSCL); `SPDX-License-Identifier:` in a file header; SBOM (`bom.json`, `*.spdx.json`,
CycloneDX, `syft`, `trivy sbom`); CRA; CLA, DCO, `Signed-off-by:`; relicensing, forking.

### This skill is the CROSS-CUTTING OWNER of the subject

**Every skill in the catalogue verifies the licence of the tools it pins** — and several have
done so and found surprises (§3.6). That is right and must continue. But **the licence policy,
the gate that enforces it and the exception process live HERE, and only here**. A language
skill decides *which linter to use*; it does **not** decide whether AGPL is acceptable in the
product. If another catalogue skill contradicts the policy of §5.1, **this one wins**.

> **Precedent that justifies the procedure in §6, verified in this series**: in **YottaDB** the
> file called `LICENSE` **does not contain the licence** —it is explanatory copyright text—; the
> real licence (**AGPLv3**) is in `COPYING`. And **GnuCOBOL** is GPLv3 in the compiler but
> **LGPLv3 in the runtime**, with the added trap that its ISAM backend via Berkeley DB drags in
> Oracle conditions. Operational consequence: **it is not enough to read the file called
> `LICENSE`; you have to read the one that contains the licence**, and check whether compiler and
> runtime go separately.
>
> **Variants of the same failure, all confirmed in the catalogue** — any mechanical check
> that assumes `raw.../main/LICENSE` produces **false negatives**: file with **another name**
> (`COPYING` in YottaDB), **another extension** (`LICENSE.txt` in NetBox, `LICENSE.md` in Traefik),
> **another capitalisation** (`License.txt` in Lucee, `license.txt` in BoxLang) and **another default
> branch** (`master` in Angie, `7.0` in Lucee, `development` in BoxLang). And an extra warning:
> **GitHub's automatic licence classification gets it wrong** — it marks BoxLang as
> `NOASSERTION` because it carries a commercial preamble in front of a perfectly valid
> Apache-2.0 text. **The API is not a substitute for reading the file.**

**Not applicable**: see `vulnerability-management-standards` (**thin and reciprocal boundary: the same
SBOM serves both and that is why they get confused**. The SBOM is generated once and consumed
twice: *for CVEs* —triage, EPSS/KEV, VEX, patching SLA— **theirs**; *for licence
obligations* —what I may combine, what I must publish, what I must attribute— **belongs here**.
Rule: if the question is "can this compromise me?", it is theirs; if it is "does this oblige me to
anything?", it belongs here), `cicd-standards` (**the pipeline runs the gate**: the runner, the job,
the cache, the OIDC and the artifact signature are theirs; **the threshold, the allowlist and what
breaks the build belong here**), `grc-compliance-standards` (**the corporate regulatory framework, the
risk register, the formal acceptance and the audit evidence are theirs**; here the technical control
that feeds them and the licence inventory), `secrets-management-standards` (a commercial licence
key —Directus, gitleaks-action— **is a secret and is managed there**; that you need one is a
licence fact and belongs here), `appsec-standards` (vulnerability classes
and SAST/DAST selection; **that Brakeman is not free belongs here**), `ai-governance-standards`
(**the governance of AI use —system inventory, AI Act, impact assessment— is
theirs; the licence of the artifact —weights, dataset, provider terms of use— belongs here**),
`ai-agent-workflow-standards` (**already written**: the licence and authorship of code generated by an
agent **is declared there as an UNRESOLVED question**. That is respected: this skill **does not invent
an answer**, it only fixes the procedure of §6.4 —traceability and provenance
verification— which is valid regardless of how it gets resolved), `git-workflow-standards`
(**the repository's licence file, the `Signed-off-by` and the commit signature are
theirs**; which licence to put and why to require DCO instead of CLA belongs here), and the language
skills —`python-standards`, `go-standards`, `rust-standards`, `typescript-standards`,
`java`/`jvm-spring-standards`, etc.— (**the specific package manager, its lock file
and its ecosystem's scanning command are theirs**; the policy that command applies belongs
here). With `green-it-standards`: **the licence of carbon measurement tools is
governed by this skill**. **Here only the *free* licence**: the **proprietary commercial licence** and
the **vendor audit** —named user, indirect access, annual measurement and declaration—
belong to `erp-sap-standards` and `crm-salesforce-standards`.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Licence of what you publish (library) | **Apache-2.0** | It is the permissive one with an **explicit patent grant** (§3.2). MIT/BSD-3 only if the ecosystem imposes it (npm, Go). In Rust, the idiom is `Apache-2.0 OR MIT` — the `OR` exists precisely to provide a way out of the GPL-2.0 incompatibility |
| Licence of an internal, non-distributed application | **Proprietary / no public licence** | Not publishing is not an oversight; publishing without deciding to is. A repo with no `LICENSE` **is not open source**: without an express grant, all rights are reserved by default |
| Identifier | **SPDX expression** in `LICENSE`, in the package metadata and in the header (`SPDX-License-Identifier:`) | The only format a gate can parse. Free prose = manual review |
| Licence list | **SPDX License List** — verify the current version (§8) | It is the gate's vocabulary. Anything unlisted goes as `LicenseRef-...` and **enters manual review by definition** |
| SPDX specification | **3.0.1** (Dec 2024) as the published version; 3.1 in *release candidate* since Jan 2026 | Do not confuse the **specification** version (3.0.1) with the **list** version (3.x independent, at 3.28.0 as of Feb 2026). Verify both separately (§8) |
| SBOM format | **CycloneDX** for internal consumption; **SPDX** when the customer or regulator requires it | Verify the version your consumer accepts before generating: some consumers reject the latest minor. This version criterion is coordinated with `vulnerability-management-standards` |
| SBOM generation | **Syft** (or `trivy sbom`) in the build pipeline, over the **artifact**, not over the repo | The repo's SBOM does not describe what you deploy. Verify the tool's licence and status (§8) |
| Licence detection (deep) | **ScanCode Toolkit** (Apache-2.0) | Scans the actual text of files, not the manifest. It is the only way to detect the cases in §3.6 |
| *Clearance* and review workflow | **FOSSology** (GPL-2.0) if there is a formal audit obligation | Verify the tool's licence before integrating it into a product: FOSSology is strong copyleft, which **is irrelevant for using it and relevant if you embed it** |
| CI orchestration | **ORT (OSS Review Toolkit)**, Apache-2.0 | Runs ScanCode + evaluates against your policy + generates attribution. It is the only one on the list that does all three. Cost: it is a project in itself |
| PR gate (GitHub) | **`dependency-review-action` with `allow-licenses`** — **never** `deny-licenses` | `deny-licenses` is **deprecated** and slated for removal in the next major. And the underlying argument is correct: a list of forbidden ones will always forget one (the classic: you forbid `GPL-2.0` and `CC-BY-SA-4.0` comes in). **Allowlist or no gate** |
| Per-ecosystem gate | **The native tool**: `cargo-deny` (Rust), `go-licenses` (Go), `pip-licenses`/`liccheck` (Python), `license-checker` (npm), `dependency-license-report` (JVM) | `dependency-review-action` only sees the dependencies **that change in the PR**; the native gate sees the whole graph. **You need both**, and both as *required status checks* |
| Authorship marking in the repo | **REUSE** (`LICENSES/`, `SPDX-License-Identifier` headers, `reuse lint` in CI) | Verify the current version of the specification (§8; there was 3.3 from Nov 2024 with signs of a later 3.4 — **declare the discrepancy**, see §8). Practical warning: GitHub identifies the licence with `licensee`, which does **not** understand REUSE — leave a `LICENSE` at the root as well as the directory |
| Attribution when distributing | **`THIRD-PARTY-NOTICES.txt` generated in the build**, versioned alongside the artifact | Generated, not hand-written: a manual file is out of date on day 2. See §5.4 |
| Incoming contributions | **DCO** (`Signed-off-by:`) | Less friction and sufficient for most projects. **CLA** only if you need to relicense or sell exceptions — and then say out loud that that is the reason (§6.1) |

## 3. What open source is, what it is not, and what each family requires

### 3.1 The definition and the edge

The **Open Source Definition** (OSI) opens, **verbatim**:

> «Open source doesn't just mean access to the source code. The distribution terms of
> open source software must comply with the following criteria:»

and lists ten criteria, whose titles are, **verbatim**: *Free Redistribution*; *Source
Code*; *Derived Works*; *Integrity of The Author's Source Code*; *No Discrimination Against
Persons or Groups*; *No Discrimination Against Fields of Endeavor*; *Distribution of License*;
*License Must Not Be Specific to a Product*; *License Must Not Restrict Other Software*;
*License Must Be Technology-Neutral*. The document identifies itself as **«Version 1.9, last
modified, 2007-03-22»**.

**Hard rule**: criterion 6 (*No Discrimination Against Fields of Endeavor*) is the one that
rules out almost everything *source-available*. A clause saying «you may not offer this as a
competing service» or «not for commercial use» **discriminates against a field of endeavour** and
therefore **is not open source**, however much the repository sits on GitHub and says «open» on the front page.

Status as of Aug 2026 of the licences that cause the most confusion — **none approved by the OSI**:

| Licence | What it is | Note |
|---|---|---|
| **SSPL-1.0** | *source-available*, copyleft extended to the service *stack* | MongoDB withdrew it from the OSI submission in 2019; in Jan 2021 the OSI declared that it **does not meet the OSD** because it discriminates against fields of endeavour, and called it *«fauxpen» source* |
| **Elastic License 2.0 (ELv2)** | *source-available*, forbids offering it as a managed service | Elastic itself describes it as **not OSI-approved** |
| **BUSL-1.1 / BSL** | non-compete + **deferred conversion to open source** (4 years by default) | «BSL is not an OSI approved license» — statement by Elastic itself. The *Additional Use Grant* is **variable per project**: you have to read the one for the specific project, not «the BUSL» |
| **RSALv2** | Redis's *source-available* | — |
| **PolyForm Shield / Noncommercial / Perimeter** | *source-available* with an anti-competition or non-commercial clause | — |
| **FSL** (Functional Source License) | *fair source*: non-compete + conversion to Apache-2.0 or MIT **after 2 years** | Created by Sentry as a simplification of the BUSL, fixing its variables |
| **FCL** (Fair Core License) | variant of FSL «that includes license key support» (fair.io, verbatim) | Adds limitations derived from ELv2 |
| **MSCL** (Monospace Sustainable Core License) | derived from FCL, used by Directus v12 | See §3.6 |

**Fair Source** is defined around three conditions: publicly readable code, use /
modification / redistribution with minimal restrictions, and **delayed open source publication
(DOSP)**. fair.io recognises, verbatim: **FSL** («A simple non-compete license with
eventual Open Source conversion after two years»), **FCL** («A variant of FSL that includes
license key support») and **BUSL/BSL** («A complex non-compete license with eventual Open Source
conversion after a certain amount of time, usually four years»). *Fair source* **is not open
source and does not claim to be**; the conflict is one of nomenclature, not of honesty.

**Declared discrepancy**: the OSI itself is the source of the concept of *Delayed Open Source
Publication* that underpins the *fair source* designation, and at the same time members of its board
publicly hold that these licences **are not open source** because their freedoms do not
reach everyone and non-compete is «legally fuzzy». **Both things are true at
once**: the OSI recognises the *mechanism* (DOSP) and rejects the *label*. Do not cite one without the other.

**Operational consequence of deferred conversion** — and almost nobody exploits this: in a
licence with DOSP, **each specific version has its own conversion date**. Akka moved to
BSL in 2022 and its versions revert to Apache-2.0 **36 months after their publication**;
Akka 2.7.0 has already reverted. Rule: **a licence with DOSP is not evaluated as a licence, it is evaluated
as a calendar** — record in the inventory the version, its publication date and its
conversion date, because the answer changes over time without anyone touching anything.

### 3.2 Families and what they actually require

**Permissive — MIT, BSD-2/3-Clause, ISC, Apache-2.0.** They require **preserving the copyright
notice and the licence** when redistributing. That is already a real obligation and it is the most
breached one (§5.4). **The technical reason to prefer Apache-2.0 over MIT is not copyleft: it is the
express patent grant** and its termination clause —if you sue a user of the software over
patents, you lose the patent licence—. MIT and BSD are silent on
patents, and silence is not a grant. Apache-2.0 additionally adds the `NOTICE` file
obligation: if the project ships one, **you propagate it**.

**Weak copyleft.**
- **LGPL (2.1 / 3.0)**: the copyleft reaches the library, not your application, **on condition
  that the end user can replace the library with another version**. With **dynamic linking**
  that is trivial; with **static linking** it requires delivering objects or sources that allow
  relinking. LGPL-3.0 additionally adds the anti-*tivoization* clause inherited from GPL-3.0.
  **Real precedent from the catalogue: Pa11y is LGPL-3.0**, not MIT.
- **MPL-2.0**: the copyleft is **per file, not per project**. You modify a covered `.js` →
  that file remains MPL and you publish that modified file. Your new code in new files
  **is not contaminated**. This makes it suitable for combining with proprietary code, and it is the
  reason so many development tools choose it. **Real precedents:
  axe-core, StyLua, selene, Lightning CSS and `data.table` are MPL-2.0**; OpenBao too.
- **EPL-2.0**: copyleft at «module» scope, with *source availability* obligations and its own
  patent clause. Fine point: **EPL-2.0 allows designating the GPL as a secondary licence**
  — if the project has done so, the compatibility answer changes. **Read it in
  the file, do not assume it.**

**Strong copyleft.**
- **GPL-2.0 vs. GPL-3.0**: they are not the same decision. GPL-3.0 adds anti-*tivoization*
  (an obligation to deliver installation information on consumer hardware), an express
  patent grant and compatibility with Apache-2.0. **`GPL-2.0-only` and `GPL-2.0-or-later` are
  different licences and the gate must distinguish them**: `-or-later` lets you move up to 3.0 and
  resolve incompatibilities; `-only` does not. **Real precedent: perltidy is GPL-2.0.**
- **AGPL-3.0 — the «network use» trigger, and it is the one that kills a SaaS.** GPL requires delivering
  sources **when distributing**; AGPL additionally requires offering the *Corresponding Source* **to
  users who interact with the program over a network**, even if you never distribute a
  binary. **This turns «we do not distribute, therefore it does not apply to us» —the correct reasoning
  for GPL in a SaaS— into a falsehood.** The scope is the modified program and its *Corresponding
  Source*, not your whole *stack* (that is SSPL, and that is why SSPL is not open source). **Real
  precedents: k6, Pyroscope, Slither, Echidna and Medusa are AGPL-3.0**; and Elasticsearch (2024) and
  Redis 8 (2025) returned to the OSD **via AGPL**, precisely because it deters resale
  as a service without leaving the definition.
- **CDDL-1.0 — it turns up where nobody expects it.** Per-file copyleft (like MPL-1.1, from which
  it descends) and **considered incompatible with the GPL by the FSF**, among other things because of its
  jurisdiction clauses. It is the reason for the eternal ZFS-in-the-Linux-kernel problem.
  **Real precedent from the catalogue: FlameGraph is CDDL**, and it shows up in any
  profiling workflow without anyone looking at it.

**Exceptions (`WITH`).** An SPDX exception **changes the result**: `Apache-2.0 WITH
LLVM-exception` (Wasmtime, and the whole LLVM ecosystem) exists precisely to avoid
attribution obligations in linked binaries and to ease combination. Treating
`Apache-2.0 WITH LLVM-exception` as plain `Apache-2.0` is an analysis error, not a
nuance. **The gate must understand the `WITH` operator**; if your tool collapses it, you have a
false result and you do not know it.

### 3.3 Compatibility: it is directional, not symmetric

**The right question is never «are A and B compatible?», but «under which licence does the
combined work end up, and can I accept it?».** Compatibility has a direction of travel:

- **Apache-2.0 → GPL-3.0**: they combine, and **the result is GPL-3.0**. Not the other way round: the
  GPL-3.0 code cannot go into an Apache project.
- **Apache-2.0 ↔ GPL-2.0-only**: **incompatible**. The FSF holds that all versions of
  the Apache License are incompatible with GPL v1 and v2, because of the patent and
  indemnity clauses. This is the most common and most silenced conflict in the real ecosystem, and the
  reason Rust is published as `Apache-2.0 OR MIT` (you pick MIT and the problem disappears)
  and why LLVM drafted its exception.
- **MPL-2.0 → GPL/LGPL**: MPL-2.0 was explicitly designed to be compatible (unlike
  MPL-1.1), unless the project has marked the file as *Incompatible With Secondary
  Licenses*. **That notice is in the file header: if you have not read it, you have not verified
  compatibility.**
- **CDDL ↔ GPL**: **incompatible** according to the FSF.
- **Permissive → proprietary**: always possible, with the attribution obligation intact.

**Gate rule**: compatibility is not reasoned about in the PR, it is **decided once** in the
policy of §5.1 and the PR only checks membership of the list. Reasoning about compatibility in every
PR guarantees that one day it will be reasoned badly, in a hurry, on a Friday.

### 3.4 The four distinctions that cause almost every mistake

1. **Static vs. dynamic linking.** Determines whether LGPL requires you to allow relinking
   (§3.2). A Go binary is **always static**: in Go, «we link dynamically» is not an
   available option and that argument does not exist. A `FROM scratch` container with a
   static binary inside does not save you either.
2. **Distribution vs. internal use.** Classic copyleft (GPL, LGPL, MPL, EPL) triggers on
   **distributing**, not on using. GPL software used internally and never delivered to a third party
   **creates no obligation to publish**. That reasoning is correct **and AGPL voids it** (§3.2)
   — and so does a customer to whom you deliver a virtual machine, a `.deb`, an
   image or a device.
3. **Container vs. binary.** Delivering a container image **is distribution of everything
   inside it**: the base image, its system packages and its libraries, not just your
   application. Your source-code SBOM does not cover that. **That is why the SBOM is generated from the
   artifact** (§2). A base image with a GPL package you do not invoke **is still distribution
   of that package**.
4. **Does a SaaS distribute?** Under GPL/LGPL/MPL, the default operational answer is **no**: giving
   access to a service is not delivering copies. **Under AGPL, yes in practice**: the
   obligation towards network users is triggered. And there are two frequent leaks that break «we do not
   distribute»: **the code you send to the user's browser** (your JavaScript bundle *is*
   distributed, to each and every one) and **any agent, CLI or SDK the customer installs**.
   A backend that does not distribute with a frontend that does is the normal case, not the
   exception.

### 3.5 SPDX and the file

Canonical identifier, in three places and all three mandatory when you publish:
`LICENSE`/`LICENSES/` with the **full text**; the manifest's licence field with the
**SPDX expression**; and `SPDX-License-Identifier: <expr>` in the **header of every file**
(REUSE). Expressions: `AND` (you comply with both), `OR` (you pick one — **and you must record which one
you pick**, because `Apache-2.0 OR MIT` with no declared choice is a pending decision), `WITH`
(exception). Anything without a listed identifier goes as `LicenseRef-...` and **enters
manual review by definition** — a `LicenseRef` or a `NOASSERTION` is never self-approved.

### 3.6 Why the manifest's `license` field LIES

**This section is the core of the skill and its reason for existing.** During the construction of
this catalogue, **verifying the raw `LICENSE` file**, the following cases turned up —
all with third-party documentation claiming the opposite:

| Case | What almost everyone says | What the file says |
|---|---|---|
| **Brakeman** | «MIT, it is the standard Rails scanner» | **Brakeman Public Use License**, proprietary to Synopsys. Code prior to 15-Jun-2018: MIT. Later: not free. **Scanning your own code is permitted; embedding it in a commercial product or service requires a commercial agreement.** Free fork of the pre-acquisition code: **Railroader** |
| **Directus** | «open source headless CMS» | Since **v12 (May 2026): Monospace Sustainable Core License**, derived from FCL. Free commercial use only via **Open Innovation Grant**, capped at **<$5M annual revenue and <50 employees**; conversion to **GPLv3 after 4 years**; mandatory **software key** (goodbye honour system). The SDKs remain MIT. **The package and the product do not share a licence** |
| **WebPageTest** | «open source web performance tool» | **PolyForm Shield**: *source-available* with an anti-competition clause |
| **FlameGraph** | «profiling script, MIT for sure» | **CDDL** — incompatible with GPL (§3.2) |
| **k6, Pyroscope** | «open source» (true) | **AGPL-3.0** — true and **relevant if you embed them in a service** |
| **Slither, Echidna, Medusa** | «Trail of Bits tools» | **AGPL-3.0** |
| **Pa11y** | «MIT like the rest of npm» | **LGPL-3.0** |
| **axe-core, StyLua, selene, Lightning CSS, `data.table`** | «MIT / permissive» | **MPL-2.0** (per-file copyleft) |
| **perltidy** | — | **GPL-2.0** |
| **Playwright** | — | **Apache-2.0** (not MIT) |
| **Extism** | — | **BSD-3-Clause** |
| **Wasmtime** | «Apache-2.0» | **Apache-2.0 WITH LLVM-exception** — the exception changes the analysis (§3.2) |
| **Tolgee, Strapi** | «open source» | **Dual, with a proprietary `ee/` directory in the same repository**. The repo has one licence; **parts of the repo have another** |
| **gitleaks** | «MIT» | The **scanner** is MIT and its author declared it *feature complete* (security patches only; successor: Betterleaks). The **GitHub action `gitleaks-action`** is **proprietary since v2.0.0** and **requires a licence key to scan an organisation's repositories** (free via form, with paid tiers by number of repos). **Two artifacts, two licences, same name** |
| **Infracost** | «Apache-2.0, free» | The **CLI** is Apache-2.0; **the hosted pricing API it depends on has a quota and a paid plan**. Free licence ≠ free operation |
| **Akka** | «Apache-2.0» | **BSL since 2.7.x** (2022), with a commercial threshold declared in the region of ~$25M revenue and **automatic reversion to Apache-2.0 after 36 months per version**. Fork: **Apache Pekko** (from 2.6.x, graduated at the ASF) |
| **Vault** | «open source» | **BUSL since 2023**. Fork: **OpenBao** (MPL-2.0, Linux Foundation) |
| **Trivy** | «Apache-2.0 as always» | **It changed licence** — verify the one for the artifact and version you use (§8) |
| **Elasticsearch** | «it went back to being open source» | **It added AGPL-3.0 (2024) alongside SSPL and ELv2 for the source code**. **Open gap: the licence of the binaries distributed by Elastic** — there are signs that the *releases* remain under the Elastic License even though the source is triple-licensed. **Not closed here: see §8** |

**The five rules that follow, and they are the policy:**

1. **The manifest's `license` field is a declaration by the packager, not a verified
   fact.** You read the `LICENSE` file **of the specific version you are going to use**.
2. **A repository may have more than one licence.** The `ee/`, `enterprise/` or
   `pro/` directory is the standard *open core* pattern; the root manifest **does not reflect it**.
3. **A project may have more than one artifact with different licences** (gitleaks vs.
   gitleaks-action; Directus core vs. SDK; Elasticsearch source vs. binary). **The unit of
   analysis is the artifact you install, not the project that publishes it.**
4. **The licence is tied to the version.** «X is MIT» is a meaningless statement without a version.
5. **Free licence ≠ free to operate** (Infracost) and **free licence ≠ maintained**
   (gitleaks). Verify all three things: licence, operating cost and project status.

## 4. Gate quality: what gets checked and what breaks the build

In increasing order of cost. The first three are mandatory; the fourth depends on whether you
distribute.

1. **Precondition — lock file.** Without `uv.lock` / `package-lock.json` / `go.sum` /
   `Cargo.lock` / `poetry.lock` the graph is not deterministic and **any scan describes a
   resolution that will never happen again**. Without a lock there is no gate: there is theatre.
2. **PR gate (seconds).** `dependency-review-action` with `allow-licenses`. Fails if the
   **new** dependency brings a licence outside the allowlist. Practical note: `OTHER` is not
   a valid SPDX identifier and translates to `LicenseRef-clearlydefined-OTHER` — use it in
   that form in the list or you will get false greens.
3. **Full-graph gate (minutes, on every `main` build).** The ecosystem's native tool.
   **It breaks the build.** Specific warning: `cargo-deny` **removed** `deny`, `copyleft`,
   `allow-osi-fsf-free` and `unlicensed` — now **everything is denied except what is explicitly
   allowed**, which is exactly the right model; an old `deny.toml` with those fields
   **fails with an error**, it does not degrade silently. And check the scope: by default it excludes
   *dev-dependencies* and **includes *build-dependencies***, because those do influence the
   artifact.
4. **Deep text scan (nightly or per *release*).** ScanCode/ORT over the artifact.
   It is the only one that detects files with a header different from the project's, copied code and
   `ee/` directories. **It does not block the PR; it opens a ticket with an SLA.**
5. **`reuse lint`** if you publish: fails if any file lacks licence information.

**What breaks the build (non-negotiable):**
- ❌ Licence outside the allowlist (§5.1).
- ❌ **Unknown** licence, `NOASSERTION`, `LicenseRef-*` without an approved exception. **The
  unknown is treated as forbidden**, not as pending: «pending» means it gets
  merged and nobody comes back.
- ❌ Strong copyleft (GPL/AGPL) in a distributed artifact or in a network service, without a
  registered exception.
- ❌ Licence change of an **existing** dependency between two versions — it is the event
  of §6.2 and must alert even if the new licence is also allowed.
- ❌ Absence of an artifact SBOM in a *release* build.

**False positives and negatives, honestly**: manifest-based detection has a structural false
negative (§3.6) and text-based detection has abundant false positives (a
sample `LICENSE` inside a test directory sets off alerts). **Every suppression of a
finding is recorded with a reason and expires** — the same model as a VEX in
`vulnerability-management-standards`. A suppression with no date is a permanent exception
in disguise.

## 5. Policy, inventory and obligations

### 5.1 The three lists

The policy has **exactly three categories**, and the list is published in the repo, not in a
wiki nobody reads:

| Category | Typical content | Rule |
|---|---|---|
| **Allowed** | MIT, BSD-2/3-Clause, ISC, Apache-2.0, Apache-2.0 WITH LLVM-exception, Unlicense, CC0-1.0, Zlib | Self-approved. The gate does not ask |
| **With review** | MPL-2.0, EPL-2.0, LGPL-*, CDDL-1.0, GPL-* with `-or-later`, duals with `ee/`, any `LicenseRef-*` | Approved **per dependency and per use case** (distributed / internal / network), with an owner and a date. The approval **is not transitive to another project** |
| **Forbidden** | AGPL-* in a distributed product or SaaS, SSPL, ELv2, BUSL, RSALv2, PolyForm, FSL, FCL, MSCL, CC-*-NC-*, «no licence» | Breaks the build. Lifting it requires a formal exception (§5.3) |

These lists **are a starting point and depend on your business model**: if you do not distribute
software and do not offer a network service, AGPL may be perfectly acceptable; if you sell a
product installed at the customer's premises, LGPL with static linking is already a problem.
**Explicit prohibition: do not copy these three lists without declaring the distribution model they
apply to.** A licence policy without a declared distribution model cannot be
applied, only obeyed blindly.

### 5.2 Inventory

It is maintained **per deployable artifact**, not per repository, and is derived from the SBOM: name,
version, **verified** SPDX expression (not the manifest's), source of the datum (manifest /
scanned text / manual review), verification date, and **if it is DOSP, the conversion
date** (§3.1). It is regenerated on every *release*; a hand-maintained inventory is a
false inventory within three months.

### 5.3 Exceptions

Name of the dependency, **version**, licence, reason, **alternative evaluated and why it was
discarded**, scope (specific project and distribution mode), approver, and **mandatory
expiry date**. Without an expiry it is not an exception, it is a policy change through the
back door. The **formal acceptance of residual risk** is recorded where
`grc-compliance-standards` dictates; here lives the technical control that makes it enforceable.

### 5.4 Attribution: the obligation almost nobody meets

**Almost every permissive licence requires preserving the copyright notice and the text of
the licence when redistributing.** It is the most breached obligation in the industry, precisely because
it is the easiest: nobody audits a `THIRD-PARTY-NOTICES` until a big customer audits it.

- It is **generated in the build** from the SBOM (ORT does it; so do the native generators) and is
  versioned with the artifact.
- It is included **in the artifact itself** when distributed: in the image, in the package, in
  the application's «About». A file in the repository does not travel with the binary.
- Apache-2.0: **the dependency's `NOTICE` is propagated**, the licence text alone is not enough.
- Copyleft: you must additionally offer the **corresponding source code** — with a valid offer
  and a channel that really exists. A written offer pointing at a switched-off server is
  a breach, not a formality.

### 5.5 SBOM: generating it is not using it

**Generating an SBOM and not consuming it is a ticked box, not a control.** The SBOM is useful if:
(a) the licence gate reads it, (b) CVE triage reads it
(`vulnerability-management-standards`), (c) attribution is generated from it, and (d) you can
answer «which deployed versions contain component X?» in minutes. If you do not
consume it in at least (a) and (b), do not generate it yet: fix that first.

**Regulatory obligation — Cyber Resilience Act (EU), Regulation (EU) 2024/2847.** Verified
dates (§8): entry into force **10-Dec-2024**; **11-Jun-2026** application of Chapter IV
(notification of conformity assessment bodies); **11-Sep-2026** application of the
**reporting obligations** —actively exploited vulnerabilities and severe incidents,
with early warning within **24 h** and notification within **72 h**, through ENISA's single
platform (art. 16)—; **11-Dec-2027** **full** application, including essential requirements,
conformity assessment, technical documentation, CE marking and **SBOM**. The SBOM requirement
of Annex I, Part II, point 1 requires identifying and documenting the components «in a commonly
used and machine-readable format», **covering at the very least the top-level dependencies**.
Penalties of up to **€15M or 2.5 % of annual worldwide turnover**, whichever is higher.

**Consequence the date hides**: even though the SBOM is enforceable in Dec 2027, **from Sep 2026
you have 24 hours to report an exploited vulnerability**, and in 24 hours you cannot investigate by
hand which components a product shipped three years ago contains. **The SBOM is an operational
prerequisite of the 2026 obligation, not of the 2027 one.**

**USA**: the SBOM requirement in federal public procurement comes from EO 14028 (2021) and its
implementation (NIST guidance, NTIA *minimum elements*, OMB memoranda on vendor
attestation). **Gap: the exact status of these orders and memoranda as of Aug 2026 has not been
verified in this drafting — see §8. No US date is cited here.**

**Scope rule, and it is the boundary with the vulnerability skill:** the CRA is above all
a **security** obligation; its risk management, notification and triage belong to
`vulnerability-management-standards` and `grc-compliance-standards`. What stays here is **the SBOM as an
artifact: which format, when it is generated, from what it is generated and which licence fields it carries**.

## 6. Life cycle: relicensing, contributions and AI artifacts

### 6.1 Contributing outwards

- **DCO** (`Signed-off-by:`, verified in CI): the contributor certifies that they have the right to
  contribute. No transfer of rights, no legal friction. **Default.**
- **CLA**: assigns or licenses rights to the project. It has only one real motive — **being able to relicense
  later or sell proprietary exceptions**. It is legitimate, but **requiring a CLA and presenting yourself
  as community-driven without explaining why is where the distrust begins**. If you ask for it, say so.
- **Risk signal for the consumer**: a project with a full-assignment CLA **can
  relicense tomorrow without asking anyone's permission**. That is not a reason to discard it; it is a reason
  to put it on the radar of §6.2. Almost every relicensing in §3.6 happened in projects
  with a CLA and a single corporate owner. **The combination «single corporate owner
  + assignment CLA» is the best available predictor of a future relicensing.**
- **Employee and contractor work**: ownership depends on the contract and the
  jurisdiction, and contributing to an external project with a personal account from the
  company laptop does not change it by itself. **That an internal contribution policy exists is a
  requirement; its drafting is a matter for legal counsel** (§1).

### 6.2 When a dependency relicenses under your feet

Four steps, in order, and none of them is optional:

1. **Detection.** The full-graph gate must **compare the licence against the one recorded in
   the inventory** and alert on any change, **even if the new one is also allowed**.
   Detecting this by reading Hacker News is the industry's default state and is not a process.
2. **Impact assessment.** Three questions, and only three: do we **distribute** the artifact that
   contains it? Do we offer it **over a network**? Do we exceed the **threshold** of the free grant
   —revenue, employees, number of repos, number of servers— today **and in 18 months**? The
   thresholds of §3.6 ($5M/50 employees for Directus, ~$25M for Akka) are the part that grows
   with you: **a dependency that is free today may stop being free without changing version, just
   because the company grew.** Add the threshold to the inventory alongside the version.
3. **Decide between four exits** (and **not** the fifth, which is not deciding):
   - **Pay for the commercial licence.** It is a legitimate option and often the cheapest. Migrating
     on principle comes out dearer than paying for a tool that works.
   - **Migrate to the community fork.** It is a **real and proven** option, not theoretical:
     **OpenTofu** (Terraform→BUSL; in the CNCF since Apr 2025, same provider binaries,
     full compatibility, and already with its own divergent functionality such as native state
     encryption), **OpenBao** (Vault→BUSL; MPL-2.0, API compatible, adopted by Nvidia),
     **Apache Pekko** (Akka→BSL; graduated at the ASF, **but with deliberate incompatibility of
     packages, configuration and ports — it is not a change of Maven coordinate**), **Valkey**
     (Redis→RSALv2/SSPL, under the Linux Foundation), **OpenSearch** (Elasticsearch→SSPL/ELv2,
     transferred to the Linux Foundation), **Railroader** (Brakeman). **The best predictor that
     a fork survives is that it has a neutral home** (ASF, LF, CNCF); those that stay in
     the forker's personal repository rarely make it past the first year.
   - **Replace with another tool.** High and honest cost.
   - **Pin the last version under the old licence.** It is the only **temporary** measure on the
     list and **requires an expiry date in the ticket from minute one**. It stops receiving
     security patches: **it is as much an exception under `vulnerability-management-standards`
     as one under this document**. Without a date, this option is the trap: nobody looks at it again until
     there is a critical CVE with no patch available.
4. **Record the decision** as an ADR, with the analysis of the four points. Relicensing will
   happen again, and the next team needs to know why what was chosen was chosen.

**And the reverse, which gets forgotten**: also review the **reversions**. Elasticsearch (AGPL, 2024)
and Redis 8 (AGPL, 2025) returned to the OSD; Akka's DOSP clock has already returned versions to
Apache-2.0. **A prohibition based on a relicensing from three years ago may be
forbidding software that is free today**, and that is also a policy failure. Review the
forbidden list at least annually.

### 6.3 Models, datasets and content

- **A model's weights almost never arrive under an OSI licence.** «Open weights» ≠ «open
  source». Llama, Gemma and similar carry **community licences with usage restrictions and
  thresholds**; part of the Qwen family and DeepSeek's MIT releases do align the
  licence, but with **partial** disclosure of training data. A model is evaluated on
  **three independent axes**: licence of the weights, licence/provenance of the dataset, and
  terms of use of the generated output. **All three are recorded in the inventory; all three
  can be different and usually are.**
- **The OSI published the Open Source AI Definition 1.0** (Oct 2024), which requires training and
  inference code under an approved licence, parameters under terms that allow use,
  study, modification and redistribution, and **«data information»** sufficient for a
  competent person to substantially recreate the system. **The discrepancy is live and
  must be declared**: the OSAID **does not require publishing the training data**, only
  describing it when it cannot be shared, and that is why the Software Freedom Conservancy holds
  that it «erodes the meaning of open source» by not requiring public reproducibility of the
  scientific process. **The OSI does not certify individual models**: any list of
  «conforming models» is discussion, not a register. **Cite the OSAID as a reference and its criticism
  at the same time; do not present it as consensus.**
- **Datasets**: non-OSI licences (CC-BY-NC, «research only», terms of the original source) and
  frequently opaque provenance. **A dataset with no declared licence is not a permissive
  dataset; it is a dataset with no licence.**
- **Content**: the CC family is not interchangeable. **CC-BY-NC-* is not free** (criterion 6 of
  the OSD) and **CC-BY-SA is copyleft**. **CC0/CC-BY for documentation is not the same as the
  code's licence, and both are declared separately.**

### 6.4 Agent-generated code

**The licence and ownership of code generated by a model are an UNRESOLVED question**,
and it is declared as such in `ai-agent-workflow-standards`. **This skill does not invent an answer**
and forbids asserting one. What it does fix, because it holds under any future answer:

- **Traceability**: the commit declares that there was assisted generation, following the convention of
  `git-workflow-standards`.
- **Provenance verification**: a block of code that appears complete and cannot be
  explained **is verified against the original before merging** — the check is the same
  as for copying from Stack Overflow or from a repository, because the risk is the same.
- **The licence gate applies just the same**: if the agent added a dependency, it goes through §4 with no
  special treatment.

## 7. Sustainability and prohibitions

**Cadence**: gate on every PR; deep scan per *release*; **review of the three-list policy
and of the DOSP dates, twice a year**; review of expired exceptions, monthly;
regeneration of the inventory, on every *release*.

**Deprecation**: `deny-licenses` in `dependency-review-action` is deprecated — migrate to
`allow-licenses` **now**, not when they remove it. Removed `cargo-deny` fields (`deny`,
`copyleft`, `allow-osi-fsf-free`, `unlicensed`): migrated. Any `deny.toml` or gate config
not reviewed in over a year is treated as unverified.

**FORBIDDEN:**

- ❌ **Adding a dependency without checking its licence.** No exception, no «it is only for a
  prototype» and no «we will look at it later». Prototypes reach production; deferred
  checks do not.
- ❌ **Trusting the manifest's `license` field, the README badge or an aggregator's
  listing.** You read the `LICENSE` of the specific version. Precedents: Directus, Brakeman,
  WebPageTest, FlameGraph, Tolgee, Strapi (§3.6).
- ❌ **Assuming MIT by default.** «It is on npm/PyPI, it will be MIT» has already failed thirteen
  documented times in this catalogue. Absence of data is unknown data, and the unknown is
  treated as forbidden (§4).
- ❌ **Using AGPL in a SaaS —or in any network-accessible service— without an explicit,
  recorded and approved decision.** It is not that it is forbidden: it is that **it must not happen by accident**.
- ❌ **Copying code fragments without verifying their provenance** — from a blog, from Stack
  Overflow, from another repository or from a model's output. A fragment with no known origin
  is a fragment with no known licence.
- ❌ **Treating «unknown», `NOASSERTION` or `LicenseRef-*` as provisionally approved.**
- ❌ **Using a list of forbidden licences instead of an allowlist.** One is always missing.
- ❌ **Approving an exception without an expiry date**, or pinning an old version because of a
  relicensing without a dated ticket.
- ❌ **Distributing without a generated attribution file**, or generating it by hand.
- ❌ **Calling software with a non-OSI-approved licence «open source»** in documentation,
  marketing, README or a customer response. *Source-available* and *fair source* have names
  of their own; using them is not a concession, it is accuracy.
- ❌ **Publishing a repository without a `LICENSE` file** and assuming that «public» implies
  permission to use. It does not.
- ❌ **Reusing the approval of a dependency in another project or in another distribution
  mode.** Approval is per dependency **and per use case**.
- ❌ **Generating an SBOM that nobody consumes** and presenting it as a compliance control.
- ❌ **Issuing a legal conclusion.** Here you decide what breaks the build; the interpretation
  of the clause and the contractual risk belong to legal counsel (§1).

## 8. Mandatory web verification

This domain changes through business decisions, not technical cycles: **a licence can
change any Tuesday** and there are no *release notes* announcing it clearly.

**Always check, before pinning anything:**

1. **The raw `LICENSE` file of the specific version** of every dependency you pin, in the
   repository, and **also that of its subdirectories** (`ee/`, `enterprise/`, `pro/`). **Never
   the badge, the aggregator or the manifest.** And **the distributed artifact may differ from the
   source** (the Elasticsearch case).
2. **Status of the OSD** (version and date of the document) and of the **list of licences approved**
   by the OSI. Which *source-available* / *fair-source* licences it has explicitly rejected and
   in what words — **cite verbatim**.
3. **Status of the Open Source AI Definition** (is it still 1.0? is there a 1.1?) and of the open debate.
4. **Current version of the SPDX specification and of the list**, separately: as of Aug 2026 the
   published spec was **3.0.1** with **3.1 in RC** since Jan 2026, and the list at **3.28.0**
   (Feb 2026), with later preview *builds*. Verify both.
5. **CRA**: confirm the dates in §5.5 against the text of Regulation (EU) 2024/2847 and the
   practical guidance published by the Commission (Jul 2026), and the status of the harmonised standards and
   of ENISA's single reporting platform. **Cite Annex I verbatim if the specific
   SBOM requirement matters to a decision.**
6. **Status of the forks**: OpenTofu, OpenBao, Valkey, OpenSearch, Pekko, Railroader —
   alive, with a neutral home, with real compatibility? And **recent relicensings and reversions**.
7. **Status and licence of the tools** you pin: ScanCode, FOSSology, ORT, Syft, Trivy,
   `cargo-deny`, `reuse`, `dependency-review-action`, `licensee`. **Trivy has already changed licence
   once** and `gitleaks` is *feature complete*: take none of them for granted.
8. **Thresholds of the free grants** (Directus, Akka, gitleaks-action and any
   licence with a threshold): **they change, and your company grows too**.

**Open gaps in this drafting — not filled without verifying:**

- **Licence of the binaries distributed by Elastic**: the source of Elasticsearch/Kibana is
  triple-licensed (AGPL-3.0 / SSPL / ELv2) since 2024, but there are signs that **the binary
  *releases* remain under the Elastic License**. **Nothing is asserted here**: verify in the licence
  file of the downloaded artifact before deciding.
- **Status as of Aug 2026 of the US executive orders and memoranda on SBOM** (EO 14028
  and later implementation, NTIA/CISA *minimum elements*, OMB vendor attestation):
  **not verified in this drafting. No US date cited. Verify before
  using it in a contractual commitment.**
- **Current version of the REUSE specification**: there was **3.3** (Nov 2024) and tooling
  references to a later **3.4** appear. **Declared discrepancy** — confirm on
  `reuse.software` which one is published before pinning it in a `REUSE.toml`.
- **Revenue threshold of Akka's BSL**: the ~$25M figure comes from third-party sources,
  **not from the text of the Additional Use Grant**. Read the project's grant.
- **Cost figures for commercial licences** (Synopsys/Brakeman, gitleaks-action tiers,
  Infracost API quotas): **none is pinned** — without a verified quote you do not
  write a price.

**When a source contradicts itself** —the normal case here: the front page says «open
source» and the `LICENSE` says otherwise— **the `LICENSE` wins**, and the contradiction is declared in
the inventory so that the next person who looks does not repeat the work.

If the web contradicts this document, **the web wins** — flag the discrepancy.
