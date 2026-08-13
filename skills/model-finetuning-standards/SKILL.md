---
name: model-finetuning-standards
description: Fine-tuning an existing model's weights as the last resort, after prompting and retrieval. Use when deciding between prompt engineering, RAG and training, running full fine-tuning versus PEFT with peft LoraConfig (r, lora_alpha, target_modules="all-linear", lora_dropout), QLoRA with bitsandbytes 4-bit, or DoRA and other LoRA variants, training with trl SFTTrainer, DPOTrainer, GRPOTrainer, KTOTrainer, RLOOTrainer or RewardTrainer, Unsloth or Axolotl configs, building a chat-formatted instruction dataset with chat templates and JSONL conversations, checking eval-set contamination and synthetic-data provenance, measuring catastrophic forgetting of general capability before and after, reading the weights licence of Llama, Gemma, Qwen, Mistral or DeepSeek checkpoints and whether it is OSI-approved, merging adapters with merge_and_unload versus serving adapters at runtime, or maintaining a family of fine-tuned variants.
---

# Model fine-tuning standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **modifying the weights of someone else's pretrained model**: the decision of whether to do it, the
method (full versus PEFT), the data, preference alignment, the mandatory
evaluation before and after, the licence of the starting weights and the deployment of the resulting
variant.

Triggers: `peft`, `LoraConfig`, `get_peft_model`, `r=`/`lora_alpha`/`target_modules`,
`QLoRA`, `bitsandbytes` 4-bit, `trl`, `SFTTrainer`, `DPOTrainer`, `GRPOTrainer`, `KTOTrainer`,
`RLOOTrainer`, `RewardTrainer`, `unsloth`, `axolotl`, `adapter_model.safetensors`,
`adapter_config.json`, `merge_and_unload`, chat template / `chat_template`, `.jsonl` of
conversations, "fine-tune the model with our documents", "make it learn our product",
"make it answer in our tone", "the model doesn't know X", "train on our tickets".

**Domain thesis**: **fine-tuning is the last option, not the first.** The order of increasing
cost and decreasing reversibility is:

1. **Prompt** (instructions, examples, structured output). Marginal cost, change in
   seconds, reversible. Solves format, tone, judgement and bounded tasks.
2. **Retrieval (RAG)**. Solves **knowledge**: your own facts, updatable, citable and
   deletable. It is what people believe fine-tuning solves.
3. **Fine-tuning**. Solves **behaviour**: rigid format, consistent style, narrow
   repetitive task, reduced prompt length and lower latency/cost per request.
4. **Training your own** (`deep-learning-standards`). Another order of magnitude of cost.

**What fine-tuning fixes and what it does not**:

| It does fix | It does not fix |
|---|---|
| Stable output format without long instructions | **Not knowing facts** — the most common and most expensive mistake |
| Consistent style, tone and register | Knowledge that changes (prices, catalogue, policies) |
| Narrow, repetitive task (classify, extract, rewrite) | Traceability and source citation |
| Consistency across runs and less instruction drift | Deleting a datum at the subject's request |
| Shorter prompt → fewer tokens, less latency | General reasoning the base model does not have |
| Meeting your own schema or taxonomy | Making the model "not hallucinate" |

**Hard rule**: if the answer to "what do you expect it to learn?" is a set of facts, the
solution is retrieval, not fine-tuning. Putting facts into the weights is expensive, not verifiable,
not updatable and not deletable.

Corollary: **fine-tuning is not training.** You start from someone else's weights, move them a little and the
result inherits the capabilities **and the legal restrictions** of the base model (§5).

**Not applicable**:

- `llm-app-engineering-standards` and `rag-standards` (**written — critical boundary**):
  **building a product on a third-party LLM is theirs**, as is **retrieval** —
  ingestion, *chunking*, embeddings, index, hybrid, *reranking*, citation. **Here, modifying the
  weights.** The order prompt → retrieval → fine-tuning crosses all three skills: from this side
  only the third rung is asserted and **the burden of proof of having exhausted the previous two
  falls here**. If the prompt or the index solve the case, this skill declares there is no
  project.
