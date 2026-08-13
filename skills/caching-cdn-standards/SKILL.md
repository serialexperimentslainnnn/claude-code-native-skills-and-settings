---
name: caching-cdn-standards
description: Use when content is stored closer to the reader — Cache-Control directives, s-maxage, stale-while-revalidate and stale-if-error, CDN-Cache-Control (RFC 9213), Cache-Status (RFC 9211), Vary and its hit-rate cost, surrogate keys and purge-by-tag, cache key normalization, origin shield, edge functions, CloudFront/Cloudflare/Fastly/Akamai/bunny.net edge configuration and egress billing, maxmemory-policy with noeviction or allkeys-lru on a Valkey/Redis cache node, cache-aside and write-through designs, key naming and value-format versioning, thundering-herd stampede, penetration and avalanche mitigation, web cache poisoning and cache deception, or hit-ratio measurement per layer.
---

# Caching and content delivery (CDN) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when deciding **whether** to cache, **where** to cache and **who invalidates**: in-process
cache, distributed in-memory cache (Valkey/Redis used *as a cache*), HTTP response cache in the
reverse proxy, and CDN. Covers caching patterns, key design and invalidation, the classic failures
with names of their own, HTTP cache header semantics, edge configuration, cache-specific security
risks and their measurement.

Triggers: `Cache-Control`, `max-age`, `s-maxage`, `must-revalidate`, `private`/`no-store`,
`stale-while-revalidate`, `stale-if-error`, `CDN-Cache-Control`, `Surrogate-Control`,
`Surrogate-Key`/`Cache-Tag`, `Cache-Status`, `Age`, `Vary`, purging and `PURGE`, *origin shield*,
cache key and query string normalisation, *edge function*/Worker/Lambda@Edge,
`maxmemory`, `maxmemory-policy`, `noeviction`, `allkeys-lru`, `volatile-ttl`, `evicted_keys`,
`keyspace_hits`/`keyspace_misses`, `proxy_cache`/`proxy_cache_path`, *cache-aside*,
*read-through*, *write-through*, *write-behind*, *thundering herd*, *cache stampede*,
*hit ratio*, cache poisoning and *web cache deception*.

**Thesis of the skill**: **caching is duplicating state, and all duplicated state goes out of
sync.** The right question is never "do I cache this?" but **"what happens when it is stale and who
invalidates it?"**. If there is no answer to the second, there is no cache: there is a time bomb
with good latency. Uncomfortable corollary: **the cache is the default solution to problems nobody
has diagnosed** — before adding a layer, measure what is slow and why (§6.4).

**Not applicable**: see `data-platform-standards` (**parent skill**: it sets **Valkey (BSD-3, Linux
Foundation) as the default cache engine** over tri-licensed Redis 8+, and the basic TTL and
cache-aside criteria. **This skill goes deeper and does not contradict it**: there the engine is
chosen and the licence declared, here the eviction policy, the invalidation strategy and the
behaviour under failure are decided), `load-balancing-standards` (**the reverse proxy and the load
balancer are theirs**: HAProxy, nginx, Traefik and Caddy — choice, health checks, draining, TLS
termination, topology and hardening; `networking-standards` is the trunk and already delegates that
depth to them. **Here only their role as an HTTP response cache**: `proxy_cache`, cache key,
coherence with the edge and with the origin. The boundary is clean: *nginx as proxy and balancer →
`load-balancing-standards`; nginx as cache → this skill*), `api-design-standards` (**the HTTP
contract is theirs**: mandatory `ETag` per resource, `If-Match`/`If-None-Match`, `412`/`428`, `304`,
and the requirement to declare correct `Cache-Control` and `Vary` on every response. **Here the
behaviour of the infrastructure that consumes those headers**: what the edge does with them,
`s-maxage` vs `max-age`, `CDN-Cache-Control`, serve-stale and the cost of a badly set `Vary` on the
hit rate. Do not duplicate ETag semantics: delegate them), `message-brokers-standards`
(queues, brokers and distributed logs: Kafka/KRaft, RabbitMQ, NATS, Redpanda, Pulsar — and the
rule that a PostgreSQL table with `SKIP LOCKED` is usually enough. **Redis/Valkey Streams used as a
queue falls on their side.** Boundary declaration: *the queue is theirs, the cache is mine*; an
instance acting as a cache does **not** act as a queue — they are workloads with different
durability and HA, and they share a process only by accident),
`microservices-architecture-standards` (data ownership, outbox, sagas),
`aws-standards`/`azure-standards`/`gcp-standards` (**CloudFront, Azure Front Door, Cloud CDN,
ElastiCache/MemoryDB, Memorystore as managed services**: their IaC, IAM, WAF and billing;
here the caching criteria that apply the same whoever the provider is), `cicd-standards` (the
**CDN purge as a deployment step** and asset versioning with a hash in the name),
`kubernetes-standards` (Ingress and proxy deployment), `cryptography-pki-standards` (TLS and
certificates at the edge), `appsec-standards` (threat methodology and general OWASP; here
only the risk classes specific to caching), `privacy-engineering-standards` (**personal data in
cache**: legal basis, minimisation and **effective erasure including cached copies** — here only
the mechanics of purging them), `observability-standards` (metrics platform; here which cache SLIs
to export), `sre-practice-standards` (SLOs and error budget),
`object-storage-standards` (the static origin behind the CDN),
`mysql-mariadb-dba-standards` and `oracle-dba-standards` (**critical boundary**: the cache usually
exists *because the database cannot cope*. If the cause is an N+1, a query with no index or
a badly chosen PK, **the right answer is to fix the query, not to add a cache** —
§6.4), `rag-standards`/`llm-app-engineering-standards` (semantic caching of prompts and
LLM responses: a domain of its own, with its own hit criteria), `lua-standards`
(**the platform belongs here** —nginx/OpenResty and its configuration, upstreams, TLS,
cache policy and purging; Redis/Valkey and its memory, persistence and eviction—; **the Lua running
inside is theirs**: `EVAL`/`EVALSHA` scripts and their determinism, and the code of the
`access_by_lua`/`content_by_lua` phases with its hard ban on blocking calls in the event loop),
`streaming-multimedia-standards` (**the video/audio pipeline is theirs** —HLS/DASH packaging,
segment duration, bitrate ladder, DRM—; **here the CDN that serves those segments**: an HLS segment
is one more cacheable HTTP object, and its TTL, its headers and its egress cost are decided here),
`web-performance-standards` (**the cache policy, the CDN, the headers and the purge belong here**;
**the effect measured on the client** —LCP, TTFB at the 75th percentile, field data— **is theirs**.
A cache that improves the *hit ratio* and does not move the user metric has solved nothing),
`pwa-standards` (**an operational warning, not just a boundary**: a *service worker*'s cache is
**another layer, in front of everything this skill decides**, and it can **override the cache policy
of the CDN and the origin**. A deployment that is not visible in the browser is usually a `sw.js`
serving old HTML, not a purge failure. The criteria for that layer —what is precached, with which
strategy and how a broken service worker is disabled— are theirs).

