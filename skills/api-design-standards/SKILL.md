---
name: api-design-standards
description: REST, GraphQL and gRPC API design standards. Use when writing or reviewing openapi.yaml/swagger.json, .graphql/.proto schemas, .spectral.yaml or redocly.yaml, HTTP status codes, pagination, ETags, RFC 9457 problem details, idempotency keys, rate-limit headers or webhook signatures.
---

# API design standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, reviewing or evolving the **contract** of an API and its governance: `openapi.yaml`/`openapi.json`/`swagger.json`, `.graphql`/`.graphqls` files, `.proto`, `.spectral.yaml`/`.spectral.js`, `redocly.yaml`, `buf.yaml`/`buf.gen.yaml`, example collections and developer portals. Triggers: HTTP verbs and status codes, ETags and conditional requests, pagination, filtering, error format, `Idempotency-Key`, quota headers, versioning and `Deprecation`/`Sunset`, GraphQL schema, protobuf evolution, webhooks and payload signing, asynchronous operations, bulk endpoints, API gateway.

Guiding principle: **the contract is the product and it is irrevocable in practice**. A published endpoint has consumers you do not control; every design decision is taken knowing that withdrawing it will cost months of coexistence and communication (§7). Design the contract first, generate the code afterwards — never the other way round.

**Not applicable**: see `microservices-architecture-standards` (topology, cutting boundaries between services, AsyncAPI contracts and event design, sagas, distributed resilience), the language skills —`python-standards`, `typescript-standards`, `go-standards`, `rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`— (concrete framework implementation: routing, serialisation, DI), `appsec-standards` (threat modelling and finding triage), `identity-access-management-standards` (OAuth 2.1/OIDC flows, PKCE, token issuance and validation, authorisation engines), `cicd-standards` (the pipeline that runs the §4 gates), `i18n-standards` (**the contract fixes the interchange format** —ISO 8601 with zone, amounts in minor units with their ISO 4217 code, BCP 47 tags and negotiation via `Accept-Language`—; **how that is presented to the user in their language and region is theirs**. The rule that avoids the classic bug: **an API does not return pre-formatted text nor dates without a zone**), `solidity-standards` (a boundary worth naming: **a contract's ABI is also a public contract**, but with a difference that inverts this skill's criteria: **it is immutable and it is not versioned**. There is no `/v2`, no orderly deprecation and no migration window; what is deployed stays. The design of that interface and its evolution via proxy are theirs).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Style | **REST over HTTP/JSON**, *contract-first* design | GraphQL if the problem is multi-source aggregation for heterogeneous clients; gRPC for high-performance internal RPC |
| Contract format | **OpenAPI 3.2.0** (stable since Sept 2025; migration from 3.1 without breakage) | 3.1 if critical tooling does not support 3.2 yet |
| OpenAPI 4.0 "Moonwalk" | **Do not use**: no release and no date; the OAI itself recommends 3.x | — |
| Contract linter | **vacuum** (Go, 100% compatible with Spectral rulesets, supports OAS 3.0/3.1/3.2) or **Redocly CLI** (`@redocly/cli` 2.x, ESM-only, Node ≥ 22.12) | Spectral only in repos already built on it (§7: degraded maintenance, no 3.2 support) |
| Error format | **RFC 9457** *problem details* (`application/problem+json`), obsoletes RFC 7807 | — |
| Collection pagination | **Cursor/keyset** | Offset only in small, bounded catalogues with a stable order |
| `POST` idempotency | **`Idempotency-Key`** header (still an I-D, not an RFC) | — |
| Quotas | `RateLimit` / `RateLimit-Policy` headers from the `httpapi-ratelimit-headers` I-D | `X-RateLimit-*` only for compatibility with existing clients |
| Deprecation | **RFC 9745** (`Deprecation`) + **RFC 8594** (`Sunset`) | — |
| Versioning | **Major in the path** (`/v1`), additive within the major | Header/media-type versioning only with governance and tooling that support it |
| Webhook signing | **HMAC-SHA256** over `id.timestamp.payload` (Standard Webhooks scheme) | RFC 9421 (HTTP Message Signatures) if you need asymmetric signing or rotation without a shared secret |
| gRPC schema | **proto3** | Editions (`edition = "2024"`) only with a deliberate migration (§3.9) |
| Protobuf breaking changes | **`buf breaking`** in CI against the base branch | — |

