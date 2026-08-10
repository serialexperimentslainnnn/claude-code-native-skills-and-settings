---
name: load-balancing-standards
description: Load balancing as a failure-handling decision, not just traffic sharing — health checks, draining and TLS termination are where the value is. Use when designing or reviewing a load balancer or reverse proxy, haproxy.cfg with backend/server/option httpchk/http-check/observe/agent-check, nginx.conf upstream blocks with proxy_pass, keepalive and max_fails, an Envoy bootstrap or xDS cluster with outlier detection and panic threshold, Traefik static and dynamic configuration with healthCheck and serversTransport, a Caddyfile reverse_proxy with lb_policy and health_uri, an AWS ALB/NLB target group, Azure Application Gateway or Front Door, GCP backend service, choosing between layer 4 and layer 7, round-robin versus least-connections versus consistent hashing and maglev, session affinity and sticky cookies, shallow versus deep health check endpoints and a health check that queries the database, rise and fall thresholds, connection draining and graceful shutdown during a rolling deploy, TLS termination, re-encryption, mTLS to backends or TCP passthrough with SNI routing, HTTP/2 and HTTP/3 (RFC 9114) on the proxy and its effect on balancing, keepalive versus idle timeouts, listen backlog and ephemeral port exhaustion, X-Forwarded-For and Forwarded (RFC 7239) trust and spoofing, PROXY protocol, rate limiting and SYN flood protection, VRRP (RFC 9568) or keepalived for the balancer itself, or stateless balancing with ECMP and anycast.
---

# Load balancing standards — sharing traffic is easy; failing well is not

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **designing, configuring and operating a load balancer or reverse proxy**: choice of layer,
balancing algorithm, health checking, draining and zero-downtime deployment, TLS termination,
HTTP protocols, high availability of the balancer itself, stateless balancing, and protection of the
service edge.

Triggers: `haproxy.cfg`, `nginx.conf` (`upstream`, `proxy_pass`), Envoy bootstrap/xDS,
`traefik.yml`, `Caddyfile` (`reverse_proxy`), `keepalived.conf`, `ipvsadm`, "target group", "backend
service", "health check", "readiness", "drain", "sticky session", "consistent hashing", "maglev",
"PROXY protocol", "X-Forwarded-For", "SNI passthrough", "ECMP", "anycast", "outlier detection".

**Not applicable** — the catalogue already splits this up: `networking-standards` is the **trunk** (proxies and
balancing as a principle, VLAN, MTU, addressing) and **already delegates the depth**, while
`routing-switching-standards` owns the campus, BGP policy and control-plane security
—**including the BGP announcement that makes anycast possible**—, `datacenter-fabric-standards` owns the
fabric, VXLAN/EVPN and lossless Ethernet, and `network-automation-standards` configuration as
code. Outwards: **caching and CDN belong to `caching-cdn-standards`**, **the service mesh and
discovery to `microservices-architecture-standards`**, **Service, Ingress and Gateway API to
`kubernetes-standards`**, filtering to `firewall-policy-standards`, identity and OIDC to
`identity-access-management-standards`, TLS and PKI to `cryptography-pki-standards`, metrics and dashboards
to `observability-standards`, the SLO to `sre-practice-standards`, **the measurement methodology and the
load model to `performance-engineering-standards`**, the reactive method to
`network-troubleshooting-standards`, **match-server session assignment to
`gaming-infrastructure-standards`** (a game server is stateful and non-interruptible:
**assigning a session is not balancing**, and applying draining or per-request health to it breaks it),
and the umbrella of `onprem-standards` (alongside
`datacenter-facilities-standards` and `hpc-standards`). Among the three
sibling skills of this batch: `wireless-standards` is the **access network**, this one the **service network** and
`high-speed-interconnect-standards` the **compute network**; **the domain's mistake is applying the
same criteria to all three**.

**Guiding principle**: **balancing is deciding what happens when something fails.** Sharing traffic is the
trivial part; **almost all the value is in the health check and in the draining**. A balancer with
a good algorithm and a bad health check sends traffic towards broken servers with
exemplary precision.

