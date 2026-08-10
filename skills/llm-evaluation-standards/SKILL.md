---
name: llm-evaluation-standards
description: Measuring non-deterministic LLM systems as an engineering discipline. Use when building and versioning a domain eval set in the repo, choosing between deterministic assertions (exact match, schema validity, regex, code or SQL execution) and an LLM judge, writing a judge rubric and calibrating it against human labels with Cohen's kappa or Krippendorff's alpha, pairwise versus pointwise judging and position/verbosity/self-preference bias, evaluating per component versus end to end and why per-step success rates compound, scoring agent task completion with cost and step count as first-class metrics, wiring evals as a CI gate with tolerance bands, run-to-run variance and sampling budgets, offline eval sets versus online experiments and their sampling bias, promoting an annotated production trace into a permanent regression case, or judging whether a public leaderboard (MMLU, MTEB, SWE-bench, LMArena) says anything about your task given saturation and training-data contamination. Tools: RAGAS, DeepEval, promptfoo, Inspect AI, lm-evaluation-harness, Langfuse, Braintrust, LangSmith, OpenAI Evals.
---

# LLM system evaluation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **measuring a non-deterministic system**: building the evaluation set, choosing the type
of measurement, calibrating judges, separating evaluation by layer, putting the eval in CI as a gate, and
closing the loop with production. It is the skill that **owns evaluation across the whole AI catalogue**:
`llm-app-engineering-standards`, `rag-standards` and `ai-agents-standards` require it as a gate and
delegate the *how it is measured* here.

**Thesis of the domain — it applies throughout the document**: **without evaluation there is no
engineering, only demos.** A change of prompt, of model, of temperature, of `effort` or of provider
version is a **behaviour change that is not observable without measurement**. Hard corollaries:

- **"It worked for me" is not a result.** An anecdote with N=1 over a stochastic system does not
  distinguish improvement from noise.
- **The system does not have a quality; it has a distribution of quality.** Any claim without a
  sample size or run-to-run variance is internal marketing.
- **If you cannot explain what a metric measures, do not use it to decide.** An opaque metric on a
  dashboard is worse than none: it turns a decision into a ritual.

Triggers: "eval set", "golden set", "regression cases", `evals/`, `*.eval.yaml`,
`promptfooconfig.yaml`, "LLM as a judge", "LLM judge", "rubric", "inter-annotator agreement",
"kappa", "position bias", "verbosity bias", "how do I know if the new prompt is better?",
"the test fails sometimes", "eval threshold in CI", "agent success rate", "cost per task",
"trajectory", "prompt A/B", "user feedback", "drift", "production annotation",
`RAGAS`, `DeepEval`, `promptfoo`, `inspect_ai`, `lm-eval`, `Langfuse`, `Braintrust`, `LangSmith`,
`MMLU`, `MTEB`, `SWE-bench`, `LMArena`, "benchmark contamination", "saturation".