## 3. Structure and conventions

### 3.1 Resource modelling and HTTP semantics

- Resources = **plural nouns**, lowercase, `kebab-case` in the path (`/payment-methods/{id}`), JSON fields with a single convention per API (`snake_case` or `camelCase`, chosen and linted). Never verbs in the path except for actions that are not resources (`/orders/{id}/cancel`) — and those, minimal and documented.
- Maximum nesting **two levels** (`/orders/{id}/items`); deeper than that, expose the subresource as a root with a filter.
- Non-negotiable semantics: `GET`/`HEAD` **safe** (they never mutate state, not even "just a counter"); `PUT`, `DELETE` idempotent; `PATCH` not idempotent unless explicitly designed to be; `POST` neither safe nor idempotent → §3.5.
- `PATCH` with a **declared media type**: `application/merge-patch+json` (merge semantics, `null` deletes) or `application/json-patch+json` (operations). A "hand-rolled PATCH" with no media type and no documented `null` semantics is forbidden.
- Status codes with meaning, not decorative: `201` + `Location` on creation; `202` for asynchronous acceptance (§3.7); `204` with no body; `400` syntax/validation, `401` no valid credential, `403` valid credential without permission, `404` to hide existence when revealing it leaks information, `409` state conflict, `412` precondition failed, `422` invalid semantics, `429` quota, `503` + `Retry-After` on unavailability. **Forbidden**: `200` with `{"error": ...}` inside.
- Errors with **RFC 9457**: `type` (stable URI that resolves to documentation), `title`, `status`, `detail`, `instance` + your own extensions (e.g. `errors[]` per field). Register the `type` values in a versioned catalogue of the contract; `detail` is for humans, `type` for machines. Never stack traces, internal paths or SQL in the error body.
- Dates in **RFC 3339/ISO 8601 with offset** (UTC by default), money in integer minor units + ISO 4217, closed enumerations documented and extensible (clients must tolerate new values).

### 3.2 Conditional requests and caching

- Every individual-resource response carries an **`ETag`**; `PUT`/`PATCH`/`DELETE` on it require `If-Match` to avoid *lost update*: without `If-Match` → `428 Precondition Required` (policy) or documented explicit acceptance; with a stale `If-Match` → `412`.
- `GET` with `If-None-Match` → `304` with no body. Weak ETag (`W/"…"`) if the representation varies in irrelevant details.
- Explicit `Cache-Control` in **every** response (including private ones: `no-store` for sensitive data) and correct `Vary` when the response depends on `Accept`, `Accept-Language` or authentication. An endpoint with no declared caching policy will end up cached by someone.

### 3.3 Pagination, filtering, sorting and sparse fieldsets

- **Opaque cursor** (`?limit=&cursor=`) with response `{ data: [...], next_cursor|links.next }`. The cursor is opaque by contract: clients do not parse it and you can change its encoding. Always include a `limit` **with a server-enforced maximum** (e.g. 100) and a documented default.
- Offset (`?page=&per_page=`) only with a small, bounded set and a stable order: it is O(n) in the database and produces duplicates/skips under concurrent writes. Keyset (`?after_id=&after_created_at=`) when you need a stable natural order without opacity.
- `total_count` **optional and on demand** (`?include_total=true`): always computing it is the hidden cost that kills a large collection.
- Filtering and sorting with an **allowlist declared in the contract** (`?status=active&sort=-created_at`): no translating arbitrary parameters into the query (injection and DoS via a non-existent index). Maximum number of sort fields and of combinable filters, documented.
- *Sparse fieldsets* (`?fields=id,name`) to reduce payload; if the API is an aggregation tree with many shapes per client, that is the signal that the case belongs to GraphQL (§3.8), not to infinite parameters.

