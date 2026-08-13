---
name: mcp-standards
description: Model Context Protocol server and client engineering. Use when building or auditing an MCP server or client with the official SDKs (modelcontextprotocol typescript-sdk, python-sdk, go-sdk, csharp-sdk, FastMCP), declaring tools/resources/prompts primitives, choosing stdio versus Streamable HTTP transport, protocol-revision fields (server/discover, _meta, Mcp-Method/Mcp-Name headers, resultType, MRTR inputRequests, ttlMs/cacheScope), mcp.json / .mcp.json / claude_desktop_config.json server entries, server.json and the MCP registry, MCP authorization (RFC 9728 protected resource metadata, RFC 8707 resource indicators, Client ID Metadata Documents, PKCE S256), or triaging tool poisoning, rug pull, server shadowing, token passthrough and confused-deputy exposure in installed servers.
---

# Model Context Protocol (MCP) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **designing, implementing, auditing or operating MCP servers and clients**, and when
deciding whether MCP is even the right integration. Covers: the host/client/server model; the
primitives (`tools`, `resources`, `prompts`) and their status in the current revision; transports
(stdio and Streamable HTTP); the design of a server's tool surface;
authorisation (OAuth 2.1 as a *resource server*, RFC 9728, RFC 8707, CIMD); the class of risk
introduced by a third-party server running with your permissions; and operational governance
(inventory, versioning, updating, observability).

Triggers by artifact: `mcp.json`, `.mcp.json`, `claude_desktop_config.json`, `server.json`,
`@modelcontextprotocol/sdk`, `mcp` (PyPI), `FastMCP`, `go-sdk`/`csharp-sdk`,
`tools/list`, `tools/call`, `resources/read`, `prompts/get`, `server/discover`,
`subscriptions/listen`, `inputRequests`/`resultType`, `Mcp-Method`/`Mcp-Name` headers,
`WWW-Authenticate` with `resource_metadata`, `/.well-known/oauth-protected-resource`,
`mcp-scan`, "MCP server", "tool poisoning", "rug pull".

**Governing principle**: **an MCP server is not an API**. An API is consumed by a program that
validates the contract; an MCP server is consumed by a model that reads text and decides. The
tool's description **is** attack surface and **is** the functional specification.
Designing an MCP server as if it were a REST wrapper produces servers that are useless
(too many tools, gigantic outputs, opaque errors) and insecure.