## 2. Default decisions

> Verify the latest version, licence and real directive support on the web before committing to it
> in a project (§8). Data from **August 2026**.

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Add a cache? | **No, until a measurement exists** identifying the slow query or route and proving the data tolerates being stale | Every cache layer is one more source of truth to maintain (§6.4) |
| Pattern | **Cache-aside** | Everything else requires justification (§3.2) |
| TTL | **Mandatory on every entry**, short and with *jitter* | "Imperfect short TTL" beats "perfect invalidation" in almost every case (§3.3) |
| Distributed cache engine | **Valkey** (BSD-3-Clause, Linux Foundation) — 9.1.x series (9.1.1, Jul-2026); live branches 9.0.x, 8.1.x, 8.0.x, 7.2.x | Set by `data-platform-standards`. **Redis 8+ is tri-licensed RSALv2 / SSPLv1 / AGPLv3** (verbatim from `LICENSE.txt`): only with explicit approval from the licensing policy, or through a real dependency on modules Valkey does not cover. Adoption context: AWS ElastiCache and Google Memorystore offer Valkey and several distributions package it as `redis-server` by default — **verify which binary you actually have** (§8) |
| Eviction policy | **`maxmemory` set + `allkeys-lru`** (or `allkeys-lfu` with a skewed access pattern) | **`noeviction` on a cache is an incident waiting for a date** (§3.6) |
| Persistence on the cache node | **Disabled** (no RDB, no AOF) | A cache is disposable by definition. If a piece of data needs durability, it is not a cache: it is a database (§3.6) |
| Shared HTTP cache | Explicit `Cache-Control` on **every** response; **never by omission** | An endpoint with no declared policy will end up cached by someone, in the layer that suits you least |
| Serve-stale | **`stale-while-revalidate` + `stale-if-error` whenever the content tolerates it** | They are the two directives with the best value/risk ratio in the standard (§3.7) |
| CDN-specific control | **`CDN-Cache-Control`** (RFC 9213) when the edge and the browser must differ | Avoids the fragile trick of using `s-maxage` for everything |
| Diagnostics | **`Cache-Status`** (RFC 9211) enabled in pre-production | In production, only to authorised clients: it exposes information about the cache key (§5) |
| Static assets | **Content-hashed name** + `Cache-Control: public, max-age=31536000, immutable` | Eliminates the invalidation problem by construction: it is the best "caching strategy" there is |
| Purge by tag | The provider's mechanism (`Surrogate-Key` in Fastly, `Cache-Tag` in Cloudflare, path invalidation in CloudFront) | **There is no current IETF standard**: `draft-ietf-httpbis-cache-groups` is still a draft. It is conscious vendor coupling, with an ADR |
| Edge functions | **Only** for cache key logic, normalisation, redirects and headers | Business logic at the edge is a parallel deployment with no observability (§7) |

## 3. Technical criteria

### 3.1 The layers, from the inside out

