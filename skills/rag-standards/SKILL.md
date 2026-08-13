---
name: rag-standards
description: Retrieval-augmented generation treated as a retrieval problem. Use when deciding RAG versus long context versus fine-tuning, parsing and chunking documents for indexing (PDF tables, multi-column, scans, overlap, structure-aware splits), picking an embedding model and dimensionality and paying the reindex cost of changing it, running pgvector versus Qdrant/Weaviate/Milvus/Chroma/LanceDB, tuning HNSW or IVFFlat parameters (m, ef_construction, ef_search, lists, probes), hybrid dense-plus-BM25 retrieval with RRF fusion, cross-encoder reranking, metadata filters, multi-query or HyDE expansion, grounding answers with citations and refusing when the context does not support them, measuring recall@k / MRR / nDCG separately from faithfulness, per-document access control on retrieved chunks, incremental index updates and deleting embeddings on erasure requests, or judging whether GraphRAG and agentic RAG earn their cost.
---

# RAG standards (retrieval-augmented generation)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to designing, building, operating or auditing a **retrieval-augmented** system: the decision
of whether RAG is the right architecture, ingestion and parsing per document type, chunking,
embeddings and their lifecycle, the vector store and its indexes, hybrid retrieval and
reranking, the generation prompt grounded in the context, the separate evaluation of retrieval and
generation, and the operation of the index (incremental update, deletion, access control, cost
and latency of the whole chain).

Triggers: "chunking", "chunk", "overlap", "splitter", "embedding", "reindex",
"dimensionality", "normalise vectors", "similarity search", "cosine", `pgvector`,
`vector(1536)`, `halfvec`, `HNSW`, `IVFFlat`, `m`, `ef_construction`, `ef_search`, `lists`,
`probes`, Qdrant, Weaviate, Milvus, Chroma, LanceDB, "hybrid search", `BM25`, `tsvector`, `RRF`,
"reranker", "cross-encoder", "metadata filtering", "multi-query", "HyDE", "cite sources",
"it hallucinates with the context right there", `recall@k`, `MRR`, `nDCG`, "faithfulness to the context", "GraphRAG",
"agentic RAG", "delete from the index", "a user sees a chunk they should not".

**Thesis of the domain — it applies throughout this document**: **RAG is a retrieval problem, not a
generation one.** The vast majority of failures ("the model hallucinates", "it answers badly") are retrieval
failures: the right fragment never reached the context. **Operational corollary: measure
retrieval separately before touching the prompt, the model or the temperature.** A team that
debugs a RAG failure by changing the generation prompt, without having measured `recall@k`, is
guessing.

**Not applicable**:

- `llm-app-engineering-standards`: the **whole application** on top of an LLM — model choice,
  prompting as code, structured output, context window budget, prefix caching,
  streaming, reliability, spend limits, prompt injection, testing the non-deterministic. **The
  app may not use RAG; RAG is used from the app.** Here only the **grounded generation** prompt
  (§3.7) — citation and refusal —, not prompting in general.
- **`claude-api`** (no `-standards` suffix, **an installed skill, the canonical reference on the
  Anthropic side**): everything **Anthropic-specific** is theirs — model IDs, prices, context
  windows, parameters, prompt caching, tool use, MCP, Managed Agents, migration. If you need a
  fact about the Claude API for the generator or for long context, **it comes from there**, not from here nor
  from memory. This skill is provider-agnostic.
- `llm-evaluation-standards`: **evaluation is theirs** — building
  eval sets, LLM-as-judge and its calibration, statistical significance, regression in CI. Here what
  **is measured in RAG and why separately** is defined (§4), and it is demanded as a gate; the evaluation
  machinery lives there.
- `ai-agents-standards`: the autonomous agent loop. **Agentic RAG** (§3.10) is
  covered here only as a **retrieval pattern and its cost**; the autonomous loop, its tools and
  its memory are theirs.
- `data-platform-standards`: **the PostgreSQL engine** — modelling, migrations, general tuning,
  replicas, PITR, backups, partitioning. **An explicit boundary with `pgvector`: the vector index and
  its parameterisation (`HNSW`/`IVFFlat`, `m`, `ef_*`, `lists`, `probes`, `halfvec`) belong to this
  skill; the engine hosting it, its operation and its backup are theirs.** Redis/Valkey and Kafka in
  ingestion are theirs too.
- `multimodal-genai-standards`: **parsing the non-textual document** — turning a PDF, a
  scan or an image into usable text (classic OCR versus VLM, spatial grounding, cost per
  page) is theirs. **Here, what gets indexed from that text, how it is chunked and how it is retrieved.**
  A reciprocal boundary, already declared in their §1.
- `object-storage-standards`: storage of the original documents (S3/MinIO/Ceph),
  lifecycle, versioning and egress cost.
- `privacy-engineering-standards`: personal data, minimisation, DPIA, consent. **The right
  to erasure applies to the index and to the embeddings too** (§6): here the mechanics of deletion in
  the vector store, there the right and its scope.