- `mlops-standards` (**written — critical boundary**): **the model's lifecycle in
  production is theirs** — artifact registry and versioning, promotion, deployment, *rollback*
  to the previous weights, drift, retraining and retirement. **Here, how the model is tuned and evaluated
  before it gets there.** An adapter you trained **is a model artifact of your own**
  and enters their registry with its card and its lineage.
- `llm-evaluation-standards` (**written**): **measuring non-deterministic systems is theirs** —
  evaluation set, LLM judges, significance, CI gates, *benchmark* contamination.
  Here evaluation before and after is **required** (§6) and **what** to measure is defined (target task
  **and** general capabilities); the **how**, there.
- `local-inference-standards` (**written**): **serving your own weights is theirs** — vLLM, llama.cpp,
  batching, KV cache, hot adapters, serving quantisation. Here, the decision to
  **merge or serve adapters** and its maintenance cost; the engine, there.
- `deep-learning-standards` (**this same wave**): training your own network. **Fine-tuning is not
  training**, but it inherits its mechanics: mixed precision, gradient accumulation, *checkpoints*
  and seeds are governed there.
- `classical-ml-standards` (**this same wave**): with thousands of labelled examples, **a
  classical classifier over embeddings usually wins on cost, latency and debuggability** over
  fine-tuning a generative model. It is the forgotten baseline.
- `gpu-computing-standards` (**the GPU as a resource that is provisioned, shared and paid for**);
  `mlsecops-standards` (**weight provenance, safe formats and attacks on the model**, including
  corpus poisoning and backdoors); `ai-governance-standards` (**risk, the AI
  Act and inventory** — careful: **tuning and publishing can turn you into a provider** for
  regulatory purposes); `opensource-licensing-standards` (**the licence policy**; here only the
  specific restriction of a given set of weights); `privacy-engineering-standards` (personal data and
  memorisation); `data-engineering-standards`, `data-governance-quality-standards`;
  `finops-standards`, `green-it-standards`; `python-standards`; `computer-vision-standards`,
  `nlp-standards`, `multimodal-genai-standards`.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Verified version (Aug 2026, PyPI) | Licence |
|---|---|---|---|
| PEFT / adapters | `peft` | 0.20.0 (28 Jul 2026) | Apache-2.0 (repo header) |
| SFT and preference trainers | `trl` | 1.9.2 (28 Jul 2026) | Apache-2.0 (PyPI metadata) |
| Models and tokenizers | `transformers` | 5.14.1 (16 Jul 2026) | Apache-2.0 |
| Distribution / launching | `accelerate` | 1.14.0 (11 Jun 2026) | Apache-2.0 |
| Training quantisation (QLoRA) | `bitsandbytes` | 0.50.0 (24 Jul 2026) | MIT (PyPI metadata) |
| Data | `datasets` | 5.0.1 (28 Jul 2026) | Apache-2.0 |
| Weight format | `safetensors` | 0.8.0 (9 Jun 2026) | verify (§8) |

**Method**: **LoRA/QLoRA by default**; full fine-tuning only if LoRA with a sufficient rank has already
fallen short **and it is measured**. QLoRA (4-bit quantised base + adapter) when VRAM
rules; assume a quality penalty that must be measured, not assumed.

**Variants**: `peft` today documents LoRA with its own variants (**DoRA, BD-LoRA, KaSA,
MonteCLoRA, VeLoRA** in its documentation index) as well as different families (AdaLoRA, LoHa,
LoKr, OFT/BOFT, IA3, prompt/prefix tuning and others). **Criteria: plain LoRA is the starting
point; a variant enters only with your own measurement justifying it**, not for being new.

## 3. Hyperparameters that really matter

Four decisions concentrate the result: **target layers, rank, learning rate and effective batch
size**. Citable reference: the *"LoRA Without Regret"* guide in the TRL
documentation, which reproduces findings from a Thinking Machines Lab paper (Schulman et al., 2025).
Verbatim from that guide:

