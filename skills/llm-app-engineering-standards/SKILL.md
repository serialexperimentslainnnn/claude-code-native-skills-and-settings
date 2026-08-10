---
name: llm-app-engineering-standards
description: Provider-agnostic engineering standards for product code backed by an LLM. Use when deciding whether a task needs an LLM at all, picking a model per task by capability/cost/latency and routing by difficulty, versioning prompt templates in the repo, enforcing JSON Schema structured output instead of parsing prose, budgeting the context window and ordering it for prefix-cache hits, streaming and cancellation UX, retries/timeouts/degradation and per-user spend caps, tokens-per-request as a first-class metric with prompt-version tracing, defending against prompt injection and treating model output as untrusted input, or testing non-deterministic behaviour with golden cases and contract assertions.
---

# LLM application engineering standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **building a product on top of a language model as an engineering discipline**, in a
**provider-agnostic** way: the decision of whether an LLM is needed at all, model choice per task, the
prompt as a code artifact, structured output and its validation, the context window as a
scarce resource, prefix caching, streaming and its UX, reliability (retries, timeouts,
degradation, spend limits), observability and cost attribution, domain security
—starting with prompt injection— and testing the non-deterministic.

Triggers: prompt template versioned in the repo (`prompts/*.md`, `*.jinja`, `*.prompt`),
`response_format` / `json_schema` / structured output, "parse the model's response",
"context window", "prompt cache", "stable prefix", "tokens per request", "cost per
user", "retry with backoff on a model call", "token streaming", "cancel the
generation", "prompt injection", "prompt injection", "system prompt leak",
"the model does not return valid JSON", "the test fails because the response changes", model
routing by difficulty, abstraction layer between providers.

**Guiding principle**: **non-determinism is permanent; the engineering around it is what makes it
operable.** Everything in this skill exists to bound it: schemas at the edge, golden cases instead of
exact equality, spend limits instead of trust, and untrusted content separated from
instructions. Hard corollary: **if a rule, a `grep` or a classical classifier solves the
problem, adding an LLM buys permanent cost, latency and non-determinism in exchange for nothing**
(§2).

**Not applicable**:

- **`model-finetuning-standards`** (closes the escalation order this skill
  starts): **prompt first (here), retrieval next (`rag-standards`), and only then fine
  tuning (there)**. The criteria that avoids the expensive mistake, held by both sides: **fine tuning
  fixes format, style and task consistency; it does NOT fix ignorance of facts**, which is
  what most people believe and why they fine-tune when they should retrieve. Theirs too is everything that
  touches the weights —PEFT/LoRA, preference alignment, catastrophic forgetting— and **the licence of the
  weights**, which is rarely what it looks like.
- **`claude-api`** (no `-standards` suffix, **already-installed skill and canonical reference on the
  Anthropic side**): everything **Anthropic-specific** is theirs and is not repeated here — model IDs,
  prices, context windows, parameters (`thinking`, `effort`, `output_config`, `speed`,
  `task_budget`), the exact mechanics of prompt caching, tool use, MCP, Managed Agents, Batches,
  Files, migration between models and error codes. **Arbitration rule: if the answer contains
  an Anthropic identifier, price, beta header or parameter name, it belongs to `claude-api`;
  if it is the agnostic criteria you would apply with any provider, it belongs to this skill.** Never
  contradict its content nor quote Claude API data from memory: it is read from there.
- `ai-agents-standards`: the **autonomous agentic loop** — planning,
  tools, memory, subagents, multi-agent, stop criteria. **Key boundary**: here we
  cover the application of **a single turn or a deterministic pipeline that you orchestrate**; there, the
  loop where the model decides what to do next. If you write the control flow, it belongs
  to this skill; if the model decides it, it is theirs.
- `llm-evaluation-standards`: **evaluation is theirs** — evaluation
  sets, LLM-as-judge and its calibration, prompt regression, metrics and their significance.
  Here it is **required as a gate** (§4) and we define what gets versioned so evaluation is
  reproducible, but how it is measured lives there.
- `rag-standards`: the **retrieval pattern** — ingestion, chunking, embeddings, vector store,
  hybrid retrieval, reranking, citation. An LLM application may not use RAG; RAG is used
  **from** an LLM application. Prompting and evaluation are **not duplicated**: they live here and in
  `llm-evaluation-standards` respectively.
- `mcp-standards`: the MCP protocol, its primitives, transports, authorisation and the security of its
  servers (tool poisoning, rug pull, confused deputy).
