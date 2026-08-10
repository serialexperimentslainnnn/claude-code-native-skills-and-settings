---
name: mlsecops-standards
description: Security of the model lifecycle and the AI supply chain. Use when verifying provenance and integrity of third-party model weights, preferring safetensors over pickle-backed formats (.pt, .bin, joblib, Keras Lambda layers) and auditing trust_remote_code, scanning weights with picklescan or modelscan and understanding their evasion limits, signing model artifacts and pinning them by digest in a model registry, triaging an AI-stack supply-chain compromise (the LiteLLM PyPI backdoor and its .pth persistence, a poisoned CI scanner, malicious models or agent skills in a public hub), producing an AIBOM or ML-BOM with CycloneDX or the SPDX AI profile, handling data and model poisoning, model backdoors, query-based extraction and unauthorized distillation, model inversion and membership inference as risk classes with indicators and mitigations, rate limiting and anomalous-use detection on a deployed inference endpoint, hardening the training pipeline and its compute isolation, running AI red teaming with garak, PyRIT or promptfoo redteam, or mapping controls to MITRE ATLAS, the OWASP GenAI Top 10 (LLM and ASI), NIST AI RMF and AI 600-1, or EU AI Act Article 15.
---

# MLSecOps standards — security of the model lifecycle and the AI supply chain

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **securing the model lifecycle and its supply chain**: provenance and integrity of the
weights, serialisation formats and their capacity for arbitrary execution, scanning and signing of
model artifacts, inventory (AIBOM), security of the training pipeline and of the model registry,
the deployed endpoint as an attack surface, the risk classes specific to the lifecycle (poisoning,
backdoors, extraction, inversion, membership inference, adversarial examples), **AI** red teaming
methodology, and the mapping to the frameworks in force (ATLAS, OWASP GenAI, NIST AI RMF, AI Act
art. 15).

**Posture**: **defensive and authorised, always.** Attacks are described as **risk class,
indicator and mitigation**; never as a reproducible procedure. See §7.

**Domain thesis**: **a third-party model is a third-party binary.** A weights file downloaded from
a public hub has the same trust profile as an executable pulled off the internet — and, in several
formats in mass use, **it literally executes code when loaded**. Everything that follows derives
from treating it as such: provenance, integrity, signature, scanning, isolation.

**Second thesis**: **the AI supply chain is the software supply chain, plus the data and the
weights.** It does not replace it: it extends it. The real 2026 incidents were not exotic attacks
against models, but classic compromises of CI and package repositories that reached AI (§3.3).
**The control that removes the most AI risk is still pinning dependencies by digest.**

Triggers: `.safetensors`, `.pt`, `.pth`, `.bin`, `.ckpt`, `.pkl`, `.gguf`, `.h5`/`.keras`,
`torch.load`, `weights_only`, `pickle`, `joblib.load`, `trust_remote_code=True`, `from_pretrained`,
`picklescan`, `modelscan`, "malicious model", "public hub", "Hugging Face", "model registry",
`MLflow`, "sign the model", "AIBOM", "ML-BOM", "CycloneDX", "SPDX AI profile", "data
poisoning", "data poisoning", "model backdoor", "backdoor", "model extraction",
"unauthorised distillation", "model inversion", "membership inference", "membership
inference", "adversarial example", "AI red team", `garak`, `PyRIT`, `promptfoo redteam`,
`deepteam`, "MITRE ATLAS", `AML.T`, `AML.CS`, "OWASP Top 10 LLM", `ASI01`, "NIST AI RMF",
"AI 600-1", "AI Act article 15", "LiteLLM", "TeamPCP".

