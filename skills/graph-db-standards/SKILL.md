---
name: graph-db-standards
description: Use when a graph engine or a graph query is on the table — proving the traversal is variable-depth before adding an engine (friend-of-a-friend, shortest path, cycle detection, propagation) instead of a two-hop JOIN or a recursive CTE, Neo4j (cypher-shell, neo4j.conf, Bolt, 5.26 LTS versus CalVer releases, Community versus Enterprise, GDS algorithms), Memgraph, MemGQL, FalkorDB, ArangoDB, JanusGraph, TigerGraph GSQL, Amazon Neptune or Neptune Analytics, Apache AGE and SQL/PGQ GRAPH_TABLE on Postgres, DuckPGQ, writing Cypher or openCypher MATCH patterns and reading their PROFILE/EXPLAIN plan, GQL as ISO/IEC 39075 and how little of it is really implemented, Gremlin and TinkerPop traversals, RDF triplestores with SPARQL, OWL ontologies, Fuseki, GraphDB or Virtuoso, deciding what is a node versus a relationship, supernodes and dense relationships, anchoring a traversal on a starting index, graph partitioning and single-machine limits, or knowledge graphs built to feed an LLM.
---

# Graph database standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **deciding on, modelling, querying and operating** a graph store: property
graph (Neo4j, Memgraph, FalkorDB, ArangoDB, JanusGraph, TigerGraph, Neptune) and
RDF/triplestore (Jena/Fuseki, GraphDB, Virtuoso, Neptune in SPARQL mode). It covers the
prior justification against SQL, query languages and their real portability, the
modelling (node vs relationship, supernodes, temporality), performance (query
anchoring, execution plan), scale limits, operation, licences and the
alternatives on PostgreSQL before adopting anything.

Triggers: "graph", "graph database", "Cypher", "openCypher", "GQL", "Gremlin", "SPARQL",
"Neo4j", "Memgraph", "Neptune", "JanusGraph", "TigerGraph", "ArangoDB", "Apache AGE",
"SQL/PGQ", "shortest path", "friends of friends", "traversal", "traversal", "supernode",
"ontology", "RDF", "triple", "knowledge graph".

**Not applicable**: see `data-platform-standards` (**mother skill**: PostgreSQL as the default,
relational modelling, indexes, replicas, PITR, backups, data classification; and the
principle "one store because it is needed, not because it is fashionable", which applies here with
particular severity),
`nosql-standards` (document, key-value and wide-column: MongoDB, DynamoDB,
Cassandra/ScyllaDB; **the graph is a different data model, not one more family of
NoSQL** — the grouping is historical and commercial, not technical: there you model by access
pattern and give up the JOIN, here the traversal *is* the access pattern),
`rag-standards` (**GraphRAG and retrieval for AI are hers**: chunking, embeddings,
hybrid retrieval, reranking, recall evaluation; here only the engine and the modelling of the
graph that may eventually feed that retrieval), `llm-app-engineering-standards` and
`mlops-standards`, `microservices-architecture-standards` (per-service data ownership:
a graph that crosses the domains of several services is a sign of badly cut boundaries),
`privacy-engineering-standards` (a graph of relationships between people is a high-risk
processing operation: DPIA, minimisation and data subject rights are hers),
`identity-access-management-standards` (ReBAC with OpenFGA/SpiceDB/Zanzibar: **they are
authorisation engines, not graph databases** — not resolved here),
`observability-standards`, `sre-practice-standards`, `backup-recovery-standards`,
`bcdr-standards`, `kubernetes-standards`, `linux-storage-standards`, `iac-standards`,
`cicd-standards`, `secrets-management-standards`, `cryptography-pki-standards`,
`grc-compliance-standards`, `vulnerability-management-standards`,
`aws-standards`/`azure-standards`/`gcp-standards` (Neptune, Cosmos DB Gremlin API, Spanner
Graph as managed services: quotas, IAM and the bill are theirs; **the modelling and query
criteria are ours**), the language skills (Bolt/Gremlin drivers and OGM),
`vector-db-standards` (**vector search and operating an ANN index: hers**, even though
graph engines have added vector indexes), `data-engineering-standards` (the
pipelines that load the graph), `data-warehouse-modeling-standards` (analytical modelling).
Also: `search-engines-standards` (relevance
search), `timeseries-db-standards`, `lakehouse-standards`
(analytics), `streaming-cdc-standards`, `data-governance-quality-standards`,
`analytics-bi-standards`, `caching-cdn-standards`, `message-brokers-standards`,
`oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`.

