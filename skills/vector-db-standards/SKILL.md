---
name: vector-db-standards
description: Operating a vector search engine as a piece of infrastructure. Use when sizing RAM and disk for an ANN index, choosing binary, scalar, product or rotational/RaBitQ-style vector compression, diagnosing a selective pre-filter or post-filter that collapses recall or latency, collection snapshots and restoring an index, index build and rebuild time, cold start after restart, replication factor, shards and horizontal partitioning of collections, tombstones and graph degradation after deletes, per-collection versus per-filter tenant isolation, securing engines that ship open (Qdrant service.api_key, AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED, Milvus authorizationEnabled and the default root password, ports 6333/6334, 19530, 8080, 8000), embedding inversion as a privacy risk, or non-RAG similarity workloads such as recommendation, deduplication and record linkage, image or audio search, anomaly detection and clustering.
---

# Vector database standards (the engine as infrastructure)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when you have to **deploy, operate, size, back up, scale, secure or pay for** a vector
search engine: the decision of whether a dedicated engine is needed at all, the
recall/latency/memory trade-off as an explicit decision, the RAM cost and build time of each
index family, pre-/post-filtering, index persistence and backup, rebuilding, deletion and graph
degradation, replicas and partitioning, multi-tenancy, and the uses of vector similarity **that are
not RAG**.

Triggers: "do I need a vector database?", "it doesn't fit in memory", "how much RAM does the index
need", "binary/scalar/product quantisation", "compress vectors", "collection snapshot",
"restore an index", "how long does a rebuild take", "cold start", "the engine takes ages to come
up", "replication factor", "collection sharding", "deletion and compaction",
"tombstones", "recall dropped when I added a filter", "the filter returns fewer results than I
ask for", "isolation by collection or by filter", "one tenant per collection", "endpoint with no
authentication", `service.api_key`, `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED`,
`authorizationEnabled`, ports `6333`/`6334`, `19530`, `8080`, `8000`, "embedding inversion",
"deduplication", "record linkage", "image search", "anomaly detection", "clustering",
"similarity-based recommendation".

**Domain thesis**: *a vector engine is a database that lives in RAM and answers with
approximations.* The two halves of that sentence decide everything else: **memory is the dominant
resource and the real cost**, and **recall is not a fact, it is a parameter you have chosen —
consciously or unconsciously**.

**Arbitration rule with `rag-standards` (read it before writing anything in this domain)**: if the
question changes **what is retrieved**, it belongs to `rag-standards`; if it changes **who operates,
pays for, backs up or restores the engine**, it belongs here. Operational corollary: raising
`ef_search` to improve the recall of a RAG belongs to `rag-standards`; the node that runs out of RAM
building that index, or the restore that takes six hours, belongs here.

**Not applicable**:

- **`rag-standards`** — **the critical boundary**. It is **the retrieval pattern for feeding an
  LLM**: chunking, choice and lifecycle of the embedding model and its reindexing cost,
  choosing between pgvector and a dedicated engine **from the perspective of retrieval quality**,
  **HNSW and IVFFlat tuning parameters** (`m`, `ef_construction`, `ef_search`, `lists`,
  `probes`), hybrid dense + BM25 retrieval with **RRF fusion**, cross-encoder reranking,
  metadata filtering as a retrieval technique, `recall@k`/`MRR`/`nDCG` metrics, and per-document
  access control in retrieval. **None of that is repeated here**: when this skill
  needs those concepts, it links to them. Here, the engine as a piece of infrastructure and the
  non-RAG uses.
- `data-platform-standards` — **parent skill**: the PostgreSQL engine (modelling, migrations, replicas,
  PITR, tuning, RLS, JSONB, full-text) and the guiding principle **"one store per need, not per fashion"**,
  which this skill inherits whole. **Three-way arbitration for `pgvector`**: the extension and its index
  parameters belong to `rag-standards`; **the PostgreSQL that hosts it, its backup, its HA and its patching
  belong to `data-platform-standards`**; the criteria for **when pgvector stops being enough and what it
  costs to operate the dedicated piece that replaces it** belong here (§2.2).