**Not applicable**: see
`llm-app-engineering-standards` (**prompt injection is theirs**, together with treating model
output as untrusted input, structured output and spend limits. **I do not claim it**:
here it appears only as one more technique in the ATLAS catalogue when mapping coverage);
`ai-agents-standards` (agent containment, sandbox, egress, human approval of
irreversible actions, lethal trifecta, OWASP ASI01–ASI10 agentic risks applied to loop design);
`rag-standards` (per-document access control over the retrieved fragments and index
deletion — poisoning of the retrieval corpus is **mitigated** there; here it is a risk
class of the lifecycle);
`mcp-standards` (tool poisoning, rug pull, server shadowing and authorisation of MCP servers);
`claude-api` (**installed skill, canonical reference on the Anthropic side**: nothing about Claude
models —id, price, limits, parameters— is asserted from memory);
`appsec-standards` (**application vulnerability classes** —IDOR, SSRF, XSS, insecure
deserialisation as a category, STRIDE, ASVS— and SAST/DAST/SCA selection. Here, insecure
deserialisation **applied to the model artifact** and the classes specific to the AI lifecycle);
`offensive-security-standards` (**the authorised exercise and its governance are theirs, without
exception**: written authorisation, RoE, scope, window, deconfliction, stop conditions, report,
retest, legal framing. **Precise boundary: if the question is "may I attack this and under what
role?", it is theirs; if it is "what is tested in an AI system and with what method?", it is
mine.** The AI red teaming of §3.7 runs **inside** their RoE, never outside);
`llm-evaluation-standards` (the measurement apparatus. **Boundary declared on
both sides: adversarial attack methodology is mine; the case set, the judge, the rubric,
the threshold and the CI gate it is measured with are theirs.** A red team finding becomes a
case in their eval set: that is the handoff);
`vulnerability-management-standards` (**CVE triage, CVSS/EPSS/KEV, remediation SLA and VEX. The
CVEs of the ML stack —`torch`, `transformers`, inference servers, harnesses— come in there**,
not here);
`cicd-standards` (**SBOM, signing with cosign/Sigstore and SLSA provenance in the pipeline are
theirs**, as is runner hardening and ephemeral identity via OIDC. **Here only what is specific
to the model**: what is signed when the artifact is weights, and what is inventoried when there is
also data);
`cryptography-pki-standards` (the signing primitive, the algorithm choice and the custody and
rotation of keys);
`secrets-management-standards` (manager, ephemeral credentials, rotation — the §3.3 incident is a
case of CI credential theft, and the structural mitigation is theirs);
`container-runtime-security-standards` and `kubernetes-standards` (isolation of the compute where
an untrusted model is loaded: seccomp, capabilities, non-root, admission);
`detection-engineering-standards` (**rule authorship and lifecycle**: Sigma, YARA, tests,
ATT&CK coverage. Here we say **which AI event must be emitted and which anomaly matters**; the rule
is written and governed there);
`incident-response-forensics-standards` (technical and forensic response to the compromise, chain of
custody, eradication and mass credential rotation);
`privacy-engineering-standards` (**personal data in training, model memorisation,
de-identification, data subject rights and how AI systems fit under GDPR/AI Act: already
covered — not duplicated here**. Membership inference appears in §3.5 as a **technical risk
class**; its treatment as a privacy risk is theirs);
`grc-compliance-standards` (management framework, SoA, audit evidence, formal risk
acceptance);
`ai-governance-standards` (AI Act as a regime, policies, inventory of
AI systems and organisational risk management. **Boundary: governance is theirs, the verifiable
technical control is mine.** If the answer is a signed document, it is theirs; if the answer is
running a scan or a signature verification, it is mine);
`mlops-standards` (the operational lifecycle of an in-house model —dataset versioning
with DVC/lakeFS, experiments in MLflow/W&B, model registry with *model cards*, states and
approval, training orchestration, *feature store*, canary deployment and weight rollback,
drift and retraining—. **This skill is its security face**: `mlops` defines the registry and
promotion between environments; I define how that chain is protected, signed, isolated and audited.
Reproducibility is a quality requirement there and a **security control here** (§3.10));
`local-inference-standards` (serving open weights on your own infrastructure: engine, quantisation,
sizing, endpoint security as a port);
`gpu-computing-standards` (the GPU as a resource: driver, MIG/MPS, accelerator isolation);
`data-platform-standards` (where the training data lives and its encryption at rest);
`iac-standards`, `identity-access-management-standards`, `bcdr-standards` (infrastructure,
identity and recovery of the ML environment).

## 2. Default decisions

> Verify the latest version and the maintenance status on the web before pinning anything (§8). This
> ecosystem has a high tool mortality rate and **repositories that get archived and moved**.

