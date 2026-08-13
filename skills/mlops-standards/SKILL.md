---
name: mlops-standards
description: Use when the lifecycle of a model you train and own runs as production engineering — versioning datasets and training runs with DVC or lakeFS, tracking experiments in MLflow or Weights & Biases, promoting artifacts through a model registry with model cards, stages and approval, orchestrating training pipelines with Airflow, Kubeflow, Metaflow, Prefect or Dagster, a feature store (Feast) and train/serve skew, batch versus online versus streaming serving with shadow and canary rollout and model rollback to the previous weights and preprocessing, detecting data drift versus concept drift with Evidently when the label arrives late or never, proxy metrics and feedback loops where the model shapes its own future data, retraining triggered by schedule, threshold or event, training versus inference cost, model retirement, or fairness and bias measured as a system property.
---

# MLOps standards — the model lifecycle as production engineering

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when you **train, register, deploy, monitor, retrain and retire a model of your own**:
classical ML (tabular, series, vision, text), *fine-tuning* of an open model, or any
trained artifact whose behaviour depends on data you control. It covers data as a
versioned artifact, experimentation, the model registry as the boundary into production,
the training pipeline, *features* and *skew*, deployment and *rollback*,
production monitoring (drift, *proxy* metrics, feedback loops), retraining, cost and retirement.

Triggers: "the model has got worse", "retrain", "drift", "data drift", "concept
drift", "train/serve skew", "feature store", "model registry",
"promote to production", "model card", "version the dataset", `dvc.yaml`, `.dvc`, `dvc repro`, `lakectl`,
`mlflow.log_metric`, `mlflow.register_model`, `MLmodel`, `MLproject`, `wandb.init`, a training
`dag.py`, `KFP`/`@dsl.pipeline`, Metaflow's `@step`, `@flow`/`@task`, `@asset`,
`feature_store.yaml`, `get_historical_features` vs. `get_online_features`, `Evidently`,
`predict_proba` in a nightly batch, *shadow deployment*, "go back to the previous model", "the label
takes weeks", "the notebook we trained the good one with", inference cost per prediction,
bias and *fairness* measured.

**Domain thesis — it applies throughout this document**: **an ML system does not fail the way
software fails; it degrades silently with the code untouched.** Three consequences that order the rest:

1. **The code is the small part.** Most of the system is data, configuration,
   *feature* extraction, verification and monitoring — the "hidden technical debt" of ML.
   An impeccable repo with a data pipeline without contracts is a fragile system.
2. **The input changes on its own.** Nobody deploys and yet accuracy falls: the world changed,
   the data provider did, or user behaviour did. Without monitoring the **data**, the
   first signal is a business complaint months late.
3. **Reproducibility is a functional requirement, not hygiene.** If you cannot rebuild the model
   serving today — data, code, hyperparameters, environment, seed — you cannot
   debug it, audit it or roll it back. And sooner or later you will have to do all three.

**Not applicable**:

- `timeseries-db-standards`: **the time-series engine and its retention policy are
  theirs**, and that policy is a **constraint on this skill, not a storage detail**:
  the *rollup* that lowers the resolution of the history destroys the training set and with it
  the reproducibility required here. Rule: **before accepting a downsampling, declare which
  signals feed a model and keep them raw**; if that is not possible, the model stops being
  rebuildable and that is recorded as debt, not discovered at retraining time.
- `data-engineering-standards`: **the data pipeline that feeds the model
  is theirs** — ingestion, ELT, idempotency, *backfill*, Parquet, scan cost, freshness and
  data observability. They share the orchestrator (Airflow, Dagster, Prefect) and that is inherent
  overlap, not an ownership question. **Arbitration rule: if the artifact produced is a table
  consumed by people or BI, it is theirs; if it is a trained model or the *features* that feed it, it
  belongs to this skill.** The *feature store* and *train/serve skew* belong here.
- `classical-ml-standards`, `deep-learning-standards` and `model-finetuning-standards`
  (**a "before and after" boundary**): **how a model is trained and evaluated is theirs**
  — splitting and data leakage, validation, metrics and calibration, decision threshold, the
  training loop, and the order prompt → retrieval → **fine-tuning**; **the production lifecycle
  belongs here**: registry, versioning, *feature store*, deployment, drift, retraining
  and *train/serve skew*. Correction to this skill: where it said that *"a fine-tuning of your own
  crosses into this skill"*, **the fine-tuning criteria now belong to `model-finetuning-standards`**;
  what still belongs here is the registration, promotion and operation of the resulting artifact.