- `search-engines-standards` — text engines (Elasticsearch/OpenSearch, Meilisearch, Typesense,
  Vespa, Solr), inverted index modelling, BM25 relevance, index lifecycle and cluster
  operation. **Several of them also do vector search**: if the engine is already deployed
  for its lexical capability, the criteria for operating it are theirs; if it is deployed **for** the
  vectors, they belong here. **Hybrid search crosses all three skills: the fusion criteria live in
  `rag-standards` (RRF) for the RAG case and in `search-engines-standards` for the implementation
  inside the text engine. Fusion is not decided here.**
- `nosql-standards`, `graph-db-standards`, `timeseries-db-standards`, `data-warehouse-modeling-standards`,
  `lakehouse-standards`, `streaming-cdc-standards`, `data-governance-quality-standards`,
  `analytics-bi-standards`, `caching-cdn-standards`, `message-brokers-standards`,
  `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`:
  their engines.
- `data-engineering-standards`: the pipeline that feeds the index (orchestration, idempotent
  backfill, watermarks). Here only the destination and its write cost.
- `privacy-engineering-standards`: personal data, minimisation, DPIA, right to erasure.
  **An embedding of personal data is personal data** (§5.3): here the technical risk of
  inversion and the mechanics of deletion in the engine, there the right and its scope.
- `llm-app-engineering-standards`, `mlops-standards`, `local-inference-standards`: the model that
  produces the vectors, its serving and its lifecycle. Here only what its output costs to store.
- `object-storage-standards`: S3/MinIO/Ceph as a snapshot destination and as the data layer of the
  engines that separate compute from storage.
- `backup-recovery-standards` (backup mechanics, proven restore, immutable repositories) and
  `bcdr-standards` (RTO/RPO derived from the business). Here only **what is particular about backing
  up an ANN index**.
- `kubernetes-standards` (StatefulSets, PVCs, operators), `linux-storage-standards` (the block layer
  under the engine), `iac-standards`, `cicd-standards`, `sre-practice-standards` (SLOs, capacity planning).
- `identity-access-management-standards` (the authorisation model), `secrets-management-standards`
  (the engine's API key), `cryptography-pki-standards` (TLS), `firewall-policy-standards` (whether to
  expose the port — §5.1), `networking-standards`, `vulnerability-management-standards` (CVEs and EOL),
  `grc-compliance-standards`.
- `aws-standards` / `azure-standards` / `gcp-standards`: managed equivalents. The sizing and
  filtering criteria apply the same; the bill and the service model are theirs.
- Language skills (`python-standards`, `typescript-standards`, `go-standards`, …): the clients.

## 2. Default decisions

> Verify version, licence and status on the web before committing to anything (§8). A sector with
> **frequent licence changes and acquisitions**; what is verified here is as of August 2026.

### 2.1 What is this really for? The non-RAG uses

RAG has eaten the conversation, but similarity search is older and broader. Each use has a
different operational profile, and **the profile decides the engine far more than fashion does**:

| Use | Load profile | What decides the design |
|---|---|---|
| **Recommendation** ("similar to this", *related items*) | Very high reads, relatively stable index, hard latency (it is on the rendering path) | Read replicas and cache. Recall matters less than p99 |
| **Deduplication and *record linkage*** | Batch loads, similarity threshold, a huge number of queries against the corpus itself | **It is not a top-k problem, it is a threshold problem.** The result is reviewed: the vector output is *candidates*, not a decision. Similarity blocking + deterministic verification afterwards |
| **Image / audio / video search** | High-dimensionality vectors, huge corpus, batch writes | Memory is the problem from day one. Quantisation mandatory, almost always |
| **Anomaly detection** | Queries the distance to the nearest neighbour, not the list | Corpus *drift* moves the threshold: periodic re-evaluation, or alerts that switch themselves off |
| **Clustering / corpus exploration** | Offline batches, no latency SLA | Almost never needs an online engine: an ANN library in a batch process is enough |
| **RAG** | See `rag-standards` | — |

**Criteria**: if the use is **offline and batch**, an in-process ANN library (FAISS, `usearch`,
`hnswlib`) or a columnar file such as Lance solves it without operating a service. **A service is
justified by concurrency, online updates and multi-client access, not by having vectors.**

### 2.2 Dedicated engine or pgvector? — the honest question

Inherited from `data-platform-standards`: **one store per need, not per fashion.**

