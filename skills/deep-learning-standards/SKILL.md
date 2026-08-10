---
name: deep-learning-standards
description: Training your own deep neural network as an engineering decision, not a default. Use when justifying a custom network against a classical model, a frozen pretrained backbone or a third-party API, writing PyTorch training code with nn.Module, DataLoader, torch.compile, torch.amp autocast and GradScaler, gradient accumulation and gradient clipping, checkpointing and resuming with torch.save/load_state_dict, seeding with torch.manual_seed and torch.use_deterministic_algorithms, scaling with DistributedDataParallel, FSDP, torchrun or accelerate versus model/tensor/pipeline parallelism, diagnosing a loss that will not go down or a train/val curve gap, dataloader bottlenecks and storage formats (webdataset, Parquet, tfrecord, memory-mapped tensors), label quality and annotation error, holding out an untouched test set, or shrinking a model for deployment with quantization, pruning, distillation, ONNX or TorchScript export. Also covers PyTorch versus JAX versus Keras/TensorFlow selection.
---

# Deep learning standards — training your own network

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **training a deep neural network that you own**: justification, framework choice,
reproducibility, production training loop, data and labels, regularisation and
diagnosis, honest evaluation and compressing the model to deploy it.

Triggers: `nn.Module`, `DataLoader`, `optimizer.step()`, `loss.backward()`, `torch.compile`,
`torch.amp` / `autocast` / `GradScaler`, `torch.manual_seed`,
`torch.use_deterministic_algorithms`, `DistributedDataParallel`, `FSDP`, `torchrun`,
`accelerate launch`, `deepspeed`, `state_dict`, `checkpoint.pt`, `jax`/`flax`/`optax`,
`keras`/`KERAS_BACKEND`, `tf.data`, `webdataset`, `.onnx`, `torch.jit`, "the loss will not go down",
"it overfits", "NaN in the loss", "training takes three days", "the GPU is at 20 %",
"how many epochs", "quantise the model", "distil", "prune".

**Domain thesis**: **training your own deep network is a decision that must be justified
against three cheaper alternatives** —(a) a classical model, (b) a frozen pretrained model
with a head trained on top, (c) a third-party API—. None of the three requires maintaining
a training cycle, or GPUs, or the reproducibility debt it brings. Your own network
is justified when at least one of these conditions holds **and can be argued**:

- **Abundant, labelled proprietary data** in a domain no pretrained model covers.
- **Latency or local deployment requirement** (edge, network isolation, data sovereignty)
  that no API satisfies.
- **Unit cost of inference** that at your volume makes the API unviable — with the sums done,
  not guessed (`finops-standards`).
- **The task does not exist as a service**: proprietary modality, format or output structure.

Corollary: **`classical-ml` is not "small deep learning"** and this skill is not its big
version. If the data is tabular, the burden of proof is on the network (see
`classical-ml-standards` §2.1), not on *gradient boosting*.

**Not applicable**:

- `mlops-standards` (**written — critical boundary**): **the model lifecycle in production
  is theirs** — data and experiment versioning, model registry, *feature store*,
  deployment, *train/serve skew*, **drift**, retraining and retirement. **Here, how the model is
  trained and evaluated before getting there.** The boundary case is resolved thus: **an offline
  metric that improves while production gets worse is diagnosed here as a distribution
  problem and watched there as drift.**
- `classical-ml-standards` (**same wave**): splitting, leakage, validation, metrics,
  calibration, threshold and tabular models. **The leakage, baseline, metrics and threshold
  sections are not duplicated here: they apply identically and live there.**
- `model-finetuning-standards` (**same wave**): **fine-tuning is not training.** Starting from
  someone else's weights and moving them a little (LoRA/QLoRA, SFT, preferences) is theirs; training
  from scratch or all the weights of your own model belongs here. Freezing a *backbone* and training
  only the head is this skill's; moving the weights of a generative *backbone* is theirs.
- `llm-app-engineering-standards` and `rag-standards` (**written**): **building a product on a
  third-party LLM is theirs**, as is retrieval. The order **prompt → retrieval →
  fine-tuning → own training** is the catalogue's cost ladder; from this side only
  the last rung is asserted: **training is the most expensive and the one most often chosen by
  default without justifying it.**
- `llm-evaluation-standards` (**written**): **measuring non-deterministic systems is theirs** —
  evaluation sets, LLM judges, significance, CI gates. Here the untouched test set and the
  baseline are required; the method of measuring when the output is free text, there.