### 3.4 Versioning and deprecation

- **Major version in the path** (`/v1/…`). Within a major, only **additive** changes: new optional fields, new endpoints, new values in extensible enums. Renaming, removing, changing a type, tightening validation or changing semantics **is breaking** even if the schema "compiles".
- Clients are *tolerant readers*: they ignore unknown fields. Document it as a consumer requirement; it is what makes additive evolution viable.
- Retirement cycle: publish `vN+1` → announce → **`Deprecation`** (RFC 9745) in the `vN` responses → **`Sunset`** (RFC 8594) with a date ≥ the `Deprecation` one → `Link` with `rel="deprecation"`/`rel="sunset"` to the migration guide → measure usage per consumer → retire. Minimum window published in writing (typical: 6-12 months in public APIs).
- Retirement is decided with **per-consumer telemetry**, not with faith. Without usage metrics per version and per client, deprecation is impossible.

### 3.5 Idempotency and unsafe operations

- `POST` with business effects (payments, orders, shipments) accepts **`Idempotency-Key`** (UUID generated by the client). Contract: same key + same payload → same stored response; same key + different payload → `422`/`409` (do not execute); new key → execute. Declared retention TTL (24h typical) and later purge.
- Deduplication is implemented with a **uniqueness constraint in the database**, not with a preceding `SELECT`: real concurrency is the test case (§4).
- Key state: store `in_progress` so that two simultaneous requests with the same key do not execute twice (`409` to the second one, or wait).

### 3.6 Bulk and batch endpoints

- Only when there is evidence of N+1 in the client; not by default. **Explicit** semantics: either all-or-nothing (transactional, global `400`) or partial with a `207`-equivalent detailing the per-element result with its own problem detail. Ambiguity here = guaranteed incident.
- Hard limit on elements per batch, documented and validated. A large bulk ⇒ turn it into an asynchronous operation (§3.7).

### 3.7 Asynchronous and long-running operations

- `POST` → **`202 Accepted`** + `Location` to the operation resource + `Retry-After`. `GET /operations/{id}` returns `{status: pending|running|succeeded|failed, result|error}` with the error in RFC 9457 format.
- The operation is a **first-class resource** with a stable id, timestamps and declared retention; it can be queried after it finishes. Explicit cancellation (`POST /operations/{id}/cancel`) if the business needs it.
- Completion notification by **webhook** (§3.10) in addition to polling; polling is the always-available fallback, never the only mechanism in long operations.

### 3.8 GraphQL

- Applies when the client needs to **choose the shape of the data** across many sources. It is not a "modern" alternative to REST: it trades the over-fetching problem for the cost of arbitrary queries.
- Schema: stable naming (`PascalCase` types, `camelCase` fields), deliberate nullability (not everything nullable "just in case"), **Relay connections** pagination (`edges`/`node`/`pageInfo`), mutations with a single input type and a payload with typed domain errors (business errors are schema data, not entries in `errors[]`).
- **N+1 must be solved with a dataloader** (batch + per-request cache). A resolver that queries per element in a list is a performance bug, not a pending optimisation.
- Hard limits in production: **maximum depth**, **complexity/cost per query** with a per-client budget, alias and batching limits (array batching is an attack multiplier), execution timeout.
- **Persisted operations / trusted documents** as an allowlist in first-party clients: the client sends an id, the server only executes known documents. Distinguish them from **APQ** (Automatic Persisted Queries), which is bandwidth saving and is **not** a security control. For public APIs the allowlist is not viable → depth/cost limits + rate limiting are mandatory.
- Introspection disabled in production (defence in depth, not a barrier: assume the schema can be inferred). `GET` only for read queries and with CSRF protection; `application/graphql-response+json` as the response media type.
- Evolution: GraphQL does not version; fields are **deprecated** (`@deprecated(reason:)`) and retired with per-field usage telemetry. `@defer`/`@stream` are still **outside the ratified spec**: do not put them in the public contract (§8).