- `appsec-standards`: classic vulnerability classes and triage. Document-level access control
  in retrieval (§5) belongs **to this skill**, but its underlying authorisation model
  belongs to `identity-access-management-standards`.
- `mcp-standards`: exposing retrieval as an MCP server and its security.
- `mlsecops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlops-standards`,
  `ai-governance-standards`: model lifecycle security,
  serving your own embeddings/rerankers (vLLM, TEI, llama.cpp), hardware, and AI Act governance.
- `observability-standards`: OTel, backends and cardinality. The **RAG chain's metrics**
  (recall, latency per stage, cost per query) belong to this skill; the transport and the backend,
  to theirs.
- `api-design-standards`: the contract of your search API to the outside.
- `python-standards` / `typescript-standards`: implementation; `cicd-standards`: the gates in §4;
  `kubernetes-standards`, `iac-standards`, `secrets-management-standards`,
  `backup-recovery-standards`, `sre-practice-standards`, `grc-compliance-standards`: their domains.

## 2. Default decisions

> Verify the latest version, licence and status on the web before pinning anything (§8). This sector has
> **frequent licence changes** and acquisitions; what is verified here is from August 2026.

### 2.1 RAG, long context or fine-tuning?

The question is answered **before** building anything. In 2026 1M-token windows are commonplace,
so "the corpus does not fit" is no longer automatic.

| Situation | Architecture | Reason |
|---|---|---|
| The corpus fits comfortably in the window and query volume is low | **Direct long context** | RAG here is **free complexity**: an ingestion pipeline, an index, and a new failure mode, for nothing |
| A corpus orders of magnitude larger than any window | **RAG** | It is the only architecture that works |
| High query volume over the same large corpus | **RAG** | Input cost scales linearly: paying to read the whole archive on every request is unsustainable |
| Traceability of which document grounded the answer is required | **RAG** | Citation is an audit requirement, not a feature |
| The corpus changes constantly | **RAG** | The index gets updated; retraining does not |
| Latency-critical over a large corpus | **RAG** | Sending 1M tokens is slower than retrieving 5 fragments |
| Holistic reasoning over a bounded set (comparing two contracts, reviewing a repository, synthesising N articles) | **Long context** | The evidence is distributed; chunking destroys it |
| You need **form**: tone, format, your own taxonomy, behaviour | **Fine-tuning** (or prompting) | Fine-tuning teaches **form, not facts**. Using it to inject knowledge is expensive, goes stale and hallucinates |
| There is an API with the answer (price, stock, balance, status) | **An API call** | Vectorising structured data with an exact answer is a design error |
| Mixed (the usual case in production) | **Hybrid**: retrieve and reason in long context over what was retrieved | Route by the shape of the query |

**Two facts that underpin the criteria and must be re-verified (§8)**: quality degrades with input
length well before the announced limit (*context rot*), and information in the middle of the
context is used less well than that at the extremes (*lost in the middle*). A large window is
capacity, not a guarantee.

**Honest decision rule**: if in doubt, start **without** RAG. Add it when you measure that it is needed.

### 2.2 Toolchain

| Area | Default | Reason / alternative |
|---|---|---|
| Vector store | **`pgvector` on the PostgreSQL you already have** (0.8.x; 0.8.6 Jul 2026, PostgreSQL licence) | **The real criterion: if you already operate PostgreSQL and the volume is moderate (up to ~tens of millions of vectors), pgvector saves you a whole operational component** — backup, HA, monitoring, authentication and transactionality already solved, and metadata filtering is simply SQL |
| Dedicated engine | **Qdrant** (Rust, Apache-2.0, 1.18.x Jul 2026) as the default when pgvector is not enough | Very good payload filtering, simple operation, clean licence |
| Alternatives | **Milvus** (Apache-2.0; **3.0.0 in Jul 2026**, in addition to the 2.6.x line) scales massively at the cost of high operational complexity; **Weaviate** (core BSD-3, 1.38.x/1.39-rc) integrated modules; **Chroma** (Apache-2.0) prototyping, **not** serious production; **LanceDB** (Apache-2.0) columnar format over object storage, a good analytical fit | A recent major change in Milvus: do not adopt 3.x without reading the migration guide |
| Lexical search | **Whatever your store already has**: `tsvector`/`ParadeDB` in PostgreSQL, sparse vectors in Qdrant, native BM25 where it exists | Adding OpenSearch/Elasticsearch **just** for BM25 is an expensive component |
| ANN index | **HNSW** by default | The best speed/recall compromise; it can be created on an empty table (no training phase) |
| IVFFlat | Only if memory is the dominant constraint and you accept worse recall | It requires representative data already loaded before indexing |
| Distance metric | **The one the embedding model declares** (almost always cosine / inner product over normalised vectors) | Using a metric different from the training one degrades silently |
| Reranker | **A cross-encoder**, `BGE reranker v2-m3` or `mxbai-rerank` (**both Apache-2.0**) self-hosted; a managed API (Cohere, Voyage) if you do not want to serve a model | ⚠️ **The Jina Reranker weights are CC-BY-NC**: not deployable in a commercial product; commercial use goes through the API. **Verify the licence of each reranker before deploying it** |
| Embedding model | **A decision made by your own evaluation** (§2.4). Current families as of Aug 2026: Qwen3-Embedding and BGE-M3 (open), and those of OpenAI/Google/Voyage/Cohere (API) | ⚠️ **Exact names and versions are NOT pinned here** — they change monthly and the public sources contradict each other. Verify (§8) |
| RAG evaluation | **RAGAS** (Apache-2.0) as a starting point, with your own set | ⚠️ Slow cadence: latest release **0.4.3 (Jan 2026)**, ~7 months without publishing as of Aug 2026. **Verify its status before depending on it**; detail in `llm-evaluation-standards` |
| Ingestion framework | **LlamaIndex** (0.14.x) if you want the connectors ready-made; your own code if the corpus has few types | A 300-line home-made ingestion pipeline is usually more maintainable than a framework for 3 formats |