- `mlsecops-standards`: security of the **model lifecycle** — AI red
  teaming, data and weight poisoning, model provenance.
- `local-inference-standards`: serving open models (vLLM, llama.cpp,
  Ollama, SGLang), quantisation, batching, server-side KV cache.
- `gpu-computing-standards`, `mlops-standards`: hardware and the lifecycle
  of your own models.
- `ai-governance-standards`: the AI Act as governance, risk
  classification, transparency obligations and regulatory documentation.
- `appsec-standards`: the classical vulnerability classes (OWASP Top 10 web/API, ASVS, STRIDE) and
  finding triage. **Prompt injection and the OWASP Top 10 for LLM Applications belong to
  this skill** — `appsec-standards` explicitly declares that it does not cover them.
- `privacy-engineering-standards`: personal data, minimisation, deletion, consent, PII that leaks
  into traces and prompts, and how the AI Act fits with personal data. Here we only **require** not
  putting PII in the trace and link there.
- `observability-standards`: OpenTelemetry, the Collector, Prometheus, backends and cardinality. **Token/cost
  metrics and LLM traces (prompt, prompt version, model, result) belong to
  this skill**; transport, backend and cardinality control are theirs.
- `api-design-standards`: the contract of **your** API outwards (OpenAPI, RFC 9457 errors,
  idempotency, pagination) when you expose the LLM functionality as a service.
- `secrets-management-standards`: custody and rotation of the provider's API keys.
- `data-platform-standards`, `object-storage-standards`: the engines where you persist conversations,
  traces and artifacts.
- `python-standards` / `typescript-standards`: the implementation (typing, async, tests, packaging).
- `sre-practice-standards`, `incident-management-standards`, `cicd-standards`,
  `kubernetes-standards`, `microservices-architecture-standards`, `identity-access-management-standards`,
  `cryptography-pki-standards`, `grc-compliance-standards`, `backup-recovery-standards`,
  `bcdr-standards`, `detection-engineering-standards`, `vulnerability-management-standards`: their
  domains unchanged.

## 2. Default decisions

> Verify on the web before pinning anything in a real project (§8). This is the catalogue domain
> where data goes stale fastest: framework versions, model capabilities and prices
> change in weeks.

### 2.1 The starting decision: is an LLM needed?

Before choosing a model, answer this in writing. An LLM in the critical path introduces **four
permanent costs**: money per request, seconds of latency, non-determinism and an external
dependency with its own availability.

| If the problem is… | Correct solution | The LLM is **vetoed** barring an ADR |
|---|---|---|
| Extracting a fixed-format field | Regex, parser, `grep` | ✅ vetoed |
| Classifying into N classes with labelled data | Classical classifier (logistic regression, gradient boosting, embeddings + kNN) | ✅ vetoed if there are >~1,000 labelled examples |
| Looking up an exact match or one by known synonyms | Lexical index / synonym table | ✅ vetoed |
| Validating, computing or deciding deterministically | Code | ✅ **always vetoed**: an LLM is neither a calculator nor a rules engine |
| Generating, summarising, rewriting, translating open text | LLM | Legitimate use |
| Extracting structure from unstructured, variable text | LLM with structured output (§2.4) | Legitimate use |
| Classifying without labelled data, in an open domain | LLM (and **label with it to train a classifier** if the volume justifies it) | Legitimate use, with an escape output |

**The most cost-effective pattern in the domain**: use the LLM to **generate the labelled dataset** and then
serve with a cheap, deterministic classical classifier. If volume is high and the task stable,
this cuts cost and latency by orders of magnitude.

### 2.2 Model choice per task, not by fashion

| Decision | Default | Reason |
|---|---|---|
| Model per task | **One per task, chosen by your own evaluation**, not one global model | The reasoning task and the classification task do not share the same cost/latency profile |
| Complex reasoning, long-horizon agents, code | Large model of the current generation | The quality difference dominates the cost |
| Classification, routing, field extraction, short rewriting | **Small/fast model** | A large model here is pure waste |
| Routing by difficulty | **Yes, if traffic is heterogeneous and volume justifies it** | Small model by default + escalation to a large one on signal (length, confidence, schema failure, difficulty classifier) |
| Provider abstraction layer | **Thin and your own**: an interface with `generate(prompt, schema, options) -> result` | Lets you switch providers and A/B test models **without** trying to abstract everything |
| Full portability between providers | **Expensive myth. Forbidden to chase it** | Prompts, tools, caching, structured output and reasoning are not equivalent across providers; an abstraction that pretends otherwise hides capabilities and adds bugs |
| Single provider with no layer | **No**: even if you never switch, the layer is what makes the code testable (§4) and enables the *fallback* (§2.8) | — |
| Pinning the model | **Explicit pin of the model identifier in configuration**, never a floating alias in production | An alias that moves changes your product's behaviour without deploying anything |