- `r-standards` and `julia-standards`: **the model lifecycle belongs to this
  skill** — registry, versioning, *feature store*, deployment, drift monitoring,
  retraining, *train/serve skew* — **regardless of the language it is trained in**;
  **how that R or that Julia is written** — `renv` and library reproducibility, type
  stability, tests, style, packaging — belongs to those skills. The dangerous case both sides must
  recognise: **an exploratory analysis that becomes a service without being rewritten** is debt
  that is collected here, in production.
- `data-warehouse-modeling-standards`: grain, facts and dimensions, SCD,
  conformed dimensions and the canonical definition of a business metric. **A *feature*
  table is not a mart** and is not governed by its modelling; but if your *features* derive from
  marts, their grain and their historisation belong there.
- `llm-app-engineering-standards` (*the most common confusion in this domain,
  and it is declared explicitly*): **building a product on top of a third-party LLM is not MLOps.** You
  do not train anything, you have no weights, there is no drift of *your* model but rather version
  changes from the provider, and the "model registry" is a string in a configuration file. There live
  versioned prompts, structured output, the context window, caching, retries and spend limits.
  **Arbitration rule: if the artifact you promote is weights you produced, it belongs to
  this skill; if it is a prompt and someone else's model identifier, it is theirs.** A *fine-tuning*
  of your own crosses into this skill; calling a model fine-tuned by the provider does not.
- `llm-evaluation-standards`: **quality measurement is theirs** — evaluation
  sets, LLM-as-judge and its calibration, deterministic assertions, significance, CI regression
  gates, trace annotation. Here, evaluation is **required as a gate** (§4) and it is defined
  **what gets recorded so that it is reproducible and comparable between model versions**; the
  methodology of measuring lives there. Fine boundary: **they produce the number, the decision to
  promote or roll back with that number belongs here.**
- `mlsecops-standards`: the **adversarial and model supply chain** side — provenance and integrity of
  third-party weights, `safetensors` versus formats with `pickle`, `trust_remote_code`,
  `picklescan`/`modelscan`, artifact signing and digest pinning,
  AIBOM/ML-BOM, data and weight poisoning, *backdoors*, extraction, inversion and membership
  inference, *red teaming* with `garak`/`PyRIT`, and the mapping to MITRE ATLAS and OWASP
  GenAI. Here, **lifecycle operations**. Shared boundaries, resolved thus: **the
  artifact format and digest pinning are required by this skill as a reproducibility requirement
  and reasoned about there as a threat**; insecure deserialization (§5) and supply chain
  incidents are **stated here as an operational prohibition** and **analysed there**. If the
  question is "can I be attacked through here?", it is theirs; if it is "how do I deploy and monitor
  it?", it belongs to this skill.
- `ai-governance-standards`: **it decides and answers for it; here it is
  operated.** The **model registry** (artifacts you train and serve, with their metrics and their
  lineage) belongs to this skill; the **AI system inventory** — which includes third-party tools
  you do not operate, SaaS with embedded AI and shadow AI — is theirs. AI Act risk
  classification, human oversight as an obligation, impact assessment and
  accountability are theirs; **fairness as a measurable property of the system belongs here**
  (§6.5) — you produce the number, they decide which threshold is acceptable and who signs it.
- `data-platform-standards`: the **store** — PostgreSQL, Kafka, partitioning, replicas, PITR,
  engine retention. Here, the dataset **as a versioned and reproducible artifact**, not the
  database that hosts it.
- `object-storage-standards`: **where datasets and artifacts live** (S3/MinIO/Ceph), object
  versioning, storage classes, lifecycle and egress cost. A *checkpoint* of
  tens of GB per experiment has a bill: the bucket's retention criteria are theirs.
- `sre-practice-standards`: SLOs, error budget, on-call and *capacity planning* for the **service**
  that serves the model. Here, the metrics **of the model**, which a latency SLO does not see: a
  service with 99.99% availability can be serving garbage predictions.
- `cicd-standards`: the **generic pipeline** — runners, OIDC, SBOM, signing, gates. Here, which
  ML-specific gate it adds (§4) and why "the tests pass" does not mean "the model works".
