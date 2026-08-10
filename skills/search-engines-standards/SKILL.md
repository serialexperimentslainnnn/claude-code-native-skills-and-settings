---
name: search-engines-standards
description: Text search and document indexing engines as infrastructure. Use when deciding between PostgreSQL full-text and a search cluster, comparing Elasticsearch, OpenSearch, Meilisearch, Typesense, Manticore, Vespa, Solr or Quickwit and their licences (Elastic License 2.0, SSPL, AGPLv3, BUSL enterprise editions, GPL), writing elasticsearch.yml, opensearch.yml, solrconfig.xml or a managed-schema, designing an explicit index mapping instead of dynamic mapping, analyzers, tokenizers, ascii folding and per-language stemming including Spanish, keyword versus text fields, the reindex API and index aliases for zero-downtime schema change, relevance tuning with field boosting, synonyms and judgment lists, shard and replica sizing and the too-many-small-shards trap, index lifecycle management with hot/warm/cold tiers, snapshot repositories and restore, major-version upgrades that force a reindex, deep pagination with search_after, wildcard-prefix and deep-aggregation query cost, or a search endpoint exposed to the internet without authentication or TLS.
---

# Text search engine standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **choosing, modelling, operating, tuning and securing** a text search and document
indexing engine: the prior decision of whether one is needed at all, the choice of product **and of
licence**, index and analyzer modelling, relevance and its measurement, cluster operation
(shards, replicas, lifecycle, snapshots, upgrades) and query performance.

Triggers: "internal search", "catalogue search", "autocomplete", "facets", "the search returns
rubbish", "tune relevance", "synonyms", "stemming", "accents and search",
"Spanish analyzer", `elasticsearch.yml`, `opensearch.yml`, `solrconfig.xml`, `managed-schema`,
"dynamic mapping", "explicit mapping", "`keyword` or `text`", "reindex", "index alias",
"too many shards", "small shards", "ILM", "hot/warm/cold", "snapshot repository", "restore an
index", "major version upgrade", "deep pagination", `search_after`, "leading wildcard",
"deep aggregation", "Elasticsearch licence", "OpenSearch", "Meilisearch", "Typesense",
"Manticore", "Vespa", "Solr", "Quickwit", "the search engine is exposed".

**Thesis of the domain**: **a search index is not a table, and reindexing is the normal operation,
not the exception.** A mapping is immutable in essence: changing a field's type, its analyzer or
its tokenization forces a full rebuild of the index. Everything else in this skill —aliases, ILM,
versioning, capacity— exists to make reindexing cheap and boring. **If reindexing scares you,
your design is wrong.**

**Not applicable**:

- `data-platform-standards` — **parent skill**: PostgreSQL, **its full-text (`tsvector`, GIN,
  `websearch_to_tsquery`) and JSONB**, and the guiding principle **"one store per need, not per
  fashion"**. **Arbitration**: whether PostgreSQL is enough for you (§2.1) is decided here, but **the
  implementation of full-text in PostgreSQL is theirs**. If the answer is "yes, it is enough", you
  close this skill and work there.
- `observability-standards` — **Loki, the log pipeline, OTel, retention and cardinality are
  theirs**, and their explicit criteria is not to bring in Elastic/OpenSearch without a real need for
  full-text search over logs. Here **only the engine** once it has been decided that a search engine
  is used: index modelling, shards, ILM, snapshots. **The decision of which log backend to use is theirs.**
- `detection-engineering-standards` — **the SIEM: Sigma rules, detections, ECS/OCSF normalisation,
  triage and ATT&CK coverage are theirs**, including the Elastic Security layer on top of Elasticsearch. Here
  the engine underneath: cluster, indices, physical retention, performance. **Boundary by purpose: if
  the artifact is a rule or an alert, it is theirs; if it is a shard or a snapshot, it belongs here.**
- **`rag-standards`** — retrieval to feed an LLM: chunking, embeddings, **hybrid dense + lexical
  retrieval and its fusion (RRF)**, reranking, `recall@k`. **Hybrid search crosses three
  skills and the rule is single: the fusion criteria lives in `rag-standards` for the RAG case; here
  only the lexical part and the implementation of fusion inside the text engine when the engine
  offers it natively. It is not duplicated.**
- `vector-db-standards` — the vector engine as infrastructure: ANN index memory,
  quantization, pre/post filtering, snapshots, multi-tenancy, non-RAG uses. **Several text engines
  also do kNN**: if the cluster already exists for its lexical capability, adding vectors belongs
  here; if the deployment is justified **by** the vectors, it belongs there.