**Decision rule**: do not choose a model by public benchmark. Choose by **your** evaluation
set (`llm-evaluation-standards`). Public benchmarks are saturated and contaminated; they are
a signal of what to test, not truth.

**Scepticism about frameworks.** Verified as of August 2026 (versions and status in §8):

| Framework | Status (Aug 2026) | Criteria |
|---|---|---|
| **Official provider SDK** (+ your own ~200-line layer) | — | **Default for most applications.** The smallest surface, zero magic, trivial debugging |
| **LangChain 1.x / LangGraph 1.x** | 1.0 GA since Oct 2025; `langchain-core` in the 1.5.x series (Jul 2026); 0.3.x in maintenance; `langgraph.prebuilt` deprecated in favour of `langchain.agents` | LangGraph adds real value if you need **stateful graphs with durable execution and resumption**; LangChain "to call a model" adds more complexity than it removes. If you migrate from 0.3.x, it is a migration, not a `pip install -U` |
| **LlamaIndex** (0.14.x, Jun 2026) | Active | Oriented to ingestion/retrieval → its natural home is `rag-standards`, not the generic app |
| **Haystack** (3.0.0, Jul 2026) | Active, **recent major** | Breaking major change: do not adopt or upgrade it without reading the migration guide |
| **DSPy** (3.2.x stable; 3.3.0 in beta, May 2026) | Active | Interesting when the prompt is **optimised against metrics** instead of written by hand; requires a real evaluation set or it is useless |
| **Instructor** (1.15.x, Jun 2026) | Active | Structured output with validation retry. Unnecessary if the provider already offers a strict native schema (§2.4) |
| **Pydantic AI** (2.x series, weekly releases, Aug 2026) | Very active | Good typed option in Python; extremely high cadence → **pin the version and read the changelogs** |
| **Semantic Kernel** (Python 1.44.x / .NET 1.78.x, Jul 2026) | Active | Reasonable in the .NET ecosystem; in Python it competes at a disadvantage |

**Forbidden to adopt a framework "just in case".** It is adopted when it solves a problem you already
have and that your own layer does not solve, and it is recorded in an ADR with the exit cost.

### 2.3 The prompt is code

| Decision | Default |
|---|---|
| Where it lives | **Versioned file in the repo** (`prompts/<domain>/<name>.<version>.md` or equivalent) |
| Where it does **not** live | ❌ In the database. ❌ Embedded in the middle of the logic. ❌ In a spreadsheet. ❌ Only in the provider's prompt playground |
| Composition | Template with **explicit variables** (templating engine with escaping, not string concatenation) |
| Review | **In a PR, with a readable diff.** A prompt change is reviewed by someone who did not write it |
| Versioning | Stable version identifier that travels in the trace (§6) |
| Prompt change | **It is a behaviour change**: it requires evaluation before merging (§4) |

**Why the database is forbidden as the prompt's home**: you lose the diff, review, atomic rollback
alongside the code that consumes it, and the correlation between prompt version and release
version. If the business needs to edit prompts without deploying, that is a **product feature** with
its own approval and evaluation flow, not an excuse to take them out of version control.

**Prompt content — hard rules**:
- No credential, key or secret. Ever. Prompts end up in logs, traces and summaries.
- No hard-coded personal data (`privacy-engineering-standards`).
- Untrusted content is **never** concatenated with instructions: it goes delimited and tagged
  as data (§5).
- No contradictory instructions accumulated by sedimentation. A prompt is code: it is
  refactored and dead parts are deleted.

### 2.4 Output structure

| Decision | Default |
|---|---|
| Output format when the consumer is code | **Native structured output with JSON Schema** from the provider, in strict mode if it exists |
| If the provider does not offer it | **Tool call with a schema** as a substitute; free text only as a last resort |
| Parsing prose with regex | ❌ **FORBIDDEN** unless the output is for a human. It is guaranteed debt |
| Validation | **Always at the edge**, with the same schema, even if the provider promises compliance |
| Schema | Closed (`additionalProperties: false`), explicit required fields, `enum` for finite sets |
| Escape field | **Mandatory**: the schema includes a way to say "I don't know" / "not applicable" |