- `kubernetes-standards` (manifests, Helm, GitOps for the deployment), `gpu-computing-standards`
  (**the GPU as a resource**: driver, MIG, DCGM, cost and cooling — here only the job that
  uses it), `local-inference-standards` (**serving open models**: vLLM, quantisation, KV cache
  — if you serve open weights without training them, that skill rules), `observability-standards` (OTel,
  Prometheus, alerts — here only **which** model metric matters), `iac-standards`,
  `python-standards` (training code as production code),
  `incident-management-standards` (a degraded model causing impact **is an incident** and is
  managed there), `bcdr-standards`, `identity-access-management-standards`,
  `secrets-management-standards`, `vulnerability-management-standards` (triage and SLA for the §5
  CVEs), `privacy-engineering-standards` (**personal data in training, minimisation,
  memorisation, DPIA** — if the dataset has PII, the lawful basis and the retention are decided
  there, not here), `grc-compliance-standards` (management framework and audit evidence),
  `rag-standards` and `ai-agents-standards` (the application layer), `mcp-standards`.
- **`claude-api`** (no `-standards` suffix, **an installed skill, the canonical reference for the
  Anthropic side**): model IDs, prices, parameters, caching, batches. **No datum about Claude models
  is asserted from memory**; if you compare the cost of training and serving your own against a
  managed API, the Anthropic side comes from there.

## 2. Default decisions / Toolchain

> Verify the latest version, the licence and the project's status on the web before committing to it
> in a real project (§8). **This ecosystem changes owner and licence frequently**: in
> recent months lakeFS (Treeverse) absorbed DVC and Prefect bought Dagster (§7).

| Decision | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Dataset versioning (small/medium project, files) | **DVC 3.67.x** (Apache-2.0). **Change of ownership**: lakeFS/Treeverse acquired the project from Iterative.ai (announced Nov-2025); the repo now lives at `treeverse/dvc`. Licence unchanged | A `git-lfs` with no lineage or pipeline: it versions the file, not the experiment |
| Dataset versioning (data lake, scale, many consumers) | **lakeFS 1.85.x** (Apache-2.0): branches and *commits* over the object storage itself | Table formats with *time travel* (Iceberg/Delta) if the data already lives there — **it is the cheapest option and often the right one**: do not add a new piece if your store already versions |
| Experiment tracking | **MLflow 3.15.x** (Apache-2.0) — de facto the standard, self-hostable, with an integrated registry | **Governance warning**: MLflow has been in the Linux Foundation since 2020, but development and direction remain dominated by Databricks. No governance change was located in 2026 (**declared gap, §8**): treat it as a de facto *single-vendor* project and weigh that risk before marrying it |
| Managed tracking alternative | **Weights & Biases**: MIT client SDK, **proprietary/SaaS server**. Excellent product, real *lock-in* | Do not confuse "open source SDK" with "open source platform". If the requirement is self-hosting without a commercial licence, it is not a candidate |
| Model registry | **MLflow**'s unless a requirement rules it out | A home-made registry in a table: it ends up with no *lineage*, no approval and nobody to maintain it |
| Orchestration (the team already has Airflow) | **Apache Airflow 3.3.x** (Apache-2.0) | **Do not introduce a new orchestrator just for ML.** The operational cost of a second platform is almost never paid for by the benefit |
| Orchestration (data science team, Python first) | **Metaflow 2.19.x** (Apache-2.0, Netflix): the one imposing the least ceremony per unit of value | Prefect 3.8.x / Dagster 1.13.x (both Apache-2.0): **Prefect announced the acquisition of Dagster Labs on 13-Jul-2026** (combined Prefect brand since Aug-2026; Dagster and Dagster+ keep their name, price and roadmap) — two products, one owner; demand a convergence plan before adopting either for the long term |
| Orchestration (you already live in Kubernetes and operate it well) | **Kubeflow Pipelines** (Apache-2.0, v1.10.x) | **Full Kubeflow is the piece that most often weighs more than it contributes**: without a dedicated platform team, it is a platform that operates you |
| Feature store | **None by default.** It is added when there is measured *skew* or *real reuse* of features between teams | **Feast 0.65.x** (Apache-2.0) if justified. A feature store for one team and three models is free complexity: the same result is achieved with **a single shared transformation function** imported by training and inference |
| Model monitoring | **Evidently** (Apache-2.0) for drift and data quality, exporting to Prometheus/OTel | **Verify activity**: the last release observed in the feed was Mar-2026 — check maintenance before adopting it (§8). WhyLabs: verify status and licence model before recommending it |
| Online serving | **KServe 0.19.x/0.20.x** (Apache-2.0) if there is already Kubernetes; **BentoML 1.4.x** (Apache-2.0) if not | **Seldon Core v2 has been under the Business Source License 1.1 since Jan-2024 — it is NOT open source**: use in commercial production requires a paid licence. `Change License` to Apache-2.0 four years after each release. **Discarded by default**; if it appears in a legacy architecture, it is debt with an invoice |
| Artifact format | **ONNX** or **safetensors** when the framework allows it | **`pickle`/`joblib` is arbitrary code execution on load** (§5). If it is unavoidable, the artifact is signed and its origin is a registry with access control |
| Model documentation | A **model card**, mandatory as a condition of registration (§3.3) | Format: the *hub*'s structured YAML + narrative. **There is no normative standard with traction**: the metadata layer (YAML, Croissant for datasets) is standardised and automated; the narrative (limitations, bias, provenance) is the worst-covered part of the ecosystem — precisely the one you will be asked for in an audit |