- *"The authors recommend applying LoRA to all weight matrices rather than limiting it to
  attention layers, as increasing the rank does not compensate for this restriction."* →
  `target_modules="all-linear"` as a starting point, not just `q_proj`/`v_proj`.
- *"For datasets that exceed LoRA capacity, LoRA underperforms FullFT"* → the rank must cover
  the capacity the dataset demands. The guide's table recommends rank **256** for SFT at
  "post-training scale" and **1-32** for RL.
- *"Counterintuitively, the blog post recommends using a higher learning rate than for full
  fine-tuning"*; in its table, 1.0e-5 for LoRA against 1.0e-6 for full fine-tuning, and *"The
  1/r scaling in LoRA makes the optimal learning rate approximately rank-independent"*.
- *"In some scenarios, LoRA is less tolerant of large batch sizes than full fine-tuning."* → the
  guide recommends an effective batch < 32.

**Declared methodology and limit**: results from a lab blog post
reproduced by HuggingFace on specific models and datasets (SmolLM3-3B, Llama-3.2-1B/3.1-8B,
tulu-3-sft-mixture, OpenThoughts-114k, OpenR1-Math-220k); **it is not peer-reviewed literature and
does not generalise to your model without measuring it**. Its compute claim ("~67% of the compute")
**is not adopted here as a figure**: it comes with no hardware or conditions (§8). `lora_alpha` is a scale
relative to the rank: it is set together with it and not touched blindly.

## 4. Preference alignment

Correct order: **SFT first** (format and task), **preferences after** (choosing between
valid answers). Skipping SFT to go straight to preferences is the usual sequencing
error.

**Real status verified in the `trl` documentation (docs index, Aug 2026)**: the
**stable** trainers are **DPO, GRPO, KTO, Reward, RLOO and SFT**. In the
**experimental** section live, among others, **PPO, ORPO, CPO, BCO, Online DPO, Nash-MD, GSPO-token,
SDPO, A2PO, GMPO, GOLD, GKD, PRM and distillation**.

Reading of the criteria: **DPO is neither superseded nor withdrawn — it remains a first-class
trainer**, and alongside it reinforcement methods with verifiable reward (GRPO,
RLOO) have consolidated, the real novelty of the last cycle; the proliferation of acronyms lives in experimental for
a reason. **Criteria: DPO for pairwise preferences; GRPO/RLOO when there is a verifiable reward
(code that compiles, a test that passes, a correct numerical result); everything else, only with your own
measurement.**

**When it is worth it**: you already have decent SFT, there is a consistent preference you cannot
write down as an instruction and you have hundreds or thousands of reliable comparisons. With less, you are
injecting noise and risking degradation.

## 5. Data and licences — the part that decides the result

### 5.1 The training set is 90 % of the result

- **Quality over quantity.** Hundreds or a few thousand **excellent and consistent** examples
  beat tens of thousands of mediocre ones; a contradictory criterion repeated teaches the contradiction.
- **Format consistency**: the data is the specification and any deviation is learned.
- **Conversation format**: use the **base model's chat template** (special tokens,
  roles, end markers). A mismatch between the training template and the inference one is
  the number one cause of "the fine-tuned model answers oddly", and it is *train/serve skew*.
- **Edges and negatives**: include examples where the correct thing is to refuse, ask for clarification or
  say it does not know. If you do not put them in, the model learns to make things up.
- **Contamination with the eval**: deduplicate the corpus against the evaluation set **before**
  training, by exact match and by similarity. A contaminated eval measures nothing and cannot be
  decontaminated after the fact: you have to retrain.
- **Synthetic data**: useful for volume and edges; it inherits bias and errors from the generator,
  collapses diversity, and **generating with a third-party model to train yours may
  violate their terms of use** (check the provider's terms, not just the licence of the
  weights). Label the synthetic origin and review a sample by hand.
- **PII**: lawfulness, minimisation and retention before building the corpus
  (`privacy-engineering-standards`). The model memorises: **there is no `DELETE` in a set of weights**.

### 5.2 Weight licences: they are not software licences