**Not applicable**: see
`claude-api` (**the concrete implementation on the Anthropic side**: the Messages API's MCP
connector, `mcp_servers` + `mcp_toolset`, MCP in Managed Agents with vaults and `mcp_oauth`
credentials, the `anthropic.lib.tools.mcp` helpers, model IDs, `effort`, caching — all of that
is **theirs**; here we have the protocol and the design criteria, provider-agnostic);
`ai-agents-standards` (the autonomous loop, the iteration budget,
context management, multi-agent, the lethal trifecta — MCP is *a* mechanism for giving tools
to an agent, not the only one, and an MCP server is consumed from many hosts that are not your own
agents; the boundary is on the client side: **if you are deciding what the server exposes
and how it is authorised, it is this skill; if you are deciding how the agent chooses, iterates and
stops, it is theirs**);
`claude-code-skills-standards` (the context format for agents: `SKILL.md`, frontmatter,
activation — **a relevant boundary**, because skills and MCP are two different ways of giving
capability to an agent: a skill injects *instructions*, an MCP server exposes *execution*;
a skill does not execute anything by itself);
`api-design-standards` (**a boundary that gets confused daily**: OpenAPI/GraphQL/gRPC, HTTP
codes, pagination, versioning of the contract of an API consumed by a program; if the consumer
is deterministic, it is theirs);
`identity-access-management-standards` (**IdP design**: OAuth 2.1/OIDC flows, PKCE,
token issuance and validation, authorisation engines — the *use* of those flows in the
MCP protocol belongs to this skill);
`secrets-management-standards` (custody and rotation of the credentials MCP servers
consume), `cryptography-pki-standards` (TLS, artifact signing);
`appsec-standards` (classic vulnerability classes: SSRF, path traversal, command
injection — which is exactly what turns up in MCP server CVEs; the triage is theirs),
`vulnerability-management-standards` (the CVE/EPSS/KEV lifecycle of the installed servers),
`container-runtime-security-standards` (sandboxing the local server: seccomp, capabilities,
rootless), `firewall-policy-standards` (egress of the server and of the host),
`observability-standards` (OpenTelemetry: MCP documents `traceparent` propagation in
`_meta`, but the telemetry design is theirs),
`detection-engineering-standards` (detection rules over that telemetry),
`incident-response-forensics-standards` (responding to a compromised server),
`offensive-security-standards` (**authorised** offensive assessment of a server),
`python-standards`/`typescript-standards` (the idiom of the SDK's language),
`cicd-standards` (the pipeline that publishes and signs the server),
`privacy-engineering-standards` / `grc-compliance-standards` (personal data and governance).
Also: `llm-app-engineering-standards` (the single-turn LLM app or deterministic
pipeline — prompting, structured output, context window, cost per request).
Plus: `rag-standards`, `llm-evaluation-standards`, `mlsecops-standards`,
`ai-governance-standards`.

## 2. Default decisions

> Verify the current revision on the web before committing to anything (§8). **This protocol changes
> by dated revision and the 2026-07-28 one broke big things**: the data below expire.

| Decision | Default | Reason / alternative |
|---|---|---|
| Protocol revision | **`2026-07-28`** (final, published 28-Jul-2026; supersedes `2025-11-25`) | The versions are `YYYY-MM-DD` dates marking the last breaking change. Pin the revision explicitly; not "the latest" |
| Local transport | **stdio** | A child process of the host; no open port, no network surface. The default for every server running on the user's machine |
| Remote transport | **Streamable HTTP** | The original HTTP+SSE has been **deprecated since `2025-03-26`** and reclassified as *Deprecated* under the lifecycle policy in `2026-07-28`. It is not implemented in new code |
| Server state | **Stateless** | `2026-07-28` removes protocol sessions and the `Mcp-Session-Id` header; state between calls is carried in explicit *handles* minted by the server and passed as a tool argument |
| MCP server or a normal function? | **A normal function** if it is **one** in-house integration consumed by **one** in-house host | MCP solves M×N → M+N. With M=1 and N=1 it only adds a process, a transport, attack surface and a translation layer |
| Remote authorisation | **OAuth 2.1 with PKCE (S256)**; the MCP server is **only a *resource server*** | Never issue tokens from the MCP server. RFC 9728 (protected resource metadata) + RFC 8707 (`resource`) mandatory |
| OAuth client registration | **Client ID Metadata Documents (CIMD)** | Dynamic Client Registration (RFC 7591) is **deprecated** in `2026-07-28`; it dropped from SHOULD to MAY in `2025-11-25`. DCR only for compatibility with ASes that do not support CIMD |
| Number of tools per server | **Few and task-oriented** (single digits, not dozens) | Every definition takes up context on every turn and competes for the model's attention. Exposing a whole API is the most common antipattern |
| Schemas | A strict `inputSchema` with `additionalProperties: false`, explicit `required` and `enum` where applicable | The model fills in whatever the schema allows. A lax schema is an invitation to malformed calls |
| Tool output | **Bounded and paginated**; a hard size limit on the server | A tool that returns 200 KB poisons the host's context and ruins the prompt cache |
| SDK | **Tier 1**: TypeScript, Python, C#, Go | Tier 2: Java, Rust, Ruby. Tier 3: Swift, PHP, Kotlin. Verify the tier table before committing to a language |
| Server registry | The official registry **in preview**, not GA | `registry.modelcontextprotocol.io` still warns of possible *breaking changes* and data resets. It is not a chain of trust: **it does not validate security**. Use an internal/curated registry for production |
| Installing third-party servers | **Audit + pin the version by digest** | An MCP server is arbitrary execution with your permissions (§5) |

### Primitives and their status (revision `2026-07-28`)

Who controls what is half of the design:

| Primitive | Who controls it | Status |
|---|---|---|
| **Tools** (`tools/list`, `tools/call`) | **The model** decides to invoke it | Active. It is 90% of what gets built |
| **Resources** (`resources/list`, `resources/read`) | **The application** contributes them to the context | Active. `resources/subscribe`/`unsubscribe` replaced by `subscriptions/listen` |
| **Prompts** (`prompts/list`, `prompts/get`) | **The user** chooses them (menu, slash command) | Active. Little adopted by clients: verify host support before relying on them |
| **Sampling** (`sampling/createMessage`) | Server → client | **DEPRECATED** in `2026-07-28`. Suggested migration: integrate directly with the LLM provider's API |
| **Roots** (`roots/list`) | Server → client | **DEPRECATED**. Migration: pass directories/files as tool parameters, resource URIs or server configuration |
| **Logging** (`logging/setLevel`) | Server → client | **DEPRECATED**. Migration: `stderr` on stdio, or OpenTelemetry |
| **Elicitation** | Server → client | Replaced by the **MRTR** pattern (Multi Round-Trip Requests): the server returns `resultType: "input_required"` with `inputRequests`, and the client retries the original request with `inputResponses` |

**Design consequence**: do not build anything new on sampling, roots or logging —
they keep working during the deprecation window (a minimum of 12 months under the lifecycle
policy), but they are debt from day one. If a design "needs" sampling, almost
always what it needs is for the **host** to make the call to the model.

## 3. Structure and conventions

### Designing the tool surface

- **One tool = one user task**, not one endpoint. `create_issue_with_labels` is
  better than `POST /issues` + `POST /issues/{id}/labels` exposed separately: fewer turns,
  fewer intermediate states, fewer opportunities for error.
- **The description says *when* to call it, not just what it does.** "Query the status of a
  deployment. Use it when the user asks whether a change is already in production or why
  a release failed; **do not** use it to list historical deployments — for that, `list_deploys`."
  Purely declarative descriptions produce under-invocation in some models and
  over-invocation in others.
- **Stable names with a namespace of their own** (`acme_deploy_status`). Name collisions
  between servers are the way in for *shadowing* (§5).
- **A deterministic order** in `tools/list`: the current revision recommends returning the
  tools in a stable order so the client can cache and improve the *hit rate* of the model's
  prompt cache. A random order (iterating a `set`, an unordered `dict`) invalidates
  the cache on every turn.
- **Errors the model can recover from**: actionable text, not a stack trace or a
  `500 Internal Server Error`. "The repository `x/y` does not exist or you do not have access. Check
  the name or use `list_repos`." The model retries well with a message like that and loops
  with an opaque one.
- **Outputs bounded by design**: cursor pagination, explicit and announced truncation
  ("showing 20 of 431; use `cursor` to continue"), and field projection. Never
  return the source system's complete object "just in case".
- **Idempotency and effects**: mark in the description which tools mutate state and which do
  not; the host uses that distinction to parallelise the read ones and to ask for approval on the
  write ones.

### Configuration file and publishing

- Server entries in `mcp.json` / `.mcp.json` / the host's configuration: **a pinned version**
  (image digest or exact package version), never `latest` and never a branch.
- `server.json` for publishing to the registry: metadata and installation instructions; the
  artifacts still live in npm/PyPI/OCI, with the supply chain of those registries
  (and their risks — §5).
- **Version the server** with SemVer and declare the supported protocol revision. Changing
  the schema or the semantics of an existing tool is a breaking change **for the
  model** even if the JSON still validates.

### What is new in `2026-07-28` that affects the code

- There is no `initialize`/`notifications/initialized` handshake: every request carries the protocol
  version and the client's capabilities in `_meta`.
- `server/discover` is **mandatory** on the server, to announce supported versions,
  capabilities and identity.
- The `Mcp-Method` and `Mcp-Name` headers are mandatory on POST over Streamable HTTP — they let
  gateways, rate limiters and WAFs route and measure without parsing the body. The server rejects
  requests where the header and the body disagree.
- `ttlMs` and `cacheScope` (`public`/`private`) are mandatory in the results of `tools/list`,
  `prompts/list`, `resources/list`, `resources/read` and `resources/templates/list`.
- SSE stream resumption (`Last-Event-ID`) is removed: a broken stream loses the in-flight
  request and **the client must reissue it with a new ID** — which demands real idempotency
  in the write tools.
- `resultType` is mandatory in every result (`"complete"` or `"input_required"`).
- Tasks moves from experimental core to an **official extension** (`io.modelcontextprotocol/tasks`).

## 4. Quality and gates

Gates in increasing order of cost. The ones marked **[BLOCKS]** break the build or the deployment.

1. **[BLOCKS] Schema validation**: every `inputSchema` with `additionalProperties: false`
   and explicit `required`. A test that walks `tools/list` and verifies it.
2. **[BLOCKS] Output budget**: a test that exercises each tool with the most
   voluminous reasonable input and fails if the response exceeds the set limit (choose one and
   document it; the useful order of magnitude is a few thousand tokens, not hundreds of thousands).
3. **[BLOCKS] No *token passthrough***: a test that sends the server a token whose `aud` is not
   the server and checks that it is **rejected**. The specification forbids it with an explicit
   MUST NOT: *"MCP servers **MUST NOT** accept any tokens that were not explicitly issued for
   the MCP server."*
4. **[BLOCKS] Remote authorisation**: `/.well-known/oauth-protected-resource` (RFC 9728)
   served and correct; audience validation; PKCE S256; validation of the `iss` parameter in
   the authorisation response (RFC 9207) before exchanging the code.
5. **[BLOCKS] SCA + artifact scanning** of the server and of its transitive dependencies.
6. **Protocol conformance**: `server/discover` responds; the `Mcp-Method`/`Mcp-Name` headers
   verified against the body; `resultType` present; `ttlMs`/`cacheScope` present.
7. **`tools/list` determinism**: a test that calls twice and compares the order byte by byte.
8. **Edge and error testing**: invalid input, non-existent resource, permission denied,
   source system timeout — each returns an actionable error, not a dump.
9. **Testing with a real model**: a server can be correct and still be useless. Run
   a set of end-to-end tasks and measure the **task success rate**, not
   API coverage. If the model picks the wrong tool, the defect is in the
   description, not in the model.
10. **Description auditing** (`mcp-scan` or equivalent) over the servers you
    install: detection of embedded instructions and of overlap between servers.
11. **Pinning definitions**: hash each tool definition on approving it and alert
    when it changes (a direct mitigation of the *rug pull*, §5).

## 5. Security — the critical section

**Premise**: **an MCP server is third-party code running with your permissions.** A local
server is a binary you execute; a remote one is a service you hand context and
credentials to. The specification is explicit: without sandboxing and consent, one-click
installation allows *arbitrary code execution* with the client's privileges, and it warns
that *"Users have no insight into what commands are being executed."*

Everything that follows is **a risk class, an indicator and a mitigation**. Nothing here is an
exploitation procedure.

### Risk classes specific to MCP

| Class | What it is | Indicator | Mitigation |
|---|---|---|---|
| **Tool poisoning** | Instructions for the model hidden in the description, the schema or the result of a tool. The user sees a short name; the model reads the full text and obeys it. **The tool does not need to be invoked**: it is enough for it to be loaded in context | Disproportionately long descriptions, imperative text addressed to the assistant, invisible or control characters, references to other tools or to the user's files | Human review of every description before approval; automated scanning; render the **full** description in the approval UI, untruncated |
| **Rug pull** | The server changes the description **after** you trusted it. Most clients do not warn about the change | A definition hash different from the approved one | Pin the version by digest; hash definitions and **fail closed** on a change; explicit re-approval |
| **Cross-server shadowing** | A malicious server's description alters the agent's behaviour with tools from **another**, trusted server. Combined with a rug pull, it hijacks without appearing in the visible log | Colliding tool names; a description that mentions other servers' tools | Per-server namespaces; isolate servers by trust level; do not mix third-party servers with tools over sensitive data in the same session |
| **Confused deputy** | An MCP proxy with a static `client_id` before the third-party AS, dynamic client registration and a consent cookie allows obtaining authorisation codes **bypassing the user's consent** | An MCP proxy that does not store consent per `client_id` | The specification requires it: *"MCP proxy servers **MUST** implement per-client consent"* — a register of user-approved `client_id`s, checked **before** forwarding to the third-party AS; a `redirect_uri` validated by exact match; a single-use `state` created **only after** consent is approved |
| **Token passthrough** | The server accepts and forwards tokens not issued for it | Absence of `aud` validation | The MUST NOT of §4.3; RFC 8707 `resource` in the authorisation **and** token requests |
| **State handle hijacking** | With the stateless protocol, whoever guesses or obtains a *handle* accesses another user's state | Sequential or predictable handles | *"MCP servers **MUST NOT** treat possession of a state handle as authentication."* Securely random handles, bound to the authenticated user on the server side (`<user_id>:<handle>`), with expiry |
| **SSRF in the client** | The malicious server publishes OAuth discovery URLs pointing at `169.254.169.254`, `localhost` or private ranges | Client requests to internal IPs | Require HTTPS, block private/reserved/link-local ranges, validate redirect destinations, an egress proxy. **Do not implement the IP validation by hand** — the encoding tricks (octal, hex, IPv4-mapped IPv6) get through |
| **Dangerous URL scheme** | A `javascript:`, `data:`, `file:` authorisation URL from the server → XSS/RCE in the client | — | Allowlist `http`(loopback)/`https`; **never** open URLs via a shell |
| **Supply chain compromise** | A trojanised server published in a registry with accounts and personas created to give an appearance of legitimacy; the official registry **is not a chain of trust** and is still in preview | A new package, a maintainer with no history, no verifiable repository | An internal curated registry; code review; digest pinning; SBOM and signing; an inventory of what is installed |

### Hard rules

- **FORBIDDEN to install a third-party MCP server without auditing it**: code, dependencies,
  maintainer and the permissions it asks for. It is the same decision as installing a binary.
- **stdio by default for local servers**; if there is a local HTTP transport, require an
  authorisation token or a unix socket with restricted permissions. A local server listening on
  localhost with no auth is reachable by DNS rebinding from the browser.
- **Sandboxing the local server**: a container or a platform sandbox, a filesystem
  restricted to the necessary directories, no network beyond the indispensable, non-root. The
  specification lists it as a client SHOULD; treat it as a requirement of your own.
- **Least privilege in the server's credentials**: a token with the task's scope, not
  the administrator's. The specification explicitly discourages omnibus *scopes*
  (`*`, `all`, `full-access`) and publishing the full catalogue in `scopes_supported`.
- **Informed consent, per sensitive action**, not an "allow everything" at install time: the
  user must see the exact command untruncated, what is executed and with what privileges. A
  dialogue that truncates the tool's description turns consent into theatre.
- **Never** put secrets in descriptions, prompts, resources or results: they end up in the
  model's context, in the history and potentially in logs and summaries.
- The server **cannot trust** that the client applies any mitigation: it validates at its
  own edge.

### The reality of adoption (context, not an excuse)

Authorisation adoption in public MCP servers is **low** —in the order of single-digit
percentages according to ecosystem analyses in 2026, and a significant fraction of the
registered servers offer no effective authentication. Operational translation: **assume any
public server is unauthenticated and badly maintained until proven otherwise.**
The volume of CVEs against MCP implementations during 2026 is high, and the dominant classes
are classic ones —path traversal, command injection, missing authentication on a sibling
endpoint— not exotic ones: see `appsec-standards` for the triage.

## 6. Performance and operability

- **A mandatory inventory** of MCP servers installed per host and per user: origin,
  pinned version, credentials it consumes, permissions it holds, who approved it and when.
  Without an inventory there is no incident response and no vulnerability management. *Shadow MCP*
  —servers installed outside change control— is the most common governance failure.
- **Observability of invocations**: which tool, from which server, with which arguments
  (with the sensitive ones redacted), what result, what latency, what token cost. The
  current revision documents W3C/OpenTelemetry trace context propagation in `_meta`
  (`traceparent`, `tracestate`, `baggage`): use it to correlate the model's call with
  the execution on the server and with the request to the source system.
- **Caching**: honour `ttlMs` and `cacheScope`; `cacheScope: "private"` is **never** cached in a
  shared intermediary. A `tools/list` with an unstable order breaks the host's prompt cache
  and makes every turn more expensive.
- **Context budget**: a server's cost is not just its latency; it is the tokens
  its definitions occupy on **every** turn. Measure that cost and prune tools that are not
  used.
- **Stateless by design** (`2026-07-28`): a remote server must be able to run behind a
  round-robin load balancer with no sticky sessions. If yours needs affinity, the state is
  badly modelled.
- **Timeouts and limits** on every call to the source system; degradation with an actionable error
  instead of hanging the model's turn.
- **Updating**: a defined cadence, the changelog read (not applied blindly — an update is a
  rug pull vector), and re-approval when tool definitions change.

## 7. Sustainability and prohibitions

- **Review cadence**: this ecosystem moves by dated revision with a minimum deprecation
  window of 12 months. Review the protocol revision and the deprecations **every
  quarter**, not every year.
- **The server's own deprecation policy**: do not break the semantics of an existing tool;
  add a new one and mark the old one. The "consumer" is a model with prompts and
  evaluations built on top.

**FORBIDDEN**
- ❌ Standing up an MCP server for **one** in-house integration consumed by **one** in-house host: it is a function.
- ❌ Exposing a whole API as MCP tools, endpoint by endpoint.
- ❌ Tool descriptions that only say what the tool does and not **when** to use it.
- ❌ Lax schemas: no `additionalProperties: false`, no `required`, free `string` where an `enum` fits.
- ❌ Tools with unbounded output.
- ❌ Opaque errors (`500`, a stack trace) returned to the model.
- ❌ Implementing HTTP+SSE in new code (deprecated since `2025-03-26`).
- ❌ Building on **sampling**, **roots** or **logging**: deprecated in `2026-07-28`.
- ❌ Letting the MCP server act as an *authorization server* or issue tokens.
- ❌ Accepting or forwarding tokens not issued for the server (the specification's **MUST NOT**).
- ❌ Treating possession of a *state handle* as authentication.
- ❌ Dynamic Client Registration in new code: use CIMD.
- ❌ Installing third-party servers without auditing them, or from unverified registries.
- ❌ `latest` / a branch / an unpinned package in a server's configuration.
- ❌ A local server with an HTTP transport and no authentication.
- ❌ Running a local server without a sandbox and with broad filesystem access.
- ❌ A consent dialogue that truncates the description or the command: it is security theatre.
- ❌ Secrets in descriptions, prompts, resources or results.
- ❌ Treating the official registry as a chain of trust or as GA.
- ❌ Accepting a server update without reviewing changes to the tool definitions.
- ❌ Trusting that the client applies the mitigations: the server validates at its edge.

## 8. Mandatory web verification

Before committing to any version, field name, primitive or normative requirement:

1. **The specification's current revision** (`modelcontextprotocol.io/specification/...`) and its
   *changelog*: the versions are dates and the `2026-07-28` one removed sessions, the handshake,
   `ping`, `logging/setLevel` and stream resumption. Check whether there is a later one.
2. **The register of deprecated features** (`/specification/<rev>/deprecated`) and the lifecycle
   policy: sampling, roots and logging are in the deprecation window — confirm whether they have
   already been **removed**.
3. **The authorisation specification**: it has been revised several times. Confirm the status of
   RFC 9728, RFC 8707, PKCE S256, `iss` validation (RFC 9207) and the exact status of CIMD
   versus DCR.
4. **The Security Best Practices page** of the current revision: it is the normative source of the
   MUSTs/MUST NOTs cited in §5. Quote **verbatim** any requirement that decides something.
5. **The SDK tier table** (`/docs/sdk` and `/community/sdk-tiers`): the tiers change.
6. **The status of the official registry**: still in preview as of August 2026 — verify whether it has
   reached GA and what guarantees it gives.
7. **CVEs and incidents** in the specific servers you are going to install (not in "MCP" in the
   abstract): NVD/GHSA per package, plus the maintainer's history.
8. **The status of the extensions** (`tasks`, MCP Apps) and of neighbouring projects (A2A under the
   Linux Foundation) if the design depends on them.

### Declared gaps (not verified in this drafting)

- **Exact CVE figures and specific vulnerability IDs for MCP servers in 2026**: they are
  described as a class and an aggregate volume from secondary sources; **no IDs or CVSS scores are
  fixed here**. Verify in NVD/GHSA before citing any.
- **The exact percentage of public servers with OAuth implemented** and the size of the registry:
  a secondary-source datum, order of magnitude only.
- **The detail of the `io.modelcontextprotocol/tasks` extension and of MCP Apps**: not verified in
  depth; consult the extensions documentation before designing on them.
- **The status of `mcp-scan` and other description-auditing tools**: it is cited as a
  category; its current maintenance has not been verified.
- **OWASP's "MCP Top 10"**: mentioned by secondary sources as a separate project; not
  verified against OWASP's primary source.

If the web contradicts this document, **the web wins** — flag the discrepancy.