| Layer | What it solves | Its characteristic failure |
|---|---|---|
| **In-process / in the pod's memory** | Zero latency, tiny and very hot data (configuration, catalogues, computation results) | **Incoherence between replicas**: N pods = N versions of the data. Only for data where divergence between instances is tolerable, and with TTLs in seconds |
| **Distributed (Valkey/Redis)** | State shared between instances, offloading the database, sessions | It becomes a SPOF if the application does not work without it; and an accidental database if someone stores there the only copy that exists |
| **The database's own** (buffer pool, plan cache, materialised views) | It is the cache you **already have and do not manage** | It gets forgotten: an external cache is added for data the buffer pool was already serving from memory. Measure first (§6.4) |
| **Reverse proxy** (nginx/Varnish/Traefik) | Complete HTTP responses close to the origin, backend protection | A badly defined cache key → one user's response is served to another (§5) |
| **CDN** | Geographic latency, peak absorption, origin egress cost | Slow and global purging; and everything you cache wrongly is multiplied by the number of PoPs |

**Rule**: **caching in the wrong layer multiplies the problem instead of solving it.** Data
personalised per user cached at the CDN is a data leak; global data cached in each pod is N
divergent copies of something that should have been in one place. Put the cache **in the outermost
layer that is correct** (most benefit) and **never further out than that** (most risk).

**No-overlap rule**: do not stack layers for the same data without deciding the relationship between
their TTLs. Two caches with 300 s TTLs in series give a maximum staleness of 600 s, not 300.

### 3.2 Patterns

- **Cache-aside (lazy loading) — the default.** The application reads the cache; on a miss it reads
  the origin and writes the cache with a TTL. Advantages: simple, the cache is never on the critical
  write path, it survives its own outage. Cost: every miss pays the full latency, and there is a
  race window between reading the origin and writing the cache.
- **Read-through**: the cache (or its library) loads the data on a miss. It encapsulates better, but
  couples the application to a component that is now on the critical read path.
- **Write-through**: writes to cache and origin at once. Better coherence, higher write latency, and
  **it fills the cache with data nobody may read**.
- **Write-behind (write-back)**: writes to the cache and persists asynchronously. Maximum
  performance and **maximum risk**: the cache holds the only copy of the data until it is flushed.
  **Vetoed** except with demonstrated durability of its own and an ADR accepting the loss.
- **Invalidation on write: delete, do not update.** A `DELETE` of the key after the write has fewer
  races than rewriting the value (two concurrent writers can leave the old value if they update).
  The next reader repopulates it.
- **Proactive refresh (*cache warming*)** only for a small, known and critical set (home page,
  featured catalogue). Pre-warming "everything" reproduces the load you were trying to avoid.

### 3.3 Invalidation: the hard problem

In order of preference:

1. **By TTL** — simple, self-limiting, no additional state, and **sufficient in the vast
   majority of cases**. There is only one design question: *how many seconds of stale data does the
   business tolerate for this data?* Put it in writing; it is usually much more than the team
   assumes, and quite a bit less than the default TTL reflects.
2. **By event** — the writer invalidates when the data changes. Correct and precise, but
   it introduces coupling and **fails silently**: when the event is lost, nobody notices.
   **Hard rule: event-based invalidation is *always* combined with a TTL as a safety net**, never
   replaces it.