**Central trap of the domain**: the licence of a set of weights is **not** a software licence and
"open source" applied to a model almost never means what it seems. Cases read in their text:

| Weights | Licence | Real restriction (verbatim from the text) |
|---|---|---|
| Llama 3.3 (text read raw; **Llama 4 has its own agreement**, §8) | *Llama Community License Agreement* (not OSI) | Mandatory attribution: *"prominently display "Built with Llama""*; forced renaming: *"you shall also include "Llama" at the beginning of any such AI model name"* if you train another model with its materials or outputs; **user limit**: *"is greater than 700 million monthly active users in the preceding calendar month, you must request a license from Meta"*; acceptable use policy incorporated by reference |
| Gemma | *Gemma Terms of Use* (not OSI) | *"You must not use any of the Gemma Services: for the restricted uses set forth in the Gemma Prohibited Use Policy"*; mandatory propagation: *"You must provide all third party recipients of Gemma or Model Derivatives a copy of this Agreement"* and *"include the use restrictions referenced in Section 3.2 as an enforceable provision"*; *"Google reserves the right to restrict (remotely or otherwise) usage of any of the Gemma Services that Google reasonably believes are in violation of this Agreement."* |
| DeepSeek-V3 | *DeepSeek License Agreement v1.0* (not OSI) | Use restrictions in its Attachment A, among them *"For military use in any way"* and *"For fully automated decision making that adversely impacts an individual's legal rights"*; mandatory propagation to derivatives; PRC jurisdiction and law |
| DeepSeek-R1 | **MIT** (repo `LICENSE`) | Genuinely permissive — **same provider family, different licence**: it is verified per model, never per brand |
| Qwen3 (e.g. Qwen3-8B) | **Apache-2.0** (repo `LICENSE`) | Permissive; keep the notice and NOTICE |
| Mistral | **Varies per model** (e.g. `license: apache-2.0` on the Mistral-Small-3.2-24B-Instruct-2506 card) | Other models from the same provider are published under a research licence: **verify the specific model** |

Rules that follow:

- **None of the licences in the "not OSI" column is free software or open source**: field-of-use
  restrictions are incompatible with the open source definition by
  construction. Calling them "open source" in internal or commercial documentation is a legal risk
  of its own.
- **The code repository's licence is not the weights' licence.** Verified example:
  the `google-deepmind/gemma` repository publishes its `LICENSE` under Apache-2.0, while the model
  card declares `license: gemma` and points to the *Gemma Terms of Use*. **You read the
  document that accompanies the weights, not the code's.**
- **Restrictions are inherited and propagated**: your fine-tuned variant is subject to the
  base's terms and, in several of these cases, you are obliged to impose them on whoever receives it.
- **The corpus licence also restricts**: a dataset with a non-commercial or research-only
  clause contaminates the use of the resulting model. Data and weight licences are recorded
  in the model card.
- The general licence policy, the CI gate and the SBOM/AIBOM belong to
  `opensource-licensing-standards`.

## 6. Mandatory evaluation, before and after

- **Prompt baseline mandatory.** Without the base model's metric with the best
  reasonable prompt —and, if applicable, with retrieval— you do not know whether the tuning added anything. **It is the
  entry gate to the project, not a later report.**
- **Two measurement axes, always**: (1) **target task**, with your own uncontaminated eval;
  (2) **general capabilities — catastrophic forgetting**: tuning narrows the model, so measure
  before and after capabilities that are **not** the task (instruction following,
  reasoning, language, refusals). An improvement on the task that breaks the language or safety is
  not an improvement.
- **Safety behaviour**: tuning can degrade the base's refusals even if the
  data is not malicious; it is measured before publishing (`mlsecops-standards` for *red teaming*).
- **Methodology**: `llm-evaluation-standards`. Here only **what** is measured and **when** it
  blocks is fixed: if the task does not improve significantly over the prompt baseline, or if
  general capabilities drop above the declared tolerance, **the artifact is not
  promoted**.
- Experiment logging (data, hyperparameters, seed, exact base by revision/digest) and
  artifact promotion: `mlops-standards`.