- `nosql-standards` — **a very close boundary: a document store and a search engine look very much
  alike from the outside and are not the same piece.** Rule: if access is **by key or by a known access
  pattern, with consistent reads and the data is the source of truth**, it is a document store (theirs).
  If access is **by free text with relevance ranking, facets and aggregations over a derived
  projection**, it is a search engine (here). **A search engine is not your primary database** (§3.1).
- `data-engineering-standards` (the pipeline that feeds the index), `streaming-cdc-standards`
  (CDC from the source of truth into the index),
  `data-governance-quality-standards`, `analytics-bi-standards`, `lakehouse-standards`,
  `graph-db-standards`, `timeseries-db-standards`, `message-brokers-standards`,
  `caching-cdn-standards`.
- `privacy-engineering-standards`: **personal data inside the index, its retention and the right to
  erasure** — a search index is one more copy of the data (§5.4).
- `api-design-standards`: the contract of your search API to the outside. **Do not expose the engine's
  query DSL to your clients** (§5.2).
- `kubernetes-standards` (StatefulSets, operators), `linux-storage-standards` (the block layer and the
  I/O scheduler under the engine), `object-storage-standards` (snapshot repository),
  `backup-recovery-standards`, `bcdr-standards`, `sre-practice-standards`, `iac-standards`,
  `cicd-standards`.
- `identity-access-management-standards` (SSO/OIDC against the engine and its dashboard),
  `secrets-management-standards`, `cryptography-pki-standards` (TLS and transport certificates),
  `firewall-policy-standards` (exposing the port), `networking-standards`,
  `vulnerability-management-standards` (CVEs and EOL), `grc-compliance-standards`.
- `aws-standards` / `azure-standards` / `gcp-standards`: the equivalent managed services.
- Language skills: the official clients and their versioning.

## 2. Default decisions

> Verify version, **licence** and status on the web before committing to anything (§8). **In this sector the
> licence has changed several times and it is the datum that decides**: what is verified here is as of August
> 2026, against repository `LICENSE` files and release Atom feeds.

### 2.1 The prior question: is PostgreSQL full-text enough for you?

**For most catalogues, internal search, documentation and back-offices, yes.** And it avoids
operating a whole cluster, with its lifecycle, its backups, its upgrades and its attack surface.

| Need | Is PostgreSQL enough? |
|---|---|
| Searching a catalogue of thousands or a few million rows, with SQL filters | **Yes.** `tsvector` + GIN index. And filtering by permissions, price or status is a transactional and consistent `WHERE` |
| Search that must be **immediately** consistent with the write | **Yes, and it is its greatest advantage**: there is no indexing lag and no pipeline to fall over |
| The searchable data already lives in PostgreSQL and there is no other source | **Yes.** Adding a search engine means adding a copy, a pipeline and a failure mode |
| Light facets and aggregations | **Yes**, with `GROUP BY` as long as the volume allows it |
| Basic fuzzy matching and suggestions | **Yes**: `pg_trgm`, `unaccent` |
| Genuinely tunable relevance, field boosting, managed synonyms | **No.** `ts_rank` is rudimentary and cannot be tuned like BM25 |
| Facets and aggregations over tens of millions of documents with low latency | **No** |
| Very high query volume competing with the OLTP load | **No** (or a dedicated replica as an intermediate step) |
| A corpus of documents, not of rows: PDFs, attachments, long multilingual text | **No** |
| Autocomplete with tens-of-ms latency and typo tolerance | **No**, except in simple cases |

**Decision rule**: **start on PostgreSQL. Make the jump when you measure that it does not reach** —latency,
load on the OLTP, or a relevance/faceting need that `ts_rank` does not cover— **and write it in
an ADR with the operational cost accepted.** There is an intermediate step almost nobody considers: **a
PostgreSQL read replica dedicated to search** solves the contention problem without
introducing a new piece. (Extensions such as ParadeDB/`pg_search` bring BM25 to PostgreSQL: they are an
option, with their own dependency cost — verify them, §8.)

### 2.2 Choice of engine — and the licence mess

**This is the main decision of the domain, and it is legal before it is technical.** Status verified as of
August 2026:

| Engine | Version | Licence (verified) | Criteria |
|---|---|---|---|
| **Elasticsearch** | **9.4.4** (Jul 2026); 9.3.8 and 8.19.19 maintained | **Triple**, verbatim from `LICENSE.txt`: *"a triple license under the 'GNU Affero General Public License v3.0 only', 'the Server Side Public License, v 1', and the 'Elastic License 2.0'"* | Maximum ecosystem and capabilities. **AGPLv3 was added as a third option from 8.16 onwards** after the SSPL/ELv2 episode of 2021. ⚠️ **See the warning about binaries below** |
| **OpenSearch** | **3.7.0** (Jun 2026); LTS **2.19.6** | **Apache-2.0**, unambiguous | **Default when the licence matters.** Governance: ownership transferred from Amazon to the **OpenSearch Software Foundation**, a **Linux Foundation** project, announced on **16-Sep-2024**. It is the engine with the cleanest governance in the sector |
| **Meilisearch** | **1.52.0** (Aug 2026) | ⚠️ **`MIT AND BUSL-1.1`** — verbatim from the `LICENSE`: the **Enterprise Edition** (files under `enterprise_editions`) is **BSL 1.1**, production use **only with a commercial contract**; the rest MIT. Change License MIT after 4 years | Product search engine, very good developer experience. **It is no longer "MIT and that's it": audit which modules you use.** Very active |
| **Typesense** | **30.2** (Apr 2026); `v31` branch active (Jul 2026) | **GPL-3.0** | Lightweight, typed alternative, no JVM. **GPL-3 is a conscious decision** if you embed or distribute it |
| **Manticore Search** | **28.6.6** (Jul 2026) | **GPL-3.0** | Heir to Sphinx. Very active, very resource-efficient; small ecosystem |
| **Vespa** | **8.731.x** (Jul 2026) | **Apache-2.0** | Search + ML ranking + vectors in a single engine, at large scale. **Steep learning curve and high operational cost**: justified by advanced relevance, not by searching text |
| **Apache Solr** | **10.0.0** (Mar 2026); 9.11-beta | **Apache-2.0** (ASF) | Mature, foundation governance. Ecosystem in decline against ES/OS; a reasonable choice if you already operate it |
| **Quickwit** | **0.9.0** (Jul 2026), repo active as of Aug 2026 | **Apache-2.0** | **Acquired by Datadog (Jan 2025)** and relicensed to Apache-2.0; **not abandoned**, still publishing. Niche: search over object storage for **logs and traces** — and there the backend decision belongs to `observability-standards` |

**⚠️ The warning that really decides on Elasticsearch**: the repository's `LICENSE.txt` is
triple, but **there are consistent reports that the official binary distributions are shipped
under Elastic License 2.0**, not under AGPLv3. **If your reason for choosing Elasticsearch is "it is open
source again", verify the licence file of the specific artifact you download or of the image
you deploy, not the one in the repository.** This is a declared gap (§8): do not take it as settled.

**Default criteria**:

1. **You use nothing**: PostgreSQL (§2.1).
2. **You need a search engine and the licence matters** (SaaS, product, distribution, company
   policy): **OpenSearch**. Apache-2.0 and a neutral foundation.
3. **You need the Elastic ecosystem and accept ELv2 on the binaries**: **Elasticsearch**.
4. **Product search engine, small team, no JVM**: **Meilisearch** (auditing the BSL boundary) or
   **Typesense** (accepting GPL-3).
5. **Advanced relevance with ML at large scale**: **Vespa**, with an ADR acknowledging its cost.
6. **You already operate Solr**: do not migrate without a reason.

**Vetoed without a signed ADR**: choosing an engine without having read its licence file **this
quarter**; assuming an engine still has the licence it had the last time you looked.

## 3. Index modelling

### 3.1 Foundational rules

- **The search engine is not the source of truth.** It is a **derived projection** of a durable store.
  Practical consequence: you can delete the whole index and rebuild it; backing it up is an
  RTO optimisation, not a durability need. **If you cannot rebuild your index from the
  source, you have an architecture problem, not a search problem.**
- **An index is modelled per query, not per entity.** Denormalise: embed what the query
  needs to display and filter on. Joins are expensive or non-existent.
- **Every index is served behind an alias**, never by its real name. The alias is what makes it possible to
  reindex and switch over with no downtime, and its absence is what turns a mapping change into
  a maintenance window.
- **Name indices with a version** (`productos_v7`) and treat the mapping as code versioned in the
  repository, reviewed in a PR.

### 3.2 Explicit mapping — dynamic mapping in production is a bomb

