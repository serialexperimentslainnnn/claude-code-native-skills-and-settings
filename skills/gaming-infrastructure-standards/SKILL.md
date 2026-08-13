---
name: gaming-infrastructure-standards
description: Multiplayer game hosting infrastructure. Use when orchestrating dedicated game servers with Agones (GameServer, Fleet, FleetAutoscaler CRDs, agones-sdk), running session-based servers on Kubernetes, matchmaking as a service (Open Match / open-match2, matchmaker tickets and backfill), managed backends (Amazon GameLift Servers, Azure PlayFab Multiplayer Servers, Unity Multiplay, Epic Online Services, Nakama/Heroic Labs, Edgegap), fleet scaling and cost per CCU or per session, UDP DDoS protection for game traffic, server browser and session allocation, or in-game voice/chat services and their compliance.
---

# Game infrastructure standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **infrastructure that hosts multiplayer**: hosting and orchestration of dedicated
match servers, session allocation and lifecycle, fleet scaling and cost,
matchmaking as a service, managed backends, protecting UDP traffic, and voice/chat services with
their compliance. This skill exists by an agreed cession: `game-development-standards`
cedes it **dedicated servers, session orchestration, fleet scaling and cost, transport and
matchmaking as a service**, and `xr-standards` cedes it **multi-user servers and sessions**.

**Thesis**: a match server **is not a microservice**. It is a **stateful, short-lived,
non-interruptible** process: it is not load-balanced per request, it does not drain in seconds, and
it is not killed by a rolling update without throwing players out. The whole discipline of this
skill derives from that: session allocation instead of load balancing, shutdown only when the match
ends, scaling that protects live sessions, and cost measured per session/CCU because the idle fleet
is the dominant cost.

Triggers: `GameServer`, `Fleet`, `GameServerAllocation`, `FleetAutoscaler`, agones-sdk,
`Allocated`/`Ready` states; Open Match tickets/backfill; GameLift (`fleet`, `game session`,
FlexMatch), PlayFab MPS (build, pool, allocation), Multiplay, EOS, Nakama, Edgegap; "how much does
each match cost us", "the autoscaler kills live matches", "they take our server down with a UDP flood",
server browser, proximity voice.