3. **By tag / surrogate key** — when one change invalidates a set ("all the products in this
   category"). It is the right thing for the edge. Cost: maintaining the tag map and depending on
   the provider's proprietary mechanism (§2).
4. **By version in the key** — change the prefix and the old cache dies by eviction.
   Instant, atomic invalidation with no purging; in exchange, a **100% miss rate** right
   afterwards. Combine it with warming the critical set or with a progressive rollout.

**Governing criterion**: **prefer a short TTL to perfect invalidation.** An event-based invalidation
system is one more distributed system to maintain, debug and monitor, with its own class of bugs; a
30 s TTL has no bugs and often solves the same business problem. Raise the complexity only when the
cost of the short TTL (load on the origin) has been measured and is unaffordable.

### 3.4 The classic failures with names of their own

- **Stampede / *thundering herd* / *dog-piling***: a hot key expires and N concurrent requests hit
  the origin at once. Mitigations, combinable:
  - **Locking or *single-flight***: only one requester recomputes; the rest wait or receive the
    stale value. The lock must have a **mandatory expiry** (if the one recomputing dies, it must not
    block everyone forever).
  - **Probabilistic early expiration**: when the entry approaches its expiry, a probabilistically
    chosen requester refreshes it in the background while the others keep serving the current value.
    It is the application-level equivalent of `stale-while-revalidate`.
  - **Soft TTL / hard TTL**: serves the value past the soft TTL while it is refreshed; it only
    blocks on reaching the hard one.
- **Penetration (non-existent keys)**: requests for identifiers that never exist never hit the
  cache and always go to the origin — a trivial DoS vector. Mitigation: **cache the negative
  result** with a short TTL (an explicit marker, not an ambiguous `null`), validate the key format at
  the edge, and a Bloom filter for large key spaces.
- **Avalanche (simultaneous expiry)**: a batch of keys created at the same time expires at the same
  time. Mitigation: **mandatory jitter on every TTL** (e.g. `ttl * (1 + rand(0, 0.2))`). Dangerous
  variant: cache restart or failover, which expires **everything** at once — the application must
  survive a 100% miss rate (§6.3). If it does not survive, the cache is not an optimisation:
  it is a hard dependency with no HA plan.

### 3.5 Key design

- **Explicit, documented format**: `<app>:<format-version>:<entity>:<id>[:<variant>]`.
  No spaces and no free user-supplied data without normalisation.
- **The key includes everything that makes the value vary**: identifier, language, currency, country,
  API version, role or segment if applicable. **A forgotten dimension = serving the wrong
  content**; in the HTTP layer, the exact equivalent is an incomplete `Vary` (§5).
- **Version the value's format in the key.** When you change the serialised shape, change the
  version: it is the only safe way to deploy N and N-1 at the same time without the new code reading
  old structures (or the other way round). Never reuse the same prefix with a different schema.
- **Never put personal data or secrets in the key**: keys appear in logs, metrics, traces and
  diagnostic output. Use an opaque identifier.
- **Bounded cardinality**: one key per combination of free user filters is a cache with a 0% hit
  rate and infinite memory pressure. Normalise and bound the key space before caching (the same
  applies to the CDN cache key, §3.8).

### 3.6 Valkey/Redis **as a cache** (not as a database)

The engine choice and its licence are set by `data-platform-standards` (Valkey by default,
BSD-3; Redis 8+ tri-licensed). Here, operation **in the cache role**:

- **`maxmemory` always set**, below the container/host memory with headroom for
  fragmentation and replica and client buffers. Without `maxmemory`, the process grows until
  the OOM killer decides for you.
- **`maxmemory-policy`**:
  - `allkeys-lru` / `allkeys-lfu` → **the default for a cache**. LFU if there are persistently
    hot keys; LRU if the pattern is temporal.
  - `volatile-*` → only if data with and without TTLs coexist in the same instance. Trap: if they
    run out of candidates with TTLs, **they behave like `noeviction`**.
  - **`noeviction` on a cache instance is an incident**: once full, writes start returning an error
    (`OOM command not allowed`) and the cache stops accepting new entries while it keeps serving the
    old ones. It silently becomes a frozen, stale store. `noeviction` only makes sense when the
    instance is **not** a cache (queue, counters, locks) — and then it is another instance, with
    another skill (§1).
- **Fragmentation**: watch `mem_fragmentation_ratio`. Values well above 1 indicate memory held by
  the allocator; `activedefrag` is an option, at a CPU cost. Values below 1 mean *swap* —
  unacceptable in a cache: disable swap or size it properly.
- **Persistence**: **disabled** in the cache role. RDB causes memory spikes from *fork*
  (copy-on-write) and I/O spikes; AOF costs latency. Unless you want a **warm start** after a
  planned restart — a conscious decision, with its cost measured, not the default inherited from the
  package.
- **The cache vs database difference**, explicitly: a cache is **rebuildable from the source of
  truth, at any moment and without loss**. The moment a piece of data only exists there (a session
  with no backing, a business counter, a work queue), it is **no longer** a cache: it inherits
  durability, backup, HA and replication requirements — and it is probably in the wrong store.
- **HA**: replica and failover (Sentinel or cluster mode) **only if the impact of losing the cache
  justifies it**, measured against the question in §6.3. Cluster for datasets that do not fit in one
  node, not out of fashion. Before setting up HA for a cache, ask whether it is not cheaper to make
  the system tolerate its absence.
- **Forbidden in production**: `KEYS` (use `SCAN`), `FLUSHALL`/`FLUSHDB` from the application,
  long Lua scripts, and sharing the cache instance with queue or lock workloads.
- **Security surface**: never exposed to an untrusted network, TLS and authentication
  mandatory, administrative commands renamed or disabled. Watch the CVEs: 2026 has
  brought in this family DoS via the *cluster bus* and **use-after-free with the possibility of
  RCE** (including in the Lua scripting engine) — with minimum fix versions
  published per branch. **Verify your branch against the current advisory** (§8).

### 3.7 HTTP: the directives that really matter

Explicit delegation: **the semantics of `ETag`, `If-None-Match`, `304`, `If-Match` and `412`, and
the obligation to declare `Cache-Control` and `Vary` on every response, belong to
`api-design-standards`.** Here, what the infrastructure does with them:

- **`max-age` vs `s-maxage`**: `max-age` applies to all caches; `s-maxage` only to shared ones
  (proxy, CDN) and **takes precedence over `max-age`** in them. The useful pattern is a short
  `max-age` in the browser (cheap revalidation) and a long `s-maxage` at the edge (where
  you can purge).
- **`CDN-Cache-Control` (RFC 9213, *Targeted HTTP Cache Control*)**: when the CDN must do
  something different from the other caches. It allows, for example, `Cache-Control: no-store` +
  `CDN-Cache-Control: max-age=600` (the edge caches, nobody else). **Careful**: carrying two
  policies in the same response is a known source of confusion about where a sensitive piece of data
  ends up stored — document the intent.
- **`stale-while-revalidate` and `stale-if-error` (RFC 5861) — the two that give the most value**:
  - `stale-while-revalidate=N`: serves the stale value for N s while revalidating in the
    background. It turns the latency spike of expiry into zero, and is the "out of the box"
    stampede mitigation in the HTTP layer.
  - `stale-if-error=N`: serves the stale value if the origin returns an error or does not respond.
    **It turns an origin outage into a degradation**, not into an error page. It costs zero in
    normal operation: set it generously.
  - Verified status (August 2026): `stale-while-revalidate` is honoured by Chrome, Firefox and Edge;
    **Safari does not**. **`stale-if-error` is not implemented by any major browser**: it is
    effectively a CDN/proxy directive. At the edge: CloudFront supports both; Cloudflare
    made its SWR **fully asynchronous in Feb-2026** (previously the first request after expiry
    blocked); **Google Cloud CDN supports SWR but not `stale-if-error`** (and applies
    `serveWhileStale` by default, 86400 s if unspecified); Fastly gives full control.
    **"Serving stale" does not mean the same thing in two CDNs: verify yours** (§8).
  - Mind the window: the asynchronous refresh only happens if a request arrives within the SWR
    window. With sparse traffic, a small window still leaves requests blocking.
- **`immutable`** for assets with a hash in the name: it avoids useless revalidations.
- **`private` vs `public` vs `no-store`**: `private` prevents storage in shared caches but
  **not** in the browser; `no-store` is the only one that prevents storing anywhere. Everything
  authenticated or personalised: `no-store` or `private` **and** a cache key that includes the user.
  Never `public` on a response that depends on the session.
- **`Vary`: the directive that destroys the hit rate without warning.** Each added value
  multiplies the stored variants by that header's cardinality.
  - `Vary: Accept-Encoding` → acceptable (2-3 variants).
  - `Vary: Accept-Language` → as many variants as the language strings browsers send
    (hundreds). **Normalise to a closed set at the edge before varying.**
  - **`Vary: User-Agent` → forbidden**: effectively infinite cardinality, hit rate
    ≈0. Use normalised *client hints* or a decision at the edge.
  - **`Vary: Cookie` or `Vary: Authorization` on public content → veto**: any analytics cookie
    fragments the cache per user. If the response depends on the session, it is not cacheable
    content in a shared cache (§5).
  - **Omitting a necessary `Vary` is worse than including it**: it is exactly the mechanism of data
    leakage between users (§5).
- **`Cache-Status` (RFC 9211)**: the standard header for knowing which layer hit and why it missed
  (no `Vary` match, stale response, partial response…). Essential for debugging a low hit rate.
  **In production, only to authorised clients**: it reveals information about the cache key, useful
  to an attacker (§5).
- **`Age`** to detect real staleness in production, and to verify that the edge and the browser
  count freshness as you expect.

### 3.8 CDN

- **What goes to the edge**: static content (with a hash in the name → `immutable`), images and
  media, anonymous HTML responses, public read-heavy API responses. **What does not**:
  anything that depends on session, cookie or authorisation header, except with a cache key that
  explicitly includes the principal — and even then, with a security review (§5).
- **Dynamic with a short SWR**: for content that changes often but tolerates seconds of
  age (listings, home pages, read API responses), a low `s-maxage` +
  `stale-while-revalidate` + a long `stale-if-error` wins more than any other configuration.
- **Cache key and normalisation — where the hit rate is won or lost**:
  - **Ignore irrelevant query parameters** (`utm_*`, `fbclid`, `gclid`…): if they enter the
    key, every marketing campaign manufactures you an empty cache.
  - **Sort and filter the query to an allowlist**; normalise host case, trailing slash
    and path encoding.
  - **Careful with aggressive normalisation**: merging into the same key two URLs the origin
    treats differently is precisely the mechanism of parser-discrepancy poisoning (§5). Normalise
    the same way at the edge and at the origin, or do not normalise.
  - Headers and cookies **out** of the key except for an explicit list.
- **Purging**: by tag when the provider allows it, by path otherwise; **by wildcard, only
  as a last resort** (equivalent to flushing). **Its real latency is not zero**: propagation to
  all PoPs takes time, and in a large CDN a downed PoP may not complete it until it returns. Do not
  design flows that assume instant, global purging. **The superior strategy is still not needing to
  purge**: a hash in the asset's name and a version in the key.
- **Origin shield**: an intermediate layer that consolidates the misses from all the PoPs against
  the origin. It drastically reduces origin load and egress cost on long-tail content;
  it adds a latency hop on a miss and one more configuration point. Enable it
  when the origin suffers from the number of PoPs, not by default.
- **Egress cost is a design criterion, not a billing surprise**: the hit rate is a
  **cost variable** as well as a performance one. Every byte that misses is paid for twice
  (origin egress + CDN transfer), and most providers also bill per request and some for *cache
  fill*. The models differ at the root (per GB, flat fee with unmetered bandwidth, base fee + GB):
  **a drop in the hit rate is a cost incident**, and deserves an alert (§6.2). Model the cost
  **before** choosing a provider and review the terms of use: "unmetered" bandwidth plans usually
  exclude the mass distribution of video or large files.
- **Edge functions** (Workers, Lambda@Edge, edge middleware): use them to manipulate the
  cache key, normalise, redirect, add security headers and run A/B tests by controlled variant.
  **Not** for business logic or data access: it is a different execution environment,
  with a different deployment model, different observability and a different failure model. If it
  ends up having state, it is no longer an edge function: it is a service with no SRE.

## 4. Quality and CI gates

In increasing order of cost. The ones marked **break the build**:

1. **Response header lint**: every route declares an explicit `Cache-Control`; **fail if
   an authenticated response lacks `no-store`/`private`**, or if a `public` response
   includes `Set-Cookie` or depends on `Authorization`. **Gate**.
2. **Veto on `Vary: User-Agent`**, on `Vary: Cookie` over public content, and on `public` +
   `Vary: Authorization`. **Gate**.
3. **Cache layer tests with a real cache** (a Valkey container), not with an in-memory
   double: TTLs, eviction and network errors are precisely what has to be tested.
4. **Invalidation tests as a happy path *and* as a failure**: write → read stale →
   invalidate → read fresh; and the case where invalidation **fails** — the TTL must still bound
   the staleness. A cache system without this test is a system with no guarantee.
5. **Edge case tests**: miss, expiry, cached negative result, cache **down**
   (the application must degrade, not fail — §6.3), and a cache returning a value in an old
   format (key versioning, §3.5).
6. **Stampede test**: N concurrent requesters on a just-expired key generate
   **one** load on the origin, not N. It is the regression that most silently comes back.
7. **Edge coherence test**: authenticated request, purge, and verification that the
   personalised content does **not** appear in a subsequent anonymous request. Automatable
   against pre-production. **Gate in the CDN configuration pipeline**.
8. **Review of the CDN configuration as code** (Terraform or OpenTofu; see
   `iac-standards`), with a reviewed diff: edge configuration changes the security behaviour of the
   whole application and **cannot be edited by hand in the console**.
9. **CDN purge as an explicit, verified deployment step** (see `cicd-standards`),
   including the case where the purge fails.
10. **Deception test in the security suite**: request an authenticated route with an
    invented static suffix (`/account/profile/x.css`, `.avif`, `.js`…) and check that it is **not**
    cached (§5).

## 5. Cache security

The three risk classes are specific to this domain and `appsec-standards` does not cover them in
this detail:

- **Serving a personalised response to another user — it is a data leak, not a performance bug.**
  It is the most serious and most frequent cache failure, and it appears through three routes:
  an incomplete cache key, a `Vary` that omits the personalising dimension, or a missing
  `Cache-Control` on an endpoint someone decided to cache further up. **Treat it as a security
  incident with notification**, not as a caching bug: if it happened, there was exposure of personal
  data (see `incident-response-forensics-standards` and `privacy-engineering-standards`).
  Defence by design: **deny by default** at the edge — nothing is cached except allowlisted routes;
  and automatic `no-store` in the presence of `Authorization` or a session cookie.
- **Cache poisoning**: the attacker gets the cache to store a manipulated response that is then
  served to everyone. Vectors: inputs not included in the key but reflected in the response
  (unkeyed headers such as `X-Forwarded-Host`, `X-Forwarded-Scheme`, query parameters ignored in the
  key but used by the application), and **URL parsing discrepancies between the edge and the
  origin** (trailing slash, encoding, delimiters) — a very active line of research: large-scale
  studies find thousands of affected sites and recurring bypasses of CDN protections.
  Mitigation: **every input that influences the response is part of the key or is removed at the
  edge**; identical normalisation at edge and origin; do not reflect non-normalised headers;
  restricted `Cache-Status`; and active tests in the security suite.
- **Cache deception (*web cache deception*)**: the attacker induces the victim to request
  `/account/profile.css`; the origin ignores the suffix and returns the profile, the edge sees a
  "static" extension and caches it as public; the attacker retrieves it. Mitigation: **the decision
  to cache is taken from the `Content-Type` and from the *origin's* policy, not from the URL
  extension**; the origin sends `Cache-Control: no-store` on everything authenticated; and do not
  trust the provider's "protected" extension lists (bypasses with new or uncommon extensions have
  been demonstrated). Normalise or reject paths with unexpected suffixes.