**Adoption rule**: every piece in this table costs operations, upgrades and CVEs. The
default architecture for a small team is **git + a versioned object store + MLflow
+ the orchestrator you already use + a monitoring job**. Everything else earns its place with a
measured problem, not with a reference diagram.

## 3. Structure and conventions

### 3.1 Reproducibility — the requirement, not the aspiration

A model in production does not exist if you cannot rebuild it. **Five axes, all mandatory**:

| Axis | How it is pinned | Typical failure |
|---|---|---|
| **Data** | An immutable snapshot identified by hash/commit/table version, not by path or by a `WHERE date > ...` run today | "The dataset" is a query that returns something different every day |
| **Code** | A git commit, with a clean tree. CI refuses to train from a dirty tree | It was trained with uncommitted local changes |
| **Hyperparameters and config** | A versioned file in the repo, not hand-typed command-line arguments | The good value lives in somebody's shell history |
| **Environment** | A lockfile (`uv.lock`, `poetry.lock`) **and** a container image by digest; CUDA/driver version noted | "It worked with the previous version of the library" |
| **Seeds and non-determinism** | A seed fixed and recorded; **and documented what remains non-deterministic** (GPU, parallelism, data order) | Promising bit-for-bit what the hardware does not give: the **tolerance** is recorded, not a false equality |

**The central antipattern: "the notebook that trained the good model".** A notebook has
hidden state, non-reproducible execution order, implicit dependencies and does not go through review.
It is good for exploring; **it is not the training artifact**. The hard rule: *the model serving
production was produced with a pipeline run by CI/the orchestrator from a commit*, and the notebook
— if it exists — is a disposable annex. A notebook on the critical path is a *bus factor* of one.

### 3.2 Reference layout

```
project/
  pipelines/          # pipeline definition (dvc.yaml / flow.py / dag.py)
  src/
    features/         # transformations — IMPORTED by training and inference (§3.5)
    training/
    inference/
  conf/               # versioned hyperparameters and config
  tests/
    test_data_contract.py   # schema, ranges, nulls, cardinality
    test_features.py        # transformation invariants
    test_model_contract.py  # I/O shape, latency, known cases
  notebooks/          # disposable exploration, off the critical path
  model_card.md
```

### 3.3 Model registry — the boundary into production

The registry is **the only path to production**. An unregistered artifact is not deployed.
Minimum metadata, without which the registry rejects the version:

- **Lineage**: code commit, dataset version/hash, hyperparameter config, environment image
  by digest, and the ID of the run that produced it.
- **Metrics** of evaluation over a **frozen and versioned** test set, and over the
  relevant **segments** (not just the aggregate: the mean hides the subgroup where it fails).
- **An identifiable owner** (person or team), not a generic mailbox.
- **Purpose and scope of use**: what it was trained for and **what it must not be used for**.
- **Known limitations**: under-represented populations, valid input range,
  assumptions whose violation invalidates the model.
- **A linked model card** (§2). Without it, it is not promoted.

**Promotion by stages** (`dev` → `staging` → `production` → `archived`) with **explicit and recorded
human approval** at the jump into production. The approval is signed by someone who can
explain what the metric measures; it is not a button. Every promotion and every rollback is left in an
immutable log: that is the evidence audit will ask for and the one you will need at 3 in the
morning.