**Hard rule: explicit mapping and `dynamic: strict` (or your engine's equivalent) in production.**

What dynamic mapping does and why it blows up:

- **The type is decided by the first document that arrives.** A field that arrives as `"1"` is mapped to
  `text`; the next document with a numeric `1` may fail or become useless for ranges and
  sorting. **The error shows up months later, in some arbitrary document, and by then it cannot be
  fixed without reindexing.**
- **Field explosion**: an object with dynamic keys (IDs, user names, free-form
  attributes) generates a new field per key. The mapping grows without bound, the cluster state
  bloats and **the whole cluster degrades**. Use types designed for this (`flattened`, key/value
  pairs as *nested*) or normalise to `[{key, value}]`.
- **You index what you do not search**: fields nobody queries cost space, memory and indexing
  time. Declare `index: false` for what is only displayed, and do not store the complete
  original document if you already have it in the source of truth.

### 3.3 `keyword` versus `text` — the most frequent modelling mistake

- **`text` is analyzed**: it is split, normalised, and serves to **search**. It does **not** serve to group,
  sort or facet reliably.
- **`keyword` is not analyzed**: it is the exact value. It serves to **filter, facet, aggregate and
  sort**. It does not serve to search inside.
- **Almost always you want both**: the field as `text` and a `keyword` subfield. Modelling this wrong is
  the number one cause of "the facets come out shredded" and of "I cannot sort by name".
- **Identifiers, SKUs, codes, enums, statuses, emails, paths and tags are `keyword`**, not
  `text`. Analyzing them breaks the exact search that is precisely what you want from them.

### 3.4 Analyzers, tokenization and stemming — and Spanish

An analyzer is **tokenizer + filters**, and **the indexing one and the query one must be
coherent**. A mismatch here does not raise an error: it gives zero results for obviously correct queries.

Criteria for Spanish (and applicable to any inflected language):

- **One analyzer per language, not one for everything.** A multilingual field with an English analyzer
  destroys retrieval in Spanish without emitting a single warning. If the corpus is multilingual:
  **a subfield per language** (`titulo.es`, `titulo.en`) and language detection at ingestion.
- **Stemming**: the Snowball *stemmers* for Spanish are **aggressive** and over-stem (distinct roots
  collapse into the same one), which introduces noise. The light variant (*light Spanish*) usually gives
  better precision on catalogues and proper nouns. **Choose by measuring (§4.2), not by default.**
- **Accents**: `asciifolding` (or `unaccent`) is nearly mandatory —the user types "arbol"— but
  **it destroys real distinctions**: `año`/`ano`, `papa`/`papá`, `esta`/`está`. **Correct pattern: a
  folded field to retrieve and an unfolded field with more weight to break ties**, so that the
  correct accented form wins in the ranking while still finding the unaccented one.
- **Stopwords**: the standard Spanish list removes `no` and `sin`. In a corpus where negation
  matters (clinical, legal, technical specifications) **that inverts the meaning of the query**.
  Review the list; often the right thing is not to use it.
- **`ñ`, diaeresis, uppercase, hyphens and apostrophes**: explicit and tested normalisation, not
  inherited from a blog example.
- **Careful with the tokenization of references**: SKUs, registration numbers, versions (`v1.2.3`) and codes with
  hyphens are split into useless pieces by the standard tokenizer. Model them as `keyword` (§3.3)
  or with a custom tokenizer.
- **Numbers, dates and units**: normalise at ingestion, not at query time.

**Changing an analyzer requires reindexing.** It is not a hot adjustment: it is the operation of §3.5.

### 3.5 Reindexing is the normal operation

The standard procedure, which must be automated and rehearsed **before** you need it:

```
1. create   productos_v8  with the new mapping
2. populate productos_v8  (reindex from v7, or from the source of truth — preferable)
3. dual write to v7 and v8 while the process lasts
4. compare: document count, and relevance over the judgment set (§4.2)
5. switch the 'productos' alias from v7 to v8 (atomic)
6. leave v7 available N days for rollback; delete afterwards
```

- **Reindexing from the source of truth is better than reindexing from the old index**: the old
  index may have lost information that the previous analyzer discarded.
- **Time the full reindex.** It is your real RTO and the limit on how many mapping changes
  you can afford per quarter.
- **A mapping change without an alias and without a reindex plan is a scheduled incident.**

## 4. Relevance and gates

### 4.1 Relevance tuning

- **BM25 is the default ranking of every serious engine**, and its parameters (term frequency
  saturation and document length normalisation) **are rarely the problem**:
  before touching them, review analyzers, fields and weights. Touching BM25 first is optimising the last
  link.
- **Field boosting** (title weighs more than body) is the most effective lever and the first one to
  try. **It is tuned by measuring, not by arguing in a meeting.**
- **Business signals** (popularity, recency, stock, margin) are combined with textual relevance
  explicitly and documented. **Keep them separate from the textual ranking**: mixing them until nobody
  knows why what comes out comes out is how search engines die.
- **Synonyms**: manage them as versioned data, not as loose configuration. **Apply them at
  query time, not at indexing time**, whenever you can: that way changing them does not force a reindex. Careful with
  multi-word ones and with synonyms that broaden too much and ruin precision.
- **Hybrid search (lexical + vector)**: the lexical part belongs to this skill, the vector part to
  `vector-db-standards`, and **the fusion criteria to `rag-standards`** when the destination is an LLM.
  If your engine implements the fusion natively, use it instead of fusing in the application. **Do not
  adopt it without measuring: for many catalogues, well-analyzed lexical beats badly-measured hybrid.**

### 4.2 How relevance is really evaluated

**"It works for me" is not a measurement.** It is the bias of someone who knows the corpus querying what
they already know is there.

- **Judgment list**: real user queries labelled with which
  documents are relevant and to what degree. **50-200 queries minimum, versioned in the
  repository, reviewed in a PR like any other code.** It is the most valuable asset of the system:
  it survives changes of engine, of mapping and of team.
- **Get them out of the search logs**: the most frequent queries, and above all **the ones that return zero
  results** and **those in which the user clicks on nothing**. That is your entire relevance backlog,
  free.
- **Mandatory edge coverage**: typos, synonyms, singular/plural, with and without accents,
  exact identifiers and SKUs, single-letter queries, extremely long queries, every language in the
  corpus, and **queries whose correct answer is "there is nothing"**.
- **Offline metrics** over that list, and **online** ones afterwards (zero-result rate, clicks in the
  top positions, abandonment, reformulation). **The offline metric tells you whether you broke something; the
  online one, whether you improved.** The machinery of retrieval metrics and their interpretation is in
  `rag-standards` §4.1.
- **No relevance change ships without an A/B comparison against the current configuration.** A tweak
  that improves three queries and worsens thirty is the default result of tuning by eye.

### 4.3 Gates that break the build

| # | Gate | Breaks if |
|---|---|---|
| 1 | Explicit versioned mapping; **`dynamic: strict`** in production | There is permissive dynamic mapping |
| 2 | Every index is served **behind an alias** | The index is queried by its real name |
| 3 | Indexing and query analyzers **coherent**, with a test that verifies it on real cases | They diverge |
| 4 | **Relevance evaluation over the judgment list with a non-regression threshold** if the diff touches mapping, analyzers, synonyms or weights | Regression |
| 5 | Language edge-case test (accents, plurals, typos, SKUs) | Fails |
| 6 | **Full reindex rehearsed and timed** at least once per quarter | Not rehearsed |
| 7 | **Snapshot restored in a clean environment and queried**, with the time recorded | It does not restore |
| 8 | **Anonymous request to the endpoint returns `401`/`403`**, and the transport is TLS | It returns `200` |
| 9 | **Isolation between tenants/roles**: a user does not retrieve documents that are not theirs | Leak. **Non-negotiable** |
| 10 | No application query uses a leading wildcard or deep `from`/`offset` pagination (§6.3) | One appears |
| 11 | Number of shards per index justified against the real size (§6.1) | Dwarf or giant shards |
| 12 | **Licence review of the engine and its plugins** recorded and current (§2.2) | Expired |
| 13 | CVEs and EOL of the engine (§5.3) | Critical unmitigated |

## 5. Security

### 5.1 Authentication and TLS: historically disabled, and the result is well known

**Search engines exposed to the Internet are a chronic source of data leaks**, with more than a
decade of documented incidents. The pattern is always the same: an index with real data,
reachable, without authentication, found by mass scanning.

Status verified (Aug 2026):

| Engine | Default state | Note |
|---|---|---|
| **Elasticsearch** | Security **auto-configured since 8.0**, verbatim from the docs: *"Elasticsearch automatically enables security features on first startup when the node is not part of an existing cluster and none of the incompatible settings have been explicitly configured"* | **Read it carefully: there are cases in which the automatic configuration is skipped.** Verify it, do not assume it |
| **OpenSearch** | Security plugin with **demo configuration installed automatically**, including **demo certificates**; since 2.12 it requires `OPENSEARCH_INITIAL_ADMIN_PASSWORD` | There is auth, but **with demo certificates that have to be replaced**. A production cluster with the demo certificates is not protected |
| **Apache Solr** | **No authentication by default** and listening on all interfaces. Security is enabled with `security.json`; **if `blockUnknown` does not appear, it is `false`, which is equivalent to not requiring authentication** | The most dangerous case on the list. Solr has accumulated exposure and RCE incidents |
| **Meilisearch / Typesense / Manticore** | They require an explicitly configured key; without it the instance is left open | Meilisearch **does not start protected if you do not pass it `--master-key`/`MEILI_MASTER_KEY`** |

**Rules**:

- **No search engine is exposed to the Internet.** Private network, default-deny firewall
  (`firewall-policy-standards`). If a client needs to search, **it talks to your API, not to the
  engine** (§5.2).
- **Authentication and TLS mandatory in every network-reachable environment**, including the transport
  between nodes and the administration dashboard. Gate 8 of §4.3.
- **Replace the demo certificates** before the cluster holds a single real document.
- Authorization by role/index/field, with least privilege: the application that queries **does not
  need cluster management permissions**. Identity and federation:
  `identity-access-management-standards`; the key, in a secrets manager.

### 5.2 Do not expose the query DSL

Letting the client send an arbitrary query to the engine is equivalent to letting them run SQL: they can
read indices and fields that are not theirs, and they can bring down the cluster with a deep aggregation or
a leading wildcard (§6.3). **Your API exposes bounded parameters and builds the query on the server**
(`api-design-standards`). Every user input is escaped according to the engine's syntax; a query
built by concatenating user text is injection.

### 5.3 Attack surface and patching

- The engine enters the patching cycle like any other piece. Precedents verified in 2026:
  **CVE-2026-63140** (reachable assertion: an **authenticated low-privilege user** brings down the
  node with a crafted query; on a cluster, one request per node) and **CVE-2026-63144** (uncontrolled
  recursion), **both fixed in Elasticsearch 8.19.19, 9.3.8 and 9.4.4** (Jul 2026), together with
  resource exhaustion via ES|QL.
- **Lesson from those CVEs**: *"only authenticated users"* is not a mitigation when the minimum read
  permission is enough. **Reduce who has search permission and limit query complexity.**
- Plugins and extensions: extra surface and a brake on upgrades. Every plugin needs justification
  and a licence review.
- SBOM, images by digest, and tracking the EOL of the major version
  (`vulnerability-management-standards`).

### 5.4 Personal data in the index

- **The index is a copy of the data**: it goes into the inventory, the classification, the retention and
  the right to erasure (`privacy-engineering-standards`).
- **Deletion must propagate** to the index, to the replicas, to the snapshots in force according to their policy
  and to the caches. A document deleted at the source that remains indexed keeps being returned.
- **Snapshots contain the data**: their retention and their encryption are part of the erasure plan.
- **Filter by permissions in the query to the engine, not after receiving the results.** Filtering
  afterwards breaks the top-k and any path that forgets the filter is a leak (criteria shared with
  `rag-standards` §5.1).
- **Search logs are personal data**: they contain what people type. Bounded retention.

## 6. Operation and performance

### 6.1 Shards and replicas — the classic mistake

**The classic mistake is having too many small shards.** Each shard is a complete inverted index
with its fixed cost in memory, files, threads and metadata in the cluster state. A cluster with
thousands of dwarf shards runs slow, starts up slowly and falls over from memory pressure on the master node
— **without any particular query looking expensive**.

- **Fewer and larger shards** is the correct bias. The query fans out to all shards and
  the p99 is set by the slowest: more shards does **not** mean faster.
- **The number of primary shards of an index is fixed at creation.** Changing it requires reindexing (§3.5)
  or split/shrink. Think about it at design time.
- **Replicas**: availability and read capacity. Each replica is a full copy: it costs
  disk and memory. **Zero replicas in production is guaranteed data loss** on a node
  failure.
- **Time-based indices** (logs, events) instead of one giant index: they make deletion by
  retention cheap (deleting an index is instantaneous; deleting by query is extremely expensive) and enable the
  lifecycle of §6.2. With *rollover* by size or age, not by intuition.
- **The target shard size is measured on your hardware with your documents.** The figures that circulate
  are heuristics from the documentation of a specific engine, in a specific version.
- **Separate node roles** in any cluster that matters: dedicated masters (odd number, without
  data load), data nodes, coordinating/ingest nodes. A master that also serves
  queries falls over when the peak arrives.

### 6.2 Lifecycle, snapshots and upgrades

- **Lifecycle by temperature** (hot / warm / cold / frozen) for data with a temporal pattern:
  expensive hardware only for the recent. **Automated by policy, not by artisanal cron.**
  The specific case of logs belongs to `observability-standards`.
- **Incremental snapshots to an object storage repository**, versioned, encrypted and with immutability
  (`object-storage-standards`, `backup-recovery-standards`). **A snapshot without a tested and
  timed restore does not exist** (gate 7).
- **Snapshot compatibility across major versions is limited**: a snapshot does not always restore
  on the version you have today. Record the version with the snapshot.
- **Major version upgrades**: the hard point of the domain. They usually support reading indices from
  the previous major, **but not from two back**. Consequence: **an old index forces a reindex before
  you can jump versions**, and if you never reindex you accumulate debt until an upgrade becomes a
  project. **Reindexing periodically is not optional hygiene: it is what keeps the cluster
  upgradable.**
- Rehearse the upgrade in an environment with representative data, with a defined rollback, and **never jump to
  a `.0` in production** (criteria inherited from `data-platform-standards`).

### 6.3 Expensive queries — the ones to forbid

| Pattern | Why it is expensive | Alternative |
|---|---|---|
| **Leading wildcard** (`*texto`) | Forces a scan of the entire term dictionary | Inverted index of suffixes, n-grams at indexing time, or a normalised `keyword` field |
| **Deep pagination with a large `from`/`offset`** | Each shard must sort and return `from+size` results, and the coordinator merge them: a cost that grows with depth, and **it can bring the node down** | **`search_after`** (cursor over the sort key) for navigation; *scroll*/PIT or *point-in-time* for bulk export. **Deep pagination is almost always a badly-framed product requirement**: nobody goes to page 400 |
| **Deep, high-cardinality aggregations** | Memory proportional to the number of *buckets*; grouping by an almost-unique field blows up the node | Limit cardinality, precompute, or move the question to the analytical store |
| **Sorting or aggregating on a `text` field** | Requires data structures that are built in memory and are enormous | `keyword` subfield (§3.3) |
| **Queries with a `script` on the hot path** | They run per document | Precompute at ingestion |
| **Queries without timeout or limit** | A single one can degrade the cluster for everybody | Timeouts, limits, *circuit breakers* and workload isolation |

**Cache**: engines cache at several levels (query, filter, request, and the operating system's
*page cache*, which is usually the most important). Consequences: **leave RAM free for the operating
system instead of giving it all to the JVM**, and **queries with precise timestamps —`now`, right
now— do not cache**: round the time windows and the hit ratio changes radically.

### 6.4 Freshness, observability and runbook

- **The index lags behind the source of truth**, and that lag is a product
  requirement: measure it, give it an SLO if the business depends on it, and **alert when the indexing
  pipeline stops** — the characteristic silent failure is a search engine returning results
  that are perfectly plausible but three days old.
- Instrument (transport and backend: `observability-standards`): cluster health and unassigned
  shards, p95/p99 search latency **by query type**, indexing lag, memory pressure
  and GC pauses, disk usage (**a node that crosses the space threshold goes read-only and writes
  die silently**), rejections from a full queue, **zero-result query rate**
  (a product metric, not an infrastructure one) and slow queries.
- Minimum runbook: unassigned shards after a restart; full disk and cluster read-only; indexing
  pipeline stopped; a query that degrades the cluster; unstable master node; half-finished reindex
  with the alias on the wrong index; a snapshot that does not restore on the current version; a search engine
  discovered exposed without authentication (**security incident**:
  `incident-response-forensics-standards`).

## 7. Sustainability and prohibitions

**Review cadence: 3 months** (the licence and the CVEs set the pace; the rest moves more slowly).

- Review: **the engine's licence and that of its plugins**, version and EOL of the major, CVEs, and whether the
  judgment list still represents real search traffic.
- **The judgment list and the versioned mapping are the assets that outlive the engine.** If tomorrow
  you migrate from Elasticsearch to OpenSearch, they are the only thing that is preserved.
- Conscious debt recorded: dynamic mapping pending closure, reindex never rehearsed,
  relevance unmeasured, demo certificates still in use.

**FORBIDDEN**

- ❌ Deploying a search cluster without having checked that PostgreSQL full-text did not reach,
  and without an ADR with the operational cost accepted.
- ❌ **Choosing an engine without reading its licence file**, or assuming the licence it had the last time.
- ❌ Assuming that an Elasticsearch binary reaches you under AGPLv3 without checking the artifact (§2.2).
- ❌ Using Meilisearch Enterprise modules in production without a commercial contract (BSL 1.1).
- ❌ **Permissive dynamic mapping in production.** No free-key object without bounds.
- ❌ Modelling identifiers, SKUs, codes, enums or emails as `text`.
- ❌ Sorting, faceting or aggregating on a `text` field.
- ❌ Querying an index by its real name instead of by an alias.
- ❌ A single analyzer for a multilingual corpus.
- ❌ Applying `asciifolding` without an unfolded field to break ties, or using the standard Spanish
  stopword list in a corpus where negation matters.
- ❌ Divergence between the indexing and the query analyzer.
- ❌ Changing mapping, analyzers or synonyms **without a relevance evaluation** against the judgment list.
- ❌ **"It works for me" as relevance validation.** Without a judgment list there is no measurement.
- ❌ Touching the BM25 parameters before reviewing analyzers, fields and weights.
- ❌ Applying synonyms at indexing time when they could have been applied at query time.
- ❌ **Treating the search engine as the source of truth**, or not being able to rebuild it from the source.
- ❌ Thousands of small shards; or zero replicas in production.
- ❌ A single giant index for data with a temporal pattern instead of time-based indices with retention.
- ❌ A snapshot without a tested and timed restore; a major version upgrade without a rehearsal or rollback;
  jumping to a `.0` in production.
- ❌ Accumulating indices without reindexing until the major version upgrade becomes impossible.
- ❌ **Exposing the engine to the Internet**, or **exposing its query DSL to clients**.
- ❌ Starting without authentication or TLS in any network-reachable environment; leaving the
  demo certificates or passwords.
- ❌ Filtering permissions after receiving the results instead of in the query to the engine.
- ❌ A leading wildcard, deep `from`/`offset`, high-cardinality aggregations without a limit, or
  queries without a timeout, on the hot path.
- ❌ Using this skill to decide the log backend (that belongs to `observability-standards`) or to write
  SIEM rules (that belongs to `detection-engineering-standards`).
- ❌ Duplicating here the hybrid fusion criteria of `rag-standards` or the vector index operation
  criteria of `vector-db-standards`.
- ❌ Pinning a version, a licence, a shard size or a performance figure from memory (§8).

## 8. Mandatory web verification

1. **Licence of each engine** — the datum that decides, and the one that has changed the most. Verified as of Aug 2026
   by reading the repositories' `LICENSE` files (not summaries from HTML pages, which **invent
   dates and go as far as inverting the meaning of a sentence**): Elasticsearch **triple AGPLv3-only / SSPL
   v1 / Elastic License 2.0**; OpenSearch **Apache-2.0**; Meilisearch **`MIT AND BUSL-1.1`** with
   the Enterprise Edition under BSL; Typesense **GPL-3.0**; Manticore **GPL-3.0**; Vespa, Solr and Quickwit
   **Apache-2.0**. **Re-verify every quarter.**