- **Poisoning via *request smuggling*** and desynchronisation between the proxy and the origin:
  the vector that turns a parsing discrepancy into total control of the cache. It is a
  risk of the proxy↔origin chain (see `networking-standards` for the network piece and
  `appsec-standards` for the technique), but **its amplification belongs to the cache**: a poisoned
  response is served to thousands.
- **Personal data in cache**: the cache is one more copy of the data, subject to the same
  classification, encryption and retention. **The right to erasure reaches cached copies**: without
  the ability to purge selectively, the TTL is your only erasure guarantee — document it and bound
  it. Never personal data in the key (§3.5) or in the edge logs.
- **DoS by cache**: requests for non-existent keys (penetration, §3.4) and requests designed
  to maximise misses (random query) turn your CDN into an amplifier against your
  own origin — and into an invoice. Strict key normalisation, rate limiting at the
  edge and negative caching.
- **Patching the cache and proxy software**: 2026 has been a hard year on this surface
  (overflows in nginx with active exploitation in the wild, resource exhaustion via
  HTTP/2 affecting multiple proxies, use-after-free in the scripting engine of the Redis/Valkey
  family). The cache is on the path of **all** the traffic: its patching window is that of an edge
  component, not that of an internal service. See
  `vulnerability-management-standards` and `networking-standards` (proxy versions).