### 3.4 Training pipeline

Explicit and cacheable stages: `ingestion → validation → features → training → evaluation →
registration`. Criteria, not a catalogue:

- **Data validation is a stage that fails the pipeline**, not a warning. Schema contract,
  ranges, nulls, cardinality and expected distribution. *Garbage in* is not detected afterwards.
- **Evaluation decides registration**: if the new model does not beat the production one on the
  frozen set **and on every monitored segment**, it is not registered. The comparison is against the
  production model, not against the previous run.
- **Idempotency and resumability**: a stage re-run with the same inputs produces the
  same thing or reuses the cache. A pipeline that must be run in full because of a failure in the last
  stage is a pipeline nobody runs.
- **A pipeline is not a pretty DAG**: if the orchestrator forces you to write more glue
  code than your logic contains, you chose badly. It is a signal to adopt what you already operate.

### 3.5 Features and *train/serve skew*

The most expensive and most silent failure of ML in production: **the same feature is computed
differently in training and in inference**. Typical cases: the mean is computed over the whole
history in training and over a sliding window in production; a `NULL` is imputed differently; the
training uses a value that does not yet exist at prediction time (**temporal leakage**
— the model evaluates wonderfully and in production is worth nothing).

**Order of solutions, cheapest to most expensive**:

1. **A single implementation of the transformation**, imported by both paths. It solves
   most cases and costs zero infrastructure.
2. **Logging the feature computed at prediction time** and comparing it offline
   against the one recomputed in training: it detects the *skew* even if you do not prevent it.
3. **A feature store** (Feast): it makes sense when there is **real reuse between teams**, or when
   you need *point-in-time correctness* over history (`get_historical_features`) because
   avoiding temporal leakage by hand is unfeasible. Outside that case it is two more stores to operate
   and synchronise. **The offline/online synchronisation is itself a source of *skew***: you did
   not buy a guarantee, you bought a different problem.

### 3.6 Deployment

| Mode | When | Trap |
|---|---|---|
| **Batch** | The prediction is consumed hours or days later (nightly scoring, segmentation) | It is the default mode and the cheapest to operate. **Start here**: many people build online *serving* for a case a nightly job would have solved |
| **Online** | The prediction is part of a user request | It adds a latency SLO, autoscaling, and the cost of keeping the model warm 24×7 |
| **Streaming** | The decision must be taken on the event in flight | The state and reprocessing complexity is rarely paid for outside fraud/hard real time |

**Rollout**: *shadow* (the new model receives real traffic and does **not** respond to the user;
predictions are compared) is the technique with the highest return per unit of risk — use it before
any canary. Then a percentage canary with abort criteria **based on business or proxy metrics**,
not just on HTTP errors.

**Rolling a model back — harder than people think.** Going back requires having
simultaneously available and compatible: the **previous weights**, the **previous preprocessing**
(the one that goes with those weights, not the current one), the **feature contract** it expected, and
the **configuration** it was served with. Rules:

- The deployable artifact **packages model + preprocessing + contract** together, versioned as
  a unit. A model without its preprocessing is not reversible.
- Version N-1 is kept **deployable and tested**, not merely stored. A `rollback` that
  nobody has exercised does not exist (the same criterion as a backup).
- If the retraining changed the feature schema, the rollback **also rolls back the feature
  pipeline**. If that is not possible, it was not a rollback: it was a new deployment backwards.

## 4. Quality and gates

Gates that **break the build or block promotion**, in order of increasing cost:

1. **Formatter + linter + type checker** over training and inference code. ML
   code is production code; see `python-standards`.
2. **Unit tests of feature transformations**: invariants, edges (empty, a single
   record, all null, unseen category) and errors. No logic in the test.
3. **Data contract test**: schema, types, ranges, nulls, cardinality. It fails the pipeline.
4. **Determinism test**: same commit + same dataset + same seed → metrics within the
   declared tolerance. If this fails, everything else is noise.
5. **Temporal leakage detection**: an explicit check that no feature uses information
   later than the prediction instant. It is the number 1 cause of "it worked in the notebook".
6. **Evaluation gate**: aggregate **and per-segment** metrics against the production model,
   over the frozen set. Methodology in `llm-evaluation-standards` where applicable.