### 2.3 Index parameters (the accuracy / memory / speed trade-off)

ANN indexes are **approximate**: they trade recall for speed. Setting their parameters blind is
the most common cause of "the system retrieves badly" without anyone noticing.

| Parameter | Effect | Criterion |
|---|---|---|
| `m` (HNSW) | Connections per node. ↑ = better recall, more memory, slower construction | Start at the default; raise it only if the measured recall falls short |
| `ef_construction` (HNSW) | Effort at build time. ↑ = a better graph, much slower construction | It is paid once; being generous here usually pays off |
| `ef_search` (HNSW) | Candidates at query time. ↑ = better recall, more latency | **The only parameter tunable at runtime. It is your recall↔latency dial in production** |
| `lists` (IVFFlat) | Number of partitions | It depends on the corpus size; reindexing is mandatory if the corpus grows a lot |
| `probes` (IVFFlat) | Partitions visited at query time | A recall↔latency dial equivalent to `ef_search` |
| Quantisation (`halfvec`, scalar, binary) | Drastically reduces memory, costs recall | **Measure recall before and after.** Never enable it "for efficiency" without measuring |

**Hard rule**: **the index's recall is measured against exact (brute force) search over a
sample**, not assumed. A badly parameterised index does not raise an error: it gives worse answers, silently.

**Interaction with filtering**: a restrictive filter combined with an ANN index can return
fewer results than requested, or degrade into a scan. Verify your engine's behaviour
(pgvector 0.8+ has *iterative scans* precisely for this) and **measure recall with the filter
applied**, not just without it.

### 2.4 Embeddings: the one-way decision

| Decision | Criterion |
|---|---|
| Model choice | **By evaluation over your corpus**, with your real queries |
| MTEB | **A signal, not a truth.** It is contaminated: many models train on data overlapping with its datasets, so the ranking does not predict quality on a private corpus. Besides, MTEB v2 is not comparable with v1. **Use it to shortlist 3-4 candidates, not to decide** |
| Multilingual | **Mandatory if the corpus or the queries are.** A model trained in English over a Spanish corpus retrieves badly, and raises no error |
| Specialised domain (legal, medical, code) | Generic models degrade. Evaluate domain models or fine-tuning the embedder — it is one of the few fine-tunings with a clear return |
| Dimensionality | **More dimensions is not better by default.** They cost index memory, latency and storage, linearly. If the model supports Matryoshka-style reduction, evaluate the reduced version: often the cost drops a lot and recall barely at all |
| Normalisation | Normalise if the metric requires it, **and do it the same way at indexing and at query time**. A mismatch here wrecks the search with no visible error |
| Symmetry | Many models require **a different prefix/instruction for the query and for the document**. Forgetting it is a very common silent bug |

**The cost of reindexing is the domain's one-way decision.** Changing embedding model
means **recomputing every vector in the corpus**: inference cost proportional to the whole
corpus, a reindexing window, and double storage if you want to do it without downtime. In practice
this means:

1. **Choose well the first time**, with a real evaluation.
2. **Store each chunk's original text** alongside the vector. Without the text you cannot reindex without
   reprocessing the source documents.
3. **Version the index** (`chunks_v3`) and include the model and version in each vector's metadata.
   Mixing vectors from two models in the same index produces nonsensical results with no error.
4. **Design the migration path from day one**: double writes to a new index, recall comparison,
   cutover behind a feature flag, and rollback.

## 3. Structure and conventions of the chain

### 3.1 Ingestion and parsing

**Garbage in is garbage out.** No chunking, embedding or reranker retrieves from text
that was extracted badly. Parsing is the stage with the **highest return per unit of effort** in the whole chain and the
one most underestimated.