| Situation | Decision |
|---|---|
| You already operate PostgreSQL, moderate volume, relational metadata filtering | **`pgvector`.** Backup, PITR, HA, authentication, RLS, transactionality and monitoring **are already solved and already paid for**. Adding a dedicated engine is adding a whole operational piece |
| The index does not fit in the PostgreSQL RAM without choking the OLTP | Dedicated engine, **or** a separate PostgreSQL instance just for vectors (an intermediate option almost nobody considers) |
| You need advanced quantisation, filtering with a complex payload, or horizontal scaling of the index | Dedicated engine |
| A corpus of hundreds of millions or billions of vectors | Dedicated engine with partitioning |
| "It's what people use for AI" | **Not a criterion.** Demands an ADR |

**The exact threshold is not quoted, it is measured.** It depends on dimensionality, quantisation,
filter selectivity, available RAM and target latency — any specific figure you read is someone
else's experiment. **Method**: load a representative sample (≥10 % of the target corpus),
build the index, measure resident RAM, p95 latency with real filters and build time, and
**extrapolate linearly in number of vectors** (index memory scales that way; latency, better
than linearly). If the extrapolation does not fit the budget, you have your answer and you have the ADR.

### 2.3 Engines — verified status (August 2026)

| Engine | Version | Licence | Operational criteria |
|---|---|---|---|
| **pgvector** | **0.8.6** (Jul 2026) | **PostgreSQL** (verbatim: *"Permission to use, copy, modify, and distribute this software…"*) | Default. You operate PostgreSQL, not a new engine |
| **Qdrant** | **1.18.3** (Jul 2026) | **Apache-2.0** | Default dedicated engine: good payload filtering, simple operation, clean licence, rich quantisation (§2.5) |
| **Weaviate** | **1.38.8**; **1.39.0-rc.1** (Aug 2026) | **BSD-3-Clause** (core, verified in the repo's `LICENSE`) | Integrated modules. ⚠️ **Anonymous access enabled by default** (§5.1) |
| **Milvus** | **3.0.0** (Jul 2026) and the **2.6.22** series | **Apache-2.0** | Massive scale in exchange for high operational complexity (several components + etcd + object storage). **Recent major: do not adopt 3.x without reading the migration guide** |
| **Chroma** | tag `Latest` (Jul 2026); last numbered **1.5.9** (May 2026) | **Apache-2.0** | Prototyping. **Not for serious production** (criteria inherited from `rag-standards`) |
| **LanceDB** | **0.36/0.37.x** (Jul 2026) | **Apache-2.0** | Columnar format over object storage. Analytical and batch fit; **cheap storage instead of expensive RAM** is its real proposition |

**Vetoed without an ADR**: adopting a dedicated engine when you have PostgreSQL and moderate volume;
deploying an engine whose licence you have not read this quarter.

### 2.4 Index families — what decides a deployment

Tuning parameters and their effect on recall belong to `rag-standards` §2.3. **Here only what
infrastructure pays for: memory and build time.**

| Family | Memory | Build | Update / delete | When |
|---|---|---|---|---|
| **Exact (brute force)** | Only the vectors | None | Trivial | Small corpus, or **as a reference for measuring the recall of the approximate index**. Recall = 1 by definition |
| **Graph (HNSW and variants)** | **High**: vectors **+ the link graph**, and the graph is not negligible | Slow, and grows more than linearly | Cheap insertion; **deletion degrades the graph** (§6.3) | Default when latency rules and RAM is sufficient |
| **IVF (centroid partitioning)** | Lower than graph | **Requires training on representative data already loaded** | Retrain when the distribution changes | When memory is the constraint and you accept worse recall |
| **With quantisation** (§2.5) | **The main lever**: divides memory by a large factor | Adds a training phase in PQ; scalar and binary are cheap | Same as the base family | When the index does not fit, which is almost always beyond a certain size |
| **On disk / hybrid** | Low RAM, high I/O | Medium | Medium | Huge corpus with tolerant latency. **Requires NVMe: over network storage it collapses** |

**Sizing rules that are always forgotten**:

1. **Budget RAM for two indexes, not one**: rebuilding without downtime requires the new one to
   coexist with the old one. If the node only holds one, you have no hot-rebuild path.
2. **Build time is either an unavailability window or a double cost.** Measure it before
   committing to a freshness SLA.
3. **Dimensionality is paid linearly in everything**: storage, index memory, bandwidth
   and comparison latency. Reducing it (Matryoshka, PQ) is usually the most profitable cost
   optimisation — the choice of model and its dimension belongs to `rag-standards` §2.4.

### 2.5 Quantisation — the cost lever

Verified as of Aug 2026, **per engine** (§8):

| Engine | Methods | Note |
|---|---|---|
| **Qdrant** | **TurboQuant** (up to 32×), **scalar** (4×), **binary** (up to 32×), **product** (up to 64×) | The official docs recommend 4-bit TurboQuant over scalar except with Manhattan distance (L1) |
| **Weaviate** | **RQ (rotational, recommended by the docs)**, **PQ**, **BQ**, **SQ**, or none | The docs mention compression by default from a certain version onwards: **verify which one applies to yours** |
| **Milvus** | SQ, PQ, binary and variants | Verify per version: 3.x changed things |
| **pgvector** | `halfvec` (half precision) and binary quantisation via an expression index | Less rich than that of the dedicated engines; usually enough |

**Hard rules**:

- **Quantisation is approximation on top of approximation.** An ANN index already costs recall;
  compressing costs more. **Measure recall before and after against brute force** (method in
  `rag-standards` §2.3) — never enable it "for efficiency" without the measurement.
- ***Rescoring* with full vectors is what makes aggressive quantisation usable**: search
  compressed, reorder the candidates at full precision. If your engine supports it, enable it; if
  it does not support it, aggressive binary is usually unacceptable.
- **Compression factors come from the engine's documentation; the impact on recall comes from your
  corpus.** The recall numbers vendors publish are measured on academic datasets with
  benign distributions. They are not your corpus.

## 3. The filtering problem — the section that prevents the incident

**It is the most common production failure in this domain** and it is almost never seen coming, because **it
does not raise an error**: in development, with 10,000 vectors and no filters, everything works; in
production, with selective filters, the system returns worse results or takes an order of magnitude longer.

The ANN index is built over **all** of the vector space. A metadata filter
(tenant, date, language, permissions, category) breaks that premise. There are three strategies and
all three fail differently:

| Strategy | What it does | How it fails |
|---|---|---|
| **Post-filtering** | Searches the index, filters afterwards | **Returns fewer than `k`, or nothing.** You ask for 10, the index returns 10 global candidates, the filter discards 9 → you are left with 1. With very selective filters, zero results and silence |
| **Naive pre-filtering** | Selects by the filter, then searches exactly over the subset | Correct but **can degrade into a full scan** if the subset is large. Latency shoots up |
| **Filtering during traversal** (*filterable HNSW*, *iterative scan*, payload indexes) | The graph traversal applies the filter while navigating | The right thing, but **the graph can become disconnected**: if the nodes that pass the filter are not reachable from each other, recall drops silently |

**Criteria**:

1. **Know which of the three your engine implements and under what conditions it switches from one
   to another.** Many engines have heuristics based on estimated selectivity: below a threshold they
   do one thing, above it another. That threshold is configurable and almost nobody touches it.
2. **Measure recall *with the filter applied*, not without it.** 98 % recall without a filter and
   40 % with `tenant_id = X` is a broken system that passes every test.
3. **Index the filter fields.** A filter with no payload index forces the engine to evaluate
   condition by condition during traversal.
4. **Ultra-selective filters (a small tenant, a specific user) are almost always resolved better
   with exact search over the subset** than with ANN. If the engine does not decide it by itself, decide it yourself.
5. **A filter whose selectivity varies a lot between tenants is a latency bomb**: p99 will be
   set by the worst tenant. Measure per tenant, not in aggregate.

**Metadata filtering *as a retrieval technique in RAG* belongs to `rag-standards`.** Here its
consequence on the index, latency and recall.

## 4. Quality and gates

| # | Gate | Breaks if |
|---|---|---|
| 1 | **Index recall measured against brute force** over a sample, with a non-regression threshold | It falls below the threshold |
| 2 | **Recall measured *with the production filters applied*** (§3), not only without a filter | It falls below the threshold |
| 3 | **A change of quantisation, index family or dimensionality ⇒ mandatory recall measurement** in the diff | The measurement is missing |
| 4 | **Proven restore**: snapshot restored in a clean environment and queried, with the time recorded | It does not restore, or the time is not measured |
| 5 | **Declared memory budget** (index RAM extrapolated to the target volume) and an alert before exhausting it | It does not exist |
| 6 | **Authentication and TLS enabled in every network-reachable environment**, verified by an automated test that makes a request **without credentials** and expects `401`/`403` | It answers `200` |
| 7 | **Isolation between tenants**: a test that one tenant does not retrieve another's vectors (§5.2) | Leak. **Non-negotiable** |
| 8 | **Propagated deletion**: once a record is deleted, it does not reappear in results after compaction | It survives |
| 9 | Index rebuild rehearsed and **timed** at least once a quarter | Not rehearsed |
| 10 | SCA and CVEs of the engine and its clients (§5.4) | Critical without mitigation |

**Gate 6 is the one that saves you most often.** A vector engine with an anonymous `curl` that
returns `200` is a data leak, not a configuration issue.

## 5. Security

### 5.1 These engines ship open — verified per engine

**The most valuable security fact in this skill.** Verified in the official documentation as of Aug 2026:

| Engine | Default state | Quote / evidence |
|---|---|---|
| **Qdrant** (self-hosted OSS) | **No authentication** | Official docs, verbatim: *"By default, all self-deployed Qdrant instances are not secure."* and *"By default, an open source Qdrant deployment accepts requests from anyone who can reach it."* It is closed with `service.api_key` (and read-only / granular keys). In Qdrant Cloud it is enabled by default |
| **Weaviate** | **Anonymous access enabled** | Environment variable reference, verbatim: `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED` … *"Defaults to true"*. It must be set to `false` and API key or OIDC enabled explicitly |
| **Milvus** | **Authentication disabled**, and with a **known default password** | Official docs, verbatim: *"By default, the `root` user is created with the password `Milvus` when Milvus is initiated."* It is enabled with `common.security.authorizationEnabled` |
| **Chroma** | No authentication in the standard startup | Port `8000`. Auth configuration explicit and optional |
| **pgvector** | **Inherits PostgreSQL's authentication** | **It is its biggest security advantage and almost nobody mentions it**: `pg_hba.conf`, roles, TLS, RLS and auditing already exist and are already reviewed |
| **LanceDB** (embedded) | There is no service to authenticate | The control is the storage's (S3/object IAM). **If the bucket is open, the index is open** |

**Rules**:

- **No vector engine is exposed to the Internet. Ever.** There is no legitimate use case for a port
  `6333`, `19530`, `8080` or `8000` of a vector engine reachable from outside. Private network, and a
  default-deny firewall rule (`firewall-policy-standards`).
- **Public research (Orca Security, May 2026)** documents exposed instances enumerable without
  authentication on those default ports, with entire corpora —tickets, knowledge bases,
  conversations— accessible. **The exact number of instances is not pinned here** (§8): what decides
  is that the pattern is confirmed and automated.
- **The API key is a secret**: `secrets-management-standards`. Not in `docker-compose.yml`, not in the
  chart, not in the image.
- **TLS mandatory** inside the perimeter too (`cryptography-pki-standards`): the vectors and the
  payloads travel in the clear otherwise.
- **The metrics endpoint and the web panel are also exposed.** Count them when opening ports.

### 5.2 Multi-tenancy: isolation by collection versus isolation by filter

| Model | Isolation | Cost | Effect on recall |
|---|---|---|---|
| **Collection (or index) per tenant** | **Strong**: a boundary, not a condition. Deleting a tenant is deleting a collection | High with many tenants: each collection has fixed index and memory overhead. Thousands of small tenants do not scale this way | **Better**: the index contains only the tenant's data, with no filter to degrade traversal |
| **`tenant_id` filter in a shared collection** | **Weak**: it depends on **every** query carrying the filter. A path that forgets it is a leak | Low and uniform | **Worse and variable**: it is exactly the problem of §3, and p99 is set by the large tenant |
| **Hybrid** (collection per large tenant, shared for the long tail) | Strong where it matters | Medium | Acceptable, at the cost of two code paths |

**Criteria**: **if isolation is a regulatory or contractual requirement, separate collection.** A
filter is a condition that an `if` can skip; a collection is a boundary. If you choose a filter,
the filter is injected **in a layer the application cannot go around**, and gate 7 of §4 proves it
in CI. **Per-document** access control inside a RAG belongs to `rag-standards` §5.1.

### 5.3 Embedding inversion — the specific privacy risk

**An embedding is not a hash nor an anonymisation.** Inversion attacks exist that reconstruct
the original text fully or partially from the vector, and membership inference attacks
that reveal whether a document was in the corpus.

Operational, not theoretical, consequences:

- **A vector derived from personal data is personal data**: it enters the record of
  processing, classification, retention and the right to erasure
  (`privacy-engineering-standards`).
- **Do not export vectors to third parties or to lower-trust environments "because they are just
  numbers".** A dump of embeddings is a dump of content.
- **Deleting the source without deleting the vector is not deletion** (§6.3).
- Minimise before vectorising: what does not enter the corpus cannot be reconstructed.

### 5.4 Attack surface and supply chain

- **The engine enters the patching cycle like any other database.** Verified
  precedents: **Milvus CVE-2025-64513**, complete authentication *bypass* in the Proxy
  component exploitable **unauthenticated**, with full administrative access; fixed in
  2.4.24 / 2.5.21 / 2.6.5. **pgvector 0.8.2 (Feb 2026) fixed CVE-2026-3172** (parallel HNSW
  index builds).
- Indirect risk through integrations: **CVE-2026-24477** leaked the Qdrant API key in the clear to
  unauthenticated users through an AnythingLLM endpoint. **Your engine's key can be leaked by
  any piece that uses it.**
- Pin the image by **digest**, not by tag; SBOM and signing (`cicd-standards`,
  `vulnerability-management-standards`).

## 6. Operation

### 6.1 Persistence and durability — verify it, do not assume it

Several of these engines were born **in memory only** or with optional persistence and added
durability later. **Before putting in data you cannot regenerate, answer in writing**:

1. What is persisted: the vectors, the index, or both? Many engines persist the vectors and
   **rebuild the index at startup** — that is the cold start (§6.5).
2. Is there a *write-ahead log*? What is lost on a `SIGKILL`?
3. Is the write a synchronous *fsync* or deferred? Configurable?
4. What consistency guarantee is there between replicas, and what do you see during a node failure?

**Golden rule that saves half of these questions: the vector index is a derived projection, not the
source of truth.** The original text, the metadata and —if you can afford it— the
vectors live in a durable store (PostgreSQL, object storage). That way, **the worst case for the
vector engine is reindexing, not losing data.** Design for that from day one and half of this
section stops being critical.

### 6.2 Backup and restore

- **A snapshot of an ANN index is not a `pg_dump`.** It is usually a consistent copy of binary
  segments coupled to the **engine version**: restoring it on a different version can fail or
  degrade silently. **Record the version with the snapshot.**
- **A hot disk snapshot taken without coordinating with the engine can be inconsistent.**
  Use the engine's own snapshot mechanism, or freeze writes (`fsfreeze` and hooks:
  `backup-recovery-standards`).