- **Supply chain** of the edge functions and the packages they bundle: they are
  deployed on the path of all the traffic. Pin by digest and verify signatures — remembering the
  2026 precedent (**Mini Shai-Hulud / CVE-2026-45321**, forgery of SLSA level 3 attestations):
  **provenance on its own is no longer sufficient proof**.

## 6. Measurement and operability

### 6.1 SLIs per layer
No aggregate metric works: **measure the hit rate per layer and per content class**.
A global 95% can hide a 99% on static assets and a 20% on the API, which is what hurts.

- **Distributed (Valkey/Redis)**: `keyspace_hits`/`keyspace_misses`, **`evicted_keys`** (if
  it grows steadily, the cache is too small or the TTLs too long),
  `expired_keys`, memory used vs `maxmemory`, `mem_fragmentation_ratio`, p99 latency,
  blocked clients and rejected connections.
- **HTTP/CDN**: hit rate (per PoP and per content type), **requests and bytes to the
  origin** (the metric that translates into an invoice), latency at origin vs at edge, `Age` of the
  responses served, stale-serve rate (`stale-while-revalidate` / `stale-if-error`
  firing: **a spike in `stale-if-error` is an origin-down alert disguised as
  normality**), origin 5xx errors and purge rate.
- **Business**: perceived end-to-end p95/p99 latency — the only one that justifies the
  cache existing.