7. ***Fairness* gate**: per-group disparity metrics within the agreed threshold (§6.5). The
   threshold is set by governance (`ai-governance-standards`); the gate is run by the pipeline.
8. **Registry completeness gate**: the §3.3 metadata present, model card linked, owner
   assigned. Without them the registry rejects the version — it is the cheapest control point that
   exists and the most forgotten.
9. ***Rollback* drill** in pre-production, periodically: deploy N-1 and verify that it
   serves. Quarterly at a minimum.
10. **Load / cost-per-prediction test** before enabling real traffic (§6.4).

**Forbidden to treat "the tests pass" as "the model works"**: a green suite with a model that
predicts the majority class is the normal scenario, not the exceptional one. The business metric is
the one that decides.

## 5. Stack security

- **Insecure deserialization is the structural vulnerability of the domain.** `pickle`, `joblib`,
  `torch.load(weights_only=False)` and `cloudpickle` **execute code on load**. MLflow's
  CVE-2024-37054/37055/37059 family (RCE via a malicious PyFunc/PyTorch/pmdarima artifact,
  CWE-502) has a recent public PoC and is still being exploited: **upgrade MLflow well beyond
  2.14.1** and **restrict the artifact API**. A model artifact is **code**, not data.
- **A tracking/registry server is never exposed to the Internet or left without authentication.** An
  open MLflow is RCE via artifact and, on top of that, a complete leak of training data and metrics.
  Authentication delegated to the IdP (`identity-access-management-standards`), segmented network.
- **The ML package supply chain — an active target in 2026.** Verified precedents:
  the compromise of **LiteLLM on PyPI (Mar-2026, versions 1.82.7/1.82.8)** originating in a **compromised
  Trivy used in CI**, with execution via `.pth` files in `site-packages` **without the package needing
  to be imported**; **telnyx** (Mar-2026); **`mistralai==2.4.6`** (May-2026); the
  **Hades** campaign against `ensmallen` and bioinformatics packages on PyPI (Jun-2026). Non-negotiable
  operational consequences: **a lockfile with hashes**, **an exact pin for every tool invoked in
  CI** (including the security scanners), builds in an ephemeral environment with no persistent
  credentials, and verification that a `pip install` does not execute anything by itself.
- **Datasets and weights with access control and lineage.** Who can read the training
  dataset is a security decision, not a convenience one; if it contains personal data,
  `privacy-engineering-standards` rules.
- **Pipeline credentials**: ephemeral identity (OIDC) towards the store and the registry; never
  static keys in the experiment code or in the notebook. See
  `secrets-management-standards`.
- **An immutable audit log** of who promoted which model, when and with what metrics.
- The **trained model can leak its training data** (memorisation, membership
  inference): the assessment of that risk belongs to `privacy-engineering-standards`; the
  adversarial attack, to `mlsecops-standards`.

## 6. Performance and operability

### 6.1 Monitoring — the part almost nobody does well

Three layers, and most teams only have the first:

1. **Service**: latency, errors, saturation. It is what you already know how to do and **says nothing
   about the model**. `sre-practice-standards`.
2. **Input data**: the distribution of each feature, null rate, unseen categories,
   volume. **It is the earliest signal available and it needs no labels.** If you monitor nothing
   else, monitor this.
3. **Prediction quality**: the distribution of the output, and — when it arrives — the real metric
   against the label.

### 6.2 Data drift versus concept drift

- **Data drift (covariate shift)**: the input distribution changes. Detectable **today and
  without labels** (distribution tests, distance between populations). **Detecting it does not imply
  the model has got worse**: an alarm on statistical drift with no measured impact is the
  domain's number one source of alert fatigue — monitor the features the model actually
  uses, with thresholds calibrated over history, not `p < 0.05` over a hundred columns.
- **Concept drift**: the **relationship** between input and output changes. The input can look
  identical while the model is getting it wrong. **It is only detected with labels or with a proxy**, and
  it is the one that really hurts you.

### 6.3 The problem of the label that is late (or never arrives)

In many systems the truth takes weeks (default, renewal, relapse) or **never arrives**
because the model prevented it (you did not grant the credit: you do not know whether they would have paid).

- Define explicit **proxy metrics** and **document their bias**: acceptance rate, score
  distribution, human intervention rate, operator override rate.
