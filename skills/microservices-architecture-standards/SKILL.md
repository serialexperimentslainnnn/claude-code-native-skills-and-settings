---
name: microservices-architecture-standards
description: Standards for systems already split across the network - the distributed topology, not the internal design of one deployable. Use when cutting service boundaries and their ownership, inter-service contracts (OpenAPI, AsyncAPI, protobuf/gRPC) and their versioning, synchronous versus asynchronous communication, sagas and distributed transactions, the outbox pattern, message queues between services, resilience patterns (circuit breaker, retries with backoff, timeouts, bulkheads), API gateways, service mesh and mTLS between services, identity propagation across service calls, or distributed tracing correlation.
---

# Microservices architecture standards

## 1. Scope and triggers

Applies when designing, reviewing or evolving: distributed services, boundaries between services, API contracts (REST/gRPC/events), asynchronous communication, resilience, distributed observability, and the prior monolith-versus-microservices decision. Triggers: "microservice", "bounded context", "event-driven", "saga", "outbox", "API gateway", "contract", "OpenAPI", "AsyncAPI", "protobuf", "circuit breaker", "strangler".

**Not applicable**: see `api-design-standards` (the **internal design** of one concrete contract: resources, verbs, HTTP status codes, pagination, ETags, RFC 9457, idempotency keys, contract versioning — here only which contract exists between which services and how its evolution is governed), `data-platform-standards` (the engine underneath: modelling, indexes, partitioning and Kafka retention, PostgreSQL tuning — here the outbox pattern, per-service data ownership and why a database is not shared), `kubernetes-standards` (how each service is deployed: manifests, Gateway API, mesh as an implementation), `observability-standards` (OTel instrumentation, sampling, cardinality and the tracing backend — here only the requirement for distributed correlation), `sre-practice-standards` (per-service SLOs, error budget, on-call and the operation of the resulting system), `identity-access-management-standards` (issuing and validating the identity that is propagated between services), `appsec-standards` (vulnerability classes in each service's code), `cryptography-pki-standards` (the PKI underpinning internal mTLS), `aws-standards`/`azure-standards`/`gcp-standards` (the provider's managed queue, bus and gateway services), the language skills (concrete implementation of each pattern), `software-architecture-patterns-standards` (**critical boundary, mirrored from its own §1**: **the internal design of a system and the prior decision on whether distribution is needed at all are theirs** — modular monolith as the default, layers, hexagonal/ports and adapters, module boundaries, bounded context, CQRS and event sourcing, ADRs, C4, quality attributes—; **here the distributed topology**: service cuts, communication over the network, saga and outbox in execution, distributed resilience, mTLS and meshes. Rule: ***if the question is how two processes separated by the network communicate, it belongs here; if it is how code is structured inside one deployable, it is theirs***. Corollary neither side may soften: **the modular monolith is the catalogue's default and this skill does not fire to justify it, but when a force already compels distribution**), `refactoring-tech-debt-standards` (**the *strangler fig*, branch by abstraction and expand/contract as safe migration techniques are theirs**; here the distributed destination being migrated to and its contracts).

Governing principle: **microservices are a technique for organisational scaling with a permanent distributed cost** — they are adopted on demonstrated need (§2.1), cut by domain (§3) and paid for with contract discipline, resilience and observability (§3–§6); without that discipline the result is a distributed monolith, the worst of both worlds.

## 2. Default decisions

> **Mandatory web verification before pinning versions**: the values below were verified in August 2026; re-verify with WebSearch on every real use (see §8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Initial architecture | **Modular monolith** with internal domain boundaries | Microservices only with justification (§2.1) |
| REST contract | **OpenAPI 3.1/3.2** (3.2.0 stable since Sept 2025), *design-first* | — |
| Event contract | **AsyncAPI 3.x** (3.1 current) | — |
| High-performance internal RPC | **gRPC + protobuf** (proto3) | REST if the team does not know it well |
| Event broker | **Kafka 4.x** (4.2.1 current, KRaft; no ZooKeeper since 4.0) | RabbitMQ for classic work queues; NATS for lightness |
| Observability | **OpenTelemetry** (traces/metrics/logs stable; CNCF *graduated* 2026; *profiles* still alpha — do not depend on it in production) | — |
| Edge | API gateway with centralised authn/authz; internal **mTLS** | Service mesh only if already needed for scale |
| Irreversible decisions | **ADR mandatory** | — |

### 2.1 When NOT to use microservices (an explicit decision, not a default)

Microservices is an expensive *one-way* decision. **Forbidden** to adopt them unless at least one of these conditions holds, documented in an ADR:

- Multiple teams (>2) that need to deploy independently and collide in the same code.
- Clearly divergent scale or fault-isolation requirements between domains (measured, not assumed).
- Domains whose lifecycle or regulatory compliance demands isolation (data, deployment, audit).

In their absence: **modular monolith** — modules with explicit domain boundaries, directed and verified dependencies (ArchUnit or equivalent), a database schema per module. That keeps the door open to extracting services later (§7, strangler fig) without paying the distributed cost today (network latency, eventual consistency, operating N systems).

Cost assumed when distributing (name it in the ADR, do not discover it in production):
- The network fails, has latency and is not secure (the fallacies of distributed computing): everything that was a function call becomes something that can fail partially.
- Eventual consistency between services: the UX and the business must tolerate it explicitly.
- Operational cost ×N: pipelines, observability, on-call, versioning and security per service.

## 3. Design and boundaries

### Domain boundaries (DDD)
- One service = one **bounded context** (or part of one); never a context split across services, nor services cut "by technical layer" (entity-service, CRUD-service).
- Between contexts, explicit translation (anti-corruption layer); do not share domain models or entity libraries between services.
- Cutting heuristic: high transactional cohesion inside, asynchronous and delay-tolerant communication outside. If two "services" need to deploy or transact together, they are one.

### Versioned contracts
- **The contract is the source of truth**: OpenAPI/AsyncAPI/`.proto` versioned in the repository, reviewed in the PR, with linting (Spectral or equivalent) and a compatibility diff in CI.
- Minimum REST conventions: plural resources, errors in a uniform format (RFC 9457 *problem details*), cursor pagination on collections that grow, filters documented in the contract, idempotency on `PUT`/`DELETE` and `Idempotency-Key` for `POST` with effects (payments, orders).
- Tolerant reader: consumers ignore unknown fields (no closed validation of the whole payload); that tolerance is what makes additive changes viable.
- **Backward compatibility is mandatory** within a major version: adding optional fields yes; renaming, removing or changing type/semantics, no. Protobuf: never reuse field numbers or change their type; use `reserved`.
- A breaking change ⇒ **a new major version published in parallel** (`/v2`, a new topic or a new event type), with a coexistence period and a retirement plan communicated to consumers. See the prohibitions in §7.
- Events with a **schema registry** and a `BACKWARD` compatibility policy (minimum) verified in CI; the event carries a schema identifier and version.

### Event design
- Distinguish and consciously choose the event type:
  - **Notification** (`OrderPlaced` + id): minimum schema coupling, but it triggers calls back to the producer — careful not to re-create synchronous coupling.
  - **Event-carried state transfer** (event carrying the state needed): removes the call back at the cost of more contract surface and more PII in transit (§5).
  - Internal **domain events** ≠ public integration events: do not publish the aggregate's internal events as they are; the public event is a curated, stable contract.
- Every event carries: `event_id` (unique, for deduplication), `occurred_at`, schema version, and a correlation/causation key for traceability.
- Name in the past tense and by business fact (`InvoiceIssued`), never by technical intent (`UpdateInvoiceRow`).

### Communication: synchronous versus events
- **Synchronous (REST/gRPC)** only when the caller needs the response to continue. Every synchronous call adds temporal coupling and multiplies the probability of failure: a chain of >2-3 synchronous hops is a *distributed monolith* smell.
- **Events** for state propagation and cross-domain flows. Non-negotiable rules:
  - **Consumer idempotency**: at-least-once delivery is the norm; deduplicate by business key or event id. Never assume end-to-end exactly-once.
  - **Transactional outbox** to publish events alongside state changes (same local transaction + relay/CDC). The "database then broker" double write is forbidden.
  - **Backpressure**: consumers with concurrency limits and monitored lag; producers that degrade or reject under pressure, never unbounded in-memory buffering.
  - **DLQ** with an alert and a reprocessing runbook; a poison message must not block the partition (retry limit before the DLQ).
  - Ordering is only guaranteed per partition: choose the partition key by the entity whose sequence matters.

### Data and transactions
- **A database per service**: each service owns its schema; no other service reads from or writes to it (not "read-only", not shared views). Data integration goes through APIs or events.
- **No distributed transactions** (2PC/XA forbidden between services). Consistency between services via **sagas**: prefer event choreography for simple flows, an explicit orchestrator for flows with complex compensation logic. Every step has a defined and tested compensation; intermediate states are visible and queryable.
- Saga rules: idempotent steps; per-step timeouts with a defined action (compensate or alert, never hung indefinitely); compensations are business operations (`CancelReservation`), not technical "rollbacks", and they can fail too — design the retry and the manual intervention (runbook).
- Cross-service queries: composition in the caller/gateway (small amounts of data) or a **local materialised view fed by events** (lightweight CQRS) for frequent reads; accept and communicate that view's eventual consistency. Solving them with JOINs against another service's database is forbidden.
- If a flow "needs" ACID across two services, the boundary is cut wrong: merge them.

## 4. Quality and testing

- **Contract testing is mandatory** between services: consumer-driven (Pact or equivalent) or schema compatibility verification in CI. A provider cannot merge a change that breaks a contract verified by a consumer.
- Pyramid: fast unit tests per service > contract tests > a few smoke E2E tests over critical flows. **Forbidden** to base confidence on massive E2E over the full environment (fragile, slow, does not scale with N services).
- Resilience tests: simulate a timeout, a 5xx error and a slow response from the *downstream* (Toxiproxy/WireMock); verify that circuit breakers trip and degradation is controlled, not only the happy path.
- Idempotency and redelivery tests: every event consumer is tested with duplicate and out-of-order messages.
- Saga tests: cover the happy path, failure at each step (does it compensate?) and failure of the compensation itself (alert + runbook?). A saga flow without compensation tests is not finished.
- Environments: each service is tested against contract-verified doubles of its dependencies, not against the full environment; the integrated environment is for smoke and exploration, not as a merge gate.
- CI gates: contract lint + compatibility diff + contract tests + build of the service in isolation. Main always green; every service independently deployable (if it cannot be, it is a distributed monolith).

## 5. Security and personal data

- **Internal zero-trust**: mTLS between services (ideally with workload identity such as SPIFFE/short-lived certificates); authn/authz in every service, not only at the gateway. No trust by network.
- **API gateway** as the single north-south entry point: TLS 1.2+/1.3 termination, token validation (OIDC/JWT with short expiry and audience/issuer verification), rate limiting, input validation against the contract.
- **Identity propagation**: the end user's identity travels with the request (propagated JWT or *token exchange*), it is not lost at the first hop; each service authorises with the user's context, not with the generic identity of the calling service. Scopes/permissions per service, not one omnipotent token.
- Least privilege on the broker: ACLs per service and topic (a service only produces/consumes what it declares).
- Validation at each service's edges: validate against the contract on input (do not trust that the gateway already validated) and encode output per context.
- Secrets out of the code and out of the image: secrets manager, ephemeral credentials, OIDC in CI.
- Supply chain: minimal non-root images, signed and verified before deployment; SBOM and scanning (SAST/SCA/images) as gates.
- **Personal data**: minimisation in events (publish identifiers and strictly what is needed, not the whole aggregate); classify topics carrying PII; for the right to erasure in immutable event logs use *crypto-shredding* (per-subject encryption with a destroyable key) or short retention + state in the owning service. A published event is an API and a replicated piece of data: think GDPR before publishing it.

## 6. Operability

- **End-to-end OpenTelemetry**: W3C `traceparent` context propagation over HTTP, gRPC and message headers; traces, metrics and logs **correlated** by trace_id. Structured logs (JSON) always.
- **Per-service SLOs** on symptoms (golden signals: p95/p99 latency, traffic, error rate, saturation) with an error budget; actionable alerts on the SLO, not on noisy internal causes. Consumer lag and DLQ depth are first-class SLIs in event systems.
- **Resilience by default** in every outbound client: explicit timeout (always; no timeout = a deferred incident), retries with **exponential backoff + jitter** only for idempotent operations and with a retry budget, a **circuit breaker** per dependency, **bulkheads** (pools/concurrency limits per dependency) and defined degradation (what do you answer when the downstream is down?).
- Separate health checks: liveness (process alive) versus readiness (dependencies ready); readiness must not chain transitive dependencies.
- End-to-end latency budget: distribute the request's SLO across hops (each hop's timeouts must be coherent with the caller's: decreasing downwards, never larger).
- Idempotency when serving too: endpoints that clients will retry (through their own retries) must tolerate repetition without double effects.
- Deployments: canary or rolling with tested automated rollback; N/N-1 compatibility between a service and its consumers during the rollout; feature flags to decouple deploy from release. Capacity: size with load data (partitions, replicas, pools), not by intuition; load-test before committing to an SLO.
- Every service with a minimum runbook: dependencies, dashboards, how to reprocess its DLQ, how to degrade it, who it wakes up. A service nobody knows how to operate is not "done".
- Shared templates/chassis for cross-cutting concerns (telemetry, health, resilience, authn): operational uniformity is achieved through the platform, not by copying code between services.

## 7. Sustainability and evolution

- **Strangler fig** to migrate monolith → services: extract one domain, route traffic gradually (facade/gateway), retire the old code when finished. Never a big-bang rewrite. Extraction order: first the domain with the most change/scale pressure and the least data coupling; extract the code first (module), then the data (its own database), in that order.
- **Formal deprecation policy**: every deprecated endpoint/event is announced (`Deprecation`/`Sunset` header in REST, contract changelog), with a retirement date and per-consumer usage telemetry; it is retired when usage is zero or the communicated deadline has passed — not earlier, and not "never".
- Contracts with a semantic *changelog* per version; consumers find out from the contract repository, not from the incident.
- **Expand/contract** for every contract or schema change: publish the new alongside the old, migrate consumers, measure that nobody uses the old any more (telemetry, not faith), retire. The retirement is part of the task, not implicit debt.
- **ADR mandatory** for one-way decisions: adopting microservices, cutting boundaries, choosing a broker, saga strategy, versioning. Short format: context, decision, alternatives, consequences. Two-way decisions are taken fast and reverted if they fail.

### List of prohibitions
- ❌ A breaking contract or event change without a new major version and a coexistence period.
- ❌ A database shared between services (including direct reads, views and "just this one JOIN").
- ❌ Distributed monolith: services that must be deployed together, versioned together or transact together.
- ❌ 2PC/XA or distributed transactions between services.
- ❌ Double write to database + broker without outbox/CDC.
- ❌ Non-idempotent consumers under at-least-once delivery.
- ❌ Outbound calls without a timeout, or retries without backoff+jitter, or retrying non-idempotent operations.
- ❌ Long synchronous chains (>3 hops) on a user request's path.
- ❌ Sharing entity/domain-model libraries between services.
- ❌ Events with no schema in a registry and no compatibility policy.
- ❌ Communication between services without TLS/mTLS or authz "because it is the internal network".
- ❌ Microservices without an ADR justifying the cost against a modular monolith.
- ❌ A service with no SLO, without propagated traces, or with logs lacking trace_id.
- ❌ Business logic in the gateway or in the mesh (only cross-cutting concerns there: routing, authn, rate limit, TLS).
- ❌ A saga without defined and tested compensations, or with invisible intermediate states.
- ❌ Deprecated endpoints retired without an announcement, usage telemetry and a communicated deadline.

Signs of wrongly cut boundaries (revisit the design, do not patch it): business changes that always touch several services at once; cascades of calls to render one screen; duplicated data that diverges with no clear owner; recurring coordinated releases.

## 8. Mandatory web verification

Before pinning any version, licence or recommendation from this document into a deliverable, **verify with WebSearch** (the data in §2 is from August 2026 and expires):

1. Kafka's stable version (is it still 4.2.x?) and the status of relevant KIPs (e.g. KIP-932 Queues, still preview in 4.1/4.2).
2. The current version of OpenAPI (3.2.x; the real status of 4.0 "Moonwalk") and AsyncAPI (3.x).
3. OpenTelemetry status per signal (profiles was alpha in March 2026) and the applicable semantic conventions.
4. Licences of the chosen brokers/registries (Confluent Community License versus Apache 2.0: Karapace/Apicurio).
5. CVEs and EOL of the versions you are going to recommend (endoflife.date).

If the web contradicts this document, **the web wins** — flag the discrepancy.