## 2. Default decisions

> Verify version, maintenance and **raw licence** before pinning any of these (§8).

| Decision | Default | Justifiable alternative / vetoed |
|---|---|---|
| Layer | **L7 (HTTP)** when you need to route by path/header, retry, terminate TLS or observe requests | **L4** when throughput rules, the protocol is not HTTP or the encryption must reach the backend intact |
| Algorithm | **Least connections** (or least requests) as a sensible default at L7 | Round-robin only with homogeneous backends and uniform requests; **consistent hashing** when there is state or per-backend caching |
| Persistence | **None**: stateless services and externalised sessions | Affinity cookie only as a patch with a retirement date; ❌ source-IP affinity (NAT and mobiles break it) |
| Health check | **Your own endpoint, shallow and cheap**, separate from business health | Deep check **only** with a different threshold and without taking down the whole pool; ❌ TCP connect as the only signal for HTTP |
| Draining | **Mandatory**: remove from the pool, wait for in-flight requests to finish, then stop | ❌ Kill the process and trust the client's retry |
| TLS | **Terminate at the balancer and re-encrypt towards the backend** | Passthrough when the backend must see the client certificate or compliance demands it; internal mTLS if the mesh does not cover it |
| Self-managed L7 proxy | **HAProxy** (core GPL-2.0, headers LGPL) for observability and traffic control; **Envoy** (Apache-2.0) when dynamic xDS is needed | **nginx**/**Angie** (both BSD-2-Clause) for familiarity; **Traefik** (MIT) in dynamic environments; **Caddy** (Apache-2.0) when the value is automatic ACME |
| High-throughput L4 | **IPVS** in the kernel for the classic case; **Cilium/XDP** with Maglev-style hashing and DSR for large scale | **Katran** only if you accept it is a low-cadence mirror of Meta's internal code; ❌ an L7 proxy as a throughput firewall |
| Balancer HA | **VRRP (RFC 9568) / keepalived** with **tested** failover; **ECMP + anycast** when the volume justifies it | ❌ A balancer with no peer, or a pair whose failover was never exercised |
| HTTP towards the client | **HTTP/2 enabled; HTTP/3 only after verifying the exact state in your proxy and version** | ❌ Assuming HTTP/3 is ready because the directive exists |
| HTTP towards the backend | **HTTP/1.1 with keepalive** unless there is a reason; H2 towards backends **changes the balancing** (§3) | ❌ No `keepalive` towards the backend and then blaming the network |

## 3. Design criteria

**L4 versus L7 — what you gain and what you lose**
- **L4** shares connections without understanding them: minimal cost per byte, any protocol, encryption
  intact. **You lose** routing by path or header, per-request retry, health with application
  semantics and **all HTTP observability**. **L7** gives you all of that, but **you pay** CPU, latency
  and a component that is part of your application's semantics (and of its attack surface).
- **Rule**: L4 for non-HTTP traffic and raw throughput; L7 as soon as the decision depends on the content.
  Mixing layers in cascade (L4 in front, L7 behind) is legitimate and often the right thing.

**Algorithms**
- **Round-robin**: only with identical backends and requests of similar cost; otherwise it concentrates the
  expensive ones in the same place. **Least connections**: a reasonable default because it approximates "who is least
  busy", with mandatory **slow start** (a freshly restarted backend has zero connections and
  takes an avalanche). **Two random choices** is cheap and very good with large lists.
- **Consistent hashing (Maglev, ketama)**: **mandatory** when the backend holds useful state per
  key —local cache, partitions, long sessions, per-tenant connections— and **when the set
  changes frequently**: a modulo-N hash reassigns *all* keys when a node is added or removed; the
  consistent one only its fraction. It is what allows several balancers to share the same way.

**Session persistence: it is a smell**
- Affinity ties a user to a server: it breaks draining, skews the sharing, turns every
  deployment into session loss and hides the real bug, which is **state in the process's memory**. If
  it exists, it is debt with an owner and a date; the solution is to move the session out. Legitimate exception:
  long-lived connections (WebSocket, SSE), where the affinity is of the connection, not a cookie.

**Health checks — the section that decides everything**
- **Shallow** (`/healthz`, no external dependencies) versus **deep** (are my dependencies
  responding?): useful, but **with different consequences**.
- **The capital danger**: a check that queries the database means that, when the database hiccups,
  **the whole pool is marked unhealthy at once** and the balancer withdraws 100% of the service for a
  problem that only degraded a part —the total outage is caused by the check, not the failure—.
  Mitigations: **separate liveness from readiness**, do not put shared dependencies into the
  check that governs the sharing, and a **panic threshold** (if more than X% of the pool is unhealthy,
  ignore health and share to all: degraded is better than switched off).
- **Threshold asymmetry**: go down fast (few failures), come back up slowly (several successes), so as not to
  oscillate. Intervals, timeouts and thresholds are declared, not inherited from the default; the **timeout must
  be smaller than the interval** or they overlap and falsify the state; and the check goes **by the same
  path** as the real traffic (same port, same TLS).
- **The application decides when it is ready**: `/readyz` must start failing **before** the
  process begins shutting down. That is the real mechanism of draining.

**Draining and zero-downtime deployment**
- Mandatory sequence: mark as unavailable → **wait for the balancer to notice** (≥ one
  full check cycle) → stop accepting new connections → finish the in-flight ones within a
  deadline → close. Skipping the wait is the usual cause of 502s during deployments. The
  grace period exceeds the longest legitimate request; long-lived connections are closed with an
  orderly signal (GOAWAY in H2). **Retries only on idempotent things** and with a budget: retrying
  everything under load turns a degradation into a storm.

**TLS**
- **Terminating at the balancer** simplifies certificates and gives visibility; **re-encrypting towards the
  backend** is the default when the internal leg is not physically trusted —"it's the internal network" is not
  an argument—, and **mTLS** when the balancer must prove who it is.
- **Passthrough** when the backend needs the client certificate or compliance forbids
  decrypting: it is routed by **SNI** and everything else is lost. It is a decision, not a default. On
  terminating you lose the real IP: **PROXY protocol** at L4, headers at L7 (§5).

**HTTP/2 and HTTP/3 on the balancer**
- **H2 towards the client** is the default. **H2 towards the backend changes the balancing**: it multiplexes many
  requests onto few connections, so balancing per connection stops sharing —you need
  **per-request** balancing, and even then a few persistent connections concentrate load—. It is the
  classic cause of "uneven balancing" after enabling internal H2.
- **H3/QUIC runs over UDP**: it changes the firewall, ECMP (hashing over UDP and the **Connection ID**),
  connection accounting and migration between networks. **Verify the exact state per proxy and
  version** (§8): maturity differs between the client-proxy and the proxy-backend direction.

**HA of the balancer itself**
- **The balancer is the single point of failure par excellence**: it concentrates all traffic and all
  connection state. A pair with VRRP (**RFC 9568**, which obsoletes 5798) or equivalent, with **exercised**
  failover, knowing that it **cuts in-flight connections** unless there is state synchronisation.
- **ECMP + anycast scales better**: N identical balancers announcing the same VIP, with no active-passive
  pair, no shared state and capacity that grows by adding nodes. The price: **a
  change in the set reshuffles the ECMP hash** and breaks connections, unless the nodes use consistent
  hashing towards the backends. It is what you need to know before buying a bigger appliance.

## 4. Quality gates

- **Validate the configuration before applying it** (`haproxy -c -f`, `nginx -t`, `envoy --mode validate`
  or the product's equivalent). A config that does not validate does not even reach staging.
- **Backend failure test with real traffic**: kill a backend and **measure** how many requests are
  lost and how long it takes to be withdrawn. If nobody has measured it, the number is unknown, not zero.
- **Zero-downtime deployment test** under load with **zero 5xx** as the acceptance criterion (it detects
  badly done draining), and a **negative health test**: degrade the shared dependency and
  verify that the whole pool is **not** withdrawn — the gate that prevents the total outage.
- **Balancer failover test**, including the **return** (it fails more than the outbound leg), and a **forwarding
  header test**: a spoofed `X-Forwarded-For` from outside and the application does not believe it.
  Config in the repo and applied by automation; a balancer that differs from its peer is a finding.

## 5. Security

- **`X-Forwarded-For` without trimming is a vulnerability.** It is a list that **anyone can
  prepend to**: if the application takes the first value, the attacker chooses their own IP and evades block
  lists, rate limits, geolocation and auditing. Rule: the edge balancer
  **overwrites** (does not append), or a **fixed and known** number of trusted proxies is counted from
  the right. The same goes for `Forwarded` (**RFC 7239**), `X-Forwarded-Proto/-Host` and `X-Real-IP`.
- **Strip at the edge every internal header** the application uses to decide (roles, "is
  internal", already-authenticated identity): an `X-Authenticated-User` that survives from outside is a
  complete authentication bypass.
- **Rate limiting at the balancer** by real IP and by credential/path, with 429 and limit headers:
  it protects even with the application saturated. Per-IP limits are bypassed behind NAT or CGNAT;
  combine them with per-identity limits.
- **Flood protection**: SYN cookies, per-source connection limits, aggressive handshake and header
  timeouts (Slowloris is killed with a header read timeout), maximum body and header
  size, and frame/stream limits in H2 (*rapid reset* is exhaustion, not throughput).
- **The balancer's own surface**: statistics and admin API **never** exposed;
  certificates with automatic renewal and an **expiry alert** (ciphers and TLS, in
  `cryptography-pki-standards`). And against **request desynchronisation** (*request
  smuggling*), which arises from proxy and backend interpreting
  `Content-Length`/`Transfer-Encoding` differently: reject ambiguous requests, normalise at the proxy and **keep
  versions up to date at both ends**.

## 6. Performance and operability

- **Signals that are always watched**: requests per second and per code, latency at **high
  percentiles** separating balancer queue from backend time, healthy versus configured backends,
  active connections and their **real distribution** per backend, retries and 502/503/504 by cause.
- **Overflow and queues**: the accept queue (`backlog`) and its kernel limit turn a
  burst into lost connections; it is sized and its **overflow is monitored**. A large `backlog`
  with no capacity behind it only swaps errors for latency.
- **Ephemeral port exhaustion**: opening a new connection per request towards few backends
  exhausts the source port range and fails intermittently. Solution: **keepalive towards the
  backend** with a sized pool, several source IPs if needed, and watch `TIME_WAIT`.
- **Timeout coherence**: the balancer's idle timeout must be **smaller** than the backend's keepalive;
  if the backend closes first, a dead connection gets reused and sporadic 502s appear
  —the hardest failure in the domain to reproduce. Write them in a table (client,
  balancer, backend, database) and verify they decrease. **Capacity**: size by
  real percentiles and by **concurrent connections**; TLS and H2 consume memory per connection.

## 7. Sustainability and prohibitions

- **Cadence**: **LTS/stable** branches versus the latest minor; quarterly review and on any CVE with
  relevant KEV/EPSS. The balancer is exposed: it is among the first to patch.
- **nginx ecosystem** (a datum that decides): nginx has belonged to **F5** since 2019; in 2024 its lead
  developer forked it into **freenginx** over governance disagreements, and since 2022 there is **Angie**,
  from former core developers. **All three share configuration and both forks are
  BSD-2-Clause**; nginx remains active (copyright through 2026), so it is not an emergency, but if
  you choose nginx **also decide whom you follow** and verify each one's release cadence.
- **Deprecation**: every retired backend, rule and certificate disappears from the configuration and from the
  inventory. A commented-out `server` is not documentation.

**FORBIDDEN**
- ❌ A balancer with no active health check, or with TCP connect as the only signal for HTTP.
- ❌ A health check that queries the database or another shared dependency and can
  mark the whole pool unhealthy at once, with no panic threshold.
- ❌ Deploying without draining: withdrawing from the pool and killing the process without waiting a health cycle.
- ❌ Permanent session affinity with no owner or retirement date; source-IP affinity.
- ❌ Trusting `X-Forwarded-For` or `Forwarded` received from the client without overwriting or trimming.
- ❌ Letting internal trust or identity headers through to the backend.
- ❌ A single balancer for something that matters; or a pair whose failover has never been tested.
- ❌ Retrying non-idempotent requests, or retrying with no maximum budget.
- ❌ Enabling HTTP/3 without verifying its state in the specific version or adjusting firewall and ECMP for UDP.
- ❌ Backends without `keepalive` (and then blaming the network for ephemeral port exhaustion), or
  a balancer idle timeout greater than the backend keepalive (phantom 502s).
- ❌ Exposing the balancer's statistics page or admin API.
- ❌ Modulo-N hashing over a backend set that changes; consistent or nothing.
- ❌ Terminating TLS and speaking in the clear to the backend "because it's the internal network", with no written decision.
- ❌ Going to production without having **measured** how many requests are lost when a backend goes down.

## 8. Mandatory web verification

**Methodology**: the RFCs, **one by one** against the `rfc-editor.org` JSON; the licences, **reading
the raw file** from the repository, not the GitHub label.

**RFCs verified Aug 2026**: **HTTP/3 = RFC 9114** (Jun 2022, Proposed Standard, nothing obsoleted);
**HTTP/2 = RFC 9113** (Jun 2022, Proposed Standard, **obsoletes 7540 and 8740** — citing RFC 7540 today is
a factual error); **the `Forwarded` header = RFC 7239** (Jun 2014, Proposed Standard); **VRRPv3 =
RFC 9568** (May 2024, Proposed Standard, **obsoletes RFC 5798**).

**Licences verified raw Aug 2026**: **HAProxy** — its `LICENSE` declares the core **GPL v2** with
the explicit intent of allowing external modules, and develops the headers scheme under LGPL:
**it is neither "plain GPL" nor MIT**. **nginx** — **2-clause** BSD, notice "Copyright (C) 2011-2026
Nginx, Inc." (active repository). **Angie** — the same BSD-2 text plus "Copyright (C) 2022-2026 Web
Server LLC": **a fork with an identical licence**, and its `LICENSE` is on the **`master` branch, not `main`**
(the usual path 404s and looks like a missing licence). **Envoy** and **Caddy** — **Apache-2.0**.
**Traefik** — **MIT**, in `LICENSE.md`, not `LICENSE`.

**Declared discrepancy**: sources diverge on HTTP/3 maturity in Envoy — the
downstream direction (client→proxy) is described as ready and the upstream one (proxy→backend) as alpha.
Treat it as unresolved and verify the documentation of **your** exact version.

**Declared gaps — DO NOT fill from memory**:
1. **Current stable versions and support windows** of HAProxy, nginx, Angie, freenginx, Envoy,
   Traefik and Caddy: **deliberately not pinned here**; in particular, **freenginx's release cadence and
   health** are not verified.
2. **Exact HTTP/3 state per proxy and version**, with its TLS-with-QUIC library dependencies and
   connection migration: **not verified product by product**.
3. **Managed cloud balancers** (ALB/NLB, Application Gateway/Front Door, backend services):
   limits, draining, health semantics and HTTP/3 **not verified here**; they belong to `aws/azure/gcp`.
4. **Katran** is active but low-cadence and a mirror of Meta's internal code; **Cilium/XDP and IPVS are not
   pinned by version**. And the **concrete values** of `backlog`, health thresholds, grace
   periods and pool sizes are engineering criteria, **not measurements**: they are derived by measuring.

If the web contradicts this document, **the web wins** — flag the discrepancy.