### 3.9 gRPC and protobuf

- Wire compatibility is the schema's responsibility: **never reuse field numbers or change their type**; use `reserved` for retired numbers and names. New fields always optional with a sensible default.
- Enums: reserve value `0` as `UNSPECIFIED`; adding values is additive, removing them is not.
- `buf breaking` against the base branch as a CI gate (§4) and `buf lint` with the standard ruleset. Schema registry (BSR or equivalent) if there are external consumers.
- **proto3 by default**: Editions (`edition = "2023"/"2024"`) brings no new functionality and changes sensitive defaults (`features.field_presence` becomes `EXPLICIT`), which turns a careless migration into a breaking change. Migrate only with a plan and verification (§8).
- Errors: `google.rpc.Status` with canonical codes; the mapping to HTTP is documented if there is a gRPC↔REST gateway.

### 3.10 Webhooks

- Payload signed with **HMAC-SHA256 over `id.timestamp.payload`** (concatenated with `.`), headers `webhook-id`, `webhook-timestamp`, `webhook-signature`. The receiver verifies **over the raw bytes** of the body, before deserialising.
- **Anti-replay**: reject timestamps outside a tolerance window (300 s is the value recommended by Standard Webhooks and Stripe's default) **and** deduplicate by `webhook-id` as an idempotency key. Both, not one.
- Signature comparison in **constant time**. Support for **multiple active secrets** for rotation without downtime (sign with the new one, accept both during the window).
- At-least-once delivery with retries and exponential backoff + jitter, attempt limit, manual redelivery endpoint and visibility of the attempt history. The consumer replies `2xx` **fast** and processes in the background; the sender's short timeout is documented.
- Controlled egress: published list of outbound IPs or mTLS; the receiver validates that the destination is theirs. On the side that registers webhook URLs, validate against **SSRF** (no private/loopback/metadata IPs, no redirects to internal ranges).

### 3.11 HATEOAS, with judgement

- Full hypermedia (HAL, JSON:API, Siren) only pays off when there are generic clients or flows with state-dependent transitions. In APIs consumed by first-party clients it generates cost with no return.
- Practical rule: include `links` for **pagination**, for **related resources** and for **actions available depending on state** (`cancelable`), and nothing else. Do not invent a hypermedia engine nobody is going to use.

## 4. Quality and CI gates

In increasing order of cost; all of them block the merge (main always green):

1. **Structural validation** of the contract (`redocly lint` / `vacuum lint` / `buf lint`): breaks if the document is not valid for the declared version.
2. **Your own style ruleset** versioned in the repo (naming, plural, unique `operationId`, mandatory `description`, examples, `4xx`/`5xx` declared with `application/problem+json`, `security` present in every operation). The ruleset is what turns "good practices" into a gate.
3. **Compatibility diff** against the published version: `redocly` / `oasdiff` for OpenAPI, `buf breaking` for protobuf, GraphQL schema check (`graphql-inspector` or equivalent). A breaking change without a major bump breaks the build.
4. **Contract tests**: the server is validated against its own contract (request/response validation in integration tests) and the key consumers against verified doubles. Generating client and server from the same contract proves nothing: validate real responses.
5. **Mandatory edge tests**, not just the happy path: pagination on the last element and with an invalid/expired cursor; stale `If-Match` → `412`; **concurrently** repeated `Idempotency-Key` (two simultaneous requests, not sequential); payload at the limit and above the limit; unknown enum; `429` with correct quota headers; webhook with an invalid signature, an expired timestamp and a duplicated id.
6. **Contract examples validated against their schemas** (an example that does not validate is false documentation) and documentation generated in CI.

## 5. Security

- Reference: **OWASP API Security Top 10 — 2023 edition** (still the current one as of Aug 2026; there is no 2026 edition despite what third-party blogs announce). Real priority: BOLA/BOPLA (object-level and property-level authorisation) and API inventory.
- **Object-level authorisation on every endpoint**: the id existing does not mean it belongs to the caller. Forbidden to rely on unguessable ids as an access control. **Property-level** authorisation too: do not serialise the whole model (`role`, `internal_notes`) nor accept mass binding — allowlist of input and output fields.
- Authentication: **OAuth 2.1 / OIDC with short-lived tokens** for user access and `client_credentials` for machine-to-machine; verify `iss`, `aud`, `exp` and the signature in **every** service. API keys only for application identification and quota, never as the sole authentication for sensitive operations; if they exist, with an identifiable prefix, hashed at rest, scoped and rotated. **Forbidden**: long-lived tokens without rotation, secrets in the query string, `Basic` outside an internal channel with mTLS.
- Declare `security` **per operation** in the contract, not only globally: an endpoint that forgot to inherit it is an open endpoint.
- **Strict validation at the boundary** against the contract schema: types, formats, lengths, ranges, `additionalProperties: false` where applicable, maximum body size and JSON depth. Reject what does not fit; do not "sanitise" by guessing.
- Rate limiting **per identity and per operation** (not just per IP), with differentiated cost for expensive endpoints; `429` + `Retry-After` + quota headers. Global concurrency limit and page-size limit as protection against application-level DoS.
- Never leak existence, internal structure, versions or traces in the error: the RFC 9457 `detail` is written by you, not by the framework. Correlate with a `trace_id` in the response for support.
- Restrictive CORS: explicit origin, never reflecting the `Origin` with `Access-Control-Allow-Credentials: true`.
- **Inventory**: every deployed API is in the catalogue with an owner, version and status. *Shadow* APIs and the versions "nobody uses any more" but that still respond are the recurring audit finding.

## 6. Performance and operability

- **Latency budget per endpoint** and SLO published in the portal (p95/p99 + availability). Without an SLO, the API has no operational contract.
- Metrics per operation (`operationId`, not per URL with ids): latency, error rate by code, quota usage, and **usage per version and per consumer** (indispensable for §3.4).
- Negotiated compression, known `Content-Length`, streaming (SSE or chunked) for large responses — OpenAPI 3.2 already describes streaming natively.
- **API gateway** for cross-cutting concerns: TLS 1.2+/1.3, authn, rate limiting, validation against the contract, observability. Forbidden to put business logic or domain-specific payload transformations in the gateway.
- Developer portal generated **from the contract** (never written by hand in parallel): reference, authentication guide, changelog per version, catalogue of error `type`s, test environment and deprecation policy. Documentation that diverges from the contract = false documentation.
- Sandbox/mock server generated from the contract so consumers can integrate before the implementation exists.

## 7. Sustainability and governance

- **Design-first**: the contract is reviewed in a PR before implementing, with an API reviewer other than the author in public APIs. Contract review is a human gate, not a formality.
- Style ruleset **shared across the organisation's APIs**, versioned and with a process for changing it. Consistency between APIs is a product attribute.
- ADR for one-way decisions: style (REST/GraphQL/gRPC), versioning scheme, error format, authentication model, deprecation policy.
- **Written and published** breaking-change policy: what counts as breaking, minimum coexistence window, notification channel, support commitment per major version. In public APIs it is a contractual commitment, not an intention.
- Cadence: quarterly review of the inventory (live versions, usage per consumer, retirement candidates) and of the tooling versions (§8).

### FORBIDDEN
- ❌ Breaking change within a major version (renaming/removing fields, changing type or semantics, tightening input validation).
- ❌ `200 OK` with an error in the body; errors without RFC 9457; `detail` with a stack trace, SQL or internal paths.
- ❌ `GET` that mutates state; `POST` with effects and no `Idempotency-Key` support.
- ❌ Offset pagination in collections that grow; a collection with no server-enforced maximum `limit`.
- ❌ Filters or sorting built from arbitrary parameters without an allowlist.
- ❌ Authorisation based on unguessable ids; serialising the full internal model; mass binding of the input.
- ❌ An endpoint with no `security` declared in the contract, or with no object-level authorisation.
- ❌ Deprecating without `Deprecation`/`Sunset`, without a published deadline and without per-consumer usage telemetry.
- ❌ Retiring a version before the communicated deadline — or leaving it alive indefinitely "just in case".
- ❌ Documentation written by hand in parallel to the contract; examples that do not validate against their schema.
- ❌ GraphQL in production without depth/complexity limits, without a dataloader or with introspection open.
- ❌ Confusing APQ with an operation allowlist and calling it a security control.
- ❌ Reusing protobuf field numbers or changing their type; publishing `.proto` without `buf breaking` in CI.
- ❌ Webhooks without a signature, without a timestamp tolerance window or without deduplication by id.
- ❌ Accepting webhook URLs without anti-SSRF validation.
- ❌ Adopting OpenAPI 4.0 "Moonwalk" in a real project (there is no release).
- ❌ Business logic in the API gateway.

## 8. Mandatory web verification

Before committing any fact from this document to a deliverable, **look it up — do not recall it**:

1. **OpenAPI**: current stable version (3.2.0 since Sept 2025) and the real status of 4.0/Moonwalk in `github.com/OAI/sig-moonwalk` and `openapis.org` — as of Aug 2026 it still has no date and the OAI itself recommends 3.x.
2. **RFCs and drafts** in `datatracker.ietf.org` before citing them: RFC 9457 (problem details, Jul 2023, obsoletes 7807) ✔; RFC 9745 (`Deprecation`) ✔; RFC 8594 (`Sunset`, informational) ✔; RFC 9110 (HTTP Semantics) ✔; RFC 9651 (Structured Fields) ✔. **Careful**: RFC 9331 is **not** rate limiting, it is ECN/L4S — the quota headers are still in `draft-ietf-httpapi-ratelimit-headers` (rev. -11, May 2026, expires Nov 2026) and their **syntax has changed several times** (today `RateLimit-Policy: "sliding";q=12;w=1` / `RateLimit: "sliding";q=12;r=1;t=1`): verify the current revision before implementing it. `Idempotency-Key` is still an I-D, not an RFC.
3. **Linters**: latest version of Redocly CLI (`@redocly/cli`, 2.x, ESM-only, Node ≥ 22.12) and vacuum, and their OAS 3.2 support. Maintenance status of Spectral (heavily degraded activity in 2025-2026, no 3.2 support; a community fork exists) before choosing it for a new project.
4. **GraphQL**: current ratified edition (September2025 at `spec.graphql.org`) and the status of `@defer`/`@stream` and incremental delivery — as of Aug 2026 they were still pending in the spec despite being in graphql-js v17+. Status of the standardisation of *persisted documents* in GraphQL-over-HTTP.
5. **Protobuf/gRPC**: Buf CLI version and its current guidance on Editions vs proto3 (`buf.build/docs`, `protobuf.dev/editions`) — the conservative recommendation cited here is from 2024.
6. **Webhooks**: current revision of the Standard Webhooks spec (`standardwebhooks.com`) and of RFC 9421 before pinning headers or algorithm.
7. **OWASP API Security Top 10**: current official edition at `owasp.org/API-Security` — as of Aug 2026 it is the **2023** one; articles titled "2026" repackage that list.
8. CVEs and EOL of any gateway, GraphQL server or library you recommend (`endoflife.date`, project advisories).

If the web contradicts this document, **the web wins** — flag the discrepancy.