- **Reserve a percentage of traffic with no model** (or with a randomised decision) where it is
  ethically and legally admissible: it is the only way to obtain uncensored labels and to really
  measure whether the model adds anything. It is a deliberate cost, with an owner and a budget.
- **Feedback loops**: if the model influences the data it will be retrained on,
  it feeds back into itself and its bias is amplified in each cycle (recommenders, queue
  prioritisation, fraud detection). **It is a design risk, not a detail**: identify it in writing
  in the model card, and measure against a sample unaffected by the model. Without that sample, you
  have no way of distinguishing "the model works" from "the model is proving itself right".

### 6.4 Retraining and cost

**Triggers** — pick an explicit one and write it down; a retraining without criteria is a
periodic lottery:

| Trigger | When | Risk |
|---|---|---|
| **By calendar** | The data renews at a known and stable rate | It retrains when it is not needed (cost, regression risk) and does not retrain when it is |
| **By threshold** | There is a reliable real or proxy metric in production | It requires the signal §6.3 says you often do not have; a badly calibrated threshold = oscillation |
| **By event** | A known change of the business, the data provider or the regulation | It depends on somebody warning you: it requires coupling it to change management |

**Hard rules of retraining**: it passes through **the same gates** as the first training
(§4) — a retrained model is not a minor update, it is a new model; it is deployed with
*shadow*/canary like any other; and **retraining does not fix concept drift if the cause
is that the problem changed**: it may be learning the broken world. Before retraining
automatically, ask whether the failure is one of data or of formulation.

**Cost**: training is a visible and budgeted spike; **inference is a continuous drip
that dominates the bill in the medium term** and almost nobody attributes it per model. Instrument
**cost per prediction** and **cost per point of metric gained**: a model 0.3% better that
triples the inference cost is a bad engineering decision disguised as an improvement. Batch
before online; a small model before a big one; caching repeated predictions before
more replicas. See `gpu-computing-standards` for utilisation as a FinOps metric.

### 6.5 Fairness and bias as a measurable property

**It is measured here; in `ai-governance-standards` it is decided what is acceptable and who answers for it.**

- Fairness metrics are **mutually incompatible**: demographic parity, equality of
  opportunity and per-group calibration cannot be satisfied at once except in
  degenerate cases. **Choosing which one applies is a product and governance decision, documented**, not
  a library's default option.
- It is measured **per segment and at the evaluation gate** (§4.7), over representative data, and it is
  measured again **in production**: a model that is fair on the test set may not be so with
  the real population.
- Bias is almost never "in the model": it is in the historical data, in the label (which usually
  records the past decision, not the truth) and in the §6.3 loop. Auditing only the output means
  arriving late.
- **The protected attributes needed to measure fairness are usually a special category of
  personal data**: how to obtain and process them lawfully belongs to `privacy-engineering-standards`.
  Do not collect them on your own to "do an analysis".

### 6.6 Model retirement

The phase that is on no diagram and that everybody omits. A model is retired when:
it no longer beats the baseline, its domain changed, its owner disappeared, or the cost exceeds the value.
Minimum procedure:

1. **Identify real consumers** by telemetry, not by documentation. There is almost always one
   nobody remembered.
2. **Announce and set a date**; offer a replacement or an explicit degradation (business rule,
   baseline, human decision).
3. **Shut it down serving an explicit error**, never returning a silent default value: a
   constant prediction disguised as a prediction is worse than a failure.
4. **Keep the artifact, model card, dataset and metrics** according to the retention policy — it may
   be needed to audit a past decision long after switching it off.
5. Mark it `archived` in the registry and **remove it from the AI system inventory** with
   `ai-governance-standards`.

## 7. Long-term sustainability

- **Cadence**: review the toolchain every **3 months** — this ecosystem changes owner and
  licence faster than almost any other in the catalogue. Recent evidence: **lakeFS acquired
  DVC** (Nov-2025), **Prefect acquired Dagster** (announced 13-Jul-2026), **Seldon Core v2 moved to BSL 1.1**
  (Jan-2024). Before adopting any tool: read the `LICENSE` **in the repo**, not the marketing
  page, and check the date of the last release.
- **Adoption criteria**: a tool goes in if it solves a **measured** problem, has a clear
  owner and its operational cost fits the team. It goes out if it has had no releases for 6 months, if it moves to
  a restrictive licence or if nobody knows how to operate it.