| Decision | Default | Reason |
|---|---|---|
| Weights format | **`safetensors`, whenever it exists** | Stores tensors only: no executable code, no deserialisation hooks. It is the only mass-use format designed to eliminate this attack class |
| Formats with arbitrary execution on load | **Vetoed without a sandbox**: pickle and everything wrapping it (`.pkl`, classic PyTorch `.pt`/`.bin`/`.ckpt`, `joblib`), and Keras models with `Lambda` layers | Pickle deserialisation **executes code by design**. The module's own documentation warns about it |
| `torch.load` over a not fully trusted source | **`weights_only=True`** (and verify your version's default) | Restricts what can be deserialised. It mitigates, **it does not eliminate** — there is research on evading restricted loaders |
| `trust_remote_code=True` | **FORBIDDEN by default** | Equivalent to running an arbitrary binary from the internet. There is a recent RCE CVE from hardcoding it (§3.2) |
| Source of the weights | **Internal replica with pinned digest**, not a direct hub download at runtime | A pull at deployment time against a public hub is a mutable dependency in the critical path |
| Artifact identification | **Cryptographic digest (SHA-256), never a tag or "latest"** | Same principle as container images. A tag is mutable |
| Signing and verification | **cosign/Sigstore over the model artifact**, verification **before loading** | Mechanics and key custody: `cicd-standards` and `cryptography-pki-standards` |
| Model scanning | **`picklescan` and/or `modelscan` as a gate**, with calibrated expectations (§3.2) | They are denylists: they detect what is known. **Necessary, insufficient** |
| Loading an unverified model | **Sandbox with no network and no credentials**, unprivileged user, read-only FS | Loading **is** execution. Containment: `container-runtime-security-standards` |
| Inventory | **AIBOM/ML-BOM in CycloneDX** for the pipeline; SPDX AI profile when the recipient is regulatory | See §3.4 on real maturity |
| Threat framework | **MITRE ATLAS** as the reference taxonomy, **complementing ATT&CK** | §3.8 |
| Application risk catalogue | **OWASP Top 10 for LLM Applications 2025** + **Top 10 for Agentic Applications 2026 (ASI01–ASI10)** | §3.8 |
| AI red teaming | **`garak`** (broad sweep, CI) + **PyRIT** (multi-turn campaigns) + **promptfoo redteam** (in PR) | §3.7 |

### Verified status of the tools (August 2026)

| Tool | Version | Date | Notes |
|---|---|---|---|
| `garak` (NVIDIA) | 0.15.1 | 2026-06-05 | **Alive**, active repo. Model-level probe scanner |
| **PyRIT (Microsoft)** | v1.0.1 | 2026-07-30 | ⚠️ **The repository moved**: `Azure/PyRIT` is **archived** (2026-03-27). The active one is **`microsoft/PyRIT`**. Any tutorial pointing at `Azure/PyRIT` is obsolete |
| `promptfoo` (redteam mode) | 0.121.20 | 2026-07-31 | Alive, high cadence. Governance: verify the acquisition by OpenAI (§8) |
| `picklescan` | 1.0.5 | 2026-07-01 | Alive. Integrated into the Hugging Face scanning pipeline |
| `modelscan` (Protect AI) | 0.8.8 | 2026-02-18 | ⚠️ **~6 months without a release.** Use it, but pin the version and do not take it as the sole control |
| `deepteam` | v1.0.4 | 2025-11-12 | ⚠️ **No releases in ~9 months.** Do not adopt for new work without re-evaluating |
| CycloneDX (spec) | 1.7 (2025-10-21), patches 1.7.1 (2026-06-02) | — | ECMA-424; verify the edition in force (§8) |
| SPDX (spec) | 3.0.1 (2024-12-17), **3.1-RC1** (2026-01-24) | — | The AI Profile lives in the 3.x line. ISO/IEC 5962:2021 codifies **SPDX 2.2.1**, not the current one |
| MITRE ATLAS | content **v2026.06** (2026-06-30), format **v6.0.0** | — | §3.8 |

## 3. Structure and conventions

### 3.1 The model as a software artifact

The three non-negotiable controls, in order:

1. **Provenance**: where it came from, who published it, which exact version, against which data it
   was trained (as far as that is knowable), and which licence it carries. Without recorded
   provenance there is no possible answer to "are we affected?" when the hub pulls a model.
2. **Integrity**: digest computed at ingestion and verified before each load. **It is always
   referenced by digest**, never by name or by tag.
3. **Signature**: the artifact is signed on entry into the internal registry and **the signature is
   verified before loading**, not only at deployment. A verification that only happens in the
   pipeline does not protect against substitution of the file in the store.

**Operational corollary**: the model registry is a **production-grade asset**, not a drawer of
`.ckpt` in a shared bucket. Least-privilege access control, audited writes, immutability of
published versions, and separation of who trains, who promotes and who deploys. An attacker with
write access to the registry needs no AI attack at all: they replace the file.

### 3.2 Third-party weights = third-party binaries

**Formats that execute code on load** (risk class: insecure deserialisation /
arbitrary execution):

- **Pickle and everything built on top of it**: `.pkl`, the classic PyTorch `.pt`/`.bin`/`.ckpt`,
  `joblib`. The mechanism is the protocol's own reconstruction hook — not a bug, **the
  design**. The pickle interpreter processes opcodes as they arrive, **without first validating that
  the file is intact**, which enables evasion techniques based on deliberately corrupted files.
- **Keras/TensorFlow with `Lambda` layers**: they execute arbitrary Python code embedded in the model.
  The problem is not exclusive to pickle.
- **`trust_remote_code=True`**: downloads and executes code from the model's repository. There is a
  recent CVE (**CVE-2026-6859**, InstructLab, verify) from hardcoding it in a training
  script: a malicious model on the hub was enough to achieve RCE on any user. **It
  requires no scanner evasion whatsoever: it is the functionality doing its job.**

**Recommended safe format**: **`safetensors`** — it stores tensor data only, with no code
or deserialisation hooks. It is the default choice and, when a model is published only in
pickle format, that is in itself a risk signal to evaluate (and, if accepted, the conversion to
safetensors happens **inside the sandbox**, not on the engineer's workstation).

**Model scanning — necessary, insufficient, and it must be said:**

- `picklescan` and `modelscan` work by **denylist** of dangerous functions. They detect
  what is known.
- Verified history of evasion: JFrog reported **three 0-days in `picklescan`** (fixed in
  0.0.31, Sept 2025), each one allowing detection to be bypassed; the **nullifAI** technique
  (ReversingLabs) evaded the hub's scanning with a deliberately broken pickle; and recent academic
  work (**ShadowPickle**) reports evasion of **ten scanners and four model hubs**.
- **A public hub that flags a model as "unsafe" normally does not block it**: it lets you
  download and run it at your own risk. The label is not a control.
- Consequence: **the scanner is a hygiene gate, not a guarantee.** The control that really
  bounds the damage is **isolation at load time** plus **preferring safetensors**.

**Verified real incidents** (use as an argument, not as an anecdote): malicious models have been
found on public hubs that open a reverse shell to an external IP when loaded; a year-on-year
increase on the order of **5×** in the upload rate of malicious models is reported; and in
February 2026, **341 malicious *skills*** were detected in a public registry of agent skills
distributing an infostealer. **The public repository of AI artifacts is today an active malware
distribution vector.**

### 3.3 The AI supply chain — the didactic case of 2026

The compromise of **LiteLLM on PyPI (March 2026)** is the canonical example that **the AI supply
chain breaks where any software supply chain breaks**. Verified chain:

1. **19 March**: the actor (**TeamPCP**) compromises the GitHub Actions of **Trivy** — an open-source
   security scanner. Since most pipelines reference Actions by **mutable tag
   instead of pinned commit SHA**, the organisations running Trivy in CI started
   executing the malicious code immediately.
2. Among the harvested credentials was the **LiteLLM PyPI publishing token**, whose
   pipeline invoked Trivy in a secret- and CVE-scanning script.
3. **24 March**: `litellm` **1.82.7** and **1.82.8** are published with a malicious payload. 1.82.8,
   ~13 minutes later, adds **persistence via a `.pth` file** (`litellm_init.pth`).
4. **The `.pth` mechanism is what must be understood**: Python's `site` module **executes** the
   contents of any `.pth` in `site-packages` during interpreter initialisation —
   **before any `import` and before any application code**. There is no need to import
   the library: `python --version` is enough to trigger it. The payload was doubly base64-encoded
   to reduce visibility to basic static analysis.
5. **Payload**: credential harvesting (more than 50 categories: SSH keys, AWS with IMDSv2 and Secrets
   Manager, GCP, Azure, Kubernetes, `.env`, shell history, git credentials, Docker
   registries, Terraform state), **lateral movement in Kubernetes** (reading secrets in all
   namespaces, creating privileged pods mounting the host filesystem) and a persistent
   backdoor via a user systemd service. Encrypted exfiltration (AES-256-CBC with a session key
   wrapped in RSA-4096) to a domain not affiliated with the project.
6. **Window**: ~40 minutes until quarantine on PyPI. Tens of thousands of installations are reported
   in that interval. The campaign continued with `telnyx` (27 March) and other registries.
7. **Who was not affected**: the deployments that **pinned dependencies** in a `requirements.txt`
   inside the official image.

**Lessons that become controls, not anecdotes:**

- **Pin by digest/SHA, not by tag**, for GitHub Actions as well as dependencies and base
  images. It is the control that separated the affected from the unaffected.
- **Installing a package is executing code.** There is no "install and then review".
- **A security scanner in your CI is a dependency with credentials.** The compromised link
  was a *defensive* tool. Apply the same criteria to it as to any other dependency.
- **Ephemeral publishing credentials** (OIDC / *trusted publishing*) instead of long-lived static
  tokens → `cicd-standards`, `secrets-management-standards`.
- **A host or CI job that installed the compromised artifact is treated as full credential
  exposure**, not as "check whether the package is present": mass rotation, hunting for
  persistence and review of activity in Kubernetes → `incident-response-forensics-standards`.
- The **catalogue precedent** is consistent: the CVEs and maintenance status of the ML stack
  (`torch`, `transformers`, inference servers, harnesses) are governed by
  `vulnerability-management-standards`; what is AI-specific is that **the weights and the data are two
  more links**, and no classic SCA covers them.

### 3.4 AIBOM / ML-BOM — real status, without optimism

A classic SBOM inventories neither weights, nor training data, nor the provenance of the model.
Hence the AIBOM. **Honest status as of August 2026: it is an emerging standard, not a mature one.**

- **CycloneDX** supports ML-BOM/AI-BOM and is the practical option for CI. Spec **1.7** published
  2025-10-21 (with 1.7.x patches in 2026), adopted as **ECMA-424**. It is the line with the most
  traction in tooling.
- **SPDX 3.x** defines an **AI Profile** and a **Dataset Profile** (model type, training
  method, data handling, explainability, limitations, energy consumption). Status:
  **3.0.1** (Dec 2024) with **3.1-RC1** (Jan 2026). **Warning**: the ISO/IEC 5962:2021 standard codifies
  **SPDX 2.2.1**, not the version with the AI profile — citing "SPDX is ISO" as proof of AIBOM
  maturity is incorrect.
- **Field reality**: the tool generates what the upstream model declared. If the publisher did not
  document data or licence, **the AIBOM comes out with gaps** — some generators explicitly score
  that incompleteness, and that score is the useful datum.

**Criteria**: generate an AIBOM because inventory is a prerequisite for everything else (and because
procurement is starting to demand it), but **do not treat it as a security control**. It is an
inventory, and an inventory with declared gaps. The control is still digest + signature + scan + sandbox.

### 3.5 Lifecycle attacks — risk class, indicator, mitigation

**Described as risk. Never as a recipe.**

| Class | Risk | Indicators | Mitigation |
|---|---|---|---|
| **Data poisoning** | Manipulating the training or fine-tuning corpus to degrade or bias the model | Anomalous contributions to the dataset; quality drift after retraining; duplicate or near-duplicate samples from a single source | Dataset provenance and access control; curation and review of external sources; anomaly/duplicate detection; **reproducibility so you can bisect which batch caused it** |
| **Model poisoning / backdoor** | Latent malicious behaviour triggered by a specific trigger | Discrepancy between aggregate metrics (good) and behaviour in specific cases; artifact without provenance | Only models with provenance and signature; evaluation with adversarial cases (§3.7 → `llm-evaluation-standards`); controlled retraining on verified data |
| **Retrieval corpus poisoning** | Inserting content into the base the system retrieves from | New documents with embedded instructions; retrieval spikes from a specific source | Write access control over the corpus; treat retrieved content as untrusted → `rag-standards`, `llm-app-engineering-standards` |
| **Unauthorised extraction / distillation** | Reconstructing model capability by querying its API en masse | Anomalous query volume per account; systematic or high-entropy queries; **many new accounts with a common pattern**; consumption spikes misaligned with product usage | Rate limits and quotas per user/organisation; anomalous-use detection; identity verification at sign-up; §3.6 |
| **Model inversion** | Reconstructing features of the training data from the outputs | Queries aimed at extracting memorisations; outputs that literally reproduce training fragments | Minimisation of training data and de-identification → `privacy-engineering-standards`; limit on output detail; output filtering |
| **Membership inference** | Determining whether a specific record was in the training set | Repeated queries about specific records | **See the realism note below.** Minimisation, avoiding overfitting, differential privacy when the risk justifies it → `privacy-engineering-standards` |
| **Adversarial examples** | Perturbed inputs that induce a wrong classification or behaviour | Error rate concentrated on inputs close to each other; inputs with imperceptible perturbations | Robustness as a requirement (AI Act art. 15); validation at the edge; out-of-distribution input detection; decision redundancy in critical uses |

**Realism note — laboratory versus production.** Distinguishing them is mandatory:

- **Query-based extraction is a threat demonstrated at industrial scale.** In February 2026,
  frontier providers disclosed extraction campaigns against their models (on the order of **10⁵
  prompts** in one campaign, and tens of thousands of fraudulent accounts generating millions of
  exchanges in another). **This is no longer theoretical: size your rate limits accordingly.**
- **Membership inference performs far worse than the headlines suggest.** Systematic
  work on pretrained models finds that most attacks **barely beat
  chance** when pretraining is ~1 epoch (little overfitting). It is **materially more
  relevant on finely tuned models or with heavily repeated data**. Treat it as a real risk
  but **conditioned on the training regime**, not as a universal threat.
- **Poisoning and backdoors are amply demonstrated in the laboratory**; their
  exploitation in production requires access to the pipeline or the artifact — which is exactly what
  §3.1–§3.3 protect. **The real mitigation is supply-chain, not ML.**

### 3.6 The deployed model as a surface

- **Rate limits and quotas per user and per organisation**, not just global. The global one does not
  stop an extraction campaign distributed across accounts.
- **Anomalous-use detection** as a first-class control: volume, entropy and systematicity of
  the queries, mass correlated account sign-ups, sweep patterns. What is logged and what
  alerts: §3.9; rule authorship belongs to `detection-engineering-standards`.
- **Identity verification and friction at sign-up** when the endpoint exposes valuable capability.
- **Watermarking: low preventive value.** It is a **forensic and post hoc** instrument:
  by the time you detect the mark, the substitute model is already trained. The current literature
  classifies it as an **attribution and litigation** tool, not a defence, and its robustness against
  distillation and paraphrasing remains the open problem. **Do not sell it internally as protection.**
- **Protection against unauthorised distillation**: the controls that work are the boring ones —
  limits, quotas, anomaly detection, enforceable terms of service and correlation between
  accounts. Technical defences (output perturbation, distillation resistance) are an active area
  of research, **not a product**. With the model publicly accessible, **there is no infallible
  barrier**: the realistic goal is to **raise the cost and detect**, not to prevent.

### 3.7 AI red teaming — methodology

**Hard precondition**: it runs inside an authorised exercise. **Written authorisation,
the RoE, the scope, the window, deconfliction, stop conditions and the report belong to
`offensive-security-standards` and are not improvised here.** What this skill contributes is the
AI-specific methodology.

**What distinguishes it from classic pentesting:**

- The target is not only code execution: it is **the behaviour of the system**. A failure can
  be an output, not a shell.
- **It is not deterministic**: an attack that works once may not repeat. A finding without a measured
  success rate over N attempts is not a finding, it is an anecdote → the measurement apparatus belongs to
  `llm-evaluation-standards`.
- The surface includes **data, weights, prompt, tools and memory**, not only network and application.
- **Two objectives that overlap but are not the same**: *safety* (harmful content, policy
  violation) and *security* (exfiltration, system compromise, unauthorised use of tools).
  Declare which one you are pursuing; the teams, the criteria and the report recipients differ.

**Recommended organisation** (aligned with industry practice and with the NIST AI RMF cycle
— *Govern, Map, Measure, Manage*):

1. **Map**: model the system and its risks based on ATLAS and the applicable Top 10 (LLM or ASI).
2. **Measure**: automate breadth — probe sweep in CI on every model deployment.
3. **Manage**: manual, multi-turn depth on what is critical, with a defined periodicity;
   mitigation and monitoring in production with a response plan.
4. **Handoff**: **every finding becomes a permanent case in the evaluation set**
   (`llm-evaluation-standards`) and, where appropriate, a detection rule
   (`detection-engineering-standards`). **A red team whose only result is a PDF is money
   burned**: half the value is in the regression it leaves installed.

**Tools in force** (versions in §2):

- **`garak`** — model-level probe scanner. Breadth and regression, cheap, fits in CI.
  Limited agentic and RAG coverage.
- **PyRIT** (`microsoft/PyRIT`, **watch out for the repository change**) — programmable orchestration of
  multi-turn campaigns. Depth on critical applications.
- **`promptfoo` in redteam mode** — adversarial regression in the PR, with presets mapped to the OWASP
  Top 10.
- **They never replace systematic measurement.** Red teaming is directed exploration; coverage and
  the threshold are evaluation.

**Forbidden**: including in internal documentation ready-to-use payloads, specific jailbreaks for
third-party products or specific guardrail bypasses. What is documented is **the class of technique, the
indicator and the mitigation**, with a reference to the framework identifier (e.g. the corresponding
ATLAS technique).

### 3.8 Frameworks

- **MITRE ATLAS** — the ATT&CK of AI. Knowledge base of tactics, techniques, mitigations and
  real cases against AI systems (`AML.T*`, `AML.M*`, `AML.CS*`).
  - **Relationship with ATT&CK: it complements, it does not replace.** It reuses the model and much of the
    tactics of ATT&CK and adds those specific to the AI domain. **Both are used together**: ATT&CK for
    the enterprise part of the intrusion, ATLAS for the AI surface.
  - **Verified status**: since May 2026 the project **separated the versioning of content and
    format**. The **content** follows a `YYYY.MM.N` scheme — latest verified release
    **v2026.06** (2026-06-30). The **data format** follows SemVer, **v6.0.0**, which introduced a
    `platforms` field on all techniques (`Predictive AI`, `Generative AI`, **`Agentic AI`**,
    `Enterprise`), Pydantic validation schemas and a REST API. Previous releases used conflated
    SemVer (v5.6.0, May 2026).
  - **Practical implication**: if your tool or your Navigator layer consumes the old format's
    `ATLAS.yaml`, **the move to v6.0.0 affects you**. Filter coverage by `platforms` so you do not
    claim agentic coverage you do not have.
  - Recent content incorporates real cases from the agentic wave (exfiltration via indirect
    injection in productivity assistants, model extraction, AI services as a C2 relay,
    RCE in agent framework plugins).
- **OWASP GenAI Security Project** — **two lists, and the right one must be used**:
  - **Top 10 for LLM Applications 2025** (`LLM01:2025`–`LLM10:2025`). **Verified: it remains the
    edition in force; there is no 2026 edition.** Applies to chatbots, copilots and RAG.
  - **Top 10 for Agentic Applications 2026** (`ASI01`–`ASI10`): Agent Goal Hijack, Tool Misuse &
    Exploitation, Agent Identity & Privilege Abuse, **Agentic Supply Chain Compromise**, Unexpected
    Code Execution, Memory & Context Poisoning, Insecure Inter-Agent Communication, Cascading Agent
    Failures, Human-Agent Trust Exploitation, Rogue Agents. It **extends** the LLM one, it does not
    replace it: ASI04 covers dynamic composition at runtime where LLM03 covered the static chain
    prior to deployment. Agent design against these risks belongs to `ai-agents-standards`;
    here, the supply-chain part (ASI04) and the execution part (ASI05).
- **NIST AI RMF** — **AI RMF 1.0** (`NIST AI 100-1`, January 2023) remains the base document;
  **there is no published 2.0**. The generative AI profile **`NIST AI 600-1` is still the one from
  July 2024, unrevised**. The 2026 activity is **additive**: critical infrastructure profile
  (concept paper, April 2026), cybersecurity overlays for AI systems (COSAiS,
  single- and multi-agent), and a standards initiative for agents via CAISI (February 2026). **Its
  practical usefulness is the Govern/Map/Measure/Manage cycle as the skeleton of the programme**, not as a
  technical catalogue: its threat model predates the agentic era.
- **AI Act (EU) — security part, art. 15**: high-risk systems must reach an
  appropriate level of **accuracy, robustness and cybersecurity**, with the accuracy metrics **declared
  in the instructions for use**, and resilience against attempts to alter their use, outputs or
  performance — **explicitly citing data and model poisoning, adversarial examples and
  confidentiality breaches**. The required level is **contextual** (purpose, state of the art,
  risk), not a universal percentage. ⚠️ **The timetable is in dispute**: the application date
  of the high-risk obligations (2 August 2026 under the original text) may have
  shifted because of the *Digital Omnibus* package — **verify in the primary source before committing to
  a date** (§8). **The regime, the inventory and risk classification belong to
  `ai-governance-standards`; here only the technical control that satisfies
  art. 15.**

### 3.9 Detection and response applied to AI

**What is logged** (minimum, correlatable and with a defined retention):

- **Artifact lifecycle**: download or ingestion of a model (source, digest), signature
  verification (success **and failure**), loading of a model into a process, and **every write to the
  model registry**.
- **Pipeline**: who launched a training run, on which dataset version, with which image, and which
  artifact it produced.
- **Inference endpoint**: caller identity, volume, tokens, latency, tools
  invoked, guardrail rejections, and authorisation errors.
- **Agent**: tool calls, network destinations, irreversible actions and approvals.

**What alerts** (symptoms, not noise):

- Signature verification failure or **loading of an artifact with an unknown digest**.
- Write to the model registry outside the authorised pipeline.
- Query pattern consistent with extraction (§3.6) or correlated account sign-ups.
- Jump in the guardrail rejection rate (sign of a jailbreak campaign) **or a sudden drop to zero**
  (sign of a broken or evaded guardrail).
- Egress from the inference process or from the load sandbox towards a disallowed destination.
- Installation in CI of a dependency version outside the pinned list.

The **authorship, testing and lifecycle** of these rules belong to `detection-engineering-standards`; the
**response and forensics** to the compromise, to `incident-response-forensics-standards`.

### 3.10 Training pipeline security

- **Who can touch the data**: minimal and audited access to the dataset; separation between who
  contributes data, who trains and who promotes the model.
- **Reproducibility as a security control**, not only a quality one: without being able to reproduce a
  training run you cannot bisect which data batch introduced the anomalous behaviour. Version
  dataset, code, configuration and image, and record the triple in the resulting artifact.
- **Compute isolation**: training and, above all, **the loading of unverified models**
  run in environments without production credentials, without access to the management plane and with
  restricted egress. The training node usually has very broad storage credentials:
  it is a high-value target.
- **Chain of custody of the artifact** end to end: training → registry (signed) →
  deployment (verified). Every hop, audited.
- **Personal data in training**: legal basis, minimisation, retention and rights belong to
  `privacy-engineering-standards`. Here only the protection of the store and of access.

## 4. Quality and CI gates

Increasing order of cost. The first ones break the build.

1. **Verified dependency pinning** (seconds, **breaks the build**): no GitHub Action, base
   image or dependency referenced by mutable tag. It is the control that separated the affected from the
   unaffected in §3.3.
2. **Secret scanning** (seconds, **breaks the build**) → `cicd-standards`,
   `secrets-management-standards`.
3. **SCA of the ML stack** (minutes, **breaks the build** at critical severity): training and
   inference dependencies. Triage and SLA: `vulnerability-management-standards`.
4. **Weights format policy** (seconds, **breaks the build**): no artifact in a format with
   arbitrary execution enters the registry without an approved and recorded exception. No
   `trust_remote_code=True` in the code.
5. **Model scanning** (`picklescan`/`modelscan`) over every ingested artifact (minutes,
   **breaks the build**). With the right expectation: it detects what is known (§3.2).
6. **Signature and digest verification before promoting and before loading** (seconds, **breaks the
   deployment**).
7. **Generation and publication of the AIBOM** as a release artifact (minutes): inventory, with its
   declared gaps.
8. **Red teaming sweep** with `garak` on every model deployment (minutes, **breaks the
   promotion** by an agreed threshold) — the threshold and variance management belong to
   `llm-evaluation-standards`.
9. **Deep multi-turn campaign** (PyRIT) with a defined periodicity, within the RoE
   (`offensive-security-standards`), **pre-release** for high-risk systems.
10. **Coverage verification against ATLAS and the applicable Top 10** (periodic review, not a gate):
    filtered by `platforms` so as not to claim non-existent agentic coverage.

## 5. Stack security

In addition to everything above, which is already §5 de facto:

- **Least-privilege inference runtime**: non-root, read-only FS, capabilities
  dropped, seccomp, no production credentials in the process that loads the model →
  `container-runtime-security-standards`, `kubernetes-standards`.
- **Filtered egress** from the training node and from the inference runtime. It is the control
  that turns a malicious load into a failed attempt, and the one that cuts exfiltration.
- **Segregation by trust**: an unverified third-party model does not share a namespace, node or
  credentials with production workloads.
- **Zero-trust between services** (mTLS, workload identity) in the ML plane as in
  any other → `identity-access-management-standards`, `networking-standards`.
- **Input and output guardrails** at the endpoint: they are defence-in-depth mitigation, **not a
  perimeter**. They are tested with red teaming and their activation rate is watched (§3.9).
- **Backups of the model registry and the dataset**, encrypted and immutable, with tested restore
  → `bcdr-standards`, `backup-recovery-standards`. Retraining from scratch can cost more than
  any other state recovery plan.

## 6. Performance and operability

- **Cost of scanning**: an artifact of tens or hundreds of GB is not scanned in the critical path
  of the deployment. Scan **at ingestion** into the internal registry, once only, and **verify the digest**
  on every use.
- **Internal cache of verified artifacts** keyed by digest. It eliminates the download from the public
  hub at runtime, which is both a security and an availability risk.
- **Red teaming budget**: the CI sweep is sized (number of probes × cost per
  call) or it will be cut on its own. Deep campaigns are planned by quarter, not by sprint.
- **False positives from the model scanner**: if the gate produces noise, the exception is documented with
  an owner and an expiry. A permanent exception without an owner is the gate disabled with more steps.
- **Programme metrics**: % of artifacts with provenance and signature, % ingested in a safe format,
  time from a model's publication to its verification, ATLAS coverage filtered by
  platform, red team findings converted into evaluation cases.

## 7. Long-term sustainability

- **Cadence**: review the mapping to ATLAS and the applicable Top 10 every quarter (ATLAS publishes
  content **monthly**); review the maintenance status of the scanning and red teaming tools
  every half-year; re-evaluate the model inventory at every release.
- **Deprecation**: a model no longer served is retired from the registry with its AIBOM archived, it is not
  left "just in case" — every live artifact is surface.
- **Conscious debt**: every exception to the format or signing policy is recorded with a reason,
  an owner, a compensating control and an **expiry date**.

### PROHIBITIONS

- ❌ **FORBIDDEN to load third-party weights without verifying provenance, digest and signature.**
- ❌ **FORBIDDEN `trust_remote_code=True`** without an approved exception, a sandbox and a record. It is
  execution of arbitrary third-party code.
- ❌ **FORBIDDEN to reference models, images, Actions or dependencies by mutable tag or `latest`.**
  Digest or SHA. It is the direct lesson of the §3.3 incident.
- ❌ **FORBIDDEN to load an unverified model outside a sandbox** with no network and no credentials. The
  load is execution.
- ❌ **FORBIDDEN to treat a model scanner as a guarantee.** It is a denylist with a
  documented history of evasion.
- ❌ **FORBIDDEN to treat a public hub's "unsafe" label as a block.** It is not one.
- ❌ **FORBIDDEN to download weights from a public hub at deployment time.** Internal replica.
- ❌ **FORBIDDEN to give production, management plane or model registry credentials to the
  process that loads or trains.**
- ❌ **FORBIDDEN to use long-lived static tokens to publish artifacts.** OIDC / trusted
  publishing.
- ❌ **FORBIDDEN to present watermarking as protection against distillation.** It is forensic and
  post hoc; selling it as a defence is misinforming whoever accepts the risk.
- ❌ **FORBIDDEN to run AI red teaming without written authorisation and RoE** →
  `offensive-security-standards`. No technical or urgency exception.
- ❌ **FORBIDDEN to document ready-to-use payloads, specific jailbreaks for third-party products or
  specific guardrail bypasses.** Class, indicator and mitigation.
- ❌ **FORBIDDEN to report a red team finding without a success rate over N attempts.** The system is
  not deterministic; an isolated success is not a finding.
- ❌ **FORBIDDEN to close a red team exercise without converting the findings into permanent
  evaluation cases** (`llm-evaluation-standards`) and, where applicable, into detection rules.
- ❌ **FORBIDDEN to treat the AIBOM as a security control.** It is inventory, with gaps.
- ❌ **FORBIDDEN to rely only on global rate limits** against extraction: the campaign is
  distributed across accounts.
- ❌ **FORBIDDEN to assume that a security scanner in your CI is trustworthy because it is defensive.** The
  compromised link of 2026 was exactly that.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web —and, for versions and dates, **via
`api.github.com`, PyPI/npm or Atom feeds, never via an HTML summariser**:

1. **MITRE ATLAS**: content release in force (verified: **v2026.06**, 2026-06-30) and the version of the
   **format** (verified: **v6.0.0**, with a `platforms` field). Check whether your tooling consumes the
   old format. **Also verify the exact count of tactics, techniques, mitigations and cases
   directly at `atlas.mitre.org`** — see the declared gap below.
2. **OWASP GenAI**: confirm that the LLM list in force is still the **2025** one (verified: no
   2026 edition) and the status of the **Agentic Applications 2026 (ASI01–ASI10)** one, plus any
   new list from the project (there is active work on agentic *skills* and agent memory).
3. **NIST**: whether `AI 100-1` is still at 1.0 and `AI 600-1` is still the July 2024 one (verified as of
   August 2026); status of the **COSAiS** overlays, of the critical infrastructure profile and of the
   CAISI agent standards initiative.
4. **AI Act**: **application date in force** of the high-risk obligations and of article 15,
   in the primary source (EUR-Lex or the Commission's AI Act Service Desk). **The *Digital Omnibus* may
   have shifted the timetable; do not commit to a date without checking it.**
5. **Weights formats**: whether `safetensors` is still the recommended safe one, the default
   behaviour of `weights_only` in your PyTorch version, and whether new evasion classes for restricted
   loaders have appeared.
6. **Scanning and red teaming tools**: version and activity of `picklescan`, `modelscan`,
   `garak`, **`microsoft/PyRIT`** (⚠️ `Azure/PyRIT` has been archived since 2026-03-27) and `promptfoo`.
   **Rule: more than 6 months without a release in this ecosystem is a sign of abandonment, not of stability.**
7. **AIBOM**: edition in force of **CycloneDX** (verified: 1.7 of 2025-10-21, 1.7.x patches in 2026;
   ECMA-424) and of **SPDX** (verified: 3.0.1, with 3.1-RC1 of 2026-01-24), and which tool generates
   which version in practice.
8. **Incidents**: verify in the primary source before citing them —the LiteLLM project's own
   advisory, Trivy's and the PyPI bulletins— and check whether there are later incidents from the
   same campaign or from other AI artifact hubs.
9. **ML stack CVEs**: not listed here. They come in through `vulnerability-management-standards`.

### Declared gaps (not verified in this drafting)

- **Exact ATLAS count** (tactics, techniques, mitigations, cases): the figure in circulation
  (~16 tactics / ~170 techniques / ~35 mitigations / ~57 cases) comes from **secondary blog
  sources** and **is not verified in the primary source**. The releases are verified via API. **Do
  not use the count in a report without checking it at `atlas.mitre.org`.**
- **CVE-2026-6859 (InstructLab, `trust_remote_code`)**: cited from a secondary source; **not
  verified in NVD**. Verify before using it as a formal reference.
- **Exact figures of the LiteLLM incident** (number of installations in the window, credentials
  potentially exposed): they vary between analysts. The **chain of events and the `.pth` mechanism**
  are corroborated by multiple independent sources, including the project's advisory; **the
  figures are not**. Use the mechanism as an argument; the figures, with reservations.
- **Acquisition of `promptfoo` by OpenAI (March 2026)**: secondary source, **not confirmed in a
  primary source**. Relevant as a governance risk if you evaluate rival models.
- **Status of `gitleaks` as *feature complete*** and other maintenance precedents in the catalogue:
  **not verified in this drafting**. Consult the corresponding skill
  (`secrets-management-standards`) before asserting it.
- **Effective application date of AI Act article 15**: **in dispute** between the original
  timetable (2026-08-02) and the possible shift from the *Digital Omnibus*. Not verified in a primary
  source. Do not set compliance dates based on this document.
- **Maturity of anti-distillation defences** beyond limits and detection: an active research
  area with no established product. None is recommended specifically, on purpose.

If the web contradicts this document, **the web wins** — flag the discrepancy.