- **The real cost of the backup is the restore, and restoring a large index includes loading it into
  memory.** Time it (§4, gate 4) and compare it against the committed RTO (`bcdr-standards`). It is
  common for **reindexing from the source of truth to be faster than restoring** — if that is your
  case, that is your recovery procedure and it has to be written down.
- Destination: object storage with versioning and immutability (`object-storage-standards`),
  client-side encrypted.

### 6.3 Updates, deletions and compaction

- **Graph indexes degrade with deletion.** The usual pattern is to mark (*tombstone*) and
  compact later: between the two, the index occupies memory for vectors that no longer exist and
  traversal passes through dead nodes. **Recall and latency get worse over time in a corpus with
  high turnover.**
- **Compaction is I/O and CPU intensive**: schedule it, observe it and account for its peak. A
  very volatile corpus may need **periodic rebuilding**, not just compaction.
- **Updating a vector = delete + insert** in almost every engine. Reindexing the same
  document repeatedly inflates the index even though the logical number of records does not change. Watch
  **logical vectors versus physical vectors**: if they diverge much, it is time to compact or rebuild.
- **In IVF, the distribution changes and the centroids age**: recall drops even though nothing fails.
  Retraining is a planned operation.
- **Deletion and the right to erasure**: the deletion must reach the vector, the index, the replicas,
  the current snapshots and any cache. A `deleted=true` that a filter can forget **is not
  a deletion** (`privacy-engineering-standards`; mechanics in RAG: `rag-standards` §6.2).