2. **Versions**, via release Atom feeds: Elasticsearch **9.4.4** (Jul 2026), OpenSearch **3.7.0**
   (Jun 2026) and **2.19.6**, Meilisearch **1.52.0** (Aug 2026), Typesense **30.2** (Apr 2026, `v31`
   branch active), Manticore **28.6.6** (Jul 2026), Vespa **8.731.x**, Solr **10.0.0** (Mar 2026),
   Quickwit **0.9.0** (Jul 2026).
3. **OpenSearch governance**: **OpenSearch Software Foundation**, a **Linux
   Foundation** project, ownership transferred from Amazon, announced on **16-Sep-2024**. Confirm it has not
   changed.
4. **Project status**: Quickwit **acquired by Datadog (Jan 2025)**, relicensed to Apache-2.0 and
   **with activity confirmed as of Aug 2026**. Check whether any other has been acquired or abandoned.
5. **CVEs and EOL**: Elasticsearch **CVE-2026-63140** and **CVE-2026-63144** fixed in 8.19.19 / 9.3.8
   / 9.4.4 (Jul 2026). Consult the bulletins of the engine and of its plugins before pinning a version.
6. **Default authentication** of the specific version you deploy (§5.1). Verified verbatim in
   official documentation for Elasticsearch, OpenSearch and Solr.