- `local-inference-standards` (**written**): **serving your own weights is theirs** — vLLM, llama.cpp,
  batching, KV cache, quantisation *in serving*. Here, quantisation/pruning/distillation as a
  **model design decision**; the engine that serves it, there.
- `gpu-computing-standards`: **the GPU as a resource that is provisioned, shared and paid for** —
  drivers, CUDA, MIG, queues, DCGM, cooling. Here, only the job that uses it.
- `mlsecops-standards` (**written**): **data poisoning, weight provenance,
  safe formats (`safetensors` versus `pickle`), `trust_remote_code`, signing and AIBOM and the
  attacks on the model are theirs.** Here they are stated as hygiene (§5) and the analysis is delegated.
- `data-engineering-standards`, `data-governance-quality-standards`: the pipeline and data
  quality. **The quality of the *labels* is handled here** (§4.1): it is a property of the learning
  problem, not of the pipeline.
- `ai-governance-standards` (risk, AI Act, inventory); `privacy-engineering-standards` (personal
  data and memorisation); `finops-standards`, `green-it-standards` (cost and footprint);
  `python-standards`, `r-standards`, `julia-standards`; `kubernetes-standards`,
  `object-storage-standards`, `observability-standards`; `computer-vision-standards`,
  `nlp-standards`, `multimodal-genai-standards` (applications by modality).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

### 2.1 Framework

| Piece | Choice | Verified status (Aug 2026) |
|---|---|---|
| Catalogue default framework | **PyTorch** | `torch` 2.13.0, released 8 Jul 2026 (PyPI); licence metadata: `Apache-2.0 AND Apache-2.0 WITH LLVM-exception AND BSD-2-Clause AND BSD-3-Clause AND BSL-1.0 AND MIT` |
| Legitimate alternative (TPU, function transformation, declarative parallelism) | **JAX** | `jax` 0.11.0, 16 Jul 2026 (PyPI); monthly *release* cadence (v0.9.2 Mar 2026, v0.10.0 Apr, v0.10.1 May, v0.10.2 Jun, v0.11.0 Jul) |
| Portable high-level layer | **Keras 3** | `keras` 3.15.1, 29 Jul 2026. Verbatim from the README: *"Keras 3 is a multi-backend deep learning framework, with support for JAX, TensorFlow, PyTorch, and OpenVINO (for inference-only)"* |
| TensorFlow | **Maintenance only of what already exists** | `tensorflow` 2.21.0, 6 Mar 2026; the previous *release*, 2.20.0, is from 13 Aug 2025 (GitHub Atom feed): ~7 months between minor versions |

**Honesty about the state of the ecosystem, with what is actually verifiable**: PyTorch and JAX
publish at a high and sustained cadence; **TensorFlow has a much more spaced-out *release*
cadence** and Keras 3 is no longer its exclusive layer, but a multi-backend façade whose own
README lists JAX first and TensorFlow as one more. **Criteria**: new project →
PyTorch, unless there is a concrete reason (TPU, existing JAX code, mobile deployment requirement
on the TF tooling). Existing project in TensorFlow → **it is not migrated for fashion**; it is
migrated if the tooling you need no longer arrives, and it is declared as a project with its cost.
**No market or publication share is asserted here: the available sources are blogs with no
methodology and they contradict each other (§8).**

### 2.2 Before training, in this order

1. **Classical baseline** (`classical-ml-standards`) or heuristic. Without it there is no context.
2. **Frozen pretrained + linear head**. Cheap, fast and surprisingly competitive;
   it is the real baseline of any network of your own.
3. **Pretrained with fine-tuning** (`model-finetuning-standards` if generative).
4. **Training from scratch**: only with the conditions of §1 argued in writing.

**FORBIDDEN to train from scratch what exists pretrained** unless explicitly justified by
domain, licence or deployment restriction (§7).

## 3. Reproducibility

- **Seeds**: Python, NumPy and the framework; and the seed of the `DataLoader`'s *sampler*/*shuffle*
  and of each *worker*. They are recorded alongside the rest of the experiment configuration
  (`mlops-standards`).
- **Exact reproducibility costs performance**, and PyTorch itself says so. Verbatim from the
  reproducibility note in the documentation (2.13): *"Completely reproducible results are not
  guaranteed across PyTorch releases, individual commits, or different platforms."* / *"Furthermore,
  results may not be reproducible between CPU and GPU executions, even when using identical
  seeds."* / *"torch.use_deterministic_algorithms() lets you configure PyTorch to use deterministic
  algorithms instead of nondeterministic ones where available."* / *"Deterministic operations are
  often slower than nondeterministic operations, so single-run performance may decrease for your
  model."*