- **PDF is the hard problem**, and its difficulty is tiered: a PDF with a clean text layer →
  trivial; **multi-column** → the reading order breaks and the text comes out interleaved;
  **tables** → they get flattened and lose the row/column relationship, which is usually exactly the data;
  **scanned** → it requires OCR and its error rate propagates into everything else.
- **Verify the extracted text over a representative sample before indexing anything.** It is the step
  most teams skip. A corpus of 100k documents with a broken reading order is money
  burned on embeddings.
- **Tables get handled separately**: extracting them into a structured representation (Markdown, CSV,
  a textual description) preserves the semantics that plain text destroys.
- **Cleaning**: repeated headers/footers, page numbering, watermarks, navigation and
  *boilerplate* are noise competing in the similarity. Remove them.
- **Metadata from the source**: source, title, section, date, version, language, author, and **everything
  needed for access control (§5)**. Metadata you do not capture at ingestion will never
  exist in the index.
- **Deduplication** before indexing: the same document in three versions fills the top-k with
  duplicates and displaces useful evidence.
- An **idempotent and re-runnable** pipeline, with a stable identifier per document and per chunk.

### 3.2 Chunking

The chunk is the **unit of retrieval *and* the unit of context** at the same time. The optimal size
depends on both: if it is too large, the similarity gets diluted and you retrieve noise; if it is
too small, you retrieve a fragment that on its own answers nothing.

| Strategy | When |
|---|---|
| **By document structure** (section, heading, article, cell, function) | **The default when the document has structure.** It respects real semantic boundaries and produces natural citation |
| By fixed size with overlap | When there is no usable structure. Simple, predictable, cheap |
| Semantic (cut where the topic changes) | When the text is continuous and unmarked. More expensive; **measure whether it helps before adopting it** |
| Per element for tables/code | Never split a table or a function in half just to hit a character limit |

Rules:

- **Overlap exists so an answer is not split in two.** A moderate overlap is healthy; a large
  overlap inflates the index and fills the top-k with near-duplicates.
- **Measure the size in the embedding model's tokens**, not in characters, and respect its maximum
  length: whatever exceeds it gets truncated **silently** and you lose the end of every chunk.
- **Enrich the chunk with its context**: the document title and the section path prepended to the
  text. It is cheap, it improves retrieval and it is what makes good citation possible.
- **Store pointers to the document and to the position** (page, offset, section) in the metadata: that is
  what makes verifiable citation possible (§3.7) and what lets you widen the context at generation time.
- **There is no universal size.** It is a hyperparameter: sweep 2-3 configurations against your evaluation
  set and choose by measured `recall@k`, not by what a tutorial says.

### 3.3 Hybrid retrieval: the serious default

**Dense alone is not enough.** Vector search fails exactly where the user is most
specific: identifiers, standard references, product codes, rare proper nouns,
acronyms, literal errors. Lexical search fails on synonyms and paraphrase. Together they cover
each other.

- **Default: dense + lexical (BM25 / `tsvector`), fused with RRF** (*Reciprocal Rank Fusion*).
- **RRF is the fusion default** because it combines rankings without needing to calibrate scores
  across systems whose scales are not comparable. A weighted sum of raw scores requires
  normalisation and decalibrates on its own.
- **Retrieve generously before refining**: a wide top-k (tens) from each retriever is
  cheap; what costs is putting it all into the context. That is what the reranker is for.
- **Metadata filtering** in the query itself (date, type, language, tenant, permissions): it reduces
  the search space and it is where pgvector shines, because it is a normal `WHERE`.

### 3.4 Reranking: the highest return per unit of effort

A **cross-encoder** scores the query and the document **together**, not separately, and that is why it orders much
better than a bi-encoder. The pattern:

```
query → [dense top-50 ∥ BM25 top-50] → RRF → cross-encoder reranker → top-5 → context
```

- **It is the first improvement to try** when retrieval fails, before changing embeddings,
  chunking or architecture. It usually moves `nDCG` more than any of them and costs one component.
- **Cost**: latency proportional to the number of candidates reranked. With a self-hosted reranker
  you avoid the network round trip, at the cost of serving a model (`local-inference-standards`).
- **Verify the licence of the weights** (§2.2): there are quality rerankers with a non-commercial licence.
- **A useful diagnostic**: if your top-50 contains the right passage but your top-5 does not, your problem is
  ordering → reranker. If it is not in the top-50, it is retrieval → hybrid, chunking or
  embeddings. **This distinction is made by measuring `recall@50` against `recall@5`.**

### 3.5 Query expansion: when it helps

- **Multi-query** (reformulating the question into N variants and fusing): it helps on ambiguous
  or multi-part queries. It costs N retrievals + a model call.
- **HyDE** (generating a hypothetical answer and searching with its embedding): it can help when the
  query and the document are worded very differently. It adds a model call on the
  critical path **and it can hallucinate the hypothesis and derail the search**.
- **Criterion**: they are optimisations, not foundations. **Hybrid + reranker first; expansion only if the
  evaluation shows the problem persists and that this fixes it.** Both add latency and
  cost on every query, including the ones that already worked.