### Governing principle: the graph is justified by the **shape of the query**, never by that of the data

"My data is connected" is not an argument: **all** relational data is;
that is what the foreign key is for. The graph wins when the **query** has this shape:

- **Variable or unknown depth**: "everything that reaches X in 1..n hops", "is there a
  path between A and B?", cycle detection (fraud, circular dependencies), transitive
  closure (ownership hierarchies, bills of materials, inherited permissions).
- **Paths as the result**: shortest path, k paths, path with constraints on
  the types of relationship traversed — not just the endpoints, but **the path itself**.
- **Propagation and influence** over the topology: centrality, communities, PageRank,
  structural similarity.
- **Highly irregular topology** where the number of hops depends on the data, not on the schema,
  and the relational plan turns into a staircase of recursive self-JOINs whose cost
  explodes.

**And when NOT — this is the dominant mistake of the domain and it has to be said bluntly**: if
your queries are **one or two fixed hops** ("a customer's orders", "a user's
followers", "an article's tags"), a `JOIN` is simpler, faster, cheaper and
**does not add an engine to operations**. A `JOIN` over indexes in
PostgreSQL beats any graph on that ground, and on top of that it keeps transactions,
aggregations, ad-hoc reporting and an ecosystem of tools the graph does not have.
Adopting a graph engine costs: a licence to review (§2.1), a language that almost
nobody on the team knows, a model that does not fit the ORM, a copy of the data that has to be
synchronised from the system of record, and one more component on call.

Before adopting, **exhaust the alternatives in §2.2** (recursive CTE, `Apache AGE`, SQL/PGQ)
and write in an ADR: the specific query that cannot be resolved that way, its real volume, its
latency budget and the measurement proving the relational route does not get there. Without that
paragraph, the answer is no.

## 2. Default decisions

> Verify version, EOL, CVEs and **current licence** on the web before committing to anything (§8).
> The data is from August 2026 and this ecosystem changes licence frequently.

| Need | Default | Justifiable alternative |
|---|---|---|
| 1-2 hop traversals, small hierarchies | **PostgreSQL** with `JOIN` or `WITH RECURSIVE` | — |
| Property graph as a secondary feature of a system already on PostgreSQL | **Apache AGE** (extension, Apache-2.0) | A dedicated engine if measurement demands it |
| Property graph as the central use case, self-managed | **Neo4j** (the most mature ecosystem, documentation and job market) — accepting the limits of its Community Edition (§2.1) | Memgraph if the profile is *streaming*/in-memory; FalkorDB if latency dominates in GraphRAG-type workloads |
| Managed graph on AWS | **Amazon Neptune** (openCypher + Gremlin + SPARQL over the same data) | — |
| Semantics, shared vocabularies, federation and inference | **RDF/triplestore**: Apache Jena/Fuseki (Apache-2.0) | Commercial GraphDB/Virtuoso/Stardog; Neptune in SPARQL mode |
| One-off graph analytics over data that already lives in the analytical store | Export and use a library (NetworkX, igraph, GraphFrames) or **DuckPGQ** | A dedicated engine only if the analytics is continuous |

Verified status (August 2026):

| Component | Status | Note that changes decisions |
|---|---|---|
| Neo4j | Monthly CalVer since 2025 (most recent verified tag: **2026.06.0**) and the **5.26 LTS** branch alive (5.26.28) | The CalVer series requires **Java 21**; 5.26 LTS accepts 17 or 21. 5.26 is a mandatory *checkpoint* when coming from 4.4/5.x |
| Memgraph | **3.12.0** (Jul 2026) | It publishes **MemGQL**, a federated **GQL** query engine that translates to backends (Memgraph, Neo4j, and relational ones: PostgreSQL, DuckDB, Iceberg) via Bolt |
| ArangoDB | 3.12.9.x | **BUSL-1.1** since 3.12 (§2.1) |
| JanusGraph | **1.1.0** (Nov 2024) as the last official release; development alive with *per-commit releases* towards 1.2.0, with no date | Slow cadence: evaluate it with eyes open. Only the CQL backend (Cassandra/ScyllaDB) |
| Apache TinkerPop / Gremlin | **3.8.1** stable; **4.0.0-beta.3** (Jul 2026) | Gremlin 4 still in beta: do not commit to it in production |
| Apache AGE | Releases per PostgreSQL branch (1.7.x for PG17/PG18; 1.8.0-rc for PG18/**PG19**); the Jan 2026 release added RLS and an index on id columns | **Active ASF top-level project**, Apache-2.0, present in Azure Database for PostgreSQL. The version is tied to the PG major: verify before planning a PG upgrade |
| Apache Jena / Fuseki | The **6.x** line (artifact 6.1.0 on Maven Central) | Jena 6 requires **Java 21+** |
| Blazegraph | No releases since 2.1.5 (2019) | **Frozen**: do not adopt. Neptune is its commercial successor |

### 2.1 Licences — verify before choosing

| Engine | Verified licence | What it implies |
|---|---|---|
| **Neo4j** | Community Edition free (historically GPLv3 — confirm on the current licensing page); Enterprise under Neo4j's commercial licence | **The CE has no clustering, no RBAC/fine-grained access control, no hot backups, and is limited to a single user database.** That is: no HA and no role-based authorisation. Any production with availability or multi-tenancy requirements ⇒ Enterprise or Aura. Budget it **before** choosing Neo4j |
| **Neo4j GDS** (algorithms) | Community edition by default; Enterprise with a licence file. The open part is assembled as **OpenGDS** under GPLv3 | GDS Community includes all the algorithms but limits **concurrency to 4 cores** and the model catalogue to 3, and does not support GDS writes in a cluster. A large graph computation with 4 threads is not a production option |
| **Memgraph** | Community Edition under **BSL 1.1** (converts to Apache-2.0 after 4 years); Enterprise under a proprietary licence (MEL) | HA, advanced authentication and multi-tenancy are Enterprise; the licence applies **by data volume**: on reaching the limit, **writes are blocked** (read and delete only). Size it beforehand |
| **ArangoDB** | Code under **BUSL-1.1** since 3.12 (previously Apache-2.0); CE binaries under the *ArangoDB Community License* | A **100 GiB** cap in production and internal use only; forbidden to offer it as a service or redistribute it with your product without a commercial agreement |
| **FalkorDB** | **SSPLv1** | Internal use with no obligation; offering it as a service to third parties requires publishing the complete service under SSPL or buying a licence |
| **JanusGraph** | Apache-2.0 | No restrictions; the cost is in also operating Cassandra/Scylla + an external index |
| **Apache AGE**, **Apache Jena/Fuseki**, **openCypher (spec)** | Apache-2.0 | No restrictions |
| **TigerGraph / GSQL** | **Proprietary** product and language (ecosystem libraries, such as `gsql-graph-algorithms`, are Apache-2.0) | Language lock-in: GSQL does not exist outside TigerGraph |
| **Neptune / Cosmos DB / Spanner Graph** | Proprietary managed service | The "licence" is the contract and the cost of leaving |

**FORBIDDEN** to state any of these licences from memory: the current official page is read
(§8). ArangoDB, Memgraph and FalkorDB are not open source, even though their marketing
suggests it.

### 2.2 Alternatives on PostgreSQL before adopting an engine

- **`WITH RECURSIVE`**: it solves hierarchies, transitive closure and paths of moderate
  depth. Rules to keep it manageable: an index on the link column,
  an **explicit depth cut-off** (`WHERE depth < n`), and **cycle detection**
  (`CYCLE ... SET ... USING ...` in PostgreSQL, or a visited array). It performs well until
  the fan-out per level explodes; that is where you measure and decide, not before.
- **Apache AGE**: an ASF extension that gives Cypher (a subset) inside PostgreSQL, with the
  transactions and the backing of the engine you already operate. It is the first option when the
  graph is a **part** of the system and not the system. Cost: lower performance than a native
  engine in deep traversals, partial Cypher coverage, and its version is tied to the
  PostgreSQL major.
- **SQL/PGQ** (part 16 of SQL:2023, `GRAPH_TABLE`, graph views over existing
  tables): verified real status — **Oracle Database 23ai** is the mature commercial
  implementation; **PostgreSQL has it in development targeting PG 19** (do not take
  its arrival for granted); **DuckDB** via the community extension **DuckPGQ**, useful but with
  the risk of a research project. Keep an eye on it: if it reaches PostgreSQL, it changes the
  adoption equation for many cases.
- **Precompute**: if the traversal always starts from the same nodes and changes little, a
  materialised reachability table (recomputed by batch or by event) solves the
  problem with no new engine. It is the option almost nobody evaluates and the one that usually
  wins.

## 3. Query languages and portability

- **Cypher / openCypher**: the de facto dialect of the property graph. openCypher is still
  alive but **has redefined its mission as a ramp towards GQL**: the specification evolves
  by incorporating GQL features. The openCypher repository is Apache-2.0 and is declared
  to be maintained by Neo4j employees/contributors in a personal capacity, with no guarantees or
  support — it is not a standard with neutral governance.
- **GQL — ISO/IEC 39075**, published in **April 2024** by ISO/IEC JTC1/SC32/WG3 (the
  same group as SQL): the first new standardised query language in more than 35 years.
  What is interesting **is not the standard, it is its adoption**, and there one has to be honest:
  - **There is no independent conformance certification regime** (nothing analogous to
    the NIST validation of SQL in the 90s). Every conformance claim is
    **self-declared by the vendor**.
  - Neo4j publishes a GQL conformance appendix in its Cypher manual, versioned by
    release, and it includes a list of **mandatory GQL features not yet
    supported**. It is the most detailed public accounting that exists — and it admits gaps.
  - Memgraph approaches it another way: **MemGQL**, a federated GQL engine that translates to
    the backends' native languages.
  - Operational conclusion: **GQL is a direction, not a guarantee of portability today**.
    Do not plan a migration between engines on the basis of "both speak GQL".
- **Gremlin (Apache TinkerPop)**: imperative, portable between TinkerPop implementations
  (Neptune, JanusGraph, Cosmos DB). 3.8.1 stable, **4.0 still in beta**. It is the option when
  portability between TinkerPop engines weighs more than readability.
- **SPARQL / RDF**: another paradigm. Verified standards status: the **SPARQL 1.2**
  specifications are **still in Working Draft**; **RDF 1.2 Concepts and RDF 1.2 Semantics are in
  Candidate Recommendation** (April 2026), pending two independent implementations
  passing the test suite. In production today you work with **SPARQL 1.1**.
- **Cross-cutting reality: portability between engines is still poor.** Even if two
  engines accept "Cypher", they diverge in functions, procedures (`CALL`), indexes,
  types, path semantics and extensions. Design consequence: **isolate access to the
  graph behind a repository of your own** in the code, and treat queries as versioned and
  tested artifacts; changing engine will be a rewrite of queries
  with or without a standard.

## 4. Modelling and quality — gates

### 4.1 Modelling (where people get it most wrong)

- **What is a node and what is a relationship** is *the* decision of the domain. Working rule: it is
  a **node** if it can be the **origin or destination of a traversal** or if it needs
  attributes of its own, identity and its own relationships; it is a **relationship** if it is a
  directed and typed connection between two nodes. If a connection in turn needs to relate to
  something else (an order that connects customer and product but also has lines, payments and
  shipments), **it is a node**, not a relationship with properties: reifying it later means
  rewriting queries and migrating data.
- **Property versus node**: a descriptive value is a property; a value that is
  **filtered on or navigated from many nodes** (category, tag, country, status)
  becomes a node... and that is where the **supernode** is born. Decide with the query in hand.
- **Supernodes and dense relationships** are *the* performance problem of the graph: a node
  with millions of edges turns any traversal that crosses it into a scan.
  Mitigations: do not model as a node what is a low-cardinality attribute; type the
  relationships finely so you can filter by type before expanding; partition the
  supernode (by time, by region, by *bucket*); explicit direction in the traversal; and
  as a last resort, denormalise into the node whatever is needed to avoid the expansion.
  **Detecting them is a design and an operations task**: a periodic maximum-degree query.
- **Temporal modelling**: if the relationship has a validity period (employments, holdings,
  ownerships), decide explicitly between (a) `from`/`to` properties on the
  relationship —simple, forces filtering in every query—, (b) the relationship reified into a
  "state/version" node —a cleaner model, more nodes and more hops— or (c) snapshots per
  period. It is an ADR decision: changing it later is a full migration.
- **Direction and types**: relationships are created **once and with a direction**; the
  query can traverse them in both directions. Duplicating the edge in both directions
  doubles writes and creates inconsistencies.
- **The graph is almost never the system of record**: it is usually a projection of data that
  lives in the relational store. If that is so, the full rebuild of the graph from the source
  must be a tested and timed procedure — and then the graph's backup matters
  less than the system of record's.

### 4.2 CI gates

1. **Declared and versioned schema**: uniqueness and existence constraints, and the
   indexes, as migrations in the repository (never created by hand in production). In
   Neo4j, versioned `CREATE CONSTRAINT`/`CREATE INDEX`; in RDF, SHACL to validate
   shape. A graph without constraints accumulates duplicate nodes within weeks.
2. **Queries as artifacts**: every application query lives in the repository,
   with its integration test **against the real engine** (Testcontainers), over a synthetic
   graph with the topology that matters — including **cycles, isolated nodes and at least
   one supernode**. No driver mocks.
3. **Traversal budget**: every variable-depth query declares its bound
   (bounded `*1..n`, `LIMIT`, transaction timeout). A query with no bound is a review
   failure: in a graph, the difference between 3 and 4 hops can be three orders of
   magnitude.
4. **Execution plan reviewed**: `PROFILE`/`EXPLAIN` of the critical queries attached in
   the PR, with the `db hits` and the starting operator visible. **Hard gate**: no
   hot query may start with a label scan (`AllNodesScan`/`NodeByLabel
   Scan`) where it should use an index.
5. **Performance regression** with a graph of representative size and **shape**: the
   cost of a traversal depends on the real fan-out, not on the number of nodes. Measure p99.
6. **Tested restore** of the backup, timed, with the rebuild from the source
   as a verified alternative plan.

## 5. Performance: anchoring and plan

- **Every traversal starts at a point.** Without a **starting index** that locates the
  node or the small initial set, there is no fast graph: the engine scans the whole
  label and the subsequent traversal makes no difference. Rule: **every query identifies its anchor
  node and that anchor has an index** (or a uniqueness constraint, which implies one).
- **The execution plan matters more than in SQL**, and for a specific reason: in SQL a bad
  plan usually degrades linearly with the size of the table; in a graph, expanding from the
  wrong end makes the cost grow with the **product of the fan-outs** of each
  hop. The same query, anchored at the other end, can be instantaneous or eternal.
  Hence `PROFILE` is mandatory (§4.2) and it is worth fixing the direction of
  expansion when the cardinality of each side is known.
- Other levers: filter by **relationship type** before expanding; bound the depth;
  use the engine's shortest-path variant instead of expanding by hand; avoid
  chained `OPTIONAL MATCH`es that multiply rows; and project only what is needed.
- **Writes**: in batches and with short transactions; massive initial loads use
  the engine's bulk import tool, not a `MERGE` loop (which also
  needs an index to avoid scanning on every iteration).
- **Graph algorithms** (PageRank, communities, centrality) are not queries: they are
  analytical workloads run over a projection, with their window, their resources and their
  cadence; never in the path of a user request. And watch out for the concurrency
  limit of the Community edition (§2.1).

## 6. Scale and operation

- **Most graphs fit on one machine** — and that is the good news: scaling
  vertically (enough RAM for the hot graph to reside in memory, NVMe, CPU) is
  the correct strategy for far longer than people assume. Design for that
  before designing to spread out.
- **Partitioning a graph is a genuinely hard problem**, not a configuration
  checkbox: any cut leaves edges crossing partitions, and every crossed edge
  turns a local hop into a network call inside a traversal that may make
  many hops. That is why native engines scale reads with **replicas** and do not
  partition the graph by default, and those that do (JanusGraph over Cassandra,
  TigerGraph) shift the cost to the latency of the distributed traversal. If you think you
  need to partition, first verify that it does not fit on a big machine and that the
  problem is not a supernode (§4.1).
- **High availability**: replicas and failover are **paid for** in several engines (§2.1). If
  the architecture requires HA and the budget does not cover the Enterprise edition, the
  correct decision is not to build artisanal HA: it is not to use that engine, or to keep the graph
  as a projection rebuildable from the system of record and accept a rebuild RTO.
- **Backups**: in Community there is usually only a **cold** copy (with the service
  stopped, or inconsistent while hot): plan a window or a rebuild. An encrypted copy,
  off the host, with an immutable copy, and a **rehearsed and timed restore** (§4.2).
- **Upgrades**: read the full release notes and rehearse in staging. In Neo4j there are
  two trains —LTS (5.26) and monthly CalVer— with different Java requirements (21 in CalVer)
  and **5.26 as a mandatory *checkpoint*** to get there from earlier versions; the
  storage format may prevent rollback, so going back is planned
  as a restore or a parallel cluster.
- **Security**: never expose Bolt/HTTP/Gremlin/SPARQL to the Internet; change default
  credentials; TLS in transit and encryption at rest; and assume that **without RBAC (Community)
  access control is done entirely by the application**, which rules out multi-tenancy in
  the same graph. Recent verified CVEs in Neo4j: **CVE-2026-1497** (incorrect authorisation
  in Enterprise composite databases; fixed in 2026.02 / 5.26.22) and
  **CVE-2026-1622** (the query log's `obfuscate_literals` option does not redact
  error information; fixed in 5.26.21 / 2026.01.3). Subscribe to the vendor's
  advisories.
- **Query injection**: it exists just as in SQL. **Always parameters** (`$param`),
  never concatenation of user input in Cypher/Gremlin/SPARQL — which also destroys
  the plan cache. In SPARQL, additional care with `SERVICE` (federation) as an
  SSRF vector.
- **Observability**: p99 latency per named query, `db hits`/pages read,
  slow queries logged, resident graph memory versus total, maximum node
  degree (emerging supernodes), *store* size, and the projection's lag relative to the
  system of record. That last one is the metric that explains the most incidents.

## 7. Sustainability and prohibitions

- **Mandatory ADR** with: the specific query that justifies the graph, the measurement of the
  relational alternative, the model (what is a node and what a relationship, and why), the
  temporal strategy, the engine and **its licence and edition at the moment of deciding**.
- **Review the licence at every major upgrade**: ArangoDB (BUSL since 3.12) and Memgraph (BSL
  with a volume limit) are examples of changes that alter obligations without touching your
  code.
- **Exit route**: keep documented the rebuild of the graph from the system of
  record and avoid the graph accumulating data that exists nowhere else. A graph
  that has accidentally become the source of truth is the classic trap.
- **Knowledge graphs for AI (GraphRAG)** — the fashionable use case, and therefore the
  one that produces the most unjustified deployments. Retrieval, evaluation and the architecture
  decision belong to **`rag-standards`**; from here, three honest verified warnings:
  (a) the graph's **construction** cost is the dominant item and it is an LLM cost, not a
  database one —entity and relationship extraction over the whole corpus, plus community
  summarisation—, with public figures that were tens of thousands of dollars for medium-sized
  corpora in 2024 and that the lazy variants (LazyGraphRAG, HippoRAG) have reduced
  drastically; (b) there is a **query cost** in tokens and latency notably higher
  than that of vector retrieval, and an expensive reindexing when the corpus changes
  often; (c) a good share of the favourable *benchmarks* are published by graph database
  vendors. Criterion: **exhaust hybrid retrieval first (BM25 + dense with
  RRF fusion) and reranking**; the graph comes in when the problem is genuinely
  multi-hop or one of global aggregation over the corpus, and the extraction pipeline is treated
  as what it is —a data generator with hallucinations— with validation and correction.

**FORBIDDEN**
- ❌ Adopting a graph engine because "the data is connected" or because the domain
  draws nicely as a graph.
- ❌ Replacing with a graph queries of **one or two fixed hops**: that is a `JOIN`.
- ❌ Adopting it without having evaluated and measured `WITH RECURSIVE`, Apache AGE or
  precomputation.
- ❌ **Unbounded** depth traversals, or ones with no `LIMIT`/timeout in production.
- ❌ Hot queries without a **starting index**, or merged without a reviewed `PROFILE`.
- ❌ Modelling as a relationship something that needs relationships of its own (late reification).
- ❌ Turning a low-cardinality attribute into a node and manufacturing a supernode.
- ❌ Duplicating edges in both directions "so that queries are easier".
- ❌ Building queries by concatenating user input (Cypher, Gremlin or SPARQL).
- ❌ Exposing Bolt/Gremlin/SPARQL to the Internet, or leaving default credentials.
- ❌ Relying on the Community Edition for production with HA, RBAC,
  multi-tenancy or hot backup requirements (§2.1) — or discovering that limit after signing.
- ❌ Taking portability between engines for granted because they "speak Cypher" or "are GQL".
- ❌ Taking TinkerPop/Gremlin 4 to production while it remains in beta.
- ❌ Adopting Blazegraph or another engine with no recent releases.
- ❌ Running heavy graph algorithms in the path of a user request.
- ❌ Letting the graph become the system of record without deciding it.
- ❌ Building GraphRAG without having exhausted hybrid retrieval and without budgeting the cost
  of construction and reindexing.
- ❌ Stating versions, standards status or **licences** from memory, without the verification in §8.

## 8. Mandatory web verification

Before committing any datum from this document to a deliverable:

1. **Current licence and edition**: Neo4j's licensing page (and what exactly the Community
   Edition includes today), the GDS licence, Memgraph's BSL and its volume limit,
   ArangoDB's BUSL and the Community License cap, FalkorDB's SSPL. It is the datum that changes
   the most and the one that costs the most to get wrong.
2. **Versions and support**: Neo4j's current CalVer release and the EOL date of **5.26 LTS**;
   Memgraph; the state of **TinkerPop 4.0** (still in beta?); JanusGraph's official release
   (has 1.2.0 come out?); the Apache AGE branch for your PostgreSQL major; the Jena line.
3. **Real status of GQL (ISO/IEC 39075)**: whether a second edition or amendment has appeared,
   and **which engines really implement it** — Neo4j's conformance appendix (list of
   mandatory features not yet supported) and the state of MemGQL. Distrust every
   conformance claim: there is no independent certification.
4. **Status of SQL/PGQ in PostgreSQL** (has it landed in PG 19?): if it arrives, many
   dedicated-engine adoptions stop being justified.
5. **Standards status of RDF 1.2 / SPARQL 1.2** on the W3C page (in August 2026: RDF
   1.2 in Candidate Recommendation, SPARQL 1.2 in Working Draft).
6. **CVEs** of the engines to be recommended and their patch version; presence in CISA's KEV
   catalogue.
7. **Supply chain incidents** in drivers and libraries (Bolt, Gremlin, OGM): npm
   and PyPI are still under recurring worm campaigns in 2026; pin versions and hashes.

**Declared gaps** (not verified in the August 2026 session; **do not fill in from
memory**):
- **The exact licence of Neo4j Community Edition today** (historically GPLv3): it was not
  possible to read the official page —`neo4j.com/docs` returned 403— and the secondary sources did
  not quote it verbatim. **Verify before asserting it.**
- **The EOL date of Neo4j 5.26 LTS**: a secondary source indicated June 2028; not
  confirmed in an official source.
- **The verbatim text of Neo4j's GQL conformance appendix** and the specific list of
  mandatory features not supported: not accessible (403). What is asserted here comes
  from secondary sources.
- **TigerGraph**: current version, *free tier* limits (the 50 GB figure has circulated since
  2020) and the state of its openCypher support: not verified.
- **Amazon Neptune**: current engine version, Neptune Analytics and its quotas: not
  verified in this session.
- **CVEs of Memgraph, ArangoDB, JanusGraph, FalkorDB and Jena/Fuseki**: not reviewed.
- **The state of Wikidata/Wikibase with respect to Blazegraph** (migration in progress or not): not
  verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