7. **Snapshot and index compatibility across major versions** before planning an
   upgrade.
8. **Spanish analyzers available** in your engine's version and their behaviour — the
   names and the default behaviour change between major versions.
9. **Equivalent managed services** and their licensing and pricing model (`aws-standards`,
   `azure-standards`, `gcp-standards`).

**Declared gaps — do NOT fill from memory**:

- **Effective licence of the Elasticsearch binary distributions**: **the most important gap in
  this document.** The repository is triple, but there are consistent reports that the downloadable
  artifacts and the official images are shipped under **Elastic License 2.0**. **Not verified
  conclusively in this review.** If your decision depends on being able to use AGPLv3, check the
  licence file of the specific artifact before committing.
- **Which specific Meilisearch modules fall under BSL 1.1**: the `LICENSE` refers to the files
  marked as Enterprise Edition under `enterprise_editions`. **The exact list is not pinned here**:
  audit it in the version you deploy.
- **Target shard sizes, number of shards and memory thresholds**: **deliberately not
  pinned.** They depend on the hardware, the document size and the query pattern; any specific
  figure is the heuristic of another engine's documentation in another version. They are measured.
- **BM25 parameters and boosting weights**: not pinned. They are determined with the judgment list (§4.2).
- **Comparative benchmarks between engines**: not pinned. The public ones are almost always from vendors.
- **Default auth status of Vespa and Quickwit**: not verified in this review. Confirm it in their
  documentation before deploying.
- **Status and maturity of the BM25 extensions for PostgreSQL** (ParadeDB / `pg_search`): mentioned
  as an option, **not verified** in version or licence in this review.

If the web contradicts this document, **the web wins** — flag the discrepancy.