## 7. Deployment, sustainability and prohibitions

- **Merge or serve adapters**: merging (`merge_and_unload`) gives a single artifact, simple
  to serve and quantise, losing modularity and multiplying storage per variant;
  serving adapters over a shared base allows many variants with a single copy of the
  weights, at the cost of complexity and compatibility ties in the engine. Rule: **one variant
  → merge; several over the same base → adapters.** The engine: `local-inference-standards`.
- **The real cost of a family of variants is maintenance, not training**: each
  one needs an eval, a card, retraining when the base changes and retirement. Before the
  second one, ask whether routing by prompt is enough.
- **When a better version of the base model comes out, the work may become obsolete**: fine-tuning
  is perishable and tied to a specific base. Plan with that expiry in mind and keep **the
  dataset**, which is the asset that survives.

**FORBIDDEN**:

- ❌ **Fine-tuning to add factual knowledge**. That is retrieval (`rag-standards`).
- ❌ **Fine-tuning without a prompt baseline** (and, where applicable, without a retrieval baseline).
- ❌ **Training on data contaminated with the evaluation set**.
- ❌ **Publishing a fine-tuned model without declaring the base model's licence**, its inherited
  restrictions and the corpus licence.
- ❌ Calling weights with use restrictions "open source".
- ❌ Inferring the licence of a set of weights from the code repository's, from the provider's
  brand or from a third-party summary: you read the text that accompanies the model.
- ❌ Publishing without measuring **catastrophic forgetting** of general capabilities and safety
  behaviour.
- ❌ Training with a chat template different from the one you will use at inference.
- ❌ Generating synthetic data with a provider whose terms forbid training competing
  models, without having read those terms.
- ❌ Skipping SFT and applying preference methods directly on the base model.
- ❌ Maintaining a family of variants without an automated eval per variant.
- ❌ Adopting a "new" LoRA variant or preference method without your own measurement.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

- Latest stable releases and *breaking changes* of `transformers`, `peft`, `trl`, `accelerate`,
  `datasets` and `bitsandbytes`: **`trl` moves trainers between stable and experimental across
  versions**, and `transformers` 5.x already introduced API breakage. Read the repo's documentation
  index, not a tutorial.
- **Status of DPO against more recent methods**: verify in the official `trl`
  documentation which trainers are in `Trainers` (stable) and which in `Experimental`. What is written
  here comes from the repository's `_toctree.yml` in Aug 2026 and **expires fast**.
- **The licence of EVERY weights model you use, read in its full text**, including the
  acceptable use policies incorporated by reference and the provider's terms if you use
  their API to generate data. **Declared gaps**: (a) the text of the *Llama Community License*
  cited here corresponds to **Llama 3.3** (version date 6 Dec 2024) read raw from the
  `meta-llama/llama-models` repository; **Llama 4 has its own agreement** (effective date
  5 Apr 2025) which **has not been read in full in this write-up** — do not assume the clauses
  match; (b) the *Gemma Terms of Use* clauses were obtained by extraction from the
  official page, **not from a raw file**: re-read them at `ai.google.dev/gemma/terms`
  before basing a legal decision on them; (c) the `safetensors` licence was not verified.
- **OSI approval**: none of the weight licences with use restrictions cited appears
  as OSI-approved, and by construction it cannot be (field-of-use restrictions
  are incompatible with the definition). Verify the current list and the status of the *Open Source
  AI Definition* (OSAID) before using the "open source" label in documentation.
- **Declared gaps**: (a) no figure for quality, compute saving or memory of LoRA/QLoRA
  against full fine-tuning — the available ones come from lab blogs or reproductions
  on specific models, with no homogeneous conditions; (b) no minimum dataset size — the
  ranges that circulate ("a thousand examples are enough") come with no task, model or metric: the number comes
  out of your evaluation curve as you vary the size.
- CVEs and maintenance status of `bitsandbytes` and the quantisation *kernels*, and
  provenance/signature of the base weights (`mlsecops-standards`).

If the web contradicts this document, **the web wins** — flag the discrepancy.