- **Operational criteria**: full determinism is enabled **for debugging** and in small regression
  tests; in long training the GPU's non-determinism is accepted (atomic reductions,
  kernel selection, TF32) and compensated for by **reporting variance across seeds**.
- **What must always be reproducible**: the version of the code and of the data,
  hyperparameters, environment (image, CUDA/driver) and the *checkpoint*. Numerical randomness is
  negotiable; traceability is not.

## 4. Data, training loop and diagnosis

### 4.1 Data and labels

- **Label quality is the factor with the most impact and the least attention.** Before changing
  architecture, sample 100-200 examples and label them yourself: if the disagreement with the
  existing label is high, **you are measuring noise and no model will fix it**. Measure
  inter-annotator agreement, define the guideline and review the model's errors for mislabelling.
- **The data loader is the real bottleneck** in almost every training run that "does not
  use the GPU": if utilisation oscillates, it is I/O or CPU preprocessing. Levers: *workers*,
  *prefetch*, `pin_memory`, offline preprocessing, GPU decoding.
- **Storage format**: millions of small files on object storage or NFS is the classic
  antipattern; grouping into sequential *shards* (webdataset/tar, Parquet, memory-mapped
  tensors) changes the order of magnitude. Storage and egress cost:
  `object-storage-standards` and `finops-standards`.
- **Splitting and leakage**: same rules as in `classical-ml-standards` §4.1-4.2. With images,
  audio or text the typical leakage is the **near-duplicate** split across train and test:
  deduplicate by similarity before splitting, not after.

### 4.2 Production training loop

| Requirement | Decision |
|---|---|
| Interruption and resumption | Periodic *checkpoint* with **complete state**: weights, optimiser, *scheduler*, epoch/step, RNG and *sampler* state. A checkpoint that only saves weights does not resume, it restarts. |
| Memory and speed | **Mixed precision** (bf16 preferred over fp16 for dynamic range; fp16 requires loss scaling) |
| Effective batch larger than VRAM | **Gradient accumulation**, adjusting the gradient scaling and the frequency of the `step` |
| Stability | Gradient norm clipping, *warmup* + learning rate *schedule* |
| Compilation | `torch.compile` when the graph is stable; measure, do not assume: recompilations due to variable shapes can cost more than they save |
| Cost | GPU-hours budget **declared before** launching, with an automatic cutoff |

### 4.3 Distributed training

- **Data parallelism** (DDP and equivalents): the default answer — the model fits on one
  GPU and there is plenty of data. Almost linear scaling until communication dominates.
- **State sharding** (FSDP/ZeRO) when what does not fit is **the optimiser state and
  the gradients**, not the model. First option for a "it does not fit": less invasive than splitting it.
- **Model parallelism** (tensor or pipeline stages) only when **a layer or the whole model does not
  fit** on one device: it complicates the code, introduces *pipeline* bubbles and ties the topology.
- **Do not distribute until you have measured that one GPU is genuinely saturated.** A badly
  configured loader spread across eight GPUs is still bad, eight times more expensive.

### 4.4 Regularisation and diagnosis

- **Training and validation curves on the same chart, always.** Training goes down and
  validation goes up = overfitting (more data, more augmentation, regularisation, early stopping,
  smaller model). Both high and flat = underfitting or an optimisation problem.
- **When the loss will not go down**, in this order: (1) deliberately overfit a batch of 8 examples
  —if it cannot, there is a bug, not a learning problem—; (2) check label-input
  alignment and the same normalisation in train and inference; (3) sweep the learning rate
  two orders of magnitude up and down; (4) review the loss and the last layer (duplicated activation,
  *logits* vs. probabilities); (5) NaN → mixed precision without scaling, division by zero or a high rate.
- **Early stopping with patience on validation**; the saved *checkpoint* is the best on
  validation, not the last one.

### 4.5 Evaluation

- **Untouched test set**: it is looked at **once**, at the end, and with the baseline alongside.
  Each additional look turns it into a validation set and its estimate stops being
  valid.
- **No metric is published without measurement conditions**: dataset and version, split,
  preprocessing, hardware, seed(s), variance across runs and baseline.
- **A model that improves on the metric and gets worse in production usually has a distribution
  problem**, not a model problem: the evaluation set does not represent real traffic, or the
  traffic changed. Diagnosis here (compare input distributions, segment the error by
  cohorts); **continuous drift monitoring belongs to `mlops-standards`**.