### 3.6 Routing by complexity

Not every query deserves the same chain. A simple factual search does not need
multi-query, nor a graph, nor an agent loop. **Route: the cheap chain by default, the expensive chain only
when the query justifies it.** Applying the full arsenal to everything is the fastest way for
the cost per query to run away with no measurable improvement.

### 3.7 The grounded generation prompt

It is the only part of prompting that lives in this skill (the rest: `llm-app-engineering-standards`).

- **Citing sources is mandatory** when the answer asserts facts. The citation must point to a
  concrete, identifiable retrieved fragment, not to "the documents".
- **Verify the citations in code**, not on trust: that the cited identifier is among those
  retrieved. An invented citation is worse than no citation.
- **Saying "I do not know" when the context does not support it is a functional requirement, not a courtesy.**
  An explicit instruction, and in the evaluation: **cases whose correct answer is the refusal.**
- **Hallucinating with the context right there is the failure that destroys trust** — the user sees
  the cited sources and the answer that does not follow from them, and from then on never believes
  the system again. It is measured as **faithfulness to the context** (§4) and it is the generation metric that matters
  most.
- **Separate retrieved context from instructions.** Retrieved content is **untrusted**
  input: a document in the corpus can carry injected instructions
  (`llm-app-engineering-standards` §5). A corpus anyone can write to is an indirect injection
  vector.
- Order the context: the most relevant at the extremes, not buried in the middle (§2.1).

### 3.8 Schema conventions

```
document(id, uri, title, type, version, hash, date, language, acl_ref, created_at)
chunk(id, document_id, position, text, tokens, page, section, hash)
embedding(chunk_id, model, model_version, dim, vector, created_at)
```

- **The chunk's text is always persisted** (§2.4): without it there is no cheap reindexing and no debugging.
- `model` + `model_version` on every vector: without this you cannot migrate nor detect mixing.
- A `hash` per document and per chunk: it is what makes ingestion incremental and idempotent (§6).
- `acl_ref`: the authorisation reference travels **with the chunk** (§5).
- An index versioned by name (`chunks_v3`), not mutated in place.

### 3.9 Chain metrics

Instrument **per stage**, not only end to end: latency and cost of the query embedding,
of dense retrieval, of lexical retrieval, of fusion, of reranking and of generation. Without the breakdown you do not know
what to optimise, and the answer is usually surprising.

### 3.10 Beyond basic RAG — with honesty about its cost

| Architecture | What it is | When it is **worth it** | The cost the blogs leave out |
|---|---|---|---|
| **GraphRAG** | It extracts entities and relations into a graph; retrieval traverses it | "Connect the dots" questions across documents, dependency chains (legal precedent, compliance, supply chain), and **entity resolution** when the same entity appears with different names, acronyms and codes | **A very high indexing cost** (LLM extraction over the whole corpus) and a new pipeline to maintain and rebuild. Lazy-indexing variants reduce that cost a lot — **verify the figures and the maturity (§8), do not assume them** |
| **Agentic RAG** | The model decomposes the query, retrieves, evaluates sufficiency and decides whether to continue | Complex, multi-hop queries where a single pass is not enough | **It multiplies latency and tokens**, and on simple factual queries it is pure waste. It requires routing by complexity (§3.6) and an iteration cap. The loop itself belongs to `ai-agents-standards` |
| **Late interaction** (ColBERT and similar) | Per-token embeddings with late scoring | Cases where a single vector is not enough: a buried clause, a value inside a table, multi-part queries | A much larger index. The bi-encoder + cross-encoder pipeline is simpler and often equivalent |

**A cross-cutting criterion**: **hybrid + reranker first.** It fixes most retrieval
failures. Everything else is added when **your metrics** show the simple approach falls short — not
from reading a blog. Most of the spectacular figures circulating about these
architectures come from vendor blogs with no reproducible conditions.

## 4. Quality and evaluation — gates

**The golden rule of the domain: measure retrieval and generation separately.** An end-to-end
metric tells you the system fails; it does not tell you **where**, and in RAG it is almost always in
retrieval. Without the separation, the team optimises the prompt for weeks while the problem
is in the chunking.

### 4.1 Retrieval metrics (no LLM, deterministic, cheap)

| Metric | What it answers |
|---|---|
| `recall@k` | Did the right fragment reach the context? **The system's most important metric**: if it is low, no generation improvement can save you |
| `precision@k` | How much noise accompanies the signal? High noise displaces evidence and costs more |
| `MRR` | How high does the first relevant result appear? |
| `nDCG@k` | The quality of the **ordering** with graded relevance. **The one reranking moves** |
| `recall@50` against `recall@5` | Diagnosis: it separates a retrieval failure from an ordering failure (§3.4) |

### 4.2 Generation metrics