**Not applicable**: see `game-development-standards` (**the game's protocol and authority model
are theirs**: netcode, prediction/reconciliation, lockstep, anticheat, server-side validation —
here the server process already exists and is treated as a workload to host),
`xr-standards` (the XR experience and its comfort budget; here its multi-user sessions),
`kubernetes-standards` (the cluster as a platform: RBAC, upgrades, nodes — here what is specific
to the game workload running on it), `load-balancing-standards` (the classic L4/L7 balancer; the
session allocation here is precisely **not** balancing), `edge-computing-standards` (the edge
platform in general; here only the criterion of placing servers close to the player),
`e-commerce-standards` and `fintech-payments-standards` (**the game's shop is a shop**: the
catalogue, price, tax and cart belong to the first; **from the charge onwards — gateway, PCI DSS,
SCA, refund and chargeback — belongs to the second**, and the fact that the currency is virtual
does not change it. What does belong here: the server validating the receipt, and the shop's
*webhook* being verified by signature, because the client lies),
`streaming-multimedia-standards` (**broadcasting matches is a video pipeline and is
theirs**: ingest, transcoding, packaging, latency and spectator mode as delivery;
**here only in-game voice** and the fact that it is bought rather than built),
`chaos-engineering-standards` (**the resilience experiment is legitimate here, with one limit**:
it is bounded to `Ready` servers and the replenishment path, never to `Allocated` ones — §7),
`networking-standards`
(the network as a discipline; here the UDP profile of game traffic), `finops-standards` (economic
unit and cost governance; here the domain metric: cost per session/CCU),
`sre-practice-standards` (SLOs and on-call; here which SLIs are the domain's).

## 2. Default decisions / Toolchain

> Verify the latest version and the commercial status on the web before pinning anything (§8). **This
> market moved hard in 2025-2026** (Multiplay deprecated, Agones into the CNCF, GameLift changed
> its cost model): almost everything in circulation is out of date. Status verified as of Aug 2026:

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Managed backend or your own orchestration? | **Managed**, unless scale/sovereignty justifies otherwise in an ADR | Agones on your own Kubernetes | The on-call for a global 24/7 fleet is the hidden cost; self-hosted only with a real platform team |
| Own orchestration | **Agones** (CNCF Sandbox since Dec 2025, donated by Google; v1.58.x, ~6-week cadence, Go/C++/C#/Unity/Unreal/Python SDKs) | Bare Kubernetes with StatefulSets: **no** — it badly reimplements the Ready/Allocated cycle | The only game-server orchestrator with a real community (Google+Ubisoft originally, 800+ contributors) |
| Managed on AWS | **Amazon GameLift Servers** | Own containers on EKS+Agones | Cost model renewed in 2026: **free bandwidth since Jun 2026 (gen 6+ instances)** and **scale-to-zero (Jan 2026)** — re-budget, the old comparisons no longer hold |
| Managed on Azure / Xbox console | **PlayFab Multiplayer Servers** (active, no retirement announced; "Foundation Mode" GDC 2026) | — | Xbox integration and LiveOps |
| Unity Multiplay | **NOT for a new design: deprecated on 1 Apr 2026** (no new allocations; continuity only for those who migrated to "Multiplay by Rocket Science") | GameLift, Edgegap, Agones | A shutdown notice with ~3 months' warning: a lesson in single-vendor risk |
| Social/lightweight backend (auth, leaderboards, simple matchmaking, rooms) | **Nakama** (Heroic Labs; server Apache-2.0, clients Apache-2.0; Heroic Cloud as managed) or **Epic Online Services** (free, cross-platform) | PlayFab | For games with no dedicated simulation server, this is enough and avoids the whole fleet |
| Matchmaking as a service | Whatever the chosen backend offers (FlexMatch, PlayFab, Nakama, EOS) | **Open Match, only with caution**: the original 1.x (Apache-2.0) is not archived but its latest release supports Kubernetes 1.24/1.25 — de facto maintenance stopped; `open-match2` exists with low activity. **Not a solid base for a new design without a fresh evaluation** (§8) | An in-house matchmaker is a distributed system with queues, state and spikes: buy it unless there is a bespoke matching design requirement |
| Geographic placement | Regions chosen by measured latency of the player base; edge (Edgegap and similar) only if the RTT percentile justifies it | — | Player latency is set by physics, not by marketing |
| Cost unit | **Cost per session and per CCU**, with the idle fleet as its own line item | — | The buffer of Ready servers is the price of matchmaking latency: it gets sized, not eliminated |

## 3. Structure and conventions

- **Session lifecycle, the canonical pattern** (Agones names it, everyone implements it):
  the server starts → `Ready` (in the warm buffer) → the matchmaker/allocator marks it
  `Allocated` and hands the IP:port to the clients → the match runs → the server
  **declares itself finished and dies**; a process is never reused between matches without a
  reason (residual state = bugs and a cheating advantage).
- **Allocation belongs to the allocator, not to a balancer**: clients connect directly
  (or via a relay) to the assigned server. An L7 LB in front of match UDP is an antipattern.
- **Scaling protects sessions**: the autoscaler keeps a buffer of `Ready` servers (size = match
  start rate × start-up time, with headroom for the daily peak) and **only** reclaims
  empty servers. Draining = stop allocating + wait for the match to end (hours, not seconds);
  node/image upgrades are done by fleet rotation (blue/green at the fleet level), not by a
  rolling update of pods.
- **The load pattern is time-zone peaks**: an evening peak per region, launch and event peaks
  10-100× the average. Scale-to-zero for test environments and small games; reserved
  capacity + spot **only for the buffer, never for live sessions** (a spot
  interruption throws players out).
- **A traceable session**: every match with an ID, server, build version, region and players —
  it is the unit of observability, of cost and of support.

## 4. Quality and testing

One line (omitted as a full section): the quality of this layer is tested with **synthetic
matches** — bots filling real sessions against the staging fleet — measuring matchmaking time,
server start-up time, and that the autoscaler and draining do not kill
matches; the launch load test simulates the day-1 peak, not the average. The rest →
`testing-qa-standards` and `game-development-standards` (netcode).

## 5. Stack security

- **DDoS over UDP — defensive posture**: game traffic is UDP with the server's IP:port
  exposed to every client, and flooding is the standard cheap attack (including the player who
  takes down their rival's server). Layered defence: provider protection (GameLift/PlayFab
  include it; self-hosted, scrubbing from the cloud or a third party), **rate limiting and packet
  validation at the first hop** (a packet not conforming to the protocol is dropped without
  processing, with a session token issued at allocation time to filter unauthenticated traffic), and
  **relays/ephemeral IPs per session** so the fleet is not stably exposed. No
  offensive cookbook: mitigation design, not attack design.
- **The match server runs game code with hostile input**: an unprivileged process,
  with no control-plane credentials in the pod/instance (Agones's sidecar SDK exists
  for exactly that), and bounded egress — a compromised game server must not be able to reach the
  accounts database.
- **Voice and chat — compliance, not just a feature**: moderation and a reporting channel are
  mandatory if minors are present (DSA in the EU, COPPA in the US); minimum retention and a legal
  basis for the audio (recording voice is personal data, and biometric if analysed) →
  `privacy-engineering-standards`.
  Buy (Vivox, EOS Voice, Discord SDK…) rather than build; verify the provider's terms and regions (§8).
- Platform secrets (store keys, backend) **never** in the distributed server image;
  the dedicated server image handed to the community (self-hosting) is
  treated as published.

## 6. Performance and operability

One line (omitted as a full section): the domain SLIs are **matchmaking time (p95)**,
**time from session allocated → playable**, **matches killed by infrastructure** (the
sacred SLI: target ≈0), RTT per region and **cost per session/CCU with idleness as its own line
item**; the SLO/on-call framework belongs to `sre-practice-standards` and the metrics platform to
`observability-standards`.

## 7. When NOT to / Prohibitions

**When NOT to use this whole skill**: if the game has no dedicated server (simple P2P/relay,
a co-op with a player host), the right answer is usually a social backend (Nakama/EOS)
and no orchestrator at all — do not build a fleet for a game that does not need one.

- ❌ Treating a game server as a microservice: per-request balancing, rolling updates that kill
  `Allocated` pods, draining in seconds, a health check that restarts a "hung" match with
  players inside.
- ❌ Player sessions on **spot/preemptible instances**.
- ❌ Chaos experiments (`chaos-engineering-standards`) against `Allocated` servers. The
  discipline is legitimate and useful here, but **the blast radius is bounded to `Ready` servers and
  the replenishment path**: what gets refuted is "if I lose free capacity, does autoscaling
  replenish before it runs short?", not "what happens if I throw a thousand players out?".
- ❌ Recommending **Unity Multiplay** (deprecated Apr 2026) or adopting **Open Match** for a new
  design without a fresh evaluation of its maintenance (§2, §8).
- ❌ Bare Kubernetes (Deployments/StatefulSets) reinventing the Ready/Allocated cycle that
  Agones already solves.
- ❌ A global self-hosted fleet "to save money" without accounting for 24/7 on-call, patching and
  DDoS: managed is ruled out with numbers, not with instinct.
- ❌ A single vendor with no exit plan: the death of Multiplay with ~3 months' notice is the
  precedent. The server image stays portable (a standard container, the orchestrator SDK isolated
  behind an in-house interface).
- ❌ Exposing the fleet with stable IP:port and no first-packet validation; processing
  packets without a session token.
- ❌ Reusing a server process between matches without justified cleanup.
- ❌ Voice/chat with no moderation and no reporting in a game accessible to minors, or recording
  audio without a declared legal basis.
- ❌ Budgeting with cost comparisons predating 2026 (GameLift's free bandwidth since Jun 2026
  invalidates the earlier tables).
- ❌ Building an in-house matchmaker with no matching requirement that no service covers, written
  in an ADR.

## 8. Mandatory web verification

1. **Agones**: latest version and supported Kubernetes at `agones.dev` and
   `api.github.com/repos/agones-dev/agones/releases` (v1.58.0, May 2026; K8s 1.33-1.35);
   CNCF status (Sandbox since 2025-12-21 — has it moved to incubating?).
2. **Open Match**: the real status of `googleforgames/open-match` (verified Aug 2026:
   `archived: false`, push 2026-07-12, Apache-2.0, but the latest release targets K8s 1.24/1.25) and
   of `open-match2` — decide on this month's activity, not on this document.
3. **GameLift Servers**: pricing and news at `aws.amazon.com/gamelift` (free bandwidth
   gen 6+ since 2026-06-15; scale-to-zero Jan 2026; end of Realtime scripts on Node.js 10
   on 2026-09-30).
4. **PlayFab MPS**: `learn.microsoft.com` and `playfab.com/pricing` — no retirement announced as of
   Aug 2026; confirm before committing.
5. **Unity Multiplay**: the status of the deprecation (2026-04-01) and of "Multiplay by Rocket
   Science" in Unity's official notices.
6. **Nakama**: the raw `LICENSE` from the repository (`heroiclabs/nakama`, Apache-2.0) and what the
   Enterprise/Heroic Cloud edition requires; **EOS**: current terms and catalogue at
   `dev.epicgames.com`.
7. **The chosen voice provider**: terms, regions, retention and moderation tooling in
   its official documentation.
8. **Regulation of chat/voice with minors**: the status of the DSA as applied, COPPA and the local
   regulator's guidance — a moving figure.
9. **Declared gaps** (unverified — do not fill them from memory): concrete per-unit pricing for
   Edgegap, Heroic Cloud and PlayFab MPS; the status of Multiplay by Rocket Science as a
   product; the real feature parity between open-match2 and Open Match 1.x; the SLAs of the
   voice providers.

If the web contradicts this document, **the web wins** — flag the discrepancy.