### 6.4 Scale

- **Read replicas** are the easy lever: the load on these systems is usually overwhelmingly
  read. They cost **full memory per replica** — the index is not shared.
- **Partitioning (sharding)**: splits the corpus. Each query goes to **all** the shards and is
  merged, so **p99 is set by the slowest shard** and adding shards does not reduce latency, only
  memory per node. **Partition for memory, not for latency.**
- **Partitioning by a business key (tenant, language, date)** is better than partitioning at random
  **if the queries carry that key**: then the query touches one shard and latency does improve.
  It is the design decision with the highest return in this section.
- **When the index stops fitting in memory** there are exactly four ways out, in order of increasing
  cost: **(1)** quantise (§2.5), **(2)** reduce dimensionality, **(3)** on-disk index over
  NVMe, **(4)** partition horizontally. Buying RAM is the fifth and not always the worst.
- **Rebalancing**: moving a shard is moving gigabytes and rebuilding an index. Ask **before**
  deploying how long it takes and whether it can be done without downtime.

### 6.5 Cold start

**The startup time of a vector engine is not that of a process, it is that of loading tens or
hundreds of GB into memory** (or rebuilding the index, per §6.1). Consequences that break deployments:

- *Liveness*/*readiness* probes with web-service thresholds **kill the pod in a loop**
  (`kubernetes-standards`): tune `startupProbe`.
- A rolling restart of N replicas costs N × startup time, with reduced capacity meanwhile.
- **Reactive autoscaling does not work** with this profile: by the time the new replica is ready, the
  peak has passed. Over-provision or scale on an anticipatory signal.
- Measure it and put it in the runbook. It is the number nobody has when it is needed.

### 6.6 Cost and observability

**Memory is the dominant cost**, and it rises through three multiplying paths: number of vectors ×
dimensionality × replicas. The levers, by return: **quantisation → dimensionality →
number of replicas → on-disk index**.

Instrument (`observability-standards` covers the transport and the backend):

- **Resident RAM of the process versus node RAM** — the metric that predicts the outage.
- p50/p95/p99 latency **per collection and per tenant**, not in aggregate.
- **Logical versus physical vectors** (compaction debt).
- Write rate, indexing lag, compaction duration.
- **Recall measured periodically against brute force over a sample**: it is the only alarm that
  detects silent degradation. **Without it, an index that gets worse produces no signal at all.**
- Cold start time and index build time, as historical series.

### 6.7 Minimum runbook

Index that does not fit in memory (node OOM); latency spiking after adding a filter; recall that
drops with no code change (pending compaction, aged centroids, corpus drift);
snapshot that does not restore on the current version; node that never finishes starting; tenant that sees
another's data (**security incident**, not a bug: `incident-management-standards`,
`incident-response-forensics-standards`); engine discovered exposed without authentication (assume
compromise and treat the corpus as leaked).

## 7. Sustainability and prohibitions

**Review cadence: 3 months.** Versions, licences, quantisation methods and CVEs move
quarterly in this sector.

- Review: engine version and CVEs, **licence** (frequent change pattern), new quantisation
  support (methods with a better trade-off appear every few months), and whether the memory
  budget still matches the real growth of the corpus.
- **Updating the engine may require rebuilding the index or invalidate snapshots.** Read it in the
  release notes beforehand, not during.
- Recorded conscious debt: recall not measured, restore not proven, pending compaction,
  postponed authentication ("it's only on the internal network").

**FORBIDDEN**

- ❌ Deploying a dedicated vector engine when you have PostgreSQL and moderate volume, without an ADR.
- ❌ Deploying a service for an **offline batch** use that an in-process ANN library would solve.
- ❌ **Exposing the engine's port to the Internet.** Under no circumstances.
- ❌ **Starting up in any network-reachable environment without authentication or TLS** (§5.1). "It's on the
  internal network" is not a control.
- ❌ Leaving Milvus's default password (`root`/`Milvus`) or any demo credential.
- ❌ Putting the engine's API key in the `docker-compose.yml`, the chart or the image.
- ❌ **Pinning index parameters or enabling quantisation without measuring recall against brute force.**
- ❌ **Measuring recall without the production filters applied** and declaring the system good.
- ❌ Trusting post-filtering with selective filters and not noticing that you return fewer than `k`.
- ❌ Filtering by a field without a payload index.
- ❌ Sizing RAM for a single index and being left with no hot-rebuild path.
- ❌ Treating the vector index as the source of truth, with no durable source to reindex from.
- ❌ Snapshot without a proven restore and **without timing it**; snapshot without recording the engine version.
- ❌ Copying the disk hot without using the engine's snapshot mechanism or freezing writes.
- ❌ Ignoring graph degradation from deletion in a corpus with high turnover.
- ❌ Logical deletion as an answer to a right to erasure.
- ❌ **Treating an embedding as anonymisation**, or exporting it to a lower-trust environment.
- ❌ Multi-tenancy by filter when isolation is a regulatory requirement, or without an isolation
  test in CI.
- ❌ Startup probes with web-service thresholds over an engine that loads GB into memory.
- ❌ Reactive autoscaling as the capacity plan of an engine with a long cold start.
- ❌ Chroma in serious production; adopting Milvus 3.x without reading the migration guide.
- ❌ Duplicating `rag-standards` criteria here (chunking, embeddings, ANN tuning, hybrid, RRF,
  reranking, `recall@k`) instead of linking to them.
- ❌ Pinning a version, a licence, a compression factor or a recall figure from memory (§8).

## 8. Mandatory web verification

1. **Version and licence of each engine**: pgvector, Qdrant, Weaviate, Milvus, Chroma, LanceDB.
   Verified as of Aug 2026 via release Atom feeds and the repository's `LICENSE` files (not via
   summaries of HTML pages, which **invent dates**): pgvector 0.8.6 / PostgreSQL licence;
   Qdrant 1.18.3 / Apache-2.0; Weaviate 1.38.8 and 1.39.0-rc.1 / **BSD-3-Clause confirmed in the
   core's `LICENSE`**; Milvus **3.0.0** and 2.6.22 / Apache-2.0; Chroma / Apache-2.0; LanceDB
   0.36-0.37.x / Apache-2.0. **Re-verify: licence change is the sector's pattern.**
2. **CVEs**: Milvus **CVE-2025-64513** (unauthenticated auth bypass, fixed in 2.4.24/2.5.21/
   2.6.5), pgvector **CVE-2026-3172** (fixed in 0.8.2), **CVE-2026-24477** (leak of the Qdrant API
   key via AnythingLLM). Check for new advisories before pinning a version.
3. **Default authentication per engine** (§5.1). Verified verbatim in official documentation for
   Qdrant, Weaviate and Milvus. **Re-verify it on every major version: it is the fact that changes
   most and the one that costs most if it is wrong.**
4. **Quantisation support per engine and version** (§2.5), and whether there is *rescoring* with full vectors.
5. **Persistence model** of the specific engine (§6.1): what is persisted, WAL, fsync, and whether the index
   is rebuilt at startup.
6. **Snapshot compatibility between versions** before any update.
7. **Equivalent managed services** and their pricing model (`aws-standards`, `azure-standards`,
   `gcp-standards`) — they change often.
8. **Supply-chain incidents** in the ecosystem (precedents in the catalogue: LiteLLM on
   PyPI, March 2026).

**Declared gaps — do NOT fill in from memory**:

- **Exact volume threshold at which pgvector stops being enough**: deliberately not pinned. It depends
  on dimensionality, quantisation, filter selectivity, RAM and target latency. **It is measured with
  the method of §2.2.**
- **Memory consumption formulas per index family**: not pinned. The ones in circulation omit the
  real overhead of the graph and the payload. Measure it over a sample.
- **Impact on recall of each quantisation method**: **not pinned.** The compression factors come
  from the vendor's documentation (verified); recall depends on your corpus and your model.
- **Quantisation in Milvus 3.x**: not verified in detail in this review (the major is from Jul 2026).
  Consult its documentation before pinning anything.
- **Default auth status of Chroma and LanceDB**: verified only indirectly (Chroma without
  auth in the standard startup, port 8000; embedded LanceDB exposes no service). **Confirm it in their
  documentation before deploying.**
- **Figures for instances exposed on the Internet**: the pattern is confirmed by public research
  (Orca Security, May 2026); **the specific counts circulating in blogs are not quoted as facts.**
- **Latencies, throughput and comparative benchmarks between engines**: not pinned. The public ones are almost
  always from vendors, without reproducible conditions and over academic datasets.
- **Prices of the managed services**: not pinned.

If the web contradicts this document, **the web wins** — flag the discrepancy.