| Metric | What it answers |
|---|---|
| **Faithfulness to the context** | Does every assertion follow from the retrieved context? It is the anti-hallucination metric |
| **Answer relevance** | Does it answer what was asked? |
| **Citation accuracy** | Do the citations exist among what was retrieved and do they support the assertion? Verifiable **in code** |
| **Correct refusal rate** | Does it say "I do not know" when it should, and only when it should? It requires negative cases in the set |

How they are computed, with which judge and with what calibration: `llm-evaluation-standards`.

### 4.3 Your own domain evaluation set

**You cannot improve what you do not measure, and no public benchmark measures your corpus.** The
minimum viable set:

- **50-200 query → relevant chunk pairs**, labelled over **your** corpus.
- **Real user** queries as soon as you have them. The ones invented by the team are
  systematically easier and cleaner than the real ones.
- Mandatory coverage of **edges**: queries whose answer is that it **is not in the corpus**;
  ambiguous queries; multi-hop (the answer requires two documents); specific ones with an identifier
  or a code; with typos; in each language of the corpus; and **from a user who must not see
  certain documents** (§5).
- It is versioned with the code. It grows when a real failure appears: **every retrieval failure in
  production leaves a regression case.**

### 4.4 Gates that break the build

| # | Gate | It breaks if |
|---|---|---|
| 1 | Lint + types (the language skill) | It fails |
| 2 | Idempotent ingestion: reprocessing the same document does not duplicate chunks | It duplicates |
| 3 | Every vector carries `model` + `model_version`; **no index mixes models** | Mixing detected |
| 4 | Every chunk keeps its text and its pointers (document, position) | Missing |
| 5 | **A permission isolation test**: a user without access to a document **never** receives its chunks (§5) | **A leak. This gate is non-negotiable** |
| 6 | **`recall@k` over the evaluation set with a no-regression threshold** | Regression |
| 7 | **The ANN index's `recall` against exact search** over a sample | Below threshold |
| 8 | Citation accuracy verified in code (every citation points to a retrieved chunk) | An invented citation |
| 9 | Refusal cases: the system does not answer what the context does not support | It answers |
| 10 | **Mandatory evaluation if the diff touches chunking, the embedding model, index parameters, retrieval or the reranker** | Regression over the threshold |
| 11 | Deletion test: with a document removed, its chunks and vectors disappear from the index (§6) | Any survive |
| 12 | SCA over the stack (§5) | A critical, or an unpinned dependency |

## 5. Security

### 5.1 Document-level access control — the classic failure

**RAG's characteristic security failure: a user retrieves a chunk they should not see.** The
application has impeccable authorisation in its API and, underneath, the vector index returns
anything to anyone. The model then cheerfully summarises the confidential document.

The criteria, in order of reliability:

1. **Filter in the query to the store, not afterwards.** Filtering the results in the application after
   retrieving them is fragile (a path that forgets the filter is a leak) and it also breaks the top-k: if
   you discard 8 of 10, you are left with 2.
2. **The authorisation reference travels with the chunk** (`acl_ref` in the metadata, §3.8) and gets
   materialised as a filter on every query. In pgvector this is a `WHERE` and, better still, **Row-Level
   Security** — the net that does not depend on the application remembering (`data-platform-standards`).
3. **Separate indexes per trust boundary** when the isolation must be strong
   (multi-tenant with regulated data). A filter is a condition; a separate index is a boundary.
4. **Permission synchronisation**: if the source's permissions change, the index must reflect it. An
   index with month-old permissions is a delayed leak. Define the frequency and **drive it
   by events** where possible.
5. **A mandatory test in CI** (§4, gate 5), with users at different levels. It is the only control
   that does not degrade on its own.
6. **Beware citations and metadata**: a document's title, its path or its very existence can
   be sensitive information even if the content is not shown. Metadata leakage is real.

### 5.2 Corpus poisoning and indirect injection

- **Retrieved content is untrusted input.** If the corpus accepts user content,
  scraping, email or tickets, an attacker can plant instructions the model will read as
  such. This is indirect prompt injection: the containment happens outside the model
  (`llm-app-engineering-standards` §5).
- **It corresponds to `LLM08` *Vector and Embedding Weaknesses* of the OWASP Top 10 for LLM Applications
  2025** (the current edition; verify §8).
- **Provenance and trust per document**: distinguish the curated corpus from the open corpus in the
  metadata, and treat the latter with less privilege (not citable as authority, not actionable).
- **Embeddings can leak information from the original text** through inversion attacks: do not
  treat them as a form of anonymisation. A vector of a piece of personal data **is** personal data.

### 5.3 Supply chain and dependencies

This ecosystem already has real incidents: the compromise of **LiteLLM on PyPI (March 2026,
versions `1.82.7`/`1.82.8`)** came through a pipeline running an unpinned tool,
and it affected users of several agent and RAG frameworks. **Pin dependencies by hash**,
verify that the published artifact corresponds to a repository tag, and treat as
compromised any host that installed an affected version. Detail in
`llm-app-engineering-standards` §5.4, `cicd-standards` and `vulnerability-management-standards`.