- **Evaluate by segments, not only in aggregate**: a stable global metric can hide a
  collapse in a subgroup. *Fairness* as a measurable property is computed here; its acceptability
  is decided in `ai-governance-standards`.

## 5. Security and provenance

- **Third-party weights**: download by pinned revision/digest, `safetensors` versus formats with
  `pickle`, `trust_remote_code` disabled unless explicitly reviewed, signature verification. The
  full criteria belong to `mlsecops-standards`; here it is an entry requirement.
- **Data poisoning**: any scraped or user-contributed corpus is attack surface
  on the trained model. Provenance declared by source and the ability to exclude an
  origin and retrain.
- **Memorisation and PII**: a network trained on personal data can reproduce it. The lawful
  basis, minimisation and erasure belong to `privacy-engineering-standards`, and they must be
  resolved **before** training: there is no `DELETE` in a `.safetensors`.
- Secrets, storage credentials and *hub* tokens never in the training code
  or in the image (`secrets-management-standards`).

## 6. Efficiency and cost

- **Quantisation, pruning and distillation are deployment decisions with measurable loss**, not
  free optimisations. They are decided with the task metric before and after, on the same
  set, and with the target latency/memory declared. Usual order of payoff:
  post-training quantisation → distillation to a smaller model → structured pruning.
  Quantisation *in the serving engine*: `local-inference-standards`.
- **Export** (ONNX, TorchScript, inference compilers): numerically validate
  equivalence over a set of cases before replacing; a preprocessing difference
  between training and export is *train/serve skew* (`mlops-standards`).
- **Cost is a design constraint, not a surprise bill**: GPU-hours with a budget and
  a cutoff, and cost per prediction at inference (which at high volume dominates that of training).
  Policy: `finops-standards`; footprint: `green-it-standards`; shared GPU:
  `gpu-computing-standards`.
- Training observability: GPU and memory utilisation, time per step, samples/s, and
  an alert if a job has spent N hours with the GPU at 20 %.

## 7. Long-term sustainability and prohibitions

- Framework, CUDA and driver versions pinned in the image and updated deliberately: a major
  change can move the metrics and is treated as an experiment, not as maintenance. A model
  trained without recoverable code, data and configuration **is a dead artefact**: it is not
  debugged or reproduced, and retiring it is the only honest option.

**FORBIDDEN**:

- ❌ **Training without a baseline** (classical, frozen pretrained or heuristic).
- ❌ **Looking at the test set more than once**, or using it to choose architecture,
  hyperparameters, *checkpoint* or threshold.
- ❌ **Publishing a metric without measurement conditions** (dataset, split, hardware, seeds,
  variance, baseline).
- ❌ **Training from scratch what exists pretrained**, without justifying domain, licence or
  deployment restriction.
- ❌ Scaling to multi-GPU without having demonstrated that one GPU is saturated.
- ❌ *Checkpoints* that only save weights in a training run lasting longer than the
  infrastructure's interruption window.
- ❌ Loading third-party weights with `pickle` or `trust_remote_code` without review.
- ❌ Presenting a 0.3 % improvement with a single seed as a result.
- ❌ Changing architecture before having manually inspected a sample of labels.
- ❌ Quantising or pruning without measuring the quality loss on the task metric.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

- Latest stable of **PyTorch, JAX, Keras and TensorFlow**, and the compatibility matrix
  PyTorch ↔ CUDA ↔ driver ↔ Python: it is the number one source of broken environments.
- State of the ecosystem: *release* cadence in the GitHub Atom feeds and official notes.
  **Declared gap**: no usage, publication or employment share between frameworks is fixed here
  — the sources located are articles with no published methodology and **they contradict each other**
  ("research share" figures from 55 % to 85 % depending on the page). If you need the data,
  demand a survey with a sample and a method.
- **Declared gap**: no speedup figure for `torch.compile`, mixed precision or
  distributed scaling; they depend on model, batch and hardware and rarely come with conditions.
- State of the distributed training APIs (DDP/FSDP and their versions) before writing
  code: they have changed name and recommendation between major versions. And which operations
  still have no deterministic implementation in the version you use.
- CVEs of the framework, the GPU runtime and the model-loading libraries
  (`vulnerability-management-standards`), and the real licences of any pretrained weights you
  incorporate: **the licence of weights is not a software licence** and is rarely OSI
  (see `model-finetuning-standards` §5 and `opensource-licensing-standards`).

If the web contradicts this document, **the web wins** — flag the discrepancy.
