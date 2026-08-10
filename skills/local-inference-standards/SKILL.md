---
name: local-inference-standards
description: Use when serving open-weight LLMs on your own infrastructure — vllm serve, llama-server and llama.cpp, ollama serve with OLLAMA_HOST/OLLAMA_NUM_PARALLEL, SGLang, TGI or TensorRT-LLM, a self-hosted OpenAI-compatible /v1/chat/completions endpoint, .gguf and .safetensors weight files and their provenance, choosing AWQ/GPTQ/FP8/NVFP4/MXFP4/Q4_K_M quantization, sizing KV cache VRAM with --max-model-len, --gpu-memory-utilization and --tensor-parallel-size, prefill versus decode and TTFT/TPOT benchmarking under sustained load, open-weight model licences, or the break-even calculation of self-hosting versus a hosted inference API.
---

# Local inference standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **you serve an open model on your own infrastructure** (yours, the client's or
rented as bare metal) and the decision is an inference platform one:

- Deciding **local versus managed API**, and calculating the break-even point (§2.1).
- Choosing an **engine** (`vllm serve`, `llama-server`, `ollama serve`, SGLang, TGI, TensorRT-LLM)
  and justifying the choice against the real load pattern.
- **Quantisation**: format, level and what is lost (`.gguf`, AWQ, GPTQ, FP8, NVFP4, MXFP4).
- **Memory sizing**: weights + KV cache + activations; `--max-model-len`,
  `--gpu-memory-utilization`, `--tensor-parallel-size`, `--kv-cache-dtype`.
- **Measurement**: TTFT, TPOT, prefill vs. decode tokens/s, throughput under sustained load.
- **API compatibility**: the OpenAI contract (`/v1/chat/completions`, `/v1/completions`,
  `/v1/embeddings`) as the backend interchangeability layer.
- **Operations**: weight provenance and verification, model licence, updating, engine metrics,
  power consumption per million tokens.
- **Endpoint security**: authentication, exposure, network isolation of the distributed
  plane.