In addition: **pgvector 0.8.2 (Feb 2026) fixed CVE-2026-3172**, an overflow in the parallel
construction of HNSW indexes capable of leaking data from other relations or taking down the server. The vector
engine is attack surface like any other: it goes into the patching cycle.

### 5.4 Personal data in the index

- Minimise before indexing: what does not enter the corpus cannot be retrieved or leaked.
- The vector index is **one more copy** of the data for inventory, retention and erasure purposes
  (§6). If your record of processing does not include it, it is incomplete.
- Encryption at rest and access control on the store, like any database
  (`data-platform-standards`, `cryptography-pki-standards`).
- Framework: `privacy-engineering-standards`.

## 6. Operation

### 6.1 Incremental update

- **Never reindex everything because one document changed.** Ingestion by events or by a sweep with
  change detection: the document `hash` → if it changed, re-chunk and re-embed only that document;
  the chunk `hash` → if the chunk did not change, reuse its vector (a big saving on documents with
  small edits).
- An **atomic operation per document**: delete the old chunks and insert the new ones in one transaction, or
  the index stays inconsistent and serves results from two versions at once.
- **Freshness as a metric**: the delay between the change at the source and its availability in the index.
  With an SLO, if the product depends on it.
- **A full reindex**: it is a planned operation, not an accident. A new index in
  parallel, a recall comparison against the current one, cutover behind a flag, rollback available (§2.4).

### 6.2 Deletion

**The right to erasure applies to the index and to the embeddings**, not just to the source
database. A document deleted from the source that remains in the index gets retrieved, cited and summarised.

- The deletion propagates to: chunks, vectors, the lexical index, query caches, result caches
  and any derived graph (GraphRAG).
- **Real deletion, not logical**, when the legal basis is the right to erasure. A `deleted_at` that
  the retrieval filter can forget is not a deletion.
- **Backups of the index also contain the data**: their handling (crypto-shredding, bounded
  retention, reindexing after a restore) is decided with `privacy-engineering-standards` and
  `backup-recovery-standards`.
- **A deletion test in CI** (§4, gate 11).

### 6.3 Cost and latency of the whole chain

An explicit budget per query, broken down by stage (§3.9):

| Stage | Dominant cost |
|---|---|
| Ingestion (one-off + incremental) | Parsing/OCR + embedding inference over the whole corpus |
| Storage | Vectors (dimensions × corpus) + the index in memory + the original text |
| Query | Query embedding + ANN search + lexical search + **reranking** + **generation** |

- **Generation almost always dominates the cost per query**; reranking dominates the added
  latency. Optimising the ANN search when 90% of the spend is in generation is optimising what
  does not matter: **measure first**.
- **A cache of frequent queries** (by normalised query + permissions) is the most profitable cost
  optimisation on stable corpora. **Always cache inside the permission boundary**: a
  cache shared between users with different access is a leak.
- Alert on: falling recall (corpus or index drift), p95 latency per stage, a rising refusal
  rate (it can indicate broken retrieval), cost per query.

### 6.4 Minimum runbook

Degraded retrieval after a reindex; a corrupt or incomplete index; the embedding model
unavailable; a document that should have been deleted and still appears; a user seeing what they should not
(**a security incident**, not a quality bug → `incident-management-standards`).

## 7. Sustainability and prohibitions

**Review cadence: 3 months.** Embedding models, rerankers, vector store licences
and architectures change quarterly.

- Review: the vector store's version and CVEs, the **licence** (a licence change is the sector's
  frequent pattern), the status of the embedding model and the reranker, and whether the evaluation
  set still represents real traffic.
- **The evaluation set is the system's highest-value long-term asset.** It survives
  changes of model, of store and of framework. Treat it as production code.
- Conscious debt recorded: pending evaluation, deletion not propagated, index parameters
  unmeasured.

**FORBIDDEN**

- ❌ Building RAG without having checked that the corpus does not fit in the context or that
  volume/latency/audit requirements demand it.
- ❌ Using fine-tuning to inject facts. It teaches form, not knowledge.
- ❌ Vectorising structured data that a query or an API answers exactly.
- ❌ **Debugging a RAG failure by touching the prompt without having measured `recall@k` first.**
- ❌ Indexing without verifying the extracted text over a sample (especially PDF).
- ❌ Splitting tables, functions or semantic units just to hit a character limit.
- ❌ Measuring the chunk size in characters instead of in the embedding model's tokens.
- ❌ Using a different prefix/instruction — or none — between indexing and querying.
- ❌ Choosing the embedding model by its MTEB position. It is contaminated and v2 does not compare with v1.
- ❌ Mixing vectors from two models or versions in the same index.
- ❌ Indexing without storing the chunk's original text or the pointers to the document.
- ❌ Changing embedding model without a reindexing plan, a recall comparison and a rollback.
- ❌ Setting ANN index parameters without measuring recall against exact search.
- ❌ Enabling quantisation "for efficiency" without measuring the recall loss.
- ❌ **Dense-only retrieval** as the final architecture: hybrid with lexical is the serious default.
- ❌ Skipping the reranker and jumping to GraphRAG or agentic RAG. It is the cheap improvement to try first.
- ❌ Applying the expensive chain to every query without routing by complexity.
- ❌ Generating without citing when facts are asserted; or citing without verifying the citation in code.
- ❌ Not allowing the system to say "I do not know". Hallucination with context destroys trust.
- ❌ Treating retrieved content as trusted.
- ❌ **Filtering permissions after retrieving instead of in the query to the store.**
- ❌ A result cache shared between users with different permissions.
- ❌ An index without permission synchronisation with the source.
- ❌ Logical deletion as the answer to the right to erasure; a deletion that does not propagate to vectors,
  the lexical index, caches and derived graphs.