### 6.2 Alerts worth having
A sharp drop in the hit rate (**a symptom of a deployment that changed the key, a new `Vary` or a
mass purge** — and also a cost incident); sustained growth of `evicted_keys`;
memory approaching `maxmemory`; spikes of stale-serving on error; and **deviation of
egress spend** from the baseline.

### 6.3 The question that defines your architecture
> **What happens if the cache disappears right now?**

If the answer is "the system goes down", **you do not have a cache: you have an in-memory database
with no durability, no backup and no HA**. Design so the application works degraded without the
cache (rate limiting, controlled degradation, a *circuit breaker* towards the origin, progressive
load while repopulating) and **rehearse it**: switching off the cache in a *game day* is one of the
most profitable tests there is. Short timeouts towards the cache: a miss must cost
milliseconds, never become the bottleneck it was meant to avoid.

### 6.4 The uncomfortable conversation: cache vs fixing the origin
Before adding any layer, answer in writing:
1. **What exactly is slow?** (trace and query plan, not intuition).
2. **Is it a database problem or an application problem?** An ORM **N+1**, a query
   with no index, a PK that fragments the clustered index or `OFFSET` pagination **are
   fixed where they belong**. Caching the result of a query with no index hides the problem,
   duplicates the state, adds a whole class of coherence bugs and leaves the bomb armed for
   the first mass miss. See `mysql-mariadb-dba-standards` §6 and `data-platform-standards`.
3. **How much staleness does the business tolerate?** If the answer is "none", no cache is
   possible: the origin has to be made faster.
4. **Who invalidates and what happens if it fails?** (§3.3).
5. **Does the system survive without the cache?** (§6.3).

Without the five answers, the cache is not designed: it is just installed.

### 6.5 A high hit rate with stale data is worse than a low one
The hit rate **is not the success metric**: it is the efficiency metric. A cache that
hits 99% serving data from an hour ago that should have been 10 seconds old is working
perfectly **and doing harm**, and it does so silently: it generates no errors, it fires no
alerts and the user simply sees something false. Always measure the hit rate **alongside**
the age served (`Age`, p95 staleness) and treat excessive staleness as
a correctness defect, not a performance one.

## 7. Sustainability and prohibitions

- **Every cache has an owner and a review date.** Review twice a year: prefixes with no traffic,
  TTLs nobody remembers choosing, CDN rules inherited from a migration, automated purges
  against routes that no longer exist. A forgotten cache rule is active debt.
- **Edge configuration is code**: versioned, reviewed and deployed by IaC, with
  a pre-production environment of its own. Changing caching in the provider's console is vetoed.
- Document in an ADR: the CDN provider choice (**a one-way door** because of the
  coupling of the purge mechanism and the edge functions), the invalidation strategy
  and the placement of each layer.
- Portability: keep the application's cache logic **provider-agnostic** and
  concentrate the proprietary parts (surrogate keys, edge functions, VCL) in a thin, isolated layer,
  with the exit cost estimated.