**Not applicable**: see
`claude-api` (**an installed skill, with no `-standards` suffix, the canonical reference for the
Anthropic side**: model IDs, prices, context windows, `effort`, `thinking`, `task_budget`, prompt
caching, `stop_reason`, Managed Agents and their *Outcomes* with a rubric. **Arbitration rule: any
concrete datum about Claude models —id, price, limit, parameter— is theirs and is not asserted from
memory.** If your evaluation compares Claude models, the data comes from there; the comparison method
belongs here);
`llm-app-engineering-standards` (**the prompt as a code artifact**, structured output,
context window, retries, spend limits, prompt injection, and the *golden cases* as a testing
technique inside the app. Boundary: **there the prompt is written and versioned; here it is decided
whether the change improved anything**);
`rag-standards` (**retrieval as a problem**: chunking, embeddings, indexes, hybrid,
reranking. The retrieval metrics are **defined** there; **measuring them separately from
generation, and the design of the evaluation set that feeds them, belongs here**);
`ai-agents-standards` (**the loop**: when an agent, the tool surface, the iteration
budget, containment, the lethal trifecta. Boundary: **there the agent is bounded; here it is measured
whether it completes the task, at what cost and in how many steps**);
`mcp-standards` (the MCP protocol: primitives, transports, authorisation, server design and
security);
`mlsecops-standards` (security of the model lifecycle and of the AI supply
chain. **The red teaming boundary, declared on both sides: the AI red teaming methodology —adversarial
attack against the system— belongs to `mlsecops`; the *measurement apparatus* that the exercise uses
—case set, judge, rubric, threshold, CI— belongs here.** A successful attack is a
new case in the eval set; the governance of the attack is not);
`mlops-standards` (the operational lifecycle of a model of your own — versioning of
datasets and runs, experiment tracking, model registry and promotion, training
orchestration, *feature store* and train/serve skew, shadow and canary deployment, weight rollback,
and **detection of data drift versus concept drift** with their proxy metrics and their
feedback loops. **Boundary: `mlops` operates, this skill measures quality.** Drift is theirs
as an operational signal; **turning that drift into new cases in the evaluation set is mine**.
Fairness and bias as a system property are theirs);
`ai-governance-standards` (the AI Act, policies, AI system inventory,
risk management. The *obligation* to evaluate and document is theirs; the technical method, mine);
`observability-standards` (telemetry pipeline, OTel, sampling, retention, platform
cost. **Here only what trace is needed to evaluate and how it becomes a case**);
`sre-practice-standards` (SLO, error budget, on-call, progressive delivery as a reliability
practice. **The canary and the A/B as deployment mechanics are theirs; the quality metric that
decides whether the canary passes is mine**);
`cicd-standards` (the pipeline that runs the gate, OIDC, artifacts, SBOM and signing);
`data-platform-standards` (where the eval set's data lives and its retention);
`privacy-engineering-standards` (**the eval set is usually real traffic: personal data**. The
legal basis, minimisation, pseudonymisation and deletion are theirs — they are not duplicated here);
`python-standards` (the evaluation harness's code);
`local-inference-standards` (serving the model you evaluate on your own infrastructure).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8). This is an
> ecosystem with a high tool mortality rate: check the date of the last release **before**
> adopting anything.

| Decision | By default | Reason |
|---|---|---|
| First instrument | **Deterministic assertion** (exact equality, valid schema, regex, code/SQL execution) | The cheapest, the most reproducible and the most underrated. Cost ~0, variance 0, needs no calibration |
| Second instrument | **LLM judge with an explicit rubric and calibration** (§3.4) | Only for what the assertion does not cover: writing quality, faithfulness, tone, reasoning |
| Third instrument | **Human annotation** | When neither the assertion nor the judge is defensible. It is the anchor for everything else, not a luxury |
| Harness in CI | **`promptfoo`** (declarative, YAML, CLI, runs locally and in CI) or **`DeepEval`** (`pytest` style) | Both alive and with a recent release. Choose one and do not mix harnesses in the same repo |
| Rigorous / safety evaluation | **Inspect AI** (UK AI Security Institute) | Designed for serious, auditable evaluations, not for dashboards. Very active |
| Reproducible academic benchmarks | **`lm-evaluation-harness`** (EleutherAI) | The de facto standard for comparing base models. **It is not a product harness** |
| Traces + annotation + production dataset | **Langfuse** (open source, self-hostable) | It closes the trace → case loop. Commercial alternative: Braintrust, LangSmith |
| RAG metrics | **RAGAS** formulas as a *conceptual reference*, implemented in your harness | **See the maintenance warning below** |
| Eval set storage | **A versioned file in the repo** (`evals/*.jsonl`, `*.yaml`), next to the prompt | The eval set is code: it is reviewed in a PR, tagged with the release, bisected |
| Judge model | **A different family from the generator's**, pinned by exact ID | It removes the bias towards the model itself (§3.4) |
| Judging protocol | **Pairwise with both orderings** to compare candidates; **absolute scoring with an anchored rubric** only for a threshold | Relative judgement is more reliable than calibrating an abstract scale |

### Verified state of the tools (August 2026)

| Tool | Latest version | Date | Verdict |
|---|---|---|---|
| `promptfoo` | 0.121.20 (npm/GitHub) | 2026-07-31 | **Alive, high cadence.** Watch the governance: the project was acquired by OpenAI (March 2026, verify) — assess the provider bias if you compare rival models |
| `deepeval` | 4.1.5 | 2026-07-29 | **Alive, high cadence.** Natural CI integration (`pytest`) |
| `inspect-ai` | 0.3.251 (PyPI) | 2026-07-29 | **Alive, very active.** No tagged releases on GitHub: version by PyPI |
| `langfuse` | 4.3.1 (server) / 4.14.2 (Python SDK) | 2026-08-03 | **Alive, very high cadence** |
| `lm-evaluation-harness` | 0.4.12 | 2026-05-11 | **Alive**, slow and stable cadence (which is what you would expect in a benchmark harness) |
| `ragas` | 0.4.3 | **2026-01-13** | ⚠️ **~7 months with no release.** Treat it as a **conceptual reference, not as a CI dependency**. If you use it in the pipeline, pin the version and have an exit plan |
| `openai/evals` | no releases; last push 2026-04-14 | — | ⚠️ **Effectively stalled.** Do not adopt it for new work |
| `mteb` (library) | 2.18.12 | 2026-08-02 | Alive, but see §3.8 on the comparability of results |

**Adoption rule**: before putting an evaluation library into the pipeline, look at the date of the
last release. **More than 6 months without publishing in an ecosystem that moves every week is a sign
of abandonment**, not of stability. An abandoned evaluation harness is debt on the critical path of
all your deployments.

## 3. Structure and conventions

### 3.1 The evaluation set is the real asset

The prompt gets rewritten in an afternoon. The model is changed with a constant. **The eval set is what
you cannot regenerate**, and it is the only thing that tells you whether those changes improved or
worsened the product.

- **Cases from your domain, not public benchmarks.** A public benchmark measures something else (§3.8).
- **Origin: real traffic.** It is collected from production traces (or from the closed beta), it is not
  invented in a brainstorming session. Invented cases come out systematically **easier**
  than reality and omit the failure modes that matter.
- **Stratification mandatory.** The set must cover, with a declared proportion: the happy path,
  **edges**, ambiguous inputs, malicious inputs, out-of-scope inputs (where the correct answer
  is to refuse), and the cases that have already broken once.
- **Minimum useful size**: below ~50 cases per category you cannot distinguish a real improvement from
  sampling noise. Start at **50–100 well chosen cases in total** (better than 1,000 auto-generated
  ones) and grow with the traffic. Always declare N alongside the result.
- **Labelling**: every case carries the input, the expected output (or the acceptance criterion), the
  category, and **who labelled it and when**. Without provenance there is no audit of the eval.
- **It is versioned in the repo, next to the prompt.** Same commit, same PR, same review. A prompt
  change and an eval set change in the same commit require explicit justification in the PR
  description: it is the pattern by which an eval stops measuring.
- **Freezing**: keep a **frozen** subset (never edited, only grown) as a historical reference, and a
  **live** subset that absorbs new cases. Comparing releases against a set that mutates is comparing
  nothing.

### 3.2 Deterministic evaluation — the default instrument

Before touching an LLM judge, exhaust this. If the task allows it, **it is always the right answer**:

| Technique | When |
|---|---|
| Exact / normalised equality | Classification, extraction of a canonical field, routing |
| **Schema validation** (JSON Schema, Pydantic) | Any structured output. **It does not measure quality, but a failure here is a failure, full stop** |
| Regular expression / substring containment | Format, presence of a citation, absence of a forbidden string |
| **Execution of the generated code** (tests, compilation) | Code generation: the test that passes is the metric |
| **Execution of the generated SQL** against a test schema | Text-to-SQL: compare result sets, not strings |
| Invariant properties | "The sum of the lines equals the total", "it does not invent an ID that is not in the context" |
| Comparison with a classic tool | If a `grep` solves the case, the `grep` is the oracle |

**Frequent antipattern**: using an expensive and noisy LLM judge to verify something a `json.loads()`
checks in a microsecond.

### 3.3 Classic NLP metrics — and their limits

BLEU, ROUGE, METEOR and the like measure **lexical overlap with a reference**. They are useful as a
cheap signal in tasks with a canonical reference and low variability (translation, extractive summary).

**They do not measure correctness.** A factually false answer using the reference's vocabulary scores
high; a correct paraphrased answer scores low. **Forbidden to use them as an acceptance criterion
for an open generative system.** Embedding similarity metrics
(BERTScore and family) mitigate the lexical problem but still do not measure factuality.

### 3.4 LLM judge — with all the small print

An LLM judge is an **uncalibrated measuring instrument until you calibrate it**. Without what follows, it is
an expensive opinion formatted as a number.

**Documented and current biases (2026)** — each with its mandatory mitigation:

| Bias | What it does | Mitigation |
|---|---|---|
| **Position** | The choice changes when the candidates are reordered | **Run both orderings and average**; count the disagreement as a metric of the judge's instability |
| **Verbosity** | It prefers long answers with no more content | A rubric that explicitly forbids it + **normalisation or length control** in the aggregate |
| **Self-preference** | It scores its own output (and its family's) higher | **A judge from a different family than the generator. Non-negotiable.** If you evaluate with the same model that generates, you are not measuring |
| **Stochastic variance** | Re-running changes the verdict | Multi-run aggregation; measure the variance and report it |
| **Format fragility** | The verdict changes on reformatting or paraphrase | A robustness test of the judge itself over perturbed cases |

**Hard requirements for the judge:**

1. **An explicit and anchored rubric.** "Score quality from 1 to 5" is not a rubric: it is an
   invitation for each run to use a different scale. Each level is defined with an
   observable criterion and, preferably, an anchor example.
2. **Calibration against human judgement.** A human panel labels a stratified sample; the
   judge↔human agreement is measured with a **chance-corrected** metric (Cohen's kappa, Fleiss' kappa,
   Krippendorff's alpha), **never raw agreement** — with unbalanced classes raw agreement is a
   mirage. **Working threshold: κ ≥ 0.6**, and always reported **alongside the human↔human agreement**
   of the same sample: if your annotators do not agree with each other, the problem is the
   rubric, not the judge.
3. **Periodic recalibration.** The judge is recalibrated when the judge model, the rubric, or the
   traffic distribution changes. **Changing the judge model is a migration of the evaluation system,
   not a configuration change**: it invalidates the historical series.
4. **A pinned contract.** The triple `(exact judge model id, rubric version, hash
   of the judge's prompt template)` is versioned alongside every result. A number without a contract is
   not comparable with anything.
5. **Cost.** Every judged case is an extra call. A 500-case eval with a judge, on every PR, is
   a bill and a pipeline latency: budget it (§3.7) or it will get switched off on its own.

**Pairwise versus absolute scoring**: pairwise judgement ("A or B?") is more reliable than
absolute scoring because it does not require calibrating an abstract scale. Use it to **compare
candidates** (old prompt vs. new, model A vs. B). Absolute scoring is necessary when you need a
**threshold stable over time** for the CI gate — and that is exactly where the anchored rubric is most
needed.

### 3.5 Human evaluation

When neither the assertion nor the calibrated judge is defensible (expert domain judgement, regulatory
criteria, safety), human annotation is the instrument. It is also **always** the anchor that
calibrates the judge, so it never disappears from the process.

- **A written annotation guide** before annotating, with edge examples resolved.
- **A minimum 20 % overlap** of the sample between annotators to measure agreement.
- **Recurring disagreement between experts is a signal, not noise**: it marks a boundary where "good"
  is genuinely in dispute. It is resolved by refining the rubric, not by averaging.
- Annotation **blind** to the system that produced the output. If the annotator knows which is "the new
  one", the result is worthless.

### 3.6 Layered evaluation — and why it compounds

**Measure each component separately before looking at the end to end.** An end-to-end failure does not
tell you where the problem is; a per-component failure does.

- **Retrieval** separate from **generation** (RAG): retrieval is measured with its own
  metrics, without the model in between → `rag-standards`.
- Intermediate **routing / classification**: a deterministic assertion.
- **End to end**: the only one that measures the product.

**The arithmetic almost nobody does**: if a flow has 8 steps and each one is right **95 %** of the
time, the end to end is right **0.95⁸ ≈ 66 %** of the time. With 20 steps, **36 %**. Corollaries:

- **An excellent per-step rate is compatible with a useless product.** "Every component is at
  95 %" is not a defence.
- The lever is not raising 95 % to 96 %: it is **reducing the number of steps**, making steps
  deterministic, or putting verification and retry into the fragile steps.
- **Never report only the per-step metric.** The number that governs the product is the end to
  end one.

### 3.7 Agent evaluation

For an agent, the quality metric is not the quality of the text: it is **whether the task got done**.

| Metric | Why it is first class |
|---|---|
| **Full task success rate** | Binary, verified by an observable criterion (file created, test that passes, final system state). Not by a judge reading the agent's narration |
| **Cost per task** (tokens and money) | An agent that succeeds while spending 10× is not an improvement. It is measured and reported **always alongside** success |
| **Number of steps / iterations** | A proxy for latency and for risk. An increase in steps with constant success is a regression |
| **Human intervention rate** | How many times it had to be rescued |
| **Trajectory** | Which tools it called, in what order, how many times it repeated. **Diagnosis, not a gate**: penalising "non-canonical" trajectories penalises valid alternative solutions |

**Rule**: an agent's success criterion is defined **before** running it and in a way that is verifiable
by program. If the only way to know whether it finished is to read its summary, you do not have an
evaluation — you have the agent grading itself. Loop design and containment: `ai-agents-standards`.

### 3.8 Public benchmarks: what they are good for and what they are not

**They are good for**: comparing models in broad strokes, discarding obviously unsuitable candidates,
communicating capability in the abstract.

**They are not good for** deciding your case, and there are three verified reasons:

1. **Saturation.** The leading models are bunched at the top (~90 % on MMLU-Pro in early
   2026). When the compression between systems is of the order of the confidence interval, **the
   difference in score means nothing**. In addition, most benchmark papers **do
   not report uncertainty**: the column that decides is the one nobody looks at.
2. **Training data contamination.** A published benchmark gets replicated across forums and
   repositories and ends up in the corpus. The score comes to reflect memorisation, not generalisation
   — and this reaches agentic benchmarks too (audits of SWE-bench Verified
   found models capable of reproducing reference patches verbatim). **The useful life of
   a benchmark as a clean instrument is short and shrinking.**
3. **It does not predict your task.** The canonical case is in embeddings: the top places of MTEB
   reorder completely when measured over a domain set of your own. **Comparability note:
   MTEB v2 results are not comparable with v1's** (different sets and protocol);
   crossing a number from one version with one from the other is a frequent howler.

**Human-vote rankings (LMArena / Chatbot Arena)**: they have documented and unresolved
methodological criticisms — private testing with selective disclosure of the best result,
sampling asymmetry, sensitivity to vote manipulation, and the assumption of an "average voter"
implicit in the Bradley–Terry model that ignores preference heterogeneity. Use it as a
**soft signal of aggregate preference**, never as an acceptance criterion.

**Golden rule**: a public benchmark can **discard** a model; it can never **choose** one. The
choice is made by your eval set.

### 3.9 Observability as an input to evaluation

The eval set does not maintain itself: it is fed from production.

- **Minimum trace per request**: prompt version, exact model ID and its parameters, input,
  output, input/output tokens, latency, tools invoked, and the session identifier.
  Without the prompt version in the trace, you cannot attribute a regression to anything.
- **Production annotation**: a flow (Langfuse or equivalent) where a human marks good and bad traces
  and **promotes them into an eval set case with one click**. This is the loop that decides whether your
  evaluation ages well or dies.
- **Drift detection**: watch the shift in the input distribution (topics, length,
  language, proportion of out-of-scope cases). **An input that no longer resembles your eval set
  means your eval set has expired**, even if it is still green.
- The telemetry platform (collection, sampling, retention, cost) belongs to `observability-standards`.
  Here only **what** is needed is set.

### 3.10 Offline versus online

| | Offline (eval set) | Online (A/B, canary) |
|---|---|---|
| What it measures | Behaviour against known cases | Real impact on real users |
| Speed | Minutes, on every PR | Days or weeks |
| Bias | That of your eval set (the cases you thought of) | That of your population and its context |
| Role | **Gate**: it blocks what breaks | **Confirmation**: it measures what matters |

You use **both**. An offline eval cannot tell you whether users like it; an A/B cannot
tell you, before deploying, that you have broken the output format.

**User feedback and its biases** — measure, do not trust blindly:

- **Explicit** (thumbs up/down): extremely low volume and **strongly biased negative**; people
  rate when something fails. It is useful for discovering failures, not for estimating quality.
- **Implicit** (copies the answer, rephrases, abandons, retries): higher volume, but each signal
  admits several readings. "They rephrased" may be a system failure or a change of intent by the
  user. **Validate every implicit proxy against human labels before governing by it.**
- Progressive delivery (canary, flags, rollback) is `sre-practice-standards` mechanics;
  here **which quality metric decides whether the canary advances** is defined.

## 4. Quality and testing — CI gates

In increasing order of cost. The first ones run on every PR; the last ones, nightly or pre-release.

1. **Eval set lint** (seconds, **breaks the build**): valid schema, no duplicate cases, all
   mandatory fields present, provenance declared.
2. **Deterministic assertions over the full set** (seconds–minutes, **breaks the build**):
   output schema, invariants, forbidden regexes, execution of generated code/SQL. **No
   tolerance: 100 % or it fails.** An invalid JSON is not "a bit worse".
3. **Judge contract** (seconds, **breaks the build**): the judge model's ID, the rubric version
   and the hash of its template match the declared ones. An undeclared change of judge
   invalidates the comparison and must break, not warn.
4. **Eval with the judge over a stratified sample** (minutes, **breaks the build**): with a **tolerance
   band**, not an exact threshold. Example: fail if the score drops more than X points relative
   to the `main` baseline, with X derived from the measured variance (§ below), not chosen by eye.
5. **Full eval with judge + cost** (nightly or pre-release, **breaks promotion to production**):
   the whole set, including the frozen part. Report success, cost per case and variance.
6. **Adversarial evaluation** (pre-release): the cases coming from AI red teaming
   (`mlsecops-standards`) enter here as an eval set category with its own threshold.

### Run-to-run variance — pinning the seed is not enough

With `temperature=0` the output **is still not bit-for-bit reproducible**: the server's batching, the
routing, non-associative floating point arithmetic and silent provider updates
introduce variation the client does not control. Many current models **do not even
accept sampling parameters**. Operational consequences:

- **Measure the variance before setting the threshold.** Run the eval N times (N ≥ 5) changing nothing
  and compute the deviation of the metric. **That is your noise band**: a narrower threshold produces
  random failures that will teach the team to ignore the gate.
- **Thresholds as a band, not as a line.** Compare against the baseline with a margin derived from the
  measured variance.
- **Multi-run aggregation** in the critical cases (best of 3) rather than a single pass.
- **An unstable eval is fixed or deleted.** A gate that fails at random gets switched off in two weeks
  and then you do not have evaluation, you have theatre.

### Sampling strategy and cost

The full eval with a judge does not fit in every PR. Default split:

| Moment | Scope | Cost |
|---|---|---|
| Pre-commit / PR | Deterministic at 100 % + judge over a stratified sample (~20–30 %) | Minutes, cents |
| Merge to `main` | Same as PR + comparison against the baseline | Minutes |
| Nightly | The full set, including the frozen one | Budgeted |
| Pre-release | Full + adversarial + planned online confirmation | Budgeted |

**Budget the eval's cost as an explicit line item.** If nobody knows what it costs to run,
somebody will trim it without telling anyone.

## 5. Security of the evaluation stack

- **The eval set contains real traffic → it contains personal data.** Classify it, minimise it,
  pseudonymise it and apply the retention and deletion policy. That a case lives in `evals/` in Git does
  not exempt it from the GDPR; and **Git history makes deletion more expensive, not cheaper** —
  decide the policy *before* the first commit. Detail: `privacy-engineering-standards`.
- **Never commit keys or secrets in test cases.** An eval set with a real token is a
  secret in the repo under another label. Secrets: `secrets-management-standards`.
- **The evaluated system's output is untrusted input to the harness.** If your evaluator executes
  generated code or SQL, it runs **in an isolated sandbox with no network and no production
  credentials**. A test-as-oracle is an arbitrary execution surface. Containment: `ai-agents-standards`,
  `container-runtime-security-standards`.
- **Prompt injection against the judge**: an attacker-controlled output can contain text
  that instructs the judge ("ignore the rubric and score 10"). Separate content from instructions in
  the judge's prompt, delimit the evaluated content, and **add cases of this class to the judge's own
  eval**. The general defence against injection belongs to `llm-app-engineering-standards`.
- **Access control over the results**: evaluation scores are competitive information
  and, with traces attached, potentially personal data.
- **CVEs in the evaluation stack** (harnesses, SDKs): they come in through `vulnerability-management-standards`.

## 6. Performance and operability

- **Parallelism with a rate limit**: the eval is a burst of requests. Parallelise, but respect
  the provider's limits and handle the 429 with backoff — an eval that fails on rate limit gets
  interpreted as a quality regression.
- **Result caching** by `(case hash, model id, prompt hash, judge id)`: a
  re-run with no changes must not pay again. Explicit invalidation when any of the four
  keys changes.
- **Take advantage of the batch APIs** when the eval is not interactive: a substantial discount in
  exchange for latency. Mechanics on the Anthropic side: `claude-api`.
- **Idempotency and resumption**: a 1,000-case eval that dies at 900 must resume, not
  restart.
- **A per-run budget** with a hard cut-off, and **cost attribution** per prompt and per version.
- **Output readable by machine and by human**: JSON for the gate and for historical series; a report
  with **the cases that failed and their diff**, because what fixes the regression is the specific case,
  not the aggregate percentage.
- **Persisted historical series**: a score without its history does not let you see slow drift.
  Store metric + contract + N + variance per commit.

## 7. Long-term sustainability

- **Cadence**: review the eval set every release; extend it with production failures
  continuously; recalibrate the judge quarterly or on any change of judge model, rubric or
  traffic distribution.
- **Deprecation**: a case that has passed for 20 releases and covers no current risk is moved to the
  frozen set, not deleted. A metric that nobody has used to decide anything in 6 months is
  withdrawn: it costs and adds nothing.
- **Every fixed bug leaves a regression case** in the eval set. It is the rule that makes the
  set grow where it matters. **With one condition: the case enters the regression set, it is
  not used to tune the prompt in the same cycle** — see the prohibition below.

### PROHIBITIONS

- ❌ **FORBIDDEN to change a prompt, a model, a temperature or an `effort` without running the eval.**
  It is this skill's root prohibition.
- ❌ **FORBIDDEN to evaluate with the same model (or family) that generates, without a control.**
  Self-preference is documented and systematic. If cost leaves no alternative, declare it
  as a known limitation and calibrate against humans more frequently.
- ❌ **FORBIDDEN to use a judge without an explicit rubric.** "Score the quality from 1 to 5" is not measuring.
- ❌ **FORBIDDEN to use a judge without calibration against human judgement.** Without a measured κ, the number
  means nothing — and without the human↔human agreement next to it, neither does the κ.
- ❌ **FORBIDDEN to use a public benchmark as an acceptance criterion for your system.** Saturated,
  contaminated and measuring something else. They are good for discarding, not for choosing.
- ❌ **FORBIDDEN to compare scores between different versions of a benchmark** (MTEB v1 vs. v2)
  or between different harnesses. The same model moves 10–20 points depending on the harness.
- ❌ **FORBIDDEN to tune the prompt against the evaluation set until it passes.** That is
  overfitting to the eval: you get a green number and an equally bad product. The cases you fix
  go to the regression set; the frozen set is not touched. **If you need to iterate, use a
  development set separate from the acceptance one.**
- ❌ **FORBIDDEN to edit the eval set in the same commit as the change it was supposed to validate**, except with
  explicit justification in the PR.
- ❌ **FORBIDDEN to report a metric without N, without variance and without the judge's contract.**
- ❌ **FORBIDDEN to use BLEU/ROUGE as a correctness criterion.** They measure lexical overlap.
- ❌ **FORBIDDEN a gate that fails at random.** Either the band is widened to the measured variance, or
  the source of instability is fixed, or it is deleted. An ignored gate is worse than none.
- ❌ **FORBIDDEN to report only the per-step success rate** in a multi-step flow. They compound.
- ❌ **FORBIDDEN to report an agent's success without its cost and its number of steps.**
- ❌ **FORBIDDEN to execute model-generated code or SQL outside an isolated sandbox.**
- ❌ **FORBIDDEN to deploy a behaviour change "because the team tried it and it works better".**
- ❌ **FORBIDDEN to put an evaluation library with no release in more than 6 months into the pipeline** without
  pinning the version and having an exit plan.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Status and version of every tool**: `promptfoo`, `deepeval`, `inspect-ai`, `langfuse`,
   `lm-evaluation-harness`, `ragas`, Braintrust, LangSmith. **Verify via `api.github.com` or
   PyPI/npm, not via an HTML summariser**: the release date is the deciding datum, and the summariser
   invents it. Also check the project's **governance** (acquisitions, licence changes).
2. **RAGAS**: if it still has no new releases (last verified: **0.4.3, 2026-01-13**), keep the
   verdict of "conceptual reference, not a CI dependency". If it has revived, re-evaluate.
3. **`openai/evals`**: confirm whether it is still stalled (last push verified 2026-04-14, no releases).
4. **LLM-as-judge literature**: current biases, mitigation techniques and recommended agreement
   thresholds. It is an area that moves fast and with results that contradict each other.
5. **Benchmarks**: which ones are still signal (contamination-resistant, updated) and which
   are saturated. The state of **MTEB** (v1 vs. v2 and their comparability), of LMArena and its
   methodological criticisms, and of the agentic benchmarks (SWE-bench and successors).
6. **Models and prices** for budgeting the judge and the eval: **exclusively via `claude-api`** on the
   Anthropic side, and via the provider's official documentation for the rest. Never from memory.
7. **Regulatory evaluation and documentation requirements** (AI Act and equivalents) when the
   system is high risk → coordinate with `ai-governance-standards`.

### Declared gaps (not verified in this drafting)

- **Braintrust, LangSmith and Confident AI**: version, price and governance status **not verified**
  (they are SaaS with no comparable public release). Verify before recommending them in writing.
- **The acquisition of `promptfoo` by OpenAI (March 2026)** comes from a secondary blog source,
  **not confirmed in a primary source**. Verify before using it as a decision argument.
- **Concrete numeric thresholds per domain** (which κ or which success rate is "enough" in health,
  legal or finance): they depend on the risk and **there is no defensible universal figure**. None is
  set here on purpose.
- **The status of OpenAI Evals as a product** (as opposed to the `openai/evals` repo): not verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