- ❌ Treating the embedding as a form of anonymisation.
- ❌ Evaluating without your own domain set, or without negative and edge cases.
- ❌ Chroma in serious production; adopting a new major (Milvus 3.x, Haystack 3.x) without reading the migration guide.
- ❌ Deploying a reranker without verifying the licence of its weights (several are non-commercial).
- ❌ Adding a dedicated vector engine when you have PostgreSQL and moderate volume, without an ADR that
  justifies the extra operational component.
- ❌ Pinning from memory an embedding model name, a price or a benchmark figure (§8).

## 8. Mandatory web verification

1. **Vector stores**: version, **licence** and status of pgvector, Qdrant, Weaviate, Milvus,
   Chroma, LanceDB. Verified as of Aug 2026: pgvector 0.8.6 (PostgreSQL licence), Qdrant 1.18.x
   (Apache-2.0), Milvus **3.0.0** in addition to 2.6.x (Apache-2.0), Weaviate 1.38.x/1.39-rc (core
   BSD-3), Chroma and LanceDB (Apache-2.0). **A licence change is a frequent pattern in this
   sector: re-verify before committing, and check whether any of them has been abandoned or acquired.**
   Prefer Atom release feeds to the summary on an HTML page.
2. **Store CVEs**: pgvector 0.8.2 fixed CVE-2026-3172 (parallel HNSW). Check advisories
   before pinning a version.
3. **Current embedding models** and their maximum length, dimensionality, multilingual support,
   prefix requirements and price. **Not pinned in this document (see the gaps).**
4. **The state of MTEB**: whether it is still the reference, whether there is a consolidated successor, and the extent of the
   contamination/saturation. As of Aug 2026 it is still the de facto reference **with documented
   contamination**, and MTEB v2 is not comparable with v1.
5. **Available rerankers and their licence**: the BGE and mixedbread families (Apache-2.0), Jina
   (CC-BY-NC weights → commercial use via the API), Cohere and Voyage (closed API). **Verify the licence and
   the current version before deploying — the exact versions are not pinned here.**
6. **RAGAS and RAG evaluation frameworks**: RAGAS 0.4.3 is from January 2026 and nothing new had been published
   as of August 2026. **Check whether it is still maintained** before depending on it (detail in
   `llm-evaluation-standards`).
7. **Ingestion frameworks**: LlamaIndex (0.14.x), Haystack (**3.0.0**, Jul 2026 — a breaking
   major), LangChain/LangGraph 1.x. Rule out the abandoned ones.
8. **OWASP Top 10 for LLM Applications**: confirm whether the **2025** edition is still current (`LLM08`
   *Vector and Embedding Weaknesses*) or whether a revision came out.
9. **Supply-chain incidents** in whatever you recommend: precedents in the catalogue — Trivy
   (March 2026), LiteLLM `1.82.7`/`1.82.8` on PyPI (March 2026), `gitleaks` (*feature complete*).
10. **Long context versus RAG**: the degradation thresholds by length (*context rot*, *lost
    in the middle*) and the relative cost figures change with every generation of models.

**Declared gaps — do NOT fill from memory**:

- **Exact names and versions of embedding models**: not pinned. The public sources
  consulted contradict each other on names and version numbering, and the cycle is monthly.
  They are verified against the provider's documentation on each use.
- **Exact versions of commercial rerankers**: not pinned, for the same reason. The **licences**
  are verified per family and are the fact that decides.
- **Prices of embeddings, rerankers and generation**: not pinned in this document.
- **Concrete numeric values for `m`, `ef_construction`, `ef_search`, `lists`, `probes`, chunk size
  and overlap**: **deliberately not pinned.** They depend on the corpus, the model and the hardware;
  any concrete figure would be a tutorial default dressed up as criteria. They are
  determined by measuring (§2.3, §3.2).
- **Cost/latency multipliers of GraphRAG and agentic RAG**: the public figures come mostly
  from vendor blogs with no reproducible conditions. **They are not cited as facts.**
- **The exact volume threshold** at which pgvector stops being enough: the "tens of
  millions of vectors" range is indicative and depends on dimensionality, filtering and hardware.
  Measure it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