**FORBIDDEN**
- ❌ Adding a cache without the five answers of §6.4. In particular, **caching to cover up a
  query with no index or an N+1**.
- ❌ Entries **with no TTL**, or a TTL with no jitter on batches created at the same time.
- ❌ Event-based invalidation **with no backing TTL**.
- ❌ `noeviction` (or `volatile-*` with no candidates) on a cache instance; an instance **with no
  `maxmemory`**.
- ❌ The cache as the **only copy** of a business datum; *write-behind* without durability of its own
  and an ADR.
- ❌ Sharing the cache instance with queues, locks or business counters.
- ❌ `KEYS`, `FLUSHALL`/`FLUSHDB` from the application in production.
- ❌ An **authenticated or personalised** response cacheable in a shared cache; `public` on
  content that depends on session or cookie.
- ❌ `Vary: User-Agent`; `Vary: Cookie` on public content; omitting a necessary `Vary`.
- ❌ Deciding cacheability **by the URL extension** instead of by the origin's
  policy (*cache deception*).
- ❌ Different key normalisation between the edge and the origin (parser-discrepancy
  poisoning).
- ❌ Personal data or secrets in the cache key, in the edge logs or in a publicly exposed
  `Cache-Status`.
- ❌ Designing on the assumption of **instant, global** CDN purging.
- ❌ An endpoint with no explicit `Cache-Control` ("the framework takes care of it").
- ❌ Business logic or data access in edge functions.
- ❌ Configuring the CDN by hand in the provider's console.
- ❌ Presenting the hit rate as a success metric without the age served (§6.5).
- ❌ Stating versions, licences or directive support **from memory**, without §8.

## 8. Mandatory web verification

Before committing to any version, licence, directive or provider behaviour:

1. **Valkey**: latest version and maintained branches
   (`api.github.com/repos/valkey-io/valkey/releases` — raw data, not the HTML of the releases page)
   and the licence **verbatim** from the raw `COPYING` file (as of August 2026:
   `SPDX-License-Identifier: BSD-3-Clause`, "Copyright (c) 2024-present, Valkey contributors";
   latest stable 9.1.1, 2026-07-21).
2. **Redis**: latest version (`api.github.com/repos/redis/redis/releases`; 8.10.0 as of 2026-07-29)
   and the licence **verbatim** from the raw `LICENSE.txt` — as of August 2026 it literally says
   "tri-licensing model": **RSALv2 or SSPLv1 or AGPLv3**, with 7.2 and earlier under BSD-3.
   **Confirm it is still the same before approving its use.**
3. **CVEs** for Valkey/Redis by branch (project advisories, RHSA, ElastiCache) and for the edge
   proxies you use (nginx, HAProxy, Varnish, Envoy). In 2026 there was active exploitation in
   nginx: **it is edge surface, short patching window**.
4. **Real support for `stale-while-revalidate` and `stale-if-error` in your specific CDN** — do not
   assume parity: as of August 2026, Google Cloud CDN does **not** support `stale-if-error`,
   Cloudflare made its SWR asynchronous in Feb-2026 and Safari does not implement SWR in the
   browser. Consult the provider's documentation, not articles.
5. **Purge by tag**: check whether `draft-ietf-httpbis-cache-groups` has advanced to an RFC
   (as of August 2026 it was still a draft, revision -07 of May-2025). Until it is, **the
   mechanism is proprietary**.
6. **Current RFCs**: 9111 (HTTP caching), 9110/9110 §conditionals, **9213** (`CDN-Cache-Control`),
   **9211** (`Cache-Status`), **5861** (serve-stale). Verify they have not been obsoleted.
7. **Pricing and billing model of the chosen CDN** (per GB, flat fee, fee + GB, *cache fill* cost,
   cost per request) and the **terms of use** for unmetered bandwidth.
   They change frequently; model with current data.
8. **Supply chain**: the status of **CVE-2026-45321 / Mini Shai-Hulud** and which provenance
   guarantees are still valid for packages and edge functions.
9. **Declared gaps** (not verified in this drafting — **do not fill from memory**):
   - **Behaviour of `stale-if-error` in Azure Front Door and in Akamai**: not verified
     against official documentation.
   - **Status of Cloudflare's "Cache Deception Armor" protection** and its equivalents in
     other providers: it has been verified that documented bypasses existed, **not** whether the
     protected extension list is up to date today.
   - **Module parity between Valkey and Redis Stack** (search, JSON, vector): there are claims
     from secondary sources, not cross-checked against project documentation.
   - **Which Valkey/Redis series each distribution packages** today and under which package name:
     verified only from secondary sources. **Check the binary you actually have.**
   - **The exact minimum fix version** for each 2026 Valkey CVE: the figures seen
     come from third-party summaries and **must be confirmed against the project advisory**.
   - CDN per-GB price figures: they come from third-party comparisons, **not** from the
     official pricing pages.

If the web contradicts this document, **the web wins** — flag the discrepancy.