- **Conscious debt**: if you train without versioning the dataset or without a fairness gate because
  today you cannot, it is written down with a reason and a date in the model card. Declared debt is
  manageable debt.

**FORBIDDEN**
- ❌ Deploying a model trained from a notebook or from a dirty git tree.
- ❌ A model in production that cannot be rebuilt (data, code, config, environment, seed).
- ❌ Promoting to production without going through the registry, without an owner, without a model card and without recorded
  human approval.
- ❌ Deploying without a **tested** *rollback* plan, or without version N-1 deployable with **its**
  preprocessing.
- ❌ Serving a model without monitoring the input distribution. Without that, you operate blind.
- ❌ Confusing a statistical drift alert with model degradation, and waking somebody up over
  a `p-value`.
- ❌ Automatic retraining that deploys without evaluation gates or a canary.
- ❌ Computing a feature twice, in two places, with two different implementations.
- ❌ Evaluating only with the aggregate metric: the mean hides the segment where the model fails.
- ❌ Loading `pickle`/`joblib` artifacts of uncontrolled origin; exposing MLflow without authentication.
- ❌ Using CI tools (including scanners) without an exact version pin — the LiteLLM precedent.
- ❌ Introducing a feature store, full Kubeflow or a new orchestrator without a measured problem that
  demands it: in this domain, most of the installed complexity has not earned its place.
- ❌ Adopting a tool without reading its `LICENSE` and its last release date.
- ❌ Presenting a metric improvement without its associated inference cost.
- ❌ Collecting protected attributes "to measure bias" without a lawful basis (see `privacy-engineering`).
- ❌ Switching off a model by returning a silent default value.
- ❌ Accepting a model whose only evidence is a demo.

## 8. Mandatory web verification

Before committing to any version, licence or tool recommendation:

1. **The repo's real licence** (`LICENSE` at `HEAD`), not the marketing site. Checked Aug-2026:
   Apache-2.0 in MLflow, DVC, lakeFS, Metaflow, Prefect, Dagster, Airflow, Feast, Evidently,
   BentoML, KServe; **Seldon Core v2 under BSL 1.1** (not open source); **W&B with an MIT SDK and a
   proprietary server**. Re-verify: licence changes in this sector are frequent.
2. **Last release and activity** via the repo's Atom feed (`/releases.atom`) or PyPI — GitHub's
   REST API is rate limited and its HTML misleads on dates. Observed Aug-2026:
   MLflow 3.15.1, DVC 3.67.1 (Mar-2026), lakeFS 1.85.0, Airflow 3.3.0, Metaflow 2.19.35, Prefect
   3.8.x, Dagster 1.13.16, Feast 0.65.0, Evidently 0.7.21 (Mar-2026), KServe 0.19/0.20-rc,
   BentoML 1.4.39, Kubeflow 1.10.0, Seldon Core 1.19.0.
3. **Ownership changes and consolidation**: lakeFS↔DVC, Prefect↔Dagster. Check whether there are
   new moves and whether any led to a licence or maintenance change.
4. **Stack CVEs**: MLflow (the CWE-502 family), Kubeflow, KServe, BentoML, and the
   serialization runtime you use. Triage and SLA in `vulnerability-management-standards`.
5. **Supply chain incidents on PyPI/npm** affecting ML packages or
   tools invoked in CI. 2026 precedents: Trivy (Mar), LiteLLM (Mar), telnyx (Mar),
   mistralai (May), the Hades/`ensmallen` campaign (Jun).
6. **Model/dataset documentation standards**: whether a format with real traction has appeared
   or a regulatory obligation that fixes the content of the technical documentation.

**Declared gaps (not filled from memory):**
- **MLflow governance**: no governance change was located in 2026 beyond its
  membership of the Linux Foundation since 2020; the project remains de facto *single-vendor*
  (Databricks). **If there is a recent change, this document does not capture it — verify it in the
  repo's governance file and in the LF AI & Data blog before deciding on adoption.**
- **Evidently's maintenance status**: the last release observed in the feed was Mar-2026;
  it has not been confirmed whether the pace is deliberate or a sign of abandonment.
- **WhyLabs**: product status and licence model **not verified**. Not recommended until
  checked.
- **Prefect↔Dagster**: no public product convergence plan has been located. Treat the
  long-term continuity of either as uncertain.
- **Feast**: current governance and sponsorship not verified in detail.

If the web contradicts this document, **the web wins** — flag the discrepancy.