**Schema design**: simple, flat schemas are complied with better than deeply
nested or recursive ones. Many providers additionally restrict the supported JSON Schema subset
(recursion, `minLength`, `minimum`…) — **verify the subset before designing**, and validate
client-side whatever the provider does not support.

**When the model does not comply with the schema** (it happens, even in strict mode — through truncation, through
refusal, or through a token limit):

1. **Check the stop reason first.** Truncation by token limit and refusal by policy are not
   fixed by retrying the same way: the first needs more output budget, the second is a
   product response, not a transient error.
2. **One retry with the validation error in the context** ("your response failed validation:
   *<error>*; return only JSON conforming to the schema"). One, not a loop.
3. **If the retry fails: explicit degradation** — return a typed error to the caller or the
   non-LLM path. Never invent a default value the user cannot tell apart from a real
   response.
4. **Count the failure as a metric** (`llm.schema_violation_total`): a rising rate is a signal
   of a change of model, of prompt or of input distribution.

### 2.5 The context window is a scarce resource

That the context is 1M tokens **does not mean using it is a good idea**. It is documented —and
consistent across models— that quality degrades with input length well before the announced
limit, and that information in the middle of the context is used worse than that at the extremes.

| Decision | Default |
|---|---|
| What goes in | **Only what answers the question.** Every block must justify its presence |
| Putting everything in "just in case" | ❌ **ANTIPATTERN.** It raises cost and latency and **lowers** quality |
| Order | **Stable first, volatile last** (§2.6). The most relevant, near the extremes |
| Budget | Set explicitly per route and **measured** (`llm.input_tokens` per feature, §6) |
| Long history | Compaction/summarisation with an explicit policy: what is summarised, what is kept verbatim, and what is lost |
| Compaction | It is **information loss with criteria**. Document what is sacrificed; never introduce it silently on a route where the detail is load-bearing |

**Operating rule**: if you cannot say why each block of the context is there, it is surplus. The context
budget is designed before writing the code, just like the latency budget.

### 2.6 Prompt caching: a first-order cost lever

The principle is **universal and agnostic**: the cache is a **prefix** match. A byte that
changes at position N invalidates everything from N onwards.

Three provider-independent rules follow from that:

1. **Stable prefix first, volatile last.** Frozen instructions and tools at the
   beginning; question, timestamps, IDs and user state at the end.
2. **Deterministic serialisation.** Sorted keys, no iterating sets, no `now()` nor UUID in the
   prefix. A `datetime.now()` in the system prompt destroys the cache of the whole application and **does
   not produce any error**: only a bigger bill.
3. **Verify it hits.** If the cache-read metric is zero between requests with an identical
   prefix, there is a silent invalidator. It is a cost bug, and it is treated as a bug.

> The **concrete mechanism** (markers, TTL, number of breakpoints, cacheable minimum, invalidation
> table) is **provider-specific**. For Anthropic it lives in `claude-api`; for others, it is
> read from their documentation. Here only the principle.

### 2.7 Streaming and UX

| Decision | Default |
|---|---|
| Streaming | **Yes** in any interface where a human waits, and in any request with long output or a high `max_tokens` (it also avoids HTTP timeouts) |
| Streaming | **No** when the consumer is code that needs the full response validated against a schema: it complicates without adding |
| Cancellation | **Mandatory and end-to-end**: the user cancels → the request to the provider is aborted. A cancelled stream that keeps generating is billed all the same |
| Failure mid-stream | The partial content already emitted **is billed**. Handle it explicitly: mark the response as incomplete in the UI, do **not** persist it as complete, and do not pass it to a consumer that assumes integrity |
| Resumption | Most APIs do not resume a cut stream. If you need resilience, it is a full retry (§2.8), not a continuation |
| Latency perception | *Time to first token* is the metric the user perceives; total latency is the one your SLO pays for. **Measure and alert on both** |

### 2.8 Reliability

| Decision | Default |
|---|---|
| Timeouts | **Always explicit**, per route. SDK defaults are minutes long and are not your SLO |
| Retries | Exponential backoff **with jitter**, attempt cap, **and only on idempotent operations** |
| Retry on an operation with side effects | ❌ **FORBIDDEN** without an idempotency key. An agent that retries a turn that already sent an email sends it twice |
| What is retried | Network errors, 408/429/5xx. **Never** 400/401/403/404 |
| What is **not** retryable | **A bad response.** A 200 with incorrect content is not a transient failure: it is a quality problem (evaluation) or a content one (refusal, schema). Retrying hides the signal |
| Policy refusal | It is a **product outcome**, not an error. Explicit degradation path, with a message to the user |
| Controlled degradation | Defined per route: alternative model, smaller model, cached response, non-LLM path, or an honest error. **Never** an invented response |
| Spend limit | **Two levels: per request and per user/tenant and time window.** Without this, a loop or an abuser turns your bill into an incident |
| Circuit breaker | On the provider, as with any external dependency (`microservices-architecture-standards`) |
| Queue / backpressure | For non-interactive loads, use the provider's batch path if it exists (typically much cheaper) instead of hammering the synchronous API |

**The distinction that is most often botched**: *network error* versus *bad response*. The first is
retried; the second is measured, evaluated and corrected in the prompt, the model or the schema. A
system that retries bad responses spends twice as much and does not improve.

## 3. Structure and conventions

```
src/
  llm/
    client.py            # thin layer: generate(prompt, schema, options) -> result
    models.py            # model registry per task + routing policy
    budget.py            # spend limits per request and per tenant
    tracing.py           # trace attributes (§6)
prompts/
  extraccion/
    factura.v3.md        # template + variables documented in the header
    factura.schema.json  # output schema, versioned alongside the prompt
  clasificacion/
    intencion.v7.md
evals/                   # evaluation sets → see llm-evaluation-standards
  extraccion_factura/
    casos_dorados.jsonl
    bordes.jsonl
```

Conventions:

- **Prompt and schema travel together and share a version.** Changing one without the other is a bug.
- The header of each template documents: purpose, variables, target model, version, and the
  evaluation set that covers it.
- The model registry (`models.py`) is the **only** source of model identifiers. No
  literal identifier scattered through the code.
- **The client layer is the only one that talks to the provider.** That is what allows mocking it in
  tests, instrumenting it once and switching providers without surgery.
- Untrusted content is marked in the type, not only in the prompt: `UntrustedText` versus
  `str`. What the type system distinguishes, the developer does not mix by accident.

## 4. Quality and testing — gates

**The problem**: `assert response == "..."` does not work. The output is non-deterministic, and even if
you pin sampling parameters exact equality is fragile and does not measure what matters.

**The strategy**, in order of increasing cost:

1. **Contract tests over the schema** (fast, deterministic, no network). The result validates
   against the schema, the required fields exist, the `enum`s are in range, the types are
   correct. **These are binary and they do go into CI on every commit.**
2. **Layer tests, with the provider mocked.** Timeouts, retries, spend limits,
   degradation, cancellation, schema-violation handling, refusal handling. **All the
   reliability behaviour of §2.8 is deterministic and must have a unit test.**
3. **Invariants over the output** (property-based): bounded length, absence of PII, absence of
   system-prompt markers, citation present when required, correct language.
4. **Golden cases**: representative inputs + expected output, evaluated with a **non-exact**
   acceptance criteria (key fields correct, semantic similarity over a threshold, calibrated
   judge). Detail in `llm-evaluation-standards`.
5. **Prompt regression evaluation**: compare the candidate version against the current one over the
   full set.

### Gates that break the build

| # | Gate | Breaks if |
|---|---|---|
| 1 | Lint + types + format (`python-standards` / `typescript-standards`) | It fails |
| 2 | **No literal model identifier outside the registry** | `grep` finds one |
| 3 | **No prompt outside `prompts/`** (neither a multiline instruction string in the code, nor a prompt loaded from a database) | It fails |
| 4 | Every prompt has a versioned output schema next to it, **if its consumer is code** | It is missing |
| 5 | Schema contract tests | One fails |
| 6 | Reliability tests with a mocked provider (timeout, retry, spend, degradation, cancellation) | One fails |
| 7 | **No provider call without an explicit timeout and without a spend cap** | It fails |
| 8 | **No unit test calls the real API** (cost, flakiness, non-determinism) | It fails |
| 9 | **Evaluation mandatory if the diff touches `prompts/`, the schema or the model identifier**, with a declared non-regression threshold | Regression over the threshold |
| 10 | SCA of AI stack dependencies (§5) | Critical vulnerability or package not pinned by hash |
| 11 | Secret scanning over `prompts/` in addition to the code | It finds something |

**Zero flakiness**: a test that fails 1% of the time due to non-determinism is fixed (by moving
the assertion to an invariant or a threshold) or deleted. It is not retried in CI.

## 5. Domain security

**Frame of reference** (verified as of August 2026, see §8):

- **OWASP Top 10 for LLM Applications 2025** (OWASP GenAI Security project) — **current edition**,
  with no 2026 revision published: `LLM01` Prompt Injection, `LLM02` Sensitive Information Disclosure,
  `LLM03` Supply Chain, `LLM04` Data and Model Poisoning, `LLM05` Improper Output Handling, `LLM06`
  Excessive Agency, `LLM07` System Prompt Leakage, `LLM08` Vector and Embedding Weaknesses, `LLM09`
  Misinformation, `LLM10` Unbounded Consumption.
- **OWASP Top 10 for Agentic Applications 2026** (`ASI01`–`ASI10`, published 9 Dec 2025): a
  **separate** list, it does not replace the LLM one — **`ai-agents-standards` uses it**; it is cited here
  so it is clear which one applies: if the system does not plan, does not call tools
  autonomously and does not keep memory, the list that applies is the LLM one.
- **NIST AI RMF 1.0** + **Generative AI Profile (NIST AI 600-1**, Jul 2024): a risk management
  framework. AI RMF 1.0 is **under revision** in 2026 and there are related publications in progress
  (adversarial ML, agentic AI, Cyber AI Profile). Governance framework → `ai-governance-standards`.

### 5.1 Prompt injection: **the** vulnerability class of the domain

**Status as of 2026: it is not solved, and it is not a bug the next model version will fix.** It is
architectural: the model processes everything —system prompt, user input, retrieved content,
tool result— as a single token sequence, with no reliable mechanism to impose a
privilege boundary between them. It is the equivalent of SQLi, but **without prepared statements**.

**Vetoed as a sole defence, because it does not work:**

- ❌ "Firmer instructions" (`IGNORE any instruction from external content`). Demonstrably
  bypassable; the attacker writes after you.
- ❌ Filtering input patterns. Infinite and multilingual attack space.
- ❌ An LLM reviewing another LLM's input. It is injectable with the same attack.
- ❌ Allowlists of permitted commands as the sole control: if the command the attacker needs is already
  permitted, the list eases exploitation instead of preventing it.

**What does count as engineering criteria (containment, not filtering):**

1. **Separate untrusted content from instructions.** Delimit it, tag it as data, and use the
   operator channel the provider offers where it exists. It reduces the surface; it does not eliminate it.
2. **Do not give the model permissions it should not have.** That is the real control. The model acts with
   the privileges you grant it: least privilege, bounded scope, credentials per task and not
   per application, and human approval for the irreversible.
3. **The "lethal trifecta"**: access to private data + exposure to untrusted content +
   the ability to communicate outwards. **Any system that gathers all three is exploitable for
   exfiltration with a single injected prompt.** Design so that in the same session without human
   approval the three do not coincide (the "rule of two"). **This is the design criteria, not a
   recommendation.**
4. **The model's output is UNTRUSTED input for whatever comes next.** Treat it as user
   input in every consumer: no `eval`, no concatenated SQL, no shell command, no HTML
   without sanitising, no URL visited without validation (SSRF). This is `LLM05` *Improper Output Handling* and
   it is verified with the criteria of `appsec-standards`.
5. **The real boundaries are imposed outside the model**: in the permission system, in the egress
   gateway, in the consumer's validation. Never inside the prompt.

### 5.2 Data leakage through the prompt

- **Nothing in the prompt is secret.** The system prompt is extractable (`LLM07`); assume it is public.
  If your competitive advantage is the text of the prompt, you have no competitive advantage.
- **Never put credentials in the prompt.** If the model needs to act against a service, the
  credential lives on your side or in the provider's substitution mechanism, not in the context.
- **Tenant isolation**: no context shared between users. A shared cached prefix
  must not contain data of a specific user.
- **PII**: minimise before sending; mask what is not needed. Provider retention,
  data residency and use for training are contractual decisions that are verified —
  `privacy-engineering-standards` and `grc-compliance-standards`.

### 5.3 Jailbreak versus abuse

They are not the same and they are not mitigated the same way:

- **Jailbreak**: the user tries to make the model produce content the policy forbids. The
  risk is reputational and regulatory. Mitigation: provider policy layers, your own output
  filters, logging and a repeat-offence threshold per account.
- **Economic abuse** (`LLM10` *Unbounded Consumption*): the user uses your product as a cheap
  proxy to the model, or triggers a loop. Mitigation: **authentication, per-user quota, spend
  cap, input and output token caps, and anomaly alerting**. This is engineering, not content
  policy, and it is the one that breaks the most bills.

### 5.4 AI stack supply chain

This ecosystem moves dependencies very fast and already has real incidents:

- **LiteLLM (PyPI, March 2026)**: versions `1.82.7` and `1.82.8` were published with malicious
  code after the CI pipeline was compromised, which ran **Trivy without a pinned version** from
  apt (the March 2026 Trivy precedent already recorded in the catalogue). A malicious `.pth` was
  executed on **every start of the Python interpreter**, even if LiteLLM was not used: credential
  theft, lateral movement in Kubernetes and persistence via systemd. It was live for tens of
  minutes with tens of thousands of downloads. **The last known good version is
  `1.82.6`; verify the current status before installing.**
- Applicable, non-negotiable lessons: **pin dependencies by hash**, verify that a tag and
  release exist in the repo matching the published artifact, run the pipeline's tools
  with a pinned version, and treat a host that installed a compromised version as
  compromised (deleting the package is not enough). Pipeline detail in `cicd-standards` and
  `vulnerability-management-standards`.

## 6. Cost and operability

**Tokens per request are a first-class metric**, at the same level as latency and the
error rate. Without it there is no cost control, and in this domain cost is the constraint that
kills projects.

### Minimum metrics

| Metric | Dimensions | What for |
|---|---|---|
| `llm.input_tokens`, `llm.output_tokens` | model, feature, tenant | Cost and context budget |
| `llm.cache_read_tokens` / `cache_write_tokens` | model, feature | Detecting silent cache invalidators (§2.6) |
| `llm.cost` (derived) | model, feature, tenant | Attribution and spend alerts |
| `llm.latency` (**total and to first token**) | model, feature | SLO and perception |
| `llm.requests_total` | model, result (`ok`/`refusal`/`schema_violation`/`timeout`/`error`) | Real health, distinguishing what is not an error |
| `llm.schema_violation_total` | model, prompt, prompt version | Early drift signal |
| `llm.stop_reason` | model | Truncations by output limit that you are serving as complete responses |

**Beware cardinality**: `tenant` as a metric label does not scale in Prometheus. Fine-grained
attribution goes to traces or an analytical store; the metric carries aggregates
(`observability-standards`).

### Traces

Every model call emits a span with, as a minimum: **model identifier, prompt version,
relevant parameters, input/output/cache tokens, stop reason, latency, result and
attempt number**. Without the prompt version in the trace you cannot correlate a quality
regression with the change that caused it — which is 80% of the debugging in this domain.

> ⚠️ **Prompt and response in the trace**: they are the most useful debugging tool and the greatest
> privacy risk in the system. Explicit decision per route: what is stored, with what retention,
> with what access control and with what PII redaction. **By default: do not store content in
> the clear on routes that handle personal data.** See `privacy-engineering-standards`.

### Actionable alerts

- Daily/hourly spend above threshold, **and** relative deviation from the baseline.
- Spend per tenant above its quota (before it becomes an incident).
- Cache read rate dropping sharply → silent invalidator, cost bug.
- Schema-violation or refusal rate rising → model or input drift.
- Mean input tokens growing with no release change → the context is fattening on its own.

### Operation

- **A provider model change is a behaviour change.** Pin the identifier,
  evaluate in preproduction, deploy with canary and have a tested rollback. A floating alias is an
  open door to a regression without a deployment.
- **Capacity**: the provider's rate limits are per organisation and per model, and they are not
  inherited when switching model. Check them **before** moving traffic.
- Minimum runbook: provider down, provider degraded, quota exhausted, spend spiking, quality
  regression after a prompt change.

## 7. Sustainability and prohibitions

**Cadence**: this domain is reviewed **every 3 months** (§7 of `claude-code-skills-standards`), not
every 6. Models, capabilities, prices and frameworks change in weeks.

- Review quarterly: identifiers and lifecycle of the models in use (retirement
  dates), prices, framework versions and stack CVEs.
- Every model in production has a **review date** and an identified successor. A model retired
  without a migration plan is a scheduled outage.
- Prompts get pruned: those no longer used are deleted; the associated evaluation sets,
  too.
- Conscious debt: every shortcut (free-text parsing pending a schema, pending evaluation,
  spend limit not implemented) is left as a TODO with a reason and an issue.

**FORBIDDEN**

- ❌ Putting an LLM where a rule, a `grep` or a classical classifier solves the problem.
- ❌ Using an LLM as a calculator, deterministic validator or rules engine.
- ❌ Prompts in the database, embedded in the logic, or outside version control.
- ❌ Changing a prompt without evaluation (§4 gate 9). A prompt change is a behaviour change.
- ❌ Parsing prose with regex when the consumer is code, structured output being available.
- ❌ Trusting the model's output without validating it against a schema at the edge.
- ❌ Inventing a default value indistinguishable from a real response when the model fails.
- ❌ Putting all the available context in "just in case".
- ❌ `now()`, UUID or non-deterministic serialisation in the cached prefix.
- ❌ Floating model alias in production.
- ❌ Retrying non-idempotent operations; retrying a bad response as if it were a network error.
- ❌ A provider call without an explicit timeout, without a token cap and without a per-user spend limit.
- ❌ An LLM endpoint without authentication or quota (free proxy to the model, `LLM10`).
- ❌ **Trusting "firmer instructions" as a defence against prompt injection.**
- ❌ **Gathering the lethal trifecta —private data + untrusted content + outbound egress— in
  one session without human approval.**
- ❌ Passing the model's output to `eval`, SQL, shell, HTML or a network request without treating it as
  untrusted input.
- ❌ Credentials, secrets or PII in the prompt or in the system prompt.
- ❌ Assuming the system prompt is private.
- ❌ `assert response == "..."` as a test strategy. Tests that call the real API in CI.
- ❌ Flaky tests tolerated "because the model is non-deterministic".
- ❌ Adopting an orchestration framework with no demonstrated problem and no ADR with the exit cost.
- ❌ Chasing full portability between providers; and at the same time, coupling to a provider without a thin
  abstraction layer that allows testing and switching.
- ❌ Choosing a model by public benchmark instead of by your own evaluation.
- ❌ Installing AI stack dependencies without pinning version/hash (§5.4).
- ❌ Repeating or contradicting `claude-api` content: Anthropic API data is read from there.

## 8. Mandatory web verification

Before pinning **any** data in this domain. It is the catalogue domain with the shortest half
life.

1. **Anthropic data**: it is not verified on the web from here — **it is read from the `claude-api` skill**,
   which is the canonical reference (model IDs, prices, parameters, caching, migration).
2. **Models from other providers**: exact identifiers, context window, input/output/cache
   price, output limits, retirement dates. **Never from memory.** Consult the
   official documentation and, where it exists, the provider's models endpoint.
3. **Frameworks**: latest version, maintenance status and major changes of LangChain/LangGraph,
   LlamaIndex, Haystack, DSPy, Instructor, Pydantic AI, Semantic Kernel. Verified as of Aug 2026;
   **discard whatever is abandoned**. Prefer release Atom feeds or the package index over the summary on
   an HTML page.
4. **OWASP Top 10 for LLM Applications**: confirm whether the **2025** edition is still current or whether a
   revision has already shipped (there was an update process open in mid-2026). Confirm also the
   current edition of the **Top 10 for Agentic Applications** (2026, `ASI01`–`ASI10`).
5. **NIST AI RMF**: status of the AI RMF 1.0 revision, of the Generative AI Profile (AI 600-1) and of
   the related publications (adversarial ML, agentic AI, Cyber AI Profile).
6. **Supply chain incidents** in any dependency you recommend: precedents in
   the catalogue — Trivy (March 2026), LiteLLM `1.82.7`/`1.82.8` on PyPI (March 2026), `gitleaks`
   (*feature complete*). Consult advisories before pinning a version.
7. **Status of prompt injection**: check whether any structural mitigation with
   evidence (not marketing) has appeared. As of August 2026 **there is none**; if the web says otherwise, verify the
   source before believing it.
8. **Degradation by context length**: public results on *context rot* and "lost in
   the middle" evolve with each generation. Re-verify before asserting a threshold.

**Declared gaps — do NOT fill from memory**:

- **Prices, context windows and model identifiers of non-Anthropic providers**: they are not
  pinned in this document **by decision**. They are verified at each use.
- **Sampling and reasoning parameters per provider** (temperature, effort, reasoning
  budgets): they diverge sharply between providers and generations; they are not documented here.
- **Concrete numeric thresholds** for degradation by context length, for relative
  RAG/long-context cost and for improvement from routing: they depend on the load and the public figures come
  in large part from provider blogs. **Measure it in your system.**
- **Rate limits per tier** for each provider: not verified; they are read from their console.

If the web contradicts this document, **the web wins** — flag the discrepancy.