**Not applicable**: see `gpu-computing-standards` (the GPU as an infrastructure resource: driver,
CUDA, MIG/MPS, DCGM, XID, power and cooling — **an inference server without a GPU, on CPU
or on Apple Silicon, still belongs to this skill**), `llm-app-engineering-standards` (the
application that **consumes** the endpoint: prompts, structured output, retries, prompt
injection — **serving belongs here, consuming belongs there**; the boundary is the HTTP port),
`claude-api` (**canonical reference for the Anthropic API**: the managed alternative to local
inference lives there, and **no datum about Claude models —id, price, limits— is asserted
from memory**; consult it before comparing cost against a provider), `mcp-standards`
(MCP servers and their tools), `kubernetes-standards` (manifests, Helm, GitOps of the
deployment), `podman-systemd-containers-standards` (the engine as a Quadlet unit on a host),
`observability-standards` (OTel, PromQL, alerts — here we only say **which** engine metric
matters), `firewall-policy-standards` (the rule that does or does not expose the port),
`identity-access-management-standards` (the IdP and the token that authenticates the caller),
`secrets-management-standards` (where the endpoint's API key lives),
`linux-storage-standards` and `zfs-standards` (**where the weights live**: files of tens or
hundreds of GB, with their sequential read pattern and their space budget),
`backup-recovery-standards` (§6.4: public weights are almost never backed up),
`privacy-engineering-standards` (**the most common reason to serve locally is personal data**:
minimisation, legal basis and retention are decided there, not here),
`grc-compliance-standards` (audit evidence), `networking-standards`,
`onprem-standards` (platform umbrella: hardware, rack, power, management plane —
this skill is a layer inside its §1.2 and does not contradict its §1.3 invariants),
`homelab-standards` (**inference at home**: there cost, noise, power consumption and
proportionality rule; if the inference server is your personal lab with no third parties and no
SLA, that skill wins and this one contributes only the technical criteria), `python-standards` (client code or
evaluation script code), `vulnerability-management-standards` (triage and SLA for the §5 CVEs), `webgl-webgpu-standards`
(**if the model runs in the browser, WebGPU is the substrate and its criteria are
theirs** —adapter, device limits, context loss, GPU memory and degradation to
WebGL2—; **the choice of model, its quantisation and the memory budget still belong
here**. Shared and verified warning: **WebGPU is not Baseline** —no support on Firefox Android and
with per-GPU restrictions on desktop—, so a browser inference deployment
needs a degradation plan), `green-it-standards` (sizing, quantisation and
the break-even calculation against a hosted API belong here; **the energy
and carbon accounting of that training or that inference is theirs** — and the warning they share:
**the footprint figures cloud providers publish are not comparable with each other**, so
a "self-host versus API" calculation in carbon terms is not settled by subtracting two numbers from
different sources).

Also `rag-standards` (retrieval and embeddings — **serving the embedding model locally
belongs here; index design, chunking and reranking belong there**) and
`ai-agents-standards` (agent loop, tool surface, containment).

Additionally: `llm-evaluation-standards` (**measuring whether
the local model is good enough for the task belongs there**: this skill measures
*performance*, not *quality*), `mlsecops-standards` (**provenance, signing and scanning of the
model artefact: shared boundary** — the supply chain criteria are theirs, the
operational rule of "which weights does this server accept" belongs here), `mlops-standards`
(training, fine-tuning and model lifecycle, as opposed to serving it),
`ai-governance-standards` (AI Act, AI system inventory, impact assessment).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

### 2.1 The starting decision: local versus API

**Legitimate reasons to serve locally**

| Reason | When it is real |
|---|---|
| **The data cannot leave** | Contractual, regulatory or classification prohibition. It is the strongest reason and the most common. It comes alongside `privacy-engineering-standards`, it does not replace it |
| **Cost at high, sustained volume** | Only if utilisation is **high and continuous** (§2.2). A GPU at 15% is more expensive than the API |
| **Latency** | When the RTT to the cloud or the provider's queue variability breaks the SLO. Measure before assuming it |
| **Provider independence** | A model with weights on your disk is not deprecated and does not change behaviour without you deciding it. It is the most underrated advantage |
| **Version determinism** | The frozen model is reproducible; a managed endpoint can change under your feet |
| **Experimentation and learning** | Legitimate, but **declare it as such** and do not dress it up as a cost decision |
| **No connectivity** | Isolated environment, edge, ship, industrial plant |

**Bad reasons**

- ❌ **"It's free".** It is not. The cost is hardware (amortisation), electricity (24×7, not
  just under load), cooling, space, network, **operations** (patching, on-call,
  observability) and above all **engineering time**, which is the largest item and the one that
  never gets budgeted.
- ❌ **"It's more private by definition".** Serving locally without authentication, without
  encryption in transit and without controlled prompt retention is *worse* than a provider with a
  data processor contract. Privacy is a property of the design, not of the location.
- ❌ **"It's more secure because it's inside".** See §5: several engines do not authenticate by default.
- ❌ **"It gives us the same result".** That is **measured** (`llm-evaluation-standards`), not
  assumed. An open model that does not solve the task is zero API cost and full infrastructure
  cost.

**Break-even calculation** — make it explicit and in writing before buying anything:

```
Coste_local_por_1M_tokens =
    ( amortización_hardware_hora        # price / (lifetime_h × utilisation_factor)
    + kWh_hora × precio_kWh × PUE       # GPU + host + cooling, not just the GPU's TDP
    + coste_operación_hora )            # % of a platform FTE / hours in the month
    ÷ tokens_por_hora_sostenidos        # measured under real load (§4), NOT a demo's peak

Coste_API_por_1M_tokens = precio_entrada × ratio_entrada + precio_salida × ratio_salida
```

Rules of the calculation, non-negotiable:

1. `tokens_por_hora_sostenidos` comes from the **§4 benchmark at the real concurrency**, not from
   a number in a tweet nor from an isolated request.
2. **The divisor is utilisation, not capacity.** If the load is office-hours (8×5, with
   peaks), divide by the *useful* hours: the hardware keeps consuming and amortising overnight.
3. Include **redundancy**: a single inference server is a SPOF. If the service
   matters, the calculation is with N+1, and that doubles the numerator.
4. API prices: **look them up on the web, never from memory** (for Anthropic, `claude-api`).
5. If the result is within ±30%, **the API wins**: the margin does not cover the operational
   risk nor the team's opportunity cost.

### 2.2 Engine choice

| Engine | Verified status (Aug 2026) | When it is the right choice |
|---|---|---|
| **vLLM** — `vllm serve` | **v0.26.0** (27 Jul 2026), very high release cadence | **Default for serving in production with concurrency.** PagedAttention (paged KV cache, no fragmentation) + *continuous batching* (fits new requests in on each iteration instead of waiting for the batch). It is the one that turns concurrency into throughput |
| **llama.cpp** — `llama-server` | Build **b10241** (3 Aug 2026), almost daily per-build releases | **Modest hardware, CPU, Apple Silicon (Metal), aggressive quantisation, edge.** GGUF, a single binary with no dependencies, partial GPU *offloading* with `-ngl`. Serves an OpenAI-compatible endpoint |
| **Ollama** — `ollama serve` | **v0.32.5** (27 Jul 2026), active | **Development and lab.** Excellent ergonomics (`ollama run`, model management, download). Wrapper over llama.cpp/its own engine. See limits below |
| **SGLang** | **v0.5.16** (25 Jul 2026), active | A serious alternative to vLLM when the load has **a lot of shared prefix** (RadixAttention) or heavy *grammar*/structured output. Evaluate with your own benchmark, not on faith |
| **TensorRT-LLM** | **v1.3.0rc23** (31 Jul 2026) — *release candidate* cadence | Only when squeezing the last 20-30% out of an NVIDIA GPU justifies the cost: engine compilation per model **and per hardware configuration**, and a rebuild on every change. **NVIDIA-only, no ROCm** |
| **TGI** (`text-generation-inference`) | ⚠️ **v3.3.7 from Dec 2025; last commit on `main`, Mar 2026.** No releases in ~8 months | ❌ **Do not choose for a new project.** Treat it as being in maintenance until proven otherwise. If it is already in production, plan an exit to vLLM or SGLang |
| **Triton Inference Server** | **2.71.0** (Jul 2026, NGC container 26.07) | When you have to serve **non-LLM models** (vision, audio, classical) alongside LLMs on a single serving surface, with heterogeneous backends |

**Ollama's limits when it is attempted in production** — declare them before
somebody discovers them during an incident:

- **Its concurrency model is not *continuous batching* comparable to vLLM's.**
  `OLLAMA_NUM_PARALLEL` raises parallelism but does not change the architecture: throughput and
  tail latency degrade much earlier than in vLLM. The published orders of magnitude
  (tens of tokens/s versus hundreds, p99 of hundreds of ms versus seconds) **verify them
  with your own benchmark**: they depend on the model, the GPU and the version.
- **It does not authenticate** (§5) and its API surface has accumulated CVEs for GGUF parsing and
  for updates (§5.3).
- **Different format**: Ollama works with GGUF; vLLM serves `safetensors` natively. The
  migration means **downloading the weights again**, not converting them. Account for it in the plan.
- **Criteria**: if there are more than ~5-10 real concurrent users, or there is an SLO, Ollama is the
  wrong tool. In `homelab-standards` and in development, it is the right one.

### 2.3 Quantisation

**What is actually lost.** Reducing bits per weight reduces memory and, since *decode* is
limited by memory bandwidth, **it increases generation speed**. What is lost is not
distributed uniformly: the degradation concentrates in chained reasoning,
code and mathematics, and is far smaller in summarisation and drafting. An almost identical
perplexity can hide a noticeable drop in the task you care about. **Rule: measure the task, not
perplexity** (`llm-evaluation-standards`).

| Format | Status | Use |
|---|---|---|
| **GGUF** (`Q4_K_M`, `Q5_K_M`, `Q6_K`, `Q8_0`) | Current, native format of llama.cpp/Ollama | CPU, Apple Silicon, modest GPU, mixed offloading. `Q4_K_M` is the recognised sweet spot (mixed quantisation: it is not uniform 4 bits) |
| **AWQ** (W4A16) | Current and very well supported | 4-bit weight / 16-bit activation in vLLM and SGLang. De facto standard for serving 4 bits on GPU |
| **GPTQ** | Current | Alternative to AWQ; on ROCm support has been more erratic than AWQ's — verify |
| **FP8** (W8A8) | Current, Hopper+ hardware and equivalents | Good quality/speed compromise when there is hardware that accelerates it. Also as **`--kv-cache-dtype fp8`**, which is where it pays off most (§2.4) |
| **NVFP4** | Current, **Blackwell (SM100)** | 4 bits with two-level scaling and a block of 16. Maximum throughput where the hardware supports it. Verify current limitations (e.g. LoRA adapters) |
| **MXFP4** | Current, multi-platform | 4-bit microscale, less tied to one vendor than NVFP4 |
| **INT8 / W8A8** | Current | The conservative path when 4 bits degrades the task |
| **bitsandbytes NF4** | Current but **for fast loading and experimentation**, not for serving with throughput | ❌ Not the choice for a production server |
| Quantisations **< 4 bits** (`Q2_K` and similar) | Technically current | ❌ **Banned in production.** There is a documented quality cliff below 4 bits, with degradation of a different order and, in small models, collapse |

**The rule of thumb "large quantised model > small model at full precision"** — it is
**true in the usual range and with concrete limits**, not an axiom:

- It holds **down to ~4 bits**. Beyond that it inverts: below 4 bits, the small model
  with more precision wins.
- The available controlled evidence is limited in domain and size (there are peer-reviewed
  studies on code generation with small models that confirm it in that range); the rest of the
  support is community consensus and perplexity on WikiText-2, which **is not your task**.
- **How to use it**: as a *starting hypothesis* to choose which two candidates to compare, never
  as a conclusion. The final decision comes out of your evaluation on your task.
- Beware of confusing levels: `Q4_0` and `Q4_K_M` are both "4 bits" and are not equivalent.
  Where GGUF with `imatrix` exists, it is preferable to the same bit width without it.

### 2.4 Memory sizing

```
VRAM_total ≈ pesos + caché_KV + activaciones + runtime fragmentation/overhead

pesos_bytes            = n_parámetros × bytes_por_parámetro
                         (FP16/BF16 = 2 · FP8/INT8 = 1 · 4 bits ≈ 0.5 + scales)

caché_KV_bytes         = 2 × n_capas × n_kv_heads × head_dim
                         × longitud_secuencia × n_secuencias_concurrentes
                         × bytes_por_elemento
```

Mandatory readings of the calculation:

1. **The `2` is K and V.** The `n_kv_heads` is the *key/value* one, **not the query one**: in models
   with GQA it is several times smaller, and that is the reason long context windows exist.
   Take it from the model's `config.json`, not from memory.
2. **The KV cache is what kills you.** It grows **linearly** in context length **and** linearly in
   concurrency. With short context it is noise; with long context and several simultaneous
   requests **it exceeds the model itself** and it is what triggers the OOM. A model that fits at
   start-up may not fit when serving.
3. **Operational corollary**: `--max-model-len` **is not left at the maximum the model advertises**.
   It is set to the context your case actually needs. Every window token you do not use is
   reserved VRAM that is not serving users.
4. `--gpu-memory-utilization` in vLLM controls the fraction of VRAM the engine reserves
   (**default value 0.90 — verify in the version you use**). Raising it increases the KV
   cache and therefore concurrency; raising it too far makes the allocation fail.
5. **`--kv-cache-dtype fp8`** is the highest-return lever with long context: it halves the
   cache. Verify its impact on quality with your evaluation before pinning it.
6. **Leave margin.** Reserving 100% of VRAM leaves no room for activations or for peaks.
7. In llama.cpp, `-ngl` decides how many layers go to the GPU. **Partial offloading degrades
   catastrophically**: if half the model lives in host RAM, PCIe bandwidth becomes
   the bottleneck. Quantise harder rather than half-offloading.

### 2.5 API compatibility

- **The de facto standard is the OpenAI API.** vLLM, llama.cpp (`llama-server`), Ollama,
  SGLang, TGI and TensorRT-LLM expose `/v1/chat/completions`, `/v1/completions` and, depending on the
  engine, `/v1/embeddings`. **That is what makes the backend interchangeable.**
- **Design rule**: the application speaks the OpenAI contract and the `base_url` is
  configuration. It is never coupled to an engine-exclusive SDK. That way the same client works for
  the local model, for another engine and for a managed provider — which is the only cheap way
  to have a plan B.
- **Compatibility is not total.** *Tool calling*, structured output / *grammar*, `logprobs`
  and sampling options diverge across engines and versions. **It is verified with a contract
  test** (§4), not assumed.

## 3. Structure and conventions

- **One engine, one model, one process, one port.** Multiplexing models in one process complicates
  KV cache sizing and turns any OOM into a shared incident. If you have
  to route between several models, you put a *router* in front (or a gateway), not inside.
- **Everything declarative**: engine flags live in a systemd/Quadlet unit, a manifest
  or a versioned IaC module (`iac-standards`, `podman-systemd-containers-standards`,
  `kubernetes-standards`). ❌ A `vllm serve` launched by hand in a `tmux` is not a deployment.
- **Weights outside the container image.** Mounted volume or storage
  (`linux-storage-standards`, `zfs-standards`, `object-storage-standards`): they are tens or
  hundreds of GB, and putting them in the image destroys the layer cache and the registry.
- **Model referenced by immutable revision**, not by name nor by `main`. The name can
  point at different bytes tomorrow; the revision hash cannot.
- **Naming**: the service name includes model and quantisation (`vllm-qwen3-32b-awq`), not
  just "llm": in six months there will be three and nobody will know which is which.
- Separate the **service network** (the endpoint) from the **coordination network** (NCCL/`torch.distributed`,
  KV cache transfer): they are planes with different trust (§5.2).

## 4. Quality and gates

**How to measure properly** — an isolated request measures nothing:

| Metric | What it is | Trap |
|---|---|---|
| **TTFT** (time to first token) | Latency to the first token. It dominates perception in conversational interfaces | It is **prefill** cost: it grows with the prompt and with the queue |
| **TPOT / ITL** | Time between tokens during *decode* | Determines the perceived "reading" speed |
| **Output throughput** | Aggregate tokens/s from the server | **It is the cost metric**, not the experience one |
| **Prefill tokens/s** | Prompt processing; **parallel, compute-bound** | Scales well with large batches |
| **Decode tokens/s** | Generation; **sequential, memory-bandwidth-bound** | That is why quantising accelerates decode and barely touches prefill |

- **Prefill and decode are different regimes.** A system with long prompts and short
  responses (RAG, classification) is prefill-bound; one with long generation, decode-bound.
  **Sizing with the wrong mix is the most expensive capacity error.**
- **Batching improves throughput and worsens individual TTFT and TPOT.** There is no
  configuration that optimises both: you choose, with a written SLO (`sre-practice-standards`).
- **Measurement gate**: benchmark with **sustained load** (several minutes), **stepped
  concurrency** (1, 2, 4, 8, 16, 32…) and **a length distribution representative of
  production**. Report **percentiles (p50/p95/p99), not means**, and the
  throughput-vs-latency curve. The operating point is where p95 still meets the SLO.
- Tools: `vllm bench serve` itself / the engine's benchmark scripts, or a
  load generator with real traces. **Verify the exact subcommand name in the
  installed version** (§8).

**CI gates that break the build** (in increasing order of cost):

1. **Valid declarative configuration**: unit/manifest linted; no loose flag outside
   the versioned artefact.
2. **Weight provenance verified**: immutable revision pinned + file hash
   checked against the source repository's manifest (§5.1). Without this it is not deployed.
3. **API contract test**: the endpoint answers the OpenAI subset the application
   uses (chat, streaming, and —if used— *tool calling* and structured output), with the same
   assertions against the current engine and against the upgrade candidate.
4. **Start-up and sizing test**: the service starts with the production `--max-model-len` and
   **survives a KV cache saturation test** (target concurrency ×
   maximum context) without OOM. This is the failure that most often reaches production.
5. **Authentication gate**: a request **without a credential** to **any** inference
   route must return 401/403. The routes outside `/v1` are tested explicitly (§5.2).
6. **Performance regression benchmark**: throughput and p95 within a threshold relative to
   the baseline; a drop of X% breaks the build. The engine version changes performance.
7. **Quality evaluation** of the task when changing model, quantisation or engine version
   (`llm-evaluation-standards`). **Changing the quantisation is changing the model.**

## 5. Stack security

### 5.1 Weight provenance

**A `.gguf` or a `.safetensors` from a stranger is a binary from a stranger.** The
format matters, but it does not close the problem:

| Format | Execution risk on load |
|---|---|
| **Pickle** (`.bin`, `.pt`, `.ckpt`, `torch.load` without `weights_only`) | ❌ **Arbitrary execution by design**: deserialisation executes code. **FORBIDDEN** to load pickle weights from an uncontrolled source. Repository scanning is signature-based and **has been shown to be evadable** with non-standard containers |
| **safetensors** | ✅ **The safe format recommended today.** JSON header + raw bytes: it does not serialise Python objects, it does not execute code. **It does not protect** against tampered weights (a backdoor in the values themselves) nor against `trust_remote_code` |
| **GGUF** | ⚠️ Not pickle, but its **binary parser is a recurring source of RCE**. Verified in NVD: **CVE-2025-49847** (CVSS 8.8, overflow in vocabulary loading, fixed in b5662), **CVE-2026-27940** (7.8, integer overflow in `gguf_init_from_file_impl()`, fixed in b8146, *bypass* of the CVE-2025-53630 fix), **CVE-2026-33298** (7.8, integer overflow in `ggml_nbytes`, fixed in b7824). In addition, **malicious chat templates embedded in the GGUF metadata** (template injection) and **CVE-2026-7482 / CVE-2026-65315** in Ollama's GGUF loader |

Hard rules:

- **`trust_remote_code=True` is FORBIDDEN** except by documented and reviewed exception: it is
  execution of arbitrary Python code written by the model's author. There are verified CVEs for engines
  that enabled it **unconditionally** (`CVE-2026-4944`, 8.8, hardcoded in vLLM;
  `CVE-2026-5817`, 8.8, `vllm-metal` backend in Docker Model Runner).
- **Pin by immutable revision** and verify the hash. Referencing a model only by
  name allows different bytes to be served to you tomorrow. There is a CVE for *pinning* controls
  applied inconsistently (`CVE-2026-47155`, 6.5, vLLM < 0.22.0) — verify that your
  version really applies it, not that it has it documented.
- **A model is loaded in a confined process**: unprivileged user, without write
  access to anything other than its working directory, reduced capabilities, read-only root
  filesystem, no outbound Internet access beyond what is needed for the download
  (`container-runtime-security-standards`, `linux-hardening-standards`,
  `firewall-policy-standards`). **The first download and the first `load` are the attack
  window.**
- **The download is a step separate from start-up**: it is downloaded, verified, scanned and
  published in an internal store. The production server **does not download from the Internet at
  start-up** (besides security, it is availability: a failure of the external repository takes
  down your service's start-up).
- Scanning and signing of the model artefact is a shared boundary with `mlsecops-standards`:
  **the supply chain criteria are theirs**; here the operational rule of what this server
  accepts wins.

### 5.2 The endpoint

**Several engines authenticate nothing by default.** Exposing an inference endpoint without
authentication is giving away compute (and, with *tool calling*, a foothold inside your network).

- **vLLM**: the official documentation is explicit — `--api-key` *"provides authentication for
  vLLM's HTTP server, but **only for OpenAI-compatible API endpoints under the `/v1` path
  prefix**, and other similar `/v2`, `/inference` path prefix"*, and *"Many other sensitive
  endpoints are exposed on the same HTTP server without any authentication enforcement"*,
  citing `/invocations` (*"particularly concerning as it provides unauthenticated access to
  the same inference capabilities"*), `/pooling`, `/classify`, `/generative_scoring` and
  control endpoints such as `/pause` and `/abort_requests`. The doc itself warns: **"Do not rely
  exclusively on `--api-key` for securing access to vLLM."**
  → **Criteria: `--api-key` is NOT the access control.** The control is a **reverse proxy
  in front that explicitly *allowlists* the exposed routes and blocks all the others**,
  with authn, rate limiting and logging — which is exactly what the official doc recommends.
- **Ollama**: **it has no authentication**. It listens on `127.0.0.1:11434` by default, and the
  problem starts when somebody sets `OLLAMA_HOST=0.0.0.0` to share it. Something on the order of
  **hundreds of thousands of instances exposed on the Internet** and active compute-hijacking
  campaigns have been reported — **verify the figure and the campaign on the web before citing
  concrete numbers** (§8). ❌ `OLLAMA_HOST=0.0.0.0` without a firewall and without a proxy in front.
- **llama-server**: verify in the installed version what it offers (`--api-key` and equivalents)
  and **assume by default that it is not enough**: same pattern, proxy in front.
- **The distributed plane is insecure by design.** vLLM: *"All communications between nodes in
  a multi-node vLLM deployment are **insecure by default** and must be protected by placing the
  nodes on an isolated network"*, and *"From a PyTorch perspective, any use of `torch.distributed`
  should be considered insecure by default."* → **Isolated network, mandatory.** No NCCL or
  KV cache transfer on the same network as everything else.
- **Never `--host 0.0.0.0` without control in front.** Bind to loopback or to the internal interface;
  expose only through the proxy.
- **Debug endpoints forbidden in production** (`VLLM_SERVER_DEV_MODE=1`,
  `--enable-tokenizer-info-endpoint` and equivalents): they leak chat templates and
  tokenizer configuration.
- **Real authentication**: per-consumer token issued by the IdP and verified at the proxy
  (`identity-access-management-standards`), managed secret
  (`secrets-management-standards`), end-to-end TLS (`cryptography-pki-standards`).
  A token shared by the whole company is not authentication: it is a password.
- **Rate limiting and per-consumer quotas** are availability control, not courtesy: without
  them, one client in a loop saturates the only GPU and takes down everyone else. There are verified
  DoS CVEs from unbounded consumption (`CVE-2026-5497`, 7.5, OOM in vLLM ≥ 0.8.0).
- **Prompts and responses are data.** Structured logging **without content** by default; if you
  have to retain, legal basis, minimisation and retention are decided in
  `privacy-engineering-standards`. Serving locally does not erase the GDPR, it only changes who is
  responsible for everything.
- **The model's output is untrusted input** for whatever comes next: that is governed by
  `llm-app-engineering-standards`, and this skill does not duplicate it. But the endpoint operator
  must know that **with *tool calling* enabled, an open endpoint is mediated remote
  execution**.

### 5.3 Dependencies and CVEs

- Inference engines are **young software, in C++/CUDA and Python, parsing untrusted
  files**: high vulnerability surface and fast patch cadence. Treat them with
  the SLA of an exposed component (`vulnerability-management-standards`).
- Verified in NVD (2026): vLLM accumulates CVEs for token injection (`CVE-2026-44222`),
  missing validation of sparse tensors (`CVE-2026-56340`, 8.7), ReDoS (`CVE-2025-71379`) and
  security checks based on `assert` (`CVE-2026-41523`, 7.5 — remember that
  `python -O` strips out `assert`s). Ollama, CVEs for out-of-range reads in the GGUF loader
  and for updates without integrity verification on Windows.
- **Pin the engine version by digest** and update on a cadence, not by reflex. Every
  version of vLLM/SGLang changes performance and sometimes behaviour: gate 6 in §4 exists
  for that.

## 6. Performance and operability

- **Engine metrics to Prometheus** (`observability-standards`): vLLM exposes `/metrics` with,
  among others, running and waiting requests, KV cache usage, *prefix cache* hit
  rate, TTFT and TPOT, and prompt and generation token counters. **Verify
  the exact metric names in the installed version** (§8: they have changed between versions).
- **The four signals that matter**:
  1. **KV cache usage** — it is your real saturation indicator. Close to 100% means the
     engine is about to queue or to reject.
  2. **Waiting request queue** — if it grows monotonically, you do not have a latency
     problem, you have a capacity problem.
  3. **TTFT p95 and TPOT p95** — against the written SLO.
  4. ***Prefix cache* hit rate** — a stable system prompt placed at the
     beginning turns prefill into something cacheable, and that is free throughput.
- **GPU metrics** (real utilisation, memory, temperature, throttling, ECC) and how to read them:
  `gpu-computing-standards`.
- **Power consumption as a first-class metric**: kWh and **cost per million tokens**
  served. It is half of the §2.1 calculation and what turns a discussion of opinion into one
  of numbers. Setting a power limit per GPU is often a small loss of
  performance for a large gain in efficiency — it is measured, not assumed
  (`gpu-computing-standards`).
- **Cold start**: loading tens of GB from disk and compiling/*warming up* kernels takes
  minutes. It affects the *readiness probe*, the deployment and the recovery plan. **Measure it and
  document it**; do not discover during an incident that your RTO was optimistic.
- **Multi-GPU and multi-node, only when needed**:
  - **Tensor parallelism** (`--tensor-parallel-size`): splits each layer across GPUs. It lowers
    latency and allows models that do not fit on one GPU, but it demands **fast interconnect
    between GPUs in the same node** (NVLink or equivalent). Over PCIe the communication eats
    the gain.
  - **Pipeline parallelism** (`--pipeline-parallel-size`): splits by layers across nodes.
    It tolerates slower links, but it introduces bubbles and **does not lower latency**.
  - **Rule**: tensor within the node, pipeline between nodes, and **only if the model does not fit** or
    the latency SLO demands it. Multi-node multiplies the failure modes; it is almost always
    better to use a smaller or more quantised model than a distributed deployment.
  - **Replicate before parallelising**: if the model fits on one GPU, N independent
    replicas behind a load balancer give more throughput and better failure isolation
    than one instance with TP=N.
- **Weight backups**: normally **public weights are not backed up** — they are re-downloaded
  from the internal store, which is backed up along with its hash manifest. **What is backed
  up**: your own fine-tuned models, artefacts no longer publicly available
  and the provenance manifest. Criteria and RTO/RPO in `backup-recovery-standards` and
  `bcdr-standards`; the input datum is "how long does it take to re-download 200 GB", which has to
  be measured.
- **Capacity**: the GPU is not oversubscribed like the CPU. When the KV cache fills up, there is no
  graceful degradation: there is a queue or there is an error. Plan with margin and with an explicit
  rejection policy (429) rather than letting the queue grow without end.

## 7. Sustainability and prohibitions

- **Cadence**: review engine version and CVEs **monthly** (an ecosystem with weekly
  releases); review the local-vs-API decision **every 6-12 months** — API prices go down
  and open model capability goes up, and a 2024 decision may be burned money today.
  Re-verify this whole skill every 3 months (§7 of `claude-code-skills-standards`).
- **Model licences: it is a legal decision, not a technical one.**
  - **"Open" is not "open source".** The OSI published the *Open Source AI Definition* v1.0, which
    requires **Data Information** (*"Sufficiently detailed information about the data used to
    train the system so that a skilled person can build a substantially equivalent system"*),
    **Code** (*"The complete source code used to train and run the system"*) and **Parameters**
    (*"The model parameters, such as weights or other configuration settings"*). **Most
    of the models called "open" do not comply**: they are *open weight*, with a proprietary
    training process.
  - Licences range from genuinely permissive (Apache-2.0, MIT) to community licences
    with **usage restrictions, user or revenue thresholds, prohibited use policies,
    naming obligations for derivatives and clauses about using the outputs to train
    other models**. Several families are **heterogeneous within themselves**: the same
    "model" can have a different licence by size or by generation.
  - **FORBIDDEN to fix in a document or in a deployment the licence of a specific model without
    reading its *model card* and its licence file at that moment.** It is where it is easiest to
    invent a datum, and the error is legal.
  - ***Distills* and *fine-tunes* inherit the base model's licence.** Check it.
  - Record the model, revision, licence and its evaluation in the inventory
    (`grc-compliance-standards`; `ai-governance-standards`).

**FORBIDDEN**

- ❌ Justifying local inference with "it's free" or "it's more private" without the §2.1 calculation
  and without the §5 controls.
- ❌ An inference endpoint accessible without authentication, or "protected" only with
  `--api-key` without a route *allowlist* in a proxy in front.
- ❌ `--host 0.0.0.0` / `OLLAMA_HOST=0.0.0.0` without a firewall and without a proxy.
- ❌ NCCL / `torch.distributed` / KV cache transfer traffic outside an isolated network.
- ❌ Loading pickle-format weights from an uncontrolled source. `trust_remote_code=True` without a
  documented and reviewed exception.
- ❌ Referencing a model by name or by branch instead of by immutable revision + hash.
- ❌ Downloading weights from the Internet at production service start-up.
- ❌ Ollama as a production server with concurrency or with an SLO.
- ❌ TGI in a new project (no release since Dec 2025; verify before condemning it).
- ❌ Quantisation below 4 bits in production.
- ❌ Changing model, quantisation or engine version without re-evaluating task quality.
- ❌ `--max-model-len` at the model's maximum "just in case": it is burned VRAM and a deferred OOM.
- ❌ Partial CPU offloading as a production strategy (quantise harder, or buy memory).
- ❌ Sizing or budgeting with the result of **one** request instead of with sustained
  load and percentiles.
- ❌ Coupling the application to an engine-specific SDK instead of to the OpenAI contract.
- ❌ Logging prompts and responses by default.
- ❌ Multi-node before exhausting "smaller model", "more quantised" and "N replicas".
- ❌ Asserting a model's licence, its size, its context window or its memory performance
  — or an API's price — without verifying it at that moment.

## 8. Mandatory web verification

Before pinning any version, number or name:

1. **Version and vitality of each engine**: `api.github.com/repos/<org>/<repo>/releases/latest` or
   the `releases.atom` feed (**not the HTML of the releases page: the summariser invents the
   year**). Checked that way in Aug 2026: vLLM **0.26.0** (27 Jul 2026), llama.cpp build
   **b10241** (3 Aug 2026), Ollama **0.32.5** (27 Jul 2026), SGLang **0.5.16** (25 Jul 2026),
   TensorRT-LLM **1.3.0rc23** (31 Jul 2026), Triton Server **2.71.0** (Jul 2026), TGI
   **3.3.7 from Dec 2025** with the last commit on `main` from Mar 2026.
2. **TGI status**: confirm whether it has resumed publishing releases before recommending it or
   pronouncing it dead.
3. **Flags and default values** of the installed engine: `--gpu-memory-utilization`,
   `--max-model-len`, `--kv-cache-dtype`, `--api-key`, the benchmark subcommand and the
   **exact names of the `/metrics` metrics**. They change between minor versions.
4. **Current quantisation formats** and their hardware support matrix in the engine's
   documentation (NVFP4/MXFP4 and their limitations evolve fast).
5. **Weight format security**: new GGUF parsing CVEs in the security advisories of
   `ggml-org/llama.cpp` and in NVD; scanning status of the source repository; recent
   incidents of malicious models.
6. **Engine CVEs** in NVD (`services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=…`)
   and in the repo's GHSA advisories. Those cited in §5 were verified against NVD in Aug 2026.
7. **The specific model's licence**: *model card* + licence file, at the moment of
   deciding. And the status of the OSI's *Open Source AI Definition*.
8. **Prices of the APIs** being compared against. For Anthropic, the `claude-api` skill is the
   canonical reference: **no Claude model id, price or limit is asserted from memory**.
9. **Model sizing data** (`n_capas`, `n_kv_heads`, `head_dim`, window): from the
   model's `config.json`, never from memory.

**Declared gaps (not verified in this pass, do not fill in from memory)**

- **Comparative performance figures for Ollama vs. vLLM** (tokens/s, p99, concurrent users
  before OOM): cited on the web with orders of magnitude consistent across sources, but **not
  independently verified**. Measure on your own hardware before using them.
- **Number of Ollama instances exposed on the Internet** and the associated hijacking campaign:
  reported by several sources with divergent figures (wide range). **Verify before citing
  a specific figure.**
- **SGLang's performance and support versus vLLM** on specific loads: not benchmarked here.
- **Exact names of vLLM 0.26's Prometheus metrics**: not verified one by one.
- **Exact state of authentication in `llama-server`** in the current build: not verified.
- **Names, sizes, context windows and licences of specific open models**:
  **deliberately omitted**. It is the datum that expires fastest and where it is easiest to
  invent. It is verified in the *model card* at the moment of deciding.
- **Measured impact of `--kv-cache-dtype fp8` on quality**: depends on the model and the task; there
  is no general number.

If the web contradicts this document, **the web wins** — flag the discrepancy.
